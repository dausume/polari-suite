#!/usr/bin/env python3
"""polari-jenkins/scan/summarize.py — turn the scanners' reports into counts.

    summarize.py counts <tool> <report.json>      → one JSON object on stdout
    summarize.py summary <outdir> [lockfile]      → writes SCAN_SUMMARY.md, prints the totals line

A REAL FILE, taking argv, on purpose: `python3 - <<'PY'` feeds the SCRIPT on
stdin, so a heredoc'd analyser can never also read a piped report. That trap has
bitten this sub-project three times (cicd-sync.sh §70, core-artifacts §72,
guest-uninstall §73) and is not going to bite it a fourth.

ADVISORY, ALWAYS. This file counts; it does not judge. Nothing here returns a
non-zero exit for a finding — the only non-zero is a usage error.
"""
import json
import os
import sys

SEVERITIES = ('critical', 'high', 'medium', 'low', 'info', 'unknown')


def _empty():
    return {s: 0 for s in SEVERITIES}


def _bump(counts, sev):
    s = str(sev or 'unknown').strip().lower()
    # every tool spells its middle severity differently; normalise, never drop
    s = {'moderate': 'medium', 'warning': 'medium', 'note': 'low',
         'error': 'high', 'informational': 'info'}.get(s, s)
    counts[s if s in counts else 'unknown'] += 1


def count_trivy(doc):
    c = _empty()
    for result in (doc.get('Results') or []):
        for key in ('Vulnerabilities', 'Misconfigurations', 'Secrets', 'Licenses'):
            for item in (result.get(key) or []):
                _bump(c, item.get('Severity'))
    return c


def count_gitleaks(doc):
    # gitleaks reports a flat list and carries no severity of its own: a leaked
    # credential has exactly one severity, and it is high. Counted as such
    # rather than invented per rule.
    c = _empty()
    for _ in (doc if isinstance(doc, list) else (doc.get('findings') or [])):
        _bump(c, 'high')
    return c


def count_pip_audit(doc):
    c = _empty()
    deps = doc.get('dependencies') if isinstance(doc, dict) else doc
    for dep in (deps or []):
        for _ in (dep.get('vulns') or []):
            _bump(c, 'unknown')      # pip-audit states no severity; it is a count, honestly unknown
    return c


def count_npm_audit(doc):
    c = _empty()
    vulns = ((doc.get('metadata') or {}).get('vulnerabilities') or {}) if isinstance(doc, dict) else {}
    for sev, n in vulns.items():
        if sev in ('total',):
            continue
        for _ in range(int(n or 0)):
            _bump(c, sev)
    return c


COUNTERS = {'trivy': count_trivy, 'gitleaks': count_gitleaks,
            'pip-audit': count_pip_audit, 'npm-audit': count_npm_audit}


def counts_for(tool, path):
    # report names are `<tool>` or `<tool>-<target>` (trivy-source, trivy-image-prf-backend,
    # trivy-deb-polari-complete…). Match the LONGEST known tool name the name starts with, so
    # a per-target report is counted by its tool rather than silently uncounted.
    base = next((t for t in sorted(COUNTERS, key=len, reverse=True)
                 if tool == t or tool.startswith(t + '-') or tool.startswith(t + ':')), tool)
    fn = COUNTERS.get(base)
    if fn is None:
        return _empty(), 'no counter for %r' % base
    try:
        doc = json.load(open(path))
    except Exception as exc:
        return _empty(), 'unreadable (%s)' % exc
    try:
        return fn(doc), ''
    except Exception as exc:
        return _empty(), 'could not be counted (%s)' % exc


def read_lock(path):
    rows = []
    try:
        for line in open(path):
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            parts = [p.strip() for p in line.split('|')]
            if len(parts) >= 5:
                rows.append(dict(zip(('tool', 'image', 'digest', 'licence', 'what'), parts[:5])))
    except Exception:
        pass
    return rows


def do_summary(outdir, lockfile):
    reports = sorted(f for f in os.listdir(outdir) if f.endswith('.json') and f != 'SUMMARY.json')
    lock = {r['tool']: r for r in read_lock(lockfile)} if lockfile else {}
    totals = _empty()
    lines, rows = [], []
    for f in reports:
        tool = f[:-len('.json')]
        c, note = counts_for(tool, os.path.join(outdir, f))
        for k in totals:
            totals[k] += c[k]
        rows.append((tool, c, note))
    skipped = []
    skip_path = os.path.join(outdir, 'SKIPPED.txt')
    if os.path.exists(skip_path):
        skipped = [l.rstrip('\n') for l in open(skip_path) if l.strip()]

    lines.append('# Scan summary — ADVISORY ONLY')
    lines.append('')
    lines.append('Nothing below gates anything. No finding here can fail a build, change a test')
    lines.append('verdict or stop a release: scans are recorded so a person can read them, and')
    lines.append('that is the whole of their authority (his standing rule).')
    lines.append('')
    lines.append('| tool | critical | high | medium | low | info | unknown | note |')
    lines.append('|---|---|---|---|---|---|---|---|')
    for tool, c, note in rows:
        lines.append('| %s | %d | %d | %d | %d | %d | %d | %s |'
                     % (tool, c['critical'], c['high'], c['medium'], c['low'], c['info'],
                        c['unknown'], note or ''))
    lines.append('| **total** | %d | %d | %d | %d | %d | %d | |'
                 % (totals['critical'], totals['high'], totals['medium'], totals['low'],
                    totals['info'], totals['unknown']))
    lines.append('')
    if skipped:
        lines.append('## Skipped')
        lines.append('')
        for s in skipped:
            lines.append('- %s' % s)
        lines.append('')
    if lock:
        lines.append('## The tools, as pinned (scan-tools.lock)')
        lines.append('')
        lines.append('| tool | image | digest | licence |')
        lines.append('|---|---|---|---|')
        for t, r in sorted(lock.items()):
            lines.append('| %s | %s | %s | %s |' % (t, r['image'], r['digest'], r['licence']))
        lines.append('')
    open(os.path.join(outdir, 'SCAN_SUMMARY.md'), 'w').write('\n'.join(lines) + '\n')
    json.dump({'totals': totals, 'tools': {t: c for t, c, _ in rows}, 'skipped': skipped},
              open(os.path.join(outdir, 'SUMMARY.json'), 'w'), indent=1)
    print('scan summary: %s' % ' '.join('%s=%d' % (k, totals[k]) for k in SEVERITIES if totals[k]) or 'nothing found')
    return 0


def main(argv):
    if len(argv) >= 3 and argv[1] == 'counts':
        c, note = counts_for(argv[2], argv[3])
        print(json.dumps({'tool': argv[2], 'counts': c, 'note': note}))
        return 0
    if len(argv) >= 3 and argv[1] == 'summary':
        return do_summary(argv[2], argv[3] if len(argv) > 3 else '')
    sys.stderr.write('usage: summarize.py counts <tool> <report.json> | summary <outdir> [lockfile]\n')
    return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv))
