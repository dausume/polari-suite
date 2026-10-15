# Firmware Generation Architecture — Revision 2: codebase assessment and reconciled plan

**Date:** 2026-10-15 · **From:** Claude (codebase) · **To:** the owner, for relay to the ChatGPT architecture review
**Status:** assessment only; nothing implemented. Supersedes nothing — it reconciles R2 with FIRMWARE_GENERATION_MODULE_PLAN.md
(R1 reconciliation, D-fgm-1..8 ruled 2026-10-15) and FIRMWARE_FLOW_STATES_PLAN.md (the no-code faces).
Paths below are relative to `polari-rf-node/polari-framework/modules/` unless stated.

---

## Part 1 — Current state (inventory with status)

Status key: **IT** implemented + tested · **IU** implemented, under-tested · **P** partial · **PL** planned · **M** missing · **?** unclear.
"Schema" = a row class exists; "runtime" = resolution / generation actually uses it.

### 1.1 Purpose, Task, CAtom, CIsotope

| concept | where | schema | runtime | notes |
|---|---|---|---|---|
| Purpose | `cmod/objects/cmod/CapabilityDefinition.py` (UI word "Purpose") | IT | IT | goal, `tasks_by_runtime_json`, `required_targets`, `exposes_fields`, `acceptance_scenario`, `status` ∈ planned / proven-on-twin / proven-on-hardware / failing — DERIVED from `ScenarioRun` (`cmod/custom/capabilities.py:derive_status`), never hand-set. Attestation (`ScenarioRun` kind `attested`) + `DerivedOverride` rows (who/when/why). `capabilities.purpose_summary` rolls Purposes up into a firmware's / binding's proof status (weakest wins) and advice (advised, never blocked). |
| Purpose instance | `CapabilityInstance.py` | IU | P | one use of a template Purpose; bindings mostly 'unbound' |
| Purpose membership doors | `cmod/cmod_capability_api.py` POST/DELETE `/api/capabilities/{p}/tasks` | IT (13/13 `tests/cmod_hdr4_selftest.py`) | IT | adds/removes `<graph>:<node>` refs |
| Task (dispatchable unit) | — | **M** | **M** | the word "task" on today's pages means an ATOM (D-fgm-1 ruled: adopt R2's meaning, atoms become "steps") |
| Dispatch / schedule | `cmod/objects/cmod/ScheduleSlot.py`, `cmod/custom/firmware.py:schedule_for` | IT | IT (derived only) | lanes isr / tick / loop / init / called DERIVED from atom annotations; not authorable |
| CAtom | `cmod/objects/cmod/CFunctionAtom.py` | IT | IT | ONE parsed C function (pycparser over the real project): ports (`CPort`), `resources_summary`, `registers`, `peripherals`, `globals_touched`, `calls`, `pure`, `isr_safe` + why, `atomic_block`, measured `text_bytes` / `stack_bytes`. It is a concrete function, not a family. |
| CIsotope | `cmod/objects/cmod/CIsotope.py`, `cmod/custom/code_interface.py` | IT (`cmod/custom/selftest_isotopes.py`) | P | parent + `bindings_json` (soc / board / programming → Datasheet) + `substitutions_json` + `source` (parent body with substitutions only) + `minimum_level` (bare-c < freertos < esp-idf/zephyr) + `foundational`. One isotope per atom × binding, DERIVED. No alternatives, no template, not selected by any resolver. Macro-indirected pins (LED_PIN) are listed, not substituted. |
| Graph of atoms | `CGraph`, `CGraphNode` (kind c-atom + glue kinds class/parser/frame/tick/rule), `CGraphEdge` | IT | IT | the canvas draws these; staged columns |
| Firmware solution | `FirmwareSolution.py`, `cmod/custom/firmware.py` | IT | IT | graph + board/variable, derived schedule + register map, validation, proof summary |
| HardwareBinding | `HardwareBinding.py`, `cmod/custom/binding.py` | IT | IT | '<solution>@<board>'; VALID only when the board meets every required task requirement; several per solution |

### 1.2 Hardware model

| concept | where | schema | runtime | notes |
|---|---|---|---|---|
| SoC | `board/objects/board/SocDefinition.py` | IT | IT | `package` is ONE string; `peripherals_json`, `clocks_json`, `memory_map_json` |
| SoC pad / logical pin | `SocPin.py` | IT | IT | `port`, `bit`, `package_pin` (a string), `functions_json`, `default_function`, cited `fact` |
| Package / enclosure variant | — | **M** | **M** | no package entity; DIP-28 vs TQFP-32 (exposes ADC6/ADC7) not representable |
| Package contact | `SocPin.package_pin` field | P | P | a string, not a row |
| Board | `BoardDefinition.py` | IT | IT | ONE `soc` / `soc_definition` per board |
| Board hardware (onboard parts) | `BoardHardware.py` | IU | P | `components_json`, `power_rails_json`, `crystal`, `usb_bridge_chip` — JSON, not rows |
| Board contact / pin | `BoardPin.py` | IT | IT | `soc_pin`, `net`, `connector_pin`, `function`, `peripheral`, `signal`, `electrical_json` (UNO: `{max_ma: 20}` cited to the board pinout), `undetermined` |
| Board net | `BoardNet.py`, `BoardPinNet.py` | IT | IT | `BoardPinNet` ties a BoardPin to a circuit net (role driver / input) |
| Connector / connector pin | `Connector.py`, `ConnectorPin.py` | IT | IT | headers incl. ICSP |
| Board extension (shield) | — | **M** | — | approximated by `electrodevice` breadboard rows (`BreadboardDefinition`, `ComponentPlacement`, `BoardJumper`) and the `KitPart` register; no extension-contact model |
| Connected component / circuit | `electrodevice/objects/circuit/{CircuitDefinition, CircuitNetDefinition, CircuitComponentDefinition}` | IT | IT | the LED + resistor + button circuit exists as rows |
| PinFunction / PeripheralSignal / Peripheral / SignalRoute | `board/objects/board/*.py` (ucd-0a: 18 peripherals, 83 signals, 80 pin functions) | IT (board 440/440) | IT | materialized + cited, reverse links on every row; the chain door `GET /api/board/<b>/chain/<pin>` (45 hops) |
| Register / RegisterField / RegisterSetting / RegisterFieldSetting | same + `AddressSpace`, `RegisterBlock`, `RegisterAddressMapping`, `MemoryRegion` | IT | IT | 96 registers / 97 cited fields; write behaviour handled in the generator (`cmod/custom/pin_config_gen.py` refuses w-strobe and rw-toggle fields by name, masked RMW for the rest) |
| Pin mux | `PinFunction` rows + `board/custom/target_compat.py` | IT | P | AVR fixed alternate functions are represented; compatibility `ok / no / undetermined` + cited reason is used by `valid-targets`, `check_drop` (422) and binding validity — **not** by isotope selection |
| Pin / peripheral claims | `cmod/objects/cmod/{PinClaim, PeripheralClaim}.py`, `cmod/custom/claims.py` | IT | IT | exclusive with a cooperation rule; no shared / time-multiplexed modes; no proposed→committed lifecycle |
| SignalPotential / DrivePotential | — | **M** | **M** | the names exist only in plans; electrical facts live in `BoardPin.electrical_json` |
| Input electrical constraints | — | **M** | — | no VIH / VIL / pull-up range |
| Electrical limits (abs max vs recommended vs typical) | — | **M** | — | one number per pin (`max_ma`), class of limit not recorded |
| Power domains / shared budgets | `BoardHardware.power_rails_json` (volts only) | P | **M** | no port-group or package current budget |
| Datasheet provenance | `Datasheet.py`, `DatasheetFact.py` | IT | IT | kinds soc / board / programming / combined / other; page-exact cites possible (`pdftotext -layout` over the ATmega328P PDF, sha b9b9d83c…); `undetermined` instead of guessing |
| Verification state | `undetermined` flags + `origin` | P | P | no verified / partial / unverified / conflicted enum |
| Circuit-level electrical checks | `board/custom/electrical_check.py` (ucd-0c) | IT | IT | rules: (a) LED current vs the driving pin's cited `max_ma` and the board's logic level; (b) one driver per net; (c) ground reachability; (d) input level compatibility on one board; (e) button pull defined (external or `PinClaim pull='up'`), else WARN. Uncited numbers → `undetermined`. |
| Lifecycle-sensitive pins | `board/custom/power_pins.py` | P | P | 5V / 3V3 / GND / VIN / IOREF / RESET / AREF: purpose + `assignable: false` + reason. **Not** modelled: D0/D1 as the bootloader + USB-serial link, the DTR auto-reset, D13's onboard L LED as a load, ICSP sharing D11–D13, crystal pins (not exposed on the UNO). No phases. |
| Multi-SoC per board / multi-board per solution | — | **M** | **M** | one SoC per BoardDefinition; one board per HardwareBinding; cross-device composition happens only at the cross-domain level (bridge ↔ backend) |

### 1.3 Generation, build, flash, communication

| concept | where | status | notes |
|---|---|---|---|
| Jinja2 in firmware generation | — | **M** | none. Jinja2 + StrictUndefined exist only in infra rendering (`pol-build/render.py` at the suite root) |
| Glue generator | `cmod/custom/glue.py`, `glue_build.py`, `glue_build_light.py` | IT | extracts atom bodies VERBATIM from hand-written C (`board/custom/firmware/uno/{hal.c, apps/*.c}`) and emits main / ISRs / parser / frame / tick in Python string code |
| Register-config generator | `cmod/custom/pin_config_gen.py` | IT | `pin_config.h/.c` from RegisterFieldSetting rows; twin-equivalent 40/40 |
| Multi-fragment isotopes | — | **M** | an atom contributes one function body |
| Determinism | glue records + `FirmwareExport` parity | IT | identical hex for identical inputs (e.g. uno-sim-rig 4188f6ae…, uno-light 6e8d95d2…); CMake export vs Makefile parity |
| Provenance | `composed_by` per task, `firmware` per canvas node, code-interface comments naming the datasheet per identifier, the chain door | P | traceable per ATOM and per register field; not per generated LINE |
| Compile | `cmod/custom/cmod_engines.py` (make / avr-gcc in `prf-board-engines`) | IT | sizes vs board limits |
| Flash | Hardware Bridge App panel (`polari-app-shell/desktop/.../hardware/`, avrdude fixed argv, no `-V`); stopgap `board/custom/flash.py` | IU | the app's flash step has never run on silicon |
| Twin verification | simavr twin + acceptance Scenarios (`firmwarefaults`) | IT | both light Purposes proven-on-twin on the live stack |
| Wire contract / state struct | `grpcbridge` pinned contracts (`LightState` v1), proto + codec gen | IT | tag order rule, versions |
| Bridge | generated Java bridge (`grpcbridge/custom/java_bridge*.py`) | IT on JVM | reconnect, snapshot, gap detection, reboot handling (ucd-0e3); `boot_session` ≠ `seq` already |
| Backend relay | gRPC Push / Commands (`grpcbridge/custom/grpc_server.py`); engine commits relayed to Commands (`polariApiServer/solutionExecutionAPI.py`) | IT to the boundary | screen → live twin end to end unproven |
| Firmware-side registry / events / ack / resync | — | **M** | the light firmware sends one struct every frame; `toggles` detects loss, does not deliver events |

---

## Part 2 — Gap analysis (what R2 adds that is not present)

Genuinely new: **(1)** Task as a dispatchable unit with Struct bindings and authored triggers; **(2)** a SEARCHING resolver (enumerate
isotopes, propose claims, backtrack) — today only validation; **(3)** Jinja2 emission with multi-fragment isotopes and whole-program
assembly; **(4)** typed electrical potentials (drive / input / limits by class) and shared budgets; **(5)** package variants and
extension contacts; **(6)** pin lifecycle constraints with phases; **(7)** firmware-side state registry, events, acknowledgment, resync;
**(8)** Purpose lifecycle and runtime fulfillment / health; **(9)** Purpose participants for multi-device scope.

Already present, R2 should reuse rather than re-specify: derived Purpose proof status and attestation; the whole pad → function →
signal → peripheral → register → field → setting chain with citations and the chain door; claims with conflict refusal; circuit rows
and five electrical rules; deterministic builds with sha parity; the wire contract, the bridge lifecycle, gRPC both ways; the
novice traversal acceptance requirement is already met from Board to RegisterField — the missing half is RegisterFieldSetting →
generated line → isotope → atom → Task → Purpose.

---

## Part 3 — Architectural critique (disagreements and alternatives)

1. **Four Purpose state dimensions: two are right, two are on the wrong object.**
   - *Lifecycle* (draft / enabled / suspended / retired) — keep, stored on the Purpose.
   - *Resolution* (unresolved / resolving / resolved / blocked) — **derive, never store.** It is exactly "does a valid HardwareBinding
     exist for this Purpose's tasks", which `binding.py` already answers. Storing it creates a second source of truth that goes stale on
     every board edit. "Resolving" is a job state, not a Purpose state.
   - *Fulfillment* conflates two things: design-time proof (already exists, derived from ScenarioRuns) and runtime fulfillment of a
     DEPLOYED firmware. Runtime fulfillment is **per board instance**, not per Purpose: two UNOs running the same Purpose can be
     Satisfied and Violated at once. → `PurposeObservation` rows keyed (Purpose, BoardInstance), written by the backend from relayed state.
   - *Execution health* belongs to the deployed instance's Tasks (and the bridge), not the Purpose. The Purpose shows the WORST of its
     instances' health as a derived summary — the same "weakest wins" rule `purpose_summary` already uses.
   - Net: stored = lifecycle; derived = resolution, proof; runtime rows = observed fulfillment + health per instance.

2. **Fulfillment predicates: do not invent a predicate language.** The acceptance Scenario (existing step kinds: pin-at, drive-adc,
   assert-field-arrival, assert-command-echo, …) already is a machine-checkable predicate for design-time proof. Add *typed criteria*
   (`max_latency_ms`, `delivery` ∈ latest | event-reliable | event-best-effort, `freshness_ms`) on the Purpose; the acceptance steps read
   them; runtime evaluation runs in the BACKEND over relayed state (never on the MCU — RULE: no compute added to an 8-bit MCU to judge itself).

3. **Five new scope entities (PurposeScope / Participant / PlacementConstraint / Dependency / CommunicationRequirement) are premature.**
   For milestone 1 add one relation: `participants_json` on the Purpose (refs to SocDefinition / BoardDefinition / host Runtime, with a
   role). Placement already has a home: `hwnocode/custom/placement.py` (RULE 2: what may run where) + `Runtime` rows. Communication
   between participants already IS the Cross-Domain Solution. Dependency between Purposes: Initialization Purpose → everything else is
   the only one we need now; model it as a list field.

4. **The connectivity graph largely exists; add only two entities.** `PackageDefinition` + `PackageContact` (needed: the UNO R3 DIP-28
   and the UNO SMD TQFP-32 expose different pins — ADC6/ADC7 only on TQFP) and `BoardExtension` + `ExtensionContact` (a shield
   consumes board contacts; the kit breadboard is one). Board nets, connectors and circuit nets already form the graph.

5. **Do not create a DrivePotential row per pin.** On AVR every GPIO in a port shares one driver class. Attach typed electrical
   characteristics to the **pin-function class** (e.g. "ATmega328P standard I/O pad at VCC=5 V") and reference it from SocPins; put budgets
   on **groups** (`PowerBudget`: pins in the group, limit, limit class, cite). That is fewer rows and matches how the datasheet states it.

6. **`required_electrical_state` + `override_policy` on lifecycle constraints is too much for milestone 1.** Phases and a policy enum
   (prohibited / conditional / reserved / preserve / free) are enough; overrides go through the existing `DerivedOverride` (who/when/why),
   never past an electrical safety refusal.

7. **R2 is missing four firmware requirements that bite on the UNO specifically:**
   - **Opening the serial port resets the UNO** (DTR auto-reset through the 100 nF capacitor). The bridge's first frames are boot frames;
     every reconnect is a reboot. `boot_session` already detects it — the resync protocol must treat "reconnect" and "reboot" as the same
     event on this board. This belongs in PinLifecycleConstraint (RESET ← DTR) and in the relay design.
   - **D0/D1 are the transport AND the bootloader link.** They must be lifecycle-reserved for USART0 whenever the transport is USB-serial;
     today they are only claimed when an atom happens to use them.
   - **D13 carries the onboard L LED** (a load on SCK). A user putting SPI on D13 or reading D13 as an input must see that load.
   - **Shared-state atomicity.** ISR ↔ Task shared variables need ATOMIC_BLOCK on multi-byte reads (sc-0 already measured the torn-read
     failure on the twin). The Task Struct binding must carry "accessed from ISR" and the generator must emit the guard.
   Also: Optiboot occupies the top 512 B of flash (the size check must subtract it), and the UART RX ring overflow is an event to report.

8. **Debounce — checked in `board/custom/firmware/uno/hal.c`:** today's `ISR(INT0_vect)` does a NON-blocking lockout debounce inside
   the ISR (compares `g_ms` with the last accepted press under `HAL_INT0_DEBOUNCE_MS`), then only counts and sets `g_toggle_pending`;
   the main loop consumes the flag under `ATOMIC_BLOCK`. That is short, non-blocking and already honours R2's rule. A lockout debounce
   accepts the first edge of a bounce burst (good latency, but a single noise spike also counts). The template version keeps this
   isotope as the bare-C default and adds a second isotope "edge + confirm after N ms on the tick" for noisy switches — a choice the
   resolver makes from the Purpose's `debounce_ms` and a switch-quality fact on the kit part, not a new mechanism.
9. **The four-way capability distinction (documented capability / available potential / proposed claim / committed configuration)**
   is right and maps cleanly: PinFunction (documented) → derived availability (computed, not stored) → `PinClaim` with a new
   `state` ∈ proposed | committed → `RegisterSetting` (committed configuration). Availability must stay a COMPUTED view; storing it
   would be the competing source of truth R2 warns against.

10. **Phases 0A–0C before Jinja2 delay the one thing that de-risks everything.** The Jinja2 regression gate (render today's uno-light
    to the identical hex) touches none of the hardware model and should run in parallel, first.

---

## Part 4 — Revised data model

**Reuse unchanged:** SocDefinition, SocPin, BoardDefinition, BoardPin, BoardNet, BoardPinNet, Connector, ConnectorPin, PinFunction,
PeripheralSignal, Peripheral, SignalRoute, Register, RegisterField, RegisterSetting, RegisterFieldSetting, Datasheet, DatasheetFact,
Circuit*, CGraph*, CPort, FirmwareSolution, HardwareBinding, FirmwareExport, ScenarioRun, DerivedOverride, wire contracts.

**Widen (fields):**
- `CapabilityDefinition` (Purpose): `lifecycle`, `criteria_json` (`max_latency_ms`, `delivery`, `freshness_ms`, `debounce_ms`…),
  `participants_json` (ref + role), `depends_on` (list), `observes_json` (state fields / events to publish, with delivery kind).
- `CFunctionAtom` → becomes the **contract** (adds `hal_contract_json`: name · family drive|register|protocol|signal|execution · kind ·
  description); the parsed function becomes its first isotope.
- `CIsotope`: `template_ref`, `fragments_json` (includes / declarations / definitions / init / isr / task-body / build-deps),
  `compat_json` (soc / package / board / toolchain / runtime), `state` (derived | authored).
- `PinClaim` / `PeripheralClaim`: `mode` ∈ exclusive | shared | time-multiplexed, `state` ∈ proposed | committed.
- `SocPin`: `package_contacts` (refs), `electrical_class` (ref).
- `BoardHardware` components → rows where a component is a load on a pin (the L LED).

**New (only these):**
| entity | why it cannot be an existing one |
|---|---|
| `TaskDefinition` | the dispatchable unit (D-fgm-1); atoms inside, Purposes served |
| `TaskStructBinding` | per Task × Struct field: read/write, owner, `isr_shared` (drives the ATOMIC_BLOCK emission) |
| `TaskTrigger` | interrupt source / tick period / command field / dependency; the authored counterpart of ScheduleSlot (which stays as the agreement check) |
| `PackageDefinition`, `PackageContact` | DIP vs TQFP |
| `BoardExtension`, `ExtensionContact` | shields / breadboard as attachable connectivity |
| `ElectricalCharacteristic` | one per pad class × condition: VOH/VOL at IOH/IOL, VIH/VIL, pull-up range, per-pin limits with `limit_class` ∈ abs-max / recommended / guaranteed / typical, `verification` ∈ verified / partial / unverified / conflicted, cite (page / table) |
| `PowerBudget` | a group of pins/ports/rail with a shared current limit, limit class, cite |
| `PinLifecycleConstraint` | pin × phase × policy × reason × cite (RESET←DTR, D0/D1 bootloader, D13 L LED, ICSP, AREF) |
| `HalBinding` | resolved typed variable: catom × name × family/kind → the row it resolves to (SocPin / PinFunction / RegisterField / ElectricalCharacteristic / transport) + validation result. Replaces the untyped `TargetDefinition.lives_on` string over time. |
| `FirmwareEvent` (schema) + `PurposeObservation` (runtime) | event kinds with sequence/delivery; per (Purpose, BoardInstance) observed fulfillment + health |

Not new: FirmwareStateRegistry (= the set of pinned wire contracts + `observes_json`), FirmwareModule (= the on-disk catom layout §5b),
GeneratedCodeProvenance (= a provenance map in the build manifest), SignalPotential (= PinFunction + PeripheralSignal already carry it;
add timing/voltage-domain fields there), PurposeScope/Placement/Communication (Part 3.3).

**Minimum complete electrical data set for the Arduino proof** (all citable from the ATmega328P datasheet DS40002061B + the UNO R3
schematic): VCC 5 V; per-pin current: recommended 20 mA, abs-max 40 mA (abs-max flagged NOT a design target); port-group / package
sums (the datasheet's notes on total IOH/IOL per port group and VCC/GND pin totals); VOH min / VOL max at the stated IOH/IOL; VIH/VIL
thresholds at 5 V; internal pull-up range; LED forward voltage + current from the kit part; resistor value (220 Ω); the button as a
switch to GND; D3's input electricals for the feedback; RESET/DTR, D0/D1, D13-L lifecycle rows.

---

## Part 5 — The pipeline (Purpose → silicon → Polari)

1. **Define** Purposes (lifecycle enabled; criteria; observes; participants: the UNO + host).
2. **Derive Task requirements:** each Purpose names Tasks (HandleButtonPress, RelayPolariState, ReceivePolariCommand + the Initialization
   Purpose's init Task); criteria become trigger requirements (debounce_ms → tick; max_latency_ms → relay period bound).
3. **Contracts:** each Task's CAtoms declare typed HAL variables (families) and Struct bindings.
4. **Enumerate** candidate CIsotopes per CAtom by `compat_json` against the binding's SoC / package / board / runtime.
5. **Resolve** HAL variables against hardware: SocPin ← PinFunction (target_compat), package contact exposed, board contact routed,
   lifecycle constraints respected, `ElectricalCharacteristic` + circuit rules satisfied, `PowerBudget` sums within recommended limits.
6. **Propose claims**; detect conflicts (exclusive peripherals, mutually exclusive functions, conflicting RegisterFieldSettings); backtrack
   to the next isotope / pin; prefer the least specialised resource.
7. **Commit** claims → RegisterSettings (existing `claims.py`) → HalBindings.
8. **Context:** normalized typed objects (no free strings), Struct registry, triggers, init order (authored + derived suggestion).
9. **Render** with Jinja2 (StrictUndefined, identifier/literal filters): isotope fragments assembled into `polari_state.{h,c}`,
   `hardware_init.c` (existing pin_config output folds in), ISRs (minimal: record + notify), Tasks, dispatcher (bare metal), transport,
   `main.c`, Makefile/CMake; provenance map line → template + isotope + binding.
10. **Build** in the engines image; size vs flash minus bootloader / RAM; hex sha; manifest (template versions, compiler flags, model shas).
11. **Prove on the twin**: acceptance Scenarios per Purpose (existing doors), including the deliberately invalid configuration refusal.
12. **Flash** through the Hardware Bridge App (gate → detect → avrdude → read-back).
13. **Relay**: firmware RelayPolariState sends latest-value state (coalesced by revision) and queued events (sequence, ack, overflow
    report); ReceivePolariCommand validates and applies; the Java bridge pushes to Polari; the backend writes `PurposeObservation`.
14. **Attest / measure on hardware** → proven-on-hardware; the novice traversal works in both directions.

---

## Part 6 — Implementation slices (reconciled with existing numbering; each its own branch, proven on the econ-core test node)

| slice | files | acceptance |
|---|---|---|
| **fgm-0** Jinja2 regression gate | `cmod/custom/generator/{env.py, context.py, filters.py}`, `cmod/templates/avr/` (today's glue + pin_config as templates) | `uno-light` renders to the identical hex sha 6e8d95d2…; sim-rig and button-clock identical; determinism test (render twice → same bytes) |
| **fgm-1** Purpose widening | `CapabilityDefinition` fields; `capabilities.py` derive resolution from bindings; Initialization Purpose seeded | the three R2 Purposes + Initialization expressed; resolution derived, never stored; existing proofs unchanged |
| **fgm-2** hardware truth for the UNO | `PackageDefinition/Contact`, `ElectricalCharacteristic`, `PowerBudget`, `PinLifecycleConstraint` rows with page cites; `electrical_check.py` rules (f) VOH under load, (g) budget sums, (h) input thresholds incl. the D6→D3 feedback, (i) abs-max refused as a target, (j) lifecycle conflicts | the deliberately invalid configs are refused by name (LED with no resistor; SPI on D13 without acknowledging the L LED; a GPIO on D0 while the transport is USB-serial); every number cited or `undetermined` |
| **fgm-3** Task + Struct bindings + triggers | `TaskDefinition`, `TaskStructBinding`, `TaskTrigger`; ScheduleSlot as the agreement check | the light test's three Tasks + init; derived schedule agrees |
| **fgm-4** typed HAL + resolver search | `HalBinding`; `cmod/custom/resolver/` (enumerate, propose, check, backtrack, commit); claims `mode`/`state` | resolve the light test from scratch; regenerate with D7 instead of D6 → valid; with D13 → advice; conflict cases backtrack |
| **fgm-5** multi-fragment isotopes + HAL templates + D3 feedback | `CIsotope.fragments_json`; `board/firmware/catoms/<name>/…` (§5b layout, under the parent Hardware tree) | identical hex for unchanged atoms; the D3 feedback isotope; the generated ISR is minimal + ATOMIC_BLOCK where `isr_shared` |
| **fgm-6** state registry, events, relay/receive | `FirmwareEvent`; templates `state/`, `transport/`; bridge ack + resync (`grpcbridge/custom/java_bridge_templates.py`) | twin: 20 rapid presses → 20 events or a reported overflow; unplug/replug (= reboot on the UNO) → consistent state |
| **fgm-7** bench | the Hardware Bridge App; attestation; `PurposeObservation` from relayed state | R2 §12.6 items 1–10 on a real UNO |
| **fgm-8** portability | second pin assignment; the TQFP package; ESP32-C3 (parse its project, iso-2) | same Tasks/Purposes, different isotopes |
| **ed-0..3** (already planned, §5b) | the polari-form ↔ jinja-form editor | round-trip identity |

fgm-0 and fgm-2 can run in parallel (no shared files). Risks: migration of the "task" word on pages (search-and-rename across seeds +
selftest pins); the parent Hardware tree move (D-fgm-2, do it after fgm-0 so the hex gate guards the move); electrical numbers that
need a person's verification (use attestation, never guess).

---

## Part 7 — Questions for the owner (only what the code cannot answer)

1. **Which physical UNO do you have** — the R3 with the socketed DIP chip, or an SMD/CH340 clone? It decides the first package
   variant and the USB ids the app detects.
2. **Purpose state placement (Part 3.1):** approve storing only lifecycle on the Purpose, deriving resolution and proof, and keeping
   observed fulfillment + health as per-board-instance rows? R2's four-dimensions-on-the-Purpose would duplicate data per instance.
3. **Command reliability:** should commands from Polari (SET_LED) also be acknowledged with retry, or is "the next state frame shows
   the result" enough for milestone 1? (Recommend: the state frame is the acknowledgment for latest-value commands; events get explicit
   ack.)
