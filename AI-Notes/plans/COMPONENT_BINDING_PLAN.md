# Hardware features — schematic blocks and one narrowing row — PLAN ONLY (2026-11-24)

## 1. The ask (the user, 2026-11-24)

People place the abstract: "a button we want to use" and "a protocol we want to use for it". The drive and signal
conditions are solved for them (pull resistors, series resistors, guard diodes against backflow into a GPIO, filter
capacitors as close to the pins as possible), the matching firmware is applied, and a schematic definition and view
always exist.

> "maybe instead of selecting pins we can choose things one piece at a time to add to an overall components page and
> we define a generic row for binding behavior together and resolving it. We should be able to start from any one of
> the columns needed for a row, and be able to filter down existing viable options across all columns each time we
> choose from another column on that row."

> "it is multi-phased logic where people can start where they want, but we should be ensuring the logic is complete
> by the end"

The user's drawing (2026-11-24) shows:
- **Each component as its own schematic block.** "LightComp" holds the light, a noise-prevention capacitor at one
  GPIO, a guard diode at the other, and the supply. "BtnSchematicComponent" holds the button, its capacitor and diode,
  across two chips.
- **Blocks marked Solved or Unsolved.** An unsolved block is bare wiring between two GPIOs, and it is drawn red.
- **A struct instance bound to the blocks:** `ButtonOn` → the button component, `LightOn` → the light component, a
  toggle object id, and the UI's toggle as a bridge input.

## 2. What exists (tested on pol 2026-11-24)

| Piece | Test | Result |
|---|---|---|
| No-code binds HAL variables to pins, checked by the HAL, the variant and the electrical rules; slots offered best first with reasons; UNO and C3 | `cmod.cmod_catom_hal_nocode_selftest` | 18/18 |
| Pin and route placement from a Mission (interrupt or polled, objective switch, reserved pins refused by name, missing parts named), UNO and C3 | `cmod.cmod_solve_selftest` | all pass |
| Electrical rules from cited numbers: an LED with no series resistor refused, VOH under load, input thresholds, budgets, lifecycle | `board.board_hardware_truth_selftest` | the 40 lines read all pass |
| Circuit states, floating inputs flagged, `.op` per state by ngspice | `electrodevice.circuit_states_selftest` | 29/29 |
| The circuit at every firmware node on the twin | `cmod.cmod_light_topology_selftest`, `cmod.cmod_node_run_selftest` | 38/38, 14/14 |

Read in source, not yet tested:
- `board/custom/electrical_check.py` rule (e), "the button's pull is defined".
- `board/custom/part_fixes.py`, which suggests catalogue parts for a drive finding.
- The ESD protection parts and events.

`board.board_circuit_selftest` and `pcb.pcb_esd_protection_selftest` printed nothing when run directly; to be run the
way they expect.

Not found in source (to be confirmed by a test, cb-0):
- applying a fix into the circuit (detection and suggestion only);
- a rule for an input filter capacitor at the pin;
- a rule for a backflow (guard) diode;
- a solved/unsolved state per path;
- a componentized schematic view.

The missing piece is the schematic block, plus the one row that binds everything together.

## 3. The schematic block (cb-1)

A `SchematicBlock` row is one component as the drawing shows it:
- **intent:** button, light, …;
- **ports:** signal, supply, ground; which chip pins they meet comes from the `HardwareFeature` row;
- **parts:** a template of the core part plus the conditioning parts, each one placed by a rule, not typed by hand;
- **solved state:** `unsolved` (never solved), `solved` (with the solver's version and inputs hash), or `stale` (an
  input changed since it was solved);
- **its findings:** in words, from the existing electrical rules.

The schematic view draws one card per block. An unsolved or stale block's paths are red.

## 4. The `HardwareFeature` row (cb-2)

Named by the user, 2026-11-24: `HardwareFeature` (for example "the button feature", "the light feature").

One generic row; each column is optional until the end:

| Column | Existing rows it points at |
|---|---|
| struct field (struct instance + field) | the struct and bridge maps (`StructObjectMap`) |
| UI control and its direction | bridge input or output |
| no-code piece | the catom / HAL variable (`HalVariableState`) |
| HAL role / operation | `hal` soc rules |
| protocol | active-low, debounced, interrupt or polled, … (rows) |
| schematic block | `SchematicBlock` |
| chip and pins | `SocPin` / `BoardPin` |

**No sim-or-real column.** The user, 2026-11-24: "a simulator/device pair should be defined. We are solving for a real
device but building initially on a simulator for safety."
- The design is always solved for a **real device**: real chip, real catalogue parts, real pins.
- Each device has a defined **simulator pair**: the engine and binding that stand in for that device, with the same
  circuit solved around it.
- Builds go to the simulator first, for safety. The same build then goes to the device.

**Narrowing.** Choosing any column filters the viable options of every other column, each time, in any order:
- A struct field of type bool admits button or switch intents.
- A button intent admits the protocols a button has.
- A protocol with an interrupt admits only pins with an interrupt route; the existing slot ranking already does this
  for one column.

Compatibility is a set of relations between column pairs, kept as rules over the existing rows, not one-off code. Each
excluded option says why. "Define new" is always offered in every column; it opens that piece's definition and returns
to the row.

**Solve from any direction (the user, 2026-11-24: "we'd want to be able to even leave out what specific pins we
choose and get suggestions, being able to solve from multiple directions").**
- Any column can be left open, pins included.
- Every open column gets ranked suggestions from the solvers, with reasons. The pin solver is
  `cmod_solve`, which already ranks pins.
- Each value carries how it got there: `chosen` (a person picked it and it is held) or `suggested` (a solver filled
  it). A re-solve may change suggested values, never chosen ones.
- A conflict between chosen values is said by name, with what would resolve it.
- The same solve runs whichever columns are filled: struct first, block first, pins first, or protocol first.

**Struct-first.** Starting from a struct instance proposes a row per field, with each field's type narrowing its row.

## 5. The solvers (cb-3)

Run on a row or a whole components page:
- **pins:** the existing `cmod_solve`;
- **conditioning:** new. From the protocol and the cited numbers, add the pull (or choose the internal one), the
  series resistor, the guard diode where the signal can rise above the pin's rail or come from another supply, and
  the filter capacitor at the pin where the protocol says the input is noisy or a debounce is in hardware. Each added
  part names the rule and the numbers. A rule that has no cited number says undetermined, never guesses.
- **firmware:** the existing HAL knobs and `pol board gen`, configured from the protocol (internal pull-up on or off;
  debounce in hardware or in firmware).

## 6. Complete by the end (cb-4)

A row is complete when every required column is filled, every solver has run on the current inputs, and no finding
refuses. Complete also means:
- **solved for the real device:** every part is a real catalogue part, and the chip has a toolchain and a flasher;
- **its simulator pair is defined:** the device's simulator has an engine whose binding passes its conformance suite,
  and the circuit can be solved around it.

What is missing from either half is named. A components page is complete when every row is. Build, flash and release refuse an incomplete page by name,
naming the row and the column. People start wherever they like; this is the one check that the logic is whole at the
end.

## 7. The components page (cb-5)

One card per row, as in the drawing: the block with its solved state (red when unsolved), the struct fields bound to
it, the no-code piece, and the pins. Built from configured displays (no raw JSON), the narrowing shown per column with
its counts and reasons.

## 8. Order

1. cb-0: test the "not found" items of §2 (no claim without a run).
2. cb-1 blocks and the view.
3. cb-2 the `HardwareFeature` row and the narrowing.
4. cb-3 the conditioning solver.
5. cb-4 the completeness gate.
6. cb-5 the page.

Release 94 is not touched by this.

## 8a. Prototype built (2026-11-25, source-tested, uncommitted until after 18:00)

Branches `dev-hw-features` in the framework and in the Angular app.

**Rows (hwnocode).** Four classes, one per file:
- `SchematicComponent`, `SchematicComponentPort`, `SchematicComponentPart`;
- `HardwareFeature`: the rough model, with `chosen` as a csv of held columns.

They are registered where the server actually registers classes: `polariServer.py` defClassList and
`polariApiServer/feature_imports.py`. `HWNOCODE_CLASSES` alone does not register a class. Each class gets its generated
CRUDE API and table from the object typing; no route is added.

**Seeds.** `custom/schematic_seed.py` holds the user's drawing:
- 2 solved components, each with a filter capacitor, a guard diode and a battery;
- 2 unsolved components, bare;
- `ButtonOn` and `LightOn` on struct-instance-1.

"Solved" names the drawing: no solver has run. No part value is invented.

**The column model.** `custom/feature_columns.py`: each column, what it refers to, what it narrows and why, whether it
is required (provisional), and the completeness reader.

**Pages.**
- `/display/schematic-components`: the cards, then the ports and parts tables.
- `/display/hardware-features`: one row per feature, one card per element (chosen / suggested / open), a schematic
  card drawing the bound component, and the completeness verdict.

**Two generic components:** `schematic-component-cards` and `feature-cards-table`. Both take class names and read
CRUDE. The drawing is a pure layout, `schematic-drawing.ts`: no d3, red where unsolved.

**Tests:**
- `hwnocode_schematic_selftest` 31/31;
- `hwnocode_selftest` 171/171 (seed counts updated);
- `pol modules conform hwnocode` clean;
- the framework selftests that read the class list or pages are unchanged; their two failures were already there before
  this change;
- Angular unit tests 602/602 (586 before, 16 new);
- `ng build` clean;
- a rendered preview from the seed rows was checked by eye.

**Not built yet:** the narrowing (§4), the solvers (§5), the completeness gate on build (§6), editing from the page.

## 8b. Integrated with the proven solution (2026-11-25, source-tested, uncommitted until after 18:00)

The user, 2026-11-25: "integrate the component logic with the currently built out and proofed solutions so we can run them to ensure
they are solved for schematics and we have fully flushed out HardwareFeature rows bound to a specific HardwareSolution".

**The solver (`hwnocode/custom/schematic_solve.py`, `pol hwnocode features <solution> [--write]`).** On a board `HardwareSolution`
(today `uno-light-system`: `uno-light` on the UNO, circuit `uno-button-clock`), it runs what is already built and proven, then keeps the
answers as rows:
1. `board.custom.electrical_check` (a)-(j) on the circuit and the firmware binding (the same call as `pol board circuit-check`);
2. `schematic_derive`: the circuit cut into components (one per core part: a switch is a button, an LED a light), with ports where the
   lines meet board pins (a second pin on the same net is a tap) and parts (the core part, resistors on the way = series, a resistor to a
   rail = pull, the firmware's PinClaim pull = the chip's own pull resistor, drawn as a resistor);
3. `schematic_rules`: four conditioning rules per component (pull, series, guard, filter), each placed / not-needed / needed with its
   reason; the electrical findings sorted onto the component they are about (the rest are about the whole solution) ->
   `SchematicComponentCheck` rows; a component is `solved`, or `blocked` when a part is needed or a rule refuses;
4. `feature_derive`: one `HardwareFeature` per component, every column from the HAL variables (`catom_variables`), the catom assertions'
   pin <-> field couplings, the firmware's pin claims, the debounce knob and `twin_kinds` (the simulator pair).

The rule for guard and filter is new and narrow. A guard diode is needed only when another board or a supply reaches a component's net. A
filter capacitor is needed for a mechanical contact that the firmware does not debounce. What they do not model (long wires, ESD) is said
in their words. No value is ever invented: a part the rule wants but cannot size is "needed, value undetermined".

**Recorded, not run at boot.** The solve takes ~20 s (the binding's pin claims come from the firmware graph). Its result is
`custom/solved/uno-light-system.json`, with one sha256 over every input it read; the seed reads the record. The selftest and
`pol hwnocode features` solve again and compare: a different inputs sha = stale (exit 1), re-record with `--write`.

**Result on uno-light-system.** Both components solved, both features complete:
- the light (LED1 on D6, R1 220 ohm placed as series, D3 a tap on D6's line): LED_PIN + SENSE_PIN, field `led_on`, active-high;
- the button (SW1 on D2, the chip's pull-up placed by PinClaim `uno-light:D2`): BUTTON_PIN int.ext, fields led_on/toggles/source/status,
  falling edge, active-low, debounced 30 ms in firmware;
- device `arduino-uno-r3`, simulator `atmega328p twin (kind avr, board-engines)`;
- 5 numbers stay undetermined and named (the LED forward voltage, the switch's closed resistance): solved does not hide them.

**The same code on the C3 design** (`--circuit c3-light --board esp32-c3 --variant esp32c3-light`, no HardwareSolution): the light
solves; the button is BLOCKED, pull needed. The variant `esp32c3-light` does not resolve to a firmware binding in `cmod binding.resolve`
(it falls back to treating the name as a board), so no pin claim is read and the internal pull-up the C3 firmware sets is not seen. The
same gap makes `pol board circuit-check c3-light --binding esp32c3-light` read "missing V_pin" and the UNO's supply total. To fix in
cmod (a C3 firmware binding), not here.

**Completeness now also needs** the hardware solution, the device and the simulator pair (`feature_columns`); the drawing's rows have
none, so they are never complete.

**Tests:** `hwnocode_solve_selftest` 30/30 (record not stale; the UNO answers above; every electrical finding lands once; each rule is
live: no PinClaim -> pull needed, debounce 0 -> filter needed, no R1 -> series needed, another board on the button net -> guard needed;
a changed input changes the sha; the C3 through the same code; the seed carries the record); `hwnocode_schematic_selftest` 32/32;
`hwnocode_selftest` 171/171; conform clean; Angular 605 + 15 skipped (3 new specs: a tap, the chip's pull as a resistor, the solver's
decisions on a card, opened when red).

## 9. Open with the user

- Is the column list in §4 right, and which columns are required for "complete"?
- One row per struct field (as the drawing binds `ButtonOn` and `LightOn`) or one row per component?
