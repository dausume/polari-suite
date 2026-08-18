# Module Projects — modules as their own downloadable sub-projects

## STATUS 2026-07-18 (late session): mp-2/mp-3 PREP BUILT — Dustin runs module-projects/ batches

All the preparation an agent can do without push/repo-create rights
is BUILT + verified on staging; the human-run remainder is scripted
in **`module-projects/`** at the suite root (read its README first).

- **mp-3 lazy core (BUILT):** polariServer's 113 feature-module
  import lines now sit in 30 per-module guarded blocks
  (try/except + exact stub tuples: SEED_* -> [], classes -> None;
  a downloaded-but-broken module still raises LOUDLY). Endpoint
  constructions gate on `feature_available` (downloaded AND
  module_gating-enabled); defClassList drops stubbed Nones with an
  honest boot line; /modules + module detail return
  'not downloaded — pol modules get <m>' rows. New seam:
  `moduleService/module_loading.py` (FEATURE_MODULES,
  FEATURE_REQUIRES from the cross-import survey, CORE_REQUIRED
  {topology,resources,xr} which move but can never drop).
  DRIFT GUARD: `moduleService/selftest_lazy_imports.py` (15 checks)
  ast-parses polariServer.py — an import added without its stub
  fails the suite. Proof: in-container import of
  polariApiServer.polariServer with modules/biomining hidden
  succeeds with the honest [ModuleLoading] line.
- **register (FILLED):** modules/polari-modules.json lists ALL 20
  feature modules + 2 legacy with kind/path/repo/description plus
  NEW fields `wave` (mp-4 order, 0 = already moved), `requires`
  (cross-feature imports: aquaponics->plant_morphology+scoring,
  dmvdata->scoring, mathshapes->aquaponics+plant_morphology,
  electrodevice->hwdigital, zones->scoring), `required_by_core`
  (xr, resources).
- **mp-2 CLI rails (BUILT):** `pol modules publish <m> [--repo url]`
  = git subtree split --prefix=modules/<m> + push (prints every git
  command; refuses while the module is still at the framework root);
  `pol modules register <name> [--vendor url|--kind|--path|--repo|
  --desc]` upserts; get refuses double-download; drop refuses
  required_by_core + downloaded dependents; registry shows sizes +
  waves + requires.
- **Cosmetic fixed:** managedFiles.openFile now honors self.Path —
  the 'File Instance ... outside of path scope' boot noise went
  304 -> 0 (covers modules-dir classes AND the long-standing core
  noise).
- **Batches for Dustin (`module-projects/`):** 00-preflight ->
  01-split-already-moved (biomining/microalgae repos) -> 10-wave.sh
  <1..6> (git mv + register + rebuild + selftests, wave list READ
  FROM the register) -> 20-split-module.sh <m> (gh repo create +
  publish) -> 90-verify-all.sh (full paint incl. the
  boots-without-biomining proof). Known env-file/pol-proxy staging
  gotchas are baked into the lib.
- **Branches:** framework `dev-mp-3-lazy-core` (off
  dev-mp-1-module-projects), cli `dev-mp-2-publish-cli` (off
  dev-mp-1-modules-cli). NOT on dev, NOT pushed (review gate).
- **Notated behavior change:** ElectroDeviceAPI now gates with the
  rest of electrodevice (it was the one ungated electrodevice
  endpoint — a POLARI_MODULES node without electrodevice previously
  still served /api/electrodevice; now it honestly does not).

**Dustin 2026-07-18:** the project is on its way to becoming enormous.
Keep the BASIS everyone operates off; the downstream modules become
their own projects, downloaded/uploaded as needed. Feature modules
sitting in the framework root was a mistake — move them into
`modules/` iteratively, then split each into its own git repo managed
through the pol CLI (which automates the git interactions). Anyone
downloading Polari gets a realistic-sized core and pulls in modules
gradually; anyone can make their own.

## Architecture

- **Core (stays in polari-framework root):** the basis packages —
  objectTree*, polariApiServer, polariDBmanagement, polariDataTyping,
  moduleService, polariPeers, accessControl, topology, polariapps,
  matrices/simulations/simSpace* (no-code + sim substrate), plus the
  FRAMEWORK_BOUNDARIES set. These define what a module IS.
- **Feature modules (move to `modules/<name>/`):** aquaponics,
  biomining, microalgae, nutrition, tanks, plant_morphology,
  waxsupply, supplychain, dmvdata, electrodevice, hwdigital, hwfpga,
  mathshapes, waxprint*, zones, grpcbridge*, resources*, scoring*, xr,
  testing, techtree*, … (*those with deep polariServer coupling move
  in LATER waves, after their seed/endpoint imports are made lazy).
- **Import seam (already exists + hardened in mp-1):** `modules/` is
  a sys.path root — `initLocalhostPolariServer` inserts it at boot,
  and `sitecustomize.py` (mp-1) inserts it for EVERY python run from
  the framework root (host selftests, `python3 -m`, the tt-11
  subprocess runner, docker exec). Moved modules keep their import
  names: `import biomining` works unchanged; NO import rewrites.
- **Registry (mp-1): `modules/polari-modules.json`** — the small
  inspectable config: every known module with `kind`
  (official | vendor | self), `downloaded` (is the code locally
  present — synced against the filesystem, never trusted stale),
  `path`, `repo` (its own git remote once split; '' until mp-2), and
  `description`. This is the file a human reads to answer "what
  exists, what do I have, where does the rest live".
- **Self modules:** user-created modules (the existing Create Module
  flow + createClassAPI custom classes) register in the SAME registry
  with kind `self` — making your own module is the same shape as
  using an official one.

## Phases

- **mp-1 (THIS SLICE — built):** `modules/` import seam hardened
  (sitecustomize), registry JSON + loader (filesystem-synced
  `downloaded` flags, self-module registration), first modules moved
  (`biomining`, `microalgae` — leaf modules, git-mv preserving
  history), all discovery/tooling taught the second root (selftest
  discovery, pip-suggest exclusions, /modules list + drill-in,
  `pol modules` list/selftest/registry), `pol modules get|drop` rails
  (honest "not split yet" until mp-2).
- **mp-2 — sub-project split:** each moved module becomes its own git
  repo (polari-module-<name>); registry `repo` fields filled;
  `pol modules get <m>` = git clone into modules/ + registry flag;
  `pol modules drop <m>` = verify clean/pushed then delete local copy
  + flag false; `pol modules publish <m>` = init/push a repo from a
  local module (official PR flow vs vendor remote). pol automates the
  git CLI; every command prints the git it runs.
- **mp-3 — core boots without downstream:** polariServer's seed/class
  imports of feature modules become registry-driven lazy loads
  (import only when downloaded+enabled); a missing module = honest
  "not downloaded — pol modules get <m>" everywhere it would surface
  (pages, plans, tech-tree theory refs, Polari-Apps readiness).
- **mp-4 — iterative migration waves:** remaining feature modules
  move in dependency order (leaves first; waxprint/scoring/techtree
  last — they carry polariServer seed wiring that mp-3 must lazify
  first). Each wave: git mv → selftests → deploy → next.
- **mp-5 — size + distribution:** per-module size in the registry,
  `pol modules get` progress/size warnings, Polari-Apps deploy pulls
  missing modules (plan already names them 'missing — build/install
  first' → becomes 'pol modules get').

## EXECUTION APPENDIX for the next agent (Dustin 2026-07-18)

**mp-2 concrete steps (repo split):**
1. Naming: one repo per module, `polari-module-<name>` (e.g.
   polari-module-biomining). ⚠️ ALL current repos are PUBLIC
   ([[public-repos-hygiene]]) — assume new module repos are public
   too; no secrets in module code (none exist today; keep it true).
2. Split preserving history: `git subtree split
   --prefix=modules/<name>` in polari-framework → push the branch to
   the new repo's main. The module stays in-tree until mp-3 makes
   the core boot without it — during the overlap the in-tree copy is
   AUTHORITATIVE and the repo mirrors it (`pol modules publish`
   re-pushes the subtree).
3. Fill `repo` in modules/polari-modules.json — the moment it is
   non-empty, `pol modules get/drop` go live (rails already built +
   refusing honestly).
4. `pol modules publish <name>` (new): runs the subtree split +
   push, prints every git command it runs. Vendor flow: `pol
   modules register <name> --vendor <git-url>` writes a registry
   entry with downloaded=false; get clones it.
5. Do mp-4 waves in this order (leaves → coupled): nutrition, tanks,
   plant_morphology, waxsupply, supplychain, dmvdata, mathshapes,
   electrodevice, hwdigital, hwfpga, zones, xr, aquaponics,
   grpcbridge, resources, waxprint, scoring, techtree, polariapps —
   the last four ship polariServer seed/endpoint imports that mp-3
   must lazify FIRST (registry-driven `if downloaded+enabled:
   import` in polariServer's import block + seed loop + endpoint
   constructions; a missing module surfaces as 'not downloaded —
   pol modules get <m>' in /modules, Polari-Apps plans, tech-tree
   theory refs).
6. Every wave ends: module selftests from the new home + suite boot
   + pol modules selftest <m> in-container + deploy.
Known cosmetic to fix alongside mp-3: functionalityAnalysis file
tracker logs 'File Instance ... outside of path scope' for
modules-dir classes (teach it the second root).

## Interactions with what exists
- PolariModule rows (source_kind git/github/file/peer) are the
  RUNTIME registry; polari-modules.json is the REPO-LEVEL config the
  two stay coherent through module_registry.sync.
- Polari-Apps plans key on module availability — mp-3 turns their
  'missing' rows into get-commands.
- The backend Docker image COPYs the whole tree — modules/ ships
  automatically; image slimming is a consequence of mp-3/mp-4 (core
  image + module layers), not a prerequisite.
