#!/usr/bin/env bash
# switch-to-dev.sh — Switch every repo in the suite to the dev branch
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# ── Per-repo summary accumulators ────────────────────────────────────────
declare -a SUMMARY=()

switch_to_dev() {
    local repo_path="$1"
    local name="$2"

    info "── $name ──"
    cd "$repo_path"

    # Stash uncommitted changes if any
    if ! git diff --quiet || ! git diff --cached --quiet; then
        warn "$name: stashing uncommitted changes"
        git stash push -m "env-management: auto-stash before switching to dev"
    fi

    # Ensure we know about remote branches
    git fetch origin --quiet

    if git show-ref --verify --quiet refs/heads/dev; then
        # Local dev branch exists
        git checkout dev
        git pull origin dev
        SUMMARY+=("$name: switched to dev (local branch existed)")
    elif git show-ref --verify --quiet refs/remotes/origin/dev; then
        # Remote dev exists but no local tracking branch yet
        git checkout -b dev origin/dev
        SUMMARY+=("$name: switched to dev (created from origin/dev)")
    else
        # No dev branch anywhere — create from main
        warn "$name: no remote dev branch found, creating dev from main"
        git checkout -b dev
        SUMMARY+=("$name: switched to dev (created new branch from main)")
    fi

    success "$name is now on dev"
}

# ── Main ─────────────────────────────────────────────────────────────────
info "Switching all repos to dev..."
echo

run_in_each_repo switch_to_dev

echo
info "═══ Summary ═══"
for line in "${SUMMARY[@]}"; do
    success "$line"
done
