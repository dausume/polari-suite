# Microchip design-level ladder — ratified shape + migration (lad arc)

**STATUS: RATIFIED (Dustin 2026-08-31) — the ladder shape below is decided.
Phases are NOT started; each confirmed phase gets its own branch off dev
(memory `branch-per-confirmed-phase`). No code until a phase is confirmed.**

> Naming note: this is the **design-level** ladder (`microchip/chip_basis.py`
> rungs — what composes into what). It is NOT `FET_LADDER_PLAN.md` /
> `si_ladder` (the open-silicon **rights × fabrication-evidence** ladder) —
> different axis, both stay.

## 0. The ratified ladder (Dustin, 2026-08-31, verbatim shape)

```
1 device (FET) → 2 standard-cell → 3 functional-block → 4 subsystem (core = one kind)
→ 5 die (monolithic boundary) → 6 package / chiplet-assembly  ← microchip ladder ends here
                                      ↓ exports a black-box PART
   composition module: boards → computers / motors / RF nodes / other electronics
```

Rationale (from the 2026-08-31 conversation):
- **Chiplet assembly is chip design**: die-to-die interconnect (interposer,
  UCIe-style links, stacks) is co-designed with the dies; timing/power budgets
  span the package; partitioning is an architecture decision; the physics is
  die-granularity (µm bumps, D2D PHYs), not board-granularity. So rank 6 lives
  ON the microchip ladder.
- **Subsystem generalizes core** (rank 4): a CPU core is one *kind* of
  subsystem; a memory-controller cluster or GPU slice is another. Kind, not
  level.
- **Die is the monolithic boundary** (rank 5): everything ≤5 is one piece of
  silicon; rank 6 composes die instances.
- **One hand-off point**: rank 6's output is a black-box PART (ports +
  characterized timing/power) consumed by the `composition` module. Computer
  assembly (cmp-c), motors, RF nodes etc. stay separate CLIENTS of
  composition — no new assembly system (`composition` already is the generic
  one: archetypes, interfaces, routings, audited promotions).
- **Same multiscale pattern at every rung** (proven at cell→block by
  `cnt_level_scenes`, 2026-08-31): a die is to a package what a cell is to a
  block — instancable black boxes carrying the lower level's REAL
  characterized data, with an interconnect layout between instances.

## 1. Current state (facts, 2026-08-31)

- `microchip/chip_basis.py` LEVELS today: `device(1) → standard-cell(2) →
  functional-block(3) → core(4) → chip(5)` — rungs are DATA.
- Seeded traversal nodes reference the old names (`polari-chip` level=chip,
  `polari-rv32e-core` level=core, …) → migration needed with any rename.
- Ranks 1–3 have LIVE artifacts (devices, libraries,
  Cell/BlockFETConfiguration + level scenes). Ranks 4+ have none — renames
  are cheap NOW.
- Config-object pattern per linked rung pair: `CellFETConfiguration` (2×1),
  `BlockFETConfiguration` (3×1). Rungs 4–6 get theirs when reached.
- `ARCHITECTURE_LEVEL_PLAN.md` (arch arc, PARKED) — its "level 3
  architecture" estimates map onto rungs 4–5 here; revive it AS the
  subsystem/die content, don't fork it.

## 2. Phases (each = own branch, confirmed one at a time)

### lad-0 — rung data migration (small)
`chip_basis.py`: rank 4 `core` → `subsystem` (with a `kinds` field:
`core`, `memory-controller`, `gpu-slice`, …; `core` = first kind), rank 5
`chip` → `die` (description: "monolithic boundary"), NEW rank 6
`package` (aka chiplet-assembly; composes die instances + interposer/passives;
description states the export contract). Migrate seeded node rows' `level`
values; traversal engine + `microchip-ladder` page + selftests follow.
Honesty rule unchanged: rungs with no artifacts REFUSE by name.

### lad-1 — the export contract as data
Define the black-box PART payload a rank-6 package exports: ports, protocol
class, characterized timing/power envelope (derived-or-cited, refusals
verbatim), provenance/freedom roll-up (worst-of everything beneath — same
rule as blocks). A `packaged-chip` archetype in `composition` consumes it.
No fake chips: until a real package rung exists, the archetype REFUSES with
the ladder path that would fill it.

### lad-2 — SubsystemConfiguration (when rank 4 is reached)
Same shape as BlockFETConfiguration one rung up: subsystem × device rows,
composition = BlockFETConfiguration linkage (down-links with `?device=`),
blocks carry `usedInSubsystems` up. Level scenes: blocks as instancable
black boxes. Prereq: a first subsystem definition (rv32e core from
`polari-rv32e-core` is the natural candidate — revive arch arc here).

### lad-3 — DieConfiguration (rank 5)
Subsystems as instancable boxes; die-level roll-ups (area/power honesty:
wire/floorplan gaps NAMED, not invented).

### lad-4 — ChipletAssembly (rank 6)
Die instances + D2D interconnect as a design object (the net-tracks pattern
one scale up); exports the lad-1 part. PARKED until rank 5 has artifacts.

## 2b. Kind generality — GPUs, AI chips, sim-specialized chips, memory
(Dustin's same-day extension, 2026-08-31: "generalize further beyond just
cpus… gpus, specialized computes like AI chips, math oriented specialized
chips… and account for ssd or hdd using fets… or RAM, whatever systems are
partially composed of fet based devices.")

**Principle: specialization enters as KINDS at existing rungs, never as new
ladders.** The ladder is about *what composes into what*; what the thing
computes is a kind axis on ranks 3–4.

| rung | logic kinds | memory kinds |
|---|---|---|
| 2 cell | INV/NAND/DFF… (library) | **bitcells ARE cells**: 6T SRAM, 1T1C DRAM, floating-gate/charge-trap flash — all FET-based, same characterize pattern |
| 3 block | ALU, FPU, MAC array, systolic tile, stencil unit, sparse-op unit | array + sense amps, bank + periphery, row/col decoders |
| 4 subsystem | cpu-core, gpu-compute-unit, npu-tensor-array, **sim-engine**, dsp | memory-controller, cache hierarchy, flash-channel controller |
| 5 die | CPU die, GPU die, accelerator die | DRAM die, NAND die, SRAM macro-heavy die |
| 6 package | SoC, chiplet CPU+GPU | **HBM stack = literally rank 6** (DRAM dies + logic die on interposer); DIMM-chip packages |

Where drives land: an **SSD is a composition-level product** (NAND dies +
controller die + DRAM on a board) — its *chips* are ladder objects, the
*drive* crosses the rank-6 hand-off into `composition`. HDD likewise
(controller chip on the ladder; motor/head assembly = composition, where the
motors module already lives). RAM modules (DIMMs) same split. This is the
hand-off point doing its job — no special cases.

### lad-5 — workload-profiled sim chips (the differentiator)
The math-specialized-chip idea, as data end-to-end (`derive-or-cite`,
`knobs-and-suggestions`):
1. **Profile**: instrument our own sim runs to count which
   `MatrixEquationOperation` nodes / equation forms dominate (we already have
   matrix-equation configuration objects — the workload profile is DERIVED
   from real runs, never assumed). → `WorkloadProfile` rows (op histogram,
   precision needs, data-shape/sparsity, memory:compute ratio).
2. **Map**: profile → suggested rank-3 block kinds (MAC array vs stencil vs
   sparse unit, sized from the histogram) with the evidence attached — a
   suggestion, not an assertion.
3. **Compose**: a `sim-engine` subsystem kind assembled from those blocks;
   scored against running the same profile on cpu-core / gpu-compute-unit
   kinds (the honest "is specialization worth it" number, refusing where
   characterized data is missing).
This makes the chip arc self-serving: chips designed FROM our simulations,
to speed up our simulations. Prereqs: lad-0 (kinds exist) + a profiling hook
in the sim engine. Extends the `cnt_targets` DesignTarget pattern
(target-scoped budgets → workload-scoped architecture).

## 2c. Non-FET physics: device FAMILIES first, peer ladders only when
## the composition topology differs
(Dustin 2026-08-31: "when those may be interweaved with other systems…
that may not cleanly be defined via just fets, if we need to build other
ladders that are peers to the fet ladder.")

**Tier 1 — generalize rank 1, not the ladder.** Rank 1 is `device`, and
FET is its first FAMILY, not its definition. Peer device families enter at
rank 1 under the same contract (characterized behavior, derive-or-cite,
refusals by name): capacitor (the C in 1T1C DRAM — already implied by
§2b!), memristor/RRAM/PCM/MRAM element, photonic (modulator, photodiode,
waveguide), MEMS resonator, on-die passives (inductor), spintronic.
Rungs 2+ then MIX families freely — that is how real chips are built:
- 1T1C DRAM cell = FET + capacitor (two families in one rank-2 cell)
- RRAM crossbar block = memristor array + FET selectors + CMOS periphery
- photonic transceiver block = optical devices + CMOS drivers on one die
- MEMS-on-CMOS = mechanical device + readout cells
The ladder is COMPOSITION TOPOLOGY (litho-built die structure), not FET
physics — so anything manufactured into a die rides it, whatever its
physics. Mixed-family cells/blocks need nothing new structurally; they
need the new family's device rows and characterization basis.

**Tier 2 — a true PEER ladder only when BOTH criteria hold:**
1. not composed lithographically into a die (different manufacturing
   substrate), AND
2. its natural rung structure differs (not device→cell→block→…).
Examples: battery ladder (electrochemical cell → module → pack), optics
assemblies, motor drivetrains (already its own world in the motors/
composition modules), possibly future quantum stacks (own intermediate
rungs; would still share ranks 5–6 die/package if litho-built).
**The machinery already supports this**: `chip_basis` stores ladders AS
DATA (polari-cnt-ladder + the RV16X-NANO precedent are already two rows) —
a peer ladder is another ladder definition with its own LEVELS, not new
code. Every peer ladder's top rung exports the SAME black-box PART
contract into `composition`, where interweaving actually happens (a drive
= NAND dies + controller + motor: two ladders + composition, no special
case).

Default rule when unsure: try Tier 1 (a family at rank 1) first; reach for
a peer ladder only when the rung structure genuinely fights you.

### fam-1 — Tier-1 family SHELLS (CONFIRMED by Dustin 2026-08-31; BUILT
### same day on branch dev-lad-1)
`microchip/chip_families.py`: `DeviceFamilyDefinition` rows — `fet` LIVE
(artifact classes counted per instance: AlignedCNTFETDevice /
SiliconMOSFET / ElectronicDeviceDefinition) + 6 SHELLS (capacitor,
memristor, photonic, mems-resonator, inductor, spintronic-mtj). Each
shell carries its characterization CONTRACT as data ({quantity, unit,
why} — revisable), its mixed-family composition targets (1T1C = fet +
capacitor; RRAM crossbar = memristor + fet; …), first target and plan
pointer. **Deliberate scope call: NO device treeObject classes for the
shells** — defining field schemas before a family's physics basis exists
violates the per-class schema-freeze rule; each family's own arc defines
its class when it characterizes something real (the shell note states
this verbatim). Routes `GET /api/microchip/families[/{name}]`; families
row (table + report panel) on `/display/microchip`; registered in
defClassList + seed pairs. `selftest_families` 9/9.

## 3. Non-goals

- NO new assembly system — `composition` is it; cmp-c stays its client.
- Board/PCB modeling: composition-domain (between packaged-chip and
  computer), its own future arc, not on this ladder.
- No renaming of the si_ladder (rights axis) — unrelated.

## 4. Open decisions (his)

| # | decision | default if unstated |
|---|---|---|
| D1 | rank 5 rename `chip` → `die`: keep `chip` as an alias in traversal? | yes, alias kept |
| D2 | subsystem kinds list — seed which? | cpu-core, memory-controller, gpu-compute-unit, sim-engine (names only; artifacts refuse) |
| D3 | when to confirm lad-0 | next microchip-module session |
| D4 | first memory bitcell in the cell library (6T SRAM is the natural one — pure FETs, no capacitor model needed) | 6T SRAM, when a cell-library session picks it up |
| D5 | lad-5 priority vs lad-1..4 (it only needs lad-0 + a sim profiling hook, so it can leapfrog) | his call — it is the differentiator |
| D6 | first non-FET device family to seed at rank 1 (capacitor unlocks 1T1C DRAM; memristor unlocks RRAM) | capacitor, when a memory-kind session needs it |

## 5. Status table

| phase | state |
|---|---|
| ladder shape | ✅ RATIFIED 2026-08-31 |
| lad-0 rung migration | planned |
| lad-1 export contract | planned |
| lad-2 SubsystemConfiguration | planned (revives arch arc) |
| lad-3 DieConfiguration | planned |
| lad-4 ChipletAssembly | planned/parked |
| lad-5 workload-profiled sim chips | planned (needs only lad-0 + profiling hook) |
| kind generality (§2b) | ✅ RATIFIED direction 2026-08-31 |
| device families + peer-ladder criteria (§2c) | ✅ RATIFIED direction 2026-08-31 |
| fam-1 family shells | ✅ BUILT 2026-08-31 (dev-lad-1; deploy owed) |
