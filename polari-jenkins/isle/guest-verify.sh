#!/bin/bash
# polari-jenkins/isle/guest-verify.sh — ci-3, LAYER 2: IS IT AN ISLE?
#
# `throwaway.sh verify` answers "is there a VM and can I ssh to it". That is a
# question about OUR pipeline. This answers a question about THE PRODUCT: after
# `isle core-install`, is what is standing there an isle — from inside the
# guest, on the guest's own DNS and its own loopback, with no help from us.
#
# The checks are the ones the isle route already has (core-install's own step 6
# and isle-polari-deploy.sh's health gate), run again as a reading rather than
# trusted from a log line:
#
#   routes           https://polari.isle/ and /isle answer 200
#   api              https://api.polari.isle/api/health answers 200, and
#                    /api/modules/status says how many modules are online
#   store            `isle store list` answers (the catalogue door)
#   router guest     the libvirt domain openwrt-isle-router is RUNNING — the
#                    nested-KVM half, and the one thing a container-only isle
#                    would quietly skip
#   containers       isle-vlan-agent + prf-isle-backend + prf-isle-frontend
#   CA               /etc/isle-mesh/ca/isle-root.crt exists and has a fingerprint
#
# `--resolve <name>:443:127.0.0.1` on the two curls is deliberate and is how the
# product's own scripts do it: the core cannot reach its own agent's macvlan
# address (kernel macvlan host isolation), so the agent publishes 80/443 on
# loopback and /etc/hosts carries a hairpin block. Resolving to loopback tests
# the SERVICE without also testing three DNS layers; the split-DNS itself is
# checked separately, as its own row, so a DNS failure is named as DNS.
#
# verify: pass only when every row passes. Each row carries its own detail, so
# "verify failed" is never a bare word in the report.

_verify_guest_script() {
cat <<'GUEST'
set -u
echo "###POLARI-VERIFY-BEGIN"

_curl() { curl -sk -o /dev/null -w '%{http_code}' --max-time 10 "$@" 2>/dev/null || echo 000; }

C=$(_curl --resolve polari.isle:443:127.0.0.1 https://polari.isle/)
[ "$C" = 200 ] && echo "###CHECK routes: the isle front page|pass|https://polari.isle/ -> 200" \
               || echo "###CHECK routes: the isle front page|fail|https://polari.isle/ -> $C"
C=$(_curl --resolve polari.isle:443:127.0.0.1 https://polari.isle/isle)
[ "$C" = 200 ] && echo "###CHECK routes: the isle hub|pass|https://polari.isle/isle -> 200" \
               || echo "###CHECK routes: the isle hub|fail|https://polari.isle/isle -> $C"

C=$(_curl --resolve api.polari.isle:443:127.0.0.1 https://api.polari.isle/api/health)
if [ "$C" = 200 ]; then
    S=$(curl -sk --max-time 10 --resolve api.polari.isle:443:127.0.0.1 \
        https://api.polari.isle/api/modules/status 2>/dev/null || echo '')
    N=$(printf '%s' "$S" | python3 -c 'import json,sys
try:
    d=json.load(sys.stdin); print("%s of %s online (%s%%)"%(d.get("onlineCount"),d.get("moduleCount"),d.get("percentOnline")))
except Exception: print("no module status document")' 2>/dev/null || echo 'no module status document')
    echo "###CHECK api: /api/health online|pass|200; modules: $N"
    echo "###FIELD modules=$N"
else
    echo "###CHECK api: /api/health online|fail|https://api.polari.isle/api/health -> $C"
    echo "###FIELD modules="
fi

# the split DNS, as its own row: a name that does not resolve is a DNS finding,
# not an "the isle is down" finding, and the two must never be confused.
if getent hosts polari.isle >/dev/null 2>&1; then
    echo "###CHECK dns: polari.isle resolves in the guest|pass|$(getent hosts polari.isle | head -1)"
else
    echo "###CHECK dns: polari.isle resolves in the guest|fail|polari.isle does not resolve — the hairpin block in /etc/hosts or the split-DNS to the router did not land"
fi

L=$(sudo isle store list 2>&1 | head -3 | tr '\n' ' ')
if sudo isle store list >/dev/null 2>&1; then echo "###CHECK store: the catalogue answers|pass|$L"
else echo "###CHECK store: the catalogue answers|fail|isle store list failed: $L"; fi

R=$(sudo virsh --connect qemu:///system domstate openwrt-isle-router 2>/dev/null | head -1 | tr -d '\n')
[ "$R" = running ] && echo "###CHECK router guest: openwrt-isle-router|pass|libvirt domain state: running (nested KVM)" \
                   || echo "###CHECK router guest: openwrt-isle-router|fail|libvirt domain state: ${R:-not defined} — the isle has no router"

MISSING=""
for c in isle-vlan-agent prf-isle-backend prf-isle-frontend; do
    sudo docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$c" || MISSING="$MISSING $c"
done
[ -z "$MISSING" ] && echo "###CHECK containers: agent + backend + frontend|pass|all three running" \
                  || echo "###CHECK containers: agent + backend + frontend|fail|not running:$MISSING"

F=$(sudo openssl x509 -in /etc/isle-mesh/ca/isle-root.crt -noout -fingerprint -sha256 2>/dev/null | cut -d= -f2)
[ -n "$F" ] && echo "###CHECK CA: the isle root exists|pass|SHA256 ${F}" \
            || echo "###CHECK CA: the isle root exists|fail|/etc/isle-mesh/ca/isle-root.crt is absent or unreadable"

echo "###POLARI-VERIFY-END"
GUEST
}

_parse_verify() {   # _parse_verify <raw log file> <json out|-> <stage> <ok|no>
python3 - "$1" "$2" "$3" "$4" <<'PY'
import json, sys, datetime

raw_path, out_path, stage, reached = sys.argv[1:5]
checks, fields = [], {}
for line in open(raw_path).read().splitlines():
    s = line.strip()
    if s.startswith('###CHECK '):
        parts = (s[len('###CHECK '):].split('|') + ['', '', ''])[:3]
        checks.append({'check': parts[0], 'verdict': parts[1], 'detail': parts[2]})
    elif s.startswith('###FIELD '):
        k, _, v = s[len('###FIELD '):].partition('=')
        fields[k.strip()] = v.strip()

failed = [c for c in checks if c['verdict'] != 'pass']
if reached != 'ok' or not checks:
    ok, why = False, 'the guest could not be reached, or printed no checks — the isle could not be verified at all'
elif failed:
    ok, why = False, '%d of %d checks failed: %s' % (len(failed), len(checks),
                                                     '; '.join('%s (%s)' % (c['check'], c['detail']) for c in failed))
else:
    ok, why = True, 'all %d checks pass — %s' % (len(checks), fields.get('modules') or 'modules not reported')

doc = {'kind': 'isle-verify', 'stage': stage, 'ok': ok, 'why': why, 'checks': checks,
       'modules': fields.get('modules', ''),
       'at': datetime.datetime.now().isoformat(timespec='seconds')}
if out_path and out_path != '-':
    json.dump(doc, open(out_path, 'w'), indent=1)
print('%s|%s' % ('ok' if ok else 'fail', why))
PY
}

verify_isle_do() {   # verify_isle_do [<json out>] [<stage>]
    local out="${1:-}" stage="${2:-1}" raw reached=ok line ok why
    say "the ISLE's own verification, from inside the guest — routes, api, store, router guest"
    if ! exists; then
        raw=""; reached=no
    else
        raw=$(_verify_guest_script | guest_ssh 'bash -s' 2>&1) || true
        case "$raw" in *POLARI-VERIFY-END*) reached=ok ;; *) reached=no ;; esac
    fi
    printf '%s\n' "$raw"
    local tmp; tmp="$(mktemp)"; printf '%s' "$raw" > "$tmp"
    line=$(_parse_verify "$tmp" "$out" "$stage" "$reached"); rm -f "$tmp"
    ok="${line%%|*}"; why="${line#*|}"
    echo
    echo "verify: $ok — $why"
    [ -n "$out" ] && say "recorded: $out" || true
    [ "$ok" = ok ] && return 0 || return 6
}
