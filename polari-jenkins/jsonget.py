#!/usr/bin/env python3
"""polari-jenkins/jsonget.py — read one field out of a JSON file, from a pipeline.

    jsonget.py <file> <dotted.path> [--default X]   one scalar, on stdout
    jsonget.py <file> <dotted.path> --lines         a list, one item per line
    jsonget.py <file> leaks --leak-lines            ci-10's leak objects, rendered

WHY THIS EXISTS. The Jenkinsfiles used `readJSON`, which comes from the
pipeline-utility-steps plugin — and that plugin is NOT in `casc/plugins.txt`, so
it has never been installed on this controller. `readJSON` therefore threw
`NoSuchMethodError` the first time a run reached it, which was ci-12's first
complete `polari-test`: the verdict had already been written and the state
marked covered, and the build still went RED in its post block. The job's colour
is supposed to mean "did it run" — a missing plugin turning a recorded verdict
into a failure is precisely the confusion the design exists to avoid.

(It had been latent since ci-10: `Jenkinsfile.isle-test` has called `readJSON`
twice per stage since then, and no run had ever got that far.)

So: no plugin. Every other reader in this sub-project already parses JSON with
python3, and this is that, as a real file taking argv — because
`python3 - <<'PY'` feeds the SCRIPT on stdin and cannot also read a piped
document, a trap this codebase has hit four times.

A MISSING FIELD IS NOT AN ERROR. It prints the default (empty unless `--default`
says otherwise) and exits 0: a pipeline reading an optional reading must not die
because an optional reading is absent. An UNREADABLE FILE is also not an error,
for the same reason — the caller checks the file exists when that matters.
"""
import json
import sys


def dig(doc, path, default=''):
    cur = doc
    for part in path.split('.'):
        if part == '':
            continue
        if isinstance(cur, dict):
            if part not in cur:
                return default
            cur = cur[part]
        elif isinstance(cur, list):
            try:
                cur = cur[int(part)]
            except (ValueError, IndexError):
                return default
        else:
            return default
    return default if cur is None else cur


def leak_line(item):
    """ci-10's leak object → the one sentence a person reads.

    The ONE place this is formatted. It used to live inline in the Jenkinsfile,
    which meant the rendering and the reader could drift.
    """
    if not isinstance(item, dict):
        return str(item)
    return '%s: %s (%s → %s)' % (item.get('kind', '?'), item.get('item', '?'),
                                 item.get('baseline', '?'), item.get('now', '?'))


def main(argv):
    if len(argv) < 3:
        sys.stderr.write(__doc__.split('\n\n')[1] + '\n')
        return 2
    path_file, key = argv[1], argv[2]
    lines = '--lines' in argv
    leaks = '--leak-lines' in argv
    default = ''
    if '--default' in argv:
        i = argv.index('--default')
        if i + 1 < len(argv):
            default = argv[i + 1]
    try:
        doc = json.load(open(path_file))
    except Exception:
        print(default)
        return 0
    value = dig(doc, key, default)
    if leaks:
        for item in (value if isinstance(value, list) else []):
            print(leak_line(item))
        return 0
    if lines:
        for item in (value if isinstance(value, list) else []):
            print(item)
        return 0
    if isinstance(value, bool):
        print('true' if value else 'false')
    elif isinstance(value, (dict, list)):
        print(json.dumps(value))
    else:
        print(value)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
