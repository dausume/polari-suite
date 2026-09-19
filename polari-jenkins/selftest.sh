#!/bin/bash
# polari-jenkins/selftest.sh — ci-7's own tests. They run WITHOUT docker,
# libvirt, sudo or network: the scripts are pointed at a temp tree and at
# PATH shims that answer for ssh / virsh / git / df, so every branch of the
# doctor's wording, the preflight's arithmetic, the tag minting and the
# route arming is exercised on this machine in under a second.
#
#   selftest.sh [-v] [--help]      → prints N/N and exits non-zero on a miss
set -euo pipefail

J="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERBOSE=0
case "${1:-}" in -v) VERBOSE=1 ;; --help|-h) sed -n '2,9p' "$0"; exit 0 ;; esac

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); [ "$VERBOSE" = 1 ] && printf '  ok   %s\n' "$1" || true; }
bad()  { FAIL=$((FAIL+1)); printf '  MISS %s\n     expected: %s\n     got: %s\n' "$1" "$2" "${3//$'\n'/ | }"; }
has()  { case "$3" in *"$2"*) ok "$1" ;; *) bad "$1" "…$2…" "$3" ;; esac; }
hasnt(){ case "$3" in *"$2"*) bad "$1" "NOT …$2…" "$3" ;; *) ok "$1" ;; esac; }
eq()   { [ "$2" = "$3" ] && ok "$1" || bad "$1" "$2" "$3"; }

# ---------------------------------------------------------------- the tree
DEV="$T/dev"; mkdir -p "$DEV"
cp -r "$J/device.sh" "$J/secrets.sh" "$J/doctor.sh" "$J/retention.sh" "$J/mint-tag.sh" \
      "$J/isle" "$J/routes" "$J/casc" "$J/docker-compose.yml" "$J/.env.example" "$J/device.env.example" "$DEV/"
mkdir -p "$DEV/pool" "$DEV/secrets/github" "$DEV/secrets/registries" "$T/bin" "$T/inv"
export CI_SECRETS_SYSTEM="$T/nonexistent-etc"   # force the repo posture in the sandbox
export CI_SECRETS_REPO="$DEV/secrets"

# ---------------------------------------------------------------- the shims
cat > "$T/bin/ssh" <<'SH'
#!/bin/bash
# a scripted target: the last argument is the command the caller asked for
CMD="${!#}"
[ "${FAKE_SSH_UP:-1}" = 1 ] || { echo "ssh: connect: Network is unreachable" >&2; exit 255; }
case "$CMD" in
  "echo reachable")            echo reachable ;;
  "echo ok")                   echo ok ;;
  "sudo -n true")              exit "${FAKE_SUDO_RC:-0}" ;;
  *"/dev/kvm"*)                exit "${FAKE_KVM_RC:-0}" ;;
  *nested*)                    printf '%s\n' "${FAKE_NESTED:-Y}" ;;
  *MemAvailable*)              printf '%s\n' "${FAKE_MEM_MB:-16384}" ;;
  *"df -BG"*)                  printf '%s\n' "${FAKE_DISK_GB:-500}" ;;
  *libvirt/images*)            printf '%s\n' "${FAKE_IMGDIR:-/var/lib/libvirt/images}" ;;
  *"command -v virt-install"*|*"command -v qemu-img"*|*"command -v virsh"*) exit "${FAKE_TOOLS_RC:-0}" ;;
  *cloud-localds*)             exit "${FAKE_TOOLS_RC:-0}" ;;
  *"virsh list"*)              printf '%s\n' "${FAKE_VMS:-}" ;;
  *polari-ci-inventory.sh*)    cat "${FAKE_INVENTORY:-/dev/null}" ;;
  *)                           exit 0 ;;
esac
SH
printf '#!/bin/bash\nexit 0\n' > "$T/bin/scp"
printf '#!/bin/bash\n[ "$1" = ls-remote ] && { printf "%%s" "$FAKE_TAGS"; exit 0; }\nexit 1\n' > "$T/bin/git"
chmod +x "$T/bin"/*
export PATH="$T/bin:$PATH"

# inventories
printf '{"docker":{"containers":[],"stacks":[],"images":[],"volumes":0},"debs":[],"units":[],"checkouts":[],"guests":[],"clis":{}}\n' > "$T/inv/clear.json"
printf '{"docker":{"containers":[{"name":"prf-backend","image":"prf-backend:staging","status":"Up"}],"stacks":["polari|6"],"images":[],"volumes":2},"debs":["polari-complete|1.0|ok"],"units":["isle-agent.service|loaded|active"],"checkouts":["/home/x/Isle-Mesh|dev|2G"],"guests":["isle-router"],"clis":{"pol":"/usr/local/bin/pol","isle":"/usr/local/bin/isle"},"etc_polari":true}\n' > "$T/inv/dirty.json"

dev_env() {  # dev_env KEY=VAL … → write device.env
    : > "$DEV/device.env"; for kv in "$@"; do printf '%s\n' "$kv" >> "$DEV/device.env"; done
}
# the footprint reader is the real inventory.sh path only as a presence check —
# on an ssh target the JSON comes back through the ssh shim (FAKE_INVENTORY).
: > "$T/inv/inventory.sh"
pf()  { ( cd "$DEV" && env FOOTPRINT_INVENTORY="$T/inv/inventory.sh" "$@" bash isle/preflight.sh --isle 2>&1 ) || true; }
doc() { ( cd "$DEV" && bash doctor.sh 2>&1 ) || true; }

echo "polari-jenkins selftest — no docker, no libvirt, no sudo, no network"

# ============================================================ 1. tag minting
echo "-- mint-tag: polari-vYYYY.MM.DD, .N for a second release the same day"
mint() { FAKE_TAGS="$1" bash "$DEV/mint-tag.sh" --date 2026.09.19 --remote fake 2>/dev/null; }
eq "no tag for the day → the base version"        "2026.09.19"   "$(mint '')"
eq "base exists → .2"                             "2026.09.19.2" "$(mint 'a	refs/tags/polari-v2026.09.19')"
eq "base and .2 exist → .3"                       "2026.09.19.3" "$(mint 'a	refs/tags/polari-v2026.09.19
b	refs/tags/polari-v2026.09.19.2')"
eq "a peeled ^{} ref is not counted twice"        "2026.09.19.4" "$(mint 'a	refs/tags/polari-v2026.09.19.3
b	refs/tags/polari-v2026.09.19.3^{}')"
eq "another day's tags are ignored"               "2026.09.19"   "$(mint 'a	refs/tags/polari-v2026.09.18.9')"
eq "no +sha in the minted version"                ""             "$(mint '' | grep '+' || true)"

# ======================================================== 2. route arming
echo "-- routes: ARMED vs DRY (secret absent) vs DRY (not in CI_ROUTES)"
mkdir -p "$T/pool"; printf '{"components":{"superproject":{"sha":"deadbee"}},"publishedTo":{}}' > "$T/pool/release.json"
armrun() { ( cd "$DEV/routes" && env -u GITHUB_TOKEN VERSION=1 POOL_DIR="$T/pool" ROUTE=github-release "$@" \
             bash -c 'source ./_lib.sh; ROUTE=github-release; arm GITHUB_TOKEN:github/github_token; echo "resolved=$DRY_RUN"' 2>&1 ) || true; }
has "auto + secret + in CI_ROUTES → ARMED"        "ARMED"                    "$(armrun CI_ROUTES=github-release GITHUB_TOKEN=x)"
has "  …and DRY_RUN resolves to 0"                "resolved=0"               "$(armrun CI_ROUTES=github-release GITHUB_TOKEN=x)"
has "auto + secret absent → DRY, naming it"       "DRY (secret github/github_token absent)" "$(armrun CI_ROUTES=github-release)"
has "auto + not in CI_ROUTES → DRY, saying so"    "DRY (not in CI_ROUTES)"   "$(armrun CI_ROUTES=ghcr GITHUB_TOKEN=x)"
has "  …a secret alone never arms a route"        "resolved=1"               "$(armrun CI_ROUTES=ghcr GITHUB_TOKEN=x)"
has "DRY_RUN=true forces render-only"             "DRY (DRY_RUN=true forced)" "$(armrun DRY_RUN=true CI_ROUTES=github-release GITHUB_TOKEN=x)"
has "DRY_RUN=false forces a real push"            "ARMED (DRY_RUN=false forced)" "$(armrun DRY_RUN=false CI_ROUTES=github-release)"
has "an unknown DRY_RUN is refused"               "is not auto|true|false"   "$(armrun DRY_RUN=maybe CI_ROUTES=github-release)"

# ========================================================== 3. preflight
echo "-- preflight: the arithmetic, and the device-is-clear reading"
dev_env CI_ISLE_TARGET=ssh CI_ISLE_SSH_HOST=fakebox CI_MIN_FREE_GB=1 CI_ISLE_NESTED=required \
        CI_ISLE_VM_RAM_GB=4 CI_ISLE_VM_DISK_GB=30 CI_MIN_RAM_HEADROOM_GB=1

OUT=$(pf FAKE_INVENTORY="$T/inv/clear.json")
has "a fit, clear ssh device is clear to run"     "clear to run"                    "$OUT"
hasnt "  …and nothing FAILs"                      "FAIL"                            "$OUT"
has "RAM row shows have vs floor"                 "free RAM on the target"          "$OUT"

OUT=$(pf FAKE_INVENTORY="$T/inv/clear.json" FAKE_MEM_MB=3072)
has "RAM below VM+headroom → FAIL"                "REFUSED"                         "$OUT"
has "  …and says how short it is"                 "short by"                        "$OUT"

OUT=$(pf FAKE_INVENTORY="$T/inv/clear.json" FAKE_DISK_GB=10)
has "disk below VM disk + floor → FAIL"           "REFUSED"                         "$OUT"

OUT=$(pf FAKE_INVENTORY="$T/inv/clear.json" FAKE_KVM_RC=1)
has "no /dev/kvm on the target → FAIL"            "/dev/kvm on the target"          "$OUT"
has "  …and refuses"                              "REFUSED"                         "$OUT"

OUT=$(pf FAKE_INVENTORY="$T/inv/clear.json" FAKE_NESTED=N)
has "nested=N with NESTED=required → FAIL"        "REFUSED"                         "$OUT"

OUT=$(pf FAKE_INVENTORY="$T/inv/clear.json" FAKE_TOOLS_RC=1)
has "no virt-install on the target → FAIL"        "virt-install on the target"      "$OUT"

OUT=$(pf FAKE_INVENTORY="$T/inv/clear.json" FAKE_VMS=polari-ci-isle)
has "a leftover VM of our name → FAIL"            "no VM named polari-ci-isle"      "$OUT"
has "  …and points at throwaway.sh down"          "did not clean up"                "$OUT"

OUT=$(pf FAKE_INVENTORY="$T/inv/dirty.json")
has "a real Polari install on an ssh target FAILs" "carries a real Polari"          "$OUT"
has "  …and lists what it found"                  "Found: debs:1"                   "$OUT"

OUT=$(pf FAKE_INVENTORY="$T/inv/clear.json" FAKE_SSH_UP=0)
has "an unreachable target FAILs first"           "target reachable"                "$OUT"
has "  …and does not pretend to know the rest"    "not reachable"                   "$OUT"

OUT=$(pf FAKE_INVENTORY="$T/inv/clear.json" FAKE_SUDO_RC=1)
has "no passwordless sudo on the target → FAIL"   "target sudo -n"                  "$OUT"

# exit code + json
( cd "$DEV" && env FOOTPRINT_INVENTORY="$T/inv/inventory.sh" FAKE_INVENTORY="$T/inv/clear.json" bash isle/preflight.sh --isle >/dev/null 2>&1 ) && RC=0 || RC=$?
eq "a clear device exits 0"                       "0"  "$RC"
( cd "$DEV" && env FOOTPRINT_INVENTORY="$T/inv/inventory.sh" FAKE_INVENTORY="$T/inv/dirty.json" bash isle/preflight.sh --isle >/dev/null 2>&1 ) && RC=0 || RC=$?
eq "a FAIL exits 4 (the resource guard)"          "4"  "$RC"
JS=$( cd "$DEV" && env FOOTPRINT_INVENTORY="$T/inv/inventory.sh" FAKE_INVENTORY="$T/inv/clear.json" bash isle/preflight.sh --isle --json 2>/dev/null || true )
eq "--json is valid json with a verdict"          "PASS" "$(printf '%s' "$JS" | python3 -c 'import json,sys; print(json.load(sys.stdin)["verdict"])' 2>/dev/null || echo parse-error)"
eq "--json carries every row"                     "1"    "$(printf '%s' "$JS" | python3 -c 'import json,sys; print(1 if len(json.load(sys.stdin)["rows"])>8 else 0)' 2>/dev/null || echo 0)"
has "the header says it is a resource guard"      "RESOURCE GUARD"  "$( cd "$DEV" && env FOOTPRINT_INVENTORY="$T/inv/inventory.sh" FAKE_INVENTORY="$T/inv/clear.json" bash isle/preflight.sh 2>&1 || true)"

# ============================================================ 4. doctor
echo "-- doctor: one WARN per misconfiguration, each naming the fix"
rm -f "$DEV/device.env"
has "device.env absent → WARN + how to write it" "pol jenkins target local"        "$(doc)"
dev_env CI_ISLE_TARGET=sideways
has "unknown target → WARN naming local/ssh"     "unknown target"                  "$(doc)"
dev_env CI_ISLE_TARGET=ssh CI_ISLE_SSH_HOST=
has "ssh target with no alias → WARN"            "with no alias"                   "$(doc)"
dev_env CI_ISLE_TARGET=local CI_ISLE_VM_RAM_GB=lots
has "a non-numeric size → WARN"                  "not a positive whole number"     "$(doc)"
dev_env CI_ISLE_TARGET=local CI_ROUTES=github-release,npm,wat
has "a PARKED route in CI_ROUTES → WARN"         "npm(PARKED)"                     "$(doc)"
has "an unknown route in CI_ROUTES → WARN"       "wat(unknown)"                    "$(doc)"
dev_env CI_ISLE_TARGET=local CI_ISLE_VM_DISK_GB=10
has "a too-small VM disk → WARN"                 "an isle install wants"           "$(doc)"
dev_env CI_ISLE_TARGET=local CI_EXECUTORS=4
has "more than one executor → WARN"              "overlaps builds"                 "$(doc)"

dev_env CI_ISLE_TARGET=local
has "(C) repo secrets posture → the loud WARN"   "readable by every process"       "$(doc)"
has "  …and names init-device as the fix"        "init-device"                     "$(doc)"
printf 'x' > "$DEV/secrets/github/github_token"; chmod 0644 "$DEV/secrets/github/github_token"
has "a secret that is not 0600 → WARN"           "not 0600"                        "$(doc)"
chmod 0600 "$DEV/secrets/github/github_token"
has "a present secret arms its route"            "route github-release       — ARMED" "$(doc)"
has "  …and a route with no secret stays DRY"    "route ghcr                 — DRY" "$(doc)"
rm -f "$DEV/secrets/github/github_token"

printf 'JENKINS_PORT=8080\nDOCKER_GID=424242\n' > "$DEV/.env"
has "DOCKER_GID that is not the docker group → WARN" "the docker group is"         "$(doc)"
rm -f "$DEV/.env"
has ".env absent → WARN"                         "pol jenkins up writes it"        "$(doc)"
has "casc numExecutors follows CI_EXECUTORS"     "casc follows CI_EXECUTORS"       "$(doc)"
sed -i 's/^      - "127\.0\.0\.1:/      - "/' "$DEV/docker-compose.yml"
has "a port not pinned to loopback → WARN"       "does not pin the port"           "$(doc)"
eq "the doctor never refuses (exit 0)"           "0"  "$( ( cd "$DEV" && bash doctor.sh >/dev/null 2>&1 ); echo $? )"
eq "--strict does refuse when something warns"   "1"  "$( ( cd "$DEV" && bash doctor.sh --strict >/dev/null 2>&1 ); echo $? )"
hasnt "no secret VALUE is ever printed"          "supersecretvalue"                "$(printf 'supersecretvalue' > "$DEV/secrets/github/github_token"; chmod 0600 "$DEV/secrets/github/github_token"; doc)"

echo
TOTAL=$((PASS+FAIL))
echo "$PASS/$TOTAL"
[ "$FAIL" = 0 ] || exit 1
