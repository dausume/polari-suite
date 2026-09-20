#!/bin/bash
# polari-jenkins/device.sh — the pipeline-device configuration, in ONE
# place: load device.env, apply the defaults, validate every key, and run
# a command ON THE TARGET (this machine, or another device over ssh).
#
# SOURCED, not executed:   source "$(dirname "$0")/device.sh"
# (executing it prints the configuration, same as `pol jenkins config`.)
# strict mode belongs to the EXECUTABLE; sourcing this must not change the
# caller's shell options (jenkins.sh runs `set -eu` on purpose).
[ "${BASH_SOURCE[0]}" = "${0}" ] && set -euo pipefail

DEVICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DEVICE_KEYS="CI_MODE CI_APP_NAME CI_APP_REPO CI_CORE_SOURCE \
CI_ISLE_TARGET CI_ISLE_SSH_HOST CI_ISLE_SSH_USER CI_ISLE_VM_NAME CI_ISLE_VM_RAM_GB \
CI_ISLE_VM_VCPUS CI_ISLE_VM_DISK_GB CI_ISLE_NESTED CI_ISLE_POOL CI_ISLE_IMAGE_URL \
CI_MIN_FREE_GB CI_MIN_RAM_HEADROOM_GB CI_EXECUTORS CI_ROUTES CI_ISLE_STAGES \
CI_CACHE CI_CACHE_DIR CI_CACHE_MAX_GB CI_CACHE_PROXIES CI_ROUTE_TARGET \
CI_CORE_URL CI_DEVICE_NAME"

# Where the module manifests live (modules/<name>/polari-app.json) — the
# catalogue CI_ISLE_STAGES is validated against. Overridable for tests.
CI_MODULES_DIR="${CI_MODULES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd)/polari-rf-node/polari-framework/modules}"

DEVICE_ENV_FILE="${DEVICE_ENV_FILE:-$DEVICE_DIR/device.env}"
DEVICE_ENV_PRESENT=0

# Precedence, highest first: an explicitly exported CI_* (how a pipeline run
# injects its own config) → device.env → the defaults below. Nothing here
# reads a value from anywhere else, so `pol jenkins config` is the truth.
device_load() {
    local k line key val
    for k in $DEVICE_KEYS; do printf -v "_PRE_$k" '%s' "${!k:-}"; done
    if [ -f "$DEVICE_ENV_FILE" ]; then
        DEVICE_ENV_PRESENT=1
        while IFS= read -r line || [ -n "$line" ]; do
            case "$line" in ''|\#*) continue ;; esac
            key="${line%%=*}"; val="${line#*=}"
            case "$key" in CI_*) ;; *) continue ;; esac
            case " $DEVICE_KEYS " in *" $key "*) ;; *) continue ;; esac
            printf -v "$key" '%s' "${val%$'\r'}"
        done < "$DEVICE_ENV_FILE"
    fi
    for k in $DEVICE_KEYS; do                      # the explicit export wins back
        local pre="_PRE_$k"; [ -z "${!pre}" ] || printf -v "$k" '%s' "${!pre}"
    done
    # ------------------------------------------------------------ defaults
    # ci-8, his addendum 2026-09-19: what this pipeline is FOR.
    #   suite  the whole Polari suite is built, tested and released (today's shape)
    #   app    ONE Polari app somebody maintains — CI_APP_NAME + CI_APP_REPO, and the CORE is PULLED
    #          from CI_CORE_SOURCE (release:<tag>|release:latest), never rebuilt
    : "${CI_MODE:=suite}"
    : "${CI_APP_NAME:=}"
    : "${CI_APP_REPO:=}"
    : "${CI_CORE_SOURCE:=release:latest}"
    : "${CI_ISLE_TARGET:=local}"
    : "${CI_ISLE_SSH_HOST:=}"
    : "${CI_ISLE_SSH_USER:=}"
    : "${CI_ISLE_VM_NAME:=polari-ci-isle}"
    : "${CI_ISLE_VM_RAM_GB:=4}"
    : "${CI_ISLE_VM_VCPUS:=2}"
    : "${CI_ISLE_VM_DISK_GB:=30}"
    : "${CI_ISLE_NESTED:=auto}"
    : "${CI_ISLE_POOL:=}"
    : "${CI_ISLE_IMAGE_URL:=https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img}"
    # ci-13 (his ruling 2026-09-20): a Polari set up FOR PIPELINE TESTING reuses what it can. The guest's
    # prerequisites are baked ONCE into a PREPARED base image in the cache (keyed by the cloud image + this
    # list) and every later throwaway boots from it; `off` boots the bare cloud image every time.
    : "${CI_ISLE_PREPARED:=auto}"
    : "${CI_ISLE_PREREQ_PKGS:=qemu-kvm qemu-system-x86 qemu-utils libvirt-daemon-system libvirt-clients bridge-utils dnsmasq acl net-tools wget jq python3 docker.io docker-compose-v2}"
    # test-built images are DISCARDED after the run (only a release keeps its images); 1 keeps them for a look
    : "${CI_KEEP_TEST_IMAGES:=0}"
    : "${CI_MIN_FREE_GB:=20}"
    : "${CI_MIN_RAM_HEADROOM_GB:=1}"
    # ci-12: FOUR, and every one of them is a WAITING SLOT, not a concurrent
    # build. What serialises the real work is the `polari-build` lock — nothing
    # here. The count only has to be large enough that nobody deadlocks, and on
    # this pipeline three things hold an executor while doing nothing:
    #   · a build WAITING for the lock holds its executor (declarative allocates
    #     the node first, then takes the lock), so dev-build and release can each
    #     be sitting on one while test runs;
    #   · a parent WAITING for a child holds its own (polari-test → isle-test);
    #   · the child then needs one of its own.
    # Two was not enough: with dev-build parked on the lock, polari-isle-test #2
    # sat at "Waiting for next available executor" while polari-test #34 held the
    # other. Four is one per job that can be in flight (dev-build, test, release,
    # isle-test) — raising it does NOT let two builds compile at once.
    : "${CI_EXECUTORS:=4}"
    : "${CI_ROUTES:=github-release,ghcr,homebrew,apt-repo}"
    : "${CI_ISLE_STAGES:=core}"
    # ci-9 (his ask 2026-09-19): "the jenkins pipeline should try and use offline artifacts for building
    # where possible". The cache is an OPTIMISATION, never a precondition — an empty cache still builds.
    : "${CI_CACHE:=on}"
    : "${CI_CACHE_DIR:=}"          # empty = <pool>/cache (so the ssh hop carries it to the TARGET's pool)
    : "${CI_CACHE_MAX_GB:=40}"     # the doctor WARNs past it; nothing ever deletes on its own
    : "${CI_CACHE_PROXIES:=off}"   # tier two (registry/devpi/verdaccio/apt-cacher-ng) — off by default
    # ci-9, app mode: WHERE this device's own releases go. Empty in suite mode (the upstream routes
    # decide); in app mode it is the developer's OWN owner/namespace, and a route pointed at the upstream
    # owner is a validation FAIL — a fork is never republished under an upstream name.
    : "${CI_ROUTE_TARGET:=}"
    # ci-8: the Polari core that holds the SETTINGS for this device. Empty = no sync; the file below is
    # then the only truth there is, which is exactly the fallback posture cicd-sync.sh degrades to.
    : "${CI_CORE_URL:=}"
    # ci-8: the NAME this device has in Polari. A name somebody chooses — never the machine's
    # hostname (his privacy rule: no real host ever reaches a row, a page or an API answer).
    : "${CI_DEVICE_NAME:=pipeline}"
    # app mode's default stage list is core + the one app (the cicd module says the same thing in python)
    if [ "$CI_MODE" = app ] && [ -n "$CI_APP_NAME" ] && [ "$CI_ISLE_STAGES" = core ]; then
        CI_ISLE_STAGES="core; $CI_APP_NAME"
    fi
}

# --------------------------------------------------------- testing stages
# CI_ISLE_STAGES: stages separated by ';', apps within a stage by ','.
# The literal `core` is the core debs only. Each stage runs in its OWN
# throwaway isle, one at a time, so a space-limited device still tests
# everything — just more slowly. Every stage installs the core debs first,
# so core is re-verified in each; the recorded core result is stage 1's.
#
#   core; household; electronics,cntfet
#     → stage 1 core only · stage 2 household · stage 3 electronics+cntfet
stages_list() {   # one stage per line, apps space-separated ('core' → an empty line)
    printf '%s' "$CI_ISLE_STAGES" | awk -v RS=';' '{
        gsub(/[ \t\r\n]/, "");
        n = split($0, a, ",");
        out = "";
        for (i = 1; i <= n; i++)
            if (a[i] != "" && a[i] != "core") out = out (out == "" ? "" : " ") a[i];
        print out
    }'
}
stages_count()    { stages_list | wc -l | tr -d ' '; }
stages_apps()     { stages_list | sed -n "${1}p"; }          # stages_apps <n>
stages_all_apps() { stages_list | tr ' ' '\n' | grep -v '^$' | sort -u || true; }
stages_known_apps() { [ -d "$CI_MODULES_DIR" ] && find "$CI_MODULES_DIR" -mindepth 2 -maxdepth 2 -name polari-app.json -printf '%h\n' 2>/dev/null | xargs -r -n1 basename | sort || true; }
stages_app_known() { [ -f "$CI_MODULES_DIR/$1/polari-app.json" ]; }
stages_print() {  # numbered, for `pol jenkins config`
    local n=1 apps
    while IFS= read -r apps; do
        printf '  stage %d  %s\n' "$n" "$([ -n "$apps" ] && echo "core + $apps" || echo 'core only')"
        n=$((n+1))
    done < <(stages_list)
}

# --------------------------------------------------- write ONE key back
# The single definition of "rewrite a key in device.env" — the CLI's
# jd_set and `pol jenkins setup` both come here, so there is one writer.
device_env_set() {   # device_env_set KEY VALUE
    local k="$1" v="${2:-}" f="$DEVICE_ENV_FILE"
    [ -f "$f" ] || { install -m 0600 /dev/null "$f"; }
    if grep -qE "^$k=" "$f" 2>/dev/null; then
        python3 - "$f" "$k" "$v" <<'PY'
import sys
path, key, val = sys.argv[1:4]
out = []
for line in open(path):
    out.append('%s=%s\n' % (key, val) if line.split('=', 1)[0] == key else line)
open(path, 'w').writelines(out)
PY
    else
        printf '%s=%s\n' "$k" "$v" >> "$f"
    fi
    printf -v "$k" '%s' "$v"
}

# Re-read device.env after something else wrote it. Plain re-sourcing does
# NOT do this: device_load treats an already-set CI_* as an explicit
# override and wins it back, so a caller that has loaded once would keep
# the stale value forever.
device_reload() { local k; for k in $DEVICE_KEYS; do unset "$k"; done; device_load; }

CI_SSH_TIMEOUT="${CI_SSH_TIMEOUT:-8}"
# The controller's own budget, for the "everything serialised" RAM sum on a
# local target (docker-compose.yml mem_limit 2g + an Angular build ~3 GB).
CI_CONTROLLER_RAM_GB="${CI_CONTROLLER_RAM_GB:-2}"
CI_BUILD_RAM_GB="${CI_BUILD_RAM_GB:-3}"

device_print() {
    local k
    echo "# pipeline device configuration ($DEVICE_ENV_FILE$([ "$DEVICE_ENV_PRESENT" = 1 ] || echo ' — ABSENT, defaults shown'))"
    for k in $DEVICE_KEYS; do printf '%s=%s\n' "$k" "${!k}"; done
    echo "# isle testing stages — each runs in its OWN throwaway isle, one at a time;"
    echo "# ONLY what a stage tested is ever released (results.json, the release rule)"
    stages_print
}

device_export() { local k; for k in $DEVICE_KEYS; do export "$k"; done; }

# ------------------------------------------------------------- validation
# Every row: key|value|status|message   (status OK|WARN|FAIL)
_row() { printf '%s|%s|%s|%s\n' "${1//|/ }" "${2//|/ }" "$3" "${4//|/ }"; }   # | is the field separator
_is_num() { case "${1:-}" in ''|*[!0-9]*) return 1 ;; *) return 0 ;; esac; }

device_validate() {
    local k
    if [ "$DEVICE_ENV_PRESENT" = 1 ]; then _row device.env "$DEVICE_ENV_FILE" OK "present"
    else _row device.env "$DEVICE_ENV_FILE" WARN "absent — defaults in force → write it with: pol jenkins target local (or: pol jenkins target ssh <alias>)"; fi

    # ---------------------------------------------------- ci-8: the two modes
    # A mode outside suite|app is a WARN and reads as `suite` — an unknown mode from a newer core must not
    # stop this device from running the pipeline it already has.
    case "$CI_MODE" in
        suite) _row CI_MODE suite OK "the whole Polari suite is built, tested and released" ;;
        app)   _row CI_MODE app OK "this device maintains ONE Polari app: ${CI_APP_NAME:-(unnamed)}" ;;
        *)     _row CI_MODE "$CI_MODE" WARN "unknown mode → suite|app; reading it as suite" ;;
    esac
    if [ "$CI_MODE" = app ]; then
        [ -n "$CI_APP_NAME" ] || _row CI_APP_NAME "" FAIL \
            "app mode maintains ONE app but names none → set CI_APP_NAME to the module package"
        [ -n "$CI_APP_REPO" ] || _row CI_APP_REPO "" FAIL \
            "app mode needs the app's own repository → set CI_APP_REPO to the polari-module-${CI_APP_NAME:-<name>} git URL"
    elif [ -n "$CI_APP_NAME$CI_APP_REPO" ]; then
        _row CI_APP_NAME "$CI_APP_NAME" WARN "set but the mode is suite → it is ignored; set CI_MODE=app to maintain one app"
    fi
    # ---- CI_CORE_SOURCE is an APP-MODE knob, and only an app-mode knob (ci-12
    # addendum 7). In SUITE mode the core under test is what THIS RUN built; the
    # release-pull path is never taken, so a `release:*` left here — and ci-9's
    # default IS release:latest — promises something the device does not do. The
    # row must not claim it does: it is INFO, not a WARN and not a promise.
    # Live, on the pipeline device: a suite-mode device carrying release:latest
    # sent every isle stage to core-artifacts.sh, which REFUSED
    # ("providers.sh is not in this checkout") and failed the run.
    if [ "$CI_MODE" != app ]; then
        _row CI_CORE_SOURCE "$CI_CORE_SOURCE" OK \
             "INFO: suite mode builds its own core here; CI_CORE_SOURCE is an app-mode knob and is ignored"
    else
        case "$CI_CORE_SOURCE" in
            build)      _row CI_CORE_SOURCE build OK "the core is REBUILT from this suite checkout" ;;
            release:)   _row CI_CORE_SOURCE "$CI_CORE_SOURCE" FAIL "release: with no tag → release:latest, or release:<a Polari release tag>" ;;
            release:*)  _row CI_CORE_SOURCE "$CI_CORE_SOURCE" OK "the core debs and images are PULLED from that Polari release, never rebuilt" ;;
            *)          _row CI_CORE_SOURCE "$CI_CORE_SOURCE" FAIL "unknown core source → release:<tag> | release:latest (pull) or build (rebuild)" ;;
        esac
    fi

    case "$CI_ISLE_TARGET" in
        local) _row CI_ISLE_TARGET local OK "the throwaway isle is created on this machine" ;;
        ssh)   _row CI_ISLE_TARGET ssh OK "the throwaway isle is created on another device" ;;
        *)     _row CI_ISLE_TARGET "$CI_ISLE_TARGET" FAIL "unknown target → set it to local or ssh: pol jenkins target local" ;;
    esac

    if [ "$CI_ISLE_TARGET" = ssh ]; then
        if [ -z "$CI_ISLE_SSH_HOST" ]; then
            _row CI_ISLE_SSH_HOST "" FAIL "target is ssh but no alias is set → pol jenkins target ssh <alias>"
        elif ! device_ssh_alias_known; then
            _row CI_ISLE_SSH_HOST "$CI_ISLE_SSH_HOST" WARN "no Host entry in ~/.ssh/config → add one (an ALIAS, never an address in a tracked file)"
        else
            _row CI_ISLE_SSH_HOST "$CI_ISLE_SSH_HOST" OK "ssh alias known"
        fi
    else
        [ -z "$CI_ISLE_SSH_HOST" ] && _row CI_ISLE_SSH_HOST "" OK "not used (target is local)" \
            || _row CI_ISLE_SSH_HOST "$CI_ISLE_SSH_HOST" WARN "set but the target is local → it is ignored; pol jenkins target ssh $CI_ISLE_SSH_HOST to use it"
    fi

    for k in CI_ISLE_VM_RAM_GB CI_ISLE_VM_VCPUS CI_ISLE_VM_DISK_GB CI_MIN_FREE_GB CI_MIN_RAM_HEADROOM_GB CI_EXECUTORS; do
        if _is_num "${!k}" && [ "${!k}" -gt 0 ]; then _row "$k" "${!k}" OK ""
        else _row "$k" "${!k}" FAIL "not a positive whole number → fix it in $DEVICE_ENV_FILE"; fi
    done
    [ "${CI_ISLE_VM_DISK_GB:-0}" -ge 30 ] 2>/dev/null || _row CI_ISLE_VM_DISK_GB "$CI_ISLE_VM_DISK_GB" WARN \
        "an isle install wants ≥ 30 GB → raise it in $DEVICE_ENV_FILE"

    case "$CI_ISLE_NESTED" in
        auto|required|off) _row CI_ISLE_NESTED "$CI_ISLE_NESTED" OK "" ;;
        *) _row CI_ISLE_NESTED "$CI_ISLE_NESTED" FAIL "unknown value → auto|required|off" ;;
    esac

    local bad=""
    local r; for r in ${CI_ROUTES//,/ }; do
        case "$r" in
            github-release|ghcr|homebrew|apt-repo) ;;
            dockerhub|npm|pypi|launchpad|snap) bad="$bad $r(PARKED)" ;;
            *) bad="$bad $r(unknown)" ;;
        esac
    done
    [ -z "$bad" ] && _row CI_ROUTES "$CI_ROUTES" OK "routes that may publish for real" \
        || _row CI_ROUTES "$CI_ROUTES" FAIL "not publishable:$bad → ACTIVE routes are github-release,ghcr,homebrew,apt-repo"

    if [ "${CI_EXECUTORS:-4}" -lt 4 ] 2>/dev/null; then
        _row CI_EXECUTORS "$CI_EXECUTORS" WARN \
            "too few: a build WAITING for the polari-build lock holds an executor, and polari-test also waits for polari-isle-test while holding its own — fewer than 4 deadlocks the isle stage → set CI_EXECUTORS=4 (they are waiting slots; the lock is what stops builds overlapping)"
    elif [ "${CI_EXECUTORS:-4}" -gt 4 ] 2>/dev/null; then
        _row CI_EXECUTORS "$CI_EXECUTORS" WARN \
            "more than 4 is more than the jobs that can be in flight (dev-build, test, release, isle-test) — harmless, but it is not buying anything"
    fi

    device_validate_cache
    device_validate_route_target
    device_validate_stages
}

# ---------------------------------------------------------- ci-9: the cache
# The offline-first cache. Every row is advisory by design: a cache that is
# misconfigured must slow a build down, never stop one.
device_validate_cache() {
    case "$CI_CACHE" in
        on)  _row CI_CACHE on OK "builds read the cache first and fetch only what is missing" ;;
        off) _row CI_CACHE off WARN "every build re-downloads its wheels, npm packages, debs and base images → set CI_CACHE=on (the default)" ;;
        *)   _row CI_CACHE "$CI_CACHE" FAIL "unknown value → on or off" ;;
    esac
    if _is_num "$CI_CACHE_MAX_GB" && [ "$CI_CACHE_MAX_GB" -gt 0 ]; then
        _row CI_CACHE_MAX_GB "$CI_CACHE_MAX_GB" OK "the budget the doctor warns past (it never deletes: pol jenkins cache prune does)"
    else
        _row CI_CACHE_MAX_GB "$CI_CACHE_MAX_GB" FAIL "not a positive whole number → fix it in $DEVICE_ENV_FILE"
    fi
    case "$CI_CACHE_PROXIES" in
        off) _row CI_CACHE_PROXIES off OK "tier one only — one directory, no services to keep alive" ;;
        on)  _row CI_CACHE_PROXIES on OK "tier two: registry/devpi/verdaccio/apt-cacher-ng on 127.0.0.1 (pol jenkins cache proxies status)" ;;
        *)   _row CI_CACHE_PROXIES "$CI_CACHE_PROXIES" FAIL "unknown value → off or on" ;;
    esac
    [ -z "$CI_CACHE_DIR" ] && _row CI_CACHE_DIR "" OK "the default: <pool>/cache (relative to the pool, so an ssh target caches on its own disk)" \
        || _row CI_CACHE_DIR "$CI_CACHE_DIR" OK "an explicit cache root"
}

# --------------------------------------------- ci-9: where a release is sent
# The UPSTREAM owner. A device in `app` mode maintains SOMEBODY'S OWN app; its
# releases go to their namespace. A route aimed at upstream Polari is refused —
# a fork is never republished under an upstream name (the ci-8 rule, now a key).
CI_UPSTREAM_OWNER="${CI_UPSTREAM_OWNER:-dausume}"
device_validate_route_target() {
    if [ "$CI_MODE" != app ]; then
        [ -z "$CI_ROUTE_TARGET" ] && _row CI_ROUTE_TARGET "" OK "not used (suite mode publishes to the suite's own routes)" \
            || _row CI_ROUTE_TARGET "$CI_ROUTE_TARGET" WARN "set but the mode is suite → it is ignored; set CI_MODE=app to publish to your own routes"
        return
    fi
    if [ -z "$CI_ROUTE_TARGET" ]; then
        _row CI_ROUTE_TARGET "" FAIL \
            "app mode releases to YOUR routes but names none → set CI_ROUTE_TARGET to your own owner/namespace (e.g. your GitHub user)"
        return
    fi
    case "$CI_ROUTE_TARGET" in
        "$CI_UPSTREAM_OWNER"|"$CI_UPSTREAM_OWNER"/*)
            _row CI_ROUTE_TARGET "$CI_ROUTE_TARGET" FAIL \
                "that is the UPSTREAM owner — a fork is never republished under an upstream name → set CI_ROUTE_TARGET to your own owner/namespace" ;;
        *)  _row CI_ROUTE_TARGET "$CI_ROUTE_TARGET" OK "this device's releases go to $CI_ROUTE_TARGET, never upstream" ;;
    esac
}

# The testing stages: every app named must be a real module (a directory
# with a polari-app.json), no app may be tested twice, no stage may be
# empty. The release rule leans on this list: only what a stage TESTED is
# published, so an unknown name here means an app silently never released.
device_validate_stages() {
    local n unknown="" dupes="" empties="" apps a seen=" " total
    total=$(stages_count)
    if [ "${total:-0}" -eq 0 ]; then
        _row CI_ISLE_STAGES "$CI_ISLE_STAGES" FAIL "no testing stage at all → set at least: CI_ISLE_STAGES=core (pol jenkins setup --step stages)"
        return
    fi
    n=0
    while IFS= read -r apps; do
        n=$((n+1))
        [ -n "$apps" ] || { [ "$n" = 1 ] || empties="$empties $n"; continue; }
        for a in $apps; do
            stages_app_known "$a" || unknown="$unknown $a"
            case "$seen" in *" $a "*) dupes="$dupes $a" ;; *) seen="$seen$a " ;; esac
        done
    done < <(stages_list)

    if [ -n "$unknown" ]; then
        _row CI_ISLE_STAGES "$CI_ISLE_STAGES" WARN \
            "not a module with a polari-app.json:$unknown → known apps: $(stages_known_apps | tr '\n' ' ' | sed 's/ $//')"
    else
        local tested; tested="$(stages_all_apps | tr '\n' ' ' | sed 's/ $//')"
        _row CI_ISLE_STAGES "$CI_ISLE_STAGES" OK "$total stage(s); apps tested: ${tested:-none (core only)}"
    fi
    [ -z "$dupes" ] || _row "isle stages (twice)" "$dupes" WARN \
        "tested twice (each stage installs core + its own apps):$dupes → name each app in ONE stage"
    [ -z "$empties" ] || _row "isle stages (empty)" "stage$empties" WARN \
        "empty stage(s)$empties — they would re-test core only → remove them, or name their apps"
    # ci-8 (his addendum): in app mode another app may be TESTED here but is never RELEASED here.
    if [ "$CI_MODE" = app ] && [ -n "$CI_APP_NAME" ]; then
        local others=""
        for a in $(stages_all_apps); do [ "$a" = "$CI_APP_NAME" ] || others="$others $a"; done
        [ -z "$others" ] || _row "isle stages (other apps)" "${others# }" WARN \
            "this device maintains $CI_APP_NAME; other apps are tested but never released here:$others"
        case " $(stages_all_apps | tr '\n' ' ') " in
            *" $CI_APP_NAME "*) ;;
            *) _row "isle stages (the app)" "$CI_APP_NAME" WARN \
                   "app mode maintains $CI_APP_NAME but no stage tests it → nothing can be released (the default is: core; $CI_APP_NAME)" ;;
        esac
    fi
}

device_ssh_alias_known() {
    [ -n "$CI_ISLE_SSH_HOST" ] || return 1
    grep -qiE "^[[:space:]]*Host([[:space:]]+[^[:space:]]+)*[[:space:]]+${CI_ISLE_SSH_HOST}([[:space:]]|$)" \
        "${HOME:-/root}/.ssh/config" 2>/dev/null
}

# --------------------------------------------------------------- the target
device_ssh_dest() { [ -n "$CI_ISLE_SSH_USER" ] && echo "$CI_ISLE_SSH_USER@$CI_ISLE_SSH_HOST" || echo "$CI_ISLE_SSH_HOST"; }

device_target_name() { [ "$CI_ISLE_TARGET" = local ] && echo "this machine" || echo "ssh:$(device_ssh_dest)"; }

# Run a shell snippet ON THE TARGET. Never interactive: an ssh that would
# ask for anything fails instead (BatchMode), which is what a pipeline needs.
on_target() {
    if [ "$CI_ISLE_TARGET" = local ]; then bash -c "$1"
    else ssh -o BatchMode=yes -o ConnectTimeout="$CI_SSH_TIMEOUT" "$(device_ssh_dest)" "$1"; fi
}

# The target's pool (VM disks, seeds, the per-run key).
device_pool() {
    if [ -n "$CI_ISLE_POOL" ]; then echo "$CI_ISLE_POOL"
    elif [ "$CI_ISLE_TARGET" = local ]; then echo "${POLARI_POOL:-$DEVICE_DIR/pool}"
    else echo "/var/tmp/polari-ci-pool"; fi
}

device_load
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    case "${1:-print}" in
        --help|-h) sed -n '2,9p' "${BASH_SOURCE[0]}" ;;
        validate)  device_validate ;;
        *)         device_print ;;
    esac
fi
