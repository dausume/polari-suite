#!/usr/bin/env python3
"""
os-security/render.py — render the DAC + MAC policy for ONE scenario and the
apps currently up.

  render.py --scenario isle [--apps apps.json | --apps-from-manifests | --apps-from-core URL]
            [--mode enforce|complain] [--out os-security/out]

Inputs
  scenarios/<name>.yml            the rings, fixed pieces, ports, networks, and how the MAC ring
                                  attaches on this route:
                                    mac_attach: security_opt    each container carries its own profile
                                                                (isle: plain docker; the compose fragment)
                                                docker-default  swarm: services cannot carry security_opt
                                                                (docker/cli drops it), so the node-wide
                                                                docker-default profile is rendered as the
                                                                UNION of the fixed pieces and loaded in
                                                                place of docker's stock one
                                    apps_run:   containers      every app is its own container → own profile
                                                in-core         apps are modules inside the core container
                                                                (`core: <fixed name>`) → no profile of their
                                                                own; their network/capabilities fold into
                                                                the core's (writable stays the core's)
  apps                            a JSON list of {name, image, security:{…}} — from the
                                  manifests in the tree (--apps-from-manifests: every
                                  modules/*/polari-app.json with a `security` stanza),
                                  from a running core (--apps-from-core: GET /api/modules/health
                                  → the online modules' manifests), or a file the isle
                                  writes from its registry.json
Outputs (out/<scenario>/)
  apparmor/isle-app-<name>        one profile per app (apps_run containers) and per fixed piece
  apparmor/docker-default         (mac_attach docker-default) the node-wide profile: the union
  apparmor/docker-default.moby    (mac_attach docker-default) docker's stock profile, for revert
  seccomp/<kind>.json             one allow-list per kind used
  compose/<name>.security.yml     the fragment a compose/stack merges — only keys the route honours
                                  (swarm: cap_drop/add, read_only, tmpfs, pids limit; no security_opt)
  docker-user.sh, ufw.sh, daemon.json, sysctl.conf, systemd-hardening.conf, perms.sh, audit.rules
  manifest.json                   what was rendered (apps, fixed, folded, kinds, mode, mac_attach) —
                                  apply.sh removes isle-app-* profiles not in it
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
MAC_ATTACH = ('security_opt', 'docker-default')
APPS_RUN = ('containers', 'in-core')


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


def _union(items, key):
    seen = []
    for it in items:
        for v in it.get(key) or []:
            if v not in seen:
                seen.append(v)
    return seen


def fold_into_core(apps, fixed, core_name):
    """apps_run in-core: modules run inside the core container. Their network and capabilities
    widen the core's stanza (a module that needs the internet or NET_ADMIN needs it from the core);
    writable is NOT unioned — module data lives under the core's own data path. Hardware
    extensions cannot run inside the core (they need a guest) and are left out, named."""
    core = next((f for f in fixed if f['name'] == core_name), None)
    if core is None:
        raise SystemExit(f"apps_run in-core needs a fixed piece named {core_name!r} (scenario key `core`)")
    folded, skipped = [], []
    for a in apps:
        if a['profile'] == 'hardware-extension' or a['devices']:
            skipped.append(a['name'])
            continue
        core['network'] = _union([core, a], 'network')
        if 'none' in core['network'] and len(core['network']) > 1:
            core['network'] = [n for n in core['network'] if n != 'none']
        core['capabilities'] = _union([core, a], 'capabilities')
        folded.append(a['name'])
    return folded, skipped


def node_profile(fixed):
    """mac_attach docker-default: ONE profile for every container on the node = the union of the
    fixed pieces' declared surfaces (the least a shared profile can be)."""
    kinds = {f['profile'] for f in fixed}
    kind = 'gateway' if kinds & {'gateway', 'vpn-gateway'} else ('hardware-extension' if 'hardware-extension' in kinds else 'worker')
    return {'name': 'docker-default', 'image': '(every container on this node)', 'profile': kind,
            'writable': _union(fixed, 'writable'), 'network': [n for n in _union(fixed, 'network') if n != 'none'] or ['none'],
            'capabilities': _union(fixed, 'capabilities'), 'devices': _union(fixed, 'devices'), 'ports': _union(fixed, 'ports')}


def compose_fragment(app, profile_name, seccomp_path, mac_attach):
    svc = {'cap_drop': ['ALL'], **({'cap_add': app['capabilities']} if app['capabilities'] else {}),
           'read_only': True, 'tmpfs': ['/tmp', '/run']}
    if mac_attach == 'security_opt':
        svc['security_opt'] = [f'apparmor={profile_name}', f'seccomp={seccomp_path}', 'no-new-privileges:true']
        svc['pids_limit'] = 512
    else:   # swarm: security_opt/pids_limit are dropped by `docker stack deploy`; the pids limit lives under deploy
        svc['deploy'] = {'resources': {'limits': {'pids': 512}}}
        svc['x-os-security'] = ('no security_opt: swarm services cannot carry an AppArmor/seccomp profile; the node-wide '
                                'docker-default profile (apparmor/docker-default) and the daemon seccomp-profile setting apply instead')
    return {'services': {app['name']: svc}}


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
    fixed_mode = a.mode or sc.get('fixed_mode', mode)   # --mode overrides BOTH (a render "in enforce" that left the fixed pieces in complain fooled a test on 2026-09-12)
    mac_attach = sc.get('mac_attach', 'security_opt')
    apps_run = sc.get('apps_run', 'containers')
    if mac_attach not in MAC_ATTACH or apps_run not in APPS_RUN:
        sys.exit(f"scenario {a.scenario}: mac_attach must be one of {MAC_ATTACH}, apps_run one of {APPS_RUN}")
    apps = []
    if a.apps:
        apps = json.load(open(a.apps, encoding='utf-8'))
    elif a.apps_from_manifests:
        apps = apps_from_manifests()
    elif a.apps_from_core:
        apps = apps_from_core(a.apps_from_core)
    apps = [validate(x) for x in apps]
    fixed = [validate({'name': f['name'], 'image': f.get('image', ''), 'security': {k: f.get(k) for k in ('profile', 'writable', 'network', 'capabilities', 'devices', 'ports')}}) for f in sc.get('fixed', [])]
    folded, skipped = [], []
    if apps_run == 'in-core':
        folded, skipped = fold_into_core(apps, fixed, sc.get('core', 'prf-backend'))
        apps = []
    env = jinja2.Environment(loader=jinja2.FileSystemLoader(os.path.join(HERE, 'templates')), undefined=jinja2.StrictUndefined,
                             trim_blocks=True, lstrip_blocks=True, keep_trailing_newline=True)
    out = os.path.join(a.out, a.scenario)
    for d in ('apparmor', 'seccomp', 'compose'):
        os.makedirs(os.path.join(out, d), exist_ok=True)
    for stale in glob.glob(os.path.join(out, 'apparmor', '*')) + glob.glob(os.path.join(out, 'compose', '*')):
        os.remove(stale)   # pure: what is not rendered now does not linger from a previous run
    rendered = {'scenario': a.scenario, 'mode': mode, 'mac_attach': mac_attach, 'apps_run': apps_run,
                'apps': [], 'fixed': [], 'folded': folded, 'folded_skipped': skipped, 'node': None, 'kinds': []}
    tpl = env.get_template('apparmor/app.j2')
    kinds = set()
    for group, items, m in (('apps', apps, mode), ('fixed', fixed, fixed_mode)):
        for app in items:
            name = f"isle-app-{app['name']}"
            open(os.path.join(out, 'apparmor', name), 'w', encoding='utf-8').write(
                tpl.render(profile_name=name, app=app, scenario=a.scenario, mode=m))
            kinds.add(app['profile'])
            frag = compose_fragment(app, name, os.path.join(out, 'seccomp', app['profile'] + '.json'), mac_attach)
            yaml.safe_dump(frag, open(os.path.join(out, 'compose', f"{app['name']}.security.yml"), 'w', encoding='utf-8'), sort_keys=False)
            rendered[group].append({'name': app['name'], 'profile': name, 'kind': app['profile'], 'mode': m})
    if mac_attach == 'docker-default':
        node = node_profile(fixed)
        open(os.path.join(out, 'apparmor', 'docker-default'), 'w', encoding='utf-8').write(
            tpl.render(profile_name='docker-default', app=node, scenario=a.scenario, mode=fixed_mode))
        open(os.path.join(out, 'apparmor', 'docker-default.moby'), 'w', encoding='utf-8').write(
            env.get_template('apparmor/docker-default.moby.j2').render(scenario=a.scenario))
        kinds.add(node['profile'])
        rendered['node'] = {'name': 'docker-default', 'profile': 'docker-default', 'kind': node['profile'], 'mode': fixed_mode,
                            'union_of': [f['name'] for f in fixed], 'revert': 'docker-default.moby'}
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
    extra = ''
    if apps_run == 'in-core':
        extra = f", {len(folded)} module(s) folded into the core's profile" + (f" ({len(skipped)} hardware app(s) left out: {', '.join(skipped)})" if skipped else '')
    if mac_attach == 'docker-default':
        extra += ', node-wide docker-default rendered (+ stock copy for revert)'
    print(f"rendered {a.scenario} ({mode}, mac via {mac_attach}): {len(apps)} app profile(s), {len(fixed)} fixed piece(s){extra}, kinds {', '.join(rendered['kinds']) or '-'} → {out}")


if __name__ == '__main__':
    main()
