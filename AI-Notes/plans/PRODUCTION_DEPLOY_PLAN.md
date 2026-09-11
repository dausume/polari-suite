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

**§11 addendum, same day — the FULL profile on swarm too, one process.**
His ruling: "we need to transition to a fully working prod deployment
process based on docker swarm". Done in the same shape as lean:
- `docker-compose.prod.yml` converted swarm-first: every generated-file
  bind is now a config or secret (`nginx.prod.conf`, the CA cert, the
  three runtime configs, `keycloak-suite.conf`, `odoo.conf`; the edge
  pair as secrets); the proxy is `nginx:1.27-alpine` + config + secrets
  (no custom image); images are `${POLARI_IMAGE_REPO:-}name:${POLARI_
  IMAGE_TAG:-prod}`; stateful/bind-mounting services pinned to the
  manager. `build:` blocks stay for the compose (authoring) route.
- `stackify.py` drops `build:` and drops profile-gated services unless
  `--with-profile <name>` (odoo rides `POL_PROD_ODOO=on`); refuses an
  empty compose config loudly instead of crashing.
- `pol swarm deploy prod` role; `pol prod` profile = logins: off → lean,
  keycloak → full (`security_setup` runs `setup-polari-security.sh prod`
  non-interactively with RANDOM passwords, `write_configs_full` replaces
  prod-setup.sh's five steps — weak literal defaults are gone; `.env.prod`
  is 0600). `POL_PROD_IMAGE_REPO` pulls release images (with registry
  auth) instead of building; `pol prod bootstrap` = fresh VM (docker,
  swarm init, guide).
- `start-prod.sh` / `prod-setup.sh` retired into delegators to `pol prod`.
- `pol build promote` no longer touches `docker-compose.prod.yml`
  (manifest row commented out with the reason) — the prod and lean files
  are authored directly until the jinja sources are re-templated.
Rendered: stack-prod.yml = 10 services (odoo pair dropped), 6 configs +
2 secrets, no compose-only keys, 5 manager pins, KC issuer set on the
backend, rendered nginx.prod.conf passes `nginx -t`, the staged
CA-signed cert carries all 11 names.

**§11 addendum 2 — the FULL profile proven on swarm (2026-09-09/10).**
`POL_PROD_AUTH=keycloak … pol prod apply --yes` on the home swarm (this
manager): security material reused, `.env.prod` with generated
credentials (0600), CA-signed edge cert with all 11 names, the nine
profile images built by compose (~40 min cold: Keycloak from UBI, the
scorecard backend's maven), stack `polari-prod` = 10 services. Three
things surfaced and were fixed:
1. nginx would not boot: static `upstream { server prf-backend:3000 }`
   blocks fail DNS until the backend TASK runs (swarm publishes a
   service name only then) → the prod template now resolves every
   upstream lazily (`set $up_x …; proxy_pass $up_x`, resolver
   127.0.0.11), the pattern the lean template already used.
2. swarm configs/secrets are immutable → `stackify` names each by
   content hash (`nginx_prod_conf-032c218e`), so a changed file
   redeploys as a new object and `pol prod deploy` can update a running
   stack.
3. the backend never reached healthy: the compose carried 384 M / 0.4
   cpu and no module set, so a full monolithic boot of every module at
   0.4 cpu ran past the 15-minute start window (no OOM, just slow) →
   explicit `POLARI_MODULES` from the answers (+ scoring), lazy boot,
   1200 M / 1.5 cpu (D1). Core-ready in ~2 min after that.
After the fixes, through the proxy by Host header: apex hub 200,
`/downloads` 200, prf frontend 200 with the Keycloak authority + demo
stanza in its runtime config, `api.prf /api/health` online 5/5,
`auth /realms/Polari` 200, psc frontend 200 + `api.psc /health` 200,
MinIO console 200 + S3 live 200, `apt /health` 200, the served
certificate carrying 11 names, `/api/terms/active` pending demo-terms.
The registrar then reported appstore and scoring degraded — all three
were REGISTRAR heuristics, not deployment faults (page-server classes
expected as tables; a route compared with its trailing slash; an
`add_route` literal split across two source lines) — fixed and
re-verified locally (24 online, 0 degraded). `pol prod down` removed
the stack; `apply` now persists its answers so later verbs act on the
same profile, and `down` removes any pol prod stack left behind.
**Swarm is THE production process now**; compose remains the authoring
form and the laptop try-out. Remaining: release images in a registry
(prd-5/D3) so a fresh VM pulls instead of building; re-templating the
jinja sources; his DNS / Let's Encrypt / apt signing key / KC rotation.

## 12. nginx: two worlds, one suite template per env (his question 2026-09-10)

**Two nginx worlds exist and they do not share code:**
1. **Isle.** On an isle member the isle AGENT's nginx is the sole ingress
   for that device's apps, generated from the agent's `registry.json`
   (`Isle-Mesh/isle-agent/isle-vlan-agent/generate-nginx-configs.sh`) —
   `<app>.isle` names, the protocol matrix. Polari on an isle
   (`Isle-Mesh/polari-isle/docker-compose.yml`: prf-isle-backend +
   prf-isle-frontend on the agent network) is fronted by THAT nginx as
   `polari.isle`. pol-proxy is not used on an isle at all. Verified
   untouched by the swarm work: no commit under `Isle-Mesh/polari-isle`
   or the agent generator since ae8f5af; the only Isle-Mesh change is
   NOTES-FROM-POL-CORE.md. The isle stays exactly as it was.
2. **Suite (compose or swarm).** pol-proxy from ONE template per env
   (`pol-proxy/nginx.{staging,prod,lean}.conf.template`). The CONFIG is
   the same for a single host and a swarm: services are reached by name
   over the docker network either way, and every upstream is resolved
   lazily (`set $up_x http://host:port; proxy_pass $up_x;` + resolver
   127.0.0.11) so nginx boots before every service exists — mandatory on
   swarm (a service name resolves only once its task runs), harmless
   under compose. Staging's eight static upstreams were converted today
   like prod's. What differs per topology is the STACK, not nginx: the
   proxy's ports mode (host-mode 80/443 on the manager) and placement.

**So the setting is the route, made explicit:** `pol proxy mode` says
which world this machine is in (isle agent present → isle; swarm active
→ suite/swarm; else suite/single). `pol proxy template <env> [--domain D]
[--topology single|swarm]` renders the template into
`.generated/nginx.<env>.conf` — the file compose mounts AND the stack
ships as a config — and REFUSES a template with static `upstream{}`
blocks; `pol proxy guard <env>` runs nginx -t with the edge cert + CA
mounted and every service name stubbed. `pol prod` renders through it.
All three envs pass the guard.

**Multi-computer with one access point: yes, by construction.** The
proxy is pinned to the manager (the access point) and reaches every
service by name over the overlay wherever the task lands; `pol allocate`
/ `POL_STACK_CONSTRAINTS` place services across nodes. One rule: with
LOCAL image builds only the manager has the images, so `pol prod` pins
every service to the manager; with a registry (`POL_PROD_IMAGE_REPO`)
services may spread. Profile-gated services (odoo) are named explicitly
for swarm (`POL_SWARM_PROFILES=odoo` / `POL_PROD_ODOO=on`): compose
config omits them otherwise, which is what every swarm role did before.

## 13. Into and out of production, both routes, by terminal (tested 2026-09-10)

**Isle route (over SSH to isle-core, the live isle from polari-complete
0.1.33).** "Prod mode" on an isle = designating the device an entrypoint
and opening a door; "out" = closing it. Sequence and results:
1. `isle url expose polari.isle --port 18443 --user tester` while NOT an
   entrypoint → refused ("exposure is regulated") ✓
2. `sudo isle url entrypoint enable` ✓ (`/etc/isle-mesh/entrypoint.enabled`)
3. `sudo isle url expose polari.isle --port 18443 --user tester --password …`
   → security gate clean → gateway container `isle-expose-18443` on
   0.0.0.0:18443 → from another machine: 401 without credentials, 200
   (the Polari frontend) with them; `.isle` itself never left the isle ✓
4. `sudo isle url unexpose --port 18443` → container gone, connection
   refused from outside ✓; `sudo isle url entrypoint disable` → "not an
   entrypoint", "the isle is fully contained" ✓
Found: `isle security gate` answers differently as root vs the login
user (the user path checks the dev checkout, not the installed
material), so `isle url expose` needs sudo today — reported to
isle-core in NOTES-FROM-POL-CORE.md. The isle's Polari (prf-isle-backend
+ frontend, up 4 days) was untouched by the swarm work.

**Swarm route (this manager).** `pol prod apply --yes` (lean) → stack
polari-lean 4/4, apex/downloads/prf/api health (4/4 modules)/apt all 200
→ `pol prod down` → no stack, ports 80/443 closed, the apex no longer
answers. Same day the full profile did the same loop (§11 addendum 2).

Both routes go into production and back out from a terminal alone; the
isle's exposure is per door and per person, the swarm's is the whole
stack. What was NOT tested: creating a fresh isle from scratch (needs a
hardware-tier machine that is not the live one — DEB_TOPOLOGY_TEST_
SCENARIOS Phase D/E, his hands-on), and the Let's Encrypt issue (needs
real DNS).

## 14. Remote install + tier from the CLI (his question 2026-09-10)

"We should be able to remote install a Polari instance or upgrade it to
hardware tier via polari cli, correct?" — partly true before, true now.
Before: `pol deploy run <node> --role engines|remote-worker|node` (ssh:
pull + compose up, staging), `pol swarm join <node>`, `pol dev deploy`
(ssh isle-polari-deploy — BROKEN on isle-core today: the binary is not
installed by polari-complete 0.1.33 though isle-polari-teardown is),
and the isle member route was a manual curl + sudo of the core's
bootstrap. Nothing said "install a Polari instance THERE" for either
route, and no tier existed on a machine row or a swarm node.
Built (`pol deploy`, the ssh-to-nodes tool; targets in nodes.yml):
- `pol deploy install <node> --route swarm-worker|swarm-server|isle-member|isle-core [--profile lean|full --domain D] [--host] [--dry-run]`
  swarm-worker = docker + join this manager's swarm (label); swarm-server
  = docker + suite checkout + pol + `pol prod apply --yes` there;
  isle-member = fetch the core's bootstrap (fingerprint read from the
  core over ssh) + `sudo bash isle-bootstrap.sh --fingerprint … --core
  <ip> [--host]`; isle-core = ship the staged polari-complete deb, apt
  install, `sudo isle core-install` (interactive, `ssh -t`).
- `pol deploy tier <node> --check | reach|member|hardware|core`:
  remote probe (docker, virt flags, /dev/kvm, libvirt, IOMMU groups,
  isle agent/cli) → what the machine qualifies for; setting a tier
  labels the swarm node `polari.tier=<t>` and posts `tier` onto the
  topology machine row (`PolariNodeMachine.tier`, new field; endpoint
  whitelists it). Hardware refuses without kvm + libvirt on the target.
Tested: isle-core --check → hardware (12 virt flags, kvm, libvirt, 10
IOMMU groups, agent up); econ-core --check → member (kvm yes, libvirt
no — the fix is named); `tier isle-core hardware` → node label set;
`install econ-core --route swarm-worker` → idempotent, already joined;
swarm-server and isle-member dry-runs print the exact ssh steps.
Not run for real: a swarm-server install on econ-core (ports 80/443
free there but it is the Odoo box; his call) and an isle-member
bootstrap (needs sudo on the target — `ssh -t` lets sudo prompt).
Isle-side `isle onboard --hardware` remains isle-core's requested verb.

**§14 addendum — the goal, restated (his message 2026-09-10) and where it stands.**
Polari must fully do both routes from a terminal: the APP route (isle,
hardware setup) drivable by a pro dev or an AI over ssh — install,
uninstall, status — even though the AI cannot click the store; and
non-isle swarm deployments as the usual choice when no hardware setup
is needed. `pol deploy` is that surface now:
| verb | swarm | isle |
|---|---|---|
| install | `--route swarm-worker` (join) / `swarm-server` (pol prod there) | `--route isle-member [--host]` (bootstrap from the core, sudo) / `isle-core [--yes]` (deb + `isle core-install`, `--skip-security` when unattended) |
| status | node role/state/labels + tasks placed there | router, agent, polari.isle HTTP, open doors, virsh guests, versions |
| uninstall | drain + `docker swarm leave` + node rm / `pol prod down` | `isle uninstall --everything --force` with `ISLE_CONFIRM_DELETE=yes` — only with `--yes` |
| tier | `polari.tier` label + machine row | same, hardware refuses without kvm + libvirt |
Tested live: status on isle-core (router ✓, agent healthy, polari.isle
200, no doors, tier hardware) and econ-core (swarm-only); dry-runs of
every uninstall; the isle-core wipe refuses without `--yes`. Real
isle install/uninstall runs need a spare hardware-tier box (his).

## 15. The remote lifecycle test (2026-09-10): wipe, reinstall, tier — and the permission groups

His test: bring down the isles on other devices and their dependencies,
do an isle core-install on isle-core, make econ-core a hardware-tier
member of it — all remotely through the Polari terminal.
**isle-core — done, unattended, from pol-core:**
- `pol deploy uninstall isle-core --route isle-core --yes` → backup,
  destroy --purge, network handback (NetworkManager owns every
  interface again), volumes backed up + removed, packages purged;
  status after: no agent, no prf-isle, no router VM.
- `pol deploy install isle-core --route isle-core --yes` → the staged
  polari-complete 0.1.33 shipped + installed, `isle core-install
  --skip-security`: router VM `openwrt-isle-router` running, CA minted
  (D6:9F:DB:E3…), prf-isle up (islemesh), `polari.isle` 200, apt-on-mesh,
  store 16 apps, JOIN INFO printed. Security walkthrough deferred (as
  the unattended form must) — `isle security setup` before any door.
**econ-core — blocked on one thing: sudo asks for a password there**,
so nothing needing root (libvirt for the hardware tier, the isle
bootstrap) can run unattended. That is the permission-group question,
answered per his ruling (two groups):
- `polari-remote` — ssh + swarm + AI-assisted setup: NOPASSWD for
  exactly the commands `pol deploy` sends (docker install/usermod,
  `isle`, the bootstrap script, the isle-mesh scripts, the platform deb
  installs, libvirt install + groups, reading the isle CA). Files:
  `polari-cli/shells/groups/polari-remote.sudoers` (+ `!requiretty`).
- `polari-app` — the app-setup route, what the store's doors run for a
  person: `isle core-install|onboard|app|url|status|uninstall`, the
  platform/app deb installs. `polari-app.sudoers`. Separate on purpose.
- `install-groups.sh <remote|app> <user>` creates the group, validates
  the file with visudo, installs it, adds the user. `pol deploy grant
  <node> --group remote|app` ships both and runs it; where sudo still
  needs a password it prints the ONE interactive line and (with a
  terminal) runs it with `ssh -t`. Both files pass `visudo -c`.
- `pol deploy tier <node> hardware --install` puts libvirt on a
  kvm-capable target through that group, then labels it.
**Next, his one line on econ-core** (or `ssh -t econ-core …` from here):
`sudo bash /tmp/install-groups.sh remote dausume` — the files are
already staged on econ-core. After it: `pol deploy tier econ-core
hardware --install`, `ISLE_CORE_IP=192.168.0.25 pol deploy install
econ-core --route isle-member --host`, `pol deploy status econ-core`.
The member dry-run already resolves the new isle's fingerprint and the
bootstrap sha from the core.

## 16. The credential vault — auto-generated secrets, safe from anyone external (his rulings 2026-09-11) — BUILT the same day (prd-9, see §18)

_His ask: "a secure file that has sudo-only permissions to be read, modified or deleted, with clear labelling and encryption, so it can be secure despite being on the desktop… leave it so they can access it later, or write it down / put it somewhere safe and delete the file." His ruling, same day: the vault is **against external access**; there is **no "no AI" restriction for now, because we need to iterate quickly** — the operator account (and an assistant working in it) may open the vault. The stricter off-machine-key mode is kept as a knob for later, not the default._

**What it protects against:** a copied disk or backup, a stolen VM image, another local user, a `.generated`/checkout leak into git or a tarball, and plaintext credentials lying in the repo tree. **What it does not try to stop:** the operator account with sudo, and whoever works inside it. That is deliberate for now.

**Design.**
- **Location and permissions:** `/etc/polari/vault/`, `root:root 0700`; one file per generation `polari-credentials-<domain>-<date>.age`, `0600`, outside the repo (survives reclones and `pol repos slim`); rotation writes a new file and marks the old superseded. Reading, changing or deleting needs `sudo`.
- **Encryption:** `age` (BSD-3, in Ubuntu's repos; openssl fallback if age is absent). Default mode **`local`**: the vault is encrypted to an age identity kept at `/etc/polari/vault/identity` (`root 0600`), generated on first apply — so the file is useless anywhere but on this machine as root, which is the external-access guarantee. Optional mode **`offline-key`** (`POL_PROD_VAULT_MODE=offline-key`, recipients = ssh public keys): encrypted only to keys whose private halves are off the machine; nothing on the server can decrypt; for when the iteration phase is over. Both modes may be combined (local identity + an offline recovery recipient), which is the recommended default once he wants it.
- **Content:** a labelled banner (`POLARI CREDENTIALS — <domain> — generated <date> on <host> — root-only, encrypted; sudo pol security vault show opens it`), then one block per credential with purpose, where it is used, and how to rotate: Keycloak admin, Keycloak DB, PSC DB, MariaDB root, MinIO root + client, the apt signing passphrase when one exists, the CA key's location (never its bytes).
- **Generation writes no plaintext to the checkout:** values are produced in memory, sent to `docker secret create` (the swarm's machine copy) and to the vault; the setup log records names only. The plaintext env files the setup shell writes today are shredded after the stack is healthy on the swarm route (compose keeps 0600 env files; the guide says so).
- **The prompt at the end of `pol prod apply`:** keep the vault here (default; `sudo pol security vault show` later), show once and shred (write it down / password manager; the TUI confirms before shredding), or export to a path and shred the local copy. Unattended runs keep.

**Verbs.** `pol security vault show|list|export <path>|import <file>|shred|rotate-key|recipients` (all sudo; `show` prints to the terminal, never to a log; in `offline-key` mode `show` says the machine cannot decrypt and points at export). `pol security rotate prod` writes a new vault and new swarm secrets in one step. `pol security status` reports the vault (present + mode, shredded-by-choice, or generated-but-unvaulted = failure) and whether any plaintext credential file still exists on the swarm route.

**What this fixes from today's finding.** The setup treats a placeholder-bearing or absent file as "generate" (fresh DB volume required, said out loud), so one run of apply is true on a used box as well as a fresh VM.

**Provider credentials and the stash choice (his ask 2026-09-11).** The vault is also the keystore for credentials of the *providers* a deployment leans on (DigitalOcean API token, a registry pull token, a Cloudflare token — never the console or registrar logins, which the server has no business holding). At the START of `pol prod guide` the operator is told: "provider credentials you enter can be stashed in the vault (root-only, encrypted) or kept only for this run; we advise recording them in your own password manager and NOT leaving them in the file." Then, per credential as it comes up, the choice is **stash all / stash some (asked per item) / stash none**, recorded in the answers as `POL_PROD_STASH=all|some|none` + `POL_PROD_STASH_ITEMS`. Stashed items land in the vault under a separate `provider credentials (stashed by your choice — move them elsewhere and shred with pol security vault forget <item>)` block; `pol security vault forget <item>` removes one; `pol security status` lists which provider credentials are stashed and how old they are, with the same "move them elsewhere" advice. Which providers are in use for what is not a secret and is tracked outside the vault: `pol prod providers` (built, §17).

Phase **prd-9**: local-identity age vault + in-memory generation into swarm secrets + shred of checkout env files + prompt + verbs + status checks + the placeholder fix; `offline-key` mode behind the knob. Proof on the fresh droplet: after apply no generated value is found in the checkout or `.generated`; `sudo pol security vault show` prints every credential; Keycloak login works with it; the vault file copied to another machine does not decrypt. His **D9**: age via a local identity (recommended, default) with the ssh-key mode as the knob — agreed 2026-09-11. **D10**: shred the checkout env files by default on the swarm route (recommended) or keep them until the vault has been used once?

## 17. Addresses and providers (built 2026-09-11)

- **`pol prod addresses`**: on a DigitalOcean droplet, reads the metadata service (no token) and lists the public IPv4, the public IPv6 when enabled, the **reserved IP** when one is attached, and the VPC address; elsewhere the address the internet sees plus the LAN address. The **exposure address** (what every A record must carry) is the reserved IP when attached, else the public IPv4 — and it is a SUGGESTION: the guide asks "keep it, or type the address you know is right", and `pol prod addresses --use <ip>` / `--auto` change it any time (his ruling: the detected address can be wrong or can change; the operator's answer wins and is recorded as `POL_PROD_EXPOSURE_IP`). The preflight and the status board say whether the address in use is detected or answered, warn when no reserved IP is attached on a droplet (a rebuilt droplet gets a new address), and flag a wrong AAAA record.
- **`pol prod providers`**: which provider fills which role — hosting, DNS, certificate, registry, code — derived from the answers and from where the machine runs, with the pages to visit for each (DigitalOcean console, reserved IPs, DNS, firewalls, API tokens, metadata docs; Let's Encrypt how-it-works, rate limits, status, crt.sh for the domain, certbot docs; GitHub packages and tokens; the registrar's DNS page and a public DNS checker). The catalogue is `polari-cli/scripts/lib/providers.sh`, one block per provider, and the guide shows the relevant links at the DNS step and the Let's Encrypt step (plus the token page when the DNS challenge is chosen). Provider credentials: only the DNS-challenge token is ever taken, from the environment, never written into the answers; stashing them is the vault's choice above.

## 18. prd-9 BUILT 2026-09-11 — the vault, the stash choice, providers, addresses

- `polari-cli/scripts/lib/vault.sh`: `pol security vault init|put|get|list|show|forget|export|import|shred|status`. Root-only dir (0700) + file (0600) at `/etc/polari/vault` (`POL_VAULT_DIR` for tests), local identity (age when installed, else openssl aes-256-cbc/pbkdf2 with a 256-bit key file — no new dependency), `offline-key` mode behind `POL_VAULT_MODE` (recipients file; the machine cannot decrypt). Document = banner + `[polari <domain>]` + `[provider <name>]` sections, every item stamped with purpose and date; edits are decrypt → edit in memory → re-encrypt, atomic replace. Proven in a scratch dir: put/get/overwrite-in-place/forget/show/export/shred/import/status, and the ciphertext contains no plaintext.
- `pol prod`: the guide opens with the vault notice and the **stash policy** (all / some = ask per item / none, answer `POL_PROD_STASH`); `stash_provider`/`recall_provider` honour it — the DNS-challenge token is taken from the environment and stashed per policy, or recalled from the vault on the next run, else the guide names the token page; `security_setup` now treats **placeholder-bearing credential files as missing** (moved to `.generated/stale-creds/<stamp>/`, fresh ones generated, the DB-volume consequence said out loud) and records every generated credential in the vault (`vault_generated`, idempotent); the end of a TUI apply asks keep / show-once-and-shred / export-and-shred (`vault_prompt`); `pol prod status` and `pol security status` carry the vault line and the stash reminder.
- Providers and addresses: §17 (built earlier the same day).
- Not done (D10 default kept): the checkout env files stay 0600 after apply — shredding them needs apply to restore from the vault first; `offline-key` mode is present but unproven end-to-end (needs `age`).

## 19. The first droplet run (2026-09-11) — what broke, what changed, and the TUI verdict

**Run on a fresh Ubuntu 26.04 droplet through the browser console via get-polari.sh.** Reached the guide, answered it, applied; failed at `docker stack deploy` with "this node is not a swarm manager". Findings and fixes (all pushed the same evening):
1. The swarm-state check was `grep -q active` — which matches **"inactive"** — so neither bootstrap nor apply ever ran `docker swarm init`. Now an exact comparison; init is loud and fatal when it fails.
2. The lean/prod compose files carry no `build:` (swarm-first rule), so "build images locally" built only pol-hub; the prf images were never built. Now `build_prf_images` builds them from the node's staging build definitions (context, dockerfile, args parsed from the compose) and tags them for the profile, with the memory/time warning said first.
3. The IPv6 check took `getent`'s IPv4-mapped answer (`::ffff:a.b.c.d`) for an AAAA record → false warnings. Filtered.
4. The deb build needs Isle-Mesh and polari-app-shell; get-polari.sh now pulls them (blobless, small).
5. Ubuntu's first-boot updates hold the package lock for minutes and the script said nothing → it now waits visibly, and step 1 no longer installs npm (pol needs only node).
6. Every `pol prod` run is now logged in full to `.generated/prod-log/<stamp>-<verb>.log` (answers included) — `pol prod log [n]` prints it; paste it here to review a run.
7. The image question is no longer a free-text tag defaulting to `staging`: one list — build here (tag `prod`), the `staging` images if present, release tags (`polari-v*`), or a pull from a registry chosen from **our official sources** (`ghcr.io/dausume/`, `lib/providers.sh`) or typed by hand with the example format; registry + tag are set together and verified with `docker manifest inspect` before they are accepted. The plan and apply now state in words where images come from.

**His verdict on the TUI: "almost unusable"** — whiptail boxes at 20×78 on the DigitalOcean web console truncate every long message, the apply output is a wall of text, and there is no way to see what step you are in. Decision to make (his D11): replace whiptail with a **Python TUI**. Options, all GPLv3-compatible:
- **Textual** (MIT, by the Rich author): full-screen apps that resize with the terminal, scrollable panes, forms, lists, progress, a live log widget, mouse support, works over any terminal incl. the browser console; `textual-serve` can even serve the same app as a web page. **Recommended.**
- **prompt_toolkit** (BSD-3): the engine under IPython; excellent prompts, completion and validation; full-screen layouts possible but more hand-built.
- **urwid** (LGPL-2.1): the mature classic; capable, dated look, less adaptive.
- **Rich** alone (MIT): rendering only (tables, panels, progress, syntax) — no interaction; pairs with `questionary`/`InquirerPy` (MIT, prompt_toolkit-based) for simple question lists.
Shape (prd-10): `polari-cli/tui/` — a Textual app `pol prod guide` launches when python3 + textual are present (install-cli.sh adds `pip install textual` where allowed; whiptail stays as the fallback). Left column: the step list with state (pending / current / done / failed) — addresses, DNS, certificate, profile, modules, installers, images, stash, apply. Right column: the current form, or during apply the live log pane (the same run log, streamed). Bottom: what will happen next and the keys. **The answers model is one Python dataclass with the constraints that must hold together** — registry ↔ tag (empty registry ⇒ tag prod; registry ⇒ tag verified), profile ⇒ compose file ⇒ stack name ⇒ image set ⇒ cert row (lean 5 names / full 11), DNS provider ⇒ challenge (dns challenge ⇒ DigitalOcean DNS + token), exposure address ⇒ DNS check target, domain ⇒ every name — validated on every change, so a mismatch cannot be submitted (his ask: "things that logically are required to map together should be tracked so we cannot mismatch logic"). The bash `prod.sh` keeps doing the work; the TUI only produces the answers file and streams the run log, so both front ends drive the same steps.
