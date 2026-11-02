# Bench Solution simulation: Systems, Solutions, Hardware Events and Struct States (bss) - plan 2026-11-01, event-driven 2026-11-02

The user (2026-11-01): "we need the different solutions setup and to make it feasible to have complete systems and solutions based off of those
systems. That way we can step through the simulation of an operation of a particular Bench Solution, and see the firmware, physics (thermal
simulation and electrical flow at appropriately small stepping, smaller than the smallest thing that needs to be seen same rule as an
oscilloscope)." Then: "A Bench Solution should show what its stepping time is and what variable was the lowest resolution time-step that caused
that overall resolution."

Then (2026-11-02), the redirect that shapes this plan: not continuous time. "Per scenario stepping and sampling. For each signal we want to analyze we
step through that signal at the time step we expect it to run its slowest step at. We do not want to sample continuous time, but just a snapshot of
time where signals were triggered and we adjust to what the slowest signal that was triggered is and how objects change and what secondary signals
are triggered." And the rule that makes it finite: "We both assume and enforce that all hardware changes cause state changes in either a struct on
the hardware or a struct on a bridge." Hardware Events are core: "we limit how many steps we take in total to only what is actually needed to test by
designing structs in a way that ties into the way the hardware is designed to make it testable via simulation."

Naming follows [systems-vs-solutions]: a System is a template with its choices still open; a Solution has every choice made, is bound to the other
Solutions, and can be simulated as a whole. A child row is named after its parent. Rows stay small and name each other; they never copy fields.
Bench Solutions are open air for now. A clip-on heat sink and a breadboard fan are allowed.

PLAN ONLY. The decisions in section 6 are the user's to make.

---

## 1. What exists (read 2026-11-01/02; reuse it, do not rebuild it)

| Piece | Where | What it is today | Its place here |
|---|---|---|---|
| `BenchSolution`, `BenchConditions` | board (cfg-0) | references to a bench, a hardware solution, a firmware solution, a thermal solution (''), and the conditions | the whole that an event is applied to |
| `FirmwareSolution` / `CGraph` | cmod | the specific build / the composed catoms with isotopes open | Firmware Solution / Firmware System, as-is |
| `HardwareSystem` + `SystemLink` | board | a SPECIFIC assembly (UNO + 16U2 + resistors + LED) | **misnamed by the rule**: it is a Hardware Solution (D-bss-1) |
| `HardwareSolution` | hwnocode | one no-code solution spanning hardware, bridge, backend, browser | **name clash**: cross-domain, not the bench's hardware (D-bss-1) |
| `StructObjectMap` | cmod (hsp-3a) | struct type -> Polari class, field -> attribute; bridges reference it | DEFINES which structs make up a Struct State |
| `CatomAssertion` | cmod (hsp-3a) | changes-struct / changes-field / reads-field / sends-to-bridge / receives-from-bridge / defines-role | says WHICH FIELDS the code can change and which pins a field drives: the raw material of the state map |
| `CatomVariable` | cmod (hsp-3d) | a HAL value that is also an assertion (BUTTON_PIN = PD2) | which lines are triggers and which are outputs |
| `TaskTrigger` | cmod | what starts a Task: boot, edge, period, command, message | the kinds of Hardware Event, already named |
| `CircuitState` / `CircuitStateTransition` | electrodevice (ptv) | one electrical state of the bench circuit; one move between two, by an external, firmware or lifecycle event, with measured timing | the ELECTRICAL half of a Struct State transition; kept, referenced |
| `Scenario` / `ScenarioStep` / `ScenarioRun` | firmwarefaults (sc) | FORCING recipes for faults (irq-at-pc, corrupt-word), before/after | the fault-forcing sibling; a Hardware Event run is NOT a fault and does not reuse these rows, but a Hardware Event can be a Scenario's starting point later |
| twin (simavr) + `twin_sessions.inject` | board | the same .hex free-running; `{"set":"PD2","level":0}`, `{"adc":0,"mv":750}`, `{"reset":1}`; pin edges streamed | the firmware engine and the ACTUATION door |
| ngspice shared library | electrodevice, pcb decks (tmp-1..5) | transient decks with `.temp` and per-part `temp=` | the electrical engine |
| thermal | pcb `PartThermalModel` (Cauer, tmp-3), electrothermal.settle | per-part temperature, the self-heating loop | the thermal engine |
| skew at the boundary | board clock_skew_run + uart_sampling (tmp-6) | UART bytes re-sampled bit by bit at each side's rate | the external-signal kind of event, already proven for one case |
| `ScopeChannel`, `WaveformCapture` | instruments (osc) | probes on bench lines; captures | the traces an event run records, per probed line |

## 2. The words

- **Struct State**: the values of every field of every mapped struct (the `StructObjectMap` rows) across the interconnected boards and bridges of one
  Bench Solution, at one instant. Two Struct States differ exactly when a field differs. It is the unit the whole system is reasoned in: "all hardware
  changes cause state changes in a struct on the hardware or a struct on a bridge" is both assumed and ENFORCED (section 4).
- **Hardware Event**: ONE trigger applied to a Bench Solution that is sitting in one Struct State, with nothing else happening, run until the Struct
  State has changed and settled. Three kinds (the user's a/b/c):
  - **(a) struct-map change**: a field is written from the Polari side and crosses a bridge (a SET_LED command, a SET_TIME). Source: `polari`.
  - **(b) actuation**: a sensor or trigger change a PERSON or the ENVIRONMENT can cause. Defined (the user asked for the non-obvious ones):
    - by a person: anything with a physical control on the bench: a button press or release, a switch, a potentiometer turned, the reset button, USB
      plugged or unplugged (power-on / boot), a bench jumper moved;
    - by the environment: anything a sensor on the bench reads from the room or the supply: ambient temperature (the TMP36's millivolts), light on a
      photoresistor, humidity, supply voltage sag or brown-out;
    - by time: a period elapsing (a `period` TaskTrigger firing, a watchdog). Neither person nor environment, but it is an actuation of the same shape, so
      it is listed here as source `time` rather than invented as a fourth kind.
    Source: `person` | `environment` | `time`.
  - **(c) external signal**: a defined test signal received from outside the Bench Solution: a frame arriving on the UART from another board or a test
    harness (bytes, at a rate, with a skew), a level or pulse on a line from another board. Source: `external`.
- **Hardware Event run**: one application of one event from one Struct State. It is **complete** when the Struct State has changed and then stayed
  still for the settle window (section 3). Its result is the new Struct State, recorded as a new scenario to evaluate.
- **Struct Transition**: "from this Struct State, this event leads to that Struct State". Defined MANUALLY (a person picks an initial state and a trigger
  and, optionally, the state they expect) or DERIVED from a run (hardware test or simulation). Status: expected (not yet run) | observed (a run agrees) |
  mismatch (a run disagrees, with the difference in words) | unreachable (the initial state was never reached).
- **State map**: the Struct States reached and the transitions between them, grown by exploration (section 4). Derived on read from the rows; never a
  stored copy.

## 3. Per-event stepping: each signal at its own step, the event as long as its slowest signal

Not continuous time. An event run samples only the signals the event triggers, each at its own step, for only as long as the slowest of them takes.

- **The triggered signals** are found, not guessed: from the trigger's line or field, follow the `CatomAssertion` chain (reads-field -> pins; changes-field
  -> sends-to-bridge) and the bench nets to the lines, fields and parts the event can reach. Secondary signals (the LED net after the button, the bridge
  frame after the struct write) are on that chain. Anything not on it is not sampled.
- **Each signal's step** comes from its smallest feature and the oscilloscope rule:
  - firmware: one CPU cycle, 1/f_clk (62.5 ns at 16 MHz): a floor, since firmware is discrete;
  - a digital or analog line: its fastest edge, `t_10-90 ~ 2.2 R C` from the driver's output resistance and the net's load, or a cited datasheet edge; then
    bandwidth `BW ~ 0.35 / t_rise` and step `<= t_rise / (0.35 k)`, k a labelled knob (D-bss-3). These are oscilloscope-practice numbers; cited before code;
  - a part's temperature: its smallest Cauer time constant / 10;
  - a bridge frame: one UART bit time at the link's rate (the tmp-6 re-sampler already works at this step).
- **Each signal's slowest step** (the user's words: "the time step we expect it to run its slowest step at") is how long it takes to finish: the debounce
  window, the LED's thermal settling, the bridge round trip. The event's **settle window** is the slowest of these among the triggered signals, times a
  margin knob (D-bss-2). The run is complete when no struct field has changed for one settle window.
- **The Bench Solution shows** (the user's second message), per event run and summarised over its events:
  - `step_s` and `step_set_by`: the finest step taken and the signal that asked for it, in words ("12.5 ns, D6 (LED line) rise 22 ns: R_out 25 Ohm x
    C 400 pF, k = 5");
  - `window_s` and `window_set_by`: how long the event took to settle and the signal that set that ("41 ms, the 40 ms debounce on PD2");
  - every triggered signal's own step and settle time beside them, so a person sees what would change if a signal were not on the chain.
  Both are derived, never typed; a change to a part, a configuration or the conditions re-derives them.
- **Feasibility**: a button-press event at 12.5 ns for 41 ms is ~3 million samples on ONE line and far fewer on the slow ones; most events are
  shorter. That is recordable. The total is bounded by the number of events x reached states, not by wall-clock time.

## 4. The state map: what can change, to what, and enforcing the rule

- **What can change, and to what (the start).** From the `StructObjectMap` fields and the `CatomAssertion` rows: each field the code can write and, by its
  C type, the values it can take: a bool or enum has every value listed; an integer or an analog-derived value cannot be enumerated, so it needs
  **declared samples** (`StructFieldSamples`: "temperature_c: 20, 25, 30, 85"; "adc0_mv: 700, 750, 800"). A field without samples blocks the events that
  reach it from running in simulation mode, and the block is said in words with the field named. Samples are declared by a person; a suggestion can be
  derived from the field's cited sensor range (knobs and suggestions).
- **The initial map** = the initial Struct State (boot) + every applicable Hardware Event: one per `TaskTrigger` edge line and command, one per actuation
  the bench offers (its controls and sensors, from the board pins and `CatomVariable` roles), one per declared external signal. Each is a row a person
  can see, remove or add to.
- **Exploration**: from each reached Struct State, run every applicable event (with each declared sample where the event carries a value); each run
  yields a transition and, when new, a new state to explore. Bounded by a depth / state-count knob (D-bss-5); unexplored states are listed, not hidden.
- **Enforcing the rule.** A run whose trigger provably reached the firmware (a pin edge was delivered, a frame was received) yet changed NO struct field is
  a FINDING on the Firmware Solution: "the press on PD2 changed no struct: the button is not testable through the structs". It is reported with the
  trace, and the Firmware Solution is marked `not-struct-testable` for that event until a struct carries the change. This is how structs are driven to be
  designed the way the hardware is designed.
- **Manual transitions**: a person picks an initial state (an existing one, or one they compose from field values) and a trigger, optionally the expected
  end state; it is evaluated like any other, and a mismatch is said in words with the differing fields.
- **From a hardware test**: a twin record or a real-board run (a `ScenarioRun` observed on hardware, a bridge log) is read into a transition with `basis`
  `hardware`; simulation runs are then compared against it.

## 5. The rows (small, by level, referencing)

| Level | Row | Its one concern | References |
|---|---|---|---|
| template | `HardwareSystem` (new meaning, D-bss-1) | a board family + a circuit with part choices open | - |
| template | `CGraph` (exists) | the Firmware System | - |
| template | `ThermalSystem` | the open-air template: allowed mitigations (none / clip-on sink / breadboard fan), ambient range | - |
| template | `BenchSystem` | which Hardware, Firmware and Thermal Systems compose one bench concept | the three Systems |
| solution | `HardwareSolution` (D-bss-1) | the specific boards, parts, nets (what `HardwareSystem` holds today) | its `HardwareSystem` |
| solution | `FirmwareSolution` (exists) | the specific graph + board + configurations -> one .hex | its `CGraph` |
| solution | `ThermalSolution` | the specific mitigations (a sink part with cited Rth, a fan with cited airflow, or none) | its `ThermalSystem`, `PartThermalModel` rows |
| solution | `BenchSolution` (exists; gains `system`) | the three Solutions bound + the conditions | its `BenchSystem`, the three Solutions, `BenchConditions` |
| definition | `StructFieldSamples` | the declared test values of one non-enumerable field | the `StructObjectMap`, the field |
| definition | `HardwareEvent` | one trigger: kind (struct-change / actuation / external-signal), source (polari / person / environment / time / external), what (the line, field or frame), its arguments | its `BenchSolution`; the `TaskTrigger` / `CatomVariable` / `BridgePath` it came from |
| state | `StructState` | one snapshot: the field values, a digest | its `BenchSolution`; the `StructObjectMap` rows |
| scenario | `StructTransition` | ONE EDGE: from-state + event -> to-state; basis (manual / simulation / hardware); status (expected / observed / mismatch / proven / unreachable / blocked) | `StructState` x2, `HardwareEvent` |
| scenario | `StructTransitionCheck` | one expectation on one edge: a field exact / within a tolerance / in a range, or a timing bound on the edge | its `StructTransition`, the field |
| run | `HardwareEventRun` | one application: from-state, to-state, complete?, `step_s` + `step_set_by`, `window_s` + `window_set_by`, the .hex sha256, finding words | its `HardwareEvent`, the `StructTransition` it produced, its `CircuitStateTransition` |
| run | `HardwareEventRunSignal` | one triggered signal in one run: its step, its settle time, where its trace is | its `HardwareEventRun`; the `WaveformCapture` |

**Whole**: a Bench Solution is whole only when each of its three Solutions exists and is complete and names a System the Bench System also names.
What is missing is said in words and derived on read.

## 5b. The views: a topology of Struct States and Hardware Events (the user, 2026-11-02)

"We need some dedicated views central to Hardware Events and Structs for this, to make a sensible way for people and AI to define topologies of
Struct states and Hardware Event States so they can be visualized as a topology via D3 and be clicked into and named."

**What exists (read 2026-11-02):** the no-code canvas (`components/custom-no-code`, d3: `no-code-state-instance-d3`, a state manager, a context menu, a
tool sidebar) already draws NODE KINDS whose drawing reads and writes the row itself ("the drawing is never a second copy": `PurposeTriggerState`,
hwnocode's `HardwareSubgraph` / `HardwareInterface`). The deployment `topology-graph-view` is specific to hosts and modules and is not reused. The pin
view (pv) is the one sanctioned custom d3 component for pins and stays about pins.

**The topology.** Nodes are Struct States; edges are Hardware Events (a `StructTransition` is one edge: from-state, event, to-state). The same drawing
serves three jobs:
- **Define**: a person or an AI places a Struct State node (composes its field values, or picks a reached one), places a Hardware Event between two
  nodes, and NAMES both. Naming is the point: `StructState.title` ("light off, idle") and `HardwareEvent.title` ("press the button") are a person's
  words over a derived digest; an unnamed node shows its differing fields instead, until named.
- **Explore**: states and transitions the exploration (section 4) reached appear in the same topology, marked derived; the person names them or
  leaves them.
- **Read a run**: click an edge -> the `HardwareEventRun` rows for it: from / to, `step_s` + `step_set_by`, `window_s` + `window_set_by`, each triggered
  signal and its trace (the osc chart), the finding words. Click a node -> the Struct State's fields, side by side with the state it was reached from
  (differences first), and the events applicable from it. Click again to deselect (click-toggle). Status is shown by theme tokens (expected / observed /
  mismatch / unreachable / blocked-for-samples), never by raw JSON.

**Where it lives.**
- Two new NODE KINDS on the no-code canvas: `struct-state` and `hardware-event`, categories **Struct** and **Hardware Event**; authored through a
  `bench_events_nocode` custom (as `purpose_nocode` does), reading and writing the rows of section 5. A Bench Solution's topology is one canvas
  (`SolutionDefinition` of kind `bench-events`, named by the Bench Solution); the Mission / Workbench pages link to it.
- Two dedicated pages beside it, both configured tables + the canvas, no new engines:
  - **Hardware Events** (`/display/hardware-events`): the events of a Bench Solution by kind and source, their runs, the findings ("changed no struct");
    a form to add a manual event or a manual transition.
  - **Structs** (`/display/structs`): the `StructObjectMap` rows, their fields with what can change them (the assertions), the declared samples and
    the fields still blocking simulation; the states reached per Bench Solution.
- For an AI: the same rows through the doors (`/api/board/bench-solutions/{name}/events|states|transitions`), so an agent defines a topology by writing
  the rows the canvas reads; nothing is drawn by hand twice.

**Testing and simulation per edge (the user, 2026-11-02: "we will also want testing and simulation per topology edge").** The edge is the unit of
test. A `StructTransition` carries its own expectation and its own runs, so one edge can be run, re-run after a rebuild, and compared across engines
without touching the rest of the topology:
- **The expectation** is the to-state plus, per field, an optional `StructTransitionCheck`: exact for a bool or enum; a tolerance or a range for an
  integer or analog-derived field ("temperature_c within 0.5 of 25"); a timing bound on the edge itself ("settles within 60 ms", checked against
  `window_s`). A check without a tolerance on an analog field is refused in words.
- **Simulate this edge**: `POST .../transitions/{name}/run` applies the event from the from-state in the twin + circuit (+ Cauer) and writes one
  `HardwareEventRun` naming the edge; the edge's status becomes observed or mismatch with the differing fields and the failed checks in words. Variants
  of the same edge run per declared sample of any field the event carries (one run per sample, all named by the edge).
- **Test this edge against hardware**: a run with basis `hardware` (a twin-session record or a real-board log read in) is kept beside the simulation
  runs of the same edge; the edge shows both and their difference (fields, and `window_s` simulated vs measured). Matching hardware is what promotes an
  edge from observed to **proven**.
- **Runs in bulk** are just edges: run every edge out of one state; run every edge of the topology; after a rebuild, run only the edges whose event chain
  touches the changed catom (bss-4). Each result lands on its own edge; there is no topology-level verdict other than the count of edges by status.
- On the canvas, an edge shows its status by theme token, and clicking it offers run / test / the runs so far; the Hardware Events page lists edges by
  status with the same actions.

**Making it obvious what was tested (the user, 2026-11-02: "views and visualization that make it obvious what was tested").** The topology IS the
coverage map, and what was NOT tested is drawn as loudly as what was:
- **On the canvas**: every edge by status, through theme tokens: proven (hardware agrees), observed (simulation only), mismatch, expected (never run,
  drawn dashed), blocked (a field without samples, drawn dashed with the field named on hover), unreachable. Every node: reached by a proven edge /
  by simulation only / defined but never reached. Hovering an edge says in one line what its runs covered: "3 runs: samples 700 / 750 / 800 mV, simulated;
  no hardware run". The legend is the status list with counts; clicking a status in the legend dims everything else (click-toggle).
- **A coverage strip** above the canvas and at the top of the Hardware Events page, derived on read: edges by status (n proven / observed / mismatch /
  untested / blocked); events by kind and source with how many of each were ever run; struct fields covered (changed by at least one observed edge) vs
  never changed by any edge; samples declared vs used. Each count is a filter into the tables below it.
- **Per edge, the test card**: which checks it has and which passed; which samples it ran with and which engines (twin, ngspice, Cauer; hardware);
  the .hex sha256 the runs used, and whether the current Firmware Solution's build is a different one (then "stale: tested on a previous build").
- **Per Firmware Solution, assertion coverage**: each `CatomAssertion` of kind changes-field / sends-to-bridge / receives-from-bridge is covered when
  an observed or proven edge exercised it (the field changed, the frame crossed); the uncovered assertions are listed by atom. This ties coverage
  back to the code's own claims, and a Firmware Solution shows "n of m assertions exercised" beside its proof status.
- **Per Bench Solution, the untested list**, in words, first: unexplored states (the exploration bound), blocked edges and the field that blocks each,
  events never run, assertions never exercised, edges tested on a stale build. An empty list is the only green.

**Decision for the user (D-bss-7):** (a, recommended) node kinds on the no-code canvas (the one canvas; drawings authored from rows; the d3 is there);
(b) a new dedicated d3 component like the pin view: an explicit exception, justified only if the canvas cannot show a few hundred states legibly: the
layout for that scale (clustered by the fields that differ) would be the reason.

## 6. Decisions (recommended option first; each is the user's)

- **D-bss-1 - the two clashing names.** (a, recommended) board `HardwareSystem` -> `HardwareSolution`; hwnocode `HardwareSolution` -> `CrossDomainSolution`
  (its own docstrings' phrase); `HardwareSystem` freed for the template. ~21 non-test references + stored-row convergence. (b) Keep both; add
  `BenchHardwareSystem` / `BenchHardwareSolution`. Nothing moves; the rule stays broken twice.
- **D-bss-2 - the settle margin.** The run is complete after no struct field changed for the slowest triggered signal's settle time x m. (a, recommended)
  m = 2, a labelled knob. (b) m = 1 (tight; a late secondary signal could be missed).
- **D-bss-3 - the oscilloscope-rule k.** (a, recommended) 5, a labelled knob. (b) 10.
- **D-bss-4 - cfg-4** (stepping with replay in CATOM_CONFIG_PLAN). (a, recommended) It merges into bss-4: a configuration change = rebuild + re-run the
  transitions whose event chain touches the changed catom.
- **D-bss-5 - the exploration bound.** (a, recommended) depth 4 from boot and 64 states, both knobs; the unexplored listed. (b) exhaustive, no bound.
- **D-bss-6 - where a run's traces live.** (a, recommended) `WaveformCapture` rows (the osc arc's, so the scope views show them unchanged). (b) files
  beside the run.

## 7. Phases (commit series on dev-electronics; selftests green; no deploy)

| Phase | What | Proof |
|---|---|---|
| bss-0 | names (D-bss-1); the template rows `HardwareSystem` / `ThermalSystem` / `BenchSystem`; `ThermalSolution`; each Solution names its System; the whole check | `uno-light-bench` / `uno-light-on-desk` whole; remove the Thermal Solution -> "not whole: no Thermal Solution", in words |
| bss-1 | the state map's start: `StructState` from the maps; "what can change and to what" from the assertions; `StructFieldSamples` and the block in words; the initial `HardwareEvent` rows derived from `TaskTrigger` / `CatomVariable` roles / `BridgePath` + manual | uno-light: boot state; events = press PD2, release PD2, SET_LED command, TMP36 level (blocked until adc0_mv samples are declared), reset; the words |
| bss-2 | ONE event run: apply the trigger to the twin + circuit (+ Cauer), sample each triggered signal at its own step, settle, record from -> to, `step_set_by`, `window_set_by`; the "changed no struct" finding | press PD2 from boot -> LightState.led_on 0 -> 1, bridge report seen; step set by D6's edge, window by the debounce; a build with the struct write removed -> the finding |
| bss-3 | the edge as the unit of test: `StructTransitionCheck`, run one edge / every edge out of a state / every edge; hardware runs beside simulation runs -> proven; exploration (bounded); manual transitions | the uno-light map: boot -> press -> release -> SET_LED ...; a manual edge with a wrong expected state -> mismatch naming the field; an analog check without a tolerance refused; a twin-record run on the press edge -> proven |
| bss-4 | configuration change = rebuild + re-run the affected transitions (cfg-4, D-bss-4) | change the debounce -> new .hex sha, only the PD2 transitions re-run, their `window_set_by` changed |
| bss-5 | the topology (section 5b): node kinds `struct-state` / `hardware-event` on the no-code canvas, authored from the rows; naming; click into a node / an edge | the uno-light canvas: boot -> press -> release drawn from the rows; name a state -> the row's title; an AI writes a transition through the door -> it appears |
| bss-6 | coverage made obvious: edge / node status on the canvas, the coverage strip, the per-edge test card, assertion coverage per Firmware Solution, the untested list; the Hardware Events and Structs pages + the Bench Solution page: whole check, per run the step and window with what set them, traces through the scope views (theme tokens, click-toggle, no raw JSON) | the Chrome pass is owed and needs a deploy, which is the user's call |

## 8. Rules this plan keeps
Every number is derived or cited, otherwise a labelled knob. Established open solvers only (simavr, ngspice, the Cauer ladder). Small rows that reference
each other; children named after their parent. The state map and the step are derived, never typed. No real identifiers. dev-electronics only. No deploys.
