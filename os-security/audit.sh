#!/bin/bash
# os-security/audit.sh — score every ring on THIS machine. Read-only. pass/fail/skip
# per control with the evidence, a verdict (hardened | partial | open), --json for rows.
#   bash audit.sh [--scenario isle] [--json]
set -u
SC="${OS_SEC_SCENARIO:-}"; JSON=false
while [ $# -gt 0 ]; do case "$1" in --scenario) SC="$2"; shift 2 ;; --json) JSON=true; shift ;; *) shift ;; esac; done
SUDO=""; [ "$(id -u)" = 0 ] || { sudo -n true 2>/dev/null && SUDO="sudo -n"; }
R=(); P=0; F=0; S=0
res() { # ring control status evidence
    R+=("{\"ring\":\"$1\",\"control\":\"$2\",\"status\":\"$3\",\"evidence\":\"$(echo "$4" | sed 's/"/\\"/g' | tr -d '\n' | cut -c1-200)\"}")
    case "$3" in pass) P=$((P+1)); c="\033[0;32mpass\033[0m" ;; fail) F=$((F+1)); c="\033[0;31mFAIL\033[0m" ;; *) S=$((S+1)); c="\033[1;33mskip\033[0m" ;; esac
    $JSON || printf "  %-8s %-34s %b  %s\n" "$1" "$2" "$c" "$4"
}
$JSON || echo "os-security audit · $(hostname) · $(date -Is)${SC:+ · scenario $SC}"
# ---- DAC
if docker info >/dev/null 2>&1; then
    SO=$(docker info --format '{{json .SecurityOptions}}' 2>/dev/null)
    echo "$SO" | grep -q userns && res dac userns-remap pass "$SO" || res dac userns-remap fail "container root = host root ($SO)"
    ROOTS=$(for c in $(docker ps -q); do docker inspect "$c" --format '{{.Name}} user={{.Config.User}} nnp={{.HostConfig.SecurityOpt}}'; done | grep -c 'user= ' || true)
    [ "$ROOTS" = 0 ] && res dac containers-non-root pass "every container declares a user" || res dac containers-non-root fail "$ROOTS container(s) run as root inside"
    PRIV=$(for c in $(docker ps -q); do docker inspect "$c" --format '{{.HostConfig.Privileged}}'; done | grep -c true || true)
    [ "$PRIV" = 0 ] && res dac no-privileged pass "no --privileged" || res dac no-privileged fail "$PRIV privileged container(s)"
    SOCK=$(for c in $(docker ps -q); do docker inspect "$c" --format '{{range .Mounts}}{{.Source}} {{end}}'; done | grep -c docker.sock || true)
    [ "$SOCK" = 0 ] && res dac no-docker-socket-mounts pass "no container mounts docker.sock" || res dac no-docker-socket-mounts fail "$SOCK container(s) mount docker.sock"
    RO=$(for c in $(docker ps -q); do docker inspect "$c" --format '{{.HostConfig.ReadonlyRootfs}}'; done | grep -c false || true)
    [ "$RO" = 0 ] && res dac read-only-rootfs pass "all read-only" || res dac read-only-rootfs fail "$RO container(s) with a writable root filesystem"
else res dac userns-remap skip "docker not reachable"; fi
[ -d /etc/isle-mesh ] && { M=$(stat -c '%a %U:%G' /etc/isle-mesh); case "$M" in 750*|700*) res dac isle-state-perms pass "$M" ;; *) res dac isle-state-perms fail "/etc/isle-mesh is $M (want 750 root:isle-admin)" ;; esac; } || res dac isle-state-perms skip "no /etc/isle-mesh"
G=$(ls /etc/sudoers.d/ 2>/dev/null | grep -c "^polari-" || true); [ "$G" -gt 0 ] && res dac sudo-groups pass "$G polari sudoers group file(s)" || res dac sudo-groups fail "no polari-remote/polari-app sudoers groups (pol deploy grant)"
# ---- MAC
if $SUDO aa-status >/dev/null 2>&1; then
    AAS=$($SUDO aa-status 2>/dev/null)
    echo "$AAS" | grep -q "apparmor module is loaded" && res mac apparmor-loaded pass "$(echo "$AAS" | grep -m1 'profiles are loaded')" || res mac apparmor-loaded fail "module not loaded"
    N=$(echo "$AAS" | grep -c "isle-app-" || true); [ "$N" -gt 0 ] && res mac per-app-profiles pass "$N isle-app-* profile(s) loaded" || res mac per-app-profiles fail "no isle-app-* profiles (os-security apply)"
    C=$(echo "$AAS" | sed -n '/complain mode/,/processes/p' | grep -c "isle-app-" || true); [ "$C" = 0 ] && res mac profiles-enforcing pass "none in complain" || res mac profiles-enforcing fail "$C isle-app-* profile(s) in complain mode"
    if docker info >/dev/null 2>&1; then
        GEN=$(for c in $(docker ps -q); do docker inspect "$c" --format '{{.AppArmorProfile}}'; done | grep -c '^docker-default$' || true)
        [ "$GEN" = 0 ] && res mac containers-per-app-profile pass "no container on the generic profile" || res mac containers-per-app-profile fail "$GEN container(s) on docker-default (generic)"
        SEC=$(for c in $(docker ps -q); do docker inspect "$c" --format '{{.HostConfig.SecurityOpt}}'; done | grep -c seccomp || true)
        [ "$SEC" -gt 0 ] && res mac seccomp-per-kind pass "$SEC container(s) with an explicit seccomp profile" || res mac seccomp-per-kind fail "builtin seccomp only"
    fi
else res mac apparmor-loaded skip "aa-status needs root"; fi
if command -v virsh >/dev/null 2>&1; then
    U=$($SUDO virsh list --name 2>/dev/null | grep -c . || true)
    if [ "$U" -gt 0 ]; then UN=$(for v in $($SUDO virsh list --name); do $SUDO virsh dominfo "$v" | grep -q "Security model: apparmor" || echo "$v"; done | wc -w); [ "$UN" = 0 ] && res mac svirt-guests pass "$U guest(s) under libvirt AppArmor" || res mac svirt-guests fail "$UN guest(s) unconfined"; else res mac svirt-guests skip "no running guests"; fi
fi
# ---- NETWORK
DU=$($SUDO iptables -S DOCKER-USER 2>/dev/null | grep -c "os-security" || true); [ "$DU" -gt 0 ] && res network docker-user-rules pass "$DU rule(s)" || res network docker-user-rules fail "DOCKER-USER carries no os-security rules (containers can reach host services)"
UF=$($SUDO ufw status 2>/dev/null | head -1); case "$UF" in *active*) [ "${UF#*: }" = active ] && res network ufw pass "$UF" || res network ufw fail "$UF" ;; *) res network ufw skip "ufw not readable" ;; esac
SSHALL=$(ss -ltn 2>/dev/null | awk '$4 ~ /(^0\.0\.0\.0|^\*|^\[::\]):22$/' | wc -l); [ "$SSHALL" = 0 ] && res network ssh-not-on-all-interfaces pass "sshd bound to specific addresses" || res network ssh-not-on-all-interfaces fail "sshd listens on all interfaces (ufw/sshd ListenAddress)"
TCP=$(ss -ltn 2>/dev/null | grep -cE ':2375 |:2376 ' || true); [ "$TCP" = 0 ] && res network no-docker-tcp pass "no docker TCP socket" || res network no-docker-tcp fail "docker listens on TCP"
if docker info >/dev/null 2>&1 && docker info --format '{{.Swarm.LocalNodeState}}' | grep -q active; then
    ENC=$(docker network ls --filter driver=overlay -q | xargs -r docker network inspect --format '{{.Name}} {{index .Options "encrypted"}}' 2>/dev/null | grep -v ingress | grep -vc 'true' || true)
    [ "$ENC" = 0 ] && res network overlay-encrypted pass "every overlay encrypted" || res network overlay-encrypted fail "$ENC overlay network(s) unencrypted"
fi
# ---- HOST
for k in kernel.kptr_restrict=2 kernel.dmesg_restrict=1 kernel.unprivileged_bpf_disabled=1 fs.protected_symlinks=1 fs.protected_hardlinks=1; do
    v=$(sysctl -n "${k%=*}" 2>/dev/null); { [ "$v" = "${k#*=}" ] || { [ "${k%=*}" = kernel.unprivileged_bpf_disabled ] && [ "${v:-0}" -ge 1 ]; }; } && res host "sysctl ${k%=*}" pass "$v" || res host "sysctl ${k%=*}" fail "is ${v:-unset}, want ${k#*=}"
done
command -v auditctl >/dev/null 2>&1 && { $SUDO auditctl -l 2>/dev/null | grep -q isle-state && res host auditd-rules pass "isle rules loaded" || res host auditd-rules fail "auditd present, isle rules not loaded"; } || res host auditd-rules fail "auditd not installed"
[ -f /etc/apt/apt.conf.d/20auto-upgrades ] && grep -q '"1"' /etc/apt/apt.conf.d/20auto-upgrades && res host unattended-upgrades pass "enabled" || res host unattended-upgrades fail "not enabled"
# ---- verdict
if [ "$F" = 0 ]; then V=hardened; elif [ "$P" -gt "$F" ]; then V=partial; else V=open; fi
if $JSON; then printf '{"host":"%s","scenario":"%s","verdict":"%s","pass":%d,"fail":%d,"skip":%d,"controls":[%s]}\n' "$(hostname)" "$SC" "$V" "$P" "$F" "$S" "$(IFS=,; echo "${R[*]}")"
else echo; echo "  verdict: $V   ($P pass, $F fail, $S skip)"; fi
[ "$V" = hardened ]
