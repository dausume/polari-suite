#!/bin/bash
# mp-2 per-module repo split: create the PUBLIC polari-module-<name>
# repo (if missing), subtree-split the module's history out of
# polari-framework, push it, fill the register's repo field.
# Safe to re-run: republishes the current in-tree state.
#
# Usage: ./20-split-module.sh <module> [<module>...]
source "$(dirname "$0")/lib.sh"

[ $# -ge 1 ] || die "usage: $0 <module> [<module>...]"
gh auth status >/dev/null 2>&1 || die "gh not authenticated — gh auth login first"

for m in "$@"; do
    [ -d "$FW/modules/$m" ] || die "'$m' is not in modules/ yet — run its wave first (./10-wave.sh)"
    REPO_URL="https://github.com/$GH_OWNER/polari-module-$m.git"
    say "split $m -> $REPO_URL"
    if gh repo view "$GH_OWNER/polari-module-$m" >/dev/null 2>&1; then
        ok "repo already exists"
    else
        confirm "create PUBLIC repo $GH_OWNER/polari-module-$m? (module code must carry no secrets)"
        run gh repo create "$GH_OWNER/polari-module-$m" --public \
            --description "Polari feature module: $m (sub-project of Polari-Framework)"
    fi
    run pol modules publish "$m" --repo "$REPO_URL"
done

say "commit the register's repo fields"
run git -C "$FW" add -f modules/polari-modules.json
git -C "$FW" commit -m "mp-2: fill register repo field(s) for $(echo "$*" | tr ' ' ',') — get/drop rails now live" \
    || ok "register already committed (nothing to commit)"
print_pointer_commits "mp-2: module repo split ($*)"
