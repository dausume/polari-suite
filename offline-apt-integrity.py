#!/usr/bin/env python3
"""Build-time distro DEB acquisition against authenticated apt SHA256 records.

The resolver must use signed apt indexes and Acquire::ForceHash=SHA256.
Neither a matching filename nor a matching byte count establishes integrity.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
from urllib.parse import urlsplit


FILENAME = re.compile(r'[A-Za-z0-9][A-Za-z0-9.+%:~_-]*\.deb')


def inventory(records):
    selected = {}
    urls = {}
    for line in records.splitlines():
        if not line.lstrip().startswith("'"):
            continue
        fields = shlex.split(line)
        if len(fields) != 4:
            raise ValueError('incomplete apt URI metadata: ' + line)
        uri, filename, size, checksum = fields
        if urlsplit(uri).scheme not in ('http', 'https') or not urlsplit(uri).hostname:
            raise ValueError('unexpected distro URI scheme')
        if not FILENAME.fullmatch(filename):
            raise ValueError('unsafe apt archive filename: ' + filename)
        if not size.isdecimal() or int(size) <= 0:
            raise ValueError('missing/invalid apt archive size: ' + filename)
        match = re.fullmatch(r'SHA256:([a-fA-F0-9]{64})', checksum)
        if match is None:
            raise ValueError('authenticated SHA256 metadata required: ' + filename)
        entry = {'uri': uri, 'file': filename, 'size': int(size), 'sha256': match[1].lower()}
        # Older cache builders used the URI's escaped basename instead of
        # apt's canonical archive filename. Reuse those bytes only if verified.
        legacy = Path(urlsplit(uri).path).name
        if FILENAME.fullmatch(legacy) and legacy != filename:
            entry['legacyCacheFile'] = legacy
        identity = (entry['size'], entry['sha256'])
        if filename in selected and (selected[filename]['size'], selected[filename]['sha256']) != identity:
            raise ValueError('ambiguous apt metadata for archive: ' + filename)
        if uri in urls and urls[uri] != identity:
            raise ValueError('ambiguous apt metadata for URI: ' + uri)
        urls[uri] = identity
        selected.setdefault(filename, entry)
    if not selected:
        raise ValueError('no distro DEBs with authenticated SHA256 metadata were selected')
    return list(selected.values())


def verified(path, entry):
    if path.is_symlink() or not path.is_file() or path.stat().st_size != entry['size']:
        return False
    result = hashlib.sha256()
    with path.open('rb') as source:
        for block in iter(lambda: source.read(1024 * 1024), b''):
            result.update(block)
    return result.hexdigest() == entry['sha256']


def copy_verified(source, destination, entry):
    if destination.exists():
        if verified(destination, entry):
            return
        raise ValueError('output archive collision/integrity mismatch: ' + str(destination))
    with tempfile.NamedTemporaryFile(prefix='.verified-copy-', dir=destination.parent, delete=False) as stream:
        temporary = Path(stream.name)
    try:
        shutil.copyfile(source, temporary)
        if not verified(temporary, entry):
            raise ValueError('copied archive failed authenticated SHA256/size verification: ' + entry['file'])
        temporary.chmod(0o644)
        temporary.replace(destination)
    finally:
        temporary.unlink(missing_ok=True)


def acquire(entries, output, cache=None):
    output.mkdir(parents=True, exist_ok=True)
    if cache:
        cache.mkdir(parents=True, exist_ok=True)

    def one(entry):
        destination = output / entry['file']
        if destination.exists():
            if not verified(destination, entry):
                raise ValueError('output archive collision/integrity mismatch: ' + str(destination))
            return 'cached', entry['size']
        if cache:
            for filename in dict.fromkeys((entry['file'], entry.get('legacyCacheFile', entry['file']))):
                candidate = cache / filename
                if verified(candidate, entry):
                    copy_verified(candidate, destination, entry)
                    return 'cached', entry['size']
                if candidate.exists():
                    print('Ignoring cache entry failing authenticated SHA256/size: ' + filename, file=sys.stderr)
        directory = cache or output
        with tempfile.NamedTemporaryFile(prefix='.apt-download-', suffix='.part', dir=directory, delete=False) as stream:
            temporary = Path(stream.name)
        try:
            subprocess.run(['curl', '-fLsS', '--output', str(temporary), '--url', entry['uri']], check=True)
            if not verified(temporary, entry):
                raise ValueError('download rejected: authenticated SHA256/size mismatch: ' + entry['file'])
            copy_verified(temporary, destination, entry)
            if cache:
                temporary.chmod(0o644)
                temporary.replace(cache / entry['file'])
            return 'fetched', entry['size']
        finally:
            temporary.unlink(missing_ok=True)

    # The resolver remains memory-capped separately; downloads retain the
    # original pipeline's P2 concurrency and hash in bounded chunks.
    with ThreadPoolExecutor(max_workers=2) as workers:
        results = list(workers.map(one, entries))
    return {kind + '_bytes': sum(size for source, size in results if source == kind)
            for kind in ('cached', 'fetched')}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    actions = parser.add_subparsers(dest='action', required=True)
    selected = actions.add_parser('inventory')
    selected.add_argument('--records', required=True, type=Path)
    selected.add_argument('--json', required=True, type=Path)
    selected.add_argument('--uris', required=True, type=Path)
    fetch = actions.add_parser('fetch')
    fetch.add_argument('--inventory', required=True, type=Path)
    fetch.add_argument('--output', required=True, type=Path)
    fetch.add_argument('--cache', type=Path)
    args = parser.parse_args()
    try:
        if args.action == 'inventory':
            entries = inventory(args.records.read_text())
            args.json.write_text(json.dumps({'schemaVersion': 1, 'source': 'signed-apt-print-uris-SHA256', 'packages': entries}, indent=2) + '\n')
            args.uris.write_text(''.join(entry['uri'] + '\n' for entry in entries))
        else:
            document = json.loads(args.inventory.read_text())
            if document.get('schemaVersion') != 1 or document.get('source') != 'signed-apt-print-uris-SHA256':
                raise ValueError('unsupported/missing authenticated apt inventory contract')
            # Revalidate the serialized contract rather than accepting a
            # user-provided filename/path or missing checksum at fetch time.
            entries = inventory('\n'.join("'%s' %s %s SHA256:%s" %
                (entry['uri'], entry['file'], entry['size'], entry['sha256'])
                for entry in document['packages']))
            report = acquire(entries, args.output, args.cache)
            print('[cache-report] apt cached_bytes=%s fetched_bytes=%s entries=%s' %
                  (report['cached_bytes'], report['fetched_bytes'], len(entries)))
    except (ValueError, KeyError, OSError, subprocess.SubprocessError) as error:
        print('Offline distro acquisition refused: ' + str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
