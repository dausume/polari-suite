#!/bin/bash
# polari-jenkins/isle/core-artifacts.sh — THE CORE, PULLED (ci-9).
#
# His addendum, 2026-09-19: *"some people will also be using this pipeline as a
# way to maintain their own Polari Apps and will only be testing the one app
# they are developing."*
#
# ci-8 gave `CI_CORE_SOURCE=release:<tag>|release:latest` a SHAPE and a
# validation. Nothing resolved it. This does: in `app` mode (or whenever
# `CI_CORE_SOURCE` names a release), the core is not rebuilt — its debs are
# fetched ONCE from the official Polari release, verified against that release's
# SHA256SUMS, and cached under `<cache>/releases/<tag>/`. The isle test then
# installs THAT core and runs the developer's app against it.
#
#   core-artifacts.sh resolve        print the tag CI_CORE_SOURCE means (or `build`)
#   core-artifacts.sh fetch          resolve, fetch + verify, print the directory
#   core-artifacts.sh status         what is cached, for which tags
#
# THE ONE READER. The tag→assets lookup is `polari-cli/scripts/lib/providers.sh`
# — the same `release_tags_with_debs` / `release_asset_urls` that `pol prod`'s
# POL_PROD_DEBS=release:<tag> uses. There is no second GitHub reader here.
#
# WHAT IT CANNOT DO. An unpublished tag, or no network, is a REFUSAL that names
# the tag — never a silent fallback to building core, because "tested against
# polari-v2026.09.19" would then be a claim nobody could check. The doctor warns
# about exactly this before a run starts.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
J="$(cd "$HERE/.." && pwd)"
SUITE="$(cd "$J/.." && pwd)"
# shellcheck source=../device.sh
source "$J/device.sh"
# shellcheck source=../cache.sh
source "$J/cache.sh"

# Every log line goes to STDERR on purpose: stdout of `resolve` is the TAG and
# stdout of `fetch` is the report the pipeline parses. A log line on stdout
# would end up inside a captured variable — the kind of bug that only shows up
# on the first real run.
say()  { printf '[core-artifacts] %s\n' "$*" >&2; }
warn() { printf '[core-artifacts] %s\n' "$*" >&2; }
die()  { warn "REFUSED: $*"; exit 6; }

# ------------------------------------------------- the ONE providers reader
providers_lib() {
    local d
    for d in "${POLARI_PROVIDERS_LIB:-}" \
             "$SUITE/polari-cli/scripts/lib/providers.sh" \
             "${WORKSPACE:-/nowhere}/polari-cli/scripts/lib/providers.sh"; do
        [ -n "$d" ] && [ -r "$d" ] && { printf '%s' "$d"; return 0; }
    done
    return 1
}
load_providers() {
    local p
    p="$(providers_lib)" || die "polari-cli/scripts/lib/providers.sh is not in this checkout — it is the ONE reader of what a Polari release carries (git submodule update --init polari-cli)"
    # shellcheck source=/dev/null
    source "$p"
}

CORE_REPO_DEFAULT="dausume/polari-suite"
core_repo() {
    # suite mode and app mode both pull the CORE from upstream Polari: an app
    # developer's own routes publish their app, never the core.
    printf '%s' "${CI_CORE_REPO:-$CORE_REPO_DEFAULT}"
}

# ----------------------------------------------------------------- resolve
# CI_CORE_SOURCE → a tag, or the literal `build`. `release:latest` is the
# NEWEST release that actually carries debs — a release with none is not a core
# anybody can install, so it is not "latest" for this purpose.
resolve_tag() {
    local src="${1:-$CI_CORE_SOURCE}"
    case "$src" in
        build) printf 'build'; return 0 ;;
        release:) die "CI_CORE_SOURCE=release: with no tag — release:latest, or release:<a Polari release tag>" ;;
        release:*) ;;
        *) die "CI_CORE_SOURCE='$src' is neither release:<tag> nor build" ;;
    esac
    local want="${src#release:}" repo; repo="$(core_repo)"
    load_providers
    if [ "$want" = latest ]; then
        local newest
        newest="$(release_tags_with_debs "$repo" | head -1 | cut -f1 || true)"
        [ -n "$newest" ] || die "github.com/$repo publishes no release carrying .deb assets yet — CI_CORE_SOURCE=build until the first one is out (and say so in the record)"
        printf '%s' "$newest"
    else
        # verify it exists AND carries debs, so a typo is caught here and not
        # halfway through an isle stage
        local urls; urls="$(release_asset_urls "$repo" "$want" .deb || true)"
        [ -n "$urls" ] || die "release '$want' of github.com/$repo does not exist, or carries no .deb assets (check the tag, or the network)"
        printf '%s' "$want"
    fi
}

# ------------------------------------------------------------------- fetch
# Into <cache>/releases/<tag>/: the debs, SHA256SUMS, and the images when the
# release publishes them. ONCE — a second call on a complete directory verifies
# and returns. Never partially: a failed verification empties the directory so
# the next run cannot inherit half a core.
#
# It sets CORE_DIR (and the three cache-arithmetic variables) rather than
# printing the path: a `$(…)` capture would swallow the log lines with it.
CORE_DIR=""; CORE_ARTIFACTS_CACHED=0; CORE_ARTIFACTS_FETCHED=0; CORE_ARTIFACTS_SECONDS=0
fetch_release() {
    local tag="$1" repo dir urls u sums n=0 t0
    repo="$(core_repo)"
    dir="$(cache_area releases)/$tag"
    CORE_DIR="$dir"
    t0=$(date +%s)
    if [ -f "$dir/.complete" ]; then
        CORE_ARTIFACTS_CACHED=$(du -sb "$dir" 2>/dev/null | cut -f1 || echo 0)
        say "release $tag already cached ($(du -sh "$dir" | cut -f1)) — nothing fetched"
        cache_touch releases "$tag"
        CORE_ARTIFACTS_FETCHED=0
        CORE_ARTIFACTS_SECONDS=$(( $(date +%s) - t0 ))
        return 0
    fi
    load_providers
    rm -rf "$dir"; mkdir -p "$dir/debs"
    say "fetching the core artifacts of release $tag from github.com/$repo (once; they are cached)"
    urls="$(release_asset_urls "$repo" "$tag" .deb || true)"
    [ -n "$urls" ] || die "release $tag carries no .deb assets"
    for u in $urls; do
        curl -fL --retry 3 --max-time 900 -o "$dir/debs/$(basename "$u")" "$u" || die "could not fetch $(basename "$u") of $tag"
        n=$((n+1))
    done
    sums="$(release_asset_urls "$repo" "$tag" SHA256SUMS | head -1 || true)"
    if [ -n "$sums" ]; then
        curl -fL --retry 3 --max-time 120 -o "$dir/SHA256SUMS" "$sums" || die "could not fetch SHA256SUMS of $tag"
        # the release's SHA256SUMS covers the whole pool tree; check the lines
        # that name a deb we actually fetched, and REFUSE on any mismatch.
        local checked=0 bad=0 line sum name
        while read -r sum name; do
            name="${name#\*}"; name="$(basename "$name")"
            [ -f "$dir/debs/$name" ] || continue
            checked=$((checked+1))
            [ "$(sha256sum "$dir/debs/$name" | cut -d' ' -f1)" = "$sum" ] || { warn "SHA256 MISMATCH: $name"; bad=$((bad+1)); }
        done < "$dir/SHA256SUMS"
        if [ "$bad" -gt 0 ]; then rm -rf "$dir"; die "$bad of $checked deb(s) of $tag failed their SHA256 — nothing is kept"; fi
        say "verified $checked deb(s) against the release's SHA256SUMS"
    else
        warn "release $tag publishes no SHA256SUMS — the debs are cached UNVERIFIED (the record says so)"
        printf 'no SHA256SUMS published for %s\n' "$tag" > "$dir/UNVERIFIED"
    fi
    # images: only when the release actually published them. Never guessed.
    if images_published "$tag"; then
        printf 'ghcr.io/%s\n' "$(printf '%s' "$repo" | cut -d/ -f1)" > "$dir/IMAGES_FROM"
        say "images for $tag are published on ghcr — the isle test may pull them"
    else
        printf 'images not published for %s — the isle test installs from the debs only\n' "$tag" > "$dir/IMAGES"
        say "images not published for $tag — the isle test installs from the debs only"
    fi
    printf '%s\n' "$tag" > "$dir/.complete"
    cache_put releases "$tag" "the core debs of Polari release $tag (app mode's tested-against core)"
    say "$n deb(s) cached in $dir"
    CORE_ARTIFACTS_CACHED=0
    CORE_ARTIFACTS_FETCHED=$(du -sb "$dir" 2>/dev/null | cut -f1 || echo 0)
    CORE_ARTIFACTS_SECONDS=$(( $(date +%s) - t0 ))
}

images_published() {   # images_published <tag> — does ghcr carry prf-backend:<tag>?
    local owner tag="$1"
    owner="$(printf '%s' "$(core_repo)" | cut -d/ -f1)"
    command -v curl >/dev/null 2>&1 || return 1
    type registry_image_tags >/dev/null 2>&1 || return 1
    registry_image_tags "ghcr.io/$owner" prf-backend 2>/dev/null | grep -qx "${tag#polari-v}" && return 0
    registry_image_tags "ghcr.io/$owner" prf-backend 2>/dev/null | grep -qx "$tag"
}

# ------------------------------------------------------------------ status
do_status() {
    local d; d="$(cache_area releases)"
    echo "core source: $CI_CORE_SOURCE   mode: $CI_MODE${CI_APP_NAME:+ ($CI_APP_NAME)}"
    echo "cache:       $d"
    local t
    if [ -d "$d" ]; then
        for t in "$d"/*/; do
            [ -d "$t" ] || continue
            printf '  %-28s %8s  %s\n' "$(basename "$t")" "$(du -sh "$t" | cut -f1)" \
                "$([ -f "$t/.complete" ] && echo complete || echo INCOMPLETE)$([ -f "$t/UNVERIFIED" ] && echo ' (unverified)' || echo '')"
        done
    fi
    [ -n "$(ls -A "$d" 2>/dev/null)" ] || echo "  (nothing cached yet — core-artifacts.sh fetch)"
}

case "${1:-status}" in
    resolve) resolve_tag "${2:-}" ; echo ;;
    fetch)
        TAG="$(resolve_tag "${2:-}")"
        if [ "$TAG" = build ]; then
            say "CI_CORE_SOURCE=build — the core is rebuilt from this checkout; nothing to fetch"
            say "(in app mode that means your app's releases are tested against YOUR build, not an official release)"
            exit 0
        fi
        fetch_release "$TAG"
        # the pipeline reads these three lines (stdout; every log line went to stderr)
        echo "CORE_TAG=$TAG"
        echo "CORE_DIR=$CORE_DIR"
        echo "CORE_DEBS=$CORE_DIR/debs"
        # ci-9: the cache arithmetic this stage contributes, when a report was named
        [ -n "${CACHE_REPORT:-}" ] && python3 "$J/cache-manifest.py" report "$CACHE_REPORT" releases \
            "${CORE_ARTIFACTS_CACHED:-0}" "${CORE_ARTIFACTS_FETCHED:-0}" "${CORE_ARTIFACTS_SECONDS:-0}" >/dev/null 2>&1 || true
        ;;
    status)  do_status ;;
    --help|-h) sed -n '2,30p' "$0" ;;
    *) echo "core-artifacts.sh resolve|fetch|status" >&2; exit 2 ;;
esac
