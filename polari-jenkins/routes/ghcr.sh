#!/bin/bash
# GHCR: push prf-backend / prf-frontend / pol-reticulum as ghcr.io/dausume/<name>:<VERSION> (+ :latest), cosign-signed.
source "$(dirname "$0")/_lib.sh"
need GHCR_TOKEN registries/ghcr_token
REG="${GHCR_NS:-ghcr.io/dausume}"
run bash -c "printf '%s' \"\$GHCR_TOKEN\" | docker login ghcr.io -u dausume --password-stdin"
for name in prf-backend prf-frontend pol-reticulum; do
    TAR="$POOL_DIR/images/${name}_$VERSION.tar"; [ -f "$TAR" ] || { echo "[$ROUTE] no $TAR — skipping $name"; continue; }
    run docker load -i "$TAR"
    run docker tag "$name:$VERSION" "$REG/$name:$VERSION"; run docker push "$REG/$name:$VERSION"
    run docker tag "$name:$VERSION" "$REG/$name:latest";   run docker push "$REG/$name:latest"
    if [ -n "${COSIGN_KEY:-}" ]; then printf '%s\n' "$COSIGN_KEY" > /tmp/cosign.key; run env COSIGN_PASSWORD="${COSIGN_PASSWORD:-}" cosign sign --yes --key /tmp/cosign.key "$REG/$name:$VERSION"; rm -f /tmp/cosign.key
    else echo "[$ROUTE] cosign_key absent — pushed UNSIGNED (put signing/cosign_key in place to sign)"; fi
done
record "https://github.com/dausume?tab=packages"
