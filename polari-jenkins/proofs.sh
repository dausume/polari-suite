#!/bin/bash
# polari-jenkins/proofs.sh — THE PROOFS STAGE (plan COMPUTE_LOD_TENSOR §I.9; ADVISORY).
#
# After the module selftests: boot the framework in the image the build stage
# just made and run EVERY MathClaim through its cheapest tier (numeric /
# interval / sympy / z3 within each claim's budget); then the Lean certificates
# — only where the engines ladder resolves a checker on this device
# (PROOF_ENGINES_URL, or the polari-proof-tools image), and only the .lean
# files that changed since their last recorded proof. One invocation of the
# framework's own tests/proofs_stage.py, inside `docker run --rm <image>`,
# exactly as selftests.sh runs a suite.
#
#   proofs.sh <out-dir>
#
# Env: CI_SELFTEST_IMAGE (default prf-backend:staging)   the image to boot
#      CI_PROOFS_TIMEOUT_S (default 1800)                  the whole stage
#      PROOF_ENGINES_URL                                    the Lean worker, if this device has one to name
#      CI_PROOFS_NO_LEAN=1                                  skip the Lean tier on purpose
#
# Exit 0 always: a red verdict (refuted / error / undecided / unprovable-here)
# is RECORDED in results.json for the verdict + report, never a build failure
# — his rule for the scans, applied here until he says otherwise. Non-zero
# only when the runner itself could not run.
set -uo pipefail

OUT="${1:?usage: proofs.sh <out-dir>}"
IMAGE="${CI_SELFTEST_IMAGE:-prf-backend:staging}"
TMO="${CI_PROOFS_TIMEOUT_S:-1800}"
DOCKER="${SELFTEST_DOCKER:-docker}"
mkdir -p "$OUT"
say() { printf '[proofs] %s\n' "$*"; }

if ! command -v "$DOCKER" >/dev/null 2>&1 || ! "$DOCKER" image inspect "$IMAGE" >/dev/null 2>&1; then
    say "the backend image $IMAGE is not on this daemon — proofs recorded 'not run'"
    printf '{"image": "%s", "ran": false, "why": "image absent", "claims": {}, "counts": {}, "red": []}\n' "$IMAGE" > "$OUT/results.json"
    exit 0
fi

ARGS=()
[ "${CI_PROOFS_NO_LEAN:-}" = 1 ] && ARGS+=(--no-lean)
ENV=()
[ -n "${PROOF_ENGINES_URL:-}" ] && ENV+=(-e "PROOF_ENGINES_URL=$PROOF_ENGINES_URL")
say "image $IMAGE · lean worker: ${PROOF_ENGINES_URL:-none named, the ladder decides} · timeout ${TMO}s"
rc=0
# the boot talks on stdout, so the results go to a file on a mounted volume — written as the HOST uid (never a
# root-owned artifact on the device), the sqlite DB in a throwaway /tmp HOME
OUT_ABS="$(cd "$OUT" && pwd)"
timeout "$TMO" "$DOCKER" run --rm --network host -u "$(id -u):$(id -g)" -e HOME=/tmp "${ENV[@]}" -v "$OUT_ABS:/out" \
    --entrypoint python3 "$IMAGE" tests/proofs_stage.py --out /out/results.json "${ARGS[@]}" \
    > "$OUT/proofs.log" 2>&1 || rc=$?
if [ "$rc" != 0 ] || ! python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$OUT/results.json" 2>/dev/null; then
    say "the stage did not complete (rc=$rc) — recorded, not thrown"
    printf '{"image": "%s", "ran": false, "why": "proofs_stage.py rc=%s", "claims": {}, "counts": {}, "red": []}\n' "$IMAGE" "$rc" > "$OUT/results.json"
    tail -20 "$OUT/proofs.log" 2>/dev/null
    exit 0
fi
grep '^\[proofs\]' "$OUT/proofs.log" | sed 's/^\[proofs\]/ /'
exit 0
