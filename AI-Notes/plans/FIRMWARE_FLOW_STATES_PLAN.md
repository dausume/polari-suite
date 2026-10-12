# Firmware flow states (flow arc): the no-code states a person needs to FOLLOW and CONTROL how hardware is set up, how data is defined, and how tasks run — on top of the atoms that already generate the code

**Date:** 2026-10-12 · **Status: PROPOSAL (his ask; nothing built; D-flow-1..5 his).**

## §0. His ask, verbatim (2026-10-12)

"what about the init functions? Those should be under their own 'Initialization Purpose' correct? If our hardware will not work or
accept commands without an init program, that should be its own purpose. An initialization purpose makes sense. And then we can have
an initialization finished node, an initialization started node, and then have from the initialization finished node, priority
assignment nodes for different tasks, and then task defining nodes, and the defining of those tasks from c atoms, where the c atoms
accept HAL data. We will need to define different kinds of HAL objects, and then we can choose to make any generic Polari Object into
a Struct Object … and we will want states for all of these. We need to define the overall flow of how we are defining data and
initialization and how we are defining the tasks in the no-code. An amalgamation of C-nodes may be enough to generate code but it is
not enough to help a normal user follow the logic flow of how to put together the logic they need for hardware and form an intuition
about how tasks work and how initialization of hardware works and what is needed to get hardware working in general. We need to
introduce a series of states to help the user follow and control the flow and priority of tasks and the setup of hardware."

Earlier the same session, on `hal`: it is the hardware abstraction layer — one C file per board family (`hal.c/hal.h`, UNO and
ESP32-C3) holding every register-touching routine; nine of the light graph's sixteen boxes are HAL plumbing drawn as peers of the
five behaviour atoms.

## §1. What exists, and what each new state is the authorable face of (reuse map — nothing here replaces a row that works)

| exists today (row / kind) | what it already knows | the new state that makes it FOLLOWABLE |
|---|---|---|
| `CFunctionAtom` + `CGraphNode` kind `c-atom`, with `stage` init \| loop \| called (from the POLARI_NODE annotation) | every function, its ports, resources, ISR-safety, cost | stays the leaf; sits INSIDE a Task, not beside it |
| glue kinds `class` · `parser` · `frame` · `tick` · `rule` (cmod-glue writes them) | the state struct, the command parser, the telemetry frame, the 1 ms tick, rules | become **Struct**, **Command handler**, **Report**, the **Tick** priority kind |
| `ScheduleSlot` (fs-0, DERIVED: isr / tick / loop / init / called lanes) | when each atom runs, derived from annotations, never authored | **Priority assignment** is the AUTHORED form; the derived lanes become the check that the author and the code agree |
| `TargetDefinition` · `PinClaim` · `PeripheralClaim` · `RegisterAssignment` · `HardwareBinding` | which pin/peripheral/register a task needs and owns, per board | **HAL object** = the person-facing bundle of one peripheral's claim + its init atom + its use atoms + its datasheet bindings (isotopes) |
| wire classes with a pinned contract (`LightState`, ucd-0e1) | the struct the board keeps and sends; fields that double as commands | **Struct** = any Polari object promoted to a wire class (contract pinned, fields typed for C) |
| `CapabilityDefinition` ("Purpose") — advised ≥ 1 per atom; the plumbing Purposes `*-bring-up`, `*-serial-link` made 2026-10-11 | a goal in a person's words + the tasks + a proof | **Initialization** becomes its own Purpose on every firmware, always first; `*-bring-up` is renamed to it |
| hn plan: RTOS node kinds task/queue/mutex (not built); the runtime ladder bare-c < freertos < esp-idf/zephyr; the suggestion engine (hn-1) | where an RTOS is needed | **Priority assignment** carries the numbers/levels the ladder and the suggestion read |
| the canvas: staged columns init → loop → called → glue; Purpose ▾ / Atom ▾ | one column per stage | the columns become the FLOW: Data → Initialization → Priorities → Tasks → Up/Down |

## §2. The states (person-facing name · class · what it carries · what it generates · what it refuses)

**Data**
1. **Struct** (`StructObject`): a Polari object class marked "lives on the board" — fields typed for C (int8..int64, bool, fixed-point), the
   pinned wire contract (version, hash), which fields are COMMANDS (down) and which are REPORTS (up). Any generic Polari object can be
   promoted to one ("Make this a Struct"): the promotion pins the contract and refuses fields that have no C type (a string, a nested
   object) by name. Generates: the `class` glue (the C struct), the codec, the proto. Today: `LightState`.
2. **HAL object** (`HalObject`), by kind — **Pin** (digital in / out, pull, edge), **Serial link** (UART: baud, frame), **Clock tick**
   (period), **Analog input** (ADC channel, reference), **PWM output** (timer, duty), **Interrupt source** (INT0/INT1/PCINT, edge),
   later **I²C** / **SPI** device. Each carries: the peripheral claim + pin claim it owns, its `init` atom, its `use` atoms (read / write /
   send / pop), its datasheet bindings (the isotopes), its electrical facts (from the chain). On the canvas it is ONE card ("Serial link:
   USART0 @ 115200"), expandable to its atoms. Generates: nothing new — it is the grouping of the existing hal atoms by what they abstract.
   Refuses: a second HAL object claiming the same pin or peripheral (the existing cooperation rule), a HAL object on a pin the board
   cannot do (target_compat).

**Initialization**
3. **Initialization started** (`InitStart`): the firmware's entry (reset → main). Carries the board, the runtime, the clock source. One
   per firmware. Generates: the top of `main()`.
4. **Initialize** (`InitStep`): one per HAL object (and one per Struct that needs a reset value); wraps that object's `init` atom;
   ordered by "then" edges (clock before serial, serial before anything that reports). Generates: the init block in order. Refuses by
   name: a Task that uses a HAL object with no Initialize step upstream of Initialization finished; a cycle.
5. **Initialization finished** (`InitDone`): the gate. Everything downstream is the run. The **Initialization Purpose** = Initialization
   started + every Initialize + Initialization finished, goal sentence: "the board is set up and ready to run its tasks and accept
   commands". Its acceptance proof on the twin: boot → the first report frame arrives with `boot_session` set.

**Priority and tasks**
6. **Priority assignment** (`PriorityAssignment`): from Initialization finished, one per Task: HOW it runs — **on interrupt** (which
   Interrupt source), **every N ms** (the Clock tick), **in the loop** (order among loop tasks), **on command** (which Struct command
   field), **on report** (every frame) — and a priority (D-flow-2: numbers, or named levels interrupt / fast / normal / background).
   Bare C generates: ISR bodies, the tick dispatch, the loop order (this IS today's derived `ScheduleSlot`, now authored; the derived
   lanes become the check "the code agrees with what you assigned"). FreeRTOS / Zephyr generate: a task per assignment with that
   priority, a queue per command field (the hn plan's task/queue/mutex kinds). The suggestion engine (hn-1) reads these: two priorities
   sharing a HAL object → the priority-inversion evidence → "FreeRTOS advised".
7. **Task** (`TaskDefinition`): a named unit of work with inputs (HAL objects it reads, Struct fields it reads) and outputs (HAL objects
   it writes, Struct fields it writes), its atoms INSIDE (expand the card), ≥ 1 Purpose (advised). Generates: `void task_<name>(void)`
   calling its atoms in order (today's `called` lane). Refuses by name: a Task writing a Struct field marked report-only from a command
   path; a Task using a HAL object it does not declare.
8. **Command handler** (`OnCommand`): a Task kind bound to a Struct command field (SET_LED) — the DOWN direction (today's `parser` +
   `apply` atoms). **Report** (`Telemetry`): a Task kind that sends the Struct up (today's `frame` + `telemetry_send`) — the UP direction.
   Both are Tasks with a fixed trigger kind, so the two directions of the light test are two visible cards.
9. The **C atom** (existing) lives inside a Task; its ports accept HAL object data (a Pin's level, a Serial link's byte) and Struct fields.

**Edges (three words):** **then** (order: Initialize → Initialize, loop Task → loop Task), **uses** (Task → HAL object / Struct field),
**triggers** (Interrupt source / Clock tick / command field / report → Task). No other edge kinds.

## §3. The flow a person reads (the canvas, left → right, the Purpose ▾ filter on top)

`Data` (Structs, HAL objects) → `Initialization` (started → Initialize… → finished) → `Priorities` (one card per Task: how + how urgent)
→ `Tasks` (cards, atoms inside) → `Up / Down` (Report, Command handler). The light test reads: LightState · Pin D6 · Pin D2 (interrupt) ·
Serial link · Clock tick → Init started → init serial → init tick → init light → init button → Init finished → [on interrupt INT0:
toggle] [on command led_on: apply] [every 100 ms: report] → toggle · apply · report. Five things to understand, not sixteen boxes.

The Initialization Purpose is always the first Purpose; "Un-used components on board" stays the honest bucket for HAL objects the board
offers and the firmware does not use.

## §4. Proof that nothing breaks (the rule for every slice)

The light test's firmware regenerated FROM the new states must produce the byte-identical `firmware.hex` sha (6e8d95d2…) and the same
`ScheduleSlot` rows the derivation already produces; the two light Purposes stay proven-on-twin; the sample graphs (sim-rig, button-clock)
regenerate identically. The states are a new FACE on the same atoms and the same glue; the generator gains an authored schedule only where
one is given (else it derives as today).

## §5. Slices

| slice | builds | proof |
|---|---|---|
| flow-0 | the **Initialization Purpose** on every firmware (rename `*-bring-up`; goal + boot acceptance), HAL atoms grouped into **HAL objects** as ROWS (no canvas yet), `Struct` = the wire class row gaining the command/report field marks | three graphs regenerate byte-identical; the Purpose list reads Initialization first |
| flow-1 | the canvas states 1–5 + 7–8 and the five columns; Task cards with atoms inside; the Purpose ▾ default = the whole flow | the light test reads as §3; screenshots at 1400/1900 |
| flow-2 | **Priority assignment** authored → generated schedule (bare C), the derived lanes as the agreement check, the RTOS mapping (task/queue) + the suggestion reading it | sim-rig's priority-inversion pair re-expressed as two assignments → "FreeRTOS advised" with the 12 160 → 2 098 µs evidence |
| flow-3 | **Make this a Struct** on any Polari object (promotion door + refusals) | a new object → a Struct → a Report task sends it from the twin |
| flow-4 | HAL object kinds × datasheet bindings (the isotopes attach to the HAL object card; a second board = a second set) | the C3's Serial link card shows its own registers |

## §6. Decisions (his; recommendation first)

- **D-flow-1 the word for the board's data object:** Struct (his word) · Wire class (today's) · State object → **Struct**, class `StructObject`; the wire contract stays its pinned form.
- **D-flow-2 priority form:** named levels interrupt / fast / normal / background (map to FreeRTOS numbers; bare C = order) · raw numbers → **named levels, numbers shown**.
- **D-flow-3 task bodies:** atoms stay parsed from C (today) · composed on the canvas (cmod-2) → **parsed now, cmod-2 after flow-2** (the Task card is where cmod-2 lands later).
- **D-flow-4 the HAL on the canvas:** one collapsed "Board support" node · HAL objects as first-class cards by kind → **first-class by kind** (a Pin and a Serial link are different things a person must set up).
- **D-flow-5 init order:** authored "then" edges only · derived from datasheet dependencies and advised → **authored, with a derived suggestion** ("serial needs the clock first").

## §7. Ties
HARDWARE_NOCODE_PLAN (RTOS kinds, the suggestion engine) · C_MODULARIZATION_PLAN cmod-2 · UNO_CORE_DEMO_PLAN §5j (Purposes), §5l (the app) ·
FIRMWARE_SOLUTION design (derived schedule D-fs-1 — flow-2 adds the authored form beside it, never replaces the derivation).
