# Handoff — casting/mold-nesting: backend COMPLETE, frontend refinement REMAINS

**From:** Fable 5 · **Date:** 2026-08-05 · **Branch:** polari-framework
`dev-cast-4-sprues` (14 commits, selftest **174/174**), suite root has
`WAX_MOLD_NESTING_PLAN.md` + this file. Nothing pushed (Dustin's step).

## What is DONE and LIVE-VERIFIED (prf-a staging, sqlite backend)

The whole plan (cast-1..9 + wizard): 15 treeObject classes in
`modules/casting/`. One API call runs the entire pipeline:

    POST /api/casting/plan {"partShape": "...", "targetMaterial": "..."}

derive-mold → chain-gates (DERIVED parity + thermal) →
master-feasibility → pour-loading (collapse/exotherm/buoyancy) →
sprues-vents → fill-sim (trapped air/unfed) → demold →
chain-full-report (economics/coatings/recycling). Verified live:
sphere×zinc feasible 8/8; steel enabled via data-selected MULLITE;
`galvanized-bio-steel` = steel chain + 450°C hot-dip conversion (parity
does not flip) with zinc mass off measured area; `localProvenance`
answers "is this genuinely local" from rows (kaolin route, the
1600-vs-1350 lining BOOTSTRAP gap, bio-zinc purity unmeasured, rung
POSSESSION ≠ catalog). Targets: geopolymer | any CeramicSample | any
CastingMaterialThermalProfile | galvanized-bio-steel. FreeCAD parts
enter via the grid path (sprue/fill on grids = named seam).

⏳ Last deploy (galvanize+provenance image) was still `admitting-modules`
at handoff; smoke it with the POST above — expected: verdict feasible,
ceramic mullite, zinc ~1g, bootstrap gap named. Earlier image verified
all preceding behavior live.

## ⚠ THE REMAINING WORK: FRONTEND REFINEMENT (Dustin 2026-08-05)

The `/casting` page today is seeded plumbing, not the product:

1. **Cert, then eyeball** (blocked me): accept the self-signed cert
   once (or run the CA-import walkthrough) at
   `https://prf.<pol-core LAN address>.nip.io/casting`, verify: mold-fill-3d
   scene renders its voxel cloud (blue fluid/gray channels/RED
   trapped/ORANGE unfed), chains/molds/plans tables render as tables.
2. **The wizard UI** — Dustin's stated ideal: pick a part (math shape
   or FreeCAD import) + pick a target material (capability endpoint
   supplies both lists) → POST plan → render EVERY step visually:
   each step's `visualShapes[]` renders via the existing
   `/api/shapes/{name}/surface` viewer; the fill step names its
   SimSpace run + `mold-fill-3d` scene. Angular work in
   polari-platform-angular (custom component or extend the
   DisplayDefinition vocabulary with a wizard/stepper item type).
3. **Per-step visual polish**: mold body/master-sprued side-by-side
   (parity pair), per-plan fill runs (today only the demo mold's run
   is seeded as rows; wizard fill runs persist rows named
   `nest--…--fill` — scene run-filtering needed), NestingPlan detail
   page (steps_json as a stepper, not JSON).
4. **Known rough edges**: NestingPlanDefinition/CeramicSample sqlite
   persistence lagged in-memory state on the earlier image — verify
   after a restart; sprues/fill on grid-path (imported) molds refuse
   (named seam); the interstitial blocked all extension automation —
   consider trusting the CA on the dev box for future browser passes.

## Gotchas that will bite again (all hit live this session)
- Modules admit in DEPENDENCY ORDER from `modules/polari-modules.json`
  `requires` — casting declares [mathshapes, composition, waxprint,
  waxsupply, pspp]. A module with no declared requires admits
  alphabetically and its seeds may run before its data exists.
- New module on an instance: `pol topology assign <mod> prf-a`, then
  apply the DERIVED env (`pol topology modules-env prf-a`) to the
  service — never hand-typed lists.
- seed_pairs WITHOUT defClassList = no table, silent skip (bit pspp's
  CeramicSample/LadderRung for months until the casting gate refused).
- Bare quadric rows are INFINITE to the field evaluator — CSG channels
  must be bounded primitive solids paired with their -eq rows.
- `pol node build backend` + `docker service update --force
  polari-node_backend`; boots ~13-15 min to full admission (health
  `phase` online), sqlite at /app/data/managerObject_DB.db.

## ADDED 2026-08-05 (focus switch): CLIMATE/AQUAPONICS frontend items

Focus moved to CO₂/health + pot sims (prf-a trimmed to 8 modules; the
15 casting-era modules shelved on prf-b, reversible, data intact).

1. **Graph DOWNLOAD buttons, everywhere graphs render** (Dustin):
   clear/obvious button on the graph-renderer component. The climate
   export module already REFUSES server-side rendering for the right
   reason (two renderers = two truths — see climate_export.export_svg
   for the exact spec): serialize the rendered SVG
   (`new XMLSerializer().serializeToString(svg)` → Blob) and
   rasterize to PNG via canvas for Medium pasting; also link the
   existing provenance-carrying exports
   (`GET /api/climate/export/series/{name}?fmt=markdown|csv|json` and
   `/api/climate/export/view/{view}` — markdown is Medium-ready text).
2. **Cited/derived tags → clickable**: bind tag click to
   `GET /api/climate/citations/{source_ref}` (resolves any registry +
   the SourceRetrieval trail w/ URLs + content signatures). Backend
   done; frontend needs the click binding + a small popover.
3. **Compression surfaced**: series detail now carries `compression`
   (the audit record) and `compressionSuggestion` (the knob) — show
   both; a compressed graph should say "N points, bin-mean of M"
   near the legend, not hide it.
4. Pot-sim refinement is the NEXT arc (2 PotDefinition + 6 PotHole +
   5 derived pot shapes live on the trimmed instance).
