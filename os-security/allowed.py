#!/usr/bin/env python3
"""
os-security/allowed.py — what enforcing would break: harvest the kernel's AppArmor audit
lines for the os-security profiles (isle-app-*, docker-default) and reduce them to a list.

  allowed.py [--since 1d] [--profile P] [--json] [--rules] [--from-file log.txt] [--selftest]

In complain mode a profile logs everything outside its allow-list as apparmor="ALLOWED"
(and permits it); in enforce mode the same accesses log as "DENIED". This reads
`journalctl -k --since …` (root or the adm group; falls back to dmesg), keeps type=1400
lines for our profiles, and groups them by profile → operation → object (path, capability,
socket family, signal, peer) with counts and the commands that did it. --rules prints, for
each group, the AppArmor rule that would allow it — a suggestion for the template, never
applied by itself. Exit 0 when the list is empty (enforcing would break nothing seen in
the window), 1 otherwise, so the test loop can gate on it.
"""
import argparse
import collections
import json
import re
import subprocess
import sys

OURS = re.compile(r'profile="(isle-app-[^"]+|docker-default)"')
KV = re.compile(r'(\w+)=("([^"]*)"|(\S+))')
SECCOMP_LOG = re.compile(r'type=1326 .*code=0x7ffc0000')   # SECCOMP_RET_LOG: permitted and logged (our SCMP_ACT_LOG lists)
SECCOMP_ANY = re.compile(r'type=1326 ')
HERE = __import__('os').path.dirname(__import__('os').path.abspath(__file__))
try:
    _T = json.load(open(HERE + '/syscalls_x86_64.json'))
    SYSCALLS = {int(k): v for k, v in _T['names'].items()}; AUDIT_ARCH = _T['audit_arch']
except (OSError, ValueError):
    SYSCALLS, AUDIT_ARCH = {}, 'c000003e'


def parse_seccomp(line):
    """type=1326 (seccomp): with SCMP_ACT_LOG the code is 0x7ffc0000 and the call went through — the syscall
    the allow-list lacks. ERRNO/KILL codes are the enforce-mode denials. No profile name: seccomp is per kind,
    so the comm/exe is the attribution."""
    d = {m.group(1): (m.group(3) if m.group(3) is not None else m.group(4)) for m in KV.finditer(line)}
    if 'syscall' not in d:
        return None
    n = int(d['syscall']); name = SYSCALLS.get(n, str(n)) if d.get('arch', AUDIT_ARCH) == AUDIT_ARCH else f"{n}@arch{d.get('arch')}"
    verdict = 'ALLOWED' if d.get('code') == '0x7ffc0000' else 'DENIED'
    return {'verdict': verdict, 'profile': 'seccomp', 'op': 'syscall', 'class': 'seccomp', 'object': f"syscall {name}", 'mask': '', 'comm': d.get('comm', '?')}
SELFTEST_LINES = """\
kernel: audit: type=1400 audit(1.1:1): apparmor="ALLOWED" operation="open" class="file" profile="isle-app-prf-backend" name="/etc/hosts" pid=5 comm="python3" requested_mask="w" denied_mask="w" fsuid=0 ouid=0
kernel: audit: type=1400 audit(1.1:2): apparmor="ALLOWED" operation="open" class="file" profile="isle-app-prf-backend" name="/etc/hosts" pid=6 comm="python3" requested_mask="w" denied_mask="w" fsuid=0 ouid=0
kernel: audit: type=1400 audit(1.1:3): apparmor="ALLOWED" operation="capable" class="cap" profile="isle-app-prf-backend" pid=5 comm="python3" capability=21 capname="sys_admin"
kernel: audit: type=1400 audit(1.1:4): apparmor="ALLOWED" operation="create" class="net" profile="docker-default" pid=7 comm="nginx" family="inet" sock_type="raw" protocol=1 requested_mask="create" denied_mask="create"
kernel: audit: type=1400 audit(1.1:5): apparmor="ALLOWED" operation="signal" class="signal" profile="docker-default" pid=8 comm="runc" requested_mask="receive" denied_mask="receive" signal=term peer="unconfined"
kernel: audit: type=1400 audit(1.1:6): apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="isle-app-prf-backend" name="/mnt/" pid=9 comm="mount" fstype="tmpfs" srcname="none"
kernel: audit: type=1400 audit(1.1:7): apparmor="DENIED" operation="open" class="file" profile="snap.gh.gh" name="/etc/gitconfig" pid=10 comm="git" requested_mask="r" denied_mask="r" fsuid=1000 ouid=0
kernel: audit: type=1400 audit(1.1:8): apparmor="STATUS" operation="profile_load" profile="unconfined" name="isle-app-prf-backend" pid=11 comm="apparmor_parser"
kernel: audit: type=1326 audit(1.1:9): auid=4294967295 uid=0 gid=0 ses=4294967295 subj=docker-default pid=12 comm="python3" exe="/usr/local/bin/python3" sig=0 arch=c000003e syscall=334 compat=0 ip=0x7f1 code=0x7ffc0000
kernel: audit: type=1326 audit(1.1:10): auid=4294967295 uid=0 gid=0 ses=4294967295 subj=docker-default pid=12 comm="python3" exe="/usr/local/bin/python3" sig=0 arch=c000003e syscall=334 compat=0 ip=0x7f1 code=0x7ffc0000
kernel: audit: type=1326 audit(1.1:11): auid=4294967295 uid=0 gid=0 ses=4294967295 subj=docker-default pid=13 comm="nginx" exe="/usr/sbin/nginx" sig=0 arch=c000003e syscall=302 compat=0 ip=0x7f1 code=0x50001
"""


def parse(line):
    if SECCOMP_ANY.search(line):
        return parse_seccomp(line)
    if 'apparmor="' not in line or not OURS.search(line):
        return None
    d = {m.group(1): (m.group(3) if m.group(3) is not None else m.group(4)) for m in KV.finditer(line)}
    if d.get('apparmor') not in ('ALLOWED', 'DENIED', 'AUDIT'):
        return None
    op, cls = d.get('operation', '?'), d.get('class', '')
    if cls == 'file' or 'name' in d and cls in ('', 'file'):
        obj = d.get('name', '?'); mask = d.get('denied_mask') or d.get('requested_mask', '')
    elif cls == 'cap' or 'capname' in d:
        obj = 'capability ' + d.get('capname', '?'); mask = ''
    elif cls == 'net' or 'family' in d:
        obj = f"network {d.get('family', '?')} {d.get('sock_type', '?')}"; mask = d.get('denied_mask') or d.get('requested_mask', '')
    elif cls == 'signal' or 'signal' in d:
        obj = f"signal {d.get('signal', '?')} peer={d.get('peer', '?')}"; mask = d.get('denied_mask') or d.get('requested_mask', '')
    elif cls == 'ptrace' or op == 'ptrace':
        obj = f"ptrace peer={d.get('peer', '?')}"; mask = d.get('denied_mask') or d.get('requested_mask', '')
    elif cls == 'mount' or op in ('mount', 'umount', 'pivotroot'):
        obj = f"{op} {d.get('name', '')} {d.get('fstype', '')}".strip(); mask = ''
    else:
        obj = d.get('name', d.get('info', '?')); mask = d.get('denied_mask') or d.get('requested_mask', '')
    return {'verdict': d['apparmor'], 'profile': d['profile'], 'op': op, 'class': cls or op, 'object': obj, 'mask': mask, 'comm': d.get('comm', '?')}


def rule_for(g):
    c, obj, mask = g['class'], g['object'], g['mask']
    if c == 'seccomp':
        return f'"{obj.split()[-1]}",   # add to the kind\'s list in templates/seccomp/kind.json.j2'
    if c == 'file':
        return f"{obj} {mask or 'r'},"
    if obj.startswith('capability '):
        return obj + ','
    if obj.startswith('network '):
        return obj + ','
    if obj.startswith('signal '):
        return f"signal ({mask or 'receive'}) peer={obj.split('peer=')[-1]},"
    if obj.startswith('ptrace '):
        return f"ptrace ({mask or 'read'}) peer={obj.split('peer=')[-1]},"
    if c == 'mount' or obj.startswith(('mount', 'umount', 'pivotroot')):
        return '# ' + obj + ' — mounting is never allowed to an app; if this is the runtime, it belongs outside the profile'
    return '# ' + obj


def read_log(since):
    for cmd in (['journalctl', '-k', '--no-pager', '-o', 'short-iso', '--since', since], ['dmesg', '-T']):
        try:
            p = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        except (OSError, subprocess.TimeoutExpired):
            continue
        if p.returncode == 0 and p.stdout:
            return p.stdout.splitlines(), cmd[0]
    return None, None


def reduce(lines, only_profile=None):
    groups = collections.OrderedDict()
    for ln in lines:
        e = parse(ln)
        if not e or (only_profile and e['profile'] != only_profile):
            continue
        key = (e['profile'], e['verdict'], e['class'], e['op'], e['object'], e['mask'])
        g = groups.setdefault(key, {**e, 'count': 0, 'comms': []})
        g['count'] += 1
        if e['comm'] not in g['comms']:
            g['comms'].append(e['comm'])
    return list(groups.values())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--since', default='1d', help='journalctl --since (default 1d; e.g. "2 hours ago", 2026-09-12)')
    ap.add_argument('--profile')
    ap.add_argument('--json', action='store_true')
    ap.add_argument('--rules', action='store_true', help='print the AppArmor rule that would allow each group')
    ap.add_argument('--from-file', help='parse this file instead of the kernel log')
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest:
        gs = reduce(SELFTEST_LINES.splitlines())
        want = [('isle-app-prf-backend', 'ALLOWED', '/etc/hosts', 2), ('isle-app-prf-backend', 'ALLOWED', 'capability sys_admin', 1),
                ('docker-default', 'ALLOWED', 'network inet raw', 1), ('docker-default', 'ALLOWED', 'signal term peer=unconfined', 1),
                ('isle-app-prf-backend', 'DENIED', 'mount /mnt/ tmpfs', 1),
                ('seccomp', 'ALLOWED', 'syscall rseq', 2), ('seccomp', 'DENIED', 'syscall prlimit64', 1)]
        got = [(g['profile'], g['verdict'], g['object'], g['count']) for g in gs]
        rules = [rule_for(g) for g in gs]
        ok = got == want and rules[0] == '/etc/hosts w,' and rules[1] == 'capability sys_admin,' and rules[2] == 'network inet raw,' \
            and rules[3] == 'signal (receive) peer=unconfined,' and rules[4].startswith('# mount') and rules[5].startswith('"rseq",')
        print(f"selftest {'PASS' if ok else 'FAIL'}: {len(gs)} groups (foreign snap profile and STATUS lines ignored; seccomp lines by syscall name)")
        if not ok:
            print(got, rules)
        sys.exit(0 if ok else 1)
    if a.from_file:
        lines, src = open(a.from_file, encoding='utf-8', errors='replace').read().splitlines(), a.from_file
    else:
        since = a.since if ' ' in a.since or '-' in a.since else {'d': ' days ago', 'h': ' hours ago', 'm': ' minutes ago'}.get(a.since[-1], '') and a.since[:-1] + {'d': ' days ago', 'h': ' hours ago', 'm': ' minutes ago'}[a.since[-1]] or a.since
        lines, src = read_log(since)
        if lines is None:
            sys.exit('cannot read the kernel log: run as root or a member of adm (journalctl -k), or pass --from-file')
    groups = reduce(lines, a.profile)
    if a.json:
        print(json.dumps({'source': src, 'since': None if a.from_file else a.since, 'groups': groups}, indent=2))
    else:
        if not groups:
            print(f"no ALLOWED/DENIED lines for os-security profiles ({src}, since {a.since}) — enforcing would break nothing seen in this window")
        by_prof = collections.OrderedDict()
        for g in groups:
            by_prof.setdefault(g['profile'], []).append(g)
        for prof, gs in by_prof.items():
            allowed = sum(g['count'] for g in gs if g['verdict'] == 'ALLOWED'); denied = sum(g['count'] for g in gs if g['verdict'] == 'DENIED')
            print(f"{prof}: {len(gs)} distinct access(es) — {allowed} would be denied under enforce (ALLOWED now), {denied} denied")
            for g in sorted(gs, key=lambda g: -g['count']):
                print(f"  {g['verdict']:7} ×{g['count']:<5} {g['op']:<12} {g['object']} {('[' + g['mask'] + ']') if g['mask'] else ''}  by {','.join(g['comms'][:4])}")
                if a.rules:
                    print(f"          → {rule_for(g)}")
    sys.exit(1 if groups else 0)


if __name__ == '__main__':
    main()
