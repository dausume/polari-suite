#!/usr/bin/env bash
# quick-commit.sh — Add, commit, and push across all repos in the suite
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# ── Get commit message ───────────────────────────────────────────────────
COMMIT_MSG="${1:-}"
if [[ -z "$COMMIT_MSG" ]]; then
    read -rp "Enter commit message: " COMMIT_MSG
    if [[ -z "$COMMIT_MSG" ]]; then
        error "Commit message cannot be empty."
        exit 1
    fi
fi

# ── Per-repo summary accumulators ────────────────────────────────────────
declare -a SUMMARY=()

commit_and_push() {
    local repo_path="$1"
    local name="$2"

    info "── $name ──"
    cd "$repo_path"

    local branch
    branch="$(git rev-parse --abbrev-ref HEAD)"

    git add .

    if git diff --cached --quiet; then
        SUMMARY+=("$name ($branch): clean — nothing to commit")
        info "$name: nothing to commit"
    else
        git commit -m "$COMMIT_MSG"
        git push origin "$branch"
        SUMMARY+=("$name ($branch): committed and pushed")
        success "$name: committed and pushed to $branch"
    fi
}

# ── Main ─────────────────────────────────────────────────────────────────
info "Quick commit across all repos: \"$COMMIT_MSG\""
echo

run_in_each_repo commit_and_push

echo
info "═══ Summary ═══"
for line in "${SUMMARY[@]}"; do
    success "$line"
done
