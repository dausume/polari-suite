#!/bin/bash
# os-security/escape-test.sh — attack OUR OWN confinement from inside a throwaway
# container that gets exactly what an app gets (the rendered profile, seccomp,
# cap_drop ALL, no-new-privileges, read-only rootfs), and expect every cross-over
# attempt to FAIL. This is the proof the plan asks for (§3); it runs after every
# apply and in the CI throwaway-isle test. Authorized use only: it targets the
# machine it runs on, with confinement we configured.
#   sudo bash escape-test.sh --scenario isle [--profile isle-app-prf-isle-backend] [--image alpine:3.20]
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SC=""; PROFILE=""; IMAGE="${OS_SEC_TEST_IMAGE:-alpine:3.20}"
while [ $# -gt 0 ]; do case "$1" in --scenario) SC="$2"; shift 2 ;; --profile) PROFILE="$2"; shift 2 ;; --image) IMAGE="$2"; shift 2 ;; *) shift ;; esac; done
[ -n "$SC" ] || { echo "usage: escape-test.sh --scenario <name> [--profile isle-app-<name>]" >&2; exit 1; }
OUT="$HERE/out/$SC"; [ -f "$OUT/manifest.json" ] || { echo "not rendered: $OUT" >&2; exit 1; }
[ -n "$PROFILE" ] || PROFILE=$(python3 -c "import json; m=json.load(open('$OUT/manifest.json')); x=(m['apps']+m['fixed']); print(x[0]['profile'] if x else '')")
[ -n "$PROFILE" ] || { echo "no profile rendered for $SC" >&2; exit 1; }
KIND=$(python3 -c "import json; m=json.load(open('$OUT/manifest.json')); print(next(x['kind'] for x in m['apps']+m['fixed'] if x['profile']=='$PROFILE'))")
aa-status 2>/dev/null | grep -q "$PROFILE" || { echo "profile $PROFILE is not loaded — apply first" >&2; exit 1; }
SECCOMP="/etc/polari/seccomp/$KIND.json"; [ -f "$SECCOMP" ] || SECCOMP="$OUT/seccomp/$KIND.json"
G="\033[0;32m"; R="\033[0;31m"; N="\033[0m"; PASS=0; FAIL=0
try() {  # label command… — the command must FAIL (non-zero) for the test to pass
    local label=$1; shift
    if docker run --rm --name os-sec-escape --security-opt "apparmor=$PROFILE" --security-opt "seccomp=$SECCOMP" --security-opt no-new-privileges \
        --cap-drop ALL --read-only --tmpfs /tmp --tmpfs /run --pids-limit 64 --network none \
        -v /var/run/docker.sock:/var/run/docker.sock:ro -v /etc:/host-etc:ro "$IMAGE" sh -c "$*" >/dev/null 2>&1; then
        echo -e "  ${R}ESCAPED${N}  $label"; FAIL=$((FAIL+1))
    else echo -e "  ${G}blocked${N}  $label"; PASS=$((PASS+1)); fi
}
echo "escape-test · $SC · profile $PROFILE · kind $KIND · image $IMAGE"
echo "  (the socket and /etc are mounted ON PURPOSE to prove the profile denies them even when present)"
try "read the docker socket"                 "test -r /var/run/docker.sock && (echo -e 'GET /version HTTP/1.0\r\n' | timeout 3 nc -U /var/run/docker.sock | grep -q Version)"
try "read the host's /etc/shadow via a bind" "cat /host-etc/shadow"
try "mount a tmpfs"                          "mount -t tmpfs none /mnt"
try "write /proc/sysrq-trigger"              "echo c > /proc/sysrq-trigger"
try "write kernel sysctl"                    "echo 1 > /proc/sys/kernel/sysrq"
try "load a kernel module (syscall)"         "python3 -c 'import ctypes; ctypes.CDLL(None).init_module(0,0,0)' || insmod /dev/null"
try "ptrace pid 1"                           "cat /proc/1/mem"
try "raw socket"                             "python3 -c 'import socket; socket.socket(socket.AF_INET, socket.SOCK_RAW, 1)'"
try "new user namespace (unshare -r)"        "unshare -r true"
try "write outside the declared paths"       "echo x > /usr/bin/pwned"
try "chroot escape helper"                   "mkdir -p /tmp/j && chroot /tmp/j /bin/true"
try "keyctl"                                 "python3 -c 'import ctypes; ctypes.CDLL(None).syscall(250, 0)'"
try "bpf syscall"                            "python3 -c 'import ctypes; ctypes.CDLL(None).syscall(321, 0, 0, 0)'"
try "read /sys/firmware"                     "ls /sys/firmware/efi/efivars"
docker rm -f os-sec-escape >/dev/null 2>&1 || true
echo; echo "  $PASS blocked, $FAIL escaped$([ "$FAIL" = 0 ] && echo ' — confinement holds' || echo ' — FIX BEFORE ANY EXPOSURE')"
[ "$FAIL" = 0 ]
