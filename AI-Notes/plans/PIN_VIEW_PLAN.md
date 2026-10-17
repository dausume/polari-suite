# The pin view: a d3 visualization of boards, chips, enclosures and their pins (pv arc) — plan 2026-10-17

✅ GO 2026-10-17 ("Go ahead and start revising work"). D-pv-1..7 as recommended ("that sounds good"); D-pv-7 applied (framework 3b6608a). Builds on hsp-0/1 (`HARDWARE_SYSTEM_PINS_PLAN.md`: enclosures, exposure maps, the availability ladder, Hardware
Systems, links, signal paths) and feeds the solution search (`MISSION_PROFILE_SOLVER_PLAN.md`).

## 0. His words (2026-10-17)

"We want to re-work the pin visualization and configuration to leverage a visualization that makes it more intuitive how boards and chips and
enclosures have pins and enclosures that limit one another and interconnect. We need symbols for things and colors for things that get
configured to particular protocols. Then we need to be able to filter for pins compatible to particular protocols or protocol sets (like SPI and
its child protocols that compose it). We want to be able to click on the chips and be able to see what pins it has and their capabilities and
what is being consumed where and by who (a board, the chip enclosure, etc). And we want the ability to dim and change colors according to
different selections, and to be able to see pins that do not have something assigned by the no-code yet. Instead of just a bunch of cards we
want a dedicated d3 visualization with math defined shapes for the chips and boards, with a focus on the pins. Not necessarily on the wires that
interconnect them but being able to select the pins and see what connects to them and what the different pins connected are doing for each
other by being connected across different levels and in terms of drive conditions and protocol signals, if they are being used or not by a task
and by what tasks for what purpose, etc.

A blank version that is the initial state of a chip or board before it is flashed with firmware should also exist, and it should be specified
when board and pin states are being altered by a connection to a new configuration"

**Standing-rule note:** the default rule is "no new custom components; every panel is a configured Table/Graph definition". His words here ask
for ONE dedicated d3 visualization — recorded as his explicit exception for this view. Its side panels stay configured tables (no raw JSON).

## 1. What exists to build on

| piece | where |
|---|---|
| d3 7.8 + shape painters + a 2-D renderer | Angular `services/sim-space-2d/{d3-renderer.service, d3-shape-painters, d3-axes}.ts`; d3 layers in no-code (`models/noCode/d3-extensions/`); `cell-schematic.component.ts` |
| math-defined shapes as rows | `MathShapeDefinition` / `ShapeNDDefinition` (shapes module; already seeded for FET parts and sim spaces) |
| pin roles + colours (server SVG) | `board/custom/pin_roles.py` (role vocabulary), `board/custom/pinmap_svg.py` (`ROLE_COLORS`: pwm, adc, uart, i2c, spi, led, power, ground, button, gpio) |
| pins at every level + what lies between | SocPin, PackageContact, BoardPin, ConnectorPin, EnclosureContact (via + part + consumer), BoardPinNet, SystemLink |
| capabilities + protocols | PinFunction → PeripheralSignal → Peripheral (80 functions, 83 signals, 18 peripherals on the 328P; the 16U2's functions) |
| who uses a pin | cmod PinClaim / PeripheralClaim / SignalRoute per binding; tasks (graph nodes) → Purposes (CapabilityDefinition tasks) |
| availability | the ladder (`board/custom/ladder.py`), reachability |
| reset values + phases | Register/RegisterField `reset_value`; PinLifecycleConstraint phases (power-up, reset, bootloader, init, runtime, programming, debug) |
| real-world events | InstallRecord (a flash), BoardInstance (`firmware_sha`, variants), BoardPinNet provenance (a wiring) |

## 2. The design

### 2.1 Shapes, math-defined
- **Packages** as parametric shapes: body width × height, pin count, pitch, rows or sides → DIP (two rows), SOIC, TQFP and QFN (four sides,
  plus the exposed pad). Pin positions are COMPUTED from the parameters, never hand-placed. Dimensions cited from each package drawing
  (28-SPDIP, 32-TQFP, the 16U2's 32M1-A QFN) or labelled as a drawing knob when only proportions matter.
- **Boards** as an outline polygon + placed footprints (the chips, the headers, the USB connector) + header pin rows at pitch. UNO outline and
  header positions cited from Arduino's published drawing; anything uncited is a labelled layout knob.
- **Enclosure levels nest visually:** the die (inner pads, undetermined today) inside the package, the package on the board, a shield (E3)
  over the board later. Each shape is a `MathShapeDefinition` row (one source for the view and later for the PCB/enclosure work).

### 2.2 Encodings
- **Colour = protocol family**, as theme tokens (styling rule: tokenized by property, each `--pin-<family>` paired with a text colour):
  gpio, interrupt, pwm/timer, analog, uart, spi, i2c, usb, clock, reset/programming, power, ground. Reuses the `ROLE_COLORS` vocabulary.
- **Symbol = what the pin is doing:** output (drive arrow), input (sense arrow), bidirectional, analog (~), clock, reset, power, ground,
  reserved (lock: a lifecycle reservation), internal-only (dotted ring: consumed on the board), not-bonded (×).
- **Fill = assignment:** solid = assigned by the no-code (a claim of the selected binding); hollow ring = nothing assigned yet; hatched =
  assigned but blocked or undetermined on the ladder.
- **Dim** everything outside the current selection or filter.

### 2.3 Interactions
- **Click a chip, board or enclosure** → it highlights; a side panel (configured tables) lists its pins, each pin's capabilities, and what is
  consumed where and by whom: the board (an onboard part on the line), the enclosure (not bonded, internal), a task (its claim), a Purpose.
- **Click a pin** → every pin connected to it across levels lights up (die pad ↔ package leg ↔ board trace ↔ header ↔ bench net ↔ the other
  chip), with what each does for the other: who drives and who senses, the drive conditions (level, current, pull from ElectricalCharacteristic),
  the protocol signal it carries, and the task and Purpose using it. Wires are not drawn as the focus; the connected pins are.
- **Filter by protocol or protocol set:** a set expands to its child signals (SPI → SCK, MOSI, MISO, SS; I²C → SDA, SCL; UART → RX, TX; USB →
  D+, D−). Pins able to carry the set are coloured; the rest dim. "Able" = the ladder's verdict for that kind in the current context, so a
  reserved or unexposed pin shows why.
- **Show unassigned:** highlight every pin the no-code has not assigned yet.
- The click-toggle rule holds everywhere: a second click deselects, Escape clears. Layout uses container queries (mesh is not a width).

### 2.4 Blank state and configuration changes
- **Blank** has two baselines, both cited or undetermined:
  - **chip blank** — the silicon after reset with no program: every I/O pin an input, tri-stated, pull-ups off (the datasheet's reset
    behaviour); every register at its cited `reset_value`.
  - **board as delivered** — the board before any of OUR firmware: the bootloader present (D0/D1 serve it, RESET answers DTR), the onboard
    parts on their lines. Whether a factory demo sketch is present is `undetermined` unless cited.
- **States the view can show:** blank → after reset → bootloader → init → runtime (with a chosen binding's configuration: its
  RegisterFieldSettings and SignalRoutes). The phases are the lifecycle phases already in the rows; after every reset the pins return to the
  blank state until init runs, and the view shows that.
- **Configuration events say when pin states change and why:** flashing a firmware (InstallRecord), connecting or removing a circuit (a
  BoardPinNet added or removed), attaching a shield, choosing another binding. Proposal: a small `ConfigurationEvent` row for real-world events
  (what changed, which pins, cause, who/when), while the per-phase pin states stay DERIVED. The view has a phase selector and an event
  timeline; selecting an event shows the pins it changed.

### 2.6 His layout sketch (2026-10-17, graph paper; transcribed, photo not committed)

What the sketch shows, outermost first:
- **The board** as a large outline, with **board pins** around its edges (and edge-connector pins just outside the outline).
- Inside the board, **the SoC enclosure** (the package) as a square with **SoC enclosure pins** on its outer edge.
- Inside the enclosure, **the SoC** (the die) as a smaller square ringed by **SoC pins** (the inner pads). Lines run from SoC pins out through the
  enclosure to the enclosure pins: the bond from pad to leg.
- Below the SoC, **two other parts on the board** ("Peripheral One", "Peripheral Two"), each a box with its own pins.
- **Peripheral One is selected, so its connections show:** its pins are drawn joined to SoC enclosure pins above it and to board pins at the
  left and bottom edges ("Peripheral to Board Connections"). Peripheral Two is not selected, so it shows no connections.

What this changes in the design:
- **Layout = concentric nesting:** die inside package inside board, each level with its own ring of pins on its own edge. Pins are placed on
  each shape's perimeter by the math-defined shape (2.1).
- **Connection lines appear only for the selection** (a chip, a part, a pin): nothing is wired by default, so the pins stay the focus (2.3).
- **Other parts on the board are first-class shapes with pins:** on the UNO they are U2 (the ATmega16U2, itself a die inside a QFN), the LMV358
  buffer (U5B), the 16 MHz part, the L LED, the series resistor networks (RN4A/B), C5, the USB connector, the ICSP headers. Selecting U2 would
  draw its lines to the 328P's D0/D1 legs (through RN4A/RN4B 1 kΩ), to RESET (through C5 from DTR), to the USB connector and to its ICSP header.
- **Terminology flag:** the sketch calls these parts "Peripheral". In the model, `Peripheral` already means a block INSIDE the chip (TIMER0,
  USART0); a part on the board is a `BoardComponent` (or a schematic part). Proposal: the view labels them "board parts" (or by their role:
  "USB bridge", "LED buffer"), and keeps "peripheral" for the on-chip blocks shown when a SoC is opened. D-pv-6 his.

### 2.7 Click surfaces and the connection ladder (his words 2026-10-17)

"We will also want to be able to click on individual peripherals and individual SoCs and enclosures and Boards, all are valid click surfaces.
Clicking on them should yield a view and render visualizations for what kinds of connections they have. These should specifically be pin to pin
connections only and disregard the electrical details, as those will have their own view, we will simply have that abstracted into drive
information that can be viewed by clicking on the connection, the connection should be clickable after clicking on a pin to see what it is
connected to."

Supersedes the electrical detail in 2.3's pin click. The interaction is a three-step ladder:
1. **Click any surface** — a board part, a SoC (die), an enclosure (package), a board. Its view renders its **pin-to-pin connections only**,
   grouped by kind (to another chip, to a board part, to a header, to the bench, pad to leg). No electrical numbers.
2. **Click a pin** → its connections are drawn and become clickable.
3. **Click a connection** → the **drive information**, abstracted: which end drives and which senses (or both), the protocol signal it carries,
   whether a task uses it and for which Purpose, and what sits in the path as a named kind only ("through a series resistor", "through a
   buffer"). A link opens the separate **electrical view** (levels, currents, limits, the electrical rule verdicts), which is out of this view.
Every surface and connection obeys the click-toggle rule. The data door (2.5) returns connections as pin-to-pin pairs with a `drive` summary;
electrical values are served only by the electrical view's own door.

### 2.8 Correction — "drive" is electricity, not signal direction (his words 2026-10-17)

"drive means electricity flow and supply, signals are different, please recall the way we were organizing pin data before for organizing if
the pin, chip, or peripheral meet valid electronics constraints."

2.7 wrongly put "which end drives and which senses, the protocol signal" under drive. The vocabulary already agreed (R2 §2.5 and §7, the HAL
families in FIRMWARE_GENERATION_MODULE_PLAN §5b/§7.3, built in fgm-2):

| term | means | where it lives today |
|---|---|---|
| **Documented capability → Available potential → Proposed resource claim → Committed configuration** | the four stages of a resource | PinFunction (documented) → the ladder (available, computed) → PinClaim (proposed/committed) → RegisterSetting (committed) |
| **SignalPotential** | the signals a resource can generate or receive: digital I/O, UART, SPI, PWM, analog input, interrupt; direction, timing, voltage-domain compatibility, modes, protocol constraints | PinFunction + PeripheralSignal (+ Peripheral) |
| **DrivePotential** | the electrical driver: output-high/low voltage at a stated current, source and sink current, drive strength, open-drain behaviour, shared output-current limits, supply domain — never an independent budget per pin | ElectricalCharacteristic per pad class (not per pin) + PinGroupBudget (shared limits) |
| **InputElectricalConstraint** | input voltage range, logic thresholds (VIL/VIH), leakage, capacitance, internal pull-up/down, analog restrictions, clamp current, powered vs unpowered | ElectricalCharacteristic input rows |
| **PinElectricalLimit** | the class of every limit: absolute maximum · recommended operating · guaranteed · typical · conditional; absolute maximum is never a design target | `limit_class` on ElectricalCharacteristic; rule (i) |
| HAL families | **drive** (all electric charging and powering: digital drive push-pull/open-drain, PWM drive, analog out, supply rail, pull, load, charge) · **signal** (digital in, edge interrupt, analog in, analog reference, comparator in, clock in) · **protocol** (UART, I²C, SPI, wire packet, timing) · **register** · **execution** | §7.3; resolver input in fgm-4 |
| the checks | does the pin / chip / part meet valid electronics constraints | electrical rules (a)–(e) `electrical_check.py`, (f)–(j) `electrical_hw.py`, lifecycle rows, the ladder rung 7 |

**2.7's connection panel, corrected — three separate sections:**
- **Drive** (DrivePotential, abstracted): which end SUPPLIES or SOURCES current and which SINKS it or is supplied, the supply domain or rail, the
  pull, and the verdict class of the relevant limit (within recommended · undetermined · over) — no numbers; the numbers are the electrical view's.
- **Signal** (SignalPotential): which end outputs and which inputs the signal, the protocol signal it carries (e.g. USART0 TXD → 16U2 RXD1),
  its family (UART) for the colour.
- **Use**: the tasks that claim it and the Purposes they serve (documented / available / proposed / committed stage).

**Vocabulary debt found:** `BoardPinNet.role` uses `driver` / `input` to mean SIGNAL direction on a net (ucd-0c, and the hsp-1 path text "D6 drives
net LED_CONTROL"). Under this vocabulary that is the signal side. Proposal: rename the role values to `output` / `input` (signal) and keep "drive"
for current and supply — D-pv-7 his; nothing renamed until he rules.

### 2.9 His go + two additions (2026-10-17)

His words: "Go ahead and start revising work, we need views specific to data on the pins, connections, etc for that visualization as well" and
"and the ability for it to be used with base composition of components before any inits occur, as well as after inits and tasks start getting
assigned via Task definitions on a Mission, and it starts to be altered via the firmware by assignments of pins to different responsibilities."

**Data views (configured pages, no raw JSON) beside the d3 view**, each a DisplayDefinition reading the same `pin-view` door family:
- **Pins** — every pin at every level (SoC pad, package leg, board pin, board-part pin): level, owner, capabilities (signal families), drive
  class (pad class), assignment stage, consumers.
- **Connections** — every pin-to-pin connection: the two ends, kind (pad-to-leg, on-board, chip-to-chip, to a board part, to the bench), via kind,
  and the three summaries (Drive / Signal / Use).
- **Surfaces** — boards, enclosures, SoCs, board parts: pin counts by stage (unassigned / available / proposed / committed).
- **Configuration events** (pv-4).
The d3 view and these tables select together (a row click selects the same pin or connection in the view).

**Composition stages the view (and the tables) can be set to** — extends §2.4's phases with the Mission side:
| stage | what defines the pins |
|---|---|
| **base composition** | the parts as composed (chips in packages on a board, board parts, bench circuit) before any init: chip blank / board as delivered; only electrical connectivity and documented capability |
| **after init** | the Initialization Purpose's configuration applied (the init tasks' register settings) |
| **tasks assigned** | Task definitions on a Mission have proposed claims: pins carry proposed responsibilities (stage "proposed") |
| **firmware committed** | a firmware binding's committed configuration: pins assigned to responsibilities by the firmware (stage "committed"), each change a ConfigurationEvent with its cause |
The same `stage` parameter drives the d3 view, the tables and the solution search's candidates (§ MISSION_PROFILE_SOLVER_PLAN sol-0 draws here).
Until fgm-3 Tasks exist, "tasks assigned" reads today's graph-node claims (PinClaim of a binding) and says so.

### 2.5 Data door (one composed read)
`GET /api/board/{board}/pin-view?system=&binding=&mission=&stage=&phase=&protocol=` (+ `/pins`, `/connections`, `/surfaces` row views for the tables) → shapes (from the shape rows), pins per level with positions, crossings,
capabilities by protocol family, consumers, ladder verdicts for the filter, the phase's pin states, and events. One read per view change; the
component sends names only.

## 3. Slices (each its own branch, proven on the econ-core test node, then a screenshot pass past the demo-terms dialog)
| # | slice | builds |
|---|---|---|
| pv-0 | backend | package + board shapes as MathShapeDefinition rows (computed pins, cited dimensions), protocol-family tokens, the `pin-view` door |
| pv-1 | the d3 component | shapes + pins + colour/symbol/fill encodings + chip/board click panel; mounted on the board page and the Hardware home |
| pv-2 | pin selection | connected pins across levels with drive conditions, protocol signals, tasks and Purposes |
| pv-3 | filters | protocol and protocol-set filters (ladder-backed), show-unassigned, dimming |
| pv-4 | states | blank (chip / board) + phases + `ConfigurationEvent` + the event timeline |
The existing card views stay until pv-1..3 cover them, then the board page leads with the pin view.

## 4. Decisions (his; my recommendation first)
- **D-pv-1** one new d3 component `hardware-pin-view` (his exception to the no-new-components rule), mounted on the board page and the Hardware home.
- **D-pv-2** colours per protocol family as theme tokens, reusing the existing role vocabulary.
- **D-pv-3** blank = two baselines (chip blank, board as delivered).
- **D-pv-4** `ConfigurationEvent` rows for real-world events; per-phase pin states derived.
- **D-pv-6** what to call the parts on a board in the view ("board parts" / role names recommended; "peripheral" stays for on-chip blocks).
- **D-pv-7** rename `BoardPinNet.role` driver → output (signal direction), keeping "drive" for current and supply (recommended).
- **D-pv-5** order: pv-0 alongside the msp register profile (rp-0), then pv-1..4; the solution search (sol-0) later draws its candidates in this view.

## 5. ✅ pv-0 BUILT + MERGED 2026-10-17 (framework cda34f9..183e92f; cli `pol board pin-view`; sonnet agent + my review)
- 23 MathShapeDefinition rows (3 packages, 2 dies, the UNO board, 14 board parts, 3 bench parts); pins computed by generators (`board/custom/pv_shapes.py`:
  two-row DIP/SOIC, quad QFP/QFN + exposed pad, die ring, part box, header rows). Cited: SPDIP pitch 2.54 / body 7.239 × 34.671 / rows 7.62 (DS40002061B
  p.644); TQFP pitch 0.80 / body 7.00 (p.636); QFN pitch 0.50 / body 5.00 / pad 3.10 (doc7799 p.295, 328P p.641–642; 16U2 pad = partial); UNO bbox
  66.04 × 50.80 + holes (A000066 p.12). Drawing knobs (labelled): die squares + pad positions, header/footprint placements, part boxes, 4 family hexes.
- 12 signal families with `--pin-<family>` tokens; sets spi/i2c/uart/usb expand to child signals (`pv_families.py`).
- UNO base view: 22 surfaces, 186 pins (die 61, package 61, board 38, part 22, bench 4), 161 pin-to-pin connections (60 pad-to-leg, 56 to-header,
  18 to-board-part, 12 on-board, 12 to-bench, 3 chip-to-chip) + 14 `unresolved` crossings with reasons. Each connection: separate drive / signal / use.
- Stages: base (0 claims) · after-init (the Initialization Purpose's tasks; = tasks-assigned for uno-light, whose four claims are init tasks) ·
  tasks-assigned · firmware-committed (claims cited by generated RegisterFieldSetting/SignalRoute rows). `mission` = undetermined until fgm-3.
- Doors `GET /api/board/{b}/pin-view` + `/pin-view/{pins,connections,surfaces}`; pages pin-view-pins / -connections / -surfaces ("Pin data views"
  group on the Hardware home); SoC surfaces link to the register profile. board 646, cmod 698, hwnocode 163.
- Review fix (me): a header pin on a bench net takes that net's signal role (the jumper reads D6 outputs / D3 inputs), else it "passes".
- Follow-ups: (1) at stage base an unassigned line names the BoardPin's default role (D6 "pwm" → OC0A) — base should list capabilities, not pick
  one; (2) claims attach to the atom that configures a pin, so `use` shows the Initialization Purpose only (the toggle/report Purposes reach the pin
  through tasks, not claims) — fix with fgm-3 Tasks; (3) a stage read takes ~7 s (no cache).

## 6. ✅ pv-1 BUILT + MERGED 2026-10-17 (angular d6219b6, framework d1a4c35 + merge fd200e7; sonnet agent)
- `hardware-pin-view` (angular `components/dashboard/generic/pin-view/`: component + layout / encode / panel / draw / service / types modules), registered
  as a generic display component; page `/display/pin-view` first in "Pin data views". Tokens `--pin-<family>` + `-text` (12 families + other) in
  `_variables.css` / `_theme-dark.css`.
- Concentric die → package → board per his sketch; nothing wired by default; surface click draws only its connections; pin → connections clickable →
  Drive / Signal / Use sections; SoC → register profile link; stage selector + binding picker; protocol sets; show-unassigned; dimming; click-toggle +
  Escape. Spec 10/10, ng build + check:styles OK, board 648, apps 126.
- Deviations: dies drawn at ≤ 55 % of their package (the 16U2 die equals its body otherwise); the lock glyph only fires on "reserv" text (no lifecycle
  field in the payload yet — follow-up: add it to the pin payload); table-row ↔ view selection sync not yet; the board page (`/display/boards`) has no
  slot (dedicated page + nav only).
- My layout fix (framework 949b0d6): the parts grid overlapped U1 → moved to the free lower-left area; computed: no surface overlaps.
