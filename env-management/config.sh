#!/usr/bin/env bash
# config.sh — Shared variables and helpers for env-management scripts

set -euo pipefail

# ── Paths ────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── Submodules ───────────────────────────────────────────────────────────
SUBMODULES=("polari-cli" "polari-rf-node" "pol-geocoder" "political-scorecard-node")

# ── Colors ───────────────────────────────────────────────────────────────
_RED='\033[0;31m'
_GREEN='\033[0;32m'
_YELLOW='\033[0;33m'
_BLUE='\033[0;34m'
_NC='\033[0m' # No Color

info()    { printf "${_BLUE}[INFO]${_NC}    %s\n" "$*"; }
success() { printf "${_GREEN}[OK]${_NC}      %s\n" "$*"; }
warn()    { printf "${_YELLOW}[WARN]${_NC}    %s\n" "$*"; }
error()   { printf "${_RED}[ERROR]${_NC}   %s\n" "$*" >&2; }

# ── Helpers ──────────────────────────────────────────────────────────────

# Run a callback function in each submodule, then in the suite root.
# Usage: run_in_each_repo my_function
#   The callback receives two arguments: <absolute-path> <display-name>
run_in_each_repo() {
    local callback="$1"

    for sub in "${SUBMODULES[@]}"; do
        local sub_path="$SUITE_ROOT/$sub"
        if [[ -d "$sub_path/.git" || -f "$sub_path/.git" ]]; then
            "$callback" "$sub_path" "$sub"
        else
            warn "Submodule directory not found or not a repo: $sub"
        fi
    done

    # Finally, the suite root itself
    "$callback" "$SUITE_ROOT" "polari-suite (root)"
}
