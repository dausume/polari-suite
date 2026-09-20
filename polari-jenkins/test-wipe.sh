#!/bin/bash
# polari-jenkins/test-wipe.sh — "PUSHING OUR DEV WORK TO TEST WILL KICK OFF THE
# PROCESS OF WIPING WHAT WE HAVE LOCALLY AND THEN RUNNING ALL OF OUR TESTS AND
# SCANS" (his ruling 2026-09-19, verbatim).
#
#   test-wipe.sh <run-dir> <sha>
#
# WHAT A WIPE IS, AND WHAT IT IS NOT. The point of wiping before a test run is
# that a verdict must be about the CODE, not about what an earlier run left
# lying around: a stale `:staging` image, a half-finished pool directory, a
# throwaway VM that outlived its stage. So this removes exactly those, and it
# removes NOTHING ELSE — not the offline cache (ci-9: it holds the base image
# and the wheels on purpose, and re-downloading them would make every test run
# slower for no gain in honesty), not another version's pool, not a foreign
# container, not anything on the isle target that this pipeline did not make
# (ci-10's `polari-ci-` tag rule).
#
# Four steps, each independently non-fatal — a wipe that could fail a run would
# make the run's verdict about the wipe:
#   1. this sha's own previous test directory (a re-run starts clean)
#   2. retention.sh prune — the pool's ordinary bound
#   3. the `:staging` images THIS device built (they are rebuilt in the next
#      stage; leaving them would let a cached image answer for new code)
#   4. the throwaway target: `isle wipe`, then `leakcheck baseline`, so the isle
#      stages have the reading they diff against and the target is provably clear
set -uo pipefail

J="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ci-13 (his ruling 2026-09-20): test-built images are DISCARDED after the run — only a release keeps its
# images. `--images-only` is the post-run form: the pool run dir (the reports, the verdict) is kept.
IMAGES_ONLY=0; [ "${1:-}" = --images-only ] && { IMAGES_ONLY=1; shift; }
RUN_DIR="${1:?usage: test-wipe.sh [--images-only] <run-dir> <sha>}"
SHA="${2:-}"
DOCKER="${WIPE_DOCKER:-docker}"
STAGING_TAGS="${CI_STAGING_TAGS:-prf-backend:staging prf-frontend:staging pol-reticulum:staging}"

say() { printf '[test-wipe] %s\n' "$*"; }

say "wiping this device's state before testing ${SHA:0:12} — the verdict must be about the CODE"

# 1. this sha's own previous run
if [ "$IMAGES_ONLY" = 0 ] && [ -d "$RUN_DIR" ]; then
    say "removing the previous test run for this sha: $RUN_DIR"
    rm -rf "$RUN_DIR"
fi
[ "$IMAGES_ONLY" = 1 ] || mkdir -p "$RUN_DIR"

# 2. the pool's ordinary bound (never the cache — retention.sh exempts it)
bash "$J/retention.sh" prune 2>&1 | sed 's/^/  /' || say "retention prune said no; carrying on"

# 3. the staging images this device built. A test run that reused yesterday's
#    image would be testing yesterday's code and calling it today's.
if command -v "$DOCKER" >/dev/null 2>&1 && "$DOCKER" info >/dev/null 2>&1; then
    for ref in $STAGING_TAGS; do
        if "$DOCKER" image inspect "$ref" >/dev/null 2>&1; then
            say "docker image rm $ref (it is rebuilt in the build stage)"
            "$DOCKER" image rm -f "$ref" >/dev/null 2>&1 \
                || say "  $ref is in use by a container — left alone, the build will re-tag it"
        fi
    done
    D="$("$DOCKER" image prune -f 2>/dev/null | tail -1)"; say "dangling layers: ${D:-none}"
    say "the BuildKit layer cache and <pool>/cache are NOT touched — ci-9's cache is an optimisation, "
    say "  and re-downloading it every test run would cost time and buy no honesty"
else
    say "no usable docker daemon — no image was removed"
fi

# 4. the throwaway target must be CLEAR, and we must have the reading the isle
#    stages diff against. Both are ci-10's own verbs; nothing is re-implemented.
say "the throwaway target: wipe what this pipeline made (and nothing else), then take the leak baseline"
bash "$J/isle/throwaway.sh" wipe 2>&1 | sed 's/^/  /' || say "wipe said no; the preflight will catch a dirty target"
CI_LEAK_DIR="$RUN_DIR" bash "$J/isle/leakcheck.sh" baseline 2>&1 | sed 's/^/  /' \
    || say "no leak baseline could be taken (target unreachable?) — the isle stages will say so"

say "wipe complete"
exit 0
