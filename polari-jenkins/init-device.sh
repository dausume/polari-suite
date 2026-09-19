#!/bin/bash
# polari-jenkins/init-device.sh — make THIS machine a pipeline device, and
# put the secrets where (C) wants them. Run as root:
#
#   sudo pol jenkins init-device [--dry-run]
#
# What it does, and nothing else:
#   1. creates the system user `polari-ci` (no login shell, no home login,
#      no password) and puts it in the `docker` group — the controller runs
#      AS that user, so "the pipeline process" is a real, nameable thing;
#   2. creates /etc/polari-jenkins/secrets  root:polari-ci 0750, and every
#      secret inside it root:polari-ci 0640. Readable by: root (a person
#      who typed sudo) and the pipeline process. NOT by the logged-in
#      human, NOT by anything else they run;
#   3. MOVES any secret already sitting in polari-jenkins/secrets/ there
#      (naming each one it moved — none are printed, only their names);
#   4. chowns jenkins_home/ and pool/ to polari-ci;
#   5. writes JENKINS_UID / JENKINS_GID / POLARI_SECRETS_DIR into .env, so
#      docker-compose.yml runs the controller as that user and mounts the
#      system secrets directory.
#
# It does NOT install packages, open a port, touch libvirt, or change the
# posture of any deployment. Re-running it is safe (idempotent).
set -euo pipefail

J="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=secrets.sh
source "$J/secrets.sh"

DRY=0
while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY=1 ;;
        --help|-h) sed -n '2,22p' "$0"; exit 0 ;;
        *) echo "init-device.sh: unknown argument '$1' (--dry-run --help)" >&2; exit 2 ;;
    esac; shift
done

run() { if [ "$DRY" = 1 ]; then echo "  would: $*"; else "$@"; fi; }
say() { echo "[init-device] $*"; }

[ "$(id -u)" = 0 ] || { echo "init-device must run as root: sudo pol jenkins init-device" >&2; exit 2; }

OWNER="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"

# 1. the pipeline user
if id -u "$CI_USER" >/dev/null 2>&1; then
    say "user $CI_USER exists (uid $(id -u "$CI_USER"))"
else
    say "creating the system user $CI_USER (no login shell, no password)"
    run useradd --system --create-home --home-dir "/var/lib/$CI_USER" --shell /usr/sbin/nologin "$CI_USER"
fi
if getent group docker >/dev/null 2>&1; then
    if id -nG "$CI_USER" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then say "$CI_USER is already in the docker group"
    else say "adding $CI_USER to the docker group (it builds images through the socket — root-equivalent, which is why only it and one admin belong there)"
         run usermod -aG docker "$CI_USER"; fi
else
    say "WARNING: no docker group on this machine — install docker before pol jenkins up"
fi

# 2. the secrets directory
say "secrets directory: $CI_SECRETS_SYSTEM (root:$CI_USER 0750; files 0640)"
run install -d -o root -g "$CI_USER" -m 0750 "$CI_SECRETS_SYSTEM"
for area in admin github registries signing packaging ssh; do
    run install -d -o root -g "$CI_USER" -m 0750 "$CI_SECRETS_SYSTEM/$area"
done

# 3. move anything already in the repo
MOVED=0
if [ -d "$CI_SECRETS_REPO" ]; then
    while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        say "moving secret '$rel' out of the checkout (its VALUE is never printed)"
        run install -D -o root -g "$CI_USER" -m 0640 "$CI_SECRETS_REPO/$rel" "$CI_SECRETS_SYSTEM/$rel"
        run shred -u "$CI_SECRETS_REPO/$rel" 2>/dev/null || run rm -f "$CI_SECRETS_REPO/$rel"
        MOVED=$((MOVED+1))
    done < <(find "$CI_SECRETS_REPO" -mindepth 2 -type f ! -name '*.example' ! -name '.gitkeep' \
                  ! -name 'README.md' ! -name 'ROTATION.log' -printf '%P\n' 2>/dev/null | sort)
fi
say "$MOVED secret(s) moved; polari-jenkins/secrets/ keeps only *.example and the README from here on"
# re-assert the modes on everything already there
if [ "$DRY" = 0 ] && [ -d "$CI_SECRETS_SYSTEM" ]; then
    find "$CI_SECRETS_SYSTEM" -type d -exec chown root:"$CI_USER" {} + -exec chmod 0750 {} +
    find "$CI_SECRETS_SYSTEM" -type f -exec chown root:"$CI_USER" {} + -exec chmod 0640 {} +
fi

# 4. state directories belong to the pipeline user
for d in jenkins_home pool; do
    run install -d -o "$CI_USER" -g "$CI_USER" -m 0750 "$J/$d"
    run chown -R "$CI_USER":"$CI_USER" "$J/$d"
done

# 5. .env — the controller runs AS polari-ci and mounts the system secrets
UIDN=$(id -u "$CI_USER" 2>/dev/null || echo '')
GIDN=$(id -g "$CI_USER" 2>/dev/null || echo '')
if [ "$DRY" = 1 ]; then
    echo "  would: write JENKINS_UID/JENKINS_GID/POLARI_SECRETS_DIR into $J/.env"
else
    [ -f "$J/.env" ] || install -o "$OWNER" -m 0600 "$J/.env.example" "$J/.env"
    set_kv() { grep -q "^$1=" "$J/.env" && sed -i "s#^$1=.*#$1=$2#" "$J/.env" || printf '%s=%s\n' "$1" "$2" >> "$J/.env"; }
    set_kv JENKINS_UID "$UIDN"
    set_kv JENKINS_GID "$GIDN"
    set_kv POLARI_SECRETS_DIR "$CI_SECRETS_SYSTEM"
    getent group docker >/dev/null 2>&1 && set_kv DOCKER_GID "$(getent group docker | cut -d: -f3)"
    chown "$OWNER" "$J/.env" 2>/dev/null || true
    say ".env: JENKINS_UID=$UIDN JENKINS_GID=$GIDN POLARI_SECRETS_DIR=$CI_SECRETS_SYSTEM"
fi

cat <<EOF

[init-device] done. The posture from here on:
  secrets      $CI_SECRETS_SYSTEM   root:$CI_USER 0750, files 0640
               → root (sudo) and the pipeline process ($CI_USER). Nobody else,
                 including $OWNER's own shell and anything it runs.
  controller   runs as $CI_USER ($UIDN:$GIDN), docker group, loopback port only
  put a secret sudo pol jenkins secrets put <area>/<name>     (reads stdin)
  check it     pol jenkins doctor
EOF
