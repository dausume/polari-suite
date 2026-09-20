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
cp -r "$J/device.sh" "$J/secrets.sh" "$J/doctor.sh" "$J/retention.sh" "$J/mint-tag.sh" "$J/setup.sh" \
      "$J/cicd-sync.sh" \
      "$J/quiet.sh" "$J/promote.sh" "$J/verdict.py" "$J/test-wipe.sh" "$J/selftests.sh" "$J/pool.sh" \
      "$J/scan" "$J/scan-tools.lock" \
      "$J/cache.sh" "$J/cache-manifest.py" "$J/cache-proxies.sh" "$J/build-images.sh" \
      "$J/cache" "$J/docker-compose.proxies.yml" \
      "$J/setup" "$J/isle" "$J/routes" "$J/casc" "$J/docker-compose.yml" "$J/.env.example" "$J/device.env.example" \
      "$J/shell-verbs.json" "$DEV/"
mkdir -p "$DEV/pool" "$DEV/secrets/github" "$DEV/secrets/registries" "$T/bin" "$T/inv"
# the dialog helpers live in polari-cli; setup.sh looks for them beside the checkout
mkdir -p "$T/polari-cli/scripts/lib"
cp "$J/../polari-cli/scripts/lib/tui.sh" "$T/polari-cli/scripts/lib/tui.sh"
export POL_TUI_LIB="$T/polari-cli/scripts/lib/tui.sh" POL_TUI=plain
# a fake module catalogue for the CI_ISLE_STAGES validation
mkdir -p "$T/modules"/{household,gears,cntfet,security}
for m in household gears cntfet security; do printf '{"name":"%s"}\n' "$m" > "$T/modules/$m/polari-app.json"; done
export CI_MODULES_DIR="$T/modules"
export CI_SECRETS_SYSTEM="$T/nonexistent-etc"   # force the repo posture in the sandbox
export CI_SECRETS_REPO="$DEV/secrets"

# ---------------------------------------------------------------- the shims
cat > "$T/bin/ssh" <<'SH'
#!/bin/bash
# a scripted target: the last argument is the command the caller asked for
CMD="${!#}"
[ "${FAKE_SSH_UP:-1}" = 1 ] || { echo "ssh: connect: Network is unreachable" >&2; exit 255; }
case "$CMD" in
  # ci-10 probes, matched FIRST: both snippets mention paths the older patterns
  # below would otherwise claim (libvirt/images, virsh list).
  *"ci-10 residue probe"*)     printf '%s\n' "${FAKE_RESIDUE:-}" ;;
  *"ci-10 leak snapshot"*)     cat "${FAKE_SNAPSHOT:-/dev/null}" ;;
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
# ci-8: a scripted Polari core. FAKE_CORE=down refuses; FAKE_CORE=ok serves
# FAKE_CORE_JSON on a GET and captures the body of a POST into FAKE_CORE_POSTED.
cat > "$T/bin/curl" <<'SH'
#!/bin/bash
[ "${FAKE_CORE:-ok}" = down ] && exit 7
POST=0; QUIET=0
for a in "$@"; do
  [ "$a" = POST ] && POST=1
  [ "$a" = /dev/null ] && QUIET=1
done
if [ "$POST" = 1 ]; then cat >> "${FAKE_CORE_POSTED:-/dev/null}"; printf '\n'; echo '{"ok": true, "stored": {}}'; exit 0; fi
[ "$QUIET" = 1 ] && exit 0
cat "${FAKE_CORE_JSON:-/dev/null}"
SH
# the git shim. ci-12 needs two more readings than ci-7's tag minting did:
# `ls-remote origin refs/heads/<branch>` (the forest sha set) and the plumbing
# quiet.sh uses to enumerate submodule URLs — the latter is REAL git against a
# real .gitmodules, so it is passed through.
cat > "$T/bin/git" <<'SH'
#!/bin/bash
REAL=/usr/bin/git
case "$*" in
  *ls-remote*refs/heads/*)
      # FAKE_HEADS="branch=sha branch=sha" — one line per match, git's own shape
      for ref in ${@}; do case "$ref" in refs/heads/*) WANT="${ref#refs/heads/}" ;; esac; done
      for kv in ${FAKE_HEADS:-}; do
          [ "${kv%%=*}" = "$WANT" ] && printf '%s\trefs/heads/%s\n' "${kv#*=}" "$WANT"
      done
      exit 0 ;;
  *ls-remote*)  printf "%s" "$FAKE_TAGS"; exit 0 ;;
  *"remote get-url"*) printf 'https://example.invalid/polari-suite.git\n'; exit 0 ;;
  *config*--get-regexp*) [ -x "$REAL" ] && exec "$REAL" "$@"; exit 1 ;;
  *) exit 1 ;;
esac
SH
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
mkdir -p "$T/pool/isle-test"; printf '{"components":{"superproject":{"sha":"deadbee"}},"publishedTo":{}}' > "$T/pool/release.json"
# ci-12: the release rule gates every route on the TEST VERDICT recorded for the
# superproject sha this build is of (deadbee, above), so the arming cases need a
# passing verdict in a pool; the rule itself is section 6.
VPOOL="$T/vpool"; mkdir -p "$VPOOL/test/deadbee"
seedverdict() {  # seedverdict <verdict> [why] [passed-apps-json]
    python3 -c 'import json,sys
json.dump({"sha": "deadbee", "branch": "test", "verdict": sys.argv[2], "why": sys.argv[3],
           "built": True, "scans": {"totals": {}},
           "selftests": {"ran": True, "modules": {"core": "pass"}, "suites": 1, "passed": 1, "failed": 0},
           "isle": {"present": True, "core_ok": sys.argv[2] == "passed", "stages": 1,
                    "passed": json.loads(sys.argv[4]), "untested": [],
                    "uninstall": {"stage1": "clean" if sys.argv[2] == "passed" else "skipped"}}},
          open(sys.argv[1], "w"))' "$VPOOL/test/deadbee/verdict.json" "$1" "${2:-}" "${3:-[\"gears\"]}"
}
seedverdict passed ''
armrun() { ( cd "$DEV/routes" && env -u GITHUB_TOKEN VERSION=1 POOL_DIR="$T/pool" POLARI_POOL="$VPOOL" ROUTE=github-release "$@" \
             bash -c 'source ./_lib.sh; ROUTE=github-release; arm GITHUB_TOKEN:github/release_token; echo "resolved=$DRY_RUN"' 2>&1 ) || true; }
has "auto + secret + in CI_ROUTES → ARMED"        "ARMED"                    "$(armrun CI_ROUTES=github-release GITHUB_TOKEN=x)"
has "  …and DRY_RUN resolves to 0"                "resolved=0"               "$(armrun CI_ROUTES=github-release GITHUB_TOKEN=x)"
has "auto + secret absent → DRY, naming it"       "DRY (secret github/release_token absent)" "$(armrun CI_ROUTES=github-release)"
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
has "more than TWO executors → WARN (two is what the parent/child wait needs)" "lets unrelated builds overlap"                 "$(doc)"

dev_env CI_ISLE_TARGET=local
has "(C) repo secrets posture → the loud WARN"   "readable by every process"       "$(doc)"
has "  …and names init-device as the fix"        "init-device"                     "$(doc)"
printf 'x' > "$DEV/secrets/github/release_token"; chmod 0644 "$DEV/secrets/github/release_token"
has "a secret that is not 0600 → WARN"           "not 0600"                        "$(doc)"
chmod 0600 "$DEV/secrets/github/release_token"
has "a present secret arms its route"            "route github-release       — ARMED" "$(doc)"
has "  …and a route with no secret stays DRY"    "route ghcr                 — DRY" "$(doc)"
rm -f "$DEV/secrets/github/release_token"

printf 'JENKINS_PORT=8080\nDOCKER_GID=424242\n' > "$DEV/.env"
has "DOCKER_GID that is not the docker group → WARN" "the docker group is"         "$(doc)"
rm -f "$DEV/.env"
has ".env absent → WARN"                         "pol jenkins up writes it"        "$(doc)"
has "casc numExecutors follows CI_EXECUTORS"     "casc follows CI_EXECUTORS"       "$(doc)"
sed -i 's/^      - "127\.0\.0\.1:/      - "/' "$DEV/docker-compose.yml"
has "a port not pinned to loopback → WARN"       "does not pin the port"           "$(doc)"
eq "the doctor never refuses (exit 0)"           "0"  "$( ( cd "$DEV" && bash doctor.sh >/dev/null 2>&1 ); echo $? )"
eq "--strict does refuse when something warns"   "1"  "$( ( cd "$DEV" && bash doctor.sh --strict >/dev/null 2>&1 ); echo $? )"
hasnt "no secret VALUE is ever printed"          "supersecretvalue"                "$(printf 'supersecretvalue' > "$DEV/secrets/github/release_token"; chmod 0600 "$DEV/secrets/github/release_token"; doc)"

# ================================================== 5. the setup walkthrough
echo "-- setup: the role arithmetic, the where-to-get-it table, --report, idempotence"

# 5a. role fitting — pure arithmetic (ram_mb cpus free_gb kvm vmram vmdisk ctrl build head minfree)
fit() { ( source "$DEV/setup/steps/01-role.sh" >/dev/null 2>&1; setup_role_fit "$@" ) }
head_() { ( source "$DEV/setup/steps/01-role.sh" >/dev/null 2>&1; setup_role_headline "$@" ) }
eq "16 GB + KVM fits everything at once"  "yes" "$(fit 16384 4 200 1 4 30 2 3 1 20 | awk -F'\t' '$1=="isle-here"{print $2}')"
eq "7.5 GB fits controller + builds"      "yes" "$(fit 7680 4 200 1 4 30 2 3 1 20 | awk -F'\t' '$1=="builds"{print $2}')"
eq "  …but not a concurrent isle VM"      "no"  "$(fit 7680 4 200 1 4 30 2 3 1 20 | awk -F'\t' '$1=="isle-here"{print $2}')"
has "  …and says so in one sentence"      "not a concurrent isle VM" "$(head_ 7680 4 200 1 4 30 2 3 1 20)"
has "  …naming the ssh way out"           "pol jenkins target ssh"   "$(head_ 7680 4 200 1 4 30 2 3 1 20)"
eq "no /dev/kvm → no isle role at all"    "no"  "$(fit 65536 16 900 0 4 30 2 3 1 20 | awk -F'\t' '$1=="isle-only"{print $2}')"
has "  …and the reason is the missing KVM" "no /dev/kvm" "$(fit 65536 16 900 0 4 30 2 3 1 20)"
eq "4.5 GB can host the VM but not build" "yes" "$(fit 4608 2 200 1 3 30 2 3 1 20 | awk -F'\t' '$1=="isle-only"{print $2}')"
eq "  …builds do not fit there"           "no"  "$(fit 4608 2 200 1 3 30 2 3 1 20 | awk -F'\t' '$1=="builds"{print $2}')"
eq "too little disk → no isle here"       "no"  "$(fit 16384 4 10 1 4 30 2 3 1 20 | awk -F'\t' '$1=="isle-here"{print $2}')"
has "the headline carries RAM, vCPU, disk" "GB RAM, 4 vCPU, 200 GB free" "$(head_ 16384 4 200 1 4 30 2 3 1 20)"

# 5b. WHERE to get it — every secret an ACTIVE route needs must have a URL or a generate command
wtable() { ( source "$DEV/secrets.sh"; source "$DEV/setup/steps/04-secrets.sh"
             miss=""
             for r in $SECRETS_ACTIVE_ROUTES; do
               for s in $(secrets_route_requires "$r"); do
                 info="$(setup_secret_info "$s" 2>/dev/null)" || { miss="$miss $s(no-entry)"; continue; }
                 wh="$(printf '%s' "$info" | cut -f4)"; how="$(printf '%s' "$info" | cut -f5)"
                 case "$wh" in https://*) continue ;; esac
                 case "$how" in *gpg*|*ssh-keygen*|*cosign*|*"pol jenkins"*) continue ;; esac
                 miss="$miss $s(no-url-no-command)"
               done
             done
             printf '%s' "${miss# }" ) }
eq "every ACTIVE route's secret has a URL or a generate command" "" "$(wtable)"
sinfo() { ( source "$DEV/setup/steps/04-secrets.sh"; setup_secret_info "$1" | cut -f"$2" ) }
has "the RELEASE token names the fine-grained token page" "settings/personal-access-tokens" "$(sinfo github/release_token 4)"
has "  …and the exact permission"                    "Contents: Read and write"        "$(sinfo github/release_token 5)"
has "the REGISTRY token says CLASSIC + write:packages"       "write:packages"                  "$(sinfo github/registry_token 5)"
has "cosign is generated, not fetched"               "cosign generate-key-pair"        "$(sinfo signing/cosign_key 5)"
has "  …with a fallback for a host without cosign"   "ghcr.io/sigstore/cosign"         "$(sinfo signing/cosign_key 5)"
has "the apt key uses an .invalid address"           "apt@polari.invalid"              "$(sinfo signing/apt_signing_gpg 5)"
eq "  …and the apt route is marked BLOCKED"          "1"                               "$(sinfo signing/apt_signing_gpg 2)"
eq "  …so is the distribution host key"              "1"                               "$(sinfo ssh/distribution_host_key 2)"
has "the deploy key names the Deploy keys page"      "settings/keys"                   "$(sinfo github/github_ssh_key 4)"
hasnt "no secret VALUE can appear in the table"      "-----BEGIN"                      "$(sinfo signing/cosign_key 5)$(sinfo signing/apt_signing_gpg 5)"

# 5c. --report with no terminal: read-only, complete, and it writes the status file
dev_env CI_ISLE_TARGET=local CI_ISLE_STAGES=core
rm -f "$DEV/SETUP_STATUS.md"
RPT=$( cd "$DEV" && FOOTPRINT_INVENTORY="$T/inv/inventory.sh" bash setup.sh --report </dev/null 2>&1 || true )
has "--report runs without a terminal"            "READ-ONLY"                       "$RPT"
has "  …walks every step"                         "step 8/8"                        "$RPT"
has "  …ends with a to-do list"                   "still to do, in order"           "$RPT"
has "  …states the release rule"                  "THE RELEASE RULE"                "$RPT"
has "  …and a READY / NOT READY verdict"          "READY"                           "$RPT"
has "  …names where to get the github token"      "https://github.com/settings"     "$RPT"
has "  …counts the steps for pol jenkins status"  "of 8 complete"                   "$RPT"
eq "  …and writes SETUP_STATUS.md"                "1"   "$([ -f "$DEV/SETUP_STATUS.md" ] && echo 1 || echo 0)"
has "the status file carries the verdict"         "**verdict:"                      "$(cat "$DEV/SETUP_STATUS.md")"
has "  …and the step count pol jenkins status reads" "steps: "                      "$(cat "$DEV/SETUP_STATUS.md")"
hasnt "the report never prints a secret value"    "supersecretvalue"                "$RPT"

# 5d. idempotence — a second --report changes nothing but the file's timestamp line
cp "$DEV/device.env" "$T/device.env.before"
RPT2=$( cd "$DEV" && FOOTPRINT_INVENTORY="$T/inv/inventory.sh" bash setup.sh --report </dev/null 2>&1 || true )
eq "a second run changes no configuration"        "same" "$(cmp -s "$T/device.env.before" "$DEV/device.env" && echo same || echo changed)"
eq "  …and reports the same step count"           "$(printf '%s' "$RPT"  | sed -n 's/.*steps: \([0-9]*\) of.*/\1/p' | tail -1)" \
                                                  "$(printf '%s' "$RPT2" | sed -n 's/.*steps: \([0-9]*\) of.*/\1/p' | tail -1)"
# the skip path: every question answered 'no' must leave the device untouched
SKIP=$( cd "$DEV" && FOOTPRINT_INVENTORY="$T/inv/inventory.sh" bash setup.sh --step stages </dev/null 2>&1 || true )
eq "answering nothing leaves device.env alone"    "same" "$(cmp -s "$T/device.env.before" "$DEV/device.env" && echo same || echo changed)"
has "  …and says the stages were left as they are" "already: OK"                    "$SKIP"

# ======================================= 6. stages + the tested-only release rule
echo "-- stages: parsing, the twice/unknown/empty warnings, and what may be released"
st() { ( cd "$DEV" && CI_ISLE_STAGES="$1" bash -c 'source ./device.sh; stages_list' ) }
eq "the literal core is a stage with no apps"     ""            "$(st 'core')"
eq "  …and there is exactly one of it"            "1"           "$(st 'core' | wc -l | tr -d ' ')"
eq "';' separates stages"                         "3"           "$(st 'core; household; gears,cntfet' | wc -l | tr -d ' ')"
eq "',' separates apps inside a stage"            "gears cntfet" "$(st 'core; gears,cntfet' | sed -n 2p)"
eq "whitespace anywhere is ignored"               "gears cntfet" "$(st '  core ;  gears , cntfet  ' | sed -n 2p)"
eq "core named inside a stage is implicit"        "household"   "$(st 'core; core,household' | sed -n 2p)"
eq "an empty stage is an empty line, not dropped" "4"           "$(st 'core; household; ; gears' | wc -l | tr -d ' ')"

stwarn() { ( cd "$DEV" && CI_MODULES_DIR="$T/modules" CI_ISLE_STAGES="$1" bash -c 'source ./device.sh; device_validate_stages' ) }
has "an unknown app name → WARN naming it"        "nosuchapp"        "$(stwarn 'core; nosuchapp')"
has "  …and lists the known apps"                 "known apps:"      "$(stwarn 'core; nosuchapp')"
has "  …listing a real one among them"            "household"        "$(stwarn 'core; nosuchapp')"
has "an app in two stages → WARN 'tested twice'"  "tested twice"     "$(stwarn 'core; household; household')"
has "an empty stage → WARN"                       "empty stage"      "$(stwarn 'core; ; gears')"
has "no stage at all → FAIL" "no testing stage" "$( cd "$DEV" && bash -c 'source ./device.sh; CI_ISLE_STAGES=""; device_validate_stages' )"
has "core alone is OK"                            "|OK|"             "$(stwarn 'core' | tr '\n' '|')"
rend() { ( source "$DEV/setup/steps/06-stages.sh" >/dev/null 2>&1; printf '%s\n' "$1" | setup_stages_render ) }
eq "the stage builder renders the knob"           "core; household; gears,cntfet" "$(rend 'core
household
gears cntfet')"
eq "  …and an empty build is just core"           "core" "$(rend '')"

# THE RELEASE RULE, ci-12 shape: read by routes/_lib.sh from the TEST VERDICT
# recorded for this build's superproject sha. (The uninstall/core_ok coupling it
# used to do itself now happens once, inside verdict.py, where the verdict is
# computed — see the ci-12 section for those cases.)
gate() { ( cd "$DEV/routes" && env -u GITHUB_TOKEN VERSION=1 POOL_DIR="$T/pool" POLARI_POOL="$VPOOL" GITHUB_TOKEN=x CI_ROUTES=github-release \
           bash -c 'source ./_lib.sh; ROUTE=github-release; arm GITHUB_TOKEN:github/release_token' 2>&1 ) || true; }
mkdir -p "$T/pool/debs"; : > "$T/pool/debs/polari-complete_1_all.deb"
: > "$T/pool/debs/polari-app-household_1_all.deb"; : > "$T/pool/debs/polari-app-gears_1_all.deb"
seedverdict passed ''
has "a PASSED verdict + secret + CI_ROUTES → ARMED" "ARMED"                            "$(gate)"
has "  …an app that did not pass is held back"    "not released: untested/failed"      "$(gate)"
has "  …naming that app's deb"                    "polari-app-household_1_all.deb"     "$(gate)"
hasnt "  …and NOT the app that passed"            "polari-app-gears_1_all.deb (untested" "$(gate)"
seedverdict failed 'the isle stages did not record core_ok'
has "a FAILED verdict → DRY, whatever the secrets" "not passed"                        "$(gate)"
has "  …repeating the verdict's OWN reason, not a generic one" "did not record core_ok" "$(gate)"
seedverdict partial 'the install cycle inside the guest is still the marked ci-3 TODO'
has "a PARTIAL verdict → DRY too: it is not a pass" "'partial', not passed"            "$(gate)"
rm -f "$VPOOL/test/deadbee/verdict.json"
has "no verdict at all → DRY, naming why"         "no passed test run for deadbee"     "$(gate)"
has "  …and it says what to do: push to test first" "promote test"                     "$(gate)"
FORCED=$( cd "$DEV/routes" && env VERSION=1 POOL_DIR="$T/pool" POLARI_POOL="$VPOOL" GITHUB_TOKEN=x DRY_RUN=false CI_ROUTES=github-release \
          bash -c 'source ./_lib.sh; ROUTE=github-release; arm GITHUB_TOKEN:github/release_token' 2>&1 || true )
has "the rule is HARD: DRY_RUN=false cannot force it" "DRY (no passed test run"        "$FORCED"
seedverdict passed ''
assets() { ( cd "$DEV/routes" && env VERSION=1 POOL_DIR="$T/pool" POLARI_POOL="$VPOOL" bash -c 'source ./_lib.sh; release_assets "$POOL_DIR/debs"' 2>/dev/null ) || true; }
has "the core deb is always an asset"             "polari-complete_1_all.deb"          "$(assets)"
has "  …a passed app deb is an asset"             "polari-app-gears_1_all.deb"         "$(assets)"
hasnt "  …an untested app deb is not"             "polari-app-household"               "$(assets)"

# ============================= 7. ci-8: the two modes, and the sync with Polari
echo "-- modes: suite vs one app; and the sync — Polari holds the settings, device.env follows"

mv() { command mv "$@"; }
dv() { ( cd "$DEV" && bash -c 'source ./device.sh; device_validate' 2>&1 ) || true; }

dev_env CI_MODE=suite
has "CI_MODE=suite → the whole suite"             "the whole Polari suite"        "$(dv)"
dev_env CI_MODE=app CI_APP_NAME= CI_APP_REPO=
has "app mode with no app name → FAIL"            "names none"                    "$(dv)"
has "  …and with no repo → FAIL naming the module repo" "polari-module-"          "$(dv)"
dev_env CI_MODE=app CI_APP_NAME=household CI_APP_REPO=https://example.invalid/r.git
has "a complete app-mode device says which app"   "maintains ONE Polari app: household" "$(dv)"
has "  …and app mode defaults the stages to core + that app" "core; household"    "$( cd "$DEV" && bash -c 'source ./device.sh; echo "$CI_ISLE_STAGES"' )"
dev_env CI_MODE=app CI_APP_NAME=household CI_APP_REPO=x CI_ISLE_STAGES='core; household; gears'
has "app mode: another app is tested but never released here" "never released here" "$(dv)"
dev_env CI_MODE=app CI_APP_NAME=household CI_APP_REPO=x CI_ISLE_STAGES='core; gears'
has "app mode: no stage tests the app it maintains → WARN with the default" "core; household" "$(dv)"
dev_env CI_MODE=sideways
has "an unknown mode → WARN, read as suite"       "reading it as suite"           "$(dv)"
dev_env CI_MODE=suite CI_CORE_SOURCE=release:
has "core source release: with no tag → FAIL"     "release: with no tag"          "$(dv)"
dev_env CI_MODE=suite CI_CORE_SOURCE=somewhere
has "an unknown core source → FAIL naming both shapes" "release:<tag>"            "$(dv)"
dev_env CI_MODE=suite CI_CORE_SOURCE=build
has "core source build → the core is rebuilt here" "REBUILT"                      "$(dv)"

# --- the pull: Polari is the source of truth, device.env follows
mkdir -p "$DEV/secrets/polari"
printf 'the-posting-token' > "$DEV/secrets/polari/cicd_ingest_token"; chmod 0600 "$DEV/secrets/polari/cicd_ingest_token"
cat > "$T/core.json" <<'JSON'
{"ok": true, "device": "pipe-1", "mode": "app",
 "device_env": "CI_MODE=app\nCI_APP_NAME=household\nCI_APP_REPO=https://example.invalid/r.git\nCI_CORE_SOURCE=release:polari-v2026.09.19\nCI_ISLE_TARGET=ssh\nCI_ISLE_SSH_HOST=isle-core\nCI_ISLE_SSH_USER=\nCI_ISLE_VM_NAME=polari-ci-isle\nCI_ISLE_VM_RAM_GB=8\nCI_ISLE_VM_VCPUS=2\nCI_ISLE_VM_DISK_GB=40\nCI_ISLE_NESTED=auto\nCI_ISLE_POOL=\nCI_ISLE_IMAGE_URL=\nCI_MIN_FREE_GB=20\nCI_MIN_RAM_HEADROOM_GB=1\nCI_EXECUTORS=1\nCI_ROUTES=ghcr\nCI_ISLE_STAGES=core; household\n",
 "validation": [{"key": "CI_MODE", "value": "app", "status": "OK", "message": ""}]}
JSON
cat > "$T/core-bad.json" <<'JSON'
{"ok": true, "device": "pipe-1", "device_env": "CI_ISLE_TARGET=sideways\n",
 "validation": [{"key": "CI_ISLE_TARGET", "value": "sideways", "status": "FAIL", "message": "unknown target"}]}
JSON
sync_() { ( cd "$DEV" && env CICD_DEVICE_NAME=pipe-1 CI_SECRETS_SYSTEM="$T/nonexistent-etc" CI_SECRETS_REPO="$DEV/secrets" "$@" bash cicd-sync.sh "$SYNCCMD" 2>&1 ) || true; }

dev_env CI_MODE=suite CI_ISLE_TARGET=local CI_CORE_URL=http://127.0.0.1:9999
SYNCCMD=pull
OUT=$(sync_ FAKE_CORE=ok FAKE_CORE_JSON="$T/core.json")
has "pull rewrites device.env from the core"      "device.env rewritten"          "$OUT"
has "  …and the pulled settings are in force"     "CI_ISLE_VM_RAM_GB=8"           "$(cat "$DEV/device.env")"
has "  …including the mode keys"                  "CI_APP_NAME=household"         "$(cat "$DEV/device.env")"
has "  …and CI_CORE_URL survives (the core does not know its own address)" "CI_CORE_URL=http" "$(cat "$DEV/device.env")"
eq "  …the last pulled key is not run into by the appended one (the \$() newline trap)" \
   "core; household" "$( cd "$DEV" && bash -c 'source ./device.sh; echo "$CI_ISLE_STAGES"' )"
BEFORE=$(cat "$DEV/device.env")
OUT=$(sync_ FAKE_CORE=down)
has "a core that does not answer is NOT fatal"    "KEEPING the device.env"        "$OUT"
eq "  …and the file is left exactly as it was"    "same" "$([ "$BEFORE" = "$(cat "$DEV/device.env")" ] && echo same || echo changed)"
OUT=$(sync_ FAKE_CORE=ok FAKE_CORE_JSON="$T/core-bad.json")
has "a core answering settings that FAIL validation is refused, and the file kept" "KEEPING the device.env" "$OUT"
eq "  …the file is still the good one"            "same" "$([ "$BEFORE" = "$(cat "$DEV/device.env")" ] && echo same || echo changed)"
dev_env CI_MODE=suite CI_ISLE_TARGET=local
OUT=$(sync_ FAKE_CORE=ok FAKE_CORE_JSON="$T/core.json")
has "no CI_CORE_URL → this device.env is the only truth, said plainly" "only truth there is" "$OUT"

# --- the push: PRESENCE and readiness, never a value
dev_env CI_MODE=suite CI_ISLE_TARGET=local CI_CORE_URL=http://127.0.0.1:9999 CI_ROUTES=ghcr
printf 'supersecretvalue' > "$DEV/secrets/github/release_token"; chmod 0600 "$DEV/secrets/github/release_token"
SYNCCMD=push
: > "$T/posted.json"
OUT=$(sync_ FAKE_CORE=ok FAKE_CORE_POSTED="$T/posted.json")
has "push posts the device kind"                  '"kind": "device"'              "$(cat "$T/posted.json" 2>/dev/null)"
has "  …with the mode and the core source"        '"mode": "suite"'               "$(cat "$T/posted.json" 2>/dev/null)"
has "  …and the routes it can see a secret for"   '"armed"'                       "$(cat "$T/posted.json" 2>/dev/null)"
# ci-11a: a push also posts the WALKTHROUGH, so a browser with no desktop shell
# sees where this device got to (the core cannot run `pol`; only the device can).
has "  …and, since ci-11a, the setup walkthrough beside it"  '"kind": "setup"'     "$(cat "$T/posted.json" 2>/dev/null)"
has "    …declaring the protocol a front end must understand" '"setup_protocol": "polari-pipeline-setup/1"' "$(cat "$T/posted.json" 2>/dev/null)"
has "    …with the steps' sub-structures as JSON STRINGS (the mirror refuses a nested question, whose key is literally \`key\`)" \
    '"questions_json"' "$(cat "$T/posted.json" 2>/dev/null)"
hasnt "    …and NO secret value anywhere in what was posted" "supersecretvalue"    "$(cat "$T/posted.json" 2>/dev/null)"
SYNCCMD=push-setup
: > "$T/posted-setup.json"
OUT=$(sync_ FAKE_CORE=ok FAKE_CORE_POSTED="$T/posted-setup.json")
has "push-setup posts the walkthrough on its own"  '"kind": "setup"'               "$(cat "$T/posted-setup.json" 2>/dev/null)"
SYNCCMD=push-secrets
: > "$T/posted-secrets.json"
OUT=$(sync_ FAKE_CORE=ok FAKE_CORE_POSTED="$T/posted-secrets.json")
has "push-secrets posts the secrets kind"         '"kind": "secrets"'             "$(cat "$T/posted-secrets.json" 2>/dev/null)"
has "  …naming the secret and whether it is PRESENT" '"secret_name": "release_token"' "$(cat "$T/posted-secrets.json" 2>/dev/null)"
has "  …as a boolean"                             '"present": true'               "$(cat "$T/posted-secrets.json" 2>/dev/null)"
hasnt "  …and NEVER the value"                    "supersecretvalue"              "$(cat "$T/posted-secrets.json" 2>/dev/null)"
hasnt "  …not in the pushed device body either"   "supersecretvalue"              "$(cat "$T/posted.json" 2>/dev/null)"
hasnt "  …nor the posting token itself"           "the-posting-token"             "$(cat "$T/posted.json" 2>/dev/null)$(cat "$T/posted-secrets.json" 2>/dev/null)"
SYNCCMD=status
OUT=$(sync_ FAKE_CORE=ok FAKE_CORE_JSON="$T/core.json")
has "status names the credential by NAME only"    "polari/cicd_ingest_token"      "$OUT"
hasnt "  …and never prints it"                    "the-posting-token"             "$OUT"
rm -f "$DEV/secrets/github/release_token"

# ============================ 8. ci-9: the offline-first cache + app mode
echo "-- cache: the manifest, prune by last_used, the report arithmetic, the network fallback"

dev_env CI_ISLE_TARGET=local CI_CACHE=on
CACHE_ROOT="$DEV/pool/cache"
cachesh() { ( cd "$DEV" && env "$@" bash cache.sh "${CACHECMD[@]}" 2>&1 ) || true; }
cachefn() { ( cd "$DEV" && bash -c "source ./cache.sh; $1" 2>&1 ) || true; }

# --- the manifest: one record per entry, with the four fields the brief names
MAN="$T/MANIFEST.json"; mkdir -p "$T/area"; printf 'wheel-bytes' > "$T/area/pkg-1.0-py3-none-any.whl"
python3 "$DEV/cache-manifest.py" put "$MAN" pkg-1.0-py3-none-any.whl "$T/area/pkg-1.0-py3-none-any.whl" "a python wheel" >/dev/null
REC=$(python3 "$DEV/cache-manifest.py" get "$MAN" pkg-1.0-py3-none-any.whl)
has "a cache entry records what it is"            '"what": "a python wheel"'  "$REC"
has "  …its sha256"                               '"sha256"'                  "$REC"
has "  …when it was fetched"                      '"fetched"'                 "$REC"
has "  …and when it was last used"                '"last_used"'               "$REC"
eq  "  …and its size in bytes"                    "11" "$(printf '%s' "$REC" | python3 -c 'import json,sys; print(json.load(sys.stdin)["bytes"])')"
eq  "an entry nothing wrote is absent (exit 1)"   "1"  "$(python3 "$DEV/cache-manifest.py" get "$MAN" nope >/dev/null 2>&1; echo $?)"
eq  "list prints one line per entry"              "1"  "$(python3 "$DEV/cache-manifest.py" list "$MAN" | wc -l | tr -d ' ')"

# --- prune removes ONLY what is older than the knob, by last_used
printf 'old' > "$T/area/old-1.0.whl"; printf 'new' > "$T/area/new-1.0.whl"
python3 "$DEV/cache-manifest.py" put "$MAN" old-1.0.whl "$T/area/old-1.0.whl" "an old wheel" >/dev/null
python3 "$DEV/cache-manifest.py" put "$MAN" new-1.0.whl "$T/area/new-1.0.whl" "a fresh wheel" >/dev/null
python3 - "$MAN" <<'PY'
import json, sys, datetime
p = sys.argv[1]; d = json.load(open(p))
d['old-1.0.whl']['last_used'] = (datetime.datetime.now() - datetime.timedelta(days=90)).isoformat(timespec='seconds')
d['unreadable.whl'] = {'what': 'an entry with no usable stamp', 'sha256': '', 'bytes': 1, 'fetched': '', 'last_used': 'not-a-date'}
json.dump(d, open(p, 'w'), indent=1)
PY
PRUNED=$(python3 "$DEV/cache-manifest.py" prune "$MAN" "$T/area" 30)
has "cache-prune drops an entry unused for 90 days"   "dropped old-1.0.whl"   "$PRUNED"
has "  …and says how long it had gone unused"         "unused 9"              "$PRUNED"
eq  "  …the file is really gone"                      "gone" "$([ -f "$T/area/old-1.0.whl" ] && echo here || echo gone)"
eq  "  …a fresh entry is UNTOUCHED"                   "here" "$([ -f "$T/area/new-1.0.whl" ] && echo here || echo gone)"
has "  …and an entry with no readable last_used is KEPT, not guessed at" "1 kept (no readable last_used)" "$PRUNED"
hasnt "prune never touches an entry inside the window" "dropped new-1.0.whl"  "$PRUNED"

# --- retention.sh: `prune` must NEVER take the cache with an old pool version
mkdir -p "$DEV/pool/2026.09.01" "$DEV/pool/cache/wheels"
RET=$( cd "$DEV" && POLARI_POOL="$DEV/pool" POOL_KEEP=0 bash retention.sh prune 2>&1 || true )
has "retention.sh prune says the cache is EXEMPT"   "EXEMPT (never a version): cache"   "$RET"
eq  "  …and the cache directory survives it"        "here" "$([ -d "$DEV/pool/cache/wheels" ] && echo here || echo gone)"
hasnt "  …the cache is not listed as a pool version" "versions (newest first): cache" "$RET"
CP=$( cd "$DEV" && POLARI_POOL="$DEV/pool" bash retention.sh cache-prune --older-than 7 2>&1 || true )
has "retention.sh cache-prune is the cache's ONE deleter" "unused for more than 7 day(s)" "$CP"

# --- the report arithmetic
REP="$T/cache-report.json"
python3 "$DEV/cache-manifest.py" report "$REP" wheels 300000000 100000000 42 >/dev/null
python3 "$DEV/cache-manifest.py" report "$REP" apt    100000000 0         8  >/dev/null
SHOW=$(python3 "$DEV/cache-manifest.py" report-show "$REP")
eq "the hit rate is cached/(cached+fetched)" "0.8" "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["hit_rate"])' "$REP")"
eq "  …bytes accumulate across stages"       "400000000" "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["cached_bytes"])' "$REP")"
eq "  …and so do the seconds"                "50.0" "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["seconds"])' "$REP")"
has "report-show states the hit rate in words" "80% of the bytes this run needed came from the cache" "$SHOW"
has "  …with a TOTAL row"                      "TOTAL"  "$SHOW"
eq "a missing report is reported, not invented" "1" "$(python3 "$DEV/cache-manifest.py" report-show "$T/nope.json" >/dev/null 2>&1; echo $?)"

# --- the network fallback: an EMPTY cache must still build
eq "CI_CACHE=on offers the wheelhouse to pip" "--find-links $CACHE_ROOT/wheels" \
   "$( cd "$DEV" && bash -c 'source ./cache.sh; cache_wheel_args' )"
eq "  …CI_CACHE=off adds NOTHING — pip goes to the index exactly as before" "" \
   "$( cd "$DEV" && CI_CACHE=off bash -c 'source ./cache.sh; cache_wheel_args' )"
eq "  …and tier two's index is added only when PIP_INDEX_URL is set" \
   "--find-links $CACHE_ROOT/wheels --index-url http://127.0.0.1:3141/root/pypi/+simple/" \
   "$( cd "$DEV" && PIP_INDEX_URL=http://127.0.0.1:3141/root/pypi/+simple/ bash -c 'source ./cache.sh; cache_wheel_args' )"
eq "a cache MISS is a miss, not a refusal" "1" \
   "$( cd "$DEV" && bash -c 'source ./cache.sh; cache_hit wheels nothing-here.whl' >/dev/null 2>&1; echo $? )"
has "CI_CACHE=off says so and hands the build back to the network" "off (CI_CACHE=off)" \
   "$( cd "$DEV" && CI_CACHE=off bash -c 'source ./cache.sh; cache_fetch wheels x https://example.invalid/x' 2>&1 || true )"

# --- status
CACHECMD=(status)
OUT=$(cachesh CI_CACHE=on)
has "cache status names the directory"            "$CACHE_ROOT"        "$OUT"
has "  …and every area"                           "scanners"           "$OUT"
has "  …says what each area is for"               "Trivy DB"           "$OUT"
has "  …and is honest that the savings are EXPECTED until a real run" "EXPECTED, not measured" "$OUT"
OUT=$(cachesh CI_CACHE=off)
has "cache status with CI_CACHE=off says the cache is OFF" "THE CACHE IS OFF" "$OUT"

# --- tier two is OFF by default, and a pipeline never starts it
eq "tier two is off unless CI_CACHE_PROXIES=on" "1" \
   "$( cd "$DEV" && bash -c 'source ./cache.sh; cache_proxies_on' >/dev/null 2>&1; echo $? )"
eq "  …so the pipeline passes NO proxy build-args" "" \
   "$( cd "$DEV" && bash -c 'source ./cache.sh; cache_build_args' )"
PUP=$( cd "$DEV" && CI_CACHE_PROXIES=off bash cache-proxies.sh up 2>&1 || true )
has "  …and 'cache proxies up' REFUSES while the knob is off" "deliberately opt-in" "$PUP"
has "  …saying nothing was started"                     "Nothing was started" "$PUP"
has "the compose file states every licence it can"      "Apache-2.0"          "$(cat "$DEV/docker-compose.proxies.yml")"
has "  …and is honest about the one it cannot verify"   "NOT VERIFIED"        "$(cat "$DEV/docker-compose.proxies.yml")"
has "  …every proxy port is bound to loopback only"     "127.0.0.1:"          "$(cat "$DEV/docker-compose.proxies.yml")"
hasnt "  …and none is published on all interfaces"      $'\n      - "5000:' "$(cat "$DEV/docker-compose.proxies.yml")"

# --- the device knobs
dev_env CI_ISLE_TARGET=local CI_CACHE=maybe
has "an unknown CI_CACHE → WARN naming on or off" "unknown value"         "$(doc)"
dev_env CI_ISLE_TARGET=local CI_CACHE=off
has "CI_CACHE=off → WARN, not a refusal"          "re-downloads"          "$(doc)"
dev_env CI_ISLE_TARGET=local CI_CACHE_MAX_GB=lots
has "a non-numeric CI_CACHE_MAX_GB → WARN"        "not a positive whole number" "$(doc)"
dev_env CI_ISLE_TARGET=local CI_CACHE_PROXIES=on
has "CI_CACHE_PROXIES=on but nothing answers → WARN naming the fix" "none of them answers" "$( cd "$DEV" && FAKE_CORE=down bash doctor.sh 2>&1 || true )"
dev_env CI_ISLE_TARGET=local
has "the doctor reports the cache against its budget" "of a 40 GB budget"   "$(doc)"
has "  …and says the hit rate is not measured yet"    "EXPECTED, not measured" "$(doc)"

# ------------------------------------------- ci-9: app mode, end to end
echo "-- app mode: the setup question, the pulled core, and a release of ONE deb to YOUR routes"

# the mode question is the FIRST thing the walkthrough shows
dev_env CI_ISLE_TARGET=local CI_MODE=suite CI_ISLE_STAGES=core
RPT=$( cd "$DEV" && FOOTPRINT_INVENTORY="$T/inv/inventory.sh" bash setup.sh --report </dev/null 2>&1 || true )
has "step 1 asks what the pipeline MAINTAINS, before anything else" "step 1/8 — what this pipeline maintains" "$RPT"
has "  …and in suite mode says the whole suite is built here" "maintains: the whole Polari suite" "$RPT"
dev_env CI_ISLE_TARGET=local CI_MODE=app CI_APP_NAME=household CI_APP_REPO=https://example.invalid/r.git \
        CI_ROUTE_TARGET=some-developer CI_ISLE_STAGES='core; household'
RPT=$( cd "$DEV" && FOOTPRINT_INVENTORY="$T/inv/inventory.sh" bash setup.sh --report </dev/null 2>&1 || true )
has "in app mode step 1 names the one app"            "maintains: ONE Polari app — household" "$RPT"
has "  …its repository"                               "repository: https://example.invalid/r.git" "$RPT"
has "  …the core it is tested against"                "core: release:latest" "$RPT"
has "  …and where ITS releases go"                    "releases go to: some-developer" "$RPT"
dev_env CI_ISLE_TARGET=local CI_MODE=app CI_APP_NAME=household CI_APP_REPO=x CI_CORE_SOURCE=build
has "CI_CORE_SOURCE=build in app mode is an INFO, not a refusal" "tested against that build, not an official release" "$(doc)"
dev_env CI_ISLE_TARGET=local CI_MODE=app CI_APP_NAME=household CI_APP_REPO=
has "app mode with no repo → the doctor WARNs" "nothing to build it from" "$(doc)"
dev_env CI_ISLE_TARGET=local CI_MODE=app CI_APP_NAME=household CI_APP_REPO=x CI_ROUTE_TARGET=dausume
has "CI_ROUTE_TARGET = the upstream owner → refused in the device settings too" "UPSTREAM owner" "$(doc)"

# core-artifacts.sh resolve, against a fixture release list (the curl shim answers)
cat > "$T/releases.json" <<'JSON'
[{"tag_name": "polari-v2026.09.19", "draft": false, "published_at": "2026-09-19T00:00:00Z",
  "assets": [{"name": "polari-complete_1_all.deb", "browser_download_url": "https://example.invalid/a.deb"},
             {"name": "SHA256SUMS", "browser_download_url": "https://example.invalid/SHA256SUMS"}]},
 {"tag_name": "polari-v2026.09.10", "draft": false, "published_at": "2026-09-10T00:00:00Z",
  "assets": [{"name": "polari-complete_0_all.deb", "browser_download_url": "https://example.invalid/b.deb"}]},
 {"tag_name": "polari-v2026.09.20-noassets", "draft": false, "published_at": "2026-09-20T00:00:00Z",
  "assets": []}]
JSON
cat > "$T/release-one.json" <<'JSON'
{"tag_name": "polari-v2026.09.19",
 "assets": [{"name": "polari-complete_1_all.deb", "browser_download_url": "https://example.invalid/a.deb"},
            {"name": "SHA256SUMS", "browser_download_url": "https://example.invalid/SHA256SUMS"}]}
JSON
mkdir -p "$T/polari-cli/scripts/lib"
cp "$J/../polari-cli/scripts/lib/providers.sh" "$T/polari-cli/scripts/lib/providers.sh"
ca() { ( cd "$DEV" && env POLARI_PROVIDERS_LIB="$T/polari-cli/scripts/lib/providers.sh" "$@" bash isle/core-artifacts.sh "$CACMD" 2>&1 ) || true; }
dev_env CI_ISLE_TARGET=local CI_MODE=app CI_APP_NAME=household CI_APP_REPO=x CI_ROUTE_TARGET=some-developer \
        CI_CORE_SOURCE=release:latest
CACMD=resolve
eq "release:latest resolves to the newest release that CARRIES debs" "polari-v2026.09.19" \
   "$(ca FAKE_CORE=ok FAKE_CORE_JSON="$T/releases.json" | tail -1)"
dev_env CI_ISLE_TARGET=local CI_MODE=app CI_APP_NAME=household CI_APP_REPO=x CI_ROUTE_TARGET=some-developer \
        CI_CORE_SOURCE=release:polari-v2026.09.19
eq "  …and an exact tag resolves to itself, verified to carry debs" "polari-v2026.09.19" \
   "$(ca FAKE_CORE=ok FAKE_CORE_JSON="$T/release-one.json" | tail -1)"
dev_env CI_ISLE_TARGET=local CI_MODE=app CI_APP_NAME=household CI_APP_REPO=x CI_ROUTE_TARGET=some-developer \
        CI_CORE_SOURCE=release:polari-v1999.01.01
printf '{"assets": []}' > "$T/release-none.json"
has "  …a tag with no debs is a REFUSAL naming the tag" "polari-v1999.01.01" \
   "$(ca FAKE_CORE=ok FAKE_CORE_JSON="$T/release-none.json")"
has "  …and never silently falls back to building core" "does not exist, or carries no .deb" \
   "$(ca FAKE_CORE=ok FAKE_CORE_JSON="$T/release-none.json")"
dev_env CI_ISLE_TARGET=local CI_MODE=app CI_APP_NAME=household CI_APP_REPO=x CI_ROUTE_TARGET=some-developer \
        CI_CORE_SOURCE=build
eq "CI_CORE_SOURCE=build resolves to the literal 'build'" "build" "$(ca FAKE_CORE=ok | tail -1)"
CACMD=fetch
has "  …and 'fetch' then has nothing to fetch, and says why" "nothing to fetch" "$(ca FAKE_CORE=ok)"

# app-mode release filtering: ONE deb, to YOUR routes
: > "$T/pool/debs/polari-app-household_1_all.deb"
seedverdict passed '' '["household","gears"]'
appassets() { ( cd "$DEV/routes" && env VERSION=1 POOL_DIR="$T/pool" POLARI_POOL="$VPOOL" "$@" \
                bash -c 'source ./_lib.sh; release_assets "$POOL_DIR/debs"' 2>/dev/null ) || true; }
OUT=$(appassets CI_MODE=app CI_APP_NAME=household CI_ROUTE_TARGET=some-developer)
has "app mode releases the app's own deb"          "polari-app-household_1_all.deb" "$OUT"
hasnt "  …and NOT the core it was tested against"  "polari-complete"                "$OUT"
hasnt "  …nor another app a stage happened to test here" "polari-app-gears"         "$OUT"
apparm() { ( cd "$DEV/routes" && env VERSION=1 POOL_DIR="$T/pool" GITHUB_TOKEN=x CI_ROUTES=github-release "$@" \
             bash -c 'source ./_lib.sh; ROUTE=github-release; arm GITHUB_TOKEN:github/release_token' 2>&1 ) || true; }
has "app mode names the one deb and the target it goes to" "releasing ONLY polari-app-household to some-developer" \
    "$(apparm CI_MODE=app CI_APP_NAME=household CI_ROUTE_TARGET=some-developer)"
has "  …and says the core is NOT re-released"      "is NOT re-released" \
    "$(apparm CI_MODE=app CI_APP_NAME=household CI_ROUTE_TARGET=some-developer)"
has "an app-mode route with no CI_ROUTE_TARGET is DRY, naming why" "CI_ROUTE_TARGET is empty" \
    "$(apparm CI_MODE=app CI_APP_NAME=household)"
has "an app-mode route aimed at the UPSTREAM owner is DRY — a fork is never republished upstream" \
    "never republished under an upstream name" "$(apparm CI_MODE=app CI_APP_NAME=household CI_ROUTE_TARGET=dausume)"
has "  …and DRY_RUN=false cannot force THAT either" "DRY (CI_ROUTE_TARGET is the UPSTREAM owner" \
    "$(apparm CI_MODE=app CI_APP_NAME=household CI_ROUTE_TARGET=dausume DRY_RUN=false)"
hasnt "suite mode is unaffected by any of it"      "app mode:" "$(apparm CI_MODE=suite)"

# tested_against: a release record that does not name its core is an unfalsifiable claim
printf '{"polari":"1","mode":"app","appName":"household","routeTarget":"some-developer","testedAgainst":"polari-v2026.09.19","publishedTo":{},"cacheReport":{"hit_rate":0.8}}' > "$T/pool/release.json"
dev_env CI_ISLE_TARGET=local CI_MODE=app CI_APP_NAME=household CI_APP_REPO=x CI_ROUTE_TARGET=some-developer CI_CORE_URL=http://127.0.0.1:9999
SYNCCMD=release
OUT=$( cd "$DEV" && env CICD_DEVICE_NAME=pipe-1 CI_SECRETS_SYSTEM="$T/nonexistent-etc" CI_SECRETS_REPO="$DEV/secrets" \
       FAKE_CORE=ok FAKE_CORE_POSTED="$T/posted-release.json" bash cicd-sync.sh release 1 "$T/pool/release.json" 2>&1 || true )
POSTED=$(cat "$T/posted-release.json" 2>/dev/null)
has "the release mirror carries the RESOLVED core it was tested against" '"tested_against": "polari-v2026.09.19"' "$POSTED"
has "  …the target it published to"                                     '"route_target": "some-developer"'        "$POSTED"
has "  …and the cache arithmetic of the build that made it"             '"cache_report"'                          "$POSTED"

# the two Dockerfiles: the offline path must be OPTIONAL
BE="$J/../polari-rf-node/polari-framework/Dockerfile"
FE="$J/../polari-rf-node/polari-platform-angular/Dockerfile.prod"
has "the backend declares a DEFAULT for the wheels build-context" "FROM scratch AS wheels" "$(cat "$BE")"
has "  …so a plain docker build with no --build-context still works" "EMPTY directory" "$(cat "$BE")"
has "  …and keeps the pip cache mount"        "type=cache,target=/root/.cache/pip"  "$(cat "$BE")"
has "  …with PIP_INDEX_URL honoured when set" "ARG PIP_INDEX_URL="                  "$(cat "$BE")"
has "the frontend caches npm across builds"   "type=cache,target=/root/.npm"        "$(cat "$FE")"
has "  …prefers what it already has"          "--prefer-offline"                    "$(cat "$FE")"
has "  …and honours a registry when one is passed" "ARG NPM_CONFIG_REGISTRY="       "$(cat "$FE")"
eq  "the syntax directive is the FIRST line of the frontend Dockerfile" "# syntax=docker/dockerfile:1" "$(head -1 "$FE")"
eq  "  …and of the backend's"                                          "# syntax=docker/dockerfile:1" "$(head -1 "$BE")"


# ==================== 9. ci-10: the teardown — the product's uninstall, our wipe, the leak diff
echo "-- ci-10: wipe scoping, the leak diff, the uninstall verdicts, and what each one gates"

# a scripted libvirt, kept OUT of the default PATH so the doctor still reads
# this machine as it really is (no virsh). Prepended only for the wipe cases.
mkdir -p "$T/vbin"
cat > "$T/vbin/virsh" <<'SH'
#!/bin/bash
A="$*"
case "$A" in
  *"net-list"*)           printf '%s\n' ${FAKE_NETS:-} ;;   # BEFORE `list --all --name` — it contains it
  *"list --all --name"*)  printf '%s\n' ${FAKE_DOMAINS:-} ;;
  *"pool-list"*)          echo default ;;
  *"vol-list"*)           printf '%s\n' ${FAKE_VOLS:-} ;;
  *domstate*)             echo "${FAKE_DOMSTATE:-shut off}" ;;
  *dominfo*)              exit "${FAKE_DOMINFO_RC:-1}" ;;   # 1 = the domain is gone (undefine took)
  *)                      echo "$A" >> "${VIRSH_LOG:-/dev/null}" ;;
esac
exit 0
SH
chmod +x "$T/vbin/virsh"

W="$T/wipe"
wipeset() {   # a fresh target: one of ours, one that is NOT ours, and a cached base image
    rm -rf "$W"; mkdir -p "$W/images" "$W/pool/ci-isle/polari-ci-isle" "$W/pool/cache/cloud"
    printf 'ours'   > "$W/images/polari-ci-isle-overlay.qcow2"
    printf 'theirs' > "$W/images/customer-vm.qcow2"
    printf 'seed'   > "$W/pool/ci-isle/polari-ci-isle/seed.iso"
    printf 'base-image-bytes' > "$W/pool/cache/cloud/ubuntu-24.04.img"
}
wipe() {   # wipe [--dry-run]  — the real throwaway.sh verb, against the tree above
    ( cd "$DEV" && PATH="$T/vbin:$PATH" env CI_ISLE_TARGET=local CI_ISLE_POOL="$W/pool" \
        CI_CACHE_DIR="$W/pool/cache" CI_WIPE_IMAGE_DIRS="$W/images" \
        bash isle/throwaway.sh wipe "$@" 2>&1 ) || true
}

wipeset
OUT=$(wipe)
has "wipe removes OUR overlay disk"                  "removed  disk $W/images/polari-ci-isle-overlay.qcow2" "$OUT"
has "  …and the per-run tree under the pool"         "polari-ci-isle"                                       "$OUT"
hasnt "wipe does NOT remove a disk that is not ours" "removed  disk $W/images/customer-vm.qcow2"            "$OUT"
has "  …it NAMES it under 'found but NOT removed'"   "customer-vm.qcow2"                                    "$OUT"
has "  …and says why it left it"                     "no 'polari-ci-' tag"                                  "$OUT"
eq  "  …the untouched disk is still on disk"         "here" "$([ -f "$W/images/customer-vm.qcow2" ] && echo here || echo gone)"
eq  "  …ours is really gone"                         "gone" "$([ -f "$W/images/polari-ci-isle-overlay.qcow2" ] && echo here || echo gone)"
eq  "the offline cache survives the wipe"            "here" "$([ -f "$W/pool/cache/cloud/ubuntu-24.04.img" ] && echo here || echo gone)"
has "  …and the wipe says the cache is EXCLUDED"     "is EXCLUDED by design"                                "$OUT"

OUT=$(wipe)
has "a second wipe finds nothing (idempotent)"       "removed: nothing"                                     "$OUT"
has "  …and says so in his words"                    "no residue of this pipeline"                          "$OUT"

wipeset
OUT=$(wipe --dry-run)
has "--dry-run lists instead of removing"            "would remove"                                         "$OUT"
has "  …and says nothing was removed"                "DRY RUN — nothing is removed"                         "$OUT"
eq  "  …our disk is STILL there after a dry run"     "here" "$([ -f "$W/images/polari-ci-isle-overlay.qcow2" ] && echo here || echo gone)"

wipeset
OUT=$(FAKE_DOMAINS="polari-ci-isle customer-vm" FAKE_NETS="default polari-ci-net" FAKE_VOLS="polari-ci-disk customer-disk" wipe)
has "a VM carrying the tag is destroyed"             "removed  VM polari-ci-isle"                           "$OUT"
hasnt "  …a VM that is not ours is NOT"              "removed  VM customer-vm"                              "$OUT"
has "  …and it is named as left alone"               "VM customer-vm (not ours"                             "$OUT"
has "a per-run libvirt network is removed"           "removed  network polari-ci-net"                       "$OUT"
hasnt "  …libvirt's own 'default' network is not"    "removed  network default"                             "$OUT"
has "a storage volume carrying the tag is removed"   "removed  volume polari-ci-disk"                       "$OUT"
hasnt "  …one that is not ours is not"               "removed  volume customer-disk"                        "$OUT"

# the PROTECTED paths — found live on isle-core 2026-09-19, where the /tmp and
# /var/tmp tag globs matched the POOL (which holds the cache) and the very
# directory the wipe had been scp'd into. Neither is inside the cache, so the
# cache exclusion alone did not save them.
prot() { ( set +u; cd /; POOL="$1"; CI_CACHE_DIR=""; HERE="$2"; CI_ISLE_VM_NAME=polari-ci-isle
           source "$DEV/isle/wipe.sh"; _protected "$3" && echo protected || echo removable ) }
eq "the POOL itself is protected — it holds the offline cache" "protected" \
   "$(prot /var/tmp/polari-ci-pool /x /var/tmp/polari-ci-pool)"
eq "  …so is the directory the wipe is running from (it would rm -rf its own cwd)" "protected" \
   "$(prot /p /tmp/polari-ci-isle.42 /tmp/polari-ci-isle.42)"
eq "  …and the cache root itself"                             "protected" \
   "$(prot /p /x /p/cache)"
eq "a per-run overlay under the pool is still removable"      "removable" \
   "$(prot /var/tmp/polari-ci-pool /x /var/tmp/polari-ci-pool/ci-isle/polari-ci-isle)"

# ------------------------------------------------- the leak diff, on a REAL local target
LP="$T/leak"; mkdir -p "$LP/pool/isle-test" "$LP/pool/ci-isle" "$LP/pool/cache/cloud"
printf 'base-image' > "$LP/pool/cache/cloud/ubuntu.img"
printf 'a result'   > "$LP/pool/ci-isle/keepme.txt"
lc() { ( cd "$DEV" && env CI_ISLE_TARGET=local CI_ISLE_POOL="$LP/pool" CI_CACHE_DIR="$LP/pool/cache" \
         CI_LEAK_DIR="$LP/pool/isle-test" FOOTPRINT_INVENTORY="$T/inv/inventory.sh" \
         bash isle/leakcheck.sh "${LCCMD[@]}" 2>&1 ); }
LCCMD=(baseline); OUT=$(lc || true)
has "leakcheck baseline is taken before the first stage" "leak baseline taken BEFORE the first stage"        "$OUT"
has "  …and says the cache is EXCLUDED"                  "EXCLUDED: $LP/pool/cache"                          "$OUT"
BASEJ="$LP/pool/isle-test/leak-baseline.json"
hasnt "the baseline does NOT count the cached base image" "ubuntu.img"                                       "$(cat "$BASEJ")"
has "  …but does count a file under the pool run dir"     "keepme.txt"                                       "$(cat "$BASEJ")"
has "  …and records the memory it must come back to"      "mem_available_mb"                                 "$(cat "$BASEJ")"

LCCMD=(check --stage 1); OUT=$(lc || true)
has "an unchanged target is CLEAN"                       "CLEAN: nothing new survived the wipe"              "$OUT"
eq  "  …exit 0"                                          "0" "$( LCCMD=(check --stage 1); lc >/dev/null 2>&1; echo $? )"

printf 'an overlay that should not be here' > "$LP/pool/ci-isle/polari-ci-isle.qcow2"
LCCMD=(check --stage 2); OUT=$(lc || true)
has "a NEW file that survived the wipe is a LEAK"        "polari-ci-isle.qcow2"                               "$OUT"
has "  …and the run is reported as LEAKED"               "LEAKED:"                                            "$OUT"
has "  …pointing at the wipe, and at the next stage"     "would start on a dirty host"                        "$OUT"
eq  "  …exit 5"                                          "5" "$( LCCMD=(check --stage 2); lc >/dev/null 2>&1; echo $? )"
rm -f "$LP/pool/ci-isle/polari-ci-isle.qcow2"

rm -f "$LP/pool/ci-isle/keepme.txt"
LCCMD=(check --stage 3); OUT=$(lc || true)
has "a thing that is GONE is never a leak"               "CLEAN"                                              "$OUT"
printf 'a result' > "$LP/pool/ci-isle/keepme.txt"

printf 'x' > "$LP/pool/cache/cloud/another-base.img"
LCCMD=(check --stage 4); OUT=$(lc || true)
has "a file APPEARING in the cache is not a leak"        "CLEAN"                                              "$OUT"
hasnt "  …it is not even counted"                        "another-base.img"                                   "$OUT"

LCCMD=(report --stage 4); OUT=$(lc || true)
has "leakcheck report prints the table his ask names"    "kind"                                               "$OUT"
has "  …with the tolerances stated"                      "tolerances: RAM 512 MB, disk 1024 MB"               "$OUT"
has "  …and the exclusion, every time"                   "EXCLUDED:"                                          "$OUT"
has "  …naming the memory question in words"             "did the RAM come back"                              "$OUT"

# the RAM/disk arithmetic, driven through the real diff with fabricated readings
mkjson() { python3 -c 'import json,sys; json.dump({"kind":"leak-snapshot","at":"t","target":"x","vm":"polari-ci-isle","items":{},"numbers":{"mem_available_mb":int(sys.argv[2]),"disk_free_images_mb":int(sys.argv[3]),"disk_free_root_mb":9000,"swap_used_mb":0},"strings":{}}, open(sys.argv[1],"w"))' "$@"; }
mkdir -p "$T/diff"
mkjson "$T/diff/base.json"  16000 500000
mkjson "$T/diff/ram.json"   15000 500000
mkjson "$T/diff/near.json"  15900 500000
mkjson "$T/diff/disk.json"  16000 400000
dfv() {  # dfv <now.json>  → the verdict the real _diff gives
    ( cd "$DEV" && bash -c 'source ./isle/leakcheck.sh 2>/dev/null; true' >/dev/null 2>&1
      sed -n '/^_diff()/,/^}/p' "$DEV/isle/leakcheck.sh" > "$T/diff/fn.sh"
      source "$T/diff/fn.sh"
      _diff "$T/diff/base.json" "$1" "$T/diff/out.json" 1 512 1024 "$T/diff/cache" ) 2>&1
}
has "RAM 1000 MB below the baseline is a LEAK (memory that did not come back)" "leaked" "$(dfv "$T/diff/ram.json")"
has "  …100 MB below it is within the tolerance"         "clean"                                              "$(dfv "$T/diff/near.json")"
has "disk 100 GB below the baseline is a LEAK"           "leaked"                                             "$(dfv "$T/diff/disk.json")"
eq  "  …and the deltas are recorded, signed"             "-1000" "$(dfv "$T/diff/ram.json" >/dev/null; python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["ram_delta_mb"])' "$T/diff/out.json")"

# ------------------------------------------ the PRODUCT's uninstall, as a test
un() { printf '%s' "$1" > "$T/guest.log"
       ( set +u; cd "$DEV"; say() { :; }; exists() { return 0; }; source isle/guest-uninstall.sh
         _parse_uninstall "$T/guest.log" - 1 "${2:-ok}" ) 2>&1; }
CLEAN_LOG='###POLARI-UNINSTALL-BEGIN
###FIELD installed=1
###STEP everything
[/] packages purged
[/] VERIFIED: nothing of isle-mesh/polari remains on this device
###FIELD rc_everything=0
###STEP verify
###FIELD rc_verify=purged
###STEP handback
###PROOF default route|pass|a default route is present
###PROOF public DNS|pass|archive.ubuntu.com resolves
###PROOF apt|pass|apt-get update succeeds
###PROOF network owner|pass|systemd-networkd is active
###PROOF desktop connections|n/a|no NetworkManager in this cloud image
###POLARI-UNINSTALL-END'
has "a full uninstall that verified zero footprint is CLEAN"  "clean|"  "$(un "$CLEAN_LOG")"
has "  …and says the box is a default Ubuntu again"           "default Ubuntu again" "$(un "$CLEAN_LOG")"
DIRTY_LOG="${CLEAN_LOG/VERIFIED: nothing of isle-mesh\/polari remains on this device/volumes remaining: 2 (data)}"
has "the product's own 'volumes remaining' makes it DIRTY"    "dirty|"  "$(un "$DIRTY_LOG")"
HANDBACK_LOG="${CLEAN_LOG/public DNS|pass|archive.ubuntu.com resolves/public DNS|fail|archive.ubuntu.com does not resolve}"
has "a hand-back proof that fails makes it DIRTY too"         "dirty|"  "$(un "$HANDBACK_LOG")"
FAILED_LOG="${CLEAN_LOG/rc_everything=0/rc_everything=1}"
has "an uninstall command that exits non-zero is FAILED"      "failed|" "$(un "$FAILED_LOG")"
has "a guest that could not be reached is FAILED"             "failed|" "$(un "$CLEAN_LOG" no)"
SKIP_LOG='###POLARI-UNINSTALL-BEGIN
###FIELD installed=0
###STEP everything
nothing of isle-mesh/polari is installed in this guest
###FIELD rc_everything=skipped
###FIELD rc_verify=skipped
###STEP handback
###PROOF default route|pass|a default route is present
###POLARI-UNINSTALL-END'
has "nothing installed → SKIPPED, not a pass"                 "skipped|" "$(un "$SKIP_LOG")"
has "  …and it says why that proves nothing"                  "proves nothing" "$(un "$SKIP_LOG")"

# ---------------------------- the coupling: a dirty hand-back blocks the release
# ci-12 moved WHERE this is decided, not WHETHER. The uninstall verdict now
# reaches the routes through the TEST VERDICT — verdict.py ANDs it in once, and
# routes/_lib.sh refuses anything that is not `passed`. The coupling is enforced
# in one place instead of two that could drift; these cases prove it end to end,
# from the isle results a stage wrote to the route that would have published.
UNDIR="$T/uncouple"
uncouple() {  # uncouple <uninstall_verdict> → build the verdict from real isle results
    # (an earlier section moves $T/pool around; the rule reads the sha from here)
    mkdir -p "$T/pool"; printf '{"components":{"superproject":{"sha":"deadbee"}},"publishedTo":{}}' > "$T/pool/release.json"
    mkdir -p "$VPOOL/test/deadbee"
    rm -rf "$UNDIR"; mkdir -p "$UNDIR/selftests" "$UNDIR/isle-test"
    printf '{"ran": true, "modules": {"core": "pass"}, "counts": {"suites": 1, "pass": 1, "fail": 0}}' \
        > "$UNDIR/selftests/results.json"
    python3 -c 'import json,sys
uv = sys.argv[2]
json.dump({"version": "1", "core_ok": uv == "clean", "passed": ["gears"], "tested": ["gears"],
           "untested": [], "stages": [{"index": 1, "uninstall_verdict": uv,
                                       "uninstall_findings": ["volumes remaining: 2"]}],
           "leak_summary": {"uninstall": {"stage1": uv}}}, open(sys.argv[1], "w"))' \
        "$UNDIR/isle-test/results.json" "$1"
    python3 "$DEV/verdict.py" build "$UNDIR" --sha deadbee --at 2026-01-01T00:00:00 >/dev/null 2>&1
    cp "$UNDIR/verdict.json" "$VPOOL/test/deadbee/verdict.json"
}
ungate() { gate; }
uncouple clean
has "a CLEAN hand-back lets the route arm"            "ARMED"                                  "$(ungate)"
uncouple dirty
has "a DIRTY hand-back holds the whole release"       "not passed"                             "$(ungate)"
has "  …and the verdict it carries is FAILED, not partial" "failed"                            "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["verdict"])' "$UNDIR/verdict.json")"
has "  …naming the product's own finding"             "dirty"                                  "$(ungate)"
uncouple skipped
has "a SKIPPED hand-back is not a pass either"        "DRY"                                    "$(ungate)"
has "  …it is PARTIAL, and the reason names ci-3"     "ci-3"                                   "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["why"])' "$UNDIR/verdict.json")"
seedverdict passed ''

# ------------------------------------------ the pipeline loop, as written
JF="$(cat "$J/pipelines/Jenkinsfile.isle-test")"
has "the pipeline takes ONE leak baseline, before the stages"  'leakcheck.sh\" baseline'       "$JF"
has "  …runs the PRODUCT's uninstall before the VM dies"       'throwaway.sh\" uninstall'      "$JF"
has "  …then down (which wipes)"                               'throwaway.sh" down'            "$JF"
has "  …then checks for leaks"                                 'leakcheck.sh\" check'          "$JF"
has "a leak is re-wiped once and re-checked before it is believed" "re-wiping once"            "$JF"
has "  …and then STOPS the run as a resource guard"            "STOPPING as a resource guard"  "$JF"
has "  …unless CI_LEAK_POLICY=continue"                        "CI_LEAK_POLICY"                "$JF"
has "results.json carries leak_summary"                        "leak_summary"                  "$JF"
has "  …and per stage the leaks and the deltas"                "ram_delta_mb"                  "$JF"
has "core_ok requires a CLEAN uninstall, in the pipeline too"  "uninstall_verdict == 'clean'"  "$JF"

# ------------------------------------------ the preflight refuses residue
has "the preflight names the wipe as the fix"                  "pol jenkins isle wipe"         "$(cat "$J/isle/preflight.sh")"
dev_env CI_ISLE_TARGET=ssh CI_ISLE_SSH_HOST=fakebox CI_MIN_FREE_GB=1 CI_ISLE_NESTED=required \
        CI_ISLE_VM_RAM_GB=4 CI_ISLE_VM_DISK_GB=30 CI_MIN_RAM_HEADROOM_GB=1
OUT=$(pf FAKE_INVENTORY="$T/inv/clear.json" FAKE_RESIDUE="polari-ci-isle")
has "residue on the target FAILs the preflight"                "residue from an earlier run"   "$OUT"
has "  …and points at the wipe"                                "pol jenkins isle wipe"         "$OUT"
has "  …and refuses the run"                                   "REFUSED"                       "$OUT"
OUT=$(pf FAKE_INVENTORY="$T/inv/clear.json")
has "  …a target with no residue PASSes that row"              "carries the polari-ci- tag"    "$OUT"

# ---------------------------------------- the doctor reports the last verdicts
mkdir -p "$DEV/pool/2026.09.19/isle-test"
printf '{"kind":"leak-check","stage":"1","verdict":"leaked","leaks":[{"kind":"file","item":"x"}],"ram_delta_mb":-900,"disk_delta_mb":-40}' \
    > "$DEV/pool/2026.09.19/isle-test/leak-check-1.json"
printf '{"version":"2026.09.19","core_ok":false,"stages":[{"index":1,"uninstall_verdict":"dirty","uninstall_findings":["volumes remaining: 2"]}]}' \
    > "$DEV/pool/2026.09.19/isle-test/results.json"
dev_env CI_ISLE_TARGET=local
has "the doctor reports the last leak verdict"        "survived the wipe"                      "$(doc)"
has "  …with the RAM that did not come back"          "RAM -900 MB"                            "$(doc)"
has "  …and the last uninstall verdict"               "stage 1: dirty"                         "$(doc)"
has "  …saying it is the PRODUCT that failed"         "FAILURE OF THE PRODUCT"                 "$(doc)"
printf '{"kind":"leak-check","stage":"1","verdict":"clean","leaks":[],"ram_delta_mb":12,"disk_delta_mb":0}' \
    > "$DEV/pool/2026.09.19/isle-test/leak-check-1.json"
has "a clean leak check reads as clean"               "CLEAN"                                  "$(doc)"
rm -rf "$DEV/pool/2026.09.19"

# =========================================== ci-11a: the machine protocol
# `pol jenkins setup --json` is what a front end drives the device through.
# What is asserted here is the CONTRACT: one document on stdout and nothing
# else, every step parseable, `--step` / `--answer` / `--run` behaving, no
# secret value anywhere in it, and every action naming a verb that exists in
# the allowlist with a regex for every parameter.
echo
echo "-- ci-11a: the setup protocol (polari-pipeline-setup/1)"
dev_env CI_ISLE_TARGET=local CI_ISLE_STAGES=core CI_MODE=suite

jset() { ( cd "$DEV" && FOOTPRINT_INVENTORY="$T/inv/inventory.sh" bash setup.sh --json "$@" </dev/null 2>/dev/null ) || true; }
jerr() { ( cd "$DEV" && FOOTPRINT_INVENTORY="$T/inv/inventory.sh" bash setup.sh --json "$@" </dev/null 2>&1 >/dev/null ) || true; }
jq_() { printf '%s' "$1" | python3 -c "
import json, sys
try: d = json.load(sys.stdin)
except Exception as e: print('UNPARSEABLE: %s' % e); raise SystemExit(0)
$2" 2>&1; }

DOC="$(jset)"
eq "the whole document parses as ONE json object"  "ok"  "$(jq_ "$DOC" 'print("ok" if isinstance(d, dict) else "not an object")')"
eq "  …and declares the protocol"  "polari-pipeline-setup/1"  "$(jq_ "$DOC" 'print(d.get("protocol"))')"
eq "  …with all EIGHT steps, in order"  "role checkout network secrets isle stages controller summary" \
   "$(jq_ "$DOC" 'print(" ".join(s["name"] for s in d["steps"]))')"
eq "  …each numbered 1..8 out of 8"  "ok" \
   "$(jq_ "$DOC" 'print("ok" if [s["index"] for s in d["steps"]] == list(range(1,9)) and all(s["total"]==8 for s in d["steps"]) else [s["index"] for s in d["steps"]])')"
eq "  …every step carries a state from the vocabulary"  "ok" \
   "$(jq_ "$DOC" 'bad=[s["name"] for s in d["steps"] if s["state"] not in ("done","todo","blocked","skipped")]; print("ok" if not bad else bad)')"
eq "  …every check carries a verdict from the vocabulary"  "ok" \
   "$(jq_ "$DOC" 'bad=[c for s in d["steps"] for c in s["checks"] if c["verdict"] not in ("OK","WARN","FAIL")]; print("ok" if not bad else bad)')"
eq "  …every step EXPLAINS itself in plain words (his ask: tell us what we should be setting up)"  "ok" \
   "$(jq_ "$DOC" 'bad=[s["name"] for s in d["steps"] if len(s.get("explain") or "") < 80]; print("ok" if not bad else bad)')"
eq "  …the summary counts the steps and names what blocks"  "ok" \
   "$(jq_ "$DOC" 'x=d["summary"]; print("ok" if set(x)=={"complete","total","ready","blocking"} and x["total"]==8 else x)')"
eq "  …the to-do list is the ordered one the terminal prints, with a command each"  "ok" \
   "$(jq_ "$DOC" 'print("ok" if all(set(t)=={"step","text","command"} for t in d["todo"]) else d["todo"])')"

# --- NOTHING but the document on stdout ------------------------------------
eq "stdout carries the document and NOTHING else (a step that prints cannot break it)" "ok" \
   "$(printf '%s' "$DOC" | python3 -c '
import json,sys
raw = sys.stdin.read()
try:
    json.loads(raw)
    print("ok")
except Exception as e:
    print("stdout is not one json document: %s" % e)')"
ERRS="$(jerr)"
has "the logs go to STDERR, where they belong"     "setup --json"  "$ERRS"
hasnt "  …and no json leaks into them"             '"protocol"' "$ERRS"

# --- one step --------------------------------------------------------------
ONE="$(jset --step secrets)"
eq "--step returns exactly that step"  "secrets"  "$(jq_ "$ONE" 'print(d["steps"][0]["name"] if len(d["steps"])==1 else "%d steps" % len(d["steps"]))')"
eq "  …and drops the summary rather than lying about the other seven"  "ok" \
   "$(jq_ "$ONE" 'print("ok" if "summary" not in d else d["summary"])')"
BAD="$( cd "$DEV" && bash setup.sh --json --step nosuchstep </dev/null 2>&1 >/dev/null || true )"
has "an unknown step is refused by NAME, listing the real ones"  "no such step"  "$BAD"

# --- the answers -----------------------------------------------------------
A1="$(jset --step role --answer CI_MODE=app)"
eq "--answer writes device.env and the recomputed step shows it"  "app"  "$(jq_ "$A1" 'print(d["device"]["mode"])')"
has "  …device.env really changed"  "CI_MODE=app"  "$(cat "$DEV/device.env")"
A2="$(jset --step role --answer CI_MODE=suite)"
eq "  …and it round-trips back"  "suite"  "$(jq_ "$A2" 'print(d["device"]["mode"])')"
A3="$(jset --step role --answer NOT_A_KEY=1)"
eq "an answer that is not a device.env key is REFUSED, and the refusal says so"  "ok" \
   "$(jq_ "$A3" 'print("ok" if any("refused NOT_A_KEY" in t["text"] for t in d["todo"]) else d["todo"])')"
A4="$(jset --step secrets --answer github/release_token=hunter2)"
eq "A SECRET may NOT be answered here — a value in an argument is a value in the process list"  "ok" \
   "$(jq_ "$A4" 'print("ok" if any("SECRET name" in t["text"] for t in d["todo"]) else d["todo"])')"
hasnt "  …and the refused value appears NOWHERE in the document"  "hunter2"  "$A4"

# --- one action ------------------------------------------------------------
R1="$(jset --run cache-status)"
eq "--run returns the action, its verdict and its exit code"  "cache-status"  "$(jq_ "$R1" 'print(d["action"])')"
eq "  …with ok, exitCode and the tail of its output"  "ok" \
   "$(jq_ "$R1" 'print("ok" if {"ok","exitCode","output"} <= set(d) else sorted(d))')"
eq "  …and the recomputed STEP it belongs to, not the whole walkthrough"  "ok" \
   "$(jq_ "$R1" 'print("ok" if "step" in d and "steps" not in d else sorted(d))')"
R2="$(jset --run no-such-action)"
eq "an unknown action fails with a non-zero exit and names the ids"  "ok" \
   "$(jq_ "$R2" 'print("ok" if d["ok"] is False and d["exitCode"] != 0 and "no such action" in d["output"] else (d["ok"], d["exitCode"]))')"
NOJSON="$( cd "$DEV" && bash setup.sh --run cache-status </dev/null 2>&1 >/dev/null || true )"
has "--run without --json is refused: it belongs to the machine protocol"  "machine protocol"  "$NOJSON"

# --- NO SECRET VALUE, anywhere --------------------------------------------
mkdir -p "$DEV/secrets/github"
printf 'ghp_thisisaverysecretvalue' > "$DEV/secrets/github/release_token"
SDOC="$(jset)"
hasnt "a stored secret's VALUE never appears in the document"  "ghp_thisisaverysecretvalue"  "$SDOC"
eq "  …a secret question says PRESENT and nothing more"  "present" \
   "$(jq_ "$SDOC" 'print([q["answered"] for s in d["steps"] for q in s["questions"] if q["key"]=="github/release_token"][0])')"
eq "  …and a secret question binds to NO answer verb: its value goes to stdin, never to argv"  "ok" \
   "$(jq_ "$SDOC" 'print("ok" if not [q for s in d["steps"] for q in s["questions"] if q["kind"]=="secret" and q.get("action")] else "a secret question carries an action")')"
eq "  …while every other question DOES bind, with {answer} left for the executor to fill"  "ok" \
   "$(jq_ "$SDOC" 'qs=[q for s in d["steps"] for q in s["questions"] if q["kind"]!="secret"]; print("ok" if qs and all(q.get("action",{}).get("params",{}).get("value")=="{answer}" for q in qs) else [q["key"] for q in qs if not q.get("action")])')"
rm -f "$DEV/secrets/github/release_token"

# --- nothing privileged is ever RUN by the protocol ------------------------
eq "a privileged action is DESCRIBED, never run — every one of them names a verb and says why"  "ok" \
   "$(jq_ "$SDOC" 'p=[a for s in d["steps"] for a in s["actions"] if a["privileged"]]; print("ok" if p and all(a.get("verb") and a.get("why") for a in p) else p)')"

# --- the ALLOWLIST ---------------------------------------------------------
echo "-- ci-11a: the verb allowlist (polari-pipeline-shell/1)"
VERBS="$(cat "$J/shell-verbs.json")"
eq "shell-verbs.json parses and declares its protocol"  "polari-pipeline-shell/1" \
   "$(jq_ "$VERBS" 'print(d["protocol"])')"
eq "  …every verb declares argv, privileged and a label"  "ok" \
   "$(jq_ "$VERBS" 'bad=[n for n,v in d["verbs"].items() if not v.get("argv") or "privileged" not in v or not v.get("label")]; print("ok" if not bad else bad)')"
eq "  …every {placeholder} in an argv has a regex, and every regex is ANCHORED"  "ok" \
   "$(jq_ "$VERBS" '
import re
bad = []
for n, v in d["verbs"].items():
    holes = {m for a in v["argv"] for m in re.findall(r"\{([a-z]+)\}", a)}
    params = v.get("params") or {}
    if holes != set(params):
        bad.append("%s: argv wants %s, params declare %s" % (n, sorted(holes), sorted(params)))
    for k, p in params.items():
        if not (p.startswith("^") and p.endswith("$")):
            bad.append("%s.%s: unanchored %s" % (n, k, p))
print("ok" if not bad else bad)')"
eq "  …only secrets-put reads stdin, and it reads a SECRET (that is the whole point of it)"  "ok" \
   "$(jq_ "$VERBS" 'st={n:v.get("stdin") for n,v in d["verbs"].items() if v.get("stdin")}; print("ok" if st == {"secrets-put":"secret"} else st)')"
eq "  …the list stays SMALL: no free-form command, no verb taking a path"  "ok" \
   "$(jq_ "$VERBS" 'print("ok" if len(d["verbs"]) <= 12 and not [n for n,v in d["verbs"].items() if any(w in ("{cmd}","{command}","{path}","{file}") for w in v["argv"])] else sorted(d["verbs"]))')"

# the join: EVERY action every step emits must name a verb that is in the file
printf '%s' "$SDOC" > "$T/doc.json"; printf '%s' "$VERBS" > "$T/verbs.json"
eq "EVERY action of EVERY step names a verb that exists in the allowlist"  "ok" \
   "$(python3 -c '
import json, re, sys
doc = json.load(open(sys.argv[1])); verbs = json.load(open(sys.argv[2]))["verbs"]
bad = []
for s in doc["steps"]:
    for a in s["actions"]:
        spec = verbs.get(a["verb"])
        if spec is None:
            bad.append("%s/%s: no verb %r" % (s["name"], a["id"], a["verb"])); continue
        declared = spec.get("params") or {}
        given = a.get("params") or {}
        if set(given) != set(declared):
            bad.append("%s/%s: params %s vs declared %s" % (s["name"], a["id"], sorted(given), sorted(declared)))
        for k, p in declared.items():
            v = given.get(k, "")
            if not re.match(p + r"\Z", v):
                bad.append("%s/%s: %s=%r fails %s" % (s["name"], a["id"], k, v, p))
        if a["privileged"] != bool(spec.get("privileged")):
            bad.append("%s/%s: privileged disagrees with the allowlist" % (s["name"], a["id"]))
print("ok" if not bad else bad)' "$T/doc.json" "$T/verbs.json" 2>&1)"
eq "  …and every question binding does too"  "ok" \
   "$(python3 -c '
import json, re, sys
doc = json.load(open(sys.argv[1])); verbs = json.load(open(sys.argv[2]))["verbs"]
bad = []
for s in doc["steps"]:
    for q in s["questions"]:
        b = q.get("action")
        if not b:
            continue
        spec = verbs.get(b["verb"])
        if spec is None:
            bad.append("%s/%s: no verb %r" % (s["name"], q["key"], b["verb"])); continue
        declared = spec.get("params") or {}
        if set(b.get("params") or {}) != set(declared):
            bad.append("%s/%s: params mismatch" % (s["name"], q["key"]))
        for k, p in declared.items():
            v = (b.get("params") or {}).get(k, "")
            if re.match(r"^\{[a-z]+\}$", v):
                continue        # the executor substitutes it, and validates it there
            if not re.match(p + r"\Z", v):
                bad.append("%s/%s: %s=%r fails %s" % (s["name"], q["key"], k, v, p))
print("ok" if not bad else bad)' "$T/doc.json" "$T/verbs.json" 2>&1)"

# --- doctor --json, preflight --json: stable, and declared -----------------
DJ="$( cd "$DEV" && bash doctor.sh --json 2>/dev/null || true )"
eq "doctor --json is ONE document and declares its protocol"  "polari-pipeline-doctor/1" \
   "$(jq_ "$DJ" 'print(d["protocol"])')"
eq "  …every row carries a verdict, and a WARN carries its fix"  "ok" \
   "$(jq_ "$DJ" 'bad=[r["check"] for r in d["rows"] if r["verdict"] not in ("OK","WARN") or (r["verdict"]=="WARN" and not r["fix"])]; print("ok" if not bad else bad)')"
PJ="$( cd "$DEV" && env FOOTPRINT_INVENTORY="$T/inv/inventory.sh" FAKE_INVENTORY="$T/inv/clear.json" bash isle/preflight.sh --isle --json 2>/dev/null || true )"
eq "preflight --json declares its protocol too"  "polari-pipeline-preflight/1" \
   "$(jq_ "$PJ" 'print(d["protocol"])')"

# --- THE FIRST RUN: no core, no device.env --------------------------------
rm -f "$DEV/device.env"
FIRST="$(jset)"
eq "with NO device.env and no Polari core at all, the protocol still answers"  "polari-pipeline-setup/1" \
   "$(jq_ "$FIRST" 'print(d.get("protocol"))')"
eq "  …with all eight steps, so a first-run screen has something to render"  "8" \
   "$(jq_ "$FIRST" 'print(len(d["steps"]))')"
dev_env CI_ISLE_TARGET=local

# ===========================================================================
# ci-12 — THE BRANCH MODEL: dev iterate · test decide · main release
# ===========================================================================
echo "-- ci-12: promote refusals, the verdict arithmetic, the release rule keyed on it,"
echo "   the scan summary + the pinned tools, and the one-deep latest-wins queue"

# ---- the verdict arithmetic. verdict.py is the ONE place it lives, so these
# cases pin the WHOLE rule — the Jenkinsfile, the CLI and the routes all read
# the file it writes and re-derive nothing.
VD="$T/verdicts"; mkdir -p "$VD"
mkverdict() {  # mkverdict <dir> <selftests.json> <isle.json> [scan.json]
    rm -rf "$1"; mkdir -p "$1/selftests" "$1/isle-test" "$1/scan"
    printf '%s' "$2" > "$1/selftests/results.json"
    [ -n "$3" ] && printf '%s' "$3" > "$1/isle-test/results.json" || rm -rf "$1/isle-test"
    [ -n "${4:-}" ] && printf '%s' "$4" > "$1/scan/SUMMARY.json" || true
}
SELF_OK='{"ran": true, "modules": {"core": "pass"}, "counts": {"suites": 88, "pass": 88, "fail": 0}}'
SELF_BAD='{"ran": true, "modules": {"core": "fail"}, "counts": {"suites": 88, "pass": 80, "fail": 8}}'
ISLE_OK='{"core_ok": true, "stages": [{"index": 1}], "passed": ["household"], "untested": [], "leak_summary": {"uninstall": {"stage1": "clean"}}}'
ISLE_SKIP='{"core_ok": false, "stages": [{"index": 1}], "passed": [], "untested": [], "leak_summary": {"uninstall": {"stage1": "skipped"}}}'
ISLE_DIRTY='{"core_ok": false, "stages": [{"index": 1}], "passed": [], "untested": [], "leak_summary": {"uninstall": {"stage1": "dirty"}}}'

mkverdict "$VD/pass" "$SELF_OK" "$ISLE_OK"
V="$(python3 "$DEV/verdict.py" build "$VD/pass" --sha deadbeef --at 2026-01-01T00:00:00 2>&1)"
has "verdict: every selftest passes and the isle recorded core_ok → PASSED" "PASSED" "$V"

mkverdict "$VD/partial" "$SELF_OK" "$ISLE_SKIP"
V="$(python3 "$DEV/verdict.py" build "$VD/partial" --sha deadbeef --at 2026-01-01T00:00:00 2>&1)"
has "verdict: selftests pass but every isle stage is SKIPPED → PARTIAL (today's honest state)" "PARTIAL" "$V"
has "  …and it says exactly why, naming ci-3 rather than shrugging" "ci-3" "$V"
hasnt "  …a partial is NOT a pass" "PASSED" "$V"

mkverdict "$VD/fail" "$SELF_BAD" "$ISLE_OK"
V="$(python3 "$DEV/verdict.py" build "$VD/fail" --sha deadbeef --at 2026-01-01T00:00:00 2>&1)"
has "verdict: a failing module selftest → FAILED, naming the module" "FAILED" "$V"
has "  …and names the module that failed" "core" "$V"

mkverdict "$VD/dirty" "$SELF_OK" "$ISLE_DIRTY"
V="$(python3 "$DEV/verdict.py" build "$VD/dirty" --sha deadbeef --at 2026-01-01T00:00:00 2>&1)"
has "verdict: a DIRTY hand-back is a failure, not a partial (ci-10's coupling survives)" "FAILED" "$V"

mkverdict "$VD/noisle" "$SELF_OK" ""
V="$(python3 "$DEV/verdict.py" build "$VD/noisle" --sha deadbeef --at 2026-01-01T00:00:00 2>&1)"
has "verdict: no isle results at all → PARTIAL, saying nothing was tested in an isle" "PARTIAL" "$V"

mkverdict "$VD/scan" "$SELF_OK" "$ISLE_OK" '{"totals": {"critical": 9, "high": 40}, "tools": {"trivy": {"critical": 9}}}'
V="$(python3 "$DEV/verdict.py" build "$VD/scan" --sha deadbeef --at 2026-01-01T00:00:00 2>&1)"
has "verdict: 9 CRITICAL scan findings do not change a thing — still PASSED" "PASSED" "$V"
has "  …the counts are carried, and the line says they are advisory" "ADVISORY" "$V"
eq "  …the verdict file records scans WITHOUT them entering the arithmetic" "passed" \
   "$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["verdict"] if d["scans"]["totals"]["critical"]==9 else "MISSED")' "$VD/scan/verdict.json")"

mkverdict "$VD/nobuild" "$SELF_OK" "$ISLE_OK"
V="$(python3 "$DEV/verdict.py" build "$VD/nobuild" --sha deadbeef --built false --at 2026-01-01T00:00:00 2>&1)"
has "verdict: nothing was BUILT → FAILED (there was nothing to test)" "FAILED" "$V"

# ---- the release rule, keyed on the verdict
RL="$T/rule"; mkdir -p "$RL/debs"
printf '{"components": {"superproject": {"sha": "cafebabe0000"}}}' > "$RL/release.json"
: > "$RL/debs/polari-complete_1_amd64.deb"
: > "$RL/debs/polari-app-household_1_all.deb"
rule() {
    ( cd "$DEV/routes" && env VERSION=2026.01.01 POOL_DIR="$RL" POLARI_POOL="$T/rulepool" \
        DRY_RUN="${DRY_RUN:-auto}" CI_ROUTES=github-release GITHUB_TOKEN=x \
        bash -c 'source ./_lib.sh; ROUTE=github-release; arm GITHUB_TOKEN:github/release_token' 2>&1 ) || true
}
rm -rf "$T/rulepool"; mkdir -p "$T/rulepool/test/cafebabe0000"
OUT="$(rule)"
has "release rule: NO verdict for the sha → DRY, naming the fix in his words" "no passed test run" "$OUT"
has "  …and the reason tells you to push to test first" "promote test" "$OUT"
cp "$VD/partial/verdict.json" "$T/rulepool/test/cafebabe0000/verdict.json"
OUT="$(rule)"
has "release rule: a PARTIAL verdict → still DRY" "not passed" "$OUT"
DRY_RUN=false OUT="$(DRY_RUN=false rule)"
has "  …and DRY_RUN=false does NOT override it (the rule is hard)" "not passed" "$OUT"
cp "$VD/pass/verdict.json" "$T/rulepool/test/cafebabe0000/verdict.json"
OUT="$(rule)"
has "release rule: a PASSED verdict → ARMED" "ARMED" "$OUT"
has "  …and the route names itself and the version" "route github-release  version 2026.01.01" "$OUT"
rm -f "$RL/release.json"
OUT="$(rule)"
has "release rule: a build with no release.json names no sha → DRY, and says so" "names no superproject sha" "$OUT"
printf '{"components": {"superproject": {"sha": "cafebabe0000"}}}' > "$RL/release.json"

# ---- the scan layer: counting from fixture reports, and the pinned tools
SC="$T/scanout"; mkdir -p "$SC"
cat > "$SC/trivy-source.json" <<'JSON'
{"Results": [{"Vulnerabilities": [{"Severity": "CRITICAL"}, {"Severity": "HIGH"}, {"Severity": "LOW"}],
              "Misconfigurations": [{"Severity": "MEDIUM"}], "Secrets": [{"Severity": "HIGH"}]}]}
JSON
printf '[{"Description": "a key"}, {"Description": "another"}]\n' > "$SC/gitleaks.json"
printf '{"metadata": {"vulnerabilities": {"info": 0, "low": 2, "moderate": 1, "high": 0, "critical": 0, "total": 3}}}\n' > "$SC/npm-audit.json"
printf '{"dependencies": [{"name": "x", "vulns": [{"id": "PYSEC-1"}]}]}\n' > "$SC/pip-audit.json"
printf 'trivy: the image could not be pulled\n' > "$SC/SKIPPED.txt"
OUT="$(python3 "$DEV/scan/summarize.py" summary "$SC" "$DEV/scan-tools.lock" 2>&1)"
SUM="$(cat "$SC/SCAN_SUMMARY.md")"
has "scan summary: trivy's four kinds of finding are counted by severity" "| trivy-source | 1 | 2 | 1 | 1 |" "$SUM"
has "  …gitleaks has no severity of its own, and a leaked credential is counted HIGH" "| gitleaks | 0 | 2 |" "$SUM"
has "  …npm audit's moderate is normalised to medium rather than dropped" "| npm-audit | 0 | 0 | 1 | 2 |" "$SUM"
has "  …pip-audit states no severity, so it is counted UNKNOWN, not invented" "| pip-audit | 0 | 0 | 0 | 0 | 0 | 1 |" "$SUM"
has "  …there is a TOTAL row" "**total**" "$SUM"
has "  …a tool that could not run is SKIPPED with its reason, not silently absent" "could not be pulled" "$SUM"
has "  …and the summary states, first, that nothing below gates anything" "Nothing below gates anything" "$SUM"
eq "  …SUMMARY.json carries the totals the verdict will embed" "4" \
   "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["totals"]["high"])' "$SC/SUMMARY.json")"

LOCKOUT="$( cd "$DEV" && bash scan/scan.sh lock 2>&1 )"
has "scan-tools.lock: trivy is pinned, with its licence" "trivy" "$LOCKOUT"
has "  …gitleaks too" "gitleaks" "$LOCKOUT"
has "  …and the lock says, in its own output, that every tool is advisory" "ADVISORY" "$LOCKOUT"
BAD="$(awk -F'|' '$1 ~ /^[a-z]/ { n=split($0,a,"|"); if (n < 5 || a[2] ~ /^[ ]*$/ || a[4] ~ /^[ ]*$/) print a[1] }' "$DEV/scan-tools.lock")"
eq "  …COMPLETENESS: every tool row carries an image, a digest field, a licence and what it scans" "" "$BAD"
NOTAG="$(awk -F'|' '$1 ~ /^[a-z]/ { gsub(/^ +| +$/,"",$2); if ($2 !~ /^host:/ && $2 !~ /:/) print $2 }' "$DEV/scan-tools.lock")"
eq "  …and every container tool names an EXPLICIT tag, never a floating one" "" "$NOTAG"
OUT="$( cd "$DEV" && SCAN_OUT="$T/scanempty" SCAN_DOCKER="$T/bin/nodocker" bash scan/scan.sh source 2>&1; echo "rc=$?" )"
has "scan: with no usable docker daemon every tool SKIPS with a line…" "SKIPPED" "$OUT"
has "  …and the stage still exits 0 — a scan can never fail a build" "rc=0" "$OUT"

# ---- the queue: ONE item deep, latest wins, and the quiet window
QP="$T/qpool"; rm -rf "$QP"; mkdir -p "$QP"
q() { ( cd "$DEV" && env POLARI_POOL="$QP" POLARI_SUITE="$T" CI_QUIET_MINUTES=5 \
        CI_QUIET_GRACE_S="${CI_QUIET_GRACE_S:-30}" FAKE_HEADS="$FAKE_HEADS" bash quiet.sh "$@" 2>&1 ) || true; }
qrc(){ ( cd "$DEV" && env POLARI_POOL="$QP" POLARI_SUITE="$T" CI_QUIET_MINUTES="${QM:-5}" \
        CI_QUIET_GRACE_S="${CI_QUIET_GRACE_S:-30}" FAKE_HEADS="$FAKE_HEADS" bash quiet.sh "$@" >/dev/null 2>&1 ); echo "$?"; }
qfield(){ python3 -c 'import json,sys
try: print(json.load(open(sys.argv[1])).get(sys.argv[2], ""))
except Exception: print("")' "$QP/queue/$1.json" "$2"; }

export FAKE_HEADS="test=aaa111"
q saw test >/dev/null
eq "queue: the first poll records ONE pending item at the newest sha" "aaa111" "$(qfield test newest_sha)"
eq "  …and it is pending" "True" "$(qfield test pending)"
# backdate the window so "it restarted" is observable without waiting
python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["since"]="1"; json.dump(d,open(p,"w"))' "$QP/queue/test.json"
for sha in bbb222 ccc333 ddd444 eee555; do export FAKE_HEADS="test=$sha"; q saw test >/dev/null; done
eq "queue: FIVE changes in three minutes leave exactly ONE pending item…" "1" \
   "$(ls -1 "$QP/queue" | wc -l | tr -d ' ')"
eq "  …and it is the LAST one that came in, not the first (latest wins)" "eee555" "$(qfield test newest_sha)"
[ "$(qfield test since)" != "1" ] && ok "  …each change RESTARTED the quiet window" \
    || bad "  …each change RESTARTED the quiet window" "a since newer than the backdated 1" "$(qfield test since)"
eq "  …nothing was appended: there is no backlog to work through" "1" \
   "$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(1 if isinstance(d.get("pending"), bool) else 0)' "$QP/queue/test.json")"

eq "quiet: a forest that moved inside the window DEFERS (exit 6), it does not build half a promotion" "6" \
   "$(CI_QUIET_GRACE_S=0 qrc check test)"
# the poll cannot land on the boundary: 30s of grace turns a four-second miss
# into a run rather than another whole tick of waiting (measured on the device:
# "only 296s of quiet, 4s to go").
python3 -c 'import json,sys,time; p=sys.argv[1]; d=json.load(open(p)); d["since"]=str(int(time.time())-290); json.dump(d,open(p,"w"))' "$QP/queue/test.json"
eq "quiet: 290s of a 300s window is inside the poll grace — it proceeds rather than waiting another tick" \
   "0" "$(qrc check test)"
eq "  …and with the grace turned off it is still a deferral, so the grace is a knob and not a silent floor change" \
   "6" "$(CI_QUIET_GRACE_S=0 qrc check test)"
python3 -c 'import json,sys,time; p=sys.argv[1]; d=json.load(open(p)); d["since"]=str(int(time.time())); json.dump(d,open(p,"w"))' "$QP/queue/test.json"
OUT="$(q check test)"
has "  …and the deferral says the pending item stays and the next poll takes it" "Nothing is queued behind it" "$OUT"
eq "quiet: once the window has elapsed the run proceeds" "0" "$(QM=0 qrc check test)"
has "  …naming the sha it settled on" "QUIET_SHA=eee555" "$( (cd "$DEV" && env POLARI_POOL="$QP" POLARI_SUITE="$T" CI_QUIET_MINUTES=0 FAKE_HEADS="$FAKE_HEADS" bash quiet.sh check test 2>&1) || true)"

# the PROMOTION MARKER short-circuits the window: a finished promotion does not
# have to sit out five minutes proving it has stopped moving.
mkdir -p "$QP/promotions/test"
printf '{"branch": "test", "repos": {".": "eee555"}, "superproject": "eee555"}\n' > "$QP/promotions/test/eee555.json"
rm -f "$QP/queue/test.json"; q saw test >/dev/null      # a fresh, still-warm window
OUT="$(q check test)"
has "quiet: a matching promotion MARKER is quiet immediately — the promotion is finished" "QUIET_SHA=eee555" "$OUT"
has "  …and it says why it did not wait" "does not have to prove it stopped" "$OUT"
printf '{"branch": "test", "repos": {".": "somethingelse"}, "superproject": "eee555"}\n' > "$QP/promotions/test/eee555.json"
eq "  …a marker that does NOT match the live forest is ignored, and the timer rules" "6" "$(qrc check test)"
rm -rf "$QP/promotions"

# a change DURING a run leaves exactly one pending item afterwards
q claim test eee555 >/dev/null
eq "queue: while a run is claimed, pending is cleared" "False" "$(qfield test pending)"
export FAKE_HEADS="test=fff666"
q saw test >/dev/null
eq "  …a change during the run sets ONE pending item, not a second queued run" "True" "$(qfield test pending)"
eq "  …naming the newest state, which is what the next run will check out" "fff666" "$(qfield test newest_sha)"
q done test eee555 >/dev/null
eq "  …and after the run there is still exactly one queue file" "1" "$(ls -1 "$QP/queue" | wc -l | tr -d ' ')"

# ---- the GATE: the cheap pre-check, and "already covered"
# A shallow forest checkout costs ~6 minutes on the pipeline device, so an idle
# tick must not pay for one — and a run that DEFERRED must be retryable, which
# an SCM trigger cannot do (by the time the forest is quiet, nothing has changed
# again). The gate is one ls-remote, before any checkout.
export CI_SUITE_REMOTE="https://example.invalid/polari-suite.git"
g() { ( cd "$DEV" && env POLARI_POOL="$QP" POLARI_SUITE="$T/nosuchcheckout" CI_QUIET_MINUTES="${QM:-5}" \
        CI_SUITE_REMOTE="$CI_SUITE_REMOTE" FAKE_HEADS="$FAKE_HEADS" bash quiet.sh "$@" 2>&1 ) || true; }
grc(){ ( cd "$DEV" && env POLARI_POOL="$QP" POLARI_SUITE="$T/nosuchcheckout" CI_QUIET_MINUTES="${QM:-5}" \
        CI_SUITE_REMOTE="$CI_SUITE_REMOTE" FAKE_HEADS="$FAKE_HEADS" bash quiet.sh "$@" >/dev/null 2>&1 ); echo "$?"; }
rm -rf "$QP/queue" "$QP/turn.json"
export FAKE_HEADS="test=111aaa"
OUT="$(g gate test)"
has "gate: with NO checkout at all it still reads the superproject tip" "111aaa" "$OUT"
eq "  …and the first sighting starts the window, so it defers" "6" "$(grc gate test)"
eq "gate: once the window has elapsed it says go" "0" "$(QM=0 grc gate test)"
QM=0 g claim test 111aaa >/dev/null
QM=0 g done test 111aaa >/dev/null
eq "gate: a run that ENDED without a verdict leaves the work outstanding (an abort must not retire a sha)" \
   "0" "$(QM=0 grc gate test)"
QM=0 g covered test 111aaa >/dev/null
eq "gate: the SAME state once it has a VERDICT is 'already covered' — a periodic tick does not rebuild it" \
   "6" "$(QM=0 grc gate test)"
has "  …and it says so rather than pretending to defer" "already covered" "$(QM=0 g gate test)"
export FAKE_HEADS="test=222bbb"
eq "gate: a NEW tip is work again" "0" "$(QM=0 grc gate test)"
has "the job ticks on a TIMER, not on an SCM change — a deferral must be retryable" \
    "cron('H/5 * * * *')" "$(cat "$J/jobs/seed.groovy")"
has "  …and the reason is written down where the trigger is" "would never" "$(cat "$J/jobs/seed.groovy")"
has "the test pipeline gates BEFORE it checks out" "is there anything to test" "$(cat "$J/pipelines/Jenkinsfile.test")"
# CPS: a java.util.regex.Matcher is NOT serializable and Jenkins persists every
# local across a step boundary. Storing one killed polari-test #4 on the pipeline
# device AFTER every check had passed. The rule, asserted so it cannot come back:
# no `def <var> = (… =~ …)` anywhere in a Jenkinsfile.
for JF in "$J"/pipelines/Jenkinsfile.*; do
    BADM="$(grep -nE '^[[:space:]]*def [A-Za-z_]+ *= *\(?[A-Za-z_.]+ *=~' "$JF" || true)"
    eq "no Matcher is stored in a local in $(basename "$JF") (NotSerializableException — polari-test #4)" "" "$BADM"
done
# the shared window: the gate starts the clock, the full check does not reset it
rm -rf "$QP/queue"
export FAKE_HEADS="test=333ccc"
QM=5 g gate test >/dev/null
python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["since"]="1"; json.dump(d,open(p,"w"))' "$QP/queue/test.json"
OUT="$(q check test)"
has "the full forest check does NOT restart the window the gate started" "keeping the window the gate already started" "$OUT"
has "  …so it can proceed on a branch the gate already timed" "QUIET_SHA=333ccc" "$OUT"
# …and it must not restart it because of a digest left over from an EARLIER tip.
# Seen live: the gate said "quiet for 417s — proceeding" and the whole-forest
# check restarted the clock at 0s twenty seconds later, because its own `digest`
# key still held the previous tip's reading. The window belongs to the TIP.
rm -rf "$QP/queue"
# 1. an OLD tip is read by both scopes, so both digests are on file
export FAKE_HEADS="test=444ddd"
QM=0 g gate test >/dev/null; QM=0 q check test >/dev/null
# 2. the tip moves. The GATE runs first (that is the pipeline's order) and must
#    clear BOTH readings with the tip, or the whole-forest check that follows
#    seconds later reads its own stale digest as "the forest moved" and restarts
#    a clock the gate has already run. Exactly what happened live: gate
#    "quiet for 417s — proceeding", check "the forest moved" 20 seconds later.
export FAKE_HEADS="test=555eee"
OUT="$(QM=5 g gate test)"
has "a NEW tip starts a fresh window, and says so in those words" "a new tip (555eee)" "$OUT"
python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["since"]="1"; json.dump(d,open(p,"w"))' "$QP/queue/test.json"
OUT="$(q check test)"
hasnt "the whole-forest check does NOT read the previous tip's digest as movement" "the forest moved" "$OUT"
has "  …it proceeds on the tip the gate already timed" "QUIET_SHA=555eee" "$OUT"

# A BACKTICK IN A DOUBLE-QUOTED MESSAGE IS A COMMAND SUBSTITUTION. His doctor run
# on the pipeline device printed `doctor.sh: line 459: partial: command not found`
# and then "the verdict will be  at best" — the word had been EXECUTED and its
# (empty) output substituted. Asserted over every message-bearing script here,
# because the same mistake is invisible on the page and obvious in the terminal.
for F in "$J/doctor.sh" "$J/quiet.sh" "$J/promote.sh" "$J/test-wipe.sh" "$J/selftests.sh" "$J/scan/scan.sh"; do
    TICKS="$(grep -nE '^[^#]*(ok|warn|say|check|_row) +"[^"]*`' "$F" || true)"
    eq "no backtick inside a message string in $(basename "$F") (it would be RUN, not printed)" "" "$TICKS"
done

# ---- THE SECRETS CATALOGUE: names that say what they are FOR, destinations
# that say where they GO, and both derived from what the route actually pushes to.
cat_() { ( cd "$DEV" && env CI_MODE="${CI_MODE:-suite}" CI_ROUTE_TARGET="${CI_ROUTE_TARGET:-}" \
           bash -c 'source ./secrets.sh; '"$1" 2>&1 ) || true; }
has "the release token's destination names the RELEASE POOL" \
    "github.com/dausume/polari-suite/releases" "$(cat_ 'secrets_destination github/release_token')"
has "  …and the homebrew tap it also feeds" "dausume/homebrew-polari" "$(cat_ 'secrets_destination github/release_token')"
has "the registry token's destination names the REGISTRY, and the images" \
    "ghcr.io/dausume (prf-backend, prf-frontend, pol-reticulum)" "$(cat_ 'secrets_destination github/registry_token')"
has "a catalogue line is name — destination — routes — present/absent" \
    "github/release_token — release pool" "$(cat_ 'secrets_catalog_line github/release_token')"
has "  …and it says which routes use it" "routes: github-release, homebrew" "$(cat_ 'secrets_catalog_line github/release_token')"
has "  …and whether it is there" "absent" "$(cat_ 'secrets_catalog_line github/release_token')"
# THE ANTI-DRIFT CHECK: the destination text must equal what the route script
# would actually push to. Both come from routes/destinations.sh, and this proves
# it by deriving the route's own constant the same way the route does.
RREPO="$(cat_ 'dest_release_repo')"; RREG="$(cat_ 'dest_registry_ns')"; RTAP="$(cat_ 'dest_homebrew_tap')"
has "the github-release route pushes to the repo the catalogue names" "$RREPO" "$(cat_ 'secrets_destination github/release_token')"
has "the ghcr route pushes to the registry the catalogue names" "$RREG" "$(cat_ 'secrets_destination github/registry_token')"
has "  …and the route script itself reads that constant, not a literal" "dest_release_repo" "$(cat "$J/routes/github-release.sh")"
has "  …ghcr too" "dest_registry_ns" "$(cat "$J/routes/ghcr.sh")"
has "  …and homebrew" "dest_homebrew_tap" "$(cat "$J/routes/homebrew.sh")"
eq "  …so no ROUTE hard-codes the upstream owner any more (only destinations.sh knows it)" "" \
   "$(grep -l 'dausume' "$J"/routes/*.sh 2>/dev/null | grep -v destinations.sh || true)"
has "  …and the upstream owner itself is declared exactly once" "1" \
    "$(grep -c 'CI_UPSTREAM_OWNER=' "$J"/routes/destinations.sh)"
# APP MODE: the destinations are the DEVELOPER'S, rendered from the device
# settings — a listing must never tell a fork that its token publishes upstream.
APP="$(CI_MODE=app CI_ROUTE_TARGET=some-developer cat_ 'secrets_destination github/registry_token')"
has "app mode: the registry destination is the DEVELOPER'S namespace" "ghcr.io/some-developer" "$APP"
hasnt "  …and never the upstream owner" "dausume" "$APP"
APP2="$(CI_MODE=app CI_ROUTE_TARGET=some-developer cat_ 'secrets_destination github/release_token')"
has "app mode: the release pool is theirs too" "some-developer/polari-suite/releases" "$APP2"

# ---- BACKWARD COMPATIBILITY: a token under its pre-ci-12 name still works,
# and the doctor says so once with the exact rename.
mkdir -p "$DEV/secrets/github" "$DEV/secrets/registries"
printf 'x' > "$DEV/secrets/github/github_token"; chmod 0600 "$DEV/secrets/github/github_token"
eq "a token stored under the OLD name is still FOUND" "0" \
   "$( ( cd "$DEV" && bash -c 'source ./secrets.sh; secrets_have github/release_token' ) >/dev/null 2>&1; echo $?)"
has "  …and the listing says it is present under the old name" "under the OLD name github/github_token" \
    "$(cat_ 'secrets_catalog_line github/release_token')"
has "the doctor WARNs once, naming the exact rename" "secrets mv github/github_token github/release_token" "$(doc)"
hasnt "  …and does NOT print its value" "x-the-value" "$(doc)"
rm -f "$DEV/secrets/github/github_token"
has "with the new names in place the doctor says so instead" "use their ci-12 names" "$(doc)"
has "the route rows name their DESTINATION" "would go to: release pool: github.com/dausume/polari-suite/releases" "$(doc)"
has "  …and the registry row names the images" "prf-backend, prf-frontend, pol-reticulum" "$(doc)"
# the where-to-get-it entries, renamed and with the click path
has "the RELEASE token's how names the click path, not just a URL" "Developer settings" "$(sinfo github/release_token 5)"
has "  …and that it needs BOTH the release repo and the tap" "homebrew-polari" "$(sinfo github/release_token 5)"
has "  …and that it carries no account permissions" "NO account permissions" "$(sinfo github/release_token 5)"
has "the REGISTRY token's how says it must be CLASSIC" "MUST be classic" "$(sinfo github/registry_token 5)"
has "  …and both name GitLab and Gitea as documentation-only examples" "documentation only" "$(sinfo github/registry_token 5)"

# ---- docker-outside-of-docker: `-v` is resolved by the DAEMON, on the HOST.
# The first real scan run pulled every tool, ran it, and produced nothing: the
# controller mounted its OWN /var/polari-pool path, docker created an empty
# directory at that path on the host, and the reports landed where nobody could
# read them. Silent, and it would have looked like "no findings" forever.
HP() { ( cd "$DEV" && env POLARI_POOL=/var/polari-pool JENKINS_HOME=/var/jenkins_home \
         CI_HOST_POOL=/srv/polari/pool CI_HOST_JENKINS_HOME=/srv/polari/jh \
         bash -c 'source ./scan/scan.sh >/dev/null 2>&1; host_path "$1"' _ "$1" 2>/dev/null ) || true; }
eq "scan.sh is SOURCEABLE, so its helpers can be tested at all" "0" \
   "$( ( cd "$DEV" && bash -c 'source ./scan/scan.sh' >/dev/null 2>&1 ); echo $?)"
eq "a pool path is translated to what the HOST calls it" "/srv/polari/pool/test/abc/scan" "$(HP /var/polari-pool/test/abc/scan)"
eq "  …a workspace path too" "/srv/polari/jh/workspace/polari-test" "$(HP /var/jenkins_home/workspace/polari-test)"
eq "  …and anything else is left alone (the scanner also runs on the host)" "/etc/hosts" "$(HP /etc/hosts)"
eq "every -v the scanner issues goes through host_path" "3" "$(grep -c 'v "$(host_path' "$J/scan/scan.sh")"
eq "  …and none is left untranslated" "" \
   "$(grep -nE '\-v "\$(WORK|OUT|POOL)' "$J/scan/scan.sh" || true)"
has "pol jenkins up tells the controller what the host calls those two paths" "CI_HOST_POOL" \
    "$(cat "$J/../polari-cli/scripts/jenkins.sh")"

# ---- reading the pool in the SYSTEM posture: "none" must mean ABSENT, never
# "I may not look". After init-device the pool belongs to polari-ci, and the
# first `promote main` on the pipeline device reported "verdict: none" for a sha
# whose verdict.json existed and said `failed`.
pr() { ( cd "$DEV" && env POLARI_POOL="$1" CI_CONTROLLER_CONTAINER=no-such-container \
         bash -c 'source ./pool.sh; pool_read "$1" || echo UNREADABLE' _ "$2" 2>/dev/null ) || true; }
mkdir -p "$T/readable/test/abc"; printf '{"verdict":"passed"}' > "$T/readable/test/abc/verdict.json"
has "a readable pool is read directly" '"verdict":"passed"' "$(pr "$T/readable" test/abc/verdict.json)"
eq "  …an absent file is UNREADABLE, not an empty success" "UNREADABLE" "$(pr "$T/readable" test/nope/verdict.json)"
has "the unreadable-pool sentence says it may not LOOK, not that nothing is there" "may not read it" \
    "$( ( cd "$DEV" && mkdir -p "$T/locked" && chmod 0000 "$T/locked" && env POLARI_POOL="$T/locked" \
          bash -c 'source ./pool.sh; pool_why_unreadable' 2>/dev/null ); chmod 0755 "$T/locked" 2>/dev/null )"
has "pool.sh reads THROUGH the controller — the pipeline process reading its own pool" "docker exec" "$(cat "$J/pool.sh")"
has "promote.sh uses it rather than cat" "pool_read" "$(cat "$J/promote.sh")"
has "  …and pol jenkins test-status too" "pool_read" "$(cat "$J/../polari-cli/scripts/lib/jenkins-device.sh")"

# ---- a FILE bind mount binds an INODE, and `git pull` writes a new file. The
# container then serves the OLD script while the checkout holds the fix — which
# is exactly what happened on the pipeline device: three runs in a row behaved
# like code that had already been replaced. The doctor now says so.
has "the doctor checks that the container is running THIS checkout's scripts" \
    "controller scripts" "$(cat "$J/doctor.sh")"
has "  …and names the reason, not just the symptom" "binds an inode" "$(cat "$J/doctor.sh")"
has "  …and the fix" "pol jenkins up" "$(cat "$J/doctor.sh")"

# the TIP-not-trigger rule, stated where it is enforced
has "the test pipeline checks out the TIP of test, never the sha that triggered it" \
    "checkout the TIP of test" "$(cat "$J/pipelines/Jenkinsfile.test")"
has "  …and the poll jobs carry the five-minute quiet period" "quietPeriod(300)" "$(cat "$J/jobs/seed.groovy")"
has "  …the polled release job is NOT parameterised, so Jenkins coalesces its queue" \
    "polari-release-manual" "$(cat "$J/jobs/seed.groovy")"

# ---- the turn: test and main alternate, and a yield costs nothing
export FAKE_HEADS="main=999aaa"
q saw main >/dev/null
q turn-done test >/dev/null
eq "turn: test ran last and main is pending → test YIELDS (exit 7), it does not sleep on the lock" "7" \
   "$(qrc turn test --once)"
OUT="$(q turn test --once)"
has "  …and the yield says the pending item is untouched" "the pending item stays" "$OUT"
eq "turn: main's turn is granted at once" "0" "$(qrc turn release --once)"
q turn-done release >/dev/null
eq "turn: with the marker flipped, test goes" "0" "$(qrc turn test --once)"
rm -f "$QP/queue/main.json"
q turn-done test >/dev/null
eq "turn: test ran last but main has NOTHING pending → test goes again (no pointless alternation)" "0" \
   "$(qrc turn test --once)"
OUT="$(q queue)"
has "pol jenkins queue prints both queues" "test" "$OUT"
has "  …and states the rule in words" "latest wins" "$OUT"

# ---- promote: the refusals
PSUITE="$T/psuite"; mkdir -p "$PSUITE/polari-cli/shells" "$PSUITE/polari-jenkins"
cp "$DEV/promote.sh" "$DEV/pool.sh" "$PSUITE/polari-jenkins/"
cat > "$PSUITE/polari-cli/shells/push-all-dev.sh" <<'SH'
#!/bin/bash
# the sweep, stubbed: it records the arguments it was given and writes the marker
echo "SWEEP $*" >> "${SWEEP_LOG:-/dev/null}"
while [ $# -gt 0 ]; do case "$1" in --summary-json) OUT="$2"; shift ;; esac; shift; done
[ -n "${OUT:-}" ] && printf '{"branch":"test","repos":{".":"%s"},"superproject":"%s"}\n' \
    "${FAKE_SUPER:-aaa111}" "${FAKE_SUPER:-aaa111}" > "$OUT"
exit "${SWEEP_RC:-0}"
SH
chmod +x "$PSUITE/polari-cli/shells/push-all-dev.sh"
PPOOL="$T/ppool"; rm -rf "$PPOOL"; mkdir -p "$PPOOL"
pro() { ( cd "$PSUITE/polari-jenkins" && env POLARI_POOL="$PPOOL" PATH="$T/bin:$PATH" \
          FAKE_HEADS="$FAKE_HEADS" SWEEP_LOG="$T/sweep.log" bash promote.sh "$@" 2>&1 ) || true; }
prorc(){ ( cd "$PSUITE/polari-jenkins" && env POLARI_POOL="$PPOOL" PATH="$T/bin:$PATH" \
          FAKE_HEADS="$FAKE_HEADS" SWEEP_LOG="$T/sweep.log" bash promote.sh "$@" >/dev/null 2>&1 ); echo "$?"; }

: > "$T/sweep.log"
export FAKE_HEADS="dev=aaa111 test=aaa111 main=000000"
OUT="$(pro test --dry-run)"
has "promote test: the sweep is asked for dev → test, ff-only" "dev → test" "$OUT"
has "  …by the ONE sweep, given a --promote-from parameter (not a copy of it)" "--promote-from dev" "$(cat "$T/sweep.log")"
hasnt "  …and a dry run does not push" "--push" "$(cat "$T/sweep.log")"

: > "$T/sweep.log"
pro test >/dev/null || true
has "promote test (for real): the sweep is told to push" "--push" "$(cat "$T/sweep.log")"
[ -f "$PPOOL/promotions/test/aaa111.json" ] && ok "  …and the PROMOTION MARKER is written for the superproject sha" \
    || bad "  …and the PROMOTION MARKER is written for the superproject sha" "$PPOOL/promotions/test/aaa111.json" "absent"

eq "promote main: NO verdict for the tip of test → REFUSED (exit 4)" "4" "$(prorc main --dry-run)"
OUT="$(pro main --dry-run)"
has "  …and the refusal names the sha" "aaa111" "$OUT"
has "  …and says what to do instead" "push to test" "$OUT"
mkdir -p "$PPOOL/test/aaa111"
cp "$VD/partial/verdict.json" "$PPOOL/test/aaa111/verdict.json"
eq "promote main: a PARTIAL verdict → still REFUSED" "4" "$(prorc main --dry-run)"
has "  …and it repeats the verdict's own reason, not a generic one" "ci-3" "$(pro main --dry-run)"
OUT="$(pro main --dry-run --force-untested)"
has "promote main --force-untested: it proceeds, LOUDLY" "FORCING AN UNTESTED PROMOTION" "$OUT"
has "  …naming the sha and the verdict it is overriding" "verdict: partial" "$OUT"
cp "$VD/pass/verdict.json" "$PPOOL/test/aaa111/verdict.json"
eq "promote main: a PASSED verdict → it proceeds" "0" "$(prorc main --dry-run)"
: > "$T/sweep.log"; pro main --dry-run >/dev/null
has "  …and the sweep is asked for test → main" "--promote-from test" "$(cat "$T/sweep.log")"
export FAKE_HEADS="dev=aaa111 main=000000"
eq "promote main: with no origin/test at all → refused, and not with the verdict message" "3" "$(prorc main --dry-run)"
export FAKE_HEADS="dev=aaa111 test=aaa111 main=000000"
OUT="$( cd "$PSUITE/polari-jenkins" && env POLARI_POOL="$PPOOL" PATH="$T/bin:$PATH" \
    FAKE_HEADS="$FAKE_HEADS" SWEEP_RC=1 bash promote.sh test --dry-run 2>&1 || true )"
has "promote: a sweep that refuses (a repo is not ff-able) stops the promotion and says so" "did NOT complete" "$OUT"

# the sweep's own ff-only rule and its stop-at-the-first-bad-repo behaviour
SWEEPSRC="$(cat "$J/../polari-cli/shells/push-all-dev.sh")"
has "the sweep refuses a non-fast-forward and NAMES the repo" "NOT fast-forwardable" "$SWEEPSRC"
has "  …and stops there, innermost-first, so nothing outside it has moved" "nothing after it was touched" "$SWEEPSRC"
has "  …it moves the ref without switching the working tree" "git fetch . " "$SWEEPSRC"
has "  …and it is ONE sweep with a --branch parameter, not a copy" "--promote-from" "$SWEEPSRC"

# ---- retention must not eat the branch model's state
RP="$T/rpool"; rm -rf "$RP"; mkdir -p "$RP/test/abc" "$RP/promotions/test" "$RP/queue" "$RP/cache" \
    "$RP/2026.01.01" "$RP/2026.01.02" "$RP/2026.01.03" "$RP/2026.01.04"
printf '{"verdict": "passed"}' > "$RP/test/abc/verdict.json"
OUT="$( cd "$DEV" && env POLARI_POOL="$RP" POOL_KEEP=2 bash retention.sh prune 2>&1 )" || true
has "retention: test/, promotions/ and queue/ are EXEMPT — none of them is a version" "EXEMPT" "$OUT"
[ -f "$RP/test/abc/verdict.json" ] && ok "  …and a verdict survives a prune (deleting one would un-test a released sha)" \
    || bad "  …and a verdict survives a prune" "the verdict file" "gone"
[ -d "$RP/cache" ] && ok "  …the ci-9 cache still survives too" || bad "  …the ci-9 cache still survives too" "cache/" "gone"
eq "  …while real old versions ARE still dropped (4 versions, POOL_KEEP=2)" "2" \
   "$(ls -1d "$RP"/2026.* 2>/dev/null | wc -l | tr -d ' ')"

# ---- the wipe: what it removes, and what it must never remove
WIPESRC="$(cat "$J/test-wipe.sh")"
has "the wipe removes the :staging images this device built" "docker image rm" "$WIPESRC"
has "  …and explicitly does NOT remove the offline cache, with the reason" "NOT touched" "$WIPESRC"
has "  …it takes the leak baseline the isle stages diff against" "leakcheck.sh\" baseline" "$WIPESRC"
has "  …and every step is non-fatal: a wipe that failed a run would make the verdict about the wipe" "exit 0" "$WIPESRC"

# ---- the module selftests: one invocation, not a second one
STSRC="$(cat "$J/selftests.sh")"
has "the module selftests reuse pol modules selftest's OWN discovery expression" "_selftest.py" "$STSRC"
has "  …run in the image the build just made, not against a running stack" "docker run --rm" "$STSRC"
has "  …a module with no suite records 'skipped', and skipped is NOT a pass" "which is NOT a pass" "$STSRC"

# ---- the two pipelines are two pipelines, and the release one runs no tests
RELSRC="$(cat "$J/pipelines/Jenkinsfile.release")"
hasnt "polari-release no longer triggers polari-isle-test — results are carried over, not re-run" \
    "build job: 'polari-isle-test'" "$RELSRC"
has "  …it reads pool/test/<sha>/verdict.json instead" "test/\${env.POLARI_FULL_SHA}/verdict.json" "$RELSRC"
has "  …and a sha with no verdict is told to go through test first" "promote test" "$RELSRC"
has "polari-isle-test locks the ISLE TARGET, not polari-build (its caller holds that lock)" \
    "polari-isle-target" "$(cat "$J/pipelines/Jenkinsfile.isle-test")"
has "polari-dev-build's description says it is the OPTIONAL quick build: no tests, no scans, no publish" \
    "NO isle tests, NO scans, NO publish" "$(cat "$J/jobs/seed.groovy")"

echo
TOTAL=$((PASS+FAIL))
echo "$PASS/$TOTAL"
[ "$FAIL" = 0 ] || exit 1
