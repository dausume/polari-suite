#!/bin/bash
# polari-jenkins/build-images.sh — build the two Polari images THROUGH the
# offline cache (ci-9, his ask 2026-09-19: *"the jenkins pipeline should try
# and use offline artifacts for building where possible, that way we are taking
# less time when repeatedly using the same data"*).
#
#   build-images.sh <suite-checkout> [<cache-report.json>]
#
# What it adds over `docker compose build backend frontend`:
#   · DOCKER_BUILDKIT=1 everywhere (the cache mounts in both Dockerfiles are
#     inert without it);
#   · the base images are loaded from <cache>/images rather than re-pulled;
#   · the backend gets the pipeline's WHEELHOUSE as the named build context
#     `wheels`, so pip installs from disk and only asks the index for what is
#     genuinely new;
#   · both get a local BuildKit LAYER cache under <cache>/layers/<image>;
#   · both get tier two's PIP_INDEX_URL / NPM_CONFIG_REGISTRY build-args when
#     the proxies actually answer, and nothing when they do not;
#   · the arithmetic (bytes from the cache vs bytes fetched, seconds) is written
#     into the run's cache-report.json.
#
# FALLBACK, ALWAYS. The layer cache and the named build context need buildx. On
# a daemon without it this runs the plain `docker compose build` the release job
# always ran, says so on one line, and the build still succeeds — slower.
#
# (It also pins the two tags the release job expects, `prf-backend:staging` and
# `prf-frontend:staging`. docker-compose.yml's backend/frontend services carry
# no `image:` key, so a compose build names them after the compose project —
# which is why the release job's `docker tag prf-backend:staging …` has never
# been able to find them. The buildx path tags them directly.)
set -euo pipefail

J="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE="${1:?usage: build-images.sh <suite-checkout> [<cache-report.json>]}"
REPORT="${2:-}"
# shellcheck source=cache.sh
source "$J/cache.sh"

export DOCKER_BUILDKIT=1 COMPOSE_DOCKER_CLI_BUILD=1
NODE="$SUITE/polari-rf-node"
[ -d "$NODE" ] || { echo "[build-images] no polari-rf-node in $SUITE" >&2; exit 2; }

# ---------------------------------------------------------------------------
# ci-3 — WHICH FRONTEND. `Dockerfile` is the DEV image: node:20, `ng serve`,
# 4.07 GB. `Dockerfile.prod` is the multi-stage one: node builds, nginx serves
# the static bundle out of /usr/share/nginx/html on :4200, ~60 MB.
#
# The isle runs the SECOND one and can run nothing else. Isle-Mesh's
# polari-isle/docker-compose.yml mounts runtime-config.json to
# `/usr/share/nginx/html/assets/runtime-config.json` — a path the dev image does
# not have — and caps the service at `mem_limit: 128m`, which `ng serve` cannot
# start inside. So a pipeline that built the dev image, tested nothing with it
# (ci-3 did not exist) and published it as `prf-frontend:<version>` was shipping
# an image no isle could run. That was true of every release this job has made.
#
# It is the SAME tag and the same place in the pipeline; only the Dockerfile
# moves, and it moves to the one the product actually deploys. Override with
# POLARI_FRONTEND_DOCKERFILE if you genuinely want the dev image in an image
# release — nothing in this suite does.
FRONTEND_DOCKERFILE="${POLARI_FRONTEND_DOCKERFILE:-Dockerfile.prod}"
echo "[build-images] frontend Dockerfile: $FRONTEND_DOCKERFILE (the image the isle's own compose runs)"

T0=$(date +%s)
BYTES_CACHED=0; BYTES_FETCHED=0

# ---- 1. the base images, from the cache when we have them ------------------
BASES="python:3.12-alpine node:20 node:20-alpine nginx:alpine"
echo "[build-images] base images: $BASES"
# bytes ALREADY in the cache before this run = bytes we did not have to pull
BYTES_CACHED=$(du -sb "$(cache_area images)" 2>/dev/null | cut -f1 || echo 0)
cache_images_warm $BASES || true

# ---- 2. the two Polari images ---------------------------------------------
WHEELS="$(cache_area wheels)"
PROXY_ARGS="$(cache_build_args || true)"
[ -n "$PROXY_ARGS" ] && echo "[build-images] tier two answers — passing: $PROXY_ARGS" \
                     || echo "[build-images] tier two not in use — the public indexes, as before"

if cache_buildx_ok; then
    echo "[build-images] buildx present — local layer cache under $(cache_area layers)"
    # shellcheck disable=SC2046,SC2086
    docker buildx build --load -t prf-backend:staging \
        $(cache_layers_args prf-backend) \
        --build-context "wheels=$WHEELS" \
        $PROXY_ARGS \
        "$NODE/polari-framework"
    # shellcheck disable=SC2046,SC2086
    docker buildx build --load -t prf-frontend:staging \
        -f "$NODE/polari-platform-angular/$FRONTEND_DOCKERFILE" \
        $(cache_layers_args prf-frontend) \
        $PROXY_ARGS \
        "$NODE/polari-platform-angular"
else
    echo "[build-images] no buildx on this daemon — falling back to 'docker compose build'."
    echo "[build-images] (the BuildKit cache MOUNTS still work; the local layer cache and the"
    echo "[build-images]  wheelhouse build-context do not — they are a buildx exporter/feature.)"
    ( cd "$NODE" && docker compose -f docker-compose.yml build backend )
    # the frontend still comes from the Dockerfile the isle runs, even here: the
    # compose service builds the DEV image, and an isle cannot run that.
    ( cd "$NODE/polari-platform-angular" \
      && DOCKER_BUILDKIT=1 docker build -f "$FRONTEND_DOCKERFILE" -t prf-frontend:staging . )
fi
( cd "$NODE" && docker compose -f docker-compose.reticulum.yml build )

# ---- 3. fold the base images back in, and report ---------------------------
cache_images_save $BASES || true
AFTER=$(du -sb "$(cache_area images)" 2>/dev/null | cut -f1 || echo 0)
BYTES_FETCHED=$(( AFTER > BYTES_CACHED ? AFTER - BYTES_CACHED : 0 ))
SECS=$(( $(date +%s) - T0 ))
echo "[build-images] done in ${SECS}s"
if [ -n "$REPORT" ]; then
    python3 "$J/cache-manifest.py" report "$REPORT" images "$BYTES_CACHED" "$BYTES_FETCHED" "$SECS" || true
fi
