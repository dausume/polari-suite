#!/bin/bash
# build-offline-medium.sh — assemble the OFFLINE MEDIUM in the standard
# template (AI-Notes/guides/OFFLINE_BUILD_TEMPLATE.md §2; rung off-2 of
# OFFLINE_INSTALL_PLAN.md) into the gitignored build cache
# offline-build/<polari-version>/ — the exact tree the medium carries and
# the deb is wrapped from. Every section directory ALWAYS exists; an
# empty one carries an EMPTY file naming why.
#
#   ./build-offline-medium.sh [--target ubuntu-22.04|ubuntu-24.04]
#                             [--version <polari-version>]   default YYYY.MM.DD-dev+<sha>
#                             [--modules household,reticulum,...]  offline module debs to carry
#                             [--closure pkg,pkg]  extra distro packages beyond the deb Depends
#                             [--bundle <dir>]     reuse an existing build-offline-bundle.sh --out
#                             [--no-download]      skeleton apt/ (closure resolved, not fetched)
#
# Inputs it expects to exist (built beforehand):
#   .generated/debs/                    build-polari-isle-deb.sh + build-polari-complete-deb.sh --flavor offline
#   docker images                       prf-backend:staging prf-frontend:staging nginx:alpine
#                                       isle-sample-app-sample:latest (python:3.11-slim) pol-reticulum:staging
#   polari-cli/shells/offline/          the installer/proof/engine scripts (copied to scripts/ + engines/)
set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK="$ROOT/polari-rf-node/polari-framework"
TARGET="ubuntu-22.04"; VERSION=""; MODULES="household,reticulum,techtree,vpn"
CLOSURE="docker.io,docker-compose-v2,containerd,runc,dpkg-dev,avahi-daemon,avahi-utils,apt-utils,gnupg"
BUNDLE=""; DOWNLOAD=1
while [ $# -gt 0 ]; do case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --version) VERSION="$2"; shift 2 ;;
    --modules) MODULES="$2"; shift 2 ;;
    --closure) CLOSURE="$2"; shift 2 ;;
    --bundle) BUNDLE="$2"; shift 2 ;;
    --no-download) DOWNLOAD=0; shift ;;
    *) echo "unknown arg $1" >&2; exit 1 ;;
esac; done
G="\033[0;32m"; R="\033[0;31m"; Y="\033[1;33m"; C="\033[0;36m"; N="\033[0m"
ok(){ echo -e "${G}[ OK ]${N} $*"; }
warn(){ echo -e "${Y}[WARN]${N} $*"; }
fail(){ echo -e "${R}[FAIL]${N} $*" >&2; exit 1; }
step(){ echo; echo -e "${C}==> $*${N}"; }
SHA=$(git -C "$ROOT" rev-parse --short HEAD)
[ -n "$VERSION" ] || VERSION="$(date +%Y.%m.%d)-dev+$SHA"
OUT="$ROOT/offline-build/$VERSION"
IMAGES="prf-backend:staging prf-frontend:staging nginx:alpine python:3.11-slim isle-sample-app-sample:latest"
ENGINE_IMAGES="pol-reticulum:staging"

step "Polari $VERSION → $OUT (target $TARGET)"
rm -rf "$OUT"; mkdir -p "$OUT"
for s in debs apt images router modules engines hardware scripts; do mkdir -p "$OUT/$s"; done
empty(){ printf '%s\n' "$2" > "$OUT/$1/EMPTY"; warn "$1/: EMPTY — $2"; }

step "debs/ (section 4: the isle itself)"
ls "$ROOT"/.generated/debs/polari-complete-offline_*.deb >/dev/null 2>&1 \
    || fail "no polari-complete-offline deb — run ./build-polari-complete-deb.sh --flavor offline"
cp "$ROOT"/.generated/debs/*.deb "$OUT/debs/"
ok "$(ls "$OUT/debs" | wc -l) debs ($(ls "$OUT/debs" | tr '\n' ' '))"

step "apt/ (section 1: distro closure as a flat file: repo)"
if [ -z "$BUNDLE" ]; then
    BUNDLE="$OUT/.bundle"
    ARGS=(--target "$TARGET" --media usb16 --out "$BUNDLE" --closure "$CLOSURE")
    [ "$DOWNLOAD" = 1 ] && ARGS+=(--download)
    "$ROOT/build-offline-bundle.sh" "${ARGS[@]}" >"$OUT/.bundle.log" 2>&1 || { tail -5 "$OUT/.bundle.log"; fail "build-offline-bundle.sh failed (log: $OUT/.bundle.log)"; }
fi
N_CLOSURE=$(ls "$BUNDLE"/pool/repo/*.deb 2>/dev/null | grep -vcE '/(isle-|polari-)' || true)
if [ "$N_CLOSURE" -gt 0 ]; then
    for f in "$BUNDLE"/pool/repo/*.deb; do case "$(basename "$f")" in isle-*|polari-*) ;; *) cp "$f" "$OUT/apt/" ;; esac; done
    cp "$BUNDLE/pool/repo/CLOSURE_URIS.txt" "$OUT/apt/"
    ( cd "$OUT/apt" && dpkg-scanpackages --multiversion . /dev/null 2>/dev/null > Packages && gzip -kf Packages \
        && apt-ftparchive -o APT::FTPArchive::Release::Origin=polari-offline \
            -o APT::FTPArchive::Release::Label="Polari offline medium" \
            -o APT::FTPArchive::Release::Suite=offline \
            -o APT::FTPArchive::Release::Description="Distro closure for a Polari offline install ($TARGET)" \
            release . > Release ) || fail "apt index build failed"
    echo "$TARGET" > "$OUT/apt/$TARGET.txt"
    ok "$N_CLOSURE closure debs indexed (Packages + Release, [trusted=yes] file: source)"
else
    cp "$BUNDLE/pool/repo/CLOSURE_URIS.txt" "$OUT/apt/" 2>/dev/null || true
    empty apt "closure resolved but not downloaded (skeleton) — rerun without --no-download"
fi
rm -rf "$OUT/.bundle"

step "images/ (section 2: docker images, saved)"
python3 -c "import json;json.dump([],open('$OUT/images/images.json','w'))"
save_image(){ # $1 ref $2 dest-dir
    local ref="$1" dir="$2" name tag file
    docker image inspect "$ref" >/dev/null 2>&1 || return 1
    name="${ref%%:*}"; tag="${ref##*:}"; file="$(echo "$name" | tr '/' '_')_$tag.tar"
    docker save -o "$dir/$file" "$ref"
    python3 - "$dir/images.json" "$name" "$tag" "$file" "$(docker image inspect --format '{{.Id}}' "$ref")" "$(stat -c %s "$dir/$file")" <<'PY'
import json, sys
p, name, tag, f, iid, b = sys.argv[1:7]
l = json.load(open(p)); l.append({'name': name, 'tag': tag, 'file': f, 'id': iid, 'bytes': int(b)}); json.dump(l, open(p, 'w'), indent=1)
PY
    ok "$ref → $file ($(du -h "$dir/$file" | cut -f1))"
}
for ref in $IMAGES; do save_image "$ref" "$OUT/images" || fail "image $ref not present locally — build/pull it first (the medium never guesses)"; done

step "router/ + hardware/ (sections 3 + 7)"
empty router "no libvirt/KVM on the target boxes; the OpenWrt qcow2 + opkg set are not fetched (routerless single-device isle)"
empty hardware "no Hardware Apps in this release (tree-1 not built)"

step "modules/ (section 5: offline module debs, wheels inside)"
( cd "$FRAMEWORK" && PYTHONPATH=.:modules python3 - "$MODULES" "$OUT/modules" <<'PY'
import json, shutil, sys, os
from appstore.app_deb_builder import generate, analyze, pool_dir
mods, out = sys.argv[1].split(','), sys.argv[2]
a = analyze(); index = {}
for m in mods:
    r = generate(m, analysis=a, flavor='offline')
    if not r.get('ok'):
        print('   %s: REFUSED — %s' % (m, r.get('refusal'))); continue
    src = os.path.join(pool_dir(), r['file']); shutil.copy(src, out)
    index[m] = {'file': r['file'], 'bytes': r['bytes']}
    print('   %s: %s (%d B)' % (m, r['file'], r['bytes']))
json.dump(index, open(os.path.join(out, 'modules.json'), 'w'), indent=1)
PY
) || fail "module deb generation failed"
[ "$(ls "$OUT"/modules/*.deb 2>/dev/null | wc -l)" -gt 0 ] || empty modules "no module debs requested"

step "engines/ (section 6: engine images + their isle compose/helpers)"
mkdir -p "$OUT/engines/reticulum"
python3 -c "import json;json.dump([],open('$OUT/engines/reticulum/images.json','w'))"
for ref in $ENGINE_IMAGES; do save_image "$ref" "$OUT/engines/reticulum" || fail "engine image $ref not present — docker compose -f polari-rf-node/docker-compose.reticulum.yml build"; done
cp "$ROOT"/polari-cli/shells/offline/reticulum/* "$OUT/engines/reticulum/"
python3 - "$OUT/engines/engines.json" <<'PY'
import json, sys
json.dump({'reticulum': {'image': 'pol-reticulum:staging', 'dir': 'reticulum/', 'enable': 'reticulum/reticulum-enable.sh',
                         'pins': {'rns': '0.9.4', 'lxmf': '0.6.3'}, 'ports': [4242, 4285],
                         'usedBy': ['reticulum']}}, open(sys.argv[1], 'w'), indent=1)
PY
ok "engines: reticulum (sidecar image + isle compose + enable/peer/status helpers)"

step "scripts/ (section 8)"
cp "$ROOT"/polari-cli/shells/offline/*.sh "$OUT/scripts/"
chmod +x "$OUT"/scripts/*.sh "$OUT"/engines/reticulum/*.sh
ok "$(ls "$OUT/scripts" | tr '\n' ' ')"

step "marker, manifest, README, SHA256SUMS"
python3 - "$OUT" "$VERSION" "$TARGET" "$SHA" <<'PY'
import json, os, sys, datetime, socket, subprocess
out, ver, target, sha = sys.argv[1:5]
def section(name):
    d = os.path.join(out, name); files = []
    for root, _, fs in os.walk(d):
        for f in fs: files.append(os.path.join(root, f))
    empty = os.path.join(d, 'EMPTY')
    return {'present': not os.path.exists(empty), 'files': len(files),
            'bytes': sum(os.path.getsize(f) for f in files),
            **({'emptyReason': open(empty).read().strip()} if os.path.exists(empty) else {})}
sections = {s: section(s) for s in ('debs', 'apt', 'images', 'router', 'modules', 'engines', 'hardware', 'scripts')}
debs = {f.split('_')[0]: f for f in sorted(os.listdir(os.path.join(out, 'debs')))}
mods = json.load(open(os.path.join(out, 'modules', 'modules.json'))) if os.path.exists(os.path.join(out, 'modules', 'modules.json')) else {}
comps = {}
for repo, key in (('polari-rf-node/polari-framework', 'prf-backend'), ('polari-rf-node/polari-platform-angular', 'prf-frontend'),
                  ('Isle-Mesh', 'isle-mesh'), ('polari-app-shell', 'app-shell'), ('polari-cli', 'pol-cli')):
    try: comps[key] = {'sha': subprocess.check_output(['git', '-C', os.path.join(os.path.dirname(out), '..', repo), 'rev-parse', '--short', 'HEAD'], text=True).strip()}
    except Exception: comps[key] = {'sha': '?'}
m = {'polari': ver, 'flavor': 'offline', 'target': target, 'superproject': sha,
     'builtAt': datetime.datetime.now().isoformat(timespec='seconds'), 'builtOn': socket.gethostname(),
     'components': comps, 'debs': debs, 'modules': mods,
     'images': json.load(open(os.path.join(out, 'images', 'images.json'))),
     'engines': json.load(open(os.path.join(out, 'engines', 'engines.json'))),
     'sections': sections, 'template': 'AI-Notes/guides/OFFLINE_BUILD_TEMPLATE.md §2',
     'rule': 'offline install: every part from a section here or a refusal naming it; never a network fallback'}
json.dump(m, open(os.path.join(out, 'manifest.json'), 'w'), indent=1)
open(os.path.join(out, 'ISLE_OFFLINE_BUNDLE'), 'w').write('polari offline medium %s flavor=offline target=%s sections=%s\n' % (
    ver, target, ','.join(s for s in sections if sections[s]['present'])))
total = sum(s['bytes'] for s in sections.values())
open(os.path.join(out, 'README.md'), 'w').write(f'''# Polari {ver} — OFFLINE medium ({target})

This directory is the whole install for a machine with NO internet: every part
the online route would fetch is in a section below. Install:

    sudo bash scripts/offproof.sh start          # optional: arm the no-internet proof
    sudo bash scripts/install-offline.sh         # verify → mode=offline → apt closure → images → platform deb
    (open the Isle App Store → "Create my own isle", or: sudo isle core-install)
    sudo bash scripts/install-app-offline.sh household     # a module from modules/
    sudo bash scripts/offproof.sh report         # the counters: must read 0

THE RULE: an offline install never falls back to the network. A part that is
not here is refused by section name — add it to the medium or install the
online package (polari-complete). The mode is recorded in
/etc/polari/install-mode (offline) by the deb itself.

Sections ({total/1e6:.0f} MB total):
''' + ''.join('- `%s/` — %s\n' % (s, ('%d files, %.1f MB' % (v['files'], v['bytes']/1e6)) if v['present'] else 'EMPTY: ' + v['emptyReason']) for s, v in sections.items())
+ f'''
Chunking to USB/DVD sets: `python3 -m appstore.offline_chunker plan <this dir> usb8 <out>` (framework);
this build is one directory. Verify any copy: `bash scripts/verify-offline.sh <dir>`.
Template + how it works: AI-Notes/guides/OFFLINE_BUILD_TEMPLATE.md. Components: {json.dumps(comps)}
''')
PY
( cd "$OUT" && find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS )
ok "manifest.json + README.md + ISLE_OFFLINE_BUNDLE + SHA256SUMS ($(wc -l < "$OUT/SHA256SUMS") files)"
bash "$OUT/scripts/verify-offline.sh" "$OUT"
echo
ok "OFFLINE MEDIUM: $OUT ($(du -sh "$OUT" | cut -f1))"
