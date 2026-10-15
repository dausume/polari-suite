# Polari Firmware Generation Module — Phase 0 reconciliation (gap analysis + file-level plan)

**Date:** 2026-10-15 · **Status:** Phase 0 deliverable of the proposal he pasted 2026-10-15 ("Polari Firmware Generation Module",
ATmega328P, C, Python + Jinja2, bidirectional button-and-LED). Nothing built. Decisions D-fgm-1..6 his.
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

1. **The D3 feedback pin.** §9 re-adds "Feedback input on D3 / PD3 / INT1". His 2026-10-11 ruling cut it: the demo is "a simple light
   test … and that is all" (§5i). The `uno-light` firmware has no D3. → D-fgm-3.
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

## 6. Decisions (his; recommendation first)

- **D-fgm-1 the word "task".** Proposal: Task = dispatchable unit of CAtoms. Pages today call each atom a "task". → **adopt the
  proposal's meaning; atoms are "steps" on pages** (also matches the flow-states plan).
- **D-fgm-2 where the module lives.** A new `firmware/` tree · inside `cmod` (+ `board`, `grpcbridge`) → **inside the existing
  modules** (the proposal itself defers to Polari conventions; a second tree would duplicate rows).
- **D-fgm-3 the D3 feedback pin.** Re-add (stronger proof: the MCU witnesses its own output) · keep cut (your 2026-10-11 ruling) →
  **keep cut for the first milestone; add as a portability-phase sample**.
- **D-fgm-4 Purposes for the light test.** Two (today) · the proposal's three (+ Initialization) → **the proposal's three plus
  Initialization** — the split makes "comm loss must not block local control" provable on its own.
- **D-fgm-5 event delivery for the button.** Latest-value only (today) · reliable events with ack → **reliable events with a bounded
  queue and explicit overflow** (acceptance test 6 requires it).
- **D-fgm-6 hand-written HAL vs templates.** Keep `hal.c` hand-written and template only glue · move HAL isotopes to templates → **move
  HAL isotopes to templates in Phase 3** (it is what makes regeneration with another pin real).
