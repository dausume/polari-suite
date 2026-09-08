#!/bin/bash
# GitHub Release on dausume/polari-suite: tag polari-v<VERSION>, upload debs + SHA256SUMS + release.json + offline chunks. The canonical home.
source "$(dirname "$0")/_lib.sh"
need GITHUB_TOKEN github/github_token
export GH_TOKEN="$GITHUB_TOKEN"
TAG="polari-v$VERSION"; REPO=dausume/polari-suite
SHA=$(manifest "['components']['superproject']['sha']")
NOTES="$POOL_DIR/RELEASE_NOTES.md"; { echo "# Polari $VERSION"; echo; echo '```json'; cat "$POOL_DIR/release.json"; echo '```'; } > "$NOTES"
if gh release view "$TAG" -R "$REPO" >/dev/null 2>&1 && [ "$DRY_RUN" != 1 ]; then echo "[$ROUTE] $TAG already exists — idempotent skip"; exit 0; fi
run gh release create "$TAG" -R "$REPO" --target "$SHA" --title "Polari $VERSION" --notes-file "$NOTES" --latest=false
run gh release upload "$TAG" -R "$REPO" "$POOL_DIR"/debs/*.deb "$POOL_DIR/SHA256SUMS" "$POOL_DIR/release.json" --clobber
record "https://github.com/$REPO/releases/tag/$TAG"
