#!/bin/bash
# build-offline-bundle.sh — the OFFLINE install bundle (off-1 of
# AI-Notes/plans/OFFLINE_INSTALL_PLAN.md; decisions 1+2 ratified:
# Ubuntu target, multi-disk/multi-USB chunking first-class).
#
# Builds the version-matched piecewise bundle the offline medium
# carries: our staged debs + the distro dependency closure as a flat
# file: apt source, chunked to media size, with manifest + sha256SUMS
# + the ISLE_OFFLINE_BUNDLE marker. Chunk planning is the ONE
# framework implementation (appstore/offline_chunker.py — the same
# module whose chunks.json contract /downloads/offline renders), so
# builder and page can never drift.
#
#   ./build-offline-bundle.sh [--media dvd|cd|usb4|usb8|usb16|BYTES]
#                             [--target ubuntu-24.04]
#                             [--out .generated/offline]
#                             [--download]     fetch the closure debs
#                                              (multi-GB — roomy box)
#                             [--iso]          per-chunk .iso images
#                                              (genisoimage), emitted
#                                              PIECE BY PIECE
#                             [--closure PKGS] extra packages, comma-
#                                              separated (until off-0
#                                              inventories the real
#                                              install's fetch list)
#
# HONESTY RULES (the transparency ethos, in a build script):
# - Without --download the bundle is a SKELETON: the closure is
#   RESOLVED (pristine container of the target release, never this
#   dev box's state) and recorded as repo/CLOSURE_URIS.txt with
#   counts+bytes, but the debs are NOT present — manifest says
#   closureDownloaded=false and README names the gap. No silent
#   half-bundle pretending to install offline.
# - Signing anchor = OPEN decision 3: sha256SUMS ships; nothing here
#   signs or pretends to. README states how verification stands.
# - App/docker/VM images = decision 4 + off-0 inventory: named as
#   absent in README, never guessed at.
set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK="$ROOT/polari-rf-node/polari-framework"
DEBS_DIR="$ROOT/.generated/debs"
OUT="$ROOT/.generated/offline"
MEDIA="dvd"
TARGET="ubuntu-24.04"
DOWNLOAD=0
ISO=0
CLOSURE_EXTRA=""
while [ $# -gt 0 ]; do case "$1" in
    --media) MEDIA="$2"; shift 2 ;;
    --target) TARGET="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --download) DOWNLOAD=1; shift ;;
    --iso) ISO=1; shift ;;
    --closure) CLOSURE_EXTRA="$2"; shift 2 ;;
    --debs-dir) DEBS_DIR="$2"; shift 2 ;;
    *) echo "unknown arg $1" >&2; exit 1 ;;
esac; done
G="\033[0;32m"; R="\033[0;31m"; Y="\033[1;33m"; C="\033[0;36m"; N="\033[0m"
ok(){ echo -e "${G}[ OK ]${N} $*"; }
warn(){ echo -e "${Y}[WARN]${N} $*"; }
fail(){ echo -e "${R}[FAIL]${N} $*" >&2; exit 1; }
step(){ echo; echo -e "${C}==> $*${N}"; }

case "$TARGET" in
    ubuntu-24.04) BASE_IMAGE="ubuntu:24.04" ;;
    ubuntu-22.04) BASE_IMAGE="ubuntu:22.04" ;;
    *) fail "unsupported --target $TARGET (ubuntu-24.04|ubuntu-22.04)" ;;
esac

[ -d "$FRAMEWORK/modules/appstore" ] || fail "framework not at $FRAMEWORK"
ls "$DEBS_DIR"/*.deb >/dev/null 2>&1 || fail \
    "no debs staged in $DEBS_DIR — run ./build-polari-isle-deb.sh first"

step "Assemble the pool (our debs)"
POOL="$OUT/pool"
rm -rf "$OUT"
mkdir -p "$POOL/repo"
cp "$DEBS_DIR"/*.deb "$POOL/repo/"
OURS=$(ls "$POOL/repo" | wc -l)
ok "$OURS staged deb(s) -> pool/repo/"

step "Resolve the dependency closure in a PRISTINE $BASE_IMAGE"
# Union Depends of our debs (minus each other) — the same honesty as
# the merged-deb build: closure of what the debs DECLARE, resolved in
# a fresh container so this dev box's installed state can't leak in.
# off-0's instrumented inventory will supersede/extend this list.
DEPS=""
for deb in "$POOL/repo/"*.deb; do
    DEPS="$DEPS $(dpkg-deb -f "$deb" Depends 2>/dev/null \
        | tr ',' '\n' | sed 's/([^)]*)//; s/|.*//; s/ //g')"
done
OUR_NAMES=$(for deb in "$POOL/repo/"*.deb; do
    dpkg-deb -f "$deb" Package; done | sort -u)
DEPS=$(echo "$DEPS" | tr ' ' '\n' | sort -u | grep -v '^$' \
    | grep -vxF -f <(echo "$OUR_NAMES") | tr '\n' ' ')
[ -n "$CLOSURE_EXTRA" ] && DEPS="$DEPS $(echo "$CLOSURE_EXTRA" | tr ',' ' ')"
echo "    closure roots:$DEPS"
URIS_FILE="$POOL/repo/CLOSURE_URIS.txt"
if docker run --rm "$BASE_IMAGE" bash -lc \
    "apt-get update -qq >/dev/null 2>&1 && \
     apt-get install --print-uris -qq -y $DEPS 2>/dev/null" \
    | grep -oP "^'\K[^']+" > "$URIS_FILE"; then
    COUNT=$(wc -l < "$URIS_FILE")
    ok "closure resolved: $COUNT deb(s) beyond the base image"
else
    fail "closure resolution failed — is docker available and $BASE_IMAGE pullable?"
fi

if [ "$DOWNLOAD" = 1 ]; then
    step "Download the closure ($COUNT debs) — roomy-box mode"
    ( cd "$POOL/repo" && xargs -n1 -P4 curl -fsSO < CLOSURE_URIS.txt )
    ok "closure debs in pool/repo/"
    CLOSURE_DOWNLOADED=true
else
    warn "closure NOT downloaded (skeleton bundle) — rerun with --download on a roomy box"
    CLOSURE_DOWNLOADED=false
fi

step "Marker + README"
echo "polari offline bundle marker (probe target for core-install)" \
    > "$POOL/ISLE_OFFLINE_BUNDLE"
STORE_VERSION=$(ls "$POOL/repo" | grep -oP 'isle-app-store_\K[^_]+' || echo unknown)
cat > "$POOL/README.txt" <<EOF
Polari offline install bundle — $TARGET — version $STORE_VERSION

WHAT THIS IS: everything the normal install would fetch from the
internet, prepared for machines with no connection. Write each
numbered chunk to its own disk/USB (see /downloads/offline on any
polari instance, or chunks.json here, for the per-disk lists).

HOW COMPLETE IS THIS COPY (honesty section):
- our installer debs: PRESENT ($OURS)
- distro dependency closure: $([ "$CLOSURE_DOWNLOADED" = true ] \
    && echo "PRESENT ($COUNT debs)" \
    || echo "NOT PRESENT — resolved only (repo/CLOSURE_URIS.txt, $COUNT debs); this skeleton cannot install offline yet")
- docker images / VM artifacts: NOT PRESENT (inventoried by off-0;
  decision 4 — app images on medium — is still open)

VERIFICATION: sha256SUMS covers every file. A signing anchor for
media built before any isle exists is an OPEN design decision
(OFFLINE_INSTALL_PLAN.md decision 3) — until it lands, obtain this
bundle only from an instance you trust.
EOF
ok "marker + honest README"

step "Chunk to $MEDIA media (framework chunker — the ONE implementation)"
( cd "$FRAMEWORK" && PYTHONPATH=.:modules python3 -m appstore.offline_chunker \
    plan "$POOL" "$MEDIA" "$POOL" \
    --target "$TARGET" --media-label "$MEDIA" \
    --built-at "$(date +%F)" ) || fail "chunk planning refused"
# manifests live IN the pool: chunks.json names files relative to
# the pool, so the pool dir IS what /downloads/offline serves.
ok "chunks.json + sha256SUMS -> $POOL (stage POLARI_OFFLINE_DIR at the POOL for /downloads/offline)"

step "Manifest"
python3 - "$POOL" "$TARGET" "$MEDIA" "$CLOSURE_DOWNLOADED" "$COUNT" <<'PYEOF'
import json, os, sys
out, target, media, downloaded, count = sys.argv[1:6]
chunks = json.load(open(os.path.join(out, 'chunks.json')))
manifest = {
    'target': target, 'media': media,
    'builtAt': chunks['builtAt'],
    'closureDownloaded': downloaded == 'true',
    'closureDebs': int(count),
    'chunks': len(chunks['chunks']),
    'files': sum(len(c['files']) for c in chunks['chunks']),
    'bytes': sum(f['bytes'] for c in chunks['chunks']
                 for f in c['files']),
}
json.dump(manifest, open(os.path.join(out, 'manifest.json'), 'w'),
          indent=2)
print('    ' + json.dumps(manifest))
PYEOF
ok "manifest.json"

if [ "$ISO" = 1 ]; then
    step "Per-chunk ISOs (piece by piece — one chunk staged at a time)"
    command -v genisoimage >/dev/null || fail "genisoimage not installed"
    CHUNKS=$(python3 -c "import json;print(len(json.load(open('$POOL/chunks.json'))['chunks']))")
    for i in $(seq 1 "$CHUNKS"); do
        STAGE="$OUT/.iso-stage"
        rm -rf "$STAGE"; mkdir -p "$STAGE"
        ( cd "$FRAMEWORK" && PYTHONPATH=.:modules \
            python3 -m appstore.offline_chunker emit "$POOL" "$MEDIA" "$i" "$STAGE" )
        # EVERY medium is self-identifying: marker + manifests ride
        # on each disk, not just the chunk they packed into.
        cp "$POOL/chunks.json" "$POOL/sha256SUMS" \
           "$POOL/manifest.json" "$POOL/ISLE_OFFLINE_BUNDLE" \
           "$POOL/README.txt" "$STAGE/"
        genisoimage -quiet -r -J -V "POLARI_OFFLINE_$i" \
            -o "$OUT/polari-offline-$TARGET-disk$i.iso" "$STAGE"
        rm -rf "$STAGE"
        ok "disk $i -> polari-offline-$TARGET-disk$i.iso"
    done
fi
echo
[ "$CLOSURE_DOWNLOADED" = true ] \
    && ok "OFFLINE BUNDLE COMPLETE: $OUT" \
    || warn "SKELETON bundle (closure resolved, not downloaded): $OUT"
