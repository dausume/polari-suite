# Computer composition + microchip continuation (cmp-c / chip arcs)

Written 2026-08-25 (Dustin's directive, post-downloads-push).
PLANNING ONLY — build starts on his go, per-arc. Two arcs run IN
PARALLEL and must stay SEPARABLE:

- **chip arc** — continue microchip functionality (the levels
  ladder: cntfet → device → digital → chip).
- **cmp-c arc** — computer ASSEMBLY + COMPONENTS as its OWN app,
  separable from microchip creation and levels.

## What already exists (assess against, never duplicate)

- `modules/computerparts` (ai-8): ComputerPartDefinition rows with
  DATED prices, 3 example builds, derived totals, assembly checks
  (socket/ram-type/psu answer today; gpu-clearance honestly
  unverified until lengths are declared). THE SEED of cmp-c — the
  new app grows from it, not beside it.
- `modules/microchip` + cnt arc (dev, merged): cntfet compact
  model (S1–S4c), electrodevice, hwdigital, hwfpga ladders; F3-
  Poisson/CharLib/OpenSTA/S6 queued (cnt memory). THE chip arc.
- `modules/composition` (arch-1..7): derived levels, EBOM/MBOM,
  PROMOTE + DFA gate, seed_upsert — composition MACHINERY the
  computer app should ride (a computer IS a composition of parts).
- dl-6 planner perf classes + pub-0 measured sizing; resource-
  awareness (res arc); hardware-architecture memory (MCU+FPGA
  stack, tiers); ai-6/7 hosting gauge + buy-vs-rent.

## cmp-c — the computer app (own module, own pages)

1. **cmp-c-0 survey**: map computerparts + composition seams;
   decide rows vs new classes (recommendation: ComputerPart stays;
   NEW ComputerAssembly = a composition.PartArchetype-backed tree,
   so EBOM/derived-levels come free).
2. **cmp-c-1 component taxonomy**: part CLASSES with declared
   interfaces — storage (HDD/SSD: capacity/interface/endurance),
   graphics (VRAM/slots/power), RAM (type/speed/channels), CPU,
   mainboard (sockets/lanes), PSU, cooling, chassis, NIC, FPGA
   accelerator cards. Each = declared specs + honest
   unverified-until-declared gaps (the ai-8 discipline).
3. **cmp-c-2 assembly composition**: a computer = tree of parts
   through composition; assembly checks become DFA-style gates
   (socket match, RAM type, PSU budget, physical clearance,
   lane/slot budget); refusals named per check.
4. **cmp-c-3 computer PROFILES** (the use-case layer): profile =
   declared requirements + fit scoring against an assembly —
   standard user desktop · assistive-AI dedicated (VRAM/RAM floors,
   ties to ai-6 hosting gauge + LocalAI profiles) · high-capacity
   storage for DEDICATED DATABASE BINDING (ties to object-
   ownership/databases arc: a computer profile that a database
   declares residence on) · FPGA/dev lab (ties hwfpga) · low-power
   member node (dl-6 'small') · more use-cases as rows, never
   hardcoded (knobs ethos: profiles are DATA).
5. **cmp-c-4 pages**: /computers app — parts catalog (dated
   prices), assembly builder (composition UI seams), profile fit
   report (evidence-bearing verdicts, ai-6 style).
6. **cmp-c-5 planner splice**: dl-6 planner's perf classes gain
   'see a concrete build' links into profiles; buy-vs-rent rides.

## chip arc — microchip continuation (parallel, separable)

- chip-1: F3 Poisson solve; chip-2: CharLib/OpenSTA timing ladder;
  chip-3: S6 circuit level (cnt memory's queued next steps).
- chip-4: the SEAM to cmp-c, defined narrowly: a chip-level
  artifact may DECLARE itself as fulfilling a component class
  (e.g. an FPGA or storage controller) — one interface table,
  no shared code paths, so the apps stay separable.
- Storage/graphics/RAM as CHIP capabilities (HDD/SSD controllers,
  GPU blocks, memory arrays) enter the chip LADDER as level
  targets, while cmp-c treats them as PURCHASABLE PARTS — the two
  views meet only at chip-4's declaration seam.

## Decisions for Dustin

1. cmp-c module name: `computers` (extend computerparts in place
   vs new module depending on it — recommend NEW module
   `computers` requiring computerparts).
2. Profile set v1 (the four above + which others?).
3. Does the database-binding profile create real topology hooks
   now (object-ownership arc) or declare-only v1?
4. chip-4 seam timing: with cmp-c-1 or deferred until a chip
   artifact actually reaches component maturity?

Sizing: cmp-c-0/1 one session; cmp-c-2/3 one-two sessions;
cmp-c-4 one session; chip-1..3 one session each (cnt patterns
established). Parallel-safe: separate modules, separate branches
(dev-cmpc-1 / dev-chip-1), composition + registry are the only
shared seams.
