#!/bin/bash
# polari-jenkins/isle/guest-uninstall.sh — ci-10, his addendum 2026-09-19:
# *"we should be using the normal isle wiping functionality so that it acts as
# a de jure test of that as well."*
#
# So the teardown is TWO LAYERS, and this is the FIRST one:
#
#   1. IN THE GUEST, before anything is destroyed — the PRODUCT'S OWN uninstall,
#      exactly as a person would run it:
#           sudo ISLE_CONFIRM_DELETE=yes isle uninstall --everything --force
#      which is backup → destroy --purge → network-handback → volumes →
#      apt purge of the whole family → its own zero-footprint verify
#      (Isle-Mesh/isle-cli/scripts/uninstall.sh). Then the HAND-BACK PROOF his
#      rule demands: a default Ubuntu still works — a default route, public DNS,
#      apt, and a network manager that owns the interfaces.
#
#   2. THEN the host layers (throwaway.sh down + wipe + leakcheck).
#
# The two are INDEPENDENT readings and must stay that way:
#   · a DIRTY uninstall is a failure OF THE PRODUCT  — the isle could not hand
#     the machine back. It is a test result, and it blocks the release.
#   · a host LEAK is a failure OF THE PIPELINE       — our own VM/disk/process
#     survived our own teardown. It is a resource guard, not a release gate.
#
# Verdicts:  clean | dirty | failed | skipped
#   skipped  nothing was installed in the guest. Until the ci-3 install cycle
#            lands this is EVERY stage's verdict, and it is the honest one:
#            an uninstall that was never asked to remove anything proves nothing.
#   failed   the uninstall command itself did not run, or the guest was lost
#   dirty    it ran, and the product's own verify (or the hand-back proof) says
#            something was left behind
#   clean    it ran, verified zero footprint, and the box is a default Ubuntu again

# ---------------------------------------------------------------- the guest half
# ONE snippet, run inside the throwaway guest over the per-run key. Every step
# is fenced so the parser below never has to guess where an output began.
_guest_script() {
cat <<'GUEST'
set -u
export DEBIAN_FRONTEND=noninteractive
INSTALLED=0
command -v isle >/dev/null 2>&1 && INSTALLED=1
dpkg-query -W -f='${Status} ${Package}\n' 2>/dev/null \
  | awk '/^install ok installed/{print $4}' \
  | grep -qE '^(isle-mesh-cli|isle-manager-app|isle-app-|polari-shell-core|polari-complete|polari-module-)' && INSTALLED=1
[ -d /etc/isle-mesh ] && INSTALLED=1

echo "###POLARI-UNINSTALL-BEGIN"
echo "###FIELD installed=$INSTALLED"

if [ "$INSTALLED" = 1 ]; then
    echo "###STEP everything"
    sudo ISLE_CONFIRM_DELETE=yes isle uninstall --everything --force 2>&1
    echo "###FIELD rc_everything=$?"
    echo "###STEP verify"
    if command -v isle >/dev/null 2>&1; then
        sudo isle uninstall --verify 2>&1
        echo "###FIELD rc_verify=$?"
    else
        echo "the isle CLI purged itself with the family (expected) — the zero-footprint sweep above, printed by"
        echo "--everything's own last step, IS the product's verify. Nothing here re-implements it."
        echo "###FIELD rc_verify=purged"
    fi
else
    echo "###STEP everything"
    echo "nothing of isle-mesh/polari is installed in this guest — there is nothing for the product's uninstall to remove"
    echo "###FIELD rc_everything=skipped"
    echo "###FIELD rc_verify=skipped"
fi

# ---- the hand-back proof: is this a default Ubuntu again? (his rule)
echo "###STEP handback"
R=$(ip route show default 2>/dev/null | head -1)
[ -n "$R" ] && echo "###PROOF default route|pass|$R" || echo "###PROOF default route|fail|no default route — the box cannot reach anything"
if getent hosts archive.ubuntu.com >/dev/null 2>&1; then echo "###PROOF public DNS|pass|archive.ubuntu.com resolves"
else echo "###PROOF public DNS|fail|archive.ubuntu.com does not resolve — split-DNS or a dead resolver was left behind"; fi
if sudo timeout 120 apt-get update -qq >/dev/null 2>&1; then echo "###PROOF apt|pass|apt-get update succeeds"
else echo "###PROOF apt|fail|apt-get update fails — an apt source or key was left behind, or DNS is gone"; fi
OWNER=""
systemctl is-active --quiet NetworkManager 2>/dev/null && OWNER="NetworkManager"
[ -z "$OWNER" ] && systemctl is-active --quiet systemd-networkd 2>/dev/null && OWNER="systemd-networkd"
if [ -n "$OWNER" ]; then echo "###PROOF network owner|pass|$OWNER is active and owns the interfaces"
else echo "###PROOF network owner|fail|no network manager is active — the uninstall left the box with no owner"; fi
if command -v nmcli >/dev/null 2>&1; then
    N=$(nmcli -t -f NAME connection show --active 2>/dev/null | wc -l)
    [ "${N:-0}" -gt 0 ] && echo "###PROOF desktop connections|pass|$N active NetworkManager connection(s)" \
                        || echo "###PROOF desktop connections|fail|NetworkManager has no active connection"
else
    echo "###PROOF desktop connections|n/a|no NetworkManager in this cloud image — a desktop install is where this row bites"
fi
for d in /etc/isle-mesh /usr/share/isle-mesh /etc/polari; do
    [ -d "$d" ] && echo "###PROOF $d gone|fail|$d is still present" || echo "###PROOF $d gone|pass|absent"
done
echo "###POLARI-UNINSTALL-END"
GUEST
}

# ------------------------------------------------- the reading, in one place
# ⚠ `python3 - <<'PY'` feeds the SCRIPT on stdin, so an analyser written that way
# can NOT also read the log from a pipe (the §70 gotcha, and it bit here first
# time: every verdict came back `skipped` because stdin was the script). The
# guest's output goes through a FILE and an argv path.
#   _parse_uninstall <raw log file> <json out|-> <stage> <ok|no>
_parse_uninstall() {
python3 - "$1" "$2" "$3" "$4" <<'PY'
import json, re, sys, datetime

raw_path, out_path, stage, reached = sys.argv[1:5]
text = open(raw_path).read()
fields, proofs, steps, cur = {}, [], {}, None
for line in text.splitlines():
    s = line.strip()
    if s.startswith('###FIELD '):
        k, _, v = s[len('###FIELD '):].partition('=')
        fields[k.strip()] = v.strip()
    elif s.startswith('###STEP '):
        cur = s[len('###STEP '):].strip(); steps.setdefault(cur, [])
    elif s.startswith('###PROOF '):
        parts = (s[len('###PROOF '):].split('|') + ['', '', ''])[:3]
        proofs.append({'check': parts[0], 'verdict': parts[1], 'detail': parts[2]})
    elif s.startswith('###POLARI-UNINSTALL'):
        continue
    elif cur:
        steps[cur].append(line)

log = '\n'.join(steps.get('everything', []) + steps.get('verify', []))

# the product's own complaints, verbatim — never re-worded, never re-derived
COMPLAINT = re.compile(r'\[✗\]|footprint remains|remaining:|still present|may remain')
findings = [l.strip() for l in log.splitlines() if COMPLAINT.search(l)]
findings += ['hand-back proof: %s — %s' % (p['check'], p['detail'])
             for p in proofs if p['verdict'] == 'fail']

installed = fields.get('installed') == '1'
rc_ev = fields.get('rc_everything', '')
verified = 'VERIFIED: nothing of isle-mesh/polari remains' in log

if reached != 'ok':
    verdict, why = 'failed', 'the guest could not be reached over ssh — the uninstall never ran'
elif not installed:
    verdict, why = 'skipped', ('nothing was installed in this guest, so the product\'s uninstall was not exercised. '
                               'Until the ci-3 install cycle lands this is every stage\'s verdict — an uninstall '
                               'that removed nothing proves nothing.')
elif rc_ev not in ('0', 'skipped'):
    verdict, why = 'failed', 'isle uninstall --everything exited %s' % (rc_ev or '?')
elif findings or not verified:
    verdict, why = 'dirty', ('the uninstall ran but did not hand the machine back cleanly — %d finding(s)'
                             % len(findings) if findings else
                             'the uninstall ran but never printed its own VERIFIED line')
else:
    verdict, why = 'clean', 'zero footprint verified, and the box is a default Ubuntu again'

doc = {'kind': 'isle-uninstall', 'stage': stage, 'verdict': verdict, 'why': why,
       'installed': installed, 'verified_line': verified, 'rc_everything': rc_ev,
       'rc_verify': fields.get('rc_verify', ''), 'findings': findings, 'handback': proofs,
       'at': datetime.datetime.now().isoformat(timespec='seconds'),
       'log_tail': log.splitlines()[-40:]}
if out_path and out_path != '-':
    json.dump(doc, open(out_path, 'w'), indent=1)
print('%s|%s|%d' % (verdict, why, len(findings)))
PY
}

# ----------------------------------------------------------------- the verb
uninstall_do() {   # uninstall_do [<json out path>] [<stage label>]
    local out="${1:-}" stage="${2:-1}" raw reached=ok
    say "the PRODUCT's own uninstall, inside the guest — this is a TEST of isle uninstall --everything, not our cleanup"
    if ! exists; then
        say "no domain '$CI_ISLE_VM_NAME' — nothing to uninstall inside"
        raw=""; reached=no
    else
        raw=$(_guest_script | guest_ssh 'bash -s' 2>&1) || true
        case "$raw" in *POLARI-UNINSTALL-END*) reached=ok ;; *) reached=no ;; esac
    fi
    printf '%s\n' "$raw"
    local line verdict why n tmp
    tmp="$(mktemp)"; printf '%s' "$raw" > "$tmp"
    line=$(_parse_uninstall "$tmp" "$out" "$stage" "$reached"); rm -f "$tmp"
    verdict="${line%%|*}"; why="${line#*|}"; n="${why##*|}"; why="${why%|*}"
    echo
    echo "uninstall verdict: $verdict — $why"
    [ "$n" = 0 ] || echo "  (${n} finding(s) recorded — the product's own words, in ${out:-the log})"
    case "$verdict" in
        clean)   echo "  → this stage's core MAY count as core_ok: an isle that hands the machine back is releasable" ;;
        skipped) echo "  → core_ok stays FALSE: the hand-back was never exercised, so nothing here is releasable" ;;
        *)       echo "  → core_ok is FALSE: an isle that cannot hand the machine back is not releasable (routes/_lib.sh)" ;;
    esac
    [ -n "$out" ] && say "recorded: $out" || true
    case "$verdict" in clean|skipped) return 0 ;; *) return 6 ;; esac
}
