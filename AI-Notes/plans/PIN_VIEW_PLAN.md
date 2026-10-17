# The pin view: a d3 visualization of boards, chips, enclosures and their pins (pv arc) — plan 2026-10-17

PLAN ONLY until his go. Builds on hsp-0/1 (`HARDWARE_SYSTEM_PINS_PLAN.md`: enclosures, exposure maps, the availability ladder, Hardware
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

### 2.5 Data door (one composed read)
`GET /api/board/{board}/pin-view?system=&binding=&phase=&protocol=` → shapes (from the shape rows), pins per level with positions, crossings,
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
- **D-pv-5** order: pv-0 alongside the msp register profile (rp-0), then pv-1..4; the solution search (sol-0) later draws its candidates in this view.
