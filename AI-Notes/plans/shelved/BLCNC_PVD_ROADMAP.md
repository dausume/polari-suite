# BLCNC + PVD — Intertwined Proofing Roadmap

**Status: PLANNING.** Revises [BLCNC_PLAN.md](BLCNC_PLAN.md) into the 5
intertwined phases Dustin set (2026-07-17), interleaving the **Bombastic
Laser CNC** and **Open-Source Physical Vapor Deposition (OS-PVD)** tracks.
End goal: prove — first by ideal-condition theory, then by feasibility —
that open-source microelectronic manufacturing is possible, and use this
roadmap as the **worked example that flushes out the real Polari / OSEB
Tech Tree** (see [TECH_TREE_TOPOLOGY_PLAN.md](TECH_TREE_TOPOLOGY_PLAN.md)).

Each phase is a **Tech Tree node**; its theory work = Polari modules/sims,
its real work = CAD/hardware, with the dependencies below driving the tree.

---

## Phase 1 — `BLCNC-Proof-On-Ideal-WaxLayeredNanocomposite`
**Goal: prove the melt-voxel physics can work AT ALL under the MOST ideal
conditions** (not realistic ones). A pure idealization study with many
controls, to find an outcome that works.

Idealizations (all "magically perfect", explicitly flagged):
- **Perfect wax nano-composites**: fine-tuned nanoparticle embeddings that
  behave exactly per the notes (recipe-7-style FeOx/SiOx/CuOx/C tuning).
  Nanoparticle size, spacing, and absorption are set, not measured.
- **Perfectly spaced lattices + layers** to ANY dimensions, fine-tunable —
  a `IdealNanocompositeLattice` (lattice pitch, layer stack, per-layer
  nanoparticle type/fraction/size). Min layer ≈ ~1 µm crystallization floor
  is the only physical floor kept.
- **Laser array, 1 / 3 / 7 lasers** (1 best, 3 next, 7 last resort) fired
  in **alternation to refine a melt voxel**. Prefer the fewest lasers that
  work.
- **Per-laser controls, perfect aim + angle** BUT a **limited overhead
  angle** realistic of a 3D-printer-like gantry (a cone, not a hemisphere).
  Each laser: modulatable **power/size** and **switchable beam diameter**.
- **iCE40-realistic pulse switching**: laser on/off + laser-select switch
  at pulse rates a good/fast iCE40 FPGA can drive; if one candidate FPGA
  clocks faster, select it. Pulse timing = the FPGA's realistic floor.
- **Ideal melt-extraction conditions**: a near-vacuum atmosphere that still
  permits **suction to extract the melted residue** without introducing
  contaminants (an `IdealExtractionEnvironment`: pressure, suction flow,
  contaminant guarantee).

Physics proven (the melt-voxel engine, blcnc-2/3 from BLCNC_PLAN): ABCD
beam + Photon Potential Field + absorption per ideal composite → fluence vs
F_th → **melt voxel** with the **Single Melt Action Metrics** as gates
(Energy Dispersion Precision, Melt Dispersion Precision, Melt Dispersion
Leakage ≈ 0). Sweep laser count / size / pulse / angle / lattice to find
the ideal-condition recipe that hits leakage≈0. Reuses the whole waxprint
voxel + optimizer + no-code command pattern (a `LaserOperation`).

**Deliverable: a simulation proving "under ideal conditions, pulsed light
on a tuned nanocomposite makes a clean melt voxel."** No claim of realism.

---

## Phase 2 — PVD + verified melt-voxel → theoretical semiconductor
**Goal: prove BY THEORETICAL CALCULATION that a microchip can be made this
way.** Depends on Phase 1's verified melt-voxel + extraction cycle.

- **OS-PVD physics (theory)**: model physical vapor deposition for BOTH (a)
  making the wax itself and (b) depositing **sol-gel + carbon nanotubes**
  (or other materials) into laser-cut **wax masks** to make devices.
- **Cycle coupling**: PVD deposit → laser melt-voxel patterning →
  extraction → repeat. Prove the coupled cycle can lay down + pattern a
  functional structure.
- **Smallest possible device**, ideally enough for the **bare minimum of a
  2000s-era computer** (a minimum-viable RISC-V-class chip is the notes'
  stated ambition). Expandable via **3D build-up** of the chip (stacked
  deposit/pattern cycles).

**Deliverable: a theoretical device definition + the calculation that the
PVD+melt-voxel+extraction cycle can realize it** (ideal-condition still).

---

## Phase 3 — Move past idealization → feasibility (LOCKED by OS-PVD)
**Goal: what can ACTUALLY be produced.** Blocked until the OS-PVD solution
(Phase 2 theory) is solved concretely.
- Solve which **wax nanocomposites are actually producible** with the
  OS-PVD process, and **what stochastic materials** they really are (real
  size distributions, defects, variance) — replacing Phase 1's "perfect"
  composites with stochastic ones.
- **Phase 3.1** (can start earlier): **guess likely stochastic material
  definitions** from existing experimental knowledge of nanocomposites made
  via PVD / CVD / similar methods, and develop against those priors while
  the real process is solved.

**Deliverable: stochastic (realistic) material + process definitions that
the Phase-2 device is re-proven against.**

---

## Phase 4 — BLCNC hardware (PARALLEL, no PVD dependency)
**Goal: develop the BLCNC hardware itself**, independent of PVD, so it can
proceed in parallel with Phase 3.
- The laser fleet + ETL optics + gantry + the iCE40/ECP5 FPGA pulse-and-
  switch controller + safety-MCU + independent Laser-Enable-LOW interlock
  (BLCNC_PLAN §1) — designed + simulated in the hwsim twin
  ([[hardware-simulation]]).
- **Aluminum nanocomposite test voxels with embedded heat sensors** for
  **heat-propagation calibration** of the real device (a physical
  calibration standard the sim is validated against).

**Deliverable: BLCNC hardware design + a heat-propagation calibration
target.** Real segment of the tech tree.

---

## Phase 5 — Combined BLCNC + PVD all-in-one microfab device
**Goal: combine the Phase-4 BLCNC hardware with the OS-PVD hardware into
one device — an all-in-one open-source microelectronic manufacturing
machine.** Depends on Phase 3 (feasible materials/process) + Phase 4
(hardware).

**Deliverable: the integrated device design.**

---

## Dependency graph (drives the Tech Tree example)
```
                OS-PVD theory ─┐
Phase1 (ideal melt voxel) ─────┼─> Phase2 (theoretical chip)
                               │         │
                               │         v
                    Phase3.1 ──┴──> Phase3 (feasible materials/process, LOCKED by OS-PVD)
                                          │
Phase4 (BLCNC hardware, parallel) ────────┼─> Phase5 (combined microfab device)
```
- Phase 1 → Phase 2 (needs verified melt voxel + extraction).
- OS-PVD theory → Phase 2 (needs deposition physics) and → Phase 3 (lock).
- Phase 2 + Phase 3.1 → Phase 3.
- Phase 3 + Phase 4 → Phase 5.
- Phase 4 is parallel (no PVD dep).

## How this seeds the Tech Tree (OSEB worked example)
Each phase becomes a `TechNode` under the OSEB tree, with segments:
- **theory (blue)** ← the sim modules (waxprint melt-voxel/LaserOperation,
  the OS-PVD module, the ideal-nanocomposite module) + their completion.
- **real (red)** ← Phase-4/5 CAD + hardware + calibration target (proven).
- **business (yellow)** / **politics (purple)** ← added later (self-manufacture
  routes, open-hardware policy).
The `depends_on` edges above are the tech-tree dependency edges, exercising
the nesting + transient-dependency rendering. When every node's present
segments complete, this slice of the **Open Source Economic Baseline** is
proven.
