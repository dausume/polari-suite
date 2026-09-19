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

DEVICE_KEYS="CI_ISLE_TARGET CI_ISLE_SSH_HOST CI_ISLE_SSH_USER CI_ISLE_VM_NAME CI_ISLE_VM_RAM_GB \
CI_ISLE_VM_VCPUS CI_ISLE_VM_DISK_GB CI_ISLE_NESTED CI_ISLE_POOL CI_ISLE_IMAGE_URL \
CI_MIN_FREE_GB CI_MIN_RAM_HEADROOM_GB CI_EXECUTORS CI_ROUTES CI_ISLE_STAGES"

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
    : "${CI_MIN_FREE_GB:=20}"
    : "${CI_MIN_RAM_HEADROOM_GB:=1}"
    : "${CI_EXECUTORS:=1}"
    : "${CI_ROUTES:=github-release,ghcr,homebrew,apt-repo}"
    : "${CI_ISLE_STAGES:=core}"
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

    [ "${CI_EXECUTORS:-1}" = 1 ] || _row CI_EXECUTORS "$CI_EXECUTORS" WARN \
        "more than one executor on a home box overlaps builds → set CI_EXECUTORS=1"

    device_validate_stages
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
