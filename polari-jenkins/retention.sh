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
# ci-12: the pool also carries the branch model's own state, and none of it is a
# "version" that ages out. `test/<sha>/` holds each test run and THE VERDICT the
# release rule reads (deleting it would silently un-test a released sha);
# `promotions/<branch>/` holds the markers the quiet-period re-check keys on;
# `queue/` is the one-deep queue itself. All exempt here; `test/` is bounded by
# its own keep count below, the other two are tiny.
KEEP_DIRS="${KEEP_DIRS:-$CACHE_NAME test promotions queue}"
TEST_KEEP="${TEST_KEEP:-5}"
free_gb(){ df -BG --output=avail "$1" | tail -1 | tr -dc '0-9'; }
case "${1:-}" in
  guard)
    F=$(free_gb "$POOL"); echo "[retention] free on $POOL: ${F} GB (floor ${MIN_GB} GB)"
    [ "$F" -ge "$MIN_GB" ] || { echo "[retention] REFUSED to build: only ${F} GB free, floor is ${MIN_GB} GB — run 'retention.sh prune' or raise DISK_MIN_FREE_GB knowingly"; exit 4; } ;;
  prune)
    cd "$POOL"
    KEEP_RE="$(printf '%s\n' $KEEP_DIRS | paste -sd'|' -)"
    mapfile -t VERS < <(ls -1dt */ 2>/dev/null | sed 's#/##' | grep -v '^test-' | grep -vE "^(${KEEP_RE})\$")
    echo "[retention] pool versions (newest first): ${VERS[*]:-none}; keeping $KEEP"
    echo "[retention] EXEMPT (never a version): $KEEP_DIRS — the offline cache (ci-9), the test runs and their"
    echo "[retention]   verdicts, the promotion markers and the queue (ci-12). 'retention.sh cache-prune' is the cache's only deleter."
    for v in "${VERS[@]:$KEEP}"; do
        echo "[retention] dropping pool/$v ($(du -sh "$v" | cut -f1))"; rm -rf "$v"
        docker images --format '{{.Repository}}:{{.Tag}}' | grep -E ":${v}$" | xargs -r docker rmi -f >/dev/null 2>&1 && echo "[retention]   images tagged :$v removed" || true
    done
    # ci-12: the test runs are bounded too, by their own count — but the newest
    # TEST_KEEP are kept whatever their age, because a verdict older than the
    # newest release is exactly the verdict `promote main` may still need.
    if [ -d "$POOL/test" ]; then
        mapfile -t TRUNS < <(ls -1dt "$POOL/test"/*/ 2>/dev/null | sed 's#/$##')
        echo "[retention] test runs: ${#TRUNS[@]}; keeping the newest $TEST_KEEP (each holds a VERDICT the release rule reads)"
        for d in "${TRUNS[@]:$TEST_KEEP}"; do echo "[retention] dropping $(basename "$d") ($(du -sh "$d" | cut -f1))"; rm -rf "$d"; done
    fi
    D=$(docker image prune -f 2>/dev/null | tail -1); echo "[retention] dangling layers: ${D:-none}"
    echo "[retention] pool now $(du -sh "$POOL" | cut -f1); free $(free_gb "$POOL") GB" ;;
  cache-prune)
    shift
    DAYS=30; [ "${1:-}" = "--older-than" ] && DAYS="${2:-30}"
    exec bash "$HERE/cache.sh" prune --older-than "$DAYS" ;;
  *) echo "usage: retention.sh guard|prune|cache-prune [--older-than DAYS]" >&2; exit 1 ;;
esac
