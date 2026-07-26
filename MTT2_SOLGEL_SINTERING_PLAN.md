# mtt-2 (first two materials): Sol-Gel library, then Ceramic Sintering

**Status: PLAN ONLY 2026-07-26 — nothing built.** Part of
MATERIALS_TECH_TREE_PLAN.md mtt-2 (close per-core simulation gaps).
Order per Dustin: **sol-gel first** (cheap, high pspp reuse), **then
the ceramic sintering engine** (the one genuinely new engine). This
file is the "what to reference / know in advance" brief for both.

Engine substrate both build on already exists and is proven:
pspp (datasets/rules/windows/state-DAG/progress/grader), gsp
(structure_groups / structure_sampling / structure_scene /
structure_validation), and the msci scene pipeline. Read those first:
`modules/pspp/*.py`, `materialsScience/crystal_snapshot.py`,
GEOPOLYMER_STRUCTURE_SAMPLING_PLAN.md, PSPP_MATERIALS_PLAN.md.

────────────────────────────────────────────────────────────
## Part A — Sol-Gel library (statistical; ~a geopolymer-shaped build)

**Why it's cheap:** sol-gel is the SAME chemistry class pspp was built
for — hydrolysis/condensation are graph-rewrite rules, and Q^n
speciation is the standard characterization the gsp groups/sampler
already consume. It is geopolymer's sibling, not a new engine.

### What to reference / know in advance
- **Chemistry**: alkoxide precursors (TEOS/TMOS Si(OR)4; also
  Al/Ti/Zr alkoxides). Two rules: hydrolysis Si-OR + H2O -> Si-OH +
  ROH; condensation 2 Si-OH -> Si-O-Si + H2O (water condensation) and
  Si-OH + Si-OR -> Si-O-Si + ROH (alcohol condensation). Q^n rises
  Q0->Q4 as condensation proceeds — SAME motif ledger as geopolymer.
- **The catalysis fork is the key domain fact**: acid catalysis ->
  weakly-branched/linear gels (low Q4, spinnable); base catalysis ->
  dense colloidal particles (high Q4). This is a GATE
  (pH / H2O:alkoxide "R ratio"), the sol-gel analog of geopolymer's
  MR. Get this gate right and most of the physics follows.
- **Stages for the state-DAG**: sol -> gel point -> aging
  (syneresis) -> drying (xerogel vs aerogel fork) -> densification.
  Maps 1:1 onto MaterialState + cure_checkpoints.
- **Data sources to digitize** (DigitizedDataset rows, same reader):
  ^29Si NMR Q^n-vs-time curves (Brinker & Scherer "Sol-Gel Science"
  is the canonical reference — figures there are the geopolymer-book
  equivalent), gel-time-vs-pH, shrinkage-vs-temperature. Refuse
  out-of-range exactly like the Maekawa curves do.
- **Reuse directly**: gsp groups (Q distribution), the ensemble
  sampler + Debye halo (silica gel IS a corner-sharing tetrahedral
  network — the sampler applies verbatim; expect the acid/base fork
  to show in the halo/density), the grader (R-ratio + pH windows).

### Build sketch (branch off the pspp/gsp stack)
- sg-1: species library (alkoxides + ROH + the Si-OH/Si-O-Si motifs
  already in reaction_network) as SEED_CHEMICAL_SPECIES additions +
  a `sol-gel` process tag.
- sg-2: the two rule families as ReactionRule rows + the pH/R-ratio
  gate type (generalize network_stepping's condition gates — today
  they're MR/temperature; add a pH gate). THE one schema touch.
- sg-3: digitize 3-4 Brinker figures as DigitizedDataset rows; wire
  the acid/base catalysis fork.
- sg-4: state-DAG stages + cure checkpoints for sol->gel->xerogel/
  aerogel; grader windows for spinnable vs colloidal.
- sg-5: point the gsp sampler/halo at a sol-gel Q distribution;
  confirm acid (low-Q4, open) vs base (high-Q4, dense) shows in the
  density/halo. Selftests per phase; file onto
  materials-science/sol-gel (node already seeded, currently a shell).
- Honesty: no kinetics law without a cited calibration (same rule as
  geopolymer) — rules are stoichiometric/topological until data says
  otherwise.

────────────────────────────────────────────────────────────
## Part B — Ceramic Sintering engine (the genuinely-new one)

**Why it's new:** sintering is MICROSTRUCTURE evolution — grain
growth + pore elimination — NOT molecular graph rewriting. pspp's
network layer does not model it; the msci crystal layer models the
phase but not the polycrystal. This is a new engine, but it slots
into existing seams (L2 domain rows already anticipate grains/pores).

### What to reference / know in advance
- **The physics (three classic stages)**: initial (neck formation
  between particles), intermediate (interconnected pore channels
  shrink, grains grow), final (isolated pores close). The observable
  the whole engine targets is **densification: relative density rho
  vs (time, temperature)** and the **grain-size distribution**.
- **The governing knobs**: temperature schedule (already have
  ThermalProcessingProfile), initial particle size, applied pressure
  (pressureless vs hot-press/SPS), dwell time. Driving force =
  surface-energy reduction; rate-limited by a diffusion mechanism
  (grain-boundary vs lattice vs surface diffusion — each a different
  exponent).
- **Model families to choose among (pick the honest-simplest first)**:
  1. Analytical **Master Sintering Curve** (MSC) — density vs a
     single "work of sintering" integral over the T-schedule; needs
     one activation energy Q. CHEAPEST, data-calibratable, honest.
     Recommended first target.
  2. Mean-field grain-growth law (d^n - d0^n = K t, Arrhenius K).
  3. (Later, expensive) phase-field / kinetic Monte-Carlo on a
     microstructure grid — real spatial grains/pores. Only if the
     mean-field version proves insufficient; it is its own project.
- **The structure-layer seam (already exists)**: `material_structure`
  allows MULTIPLE L2 domain rows (grain domains, pore networks). The
  sintering engine WRITES these: grain-size descriptor + porosity
  descriptor + rho per MaterialState checkpoint. That is exactly the
  qDistribution-descriptor pattern gsp-4 reads — so a sintered-state
  "groups"/structure view comes almost free once the engine writes
  the rows.
- **Data sources**: densification curves (rho vs T) and grain-growth
  data are standard in ceramics literature per material (alumina,
  zirconia are the textbook cases); digitize as DigitizedDataset.
  The MSC activation energy Q is the one fitted constant — fit it
  from a curve, refuse to extrapolate past the data (pspp house rule).
- **Cross-cutting reuse**: porosity model here ALSO fills the known
  geopolymer-porosity gap (PSPP plan §4b) — build once, both benefit.
  Thermal/structural variant layers (mtt-4/5) read rho + grain size
  as their inputs, so this engine unblocks them.

### Build sketch (new engine, msci or pspp side)
- sinter-1: MSC engine — `sintering_engine.py`: work-of-sintering
  integral over a ThermalProcessingProfile -> rho(t); calibrate Q
  from a digitized densification curve; honest refusal off-range.
- sinter-2: mean-field grain growth (d^n law) alongside rho.
- sinter-3: write grain-size + porosity + rho descriptors onto L2
  ScaleStructureDefinition rows per cure/fire checkpoint (the seam).
- sinter-4: endpoint + a page panel (rho-vs-T curve via sci-xy-chart;
  reuse the pspp progress-chart pattern) filed onto
  materials-science/ceramics.
- sinter-5 (defer): phase-field/kMC spatial microstructure — its own
  plan if mean-field is insufficient.
- Selftests per phase; the MSC integral has an analytic check
  (isothermal hold reduces to a closed form) — good first assertion.

────────────────────────────────────────────────────────────
## Sequencing note
Sol-gel touches ONE schema thing (the pH gate) and is otherwise data
+ reuse — do it first to warm up and to prove the "swap the library"
claim a third time (after wax + CMC). Sintering is the real new
engine; start it from the Master Sintering Curve (analytic, cheap,
honest) and only escalate to spatial microstructure if the data
demands it. Both file onto already-seeded nodes (mtt-1) — the tree
homes exist.
