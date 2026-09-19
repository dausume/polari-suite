#!/bin/bash
# polari-jenkins/isle/preflight.sh — (A) of ci-7: BEFORE the pipeline that
# creates a throwaway isle touches anything, prove the device is CLEAR and
# has room. Every check is one row:  check | value | floor | verdict.
#
#   preflight.sh [--isle] [--json] [--help]
#     --isle   also check the throwaway-VM requirements (KVM, nested, the
#              VM's RAM/disk, the tools, and that the device carries no
#              Polari footprint of its own)
#     --json   machine-readable, for the pipeline stage
#
# ⚠ This is a RESOURCE GUARD, not a security gate. It refuses a run that
#   would run the device out of memory or disk, or that would create a
#   throwaway isle on a device that is somebody's real one. It grants no
#   authority, changes no posture, and installs nothing.
#
# exit 0 = every check PASS/WARN · exit 4 = at least one FAIL
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
J="$(cd "$HERE/.." && pwd)"
# shellcheck source=../device.sh
source "$J/device.sh"
# shellcheck source=footprint.sh
source "$HERE/footprint.sh"

ISLE=0; JSON=0
while [ $# -gt 0 ]; do
    case "$1" in
        --isle) ISLE=1 ;;
        --json) JSON=1 ;;
        --help|-h) sed -n '2,16p' "$0"; exit 0 ;;
        *) echo "preflight.sh: unknown argument '$1' (--isle --json --help)" >&2; exit 2 ;;
    esac; shift
done

ROWS=(); FAILS=0; WARNS=0
row() {  # row <check> <value> <floor> <verdict> [note]
    ROWS+=("$1|$2|$3|$4|${5:-}")
    case "$4" in FAIL) FAILS=$((FAILS+1)) ;; WARN) WARNS=$((WARNS+1)) ;; esac
}
# verdict from a "have >= want" comparison
cmp_row() { # cmp_row <check> <have> <want> <unit> [FAIL|WARN when short]
    local have="$2" want="$3" u="$4" bad="${5:-FAIL}"
    case "$have" in ''|*[!0-9]*) have="" ;; esac      # a non-numeric reading is unknown, not an arithmetic crash
    if [ -z "$have" ]; then row "$1" "unknown" "$want$u" "$bad" "could not read it on the target"
    elif [ "$have" -ge "$want" ]; then row "$1" "$have$u" "$want$u" PASS ""
    else row "$1" "$have$u" "$want$u" "$bad" "short by $((want-have))$u"; fi
}

TARGET_DESC="$(device_target_name)"
POOL_TARGET="$(device_pool)"

# ---------------------------------------------------------------- 1. reach
REACHABLE=0
if [ "$CI_ISLE_TARGET" = local ]; then
    REACHABLE=1; row "target reachable" "local" "-" PASS "the pipeline device is the isle device"
elif [ -z "$CI_ISLE_SSH_HOST" ]; then
    row "target reachable" "no alias" "-" FAIL "CI_ISLE_TARGET=ssh with no CI_ISLE_SSH_HOST — pol jenkins target ssh <alias>"
else
    if out=$(on_target 'echo reachable' 2>&1) && [ "$out" = reachable ]; then
        REACHABLE=1; row "target reachable" "$(device_ssh_dest)" "-" PASS "ssh BatchMode"
        if on_target 'sudo -n true' >/dev/null 2>&1; then row "target sudo -n" "yes" "yes" PASS ""
        else row "target sudo -n" "no" "yes" FAIL "libvirt needs passwordless sudo on the target for the pipeline (no prompt exists in a job)"; fi
    else
        row "target reachable" "$(device_ssh_dest)" "-" FAIL "ssh -o BatchMode=yes failed: ${out//$'\n'/ }"
    fi
fi

# ------------------------------------------------------- 2. the pool floor
if [ -x "$J/retention.sh" ]; then
    if guard=$(POLARI_POOL="${POLARI_POOL:-$J/pool}" DISK_MIN_FREE_GB="$CI_MIN_FREE_GB" bash "$J/retention.sh" guard 2>&1); then
        row "pool free (retention guard)" "$(echo "$guard" | grep -oE '[0-9]+ GB' | head -1)" "${CI_MIN_FREE_GB}GB" PASS ""
    else
        row "pool free (retention guard)" "$(echo "$guard" | grep -oE 'only [0-9]+ GB' | head -1)" "${CI_MIN_FREE_GB}GB" FAIL "retention.sh prune, or raise CI_MIN_FREE_GB knowingly"
    fi
else
    row "pool free (retention guard)" "retention.sh missing" "-" WARN "polari-jenkins/retention.sh is not executable"
fi

# ------------------------------------------- 3. the throwaway-isle checks
if [ "$ISLE" = 1 ] && [ "$REACHABLE" = 1 ]; then
    # /dev/kvm
    if on_target '[ -e /dev/kvm ]' >/dev/null 2>&1; then row "/dev/kvm on the target" "present" "present" PASS ""
    else row "/dev/kvm on the target" "absent" "present" FAIL "no hardware virtualisation on $TARGET_DESC — choose another device: pol jenkins target ssh <alias>"; fi

    # nested KVM (the isle's router guest runs inside the throwaway VM)
    NESTED=$(on_target 'cat /sys/module/kvm_intel/parameters/nested /sys/module/kvm_amd/parameters/nested 2>/dev/null | head -1' 2>/dev/null || true)
    case "$CI_ISLE_NESTED" in
        off) row "nested KVM" "not checked" "-" PASS "CI_ISLE_NESTED=off — no router guest in this run" ;;
        required|auto)
            want=FAIL; [ "$CI_ISLE_NESTED" = auto ] && [ "$CI_ISLE_TARGET" != local ] && want=WARN
            case "$NESTED" in
                Y|1) row "nested KVM" "$NESTED" "Y" PASS "the isle's router guest can run inside the throwaway VM" ;;
                N|0) row "nested KVM" "$NESTED" "Y" "$want" "enable it: options kvm_intel nested=1 (or kvm_amd) in /etc/modprobe.d, then reload the module" ;;
                *)   row "nested KVM" "unreadable" "Y" "$want" "no kvm_intel/kvm_amd module parameter on the target" ;;
            esac ;;
    esac

    # RAM
    AVAIL_MB=$(on_target "awk '/MemAvailable/{print int(\$2/1024)}' /proc/meminfo" 2>/dev/null || true)
    AVAIL_GB=$([ -n "$AVAIL_MB" ] && echo $((AVAIL_MB/1024)) || echo "")
    WANT_RAM=$((CI_ISLE_VM_RAM_GB + CI_MIN_RAM_HEADROOM_GB))
    # everything is serialised on ONE device: the controller and the build
    # share the RAM with the VM only when the isle target is this machine.
    [ "$CI_ISLE_TARGET" = local ] && WANT_RAM=$((WANT_RAM + CI_CONTROLLER_RAM_GB + CI_BUILD_RAM_GB))
    cmp_row "free RAM on the target" "$AVAIL_GB" "$WANT_RAM" "GB" FAIL
    [ "$CI_ISLE_TARGET" = local ] && row "  RAM budget" "VM ${CI_ISLE_VM_RAM_GB} + controller ${CI_CONTROLLER_RAM_GB} + build ${CI_BUILD_RAM_GB} + headroom ${CI_MIN_RAM_HEADROOM_GB}" "${WANT_RAM}GB" PASS "serialised on one device" || true

    # disk on the libvirt image dir
    IMGDIR=$(on_target 'for d in /var/lib/libvirt/images /var/lib/libvirt; do [ -d "$d" ] && { echo "$d"; break; }; done' 2>/dev/null || true)
    [ -n "$IMGDIR" ] || IMGDIR="$POOL_TARGET"
    FREE_GB=$(on_target "df -BG --output=avail '$IMGDIR' 2>/dev/null | tail -1 | tr -dc '0-9'" 2>/dev/null || true)
    cmp_row "free disk on $IMGDIR" "$FREE_GB" "$((CI_ISLE_VM_DISK_GB + CI_MIN_FREE_GB))" "GB" FAIL

    # tools
    for t in virt-install qemu-img virsh; do
        if on_target "command -v $t >/dev/null" >/dev/null 2>&1; then row "$t on the target" "present" "present" PASS ""
        else row "$t on the target" "absent" "present" FAIL "install libvirt/qemu on $TARGET_DESC (this script installs nothing)"; fi
    done
    if on_target 'command -v cloud-localds >/dev/null || command -v genisoimage >/dev/null || command -v mkisofs >/dev/null' >/dev/null 2>&1; then
        row "cloud-init seed tool" "present" "cloud-localds or genisoimage" PASS ""
    else
        row "cloud-init seed tool" "absent" "cloud-localds or genisoimage" FAIL "install cloud-image-utils (or genisoimage) on $TARGET_DESC"
    fi

    # ------------------------------------------------- the device is CLEAR
    # (i) no VM by our name already
    EXISTING=$(on_target "sudo -n virsh list --all --name 2>/dev/null || virsh list --all --name 2>/dev/null" 2>/dev/null | grep -Fx "$CI_ISLE_VM_NAME" || true)
    if [ -z "$EXISTING" ]; then row "no VM named $CI_ISLE_VM_NAME" "none" "none" PASS ""
    else row "no VM named $CI_ISLE_VM_NAME" "EXISTS" "none" FAIL "a previous run did not clean up → isle/throwaway.sh down"; fi

    # (i-b) ci-10: RESIDUE from an earlier run — anything carrying our own tag,
    #       not just a domain by our name. A disk, a network, a qemu process or
    #       a /tmp tree left behind is the start of the "memory issues" his ask
    #       names: every stage would then start on a dirtier device than the last.
    WIPE_TAG="${CI_WIPE_TAG:-polari-ci-}"
    RESIDUE=$(on_target "
        : ci-10 residue probe
        S=''; sudo -n true >/dev/null 2>&1 && S='sudo -n'
        { \$S virsh list --all --name 2>/dev/null; \$S virsh net-list --all --name 2>/dev/null; } \
            | grep -E '^${WIPE_TAG}' | sed 's/^/vm-or-net:/'
        for d in /var/lib/libvirt/images /tmp /var/tmp; do
            [ -d \"\$d\" ] || continue
            for f in \"\$d/${WIPE_TAG}\"*; do
                [ -e \"\$f\" ] || continue
                # the POOL and the offline cache carry the tag by design and are
                # NOT residue (found live on isle-core 2026-09-19, where
                # /var/tmp/polari-ci-pool read as leftovers from a past run)
                case \"\$f\" in '$POOL_TARGET'|'$POOL_TARGET'/*) continue ;; esac
                echo \"file:\$f\"
            done
        done
        # ⚠ this probe's OWN command line carries both 'qemu-system' and the tag,
        # so it matches itself unless it is filtered out by its marker.
        ps -eo args= 2>/dev/null | grep -F 'qemu-system' | grep -v 'ci-10 residue probe' \
            | grep -E 'guest=${WIPE_TAG}|${WIPE_TAG}' | sed 's/^/process:qemu /' | cut -c1-60
    " 2>/dev/null | sed '/^$/d' || true)
    if [ -z "$RESIDUE" ]; then
        row "residue from an earlier run" "none" "none" PASS "nothing on the target carries the ${WIPE_TAG} tag"
    else
        row "residue from an earlier run" "$(printf '%s' "$RESIDUE" | wc -l | tr -d ' ') item(s)" "none" FAIL \
            "an earlier run left ${WIPE_TAG} things behind → run \`pol jenkins isle wipe\` (\`--dry-run\` lists first). Found: $(printf '%s' "$RESIDUE" | tr '\n' ' ')"
    fi

    # (ii) no Polari/isle footprint at all — a device that is somebody's
    #      live isle is not a throwaway. os-security/inventory.sh is the
    #      one reading of "what Polari put on this machine".
    FOOT=$(target_footprint || true)
    if [ -z "$FOOT" ]; then
        row "device is clear of Polari" "nothing installed" "nothing" PASS ""
    elif [ "$FOOT" = "unreadable" ]; then
        row "device is clear of Polari" "inventory unreadable" "nothing" WARN "os-security/inventory.sh did not produce JSON on $TARGET_DESC"
    elif [ "$CI_ISLE_TARGET" = local ]; then
        row "device is clear of Polari" "NOT clear" "nothing" WARN "this is the pipeline device itself — a local throwaway VM coexists, but the VM name must stay unique. Found: $FOOT"
    else
        row "device is clear of Polari" "NOT clear" "nothing" FAIL "$TARGET_DESC carries a real Polari/isle installation — a throwaway run would fight it; pick an empty device. Found: $FOOT"
    fi
elif [ "$ISLE" = 1 ]; then
    row "throwaway-isle checks" "skipped" "-" FAIL "the target is not reachable — nothing below it could be read"
fi

# ------------------------------------------------------------------ report
if [ "$JSON" = 1 ]; then
    { printf '%s\n' "$TARGET_DESC" "$CI_ISLE_TARGET" "$CI_ISLE_VM_NAME" "$FAILS" "$WARNS" "$ISLE"; printf '%s\n' "${ROWS[@]:-}"; } | python3 -c '
import json, sys
L = sys.stdin.read().split("\n")
tgt, mode, vm, fails, warns, isle = L[0], L[1], L[2], int(L[3]), int(L[4]), L[5] == "1"
rows = []
for l in L[6:]:
    if not l.strip(): continue
    f = (l.split("|") + [""] * 5)[:5]
    rows.append(dict(zip(("check", "value", "floor", "verdict", "note"), f)))
print(json.dumps({"protocol": "polari-pipeline-preflight/1",
                  "kind": "resource-guard", "target": tgt, "mode": mode, "vm": vm,
                  "isle_checks": isle, "fails": fails, "warns": warns,
                  "verdict": "FAIL" if fails else ("WARN" if warns else "PASS"),
                  "rows": rows}, indent=1))'
else
    echo "polari-jenkins preflight — RESOURCE GUARD (not a security gate): it refuses a run"
    echo "that would exhaust the device or build a throwaway isle on a device that has a real one."
    echo "target: $TARGET_DESC   vm: $CI_ISLE_VM_NAME ${CI_ISLE_VM_RAM_GB}GB/${CI_ISLE_VM_VCPUS}vcpu/${CI_ISLE_VM_DISK_GB}GB   isle checks: $([ "$ISLE" = 1 ] && echo on || echo 'off (--isle)')"
    echo
    printf '%-34s %-22s %-12s %s\n' "check" "value" "floor" "verdict"
    printf '%-34s %-22s %-12s %s\n' "----------------------------------" "----------------------" "------------" "-------"
    for r in "${ROWS[@]:-}"; do
        IFS='|' read -r c v f vd n <<<"$r"
        printf '%-34s %-22s %-12s %s\n' "$c" "$v" "$f" "$vd"
        [ -n "$n" ] && printf '%-34s %s\n' "" "  ↳ $n" || true
    done
    echo
    if [ "$FAILS" -gt 0 ]; then echo "REFUSED: $FAILS check(s) FAIL, $WARNS warn — fix the rows above (exit 4)"
    elif [ "$WARNS" -gt 0 ]; then echo "clear to run, with $WARNS warning(s)"
    else echo "clear to run"; fi
fi
[ "$FAILS" -gt 0 ] && exit 4 || exit 0
