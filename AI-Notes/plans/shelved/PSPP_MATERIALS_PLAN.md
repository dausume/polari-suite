# PSPP Materials Plan — Processing → Structure → Properties → Performance

**Status: TENTATIVE GO (Dustin 2026-07-18) — pspp-1/2/3/4 + pspp-7 core BUILT as
module `modules/pspp/` (per Dustin's directive: under polari modules). Stacked
branches dev-pspp-1 → 2 → 3 → 7-q-distribution → 4-process-layer (NOT on dev).
182 pspp selftest checks + full msci suite green, zero call-site edits. Book:
Davidovits, "Geopolymer Chemistry and Applications". The Ch.8.2-8.6 review reframed
the target as a GENERIC REACTIVE-MATERIAL ENGINE — reaction networks as data
(species + graph-rewrite rules with hypothesis status + site constraints), with the
geopolymer chemistry as the first library: 11 digitized datasets, 8 patent windows,
17 reaction rules (Na two-phase + phillipsite + K kalsilite/leucite analogue routes),
3 benchmark cases. Remaining phases: pspp-5 transfers, 6 slice glue, 8 progress
engines, 9 performance, 10 frontend, 11 generality proof. Data asks: straight-on
Fig 5.22, Fig 5.21, threshold-window variant for the p.193 asymmetric bands.**

**UPDATE 2026-07-19 (later session): pspp-8 FULL + threshold windows BUILT
on framework branch `dev-pspp-8-network-stepping` (off the pspp-5 head).
340 checks green across 17 pspp suites. What landed:**
- **ThresholdReactionWindow** (`threshold_windows.py`) — the banded/asymmetric
  variant: ordered contiguous full-coverage half-open bands, each with its own
  grade + physical note. p.193 seeds (`k-ps:SiO2/Al2O3:banded`,
  `k-ps:M2O/Al2O3:banded` — preferred 4.0-4.2 / 1.3-1.52, crack thresholds
  <3.7 / <1.1, free-K-silicate ceiling) SUPERSEDE the binary symmetric rows in
  merged grading (`grade_composition_merged`; /api/pspp/grade now uses it).
  `window_role='condition-gate'` rows open/close PATHWAYS instead of grading:
  seed `na-silicate:mr-q0-depolymerization` models the p.188/p.196 MR<1.20 Q0
  threshold as data.
- **Network stepping** (`network_stepping.py`, pspp-8 full) — rules consume/
  produce species with the Table 5.6 Q-distribution as the DYNAMIC RESOURCE
  (`solution_inventory`; None = present-unquantified); `applicable_rules`
  (species multiplicity + Fig 8.21 site + NEW `cation_family` on ReactionRule
  (§8.5 Na vs §8.6 K routes — a Na mix can no longer conjure KOH) + condition
  gates via `condition_windows_json`, honest-absence blocking);
  `step_once` stoichiometric scientist-driven stepping; `reachable_frameworks`
  kinetics-free presence-only closure (pathway rule chains, hypothesis FLOOR =
  weakest rule standing, competing branches surfaced never resolved). I5
  stands: rule_rate still refuses; time-resolved sim waits on cited kinetics.
- **Cure checkpoints** (`cure_checkpoints.py`) — plan/apply promotion of
  measured cure completions (progress_engine v1) to durable MaterialState rows
  via TRANSFORMATIVE sealed-cure MaterialProcessExecution edges (I2/I3) +
  reactionExtent StructureClaim (I4). PLAN-FIRST: plan returns exact rows,
  apply is the explicit knob (`POST /api/pspp/checkpoint {"apply": true}`),
  duplicates refused.
- **Experiment guidance** (`experiment_guidance.py`) — ONE payload walking a
  bench scientist through mix grading + open/blocked pathways + measured cure
  schedule; every refusal becomes a gap entry naming the exact measurement/
  dataset to enter (the gap list IS the experiment plan).
- API: `GET /api/pspp/pathways`, `POST /api/pspp/guide`,
  `POST /api/pspp/checkpoint`; ThresholdReactionWindow registered + seeded in
  polariServer (lazy-imports drift guard 15/15).

### Ch.5–8 review update (relayed from ChatGPT 2026-07-18) — folded in

Confirmations: no new resolution level; MaterialState + process graph as designed;
recipe alone insufficient (identical chemistry + different process ORDER = different
material); three orthogonal spaces (Composition/Process/State). New concepts adopted:
- **Computed composition descriptors** (Ch.8): SiO₂/Al₂O₃, M₂O/SiO₂, M₂O/Al₂O₃,
  H₂O/M₂O, Si/Al, Na/K derived from stored composition, never hand-entered —
  ✅ BUILT (`pspp.composition_math`, book p.84 constants pinned as cross-checks).
- **Reaction windows** (Ch.8): empirical regions, graded ideal/acceptable/marginal/
  failure, per-family, never transferable — ✅ machinery BUILT
  (`pspp.reaction_windows`); the numeric Ch.8 ranges arrive as cited rows (data ask).
- **ReactionProgress ∈ [0,1]** continuous (aging/pot-life/shelf-life) — ✅ in the
  mandatory structure core as `reactionExtent`.
- **Q-species as structural motifs** (Figs 5.5/5.6): summaries over an underlying
  network representation, evolving via reaction rules — pspp-7/8 shape confirmed.
- **Mechanisms as competing hypotheses** (Ch.7): the seven-step mechanism, Al–O–Al vs
  Loewenstein — reaction graphs as data, never hardcoded chemistry (extends I5). The
  observed sequence (edge attack → dissolution → monomer → condensation → network
  growth) is still the process-graph template.
- **Heating methods as process subclasses** (conventional/microwave/RF/Joule — kinetics
  not chemistry) — pspp-4 vocabulary.
- **Transport as explicit models** (alkali migration, water, heat) — pspp-9 engines,
  state-dependent, not scalar properties.
- **Ch.8 patent examples = benchmark validation cases** (near-complete sim inputs +
  measured outcomes) — pspp-9/11 validation data ask, entered as rows when photographed.
Devised 2026-07-18 in a three-way design dialogue (Dustin relaying between Claude and
ChatGPT, which has ingested the geopolymer + ceramic-composites books). Architecture was
converged over three rounds; ChatGPT's closing statement confirmed it settled.

Standing principles apply throughout: knobs + evidence-bearing suggestions (never
auto-apply), object coherence (every capability is an object-tree node, configurable
there), small files split by concern, branch per confirmed phase (`dev-pspp-N-*`),
absence is honest data, no silent fallbacks.

---

## 1. The settled architecture

Polari previously conflated three concepts that PSPP forces apart. They are now
**orthogonal**:

1. **Material Identity** — "what material is this?" (`MaterialsScienceMaterial`, exists)
2. **Material State** — "what condition is it in?" (NEW: an evolving history)
3. **Material Resolution** — "how is this state represented mathematically?"
   (the existing L0–L4 ladder — adequate as-is; **no sixth scale is added**)

```
MaterialIdentity
  └── MaterialState DAG           nodes = durable states; edges = MaterialProcessExecution
      │                           (incl. degradation scenarios)
      ├── ProcessingStage + ThermodynamicPhase     orthogonal, per state
      ├── MultiScaleMaterialStructure              per state; L2 sub-domains;
      │                                            5-descriptor mandatory core
      ├── PropertyClaims / StructureClaims         value + EvidenceMethod + assumptions
      │                                            + validity (annotations, NOT edges)
      └── ScaleTransferDefinitions                 claims moved between levels, gated
PerformanceScenario = MaterialState + Geometry + ExposureScenario + Loads
                      → result claims + promoted result-states (edges)
```

PSPP maps onto today's Polari as: Properties ✅ strong (property classes,
`MaterialPropertyMeaning`, engine results) · Processing 🟡 partial (`ThermalProcessingProfile`,
purposes, devices — no transformation object) · Structure ❌ missing entirely ·
Performance 🟡 target-scoring only. This plan fills the gaps without duplicating what
exists.

### Design rules (invariants — enforce in code and selftests)

- **I1 — Canonical-state resolution.** Every material gets a canonical/default state.
  All legacy name-based lookups (`beeswax@L0`, waxprint `*_ref`, aquaponics pots,
  `material_detail`) resolve ONLY through the canonical state unless the caller names
  another state. This prevents mixing properties from different DAG branches.
- **I2 — Edges vs annotations.** The discriminator is a **declared execution semantic**
  `ExecutionEffect: OBSERVATIONAL | TRANSFORMATIVE` — not an inferred structure delta.
  TRANSFORMATIVE ⇒ `MaterialProcessExecution` edge + child `MaterialState` node(s), even
  if some resulting structure fields are unknown. OBSERVATIONAL ⇒ attach
  Property/Structure/ValidationClaims to the existing state (an FEM re-run never spawns
  a state; a thermal exposure with no modeled structure delta still does).
- **I3 — SimulationFrame ≠ MaterialState.** Per-timestep sim rows (e.g.
  `MaterialCondensationState`) are the *SimulationFrame* concept — trajectories, not
  history. Only designated checkpoints (end of cure, end of exposure) are promoted to
  durable `MaterialState` rows. No class renames now; the plan just fixes vocabulary so
  the two are never mixed.
- **I4 — Claims, not values.** Every predicted/looked-up property is a claim: value +
  evidence method + assumptions + validity range + source. "38 GPa" is never stored
  bare.
- **I5 — No invented kinetics.** Relations the books do not establish with validity
  ranges (MR→strength, Si:Al→strength, porosity→permeability, cure-T→rate, Ryshkewitch
  as "the" strength law…) stay as **registered-but-unimplemented engine interfaces**
  that refuse with an evidence-bearing suggestion naming the missing calibration knob.
- **I6 — Curves are data, not code.** Digitized book figures/tables are DB rows read by
  one generic interpolation engine. `extrapolation_policy` defaults to **UNSUPPORTED**
  (out-of-range ⇒ refusal naming the validity domain, never linear extrapolation).
- **I7 — Recipes are process inputs.** A formulation is an instruction, not a material.
  `Formulation` becomes the input-constraint set of a mixing/activation process;
  multiple recipes may converge to near-identical states (as happens experimentally).
- **I8 — Scale-qualified semantics.** The same word means different things per level
  (L3 porosity = atomic free volume; L2 = gel/capillary pore distribution; L1 =
  continuum field; L0 = measured bulk/open). `MaterialPropertyMeaning` already carries
  `scale_levels_json`; structure descriptors get the same treatment.

### Where code lives

Basis extensions in `polari-rf-node/polari-framework/materialsScience/` (new small
files, one concern each). The geopolymer vertical slice is a **new module**
`modules/geopolymer/` (module-projects idiom: eventually its own `polari-module-*`
public repo — no private info, book data entered as digitized rows WITH citations, no
scanned pages committed). Frontend in
`polari-platform-angular/src/app/components/materials-science/` (new small components,
not appended to existing ones).

---

## 2. New classes (all `treeObject`, auto DB + CRUDE API)

```
MaterialState                     materialsScience/material_states.py
  material_name, state_name (key '<material>#<state>'), is_canonical,
  processing_stage, thermodynamic_phase, composition_snapshot_json,
  environmental_snapshot_json, parent_state_ids_json, producing_execution_id,
  validation_status, provenance_id

ProcessingStageVocabulary         same file (rows, extensible — NOT an enum)
  seed stages: raw-powder, slurry, reactive-suspension, percolating-gel, set-gel,
  green-body, cured-solid, heat-treated-ceramic, carbonated, oxidized, damaged;
  wax: solid, softened, melt, superheated
ThermodynamicPhase                simple field: solid|liquid|gas|plasma|mixed
  (a gel is thermodynamically condensed but a distinct processing stage — kept separate)

MaterialProcessDefinition         materialsScience/material_processes.py
  name, process_type, execution_effect (OBSERVATIONAL|TRANSFORMATIVE),
  accepted_input_constraints_json (incl. ThermalProcessingProfile admissibility),
  parameter_schema_json, transformation_engine_refs_json, output_state_schema_json
MaterialProcessExecution          same file — the DAG edge
  definition_name, input_state_ids_json, parameter_values_json, schedule_json,
  device_id, output_state_ids_json, measured_observations_json, provenance_id

MultiScaleMaterialStructure       materialsScience/material_structure.py
  state_key, one per MaterialState
ScaleStructureDefinition          same file — per-level view under the structure
  resolution_level, characteristic_length_min/max, domain_type (L2 may have SEVERAL
  rows: gel-domain, capillary-pore, reaction-rim, fiber-interphase, microcrack-network…),
  representation_type, descriptors_json, source, status (defined|partial|planned),
  uncertainty_json

PropertyClaim                     materialsScience/claims.py
  subject_state_key, property_meaning_name, scale_level, value, units,
  evidence_method, assumptions_json, validity_json, source_execution_id,
  confidence_json (optional interval/distribution/variance), provenance_id
  (StructureClaim / ValidationClaim: same shape, different subject field)

EvidenceMethod                    materialsScience/evidence_methods.py
  ONE shared vocabulary object replacing parallel enums. Seeds = union of existing
  DERIVATION_METHODS (measured, rules-of-mixtures, homogenized, coarse-grained,
  dft-parameterized, literature) + estimated, interpolated, ml-prediction, unknown.
  Fields: identifier, category, description, required_provenance,
  default_validation_class, supports_uncertainty.
  MaterialScaleDefinition.derivation_method values become identifiers into this
  vocabulary (values already match — no data migration needed, just validation).

ScaleTransferDefinition           materialsScience/scale_transfers.py
  source_state_key, source_scale, target_state_key, target_scale,
  transfer_method (names a registered engine), assumptions_json, validity_json,
  uncertainty_json, validation_evidence_json
  (first-class promotion of the existing derived_from_name/derivation_method lineage;
  executes through ENGINE_REGISTRY under simulation_gate like everything else)

DigitizedDataset                  materialsScience/digitized_datasets.py
  name, independent_variables_json, dependent_variables_json, units_json,
  source_conditions_json, interpolation_policy, extrapolation_policy (default
  UNSUPPORTED), validity_domain_json, digitization_method, digitization_error,
  source_reference (book/figure/table citation), version, points_json
  (covers both InterpolationCurve and TransformationLookup shapes)

ExposureScenario                  materialsScience/exposure_scenarios.py
  name, environment_json, boundary_conditions_json — reusable across disciplines
  (seed: outdoor, marine, acid, fire, freeze-thaw, high-vacuum, hydroponic…)
MaterialPerformanceScenario       materialsScience/performance_scenarios.py
  = initial MaterialState + part geometry ref + ExposureScenario + loads + duration +
  performance_engine ref; runs as a SimulationDefinition specialization; results =
  claims + promoted result-states (TRANSFORMATIVE ⇒ DAG edges)
```

Existing pieces absorbed, not duplicated: `ThermalProcessingProfile` → admissibility
constraints consumed by `accepted_input_constraints`; `MaterialPurpose` tags → derived
claims ("printable" = ∃ admissible process route); `MaterialRelatedDevice` → the
`device_id` on executions; `Formulation` → per I7.

---

## 3. Phases

### pspp-1 — Evidence + claims + dataset foundation
`evidence_methods.py`, `claims.py`, `digitized_datasets.py` + one generic
`engines/dataset_interpolation.py` (reads DigitizedDataset rows, interpolation with
uncertainty bands, UNSUPPORTED extrapolation refusals per I6). Register classes, seeds
for EvidenceMethod. Selftest: claim round-trip; in-range interpolation with band;
out-of-range refusal names the validity domain and the dataset row (knob).
**No behavior change for any existing consumer.**

### pspp-2 — MaterialState DAG + canonical state + migration safety
`material_states.py` + ProcessingStage vocabulary rows. Migration (nondestructive):
- Boot-time backfill: every existing `MaterialsScienceMaterial` gets one canonical
  state (`<name>#as-defined`, `is_canonical=True`).
- `MaterialScaleDefinition` gains nullable `state_key`; NULL ⇒ canonical (schema-sync
  handles the column add; existing rows untouched).
- New resolver `materialsScience/state_resolution.py`: `resolve_state(material_name,
  state_name=None)` — the ONLY path from name to state (I1). `material_detail`,
  scale gates, waxprint `*_ref`, aquaponics seeds keep working unchanged because they
  resolve through canonical by default.
Acceptance: full existing msci selftest suite green with zero call-site edits; a
two-branch DAG (cured → carbonated | heat-treated) round-trips and a property query
against each branch returns only that branch's claims.

### pspp-3 — Structure layer
`material_structure.py`: MultiScaleMaterialStructure + ScaleStructureDefinition with
L2 multi-domain support. Mandatory descriptor core (exactly 5): `bulk_density`,
`phase_fractions`, `total_porosity`, `moisture_state`, `reaction_extent` — everything
else optional/`planned` per honesty model. Engines declare their own descriptor
requirements (`require_descriptors()` sibling of `require_scale_levels()` in
`scale_presence.py`) — the gate refuses with a pointer at the exact missing descriptor
knob. New scale-qualified `MaterialPropertyMeaning` rows for porosity-per-level (I8).

### pspp-4 — Process layer + DAG edges
`material_processes.py` with ExecutionEffect (I2). Wire `ThermalProcessingProfile`
into `accepted_input_constraints` (a process whose schedule exits the no-volatiles
window refuses, naming the offending component — existing rule, new enforcement
point). `Formulation` bridged per I7 (Formulation row referenced as the mixing
process's input constraint; NOT deleted or moved — legacy path keeps working).
Acceptance: an inadmissible cure schedule is refused with evidence; a TRANSFORMATIVE
execution creates edge + child state; an OBSERVATIONAL engine run attaches claims and
provably does NOT create a state.

### pspp-5 — Scale transfers first-class
`scale_transfers.py` per §2; transfer engines run through ENGINE_REGISTRY +
simulation_gate. Retro-fit: existing wax lineage (paraffin L0 → FEM `wax-thermal-
continuum` L1 → DFT L4) re-expressed as ScaleTransferDefinition rows so the wax world
is the first proof the shape fits — without changing wax behavior.

### pspp-6 — Geopolymer module + Tier-1 deterministic engines
New `modules/geopolymer/` (module-projects idiom). Engines (all
directly supported by the photographed Chapter 5 pages — safe now):
- `CompositionNormalizer` — recipes normalized to moles; supplier-reported convention
  retained separately (book's explicit MR-vs-WR confusion warning).
- `WaterglassMRCalculator` — MR = mol SiO₂ / mol M₂O; WR stored separately, never
  silently converted (K₂O molar mass ≠ Na₂O).
- Baumé ↔ SG: °Bé = 145(1 − 1/SG), SG = 145/(145 − °Bé); temperature convention in
  metadata.
- Commercial silicate-solution composition presets (actual oxide + water composition —
  never "waterglass grade 3.3" as sufficient chemistry).
Selftests with hand-checked numbers for Na and K silicates.

### pspp-7 — Tier-2/3 digitized-data engines  ⚠ blocked on data entry (see §4)
- `EmpiricalQDistributionEngine`: (cation family, MR, state=glass) → Q0–Q4 fractions
  from Fig 5.4 (Na) / Fig 5.5 (K) DigitizedDataset rows; interpolation bands;
  out-of-range unsupported.
- `GlassToSolutionQTransform`: Table 5.6 fixed reference mappings at the listed MRs
  ONLY (no general kinetic law — the source doesn't provide one).
- Q-state derived descriptors (`q_n` = bridging-O neighbors, `m_al` = Al neighbors)
  as functions over the L3 network representation — derived, never replacing the graph.
Tier 4/5/6 (viscosity Fig 5.20, solubility Fig 5.22, polymerization degree /
dissolution times) = same DigitizedDataset pattern, added whenever the data arrives;
no code changes needed (I6 pays off here).

### pspp-8 — ReactionProgressModel + the vertical slice
`ReactionProgressModel` as a versioned interface: **v1 = measured extent-vs-time curve
only** (user-entered or fit from a measured series, evidence_method=measured|
calibrated). v2 piecewise-empirical / v3 Arrhenius / v4 coupled-dissolution are
registered-unimplemented (I5 — per ChatGPT: do not build even a provisional Arrhenius
engine unless activation parameters cite a specific source).
Seed the slice: calcined kaolin + Na/K silicate + water + sand →
`raw-powder → activated-slurry → percolating-gel → cured-solid` state chain with
executions as edges; structure rows carrying the 5 mandatory descriptors (measured or
`planned`); Q-distribution and microcrack density start `planned` — schema present,
honestly absent.

### pspp-9 — Performance scenarios
`exposure_scenarios.py` + `performance_scenarios.py` riding the existing
SimulationDefinition / MultiScaleSimulationDefinition machinery (stage gates declare
required scale levels AND descriptors for the input state). First two engines,
explicitly provisional, requirements-declared:
- `PoreStructureToWaterTransportEstimate` (needs open/connected porosity + pore-size
  summary),
- `StructureToElasticEstimate` (needs bulk density + phase fractions + porosity;
  Voigt/Reuss/Hill bounds from existing `formulation_math`, labeled as bounds).
Degradation engine INTERFACES registered-unimplemented: geopolymer (carbonation,
efflorescence-risk, alkali leaching, wet-dry, freeze-thaw, thermal dehydration) and
CMC (oxidation recession, creep rupture, interface degradation…) — source targets for
future book-page ingestion.
Acceptance: slice runs end-to-end — cured state + hydroponic ExposureScenario →
moisture scenario produces claims; a compressive scenario returns bounded elastic
claims; scenario against a state missing `connected_porosity` refuses pointing at the
descriptor knob.

### pspp-10 — Frontend
Material detail page gains: state-DAG view (nodes/edges, canonical badge, click →
per-state detail), claims rendered with evidence-method badges + validity ranges,
structure-by-level panel with L2 domains, process execution history. New small
components beside `material-detail.component.*`, backed by extensions to
`materials-basis.service.ts` / `materials-basis-types.ts`. (D3 DAG rendering can
follow the existing no-code canvas idioms.)

### pspp-11 — Generality proof (wax + CMC skeleton)
- Wax: map the existing waxprint world onto states (solid → softened → melt →
  superheated ProcessingStages; feedstock claims sourced from canonical state) —
  behavior unchanged, representation upgraded.
- CMC: enter the minimal ceramic-composite schema **as data only** (structure
  descriptor meanings: reinforcement volume fraction, orientation tensor, interface
  type/shear strength/fracture energy, matrix crack density, fiber strength
  distribution, coating stack…; process vocabulary: CVI, PIP cycles, melt
  infiltration, sintering profiles) with zero new engines — equations wait for the
  ceramic book's chapter pages (only its ToC is ingested).
This phase is the test that PSPP generalizes beyond geopolymers; it must require no
schema changes. If it does, the schema was wrong — fix before declaring done.

---

## 4. External dependency — book-figure digitization (Dustin)

pspp-7 needs digitized points (photographs → number pairs) with per-dataset metadata
(axes, units, source conditions, digitization method + error, citation).
**Captured 2026-07-18** from Dustin's page photos (pp. 101/103/110/112) into
`PSPP_DIGITIZED_DATASETS.json` (seed-ready DigitizedDataset rows + qualitative
claims: pH/stability constraints §5.9, metasilicate hydrate presets §5.11,
liquid-NMR Q4-artifact caveat):

| Tier | Source | Status |
|---|---|---|
| 2 | Figs 5.4/5.5 p.90: MR→Q0..Q4 for Na/K GLASSES (Maekawa et al. 1991) | ✅ CAPTURED — digitized with Table 5.6 cross-confirmation + p.90 text anchors (MR=1/2/4); `q_glass_distribution` + `glass_to_solution_q` engines LIVE (pspp-7 core done) |
| 3 | Table 5.6 (glass→solution Q at listed MRs) | ✅ exact transcription |
| 4 | Fig 5.20 viscosity (Na MR=2, K MR=2.2 vs T) | ✅ printed point labels; concentration unstated → relative curves only |
| 5 | Fig 5.22 solubility vs temperature | 🟡 shape only — angled photo, RE-SHOOT requested before points entered |
| 6 | Tables 5.4/5.5 (MR→mol. weight + polymerization degree) | ✅ exact transcription |
| — | p.84: MR=1.032·WR (Na), 1.568·WR (K); Table 5.1 commercial MRs; practical range 0.4–4.0 | ✅ encoded in `pspp.composition_math`, selftest-pinned |
| — | p.85 Fig 5.1: production flow chart (furnace + hydrothermal, after Crosfield 1997) | ✅ noted — process-vocabulary evidence for pspp-4 |
| — | Fig 5.21 (pH vs MR and M₂O concentration) | not yet photographed |
| — | Ch.8 reaction-window numeric ranges + patent benchmark examples | ⚠ NEEDED for ReactionWindow rows + pspp-9/11 validation cases |

Tier 1 (pspp-6) is essentially DONE early (composition_math). Book citation confirmed:
Davidovits, *Geopolymer Chemistry and Applications* (edition still to note).
Still wanted from Dustin: the **MR→Q glass distribution curves**, a straight-on
**Fig 5.22** re-shoot, **Ch.8 ranges/patent examples**, optionally Fig 5.21.

## 4b. GAP REGISTER (2026-07-19, end of the pspp-8/V3/11 build) — the
## to-address list. Architecture is CLOSED: every gap below is (a) data
## entry, (b) an engine behind an already-registered seam, or (c) debug/
## polish. None requires schema change or redesign. Ordered by leverage.

### A. Engine gaps behind existing seams (code, no schema)
- **A1 Time-resolved kinetics execution.** ReactionRule already carries
  `kinetics_status`/`kinetics_ref`; `rule_rate` refuses even for a
  calibrated rule ("calibrated kinetics execution not yet implemented").
  Closing = an integrator engine (ReactionProgressModel v2 piecewise /
  v3 Arrhenius per §pspp-8) that consumes CITED calibration rows and
  steps amounts through `network_stepping.step_once` over time. Blocked
  on data (D1) by design — never build with invented constants (I5).
- **A2 Solid-gel structure evolution.** reactionExtent lands as a
  StructureClaim at checkpoints, but nothing predicts the cured gel's
  own Q-distribution / porosity development. Today: measured
  StructureClaims only. Closing = engine over the same 5-descriptor
  core + L3 network representation; the Q-motif species are already
  the dynamic resource it would update.
- **A3 Degradation/durability engines.** Carbonation, efflorescence
  risk, alkali leaching, wet-dry, freeze-thaw, thermal dehydration are
  registered-unimplemented interfaces (pspp-9). Each closes as engine +
  cited rows when its book pages arrive; the carbonated/damaged
  ProcessingStages and exposure scenarios already exist to receive
  results.
- **A4 Strength prediction.** Deliberately refused (I5). If ever
  loaded, Ryshkewitch etc. = SELECTABLE models with fitted parameters
  + explicit applicability (claims carry the model name), never "the"
  strength law. Benchmark case 2 (Fig 8.18 series) is the ready-made
  validation target.
- **A5 Amount-tracked reachability.** `reachable_frameworks` is
  presence-only (correct without rates); once A1 exists, closure can
  weight branches by consumption — competing frameworks would get
  predicted FRACTIONS instead of open/closed. Case 1's ~50/50
  nepheline/albite is the validation target.

### B. Data asks (Dustin/book — every one already named by a refusal)
- **B1 K glass→solution Q table** (Table 5.6 is Na-only): lights up K
  pathway inventories; today `solution_inventory('K', …)` refuses with
  this exact ask.
- **B2 Kinetics calibrations** (any cited rate law + constants):
  unlocks A1. Per-rule via `kinetics_ref`.
- **B3 Fig 5.22 straight-on re-shoot** (solubility vs T — dataset is
  status=provisional, shape-only).
- **B4 Ch.6 Fig 6.6 molecule types; Ch.7 kaolinite steps 1-7 pages;
  CMC chapter equations** (turn cmc_library data into engines).
- **B5 Setting-class completion times for classes 3/4 + more exotherm
  ladders** (extends progress_engine v1 coverage; today refuses
  off-table MRs and non-80C temperatures except near MR=1.83).
- **B6 p.191 cut-off "preferably…" text** (would refine Table A bands
  the way p.193 refined Table C).

### C. Debug/polish list (rough-functionality build, no browser pass)
- **C1 Staging deploy + live verify**: backend rebuild for new routes/
  classes (all seeds add-only, no volume surgery); then browser pass on
  /pspp/{benchmarks,guide,states} + banded grader gauges.
- **C2 Benchmark overlay measured panels** are raw JSON pretty-print —
  want per-aspect renderers (EDS table, pH ladder, strength series
  chart from the mk750 dataset row).
- **C3 State-DAG layout** is naive depth-columns; no zoom/pan; wax
  route picker UX minimal. Also: mount `pspp-state-dag` on
  material-detail (seam identified, not wired).
- **C4 "Editable on canvas" v1** = links to /class-main-page/:class;
  v2 = inline edit in the network panel + grader (CRUDEservicesManager
  already exposes full CRUD).
- **C5 Guide page K-path UX**: refuses correctly (B1) but should
  surface the qualitative-inventory fallback the benchmark overlay
  uses, so K users still see open/closed routes.
- **C6 Checkpoint UI**: /api/pspp/checkpoint has no page (plan/apply
  buttons + the planned rows rendered before apply).
- **C7 Threshold-window selftest coverage in-container** + add the 6
  new suites to `pol modules selftest pspp` discovery verification.

### D. Structural decisions (Dustin)
- **D1 pspp-6 split**: geopolymer folded into modules/pspp — decide
  whether to split per module-projects idiom (registry entry, subtree
  repo) or bless pspp as the umbrella.
- **D2 Spatially-resolved geopolymer sims** (fields over part geometry
  vs summary descriptors): least-exercised path; seam = scale
  transfers + SimSpace/FEM like the wax world. Decide if/when a use
  case needs it.
- **D3 Uncertainty propagation** through transfers/stepping (v1 =
  per-claim intervals only) — deferred per §5.

## 5. Explicitly deferred / out of scope

- Uncertainty **propagation** through transfers (v1 = EvidenceMethod + optional
  interval per claim; full UQ later).
- Universal kinetic/strength laws (I5) — including Ryshkewitch, which if ever loaded
  is a *selectable model with fitted parameters and explicit applicability*, never
  "the geopolymer strength equation".
- CMC mechanics beyond rule-of-mixtures bounds + efficiency-factor interface
  (η_o, η_l must come from a named model/fit — no arbitrary defaults).
- Renaming existing sim-state classes to `SimulationFrame` (vocabulary only for now).
- Legacy `polariMaterialsScienceModule` OO-tree restructuring — the basis remains the
  bridge; System A untouched.
