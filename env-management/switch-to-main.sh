#!/usr/bin/env bash
# switch-to-main.sh — Switch every repo in the suite to the main branch
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# ── Per-repo summary accumulators ────────────────────────────────────────
declare -a SUMMARY=()

switch_to_main() {
    local repo_path="$1"
    local name="$2"

    info "── $name ──"
    cd "$repo_path"

    # Stash uncommitted changes if any
    if ! git diff --quiet || ! git diff --cached --quiet; then
        warn "$name: stashing uncommitted changes"
        git stash push -m "env-management: auto-stash before switching to main"
        SUMMARY+=("$name: switched to main (changes stashed)")
    else
        SUMMARY+=("$name: switched to main (clean)")
    fi

    git checkout main
    git pull origin main
    success "$name is now on main"
}

# ── Main ─────────────────────────────────────────────────────────────────
info "Switching all repos to main..."
echo

run_in_each_repo switch_to_main

echo
info "═══ Summary ═══"
for line in "${SUMMARY[@]}"; do
    success "$line"
done
