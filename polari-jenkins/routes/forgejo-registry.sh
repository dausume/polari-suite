#!/bin/bash
# The forge's container registry (frg-3) — the ghcr twin: push the TESTED release images as
# <forge host>/<owner>/<name>:<VERSION> (+ :latest), cosign-signed when a key is present.
# Never rebuilt: the same tarballs ghcr.sh loads (pool/<version>/images/<name>_<VERSION>.tar, loaded from what the
# test run kept for the sha), and arm's released == tested check holds over DIGESTS.txt for both routes alike.
# docker login needs the token's USER (the owner is an org on the forge), read from /api/v1/user when ARMED.
source "$(dirname "$0")/_lib.sh"
arm FORGE_TOKEN:forge/publish_token
source "$(dirname "$0")/_forge.sh"
REG="$(dest_forge_registry)"; FHOST="$(dest_forge_host)"
if [ "$DRY_RUN" = 1 ]; then FUSER="<the token's user>"
else
    fj_get "$FORGE/api/v1/user"
    FUSER=""; [ "$FJ_CODE" = 200 ] && FUSER="$(fj_field 'd.get("login")')"
    [ -n "$FUSER" ] || { echo "[$ROUTE] REFUSED: the forge did not accept forge/publish_token ($(fj_why)) — pol jenkins doctor proves it"; exit 3; }
fi
run bash -c "printf '%s' \"\$FORGE_TOKEN\" | docker login $FHOST -u '$FUSER' --password-stdin"
for name in $DEST_REGISTRY_IMAGES; do
    TAR="$POOL_DIR/images/${name}_$VERSION.tar"; [ -f "$TAR" ] || { echo "[$ROUTE] no $TAR — skipping $name"; continue; }
    run docker load -i "$TAR"
    run docker tag "$name:$VERSION" "$REG/$name:$VERSION"; run docker push "$REG/$name:$VERSION"
    run docker tag "$name:$VERSION" "$REG/$name:latest";   run docker push "$REG/$name:latest"
    if [ -n "${COSIGN_KEY:-}" ]; then printf '%s\n' "$COSIGN_KEY" > "$FJ_WORK/cosign.key"; run env COSIGN_PASSWORD="${COSIGN_PASSWORD:-}" cosign sign --yes --key "$FJ_WORK/cosign.key" "$REG/$name:$VERSION"; rm -f "$FJ_WORK/cosign.key"
    else echo "[$ROUTE] cosign_key absent — pushed UNSIGNED (put signing/cosign_key in place to sign)"; fi
done
record "$FORGE/$FOWNER/-/packages/container"
