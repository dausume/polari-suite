#!/bin/bash
# The forge's release pool (frg-3): release polari-v<VERSION> on <owner>/polari-suite at the forge, carrying EXACTLY
# what github-release.sh carries — the tested debs, SHA256SUMS, release.json and the evidence (TEST_REPORT.md,
# SCAN_SUMMARY.md, verdict.json). DUAL ROUTE (his ruling): GitHub is online availability, this copy is the
# self-sustaining one and production's default — a device's `pol prod update` asks the forge first.
#
# The repository must already be on the forge (a pull mirror of GitHub, or a primary): this route never creates
# one — `pol forge mirror --forest` does. A MIRROR receives the tag and the commit from GitHub on its weekly check
# (or `pol forge mirror --sync`); when the release sha is not there yet the route asks for ONE mirror-sync, waits
# briefly, and refuses honestly if it is still absent. Idempotent: an existing release is reused and every asset
# is re-uploaded with clobber semantics (as `gh release upload --clobber`).
source "$(dirname "$0")/_lib.sh"
arm FORGE_TOKEN:forge/publish_token
source "$(dirname "$0")/_forge.sh"
TAG="polari-v$VERSION"
SHA=$(manifest "['components']['superproject']['sha']")
NOTES="$POOL_DIR/RELEASE_NOTES.md"; release_notes "$NOTES"   # the same body as the GitHub release (_lib.sh)
say "forge $FORGE · repository $FREPO · tag $TAG at $SHA"

RID=""
if [ "$DRY_RUN" = 1 ]; then
    say "(checks first, ARMED only: GET $(fj_api '') exists — else REFUSE 'mirror the forest first'; GET $(fj_api "/git/commits/$SHA") — a mirror lacking it gets ONE POST $(fj_api /mirror-sync); GET $(fj_api "/releases/tags/$TAG") — an existing release is reused)"
else
    fj_get "$(fj_api '')"
    case "$FJ_CODE" in
        200) ;;
        404) echo "[$ROUTE] REFUSED: $FREPO is not on the forge $FORGE — mirror the forest first (pol forge mirror --forest)"; exit 3 ;;
        *)   echo "[$ROUTE] REFUSED: the forge did not answer for $FREPO ($(fj_why)) — nothing published"; exit 3 ;;
    esac
    MIRROR="$(fj_field 'bool(d.get("mirror"))')"
    fj_get "$(fj_api "/git/commits/$SHA")"
    if [ "$FJ_CODE" != 200 ]; then
        if [ "$MIRROR" = True ]; then
            echo "[$ROUTE] $SHA is not on the forge's mirror yet — asking for one mirror-sync"
            fj POST "$(fj_api /mirror-sync)"
            waited=0; step="${FORGE_SYNC_STEP:-5}"; max="${FORGE_SYNC_WAIT:-60}"
            while :; do
                fj_get "$(fj_api "/git/commits/$SHA")"; [ "$FJ_CODE" = 200 ] && break
                [ "$waited" -ge "$max" ] && break
                sleep "$step"; waited=$((waited + step))
            done
        fi
        [ "$FJ_CODE" = 200 ] || {
            echo "[$ROUTE] REFUSED: the release sha $SHA is not on $FORGE/$FREPO$([ "$MIRROR" = True ] && echo " (asked for a mirror-sync; still absent after ${max}s — run: pol forge mirror --sync $FREPO, then re-run polari-publish)" || echo " — push it to the forge (it is a primary, not a mirror), then re-run polari-publish")"; exit 3; }
        echo "[$ROUTE] $SHA is on the forge now"
    fi
    RID="$(fj_release_id "$TAG")"
    [ -n "$RID" ] && echo "[$ROUTE] $TAG already exists on the forge (id $RID) — idempotent skip of the create; assets re-checked with clobber"
fi

if [ -z "$RID" ]; then
    PAYLOAD="$FJ_WORK/release.json"
    python3 - "$PAYLOAD" "$TAG" "$SHA" "Polari $VERSION" "$NOTES" <<'PY'
import json, sys
p, tag, sha, name, notes = sys.argv[1:6]
json.dump({"tag_name": tag, "target_commitish": sha, "name": name, "body": open(notes).read(),
           "draft": False, "prerelease": False}, open(p, "w"))
PY
    fj POST "$(fj_api /releases)" -H 'Content-Type: application/json' --data-binary "@$PAYLOAD"
    if [ "$DRY_RUN" = 1 ]; then RID="<release id>"
    else
        case "$FJ_CODE" in
            201) RID="$(fj_field 'd.get("id")')" ;;
            409) echo "[$ROUTE] $TAG already exists (409) — idempotent skip of the create"; RID="$(fj_release_id "$TAG")" ;;
        esac
        [ -n "$RID" ] || { echo "[$ROUTE] FAILED: creating $TAG — $(fj_why)"; exit 1; }
    fi
fi

# the release rule: the same tested assets the GitHub release carries — and nothing else
mapfile -t ASSETS < <(release_assets "$POOL_DIR/debs")
mapfile -t EVIDENCE < <(tested_assets)
[ ${#EVIDENCE[@]} -gt 0 ] && say "evidence attached: $(printf '%s ' "${EVIDENCE[@]##*/}")" \
                          || say "no TEST_REPORT.md / SCAN_SUMMARY.md / verdict.json for this sha to attach"
for f in "${ASSETS[@]}" "${EVIDENCE[@]}" "$POOL_DIR/SHA256SUMS" "$POOL_DIR/release.json"; do
    [ -n "$f" ] || continue
    fj_upload_asset "$RID" "$f" || true
done
[ "$FAILED" = 0 ] || { echo "[$ROUTE] FAILED: $FAILED asset(s) did not upload — re-run polari-publish (every step is idempotent)"; exit 1; }
record "$FORGE/$FREPO/releases/tag/$TAG"
