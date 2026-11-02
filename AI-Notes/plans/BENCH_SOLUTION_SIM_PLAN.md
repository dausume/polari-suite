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

## 2. The words (corrected 2026-11-02 twice; the second: "edges should always be ending with a defined struct change")

- **Struct State**: the values of every field of every mapped struct (the `StructObjectMap` rows) across the interconnected boards and bridges of one
  Bench Solution, at one instant. "All hardware changes cause state changes in a struct on the hardware or a struct on a bridge" is assumed and
  ENFORCED (section 4).
- **The root**: the hardware as delivered, BEFORE it is flashed: the chip at reset (inputs, tri-stated, reset values; the pin view's blank state), the
  bootloader, no structs yet. Every node branches out from it (the user: "all of these nodes to branch out from the initial state of the hardware
  before it is flashed"). The first edge is the flash (the existing `ConfigurationEvent` kind flash, confirmed by `SimInstallConfirmation`), and its
  node is boot: every struct at its init value.
- **Node**: a set of END-STATE REQUIREMENTS on the structs, and a name (the user, 2026-11-02: "nodes have matching end-state struct set requirements
  ... only specific values or value ranges or sets that need to be met for something to be considered ending in that node's state"). Each requirement
  names one field and what it must satisfy: an exact value (`led_on = 1`), a range (`temperature_c in 20..30`), or a set of allowed values
  (`state in {armed, firing}`). A field the node does not name is don't-care. A node is NOT a snapshot: the full Struct State a run has when it lands
  there is recorded per run, and may differ between paths; only the requirements must match. A node may or may not carry **collaterals** (section 2b).
  Per node, two things are declared: its **requirements** and the **Catom executions** expected to bring the structs to meet them (the atoms, with the
  isotopes the Firmware Solution's configuration selected).
- **Edge**: what moves from one node to the next. Two kinds:
  - **trigger edge**: a Hardware Event starts it: an actuation (person / environment / time) or an external signal from one of various sources
    (a Polari command through a bridge, another board, a harness, a network message to a bridge);
  - **cascade edge**: no outside trigger: the previous node's change makes code run that produces the next change (`button_down` -> `led_on`;
    `command` -> `led_on` -> a report frame leaves on the bridge). A bridge change is a node like any other, reached by a cascade edge.
  An edge ALWAYS ENDS when its node's requirements are all met at once. Never by a clock. A guard time (D-bss-2) only turns a run into "not reached"
  with its trace; a struct change on a field the node requires that lands OUTSIDE its requirement (`led_on` required 1, became 0) is a **divergence**
  (D-bss-10), offered as a new node for a person to accept and name, never silently absorbed. Changes on don't-care fields are recorded, not judged.
- **Path**: the ordered edges from the root to a node. A node can be reached by several paths. **Every test of a node starts at the root and replays
  a path** (the user: "whenever testing a new node we go from the beginning in terms of struct state so we have a coherent and complete state context
  for the bench"); nothing is resumed from a snapshot. The **first test of a node uses the fastest plausible path**: the fewest edges whose nodes are
  all defined, preferring already-confirmed nodes; other paths can be chosen and tested after, each recorded on its own. The full Struct State at the
  node may differ by path (the don't-care fields); each run records its own, and the node shows them side by side.
- **Confirmation**: a node is confirmed, for one path and one build, when a run from the root met its requirements, the declared Catom executions
  were observed running (the twin's trace of symbols), and its collaterals measured within bounds. Confirmed by simulation (engine named), by hardware
  (a record read in), or by a person (attested in words, like `SimInstallConfirmation`); a confirmation is VOIDED, never deleted, when the build sha256
  or the node's definition changes. The user: "we will need confirmations of things being completed."
- **Test profile** (section 3b): what one test monitors; definable manually.

### 2b. Collaterals
A collateral is a measurable effect of a node's change OUTSIDE the structs: a pin level, a net's current, the LED's light (forward current), a part's
temperature rise, a frame's bytes on the wire, a timing from the edge's start to the change. Each node says whether it has collaterals to measure:
none (a pure data change: the twin alone proves it) or declared rows, each naming the signal, the engine that measures it (twin pin trace, ngspice,
Cauer; a scope on hardware) and its bound. Collaterals are what the physics engines are for. D-bss-9 proposes deriving them where a changed field
drives a pin or crosses a bridge, marked derived, for a person to confirm, edit or set to none.

## 3. Stepping per node: the Catoms and isotopes decide it

"The Catoms and isotopes selected for a node determine what stepping we do in the scenario simulation." Not continuous time: an edge's run steps
finely only where its node's executions and collaterals need it, and the firmware runs free between.

- **Each Catom execution at a node brings a step rule from its isotope** (an `IsotopeStepRule`, derived or cited, per `IsotopeVariant`):
  - gpio-poll: the poll period or the main-loop iteration time (measured on the twin: cycles per loop);
  - pin-change-interrupt / external interrupt: cycle level around the edge (one CPU cycle, 1/f_clk; ISR latency measured);
  - uart (send / receive): one bit time at the link's rate (tmp-6's bit-level re-sampler already does this);
  - pwm drive: the PWM period / k;
  - analog-threshold / adc read: the ADC conversion time (13 ADC clocks on the 328P: cited);
  - timer / period: the timer tick.
  A rule is a labelled knob until its number is derived (measured on the twin) or cited (the datasheet), and says which.
- **Each collateral brings a physics step rule**: a line's fastest edge (`t_10-90 ~ 2.2 R C` or a cited edge) through the oscilloscope rule
  (`BW ~ 0.35 / t_rise`, step `<= t_rise / (0.35 k)`, k a knob, D-bss-3; cited before code); a part's temperature at its smallest Cauer time constant / 10;
  a frame at one bit time.
- **The node's step** is the finest step its executions and collaterals ask for; **the edge's duration** is how long it took to encounter the change
  (not a settle window). The Bench Solution and the node show (the user's ask): `step_s` + `step_set_by` ("12.5 ns, D6 rise 22 ns, k = 5" or "62.5 ns,
  the pin-change isotope of read-button") and `duration_s` + `duration_set_by` ("41 ms, the 40 ms debounce in read-button:gpio-poll"), plus every
  execution's and collateral's own rule beside them. Derived, never typed; a configuration or isotope change re-derives them (cfg: an isotope changes the
  code, a configuration the values; both change the stepping).
- **Feasibility**: a path is a handful of edges; each edge steps finely only around its executions and collaterals; the twin runs free elsewhere. The
  total is bounded by nodes x paths tested, not by wall-clock time.

## 3b. Test profiles: what is monitored

A **TestProfile** is a named, reusable answer to "what do we watch, and how finely": `TestProfileItem` rows, each one of
- a **signal** (a line, a net, a part's temperature) with its step rule and the engine that samples it;
- a **datum** (a struct field, a bridge frame, a Polari attribute), recorded when it changes, not on a clock;
- a **timing** between two items, with a bound.

Three sources, the same rows either way (D-bss-8); the user: "we should have a way to define a TestProfile manually":
1. **Manual**: a person composes a profile item by item and names it ("button-to-light", "bridge round trip", "thermal only"). Assignable to any node
   whose executions and collaterals can reach the items (an unreachable item is refused in words). Reusable across nodes and Bench Solutions with the
   same structs.
2. **Derived default per node**: the node's change-set fields, its executions' symbols, its declared collaterals, the edge's trigger. Named
   `<node>:derived`; what a node runs with when nobody chose.
3. **Suggested from the node's checks**: field-only checks suggest a data-only profile; a timing check suggests the two ends and the lines between; a
   thermal collateral suggests the part's temperature and the net's current. Shown, never applied silently.

A run names its profile; the coverage views (5b) say per node what the profile left unwatched. A node whose collaterals are not all monitored is
observed at most, never confirmed.

## 4. Defining the topology, exploring it, and enforcing the rule

- **Definition first.** People and AI define nodes branching from the root: the requirements, the executions, the collaterals (or none), the edge that
  reaches it (trigger or cascade) and a name. The AI defines through the same doors the canvas writes. Exploration (below) only PROPOSES nodes.
- **What can change, and to what.** From the `StructObjectMap` fields and the `CatomAssertion` rows: each field the code can write and, by its C type,
  the values it can take: a bool or enum enumerates; an integer or analog-derived field needs **declared samples** (`StructFieldSamples`: "adc0_mv: 700,
  750, 800"). A node whose requirements name a value of such a field without a sample is blocked, in words, naming the field (a RANGE requirement on such a field
  is not blocked: the run's value is judged against the range). Suggestions for samples
  come from the field's cited sensor range.
- **The offered edges** from any node: one trigger edge per actuation the bench offers (its controls and sensors: board pins and `CatomVariable` roles;
  `TaskTrigger` edge / period / boot rows name them), one per external source (`TaskTrigger` command / message rows, each `BridgePath`, each declared
  harness signal); and the cascade edges the assertions predict (changes-field -> reads-field -> changes-field / sends-to-bridge). The predicted
  changes of each are shown before any run, so a person can turn them into a node's requirements.
- **Exploration (secondary, bounded, D-bss-5)**: from a confirmed node, run each offered edge from the root along the node's fastest path; a run whose
  changes meet no defined node's requirements is PROPOSED as a node (its requirements = the exact changed values, to be loosened by a person) (derived, unnamed) for a person to accept or discard. Unexplored edges are listed.
- **Enforcing the rule.** A trigger edge whose trigger provably reached the firmware (the pin edge delivered, the frame received) yet encountered NO
  struct change within the guard is a FINDING on the Firmware Solution: "the press on PD2 changed no struct: the button is not testable through the
  structs", with the trace; the Firmware Solution is marked `not-struct-testable` for that trigger until a struct carries the change.
- **From a hardware test**: a twin-session record or a real-board run (a `ScenarioRun` observed on hardware, a bridge log) is read in as a path run with
  basis `hardware`; its confirmations sit beside the simulation's.

## 5. The rows (small, by level, referencing; children named after their parent)

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
| catalogue | `IsotopeStepRule` | the step an isotope asks for (kind, value, basis: derived / cited / knob) | its `IsotopeVariant` |
| definition | `StructFieldSamples` | the declared test values of one non-enumerable field | the `StructObjectMap`, the field |
| definition | `HardwareEvent` | one trigger: kind (actuation / external-signal), source (person / environment / time / polari / board / harness / network), what, its arguments | its `BenchSolution`; the `TaskTrigger` / `CatomVariable` / `BridgePath` it came from |
| topology | `StructNode` | ONE NODE: its title, kind (root / boot / state), whether it has collaterals | its `BenchSolution` |
| topology | `StructNodeRequirement` | one end-state requirement: a field and what it must satisfy (exact value / range / set of allowed values) | its `StructNode`; the `StructObjectMap` field |
| topology | `StructNodeExecution` | one Catom execution expected at the node (atom, the isotope as configured, order) | its `StructNode`; the `CFunctionAtom`, `IsotopeVariant`, `CatomAssertion` |
| topology | `StructNodeCollateral` | one measurable effect outside the structs: the signal, the engine, the bound | its `StructNode`; the pin / net / `PartThermalModel` |
| topology | `StructEdge` | ONE EDGE: from node, to node, kind (trigger / cascade / flash) | `StructNode` x2; the `HardwareEvent` when trigger; the `ConfigurationEvent` when flash |
| topology | `StructEdgeCheck` | one expectation on an edge beyond the requirements: a field tolerance / range, a timing bound | its `StructEdge`, the field or collateral |
| topology | `StructNodePath` | one ordered path root -> node (edges in order, length, fastest?) | its `StructNode`; the `StructEdge` rows |
| definition | `TestProfile`, `TestProfileItem` | what one test monitors (3b) | its `BenchSolution` ('' when shared); the line / field / collateral per item |
| state | `StructState` | the full snapshot a run had when it met a node's requirements: field values, digest (may differ by path: the don't-care fields) | its `StructNodeRun` |
| run | `StructNodeRun` | one test of a node: from the root along one path, with one profile, on one .hex sha256; outcome (reached / not reached / diverged / blocked); `step_s` + `step_set_by`, `duration_s` + `duration_set_by` | its `StructNode`, `StructNodePath`, `TestProfile` |
| run | `StructNodeRunEdge` | one edge as it ran in that test: requirements met at cycle N, duration, the executions observed (symbols), the collaterals measured vs bounds, divergence words | its `StructNodeRun`, `StructEdge`; the `CircuitStateTransition` |
| run | `StructNodeRunSignal` | one monitored signal's trace in that test | its `StructNodeRun`; the `WaveformCapture` |
| evidence | `StructNodeConfirmation` | one confirmation: node, path, by (simulation engine / hardware record / person), the run, the build sha256; state confirmed / voided (why) | its `StructNode`, `StructNodePath`, `StructNodeRun` |

**Whole**: a Bench Solution is whole only when each of its three Solutions exists and is complete and names a System the Bench System also names.
What is missing is said in words and derived on read.

## 5b. The views: a topology of Struct States and Hardware Events (the user, 2026-11-02)

"We need some dedicated views central to Hardware Events and Structs for this, to make a sensible way for people and AI to define topologies of
Struct states and Hardware Event States so they can be visualized as a topology via D3 and be clicked into and named."

**What exists (read 2026-11-02):** the no-code canvas (`components/custom-no-code`, d3: `no-code-state-instance-d3`, a state manager, a context menu, a
tool sidebar) already draws NODE KINDS whose drawing reads and writes the row itself ("the drawing is never a second copy": `PurposeTriggerState`,
hwnocode's `HardwareSubgraph` / `HardwareInterface`). The deployment `topology-graph-view` is specific to hosts and modules and is not reused. The pin
view (pv) is the one sanctioned custom d3 component for pins and stays about pins.

**The topology.** One tree-like graph from the ROOT (the unflashed hardware) through the flash edge to boot and out: nodes are `StructNode`s (a defined
requirements, named), edges are `StructEdge`s (trigger, drawn with the Hardware Event's source; cascade, drawn thin; flash). A node with collaterals carries
small marks (measured / unmeasured / none declared). The path being tested is highlighted root -> node. The same drawing serves three jobs:
- **Define**: a person or an AI adds a node out of an existing one: its requirements (fields with exact / range / set), its executions (picked from the catoms the assertions say can make
  that change), its collaterals or none, the edge kind (a trigger from the offered Hardware Events, or a cascade), and NAMES it. Naming is the point:
  `StructNode.title` ("light on") and `HardwareEvent.title` ("press the button") are a person's words; an unnamed node shows its requirements until named.
- **Explore**: nodes the exploration (section 4) proposed appear dashed and unnamed; the person accepts and names them, or discards them.
- **Read a run**: click a node -> its confirmations (by path, by engine / hardware / person, on which build; voided ones greyed), its runs with
  `step_s` + `step_set_by` and `duration_s` + `duration_set_by`, its requirements, and the full Struct State each run had on arrival beside its parent's (the required fields first), and the edges offered
  from it. Click an edge -> its checks and its `StructNodeRunEdge` rows: reached at which cycle, the executions observed, the collaterals measured, the
  traces (the osc chart), divergence words. Click again to deselect (click-toggle). Status is shown by theme tokens (expected / observed /
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

**Testing and simulation per edge (the user, 2026-11-02: "we will also want testing and simulation per topology edge").** The node, reached by an edge along a path, is the
unit of test; the edge carries the checks. One node can be tested, re-tested after a rebuild, and compared across engines without touching the rest:
- **The expectation** is the node's requirements plus, per field, an optional `StructEdgeCheck`: exact for a bool or enum; a tolerance or a range for an
  integer or analog-derived field ("temperature_c within 0.5 of 25"); a timing bound on the edge itself ("reached within 60 ms", checked against
  `duration_s`). A check without a tolerance on an analog field is refused in words.
- **Test this node**: `POST .../nodes/{name}/run {path?, profile?}` replays from the root along the fastest plausible path (or the named one) in the
  twin + circuit (+ Cauer), stepping at each node as its executions and collaterals ask, and writes one `StructNodeRun` with a `StructNodeRunEdge` per
  edge; reached with every check met -> a `StructNodeConfirmation` by simulation; otherwise not reached / diverged / blocked, in words. One run per
  declared sample where the path's trigger carries a value.
- **Test this node against hardware**: a run with basis `hardware` (a twin-session record or a real-board log read in) is kept beside the simulation runs
  of the same node and path; the node shows both and their difference (fields, `duration_s` simulated vs measured) and gains a hardware confirmation.
- **Runs in bulk** are just nodes: every node out of one node; every node of the topology (each from the root along its fastest path; shared prefixes are
  replayed, not snapshotted); after a rebuild every confirmation on that build is voided and the nodes whose executions touch the changed catom are
  re-tested first (bss-4). There is no topology-level verdict other than the count of nodes by confirmation state.
- On the canvas, a node shows its confirmation state by theme token (confirmed by simulation / by hardware / by a person; voided; diverged; not reached;
  blocked; never tested), and clicking it offers test / the path / the runs so far; the Hardware Events page lists nodes by state with the same actions.

**Making it obvious what was tested (the user, 2026-11-02: "views and visualization that make it obvious what was tested").** The topology IS the
coverage map, and what was NOT tested is drawn as loudly as what was:
- **On the canvas**: every node by confirmation state, through theme tokens: confirmed by hardware / by simulation only / by a person only; voided (the
  build changed); diverged; not reached; blocked (a field without samples, dashed, the field on hover); never tested (dashed). Every edge by whether any
  confirmed run crossed it. Hovering a node says in one line what its runs covered: "3 runs by path 2: samples 700 / 750 / 800 mV, simulated; no hardware
  run; collateral D6 current unmeasured". The legend is the state list with counts; clicking a state dims everything else (click-toggle).
- **A coverage strip** above the canvas and at the top of the Hardware Events page, derived on read: nodes by confirmation state (n confirmed by hardware / by simulation /
  voided / diverged / not reached / blocked / never tested), paths tested per node; events by kind and source with how many of each were ever run; struct fields covered (changed by at least one observed edge) vs
  never changed by any edge; samples declared vs used. Each count is a filter into the tables below it.
- **Per node, the test card**: its paths and which were tested; which checks passed; which executions were observed; which collaterals were measured
  and which not; which samples and engines (twin, ngspice, Cauer; hardware); the .hex sha256 of each confirmation, voided ones greyed with why.
- **Per Firmware Solution, assertion coverage**: each `CatomAssertion` of kind changes-field / sends-to-bridge / receives-from-bridge is covered when
  a confirmed node's run exercised it (the field changed, the frame crossed); the uncovered assertions are listed by atom. This ties coverage
  back to the code's own claims, and a Firmware Solution shows "n of m assertions exercised" beside its proof status.
- **Per Bench Solution, the untested list**, in words, first: nodes never tested, nodes with only voided confirmations, nodes confirmed by one path only when
  others exist, blocked nodes and the field that blocks each, collaterals never measured, Hardware Events never used by any edge, assertions never
  exercised, proposed nodes not yet accepted. An empty list is the only green.

**Decision for the user (D-bss-7):** (a, recommended) node kinds on the no-code canvas (the one canvas; drawings authored from rows; the d3 is there);
(b) a new dedicated d3 component like the pin view: an explicit exception, justified only if the canvas cannot show a few hundred states legibly: the
layout for that scale (clustered by the fields that differ) would be the reason.

## 6. Decisions (recommended option first; each is the user's)

- **D-bss-1 - the two clashing names.** (a, recommended) board `HardwareSystem` -> `HardwareSolution`; hwnocode `HardwareSolution` -> `CrossDomainSolution`
  (its own docstrings' phrase); `HardwareSystem` freed for the template. ~21 non-test references + stored-row convergence. (b) Keep both; add
  `BenchHardwareSystem` / `BenchHardwareSolution`. Nothing moves; the rule stays broken twice.
- **D-bss-2 - the guard.** An edge ends only on its change; the guard is how long a run waits before saying "not reached". (a, recommended) 2 x the
  slowest step rule among the node's executions (the debounce, the period, the bridge round trip), a labelled knob. (b) a fixed time per Bench Solution.
- **D-bss-3 - the oscilloscope-rule k.** (a, recommended) 5, a labelled knob. (b) 10.
- **D-bss-4 - cfg-4** (stepping with replay in CATOM_CONFIG_PLAN). (a, recommended) It merges into bss-4: a configuration change = rebuild + re-run the
  transitions whose event chain touches the changed catom.
- **D-bss-5 - the exploration bound** (exploration only proposes nodes). (a, recommended) one edge out from confirmed nodes, up to 64 proposals, knobs;
  the unexplored listed. (b) deeper, exhaustive.
- **D-bss-6 - where a run's traces live.** (a, recommended) `WaveformCapture` rows (the osc arc's, so the scope views show them unchanged). (b) files
  beside the run.

- **D-bss-8 - how test profiles are defined.** (a, recommended) all three of 3b: a derived default per edge, named saved profiles assignable to edges,
  purpose-based suggestions never applied silently. (b) only derived defaults (nothing to name or reuse). (c) only hand-made profiles (every edge needs one
  before it runs).
- **D-bss-10 - divergence.** A run in which a required field lands outside its requirement. (a, recommended) outcome diverged; the reached values are
  proposed as a new node off the same parent for a person to accept, loosen and name; the intended node stays unconfirmed. (b) a plain failure.
- **D-bss-9 - collaterals by default.** (a, recommended) every change node whose field drives a pin (a reads-field assertion) or crosses a bridge gets its
  collaterals DERIVED (the pin's level and net, the frame's bytes) and marked derived; a person confirms, edits or sets none. (b) none until declared.

## 7. Phases (commit series on dev-electronics; selftests green; no deploy)

| Phase | What | Proof |
|---|---|---|
| bss-0 | names (D-bss-1); `HardwareSystem` / `ThermalSystem` / `BenchSystem`; `ThermalSolution`; each Solution names its System; the whole check | `uno-light-bench` / `uno-light-on-desk` whole; remove the Thermal Solution -> "not whole: no Thermal Solution", in words |
| bss-1 | the topology's start: the root (unflashed), the flash edge, the boot node from the structs' init values; `StructNode` / `Requirement` / `Execution` / `Collateral`, `StructEdge`, `StructNodePath`; `IsotopeStepRule` rows for the isotopes the UNO light uses (derived on the twin or cited); the offered edges and predicted requirementss from the assertions; `StructFieldSamples` and the block in words; `HardwareEvent` rows | uno-light: root -> flash -> boot; offered: press PD2, release PD2, SET_LED, TMP36 level (blocked until adc0_mv samples), reset; a defined node "light on" with requirement `led_on = 1`, execution `led_follow_state`, collateral D6 level + LED current; a node "warm" with `temperature_c in 20..30`; its fastest path named |
| bss-2 | ONE node test from the root along the fastest path: the twin replays flash -> boot -> press, stepping at each node as its executions and collaterals ask, ngspice for D6, Cauer for the LED; the edge ends on the change; `StructNodeRun` + per-edge rows; `step_set_by`, `duration_set_by`; the "changed no struct" finding; the guard | "light on" met: `led_on = 1` at cycle N, `led_follow_state` observed, D6 high, LED current within bound -> confirmed by simulation; a build with the struct write removed -> the finding; step set by D6's edge, duration by the debounce in read-button:gpio-poll |
| bss-3 | confirmations and paths: `StructNodeConfirmation` (simulation / hardware / person; voided on a build change); a second path to the same node with a different don't-care field, both confirmed; divergence proposals (D-bss-10); `StructEdgeCheck`; hardware records read in; manual `TestProfile`s | "light off again" by press -> release -> press and by SET_LED: two confirmations; a requirement `led_on = 0` where the code sets 1 -> diverged with a proposed node; a twin-record run -> a hardware confirmation; a manual profile without the D6 collateral -> "observed, not confirmed: D6 current unmonitored" |
| bss-4 | a configuration or isotope change = rebuild, void that build's confirmations, re-test the nodes whose executions touch the changed catom first (cfg-4) | switch read-button to pin-change-interrupt: step rule changes to cycle level, the press nodes re-tested, their `step_set_by` changed; untouched nodes voided but queued |
| bss-5 | the canvas: node kinds `struct-node` / `struct-edge` on the no-code canvas, authored from the rows; the root at the top; the tested path highlighted; naming; click into a node / an edge | the uno-light canvas drawn from the rows; name a node -> the row's title; an AI adds a node through the door -> it appears |
| bss-6 | coverage made obvious: node confirmation states, the coverage strip, the per-node test card, assertion coverage per Firmware Solution, the untested list; the Hardware Events and Structs pages + the Bench Solution page (theme tokens, click-toggle, no raw JSON) | the Chrome pass is owed and needs a deploy, which is the user's call |

## 8. Rules this plan keeps
Every number is derived or cited, otherwise a labelled knob. Established open solvers only (simavr, ngspice, the Cauer ladder). Small rows that reference
each other; children named after their parent. The state map and the step are derived, never typed. No real identifiers. dev-electronics only. No deploys.
