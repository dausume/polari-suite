#!/bin/bash
# polari-jenkins/quiet.sh — THE QUIET PERIOD, THE ONE-DEEP QUEUE, AND WHOSE TURN
# IT IS (ci-12, his rulings 2026-09-19).
#
# His words: "this is a super project spread across many repos, so we will
# likely be detecting many changes, but we should only be running if we detect a
# change and then do not detect any more changes elsewhere within 5 minutes. We
# should not be endlessly queuing jobs. main and test queues are different
# queues. We should not run both at the same time but alternate them if they are
# getting things in series." And: "if multiple changes come in we just keep
# putting off testing and do the LAST one that came in for that queue."
#
# So three rules, and this file is all three of them:
#
#   0. A DEFERRAL MUST BE RETRYABLE. Jenkins' SCM trigger fires on a CHANGE; a
#      run that defers because the change is still landing would then never be
#      retried, because by the time the forest IS quiet nothing has changed
#      again. So the jobs are driven by a periodic trigger and `gate` is what
#      makes that cheap: ONE `git ls-remote` of the superproject, before any
#      checkout, answering "is there anything here that is not already tested?".
#      Idle ticks cost a second; only a tick with work to do pays for a clone.
#      (Measured on the pipeline device: a shallow forest checkout is ~6 minutes
#      over Wi-Fi. Deferring AFTER that would be an expensive way to do nothing.)
#
#   1. QUIET. A run starts only when the WHOLE FOREST — the superproject and
#      every top-level submodule remote — has not moved for CI_QUIET_MINUTES
#      (default 5). `check` compares a live `git ls-remote` sha set against the
#      one the queue file recorded; any difference restarts the clock and the
#      run DEFERS (exit 6) instead of building half a promotion.
#      A finished `pol jenkins promote` writes pool/promotions/<branch>/<sha>.json
#      naming the complete sha set; `check` treats a marker that MATCHES the live
#      set as quiet IMMEDIATELY. The two interact as: the marker is a promise
#      that no more commits are coming, so the timer is unnecessary; without one
#      (a hand push, a push from another machine) the timer is the only evidence
#      there is, and it is used.
#
#   2. ONE DEEP, LATEST WINS. pool/queue/<branch>.json is the queue, and it holds
#      AT MOST ONE pending item. A newer change while one is pending REPLACES it
#      (and restarts the clock); a newer change during a run does not queue a
#      second — it sets the same single pending item. There is therefore no
#      backlog that can form, ever, and the item never means a specific sha: it
#      means "the newest state of this branch", which is why the pipeline checks
#      out the branch TIP and not the sha that triggered it.
#
#   3. TURNS. `test` and `main` are separate jobs, so separate Jenkins queues;
#      the shared `polari-build` lock already stops them running at once. `turn`
#      adds the alternation on top: a job whose name is the LAST one that ran
#      yields while the other side has something pending, so a fast-re-queueing
#      test branch cannot starve main.
#
#   4. A FAILURE IS AN ANSWER (his ruling 2026-09-21, after polari-release failed
#      at the same stage every ten minutes for a day, rebuilding everything each
#      time). The tick stays cheap and frequent — it is how a change is NOTICED —
#      but a run needs a CONFIRMED change, and:
#        · a run that FAILED covers the state it failed on, and the pipeline then
#          WAITS ("if we fail a pipeline we wait until the next manual run or a
#          re-push"): a RE-PUSH (the branch moves, or the same sha is promoted
#          again — its promotion marker is newer than the failure) or a MANUAL RUN
#          (`pol jenkins retry <branch>`, or Build Now in Jenkins). Nothing else
#          re-arms it — not a tick, not a controller restart.
#      An ABORTED run is neither: it proves nothing and leaves the work outstanding.
#
#   quiet.sh gate <branch>             the CHEAP pre-check: one ls-remote of the
#                                      superproject, no checkout. exit 0 = worth
#                                      checking out · 6 = nothing to do
#   quiet.sh check <branch>            the FULL forest check, after a checkout.
#                                      exit 0 quiet · 6 defer (and say why)
#   quiet.sh saw <branch>              record the live sha set as pending (a poll)
#   quiet.sh claim <branch> <sha>      a run started: pending=false, running=<sha>
#   quiet.sh done <branch> <sha> [result]
#                                      a run ended (for ANY reason). result =
#                                      Jenkins' word (success|unstable|failure|
#                                      aborted|not_built): a CLAIMED run that ended
#                                      failure covers the state it failed on
#   quiet.sh rearm <branch>|all [why]  a MANUAL run: the failed state is work again.
#                                      Only a person's call reaches this (pol jenkins
#                                      retry, Build Now) — nothing automatic does
#   quiet.sh covered <branch> <sha>    …and it reached a VERDICT, so a tick will
#                                      not rebuild that state. Only the verdict
#                                      stage calls this: an aborted run must
#                                      leave the work outstanding.
#   quiet.sh release-rule main <sha>   THE RELEASE RULE, AT THE GATE. exit 0 =
#                                      this sha has a `passed` test verdict and
#                                      may be released · 6 = it does not: the
#                                      refusal is RECORDED (pool/release/<sha>/
#                                      refused.json), the sha counts as covered,
#                                      and the build ends NOT_BUILT.
#   quiet.sh refused <branch> <sha> <verdict> [reason]
#                                      record that refusal directly (what
#                                      release-rule calls; a stage that refuses
#                                      later can call it too).
#   quiet.sh queue [<branch>]          print both queues (or one)
#   quiet.sh queue --json [<branch>]
#   quiet.sh turn <job> [--once]       wait for this job's turn (test|release);
#                                      --once exits 7 instead of sleeping — the
#                                      caller ends the build and the next poll
#                                      takes the (still pending) item
#   quiet.sh turn-done <job>           record that this job has had its turn
#   quiet.sh shas <branch>             the live forest sha set, one 'repo sha' per line
set -euo pipefail

J="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE="${POLARI_SUITE:-$(cd "$J/.." && pwd)}"
POOL="${POLARI_POOL:-$J/pool}"

# --- the knobs. ENVIRONMENT knobs, deliberately not device.env keys: they are
# about THIS controller's scheduling, not about the device's identity, and the
# ci-10 leak tolerances set that precedent.
QUIET_MINUTES="${CI_QUIET_MINUTES:-5}"
MAX_DEFER_MINUTES="${CI_MAX_DEFER_MINUTES:-0}"   # 0 = unlimited (his default: keep putting it off)
# A periodic tick cannot land exactly on the boundary. With a 5-minute tick and a
# 5-minute window the tick that SHOULD pass arrives a few seconds early — the
# pipeline device measured "only 296s of quiet, 4s to go" and "299s, 1s to go" —
# and the run is then put off for another whole tick. 30 seconds of grace turns a
# four-second miss into a run. It is a rounding allowance on the poll, not a
# weakening of the window: nothing proceeds that has not been still for ~5 min.
QUIET_GRACE_S="${CI_QUIET_GRACE_S:-30}"
TURN_MAX_WAIT_S="${CI_TURN_MAX_WAIT_S:-3600}"
TURN_POLL_S="${CI_TURN_POLL_S:-20}"

say()  { printf '[quiet] %s\n' "$*"; }
now()  { date +%s; }

QUEUE_DIR="$POOL/queue"
TURN_FILE="$POOL/turn.json"

# job → branch, and back. The only place the mapping exists.
branch_of_job() { case "$1" in test) echo test ;; release|main) echo main ;; *) echo "" ;; esac; }
job_of_branch()  { case "$1" in test) echo test ;; main) echo release ;; *) echo "" ;; esac; }
other_branch()   { case "$1" in test) echo main ;; main) echo test ;; esac; }

# --------------------------------------------------------------- the sha set
# Every remote that can carry this branch: the superproject, then each
# submodule URL found in the .gitmodules of the superproject and of the two
# nesting submodules. Non-https URLs are SKIPPED and said so — Isle-Mesh nests
# an ssh-URL submodule that no poller can reach, and a poller that failed on it
# would never run at all.
_module_urls() {
    local base name url
    for base in "$SUITE" "$SUITE/polari-rf-node" "$SUITE/political-scorecard-node"; do
        [ -f "$base/.gitmodules" ] || continue
        while read -r name url; do
            case "$url" in
                https://*) printf '%s\t%s\n' "${name#submodule.}" "$url" ;;
                *) printf '%s\t-\n' "${name#submodule.}" ;;
            esac
        done < <(git config -f "$base/.gitmodules" --get-regexp '^submodule\..*\.url$' 2>/dev/null \
                 | sed 's/\.url / /' || true)
    done
}

# The superproject's own remote. A `gate` runs BEFORE any checkout exists, so it
# cannot ask a working copy — CI_SUITE_REMOTE is the knob, defaulting to the same
# URL both Jenkinsfiles already hard-code for their checkout.
super_remote() {
    local u
    u="$(git -C "$SUITE" remote get-url origin 2>/dev/null || true)"
    printf '%s' "${u:-${CI_SUITE_REMOTE:-https://github.com/dausume/polari-suite.git}}"
}

super_sha() {  # super_sha <branch> → the superproject tip, or 'none'
    local sha
    sha="$(GIT_TERMINAL_PROMPT=0 timeout "${CI_LSREMOTE_TIMEOUT_S:-20}" git ls-remote "$(super_remote)" "refs/heads/$1" 2>/dev/null | awk '{print $1}' | head -1)"
    printf '%s' "${sha:-none}"
}

forest_shas() {  # forest_shas <branch> → 'repo<TAB>sha' lines, superproject FIRST
    local branch="$1" origin name url sha
    origin="$(super_remote)"
    sha="$(GIT_TERMINAL_PROMPT=0 timeout "${CI_LSREMOTE_TIMEOUT_S:-20}" git ls-remote "$origin" "refs/heads/$branch" 2>/dev/null | awk '{print $1}' | head -1)"
    printf 'superproject\t%s\n' "${sha:-none}"
    while IFS=$'\t' read -r name url; do
        [ -n "$name" ] || continue
        if [ "$url" = '-' ]; then continue; fi          # not pollable (ssh URL) — skipped on purpose
        # a remote that hangs must not hang the pipeline: one tick's reading is
        # worth a few seconds, never minutes. An unreadable remote reads as
        # `none`, which differs from a sha and so DEFERS — the safe direction.
        sha="$(GIT_TERMINAL_PROMPT=0 timeout "${CI_LSREMOTE_TIMEOUT_S:-20}" git ls-remote "$url" "refs/heads/$branch" 2>/dev/null | awk '{print $1}' | head -1)"
        printf '%s\t%s\n' "$name" "${sha:-none}"
    done < <(_module_urls | sort -u)
}

# ONE read per invocation. forest_shas is ~10 `git ls-remote` round trips over
# whatever link the device has; calling it once for the digest, again for the
# superproject sha and a third time for the marker comparison tripled the cost of
# every tick for nothing. The reading is cached in a temp file for the life of
# the process.
_FOREST_CACHE=""
_forest() {  # _forest <branch> → the cached reading
    if [ -z "$_FOREST_CACHE" ]; then
        _FOREST_CACHE="$(mktemp)"
        trap 'rm -f "$_FOREST_CACHE"' EXIT
        forest_shas "$1" > "$_FOREST_CACHE"
    fi
    cat "$_FOREST_CACHE"
}
_digest() { _forest "$1" | sort | sha256sum | cut -c1-16; }
_super()  { _forest "$1" | awk -F'\t' '$1=="superproject"{print $2}'; }

# ------------------------------------------------------------- the queue file
_queue_path() { printf '%s/%s.json' "$QUEUE_DIR" "$1"; }

_queue_read() {  # _queue_read <branch> <field> [default]
    local f; f="$(_queue_path "$1")"
    [ -f "$f" ] || { printf '%s' "${3:-}"; return; }
    python3 -c 'import json,sys
try: d = json.load(open(sys.argv[1]))
except Exception: d = {}
v = d.get(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else "")
print("" if v is None else (str(v).lower() if isinstance(v, bool) else str(v)))' "$f" "$2" "${3:-}"
}

_queue_write() {  # _queue_write <branch> key=value …
    local branch="$1"; shift
    mkdir -p "$QUEUE_DIR"
    python3 - "$(_queue_path "$branch")" "$@" <<'PY'
import json, os, sys
path = sys.argv[1]
try:
    d = json.load(open(path))
except Exception:
    d = {}
for kv in sys.argv[2:]:
    k, _, v = kv.partition('=')
    if v in ('true', 'false'):
        d[k] = (v == 'true')
    elif v == '':
        d[k] = ''
    else:
        d[k] = v
tmp = path + '.tmp'
json.dump(d, open(tmp, 'w'), indent=1)
os.replace(tmp, path)
PY
}

# `saw` — one poll's reading. LATEST WINS: a change replaces whatever was
# pending and restarts the clock. Nothing is ever appended, so no backlog exists.
do_saw() {  # do_saw <branch>
    local branch="$1" dg sup prev
    dg="$(_digest "$branch")"; sup="$(_super "$branch")"
    prev="$(_queue_read "$branch" digest)"
    mkdir -p "$QUEUE_DIR"
    if [ "$dg" != "$prev" ]; then
        _queue_write "$branch" digest="$dg" newest_sha="$sup" pending=true "since=$(now)" \
                     "since_iso=$(date -Is)"
        say "$branch: the forest moved → pending (newest ${sup:0:12}); the ${QUIET_MINUTES}-minute quiet window restarts"
    else
        [ "$(_queue_read "$branch" pending false)" = true ] \
            && say "$branch: unchanged — still ONE pending item at ${sup:0:12} (latest wins; nothing is queued behind it)" \
            || say "$branch: unchanged and nothing pending"
    fi
}

# `gate`  — the CHEAP pre-check, before any checkout (superproject only).
# `check` — the FULL forest check, after one.
#
# Both share the same three questions, in this order:
#   1. is this exact state already tested?          → nothing to do (exit 6)
#   2. has it moved since the reading we recorded?  → restart the window (exit 6)
#   3. has the window elapsed (or is there a matching promotion marker)?
#                                                   → proceed (exit 0)
do_check() {  # do_check <branch> [--super-only]
    local branch="$1" scope="${2:-}" dg sup prev since age marker key lastkey
    if [ "$scope" = --super-only ]; then
        sup="$(super_sha "$branch")"; dg="$sup"
        key=super_digest; lastkey=last_run_super
    else
        dg="$(_digest "$branch")"; sup="$(_super "$branch")"
        key=digest; lastkey=last_run_digest
    fi
    [ -n "$sup" ] && [ "$sup" != none ] || { say "$branch has no published tip — nothing to run"; exit 6; }

    # 1a. ALREADY COVERED BY A REFUSAL. A release-rule refusal is a RECORDED
    # OUTCOME — "this sha has no passed verdict" is an answer, not a build error
    # — so the sha is covered by it, exactly as it would be by a verdict. It
    # stays covered until main MOVES or that sha's test VERDICT CHANGES, and the
    # second half is what makes it re-armable: promote the sha to test, let
    # polari-test record `passed`, and the next tick releases it without anybody
    # touching main. (Live: polari-release #84/#85/#86 all ran on 0ee38c6, ten
    # minutes apart, each one re-deriving the same refusal and going red for it.)
    if _refusal_still_stands "$branch" "$sup"; then exit 6; fi

    # 1b. ALREADY TESTED. A periodic trigger fires whether or not anything
    # changed, so the first thing to answer is "is there anything here that is
    # not already done?". Without this the retry loop would rebuild the same sha
    # every tick, forever.
    if [ "$dg" = "$(_queue_read "$branch" "$lastkey")" ]; then
        say "$branch: ${sup:0:12} is exactly what the last run already covered — nothing to do"
        exit 6
    fi

    # 1c. IT FAILED HERE (rule 4). A failure is an answer about THIS state; the
    # pipeline waits for a RE-PUSH or a MANUAL RUN. A moved branch is a different
    # digest and falls through by itself; the same sha PROMOTED AGAIN is a re-push
    # too, and the evidence is its promotion marker being newer than the failure.
    local fkey=failed_digest; [ "$scope" = --super-only ] && fkey=failed_super
    if [ -n "$(_queue_read "$branch" "$fkey")" ] && [ "$dg" = "$(_queue_read "$branch" "$fkey")" ]; then
        local fmark="$POOL/promotions/$branch/$sup.json" fat; fat="$(_queue_read "$branch" failed_at 0)"
        if [ -f "$fmark" ] && [ "$(stat -c %Y "$fmark" 2>/dev/null || echo 0)" -gt "${fat:-0}" ]; then
            say "$branch: ${sup:0:12} was PROMOTED AGAIN after it failed — a re-push, so it is work again"
            _queue_write "$branch" failed_sha='' failed_digest='' failed_super='' failed_at='' failed_iso='' failed_build=''
        else
            say "$branch: ${sup:0:12} FAILED at $(_queue_read "$branch" failed_iso '?') — not re-running it. The pipeline waits for"
            say "  a re-push ($branch moves, or pol jenkins promote $branch again) or a manual run (pol jenkins retry $branch · Build Now in Jenkins)."
            exit 6
        fi
    fi

    # THE WINDOW BELONGS TO THE SUPERPROJECT TIP, not to a scope. The gate reads
    # the superproject alone and the check reads the whole forest, so they record
    # different digests — and a digest left over from an EARLIER tip made the
    # check announce "the forest moved" seconds after the gate had already timed
    # the current one. (Seen live: gate "quiet for 417s — proceeding", then the
    # check restarting the clock at 0s.) When the tip changes, BOTH readings are
    # cleared with it; within one tip, a scope's digest changing means a
    # SUBMODULE moved under a fixed pointer, which is exactly the still-landing
    # case worth deferring on.
    local window_sha; window_sha="$(_queue_read "$branch" window_sha)"
    if [ "$window_sha" != "$sup" ]; then
        _queue_write "$branch" window_sha="$sup" digest='' super_digest='' \
                     newest_sha="$sup" pending=true "since=$(now)" "since_iso=$(date -Is)"
        say "$branch: a new tip (${sup:0:12}) — the ${QUIET_MINUTES}-minute quiet window starts now"
    fi
    prev="$(_queue_read "$branch" "$key")"
    since="$(_queue_read "$branch" since 0)"
    if [ -n "$prev" ] && [ "$dg" != "$prev" ]; then
        # it MOVED since the reading we recorded — the window restarts.
        _queue_write "$branch" "$key=$dg" newest_sha="$sup" pending=true "since=$(now)" "since_iso=$(date -Is)"
        since="$(now)"
        say "$branch: the forest moved → the ${QUIET_MINUTES}-minute quiet window restarts at ${sup:0:12}"
    elif [ -z "$prev" ]; then
        # FIRST reading at this scope. The gate reads the superproject alone and
        # the check reads the whole forest, so the check's first pass has no
        # previous digest of its own — but the window the GATE started is the
        # same window, and resetting it here would mean the full check could
        # never pass on a branch that has stopped moving. Record the digest,
        # keep the clock.
        if [ -z "$since" ] || [ "$since" = 0 ]; then
            _queue_write "$branch" "$key=$dg" newest_sha="$sup" pending=true "since=$(now)" "since_iso=$(date -Is)"
            since="$(now)"
            say "$branch: first reading at ${sup:0:12} — the ${QUIET_MINUTES}-minute quiet window starts now"
        else
            _queue_write "$branch" "$key=$dg" newest_sha="$sup" pending=true
            say "$branch: first whole-forest reading at ${sup:0:12} — keeping the window the gate already started"
        fi
    fi
    age=$(( $(now) - since ))

    # THE PROMOTION MARKER. A completed `pol jenkins promote` recorded the whole
    # sha set; if the live set still matches it, the promotion is finished and
    # waiting out the timer would only delay a run for nothing.
    marker="$POOL/promotions/$branch/$sup.json"
    if [ -f "$marker" ] && { [ "$scope" = --super-only ] || _marker_matches "$branch" "$marker"; }; then
        say "$branch: promotion marker for ${sup:0:12} matches the live forest — QUIET immediately (a finished promotion does not have to prove it stopped)"
        printf 'QUIET_SHA=%s\n' "$sup"
        return 0
    fi

    if [ $(( age + QUIET_GRACE_S )) -ge $(( QUIET_MINUTES * 60 )) ]; then
        say "$branch: quiet for ${age}s (floor $(( QUIET_MINUTES * 60 ))s, ${QUIET_GRACE_S}s poll grace) at ${sup:0:12} — proceeding"
        printf 'QUIET_SHA=%s\n' "$sup"
        return 0
    fi

    if [ "${MAX_DEFER_MINUTES:-0}" -gt 0 ] && [ "$age" -ge $(( MAX_DEFER_MINUTES * 60 )) ]; then
        say "$branch: CI_MAX_DEFER_MINUTES=$MAX_DEFER_MINUTES reached — proceeding on the last state anyway (an OVERRIDE, not the default)"
        printf 'QUIET_SHA=%s\n' "$sup"
        return 0
    fi

    say "$branch: changes still landing — only ${age}s of quiet, $(( QUIET_MINUTES * 60 - QUIET_GRACE_S - age ))s to go. DEFERRING;"
    say "  the single pending item stays pending at ${sup:0:12} and the next tick picks it up. Nothing is queued behind it."
    exit 6
}

_marker_matches() {  # _marker_matches <branch> <marker.json>
    local branch="$1" marker="$2" tmp rc=0
    tmp="$(mktemp)"; _forest "$branch" > "$tmp"
    python3 - "$marker" "$tmp" <<'PY' || rc=$?
import json, sys
marker, live = sys.argv[1:3]
try:
    m = json.load(open(marker))
except Exception:
    raise SystemExit(1)
want = {str(v) for v in (m.get('repos') or {}).values()}
have = {line.split('\t')[1].strip() for line in open(live) if '\t' in line}
have.discard('none')
# every sha the promotion published must still be a sha the forest is showing.
raise SystemExit(0 if want and want <= have else 1)
PY
    rm -f "$tmp"
    return $rc
}

# A run CLAIMS the state it is about to test, and on DONE that state becomes
# "already covered" — which is what stops a periodic trigger rebuilding the same
# sha every tick. Both digests travel, because `gate` compares superproject-only
# readings and `check` compares whole-forest ones, and the two must not be
# compared against each other.
do_claim() {
    _queue_write "$1" pending=false running="$2" "running_since=$(now)" \
                 "claim_digest=$(_queue_read "$1" digest)" "claim_super=$(_queue_read "$1" super_digest)"
    say "$1: run started on ${2:0:12} — pending cleared (a change from here on sets ONE new pending item)"
}
# `done` only ends the run. It does NOT mark the state covered, because a run
# can end for reasons that prove nothing: aborted, killed by a restart, failed in
# the build. polari-test #11 on the pipeline device was aborted mid-build and its
# `done` marked the sha covered — after which every tick said "nothing to do" and
# the sha was never tested at all. Only `covered` claims that, and only the
# VERDICT stage calls it.
#
# rule 4 rides on the same call, because `done` is the one place every ending
# passes through. Only a CLAIMED run counts (the release job calls `done` on its
# deferred ticks too, with nothing running), and only a FAILURE says something:
# it covers the state it failed on. aborted/not_built change nothing; a success
# is covered by its verdict/release record as before.
do_done() {  # do_done <branch> <sha> [result]
    local branch="$1" sha="$2" result running
    result="$(printf '%s' "${3:-}" | tr 'A-Z' 'a-z')"
    running="$(_queue_read "$branch" running)"
    if [ -z "$running" ]; then
        _queue_write "$branch" "last_tick_at=$(now)"
        return 0
    fi
    _queue_write "$branch" running='' last_run_sha="$sha" "last_run_at=$(now)" "last_run_iso=$(date -Is)" \
                 last_result="${result:-unknown}"
    say "$branch: run finished on ${sha:0:12}${result:+ ($result)}"
    if [ "$result" = failure ]; then
        _queue_write "$branch" failed_sha="$sha" "failed_digest=$(_queue_read "$branch" claim_digest)" \
                     "failed_super=$(_queue_read "$branch" claim_super)" "failed_at=$(now)" "failed_iso=$(date -Is)" \
                     failed_build="${BUILD_TAG:-}" pending=false
        say "$branch: ${sha:0:12} FAILED — the pipeline now WAITS for a re-push or a manual run; no tick re-runs it"
        say "  (the branch moves · pol jenkins promote $branch again · pol jenkins retry $branch · Build Now in Jenkins)"
    else
        _queue_write "$branch" failed_sha='' failed_digest='' failed_super='' failed_at='' failed_iso='' failed_build=''
    fi
}

# `rearm` — a MANUAL RUN: the failed state is work again. Only a person's call
# reaches it — `pol jenkins retry <branch>`, or a build started by hand in Jenkins
# (the pipelines read their own build cause).
do_rearm() {  # do_rearm <branch>|all [why]
    local which="$1" why b; shift
    why="${*:-asked}"
    for b in test main; do
        [ "$which" = all ] || [ "$which" = "$b" ] || continue
        if [ -n "$(_queue_read "$b" failed_sha)" ]; then
            say "$b: the failure on $(_queue_read "$b" failed_sha | cut -c1-12) no longer covers it ($why) — it is work again"
            _queue_write "$b" failed_sha='' failed_digest='' failed_super='' failed_at='' failed_iso='' failed_build='' \
                         pending=true "since=$(now)" "since_iso=$(date -Is)"
        else
            say "$b: no failure on file — nothing to re-arm"
        fi
    done
}

# --------------------------------------------- the release rule, at the gate
# TWO RULES §76 STATED AND THE RELEASE SIDE DID NOT KEEP (found live, 2026-09-20):
#
#   · latest-wins says a sha that is already COVERED is not re-run. The test job
#     has had that since ci-12 (the NOT_BUILT "exactly what the last run already
#     covered" path). The release job only ever marked a sha covered from its
#     LAST stage, so any run that ended earlier left the sha outstanding and the
#     next tick did the whole thing again. polari-release #84/#85/#86 each ran
#     on 0ee38c6, ten minutes apart.
#   · a release-rule refusal is a RECORDED OUTCOME, not a build error. "There is
#     no passed verdict for this sha" is the rule working. It was ending the
#     build FAILURE, which is the same confusion §76 set out to remove: the
#     colour is supposed to say whether it RAN.
#
# So the rule moved to the GATE — which already knows the tip sha, from the one
# ls-remote it does before any checkout — and its refusal is written down:
#
#     pool/release/<sha>/refused.json   { sha, verdict, reason, at }
#
# …after which the sha is covered, and stays covered until main moves or that
# sha's verdict CHANGES. A sha promoted to test and passed there re-arms itself.
VERDICT_ROOT="${POLARI_TEST_POOL:-$POOL/test}"
RELEASE_ROOT="$POOL/release"

_verdict_of() {  # _verdict_of <sha> → the recorded verdict, or 'none'
    local f="$VERDICT_ROOT/$1/verdict.json"
    [ -f "$f" ] || { printf 'none'; return 0; }
    python3 -c 'import json,sys
try: print(json.load(open(sys.argv[1])).get("verdict") or "none")
except Exception: print("unreadable")' "$f" 2>/dev/null || printf 'unreadable'
}

_refusal_reason() {  # _refusal_reason <verdict> → the short phrase the queue shows
    case "$1" in
        none)       printf 'no passed verdict' ;;
        unreadable) printf 'the verdict for this sha is unreadable' ;;
        *)          printf 'the verdict is %s, not passed' "$1" ;;
    esac
}

# Does the recorded refusal still cover this tip? Yes → the caller ends the build
# NOT_BUILT. No (main moved, or the verdict changed under it) → it is work again,
# and the refusal is cleared here so the next answer is computed fresh.
_refusal_still_stands() {  # _refusal_still_stands <branch> <sup>
    local branch="$1" sup="$2" covsha covv now
    covsha="$(_queue_read "$branch" covered_sha)"
    covv="$(_queue_read "$branch" covered_verdict)"
    [ -n "$covv" ] || return 1                      # no refusal on file
    [ "$covsha" = "$sup" ] || return 1              # main moved — a different question
    now="$(_verdict_of "$sup")"
    if [ "$now" = "$covv" ]; then
        say "$branch: covered ${sup:0:12} (refused: $(_refusal_reason "$covv")) — nothing to do."
        say "  It runs again when main moves, or when that sha's test verdict changes (promote it to test and let polari-test record 'passed')."
        return 0
    fi
    _queue_write "$branch" covered_verdict='' covered_reason='' pending=true \
                 "since=$(now)" "since_iso=$(date -Is)"
    say "$branch: the test verdict for ${sup:0:12} changed ($covv → $now) — the refusal no longer stands and this sha is work again"
    return 1
}

# `refused` — the rule said no, and that is an ANSWER. Record it where a person
# can read it, and cover the sha with it.
do_refused() {  # do_refused <branch> <sha> <verdict> [reason]
    local branch="$1" sha="$2" verdict="${3:-none}" reason="${4:-}"
    [ -n "$reason" ] || reason="$(_refusal_reason "$verdict")"
    mkdir -p "$RELEASE_ROOT/$sha"
    python3 - "$RELEASE_ROOT/$sha/refused.json" "$sha" "$verdict" "$reason" "$branch" <<'PY'
import json, os, sys
path, sha, verdict, reason, branch = sys.argv[1:6]
import datetime
d = {'sha': sha, 'branch': branch, 'verdict': verdict, 'reason': reason,
     'at': datetime.datetime.now().astimezone().isoformat(timespec='seconds'),
     'rule': 'only a sha whose test verdict is `passed` may be released',
     'rearms_when': 'main moves, or the test verdict for this sha changes to passed'}
tmp = path + '.tmp'
json.dump(d, open(tmp, 'w'), indent=1)
os.replace(tmp, path)
PY
    _queue_write "$branch" covered_sha="$sha" covered_verdict="$verdict" \
                 covered_reason="$reason" newest_sha="$sha" pending=false running=''
    say "$branch: RECORDED the refusal for ${sha:0:12} — $reason ($RELEASE_ROOT/$sha/refused.json)"
    say "  the sha is now COVERED: no tick re-runs it until main moves or its verdict changes. This is NOT a build failure."
}

# `release-rule` — ask it, at the gate, before anything is checked out.
do_release_rule() {  # do_release_rule <branch> <sha>
    local branch="$1" sha="$2" v
    [ -n "$sha" ] || { say "release-rule: no sha given — nothing to check"; return 0; }
    v="$(_verdict_of "$sha")"
    if [ "$v" = passed ]; then
        say "$branch: ${sha:0:12} has a PASSED test verdict — the release rule is satisfied"
        return 0
    fi
    say "$branch: REFUSED by the release rule — $(_refusal_reason "$v") for ${sha:0:12}"
    say "  Fix: pol jenkins promote test, let polari-test record a passing verdict for this sha, and this tick releases it."
    do_refused "$branch" "$sha" "$v"
    exit 6
}

# `covered` — this state has a VERDICT. Called by the verdict stage and by
# nothing else, so an aborted or failed run leaves the work outstanding and the
# next tick picks it up.
do_covered() {
    local cd cs; cd="$(_queue_read "$1" claim_digest)"; cs="$(_queue_read "$1" claim_super)"
    if [ -z "$cd$cs" ]; then
        say "$1: ${2:0:12} reached a verdict without a claim — not marking it covered (there is nothing to compare)"
        return 0
    fi
    # covered_verdict/_reason are the REFUSAL's fields. A run that got all the way
    # to a verdict has superseded any refusal on file, so they are cleared here —
    # otherwise the refusal would keep answering for a sha that has since been
    # released.
    _queue_write "$1" "last_run_digest=$cd" "last_run_super=$cs" "covered_sha=$2" \
                 covered_verdict='' covered_reason=''
    say "$1: ${2:0:12} now has a verdict — that state is 'already covered' and a periodic tick will not rebuild it"
}

do_queue() {
    local want="${1:-}"
    for b in test main; do
        [ -z "$want" ] || [ "$want" = "$b" ] || continue
        local pend sup since run last covsha covv covr
        pend="$(_queue_read "$b" pending false)"; sup="$(_queue_read "$b" newest_sha)"
        since="$(_queue_read "$b" since_iso)"; run="$(_queue_read "$b" running)"
        last="$(_queue_read "$b" last_run_iso)"
        covsha="$(_queue_read "$b" covered_sha)"; covv="$(_queue_read "$b" covered_verdict)"
        covr="$(_queue_read "$b" covered_reason)"
        printf '%-5s  %s\n' "$b" "$(
            if [ -n "$run" ]; then printf 'RUNNING %s' "${run:0:12}"
            # a REFUSED sha is covered, not idle and not pending: the queue has an
            # answer for it and is waiting for main to move or its verdict to change.
            elif [ -n "$covv" ] && [ "$covsha" = "$sup" ]; then
                printf 'covered %s (refused: %s)' "${covsha:0:12}" "${covr:-$(_refusal_reason "$covv")}"
            elif [ -n "$(_queue_read "$b" failed_sha)" ] && [ "$(_queue_read "$b" failed_sha)" = "$sup" ]; then
                printf 'FAILED %s at %s — waiting for a re-push or a manual run (pol jenkins retry %s)' \
                       "${sup:0:12}" "$(_queue_read "$b" failed_iso '?')" "$b"
            elif [ "$pend" = true ]; then printf 'pending %s since %s' "${sup:0:12}" "${since:-?}"
            else printf 'idle'; fi)"
        printf '       newest %s   last run %s\n' "${sup:0:12}" "${last:-never}"
    done
    printf '       one item deep, latest wins: a newer change REPLACES the pending item; nothing queues behind it\n'
    printf '       a FAILED run is not re-run by a tick: it waits for a re-push or a manual run (pol jenkins retry)\n'
    printf '       quiet window %s min (CI_QUIET_MINUTES), max defer %s\n' "$QUIET_MINUTES" \
           "$([ "${MAX_DEFER_MINUTES:-0}" -gt 0 ] && echo "${MAX_DEFER_MINUTES} min" || echo 'unlimited (his default)')"
    local t; t="$([ -f "$TURN_FILE" ] && python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("last",""))' "$TURN_FILE" 2>/dev/null || true)"
    printf '       last turn: %s\n' "${t:-none}"
}

do_queue_json() {
    python3 - "$QUEUE_DIR" "$TURN_FILE" "$QUIET_MINUTES" "$MAX_DEFER_MINUTES" <<'PY'
import json, os, sys
qdir, turn, quiet, maxdefer = sys.argv[1:5]
out = {'quiet_minutes': int(quiet), 'max_defer_minutes': int(maxdefer), 'queues': {}}
for b in ('test', 'main'):
    p = os.path.join(qdir, '%s.json' % b)
    try:
        out['queues'][b] = json.load(open(p))
    except Exception:
        out['queues'][b] = {'pending': False}
try:
    out['turn'] = json.load(open(turn))
except Exception:
    out['turn'] = {}
print(json.dumps(out, indent=1))
PY
}

# ------------------------------------------------------------------ the turn
# The `polari-build` lock already stops test and main running together. This is
# the ALTERNATION on top of it: if I was the last to run and the other side has
# something pending, I wait — OUTSIDE the lock, so I am not holding the build
# resource while I do it.
do_turn() {  # do_turn <job> [--once]
    local job="$1" once="${2:-}" mine other waited=0 last
    mine="$(branch_of_job "$job")"; other="$(other_branch "$mine")"
    [ -n "$mine" ] || { say "unknown job '$job' — no turn to take"; return 0; }
    while :; do
        last="$([ -f "$TURN_FILE" ] && python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("last",""))' "$TURN_FILE" 2>/dev/null || true)"
        [ "$last" = "$job" ] || { say "turn: last run was '${last:-none}' — $job goes now"; return 0; }
        [ "$(_queue_read "$other" pending false)" = true ] || {
            say "turn: $job ran last, but $other has nothing pending — $job goes again"; return 0; }
        if [ "$once" = --once ]; then
            # YIELD BY GOING AWAY, not by sleeping. A pipeline that slept here
            # would be sleeping while holding the `polari-build` lock and an
            # executor — starving the very job it is trying to let through. So
            # it ends the build instead: the ONE pending item is untouched, the
            # lock is released at once, and the next poll picks this branch up
            # after the other side has had its turn. "Latest wins" is preserved
            # because the pending item never named a sha in the first place.
            say "turn: $job ran last and $other is pending — YIELDING (this build ends; the pending item stays and the next poll takes it)"
            return 7
        fi
        if [ "$waited" -ge "$TURN_MAX_WAIT_S" ]; then
            say "turn: waited ${waited}s for $other and it has not taken its turn — going anyway (CI_TURN_MAX_WAIT_S=$TURN_MAX_WAIT_S)"
            return 0
        fi
        say "turn: $job ran last and $other is pending — yielding for ${TURN_POLL_S}s (waited ${waited}s)"
        sleep "$TURN_POLL_S"; waited=$(( waited + TURN_POLL_S ))
    done
}

do_turn_done() {
    mkdir -p "$POOL"
    printf '{"last": "%s", "at": "%s"}\n' "$1" "$(date -Is)" > "$TURN_FILE.tmp"
    mv "$TURN_FILE.tmp" "$TURN_FILE"
    say "turn: recorded '$1' as the last job to run"
}

case "${1:-queue}" in
    gate)      do_check "${2:?branch}" --super-only ;;
    check)     do_check "${2:?branch}" ;;
    saw)       do_saw "${2:?branch}" ;;
    claim)     do_claim "${2:?branch}" "${3:-}" ;;
    done)      do_done "${2:?branch}" "${3:-}" "${4:-}" ;;
    rearm)     shift; do_rearm "${1:?branch|all}" "${@:2}" ;;
    covered)   do_covered "${2:?branch}" "${3:-}" ;;
    refused)   do_refused "${2:?branch}" "${3:?sha}" "${4:-none}" "${5:-}" ;;
    release-rule) do_release_rule "${2:?branch}" "${3:-}" ;;
    queue)     if [ "${2:-}" = --json ]; then do_queue_json; else do_queue "${2:-}"; fi ;;
    turn)      do_turn "${2:?job}" "${3:-}" ;;
    turn-done) do_turn_done "${2:?job}" ;;
    shas)      forest_shas "${2:?branch}" ;;
    --help|-h) sed -n '2,101p' "$0" ;;
    *) printf 'usage: quiet.sh gate|check|saw|claim|done|rearm|covered|refused|release-rule|queue|turn|turn-done|shas …\n' >&2; exit 2 ;;
esac
