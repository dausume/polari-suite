# Dynamic modules — restoring web-era modularity (PLAN, PRIORITY ARC)

**Date:** 2026-08-10 · **Status: dyn-1/2/3 ✅ BUILT + PROVEN
2026-08-10** on `polari-framework` branch `dev-dyn-1` (3 commits,
NOT merged, NOT pushed — Dustin's review gate). Proofs ran in one-off
containers against `prf-backend:staging`, never touching the live
stack:

- **dyn-1** — 43 guarded import blocks + 34 endpoint gates extracted
  to `feature_imports.py` (data) + `module_endpoints.py`
  (per-module constructors) by asserting AST codegen;
  `polariServer.py` 4,544 → 3,199 lines; boot parity EXACT (1,849
  routes, 372 classes, 421 URIs, dev-vs-dev deterministic; the one
  row delta IS the new `allDefClassList` attribute). Drift guard
  rewritten, 23/23 — it now also covers the registry-only modules
  the old guard silently ignored.
- **dyn-2** — `POST /modules/{m}/admit`: gears admitted into a
  RUNNING gated server in **1.5s** (6 classes, 28 seeded rows, 6
  CRUDE routes + custom API post-listen); 404→200 with no restart;
  honest 409s for core packages and unmet requires; idempotent.
- **dyn-3** — `POST /modules/{m}/put-away`: **0.025s**, rows freed
  from RAM, DB tables KEPT; custom API + CRUDE answer **410 Gone**
  with the bring-back hint; reverse-requires 409 names dependents;
  re-admit restored the same 28 rows; boot-vs-readmit identical.
  Full lifecycle proven under BOTH monolithic and lazy boot.

- **dyn-2b** ✅ — `topology/placement_truth.py`: admit/put-away LAND
  in `ModuleAssignment` rows (upserted, sourced); the backend reports
  its live set as `TopologyObservation` `live-modules@<instance>`
  (boot + every change, both boot modes); `/api/modules/status`
  carries the authoritative placement read + the three-way coherence
  diff (declared / live+env / isle view) — drift NAMED with a
  suggestion, never auto-healed. Proven: put-away created
  `gears@prf-test` disabled, re-admit flipped it enabled, undeclared
  modules flagged with the `pol topology assign` suggestion.
  Isle-agent subscribe/refresh = the isle-core handoff item.

- **dyn-4** ✅ — `POST /modules/{m}/fetch-admit`: a module genuinely
  ABSENT at boot (boot logged "not downloaded") was fetched and
  admitted live in **1.8s** — all 6 classes recovered from the dyn-1
  declaration, 28 rows seeded, endpoints constructed, assignment row
  synced. Peer-sourced CODE refused; sources recorded as
  `ModuleSourceConfig` rows (auto_fetch stays off).
  ⚠ Found while proving it: **4 `pspp` classes are in `seed_pairs`
  but missing from `defClassList`** — the standing "silent no-table"
  gotcha, pre-existing, recorded not fixed.
  ⚠ Test-harness lesson: the backend image carries its own
  `/app/modules` copy on `PYTHONPATH`, so bind-mounting the repo
  elsewhere leaves module code importable and invalidates any
  absence test — mount the repo AT `/app`.

- **dyn-5** ✅ — `topology/baseline_profile.py` + `GET|POST
  /api/topology/baseline/{instance}`: the floor is **polariapps +
  appstore + islemesh** (describe what you offer, hand a client the
  way in, be locatable); core is unlisted because it is not
  optional; exclusions are named. Baseline = explicit rows, never an
  empty env; `?standDown=true` marks non-floor rows *transient*
  (reversible), never deleted. Plus **`?withDeps=true`** on admit:
  the requires-closure admitted in dependency order, one module at a
  time — refusing one level at a time was not a bring-up story.
  Proven: **baseline boot ready in 17.1s** with 3 modules; a bare
  `gears` admit refused naming mathshapes; `withDeps` admitted
  plant_morphology → scoring → aquaponics → mathshapes → gears in
  25.5s (83 classes, 564 rows) and `/api/gears/types` went 404→200;
  put-away dropped gears back out. No restart at any point.

- **dyn-6 + dyn-8 (backend half)** ✅ — the refs directory answers
  from the pre-gate list, so a class not served here appears with
  `servedHere:false` and a named state (`elsewhere` + `servedBy` /
  `put-away` / `not-admitted` + `bringUp`) instead of vanishing —
  the change that makes a move followable at all. It also declares
  `invalidateOn` (STOMP topic + 410) so clients stop holding a
  fetch-once map. App nav went **tri-state → quad-state**
  (`elsewhere` is what it could not say), every absent item carries
  `bringup.admit`, and each app gains a `modulePlan`. Proven:
  `app-business` reported `ready:false` with three missing modules,
  acting on its own suggestions admitted supplychain → bizops →
  odooconnect in **7.0s**, and the app then reported `ready:true`.
- **dyn-7** ✅ — `/api/topology/module-move/{plan,local-half}`:
  admit-on-gainer (overlap, so no unserved window) → data handoff →
  put-away-on-loser → rows+push. The backend stays the ledger:
  cross-instance steps come back as the caller's acts with their
  exact calls, consent + addressability are checked in the *plan*,
  and `local-half` **refuses without `dataMoved:true`** so the rows
  can never claim a move the data did not make. Proven: 6 classes /
  28 rows planned; local-half in **0.109s** turned the row
  *transient* (reversible), the API 410, the directory `put-away`
  with `bringUp`, placement not-live — no restart.

Remaining (frontend/shell, not backend): the Angular half of dyn-8
(consume `servedBy`/`invalidateOn`, cross-instance auth, route the
~69 hand-written module services through the directory) and the
shell fixes (`startRoute`, real deb probe identity, registry
`refresh` verb).
**Priority: this arc comes FIRST** (Dustin, 2026-08-10) — ahead of
`SCAN_RECONSTRUCTION_PLAN.md`, whose `scanning` module should be the
first *new* module built on this machinery.

**The goal in Dustin's terms:** polari-rf must be lightweight but
functional — quickly stand up a **baseline instance**, then bring
modules up **one at a time, dynamically, as needed**, pulling module
definitions into instances on demand; and **put modules away** when not
needed, so development fits the resources we actually have. Modules
should regain the level of modularity the web-app-only version had —
leveraging apps as we have now defined them.

## 0. What the archaeology actually found (so we revive the right thing)

Git history of `polari-framework` (earliest commit 2020-06-18; last
pre-Docker revision `7220dcd`, 2023-11-08) shows the web-era dynamism
was **real, and it was in-process**:

1. **Zero-declaration registration** — attach an instance to a manager
   and `__setattr__` → `getObjectTyping` → `makeDefaultObjectTyping`
   gave it typing, a tree position, and a DB table. Nothing was listed
   anywhere.
2. **Zero-declaration APIs** — `polariServer.__init__` looped
   `objectTypingDict` and minted a falcon route per typed class.
3. **Runtime constructor resolution** — `polyTyping.getCreateMethod()`
   resolved a class by `importlib` from a *recorded file path*;
   `polariServer.py` had **8 imports** and never imported the classes
   it served.
4. **A bootstrap registry by (className, filePath) strings** —
   `primePolyTyping()` — not by imported symbols.

It went dormant at two identifiable commits: `34aad50` (2026-02-12)
added the `if self.classDefinition is not None: return
self.classDefinition` short-circuit that bypasses the dynamic path, and
`3c68a13` (2026-02-16) introduced `defClassList` — the static manifest.
Today `polariServer.py` is 4,544 lines with ~80 imports, 44 guarded
import blocks, a giant `defClassList` literal, and ~40 inline endpoint
constructions, all executed once inside `__init__`.

**Honest correction to the memory:** *network* module-pulling was never
code in that era — the peer verbs were 1-of-5 implemented, and
"download the template" existed as a comment in `initPolari.py`. It
first became partially real 2026-07-03 (module bundles — rows, not
code). So this arc is not "restore a lost feature"; it is "restore the
lost in-process architecture AND finish the never-built network half."

**And: do not revive the old implementation.** `getCreateMethod`'s
~120 lines of hand-rolled path arithmetic broke on macs (`0327b65`)
and stayed brittle. The modern equivalent of everything it did is
`importlib.import_module('modules.<name>...')` against the
already-import-rooted `modules/` dir. Revive the architecture, not the
code.

**Topology archaeology (same pass): there is nothing to revive.** The
web era's multi-instance story was *vocabulary, not code*: sibling
server/system lists with no writers, a sink adapter that would
`NameError` on its first line, ARP discovery whose results nothing
consumed, `objectEndpoints`/"map to remote endpoints" as an empty dict
plus a comment, and `#WRITE CODE FOR APPENDING SUBORDINATE OBJECTS
HERE` where the sub-Polari hierarchy was meant to go. The first real
cross-instance execution is 2026-07-03 (peer handshake + module
bundles), and today's `topology/` (born 2026-07-08 as object-tree
rows) is a from-scratch rebuild on the 2020 object-tree substrate —
it preserved the good *ideas* (source/sink addressing →
`ModuleDependencyEdge`; `isoSys` → `PolariNodeMachine`; "which network
am I on" → `accessibility_scope`) and correctly dropped the rest. So
for topology, this arc's job is not restoration but **not breaking the
invariants the 2026 rebuild encodes** — see §6.

## 1. What already exists to build on (from the code investigation)

- **Runtime import + live CRUDE registration is already proven**: three
  code paths call `registerCRUDEforObjectType` post-boot
  (`modulesAPI._toggle_module` — live enable via `PUT /modules` for the
  two `polari*Module`-style dynamic modules; `createClassAPI`;
  restored dynamic classes). Falcon 4.2's router recompiles on
  `add_route`, no rebinding needed (narrow `_compile` race — serialize
  route mutations behind the quiesce gate).
- **`AdmissionWorker._admit` is idempotent and re-invocable** — it is
  `only_*`-scoped (`restoreTables` + `ensureDefinitionTables`). The
  worker's *orchestration* is boot-once; the per-module step is not.
- **The honesty surface exists**: `ModuleLoadingMiddleware` 503s for
  pending modules; `PolariModule` rows carry lifecycle
  (`pending|loading|online|failed|blocked|disabled`), `ModuleBootRecord`
  carries ETAs; STOMP pushes `/topic/PolariModule`; the frontend
  bringup panel renders it live.
- **Code fetch exists, unwired**: `ModuleSourceConfig` rows +
  `module_fetcher.fetch_module_project()` clone into `modules/<name>`
  (already an import root); `auto_fetch` knob defaults off;
  `POST /api/module-projects/fetch`. Registry `downloaded` is re-derived
  from the filesystem on every read.
- **Per-module pip deps are derivable and installable**:
  `module_dependency_tracker` AST-scans boundary imports,
  `plan_install()`/`install_packages()` run a real confirmed pip
  install into the running container (`POST
  /api/modules/dependencies/install`). Nothing calls it on fetch.
- **Data motion exists offline**: module bundles (rows over the wire),
  `module_data_move.py` (whole-class vs named-subset, quiesced,
  UNION-merge).
- **The app/frontend seams for mobility partially exist**: the app nav
  is tri-state and never hides (an absent module renders with a
  bring-up chip, `apps_nav.py`); `/api/refs/directory` maps class →
  `{module, instance, baseUrl}` from `ModuleAssignment` ∩ `PeerNode`
  rows and the Angular `ClassDirectoryService` consumes it for generic
  CRUDE + STOMP — the "frontend coordinates all backends" architecture
  is real, if narrow; the shell's `InstanceRegistry` is add-only and
  conflict-recording, so a moved/replaced instance can never silently
  hijack a registration.

## 2. What is blocking (the honest list)

1. **`polariServer.__init__` IS the boot sequence.** The 44 guarded
   import blocks, the `defClassList` literal, the ~40 custom-endpoint
   constructions, and the `seed_pairs` literals inside seed methods are
   all single-shot and inline. Nothing can re-run them per-module.
2. Gated-out classes are **discarded** at the `class_enabled` filter —
   there is no retained "all classes" list to admit from later.
3. `registry.all_online` is a **one-way latch** — once set, the honesty
   middleware short-circuits and a later-admitted module would serve
   empty data instead of 503.
4. "Disable" today is **destructive**: `_toggle_module(enabled=False)`
   → `purgeObjectType` → `dropTable`. There is no put-away.
5. Falcon has **no route removal** — CRUDE has the `_guard_purged` 404
   compensation, but custom module APIs have no equivalent guard.
6. Activation changes ride **container recreates** (~1–2 min per
   backend even lazy) — the isle `module move` recreates both ends.
7. Python cannot **un-import**: freed rows/routes yes, resident code
   no. Put-away reclaims data memory, not code memory. (Accepted
   limit; recreate remains the full-reclaim path.)
8. Fetched-at-runtime code: no `importlib.invalidate_caches()` call
   exists repo-wide; the stubbed symbols in `polariServer` globals
   need a defined un-stub path; container-layer pip installs are lost
   on recreate.

And on the **app/shell side** (investigated 2026-08-10 — today NO
running shell app follows a module move):

9. The refs directory is built from the **post-gate** `defClassList`
   (`refs_api.py`), so when a module moves off A, A's directory drops
   the class *key* entirely instead of answering "served by prf-b at
   <url>" — the one follow mechanism can't express a move. It is also
   fetched once per SPA load and never invalidated, and only generic
   CRUDE consumes it — all ~69 hand-written module services hard-wire
   the core base URL.
10. Cross-instance calls are unauthenticated: the auth interceptor
    attaches tokens only to the configured backend base URL.
11. The shell is inert about placement: `startRoute` and `scope=app`
    are parsed and **never used** (every app opens the instance root);
    the registration document is never re-fetched; the reachability
    probe machinery is dead on the launcher-deb path (the build
    scripts emit blank `identityUrl`/`instanceId`, so probes always
    read "reachable"); `shell.instance.list/switch` are implemented in
    Java and called by no frontend code.
12. Placement truth lives in **three unreconciled places**: the
    `POLARI_MODULES` env a backend actually booted with,
    `ModuleAssignment` rows, and the isle agent registry's
    `modes:modules:…` strings. The §49 app-placement resolver
    (`resolve_app_placement`, `/api/islemesh/appplan/{app}`) is
    orphaned in this repo — its only consumer is its own selftest.
    → addressed by dyn-2b: rows authoritative, env + isle strings
    demoted to derived caches, three-way coherence diff.
13. A module gated OFF answers a bare falcon 404 (no refusal body, no
    pointer to the new provider) — only *loading* modules get the
    honest 503.

## 3. The design: one manifest, one admission path, used by boot AND runtime

### dyn-1 — THE EXTRACTION (highest-leverage, everything hangs off it)

Turn each module's five inline contributions to `polariServer.py` into
**one declarative per-module manifest**, and make boot iterate
manifests instead of inline code:

```python
MODULE_MANIFESTS['motors'] = ModuleManifest(
    imports   = [('motors.motor_basis', ['MotorDesignDefinition', ...]),
                 ('motors.motor_seed',  ['SEED_MOTOR_DESIGNS', ...])],
    classes   = [...],                    # -> defClassList contribution
    seeds     = [...],                    # -> seed_pairs contribution
    endpoints = _construct_motors_endpoints,  # the extracted if-block
)
```

- Boot becomes: `for m in gated_modules: admit(m)` — the SAME function
  live admission calls. One code path, no drift between boot and
  runtime (extend the `selftest_lazy_imports` drift guard to assert
  the manifests match the modules on disk).
- The import-or-stub AND un-stub logic both read the same declaration
  (kills the 44 hand-written guarded blocks).
- Seeds become `only_classes`-scoped uniformly (today only
  `_seedSimSpace3D` honors scoping; the rest are all-or-nothing).
- This is also the long-standing file-size/decomposition preference
  applied to the 4,544-line `polariServer.py` — manifest per module,
  living next to the module's code (a `manifest.py` in each module dir
  or a section in `polari-modules.json`; prefer in-code so symbols are
  real).
- Retain the pre-gate class list (`allDefClassList`) so gated-out
  modules can be admitted later (fixes blocker 2).

**Everything below is small once dyn-1 exists.** Attempting dyn-2+
without it means duplicating boot logic and drifting.

### dyn-2 — live admission of an on-disk module (no restart)

`admit_module_live(module)`: typing pass for the module's classes →
extend `defClassList` + `bootRegistry.register_classes` → flip
`all_online` latch to a per-module condition (fixes blocker 3; the 503
window works during admission) → `_admit(module)` (tables + restore +
scoped seeds) → `registerCRUDEforObjectType` per class under the
quiesce/route lock → run the manifest's endpoint constructor →
lifecycle rows + boot record + STOMP, exactly as the admission worker
does. Ordering respects `dependency_order()` — a module admits only
after its `requires` (inheritance across modules makes this mandatory,
not cosmetic).

Surface: `POST /api/modules/{m}/admit` + `pol modules admit <m>
--instance <i>`. Posture per the standing rule: an explicit knob,
human-invoked (or proposal-gated at reversible-system level) — never
auto-applied. `ModuleAssignment` stays the source of truth:
assignment writes rows; *admit* makes them live without the recreate.

### dyn-2b — one placement truth (tie env, rows, and isle registry together)

Dustin, 2026-08-10: the three placement sources should be tied
together **so that a change made on either side smoothly propagates to
the other side and can be SEEN there.** The design: **`ModuleAssignment`
rows are the single authority; the other two become derived caches
that KNOW they are derived** — and every change, wherever initiated,
follows one propagation chain:

> change (polari API / `pol` / isle CLI) → **rows** → live admission
> or put-away on the affected backend (dyn-2/3) → STOMP
> `/topic/PolariModule` → isle agent registry refresh + SPA
> directory/nav refresh (dyn-8) → visible everywhere: the topology
> graph, the bringup panel, the app nav, and the isle side all show
> the new placement within seconds, without anyone re-deriving by
> hand.

An isle-initiated change writes rows through the polari API (it
already talks to the backend to deploy); a polari-initiated change
reaches the isle side through the same STOMP/poll refresh. Neither
side ever edits the other's cache directly — both watch the rows.

- **The env** (`POLARI_MODULES`) demotes to a bootstrap hint. It is
  already derived from rows at deploy (with a loud warning on manual
  override); with dyn-2 the *running* set tracks rows live, so env
  drift can only exist between a row change and the next
  recreate — and it becomes visible: at boot the backend **reports
  back** its actually-booted module set as an observation
  (`TopologyObservation` already exists from top-1 for exactly this
  observed-vs-declared shape) rather than the env being silent.
- **The isle agent registry** (`modes:modules:…` strings) demotes to
  a derived cache: the agent refreshes it from the instance's own
  authoritative report (`/api/modules/status`, or the identity probe
  extended with the module set) instead of being independently
  maintained — with a recorded derivation timestamp, never hand-edited
  truth. The STOMP `/topic/PolariModule` push that admission already
  emits doubles as the refresh signal for an agent that subscribes
  (polling is the fallback). ⛔ Boundary respected: the agent/CLI code
  lives on isle-core — this repo ships the authoritative read surface
  and the contract; the isle-side change is a handoff item, not work
  here.
- **The three-way diff**: extend `islemesh_coherence.py` (which
  already joins isle↔polari topology) to compare rows vs booted-set
  vs isle strings per instance, reporting drift as evidence with a
  suggested refresh action — never auto-healed, per the knob rule.
  This also retires §2 blocker 12 and gives the orphaned §49 resolver
  a truthful input to resolve against.

### dyn-3 — put-away (non-destructive deactivation)

A new teardown that is NOT `purgeObjectType`: drop the module's rows
from in-memory `objectTables` (free RAM), remove typing + CRUDE from
the live registries, shrink `defClassList` — **leave DB tables
intact** so re-admission is `restoreTables` away. One middleware rule
(extend `ModuleLoadingMiddleware`): requests resolving to a put-away
module answer `410 Gone` + "module put away — POST /api/modules/{m}/
admit to bring it back" — this covers custom APIs too (fixes blocker
5). Persist via `moduleState` so the next boot agrees. Honest framing
everywhere: put-away frees data memory and quiets the API; imported
code stays resident until the next recreate (blocker 7).

### dyn-4 — pulling module definitions into an instance (the network half)

Fetch + admit, end to end: `POST /api/module-projects/fetch` (or
`ModuleSourceConfig.auto_fetch` for pre-approved sources) →
`importlib.invalidate_caches()` (new — required) → per-module pip
deps via `plan_install()`/`install_packages()` with the existing
confirm knob → manifest import (un-stub from the dyn-1 declaration) →
`admit_module_live()`. Registry `downloaded` self-corrects from the
filesystem.

Two honest sub-problems with named answers:
- **Dep persistence:** a pip install into the running container is
  lost on recreate. Record accepted packages on the instance (a
  `ModuleDependencyState` row or an instance-local requirements
  overlay re-applied at boot Phase C) — never silently re-lost.
- **Provenance/trust:** fetched code is code execution. Fetch sources
  stay the `ModuleSourceConfig` allowlist (git/github/file; `peer` is
  refused honestly today and stays refused until signing exists), and
  fetch+admit of a NEW source is a proposal, not a default.

### dyn-5 — the baseline instance

A sanctioned minimal profile: core packages + `polariapps` +
`appstore` + `islemesh` (the pieces that let an instance *describe and
acquire* everything else) and nothing more. `pol node up --env
<tier> --baseline` (or a `baseline` topology seed) writes the minimal
`ModuleAssignment` rows — the derive-refuses-on-zero-rows rule stays,
baseline is explicit rows, not an empty string. Target: core-ready in
~1 min on modest hardware, everything else arriving via dyn-2/dyn-4
one module at a time, watched live on the bringup panel. This is the
"quickly put up baseline polari-rf instances, then gradual bring-up"
sentence, made literal.

Follow-on (separate, optional): slim the base image's global
`requirements.txt` toward core-only once dyn-4 dep handling is proven,
so the image itself lightens — measured, not assumed.

### dyn-6 — apps drive module presence

Apps as defined (`PolariAppDefinition.modules_json`) become the demand
signal: opening/installing an app whose modules aren't admitted yields
an evidence-bearing **suggestion** ("this app needs gears, motors —
admit now? ~40s each, ETA from boot records") that executes dyn-2/dyn-4
on confirm; a module no app references becomes a put-away suggestion
with the same evidence posture. Store surfaces (appstore/islemesh
catalog) show module footprint per app. Never auto-applied — the knob
rule holds.

### dyn-7 — zero-downtime module move (closes the §48/§49 gap)

Replace the recreate-both-backends move with: admit on the gaining
instance (dyn-2/4) → data handoff (wire `module_data_move` in, quiesced,
online window bounded) → put-away on the losing instance (dyn-3) →
**push the placement delta** (STOMP, see dyn-8) so open clients
re-point without a reload. This is the "zero-downtime module reload +
stateful data handoff" the mesh-convergence handoff names as
documented-but-unbuilt. Without the last clause a move is
zero-downtime for the backend and still a broken page for the user.

### dyn-8 — apps follow moves (the shell/frontend half)

The 2026-08-10 investigation's verdict: module moves are safe for
topology bookkeeping and honest in the nav map, **but no running app
follows a move today**. The client half, in leverage order:

- **Placement-aware directory** — the single change that unlocks the
  rest: `/api/refs/directory` (and `/api/apps/nav`) answer from the
  dyn-1 retained pre-gate class list, so an instance that no longer
  serves a module says `servedBy: {instance, baseUrl, wsUrl}` instead
  of dropping the key. Nav goes tri-state → quad-state:
  `enabled | absent | unknown | elsewhere` — an `elsewhere` item
  carries its target, not an "install it here" chip.
- **Live invalidation** — STOMP `/topic/PolariModule` (already pushed
  by admission) triggers `ClassDirectoryService`/`AppsNavService`
  refresh; plus refresh-on-`410` in an HTTP interceptor (the dyn-3
  410 becomes the client's re-route signal, with `servedBy` in its
  body).
- **Cross-instance auth** — the auth interceptor attaches tokens to a
  trusted-origins list derived from the directory (one KC realm makes
  this sound; say so explicitly), not just the home base URL.
- **Module services route by module** — a module-aware base-URL helper
  so the ~69 hand-written services follow the directory the way
  generic CRUDE already does (mechanical sweep).
- **Shell honors placement** — `startUrl()` = `webUrl + startRoute`
  (or `/app/<name>` for `scope:'app'`) — a ~3-line fix; the deb build
  scripts emit real `identityUrl`/`instanceId` so probes mean
  something; a `refresh` verb on `InstanceRegistry` (distinct from
  add-only merge) lets a re-fetched registration document update an
  existing instance instead of being recorded as a conflict.
- **One instance at a time stays true — and honest**: wire
  `shell.instance.list/switch` into the SPA so an `elsewhere` module
  can offer "switch to prf-b"; a genuinely split app (modules across
  two instances) is *named* as such in the nav rather than silently
  half-broken. Serving a split app from one page is the directory's
  job (CRUDE + services follow per-module URLs), not the shell's.

## 4. Suggested order + what proves each step

1. **dyn-1 extraction** — proof: boot parity (same modules, same
   routes, same seeded counts before/after; the render/parity habit
   applied to boot), selftests + drift guard green. No behavior change.
2. **dyn-2 admit-live** — proof: baseline-boot an instance, admit
   `gears` live, `GET /api/gears/types` 200 without any restart;
   503→online transition visible on the bringup panel.
   **dyn-2b one truth** — proof of propagation, both directions: flip
   an assignment via the polari API and watch the isle registry + app
   nav update without manual refresh; flip one via the isle CLI and
   watch the topology graph + bringup panel update; then hand-perturb
   one cache (stale isle string) and the three-way diff names it with
   the suggested refresh.
3. **dyn-3 put-away** — proof: put `gears` away, API answers 410 with
   the bring-back hint, DB table intact, re-admit restores rows;
   memory delta measured and reported honestly.
4. **dyn-4 fetch+admit** — proof: delete `modules/gears` from a dev
   container, fetch from its `polari-module-gears` repo, admit, 200 —
   the full "pull a module definition into an instance" loop.
5. **dyn-5 baseline** — proof: `pol node up --baseline` wall-clock
   measured; then bring up the 8 focus modules one at a time.
6. **dyn-6 app-driven** — proof: install an app from the store on a
   baseline instance; its module closure is suggested, confirmed,
   admitted; app works.
7. **dyn-7 move** — proof: `module move` with no container recreate,
   data intact both sides (the instance-data-persistence lesson:
   verify rows, not vibes).
8. **dyn-8 apps follow** — proof: with an app open in the shell, move
   one of its modules prf-a → prf-b; the open page re-points (nav
   shows `elsewhere`→`enabled`, CRUDE + module service calls land on
   prf-b, authenticated) without a reload. The quick wins inside
   dyn-8 (`startRoute` honored, real probe identity in the deb
   scripts, directory-from-pre-gate-list) can land earlier — the
   directory fix naturally rides dyn-1/2, the shell fixes are
   independent of everything.

## 5. Topology invariants this arc must NOT break

The 2026 topology rebuild encodes rules that live admission/put-away/
move could silently violate if not named:

- **Transient ghosts are the reversibility contract** — a former
  placement becomes `state='transient'` (visible, inert, one click
  back), never a deleted row. dyn-3 put-away must ghost, not delete.
- **`placement_check` decides who may receive modules** — only Polari
  instances (workers/engines ARE Polari instances); auth, infra, and
  integrated apps (psc) never receive modules; engine-capability
  modules only land on engine/worker kinds.
- **Refuse-on-empty** — `modules_env_for_instance` with zero rows
  refuses rather than emitting `''` (= the monolithic all-modules
  default). The dyn-5 baseline is explicit rows, never an empty env.
- **`contested` is a coherence fault, not a merge** — two modules
  defining one class is named and refused; live admission must run the
  same check before extending `defClassList`.
- **Bilateral consent before cross-instance anything** — fetching from
  or serving to a peer rides an approved `PeerAgreement`; dyn-4 adds
  no back door.
- **An explicit env knob always wins** — the provider-registry ladder
  rule: routing never overrides a human's configuration.
- **The backend is the ledger, not the executor** — move execution
  stays a human-invoked `pol` command; dyn-2/3/7 change what that
  command *does* (no recreate), not who invokes it.
- **sqlite is local by construction** — a module move between sqlite
  instances is a data *handoff* (`module_data_move`), never a shared
  file.

## 6. Boundaries — named so they don't smuggle themselves in

- **Deploys stay human.** Admission/put-away are explicit acts (API,
  CLI, or confirmed suggestion). `auto_fetch` remains per-row opt-in.
- **Code memory is not reclaimed by put-away** — recreate remains the
  full-reset. Say so in every surface that offers put-away.
- **Peer-sourced code stays refused** until there is a signing story.
  Bundles (rows) from peers remain fine — data is not code.
- **This arc does not move data between instances** except dyn-7,
  which reuses the existing quiesced mover rather than inventing one.
- **isle networking stays on isle-core.** dyn-7 changes what the isle
  CLI *calls*, not where it lives.

## 7. Pre-existing issues found during these investigations (recorded
so they aren't re-discovered; several are one-line fixes)

- `startRoute` and `scope:'app'` are parsed everywhere and consumed
  nowhere — every shell app opens the instance root (`ShellFrame.
  startUrl()` returns bare `webUrl`).
- The launcher/store deb build scripts emit blank
  `identityUrl`/`instanceId`, so the shell's reachability probe always
  reports "reachable" on the deb path — the wrong-instance machinery
  only works for store-generated registration documents.
- `refs_api.py` builds the class directory from the post-gate
  `defClassList` (see §2 blocker 9).
- The native OIDC client (`OidcClient`/`Pkce`) is built and referenced
  only from tests — production login is the SPA's PKCE inside JCEF
  (fine, but the dead code misleads).
- `MOVE_SUBJECTS['odoo']` declares kind `server-move`, which is not in
  `MOVE_KINDS` and has no step plan — `move_plan(subject='odoo')`
  returns the no-step-plan refusal.
- Three unreconciled placement sources (§2 blocker 12) and the
  orphaned §49 resolver.

## 8. Open questions for Dustin

- Baseline contents: is core + polariapps + appstore + islemesh the
  right floor, or should appstore itself be admit-on-demand too?
- Authority: should live admission be a plain authenticated API call,
  or ride the proposal gate (propose → human execute) like other
  consequential ops? (Plan assumes proposal-gated for *fetched* code,
  plain-but-explicit for already-on-disk modules.)
- Manifest home: `manifest.py` inside each module dir (symbols real,
  moves with the module — the plan's preference) vs a section in
  `polari-modules.json` (single file, but strings-not-symbols)?
- Does dyn-6's app-driven admission apply to the shell/store install
  flow too (installing an app on a phone nudges the *instance* to
  admit the app's modules), or only to in-browser app opening?
