#!/bin/bash
# polari-jenkins/isle/footprint.sh — "is this device CLEAR?", read the ONE
# way the suite already reads it: os-security/inventory.sh (the same JSON
# `pol deploy inventory <node>` shows). Sourced by isle/preflight.sh.
#
#   target_footprint   → "" (clear) | "unreadable" | "debs:2 guests:1 checkouts:1 …"
#
# Read-only. It installs nothing, changes nothing, and on an ssh target it
# copies the inventory script to /tmp and removes it again — exactly what
# `pol deploy inventory` does today.
# strict mode belongs to the EXECUTABLE; sourcing this must not change the
# caller's shell options (jenkins.sh runs `set -eu` on purpose).
[ "${BASH_SOURCE[0]}" = "${0}" ] && set -euo pipefail

FOOTPRINT_INVENTORY="${FOOTPRINT_INVENTORY:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/os-security/inventory.sh}"

target_inventory_json() {
    if [ "$CI_ISLE_TARGET" = local ]; then
        [ -f "$FOOTPRINT_INVENTORY" ] || return 1
        bash "$FOOTPRINT_INVENTORY" 2>/dev/null
    else
        [ -f "$FOOTPRINT_INVENTORY" ] || return 1
        scp -q -o BatchMode=yes -o ConnectTimeout="$CI_SSH_TIMEOUT" \
            "$FOOTPRINT_INVENTORY" "$(device_ssh_dest):/tmp/polari-ci-inventory.sh" >/dev/null 2>&1 || return 1
        on_target 'bash /tmp/polari-ci-inventory.sh 2>/dev/null; rm -f /tmp/polari-ci-inventory.sh'
    fi
}

# Summarise the inventory into the footprint that matters for "throwaway"
# (isle/footprint.py — the reading, kept in one place and unit-testable).
footprint_summarise() { python3 "$(dirname "${BASH_SOURCE[0]}")/footprint.py"; }

target_footprint() {
    local j
    j=$(target_inventory_json 2>/dev/null) || { echo unreadable; return 0; }
    [ -n "$j" ] || { echo unreadable; return 0; }
    printf '%s' "$j" | footprint_summarise
}
