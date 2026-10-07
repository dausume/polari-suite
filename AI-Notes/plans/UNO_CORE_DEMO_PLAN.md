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

## §6. Cost, bloat budget, licences

New code: ~6 C atoms + one wire class (small), one Firmware Solution, one Cross-Domain Solution, one backend solution,
two row classes, one display, one module manifest, one small JavaFX app (ucd-4). Zero new images, toolchains,
transports, framings, components. The JavaFX app's measured cost (jpackage image size, RSS) is recorded as a
`ResourceCost` row at ucd-4 per the cost rule. Licences unchanged from FIRMWARE_EXPORT_PLAN §5.

## §7. Ties

DEMONSTRABLES_PLAN §9 (the three solution kinds) · HARDWARE_DEV_PRIORITIES P1/P2/§3b (capabilities, the bench, the
selection model) · FIRMWARE_EXPORT_PLAN §2/§2b/§4 (the Installer, BridgingCapability, exp-2) · HARDWARE_NOCODE_PLAN
(one no-code model) · POLARI_TREE_PLAN §2 (app kinds) · BOARD_PROGRAMMING_PLAN §7a · HARDWARE_ARC_TEST_GUIDE §4–5.
