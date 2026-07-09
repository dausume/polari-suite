#!/usr/bin/env python3
"""topology_render.py — TopologyDefinition -> build manifests (top-3).

Reads a portable topology package (topologies/<name>.topology.yml)
and emits pol-build/manifests/topology-<name>/:
  bundles-suite.yml   render.py manifest for the suite project
  bundles-node.yml    render.py manifest for polari-rf-node
  stacks.yml          swarm stacks (role + stack name + placement)
  actions.yml         the ordered `pol` actions apply/deploy replay

Instances map to the EXISTING template vocabulary by their exact
service-kind sets (the SHAPES table). Unknown combinations refuse
honestly, naming the knob: add a pol-services template + registry
entry, or reshape service_kinds to a known shape. Nothing here
deploys — `pol topology apply` replays actions.yml, human-invoked.

Parity contract: for the seeded staging-a topology the emitted
manifests are a SUBSET of suite-bundles.yml + node-bundles.yml, so
render.py's byte-parity gate proves the round trip.

Usage:
  topology_render.py <package.topology.yml> [--out-root <suite root>]
"""

import os
import sys

import yaml

# ---- the shape vocabulary (exact service-kind sets) -----------------

PRF_CORE = frozenset({'prf-backend', 'prf-frontend'})
PSC = frozenset({'psc-backend', 'psc-frontend', 'psc-redis'})
POL_INFRA = frozenset({'pol-mariadb', 'pol-keycloak',
                       'pol-file-store', 'pol-proxy'})
NODE_FULL = frozenset({'prf-backend', 'prf-frontend', 'prf-mariadb',
                       'prf-keycloak', 'prf-file-store', 'prf-proxy'})
TWIN = frozenset({'prf-backend-b', 'prf-frontend-b', 'prf-keydb-b'})
DASK = frozenset({'prf-dask'})
ENGINES = frozenset({'prf-msci-engines'})

#: env tier -> (suite output file, node output file) for the core
#: bundles (mirrors suite-bundles.yml / node-bundles.yml outputs).
SUITE_ENV_FILES = {
    'dev': 'docker-compose.yml',
    'staging': 'docker-compose.staging-nip.yml',
    'prod': 'docker-compose.prod.yml',
}
NODE_ENV_FILES = {
    'dev': 'docker-compose.yml',
    'stateless': 'docker-compose.stateless.yml',
    'staging': 'docker-compose.staging-nip.yml',
    'prod': 'docker-compose.prod.yml',
    'test': 'docker-compose.fullstack-test.yml',
}

SUITE_TEMPLATE = 'pol-services/compose/suite-bundle.yml.j2'
NODE_TEMPLATE = 'pol-services/compose/node-bundle.yml.j2'
SPECIALS_DIR = 'pol-services/compose/bundles'

KNOWN_SHAPES = (
    'prf-core {prf-backend,prf-frontend} (+ psc + pol-infra on the '
    'same machine = the combined suite)',
    'node-full {prf-backend,prf-frontend,prf-mariadb,prf-keycloak,'
    'prf-file-store,prf-proxy} (standalone rf node)',
    'twin {prf-backend-b,prf-frontend-b,prf-keydb-b} '
    '(db sqlite -> twin-b bundle, mariadb+keydb -> dbcombo bundle)',
    'dask {prf-dask}', 'engines {prf-msci-engines} '
    '(swarm -> polari-engines stack, compose -> msci-engines/'
    'remote-worker bundle)',
)


def die(msg):
    print(f'REFUSED: {msg}', file=sys.stderr)
    sys.exit(1)


def load_package(path):
    doc = yaml.safe_load(open(path))
    if not isinstance(doc, dict) or doc.get(
            'kind') != 'polari-topology-package':
        die(f'{path} is not a polari-topology-package')
    return doc


def group_instances(doc):
    """Map instances to build groups; refuse unknown shapes."""
    machines = {m['name']: m for m in doc.get('machines', [])}
    groups, claimed = [], set()
    insts = doc.get('instances', [])
    by_name = {i['name']: i for i in insts}

    def kinds(i):
        import json as _json
        return frozenset(_json.loads(i.get('service_kinds_json',
                                           '[]') or '[]'))

    # 1. the combined suite: prf-core + psc + pol-infra, same
    #    machine, all compose.
    by_machine = {}
    for i in insts:
        by_machine.setdefault(i.get('machine_name', ''), []).append(i)
    for machine, members in by_machine.items():
        shapes = {kinds(i): i for i in members
                  if i.get('orchestration_target') == 'compose'}
        if PRF_CORE in shapes and PSC in shapes and POL_INFRA in shapes:
            trio = [shapes[PRF_CORE], shapes[PSC], shapes[POL_INFRA]]
            envs = {i.get('env_tier', 'staging') for i in trio}
            if len(envs) != 1:
                die(f'suite trio on "{machine}" spans env tiers '
                    f'{sorted(envs)} — one tier per suite '
                    '(InstanceDefinition.env_tier)')
            env = envs.pop()
            if env not in SUITE_ENV_FILES:
                die(f'no suite bundle output for env "{env}" '
                    f'(known: {sorted(SUITE_ENV_FILES)})')
            groups.append({
                'group': 'suite', 'machine': machine, 'env': env,
                'instances': [i['name'] for i in trio],
                'project': 'suite', 'template': SUITE_TEMPLATE,
                'file': SUITE_ENV_FILES[env],
                'action': 'pol compose suite up'})
            claimed.update(i['name'] for i in trio)

    # 2. per-instance shapes.
    for i in insts:
        if i['name'] in claimed:
            continue
        k, env = kinds(i), i.get('env_tier', 'staging')
        target = i.get('orchestration_target', 'compose')
        db = i.get('db_backend', 'sqlite')
        machine = i.get('machine_name', '')
        remote = bool(machines.get(machine, {}).get('ssh_alias', ''))
        if k == NODE_FULL and target == 'compose':
            if env not in NODE_ENV_FILES:
                die(f'no node bundle output for env "{env}"')
            groups.append({
                'group': 'node', 'machine': machine, 'env': env,
                'instances': [i['name']], 'project': 'node',
                'template': NODE_TEMPLATE,
                'file': NODE_ENV_FILES[env], 'remote': remote,
                'action': 'pol compose node up'})
        elif k == TWIN and target == 'compose':
            special = ('dbcombo' if db == 'mariadb+keydb'
                       else 'twin-b')
            groups.append({
                'group': special, 'machine': machine, 'env': 'staging',
                'instances': [i['name']], 'project': 'node',
                'template': f'{SPECIALS_DIR}/docker-compose.'
                            f'{special}.yml.j2',
                'file': f'docker-compose.{special}.yml',
                'remote': remote,
                'action': 'pol compose twin up'})
        elif k == DASK and target == 'compose':
            groups.append({
                'group': 'dask', 'machine': machine, 'env': 'staging',
                'instances': [i['name']], 'project': 'node',
                'template': f'{SPECIALS_DIR}/docker-compose.dask'
                            '.yml.j2',
                'file': 'docker-compose.dask.yml', 'remote': remote,
                'action': 'pol compose dask up'})
        elif k == ENGINES and target == 'swarm':
            groups.append({
                'group': 'engines-stack', 'machine': machine,
                'env': 'staging', 'instances': [i['name']],
                'project': 'node',
                'template': f'{SPECIALS_DIR}/docker-compose.'
                            'msci-engines.yml.j2',
                'file': 'docker-compose.msci-engines.yml',
                'stack': 'polari-engines', 'role': 'engines',
                'replicas': i.get('replicas', 1),
                # machines are addressed by the stable label pol swarm
                # init/join sets, never by hostname
                'placement': (i.get('placement_constraint', '')
                              or (f'node.labels.polari.machine == '
                                  f'{machine}' if machine else '')),
                'remote': remote,
                'action': 'pol swarm deploy engines'})
        elif k == ENGINES and target == 'compose':
            special = 'remote-worker' if remote else 'msci-engines'
            groups.append({
                'group': special, 'machine': machine,
                'env': 'staging', 'instances': [i['name']],
                'project': 'node',
                'template': f'{SPECIALS_DIR}/docker-compose.'
                            f'{special}.yml.j2',
                'file': f'docker-compose.{special}.yml',
                'remote': remote,
                'action': ('pol deploy run ' + machine
                           + ' --role engines' if remote
                           else 'pol compose engines up')})
        elif k == PRF_CORE:
            die(f'instance "{i["name"]}" is a bare prf-core but no '
                'psc + pol-infra trio shares its machine — a '
                'standalone prf needs the node-full shape (its own '
                'infra). Knob: InstanceDefinition.service_kinds_json')
        else:
            die(f'instance "{i["name"]}" has no known build shape '
                f'for kinds {sorted(k)} / target {target}. Known '
                f'shapes: {KNOWN_SHAPES}. Knob: add a pol-services '
                'template + registry entry, then extend '
                'topology_render.py SHAPES')
        claimed.add(i['name'])
    return groups


def emit(doc, groups, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    name = doc.get('topology', {}).get('name', 'unnamed')
    header = (f'# GENERATED by topology_render.py from topology '
              f'"{name}" — do not hand-edit.\n'
              f'# Re-render: pol topology render {name}\n')

    def bundles_for(project):
        seen = {}
        for g in groups:
            if g['project'] != project:
                continue
            seen.setdefault(g['template'], []).append(
                {'env': g['env'], 'file': g['file']})
        return [{'template': t, 'outputs': outs}
                for t, outs in seen.items()]

    written = []
    for project, fname in (('suite', 'bundles-suite.yml'),
                           ('node', 'bundles-node.yml')):
        bundles = bundles_for(project)
        if not bundles:
            continue
        path = os.path.join(out_dir, fname)
        with open(path, 'w') as fh:
            fh.write(header)
            yaml.safe_dump({'bundles': bundles}, fh,
                           sort_keys=False, default_flow_style=False)
        written.append(path)

    stacks = [{'stack': g['stack'], 'role': g['role'],
               'machine': g['machine'],
               'replicas': g.get('replicas', 1),
               'placement': g.get('placement', ''),
               'source': g['file']}
              for g in groups if g['group'] == 'engines-stack']
    if stacks:
        path = os.path.join(out_dir, 'stacks.yml')
        with open(path, 'w') as fh:
            fh.write(header)
            yaml.safe_dump({'stacks': stacks}, fh, sort_keys=False,
                           default_flow_style=False)
        written.append(path)

    actions = [{'order': n + 1, 'group': g['group'],
                'machine': g['machine'],
                'remote': bool(g.get('remote', False)),
                'instances': g['instances'], 'command': g['action']}
               for n, g in enumerate(groups)]
    path = os.path.join(out_dir, 'actions.yml')
    with open(path, 'w') as fh:
        fh.write(header)
        yaml.safe_dump({'topology': name, 'actions': actions}, fh,
                       sort_keys=False, default_flow_style=False)
    written.append(path)
    return written


def main():
    args = sys.argv[1:]
    if not args:
        die('usage: topology_render.py <package.topology.yml> '
            '[--out-root <suite root>]')
    pkg_path = args[0]
    root = (args[args.index('--out-root') + 1]
            if '--out-root' in args else
            os.path.dirname(os.path.dirname(
                os.path.dirname(os.path.abspath(__file__)))))
    doc = load_package(pkg_path)
    name = doc.get('topology', {}).get('name', '')
    if not name:
        die('package has no topology.name')
    groups = group_instances(doc)
    out_dir = os.path.join(root, 'pol-build', 'manifests',
                           f'topology-{name}')
    written = emit(doc, groups, out_dir)
    print(f'topology "{name}": {len(groups)} build groups')
    for g in groups:
        where = f'@{g["machine"]}' + (' (remote)' if g.get('remote')
                                      else '')
        print(f'  {g["group"]:<14} {where:<24} -> {g["action"]}')
    for w in written:
        print(f'  wrote {os.path.relpath(w, root)}')


if __name__ == '__main__':
    main()
