#!/bin/bash
# Our signed apt repo on the distribution VM (apt.polari-systems.org): reprepro include + rsync. ⛔ KC rotation before this host faces the web.
source "$(dirname "$0")/_lib.sh"
need APT_SIGNING_GPG signing/apt_signing_gpg; need APT_SIGNING_KEYID signing/apt_signing_keyid; need DISTRIBUTION_HOST_KEY ssh/distribution_host_key
HOST="${APT_HOST:-deploy@apt.polari-systems.org}"; REPO_DIR="${APT_REPO_DIR:-/srv/apt}"; DIST="${APT_DIST:-stable}"
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
export GNUPGHOME="$WORK/gnupg"; mkdir -m 0700 "$GNUPGHOME"
run bash -c "printf '%s\n' \"\$APT_SIGNING_GPG\" | gpg --batch --import"
mkdir -p "$WORK/repo/conf"; printf 'Codename: %s\nComponents: main\nArchitectures: amd64 all\nSignWith: %s\n' "$DIST" "$APT_SIGNING_KEYID" > "$WORK/repo/conf/distributions"
for deb in "$POOL_DIR"/debs/*.deb; do run reprepro -b "$WORK/repo" includedeb "$DIST" "$deb"; done
printf '%s\n' "$DISTRIBUTION_HOST_KEY" > "$WORK/key"; chmod 0600 "$WORK/key"
run rsync -a -e "ssh -i $WORK/key -o StrictHostKeyChecking=accept-new" "$WORK/repo/" "$HOST:$REPO_DIR/"
record "https://apt.polari-systems.org/ ($DIST)"
