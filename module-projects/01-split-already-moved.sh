#!/bin/bash
# mp-2 first splits: biomining + microalgae (already living in
# modules/ since mp-1). Creates their PUBLIC repos, pushes the
# subtree history, fills the register's repo fields — from that
# moment `pol modules get|drop` are live for them.
# The in-tree copy stays AUTHORITATIVE; re-run `pol modules publish`
# after in-tree changes to re-push.
source "$(dirname "$0")/lib.sh"

gh auth status >/dev/null 2>&1 || die "gh not authenticated — gh auth login first"

for m in biomining microalgae; do
    REPO_URL="https://github.com/$GH_OWNER/polari-module-$m.git"
    say "split $m -> $REPO_URL (PUBLIC — module code carries no secrets)"
    if gh repo view "$GH_OWNER/polari-module-$m" >/dev/null 2>&1; then
        ok "repo already exists"
    else
        confirm "create PUBLIC repo $GH_OWNER/polari-module-$m?"
        run gh repo create "$GH_OWNER/polari-module-$m" --public \
            --description "Polari feature module: $m (sub-project of Polari-Framework)"
    fi
    # publish = subtree split (history kept) + push + register fill;
    # prints every git command it runs.
    run pol modules publish "$m" --repo "$REPO_URL"
done

say "register now carries the repos:"
pol modules registry | grep -A1 -E "^  (biomining|microalgae)"

say "commit the register change (framework repo)"
run git -C "$FW" add -f modules/polari-modules.json
git -C "$FW" commit -m "mp-2: biomining + microalgae split into polari-module-* repos (register repo fields filled)" \
    || ok "register already committed (nothing to commit)"
print_pointer_commits "mp-2: first module repos split (biomining, microalgae)"

cat <<EOF

${BOLD}Optional round-trip proof (safe: biomining is a leaf):${NC}
  pol modules drop biomining     # refuses if anything is uncommitted
  pol modules get biomining      # clones it back from the new repo
  pol modules selftest biomining # 33/33 from the cloned copy
NOTE: drop only works once the in-tree copy is retired from the
framework repo (mp-4 end state). While the copy is tracked in-tree,
drop refuses with 'not its own git checkout' — that refusal is
correct during the overlap period.
EOF
