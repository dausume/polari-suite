# Solid-State Physics & Lattice Visualization — Plan (ssp-1..8)

**STATUS 2026-07-23 (evening): ssp-1, ssp-2, ssp-3, ssp-4 + the ssp-6
chart/view core BUILT + LIVE-VERIFIED on the suite staging stack.
Dustin's directive: lives under materialsScience/ (NOT its own
module). ⚠️ REVIEW GATE — stacked branches, NOT on dev, NOT pushed.**

## Build state (what exists now)

- Branch stack (polari-framework):
  `dev-ssp-1-crystal-structure` → `dev-ssp-2-lattice-view` →
  `dev-ssp-4-lattice-dynamics` → `dev-ssp-3-symmetry-xrd` (head).
  polari-platform-angular: `dev-ssp-2-lattice-view`.
  polari-rf-node: `dev-ssp-3-symmetry-xrd` (worker + Dockerfile).
- ✅ ssp-1: CrystalStructureDefinition + crystal_ops (ASE build,
  facts, bonds, primitive reduction via centering cuts) + 8 seeded
  literature structures + /api/msci/structures. 46-check selftest.
- ✅ ssp-2: crystal_snapshot scene compiler → freestandingOnly
  SimSpaceDefinition per structure (spheres + oriented-cylinder
  bonds/cell edges, jmol element materials, ghost replicas,
  supercell knob), POST .../{name}/scene regenerate,
  /display/crystal-structures page. LIVE: snapshot compiles 95
  spheres + 140 cylinders for Si 2×2×2. 17-check selftest.
- ✅ ssp-4: engines/lattice_dynamics_engine — phonon dispersion
  (analytic pair-potential force constants → D(k) along ASE band
  paths + DOS, acoustic-sum + stability honesty) and clamped-ion
  cubic C11/C12/C44 + dual-route bulk modulus. ssp.* registry keys
  (structureName resolved to rows), 13 engine templates, L3
  SCALE_LEVEL_DETAILS, POST .../phonons + /elastic. LIVE on Al fcc.
  29-check selftest (√(k/m) scaling exact, Cauchy C12=C44).
- ✅ ssp-3: worker /structure/analyze + /structure/xrd (pymatgen) —
  live-verified: all 5 nontrivial seeds' detected space groups MATCH
  declared; Si XRD (111) 28.465° vs lit 28.44°. Backend
  crystal_analysis + declared-vs-detected suggestion + on-row cache
  (new last_analysis_json field), /analyze + /xrd routes. 11-check
  selftest.
- ✅ ssp-6 core: sci-xy-chart (reusable Observable-Plot XY component,
  k-path categorical ticks) + crystal-structure-view (picker, facts,
  embedded SimSpace scene + regenerate knob, phonon/elastic panels
  with honesty chips). ng build green. ⚠️ NO browser pass yet.

## Deploy facts / gotchas (this box)

- Suite staging stack runs the CUSTOM DOMAIN `polari-staging.test`
  (Host: api.prf.polari-staging.test), NOT nip.io. Backend boot on
  this volume takes ~25 min, and API routes 404 until endpoint
  construction finishes (the / route answers long before).
- **Frontend .dockerignore trap (FIXED)**: boilerplate `**/charts`
  silently dropped `src/app/components/charts/` from the image
  context — production image build failed while local ng build
  passed. Scoped to `/charts`; ALWAYS check the image build's own
  error lines, not just `up -d` (the old container keeps running on
  a failed build).
- The deployed API's analyze/xrd currently return the HONEST
  stale-worker refusal (topology resolves the old isle-core worker);
  the full pymatgen path is verified in-container with
  MSCI_ENGINES_URL=http://prf-msci-engines:9500 (magnetite Fd-3m
  #227 agrees, 17 XRD peaks).
- **Host port 9500 is an isle-core tunnel** (the topology's
  engines-on-isle-core placement; sshd-owned listener answering with
  the OLD worker code). The refreshed local worker therefore runs
  WITHOUT a host publish: container prf-msci-engines on polari-link
  + polari-suite_polari-network (backend reaches it by name; DNS
  verified in-container). ⚠️ isle-core's worker predates
  /structure/* — update it there (its own Claude instance) or point
  MSCI_ENGINES_URL at the local worker (topology decision — left to
  Dustin, env knob deliberately NOT hardcoded into the compose).

## Remaining (next agent picks up here)

1. Browser pass on /display/crystal-structures (scene look, phonon
   chart, XR button) — then Dustin's visual review.
2. xrd-pattern-view on sci-xy-chart (data is live; sticks =
   scatter+rules) + material-detail Structure panel link-through
   (ssp-6 §2/§3 below).
3. ssp-5 periodic DFT (WITH_QE build arg exists on the worker
   Dockerfile; pseudopotentials + /dft/periodic endpoint + bands).
4. ssp-7 integrations (PSPP crystal-structure-ref, no-code selftest
   case, demo multi-scale pipeline); ssp-8 instanced renderer
   (deferred until a real supercell case).

---

Goal: give the Materials Science module real solid-state physics — crystal
lattices as first-class objects, 3D lattice visualization, symmetry/XRD
analysis, phonon/band-structure/elastic properties — at the correct rungs of
the existing L0–L4 scale ladder, using the seams that already exist
(MaterialScaleDefinition, engine registry, SimSpace renderer, msci-engines
worker). Standing principles apply: knobs + evidence-bearing suggestions
(never auto-apply), object coherence, small files split by concern, honest
capability gates, branch per confirmed phase.

---

## 1. Capability survey (what exists today — verified 2026-07-23)

### Backend (`polari-rf-node/polari-framework`)

The 5-level material resolution ladder is defined in
`materialsScience/materials_basis.py` (`SCALE_LEVELS` lines 35-41,
`SCALE_LEVEL_DETAILS` lines 53-88):

| Level | Name | Range | Live engines today |
|---|---|---|---|
| L0 | experimental | mm–m | measured / rules-of-mixtures / blend math |
| L1 | continuum | µm–mm | `fem.effective-conductivity` (scikit-fem), transport, darcy |
| L2 | mesoscale | nm–µm | `meso.rod-percolation`, `meso.dipolar-chaining` |
| L3 | atomistic | Å–nm | `md.lj-melt`, `md.bead-spring-melt` (pure-numpy reduced units) |
| L4 | quantum | Å | `dft.*` via ASE; pyscf molecular DFT on msci-engines worker; QE capability-gated (not installed) |

Solid-state-relevant inventory:
- **Crystallography = one thin pass-through**: `dft_engine.py:91`
  `build_bulk_structure(symbol, crystal, lattice_a)` wraps `ase.build.bulk`
  ('fcc'/'bcc'/…); `DFTModelDefinition.structure_json` accepts
  `{"kind":"bulk","symbol":"Al","crystal":"fcc","latticeA":4.05}`. That is
  the ENTIRE crystal-structure surface. No lattice class, no basis atoms, no
  space groups, no Miller/Bravais/Brillouin/reciprocal-space code anywhere.
- **No band structure**: `modules/electrodevice/semiconductor.py` derives a
  semiconductor *character* from molecular-fragment HOMO/LUMO gaps and says
  so honestly (line 172: fragment gaps overestimate bulk — "CHARACTER, not
  band"). No k-space, no DOS, no phonons, no elastic tensors, no
  dislocations/grain boundaries. "unit cell" elsewhere = the FEM 2D
  homogenization cell, not a crystallographic cell.
- **PSPP** models chemistry at the Qn-motif/species-graph level (quasi-
  atomistic connectivity, no coordinates). Its
  `material_structure.ScaleStructureDefinition` already reserves
  representation types `'network-graph-ref'` / `'particle-config-ref'` —
  unused hooks a real atomic representation can fill.
- **Seams a new layer plugs into** (all proven by the L2/L3 build):
  `SCALE_LEVEL_DETAILS[..]['engines']` lists → `scale_execution.py` dispatch
  → `*ModelDefinition` treeObjects → `/api/msci/models/{name}/validate|execute`
  → `engineModel` stages in multi-scale sims → objectRef bindings for the
  "closing move" comparisons.
- **Library situation** (`FEM_DFT_LIBRARY_OPTIONS.md`, empirically tested):
  base image is Alpine/musl → pure-Python only (numpy/scipy/ase/scikit-fem
  live there). Compiled science libs (pyscf, **pymatgen**, sfepy) live on the
  Debian **msci-engines worker** (`polari-rf-node/msci-engines/
  engines_service.py`). **Quantum ESPRESSO** is the committed
  periodic-solids engine (via the ASE Espresso calculator) but is NOT
  installed anywhere — a named knob. phonopy/spglib/LAMMPS/OpenMM: absent.

### Frontend (`polari-rf-node/polari-platform-angular`)

- **3D**: three.js 0.169 behind `SimSpaceRenderer` (d3 for 2D spaces). The
  renderer is a pure reconciler over backend-supplied flat lists:
  `SimSpaceObject` (sphere/cylinder/… primitives, stable trackKeys),
  `SimSpaceConnection` (lines), `SnapshotVector` (arrows), plus
  server-computed triangle meshes (`mathshape:` surfaces) and glTF.
  **A lattice view needs ZERO new rendering primitives** — atoms are sphere
  objects, bonds are connections, unit-cell edges are styled connections,
  phonon displacement arrows are vectors, and the temporal scrubber
  animates mode motion. WebXR rides on the same scenes for free
  (`XrSceneRegistry` binds any mounted 3D viewer).
- **Material detail view** (`material-detail.component`, `/materials/{name}`):
  purely tabular today — properties, thermal window, blends, per-level tabs.
  No structure panel, no charts beyond one hand-rolled SVG trajectory graph.
- **2D scientific plotting is the real frontend gap**: no reusable XY
  line/scatter component. `@observablehq/plot` is in package.json but used
  only inside `pspp-dataset-chart.component`. katex/mathlive available for
  Γ/X/L k-path labels. No heatmap/contour renderer (charge density), no
  `InstancedMesh`/`THREE.Points` path (large supercells), no voxel/volume
  renderer.
- **Display plumbing**: `DISPLAY_COMPONENT_REGISTRY` + per-module
  `*-display-components.ts` registrars; 3D embeds go through a seeded
  `SimSpaceDefinition` + binding (`msim-scene-panel` pattern).

---

## 2. Where solid-state physics sits in the material-definition levels

**Decision to review:** a crystal structure is not itself a "level" — it is
the *structural representation* that L3 and L4 physics share. So:

- **`CrystalStructureDefinition` = a representation object** (like
  `FEMModelDefinition` is for L1), referenced by scale rows at **L3 and L4**
  via the existing `definition_class`/`definition_ref` mechanism, and by
  PSPP's `ScaleStructureDefinition.representation_class` (the reserved
  `'particle-config-ref'` slot generalizes to `'crystal-structure-ref'`).
- **Properties earned FROM it land at the level of the physics that
  computed them**, then flow UP the ladder through the existing
  derivation-lineage machinery:
  - L4 (quantum): total energy, relaxed lattice constant, EOS → bulk
    modulus, electronic band structure + DOS + band gap, (later) DFPT
    phonons. Derivation method `dft-parameterized`.
  - L3 (atomistic): empirical-potential phonon dispersion + DOS, harmonic
    elastic constants, defect formation energies (later). Reduced-unit /
    classical-potential honesty notes, same as the MD engines.
  - L2 (mesoscale): grain/polycrystal texture is the eventual home of
    grain-boundary work — OUT OF SCOPE here except as a named gap
    (PSPP already labels `grain-domain` at L2).
  - L0: derived scalars (bulk modulus, band gap, lattice parameter) become
    ordinary material properties with lineage rows pointing down at the
    L3/L4 computation that earned them — exactly the msci-26
    derived-vs-assumed pattern.

**The closing move (knobs-and-suggestions idiom):** seed a VARIANT of the
electrodevice semiconductor-character model whose gap is an objectRef
binding into a periodic band-structure result, next to the existing
fragment-gap model. Fragment gap vs real band gap side by side — the
comparison IS the evidence, same shape as the msci-26 derived-vfc CNT story.

---

## 3. Phases

### ssp-1 — CrystalStructureDefinition (backend, base image, pure ASE)

Branch `dev-ssp-1-crystal-structure` in polari-framework.

1. `materialsScience/crystal_structure_definition.py` (NEW, one class per
   file): `CrystalStructureDefinition` treeObject — name, material_ref,
   `bravais` (14 lattices) or `space_group` (number + setting),
   lattice params `a,b,c,alpha,beta,gamma`, `basis_json` (element +
   fractional coords + optional Wyckoff label), `supercell_json`
   (nx,ny,nz knob, default 1×1×1), provenance/notes, last_analysis_json.
   Structures build through ASE (`ase.spacegroup.crystal` /
   `ase.build.bulk`) — **verify at build time that ASE's spacegroup path is
   pure-Python on Alpine; if it needs spglib, fall back to explicit-basis
   construction in-image and space-group-aware building on the worker.**
2. `crystal_structure_ops.py`: build → ASE Atoms; derived read-only facts
   (cell volume, density from basis masses, nearest-neighbor distance,
   coordination count, bond list by cutoff knob); honest refusals for
   inconsistent inputs (e.g. basis atom outside cell → named knob).
3. Seeds (`crystal_structures_seed.py`): structures for materials already
   in the basis — Al (fcc), Fe (bcc), magnetite/ferrite (spinel, explicit
   basis), graphite + a rolled-CNT segment (from the existing CNT identity),
   NaCl as the two-element teaching case, Si (diamond) as the band-structure
   workhorse. Literature lattice constants labeled with provenance.
4. `DFTModelDefinition.structure_json` gains
   `{"kind":"crystal-ref","name":...}` resolving through the new class
   (old inline `"bulk"` kind stays working — no silent rewire).
5. API: fold into `/api/msci` — `GET /api/msci/structures`,
   `GET /api/msci/structures/{name}` (+ built facts + bond list).
   Selftest `selftest_crystal_structures.py` (counts, volume/density vs
   literature bands, refusal shapes).

### ssp-2 — Lattice 3D visualization (backend compiler + frontend panel)

Branch `dev-ssp-2-lattice-view` (framework) + `dev-ssp-2-lattice-view`
(angular).

1. Backend `crystal_snapshot.py`: compile a CrystalStructureDefinition →
   SimSpace records — atoms as `sphere` SimSpaceObjects (per-element
   CPK/jmol color + covalent-radius scale via a small pure-data table;
   styleRefs seeded as Material3DDefinitions), bonds as SimSpaceConnections
   (cutoff knob), unit-cell edges as 12 styled connections, optional
   ghost-replica atoms at cell boundaries (knob, default on — a lattice
   view without boundary atoms reads wrong). Seed a `SimSpaceDefinition`
   per seeded structure through the existing snapshot/binding path.
2. Angular `crystal-structure-view.component` (components/
   materials-science/): embeds `SimSpaceViewerComponent` via the
   msim-scene-panel idiom; controls = supercell stepper, bond-cutoff
   slider, cell-edges/replica toggles; facts sidebar (volume, density, NN
   distance) from ssp-1's API. Register as display component
   `crystal-structure-view` in `msci-display-components.ts`; seed page
   `/display/crystal-structures`.
3. Material detail view gains a **Structure panel** when a structure row
   exists for the material; the L3/L4 level tabs link to it ("view
   lattice"). XR comes free — verify Enter-XR binds the lattice scene.
4. Scale check: seeded cells are ≤ hundreds of atoms — fine for the
   one-Object3D-per-atom renderer. **InstancedMesh path = ssp-8, only when
   a real supercell need arrives** (resource-aware: the view should show an
   atom-count cost line before building large supercells).

### ssp-3 — Symmetry + XRD analysis (msci-engines worker, pymatgen)

Branch `dev-ssp-3-symmetry-xrd`.

1. `msci-engines/structure_service.py` (worker, Debian, pymatgen already
   wheel-clean there): `POST /structure/analyze` — space-group detection
   (symbol + number), symmetrized cell, Wyckoff positions;
   `POST /structure/xrd` — simulated powder XRD pattern
   (pymatgen XRDCalculator: 2θ + intensities + hkl labels). Capability
   entries in `GET /capability`.
2. Framework side: `crystal_analysis.py` delegates via the existing
   `engines/remote.py` seam (`MSCI_ENGINES_URL`); honest refusal when the
   worker is absent (names the compose knob). Results cached on
   `last_analysis_json` with timestamp.
3. Suggestion, never auto-apply: when detected space group disagrees with
   the seeded `space_group`, surface an evidence-bearing suggestion on the
   structure row (the detected value + tolerance), with an explicit
   accept knob.
4. XRD becomes the first *measurable prediction*: the pattern is exactly
   what a bench XRD would compare against — plot lands in ssp-6.

### ssp-4 — L3 phonons + elastic constants (pure-numpy engine, base image)

Branch `dev-ssp-4-lattice-dynamics`. Same tradition as md_engine: small,
honest, reduced-unit-capable, no compiled deps.

1. `engines/lattice_dynamics_engine.py`: finite-difference force constants
   on a CrystalStructureDefinition with a pairwise potential
   (LJ with per-material ε/σ mapping knobs, or harmonic springs with
   user-set stiffness) → dynamical matrix → **phonon dispersion along a
   high-symmetry k-path** (path table per Bravais lattice — the one piece
   of reciprocal-space code this plan introduces; keep it a small pure-data
   module `k_paths.py`) + phonon DOS (histogram) + Γ-point acoustic-sum
   check as the built-in honesty invariant. Also harmonic **elastic
   constants** (energy-vs-strain finite differences → C11/C12/C44 for
   cubic; bulk modulus from them).
2. Registry: `'ssp.phonon-dispersion'`, `'ssp.elastic-constants'` under L3
   in `SCALE_LEVEL_DETAILS`; engine templates + `LatticeModelDefinition`
   (or reuse MDModelDefinition sections if the fit is clean — decide at
   build time, file-size principle) + validate/execute through the
   standard model_execution path.
3. Physics-invariant selftests (bands generous): 3 acoustic branches → 0
   at Γ; ω real everywhere for the stable seeded structures (imaginary
   modes reported as an instability verdict, not an error); LJ-FCC bulk
   modulus consistent between EOS-curvature and elastic-constant routes;
   dispersion max frequency scales √(k/m) on the spring model.
4. Honesty notes carried on templates: classical pair potentials get
   trends/teaching-grade numbers, NOT quantitative phonon spectra for real
   metals — the quantitative rung is DFPT (ssp-5 gap note).

### ssp-5 — L4 periodic DFT: Quantum ESPRESSO knob (msci-engines worker)

Branch `dev-ssp-5-periodic-dft`. The plan FEM_DFT_LIBRARY_OPTIONS.md
already commits to: QE via the ASE Espresso calculator on the worker.

1. Worker image gains a `WITH_QE` build arg (apt `quantum-espresso` +
   a small curated SSSP-efficiency pseudopotential set for the seeded
   elements only — keep the image bloat explicit and listed); capability
   report shows qe true/false with the knob named.
2. `POST /dft/periodic` on the worker: modes `total-energy`, `relax-cell`
   (→ lattice constant + EOS points → bulk modulus via Birch-Murnaghan
   fit), `bands` (SCF → k-path NSCF → eigenvalues along the ssp-4
   `k_paths` table + band gap direct/indirect verdict), `dos`.
   k-grid/cutoff knobs surfaced with cost-class estimates BEFORE run
   (resource-aware principle); convergence honesty: report SCF iterations
   + a not-converged refusal rather than a silently bad number.
3. Framework: extend `dft_engine.py` dispatch (`dft.periodic-*` engine ids
   under L4), seed models for Si (band gap — the classic DFT-underestimates
   note carried with provenance), Al (lattice constant + bulk modulus vs
   literature), Fe if pseudopotential budget allows (spin knob = named gap
   if deferred).
4. **Closing moves** (the evidence): (a) DFT-relaxed lattice constant as a
   suggestion against the seeded literature `a` on the structure row;
   (b) L0 bulk-modulus property rows derived `dft-parameterized` with
   lineage; (c) the electrodevice variant — periodic band gap objectRef
   next to the fragment-gap character model (see §2).
5. DFPT phonons = named gap on the capability report (quantitative phonon
   rung above ssp-4), deliberately deferred.

### ssp-6 — 2D scientific plot component + band/phonon/XRD pages (frontend)

Branch `dev-ssp-6-sci-plots`. This closes the fragmented-plotting gap.

1. Extract/generalize `pspp-dataset-chart` into a reusable
   `sci-xy-chart.component` (components/shared/ or charts/): line/scatter/
   band series, linear/log Y, categorical x-tick mode with **katex labels**
   (Γ, X, L, W…), vertical guide lines at k-path vertices, hover readout.
   pspp-proofing migrates to it (no behavior change — prove by side-by-side
   screenshot).
2. `band-structure-view.component` (bands + DOS side panel, gap chip with
   direct/indirect verdict), `phonon-dispersion-view.component` (branches +
   DOS + the Γ acoustic-sum honesty chip, imaginary modes drawn below zero
   in the warning color), `xrd-pattern-view.component` (stick pattern +
   hkl hover). All registered display components; material detail L3/L4
   tabs and the structure panel link through to them.
3. Config UIs follow the msci-27 idiom (mirror practitioner setup shape,
   disabled-with-reason rows from the capability report):
   `lattice-model-config` (structure → potential → k-path → sampling) and
   the periodic modes folded into the existing `dft-model-config` as a new
   System branch (crystal-ref picker + k-grid/cutoff + cost line).
4. Phonon mode animation (stretch, cheap): a chosen mode's eigenvector →
   SnapshotVector arrows + scrubber-driven displacement animation on the
   ssp-2 lattice scene — in XR this is the showpiece.

### ssp-7 — PSPP + no-code + sim integration

1. PSPP: `ScaleStructureDefinition` representation types gain
   `'crystal-structure-ref'`; geopolymer L3 rows can point at real cells
   when they exist (zeolitic framework cells are a later data task, named).
2. No-code: EngineModelOperation already reaches any find_model class —
   extend find_model to the new definition class(es); one selftest case
   (phonon model through SolutionExecutionEngine).
3. Multi-scale sims: `engineModel` stages can gate on ssp results (e.g. a
   stage that requires bulk modulus before a continuum FEM stage consumes
   it) — seed one demo pipeline: Si structure → relax → elastic → FEM
   stage using the derived modulus, the full ladder in one sim.

### ssp-8 — Large-supercell instanced renderer (DEFERRED until needed)

`THREE.InstancedMesh` path in the three renderer for >~1k same-shape
objects (per-instance color/matrix, picking via instanceId), behind a
threshold knob on the SimSpaceDefinition. Also the seam a future
voxel/volume view (wax-print, charge density) would reuse. Do NOT build
until a concrete supercell/defect case demands it.

---

## 4. Named gaps (carry into memory when built)

- DFPT/phonopy quantitative phonons; spin-polarized DFT; charge-density
  volume rendering (needs the ssp-8 seam + a volume renderer).
- Defects (vacancies/dislocations), grain boundaries / polycrystal L2 —
  the natural follow-on family after ssp-1..7.
- Materials Project API import (pymatgen can fetch structures — knob +
  provenance question, deliberately not in v1).
- LAMMPS/OpenMM force-field MD (pre-existing gap, unchanged).

## 5. Conventions checklist

Selftests `python3 -m materialsScience.<mod>` from polari-framework/;
worker selftests self-contained in msci-engines/; staging deploy per
MD_MESO_ENGINES_PLAN.md conventions (backend rebuild + `docker exec
pol-proxy nginx -s reload` after container recreate); seeds don't reach
existing volumes (new rows fine; NEW FIELDS on existing rows need the
explicit CRUDE PUT — seed-field-addition gotcha); branch per confirmed
phase; literature values labeled with provenance; every capability =
knob + suggestion, never auto-applied.
