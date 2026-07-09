# Aquaponics Module — Phase 2 Plan (aqp-3 / aqp-7 / aqp-8)

> **✅ STATUS 2026-07-09: ALL THREE PHASES BUILT + LIVE-VERIFIED on
> staging.** 133 aquaponics selftest checks green; prf-backend rebuilt
> + cold-seeded. aqp-3 runs the scikit-fem Darcy solve IN-BACKEND
> (`fidelity: fem`, 8192 elems — skfem is pure-python and rides the
> Alpine image, so the msci-engines worker rebuild is NOT needed);
> aqp-7 compare-modes + simulate-persist + `nutrient-enrichment-
> efficiency` scoring resolve; aqp-8 grow survives healthy and FAILS
> under starved nitrate naming `nitrate-n`. Branch stack (framework)
> `dev-aqp-3-hydraulics → dev-aqp-7-vermicompost → dev-aqp-8-growth`
> (054f401); rf-node worker twin `dev-aqp-3-hydraulics` (3c09349).
> NOT pushed to GitHub. Remaining tail + verify commands: see
> `NEXT_AGENT_HANDOFF.md`. The runnable-sim-object wrappers (*SimState
> / SimulationDefinition, §aqp-3 item 4) were intentionally deferred
> (not in acceptance; the engine+analysis+API+scoring for each phase
> ARE built). Below is the original plan, retained for reference.


**Written 2026-07-09 as a durable, executable handoff.** Three new
phases extend the existing `aquaponics/` module. Ordered HARDEST →
EASIEST (Dustin's directive) so the executing agent front-loads risk:

1. **aqp-3 — FEM water-flow engine** (hardest: real scikit-fem solver).
2. **aqp-7 — worm-compost (vermicompost) nutrient-enrichment loop**
   (medium: new box-model biology + two flow-coupling modes +
   periodic scheduling; ABSTRACT ESTIMATE is acceptable).
3. **aqp-8 — per-part plant growth / growth-failure dynamics**
   (easiest: extends the aqp-4 objects already in the tree).

Each section below is SELF-CONTAINED and written so a fresh agent
(GPT-4-class) can execute it without re-deriving the module. Do the
phases one at a time, branch per phase (`dev-aqp-3-hydraulics`, …),
selftest green before moving on. Do NOT start coding until the plan
for the phase you're on is understood; all three are planned here in
advance because model access may lapse.

---

## 0. What already exists (read before touching anything)

Module `polari-rf-node/polari-framework/aquaponics/` (sibling of
`scoring/`, `materialsScience/`). BUILT + committed (5 stacked
branches off the scoring stack; NOT yet deployed to staging):

| Phase | Branch | Gives you |
|---|---|---|
| aqp-1 | dev-aqp-1-pot | `pot_basis.py` PotDefinition + PotHole; `pot_geometry.py` gravity-clamp validation + `generate_holes`; 2 waterproof pot materials + 3 hydraulic property meanings (L0 PRIORS — aqp-3 replaces the priors); `pot_api.py`. |
| aqp-2 | dev-aqp-2-media | `growth_media.py` NutrientSpecies, NutrientProfile, SoilDefinition, WaterDefinition (multiscale, tunable); `media_analysis.py`; `media_api.py`. |
| aqp-4 | dev-aqp-4-plant | `plant_basis.py` PlantDefinition + PlantPart (permanent_fraction + FATE, composition, per-species flux w/ needed+min-max incl CO₂/O₂); `plant_analysis.py` part_capture / lifetime capture / gas+nutrient budget; `plant_api.py`. |
| aqp-5 | dev-aqp-5-atmosphere | `atmosphere_basis.py` AtmosphereDefinition; `atmosphere_analysis.py` VPD (Tetens) + plant↔air gas exchange; `atmosphere_api.py`. |
| aqp-6 | dev-aqp-6-impact | `pot_system.py` PotSystemDefinition binds pot+soil+water+plant+atmosphere; `system_survival` (limiting factor named) + `system_impact` (persisted `impact_result_json`); scoring bridge `pot-environmental-impact` ScoreConcept ranks systems via objectRef into `impact_result_json`. |

### Module conventions (all three new phases MUST follow)
- **Classes are `treeObject`s**: `from objectTreeDecorators import
  treeObject, treeObjectInit`; subclass `treeObject`; `@treeObjectInit`
  on `__init__`; every field a typed kwarg with a default; `manager=
  None` LAST; body is pure `self.x = x` assignment (no logic). The
  `__init__` signature IS the DB schema (auto-CRUDE + persisted).
  Cross-class refs are JSON-string fields BY NAME, resolved at read
  time from `manager.objectTables['ClassName']`.
- **Analysis/math files** take `manager` duck-typed (anything with
  `.objectTables`) so selftests run stdlib-only with
  `types.SimpleNamespace` rows and a fake manager.
- **API classes**: `class XAPI(treeObject)` with `@treeObjectInit
  def __init__(self, polServer)`, set `self.apiName='/api/aquaponics/…'`,
  register routes via `polServer.falconServer.add_route('/api/…', self,
  suffix='…')`, handlers `on_get_<suffix>` / `on_post_<suffix>`. Falcon
  POST bodies read `json.load(request.bounded_stream)`.
- **Seeds**: `SEED_*` lists of plain dicts (keys == `__init__` kwargs),
  idempotent-by-name.
- **Wiring in `polariApiServer/polariServer.py`**: (a) import classes +
  seeds near the other aquaponics imports (~lines 158–190); (b) add
  classes to `defClassList` (~line 686, in the aquaponics block); (c)
  instantiate the API next to `AquaponicsSystemAPI` (~line 612); (d) add
  `(name, cls, SEED_*)` tuples to `seed_pairs` in `_seedSimSpace3D`
  (~lines 1559–1580), respecting dependency order (referenced rows
  first). **Newly-created rows via the API need explicit
  `manager.db.saveInstanceInDB(row)`** — creation alone only registers
  in memory (learned in the topology round).
- **Selftests** run IN the container: `pol modules selftest aquaponics`
  → `docker exec prf-backend python3 -m aquaponics.selftest_<name>`.
  Pattern: a `check(label, cond)` helper appending to `_results`, fake
  manager from SEED_* via SimpleNamespace, everything under
  `if __name__=='__main__':`, tail `raise SystemExit(1 if failed else 0)`.
- **Standing principles**: object-coherence (every capability = a
  configurable row), knobs-and-suggestions (every tunable = an explicit
  knob PLUS an evidence-bearing suggestion; NEVER auto-apply),
  file-size-decomposition (one class-family per file), honest-absence
  (missing engine/data = named refusal carrying the knob), and
  "labels/derived-values travel with their numbers" (every computed
  value carries how it was derived).

### Deploy / verify loop (per phase)
- Rebuild only what changed: `export LOCAL_IP=192.168.0.210` (MANDATORY
  — else pol-file-store crash-loops on MINIO_BROWSER_REDIRECT_URL),
  then `docker compose -f docker-compose.staging-nip.yml up -d --build
  prf-backend` from the suite root. Backend serves :3000 only AFTER
  cold-seed finishes (minutes; healthcheck flaps meanwhile).
- Selftest in-container, then hit the live API via `docker exec
  prf-backend python3 -c "...urllib..."` or the public proxy
  `https://api.prf.192.168.0.210.nip.io/api/aquaponics/...`.
- Nothing is pushed to GitHub — local commits, branch per phase.

---

## PHASE aqp-3 — FEM water-flow engine (HARDEST, do first)

### Goal
A real (not prior) hydraulics engine answering, dynamically: given a
pot's geometry + hole set + soil + water level, **does it drain by
gravity, at what rate, and what is the moisture field in the soil?**
Replaces the aqp-1 L0 hydraulic-permeability PRIORS with computed
values, and feeds aqp-7/aqp-8 the real flow rates they couple to.

This is the phase flagged in AQUAPONICS_MODULE_PLAN.md: **no fluid
physics exists in the framework** — you are ADDING a scikit-fem scalar
Darcy/diffusion engine, structurally a twin of
`materialsScience/engines/fem_engine.py`
(`solve_steady_conduction` at line 134 —
∇·(k∇u)=source over a MeshTri with ElementTriP1 — the SAME operator as
Darcy ∇·(K∇h)=0). Read that function first; you are cloning its
assembly pattern.

### Where compute runs (IMPORTANT — reuse the topology round)
The backend image is Alpine and cannot pip scikit-fem; the
`msci-engines` worker (Debian) has it (scikit-fem 10.0.2, verified
live). Delegation goes through `materialsScience/engines/remote.py`,
which as of 2026-07-09 **ladders**: `MSCI_ENGINES_URL` env knob →
topology-resolved live provider (`topology/provider_registry.py`) →
honest refusal. So: add the Darcy solver to the worker's engine set,
call it via `remote_post('/darcy/...', payload)`, and it resolves the
worker automatically (the suite backend already reaches pyscf/scikit-fem
this way with no env var set). Local-first ladder like
`dft_engine.molecular_energy` (fem_engine.py:126-157): try local skfem
(present only on the worker), fall through to `remote_post`, else the
`{'ok': False, 'suggestion': {knob, action, evidence}}` refusal.

### New files (aquaponics/ + one engine)
1. `materialsScience/engines/darcy_engine.py` — the solver. Functions:
   - `capability()` — mirror fem_engine.capability() (skfem present?).
   - `solve_head_field(geometry, k_field, bc_dirichlet, source=0.0)` —
     steady Darcy: build a 2-D vertical cross-section MeshTri of the
     pot interior (soil column + the two hole boundaries), assemble
     ∇·(K∇h)=source with ElementTriP1, apply Dirichlet head at the
     input hole (water level) and output hole (ambient), `condense`+
     `solve`. Return `{ok, headField (per-node), darcyFlux (per-elem
     from -K∇h), outflowRate, meshMeta}`. Reuse fem_engine's
     `_tri_areas` and the `conduction`/`grad`/`dot` idiom verbatim;
     only the coefficient (hydraulic conductivity K instead of thermal
     k) and BCs change.
   - `drains_by_gravity(geometry, holes, k_field)` — the headline
     answer: is the steady solution net-outflow-positive with the water
     table above the lowest output hole? Return `{ok, drains: bool,
     outflowRate, evidence, limitingFactor}`.
   - Keep it a SCALAR field solve (head h). Full Navier–Stokes is out
     of scope; document that as the fidelity ceiling.
2. In the worker's engine router (same place `/dft/*`, `/fem/*` are
   served — find it by grepping the msci-engines app for `add_route`
   or the flask/falcon router; the capability endpoint is
   `/api/msci/engines/capability`), add `/darcy/head-field` and
   `/darcy/drains` POST routes calling the two functions.
3. `aquaponics/hydraulics.py` — the module-side analysis (duck-typed
   `manager`, stdlib-only): builds the darcy payload FROM a
   PotDefinition + its PotHoles + a SoilDefinition (K from the soil's
   `hydraulicConductivity` scale property; geometry from pot
   dimensions), calls the engine (via `remote_post`), and turns the
   result into evidence-bearing findings ("output hole at height 40mm
   drains at 3.2 mL/s"; or "does NOT drain — water table 12mm below
   the lowest output; knob: lower the output hole or reduce inflow").
4. `aquaponics/*SimState` classes (in a new `hydraulics_state.py`) +
   the sim-as-data wiring: a `PotHydraulicsSimState` (field state via
   the `WindFieldGridState.cells_json` matrix convention — see
   `simulations/wind_field_seed.py`), a `SimulationDefinition` +
   `SimulationCouplingDefinition`, assembled under a
   `MultiScaleSimulationDefinition`. This makes the flow a runnable,
   inspectable sim object (object-coherence), not just an API call.
   Model on `simulations/multi_scale_seed.py`.
5. `aquaponics/hydraulics_api.py` — `AquaponicsHydraulicsAPI`:
   `GET /api/aquaponics/pots/{name}/drains` (runs drains_by_gravity),
   `POST /api/aquaponics/hydraulics/head-field` (full field for a
   pot+soil+level), `GET /api/aquaponics/hydraulics/capability`
   (engine presence, honest when absent).
6. `aquaponics/selftest_hydraulics.py` — fake-manager tests over the
   PAYLOAD BUILDER and the FINDINGS mapping (engine is mocked: feed a
   canned `{ok, headField, outflowRate}` and assert the drains verdict
   + evidence; also assert the honest-refusal shape when the mock
   returns `{ok: False, suggestion}`). Do NOT require skfem in the
   selftest (it isn't in the backend image).

### Fidelity knob (knobs-and-suggestions)
A `fidelity` knob on the sim/def: `reservoir` (fast 1-D
Torricelli/Darcy-lite reduced model, no mesh — a good default and the
fallback when the engine is absent) vs `fem` (the scikit-fem field
solve on the worker). The reduced model must run in-backend (pure
python) so there is ALWAYS an answer; the FEM path upgrades it when the
worker is reachable. Every result names which fidelity produced it.

### Acceptance
- `pol modules selftest aquaponics` (hydraulics suite) green.
- Live: `GET /api/aquaponics/pots/<seeded pot>/drains` returns a
  computed drain verdict + rate; when the worker is up the field solve
  returns a per-node head field; when MSCI_ENGINES_URL is unset AND no
  provider resolves, the reduced model still answers and says so.
- The aqp-1 pot's hydraulic-permeability property meanings can cite the
  computed value instead of the L0 PRIOR (close that honesty gap).

### Gotchas
- 2-D cross-section is enough (axisymmetric-ish); don't attempt 3-D.
- Units discipline: K in m/s, heads in m, areas from mm geometry →
  convert once, carry units in the result.
- The worker image may need a rebuild to include the new engine file —
  it's built from `polari-rf-node/msci-engines/`; rebuild via
  `pol compose engines up` / `pol swarm deploy engines` (engines
  currently runs on the **lightweight** swarm node — see
  [[topology-orchestration]]; redeploy re-syncs the image there).

---

## PHASE aqp-7 — worm-compost nutrient-enrichment loop (MEDIUM, do second)

### Goal (Dustin 2026-07-09, verbatim intent)
Simulate a **worm-based compost bin** (vermicompost soil) that the
aquaponic water passes through for **nutrient enrichment**, as a
source. TWO modes, BOTH selectable:
- **direct-in-loop**: the bin sits inline; all circulating water flows
  through the vermicompost continuously.
- **controlled periodic flow-through**: water is routed through the bin
  on a schedule (e.g. N minutes every M hours), otherwise bypasses it.
An **abstract estimate is acceptable** — a box-model of decomposition +
leaching kinetics, not a microbial CFD.

### Object model (new file `vermicompost.py`)
- **CompostBinDefinition** (treeObject): vessel + bed. Knobs: volume_l,
  bed_mass_kg, worm_density (kg worms / kg bed), feedstock_kind
  (food-scraps / manure / mixed), c_to_n_ratio, moisture_target,
  temperature_c, maturity_days (how cured the castings are), and the
  MODE (`direct` | `periodic`) + schedule knobs
  (`on_minutes`, `cycle_hours`) used only in periodic mode.
- **VermicompostProfile** (treeObject or reuse NutrientProfile): the
  nutrient RELEASE profile of mature castings — per-species soluble
  concentration the bin can leach into passing water (N as NO₃/NH₄, P,
  K, Ca, Mg, micros, plus a DOC/humic term). Reuse aqp-2's
  `NutrientSpecies` vocabulary; this is the "source" the water enriches
  from. Tunable, honestly flagged as ABSTRACT PRIORS (literature-range
  defaults) until measured.
- **CompostLoopState** (a *SimState, cells_json convention): the bin's
  running state — available soluble pool per species, decomposition
  progress, cumulative leached mass — integrated over the sim timeline.

### Kinetics (abstract box-model — keep it defensible, cite the priors)
In `vermicompost_analysis.py` (duck-typed manager, stdlib-only):
- **Mineralization**: first-order release of soluble nutrients from the
  bed pool: `dPool/dt = k_min(T, moisture, worm_density) · substrate`
  with k_min a knob (default from vermicompost literature ranges;
  temperature via a Q10 factor, moisture via a 0–1 suitability curve).
- **Leaching into water**: contact-time-limited transfer. Enrichment of
  the passing water per species = `min(pool, transfer_coeff · flow_rate
  · contact_time · (C_bin − C_water))` — a mass-transfer term driven by
  the concentration gradient. `flow_rate` comes from aqp-3 (direct
  mode: full loop flow; periodic mode: flow only during the on-window,
  time-averaged over the cycle). Never leach more than the pool holds.
- **Two modes = two schedule integrators over the SAME kinetics**:
  - direct: continuous contact; steady enrichment at loop flow.
  - periodic: enrichment applied for `on_minutes` each `cycle_hours`;
    between windows the pool RECHARGES (mineralization continues, no
    leaching) → periodic mode can deliver PULSES of higher enrichment.
    Report both the per-cycle pulse and the cycle-averaged delivery.
- **Coupling out**: the enriched water is the input to the pot's
  WaterDefinition nutrient profile — i.e. the bin RAISES the input
  concentrations feeding aqp-6's `system_survival`/`system_impact`. Add
  a coupling that composes the bin's leached profile onto the water
  source before the pot draws it.

### Object-coherence + comparison
- **CompostLoopDefinition** binds a CompostBinDefinition + a
  PotSystemDefinition + the MODE → one runnable, rankable object
  (mirror `PotSystemDefinition`). Its result (`enrichment_result_json`)
  is objectRef-scorable: extend or add a ScoreConcept
  (`nutrient-enrichment-efficiency` / `bioremediation-uplift`) so
  direct-vs-periodic and bin-size choices can be RANKED live via the
  scoring bridge (beeswax@L1 idiom, same as aqp-6).

### API + selftest
- `vermicompost_api.py`: `GET /api/aquaponics/compost-bins/{name}/release`
  (steady release profile), `POST /api/aquaponics/compost-loops/{name}/
  simulate` body `{mode, hours}` → per-species enrichment timeline +
  cycle-averaged + pulse peaks + limiting factor; `GET
  /compost-loops/{name}/compare-modes` → direct vs periodic side by
  side with the evidence (knobs-and-suggestions: recommend a mode,
  don't impose it).
- `selftest_vermicompost.py`: fake manager; assert (a) mineralization
  monotonic + temperature/moisture responsive; (b) leaching never
  exceeds the pool; (c) direct mode = steady, periodic mode = pulses
  that recharge between windows; (d) enrichment raises the coupled water
  profile; (e) honest flag that the priors are abstract.

### Acceptance
Selftest green; live `simulate` shows a worm-compost bin lifting the
aquaponic water's N/P/K over time in both modes; `compare-modes`
returns an evidence-bearing recommendation; a CompostLoop is rankable
through the scoring engine.

### Gotchas
- Keep it a BOX MODEL. Flag every rate constant as an abstract prior
  with its literature range; do not present pseudo-precision.
- Periodic mode's value is the pulse/recharge dynamic — make sure the
  integrator actually recharges between windows or the two modes look
  identical.
- Depends on aqp-3 for `flow_rate`; until aqp-3 lands, accept a
  flow_rate knob with an honest "assumed, pending aqp-3 hydraulics" flag
  so aqp-7 can be built and tested independently.

---

## PHASE aqp-8 — per-part plant growth / growth-failure dynamics (EASIEST, do last)

### Goal (Dustin 2026-07-09, verbatim intent)
Simulate **growth OR growth-failure** for a plant, with **objects
defined per part** so we can **identify likely interactions via
estimating using VOLUME per plant-part type and condition**. aqp-4
already has PlantDefinition + PlantPart with per-part composition,
permanent fraction, and per-species nutrient/CO₂/O₂ flux with min–max
bands — this phase makes those STATIC parts GROW (or fail to) over time
and reason about part-to-part interactions by volume.

### What to add (extends aqp-4, does not rebuild it)
1. **PlantPart** gets growth knobs (extend the aqp-4 class, or a
   sibling `PlantGrowthModel` row referencing it): `max_volume_cm3`,
   `growth_rate` (per-part sigmoid/logistic parameter), `condition`
   (healthy / stressed / senescing — drives rate + failure),
   `volume_density_g_cm3` (to convert the existing per-mass composition
   → per-VOLUME, which is the interaction currency Dustin asked for).
2. **PlantLifetimeState** (a *SimState, cells_json convention): per-part
   volume over time — the sim integrates each part's logistic growth
   against the LIMITING resource (nutrient/water/light/CO₂ availability
   from aqp-2/5/6, and flow/moisture from aqp-3). This is the
   growth-vs-failure engine.
3. `plant_growth.py` (duck-typed manager, stdlib-only):
   - **Growth integrator**: `dV_part/dt = growth_rate · V · (1 −
     V/V_max) · supply_factor(part)` where `supply_factor ∈ [0,1]` is
     the min across that part's required species vs available supply
     (reuse aqp-4's min–max bands + aqp-6's supply=flow×conc). When
     `supply_factor` sits below a threshold for a sustained window →
     the part's `condition` transitions to stressed, then FAILURE
     (growth halts / volume regresses), with the LIMITING factor named
     (honest-absence idiom, same as aqp-6 `system_survival`).
   - **Volume-based interaction estimation** (the specific ask):
     compute, per timestep, an interaction matrix over part-type pairs
     using each part's CURRENT VOLUME and CONDITION — e.g. leaf volume
     ↑ → shading/transpiration demand on roots ↑; root volume ↑ →
     uptake capacity ↑ supporting shoot growth; fruit volume ↑ → sink
     competition drawing nutrients from leaves. Model these as
     volume-weighted coupling coefficients (a small declarable
     `PART_INTERACTIONS` table: source-part-type → target-part-type →
     effect sign + a volume-scaled magnitude), so the estimate is
     transparent and tunable (knobs-and-suggestions). Output a ranked
     "likely interactions" list with the volumes and conditions that
     drove each — labels travel with numbers.
   - **Growth curve + failure report**: per-part volume trajectory,
     time-to-maturity or time-to-failure, the limiting factor at each
     inflection, and the interaction estimate at maturity.
4. `plant_growth_api.py` (or extend `plant_api.py`):
   `POST /api/aquaponics/plants/{name}/grow` body `{days, environment
   refs}` → per-part volume timeline + condition transitions + failure
   verdict + limiting factors; `GET /plants/{name}/interactions` →
   the volume-based interaction estimate at a given state.
5. `selftest_plant_growth.py`: fake manager; assert (a) logistic growth
   saturates at V_max under ample supply; (b) starving one species
   drives the dependent part to stressed→failure with THAT species
   named; (c) interaction estimate responds to volume (big leaves →
   stronger root-demand coupling); (d) a healthy vs a resource-starved
   run diverge as expected; (e) volumes and conditions accompany every
   interaction claim.

### Object-coherence + scoring
The growth run's outcome (permanent volume by part, failure/survival,
time-to-maturity) feeds aqp-6's existing `system_impact`/`system_
survival` — a grown plant's REALIZED per-part permanent capture (by
volume) replaces the static estimate, and becomes objectRef-scorable
(rank plant+pot+water+compost configs by realized carbon/nutrient
capture and survival margin). Reuse the aqp-6 scoring bridge.

### Acceptance
Selftest green; live `grow` shows a plant maturing under good
conditions and FAILING (with the limiting species named) under a
starved one; `interactions` returns a volume-driven, evidence-bearing
ranking; the realized per-part volumes flow into the existing
env-impact scoring.

### Gotchas
- This is the easiest ONLY because aqp-4's per-part objects exist —
  reuse PlantPart composition/fate/flux; don't duplicate them.
- The interaction table is an ABSTRACT ESTIMATE — keep it a small,
  declared, tunable coefficient table with a clear "estimate, not
  measured" flag; the value is transparency, not biophysical exactness.
- Growth integrator shares the sim-as-data machinery with aqp-3/aqp-7
  (*SimState + SimulationDefinition + coupling) — if aqp-3 built those
  wrappers, follow the same shape here.

---

## Cross-phase notes
- **Dependency order for coupling**: aqp-3 provides `flow_rate` /
  moisture → aqp-7 (enrichment vs flow) and aqp-8 (supply vs flow) both
  consume it. Each phase accepts an honest "assumed, pending aqp-3"
  knob so it can be built and tested BEFORE aqp-3 is finished if needed
  — but the hardest-first order means aqp-3 should land first.
- **All three are sims-as-data**: the *SimState /
  SimulationDefinition / SimulationCouplingDefinition /
  MultiScaleSimulationDefinition machinery is shared; aqp-3 establishes
  the pattern for the module, aqp-7/aqp-8 reuse it. Worked templates:
  `simulations/wind_field_seed.py` (cells_json field state),
  `simulations/multi_scale_seed.py` (coupling assembly),
  `simulations/material_space_seed.py`.
- **Engine compute** (aqp-3 only) rides the topology-routed remote seam
  (`materialsScience/engines/remote.py` → `topology/provider_registry`)
  — no env var needed on the suite backend; the engines worker
  currently runs on the lightweight swarm node.
- **Deploy discipline**: `LOCAL_IP=192.168.0.210` on every compose
  command; selftests in-container; branch per phase; commit locally
  (nothing pushed); update `aquaponics-module` memory + this doc's
  status as each phase lands.
