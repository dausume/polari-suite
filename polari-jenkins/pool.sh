#!/bin/bash
# polari-jenkins/pool.sh — READING THE POOL FROM THE HOST, in the system posture.
#
# After `sudo pol jenkins init-device` the pool belongs to the `polari-ci` system
# user and the controller runs as it. That is the whole point of the posture (C):
# the build output — and, since ci-12, THE VERDICTS — are readable by the
# pipeline process and by root, and by nobody else. Which means a person typing
# `pol jenkins test-status` or `pol jenkins promote main` cannot simply `cat` the
# file, and the first version of both reported "no verdict" for a sha that had
# one. A tool that says "none" when it means "I may not look" is worse than one
# that refuses.
#
# So a pool read is tried three ways, in the order that keeps the posture:
#   1. directly, when the file is readable (the repo posture, or a person in the
#      polari-ci group);
#   2. through the CONTROLLER — `docker exec` into the container that runs as
#      polari-ci. This is the pipeline process reading its own pool, which is
#      exactly who the posture says may;
#   3. `sudo -n`, for a person who already has passwordless root.
# If none works, the caller is told it could not READ the file, not that the
# file is absent.
#
# SOURCED, not executed.
[ "${BASH_SOURCE[0]}" = "${0}" ] && set -euo pipefail

POOL_SH_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POOL_HOST_DIR="${POLARI_POOL:-$POOL_SH_SELF/pool}"
POOL_CONTAINER="${CI_CONTROLLER_CONTAINER:-polari-jenkins}"
POOL_IN_CONTAINER="${CI_POOL_IN_CONTAINER:-/var/polari-pool}"

# pool_read <path-relative-to-the-pool> → the file on stdout, or exit 1
pool_read() {
    local rel="$1"
    [ -r "$POOL_HOST_DIR/$rel" ] && { cat "$POOL_HOST_DIR/$rel"; return 0; }
    if command -v docker >/dev/null 2>&1 \
       && docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$POOL_CONTAINER"; then
        docker exec "$POOL_CONTAINER" sh -c "cat '$POOL_IN_CONTAINER/$rel' 2>/dev/null" 2>/dev/null && return 0
    fi
    sudo -n cat "$POOL_HOST_DIR/$rel" 2>/dev/null && return 0
    return 1
}

# pool_exists <path> — is it there at all (as opposed to unreadable)?
pool_exists() { pool_read "$1" >/dev/null 2>&1; }

# pool_why_unreadable — the sentence to print when a read fails, so the answer is
# never a bare "none".
pool_why_unreadable() {
    if [ -d "$POOL_HOST_DIR" ] && [ ! -r "$POOL_HOST_DIR" ]; then
        printf 'the pool (%s) belongs to the pipeline user and this shell may not read it — and the controller is not running, so it cannot read it for you. Start it (pol jenkins up), or use sudo.' "$POOL_HOST_DIR"
    else
        printf 'there is no such file under %s' "$POOL_HOST_DIR"
    fi
}
