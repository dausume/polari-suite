#!/bin/bash
# polari-jenkins/isle/wipe.sh — ci-10: remove everything THIS PIPELINE made on
# the target, and NOTHING else. Sourced by throwaway.sh (`throwaway.sh wipe`),
# so it travels to an ssh target through the same hop and there is exactly one
# implementation of "leave the device as we found it".
#
# THE SCOPE RULE, and it is the whole point of this file: a thing is ours only
# when it carries the `polari-ci-` tag (CI_WIPE_TAG) or IS the configured VM
# name. Everything else the wipe SEES is printed under "found, NOT removed" —
# named, so a person can look — and left exactly where it is. A CI wipe that
# took somebody's VM with it would be worse than a leak.
#
# What it removes, in order:
#   1. the domain: destroy if running, then undefine --nvram --remove-all-storage
#      (with the older two-flag and no-flag forms as fallbacks)
#   2. qcow2 / img / raw / iso / seed files carrying the tag, under the libvirt
#      images dir, the pool's ci-isle dir and the run dir  (bytes reported)
#   3. libvirt storage volumes carrying the tag, in every pool
#   4. a libvirt network carrying the tag (the default network is never ours)
#   5. a stray qemu-system process still holding the guest open
#   6. /tmp/polari-ci-* and /var/tmp/polari-ci-* leftovers
#   7. the per-run ssh key (shredded) and the run directory itself
#
# THE CACHE IS NEVER WIPED. <cache>/cloud holds the Ubuntu base image on
# purpose (ci-9) — re-downloading gigabytes every stage is not hygiene. It is
# excluded by path here and excluded by name in leakcheck.sh.
#
# Idempotent: a second wipe finds nothing and says so. `--dry-run` lists.

CI_WIPE_TAG="${CI_WIPE_TAG:-polari-ci-}"
WIPE_DRY="${WIPE_DRY:-0}"

_WIPED=(); _KEPT=(); _WIPE_BYTES=0

_w()    { _WIPED+=("$1"); }
_k()    { _KEPT+=("$1"); }
_bytes(){ stat -c %s "$1" 2>/dev/null || echo 0; }
_human(){ local b="${1:-0}"; if [ "$b" -ge 1073741824 ] 2>/dev/null; then printf '%.1fG' "$(echo "$b/1073741824" | bc -l 2>/dev/null || echo 0)"
          elif [ "$b" -ge 1048576 ] 2>/dev/null; then printf '%.0fM' "$(echo "$b/1048576" | bc -l 2>/dev/null || echo 0)"
          else printf '%sB' "$b"; fi; }

# ours = the configured VM name, or anything carrying the tag. Nothing else.
wipe_ours() { case "$1" in "$CI_ISLE_VM_NAME") return 0 ;; "$CI_WIPE_TAG"*) return 0 ;; esac; return 1; }

# the cache root, which is EXCLUDED from every sweep below
wipe_cache_root() { printf '%s' "${CI_CACHE_DIR:-$POOL/cache}"; }
_in_cache() { case "$1" in "$(wipe_cache_root)"/*|"$(wipe_cache_root)") return 0 ;; esac; return 1; }

# PROTECTED: a path that IS, or CONTAINS, something this wipe must not take with
# it. Found live on the first real ssh-target run 2026-09-19, where the tag glob
# on /tmp and /var/tmp matched two things it must never remove:
#   · /var/tmp/polari-ci-pool   — the POOL itself, which holds the offline cache
#   · /tmp/polari-ci-isle.<pid> — the directory THIS script was scp'd into and is
#                                 running from, i.e. it would rm -rf its own cwd
# The cache exclusion alone did not catch either: neither path is INSIDE the cache.
_protected() {
    local p="$1" c; c="$(wipe_cache_root)"
    case "$POOL"       in "$p"|"$p"/*) return 0 ;; esac
    case "$c"          in "$p"|"$p"/*) return 0 ;; esac
    case "${HERE:-/-}" in "$p"|"$p"/*) return 0 ;; esac
    case "$PWD"        in "$p"|"$p"/*) return 0 ;; esac
    return 1
}

_rm() {  # _rm <path> <label>
    local p="$1" label="$2" b
    [ -e "$p" ] || return 0
    _in_cache "$p" && { _k "$label (inside the offline cache — never wiped)"; return 0; }
    _protected "$p" && { _k "$label (it holds the pool, the offline cache or this very run — left alone)"; return 0; }
    b=$(_bytes "$p"); _WIPE_BYTES=$((_WIPE_BYTES + b))
    if [ "$WIPE_DRY" = 1 ]; then _w "would remove  $label  ($(_human "$b"))"; return 0; fi
    $SUDO rm -rf "$p" 2>/dev/null || rm -rf "$p" 2>/dev/null || { _k "$label (could not remove — permission?)"; return 0; }
    _w "removed  $label  ($(_human "$b"))"
}

# ------------------------------------------------------------- 1. the domain
_wipe_domains() {
    command -v virsh >/dev/null 2>&1 || { _k "virsh absent — no domain could be read on this target"; return 0; }
    local d st
    while IFS= read -r d; do
        [ -n "$d" ] || continue
        if ! wipe_ours "$d"; then _k "VM $d (not ours — no '$CI_WIPE_TAG' tag)"; continue; fi
        st=$($VIRSH domstate "$d" 2>/dev/null | head -1 | tr -d '\n')
        if [ "$WIPE_DRY" = 1 ]; then _w "would remove  VM $d (state: ${st:-unknown})"; continue; fi
        [ "$st" = running ] && $VIRSH destroy "$d" >/dev/null 2>&1 || true
        $VIRSH undefine "$d" --nvram --remove-all-storage >/dev/null 2>&1 \
            || $VIRSH undefine "$d" --remove-all-storage >/dev/null 2>&1 \
            || $VIRSH undefine "$d" --nvram >/dev/null 2>&1 \
            || $VIRSH undefine "$d" >/dev/null 2>&1 || true
        if $VIRSH dominfo "$d" >/dev/null 2>&1; then _k "VM $d (undefine did not take — look with: virsh dominfo $d)"
        else _w "removed  VM $d (was: ${st:-unknown})"; fi
    done < <($VIRSH list --all --name 2>/dev/null || true)
}

# --------------------------------------------- 2. disks, seeds and overlays
# Only the tag's files in the shared images dir; the pool's own ci-isle tree is
# ours whole. An untagged file in the images dir is reported, never touched.
_wipe_disks() {
    local dir f base
    for dir in "$IMAGES" ${CI_WIPE_IMAGE_DIRS:-/var/lib/libvirt/images}; do
        [ -d "$dir" ] || continue
        _in_cache "$dir" && continue          # <cache>/cloud holds the base image ON PURPOSE
        for f in "$dir"/*; do
            [ -f "$f" ] || continue
            base="$(basename "$f")"
            case "$base" in
                "$CI_WIPE_TAG"*|"$CI_ISLE_VM_NAME"*) _rm "$f" "disk $f" ;;
                *.qcow2|*.img|*.raw|*.iso) _k "$f ($(_human "$(_bytes "$f")") — not ours, left alone)" ;;
            esac
        done
    done
    [ -d "$POOL/ci-isle" ] && for f in "$POOL/ci-isle"/*; do
        [ -e "$f" ] || continue
        base="$(basename "$f")"
        if wipe_ours "$base"; then _rm "$f" "run tree $f"; else _k "$f (in the pool but not ours)"; fi
    done
    return 0
}

# ----------------------------------------------- 3. libvirt storage volumes
_wipe_volumes() {
    command -v virsh >/dev/null 2>&1 || return 0
    local p v
    while IFS= read -r p; do
        [ -n "$p" ] || continue
        while IFS= read -r v; do
            [ -n "$v" ] || continue
            if wipe_ours "$v"; then
                if [ "$WIPE_DRY" = 1 ]; then _w "would remove  volume $v (pool $p)"
                elif $VIRSH vol-delete "$v" --pool "$p" >/dev/null 2>&1; then _w "removed  volume $v (pool $p)"
                else _k "volume $v in pool $p (vol-delete refused)"; fi
            fi
        done < <($VIRSH vol-list "$p" --name 2>/dev/null || true)
    done < <($VIRSH pool-list --name 2>/dev/null || true)
}

# ------------------------------------------------------- 4. a per-run network
_wipe_networks() {
    command -v virsh >/dev/null 2>&1 || return 0
    local n
    while IFS= read -r n; do
        [ -n "$n" ] || continue
        wipe_ours "$n" || continue                 # `default` is libvirt's, never ours
        if [ "$WIPE_DRY" = 1 ]; then _w "would remove  network $n"; continue; fi
        $VIRSH net-destroy "$n" >/dev/null 2>&1 || true
        $VIRSH net-undefine "$n" >/dev/null 2>&1 || true
        _w "removed  network $n"
    done < <($VIRSH net-list --all --name 2>/dev/null || true)
}

# ------------------------------------- 5. a qemu process outliving its domain
_wipe_processes() {
    local line pid args
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        pid="${line%% *}"; args="${line#* }"
        case "$args" in
            *qemu-system*) ;;
            *) continue ;;
        esac
        case "$args" in
            *"guest=$CI_ISLE_VM_NAME"*|*"$CI_WIPE_TAG"*) ;;
            *) _k "pid $pid (a qemu process that is not ours — left running)"; continue ;;
        esac
        if [ "$WIPE_DRY" = 1 ]; then _w "would kill  pid $pid (qemu holding $CI_ISLE_VM_NAME open)"; continue; fi
        $SUDO kill "$pid" 2>/dev/null || kill "$pid" 2>/dev/null || true
        sleep 1
        kill -0 "$pid" 2>/dev/null && { $SUDO kill -9 "$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null || true; }
        _w "killed  pid $pid (stray qemu for $CI_ISLE_VM_NAME)"
    done < <(ps -eo pid=,args= 2>/dev/null | sed 's/^ *//' || true)
}

# -------------------------------------------------------- 6. /tmp leftovers
_wipe_tmp() {
    local d f
    for d in /tmp /var/tmp; do
        [ -d "$d" ] || continue
        for f in "$d/$CI_WIPE_TAG"*; do [ -e "$f" ] && _rm "$f" "leftover $f"; done
    done
    return 0
}

# ------------------------------------------- 7. the key, then the run dir
_wipe_run_dir() {
    [ -d "$RUN" ] || return 0
    local k
    for k in "$RUN"/id_ed25519 "$RUN"/id_ed25519.pub; do
        [ -f "$k" ] || continue
        if [ "$WIPE_DRY" = 1 ]; then _w "would shred  per-run ssh key $k"
        else shred -u "$k" 2>/dev/null || rm -f "$k" 2>/dev/null || true; _w "shredded  per-run ssh key $k"; fi
    done
    _rm "$RUN" "run directory $RUN"
}

# ----------------------------------------------------------------- the verb
wipe_do() {   # wipe_do [--dry-run]
    case "${1:-}" in --dry-run|-n) WIPE_DRY=1 ;; esac
    _WIPED=(); _KEPT=(); _WIPE_BYTES=0
    say "wipe — scope: the VM '$CI_ISLE_VM_NAME' and anything tagged '$CI_WIPE_TAG'$([ "$WIPE_DRY" = 1 ] && echo '  (DRY RUN — nothing is removed)')"
    wipe_ours "$CI_ISLE_VM_NAME" || _k "⚠ CI_ISLE_VM_NAME='$CI_ISLE_VM_NAME' does not carry the '$CI_WIPE_TAG' tag — the scoping rests on that exact name alone"
    _wipe_domains
    _wipe_disks
    _wipe_volumes
    _wipe_networks
    _wipe_processes
    _wipe_tmp
    _wipe_run_dir

    echo
    if [ "${#_WIPED[@]}" = 0 ]; then
        echo "removed: nothing — the target carries no residue of this pipeline (idempotent: a second wipe says exactly this)"
    else
        echo "removed ($(_human "$_WIPE_BYTES") reclaimed):"
        printf '  %s\n' "${_WIPED[@]}"
    fi
    echo
    if [ "${#_KEPT[@]}" = 0 ]; then
        echo "found but NOT removed: nothing — every VM, disk and process on the target carried the tag"
    else
        echo "found but NOT removed (no '$CI_WIPE_TAG' tag — this wipe never touches what it did not make):"
        printf '  %s\n' "${_KEPT[@]}"
    fi
    echo "the offline cache ($(wipe_cache_root)) is EXCLUDED by design — it holds the base image on purpose (ci-9)"
}
