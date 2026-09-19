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
      "$J/setup" "$J/isle" "$J/routes" "$J/casc" "$J/docker-compose.yml" "$J/.env.example" "$J/device.env.example" "$DEV/"
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
mkdir -p "$T/pool/isle-test"; printf '{"components":{"superproject":{"sha":"deadbee"}},"publishedTo":{}}' > "$T/pool/release.json"
# the release rule gates every route, so the arming cases need a version the
# isle test passed; the rule itself is section 6.
printf '{"version":"1","core_ok":true,"passed":["gears"],"untested":[],"tested":["gears"]}' > "$T/pool/isle-test/results.json"
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
has "github_token names the fine-grained token page" "settings/personal-access-tokens" "$(sinfo github/github_token 4)"
has "  …and the exact permission"                    "Contents: Read and write"        "$(sinfo github/github_token 5)"
has "ghcr_token says CLASSIC + write:packages"       "write:packages"                  "$(sinfo registries/ghcr_token 5)"
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

# the release rule, read by routes/_lib.sh
RES="$T/pool/isle-test/results.json"
gate() { ( cd "$DEV/routes" && env -u GITHUB_TOKEN VERSION=1 POOL_DIR="$T/pool" GITHUB_TOKEN=x CI_ROUTES=github-release \
           bash -c 'source ./_lib.sh; ROUTE=github-release; arm GITHUB_TOKEN:github/github_token' 2>&1 ) || true; }
mkdir -p "$T/pool/debs"; : > "$T/pool/debs/polari-complete_1_all.deb"
: > "$T/pool/debs/polari-app-household_1_all.deb"; : > "$T/pool/debs/polari-app-gears_1_all.deb"
printf '{"version":"1","core_ok":true,"passed":["gears"],"tested":["gears","household"],"untested":["household"]}' > "$RES"
has "core_ok + secret + CI_ROUTES → ARMED"        "ARMED"                              "$(gate)"
has "  …an app that did not pass is held back"    "not released: untested/failed"      "$(gate)"
has "  …naming that app's deb"                    "polari-app-household_1_all.deb"     "$(gate)"
hasnt "  …and NOT the app that passed"            "polari-app-gears_1_all.deb (untested" "$(gate)"
printf '{"version":"1","core_ok":false,"passed":[],"tested":[],"untested":[]}' > "$RES"
has "core_ok false → DRY, whatever the secrets"   "did not record core_ok"             "$(gate)"
rm -f "$RES"
has "no results file at all → DRY, naming why"    "no isle-test results for 1"         "$(gate)"
has "  …and the wording is his rule, verbatim"    "only releases what it tested"       "$(gate)"
FORCED=$( cd "$DEV/routes" && env VERSION=1 POOL_DIR="$T/pool" GITHUB_TOKEN=x DRY_RUN=false CI_ROUTES=github-release \
          bash -c 'source ./_lib.sh; ROUTE=github-release; arm GITHUB_TOKEN:github/github_token' 2>&1 || true )
has "the rule is HARD: DRY_RUN=false cannot force it" "DRY (no isle-test results"      "$FORCED"
printf '{"version":"1","core_ok":true,"passed":["gears"],"tested":["gears","household"],"untested":["household"]}' > "$RES"
assets() { ( cd "$DEV/routes" && env VERSION=1 POOL_DIR="$T/pool" bash -c 'source ./_lib.sh; release_assets "$POOL_DIR/debs"' 2>/dev/null ) || true; }
has "the core deb is always an asset"             "polari-complete_1_all.deb"          "$(assets)"
has "  …a passed app deb is an asset"             "polari-app-gears_1_all.deb"         "$(assets)"
hasnt "  …an untested app deb is not"             "polari-app-household"               "$(assets)"

echo
TOTAL=$((PASS+FAIL))
echo "$PASS/$TOTAL"
[ "$FAIL" = 0 ] || exit 1
