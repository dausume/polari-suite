# UNO core demo (ucd arc): one bare-bones proof that a Polari Hardware App, its Polari app component and its Firmware Solution talk to one another, composed as ONE Cross-Domain Solution

_Planned 2026-10-07 on suite dev b1836d5. PLAN ONLY — nothing built; his rulings on D-ucd-1..7 and his go start ucd-0._

## §0. His ask, verbatim (2026-10-07, four messages)

> "What I would like to do is make a simple proof based on the arduino uno, that can show thoroughly that everything
> makes sense and works and talks to one another. We should make a very simple firmware that makes date-times on the
> firmware and syncs it with the OS, it then has a single button that controls the light turning on and off, we will
> want to have the button simultaneously be turning on and off and have a pin detecting those switching signals for on
> and off and maintaining a struct on the microcontroller which gets sent back through a configured bridge through the
> kernel and the JavaFx app and up into Polari. We just want to focus on this one demo for now since it brings together
> the core of the functionality we want in a bare bones way."

> "this should be considered the core demo and proof for a Polari Hardware app."

> "this is meant to combine the various kinds of no-code, and we will want to make an overall cross domain app, which
> has the hardware app and it's polari app component it uses and the firmware it uses"

> "and we will want to focus on the cross domain while ensuring we can traverse to the different pieces of no-code we
> need detailed"

Read together: ONE demo, ONE Cross-Domain Solution as its front door, THREE composed parts each in its own no-code
kind (C device tasks → Firmware Solution; Java bridging → the Hardware App; Python/TypeScript → the Polari app
component), every state on the cross-domain canvas opening the detailed no-code behind it and that page linking back.
It is the proof that the `hardware-app` kind works end to end, from a button on a breadboard to a configured page.

## §1. The demo, precisely

### The bench (Arduino Starter Kit parts only — every part is a `kit-parts` row)

| part | pin | role | why this pin |
|---|---|---|---|
| pushbutton (kit) | **D2** (INT0), internal pull-up, 10 kΩ pull-down optional per the book | the person's input | `target_compat` rates `interrupt-in` **ok** only on INT0/INT1; the `HAL_INT0` atom already exists (`hal.c:146-183`) |
| LED (kit) + 220 Ω | **D6** → LED → GND | the light the button controls | D6 already carries the LED in `uno-sim-rig`; the register map row exists |
| one jumper wire | **D6 → D3** (INT1) | **the sense pin**: the MCU independently detects the on/off edges on the LED's own line | his "a pin detecting those switching signals": a real wire, not the MCU reading its own output latch; INT1 is the second `interrupt-in`-ok pin |
| on-board L LED | D13 | mirrors `led_on` | free, nothing to wire |

### The firmware (Firmware Solution `uno-button-clock`, runtime bare C, board arduino-uno-r3)

Tasks (cmod atoms, each parsed from real C, never hand-listed):

1. `clock.tick` — a software wall clock: `epoch_s` + `ms` advanced from `hal_millis()`; `clock_synced` false until the
   host sets it. No RTC chip exists in the kit (D-ucd-4), so the OS is the time source and the MCU keeps it between syncs.
2. `clock.set` — command handler: `SET_TIME{epoch_s, ms}` from the host; records `drift_ms` = (device time before set −
   host time) so the page can SHOW how far the MCU clock wandered since the last sync.
3. `button.isr` — `ISR(INT0_vect)` on D2, falling edge, software debounce (`HAL_INT0_DEBOUNCE_MS`, the atom that
   already exists); increments `button_presses`, sets a `toggle_pending` flag (no work in the ISR beyond that).
4. `led.toggle` — main loop: on `toggle_pending`, flips D6 (and D13), stamps `led_changed_at` with the clock.
5. `sense.isr` — `ISR(INT1_vect)` on D3, ANY-edge (`ISC10`): counts `sense_rises` / `sense_falls`, stamps
   `last_edge_at` (epoch_s, ms). This is the independent witness that the LED line really switched.
6. `telemetry.send` — every `telemetry_hz` ticks, frames the struct below (the `SimRigState_frame` pattern, same
   PolariPacket header + CRC32, same 115200 baud, same presence bitmask).

The struct on the microcontroller (one new wire class, generated through the existing `c_twin` codegen, contract version bumped):

```
ButtonClockState {
  seq            u32   // frame counter
  epoch_s        u32   // device wall clock, seconds
  ms             u16
  clock_synced   bool
  drift_ms       i32   // measured at the last SET_TIME
  uptime_ms      u32
  button_presses u32
  led_on         bool
  led_changed_at u32   // epoch_s
  sense_rises    u32
  sense_falls    u32
  last_edge_at   u32   // epoch_s
  last_edge_ms   u16
}
commands: SET_TIME{epoch_s, ms} · SET_LED{on} (host override, optional, keeps parity with blink-on-command)
```

Invariant the proof checks on every frame: `sense_rises + sense_falls == button_presses` (± the frame in flight) and
`led_on == (sense_rises > sense_falls)`. If the wire is missing the invariant fails loudly and names D3.

### The data path (every hop names what already exists)

```
button → D2 INT0 ──┐
                   ├─ ATmega328P: ButtonClockState ─ USART0 115200 ─ USB CDC ─ kernel cdc_acm (/dev/ttyACM0, dialout)
LED line → D3 INT1 ┘                                                              │
                                                       JavaFX Polari Firmware Installer (the Hardware App on the host)
                                                       hosts the GENERATED Java bridge (SerialCdcPort → GrpcForwarder)
                                                                                  │ gRPC :3002 (PolariGrpcServer)
                                                       Cross-Domain Solution uno-button-clock:
                                                         Firmware Run → Bridge → Relay-in → [backend solution button-clock-ledger]
                                                         Relay-out ← SET_TIME at attach + every N min ← host clock
                                                                                  │
                                                       rows: ButtonClockState (latest) + ButtonClockEvent (one per edge)
                                                                                  │
                                                       /display/uno-core-demo: configured tables + sci-xy-chart (edges over time)
```

Nothing new in the path's mechanisms: `SerialCdcPort`/`GrpcForwarder` are generated today (`java_bridge_templates.py`),
`PolariGrpcServer` listens on 3002 today, Relay-in/Relay-out states exist (fs-2), the display engine exists.

## §2. What exists vs what the demo needs (reuse first)

| need | exists today (path) | missing | we refuse to add |
|---|---|---|---|
| button edge ISR on D2 | `HAL_INT0` atom, `hal_button_init()/hal_presses()`, `hal.c:146-183`, debounce knob; gated behind the sc-1 scenario flag | a seeded variant that turns it on (`variants.py`) | a second button HAL |
| second interrupt pin (sense) | `target_compat.py:158-165` rates INT1 ok; no `INT1_vect` atom | `sense.isr` (a sibling of the INT0 atom, ANY-edge) | PCINT banks (still undetermined, datasheet chapter not fetched) |
| LED on D6 | `uno-sim-rig` register map + `sim_rig.c` LED/PWM | the local button→toggle logic (today LED only by command or self-blink) | — |
| device clock | `hal_millis()` only; no RTC, no datetime anywhere in firmware | `clock.tick` + `clock.set` + `SET_TIME` command (the existing command/apply idiom in `echo.c`/`sim_rig.c`) | an RTC driver (no RTC part in the kit; D-ucd-4) |
| struct telemetry | `SimRigState` + `SimRigState_frame` at `TELEMETRY_MS`; PolariPacket + CRC32; presence mask | `ButtonClockState` wire class + its codegen run | a second framing |
| C project → Firmware Solution → build | cmod atoms (pycparser), `FirmwareSolution`, derived `ScheduleSlot`/`RegisterAssignment`, `glue_build.py`, repro block | the new solution row + graph `uno-button-clock-graph` | a hand-authored schedule |
| twin | `board.custom.twin` (simavr, USART0↔TCP↔pty), sc-1 press injection (`button-bounce-double-count`) | a twin rig that connects D6→D3 inside simavr (irq connect) OR injects INT1 in lockstep with the LED latch | a second simulator |
| serial on the host | the GENERATED bridge's `SerialCdcPort` (raw fd + `stty`, dialout check) | nothing for the bridge; the app shell has NO serial code (it hosts the bridge jar as a child process, per FIRMWARE_EXPORT_PLAN §2) | jSerialComm/RXTX in the shell |
| bridge → backend | `GrpcForwarder` → `PolariGrpcServer :3002`; `bridge.properties grpc.target` | the `HardwareBridgeDefinition` row for `ButtonClockState` (generate_project does the rest) | a second transport |
| cross-domain | fs-2: Firmware Run · Bridge · Relay-in · Relay-out · API call · Frontend emit; `uno-temp-split` as the template | the solution `uno-button-clock` + traversal links on every state (§3) | compute on the canvas (D-fs-3) |
| backend compute | `temp_analysis.py` as the pattern (SolutionDefinition) | `button-clock-ledger`: upsert latest state, append one `ButtonClockEvent` per edge, compute presses/min, flag invariant breaks | logic in Java |
| capability + proof | `CapabilityDefinition` + derived status from `ScenarioRun`; prove door; proof-push door | `button-clock-to-os` definition + its acceptance scenario | a hand-set status |
| flash | `flash.py` docker-with-device stopgap (DEBT), DRY-RUN + `--yes` + read-back | the ONE flash path = the Hardware App (ucd-4) | extending flash.py |
| the Hardware App | `polari-app-shell` frame, `HostInstall` pkexec, `InstanceRegistry`/`OidcClient`, jpackage+deb; FIRMWARE_EXPORT_PLAN §2 (exp-2) | the app itself: the minimal subset in ucd-4 | a second JavaFX frame; connected-mode discovery on swarm (D-ucd-1) |
| app kind | `app.kind: hardware-app` in `polari-app.json`; `BridgingCapability` planned (§2b) | module `uno_core_demo` (kind hardware-app) whose manifest NAMES the three parts; the `BridgingCapability` row for the Installer | a KVM guest for this demo (D-ucd-2) |
| pages | configured tables, sci-xy-chart, the pin map with register assignments, `composed_by` deep links | `/display/uno-core-demo` (configured only) + the readiness row | any new custom component; raw JSON |

## §3. The composition: one Cross-Domain Solution as the front door, three parts behind it

```
uno-button-clock  (Cross-Domain Solution, category cross-domain, NO compute)
├─ Firmware Run   → opens /display/firmware-solutions?solution=uno-button-clock  (task list · schedule · register map · targets)
├─ Bridge         → opens the Hardware App row: BridgingCapability + HardwareBridgeDefinition(ButtonClockState) + its generated project
├─ Relay-in       → opens the backend solution button-clock-ledger on the backend no-code canvas
├─ Relay-out      → opens the SET_TIME command definition (the wire class's command table)
└─ Frontend emit  → opens the display definition of /display/uno-core-demo (the table/graph definitions)
```

**Traversal rule (his fourth message):** every state carries `detail_ref` (class + id) and the detail page carries
`composed_by` back to the cross-domain state — the same two-way idiom the schedule rows already carry to the C canvas.
Spec: from the cross-domain canvas any state opens its detail in ≤ 1 click; every detail page shows "part of
uno-button-clock" and returns in ≤ 1 click; the selection model is the ruled one (select, then confirm; second click
deselects; Escape clears).

**The module** `uno_core_demo` (`polari-app.json`, `app.kind: hardware-app`, `agentTier: hardware`) declares in its manifest:
`firmware: uno-button-clock` (Firmware Solution), `bridge: ButtonClockState` (HardwareBridgeDefinition, hosted by the
Polari Firmware Installer), `polari_app: button-clock-ledger + /display/uno-core-demo`, `cross_domain: uno-button-clock`.
The readiness page lists the three parts with their own status (built / proven-on-twin / proven-on-hardware) and the
composition's status = the weakest part. This is the first `hardware-app` module that is a SHELL-APP realization
(bridging over USB) rather than a KVM guest — D-ucd-2.

## §4. Slices (ordered so every rung is provable before the next; his go per slice)

| slice | builds | proof (a persisted run, never a claim) |
|---|---|---|
| **ucd-0** firmware + twin + CMake export | atoms 1–6, `ButtonClockState` codegen, variant `uno-button-clock`, Firmware Solution + graph, twin rig with the D6→D3 link, capability `button-clock-to-os`, the CMake export directory with `twin`/`board` targets (§5b) | `pol capability prove button-clock-to-os --twin`: injected presses → LED toggles → sense edges counted → invariant holds → SET_TIME lands and `drift_ms` is reported → **proven-on-twin**; the exported directory rebuilds on econ-core (no Polari) to the same `.hex` sha for both targets |
| **ucd-1** cross-domain + app component | Cross-Domain Solution `uno-button-clock`, backend solution `button-clock-ledger`, rows `ButtonClockState`/`ButtonClockEvent`, `/display/uno-core-demo`, traversal links both ways | the twin's frames arrive as rows on the live stack; the chart moves; every state opens its detail and returns (browser pass, his) |
| **ucd-2** the module + the realization field | `hardware-app.realization: kvm \| bridge` (manifest field, validator, derived tier, the two names "Hardware App (KVM)" / "Hardware Bridge App", migration of existing KVM rows — D-ucd-2 ruled); `uno_core_demo` (kind hardware-app, realization bridge) manifest naming the three parts; `BridgingCapability` row (never-run); readiness row | `pol modules conform` refuses a hardware-app without a realization and passes all existing ones; selftest; the readiness page shows the three parts and the composed status |
| **ucd-3** bench, stopgap path | nothing new: flash via the existing `flash.py --yes` (DEBT, last use), the generated bridge jar run by hand on pol-core | `pol capability prove button-clock-to-os --hardware`: real presses → **proven-on-hardware #1**; every refusal recorded verbatim |
| **ucd-4** the Hardware App (exp-2 minimal) | the Polari Firmware Installer: plain JavaFX `Stage`, detect (VID:PID), gate (export → rebuild → sha compare), flash via `HostInstall`-shaped fixed argv, HOST the generated bridge jar as a child, SET_TIME at attach + every N min, local door the backend requests through; `BridgingCapability` → passed by the bridge self-test | **proven-on-hardware #2 through the app**; firmware sha identical to ucd-3's; `flash.py` route retired for the UNO |
| **ucd-5** the other export forms + the Export action | the app as `.deb` (jpackage + the isle-manager-app control/postinst/polkit triple), the bridge `.deb`, the module as a `pol project` directory, "Export all parts"; the Export action on the canvas and the three detail pages with the `Export` rows table (§5b) | an offline install on econ-core flashes the same sha; every export is ≤ 2 clicks from its page and its row states the sha it rebuilt to |

ucd-0..2 need no hardware and no JavaFX. ucd-3 is the first silicon. ucd-4 is the one new codebase.

**Do-not-build list:** no RTC driver; no PCINT; no compute in Java or on the cross-domain canvas; no custom Angular
component; no second serial/framing/transport; no connected-mode discovery stack on swarm (D-ucd-1); no KVM guest;
no extension of `flash.py` beyond its last use in ucd-3.

## §5. Decisions (recommendation first; his to rule)

- **D-ucd-1 — the home stack is a swarm, connected mode is isle-only (his 2026-10-06 ruling).** How does the Hardware App reach Polari on the bench? **Recommend:** the app runs OFFLINE for flashing (reviewed export from disk, the gate, the confirm) and the bridge it hosts reaches the backend by the generated project's existing `grpc.target` plus the pinned instance CA — no discovery, no STOMP push, no manual trust bypass. CONNECTED mode (discovery, "flash the latest", pushes) stays isle-only and is not built here. Alternative: make pol-core an isle first (bigger, blocks the demo on the mesh gap).
- **D-ucd-2 — Hardware App realization. RULED 2026-10-07 ("that sounds good").** Facts: as defined (tree plan §2, sap-1/2, the
  `hardwareapps` module) `hardware-app` was strictly a KVM guest; the JavaFX bridging case came from his 2026-10-06 words and had
  no kind. Ruling: ONE kind `hardware-app` with a required `realization: kvm | bridge` field (the `MeshAppRealization.kind` idiom).
  `kvm` = virtualizes hardware (a guest owning devices by passthrough; needs libvirt, the `hardware` tier; install plan `isle vm
  define/start`; isle-lab, isle-sdr-rx, the router). `bridge` = a JavaFX app on the host binding to external hardware (owns a USB or
  serial port; needs the shell app installed, dialout, a proven `BridgingCapability` transport; install plan = deb + launch; the
  Polari Firmware Installer). Person-facing names: **Hardware App (KVM)** and **Hardware Bridge App**. Tier requirements DERIVE
  from the realization — a bridge app never needs libvirt. Readiness/catalog/tree pages keep one row with two sub-rows. Not a third
  kind. Built in ucd-2: the manifest field, its validator (`pol modules conform` refuses a hardware-app without a realization),
  the derived tier, the two names on the pages; existing KVM rows get `realization: kvm` by migration.
- **D-ucd-3 — the sense pin.** **Recommend:** a real jumper D6 → D3 with INT1 any-edge, so the MCU witnesses the LED line itself. Alternative: read D6's PIN register in the loop (no wire, but it is the MCU reading its own output, a weaker proof).
- **D-ucd-4 — date-time source.** **Recommend:** a software clock synced by SET_TIME from the host at attach and every N minutes, with `drift_ms` measured and shown; no RTC chip (none in the kit; a DS3231 would be a later kit-parts row).
- **D-ucd-5 — what lands as rows.** **Recommend:** both: `ButtonClockState` upserted (latest), `ButtonClockEvent` appended per edge (bounded by a retention knob, default 10 000). Alternative: snapshots only (loses the edge ledger the chart needs).
- **D-ucd-6 — order.** **Recommend:** twin first (ucd-0..2), then silicon through the stopgap (ucd-3), then the Hardware App (ucd-4) proves the same sha through the one real flash path. Alternative: JavaFX first — delays the first silicon by the whole app.
- **D-ucd-7 — firmware build system of the export.** **Recommend:** CMake is THE exported build (toolchain file, `twin`/`board`/`flash` targets); cmod-glue's Makefile stays only as the in-container proof build with a sha parity check (§5b). Alternative: CMake only, rewriting glue_build.py's build leg now (bigger, touches every existing cmod proof).

## §5b. Exports: every part buildable, inspectable, installable outside Polari (his fifth message, 2026-10-07)

> "each of the apps need to be buildable and their code exportable and inspectable and installable via normal cmake for
> firmware so we can inspect the final code for the firmware made for simulation and board specific installable firmware
> cases. and we need easy to see ways that we request those exports in the no-code"

| part | export form | builds with | the two cases, visible in the code |
|---|---|---|---|
| the firmware (Firmware Solution `uno-button-clock`) | a directory (exp-0 shape): the generated C project + `CMakeLists.txt` + `cmake/avr-gcc.toolchain.cmake` + README (what it does, schedule, register map, sizes, sha) + the repro block | **plain CMake**: `cmake -B build -DPOLARI_TARGET=twin|board`; `cmake --build build` → `twin` target = the simavr-runnable ELF, `board` target = the `.hex` + a `flash` target that prints/runs the avrdude argv | `POLARI_TARGET` selects `board_config.h` for simulation (twin link, no fuse/bootloader assumptions) or the board-specific installable case (Optiboot window, DTR reset); both generated outputs are checked in to the export so the final code of EACH case can be read side by side |
| the Hardware App (Polari Firmware Installer) | a Gradle project (the `polari-app-shell` shape) + a jpackage/deb form | `./gradlew jpackage` / `build-launcher-deb.sh` | one app; the generated bridge jar it hosts ships beside it as its own Maven project (below) |
| the bridge (`HardwareBridgeDefinition ButtonClockState`) | the EXISTING generated Maven project (`generate_project`) + `.deb` via the isle-manager-app triple (exp-1) | `mvn package` | `bridge.properties` carries `source=serial|simulated` — the twin vs board case of the bridge |
| the Polari app component (`uno_core_demo` module + `button-clock-ledger` + the display) | the module directory as a `pol project` standalone (polari-app.json, objects/, custom/, initialData/) | `pol project up` (the standalone module dev loop) | — |
| the Cross-Domain Solution | one JSON document (states, edges, detail_refs) inside the module export | — | — |

**Build-system ruling to take (D-ucd-7):** cmod's rule today is "the output is always a real C project, `make` alone
builds" (a Makefile). His word is **CMake**. Recommend: the exported firmware carries BOTH — `CMakeLists.txt` as the
documented, person-facing build (toolchain file, the two targets, `flash`), and cmod-glue's Makefile kept ONLY as the
in-container build the twin/glue proofs already use, with a parity check that both produce the same `.hex` sha. The
export README names CMake as the build; the Makefile is listed as "the proof build".

**Requesting exports from the no-code (easy to see):** one `Export` action, not a new component:
- on the Cross-Domain canvas, the selection bar for a selected state offers **Export** beside its detail link
  ("Export uno-button-clock firmware as a CMake directory · online | offline"); the whole-solution bar offers
  **Export all parts** (one archive with the four directories above and a top README that names which part is which);
- every detail page (Firmware Solution, Bridge, module) carries the same Export row-action at the top, next to
  "part of uno-button-clock";
- an export is an `Export` row (FIRMWARE_EXPORT_PLAN D-exp-1: `module_home('exp')`, generated on request, TTL) with
  `part`, `form` (source-dir | tar | deb | jpackage), `mode` (online | offline), `target` (twin | board | both), the
  sha of what it rebuilds to, and a download link; the row is listed in a configured table on the same page, so a
  person sees what was requested, when, and whether it rebuilt to the same sha (the gate, §3 of the export plan);
- the CLI mirror is `pol firmware export uno-button-clock --form source-dir --target both` /
  `pol app export uno_core_demo --all` (consent, `--json`, journal, per the CLI-wrapped rule).

Spec: from any of the three detail pages or the cross-domain canvas an export is ≤ 2 clicks (select, Export, confirm);
the resulting directory builds on a machine without Polari (econ-core) to the sha the row states; the twin and board
outputs are both present and readable.

## §5c. RULE (his, 2026-10-07): the Hardware Bridge App's communications do not and CANNOT expose the local system to the isle

> "we need to ensure any communications between the hardware app does not and cannot expose any information about the
> local systems to the isle."

What leaves the app, and nothing else — an ALLOW-LIST, structural, not a filter:
- the device frames exactly as the wire class defines them (`ButtonClockState` fields — generated from the row, so the
  outbound schema IS the proto the generator emits; no free-form field, no "extra" map);
- an opaque `BoardInstance` id MINTED BY POLARI at admission (never the host's `/dev/serial/by-id/...` path, never the
  board's USB serial number, never the VID:PID string — those stay in the app; the app reports "board kind X attached"
  by the BoardDefinition name only);
- the firmware sha the app verified, and a BridgingCapability proof verdict (passed/failed + date);
- the commands it accepts (SET_TIME, SET_LED) flow DOWN; nothing about the host flows up with the ack.

Never on the wire, by construction: hostname, username, home paths, kernel/OS version, IPs/MACs, device node paths,
USB serial numbers, the list of other attached devices, logs, stack traces, crash reports, environment. The app keeps
no telemetry channel of its own. "Cannot" is enforced three ways: (1) the only outbound code path is the GENERATED
bridge (`GrpcForwarder`) whose message types come from the wire class — the generator REFUSES a wire class whose
field names or types match the host-fact vocabulary (a validator like the cross-domain one); (2) the app's own
`FirmwareApiClient` has a closed set of request shapes (attach / proof verdict / sha) with no free-text fields;
(3) a capture test in `BridgingCapability.proven_by`: the self-test records the app's outbound bytes against the twin
and asserts none of the host identifiers (collected locally on the test machine) appear — the proof FAILS if any do.
The same posture as [[privacy-no-real-identifiers]], now applied to a running process, not just tracked files.
Recorded as an acceptance item of ucd-4; the vocabulary of refused field names lives in one place (board module).

## §5d. The pin model as it actually is today, and where it is thin (for the ChatGPT discussion, 2026-10-07)

His words: "I do not think the current model for pins is sufficiently robust." The facts, from the code:

**What exists (board module, one class per file):**
- `BoardPin` — one row per board pin: `canonical` (D6), `number`, `soc_pin` (PD6), `net`, `connector_pin`, ONE
  `function` string (gpio | pwm | adc | … | button | led), `peripheral`, `signal`, `firmware_symbol`, `electrical_json`
  (FREE-FORM), `facts_json`, `origin`, `undetermined`.
- `SocPin` — port/bit, package pin, `functions_json` = a LIST OF NAMES verbatim from the datasheet table
  (`PD3: ['INT1', 'OC2B', 'PCINT19']`), `default_function`, one `fact`.
- `BoardNet`, `Connector`, `ConnectorPin` — the KiCad net view; power/ground nets.
- `TargetCompatibilityRule` + `target_compat.compatible()` — a hand-written if-chain: task kind (analog-in, pwm-out,
  uart-rx/tx, i2c-*, spi-*, digital-in/out, interrupt-in, power, ground) vs the NAMES in `functions_json`; INT0/INT1 ok,
  PCINT undetermined, power/ground never.
- cmod's `TargetDefinition` / `RegisterAssignment` — a task port → `lives_on` = a BoardPin name; status bound |
  unbound | conflict (conflict = two tasks on the same PIN).
- `KitPart` rows (23), `DatasheetFact` rows, `pin_roles` (vocabulary with citations).

**Where it is thin — each is a thing the demo would hit:**
1. **"Register" means pin.** No row for a real register: DDRD/PORTD/PIND, EICRA/EIMSK (INT0/INT1 sense bits),
   PCICR/PCMSKn, TCCRnx. The "register map on the pin map" is a pin map. Assigning `sense.isr` to D3 cannot say
   "ISC11:ISC10 = 01 (any edge)" as data; it is C in the atom.
2. **A pin has one `function`.** D13 is both LED and SCK; D3 is INT1 and OC2B and PCINT19. The row keeps one; the
   rest live only in `SocPin.functions_json` as strings. There is no exclusivity knowledge: which alternate functions
   can be ACTIVE at the same time on one pin, which cannot (D11 as MOSI vs OC2A).
3. **No peripheral-level resources.** Timer0/1/2, USART0, ADC, EXTINT, TWI, SPI are not rows anyone can CLAIM.
   `hal_millis` owns Timer2; a PWM on D3 (OC2B) silently fights it; telemetry owns USART0 so D0/D1 are taken — nothing
   records either. Conflict detection stops at "two tasks, same pin".
4. **No pin STATE per firmware.** Direction, pull-up, drive, edge sense, initial level — what D2 IS in `uno-button-clock`
   (input, pull-up, falling) vs in `uno-sim-rig` — is nowhere as data; only the C says it.
5. **Electrical facts are untyped.** `electrical_json` is free JSON; no typed max current per pin / per port / per
   chip, no logic-level or tolerance, so no check that an LED on D6 through 220 Ω is within budget, or that
   driving D6 (output) into D3 (input) is legal while driving two outputs together would not be.
6. **No wiring beyond the board edge.** The jumper D6→D3, the button between D2 and GND, the LED + resistor — the
   breadboard — exist only as prose in the test guide ("left pin → 5V"). `KitPart` rows exist but no row links a part's
   TERMINAL to a board pin or net. So the twin cannot build the D6→D3 link from data, the sim rig cannot be drawn, and
   nothing validates the wiring against the part's limits.
7. **ATmega328P-literal code.** `FUNCTION_PERIPHERAL`, `PWM_FUNCTIONS`, the if-chain, `POWER_LABELS` are written for
   the UNO. The C3 has no SocPin rows (its road says "datasheet-facts: todo"). A second SoC means a second if-chain.
8. **Addressing by canonical name only.** Fine for a header pin; a SoC-only pin, a connector-only pin, a bus endpoint,
   or a pin on an attached module (a shield, a kit part) has no address grammar.
9. **PCINT is undetermined** because the bank registers are not modeled — a symptom of (1) and (3).

**The direction worth discussing (my proposal, not ruled):** a layered, derived, cited model —
- `Peripheral` rows per SoC (TIMER0, USART0, EXTINT, PCINT bank 2, ADC …) with their `Register` rows (name, address,
  bit fields, cited page) — the real register map;
- `PinFunction` rows: SocPin × (peripheral, signal), with an `exclusive_group` so "active at once" is data;
- `BoardPin` keeps canonical/net/connector; `function` becomes DERIVED from the active claims, not a stored string;
- `PinClaim` per Firmware Solution per pin: owner task, mode (in | out | alt:<PinFunction>), pull, edge, initial level
  — rendered INTO the C (DDR/PORT/EICRA values generated, not hand-written) and checked for conflicts at BOTH the
  pin and the peripheral level (`PeripheralClaim`: hal_millis → TIMER2);
- `ExternalConnection` rows: a kit part's terminal ↔ a board pin or net (the breadboard as data) — the twin wires
  simavr from these, the sim-rig drawing renders from these, electrical checks run over these using TYPED fields
  (`max_ma`, `v_level`) moved out of `electrical_json`;
- the compatibility if-chain becomes a table over `PinFunction` rows (one rule set for every SoC), PCINT included.
Each piece is a row a page can show and an export README can print; nothing is typed in that the datasheet or the
C does not already say. This would be its own arc (pin-2?), sized AFTER the discussion; ucd-0 can proceed on the
model as it is (D2/D3/D6 are all INT/GPIO-clean today) while the discussion settles what ucd-1/4 render.

## §5e. ChatGPT round 2 — reply grounded in the code (2026-10-07; round 1 = the §5d facts; his relay)

ChatGPT's consolidated review (relayed by him) proposed: four concepts (HardwareCapability / HardwareConfiguration /
HardwareState / HostObservedState); an address-space model (AddressSpace, MemoryRegion, Bus, Peripheral, Register,
RegisterField, InterruptSource, PeripheralSignal, PinFunction, SignalRoute); ResourceRequirement/ResourceAllocation
around PinClaim; SignalRoute for the C3's GPIO matrix; ElectricalNet/ComponentInstance/Terminal for the breadboard;
typed electrical facts; generate pin config from the model; a HardwareState struct with a bounded transition queue
and versioned serialization; an OS-side C receiver → JNI → JavaFX; reuse of the no-code state system; ten questions.

**Confirmed codebase facts (verified this round):**
- cmod atoms ALREADY derive resources: every register an atom touches (name, access r/w, PERIPHERAL via
  `cmod/custom/registers.py` PERIPHERAL_RULES — USARTn, TIMERn, GPIO PORTx, ADC, EXTINT, PCINT, WDT, EEPROM, SPI, TWI,
  CPU), declared macros (LED_PIN…), globals shared with ISRs, the ISR vector. `registers_atmega328p.json` is a
  derived snapshot from `avr-gcc -E -dM <avr/io.h>` carrying addr, width, SPACE (io | mem) per register + vectors,
  with the avr-libc version and the sha of the -dM text. So the AVR address-space facts and the register→peripheral
  grouping exist as DERIVED data; what is missing is only their promotion to rows a page shows, and bit FIELDS.
- `cmod/custom/targets.py:requirement_kind()` already derives a task's target kind (analog-in, pwm-out, uart-rx/tx,
  interrupt-in, digital-in/out…) from the atom's resources and port shape — ChatGPT's ResourceRequirement exists as a
  derivation, not as a row. `RegisterAssignment` is the allocation row (per solution, per task port → BoardPin).
- Ownership in the real HAL (`board/custom/firmware/uno/hal.c`): Timer2 = `hal_tick_init` (TCCR2A/TCCR2B/TIMSK2,
  lines 119-122) for `hal_millis`; USART0 = `hal_usart_init` (UBRR0/UCSR0A/B/C, 87-98); PWM = Timer0 on D5/D6 or
  Timer1 on D9/D10 (236-242); the button = DDRD/PORTD/EICRA/EIMSK for INT0 (170-174). All of it hand-written C,
  parameterized by `board_config.h` macros rendered from a `FirmwareVariant` row (LED_PIN, PWM_PIN, ADC_CHANNEL,
  TELEMETRY_HZ, FEATURE_*). Pin NUMBERS are generated; register VALUES are not.
- The breadboard already has rows: electrodevice `CircuitDefinition` / `CircuitNetDefinition` (net, is_ground) /
  `CircuitComponentDefinition` (kinds vsource, resistor, capacitor, inductor, diode, led, device; `pins_json` = ordered
  net names; `params_json` ohms etc.) rendering to an ngspice netlist; `BreadboardDefinition` / `ComponentPlacement`
  (tie points) / `BoardJumper`; `PinBindingDefinition` (a design output bit → a vsource). The board module links to it
  only through `BoardNet.circuit_net`. No `switch`/button kind; no typed limits beyond `params_json`; no row puts a
  BoardPin on a circuit net.
- The wire is already versioned and structured: `PolariPacket` (12-byte header + CRC32) + `WireContract` rows
  (contract_version, tag-ordered fields, presence mask, instance-index prelude, wire_version, contract hashes);
  `HardwareBridgeDefinition` (source simulated | serial, serial_device, baud, exposed classes → msg_type, grpc_target,
  device_id). The C struct, the Java record/codec and the Python row are three materializations of ONE Polari class
  (the `c_twin` codegen).
- The simavr twin (`prf-board-engines/polari_avr_twin.c`, 327 lines; `twin_forcing.c`, 672) already observes PB5 by
  ioport IRQ notify, drives ADC channels, raises interrupt VECTORS at a cycle (`--irq-at cycle=,vec=`), pokes RAM,
  traces VCD. No pin-to-pin wiring flag; the button today is injected as the INT0 vector, not as a level on PD2.
- The backend no-code state system: `StateDefinition` (source class, event method, input/output `SlotDefinition`s,
  display fields, category) + `SolutionDefinition` + `StateBuildingBlock`/`SolutionExecutionEngine`; hwnocode adds
  `HardwareSolution`, `HardwareNodePlacement`, `Runtime`, `FirmwareRunState`, `HardwareInterface`; fs-2 adds the
  cross-domain states. Device state = the wire class on the device; host-observed state = the SAME class's row on the
  server after the bridge push, plus `BackendStateChange` events in the relay.

**Answers to the ten questions:**
1. `RegisterAssignment` stays the firmware-binding row. Generalize by ADDING two derived rows beside it, not by
   widening it: `PinClaim` (solution, pin, task, mode in|out|alt:<function>, pull, edge, initial level) and
   `PeripheralClaim` (solution, peripheral, task, usage exclusive | shared-read | shared-config), both derived from
   the atoms' resources + the solution's assignments. `requirement_kind` becomes a stored field on `TargetDefinition`
   (it is computed today and thrown away). Conflicts then check at the pin AND the peripheral level.
2. `BoardNet` stays board-internal (KiCad). External wiring reuses electrodevice: one new membership row
   `BoardPinNet` (board pin → `CircuitNetDefinition` net) + a `switch` component kind + typed limit fields. No
   ElectricalNet/ComponentInstance/Terminal classes — they would duplicate circuit rows that already render to ngspice.
3. One class, three materializations (above). No new state-description system. `StateDefinition` describes how a
   class is a no-code state; the relay states (fs-2) carry the timing/ownership difference. `FirmwareRunState` is the
   firmware-side run row.
4. Pin numbers only (macros from `FirmwareVariant`). Register values are hand C. Phase-1 change: render `pin_config.c`
   (DDR/PORT/EICRA/EIMSK init) from `PinClaim` rows; the HAL atoms call it instead of writing those registers.
5. None as a class. `SocPin.functions_json`, `soc_atmega328p.FUNCTION_PERIPHERAL`, `registers.py` PERIPHERAL_RULES and
   the atoms' resource lists are the peripheral knowledge, all derived. A `Peripheral` + `Register` row pair rendered
   FROM the snapshot is the cheap promotion; `RegisterField` rows only for the fields the demo uses (EICRA ISC, EIMSK
   INT, DDR/PORT bits), cited.
6. The C3 needs: a derivation like `registers.py` over ESP-IDF's `soc/*_reg.h` + `gpio_sig_map.h` (not avr-libc);
   `PinFunction` rows with a `routing` column (fixed | mux | matrix); `compatible()` rewritten as a table lookup over
   PinFunction rows keyed by (task kind → signal) with the routing mechanism deciding whether ANY pin qualifies.
   Deferred to Phase 2; nothing in Phase 1 should hard-code AVR names in a new place.
7. Add two flags to the twin: `--wire PD6:PD3` (ioport notify on the source bit → raise the ioport IRQ on the
   destination; the same simavr APIs the twin already uses) and `--pin-at cycle=,PD2=0|1` (a LEVEL on the pin, so the
   INT0 edge comes from the pin logic, not an injected vector). Both rendered from `BoardPinNet` rows by the twin
   runner — the same rows the electrical check reads.
8. Hardware definitions = board + SoC rows (and the register snapshot); task configuration = `PinClaim`/
   `PeripheralClaim` per Firmware Solution, rendered into `pin_config.c`; `board_config.h` keeps only knobs that are
   not pin configuration (rates, features). The HAL stops owning pin setup.
9. Reuse as is: cmod atoms/glue/graphs, `FirmwareSolution`, `glue_build.py` (make → size → conform → twin equivalence),
   `FirmwareBuild` repro block, `flash.py` DRY-RUN/`--yes`/read-back (last use, ucd-3), `pol capability prove`,
   `ScenarioRun`, `WireContract`/PolariPacket, the generated Java bridge, the twin and its forcing flags.
10. Redundant with the code: ElectricalNet/ComponentInstance/Terminal/NetMembership (electrodevice), a new versioned
    serialization (WireContract), ResourceRequirement as a class (a derived field suffices), HostObservedState as a
    class (the class row itself), AddressSpace/MemoryRegion/Bus for AVR (the snapshot; Phase 3 for custom SoCs),
    "OS C receiver" (next item).

**Where I disagree with the review:**
- "OS C receiver → JNI → JavaFX": Polari's standing language rule is C on MCUs/FPGAs only; Java is the bridge, and
  the generated bridge already reads the serial port (`SerialCdcPort`). No C receiver in the runtime path and no JNI.
  A tiny C reader may ship in the firmware EXPORT as an inspection tool for a machine without Java — not a layer.
- "monotonic time only, RTC later": his ask is date-times synced with the OS. Keep both: `uptime_ms` (monotonic,
  primary ordering) AND the SET_TIME-synced epoch with measured `drift_ms`; the host adds `received_at`. No RTC chip.
- `device_id` is fine (it exists in `HardwareBridgeDefinition`) and is a configured small integer, not a host fact,
  so §5c holds.
- Four new top-level concepts: not as classes. They are the existing rows (capability = board/SoC rows + snapshot;
  configuration = RegisterAssignment + PinClaim/PeripheralClaim; state = the wire class on the device; host-observed
  = the same class's server row + relay events).

**Adopted from the review:** the bounded transition queue on the device (a second wire class `ButtonClockEvent`
with `dropped_events` in the state struct — the bridge already supports several exposed classes per contract),
acquisition and publication as separate atoms, ATOMIC_BLOCK copies (already proven by the torn-millis fault), the
explicit acceptance list (startup, rapid transitions, timestamp ordering, overflow, reconnection), Phase 2/3 as
influences not prerequisites.

**Phase-1 model delta (the whole of it):** rows `PinClaim`, `PeripheralClaim`, `BoardPinNet`; `TargetDefinition.
requirement_kind` stored; `Peripheral`/`Register` rendered from the snapshot + the handful of cited `RegisterField`s;
electrodevice `switch` kind + typed `max_ma`/`v_forward`/`v_level` on the few parts used; `pin_config.c` rendering;
two twin flags; the CMake export. Everything else in the review is Phase 2+.

## §5f. His correction (2026-10-07) + ChatGPT round 3 → the revised Phase-1 scope and the file-level sequence

**His correction, the measure of success:** "intuitive no-code hardware design, exploration, and learning … a novice can
inspect the model and understand why that firmware configures the hardware the way it does." Navigable both ways:
**Board → Pin → SoC Pin → PinFunction → PeripheralSignal → Peripheral → Register → RegisterField**, and from a pin: its
functions, peripherals, registers/fields, the active firmware configuration, the tasks claiming it, electrical facts
and external connections, and the generated C implementing the choices. First-class rows for Peripheral, Register,
RegisterField, PeripheralSignal, PinFunction, SignalRoute even where derived — materialized from authoritative
sources with stable identities, references, provenance, configured views. This OVERRULES ChatGPT's round-3 cut #1
("projection only"); the two reconcile because Polari's idiom IS materialization: rows seeded at boot from a derivation
(`rows()` + `seed_upsert`), `origin` on every row, a disagreement = `BoardConflict`, never a hand edit.

**Verified this round (ChatGPT's four asks):**
1. *Do atom resources carry enough to derive every PinClaim field?* **No.** The scan records register names and r/w
   access (`scan.py` `_write(lvalue)`), ports' directions, declared macros, ISR vectors — not the VALUES written, so
   edge, pull, initial level and alternate-function choice are not derivable; the annotation grammar is
   `in/out/inout/uses/role` only. Per his correction these are the novice's DESIGN CHOICES, so: PinClaim fields
   `mode/pull/edge/initial` are authored on the pin page when a task is registered (the ruled selection-then-confirm
   dialog gathers them, defaults offered from `requirement_kind` + an evidence-bearing suggestion from the circuit
   rows, e.g. "switch to GND with no external resistor → internal pull-up"), provenance `canvas`; an atom may state a
   hard need with ONE new clause `needs(edge=any)`, and a claim that contradicts a need refuses. Nothing is guessed
   from register names.
2. *Can simavr pin-level forcing exercise real EICRA/EIMSK?* By simavr's design yes: `avr_extint` is wired to the ioport
   pin IRQs and evaluates the ISCn mode (low | any | falling | rising) on each level notify, raising the vector only
   when EIMSK enables it; `avr_ioport` handles PCINT masks the same way. **To be PROVEN by the first twin test**, with a
   negative: EIMSK cleared → no ISR; ISC=any → two ISR entries per press+release; ISC=falling → one.
3. *Does the wire/bridge support SET_TIME and reconnect?* SET_TIME fits today: commands are presence-masked fields of
   the class's command frame (the existing PUT path; the next frame's `status` = `commanded` is the ack). `PolariPacket`
   carries a per-frame `sequence`, so gap detection at the packet layer is possible but NOT implemented. No ack
   semantics beyond that. **Reconnect: absent** — `SerialCdcPort` reads a `FileInputStream`, `read()` throws
   `EOFException`, no reopen/backoff anywhere in the template. New, small: reopen with backoff + a `SNAPSHOT` command on
   (re)attach (device answers a full state frame and replays queued events) + sequence-gap counting in the bridge.
4. *Can the register snapshot be shown without persistent rows?* The pages read class rows only, so the answer is the
   materialization idiom above: `Register` rows regenerated from `registers_atmega328p.json` at boot (origin = the
   snapshot's sha), never hand-maintained. The configured table already renders `column:ref:<Class>` as a link to
   `/object/<Class>/<name>`, `refs` for many, `link` for URLs (`class-rows-table.component.ts:53-58`); the object page
   (`instance-detail-panel`) lists related rows by `filterField`/`filterValue`. So BOTH directions of his chain are
   configured tables: forward = ref columns; reverse = "rows of X where <ref> = this" tables on the object's page tabs
   (his per-object display rule). **No new frontend component.** The fs-2 Target-details panel (already custom) gains
   the chain as rows; the graph view (tech-tree/topology layout via `cross_refs_json`) is optional.

**The chain as rows (board module unless noted; all derived+cited, materialized at boot):**
`Peripheral` (<soc>:TIMER2; kind; datasheet chapter) ← from `registers.py` PERIPHERAL_RULES groups ·
`PeripheralSignal` (<soc>:TIMER2:OC2B; channel; direction) ← from the SocPin function lists grouped by peripheral ·
`PinFunction` (<soc>:PD3:OC2B; soc_pin → signal; routing fixed | mux | matrix; exclusive_group) ← from
`SocPin.functions_json` · `SignalRoute` (<solution>:PD3←INT1; the ACTIVE PinFunction a claim selected; fixed on AVR,
matrix later) ← from PinClaim · `Register` (<soc>:EICRA; addr, space io|mem, width) ← from the snapshot ·
`RegisterField` (<soc>:EICRA.ISC1; bits; values with meanings; cite) ← hand-cited for the fields the demo generates
(EICRA ISC0/ISC1, EIMSK INT0/INT1, EIFR INTF0/1, DDRD/PORTD/PIND bit n, PCICR PCIE2, PCMSK2 PCINT18/19 — which also
settles the PCINT "undetermined") · `RegisterSetting` (<solution>:EICRA = 0b00001101; fields set; the claims that
produced it; the `pin_config.c` line) ← from PinClaims — the row a novice reads to see WHY · cmod: `PinClaim`,
`PeripheralClaim` (peripheral + channel + usage exclusive | shared-read | shared-config, so TIMER0's prescaler is
shared-config while OC0A/OC0B are channel-exclusive) · `BoardPinNet` (BoardPin → electrodevice `CircuitNetDefinition`).
Everything stays navigable from D3: PD3 → PinFunctions (GPIO, INT1, OC2B, PCINT19) → signals → EXTINT/TIMER2/PCINT →
EICRA/EIMSK/TCCR2x/PCMSK2 → fields → the solution's PinClaim + RegisterSettings → `pin_config.c` lines → the circuit
net LED_CONTROL and its parts. And back.

**Adopted from round 3:** init vs runtime split (generated `pin_config_init()` owns DDR/PORT/pull/initial, EICRA, EIFR
clear, EIMSK in that fixed order; `sei()` stays in main after all inits; the HAL atoms keep RUNTIME ops only — toggling
D6, reading PIND); provenance comments in generated C naming the PinClaim/RegisterSetting ids; no Polari at build time;
`--wire` validated (driven output → input, shared ground, level-compatible, single driver) before use; minimal
PeripheralClaim with channel-level sharing; typed electrical fields only for the demo's parts; the time model
(`uptime_ms` monotonic + `epoch_ms_est` from an offset + `sync_generation` + `sync_uncertainty_ms`; drift from ≥2 syncs,
never from one; defined after reset; wrap-safe; host `received_at`; adjustments never reorder events); two wire
classes with an explicit overflow policy (drop-oldest + `dropped_events`); the acceptance list.

**Revised Phase-1 slices (replace §4's ucd-0):**
| slice | files (new ⊕ / changed Δ) | tests to extend |
|---|---|---|
| **ucd-0a the hardware object chain** (incl. RegisterField values/meanings/`access`/provenance for every field 0b generates — §5g C) | ⊕ `board/objects/board/{Peripheral,PeripheralSignal,PinFunction,SignalRoute,Register,RegisterField,RegisterSetting,RegisterFieldSetting,BoardPinNet}.py` · Δ `board/custom/soc_atmega328p.py` (chain derivation) · move `cmod/custom/registers.py` + `registers_atmega328p.json` → `board/custom/` (cmod already imports board; no cycle) · ⊕ `board/custom/register_fields_atmega328p.py` (cited) · Δ `board/board_page.py` (tables with `:ref:` columns + per-object reverse tables) · Δ `defClassList`, `feature_imports.py`, `board/polari-app.json` | `board/board_selftest.py` (row counts, every ref resolves, D3 forward+reverse walk), `selftest_manifests` guard, `board_uno_selftest` |
| **ucd-0b claims + generated config** | ⊕ `cmod/objects/cmod/{PinClaim,PeripheralClaim}.py` · ⊕ `cmod/custom/claims.py` (derive, conflicts pin+peripheral+channel) · Δ `targets.py` (store `requirement_kind`) · Δ `annotation.py` (`needs(...)`) · Δ `firmware.py` (validate claims; `assign` door gathers mode/pull/edge) · ⊕ `cmod/custom/pin_config_gen.py` → `pin_config.h/.c` · Δ `board/custom/firmware/uno/hal.c` (init out, runtime kept) · Δ `cmod_firmware_api.py` · Δ `firmware-solution-panel.component.ts` (Target details = the chain rows; the confirm dialog's three fields) | cmod selftests, `tests/cmod_liveboot_probe.py --engines` (glue parity = frames identical), `tests/hwnocode_probe.py` |
| **ucd-0c circuit + checks** | Δ `electrodevice/objects/circuit/_shared.py` (`switch` kind; typed `v_forward`, `max_ma`, `v_level`, `pull`) · ⊕ seed circuit `uno-button-clock` (nets LED_CONTROL, LED_ANODE, GND, BUTTON_INPUT; parts from `kit_parts`) · ⊕ `board/custom/electrical_check.py` (LED current, pin/port/chip budget cited, shared ground, single driver on LED_CONTROL, D2 pull defined) | `electrodevice/circuit_rows_selftest.py`, `board_selftest` |
| **ucd-0d twin at pin level** | Δ `prf-board-engines/polari_avr_twin.c` (`--wire PD6:PD3`, `--pin-at cycle=,PD2=0|1`) · Δ `board/custom/twin.py` (flags from `BoardPinNet`) · Δ `firmwarefaults/custom/harness.py` (step kind `pin-at`) | `tests/board_uno_twin_probe.py` (+ EIMSK-off negative, ISC any/falling counts), `firmwarefaults_selftest` |
| **ucd-0e1 the wire contract** | ⊕ `board/objects/board/{ButtonClockState,ButtonClockEvent}.py` (incl. `boot_session`, `seq`, `dropped_events`, the time fields; commands SET_TIME/SET_LED/SNAPSHOT) + `c_twin` codegen (contract bump; C header, Java record/codec, Python row regenerated) · ⊕ `HardwareBridgeDefinition` row | `grpcbridge` loopback selftest, `WireContract` parity |
| **ucd-0e2 the firmware** | ⊕ `board/custom/firmware/uno/apps/button_clock.c` (atoms clock.tick/clock.set/button.isr/led.toggle/sense.isr/events.queue/telemetry.send; ATOMIC_BLOCK; bounded queue drop-oldest; the time model §5g) · Δ `hal.c` (INT1 atom; init moved to generated config in 0b) · Δ `variants.py` · ⊕ capability `button-clock-to-os` | `hwnocode_probe`, `board_uno_twin_probe`, `pol capability prove … --twin` → proven-on-twin |
| **ucd-0e3 the bridge lifecycle** | Δ `java_bridge_templates.py` (reopen with backoff, SNAPSHOT on attach, sequence-gap counting, reboot vs reconnect by `boot_session`) | loopback selftest + a reconnect case + a reboot case |
| **ucd-0f CMake export** | ⊕ `cmod/custom/export_cmake.py` + `cmake/avr-gcc.toolchain.cmake` template; README with provenance; `twin`/`board`/`flash` targets; Makefile parity sha | `tests/board_installer_probe.py` (+ build on econ-core without Polari) |

ucd-1..5 unchanged. Order: 0a → 0b → 0c → 0d → 0e → 0f, each with its proof before the next; a → d need no hardware.

## §5g. ChatGPT round 4 refinements (2026-10-07) — FINAL Phase-1 structure

**A. RegisterSetting granularity.** `RegisterSetting` = one row per (solution, register, phase: init | runtime), carrying
the final `value`, a `write_mask` (which bits this solution sets; bits outside the mask are left as reset values and
SAID so), and the `pin_config.c` line. Beneath it, `RegisterFieldSetting` = one row per field set: `register_setting`,
`register_field` (→ the cited RegisterField), `value` (+ its meaning from the field's value table), `pin_claim`, `task`,
`rule` (the derivation rule name). Two field settings in one register with overlapping bits = a `conflict` row, never
last-write-wins; two solutions never share a RegisterSetting (it is per solution). `RegisterField.access` is typed:
`rw | r | w1c (write-one-to-clear) | w | rw-strobe`, cited — EIFR's INTFn are `w1c`, so "clear pending" renders as a plain
write of the mask, never a read-modify-write; the generator refuses a field whose access it does not know. The page
for a register shows the bit strip (value per bit, the fields highlighted) and "why these bits have these values"
(one line per RegisterFieldSetting: field · value · meaning · the claim · the task) — both configured tables over
these rows, no custom component (the bit strip is a `bits` column format over `value`+`fields`, one small format
addition if the table lacks it; else a plain per-bit table).
**B. SignalRoute stays in Phase 1**, also for fixed AVR routes: `PinFunction` = what is available; `SignalRoute` = the
selected active route (one per PinClaim that uses an alternate function; `routing` copied from the PinFunction;
`configuration` = the RegisterFieldSettings that make it active, e.g. none for a fixed INT1 pin beyond EIMSK);
`PinClaim` = who asked. References are row NAMES typed by the column's class (`:ref:<Class>`), the Polari idiom —
never an encoded composite that a page would have to parse. The same shape carries the C3 matrix later.
**C. Sequence.** 0a now INCLUDES `RegisterField` values, meanings, `access` and provenance for every field 0b will
generate (the generator reads them; it never carries its own table). 0e splits into **0e1** the wire contract
(`ButtonClockState`, `ButtonClockEvent`, the commands incl. SET_TIME/SNAPSHOT, `boot_session`, contract bump, Java
record/codec + Python row + C header regenerated, loopback selftest), **0e2** the firmware (atoms, queue, time model,
variant, twin proof), **0e3** the bridge lifecycle (reopen with backoff, SNAPSHOT on attach, sequence-gap counting,
reboot vs reconnect). **Boot session ≠ packet sequence:** the device mints `boot_session` at reset (a counter kept in
EEPROM or a 32-bit random from an uninitialised-SRAM seed — pick one in 0e1, cited) and stamps it in every state frame;
the host reads a NEW boot_session as a reboot (fresh state, counters restart, no gap alarm) and the SAME boot_session
with a sequence gap as a transport loss (counted). Neither is confused with the other.

**The two explanation chains, as the acceptance spec of Phase 1 (configured pages, both directions, ≤ 1 click per hop):**
- firmware side: `Firmware Task → PinClaim → SignalRoute → PinFunction → PeripheralSignal → Peripheral → RegisterField
  → RegisterFieldSetting → RegisterSetting → the generated C line`;
- physical side: `Board → BoardPin → SocPin → PinFunction → PeripheralSignal → Peripheral → Register → RegisterField`,
  plus `BoardPin → BoardPinNet → CircuitNet → parts`.
The navigable model is a primary product capability, not a by-product of generation: every row above has a page,
every reference is a link, every reverse table exists.

**Status after round 4:** plan FINAL for Phase 1. **His go for ucd-0a 2026-10-07** ("This is Dustin and I agree on this,
you can start work"). Still owed: D-ucd-1, 3, 4, 5, 6, 7 (recommendations in §5).

### ✅ ucd-0a BUILT 2026-10-07 (branch `dev-ucd-0a` in polari-framework + polari-cli; NOT merged, NOT rolled)
Nine row classes (`Peripheral`, `PeripheralSignal`, `PinFunction`, `SignalRoute`, `Register`, `RegisterField`,
`RegisterSetting`, `RegisterFieldSetting`, `BoardPinNet`); five materialized at boot from the register snapshot (moved to
`board/custom/registers.py`, cmod re-exports), the SoC pin table and a NEW cited field table
(`board/custom/register_fields_atmega328p.py`: EXINT, PCINT bank, ports B/D, MCUCR.PUD, Timer2 — 97 fields, every one
with section/table/page from DS40002061B re-read via pdftotext, sha matched). Counts: 18 peripherals · 83 signals ·
80 pin functions · 96 registers · 97 fields. Reverse links as `*_refs_json` (Class:name) on every row and on
SocPin/BoardPin (`links_refs_json`, new column), so the generic object page walks both ways; six configured tables on
/display/boards (the D3 walk via `GET /api/board/<board>/chain/<pin>`, peripherals, signals, pin functions, registers,
fields) with `:ref:` / `:refs` columns; `pol board chain <board> <pin>`. Peripheral ids unified (EXINT, AC — the datasheet's
names) across registers.py / FUNCTION_PERIPHERAL / cmod targets / the committed firmware manifest. Also closed: KitPart was
never in `defClassList` (the guard named it). Tests: board_selftest 322/322 (+21 chain checks: construction, counts,
citations, typed access, every forward ref + every reverse link resolves, the D3 walk forward and reverse, refusal, the
board object unchanged); cmod_selftest 169/169; selftest_uno + selftest_firmwaresol exit 0; manifests guard 8/9 (the one
failure = the parked pspp/testing legacy classes, pre-existing, not board); `cmod conform uno` changed only the 3 EXINT
spellings. **Limitations:** fields captured for EXINT/PCINT/ports B+D/Timer2 only (the rest say so in
`Register.undetermined`); `exclusive_group` undetermined (not cited); directions derived by signal family, 'undetermined'
where mode-dependent; the ESP32-C3's SocPins carry no chain (matrix = Phase 2); `PeripheralSignal` has no datasheet
chapter cite for AC/WDT/EEPROM/CPU/CLOCK/RESET (said in `undetermined`); the firmware-solution panel's Target details does
not yet show the chain (ucd-0b); the four settings/route/circuit rows are defined and empty by design; the live stack is
not rolled (his call). Manifest `generate` again dropped `requires.engines` + rewrote `selftests` — restored by hand
(DEBT unchanged).
**ROLLED LIVE 2026-10-07** on the home swarm from `dev-ucd-0a` (backend image 76d499023813): `/api/board/arduino-uno-r3/chain/D3`
answers `source: live`, 45 hops; /display/boards 200; every chain class answers on its CRUDE door. ⚠ Incident during the roll:
`pol rebuild help` RAN the rebuild (the trailing word was ignored) and removed the node stack; volumes survived; recovered by
`pol node build --env staging backend` + `POLARI_MODULES=<the list the rows gave minutes earlier> pol swarm deploy node`
(the resolver's documented bootstrap path while the core is down). Fixed in polari-cli 9914d2c (a trailing help word prints
usage for start|rebuild|stop). Also learned: `pol swarm deploy node` does NOT rebuild images — build first (`pol node build
--env staging backend`), then deploy. Disk pruned after the build. **Second lesson (the 0f roll):** with the tag unchanged
(`prf-backend:staging`) and no registry digest, `docker stack deploy` KEEPS the running task — the 0a roll only took because
the stack had been recreated. The roll recipe is therefore: build → `pol swarm deploy node` (re-renders) → `docker service
update --force polari-node_backend` (and `_frontend` when its image changed). The frontend-only path = the forced update alone.

### ✅ ucd-0b BUILT 2026-10-08 (branch `dev-ucd-0b` in framework / angular / cli / rf-node / suite; two sonnet agents + one for the generator)
Backend: `PinClaim` + `PeripheralClaim` rows (cmod), `RegisterAssignment.config_json` (what a person authored on the pin
page: mode / pull / edge / initial — the assign door accepts `config`), `cmod/custom/claims.py` (pin_claims from
assignments + requirement_kind, peripheral_claims from the atoms' resources with channel-level usage, register_settings →
RegisterSetting / RegisterFieldSetting / SignalRoute rows for PHASE init from the cited RegisterField rows: DDRx, PORTx,
EICRA, EIFR (w1c), EIMSK, PCMSKx, PCICR — bit positions and meanings looked up, never hard-coded; overlapping fields =
conflict), validate() refuses conflicts and names `incomplete` claims; the solution payload gains claims /
peripheral_claims / register_settings / field_settings / routes (materialized into the tables on every GET);
`GET /api/firmware/solutions/<s>/pins/<pin>/chain` (claim + settings + the board hops; an unclaimed pin answers with
hops); `pol firmware claims`. Generator: `cmod/custom/pin_config_gen.py` renders `pin_config.h/.c` into the glue project
(fixed order; masked RMW for rw, plain write for w1c, REFUSES strobe/toggle/read-only fields; provenance comment per
register naming the setting, each field's meaning, claim, task, rule; deterministic bytes); the glue's `main()` calls
`pin_config_init()` first; the HAL's GPIO/EXINT init writes are gated by `POLARI_PIN_CONFIG` so the hand-written
reference keeps its own; **twin proof EQUIVALENT 40/40 frames** (generated config == hand-written init); conform twice
unchanged; export parity still identical (hex 1bb5c09e…). Frontend: Target details "Why this pin is configured this way"
(claim · field-setting lines · 8-bit strips · the chain hops as links · a Hardware chain page link); the Register confirm
gains edge / pull / initial selects by task kind, sent as `config`; tasks show incomplete / conflict chips. Also: the
board worker (isle-core) now lists make + cmake and cmod resolves them remotely, so the page's export verify can run.
Tests: cmod 239/239, board 322/322, manifests 8/9. Limitations: timer / USART / ADC register config stays hand-written in
the HAL (their SignalRoutes stay `planned`); the EXINT path is proven by a synthetic D2 claim only (no interrupt-in task in
uno-sim-rig yet — the button-clock firmware of 0e brings the real one); the confirm sentence omits the alternate-function
name ("as INT1") because the valid-targets door does not carry it yet.
**ROLLED LIVE 2026-10-08** (backend cf4a4af3028a, frontend 7b90e361c23f, runtime.fa28d565…): the solution payload carries the
claims (A0 alt ADC0, D6 alt OC0A, D13 out, D0/D1 alt RXD/TXD) and the two DDR settings; the chain door answers for a claimed pin
(D6: DDRD.DDD6 = 1, 35 hops) and an unclaimed one (D3: claim null, 45 hops); the page's export verify now runs on the isle-core
worker (cmake listed) → **parity identical on the page** (1bb5c09e…). Pending his browser review and his merge word.

### ✅ ucd-0f PULLED FORWARD + BUILT 2026-10-08 (his verdict on the 0a roll: "the key functionality has been drowned under a sea of data")
His ask: "a link that shows just the UI for firmware no code and an export"; "keep [the tables] for more specialized or tabular
displays we can open". Built on `dev-ucd-0a`: **/display/firmware** = the canvas + the exports table, nothing else;
**/display/hardware-chain** = the six chain tables (moved off /display/boards, which is back to its 17 items);
**Export (CMake)** button on the canvas bar → `POST /api/firmware/solutions/<name>/export` → `cmod.custom.export_cmake`
writes `module_home('exp')/<solution>@<stamp>/` = the rendered C byte for byte + `CMakeLists.txt` (the Makefile's exact
flags; targets board / twin / size / flash with the avrdude argv) + `avr-gcc.toolchain.cmake` + `polari-build.cmake` (one
command) + README rendered from the rows (build, the two cases, the flash gate, the board as data, tasks by lane, register
map, sizes, shas, provenance) + `polari-export.json` (every file's sha, usb ids / programmer / baud) and the tar.gz;
`verify()` runs the exported CMake build on the engines image (cmake added to prf-board-engines, 3.31.6; `cmake` is a cmod
engine beside make) and compares the hex sha with the committed Makefile build: **uno-sim-rig = IDENTICAL (4188f6ae…)** —
the same bytes, the twin and the board are one code. `FirmwareExport` row (the durable record; the files are transient),
`GET /api/firmware/exports` + `/<name>/download`, `pol firmware export <solution> --verify`. D-ucd-7 as recommended
(CMake = the exported build, the Makefile = the proof build, parity by sha). Tests: cmod_selftest 179/179 (+10 export
checks incl. parity), board 322/322, manifests 8/9 (parked legacy only). Limitations: one solution exported so far
(uno-sim-rig); `-DPOLARI_TARGET` is a definition the C does not read (proven unused by the identical sha); offline form
(the engines image tar) and the deb/jpackage forms are still exp-3/ucd-5; the Export action lives on the custom panel
(no configured-table action exists); `generate` manifests again dropped `requires`/`selftests` (restored by hand).
**ROLLED LIVE 2026-10-08** (backend fc1c9d86ec31, frontend 76d34915949f, runtime.8c70eadb…): /display/firmware, /display/hardware-chain,
/display/boards all 200; the live export door wrote `uno-sim-rig@2026-10-08T12-06-28` and its download serves the 13-file tar.gz
(21 KB). **Limitation on the server:** verify is REFUSED there, named — inside the backend container avr-gcc resolves to the
remote worker (BOARD_ENGINES_URL → isle-core :9830), which runs single engines and has no cmake; parity shows `not-run` on the
page while the host-side `pol firmware export --verify` proved IDENTICAL. DEBT: a `cmake` engine on the board worker (ship the
rebuilt prf-board-engines to isle-core + list cmake in its /run engines) so the page's export verifies too.

## §5h. ChatGPT round 5 (2026-10-08, relayed): "two revisions against the actual data model" — THE AUDIT, before any table changes

The review asked for (1) a TaskResourceRequirement / TaskResourceAssignment model (many resources per task, typed refs,
a configuration context) replacing a single `target`, and (2) a peripheral-centred hardware/memory-map model (RegisterBlock,
AddressSpace, MemoryRegion, RegisterAddressMapping, SignalRoute as the static route + SignalRouteSelection as the choice,
HardwareConfiguration), with migrations, materialization kept, firmware generation and UI following, and an ordered process:
audit → reconcile → migrate → task refactor → firmware → UI → verify. It admits it has not seen the repository. This section is
the audit it asked for, against the code as it is after ucd-0a/0b.

**A. What already exists, under which names (verified by running the derivations on uno-sim-rig):**
| the review's entity | Polari today | verdict |
|---|---|---|
| HardwareTask | `CGraphNode` (a c-atom instance in a `CGraph`); NO `target` field exists | the "single target" premise is wrong: targets are rows per port |
| TaskResourceRequirement | `TargetDefinition` — ONE ROW PER PORT (or memory field) of a node: `usart_init` → two rows (D0, D1); `apply` → two (D13, D6); `kind` register \| pin \| peripheral \| memory-field \| bus \| dynamic; `direction`, `ctype`, `width`, `unit`, `constraints`, `provenance` | exists; GAPS: `requirement_kind` (uart-rx/tx, interrupt-in …) is derived PER TASK (`targets.requirement_kind`) not per row; no `role`; no `required`; the kind vocabulary is pin-flavoured |
| TaskResourceAssignment | `RegisterAssignment` — one per (solution, task, port): `lives_on` = a BoardPin row name, status bound \| unbound \| conflict, `config_json` (0b: the authored mode/pull/edge/initial), provenance | exists; GAPS: the resource is ALWAYS a BoardPin (no typed peripheral / signal / bus assignment); the configuration context is implicit (= the solution) |
| HardwareConfiguration | `FirmwareSolution` (settings, claims, routes are keyed by solution + phase) | exists under that name |
| derived allocations | `PinClaim`, `PeripheralClaim` (0b; channel + usage exclusive \| shared-read \| shared-config) | exists |
| Peripheral / PeripheralSignal / RegisterField | 0a rows, cited | exists |
| SignalRoute (static possible route) | `PinFunction` (soc_pin × signal, `routing` fixed \| mux \| matrix) | exists under the other name |
| SignalRouteSelection (the choice) | `SignalRoute` (per solution, per PinClaim, `configuration_refs_json`) | exists under the other name |
| Register with width / reset / access | `Register` (addr, addr_mem, space io \| mem, width, reset_value, cited title) | exists; the alias is two COLUMNS, not rows |
| RegisterBlock | `Register.peripheral` (grouping by the datasheet's register-summary naming rules) | implicit; no row; shared/aliased blocks not expressible |
| AddressSpace / RegisterAddressMapping | `Register.space` + `addr` / `addr_mem` | implicit (two spaces on the AVR: I/O and data) |
| MemoryRegion | `SocDefinition.memory_map_json` (flash / sram / eeprom with cited facts) | a JSON column, not rows |
| BoardPin ↔ net ↔ SoC pin | `BoardPin.net`, `BoardNet`, `ConnectorPin.board_pin` — several connector pins on one net already (GND) | exists; not 1:1 |
| "migration" | Polari has no migration framework: derived rows are code-owned and CONVERGE at boot (`_register_owned`); authored data survives through the seed's `keep` list | the migration is a re-derivation + a keep list, never a SQL script |

**B. Reconciliation — what changes (smallest set that gives the review's semantics):**
1. `TargetDefinition` gains `requirement_kind` (stored per ROW, derived per port: the usart atom's two rows become uart-tx and uart-rx
   from the SIGNAL the port is bound to or a `needs(...)` clause — never from a per-task guess), `role` (input \| output \| receive \|
   transmit \| clock \| select \| data \| ''), `required` (bool; a memory-field target is not a hardware requirement), and
   `resource_kind` (pin \| signal \| peripheral \| bus). `requirement_kind()` keeps its signature but reads the row.
2. `RegisterAssignment` gains typed resource columns beside `lives_on`: `peripheral`, `signal`, `bus` (row names; at most one of
   the four non-empty, VALIDATED), `configuration` (= the solution name, explicit), `signal_route` (the chosen PinFunction when a
   pin assignment activates an alternate function). A resource may satisfy requirements of several tasks (shared-read on ADC) —
   already the case; the per-row status stays.
3. NEW rows, derived, materialized: `AddressSpace` (atmega328p: `io` — IN/OUT, 0x00–0x3F; `data` — LD/ST, the I/O space at
   +0x20 — cited §8 "I/O Memory"), `RegisterAddressMapping` (one per register × space: EIMSK → io 0x1D + data 0x3D; the alias as
   ROWS, `Register.addr/addr_mem` become derived from them), `RegisterBlock` (one per peripheral today = the datasheet's register
   summary grouping; `shared_with_refs_json` for a block another peripheral configures through — MCUCR.PUD for the ports; the C3's
   `*_reg.h` blocks later), `MemoryRegion` (from `memory_map_json`, 3 rows). `Register.block` references the RegisterBlock.
4. NAMES: keep the existing class names. `plain_words` and page titles say "task resource requirement" / "task resource
   assignment" / "possible route" / "selected route"; a rename would churn every page, door, selftest and the committed firmware
   manifest for no gain a novice sees. (D-ucd-8, below.)
5. Firmware generation already follows requirement → assignment → claim → RegisterSetting → `pin_config.c` (0b). The pin-mux
   registers that belong to a port or system controller (on the AVR: the peripheral's own enable bits, TXEN0/RXEN0 in UCSR0B,
   COM0A in TCCR0A; MCUCR.PUD for the ports) are the NEXT generation step: PeripheralClaim → RegisterSettings for the enable
   fields, which needs RegisterField rows for UCSR0B / TCCR0A / ADCSRA / ADMUX (cited, ucd-0b2). Until then those routes read
   `planned` honestly.
6. UI: the Target details block gains "resources this task uses" (all of a task's requirements with their assignments and
   routes, so a UART task shows TX and RX together) and the register-first direction already exists (RegisterField →
   RegisterFieldSetting → solution → task, by the rows' refs). Unresolved requirements, conflicts and shared use are the
   status/usage columns the pages already show.

**C. Tests the review lists, mapped:** single-pin GPIO (exists: D13); UART TX+RX as two assignments of one task (exists: usart_init
D0/D1 — becomes an explicit assertion on `role` receive/transmit); I²C shared SDA/SCL and SPI with two chip-selects: NO atoms
exist in the UNO firmware — add two small C fixture atoms under `cmod/custom/fixtures/` (twi_init touching TWCR/TWBR with ports
sda/scl; spi_init + two `spi_select(cs)` ports) so the derivation is tested without inventing firmware; alternate-function conflicts
(exists: `check_drop` + claims conflict); registers/fields independent of pins (exists); address-space alias (EIMSK io/data → the
new mapping rows); stable ids + provenance across re-materialization (add: materialize twice, diff = ∅); legacy target migration
(there is nothing to migrate: `lives_on` already names BoardPin rows or `unbound`; assert no free-string targets exist); generated C
+ reverse navigation (exists: pin_config selftest + the chain door).

**Decisions for him (recommendation first):**
- **D-ucd-8 class names.** Recommend KEEP `TargetDefinition` / `RegisterAssignment` / `PinFunction` / `SignalRoute` and widen them;
  rename only `plain_words` and titles. Alternative: rename to the review's names with converge-time aliasing (every page, door,
  selftest and the committed polari-firmware.json change; a week of churn, no new capability).
- **D-ucd-9 address-space rows now or later.** Recommend NOW (small: 2 AddressSpace + ~100 mapping + 3 MemoryRegion rows, derived
  from data already present), because the C3 and a custom RISC-V need them and the alias becomes a row a novice can click.
- **D-ucd-10 HardwareConfiguration as its own row.** Recommend NOT YET: the FirmwareSolution is the configuration context; a
  separate row only pays off when one solution carries several configurations (variants per board). Keep `configuration` as an
  explicit column (= the solution) so the split is a rename later, not a migration.
- **D-ucd-11 the fixture atoms for I²C/SPI tests.** Recommend YES (two tiny C files, parsed by the same pycparser path), because a
  requirement model proven only on GPIO/UART/ADC would be the review's own objection.

- **D-ucd-12 RULED 2026-10-08 (his words): "We specifically want 'Purpose' as the label for groupings of tasks, and need to
  acknowledge a task can belong to multiple purpose groupings. So it is Task and Purpose which is easy to remember naming wise."**
  → the person-facing words are **Task** (a c-atom instance, a CGraphNode) and **Purpose** (what the arc called a Capability:
  `CapabilityDefinition` with its goal sentence, acceptance proof and derived status). Class names stay (D-ucd-8's posture);
  `plain_words`, page/table titles, the panel's headings and the payload key become Purpose/Task. Membership is MANY-TO-MANY as
  data (it already is: `tasks_by_runtime_json` on each definition names tasks; `composed_by.purposes` is a list per task); the
  Tasks section lists a task under EVERY Purpose it belongs to (never one exclusive bucket), with an "also in" chip; a task in no
  Purpose sits under "No purpose yet". Built as a small slice before 0b2 (one sonnet agent).

**RULED 2026-10-08 (his words: "keep names and widen them for now. add address space rows now. Solutions should be separable
from specific hardware, we should have hardware specific objects that are bindings or masks that bind to the solutions to
combine into making a valid firmware, needing to meet the minimum requirements of the task for the hardware to be a valid
target. Yes"):** D-ucd-8 keep + widen; D-ucd-9 address-space rows now; D-ucd-11 fixture atoms yes; **D-ucd-10 OVERRULED into a
stronger model: the HardwareBinding.** A `FirmwareSolution` is HARDWARE-AGNOSTIC: its tasks (CGraphNodes) and their requirements
(TargetDefinition rows: kind, role, required, constraints). A NEW row **`HardwareBinding`** ('<solution>@<board>') is the
hardware-specific object — the mask that lays the solution over one board: it OWNS the assignments (RegisterAssignment →
re-keyed by binding), the derived PinClaims / PeripheralClaims / SignalRoutes / RegisterSettings / RegisterFieldSettings, and a
`status` valid | incomplete | invalid with `why` = the requirements the board cannot meet (no pin function for the kind, a
peripheral the SoC lacks, a conflict) — "the minimum requirements of the task for the hardware to be a valid target". One
solution may have several bindings (UNO, ESP32-C3, a custom board); `FirmwareSolution.board_definition` becomes the DEFAULT
binding's board (converge: one binding derived per existing solution + its resolved board, assignments carried over by name).
A build/run/export takes a binding, not a bare solution (the CLI/API accept `<solution>` meaning its default binding, or
`<solution>@<board>`). Validity is computed from rows only: every `required` requirement has an assignment whose resource is a
PinFunction/Peripheral/Signal the board's SoC actually has, no two assignments conflict, no peripheral over-claimed. The pages:
a Bindings table on /display/firmware (solution · board · status · why) and the canvas works ON a binding (pick solution, then
board; the pin map is the binding's). This is 0b2's heart; the rest of §5h B/C stands.

✅ **ucd-0b2a BUILT 2026-10-08** (framework 33dd5da on dev-ucd-0b): AddressSpace (io, data — cited §8.5 p.30), RegisterAddressMapping (one per
register per space; io registers carry both, EIMSK 0x1D/0x3D; Register.addr/addr_mem now come FROM the mappings), RegisterBlock (one per
peripheral; MCUCR's block shared with the three GPIO ports, §14.4.1), MemoryRegion (flash/sram/eeprom from the cited memory map); two
tables on /display/hardware-chain; TargetDefinition widened (requirement_kind PER ROW — usart_init's D0 row = uart-rx, D1 row = uart-tx —
role, required, resource_kind), RegisterAssignment widened (peripheral/signal/bus typed refs, at most one, validated; signal_route;
configuration); I²C/SPI fixture atoms prove i2c-sda+i2c-scl and two spi-ss rows for one task; the legacy proof: no free-string target
exists. cmod 275/275, board 333/333, parity identical.
✅ **ucd-0b2b BUILT 2026-10-08** (framework 88ce568, cli 35635ad): `HardwareBinding` ('<solution>@<board>'; is_default; status valid |
incomplete | invalid; why; requirements_met/total; reverse refs to its assignments/claims/settings/routes); one default binding derived per
seeded solution, converges; a person's extra bindings are kept; claims/settings/routes re-keyed by binding (solution kept); validity from
rows only (required rows met by a compatible resource of THIS board; conflicts → invalid; a board without chain rows → incomplete "Phase 2",
never a crash); build/run/export take a binding (non-default = Phase 2, refused by name); doors GET /api/firmware/bindings, POST
/api/firmware/solutions/<s>/bindings {board}, payload `binding` + `bindings`, every {name} accepts <solution>@<board>; Bindings tables on
/display/firmware and /display/firmware-solutions; `pol firmware bindings | bind`. cmod 307/307. Found by it: three requirement rows had the
wrong KIND (tick_init = the TIMER2 peripheral, not pwm-out; led_init = the same D13 as led; rx_pop = the USART0 RXD signal through the ring)
→ ucd-0b2d fixes the derivation so the default binding reads valid by derivation, not by editing data. ✅ **ucd-0b2c + 0b2d BUILT 2026-10-09.** 0b2c (angular): a Binding picker beside the Solution picker (every door re-targeted to
<solution>@<board>; the default stays bare so older backends work), the binding status line with why, "+ bind to another board"
(boards from the readiness door; nothing written before Bind), "Resources this task uses" (every requirement row of the task: port ·
kind · role · required · bound to · status · route — a UART task shows TX and RX together; unbound required rows read "needs a pin";
memory fields dimmed), N/M-bound chips per task. 0b2d (framework): requirement rows typed honestly — tick_init = the TIMER2
peripheral (kind timer, role clock) met by its PeripheralClaim; rx_pop = the USART0 RXD signal through the ring (met via D0); led_init
shares D13 with led; peripheral-level kinds added to the vocabulary (timer, usart, adc, spi, twi, exint, pcint, gpio-port, cited);
`uno-sim-rig@arduino-uno-r3` = **valid 14/14, why ''** — by derivation. The glue project re-rendered (comment names led_init), rebuilt
(hex unchanged 1bb5c09e…), re-proved EQUIVALENT 40/40, conformed twice unchanged. cmod 311/311, board 332/332, manifests 8/9.
**ROLLED LIVE 2026-10-09** (backend b97a5f2's image, frontend a45f4e41, runtime.fd71571a…): bindings door → `uno-sim-rig@arduino-uno-r3
valid 14/14`; the payload serves the DERIVED assignment rows overlaid by live values and joined with the requirement facts (two fixes
found on the live stack: a store predating a field answers None; the facts live on TargetDefinition) — tick_init reads timer · clock ·
peripheral, rx_pop uart-rx · receive · signal, led_init digital-out · output · pin; chain hop detail shows the alias (EIMSK io 0x1d
(0x3D)); export parity identical remote. **Known gap:** a task with several whole-node targets (usart_init: D0 and D1) collapses to ONE
assignment row by name ('<solution>:<task>'), so the page's "Resources this task uses" shows the UART init as one row (uart-tx) instead
of TX + RX; the per-pin claims are right (D0 RXD, D1 TXD). Fix = name whole-node rows per pin when a task has several
('<solution>:<task>@<pin>') — first item of the next slice. Pending his review + merge word.

**Status:** AUDIT ONLY. ucd-0b2 (the reconciliation slice: items B1–B3, B6 and C) starts on his rulings; it is a day of work with
one sonnet agent per half (model + tests; UI).

## §6. Cost, bloat budget, licences

New code: ~6 C atoms + one wire class (small), one Firmware Solution, one Cross-Domain Solution, one backend solution,
two row classes, one display, one module manifest, one small JavaFX app (ucd-4). Zero new images, toolchains,
transports, framings, components. The JavaFX app's measured cost (jpackage image size, RSS) is recorded as a
`ResourceCost` row at ucd-4 per the cost rule. Licences unchanged from FIRMWARE_EXPORT_PLAN §5.

## §7. Ties

DEMONSTRABLES_PLAN §9 (the three solution kinds) · HARDWARE_DEV_PRIORITIES P1/P2/§3b (capabilities, the bench, the
selection model) · FIRMWARE_EXPORT_PLAN §2/§2b/§4 (the Installer, BridgingCapability, exp-2) · HARDWARE_NOCODE_PLAN
(one no-code model) · POLARI_TREE_PLAN §2 (app kinds) · BOARD_PROGRAMMING_PLAN §7a · HARDWARE_ARC_TEST_GUIDE §4–5.
