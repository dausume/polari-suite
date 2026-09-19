#!/bin/bash
# setup/steps/05-isle.sh — WHERE the throwaway isle goes, and everything
# that device needs. Writes device.env through `pol jenkins target` (the
# existing verb) and proves the result with the real preflight.

STEP_TITLE_isle="where the throwaway isle goes"

_ssh_config_template() {
    cat <<'EOF'
  Host <alias>
      HostName    <the address or DNS name — this line lives ONLY in ~/.ssh/config>
      User        <the login on that device>
      IdentityFile ~/.ssh/id_ed25519
EOF
}
_sudoers_line() {   # the exact drop-in, for the ci user on the target
    printf '%s ALL=(ALL) NOPASSWD: /usr/bin/true, /usr/bin/virsh, /usr/bin/virt-install, /usr/bin/qemu-img, /usr/bin/cloud-localds, /usr/bin/virt-clone, /usr/bin/virt-viewer\n' "$1"
}

step_isle_check() {
    local okall=1
    check OK "target: $(device_target_name) (device.env: CI_ISLE_TARGET=$CI_ISLE_TARGET)"
    check OK "VM: $CI_ISLE_VM_NAME — ${CI_ISLE_VM_RAM_GB} GB / ${CI_ISLE_VM_VCPUS} vCPU / ${CI_ISLE_VM_DISK_GB} GB, nested=$CI_ISLE_NESTED"
    if [ "$CI_ISLE_TARGET" = ssh ]; then
        doctor_check 'ssh target'    'ssh'            || okall=0
        doctor_check 'target sudo -n' 'sudo -n'       || okall=0
        doctor_check 'target /dev/kvm' '/dev/kvm'     || okall=0
        doctor_check 'target libvirt' 'libvirt tools' || okall=0
        doctor_ok 'ssh target' 2>/dev/null     || todo "make the isle device answer a BatchMode ssh" "ssh-copy-id $CI_ISLE_SSH_HOST  (after a Host entry in ~/.ssh/config)"
        doctor_ok 'target sudo -n' 2>/dev/null || todo "grant passwordless sudo on the isle device (a job cannot answer a prompt)" "pol jenkins setup --step isle — it writes the drop-in for you"
        doctor_ok 'target libvirt' 2>/dev/null || todo "install libvirt/qemu on the isle device" "$(doctor_fix 'target libvirt' 2>/dev/null || echo 'sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients virtinst qemu-utils cloud-image-utils')"
    else
        doctor_check '/dev/kvm'      'KVM here'       || okall=0
        doctor_check 'libvirt client' 'libvirt here'  || okall=0
        check MISS "LOCAL-TARGET CAVEAT: the controller is a CONTAINER and libvirt lives on the host, so a local target needs the libvirt socket mounted in (a posture change nobody has authorised) or a host-tier agent. The ssh target has no such problem."
        doctor_ok '/dev/kvm' 2>/dev/null || todo "this machine has no /dev/kvm — the isle cannot be built here" "pol jenkins target ssh <alias>, or enable VT-x/AMD-V in firmware"
    fi
    doctor_check 'isle target for tests' 'testable' || okall=0

    local pv; pv="$(preflight_verdict)"
    case "$pv" in
        PASS) check OK "preflight --isle: PASS — clear to run" ;;
        WARN) check MISS "preflight --isle: clear to run, with warnings" ;;
        *)    check MISS "preflight --isle: $pv — pol jenkins preflight --isle shows the table"
              todo "the preflight refuses this device" "pol jenkins preflight --isle   (each FAIL row names its own fix)" ;;
    esac

    [ "$okall" = 1 ] && [ "$pv" = PASS ] && state done "$(device_target_name), preflight PASS" || state todo "$(device_target_name), preflight $pv"
    [ "$okall" = 1 ] && [ "$pv" = PASS ]
}

step_isle_do() {
    explain "The throwaway isle is a VM the pipeline creates, installs Polari into, tests and then destroys. It needs /dev/kvm, libvirt, ${CI_ISLE_VM_RAM_GB} GB of RAM and ${CI_ISLE_VM_DISK_GB} GB of disk — and nested KVM, because an isle boots its own router guest inside that VM.

LOCAL means the machine running Jenkins also hosts that VM. Honest caveat: this controller is a CONTAINER and libvirt lives on the host, so the local path needs the libvirt socket mounted into the controller (a posture change nobody has authorised) or a host-tier agent.

SSH means the VM is made on another device. This machine then needs only docker; the target needs KVM, libvirt and passwordless sudo. That path has no caveat — it is much of why the device is configurable at all.

⚠ The isle device is named by an ssh ALIAS from ~/.ssh/config, never by an address. device.env is gitignored, but habits are not."
    echo
    step_isle_check || true
    echo

    local where_="$CI_ISLE_TARGET" alias_=""
    if [ "$MODE" != report ]; then
        where_=$(tui_menu "Where does the throwaway isle go?" \
            "The pipeline builds an isle in a VM and destroys it. The machine running Jenkins does not have to be the one that provides KVM." \
            "$CI_ISLE_TARGET" \
            local "this machine — needs KVM + libvirt + RAM for controller, build AND the VM" \
            ssh   "another device over ssh — this machine then only needs docker")
    fi
    case "$where_" in local|ssh) ;; *) where_="$CI_ISLE_TARGET" ;; esac

    if [ "$where_" = ssh ]; then
        alias_="$(ask_value 'ssh alias' 'The Host alias from ~/.ssh/config for the isle device (an ALIAS, never an address):' "$CI_ISLE_SSH_HOST")"
        if [ -z "$alias_" ]; then
            check MISS "no alias given — leaving the target as it was"
            todo "name the isle device" "pol jenkins target ssh <alias>"
        else
            if ! device_ssh_alias_known 2>/dev/null && ! grep -qiE "^[[:space:]]*Host(.*[[:space:]])?$alias_([[:space:]]|$)" "$HOME/.ssh/config" 2>/dev/null; then
                check MISS "no Host entry for '$alias_' in ~/.ssh/config yet"
                where "~/.ssh/config on THIS machine — the address lives there and nowhere else"
                echo; _ssh_config_template | sed "s/<alias>/$alias_/"; echo
                howto "add that block, then: ssh-keygen -t ed25519   and   ssh-copy-id $alias_"
            fi
            CI_ISLE_SSH_HOST="$alias_"
        fi
    fi

    if [ "$MODE" != report ] && [ -r "$CLI_JENKINS" ]; then
        if [ "$where_" = ssh ] && [ -n "${alias_:-}" ]; then
            act "device.env written: the isle goes to the ssh alias '$alias_'" -- bash "$CLI_JENKINS" target ssh "$alias_" || true
        elif [ "$where_" = local ]; then
            act "device.env written: the isle is built on this machine" -- bash "$CLI_JENKINS" target local || true
        fi
        device_reload
    fi

    # the VM knobs
    if [ "$MODE" != report ]; then
        local ram disk vcpus
        ram="$(ask_value 'VM memory (GB)' 'How much memory the throwaway isle VM gets (the preflight refuses a run the device cannot spare):' "$CI_ISLE_VM_RAM_GB")"
        vcpus="$(ask_value 'VM vCPUs' 'Virtual CPUs for the throwaway isle:' "$CI_ISLE_VM_VCPUS")"
        disk="$(ask_value 'VM disk (GB)' 'The overlay disk (an isle install wants 30 GB or more):' "$CI_ISLE_VM_DISK_GB")"
        [ -n "$ram" ]   && device_env_set CI_ISLE_VM_RAM_GB   "$ram"
        [ -n "$vcpus" ] && device_env_set CI_ISLE_VM_VCPUS    "$vcpus"
        [ -n "$disk" ]  && device_env_set CI_ISLE_VM_DISK_GB  "$disk"
        doctor_refresh; PREFLIGHT_JSON=""
    fi

    # --------------------------------------------------- the ssh device
    if [ "$CI_ISLE_TARGET" = ssh ] && [ -n "$CI_ISLE_SSH_HOST" ]; then
        local dest; dest="$(device_ssh_dest)"
        if ! ssh -o BatchMode=yes -o ConnectTimeout=8 "$dest" 'echo ok' >/dev/null 2>&1; then
            howto "ssh-keygen -t ed25519 -C polari-ci    (if you have no key yet)"
            howto "ssh-copy-id $dest                     (it asks for that device's password once)"
            if ask "copy your ssh key to $dest?" "The device does not answer a BatchMode ssh yet. Run ssh-copy-id $dest now? It will ask for that device's password once, then never again."; then
                [ -f "$HOME/.ssh/id_ed25519" ] || act "generated ~/.ssh/id_ed25519" -- ssh-keygen -t ed25519 -C polari-ci -f "$HOME/.ssh/id_ed25519" -N "" -q || true
                act "key copied — $dest now answers without a prompt" -- ssh-copy-id "$dest" || true
            fi
        else
            check OK "$dest answers a BatchMode ssh — already: OK"
        fi

        if ssh -o BatchMode=yes -o ConnectTimeout=8 "$dest" 'sudo -n true' >/dev/null 2>&1; then
            check OK "passwordless sudo on $dest — already: OK"
        else
            local ruser line
            ruser="$(ssh -o BatchMode=yes -o ConnectTimeout=8 "$dest" 'id -un' 2>/dev/null || echo '<the ci user>')"
            line="$(_sudoers_line "$ruser")"
            explain "A pipeline job cannot answer a password prompt, so the ssh user on the isle device needs passwordless sudo for the libvirt commands. The exact drop-in, verbatim:"
            echo; printf '     /etc/sudoers.d/polari-ci-libvirt   (mode 0440)\n     %s\n' "$line"; echo
            howto "ssh -t $dest \"printf '%s' '$line' | sudo tee /etc/sudoers.d/polari-ci-libvirt >/dev/null && sudo chmod 0440 /etc/sudoers.d/polari-ci-libvirt && sudo visudo -c\""
            if ask "write that drop-in on $dest?" "Apply the drop-in above on $dest over ssh? You will be asked for that device's sudo password once (it is applied only on yes, and validated with visudo -c afterwards).

⚠ /usr/bin/true is in the list on purpose: 'sudo -n true' is the probe the preflight uses." no; then
                act "sudoers drop-in written and validated on $dest" -- ssh -t "$dest" \
                    "printf '%s\n' '$line' | sudo tee /etc/sudoers.d/polari-ci-libvirt >/dev/null && sudo chmod 0440 /etc/sudoers.d/polari-ci-libvirt && sudo visudo -c" || true
            else
                todo "grant passwordless sudo for libvirt on $dest" "the drop-in above, in /etc/sudoers.d/polari-ci-libvirt"
            fi
        fi

        if ! ssh -o BatchMode=yes -o ConnectTimeout=8 "$dest" 'command -v virt-install >/dev/null && command -v virsh >/dev/null && command -v qemu-img >/dev/null' >/dev/null 2>&1; then
            howto "ssh $dest 'sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients virtinst qemu-utils cloud-image-utils'"
            howto "ssh $dest 'sudo usermod -aG libvirt \$(id -un)'   — then a new login on that device"
            if ask "install libvirt/qemu on $dest?" "The isle device is missing some of virt-install / virsh / qemu-img / cloud-localds. Install them over ssh now? (sudo on that device will prompt.)"; then
                act "libvirt tooling installed on $dest" -- ssh -t "$dest" \
                    'sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients virtinst qemu-utils cloud-image-utils && sudo usermod -aG libvirt $(id -un)' || true
            fi
        else
            check OK "libvirt tooling on $dest — already: OK"
        fi

        if ! ssh -o BatchMode=yes -o ConnectTimeout=8 "$dest" '[ -e /dev/kvm ]' >/dev/null 2>&1; then
            check MISS "$dest has no /dev/kvm — hardware virtualisation is OFF in that device's firmware, or the CPU has none"
            howto "reboot that device into its firmware/BIOS and enable VT-x (Intel) or AMD-V/SVM (AMD); nothing on this side can do it"
            todo "enable hardware virtualisation on the isle device" "its firmware setup — VT-x / AMD-V, then check: ls -l /dev/kvm"
        fi
    elif [ "$CI_ISLE_TARGET" = local ] && [ ! -e /dev/kvm ]; then
        check MISS "this machine has no /dev/kvm"
        howto "enable VT-x / AMD-V in this machine's firmware, or choose an ssh target: pol jenkins target ssh <alias>"
    fi

    # ------------------------------------------------- prove it, for real
    echo
    explain "Now the real preflight (A): is the device CLEAR of any Polari/isle installation of its own, and does it have the room? Any FAIL refuses the run — this is a resource guard, not a security gate."
    echo
    PREFLIGHT_JSON=""
    if [ "$MODE" != report ]; then bash "$J/isle/preflight.sh" --isle 2>&1 | sed 's/^/   /' || true; fi
    echo
    step_isle_check || true
}
