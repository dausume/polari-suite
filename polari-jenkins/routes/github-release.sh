#!/bin/bash
# GitHub Release on <owner>/polari-suite: tag polari-v<VERSION>, upload debs + SHA256SUMS +
# release.json + offline chunks. The canonical home. The owner comes from
# routes/destinations.sh, which is also what the secrets catalogue names as this
# token's destination — one constant, so the two cannot disagree.
source "$(dirname "$0")/_lib.sh"
arm GITHUB_TOKEN:github/release_token
export GH_TOKEN="$GITHUB_TOKEN"
# the destination comes from routes/destinations.sh, which is also what the
# secrets catalogue renders — so "where does this token publish?" has ONE answer.
TAG="polari-v$VERSION"; REPO="$(dest_release_repo)"
SHA=$(manifest "['components']['superproject']['sha']")
NOTES="$POOL_DIR/RELEASE_NOTES.md"
{ echo "# Polari $VERSION"; echo
  echo "Tested in a throwaway isle: $(tested_apps | sed 's/^$/core only/')"
  EXCL="$(release_excluded "$POOL_DIR/debs" || true)"
  [ -n "$EXCL" ] && { echo; echo "**not released: untested/failed**"; printf '%s\n' "$EXCL" | sed 's/^/- /'; } || true
  echo; echo '```json'; cat "$POOL_DIR/release.json"; echo '```'; } > "$NOTES"
if gh release view "$TAG" -R "$REPO" >/dev/null 2>&1 && [ "$DRY_RUN" != 1 ]; then echo "[$ROUTE] $TAG already exists — idempotent skip"; exit 0; fi
run gh release create "$TAG" -R "$REPO" --target "$SHA" --title "Polari $VERSION" --notes-file "$NOTES" --latest=false
# the release rule: app debs the isle test did not pass are NOT uploaded
mapfile -t ASSETS < <(release_assets "$POOL_DIR/debs")
# ci-3: and the EVIDENCE travels with them — the one-page test report, the
# advisory scan summary and the verdict itself. "What was this release tested
# with?" must be answerable from the release page alone, by somebody who has
# never seen the device that built it.
mapfile -t EVIDENCE < <(tested_assets)
[ ${#EVIDENCE[@]} -gt 0 ] && echo "[$ROUTE] evidence attached: $(printf '%s ' "${EVIDENCE[@]##*/}")" \
                          || echo "[$ROUTE] no TEST_REPORT.md / SCAN_SUMMARY.md / verdict.json for this sha to attach"
run gh release upload "$TAG" -R "$REPO" "${ASSETS[@]}" "${EVIDENCE[@]}" \
    "$POOL_DIR/SHA256SUMS" "$POOL_DIR/release.json" --clobber
record "https://github.com/$REPO/releases/tag/$TAG"
