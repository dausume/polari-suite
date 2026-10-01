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
# frg-3 (his rulings 2026-09-27/30): THE FORGE — Forgejo, self-hosted. DUAL ROUTE always: GitHub is online
# availability, the forge is self-sustaining and, on production, THE DEFAULT people pull from. Its Debian
# registry REPLACES the old self-run apt route: the same debs from the same release pool, byte-identical,
# with apt indexes the forge signs itself (no signing key of ours, no rsync host).
# FORGE_URL is a knob (device.env); the default is the public forge on production. A chosen public name,
# like the release repo's — never a machine's real address (his no-real-identifiers rule).
dest_forge_url()          { local u="${FORGE_URL:-https://forge.polari-systems.org}"; printf '%s' "${u%/}"; }
dest_forge_host()         { local h; h="$(dest_forge_url)"; h="${h#*://}"; printf '%s' "${h%%/*}"; }
dest_forge_owner()        { route_owner; }
dest_forge_release_repo() { printf '%s/polari-suite' "$(dest_forge_owner)"; }                 # forgejo-release
dest_forge_registry()     { printf '%s/%s' "$(dest_forge_host)" "$(dest_forge_owner)"; }       # forgejo-registry
DEST_FORGE_APT_DIST="${FORGE_APT_DIST:-stable}"; DEST_FORGE_APT_COMPONENT="${FORGE_APT_COMPONENT:-main}"
dest_forge_apt_url()      { printf '%s/api/packages/%s/debian' "$(dest_forge_url)" "$(dest_forge_owner)"; }  # forgejo-apt
dest_forge_apt_line()     { printf 'deb [signed-by=/etc/apt/keyrings/polari-forge.asc] %s %s %s' "$(dest_forge_apt_url)" "$DEST_FORGE_APT_DIST" "$DEST_FORGE_APT_COMPONENT"; }
dest_forge_apt_key()      { printf '%s/repository.key' "$(dest_forge_apt_url)"; }
dest_forge_generic()      { printf '%s/api/packages/%s/generic/polari-offline' "$(dest_forge_url)" "$(dest_forge_owner)"; }  # forgejo-generic

# ------------------------------------------------- the prose a listing prints
# ONE sentence per route, built from the constants above, so what a person reads
# is what the route does.
route_destination() {  # route_destination <route>
    case "$1" in
        github-release)   printf 'release pool: github.com/%s/releases' "$(dest_release_repo)" ;;
        homebrew)         printf 'the pol formula in github.com/%s' "$(dest_homebrew_tap)" ;;
        ghcr)             printf 'registry: %s (%s)' "$(dest_registry_ns)" "$(printf '%s' "$DEST_REGISTRY_IMAGES" | tr ' ' ',' | sed 's/,/, /g')" ;;
        forgejo-release)  printf 'forge release pool: %s/%s/releases' "$(dest_forge_url)" "$(dest_forge_release_repo)" ;;
        forgejo-registry) printf 'forge registry: %s (%s)' "$(dest_forge_registry)" "$(printf '%s' "$DEST_REGISTRY_IMAGES" | tr ' ' ',' | sed 's/,/, /g')" ;;
        forgejo-apt)      printf 'forge apt repository: %s (%s %s, signed by the forge)' "$(dest_forge_apt_url)" "$DEST_FORGE_APT_DIST" "$DEST_FORGE_APT_COMPONENT" ;;
        forgejo-generic)  printf 'forge offline medium: %s/<version>' "$(dest_forge_generic)" ;;
        *)                return 1 ;;
    esac
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    echo "# where each route pushes (owner: $(route_owner), mode: ${CI_MODE:-suite})"
    for r in github-release homebrew ghcr forgejo-release forgejo-registry forgejo-apt forgejo-generic; do printf '%-17s %s\n' "$r" "$(route_destination "$r")"; done
fi
