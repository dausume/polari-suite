#!/bin/bash
# polari-jenkins/selftests.sh — THE TESTS THAT DO NOT NEED AN ISLE (ci-12).
#
# His ruling 2026-09-19: pushing to `test` "runs all of our tests and scans …
# automates running tests for all of the modules and apps configured to run in
# that particular pipeline run."
#
# There are two kinds of test in this suite and they need different machines:
#
#   · the ISLE tests — install the deb, `isle core-install`, prove the product
#     hands the machine back. They need a throwaway VM, and that is
#     Jenkinsfile.isle-test's stage loop (still gated on ci-3).
#   · the MODULE selftests — pure python against the framework. They need
#     nothing but the backend image the build stage just made. That is this
#     file, and it is why a `partial` verdict is still worth having: the module
#     half runs today, on every push to test, isle or no isle.
#
# ONE INVOCATION, NOT A SECOND ONE. `pol modules selftest <m>` discovers a
# module's suites with exactly this `ls` and runs each as `python3 -m <dotted>`;
# the only difference here is `docker run --rm <image>` instead of
# `docker exec <running container>`, because a test pipeline has a freshly built
# image and no running stack. The discovery expression is copied verbatim so the
# two can never disagree about what a module's tests ARE.
#
#   selftests.sh <out-dir> [module…]      modules to run; `core` = the framework's
#                                         own packages (accessControl, moduleService,
#                                         polariApiServer, materialsScience, …)
#
# Env: CI_SELFTEST_IMAGE (default prf-backend:staging)
#      CI_SELFTEST_TIMEOUT_S (default 300, per suite)
#      CI_SELFTEST_CORE_LIMIT (default 0 = every core suite)
#
# Exit 0 always for a FAILING test — a failed test is a RECORDED VERDICT, not a
# build error (his model: the test pipeline runs to the end and records what it
# found). Non-zero only when the runner itself could not run at all.
set -uo pipefail

OUT="${1:?usage: selftests.sh <out-dir> [module…]}"; shift || true
IMAGE="${CI_SELFTEST_IMAGE:-prf-backend:staging}"
TMO="${CI_SELFTEST_TIMEOUT_S:-300}"
CORE_LIMIT="${CI_SELFTEST_CORE_LIMIT:-0}"
DOCKER="${SELFTEST_DOCKER:-docker}"

mkdir -p "$OUT"
say() { printf '[selftests] %s\n' "$*"; }

if ! command -v "$DOCKER" >/dev/null 2>&1 || ! "$DOCKER" image inspect "$IMAGE" >/dev/null 2>&1; then
    say "the backend image $IMAGE is not on this daemon — every module records 'skipped'"
    printf '{"image": "%s", "ran": false, "why": "image absent", "modules": {}, "suites": {}}\n' "$IMAGE" \
        > "$OUT/results.json"
    exit 0
fi

# ---------------------------------------------------------------- discovery
# The MODULE case: `pol modules selftest`'s own expression, verbatim.
suites_of_module() {   # suites_of_module <module> → dotted module paths, one per line
    "$DOCKER" run --rm --entrypoint sh "$IMAGE" -c \
        "ls $1/*_selftest.py $1/selftest_*.py 2>/dev/null || ls modules/$1/*_selftest.py modules/$1/selftest_*.py 2>/dev/null" \
        2>/dev/null | sed 's#^modules/##; s/\.py$//' | tr / .
}

# The CORE case: the framework's own packages — every top-level package with a
# selftest that is NOT under modules/. `pol modules list` reads the same two
# globs for the same reason.
suites_of_core() {
    "$DOCKER" run --rm --entrypoint sh "$IMAGE" -c \
        "ls */*_selftest.py */selftest_*.py 2>/dev/null" 2>/dev/null \
        | grep -v '^modules/' | sed 's/\.py$//' | tr / . | sort
}

# ------------------------------------------------------------------ the run
declare -A MODULE_STATE=()
RESULT_ROWS=""
run_suite() {   # run_suite <owner> <dotted>
    local owner="$1" dotted="$2" log rc=0
    log="$OUT/$(printf '%s' "$dotted" | tr '.' '_').log"
    say "$owner: python3 -m $dotted"
    timeout "$TMO" "$DOCKER" run --rm --entrypoint python3 "$IMAGE" -m "$dotted" > "$log" 2>&1 || rc=$?
    local state=pass
    if [ "$rc" = 124 ]; then state=fail
    elif [ "$rc" != 0 ]; then state=fail; fi
    printf '  %-8s %s (rc=%s, %s)\n' "$state" "$dotted" "$rc" "$(wc -l < "$log") line(s)"
    RESULT_ROWS="$RESULT_ROWS$owner	$dotted	$state	$rc
"
    case "${MODULE_STATE[$owner]:-}" in
        fail) ;;                                  # a module is only as good as its worst suite
        *) [ "$state" = fail ] && MODULE_STATE["$owner"]=fail || MODULE_STATE["$owner"]=pass ;;
    esac
}

MODULES=("$@")
[ ${#MODULES[@]} -gt 0 ] || MODULES=(core)
say "image $IMAGE · modules: ${MODULES[*]} · per-suite timeout ${TMO}s"

for m in "${MODULES[@]}"; do
    if [ "$m" = core ]; then
        mapfile -t SUITES < <(suites_of_core)
        if [ "${CORE_LIMIT:-0}" -gt 0 ]; then SUITES=("${SUITES[@]:0:$CORE_LIMIT}"); fi
        say "core: ${#SUITES[@]} suite(s) in the framework's own packages"
    else
        mapfile -t SUITES < <(suites_of_module "$m")
        say "$m: ${#SUITES[@]} suite(s)"
    fi
    if [ ${#SUITES[@]} -eq 0 ]; then
        MODULE_STATE["$m"]=skipped
        say "$m: no selftest suite found — recorded 'skipped', which is NOT a pass"
        continue
    fi
    for s in "${SUITES[@]}"; do [ -n "$s" ] && run_suite "$m" "$s"; done
done

# ----------------------------------------------------------------- the record
{
    for k in "${!MODULE_STATE[@]}"; do printf '%s\t%s\n' "$k" "${MODULE_STATE[$k]}"; done
} > "$OUT/.modules.tsv"
printf '%s' "$RESULT_ROWS" > "$OUT/.suites.tsv"

python3 - "$OUT" "$IMAGE" <<'PY'
import json, os, sys
out, image = sys.argv[1:3]
modules, suites = {}, {}
p = os.path.join(out, '.modules.tsv')
if os.path.exists(p):
    for line in open(p):
        if '\t' in line:
            k, v = line.rstrip('\n').split('\t', 1)
            modules[k] = v
p = os.path.join(out, '.suites.tsv')
if os.path.exists(p):
    for line in open(p):
        parts = line.rstrip('\n').split('\t')
        if len(parts) >= 4:
            suites[parts[1]] = {'module': parts[0], 'state': parts[2], 'rc': int(parts[3] or 0)}
doc = {'image': image, 'ran': True, 'modules': modules, 'suites': suites,
       'counts': {'pass': sum(1 for v in suites.values() if v['state'] == 'pass'),
                  'fail': sum(1 for v in suites.values() if v['state'] == 'fail'),
                  'suites': len(suites), 'modules': len(modules)}}
json.dump(doc, open(os.path.join(out, 'results.json'), 'w'), indent=1)
print('selftests: %d suite(s) — %d pass, %d fail; modules: %s'
      % (doc['counts']['suites'], doc['counts']['pass'], doc['counts']['fail'],
         ', '.join('%s=%s' % kv for kv in sorted(modules.items()))))
PY
rm -f "$OUT/.modules.tsv" "$OUT/.suites.tsv"
exit 0
