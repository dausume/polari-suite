# MODULE LAZY BOOT — incremental module bring-up + frontend visibility

**Status: DRAFT 2026-07-25 — nothing built. Blocked until the swarm msci
instance is confirmed healthy (backend seed verified end-to-end).**

## Context — what "mp" was, and why this plan exists

`mp-N` = phases of **MODULE_PROJECTS_PLAN.md** ("module projects", built
2026-07-18/19): mp-1 module register, mp-2 split to `polari-module-*` repos,
**mp-3 = "lazy core"**, mp-4 the migration waves that moved all 22 feature
modules into `modules/`.

What mp-3's lazy core already gives us (all on the deployed branches):
- Core boots **without downstream code present**: polariServer's feature
  imports are guarded per module (`moduleService/module_loading.py`);
  absent code stubs its symbols and lands in `MISSING_FEATURE_MODULES`
  with an honest "not downloaded" message. Broken-but-present code stays
  a LOUD failure.
- A gating knob that already exists: env **`POLARI_MODULES`** (comma list,
  `polariApiServer/module_gating.py`) — only named modules (plus core)
  are enabled; `gate_summary()` reports the decision.
- The register `modules/polari-modules.json` (kind/downloaded/repo/wave/
  requires), `FEATURE_REQUIRES` dependency edges, and
  `module_dependency_tracker.py`.

What mp-3 does **not** give us — the gap this plan closes ("escalate
mp-3"): gating is boot-time and all-or-nothing per process. Every enabled
module still imports, seeds, and registers its endpoints **serially,
before the server listens**. Observed on the swarm bring-up 2026-07-25:
~280 classes' seeds + verbose `[DB-Save]` logging + 0.4-CPU limit →
15-25 min of dead air, healthcheck kill-loops (240s/900s grace both blew),
and a proxy that had nothing to route to. The frontend was up in seconds
but could show nothing about what was happening.

## Goal

1. **Core answers fast**: object tree, auth, health, modules API listening
   in seconds-to-a-minute.
2. **Modules come online incrementally after listen**, dependency-ordered,
   with per-module status.
3. **The frontend shows the bring-up live**: which modules are online,
   loading, pending, failed — from the first moment the core answers.

## Phases

### mlb-0 — msci focus via the existing knob (no code; do first)
Set `POLARI_MODULES` for this instance to the msci working set (core +
materialsScience family + pspp + simulation deps), driven from topology
data (ModuleAssignment rows / `pol apps`), surfaced as a compose/stack
env knob. Immediate boot-time cut with zero new machinery, and it proves
the gate end-to-end. Evidence: `gate_summary()` in boot log + modules API.

### mlb-1 — two-phase boot (core-ready, then module admission)
Split boot: Phase 0 = core packages only (object tree, DB/replay for core
classes, auth, health route, modules API) → **start listening**. Then a
module-admission worker loads enabled modules one at a time (dependency
order from `FEATURE_REQUIRES` / dependency tracker): import → polyTyping/
table ensure → seeds → CRUDE + custom endpoint registration (Falcon
add_route is legal post-listen). Requests to a not-yet-online module's
routes return the honest 503-style "module loading" body, not 404.
- Healthcheck flips healthy at **core-ready** — kill-loops become
  structurally impossible; grace can drop back to ~120s.
- Knob: `POLARI_LAZY_BOOT=on|off` (off = today's monolithic boot, the
  safe fallback).

### mlb-2 — module lifecycle as object-tree data
`PolariModule` rows carry the lifecycle: `boot_status`
(pending|importing|seeding|routing|online|failed|disabled),
started/finished timestamps, seeded-row counts, error text on failure.
Persisted like everything else (CRUDE-visible, provenance-friendly);
`boot_report()` extends to read them. This keeps the capability mapped
to an object-tree node per the coherence rule.

### mlb-3 — status API + push
- `GET /api/modules/status` — one summary doc: core-ready time, per-module
  lifecycle rows, counts, overall percent.
- STOMP broadcast on every module state transition (frontend needs no
  polling; poll fallback stays).

### mlb-4 — frontend bring-up tracking
- Boot/status panel (route + a compact header widget): module tiles that
  go pending → loading → online/failed in real time, overall progress,
  time-to-core and time-to-full.
- Nav/display gating: pages owned by a not-yet-online module render an
  honest "loading — Xth in queue" state instead of erroring; flip live
  on the STOMP event.
- Works on any boot, not just cold seed (restarts show the catch-up).

### mlb-5 — seed diet (makes every path faster)
- `[DB-Save]`/`failed to analyze` per-field logging behind a knob
  (`POLARI_DB_LOG=quiet|verbose`, default quiet) — the verbose stream is
  a measurable chunk of the 15-25 min.
- Batch seed inserts per class in one transaction.
- (Later, own phase if wanted): per-module persistence replay so Phase 0
  replay only covers core classes.

## Order + review gates
mlb-0 alone unblocks the msci instance now. mlb-1+2 land together
(framework), mlb-3 rides on 2, mlb-4 is angular-only after 3. Each phase
gets its own branch off the current stack per the branch-per-phase rule;
review gate before merge, as usual.

## Verification sketch
- Selftests: two-phase boot with a module set {A requires B} asserts
  order, status rows, honest 503 pre-online, LOUD failure propagation.
- Live: cold-volume swarm boot must show core healthy < 2 min, modules
  trickling online in the frontend panel, `pol modules` agreeing with
  `/api/modules/status`.
