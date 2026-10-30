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
| bob-3 Board Details | `/display/board-details?board=<BenchBoard>` dispatching by definition kind: datasheet (the pin view's board/package/die levels, the facts), geometry (the breadboard drawing + rules), layers (schematic/layout SVGs, the KiCad coverage table, layers/stackup). Linked from every Board on the Bench page and the bench pin view. | Click-toggle, theme tokens, no raw JSON; one click from the Bench to the Details and back. |
| bob-4 bench views on footholds | The bench pin view and layout view draw every Board's footholds the same way (a PCB's connector pads like a dev board's header pins); drive/signal modes read foothold data only. | The UNO pin view unchanged byte for byte; the PCB appears on the bench drawing with its connectors. |

## 5. Ties to other arcs

- kxc (KICAD_INTERCHANGE_PLAN): the layers definition is fed by kxc ingest; kxc-2 (connectivity) gives PCB nodes, kxc-4 gives pads. kxc-5
  exports a Bench (boards + connections) to KiCad where it can.
- hsp (HARDWARE_SYSTEM_PINS_PLAN): the enclosure levels already say E2 "the board (PCB or dev board)"; footholds are the board's outward
  exposure (E2 → bench). EnclosureContact rows stay the definition-level chain (die → package → board).
- Mission (MISSION_GENERIC_PLAN): the Inventory step reads Boards on the Bench; Combine places parts on footholds.

## 6. Decisions (his)

- D-bob-1: the word. "foothold" (his) for the bench-level landing point — recommended, distinct from the chip-level "pin" and the
  definition-level "contact".
- D-bob-2: where the Board on the Bench lives: extend electrodevice's `BenchBoard` (already the "board on the table") — recommended — or a new
  board-module class.
- D-bob-3: one breadboard class: keep board.BreadboardModel's fields (tie points, power limits) merged into electrodevice.BoardModel kind
  breadboard — recommended (BoardModel already spans kinds).
