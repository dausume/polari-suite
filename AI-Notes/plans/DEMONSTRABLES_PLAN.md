# Demonstrables (demo arc): put a 2D sim-space on the page BEFORE the tables, on every hardware-arc page, reading the same rows the tables show

**Date:** 2026-10-04 · **Status: PLAN; demo-1's descriptions sweep + derived board readiness MERGED to dev at
`23e38cf` (the inline-SVG viewer and UNO pin map named in demo-1 below are NOT in that merge — verified by file
search, not yet built). His reordering ruling (same day, quoted in §4) puts demo-4 FIRST. D-demo-1..5 his.**
Drafted by an opus agent from the tree at suite `origin/dev` 7fc1f2f; revised the same day at `23e38cf` for the
reordering + target-definitions ruling. Companions (read, not duplicated):
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

### demo-1 (S) — descriptions sweep MERGED (`23e38cf`); PCB SVGs inline + the UNO pin map STILL OWED from this slice

- **Descriptions — MERGED (`23e38cf`).** Every `_table(...)` call across `board_page.py`, `cmod_page.py`,
  `firmwarefaults_page.py`, `hwnocode_page.py`, `pcb_page.py` now carries a generic `DisplayItem.description` (one-line
  purpose + "one row = …" + a columns note), pulling from each class's `plain_words` docstring attribute where
  present; `board_page.py` additionally gained a derived device-readiness split (usable / partial / tracked).
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
- **Proof (descriptions half, met):** every page in §1's table lists its tables with real descriptions (grepped, 0
  empty). **Proof (SVG half, owed):** the ecc83-pp demo's schematic + 2-layer layout render inline with a working
  layer selector and the 2 DRC warnings marked on the drawing at their x_mm/y_mm; the UNO pin map SVG matches
  `boards-pins` row-for-row (every canonical name on the drawing, no extras, no omissions).

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

### §3a. Target definitions and capabilities (inside demo-4's scope — his ruling 2026-10-04, §4)

**Why it is here, not in demo-2.** His ruling: targets get defined on no-code components FIRST, independently;
tying them to board components is a LATER step. demo-4 declares targets on C-no-code nodes with no board in the
loop; demo-2 (later) is the first thing that BINDS a declared target to a drawn board component. Built once, read
by both.

**New rows (module `hwnocode`, beside `HardwareNodePlacement` — file-per-class, cited not duplicated):**
- **`TargetDefinition`** — one per `CPort` (or glue-owned `CGraphNode` field) that is a point of physical control;
  not every port gets one (a pure math port, e.g. a moving-average's window size, never does). Fields: `port`/
  `node_field`, `kind` (register | pin | peripheral | memory-field | bus | dynamic — resolved at placement, e.g.
  "whichever ADC channel this instance is wired to"), `controls` (plain words — "ambient temperature, read-only"),
  `lives_at` (where it lives TODAY, D-demo-5), `width`/`direction`/`rate` (mirroring `CPort.width_bytes`/`direction`,
  never restated), `provenance` (declared-in-annotation | derived-from-parse | set-in-canvas).
- **`CapabilityDefinition`** — a `CGraph` (or a named subset) + its ordered, still-UNBOUND `TargetDefinition`s + the
  struct/class fields it exposes. Example: "temperature sensor solution" = the TMP36 `hal_adc_read` atom + a
  moving-average node + one target {kind: pin, controls: "ADC input"} + the exposed field `temp_c`.
- **`CapabilityInstance`** — one placement of a `CapabilityDefinition`, N per definition, each with its own target
  bindings (two sensors = two instances, each binding its `pin` target to a different `BoardPin`).

**Reused, not reinvented:** `CFunctionAtom.registers`/`resources_summary` (the `uses(...)` annotation clause,
`C_MODULARIZATION_PLAN.md` §4) is the DERIVED, atom-wide, read-only guess; `TargetDefinition` is the bindable,
port-level counterpart read beside it, not a replacement. `CPort` is the port shape it rides beside (zero or one per
port). `HardwareInterfaceBinding.instance_index` (grpc-j4) is the EXISTING dense-N-instances machinery —
`CapabilityInstance` reuses that pattern rather than a second index scheme, and where a target crosses the bridge,
the `HardwareInterfaceBinding` row IS its `lives_at`. `EnumMapping` is reused for any exposed enum field, not a new
table. The hwsim-nocode design's original `FieldRegisterBinding` (absorbed into `HARDWARE_NOCODE_PLAN.md` §1a as
the cmod edge kind `field-register`, owed, not yet built) is exactly a register-kind target — `lives_at` naming a
register is that same destination as a declarable ROW, not a parallel class. `HardwareNodePlacement` (WHERE a node
RUNS) is a different axis from WHAT it controls; `TargetDefinition` is additive beside it. **Genuinely new: the
three rows above, nothing else.**

**Scope split (his words):** "do the[m] independently with C no-code first… drag in that capability on our board
sim-space no-code view, and tie required targets to where they belong."
- **demo-4:** targets DECLARED and shown on canvas nodes (kind/controls/`lives_at`, `unbound` allowed); a
  `CapabilityDefinition` saves and reuses with no board involved.
- **demo-2 (later):** the board view gains "drag a capability onto the drawing" — dropping it on a `BoardPin`
  creates a `CapabilityInstance` and binds each target's `lives_at`; a second drop elsewhere makes a second
  instance with its own index (two sensors, one `CapabilityDefinition`).

### demo-5 (per the dlv plan — reference, do not re-plan) — the ladder below the board, then semantic zoom

RTL/netlist/cells/layout renderers and the semantic-zoom composition are entirely `DESIGN_LEVEL_VIEWS_PLAN.md`'s
slices dlv-0 through dlv-6. This plan's only addition: demo-2's `board` renderer and demo-3's `trace` renderer are
written as `level-view` renderers (§3 above) SO THAT dlv-6's semantic zoom can, eventually, compose a board drawing
and a netlist drawing on the same canvas if a `DesignNode` ever ties a board pin to a netlist pin (not scoped here —
noted so the two plans' components do not diverge).

## §4. Order, browser-pass checklist, costs, licences

**Order — REORDERED by his ruling 2026-10-04 (quoted verbatim):**

> "C graph in the no code canvas first, since we want to be able to tie pieces of the no code states into the 2D sim
> spaces later so we can see side by side how the no-code corresponds to hardware…. For now just focus on doing the
> [them] independently with C no-code first. For the sim space later, we need to define no-code components with
> valid target definitions (what is this trying to control, what registers is it living on, or is it dynamic,
> etc). Then based on those target definitions we should later on see the relation between and be able to tie them
> to specific components on a board. Like in the no-code we may say 'assign to 1 specific register this part of a
> struct, which we will use to track temperature from a sensor'. Then we generalize that along with it's code as
> 'temperature sensor solution' and we can drag in that capability on our board sim-space no-code view, and tie
> required targets to where they belong and be able to define multiple temperature sensors."

**demo-4 → demo-2 → demo-3 → demo-5.** demo-4 (C in the canvas, now carrying §3a's target definitions and
capabilities) moves first and stands alone: it needs no board, no twin, no live hardware, and it is the piece every
later tie-in depends on — a capability cannot be dragged onto a board drawing (demo-2) before it exists as a
declared, nameable thing with unbound targets. demo-2 follows second (the board sim-space is where a capability's
targets first get BOUND to real pins — §3a's second half). demo-3 stays third (independent of both; pure replay from
rows already on dev). demo-5 last, unchanged (rides the dlv plan's own ladder).

**Browser-pass checklist (one line each, added to `AI-Notes/guides/HARDWARE_ARC_TEST_GUIDE.md`, not duplicated
here; order matches the build order above):**
- demo-1: every table on the five pages shows a description tooltip/caption (MET, `23e38cf`); the PCB layout SVG
  renders inline with a working layer dropdown and the 2 DRC warnings marked on it; the UNO pin map SVG is visible
  on `/display/boards` (both still owed).
- demo-4: `/display/c-atoms` opens `uno-sim-rig-graph` on the canvas with real ports and badges; every node shows
  its target definition (kind/controls/`lives_at`, `unbound` allowed); the "used by" table lists `uno-temp-split`;
  `/display/hardware-solutions` shows a live temperature chart during a twin run; a `CapabilityDefinition` can be
  saved with no board attached.
- demo-2: `/display/firmware-installer` shows the board drawing above the install flow; dragging a saved capability
  onto a drawn pin creates a `CapabilityInstance` and binds its targets; two drops of the same capability give two
  distinct instances; moving the ADC slider moves the drawing; pause freezes it; with no twin running the page still
  shows a replayed drawing, not a blank panel.
- demo-3: `/display/firmware-faults` shows a BEFORE/AFTER trace pair above the tables; the cursor steps one
  instruction at a time; the claim badge matches the row's outcome.

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

## §5. Decisions for him (D-demo-1..5)

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

- **D-demo-5 a target's "where it lives" (`TargetDefinition.lives_at`): a reference to the board object's
  `BoardPin`/register rows, or a free string?**
  **Recommendation: a reference, not a free string.** For `kind=pin`, `lives_at` names a `BoardPin.name`
  (`board/objects/board/BoardPin.py` — the ONE row every view, KiCad/Zephyr/ESP-IDF/bare-C/Polari, already reads);
  for `kind=register`, it names the register from the avr-libc register snapshot cmod-0 already committed (96
  registers + 25 vectors, cited by sha) or the generator rows that own a register map (`hwfpga`
  `RegisterMapDefinition`/`RegisterDefinition`) where one exists. A free string is allowed ONLY for `kind=dynamic`
  (genuinely unresolved until placement) or `unbound` — never as a substitute for a reference that could be made.
  Reasoning: demo-2's board drawing must resolve a binding to literal geometry without re-parsing text, and a
  reference lets a pin rename be caught as model drift the same way `BoardConflict` already catches every other
  view's disagreement with the board's own rows (brd-bo's existing pattern) — a free string would silently rot.

---

Not in scope: VHDL/C++/Rust/MicroPython on devices (RULE 2, unchanged); editing a CGraph's generated C from the
canvas (cmod's hand-edit guard stays a file-level boundary); the dlv ladder's RTL/netlist/cell/layout renderers
(dlv's own slices, not re-planned here); a second chart engine (sci-xy-chart stays THE chart home); 3D views beyond
the existing click-to-detail precedent (his ruling, unchanged).


## 8. Addendum 2026-10-04 late — runtimes (his ruling) and what landed after the plan was written
His words on seeing /display/c-canvas: "what is a hardware-subgraph? Also, the no-code solution seems to just be a single state, C (Hardware),
along with Java/JavaFx (Native Bridge Backend and Frontend), these should be their own runtimes." Ruling: RUNTIMES are first-class rows
(python-backend | typescript-browser | c-device | c-twin | java-bridge | javafx-native); every no-code node is placed into one (derived from
hwnocode's placement rule); the canvas shows runtime lanes, cross-lane edges are the interfaces; a C graph's atoms are real nodes in the
c-device lane; `HardwareSubgraph` (hn-0) survives only as the collapsed view of the C graph inside a mixed solution.
Landed on dev the same night: demo-1 (descriptions, readiness split), demo-1b (api-svg-panel: schematic/layer SVGs + markers, the pin map
from BoardPin rows for every modelled board, pin-roles table), demo-4 (c-graph-canvas-panel, TargetDefinition, CapabilityDefinition ×2
instances, used_by), loopfix (the reload storm: unsaved local solutions survive initializeFromBackend; display-page reloads only on a real
param change), demo-4b (Runtime rows, lanes/legend/crossings, atoms as real nodes, uno-temp-split first). Leftovers are in the handoff TODO §3.

## §9. Firmware Solution + Cross-Domain Solution (proposal, 2026-10-05)

His quote, on uno-temp-split after the uno-digital-twin rename landed:

> "rather than just calling it twin which is confusing, call it uno-digital-twin so it is clear. Also, we will need
> a configuration based conditional and statement so that it goes the digital twin route when the configuration is
> in one mode, and [hardware] route in the other case. Also it is not clear what the backend state change is for,
> it seems like it is receiving temperature through the bridge from the Digital Twin? Also not sure what the
> analysis call is. This seems to more so be a Cross-Domain Solution (Likely something that should be its own
> category that specifically uses different kinds of bridging and api calls and relay specifications only). And
> then the code defining what is happening specifically just in the Firmware itself (C only) should be in its own
> solution). And maybe it is the case that our current formatting and approach does not make sense for C no-code?
> … What I want to be able to do is define tasks (I think that is atoms) and then define register assignments, and
> what the solution does is take in a Board Definition and puts out a finished firmware to be flashed or simulated
> (digital twin). Maybe call it a Firmware Solution? And then we will want a state that takes a Firmware solution
> based on a C runtime, and accepts a board definition that may be either passed as a variable or set from known
> board solutions and validated when running that it still exists. The connectors also seem to not be set up
> properly on the new uno-twin solution in the way it is in other solutions, or it may be the new states that do
> not handle it properly."

(The connector and rename complaints are FIXED, separately, 2026-10-05 — see the hn-0 selftest / the renamed state.
This §9 is the proposal for the bigger restructuring his message asks for: today's single mixed canvas splits into
three solution KINDS.)

**(1) Firmware Solution** — a new HardwareSolution variant whose runtime is `c-device` | `c-digital-twin` (not the
mixed board/bridge/backend canvas hn-0 draws today). Its canvas is not a free graph but THREE PARTS:
  - a **TASK LIST**: the atoms (his "tasks (I think that is atoms)") with their ports and resources — what cmod
    already calls a c-atom, listed, not scattered across a free-form canvas;
  - a **SCHEDULE LANE**: tick ISR / main loop / interrupts, ordered, with measured cycles beside each (cmod-0's
    already-measured per-atom cycle counts feed this directly — no new measurement);
  - a **REGISTER MAP** bound to the board's pin map: dragging a task's target onto a pin/register sets
    `TargetDefinition.lives_on` to that `BoardPin` (demo's own D-demo-5 ruling: a reference, never a free string).

  Input: a `BoardDefinition` — passed as a variable, or picked from the known/usable boards (`/display/boards`'s own
  readiness rows) and VALIDATED AT RUN TIME that it still exists (his words exactly) — a stale pick refuses loud,
  named, the same posture as `knobs.check_runtime()`. Output: a `FirmwareBuild` (the existing class: .hex + the
  repro block cmod-glue already produces) → flashed (`board.custom.installer`) or run in the digital twin
  (`board.custom.twin`). Edges inside it are struct fields or triggers only (never a device↔backend crossing — there
  is no backend here). `cmod-glue` still generates the C project; nothing about its C output changes.

**(2) Cross-Domain Solution** — a new SOLUTION CATEGORY (his words: "its own category that specifically uses
different kinds of bridging and api calls and relay specifications only") whose states are ONLY bridging/relay,
never compute:
  - **Firmware Run** — takes a Firmware Solution + a board (or digital twin) + the mode; this is the ONE place the
    HARDWARE_MODE knob is read (today's `hwnocode.custom.solutions._hardware_route()`, moved here) and reports
    which route it took (unchanged behavior, new home);
  - **Bridge** — the serial/gRPC attach (today's HardwareInterface/HardwareInterfaceBinding, unchanged rows);
  - **Relay** — frame → a backend event; a command → back down (today's BackendStateChange on the way up,
    StateChangeCommit on the way down);
  - **API call** / **Frontend emit** — the existing engine node kinds, unchanged.
  Arithmetic (his "backend state change... analysis call" confusion) never lives here — a Relay state calls OUT to
  a backend solution; it does not compute inline.

**(3) Migration of `uno-temp-split`** (no behavior change, re-filed):
  - the firmware half (`sim-rig`) → a new Firmware Solution `uno-sim-rig` (task list = the sim-rig CGraph's 18
    atoms, unchanged; schedule lane = their existing stage/order fields; register map = TMP36 on A0, LED on D13);
  - the relay half (`uno-digital-twin`/`on-temp`/`commit`) → the Cross-Domain Solution `uno-temp-split`, states
    Firmware Run → Bridge → Relay (up) / Relay → Bridge (down);
  - the analysis (`moving-avg`/`over?`/`flag-on`/`flag-off`) → a backend solution `temp-analysis`, called BY the
    Relay state (his "this seems to more so be a Cross-Domain Solution" read literally: the split moves, nothing
    about the moving-average math changes).

**Slices** (D-fs-1..3 his, below, gate the order): **fs-0** the Firmware Solution model + rows + the BoardDefinition
input's run-time validation; **fs-1** the three-part canvas formatting (task list / schedule lane / register map);
**fs-2** the Cross-Domain category + the Firmware Run state + the HARDWARE_MODE knob's new home; **fs-3** the
migration itself (uno-sim-rig / uno-temp-split / temp-analysis) + the firmware installer switched to read Firmware
Solutions instead of FirmwareBuild rows directly.

**Decisions (his, D-fs-1..3):**
- **D-fs-1** — is the SCHEDULE LANE *derived* from each atom's existing ISR/tick annotation (cmod's own
  `stage`/`order` fields, read-only, same posture as demo-4's "placement is derived, never typed in"), or
  *authored* by dragging atoms into lanes on the canvas (and cmod-glue reads THAT as the source of truth instead)?
- **D-fs-2** — does register assignment happen ON the pin map (drag-a-task-onto-a-BoardPin, demo-5's `lives_on`
  reference) or in a bound TABLE (a configured `class-rows-table` over `TargetDefinition`, no new canvas
  interaction)? Both resolve to the same reference; this is a UI-effort choice, not a data-model one.
- **D-fs-3** — may a Cross-Domain Solution contain ANY compute at all (e.g. a trivial unit conversion on a relayed
  field), or is it bridging/relay ONLY, full stop, with even a one-line conversion required to live in a backend
  solution the Relay state calls? His message says "relay specifications only" — this decision is whether that is
  read as absolute or as "no business logic," which changes how strict fs-2's Relay state's refusal rule is.

**RULED 2026-10-05 (his: "go with your picks on the decisions"):** §9 ratified. D-fs-1 = the schedule lane is DERIVED from the atoms'
ISR/tick/loop annotations, never authored. D-fs-2 = register assignment by dragging a task's target onto the PIN MAP (TargetDefinition.lives_on
→ BoardPin). D-fs-3 = a Cross-Domain Solution contains NO compute — bridging/relay states only, validated. fs-0 building on `dev-fs-0`
(rows FirmwareSolution / ScheduleSlot / RegisterAssignment / the Firmware Run state kind in a Cross-Domain palette category; derivations +
validation; `/api/firmware`, `pol firmware`, /display/firmware-solutions; migration seeds uno-sim-rig + uno-temp-split (cross-domain) +
temp-analysis). fs-1 = the three-part canvas formatting (task list · schedule lane · register map with the drag).

### fs-2 — targets, registered tasks, compatibility (his ask 2026-10-06, go: "okay sounds good")
His words: "we need to know compatibility between targets and registers as well, we should have a fourth section that gives the
details about the targets. Also the views are too small even on a full computer screen … collapse and expand sections … a clear
indicator of when we click on a target what ones are valid targets. The pins are the targets … call them 'Unregistered Tasks' whereas
we should also be able to click on pins and see the 'Registered Tasks' and an expanded detail view of the register and info about it."
Vocabulary: TARGETS = the pins (+ the register bits behind them); tasks needing a pin = UNREGISTERED TASKS; bound = REGISTERED TASKS of
a pin. Compatibility DERIVED: task target kind (analog-in, pwm-out, uart-rx/tx, i2c, spi, digital-in/out, interrupt-in) × pin roles,
a CITED table in the BOARD module (`target_compat.py`, `TargetCompatibilityRule` rows; ATmega328P datasheet facts; `undetermined` when a
fact is missing; power/ground never assignable). Four COLLAPSIBLE sections (Unregistered Tasks · Schedule lanes · Pin map · Target
details) with presets (all / one maximised / two side by side), layout remembered per viewer. Click a task → valid pins light, invalid
grey with a reason; click a pin → its Registered Tasks + register detail (port/bit, DDR/PIN, alt functions, timer/ADC channel, limits,
each cited). Invalid drop REFUSED; the conflict guard uses the backend's cooperation rule.
- fs-2a (backend): `target_compat.py` + rows; `GET /api/board/<b>/pins/<pin>` (register detail + registered_tasks); `GET
  /api/firmware/solutions/<n>/tasks/<t>/valid-targets`; solution payload gains unregistered_tasks + per-pin registered_tasks; `/assign`
  refuses invalid/conflicting. Tests: ADC → A0–A5 exactly; PWM → D3 D5 D6 D9 D10 D11; UART → D0/D1; power never.
- fs-2b (frontend): the four collapsible sections + presets, the renames, highlight/grey-out with reasons, the Target details section,
  the stricter drop. Spec on real fixtures; his browser pass.
