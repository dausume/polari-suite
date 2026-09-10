#!/usr/bin/env python3
"""
os-security/render.py — render the DAC + MAC policy for ONE scenario and the
apps currently up.

  render.py --scenario isle [--apps apps.json | --apps-from-manifests | --apps-from-core URL]
            [--mode enforce|complain] [--out os-security/out]

Inputs
  scenarios/<name>.yml            the rings, fixed pieces, ports, networks
  apps                            a JSON list of {name, image, security:{…}} — from the
                                  manifests in the tree (--apps-from-manifests: every
                                  modules/*/polari-app.json with a `security` stanza),
                                  from a running core (--apps-from-core: GET /api/modules/health
                                  → the online modules' manifests), or a file the isle
                                  writes from its registry.json
Outputs (out/<scenario>/)
  apparmor/isle-app-<name>        one profile per app and per fixed piece
  seccomp/<kind>.json             one allow-list per kind used
  compose/<name>.security.yml     the fragment a compose/stack merges: security_opt, cap_drop/add, read_only, tmpfs
  docker-user.sh, ufw.sh, daemon.json, sysctl.conf, systemd-hardening.conf, perms.sh, audit.rules
  manifest.json                   what was rendered (apps, kinds, mode) — apply.sh removes profiles not in it
Pure: reads the tree, writes out/. Validates the stanza vocabulary; refuses unknown values.
"""
import argparse
import glob
import json
import os
import sys
import urllib.request

import jinja2
import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
SUITE = os.path.dirname(HERE)
PROFILES = ('web-app', 'worker', 'gateway', 'vpn-gateway', 'hardware-extension')
NETWORKS = ('isle', 'internet', 'none')
CAPS = ('NET_ADMIN', 'NET_BIND_SERVICE', 'CHOWN', 'SETUID', 'SETGID', 'DAC_READ_SEARCH')
DEFAULT_STANZA = {'profile': 'web-app', 'writable': ['/data'], 'network': ['isle'], 'capabilities': [], 'devices': [], 'ports': []}


def validate(app):
    sec = dict(DEFAULT_STANZA)
    sec.update({k: v for k, v in (app.get('security') or {}).items() if v is not None})
    errs = []
    if sec['profile'] not in PROFILES:
        errs.append(f"profile {sec['profile']!r} not in {PROFILES}")
    for n in sec['network']:
        if n not in NETWORKS:
            errs.append(f"network {n!r} not in {NETWORKS}")
    for c in sec['capabilities']:
        if c not in CAPS:
            errs.append(f"capability {c!r} not in the allow-list {CAPS}")
    for w in sec['writable']:
        if not w.startswith('/') or w in ('/', '/etc', '/usr', '/bin', '/sbin', '/lib', '/boot', '/root', '/home', '/proc', '/sys', '/dev'):
            errs.append(f"writable {w!r} refused (must be an absolute path inside the app's own tree)")
    if sec['devices'] and sec['profile'] != 'hardware-extension':
        errs.append("devices are only for profile hardware-extension (hardware belongs in a guest)")
    if errs:
        raise SystemExit(f"app {app.get('name')}: " + '; '.join(errs))
    return {'name': app['name'], 'image': app.get('image', ''), **sec}


def apps_from_manifests():
    out = []
    for p in sorted(glob.glob(os.path.join(SUITE, 'polari-rf-node', 'polari-framework', 'modules', '*', 'polari-app.json'))):
        m = json.load(open(p, encoding='utf-8'))
        if m.get('security'):
            out.append({'name': m['id'], 'image': 'prf-backend', 'security': m['security']})
    return out


def apps_from_core(url):
    with urllib.request.urlopen(url.rstrip('/') + '/api/modules/health?brief=1', timeout=15) as r:
        health = json.load(r)
    online = [m for m, rec in (health.get('modules') or {}).items() if rec.get('state') == 'online']
    by_id = {a['name']: a for a in apps_from_manifests()}
    return [by_id[m] for m in online if m in by_id]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--scenario', required=True)
    ap.add_argument('--apps')
    ap.add_argument('--apps-from-manifests', action='store_true')
    ap.add_argument('--apps-from-core')
    ap.add_argument('--mode', choices=['enforce', 'complain'])
    ap.add_argument('--out', default=os.path.join(HERE, 'out'))
    a = ap.parse_args()
    sc_path = os.path.join(HERE, 'scenarios', a.scenario + '.yml')
    if not os.path.isfile(sc_path):
        sys.exit(f"no scenario {a.scenario} (have: {', '.join(os.path.basename(p)[:-4] for p in glob.glob(os.path.join(HERE, 'scenarios', '*.yml')))})")
    sc = yaml.safe_load(open(sc_path, encoding='utf-8'))
    mode = a.mode or sc.get('mode', 'enforce')
    fixed_mode = sc.get('fixed_mode', mode)
    apps = []
    if a.apps:
        apps = json.load(open(a.apps, encoding='utf-8'))
    elif a.apps_from_manifests:
        apps = apps_from_manifests()
    elif a.apps_from_core:
        apps = apps_from_core(a.apps_from_core)
    apps = [validate(x) for x in apps]
    fixed = [validate({'name': f['name'], 'image': f.get('image', ''), 'security': {k: f.get(k) for k in ('profile', 'writable', 'network', 'capabilities', 'devices', 'ports')}}) for f in sc.get('fixed', [])]
    env = jinja2.Environment(loader=jinja2.FileSystemLoader(os.path.join(HERE, 'templates')), undefined=jinja2.StrictUndefined,
                             trim_blocks=True, lstrip_blocks=True, keep_trailing_newline=True)
    out = os.path.join(a.out, a.scenario)
    for d in ('apparmor', 'seccomp', 'compose'):
        os.makedirs(os.path.join(out, d), exist_ok=True)
    rendered = {'scenario': a.scenario, 'mode': mode, 'apps': [], 'fixed': [], 'kinds': []}
    tpl = env.get_template('apparmor/app.j2')
    kinds = set()
    for group, items, m in (('apps', apps, mode), ('fixed', fixed, fixed_mode)):
        for app in items:
            name = f"isle-app-{app['name']}"
            open(os.path.join(out, 'apparmor', name), 'w', encoding='utf-8').write(
                tpl.render(profile_name=name, app=app, scenario=a.scenario, mode=m))
            kinds.add(app['profile'])
            frag = {'services': {app['name']: {
                'security_opt': [f'apparmor={name}', f"seccomp={os.path.join(out, 'seccomp', app['profile'] + '.json')}", 'no-new-privileges:true'],
                'cap_drop': ['ALL'], **({'cap_add': app['capabilities']} if app['capabilities'] else {}),
                'read_only': True, 'tmpfs': ['/tmp', '/run'], 'pids_limit': 512}}}
            yaml.safe_dump(frag, open(os.path.join(out, 'compose', f"{app['name']}.security.yml"), 'w', encoding='utf-8'), sort_keys=False)
            rendered[group].append({'name': app['name'], 'profile': name, 'kind': app['profile'], 'mode': m})
    stpl = env.get_template('seccomp/kind.json.j2')
    for k in sorted(kinds):
        txt = stpl.render(kind=k, scenario=a.scenario)
        json.loads(txt)   # must be valid JSON
        open(os.path.join(out, 'seccomp', k + '.json'), 'w', encoding='utf-8').write(txt)
    rendered['kinds'] = sorted(kinds)
    ctx = {'scenario': a.scenario, 'docker': sc.get('docker', {}), 'allow_to_host': sc.get('allow_to_host', []),
           'deny_to_host_ports': sc.get('deny_to_host_ports', []), 'ufw': sc.get('ufw', {'enabled': False, 'allow': [], 'default_incoming': 'deny'}),
           'host': sc.get('host', {'perms': []}), 'host_units': ['isle-host-agent', 'mesh-mdns', 'polari-isle-push'],
           'host_rw_paths': ['/etc/isle-mesh/agent', '/run/isle-mesh', '/var/lib/isle']}
    for src, dst in (('firewall/docker-user.sh.j2', 'docker-user.sh'), ('firewall/ufw.sh.j2', 'ufw.sh'), ('dac/daemon.json.j2', 'daemon.json'),
                     ('dac/sysctl.conf.j2', 'sysctl.conf'), ('dac/systemd-hardening.conf.j2', 'systemd-hardening.conf'),
                     ('dac/perms.sh.j2', 'perms.sh'), ('dac/audit.rules.j2', 'audit.rules')):
        open(os.path.join(out, dst), 'w', encoding='utf-8').write(env.get_template(src).render(**ctx))
    json.loads(open(os.path.join(out, 'daemon.json')).read())
    for f in ('docker-user.sh', 'ufw.sh', 'perms.sh'):
        os.chmod(os.path.join(out, f), 0o755)
    json.dump(rendered, open(os.path.join(out, 'manifest.json'), 'w', encoding='utf-8'), indent=2)
    print(f"rendered {a.scenario} ({mode}): {len(apps)} app(s), {len(fixed)} fixed piece(s), kinds {', '.join(rendered['kinds']) or '-'} → {out}")


if __name__ == '__main__':
    main()
