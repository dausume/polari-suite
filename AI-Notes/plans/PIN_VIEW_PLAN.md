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


## 7. Drive view, signal view, filters (his words 2026-10-17) → slice pv-2

"We are also going to do a drive view where only pins relevant to drive and their status in relation to drive appear, and the symbols change to
revolve around drive and power flow rather than signals. We are also going to want to have a signals specific view, where we see only pins related to
signals and what is activated per pin in terms of protocols. We are going to also want filters we can apply to highlight pieces of logic we want to
narrow down to like identifying the pins relevant to I2C only, or pins relevant to SPI only and so on while some are highlighted when filtered others
are greyed out"

A **view mode** on the pin view: **All** (today) · **Drive** · **Signal**. Each mode shows only the pins relevant to it; the rest are hidden (not merely
dimmed), and the legend switches with the mode. Filters then highlight within the mode; what does not match is greyed out.

**Drive view** (DrivePotential — electricity: flow and supply, never signal direction):
- Pins shown: supply and ground pins and rails, every pin that can source or sink current (I/O pads), pins with a pull, pins feeding a load (the
  LED through R1), the USB VBUS / fuse path, the regulator-fed rails.
- Status per pin at the chosen stage: **supplies** (a rail source: VBUS, the 5 V / 3V3 pins) · **supplied** (VCC, AVCC) · **returns** (GND) ·
  **sources current** / **sinks current** (an output into a load; which one depends on the level, so a committed output shows "sources or sinks") ·
  **pulled up / pulled down** (internal pull enabled by the claim) · **high impedance** (an input: leakage only) · **not driven** (blank stage).
  Plus the limit verdict class (within recommended · undetermined · over) from the electrical rules, and the shared group budget it counts toward.
- Symbols for power flow: arrow out of the pin = sources current; arrow in = sinks; ⊕ supply, ⏚ return, a small resistor glyph = pull, a load glyph on
  the far end (LED, resistor), a fuse/inductor glyph on via-parts in the path; colour = rail/domain (5 V, 3.3 V, USB VBUS, ground) or limit class.
- Drive filters: by rail (5 V / 3.3 V / VBUS / ground), by status (sourcing, sinking, pulled, high-impedance), by limit class (show only
  undetermined / over), by group budget.

**Signal view** (SignalPotential):
- Pins shown: every pin that carries or can carry a signal (no supply or ground pins).
- Per pin: what is ACTIVATED at the chosen stage — the protocol function in use (e.g. D0 = USART0 RXD, D2 = INT0) — with the other capable
  functions listed greyed beside it; at stage base nothing is activated, so every pin shows its capabilities only (fixes pv-0 follow-up 1).
- Symbols: outputs / inputs / bidirectional / clock / analog, coloured by protocol family.
- Signal filters (exists for one protocol; extend): one protocol or a protocol SET (I²C → SDA/SCL; SPI → SCK/MOSI/MISO/SS; UART → RXD/TXD; USB → D+/D−;
  interrupt; PWM/timer; analog), several at once; "activated only" vs "capable"; matching pins highlighted, the rest greyed.

**Also in pv-2 (from my screenshot pass 2026-10-17):** label collisions (CSTCE16M0V53-R0 over ICSP1; "PB6 line" texts), unnamed small part boxes,
bench parts clipped at the right edge by the fit, the die label overlapping leg labels; the lifecycle reservation as a payload field (the lock glyph).
Data: the pin payload gains per-mode fields (`drive_status`, `rail`, `pull`, `limit_class`, `group_budget`; `activated` + `capable` functions) so the
component never re-derives a rule.
- **Live check on econ-core 2026-10-17** (after the rotation + header fixes): U1 lies along the board; the top header reads SCL/SDA … D8, D7 … D0; clicking
  the U2 package dims the rest and draws its 73 connections (to U1's D0/D1/RESET legs, the USB connector, its crystal Y1, its ICSP header, the test pads,
  the rails); the side panel lists its 33 pins with capabilities, stage and consumer. Readability findings handed to pv-2: zoom to the selection
  (a 5 mm QFN is a cluster at board scale) and collapse rail connections to stubs outside Drive mode.

## 8. ✅ pv-2 BUILT + MERGED 2026-10-17 (framework eb2a635, angular 1547323; sonnet agent)
- Payload: per pin `drive_relevant, drive_status, drive_why, rail, pull, limit_class, limit_basis, group_budget` and `signal_relevant, activated, capable,
  lifecycle (locks)`; per connection `drive_relevant, signal_relevant`; part `short_title, title_pos, extent`; filters `protocol=i2c,spi`, `activated_only=1`,
  row-view `rail / drive_status / limit_class` lists. Base lines name no protocol signal (capabilities only) — pv-0 follow-up 1 closed.
- Component: mode switch All · Drive · Signal (irrelevant pins hidden; legend + panel per mode); drive glyphs (out/in/double current, ⊕, ⏚, pull resistor,
  hatched limit); signal badges; multi-select protocol + drive chips (highlight, grey the rest); zoom to the selection; rail stubs outside Drive; shelf-packed
  part labels (no overlaps, selftested), fit includes parts + labels, die titles inside the die; `--drive-*` tokens.
- board 668, cmod 698, hwnocode 163, spec 20/20, ng build + check:styles OK.
- Honest gaps: `pull=external` never emitted (no row names one); the 16U2 UCAP rail undetermined; unclaimed I/O stays not-driven at later stages;
  ICSP header pins reach the chip only through the ICSP1 part (not mode-relevant).
- **Live check of pv-2 on econ-core 2026-10-17:** Drive at firmware-committed — D2 pulled-up, D1 (TX) sources-or-sinks, D0 (RX) high-impedance, D6 current glyph
  hatched (limit undetermined, assumed Vf), 3V3 / 5V coloured by rail, grounds as returns. Signal + I²C + SPI — D10–D13, SDA/SCL, A4/A5 and the matching
  U1 legs highlighted, the rest greyed, supplies hidden; "31 pins can carry i2c + spi" (incl. the 16U2's SPI pins). Found: every label spread
  ("a r d u i n o") — measured cause: the page's inherited letter-spacing 0.25px on a ~0.9-unit font under the zoom → reset on the drawing's text
  (angular, this commit). Still to see after the redeploy: label packing, package-title overlap, the empty band above the board in the fit.
- **After the letter-spacing fix (econ-core, 2026-10-17):** labels read normally; no part-label collisions; clicking U2 zooms in, rail links show as
  "5V"/"GND" stubs with the rail's other pins listed in the panel, D0/D1/RESET legs carry the lifecycle lock, its connections to U1, ICSP1, the test
  pads, Y1 and X2 are drawn. Left: the U2 package title runs into a U1 leg label; an empty band above the board in the fit-all view.
- **✅ Rolled to pol-core 2026-10-17** (rp-0, pv-0, pv-1, pv-2 and fixes): pin-view surfaces, register profile and `/display/pin-view` answer 200 (backend ready ≈ 27 min). Disk was 98 % → `docker builder prune -af` freed 3.9 GB; now 95 % (6.3 GB free).

## 9. ✅ Small fixes MERGED 2026-10-17 night (framework 448127a, angular 820c7e0; sonnet agent) — his "do small fixes first"
- Package titles: short titles ("U2 QFN", "U1 SPDIP"), full name on hover; selftest: package-title boxes vs every other chip's leg-label boxes (at an
  assumed 6 px/mm fit zoom — a knob, not measured).
- Empty band: cause = fit() centred a wide board vertically in a tall viewport → `fitTransform()` hangs content from the top (18 px margin); spec at 3 sizes.
- Page headers: optional `title` on DisplayDefinitions (definition JSON), else the name humanized ("pin-view" → "Pin view"; names already in prose
  unchanged); titles set on Pin view / Pins / Connections / Surfaces / Register profile / Memory map. On an already-seeded server the title lands
  only if the seed rewrites the row — else the humanized fallback shows.
- Table → view: the component reads `pin= / surface= / connection=` (with mode/stage/protocol) and selects + zooms; `class-rows-table` gains a
  `view:` column format (`view:view:/display/pin-view?pin={id}`, in-app routerLink); every pin-data table has a "show in view" link.
- board 671, apps 126, specs 33/33, check:styles + ng build OK. To verify live with mis-0.
- **Live check 2026-10-18 (econ-core, small fixes + mis-0):** header reads "Pin view"; fit hangs from the top (no empty band); short package titles
  "U1 SPDIP" / "U2 QFN" clear of the leg labels; labels clean. The first load right after the backend's boot showed "The server could not be reached"
  (the door answered 200 in 0.3–0.7 s moments later) → follow-up: the component retries a failed read once (with a short back-off) before saying so.

## 10. ✅ pv-4 BUILT + MERGED 2026-10-18 (framework 61fee87 + merge a7574d9, angular 238aaf9; sonnet agent)
- Phases on the pin-view door (`phase=power-up|reset|bootloader|init|runtime|programming|debug`, `blank=chip|board`; per-pin `phase_basis`): power-up/reset —
  every I/O pin high-impedance, no pull, nothing activated (328P DS40002061B §14.2.1 p.85 + Table 14-1 p.86; 16U2 doc7799 §2.2.4–2.2.6 p.4–5, §12.2.1 p.68;
  DDRC/PORTC reset values not in the rows — said); bootloader (board as delivered) — D0 serves RXD (§20.7 p.188), D1 TXD (§20.6 p.185), RESET answers DTR via
  C5, the rest blank (Optiboot's D13 start-up flashes and the 16U2's own firmware undetermined); chip blank → no bootloader; init = the after-init stage.
- `ConfigurationEvent` (observed, never seeded); GET/POST `/api/board/{board}/config-events`: InstallRecord (installed) → flash, canvas BoardPinNet → wiring-added,
  derived on every read; POST validates kind/refs/who/when, refuses unknown kinds by name; a recorded event citing an InstallRecord hides the derived one;
  `pins_changed` = the payload diff (2–5 s per distinct comparison).
- Angular: phase selector + blank toggle + "After every reset the pins are blank until init runs" banner + an event timeline (click → its pins, before/after table).
- board 722, cmod 1011, manifests 8/9, spec 30/30, ng build OK. Owed: a "Configuration events" table page + a `pol board events` verb; derived wiring events
  carry no time/person (the row stores none).
