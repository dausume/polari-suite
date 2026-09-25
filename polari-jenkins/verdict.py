#!/usr/bin/env python3
"""polari-jenkins/verdict.py — THE ONE VERDICT OF ONE TEST RUN (ci-12).

    verdict.py build <run-dir> --sha <sha> [--branch test] [--device <name>]
                               [--built true|false] [--run <job#n>]
    verdict.py show  <verdict.json>

His model (2026-09-19): "Based on the outcome on the test stage, we make a
decision to push changes to main." That decision needs ONE answer per sha, and
this file is the only place the answer is computed — the Jenkinsfile collects
readings, this arithmetic turns them into a verdict, and `pol jenkins
test-status` and `pol jenkins promote main` both read the result rather than
re-deriving it.

THE ARITHMETIC, stated once:

    passed   every configured module selftest passed AND the isle stages
             recorded core_ok (which, per ci-10, already requires a CLEAN
             hand-back from the product's own uninstall)
    failed   something that RAN said no
    partial  nothing said no, but something that should have answered did not

`partial` is not a hedge: it is for a run where something that should have
answered did not — no isle results at all, or a stage that could not be run
because an earlier one leaked. It is NOT the resting state any more. Before ci-3
it was: the isle stage body was a marked TODO, so every stage recorded `skipped`
and `core_ok` could never become true. That cycle now exists, so a run that
installs the deb, stands the isle up, runs the suites inside it and hands the
machine back clean reaches `passed` — and one that cannot reaches `failed` with
the first failing part named.

SCANS ARE NEVER IN THE ARITHMETIC. They are carried in the verdict so a person
reading it sees the counts, and they cannot change the verdict by one letter
(his standing rule: security scans are advisory).
"""
import argparse
import json
import os
import sys

VERDICTS = ('passed', 'failed', 'partial')


def _load(path, default=None):
    try:
        return json.load(open(path))
    except Exception:
        return default if default is not None else {}


def selftest_summary(run_dir):
    doc = _load(os.path.join(run_dir, 'selftests', 'results.json'))
    modules = doc.get('modules') or {}
    counts = doc.get('counts') or {}
    return {'ran': bool(doc.get('ran')), 'image': doc.get('image', ''),
            'modules': {str(k): str(v) for k, v in modules.items()},
            'suites': int(counts.get('suites') or 0),
            'passed': int(counts.get('pass') or 0),
            'failed': int(counts.get('fail') or 0)}


def scan_summary(run_dir):
    doc = _load(os.path.join(run_dir, 'scan', 'SUMMARY.json'))
    return {'totals': doc.get('totals') or {}, 'tools': doc.get('tools') or {},
            'skipped': doc.get('skipped') or [],
            'advisory': 'scans never gate — these counts are recorded, not enforced'}


def proofs_summary(run_dir):
    doc = _load(os.path.join(run_dir, 'proofs', 'results.json'))
    return {'ran': bool(doc.get('ran')), 'counts': doc.get('counts') or {}, 'red': [r.get('claim') for r in (doc.get('red') or [])],
            'lean': {'checked': len((doc.get('lean') or {}).get('checked') or []), 'unchanged': len((doc.get('lean') or {}).get('skipped_unchanged') or []),
                     'not_run': (doc.get('lean') or {}).get('not_run')},
            'worst_case_s': (doc.get('aggregate') or {}).get('worst_case_s'), 'elapsed_s': doc.get('elapsed_s'),
            'advisory': 'proofs never gate — a red verdict is recorded, not enforced (plan §I.9)'}


def isle_summary(run_dir):
    doc = _load(os.path.join(run_dir, 'isle-test', 'results.json'))
    if not doc:
        return {'present': False, 'core_ok': False, 'stages': 0, 'passed': [], 'untested': [],
                'uninstall': {}, 'leak': {}, 'why': '', 'stage_rows': [], 'images': {},
                'not_run': []}
    stages = doc.get('stages') or []
    rows, not_run = [], []
    for st in stages:
        row = {'index': st.get('index'), 'apps': st.get('apps') or [],
               'core_ok': bool(st.get('core_ok')), 'why': st.get('why', ''),
               'install_ok': bool((st.get('install') or {}).get('ok')),
               'time_to_online': (st.get('install') or {}).get('time_to_online'),
               'verify_ok': bool((st.get('verify') or {}).get('ok')),
               'selftests': st.get('selftest_counts') or {},
               'uninstall': st.get('uninstall_verdict', 'skipped'),
               # his ruling 2026-09-20: a stage's WARNINGS (the uninstall, by default) ride with it
               'warnings': list(st.get('warnings') or []),
               'results': st.get('results') or {}}
        rows.append(row)
        if st.get('error'):
            not_run.append('stage %s: %s' % (st.get('index'), st.get('error')))
    return {'present': True, 'core_ok': bool(doc.get('core_ok')), 'stages': len(stages),
            'passed': list(doc.get('passed') or []), 'untested': list(doc.get('untested') or []),
            'tested_against': doc.get('tested_against', ''),
            'why': doc.get('why', ''), 'stage_rows': rows, 'not_run': not_run,
            'images': doc.get('images') or {},
            'uninstall': (doc.get('leak_summary') or {}).get('uninstall') or {},
            'leak': {'stages_clean': (doc.get('leak_summary') or {}).get('stages_clean', 0),
                     'stages_leaked': (doc.get('leak_summary') or {}).get('stages_leaked', 0)}}


def decide(built, selftests, isle):
    """(verdict, why) — the whole arithmetic, in one function so it is testable.

    ci-3 (his ask 2026-09-20) closed the last hole in it. Until ci-3 the isle
    stages could not install anything, so `core_ok` could never be true and a
    run whose selftests all passed was `partial` BY CONSTRUCTION — the special
    case that said so in words is gone, because the cycle it apologised for now
    exists. What is left is the plain reading:

        failed   something that RAN said no — a module suite, an install, a
                 verify, a suite inside the isle, or the product's own uninstall.
                 `why` names THE FIRST failing part, not all of them.
        partial  nothing said no, but something that should have answered did
                 not: no isle results at all, or a stage that could not run.
        passed   every configured module selftest passed on the device, every
                 isle stage recorded core_ok, and every app a stage was
                 configured to test passed inside the isle.
    """
    if not built:
        return 'failed', 'the build stage did not produce the artifacts this run was supposed to test'

    # ---- 1. the device selftests (they need no isle, and they run first)
    failed_modules = sorted(m for m, s in (selftests.get('modules') or {}).items() if s == 'fail')
    skipped_modules = sorted(m for m, s in (selftests.get('modules') or {}).items() if s == 'skipped')
    if failed_modules:
        return 'failed', ('module selftests failed on the device: %s (%d of %d suites)'
                          % (', '.join(failed_modules), selftests.get('failed', 0),
                             selftests.get('suites', 0)))

    reasons = []
    if not selftests.get('ran'):
        reasons.append('the module selftests did not run at all (no backend image on this device)')
    elif not selftests.get('modules'):
        reasons.append('no module was configured for selftests in this run')
    elif skipped_modules:
        reasons.append('no selftest suite exists for: %s (skipped is not a pass)' % ', '.join(skipped_modules))

    # ---- 2. the isle stages: install, verify, the suites inside the product,
    #         and the product's own hand-back.
    if not isle.get('present'):
        reasons.append('the isle stages left no results.json — nothing was tested in a throwaway isle')
    else:
        rows = isle.get('stage_rows') or []
        if not rows:
            reasons.append('the isle stages recorded no stage at all')
        for row in rows:
            if row.get('why', '').startswith('not run'):
                reasons.append('isle stage %s could not run: %s' % (row.get('index'), row.get('why')))
                continue
            if not row.get('core_ok'):
                return 'failed', ('isle stage %s did not pass — %s'
                                  % (row.get('index'), row.get('why') or 'no reason recorded'))
            bad = sorted(a for a, v in (row.get('results') or {}).items() if v != 'pass')
            if bad:
                return 'failed', ('isle stage %s: the app(s) it was configured to test did not pass — %s'
                                  % (row.get('index'),
                                     ', '.join('%s=%s' % (a, row['results'][a]) for a in bad)))
        if rows and not isle.get('core_ok'):
            return 'failed', ('the isle stages did not record core_ok — %s'
                              % (isle.get('why') or 'no reason recorded'))

    if reasons:
        return 'partial', '; '.join(reasons)
    warnings = [w for row in (isle.get('stage_rows') or []) for w in (row.get('warnings') or [])]
    if warnings:
        # passed WITH warnings: the product's own uninstall (by his ruling a warning, not a failure) or any
        # other non-gating finding is named here so a reader never mistakes "passed" for "clean".
        return 'passed', ('every configured module selftest passed on the device and every isle stage '
                          'installed, verified and tested — WITH WARNINGS: %s' % '; '.join(warnings))
    return 'passed', ('every configured module selftest passed on the device, every isle stage installed, '
                      'verified, tested and handed the machine back clean')


def build(args):
    run_dir = args.run_dir
    selftests = selftest_summary(run_dir)
    scans = scan_summary(run_dir)
    proofs = proofs_summary(run_dir)
    isle = isle_summary(run_dir)
    built = str(args.built).lower() in ('1', 'true', 'yes')
    verdict, why = decide(built, selftests, isle)
    doc = {
        'sha': args.sha, 'branch': args.branch, 'device': args.device, 'run': args.run,
        'built': built,
        'scans': scans, 'proofs': proofs, 'selftests': selftests, 'isle': isle,
        'verdict': verdict, 'why': why,
        'decided_by': 'pipeline',
        # ci-3: the one page a person reads. report.py renders it beside this file.
        'report_path': os.path.join(run_dir, 'TEST_REPORT.md'),
        'at': args.at or __import__('datetime').datetime.now().isoformat(timespec='seconds'),
        'release_rule': ('only a sha whose verdict is `passed` may be promoted to main; '
                         '`pol jenkins promote main --force-untested` is the only override and it says so '
                         'loudly'),
    }
    out = os.path.join(run_dir, 'verdict.json')
    os.makedirs(run_dir, exist_ok=True)
    json.dump(doc, open(out, 'w'), indent=1)
    show(doc)
    return 0


def show(doc):
    print('')
    print('TEST VERDICT — %s  (%s)' % (doc['verdict'].upper(), doc.get('branch', '?')))
    print('  sha        %s' % doc.get('sha', ''))
    print('  why        %s' % doc.get('why', ''))
    st = doc.get('selftests') or {}
    print('  selftests  %d suite(s): %d pass, %d fail   modules: %s'
          % (st.get('suites', 0), st.get('passed', 0), st.get('failed', 0),
             ', '.join('%s=%s' % kv for kv in sorted((st.get('modules') or {}).items())) or 'none'))
    isle = doc.get('isle') or {}
    print('  isle       %s  core_ok=%s  stages=%d  uninstall: %s'
          % ('results present' if isle.get('present') else 'NO results',
             isle.get('core_ok'), isle.get('stages', 0),
             ', '.join('%s=%s' % kv for kv in sorted((isle.get('uninstall') or {}).items())) or 'none'))
    sc = (doc.get('scans') or {}).get('totals') or {}
    print('  scans      %s   (ADVISORY — no finding changes this verdict)'
          % (' '.join('%s=%s' % (k, v) for k, v in sorted(sc.items()) if v) or 'nothing found'))
    pf = doc.get('proofs') or {}
    print('  proofs     %s   (ADVISORY — a red verdict changes nothing here)'
          % (('%s; red: %s; lean %s' % (' '.join('%s=%s' % kv for kv in sorted((pf.get('counts') or {}).items())) or 'no claims',
                                        ', '.join(pf.get('red') or []) or 'none',
                                        ('checked %d, unchanged %d' % ((pf.get('lean') or {}).get('checked', 0), (pf.get('lean') or {}).get('unchanged', 0))) if not (pf.get('lean') or {}).get('not_run') else 'not run'))
             if pf.get('ran') else 'not run'))
    for row in (isle.get('stage_rows') or []):
        tto = row.get('time_to_online')
        print('    stage %-2s %-18s install=%s (%s)  verify=%s  suites=%s/%s  uninstall=%s'
              % (row.get('index'), (', '.join(row.get('apps') or []) or 'core only')[:18],
                 row.get('install_ok'),
                 ('%ss to online' % tto) if tto is not None else 'never came online',
                 row.get('verify_ok'),
                 (row.get('selftests') or {}).get('pass', 0), (row.get('selftests') or {}).get('suites', 0),
                 row.get('uninstall')))
    if doc.get('report_path'):
        print('  report     %s' % doc['report_path'])
    print('')


def main(argv):
    ap = argparse.ArgumentParser(prog='verdict.py')
    sub = ap.add_subparsers(dest='cmd')
    b = sub.add_parser('build')
    b.add_argument('run_dir')
    b.add_argument('--sha', default='')
    b.add_argument('--branch', default='test')
    b.add_argument('--device', default=os.environ.get('CI_DEVICE_NAME', 'pipeline'))
    b.add_argument('--run', default='')
    b.add_argument('--built', default='true')
    b.add_argument('--at', default='')
    s = sub.add_parser('show')
    s.add_argument('path')
    args = ap.parse_args(argv[1:])
    if args.cmd == 'build':
        return build(args)
    if args.cmd == 'show':
        doc = _load(args.path)
        if not doc:
            print('no verdict at %s — push to test and let polari-test run' % args.path)
            return 1
        show(doc)
        return 0
    ap.print_help()
    return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv))
