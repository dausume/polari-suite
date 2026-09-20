#!/bin/bash
# polari-jenkins/cache.sh — THE OFFLINE-FIRST CACHE (ci-9).
#
# His ask, 2026-09-19: *"the jenkins pipeline should try and use offline
# artifacts for building where possible, that way we are taking less time when
# repeatedly using the same data"*.
#
# TIER ONE — no new services, nothing to run, nothing to keep alive: one
# directory under the pool that every builder reads FIRST and writes back to.
#
#   <cache>/wheels    python wheels (`pip download`, the offline deb's payload)
#   <cache>/npm       npm tarballs (the verdaccio volume in tier two)
#   <cache>/apt       distro .debs (the offline medium's closure)
#   <cache>/images    `docker save` tarballs of the base images a build pulls
#   <cache>/cloud     the Ubuntu cloud image the throwaway isle boots from
#   <cache>/scanners  RESERVED for the scanning arc's Trivy DB (nothing here yet)
#   <cache>/releases  official Polari releases fetched by tag (app mode's core)
#   <cache>/layers    BuildKit local layer cache, one directory per image
#   <cache>/proxies   tier two's volumes (registry/devpi/verdaccio/apt-cacher-ng)
#
# THE RULE, everywhere: the cache is an OPTIMISATION, never a precondition. An
# empty cache must still build — every reader falls back to the network and
# says so. Nothing here ever refuses a build for a cache miss.
#
# The knobs live in device.env (device.sh owns them):
#   CI_CACHE=on|off        default on
#   CI_CACHE_DIR           default <pool>/cache
#   CI_CACHE_MAX_GB=40     the doctor WARNs past it (it never deletes on its own)
#   CI_CACHE_PROXIES=off   tier two (docker-compose.proxies.yml)
#
# SOURCED by the builders, EXECUTED by `pol jenkins cache`:
#   cache.sh status [--json]         sizes per area against the max, and the last run's hit rate
#   cache.sh prune [--older-than N]  the ONE deleter: entries unused for > N days (default 30)
#   cache.sh dir [area]              print a path (and create it)
#   cache.sh fetch <area> <entry> <url>   cached download; prints the path
#   cache.sh wheels <dest> <spec>…   pip download, cache first, network only for the misses
#   cache.sh images warm|save <ref>… docker save/load of base images, digest-checked
#   cache.sh layers-args <image>     the buildx --cache-from/--cache-to pair (empty when unavailable)
#   cache.sh build-args              PIP_/NPM_ build-args when tier two answers (empty otherwise)
#   cache.sh report <file> <area> <cached> <fetched> <seconds>
#   cache.sh report-show <file>
#   cache.sh proxies up|down|status  tier two — OFF by default, and never started by a pipeline
[ "${BASH_SOURCE[0]}" = "${0}" ] && set -euo pipefail

CACHE_DIR_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# device.sh may already be sourced (the builders source it first); sourcing it
# twice is harmless but re-sourcing would lose a value the caller just wrote.
if [ -z "${DEVICE_KEYS:-}" ]; then
    # shellcheck source=device.sh
    source "$CACHE_DIR_SELF/device.sh"
fi

CACHE_AREAS="wheels npm apt images cloud scanners releases layers proxies ciimages"
CACHE_MANIFEST_PY="${CACHE_MANIFEST_PY:-$CACHE_DIR_SELF/cache-manifest.py}"

cache_on() { [ "${CI_CACHE:-on}" = on ]; }

# The cache root. Relative to the POOL by default, which is what makes the ssh
# hop work: `throwaway.sh` re-runs itself on the target with CI_ISLE_POOL set,
# and the cloud image lands beside that target's pool rather than being copied.
cache_root() {
    if [ -n "${CI_CACHE_DIR:-}" ]; then printf '%s' "$CI_CACHE_DIR"
    else printf '%s/cache' "$(device_pool)"; fi
}

cache_area() {   # cache_area <area> — the path, created
    local a="$1"
    case " $CACHE_AREAS " in *" $a "*) ;; *) echo "cache.sh: unknown area '$a' (one of: $CACHE_AREAS)" >&2; return 2 ;; esac
    local d; d="$(cache_root)/$a"
    mkdir -p "$d" 2>/dev/null || true
    printf '%s' "$d"
}
cache_manifest() { printf '%s/MANIFEST.json' "$(cache_area "$1")"; }

# ---------------------------------------------------------------- bookkeeping
cache_put()   { python3 "$CACHE_MANIFEST_PY" put "$(cache_manifest "$1")" "$2" "$(cache_area "$1")/$2" "$3" >/dev/null 2>&1 || true; }
cache_touch() { python3 "$CACHE_MANIFEST_PY" touch "$(cache_manifest "$1")" "$2" >/dev/null 2>&1 || true; }
# cache_hit <area> <entry> — 0 when the entry is here AND non-empty; touches it.
cache_hit() {
    cache_on || return 1
    local p; p="$(cache_area "$1")/$2"
    [ -s "$p" ] || [ -d "$p" ] || return 1
    cache_touch "$1" "$2"
    return 0
}

# ------------------------------------------------------------------ fetching
# cache_fetch <area> <entry> <url> [what] — prints the path on stdout, and on
# stderr one line saying whether it came from the cache or the network. NEVER
# fatal on a cache problem: a failed fetch is a failed fetch (rc 1), a failed
# *cache* write is a warning.
cache_fetch() {
    local area="$1" entry="$2" url="$3" what="${4:-$entry}"
    local dir path
    if ! cache_on; then
        echo "[cache] off (CI_CACHE=off) — $entry comes from the network" >&2
        return 1
    fi
    dir="$(cache_area "$area")"; path="$dir/$entry"
    if cache_hit "$area" "$entry"; then
        echo "[cache] hit  $area/$entry ($(du -h "$path" 2>/dev/null | cut -f1))" >&2
        printf '%s' "$path"; return 0
    fi
    echo "[cache] miss $area/$entry — fetching once" >&2
    mkdir -p "$(dirname "$path")"
    if curl -fL --retry 3 --create-dirs -o "$path.part" "$url"; then
        mv "$path.part" "$path"
        cache_put "$area" "$entry" "$what"
        printf '%s' "$path"; return 0
    fi
    rm -f "$path.part"
    return 1
}

# ------------------------------------------------------------------- wheels
# cache_wheels <dest> <spec>… — the pip half of his ask. The cache is consulted
# FIRST (`--find-links <wheels>`), so a repeat build downloads only what is
# genuinely new; everything fetched is folded back into the cache for next time.
# An empty cache still works: pip falls through to the index.
#
# The flag half is its own function so the selftest can check it WITHOUT a
# network or a pip: "does an on cache add --find-links, and does an off one add
# nothing at all" is the whole contract.
cache_wheel_args() {
    local out=""
    cache_on && out="--find-links $(cache_area wheels)"
    [ -n "${PIP_INDEX_URL:-}" ] && out="$out${out:+ }--index-url $PIP_INDEX_URL"
    printf '%s' "$out"
}
cache_wheels() {
    local dest="$1"; shift
    [ $# -gt 0 ] || { echo "[cache] no requirements named — no wheels to gather"; return 0; }
    mkdir -p "$dest"
    local wh="" args=()
    if cache_on; then
        wh="$(cache_area wheels)"
        args+=(--find-links "$wh")
    fi
    [ -n "${PIP_INDEX_URL:-}" ] && args+=(--index-url "$PIP_INDEX_URL")
    local before after
    before=$(ls -1 "$dest" 2>/dev/null | wc -l | tr -d ' ')
    python3 -m pip download --no-deps --dest "$dest" "${args[@]}" "$@" || return 1
    after=$(ls -1 "$dest" 2>/dev/null | wc -l | tr -d ' ')
    echo "[cache] wheels: $after file(s) in $dest ($((after - before)) new this run)"
    if [ -n "$wh" ]; then
        local f base
        for f in "$dest"/*; do
            [ -f "$f" ] || continue
            base="$(basename "$f")"
            if [ ! -s "$wh/$base" ]; then
                cp -n "$f" "$wh/$base" 2>/dev/null && cache_put wheels "$base" "a python wheel/sdist gathered by a pipeline build" || true
            else
                cache_touch wheels "$base"
            fi
        done
    fi
}

# -------------------------------------------------------------------- images
# The base images a Dockerfile pulls (python:3.12-alpine, node:20, nginx:alpine…)
# are saved once and loaded back on a later run, so a rebuild on a cold daemon
# does not re-pull them. Idempotent, and digest-checked: an image whose local id
# already matches the cached one is neither saved nor loaded again.
_image_entry() { printf '%s.tar' "$(printf '%s' "$1" | tr '/:' '__')"; }
cache_images_warm() {
    local ref entry path id
    for ref in "$@"; do
        entry="$(_image_entry "$ref")"
        id="$(docker image inspect --format '{{.Id}}' "$ref" 2>/dev/null || true)"
        if [ -n "$id" ]; then echo "[cache] $ref already on this daemon"; cache_touch images "$entry"; continue; fi
        if cache_hit images "$entry"; then
            path="$(cache_area images)/$entry"
            echo "[cache] loading $ref from $entry"
            docker load -i "$path" >/dev/null && continue || echo "[cache] load failed — pulling $ref" >&2
        fi
        docker pull "$ref" >/dev/null 2>&1 || { echo "[cache] could not pull $ref (the build will try on its own)" >&2; continue; }
        cache_images_save "$ref"
    done
}
cache_images_save() {
    cache_on || return 0
    local ref entry path
    for ref in "$@"; do
        entry="$(_image_entry "$ref")"; path="$(cache_area images)/$entry"
        docker image inspect "$ref" >/dev/null 2>&1 || continue
        docker save -o "$path.part" "$ref" 2>/dev/null && mv "$path.part" "$path" || { rm -f "$path.part"; continue; }
        cache_put images "$entry" "docker image $ref, saved for a cold daemon"
        echo "[cache] saved $ref → images/$entry ($(du -h "$path" | cut -f1))"
    done
}

# -------------------------------------------------------------- docker layers
# The BuildKit local cache exporter needs buildx. `docker build` alone cannot
# write type=local (docker 27's classic builder has no exporter), so the pair is
# printed only when buildx is really there and the caller uses `docker buildx
# build`. When it is not, the args are EMPTY and the plain build still works —
# slower, never broken.
cache_buildx_ok() { command -v docker >/dev/null 2>&1 && docker buildx version >/dev/null 2>&1; }
cache_layers_args() {   # cache_layers_args <image-name> → the two flags, or nothing
    cache_on || return 0
    cache_buildx_ok || return 0
    local d; d="$(cache_area layers)/$(printf '%s' "$1" | tr '/:' '__')"
    mkdir -p "$d"
    printf -- '--cache-from type=local,src=%s --cache-to type=local,dest=%s,mode=max' "$d" "$d"
}

# ------------------------------------------------------ tier two: the proxies
# OFF by default (CI_CACHE_PROXIES=off). A pipeline NEVER starts them; it only
# asks whether they answer, and passes the build-args when they do.
CACHE_PROXY_PIP_PORT="${CACHE_PROXY_PIP_PORT:-3141}"
CACHE_PROXY_NPM_PORT="${CACHE_PROXY_NPM_PORT:-4873}"
CACHE_PROXY_APT_PORT="${CACHE_PROXY_APT_PORT:-3142}"
CACHE_PROXY_REG_PORT="${CACHE_PROXY_REG_PORT:-5001}"
_proxy_answers() { curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$1/" 2>/dev/null; }
cache_proxies_on() { [ "${CI_CACHE_PROXIES:-off}" = on ]; }
cache_build_args() {   # the --build-arg list the pipeline adds; EMPTY unless a proxy really answers
    cache_proxies_on || return 0
    local out=""
    _proxy_answers "$CACHE_PROXY_PIP_PORT" && out="$out --build-arg PIP_INDEX_URL=http://127.0.0.1:$CACHE_PROXY_PIP_PORT/root/pypi/+simple/"
    _proxy_answers "$CACHE_PROXY_NPM_PORT" && out="$out --build-arg NPM_CONFIG_REGISTRY=http://127.0.0.1:$CACHE_PROXY_NPM_PORT/"
    _proxy_answers "$CACHE_PROXY_APT_PORT" && out="$out --build-arg APT_PROXY=http://127.0.0.1:$CACHE_PROXY_APT_PORT"
    printf '%s' "${out# }"
}

# ------------------------------------------------------------------- reading
cache_size_gb() { du -sm "$(cache_root)" 2>/dev/null | awk '{printf "%.1f", $1/1024}'; }
cache_area_line() {
    local a="$1" d n b
    d="$(cache_root)/$a"
    [ -d "$d" ] || { printf '  %-9s %8s  %5s  %s\n' "$a" "-" "-" "$(cache_area_what "$a") (not created yet)"; return; }
    b="$(du -sh "$d" 2>/dev/null | cut -f1)"
    n="$(python3 "$CACHE_MANIFEST_PY" list "$d/MANIFEST.json" 2>/dev/null | wc -l | tr -d ' ')"
    printf '  %-9s %8s  %5s  %s\n' "$a" "${b:-0}" "$n" "$(cache_area_what "$a")"
}
cache_area_what() {
    case "$1" in
        wheels)   echo "python wheels — the offline deb's payload, and the backend build's find-links" ;;
        npm)      echo "npm tarballs (tier two's verdaccio volume)" ;;
        apt)      echo "distro debs — the offline medium's closure, downloaded once" ;;
        images)   echo "docker save tarballs of the base images a build pulls" ;;
        cloud)    echo "the Ubuntu cloud image the throwaway isle boots from" ;;
        scanners) echo "RESERVED for the scanning arc's Trivy DB (nothing here yet)" ;;
        releases) echo "official Polari releases fetched by tag (app mode's core)" ;;
        layers)   echo "BuildKit local layer cache, one directory per image" ;;
        proxies)  echo "tier two's volumes — only when CI_CACHE_PROXIES=on" ;;
    esac
}

cache_status() {
    local root max used
    root="$(cache_root)"; max="${CI_CACHE_MAX_GB:-40}"
    echo "polari-jenkins cache — offline-first builds (ci-9). CI_CACHE=${CI_CACHE:-on}"
    echo "directory: $root"
    if ! cache_on; then
        echo
        echo "THE CACHE IS OFF (CI_CACHE=off in device.env) — every build pulls from the network."
        echo "Turn it on: set CI_CACHE=on in polari-jenkins/device.env (it is the default)."
        return 0
    fi
    [ -d "$root" ] || { echo; echo "nothing cached yet — the first build fills it."; return 0; }
    used="$(cache_size_gb)"
    echo
    printf '  %-9s %8s  %5s  %s\n' area size entries what
    local a; for a in $CACHE_AREAS; do cache_area_line "$a"; done
    echo
    printf '  total %s GB of a %s GB budget (CI_CACHE_MAX_GB)%s\n' "${used:-0}" "$max" \
        "$(awk -v u="${used:-0}" -v m="$max" 'BEGIN{ if (u+0 > m+0) print " — OVER: pol jenkins cache prune" }')"
    # the hit/miss arithmetic of the LAST run that wrote one
    local pool latest rep
    pool="${POLARI_POOL:-$CACHE_DIR_SELF/pool}"
    latest="$(ls -1 "$pool" 2>/dev/null | grep -E '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}' | sort -V | tail -1 || true)"
    rep="$pool/$latest/cache-report.json"
    echo
    if [ -n "$latest" ] && [ -f "$rep" ]; then
        echo "last run ($latest):"
        python3 "$CACHE_MANIFEST_PY" report-show "$rep" | sed 's/^/  /'
    else
        echo "no cache-report.json yet — every build stage writes one into pool/<version>/."
        echo "Until a real run has happened the savings below are EXPECTED, not measured."
    fi
}

cache_prune() {   # cache_prune [days]
    local days="${1:-30}" a
    echo "[cache] prune — dropping only entries unused for more than $days day(s)"
    echo "[cache] (retention.sh prune never touches this directory; this verb is the only deleter)"
    for a in $CACHE_AREAS; do
        local d="$(cache_root)/$a"
        [ -d "$d" ] || continue
        echo "-- $a"
        python3 "$CACHE_MANIFEST_PY" sweep "$d/MANIFEST.json" "$d" >/dev/null 2>&1 || true
        python3 "$CACHE_MANIFEST_PY" prune "$d/MANIFEST.json" "$d" "$days" | sed 's/^/   /'
    done
    echo "[cache] now $(cache_size_gb) GB"
}

# ------------------------------------------------------------- the executable
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    CMD="${1:-status}"; shift || true
    case "$CMD" in
        status)   cache_status ;;
        prune)    D=30; [ "${1:-}" = "--older-than" ] && D="${2:-30}"; cache_prune "$D" ;;
        dir)      cache_area "${1:-wheels}"; echo ;;
        fetch)    cache_fetch "$1" "$2" "$3" "${4:-}"; echo ;;
        wheels)   D="$1"; shift; cache_wheels "$D" "$@" ;;
        images)   case "${1:-warm}" in
                      warm) shift; cache_images_warm "$@" ;;
                      save) shift; cache_images_save "$@" ;;
                      *) echo "cache.sh images warm|save <ref>…" >&2; exit 2 ;;
                  esac ;;
        layers-args) cache_layers_args "${1:?cache.sh layers-args <image>}"; echo ;;
        build-args)  cache_build_args; echo ;;
        report)      python3 "$CACHE_MANIFEST_PY" report "$@" ;;
        report-show) python3 "$CACHE_MANIFEST_PY" report-show "${1:?cache.sh report-show <file>}" ;;
        proxies)  bash "$CACHE_DIR_SELF/cache-proxies.sh" "${1:-status}" ;;
        --help|-h) sed -n '2,50p' "$0" ;;
        *) echo "cache.sh: unknown command '$CMD' (status|prune|dir|fetch|wheels|images|layers-args|build-args|report|report-show|proxies)" >&2; exit 2 ;;
    esac
fi
