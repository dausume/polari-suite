#!/bin/bash
# The living record, re-uploaded LAST. release.json gains a publishedTo entry from every route as it runs, but the
# github-release route (the first one) had already uploaded the file — so the copy beside the assets said "ghcr:
# nothing" for a release whose images were pushed a minute later, and a device's `pol prod update` (which reads THAT
# copy and refuses images that were never really pushed) would have refused every release. Found 2026-09-27 building
# the device-side update; this step runs after the routes stage, whatever the routes did, and clobbers the asset.
# Not a route: it publishes nothing new, it corrects the record of what was published.
source "$(dirname "$0")/_lib.sh"
ROUTE_GATE=github-release   # armed exactly when the github-release route is (publish #5: gated as "record" it was always DRY)
arm GITHUB_TOKEN:github/release_token
export GH_TOKEN="$GITHUB_TOKEN"
TAG="polari-v$VERSION"; REPO="$(dest_release_repo)"
if [ "$DRY_RUN" != 1 ] && ! gh release view "$TAG" -R "$REPO" >/dev/null 2>&1; then
    echo "[$ROUTE] no GitHub release $TAG on $REPO — nothing to correct (the github-release route did not publish)"; exit 0
fi
echo "[$ROUTE] publishedTo now: $(manifest "['publishedTo']" | python3 -c 'import sys,ast; d=ast.literal_eval(sys.stdin.read()); print(", ".join("%s=%s" % (k, "dry" if v.get("dryRun") else "real") for k, v in sorted(d.items())) or "nothing")')"
run gh release upload "$TAG" -R "$REPO" "$POOL_DIR/release.json" --clobber
