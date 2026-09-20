#!/bin/bash
# polari-jenkins/isle/payload.sh — ci-3: WHAT GOES INTO THE GUEST.
#
#   payload.sh build <outdir> <core-debs-dir> [<app-debs-dir>]
#
# The throwaway guest installs THE ARTIFACTS THIS RUN BUILT, not a published
# release. Two kinds of artifact have to travel, and they travel differently:
#
#   · the DEBS — already in the pool, small (~150 MB), copied as files.
#   · the IMAGES — `prf-backend:staging` and `prf-frontend:staging`, on the
#     BUILDING device's docker daemon and NOWHERE ELSE. They are unreleased, so
#     `docker pull` inside the guest would either fail or — worse — succeed and
#     pull somebody else's published image, and the run would then report a
#     verdict about code it never tested. So they are `docker save`d here and
#     `docker load`ed in the guest.
#
# WHICH images. ONLY the two `polari-isle/docker-compose.yml` actually runs
# (backend + frontend). `pol-reticulum:staging` is built by the same run but the
# isle compose has no reticulum service, so shipping it would be 224 MB of
# transfer for something that never starts. CI_ISLE_IMAGES overrides the list.
#
# THE KEY. images.key is the sha256 of the image IDs. It is what the target
# caches the tarball under, so a second run whose frontend and backend did not
# change re-uses a tarball that is already there instead of pushing gigabytes
# over the wire again. The IDs are also what results.json records, so "tested ==
# released" is asserted on image identity and not on a tag that anyone can move.
set -euo pipefail

CMD="${1:-}"; shift || true
[ "$CMD" = build ] || { echo "payload.sh build <outdir> <core-debs-dir> [<app-debs-dir>]" >&2; exit 2; }
OUT="${1:?payload.sh build <outdir> <core-debs-dir> [<app-debs-dir>]}"; shift
CORE_DEBS="${1:-}"; shift || true
APP_DEBS="${1:-}"

IMAGES="${CI_ISLE_IMAGES:-prf-backend:staging prf-frontend:staging}"
DOCKER="${PAYLOAD_DOCKER:-docker}"
say() { printf '[payload] %s\n' "$*" >&2; }

rm -rf "$OUT"; mkdir -p "$OUT/debs"

# ------------------------------------------------------------------- the debs
n=0
if [ -n "$CORE_DEBS" ] && [ -d "$CORE_DEBS" ]; then
    cp "$CORE_DEBS"/*.deb "$OUT/debs/" 2>/dev/null || true
    n="$(find "$OUT/debs" -name '*.deb' | wc -l)"
fi
[ "$n" -gt 0 ] || { echo "[payload] REFUSED: no core debs in '${CORE_DEBS:-(none)}' — the build stage must run first" >&2; exit 5; }
a=0
if [ -n "$APP_DEBS" ] && [ -d "$APP_DEBS" ]; then
    mkdir -p "$OUT/app-debs"
    cp "$APP_DEBS"/*.deb "$OUT/app-debs/" 2>/dev/null || true
    a="$(find "$OUT/app-debs" -name '*.deb' 2>/dev/null | wc -l)"
fi
say "$n core deb(s), $a app deb(s)"

# ----------------------------------------------------------------- the images
: > "$OUT/images.txt"
MISSING=""
for ref in $IMAGES; do
    id="$("$DOCKER" image inspect --format '{{.Id}}' "$ref" 2>/dev/null || true)"
    [ -n "$id" ] || { MISSING="$MISSING $ref"; continue; }
    printf '%s\t%s\n' "$ref" "$id" >> "$OUT/images.txt"
done
if [ -n "$MISSING" ]; then
    echo "[payload] REFUSED: these images are not on this daemon:$MISSING" >&2
    echo "[payload] the isle test installs THE IMAGES THIS RUN BUILT — it never falls back to a" >&2
    echo "[payload] published tag, because a verdict about an image we did not build is not a verdict." >&2
    exit 5
fi
KEY="$(cut -f2 "$OUT/images.txt" | sha256sum | cut -d' ' -f1)"
printf '%s\n' "$KEY" > "$OUT/images.key"

T0=$(date +%s)
# shellcheck disable=SC2086
"$DOCKER" save $IMAGES | gzip -1 > "$OUT/images.tar.gz"
SZ="$(du -m "$OUT/images.tar.gz" | cut -f1)"
say "images.tar.gz ${SZ} MB in $(( $(date +%s) - T0 ))s — key ${KEY:0:12}"
sed 's/^/[payload]   /' "$OUT/images.txt" >&2

printf 'CI_ISLE_IMAGE_KEY=%s\n' "$KEY" > "$OUT/stage.env"
echo "PAYLOAD=$OUT"
echo "IMAGE_KEY=$KEY"
echo "IMAGE_MB=$SZ"
