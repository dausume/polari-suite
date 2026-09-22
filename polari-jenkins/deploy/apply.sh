#!/bin/bash
# polari-jenkins/deploy/apply.sh — DEPLOY ONE RELEASE TO ONE TARGET, over ssh, as the pipeline user (dep-1, plan §11.4)
#
#   apply.sh <target> <version> [--now] [--dry-run]
#
# 1. conditions.sh must say GO (a person's --now overrides window + hold + an earlier failure, nothing else)
# 2. lock pool/deploy/<target>/lock — one deploy of a target at a time
# 3. ONLY the deploy agent's verbs cross the ssh (his ruling 2026-09-22 — the pipeline's key is RESTRICTED to
#    the agent on the target; it cannot touch production secrets, and `docker service update --image` keeps
#    every secret and config attached):
#      ssh <alias> pol prod agent stash <version>     every named volume of the stack tar'd BEFORE anything moves
#      ssh <alias> pol prod agent update <version>    per service: --image <registry>/<name>:<version>, start-first,
#                                                     one at a time, converged before the next — no interruption
#      ssh <alias> pol prod agent verify              every service n/n + the local /api/health
#      wait SETTLE_S; every HEALTH url must answer 2xx (from here — the public routes)
# 4. success → pool/deploy/<target>/<version>/applied.json (+ a DeployRecord mirrored in)
#    failure → ROLLBACK = `agent rollback <previous>` (releases are immutable; "back" is a re-pin of the previous
#              tags, the stash stays for a person's `pol prod restore`), verify again, failed.json with BOTH
#              outputs — and rule 4: this version is not retried on this target until a newer release or --now.
# NOTHING BUILDS ON THE TARGET, and the FIRST deploy (no stack yet) is a person's `pol prod apply` there.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; J="$(cd "$HERE/.." && pwd)"
. "$HERE/targets.sh"; . "$J/routes/destinations.sh"
POOL="${POLARI_POOL:-$J/pool}"
TARGET="${1:?target name}"; VERSION="${2:?version}"; shift 2
NOW=0; DRY=0
for a in "$@"; do case "$a" in --now) NOW=1 ;; --dry-run) DRY=1 ;; *) echo "apply.sh: unknown flag $a" >&2; exit 2 ;; esac; done
target_exists "$TARGET" || { echo "apply.sh: no such target '$TARGET'" >&2; exit 2; }
SSH_BIN="${CI_DEPLOY_SSH:-ssh}"; SSH_TMO="${CI_SSH_TIMEOUT:-15}"; CURL_BIN="${CI_DEPLOY_CURL:-curl}"
ALIAS="$(target_field "$TARGET" SSH_ALIAS)"; PROFILE="$(target_field "$TARGET" PROFILE)"
HEALTH="$(target_field "$TARGET" HEALTH)"; SETTLE="$(target_field "$TARGET" SETTLE_S)"
REG="$(dest_registry_ns)"; REG="${REG%/}/"
OUT_DIR="$POOL/deploy/$TARGET/$VERSION"; LOCK="$POOL/deploy/$TARGET/lock"
say() { printf '[deploy:%s] %s\n' "$TARGET" "$*"; }
# only the agent's verbs (see the header); the prefix is for an unrestricted dev key, a restricted key ignores it
tssh() { "$SSH_BIN" -o BatchMode=yes -o ConnectTimeout="$SSH_TMO" "$ALIAS" "pol prod agent $*" 2>&1; }
health_after() {  # → '' when every url answers 2xx, else the bad ones
    local bad="" u c
    for u in $HEALTH; do c="$("$CURL_BIN" -sk -o /dev/null -m 10 -w '%{http_code}' "$u" 2>/dev/null || echo 000)"; case "$c" in 2*) ;; *) bad="$bad $u→$c" ;; esac; done
    printf '%s' "$bad"
}
record() {  # record <applied|failed> <from> <k=v json fragments…>
    local kind="$1" from="$2"; shift 2
    mkdir -p "$OUT_DIR"
    python3 - "$OUT_DIR/$kind.json" "$TARGET" "$VERSION" "$from" "$kind" "$ALIAS" "$@" <<'PY'
import json, sys, datetime
path, target, version, frm, kind, alias = sys.argv[1:7]
d = {'target': target, 'version': version, 'release': 'polari-v' + version, 'from_release': frm, 'result': kind,
     'ssh_alias': alias, 'at': datetime.datetime.now().astimezone().isoformat(timespec='seconds')}
for kv in sys.argv[7:]:
    k, _, v = kv.partition('=')
    try: d[k] = json.loads(v)
    except Exception: d[k] = v
json.dump(d, open(path, 'w'), indent=1)
PY
    say "recorded: $OUT_DIR/$kind.json"
    bash "$J/cicd-sync.sh" deploy "$OUT_DIR/$kind.json" 2>/dev/null || true
}

# ---- 1 the conditions (a dry run only REPORTS; nothing is written)
say "conditions for $VERSION on $TARGET:"
if [ "$DRY" = 1 ]; then bash "$HERE/conditions.sh" "$TARGET" "$VERSION" --report $([ "$NOW" = 1 ] && echo --now); CRC=$?
else bash "$HERE/conditions.sh" "$TARGET" "$VERSION" $([ "$NOW" = 1 ] && echo --now); CRC=$?; fi
if [ "$DRY" = 1 ]; then
    say "DRY RUN — the commands a real run would send to '$ALIAS' (conditions said $([ "$CRC" = 0 ] && echo GO || echo SKIP)):"
    echo "  ssh $ALIAS pol prod agent stash $VERSION      # every named volume of the stack, tar'd first"
    echo "  ssh $ALIAS pol prod agent update $VERSION     # docker service update --image <registry>/<name>:$VERSION, start-first, one at a time"
    echo "  ssh $ALIAS pol prod agent verify"
    echo "  sleep $SETTLE; then every HEALTH url must answer 2xx: ${HEALTH:-(none configured)}"
    echo "  on failure: ssh $ALIAS pol prod agent rollback <previous>  (re-pin), then verify again; the stash stays for pol prod restore"
    echo "  (the key on '$ALIAS' is restricted to the agent: it can run nothing else there — pol jenkins deploy authorize $TARGET)"
    exit 0
fi
[ "$CRC" = 0 ] || { say "SKIP — not deploying (see above)"; exit 6; }

# ---- 2 the lock
mkdir -p "$(dirname "$LOCK")"
if ! mkdir "$LOCK" 2>/dev/null; then say "another deploy holds $LOCK — not deploying"; exit 6; fi
printf '%s %s pid=%s\n' "$VERSION" "$(date -Is)" "$$" > "$LOCK/what"
trap 'rm -rf "$LOCK"' EXIT

# ---- 3 what the target runs now (the rollback point), the STASH, then the update
FROM="$(tssh current 2>/dev/null | sed -n 's/^release=//p' | head -1)"
say "the target runs: ${FROM:-nothing yet} → deploying polari-v$VERSION"
mkdir -p "$OUT_DIR"; T0=$(date +%s)
say "ssh $ALIAS pol prod agent stash $VERSION   (every named volume of the stack, before anything moves)"
STASH_OUT="$(tssh stash "$VERSION" | tee "$OUT_DIR/stash.log")"; SRC=${PIPESTATUS[0]}
STASH="$(printf '%s\n' "$STASH_OUT" | sed -n 's/^stash=//p' | tail -1)"
if [ "$SRC" != 0 ]; then
    say "STASH FAILED (rc=$SRC) — the update does not proceed without a complete stash"; VERIFY_OUT="(stash failed before the update)"; FAILED=stash; ARC=1
else
    say "stashed: ${STASH:-nothing to stash}"
    say "ssh $ALIAS pol prod agent update $VERSION   (start-first, one service at a time, converged before the next)"
    tssh update "$VERSION" | tee "$OUT_DIR/apply.log"; ARC=${PIPESTATUS[0]}
fi
T1=$(date +%s)
if [ "$ARC" != 0 ]; then
    [ -n "${FAILED:-}" ] || { say "UPDATE FAILED (rc=$ARC, $((T1-T0))s)"; VERIFY_OUT="(update failed before verify)"; FAILED=update; }
else
    say "ssh $ALIAS pol prod agent verify"
    VERIFY_OUT="$(tssh verify | tee "$OUT_DIR/verify.log")"; VRC=${PIPESTATUS[0]}
    if [ "$VRC" != 0 ]; then say "VERIFY FAILED (rc=$VRC)"; FAILED=verify
    else
        say "settling ${SETTLE}s before the health reading"; sleep "$SETTLE"
        BAD="$(health_after)"
        if [ -n "$BAD" ]; then say "NOT HEALTHY after the deploy:$BAD"; FAILED=health
        else FAILED=""; say "healthy after: ${HEALTH:-(no urls configured)}"; fi
    fi
fi

# ---- 4 the outcome
if [ -z "$FAILED" ]; then
    say "DEPLOYED polari-v$VERSION to $TARGET in $(( $(date +%s) - T0 ))s (was ${FROM:-nothing})"
    record applied "$FROM" "apply_seconds=$((T1-T0))" "stash=\"${STASH:-}\"" "verify=$(python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()[-4000:]))' <<< "$VERIFY_OUT")" "health=\"${HEALTH:-none}\""
    exit 0
fi

# ---- rollback = re-pin the previous release
RB_OUT=""; RB_RC=""; RB_VERIFY=""
if [ "$FAILED" = stash ]; then
    RB_STATE="nothing moved (the stash failed first) — the target is untouched; a person looks at the stash: ssh $ALIAS"
elif [ -n "$FROM" ] && [ "$FROM" != "polari-v$VERSION" ]; then
    PREV="${FROM#polari-v}"
    say "ROLLBACK: ssh $ALIAS pol prod agent rollback $PREV  (releases are immutable — back is a re-pin of the previous tags; the stash ${STASH:-} stays for pol prod restore)"
    RB_OUT="$(tssh rollback "$PREV" | tee "$OUT_DIR/rollback.log")"; RB_RC=${PIPESTATUS[0]}
    RB_VERIFY="$(tssh verify 2>&1)"; RB_VRC=$?
    say "rollback apply rc=$RB_RC, verify rc=$RB_VRC"
    RB_STATE="$([ "$RB_RC" = 0 ] && [ "$RB_VRC" = 0 ] && echo "rolled back to $FROM" || echo "ROLLBACK FAILED — the target needs a person: ssh $ALIAS")"
else
    RB_STATE="no previous release to roll back to (this was the first deploy) — the target needs a person: ssh $ALIAS"
fi
say "FAILED at $FAILED — $RB_STATE"
record failed "$FROM" "failed_at=\"$FAILED\"" "rollback=\"$RB_STATE\"" "stash=\"${STASH:-}\"" \
       "verify=$(python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()[-4000:]))' <<< "$VERIFY_OUT")" \
       "rollback_verify=$(python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()[-4000:]))' <<< "$RB_VERIFY")" \
       "note=\"rule 4: this version is not retried on this target until a newer release, or a person: pol jenkins deploy $TARGET --now\""
exit 1
