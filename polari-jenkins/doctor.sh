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
#   doctor.sh [--strict] [--help]
set -euo pipefail

J="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=device.sh
source "$J/device.sh"
# shellcheck source=secrets.sh
source "$J/secrets.sh"

STRICT=0
while [ $# -gt 0 ]; do
    case "$1" in
        --strict) STRICT=1 ;;
        --help|-h) sed -n '2,16p' "$0"; exit 0 ;;
        *) echo "doctor.sh: unknown argument '$1' (--strict --help)" >&2; exit 2 ;;
    esac; shift
done

WARNS=0
ok()   { printf 'OK    %-26s — %s\n' "$1" "$2"; }
warn() { printf 'WARN  %-26s — %s → %s\n' "$1" "$2" "$3"; WARNS=$((WARNS+1)); }
sec()  { printf '\n-- %s\n' "$1"; }

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
if command -v pol >/dev/null 2>&1; then ok "pol CLI" "$(command -v pol)"
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
if [ -z "$LATEST" ]; then
    ok "isle-test results" "no release built yet — the first polari-release run mints a version"
elif [ -f "$J/pool/$LATEST/isle-test/results.json" ]; then
    ok "isle-test results" "$LATEST has results — the release rule can decide what to publish"
else
    warn "isle-test results" "$LATEST has no isle-test/results.json — every route stays DRY and the tag is not pushed" \
         "run the polari-isle-test job for $LATEST (the pipeline only releases what it tested)"
fi

echo
if [ "$WARNS" = 0 ]; then echo "doctor: everything checked is set up properly."
else echo "doctor: $WARNS warning(s) above — each says what is wrong and what to do. (Nothing was changed.)"; fi
[ "$STRICT" = 1 ] && [ "$WARNS" -gt 0 ] && exit 1
exit 0
