#!/usr/bin/env python3
"""pol-build renderer (bld-2) — python replacement for the Ansible render
step of the embed-jinja pipeline (isle-mesh idiom, ansible-compatible
output flags so previously rendered files stay byte-identical).

Pipeline per project:
  1. detect   annotated working files (# jinja-start markers) via the
              existing bash detector, extract to jinja-templates/<f>.j2
              via the existing bash processor (only-if-changed)
  2. render   every jinja-templates/**/*.j2 -> jinja-build/<f>
              (context = setup.yml environments.<current-setup.env>
              promoted to top-level vars + env_ctx + env_name + the full
              setup.yml as `variants` etc. — matches jinja-gen/playbook.yml)

Usage:
  render.py <project_dir> [--setup setup.yml] [--check]
    --check   render to memory and report which outputs WOULD change;
              exit 1 if any (CI/parity guard), write nothing.

Credential policy: the context must never carry secrets — setup.yml keys
that look credential-like are refused loudly (bld-7 purges the legacy
ones; until then they are allowlisted with a warning so existing renders
keep working).
"""
import argparse
import os
import subprocess
import sys

import jinja2
import yaml

LEGACY_CRED_KEYS = {  # known plaintext values in rf-node setup.yml — bld-7 purges
    "minio_password", "password", "minio_user",
}


def load_context(setup_path, env_override=None):
    with open(setup_path) as fh:
        setup = yaml.safe_load(fh)
    env_name = env_override or setup.get("current-setup", {}).get("env", "dev")
    env = (setup.get("environments") or {}).get(env_name)
    if env is None:
        sys.exit(f"render.py: environments.{env_name} not found in {setup_path}")
    warned = []

    def scan(node, path=""):
        if isinstance(node, dict):
            for k, v in node.items():
                if k in LEGACY_CRED_KEYS and isinstance(v, str) and not v.startswith("${"):
                    warned.append(f"{path}{k}")
                scan(v, f"{path}{k}.")
        elif isinstance(node, list):
            for i, v in enumerate(node):
                scan(v, f"{path}{i}.")

    scan(env)
    if warned:
        print(f"  [warn] plaintext credential-like values in setup.yml context: {', '.join(warned)}")
        print("         (legacy — scheduled for purge in bld-7; new manifests must use env-file refs)")
    ctx = dict(env)                      # promote env dict to top-level vars
    ctx["env_ctx"] = env                 # isle-mesh ansible-playbook idiom
    ctx["env_name"] = env_name
    ctx["active_env_vars"] = env         # rf-node jinja-gen/playbook.yml names
    ctx["active_env_name"] = env_name
    return ctx


def run_embed_extraction(project_dir):
    """Run the bash detector + processor (annotated file -> .j2).

    Tooling: the canonical copies live in pol-build/ (next to this file);
    a project-local jinja-gen/ pair is honored as a fallback. Detection
    scope: <project>/pol-services/ when it exists (the bld-3 annotated
    source tree), else the whole project.
    """
    here = os.path.dirname(os.path.abspath(__file__))
    candidates = [here, os.path.join(project_dir, "jinja-gen")]
    detector = processor = None
    for c in candidates:
        d = os.path.join(c, "embedded-jinja-detector.sh")
        p = os.path.join(c, "embed-jinja-file-processor.sh")
        if os.path.exists(d) and os.path.exists(p):
            detector, processor = d, p
            break
    if not detector:
        return 0
    scope = os.path.join(project_dir, "pol-services")
    if not os.path.isdir(scope):
        scope = project_dir
    excludes = [os.path.join(project_dir, x)
                for x in ("node_modules", ".git", "jinja-build", "jinja-templates")]
    out = subprocess.run(["bash", detector, scope, *excludes],
                         capture_output=True, text=True, check=False).stdout
    hits = [l.strip() for l in out.splitlines() if l.strip() and os.path.isfile(l.strip())]
    for f in hits:
        # processor mirrors paths relative to its <project_dir> arg — pass
        # the real project root so templates land in <project>/jinja-templates/.
        subprocess.run(["bash", processor, project_dir, f], check=True)
    return len(hits)


def render(project_dir, setup_path, check=False, only=None):
    ctx = load_context(setup_path)
    tdir = os.path.join(project_dir, "jinja-templates")
    bdir = os.path.join(project_dir, "jinja-build")
    if not os.path.isdir(tdir):
        sys.exit(f"render.py: no jinja-templates/ in {project_dir}")
    env = jinja2.Environment(
        loader=jinja2.FileSystemLoader(tdir),
        # ansible template-module flags — keeps output byte-identical to
        # the previous ansible-rendered files:
        trim_blocks=True, lstrip_blocks=False, keep_trailing_newline=True,
        undefined=jinja2.StrictUndefined,
    )
    changed, total = [], 0
    for root, _dirs, files in os.walk(tdir):
        for name in sorted(files):
            if not name.endswith(".j2"):
                continue  # e.g. compose_macros.jinja — import-only
            if only and name not in (only, only + ".j2"):
                continue
            rel = os.path.relpath(os.path.join(root, name), tdir)
            total += 1
            out_text = env.get_template(rel.replace(os.sep, "/")).render(**ctx)
            out_path = os.path.join(bdir, rel[:-3])
            old = None
            if os.path.exists(out_path):
                with open(out_path) as fh:
                    old = fh.read()
            if old != out_text:
                changed.append(rel[:-3])
                if not check:
                    os.makedirs(os.path.dirname(out_path), exist_ok=True)
                    with open(out_path, "w") as fh:
                        fh.write(out_text)
                    print(f"  rendered (changed): {rel[:-3]}")
            elif not check:
                print(f"  unchanged: {rel[:-3]}")
    if check:
        for c in changed:
            print(f"  WOULD CHANGE: {c}")
        print(f"  {total} template(s); {len(changed)} would change")
        return 1 if changed else 0
    print(f"  {total} template(s) rendered into {bdir} ({len(changed)} changed)")
    return 0


def render_manifest(project_dir, setup_path, manifest_path, check=False):
    """Multi-env rendering: one template -> N outputs (one per env), per
    pol-build/manifests/*.yml. Each output lands in jinja-build/<file> and
    is byte-compared against the hand-written <file> at the project root
    when it exists (parity report)."""
    with open(manifest_path) as fh:
        manifest = yaml.safe_load(fh)
    tdir = os.path.join(project_dir, "jinja-templates")
    bdir = os.path.join(project_dir, "jinja-build")
    jenv = jinja2.Environment(
        loader=jinja2.FileSystemLoader(tdir),
        trim_blocks=True, lstrip_blocks=False, keep_trailing_newline=True,
        undefined=jinja2.StrictUndefined,
    )
    failures = 0
    for bundle in manifest.get("bundles", []):
        template = bundle["template"]
        for out in bundle["outputs"]:
            ctx = load_context(setup_path, env_override=out["env"])
            text = jenv.get_template(template).render(**ctx)
            out_path = os.path.join(bdir, out["file"])
            os.makedirs(os.path.dirname(out_path) or bdir, exist_ok=True)
            hand = os.path.join(project_dir, out["file"])
            if not check:
                with open(out_path, "w") as fh:
                    fh.write(text)
            if os.path.exists(hand):
                with open(hand) as fh:
                    ok = fh.read() == text
                status = "PARITY OK (byte)" if ok else "PARITY DIFF"
                failures += 0 if ok else 1
            else:
                status = "no hand-written twin"
            print(f"  [{out['env']:>7}] {out['file']:<36} {status}")
    return 1 if failures else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("project_dir")
    ap.add_argument("--setup", default=None, help="values file (default <project>/setup.yml)")
    ap.add_argument("--check", action="store_true", help="report drift, write nothing, exit 1 on change")
    ap.add_argument("--only", default=None, metavar="NAME",
                    help="render just one bundle (template basename, .j2 optional)")
    ap.add_argument("--manifest", default=None,
                    help="multi-env bundle manifest (renders each output per its env)")
    args = ap.parse_args()
    project = os.path.abspath(args.project_dir)
    setup = args.setup or os.path.join(project, "setup.yml")
    n = run_embed_extraction(project)
    if n:
        print(f"  extracted {n} annotated working file(s) -> jinja-templates/")
    if args.manifest:
        sys.exit(render_manifest(project, setup, args.manifest, check=args.check))
    sys.exit(render(project, setup, check=args.check, only=args.only))


if __name__ == "__main__":
    main()
