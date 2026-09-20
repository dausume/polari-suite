#!/usr/bin/env python3
"""polari-jenkins/isle/results.py — ci-3: the isle stages' readings, assembled.

    results.py stage    <run-dir> --index N [--apps "a b"] [--started T] [--error E]
    results.py assemble <run-dir> --version V [--mode M] [--tested-against T]
                                  [--core-debs D] [--leak-policy P] [--stopped WHY]

WHY THIS FILE EXISTS AND THE JENKINSFILE DOES NOT DO IT.

Until ci-3 the stage loop built `results.json` in Groovy, field by field, out of
a dozen `jsonget.py` calls. That was tolerable while a stage recorded three
scalars. It is not tolerable now that a stage records an install, a verify, a
suite-by-suite selftest run, an image map, an uninstall verdict and a leak diff
— and it was never testable: the ONE piece of arithmetic that decides whether a
core may be released (`core_ok`) lived inside a Jenkinsfile that no selftest can
execute. So the Jenkinsfile now only orchestrates and writes each reading to its
own file; this assembles them, and `polari-jenkins/selftest.sh` runs it against
fixtures.

THE ARITHMETIC, stated once and implemented once:

    stage.core_ok = install.ok
                  AND verify.ok
                  AND the uninstall verdict is `clean`
                  AND, for a stage that ran the CORE selftests, every core suite
                      passed.

    results.core_ok = stage 1's core_ok.

Stage 1 is always the core-only stage (`CI_ISLE_STAGES` starts with `core`), so
the second reading of the first is the four-term formula in full. A later stage
that names apps runs THOSE apps' suites rather than the core's — its core_ok is
the three-term form, and `apps_ok` carries the apps. Nothing is silently
weakened: a stage that ran no core suites says so in `core_selftests`.

A MISSING READING IS A FAILURE, NOT A ZERO. If install-N.json is absent the
stage did not install, `ok` is false and `why` says the file never appeared.
That is the opposite of the pre-ci-3 default, where an absent reading left
`skipped` and looked survivable.
"""
import argparse
import datetime
import glob
import json
import os
import sys


def _load(path, default=None):
    try:
        return json.load(open(path))
    except Exception:
        return {} if default is None else default


def _now():
    return datetime.datetime.now().isoformat(timespec='seconds')


# --------------------------------------------------------------- one stage
def build_stage(run_dir, index, apps, started='', finished='', error='',
                version='', tested_against='', leak_verdict=''):
    p = lambda n: os.path.join(run_dir, '%s-%s.json' % (n, index))          # noqa: E731

    inst = _load(p('install'))
    ver = _load(p('verify'))
    st = _load(p('selftests'))
    appi = _load(p('apps'))
    unin = _load(p('uninstall'))
    leak = _load(p('leak-check'))

    install = {
        'ok': bool(inst.get('ok')),
        'why': inst.get('why') or 'no install reading came back from the guest',
        'seconds': int(inst.get('seconds') or 0),
        'seconds_by_step': inst.get('seconds_by_step') or {},
        'time_to_online': inst.get('time_to_online'),
        'deb': inst.get('deb', ''), 'deb_sha256': inst.get('deb_sha256', ''),
        'deb_version': inst.get('deb_version', ''),
        'containers': inst.get('containers') or [],
        'log': (inst.get('log_tail') or [])[-25:],
    }
    verify = {
        'ok': bool(ver.get('ok')),
        'why': ver.get('why') or 'no verify reading came back from the guest',
        'modules': ver.get('modules', ''),
        'details': ['%s: %s — %s' % (c.get('verdict', '?'), c.get('check', '?'), c.get('detail', ''))
                    for c in (ver.get('checks') or [])],
    }
    # `selftests` is SUITE -> pass|fail, which is what a person wants to read;
    # `selftest_modules` is the module roll-up the app results are taken from.
    selftests = {k: (v or {}).get('state', '?') for k, v in (st.get('suites') or {}).items()}
    selftest_modules = dict(st.get('modules') or {})
    counts = st.get('counts') or {}
    images = dict(inst.get('images') or {})

    uninstall = {'verdict': unin.get('verdict') or 'failed',
                 'findings': list(unin.get('findings') or [])}
    if not unin:
        uninstall['findings'] = ['no uninstall reading came back from the guest']

    leaks = ['%s: %s (%s -> %s)' % (i.get('kind', '?'), i.get('item', '?'),
                                    i.get('baseline', '?'), i.get('now', '?'))
             if isinstance(i, dict) else str(i)
             for i in (leak.get('leaks') or [])]

    ran_core = 'core' in selftest_modules
    core_selftests = selftest_modules.get('core', 'not run in this stage')
    core_ok = (install['ok'] and verify['ok'] and uninstall['verdict'] == 'clean'
               and (not ran_core or core_selftests == 'pass'))

    results = {}
    for a in apps:
        results[a] = selftest_modules.get(a, 'skipped')
    apps_ok = bool(apps) and all(v == 'pass' for v in results.values())

    return {
        'index': index, 'apps': list(apps),
        # `version` and `tested` are the names cicd-sync.sh's isle-test door reads;
        # `apps` is this file's own name for the same list. One document, both keys,
        # rather than a second shape for the mirror to parse.
        'version': version, 'tested': list(apps), 'tested_against': tested_against,
        'started': started or _now(), 'finished': finished or _now(),
        'error': error,
        'install': install, 'verify': verify,
        'selftests': selftests, 'selftest_modules': selftest_modules,
        'selftest_counts': {'suites': int(counts.get('suites') or 0),
                            'pass': int(counts.get('pass') or 0),
                            'fail': int(counts.get('fail') or 0)},
        'selftests_why': st.get('why', ''),
        # the first lines of each failing suite's own output, so the report can
        # name the failing CHECKS and not merely the failing suite
        'selftest_logs': {k: [str(x) for x in v[:8]] for k, v in (st.get('failing_logs') or {}).items()},
        'selftest_backend_image': st.get('image', ''),
        'core_selftests': core_selftests,
        'app_install': {'ok': bool(appi.get('ok')), 'why': appi.get('why', '')} if apps else {},
        'images': images,
        'uninstall_verdict': uninstall['verdict'], 'uninstall_findings': uninstall['findings'],
        'uninstall': uninstall,
        'handback': unin.get('handback') or [],
        # the file's own verdict, unless the caller saw a SECOND failing check
        # after a re-wipe — only the Jenkinsfile knows that, because only it
        # re-wipes, so it may say so and nothing else may.
        'leaks': leaks,
        'leak_verdict': leak_verdict or leak.get('verdict') or ('clean' if leak else 'leak-check-unreadable'),
        'ram_delta_mb': int(leak.get('ram_delta_mb') or 0),
        'disk_delta_mb': int(leak.get('disk_delta_mb') or 0),
        'results': results, 'apps_ok': apps_ok,
        'core_ok': core_ok,
        'why': _stage_why(install, verify, uninstall, ran_core, core_selftests, results),
    }


def _stage_why(install, verify, uninstall, ran_core, core_selftests, results):
    """The FIRST failing part, named. Order matters: it is the order they run."""
    if not install['ok']:
        return 'install: %s' % install['why']
    if not verify['ok']:
        return 'verify: %s' % verify['why']
    if ran_core and core_selftests != 'pass':
        return 'the core selftests inside the isle are %s' % core_selftests
    bad = sorted(a for a, v in results.items() if v != 'pass')
    if bad:
        return 'app selftests inside the isle did not pass: %s' % ', '.join(
            '%s=%s' % (a, results[a]) for a in bad)
    if uninstall['verdict'] != 'clean':
        return ("the product's own uninstall came back %s — %s"
                % (uninstall['verdict'], '; '.join(uninstall['findings']) or 'no findings recorded'))
    return 'installed, verified, tested and handed the machine back clean'


# ------------------------------------------------------------- the whole run
def assemble(run_dir, version, mode, tested_against, core_debs, leak_policy, stopped):
    stages = []
    for f in sorted(glob.glob(os.path.join(run_dir, 'stage-*.json')),
                    key=lambda p: int(os.path.basename(p)[len('stage-'):-len('.json')] or 0)):
        doc = _load(f)
        if doc:
            stages.append(doc)

    tested, passed = [], []
    for s in stages:
        for a, v in (s.get('results') or {}).items():
            if a not in tested:
                tested.append(a)
            if v == 'pass' and a not in passed:
                passed.append(a)

    images = {}
    for s in stages:
        images.update(s.get('images') or {})

    core_ok = bool(stages and stages[0].get('core_ok'))
    doc = {
        'version': version or 'none', 'mode': mode or 'suite',
        'tested_against': tested_against, 'core_debs': core_debs,
        'stages': stages,
        'tested': tested, 'passed': passed, 'untested': [a for a in tested if a not in passed],
        'core_ok': core_ok,
        'images': images,
        'why': (stages[0].get('why') if stages else 'no isle stage ran at all'),
        'leak_summary': {
            'policy': leak_policy, 'stopped': stopped or '',
            'stages_clean': sum(1 for s in stages if s.get('leak_verdict') == 'clean'),
            'stages_leaked': sum(1 for s in stages if s.get('leak_verdict') != 'clean'),
            'leaks': [x for s in stages for x in (s.get('leaks') or [])],
            'ram_delta_mb': sum(int(s.get('ram_delta_mb') or 0) for s in stages),
            'disk_delta_mb': sum(int(s.get('disk_delta_mb') or 0) for s in stages),
            'uninstall': {'stage%s' % s.get('index'): s.get('uninstall_verdict') for s in stages},
        },
        'at': _now(),
    }
    return doc


def main(argv):
    ap = argparse.ArgumentParser(prog='results.py')
    sub = ap.add_subparsers(dest='cmd')

    s = sub.add_parser('stage')
    s.add_argument('run_dir')
    s.add_argument('--index', type=int, required=True)
    s.add_argument('--apps', default='')
    s.add_argument('--started', default='')
    s.add_argument('--finished', default='')
    s.add_argument('--error', default='')
    s.add_argument('--version', default='')
    s.add_argument('--tested-against', default='')
    s.add_argument('--leak-verdict', default='')

    a = sub.add_parser('assemble')
    a.add_argument('run_dir')
    a.add_argument('--version', default='')
    a.add_argument('--mode', default='suite')
    a.add_argument('--tested-against', default='')
    a.add_argument('--core-debs', default='')
    a.add_argument('--leak-policy', default='stop')
    a.add_argument('--stopped', default='')

    args = ap.parse_args(argv[1:])
    if args.cmd == 'stage':
        apps = [x for x in args.apps.split() if x]
        doc = build_stage(args.run_dir, args.index, apps, args.started, args.finished, args.error,
                          args.version, args.tested_against, args.leak_verdict)
        out = os.path.join(args.run_dir, 'stage-%d.json' % args.index)
        json.dump(doc, open(out, 'w'), indent=1)
        print('stage %d: core_ok=%s — %s' % (args.index, doc['core_ok'], doc['why']))
        return 0
    if args.cmd == 'assemble':
        doc = assemble(args.run_dir, args.version, args.mode, args.tested_against,
                       args.core_debs, args.leak_policy, args.stopped)
        out = os.path.join(args.run_dir, 'results.json')
        json.dump(doc, open(out, 'w'), indent=1)
        print('isle results: %d stage(s), core_ok=%s — %s'
              % (len(doc['stages']), doc['core_ok'], doc['why']))
        return 0
    ap.print_help()
    return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv))
