# Computer composition + microchip continuation (cmp-c / chip arcs)

Written 2026-08-25 (Dustin's directive, post-downloads-push).
**BUILD STATUS 2026-08-25 (same-day session, on his "keep
working" go): chip-1 BUILT (D13 SCF Poisson, cntfet 72/72 — and
the identity pin CAUGHT an S5-era a1/a2 mirror bug in eq.(5),
fixed) ∥ cmp-c-0..4 BUILT (computerparts PORTED from dev-ai-1 —
it was never on dev — + new modules/computers: taxonomy, gates,
profiles, /display/computers page; computers 22/22,
computerparts 14/14, lazy-imports 15/15). ALL UNCOMMITTED
(no-git-during-work rule); disjoint file sets ready for
dev-chip-1 / dev-cmpc-1. Decisions 1–4 were taken as this plan's
recommendations pending Dustin's ratification (seeds converge by
upsert if overridden). Remaining: cmp-c-5 planner splice,
composition MATERIALIZATION (view-only v1), chip-2/3
(CharLib/OpenSTA, S6), chip-4 seam (deferred). Details:
TESTING_OWED §000.**

**SESSION 2 (2026-08-26): BOTH ARCS GOT THEIR NAV APPS — the
2026-08-25 work was live but unreachable by browsing (no
PolariAppDefinition rows). Module-LOCAL app rows (climate_app
pattern, keeps commit sets disjoint + modules droppable):
computers/computers_app.py = `app-computer-assembly` (Computer
Assembly), cntfet/cnt_app.py = `app-microchips` (Microchips &
Semiconductors); seed passes wired in polariServer. 14 apps
live-verified. PLUS cmp-c-6 BUILT (interconnects as data — §7
below) on his directive; cmp-c-7 visual workbench PLANNED (§8).
All UNCOMMITTED, same no-git rule; computers_app + cmp-c-6 files
→ dev-cmpc-1, cnt_app.py → dev-chip-1, polariServer.py carries
BOTH seed passes (already in the dev-cmpc-1 set — flag at the
split).** Two arcs run IN
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
7. **cmp-c-6 interconnects as DATA** (✅ BUILT 2026-08-26, his
   directive: "mappings to what their viable interconnects are…
   communication parts… embedded directly or attached via
   usb/usb-c, and the parts that enable usb attachment at all"):
   NEW `InterconnectDefinition` rows = the port/connector
   vocabulary (17 seeded: cpu-socket, ddr4-dimm, pcie-x16/x4,
   m2-key-m/key-e, sata-data/power, usb-a/usb-c, the
   usb2/usb3/usb-c HEADERS that enable front-panel USB, rj45,
   power connectors). Parts declare `ports_provided` /
   `ports_required` {token: count} on specs_json; pure engine in
   computers_ports.py: `viable_links` (pairwise), `interconnect_
   matrix` (nodes+edges, undeclared parts LISTED never guessed),
   `port_budget_gates` (per-token provided-vs-required — ok /
   mismatch only on a DECLARED shortage / unverified) joined into
   assembly_gate_report. NEW PART_KINDS + taxonomy rows: `comms`
   (wifi/bt/cellular — EMBEDDED m2-key-e vs ATTACHED usb-a/usb-c
   falls out of ports_required, not a subclass) and
   `usb-expansion` (PCIe USB controller cards / hubs / header
   adapters — the ENABLERS). 3 UNPRICED example parts (ai-8 rule:
   dated price only when sourced). API: GET
   /api/computers/interconnects + /interconnects/build/{name}.
   Page row 3 on /display/computers. Selftest 22→30.
8. **cmp-c-7 visual assembly workbench** (NEXT, his directive:
   "more intuitive and visual display of selecting parts…use the
   existing d3 topology and other mappings"): the frontend over
   cmp-c-6's matrix. Surveyed reuse paths (NO new graph engine,
   per frontend-graphing-capability):
   - **Slot/connector path** (interactive assembly): the no-code
     editor's `models/noCode/Slot.ts` + `Connector.ts` +
     `d3-extensions/RectangleStateLayer` — parts as nodes, ports
     as typed angular-positioned slots WITH cardinality
     (allowOneToMany/allowManyToOne) and drag-to-connect incl.
     invalid-drop rollback, all already built.
   - **Topology path** (read-only compatibility map): feed the
     matrix in `TopologyGraph` shape into `topology-graph-view`
     — nesting (board contains ram/cpu), typed colored edges,
     resolved/unresolved/degraded ≈ ok/mismatch/unverified.
   - **Palette**: `sim-space-selector` (registered, seedable
     from backend like the periodic table) or the no-code
     `state-tool-sidebar` for the pick-a-part step.
   Recommended v1: a `computer-workbench` display component =
   topology-path map + part palette filtered by kind, edges
   colored by port-budget verdict; slot/connector interactivity
   as v2. ⚠ Angular work — lands in polari-platform-angular,
   which currently carries dev-chip-1's working tree: needs its
   own branch cut at his commit split (or after dev-chip-1
   lands) to keep the arcs separable.

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
