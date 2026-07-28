#!/bin/bash
# push-dev.sh — push every repo's dev branch, innermost-first.
# Usage:  ./push-dev.sh            (pushes)
#         ./push-dev.sh --dry-run  (shows what WOULD push, touches nothing)
#
# Safety per repo before anything pushes: must be ON dev, working tree
# clean (submodule-pointer drift 'm' entries ignored), and dev must
# fast-forward origin (never a force push). Stops on the first failure.
set -e
cd "$(dirname "$0")"
DRY=""
[ "${1:-}" = "--dry-run" ] && DRY=1

# Innermost-first: leaf submodules -> mid-level -> superproject.
REPOS=(
    polari-rf-node/polari-framework
    polari-rf-node/polari-platform-angular
    political-scorecard-node/political-scorecard-frontend
    political-scorecard-node/political-scorecard-backend
    polari-cli
    polari-rf-node
    political-scorecard-node
    .
)

echo "== preflight =="
for r in "${REPOS[@]}"; do
    [ -d "$r/.git" ] || [ -f "$r/.git" ] || { echo "  $r: not a git repo (skipping)"; continue; }
    b=$(git -C "$r" branch --show-current)
    [ "$b" = "dev" ] || { echo "ABORT: $r is on '$b', not dev"; exit 1; }
    if git -C "$r" status --short | grep -qv '^ m'; then
        echo "ABORT: $r has uncommitted changes:"; git -C "$r" status --short | grep -v '^ m'; exit 1
    fi
    git -C "$r" fetch origin dev >/dev/null 2>&1 || true
    if git -C "$r" rev-parse --verify origin/dev >/dev/null 2>&1; then
        behind=$(git -C "$r" rev-list --count dev..origin/dev)
        [ "$behind" = "0" ] || { echo "ABORT: $r — origin/dev has $behind commits we don't (pull/rebase first, never force)"; exit 1; }
        ahead=$(git -C "$r" rev-list --count origin/dev..dev)
    else
        ahead="(new branch on origin)"
    fi
    echo "  $r: dev ok, clean, ahead of origin by $ahead"
done

echo
echo "== push (innermost-first) =="
for r in "${REPOS[@]}"; do
    [ -d "$r/.git" ] || [ -f "$r/.git" ] || continue
    if [ -n "$DRY" ]; then
        echo "  DRY: git -C $r push origin dev"
    else
        echo "  pushing $r ..."
        git -C "$r" push origin dev
    fi
done
echo
[ -n "$DRY" ] && echo "dry run — nothing pushed." || echo "all dev branches pushed."
