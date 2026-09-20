#!/bin/bash
# polari-jenkins/isle/throwaway.sh — the THROWAWAY isle VM: one script for
# both targets. `CI_ISLE_TARGET=ssh` copies this same script to the target
# and runs it there with the configuration exported, so there is exactly
# one implementation of "make a VM, prove it, destroy it".
#
#   throwaway.sh up         create it (idempotent — an existing one is reported, not rebuilt)
#   throwaway.sh verify     ssh into the guest: hostname, nproc, memory, disk
#   throwaway.sh install --payload <dir> [--json <f>] [--stage N] [--modules m]
#                           ci-3: install THE ARTIFACTS THIS RUN BUILT inside the
#                           guest — prerequisites, the run's own images, the
#                           polari-complete deb, `isle core-install`, and the wait
#                           for the isle to answer (isle/guest-install.sh)
#   throwaway.sh apps --apps "a b" [--json <f>] [--stage N]
#                           ci-3: install this stage's app debs into the isle
#   throwaway.sh verify-isle [--json <f>] [--stage N]
#                           ci-3: the ISLE's own verification from inside the
#                           guest — routes, api, store, router guest
#                           (isle/guest-verify.sh)
#   throwaway.sh selftests --modules "core x" [--json <f>] [--stage N]
#                           ci-3: the module selftests INSIDE the installed
#                           backend container (isle/guest-selftests.sh)
#   throwaway.sh image-cache has|put|path <key>
#                           ci-3: the target's cache of `docker save` tarballs,
#                           keyed by the IMAGE IDS. `put` reads stdin. It is what
#                           stops a run whose images did not change from pushing
#                           gigabytes over the wire a second time.
#   throwaway.sh uninstall  ci-10: run the PRODUCT'S OWN uninstall inside the guest
#                           (isle uninstall --everything → its verify → the
#                           hand-back proof) as a TEST — see isle/guest-uninstall.sh
#   throwaway.sh down       destroy + undefine + delete the disk AND the per-run
#                           key, then `wipe` (ci-10) so nothing of ours is left
#   throwaway.sh wipe [--dry-run]
#                           ci-10: remove everything THIS pipeline made on the
#                           target and nothing else, printing both lists —
#                           see isle/wipe.sh for the scope rule
#   throwaway.sh status     what exists right now
#
# THE TEARDOWN IS TWO LAYERS, and they are different questions:
#   `uninstall` asks: can the PRODUCT hand this machine back?  (a test result)
#   `wipe` asks:      did OUR pipeline leave anything behind?  (a resource guard)
# isle/leakcheck.sh then proves the second one from outside, by diff.
#
# Everything it makes lives under ONE directory (<pool>/ci-isle/<vm>/) and
# `down` removes that directory: the VM, its disk, its cloud-init seed and
# the ssh key generated for this run. The key is generated PER RUN, kept
# 0600 under the pool, and is the only way into the guest — no password,
# no shared key, nothing that outlives `down`.
#
# It installs nothing ON THE TARGET. isle/preflight.sh says when libvirt/qemu is
# missing. What it installs INSIDE THE GUEST is ci-3 — `install`, `apps`,
# `verify-isle`, `selftests` above — and every one of those runs over the same
# `guest_ssh`, with no second path into the guest.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
J="$(cd "$HERE/.." && pwd)"
# In the checkout device.sh is the parent's; on an ssh TARGET this script and
# its libraries all sit in one scp'd directory, so $J is whatever /tmp happens
# to be. Prefer the sibling — cache.sh has always resolved itself this way, and
# the parent-only form was a latent break in the remote hop (found live 2026-09-19:
# `throwaway.sh: /tmp/device.sh: No such file or directory` on the first real
# ssh-target run; ci-7 only ever exercised the LOCAL path).
# shellcheck source=../device.sh
if [ -f "$HERE/device.sh" ]; then source "$HERE/device.sh"; else source "$J/device.sh"; fi

CMD="${1:-status}"; shift || true
ARGS=("$@")
case "$CMD" in
    up|verify|down|status|wipe|uninstall) ;;
    install|apps|verify-isle|selftests|image-cache) ;;
    --help|-h) sed -n '2,52p' "$0"; exit 0 ;;
    *) echo "throwaway.sh: unknown command '$CMD' (up|verify|install|apps|verify-isle|selftests|uninstall|down|wipe|status|image-cache|--help)" >&2; exit 2 ;;
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
    # ci-10: wipe.sh and guest-uninstall.sh travel too — the scope rule and the
    # product-uninstall test have exactly one implementation, on both targets.
    # ci-3: the three guest-cycle libraries travel too — install, verify, selftests
    # — for the same reason wipe.sh and guest-uninstall.sh do: ONE implementation,
    # on both targets, and no second way into the guest.
    scp -q -o BatchMode=yes "$HERE/throwaway.sh" "$HERE/wipe.sh" "$HERE/guest-uninstall.sh" \
        "$HERE/guest-install.sh" "$HERE/guest-verify.sh" "$HERE/guest-selftests.sh" \
        "$J/device.sh" "$J/cache.sh" "$J/cache-manifest.py" "$DEST:$REMOTE_DIR/"
    ENVS="CI_ISLE_REMOTE=1 CI_ISLE_TARGET=local"
    # ci-3: the guest-cycle knobs travel too. They were the kind of omission that
    # only shows up on the target — a timeout set on the controller that silently
    # keeps its default over there is worse than no knob at all.
    for k in CI_ISLE_VM_NAME CI_ISLE_VM_RAM_GB CI_ISLE_VM_VCPUS CI_ISLE_VM_DISK_GB CI_ISLE_NESTED CI_ISLE_IMAGE_URL CI_MIN_FREE_GB CI_CACHE CI_CACHE_DIR CI_CACHE_MAX_GB CI_WIPE_TAG \
             CI_ISLE_SSH_WAIT_S CI_ISLE_IP_TRIES \
             CI_ISLE_MODULES CI_ISLE_IMAGE_TAG CI_ISLE_CORE_INSTALL_TMO_S CI_ISLE_ONLINE_WAIT_S \
             CI_ISLE_BACKEND_CONTAINER CI_ISLE_SELFTEST_TIMEOUT_S CI_ISLE_SELFTEST_CORE_LIMIT \
             CI_ISLE_UNINSTALL_TMO_S; do
        ENVS="$ENVS $k=$(printf '%q' "${!k:-}")"
    done
    ENVS="$ENVS CI_ISLE_POOL=$(printf '%q' "$(device_pool)")"
    # ci-10: an `uninstall --json <path>` names a path on THIS machine (the
    # controller writes results.json), but the command runs over there. So the
    # guest's reading is written on the target and copied back afterwards —
    # never silently dropped, which is how a test result goes missing.
    REMOTE_ARGS=(); WANT_JSON=""; SEND_PAYLOAD=""
    i=0; while [ "$i" -lt "${#ARGS[@]}" ]; do
        case "${ARGS[$i]}" in
            --json) WANT_JSON="${ARGS[$((i+1))]:-}"; REMOTE_ARGS+=(--json "$REMOTE_DIR/out.json"); i=$((i+2)) ;;
            # ci-3: a --payload names a directory on THIS machine (the controller
            # holds the pool). It has to exist on the TARGET before the verb runs.
            --payload) SEND_PAYLOAD="${ARGS[$((i+1))]:-}"; REMOTE_ARGS+=(--payload "$REMOTE_DIR/payload"); i=$((i+2)) ;;
            *) REMOTE_ARGS+=("${ARGS[$i]}"); i=$((i+1)) ;;
        esac
    done

    # ci-3 — THE PAYLOAD HOP, and why the images are not simply copied with it.
    #
    # The debs are ~150 MB and travel every run. The image tarball is measured in
    # GB and, on a pipeline device that reaches its isle target over Wi-Fi, is by
    # far the most expensive thing in the run. But it only CHANGES when the
    # frontend or backend source changed — so it is keyed by the image IDs
    # (payload.sh writes images.key) and cached on the target. A run that rebuilt
    # identical images transfers nothing at all.
    if [ -n "$SEND_PAYLOAD" ]; then
        [ -d "$SEND_PAYLOAD" ] || { echo "throwaway.sh: --payload '$SEND_PAYLOAD' is not a directory" >&2; exit 2; }
        echo "[throwaway] payload → the target (everything but the image tarball)"
        tar -C "$SEND_PAYLOAD" --exclude=images.tar.gz -cf - . \
            | ssh -o BatchMode=yes "$DEST" "mkdir -p $REMOTE_DIR/payload && tar -C $REMOTE_DIR/payload -xf -"
        IMG_KEY="$(cat "$SEND_PAYLOAD/images.key" 2>/dev/null || true)"
        if [ -n "$IMG_KEY" ] && [ -s "$SEND_PAYLOAD/images.tar.gz" ]; then
            if ssh -o BatchMode=yes "$DEST" \
                "cd $REMOTE_DIR && env $ENVS DEVICE_ENV_FILE=$REMOTE_DIR/none.env bash throwaway.sh image-cache has $IMG_KEY" >/dev/null 2>&1; then
                echo "[throwaway] the target already holds these exact images (key ${IMG_KEY:0:12}) — nothing transferred"
            else
                echo "[throwaway] streaming the image tarball ($(du -m "$SEND_PAYLOAD/images.tar.gz" | cut -f1) MB, key ${IMG_KEY:0:12}) to the target"
                T0=$(date +%s)
                ssh -o BatchMode=yes "$DEST" \
                    "cd $REMOTE_DIR && env $ENVS DEVICE_ENV_FILE=$REMOTE_DIR/none.env bash throwaway.sh image-cache put $IMG_KEY" \
                    < "$SEND_PAYLOAD/images.tar.gz"
                echo "[throwaway] transferred in $(( $(date +%s) - T0 ))s"
            fi
        fi
    fi
    # device.sh sits beside throwaway.sh on the target, so the remote copy
    # is self-contained; DEVICE_ENV_FILE is pointed at nothing on purpose —
    # the configuration travels in the environment, never in a file there.
    trap 'ssh -o BatchMode=yes "$DEST" "rm -rf $REMOTE_DIR" >/dev/null 2>&1 || true' EXIT
    RC=0
    ssh -o BatchMode=yes -o ConnectTimeout="$CI_SSH_TIMEOUT" "$DEST" \
        "cd $REMOTE_DIR && env $ENVS DEVICE_ENV_FILE=$REMOTE_DIR/none.env bash throwaway.sh $CMD ${REMOTE_ARGS[*]:-}" || RC=$?
    if [ -n "$WANT_JSON" ]; then
        mkdir -p "$(dirname "$WANT_JSON")"
        scp -q -o BatchMode=yes "$DEST:$REMOTE_DIR/out.json" "$WANT_JSON" 2>/dev/null \
            || echo "[throwaway] ⚠ the guest reading could not be copied back to $WANT_JSON" >&2
    fi
    exit "$RC"
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

# ci-10: the two teardown layers. Sourced AFTER the variables above, because
# both read POOL/RUN/IMAGES/VIRSH/SUDO and call say().
# shellcheck source=wipe.sh
source "$HERE/wipe.sh"
# shellcheck source=guest-uninstall.sh
source "$HERE/guest-uninstall.sh"
# ci-3: the guest cycle — install, verify, selftests. Sourced here for the same
# reason as the two above: they call say()/exists()/guest_ssh() and must see the
# variables resolved above them.
# shellcheck source=guest-install.sh
source "$HERE/guest-install.sh"
# shellcheck source=guest-verify.sh
source "$HERE/guest-verify.sh"
# shellcheck source=guest-selftests.sh
source "$HERE/guest-selftests.sh"
exists() { $VIRSH dominfo "$CI_ISLE_VM_NAME" >/dev/null 2>&1; }

# ci-3 — the image tarball cache, on the TARGET, keyed by the image IDs.
# It lives in the offline cache beside the cloud image, so `leakcheck.sh` already
# excludes it (a cached artefact is never a leak) and `pol jenkins cache prune`
# is the one thing that removes it.
img_cache_dir() { local d; d="$(cache_area ciimages 2>/dev/null || echo "$POOL/ci-images")"; mkdir -p "$d"; printf '%s' "$d"; }
img_cache_path() { printf '%s/%s.tar.gz' "$(img_cache_dir)" "$1"; }
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


# ci-3, found on the FIRST real install (isle-test #7, 2026-09-20): a guest
# script that reconfigures the guest's own network CANNOT be run down a single
# ssh pipe. `isle core-install` printed its whole log and its "ISLE CORE READY"
# banner, and then the connection died before the script's next `echo` — so the
# fenced `###…END` marker never arrived and the reading said "the guest could
# not be reached", about an isle that was standing there fully working. The same
# is true by construction of `isle uninstall --everything`, whose network
# hand-back is the thing it is being tested for.
#
# So: write the script INTO the guest, start it DETACHED (setsid + nohup, stdin
# closed, output to a file), and then poll with FRESH connections until its end
# marker appears. A dropped connection becomes a failed poll and the next one
# succeeds; the reading is a file, and a file survives the network.
#
#   guest_run_detached <tag> <end marker> <timeout s>   — script on stdin, log on stdout
guest_run_detached() {
    local tag="$1" marker="$2" tmo="${3:-2400}"
    # NOT on the line above. Under `set -u` bash expands EVERY assignment word of
    # a single `local` before it performs any of them, so `local a=$1 b=x-$a`
    # dies with "a: unbound variable" — which is exactly how this failed on
    # isle-test #8, after the payload had already been moved.
    local dir="/home/$GUEST_USER/polari-ci-$tag"
    local waited=0 step=15 last=""
    guest_ssh "rm -rf $dir && mkdir -p $dir" >/dev/null 2>&1 || return 1
    guest_ssh "cat > $dir/run.sh" || return 1
    guest_ssh "cd $dir && setsid nohup bash run.sh > run.log 2>&1 < /dev/null & echo started" >/dev/null 2>&1 || return 1
    say "$tag: running detached in the guest (it reconfigures the network, so the ssh session is not trusted to survive it)"
    while [ "$waited" -lt "$tmo" ]; do
        if guest_ssh "grep -q '$marker' $dir/run.log" >/dev/null 2>&1; then break; fi
        sleep "$step"; waited=$((waited + step))
        # a heartbeat, so a twenty-minute step is legible while it happens
        if [ $((waited % 60)) = 0 ]; then
            last="$(guest_ssh "grep -a '^###STEP ' $dir/run.log 2>/dev/null | tail -1" 2>/dev/null || true)"
            say "$tag: ${waited}s — ${last:-(the guest is not answering right now; that is expected while it re-does its own network)}"
        fi
    done
    guest_ssh "cat $dir/run.log" 2>/dev/null || true
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
    # The hypervisor runs as ITS OWN user (libvirt-qemu on Ubuntu), not as the person: the first real run
    # (2026-09-19, §75) died with "Cannot access storage file … (as uid:64055) Permission denied" because the
    # run dir was 0700. The dir stays private to the person (the ssh key lives here and keeps its 0600);
    # the hypervisor gets TRAVERSE on the dir and READ/WRITE on exactly the two files it opens. ACLs when the
    # tool exists, the coarse mode bits otherwise. Parents are created 0775 by the umask (traversable).
    hv_user="$(getent passwd libvirt-qemu >/dev/null 2>&1 && echo libvirt-qemu || echo qemu)"
    if command -v setfacl >/dev/null 2>&1; then
        chmod 0710 "$RUN"
        setfacl -m "u:$hv_user:x" "$RUN"
        setfacl -m "u:$hv_user:rw" "$RUN/disk.qcow2" "$RUN/seed.iso"
    else
        chmod 0711 "$RUN"; chmod 0666 "$RUN/disk.qcow2" "$RUN/seed.iso"
    fi
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
    # An address arrives seconds before sshd does (cloud-init is still writing the key): the first real
    # run (2026-09-19, §75) had `verify` refused with "Connection refused" 21 s after boot. `up` is not
    # done until the guest ANSWERS over ssh, so verify/uninstall never race it.
    waited=0
    until guest_ssh true >/dev/null 2>&1; do
        sleep 5; waited=$((waited + 5))
        [ "$waited" -lt "${CI_ISLE_SSH_WAIT_S:-240}" ] || { say "the guest has an address ($ip) but ssh never answered in ${CI_ISLE_SSH_WAIT_S:-240} s — \`throwaway.sh status\`, then \`down\`"; exit 5; }
    done
    say "up at $ip after ${waited}s of ssh wait (key: $RUN/id_ed25519, 0600, deleted by \`down\`)"
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
    # ci-10: the ordinary teardown above handles the happy path. `wipe` then
    # sweeps everything it can have missed — a domain that refused to undefine,
    # an orphaned overlay in the images dir, a qemu process outliving its
    # domain, a per-run network, /tmp leftovers. It is scoped and idempotent,
    # so calling it here costs nothing when there is nothing to find.
    echo
    wipe_do
    say "down — the base image stays in the offline cache ($IMAGES); retention.sh prune never touches it, pol jenkins cache prune does"
    ;;
wipe)
    wipe_do "${ARGS[0]:-}"
    ;;
image-cache)
    # ci-3: the target's own cache of `docker save` tarballs. `put` reads stdin
    # into a .part and renames — so a transfer that dies half way never leaves a
    # truncated tarball that the next run would happily `docker load`.
    ICMD="${ARGS[0]:-has}"; IKEY="${ARGS[1]:-}"
    [ -n "$IKEY" ] || { echo "throwaway.sh image-cache has|put|path <key>" >&2; exit 2; }
    P="$(img_cache_path "$IKEY")"
    case "$ICMD" in
        has)  [ -s "$P" ] && exit 0 || exit 1 ;;
        path) printf '%s\n' "$P" ;;
        put)  cat > "$P.part"; mv "$P.part" "$P"
              cache_put ciimages "$IKEY.tar.gz" "the images one pipeline run built, saved for the throwaway isle" 2>/dev/null || true
              say "image tarball cached: $P ($(du -h "$P" | cut -f1))" ;;
        *)    echo "throwaway.sh image-cache has|put|path <key>" >&2; exit 2 ;;
    esac
    ;;
install|apps|verify-isle|selftests)
    # ci-3 — the guest cycle. One argument parser for all four: every one of them
    # takes --json (where the reading goes) and --stage (which stage asked).
    G_JSON=""; G_STAGE=1; G_PAYLOAD=""; G_MODULES=""; G_APPS=""
    i=0; while [ "$i" -lt "${#ARGS[@]}" ]; do
        case "${ARGS[$i]}" in
            --json)    G_JSON="${ARGS[$((i+1))]:-}"; i=$((i+2)) ;;
            --stage)   G_STAGE="${ARGS[$((i+1))]:-1}"; i=$((i+2)) ;;
            --payload) G_PAYLOAD="${ARGS[$((i+1))]:-}"; i=$((i+2)) ;;
            --modules) G_MODULES="${ARGS[$((i+1))]:-}"; i=$((i+2)) ;;
            --apps)    G_APPS="${ARGS[$((i+1))]:-}"; i=$((i+2)) ;;
            *) echo "throwaway.sh $CMD: unknown argument '${ARGS[$i]}'" >&2; exit 2 ;;
        esac
    done
    case "$CMD" in
        install)
            [ -n "$G_PAYLOAD" ] || { echo "throwaway.sh install needs --payload <dir> (isle/payload.sh build)" >&2; exit 2; }
            # the image tarball is not IN the payload on this side of the hop —
            # it is in the target's cache, under the key the payload names.
            if [ ! -s "$G_PAYLOAD/images.tar.gz" ] && [ -s "$G_PAYLOAD/images.key" ]; then
                IKEY="$(cat "$G_PAYLOAD/images.key")"; P="$(img_cache_path "$IKEY")"
                if [ -s "$P" ]; then
                    ln -sf "$P" "$G_PAYLOAD/images.tar.gz"
                    say "images resolved from the target cache: $P"
                else
                    say "⚠ neither the payload nor the cache holds the image tarball for key ${IKEY:0:12}"
                fi
            fi
            install_do "$G_PAYLOAD" "$G_JSON" "$G_STAGE" "${G_MODULES:-${CI_ISLE_MODULES:-islemesh}}" ;;
        apps)        install_apps_do "$G_APPS" "$G_JSON" "$G_STAGE" ;;
        verify-isle) verify_isle_do "$G_JSON" "$G_STAGE" ;;
        selftests)   selftests_do "${G_MODULES:-core}" "$G_JSON" "$G_STAGE" ;;
    esac
    ;;
uninstall)
    # ci-10, his addendum: the PRODUCT'S OWN uninstall, run as a de jure test.
    UN_JSON=""; UN_STAGE=1
    i=0; while [ "$i" -lt "${#ARGS[@]}" ]; do
        case "${ARGS[$i]}" in
            --json)  UN_JSON="${ARGS[$((i+1))]:-}"; i=$((i+2)) ;;
            --stage) UN_STAGE="${ARGS[$((i+1))]:-1}"; i=$((i+2)) ;;
            *) echo "throwaway.sh uninstall: unknown argument '${ARGS[$i]}' (--json <path> --stage <n>)" >&2; exit 2 ;;
        esac
    done
    uninstall_do "$UN_JSON" "$UN_STAGE"
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
    echo "teardown: uninstall (the PRODUCT's own, a TEST) → down → wipe (ours, scoped to '${CI_WIPE_TAG:-polari-ci-}')"
    echo "          \`throwaway.sh wipe --dry-run\` lists what a wipe would take and what it would leave;"
    echo "          \`isle/leakcheck.sh check\` then proves from outside that nothing of ours survived."
    ;;
esac
