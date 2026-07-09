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

stdin: compose-config yaml   stdout: stack yaml
"""
import sys

import yaml

doc = yaml.safe_load(sys.stdin)
doc.pop("name", None)

for svc in (doc.get("services") or {}).values():
    svc.pop("container_name", None)
    svc.pop("restart", None)
    mem = svc.pop("mem_limit", None)
    svc.pop("cpu_shares", None)
    if mem is not None:
        limits = svc.setdefault("deploy", {}).setdefault("resources", {}).setdefault("limits", {})
        limits.setdefault("memory", str(mem))
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

yaml.safe_dump(doc, sys.stdout, sort_keys=False, default_flow_style=False)
