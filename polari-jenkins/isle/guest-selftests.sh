#!/bin/bash
# polari-jenkins/isle/guest-selftests.sh — ci-3, LAYER 3: THE TESTS, IN THE ISLE.
#
# polari-jenkins/selftests.sh already runs every module selftest on the pipeline
# device, in the backend image the build stage just made. That is a real reading
# and it is the one that runs on every push to test. It is NOT this reading.
#
# This one runs the same suites INSIDE THE INSTALLED PRODUCT: in the
# `prf-isle-backend` container that `isle core-install` stood up in the throwaway
# guest, out of the image the isle's own compose chose, with the isle's own
# sqlite database, its own POLARI_MODULES and its own lazy boot. A suite that
# passes in a bare `docker run` and fails here has found something neither the
# device selftests nor a human browser pass would have found.
#
# ONE DISCOVERY EXPRESSION, NOT A THIRD ONE. `pol modules selftest <m>`
# (polari-cli/scripts/modules.sh) finds a module's suites with an `ls` of two
# globs and runs each as `python3 -m <dotted>`; selftests.sh copies that
# expression verbatim for `docker run`; this copies the SAME expression for
# `docker exec` into the isle's container. The three can disagree about nothing.
#
# WHY NOT JUST CALL `pol modules selftest` HERE. Because `pol` is not on an isle
# box at all — polari-complete installs the isle CLI, not the suite CLI — and
# even where it is, `core_backend_container` matches `prf-backend` and
# `polari-node_backend` exactly and so never finds `prf-isle-backend`. That
# second half is a defect and is fixed in polari-cli rather than worked around
# here; this file would still not be able to use it, because there is no `pol`
# in the guest.
#
# Per module: pass | fail | skipped. `skipped` is NOT a pass — it means the
# module ships no selftest suite, and the report says so by name.

_selftests_guest_script() {
cat <<GUEST
set -uo pipefail
CONTAINER="${CI_ISLE_BACKEND_CONTAINER:-prf-isle-backend}"
MODULES="$1"
TMO="${CI_ISLE_SELFTEST_TIMEOUT_S:-300}"
CORE_LIMIT="${CI_ISLE_SELFTEST_CORE_LIMIT:-0}"
GUEST
cat <<'GUEST'
echo "###POLARI-SELFTEST-BEGIN"
if ! sudo docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER"; then
    echo "###FIELD container=ABSENT"
    echo "###FIELD why=the isle's backend container '$CONTAINER' is not running — nothing could be run inside the product"
    echo "###POLARI-SELFTEST-END"
    exit 0
fi
echo "###FIELD container=$CONTAINER"
echo "###FIELD image=$(sudo docker inspect --format '{{.Image}}' "$CONTAINER" 2>/dev/null)"

for M in $MODULES; do
    if [ "$M" = core ]; then
        # the framework's own packages: every top-level package with a suite
        # that is NOT under modules/ — `pol modules list` reads the same globs.
        SUITES=$(sudo docker exec "$CONTAINER" sh -c \
            "ls */*_selftest.py */selftest_*.py 2>/dev/null" 2>/dev/null \
            | grep -v '^modules/' | sed 's/\.py$//' | tr / . | sort)
        if [ "${CORE_LIMIT:-0}" -gt 0 ]; then SUITES=$(printf '%s\n' "$SUITES" | head -n "$CORE_LIMIT"); fi
    else
        SUITES=$(sudo docker exec "$CONTAINER" sh -c \
            "ls $M/*_selftest.py $M/selftest_*.py 2>/dev/null || ls modules/$M/*_selftest.py modules/$M/selftest_*.py 2>/dev/null" \
            2>/dev/null | sed 's#^modules/##; s/\.py$//' | tr / .)
    fi
    N=$(printf '%s' "$SUITES" | grep -c . || true)
    echo "###MODULE $M|$N"
    [ "$N" = 0 ] && continue
    for S in $SUITES; do
        [ -n "$S" ] || continue
        T0=$(date +%s)
        OUT=$(sudo timeout "$TMO" docker exec "$CONTAINER" python3 -m "$S" 2>&1)
        RC=$?
        SEC=$(( $(date +%s) - T0 ))
        [ "$RC" = 0 ] && ST=pass || ST=fail
        echo "###SUITE $M|$S|$ST|$RC|$SEC"
        if [ "$ST" = fail ]; then
            echo "###SUITELOG-BEGIN $S"
            printf '%s\n' "$OUT" | tail -25
            echo "###SUITELOG-END"
        fi
    done
done
echo "###POLARI-SELFTEST-END"
GUEST
}

_parse_selftests() {   # _parse_selftests <raw log file> <json out|-> <stage> <ok|no>
python3 - "$1" "$2" "$3" "$4" <<'PY'
import json, sys, datetime

raw_path, out_path, stage, reached = sys.argv[1:5]
fields, modules, suites, logs = {}, {}, {}, {}
cur_log, cur_name = None, None
for line in open(raw_path).read().splitlines():
    s = line.strip()
    if s.startswith('###SUITELOG-BEGIN '):
        cur_name = s[len('###SUITELOG-BEGIN '):].strip(); cur_log = []
    elif s.startswith('###SUITELOG-END'):
        if cur_name:
            logs[cur_name] = cur_log
        cur_log, cur_name = None, None
    elif cur_log is not None:
        cur_log.append(line)
    elif s.startswith('###FIELD '):
        k, _, v = s[len('###FIELD '):].partition('=')
        fields[k.strip()] = v.strip()
    elif s.startswith('###MODULE '):
        p = (s[len('###MODULE '):].split('|') + ['', '0'])[:2]
        modules.setdefault(p[0], 'skipped' if p[1] == '0' else 'pass')
    elif s.startswith('###SUITE '):
        p = (s[len('###SUITE '):].split('|') + ['', '', '', '', ''])[:5]
        suites[p[1]] = {'module': p[0], 'state': p[2], 'rc': p[3], 'seconds': int(p[4] or 0)}
        if p[2] == 'fail':
            modules[p[0]] = 'fail'          # a module is only as good as its worst suite

npass = sum(1 for v in suites.values() if v['state'] == 'pass')
nfail = sum(1 for v in suites.values() if v['state'] == 'fail')
failed_modules = sorted(m for m, v in modules.items() if v == 'fail')
skipped_modules = sorted(m for m, v in modules.items() if v == 'skipped')

if reached != 'ok':
    ok, why = False, 'the guest could not be reached — no suite ran inside the isle'
elif fields.get('container') == 'ABSENT':
    ok, why = False, fields.get('why', "the isle's backend container is not running")
elif not suites:
    ok, why = False, 'no selftest suite was discovered inside the isle at all'
elif failed_modules:
    ok, why = False, ('%d of %d suites failed inside the isle — %s'
                      % (nfail, len(suites), ', '.join(failed_modules)))
elif skipped_modules:
    ok, why = False, ('no selftest suite exists inside the isle for: %s (skipped is not a pass)'
                      % ', '.join(skipped_modules))
else:
    ok, why = True, '%d suite(s) ran inside the isle, all pass' % len(suites)

doc = {'kind': 'isle-selftests', 'stage': stage, 'ok': ok, 'why': why,
       'container': fields.get('container', ''), 'image': fields.get('image', ''),
       'modules': modules, 'suites': suites,
       'counts': {'suites': len(suites), 'pass': npass, 'fail': nfail},
       'failing_logs': logs,
       'at': datetime.datetime.now().isoformat(timespec='seconds')}
if out_path and out_path != '-':
    json.dump(doc, open(out_path, 'w'), indent=1)
print('%s|%s' % ('ok' if ok else 'fail', why))
PY
}

selftests_do() {   # selftests_do <modules> [<json out>] [<stage>]
    local modules="${1:-core}" out="${2:-}" stage="${3:-1}" raw reached=ok line ok why
    say "the module selftests, INSIDE the installed isle's backend container: $modules"
    if ! exists; then
        raw=""; reached=no
    else
        raw=$(_selftests_guest_script "$modules" | guest_ssh 'bash -s' 2>&1) || true
        case "$raw" in *POLARI-SELFTEST-END*) reached=ok ;; *) reached=no ;; esac
    fi
    printf '%s\n' "$raw"
    local tmp; tmp="$(mktemp)"; printf '%s' "$raw" > "$tmp"
    line=$(_parse_selftests "$tmp" "$out" "$stage" "$reached"); rm -f "$tmp"
    ok="${line%%|*}"; why="${line#*|}"
    echo
    echo "selftests in the isle: $ok — $why"
    [ -n "$out" ] && say "recorded: $out" || true
    [ "$ok" = ok ] && return 0 || return 6
}
