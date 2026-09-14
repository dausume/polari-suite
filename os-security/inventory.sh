#!/bin/bash
# os-security/inventory.sh — READ-ONLY: what Polari put on this machine and in what form (debs, docker images/containers/
# stacks/volumes, checkouts, CLIs, units, timers, guests, apt sources, the rings' files), and the machine's ssh capabilities as a
# security vector (listen addresses, auth methods, root login, authorized keys by TYPE and hashed comment — never key
# material, private keys present, outbound relationships, fail2ban, failed logins). JSON on stdout.
#   bash inventory.sh            pol deploy inventory <node> [--post <core url>]   (POST /api/security/inventory)
S="sudo -n"; $S true 2>/dev/null || S=""
j() { python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"; }
echo "{"
echo "\"role_hint\": \"$(hostname | sed 's/.*/host/')\", \"os\": $(j "$(lsb_release -ds 2>/dev/null)"), \"kernel\": \"$(uname -r)\", \"arch\": \"$(uname -m)\","
echo "\"docker\": {\"version\": \"$(docker version --format '{{.Server.Version}}' 2>/dev/null)\", \"swarm\": \"$(docker info --format '{{.Swarm.LocalNodeState}}/{{.Swarm.ControlAvailable}}' 2>/dev/null)\","
echo " \"containers\": $(docker ps --format '{{.Names}}|{{.Image}}|{{.Status}}' 2>/dev/null | python3 -c 'import sys,json; print(json.dumps([dict(zip(("name","image","status"), l.strip().split("|"))) for l in sys.stdin if l.strip()]))'),"
echo " \"images\": $(docker images --format '{{.Repository}}:{{.Tag}}|{{.Size}}' 2>/dev/null | grep -iE 'polari|prf|pol-|psc|isle|keycloak|mariadb|minio|keydb|nginx|python|alpine|odoo|jenkins' | python3 -c 'import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()][:40]))'),"
echo " \"stacks\": $(docker stack ls --format '{{.Name}}|{{.Services}}' 2>/dev/null | python3 -c 'import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))'),"
echo " \"volumes\": $(docker volume ls --format '{{.Name}}' 2>/dev/null | grep -icE 'polari|prf|pol_|psc|isle' || true)},"
echo "\"debs\": $(dpkg-query -W -f='${Package}|${Version}|${Status}\n' 2>/dev/null | grep -iE '^(polari|isle|shell-core|prf|pol-)' | python3 -c 'import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))'),"
echo "\"apt_sources\": $(grep -rhoE 'https?://[^ ]+' /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources 2>/dev/null | sort -u | grep -iE 'isle|polari|docker' | python3 -c 'import sys,json; print(json.dumps([l.strip() for l in sys.stdin]))'),"
echo "\"clis\": {\"pol\": \"$(command -v pol 2>/dev/null)\", \"isle\": \"$(command -v isle 2>/dev/null)\", \"isle_share\": $( [ -d /usr/share/isle-mesh ] && echo true || echo false ), \"pol_version\": $(j "$(pol --version 2>/dev/null | head -1)")},"
echo "\"checkouts\": $(for d in ~/Desktop/polari-suite ~/polari-suite ~/Isle-Mesh ~/polari-isle /opt/polari /var/lib/polari; do [ -e "$d" ] && printf '%s|%s|%s\n' "$d" "$( [ -d "$d/.git" ] && git -C "$d" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '-' )" "$(du -sh "$d" 2>/dev/null | cut -f1)"; done | python3 -c 'import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))'),"
echo "\"units\": $(systemctl list-units --type=service --all --no-legend --plain 2>/dev/null | awk '{print $1"|"$3"|"$4}' | grep -iE 'isle|polari|mesh|docker|libvirtd|jenkins|ssh|certbot' | python3 -c 'import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))'),"
echo "\"timers\": $(systemctl list-timers --all --no-legend --plain 2>/dev/null | grep -iE 'isle|polari|renew|certbot' | awk '{print $NF}' | python3 -c 'import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))'),"
echo "\"guests\": $( $S virsh list --all --name 2>/dev/null | grep -v '^$' | python3 -c 'import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))'),"
echo "\"kvm\": $( [ -e /dev/kvm ] && echo true || echo false ), \"iommu\": $( [ -n "$(ls /sys/kernel/iommu_groups 2>/dev/null)" ] && echo true || echo false ),"
echo "\"etc_isle_mesh\": $( [ -d /etc/isle-mesh ] && echo true || echo false ), \"etc_polari\": $( [ -d /etc/polari ] && echo true || echo false ), \"apparmor_polari\": $( ls /etc/apparmor.d/isle-app-* /etc/apparmor.d/docker-default 2>/dev/null | wc -l ),"
echo "\"sudoers_polari\": $(ls /etc/sudoers.d/ 2>/dev/null | grep -c '^polari-' || true), \"passwordless_sudo_for_me\": $( [ -n "$S" ] && echo true || echo false ),"
# ---- ssh as a security vector (no key material: types + hashed comments only)
SSHD=$( $S sshd -T 2>/dev/null )
echo "\"ssh\": {\"listen\": $(ss -ltn 2>/dev/null | awk '$4 ~ /:22$/ {print $4}' | python3 -c 'import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))'),"
echo " \"password_auth\": \"$(echo "$SSHD" | awk '/^passwordauthentication/ {print $2}')\", \"pubkey_auth\": \"$(echo "$SSHD" | awk '/^pubkeyauthentication/ {print $2}')\", \"permit_root\": \"$(echo "$SSHD" | awk '/^permitrootlogin/ {print $2}')\", \"kbd_interactive\": \"$(echo "$SSHD" | awk '/^kbdinteractiveauthentication/ {print $2}')\", \"max_auth_tries\": \"$(echo "$SSHD" | awk '/^maxauthtries/ {print $2}')\", \"allow_users\": \"$(echo "$SSHD" | awk '/^allowusers/ {print $2}')\", \"sshd_t_readable\": $( [ -n "$SSHD" ] && echo true || echo false ),"
# ---- permission levels behind ssh (his ask 2026-09-14): who may log in (AllowGroups), the groups and their members,
#      every sudoers grant (blanket ALL vs a command list), and the declared posture (/etc/polari/posture.json: secure|dev + until)
echo " \"allow_groups\": \"$(echo "$SSHD" | awk '/^allowgroups/ {$1=""; print}' | xargs)\", \"allow_users_list\": \"$(echo "$SSHD" | awk '/^allowusers/ {$1=""; print}' | xargs)\","
echo " \"groups\": $( { getent group sudo admin wheel; getent group | grep -E '^polari-'; } 2>/dev/null | awk -F: '{print $1"|"$4}' | python3 -c 'import sys,json; print(json.dumps(sorted({l.strip() for l in sys.stdin if l.strip()})))'),"
echo " \"sudoers\": $( $S cat /etc/sudoers /etc/sudoers.d/* 2>/dev/null | grep -vE '^[[:space:]]*(#|$|Defaults|@include|#include)' | python3 -c 'import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))'),"
echo " \"posture\": $( $S cat /etc/polari/posture.json 2>/dev/null | python3 -c 'import sys,json; print(json.dumps(json.load(sys.stdin)))' 2>/dev/null || echo null ),"
echo " \"root_match_dropins\": $(grep -lsE 'PermitRootLogin' /etc/ssh/sshd_config.d/* 2>/dev/null | python3 -c 'import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))'),"
echo " \"authorized_keys\": $(for h in /root /home/*; do f=$h/.ssh/authorized_keys; [ -r "$f" ] || f=$( $S test -r "$f" 2>/dev/null && echo "$f" ); [ -n "$f" ] && $S cat "$f" 2>/dev/null | grep -vE '^\s*(#|$)' | awk -v u="$(basename $h)" '{c=$NF; if (NF<3) c=""; print u"|"$1"|"c}'; done | python3 -c '
import sys,json,hashlib
out=[]
for l in sys.stdin:
    u,t,c=(l.rstrip("\n").split("|")+["",""])[:3]
    out.append({"user":u,"type":t,"comment_hash":hashlib.sha256(c.encode()).hexdigest()[:10] if c else "", "comment_kind": ("user@host" if "@" in c else ("named" if c else "none"))})
print(json.dumps(out))'),"
echo " \"host_keys\": $(ls /etc/ssh/ssh_host_*_key.pub 2>/dev/null | sed 's|.*/ssh_host_||; s|_key.pub||' | python3 -c 'import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))'),"
echo " \"outbound_known_hosts\": $(for h in /root /home/*; do f=$h/.ssh/known_hosts; $S test -r "$f" 2>/dev/null && $S wc -l < "$f" | awk -v u="$(basename $h)" '{print u"|"$1}'; done | python3 -c 'import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))'),"
echo " \"private_keys_present\": $(for h in /root /home/*; do for k in $h/.ssh/id_*; do case "$k" in *.pub) continue;; esac; $S test -f "$k" 2>/dev/null && echo "$(basename $h)|$(basename $k)"; done; done | python3 -c 'import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))'),"
echo " \"ssh_config_hosts\": $(for h in /root /home/*; do $S grep -hE '^Host ' $h/.ssh/config 2>/dev/null | awk -v u="$(basename $h)" '{print u"|"$2}'; done | python3 -c 'import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))'),"
echo " \"fail2ban\": \"$( systemctl is-active fail2ban 2>/dev/null; true )\", \"ufw\": \"$( $S ufw status 2>/dev/null | head -1 )\", \"recent_failed_logins_24h\": $( $S journalctl -u ssh -u sshd --since '24 hours ago' --no-pager 2>/dev/null | grep -c 'Failed password\|Invalid user' || true )}"
echo "}"
