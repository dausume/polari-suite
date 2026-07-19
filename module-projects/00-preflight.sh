#!/bin/bash
# Preflight for the module-projects batches: verifies every tool,
# auth, and repo state the later scripts depend on. Read-only.
source "$(dirname "$0")/lib.sh"

say "polari-framework state"
git -C "$FW" status -sb | head -3
[ -z "$(git -C "$FW" status --porcelain)" ] \
    && ok "framework tree clean" \
    || echo "${RED}framework tree NOT clean — commit the review-gate work first${NC}"

say "pol CLI"
command -v pol >/dev/null || die "pol not installed (polari-cli/shells/install-cli.sh)"
pol modules registry >/dev/null || die "pol modules registry failed"
ok "pol modules registry reads"

say "git subtree availability"
# (usage text exits 129 — presence of the subcommand is the check;
#  the || true keeps pipefail from eating the successful grep)
(git -C "$FW" subtree -h 2>&1 || true) | grep -q "git subtree split" || die "git subtree not available"
ok "git subtree present"

say "GitHub CLI (needed to create the polari-module-* repos)"
if gh auth status >/dev/null 2>&1; then
    ok "gh authenticated"
else
    echo "${RED}gh is NOT authenticated — run: gh auth login${NC}"
    echo "(the split scripts create PUBLIC repos under $GH_OWNER — no secrets in module code!)"
fi

say "live stack"
docker ps --format '{{.Names}}' | grep -qx prf-backend \
    && ok "prf-backend running (selftests will run in-container)" \
    || echo "${RED}prf-backend not running — pol suite up --env staging first${NC}"

say "selftest baseline (biomining from modules/ — the mp-1 proof)"
pol modules selftest biomining | tail -1

say "preflight done — next: 01-split-already-moved.sh"
