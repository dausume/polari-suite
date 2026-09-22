#!/bin/bash
# polari-jenkins/deploy/conditions.sh — MAY THIS TARGET BE DEPLOYED, NOW, WITH THIS RELEASE? (dep-0, plan §11.3)
#
#   conditions.sh <target> <version> [--now] [--report]
#
# Eight conditions, every one PRINTED with its evidence, in this order:
#   1 newer     the target runs an OLDER release than <version> (READ over ssh from the deploy agent: `current`)
#   2 tested    <version> has a `passed` test verdict, and released == tested by image id (routes/_lib.sh)
#   3 published <version> was published FOR REAL to every route this target consumes (release.json publishedTo)
#   4 window    now is inside the target's maintenance window (cron) — a person's --now overrides
#   5 healthy   every HEALTH url answers 2xx now — an unhealthy target is a rescue, not an upgrade
#   6 disk      free space on the target ≥ MIN_FREE_GB
#   7 idle      no other deploy of this target is in flight (pool/deploy/<target>/lock)
#   8 hold      HOLD is off — a person's --now overrides
#   9 unfailed  this release did not already FAIL on this target (rule 4: a failed deploy waits for a
#               newer release or a person's --now; pool/deploy/<target>/<version>/failed.json)
# Any one false → SKIP: pool/deploy/<target>/<version>/skipped.json is written (not with --report)
# and the exit is 6. All true → GO, exit 0. A skip is an ANSWER, never a failure; nothing is touched.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; J="$(cd "$HERE/.." && pwd)"
. "$HERE/targets.sh"
POOL="${POLARI_POOL:-$J/pool}"
TARGET="${1:?target name}"; VERSION="${2:?version}"; shift 2
NOW=0; REPORT=0
for a in "$@"; do case "$a" in --now) NOW=1 ;; --report) REPORT=1 ;; *) echo "conditions.sh: unknown flag $a" >&2; exit 2 ;; esac; done
target_exists "$TARGET" || { echo "conditions.sh: no such target '$TARGET' (pol jenkins deploy list)" >&2; exit 2; }
SSH_BIN="${CI_DEPLOY_SSH:-ssh}"; SSH_TMO="${CI_SSH_TIMEOUT:-15}"
CURL_BIN="${CI_DEPLOY_CURL:-curl}"
ALIAS="$(target_field "$TARGET" SSH_ALIAS)"
POOL_DIR="$POOL/$VERSION"
OUT_DIR="$POOL/deploy/$TARGET/$VERSION"

ROWS=(); VERDICT=GO; FIRST_FAIL=""
row() {  # row GO|SKIP|INFO <condition> <evidence>
    printf '%-4s %-9s %s\n' "$1" "$2" "$3"; ROWS+=("$1"$'\t'"$2"$'\t'"$3")
    if [ "$1" = SKIP ]; then VERDICT=SKIP; [ -n "$FIRST_FAIL" ] || FIRST_FAIL="$2: $3"; fi
}
# ONLY the deploy agent's verbs ever cross this ssh (his ruling 2026-09-22): the pipeline's key is restricted
# to the agent on the target (authorize --forced-command), which reads no answers, vault or certificate.
# The prefix is what an unrestricted dev key needs; a restricted key ignores it (SSH_ORIGINAL_COMMAND).
tssh() { "$SSH_BIN" -o BatchMode=yes -o ConnectTimeout="$SSH_TMO" "$ALIAS" "pol prod agent $*" 2>&1; }

echo "deploy conditions — target $TARGET (alias $ALIAS, route $(target_field "$TARGET" ROUTE), profile $(target_field "$TARGET" PROFILE)) ← release $VERSION${NOW:+ }$([ "$NOW" = 1 ] && echo '[--now: a person; window + hold overridden]')"

# ---- 1 newer: what the target runs is READ, never guessed
CUR="$(tssh current 2>/dev/null)"; RC=$?
if [ "$RC" != 0 ] || ! printf '%s' "$CUR" | grep -q '^release='; then
    row SKIP newer "cannot read the target: ssh $ALIAS 'pol prod agent current' → rc=$RC ${CUR:+(${CUR//$'\n'/ | }})"
    CUR_REL=""
else
    CUR_REL="$(printf '%s\n' "$CUR" | sed -n 's/^release=//p' | head -1)"
    CUR_STACK="$(printf '%s\n' "$CUR" | sed -n 's/^stack=//p' | head -1)"
    WANT="polari-v$VERSION"
    if [ -z "$CUR_REL" ] && [ "${CUR_STACK:-none}" = none ]; then
        row SKIP newer "the target runs NO stack yet — the FIRST deploy is a person's \`pol prod apply\` there (the agent only replaces images); after that this pipeline keeps it current"
    elif [ -z "$CUR_REL" ]; then
        row GO newer "the target's stack ${CUR_STACK} runs images without a release tag — $WANT would be its first release"
    elif [ "$CUR_REL" = "$WANT" ]; then
        row SKIP newer "the target already runs $WANT (stack ${CUR_STACK:-none}) — nothing to deploy"
    elif [ "$(printf '%s\n%s\n' "$CUR_REL" "$WANT" | sort -V | tail -1)" = "$WANT" ]; then
        row GO newer "the target runs $CUR_REL; $WANT is newer"
    else
        row SKIP newer "the target runs $CUR_REL, which is NEWER than $WANT — a deploy never goes backwards by itself (rollback is a person's re-pin)"
    fi
fi

# ---- 2 tested: the same two checks every publish route makes
if [ -f "$POOL_DIR/release.json" ]; then
    T="$( cd "$J/routes" && VERSION="$VERSION" POOL_DIR="$POOL_DIR" POLARI_POOL="$POOL" bash -c '. ./_lib.sh >/dev/null 2>&1; tested_state && released_vs_tested' 2>&1 | tail -1 )"
    case "$T" in OK) row GO tested "verdict passed for $(python3 -c 'import json,sys; print((json.load(open(sys.argv[1])).get("components") or {}).get("superproject",{}).get("sha","?")[:12])' "$POOL_DIR/release.json" 2>/dev/null); released == tested by image id" ;;
                 *)  row SKIP tested "${T:-the release rule could not be evaluated}" ;; esac
else
    row SKIP tested "no release.json under pool/$VERSION — this version was never built here"
fi

# ---- 3 published: FOR REAL, to every route this target consumes
NEEDS="$(target_field "$TARGET" NEEDS)"
if [ -f "$POOL_DIR/release.json" ]; then
    P="$(python3 - "$POOL_DIR/release.json" "$NEEDS" <<'PY'
import json, sys
m = json.load(open(sys.argv[1])); pub = m.get('publishedTo') or {}
missing = []
for r in [x for x in sys.argv[2].split(',') if x]:
    v = pub.get(r)
    if not v: missing.append('%s: not published' % r)
    elif v.get('dryRun'): missing.append('%s: rendered only (dry run)' % r)
print('OK ' + ', '.join('%s → %s' % (r, pub[r].get('url', '?')) for r in pub if not pub[r].get('dryRun')) if not missing else 'MISSING ' + '; '.join(missing))
PY
)"
    case "$P" in OK*) row GO published "${P#OK }" ;; *) row SKIP published "${P#MISSING } — the artifacts this target pulls are not all out (needs: $NEEDS)" ;; esac
else
    row SKIP published "no release.json — nothing was published"
fi

# ---- 4 window
WIN="$(target_field "$TARGET" WINDOW)"
if [ "$NOW" = 1 ]; then row GO window "overridden by --now (a person)"
elif [ "$WIN" = any ]; then row GO window "any"
else
    W="$(python3 - "$WIN" <<'PY'
import sys, datetime
spec = sys.argv[1].split()
now = datetime.datetime.now()
vals = [now.minute, now.hour, now.day, now.month, now.isoweekday() % 7]
def ok(field, v, lo, hi):
    for part in field.split(','):
        step = 1
        if '/' in part: part, step = part.split('/'); step = int(step)
        if part == '*': a, b = lo, hi
        elif '-' in part: a, b = map(int, part.split('-'))
        else: a = b = int(part)
        if a <= v <= b and (v - a) % step == 0: return True
    return False
if len(spec) != 5: print('BAD'); sys.exit(0)
bounds = [(0, 59), (0, 23), (1, 31), (1, 12), (0, 7)]
print('IN' if all(ok(f, v, *b) for f, v, b in zip(spec, vals, bounds)) else 'OUT')
PY
)"
    case "$W" in IN) row GO window "now ($(date +%H:%M' '%a)) is inside '$WIN'" ;;
                 OUT) row SKIP window "now ($(date +%H:%M' '%a)) is outside '$WIN' — the next tick inside it deploys" ;;
                 *) row SKIP window "'$WIN' is not a 5-field cron window (or any)" ;; esac
fi

# ---- 5 healthy before
HEALTH="$(target_field "$TARGET" HEALTH)"
if [ -z "$HEALTH" ]; then row GO healthy "no HEALTH urls configured — no health gate (set DEPLOY_<name>_HEALTH)"
else
    BAD=""; for u in $HEALTH; do c="$("$CURL_BIN" -sk -o /dev/null -m 10 -w '%{http_code}' "$u" 2>/dev/null || echo 000)"; case "$c" in 2*) ;; *) BAD="$BAD $u→$c" ;; esac; done
    [ -z "$BAD" ] && row GO healthy "every url answers 2xx: $HEALTH" || row SKIP healthy "not healthy BEFORE the deploy:$BAD — an unhealthy target is a rescue (a person), not an upgrade"
fi

# ---- 6 disk
MINF="$(target_field "$TARGET" MIN_FREE_GB)"
FREE="$(printf '%s\n' "${CUR:-}" | sed -n 's/^free_gb=//p' | head -1)"
if [ -z "$FREE" ]; then row SKIP disk "free space unknown (the target did not answer)"
elif [ "$FREE" -ge "$MINF" ] 2>/dev/null; then row GO disk "${FREE} GB free on the target (floor $MINF)"
else row SKIP disk "only ${FREE} GB free on the target (floor $MINF) — free space there first"; fi

# ---- 7 idle
LOCK="$POOL/deploy/$TARGET/lock"
if [ -d "$LOCK" ]; then
    AGE=$(( $(date +%s) - $(stat -c %Y "$LOCK" 2>/dev/null || echo 0) ))
    if [ "$AGE" -gt "${CI_DEPLOY_LOCK_STALE_S:-7200}" ]; then row GO idle "a lock from ${AGE}s ago is STALE (> ${CI_DEPLOY_LOCK_STALE_S:-7200}s) — treated as free"
    else row SKIP idle "another deploy of $TARGET is in flight (lock ${AGE}s old: $(cat "$LOCK/what" 2>/dev/null || echo '?'))"; fi
else row GO idle "no deploy of $TARGET in flight"; fi

# ---- 8 hold
HOLD="$(target_field "$TARGET" HOLD)"
if [ "$NOW" = 1 ]; then row GO hold "overridden by --now (a person)"
elif [ "$HOLD" = true ]; then row SKIP hold "HOLD is on for $TARGET — nothing deploys by itself; a person runs: pol jenkins deploy $TARGET --now"
else row GO hold "off"; fi

# ---- 9 unfailed (rule 4 for deploys)
if [ -f "$OUT_DIR/failed.json" ] && [ "$NOW" = 0 ]; then
    row SKIP unfailed "$VERSION already FAILED on $TARGET at $(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("at","?"))' "$OUT_DIR/failed.json" 2>/dev/null) — a failed deploy waits for a newer release or a person: pol jenkins deploy $TARGET --now"
elif [ -f "$OUT_DIR/failed.json" ]; then row GO unfailed "failed earlier, retried by --now (a person)"
else row GO unfailed "no earlier failure of $VERSION on $TARGET"; fi

echo "→ $VERDICT${FIRST_FAIL:+ — $FIRST_FAIL}"
if [ "$VERDICT" = SKIP ] && [ "$REPORT" = 0 ]; then
    mkdir -p "$OUT_DIR"
    python3 - "$OUT_DIR/skipped.json" "$TARGET" "$VERSION" "$CUR_REL" "${ROWS[@]}" <<'PY'
import json, sys, datetime
path, target, version, cur = sys.argv[1:5]
rows = [dict(zip(('state', 'condition', 'evidence'), r.split('\t', 2))) for r in sys.argv[5:]]
d = {'target': target, 'version': version, 'target_runs': cur, 'verdict': 'skipped',
     'first_false': next((r for r in rows if r['state'] == 'SKIP'), None),
     'conditions': rows, 'at': datetime.datetime.now().astimezone().isoformat(timespec='seconds'),
     'note': 'a skip is an answer, not a failure: nothing touched the target; the next tick asks again'}
json.dump(d, open(path, 'w'), indent=1)
PY
    echo "  recorded: $OUT_DIR/skipped.json"
fi
[ "$VERDICT" = GO ] && exit 0 || exit 6
