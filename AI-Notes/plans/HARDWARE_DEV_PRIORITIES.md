# Hardware dev priorities (hw arc): what "capability" means across runtimes, where the chain actually stands, and what to do next

**Date:** 2026-10-06 · **Status: PLAN ONLY — nothing built.** Read-only research against suite `origin/dev` (3d35bc0)
across the board/cmod/hwnocode/firmwarefaults modules and the plans below. Companions (read, not duplicated):
`AI-Notes/handoffs/BOARD_ARC_HANDOFF.md` (state + TODO this plan reorders), `AI-Notes/plans/DEMONSTRABLES_PLAN.md`
§3a/§9 (target definitions, CapabilityDefinition/CapabilityInstance, Firmware Solution / Cross-Domain Solution),
`AI-Notes/plans/BOARD_PROGRAMMING_PLAN.md` §7a/§8a (the installer, track-all-simulate-few), `AI-Notes/plans/
FIRMWARE_SCENARIO_PLAN.md` (sc-5, silicon replay), `AI-Notes/plans/FIRMWARE_EXPORT_PLAN.md` (the LATER iteration —
reference only, not re-planned here), `AI-Notes/ledgers/BARRIERS_AND_SOLUTIONS.md`.

## §0. His ask, verbatim (2026-10-06)

> "okay we are going to want that [the export arc] to be another iteration but plan that out and figure out what our
> more recent priorities were around getting hardware development in general working. We should define something like
> task groups or functional groups? Something that groups different related tasks to achieve a more general goal like
> 'We want to ensure data is being retrieved from a temp sensor and gets sent back over usb to the OS'."

**Two corrections he gave while this document was being drafted, both folded in below:** (1) *"perhaps a capability
definition is fine i just need clarity on that"* — the existing `CapabilityDefinition` row stays; no rename to
"Functional Group" is proposed (D-hw-1 is therefore moot, stated as settled in §4, not left open). (2) *"the way
selection and interactions happen on the pins is unintuitive"* — a UX item for the pin-map interaction model is in
§3b, and a general Polari-wide selectable-element rule (*"we need everything that is selectable via click to also be
deselected on a second click"*) is folded into that same item.

## §1. CapabilityDefinition, plainly

A **CapabilityDefinition** names one goal in a person's words — "read a temperature sensor and send it back over USB
to the OS" — and is realised by tasks that may live in different runtimes: a C read/frame/send task on the device
(`c-device`), a relay task on the bridge (`java-bridge`), and a handler task on the backend
(`python-backend`). It names the **targets** those tasks must be registered to (a pin, a register, a bus signal — the
`RegisterAssignment`/`TargetDefinition` rows cmod already derives), the **fields** it exposes once wired (`temp_c`),
and the **proof** that it actually works end to end. One USE of a definition is a **CapabilityInstance** — two
sensors wired to two different pins are two instances of the same definition, each with its own target bindings. The
Firmware Solution (fs-0/fs-1) is what schedules and builds the capability's C tasks into a real `.hex`; the
Cross-Domain Solution (fs-0's `FirmwareRunState`/Bridge/Relay) is what carries its relay up to the backend; the
capability is the THREAD that runs through both — the one row a person reads to ask "is this goal actually working,"
without needing to open either canvas separately. The UI word for this, everywhere it is shown (the canvas palette
entry, the firmware panel's task list, the cross-domain canvas's highlighted slice across lanes), is **"Capability."**

**Fields `CapabilityDefinition` already has** (`modules/cmod/objects/cmod/CapabilityDefinition.py`): `graph` (the
CGraph it is drawn from), `title`, `purpose`, `required_targets` (csv of target port-refs it needs bound),
`exposes_fields` (csv of class fields it makes available), `instance_count` (derived). `CapabilityInstance` already
has: `capability`, `graph`, `index` (1, 2, … among the definition's instances), `bindings` (csv of
`target_port_ref=lives_on`), `status` (unbound | bound).

**What is new, named so it is not mistaken for something already built:**
- **`goal`** — the one-sentence, person's-words statement (today `purpose` is free text with no required shape;
  `goal` is the same field, renamed/required, read by both canvases and the validator below — not a second field).
- **per-runtime task references** — today `required_targets`/`exposes_fields` are csv against ONE graph; a capability
  whose tasks span `c-device` (the Firmware Solution's graph), `java-bridge` (the Cross-Domain solution's Relay
  state), and `python-backend` (a called backend solution, `temp-analysis`'s own pattern) needs a reference PER
  RUNTIME — e.g. `tasks_by_runtime` = `{c-device: <CGraphNode names>, java-bridge: <Relay state name>,
  python-backend: <SolutionDefinition name>}`. This generalises `required_targets` across runtimes rather than
  replacing it: the c-device entries are exactly today's `required_targets`.
- **acceptance proof** — a stated, checkable claim ("a `temp_c` that left the sensor arrives on a backend row within
  N ms"), proven first on the digital twin, then on real hardware (the sc-5 replay is this same proof, re-run on
  silicon). Not built today; §4's D-hw-2 is which existing row kind holds it.
- **status** — `planned | proven-on-twin | proven-on-hardware | failing`, derived from whether its acceptance proof
  has a passing run on each tier (not hand-set).

**One validator** (new, small): a capability's status may not read `proven-on-*` unless every task it names exists
(resolves to a real CGraphNode/state/SolutionDefinition) and every required target is registered (a `RegisterAssignment`
in `bound` status, not `unbound`/`conflict`) — refuses naming the first missing task or unbound target, same posture
as `hwnocode.custom.cross_domain.validate`'s first-offender refusal.

**Seed example 1 — the temperature-sensor-to-OS capability**, over the existing rows: graph `uno-sim-rig-graph`
(c-device: ADC read → moving-average → frame), Firmware Solution `uno-sim-rig` (schedules and builds it),
Cross-Domain Solution `uno-temp-split` (Bridge + Relay carrying `SimRigState`/`temp_c` to the backend), backend
solution `temp-analysis` (the handler). Its acceptance proof restates the EXISTING hwnocode twin probe
(`tests/hwnocode_probe.py`): a `temp_c` set at the twin's simulated ADC0 (700→800 mV ramp) arrives on
`SimRigTempSample`/`SimRigTempDerived` within one frame period (~0.1 s at 10 Hz) — already measured, never run as a
named capability claim before. Status today: would read `proven-on-twin` (never on hardware — §2).

**Seed example 2 — "blink the LED on command from the OS."** The register already expresses this with no new rows:
task = the `uno-blink-only` variant's LED-toggle atom (c-device), relay = a `BackendStateChange`/command path like
`uno-sim-rig`'s existing `led_on` PUT (java-bridge), target = `D13` (bound, `RegisterAssignment` already resolves
it). No backend compute task is needed — the capability's `tasks_by_runtime.python-backend` entry is empty, which the
validator must allow (a capability need not use every runtime).

## §2. Where hardware development actually stands

| link in the chain | state |
|---|---|
| define tasks (C atoms, cmod parse) | done |
| register assignments + compatibility (fs-2) | done |
| firmware solution → build (fs-0) | done, twin only |
| schedule derived from ISR/tick annotations (fs-0, D-fs-1) | done |
| cross-domain relay + backend handler (fs-1) | done, twin only |
| digital twin proof (`tests/hwnocode_probe.py`) | done |
| the live 2D board view (demo-2) | not built |
| fault scenarios on the twin | done |
| fault trace view (demo-3) | not built |
| REAL BOARD: detect | never run on real hardware |
| REAL BOARD: flash | only the docker stopgap (`board/custom/flash.py`'s engines-image route), never exercised on a real port |
| frames from a real UNO | none — every proof so far is simavr |
| silicon replay (sc-5) | not started |
| the installer app / one flash path (exp arc) | not built — later iteration |
| connected mode (isle) | not built — later iteration, isle-only |

**The single biggest gap, plainly: NOTHING HAS TOUCHED REAL HARDWARE.** Every "proven" claim in the handoff and the
plans — brd-0 through brd-wire, sc-0 through sc-4, fs-0 through fs-2, the hwnocode twin probe — is proven on simavr
or QEMU. The UNO sitting on his desk has never been plugged into a host running `pol board detect`.

## §3. Priorities, in order, with why

**P1 — CapabilityDefinition widened (small).** Add `goal` (required, person's words), `tasks_by_runtime`, the
acceptance-proof field, derived `status`, and the one validator (§1); seed the two examples. Builds on: nothing new
— `CapabilityDefinition`/`CapabilityInstance` already exist (cmod). Proof: the temp-sensor capability's status reads
`proven-on-twin` from the EXISTING hwnocode probe restated as its acceptance run; the blink capability validates with
an empty backend-runtime entry. Must NOT add: a second graph/solution concept, a rename, a new canvas. **Why first:**
it is the unit every later priority is measured against — P2's bench run needs a capability to prove, not just a
build to flash.

**P2 — the real UNO on the bench (small to medium).** Through the EXISTING stopgap flash path only (no new flash
mechanism — the installer/export arc owns that later): his step — plug it in; `pol board detect` → `pol board install
uno --variant uno-blink-only` → `uno-echo` → `uno-sim-rig`; the temp-sensor capability's acceptance proof re-run on
real frames instead of twin frames; record what breaks (DTR reset timing, Optiboot window, simavr's 1-LSB ADC
difference, whichever datasheet fact turns out wrong). Builds on: brd-0/brd-1/brd-fi/brd-wire (all BUILT), the
installer's existing DRY-RUN/`--yes`/read-back-verify gate. Proof: the capability's status reaches
`proven-on-hardware`. Must NOT add: a new flash path (the docker-run stopgap stays exactly what it is until the
export arc's exp-2 retires it — BARRIERS_AND_SOLUTIONS and the handoff's DEBT table both already say so); no board
beyond the UNO. **Why second:** it is the first time ANYTHING in this whole arc meets silicon — every number this
arc has produced (cycle counts, footprints, rates) is a twin's estimate until one real run checks it.

**P3 — demo-2, the live board sim-space (medium).** The UNO as a live 2D board drawing (pin states, ADC needle, LED
fill, PWM wedge, UART strip) fed by twin frames (replay fallback when nothing is live), with the active capability
highlighted on the drawing. Builds on: the `level-view` component (dlv plan), the demo-1 pin-map SVG, the existing
STOMP frame path the installer panel already uses. Proof: DEMONSTRABLES_PLAN §3 demo-2's own proof (ADC slider moves
the needle, pause freezes the drawing, replay when nothing is live) PLUS the temp-sensor capability drawn as one
highlighted slice across the pin map. Must NOT add: a second viewer component, instruction-level stepping (that is
demo-3), a new chart engine. Runs alongside §3b (the pin-interaction rework, below) since both touch the same pin
map.

**P4 — the installer's live validate→build→run door (small).** Wire the firmware panel's buttons to the REAL
`/api/firmware` validate→build→run calls (today mocked per the handoff's demo-4 leftovers), through the stopgap flash
path until the export arc's exp-2 ships. Builds on: fs-0/fs-1/fs-2's existing doors. Proof: a click in
`/display/firmware-solutions` produces the same sha the CLI path already produces. Must NOT add: the export gate
itself (that is the later iteration, D-exp-4) — this is the web panel catching up to what the CLI can already do.

**P5 — demo-3 + sc-5 (medium).** The fault-scenario trace view (cursor, BEFORE/AFTER side by side, reading
`ScenarioTraceCycle` rows already written) AND the silicon replay of scenario 1 (torn-millis-read) on the now-bench-
proven UNO (P2). Builds on: sc-0/sc-1 (BUILT), P2's working bench setup. Proof: the BEFORE build shows backwards
`uptime_ms` on real frames, the AFTER build never does, over N minutes — FIRMWARE_SCENARIO_PLAN's own sc-5 definition.
Must NOT add: a second trace component (reuses `level-view`'s `trace` renderer, D-demo-2 in DEMONSTRABLES_PLAN).

**P6 — the dlv rungs.** RTL/netlist/cell/layout renderers and semantic zoom, per `DESIGN_LEVEL_VIEWS_PLAN.md`'s own
slices — referenced, not re-planned here. Lowest priority of the six because nothing above depends on it, and his
own ruling elsewhere keeps 3D per-object detail (not a new LOD rung) as the standing posture.

**Then the export iteration (exp-0..4) as its own arc** — `FIRMWARE_EXPORT_PLAN.md`, unchanged, awaiting his go. Not
reordered or resequenced here: his message that opened this document explicitly calls it "another iteration," kept
separate from the priorities above.

## §3b. Pin-map interaction model (UX slice, after/with P1, before/with P3)

His words: *"the way selection and interactions happen on the pins is unintuitive."* The model to build against,
on `/display/firmware-solutions`'s pin map and task list (fs-2's four-section panel) and demo-2's live drawing alike:

- **Hover** previews a pin's name + roles (no commitment).
- **One click** on a pin selects it and opens its Target details section; clicking the SAME pin again, or **Escape**,
  deselects it.
- **Selecting a task** switches the pin map to choose-a-target mode: only valid pins (per fs-2a's compatibility door)
  are clickable; one click on a valid pin REGISTERS it (drag remains available as a shortcut, not the only path).
- **One place above the map** always states the current selection in words — "Selected: task `adc.channel` — choose
  a target" or "Selected: pin D13" — so the mode is never ambiguous from the drawing alone.
- **Pin hit areas** are drawn larger than the visual cell (a pin's clickable region exceeds its drawn rectangle) so a
  precise click is never required.

**The first section is renamed and re-scoped** (his correction: *"the Tab for tasks should not be called
Unregistered Tasks since it is all tasks, the shorthand display of the unregistered tasks for assignment makes
sense"*): the section itself is **"Tasks"**, listing EVERY task a solution declares — a registered task shows the pin
it is bound to, an unregistered one is marked as such. The existing compact chip strip of unregistered-only tasks
stays, unchanged in purpose, as the assignment SHORTHAND beside/within the pin map — only the full section's tab
label was wrong, not the strip's name.

**One selection model, many entry points** (his correction): selecting a task is the SAME action regardless of where
it is clicked — the Tasks section's row, the Unregistered Tasks chip strip, a schedule-lane chip, or a
registered-task row inside Target details. Each produces the identical result: the task becomes the selection, the
pin map enters choose-a-target mode with valid/invalid/undetermined colouring, Target details shows its requirement
plus its valid-target list, and the selection bar names it; a second click on whichever element was clicked
deselects it. One selection model, four entry points, never four separate behaviours.

**A general Polari-wide rule, raised here, not scoped to pins:** *"we need everything that is selectable via click to
also be deselected on a second click"* (his words). Every selectable element in the firmware panel — pins,
Tasks-section rows, Unregistered Task chips, schedule chips, a section header's own selected state, a preset choice
where toggling makes sense — follows the same toggle: click selects, the same click deselects, Escape clears every
selection at once. Belongs in specs as **one toggle-spec per selectable element** (select / same-click deselect /
Escape-clears-all), the same way `per-object-display-config` and `no-raw-json-on-screens` are checked today, PLUS
**one "same behaviour, many entry points" spec** asserting the Tasks row / chip / schedule chip / Target-details row
all drive identical selection state — not verified once and assumed equal elsewhere.

## §4. Decisions for him (D-hw-1..3)

- **D-hw-1 — SETTLED, not a live decision.** His "perhaps a capability definition is fine i just need clarity on
  that" keeps the name **CapabilityDefinition**; no rename to "Functional Group" or "Task Group" is proposed. The UI
  word is **"Capability."**

- **D-hw-2 — is a capability's acceptance proof a `Scenario` row (reuse firmwarefaults' `Scenario`/`ScenarioRun`
  machinery) or its own row?**
  **Recommendation: a `Scenario` of a new kind `acceptance`, reusing the existing machinery.** `Scenario` already
  carries everything an acceptance check needs — a target build/variant, steps, an expected observable, a window, a
  simulator (twin or silicon) — and `ScenarioRun` already carries the pass/fail outcome plus its evidence
  (`outcome`, `observed_json`, `trace_sha256`). A capability's acceptance check IS a scenario in every sense except
  that it is not forcing a FAULT — it is checking a GOAL holds under normal operation. Reusing the row avoids a
  second "run recorded a pass/fail with evidence" concept existing side by side with the first, and lets the
  capability's derived `status` read straight off `ScenarioRun.outcome` for its own `kind='acceptance'` runs — the
  same way a `MathClaim` already derives from a `ScenarioRun`.

- **D-hw-3 — does P2 (the bench) happen before P1's seeds?**
  **Recommendation: P1 first**, so the bench run in P2 has a named capability to prove (its acceptance scenario run
  moving from twin-passed to hardware-passed) rather than a bare "did the LED blink" check with nothing durable
  recorded against it. P1 is small (row fields + one validator + two seeds); nothing about it blocks plugging the
  UNO in on the same day.

---

Not in scope here: the export arc itself (`FIRMWARE_EXPORT_PLAN.md`, unchanged, his separate go required); any new
board beyond the UNO (BOARD_PROGRAMMING_PLAN's `Road` rows already track the rest as to-do); VHDL/C++/Rust/MicroPython
on devices (RULE 2, unchanged); a second chart/viewer component anywhere in §3's slices.

### §3b addendum — the selection model, ruled 2026-10-06 (his pick: option 3, "selection then action with a confirm")
His ask: "The selection of a register and the selection of a task should be similar, selecting either highlights all that are
connected and it goes both ways. We should have some kind of intuitive way to trigger toggling between just selecting and selecting
in a way that sets a task to a register or vice versa though." Ruled:
- **Symmetric highlighting, one grammar both ways.** Select a task → its registered pins SOLID, pins it could still register to
  OUTLINED (valid), the rest grey with the reason on hover; its caller/called tasks solid in Tasks and Schedule. Select a pin → its
  Registered Tasks solid in Tasks and Schedule, unregistered tasks that could register there outlined, the rest dim; Target details
  shows the register.
- **Selection then action, with a confirm — no mode switch.** With a task selected, clicking an OUTLINED pin offers
  "Register <task> to <pin>? [Register] [Cancel]" in the selection bar; the mirror from a selected pin offers the same for an
  outlined task; clicking a SOLID (already registered) counterpart offers "Unregister <task> from <pin>?". Nothing is written before
  Register. Drag remains a shortcut that lands on the same confirm — ONE path to a write. The selection bar always states what the
  next click will do ("click an outlined pin to register adc.channel there, or click adc.channel again to deselect").
- **The toggle rule holds:** the second click on the selected item deselects and the offer disappears; Escape clears all.
- A visible "skip confirmations" switch only as a per-viewer preference if ever asked, off by default.
- Specs: symmetric highlight from both ends; offer appears only for valid pairs; no POST before Register; Unregister path; drag lands
  on the confirm; toggle per selectable.
