#!/bin/bash
# build-polari-complete-deb.sh — the ALL-IN-ONE installer (dl-3 of
# AI-Notes/plans/DOWNLOADS_PAGE_PLAN.md, ratified 2026-08-24).
#
# dpkg holds its lock during maintainer scripts, so a deb cannot
# install bundled sibling debs from postinst (dpkg-in-dpkg). This
# script therefore builds a TRUE MERGED package from the member debs
# in .generated/debs/:
#
#   polari-complete_<v>_<arch>.deb
#     files    = union of every member's file tree (REFUSES on any
#                path collision — members are ours, collisions are
#                build bugs, never silently clobbered)
#     Depends  = union of member Depends minus the members themselves
#     Provides/Conflicts/Replaces = every member, so the one-file and
#                piece-by-piece routes can never coexist or install
#                twice (reinstall-dedup rule)
#     scripts  = member maintainer scripts concatenated in INSTALL
#                order (reverse order for removal), each isolated in
#                a subshell under set -e
#
# Version = the isle-app-store member's (matches the /downloads
# headline). REFUSES unless every member is present — no silent
# partial bundle.
#
#   ./build-polari-complete-deb.sh [--debs-dir .generated/debs] [--flavor online|offline]
#
# FLAVORS (OFFLINE_INSTALL_PLAN.md §C, 2026-09-06): the same merged
# tree, but `--flavor offline` names the package polari-complete-offline
# (Provides/Conflicts/Replaces polari-complete — the two can never
# coexist; switching mode = installing the other flavor), stamps
# X-Polari-Install-Mode, and its postinst writes /etc/polari/install-mode
# BEFORE any member script runs — the one file every later step (isle
# create / core-install / onboard, and Polari via POLARI_INSTALL_MODE)
# reads. An offline install never falls back to the network.
set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEBS_DIR="$ROOT/.generated/debs"
FLAVOR="online"
while [ $# -gt 0 ]; do case "$1" in
    --debs-dir) DEBS_DIR="$2"; shift 2 ;;
    --flavor) FLAVOR="$2"; shift 2 ;;
    *) echo "unknown arg $1" >&2; exit 1 ;;
esac; done
G="\033[0;32m"; R="\033[0;31m"; C="\033[0;36m"; N="\033[0m"
ok(){ echo -e "${G}[ OK ]${N} $*"; }
fail(){ echo -e "${R}[FAIL]${N} $*" >&2; exit 1; }
step(){ echo; echo -e "${C}==> $*${N}"; }

# Install order — mirrors appstore/downloads_page.py INSTALL_ORDER.
MEMBERS="isle-mesh-cli polari-shell-core isle-app-store polari-isle"

step "collect members from $DEBS_DIR"
declare -A DEB VER ARCH
for m in $MEMBERS; do
    f=$(ls -1 "$DEBS_DIR/${m}_"*.deb 2>/dev/null | sort -V | tail -1 || true)
    [ -n "$f" ] || fail "member '$m' has no deb in $DEBS_DIR — build the full bundle first (no partial polari-complete)"
    DEB[$m]="$f"
    VER[$m]=$(dpkg-deb -f "$f" Version)
    ARCH[$m]=$(dpkg-deb -f "$f" Architecture)
    ok "$m ${VER[$m]} (${ARCH[$m]})"
done
VERSION="${VER[isle-app-store]}"
OUTARCH="all"
for m in $MEMBERS; do [ "${ARCH[$m]}" = "all" ] || OUTARCH="${ARCH[$m]}"; done

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
MERGED="$STAGE/root"
mkdir -p "$MERGED/DEBIAN"

step "merge file trees (collision = refusal)"
for m in $MEMBERS; do
    EX="$STAGE/m-$m"
    dpkg-deb -R "${DEB[$m]}" "$EX"
    while IFS= read -r -d '' f; do
        rel="${f#"$EX"/}"
        case "$rel" in DEBIAN/*) continue ;; esac
        dest="$MERGED/$rel"
        if [ -f "$dest" ]; then
            fail "path collision between members: /$rel (from $m) — fix the member builds, never clobber"
        fi
        mkdir -p "$(dirname "$dest")"
        cp -a "$f" "$dest"
    done < <(find "$EX" -type f -print0 -o -type l -print0)
done
ok "merged $(find "$MERGED" -type f | wc -l) files"

step "merged control"
# Depends union minus the members themselves (handles versioned
# entries like 'isle-mesh-cli (>= 0.1.20)').
ALLDEPS=""
for m in $MEMBERS; do
    d=$(dpkg-deb -f "${DEB[$m]}" Depends || true)
    ALLDEPS="$ALLDEPS,$d"
done
DEPS=$(echo "$ALLDEPS" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | \
    awk 'NF' | while read -r dep; do
        name="${dep%% *}"
        skip=0
        for m in $MEMBERS; do [ "$name" = "$m" ] && skip=1; done
        [ "$skip" = 0 ] && echo "$dep"
    done | sort -u | tr '\n' '\001' | sed 's/\x01$//; s/\x01/, /g')
PROVIDES=$(echo "$MEMBERS" | tr ' ' ',' | sed 's/,/, /g')
case "$FLAVOR" in
    online)  PKG="polari-complete"; PROVIDES_ALL="$PROVIDES" ;;
    offline) PKG="polari-complete-offline"; PROVIDES_ALL="$PROVIDES, polari-complete" ;;
    *) fail "--flavor must be online|offline (got $FLAVOR)" ;;
esac
cat > "$MERGED/DEBIAN/control" <<EOF
Package: $PKG
Version: $VERSION
Section: net
Priority: optional
Architecture: $OUTARCH
Depends: $DEPS
Provides: $PROVIDES_ALL
Conflicts: $PROVIDES_ALL
Replaces: $PROVIDES_ALL
X-Polari-Install-Mode: $FLAVOR
Maintainer: Polari Systems <dustinetts@gmail.com>
Description: Polari + Isle Mesh — everything in one installer ($FLAVOR)
 The complete suite as a single package: the isle networking CLI,
 the shared desktop shell runtime, the Isle App Store, and the
 finishing meta-package, merged so one install replaces the four
 piece-by-piece downloads.
$( [ "$FLAVOR" = offline ] \
  && echo " OFFLINE flavor: installs only from the offline medium (docker" \
  && echo " images, distro debs, module debs) and never falls back to the" \
  && echo " network; a missing part is refused by section name." \
  || echo " ONLINE flavor: distro dependencies and images arrive from the" \
  && echo " internet / the mesh registry during install." )
EOF
ok "Depends: $DEPS"

step "concatenate maintainer scripts (install order; removal reversed)"
concat_scripts() { # $1 = script name, $2 = member order
    local out="$MERGED/DEBIAN/$1" any=0
    {   echo '#!/bin/sh'
        echo 'set -e'
        if [ "$1" = postinst ]; then
            # the install-mode file FIRST (OFFLINE_INSTALL_PLAN.md §C)
            echo '# ---- polari install mode (written before any member script) ----'
            echo 'mkdir -p /etc/polari'
            echo "printf '%s\\n' '$FLAVOR' > /etc/polari/install-mode"
            if [ "$FLAVOR" = offline ]; then
                echo 'echo "polari: install-mode=offline — every later step (isle core-install / onboard) installs from the offline medium only; nothing falls back to the network"'
            fi
        fi
        for m in $2; do
            local src="$STAGE/m-$m/DEBIAN/$1"
            [ -f "$src" ] || continue
            any=1
            echo "# ---- from member: $m ----"
            echo '('
            sed '1{/^#!/d}' "$src"
            echo ')'
        done
    } > "$out"
    if [ "$any" = 1 ]; then chmod 0755 "$out"; else rm -f "$out"; fi
}
REVERSED=$(echo "$MEMBERS" | tr ' ' '\n' | tac | tr '\n' ' ')
concat_scripts preinst  "$MEMBERS"
concat_scripts postinst "$MEMBERS"
concat_scripts prerm    "$REVERSED"
concat_scripts postrm   "$REVERSED"
for s in preinst postinst prerm postrm; do
    [ -f "$MERGED/DEBIAN/$s" ] && sh -n "$MERGED/DEBIAN/$s" \
        && ok "$s merged + syntax-checked" || true
done

step "build + prune"
OUTDEB="$DEBS_DIR/${PKG}_${VERSION}_${OUTARCH}.deb"
dpkg-deb -b --root-owner-group "$MERGED" "$OUTDEB" >/dev/null
for old in "$DEBS_DIR"/${PKG}_*.deb; do
    [ "$old" = "$OUTDEB" ] || rm -f "$old"
done
ok "$(basename "$OUTDEB") ($(du -h "$OUTDEB" | cut -f1))"
