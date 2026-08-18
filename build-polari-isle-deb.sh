#!/bin/bash
# build-polari-isle-deb.sh — the polari-isle BUNDLE, built on the spot
# from the checked-out suite (pub-3 of POLARI_SYSTEMS_ORG_PLAN.md).
#
# Produces, into .generated/debs/ (gitignored):
#   isle-mesh-cli_<v>_all.deb      from Isle-Mesh/isle-cli/shells
#   isle-app-store_<v>_all.deb     from polari-app-shell/shells
#   polari-isle_<v>_all.deb        the META-deb depending on both
#
# So a normal debian-route install works USING JUST THE CODE:
#   ./build-polari-isle-deb.sh
#   sudo apt install ./.generated/debs/isle-mesh-cli_*_all.deb \
#                    ./.generated/debs/isle-app-store_*_all.deb \
#                    ./.generated/debs/polari-isle_*_all.deb
# then: sudo isle core-install   (own isle — ends with the production-
# security walkthrough) or join an existing isle via its bootstrap.
#
# NO security material enters any deb — passwords/domain/certs are put
# in AT DEPLOY TIME by the walkthrough (isle security setup).
#
# Knobs:
#   --version <v>     bundle version                  (default 0.1.0)
#   --apt-url <url>   have postinst add this signed apt source (the
#                     pub-4 public repo, e.g. https://apt.polari-systems.org)
#                     — OFF by default; local/dev builds add no source
set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$ROOT/.generated/debs"
VERSION="0.1.0"
APT_URL=""
while [ $# -gt 0 ]; do case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    --apt-url) APT_URL="$2"; shift 2 ;;
    *) echo "unknown arg $1" >&2; exit 1 ;;
esac; done
G="\033[0;32m"; Y="\033[1;33m"; C="\033[0;36m"; N="\033[0m"
ok(){ echo -e "${G}[ OK ]${N} $*"; }
warn(){ echo -e "${Y}[WARN]${N} $*"; }
step(){ echo; echo -e "${C}==> $*${N}"; }
mkdir -p "$OUT"

# ---- 1. isle-mesh-cli from the Isle-Mesh checkout ----
step "isle-mesh-cli (from Isle-Mesh/)"
[ -f "$ROOT/Isle-Mesh/isle-cli/shells/build-cli-deb.sh" ] \
    || { echo "Isle-Mesh not pulled — ./bootstrap-dev.sh Isle-Mesh" >&2; exit 1; }
# version = 0.1.<commit-count> — monotonic with the branch, no hand-picked
# number to collide with (continues past the hand-staged 0.1.2x series)
CLI_VERSION="0.1.$(cd "$ROOT/Isle-Mesh" && git log --oneline | wc -l)"
( cd "$ROOT/Isle-Mesh/isle-cli/shells" \
    && bash build-cli-deb.sh --version "$CLI_VERSION" --output "$OUT" ) | tail -1
[ -f "$OUT/isle-mesh-cli_${CLI_VERSION}_all.deb" ] || { echo "cli deb not produced" >&2; exit 1; }
ok "isle-mesh-cli_${CLI_VERSION}_all.deb"

# ---- 2. isle-app-store from the polari-app-shell checkout ----
step "isle-app-store (from polari-app-shell/)"
if [ -f "$ROOT/polari-app-shell/shells/build-store-deb.sh" ]; then
    STORE_VERSION="0.1.$(cd "$ROOT/polari-app-shell" && git log --oneline | wc -l)"
    ( cd "$ROOT/polari-app-shell/shells" \
        && bash build-store-deb.sh --version "$STORE_VERSION" --output "$OUT" ) | tail -1
    [ -f "$OUT/isle-app-store_${STORE_VERSION}_all.deb" ] \
        && ok "isle-app-store_${STORE_VERSION}_all.deb" \
        || warn "store deb not produced — bundle still builds (Depends will pull it from an apt source instead)"
else
    warn "polari-app-shell not pulled — store deb skipped;"
    warn "pull it (./bootstrap-dev.sh polari-app-shell) or the bundle's"
    warn "Depends will need it from an apt source at install time"
fi

# ---- 3. the polari-isle META-deb ----
step "polari-isle meta-deb"
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/DEBIAN" "$STAGE/usr/share/doc/polari-isle"

cat > "$STAGE/usr/share/doc/polari-isle/README" <<'EOF'
polari-isle — polari + isle-mesh as ONE install.

After install, two doors (the membership rule — the running agent IS
membership; the store installs nothing on non-members):
  sudo isle core-install     make this device its own (single-device)
                             isle — ends with the production-security
                             walkthrough (deploy-time passwords/domain/
                             certs; generic self-hosting first, provider
                             post-step after)
  ...or join an existing isle via its bootstrap one-liner
                             (printed by core-install on the core).
EOF

cat > "$STAGE/DEBIAN/control" <<EOF
Package: polari-isle
Version: $VERSION
Section: utils
Priority: optional
Architecture: all
Depends: isle-mesh-cli (>= 0.1.20), isle-app-store
Maintainer: polari-systems <dustinetts@gmail.com>
Description: polari + isle-mesh bundled install (single download)
 Meta-package: the isle CLI (agents, DNS, store plumbing) and the
 native app store shell as one install. Security material is put in
 at deploy time by 'isle security setup' — never shipped in a deb.
EOF

cat > "$STAGE/DEBIAN/postinst" <<EOF
#!/bin/sh
# trust-seed/pointer ONLY — agent bring-up and credentials are explicit
# interactive steps (the 2026-08-09 incident rule + deploy-time security)
EOF
if [ -n "$APT_URL" ]; then
    cat >> "$STAGE/DEBIAN/postinst" <<EOF
# the public apt source (pub-4): further apps arrive piece-wise via apt
# even with nothing local
mkdir -p /etc/apt/sources.list.d
echo "deb [trusted=no] $APT_URL ./" > /etc/apt/sources.list.d/polari-isle.list
echo "polari-isle: apt source added ($APT_URL) — key setup: see the"
echo "download page (signed repo; the key is published there, not baked here)"
EOF
fi
cat >> "$STAGE/DEBIAN/postinst" <<'EOF'
echo "polari-isle installed. Two doors:"
echo "  sudo isle core-install    (own isle; ends with the security walkthrough)"
echo "  ...or join an existing isle (its core prints the bootstrap one-liner)"
exit 0
EOF
chmod 755 "$STAGE/DEBIAN/postinst"

dpkg-deb --build --root-owner-group "$STAGE" "$OUT/polari-isle_${VERSION}_all.deb" >/dev/null
ok "polari-isle_${VERSION}_all.deb"

echo
ok "bundle ready in $OUT:"
ls -sh1 "$OUT" | sed 's/^/   /'
echo "   install (normal debian route, just from this code):"
echo "     sudo apt install $OUT/isle-mesh-cli_*_all.deb \\"
echo "                      $OUT/isle-app-store_*_all.deb \\"
echo "                      $OUT/polari-isle_${VERSION}_all.deb"
