#!/usr/bin/env python3
"""One-time migration aid (bld-3): unify the three hand-written suite
bundles (dev/staging/prod) into per-service ANNOTATED sources
(pol-services/compose/services/*.yml, comment-jinja with '## variation:'
notes) + a bundle source that includes them. Byte-parity by construction:
split points are computed per file and re-concatenation reproduces the
original bytes; env-grouped conditionals cover every difference.

Normalizations (collapse tier-tracking diffs into template values):
  image: X:(latest|staging|prod)     -> image: X:{{ suite_image_tag }}
  .generated/.env.(staging|prod)     -> .generated/.env.{{ gen_env }}
  .generated/nginx.(staging|prod).conf -> .generated/nginx.{{ gen_env }}.conf
  .generated/prf-runtime-config(.prod)?.json -> {{ prf_runtime_config }}
"""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ENVS = [("dev", "docker-compose.yml"),
        ("staging", "docker-compose.staging-nip.yml"),
        ("prod", "docker-compose.prod.yml")]
OUT_DIR = os.path.join(ROOT, "pol-services", "compose")


def normalize(text):
    text = re.sub(r"(image:\s+\S+?):(latest|staging|prod)\s*$",
                  r"\1:{{ suite_image_tag }}", text, flags=re.M)
    text = re.sub(r"\.generated/\.env\.(staging|prod)\b",
                  ".generated/.env.{{ gen_env }}", text)
    text = re.sub(r"\.generated/nginx\.(staging|prod)\.conf",
                  ".generated/nginx.{{ gen_env }}.conf", text)
    text = re.sub(r"\.generated/prf-runtime-config(\.prod)?\.json",
                  "{{ prf_runtime_config }}", text)
    text = re.sub(r"\.generated/psc-runtime-config(\.prod)?\.json",
                  "{{ psc_runtime_config }}", text)
    return text


def split_file(path):
    """-> (preamble, {svc: block}, order, tail); concat == original bytes."""
    lines = open(path).read().splitlines(keepends=True)
    svc_idx = []
    in_services = False
    services_line = None
    for i, l in enumerate(lines):
        if re.match(r"^services:\s*$", l):
            in_services = True
            services_line = i
            continue
        if in_services and re.match(r"^[A-Za-z]", l):
            in_services = False
            tail_first = i
        if in_services and re.match(r"^  [A-Za-z0-9_-]+:\s*$", l):
            svc_idx.append(i)
    # find tail start (first column-0 key after the last service)
    tail_first = None
    for i in range(svc_idx[-1] + 1, len(lines)):
        if re.match(r"^[A-Za-z]", lines[i]):
            tail_first = i
            break
    if tail_first is None:
        tail_first = len(lines)

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
    tail = "".join(lines[tail_start:])
    return preamble, blocks, order, tail


def grouped(texts):
    """{env: text} -> list of (envs_tuple, text) in dev,staging,prod order."""
    groups = []
    for env, _f in ENVS:
        t = texts[env]
        for g in groups:
            if g[1] == t:
                g[0].append(env)
                break
        else:
            groups.append(([env], t))
    return groups


def annotate(text):
    out = []
    for line in text.splitlines():
        out.append("# " + line if line.strip() else "# ")
    return out


def emit_section(texts, note_name):
    """Emit annotated lines for one section (verbatim or env-conditional)."""
    gs = grouped(texts)
    out = []
    if len(gs) == 1:
        out += annotate(gs[0][1])
        return out
    label = " | ".join("+".join(g[0]) for g in gs)
    out.append(f"## variation: env — {note_name} differs per tier: {label}")
    for n, (envs, text) in enumerate(gs):
        cond = " or ".join(f"env_name == '{e}'" for e in envs)
        kw = "if" if n == 0 else "elif"
        out.append(f"# {{% {kw} {cond} %}}")
        out += annotate(text)
    out.append("# {% endif %}")
    return out


def main():
    data = {env: split_file(os.path.join(ROOT, f)) for env, f in ENVS}
    order = data["dev"][2]
    assert all(d[2] == order for d in data.values()), "service order mismatch"

    svc_dir = os.path.join(OUT_DIR, "services")
    os.makedirs(svc_dir, exist_ok=True)

    for svc in order:
        texts = {env: normalize(data[env][1][svc]) for env, _ in ENVS}
        lines = ["# jinja-start",
                 f"## SERVICE: {svc} — annotated source (see suite-bundle.yml).",
                 "## Rendered per env by pol-build/manifests/suite-bundles.yml."]
        lines += emit_section(texts, svc)
        lines.append("# jinja-end")
        with open(os.path.join(svc_dir, f"{svc}.yml"), "w") as fh:
            fh.write("\n".join(lines) + "\n")
        print(f"  service source: services/{svc}.yml "
              f"({len(grouped(texts))} env group(s))")

    pre = {env: normalize(data[env][0]) for env, _ in ENVS}
    tail = {env: normalize(data[env][3]) for env, _ in ENVS}
    lines = ["# jinja-start",
             "## ==========================================================================",
             "## SUITE BUNDLE — annotated source generating ALL THREE suite compose files",
             "## (dev/staging/prod) via pol-build/manifests/suite-bundles.yml.",
             "## Per-service sources: pol-services/compose/services/*.yml (one file per",
             "## service kind — 1:1 with pol-build/registry/services.yml entries).",
             "## '## variation:' notes name the env groups on every conditional.",
             "## =========================================================================="]
    lines += emit_section(pre, "preamble")
    for svc in order:
        lines.append(f"# {{% include 'pol-services/compose/services/{svc}.yml.j2' %}}")
    lines += emit_section(tail, "tail (networks/volumes)")
    lines.append("# jinja-end")
    with open(os.path.join(OUT_DIR, "suite-bundle.yml"), "w") as fh:
        fh.write("\n".join(lines) + "\n")
    print("  bundle source: suite-bundle.yml")


if __name__ == "__main__":
    main()
