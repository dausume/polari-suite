#!/usr/bin/env python3
"""polari-jenkins/report.py — ci-3: ONE PAGE PER COMMIT, and the release carries it.

    report.py build <run-dir>          render <run-dir>/TEST_REPORT.md
    report.py show  <run-dir>          print it (rendering it first if absent)

His ask, 2026-09-20: *"make sure the overall functionality including getting the
actual tests to run and the reports built … so we can be confident when doing a
deployment from test to main and in the end-result artifacts from that."*

The verdict answers ONE question in one word, which is what `promote main` and
`routes/_lib.sh` need. A person deciding to promote needs the other thing: what
was built, what was scanned, what ran, where, for how long, and what the product
said when it was asked to remove itself. That is this file, and it is deliberately
ONE PAGE — not an index of logs. Everything in it is read out of readings the
pipeline already wrote; nothing here re-derives a verdict, which is why the
verdict line at the top is quoted from verdict.json rather than recomputed.

It is rendered by `polari-test` after the verdict and published as a RELEASE
ASSET beside SCAN_SUMMARY.md and verdict.json, so the question "what was this
release tested with?" is answerable from the release page alone, by somebody who
has never seen this device.

SCANS APPEAR AND DO NOT GATE. The counts are here, and the top findings by
package, because a person promoting should see them. No number in this file can
change a verdict by one letter (his standing rule).
"""
import argparse
import json
import os
import sys

BAR = '-' * 78


def _load(path, default=None):
    try:
        return json.load(open(path))
    except Exception:
        return {} if default is None else default


def _sha256s(debs_dir):
    out = {}
    try:
        import hashlib
        for name in sorted(os.listdir(debs_dir)):
            if not name.endswith('.deb'):
                continue
            h = hashlib.sha256()
            with open(os.path.join(debs_dir, name), 'rb') as fh:
                for chunk in iter(lambda: fh.read(1 << 20), b''):
                    h.update(chunk)
            out[name] = h.hexdigest()
    except Exception:
        pass
    return out


def _scan_top(run_dir, limit=10):
    """The top findings by package. scan.sh's SUMMARY.json is the only source."""
    doc = _load(os.path.join(run_dir, 'scan', 'SUMMARY.json'))
    rows = doc.get('top') or doc.get('findings') or []
    out = []
    for r in rows[:limit]:
        if isinstance(r, dict):
            out.append('%-12s %-28s %-22s %s'
                       % (str(r.get('severity', '?'))[:12], str(r.get('package', r.get('pkg', '?')))[:28],
                          str(r.get('id', r.get('advisory', '')))[:22], str(r.get('tool', ''))[:12]))
        else:
            out.append(str(r))
    return out, doc


def render(run_dir):
    v = _load(os.path.join(run_dir, 'verdict.json'))
    isle = v.get('isle') or {}
    st = v.get('selftests') or {}
    res = _load(os.path.join(run_dir, 'isle-test', 'results.json'))
    scans_top, scan_doc = _scan_top(run_dir)
    debs = _sha256s(os.path.join(run_dir, 'debs'))

    L = []
    a = L.append
    a('# Polari test report — %s' % (str(v.get('sha', '')) or 'no sha recorded'))
    a('')
    a('    verdict   %s' % str(v.get('verdict', 'not reached')).upper())
    a('    why       %s' % (v.get('why') or ''))
    a('    branch    %s        device  %s' % (v.get('branch', '?'), v.get('device', '?')))
    a('    run       %s        at      %s' % (v.get('run', '?'), v.get('at', '?')))
    a('')
    a('THE RELEASE RULE. Only a sha whose verdict is `passed` may be promoted to main and')
    a('published. Every route re-reads this verdict independently (polari-jenkins/routes/_lib.sh),')
    a('so triggering a publish by hand on an untested build renders and publishes nothing.')
    a('`pol jenkins promote main --force-untested` is the one override and it names what it')
    a('is overriding, in the log and in this report\'s absence.')
    a('')

    # ------------------------------------------------------------- what was built
    a(BAR)
    a('## What was built')
    a('')
    if debs:
        for name, sha in debs.items():
            a('    %-44s %s' % (name, sha))
    else:
        a('    (no debs recorded in %s/debs)' % run_dir)
    a('')
    images = (res.get('images') or {}) or (isle.get('images') or {})
    if images:
        a('    images installed in the isle — the IDs, which is what "tested == released" is asserted on:')
        for name, iid in sorted(images.items()):
            a('    %-32s %s' % (name, iid))
    else:
        a('    (no image ids recorded — no isle stage installed anything)')
    a('')

    # ------------------------------------------------------------------- scans
    a(BAR)
    a('## Scans (ADVISORY — no finding changed the verdict)')
    a('')
    totals = (v.get('scans') or {}).get('totals') or {}
    tools = (v.get('scans') or {}).get('tools') or {}
    a('    totals    %s' % (' '.join('%s=%s' % kv for kv in sorted(totals.items())) or 'nothing found'))
    for tool, counts in sorted(tools.items()):
        if isinstance(counts, dict):
            a('    %-12s %s' % (tool, ' '.join('%s=%s' % kv for kv in sorted(counts.items()))))
    skipped = (v.get('scans') or {}).get('skipped') or []
    if skipped:
        a('    not run   %s' % ', '.join(str(x) for x in skipped))
    if scans_top:
        a('')
        a('    top findings by package:')
        for row in scans_top:
            a('      %s' % row)
    elif totals:
        a('')
        a('    (SUMMARY.json carries counts but no per-finding rows — see scan/SCAN_SUMMARY.md)')
    a('')

    # ------------------------------------------------- the device selftests
    a(BAR)
    a('## Module selftests on the device (no isle needed)')
    a('')
    a('    %d suite(s): %d pass, %d fail   image %s'
      % (st.get('suites', 0), st.get('passed', 0), st.get('failed', 0), st.get('image', '?')))
    mods = st.get('modules') or {}
    bad = sorted(m for m, s in mods.items() if s != 'pass')
    a('    modules   %s' % (', '.join('%s=%s' % kv for kv in sorted(mods.items())) or 'none'))
    if bad:
        a('    NOT PASSING: %s' % ', '.join('%s=%s' % (m, mods[m]) for m in bad))
    a('')

    # --------------------------------------------------------- the isle stages
    a(BAR)
    a('## The throwaway isle stages — the product, installed and tested')
    a('')
    a('    tested against  %s' % (isle.get('tested_against') or res.get('tested_against') or '?'))
    a('    core debs       %s' % (res.get('core_debs') or '?'))
    a('')
    stages = res.get('stages') or []
    if not stages:
        a('    NO STAGE RAN. Nothing was installed in a throwaway isle, so nothing here is releasable.')
    for s in stages:
        idx = s.get('index')
        a('### stage %s — %s' % (idx, ', '.join(s.get('apps') or []) or 'core only'))
        a('')
        a('    core_ok   %s' % s.get('core_ok'))
        a('    why       %s' % s.get('why', ''))
        inst = s.get('install') or {}
        tto = inst.get('time_to_online')
        a('    install   ok=%s  %s' % (inst.get('ok'), inst.get('why', '')))
        a('              deb %s (%s)' % (inst.get('deb', '?'), inst.get('deb_version', '?')))
        a('              sha256 %s' % (inst.get('deb_sha256', '') or '?'))
        a('              time to online: %s s   (by step: %s)'
          % (tto if tto is not None else 'never came online',
             ' '.join('%s=%ss' % kv for kv in sorted((inst.get('seconds_by_step') or {}).items()))))
        if inst.get('containers'):
            a('              containers: %s' % ', '.join(inst['containers']))
        ver = s.get('verify') or {}
        a('    verify    %s — %s' % ('pass' if ver.get('ok') else 'FAIL', ver.get('why', '')))
        for d in (ver.get('details') or []):
            a('              %s' % d)
        counts = s.get('selftest_counts') or {}
        a('    selftests inside the isle: %d suite(s), %d pass, %d fail   (%s)'
          % (counts.get('suites', 0), counts.get('pass', 0), counts.get('fail', 0),
             s.get('selftests_why', '')))
        failing = sorted(k for k, st2 in (s.get('selftests') or {}).items() if st2 != 'pass')
        for k in failing:
            a('              FAIL %s' % k)
        if s.get('results'):
            a('    apps      %s' % ', '.join('%s=%s' % kv for kv in sorted(s['results'].items())))
        a('    uninstall %s' % s.get('uninstall_verdict'))
        for f in (s.get('uninstall_findings') or []):
            a('              - %s' % f)
        a('    leaks     %s (%s)   RAM %+d MB, disk %+d MB'
          % (s.get('leak_verdict'), '; '.join(s.get('leaks') or []) or 'none',
             s.get('ram_delta_mb', 0), s.get('disk_delta_mb', 0)))
        if s.get('error'):
            a('    error     %s' % s['error'])
        a('')

    leak = (res.get('leak_summary') or {})
    if leak:
        a('    leak summary: %s stage(s) clean, %s leaked; policy %s%s'
          % (leak.get('stages_clean', 0), leak.get('stages_leaked', 0), leak.get('policy', '?'),
             ('; STOPPED: %s' % leak['stopped']) if leak.get('stopped') else ''))
        a('')
    a(BAR)
    a('Rendered by polari-jenkins/report.py from the run\'s own readings. It re-derives nothing:')
    a('the verdict above is quoted from verdict.json, which is computed once, in verdict.py.')
    return '\n'.join(L) + '\n'


def main(argv):
    ap = argparse.ArgumentParser(prog='report.py')
    sub = ap.add_subparsers(dest='cmd')
    b = sub.add_parser('build')
    b.add_argument('run_dir')
    sh = sub.add_parser('show')
    sh.add_argument('run_dir')
    args = ap.parse_args(argv[1:])
    if args.cmd not in ('build', 'show'):
        ap.print_help()
        return 2
    out = os.path.join(args.run_dir, 'TEST_REPORT.md')
    if args.cmd == 'build' or not os.path.exists(out):
        text = render(args.run_dir)
        os.makedirs(args.run_dir, exist_ok=True)
        open(out, 'w').write(text)
        if args.cmd == 'build':
            print(out)
            return 0
    sys.stdout.write(open(out).read())
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
