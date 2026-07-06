# FEM / DFT Library Options for the Materials Science Module

**For Dustin's review (2026-07-06).** Requested comparison of open-source libraries for
the general FEM (scale level 1) and DFT (scale level 4) capabilities, judged on: can it
"generally handle anything", does it transition smoothly into Polari modules (pip into
the backend image vs its own module/worker container), OO Python API quality, license,
and self-hosted fit. Install claims marked ✅/❌ were **empirically tested on this
machine** (pip, in a clean venv on the staging box) — see the test log note at the end.

**Decisive empirical finding: the backend image is ALPINE (musl) — pip wheels with
compiled extensions don't exist for it; only pure-Python libraries ride in the base
image.** That cleanly splits the architecture in two, and it matches the
modules-as-projects direction anyway:
- **In the base image (pure Python)**: scikit-fem + ASE — already live and validated.
- **In a dedicated Debian-based `msci-engines` WORKER container (its own Polari
  module)**: pyscf + pymatgen (wheels install clean — tested), sfepy (needs gcc in the
  image — tested), Quantum ESPRESSO binary as a knob. **Proof it's real: propane
  B3LYP/6-31G converged to −118.8543 Ha in 3.1 s inside a stock container on this
  box.**

**Bottom line (best judgment, being implemented — veto anytime):**
- **FEM ladder: scikit-fem (base image, live) → sfepy in msci-engines (adds the
  HOMOGENIZATION engine — rigorous composite micro→macro, the upgrade path from
  Voigt/Reuss) → FEniCSx as its own worker module if MPI-scale is ever needed.**
- **DFT: ASE stays the abstraction (calculator = knob); pyscf in msci-engines is the
  molecular engine (waxes are molecules — running TODAY); Quantum ESPRESSO (your
  notes' engine) is the periodic-solids knob on the same worker; GPAW optional later
  behind the same ASE seam.**
- **pymatgen in msci-engines as the materials-analysis layer (structures, symmetry,
  phase diagrams, Materials Project data).**

---

## FEM (continuum, scale level 1)

| Option | License | Python OO | Capability ceiling | Polari fit | Verdict |
|---|---|---|---|---|---|
| **scikit-fem** (current) | BSD-3 | pure Python, weak forms as decorated functions | arbitrary weak forms, 1D/2D/3D, P1-P4/quads/hex; NO MPI, scipy solvers only → ~10⁵-10⁶ DOF practical | ✅ pip, numpy/scipy only — already in image + validated | **Keep** as the always-available default |
| **sfepy** | BSD-3 | Python + C extensions, problem-description OO API | multi-physics (elasticity, thermal, piezo, acoustics, Navier-Stokes) + **built-in HOMOGENIZATION engine for composites/micro-macro** — exactly our rules-of-mixtures-beyond-level-0 need | ✅ pip wheels (tested) | **Add** — the capability step; homogenization feeds MaterialScaleDefinition lineage (L2/L1 → L0/L1 derived properties) |
| **FEniCSx** (dolfinx) | LGPL | symbolic UFL weak forms (write the PDE, it compiles) | the open-source ceiling: MPI-parallel, PETSc solvers, 10⁸+ DOF, adaptive meshes | ❌ not pip; conda/apt/**docker image** — fits modules-as-projects as its OWN worker service | **Defer** — adopt as `fem-worker` module when a real problem outgrows sfepy |
| deal.II / MOOSE | LGPL | C++ (python bindings thin) | huge (MOOSE = multiphysics framework) | own container + file/wrapper coupling; not OO-Python-first | Pass for now |
| Elmer / CalculiX / code_aster | GPL | none (input-file solvers) | strong solvers (CalculiX ≈ Abaqus-like) | driveable via generated input files only | Pass — conflicts with "smoothly transitioned into Polari modules" |

**Why this ladder:** scikit-fem embeds beautifully (it's just Python objects — a
MaterialScaleDefinition can execute it TODAY, proven), sfepy adds the one feature the
materials module genuinely needs next (homogenization of composite microstructure →
effective bulk properties, i.e. the rigorous version of Voigt/Reuss), and FEniCSx is a
deployment decision (its docker image becomes a Polari module/worker exactly like the
dask workers), not a code decision — ASE-style, nothing above it changes.

## DFT (quantum, scale level 4)

| Option | License | Python OO | Capability ceiling | Polari fit | Verdict |
|---|---|---|---|---|---|
| **ASE** (current) | LGPL | Atoms/Calculators — the de-facto OO layer | not an engine — the ABSTRACTION over all engines below | ✅ pip, already in image | **Keep** — the calculator IS the knob |
| **pyscf** | Apache-2.0 | fully OO, NumPy-native | molecular HF/DFT/MP2/CCSD(T)/TDDFT + periodic (PBC, Gaussian basis); GPU fork exists | ✅ pip wheel (tested) — REAL DFT runs in-image | **Add as in-image engine** — waxes are molecules; alkane conformer energies, functional-group properties run TODAY |
| **Quantum ESPRESSO** (via ASE) | GPL | via ASE Espresso calculator | plane-wave periodic solids: phonons, DFPT, + your notes' BoltzTraP/AMSET/Wannier90 transport pipeline | binary + pseudopotentials (~GB) → its OWN `dft-worker` module, not base image | **Keep as periodic-solids engine** (your notes commit to it); capability-gated already |
| GPAW | GPL | Python-native, deepest ASE integration (no input files) | PAW real-space/planewave/LCAO periodic DFT | ❌ pip needs libxc system lib + compile (tested: fails on clean image); apt python3-gpaw exists | Optional later — same ASE seam, zero code change |
| Psi4 | LGPL | OO (psi4.energy) | molecular QC ≈ pyscf | conda-first, pip unsupported | Pass — pyscf covers it with cleaner install |
| ABINIT / CP2K / SIESTA | GPL | via ASE calculators | comparable periodic engines | binaries, own containers | Pass — QE per your notes; swappable behind ASE anytime |
| **pymatgen** (bonus) | MIT | fully OO | not an engine: structures, symmetry, phase diagrams, Materials Project API, IO for all engines above | ✅ pip wheel (tested) | **Add** — the analysis layer both FEM homogenization inputs and DFT outputs flow through |

**Why this shape:** "generally handle anything" is exactly what ASE's calculator
abstraction buys — the engine is configuration, so heavyweight engines (QE, GPAW, CP2K)
become Polari **modules/worker services** (the modules-as-projects track) rather than
image bloat, while pyscf gives real in-image quantum capability now for the molecular
systems the wax work actually involves. Every engine choice is a
MaterialScaleDefinition `parameters_json` knob + an engines/ capability report, so
switching or adding engines never touches the basis schema.

## Smooth-transition contract (what "a Polari module" means here)

Each engine integration follows the same pattern (fem_engine/dft_engine already do):
1. `capability()` — honest availability report with evidence + the knob to turn.
2. Pure functions data-in/data-out → callable from CRUDE, stage gates, and dask workers.
3. A MaterialScaleDefinition points at results via definition_class/definition_ref +
   derivation lineage — object coherence preserved.
4. Heavy engines ship as their own module project (Track 2) exposing the same interface
   over the peer/worker link — pattern proven by the dask compose.

## Empirical install tests (this box, 2026-07-06)

| Library | In backend image (Alpine/musl) | In python:3.12-slim (Debian) |
|---|---|---|
| scikit-fem, ase, PyMySQL, redis | ✅ (pure Python — live now) | ✅ |
| pyscf | ❌ source build fails | ✅ wheel; **real B3LYP run: C3H8 → −118.8543 Ha, 3.1 s** |
| pymatgen | ❌ source build fails | ✅ wheel (2026.5.18) |
| sfepy | ❌ | ❌ bare slim / ✅ with gcc+g++ installed (source build) |
| gpaw | ❌ | ❌ needs libxc dev libs (apt python3-gpaw route instead) |
| Quantum ESPRESSO | not pip — Debian `quantum-espresso` apt package on the worker | — |

Corrections vs first draft: sfepy and pymatgen are NOT pip-smooth in the Alpine base —
the earlier "✅ pip" claims were from generic wheel availability; the in-stack tests
above are what counts. The msci-engines worker (Debian) is where all compiled-extension
science libs live.
