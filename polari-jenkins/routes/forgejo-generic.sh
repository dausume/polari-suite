#!/bin/bash
# The forge's generic package registry (frg-3): the OFFLINE MEDIUM — its chunk set (pool/<v>/offline/chunks/*) and/or
# an ISO (pool/<v>/offline/*.iso|*.img) — as package polari-offline, version <VERSION>:
#   PUT <forge>/api/packages/<owner>/generic/polari-offline/<VERSION>/<file>    201 uploaded · 409 already there (done)
# Most releases carry no medium in publishable form: the route then says "nothing to upload" and records that.
source "$(dirname "$0")/_lib.sh"
arm FORGE_TOKEN:forge/publish_token
source "$(dirname "$0")/_forge.sh"
GEN="$(dest_forge_generic)/$VERSION"
mapfile -t FILES < <(offline_assets)
if [ ${#FILES[@]} = 0 ]; then
    say "nothing to upload — the pool carries no offline medium chunks/ISO ($POOL_DIR/offline/chunks/*, *.iso, *.img)"
    record "none (no offline medium in publishable form)"; exit 0
fi
for f in "${FILES[@]}"; do
    fj PUT "$GEN/$(urlq "$(basename "$f")")" --upload-file "$f"
    [ "$DRY_RUN" = 1 ] && continue
    case "$FJ_CODE" in
        200|201) ;;
        409) echo "[$ROUTE]   $(basename "$f") is already there — counts as done" ;;
        *)   echo "[$ROUTE] FAILED: uploading $(basename "$f") — $(fj_why)"; FAILED=$((FAILED + 1)) ;;
    esac
done
[ "$FAILED" = 0 ] || { echo "[$ROUTE] FAILED — re-run polari-publish"; exit 1; }
record "$FORGE/$FOWNER/-/packages/generic/polari-offline/$VERSION"
