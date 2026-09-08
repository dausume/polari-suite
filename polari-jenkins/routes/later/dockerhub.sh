#!/bin/bash
# Docker Hub mirror for discovery: docker.io/<org>/<name>:<VERSION>. D9 = the org name.
source "$(dirname "$0")/../_lib.sh"
need DOCKERHUB_USER registries/dockerhub_user; need DOCKERHUB_TOKEN registries/dockerhub_token
ORG="${DOCKERHUB_ORG:-$DOCKERHUB_USER}"
run bash -c "printf '%s' \"\$DOCKERHUB_TOKEN\" | docker login -u \"\$DOCKERHUB_USER\" --password-stdin"
for name in prf-backend prf-frontend pol-reticulum; do
    TAR="$POOL_DIR/images/${name}_$VERSION.tar"; [ -f "$TAR" ] || continue
    run docker load -i "$TAR"; run docker tag "$name:$VERSION" "docker.io/$ORG/$name:$VERSION"; run docker push "docker.io/$ORG/$name:$VERSION"
done
record "https://hub.docker.com/u/$ORG"
