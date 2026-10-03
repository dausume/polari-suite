#!/bin/bash
# polari-jenkins/scenarios.sh — THE FIRMWARE SCENARIOS STAGE (plan FIRMWARE_SCENARIO §9 sc-4, D-sc-3; ADVISORY).
#
# After the proofs stage: every RUNNABLE firmwarefaults scenario re-run as its BEFORE/AFTER pair on the simavr
# UNO twin, in the image the build stage just made — so a firmware change that breaks a technique (the AFTER
# build no longer witnessed) shows up in the report. The pairs run through the module's OWN entry point,
# `python3 -m firmwarefaults.custom.faults_cli run <scenario> --both --seed <k>` (the CLI's offline path, one
# local JSON record per pair), driven by a small python loop this script hands to `docker run` — no file is
# added to the framework for it. The twin, avr-gcc and the disassembler run in a THROWAWAY worker of the board
# engines image (prf-board-engines:trixie) on a private network, named to the module by its own knob
# BOARD_ENGINES_URL — the backend image has no docker to take the board ladder's local-image rung.
#
#   scenarios.sh <out-dir>                      the stage → <out-dir>/results.json + scenarios.log
#   scenarios.sh --print-driver                 the in-container driver (python), for a dry run on a host
#   scenarios.sh --summarise <records> <out>    records (the driver's tree) → results.json (selftest fixtures)
#
# Env: CI_SCENARIOS (default on)               off = skip, recorded with the reason
#      CI_SCENARIO_SEEDS (default 1)           seeds 0..N-1 per pair (the twin is deterministic without a BER step,
#                                              so N > 1 only buys anything on the seeded --uart-ber / --rx-noise ones)
#      CI_SELFTEST_IMAGE (default prf-backend:staging)   the backend image to run the module in
#      BOARD_ENGINES_IMAGE (default prf-board-engines:trixie)   the engines worker image (board's own knob)
#      BOARD_ENGINES_URL                       a worker this device already names — used instead of a throwaway one
#      CI_SCENARIOS_TIMEOUT_S (default 900)    the whole run of pairs
#
# Exit 0 always: a red pair (AFTER not witnessed, a pair that would not run) is RECORDED in results.json for the
# verdict + report, never a build failure — D-sc-3 (advisory, yes). Results come OUT of the container with
# `docker cp` — never a bind mount of a controller path (proofs.sh's fix, polari-test #2084: the host daemon
# resolves -v paths on the HOST and made a root-owned dir).
set -uo pipefail

driver() {
cat <<'PY'
# the scenarios stage's driver — runs INSIDE the backend image (workdir = the framework, PYTHONPATH has modules/)
import json, os, subprocess, sys, time
ROOT = os.environ.get('SCN_ROOT', '/tmp/scn')
SEEDS = max(1, int(os.environ.get('CI_SCENARIO_SEEDS', '1') or 1))
os.makedirs(ROOT, exist_ok=True)
from firmwarefaults.custom import scenarios as SC
gap = getattr(SC, 'engine_gap', lambda s: '')   # sc-3: the C3 scenarios need the esp engines (ESP_ENGINES_URL / prf-esp-engines)
names = [s['name'] for s in SC.SEED_SCENARIOS if SC.runnable(s) and not gap(s)]
skipped = [{'scenario': s['name'], 'why': (SC.refusal(s) or gap(s))[:200]} for s in SC.SEED_SCENARIOS if not SC.runnable(s) or gap(s)]
print('[scenarios] runnable: %s' % ' '.join(names), flush=True)
for s in skipped:
    print('[scenarios] not runnable (refused before anything is built): %s — %s' % (s['scenario'], s['why'][:120]), flush=True)
eng = subprocess.run([sys.executable, '-m', 'firmwarefaults.custom.faults_cli', 'engines'], capture_output=True, text=True)
print(eng.stdout, end='', flush=True)
json.dump({'runnable': names, 'not_runnable': skipped, 'engines': eng.stdout, 'seeds': SEEDS}, open(os.path.join(ROOT, 'index.json'), 'w'), indent=1)
for n in names:
    for k in range(SEEDS):
        d = os.path.join(ROOT, '%s@seed%d' % (n, k))
        os.makedirs(d, exist_ok=True)
        env = dict(os.environ, POLARI_FAULTS_HOME=os.path.join(d, 'faults-home'), POLARI_BOARD_HOME=os.path.join(d, 'board-home'))
        t0 = time.time()
        p = subprocess.run([sys.executable, '-m', 'firmwarefaults.custom.faults_cli', 'run', n, '--both', '--seed', str(k)],
                           capture_output=True, text=True, env=env)
        wall = round(time.time() - t0, 3)
        open(os.path.join(d, 'run.log'), 'w').write(p.stdout + p.stderr)
        json.dump({'scenario': n, 'seed': k, 'rc': p.returncode, 'wall_s': wall,
                   'tail': (p.stdout + p.stderr).strip().splitlines()[-3:]}, open(os.path.join(d, 'meta.json'), 'w'), indent=1)
        print(p.stdout, end='', flush=True)
        if p.returncode:
            print(p.stderr[-1500:], end='', flush=True)
        print('[scenarios] %s seed %d rc=%d %.2f s' % (n, k, p.returncode, wall), flush=True)
PY
}

summarise() {   # <records-dir> <out-json> [image] [engines-where] [elapsed_s]
python3 - "$@" <<'PY'
import glob, json, os, sys
rec_dir, out = sys.argv[1], sys.argv[2]
image = sys.argv[3] if len(sys.argv) > 3 else ''
where = sys.argv[4] if len(sys.argv) > 4 else ''
elapsed = float(sys.argv[5]) if len(sys.argv) > 5 and sys.argv[5] else None
def load(p):
    try:
        return json.load(open(p))
    except Exception:  # noqa: BLE001
        return {}
idx = load(os.path.join(rec_dir, 'index.json'))
pairs, red, warn = [], [], []
for d in sorted(glob.glob(os.path.join(rec_dir, '*@seed*'))):
    meta = load(os.path.join(d, 'meta.json'))
    name, seed = meta.get('scenario') or os.path.basename(d).rsplit('@seed', 1)[0], meta.get('seed', 0)
    recs = sorted(glob.glob(os.path.join(d, 'faults-home', 'runs', '*.json')))
    rec = load(recs[-1]) if recs else {}
    runs = {r.get('side'): r for r in rec.get('ScenarioRun', [])}
    claims = {c.get('name'): c.get('proof_status', '') for c in rec.get('MathClaim', [])}
    def side(r):
        if not r:
            return None
        return {'outcome': r.get('outcome', ''), 'claim_status': claims.get(r.get('claim'), ''), 'variant': r.get('variant', ''),
                'observed': (r.get('observable_value') or r.get('uptime_sequence') or '')[:120], 'words': (r.get('verdict_words') or '')[:200],
                'wall_s': r.get('wall_s')}
    b, a = side(runs.get('before')), side(runs.get('after'))
    cd = {}
    try:
        cd = json.loads((runs.get('after') or {}).get('cost_delta_json') or '{}')
    except ValueError:
        pass
    cost = {k: cd[k] for k in ('flash_bytes', 'ram_bytes', 'cycles', 'guarded_fn_cycles', 'cycles_what', 'isr_latency_max_cycles',
                               'stack_high_water_bytes') if k in cd}
    p = {'scenario': name, 'seed': seed, 'before': b, 'after': a, 'cycle': int((runs.get('before') or {}).get('fault_cycle') or 0),
         'cost': cost, 'wall_s': meta.get('wall_s'), 'rc': meta.get('rc')}
    pairs.append(p)
    if meta.get('rc') not in (0, None) or b is None:
        red.append({'scenario': name, 'seed': seed, 'why': 'did not run (rc=%s): %s' % (meta.get('rc'), ' '.join(meta.get('tail') or [])[:300])})
    elif a is None:   # a build-refused scenario (1b): the refusal IS the safe outcome
        if b['outcome'] != 'inapplicable':
            red.append({'scenario': name, 'seed': seed, 'why': 'the guard no longer refuses the build: BEFORE %s' % b['outcome']})
    elif a['claim_status'] != 'witnessed' and not (not a['claim_status'] and a['outcome'] == 'passed'):
        red.append({'scenario': name, 'seed': seed, 'why': 'AFTER (%s) not witnessed: %s / %s — %s' % (a['variant'], a['outcome'], a['claim_status'] or '-', a['words'][:160])})
    if b and a and b['outcome'] != 'failed':
        warn.append({'scenario': name, 'seed': seed, 'why': 'BEFORE (%s) no longer reproduces the fault: %s' % (b['variant'], b['outcome'])})
counts = {'pairs': len(pairs), 'witnessed': sum(1 for p in pairs if p['after'] and p['after']['claim_status'] == 'witnessed'),
          'refused_builds': sum(1 for p in pairs if p['before'] and not p['after'] and p['before']['outcome'] == 'inapplicable'),
          'red': len(red)}
doc = {'ran': bool(pairs), 'not_run': '' if pairs else 'no pair produced a record', 'image': image, 'engines': where,
       'seeds': idx.get('seeds'), 'runnable': idx.get('runnable', []), 'not_runnable': idx.get('not_runnable', []),
       'pairs': pairs, 'red': red, 'warn': warn, 'counts': counts,
       'pairs_wall_s': round(sum(float(p['wall_s'] or 0) for p in pairs), 3), 'elapsed_s': elapsed,
       'advisory': 'scenario pairs never gate — a red pair is recorded, not enforced (FIRMWARE_SCENARIO_PLAN D-sc-3)'}
json.dump(doc, open(out, 'w'), indent=1)
print('[scenarios] %d pair(s): %d witnessed, %d refused build(s), %d red%s · pairs %.1f s%s' % (
    counts['pairs'], counts['witnessed'], counts['refused_builds'], counts['red'],
    (' (' + ', '.join(r['scenario'] for r in red) + ')') if red else '', doc['pairs_wall_s'],
    (' · stage %.1f s' % elapsed) if elapsed is not None else ''))
PY
}

case "${1:-}" in
    --print-driver) driver; exit 0 ;;
    --summarise) shift; summarise "$@"; exit $? ;;
esac

OUT="${1:?usage: scenarios.sh <out-dir> | --print-driver | --summarise <records> <out>}"
IMAGE="${CI_SELFTEST_IMAGE:-prf-backend:staging}"
ENG_IMAGE="${BOARD_ENGINES_IMAGE:-prf-board-engines:trixie}"
TMO="${CI_SCENARIOS_TIMEOUT_S:-900}"
DOCKER="${SELFTEST_DOCKER:-docker}"
T0=$(date +%s.%N)
mkdir -p "$OUT"
say() { printf '[scenarios] %s\n' "$*"; }
elapsed() { python3 -c "import sys; print(round(float(sys.argv[2]) - float(sys.argv[1]), 3))" "$T0" "$(date +%s.%N)"; }
not_run() {   # <why>
    say "not run: $1 — recorded, not thrown"
    python3 - "$OUT/results.json" "$IMAGE" "$1" "$(elapsed)" <<'PY'
import json, sys
json.dump({'ran': False, 'not_run': sys.argv[3], 'image': sys.argv[2], 'pairs': [], 'red': [], 'warn': [], 'counts': {},
           'elapsed_s': float(sys.argv[4]), 'advisory': 'scenario pairs never gate (FIRMWARE_SCENARIO_PLAN D-sc-3)'},
          open(sys.argv[1], 'w'), indent=1)
PY
    exit 0
}

case "${CI_SCENARIOS:-on}" in
    off|0|false|no) not_run "CI_SCENARIOS=${CI_SCENARIOS} on this device" ;;
esac
if ! command -v "$DOCKER" >/dev/null 2>&1 || ! "$DOCKER" image inspect "$IMAGE" >/dev/null 2>&1; then
    not_run "image absent: the backend image $IMAGE is not on this daemon"
fi
# the module, in THIS image — a backend built before firmwarefaults existed cannot run a pair (and says so)
if ! "$DOCKER" run --rm --entrypoint python3 "$IMAGE" -c 'import firmwarefaults.custom.faults_cli, board.custom.board_engines' >/dev/null 2>&1; then
    not_run "module absent in image: $IMAGE has no firmwarefaults (or board) module"
fi

NAME="polari-ci-scenarios-$$"
NET=""; WORKER=""
cleanup() {
    "$DOCKER" rm -f "$NAME" >/dev/null 2>&1 || true
    [ -n "$WORKER" ] && "$DOCKER" rm -f "$WORKER" >/dev/null 2>&1 || true
    [ -n "$NET" ] && "$DOCKER" network rm "$NET" >/dev/null 2>&1 || true
}
trap cleanup EXIT
"$DOCKER" rm -f "$NAME" >/dev/null 2>&1 || true

if [ -n "${BOARD_ENGINES_URL:-}" ]; then
    URL="$BOARD_ENGINES_URL"; NETARG=(--network host); WHERE="BOARD_ENGINES_URL=$URL (this device's worker)"
else
    "$DOCKER" image inspect "$ENG_IMAGE" >/dev/null 2>&1 || not_run "image absent: the board engines image $ENG_IMAGE is not on this daemon (and no BOARD_ENGINES_URL)"
    NET="polari-ci-scn-$$"; WORKER="polari-ci-scn-engines-$$"
    "$DOCKER" network create "$NET" >/dev/null 2>&1 || not_run "could not create the private network $NET"
    "$DOCKER" run -d --name "$WORKER" --network "$NET" --network-alias board-engines --memory 512m "$ENG_IMAGE" >/dev/null 2>&1 \
        || not_run "the board engines worker ($ENG_IMAGE) would not start"
    up=""
    for _ in $(seq 1 60); do
        if "$DOCKER" exec "$WORKER" python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:9830/capability', timeout=2)" >/dev/null 2>&1; then up=1; break; fi
        sleep 0.5
    done
    [ -n "$up" ] || not_run "the board engines worker ($ENG_IMAGE) never answered /capability"
    URL="http://board-engines:9830"; NETARG=(--network "$NET"); WHERE="a throwaway worker of $ENG_IMAGE ($("$DOCKER" image inspect -f '{{.Id}}' "$ENG_IMAGE" 2>/dev/null | cut -c8-19))"
fi

say "image $IMAGE · engines: $WHERE · seeds ${CI_SCENARIO_SEEDS:-1} · timeout ${TMO}s"
rc=0
timeout "$TMO" "$DOCKER" run --name "$NAME" "${NETARG[@]}" -u "$(id -u):$(id -g)" -e HOME=/tmp \
    -e BOARD_ENGINES_URL="$URL" -e CI_SCENARIO_SEEDS="${CI_SCENARIO_SEEDS:-1}" -e SCN_ROOT=/tmp/scn \
    --entrypoint python3 "$IMAGE" -c "$(driver)" > "$OUT/scenarios.log" 2>&1 || rc=$?
rm -rf "$OUT/records"
"$DOCKER" cp "$NAME:/tmp/scn" "$OUT/records" >/dev/null 2>&1 || say "no records came out of the container (rc=$rc)"
if [ ! -d "$OUT/records" ]; then
    tail -20 "$OUT/scenarios.log" 2>/dev/null
    not_run "the driver did not complete (rc=$rc)"
fi
[ "$rc" = 0 ] || say "the driver exited rc=$rc (timeout = 124) — the pairs that finished are summarised"
summarise "$OUT/records" "$OUT/results.json" "$IMAGE" "$WHERE" "$(elapsed)"
grep '^\[scenarios\]\|^\[FAIL\]\|^\[PASS\]\|^\[N/A \]\|^\[COST\]\|^\[REFUSED\]' "$OUT/scenarios.log" | sed 's/^/  /'
exit 0
