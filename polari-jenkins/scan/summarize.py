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


# ci-3 — THE FINDINGS THEMSELVES, not just the counts (his ask 2026-09-20: the
# report carries "the top 10 critical findings by package, advisory"). A table of
# totals tells a person there is something to look at; it does not tell them
# WHAT, and a person deciding to promote should not have to open four JSON files
# to find out. Still advisory: these rows can no more gate a release than the
# counts they come from.
#
# Only the tools that name a package name one. pip-audit states no severity at
# all (it is counted `unknown`, honestly), and gitleaks names a rule rather than
# a package — both are represented rather than dropped, so "nothing listed" never
# silently means "that tool has no rows to give".
RANK = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3, 'info': 4, 'unknown': 5}


def findings_trivy(doc, tool):
    out = []
    for result in (doc.get('Results') or []):
        target = result.get('Target', '')
        for item in (result.get('Vulnerabilities') or []):
            out.append({'tool': tool, 'severity': str(item.get('Severity', 'unknown')).lower(),
                        # never an EMPTY package: a row nobody can attribute sorts to the
                        # top of an alphabetical list and pushes a real one out of a top-10.
                        'package': item.get('PkgName') or target or tool,
                        'id': item.get('VulnerabilityID', ''),
                        'advisory': item.get('PrimaryURL', '') or item.get('Title', '')})
        for item in (result.get('Secrets') or []):
            out.append({'tool': tool, 'severity': str(item.get('Severity', 'high')).lower(),
                        'package': target or tool, 'id': item.get('RuleID', 'secret'),
                        'advisory': item.get('Title', '')})
    return out


def findings_pip_audit(doc, tool):
    deps = doc.get('dependencies') if isinstance(doc, dict) else doc
    out = []
    for dep in (deps or []):
        for v in (dep.get('vulns') or []):
            out.append({'tool': tool, 'severity': 'unknown',
                        'package': '%s %s' % (dep.get('name', '?'), dep.get('version', '')),
                        'id': v.get('id', ''), 'advisory': (v.get('description') or '')[:60]})
    return out


def findings_gitleaks(doc, tool):
    rows = doc if isinstance(doc, list) else (doc.get('findings') or [])
    return [{'tool': tool, 'severity': 'high', 'package': r.get('File', '?'),
             'id': r.get('RuleID', 'secret'), 'advisory': r.get('Description', '')[:60]}
            for r in rows if isinstance(r, dict)]


def findings_of(tool, doc):
    if tool.startswith('trivy'):
        return findings_trivy(doc, tool)
    if tool.startswith('pip-audit'):
        return findings_pip_audit(doc, tool)
    if tool.startswith('gitleaks'):
        return findings_gitleaks(doc, tool)
    return []          # npm audit's summary form carries no per-finding rows


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
    lines, rows, found = [], [], []
    for f in reports:
        tool = f[:-len('.json')]
        path = os.path.join(outdir, f)
        c, note = counts_for(tool, path)
        for k in totals:
            totals[k] += c[k]
        rows.append((tool, c, note))
        # ci-3: the rows themselves, worst first, so the report can name what a
        # count is a count OF. Unreadable report -> no rows, never an exception:
        # a scanner that wrote nonsense must not take the summary down with it.
        try:
            found += findings_of(tool, json.load(open(path)))
        except Exception:
            pass
    found.sort(key=lambda r: (RANK.get(r.get('severity'), 9), r.get('package', ''), r.get('id', '')))
    top = found[:int(os.environ.get('CI_SCAN_TOP', '10'))]
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
    if top:
        lines.append('## The worst of them, by package (ADVISORY — this list gates nothing)')
        lines.append('')
        lines.append('| severity | package | id | tool | advisory |')
        lines.append('|---|---|---|---|---|')
        for r in top:
            lines.append('| %s | %s | %s | %s | %s |'
                         % (r.get('severity', '?'), r.get('package', '?'), r.get('id', ''),
                            r.get('tool', ''), str(r.get('advisory', ''))[:60]))
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
    json.dump({'totals': totals, 'tools': {t: c for t, c, _ in rows}, 'skipped': skipped,
               'top': top}, open(os.path.join(outdir, 'SUMMARY.json'), 'w'), indent=1)
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
