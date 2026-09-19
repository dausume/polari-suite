#!/bin/bash
# polari-jenkins/secrets.sh — WHERE the auth material lives and WHO can
# read it. (C) of ci-7, his ask 2026-09-19: "the secrets involved are only
# accessible via either sudo or the pipeline process itself, never a third
# party."
#
# Two postures, and the doctor is loud about which one is in force:
#
#   system  /etc/polari-jenkins/secrets   root:polari-ci 0750, files 0640
#           → root (i.e. a person who typed sudo) and the polari-ci system
#             user the controller runs as. Nobody else, including the
#             human who is logged in. This is the posture (C) asks for.
#           Created by:  sudo pol jenkins init-device
#
#   repo    polari-jenkins/secrets        owned by the host user, 0600
#           → readable by EVERY process of that user: a browser extension,
#             a node_modules postinstall, any script they run. Git never
#             sees it, but that is not the same as protected. Fallback
#             only, until init-device has run.
#
# SOURCED, not executed (executing prints the posture).
# strict mode belongs to the EXECUTABLE; sourcing this must not change the
# caller's shell options (jenkins.sh runs `set -eu` on purpose).
[ "${BASH_SOURCE[0]}" = "${0}" ] && set -euo pipefail

SECRETS_DIR_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CI_USER="${CI_USER:-polari-ci}"
CI_SECRETS_SYSTEM="${CI_SECRETS_SYSTEM:-/etc/polari-jenkins/secrets}"
CI_SECRETS_REPO="${CI_SECRETS_REPO:-$SECRETS_DIR_SELF/secrets}"

secrets_mode() { [ -d "$CI_SECRETS_SYSTEM" ] && echo system || echo repo; }
secrets_dir()  { [ -d "$CI_SECRETS_SYSTEM" ] && echo "$CI_SECRETS_SYSTEM" || echo "$CI_SECRETS_REPO"; }

# area/name for every REAL secret (examples, keepers and docs excluded).
# In system posture the directory may not be listable by this user — then
# `sudo -n` is tried, and an empty answer means "needs sudo to list".
secrets_list() {
    local d; d="$(secrets_dir)"
    if [ -r "$d" ] && [ -x "$d" ]; then
        find "$d" -mindepth 2 -type f ! -name '*.example' ! -name '.gitkeep' \
             ! -name 'README.md' ! -name 'ROTATION.log' -printf '%P\n' 2>/dev/null | sort
    else
        sudo -n find "$d" -mindepth 2 -type f ! -name '*.example' ! -name '.gitkeep' \
             ! -name 'README.md' ! -name 'ROTATION.log' -printf '%P\n' 2>/dev/null | sort || true
    fi
}

secrets_have() { # secrets_have <area/name> — present AND non-empty
    local d; d="$(secrets_dir)"
    [ -s "$d/$1" ] && return 0
    sudo -n test -s "$d/$1" 2>/dev/null
}

# Which ACTIVE route needs which secret — one declaration, read by the
# doctor (host side) and by pol jenkins secrets status.
secrets_route_requires() { # secrets_route_requires <route> → area/name…
    case "$1" in
        github-release) echo "github/github_token" ;;
        homebrew)       echo "github/github_token" ;;
        ghcr)           echo "registries/ghcr_token" ;;
        apt-repo)       echo "signing/apt_signing_gpg signing/apt_signing_keyid ssh/distribution_host_key" ;;
        *)              return 1 ;;
    esac
}
SECRETS_ACTIVE_ROUTES="github-release ghcr homebrew apt-repo"
SECRETS_PARKED_ROUTES="dockerhub npm pypi launchpad snap"

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    echo "posture: $(secrets_mode)   dir: $(secrets_dir)   ci user: $CI_USER"
    secrets_list | sed 's/^/  /'
fi
