# Handoff — dynamic modules: what was BUILT, how to TEST it, what's NEXT

**Date:** 2026-08-11 · **Branch:** `polari-framework` `dev-dyn-1`
(9 commits) · **Status: BACKEND COMPLETE + PROVEN in one-off
containers. NOT merged to `dev`, NOT pushed, superproject pointers
NOT committed — Dustin's review gate. Never deployed to the live
stack.**

Plan: `DYNAMIC_MODULES_PLAN.md`. Why this arc jumped the queue:
Dustin, 2026-08-10 — *"if dynamic modules are not working then polari
itself is not currently in a working state."*

## 1. What exists now (the whole surface, one table)

| Act | Call | Proven |
|---|---|---|
| admit an on-disk module | `POST /modules/{m}/admit` | gears live in **1.5s**, 404→200, no restart |
| …with its dependency closure | `POST /modules/{m}/admit?withDeps=true` | plant_morphology→scoring→aquaponics→mathshapes→gears, **25.5s**, 83 classes / 564 rows |
| pull a module's DEFINITION in | `POST /modules/{m}/fetch-admit` `{sourceRef, sourceKind, installDeps}` | module absent at boot → live in **1.8s** |
| put a module away | `POST /modules/{m}/put-away` | **0.025s**, tables kept, API 410, re-admit restored identical rows |
| baseline floor | `GET\|POST /api/topology/baseline/{instance}` | boot **17.1s** with 3 modules |
| placement truth + drift | `GET /api/topology/placement`, also inside `/api/modules/status` | rows authoritative; 3-way diff names drift |
| move between live instances | `POST /api/topology/module-move/plan` then `.../local-half` | plan refuses honestly; local half **0.109s**, row→transient |
| devices + what they grant | `GET /api/topology/devices` | isle devices ⋈ observed machines, gaps named |
| consumed vs available | `GET /api/topology/resource-ledger` | staging-a 4 threads/15.9GB vs 2/320MB claimed |
| app module readiness | `GET /api/apps/nav[/{app}]` → `modulePlan` | app-business ready:false → acted → **ready:true in 7.0s** |
| class → who serves it | `GET /api/refs/directory` | classes not served here carry `servedBy`/`bringUp` |

## 2. How to TEST it (do this before merging)

Everything below ran green in one-off containers; none of it has run
on the live swarm. **Test in this order** — each step's failure mode
is cheaper than the next.

### 2a. Selftests (fast, no server)
```
cd polari-rf-node/polari-framework
python3 -m moduleService.selftest_lazy_imports      # 23/23 — the drift guard
docker run --rm -u 1000:1000 -e HOME=/tmp -v $PWD:/app -w /app \
  --entrypoint python3 prf-backend:staging -m topology.selftest_topology     # 52/52
  # …same for modules.polariapps.selftest_apps (45/45), polariRefs.selftest_refs (51/51)
```

### 2b. Boot parity — the dyn-1 safety net
The extraction must change NOTHING about a normal boot. Compare a
`dev` worktree against the branch with
`scratchpad/parity_dump.py` (routes / defClassList / uriList /
tables). Expected: 1849 routes, 372 classes, 421 URIs, identical.
⚠ **Mount the repo AT `/app`** — the image carries its own
`/app/modules` copy on `PYTHONPATH`, so mounting elsewhere leaves
module code importable and silently invalidates any absence test.
(This bit me: my first dyn-4 proof was bogus for exactly this
reason.)

### 2c. The live loop, on a REAL staging instance
Not yet done — this is the first thing to try after review:
1. `pol node up --env staging` as usual, then
   `GET /api/modules/status` → confirm `placement` block present and
   coherence findings sensible for prf-a.
2. `POST /modules/gears/put-away` → `/api/gears/types` should 410
   with the bring-back hint; **check the frontend does not white-
   screen** (it has never seen a 410 from an API before — the
   Angular half is unbuilt, see §4).
3. `POST /modules/gears/admit` → 200, rows restored, page works.
4. Repeat under `POLARI_LAZY_BOOT=on` (both modes were proven in
   containers, but never on the swarm).
5. `GET /api/topology/resource-ledger` on the real topology and
   sanity-check the numbers against `htop`/`docker stats`.

### 2d. What to watch for specifically
- **Falcon route mutation on a serving app.** `add_route` recompiles
  the router; admissions are serialized behind a lock, but this has
  never run under real concurrent load. Watch for 404s on unrelated
  routes during an admit under traffic.
- **Memory.** Put-away frees rows and quiets the API; it does NOT
  reclaim imported code (Python can't un-import). Measure the actual
  RSS delta so the honest claim stays honest.
- **Seeds.** `_seedSimSpace3D` honors `only_classes`; the other seed
  methods are all-or-nothing (idempotent, but slow). A live admit
  re-runs more than it strictly needs.
- **The 410 is new.** Nothing in the SPA or shell interprets it yet.

## 3. Known defects found along the way (NOT fixed — pre-existing)

1. **4 `pspp` classes are in `seed_pairs` but missing from
   `defClassList`** → the standing "silent no-table" gotcha, live in
   the codebase now (`BenchmarkCase`, `PrecursorSource`,
   `ResearchTool`, `ThresholdReactionWindow`).
2. `modules/mathshapes/cad_minio.py` `presigned_get` signs against
   the INTERNAL client → browser-unusable URLs.
3. `prf-cad-engines` missing from `pol-build/registry/services.yml`.
4. Registry drift: `pspp`/`magnetics` declare `requires:
   ["materialsScience"]` but the key is `materials_science`, so those
   edges resolve to nothing; the `video` module is unregistered.
5. Shell: `startRoute` and `scope=app` parsed and never used; the
   launcher-deb build scripts emit blank `identityUrl`/`instanceId`
   so probes always read "reachable".
6. `MOVE_SUBJECTS['odoo']` declares a kind with no step plan.

## 4. What's NEXT on this arc (frontend/shell half — unbuilt)

The backend contract is proven; nothing consumes it yet:
- **Angular**: consume `servedBy`/`invalidateOn` from
  `/api/refs/directory`; refresh the directory + nav on STOMP
  `/topic/PolariModule` and on any 410; render the quad-state
  (`elsewhere` with its target, `absent` with the admit act).
- **Cross-instance auth**: the interceptor attaches tokens only to
  the home base URL — needs a trusted-origins list from the
  directory.
- **~69 hand-written module services** hard-wire the core base URL;
  route them through the directory by module (mechanical sweep).
- **Shell**: honor `startRoute` / `scope=app` (~3 lines), emit real
  probe identity in the deb builds, add an `InstanceRegistry.refresh`
  verb distinct from add-only merge.
- **isle-core handoff**: the agent should refresh its
  `modes:modules:` strings from `GET /api/modules/status` and
  subscribe to `/topic/PolariModule`, rather than maintaining its own
  placement truth. Contract is live on this side.

## 5. Back to the originally-planned round

This arc interrupted the round we had actually planned. Resuming
order, unchanged by the interruption:

1. **`SCAN_RECONSTRUCTION_PLAN.md` (photogrammetry)** — the priority
   Dustin named on 2026-08-10, now genuinely unblocked: the
   `scanning` module should be **the first new module built
   manifest-first** on dyn-1 (a `feature_imports` entry + a
   `module_endpoints` constructor — no new inline blocks in
   `polariServer.py`), which also makes it admittable/put-awayable
   from day one. Its §0 four-layer split (scanning module → recon
   engines image → shell camera capability → capture app) stands.
   Blocking first step is still the **LICENSE GATE** (§1).
2. **`LIVEKIT_COLLABORATION_PLAN.md`** — Phase 0 remains proving UDP
   media on the LAN; confirmed absent suite-wide (no `/udp`
   mappings, no nginx `stream`, netledger is TCP+CIDR only).
3. **`CREDENTIAL_ROTATION_PLAN.md`** — still TABLED, do not execute
   without Dustin.
4. **`ISLE_ETHERNET_ROUTE_PRIORITY_HANDOFF.md`** (new, 2026-08-11) —
   the wired-over-wifi default-route bug that killed a session;
   isle-core's box, its Claude, `ipv4.never-default` is the fix.

## 6. Merge checklist when review passes

```
cd polari-rf-node/polari-framework && git checkout dev && git merge dev-dyn-1
cd ../..                # commit submodule pointers innermost-first:
#   polari-framework -> polari-rf-node -> polari-suite
polari-cli/shells/push-all-dev.sh            # dry-run first
polari-cli/shells/push-all-dev.sh --push     # Dustin's manual step
```
