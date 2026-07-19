#!/bin/bash
# Shared helpers for the module-projects batch scripts (mp-2/mp-4).
# Every state-changing command is ECHOED before it runs so the batch
# is auditable; scripts stop on first failure.
set -euo pipefail

SUITE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FW="$SUITE_ROOT/polari-rf-node/polari-framework"
RF="$SUITE_ROOT/polari-rf-node"
GH_OWNER=dausume
export LOCAL_IP=${LOCAL_IP:-192.168.0.210}

BOLD=$'\033[1m'; CYAN=$'\033[0;36m'; RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; NC=$'\033[0m'

say()  { echo "${BOLD}== $*${NC}"; }
run()  { echo "${CYAN}RUN:${NC} $*"; "$@"; }
die()  { echo "${RED}FAIL:${NC} $*" >&2; exit 1; }
ok()   { echo "${GREEN}OK:${NC} $*"; }

confirm() {
    read -r -p "$1 [y/N] " a
    [ "$a" = "y" ] || [ "$a" = "Y" ] || die "aborted by user"
}

need_clean_fw() {
    [ -z "$(git -C "$FW" status --porcelain)" ] \
        || die "polari-framework working tree is not clean — commit or stash first (git -C $FW status)"
}

# Move one module into modules/ and update the register's path.
move_module() {
    local m=$1
    [ -d "$FW/$m" ] || { [ -d "$FW/modules/$m" ] && ok "$m already in modules/" && return 0; die "no $m/ directory at the framework root"; }
    run git -C "$FW" mv "$m" "modules/$m"
    run pol modules register "$m" --path "modules/$m"
}

# Rebuild the staging backend with the moved code + restart the proxy
# (stale nginx upstream after a backend recreate = 502, known gotcha).
# ALWAYS --env-file .generated/.env.staging: a recreate without it
# loses the MariaDB credentials (1045 Access denied at boot).
rebuild_backend() {
    say "rebuilding prf-backend (staging) with the new layout"
    [ -f "$SUITE_ROOT/.generated/.env.staging" ] || die "no .generated/.env.staging — pol security setup / pol suite up first"
    run docker compose --env-file "$SUITE_ROOT/.generated/.env.staging" \
        -f "$SUITE_ROOT/docker-compose.staging-nip.yml" up -d --build --no-deps prf-backend
    run docker restart pol-proxy
    say "waiting for the backend to serve (cold seed can take minutes)"
    local i=0
    until docker exec prf-backend python3 -c \
        "import urllib.request as u; u.urlopen('http://localhost:3000/modules', timeout=3)" 2>/dev/null; do
        docker logs prf-backend 2>&1 | grep -q Traceback \
            && die "backend boot traceback — docker logs prf-backend"
        i=$((i+5)); [ $i -gt 900 ] && die "backend did not serve within 15m"
        sleep 5
    done
    ok "backend serving"
}

# Run one module's selftests in-container; fails the batch on red.
selftest_module() {
    local m=$1
    if docker exec prf-backend sh -c "ls modules/$m/selftest_*.py >/dev/null 2>&1 || ls $m/selftest_*.py >/dev/null 2>&1"; then
        run pol modules selftest "$m"
    else
        ok "$m has no selftest suites (nothing to run)"
    fi
}

# Innermost-first commit reminder (framework -> rf-node -> suite).
print_pointer_commits() {
    cat <<EOF

${BOLD}Submodule pointers (run when you are happy with this wave):${NC}
  git -C $RF add polari-framework && git -C $RF commit -m "$1"
  git -C $SUITE_ROOT add polari-rf-node && git -C $SUITE_ROOT commit -m "$1"
EOF
}
