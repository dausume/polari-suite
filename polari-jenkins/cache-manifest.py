#!/usr/bin/env python3
"""polari-jenkins/cache-manifest.py — the OFFLINE-FIRST cache's bookkeeping.

ci-9, his ask 2026-09-19: *"the jenkins pipeline should try and use offline
artifacts for building where possible, that way we are taking less time when
repeatedly using the same data"*.

One record per cache ENTRY — `what` (a sentence a person can read), `sha256`,
`fetched`, `last_used`, `bytes` — kept as ONE index file per area
(`<cache>/<area>/MANIFEST.json`, a dict keyed by entry name) rather than a
sidecar file per entry: a wheelhouse is hundreds of files and a per-file
sidecar would double the inode count of the cache it is supposed to shrink.
The record shape is per entry either way, and `prune` reads exactly the
`last_used` the brief names.

A real file, not a heredoc: `python3 - <<'PY'` feeds the SCRIPT on stdin, so a
heredoc'd analyser can never also read piped data (the §70/§71 gotcha, twice
found the hard way). Everything here takes argv and prints to stdout.

    cache-manifest.py put    <manifest> <entry> <path> <what>   record/refresh an entry
    cache-manifest.py touch  <manifest> <entry>                 last_used = now
    cache-manifest.py get    <manifest> <entry>                 the record as JSON (exit 1 when absent)
    cache-manifest.py list   <manifest>                         entry<TAB>bytes<TAB>last_used<TAB>what
    cache-manifest.py prune  <manifest> <area-dir> <days>       drop entries unused for > days (deletes the files)
    cache-manifest.py sweep  <manifest> <area-dir>              forget entries whose file is gone
    cache-manifest.py report <report.json> <area> <cached> <fetched> <seconds>
    cache-manifest.py report-show <report.json>
"""
import datetime
import hashlib
import json
import os
import sys


def _now():
    return datetime.datetime.now().isoformat(timespec='seconds')


def _load(path):
    try:
        with open(path) as fh:
            data = json.load(fh)
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def _save(path, data):
    os.makedirs(os.path.dirname(path) or '.', exist_ok=True)
    tmp = path + '.tmp'
    with open(tmp, 'w') as fh:
        json.dump(data, fh, indent=1, sort_keys=True)
    os.replace(tmp, path)


def _sha256(path):
    h = hashlib.sha256()
    try:
        with open(path, 'rb') as fh:
            for chunk in iter(lambda: fh.read(1 << 20), b''):
                h.update(chunk)
    except Exception:
        return ''
    return h.hexdigest()


def _size(path):
    """Bytes of a file, or of a directory tree (a release entry is a tree)."""
    if os.path.isfile(path):
        return os.path.getsize(path)
    total = 0
    for root, _dirs, files in os.walk(path):
        for f in files:
            try:
                total += os.path.getsize(os.path.join(root, f))
            except OSError:
                pass
    return total


def _age_days(stamp):
    try:
        then = datetime.datetime.fromisoformat(stamp)
    except Exception:
        return None
    return (datetime.datetime.now() - then).total_seconds() / 86400.0


def cmd_put(manifest, entry, path, what):
    data = _load(manifest)
    rec = data.get(entry) or {}
    rec['what'] = what
    # a directory entry (a release tree) is not hashed file-by-file: its own
    # SHA256SUMS is the checksum that matters and is verified where it is used.
    rec['sha256'] = _sha256(path) if os.path.isfile(path) else ''
    rec['bytes'] = _size(path)
    rec.setdefault('fetched', _now())
    rec['last_used'] = _now()
    data[entry] = rec
    _save(manifest, data)
    print(rec['sha256'] or '(directory)')
    return 0


def cmd_touch(manifest, entry):
    data = _load(manifest)
    if entry not in data:
        return 1
    data[entry]['last_used'] = _now()
    _save(manifest, data)
    return 0


def cmd_get(manifest, entry):
    data = _load(manifest)
    if entry not in data:
        return 1
    print(json.dumps(data[entry], indent=1, sort_keys=True))
    return 0


def cmd_list(manifest):
    for entry, rec in sorted(_load(manifest).items()):
        print('%s\t%s\t%s\t%s' % (entry, rec.get('bytes', 0),
                                  rec.get('last_used', ''), rec.get('what', '')))
    return 0


def cmd_prune(manifest, area_dir, days):
    """Remove ONLY entries whose last_used is older than the knob.

    An entry with no readable last_used is KEPT and reported: the cache is an
    optimisation, and deleting something whose age we cannot read would be a
    guess that costs a download.
    """
    days = float(days)
    data = _load(manifest)
    removed = kept_unknown = 0
    freed = 0
    for entry in sorted(list(data)):
        rec = data[entry]
        age = _age_days(rec.get('last_used', ''))
        if age is None:
            kept_unknown += 1
            continue
        if age <= days:
            continue
        target = os.path.join(area_dir, entry)
        freed += rec.get('bytes', 0) or _size(target)
        if os.path.isdir(target) and not os.path.islink(target):
            import shutil
            shutil.rmtree(target, ignore_errors=True)
        elif os.path.exists(target):
            try:
                os.remove(target)
            except OSError:
                pass
        del data[entry]
        removed += 1
        print('  dropped %s (unused %.1f days)' % (entry, age))
    _save(manifest, data)
    print('%d removed, %.1f MB freed, %d kept (no readable last_used)'
          % (removed, freed / 1e6, kept_unknown))
    return 0


def cmd_sweep(manifest, area_dir):
    data = _load(manifest)
    gone = [e for e in data if not os.path.exists(os.path.join(area_dir, e))]
    for e in gone:
        del data[e]
    _save(manifest, data)
    print(len(gone))
    return 0


def cmd_report(path, area, cached, fetched, seconds):
    """Accumulate one build stage's cache arithmetic into pool/<version>/cache-report.json.

    bytes served from the cache vs bytes fetched over the network, and the
    seconds the stage took. `pol jenkins cache status` and the cicd mirror read
    this; nothing here estimates — a stage that cannot measure reports 0 and is
    honest about it.
    """
    try:
        with open(path) as fh:
            doc = json.load(fh)
    except Exception:
        doc = {}
    if not isinstance(doc, dict):
        doc = {}
    doc.setdefault('areas', {})
    rec = doc['areas'].setdefault(area, {'cached_bytes': 0, 'fetched_bytes': 0,
                                         'seconds': 0.0, 'stages': 0})
    rec['cached_bytes'] += int(cached or 0)
    rec['fetched_bytes'] += int(fetched or 0)
    rec['seconds'] = round(rec['seconds'] + float(seconds or 0), 2)
    rec['stages'] += 1
    total_c = sum(a['cached_bytes'] for a in doc['areas'].values())
    total_f = sum(a['fetched_bytes'] for a in doc['areas'].values())
    doc['cached_bytes'] = total_c
    doc['fetched_bytes'] = total_f
    doc['seconds'] = round(sum(a['seconds'] for a in doc['areas'].values()), 2)
    doc['hit_rate'] = round(total_c / (total_c + total_f), 4) if (total_c + total_f) else 0.0
    doc['at'] = _now()
    _save(path, doc)
    print('%s: %.1f MB cached / %.1f MB fetched (%.0f%% hit) in %.0fs'
          % (area, int(cached or 0) / 1e6, int(fetched or 0) / 1e6,
             100 * doc['hit_rate'], float(seconds or 0)))
    return 0


def cmd_report_show(path):
    try:
        with open(path) as fh:
            doc = json.load(fh)
    except Exception:
        print('no cache report yet (%s)' % path)
        return 1
    print('cache report %s — %.0f%% of the bytes this run needed came from the cache'
          % (doc.get('at', ''), 100 * doc.get('hit_rate', 0)))
    print('%-10s %12s %12s %9s' % ('area', 'from cache', 'fetched', 'seconds'))
    for area, rec in sorted((doc.get('areas') or {}).items()):
        print('%-10s %11.1fM %11.1fM %9.0f'
              % (area, rec['cached_bytes'] / 1e6, rec['fetched_bytes'] / 1e6, rec['seconds']))
    print('%-10s %11.1fM %11.1fM %9.0f'
          % ('TOTAL', doc.get('cached_bytes', 0) / 1e6,
             doc.get('fetched_bytes', 0) / 1e6, doc.get('seconds', 0)))
    return 0


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    cmd, rest = argv[1], argv[2:]
    table = {
        'put': (4, cmd_put), 'touch': (2, cmd_touch), 'get': (2, cmd_get),
        'list': (1, cmd_list), 'prune': (3, cmd_prune), 'sweep': (2, cmd_sweep),
        'report': (5, cmd_report), 'report-show': (1, cmd_report_show),
    }
    if cmd not in table:
        sys.stderr.write('cache-manifest.py: unknown command %r\n' % cmd)
        return 2
    need, fn = table[cmd]
    if len(rest) < need:
        sys.stderr.write('cache-manifest.py %s: needs %d argument(s)\n' % (cmd, need))
        return 2
    return fn(*rest[:need])


if __name__ == '__main__':
    sys.exit(main(sys.argv))
