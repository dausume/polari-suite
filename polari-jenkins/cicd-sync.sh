#!/bin/bash
# polari-jenkins/cicd-sync.sh — the two directions between THIS device and
# the Polari core that owns its settings (ci-8, his ask 2026-09-19: "We may
# want a CICD app as well that is always enabled with the pipeline that can
# allow us to read and modify the settings of the pipeline.").
#
#   cicd-sync.sh pull            GET  $CI_CORE_URL/api/cicd  → rewrite device.env
#   cicd-sync.sh push            POST the device kind: readiness, routes armed, stages
#   cicd-sync.sh push-secrets    POST the secrets kind: PRESENCE only, never a value
#   cicd-sync.sh push-setup      POST the setup walkthrough (`pol jenkins setup --json`) so a
#                                browser with no desktop shell still sees this device's state
#                                (`push` does it too — the core cannot run `pol` itself)
#   cicd-sync.sh run <job> <number> <status> [version] [summary]
#   cicd-sync.sh isle-test <run> <stage> <core_ok> <results.json>
#   cicd-sync.sh release <version> <release.json>
#   cicd-sync.sh verdict <verdict.json> [<run>]     ci-12: ONE answer per tested sha
#   cicd-sync.sh status          what it would do, and whether the core answers
#
# THE DIRECTION OF TRUTH. Polari holds the settings; this file is the
# FALLBACK. `pull` runs at the top of every Jenkinsfile and is deliberately
# NON-FATAL: when the core does not answer, the device keeps the device.env
# it has and says so on one line. A pipeline that stalled because a web
# service was down would be a worse pipeline than one that used yesterday's
# knobs and told you.
#
# NOTHING HERE SENDS A SECRET VALUE. `push-secrets` sends names and a
# boolean; the core's ingest door REFUSES a body carrying a value-shaped
# field, so a mistake here is a 400, not a leak. The posting credential is
# itself a secret of the ci-7 posture (polari/cicd_ingest_token) and is only
# ever read into a header.
set -euo pipefail

J="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=device.sh
source "$J/device.sh"
# shellcheck source=secrets.sh
source "$J/secrets.sh"

CICD_TOKEN_SECRET="${CICD_TOKEN_SECRET:-polari/cicd_ingest_token}"
# The device's NAME in Polari. device.env's CI_DEVICE_NAME, defaulting to `pipeline` — deliberately
# NOT the machine's hostname: it would end up in a row, on a page and in an API answer.
CICD_DEVICE_NAME="${CICD_DEVICE_NAME:-${CI_DEVICE_NAME:-pipeline}}"
CURL_TIMEOUT="${CICD_TIMEOUT:-8}"

say()  { printf '[cicd-sync] %s\n' "$*"; }
warn() { printf '[cicd-sync] %s\n' "$*" >&2; }

core_url() { printf '%s' "${CI_CORE_URL:-}"; }

# The posting-only token, read into a variable and never printed. An absent
# token is not an error for `pull` (that door is a read) — only for a post.
read_token() {
    local d; d="$(secrets_dir)"
    if [ -r "$d/$CICD_TOKEN_SECRET" ]; then cat "$d/$CICD_TOKEN_SECRET"
    else sudo -n cat "$d/$CICD_TOKEN_SECRET" 2>/dev/null || true; fi
}

# ------------------------------------------------------------------- pull
# GET /api/cicd → device.env. The answer carries `device_env` already
# rendered by the module (ONE renderer, in python, beside the validation),
# so this script never re-derives a key: it writes what the core computed,
# or it keeps the file.
do_pull() {
    local url; url="$(core_url)"
    if [ -z "$url" ]; then
        say "no CI_CORE_URL — this device.env is the only truth there is (set CI_CORE_URL to sync)"
        return 0
    fi
    local body rc=0
    body="$(curl -fsS --max-time "$CURL_TIMEOUT" "$url/api/cicd?device=$CICD_DEVICE_NAME" 2>/dev/null)" || rc=$?
    if [ "$rc" != 0 ] || [ -z "$body" ]; then
        warn "the core at $url did not answer (curl rc=$rc) — KEEPING the device.env this device already has"
        return 0
    fi
    # ⚠ `python3 - <<'PY'` feeds the SCRIPT on stdin, so a heredoc'd analyser can NOT also read a pipe
    # (the §70 gotcha, in this file too). The body goes through a file and an argv path.
    local raw; raw="$(mktemp)"; printf '%s' "$body" > "$raw"
    local rendered
    rendered="$(python3 - "$raw" <<'PY' 2>/dev/null || true
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)
if not d.get('ok') or not d.get('device_env'):
    sys.exit(1)
bad = [r for r in (d.get('validation') or []) if r.get('status') == 'FAIL']
if bad:
    sys.stderr.write('REFUSED by validation: %s\n' % '; '.join('%s %s' % (r['key'], r['message']) for r in bad))
    sys.exit(2)
sys.stdout.write(d['device_env'])
PY
)"
    rm -f "$raw"
    if [ -z "$rendered" ]; then
        warn "the core answered but not with a usable settings set — KEEPING the device.env this device has"
        return 0
    fi
    local tmp; tmp="$(mktemp)"; chmod 0600 "$tmp"
    # ⚠ $(…) strips the trailing newline, so the LAST key would otherwise run into whatever is appended
    # next (seen live: CI_ISLE_STAGES=core; householdCI_CORE_URL=…). printf '%s\n', always.
    printf '%s\n' "$rendered" > "$tmp"
    if [ -f "$DEVICE_ENV_FILE" ] && cmp -s "$tmp" "$DEVICE_ENV_FILE"; then
        rm -f "$tmp"; say "device.env already matches the core — nothing to write"
    else
        # keep CI_CORE_URL: the core does not know its own address, and a pull
        # that erased it would make the NEXT pull impossible.
        printf 'CI_CORE_URL=%s\n' "$url" >> "$tmp"
        mv "$tmp" "$DEVICE_ENV_FILE"; chmod 0600 "$DEVICE_ENV_FILE"
        say "device.env rewritten from $url (Polari is the source of truth for these settings)"
    fi
    device_reload
    # ⚠ device.sh's precedence is: an explicitly EXPORTED CI_* beats the file. That exists so a run can
    # inject its own config — but it also means a CI_* exported into this process before the pull (the
    # compose environment `pol jenkins up` wrote) would silently outrank what we just pulled. Say so per
    # key rather than pretending the pull took effect.
    local k pre
    for k in $DEVICE_KEYS; do
        pre="_PULL_$k"; printf -v "$pre" '%s' "${!k:-}"
    done
    ( set -a; . "$DEVICE_ENV_FILE"; set +a
      for k in $DEVICE_KEYS; do
          pre="_PULL_$k"
          [ "${!k:-}" = "${!pre:-}" ] || printf '[cicd-sync] ⚠ %s: the core says %q but an exported value %q is in force in this shell (pol jenkins restart re-exports from the new file)\n' \
              "$k" "${!k:-}" "${!pre:-}" >&2
      done ) || true
}

# ------------------------------------------------------------------- post
post_kind() {   # post_kind <json on stdin>
    local url tok rc=0 out
    url="$(core_url)"
    # Every caller pipes a python generator into this function. Returning without
    # reading that pipe hands the generator EPIPE on its final flush — the
    # "BrokenPipeError: [Errno 32]" that used to litter a green build's log. So
    # each early exit DRAINS stdin first: nothing is posted, and nothing shouts.
    [ -n "$url" ] || { cat >/dev/null; say "no CI_CORE_URL — nothing posted"; return 0; }
    tok="$(read_token)"
    if [ -z "$tok" ]; then
        cat >/dev/null
        warn "no posting credential ($(secrets_dir)/$CICD_TOKEN_SECRET) — an administrator mints one with"
        warn "  POST $url/api/cicd/device/token   then: pol jenkins secrets put $CICD_TOKEN_SECRET"
        return 0
    fi
    out="$(curl -fsS --max-time "$CURL_TIMEOUT" -X POST "$url/api/cicd/ingest" \
            -H 'Content-Type: application/json' -H "X-Polari-CICD-Token: $tok" \
            --data-binary @- 2>&1)" || rc=$?
    if [ "$rc" != 0 ]; then warn "post failed (curl rc=$rc): ${out:0:200}"; return 0; fi
    printf '%s\n' "$out" | head -c 400; echo
}

json_list() {   # json_list a b c  → ["a","b","c"]
    python3 -c 'import json,sys; print(json.dumps(sys.argv[1:]))' "$@"
}

# ------------------------------------------------------------------- push
# The device REPORTS: readiness, which routes have their secret, and — on a
# device the core has never seen — its own settings, which the core adopts
# as the first version of the truth.
do_push() {
    local ready=false steps=0 total=8 verdict="" warns=0 pre=""
    if [ -f "$J/SETUP_STATUS.md" ]; then
        steps=$(sed -n 's/^steps: \([0-9]*\) of.*/\1/p' "$J/SETUP_STATUS.md" | head -1 || true)
        total=$(sed -n 's/^steps: [0-9]* of \([0-9]*\).*/\1/p' "$J/SETUP_STATUS.md" | head -1 || true)
        verdict=$(sed -n 's/^\*\*verdict: \([^*]*\)\*\*.*/\1/p' "$J/SETUP_STATUS.md" | head -1 || true)
        warns=$(sed -n 's/.*doctor warnings: \([0-9]*\).*/\1/p' "$J/SETUP_STATUS.md" | head -1 || true)
        pre=$(sed -n 's/.*preflight --isle: \([A-Z]*\).*/\1/p' "$J/SETUP_STATUS.md" | head -1 || true)
        [ "$verdict" = "READY" ] && ready=true
    fi
    local routes="[]" r need s miss armed
    routes="$(
      for r in $SECRETS_ACTIVE_ROUTES; do
          need=$(secrets_route_requires "$r"); miss=""; armed=true
          for s in $need; do secrets_have "$s" || { miss="$miss $s"; armed=false; }; done
          printf '%s\t%s\t%s\t%s\n' "$r" "$armed" "${miss# }" "$need"
      done | python3 -c '
import json, sys
out = []
for line in sys.stdin:
    if not line.strip():
        continue
    name, armed, miss, need = (line.rstrip("\n").split("\t") + ["", "", ""])[:4]
    out.append({"name": name, "armed": armed == "true", "parked": False,
                "why": ("" if armed == "true" else "secret absent: " + miss),
                "needs": need.split()})
for p in "dockerhub npm pypi launchpad snap".split():
    out.append({"name": p, "armed": False, "parked": True,
                "why": "parked — it needs an outside account (his rule)", "needs": []})
print(json.dumps(out))')"
    local stages; stages="$(stages_list | python3 -c '
import json, sys
print(json.dumps([[a for a in line.split() if a] for line in sys.stdin.read().splitlines()]))')"
    python3 - "$CICD_DEVICE_NAME" "$routes" "$stages" \
             "${steps:-0}" "${total:-8}" "$ready" "$verdict" "${warns:-0}" "$pre" <<'PY' | post_kind
import json, os, sys, datetime
dev, routes, stages, steps, total, ready, verdict, warns, pre = sys.argv[1:10]
g = os.environ.get
print(json.dumps({
    'kind': 'device', 'device': dev, 'at': datetime.datetime.now().isoformat(timespec='seconds'),
    'role': 'both' if g('CI_ISLE_TARGET') == 'local' else 'pipeline',
    'settings': {
        'mode': g('CI_MODE', 'suite'), 'app_name': g('CI_APP_NAME', ''), 'app_repo': g('CI_APP_REPO', ''),
        'core_source': g('CI_CORE_SOURCE', 'release:latest'),
        'isle_target': g('CI_ISLE_TARGET', 'local'), 'isle_ssh_alias': g('CI_ISLE_SSH_HOST', ''),
        'isle_ssh_user': g('CI_ISLE_SSH_USER', ''), 'vm_name': g('CI_ISLE_VM_NAME', 'polari-ci-isle'),
        'vm_ram_gb': g('CI_ISLE_VM_RAM_GB', '4'), 'vm_vcpus': g('CI_ISLE_VM_VCPUS', '2'),
        'vm_disk_gb': g('CI_ISLE_VM_DISK_GB', '30'), 'nested': g('CI_ISLE_NESTED', 'auto'),
        'isle_pool': g('CI_ISLE_POOL', ''), 'image_url': g('CI_ISLE_IMAGE_URL', ''),
        'min_free_gb': g('CI_MIN_FREE_GB', '20'), 'min_ram_headroom_gb': g('CI_MIN_RAM_HEADROOM_GB', '1'),
        'executors': g('CI_EXECUTORS', '1'),
        'routes': [r for r in g('CI_ROUTES', '').split(',') if r],
        # ci-9: the offline-first cache, and where this device's own releases go
        'cache': g('CI_CACHE', 'on'), 'cache_dir': g('CI_CACHE_DIR', ''),
        'cache_max_gb': g('CI_CACHE_MAX_GB', '40'), 'cache_proxies': g('CI_CACHE_PROXIES', 'off'),
        'route_target': g('CI_ROUTE_TARGET', ''),
    },
    'stages': json.loads(stages or '[]'),
    'routes': json.loads(routes or '[]'),
    'setup': {'steps_done': int(steps or 0), 'steps_total': int(total or 8), 'ready': ready == 'true',
              'verdict': verdict, 'doctor_warnings': int(warns or 0), 'preflight_verdict': pre},
}))
PY
}

# ------------------------------------------------------------ push-setup
# ci-11a. THE WALKTHROUGH ITSELF, mirrored in, so a plain browser with no
# desktop shell can still see where this device got to. The core cannot run
# `pol`; only the device can. This is the only way that state reaches a page.
#
# LAYER BOUNDARY: setup.sh EMITS the protocol and knows nothing about Polari
# or about any front end; this file TRANSPORTS it and knows nothing about how
# it was produced. Neither knows a desktop application exists.
#
# The document's own nesting is posted as JSON STRINGS (`checks_json`,
# `questions_json`, …), for two reasons: the ingest door refuses any key
# named like a value — and a question's key is literally `key` — and a step's
# sub-structures are opaque to the rows anyway. A `secret` question carries
# `present` or nothing; no value exists anywhere in this payload.
do_push_setup() {
    local doc rc=0
    doc="$(bash "$J/setup.sh" --json 2>/dev/null)" || rc=$?
    if [ -z "$doc" ]; then
        warn "the setup protocol could not be produced (rc=$rc) — nothing posted"
        return 0
    fi
    printf '%s' "$doc" | python3 -c '
import json, sys, datetime
dev = sys.argv[1]
try:
    d = json.load(sys.stdin)
except Exception as exc:
    sys.stderr.write("the setup document did not parse: %s\n" % exc)
    raise SystemExit(1)
steps = []
for s in d.get("steps") or []:
    steps.append({
        "name": s.get("name", ""), "index": int(s.get("index") or 0),
        "total": int(s.get("total") or 0), "title": s.get("title", ""),
        "state": s.get("state", "todo"), "explain": s.get("explain", ""),
        "checks_json": json.dumps(s.get("checks") or []),
        "questions_json": json.dumps(s.get("questions") or []),
        "actions_json": json.dumps(s.get("actions") or []),
        "where_json": json.dumps(s.get("where") or []),
    })
summary = d.get("summary") or {}
print(json.dumps({
    "kind": "setup", "device": dev,
    "at": datetime.datetime.now().isoformat(timespec="seconds"),
    "setup_protocol": d.get("protocol", ""),
    "steps": steps,
    "todo_json": json.dumps(d.get("todo") or []),
    "complete": int(summary.get("complete") or 0),
    "steps_total": int(summary.get("total") or len(steps)),
    "ready": bool(summary.get("ready")),
    "blocking": summary.get("blocking", ""),
}))' "$CICD_DEVICE_NAME" | post_kind
}

# PRESENCE, never a value — the whole point of the row class on the other end.
do_push_secrets() {
    local d; d="$(secrets_dir)"
    { for area_name in $(for r in $SECRETS_ACTIVE_ROUTES; do secrets_route_requires "$r"; done | tr ' ' '\n' | sort -u); do
          secrets_have "$area_name" && printf '%s\t1\n' "$area_name" || printf '%s\t0\n' "$area_name"
      done; } | python3 -c '
import json, sys, datetime
dev = sys.argv[1]
needs = {"github/github_token": ["github-release", "homebrew"], "registries/ghcr_token": ["ghcr"],
         "signing/apt_signing_gpg": ["apt-repo"], "signing/apt_signing_keyid": ["apt-repo"],
         "ssh/distribution_host_key": ["apt-repo"]}
items = []
for line in sys.stdin:
    if not line.strip():
        continue
    rel, present = line.rstrip("\n").split("\t")
    area, _, name = rel.partition("/")
    items.append({"area": area, "secret_name": name, "present": present == "1",
                  "kind": "paste", "needed_by": needs.get(rel, [])})
print(json.dumps({"kind": "secrets", "device": dev,
                  "at": datetime.datetime.now().isoformat(timespec="seconds"), "items": items}))' \
      "$CICD_DEVICE_NAME" | post_kind
}

do_run() {  # run <job> <number> <status> [version] [summary]
    python3 - "$CICD_DEVICE_NAME" "$@" <<'PY' | post_kind
import json, sys, datetime
dev, job, number, status = sys.argv[1:5]
version = sys.argv[5] if len(sys.argv) > 5 else ''
summary = sys.argv[6] if len(sys.argv) > 6 else ''
now = datetime.datetime.now().isoformat(timespec='seconds')
body = {'kind': 'run', 'device': dev, 'job': job, 'number': int(number or 0), 'version': version,
        'status': status, 'summary': summary, 'url': ''}
body['started' if status == 'running' else 'finished'] = now
print(json.dumps(body))
PY
}

do_isle_test() {  # isle-test <run> <stage> <core_ok> <results.json>
    python3 - "$CICD_DEVICE_NAME" "$@" <<'PY' | post_kind
import json, sys, datetime
dev, run, stage, core_ok, path = sys.argv[1:6]
try:
    data = json.load(open(path))
except Exception:
    data = {}
# ci-10: an isle that cannot hand the machine back never counts as a passing core, wherever
# the reading is mirrored. The Jenkinsfile applies the same coupling; this is the second door.
clean_uninstall = data.get('uninstall_verdict') == 'clean'
print(json.dumps({'kind': 'isle-test', 'device': dev, 'run': run, 'stage_index': int(stage or 1),
                  'version': data.get('version', ''), 'apps': data.get('tested', []),
                  'core_ok': (core_ok in ('1', 'true', 'yes')) and clean_uninstall,
                  'results': data.get('results', {}),
                  # ci-10, the two teardown readings: the PRODUCT's hand-back, and OUR leak diff
                  'uninstall_verdict': data.get('uninstall_verdict', 'skipped'),
                  'uninstall_findings': data.get('uninstall_findings', []),
                  'leak_verdict': data.get('leak_verdict', 'clean'), 'leaks': data.get('leaks', []),
                  'ram_delta_mb': data.get('ram_delta_mb', 0), 'disk_delta_mb': data.get('disk_delta_mb', 0),
                  # ci-3: the cycle — install, verify, the suites INSIDE the product, and the image ids
                  # that "released == tested" is asserted on. The ingest door ANDs core_ok with the first
                  # two, as it already did with the uninstall verdict.
                  'install': data.get('install', {}), 'verify': data.get('verify', {}),
                  'selftests': data.get('selftests', {}),
                  'selftest_counts': data.get('selftest_counts', {}),
                  'images': data.get('images', {}),
                  'finished': datetime.datetime.now().isoformat(timespec='seconds')}))
PY
}

# dep-1 — A DEPLOY RECORD, mirrored in: what runs where, since when, from which
# release, and how it went. The arithmetic happened in deploy/apply.sh; this
# posts the file it wrote (applied.json | failed.json) as kind `deploy`.
do_deploy() {  # deploy <applied.json|failed.json>
    python3 - "$CICD_DEVICE_NAME" "$@" <<'PY' | post_kind
import json, sys, datetime
dev, path = sys.argv[1:3]
try:
    d = json.load(open(path))
except Exception:
    d = {}
print(json.dumps({'kind': 'deploy', 'device': dev, 'target': d.get('target', ''), 'release': d.get('release', ''),
                  'from_release': d.get('from_release', ''), 'result': d.get('result', ''),
                  'failed_at': d.get('failed_at', ''), 'rollback': d.get('rollback', ''),
                  'apply_seconds': d.get('apply_seconds', 0), 'at': d.get('at') or datetime.datetime.now().isoformat(timespec='seconds')}))
PY
}

do_release() {  # release <version> <release.json>
    python3 - "$CICD_DEVICE_NAME" "$CI_MODE" "$CI_APP_NAME" "$CI_CORE_SOURCE" "$@" <<'PY' | post_kind
import json, os, sys, datetime
dev, mode, app, core_source, version, path = sys.argv[1:7]
try:
    m = json.load(open(path))
except Exception:
    m = {}
published = [r for r, v in (m.get('publishedTo') or {}).items() if not v.get('dryRun')]
dry = {r: 'rendered only (dry run)' for r, v in (m.get('publishedTo') or {}).items() if v.get('dryRun')}
print(json.dumps({'kind': 'release', 'device': dev, 'version': version, 'mode': mode, 'app_name': app,
                  # an app release must name the CORE it passed against, or "it passed" means nothing.
                  # ci-9: release.json's testedAgainst is the RESOLVED tag (core-artifacts.sh turned
                  # release:latest into a real one); CI_CORE_SOURCE is the fallback when it is absent.
                  'tested_against': (m.get('testedAgainst')
                                     or (core_source if mode == 'app' else ('release:polari-v%s' % version))),
                  'route_target': m.get('routeTarget', ''),
                  'cache_report': m.get('cacheReport', {}),
                  'tag': m.get('tag', ''), 'tag_pushed': bool(m.get('tagPushed')),
                  'results_present': bool(m.get('isleTestResults')), 'core_ok': bool(m.get('coreOk')),
                  'published_routes': published, 'dry_routes': dry,
                  'released': m.get('released', []), 'not_released': m.get('notReleased', {}),
                  'why_not': m.get('whyNot', ''),
                  'released_at': datetime.datetime.now().isoformat(timespec='seconds')}))
PY
}

# ci-12 — THE TEST VERDICT, mirrored in. The arithmetic happened in
# polari-jenkins/verdict.py on the device that ran the tests; this transports it.
# NOTHING here recomputes a verdict: the enforcement path (`pol jenkins promote
# main`, `routes/_lib.sh`) reads the FILE on the device, so a core that is down
# can never block or unblock a release. This row is the legible copy.
do_verdict() {  # verdict <verdict.json> [<run>]
    local path="${1:?verdict.json}" run="${2:-}"
    [ -f "$path" ] || { warn "no verdict at $path — nothing posted"; return 0; }
    python3 - "$CICD_DEVICE_NAME" "$path" "$run" <<'PY' | post_kind
import json, sys
dev, path, run = sys.argv[1:4]
try:
    v = json.load(open(path))
except Exception as exc:
    sys.stderr.write('the verdict did not parse: %s\n' % exc)
    raise SystemExit(1)
print(json.dumps({'kind': 'test-verdict', 'device': dev,
                  'sha': v.get('sha', ''), 'branch': v.get('branch', 'test'),
                  'verdict': v.get('verdict', 'partial'), 'why': v.get('why', ''),
                  'built': bool(v.get('built')),
                  # the three summaries travel whole; the row stores them as JSON strings and the
                  # page renders them as configured columns (no raw JSON on a screen).
                  'scans': v.get('scans') or {}, 'selftests': v.get('selftests') or {},
                  'isle': v.get('isle') or {},
                  'run': run or v.get('run', ''), 'decided_by': v.get('decided_by', 'pipeline'),
                  # ci-3: the page a person reads, named on the row
                  'report_path': v.get('report_path', ''),
                  'at': v.get('at', '')}))
PY
}

do_status() {
    local url; url="$(core_url)"
    echo "device:      $CICD_DEVICE_NAME"
    echo "mode:        $CI_MODE${CI_APP_NAME:+ ($CI_APP_NAME, core from $CI_CORE_SOURCE)}"
    echo "core:        ${url:-(none — device.env is the only truth)}"
    echo "credential:  $([ -n "$(read_token)" ] && echo "present ($CICD_TOKEN_SECRET)" || echo "absent ($CICD_TOKEN_SECRET) — pol jenkins secrets put $CICD_TOKEN_SECRET")"
    if [ -n "$url" ]; then
        if curl -fsS --max-time "$CURL_TIMEOUT" -o /dev/null "$url/api/cicd" 2>/dev/null; then
            echo "reachable:   yes — pol jenkins sync pull rewrites device.env from it"
        else
            echo "reachable:   NO — a pull keeps the device.env this device has and says so (never fatal)"
        fi
    fi
}

case "${1:-status}" in
    pull)         do_pull ;;
    # ci-11a: a push reports the device AND the walkthrough it is in the middle
    # of, so the page a person opens is never more stale than the last push.
    push)         do_push; do_push_setup ;;
    push-secrets) do_push_secrets ;;
    push-setup)   do_push_setup ;;
    run)          shift; do_run "$@" ;;
    isle-test)    shift; do_isle_test "$@" ;;
    release)      shift; do_release "$@" ;;
    deploy)       shift; do_deploy "$@" ;;
    verdict)      shift; do_verdict "$@" ;;
    status)       do_status ;;
    --help|-h)    sed -n '2,30p' "$0" ;;
    *)            warn "unknown: cicd-sync.sh $1 (pull|push|push-secrets|push-setup|run|isle-test|release|verdict|status)"; exit 2 ;;
esac
