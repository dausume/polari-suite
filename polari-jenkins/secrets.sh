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

secrets_have() { # secrets_have <area/name> — present AND non-empty, under the new name OR the pre-ci-12 one
    local d old; d="$(secrets_dir)"
    [ -s "$d/$1" ] && return 0
    sudo -n test -s "$d/$1" 2>/dev/null && return 0
    old="$(secrets_old_name "$1" 2>/dev/null || true)"
    [ -n "$old" ] || return 1
    [ -s "$d/$old" ] && return 0
    sudo -n test -s "$d/$old" 2>/dev/null
}

# ---------------------------------------------------------- THE ONE CATALOGUE
# His ask 2026-09-19: *"we should explicitly call them registry and release
# tokens"*, and *"the tokens must make clear WHICH registry and WHICH release
# pool they go to."*
#
# So a secret has a NAME that says what it is for, and a DESTINATION that says
# where the thing it unlocks goes. Both live here, once. The destination is not
# written down — it is rendered by routes/destinations.sh from the very
# constants the route scripts push to, so the catalogue cannot drift from
# reality, and in app mode it says the DEVELOPER'S namespace rather than
# upstream's.
# shellcheck source=routes/destinations.sh
[ -f "$SECRETS_DIR_SELF/routes/destinations.sh" ] && . "$SECRETS_DIR_SELF/routes/destinations.sh"

# Which ACTIVE route needs which secret — one declaration, read by the
# doctor (host side), by pol jenkins secrets status and by the setup.
secrets_route_requires() { # secrets_route_requires <route> → area/name…
    case "$1" in
        github-release) echo "github/release_token" ;;
        homebrew)       echo "github/release_token" ;;
        ghcr)           echo "github/registry_token" ;;
        apt-repo)       echo "signing/apt_signing_gpg signing/apt_signing_keyid ssh/distribution_host_key" ;;
        *)              return 1 ;;
    esac
}
SECRETS_ACTIVE_ROUTES="github-release ghcr homebrew apt-repo"
SECRETS_PARKED_ROUTES="dockerhub npm pypi launchpad snap"

# ------------------------------------------------------- BACKWARD COMPATIBILITY
# ci-12 renamed the two GitHub tokens so their names say what they are FOR.
# A device that already holds one under the old name keeps working: every read
# falls back, and the doctor says, once, how to rename it. Silence would be the
# wrong kindness here — the old name stays in place and nobody ever fixes it.
secrets_old_name() {  # secrets_old_name <new> → the pre-ci-12 name, or nothing
    case "$1" in
        github/release_token)  echo "github/github_token" ;;
        github/registry_token) echo "registries/ghcr_token" ;;
    esac
}

# The name a secret is ACTUALLY stored under on this device: the new one if it
# is there, else the old one if that is, else the new one (so a refusal names
# what to create, not what is deprecated).
secrets_stored_as() {  # secrets_stored_as <new>
    local old
    _secrets_present "$1" && { printf '%s' "$1"; return 0; }
    old="$(secrets_old_name "$1")"
    if [ -n "$old" ] && _secrets_present "$old"; then printf '%s' "$old"; return 0; fi
    printf '%s' "$1"
}

_secrets_present() {
    local d; d="$(secrets_dir)"
    [ -s "$d/$1" ] && return 0
    sudo -n test -s "$d/$1" 2>/dev/null
}

# The secrets that are present under a pre-ci-12 name, one 'old new' per line.
secrets_legacy_names() {
    local new old
    for new in github/release_token github/registry_token; do
        old="$(secrets_old_name "$new")"
        [ -n "$old" ] || continue
        if ! _secrets_present "$new" && _secrets_present "$old"; then printf '%s %s\n' "$old" "$new"; fi
    done
}

# What each secret is FOR, and WHERE the thing it unlocks goes. `destination` is
# rendered, never stored — see routes/destinations.sh.
secrets_destination() {  # secrets_destination <area/name>
    local r out="" d
    for r in $SECRETS_ACTIVE_ROUTES; do
        case " $(secrets_route_requires "$r") " in *" $1 "*) ;; *) continue ;; esac
        d="$(route_destination "$r" 2>/dev/null || true)"
        [ -n "$d" ] || continue
        case " $out " in *" $d "*) ;; *) out="${out:+$out; }$d" ;; esac
    done
    case "$1" in
        signing/cosign_key|signing/cosign_password)
            out="signs what the ghcr and github-release routes publish (optional)" ;;
        github/github_ssh_key)
            out="the version tag on github.com/$(dest_release_repo) (an alternative to the release token, for the tag push only)" ;;
        polari/cicd_ingest_token)
            out="the Polari core that holds this device's settings (posting-only: it mirrors runs and verdicts IN, and can do nothing else)" ;;
        admin/jenkins_admin_password)
            out="this controller's own login, on 127.0.0.1 only" ;;
    esac
    printf '%s' "${out:-(no active route uses it)}"
}

secrets_routes_of() {  # secrets_routes_of <area/name> → the routes that need it
    local r out=""
    for r in $SECRETS_ACTIVE_ROUTES; do
        case " $(secrets_route_requires "$r") " in *" $1 "*) out="${out:+$out, }$r" ;; esac
    done
    printf '%s' "$out"
}

# `name — destination — routes — present/absent`, the ONE rendering every
# listing uses (pol jenkins secrets status, the doctor's route rows, the setup).
secrets_catalog_line() {  # secrets_catalog_line <area/name>
    local stored routes; stored="$(secrets_stored_as "$1")"; routes="$(secrets_routes_of "$1")"
    printf '%s — %s%s — %s\n' "$1" "$(secrets_destination "$1")" \
        "${routes:+ — routes: $routes}" \
        "$(if secrets_have "$1"; then
               [ "$stored" = "$1" ] && echo present || echo "present (under the OLD name $stored)"
           else echo absent; fi)"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    echo "posture: $(secrets_mode)   dir: $(secrets_dir)   ci user: $CI_USER"
    secrets_list | sed 's/^/  /'
    echo
    echo "catalogue — name, where the thing it unlocks GOES, and which routes use it:"
    for _r in $SECRETS_ACTIVE_ROUTES; do
        for _s in $(secrets_route_requires "$_r"); do
            case " ${_seen:-} " in *" $_s "*) continue ;; esac
            _seen="${_seen:-} $_s"
            printf '  %s\n' "$(secrets_catalog_line "$_s")"
        done
    done
fi
