# Hardware Simulator generality — PLAN ONLY (2026-11-24)

## 1. The goal (the user, 2026-11-24)

The Hardware Simulator App behaves exactly like real hardware: a Polari Firmware image runs unmodified in a chip
engine, its pins are driven by our Python circuit emulators, and the same generated bridge reaches it with the same
struct maps. Each hardware instance carries one flag saying whether its bridge goes to a simulator or a real device;
both operate the same way. The aim is not a C3 proof but a data structure that generalizes: with the tables fully
populated, proving a few cases establishes that the others work.

> "an engine is needed, but the binding of an engine could be considered a validatable code"

## 2. The boundary

| Layer | What it is | How a new case is added | How it is checked |
|---|---|---|---|
| Engine | the emulator itself (simavr; Espressif QEMU + the `polari-block` pin device) | code, once per chip family | the engine's own tests |
| Engine binding | the adapter between an engine and Polari: `polari-avr-twin` (`prf-board-engines/twin_ctl.h`), `polari-c3-twin` (`prf-esp-engines/polari_c3_twin.py`) | code, once per family, but it must pass **one conformance suite** and **declare** what it supports | §3 |
| Everything else | chip facts, HAL roles, install steps, board picture, firmware struct maps, the bridge | rows only | §5: a case added with no code change |

A binding that passes the suite is accepted for any chip of its family and any firmware; nothing above it names a
chip.

**Engines are defined and bound by hand for now** (the user, 2026-11-24). Generating engines from custom
defined or simulated chips comes later, built on the layered chip rows in `PIN_TWIN_PLAN.md` §2a (`SimulatedChip`,
`SimOverlay`, and the one `polari-block` device loaded from a layout). The conformance suite of §3 is written so that
a generated engine and its binding must pass the same suite as a hand-made one, so nothing here changes when
generation arrives.

## 3. The engine-binding contract (made validatable)

Today the contract is prose in `twin_ctl.h`, and the two bindings already differ: the C3 has no `run:false`,
`reset` or `adc` (it refuses each in words), sends `ns` where the AVR sends `cycle`, and takes `"z"` as a level.
These differences are correct, but they are written in code (`board/custom/twin_kinds.py`) rather than declared.

- **g-2a, the contract as data:** the control line's verbs (`token`, `set`, `watch`, `status`, `run`, `reset`, `adc`),
  the out lines (`ack`, `pin`, `status`, `refused`), the stdout lines (`ready`, `status`, `ended`), the UART channel,
  and the time base (`cycle` or `ns`). One file, read by the suite and by `twin_kinds`. It lives at
  `engines/chip-emulator/contract.json` in the common engine layout (`ENGINE_CATALOGUE_PLAN.md` §4a), and the suite at
  `engines/chip-emulator/conformance/`.
- **g-2b, the declaration:** each binding answers `{"capabilities":1}` with what it supports (for example
  `levels: [0,1,"z"]`, `reset: false`, `adc: []`, `time: "ns"`, plus its pads as the layout reports them). The bench and
  the bridge read this instead of a per-chip branch.
- **g-2c, the conformance suite:** one test run against every binding, with the network off:
  - token: refusal and close;
  - set → ack → pin event on a watched pin;
  - watch replaces the list;
  - every declared capability works, and every undeclared one is refused in words, never a silent yes;
  - UART bytes pass both ways;
  - `ready`, `status` and `ended` come in order;
  - time is monotonic.

  It runs against `polari-avr-twin` and `polari-c3-twin` in their images.

## 4. One flag

Today the sim-or-real distinction lives in three places: `PolariBridgeInstance.mode` (`serial | simulated`),
`HardwareInterfaceBinding.interface_kind` (`serial | twin-pty`), and the `twin:` prefix on a board instance's name.
The user, 2026-11-24: "a simulator/device pair should be defined. We are solving for a real device but building
initially on a simulator for safety."

**g-3, the device/simulator pair:**
- A device definition names its simulator pair: the engine and binding, and the circuit around it.
- The design is solved for the device.
- A build runs on the simulator first. The same image and the same bridge then go to the device, so the parity test
  (g-6) compares the two halves of one pair.
- Each running instance records which half of its pair it is (`device` or `simulator`), and that is the only place
  the distinction lives. The bridge's device port is chosen from it. The bridge instance, the interface binding
and the installer read it; the name prefix becomes display only. The bridge's device port is chosen from it:
serial for `device`; TCP or `wss://` for `simulator`.

## 5. Proving generality

- **g-1, the audit:** list where UNO and C3 cross the boundary of §2, that is, any code outside an engine or binding
  that names a chip or a firmware. Candidates to read: `board/custom/install_c3.py`, the per-firmware
  `light_*_twin.py` checks, `electrodevice/custom/layout_sources.py`, and `twin_kinds.py`'s branches. Each one is moved
  into rows, or justified in one line.
- **g-4, the circuit in the loop:** check that the Python circuit emulator, not the bench click, drives the twin's
  input pins and reads its outputs. In 94's proof the click sets GPIO3 directly. If the circuit is not in the loop,
  wire it through the same control line.
- **g-5, a third case with rows only.** Two axes:
  - a different firmware on a chip we already have, with a UART or sensor struct rather than light and button. This
    proves the bridge and struct maps generalize across firmware.
  - another chip of an existing family. This proves the HAL tables do.

  The test of success is that the diff touches no code outside tables and seeds.
- **g-6, the parity test:** the same firmware image, the same generated bridge, and the same scripted struct writes,
  run on the simulator and on the real board. The struct traces match exactly in order and value; timing is compared
  within a stated tolerance (virtual time against wall-clock time). The real-board half needs a physical board on the
  bench and the user's go to flash it.

### 5a. g-1 audit result (2026-11-24; read from source, the key lines checked by hand)

- **The bridge passes.** `grpcbridge/custom/java_bridge_codegen.py` is driven by the struct contract alone (field map,
  class, version, hash) and names no chip. The bridge is already general across firmware.
- **The circuit IS in the loop for UNO firmware runs (tested 2026-11-24; the first audit's "not in the loop" was
  wrong).** `cmod.cmod_light_topology_selftest` 38/38 and `cmod.cmod_node_run_selftest` 14/14, run on pol with the
  board engines image: the twin's wires come from the circuit's nets (`board/custom/twin.py` `wires_from_circuit`),
  and at every firmware node the circuit state the twin left behind is solved by ngspice (`.op`) and judged against
  the chip's cited limits (`cmod/custom/node_electrical.py`, bss-12). `electrodevice.circuit_states_selftest` 29/29
  (cst-0/1). In the release images these two fail only because the engine is unreachable with the network off.
- **Not covered, still to test:** the live Sim bench session (a click sets the twin pin; the LED is the pad's level:
  `electrodevice/custom/layout_scene.py:132-145`), and the C3 (`node_electrical` is written for the UNO: 5 V rail,
  `electrical_atmega328p`).
- **Data, fine as is (to move to rows later):** the datasheet, register, package, fact, lifecycle and seed modules
  (`esp32c3_tables`, `registers_esp32c3`, `packages_*`, `soc_*`, `uno_facts`, `lifecycle_*`, `board_c3`/`board_uno`,
  `sim_bindings`, `board_engines`).
- **Per-chip tables holding logic:** `board/custom/twin_kinds.py` (`if kind is C3` in `admit`, `firmware`, `request`
  and `command_set`; the C3 image build), `install_kinds.py`, `electrodevice/custom/layout_boards.py`.
- **Crossings, the top five:**
  1. Branches on chip or board names in view and check code: `register_view.py:176-207`, `pin_stages.py:44/55`,
     `pv_shapes.py`, `electrical_check.py`, `exposure.py`, `hal/custom/generate.py:54`. Row: a chip kind naming its
     shape, lifecycle set and exposure map.
  2. Install, flash, build and project generation split by chip: `install_c3`, `flash_c3`, `build_c3`, `gen_c3`, and
     the alias matches in `gen.py`, `build.py`, `flash.py` and the CLIs. Row: an install kind naming the template,
     build engine, programmer and ordered steps; one step runner.
  3. `twin_kinds`/`install_kinds` branching on the kind: the C3-only image and layout work become hooks of the C3
     binding, declared in its row.
  4. Layout: `layout_sources.py` constants (`CIRCUIT`, `BOARD`, `STAND_INS`) and `layout_boards.py` branches. Row: a
     layout board naming its circuit, header, knobs, connectors and stand-ins.
  5. Parallel chain and bridge-path modules: `hardware_chain.py` ("only the atmega328p is materialized", :443) beside
     `hardware_chain_c3.py`; `grpcbridge/custom/bridge_paths.py` (`UNO_BRIDGE`, `C3_BRIDGE`);
     `bridge_link_checks.py`; `cycle_stimuli.py` (stimuli per `uno-light*`). Rows: chain hops per board, stimuli per
     firmware variant.
- **The HAL rules:** the first audit called them a crossing; that was not checked, and the user's reading is that
  they map code to no-code correctly. Withdrawn until checked by a test, not by a grep.
- **The list above is unverified, and it still includes engine-side code.** Chip-specific code inside an engine or its
  binding is allowed (the user, 2026-11-24), and a toolchain or flasher (ESP-IDF, esptool) is an engine. So
  `build_c3`/`flash_c3` and part of `install_c3` may be legitimate. Each item is re-sorted, with a test, before any
  change.

## 6. Order

Release 94 first (it is the two-case base). Then g-1, then g-2a–c, g-3, g-4, g-5, g-6. g-2c and g-5 are the
evidence for the generality claim; the rest makes them possible.

## 7. Open

- Should the contract and the capability declarations be Polari rows (no-code first) or a data file in the engine
  images? Rows are the default unless the engine images must read them offline.
- Which real C3 board is on the bench (asked before: still open).
