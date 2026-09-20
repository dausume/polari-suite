#!/bin/bash
# GHCR: push the release images as <registry>/<name>:<VERSION> (+ :latest), cosign-signed.
# WHERE is routes/destinations.sh — the same constants the secrets catalogue renders,
# and in app mode the developer's own namespace rather than upstream's.
source "$(dirname "$0")/_lib.sh"
arm GHCR_TOKEN:github/registry_token
REG="$(dest_registry_ns)"
run bash -c "printf '%s' \"\$GHCR_TOKEN\" | docker login ghcr.io -u $(dest_registry_user) --password-stdin"
for name in $DEST_REGISTRY_IMAGES; do
    TAR="$POOL_DIR/images/${name}_$VERSION.tar"; [ -f "$TAR" ] || { echo "[$ROUTE] no $TAR — skipping $name"; continue; }
    run docker load -i "$TAR"
    run docker tag "$name:$VERSION" "$REG/$name:$VERSION"; run docker push "$REG/$name:$VERSION"
    run docker tag "$name:$VERSION" "$REG/$name:latest";   run docker push "$REG/$name:latest"
    if [ -n "${COSIGN_KEY:-}" ]; then printf '%s\n' "$COSIGN_KEY" > /tmp/cosign.key; run env COSIGN_PASSWORD="${COSIGN_PASSWORD:-}" cosign sign --yes --key /tmp/cosign.key "$REG/$name:$VERSION"; rm -f /tmp/cosign.key
    else echo "[$ROUTE] cosign_key absent — pushed UNSIGNED (put signing/cosign_key in place to sign)"; fi
done
record "https://github.com/$(dest_registry_user)?tab=packages"
