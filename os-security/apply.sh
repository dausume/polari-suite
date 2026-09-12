#!/bin/bash
# os-security/apply.sh — load what render.py produced for a scenario, on THIS machine.
#   sudo bash apply.sh --scenario isle [--complain|--enforce] [--rings mac,network,host,dac] [--dry-run]
# Idempotent. Profiles of apps that are no longer in the rendered manifest are unloaded
# and their files removed (the policy follows the apps up and down). Docker's
# daemon.json is DIFFED, never written (a restart is the operator's window).
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# WARN-ONLY by default (his rule 2026-09-12): AppArmor profiles load in complain mode (everything is logged, nothing is
# denied) and the rings that cannot warn — the firewall chains, sysctl, permissions — are only PRINTED unless --enforce
# is given explicitly. Change one piece, re-test (audit + escape-test + pol prod verify), then move to the next.
SC=""; MODE="complain"; RINGS="mac,network,host,dac"; DRY=false; ENFORCE=false; REVERT=false
while [ $# -gt 0 ]; do case "$1" in
    --scenario) SC="$2"; shift 2 ;; --complain) MODE=complain; shift ;; --enforce) MODE=enforce; ENFORCE=true; shift ;;
    --rings) RINGS="$2"; shift 2 ;; --dry-run) DRY=true; shift ;; --revert-docker-default) REVERT=true; shift ;; *) shift ;;
esac; done
[ -n "$SC" ] || { echo "usage: apply.sh --scenario <name> [--complain|--enforce] [--rings …] [--dry-run] [--revert-docker-default]" >&2; exit 1; }
OUT="$HERE/out/$SC"; [ -f "$OUT/manifest.json" ] || { echo "not rendered: $OUT — python3 $HERE/render.py --scenario $SC …" >&2; exit 1; }
$DRY || [ "$(id -u)" = 0 ] || { echo "apply needs root (or --dry-run)" >&2; exit 1; }
has() { case ",$RINGS," in *,"$1",*) return 0 ;; *) return 1 ;; esac; }
run() { if $DRY; then echo "  [dry-run] $*"; else "$@"; fi; }
warn_only() { if $ENFORCE; then "$@"; else echo "  [warn-only — not applied; --enforce to apply] $*"; fi; }   # rings that cannot warn
G="\033[0;32m"; Y="\033[1;33m"; N="\033[0m"; ok(){ echo -e "${G}[ OK ]${N} $*"; }; warn(){ echo -e "${Y}[WARN]${N} $*"; }
ATTACH=$(python3 -c "import json; print(json.load(open('$OUT/manifest.json')).get('mac_attach','security_opt'))")

if $REVERT; then
    # put docker's STOCK docker-default back in the kernel (live: running containers switch at once), forget ours
    [ -f "$OUT/apparmor/docker-default.moby" ] || { echo "no stock copy rendered for $SC (mac_attach is $ATTACH)" >&2; exit 1; }
    run apparmor_parser -r --skip-cache "$OUT/apparmor/docker-default.moby" && ok "docker-default: stock profile restored (enforce, as docker loads it)"
    run rm -f /etc/apparmor.d/docker-default && ok "/etc/apparmor.d/docker-default removed — the next docker start loads its own again"
    exit 0
fi

if has mac; then
    echo "== MAC: AppArmor profiles ($SC, attach via $ATTACH)"
    command -v apparmor_parser >/dev/null || { warn "apparmor_parser missing (apt install apparmor)"; }
    if [ "$ATTACH" = docker-default ]; then
        # swarm: services cannot carry security_opt, so the ONE profile every container gets is replaced
        # (apparmor_parser -r swaps it live for running containers; dockerd only loads its own when none is
        # loaded, and /etc/apparmor.d/docker-default is loaded at boot before docker). In complain mode the
        # profile keeps docker's stock explicit denies and logs everything narrower as ALLOWED — nothing
        # is denied that stock docker does not deny today. --revert-docker-default puts the stock one back.
        flag=""; [ "$MODE" = complain ] && flag="-C"
        run install -m 0644 "$OUT/apparmor/docker-default" /etc/apparmor.d/docker-default
        run apparmor_parser -r --skip-cache $flag /etc/apparmor.d/docker-default && ok "docker-default replaced by the node-wide union profile ($MODE) — every container on this node is under it now"
        $DRY || { command -v docker >/dev/null 2>&1 && docker info --format '{{json .SecurityOptions}}' 2>/dev/null | grep -q apparmor || warn "docker does not report apparmor among its security options — is AppArmor enabled for the daemon?"; }
    fi
    WANT=$(python3 -c "import json; m=json.load(open('$OUT/manifest.json')); print(' '.join(x['profile'] for x in m['apps']+m['fixed']))")
    for P in $OUT/apparmor/isle-app-*; do
        name=$(basename "$P"); m=$(python3 -c "import json; m=json.load(open('$OUT/manifest.json')); print(next((x['mode'] for x in m['apps']+m['fixed'] if x['profile']=='$name'), 'enforce'))")
        [ -n "$MODE" ] && m=$MODE
        [ -n "$MODE" ] && m="$MODE"; flag=""; [ "$m" = complain ] && flag="-C"
        run install -m 0644 "$P" "/etc/apparmor.d/$name"
        # --skip-cache: the parser's cache is keyed by basename, and a complain→enforce change of the same
        # file can come back as "same as current profile, skipping" (seen 2026-09-12); our profiles are small
        run apparmor_parser -r --skip-cache $flag "/etc/apparmor.d/$name" && ok "$name ($m)"
    done
    # profiles for apps that are gone: unload + remove
    for F in /etc/apparmor.d/isle-app-*; do
        [ -e "$F" ] || continue; n=$(basename "$F")
        case " $WANT " in *" $n "*) ;; *) run apparmor_parser -R "$F" 2>/dev/null || true; run rm -f "$F"; ok "$n removed (app no longer up)" ;; esac
    done
    warn_only install -d -m 0755 /etc/polari/seccomp; for S in $OUT/seccomp/*.json; do run install -m 0644 "$S" "/etc/polari/seccomp/$(basename "$S")"; done
    ok "seccomp allow-lists in /etc/polari/seccomp/"
fi
if has network; then
    echo "== NETWORK: DOCKER-USER + ufw"
    warn_only bash "$OUT/docker-user.sh"
    warn_only bash "$OUT/ufw.sh"
fi
if has host; then
    echo "== HOST: sysctl, auditd, units"
    warn_only install -m 0644 "$OUT/sysctl.conf" /etc/sysctl.d/60-polari-os-security.conf && warn_only sysctl -q --system && ok "sysctl $($ENFORCE && echo applied || echo "printed (warn-only)")"
    if command -v auditctl >/dev/null 2>&1; then
        warn_only install -m 0640 "$OUT/audit.rules" /etc/audit/rules.d/60-polari-os-security.rules && run augenrules --load >/dev/null 2>&1 && ok "audit rules loaded" || warn "audit rules staged; augenrules --load failed"
    else warn "auditd not installed (apt install auditd) — rules staged only"; fi
    for U in isle-host-agent mesh-mdns polari-isle-push; do
        [ -f "/etc/systemd/system/$U.service" ] || [ -f "/lib/systemd/system/$U.service" ] || continue
        warn_only install -d "/etc/systemd/system/$U.service.d" && run install -m 0644 "$OUT/systemd-hardening.conf" "/etc/systemd/system/$U.service.d/50-os-security.conf" && ok "$U hardened (restart to take effect)"
    done
    $DRY || systemctl daemon-reload
fi
if has dac; then
    echo "== DAC: ownership, docker daemon settings"
    warn_only bash "$OUT/perms.sh"
    if [ -f /etc/docker/daemon.json ]; then
        if python3 - "$OUT/daemon.json" /etc/docker/daemon.json <<'PY'
import json, sys
want, have = json.load(open(sys.argv[1])), json.load(open(sys.argv[2]))
diff = {k: v for k, v in want.items() if not k.startswith('_') and have.get(k) != v}
print('  daemon.json differs on: ' + ', '.join(diff) if diff else '  daemon.json already matches')
sys.exit(1 if diff else 0)
PY
        then :; else warn "merge $OUT/daemon.json into /etc/docker/daemon.json and restart docker in a window (never automatic: userns-remap changes ownership of images/volumes)"; fi
    else warn "no /etc/docker/daemon.json yet — install $OUT/daemon.json and restart docker in a window"; fi
fi
ok "apply ($SC) done — bash $HERE/audit.sh to score it"
