#!/bin/bash
# setup/steps/02-checkout.sh — the checkout, the CLI and the host tools.
# Every check here is a DOCTOR row (submodules / pol CLI / host tools /
# docker group were added to doctor.sh for exactly this reason) — setup
# reads them and offers to fix each locally.

STEP_TITLE_checkout="the checkout and the CLI"

_missing_tools() {   # the doctor's "host tools" row lists what is absent
    local m; m="$(doctor_what 'host tools' 2>/dev/null || true)"
    case "$m" in absent:*) printf '%s' "${m#absent:}" ;; *) printf '' ;; esac
}
_apt_names() {   # tool names → package names
    local t out=""
    for t in $1; do case "$t" in docker) out="$out docker.io" ;; *) out="$out $t" ;; esac; done
    printf '%s' "${out# }"
}

step_checkout_check() {
    local okall=1
    doctor_check 'submodules' 'submodules' || okall=0
    doctor_check 'pol CLI'    'pol CLI'    || okall=0
    doctor_check 'host tools' 'host tools' || okall=0

    local me; me="$(id -un)"
    if doctor_check 'your docker access' 'docker group'; then :; else
        okall=0
        todo "put $me in the docker group (it is root-equivalent — grant it deliberately)" \
             "sudo usermod -aG docker $me   then log out and back in"
    fi

    doctor_row 'submodules' >/dev/null 2>&1 && ! doctor_ok 'submodules' && \
        todo "populate the submodules" "$(doctor_fix 'submodules')"
    doctor_row 'pol CLI' >/dev/null 2>&1 && ! doctor_ok 'pol CLI' && \
        todo "install the pol CLI" "bash $SUITE/polari-cli/shells/install-cli.sh"
    local miss; miss="$(_missing_tools)"
    [ -n "$miss" ] && todo "install the missing host tools:$miss" "sudo apt-get install -y $(_apt_names "$miss")"

    [ "$okall" = 1 ] && state done "checkout, pol, docker and the host tools are all in place" || state todo "something below is missing"
    [ "$okall" = 1 ]
}

# ci-11a — the same three offers the interactive path makes, declared. Two of
# them need root and are therefore only DESCRIBED here: they name a verb from
# shell-verbs.json and are never run by this script in JSON mode.
step_checkout_json() {
    json_explain "The pipeline is the suite checkout plus four things on the host: the pol CLI (it is how every verb here is spelled), docker (the controller AND every build run in containers), python3/git/curl (the scripts), and whiptail (the terminal dialogs — optional).

Docker-group membership is ROOT-EQUIVALENT on this machine: anyone in it can mount the host filesystem into a container as root. Grant it to you and to the pipeline user, nobody else."
    json_where 'docker engine (everything else is plain apt)' 'https://docs.docker.com/engine/install/ubuntu/' ''
    local miss me; miss="$(_missing_tools)"; me="$(id -un)"
    json_action apt-install-tools "Install the host tools this device is missing${miss:+:$miss}" 1 apt-install-tools \
        "$([ -z "$miss" ] && echo 1 || echo 0)" \
        "apt needs root. The argv is fixed in shell-verbs.json — libvirt-clients virtinst qemu-utils cloud-image-utils whiptail — and takes nothing from this device." ''
    json_action docker-group "Put $me in the docker group" 1 docker-group \
        "$(id -nG "$me" 2>/dev/null | tr ' ' '\n' | grep -qx docker && echo 1 || echo 0)" \
        "usermod needs root. ⚠ the group is ROOT-EQUIVALENT: a member can start a container that mounts / as root. A new login is needed afterwards." \
        "user=$me"
    json_action install-cli 'Install the pol CLI from this checkout' 0 setup-run \
        "$(command -v pol >/dev/null 2>&1 && echo 1 || echo 0)" \
        'runs polari-cli/shells/install-cli.sh. Without root it links ~/.local/bin/pol, which is NOT a safe target for an elevated run — the doctor says so, and `sudo bash polari-cli/shells/install-cli.sh` links /usr/local/bin/pol instead.' \
        'action=install-cli'
    json_action submodules 'Populate the submodules' 0 setup-run \
        "$(doctor_ok 'submodules' 2>/dev/null && echo 1 || echo 0)" \
        'git submodule update --init --recursive — it pulls several GB' 'action=submodules'
}

step_checkout_do() {
    explain "The pipeline is the suite checkout plus four things on the host: the pol CLI (it is how every verb here is spelled), docker (the controller AND every build run in containers), python3/git/curl (the scripts), and whiptail (these dialogs — optional, without it you get plain prompts).

Docker-group membership is ROOT-EQUIVALENT on this machine: anyone in it can mount the host filesystem into a container as root. Grant it to you and to the pipeline user, nobody else."
    echo
    step_checkout_check || true
    echo

    local miss; miss="$(_missing_tools)"
    if [ -n "$miss" ]; then
        where "apt for everything but docker; the upstream docker repo is https://docs.docker.com/engine/install/ubuntu/"
        howto "sudo apt-get install -y $(_apt_names "$miss")"
        if ask "install the missing host tools?" "Missing:$miss

Run  sudo apt-get install -y $(_apt_names "$miss")  now? sudo will ask for your password itself."; then
            act "installed:$miss" -- sudo apt-get install -y $(_apt_names "$miss") || true
        fi
    fi

    if ! doctor_ok 'pol CLI' 2>/dev/null; then
        where "$SUITE/polari-cli/shells/install-cli.sh (in this checkout)"
        howto "bash polari-cli/shells/install-cli.sh"
        if ask "install the pol CLI?" "pol is not on PATH. Install it from this checkout now?"; then
            act "pol installed (open a new shell if the name is still not found)" -- bash "$SUITE/polari-cli/shells/install-cli.sh" || true
        fi
    fi

    local me; me="$(id -un)"
    if [ "$(id -u)" != 0 ] && ! id -nG "$me" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
        howto "sudo usermod -aG docker $me   (then log out and back in — group membership is read at login)"
        if ask "add $me to the docker group?" "Every build goes through the docker socket, so $me must be in the docker group.

⚠ Membership is ROOT-EQUIVALENT: a member can start a container that mounts / as root. Add $me?"; then
            act "$me added to the docker group — LOG OUT AND BACK IN before pol jenkins up" -- sudo usermod -aG docker "$me" || true
        fi
    fi

    if ! doctor_ok 'submodules' 2>/dev/null; then
        howto "git -C $SUITE submodule update --init --recursive   (or ./bootstrap-dev.sh for the piece-wise pull)"
        if ask "populate the submodules?" "Some submodules are empty. Run git submodule update --init --recursive? It pulls several GB."; then
            act "submodules populated" -- git -C "$SUITE" submodule update --init --recursive || true
        fi
    fi
    echo
    step_checkout_check || true
}
