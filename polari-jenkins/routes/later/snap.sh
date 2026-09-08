#!/bin/bash
# Snap Store: the store SHELL as a classic snap (manual review by Canonical — D10). Refuses until snap/snapcraft.yaml exists in polari-app-shell.
source "$(dirname "$0")/../_lib.sh"
need SNAPCRAFT_LOGIN packaging/snapcraft_login
[ -f polari-app-shell/snap/snapcraft.yaml ] || { echo "[$ROUTE] REFUSED: polari-app-shell/snap/snapcraft.yaml does not exist yet (ci-6c)"; exit 3; }
run bash -c "printf '%s' \"\$SNAPCRAFT_LOGIN\" > /tmp/snap.login && snapcraft login --with /tmp/snap.login && rm -f /tmp/snap.login"
run bash -c "cd polari-app-shell && snapcraft pack && snapcraft upload --release=edge *.snap"
record "https://snapcraft.io/isle-app-store"
