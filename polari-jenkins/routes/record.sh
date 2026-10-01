#!/bin/bash
# The living record, re-uploaded LAST. release.json gains a publishedTo entry from every route as it runs, but the
# github-release route (the first one) had already uploaded the file — so the copy beside the assets said "ghcr:
# nothing" for a release whose images were pushed a minute later, and a device's `pol prod update` (which reads THAT
# copy and refuses images that were never really pushed) would have refused every release. Found 2026-09-27 building
# the device-side update; this step runs after the routes stage, whatever the routes did, and clobbers the asset.
# Not a route: it publishes nothing new, it corrects the record of what was published.
#
# frg-3: TWO copies now — the GitHub release's and the FORGE release's (devices ask the forge first). Each half arms
# exactly when the route it serves is armed (ROUTE_GATE), so both copies end up saying the same thing.
source "$(dirname "$0")/_lib.sh"
DRY_RUN_ASKED="$DRY_RUN"   # arm resolves DRY_RUN in place; the forge half must resolve from what was ASKED, not from the GitHub half's answer
TAG="polari-v$VERSION"
echo "[$ROUTE] publishedTo now: $(manifest "['publishedTo']" | python3 -c 'import sys,ast; d=ast.literal_eval(sys.stdin.read()); print(", ".join("%s=%s" % (k, "dry" if v.get("dryRun") else "real") for k, v in sorted(d.items())) or "nothing")')"

# ---- the GitHub copy — armed exactly when the github-release route is (publish #5: gated as "record" it was always DRY)
ROUTE_GATE=github-release
arm GITHUB_TOKEN:github/release_token
export GH_TOKEN="$GITHUB_TOKEN"
REPO="$(dest_release_repo)"
if [ "$DRY_RUN" != 1 ] && ! gh release view "$TAG" -R "$REPO" >/dev/null 2>&1; then
    echo "[$ROUTE] no GitHub release $TAG on $REPO — nothing to correct there (the github-release route did not publish)"
else
    run gh release upload "$TAG" -R "$REPO" "$POOL_DIR/release.json" --clobber
fi

# ---- the forge copy — armed exactly when the forgejo-release route is
DRY_RUN="$DRY_RUN_ASKED"; ROUTE_GATE=forgejo-release
arm FORGE_TOKEN:forge/publish_token
source "$(dirname "$0")/_forge.sh"
if [ "$DRY_RUN" = 1 ]; then RID="<release id>"
else
    RID="$(fj_release_id "$TAG")"
    [ -n "$RID" ] || { echo "[$ROUTE] no forge release $TAG on $FORGE/$FREPO — nothing to correct there (the forgejo-release route did not publish)"; exit 0; }
fi
fj_upload_asset "$RID" "$POOL_DIR/release.json"
