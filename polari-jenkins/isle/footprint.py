#!/usr/bin/env python3
"""Summarise os-security/inventory.sh JSON (stdin) into a one-line Polari
FOOTPRINT: what Polari/isle put on the device, and nothing else.

Generic infrastructure the inventory also reports — docker itself, sshd,
containerd, libvirtd, a stray nginx/python image — is NOT a Polari
footprint and is deliberately not counted: the question this answers is
"is this device clear enough to be a throwaway?", not "is it empty".

  ""            the device is clear
  "unreadable"  the inventory did not parse
  "debs:2 guests:1 checkouts:1 /etc/polari pol-cli"
"""
import json
import re
import sys

POL = re.compile(r'polari|isle|prf|psc|pol-|shell-core|mesh', re.I)
GENERIC_UNIT = re.compile(r'(docker|ssh|sshd|containerd|libvirtd)\.')


def names(value):
    out = []
    for item in value or []:
        if isinstance(item, dict):
            item = '|'.join(str(v) for v in item.values())
        out.append(str(item))
    return out


def summarise(d):
    parts = []

    def add(label, items):
        items = [i for i in items if POL.search(i)]
        if items:
            parts.append('%s:%d' % (label, len(items)))

    dk = d.get('docker') or {}
    add('debs', names(d.get('debs')))
    add('containers', names(dk.get('containers')))
    add('stacks', names(dk.get('stacks')))
    add('images', names(dk.get('images')))
    add('units', [u for u in names(d.get('units')) if not GENERIC_UNIT.match(u)])
    add('checkouts', names(d.get('checkouts')))
    add('guests', names(d.get('guests')))
    if dk.get('volumes'):
        parts.append('volumes:%s' % dk['volumes'])
    for key, label in (('etc_isle_mesh', '/etc/isle-mesh'), ('etc_polari', '/etc/polari')):
        if d.get(key):
            parts.append(label)
    clis = d.get('clis') or {}
    for key in ('pol', 'isle'):
        if clis.get(key):
            parts.append('%s-cli' % key)
    if clis.get('isle_share'):
        parts.append('/usr/share/isle-mesh')
    return ' '.join(parts)


if __name__ == '__main__':
    try:
        data = json.load(sys.stdin)
    except Exception:
        print('unreadable')
        raise SystemExit(0)
    print(summarise(data))
