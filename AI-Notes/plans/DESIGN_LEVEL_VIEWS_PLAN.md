# Design level views (dlv arc): a PAGE PER LEVEL that stands alone, one shared 2D viewer parameterised by level, and the capsule rows that tie adjacent levels together; the semantic-zoom viewer is built LAST from the same per-level renderers

**Date:** 2026-10-03 · **Status: PLAN ONLY — nothing built; decisions D-dlv-1..5 his.** Drafted by an opus agent from the
tree at suite `origin/dev` 94f2900 with framework / angular at the `dev-hn-0` tips 17b99ef / d563892; Fable reviews.
His ask (2026-10-03): *"We need pages per each level, so that we can look at them individually when only one is defined
but not another. … Put together the plan forward for making those visualizations and how we tie them together with
what we already have."* The design this plan builds is memory `design-lod-viewer` (his "this makes sense", 2026-10-01):
capsules with invariant ports + per-rung refinements, levels DERIVED by engines, `polari_block` preserved through
synthesis, ONE 2D semantic-zoom viewer, VCD as the time axis; **his ruling: zoom is 2D only, 3D = the object's detail
page reached by a click.** The board half of his ask is the companion `PCB_FROM_SCRATCH_PLAN.md` (pcb arc).
Facts marked **unverified** were not confirmed from a primary source on 2026-10-03.

## 0. The ask and the principle

1. **A page per level, standalone.** `/display/level-<rung>` for each ComputeLOD rung that has a graph to draw. A page
   reads ONLY its own level's rows; when nothing above or below exists it still renders fully (the "only one is
   defined" case). Each page is a configured display (`_page/_row/_table/_sapi` from
   `polariApiServer/module_pages_seed.py`, the `computelod_page.py` pattern) — tables per row class, structured
   readings, `named-graph-panel` for series — plus ONE viewer panel.
2. **One viewer component, per-level renderers.** The levels are all GRAPHS (nodes with ports, nets between them) but
   with different vocabularies (module boxes / cell instances / transistors / placed rectangles) and different layout
   sources (computed at RTL/netlist, hand-drawn at cell, real coordinates at layout). The minimum is ONE registered
   component `level-view` (selection, d3-zoom pan, the VCD cursor, up/down doors, the detail click) + a small
   renderer per vocabulary behind an interface. Not one component per level (five copies of selection/zoom/cursor);
   not one renderer for all (a DEF placement is not an ELK graph). The existing `cell-schematic` (fp-5,
   `components/dashboard/generic/cell-schematic.component.ts`, d3-zoom via `cell-diagram-shapes.ts attachZoom`)
   becomes the transistor renderer; `cell-logic-diagram` (fp-5, the gate-level DAG) the gate-symbol renderer.
3. **Ties are rows, added as glue.** The capsule rows (`DesignNode`, `DesignPort`, `DesignRefinement`,
   `DesignCorrespondence`, §2a) are what links levels. A page asks "does a refinement/abstraction exist for this
   node?" per node; when yes, the node shows a **down** door (to its refinement on the next page) and/or an **up**
   door. Nothing on a page depends on the neighbour existing.
4. **Semantic zoom last, by composition.** The zoom viewer (dlv-6) is `level-view` in "mixed" mode: a node replaced in
   place by its refinement drawn by the NEXT level's renderer inside the parent box. No second implementation.
5. Inherited rules: no raw JSON (every panel configured); per-object displays (a level's rows get their
   TableDefinitions on their own class pages); sci-xy-chart is the only chart home, reached through a GraphDefinition
   + `named-graph-panel` (hn-0 finding: sci-xy-chart is not itself a display component); `@container` not `@media`;
   colours as theme tokens (`--level-*` for node kinds, each with its `-text` pair); knobs + suggestions; derive or
   cite; costs measured into `ModuleResourceProfile` rows; every derived row carries a repro block (input sha256,
   engine digest, knobs).

## 1. What exists per level (verified in the tree)

Paths under `polari-rf-node/polari-framework/modules/` unless stated. Rungs = `computelod/computelod_seed.py`
`SEED_COMPUTE_LODS` (11 rungs; `design_level_ref` points rungs 4/6/7/8 at the microchip ladder's
`DesignLevelDefinition` rows, `microchip/objects/chip/DesignLevelDefinition.py`: rank, artifact_classes_json,
scale_axes_json).

| rung | rows today | generator / engine | artifacts | existing view | gap |
|---|---|---|---|---|---|
| 1 c-source | cmod `CProject/CModule/CFunctionAtom/CPort`, `CGraph*` | pycparser (cmod-0), `cmod-glue` | UNO firmware, 34 atoms / 6 configs | `/display/c-atoms` (tables) | no graph view of atoms (hn-0's canvas overlay shows a CAtom) |
| 2–3 compiler / ISA | `CompilerArtifact` (lod-1) | riscv-gcc in eda-tools | `lod1/add.c`, `add.s`, `add.objdump` | `/display/computelod` tables | fine as tables |
| 4 microarchitecture | `MicrochipDesignNode` (design, level, parent, artifact_refs_json, metrics_json) — a tree, hand rows | none | — | microchip page tables, `microchip-ladder` component | no derivation from RTL; no tags |
| 5 RTL | hwfpga `RegisterMapDefinition/RegisterDefinition` → `polari_regblock.v` (`hwfpga/custom/fpga_verilog.py render_core`); hwdigital `LogicBlockDesign/LogicBlockNode` → Verilog (`hwdigital/custom/logic_verilog.py render_module`) | the two generators; PicoRV32 pinned at `computelod/custom/rtl/picorv32/` (8 modules) | `lod1/rv32_add.v` (ONE flat module: `assign alu_out = reg_op1 + reg_op2`), `tb_rv32_add.v` | none | no module/port/net rows at all |
| 6 netlist | only counts: `CharacterizationMapping` gate_count (lod-1: adder 220 generic cells, PicoRV32 8126) | yosys in eda-tools; **`write_verilog -noattr`** (`computelod/custom/lod1_chain.py:133`) — attributes are STRIPPED; no `write_json` anywhere in the tree | `lod2/rv32_add_sky130.v` (96 sky130 cells, 855.82 µm²), `lod2/cnt/rv32_add_cnt.v` | none | no instance/net rows; `polari_block` would not survive today |
| 7 standard cells | cntfet `CNTCellDefinition`, `CellCharacterizationRun`; 25 cells switch-level (cntfet/sifet); two Liberties (SKY130 cached, `lod2/cnt/polari_cnt_lib.lib` ours) | ngspice + OpenVAF (cntfet ladder); OpenSTA | `lod2/decks/lod2c/*.sp` | `cell-schematic` + `cell-logic-diagram` (both d3-zoom, `/api/cntfet/cell/{cell}/logic`) — **the only zoomable views** | no library-wide page tying a netlist instance to its cell |
| 8 devices | lod-4c Ion/Ioff/Vt/DIBL/SS on the sky130 `SiliconProcessNode` row (`lod4_devices.py`); cntfet `AlignedCNTFETDevice`, sifet `SiliconMOSFET`; electrodevice `ElectronicDeviceDefinition`, `SpiceModelCard`, `CircuitRunResult` | ngspice (BSIM4 PDK models; VS-CNFET OSDI) | `lod3/decks/lod3b`, `lod3c` | FET pages (`fet-overview`, `fet-characteristic-explorer`) | IV curves already exist as FET pages — link, not rebuild |
| 9 layout | `ComputeMapping`/`CharacterizationMapping` rows only (lod-3e/3f numbers) | ORFS in `openroad/orfs` pinned by digest (worker `prf-orfs-engines`); magic + netgen (eda-tools) | per variant `lod3/pnr/{as-flow,cells-kept}/`: `6_final.def` (as-flow: DIEAREA 67.415 µm square, 624 COMPONENTS incl. 146 buffers + taps/fill, 98 PINS, 306 NETS), `6_final.spef`, `6_final.v`, `final_placement.webp.png`, DRC/LVS logs. **GDS never committed** (`6_1_merged.gds` regenerated by `lod3_pnr run`, per `pnr/drc_lvs_report.json`) | a PNG only | no placement rows; no layer view |
| 10 fabrication | pspp `ProcessingStage`, `MaterialProcessDefinition` (lod-4b sky130-/cnt- rows) | — | — | `/display/pspp` | link only |
| 11 materials | `MaterialsScienceMaterial` + `MaterialScaleDefinition` (lod-4d, 11 chip materials) | — | — | materials pages | link only |

Viewers that exist (`polari-platform-angular/src/app/`): `tensor-tree-panel` (d3 tree + mapping arcs; tt-12 hosts
`SimSpaceViewerComponent` = the 3D scene INSIDE a node's detail — the precedent for "click → 3D detail"),
`sci-xy-chart` (Observable Plot), `named-graph-panel`, `dashboard-renderer` + `models/dashboards/ComponentRegistry.ts`
(`registerDisplayComponent`), `block-detail-panel`, `cell-detail-panel`, `microchip-ladder`. Graph libraries in
`package.json`: d3 7, @observablehq/plot, three — **no ELK, no dagre**. VCD: `prf-board-engines` carries pyvcd 0.5.0
(MIT, hash-pinned) + `polari-vcd-window`; `firmwarefaults` `ScenarioTraceCycle` rows (one AVR instruction boundary
each: cycle, pc, symbol, instruction, sp, isr_vector, watch). SymbiYosys is in no image.

**The adder is the one design present at every level from RTL to layout** (RTL `rv32_add.v` → netlists 220 generic /
96 sky130 / 96 CNT cells → cells → placed+routed DEF ×2 variants, DRC 0, LVS match) — but its RTL is ONE flat module.
So hierarchy is proven on `polari_regblock.v` and PicoRV32; cross-level ties on the adder.

## 2. The rows and the pages

### 2a. Capsule rows (new module `designlevels`, one class per file; depends on computelod)

- **`DesignProject`**: a source set (files by sha256), top module, origin (`hwfpga`/`hwdigital`/`picorv32`/`lod`/
  upload), engine digests. One per ingest.
- **`DesignNode`**: project, `rung` (ComputeLOD name), `kind` (ComputeKind row), `hier_path` (Yosys hierarchical
  name, the identity across rungs), `parent`, `polari_block` (the stamped row id or ''), `src` (file:line from Yosys
  `src`), `tags_json` (microarchitecture kinds), `body_ref` (artifact path + sha), `cell_type` at netlist/cell rungs.
- **`DesignPort`**: node, name, direction, width — INVARIANT across rungs for a capsule (selftest: a refinement's
  boundary ports equal its parent's).
- **`DesignNet`**: project, rung, name, width, `driver`, `loads_json` (node.port bits).
- **`DesignRefinement`**: node@N → the node set @N+1, `how` (yosys-synth / abc-map / orfs-place / cell-netlist),
  `evidence_ref` (a `ComputeMapping` row where one exists — the lod rows ARE refinements at rung granularity).
- **`DesignCorrespondence`**: net/bit@N ↔ net/bit@N+1, `method` (name / `polari_block` / LVS), status.
- **`LevelLayout`**: a CACHE row — graph sha + engine + options sha → positions; never hand data; rebuilt on miss.
- **`PlacedInstance`** (layout rung): instance, cell, x, y, orient, from DEF; **`LayoutLayerTile`** (if D-dlv-3 = KLayout):
  layer, bbox, image artifact sha.

### 2b. The pages (one configured display each; viewer = `level-view` with `level=` and a renderer)

**`/display/level-microarchitecture`** — rows: `DesignNode` with tags at rung 5 pruned to tagged modules (+ the
existing `MicrochipDesignNode` tree as a second source). Derivation: the RTL hierarchy filtered by the
`(* polari_kind="alu" *)` attribute (hwdigital/hwfpga generators stamp it; PicoRV32 gets a tag file, never edits to
the pinned source). Alone: a tree of blocks + annotations (metrics_json) with no RTL needed (hand `MicrochipDesignNode`
rows). Ties: down → the module on level-rtl. Layout: ELK layered (block diagram). Knob `untagged=collapse|show`;
suggestion when >N untagged modules sit under a tag ("tag these to see them here"). Cost: trivial (tens of rows).

**`/display/level-rtl`** — rows: `DesignNode` (modules + instances), `DesignPort`, `DesignNet` at rung 5. Derivation:
`yosys -p "read_verilog -sv …; hierarchy -top T; proc; write_json"` (NO flatten, attributes kept). Alone: module
hierarchy table + per-module schematic (instances as boxes with ports, nets as orthogonal edges). Ties: down → the
module's netlist subgraph (by `hier_path`); up → its microarchitecture block; source door → `src` file:line. Layout:
ELK layered with port constraints, cached in `LevelLayout`. VCD cursor colours nets by value (§4). Knobs:
`expand_depth`, `bus_bundling=on`; suggestion on >300 nodes in one module ("bundle buses / expand one level").
Cost: PicoRV32 ≈ 8 module rows + hundreds of nets — small.

**`/display/level-netlist`** — rows: the same classes at rung 6 (cell instances `cell_type`, nets with bits).
Derivation: `synth -top T` (generic) or `dfflibmap/abc -liberty` (mapped: SKY130 or the CNT Liberty), then
`write_json`; hierarchy kept (`synth` without `-flatten`; the `(* keep_hierarchy *)` attribute on capsules).
`polari_block` + `src` follow each cell (yosys copies attributes it can; what is lost is SAID per cell, not guessed —
the dlv-0 measurement). Alone: an ingested netlist `.v` with no RTL (e.g. `lod2/rv32_add_sky130.v`) still renders.
Ties: up → the RTL module (hier_path / polari_block); down → the cell on level-cells; across → the placed instance on
level-layout. Layout: same ELK renderer, denser (gate symbols from `cell-diagram-shapes` `gateBodyPath`). Knob
`library=generic|sky130|cnt` (one netlist per library = a separate refinement, both kept). Suggestion when >2000
instances: "view by module (semantic zoom) or filter to a net cone". Cost: adder 96–220 cells; PicoRV32 8126 cells ≈
8k nodes + ~10k nets of rows — **measure** in dlv-1 (row count, DB bytes, layout ms).

**`/display/level-cells`** — rows: the cell library (`CNTCellDefinition`, sifet cells, Liberty-derived timing as
`CharacterizationMapping`), the census of a selected netlist. Alone: the library table + the existing single-cell
schematic and gate diagram (renderers) + Liberty tables (delay/slew/power per arc) as configured tables, delay vs load
as a GraphDefinition. Ties: up → every netlist instance of this cell (count, list); down → its devices. Layout: the
hand layout `cell-schematic` already computes (VDD top, GND bottom). Cost: 25 cells; nothing new to run.

**`/display/level-devices`** — rows: `SiliconMOSFET`, `AlignedCNTFETDevice`, `ElectronicDeviceDefinition`,
`SpiceModelCard`, the sky130 Ion/Ioff/Vt numbers. Alone: device tables + IV curves through a GraphDefinition
(`named-graph-panel`; sci-xy-chart underneath). Ties: up → the cells using this device flavour. 3D: click → the
device's own FET pages (`fet-overview` etc.). **Link-mostly: the FET arcs already own these views.**

**`/display/level-layout`** — rows: `PlacedInstance` + die area + pins + (optional) route segments from DEF; layer
tiles if D-dlv-3. Derivation: `pol design ingest --def 6_final.def` (a DEF reader in Python, stdlib: COMPONENTS /
PINS / NETS sections — ~600 components here); GDS stays un-committed and is regenerated (lod-3f rule). Alone: the
placement drawn to scale (rectangles by cell type colour token, rows, pins), a DRC/LVS verdict table (lod-3f rows).
Ties: up → the netlist instance by name (ORFS keeps instance names; inserted buffers/taps/fill have NO upward tie —
shown as "inserted by the flow", which is itself the finding lod-3e reported: 146 buffers). Renderer: real
coordinates, no layout engine. Layers: KLayout (GPL-3.0, verified) can render GDS/DEF to PNG headless via a
standalone `LayoutView.save_image_with_options` (verified, KLayout API doc) — as tiles from an engine, or our own
SVG of DEF rectangles only (D-dlv-3). 3D: click a cell → its detail page; a die 3D stack (layers extruded) is a
later per-object scene, never a zoom. Knob `variant=as-flow|cells-kept`; suggestion: "a placement density above the
`PLACE_DENSITY` knob — see lod-3e". Cost: DEF ≈ 155–197 kB; rows ≈ 624 + 306; KLayout already inside `openroad/orfs`
(4.6 GB, no new image) or its own Debian package (size **unverified**).

**`/display/level-fabrication`, `/display/level-materials`** — no new page: the pspp and materials pages are linked
from the ladder; a "level" alias row points at them (`/display/pspp`, materials). Ties = the lod-4b/4d mappings.

Every page also carries: a "what this level is" plain-words panel (`/api/plain?classes=…`, the computelod pattern), the
rung's `ComputeMapping` rows in/out, and the ingest provenance (`DesignProject` shas) as a table.

### 2c. The viewer component (`level-view`, polari-platform-angular, registered in ComponentRegistry)

Inputs: `project`, `level`, `node` (root), `mode` (`single`|`mixed`), `cursor` (trace window ref). Fetches
`GET /api/designlevels/view?project&level&node` → `{nodes, ports, nets, layout, ties}` (layout from `LevelLayout`;
on a miss the client runs ELK in a web worker and POSTs the result for caching). Renderer interface:
`measure(node) → size`, `draw(g, graph, layout)`, `hit(x,y) → node|net`. Renderers: `block` (ELK boxes, rungs 4–6),
`gate` (from `cell-logic-diagram`), `transistor` (from `cell-schematic`), `placement` (DEF coordinates). The two fp-5
components keep working standalone (refactor = extract their draw functions, not rewrite). Clicking a node opens its
detail (instance-detail-panel / the class page tabs — where a 3D scene lives, his ruling).

## 3. Ingestion: `pol design ingest <project>`

One verb, three inputs, every output a row set with shas (`computelod.custom.repro.record`):
- **Verilog/SV** (`--top T --rtl files…`): yosys through the engines ladder (`eda_engines.py`: knob → local binary →
  pinned image → topology provider `computelod.eda` → refusal) runs `hierarchy; proc; write_json rtl.json` and
  `synth [-liberty L]; write_json net.json`; Python maps JSON → rows (`designlevels/custom/yosys_json.py`). The
  generators stamp `(* polari_block="<row id>", polari_kind="<kind>" *)` on each module they emit (hwdigital
  `render_module`, hwfpga `render_core`); the flow drops `-noattr`. A selftest asserts the stamp survives to every
  mapped cell of a `keep_hierarchy` capsule — or lists where yosys dropped it (D: where the stamp lives if not).
- **A C project**: nothing new — cmod-0 already derives atoms; ingest links `CProject` → `DesignProject` so the
  c-source rung appears in the same tie graph (rung 1 node = an atom).
- **A placed design** (`--def F --netlist F.v`): DEF → `PlacedInstance`, nets; `6_final.v` → netlist rows tied to the
  pre-layout netlist by instance name.
Inputs are re-read by sha: re-ingesting unchanged files is a no-op (the second conform = no change, cmod's rule).

## 4. Time: the shared VCD cursor, then cycle-level C stepping

- **dlv-5 cursor:** a `TraceWindow` row (project, source = iverilog|verilator|simavr|ngspice, file sha, t0..t1,
  timescale, signal → `DesignNet` map by hierarchical name). VCD files live in the file store (SeaweedFS, fs-1);
  rows hold only the window index + per-net transitions for the visible window (pyvcd reads; `polari-vcd-window`
  already slices). Every page with a cursor colours nets/pins by value at t; the step = the next edge of ANY clock
  in the window (multi-clock: domain shown). First traces: the adder bench `tb_rv32_add.v` on RTL AND on the
  netlist (lod-1 already ran both under iverilog: "RTL and gates agree") → the same cursor drives two pages.
- **The C end:** `ScenarioTraceCycle` rows (sc-0) are instruction-boundary traces of the UNO firmware; mapped to
  cmod atoms by symbol, they animate the c-atoms page — the same cursor contract, a different source.
- **Cycle-level C stepping (dlv-7, after this arc's pages):** the reference core runs the riscv-gcc program under
  Verilator; "step a C line" = advance cycles until the PC leaves the line's DWARF range; register-file/bus nets
  animate on level-rtl. Pick (memory `riscv-cores-reference`): **PicoRV32** (ISC, native Verilog, already pinned in
  computelod, small: one module tree) for bare C; CVA6 (Solderpad, SV, RV64GC/Linux) as the large later case.
- **Deadlock tiers (dlv-8):** detect (watchdog rows over a trace) / prove (SymbiYosys as a mathproofs tier — not in any
  image yet; licence + size to verify first) / estimate (stimulus distributions) — per the design memory; first
  subject the bridge's UART rx parser FSM.

## 5. Decisions (his; recommendations in bold)

- **D-dlv-1 viewer shape:** **one `level-view` component + per-level renderers** (selection/zoom/cursor/doors once;
  the fp-5 views become renderers) vs one component per level (duplicated interaction code ×5).
- **D-dlv-2 layout engine:** **ELK via elkjs** for rtl/netlist/microarchitecture — EPL-2.0 **with "GNU General Public
  License v3.0 or later" designated as a Secondary License** in its LICENSE.md (verified,
  https://raw.githubusercontent.com/kieler/elkjs/master/LICENSE.md) → GPLv3-compatible; layered layout with port
  constraints and orthogonal edges is what schematics need, which d3 has no layout for (d3-force tangles a netlist).
  Lazy-loaded in a web worker like Observable Plot; bundle size **unverified** (measure). Alternative: our own
  longest-path layering in d3 (no dependency, weaker crossings).
- **D-dlv-3 layout layers:** **phase 1 our own SVG of DEF rectangles (no engine); phase 2 KLayout as an engine for GDS
  layer tiles** (GPL-3.0 per its LICENSE file, verified https://raw.githubusercontent.com/KLayout/klayout/master/LICENSE;
  headless images via a standalone `LayoutView` per https://www.klayout.de/doc-qt5/code/class_LayoutView.html; it
  reads GDS2/OASIS/LEF/DEF/Gerber per https://www.klayout.de/) — already present in the pinned `openroad/orfs` image.
- **D-dlv-4 first page:** **RTL + netlist together** (Yosys makes both from one source; the adder + regblock exist),
  then cells (the schematic exists), then layout (the DEF exists).
- **D-dlv-5 reference core for C stepping:** **PicoRV32** now (pinned, ISC, Verilog), CVA6 later.

## 5a. ✅ D-dlv-1..5 RULED 2026-10-03 — "go with all other recommendations": ONE parameterised `level-view` component with
a renderer per level; ELK (elkjs) for the RTL / netlist / microarchitecture layouts; the layout level drawn from the DEF
first, KLayout for GDS layers later; RTL + netlist pages first, cells second; PicoRV32 as the reference core for
cycle-level C stepping.

## 6. Slices (each its own branch off dev; proofs on the adder at the hardware end, the UNO atoms at the C end)

| slice | what | proof | gate |
|---|---|---|---|
| dlv-0 | module `designlevels`: the §2a rows; `pol design ingest` for Verilog (yosys `write_json`, no `-noattr`, no flatten); the `polari_block`/`polari_kind` stamp in the hwdigital + hwfpga generators; `/api/designlevels/*` | ingest `rv32_add.v`, `polari_regblock.v`, PicoRV32: row counts + shas; port invariance selftest; the stamp traced RTL → generic → sky130 cells, losses listed; re-ingest = no change; cost row (rows, DB bytes, yosys CPU-s) | D-dlv-4 |
| dlv-1 | `level-view` + `block` renderer + ELK worker + `LevelLayout` cache; pages level-rtl, level-netlist | adder RTL alone (no netlist ingested) renders; `lod2/rv32_add_sky130.v` alone (no RTL) renders; both ingested → each regblock/adder node gets up/down doors; PicoRV32 8126-cell netlist: layout ms + memory measured; no raw JSON (browser pass) | D-dlv-1, D-dlv-2 |
| dlv-2 | level-cells: library tables, Liberty arcs, `gate`/`transistor` renderers extracted from fp-5 | the two fp-5 components unchanged in behaviour (their specs green); a netlist instance → its cell → its devices by doors; the census of the adder (xnor2 61, maj3 29 …) matches `pnr_report.json input_netlist.census` | dlv-1 |
| dlv-3 | level-layout: DEF ingest → `PlacedInstance`; `placement` renderer; DRC/LVS tables | both variants drawn to scale (die 67.415 µm); 96 logic cells tie up by name, 146 buffers + taps shown as flow-inserted; side by side with `final_placement.webp.png` | D-dlv-3 |
| dlv-4 | level-microarchitecture (tags), level-devices (links + IV GraphDefinitions), alias rows for fabrication/materials; c-atoms joins the tie graph | a hwdigital LogicBlockDesign stamped → appears on microarchitecture/rtl/netlist with doors; UNO atoms (cmod-0) appear as rung-1 nodes; every level page renders with every neighbour absent (selftest per page) | dlv-1 |
| dlv-5 | `TraceWindow` + the shared cursor on rtl/netlist/c-atoms | `tb_rv32_add.v` VCD on RTL and netlist: same values at every edge on both pages; a `ScenarioTraceCycle` window animates the UNO atoms (the torn `hal_millis` read visible at its cycle) | dlv-2 |
| dlv-6 | semantic zoom = `level-view mode=mixed`: a node expands in place via its refinement, drawn by the next renderer | adder: RTL box → its 96 cells inside the box → one cell → its transistors, without leaving the page; PicoRV32 one module expanded while the rest stay RTL; 3D only via the click → detail page | dlv-1..5 |

After this arc: dlv-7 cycle-level C stepping on PicoRV32 (D-dlv-5), dlv-8 the deadlock tiers.

**Cost (estimates until measured, `resource-cost-tracking`):** no new engine image for dlv-0..5 (yosys/iverilog in
`polari-eda-tools`, ORFS image for regeneration only, pyvcd in `prf-board-engines`); elkjs in the Angular bundle
(lazy); rows per design ≈ (cells + nets) per rung — the PicoRV32 netlist is the stress test and its numbers decide a
knob `max_rows_per_rung` (beyond it, a rung stays an artifact + counts, with the suggestion to view by module).

Not in scope: 3D zoom (his ruling), editing designs from the viewer (the no-code canvas owns editing), a second chart
engine, VHDL/Chisel sources (generated Verilog only, `language-layering`).
