# MD + Mesoscale Engines → L2/L3 Models (msci-25, msci-26, msci-27)

**STATE 2026-07-10 (evening): ALL THREE PHASES ✅ BUILT +
LIVE-VERIFIED. PLAN COMPLETE.**

msci-27 executed same day: md-model-config + meso-model-config
components (angular dev-msci-27-md-meso-ui 4d3883f), pages
/display/md-models + /display/meso-models seeded, nav + level-page
on-ramps, no-code bead-spring case (8/8), and one backend gap closed
along the way — execute_scale_definition now accepts
MDModelDefinition/MesoModelDefinition rows (framework
dev-msci-27-md-meso-ui b97052f), so the L2/L3 scale rows flipped
partial→DEFINED live: carbon-nanotube@L2, wax-ferrite@L2,
paraffin-wax@L3 all carry results on the rows now. use-as-threshold
binding PUT proven end-to-end (original 0.005 model untouched);
derived-vfc comparison live (157.7 vs 227.3 S/m). 22/22 smoke.
Remaining tail: Dustin's browser review; repos NOT pushed.
Deploy gotcha: recreating prf-frontend/prf-backend changes container
IPs — pol-proxy caches them; `docker exec pol-proxy nginx -s reload`
after every up -d --build.

## (superseded) PICK UP HERE — msci-27 execution context
- Backend work lives on polari-framework branch `dev-hwsim-1-renode`
  (contains everything through msci-26; suite pointer cd9d9d4+). All
  backend seams msci-27 needs ALREADY EXIST — this phase is Angular +
  page seeds + one no-code selftest case; no new backend endpoints.
- Frontend repo: polari-platform-angular, branch `dev-tests-frontend`
  (current head bd678d1) — cut `dev-msci-27-md-meso-ui` from it.
- Live facts to render in the UIs (from the msci-26 live runs):
  lj-reference-fluid T* 0.988 / U*/N −4.71 / P* 1.58;
  paraffin-bead-spring bond 0.965 (KG lit ~0.97), Rg 1.65;
  cnt-percolation-threshold vf_c 0.00754 (1.08× Balberg limit 0.007,
  aspect 100); ferrite-chaining λ=12 → chainsFormed (0.647/0.657).
  THE COMPARISON the results panel must show: derived vf_c 0.00754 →
  σ_eff 157.7 S/m vs assumed 0.005 → 227.3 S/m (the
  cnt-wax-percolation-derived-vfc variant already binds it live).
- APIs in place: GET /api/msci/capability (fem/dft/md/meso incl.
  forceFieldMD + dpd named gaps), engine-templates (11: md-lj-melt,
  md-bead-spring-melt, meso-rod-percolation, meso-dipolar-chaining
  new), POST /api/msci/models/{name}/validate + /execute (find_model
  covers MDModelDefinition + MesoModelDefinition; sections system /
  thermodynamicState / integration / sampling; objectRef bindings
  resolve — the use-as-threshold button writes such a binding).
- Deploy: docker compose -f docker-compose.staging-nip.yml --env-file
  .generated/.env.staging up -d --build prf-frontend (backend already
  carries msci-26). Selftests: python3 -m materialsScience.<mod> from
  polari-framework/.
- Execute msci-27 steps 1-6 below EXACTLY as written (they were
  designed against the msci-17 FEM/DFT config components —
  fem-model-config / dft-model-config in
  src/app/components/materials-science/ are the structural mirrors).

## Dustin's directive (2026-07-08)

> "We need the engines first, then those models yes. The point is to have
> those engines and the simulation capabilities so we can operate at all
> layers."

Context: the msci-24 accountability pages show L2 (mesoscale) and L3
(atomistic) honestly all-missing because no engine serves them. This plan
adds the engines (msci-25), then the material models + scale rows that use
them (msci-26). Test cases were chosen because each CLOSES an assumption a
live L1 model currently states:
- rod percolation MC **derives** the `percolationThreshold = 0.005` that
  the msci-23 CNT percolation models take as a literature assumption;
- dipolar chaining answers the microstructure question behind the
  tuned-magnetic-structures goal (do ferrite particles chain in a melt?);
- bead-spring MD is the coarse-grained melt-structure rung for printable
  wax (full TraPPE/GAFF alkane MD = named gap, needs OpenMM/LAMMPS on the
  worker as a WITH_MD build, same ladder as WITH_QE).

## STATE (superseded — kept for history): engines were parked WIP here;
   msci-25 remainder steps 1-8 and msci-26 steps 1-5 below were ALL
   executed + live-verified 2026-07-10 (see PICK UP HERE above).

Branch `dev-msci-25-md-meso-engines` in polari-framework, commit e3db4c5
(base: dev-msci-24-materials-pages daff804 — msci-24 all live + committed).

- `materialsScience/engines/md_engine.py` (NEW, committed): `capability()`
  (top-level `available` + honest `forceFieldMD` gap note);
  `lj_melt(density, temperature, n_particles=256, steps=3000,
  equilibration=1000, dt=0.005, thermostat='langevin'|'none', seed=1234)`
  — LJ reduced units, shifted-potential cutoff 2.5, velocity-Verlet,
  Langevin O-step, virial pressure, `nveDriftPerParticle` when
  thermostat='none'; `bead_spring_melt(chain_length=10, n_chains=20,
  density=0.85 [guarded >=0.4], temperature=1.0, steps=3000,
  equilibration=1000, dt=0.004, seed)` — Kremer-Grest FENE(k=30, R0=1.5)
  + WCA, boustrophedon snake-lattice init (verified continuous), broken
  bond -> honest refusal, unwrapped Rg/end-to-end/bond outputs.
- `materialsScience/engines/meso_engine.py` (NEW, committed):
  `capability()` (names the DPD/hydrodynamics gap);
  `rod_percolation_threshold(aspect_ratio [2..200], n_rods=300, trials=8,
  iterations=9, seed)` — vectorized Ericson segment-segment distance,
  union-find spanning in x, bisection to 50% spanning, returns
  `percolationThreshold` + `slenderRodLimit` (0.7/aspect, prov Balberg
  1984) + `ratioToLimit`; `dipolar_chaining(coupling_lambda [0..20],
  volume_fraction [0.005..0.3], n_particles=150, steps=2500, dt=0.002,
  seed)` — overdamped BD, field-pinned point dipoles (force math sign-
  checked: head-tail attracts, side-by-side repels), WCA core, force cap,
  cluster stats (meanClusterSize, chainedFraction >=3, fieldAlignment) +
  `chainsFormed` verdict.
- `materialsScience/scale_execution.py`: md/meso IMPORTS added (registry
  entries NOT yet — that's step 25.2).

### Smoke results (this session, real runs — use as selftest bands)
- lj_melt ρ*=0.8 T*=1.0 N=125: measured T 1.040, U/N −4.632, ~2s.
- Dilute gas ρ*=0.05 T*=2.0: P 0.0886 vs ideal 0.0934 (−5%, correct sign
  of second virial).
- NVE drift 3.4e-4 /particle over 400 NVE steps (dt 0.005).
- bead_spring 20×10 beads: bond 0.966 (KG lit ~0.97σ), Rg 1.71, ~5s.
- rod_percolation aspect 20, 150 rods: vf_c 0.0428 = 1.22× slender limit
  0.035 (finite-aspect correction expected >1), <1s.
- dipolar λ=6 vf=0.12 6000 steps: chained 0.63, alignment 0.71,
  chainsFormed True (~20s at N=100). λ=0.5: not formed. **At vf=0.05 the
  8000-step run only reaches chained 0.19 — aggregation-kinetics-limited,
  NOT broken physics (alignment 0.99 on what forms). See 25.1.**
- FIXED during smoke: NaN leak in `_dipole_forces` (inf diagonal ×
  inv_r7) — `r2_safe` masking, committed.

## msci-25 remainder — register + validate + surface (branch continues)

1. **dipolar defaults/honesty**: default `steps` 2500→6000; validity note
   gains "kinetics-limited at low vf: below ~0.1 use longer runs or read
   fieldAlignment (structure) separately from chainedFraction (kinetics)".
2. **ENGINE_REGISTRY** (scale_execution.py, imports already in): 4 new
   entries, registry 7→11, camelCase inputs → kwargs:
   - `'md.lj-melt'`: density, temperature, nParticles, steps,
     equilibration, dt, thermostat, seed
   - `'md.bead-spring-melt'`: chainLength, nChains, density, temperature,
     steps, equilibration, dt, seed
   - `'meso.rod-percolation'`: aspectRatio, nRods, trials, iterations, seed
   - `'meso.dipolar-chaining'`: couplingLambda, volumeFraction,
     nParticles, steps, dt, seed
3. **engine_model_seed.py**: `_REGISTRY_INPUT_KEYS` += the 4 sets;
   4 new templates (11 total): `md-lj-melt`, `md-bead-spring-melt`
   (sections: system / thermodynamicState / integration),
   `meso-rod-percolation` (system / sampling), `meso-dipolar-chaining`
   (system / integration). Each: parameter_schema_json with min/max
   mirroring the engine guards, section_map_json, outputs_json from the
   result keys above, cost_class 'moderate',
   capability_requirements_json `["md"]` / `["meso"]`, notes carrying the
   validity/gap lines. **selftest_engine_models: template-count checks
   7→11.**
4. **model_execution.check_capability_requirements** (~line 47): caps
   dict += `'md': md_engine.capability(), 'meso': meso_engine.capability()`.
5. **scale_execution_api.on_get_capability**: response += md + meso.
6. **SCALE_LEVEL_DETAILS** (materials_basis.py): L2 engines
   `['meso.rod-percolation', 'meso.dipolar-chaining']`, L3 engines
   `['md.lj-melt', 'md.bead-spring-melt']`; REWRITE both earnedBy strings
   (currently say "no … engine is wired yet" — now false). L3 earnedBy
   should still name the force-field-MD gap.
   **selftest_scale_presence check 5** ("no mesoscale/atomistic engine
   wired -> L2/L3 all-missing") — keep the all-missing count assertion
   (still true, no rows yet) but reword the label + add a check that L2/L3
   engines lists are now non-empty. The material-level-page frontend
   already switches off its "No engine is wired" banner automatically when
   engines[] is non-empty — no frontend change.
7. **selftest_md_meso_engines.py** (NEW): physics-invariant validations
   (bands from the smoke results, generous): Langevin T within 5% of
   target; NVE drift < 5e-3/particle; dilute P within 10% of ρT; dense
   U/N in (−7, −3); KG bond in [0.92, 1.02]; chains never broken; rod
   vf_c/slenderLimit in [0.8, 2.5] at aspect 20 AND vf_c(aspect 40) <
   vf_c(aspect 10) (monotonicity); dipolar formed at λ=6/vf=0.12, not at
   λ=0.5; every refusal shape (bad density/aspect/λ ranges) honest with
   the range named. Use small N + few steps to keep it <2 min.
8. **Deploy + live verify**: staging backend rebuild;
   `GET /api/msci/engines/capability` now shows fem/dft/md/meso; execute
   one md + one meso through ENGINE_REGISTRY in-container (models come in
   msci-26). Commit msci-25; update materials-science-module memory.

## msci-26 — models + L2/L3 scale rows (branch `dev-msci-26-l2-l3-models`)

1. **Definition classes** (one class per file, treeObject + defClassList
   + polyTyping, mirror fem_model_definition.py): `MDModelDefinition`
   (system_json, thermodynamicState_json, integration_json,
   physics_ref→md-* template, last_result_json, last_executed_at) and
   `MesoModelDefinition` (system_json, sampling_json, integration_json,
   structure_ref→meso-* template). Extend `model_execution.find_model`'s
   class list (currently FEM+DFT) and any engine_model_api class lists.
   component_binding validate/resolve are section-map-generic — verify,
   don't fork.
2. **Seed models** (standard_materials_seed.py or a new
   l2_l3_models_seed.py if size demands — file-size principle):
   - `cnt-percolation-threshold` (meso-rod-percolation): aspectRatio 100
     with the honesty note (real CNT aspect ~1000 exceeds the engine's
     finite-size-validated range; vf_c scales as 1/aspect so the derived
     value is an UPPER bound), nRods 400.
   - `ferrite-chaining-in-wax` (meso-dipolar-chaining): couplingLambda
     from a documented calculation (magnetite moment + particle size →
     λ; show the arithmetic in notes with provenance), volumeFraction
     0.12 (the smoke-validated regime), steps 6000.
   - `paraffin-bead-spring-melt` (md-bead-spring-melt): chainLength 10
     (≈3 CH2/bead mapping note), density 0.85, T* 1.0.
   - `lj-reference-fluid` (md-lj-melt): the validation-rung model
     (ρ*=0.8, T*=1.0) — keeps the integrator honest forever.
3. **Scale rows** (SEED_STANDARD_SCALE_DEFINITIONS): carbon-nanotube@L2
   (→cnt-percolation-threshold; n-doped/b-doped derive from it),
   wax-ferrite@L2 (→ferrite-chaining-in-wax, derived_from wax-ferrite@L0),
   paraffin-wax@L3 (→paraffin-bead-spring-melt, derived_from
   paraffin-wax@L0). Statuses 'partial' (executable, result pending).
   Identity count in selftest_standard_materials unchanged (no new
   identities); scale-row checks += the new rows; presence pages will show
   L2/L3 leaving all-missing — update selftest_scale_presence counts.
4. **The closing move** (knobs-and-suggestions — never rewire silently):
   seed `cnt-wax-percolation-derived-vfc`, a VARIANT of the msci-23
   percolation model whose `percolationThreshold` is an objectRef binding
   into carbon-nanotube@L2's derived result; the original assumed-0.005
   model stays. The comparison IS the evidence.
5. **Live verify**: execute all 4 models via
   POST /api/msci/models/{name}/execute; L2/L3 rows flip partial→defined
   with results ON the rows; /display/materials matrix + level pages show
   the change; derived vf_c vs assumed 0.005 comparison visible. Commit +
   memory. (Specialized config UI is msci-27 — the models are ALREADY
   reachable meanwhile via the engine-templates API + basis browser +
   level pages.)

## msci-27 — MD/meso-SPECIFIC simulation interfaces (branch
`dev-msci-27-md-meso-ui`, angular + page seeds)

Dustin (2026-07-08): the plan must also cover "building out the custom
interfaces for configuring those kinds of levels as simulations". Same
principle as the msci-17 FEM/DFT interfaces: mirror how practitioners
structure these setups, specialized at the simulation level — NOT a
generic form. The domain idioms to mirror (LAMMPS input decks / GROMACS
.mdp / HOOMD scripts all share this shape):

  MD:   System → Interactions → Ensemble/Thermostat → Integration →
        Sampling/Outputs
  meso: System/Structure → Interactions/Coupling → Sampling (MC) or
        Integration (BD) → Verdicts

1. **`md-model-config.component`** (components/materials-science/,
   mirror fem-model-config structure + model-config.shared.scss):
   - **System**: model picker (md-* templates); composition — LJ fluid
     (nParticles, density* slider with gas/liquid annotations) vs
     bead-spring (chainLength, nChains, density* with the >=0.4 guard
     surfaced as a disabled-region note); reduced-units explainer chip
     ("epsilon=sigma=m=kB=1 — map to a real material by choosing
     epsilon/sigma with provenance") with the mapping fields optional
     (epsilon eV, sigma nm, per-material objectRef bindable).
   - **Interactions**: potential shown per template (LJ shifted rc=2.5 /
     FENE k=30 R0=1.5 + WCA — constants visible, read-only v1);
     force-field MD (TraPPE/GAFF) listed DISABLED with the WITH_MD gap
     note (the msci-17 "unsupported stays visible and says why" idiom).
   - **Ensemble**: thermostat picker (Langevin NVT / none→NVE) +
     temperature*; NVE shows the drift-check explainer (it IS the
     integrator honesty knob).
   - **Integration**: dt, steps, equilibration, seed — with the O(N^2)
     cost estimate line (N^2 x steps, from the template cost_class +
     live inputs) BEFORE run (resource-aware principle).
   - **Outputs/Results**: declared outputs from the template; last
     result rendered as measured-vs-target T badge, P vs ideal-gas P,
     U/N, and for chains bond/Rg/end-to-end with the KG ~0.97 reference
     line drawn (provenance shown).
2. **`meso-model-config.component`**:
   - **System/Structure**: model picker (meso-* templates); rod mode —
     aspectRatio (with the [2,200] range + real-CNT-aspect honesty
     note), nRods; dipolar mode — couplingLambda (with the lambda~2
     chaining-onset reference line + a helper popover computing lambda
     from moment/size/T when those are bound), volumeFraction, nParticles.
   - **Sampling** (rods): trials, iterations, seed — bisection explainer.
   - **Integration** (dipolar): steps, dt, seed + the kinetics-limited
     warning auto-shown when volumeFraction < 0.1 (evidence-bearing:
     names the smoke result).
   - **Results/Verdicts**: rods — vf_c vs the Balberg slender-rod limit
     as a two-bar comparison + ratioToLimit + THE KNOB: an explicit
     "use as percolationThreshold in <L1 model picker>" suggestion
     button that creates/updates the objectRef binding on a CHOSEN
     percolation model (never auto-applied; msci-26's derived-vfc
     variant is the seeded example). Dipolar — chainedFraction /
     fieldAlignment gauges + the chainsFormed verdict chip with both
     thresholds visible.
3. **Shared machinery**: reuse model-binding-editor (objectRef/
   stageDerived pickers), model-run-bar (validate/execute), the
   capability-banner pattern (md/meso roots from
   /api/msci/engines/capability — forceFieldMD + dpd gaps rendered as
   the disabled-with-reason rows). engine-model.service already speaks
   templates+models generically — extend its model-class routing to the
   two new definition classes.
4. **Pages + nav**: DisplayDefinition seeds `md-models` + `meso-models`
   (msci_pages_seed loop/idiom, componentNames md-model-config/
   meso-model-config, defaults lj-reference-fluid /
   cnt-percolation-threshold); register in msci-display-components.ts
   (+ selftest_msci_pages REGISTERED_COMPONENTS + count 10→12); add to
   the materials-home tools row and the home Materials Science card;
   LEVEL-PAGE tie-in: materials-level-2/-3 "missing" suggestions and the
   engines list link to the matching config page ("configure a model
   for this level") — the accountability page becomes the on-ramp.
5. **No-code**: EngineModelOperation resolves models by name through
   find_model — once msci-26 extends find_model to the new classes, MD/
   meso models are already weavable into no-code solutions; add one
   selftest case (bead-spring model through SolutionExecutionEngine) to
   prove it, no new node needed.
6. **Selftests + verify**: ng build clean; selftest_msci_pages updated;
   live — configure + validate + run lj-reference-fluid and
   cnt-percolation-threshold from the browser, see the vf_c comparison
   bars, exercise the use-as-threshold suggestion button end-to-end
   (binding created on the variant model, original untouched), level
   pages link through. Commit + memory.

## Deferred / named gaps (carry into memory)
- WITH_MD worker build (OpenMM pip wheel on Debian msci-engines) for
  TraPPE/GAFF alkane MD → real wax melt density/viscosity at L3.
- DPD (momentum-conserving) for nanoparticle dispersion kinetics — the
  BLCNC layer-uniformity question; after LASiS size measurements land.
- Periodic-boundary rod percolation + waviness/attraction corrections.
- Free dipole orientations (torque integration) for zero-field
  self-assembly.

## Conventions checklist (unchanged)
Selftests from polari-framework/ via `python3 -m materialsScience.<mod>`;
staging deploy `cd polari-rf-node && export LOCAL_IP=192.168.0.210 &&
docker compose -f docker-compose.staging-nip.yml build backend && up -d
backend` (~150s restore; API curl -sk -H "Host:
api.prf.192.168.0.210.nip.io" https://localhost/...); branch per confirmed
phase; edited seeds do NOT reach existing volumes (new rows fine);
knobs-and-suggestions; literature values labeled with provenance; honest
refusals name the knob.
