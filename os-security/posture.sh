#!/bin/bash
# posture.sh — the node's POSTURE (ISLE_HARDENING_PLAN §16, his rulings 2026-09-14): runs ON the node as root.
#   posture.sh status
#   posture.sh dev --for 8h [--relax ssh.root-key-from-isle,host.ptrace-scope] [--cidr <isle cidr>] [--by <who>]
#   posture.sh production                       revert every relaxation now; the standing posture
#   posture.sh revert                           = production (what the expiry timer runs)
# A dev posture is a LIST of named, isle-scoped relaxations, time-boxed (a systemd timer reverts it; reboot reverts it
# too: the timer is not persistent and the apply re-checks expiry), recorded in /etc/polari/posture.json — the
# inventory, the audit's posture-assurance control and the security module read that file. The invariants never move:
# PasswordAuthentication stays off (never touched here), nothing opens on a non-isle interface.
# Refused on a production route (/etc/polari/production-route, written by pol prod apply on a server).
set -u
VERB=${1:-status}; shift || true
DIR=/etc/polari; FILE=$DIR/posture.json; SSHD_DROPIN=/etc/ssh/sshd_config.d/60-polari-dev-posture.conf
SYSCTL_DROPIN=/etc/sysctl.d/60-polari-dev-posture.conf; UNIT=polari-posture-revert
G="\033[0;32m"; Y="\033[1;33m"; R="\033[0;31m"; N="\033[0m"
ok(){ echo -e "${G}[ OK ]${N} $*"; }; warn(){ echo -e "${Y}[WARN]${N} $*"; }; die(){ echo -e "${R}[FAIL]${N} $*" >&2; exit 1; }
WARNING="DEV POSTURE: any connection to systems that are not your own is EXTREMELY DANGEROUS — the relaxed security travels with every connection. Keep this machine on your own isle."
need_root(){ [ "$(id -u)" = 0 ] || die "run as root (sudo)"; }
field(){ python3 -c "import json,sys; d=json.load(open('$FILE')); print(d.get('$1',''))" 2>/dev/null; }

isle_cidr(){   # the isle's own subnet: the WireGuard/isle interface, else the LAN the isle bridge sits on
    local c=${1:-}
    [ -n "$c" ] && { echo "$c"; return; }
    local a
    a=$(ip -4 -o addr show 2>/dev/null | awk '$2 ~ /^(wg|isle|br-isle|vlan)/ {print $4; exit}')
    if [ -z "$a" ]; then   # a home isle without a WireGuard/isle interface: the LAN the default route sits on IS the isle
        local dev; dev=$(ip -4 route show default 2>/dev/null | awk '{print $5; exit}')
        a=$(ip -4 -o addr show dev "$dev" 2>/dev/null | awk '{print $4; exit}')
        [ -n "$a" ] && warn "no isle interface — using the LAN of the default route ($dev) as the isle subnet; pass --cidr to narrow it" >&2
    fi
    python3 -c 'import ipaddress,sys; a=sys.argv[1]; print(ipaddress.ip_network(a, strict=False) if a else "")' "$a" 2>/dev/null
}

apply_relaxation(){   # $1 = name, $2 = cidr
    case "$1" in
        ssh.root-key-from-isle)
            [ -n "$2" ] || die "ssh.root-key-from-isle needs the isle cidr (--cidr) — no isle interface found"
            mkdir -p "$(dirname "$SSHD_DROPIN")"
            printf 'Match Address %s\n    PermitRootLogin prohibit-password\n' "$2" > "$SSHD_DROPIN"
            sshd -t 2>/dev/null || { rm -f "$SSHD_DROPIN"; die "sshd rejected the drop-in"; }
            systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || true
            ok "ssh: root with a KEY from $2 only (Match Address; passwords stay off) — $SSHD_DROPIN" ;;
        host.ptrace-scope)
            echo 'kernel.yama.ptrace_scope = 0' > "$SYSCTL_DROPIN"; sysctl -q -p "$SYSCTL_DROPIN" 2>/dev/null || true
            ok "host: ptrace_scope 0 (debuggers may attach) — $SYSCTL_DROPIN" ;;
        host.core-dumps)
            echo 'kernel.core_pattern = core.%e.%p' >> "$SYSCTL_DROPIN"; sysctl -q -p "$SYSCTL_DROPIN" 2>/dev/null || true
            ok "host: core dumps on" ;;
        mac.complain|seccomp.log|net.isle-port|dac.dev-group-write|ssh.group)
            warn "$1: recorded (applied by the os-security rings / the isle CLI, not by this script)" ;;
        *) die "unknown relaxation '$1' (ssh.root-key-from-isle, host.ptrace-scope, host.core-dumps, mac.complain, seccomp.log, net.isle-port, dac.dev-group-write, ssh.group)" ;;
    esac
}

revert_all(){
    if [ -f "$SSHD_DROPIN" ]; then rm -f "$SSHD_DROPIN"; systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || true; ok "ssh: root-from-isle relaxation removed"; fi
    if [ -f "$SYSCTL_DROPIN" ]; then rm -f "$SYSCTL_DROPIN"; sysctl -q -w kernel.yama.ptrace_scope=1 2>/dev/null || true; ok "host: sysctl relaxations removed"; fi
    systemctl stop "$UNIT.timer" 2>/dev/null; systemctl disable "$UNIT.timer" 2>/dev/null; rm -f "/etc/systemd/system/$UNIT.timer" "/etc/systemd/system/$UNIT.service"; systemctl daemon-reload 2>/dev/null
}

write_posture(){   # $1 mode, $2 until, $3 relaxations csv, $4 by
    mkdir -p "$DIR"
    python3 - "$1" "$2" "$3" "$4" "$FILE" <<'PY'
import json, sys, time
mode, until, rlx, by, path = sys.argv[1:6]
json.dump({'posture': mode, 'until': until, 'relaxations': [r for r in rlx.split(',') if r], 'applied_by': by, 'written': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())}, open(path, 'w'), indent=1)
PY
    chmod 644 "$FILE"
}

case "$VERB" in
    status)
        if [ -f "$FILE" ]; then
            echo "posture: $(field posture)  until: $(field until)  relaxations: $(python3 -c "import json; print(', '.join(json.load(open('$FILE')).get('relaxations', [])) or 'none')")  by: $(field applied_by)"
            systemctl is-active "$UNIT.timer" >/dev/null 2>&1 && echo "revert timer: $(systemctl show "$UNIT.timer" -p NextElapseUSecRealtime --value)"
        else echo "posture: production (no $FILE)"; fi
        [ -f "$SSHD_DROPIN" ] && echo "ssh drop-in present: $(tr '\n' ' ' < "$SSHD_DROPIN")"
        [ -f /etc/polari/production-route ] && echo "production route: $(cat /etc/polari/production-route)"
        exit 0 ;;
    dev)
        need_root
        [ -f /etc/polari/production-route ] && die "REFUSED: this machine is on a PRODUCTION route ($(cat /etc/polari/production-route)) — a dev posture never exists there (plan §16 invariant 5)"
        FOR=8h; RLX=""; CIDR=""; BY=${SUDO_USER:-$(id -un)}
        while [ $# -gt 0 ]; do case "$1" in --for) FOR="$2"; shift 2 ;; --relax) RLX="$2"; shift 2 ;; --cidr) CIDR="$2"; shift 2 ;; --by) BY="$2"; shift 2 ;; *) shift ;; esac; done
        SECS=$(python3 -c "
import re,sys; m=re.fullmatch(r'(\d+)([hmd]?)', '$FOR'); u={'':3600,'h':3600,'m':60,'d':86400}[m.group(2)] if m else None; print(int(m.group(1))*u if m else 0)")
        [ "$SECS" -gt 0 ] || die "--for takes 30m | 8h | 2d"
        [ "$SECS" -le $((7*86400)) ] || die "--for never exceeds 7 days (plan §16)"
        UNTIL=$(date -u -d "+$SECS seconds" +%FT%TZ)
        CIDR=$(isle_cidr "$CIDR")
        # the revert timer needs a copy that outlives this run (pol deploy ships this script to /tmp and removes it)
        SELF=/usr/local/lib/polari/posture.sh; mkdir -p "$(dirname "$SELF")"; cp "$(readlink -f "$0")" "$SELF"; chmod 755 "$SELF"
        revert_all >/dev/null 2>&1
        IFS=, read -ra R <<< "$RLX"; for r in "${R[@]}"; do [ -n "$r" ] && apply_relaxation "$r" "$CIDR"; done
        write_posture dev "$UNTIL" "$RLX" "$BY"
        cat > "/etc/systemd/system/$UNIT.service" <<EOF
[Unit]
Description=Polari: revert the dev posture at its expiry
[Service]
Type=oneshot
ExecStart=/bin/bash $SELF revert
EOF
        cat > "/etc/systemd/system/$UNIT.timer" <<EOF
[Unit]
Description=Polari: the dev posture expires at $UNTIL
[Timer]
OnCalendar=$(date -u -d "@$(( $(date +%s) + SECS ))" '+%Y-%m-%d %H:%M:%S UTC')
Persistent=false
[Install]
WantedBy=timers.target
EOF
        systemctl daemon-reload && systemctl enable --now "$UNIT.timer" >/dev/null 2>&1 && ok "revert timer set for $UNTIL (a reboot also reverts)"
        ok "$FILE: posture=dev until $UNTIL, relaxations: ${RLX:-none}, isle cidr: ${CIDR:-none}"
        echo -e "${Y}$WARNING${N}"; exit 0 ;;
    production|revert)
        need_root
        revert_all
        write_posture production "" "" "${SUDO_USER:-$(id -un)}"
        ok "$FILE: posture=production — every relaxation reverted"; exit 0 ;;
    *) echo "usage: posture.sh status | dev --for 8h [--relax a,b] [--cidr <isle cidr>] | production | revert"; exit 1 ;;
esac
