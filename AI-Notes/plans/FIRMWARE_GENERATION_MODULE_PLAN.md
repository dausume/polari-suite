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

## 8. Purpose no-code (fgm-1, expanded) — the states, the code, what it looks like (his ask 2026-10-15)

His words: "please do work on fleshing out what states are needed and the code for it and what it should look like for purpose no-code."
Rulings it must honour: lifecycle STORED on the Purpose; resolution DERIVED from actual bindings; runtime fulfillment + health PER
DEPLOYED DEVICE; the declarative fulfillment contract and observation requirements live ON the Purpose (§7.8.2); a Purpose answers
"why this is in this firmware"; every task ≥ 1 Purpose and every Purpose ≥ 1 Firmware Solution, ADVISED never blocked; commands are
confirmed by correlated state (§7.8.3).

### 8.1 The principle
A Purpose is drawn as ONE no-code solution of category **`purpose`** — a declarative description, never executed by the engine (the
category validator refuses every compute and runtime kind, the same posture as `cross-domain` / `hardware-app`). The
`CapabilityDefinition` row stays the single source of truth; the drawing is rendered FROM the row, and edits on the canvas write BACK to
the row's fields through one door (never a second copy that can drift).

### 8.2 The states (node kinds), left → right as a person reads a Purpose

| # | state (kind · class) | carries | row field it reads/writes | derived or authored |
|---|---|---|---|---|
| 1 | **Purpose** `purpose-goal` · `PurposeGoalState` | name, the goal sentence ("why this is in this firmware"), lifecycle (draft / enabled / suspended / retired) | `goal`, `title`, `lifecycle` | authored |
| 2 | **Depends on** `purpose-depends` · `PurposeDependsState` | the Purpose that must hold first (every firmware Purpose depends on Initialization) | `depends_on` | authored |
| 3 | **Participant** `purpose-participant` · `PurposeParticipantState` (one per participant) | what takes part and in what role: the board (+ its pending package / USB-interface variant), the MCU, the host + Polari | `participants_json` | authored; refs validated against rows |
| 4 | **When** `purpose-trigger` · `PurposeTriggerState` | what starts it: a hardware event (button press on an interrupt source), a command from Polari (a Struct command field), a period, boot | `criteria_json.trigger` | authored |
| 5 | **Then** `purpose-outcome` · `PurposeOutcomeState` | the expected observable result: a Struct field transition (LightState.led_on flips), a physical output (D6 high) | `criteria_json.outcome` | authored |
| 6 | **Within** `purpose-criterion` · `PurposeCriterionState` (one per criterion) | a measurable bound: max_latency_ms, debounce_ms, freshness_ms, delivery (latest / event-reliable / event-best-effort), reliability, electrical_safety | `criteria_json.criteria[]` | authored |
| 7 | **Polari must see** `purpose-observes` · `PurposeObservesState` (one per item) | a state field or an event Polari must observe, with its delivery kind; a command's correlation (command_id echoed) | `observes_json` | authored |
| 8 | **Done by** `purpose-tasks` · `PurposeTasksState` | the Tasks that fulfil it (today: the atom refs `tasks_by_runtime_json`; after fgm-3 the TaskDefinitions), each linking to the firmware canvas | `tasks_by_runtime_json` | authored (membership doors exist) |
| 9 | **Proved by** `purpose-proof` · `PurposeProofState` | the acceptance Scenario + its DERIVED status (planned / proven-on-twin / proven-on-hardware / failing) + last proof | `acceptance_scenario`, `status`, `last_proof` | scenario authored; status derived, read-only |
| 10 | **Can it run here?** `purpose-resolution` · `PurposeResolutionState` | DERIVED: resolved (a valid HardwareBinding exists for its tasks) / unresolved (none) / blocked (the binding validator's named reason) | — (never stored) | derived, read-only |
| 11 | **On each device** `purpose-observed` · `PurposeObservedState` | DERIVED summary of the per-device runtime rows: per BoardInstance fulfillment (unknown / satisfied / at-risk / violated) + health (unknown / healthy / degraded / failed); the weakest shown, each device one click | `PurposeObservation` rows | derived, read-only |

Edges: one kind, **then**, in the fixed reading order 1 → 11 (the drawing is a sentence: *Purpose … depends on … with … when … then …
within … Polari must see … done by … proved by … can run here … on each device*). Multiple Participants / Criteria / Observes are
stacked in their column.

### 8.3 The code (what lands, all in `cmod` — Purpose already lives there)
- `cmod/objects/cmod/CapabilityDefinition.py` — new fields `lifecycle` (default `enabled`), `criteria_json` (`{trigger, outcome,
  criteria[]}`), `observes_json`, `participants_json`, `depends_on`; `status` unchanged (derived).
- `cmod/objects/cmod/PurposeObservation.py` — NEW runtime row: `purpose`, `board_instance`, `fulfillment`, `health`, `why`, `observed_at`,
  `evidence` (the frame / event that decided it). Written by the backend, never by a person (overrides via `DerivedOverride`).
- `cmod/objects/cmod/Purpose*State.py` — the eleven node-kind classes, each with a `statePalette` (category **Purpose**, plain-words
  description, `displayFields`, `variables`) so the palette is data-driven like `FirmwareRunState`.
- `cmod/custom/purpose_nocode.py` — `render(capability_row) → SolutionDefinition dict` (category `purpose`, the eleven-column layout, every
  state's `displayName` + `purpose` sentence so the canvas card titles itself, links on each state to where it points);
  `validate(definition)` (only Purpose kinds; refuses compute / runtime kinds by name); `write_back(definition, row)` (canvas edits →
  row fields; refuses edits to derived states); `resolution(row, manager)` (from `binding.py`); `observed_summary(row, manager)`.
- `cmod/cmod_capability_api.py` — `GET /api/capabilities/{p}/solution` (the rendered drawing), `PUT /api/capabilities/{p}/solution`
  (write-back), `GET /api/capabilities/{p}/resolution`, `GET/POST /api/capabilities/{p}/observations` (POST = the backend's writer; 403 for
  a person).
- Seeds (`cmod/custom/capabilities.py`): the R2 three — `ensure-button-controls-light`, `ensure-polari-observes-hardware-state`,
  `ensure-polari-can-control-light` — plus `initialization` for uno-light, each with criteria / observes / participants filled; the old
  `light-from-polari` / `light-from-button` set to `lifecycle = retired` (their runs kept as history), acceptance Scenarios re-pointed.
- Pages: the Purpose drawing opens on the existing canvas at `/display/hardware-solutions?solution=purpose-<name>`; the Purposes table
  (c-canvas page) gains columns lifecycle · resolution · observed and a link to each drawing; the Hardware home's "The light demo" group
  gains "The Purposes: why each part exists".

### 8.4 What it looks like (the light test, `ensure-polari-can-control-light`)
```
[Purpose]          [Depends on]     [Participant]        [When]                 [Then]                    [Within]
Polari can         Initialization   UNO R3 (board,       a command from         LightState.led_on         max latency 100 ms
control the light  (board set up)   variant pending)     Polari: SET_LED        equals the command,       delivery: latest-value
enabled                             ATmega328P (MCU)     with command_id        D6 follows                confirmed by command_id
                                    host + Polari
→ [Polari must see]                → [Done by]                     → [Proved by]              → [Can it run here?] → [On each device]
LightState.led_on (latest)          ReceivePolariCommand (rx_pop,    light-from-polari-         resolved: uno-light   uno-light #1:
LightState.last_command_id +        apply, led_toggle) +             acceptance · proven-on-    @arduino-uno-r3       unknown (not
last_command_result                 RelayPolariState (report)        twin (last run …)          valid 11/11           deployed yet)
```
Every card is the generic state card (title = displayName, the purpose sentence beneath, since 2026-10-12); the two derived columns
are grey and read-only; clicking a Task opens the firmware canvas at that atom; clicking a device opens its BoardInstance.

### 8.5 Not in this slice
TaskDefinition (fgm-3) — "Done by" lists atom refs until then; the runtime writer of PurposeObservation from relayed state needs the
command-id contract (fgm-6) — the row class, doors and summary land now with no writer except a selftest; a dedicated Purpose overlay
(the generic card suffices).

### 7.14 ✅ fgm-2 follow-ups closed 2026-10-15 (me, while fgm-1 builds)
- **Rule (a) honest about an assumed Vf** (framework 28f82f9): the circuit LED row carries `v_forward_basis: assumed`; `led_current`
  reports `undetermined` with the assumed figure (13.636 mA) and the Vf-free ceiling (22.7 mA) instead of `ok` — now agrees with rule (f).
  board 498.
- **Detect reads the modelled USB-interface variants** (framework 9ac6f0f + app-shell 89b3ef2): the demo bundle carries
  `usb-interfaces.json` (the board design's `UsbInterfaceDefinition` rows: 16U2 verified with its three ids, CH340 unverified); the
  Hardware Bridge panel's Detect matches those, names the interface it saw, and says when a variant is UNVERIFIED (confirm before
  flashing); with no bundle open the old 16U2-only default is unchanged; an ESP32's CP2102 is still refused by name. cmod 632, desktop 31.
  The runtime deb (polari-shell-core) must be rebuilt to carry this (`pol shell dist --core`) before the bench.
Still open from §7.13: a display surface for the new hardware classes.

### 8.6 ✅ fgm-1 BUILT + MERGED 2026-10-15 (framework merge 52e8205, sonnet agent)
The eleven states as `Purpose*State` classes (category Purpose, statePalette) + `PurposeObservation` (per BoardInstance; writer = the
backend's service account only, a person's POST → 403); `cmod/custom/purpose_{nocode,derived,text,palette,seeds,doors}.py`; a `purpose`
category in `hwnocode/custom/cross_domain.validate` (refuses compute + runtime kinds by name). Doors: `GET/PUT /api/capabilities/{p}/solution`
(PUT writes back to the row; refuses derived-state edits, unknown lifecycle/dependency/participant, and task-list changes — those go through
the existing …/tasks doors), `GET …/resolution` (derived: resolved / unresolved / blocked + the binding's reason), `GET/POST …/observations`,
`GET /api/purposes` (the Purposes table with derived resolution + observed + a drawing link). Seeds: `initialization`,
`ensure-button-controls-light`, `ensure-polari-observes-hardware-state` (its own new acceptance Scenario reusing the button frames),
`ensure-polari-can-control-light`; `light-from-polari` / `light-from-button` lifecycle **retired** (kept with their runs); scenarios
re-pointed — runs recorded under those scenario names before the re-point COUNT for the new Purposes (same steps; said in the scenario
notes). Numbers cited from the variant's own knobs (debounce 30 ms, 10 Hz report → 100 ms bound). Coverage 16/16 atoms named by a live
Purpose. Retired Purposes no longer decide a firmware's proof status. Merged-tree selftests: cmod 698, board 498, hwnocode 163, polariapps
126, uno_core_demo 34, firmwarefaults 197.
**Gaps (next, fgm-1b — Angular):** a Purpose drawing on the canvas must LOAD through `GET …/solution` (so the three derived cards show live
values — today the stored drawing row reads "(worked out when asked)") and SAVE through `PUT …/solution`, never through the canvas's generic
CRUDE auto-save (which would store derived values on the drawing row). Also: initialization has no acceptance (no step kind reads
boot_session — add one in fgm-6 with the boot frame); command_id correlation is declared on the Purpose but not on the wire until fgm-6;
no DerivedOverride path for a person disputing an observation; a reseed overwrites goal/lifecycle edits made through the door (the existing
converge behaviour for goal — decide whether lifecycle should be `keep` in the converge list: recommend yes, it is a person's intent).

### 8.7 ✅ fgm-1b + polish MERGED and SEEN on the test node 2026-10-15/16
- **fgm-1b** (angular 86fe322, sonnet): a `category: purpose` drawing LOADS through `GET …/solution` (derived cards live — the test node
  shows "Proved by … proven-on-twin" and "Can it run here? resolved") and SAVES through `PUT …/solution` (debounced 2 s, only on a real
  change; a 422 is shown on the canvas naming the state); the generic CRUDE auto-save skips Purpose drawings; derived cards refuse edits
  (moving allowed). The CRUDE rows DO carry `category` (verified live), so recognition is by category.
- **Generic card shows the state's own values** (angular 9a64921): the default overlay filled fields from class defaults only (every
  generic card — e.g. a criterion's Bound/Value/Unit — read blank); the canvas now passes `boundObjectFieldValues`.
- **Palette groups + no lanes** (angular, dev-purpose-canvas): `Purpose` and `Cross-Domain` are palette categories of their own (they had
  been folded into Custom); a Purpose drawing is not re-laid into runtime lanes (it pushed every card into a default lane off-screen).
- **Converge keep** (framework 4d6da0d): a reseed never resets a Purpose's `lifecycle`, `status` or `last_proof`.
- Seen past the demo-terms dialog with the new CDP driver (`scratchpad/cdp-shot.js`, memory test-builds-over-ssh).
**Still small:** the first column is clipped at the canvas's left edge until Recenter (initial pan); the Runtime select reads "Python
(Backend) (default)" for a declarative drawing (should read "Declarative — not run"); the canvas viewport cannot show all eleven columns
at once at 1900 px (zoom-to-fit on open would). Not rolled to pol-core yet.

## 9. fgm-3 Tasks — started 2026-10-18 under his night go ("move on autonomously, work through the night")
Scope = §7.7 slice 4 + the terminology rulings (SYSTEM_HIERARCHY_TERMINOLOGY §8: Tasks DERIVED by automation and editable by hand in no-code; a **Task
Plan** is derived for ONE Hardware System, each Task on ONE processor; "Designed for" written once, "Also runs on" recorded; priority deadline-monotonic
with importance breaking ties, overridable) + the attempt engine (MISSION_PROFILE_SOLVER_PLAN §14: the chosen candidate seeds the Task Plan).
- Classes: `TaskDefinition` (name, plan, processor, purposes, steps = CAtom refs in order, trigger, deadline, period, priority derived + override, context
  init/isr/loop/task, struct bindings), `TaskStructBinding` (incl. `isr_shared` → ATOMIC_BLOCK later in fgm-5), `TaskTrigger` (boot | edge | period | command
  | message), `TaskPlan` (hardware system, processor list, tier, chosen variants, designed_for (immutable), also_runs_on [{hardware, how we know}], source
  = derived | edited).
- Derivation: Mission → Purposes → their graph nodes (atoms) + criteria → Tasks grouped per processor and trigger, using the sol-0 candidate's variants/pins.
  The existing derived `ScheduleSlot` lanes become the AGREEMENT CHECK (a Task's context must match the lane its atoms derive).
- Acceptance: the light test's Tasks (init, handle-button-press, relay-state, receive-command, + sense) with triggers/deadlines from the Purpose criteria,
  the agreement check passing, a hand edit kept beside the derived value (DerivedOverride) and surviving a re-derive.
- NOT in this slice: the page-wide word sweep atoms → "steps" (D-fgm-1; touches many pages — its own sweep later); the Task no-code drawing (a configured
  page first); code generation from Tasks (fgm-5/6).
### 9.1 ✅ fgm-3 BUILT 2026-10-18 (framework 502859f; merging after fgm-5a)
- `TaskDefinition`, `TaskStructBinding` (isr_shared), `TaskTrigger`, `TaskPlan`; `cmod/custom/task_plan*.py`. Light Mission on `uno-light-system`, seeded from
  sol-0's chosen candidate (bare-c; at the time: button polled on A0, sense polled on A1): five Tasks on U1 — init (boot, priority 0, agrees init) ·
  handle-button-press (edge polled, debounce 30 ms, 100 ms, 1, agrees loop) · receive-command (USART RX interrupt on D0, 2, agrees) · relay-state (period
  100 ms from TELEMETRY_HZ, labelled estimate, 3, agrees) · sense (A1 polled, 4, UNCHECKED — the gpio-poll route has no atoms yet; with the INT1 candidate
  the sense Task takes the route's atoms and agrees isr). The four 100 ms tasks TIE (deadline + importance) → Purpose order, marked "TIE with …".
- isr_shared: g_toggle_pending, the rx ring head/tail, g_ms. Edits via `POST /api/firmware/overrides` on TaskDefinition (priority, trigger, steps_order,
  deadline_ms, context) survive a re-derive and are flagged when the derived value moves; "Designed for" written once by POST `/api/missions/{name}/task-plan`.
- cmod 1060 (+49), board 734, apps 131. Owed: link `HardwareSystem.task_plan` (still empty, text says "arrives with fgm-3"); rt-0's preview text; the
  sense gpio-poll atoms (or a sense latency criterion so INT1 wins by rule — see MSP plan §14 note).

## 10. fgm-6a — command confirmation on the wire (LightState v2), started 2026-10-18 under the night go
His ruling §7.8.3 (command_id correlation; reliable events with ack) + §7.9.1 (LightState v2 = a deliberate, gated change). To keep the bench path he
has prepared intact (the v1 firmware, the Hardware Bridge deb, the demo bundle), v2 is built as a NEW contract + NEW firmware variant beside v1
(`uno-light-v2`); v1 stays the default until he says switch. Scope: pinned `LightState` v2 (tag order rule) with `last_command_id` (u16, minted by the
sender, monotonic per the sender's boot session), `last_command_result` (applied | rejected-invalid | rejected-busy), `boot_session`; the firmware echoes
them; the backend counts a command confirmed ONLY on a frame whose last_command_id matches within the boot_session it was sent into (a reboot between
send and echo = "unknown, resend"); codec/proto/Java bridge regenerated for v2 alongside v1; twin proof (20 rapid commands → 20 confirmations or
named failures; unplug/replug = reboot → unknown, resend). Identical-hex gate: v1 hexes unchanged; v2's hex is a new recorded baseline.

## 11. C3 pin functions — so the attempt engine can resolve on a second board, started 2026-10-18
The ESP32-C3 model has no PinFunction / PeripheralSignal rows (sol-0 reports it undetermined). Build them from cited Espressif sources (the ESP32-C3
datasheet's pin table + the TRM's IO MUX / GPIO matrix chapters; fetched, hashed, page-cited like the UNO's documents) with `routing = matrix` for
signals the GPIO matrix routes to any GPIO and `fixed` for IO-MUX-only functions, strapping pins and the USB-JTAG pins as lifecycle constraints. Then
sol-0 on the C3 resolves or refuses by rule, and "Also runs on" can record a real second board.
### 10.1 ✅ fgm-6a BUILT 2026-10-18 (framework 54bbb22 + my review fix; merging)
- `LightStateV2` = a NEW class beside LightState (contract `board/custom/contracts/LightStateV2.v1.json`, hash 7168b2d02d82157e, wire v2 5976dfed2e718479):
  the 7 v1 fields + `command_id` (down), `last_command_id` (up), `last_command_result` (up: applied | rejected-invalid | rejected-busy); tags alphabetical
  (fresh class); u16 range enforced in firmware + backend. C codec, proto, Java record/codec/enums generated beside v1 (javac clean).
- Firmware `uno-light-v2`: 3920 B flash / 652 B RAM, baseline hex e288db76… (identical across builds); answers each command with an immediate frame
  (id + result), rejects malformed as rejected-invalid, ignores a repeat of the id it last answered; the button leaves the echo alone; RX_RING 128.
- Backend `board/custom/light_confirm.py` + door GET/POST `/api/board/light-v2` (pending_command + recent commands); `LightCommand` ledger; frame observer
  hook `register_frame_observer` in grpcbridge wire_contract; `light-toggle-v2` built but NOT seeded (v1 stays the default).
- Twin proofs (ScenarioRuns, simavr): 20 rapid commands → 20 confirmations by their own ids; reset mid-answer / mid-command → unknown-resend (sessions 1→2,
  a no-reset control confirmed); 4 malformed commands → rejected-invalid, light stays off, the next good one applies; a button press never confirms a pending
  command (a lost command → unconfirmed at its timeout).
- v1 unchanged: uno-light hex 94b9b77f… (3090/10/503), LightState header + contract file + Java/proto v1 pinned in selftests.
- My review fix: the stale-id hazard the agent flagged (a row's outgoing command_id surviving a board restart would be APPLIED by a later whole-row push) →
  `on_report` clears it when a report shows a new boot_session; selftest.
- To switch the demo to v2 (his word): Hardware Bridge app `LightClient.java` (read/parse → /LightStateV2 or the light-v2 door; toggle → POST + poll
  pending_command), `State.sentence()`, `HardwareBridgePanel.java` SOLUTION/toggle, `Bundle.java` (v2 firmware + bridge.properties + uno-light-app),
  `HardwareBridgeTest.java`; the light page (`hwnocode/light_page.py`: LightStateV2 + LightCommand tables); seed the v2 solution rows (`toggle_v2_rows()`).
### 11.1 ✅ C3 pin functions BUILT 2026-10-18 (framework ea22925; merging)
- Documents fetched + hashed, facts extracted (PDFs not committed): ESP32-C3 datasheet v2.4 (833fc000…), TRM v1.4 (90ef8256…), ESP32-C3-MINI-1/1U datasheet
  v2.2 (de736138…: in-package flash, which pads the module exposes), ESP32-C3-DevKitM-1 guide (e36f1ce3…: headers, RGB LED on GPIO8, the USB-UART bridge).
- Rows: Peripheral 22, PeripheralSignal 178 (the 120 valid GPIO-matrix signals of TRM Table 5.11-1 + JTAG + ADC/USB/XTAL + per-pad), PinFunction 2712
  (2640 matrix-routed = 22 pads × 120 + 72 fixed), `exclusive_group` only where cited (F0/F2/GPIO/matrix outputs of one pad); 43 lifecycle rows (strapping
  GPIO2/8/9, USB GPIO18/19, UART0 GPIO20/21 as the bridge transport, JTAG GPIO4–7, flash GPIO11–17, the RGB LED + boot button); a QFN32 package (33 contacts).
- C3 now: ladder rungs 1/2/6/8 answer from rows (rung 3 undetermined — no E2 header map); analog-in only GPIO0–5; INT/PCINT/PWM/UART/GPIO/ADC/TMP36 routes
  ok on FreeRTOS; the comparator route blocked by name (no comparator in the datasheet's peripheral list); bare-c blocked (no template). sol-0 PLACES the light
  Mission (FreeRTOS, ≈37 s cold): transport GPIO20/21, LED GPIO3, button GPIO10, sense GPIO8 (strapping pad + RGB-LED load → rungs 6/8 conditional risks).
- Engine changes (`soc_functions.py`): ladder / target_compat / eligibility / solve handle a SoC whose functions are PinFunction names; reserved lines refuse
  matrix-routed options as "transport-wire"; strapping pads carry a scarcity tag. UNO behaviour unchanged.
- Open: the C3's E2 header map (rung 3); the N4 vs N4X variant; the bridge wiring + boot button rows are partial; 2712 rows add to the boot-time restore
  (watch the 31-min test-node boot).
- **Live 2026-10-18 (econ-core):** C3 solve via the door → 200 in 15 s, FreeRTOS, transport GPIO20/21, LED GPIO3, button GPIO10 (polled), sense GPIO8 (polled).
  `/api/board/light-v2` → 404 "no LightStateV2 row named 'uno-light-v2'" (expected: v2 is not seeded; a v2 board's first report creates it).
  ⚠ **Backend boot grew to ≈48 min** (10:33 → 11:21; was ≈31) — the C3 slice added ≈3 000 stored rows (2 640 of them mechanical matrix PinFunctions).
  The healthcheck grace is 60 min. NEXT (c3-derive): keep the 72 fixed C3 PinFunctions + the 178 signals as rows and DERIVE the 2 640 matrix-routed
  PinFunctions on read (the overlap-table pattern: code-owned, deterministic, no stored copy to drift); measure the boot before/after.
### 11.2 c3-derive BUILT 2026-10-18 (framework 1b52078 + retire door 16df4b5; merging) + cyc-0 merged (5b4b4bf)
- The 2 640 C3 GPIO-matrix PinFunctions are DERIVED on read (`board/custom/soc_functions.py` `pin_functions(tables, soc)`: stored + derived, deduped by
  name, a stored/edited row wins); every reader moved onto it (ladder, pin view, chain, target_compat, solve, eligibility, claims, scope). Board seed 4 730 →
  2 090 rows; PinFunction in the seed 2 792 → 152; the seed build 18.3 s → 7.7 s on pol-core. Equivalence pinned by sha256 per pad against the old stored set.
- A server seeded before still holds the old copies → GET/POST `/api/board/maintenance/retire-derived-rows` (dry run / {"apply": true}; only rows
  identical to the derived copy; edited rows kept; 503 without a manager) + `pol board retire-derived [--apply] [--api URL]`. To run once on econ-core and
  pol-core after the roll, then measure the boot (was ≈48 min on econ-core).
- Generic `GET /PinFunction` now lists stored rows only (UNO + the C3's 72 fixed); derived rows are served through the domain doors.
- cyc-0 merge note: its "counted by structure" check assumed the polled sense had no atoms (fgm-5b gave it atoms) → the clause now applies only when such a
  part exists.
