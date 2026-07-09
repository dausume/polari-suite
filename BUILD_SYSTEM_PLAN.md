# Polari Build System Plan — jinja-script, swarm, proxies, `pol` CLI

_2026-07-08. Dustin's directive: revise the builds around the ISLE-MESH
jinja-script approach (NOT the current rf-node jinja-templates approach,
which is rejected); per-service files; meticulously notated conditional
variations; output modes for both the existing docker-compose files AND
docker-swarm deployments; everything fully auto-deployable + secure via
shell-based deployments automating ssh + cert interlinking to the nginx
proxy; auto-generate the nginx proxies and their swarm equivalents; and a
`pol *` CLI (modeled on the isle-mesh cli-tool, thoroughly documented) to
bring it all together. This round focuses on the build; scorecard +
aquaponics work is parked. Guidepost toward isle-mesh-apps later._

## 0. The two reference systems (recon reports, 2026-07-08)

### 0a. Isle-mesh "jinja-script" (the model to follow)
On isle-core `/home/detts/Isle-Mesh/embed-jinja/`. The ANNOTATED WORKING
FILE is the source of truth — a normal compose/py/env/conf file carries
Jinja logic inside its own native comments; tooling extracts it into a
`.j2`, then renders finalized files into a mirror tree:

- Markers per comment-schema (case-insensitive, `jinja-start`/`start-jinja`):
  - hash files (`.yml .sh .py .env .conf Dockerfile`): `# jinja-start` …
    `# jinja-end`; logic lines `# {% ... %}`; `## ` lines = author-only
    comments, STRIPPED from the template.
  - slash files (`.js .ts .go`…): `// jinja-start` … `// jinja-end`.
  - tag files (`.html .xml`…): `<!-- jinja-start -->` … `<!-- jinja-end -->`.
- `embedded-jinja-detector.sh <project> [excludes...]` finds annotated files.
- `embed-jinja-file-processor.sh <project> <file>` strips ONE leading `# `
  (indent preserved) inside blocks, drops `##` lines, writes
  `<project>/jinja-templates/<relpath>.j2` only-if-changed (`cmp -s`).
- Ansible (`ansible-playbook.yml` → `per_project.yml`) selects
  `current-setup.env` from `setup.yml`, promotes `environments.<env>` to
  template context (`env_ctx`, `env_name`, per-key vars), renders every
  `jinja-templates/**/*.j2` → `jinja-build/<same path minus .j2>`.
- `clear-jinja-build.sh` resets both mirror trees; `ansible-ready.env`
  (`IS_ANSIBLE_DONE`) is the completion barrier; `docker-compose.auto.yml`
  chains render → `docker compose -f jinja-build/docker-compose.yml up`.
- rf-node ALREADY has a port of the detector/processor + an Ansible
  playbook under `polari-rf-node/jinja-gen/` — but no source file carries
  markers yet (the authored per-file `.j2`s under `jinja-templates/` are
  the rejected approach). The machinery is reusable; the authoring model
  flips to annotated working files.

Conditional-variation notation to adopt (verbatim isle-mesh idioms):
```yaml
# Jinja-Start
## <author note — stripped from template>
# {% if expose_backend_port_on_localhost %}          ← variation: dev-localhost
#       - "127.0.0.1:{{ backend_port }}:{{ backend_port }}"
# {% else %}                                          ← variation: lan/prod
#       - "{{ backend_port }}:{{ backend_port }}"
# {% endif %}
# Jinja-End
```
POLARI EXTENSION (the "meticulous notation" requirement): every
conditional block gets a `## variation:` author-comment line naming which
variation(s) the branch belongs to, e.g. `## variation: staging-nip |
swarm` — stripped from the rendered template, permanent in the source.

### 0b. Isle-mesh nginx/proxy generation (segments + assembly)
- `isle-agent/templates/nginx-mesh-proxy.conf.j2` `{% extends
  "segments/base.conf.j2" %}`; per-concern segments (`upstream`,
  `security-headers`, `server-http-base`, `server-https-subdomain-simple`,
  `server-https-subdomain-mtls`); per-service loop chooses mTLS vs simple
  by `service.mtls`; segment dirs per variation (`segments/local/`,
  `segments/isle/`); `{% extends %}` + named blocks for variation
  inheritance (`isle` extends `localhost-mdns`).
- Values extracted FROM the compose file itself (`parse-docker-compose.sh`,
  yq → JSON: name/port/`mesh.subdomain`/`mesh.mtls` labels).
- Validation: `merge-configs.sh` runs `nginx -t` in a throwaway
  `nginx:alpine` per fragment + on the merged whole; `registry.json`
  prevents domain collisions.
- Cert interlink: `generate_mesh_ssl.sh` emits base cert + per-subdomain
  re-encryption certs whose FILENAMES are what the mTLS segment references
  (`proxy_ssl_trusted_certificate /ssl/certs/{{ subdomain_cert }}`).
- ssh deploy: `isle-cli/scripts/join.sh` pattern (remote agent bring-up
  over ssh + registration).

### 0c. Isle-mesh CLI (model for `pol`)
- Tier 1: Node dispatcher `index.js`, installed via package.json
  `"bin"` — ONE declarative command table `{name: {script, desc,
  aliases?, docker?, deprecated?}}` = single source of truth for routing,
  aliases, help, validation. Uniform dispatch `bash scripts/<script>
  <sub> <args...>` with `stdio: inherit` + exit-code propagation;
  `namespacelessCommands` guard list; per-command precondition hooks
  (docker group check); `validateScripts()` chmod +x on the fly.
- Tier 2: per-namespace bash sub-dispatchers (`app.sh` `case → exec bash
  leaf.sh`), each with boxed colorized `show_help()`.
- Install: `shells/cli-paths.sh` = single source of truth
  (`/usr/local/bin/<cmd>` symlink; `link/unlink` helpers; `_priv` =
  sudo -n only when target not user-writable); dev route symlinks the
  live checkout; package route respects an existing dev install.
- Docs: table `desc` feeds help; every script has `show_help()`; markdown
  INDEX.md + architecture/extension/quick-ref docs.
- Improvement to make (agent's note): shared `lib/log.sh` instead of
  per-script color/log duplication.

### 0d. Current Polari state (what exists to fold in)
- rf-node `jinja-gen/` (Ansible render + detector/processor port +
  `check-parity.sh` = semantic `docker compose config` diff harness, 10
  variants incl. dbcombo-as-overlay + remote-worker `--profile dask`) and
  `setup.yml` (variants model; has PLAINTEXT creds — must be purged).
- `compose-gen/node-model.yml` = inert stub (generator never written) but
  its DRY ideas (defaults/presets, serviceOverrides, parity_with) inform
  the service model. Supersede + delete once the new system covers it.
- 13 hand-written compose files: 10 rf-node + 3 suite-root (suite trio is
  NOT covered by any generator today).
- nginx: `sed`-substituted `.template` files via staging/prod-setup.sh —
  to be replaced by segment/assembly jinja generation.
- Security substrate (committed 2026-07-08, suite `dev-build-security` +
  rf-node `dev-jinja-family`): ALL credentials setup-generated or
  knob-supplied; skip-if-exists generators; `pol-file-store` + suite `.env`
  generators; keycloak DB passwords via env override (conf scrubbed);
  fresh-pull one-script bootstrap VERIFIED. The build system builds ON
  this: templates must never re-introduce inline credentials.
- polari-cli repo (github.com/dausume/polari-cli): near-empty Node CLI
  (index.js + package.json, `pol` prefix already chosen). This is the home
  of the new CLI.
- Swarm: zero existing support anywhere (greenfield).

## 1. Target architecture

```
polari-suite/
  pol-services/                    ← ANNOTATED per-service working files
    prf-backend/service.yml        (source of truth; carries jinja-script
    prf-frontend/service.yml        comments with ## variation: notes)
    prf-keycloak/service.yml
    prf-mariadb/service.yml
    prf-file-store/service.yml
    prf-proxy/service.yml
    pol-mariadb/service.yml  pol-keycloak/service.yml
    pol-file-store/service.yml  pol-proxy/service.yml
    psc-backend/service.yml  psc-frontend/service.yml  psc-redis/service.yml
    _fragments/                    (shared blocks: healthchecks, deploy
                                    presets nano..xlarge, env wiring)
  pol-proxy-gen/                   ← nginx segment/assembly templates
    segments/{base,upstream,security-headers,server-*}.conf.j2
    segments/swarm/…               (swarm-equivalent segment variations)
    templates/nginx-node-proxy.conf.j2
  pol-build/                       ← generator pipeline (python3 + jinja2,
    detect.sh  process.sh          bash detector/processor ported from
    render.py  assemble.py         isle-mesh; render assembles service
    parity.sh                      files per variant manifest)
    manifests/…                    (variant → service-set + overrides;
                                    the successor of setup.yml variants,
                                    NO credentials — env files only)
  jinja-templates/ + jinja-build/  ← generated mirror trees (gitignored)
polari-cli/  (the `pol` command — separate repo)
  index.js         (declarative command table, isle-mesh idiom)
  scripts/*.sh     (tier-2 namespace dispatchers + leaves)
  scripts/lib/log.sh (shared colors/logging — the improvement)
  shells/cli-paths.sh + install-cli.sh
  docs/ INDEX.md CLI-ARCHITECTURE.md EXTENSION-GUIDE.md QUICK-REFERENCE.md
```

Variation axes (every conditional names its axis+value in `## variation:`):
- `env`: dev | staging-nip | prod | stateless | fullstack-test
- `topology`: single (compose) | swarm (stack)
- `role`: node (rf standalone) | suite (combined) | twin-b | dask |
  msci-engines | remote-worker
Output = manifest selects (env, topology, role) → assembled compose file
or swarm stack file, byte-parity-checked against the 13 hand-written
files for the `single` topology (then the hand-written files become
generated artifacts and are retired from hand maintenance).

Swarm mode differences (encoded as `{% if topology == 'swarm' %}` blocks):
- `deploy:` placement/replicas/restart_policy (presets from _fragments)
- overlay networks instead of bridge; `docker stack deploy` entry
- credentials via `docker secret` (from the SAME generated env files —
  `pol build secrets sync` creates/rotates secrets from them)
- proxy: swarm-mode nginx service w/ dnsrr upstreams (segment variation
  dir `segments/swarm/`), later Traefik evaluation — NOT this round.

Deploy automation (`pol deploy …`): shell over ssh in the isle-mesh
join.sh style — push env-file-less repo (git pull on target), run
setup scripts remotely (they self-generate creds), distribute CA-signed
certs (ca/ toolkit already exists in both repos), interlink cert paths
into generated proxy configs, `docker compose up` / `docker stack deploy`,
verify endpoints. Targets configured in `pol-build/manifests/nodes.yml`
(hosts, ssh aliases, roles) — no secrets in it.

## 2. `pol` CLI command surface (bld-1 BUILT 2026-07-08)

Orchestration MODES are first-class namespaces (Dustin's directive):
`pol compose` = the existing compose family; `pol swarm` = being defined
now as the STAND-IN for isle-mesh until its capabilities land; `pol isle`
= the future real thing (placeholder that refuses honestly). Any service
kind is independently deployable (engines especially).

```
pol help                          boxed overview (auto from command table)
pol security setup|node-setup|status|cleanup    self-generating substrate
pol compose <role> <action>       roles: suite|node|engines|dask|twin
                                  actions: up|down|build|ps|logs
                                  single services: pol compose node up backend
pol node / pol suite …            shortcuts for compose's two main roles
pol swarm init|status|join-token  WORKING today (single-node swarm ready)
pol swarm render|secrets|deploy|rm|ps    refuse until bld-5
pol isle …                        refuses; names swarm as the stand-in
pol build render|parity|detect|clean     wraps jinja-gen now; bld-2+ target
pol registry list|show|interconnects|check      service accountability
pol cert setup|issue|renew|verify|walkthrough   ca/ toolkit
```
Conventions locked from isle-mesh: declarative table in index.js; tier-2
bash dispatchers w/ show_help(); shared lib/log.sh; cli-paths.sh single
symlink (/usr/local/bin/pol, ~/.local/bin fallback); dev install =
symlink live checkout; namespaceless-verb guard; docker-precondition hook.

## 2b. Service registry (accountability — BUILT 2026-07-08)

`pol-build/registry/services.yml` catalogs EVERY service kind (19),
its config surface (env files, generated artifacts, knobs), its
variation notes, and the `interconnects:` section — the auto-generated
artifacts that wire prf/psc instances to each other and to CHILD
instances (runtime-config JSONs, the twin peer-token + polari-link +
PeerAgreement admission, keycloak client secrets re-PATCHed at boot,
db/minio credentials, generated nginx configs, and the scr-7 PSC→PRF
scoring-API seam, designed-not-built). `pol registry check` diffs
compose-declared services against the registry (19/19 green); the bld-3
per-service files must stay 1:1 with registry entries. Precedent:
isle-mesh registry.json.

## 3. Phases (branch per confirmed phase)

- **bld-1 `pol` CLI skeleton** — polari-cli repo: dispatcher + table,
  lib/log.sh, cli-paths.sh/install, `pol security|node|suite` wrapping the
  EXISTING scripts (immediately useful), docs skeleton (INDEX,
  ARCHITECTURE, EXTENSION, QUICK-REFERENCE), per-script help. ✅ then wire
  `pol build` as later phases land.
- **bld-2 engine port** — pol-build/: detector+processor (from rf-node
  jinja-gen, generalized to suite root), python renderer (jinja2, replaces
  ansible dependency; keep ansible-compat behavior: env promotion,
  only-if-changed writes), manifests schema (NO creds), `pol build render`.
- **bld-3 per-service annotation** — author pol-services/*/service.yml as
  annotated working files covering the 13 compose targets; assemble.py
  composes them per manifest; parity harness green for all 13 (extend
  rf-node check-parity.sh style to suite trio).
- **bld-4 proxy generation** — pol-proxy-gen segments/assembly from the
  isle-mesh nginx model, replacing the sed templates; values parsed from
  the rendered compose (labels `polari.subdomain`, `polari.tls`);
  containerized `nginx -t` validation; cert-path interlink with ca/
  toolkit filenames.
- **bld-5 swarm output** — topology=swarm blocks in service files, secrets
  sync from generated env files, overlay networks, `pol swarm deploy`
  against a single-node swarm on staging A for validation.
- **bld-6 ssh deploy automation** — nodes.yml + `pol deploy` (join.sh
  idiom): remote bootstrap on isle-core/lightweight as test targets.
- **bld-7 retirement** — delete rejected jinja-templates/*.j2 authored
  variants, compose-gen stub, sed nginx path; hand-written compose files
  become generated (or gain a "GENERATED — edit pol-services/" banner);
  purge plaintext creds from setup.yml (values move to env-file
  references).

## 4. Standards (non-negotiable, from standing memory)
- knobs-and-suggestions: every build capability = explicit knob + honest
  refusal/suggestion when preconditions missing (e.g. `pol swarm deploy`
  refuses with the exact `docker swarm init` needed).
- No credentials in templates, manifests, or rendered files — only
  env_file references to setup-generated files (2026-07-08 substrate).
- `## variation:` notation on EVERY conditional branch in annotated files.
- Parity before retirement: a hand-written file is only retired after its
  generated twin passes semantic parity.
- File-size discipline: one service per file, one segment per concern,
  leaf scripts small; no thousand-line monoliths.
```
