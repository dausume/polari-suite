# GEOPOLYMER STRUCTURE SAMPLING — lattice-quality views for stochastic structures

**Status 2026-07-26: gsp-1..4 BUILT (see Build state below), gsp-5
parked. Companion to
PSPP_MATERIALS_PLAN.md (§4b gap register) and the ssp crystal pages
(SOLID_STATE_PHYSICS_PLAN.md). Dustin's ask: geopolymer structure pages
displayed "similarly to crystal lattices despite being defined
stochastically — accounting for different groups and showing the most
likely groups per material."**

## Principle

Geopolymers are amorphous: there is no unit cell, only an ENSEMBLE.
The honest analog of the crystal page is (a) the motif DISTRIBUTION as
first-class data and (b) REPRESENTATIVE SAMPLES drawn from it, clearly
labeled as samples. Everything builds on machinery that already exists:

- `pspp.q_distribution.q_glass_distribution(cation, MR)` → Q0–Q4
  fractions (Maekawa curves, Na/K), bands + honest refusals out of range.
- `pspp.material_structure` — `qDistribution` descriptor per
  MaterialState per scale (motifs are summaries, never the structure).
- `pspp.reaction_network` species/motifs + `network_stepping` (species
  populations evolve through cure checkpoints).
- ssp scene pipeline: `crystal_snapshot`-style compiler →
  freestandingOnly `SimSpaceDefinition` (spheres + oriented-cylinder
  bonds, element materials) + the crystal-structure-view page patterns.

## Phases

### gsp-1 — most-likely-groups panel (data only, cheap)
`GET /api/pspp/structure/groups?material=<state>|(cation,MR)` returns
ranked motif fractions (Q0–Q4 + network species where a stepped state
exists), uncertainty bands, provenance, and the standing Q4-NMR-artifact
caveat. Angular: per-material "Groups" panel (reuse `sci-xy-chart`
bars + banded gauges from pspp-v3) on `/pspp` and the material detail
view. No sampling yet — pure join of existing data. Selftest: fractions
sum to 1 within tolerance; out-of-range MR refuses with the knob named.

### gsp-2 — ensemble sampler (backend)
`build_geopolymer_sample(qdist, nTetrahedra, seed, cation)` →
one amorphous cluster: SiO4/AlO4 tetrahedra with connectivity drawn to
match the Q-distribution (bridging vs non-bridging oxygens explicit),
Al sites charge-balanced by Na+/K+ placements, simple distance-geometry
relaxation (no periodicity; bond lengths/angles from literature bands).
DETERMINISTIC per seed — same seed, same cluster (reproducible views;
"resample" = new seed). Honesty: result carries achieved-vs-target
Q-fractions (small N can't hit fractions exactly) + sample-not-structure
flag. Selftests: achieved fractions converge with N; charge balance
exact; determinism.

### gsp-3 — scene compilation + page
Sampler output → the ssp scene compiler path (spheres + cylinder bonds,
jmol materials, bridging/non-bridging O distinguished, cations as
spheres) → SimSpaceDefinition per (state, seed). Angular
`/pspp/structure`: picker (material state or cation+MR), embedded
SimSpace scene, Groups panel (gsp-1) beside it, resample + nTetrahedra
knobs, honesty chip "sample from ensemble, seed=N". Follows the
crystal-structure-view layout so crystals and geopolymers read as
siblings. Theming per FRONTEND_THEMING_PLAN rule from day one.

### gsp-4 — cure-time evolution (rides network stepping)
Groups panel + sampler keyed to cure checkpoints: slurry → gel → cured
states get their own distributions (from stepped species populations
where available, glass/solution reference data otherwise); state-DAG
links each state to its structure view. Animation = resampling along
checkpoints with the same seed.

### gsp-5 (later) — validation hooks
Sampled clusters → simulated XRD amorphous halo / pair-distribution
sanity vs. literature; ties into the msci-engines worker. Only worth it
once gsp-1..3 are used in anger.

## Build state (2026-07-26)

- ✅ gsp-1: `pspp/structure_groups.py` — reference mode (glass Na/K,
  solution Na at listed MRs) + ranked groups + caveats/assumptions;
  `GET /api/pspp/structure/groups`. 24-check selftest.
- ✅ gsp-2: `pspp/structure_sampling.py` — deterministic-seed cluster
  sampler (largest-remainder Q counts + parity repair, stub pairing,
  Loewenstein swap repairs, spring-relaxed centers, terminal-O arms,
  one cation per Al). achievedQ vs targetQ always reported.
- ✅ gsp-3: `pspp/structure_scene.py` (reuses crystal_snapshot
  emission; pale `geopolymer-terminal-o` material) +
  `POST /api/pspp/structure/{sample,scene}` (scene upserts the
  SimSpaceDefinition + missing Material3D rows) + Angular
  `/pspp/structure` (groups bars, knobs, sim-space-viewer embed,
  honesty chips, refusal rendering; theme tokens per
  FRONTEND_THEMING_PLAN). 21-check selftest incl. scene.
- ✅ gsp-4 (state mode): groups keyed to resolved MaterialStates via
  the `qDistribution` structure descriptor; missing descriptor =
  honest refusal naming the exact row/knob (never guesses); page
  offers the reference-mode fallback. NOTE cure checkpoints do NOT
  yet write qDistribution descriptors, so state mode refuses until
  someone records one — deliberate.
- ✅ gsp-4b: `structure_groups.stepped_groups` — solution inventory →
  scientist-driven step_once chain → qn-carrying populations →
  fractions; quantified-but-unmapped species (e.g. ortho-sialate)
  and present-unquantified reported, di-siloxonate/Q1 alias counted
  once; `POST /api/pspp/structure/stepped-groups`; "stepped" mode on
  the page (rule xN lines). Fractions ride to sample/xrd as explicit
  qFractions.
- ✅ gsp-5: `structure_validation.simulated_halo` — finite-cluster
  DEBYE pattern (correct tool: no unit cell, so the worker's
  pymatgen periodic XRD does not apply). f=Z first-order intensities;
  size-envelope removed by moving-average baseline; residual peaks
  reported with d-spacings; gel-band (26-30.5° CuKa, d~3.0-3.3 Å
  sanity band) verdict = any peak in band. `POST
  /api/pspp/structure/xrd` + chart panel (sci-xy-chart) on the page.
  ⭐ The halo validation immediately caught a REAL sampler bug: the
  relaxation repulsion sign was inverted (clusters collapsed to
  0.04 Å pair distances) — fixed, with a min-T-T regression check in
  the sampling selftest. Validation earning its keep on day one.
- ✅ gsp-2b (densification): `targetDensity` knob (default 2.0 g/cm3,
  0 = open network) — container-radius packing in the relaxation
  (repulsion 0.75 + annealed steps from a 2026-07-26 parameter sweep;
  0.25 let packed pairs jam to 1.6 A), achieved density reported as a
  bounding-sphere estimate with its mean-unit-mass assumption; page
  knob + packed-density chip. HONESTY CALL: no density target lands
  the halo in the gel band on EVERY seed (~half do; default case
  does) — the band verdict is left as an honest fidelity readout of
  the toy relaxation, NOT tuned until it flatters. Next fidelity step
  if wanted: ring-statistics bias in stub pairing.
- Selftest totals: 24 (groups) + 22 (sampling incl. geometry guard)
  + 24 (stepped+halo) = 70 checks green in-container.

## Order + gates
gsp-1 standalone; gsp-2+3 together (backend then page); gsp-4 after 3.
Branch per phase off the pspp/ssp stack, review gate before merge,
selftests per phase as sketched.
