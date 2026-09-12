#!/bin/bash
# os-security/escape-test.sh — attack OUR OWN confinement from inside a throwaway
# container that gets exactly what an app gets (the rendered profile, seccomp,
# cap_drop ALL, no-new-privileges, read-only rootfs), and expect every cross-over
# attempt to FAIL. This is the proof the plan asks for (§3); it runs after every
# apply and in the CI throwaway-isle test. Authorized use only: it targets the
# machine it runs on, with confinement we configured.
#   sudo bash escape-test.sh --scenario isle [--profile isle-app-prf-isle-backend] [--image python:3.12-alpine]
# Verdicts per attempt: blocked (the command failed — confinement held), ESCAPED (it succeeded),
# HUNG (no answer within the time limit — counted as a failure of the TEST, fix the probe),
# skipped (the image lacks what the probe needs — never counted as blocked).
# The image must carry python3 for the syscall probes (raw socket, keyctl, bpf, the docker socket):
# the default is python:3.12-alpine; OS_SEC_TEST_IMAGE overrides. With a python-less image those
# probes are reported as skipped, not blocked (a lesson from 2026-09-12: on plain alpine they had
# "passed" because python3 was missing, and the socket probe's busybox nc hung forever).
# In COMPLAIN mode the profile denies nothing beyond stock docker, so several attempts WILL escape —
# that is the point of warn-only: the kernel logs each as ALLOWED and `allowed.py` lists them.
# Two passes: "full" = everything an app gets (the honest deployment shape); "mac-alone" (--alone) = ONLY the
# AppArmor profile, with the other rings deliberately off (seccomp unconfined, default capabilities, writable
# rootfs). The second pass is what proves the MAC ring contributes anything at all: on 2026-09-12 the full pass
# blocked 14/14 with ZERO AppArmor audit lines — every block came from cap_drop/seccomp/read-only, and the
# profile was never consulted. Run both; the mac-alone pass's escapes under complain are the profile's to-do list.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SC=""; PROFILE=""; IMAGE="${OS_SEC_TEST_IMAGE:-python:3.12-alpine}"; LIMIT="${OS_SEC_TEST_TIMEOUT:-60}"; ALONE=false; VERBOSE="${OS_SEC_TEST_VERBOSE:-0}"
while [ $# -gt 0 ]; do case "$1" in --scenario) SC="$2"; shift 2 ;; --profile) PROFILE="$2"; shift 2 ;; --image) IMAGE="$2"; shift 2 ;; --alone) ALONE=true; shift ;; --verbose|-v) VERBOSE=1; shift ;; *) shift ;; esac; done
[ -n "$SC" ] || { echo "usage: escape-test.sh --scenario <name> [--profile isle-app-<name>] [--image IMG]" >&2; exit 1; }
OUT="$HERE/out/$SC"; [ -f "$OUT/manifest.json" ] || { echo "not rendered: $OUT" >&2; exit 1; }
[ -n "$PROFILE" ] || PROFILE=$(python3 -c "import json; m=json.load(open('$OUT/manifest.json')); x=(m['apps']+m['fixed']); print(x[0]['profile'] if x else '')")
[ -n "$PROFILE" ] || { echo "no profile rendered for $SC" >&2; exit 1; }
KIND=$(python3 -c "import json; m=json.load(open('$OUT/manifest.json')); print(next(x['kind'] for x in m['apps']+m['fixed']+([m['node']] if m.get('node') else []) if x['profile']=='$PROFILE'))")
MODE=$(aa-status 2>/dev/null | sed -n '/complain mode/,/processes/p' | grep -q "^ *$PROFILE$" && echo complain || echo enforce)
aa-status 2>/dev/null | grep -q "$PROFILE" || { echo "profile $PROFILE is not loaded — apply first" >&2; exit 1; }
SECCOMP="/etc/polari/seccomp/$KIND.json"; [ -f "$SECCOMP" ] || SECCOMP="$OUT/seccomp/$KIND.json"
G="\033[0;32m"; R="\033[0;31m"; Y="\033[1;33m"; N="\033[0m"; PASS=0; FAIL=0; HUNG=0; SKIP=0
ERRF=$(mktemp); trap 'rm -f "$ERRF"' EXIT
docker image inspect "$IMAGE" >/dev/null 2>&1 || docker pull -q "$IMAGE" >/dev/null 2>&1 || { echo "cannot pull $IMAGE (offline? pass --image or OS_SEC_TEST_IMAGE)" >&2; exit 1; }
HAS_PY=false; docker run --rm --network none "$IMAGE" sh -c 'command -v python3' >/dev/null 2>&1 && HAS_PY=true
run_probe() {  # label needs-python command… — the command must FAIL (non-zero) for the test to pass
    local label=$1 needpy=$2; shift 2
    if [ "$needpy" = py ] && ! $HAS_PY; then echo -e "  ${Y}skipped${N}  $label (no python3 in $IMAGE)"; SKIP=$((SKIP+1)); return; fi
    docker rm -f os-sec-escape >/dev/null 2>&1 || true
    timeout --kill-after=5 "$LIMIT" docker run --rm --name os-sec-escape --security-opt "apparmor=$PROFILE" "${RINGS[@]}" --pids-limit 64 --network none \
        -v /var/run/docker.sock:/var/run/docker.sock:ro -v /etc:/host-etc:ro "$IMAGE" sh -c "$*" >/dev/null 2>"$ERRF"
    local rc=$?; local err; err=$(tail -1 "$ERRF" | cut -c1-110)
    if [ $rc = 124 ] || [ $rc = 137 ]; then echo -e "  ${Y}HUNG${N}     $label (no answer in ${LIMIT}s — the probe, not the confinement, is broken)"; HUNG=$((HUNG+1)); docker rm -f os-sec-escape >/dev/null 2>&1 || true
    elif [ $rc = 0 ]; then echo -e "  ${R}ESCAPED${N}  $label"; FAIL=$((FAIL+1))
    elif [ $rc = 127 ] || [ $rc = 126 ] || grep -qE "Error relocating|not found|No such file" "$ERRF"; then
        # the probe could not even run (the interpreter cannot start under this confinement, a path is absent):
        # that is not a block — it is a broken probe or a confinement that breaks the app itself. Count it as a failure of the test.
        echo -e "  ${Y}BROKEN${N}   $label  ← ${err:-exit $rc}"; HUNG=$((HUNG+1))
    else echo -e "  ${G}blocked${N}  $label$([ "$VERBOSE" = 1 ] && [ -n "$err" ] && echo "  ← $err")"; PASS=$((PASS+1)); fi
}
# syscall probes: EPERM/EACCES = blocked; any other errno means the call REACHED the kernel (escaped)
PY_SYSCALL='import ctypes,sys; l=ctypes.CDLL(None, use_errno=True); r=l.syscall(%s); e=ctypes.get_errno(); sys.exit(1 if (r<0 and e in (1,13)) else 0)'
if $ALONE; then RINGS=(--security-opt seccomp=unconfined --tmpfs /tmp --tmpfs /run); PASSNAME="mac-alone (AppArmor only: seccomp unconfined, default caps, writable rootfs)"
else RINGS=(--security-opt "seccomp=$SECCOMP" --security-opt no-new-privileges --cap-drop ALL --read-only --tmpfs /tmp --tmpfs /run); PASSNAME="full (profile + seccomp + cap_drop ALL + no-new-privileges + read-only)"; fi
echo "escape-test · $SC · profile $PROFILE ($MODE) · kind $KIND · image $IMAGE"
echo "  pass: $PASSNAME"
echo "  (the socket and /etc are mounted ON PURPOSE to prove the profile denies them even when present)"
run_probe "read the docker socket"                 py "python3 -c \"import socket; s=socket.socket(socket.AF_UNIX); s.settimeout(3); s.connect('/var/run/docker.sock'); s.sendall(b'GET /version HTTP/1.0\\r\\n\\r\\n'); d=s.recv(400); assert b'Version' in d or b'HTTP/1' in d\""
run_probe "read the host's /etc/shadow via a bind" sh "cat /host-etc/shadow"
run_probe "mount a tmpfs"                          sh "mount -t tmpfs none /mnt"
run_probe "write /proc/sysrq-trigger"              sh "echo c > /proc/sysrq-trigger"
run_probe "write kernel sysctl"                    sh "echo 1 > /proc/sys/kernel/sysrq"
run_probe "load a kernel module (syscall)"         py "python3 -c \"$(printf "$PY_SYSCALL" '175, 0, 0, 0')\""
run_probe "ptrace pid 1"                           sh "cat /proc/1/mem"
run_probe "raw socket"                             py "python3 -c 'import socket; socket.socket(socket.AF_INET, socket.SOCK_RAW, 1)'"
run_probe "new user namespace (unshare -r)"        sh "unshare -r true"
run_probe "write outside the declared paths"       sh "echo x > /usr/bin/pwned"
run_probe "chroot (CAP_SYS_CHROOT)"                sh "chroot / /bin/true"   # the capability check happens before the target matters; a bare chroot dir cannot run alpine's dynamic busybox
run_probe "keyctl (session keyring id)"            py "python3 -c \"$(printf "$PY_SYSCALL" '250, 0, -3, 0')\""
run_probe "bpf syscall"                            py "python3 -c \"$(printf "$PY_SYSCALL" '321, 0, 0, 0')\""
run_probe "see anything under /sys/firmware"       sh "[ \$(ls /sys/firmware/ 2>/dev/null | wc -l) -gt 0 ]"   # docker masks it as an empty dir; the profile denies it if ever unmasked
docker rm -f os-sec-escape >/dev/null 2>&1 || true
echo; echo "  $PASS blocked, $FAIL escaped, $HUNG hung/broken, $SKIP skipped$( [ "$FAIL" = 0 ] && [ "$HUNG" = 0 ] && [ "$SKIP" = 0 ] && echo ' — confinement holds' || { [ "$MODE" = complain ] && echo " — profile is in COMPLAIN mode: escapes are expected and logged (pol security os allowed --profile $PROFILE)" || echo ' — FIX BEFORE ANY EXPOSURE'; })"
[ "$FAIL" = 0 ] && [ "$HUNG" = 0 ] && [ "$SKIP" = 0 ]
