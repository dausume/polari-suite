# Wax-Mold Nesting Plan — casting chains, sprues, fill/demold simulation

**Date:** 2026-08-05 · **From:** Fable 5, with Dustin
**Handoff:** `WAX_MOLD_NESTING_HANDOFF.md` (read it first — parity and
thermal ordering are the two correctness properties; they are restated
here as gates, not prose).
**Dustin's directives beyond the handoff (2026-08-05):**

- Use **both** voxel analysis and matrix-equation analysis — the
  handoff's biggest fork is resolved: analytic where exact, voxel where
  connectivity/fill/undercut demands it, each checking the other.
- Auto-nest **math shapes AND FreeCAD-defined parts**.
- Objects for **multi-tier mold nestings**, **sprue strategies**, and
  **mold-fill simulations** per material with air-pocket/hole detection.
- **Interventions**: positive/negative pressure through a sprue,
  applied heat or cold — each gated so it damages neither material.
- **Demold simulation**: removal without damage.
- **Mold strategies + coatings** feasible locally and renewably, with
  **mold recycling** designed in.

---

## 0. Verified ground truth (surveyed 2026-08-05, both repos on `dev`)

What exists and what is genuinely new. Build on the left column; the
right column is the work.

| Exists (verified) | Gap (verified absent) |
|---|---|
| CSG algebra `union=min / intersection=max / difference=max(a,−b)`, inside<0, quadric surfaces, `<shape>--field` equations (`mathshapes/shape_equations.py`) | No `offset/shell` operator; shells are two concentric quadrics differenced |
| `shape_modify.pot_shape_from_definition` — attach/subtract features on curved surfaces, equation-first, with `-eq` quadric rows + render rows | No sprue, no mold-as-geometry, no casting objects anywhere (`grep sprue` = 0 hits) |
| Voxelizer inside `shape_analysis._grid_properties` (res ≤ 80) and `_march_voxel_mesh` | Grid is function-local and **discarded**; no reusable occupancy grid; **no flood-fill / connected-components anywhere in the framework** |
| CAD import real: trimesh formats always; STEP/FCStd behind `WITH_FREECAD=1` on the cad-engines worker; MinIO storage; `ImportedCadObject` | Imported meshes **cannot** participate in CSG; ⚠ `shape_analysis._evaluate_shape` silently returns *outside* for `imported-mesh` — a fill sim pointed at one computes a confidently empty mold |
| `composition.RoutingDefinition` + `RoutingOperation` (6 routings / 16 ops live), PROMOTE gate, `PartComponentDefinition.coating_ref` | `RoutingOperation` has **no parameter bag, no material/shape ref, no tool ref** — an op cannot name the mold it casts against |
| Temperatures: `ThermalProcessingProfile` (waxes: melt + smoke), `CeramicSample` (firing/service/softening + `thermal_shock` + `temp_claim_status`), `LadderRung` furnace ceilings, geopolymer cure 40–85 °C, measured geopolymer→ceramic ladder 1000–1400 °C | **No metal melt point exists anywhere.** `galvanized-bio-steel` is an identity row; its ">~200 °C invalid" envelope is prose in `notes` |
| Mold economics + honesty rules: `supplychain/mold_analysis.py` (`MOLD_STRATEGY_PRIORS` w/ cycle lives, "fresh geopolymer BONDS to cured geopolymer → needs release", slip-cast-in-geopolymer **refused**, crush-to-aggregate credit, "wax molds MELT, not crush"), `waxprint.MoldLifecycleRecord` (`casts_completed`, `release_agent`), `waxsupply` jojoba = mold release, `mold` use ranking (carnauba 0.965 top) | Nothing links mold economics to geometry or to routing; coatings/recycling are costed but not process-modeled |
| Makability verdicts: `motors/scale_goals.goal_feasibility` (`verdict/blockers/gaps` — "scores rank options; blockers decide"), `pspp/solgel_sourcing` accessibility tiers, `CeramicSample.track` local/non-local | techtree itself computes completion, **not** feasibility — bind to the `goal_feasibility` pattern, not techtree |
| Sim registration pattern: `waxprint/sim_seed.py` trigger-on-import appends + `WaxPrintSimState` one-row-per-cell + `render_state` → SimSpace binding renders with zero new frontend code | — |

House rules that bite here: new treeObject classes **must** enter
`polariServer.defClassList` (~L2031) or seeds silently vanish; new
seeded tables should wire through `composition.seed_upsert`
(ten-strikes); knobs + evidence-bearing suggestions, never auto-apply;
refuse rather than invent; per-object displays, not raw JSON; small
files; branch per confirmed phase.

---

## 1. The two representations and how they divide the work

**Matrix-equation (analytic) side — exact, owns correctness:**

- **Inversion is algebra.** The negative of part `P` inside stock `S`
  is `intersection(S, −F_P)` = `max(F_S, −F_P)` — the existing CSG
  executor evaluates it today with zero new math. Parity through N
  stages is N sign flips; that is why parity can be *derived*.
- **Shrinkage is a matrix transform.** A uniform allowance scale `s`
  maps every surface quadric `Q → Sᵀ⁻¹ Q S⁻¹` — exact, per-stage,
  declared not baked.
- Sprue/vent attachment = new `-eq` quadric rows unioned into the
  chain (the `pot_shape_from_definition` idiom, with `union` where the
  pot used `difference`).
- Cross-checks in the `equation_parity` style: analytic volume vs
  voxel volume, cavity field sign vs grid membership.

**Voxel side — connectivity, owns everything topological:**

- Fill fronts, trapped air, vent reachability, undercut/parting
  sweeps, channel-width minima — all are connectivity questions the
  analytic field cannot answer without root-finding.
- One new reusable structure (`OccupancyGrid`) lifted from the loop
  `shape_analysis._grid_properties` already runs and throws away, plus
  the flood-fill the framework has never had.
- **The FreeCAD bridge lives here.** An imported mesh voxelizes into
  the same grid (ray-parity point-in-mesh on the stored BufferGeometry;
  trimesh on the worker as the checked alternative), so *any* part —
  math shape or FreeCAD import — enters the casting pipeline as a
  grid, and math shapes additionally carry their exact field. Fixes
  the silent-outside trap by making `imported-mesh` either voxelize or
  **refuse loudly** — never evaluate as empty space.

Rule of thumb encoded in the module: *the analytic side decides what
the geometry IS; the voxel side decides what the process can DO to
it; disagreements beyond tolerance are a named refusal, not an
average.*

---

## 2. Object model (new module `modules/casting/`)

One module owns all new classes (per `/topology/databases` one-owner
rule). Recommended name `casting` — distinct concern from `waxprint`
(fabrication) and `composition` (structure). All classes are
treeObjects → defClassList + seed_pairs + seed_upsert wiring.

### Geometry

- **`MoldDefinition`** — the negative as a first-class object.
  `name`, `part_shape_ref` (MathShapeDefinition **or**
  ImportedCadObject — `part_source` discriminates), `stock_shape_ref`
  (default auto box with declared margin), `cavity_shape_name` (the
  *derived* CSG row `<name>--cavity`), `shrink_allowance_pct`
  (declared, default 0 with `named_absence`), `parting_axis_hint`,
  `coating_ref`, `mold_material_ref`, `provenance_id`, `notes`.
  Derivation writes the cavity CSG rows; hand-editing the cavity is
  refused ("derived — edit the part or the allowance").
- **`SprueStrategyDefinition`** — a *strategy*, reusable across molds:
  `name`, `gate_style` (`top-gate | bottom-gate-riser | side-gate`),
  `n_vents`, `vent_placement` (`high-points | manual`),
  `sprue_taper_deg`, `neck_area_ratio` (neck cross-section as a
  fraction of local part section — the removability knob),
  `removal_mode` (`snap | cut | melt-with-master`), `notes`.
- **`SprueSetInstance`** — the strategy *applied* to one mold:
  `mold_ref`, `strategy_ref`, generated `sprue_shape_names_json` +
  `vent_shape_names_json` (each a `-eq` quadric row + render row),
  `placements_json` (where and why — evidence), `removability_score`,
  `removability_evidence_json`.

- **`MasterFeedstockDefinition`** *(added by Dustin's 2026-08-05
  directive, BUILT in cast-2b)* — what the sacrificial master is made
  of: `material_kind` (`natural-wax | machinable-wax | wax-filament |
  pla`), `priority` (`core` = the natural locally-producible wax —
  the focus; `supported` = commercial alternates), accessibility
  tier + renewable flag, `make_routes_json`
  (`auger-pellet-print | fdm-voron | cnc`), density/strength/soften/
  melt with claim status, print kinematics, and `removal_route`
  (`melt-out | burn-out | mechanical` — gated against the mold
  material by cast-3). `master_report` dispatches feasibility +
  print time by route; CNC time is a named absence v1.

### Process chain (rides composition, does not fork it)

- **`MoldNestingChain`** — the multi-tier object. `name`,
  `target_part_shape_ref`, `stages_json` (ordered refs to
  CastingStage), `routing_ref` (a real `RoutingDefinition` this chain
  emits/maintains), **derived**: `wax_master_parity`
  (`negative | positive`, = odd/even stage count — **refused if any
  caller tries to set it**), `thermal_ordering_verdict`
  (`ok | refused`, with `offending_pair` named), `chain_report_json`.
- **`CastingStageDefinition`** — one inversion. `name`, `chain_ref`,
  `sequence`, `mold_material_ref`, `cast_material_ref`,
  `mold_def_ref`, `sprue_set_ref`, `routing_op_ref` → a real
  `RoutingOperation` (`kind='shape'` or `'condition-change'` for the
  geopolymer→ceramic firing) — **this join class is how casting
  parameters attach to the routing spine without adding fields to the
  seeded RoutingOperation class**, `process_temp_c` (derived from
  material rows, not typed in), `fill_sim_ref`, `demold_plan_ref`.
  Note: a *conversion* stage (geopolymer fired to ceramic in place)
  inverts nothing — `inverts_geometry` is derived from kind, and the
  parity computation counts only inverting stages.
- **`CastingMaterialThermalProfile`** — closes the metal-data gap
  *without* touching seeded materialsScience classes:
  `material_ref` (→ MaterialsScienceMaterial), `solidus_c`,
  `liquidus_c`, `recommended_pour_c`, `solidification_shrink_pct`,
  `claim_status` (`literature-approximate` — the CeramicSample
  pattern), `source_note`, `provenance_id`. Seed zinc, plain-bio-steel,
  (aluminum optional). Waxes/ceramics/geopolymer keep their existing
  rows — the gate *reads* ThermalProcessingProfile / CeramicSample /
  cure datasets first and this class only where those are silent.
- **Galvanized steel is named honestly:** galvanizing is a ~450 °C
  hot-dip *coating* operation after the last casting stage — modeled
  as a `RoutingOperation` + `PartComponentDefinition.coating_ref`
  (both exist), **not** a fourth inversion. The 3-stage chain ends in
  cast steel; `galvanized-bio-steel` is what the coating op emits.

### Simulation

- **`MoldFillSimState`** — one row per rendered voxel per recorded
  step, exactly the `WaxPrintSimState` idiom (`simulation_run_ref`,
  `step`, `pos_x/y/z`, `render_state`: 0 empty / 1 filling / 2 solid /
  3 trapped-air / 4 refused-region, plus `fill_fraction`,
  `local_section_mm`, `froze_before_fill`). Display grids are capped
  (res ≤ 24 for persisted rows); analysis grids run finer in memory.
- **`FillInterventionDefinition`** — a knob, never auto-applied:
  `kind` (`pressure-positive | pressure-vacuum | heat-soak |
  chill`), `magnitude`, `applied_at` (`sprue | vent | mold-wall`),
  **`damage_gates_json`** — each gate names the material row + field
  it checks (mold `max_service_temp_c`, `thermal_shock`, wax
  `safe_melt_max_c`, burst-pressure = *named absence* until measured)
  and its verdict. An intervention whose gate refuses is reported
  with the evidence, not silently clamped.
- **`DemoldPlanDefinition`** — `mold_ref`, `method` (`melt-out |
  burn-out | mechanical-part | dissolve` — dissolve refuses v1),
  derived: `parting_direction_json` + `undercut_report_json` (voxel
  sweep), `thermal_gates_json` (melt-out temp vs mold cure/service;
  burn-out vs `smoke_low_c` with a ventilation note), `release_
  coating_required` (derived from the geopolymer-bonds-to-geopolymer
  rule), `damage_verdict` + evidence.
- **`MoldCoatingDefinition`** — `name`, `coating_material_ref`
  (jojoba first; graphite/talc as candidates), `purpose`
  (`release | sealing | surface-finish`), `accessibility_tier` (the
  solgel_sourcing vocabulary), `renewable` (bool + basis),
  `max_service_temp_c`, `applies_to_mold_materials_json`.
- **`CastingRunRecord`** — one physical/simulated cast:
  `stage_ref`, `mold_lifecycle_ref` (→ existing
  `waxprint.MoldLifecycleRecord` — reuse, don't duplicate),
  `fill_run_ref`, `outcome`, `defects_json`.
- Recycling is **not** a new class: the chain report binds
  `mold_analysis.MOLD_STRATEGY_PRIORS` (cycle lives, release kg/cast,
  crush-to-aggregate credit, wax melt-reclaim) per stage.

### The two derived gates (the whole point, as refusals)

1. **Parity gate.** `wax_master_parity = negative if (count of
   inverting stages) is odd else positive`. Stored nowhere as input;
   any seed/API attempt to set it → refusal naming the derivation.
   Selftest pins 1-stage=negative, 2=positive, 3=negative, and that
   inserting a conversion (non-inverting) stage does *not* flip it.
2. **Thermal ordering gate.** For each stage: mold material's
   survivable ceiling (CeramicSample `max_service_temp_c` / geopolymer
   cure envelope / wax `safe_melt_max_c`) ≥ the cast material's
   process temp (cure exotherm peak / firing band / `recommended_
   pour_c`); AND the sacrificial predecessor must be *removable
   below* the mold's damage threshold. Any violation → `refused` with
   the offending pair and both numbers named. Missing data (e.g. no
   thermal profile row for a metal) → `refused: data-absent`, never a
   default. Furnace reachability cross-checked against `LadderRung`
   ceilings (a 1600 °C pour with a 1350 °C best furnace is a
   *blocker*, in `goal_feasibility` vocabulary).

---

## 3. Phases (each = one branch off `dev`, small files, selftest-gated)

**cast-1 — module scaffold + the inversion primitive.**
`modules/casting/` (`casting_basis.py`, `mold_geometry.py`,
`casting_seed.py`, `selftest_casting.py`). `MoldDefinition` +
derivation: cavity CSG rows via the `build_quadric_eq_row` /
`_insert_rows` idiom, shrink as the quadric scale transform,
`imported-mesh` parts **refused at this phase** (bridge lands in
cast-2) — loudly, citing the silent-outside trap. Registration:
defClassList, seed_pairs, seed_upsert, module boundary +
PolariModule row, ownership visible at `/topology/databases`.
*Proof:* unit-sphere mold: cavity field = `max(F_box, −F_sphere)`;
analytic cavity volume vs voxel volume within tolerance.

**cast-2 — OccupancyGrid + flood-fill + the FreeCAD bridge.**
`voxel_grid.py` (grid lifted out of `shape_analysis`, reusable:
membership, connected components, BFS flood-fill, boundary faces),
`mesh_voxelize.py` (ray-parity point-in-mesh over the stored
BufferGeometry; worker-side trimesh check when cad-engines is up).
`imported-mesh` now voxelizes or refuses — never silently empty.
*Proof:* voxel volume of `pot-with-holes` matches
`shape_properties`; an imported STL cube voxelizes to its known
volume; cavity connectivity of a two-chamber test mold = 2.

**cast-3 — the chain as data with both gates.**
`chain_basis.py`, `thermal_gate.py`, `CastingMaterialThermalProfile`
(+ zinc/steel literature rows, claim-status carried),
`MoldNestingChain` / `CastingStageDefinition` emitting real
`RoutingDefinition`/`RoutingOperation` rows (new `rt-cast-*` rows;
no fields added to composition classes). Seed the three chains:
`wax→geopolymer` (1), `wax→geopolymer→ceramic` (2 + firing
conversion stage), `wax→geopolymer→ceramic→steel[+galvanize coating
op]` (3). *Proof:* parity pinned per §2; a deliberately-broken chain
(pour steel into earthenware, 1000 °C service) refuses naming the
pair; absent-metal-data refusal pinned.

**cast-4 — sprues and vents, automated.**
`sprue_geometry.py` + strategy/instance classes. Placement: gates
from the strategy style + gravity axis; vents at voxel-detected
cavity high points (the connectivity work from cast-2); geometry as
tapered-frustum `-eq` rows unioned in, sized by `neck_area_ratio`
against the *local* part section (the `mid_r`-relative sizing idiom
from the pot holes). **Removability, proposed numeric definition
(for Dustin to confirm):** `removability = w_neck·(1 −
neck/local-section ratio, target ≤0.25 brittle / ≤0.4 ductile) +
w_access·(line-of-sight to neck from outside, voxel ray) +
w_mode·(snap for brittle, cut for ductile, melt for wax)` — each
term with evidence, worst-wins verdict like the movement scorer.
*Proof:* auto-sprue on the pot and on a sphere; neck ratio respected;
a sprue that would land on an undercut face is rejected with reason.

**cast-5 — fill simulation per material.**
`fill_sim.py` + `MoldFillSimState` + sim registration (the
`sim_seed.py` trigger-on-import appends; scene + bindings +
Material3D rows; page display). Model, honestly scoped: quasi-static
gravity fill — level-by-level flood from gate-connected regions;
air must escape *upward* to a vent/sprue or it is a **trapped
pocket** (connected-component of unfilled cavity with no rising
path); thin-channel gate: channel width < 2 voxels → `refused-region`
(analytic field refines locally where available); freeze-before-fill
flag per region via fill-time vs solidification-time ratio (local
modulus V/A from the grid; wax/ceramic/metal parameters from their
rows; **geopolymer slip-cast refusal from mold_analysis is honored
and surfaced**). Named unmodelled v1: turbulence, surface tension,
menisci, gas back-pressure magnitude. *Proof:* a mold with a
deliberate dead-end dome shows a trapped pocket; adding a vent at
the reported cell clears it; per-material runs differ (steel freezes
in thin sections where zinc doesn't).

**cast-6 — interventions.**
`interventions.py` + `FillInterventionDefinition`. Positive pressure
lowers the thin-channel threshold and shrinks (never deletes)
trapped-air volume — with the burst-strength gate a *named absence*
until measured; vacuum converts trapped pockets to filled iff an
evacuation path existed pre-fill; heat-soak extends the fill window
(gates: mold `max_service_temp_c`, wax `safe_melt_max_c`); chill
shortens it (gate: `thermal_shock` on ceramic rows). Every
intervention = knob + evidence-bearing suggestion attached to the
fill report ("trapped pocket at (i,j,k): vacuum via vent-2 clears
it; gate ok at −30 kPa"), never auto-applied. *Proof:* each gate's
refusal pinned with a real material row.

**cast-7 — demold simulation.**
`demold.py` + `DemoldPlanDefinition`. Undercut/parting sweep:
directional voxel scan (±principal axes + parting hint); a cavity
demolds mechanically along `d` iff every cavity column is monotone;
otherwise undercut cells are reported and a two-part parting plane
is searched (axis-aligned v1); melt-out/burn-out gated per §2;
release-coating requirement derived from the bonding rule and
satisfied by a `MoldCoatingDefinition`; ejection-damage verdict from
contact area × adhesion class vs brittle/ductile. *Proof:* sphere
demolds nowhere in one piece (undercut everywhere) → two-part plan
found; pot demolds along its axis; wax master melt-out passes at
64–86 °C vs geopolymer 80 °C cure envelope — and the gate catches a
hypothetical wax with `safe_melt_max_c` above mold damage.

**cast-8 — coatings, recycling, and the chain report.**
`MoldCoatingDefinition` seeds (jojoba release from waxsupply;
candidates tiered by `solgel_sourcing` accessibility + renewable
basis), `CastingRunRecord` → `MoldLifecycleRecord` binding, chain
report composing: per-stage mold mass/cycle-life/release-per-cast
from `MOLD_STRATEGY_PRIORS`, end-of-life route (wax **melts** to
reclaim; geopolymer/ceramic **crush** to aggregate with credit),
and the local-makability verdict per stage in `goal_feasibility`
vocabulary (verdict/blockers/gaps — e.g. steel stage: furnace rung
+ imported-copper-style honest exceptions). *Proof:* 3-stage chain
report end-to-end with every number traceable to a row.

**cast-9 — pages + per-object displays + browser pass.**
`/casting` page: chain viewer (stages with parity/thermal badges),
mold page tabs (cavity 3D via existing surface sampling, sprue set,
fill runs, demold plan), fill-sim SimSpace scene, seeded
DisplayDefinitions (never raw JSON). Deploy via `pol node build
backend|frontend` + `docker service update --force`, live probes,
Chrome visual pass.

Dependency order is strict through cast-3; cast-4..7 each depend on
cast-2/3 but are mutually parallelizable if we want to interleave
review.

---

## 4. Decisions for Dustin (recommendations inline, none blocking cast-1)

1. **Module name** — recommend `casting`. (Alternative: `molding`.)
2. **"Easy to remove," numerically** — the cast-4 formula above is a
   proposal; confirm or adjust the neck-ratio targets (0.25 brittle /
   0.4 ductile) and the term weights before cast-4 builds.
3. **v1 physics scope** — modeled: gravity fill + connectivity,
   freeze-vs-fill ratio, shrink as declared allowance, undercut
   sweeps, thermal gates. Named-unmodelled: turbulence, surface
   tension, cure distortion, draft angle optimization, mold burst
   pressure (until measured). Confirm this split.
4. **Metal thermal rows** — seeding zinc + plain-bio-steel
   solidus/liquidus/pour as `literature-approximate` with sources:
   confirm this is acceptable provenance (it mirrors CeramicSample).
5. **FreeCAD depth** — v1 bridge voxelizes imported parts (grid-only,
   no exact field). Full parametric FreeCAD knobs
   (`parametric_params_json` is name-only today) is a separate later
   arc. Confirm deferral.

## 5. Verify

`pol` only. Per phase: `pol modules selftest casting` in-container;
cast-5+ add sim probes; cast-9 is the deploy + browser pass. Backend
is a swarm service — rebuild + `docker service update --force`,
never `docker cp`. Live API `https://api.prf.192.168.0.210.nip.io`.
Commit innermost-first; push stays Dustin's manual step.
