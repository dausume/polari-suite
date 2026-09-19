#!/bin/bash
# retention.sh — an automated builder must never overwhelm the host's data
# (his rule 2026-09-08). Bounded, knob-driven, and it touches ONLY what the
# pipelines made: pool/<version> dirs, images tagged <name>:<polari-version>,
# dangling layers, and the workspace. Never the developer's own images/tags
# (prf-*:staging etc.), never anything outside the pool. Runs as a post
# stage AND as a pre-flight disk guard.
#   retention.sh guard          fail fast when free disk < DISK_MIN_FREE_GB
#   retention.sh prune          keep the newest POOL_KEEP versions, drop the rest (+ their images)
#   retention.sh cache-prune [--older-than DAYS]
#                               the OFFLINE CACHE's own deleter (ci-9) — entries nothing
#                               has used for > DAYS. `prune` never touches the cache: a
#                               cache that vanished with yesterday's build is not a cache.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POOL="${POLARI_POOL:-/var/polari-pool}"; KEEP="${POOL_KEEP:-3}"; MIN_GB="${DISK_MIN_FREE_GB:-20}"
# ci-9: the cache lives under the pool by default. `prune` walks pool/*/ and
# would otherwise delete it as if it were an old version — it is EXEMPT here,
# and `cache-prune` (last_used, not age-on-disk) is the only thing that empties it.
CACHE_NAME="${CACHE_NAME:-cache}"
free_gb(){ df -BG --output=avail "$1" | tail -1 | tr -dc '0-9'; }
case "${1:-}" in
  guard)
    F=$(free_gb "$POOL"); echo "[retention] free on $POOL: ${F} GB (floor ${MIN_GB} GB)"
    [ "$F" -ge "$MIN_GB" ] || { echo "[retention] REFUSED to build: only ${F} GB free, floor is ${MIN_GB} GB — run 'retention.sh prune' or raise DISK_MIN_FREE_GB knowingly"; exit 4; } ;;
  prune)
    cd "$POOL"; mapfile -t VERS < <(ls -1dt */ 2>/dev/null | sed 's#/##' | grep -v '^test-' | grep -vx "$CACHE_NAME")
    echo "[retention] pool versions (newest first): ${VERS[*]:-none}; keeping $KEEP"
    echo "[retention] the offline cache ($POOL/$CACHE_NAME) is EXEMPT — 'retention.sh cache-prune' is its only deleter"
    for v in "${VERS[@]:$KEEP}"; do
        echo "[retention] dropping pool/$v ($(du -sh "$v" | cut -f1))"; rm -rf "$v"
        docker images --format '{{.Repository}}:{{.Tag}}' | grep -E ":${v}$" | xargs -r docker rmi -f >/dev/null 2>&1 && echo "[retention]   images tagged :$v removed" || true
    done
    D=$(docker image prune -f 2>/dev/null | tail -1); echo "[retention] dangling layers: ${D:-none}"
    echo "[retention] pool now $(du -sh "$POOL" | cut -f1); free $(free_gb "$POOL") GB" ;;
  cache-prune)
    shift
    DAYS=30; [ "${1:-}" = "--older-than" ] && DAYS="${2:-30}"
    exec bash "$HERE/cache.sh" prune --older-than "$DAYS" ;;
  *) echo "usage: retention.sh guard|prune|cache-prune [--older-than DAYS]" >&2; exit 1 ;;
esac
