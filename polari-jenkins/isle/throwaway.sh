#!/bin/bash
# polari-jenkins/isle/throwaway.sh — the THROWAWAY isle VM: one script for
# both targets. `CI_ISLE_TARGET=ssh` copies this same script to the target
# and runs it there with the configuration exported, so there is exactly
# one implementation of "make a VM, prove it, destroy it".
#
#   throwaway.sh up        create it (idempotent — an existing one is reported, not rebuilt)
#   throwaway.sh verify    ssh into the guest: hostname, nproc, memory, disk
#   throwaway.sh down      destroy + undefine + delete the disk AND the per-run key
#   throwaway.sh status    what exists right now
#
# Everything it makes lives under ONE directory (<pool>/ci-isle/<vm>/) and
# `down` removes that directory: the VM, its disk, its cloud-init seed and
# the ssh key generated for this run. The key is generated PER RUN, kept
# 0600 under the pool, and is the only way into the guest — no password,
# no shared key, nothing that outlives `down`.
#
# It installs nothing. isle/preflight.sh says when libvirt/qemu is missing.
# The deb-install → core-install → verify → uninstall cycle is ci-3 and is
# NOT here (see the TODO in pipelines/Jenkinsfile.isle-test).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
J="$(cd "$HERE/.." && pwd)"
# shellcheck source=../device.sh
source "$J/device.sh"

CMD="${1:-status}"
case "$CMD" in
    up|verify|down|status) ;;
    --help|-h) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "throwaway.sh: unknown command '$CMD' (up|verify|down|status|--help)" >&2; exit 2 ;;
esac

# ------------------------------------------------- run it ON the target
# CI_ISLE_REMOTE=1 means "you ARE the target" — do not hop again.
if [ "$CI_ISLE_TARGET" = ssh ] && [ "${CI_ISLE_REMOTE:-0}" != 1 ]; then
    [ -n "$CI_ISLE_SSH_HOST" ] || { echo "throwaway.sh: CI_ISLE_TARGET=ssh with no CI_ISLE_SSH_HOST" >&2; exit 2; }
    DEST="$(device_ssh_dest)"; REMOTE_DIR="/tmp/polari-ci-isle.$$"
    ssh -o BatchMode=yes -o ConnectTimeout="$CI_SSH_TIMEOUT" "$DEST" "mkdir -p $REMOTE_DIR"
    # ci-9: cache.sh + cache-manifest.py travel too, so the cloud image is cached
    # on the TARGET's own disk (CI_CACHE_DIR defaults to <pool>/cache, and the
    # pool on an ssh target is the target's) rather than copied over the wire.
    scp -q -o BatchMode=yes "$HERE/throwaway.sh" "$J/device.sh" "$J/cache.sh" "$J/cache-manifest.py" "$DEST:$REMOTE_DIR/"
    ENVS="CI_ISLE_REMOTE=1 CI_ISLE_TARGET=local"
    for k in CI_ISLE_VM_NAME CI_ISLE_VM_RAM_GB CI_ISLE_VM_VCPUS CI_ISLE_VM_DISK_GB CI_ISLE_NESTED CI_ISLE_IMAGE_URL CI_MIN_FREE_GB CI_CACHE CI_CACHE_DIR CI_CACHE_MAX_GB; do
        ENVS="$ENVS $k=$(printf '%q' "${!k}")"
    done
    ENVS="$ENVS CI_ISLE_POOL=$(printf '%q' "$(device_pool)")"
    # device.sh sits beside throwaway.sh on the target, so the remote copy
    # is self-contained; DEVICE_ENV_FILE is pointed at nothing on purpose —
    # the configuration travels in the environment, never in a file there.
    trap 'ssh -o BatchMode=yes "$DEST" "rm -rf $REMOTE_DIR" >/dev/null 2>&1 || true' EXIT
    ssh -o BatchMode=yes -o ConnectTimeout="$CI_SSH_TIMEOUT" "$DEST" \
        "cd $REMOTE_DIR && env $ENVS DEVICE_ENV_FILE=$REMOTE_DIR/none.env bash throwaway.sh $CMD"
    exit $?
fi

# ------------------------------------------------------------- local work
POOL="$(device_pool)"
RUN="$POOL/ci-isle/$CI_ISLE_VM_NAME"
# ci-9: the cloud image lives in the shared offline cache (<cache>/cloud), not
# in pool/images — so `retention.sh prune` no longer takes it with a dropped
# version, and `pol jenkins cache status` can see and account for it. A copy
# left in the old pool/images by an earlier run is adopted rather than re-fetched.
# shellcheck source=../cache.sh
source "$(dirname "${BASH_SOURCE[0]}")/../cache.sh" 2>/dev/null || source "$(dirname "${BASH_SOURCE[0]}")/cache.sh"
IMAGES="$(cache_area cloud 2>/dev/null || echo "$POOL/images")"
IMG_NAME="$(basename "${CI_ISLE_IMAGE_URL%%\?*}")"
BASE="$IMAGES/$IMG_NAME"
LEGACY_BASE="$POOL/images/$IMG_NAME"
KEY="$RUN/id_ed25519"
GUEST_USER=polari-ci

SUDO=""; sudo -n true >/dev/null 2>&1 && SUDO="sudo -n"
VIRSH="$SUDO virsh --connect ${LIBVIRT_URI:-qemu:///system}"

say() { echo "[throwaway:$CI_ISLE_VM_NAME] $*"; }
exists() { $VIRSH dominfo "$CI_ISLE_VM_NAME" >/dev/null 2>&1; }
state()  { $VIRSH domstate "$CI_ISLE_VM_NAME" 2>/dev/null | head -1 | tr -d '\n'; }

guest_ip() {
    local ip=""
    ip=$($VIRSH domifaddr "$CI_ISLE_VM_NAME" --source lease 2>/dev/null | awk '/ipv4/{split($4,a,"/"); print a[1]; exit}')
    [ -n "$ip" ] || ip=$($VIRSH domifaddr "$CI_ISLE_VM_NAME" --source agent 2>/dev/null | awk '/ipv4/{split($4,a,"/"); print a[1]; exit}')
    echo "$ip"
}

wait_for_ip() {
    local tries="${CI_ISLE_IP_TRIES:-60}" ip=""
    while [ "$tries" -gt 0 ]; do
        ip=$(guest_ip); [ -n "$ip" ] && { echo "$ip"; return 0; }
        sleep 5; tries=$((tries-1))
    done
    return 1
}

guest_ssh() {  # guest_ssh <command…>
    local ip; ip=$(cat "$RUN/ip" 2>/dev/null || guest_ip)
    [ -n "$ip" ] || { echo "no address for $CI_ISLE_VM_NAME (is it up?)" >&2; return 1; }
    ssh -i "$KEY" -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o LogLevel=ERROR -o ConnectTimeout=10 "$GUEST_USER@$ip" "$@"
}

fetch_base() {
    mkdir -p "$IMAGES"
    if [ -s "$BASE" ]; then
        say "base image cached: $BASE ($(du -h "$BASE" | cut -f1))"
        cache_touch cloud "$IMG_NAME" 2>/dev/null || true
        return 0
    fi
    # an image a pre-ci-9 run left in pool/images is MOVED, not re-downloaded
    if [ -s "$LEGACY_BASE" ] && [ "$LEGACY_BASE" != "$BASE" ]; then
        say "adopting the cloud image from the old pool/images into the cache"
        mv "$LEGACY_BASE" "$BASE"
        cache_put cloud "$IMG_NAME" "the Ubuntu cloud image the throwaway isle boots from" 2>/dev/null || true
        return 0
    fi
    say "fetching the cloud image (ONCE — it lives in the offline cache and survives retention.sh prune)"
    curl -fL --retry 3 -o "$BASE.part" "$CI_ISLE_IMAGE_URL"
    mv "$BASE.part" "$BASE"
    cache_put cloud "$IMG_NAME" "the Ubuntu cloud image the throwaway isle boots from" 2>/dev/null || true
}

make_seed() {
    ssh-keygen -q -t ed25519 -N '' -C "polari-ci-throwaway" -f "$KEY"
    chmod 0600 "$KEY"
    cat > "$RUN/meta-data" <<EOF
instance-id: $CI_ISLE_VM_NAME
local-hostname: $CI_ISLE_VM_NAME
EOF
    cat > "$RUN/user-data" <<EOF
#cloud-config
# A THROWAWAY guest: one user, one key, generated for this run and deleted
# by \`throwaway.sh down\`. No password, no sudo password, nothing persists.
users:
  - name: $GUEST_USER
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: true
    ssh_authorized_keys:
      - $(cat "$KEY.pub")
ssh_pwauth: false
disable_root: true
growpart: { mode: auto }
EOF
    if command -v cloud-localds >/dev/null 2>&1; then
        cloud-localds "$RUN/seed.iso" "$RUN/user-data" "$RUN/meta-data"
    else
        local mk; mk=$(command -v genisoimage || command -v mkisofs) || { echo "no cloud-localds/genisoimage" >&2; return 1; }
        "$mk" -quiet -output "$RUN/seed.iso" -volid cidata -joliet -rock "$RUN/user-data" "$RUN/meta-data"
    fi
    chmod 0644 "$RUN/seed.iso"
}

case "$CMD" in
up)
    if exists; then
        say "already defined (state: $(state)) — idempotent, nothing rebuilt"
        [ "$(state)" = "running" ] || $VIRSH start "$CI_ISLE_VM_NAME"
        ip=$(wait_for_ip) && { echo "$ip" > "$RUN/ip"; say "address: $ip"; }
        exit 0
    fi
    mkdir -p "$RUN"; chmod 0700 "$RUN"
    fetch_base
    say "overlay disk: ${CI_ISLE_VM_DISK_GB}G on top of $(basename "$BASE") (the base is never written)"
    qemu-img create -q -f qcow2 -F qcow2 -b "$BASE" "$RUN/disk.qcow2" "${CI_ISLE_VM_DISK_GB}G"
    make_seed
    say "virt-install: ${CI_ISLE_VM_RAM_GB}GB / ${CI_ISLE_VM_VCPUS} vcpu"
    $SUDO virt-install \
        --connect "${LIBVIRT_URI:-qemu:///system}" \
        --name "$CI_ISLE_VM_NAME" \
        --memory "$((CI_ISLE_VM_RAM_GB * 1024))" \
        --vcpus "$CI_ISLE_VM_VCPUS" \
        --cpu host-passthrough \
        --disk "path=$RUN/disk.qcow2,format=qcow2,bus=virtio" \
        --disk "path=$RUN/seed.iso,device=cdrom" \
        --os-variant ubuntu24.04 \
        --network network=default,model=virtio \
        --graphics none --console pty,target_type=serial \
        --import --noautoconsole
    ip=$(wait_for_ip) || { say "no address after the wait — \`throwaway.sh status\`, then \`down\`"; exit 5; }
    echo "$ip" > "$RUN/ip"; chmod 0600 "$RUN/ip"
    say "up at $ip (key: $RUN/id_ed25519, 0600, deleted by \`down\`)"
    ;;
verify)
    exists || { echo "[throwaway] $CI_ISLE_VM_NAME is not defined — run \`up\` first" >&2; exit 5; }
    say "ssh into the guest…"
    guest_ssh 'echo "hostname: $(hostname)"; echo "nproc:    $(nproc)"; echo "memory:   $(awk "/MemTotal/{printf \"%.1f GB\", \$2/1048576}" /proc/meminfo)"; echo "disk:     $(df -h / | awk "NR==2{print \$4\" free of \"\$2}")"; echo "kvm:      $([ -e /dev/kvm ] && echo present || echo absent)  (the isle router guest needs it — nested)"'
    say "verified"
    ;;
down)
    if exists; then
        say "destroying"
        $VIRSH destroy "$CI_ISLE_VM_NAME" >/dev/null 2>&1 || true
        $VIRSH undefine "$CI_ISLE_VM_NAME" --remove-all-storage --nvram >/dev/null 2>&1 \
            || $VIRSH undefine "$CI_ISLE_VM_NAME" --remove-all-storage >/dev/null 2>&1 || true
    else
        say "no such domain — nothing to destroy"
    fi
    if [ -d "$RUN" ]; then
        [ -f "$KEY" ] && { shred -u "$KEY" 2>/dev/null || rm -f "$KEY"; }
        $SUDO rm -rf "$RUN"
        say "run directory removed (disk, seed, key): $RUN"
    fi
    say "down — the base image stays in the offline cache ($IMAGES); retention.sh prune never touches it, pol jenkins cache prune does"
    ;;
status)
    echo "target:   $(device_target_name)"
    echo "vm:       $CI_ISLE_VM_NAME  ${CI_ISLE_VM_RAM_GB}GB / ${CI_ISLE_VM_VCPUS} vcpu / ${CI_ISLE_VM_DISK_GB}GB"
    echo "pool:     $POOL"
    echo "run dir:  $RUN $([ -d "$RUN" ] && echo '(present)' || echo '(absent)')"
    echo "base img: $BASE $([ -s "$BASE" ] && echo "(cached $(du -h "$BASE" | cut -f1))" || echo '(not cached)')"
    if command -v virsh >/dev/null 2>&1; then
        echo "domain:   $(exists && echo "defined, state $(state)" || echo 'not defined')"
        exists && echo "address:  $(guest_ip || true)"
    else
        echo "domain:   virsh absent on this machine — isle/preflight.sh --isle says so as a FAIL"
    fi
    echo "key:      $([ -f "$KEY" ] && echo "$KEY ($(stat -c %a "$KEY"))" || echo 'none (generated by up, deleted by down)')"
    ;;
esac
