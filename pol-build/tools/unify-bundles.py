#!/usr/bin/env python3
"""Generalized bundle unifier (bld-3) — successor of unify-suite-bundles.py.

Splits a family of hand-written compose bundles into per-service ANNOTATED
sources (comment-jinja, '## variation:' notes) + a bundle assembly source
with PRESENCE-AWARE includes ({% if env_name in (...) %} around services
that only exist in some variants). Byte parity by construction.

Usage: unify-bundles.py suite|node
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

CONFIGS = {
    "node": {
        "base": os.path.join(ROOT, "polari-rf-node"),
        "envs": [("dev", "docker-compose.yml"),
                 ("stateless", "docker-compose.stateless.yml"),
                 ("staging", "docker-compose.staging-nip.yml"),
                 ("prod", "docker-compose.prod.yml"),
                 ("test", "docker-compose.fullstack-test.yml")],
        "order": ["prf-mariadb", "prf-keycloak", "prf-proxy", "prf-file-store",
                  "frontend", "backend", "polari-framework-tests",
                  "polari-framework-server", "polari-frontend-tests"],
        "out": os.path.join(ROOT, "polari-rf-node", "pol-services", "compose"),
        "bundle_name": "node-bundle.yml",
        "include_prefix": "pol-services/compose/services/",
        "normalize": [
            (r"(image:\s+prf-[a-z-]+):(dev|stateless|staging|prod|test)\s*$",
             r"\1:{{ node_image_tag }}", re.M),
            (r"\.generated/\.env\.(staging|prod)\b",
             ".generated/.env.{{ gen_env }}", 0),
            (r"\.generated/nginx\.(staging|prod)\.conf",
             ".generated/nginx.{{ gen_env }}.conf", 0),
            (r"polari-fullstack-test-network|polari-node-network",
             "{{ node_network }}", 0),
        ],
    },
}


def normalize(text, rules):
    for pat, rep, flags in rules:
        text = re.sub(pat, rep, text, flags=flags)
    return text


def split_file(path):
    lines = open(path).read().splitlines(keepends=True)
    svc_idx, in_services, services_line = [], False, None
    for i, l in enumerate(lines):
        if re.match(r"^services:\s*$", l):
            in_services, services_line = True, i
            continue
        if in_services and re.match(r"^[A-Za-z]", l):
            in_services = False
        if in_services and re.match(r"^  [A-Za-z0-9_-]+:\s*$", l):
            svc_idx.append(i)
    tail_first = len(lines)
    for i in range(svc_idx[-1] + 1, len(lines)):
        if re.match(r"^[A-Za-z]", lines[i]):
            tail_first = i
            break

    def ext_back(i, floor):
        j = i
        while j - 1 > floor and (lines[j - 1].strip() == "" or lines[j - 1].lstrip().startswith("#")):
            j -= 1
        return j

    starts = [ext_back(i, services_line) for i in svc_idx]
    tail_start = ext_back(tail_first, svc_idx[-1])
    preamble = "".join(lines[: starts[0]])
    blocks, order = {}, []
    for n, s in enumerate(starts):
        e = starts[n + 1] if n + 1 < len(starts) else tail_start
        name = re.match(r"^  ([A-Za-z0-9_-]+):", lines[svc_idx[n]]).group(1)
        order.append(name)
        blocks[name] = "".join(lines[s:e])
    return preamble, blocks, order, "".join(lines[tail_start:])


def grouped(texts, env_order):
    groups = []
    for env in env_order:
        if env not in texts:
            continue
        t = texts[env]
        for g in groups:
            if g[1] == t:
                g[0].append(env)
                break
        else:
            groups.append(([env], t))
    return groups


def annotate(text):
    return ["# " + l if l.strip() else "# " for l in text.splitlines()]


def emit_section(texts, note_name, env_order):
    gs = grouped(texts, env_order)
    out = []
    if len(gs) == 1 and len(gs[0][0]) == len([e for e in env_order if e in texts]):
        if len(texts) == len(env_order):
            return annotate(gs[0][1])
    label = " | ".join("+".join(g[0]) for g in gs)
    out.append(f"## variation: env — {note_name}: {label}")
    for n, (envs, text) in enumerate(gs):
        cond = " or ".join(f"env_name == '{e}'" for e in envs)
        kw = "if" if n == 0 else "elif"
        out.append(f"# {{% {kw} {cond} %}}")
        out += annotate(text)
    out.append("# {% endif %}")
    return out


def main():
    cfg = CONFIGS[sys.argv[1]]
    env_order = [e for e, _ in cfg["envs"]]
    data = {env: split_file(os.path.join(cfg["base"], f)) for env, f in cfg["envs"]}
    for env, d in data.items():
        assert [s for s in cfg["order"] if s in d[2]] == d[2], f"order mismatch in {env}"

    svc_dir = os.path.join(cfg["out"], "services")
    os.makedirs(svc_dir, exist_ok=True)

    presence = {}
    for svc in cfg["order"]:
        texts = {env: normalize(data[env][1][svc], cfg["normalize"])
                 for env in env_order if svc in data[env][1]}
        presence[svc] = [e for e in env_order if e in texts]
        lines = ["# jinja-start",
                 f"## SERVICE: {svc} — annotated source; envs: {'+'.join(presence[svc])}.",
                 "## Assembled by the bundle source per the manifest."]
        lines += emit_section(texts, svc, env_order)
        lines.append("# jinja-end")
        with open(os.path.join(svc_dir, f"{svc}.yml"), "w") as fh:
            fh.write("\n".join(lines) + "\n")
        print(f"  service source: services/{svc}.yml (envs {'+'.join(presence[svc])}, "
              f"{len(grouped(texts, env_order))} group(s))")

    pre = {env: normalize(data[env][0], cfg["normalize"]) for env in env_order}
    tail = {env: normalize(data[env][3], cfg["normalize"]) for env in env_order}
    lines = ["# jinja-start",
             "## ==========================================================================",
             f"## BUNDLE ASSEMBLY — generates every '{sys.argv[1]}' compose variant from",
             "## the per-service sources (presence-aware includes). Driven by the",
             "## pol-build manifest; '## variation:' notes name env groups everywhere.",
             "## =========================================================================="]
    lines += emit_section(pre, "preamble", env_order)
    for svc in cfg["order"]:
        envs = presence[svc]
        inc = f"# {{% include '{cfg['include_prefix']}{svc}.yml.j2' %}}"
        if len(envs) == len(env_order):
            lines.append(inc)
        else:
            cond = " or ".join(f"env_name == '{e}'" for e in envs)
            lines.append(f"## variation: env — {svc} only exists in: {'+'.join(envs)}")
            lines.append(f"# {{% if {cond} %}}")
            lines.append(inc)
            lines.append("# {% endif %}")
    lines += emit_section(tail, "tail (networks/volumes)", env_order)
    lines.append("# jinja-end")
    with open(os.path.join(cfg["out"], cfg["bundle_name"]), "w") as fh:
        fh.write("\n".join(lines) + "\n")
    print(f"  bundle source: {cfg['bundle_name']}")


if __name__ == "__main__":
    main()
