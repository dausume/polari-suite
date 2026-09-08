#!/bin/bash
# Launchpad PPA (ppa:polari/stable): SOURCE packages only (isle-mesh-cli, polari-cli). Needs debhelper packaging in those repos (ci-6b) — refuses until it exists.
source "$(dirname "$0")/../_lib.sh"
need LAUNCHPAD_SSH_KEY packaging/launchpad_ssh_key
for src in Isle-Mesh/isle-cli polari-cli; do
    [ -d "$src/debian" ] || { echo "[$ROUTE] REFUSED: $src has no debian/ source packaging yet (ci-6b) — Launchpad accepts source uploads only"; continue; }
    run bash -c "cd $src && debuild -S -sa -k\"\$APT_SIGNING_KEYID\" && dput ppa:polari/stable ../*.changes"
done
record "https://launchpad.net/~polari/+archive/ubuntu/stable"
