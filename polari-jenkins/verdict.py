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

`partial` is not a hedge, it is the honest state of this pipeline today: the
isle stage body is still the marked ci-3 TODO, so every stage records `skipped`
and `core_ok` stays false. A run whose selftests all pass and whose isle stages
are skipped is therefore `partial`, and `why` says exactly that in words. It is
NOT `passed`, so `promote main` refuses — which is the release rule holding,
not a bug.

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


def isle_summary(run_dir):
    doc = _load(os.path.join(run_dir, 'isle-test', 'results.json'))
    if not doc:
        return {'present': False, 'core_ok': False, 'stages': 0, 'passed': [], 'untested': [],
                'uninstall': {}, 'leak': {}}
    stages = doc.get('stages') or []
    return {'present': True, 'core_ok': bool(doc.get('core_ok')), 'stages': len(stages),
            'passed': list(doc.get('passed') or []), 'untested': list(doc.get('untested') or []),
            'tested_against': doc.get('tested_against', ''),
            'uninstall': (doc.get('leak_summary') or {}).get('uninstall') or {},
            'leak': {'stages_clean': (doc.get('leak_summary') or {}).get('stages_clean', 0),
                     'stages_leaked': (doc.get('leak_summary') or {}).get('stages_leaked', 0)}}


def decide(built, selftests, isle):
    """(verdict, why) — the whole arithmetic, in one function so it is testable."""
    reasons = []
    if not built:
        return 'failed', 'the build stage did not produce the artifacts this run was supposed to test'

    failed_modules = sorted(m for m, s in (selftests.get('modules') or {}).items() if s == 'fail')
    skipped_modules = sorted(m for m, s in (selftests.get('modules') or {}).items() if s == 'skipped')
    if failed_modules:
        return 'failed', ('module selftests failed: %s (%d of %d suites)'
                          % (', '.join(failed_modules), selftests.get('failed', 0),
                             selftests.get('suites', 0)))
    if not selftests.get('ran'):
        reasons.append('the module selftests did not run at all (no backend image on this device)')
    elif not selftests.get('modules'):
        reasons.append('no module was configured for selftests in this run')
    elif skipped_modules:
        reasons.append('no selftest suite exists for: %s (skipped is not a pass)' % ', '.join(skipped_modules))

    if not isle.get('present'):
        reasons.append('the isle stages left no results.json — nothing was tested in a throwaway isle')
    elif not isle.get('core_ok'):
        uninst = isle.get('uninstall') or {}
        if set(uninst.values()) <= {'skipped'} and uninst:
            reasons.append('every isle stage recorded uninstall=skipped: the install + selftest cycle '
                           'INSIDE the guest is still the marked ci-3 TODO, so core_ok cannot become true '
                           'yet and no core has actually been exercised in an isle')
        else:
            return 'failed', ('the isle stages did not record core_ok (uninstall verdicts: %s)'
                              % (', '.join('%s=%s' % kv for kv in sorted(uninst.items())) or 'none'))

    if reasons:
        return 'partial', '; '.join(reasons)
    return 'passed', 'every configured module selftest passed and the isle stages recorded core_ok'


def build(args):
    run_dir = args.run_dir
    selftests = selftest_summary(run_dir)
    scans = scan_summary(run_dir)
    isle = isle_summary(run_dir)
    built = str(args.built).lower() in ('1', 'true', 'yes')
    verdict, why = decide(built, selftests, isle)
    doc = {
        'sha': args.sha, 'branch': args.branch, 'device': args.device, 'run': args.run,
        'built': built,
        'scans': scans, 'selftests': selftests, 'isle': isle,
        'verdict': verdict, 'why': why,
        'decided_by': 'pipeline',
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
