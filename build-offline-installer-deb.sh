#!/bin/bash
# Wrap a VERIFIED full medium in a normal desktop installer application.
# Installing this package only stages files; launching its app runs the same
# local-only installer as removable media. No package hooks touch networking.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEDIUM="${1:?usage: build-offline-installer-deb.sh <medium> [output-dir]}"
OUTPUT="${2:-$ROOT/.generated/debs/offline-installer}"
MEDIUM=$(realpath "$MEDIUM")
bash "$ROOT/polari-cli/shells/offline/verify-offline.sh" "$MEDIUM"
VERSION=$(python3 - "$MEDIUM/manifest.json" <<'PY'
import json,sys
print(json.load(open(sys.argv[1]))['polari'])
PY
)
dpkg --validate-version "$VERSION"
ARCH=$(dpkg --print-architecture)
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
SHARE="$STAGE/usr/share/polari-offline-installer"
mkdir -p "$SHARE/medium" "$STAGE/DEBIAN" "$STAGE/usr/share/applications" "$OUTPUT"
# Immutable build inputs can share inodes while dpkg reads them. This avoids
# writing the multi-GB payload to disk again just to build a small revision.
if ! cp -al "$MEDIUM/." "$SHARE/medium/" 2>/dev/null; then
    rm -rf "$SHARE/medium"
    mkdir -p "$SHARE/medium"
    cp -a "$MEDIUM/." "$SHARE/medium/"
fi
cat > "$SHARE/launch.sh" <<'LAUNCH'
#!/bin/bash
set -eu
INSTALLER=/usr/share/polari-offline-installer/medium/scripts/install-offline.sh
for terminal in konsole gnome-terminal x-terminal-emulator xterm; do
    command -v "$terminal" >/dev/null 2>&1 || continue
    if [ "$terminal" = gnome-terminal ]; then
        exec "$terminal" --wait -- bash -c 'pkexec bash "$1"; result=$?; echo; if [ "$result" = 0 ]; then echo "Ready. Open Isle App Store to create your Isle."; else echo "Installation stopped (exit $result). See the message above."; fi; read -r -p "Press Enter to close…"' installer "$INSTALLER"
    fi
    exec "$terminal" -e bash -c 'pkexec bash "$1"; result=$?; echo; if [ "$result" = 0 ]; then echo "Ready. Open Isle App Store to create your Isle."; else echo "Installation stopped (exit $result). See the message above."; fi; read -r -p "Press Enter to close…"' installer "$INSTALLER"
done
echo "No terminal emulator found. Open the installer from a desktop with a terminal." >&2
exit 1
LAUNCH
chmod 755 "$SHARE/launch.sh"
cat > "$STAGE/usr/share/applications/polari-offline-installer.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Polari Offline Installer
Comment=Install a complete Isle using bundled files
Exec=/usr/share/polari-offline-installer/launch.sh
Icon=system-software-install
Terminal=false
Categories=System;PackageManager;
DESKTOP
SIZE=$(du -sk "$STAGE/usr" | cut -f1)
cat > "$STAGE/DEBIAN/control" <<EOF
Package: polari-offline-installer
Version: $VERSION
Architecture: $ARCH
Maintainer: Polari <polari@localhost>
Depends: bash, python3
Installed-Size: $SIZE
Section: admin
Priority: optional
Description: Complete Polari Isle offline installer
 Carries the platform packages, distro dependency closure, container images,
 and pristine OpenWrt router plus packages. Open Polari Offline Installer
 after installation. Compatible installed dependencies and images are reused.
EOF
dpkg-deb --build --root-owner-group --threads-max=1 -Zzstd -z3 "$STAGE" "$OUTPUT/polari-offline-installer_${VERSION}_${ARCH}.deb"
