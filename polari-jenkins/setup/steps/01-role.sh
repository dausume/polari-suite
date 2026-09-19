#!/bin/bash
# setup/steps/01-role.sh — "what can THIS device be?"
#
# The pipeline has two jobs that want very different machines:
#   · the PIPELINE DEVICE — the Jenkins controller, the builds, the scans
#     and the publish routes. Measured: the controller image is capped at
#     2 GB (docker-compose.yml mem_limit), an Angular frontend build wants
#     ~3 GB, and they are serialised (CI_EXECUTORS=1), so ~5 GB of RAM.
#   · the THROWAWAY-ISLE TARGET — a VM that is created, installed into,
#     tested and destroyed: 4 GB / 2 vCPU / 30 GB by default, and it needs
#     /dev/kvm plus NESTED KVM (the isle's own router guest runs inside it).
# One device can be both — if it has the RAM for both at once.
#
# setup_role_fit is PURE arithmetic (the selftest drives it directly).

STEP_TITLE_role="what this pipeline maintains, and this device's role"

# ---------------------------------------------------------------------------
# ci-9 — THE FIRST QUESTION (his addendum 2026-09-19: "some people will also be
# using this pipeline as a way to maintain their own Polari Apps and will only
# be testing the one app they are developing").
#
# ci-8 gave the keys (CI_MODE, CI_APP_NAME, CI_APP_REPO, CI_CORE_SOURCE) and
# the validation. Nothing ASKED. It is asked here, and it is asked FIRST,
# because every later step's answer depends on it: app mode does not build the
# core, its stages default to `core; <app>`, its release is one deb, and it
# publishes to the developer's own routes.
# ---------------------------------------------------------------------------

setup_mode_summary() {   # one line, used by the check and the summary
    if [ "$CI_MODE" = app ]; then
        printf 'ONE app: %s (core %s, published to %s)' \
            "${CI_APP_NAME:-(unnamed)}" "$CI_CORE_SOURCE" "${CI_ROUTE_TARGET:-(no target set)}"
    else
        printf 'the whole Polari suite (core built here)'
    fi
}

# Does a name look like a module somebody could maintain? A module directory
# with a polari-app.json in THIS checkout is the strong answer; a
# polari-module-<name> repository URL is the answer for somebody whose app is
# not in this tree at all (the `pol project` standalone loop). Either is enough.
setup_app_known_here() { stages_app_known "$1"; }
setup_app_repo_guess() { printf 'https://github.com/<you>/polari-module-%s.git' "$1"; }

# `pol project` conventions, reused rather than reinvented: a module project is
# a directory with polari-app.json (+ .polari/project.json that `pol project
# init` writes). Cloning CI_APP_REPO under <pool>/apps/<name> gives the pipeline
# exactly what `pol project build` expects to find.
setup_app_checkout_dir() { printf '%s/apps/%s' "$(device_pool)" "${1:-$CI_APP_NAME}"; }
setup_app_clone() {   # setup_app_clone <name> <repo-url>  → 0 when the checkout is usable
    local name="$1" repo="$2" dir
    dir="$(setup_app_checkout_dir "$name")"
    if [ -d "$dir/.git" ]; then
        check OK "app checkout: $dir (already cloned — the pipeline pulls it per run)"
        return 0
    fi
    mkdir -p "$(dirname "$dir")"
    if git clone --depth 1 "$repo" "$dir" >/dev/null 2>&1; then
        if [ -f "$dir/polari-app.json" ]; then
            check OK "cloned $name → $dir (polari-app.json present — pol project conventions)"
            return 0
        fi
        check BAD "$repo has no polari-app.json at its root — that is not a Polari module project (pol project init <name> makes one)"
        return 1
    fi
    check BAD "could not clone $repo (a private repo needs a credential the pipeline does not have)"
    return 1
}

setup_role_fit() {
    # setup_role_fit <ram_mb> <cpus> <free_gb> <kvm 0|1> <vm_ram_gb> <vm_disk_gb> <ctrl_gb> <build_gb> <headroom_gb> <min_free_gb>
    # prints: role<TAB>yes|no<TAB>reason
    local ram=$1 cpus=$2 free=$3 kvm=$4 vmram=$5 vmdisk=$6 ctrl=$7 build=$8 head=$9 minfree=${10}
    local need_ctrl=$((ctrl * 1024)) need_build=$(((ctrl + build) * 1024))
    local need_both=$(((ctrl + build + vmram + head) * 1024)) need_alone=$(((vmram + head) * 1024))
    local disk_both=$((minfree + vmdisk)) disk_alone=$((vmdisk + minfree))

    if [ "$ram" -ge "$need_ctrl" ]; then printf 'controller\tyes\tthe controller is capped at %s GB\n' "$ctrl"
    else printf 'controller\tno\tless than %s GB of RAM\n' "$ctrl"; fi

    if [ "$ram" -ge "$need_build" ]; then printf 'builds\tyes\tcontroller %s GB + one build ~%s GB, serialised\n' "$ctrl" "$build"
    else printf 'builds\tno\ta frontend build wants ~%s GB on top of the controller (%s GB total)\n' "$build" "$((ctrl + build))"; fi

    if [ "$kvm" != 1 ]; then printf 'isle-here\tno\tno /dev/kvm on this machine\n'
    elif [ "$ram" -lt "$need_both" ]; then printf 'isle-here\tno\t%s GB needed for controller+build+VM+headroom, this machine has %s GB\n' "$((need_both / 1024))" "$((ram / 1024))"
    elif [ "$free" -lt "$disk_both" ]; then printf 'isle-here\tno\t%s GB of free disk needed (VM %s + pool floor %s)\n' "$disk_both" "$vmdisk" "$minfree"
    else printf 'isle-here\tyes\tRAM and disk for the controller, a build AND the VM at once\n'; fi

    if [ "$kvm" != 1 ]; then printf 'isle-only\tno\tno /dev/kvm on this machine\n'
    elif [ "$ram" -lt "$need_alone" ]; then printf 'isle-only\tno\tthe VM alone wants %s GB\n' "$((need_alone / 1024))"
    elif [ "$free" -lt "$disk_alone" ]; then printf 'isle-only\tno\tthe VM alone wants %s GB of free disk\n' "$disk_alone"
    else printf 'isle-only\tyes\tas a dedicated isle target for another device'\''s controller\n'; fi
}

setup_role_headline() {   # same arguments; one sentence
    local fit; fit="$(setup_role_fit "$@")"
    local ram=$1 cpus=$2 free=$3 c b h o
    c=$(printf '%s' "$fit" | awk -F'\t' '$1=="controller"{print $2}')
    b=$(printf '%s' "$fit" | awk -F'\t' '$1=="builds"{print $2}')
    h=$(printf '%s' "$fit" | awk -F'\t' '$1=="isle-here"{print $2}')
    o=$(printf '%s' "$fit" | awk -F'\t' '$1=="isle-only"{print $2}')
    local gb; gb=$(awk -v m="$ram" 'BEGIN{printf "%.1f", m/1024}')
    local verdict
    if   [ "$h" = yes ]; then verdict="controller + builds + a concurrent throwaway isle — this one device can be the whole pipeline"
    elif [ "$b" = yes ] && [ "$o" = yes ]; then verdict="controller + builds serialised — not a concurrent isle VM. It could host the isle on its own, but not while a build runs; put the isle on another device (pol jenkins target ssh <alias>) or add RAM"
    elif [ "$b" = yes ]; then verdict="controller + builds serialised — not a concurrent isle VM; put the isle on another device (pol jenkins target ssh <alias>) or add RAM"
    elif [ "$o" = yes ]; then verdict="a throwaway-isle TARGET only — too little RAM to also build here"
    elif [ "$c" = yes ]; then verdict="the controller only — a frontend build will not fit; build elsewhere or add RAM"
    else verdict="neither role: even the controller wants more than this"; fi
    printf '%s GB RAM, %s vCPU, %s GB free: %s\n' "$gb" "$cpus" "$free" "$verdict"
}

_role_readings() {   # RAM_MB CPUS FREE_GB KVM NESTED
    ROLE_RAM_MB=$(awk '/MemTotal/{print int($2/1024)}' /proc/meminfo 2>/dev/null || echo 0)
    ROLE_CPUS=$(nproc 2>/dev/null || echo 1)
    ROLE_FREE_GB=$(df -BG --output=avail "$J" 2>/dev/null | tail -1 | tr -dc '0-9' || echo 0)
    [ -n "$ROLE_FREE_GB" ] || ROLE_FREE_GB=0
    ROLE_KVM=0; [ -e /dev/kvm ] && ROLE_KVM=1
    ROLE_NESTED=$(cat /sys/module/kvm_intel/parameters/nested /sys/module/kvm_amd/parameters/nested 2>/dev/null | head -1 || true)
    [ -n "$ROLE_NESTED" ] || ROLE_NESTED=unreadable
}

step_role_check() {
    _role_readings
    local head fit
    # --- ci-9: the mode, first ------------------------------------------------
    if [ "$CI_MODE" = app ]; then
        check OK "maintains: ONE Polari app — $([ -n "$CI_APP_NAME" ] && echo "$CI_APP_NAME" || echo '(no name set)')"
        if [ -n "$CI_APP_NAME" ]; then
            setup_app_known_here "$CI_APP_NAME" \
                && check OK "  the module is in this checkout (modules/$CI_APP_NAME/polari-app.json)" \
                || check MISS "  not a module in this checkout — it comes from CI_APP_REPO"
        else
            check BAD "  CI_APP_NAME is empty — app mode maintains one app and must name it"
        fi
        [ -n "$CI_APP_REPO" ] && check OK "  repository: $CI_APP_REPO" \
            || check BAD "  CI_APP_REPO is empty — the app's own repository is where the pipeline builds it from"
        check OK "  core: $CI_CORE_SOURCE $([ "$CI_CORE_SOURCE" = build ] && echo '(REBUILT here — your app is tested against YOUR build, not an official release)' || echo '(pulled, never rebuilt)')"
        [ -n "$CI_ROUTE_TARGET" ] && check OK "  releases go to: $CI_ROUTE_TARGET" \
            || check MISS "  CI_ROUTE_TARGET is empty — app-mode releases must name YOUR owner/namespace"
    else
        check OK "maintains: the whole Polari suite — core, apps and images are all built here"
    fi
    head="$(setup_role_headline "$ROLE_RAM_MB" "$ROLE_CPUS" "$ROLE_FREE_GB" "$ROLE_KVM" \
             "$CI_ISLE_VM_RAM_GB" "$CI_ISLE_VM_DISK_GB" "$CI_CONTROLLER_RAM_GB" "$CI_BUILD_RAM_GB" \
             "$CI_MIN_RAM_HEADROOM_GB" "$CI_MIN_FREE_GB")"
    fit="$(setup_role_fit "$ROLE_RAM_MB" "$ROLE_CPUS" "$ROLE_FREE_GB" "$ROLE_KVM" \
             "$CI_ISLE_VM_RAM_GB" "$CI_ISLE_VM_DISK_GB" "$CI_CONTROLLER_RAM_GB" "$CI_BUILD_RAM_GB" \
             "$CI_MIN_RAM_HEADROOM_GB" "$CI_MIN_FREE_GB")"
    check OK "measured here: $head"
    printf '%s\n' "$fit" | while IFS=$'\t' read -r role yn why; do
        [ -n "$role" ] || continue
        [ "$yn" = yes ] && check OK "$role: yes — $why" || check MISS "$role: no — $why"
    done
    check "$([ "$ROLE_NESTED" = Y ] || [ "$ROLE_NESTED" = 1 ] && echo OK || echo MISS)" \
          "nested KVM: $ROLE_NESTED (the isle's router guest runs INSIDE the throwaway VM)"

    local mode_ok=1
    if [ "$CI_MODE" = app ]; then
        [ -n "$CI_APP_NAME" ] || { mode_ok=0; todo "app mode maintains ONE app but names none" "pol jenkins setup --step role"; }
        [ -n "$CI_APP_REPO" ] || { mode_ok=0; todo "app mode needs the app's own repository (CI_APP_REPO)" "pol jenkins setup --step role"; }
        [ -n "$CI_ROUTE_TARGET" ] || { mode_ok=0; todo "app-mode releases must name YOUR owner/namespace (CI_ROUTE_TARGET)" "pol jenkins setup --step role   — a fork is never republished under an upstream name"; }
        case "$CI_CORE_SOURCE" in
            release:*)
                if [ "$CI_CORE_SOURCE" != "release:latest" ] || true; then
                    check OK "  the core release is resolved and fetched once per tag: bash polari-jenkins/isle/core-artifacts.sh status"
                fi ;;
            build) check MISS "  CI_CORE_SOURCE=build — you are rebuilding core; releases of your app are tested against that build, not an official release" ;;
        esac
    fi

    if printf '%s' "$fit" | grep -q '^builds	yes'; then
        [ "$mode_ok" = 1 ] && state done "$(setup_mode_summary) — $head" || state todo "$head"
    else
        state todo "$head"
        todo "this machine cannot serialise the controller and a build (${CI_CONTROLLER_RAM_GB}+${CI_BUILD_RAM_GB} GB)" \
             "add RAM, or run the controller on a bigger device"
    fi
    # the "where does the isle go" to-do belongs to step 5, which owns the
    # choice — this step only measures and says which roles fit.
}

# ---------------------------------------------------------------- the ask
# THE FIRST QUESTION OF THE WHOLE WALKTHROUGH.
setup_ask_mode() {
    [ "$MODE" = report ] && return 0
    explain "FIRST: what does this pipeline maintain?

  1. THE WHOLE POLARI SUITE — core, the app modules, the images, the debs. It builds everything from a suite checkout, tests it in a throwaway isle and releases it. This is upstream Polari's own shape.

  2. ONE POLARI APP YOU ARE DEVELOPING — your module, from your own repository. The CORE IS NOT REBUILT: its debs come from an official Polari release, your app is tested against THAT core, and the release carries your app's deb alone, published to YOUR routes. Cheaper in every direction: no core build, one app's stage, one deb.

You can change this later: pol jenkins setup --step role."
    echo
    local pick
    pick="$(tui_menu 'What does this pipeline maintain?' \
        'The rest of the walkthrough follows from this answer.' \
        "$CI_MODE" \
        suite 'the whole Polari suite (core is built here)' \
        app   'ONE Polari app you are developing (core is pulled from a release)')"
    [ -n "$pick" ] || pick="$CI_MODE"
    device_env_set CI_MODE "$pick"
    check OK "device.env: CI_MODE=$pick"
    [ "$pick" = app ] || {
        # leaving app mode: the app keys become noise, and the doctor says so.
        [ -z "$CI_APP_NAME$CI_APP_REPO$CI_ROUTE_TARGET" ] || \
            check MISS "CI_APP_NAME / CI_APP_REPO / CI_ROUTE_TARGET are set but the mode is suite — they are ignored"
        device_reload
        return 0
    }

    # --- which app ---------------------------------------------------------
    local name repo known
    known="$(stages_known_apps | tr '\n' ' ')"
    name="$(ask_value 'Which app?' "The module package you maintain.

Modules in THIS checkout: ${known:-(none — polari-rf-node is not populated)}

If your app is not in this tree, name it anyway and give its repository next —
the pipeline clones it under $(setup_app_checkout_dir '<name>') the way
\`pol project\` expects (a polari-app.json at the root)." "$CI_APP_NAME")"
    [ -n "$name" ] || { check MISS "no app named — app mode cannot release anything until CI_APP_NAME is set"; device_reload; return 0; }
    device_env_set CI_APP_NAME "$name"
    if setup_app_known_here "$name"; then
        check OK "$name is a module in this checkout (modules/$name/polari-app.json)"
    else
        check MISS "$name is not a module in this checkout — it must come from its own repository"
    fi

    repo="$(ask_value "$name's repository" "The git URL \`pol project\` builds from. Convention: polari-module-<name>.

  $(setup_app_repo_guess "$name")

It is cloned (shallow) under $(setup_app_checkout_dir "$name") and must carry a polari-app.json at its root." "${CI_APP_REPO:-}")"
    if [ -n "$repo" ]; then
        device_env_set CI_APP_REPO "$repo"
        ask 'clone it now?' "Clone $repo into $(setup_app_checkout_dir "$name") so the pipeline has it? (It is re-pulled on every run either way.)" yes \
            && setup_app_clone "$name" "$repo" || true
    else
        check MISS "no repository — CI_APP_REPO is what the pipeline builds your app from"
    fi

    # --- which core --------------------------------------------------------
    local core
    core="$(tui_menu 'Which core is your app tested against?' \
        "An app that 'passed' against an unnamed core is a claim nobody can check, so the release record always names this.

release:latest resolves to the newest official Polari release that actually carries debs, and its artifacts are fetched ONCE into the cache." \
        "$CI_CORE_SOURCE" \
        release:latest 'the newest official Polari release (recommended)' \
        pin            'a specific release tag — you will be asked for it' \
        build          'rebuild core from this checkout (you also patch core)')"
    case "${core:-}" in
        pin)
            local tag
            tag="$(ask_value 'Which release tag?' 'e.g. polari-v2026.09.19 — it must be a published release carrying .deb assets.' "${CI_CORE_SOURCE#release:}")"
            [ -n "$tag" ] && device_env_set CI_CORE_SOURCE "release:$tag" || check MISS "no tag given — CI_CORE_SOURCE left as $CI_CORE_SOURCE" ;;
        '') : ;;
        *) device_env_set CI_CORE_SOURCE "$core" ;;
    esac
    if [ "$CI_CORE_SOURCE" = build ]; then
        check MISS "you are rebuilding core; releases of your app are tested against that build, not an official release"
    else
        local resolved
        resolved="$(bash "$J/isle/core-artifacts.sh" resolve 2>/dev/null || true)"
        [ -n "$resolved" ] && check OK "$CI_CORE_SOURCE resolves to $resolved" \
            || check MISS "$CI_CORE_SOURCE does not resolve right now (no network, or no such published release) — the doctor names it before a run"
    fi

    # --- where the releases go --------------------------------------------
    local target
    target="$(ask_value 'Where do YOUR releases go?' "Your own owner/namespace — the GitHub user or org your app's release, deb and images are published under.

The upstream owner ($CI_UPSTREAM_OWNER) is REFUSED: a fork is never republished under an upstream name." "$CI_ROUTE_TARGET")"
    if [ -n "$target" ]; then
        case "$target" in
            "$CI_UPSTREAM_OWNER"|"$CI_UPSTREAM_OWNER"/*) check BAD "$target is the upstream owner — refused. Use your own." ;;
            *) device_env_set CI_ROUTE_TARGET "$target"; check OK "device.env: CI_ROUTE_TARGET=$target" ;;
        esac
    else
        check MISS "no target — app-mode routes stay DRY until CI_ROUTE_TARGET names your own owner/namespace"
    fi

    # app mode's stage default, written once so step 6 shows the real thing
    if [ "$CI_ISLE_STAGES" = core ] && [ -n "$CI_APP_NAME" ]; then
        device_env_set CI_ISLE_STAGES "core; $CI_APP_NAME"
        check OK "stages default to: core; $CI_APP_NAME (step $(step_index stages) can change them)"
    fi
    device_reload
    doctor_refresh
}

# ci-11a — the SAME questions setup_ask_mode asks, declared so a machine can
# answer them one at a time. The checks are not repeated here: json_step runs
# step_role_check, the same function the terminal prints.
step_role_json() {
    json_explain "FIRST: what does this pipeline maintain?

1. THE WHOLE POLARI SUITE — core, the app modules, the images, the debs. It builds everything from a suite checkout, tests it in a throwaway isle and releases it. This is upstream Polari's own shape.

2. ONE POLARI APP YOU ARE DEVELOPING — your module, from your own repository. The CORE IS NOT REBUILT: its debs come from an official Polari release, your app is tested against THAT core, and the release carries your app's deb alone, published to YOUR routes. Cheaper in every direction: no core build, one app's stage, one deb."
    json_explain "Two roles, and one device can hold both if it has the room. PIPELINE DEVICE — the controller (capped at ${CI_CONTROLLER_RAM_GB} GB), the builds (~${CI_BUILD_RAM_GB} GB, serialised) and the publish routes; nothing inbound is ever opened. THROWAWAY-ISLE TARGET — a VM created, tested and destroyed: ${CI_ISLE_VM_RAM_GB} GB / ${CI_ISLE_VM_VCPUS} vCPU / ${CI_ISLE_VM_DISK_GB} GB, needing /dev/kvm AND nested KVM. This step only measures; step $(step_index isle) chooses where the isle goes."
    json_question CI_MODE 'What does this pipeline maintain?' choice suite "$CI_MODE" \
        'suite=the whole Polari suite (core is built here)|app=ONE Polari app you are developing (core is pulled from a release)'
    if [ "$CI_MODE" = app ]; then
        json_question CI_APP_NAME 'Which app?' text '' "$CI_APP_NAME" ''
        json_question CI_APP_REPO "The app's own repository (polari-module-<name>, a polari-app.json at its root)" \
            text '' "$CI_APP_REPO" ''
        json_question CI_CORE_SOURCE 'Which core is your app tested against?' choice release:latest "$CI_CORE_SOURCE" \
            'release:latest=the newest official Polari release (recommended)|build=rebuild core from this checkout'
        json_question CI_ROUTE_TARGET "Where do YOUR releases go? (your own owner/namespace — $CI_UPSTREAM_OWNER is refused)" \
            text '' "$CI_ROUTE_TARGET" ''
        if [ -n "$CI_APP_REPO" ] && [ -n "$CI_APP_NAME" ]; then
            json_action clone-app "Clone $CI_APP_NAME into the pool" 0 setup-run \
                "$([ -d "$(setup_app_checkout_dir "$CI_APP_NAME")/.git" ] && echo 1 || echo 0)" \
                "a shallow clone under $(setup_app_checkout_dir "$CI_APP_NAME"); the pipeline re-pulls it every run" \
                'action=clone-app'
        fi
    fi
}

step_role_do() {
    setup_ask_mode
    echo
    explain "Two roles, and one device can hold both if it has the room.

PIPELINE DEVICE — the Jenkins controller, the builds, the scans and the publish routes. Measured: the controller is capped at ${CI_CONTROLLER_RAM_GB} GB (compose mem_limit), an Angular frontend build wants ~${CI_BUILD_RAM_GB} GB, and only one build runs at a time (CI_EXECUTORS=1). Nothing inbound is ever opened: the UI binds 127.0.0.1 and every publish is an outbound push.

THROWAWAY-ISLE TARGET — a VM created, installed into, tested and destroyed for every isle-test stage: ${CI_ISLE_VM_RAM_GB} GB / ${CI_ISLE_VM_VCPUS} vCPU / ${CI_ISLE_VM_DISK_GB} GB, needing /dev/kvm AND nested KVM (the isle boots its own router guest inside that VM).

This step only reads and reports — it changes nothing. Step $(step_index isle) is where you choose where the isle goes."
    echo
    step_role_check
}
