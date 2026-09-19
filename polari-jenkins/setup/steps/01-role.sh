#!/bin/bash
# setup/steps/01-role.sh — "what can THIS device be?"
#
# The pipeline has two jobs that want very different machines:
#   · the PIPELINE DEVICE — the Jenkins controller, the builds, the scans
#     and the publish routes. Measured: the controller image is capped at
#     2 GB (docker-compose.yml mem_limit), an Angular frontend build wants
#     ~3 GB, and they are serialised (CI_EXECUTORS=1), so ~5 GB of RAM.
#   · the THROWAWAY-ISLE TARGET — a VM that is created, installed into,
#     tested and destroyed: 4 GB / 2 vCPU / 30 GB by default, and it needs
#     /dev/kvm plus NESTED KVM (the isle's own router guest runs inside it).
# One device can be both — if it has the RAM for both at once.
#
# setup_role_fit is PURE arithmetic (the selftest drives it directly).

STEP_TITLE_role="this device's role"

setup_role_fit() {
    # setup_role_fit <ram_mb> <cpus> <free_gb> <kvm 0|1> <vm_ram_gb> <vm_disk_gb> <ctrl_gb> <build_gb> <headroom_gb> <min_free_gb>
    # prints: role<TAB>yes|no<TAB>reason
    local ram=$1 cpus=$2 free=$3 kvm=$4 vmram=$5 vmdisk=$6 ctrl=$7 build=$8 head=$9 minfree=${10}
    local need_ctrl=$((ctrl * 1024)) need_build=$(((ctrl + build) * 1024))
    local need_both=$(((ctrl + build + vmram + head) * 1024)) need_alone=$(((vmram + head) * 1024))
    local disk_both=$((minfree + vmdisk)) disk_alone=$((vmdisk + minfree))

    if [ "$ram" -ge "$need_ctrl" ]; then printf 'controller\tyes\tthe controller is capped at %s GB\n' "$ctrl"
    else printf 'controller\tno\tless than %s GB of RAM\n' "$ctrl"; fi

    if [ "$ram" -ge "$need_build" ]; then printf 'builds\tyes\tcontroller %s GB + one build ~%s GB, serialised\n' "$ctrl" "$build"
    else printf 'builds\tno\ta frontend build wants ~%s GB on top of the controller (%s GB total)\n' "$build" "$((ctrl + build))"; fi

    if [ "$kvm" != 1 ]; then printf 'isle-here\tno\tno /dev/kvm on this machine\n'
    elif [ "$ram" -lt "$need_both" ]; then printf 'isle-here\tno\t%s GB needed for controller+build+VM+headroom, this machine has %s GB\n' "$((need_both / 1024))" "$((ram / 1024))"
    elif [ "$free" -lt "$disk_both" ]; then printf 'isle-here\tno\t%s GB of free disk needed (VM %s + pool floor %s)\n' "$disk_both" "$vmdisk" "$minfree"
    else printf 'isle-here\tyes\tRAM and disk for the controller, a build AND the VM at once\n'; fi

    if [ "$kvm" != 1 ]; then printf 'isle-only\tno\tno /dev/kvm on this machine\n'
    elif [ "$ram" -lt "$need_alone" ]; then printf 'isle-only\tno\tthe VM alone wants %s GB\n' "$((need_alone / 1024))"
    elif [ "$free" -lt "$disk_alone" ]; then printf 'isle-only\tno\tthe VM alone wants %s GB of free disk\n' "$disk_alone"
    else printf 'isle-only\tyes\tas a dedicated isle target for another device'\''s controller\n'; fi
}

setup_role_headline() {   # same arguments; one sentence
    local fit; fit="$(setup_role_fit "$@")"
    local ram=$1 cpus=$2 free=$3 c b h o
    c=$(printf '%s' "$fit" | awk -F'\t' '$1=="controller"{print $2}')
    b=$(printf '%s' "$fit" | awk -F'\t' '$1=="builds"{print $2}')
    h=$(printf '%s' "$fit" | awk -F'\t' '$1=="isle-here"{print $2}')
    o=$(printf '%s' "$fit" | awk -F'\t' '$1=="isle-only"{print $2}')
    local gb; gb=$(awk -v m="$ram" 'BEGIN{printf "%.1f", m/1024}')
    local verdict
    if   [ "$h" = yes ]; then verdict="controller + builds + a concurrent throwaway isle — this one device can be the whole pipeline"
    elif [ "$b" = yes ] && [ "$o" = yes ]; then verdict="controller + builds serialised — not a concurrent isle VM. It could host the isle on its own, but not while a build runs; put the isle on another device (pol jenkins target ssh <alias>) or add RAM"
    elif [ "$b" = yes ]; then verdict="controller + builds serialised — not a concurrent isle VM; put the isle on another device (pol jenkins target ssh <alias>) or add RAM"
    elif [ "$o" = yes ]; then verdict="a throwaway-isle TARGET only — too little RAM to also build here"
    elif [ "$c" = yes ]; then verdict="the controller only — a frontend build will not fit; build elsewhere or add RAM"
    else verdict="neither role: even the controller wants more than this"; fi
    printf '%s GB RAM, %s vCPU, %s GB free: %s\n' "$gb" "$cpus" "$free" "$verdict"
}

_role_readings() {   # RAM_MB CPUS FREE_GB KVM NESTED
    ROLE_RAM_MB=$(awk '/MemTotal/{print int($2/1024)}' /proc/meminfo 2>/dev/null || echo 0)
    ROLE_CPUS=$(nproc 2>/dev/null || echo 1)
    ROLE_FREE_GB=$(df -BG --output=avail "$J" 2>/dev/null | tail -1 | tr -dc '0-9' || echo 0)
    [ -n "$ROLE_FREE_GB" ] || ROLE_FREE_GB=0
    ROLE_KVM=0; [ -e /dev/kvm ] && ROLE_KVM=1
    ROLE_NESTED=$(cat /sys/module/kvm_intel/parameters/nested /sys/module/kvm_amd/parameters/nested 2>/dev/null | head -1 || true)
    [ -n "$ROLE_NESTED" ] || ROLE_NESTED=unreadable
}

step_role_check() {
    _role_readings
    local head fit
    head="$(setup_role_headline "$ROLE_RAM_MB" "$ROLE_CPUS" "$ROLE_FREE_GB" "$ROLE_KVM" \
             "$CI_ISLE_VM_RAM_GB" "$CI_ISLE_VM_DISK_GB" "$CI_CONTROLLER_RAM_GB" "$CI_BUILD_RAM_GB" \
             "$CI_MIN_RAM_HEADROOM_GB" "$CI_MIN_FREE_GB")"
    fit="$(setup_role_fit "$ROLE_RAM_MB" "$ROLE_CPUS" "$ROLE_FREE_GB" "$ROLE_KVM" \
             "$CI_ISLE_VM_RAM_GB" "$CI_ISLE_VM_DISK_GB" "$CI_CONTROLLER_RAM_GB" "$CI_BUILD_RAM_GB" \
             "$CI_MIN_RAM_HEADROOM_GB" "$CI_MIN_FREE_GB")"
    check OK "measured here: $head"
    printf '%s\n' "$fit" | while IFS=$'\t' read -r role yn why; do
        [ -n "$role" ] || continue
        [ "$yn" = yes ] && check OK "$role: yes — $why" || check MISS "$role: no — $why"
    done
    check "$([ "$ROLE_NESTED" = Y ] || [ "$ROLE_NESTED" = 1 ] && echo OK || echo MISS)" \
          "nested KVM: $ROLE_NESTED (the isle's router guest runs INSIDE the throwaway VM)"

    if printf '%s' "$fit" | grep -q '^builds	yes'; then
        state done "$head"
    else
        state todo "$head"
        todo "this machine cannot serialise the controller and a build (${CI_CONTROLLER_RAM_GB}+${CI_BUILD_RAM_GB} GB)" \
             "add RAM, or run the controller on a bigger device"
    fi
    # the "where does the isle go" to-do belongs to step 5, which owns the
    # choice — this step only measures and says which roles fit.
}

step_role_do() {
    explain "Two roles, and one device can hold both if it has the room.

PIPELINE DEVICE — the Jenkins controller, the builds, the scans and the publish routes. Measured: the controller is capped at ${CI_CONTROLLER_RAM_GB} GB (compose mem_limit), an Angular frontend build wants ~${CI_BUILD_RAM_GB} GB, and only one build runs at a time (CI_EXECUTORS=1). Nothing inbound is ever opened: the UI binds 127.0.0.1 and every publish is an outbound push.

THROWAWAY-ISLE TARGET — a VM created, installed into, tested and destroyed for every isle-test stage: ${CI_ISLE_VM_RAM_GB} GB / ${CI_ISLE_VM_VCPUS} vCPU / ${CI_ISLE_VM_DISK_GB} GB, needing /dev/kvm AND nested KVM (the isle boots its own router guest inside that VM).

This step only reads and reports — it changes nothing. Step $(step_index isle) is where you choose where the isle goes."
    echo
    step_role_check
}
