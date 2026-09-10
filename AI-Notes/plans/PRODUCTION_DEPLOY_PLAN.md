# Production deployments on a small VM (prd arc): swarm as production, compose authored swarm-first, one lean profile, smaller images

**Date:** 2026-09-04 · **Status: ASSESSMENT + PLAN (prd-0). No code changed.
His rulings the same morning: "we actually only need swarm and dev" and
"we do not need to get rid of compose and we still use them occasionally
but any compose builds should be built around preparing to transition
to swarm" — so SWARM is THE production route, compose is the authoring
form that renders into the swarm stack (which is what `pol swarm render`
already does), and the deb is NOT a production deployer (it stays the
desktop / isle route). §2 and §5 are written to that.**
Grounded in a three-way survey of the tree on 2026-09-04 (file:line cites
are from that tree) and live measurements on pol-core. His framing:
"we serve the official polari app using a normal user install on
ubuntu … the standard route a user would take by installing a deb …
optimized as much as possible to fit onto the small vm on digital
ocean"; and "compose, deb, and swarm routes — all of them should be
viable." Supersedes the sizing assumption of POLARI_SYSTEMS_ORG_PLAN
pub-0 (a 4 vCPU / 8 GB droplet at $48/mo).

## 0. The answer in one paragraph

Today no route can put Polari on a small DigitalOcean droplet from a
fresh Ubuntu: nothing can obtain the images without building them
locally (nothing is published; `registry.isle:5000` is mesh-only), the
`prod`/staging profiles carry Keycloak + MariaDB + MinIO (≈ 750 MB of
RAM before Polari itself), the backend image is 951 MB with a 698 MB
Python venv of which ~480 MB is the scientific stack that most module
sets never import, and the backend serves from the stdlib dev server.
(The deb route additionally needs KVM for the router VM and a JDK for
the shell — which is why it stays a desktop/isle route, not a server
one.) Frontend builds
are ALREADY minified (AOT, terser, hashed — 23 MB on disk, 1.1 MB gzip
for the main bundle); the wins there are lazy-loading and edge
compression, not "turning minification on". The backend cannot be
minified in the JS sense; it shrinks by shipping less (a core
requirements set, no build residue, engines in their own images) and
by importing less at boot. The plan: ONE lean production profile
(sqlite, optional Keycloak, chosen module set, bounded WSGI server)
authored as a compose file and deployed as a swarm stack — compose is
how it is written and tried on a laptop, swarm is how it runs in
production — plus published images so the droplet never builds, and a
one-command bootstrap (`pol swarm bootstrap`) for a fresh Ubuntu box.
Target: the $12/mo 2 GB droplet with Keycloak, the $6/mo 1 GB droplet
without it.

## 1. What exists today (verified)

### 1.1 The three routes

| Route | Verb | What it deploys | Cites |
|---|---|---|---|
| **compose** | `pol node up --env dev\|test\|staging\|prod\|stateless` | `docker-compose.prod.yml`: mariadb (512M), keycloak (1024M, `-Xmx768m`), proxy (64M), minio file-store (256M), frontend (64M), backend (**384M — stale**; staging-nip carries 1536M after the 2026-09-02 OOM) | `polari-cli/scripts/node.sh:42-49`, `polari-rf-node/docker-compose.prod.yml:72-261`, `docker-compose.staging-nip.yml:327-330` |
| **deb** | `./build-polari-isle-deb.sh` → `polari-complete`/`polari-isle` → `sudo isle core-install` (or the store's "Create my own isle") | the ISLE stack: OpenWrt router VM (libvirt/KVM), `isle-vlan-agent` nginx, `prf-isle-backend` (sqlite, `POLARI_MODULES=islemesh`, lazy boot, **no Keycloak, no MinIO**, `mem_limit 2g`), `prf-isle-frontend` (128m); desktop shell = jpackage JavaFX (`polari-shell-core`, needs JDK 17+) | `build-polari-isle-deb.sh:1-250`, `Isle-Mesh/polari-isle/docker-compose.yml:9-32`, `Isle-Mesh/isle-cli/scripts/core-install.sh:43-140`, `GETTING_STARTED_DEV.md:17-24` |
| **swarm** | `pol swarm deploy node` (dev since 2026-08-26) | the staging-nip stack as a swarm service set; `POLARI_MODULES` derived from ModuleAssignment rows | `polari-cli/scripts/swarm.sh`, memory `dev-swarm-prod-app-route` |

No deb starts a compose stack or installs a systemd unit; the store deb
only seeds trust and prints the next command. **Image supply is the
shared gap**: `Isle-Mesh/polari-isle/docker-compose.yml:9,32` wants
`prf-backend:staging` / `prf-frontend:staging`, and
`isle-polari-deploy.sh:52-59` pulls only from `registry.isle:5000`; the
compose and swarm routes build locally. Nothing is published to any
public registry or GitHub release. The public site / apt repo
(POLARI_SYSTEMS_ORG_PLAN pub-3..5) is planning only.

### 1.2 Sizes (measured 2026-09-04)

| Artifact | Size | What dominates |
|---|---|---|
| `prf-backend:staging` | **951 MB** | venv 674 MB layer (site-packages 698 MB: scipy 156, pandas 75, sympy 72, tippecanoe 65, numpy 68, matplotlib+fontTools+PIL ~85 (pulled by **ase**), ase 25, grpc 17, dask+distributed 20, pip+setuptools 17); `apk add … ngspice ffmpeg` 184 MB; source 25 MB; **13 MB freetype SOURCE tree copied into the runtime** (`polari-framework/Dockerfile:98`) |
| `prf-frontend:staging` | 92.6 MB | nginx:alpine ~70 + dist 23 MB (10.4 MB JS; **9.5 MB WebXR `.glb` controller models** shipped eagerly, `angular.json:26-31`) |
| `prf-proxy:staging` | 162 MB | `nginx:latest` (Debian) — alpine would be ~70 |
| engines (`prf-msci-engines`, `prf-cnt-engines`) | 2.2–2.3 GB each | not part of a small-VM deployment |

Frontend build facts: `Dockerfile.prod:26` runs `ng build
--configuration=production` → optimization/AOT/buildOptimizer on,
sourcemaps off, hashed names (`angular.json:62-82`, CLI defaults). So
**production builds are minified already.** What is not tight: the
initial budget is 5 MB warn / 7 MB error (`angular.json:66-67`);
`app.module.ts` declares the whole no-code editor + dashboards eagerly
so `main.js` is 4.98 MB raw / 1.13 MB gzip although 61 of 76 routes are
lazy; `three` (27 static imports) and `d3` (22) are never
dynamic-imported; katex/video.js/maplibre CSS and the Material theme are
eager; `index.html` is 68 KB of inlined critical CSS re-sent every
navigation; the edge proxy has **no gzip, no brotli, no HTTP/2**
(`prf-proxy/nginx.prod.conf` — zero hits), the frontend nginx gzips at
level 1 without `gzip_static`; the builder is webpack, not esbuild.

### 1.3 Runtime footprint (live, pol-core, 21 modules)

| Service | RSS | Limit |
|---|---|---|
| backend | **744 MiB** (196 MiB with the pub-0 demo module set; climbs ~170 MB per page sweep and never returns — `TESTING_OWED.md:1018`) | 1536M |
| keycloak | 575 MiB | 1024M |
| mariadb | 86 MiB | 512M |
| minio | 73 MiB | 256M |
| proxy + frontend | 14 MiB | 64M each |

Two structural causes: the backend serves from **`wsgiref.simple_server`
with `ThreadingMixIn`** — one unbounded thread per request, no worker
recycling (`initLocalhostPolariServer.py:21-81`); and `POLARI_MODULES`
gates class REGISTRATION only — every module package on disk is still
imported, so scipy/pandas/sympy RSS is paid regardless of the module
set (`polariApiServer/module_gating.py:18-22,78`,
`moduleService/module_loading.py:15-17`). Boot on pol-core: the CRUDE
registration cycle ran 61 × 16 s ≈ 16 min before seeding (§12/§13 of
the testing ledger).

### 1.4 The droplet menu (DigitalOcean Basic, 2026 list prices)

| Plan | RAM | vCPU | Disk | Fits |
|---|---|---|---|---|
| $4 | 512 MB | 1 | 10 GB | no (image alone ~1 GB, backend RSS > RAM) |
| **$6** | 1 GB | 1 | 25 GB | lean profile WITHOUT Keycloak, small module set, swap on |
| **$12** | 2 GB | 1 | 50 GB | lean profile WITH Keycloak — the default target |
| $18 | 2 GB | 2 | 60 GB | same, faster boot |
| $24 | 4 GB | 2 | 80 GB | the full prod profile as it is today |

Nested virtualization is not available on Basic droplets: the OpenWrt
router VM cannot run there. A droplet is therefore a single-device isle
WITHOUT a router (POLARI_SYSTEMS_ORG_PLAN decision 5 already says
"single-device isle"; this makes the no-router mode a hard requirement).

## 2. Shape — one lean profile, authored in compose, deployed by swarm

```
   compose (authoring + dev)                 swarm (production + dev cluster)
   docker-compose.lean.yml  ──pol swarm render──▶  .generated/stack-lean.yml
   pol node up --env lean   (laptop try-out)      pol swarm deploy lean  (1-node droplet
                                                  or the 3-node home swarm)
                       ┌────────── the LEAN PROFILE (one file) ───────────┐
                       │ images: prf-backend-core (+ -full), prf-frontend,  │
                       │         prf-proxy — PUBLISHED, versioned tags      │
                       │ module set: POLARI_MODULES from ModuleAssignment   │
                       │             rows (swarm) or the env (compose)      │
                       │ data: sqlite (parity proven); Keycloak + MinIO     │
                       │       are KNOBS (profiles / stack sections)        │
                       │ server: bounded WSGI workers; a memory budget per  │
                       │         service written as deploy.resources        │
                       │ edge: proxy with gzip+brotli+http2, LE cert        │
                       └────────────────────────────────────────────────────┘
```

- **Swarm is production.** `pol swarm deploy <role>` already renders the
  compose bundle into a stack file and derives `POLARI_MODULES` from
  the topology rows; the lean profile becomes a fourth role next to
  `node | suite | engines`. On a droplet: `docker swarm init` (one
  node), `pol swarm deploy lean`; at home: the same file on the 3-node
  swarm. Everything swarm cannot honour from compose (`build:`,
  `mem_limit`, `depends_on` conditions, `profiles`) is written the
  swarm way from the start (`deploy.resources`, `deploy.placement`,
  healthchecks + restart policies, secrets/configs) so the compose file
  IS the swarm file with no translation debt — that is what "compose
  builds prepared to transition to swarm" means concretely.
- **Compose stays** for authoring, laptop try-outs and the occasional
  single-host run: `pol node up --env lean` runs the same file with
  `docker compose` (compose ignores `deploy.placement`, honours
  `deploy.resources.limits` since v2). Rule: no compose-only construct
  in any file that has a swarm role; `pol build parity` gains a check
  for it (build-only keys, `mem_limit`, `profiles`, `depends_on`
  conditions).
- **The deb is not a server route.** `polari-complete` / `polari-isle`
  / the store + shell remain the desktop and isle installers. For a
  fresh Ubuntu server the entry point is a bootstrap verb / script
  (`pol swarm bootstrap --env lean --domain <d>`: installs docker if
  absent, `swarm init`, pulls the pinned images, writes the env,
  deploys the stack) — shippable as a tiny `polari-bootstrap` deb later
  if a package is wanted, but it is a courtesy wrapper around swarm,
  not a third deployer.

Shared and owned here: the image diet (§3), the runtime diet (§4), the
release script (build → tag → push → manifest), the parity check, and
the measurement harness that prints the memory budget per module set.

## 2b. The core-only server (his ruling 2026-09-04: "not all of the code should need to be on the production server … pull data dynamically and build the modules and hold them only temporarily to give them out when requested")

The production image carries the CORE and the MODULE SYSTEM only — no
`modules/` directory baked in. Modules arrive on demand, live for a
while, and go away; artifacts are built when asked for and expire.
Most of the machinery already exists (DYNAMIC_MODULES_PLAN, MODULE_
PROJECTS_PLAN, DOWNLOADS_PAGE_PLAN) — this section names what is
built, what the server must add, and the rule that makes the small VM
possible.

| Need | Exists today | Gap for production |
|---|---|---|
| Fetch a module's CODE from its own repo when it is absent at boot | ✅ dyn-4 `POST /modules/{m}/fetch-admit` — absent module cloned from its `polari-module-<m>` repo (ModuleSourceConfig row) and admitted live in 1.8 s; `pol modules get` | the image must ship WITHOUT `modules/` (Dockerfile `COPY . /app` copies it today) and the registry's `repo` must be set for every module (all 40 have repos; `vpn`/`household`/`mealoptions` still `''`) |
| Admit / put away at runtime | ✅ dyn-2 admit 1.5 s, dyn-3 put-away 0.025 s (rows freed, tables kept, 410 Gone with bring-back hint), dyn-2b rows are the authority | an **idle policy**: put away a module nobody has requested for N minutes, keep at most K admitted (LRU); admission on first request instead of on boot — the "hold temporarily" half |
| Python dependencies a fetched module needs | ⚠ none — the full image has everything preinstalled; a core image has falcon/crypto/DB/numpy only | per-module extras from `module_requirements.py`'s closure installed into the venv at admission (`pip install` from wheels, cached on the data volume) OR — the production answer — modules that need the scientific stack are served as **exhibit variants** (pub-2: display samples + data, no engines) so the core image never installs scipy on the droplet |
| Module DATA pulled dynamically | ✅ `modules/<pkg>/initialData/*.json` + `GET /modules/{m}/initial-data` + `POST /modules/seed` (install from GitHub OR another instance's API); `POST /modules/export` (privacy-stripped) | the exhibit export→seed pass per module (pub-2), and a TTL on data pulled for a module that was put away |
| Build artifacts on request, hold temporarily | ✅ dl-4 on-demand app/module deb generation, content-hash version as the TTL cache key, `POLARI_APP_DEB_TTL` / `POLARI_APP_DEB_PREBUILD` knobs, offline chunker generating piece by piece | a disk cap next to the TTL (the droplet has 25–50 GB; images alone are ~1 GB), and the bundle deb built from FETCHED module trees rather than the checkout |
| The smallest footprint that still boots | ✅ dyn-5 `baseline_profile`: floor = polariapps + appstore + islemesh | measure the floor on the core image (prd-1) — that number IS the $6-droplet budget |

Rules that follow:
- **Boot = the floor.** The server boots with the baseline set only
  (dyn-5), so the 61-cycle registration sweep becomes a 3-module boot
  (~35 s on the isle lean stack today).
- **Request = admission.** A request for a module's pages, API or deb
  triggers fetch-admit (code + data) if it is absent; the module stays
  admitted while used and is put away when idle (K/N knobs, defaults
  K=4, N=30 min for the $12 tier). Put-away keeps the DB tables, so a
  re-admit restores rows without a refetch of data.
- **Artifacts expire.** Debs and bundles are built on demand into a
  TTL + disk-capped cache (the dl-4 design), never a pre-built pool by
  default.
- **Heavy code never lands on the droplet.** Modules whose closure
  needs the scientific stack are only ever admitted as exhibit
  variants there; the full variants stay for owned hardware. The
  registry says which (an `exhibit_only_on: lean` flag next to
  `requires`).
- **The core image is the same for every route.** Compose, swarm and
  the isle route all pull `prf-backend-core`; only the module set and
  the knobs differ.

## 2c. What the production server IS (his ruling #4, 2026-09-04): a distribution point, not a demo

"I do not think we need the demos of functionality on the production
anyways, just a way and place where people can feasibly download
working deb files and perform installs, which in theory should already
exist on the main route." So the public instance runs the **floor set
only** — `polariapps` (the app definitions), `appstore` (the downloads
page, the deb/bundle builders, the offline chunker) and `islemesh` (the
catalog) — the exact dyn-5 baseline. No exhibit variants, no science
modules, no engines, no Keycloak needed for browsing and downloading
(D2 default flips to OFF for this server). That is the $6 droplet.

What "download working debs and install" needs, and where each piece
stands:

| Piece | Exists (main route) | Gap |
|---|---|---|
| The downloads page + install-order rendering (Option A bundle / Option B members) | ✅ dl-5 `appstore/downloads_page.py`, `/downloads`, `/downloads/offline`, `/downloads/plan` | served from a locally staged `POLARI_DOWNLOADS_DIR` on a running instance — nothing public yet (pub-1/pub-3/pub-5) |
| Per-app / per-module debs built ON DEMAND, TTL-cached | ✅ dl-4 `app_deb_builder.py`, content-hash version = cache key, `POLARI_APP_DEB_TTL`, prebuild pool off by default | the builder reads `modules/<m>` from the CHECKOUT; on a core-only server it must **fetch the module repo into a temp tree** (the module_fetcher clone, dyn-4's first half, no admit), build, cache, delete the tree — "pull dynamically, build, hold temporarily, give out when requested" verbatim |
| The platform debs (`polari-complete`, `polari-isle`, `isle-mesh-cli`, `polari-shell-core` 55 MB JavaFX, `isle-app-store`) | ✅ built from code by `build-polari-isle-deb.sh` / `build-polari-complete-deb.sh` — proven on a fresh box 2026-08-19 | they need the whole suite checkout, docker builds and a JDK with jpackage — NOT buildable on the droplet. They are **release artifacts**: built at home by the release script (prd-5), uploaded to the server's pool (the prebuild pool option, ON for these five only), listed with version + date (house style) |
| `apt install` from a public repo | ✅ the signed flat-repo publisher exists for `apt.isle` (`isle apt-repo publish`) | port to `apt.polari-systems.org` (pub-4) — the same script pointed at the droplet's pool; a public signing key in the site's trust page |
| An installed deb that can RUN polari | ⚠ the isle stack pulls `prf-backend:staging` from `registry.isle:5000` only; the compose/swarm routes build | **published images** (prd-5, D3) — without them a downloaded deb installs a launcher that cannot start polari on a box that has never built it. This is the one gap that makes today's debs "working in theory" only |
| Offline media (USB/DVD chunks) | ✅ dl-5 chunker + `/downloads/offline` | the chunk sets need the image tarballs — same prd-5 output |

Consequences for the phases: prd-1 measures the floor set only (the
demo set is dropped); prd-3b's "hold temporarily" applies to fetched
module TREES for deb builds (and to any module admitted for a page),
not to demo data; pub-2 (exhibit variants) is **not needed for
production** and stays parked; the release script (prd-5) is the
centre of the arc because it produces BOTH the images the installed
debs pull AND the platform debs the server hands out.

## 3. Image diet (what "minified builds" means for us)

**Frontend (already minified — make it lazy and compressed):**
- f1 lazy-load the eager declarations of `app.module.ts` (the no-code
  editor, dashboards, matrices) behind their routes; dynamic-import
  `three` and `d3`; move katex/video.js/maplibre CSS next to their
  consumers. Expected: main.js 5 MB → ≤ 1.5 MB raw.
- f2 WebXR controller `.glb` models (9.5 MB) served on demand (fetch on
  first XR session) or from a separate `assets-xr` path excluded from
  the default image.
- f3 edge compression: `gzip_static` + brotli (`ngx_brotli` or
  pre-compressed `.br` at build time) + `http2` in `prf-proxy`; gzip
  level 6 in the frontend nginx; drop the 67 KB inlined critical CSS
  from `index.html` (Beasties knob) or accept it — measure.
- f4 tighten budgets (initial 2 MB warn / 2.5 MB error, per-chunk
  budgets) so regressions fail the build; migrate to the esbuild
  `application` builder (faster builds, smaller output).
- f5 `prf-proxy` on `nginx:alpine` (162 → ~70 MB).

**Backend (cannot be minified — ship less, import less):**
- b1 Dockerfile hygiene: drop `COPY --from=builder /build /build`
  (13 MB of freetype source), remove pip/setuptools from the runtime
  venv (17 MB), extend `.dockerignore` (selftests, `data/`,
  `run_tests.py`, docs) — ~35 MB, zero risk.
- b2 split `requirements.txt` into `requirements-core.txt` (falcon,
  cryptography, PyJWT, PyMySQL, redis, minio, numpy) and per-feature
  extras (`sci`: scipy/pandas/matplotlib; `equations`: sympy; `dask`;
  `materials`: scikit-fem/ase; `geo`: tippecanoe; `grpc`). Two images:
  **`prf-backend-core`** — core deps AND NO `modules/` DIRECTORY (§2b;
  the module system fetches what a request needs) — and
  **`prf-backend-full`** (today's content minus b1, for owned hardware
  and the engines). The registry's `module_requirements.py` already
  knows the import→distribution closure per module; it becomes the
  source of truth for which extras a module set needs, and boot refuses
  honestly when a chosen module's extra is absent (the existing
  "module not downloaded" message shape).
- b3 `ngspice` and `ffmpeg` out of the base image (184 MB): they are
  engine probes; the engines images and a `prf-backend-full` variant
  keep them.
- b4 (optional) `python -OO` is NOT safe here — the framework reads
  docstrings for API descriptions; `.pyc`-only shipping saves little.
  Skip.

## 4. Runtime diet (what makes the small VM survive)

- r1 **a real WSGI server**: gunicorn (or waitress) with a bounded
  worker/thread count, `--max-requests` recycling so the ~170 MB
  non-returning RSS climb is reclaimed, and a request timeout. The
  Falcon app object is already what `wsgiref` serves; TLS stays at the
  proxy (the in-process HTTPS listener at
  `initLocalhostPolariServer.py:212` becomes a dev-only knob).
- r2 **make `POLARI_MODULES` gate imports**: `module_loading` treats a
  module that is on disk but not in the knob as not-downloaded for the
  guarded import blocks, so the scientific stack is never imported for
  a module set that does not need it. Expected: the 61 × 16 s
  registration sweep collapses to the enabled set (the lean stack on
  the isle boots in ~35 s with one module — `POLARI_SYSTEMS_ORG_PLAN
  :262-285`).
- r3 **sqlite by default** for Polari data (parity proven; MariaDB only
  when Keycloak is on, as Keycloak's DB — or Keycloak on its dev-file
  store for the $12 tier; measure).
- r4 **Keycloak as a knob**: the isle lean stack already runs without
  it; the lean profile exposes `POLARI_AUTH=keycloak|local` and the
  frontend's OIDC config follows (the runtime-config.json path).
- r5 memory budget as data: a `SizingProfile` row per module set
  (measured RSS at boot / after a page sweep / after the selftests) so
  the downloads page and `pol node up --env lean` can say "this set
  needs 2 GB" before deploying — the "derive or cite" rule applied to
  RAM.

## 5. Phases

- **prd-0 — this assessment.** ✅
- **prd-1 — measure.** A harness (`pol node sizing <module-set>`) that
  boots the lean profile locally with a module set, waits for health,
  runs the page sweep + selftests, and records image sizes + RSS per
  service into `SizingProfile` rows and a markdown table. Sets:
  `demo` (pub-0's), `islemesh-only`, `household+mealoptions+nutrition`,
  `all`. This decides D1/D2 with numbers.
- **prd-2 — image diet.** b1–b3 + f1–f5. Acceptance: backend-core
  ≤ 300 MB, backend-full ≤ 650 MB, frontend ≤ 40 MB with main.js ≤ 1.5 MB
  raw, proxy ≤ 80 MB; brotli + http2 verified with curl; the browser
  pass (CDP) still 17/17 on the vpn page and the mealplan pages.
- **prd-3 — runtime diet.** r1–r4. Acceptance: the demo set boots in
  < 2 min on 1 vCPU, backend RSS ≤ 400 MB after the sweep and returns
  after recycling, sqlite lean stack passes the live API + browser
  passes, Keycloak-off mode logs in (local) and Keycloak-on mode logs in
  (OIDC).
- **prd-3b — the core-only server (§2b).** Boot = the dyn-5 floor;
  request-triggered fetch-admit (code from the module repo, data from
  `initial-data` / an upstream instance); idle put-away with the K/N
  knobs; per-module extras installed at admission from a wheel cache OR
  refused with the exhibit suggestion; the `exhibit_only_on` registry
  flag; artifact cache TTL + disk cap. Acceptance on the core image: a
  first request for `/display/techtree` on a server that has never seen
  techtree admits it (cloned + seeded) within 10 s, a second module
  request evicts the idle one when K is exceeded, RSS after eviction
  returns to the floor, and `du` of the module + artifact caches stays
  under the cap through a 20-module sweep.
- **prd-4 — the lean profile as a swarm role.** `docker-compose.lean.yml`
  written swarm-first (§2); `pol swarm render|deploy lean`; `pol node up
  --env lean|public` runs the same file under compose; `BASE_DOMAIN`
  threading; LE via the existing `pol cert prod letsencrypt`; the
  parity check that refuses compose-only constructs. Acceptance: the
  demo set deployed by `pol swarm deploy lean` on a 1-node swarm on
  this box AND by `pol node up --env lean`, both green on the live API +
  browser passes, from the same file.
- **prd-5 — published images + bootstrap.** Release script
  (`pol build release <ver>`: both backend variants + frontend + proxy,
  tag `<ver>`, push to the registry of D3, write the manifest the stack
  file pins); `pol swarm bootstrap` (fresh Ubuntu → docker → swarm init
  → pull → deploy); the offline flavor loads image tarballs
  (`build-offline-bundle.sh` exists). Acceptance: on a fresh Ubuntu
  24.04 VM with nothing installed, one command serves the demo set at
  `https://<host>` within 5 min without building anything.
- **prd-6 — the droplet proof.** One $12 droplet: `pol swarm bootstrap`,
  measured (boot time, RSS, disk); then compose try-out of the same
  file on the same box for parity; then the $6 attempt without
  Keycloak. Numbers into this plan and the downloads page.
- **prd-7 — the isle route on a droplet** (isle-core, OPTIONAL now):
  `isle core-install --no-router` for a single-device isle without KVM,
  `isle-polari-deploy` pulling from the public registry. Only if the
  public instance must also be an isle (POLARI_SYSTEMS_ORG decision 5);
  otherwise the droplet is a plain swarm node.

## 6. Decisions (defaults in bold; his call)

- D1 target: **the $12 / 2 GB droplet with Keycloak; $6 / 1 GB as the
  no-Keycloak stretch** (prd-1's numbers may move this).
- D2 auth on the small VM: **Keycloak optional via `POLARI_AUTH`;
  default OFF for the distribution server (browse + download need no
  login), ON where people log in**.
- D3 image registry: **GHCR under `dausume/` (free for public images,
  same org as the module repos)** vs DigitalOcean's registry vs GitHub
  release tarballs only. Offline flavor keeps tarballs either way.
- D4 backend images: **two (`core`, `full`)** vs one full image with the
  extras uninstalled at boot (slower, fragile) vs one core image plus
  per-module wheels pulled at admission (the appstore's future — out of
  scope here).
- D5 WSGI server: **gunicorn (sync workers, `--max-requests`)** vs
  waitress (pure python, Windows-friendly, no recycling).
- D6 the server entry point: **`pol swarm bootstrap` (script/verb),
  optionally wrapped later as a tiny `polari-bootstrap` deb** vs a full
  headless `polari-server` deb that owns the stack (rejected by his
  ruling: swarm owns production; a deb that runs compose would be a
  third deployer).
- D7 frontend builder: **stay on webpack for prd-2 (lazy-loading + edge
  compression give the size), migrate to esbuild in prd-2b** if the
  migration is clean.
- D8 python `-OO`: **no** (docstrings are read at runtime).

## 7. Boundaries

- Ours: everything in §3–§5 except prd-7 (now optional).
- isle-core's Claude: prd-7 (no-router core-install, registry fallback).
- Dustin: D1–D8, the droplet + DNS + `DO_API_TOKEN` (POLARI_SYSTEMS_ORG
  pub-0 still holds), the KC secret rotation before anything is
  internet-facing (`pol security rotate staging`), the registry
  namespace (D3).

## 8. Not in scope

Engines images on the small VM (they stay on owned hardware or a bigger
box — `prf-*-engines` are 2+ GB and compute-bound), the PSC/Odoo suite
(compose `suite` tier), horizontal scaling (one droplet = one node).

## 9. Distribution + public TLS in the prod stack (2026-09-09, his two asks)

**Ask 1 — prod builds and serves the debs (or has the capability).**
What existed: the builders (`build-polari-isle-deb.sh`,
`build-polari-complete-deb.sh --flavor online|offline`,
`build-offline-medium.sh`), the Jenkins release stage that runs them into
the pool, the appstore module's server-rendered download surfaces
(`/downloads`, `/downloads/apps`, `/downloads/offline`, per-app debs on
demand), and the apt-repo publish route (reprepro + rsync to a
distribution host). What was missing in the prod STACK: the backend had
no staged-deb directory or pool, nothing exposed `/downloads` at the
apex, and nothing served an apt repository. Built:
- `docker-compose.prod.yml`: prf-backend gets `POLARI_DOWNLOADS_DIR=
  /app/downloads` ← `./.generated/debs` (the release pool's debs/) and
  `POLARI_APP_DEBS_DIR=/app/data/app-debs` (on-demand pool, persisted);
  pol-proxy mounts `./.generated/apt` at `/srv/apt`.
- `pol-proxy/nginx.prod.conf.template`: apex `location /downloads` →
  prf-backend (long read timeout, no buffering, for on-demand builds);
  new `apt.${PROD_DOMAIN}` server serving `/srv/apt` (autoindex) — the
  apt-repo route can rsync to this VM (`APT_REPO_DIR=<suite>/.generated/apt`).
- `prod-setup.sh` creates `.generated/{debs,apt}` and says when no
  platform deb is staged yet. The hub gets a Download link (nav +
  footer + the Install category) → `/downloads`.
Remaining (his side): run the builders (or copy the release pool) into
`.generated/debs` on the server; the apt route's signing key + host key
(polari-jenkins/secrets) and ⛔ KC rotation before the host faces the web.

**Ask 2 — HTTPS with a publicly trusted certificate.**
What existed: `pol cert prod letsencrypt` (certbot DNS-01 via
DigitalOcean) + weekly `renew.sh`, but the issued cert was never wired
into the stack (the proxy image bakes the self-signed pair; the manifest
had no row named `pol-proxy-public`, and its `prf-proxy` row lists the
rf-node hostnames, not the suite's). Built:
- `ca/cert-manifest.conf`: row `pol-proxy-public | edge | apex, www,
  auth, psc, api.psc, prf, api.prf, files, s3, odoo, apt` — every name
  the prod proxy terminates, resolved from PROD_DOMAIN.
- `setup-letsencrypt.sh`: `LE_CHALLENGE=http` = HTTP-01 through the
  proxy's `/.well-known/acme-challenge/` webroot (`.generated/
  certbot-www`, served on :80 before the redirect) — any registrar, no
  DNS API; DNS-01 stays the default. After issue (either mode) the new
  `ca/stage-edge-cert.sh` copies fullchain/privkey into
  `.generated/certs/edge/` and reloads the running proxy; `renew.sh`
  does the same after each renewal (docker exec reload when the proxy
  is a container).
- `docker-compose.prod.yml`: pol-proxy mounts `.generated/certs/edge/
  {fullchain,privkey}.pem` over `/etc/nginx/certs/pol-proxy.{crt,key}`;
  `prod-setup.sh` stages the LE pair when issued, else the self-signed
  pair (stack comes up either way; the setup output says which).
Verified: rendered prod nginx config passes `nginx -t`; `docker compose
config` validates; the manifest row resolves to the eleven names.
Remaining (his side): point DNS at the VM, run `pol cert prod
letsencrypt` (DNS-01 with DO_API_TOKEN, or `LE_CHALLENGE=http` with
the stack up), `pol cert auto-renew install`.

## 10. Demo notice + demo terms (2026-09-09, his ask)

Public instances must say they are demonstrations and that no personal
information belongs in them. Built: a `demo` stanza in both frontends'
runtime-config (`enabled`, `title`, `message`, `termsUrl`, `version`),
written by `nip-staging-setup.sh` and `prod-setup.sh` (on unless
`POLARI_DEMO_NOTICE=false`; `termsUrl` = `https://<domain>/docs/demo-terms.html`);
a `demo-notice` component in the Polari frontend (standalone, in the
root above everything) and in the scorecard frontend (same behaviour):
a persistent amber bar on every page ("Demonstration instance. Do not
enter personal information …" + the terms link) and a first-visit dialog
that must be acknowledged, remembered in localStorage per terms
`version` so changed terms re-prompt everyone. Isles and developer nodes
have no stanza and show nothing. The terms page is hand-written in the
hub (`pol-hub/site/docs/demo-terms.html`, Start here + footer): plain
language, explicitly not legal advice — what a demo instance is, no
personal information, nothing private or kept, demo accounts only,
acceptable use, no warranty (GPLv3, as is), run your own, versioned
changes. Both frontends type-check; not yet seen in a browser.

**Generalised the same day (his follow-up): the `terms` module.**
Terms are now rows, not a stanza. `TermsDocument` (versioned; `scope`
global or app + `app_name`; `kind` demo|standard|privacy|custom; `active`,
`requires_acceptance`, `show_bar`; Markdown body) and `TermsAcceptance`
(append-only: who — the Keycloak `sub` when logged in, else the browser's
anonymous terms session id — which version, sha256 of the exact text
shown, when, how = clickwrap, app, hashed client fingerprint; never a raw
address). Seeded boilerplate: `demo-terms` ACTIVE, `standard-terms` and
`privacy-notice` templates off — plain language, explicitly not legal
advice. API: `GET /api/terms/active?app=&session=` (what this subject
must still accept; bar on/off), `POST /api/terms/accept` (refuses a
version/text that is not the one served → 409), `GET /api/terms/status`,
`GET /terms/<name>` (plain page). Page `/display/terms` (documents +
ledger). Both frontends' gate now reads the API first — every pending
document in turn, full text shown, click recorded — and falls back to
the runtime-config stanza only where the module is absent. Proven on a
local instance (registrar online 2/2 classes, 3/3 seeds; fresh session
pending → bad hash 409 → accept recorded → that session clear, another
still pending; page renders). Selftest 14/14. What makes it binding is
the operator's and a lawyer's call; the mechanics record the elements
clickwrap is usually judged on. Frontends type-check; not browser-verified.

## 11. `pol prod` — the guided production flow + the lean swarm role (prd-4 built, 2026-09-09)

His ask: the prod shells were built around one compose file; carry the
concepts forward to the swarm-first approach, with a better TUI that
guides a user through every choice, and keep both routes — swarm
(developers, AI-assisted) and apps/KVM (people).

**Audit (agent, 2026-09-09) in one line:** `start-prod.sh` → `setup-polari-
security.sh prod` → `prod-setup.sh` (5 steps: domain, credentials, nginx
by sed + cert staging + dirs, `.env.prod`, three runtime configs) →
`docker compose up --build`; `pol suite up --env prod` never runs the
setup; `swarm.sh` knew only engines|cnt-engines|node|suite (suite pinned
to the STAGING file) — no prod role, no lean profile; the jinja sources
under `pol-services/` are stale against the hand-edited prod compose and
proxy template (a `pol build render && promote` would REGRESS §9's
downloads/apt/edge-cert work — bld debt, flagged, not fixed here); the
user-friendly route is the store shell's zenity three-door dialog →
`isle core-install` in a terminal; no release→deploy-to-prod step exists
anywhere.

**Built.**
- `docker-compose.lean.yml` — the lean profile, swarm-first (no build:,
  mem_limit, profiles or depends_on conditions; deploy.resources /
  placement / restart_policy; configs for nginx.lean.conf + the two
  runtime configs; SECRETS for the edge cert; host-mode 80/443; the
  proxy + backend pinned to the manager where the debs / apt / ACME
  webroot directories live). Four services: nginx:1.27-alpine proxy,
  pol-hub (site + docs baked in), prf-frontend, prf-backend on sqlite
  with `POLARI_MODULES=polariapps,appstore,islemesh,terms`, lazy boot,
  no Keycloak (D2), `/app/downloads` + on-demand pool.
- `pol-proxy/nginx.lean.conf.template` — five names, one cert
  (`ca/cert-manifest.conf` row `pol-proxy-lean`): apex/www → hub +
  `/downloads` + `/terms/`; prf → frontend; api.prf → backend (HTTP +
  STOMP upgrade); apt → `/srv/apt`; :80 = ACME webroot + redirect;
  resolver 127.0.0.11 with variable proxy_pass so the proxy boots first.
- `pol prod` (`polari-cli/scripts/prod.sh`): `guide` (whiptail menus on a
  terminal, plain prompts otherwise; route → domain + live DNS check →
  certificate: provider-issued/auto-approved (Let's Encrypt, http or dns
  challenge, e-mail) or auto-generated → logins → modules → installers
  (build | copy | skip) → demo notice → image tag → plan → apply),
  `check` (preflight), `plan`, `apply [--yes]` (10 idempotent steps),
  `status` (board: stack, services, cert issuer/expiry + PUBLIC or not,
  DNS per name vs this host, staged debs, apt tree, /api/health, terms
  gate, next action), `cert`, `debs build|copy`, `render|deploy|down`.
  Every answer = `.generated/prod-answers.env` and/or `POL_PROD_*` env
  → the AI/script route is `pol prod apply --yes`. Self-signed edge
  certs are signed by the suite CA with the five SANs; LE goes through
  `ca/setup-letsencrypt.sh` with `LE_CERT_NAME=pol-proxy-lean`, then
  the stack re-deploys with the new secret and auto-renew is installed.
- `pol swarm deploy lean` (role added; records env production); the
  store shell gains a fourth door "Set up a public server" → `pol prod
  guide` in a terminal (or instructions when `pol` is absent).
- Docs: `AI-Notes/guides/PROD_SERVER_GUIDE.md` → hub page
  "Setting up a production server" (Install category).

**Proven on the home swarm (3 nodes, this manager), then removed:**
`POL_PROD_DOMAIN=example.org … pol prod apply --yes` → preflight
(manager, ports free, images present, 6 debs staged), configs, CA-signed
cert with the 5 SANs, hub image, stack rendered (no compose-only keys),
`polari-lean` 4/4 replicas; through the proxy by Host header: apex hub
200 + docs page 200 + `/downloads` 200 (Downloads page), prf frontend 200
with the demo stanza, `api.prf /api/health` online 4/4 modules,
`/api/terms/active` pending demo-terms + bar on, `apt /health` 200, :80
→ 301 https, the served cert carries exactly the five names.
`pol prod down` left the swarm clean.

**Remaining.** (1) bld debt: re-sync `pol-services/` jinja sources with
the hand-edited prod compose/proxy (or retire the sed path) — until then
`pol build promote` must not touch prod; (2) images from GHCR (D3/prd-5)
so a fresh VM needs no local build — today the guide asks for a tag
present on the manager; (3) `pol prod` for the FULL profile (Keycloak)
still hands off to `start-prod.sh`; (4) the isle-side KVM route is the
store shell's own guide, untouched; (5) his: DNS, the real domain, the
LE issue, the apt signing key, KC rotation for the full profile.
