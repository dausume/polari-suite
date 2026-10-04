# Demonstrables (demo arc): put a 2D sim-space on the page BEFORE the tables, on every hardware-arc page, reading the same rows the tables show

**Date:** 2026-10-04 · **Status: PLAN; demo-1 BUILDING on `dev-demo-1` (his word — see the handoff). D-demo-1..4 his.**
Drafted by an opus agent from the tree at suite `origin/dev` 7fc1f2f. Companions (read, not duplicated):
`DESIGN_LEVEL_VIEWS_PLAN.md` (dlv — the `level-view` component this plan's demo-5 rung reuses, and whose §2c/§6
slices own everything above RTL), `HARDWARE_NOCODE_PLAN.md` (hn — the canvas, `HardwareSolution`, placement,
`hn-split`), `C_MODULARIZATION_PLAN.md` (cmod — atoms, `CGraph`/`CGraphNode`/`CGraphEdge`, `cmod-glue`),
`FIRMWARE_SCENARIO_PLAN.md` (sc — scenarios, `ScenarioRun`, `ScenarioTraceCycle`), `AI-Notes/handoffs/BOARD_ARC_HANDOFF.md`
(what is merged to dev today).

## §0. His verdict (quoted verbatim, 2026-10-04)

> "unfortunately all of this work seems almost unusable as it is now, it is just many rows of data with no
> demonstratables or sim-spaces. We need a sim-space that is 2d at different LODs, what I see currently on ALL of
> those pages, are purely many tables that are very abstract and do not even have proper descriptions of what each
> table is for and what it's row and column logic is. There were supposed to be multiple 2D visualizations based on
> 2D sim-spaces, and there was also supposed to be C No-Code using the same approach as we had and objects for
> solutions in no-code in general, except incorporating C as you described and linking to those no-code solutions
> where they are used. I see none of those key pieces of functionality that were asked for."

Standing rulings this plan must honour, not re-litigate: LOD zoom is 2D ONLY, 3D is per-object detail reached by a
click (`design-lod-viewer` memory); step at the lowest clock; no raw JSON on screens — configured Table/Graph
definitions and the existing graph homes; the ONE `level-view` component with per-level renderers (dlv plan) is the
only new-component allowance it carries forward, and this plan adds exactly four more (demo-2's `board` renderer,
demo-3's `trace` renderer, demo-4's canvas-opens-CGraph wiring, and a pin-map SVG generator that is backend code, not
a component); C/Verilog/SV only on devices; derive-or-cite; every table gets a plain-words description.

## §1. What exists vs what was asked — per arc

| arc | rows / verbs / probes that exist today | demonstrable asked for | what is missing |
|---|---|---|---|
| **board** | `BoardDefinition`, `BoardPin` (canonical name ↔ SoC pin ↔ net ↔ connector pin ↔ firmware_symbol, brd-bo), `BoardInstance`, `FirmwareVariant`/`FirmwareBuild`, the installer flow (`firmware-installer-panel`, the ONE existing hardware component — STOMP-fed live rows, argv, frames table) | a drawing of the board you can SEE pins light up on | the installer panel shows frames as a text table, never a board drawing; `/display/boards` shows `boards-pins` as a table only, no SVG; no live 2D sim-space at all |
| **faults (sc)** | `ScenarioRun` (fault_cycle, fault_pc, landed_pc, outcome), `ScenarioTraceCycle` (per-instruction: cycle, pc, symbol, instruction, sp, sreg_i, isr_vector, r22..r25, watch, forced) — exactly the "cycle where it goes wrong" | a timeline you can step through, cursor on the fault, BEFORE/AFTER side by side | `/display/firmware-faults` shows ScenarioTraceCycle as a plain table (plan's own §6 admits this: "a run shows the VCD artifact link… until the 2D viewer takes the VCD"); no cursor, no step, no side-by-side |
| **cmod** | `CGraph`/`CGraphNode`/`CGraphEdge` (a real no-code graph over C atoms, cmod-1 proven byte-identical), the `c-atom` / `hw-interface` canvas overlays (hn-0, on the ONE canvas) | open a CGraph ON the canvas and edit/build/prove it like any other no-code graph | the overlays exist for single nodes dropped fresh, but there is no "open this existing seeded CGraph (`uno-sim-rig-graph`, 18 nodes) in the canvas" path; `/display/c-atoms` lists CGraphNode/CGraphEdge as 9 configured tables, no canvas, no diagram |
| **hwnocode** | `HardwareSolution`, `HardwareNodePlacement` (one row per node: board/twin/bridge/backend/browser + why), the split proof (uno-temp-split: twin 19, bridge 1, backend 6, browser 1) | the solution↔graph link visible both directions, a live chart of the twin's own data | `/display/hardware-solutions` is 3 configured tables + one GraphDefinition chart (named-graph-panel) — the placement rows exist but nothing draws "this board node maps to this C graph node maps to this solution," no canvas open-in-place |
| **pcb** | `Schematic`, `PcbBoard`, `FabricationExport` (gerber/drill/pos/bom/**svg**/step/job, per kind+layer, sha256), `DrcResult`/ERC rows, `Placement` (x_mm, y_mm, rotation, side) | the layout and schematic SHOWN, with DRC/ERC markers on it | `/display/pcb-*` pages are `class-rows-table` over `FabricationExport` — the SVG kind exists as a ROW with an `artifact_url`, but the page renders the row as a table, the SVG is a LINK to click, never shown inline; no layer selector; DRC/ERC rows are a separate table, never overlaid on the drawing |
| **dlv** | PLAN ONLY (no rows built: `designlevels` module is dlv-0, ungated) | a page per LOD level, one `level-view` with per-level renderers | nothing built yet — this plan's demo-5 is explicitly "ride the dlv plan's own slices," not a second plan for the same ground |

## §2. The definition of done (new, applies to every slice below)

1. **The demonstrable is FIRST on the page**, at the LOD rung the page is about. Tables sit BELOW it, never beside
   it as the only content.
2. **Every table on the page carries a plain-words description**: purpose, what one row IS, what each column means.
   This is not new display machinery — `_table(...)` already takes a description string (`board_page.py` already
   does this for most tables; the fault/cmod/pcb/hwnocode pages are the ones with thin or missing descriptions) and
   `/api/plain?classes=…` (the computelod pattern, cited by the dlv plan §2b) is the existing per-class plain-words
   door. demo-1 is the sweep that fills every gap, module by module, using each class's own `plain_words` attribute
   where set (board, cmod, hwnocode, pcb, firmwarefaults rows already carry `plain_words` — grep shows most classes
   have it; the gap is wiring it onto the TABLE description, not writing it from scratch).
3. **The demonstrable reads the SAME rows the tables below it show** — never a second, parallel data path. A board
   drawing reads `BoardPin` + live frames; a trace view reads `ScenarioTraceCycle`; a canvas reads `CGraphNode`/
   `CGraphEdge`; a PCB view reads `FabricationExport` + `Placement` + `DrcResult`.
4. **A browser-pass item per slice** — one line, what he should SEE, added to `AI-Notes/guides/HARDWARE_ARC_TEST_GUIDE.md`
   (not duplicated here).

## §3. The slices

### demo-1 (S) — BUILDING now on `dev-demo-1`: descriptions everywhere + PCB SVGs shown inline + the UNO pin map

- **Descriptions.** Every `_table(...)` call across `board_page.py`, `cmod_page.py`, `firmwarefaults_page.py`,
  `hwnocode_page.py`, `pcb_page.py` gets a one-line purpose + "one row = …" + a columns note, pulling from each
  class's `plain_words` docstring attribute where present, written by hand where it is not yet on the class.
- **Inline KiCad SVGs.** `pcb_page.py`'s schematic/layout displays currently show `FabricationExport` rows (kind=svg)
  as a `class-rows-table` with `artifact_url` as a link column. demo-1 adds an `svg-artifact-viewer` display
  component (new, small: an `<img>`/`<object>` over the artifact URL + a layer `<select>` built from the distinct
  `layer` values of the board's `svg` rows + markers plotted from `DrcResult.x_mm/y_mm` at the SVG's own mm→px
  scale, read from the `.kicad_pcb`/`.kicad_sch` page size already in `PcbBoard`). It is read-only (no edit, D-pcb-2
  stands); it is the ONE new component this slice needs, same justification class as `cell-schematic`.
- **The UNO pin map.** A generated SVG (backend, `pcb` or `board` custom code — board owns `BoardPin`, so it is
  `board/custom/pinmap.py`) rendering every `BoardPin` row for a board as a rectangle (MCU) with pins around the
  edge, each labelled `canonical` and coloured by `function` (gpio/pwm/adc/uart/i2c/spi/usb — theme tokens
  `--pin-<function>` + its `-text` pair, per `styling-theme-tokens`). Committed as a `FabricationExport`-shaped row
  (or a sibling `BoardView` row if `pcb`'s classes don't fit a non-PCB board) so it is itself a cited artifact with a
  sha256, shown the same way the KiCad SVGs are. Lands on `/display/boards` above `boards-pins`.
- **Proof:** every page in §1's table lists its tables with real descriptions (grepped, 0 empty); the ecc83-pp demo's
  schematic + 2-layer layout render inline with a working layer selector and the 2 DRC warnings marked on the
  drawing at their x_mm/y_mm; the UNO pin map SVG matches `boards-pins` row-for-row (every canonical name on the
  drawing, no extras, no omissions).

### demo-2 (L) — the UNO as a live 2D board sim-space. Rung 0 of the ladder.

**Component:** `level-view` renderer `board` (reuses the dlv plan's D-dlv-1 component shape and selection/zoom
machinery — NOT a second viewer component; dlv's `level-view` is parameterised by `level`, and `board` becomes one
of its registered renderers alongside `block`/`gate`/`transistor`/`placement`). Its `measure`/`draw`/`hit` contract
draws the demo-1 pin-map SVG's geometry (same rows, same layout — the SVG becomes the renderer's static base layer)
with a LIVE overlay: pin states (digital high/low), the ADC value (a needle/number on the ADC0 pin), LED state (fill
colour), PWM duty (a filled wedge or bar on the PWM pin), UART frames (a scrolling strip of decoded bytes/fields
along the TX/RX pins).

**Rows it reads:** `BoardPin` (geometry, function, canonical, firmware_symbol — unchanged from demo-1), live frames
from the bound class row (`SimRigState` today; the firmware-installer-panel's existing STOMP subscription is the
precedent: `fetchDisplaysForClass` + the class's STOMP topic), `BoardInstance`/the twin's running state (installer's
`doc.twin`).

**Live source:** the twin's frames over STOMP (the installer panel's existing path: `board/custom/twin.py` runs
simavr + the generated Java bridge; frames arrive as class-row pushes) WHEN a twin or real board is running; a
REPLAY of recorded frames (any `InstallRecord.frames` or a `ScenarioRun`'s decoded frames — same `SimRigState` shape)
when nothing is live, so the page always renders something (D-demo-1).

**Controls:** variant picker (same `FirmwareVariant` list the installer already has), ADC knob (`--adc0-mv`, already
a `board/custom/twin.py twin_args` parameter — exposed as a slider that calls the existing twin-restart path, not a
new knob), step / pause (pause = stop consuming new frames; step = advance one frame at a time from the buffered
queue — this is frame-level, not instruction-level; instruction-level stepping is demo-3's trace view, a different
rung).

**Page:** `/display/firmware-installer` gets it ABOVE `fi-flow` (the existing installer panel moves below it — the
drawing is what proves the install worked, the flow panel is how you got there); `/display/boards` keeps the STATIC
drawing from demo-1 (no live overlay there — that page is about the catalogue, not a running instance).

**Proof:** with the twin running, flipping `--adc0-mv` moves the drawn needle and the decoded `temp_c`/`uptime_ms`
visibly; pausing freezes the drawing while frames keep arriving server-side (buffered, not dropped — checked against
`frames_total`); with no twin running, the same page renders the last `InstallRecord`'s frames as a replay, stepped
frame by frame; the LED fill matches `led_on` on every frame, 0 discrepancies over a 60 s run.

### demo-3 (M) — fault scenarios as a cycle-resolution trace view. Rung 1.

**Component:** `level-view` renderer `trace` (or, if D-demo-2 goes the other way, a `sci-xy-chart` configuration —
see §5). Either way it reads `ScenarioTraceCycle` rows directly (cycle, rel_cycle, pc, symbol, instruction, sp,
sreg_i, isr_vector, r22..r25, watch, forced) with no new backend shape — the rows already carry everything a
timeline needs.

**Layout:** a cycle axis (x), rows = PC (symbol-labelled), ISR vector (0 = main loop), SREG.I, r22..r25, the watched
word — exactly the row layout `FIRMWARE_SCENARIO_PLAN.md` §3 already specifies for "the 2D viewer" ("row 1 = main-
loop PC … row 8 = g_ms bytes"). A cursor scrubs cycles; STEP moves to the next `ScenarioTraceCycle.idx` (the lowest
clock in the window — there is no finer granularity than one instruction boundary here, so "step at the lowest
clock" is satisfied exactly, not approximated). BEFORE/AFTER: two `ScenarioRun`s (same `Scenario`, different
`technique_applied`) drawn side by side, same cycle axis, so the torn read is visible on the left and its absence on
the right at the same relative cycle. The claim badge (`MathClaim` kind `safe-under-scenario`, status
refuted/witnessed/decided) sits on each side.

**Live source:** none needed — `ScenarioRun`/`ScenarioTraceCycle` are already written by the twin runs (sc-0..sc-3,
built); this is pure replay from rows, same contract as dlv's VCD cursor (§4 of the dlv plan) but reading pyvcd-
derived rows instead of a live VCD file.

**Page:** `/display/firmware-faults` gets it ABOVE the existing fault/technique/scenario/run tables.

**Proof:** scenario `torn-millis-read` BEFORE/AFTER side by side: the left trace visibly shows r22..r25 loaded across
the forced ISR (the 0xFF→0x100 carry landing between loads), the right shows the ISR pending through `cli`/`out
SREG`; stepping the cursor one instruction at a time matches the `ScenarioRun.fault_cycle`/`fault_pc` exactly; the
claim badge flips refuted/witnessed matching the row.

### demo-4 (L) — C in the no-code canvas, both link directions

- **Open an existing CGraph in the canvas.** Today the canvas only knows single `c-atom`/`hw-interface` nodes
  dropped fresh (hn-0). demo-4 adds: a CGraph loads into the canvas as its `CGraphNode` rows (atoms from
  `CFunctionAtom` as palette items, already the plan's `c-atom` overlay — reused, not rebuilt) + `CGraphEdge` rows as
  wires + the glue-owned kinds (`class`/`parser`/`frame`/`tick`/`rule`) as read-only nodes showing the generated
  `polari_graph.c`/`.h` the glue owns (text view, not editable — cmod's hand-edit guard stays the boundary: editing
  the generated C is a file edit tracked by `pol cmod diff`, never a canvas edit). Render / build / prove buttons
  call the EXISTING `GET/POST /api/cmod/graphs/{g}/render|/diff`, `pol cmod build`, `pol cmod prove` endpoints — no
  new backend verb, just UI buttons wired to what `pol cmod` already does.
- **Both-direction links.** `HardwareNodePlacement` already names, per solution, which `CGraphNode` maps to which
  placement; demo-4 adds the REVERSE index (a CGraph lists every `HardwareSolution` referencing it — a derived
  table, not a new row class, computed the way `board_page.py`'s existing cross-reference tables are: a query over
  `HardwareSolution.cgraph`). `/display/c-atoms` gets a "used by these solutions" table per CGraph; `/display/
  hardware-solutions` gets a "this solution's graph, opened" canvas link plus the placement table it already has.
- **The live chart.** `uno-temp-split`'s `SimRigTempSample`/`SimRigTempDerived` rows already exist (hn-0 proof: 258
  rows of both series); demo-4 wires a `GraphDefinition` + `named-graph-panel` (THE chart home, no new chart engine)
  on `/display/hardware-solutions` showing the twin's temperature live — reusing `sci-xy-chart` underneath exactly
  as the dlv and hn plans already do for IV curves and the uno-temp-split's existing chart tab.

**Page:** `/display/c-atoms` and `/display/hardware-solutions` both get the canvas-open-in-place ABOVE their tables.

**Proof:** opening `uno-sim-rig-graph` (18 nodes, 15 edges) on the canvas shows every atom with its real ports and
badges (ISR-safe/pure/cost, already derived data); render/build/prove from the canvas button reproduce the SAME
`.hex` sha256 (`4188f6ae…`) as the CLI path; `/display/c-atoms` lists `uno-temp-split` under "used by" for the
`uno-sim-rig-graph` row (or its successor graph); the temperature chart updates live during a twin run.

### demo-5 (per the dlv plan — reference, do not re-plan) — the ladder below the board, then semantic zoom

RTL/netlist/cells/layout renderers and the semantic-zoom composition are entirely `DESIGN_LEVEL_VIEWS_PLAN.md`'s
slices dlv-0 through dlv-6. This plan's only addition: demo-2's `board` renderer and demo-3's `trace` renderer are
written as `level-view` renderers (§3 above) SO THAT dlv-6's semantic zoom can, eventually, compose a board drawing
and a netlist drawing on the same canvas if a `DesignNode` ever ties a board pin to a netlist pin (not scoped here —
noted so the two plans' components do not diverge).

## §4. Order, browser-pass checklist, costs, licences

**Order:** demo-1 → demo-2 → demo-3 → demo-4 → demo-5, unless he reorders. Reasoning: demo-2 is first because
everything else either reuses its renderer contract (demo-5) or is independent of it (demo-3, demo-4) but demo-2 is
the only slice that proves a LIVE 2D sim-space exists at all — his verdict's central complaint. demo-3 next because
it needs no live hardware (pure replay from rows already on dev) and is the cheapest proof that "step at the lowest
clock" is real. demo-4 last among the near-term slices because it depends on the canvas's existing overlay
machinery being proven stable by demo-2's real usage first (a canvas regression would be caught against a graph
people are actually watching run).

**Browser-pass checklist (one line each, added to `AI-Notes/guides/HARDWARE_ARC_TEST_GUIDE.md`, not duplicated
here):**
- demo-1: every table on the five pages shows a description tooltip/caption; the PCB layout SVG renders inline with
  a working layer dropdown and the 2 DRC warnings marked on it; the UNO pin map SVG is visible on `/display/boards`.
- demo-2: `/display/firmware-installer` shows the board drawing above the install flow; moving the ADC slider moves
  the drawing; pause freezes it; with no twin running the page still shows a replayed drawing, not a blank panel.
- demo-3: `/display/firmware-faults` shows a BEFORE/AFTER trace pair above the tables; the cursor steps one
  instruction at a time; the claim badge matches the row's outcome.
- demo-4: `/display/c-atoms` opens `uno-sim-rig-graph` on the canvas with real ports and badges; the "used by"
  table lists `uno-temp-split`; `/display/hardware-solutions` shows a live temperature chart during a twin run.

**Costs:** demo-1's SVG viewer and pin-map generator add 0 MB of new engine image (KiCad SVGs are already exported
by `prf-pcb-engines`, the pin map is pure Python + a template, no new binary). demo-2's frame rate is capped at the
twin's own rate — measured 10.27 rows/s on tmpfs, ~2.65 Hz on a real disk (hn-0's storage-bound finding, owed core
fix before 10 Hz is sustained) — so the drawing's redraw rate is capped at the SAME rate, never faster than the data
(no interpolation invented between frames unless he asks for it later). demo-3 adds 0 MB (reads existing rows). demo-4
reuses the existing canvas and `cmod-glue`/`hn-split` compiler rows; 0 MB. SVG sizes: the UNO pin map is a few KB (≈
30 pins); the ecc83-pp layout/schematic SVGs are KiCad's own export sizes (unmeasured here — read off the
`FabricationExport.bytes` field once ingested, per `derive-or-cite`).

**Licences:** none new. The SVG viewer and pin-map generator are Polari code. KiCad's SVG export is already covered
by pcb-0's KiCad licensing note (GPL-2.0-or-later for the kicad-demos content used).

## §5. Decisions for him (D-demo-1..4)

- **D-demo-1 frame source priority for demo-2 (board sim-space): live STOMP first, falling back to replay, or
  replay-first with a manual "go live" switch?**
  **Recommendation: live-first with automatic fallback** (what §3 demo-2 already specifies) — the page should show
  SOMETHING the instant it loads (a replay) and upgrade to live the moment a twin/board's STOMP frames arrive,
  rather than making a person choose. This matches the installer panel's existing behaviour (it already polls as a
  STOMP fallback).

- **D-demo-2 is the fault trace its own `level-view` renderer (`trace`), or a `sci-xy-chart`/`GraphDefinition`
  configuration?**
  **Recommendation: its own renderer (`trace`)**, NOT a sci-xy-chart configuration. Reasoning: a sci-xy-chart
  (Observable Plot underneath) draws continuous/categorical series, not a multi-row register timeline with a
  stepping cursor, symbol-labelled PC bands, and a side-by-side BEFORE/AFTER layout with synchronized cursors — that
  interaction (cursor, step, two-pane sync) is exactly what the dlv plan's `level-view` already builds for the VCD
  cursor (§4 of that plan: "every page with a cursor colours nets/pins by value at t; the step = the next edge").
  Building `trace` as a `level-view` renderer reuses that cursor/step machinery instead of duplicating it inside a
  chart config, and keeps "one viewer component, renderers behind it" (dlv's own D-dlv-1 principle) intact rather
  than growing a second interaction model inside sci-xy-chart.

- **D-demo-3 where does the canvas open a C graph: its own route, or inside the solution/c-atoms page?**
  **Recommendation: inside the existing page** (`/display/c-atoms` and `/display/hardware-solutions`, as an
  embedded canvas panel above the tables — §3 demo-4), NOT a new route. Reasoning: his ruling on the dlv plan and on
  hn-0 (D-hn-2, "one canvas, not a second") both point the same way — a separate `/canvas/cgraph/<name>` route would
  fork navigation and state (selection, zoom) away from the object whose page it belongs to, and `per-object-display-
  config` already says displays live on the object's own page tabs. An embedded panel keeps the CGraph's canvas
  state scoped to the page that names it, consistent with `named-graph-panel` and `firmware-installer-panel` both
  being embedded, not routed.

- **D-demo-4 frame-rate cap for the live board drawing (demo-2):** **Recommendation: cap the redraw at the measured
  live rate (≈10 Hz on tmpfs / ≈2.65 Hz on disk today — hn-0's own numbers), with NO client-side interpolation
  between frames** (a held value, not a fake tween), so what is drawn is never faster or smoother than what actually
  happened on the device. Once the storage-bound fix (hn-0's owed core item: batched/async row saves) lands and the
  measured rate rises, the cap rises with it automatically — the cap reads the twin's own reported `frames_per_s`,
  it is never a hardcoded number.

---

Not in scope: VHDL/C++/Rust/MicroPython on devices (RULE 2, unchanged); editing a CGraph's generated C from the
canvas (cmod's hand-edit guard stays a file-level boundary); the dlv ladder's RTL/netlist/cell/layout renderers
(dlv's own slices, not re-planned here); a second chart engine (sci-xy-chart stays THE chart home); 3D views beyond
the existing click-to-detail precedent (his ruling, unchanged).
