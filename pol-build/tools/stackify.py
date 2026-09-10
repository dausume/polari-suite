#!/usr/bin/env python3
"""stackify — turn `docker compose config` output into a docker-stack-
deployable file (bld-5 v1).

Transforms (each an explicit swarm-schema requirement):
  - drop top-level `name` (stack name is set at deploy time)
  - per service: drop container_name/restart (swarm owns naming+restart
    policy), convert mem_limit/cpu_shares into deploy.resources.limits
  - depends_on: map form (condition:) -> plain list (stack ignores
    startup conditions; healthcheck-based ordering is a swarm non-feature)
  - networks declared `external: true` with LOCAL scope become stack-owned
    overlay networks (cross-stack shared overlays are a later refinement —
    the stack gets its own namespaced overlay)
  - --constraint <service>=<expr> (repeatable, top-4): emit
    deploy.placement.constraints — how `pol allocate` pins a service to
    a machine (node labels, set by pol swarm init/join)

stdin: compose-config yaml   stdout: stack yaml
"""
import sys

import yaml

constraints = {}
with_profiles = set()
args = sys.argv[1:]
while args:
    if args[0] == "--constraint" and len(args) > 1:
        svc, _, expr = args[1].partition("=")
        constraints.setdefault(svc, []).append(expr)
        args = args[2:]
    elif args[0] == "--with-profile" and len(args) > 1:
        with_profiles.add(args[1])
        args = args[2:]
    else:
        args = args[1:]

doc = yaml.safe_load(sys.stdin)
if not doc:
    sys.exit("stackify: empty compose config on stdin (docker compose config failed?)")
doc.pop("name", None)
# prd-4: swarm has no profiles — a profile-gated service (odoo) deploys only
# when named with --with-profile; `build:` is authoring-only (compose builds
# the image locally; the stack pulls it by name).
for name in list(doc.get("services") or {}):
    svc = doc["services"][name]
    profs = svc.pop("profiles", None) or []
    if profs and not (set(profs) & with_profiles):
        del doc["services"][name]
        continue
    svc.pop("build", None)

for name, svc in (doc.get("services") or {}).items():
    for expr in constraints.get(name, []):
        placement = svc.setdefault("deploy", {}).setdefault(
            "placement", {})
        cons = placement.setdefault("constraints", [])
        if expr not in cons:
            cons.append(expr)

for svc in (doc.get("services") or {}).values():
    svc.pop("container_name", None)
    svc.pop("restart", None)
    mem = svc.pop("mem_limit", None)
    svc.pop("cpu_shares", None)
    if mem is not None:
        limits = svc.setdefault("deploy", {}).setdefault("resources", {}).setdefault("limits", {})
        limits.setdefault("memory", str(mem))
    # compose config emits cpus as floats; the stack schema requires strings.
    for section in ("limits", "reservations"):
        res = svc.get("deploy", {}).get("resources", {}).get(section)
        if res and "cpus" in res and not isinstance(res["cpus"], str):
            res["cpus"] = str(res["cpus"])
    dep = svc.get("depends_on")
    if isinstance(dep, dict):
        svc["depends_on"] = sorted(dep.keys())
    for port in svc.get("ports") or []:
        # compose config emits interpolated ports as strings; the stack
        # schema requires integers.
        if isinstance(port, dict):
            for k in ("published", "target"):
                if k in port and isinstance(port[k], str) and port[k].isdigit():
                    port[k] = int(port[k])

for net in (doc.get("networks") or {}).values():
    if isinstance(net, dict) and net.pop("external", False):
        net["driver"] = "overlay"
        net.pop("name", None)
    elif isinstance(net, dict):
        # swarm services can only attach to swarm-scoped networks;
        # compose bundles declare plain bridge networks — promote them.
        if net.get("driver") in (None, "bridge"):
            net["driver"] = "overlay"

# prd-4: configs/secrets are immutable in swarm — give each a content-versioned
# name so a changed file deploys as a new object (old ones can be pruned later).
import hashlib, os
for section in ("configs", "secrets"):
    for key, entry in (doc.get(section) or {}).items():
        path = (entry or {}).get("file")
        if path and os.path.isfile(path):
            digest = hashlib.sha256(open(path, "rb").read()).hexdigest()[:8]
            base = (entry.get("name") or key).split("-v")[0] if False else key
            entry["name"] = f"{key}-{digest}"
yaml.safe_dump(doc, sys.stdout, sort_keys=False, default_flow_style=False)
