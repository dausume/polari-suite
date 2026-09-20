#!/bin/bash
# polari-jenkins/routes/destinations.sh — WHERE EACH ROUTE PUSHES, IN ONE PLACE.
#
# His ask, 2026-09-19: *"we should explicitly call them registry and release
# tokens"* and *"the tokens must make clear WHICH registry and WHICH release pool
# they go to."*
#
# A secret's name should say what it is FOR, and a listing of secrets should say
# where the thing it unlocks actually GOES. That second half is only honest if
# the destination a listing prints is the same string the route pushes to — so
# the constants live here, the routes read them from here, and the secrets
# catalogue renders its prose from here. A catalogue that carried its own copy of
# "ghcr.io/dausume" would be a promise nobody checks, and it would be wrong the
# first time somebody ran the pipeline in app mode.
#
# APP MODE is exactly that case. A developer maintaining one Polari app publishes
# to THEIR OWN owner/namespace (`CI_ROUTE_TARGET`), never upstream — so every
# destination below is derived from the owner, not written down. The strings in
# the docs are the suite-mode defaults, which is what `route_owner` returns when
# the device is not in app mode.
#
# SOURCED, never executed on its own (executing it prints the table).
[ "${BASH_SOURCE[0]}" = "${0}" ] && set -euo pipefail

CI_UPSTREAM_OWNER="${CI_UPSTREAM_OWNER:-dausume}"

# The owner/namespace THIS device publishes under. In app mode it is the
# developer's own; routes/_lib.sh refuses an app-mode device that names the
# upstream owner, so this can never quietly resolve to upstream for a fork.
route_owner() {
    if [ "${CI_MODE:-suite}" = app ] && [ -n "${CI_ROUTE_TARGET:-}" ]; then
        printf '%s' "$CI_ROUTE_TARGET"
    else
        printf '%s' "$CI_UPSTREAM_OWNER"
    fi
}

# --------------------------------------------------------------- the constants
# Each route reads its destination from exactly one of these.
dest_release_repo()  { printf '%s/polari-suite' "$(route_owner)"; }              # github-release
dest_homebrew_tap()  { printf '%s/homebrew-polari' "$(route_owner)"; }           # homebrew
dest_registry_ns()   { printf '%s' "${GHCR_NS:-ghcr.io/$(route_owner)}"; }       # ghcr
dest_registry_user() { route_owner; }
DEST_REGISTRY_IMAGES="${DEST_REGISTRY_IMAGES:-prf-backend prf-frontend pol-reticulum}"
dest_apt_host()      { printf '%s' "${APT_HOST:-deploy@apt.polari-systems.org}"; }
dest_apt_dist()      { printf '%s' "${APT_DIST:-stable}"; }
dest_apt_url()       { printf 'https://apt.polari-systems.org/ (%s)' "$(dest_apt_dist)"; }

# ------------------------------------------------- the prose a listing prints
# ONE sentence per route, built from the constants above, so what a person reads
# is what the route does.
route_destination() {  # route_destination <route>
    case "$1" in
        github-release) printf 'release pool: github.com/%s/releases' "$(dest_release_repo)" ;;
        homebrew)       printf 'the pol formula in github.com/%s' "$(dest_homebrew_tap)" ;;
        ghcr)           printf 'registry: %s (%s)' "$(dest_registry_ns)" "$(printf '%s' "$DEST_REGISTRY_IMAGES" | tr ' ' ',' | sed 's/,/, /g')" ;;
        apt-repo)       printf 'apt repository: %s → %s' "$(dest_apt_host)" "$(dest_apt_url)" ;;
        *)              return 1 ;;
    esac
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    echo "# where each route pushes (owner: $(route_owner), mode: ${CI_MODE:-suite})"
    for r in github-release homebrew ghcr apt-repo; do printf '%-16s %s\n' "$r" "$(route_destination "$r")"; done
fi
