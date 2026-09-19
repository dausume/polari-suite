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
