#!/usr/bin/env python3
"""Build-time only: acquire a pristine pinned base and its OpenWrt IPK closure.

Never reads a running VM or changes host networking. Output is input to
build-offline-medium.sh --router-image ... --router-packages ... .
"""
import argparse
import gzip
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import urllib.request

VERSION = '23.05.3'
BASE_SHA256 = '7643950cbf6bf5d785525f300efc4e2ceaad613b5d0725886e7f5fcc5a9d18f9'
ROOTS = ['avahi-dbus-daemon', 'avahi-utils', 'ip-full', 'tcpdump']


def fetch(url, destination, digest=None):
    if destination.is_file() and digest and hashlib.sha256(destination.read_bytes()).hexdigest() == digest:
        return
    temporary = destination.with_suffix(destination.suffix + '.part')
    try:
        with urllib.request.urlopen(url, timeout=25) as response, temporary.open('wb') as output:
            shutil.copyfileobj(response, output)
        if digest and hashlib.sha256(temporary.read_bytes()).hexdigest() != digest:
            raise ValueError('checksum mismatch: ' + url)
        temporary.replace(destination)
    finally:
        temporary.unlink(missing_ok=True)


def stanzas(text):
    for stanza in text.split('\n\n'):
        fields = {}
        for line in stanza.splitlines():
            if ': ' in line and not line.startswith(' '):
                key, value = line.split(': ', 1)
                fields[key] = value
        if fields.get('Package'):
            yield fields


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    output = args.output.resolve()
    if str(output).startswith('/var/lib/libvirt/'):
        parser.error('output must be a build cache, never an installed VM directory')
    output.mkdir(parents=True, exist_ok=True)
    packages = output / 'packages'
    packages.mkdir(exist_ok=True)
    upstream = f'https://downloads.openwrt.org/releases/{VERSION}'
    target = upstream + '/targets/x86/64'
    base = output / f'openwrt-{VERSION}-x86-64-generic-ext4-combined.img.gz'
    print('Acquiring pinned pristine OpenWrt base', flush=True)
    fetch(target + '/' + base.name, base, BASE_SHA256)
    manifest = output / 'base.manifest'
    fetch(target + f'/openwrt-{VERSION}-x86-64.manifest', manifest)
    installed = dict(line.split(' - ', 1) for line in manifest.read_text().splitlines() if ' - ' in line)
    feeds = [target + '/packages'] + [upstream + '/packages/x86_64/' + name for name in ('base', 'packages', 'luci', 'routing')]
    index = {}
    for number, feed in enumerate(feeds):
        local = output / f'feed-{number}.gz'
        fetch(feed + '/Packages.gz', local)
        for fields in stanzas(gzip.decompress(local.read_bytes()).decode()):
            # Feed order matches OpenWrt: target then base then packages.
            index.setdefault(fields['Package'], (feed, fields))
    pending = list(ROOTS)
    selected = {}
    while pending:
        requirement = pending.pop()
        match = re.fullmatch(r'([\w+.-]+)(?:\s*\(([<>=]+)\s*([^()]+)\))?', requirement.strip())
        if not match:
            raise ValueError('unsupported OpenWrt dependency: ' + requirement)
        name, operator, wanted = match.groups()
        if name in installed:
            if operator and subprocess.run(['dpkg', '--compare-versions', installed[name], operator, wanted]).returncode:
                raise ValueError('base package does not satisfy ' + requirement)
            continue
        if name in selected:
            if operator and subprocess.run(['dpkg', '--compare-versions', selected[name]['version'], operator, wanted]).returncode:
                raise ValueError('selected package does not satisfy ' + requirement)
            continue
        if name not in index:
            raise ValueError('OpenWrt dependency not found: ' + requirement)
        feed, fields = index[name]
        if operator and subprocess.run(['dpkg', '--compare-versions', fields['Version'], operator, wanted]).returncode:
            raise ValueError('available package does not satisfy ' + requirement)
        filename = fields['Filename']
        if '/' in filename or not filename.endswith('.ipk'):
            raise ValueError('unexpected package filename: ' + filename)
        digest = fields.get('SHA256sum')
        if not digest or not re.fullmatch('[0-9a-f]{64}', digest):
            raise ValueError('missing package checksum: ' + name)
        print('Acquiring ' + name, flush=True)
        fetch(feed + '/' + filename, packages / filename, digest)
        selected[name] = {'file': filename, 'version': fields['Version'], 'sha256': digest, 'depends': fields.get('Depends', '')}
        pending.extend(d.strip() for d in fields.get('Depends', '').split(',') if d.strip())
    # Convert only the checked pristine raw image, never an installed qcow2.
    disk = output / 'openwrt-isle-router.qcow2'
    with tempfile.TemporaryDirectory(dir=output) as directory:
        raw = Path(directory) / 'base.img'
        # OpenWrt gzip has trailing padding; zlib accepts its first stream.
        import zlib
        raw.write_bytes(zlib.decompress(base.read_bytes(), 16 + zlib.MAX_WBITS))
        subprocess.run(['qemu-img', 'convert', '-f', 'raw', '-O', 'qcow2', str(raw), str(disk)], check=True)
        subprocess.run(['qemu-img', 'resize', str(disk), '4G'], check=True)
    inventory = {'openwrt': VERSION, 'baseSha256': BASE_SHA256, 'roots': ROOTS, 'basePackages': installed, 'packages': selected,
                 'imageSha256': hashlib.sha256(disk.read_bytes()).hexdigest()}
    (output / 'router-build.json').write_text(json.dumps(inventory, indent=2) + '\n')
    print(f'Prepared pristine router + {len(selected)} IPKs in {output}', flush=True)


if __name__ == '__main__':
    main()
