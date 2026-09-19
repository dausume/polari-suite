#!/bin/bash
# setup/steps/03-network.sh — the network this device needs. Outbound
# only: nothing is ever opened inbound. The two live checks (wired IPv4,
# git origin reachable) are the doctor's rows.

STEP_TITLE_network="the network — outbound only"

_wired_conns() {   # NAME<TAB>DEVICE<TAB>ACTIVE  for every wired connection nmcli knows
    command -v nmcli >/dev/null 2>&1 || return 0
    nmcli -t -f NAME,TYPE,DEVICE,STATE con show 2>/dev/null | awk -F: '$2=="802-3-ethernet"{printf "%s\t%s\t%s\n", $1, $3, ($4=="activated"?"up":"down")}'
}

step_network_check() {
    local okall=1
    doctor_check 'wired IPv4' 'wired IPv4' || okall=0
    doctor_check 'git origin' 'git origin' || okall=0
    check OK "inbound: nothing is opened — the UI binds 127.0.0.1 and every publish is an outbound push"

    local w; w="$(_wired_conns)"
    if [ -n "$w" ]; then
        printf '%s' "$w" | while IFS=$'\t' read -r n d s; do check "$([ "$s" = up ] && echo OK || echo MISS)" "nmcli connection '$n' (${d:-no device}) is $s"; done
    fi

    doctor_ok 'wired IPv4' 2>/dev/null || todo "put this device on a wire — a release build pulls gigabytes and a dropped Wi-Fi link fails the run" \
        "nmcli con show   then   nmcli con up \"<the wired connection>\""
    doctor_ok 'git origin' 2>/dev/null || todo "make github.com reachable — the jobs POLL it (no webhook, no inbound port)" \
        "git -C $SUITE ls-remote origin HEAD"

    [ "$okall" = 1 ] && state done "wired IPv4 present, github reachable, nothing inbound" || state todo "see below"
    [ "$okall" = 1 ]
}

step_network_do() {
    explain "This device needs exactly one thing from the network: a good OUTBOUND path. It polls github.com every 10 minutes, pulls gigabytes for a release build, and pushes releases out. Nothing is ever opened inbound — the Jenkins UI binds 127.0.0.1 only, there is no webhook and no tunnel.

A wire matters more than it sounds: a release build downloads base images, apt packages and npm trees, and a Wi-Fi link that drops halfway through fails the whole run."
    echo
    step_network_check || true
    echo

    if ! doctor_ok 'wired IPv4' 2>/dev/null; then
        howto "nmcli con show              — list every connection this device knows"
        howto "nmcli con up \"<name>\"       — bring the wired one up"
        local w down_name=""
        w="$(_wired_conns)"
        down_name="$(printf '%s' "$w" | awk -F'\t' '$3=="down"{print $1; exit}')"
        if [ -n "$down_name" ]; then
            if ask "bring up the wired connection?" "nmcli knows a wired connection that is down: '$down_name'.

Run  nmcli con up \"$down_name\"  now? (Plug the cable in first.)"; then
                act "wired connection '$down_name' up" -- nmcli con up "$down_name" || true
            fi
        elif [ -z "$w" ]; then
            check MISS "nmcli knows no wired connection at all — plug a cable in, or accept the Wi-Fi risk knowingly"
        fi
    fi

    if ! doctor_ok 'git origin' 2>/dev/null; then
        where "https://github.com/dausume/polari-suite — public, so polling needs no token"
        howto "git -C $SUITE ls-remote origin HEAD   (this is exactly the reachability test)"
    fi
    echo
    step_network_check || true
}
