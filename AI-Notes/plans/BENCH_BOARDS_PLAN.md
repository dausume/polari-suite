# Boards on the Bench (bob) — every board is equally a Board; its definition is its own level

## 1. The ruling (his words, 2026-10-30)

> "we should also track that dev boards and breadboards and pcbBoards are all just equally Boards on the Bench. We might define our PCB in
> KiCAD then import it and integrate it with a simulated Breadboard wired to a dev board, and so on. We should be able to handle that some
> boards are defined via their layers and physics properties while others are defined directly from data-sheets, because Board definition in
> general is basically it's own level of abstraction seperate from what we are concerned about on the Bench. We should have an option to dive
> into a page about the Board Details from the Bench, but the abstracted drive and signal data centered around pins and footholds are our main
> concern at the Bench level."

Two levels, kept apart:
- **The Bench level:** Boards on the Bench, their FOOTHOLDS (every point where something can land: a header pin, a breadboard tie point, a
  connector pad, a terminal) with the abstracted DRIVE and SIGNAL data of each foothold, and the connections between footholds (wires,
  jumpers, a dev board's pins pushed into breadboard holes). Every bench feature (pin view, layout, electrical checks, simulation, Mission
  search) reads only this level.
- **The Board Definition level:** how a board is known. Three ways today, more later, none privileged:
  | Definition kind | Known from | Today's rows |
  |---|---|---|
  | datasheet | the vendor's documents (pinout, header tables, electrical tables) | BoardDefinition + BoardPin + ConnectorPin + ElectricalCharacteristic + DatasheetFact (UNO, ESP32-C3-DevKitM-1) |
  | geometry | a regular layout derived from counts and pitch | BoardModel kind breadboard (electrodevice) **and** BreadboardModel (board) — two classes for one idea |
  | layers + physics | the copper, stackup, parts and nets of a design (a KiCad import or a Polari design) | PcbBoard + Placement + Footprint + Route + SchematicSymbol + BoardNet (pcb, kxc) |
  A **Board Details page** per definition kind is where one dives in from the Bench.

### His correction (2026-10-30, later) - the Bench is NOT a netlist

> "keep in mind that the board is only concerned about connections and pins, it is not meant to be a complete netlist, the netlist/schematic can be
> something addressed at the board level that gets converted into a connection with drive and signal characteristics at the Bench level. The Bench
> level is focused around pins from board and chips and their connections to firmware and the pin driving requirements being met from inherent
> properties of pins and defined connections. Connections may be something we want defined at the board level since it needs robust schematics to
> define real drive behavior and safety handling."

So:
- **Board level** holds schematics / netlists (a PCB's, a breadboard circuit's) and is where real drive behaviour and safety handling are worked out.
- A board-level definition is CONVERTED into **bench connections**: pin <-> pin, or pin <-> load, each with DRIVE and SIGNAL characteristics (the
  current it needs, the level it needs, which side drives, the safety handling it carries) and the board-level definition it came from.
- **Bench level** = pins of boards and chips + their firmware use + those connections; the check is per pin: do the pin's INHERENT properties (source /
  sink limit, logic level, direction) meet the requirements of the connections defined on it.
- bob-2 as first built drifted: it unions breadboard strips and wires into bench-wide nets. That union is the board-level CONVERSION step; its output
  must be pin-to-pin connections with characteristics, and the checks must be per pin (bob-2b).

His follow-up the same day: "We can still have a bench level netlist view, it should just not be the main focus at the Bench level. The bench level is
meant to make it intuitive for normal people and simplify things to be concerned about the minimum possible. The Bench level netlist can exist but be
it's own seperate view that comes as a popup, it would overcrowd the main view to put a full netlist on there with the visualizations of real
components." → the bench netlist (bob-2's union, `GET .../nets`) stays as its OWN view, opened as a POPUP from the bench; the main bench view shows
only pins, their connections and whether the drive requirements are met.

## 2. Where we are (gaps)

- `Bench` keeps two lists (`boards_json` dev/eval boards, `breadboards_json` breadboards); PCBs cannot be on a Bench.
- `BenchBoard` (electrodevice, lay-0) is already "one physical board on a bench" over a `BoardModel`, whose kinds `protoboard` and `pcb` are
  RESERVED (no geometry). It does not name a Bench.
- Two breadboard-kind classes: board.BreadboardModel (bench-0, tie points / rails / power limits) and electrodevice.BoardModel kind breadboard
  (lay-0, rows / holes / pitch).
- No foothold row: the bench features read BoardPin (dev boards), the breadboard compiler's tie points (breadboards) and nothing (PCBs), each
  in its own way.

## 3. The bench contract: footholds

`BoardFoothold` (new, one row per landing point of a board DEFINITION, so every BenchBoard of that definition shares them):
- identity: definition kind + definition, `foothold` id (J1:9, a17, J3:2, TP4), kind header-pin | tie-point | pad | connector-pin | terminal | test-pad,
  position on the board (mm, the definition's own frame), side.
- **node**: which footholds are the SAME electrical node inside the board (a breadboard strip a-e, a PCB net, a dev board's two GND pins) — the
  board's internal wiring reduced to "these are joined"; the inside detail stays at the definition level.
- **drive**: rail / supply voltage (nullable = unknown), current limits (source / sink / rail), the cited basis of each number.
- **signal**: families (gpio, uart, adc, pwm ...), the chip pin behind it when there is one (BoardPin / SocPin), direction capability,
  input thresholds — or none (a passive tie point).
- every value carries its source in the definition (a DatasheetFact, the geometry rule, a KiCad net + the ERC pin type) or says undetermined.

One ADAPTER per definition kind derives the footholds from the definition's rows (`board.custom.footholds.<kind>`); nothing is typed twice.

## 4. Slices

| Slice | What | Acceptance |
|---|---|---|
| bob-0 contract | `BoardFoothold` class + the three adapters (datasheet from BoardPin/ConnectorPin/ElectricalCharacteristic; geometry from the breadboard rows; layers from PcbBoard/Placement/BoardNet + pads once kxc-4 lands, header pads only until then). | UNO, C3, a half breadboard and the ingested ecc83 board each yield footholds; every drive/signal number cited or undetermined; the UNO's two GND header pins share a node; breadboard strip a-e is one node. |
| bob-1 one Bench list | `BenchBoard` names its Bench and a (definition_kind, definition); `Bench.boards_json` + `breadboards_json` converge onto BenchBoard rows (old fields read, kept until the Bench page is moved). One breadboard class (converge BreadboardModel ↔ BoardModel by name). `BoardModel` kind `pcb` stops being reserved: a PCB BenchBoard points at a PcbBoard. | home-bench lists UNO, C3, the breadboards and an ingested PCB as equal Boards; nothing a person added is lost. |
| bob-2 connections across boards | Wires/jumpers foothold ↔ foothold across any two Boards; MATING (a dev board's header pins pushed into breadboard tie points, a PCB connector onto a header) joins footholds automatically. The layout compiler and the electrical checks (drive limits, levels, one output per node) run over footholds + connections. | A C3 DevKitM-1 on a breadboard wired to an ingested KiCad PCB: one node graph, the 3.3 V vs 5 V check fires across boards, the LED current check reads the foothold drive data. |
| bob-3 Board Details = the single-Board design simulation view | His addition 2026-10-30 (below). `/display/board-details?board=<BenchBoard>` is a SEPARATE simulation view for ONE Board and its design, dispatching by definition kind. For a layers+physics board it breaks the design down: the layer stack (copper, dielectric, mask, silkscreen, paste, courtyard, edge) one layer at a time; the circuits IN the layers (nets traced across copper and vias, which parts and pads each joins, per-net current/voltage from the circuit simulation); THERMAL behaviour (heat sources from the parts' dissipation, spreading through copper/planes/vias, the board's temperature map); silkscreen and fab layers; footprints and pads per part. For a datasheet board: its package / die levels (today's pin view levels), facts and electrical tables. For a geometry board: the strip drawing and its rules. Linked from every Board on the Bench page and the bench pin view; the Bench never shows this detail itself. | Click-toggle, theme tokens, no raw JSON; one click Bench → Details → back; each simulated number (thermal, net current) names its model and inputs or says undetermined. |
| bob-4 bench views on footholds | The bench pin view and layout view draw every Board's footholds the same way (a PCB's connector pads like a dev board's header pins); drive/signal modes read foothold data only. | The UNO pin view unchanged byte for byte; the PCB appears on the bench drawing with its connectors. |

### The single-Board design simulation view (his words, 2026-10-30)
> "We can have a seperate simulation view for the breakdown of a single Board and it's design. Going into the layers, going into the details of
> how the circuits in the layers work, how it handles thermal behaviors, silk screens, footprints, etc"

Its layers (sub-slices of bob-3, each needing the kxc data it reads):
| Part | Reads | Simulation |
|---|---|---|
| layer stack | PcbBoard layers/stackup (kxc-1 today), per-layer geometry (kxc-4) | — (drawing) |
| circuits in the layers | kxc-2 nets + kxc-4 tracks/vias/zones + SchematicSymbol | the circuit simulation (kxc-3) projected onto copper: current per net / track, voltage per node, IR drop along a track (from width, length, copper weight) |
| thermal | parts' dissipation (from the circuit simulation), copper areas, vias, stackup materials | board heat spreading → temperature map; every material number cited, every model named (a new thermal engine; the fp arc's thermal work is the nearest relative) |
| silkscreen / fab | kxc-4 graphics on F/B.Silkscreen, Fab, Courtyard | — (drawing, overlap checks) |
| footprints / pads | kxc-4 pads per footprint, Footprint/LandPattern rows | pad-to-courtyard and pad-size checks (land patterns vs datasheet, pcb-3) |

## 5. Ties to other arcs

- kxc (KICAD_INTERCHANGE_PLAN): the layers definition is fed by kxc ingest; kxc-2 (connectivity) gives PCB nodes, kxc-4 gives pads. kxc-5
  exports a Bench (boards + connections) to KiCad where it can.
- hsp (HARDWARE_SYSTEM_PINS_PLAN): the enclosure levels already say E2 "the board (PCB or dev board)"; footholds are the board's outward
  exposure (E2 → bench). EnclosureContact rows stay the definition-level chain (die → package → board).
- Mission (MISSION_GENERIC_PLAN): the Inventory step reads Boards on the Bench; Combine places parts on footholds.

## 5b. As built

- **D-bob-1..3 his (2026-10-30): "Just go with recommendations"** → foothold; extend electrodevice `BenchBoard`; one breadboard class into `BoardModel`.
- **bob-0 ✅ BUILT 2026-10-30:** `BoardFoothold` (board module; derived on read for datasheet/geometry, stored by the PCB ingest) +
  `board.custom.footholds` (datasheet / geometry adapters, dispatcher) + `pcb.custom.kicad_footholds` (layers: connector / test pads, positions =
  pcbnew's on all 198 pads of two demo boards, references in `pcb/custom/reference/`) + door `GET /api/board/footholds/{kind}/{definition}`.
  UNO 38 footholds (4 GND pins one node), C3 30, half breadboard 400 / 64 nodes, ecc83 PCB 12 pads; every number cited or -1 + reason.
  With kxc-2, a PCB foothold names what is behind its pad (the schematic net's pins + ERC types; drivers → direction out, inputs only → in).
- **bob-1 (part a) ✅ BUILT 2026-10-30:** `BenchBoard` gains `bench`, `definition_kind`, `definition`; `board.custom.bench_boards`: ONE list per
  bench (the older two lists + BenchBoard rows naming the bench); doors `GET /api/board/benches/{bench}/all-boards`,
  `POST /api/board/benches/{bench}/pcbs`. **Found:** three of the four dev boards on home-bench (Zero, Feather M0, ESP32-S3 e-paper) have NO
  BoardPin rows → no footholds (said per row). Still open in bob-1: the breadboard class merge (D-bob-3), the Bench page reading the one list.
- **bob-2 ✅ BUILT 2026-10-30:** `BenchConnection` (bench, from board + foothold, to board + foothold, kind wire | jumper | mated, colour);
  every Board on the Bench has a stable `id` (boards_json#n, breadboards_json#e.k, a BenchBoard name); `board.custom.bench_nets`: union-find over
  each board's own nodes + the connections → nets that cross boards, findings from foothold data only (supply-conflict, supply-to-ground,
  over-voltage: a pin's logic level below a rail / driving level on its net); "only inputs" is a NOTE (a board's own pull is not a foothold fact
  yet); `mate_header` (a 1 x N header pushed into breadboard holes). Doors `GET|POST /api/board/benches/{bench}/connections`, `POST .../mate`,
  `GET .../nets` (`bench_nets_api.py`). His example works: C3 on a breadboard wired to the UNO → one graph; UNO D6 onto C3 IO0's strip = over-voltage.
  Open: pulls as foothold facts; current budgets across boards (LED current through a series part needs the circuit, kxc-3); the bench page drawing.
- **bob-2b ✅ BUILT 2026-10-30 (after his correction):** `board.custom.bench_pins` CONVERTS the board-level wiring (wires, mated headers, a
  breadboard's strips) into the main bench view: one row per PIN (pins a board joins inside = one row, "UNO GND (4 pins)"; no breadboard hole is
  ever a row - holes are named in `via`), its FIRMWARE use (CatomVariable: LED_PIN gpio.out in uno-light ...), the pins it reaches, and checks of
  the pin's inherent properties against its connections + firmware: over-voltage, contention (two outputs driving each other), short (two
  supplies / a supply and ground); notes for floating inputs and for loads (no board-level circuit defines a load yet - the mA limits wait for
  one). Door `GET /api/board/benches/{bench}/pins`. /display/bench's "Boards on the bench" tab: the one list, then the PINS table; the bench
  NETLIST (bench_nets, `GET .../nets`) only in its own popup ("Bench netlist" picker-button, his follow-up); the raw wiring table beside it.
  bob-2c (below) followed: connections DEFINED at board level with real drive behaviour - a breadboard circuit (CircuitDefinition: R + LED) or a PCB
  schematic net converted into a pin <-> load connection whose current / level requirement comes from the board-level schematic (electrical_check
  / the simulation), so the load check reads real numbers.
- **bob-2c ✅ BUILT 2026-10-30:** a board-level circuit built on the bench = a BenchConnection of kind `circuit` (POST .../circuits {board,
  circuit, on?}); bench_pins runs board.custom.electrical_check on it (the circuit's BoardPinNet binding to the board's pins) and each finding that
  names a pin lands on that pin's row: `defined` names the circuit + role + net, refuse = a check, warn / undetermined = a note (D6: 13.636 mA with
  the ASSUMED 2 V LED, Vf-free ceiling 22.727 mA vs the cited 20 mA; D2: no pull). New cross-check: firmware use vs the circuit's role for the pin
  (a firmware that reads a pin the circuit drives = role mismatch). The page's pins table shows `defined`.
- **bob-2d ✅ BUILT 2026-10-30:** the firmware a Board RUNS = a BenchConnection of kind `firmware` (POST .../firmware {board, firmware}); the bench
  then shows only that firmware's pin use (others: "uno-light (if flashed)") and the board-level checks run with its binding
  (`<solution>@<board>`), so they read its real PinClaims - uno-light's D2 pull-up (hal_button_init: PORTD |= _BV(PD2)) turns the false "D2 has
  no pull" warning into ok. (esp32c3-light has no FirmwareSolution yet: its claims are not derivable - said, never guessed.)
- **bob-3 (part a) ✅ BUILT 2026-10-30:** `/display/board-details?board=<kind>/<definition>` (`board_details_page.py`, configured tables only):
  picker = the Boards on home-bench; tabs Summary / Footholds / Nets / Parts / Layers / KiCad coverage, all from `GET /api/board/details/{kind}/
  {definition}/{part}` (`board.custom.board_details`). Each bench row now carries `board` = kind/definition and `details` = the page link.
  The design-simulation drawing (copper per layer, circuits in the layers, thermal map) is the next part; its data now exists (kxc-4).
- **bob-1b ✅ 2026-10-30:** /display/bench gains the tab "Boards on the bench (one list)": every Board with a Board Details link (`view` cell),
  the connections, the nets across boards with their findings.
- **bob-3b ✅ 2026-10-30:** Board Details tabs for a PCB's design - Pads, Copper (per net: segments, vias, length, narrowest track, DC resistance
  rho L / (w t) per segment, t from the board's stackup, rho = IEC 60028 annealed copper by definition; the net sum labelled an UPPER BOUND),
  Zones (filled copper area), Silkscreen + drawings, Net classes + rules. Thermal is NOT built: it needs each part's dissipation (the circuit
  simulation, kxc-3) and a spreading model - said on the page.

## 6. Decisions (his)

- D-bob-1: the word. "foothold" (his) for the bench-level landing point — recommended, distinct from the chip-level "pin" and the
  definition-level "contact".
- D-bob-2: where the Board on the Bench lives: extend electrodevice's `BenchBoard` (already the "board on the table") — recommended — or a new
  board-module class.
- D-bob-3: one breadboard class: keep board.BreadboardModel's fields (tie points, power limits) merged into electrodevice.BoardModel kind
  breadboard — recommended (BoardModel already spans kinds).
