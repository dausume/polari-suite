#!/bin/bash
# polari-jenkins/promote.sh — THE BRANCH MODEL (ci-12, his ruling 2026-09-19).
#
#   dev    where we iterate. Nothing is promised here.
#   test   what we are testing. A push to it WIPES this device's state, builds,
#          scans and runs the tests, and records ONE verdict for that sha.
#   main   what we release. A push to it generates and publishes artifacts —
#          and ONLY for a sha that already has a PASSED verdict.
#
#   promote.sh test [--dry-run]
#   promote.sh main [--dry-run] [--force-untested]
#   promote.sh status
#
# ONE SWEEP. The forest walk, the ff-only rule, the clean-tree checks, the
# artifact guard and the pointer coherence all live in
# polari-cli/shells/push-all-dev.sh, which ci-12 gave a `--branch` /
# `--promote-from` parameter rather than a copy. This file adds exactly two
# things that belong to the PIPELINE and not to the sweep:
#
#   1. THE RELEASE RULE AT THE BRANCH LEVEL. `promote main` refuses unless the
#      superproject sha on `test` carries pool/test/<sha>/verdict.json with
#      verdict `passed`. `--force-untested` overrides it with a loud line that
#      names the sha and the verdict it is overriding — there is no quiet way.
#   2. THE PROMOTION MARKER. The sweep pushes the superproject LAST, so its sha
#      set is the complete forest state. It is written to
#      pool/promotions/<branch>/<sha>.json, and the poller's quiet-period
#      re-check (quiet.sh) treats a sha with a matching marker as ALREADY quiet
#      — a finished promotion does not have to sit out five minutes proving it
#      has stopped moving.
set -euo pipefail

J="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE="$(cd "$J/.." && pwd)"
SWEEP="$SUITE/polari-cli/shells/push-all-dev.sh"
POOL="${POLARI_POOL:-$J/pool}"
# ci-12: in the system posture the pool belongs to polari-ci and this shell may
# not read it. pool.sh reads THROUGH the controller (the pipeline process reading
# its own pool — exactly who the posture says may), so `promote main` never says
# "no verdict" when it means "I may not look".
# shellcheck source=pool.sh
. "$J/pool.sh"

say()  { printf '[promote] %s\n' "$*"; }
die()  { printf '[promote] %s\n' "$*" >&2; exit "${2:-1}"; }

# The superproject sha a branch points at, read from the ORIGIN (a promotion is
# about what is published, not about what this checkout happens to hold).
remote_sha() {  # remote_sha <branch>
    git -C "$SUITE" ls-remote origin "refs/heads/$1" 2>/dev/null | awk '{print $1}' | head -1
}

_verdict_json() { pool_read "test/$1/verdict.json" 2>/dev/null; }

# Is THIS machine the pipeline device at all? The verdicts live in the device's
# pool; on a developer box there is nothing to read and never was. Saying a bare
# "none" there reads as "this sha failed to be tested", when the truth is "ask
# the device". Same distinction pool.sh draws between absent and unreadable.
_is_pipeline_device() {
    [ -d "$POOL/test" ] && return 0
    command -v docker >/dev/null 2>&1 \
        && docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "${CI_CONTROLLER_CONTAINER:-polari-jenkins}"
}
_not_here() {
    _is_pipeline_device && return 1
    printf 'no verdict on THIS machine — the verdicts live in the pipeline device'"'"'s pool. Run pol jenkins test-status there, or promote from there.'
}

verdict_of() {  # verdict_of <sha> → passed|failed|partial|none
    local body; body="$(_verdict_json "$1")" || { echo none; return; }
    [ -n "$body" ] || { echo none; return; }
    printf '%s' "$body" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("verdict") or "none")
except Exception: print("none")'
}

verdict_why() {  # verdict_why <sha> → the one-line reason
    local elsewhere; elsewhere="$(_not_here || true)"
    local body; body="$(_verdict_json "$1")" || {
        [ -n "$elsewhere" ] && { printf '%s' "$elsewhere"; return; }
        printf 'no test run has ever been recorded for this sha (%s)' "$(pool_why_unreadable)"; return; }
    if [ -z "$body" ]; then
        [ -n "$elsewhere" ] && { printf '%s' "$elsewhere"; return; }
        printf 'no test run has ever been recorded for this sha'; return
    fi
    printf '%s' "$body" | python3 -c 'import json,sys
try: d = json.load(sys.stdin)
except Exception as e: print("verdict.json unreadable (%s)" % e); raise SystemExit
print(d.get("why") or "")'
}

write_marker() {  # write_marker <branch> <summary.json>
    local branch="$1" summary="$2" sha
    sha="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("superproject") or "")' "$summary" 2>/dev/null || true)"
    [ -n "$sha" ] || { say "no superproject sha in the sweep summary — no marker written"; return 0; }
    mkdir -p "$POOL/promotions/$branch"
    cp "$summary" "$POOL/promotions/$branch/$sha.json"
    say "marker: pool/promotions/$branch/$sha.json — quiet.sh reads it as 'this promotion is COMPLETE'"
}

do_promote() {  # do_promote <target> <source> [--dry-run]
    local target="$1" source="$2"; shift 2
    local dry=0 args=()
    for a in "$@"; do case "$a" in --dry-run) dry=1 ;; esac; done
    local summary; summary="$(mktemp)"
    args=(--branch "$target" --promote-from "$source" --summary-json "$summary")
    [ "$dry" = 1 ] || args+=(--push)
    say "$source → $target, innermost-first, fast-forward only$([ "$dry" = 1 ] && echo '  (DRY RUN — nothing is pushed)')"
    if ! bash "$SWEEP" "${args[@]}"; then
        rm -f "$summary"
        die "the promotion did NOT complete — the repo named above must be reconciled first (ff-only, by design)" 1
    fi
    if [ "$dry" = 0 ]; then write_marker "$target" "$summary"; fi
    rm -f "$summary"
}

case "${1:-status}" in
  test)
    shift
    # dev → test. No gate: `test` is where we find out. The wipe, the build, the
    # scans and the tests all happen on the other side of this push.
    do_promote test dev "$@"
    ;;

  main)
    shift
    force=0; dry=0
    for a in "$@"; do case "$a" in --force-untested) force=1 ;; --dry-run) dry=1 ;; esac; done
    SHA="$(remote_sha test || true)"
    [ -n "$SHA" ] || die "there is no origin/test yet — pol jenkins promote test first" 3
    V="$(verdict_of "$SHA")"
    say "origin/test is at ${SHA:0:12}; its recorded test verdict is: $V"
    if [ "$V" != passed ]; then
        WHY="$(verdict_why "$SHA")"
        if [ "$force" = 1 ]; then
            printf '\n'
            printf '  !! FORCING AN UNTESTED PROMOTION !!\n'
            printf '  sha:     %s\n' "$SHA"
            printf '  verdict: %s\n' "$V"
            printf '  reason:  %s\n' "${WHY:-(none recorded)}"
            printf '  The RELEASE RULE says only what was tested is released. This overrides it by hand,\n'
            printf '  for this promotion only, and the override is in this log and nowhere else.\n\n'
        else
            printf '[promote] REFUSED: %s\n' "$SHA" >&2
            printf '[promote]   the test verdict for this sha is %s, not passed.\n' "$V" >&2
            printf '[promote]   %s\n' "${WHY:-no verdict.json — push to test and let polari-test run}" >&2
            printf '[promote]   Fix: push to test (pol jenkins promote test), let polari-test record a\n' >&2
            printf '[promote]   passing verdict, then promote main. pol jenkins test-status %s shows the\n' "${SHA:0:12}" >&2
            printf '[promote]   whole verdict — every reading it is made of, and which one said no.\n' >&2
            printf '[promote]   Override knowingly: pol jenkins promote main --force-untested\n' >&2
            exit 4
        fi
    fi
    do_promote main test "$@"
    ;;

  status)
    _not_here >/dev/null && say "(this machine is not the pipeline device — verdicts are read from its pool, so they read 'none here')"
    for b in test main; do
        S="$(remote_sha "$b" || true)"
        if [ -z "$S" ]; then printf '%-5s  (not published yet)\n' "$b"; continue; fi
        M="$POOL/promotions/$b/$S.json"
        V="$(verdict_of "$S")"
        [ "$V" = none ] && _not_here >/dev/null && V="none here"
        printf '%-5s  %s  verdict=%s  marker=%s\n' "$b" "${S:0:12}" "$V" \
               "$([ -f "$M" ] && echo present || echo none)"
    done
    D="$(remote_sha dev || true)"; printf '%-5s  %s\n' dev "${D:0:12}"
    ;;

  --help|-h|help) sed -n '2,30p' "$0" ;;
  *) die "usage: promote.sh test|main|status [--dry-run] [--force-untested]" 2 ;;
esac
