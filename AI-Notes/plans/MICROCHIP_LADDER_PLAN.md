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

## 3. Non-goals

- NO new assembly system — `composition` is it; cmp-c stays its client.
- Board/PCB modeling: composition-domain (between packaged-chip and
  computer), its own future arc, not on this ladder.
- No renaming of the si_ladder (rights axis) — unrelated.

## 4. Open decisions (his)

| # | decision | default if unstated |
|---|---|---|
| D1 | rank 5 rename `chip` → `die`: keep `chip` as an alias in traversal? | yes, alias kept |
| D2 | subsystem kinds list — seed which? | core, memory-controller only |
| D3 | when to confirm lad-0 | next microchip-module session |

## 5. Status table

| phase | state |
|---|---|
| ladder shape | ✅ RATIFIED 2026-08-31 |
| lad-0 rung migration | planned |
| lad-1 export contract | planned |
| lad-2 SubsystemConfiguration | planned (revives arch arc) |
| lad-3 DieConfiguration | planned |
| lad-4 ChipletAssembly | planned/parked |
