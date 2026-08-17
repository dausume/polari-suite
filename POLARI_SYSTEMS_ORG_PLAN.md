# polari-systems.org — public site + single-download bundle + demo
# instance (pub-0..pub-6)

**Date:** 2026-08-16 · **Status: PLANNING ONLY (Dustin: "just
making a plan for that for now").** Scanning + local-AI hosting
explicitly shelved for a while (their plans/ledgers stand).
Grounded in a survey of the previous production flow, the isle
onboarding installers, the app-store deb chain, and the ai-7/ai-8
hosting data — assumptions are MARKED.

**Dustin's brief:** revise the primary polari website so people
can (1) download the BUNDLED polari + isle-mesh as ONE download,
(2) use that installed endpoint to download the remaining apps
through apt even when they don't have them locally; base domain
https://polari-systems.org with subdomains; a NEW merged
isle-mesh + polari deployment that feasibly runs on a minimal
4 vCPU DO VM; the public instance is a LIGHTWEIGHT demo — pre-run
sims/data served and replayable, NEW runs disabled when the
engines/modules they depend on are absent; serve the debs, make
install easy, walk people through, demo as much as we can.

## Ground truth (surveyed 2026-08-16)

- **The primary website already exists**: `pol-hub/` — a static
  nginx front door (index + Mermaid docs, theme-aware) serving
  the APEX + www behind pol-proxy in both staging and prod
  composes. The revision extends it; nothing starts from zero.
- **The previous compose-only production flow exists**:
  `docker-compose.prod.yml` (19 services: prf + psc + odoo +
  shared mariadb/keydb/minio/KC/proxy/hub) + `prod-setup.sh` /
  `start-prod.sh`; `pol suite up --env prod` drives it. TOO HEAVY
  for 4 vCPU as-is — the new deployment is a SUBSET profile, not
  a rewrite.
- **polari-systems.org is already the named production domain**:
  `setup-polari-security.sh` mints the prod CA/SANs for
  `auth.polari-systems.org` + apex. The strategy was designed in.
- **Let's Encrypt via DO is BUILT**: `pol cert prod letsencrypt`
  = certbot DNS-01 walkthrough needing LE_DOMAIN / LE_EMAIL /
  **DO_API_TOKEN**, plus `pol cert auto-renew install` (weekly
  cron). DNS-01 also grants a wildcard — one cert covers every
  subdomain. ⚠ MARKED ASSUMPTION: the domain's DNS is (or will
  be) hosted at DigitalOcean so the token works.
- **BASE_DOMAIN generalization is built** (custom-staging-domain,
  consolidated to dev 2026-08-02): the whole env/proxy/cert/
  runtime-config chain threads a configurable base domain; prod
  needs the same treatment pointed at polari-systems.org.
- **The single-download's halves are BUILT + proven** (isle
  onboarding, 2026-08-09): isle-mesh-cli deb 0.1.9 + store deb
  0.1.7 (postinst CA seed, sanitized-PATH fix, fresh-device
  bootstrap proven on econ-core); **apt-on-mesh LIVE at
  apt.isle**; `isle core-install` stands up a single-device isle
  (first-class by the membership rule: the agent IS membership,
  the store installs nothing on non-members).
- **The app/deb chain is built**: `pol apps shell <app>` (row →
  registration → launcher deb, idempotent); appstore artifacts
  (MinIO) + enrollment tokens; 16/16 apps converted (sep-6);
  module debs (mac-8) exist for module installs.
- **The demo-honesty machinery is built**: module gating with
  honest 503s + bring-up affordances (mlb/dyn), engine resolution
  ladders + refusals naming what's absent (sep-4), warm-boot ETAs.
  "Disable new runs when engines/modules are absent" is DETECTION
  the framework already does — the demo work is curation + the
  banner + download affordances, not new gating.
- **Sizing truth (ai-6/ai-7/ai-8 data)**: DO Basic 4 vCPU / 8 GB
  / 160 GB = $48/mo (dated 2026-08-16). prf-a today boots 8
  modules in ~385 s on 4 cores/16 GB; the demo set must be
  SMALLER and measured (resource profiles + baseline_profile
  exist to measure it). MariaDB+KC are the RAM heavies; sqlite
  parity is proven if MariaDB must go.
- **Security posture**: all 8 repos are PUBLIC (no secrets in
  git) but **KC-secret rotation is still pending** — an
  internet-facing deploy makes that a BLOCKER-level prerequisite.

## ✅ DECIDED (from the brief)

| # | Decision |
|---|---|
| 1 | polari-systems.org apex = the revised pol-hub (info + walkthrough + downloads); subdomains per service (prf/api/auth/apt/...) under ONE wildcard LE cert |
| 2 | ONE download: a `polari-isle` bundle deb wrapping the PROVEN pair (store shell deb + isle-mesh CLI deb) — install ends with a working native app + an isle agent (membership rule satisfied), apt source pointed at the public repo |
| 3 | The installed endpoint pulls further apps via apt from apt.polari-systems.org even with nothing local — the apt-on-mesh publisher ported to a public, signed repo |
| 4 | The public instance is a DEMO: minimal module set + pre-run sims/data, replay allowed, new runs refuse honestly (existing detection) with a "run this yourself — install locally" affordance |
| 5 | The deployment is compose-only (the previous production flow's shape), sized for a 4 vCPU DO VM, and is itself a single-device ISLE (isle core-install on the droplet) so polari + isle-mesh ship merged |
| 6 | Prices/dates discipline carries over: the download page states versions + dates; the ai-7 hosting page pattern is the house style |
| 7 | **The variant name is `exhibit`** (Dustin 2026-08-16): keys `<module>.exhibit`, debs `polari-module-<m>-exhibit`, the exhibit banner on every sample page — Q5 CLOSED |
| 8 | The site carries a real DOCUMENTATION section (Dustin): polari core, isle-mesh, module functionality, and the approach + purpose of the open-source economic baseline (OSEB) |

## Phases

- **pub-0 — prerequisites + sizing proof (nothing public yet).**
  Rotate the pending KC secrets (blocker for internet-facing);
  Dustin: confirm DNS at DO + mint DO_API_TOKEN + create the
  droplet (ai-7 row: DO Basic 4 vCPU/8 GB $48/mo). Us: define the
  DEMO MODULE SET (proposal: topology, islemesh, appstore,
  polariapps, simulations, **techtree — FULL, not exhibit**
  (Dustin: the tech tree is core to people walking through and
  understanding how it functions; it is browse-native data —
  trees/nodes/segments + derived completion, no engines — so the
  full module is cheap and the interactivity IS the point) + 2-3
  showcase modules as exhibits — climate, motors, mathshapes) and
  MEASURE it locally (baseline_profile) against 4 vCPU/8 GB;
  pick MariaDB-vs-sqlite from the numbers.
- **pub-1 — the minimal merged compose profile.**
  `docker-compose.public.yml` as a SUBSET of prod.yml: proxy +
  hub + KC + prf backend/frontend + file-store (+ mariadb per
  pub-0), NO psc/odoo. Thread BASE_DOMAIN=polari-systems.org
  through the prod chain (the staging generalization, applied to
  prod); wildcard LE cert + auto-renew; `pol suite up --env
  public` (or a `pol public` verb). Deploy = `isle core-install`
  on the droplet FIRST (the droplet is a single-device isle),
  polari behind its agent — the merged deployment of decision 5.
- **pub-2 — EXHIBIT module variants + demo mode.** (Dustin
  2026-08-16: "a display-samples-only version of each of the
  modules that removes most of the backend capabilities and just
  enables showing results — sub-sets of modules for sampling
  only.") Naming proposal: **exhibit variants**, keyed
  `<module>.exhibit` — the dotted-subset vocabulary the framework
  already speaks (`materialsScience.dft`, `scanning.recon`), and
  the word says the semantics honestly: finished results on
  display, machinery absent. (Alternates if preferred: `sampler`
  — closest to Dustin's own word — or `showcase`; his call, Q5.)
  Mechanics (all existing seams): an exhibit variant is a
  MANIFEST naming the KEPT classes (definitions + result rows +
  display/page seeds) — no workers, no engines, no action APIs;
  the CRUDE gate refuses writes on exhibit classes; run verbs
  refuse via the existing module/engine detection, DECORATED with
  the affordance ("sample result — install <module> to run your
  own", linking the bundle + apt line). Every exhibit page wears
  the exhibit banner — samples are never passed off as a working
  module. Pre-run content ships IN the exhibit seeds (seed-borne
  results free: motors, materials, shapes; ingested series like
  climate need an export→seed step). A `POLARI_DEMO` knob marks
  the instance (banner + /identity). SIZING WIN: the demo box
  runs exhibits, not full modules — smaller classes, smaller
  boot, easier 4 vCPU fit (pub-0 measures exhibits, not fulls).
  Exhibit variants also become their own DEBS (pub-3/4): tiny
  sampler packages anyone can install locally before committing
  to the full module.
- **pub-3 — the single-download bundle.** `polari-isle` meta-deb:
  Depends: isle-mesh-cli, polari store shell deb; postinst adds
  the apt.polari-systems.org source + key and seeds the public
  CA/LE trust note; first-run offers `isle core-install` (own
  isle) or `isle join` (existing isle) — the membership rule's
  two doors. Built by a committed builder script (the 0.1.4
  lesson: no /tmp hand-builds). Served from the website with
  version + date stated.
- **pub-4 — the public apt repo.** Port the apt-on-mesh publisher
  to apt.polari-systems.org: signed repo (new public signing key
  — NOT the isle key), serving isle-mesh-cli, the store deb, the
  bundle, launcher debs, module debs. The bundle's apt source
  makes "download remaining apps without having them locally"
  true by construction. ⚠ apt gotchas already learned: sanitized
  PATH, CLI-deb-overwrites-repo-edits (in the onboarding memory).
- **pub-5 — the website revision.** pol-hub gains: the download
  front door (bundle + per-platform artifacts from the appstore
  machinery, versions + dates), a walkthrough (install → first
  login → tour), a "what you're seeing is a demo" page linking
  every exhibit result to the module/app that produced it, the
  live demo links (prf.polari-systems.org) — AND the
  **documentation section** (decision 8), four pillars:
  1. **Polari core** — object tree, classes → tables + CRUDE,
     displays as data, modules, topology, the knob-and-suggestion
     discipline (source: the polari-overview/backend/frontend
     material + polari-mcp conventions).
  2. **Isle-Mesh** — isles, membership (the agent IS membership),
     cores vs members, the store, apt-on-mesh, how a device
     joins (source: the convergence/onboarding handoffs).
  3. **Module functionality** — what a module is, full vs
     `.exhibit` variants, the catalog with per-module pages
     (ideally DERIVED from the registry JSON + PolariAppDefinition
     rows rather than hand-written — one source of truth).
  4. **The OSEB** — the approach and PURPOSE of the open-source
     economic baseline: empowering small businesses, the GPLv3/
     no-NC stance and why, the tech-tree framing (source: the
     seeded OSEB tech tree + techtree content rows — again
     derived where possible, prose where it must be). The docs
     pages LINK INTO the live tech tree on the demo instance
     (techtree runs FULL there, pub-0) — read the approach, then
     walk the actual tree.
  **Tree ↔ docs cross-links as DATA** (Dustin): docs sections
  carry stable anchors; TechNode rows reference the relevant
  anchor (the nav `ref` pattern — a `doc_ref` on the node, seeded
  where sensible), so the live tree links back into the docs and
  the docs link into the tree — both directions derived from
  rows, neither hand-maintained in prose.
  **AI-walkable by design** (Dustin: "people can use AI to see
  what is going on with polari as a system when an AI reaches
  out to polari-systems.org"):
  - `llms.txt` at the apex (the emerging convention): what polari
    is, the docs map, and the MACHINE endpoints an agent may read
    (the public instance's honest JSON: apps catalog, tech tree,
    engines, module directory, exhibit listings).
  - Docs pages are semantic static HTML readable WITHOUT
    JavaScript (already the hub's nature) — an agent fetching any
    page gets real content, not an app shell.
  - A machine index (JSON): the docs sitemap + per-doc summaries
    + the API endpoint list with one-line contracts — generated
    at build time alongside the derived pages.
  - ⚠ OPTION, Dustin's security call (Q6): a public READ-ONLY
    MCP surface (polari-mcp exists; the demo instance could
    expose its inspect-only tools) — the strongest form of
    "an AI can walk the system", but it is exposure and belongs
    behind the pub-6 hardening decisions, not assumed.
  Format: extends the existing docs.html Mermaid pattern — static
  stays static (the hub's own rule), with derived content
  generated AT BUILD/DEPLOY time from the instance's own rows,
  never a runtime dependency for the docs pages.
- **pub-6 — hardening + ops.** Public-KC policy per Dustin's
  answer (Q4); rate limiting at the proxy; backups of the
  droplet's data volume; uptime checks; the ai-7 page's
  destroy/renew notes applied to our own droplet (it bills while
  powered off only for GPU — plain droplets stop billing off, but
  document either way); TESTING_OWED walk.

## Boundaries

- Ours: compose profile, BASE_DOMAIN prod threading, demo knob +
  content export, bundle deb builder, apt publisher port, hub
  content, sizing measurements.
- Dustin's: domain/DNS control + DO_API_TOKEN + droplet creation
  ($48/mo commitment), KC secret rotation sign-off, the 4 open
  questions below, DNS records.
- isle-core's Claude: nothing — the droplet is its OWN
  single-device isle; the home isle's networking is untouched.

## Open questions for Dustin (Q1/Q2 block pub-1; Q3/Q4 block pub-2/6)

1. **DNS**: is polari-systems.org's DNS hosted at DigitalOcean
   (or movable there) so `pol cert prod letsencrypt`'s DNS-01
   token path works as built?
2. **Droplet size**: start at Basic 4 vCPU/8 GB ($48/mo, the
   brief's minimum) and scale on measurement, or General Purpose
   dedicated from day one ($126/mo)? (Plan assumes Basic.)
3. **Showcase set**: which demo apps/datasets lead? (Plan
   proposes climate + motors + mathshapes; the full 16-app
   catalog stays browsable with install affordances.)
4. **Public auth policy**: anonymous read-only browsing + no
   signup? Open KC registration? A shared demo login? (Security
   posture differs a lot; plan assumes anonymous read-only +
   no public signup until decided.)
~~5. The variant name~~ — **CLOSED: `exhibit`** (decision 7).
6. **Public read-only MCP** — Dustin 2026-08-16: "likely fine,
   but it depends on how lightweight it would be and if it might
   become a limiting factor." → CONDITIONALLY IN, two gates:
   (a) **pub-0 measures it**: the MCP server is a thin process
   over the same REST surface, so its idle cost is small — the
   real risk is agent TRAFFIC amplifying the expensive endpoints
   (engine capability probes carry 4 s timeouts; topology
   resolves fan out). Measure tool-call cost on the demo module
   set alongside the boot/RAM baselines.
   (b) **pub-6 guardrails before exposure**: a public tool
   ALLOWLIST of cheap inspect-only tools (list/read/conventions;
   EXCLUDE live probes and anything that fans out), response
   caching for the derived answers, proxy rate limiting +
   concurrency cap on the MCP path so agents can never starve
   human demo traffic, and the mutation/propose tools absent
   entirely (not gated — absent).
   If (a) shows even the allowlisted surface pressuring the 4
   vCPU box, ship llms.txt + JSON endpoints only and revisit
   after a droplet resize — the fallback is already decision 8's
   floor, so nothing blocks on this.

## pub-0 evidence (measured 2026-08-16)

**Sizing: the demo set FITS 4 vCPU/8 GB with huge headroom.**
One-off boot of prf-backend:staging capped at 4 CPUs / 6 GB,
sqlite, `POLARI_LAZY_BOOT=on`, `POLARI_MODULES=` the proposed
demo set + its measured dep closure (topology, islemesh,
appstore, polariapps, simulations, techtree, climate, motors,
mathshapes + matrices, polariNoCode, simSpace, simSpace3D,
materialsScience — closures read from `/modules/<m>?withDeps=1`;
all showcase modules declare ZERO polari deps; simulations pulls
the other five):

- **secondsToCore 32.2 / secondsToFull 36.8, 9/9 online** —
  vs 325/434 s for the current staging set on the SAME host.
  Every lazy module admits in <1 s.
- **Backend RAM peak ~196 MiB** (VmHWM; cgroup peak 160 MiB).
  Live staging idle RSS for the rest: KC 368 MiB, MariaDB 13,
  file-store 77, proxy 9, frontend 5 — whole stack ≈650 MiB,
  compose limits total ≈3 GiB. 8 GB is not the constraint.
- Images: backend 937 MB, frontend 86, proxy 161 — trivial vs
  the 160 GB droplet disk.
- **MariaDB-vs-sqlite call: sqlite for polari data** (proven
  fine at this scale; techtree declares sqlite-local storage by
  construction). MariaDB stays ONLY as Keycloak's DB.
- **Q6 gate (a) answer: the read surface is cheap.** On the
  constrained box: /modules, /classInstanceCounts, /api/apps,
  /api/techtree/summary, /api/modules/status all ≤4 ms median;
  `/system-info` is the one heavy read (~110–170 ms) — exclude
  or cache it in any public allowlist. Engine-probe endpoints
  are absent from the demo set entirely.
- **Climate caveat (confirms pub-2's export→seed step):** the
  one-off seeds only 89 climate rows vs 3,325 live on prf-a —
  the ingested real series are NOT seed-borne; the exhibit
  needs the export→seed pass before the demo shows real data.
  techtree (222 rows), motors (107), mathshapes (68),
  simulations (466), materialsScience (324) ARE seed-borne.
- Harness kept re-runnable:
  `polari-framework/moduleService/dyn_proofs/pub0_sizing.py`
  (dyn5-proof pattern; run per dyn_proofs/README, repo at /app,
  add `--cpus=4 --memory=6g`). NOTE: `baseline_profile.py` is
  the dyn-5 module FLOOR, not a measurement tool; there is no
  `pol` verb for any of this yet.

**⛔ KC finding (worse than the memory believed): the 2026-07
"rotation" never rotated anything.** The working-tree
`prf-keycloak-admin.env` is a verbatim copy of the TRACKED
`.example`: the live staging client secret is the public
`REPLACE_ME…` placeholder, KC admin is `admin`/`admin`, and
`prf-mariadb/mariadb.env`'s three passwords are placeholders
baked into the 2-week-old volume. Five origin branches
(dev-msim-page-phase1/2/3/5, dev-wind-coupling) still publish
the OLD leaked secret at their tips, and leak commit 74d85c6
remains reachable from origin/dev. Rotation procedure (not
executed — Dustin's sign-off per Boundaries):
1. `pol security node-setup prod` (NOT staging — staging
   re-defaults admin to `admin`) or `pol security setup prod`
   with `POLARI_KC_ADMIN_PASS` set; rewrites the env with a
   fresh `openssl rand` secret + real admin password.
2. Restart prf-keycloak FIRST (entrypoint re-PATCHes the client
   secret), then the backend. Verify via `docker inspect`: no
   `REPL` prefix.
3. MariaDB password rotation = separate window (needs a fresh
   volume + data plan) — for the DROPLET it's free: fresh
   volume from day one, so run prod-setup there BEFORE first
   boot and the droplet never has this problem.
4. Delete/rewrite the 5 stale origin branches; history purge of
   74d85c6 optional once the secret is dead.
5. Hardening: change the `.example` placeholder to EMPTY —
   `configure_clients.sh` skips the PATCH on empty, so a
   missed setup fails closed instead of installing a public
   secret.

**Remaining pub-0 items:** the KC rotation execution (now ONE
command — see below — but run with Dustin present), Dustin's
DNS-at-DO confirmation + DO_API_TOKEN + droplet, and the climate
export→seed pass (can fold into pub-2).

## Deployment-security lifecycle (BUILT 2026-08-16, Dustin's call)

Dustin's directive: ALL security material (domain, passwords,
certs) is put in AT DEPLOY TIME; deployments detect existing
material, timestamp last update, flag >30 days stale, and the
same shells do create AND smooth update. Built on the existing
setup-shell chain (uncommitted, working tree):

- **`polari-rf-node/security-ledger.sh`** (NEW lib): TSV ledger in
  `.generated/security-ledger.tsv` — name/epoch/iso/source/
  sha256-fingerprint per credential artifact; `ledger_stamp`,
  `ledger_age_days` (fingerprint-checked, mtime fallback),
  `sec_placeholders` (secret-KEY values that are dev defaults,
  REPLACE_ME, or empty), `sec_is_stale` (`SEC_STALE_DAYS`=30).
  Values never enter the ledger.
- **staging-setup.sh / prod-setup.sh**: keep-or-rotate — existing
  REAL credentials are KEPT (age shown; stale ⇒ rotation
  suggestion, never auto); placeholder-bearing files are rotated
  UNCONDITIONALLY (fail closed); every write stamped. prod is
  interactive (keep? rotate?), staging honors POLARI_ROTATE_KC.
  mariadb.env placeholder warnings name the volume-coupling.
- **`pol security status`**: full inventory — exists/missing/
  placeholder counts, last-updated age, STALE flags, cert
  expiries (openssl), and a RUNNING-stack probe (docker inspect,
  prefix-only) that catches placeholder creds live.
- **`pol security gate [staging|prod]`**: the deploy-time check,
  wired into `pol node up` + `pol suite up` — prod FAILS CLOSED
  on missing/placeholder (override POLARI_SKIP_SECURITY_GATE=yes,
  loudly); staging warns. Verified: staging exit 0, prod exit 1
  on today's tree.
- **`pol security rotate [staging|prod]`**: the smooth update —
  re-runs the setup shell with POLARI_ROTATE_KC=yes, then rolls
  out IN ORDER: Keycloak first (entrypoint re-PATCHes the client
  secret), wait healthy, then backend; swarm-aware (stack
  redeploy + `service update --force` backend) and compose-aware
  (`--force-recreate` + exact-container health wait); ends with
  the live probe and refuses to call success while the running
  stack still shows placeholders.
- **`.example` fail-closed**: prf-keycloak-admin.env.example now
  ships EMPTY secret values — configure_clients.sh skips the
  PATCH on empty, so a missed setup can never install a tracked
  public string as the live secret (the root cause of the pub-0
  finding).

Verified: bash -n all shells; ledger lib unit-tested (fresh/
backdated/drift/missing); `pol security status` correctly flags
all 7 placeholder files + the running KC on this box. NOT run:
the actual rotation (`pol security rotate staging`) — one
command, but it bounces Keycloak + backend, so run it with
Dustin. Note: suite-level setup-polari-security.sh doesn't stamp
the ledger yet (ages fall back to mtime there) — fine for now,
stamp it when the suite path matters for pub-1.

**Isle-mesh integration (BUILT 2026-08-16, Isle-Mesh dev
ec6af24, CLI deb 0.1.24 installed on isle-core + republished to
apt.isle).** Dustin: the walkthrough lives in the ISLE SETUP
PHASE and the .deb install process; polkit where shells need
root. Delivered:
- `isle security creds|gate|setup` (secure-creds.sh + a polkit-
  aware port of security-ledger.sh; device ledger at
  /etc/isle-mesh/security-ledger.tsv): inventory covers polari-
  rf-node checkouts on merged boxes (the droplet case — setup
  RUNS prod-setup.sh, which prompts domain + passwords), the
  exposure-door htpasswds (ages, rotate-shown-once), and the
  isle CA expiry.
- `isle core-install` step 7/7 = production security: status
  always, interactive walkthrough offered on gaps,
  --skip-security defers loudly. Deb postinst points here —
  the deb itself never ships credentials.
- **The .isle→web upgrade is gated fail-closed**: `isle url
  expose` refuses to open an outside door while the gate fails
  (verified: refusal before any gateway container);
  `entrypoint enable` names the walkthrough.
- Verified on isle-core: clean gate=0, planted placeholder=1,
  stale flags, walkthrough output, deb carries the scripts.
  The droplet flow is now: install bundle → `isle
  core-install` → walkthrough prompts for real domain/passwords
  → gate clean → doors may open.
- **Walkthrough shape (Dustin, refined; CLI 0.1.25, ec6af24 +
  706cdb3): GENERIC self-hosting FIRST, providers as a POST
  step.** Steps 1–3 are provider-agnostic (credentials, doors,
  generic cert guidance — internal CA everywhere, browser-trust
  needs a real domain); step 4/5 asks "hosting with a particular
  provider?" [do/vps/home/none] — DigitalOcean gets the built
  machinery (DO DNS-01, DO_API_TOKEN asked at cert time and
  never stored, wildcard LE, auto-renew, droplet billing note);
  vps/home get honest guidance only; step 5/5 = the gate
  verdict. Provider steps are functions — new providers slot in
  as new cases.

## Grounding index

- pol-hub/ (site, Dockerfile, nginx.conf, README)
- docker-compose.prod.yml + prod-setup.sh + start-prod.sh +
  `pol suite --env prod` (suite.sh)
- setup-polari-security.sh (polari-systems.org CA/SANs)
- polari-cli/scripts/cert.sh (`prod letsencrypt`, auto-renew)
- ISLE_ONBOARDING_HANDOFF.md (+ §41 of the convergence handoff):
  apt-on-mesh, deb builders, membership rule, bootstrap gotchas
- custom-staging-domain memory (BASE_DOMAIN chain)
- module gating / mlb 503s / engine ladders (the demo honesty)
- ai-7 RemoteHostingOption rows (DO pricing, dated) + ai-6 gauge
- public-repos-hygiene memory (KC rotation pending — pub-0
  blocker)
