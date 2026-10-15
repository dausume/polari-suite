# Polari Firmware Generation Module — Phase 0 reconciliation (gap analysis + file-level plan)

**Date:** 2026-10-15 · **Status:** Phase 0 deliverable of the proposal he pasted 2026-10-15 ("Polari Firmware Generation Module",
ATmega328P, C, Python + Jinja2, bidirectional button-and-LED). Nothing built. **ALL D-fgm-1..8 RULED 2026-10-15:** D-fgm-2 and D-fgm-3
his own (§6); the rest "your recommendations seemed fine" → as recommended. HAL variable families added (§5b).
Companion plans: FIRMWARE_FLOW_STATES_PLAN (the no-code FACES: Struct, HAL object, Init, Priority, Task) — this plan is the ENGINE
underneath them; UNO_CORE_DEMO_PLAN §5i–§5l (the light test, the Hardware App, the bench).

## 1. Headline

Roughly two thirds of the proposal's chain already exists as rows, doors and proofs. Three things are genuinely missing and are the
real work: (a) **Jinja2 template emission** — today firmware C is hand-written atoms extracted verbatim plus Python-emitted glue;
(b) a **resolver that searches** (enumerate isotopes, propose claims, backtrack) — today we only VALIDATE a binding a person made;
(c) **firmware-side state semantics** — a state registry with revisions, a bounded event queue, acknowledgment and resync.
Everything else is reuse, renaming, or widening.

## 2. Model-by-model reconciliation

| proposal | exists today | verdict |
|---|---|---|
| FirmwareSolution | `FirmwareSolution` (cmod, fs-0): graph + board/variable, derived schedule, register map, proof summary | **reuse** |
| Purpose | `CapabilityDefinition` (UI word "Purpose", D-ucd-12): goal, tasks per runtime, acceptance Scenario, DERIVED status | **reuse; widen** with fulfillment criteria as typed fields (max latency ms, delivery kind) — today they live in prose + acceptance steps |
| Task (dispatchable unit of CAtoms) | **naming clash**: pages call each ATOM a "task". The flow-states plan's `TaskDefinition` is this concept, not built | **build** as flow-states' Task; rename the page word for atoms → "step" (D-fgm-1) |
| CAtom (family of implementations, contract, HAL needs) | `CFunctionAtom` = ONE concrete parsed C function + ports + resources + ISR-safety + cost | **widen**: the CAtom becomes the contract; today's parsed function becomes its first CIsotope |
| CIsotope (hardware-specific implementation, templates, bindings) | `CIsotope` (iso-0): parent atom + datasheet bindings + substitutions + `minimum_level`; source = parent body with substitutions only | **widen**: add `template_ref` + typed `bindings` contract; keep substitution isotopes as the degenerate case |
| Hardware models (SoC, package, board contacts, nets, signals, registers…) | ucd-0a/0b: Peripheral, PeripheralSignal, PinFunction, SignalRoute, Register, RegisterField, RegisterSetting, RegisterFieldSetting, BoardPinNet, PinClaim, PeripheralClaim, AddressSpace/RegisterBlock; cited, materialized, origin on every row; the chain door | **reuse** (largely done); gaps: SignalPotential/DrivePotential as typed electrical fields (0c has 5 electrical rules, not the two-potential model) |
| TaskStructBinding | none (atoms read/write globals; the glue's `class` struct) | **build** (with flow-states Task) |
| FirmwareStateRegistry | wire classes with pinned contracts (`LightState` v1, enums), grpcbridge proto gen | **widen**: registry = the set of pinned contracts per firmware + per-field ownership/publication/delivery kind |
| StatePublicationRequirement | none (every frame sends the whole struct) | **build** |
| FirmwareEvent | `ButtonClockEvent` existed (button-clock sample, backend-side ledger); the light firmware has NO event queue (a `toggles` counter detects loss, does not deliver) | **build** firmware-side bounded queue |
| TaskTriggerBinding | `ScheduleSlot` (DERIVED from annotations: isr/tick/loop/init/called) | **build** the authored form (= flow-states Priority assignment); keep derivation as the agreement check |
| HALBinding | `TargetDefinition` + `RegisterAssignment` + `HardwareBinding` ('<solution>@<board>', valid only when the board meets every requirement) | **reuse; type it**: today bindings resolve to rows but are not typed by kind (gpio_input, interrupt_source…) |
| ResourceClaim | `PinClaim` / `PeripheralClaim` + the cooperation rule + `check_drop` 422s | **widen**: add shared / time-multiplexed modes and the proposed → committed lifecycle |
| FirmwareBuildManifest | glue record (graph sha, files sha, hex sha, cost), `FirmwareExport` manifest (shas, parity, proof), repro block | **reuse; add** template versions + compiler flags as fields |
| GeneratedCodeProvenance | `composed_by` per task, `firmware` per canvas node, code-interface comments naming the datasheet per identifier, the chain door | **widen**: per generated LINE → template + isotope + binding (needed once Jinja emits code) |
| Relay/Receive Tasks | atoms `telemetry_send`, `rx_pop`, `apply_command`; Java bridge (reconnect, snapshot, gaps, reboot — ucd-0e3); gRPC Push/Commands; boot_session ≠ seq already | **reuse transport**; **build** revision-based coalescing, ack, full-state resync on the firmware side |
| Build / flash / verify | cmod-glue make (in the engines image), CMake export with sha parity, Hardware Bridge App flash step (avrdude fixed argv, read-back), acceptance Scenarios on the twin, attestation for hardware | **reuse**; hardware-in-the-loop automation is the bench (ucd-3) |
| Repository layout `firmware/…` | the same responsibilities live in modules `board` (hardware), `cmod` (atoms, glue, firmware solutions, exports), `hwnocode` (runtimes, cross-domain), `grpcbridge` (wire, bridge), `firmwarefaults` (scenarios) | **do not create** a parallel tree; new code lands as `cmod/custom/{resolver,generator}/` + `cmod/templates/` (D-fgm-2) |

## 3. Pipeline: proposal vs today

| proposal step | today |
|---|---|
| requirements from Purposes | Purposes name tasks; requirements are not derived from them (the binding validator derives requirements from ATOMS) |
| collect CAtom HAL requirements | ✅ atom `resources` + `TargetDefinition` (requirement_kind derived) |
| enumerate compatible CIsotopes | ❌ one isotope per atom×binding, derived, no alternatives |
| resolve peripherals/pins/signals/registers | ✅ `target_compat` (cited ok/no/undetermined) + `valid-targets` door — for ONE task at a time, chosen by a person |
| propose → check → backtrack → commit | ❌ no search; `check_drop` refuses a bad person-made choice |
| materialize register settings + HAL bindings | ✅ `claims.py` → RegisterSetting/FieldSetting/SignalRoute; `pin_config_gen` → pin_config.h/.c (generated, equivalent on the twin 40/40) |
| render with Jinja2 | ❌ Python emission (`glue.py`, `pin_config_gen.py`) + atom bodies extracted verbatim from hand-written `hal.c`/`apps/*.c` |
| compile, size, artifact | ✅ make in the engines image; size vs board limits; hex sha parity CMake vs Makefile |
| flash + verify | ✅ app flash step (built, never run on silicon); twin acceptance ✅; hardware = the bench |

## 4. Where the proposal differs from his standing rulings (flag, his call)

1. **The D3 feedback pin — CORRECTED 2026-10-15.** Earlier notes said he cut it on 2026-10-11. He did not: his words were about the demo's
   purpose ("a simple light test … to make sure we can send data in both directions"); dropping the sense pin was an AGENT inference
   recorded as his ruling. His rule (2026-10-15): "we should be trying to account for everything we can about the boards, chips, and all
   levels of pins, we cannot ignore things and then be missing them later." → D3/INT1 feedback is IN the first milestone (§9 as proposed).
2. **Three Purposes vs two.** Proposal: ButtonControlsLight · PolariObservesHardwareState · PolariCanControlLight. Today:
   `light-from-button` (button → light → Polari) · `light-from-polari` (Polari → light → report) + the planned Initialization Purpose.
   The proposal splits "button controls light" from "Polari observes" — finer, and it makes acceptance test 7 (comm loss must not
   block local control) a Purpose of its own. → D-fgm-4.
3. **Acceptance test 6 (rapid presses must not disappear when event delivery is required)** fails by construction today: the light
   firmware coalesces into `toggles` + `led_on`. It needs FirmwareEvent + a bounded queue + ack. → in Phase 5/6.
4. **Acceptance test 9 (regenerate with a different valid pin)** is half-there: `pin_config.c` and the register settings regenerate
   from claims, but `hal.c` uses `LED_PIN`/`BUTTON_PIN` macros the isotopes list but do not substitute. Jinja-rendered HAL isotopes are
   exactly the fix.

## 5. File-level plan (phases mapped onto the existing modules; each phase = a branch, proven on the econ-core test node first)

| proposal phase | lands in | proof |
|---|---|---|
| 0 reconciliation | this file | — |
| 1 model contracts | `cmod/objects/cmod/`: widen `CFunctionAtom` (contract fields), `CIsotope` (`template_ref`, `bindings_json` typed), new `TaskDefinition`, `TaskStructBinding`, `TaskTriggerBinding`; `CapabilityDefinition` gains typed criteria (`max_latency_ms`, `delivery`) | the light test expressed in the new rows; validator selftest; nothing generated yet |
| 2 hardware/register | `board/custom/`: typed electrical (SignalPotential vs DrivePotential), write-behaviour per RegisterField (rw / w1c / strobe — `pin_config_gen` already refuses strobe/toggle fields by name), shared/time-multiplexed claim modes | conflict selftests (two timers, a GPIO that cannot drive the LED, INT on a non-INT pin) |
| 3 Jinja2 foundation | `cmod/custom/generator/` (context builder, StrictUndefined env, identifier/literal filters, deterministic output) + `cmod/templates/avr/` (gpio_in, gpio_out, ext_interrupt isotopes) — reuse pol-build's StrictUndefined idiom | rendered GPIO/INT isotopes compile; **byte-identical hex for `uno-light`** vs today's glue (the regression gate) |
| 4 task + dispatch | `cmod/templates/{bare_metal,isr,task,root}/`; authored triggers → generated ISR + dispatcher; derived `ScheduleSlot` as the agreement check | twin: button → LED via generated dispatcher; both Purposes stay proven |
| 5 state registry | `grpcbridge` contracts + `cmod/templates/state/`: root struct, revisions, accessors, bounded event queue with explicit overflow | twin: 20 rapid presses → 20 events or a named overflow, never silent |
| 6 communication | firmware relay/receive tasks (coalesce by revision, ack, resync) against the EXISTING Java bridge (0e3 lifecycle) | twin: unplug/replug the bridge → consistent state; ack-gated event clearing |
| 7 build/flash/verify | the Hardware Bridge App flash step + `pol capability prove --hardware` | the bench (ucd-3) |
| 8 portability | a second pin assignment on the UNO, then the ESP32-C3 (iso-2: parse the C3 project) | same Tasks/Purposes, different isotopes |

**First slice to build** (smallest, highest leverage): Phase 3's regression gate — render today's `uno-light` glue + pin_config through
Jinja2 templates and get the identical `firmware.hex` sha. It proves the engine without changing any behaviour, and every later phase
then edits templates instead of Python string code.

## 5b. His addition 2026-10-15: editing a CAtom in Polari, two views of one template, and a fixed on-disk layout

His words: "we will additionally want to have a way to edit a catom in the polari interface, and be able to insert HAL variable without
having to specify they are HAL in the variable name, instead in the editor on polari that is edited out and we convert between a real
jinja template we can use and a polari-format coding that we show to the user. We should have insertion similar to how we do insertion
in math equation for latex, having the option to enter variable names and then we see both the style altered and the real jinja version
code on the catom or cisotope detail page. We should also have a defined file structure for when catoms and cisotopes are saved in
modules and they should have a dedicated directory and structure."

**Two forms of one source, converted losslessly both ways (`cmod/custom/generator/polari_format.py`):**
- **Jinja form** (on disk, rendered by the generator): plain C with `{{ hal.<name> }}` for every HAL variable, `{{ struct.<name>.<field> }}`
  for Task Struct bindings, `{% if hal.<name>.feature %}` only for resolved optional features (§5 template rules).
- **Polari form** (shown and edited): the same C, every variable written as its bare name — `PORTD |= (1 << led_bit);` — and DRAWN as a
  chip (styled, coloured by kind: HAL variable · Struct field · constant), never typed with a `hal.` prefix. The variable's identity is
  carried as a TOKEN, not inferred from the text: the editor stores a token list `[{kind, name, offset}]` beside the text, so a C
  identifier that happens to share a name is never turned into a variable by accident.
- Conversion rules: polari → jinja replaces each token with its `{{ hal.<name> }}` / `{{ struct.… }}` form; jinja → polari parses the
  `{{ … }}` expressions back into tokens. Anything else in `{{ }}` / `{% %}` that the converter does not recognise is REFUSED by name
  (no silent passthrough), so the two forms can never drift. Round-trip property is the selftest: jinja → polari → jinja is identity
  for every seeded template.
- Every HAL variable must be declared in the CAtom's `hal_contract` (name · family · kind · description). **Families (his rule
  2026-10-15: "different kinds of HAL variables like drive variables (all electric charging and powering methods) and register variables,
  and protocol variables"):**
  - **Drive variables** — everything that charges or powers: digital drive (push-pull, open-drain, sink/source current limit), PWM drive
    (frequency, duty, resolution), analog/DAC output, supply rail selection (5V / 3V3 / VIN / IOREF), internal pull-up/down, battery and
    charging methods (charge current, termination, cell chemistry), load characteristics (LED forward voltage + resistor, motor, relay
    coil). They bind to the board's DrivePotential / SignalPotential facts (kept separate, §2) and the electrical rules (0c), so "can this
    pin safely drive this load" is checked from the variable, not guessed.
  - **Register variables** — register, register field, bit position, mask, write behaviour (rw / w1c / strobe), reset value: bound to
    Register / RegisterField rows with their datasheet citation.
  - **Protocol variables** — UART (baud, framing, parity, stop bits), I²C (address, speed), SPI (mode, clock, CS), the Polari wire packet
    (device id, schema version, sequence width), timing (debounce ms, tick period, deadlines).
  - **Signal variables** — inputs and events: GPIO level, edge, interrupt source and sense, ADC channel and reference.
  - **Execution variables** — execution context (ISR / task / init), priority, Task Struct bindings.
  Each family has its own chip colour in the editor and its own section in the "Insert variable" palette; a variable's kind fixes which
  rows it may resolve to (a register variable can never resolve to a protocol setting). Inserting an undeclared
  name offers "declare it" (kind picker) rather than accepting free text.

**The editor (reuse the LaTeX insertion idiom, no new editing paradigm):** the existing `shared/latex-edit-dialog` already keeps the
last-known cursor across palette clicks and inserts a palette entry with a cursor offset (`insertSymbol`). The CAtom editor is that
dialog's pattern with a different palette: **Insert variable ▾** lists the CAtom's declared HAL variables and its Task's Struct fields
(grouped by kind, each with its one-line description and, under a chosen binding, the value it resolves to); a **New variable** entry
declares one inline. Typing a name and pressing Tab converts it to a chip when it matches a declared variable. Save writes the JINJA form
to the module directory below; nothing is saved in the polari form.

**The detail pages (CFunctionAtom / CIsotope object pages — the iso-1 sections, reusing `shared/code-block`):** three panes side by
side, collapsible: **Polari form** (styled chips, editable via the dialog) · **Jinja form** (the real template, read-only, line
numbers) · **Rendered C** under the chosen HardwareBinding (today's code-interface view: each resolved value with the datasheet
comment that justifies it). A row under them lists every variable: kind, description, its binding's value and the register field /
pin it comes from (the traceability chain, one click each). A CIsotope page shows only its substitutions/overrides over the parent
CAtom, with "inherited" marked on the rest (the iso-0 rule: structure inherited, never re-authored).

**On-disk layout — one dedicated directory per module, the same shape everywhere (D-fgm-7):**
```
modules/<module>/firmware/
  catoms/
    <catom_name>/
      catom.json             # contract: purpose sentence, inputs/outputs, hal_contract[], resources, isr_safe, cost hints, version
      template.c.j2          # the JINJA form (the only source of truth for the body)
      README.md              # generated: the polari form rendered as text + what each variable is
      isotopes/
        <isotope_name>/      # e.g. avr-atmega328p, esp32c3-freertos
          isotope.json       # compatibility: soc / board / programming bindings, minimum_level, toolchain, overrides of hal_contract defaults
          template.c.j2      # ONLY when the isotope overrides the body; absent = inherits the parent's
          substitutions.json # per-variable fixed values for this hardware (iso-0's substitutions), each with its datasheet fact
  templates/                 # shared non-atom templates this module contributes: isr/, task/, dispatcher/, state/, transport/, root/
  boards/<board>/            # optional: board-specific HAL defaults (today's board_config.h moves here as a template + json)
  fixtures/                  # golden rendered C per (catom × isotope × binding) for the regression gate
```
Rules: names are lowercase-kebab and equal the row name; the JSON files are what the seed reads (the module initialData convention:
files → rows at boot, rows → files on export, privacy strip unchanged); a CAtom/CIsotope edited in the Polari editor is written back
through the module's export door to these files, then committed like any module change. Today's hand-written `board/custom/firmware/
uno/{hal.c, apps/*.c}` stays as the PARSED source of the first isotopes until Phase 3 converts each function into `catoms/<name>/
template.c.j2`; the byte-identical hex check gates every conversion.

**Slices:** fgm-ed-0 the converter + round-trip selftest + the on-disk layout with the `uno-light` atoms converted (gated by identical
hex) · fgm-ed-1 the three-pane detail pages (read-only) · fgm-ed-2 the editor dialog with variable insertion and declare-inline · fgm-ed-3
save-through-export to module files.

## 6. Decisions (his; recommendation first)

- ✅ (ruled as recommended) **D-fgm-7 where atom files live.** Under each owning module's `firmware/` (board owns the HAL atoms, the demo module owns its app
  atoms) · one central `cmod/firmware/` → **under each owning module**, so a module repo (polari-module-*) carries its own atoms.
- ✅ (ruled as recommended) **D-fgm-8 variable chips.** Styled inline chips in an editable text area · a structured block editor → **chips in text**, matching
  the LaTeX dialog.

- ✅ (ruled as recommended) **D-fgm-1 the word "task".** Proposal: Task = dispatchable unit of CAtoms. Pages today call each atom a "task". → **adopt the
  proposal's meaning; atoms are "steps" on pages** (also matches the flow-states plan).
- **D-fgm-2 where the module lives — RULED 2026-10-15 (his):** "a parent overall hardware tree that contains them, since this is a superset of
  all of those." → ONE parent **Hardware** tree over board · cmod · hwnocode · grpcbridge · firmwarefaults · pcb · hwmap · hardwareapps ·
  uno_core_demo (and future electrodevice/hwdigital). Step 1 logical: a `parent: hardware` field in each manifest + the Hardware app home
  as its front door + one object-tree root; step 2 physical: `modules/hardware/<sub>/` with the firmware layout (§5b) under it — moved
  module by module, imports kept by alias, each move gated by the module selftests and the byte-identical hex.
- **D-fgm-3 the D3 feedback pin — RULED 2026-10-15 (his):** account for everything; never drop a pin or level to simplify. → D3/INT1
  feedback in the first milestone; the hardware model stays exhaustive (every pin, every level, every function) — demos SCOPE what they
  use, the model never omits.
- ✅ (ruled as recommended) **D-fgm-4 Purposes for the light test.** Two (today) · the proposal's three (+ Initialization) → **the proposal's three plus
  Initialization** — the split makes "comm loss must not block local control" provable on its own.
- ✅ (ruled as recommended) **D-fgm-5 event delivery for the button.** Latest-value only (today) · reliable events with ack → **reliable events with a bounded
  queue and explicit overflow** (acceptance test 6 requires it).
- ✅ (ruled as recommended) **D-fgm-6 hand-written HAL vs templates.** Keep `hal.c` hand-written and template only glue · move HAL isotopes to templates → **move
  HAL isotopes to templates in Phase 3** (it is what makes regeneration with another pin real).

---

## 7. Revision 2 amendment (2026-10-15) — reconciled INTO this plan; every D-fgm ruling preserved

Source: ChatGPT "Polari Firmware Generation Architecture — Revision 2" (relayed by him) + his framing: treat R2 as an amendment, keep
D-fgm-1..8, reopen nothing without a concrete technical conflict; the hardware model represents ALL documented capabilities at SoC,
package, board and extension level even though milestone 1 exercises a subset. The codebase inventory with file paths and per-item
status is `FIRMWARE_GENERATION_REVIEW_R2.md` (Part 1); this section is the reconciled architecture.

### 7.1 Preserved, unchanged

Parent **Hardware** tree over every hardware module (D-fgm-2) · catom/cisotope on-disk layout under each OWNING module (D-fgm-7, §5b) —
i.e. `modules/hardware/<module>/firmware/catoms/<name>/…` once the tree move lands · the Polari-native editor: bare-name tokens drawn
as chips, lossless Polari-form ↔ Jinja-form conversion, unknown template expressions refused (§5b, D-fgm-8) · the five HAL-variable
families drive / register / protocol / signal / execution (§5b) · D3/INT1 feedback in milestone 1 + an exhaustive hardware model
(D-fgm-3) · "task" = R2's dispatchable unit, atoms are "steps" on pages (D-fgm-1) · three Purposes + Initialization (D-fgm-4) ·
reliable button events with a bounded queue (D-fgm-5) · HAL routines move into templates (D-fgm-6).

### 7.2 Three kinds of progress (E = existing runtime behaviour · S = schema/model only, runtime incomplete · N = newly proposed)

| area | E | S | N |
|---|---|---|---|
| Purpose | goal, tasks, acceptance Scenario, DERIVED proof status, attestation, overrides, weakest-wins summary (`cmod/custom/capabilities.py`) | `CapabilityInstance` (bindings mostly unbound) | lifecycle, typed criteria, observes, participants, per-instance observation |
| Task / dispatch | derived `ScheduleSlot` lanes | — | `TaskDefinition`, `TaskStructBinding`, `TaskTrigger` |
| CAtom / CIsotope | parsed atoms with ports/resources/ISR-safety/cost; derived substitution isotopes with `minimum_level` | isotope `bindings_json` (no selection uses it) | atom as contract (`hal_contract`), isotope `template_ref` + `fragments` + `compat`, alternatives |
| SoC / package / board / extension | SocDefinition, SocPin (28-SPDIP numbers cited), BoardDefinition (UNO R3 A000066), BoardPin, BoardNet, BoardPinNet, Connector(Pin), circuit rows | `SocPin.package_pin` (string), `BoardHardware.components_json` (U1 ATmega328P-PU DIP-28, U2 ATmega16U2), power pins as package facts | `PackageDefinition` + `PackageContact`, `BoardExtension` + `ExtensionContact`, board component rows referencing their own SoC |
| Pin mux | PinFunction / PeripheralSignal / Peripheral / SignalRoute, `target_compat` ok/no/undetermined used by valid-targets, check_drop, binding validity | — | mux-exclusivity groups as data the resolver searches over |
| Registers | Register / Field / Setting / FieldSetting, masked RMW + strobe/toggle refusal in `pin_config_gen.py` | — | write-behaviour as a typed field the templates read |
| Electrical | five circuit rules in `board/custom/electrical_check.py` over `BoardPin.electrical_json` (`max_ma` 20, cited) | `BoardHardware.power_rails_json` (volts) | `ElectricalCharacteristic` (per pad class × condition, limit class, verification), `PowerBudget` (groups) |
| Lifecycle pins | power/reference pins `assignable:false` with reason (`power_pins.py`) | — | `PinLifecycleConstraint` (pin × phase × policy × cite): RESET←DTR, D0/D1 transport+bootloader, D13 L LED, ICSP, AREF |
| Claims | exclusive PinClaim/PeripheralClaim with the cooperation rule | — | `mode` shared/time-multiplexed, `state` proposed/committed |
| Generation | Python glue + verbatim atom extraction; pin_config generated; deterministic hex | — | Jinja2 env/context/filters, multi-fragment assembly, per-line provenance |
| Build / flash | make in the engines image, size check, CMake export parity | the app's flash step (built, never run on silicon) | bootloader-aware size budget |
| State / relay | pinned wire contract, Java bridge lifecycle, gRPC both ways, boot_session ≠ seq | — | firmware registry with revisions, `FirmwareEvent`, ack, resync |

### 7.3 Assessment 1 — do the five HAL-variable families cover R2's electrical and mux requirements?

**Yes as families; they need named KINDS and two attached checks.** Nothing in R2 needs a sixth family.

| family | kinds needed for R2 | resolves to |
|---|---|---|
| drive | digital_drive (push-pull / open-drain, source/sink limit), pwm_drive, analog_out, supply_rail, pull (up/down, range), load (LED Vf+R, relay coil, motor), charge (current, termination, chemistry) | `ElectricalCharacteristic` (VOH/VOL at IOH/IOL, limits by class), `PowerBudget` membership, the circuit component |
| signal | digital_in (VIH/VIL), edge_interrupt (source + sense), analog_in (channel), analog_ref (AREF / AVCC / internal), comparator_in, clock_in | `PinFunction` + `PeripheralSignal` + input characteristics |
| register | register, field, bit, mask, write_behaviour (rw / w1c / strobe / toggle), reset value | `Register` / `RegisterField` (+ citation) |
| protocol | uart, i2c, spi, wire_packet (device id, schema version, sequence width), timing (debounce, tick, deadline) | `Peripheral` instance + transport / contract rows |
| execution | context (init / isr / task), priority, struct_binding, isr_shared | `TaskDefinition` / `TaskStructBinding` |

**Pin multiplexing is not a variable family and should not become one.** An atom author declares WHAT it needs (signal:edge_interrupt,
protocol:uart); the mux choice — which PinFunction on which SocPin — is the resolver's OUTPUT, recorded as the claim and as the
binding's target. Making it a variable would let a template choose a pin (R2 §2.6 / §5 template rule 4 forbid that).

**Two checks attach to every binding that resolves to a pin:** the electrical check (drive and signal kinds evaluate their
`ElectricalCharacteristic` + `PowerBudget` + the connected circuit; absolute-maximum values are never accepted as a target; a missing
number yields `undetermined`, never unlimited) and the lifecycle check (`PinLifecycleConstraint` for every phase the firmware passes
through). The editor shows both verdicts on the variable's chip.

### 7.4 Assessment 2 — do R2's Purpose states and fulfillment contracts fit the existing Purpose?

**Naturally, with one correction.** The existing rule is that Purpose status is DERIVED from evidence and never hand-set; R2's four
stored dimensions would break that rule twice:
- **lifecycle** (draft / enabled / suspended / retired) — a person's intent → STORED field on `CapabilityDefinition`. No conflict.
- **resolution** (unresolved / resolving / resolved / blocked) — already answerable: a valid `HardwareBinding` exists for the Purpose's
  tasks or it does not (`cmod/custom/binding.py`). → DERIVED on read, like `status`. "Resolving" is a job's state, not a Purpose's.
- **fulfillment** splits into design-time proof (exists: `status` from ScenarioRuns, attestation) and runtime fulfillment of a
  DEPLOYED firmware, which is per board instance (two UNOs running one Purpose can disagree) → `PurposeObservation` rows keyed
  (Purpose, BoardInstance), written by the backend from relayed state; the Purpose shows the weakest (existing `purpose_summary` rule).
- **execution health** — same: per instance's Tasks + bridge, summarised up.
**Fulfillment contract** = typed `criteria_json` (max_latency_ms, delivery, freshness_ms, debounce_ms, reliability) + the existing
acceptance Scenario (machine-checkable on the twin) + runtime predicates evaluated in the BACKEND over relayed state, never on the MCU.
**Observation requirements** (`observes_json`: fields and events with delivery kind) are what drive the relay Task: they become its
trigger (tick period bounded by the tightest freshness/latency), its coalescing rule (latest-value fields) and its queue (events).
**Scope**: one `participants_json` relation (SocDefinition / BoardDefinition / host Runtime, with a role) is enough; placement already
lives in `hwnocode/custom/placement.py` + `Runtime`; communication between participants already IS the Cross-Domain Solution. R2's five
scope entities are not needed for milestone 1 and not ruled out later.
**Multi-chip is already real:** the UNO R3 carries two programmable MCUs (U1 ATmega328P, U2 ATmega16U2 running the USB-serial
firmware). The model gains a board component row → its own SocDefinition; milestone-1 firmware targets U1 only; U2 appears as the
transport participant and as the cause of the DTR auto-reset.

### 7.5 Assessment 3 — extend the resolver, or replace it?

**Extend.** Today's "resolver" is a set of correct predicates without a search loop:
| exists (keep as predicates) | role in the new resolver |
|---|---|
| `board/custom/target_compat.py: compatible()` | can this pin do this requirement kind (ok / no / undetermined + cite) |
| `GET …/tasks/<t>/valid-targets` | candidate enumeration for ONE requirement |
| `check_drop()` (422) | refuse a conflicting choice, named |
| `cmod/custom/binding.py: validate` | does the board meet every required task requirement |
| `cmod/custom/claims.py` | turn committed claims into RegisterSettings / FieldSettings / SignalRoutes |
| `board/custom/electrical_check.py` | circuit findings |
| `code_interface.isotopes_for_atom` | derive substitution isotopes |
New layer only: `cmod/custom/resolver/` — enumerate isotopes by `compat`, collect all requirements of all Tasks, order them most-constrained
first, propose claims, run the existing predicates + the new electrical/lifecycle checks, backtrack on conflict, prefer the least
specialised resource, commit. The person-driven path (drag a task onto a pin) keeps working through the same predicates; the resolver
just becomes a second caller. No predicate is rewritten.

### 7.6 Contradictions found (and how each resolves)

1. **R2 stores four Purpose state dimensions** vs the existing derived-status rule → 7.4 (store lifecycle only).
2. **R2 orders phases 0A–0C (Purpose, connectivity, electrical) before Jinja2** vs this plan's first slice (Jinja2 identical-hex gate).
   Technical reason to keep the gate first: it guards the D-fgm-2 tree move and every later template change; it touches no hardware
   rows, so it runs in PARALLEL with the electrical work rather than delaying it.
3. **R2 PinLifecycleConstraint carries its own `override_policy`** vs the existing `DerivedOverride` (who/when/why) → overrides go
   through `DerivedOverride`; never past an electrical safety refusal.
4. **R2's `PurposeScope` / `PurposeParticipant` / `PurposePlacementConstraint` / `PurposeDependency` / `PurposeCommunicationRequirement`**
   overlap placement and the Cross-Domain Solution → one `participants_json` + `depends_on` now (7.4).
5. **My own R2 review (Part 6, fgm-5) placed catoms under `board/firmware/catoms`** — contradicts D-fgm-2/7 → corrected: under the
   owning module inside the parent Hardware tree.
6. **R2 says "SignalPotential" as a separate entity** — the signal side is already carried by PinFunction + PeripheralSignal; add its
   timing / voltage-domain fields there. DrivePotential becomes `ElectricalCharacteristic` per pad CLASS (not per pin), which is how
   the datasheet states it.
7. **R2 §12.1's board — PENDING hardware identification (his ruling 7.8.1).** The code models the UNO R3 A000066 (ATmega328P-PU in
   28-SPDIP, Figure 1-1 p.12 cites; ATmega16U2 USB bridge); the physical board on the bench is NOT confirmed. The model must carry
   package variants (DIP-28, TQFP-32 with ADC6/ADC7) and USB-interface variants (16U2 2341:0043 / 2341:0001 / 2a03:0043; CH340
   1a86:7523; others) INDEPENDENTLY, and the app identifies the real board at Detect.

### 7.7 Updated implementation sequence (each slice its own branch, proven on the econ-core test node, nothing starts before his go)

| # | slice | builds | acceptance |
|---|---|---|---|
| 1 | **fgm-0** Jinja2 gate | `cmod/custom/generator/` (StrictUndefined env, typed context, identifier/literal filters) + today's glue and pin_config as templates | `uno-light`, `uno-sim-rig`, `uno-button-clock` render to their identical hex; render twice → same bytes |
| 1′ (parallel) | **fgm-2** UNO hardware truth | `PackageDefinition`/`PackageContact` (DIP-28 + TQFP-32), board component → SoC rows (U1, U2), `ElectricalCharacteristic`, `PowerBudget`, `PinLifecycleConstraint` — every number page-cited from DS40002061B / the R3 pinout or `undetermined`; `electrical_check.py` rules (f) VOH under load (g) group budgets (h) input thresholds incl. D6→D3 (i) abs-max never a target (j) lifecycle conflicts | deliberate invalid configs refused by name: LED without resistor; GPIO on D0 while USB-serial is the transport; SPI on D13 without the L-LED load; the novice chain shows package and lifecycle hops |
| 2 | **fgm-T** the parent Hardware tree | `parent: hardware` in each hardware manifest, one object-tree root, the Hardware home as front door; then `modules/hardware/<sub>/` moves one module at a time (imports aliased) | every module selftest + the fgm-0 hex gate green after each move |
| 3 | **fgm-1** Purpose widening | `CapabilityDefinition`: `lifecycle`, `criteria_json`, `observes_json`, `participants_json`, `depends_on`; derived `resolution`; Initialization Purpose; the R2 three Purposes | existing proofs unchanged; resolution never stored |
| 4 | **fgm-3** Tasks | `TaskDefinition`, `TaskStructBinding` (incl. `isr_shared`), `TaskTrigger`; derived ScheduleSlot as the agreement check | the four Tasks of the light test; agreement check passes |
| 5 | **fgm-4** typed HAL + resolver search | `hal_contract` (five families × kinds, 7.3) on atoms; `HalBinding`; `cmod/custom/resolver/` over the existing predicates; claim `mode`/`state` | light test resolved from scratch; D7 instead of D6 → valid; conflicts backtrack; each binding shows electrical + lifecycle verdicts |
| 6 | **fgm-5** templates for real | multi-fragment isotopes; HAL routines as `catoms/<name>/template.c.j2` under their owning module; the D3 feedback isotope; ATOMIC_BLOCK emitted for `isr_shared` | unchanged atoms → identical hex; new firmware with D3 compiles and passes on the twin |
| 6′ | **ed-0..3** the editor | converter + round-trip selftest → three-pane detail pages → insertion dialog → save through export | jinja → polari → jinja identity on every template |
| 7 | **fgm-6** state registry + relay | `FirmwareEvent`, revisions, bounded queue + overflow report, ack, resync treating reconnect = reboot on the UNO; bridge ack (`grpcbridge/custom/java_bridge_templates.py`); `PurposeObservation` | twin: 20 rapid presses → 20 events or a reported overflow; unplug/replug → consistent state |
| 8 | **fgm-7** bench | the Hardware Bridge App flash + attestation | R2 §12.6 items 1–10 on the real UNO |
| 9 | **fgm-8** portability | second pin assignment; TQFP package; ESP32-C3 | same Tasks/Purposes, different isotopes |

**✅ RULED 2026-10-15 — see 7.8 for the exact wording (supersedes this line's first draft).** Was open: (a) approve 7.4 — Purpose stores lifecycle only; resolution derived; runtime fulfillment + health per
board instance; (b) command acknowledgment: the next state frame confirms a latest-value command (SET_LED), explicit ack only for
events — or ack commands too; (c) the go to start slices 1 and 1′.

### 7.8 His rulings on the three questions (2026-10-15, verbatim intent) and what each changes

1. **Board variant: pending identification.** "Keep the physical Uno variant as a pending hardware-identification question. The model
   must support package and USB-interface variants independently." → `PackageDefinition` and a new `UsbInterfaceDefinition` (the bridge
   chip + its VID:PID set + whether DTR resets the MCU + its own firmware/SoC when programmable) are SEPARATE axes on the board; a
   physical board = one board design × one package × one USB interface. Detect (the app + `pol board detect`) reports which USB
   interface it saw; the package is confirmed by a person (attestation) when not readable.
2. **Purpose state.** "I approve storing lifecycle on the Purpose, deriving resolution from actual bindings, and storing runtime
   fulfillment and health per deployed device. Preserve the declarative fulfillment contract and observation requirements on the
   Purpose." → `CapabilityDefinition` keeps `criteria_json` (the fulfillment contract) and `observes_json` (observation requirements) as
   declared fields; `lifecycle` stored; `resolution` derived from `HardwareBinding` validity; `PurposeObservation` (Purpose × deployed
   BoardInstance): observed fulfillment + health, written by the backend from relayed state.
3. **Command confirmation.** "use correlated state updates as light-command confirmation for the initial milestone, with explicit
   acknowledgment for reliable events. Include command identifiers or equivalent correlation so an unrelated state update cannot be
   mistaken for command completion." → every command carries `command_id` (u16, minted by the sender, monotonic per boot session of the
   SENDER); the firmware echoes `last_command_id` + `last_command_result` (applied | rejected-invalid | rejected-busy) in the state
   struct; a command counts as confirmed only by a frame whose `last_command_id` equals it (and whose `boot_session` is the one the
   command was sent into — a reboot between send and echo means "unknown, resend", never "done"). Reliable events keep explicit ack.

### 7.9 Remaining conflicts to resolve before implementation (none blocks slice 1)

1. **The wire contract changes.** `LightState` v1 (pinned) has no `last_command_id` / `last_command_result` and no event queue fields →
   **`LightState` v2** (new pinned contract; tag order rule), regenerated codec/proto/Java bridge, the `light-toggle` solution minting
   `command_id`, the Hardware Bridge panel's Toggle PUT carrying it. Sequenced AFTER fgm-0 (the identical-hex gate must be green on v1
   first, then v2 is a deliberate, gated change) — it lands in fgm-6.
2. **The Hardware Bridge panel refuses CH340 clones.** Its Detect step matches only 2341:0043 / 2341:0001 / 2a03:0043
   (`polari-app-shell/desktop/.../hardware/BoardDetector.java`). With the variant pending, Detect must read the USB-interface variants
   from the model (7.8.1) instead of a hard-coded list → fgm-2 adds the rows, a small app change follows it.
3. **Purpose names migrate.** Live proofs exist for `light-from-polari` and `light-from-button`; D-fgm-4 adds the R2 three + Initialization.
   Resolution: seed the four new Purposes; set the two old ones to `lifecycle = retired` (their runs stay as history — the first real use of
   the lifecycle field); acceptance Scenarios re-pointed; nothing deleted.
4. **The "task" word (D-fgm-1)** touches page text, seeds and selftest pins across cmod / hwnocode / uno_core_demo → done in fgm-3 in one
   sweep with the pins updated, never piecemeal.
5. **fgm-2 vs the tree move (fgm-T).** Both touch the board module. Order: fgm-0 → fgm-2 merged → fgm-T moves board (with its new rows)
   under the Hardware tree. fgm-2 starts in parallel with fgm-0 because it adds rows/checks only and renders no C.
6. **D3 feedback in the light firmware** changes the C → never inside fgm-0 (which must be byte-identical); it lands in fgm-5 as a new
   isotope, gated by the twin proof, not by the hex.

**Sequence unchanged otherwise (7.7):** slice 1 = fgm-0, the identical-HEX Jinja2 migration; fgm-2 (electrical / package / USB-interface /
lifecycle data) runs independently alongside it. Nothing starts before his explicit go.

### 7.10 The kit on the bench (his photos 2026-10-15; transcribed here — photos NOT committed: barcode + personal background)

**Board identification evidence (not yet a confirmation):** the box is the genuine Arduino Starter Kit, SKU **A000066_K7**, listing "1
ARDUINO UNO board R3"; the cover art shows the socketed 28-pin DIP MCU and the small square USB-bridge chip by the USB-B jack — consistent
with the modelled R3 (ATmega328P-PU DIP-28 + ATmega16U2, USB id 2341:0043). Status stays **pending** until Detect reads the real USB ids
from the board itself (7.8.1); the box becomes a cited source for the KitPart rows and the board's package/USB-interface evidence.

**His rule: "all parts we can use"** — every part in the kit is modelled as usable (a KitPart row with a count, its electrical facts
cited or `undetermined`), whether or not a demo uses it.

**Counts printed on the box ("THIS KIT INCLUDES") vs the code's register** (`board/custom/kit_parts.py`, 23 types, every `kit_quantity`
today "undetermined" — the book prints no counts; the box does):

| box line | count | register row | change in fgm-2 |
|---|---|---|---|
| Projects book (176 pp.) | 1 | — | source document (Datasheet kind other) |
| Arduino UNO board R3 | 1 | arduino-uno | qty 1 |
| USB cable | 1 | usb-cable | qty 1 |
| Breadboard | 1 | breadboard | qty 1 |
| Easy-to-assemble base | 1 | — | new row (mechanical, no electrical role) |
| 9V battery snap | 1 | battery-snap | qty 1 |
| Solid core jumper wires | 70 | jumper-wires | qty 70 + split |
| Stranded jumper wires | 2 | jumper-wires | qty 2 (variant) |
| Light sensors | 6 | phototransistor | qty 6 |
| Potentiometer 10 kΩ | 3 | potentiometer | qty 3, value 10 kΩ |
| Pushbuttons | 10 | pushbutton | qty 10 |
| Temperature sensor | 1 | tmp36 | qty 1 |
| Tilt sensor | 1 | tilt-sensor | qty 1 |
| LCD screen 16×2 | 1 | lcd-16x2 | qty 1 |
| LED bright white | 1 | led | variant white, qty 1 |
| LED RGB | 1 | led | NEW variant rgb (4 legs, common lead — polarity cited or undetermined) |
| LEDs red / green / yellow / blue | 8 / 8 / 8 / 3 | led | per-colour variants with counts (Vf differs by colour — cite or undetermined) |
| Small DC motor 6/9 V | 1 | dc-motor | qty 1, rated 6/9 V |
| Small servo motor | 1 | servo | qty 1 |
| Piezo capsule | 1 | piezo | qty 1 |
| H-bridge motor driver | 1 | h-bridge | qty 1 |
| Optocouplers | 2 | optocoupler | qty 2 |
| MOSFET transistors | 2 | transistor | NEW row `mosfet` (a different device from the bipolar transistors) |
| Transistors | 5 | transistor | qty 5 |
| Capacitors 100 µF / 100 nF / 100 pF | 3 / 5 / 5 | capacitors | per-value variants |
| Diodes | 7 | diode | qty 7 |
| Transparent gels (R, G, B) | 3 | gels | qty 3 |
| Male pins strip (40×1) | 1 | male-header-pins | qty 1 |
| Resistors 220 Ω / 560 Ω / 1 kΩ / 4.7 kΩ / 10 kΩ / 1 MΩ / 10 MΩ | 22 / 7 / 7 / 7 / 22 / 7 / 7 | resistors | per-value variants with counts |

Consequences for the light test: the LED on D6 uses a 220 Ω (22 in the kit) — with a red LED's forward voltage the current is the value
the electrical rule checks; the D6→D3 feedback needs no extra part (a jumper; 70 available); the pushbutton is one of 10; the bench uses
the board's USB cable. Per-part electrical facts that the box does not print (LED Vf per colour, MOSFET/transistor part numbers) stay
`undetermined` until the parts' own markings or datasheets are read — a person can read the part numbers off the transistors and the
H-bridge for us (the attestation path).

### 7.11 Record 2026-10-15: his go, and what starts

His words: "mark those as things to remind me to do and start on the things you can reasonably start on" → then "update plans for record
first". Reminders written to `AI-Notes/ledgers/OWNER_REMINDERS.md` (part markings, board Detect, bench prerequisites, wiring, D-flow-1..6).

**Starting now (things that need nothing from him), one sonnet agent each, own worktree, own branch off framework `dev` cf1f32e:**
- **fgm-0** — the Jinja2 identical-hex migration (§7.7 slice 1): branch `dev-fgm-0`. Gate: `uno-light`, `uno-sim-rig`, `uno-button-clock`
  render to their identical hex; render twice → identical bytes; no behaviour change, no wire-contract change, no D3 (that is fgm-5).
- **fgm-2** — the UNO hardware data (§7.7 slice 1′): branch `dev-fgm-2`. Package variants (DIP-28 + TQFP-32), USB-interface variants as
  an independent axis (7.8.1), board component → SoC rows (U1, U2), `ElectricalCharacteristic` per pad class, `PowerBudget` groups,
  `PinLifecycleConstraint` rows, the kit counts from the box (§7.10) incl. the new rows, electrical rules (f)–(j); every number cited
  to DS40002061B / the R3 pinout / the box, else `undetermined`. Renders no C.
**Not starting** (need his input or depend on the above): fgm-T tree move (after fgm-0 + fgm-2 merge), fgm-1 onward, the board-variant
confirmation (needs the board plugged in), part-marking facts (need his photos), the bench, the flow-state decisions.

### 7.12 ✅ fgm-0 BUILT + MERGED 2026-10-15 (framework ed8d38c, sonnet agent)

Generator `cmod/custom/generator/` (StrictUndefined env, refusing filters c_ident / c_type / c_expr / c_int / c_hex / c_block / c_comment /
c_str, typed contexts) + templates `cmod/custom/templates/avr/` (polari_graph.c/.h, Makefile, pin_config.h/.c, shared macro libs) — under
`custom/` because the manifests selftest allows only objects/ custom/ initialData/ as module subdirectories (the §5b on-disk layout must
respect the same rule: `firmware/` will need a manifest-schema allowance, or live under `custom/firmware/` — decide at fgm-5/ed-0).
Legacy emitters kept as `glue_legacy.py` / `pin_config_legacy.py` behind `POLARI_GLUE_LEGACY=1` for diffing. Gate: source byte-identical
legacy vs templates vs committed project for uno-light / uno-sim-rig / uno-button-clock; built hex = committed record (6e8d95d2… ·
1bb5c09e… · d26ddf2e… — note the sim-rig GLUE hex is 1bb5c09e…; 4188f6ae… is its hand-written reference); render twice identical.
Records gain `templates` (name → sha256) + `template_generator: jinja2 3.1.6`. cmod 575 → 631, hwnocode 163, board 440, uno_core_demo 34;
manifests 8/9 (the known pspp/testing legacy). Jinja2 3.1.6 already in the backend image; now declared in requirements.txt.

### 7.13 ✅ fgm-2 BUILT + MERGED 2026-10-15 (framework merge 966fd03 on top of fgm-0, sonnet agent)

Seven board classes (48 total): `PackageDefinition` (28-SPDIP, 32-TQFP) + `PackageContact` (60), `UsbInterfaceDefinition` (ATmega16U2
bridge, CH340), `BoardComponent` (U1 mcu, U2 usb-bridge + a new `atmega16u2` SocDefinition), `ElectricalCharacteristic` (33, per pad
class × condition), `PinGroupBudget` (7 — renamed from PowerBudget: cntfet already owns that class name), `PinLifecycleConstraint` (23).
SocPin gains electrical class + package-contact refs; BoardInstance gains `package_variant` / `usb_interface` / `variant_status` (pending).
Kit: all 25 KitPart rows have box-cited counts (+ `mosfet`, `assembly-base`; variants as `variants_json` on the part). Rules (f)–(j) in
`board/custom/electrical_hw.py`. Cites read page-exact from DS40002061B (sha b9b9d83c…): Table 30-1 pp.322–323 (VOH 4.2 V min @ −20 mA,
VOL 0.9 V max @ 20 mA, VIL 0.3·VCC, VIH 0.6·VCC, RPU 20–50 kΩ, IIH/IIL ≤ 1 µA, group notes 3–4: 2×150 mA source / 3×100 mA sink), abs-max
pp.308/322 (40 mA/pin, 200 mA VCC/GND), the UNO R3 schematic (DTR → C5 100 nF → RESET with the RESET-EN jumper; D0/D1 via 1 kΩ to the
16U2), UNO product datasheet p.6 (−40…85 °C). **Correction found in the schematic:** D13's onboard L LED is driven by an LMV358 buffer whose
input is on SCK — the load on D13 is the buffer input, not the LED. Refusals proven by name: LED with no resistor; GPIO on D0 while the
transport is USB-serial; SPI on D13 without the `l-led` acknowledgment; a design relying on abs-max; 153 mA over a 150 mA group; a 25 mA load
on the D6→D3 net. The light test: no refusal; five findings `undetermined` (red LED Vf ×3, pushbutton closed resistance, supply total).
Merged-tree selftests: board 498, cmod 631, hwnocode 163, uno_core_demo 34.
**Follow-ups found:** (1) the older rule (a) `led_current` still assumes 2.0 V Vf from the circuit rows and reports ok while rule (f)
says the Vf is uncited — reconcile in the next hardware slice (rule (a) must read the same cited Vf or report undetermined); (2) no page /
table shows the new classes yet (plain-words display surface owed — on the chain page and object pages, not the demo page); (3) the
Hardware Bridge app's Detect still hard-codes the genuine VID:PIDs — read `UsbInterfaceDefinition` rows instead (§7.9 item 2); (4) the new
rules are not yet called by a resolver (fgm-4).
**Next per §7.7:** fgm-T (the parent Hardware tree move), then fgm-1 (Purpose widening).
