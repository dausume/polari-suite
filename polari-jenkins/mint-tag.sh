#!/bin/bash
# polari-jenkins/mint-tag.sh — the release VERSION, minted the way
# POLARI_VERSIONING_PLAN.md §2 says: one calendar tag per release day,
#
#     polari-vYYYY.MM.DD          the day's first release
#     polari-vYYYY.MM.DD.2        the second release that same day, .3 …
#
# and NOT `YYYY.MM.DD+<sha>`, which produced the malformed tag
# `polari-v2026.09.19+sha` (SCANNING_AND_RELEASE_AUTOMATION_PLAN.md §1.3).
# The sha stays in release.json, where every component sha already lives.
#
#   mint-tag.sh [--date YYYY.MM.DD] [--remote <url>] [--help]
#     → prints the VERSION (no polari-v prefix); the tag is polari-v<version>
#
# The existing tags are read from the REMOTE (`git ls-remote --tags`), so a
# shallow CI checkout — which has no tags at all — still counts correctly.
# A remote that cannot be reached is not fatal: it prints the day's base
# version and says so on stderr, and the release job stays in dry.
set -euo pipefail

DATE=""; REMOTE="${POLARI_RELEASE_REMOTE:-https://github.com/dausume/polari-suite.git}"
while [ $# -gt 0 ]; do
    case "$1" in
        --date)   DATE="$2"; shift ;;
        --remote) REMOTE="$2"; shift ;;
        --help|-h) sed -n '2,18p' "$0"; exit 0 ;;
        *) echo "mint-tag.sh: unknown argument '$1'" >&2; exit 2 ;;
    esac; shift
done
[ -n "$DATE" ] || DATE=$(date +%Y.%m.%d)

case "$DATE" in
    [0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9]) ;;
    *) echo "mint-tag.sh: --date must be YYYY.MM.DD, got '$DATE'" >&2; exit 2 ;;
esac

if ! EXISTING=$(git ls-remote --tags "$REMOTE" "polari-v$DATE" "polari-v$DATE.*" 2>/dev/null); then
    echo "mint-tag.sh: could not reach $REMOTE — assuming no tag exists for $DATE" >&2
    echo "$DATE"; exit 0
fi

# refs/tags/polari-v2026.09.19{,.2,^{}} → the suffix number (base counts as 1)
MAX=$( { printf '%s\n' "$EXISTING" \
         | sed 's/.*refs\/tags\///; s/\^{}$//' \
         | grep -E "^polari-v$DATE(\.[0-9]+)?$" || true; } \
       | sed "s/^polari-v$DATE//; s/^\.//" \
       | awk '{ n = ($0 == "" ? 1 : $0 + 0); if (n > m) m = n } END { print m + 0 }')

if [ "${MAX:-0}" -lt 1 ]; then echo "$DATE"; else echo "$DATE.$((MAX + 1))"; fi
