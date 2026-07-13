# FEM/DFT Simulation Interfaces + No-Code Engine States + Recursive Multi-Scale Composition (msci-15…19)

## Context

Dustin's directive (2026-07-07, two messages):
1. **First priority: configure FEM and DFT simulations as multi-scale models in the general case, as templates; then NEST those to build the materials-science multiscale model as pure configuration** ("MultiScale Models incorporating abstracted multiscale model components"). Decisions locked: template layer over EXISTING solvers only; FULL recursive sub-models; input slots bind to values OR object refs.
2. **Refinement (rejected the generic-only shape): FEM and DFT need SPECIFIC simulation interfaces** — these are extremely complicated model families; mirror how existing tools structure them and build specialized UI at the simulation level. **Also: FEM/DFT no-code STATES** so custom physics/chemistry logic can weave engine calls into no-code solutions.

Today FEM/DFT are three hard-coded `ENGINE_REGISTRY` lambdas (`materialsScience/scale_execution.py`) consumed by `EngineComputation` rows and the formulation runner's FEM rung. No domain-shaped configuration objects, no typed schemas, no object-ref binding, no nesting, no engine access from no-code.

**Domain grounding for the interfaces (what "existing tools" do):**
- FEM problem definition (COMSOL physics interfaces, FreeCAD FEM workbench, SfePy problem descriptions, ANSYS): **Domain/Geometry → Material assignment (per region) → Physics + Boundary Conditions → Mesh → Solver/Study → Results.**
- DFT calculation setup (Quantum ESPRESSO namelists &CONTROL/&SYSTEM/&ELECTRONS + ATOMIC_SPECIES/K_POINTS cards, ASE calculators, pymatgen input sets like MPRelaxSet): **Structure (molecule/bulk) → Method (theory level, basis/plane-waves, XC functional, pseudopotentials, charge/spin) → Accuracy (cutoffs, k-point mesh, convergence) → Calculation type (SCF energy / structure build / relax later) → Outputs.**
These section vocabularies ARE the specialized interfaces; today's engines fill a small subset of each section honestly (unsupported choices = evidence-bearing refusals naming the gap, per knobs-and-suggestions).

**This plan supersedes the completed msci-0..14 plan.** First implementation step: copy this file to `~/Desktop/polari-suite/ENGINE_TEMPLATES_PLAN.md` and update the materials-science memory file to point at it (chat will be renewed).

**Base:** all msci-0..14 work is committed + live on staging A. Framework tip on `dev-msci-14-pages` (fcac649), angular on `dev-msim-profile-ui` (53651e6). Branch per confirmed phase, selftest + live verify each.

## Verified machinery (exploration + design pass done — trust this, verify line numbers)

- **Engines** (`materialsScience/engines/`): `fem_engine.solve_steady_conduction(thermal_conductivity, heat_source=1.0, refine=4)`; `fem_engine.effective_conductivity(matrix_k, inclusion_k, volume_fraction, refine=5)` (vf (0,0.6)); `dft_engine.molecular_energy(atoms, basis='6-31g', xc='b3lyp', charge=0, spin=0)` (pyscf local→worker ladder); `dft_engine.build_bulk_structure(symbol, crystal, lattice_a)`; `dft_engine.total_energy(symbol, crystal, lattice_a, ecutwfc=30.0, kpts=(3,3,3))` (QE, usually refuses). All `{ok,...}|{ok:False,error,suggestion}`, never raise; `capability()` on both (dft has 3 layers: structureLayer/molecularLayer/executionLayer). Worker HTTP (msci-engines :9500) has ONLY /capability, /dft/molecular-energy, /fem/conduction.
- **One-shot verdict:** SimulationRunner is per-timestep over *SimState rows; FEM/DFT solves are one-shot stage executors. **`materialsScience/formulation_stage.py` is THE executor precedent**: reshape into the `run_stage_search` contract `{achieved, winner{run,candidate,derivedValues}, winners, searchComplete, exhausted, totalCandidates, attempted, advancedThisCall, attempts, backend, warnings, error}`; gates reuse `multi_scale_stages.evaluate_gate_over_fields(manager, stage, flat)`; dispatch = `stage.get('kind')` branches in `simulation_api.on_post_stage_search` (~line 724, before the candidates 400) and `on_post_stage_gate` (~line 654, before `_find_run`); `apply_derive` flows winner derivedValues onward; `parse_stages` keeps unknown kinds.
- **NO server-side stage context exists** — `deriveResolved` is per-HTTP-call, consumed by the frontend (`msim-ic-panel.component.ts` ~line 400). `stageDerived` bindings therefore need a context builder that RE-EVALUATES upstream stage gates at resolve time (all gate evaluators are pure server-side calls over persisted rows — cheap and honest).
- **`validate_composition`** (`simulations/simulation_intents.py`): default intent expression (~line 155) is `'observe' if kind=='coStep' else 'search'` — new kinds need a kind-aware default or they trip the search-family candidates rule (~line 184, already extended once for `formulationSearchRef`). PRODUCT_BEARING=(search, feasibility, optimize, calibrate); derive requires product-bearing; `'calibrate'` fits engine solves that parameterize later stages, `'validate'` for evidence-only.
- **`execute_scale_definition`** hard-rejects `definition_class != 'EngineComputation'` (~line 72) — bridge = added branch, back-compat byte-identical.
- **Seed locations** (polariServer.py): msci object seeds in `_seedSimSpace3D` (~1304-1332); msim/profile seeds in `_seedSimulations` (~1377-1439); defClassList ~line 506; APIs instantiated ~467-490. `upgrade_msim_rows` (multi_scale_seed.py:404) refreshes ONLY pendulum msim panels/profile_ref — edited seeds do NOT reach existing volumes otherwise → new rows, not edited rows; profile changes need a new shape-guarded `upgrade_profile_rows` or documented delete+restart.
- **Profiles/conformance:** `MultiScaleSimulationProfile.fidelity_ladder_json` `[{rung, level, engines, costClass, purpose}]`; `check_profile_conformance` is kind-agnostic (matches stage templates by (kind,intent), inspects slot keys) — new stage kinds work with zero checker changes.
- **No-code precedent:** SolutionExecutionEngine (`polariNoCode/SolutionExecutionEngine.py`) walks state graphs executing operation types (arithmetic/comparison/matrix/equation); `MatrixEquationOperation` was added end-to-end before (backend operation + polyTyped def class + frontend no-code node with responsive LOD tiers + operand bindings — see memory `matrix-equation-operation-node`). Mirror that for the engine operation. **Survey the exact operation-registration seam at impl time** (how the engine dispatches an operation class → executor; where node components register in the editor).
- **Conventions:** one class per file; treeObject/@treeObjectInit + defClassList + seed pairs; small self-registering falcon APIs (profile_api.py / formulation_search_api.py); selftests w/ stub-manager pattern (selftest_formulation_objects.py — monkeypatch row classes to SimpleNamespace factories; lazy imports read patched attrs); honest refusals+suggestions; avoid SQL reserved words; Alpine backend pure-python; API classes get self.manager via the manager= kwarg. Frontend: msim page stage recognition via `stageHasSearch`/`stageKindLabel`; DisplayDefinition pages via `registerMsciDisplayComponents` (msci-14 pattern); pageRoute now resolves at /display/<route>.
- **Staging:** compose services `frontend`/`backend` in polari-rf-node/docker-compose.staging-nip.yml, `LOCAL_IP=192.168.0.210`; backend restore ~150s; API `curl -k -H "Host: api.prf.192.168.0.210.nip.io" https://localhost/...`; frontend https://prf.192.168.0.210.nip.io. Bash cwd persists between calls.

---

## Phase 15 — Domain-shaped model definitions + catalog + resolver + bridge (branch `dev-msci-15-engine-models`, framework)

### The specialized interfaces (Dustin's refinement) — three objects, one class per file, all in `materialsScience/`:

**`engine_model_template.py` — `EngineModelTemplate`** (the solver/calculation CATALOG row — which physics/calculations exist, their schemas per section, what capability they need):
```
name ('fem-steady-conduction'|'fem-effective-conductivity'|'dft-molecular-energy'|
      'dft-bulk-structure'|'dft-total-energy'),
display_name, description, engine_kind ('fem'|'dft'), engine_key (ENGINE_REGISTRY),
# Typed slots grouped by the DOMAIN SECTIONS above:
# [{"section": "domain|materials|boundaryConditions|mesh|solver"   (fem)
#              "structure|method|accuracy|calculation"             (dft),
#   "key","type"('number'|'integer'|'string'|'vector'),"unit",
#   "required","default","min","max","description"}]
parameter_schema_json,
outputs_json,                    # [{key,type,unit,description}]
cost_class ('cheap'|'moderate'|'expensive'),
capability_requirements_json,    # ["fem"] | ["dft.molecularLayer"] | ["dft.structureLayer"] | ["dft.executionLayer"]
notes, enabled
```
Module-top assertion: every engine_key ∈ ENGINE_REGISTRY, schema keys match the registry lambda's input names (profile-seed assertion pattern).

**`fem_model_definition.py` — `FEMModelDefinition`** (the FEM-specific simulation interface — a configured FEM problem, sectioned like FEM tools):
```
name, display_name, description,
physics_ref,                 # EngineModelTemplate name (fem-* row) — the physics/study
domain_json,                 # geometry: {"shape":"unit-square", "inclusion":{"shape":"circle","volumeFraction":...}} — honest: only what the engines support; unsupported shapes refuse naming the gap
materials_json,              # per-region: {"matrix":{"thermalConductivity": <binding>}, "inclusion":{...}} — values here are BINDINGS (see resolver)
boundary_conditions_json,    # [{"boundary":"all","type":"dirichlet","value":0}] — v1 fixed set per physics; others refuse w/ suggestion
source_terms_json,           # {"heatSource": <binding>}
mesh_json,                   # {"refine": 4}
solver_json,                 # {} v1 (engine defaults) — the section exists so the interface is honest about where solver knobs go
last_result_json, last_executed_at, notes, enabled
```

**`dft_model_definition.py` — `DFTModelDefinition`** (the DFT-specific simulation interface, sectioned like QE/ASE/pymatgen input sets):
```
name, display_name, description,
calculation_ref,             # EngineModelTemplate name (dft-* row) — the calculation type
structure_json,              # {"kind":"molecule","atoms": <binding>} | {"kind":"bulk","symbol":...,"crystal":...,"latticeA":...}
method_json,                 # {"basis": <binding|value>, "xc":..., "charge":0, "spin":0, "pseudopotentials": null (v1 honest: QE layer only)}
accuracy_json,               # {"ecutwfc":30.0, "kpts":[3,3,3]} (used by total-energy; ignored-with-note by molecular)
last_result_json, last_executed_at, notes, enabled
```

A **binding** anywhere in the section JSON is `{"kind":"value","value":...}` | `{"kind":"objectRef","className":...,"name":...,"path":"parameters_json.inputs.matrixK"}` | `{"kind":"stageDerived","stage":"<stageKey>","key":"candidate.score"}`; bare literals are treated as `{"kind":"value"}` for ergonomics.

### Shared machinery:
- **`component_binding.py`**: `validate_model(manager, model_row) -> {ok, findings, suggestions}` (sections vs the template schema: required unfilled → error naming the section+key; unknown → warning; type/min/max); `resolve_model(manager, model_row, stage_context=None) -> {ok, inputs, resolved(provenance per param), refusals}`. objectRef path-walking: getattr first segment; str values json.loads'd and walked (dict keys / int list indices); refusals list available keys as evidence. stageDerived resolves from `stage_context["<stage>.<key>"]`; absent context → refusal + "run/gate the upstream stage first". Section→engine-input flattening lives here (e.g. materials_json.matrix.thermalConductivity → matrixK per a per-template section-map on the template row: add `section_map_json` to EngineModelTemplate mapping schema keys → section paths).
- **`model_execution.py`**: `find_model(manager, name)` (searches both definition classes); `check_capability_requirements(template)`; `execute_model(manager, name, stage_context=None) -> {ok, model, template, engine, inputs, resolved, result|error+suggestion, executedAt, persisted}` — validate → capability-gate BEFORE the engine call → resolve → `ENGINE_REGISTRY[engine_key](inputs)` → persist last_result_json/last_executed_at on the model row.
- **ENGINE_REGISTRY additions** (scale_execution.py): `'dft.bulk-structure'`, `'dft.total-energy'` (kpts arrives as list → tuple in the lambda).
- **EngineComputation bridge**: `execute_scale_definition` accepts `definition_class in ('FEMModelDefinition','DFTModelDefinition')` with `definition_ref` = model name → delegates to `execute_model`, stores result on the scale row identically (partial→defined). Existing EngineComputation rows byte-identical.
- **Seeds** (`engine_model_seed.py`): the 5 templates (schemas transcribed from verified signatures, section-tagged) + 2 models: `wax-thermal-continuum` (FEMModelDefinition, physics fem-effective-conductivity; materials matrix/inclusion k bound objectRef → `beeswax-carnauba-blend@L1` row's `parameters_json.inputs.matrixK/.inclusionK` (live 0.25/0.30), inclusion volumeFraction value 0.2, mesh refine 5) and `paraffin-quantum-energy` (DFTModelDefinition, calculation dft-molecular-energy; structure.atoms bound objectRef → `paraffin-wax@L4` row's `.inputs.atoms` propane fragment; method basis/xc objectRefs to same row). Seed pairs in `_seedSimSpace3D` after MaterialScaleDefinition (templates before models).
- **API** (`engine_model_api.py`, FormulationSearchAPI pattern): `GET /api/msci/engine-templates` (+live capability verdict per template), `POST /api/msci/models/{name}/validate`, `POST /api/msci/models/{name}/execute` {stageContext?}.
- **Selftest** `selftest_engine_models.py` (stub-manager): seed/registry coherence incl. section maps; validate (required/min/max/unknown); resolve (value/objectRef JSON-path incl. bad-path refusal w/ available keys; stageDerived with+without context); execute end-to-end w/ real scikit-fem (or assert honest refusal shape if lib absent — pass either way); capability-gated dft-total-energy refusal; bridge through execute_scale_definition + EngineComputation back-compat locked verbatim.
- **Live verify:** GET engine-templates (5 w/ verdicts); execute wax-thermal-continuum → effectiveK within bounds; edit the blend@L1 row's matrixK via CRUDE → re-execute → input changed (the object-coherence proof); DFT model executes via worker.

## Phase 16 — `engineModel` + `subModel` stage kinds, stage context, intents (branch `dev-msci-16-nesting`, framework + tiny angular)

- **`simulations/engine_model_stage.py`**: `build_stage_context(manager, msim, upto_stage_key)` — walk prior stages, evaluate each's EXISTING gate over its newest persisted artifact (formulationSearch → newest FormulationSearchRun → evaluate_formulation_gate; engineModel → the model row's last_result flattener; runToCompletion → newest SimulationRun → evaluate_stage_gate; subModel → its gate), namespace `"<stageKey>.<key>"` + `"<stageKey>.__complete"`. `run_engine_model_stage(manager, msim_name, stage, body)` — stage `{key, kind:'engineModel', intent:'calibrate'|'validate', modelRef, gate{solutionRef?,failReason}, derive{params}}` → execute_model w/ built context → single-attempt stage-search contract (candidate = resolved inputs flat readable w/ provenance; derivedValues = `model.<outputKey>` + `input.<param>`; achieved = ok/gate; extras in report['engineModel']). `evaluate_engine_model_gate` over the model row's persisted result (never executed → honest refusal); solutionRef → evaluate_gate_over_fields.
- **`simulations/sub_model_stage.py`**: stage `{key, kind:'subModel', intent:'search', msimRef, gate?, derive?}`. v1 semantics (honest): walk child stages in order — engineModel/formulationSearch/subModel execute directly (child context accumulates; formulationSearch gets attemptTag `sub:<parent>` namespacing); runToCompletion/coStep are gate-CHECKED only (auto-driving stepping sims = out of scope; incomplete child stage → honest non-achievement naming the stage + suggestion linking `/multi-scale-sim/<child>`). Cycle guard (visited set incl. parent) + MAX_SUB_MODEL_DEPTH=8. Report: one attempt per child stage; derivedValues namespaced `sub.<childStageKey>.<key>`; extras report['subModel']={child, childStages, blockedAt}.
- **Dispatch:** two kind branches each in on_post_stage_search + on_post_stage_gate (formulationSearch branch mirrored byte-for-byte in structure).
- **Intents:** kind-aware default intent (coStep→observe, engineModel→calibrate, subModel→search, else search); candidates rule accepts modelRef/msimRef; typed existence checks (modelRef resolves in either model class + its template exists; msimRef exists); static subModel cycle detection (DFS, error names path). Regression: pendulum + wax-derivation findings unchanged (selftested).
- **Conformance:** zero checker changes (kind-agnostic); recursive roll-up deferred, noted.
- **Angular (tiny):** `MsimStage` += modelRef/msimRef; stageHasSearch += both kinds; stageKindLabel ("one-shot engine solve over the configured model", "nested multi-scale sub-model") + chip link to the child msim.
- **Selftests** `selftest_engine_model_stage.py` + `selftest_sub_model_stage.py`: contract-key equality (reuse CONTRACT_KEYS from selftest_wax_derivation); context builder namespacing + incomplete-upstream omission + stageDerived binding resolution through it; gate default vs solutionRef; subModel child-exec/blocking/cycles/depth; validate_composition new cases + regressions.

## Phase 17 — Specialized FEM & DFT configuration UI (branch `dev-msci-17-model-ui`, angular + page seeds)

The simulation-level interfaces Dustin asked for — sectioned the way practitioners expect:
- **`components/materials-science/fem-model-config.component.*`** — sections as collapsible groups: **Domain & Geometry** (shape picker — honest: only supported geometries selectable, others visible-but-disabled with the gap named), **Materials** (per-region property rows with a binding editor: literal / object-ref picker (class+row+path browser over parameters_json) / stage-derived key), **Boundary Conditions** (typed rows; unsupported types disabled w/ reason), **Mesh** (refine slider + element count estimate from prior results), **Solver** (v1: engine defaults, section visible), **Outputs** (declared outputs from the template). Header: physics picker (fem-* templates) + live capability banner + Validate + Run buttons (validate/execute endpoints) + last result display (k_eff vs Voigt/Reuss bounds visualized for homogenization; T-field stats for conduction).
- **`components/materials-science/dft-model-config.component.*`** — **Structure** (molecule: atoms geometry text w/ object-ref binding, atom count preview via bulk-structure/capability; bulk: symbol/crystal/lattice), **Method** (basis + XC dropdowns w/ common presets: 6-31g/cc-pVDZ…, B3LYP/PBE…; charge/spin; pseudopotentials section present-but-gated w/ the QE note), **Accuracy** (ecutwfc, k-points — marked which calculation types consume them), **Calculation** (dft-* template picker: SCF energy / bulk structure / total energy), **Outputs** + capability banner (3 DFT layers shown honestly) + Validate/Run + last result (energy in Ha and eV, convergence flag).
- Shared `model-binding-editor.component.ts` (the literal/objectRef/stageDerived picker — reused by both).
- **Pages**: DisplayDefinition seeds `fem-models` + `dft-models` (pageRoute; list + edit via the config components; msci-14 pattern with registerMsciDisplayComponents additions). Links from the Materials Science home card.
- Services: `engine-model.service.ts` (templates+capability, models CRUDE read/save FormData, validate/execute).
- **Selftest** additions to `selftest_msci_pages.py` (routes, componentNames); ng build clean; live: configure a model in the browser, validate, run, see the result + the bound source row edit reflected.

## Phase 18 — No-code engine states (branch `dev-msci-18-nocode-engine`, framework + angular)

Weaving custom physics/chemistry logic into simulations via the engine — mirror the MatrixEquationOperation end-to-end precedent:
- **Impl-time survey first** (30 min): how SolutionExecutionEngine dispatches operation classes (the seam MatrixEquationOperation used), how operand ValueSourceConfigs resolve, how the frontend registers node components + LOD tiers.
- **Backend**: `EngineModelOperation` (polyTyped def class like MatrixEquationOperation): references a model by name (or inline template+bindings), operand bindings map solution-context values → model input overrides (stage_context analog), outputs write the engine result keys into the execution context (so downstream no-code states compute on totalEnergyHa/effectiveK/etc.). Execution path calls `execute_model` with binding_overrides; refusals become the state's honest error (trace-visible). Capability gating identical.
- **Frontend**: the no-code editor node (responsive tiers, operand binding UI, live trace values, full-size popup — clone the MatrixEquationOperation node structure), listed in the editor's node palette under a Physics/Chemistry group.
- **Selftest**: a SolutionDefinition graph that binds two literals → EngineModelOperation (fem-effective-conductivity) → arithmetic on effectiveK → ReturnValue; executes through SolutionExecutionEngine with the real engine; refusal path when the model/template is missing. This also means **msim GATES can now contain engine calls** (gates run through the same engine) — note it, don't build extra.
- Live verify: author the demo graph in the editor on staging, execute via the existing solution-execution endpoints.

## Phase 19 — Materials science AS configuration (branch `dev-msci-19-materials-config`, framework + verify)

The retrofit proof: **`wax-multiscale` msim = subModel(wax-derivation) → engineModel(wax-thermal-continuum) → engineModel(paraffin-quantum-energy)** — NEW msim row (edited seeds don't reach existing volumes), `wax-derivation` untouched.
- Seed (`wax_multiscale_seed.py`): stages as above (screening subModel derives `sub.formulation-screening.candidate.score`; continuum-verify intent calibrate derives `derived.effectiveK` = `model.effectiveK`; quantum-evidence intent validate). Panels: explainer (nesting story) + subModel link card + the engineModel stages via the stage UI.
- Profile extension (multi_scale_profile_seed.py): materials-science gains optional engineModel stage templates (continuum-verification/quantum-evidence) + `templates` key on fidelity ladder rungs naming EngineModelTemplate rows. Add shape-guarded `upgrade_profile_rows` (mirroring upgrade_msim_rows) OR document delete+restart of the 2 profile rows on staging.
- Bridge demo scale row: new `beeswax-carnauba-blend@L1c` (`definition_class='FEMModelDefinition'`, `definition_ref='wax-thermal-continuum'`, derivation homogenized, partial).
- `selftest_wax_multiscale.py`: parses, validates (no cycles), conforms, subModel over stubbed child, bridge row executes.
- **Live end-to-end:** /multi-scale-sim/wax-multiscale runs all three stages (screening nests the whole derivation; FEM from object-bound inputs; DFT via worker); conformance green on all msims; editing a bound source row changes the next execution's inputs.

## Risks
1. **subModel v1**: child stepping stages gate-checked, not auto-driven (needs a headless run-to-completion engine — flagged follow-up).
2. **Stage context recomputed, not persisted** — upstream reruns change stageDerived values silently between calls; provenance in every report mitigates; persisted context = future.
3. **Section→engine-input maps** couple the domain interfaces to today's narrow engines; every unsupported section choice must refuse naming the gap (that IS the design), and new physics later = new template + section map, no interface change.
4. **No-code operation seam unverified** — Phase 18 starts with its own survey; MatrixEquationOperation proves the path exists.
5. **Long HTTP calls** (subModel chains w/ worker DFT up to 300s/component) — check gunicorn timeout on staging before live verify; cost_class surfaces in reports.
6. **Profile/seed idempotency** — new rows seed cleanly; profile edits need the upgrade guard or delete+restart (documented per phase).

## Verification (cumulative)
Selftests from polari-framework/ (`python3 -m materialsScience.selftest_engine_models`, `simulations.selftest_engine_model_stage`, `simulations.selftest_sub_model_stage`, `materialsScience.selftest_wax_multiscale`) + regressions (multi_scale_page 48, msim_profile 15, formulation_objects 25, wax_derivation 17, msci_pages 6+). `npx ng build --configuration development` clean per frontend phase. Live per phase on staging A (compose build/up, LOCAL_IP=192.168.0.210, backend ~150s). Final: wax-multiscale runs nested live; the FEM/DFT config pages configure/validate/run their models; a no-code graph calls the FEM engine; commit per confirmed phase.
