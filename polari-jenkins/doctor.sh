#!/bin/bash
# polari-jenkins/doctor.sh — (B) of ci-7: "the configuration was set
# properly, and we warn the user if it is not and WHAT was not set up
# properly." Every check prints one line:
#
#   OK    <check> — <what is true>
#   WARN  <check> — <what is wrong> → <what to do>
#
# It NEVER refuses: exit 0 whatever it finds, so it can run at the end of
# `pol jenkins up` and `pol jenkins status` without breaking them.
# --strict exits non-zero on any WARN (for a pipeline stage or a gate).
# It reads; it changes nothing and prints no secret value.
#
#   doctor.sh [--strict] [--json] [--help]
#
# --json (ci-11a) prints ONE document, `polari-pipeline-doctor/1`, and
# nothing else on stdout: the same rows, machine-readable, each with its
# own fix. Every other line this script prints — its banner, its section
# headings, a tool's own chatter — is moved to stderr for the whole run,
# so "no stdout noise" is a property of the flag and not a promise each
# future check has to keep.
set -euo pipefail

J="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=device.sh
source "$J/device.sh"
# shellcheck source=secrets.sh
source "$J/secrets.sh"

STRICT=0; JSON=0
while [ $# -gt 0 ]; do
    case "$1" in
        --strict) STRICT=1 ;;
        --json) JSON=1 ;;
        --help|-h) sed -n '2,24p' "$0"; exit 0 ;;
        *) echo "doctor.sh: unknown argument '$1' (--strict --json --help)" >&2; exit 2 ;;
    esac; shift
done

DOC_ROWS=()
if [ "$JSON" = 1 ]; then exec 3>&1 1>&2; fi

WARNS=0
DOC_SECTION=""
DOC_US=$'\037'
doc_row() { DOC_ROWS+=("$1$DOC_US$DOC_SECTION$DOC_US$2$DOC_US$3$DOC_US${4:-}"); }
ok()   { printf 'OK    %-26s — %s\n' "$1" "$2"; doc_row OK "$1" "$2" ""; }
warn() { printf 'WARN  %-26s — %s → %s\n' "$1" "$2" "$3"; WARNS=$((WARNS+1)); doc_row WARN "$1" "$2" "$3"; }
sec()  { printf '\n-- %s\n' "$1"; DOC_SECTION="$1"; }

ME="$(id -un)"
echo "polari-jenkins doctor — what is configured, and what is not (read-only; it changes nothing)"
echo "device: $(device_target_name)   user: $ME   secrets posture: $(secrets_mode)"

# --------------------------------------------------- the checkout + CLI
# (added in ci-7b so `pol jenkins setup` reads these from the doctor
# instead of growing a second copy of them.)
sec "the checkout and the CLI"
SUITE="$(cd "$J/.." && pwd)"
MISSING_SUB=""
for s in polari-cli polari-rf-node political-scorecard-node polari-app-shell Isle-Mesh; do
    [ -d "$SUITE/$s" ] && [ -n "$(ls -A "$SUITE/$s" 2>/dev/null)" ] || MISSING_SUB="$MISSING_SUB $s"
done
[ -z "$MISSING_SUB" ] && ok "submodules" "all five populated (polari-cli, polari-rf-node, political-scorecard-node, polari-app-shell, Isle-Mesh)" \
    || warn "submodules" "not populated:$MISSING_SUB" "git -C $SUITE submodule update --init --recursive (or ./bootstrap-dev.sh)"
if command -v pol >/dev/null 2>&1; then
    POL_PATH="$(command -v pol)"
    # ci-11a: WHERE pol lives matters as soon as anything runs it elevated. A
    # `pol` under a user's own home is writable by that user, so running it as
    # root would let whoever owns that file choose what root does — an
    # escalation, not a convenience. install-cli.sh prefers /usr/local/bin and
    # only falls back to ~/.local/bin when it cannot write there; a device that
    # any front end will drive should be on the system-wide one.
    case "$POL_PATH" in
        "$HOME"/*) warn "pol CLI" "$POL_PATH — pol is installed under your home, so it is not a safe target for an elevated run (whoever can write that file would choose what root does)" \
                        "sudo bash $SUITE/polari-cli/shells/install-cli.sh   — it then links /usr/local/bin/pol" ;;
        *) ok "pol CLI" "$POL_PATH (system-wide — safe to run elevated)" ;;
    esac
else warn "pol CLI" "pol is not on PATH" "bash $SUITE/polari-cli/shells/install-cli.sh, then open a new shell"; fi
MISSING_TOOL=""
for t in docker python3 git curl whiptail; do command -v "$t" >/dev/null 2>&1 || MISSING_TOOL="$MISSING_TOOL $t"; done
[ -z "$MISSING_TOOL" ] && ok "host tools" "docker python3 git curl whiptail — all present" \
    || warn "host tools" "absent:$MISSING_TOOL" "sudo apt-get install -y$(echo "$MISSING_TOOL" | sed 's/ docker/ docker.io/') (docker: https://docs.docker.com/engine/install/ubuntu/)"

# ------------------------------------------------------------ device.env
sec "the pipeline device (device.env)"
while IFS='|' read -r key val status msg; do
    [ -n "$key" ] || continue
    case "$status" in
        OK)   ok "$key" "${val:-(empty)}${msg:+ — $msg}" ;;
        WARN) warn "$key" "${msg%% → *}" "${msg##* → }" ;;
        FAIL) warn "$key" "${msg%% → *}" "${msg##* → }" ;;
    esac
done < <(device_validate)

# ------------------------------------------- ci-8: where the settings live
# The `cicd` Polari app is the SOURCE OF TRUTH for everything above; this
# file is the fallback. The doctor only COMPARES — it promises to change
# nothing, so it never pulls (that is `pol jenkins sync pull`).
sec "the settings' source — the cicd app (Polari), with device.env as the fallback"
if [ -z "${CI_CORE_URL:-}" ]; then
    warn "cicd core" "CI_CORE_URL is empty — this device.env is the only truth there is" \
         "set CI_CORE_URL in device.env to the Polari instance that holds the pipeline settings, then pol jenkins sync push"
else
    if CORE_BODY=$(curl -fsS --max-time 8 "$CI_CORE_URL/api/cicd?device=$CI_DEVICE_NAME" 2>/dev/null); then
        if printf '%s' "$CORE_BODY" | grep -q '"ok": *true'; then
            CORE_ENV=$(printf '%s' "$CORE_BODY" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("device_env",""))' 2>/dev/null || true)
            HERE=$(grep -vE '^(#|$|CI_CORE_URL=)' "$DEVICE_ENV_FILE" 2>/dev/null | sort || true)
            THERE=$(printf '%s' "$CORE_ENV" | grep -vE '^(#|$|CI_CORE_URL=)' | sort || true)
            if [ "$HERE" = "$THERE" ]; then ok "cicd core" "$CI_CORE_URL — device.env matches the rows"
            else warn "cicd core" "$CI_CORE_URL answers, and its settings DIFFER from this device.env" \
                      "pol jenkins sync pull — Polari is the source of truth; this file follows"; fi
        else
            warn "cicd core" "$CI_CORE_URL has no PipelineDevice row for this device" \
                 "pol jenkins sync push — the first push ADOPTS this device's configuration as the first version of the truth"
        fi
    else
        # 404 from a core that IS up means the `cicd` module is not admitted there — a different problem
        # from a core that is down, and it has a different fix, so the two are never reported as one.
        CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 8 "$CI_CORE_URL/api/cicd" 2>/dev/null || echo 000)
        if [ "$CODE" = 404 ]; then
            warn "cicd module" "$CI_CORE_URL answers but has no /api/cicd — the cicd module is NOT admitted on that instance" \
                 "admit it: pol prod profile use pipeline-device --apply (its POL_PROD_MODULES ends in ,cicd), or add cicd to POL_PROD_MODULES / POLARI_LEAN_MODULES and redeploy"
        else
            ok "cicd core" "$CI_CORE_URL does not answer (HTTP $CODE) — the pipeline runs on this device.env and says so (never fatal)"
        fi
    fi
    if secrets_have "${CICD_TOKEN_SECRET:-polari/cicd_ingest_token}"; then
        ok "cicd credential" "polari/cicd_ingest_token present — the mirror can post runs and results"
    else
        warn "cicd credential" "polari/cicd_ingest_token absent — runs and isle results are not mirrored into Polari" \
             "an administrator mints it (POST $CI_CORE_URL/api/cicd/device/token, shown once), then: pol jenkins secrets put polari/cicd_ingest_token"
    fi
fi

# --------------------------------------------------------------- .env
sec "the controller (.env, compose)"
if [ -f "$J/.env" ]; then
    ok ".env" "present"
    PORT=$(grep -E '^JENKINS_PORT=' "$J/.env" | tail -1 | cut -d= -f2- || true)
    [ -n "$PORT" ] && ok "JENKINS_PORT" "$PORT" || warn "JENKINS_PORT" "not set in .env" "copy it from .env.example, or re-run pol jenkins up"
    DG=$(grep -E '^DOCKER_GID=' "$J/.env" | tail -1 | cut -d= -f2- || true)
    REAL=$(getent group docker 2>/dev/null | cut -d: -f3 || true)
    if [ -z "$REAL" ]; then warn "DOCKER_GID" "no docker group on this machine" "install docker — the jobs build images through the socket"
    elif [ "$DG" = "$REAL" ]; then ok "DOCKER_GID" "$DG matches the docker group"
    else warn "DOCKER_GID" ".env says '$DG', the docker group is $REAL" "set DOCKER_GID=$REAL in polari-jenkins/.env and pol jenkins restart"; fi
else
    warn ".env" "absent" "pol jenkins up writes it from .env.example"
    PORT=8080
fi

# port bound to loopback only
BIND=$(grep -oE '"127\.0\.0\.1:\$\{JENKINS_PORT[^"]*"' "$J/docker-compose.yml" || true)
[ -n "$BIND" ] && ok "port binding" "127.0.0.1 only (compose)" \
    || warn "port binding" "docker-compose.yml does not pin the port to 127.0.0.1" "restore the 127.0.0.1: prefix — this UI is never exposed"
if command -v ss >/dev/null 2>&1; then
    LISTEN=$(ss -ltn 2>/dev/null | awk -v p=":${PORT:-8080}\$" '$4 ~ p {print $4}' | sort -u | tr '\n' ' ' || true)
    if [ -z "$LISTEN" ]; then ok "listening" "nothing on port ${PORT:-8080} (controller down)"
    elif echo "$LISTEN" | grep -qE '(^| )(0\.0\.0\.0|\*|\[::\]):'; then
        warn "listening" "port ${PORT:-8080} is bound on ALL interfaces ($LISTEN)" "stop it and pol jenkins up — the compose file binds 127.0.0.1 only"
    else ok "listening" "$LISTEN"; fi
fi

# executors
CASC_EXEC=$(grep -E '^\s*numExecutors:' "$J/casc/jenkins.yaml" | head -1 | sed 's/.*numExecutors:\s*//' || true)
case "$CASC_EXEC" in
    *'${CI_EXECUTORS'*) ok "numExecutors" "casc follows CI_EXECUTORS (=$CI_EXECUTORS)" ;;
    "$CI_EXECUTORS")    ok "numExecutors" "$CASC_EXEC" ;;
    *) warn "numExecutors" "casc/jenkins.yaml says '$CASC_EXEC', device.env says CI_EXECUTORS=$CI_EXECUTORS" "make casc read \${CI_EXECUTORS:-1}, then pol jenkins restart" ;;
esac

# jenkins_home
sec "state directories"
for d in jenkins_home pool; do
    if [ -d "$J/$d" ]; then
        OWN=$(stat -c '%U:%G %a' "$J/$d")
        case "$(secrets_mode)" in
            system) [ "${OWN%%:*}" = "$CI_USER" ] && ok "$d" "$OWN" \
                        || warn "$d" "owned by $OWN, not $CI_USER" "sudo chown -R $CI_USER $J/$d — the controller runs as $CI_USER after init-device" ;;
            repo)   ok "$d" "$OWN (repo posture — the host user owns it)" ;;
        esac
    else
        warn "$d" "absent" "pol jenkins up creates it"
    fi
done

# --------------------------------------------------------------- secrets
sec "secrets — (C): reachable by sudo or the pipeline process, by nobody else"
SDIR="$(secrets_dir)"
if [ "$(secrets_mode)" = system ]; then
    ok "posture" "system — $SDIR (root:$CI_USER)"
    DOWN=$(stat -c '%U:%G %a' "$SDIR" 2>/dev/null || sudo -n stat -c '%U:%G %a' "$SDIR" 2>/dev/null || echo unknown)
    case "$DOWN" in
        "root:$CI_USER 750"|"root:$CI_USER 700") ok "secrets dir" "$DOWN" ;;
        unknown) warn "secrets dir" "cannot stat $SDIR" "sudo pol jenkins doctor" ;;
        *) warn "secrets dir" "$SDIR is $DOWN" "sudo chown root:$CI_USER $SDIR && sudo chmod 0750 $SDIR" ;;
    esac
    # the invoking human must NOT be able to read a secret without sudo
    LEAK=0; N=0
    while read -r rel; do
        [ -n "$rel" ] || continue; N=$((N+1))
        [ -r "$SDIR/$rel" ] && LEAK=$((LEAK+1))
    done < <(secrets_list)
    if [ "$ME" = "$CI_USER" ] || [ "$(id -u)" = 0 ]; then
        ok "readability test" "running as $ME — reading them IS the sanctioned path"
    elif [ "$LEAK" = 0 ]; then
        ok "readability test" "$N secret(s); user $ME cannot read any without sudo"
    else
        warn "readability test" "$LEAK of $N secret(s) are readable by $ME without sudo" \
             "sudo chmod 0640 $SDIR/* and remove $ME from the $CI_USER group (groups $ME)"
    fi
    if id -nG "$ME" 2>/dev/null | tr ' ' '\n' | grep -qx "$CI_USER"; then
        warn "$CI_USER group" "$ME is in the $CI_USER group — every process they run can read the secrets" \
             "sudo gpasswd -d $ME $CI_USER; the pipeline runs as $CI_USER, a person uses sudo"
    else
        ok "$CI_USER group" "$ME is not a member (members: $(getent group "$CI_USER" 2>/dev/null | cut -d: -f4 || true))"
    fi
else
    warn "posture" "REPO — secrets are readable by every process of user $ME ($CI_SECRETS_REPO)" \
         "sudo pol jenkins init-device — it creates the $CI_USER user and moves them to $CI_SECRETS_SYSTEM (root:$CI_USER 0640)"
    BAD=$(find "$CI_SECRETS_REPO" -mindepth 2 -type f ! -name '*.example' ! -name '.gitkeep' ! -name 'README.md' ! -name 'ROTATION.log' ! -perm 600 2>/dev/null | wc -l || true)
    [ "$BAD" = 0 ] && ok "modes" "every secret is 0600" \
        || warn "modes" "$BAD secret file(s) are not 0600" "chmod 0600 $CI_SECRETS_REPO/*/*"
fi
LEAKED=$( { git -C "$J/.." status --porcelain polari-jenkins/secrets 2>/dev/null || true; } | grep -vcE '\.example|README|\.gitkeep' || true)
[ "$LEAKED" = 0 ] && ok "git" "no real secret is visible to git" \
    || warn "git" "$LEAKED real secret file(s) under polari-jenkins/secrets are visible to git" "move them: pol jenkins secrets put <area>/<name>"

# routes armed vs dry
sec "publication routes — ARMED (publishes for real) vs DRY (renders only)"
for r in $SECRETS_ACTIVE_ROUTES; do
    need=$(secrets_route_requires "$r"); miss=""
    for s in $need; do secrets_have "$s" || miss="$miss $s"; done
    inlist=0; for c in ${CI_ROUTES//,/ }; do [ "$c" = "$r" ] && inlist=1; done
    if [ "$inlist" = 0 ]; then ok "route $r" "DRY (not in CI_ROUTES)"
    elif [ -n "$miss" ]; then ok "route $r" "DRY (secret absent:$miss)"
    else ok "route $r" "ARMED — a release WILL publish to it"; fi
done
ok "routes parked" "$SECRETS_PARKED_ROUTES (routes/later/ — they need an outside account)"

# --------------------------------------------------------------- docker
sec "the docker socket — membership is root-equivalent"
MEMBERS=$(getent group docker 2>/dev/null | cut -d: -f4 || true)
if [ -z "$MEMBERS" ]; then ok "docker group" "no members beyond root"
else
    N=$(echo "$MEMBERS" | tr ',' '\n' | grep -c . || true)
    if [ "$N" -le 2 ]; then ok "docker group" "$MEMBERS ($N member(s); membership is root-equivalent)"
    else warn "docker group" "$MEMBERS — $N members, and docker-group membership is root-equivalent on this machine" \
              "leave the $CI_USER user and ONE admin in it: sudo gpasswd -d <user> docker"; fi
fi
# …and whether the invoking human can actually use it (every build goes through it)
if [ "$(id -u)" = 0 ] || id -nG "$ME" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
    ok "your docker access" "$ME can talk to the docker socket"
else
    warn "your docker access" "$ME is not in the docker group — no build can run as $ME" \
         "sudo usermod -aG docker $ME, then log out and back in (membership is read at login)"
fi

# ------------------------------------------------------ virtualisation
sec "virtualisation on this machine"
if [ -e /dev/kvm ]; then
    ok "/dev/kvm" "present"
    NEST=$(cat /sys/module/kvm_intel/parameters/nested /sys/module/kvm_amd/parameters/nested 2>/dev/null | head -1 || true)
    case "$NEST" in
        Y|1) ok "nested KVM" "$NEST — a router guest can run inside the throwaway VM" ;;
        *)   warn "nested KVM" "nested is '${NEST:-unreadable}'" "options kvm_intel nested=1 in /etc/modprobe.d, reload the module — or put the isle on a device that has it" ;;
    esac
else
    if [ "$CI_ISLE_TARGET" = local ]; then
        warn "/dev/kvm" "absent, and CI_ISLE_TARGET=local — the throwaway isle cannot be created here" \
             "pol jenkins target ssh <alias> to put the isle on a device with KVM"
    else
        ok "/dev/kvm" "absent here, but the isle target is $(device_target_name)"
    fi
fi
command -v virsh >/dev/null 2>&1 && ok "libvirt client" "virsh present" \
    || { [ "$CI_ISLE_TARGET" = local ] && warn "libvirt client" "virsh absent and the isle target is local" "apt install libvirt-clients virtinst qemu-utils cloud-image-utils" \
         || ok "libvirt client" "not needed here (the isle target is remote)"; }

# ------------------------------------------------------- the ssh target
if [ "$CI_ISLE_TARGET" = ssh ]; then
    sec "the isle device over ssh"
    if [ -z "$CI_ISLE_SSH_HOST" ]; then
        warn "ssh target" "CI_ISLE_TARGET=ssh with no alias" "pol jenkins target ssh <alias>"
    elif out=$(on_target 'echo ok' 2>&1) && [ "$out" = ok ]; then
        ok "ssh target" "$(device_ssh_dest) reachable (BatchMode — no prompt)"
        if on_target 'sudo -n true' >/dev/null 2>&1; then ok "target sudo -n" "passwordless"
        else warn "target sudo -n" "the target asks for a sudo password" "a job cannot answer a prompt — grant NOPASSWD for the libvirt commands on that device"; fi
        on_target '[ -e /dev/kvm ]' >/dev/null 2>&1 && ok "target /dev/kvm" "present" \
            || warn "target /dev/kvm" "the isle device has no /dev/kvm" "choose a device with hardware virtualisation"
        TMISS=""
        for t in virt-install qemu-img virsh; do
            on_target "command -v $t >/dev/null" >/dev/null 2>&1 || TMISS="$TMISS $t"
        done
        on_target 'command -v cloud-localds >/dev/null || command -v genisoimage >/dev/null' >/dev/null 2>&1 || TMISS="$TMISS cloud-localds"
        [ -z "$TMISS" ] && ok "target libvirt" "virt-install qemu-img virsh + a cloud-init seed tool — all present" \
            || warn "target libvirt" "absent on $(device_ssh_dest):$TMISS" \
                    "ssh $(device_ssh_dest) 'sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients virtinst qemu-utils cloud-image-utils'"
    else
        warn "ssh target" "$(device_ssh_dest) is not reachable with BatchMode ssh (${out//$'\n'/ })" \
             "add a Host entry and a key: ssh-copy-id <alias>"
    fi
fi

# ---------------------------------------------------------- the network
sec "network"
WIRED=""; WIFI=""
if command -v ip >/dev/null 2>&1; then
    while read -r ifn; do
        [ -n "$ifn" ] || continue
        case "$ifn" in lo|docker*|br-*|veth*|virbr*|tun*|tap*) continue ;; esac
        addr=$(ip -4 -o addr show dev "$ifn" 2>/dev/null | awk '{print $4}' | head -1)
        [ -n "$addr" ] || continue
        if [ -d "/sys/class/net/$ifn/wireless" ] || [ -e "/sys/class/net/$ifn/phy80211" ]; then WIFI="$WIFI $ifn"; else WIRED="$WIRED $ifn"; fi
    done < <(ls /sys/class/net 2>/dev/null)
fi
if [ -n "$WIRED" ]; then ok "wired IPv4" "on$WIRED"
elif [ -n "$WIFI" ]; then warn "wired IPv4" "only a wireless interface carries an address ($WIFI) — builds will pull over Wi-Fi" \
        "plug the device in: a release build pulls gigabytes and a dropped Wi-Fi link fails the run"
else warn "wired IPv4" "no interface carries an IPv4 address" "the poller cannot reach GitHub"; fi

if git -C "$J/.." ls-remote --exit-code origin HEAD >/dev/null 2>&1; then
    ok "git origin" "reachable — polling works (public repos need no token)"
else
    warn "git origin" "git ls-remote of the superproject failed" "check the network, or put a read token in place — the jobs poll GitHub over https"
fi

# ------------------------------------------- ci-9: the offline-first cache
# His ask 2026-09-19: "the jenkins pipeline should try and use offline
# artifacts for building where possible". The cache is an OPTIMISATION — every
# row here is a WARN at worst, because a cache problem must slow a build down,
# never stop one.
sec "the offline cache — build once, reuse (ci-9)"
# shellcheck source=cache.sh
source "$J/cache.sh"
if ! cache_on; then
    warn "cache" "CI_CACHE=off — every build re-downloads its wheels, npm packages, debs and base images" \
         "set CI_CACHE=on in polari-jenkins/device.env (it is the default)"
else
    CROOT="$(cache_root)"
    if [ -d "$CROOT" ]; then
        CUSED="$(cache_size_gb)"
        if awk -v u="${CUSED:-0}" -v m="${CI_CACHE_MAX_GB:-40}" 'BEGIN{exit !(u+0 > m+0)}'; then
            warn "cache size" "$CUSED GB, over the ${CI_CACHE_MAX_GB} GB budget (CI_CACHE_MAX_GB)" \
                 "pol jenkins cache prune --older-than 30, or raise CI_CACHE_MAX_GB knowingly"
        else
            ok "cache size" "$CUSED GB of a ${CI_CACHE_MAX_GB} GB budget — $CROOT"
        fi
    else
        ok "cache" "nothing cached yet ($CROOT) — the first build fills it"
    fi
    CPOOL="${POLARI_POOL:-$J/pool}"
    CLATEST=$(ls -1 "$CPOOL" 2>/dev/null | grep -E '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}' | sort -V | tail -1 || true)
    if [ -n "$CLATEST" ] && [ -f "$CPOOL/$CLATEST/cache-report.json" ]; then
        ok "cache hit rate" "$(python3 "$J/cache-manifest.py" report-show "$CPOOL/$CLATEST/cache-report.json" 2>/dev/null | head -1)"
    else
        ok "cache hit rate" "no cache-report.json yet — every build stage writes one; until a real run the savings are EXPECTED, not measured"
    fi
    if cache_proxies_on; then
        PANS=""; for P in "$CACHE_PROXY_REG_PORT" "$CACHE_PROXY_PIP_PORT" "$CACHE_PROXY_NPM_PORT" "$CACHE_PROXY_APT_PORT"; do
            curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$P/" 2>/dev/null && PANS="$PANS $P"
        done
        [ -n "$PANS" ] && ok "cache proxies" "tier two answering on 127.0.0.1:$PANS" \
            || warn "cache proxies" "CI_CACHE_PROXIES=on but none of them answers" \
                    "pol jenkins cache proxies up (or set CI_CACHE_PROXIES=off — tier one alone is the default and works)"
    else
        ok "cache proxies" "tier two off (the default) — tier one is a directory and needs nothing running"
    fi
fi

# ------------------------------- ci-9: app mode, and the core it is tested against
if [ "$CI_MODE" = app ]; then
    sec "app mode — ONE app, a pulled core, YOUR routes"
    [ -n "$CI_APP_NAME" ] && ok "CI_APP_NAME" "$CI_APP_NAME" \
        || warn "CI_APP_NAME" "app mode maintains ONE app but names none" "pol jenkins setup --step role"
    [ -n "$CI_APP_REPO" ] && ok "CI_APP_REPO" "$CI_APP_REPO" \
        || warn "CI_APP_REPO" "no repository for ${CI_APP_NAME:-the app} — the pipeline has nothing to build it from" "pol jenkins setup --step role"
    case "$CI_CORE_SOURCE" in
        build)
            ok "core source" "INFO: you are rebuilding core; releases of your app are tested against that build, not an official release" ;;
        release:*)
            if RESOLVED=$(bash "$J/isle/core-artifacts.sh" resolve 2>/dev/null) && [ -n "$RESOLVED" ]; then
                ok "core source" "$CI_CORE_SOURCE → $RESOLVED (fetched once into the cache: bash polari-jenkins/isle/core-artifacts.sh fetch)"
            else
                warn "core source" "$CI_CORE_SOURCE does not resolve — no network, or no published release by that name (${CI_CORE_SOURCE#release:})" \
                     "check the tag against github.com/dausume/polari-suite/releases, or set CI_CORE_SOURCE=build knowingly"
            fi ;;
    esac
fi

# ------------------------------------------------------------ the pool
sec "the pool"
if FREE=$(POLARI_POOL="$J/pool" DISK_MIN_FREE_GB="$CI_MIN_FREE_GB" bash "$J/retention.sh" guard 2>&1); then
    ok "pool floor" "$(echo "$FREE" | tail -1)"
else
    warn "pool floor" "$(echo "$FREE" | tail -1)" "bash polari-jenkins/retention.sh prune, or lower CI_MIN_FREE_GB knowingly"
fi

# ------------------------------------------ what may be RELEASED at all
# The release rule (his ask 2026-09-19): the pipeline only generates
# artifacts for things it TESTED in a throwaway isle. So "can this device
# run an isle test at all?" decides whether anything can ever be published.
sec "isle testing stages — only what is TESTED is ever released"
stages_print
CAN_TEST=1; WHYNOT=""
if [ "$CI_ISLE_TARGET" = ssh ]; then
    [ -n "$CI_ISLE_SSH_HOST" ] || { CAN_TEST=0; WHYNOT="CI_ISLE_TARGET=ssh with no alias"; }
elif [ ! -e /dev/kvm ]; then
    CAN_TEST=0; WHYNOT="the target is this machine and it has no /dev/kvm"
fi
if [ "$CAN_TEST" = 1 ]; then ok "isle target for tests" "$(device_target_name) can host a throwaway isle (pol jenkins preflight --isle proves it)"
else warn "isle target for tests" "$WHYNOT — NOTHING can be released until an isle target exists" \
          "pol jenkins target ssh <alias> (a device with /dev/kvm + libvirt), then pol jenkins preflight --isle"; fi
LATEST=$(ls -1 "$J/pool" 2>/dev/null | grep -E '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}' | sort -V | tail -1 || true)

# ------------------------------------------ ci-12: the branch model
# dev iterate · test decide · main release. Three rows: where each branch is,
# what the newest test verdict said, and what the two poll queues are holding.
sec "the branch model — dev iterate · test decide · main release (ci-12)"
_remote_sha(){ git -C "$J/.." ls-remote origin "refs/heads/$1" 2>/dev/null | awk '{print $1}' | head -1; }
BR_DEV=$(_remote_sha dev); BR_TEST=$(_remote_sha test); BR_MAIN=$(_remote_sha main)
if [ -z "$BR_TEST" ]; then
    warn "branch test" "origin/test does not exist yet — nothing can be tested, and so nothing can ever be released" \
         "pol jenkins promote test   (it fast-forwards every repo in the forest from dev, innermost-first)"
else
    ok "branch test" "origin/test ${BR_TEST:0:12}$([ "$BR_TEST" = "$BR_DEV" ] && echo ' (== dev)' || echo ' (dev has moved on)')"
fi
if [ -z "$BR_MAIN" ]; then
    warn "branch main" "origin/main does not exist" "pol jenkins promote main (it refuses without a passed test verdict)"
elif [ "$BR_MAIN" = "$BR_TEST" ]; then
    ok "branch main" "origin/main ${BR_MAIN:0:12} == test — everything tested has been released"
else
    ok "branch main" "origin/main ${BR_MAIN:0:12} — test is ahead; pol jenkins promote main when its verdict passes"
fi
VJ=""; [ -n "$BR_TEST" ] && VJ="$J/pool/test/$BR_TEST/verdict.json"
if [ -z "$VJ" ] || [ ! -f "$VJ" ]; then
    warn "test verdict" "no verdict recorded for the tip of test${BR_TEST:+ (${BR_TEST:0:12})} — main may not be promoted" \
         "let polari-test run (it polls test every 5 min), then: pol jenkins test-status"
else
    VERD=$(python3 -c 'import json,sys
d=json.load(open(sys.argv[1])); print("%s|%s" % (d.get("verdict","?"), (d.get("why") or "")[:110]))' "$VJ" 2>/dev/null || echo "unreadable|")
    IFS='|' read -r VV VWHY <<<"$VERD"
    case "$VV" in
        passed) ok "test verdict" "${BR_TEST:0:12} PASSED — pol jenkins promote main may proceed" ;;
        partial) warn "test verdict" "${BR_TEST:0:12} PARTIAL — $VWHY" \
                 "a partial verdict does not release. pol jenkins test-status shows every reading it is made of" ;;
        *) warn "test verdict" "${BR_TEST:0:12} $VV — $VWHY" "pol jenkins test-status ${BR_TEST:0:12}" ;;
    esac
fi
QLINE=$(bash "$J/quiet.sh" queue 2>/dev/null | head -4 | tr '\n' ' ' | tr -s ' ' || true)
ok "queue" "${QLINE:-both queues idle} (one item deep, latest wins — no backlog can form)"

# ------------------------------------------ the isle results the verdict reads
if [ -z "$BR_TEST" ]; then
    ok "isle-test results" "no test branch yet — the first pol jenkins promote test creates it"
elif [ -f "$J/pool/test/$BR_TEST/isle-test/results.json" ]; then
    ok "isle-test results" "the tip of test has isle results — the verdict can be computed from them"
else
    warn "isle-test results" "the tip of test has no isle-test/results.json — the verdict will be 'partial' at best" \
         "let polari-test run (it triggers polari-isle-test with VERSION=test/<sha>)"
fi

# ---------------------------------- ci-10: the teardown, in its two layers
# 1. did the PRODUCT hand the machine back?  (uninstall_verdict — a test result)
# 2. did OUR pipeline leave anything behind?  (leak_verdict — a resource guard)
# Both are read from the NEWEST results the pool carries; neither is re-derived.
# ci-12: the newest readings now live under the TEST branch's run, not under a
# release version — that is where the tests happen. The release pool is used as
# a fallback for a device that still carries pre-ci-12 runs.
ITDIR=""
if [ -n "$BR_TEST" ] && [ -d "$J/pool/test/$BR_TEST/isle-test" ]; then ITDIR="$J/pool/test/$BR_TEST/isle-test"
elif [ -n "$LATEST" ]; then ITDIR="$J/pool/$LATEST/isle-test"; fi
NEWEST_LEAK=$(ls -1t "$ITDIR"/leak-check-*.json 2>/dev/null | head -1 || true)
if [ -z "$NEWEST_LEAK" ]; then
    ok "leak check" "no leak check recorded yet — the first isle-test run takes a baseline and diffs every stage against it"
else
    LV=$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print("%s|%d|%+d|%+d" % (d.get("verdict","?"), len(d.get("leaks",[])), d.get("ram_delta_mb",0), d.get("disk_delta_mb",0)))' "$NEWEST_LEAK" 2>/dev/null || echo "unreadable|0|0|0")
    IFS='|' read -r LVERD LN LRAM LDISK <<<"$LV"
    if [ "$LVERD" = clean ]; then
        ok "leak check" "$(basename "$NEWEST_LEAK"): CLEAN — RAM $LRAM MB, images-dir disk $LDISK MB back to the baseline"
    else
        warn "leak check" "$(basename "$NEWEST_LEAK"): $LVERD — $LN thing(s) survived the wipe (RAM $LRAM MB, disk $LDISK MB)" \
             "pol jenkins isle leakcheck report, then pol jenkins isle wipe — the next stage would otherwise start on a dirty host"
    fi
fi
if [ -n "$ITDIR" ] && [ -f "$ITDIR/results.json" ]; then
    UV=$(python3 -c 'import json,sys
d=json.load(open(sys.argv[1])); s=(d.get("stages") or [{}])[0]
print("%s|%s" % (s.get("uninstall_verdict","(not recorded)"), "; ".join(s.get("uninstall_findings") or [])[:120]))' "$ITDIR/results.json" 2>/dev/null || echo "(unreadable)|")
    IFS='|' read -r UVERD UWHY <<<"$UV"
    case "$UVERD" in
        clean) ok "isle uninstall (the product's own)" "stage 1: CLEAN — isle uninstall --everything handed the machine back, so this core MAY be released" ;;
        skipped) ok "isle uninstall (the product's own)" "stage 1: skipped — nothing was installed in the guest (the ci-3 install cycle is not built), so core_ok stays false" ;;
        *) warn "isle uninstall (the product's own)" "stage 1: $UVERD${UWHY:+ — $UWHY}" \
                "this is a FAILURE OF THE PRODUCT, not of the pipeline: an isle that cannot hand the machine back is not releasable (routes/_lib.sh)" ;;
    esac
fi

echo
if [ "$WARNS" = 0 ]; then echo "doctor: everything checked is set up properly."
else echo "doctor: $WARNS warning(s) above — each says what is wrong and what to do. (Nothing was changed.)"; fi

if [ "$JSON" = 1 ]; then
    exec 1>&3 3>&-
    { printf '%s\n' "$WARNS" "$(device_target_name)" "$ME" "$(secrets_mode)" "$CI_MODE"
      printf '%s\n' "${DOC_ROWS[@]:-}"; } | python3 -c '
import json, sys
L = sys.stdin.read().split("\n")
warns, target, user, posture, mode = L[0], L[1], L[2], L[3], L[4]
US = "\x1f"
rows = []
for line in L[5:]:
    if not line.strip():
        continue
    f = (line.split(US) + [""] * 5)[:5]
    rows.append(dict(zip(("verdict", "section", "check", "message", "fix"), f)))
print(json.dumps({"protocol": "polari-pipeline-doctor/1", "kind": "doctor",
                  "device": {"target": target, "user": user, "secrets_posture": posture, "mode": mode},
                  "warns": int(warns or 0), "rows": rows}, indent=1))'
fi
[ "$STRICT" = 1 ] && [ "$WARNS" -gt 0 ] && exit 1
exit 0
