# Board programming (brd arc): program REAL boards over USB / USB-C from Polari — the Arduino UNO R3 (his Starter Kit) first, the BeagleV-Fire second; a board and its twin are interchangeable behind the same bridge seam

**Date:** 2026-10-01 · **Status: brd-0 BUILT 2026-10-01 on `dev-brd-0`; brd-1 BUILT 2026-10-01 on `dev-brd-1` (framework, rf-node, cli, suite; stacked on brd-0, unmerged — his word) — the UNO end to end PROVEN ON THE SIMAVR TWIN (incl. the real Java bridge); the real-UNO step is owed (none attached).** Drafted by an opus agent from verified
sources, reviewed and shaped by Fable; the seam, the rule and the decisions are the design. His ask: he owns the Arduino Starter Kit
(UNO R3 + its parts) and a BeagleV-Fire and wants both as ways to program boards FROM Polari. **THE RULE (his,
2026-10-01): only boards programmable over USB or USB-C are admitted. JTAG-only and SD-card-only flows are out.** USB keeps
a board reachable from Polari with nothing but a cable. The rule becomes a selftest (brd-0). **Refined the same day (his
D-brd-6 answer): "adapters can be fine so long as we are able to use usb or usb-c" — the HOST side must be USB/USB-C; a
USB adapter or programmer (USB-UART, a USB SWD/JTAG probe, a USB ISP dongle) in between is allowed. So the rule reads:
reachable from the Polari host over USB, directly or through a USB adapter that Polari knows (§2a adapters).**
**RULE 2 (his, 2026-10-01): microcontroller and hardware work is written in C, Verilog or SystemVerilog ONLY** — "to
simplify what we need to support". No C++ (so no Arduino core/sketches), no MicroPython/Rust on the MCU side, no VHDL on
the hardware side. Host-side code is a different layer (memory `language-layering`: web stack primary; Java — JavaFX apps
when a window is needed — as the bridge to the kernel and hardware virtualization; C for peripherals/FPGAs/hardware).
What exists already complies: the Renode twin firmware is plain C, the generated headers are C, the register block is
Verilog and its self-checking bench SystemVerilog. Rule 2 is the second brd-0 selftest: a
`BoardDefinition.toolchain_engines` may name only C compilers / Verilog-SystemVerilog tools, and a generated project
contains only `.c/.h/.v/.sv` (+ Makefile/linker script).

Companions: `HARDWARE_SIMULATION_PLAN.md` (hwsim-1/3/led: the Renode twin and the register block this arc puts on silicon),
`GRPC_BRIDGE_PLAN.md` (grpc-j3: the C twin), memory `polari-hardware-architecture.md` (the layered stack and tiers).
Facts marked **unverified** were not confirmed from a primary source on 2026-10-01.

## 0. The ask, the rule, and what "programmable via Polari" means

A board counts as programmable via Polari when ONE object round trip goes through these five steps with no hand steps
except plugging in the cable:

1. **detect**: `hwmap`'s scanner sees the USB VID:PID and the `/dev/serial/by-id` name, which match a `BoardDefinition`.
2. **generate**: the firmware/project is rendered AROUND the generated per-class header `<class>_packets.h`
   (`grpcbridge/custom/c_twin.py`). The firmware knows only the classes its rig needs.
3. **build**: the board's OPEN toolchain runs as an ENGINE, resolved by the engines ladder. The module never assumes a device.
4. **flash**: over USB only (USB-CDC bootloader, USB mass storage, later DFU/UF2). It is DRY-RUN by default.
5. **attach**: the Java hardware bridge opens the port (`SerialCdcPort`, `/dev/ttyACM*`, 115200, raw) and the class rows
   update. A REST PUT of an actuator field rides the Commands stream down ("send the object, it acts").

Step 5 is byte for byte the seam the Renode twin already uses (`grpcbridge/custom/renode_twin/README.md`: the bridge with
`source=serial` at a pty). So a board and its twin are interchangeable: the only difference is `serialDevice`.

## 1. What exists (verified in the tree 2026-10-01) and the one gap

All paths are under `polari-rf-node/polari-framework/modules/`.

- `grpcbridge/custom/c_twin.py`: per-class C header with the struct, encode/decode, CRC32 (bitwise, no table) and the
  12-byte LE header (magic 0x504C, version, msg_type, device_id, sequence, payload_len). Strings are fixed `char[64]`
  (`C_STR_MAX`). It is served at `GET /api/grpc/exposures/{class}/c-header`.
- `grpcbridge/custom/renode_twin/`: bare-metal STM32F4 firmware (`firmware/main.c`, `build.sh`, arm-none-eabi) in Renode
  (`sim_rig.resc`, `sim_rig_mcu_only.resc`) at a USART pty, plus `fpga/` (the Verilated regblock co-sim).
  `SimRigState` (`grpcbridge/objects/hwsim/SimRigState.py`) has these fields: `name, uptime_ms, temp_c, pwm_duty, led_on,
  status`.
- `grpcbridge/custom/java_bridge_templates.py`: `SerialCdcPort` (USB CDC-ACM, defaults `/dev/ttyACM0` / `115200`).
- `hwfpga/custom/fpga_verilog.py`: `RegisterMapDefinition`/`RegisterDefinition` rows become a synthesizable AXI4-Lite
  `polari_regblock.v`, a Verilator wrapper, a Renode co-sim harness, `<map>_regs.h` and a testbench. This is the Hardware
  Runtime map (0x0000 Device ID … 0x1000 device data). hwsim-led (the 4x4 LED grid, `LedMatrix4x4State.driver` =
  'fpga'|'mcu') is live in sim.
- `hwmap/custom/scanner.py`: `usb_devices()` (lsusb VID:PID), `usb_tree()`, `serial_ports()` (`/dev/serial/by-id`), PCI and
  IOMMU. It runs on the DEVICE and is stdlib only. Board detection reuses it and adds no new scanner.
- `voron/custom/provision.py`: puts `avrdude gcc-avr avr-libc stm32flash dfu-util gcc-arm-none-eabi` in `APT_PACKAGES`
  for the Voron guest, but its docstring is explicit: "`make flash` is NOT run". **No Polari code has ever flashed a chip.**
- `electrodevice/` (breadboard/netlist/SPICE bases): the home for the kit's parts (§6).
- The engines ladder, `computelod/custom/eda_engines.py`, resolves in this order: knob → local binary → local pinned image →
  topology provider → refusal naming the knobs. Modules declare `requires.engines` in `polari-app.json`; see
  `computelod/polari-app.json` (`riscv-gcc`, `yosys`, … with `kind`/`probe`). Proprietary or heavy tools live as WORKERS
  (`polari-rf-node/polari-eda-tools/`, ledger `LICENSES.md`).

**The gap is the last mile to silicon.** There is no board object, no flasher ever run, no board-specific firmware
template, and no detection-to-board match. A second gap was found while reading `c_twin.py`: the encoder does
`memcpy(p, &s->temp_c, 8)` with the comment "LE host assumed (Cortex-M / x86)". On the UNO, `double` is 4 bytes, the same
as `float` (https://docs.arduino.cc/language-reference/en/variables/data-types/double). That memcpy would read 4 bytes past
the field and corrupt the wire. brd-1 therefore needs a c_twin AVR mode: software float32↔binary64 conversion for
`double` fields. AVR itself is little-endian, so the rest of the layout holds.

## 2. The Board object model (brd-0)

- **`BoardDefinition`** (seeded rows, one per admitted model):
  - `kind` (`mcu`|`linux-soc-fpga`) and `soc` (`ATmega328P`, `MPFS025T`).
  - `usb_ids`: a list of VID:PID, one per mode the board shows (the UNO has one; the Fire shows its Linux gadget AND its
    HSS mass-storage mode).
  - `programmer`: `avrdude-optiboot` | `usb-mass-storage+linux` | `dfu` | `uf2` (later).
  - `toolchain_engines`: engine names for the ladder.
  - `transport`: `usb-cdc-serial` | `usb-network+ssh`.
  - `flash_kb`, `ram_kb`, `twin` (`renode:<platform>` | `simavr:<mcu>` | `none`), `usb_rule_ok` (bool + citation), and
    `licence_notes`.
- **`BoardInstance`** (one per detected board): `definition`, `host` (the device it is plugged into, a topology node),
  `by_id_path`, `port`, `serial_number`, `firmware_sha`, `last_flash_at`, `last_seen_at`, `bridge_name`.
- **`FirmwareBuild`** (one per build): `board_definition`, `classes` (each with its header contract hash),
  `template`, `source_sha`, `artifact_sha256`, engine versions/digests, `size_text/data/bss`, `built_at`, `flashed_to`
  (BoardInstance), `flash_log`, and a repro block (memory `reproducible-initial-conditions`).
- **Detection** is `pol board detect`, which runs `hwmap.custom.scanner` on the host and matches `usb_devices()` VID:PID
  plus `serial_ports()` names against `BoardDefinition.usb_ids`. It upserts `BoardInstance` and pushes the result like
  `pol hwmap scan --push`. A device with no matching definition is listed as "unadmitted", never guessed. pol-core today shows exactly one such device, a
  Silicon Labs CP2102 USB-to-UART bridge (`/dev/serial/by-id/usb-Silicon_Labs_CP2102_…`), the classic USB-serial chip of
  ESP32 and many other dev boards: `detect` will name it unadmitted until a definition (D-brd-4) admits its board.
- **The rule as a selftest**: every `BoardDefinition` must name a USB `programmer` and a USB `transport`. A row whose only
  route is JTAG or SD fails `brd_selftest` with a named refusal.
- **Build vs flash placement (important).** Compiling can run on ANY device (engine worker). Flashing and attaching must run
  on `BoardInstance.host`, the machine holding the USB port. The flash engine therefore resolves with a placement
  constraint: the worker on that host, with `--device <by-id path>` mapped, or a local binary there. A remote worker is
  refused for flashing.

## 3. The Arduino UNO route (brd-1, on HIS kit)

Verified board facts:
- MCU ATmega328P, 16 MHz, 32 KB flash, 2 KB SRAM, 1 KB EEPROM. USB-serial is an ATmega16U2, and opening the port resets
  the board via DTR (https://en.wikipedia.org/wiki/Arduino_Uno, https://docs.arduino.cc/hardware/uno-rev3/).
- The ArduinoCore-avr `boards.txt` `uno` entry (https://raw.githubusercontent.com/arduino/ArduinoCore-avr/master/boards.txt):
  - `upload.tool=avrdude`, `upload.protocol=arduino`, `upload.speed=115200`
  - `upload.maximum_size=32256`, i.e. 32768 minus the 512-byte Optiboot (https://github.com/Optiboot/optiboot)
  - `upload.maximum_data_size=2048`, `bootloader.file=optiboot/optiboot_atmega328.hex`
  - VID:PID `2341:0043`, `2341:0001`, `2A03:0043`, `2341:0243`, `2341:006A`
- The CDC device appears as `/dev/ttyACM0`, the same device class `SerialCdcPort` defaults to.

The flow:
1. `pol board detect` finds the UNO (2341:0043 on an R3; the by-id name `usb-Arduino…_0043_<serial>-if00` is typical,
   **unverified on his board**).
2. `pol board gen uno --class SimRigState` renders a plain-C avr-libc project (RULE 2: no Arduino core, no sketch):
   `main.c` + `Makefile` + the generated `simrigstate_packets.h` (AVR mode); USART0 at 115200 8N1 (UBRR0 = 8 at 16 MHz),
   ADC on channel 0 (AVcc reference), Timer0/Timer1 PWM, a 1 ms tick from Timer2 for `uptime_ms`; a 10 Hz loop that:
   - sets `uptime_ms` from the tick;
   - reads the kit's TMP36 on A0, with `temp_c = (mV − 500)/10` (10 mV/°C, 500 mV offset per the TMP36 datasheet,
     **URL not fetched**; the kit's project 03 uses this sensor);
   - writes `led_on` → PORTB5 (the on-board LED, D13) or any pin with the kit's LED + 220 Ω, and `pwm_duty` → OCR0A/OCR1A
     on a PWM pin (D5/D6 Timer0, D9/D10 Timer1, D3/D11 Timer2);
   - echoes `status` ('boot' → 'ok' → 'commanded').
   These are the same fields and semantics as the Renode firmware, so the existing `renode-rig` bridge config works
   with `serialDevice` swapped.
3. `pol board build` runs `avr-gcc -mmcu=atmega328p -DF_CPU=16000000UL -Os` + `avr-objcopy -O ihex` straight (GPL,
   avr-libc; no arduino-cli — RULE 2 makes it unnecessary). `avr-size` fills `FirmwareBuild.size_text/data/bss`; the build
   refuses past 32256 B flash / 2048 B RAM (the `boards.txt` limits still apply; Optiboot stays as the USB flash route).
4. `pol board flash` runs avrdude (GPL-2.0, https://github.com/avrdudes/avrdude) as
   `avrdude -p atmega328p -c arduino -P <by-id> -b 115200 -D -U flash:w:<hex>:i`. DRY-RUN (the default) prints the exact argv. The real run needs the device present AND `--yes`, then
   verifies (avrdude's read-back) and stamps `BoardInstance.firmware_sha`.
5. `pol board monitor` points a bridge at the port (POST `/api/grpc/bridges` `{source: serial, serialDevice: <by-id>}`).
   The DTR reset means the first ~1–2 s after open belong to Optiboot (the length is **unverified**; the bridge already
   resyncs on bad magic per `c_twin.py`).

**Proof on real hardware:** the TMP36 reading appears in the `SimRigState` row and tracks a finger on the sensor. A REST
PUT `led_on=true` lights the LED and a PUT of `pwm_duty` dims it, and the next frame echoes `status='commanded'`.

**Footprint estimate (to be MEASURED by `FirmwareBuild.size_*`, per the cost rule):**
- Flash: no Arduino core (RULE 2) — the avr-libc startup + our USART/ADC/PWM code is well under 1 KB. The header's encode/decode, which leans on 64-bit
  integer shifts that avr-gcc expands into library calls, is about 1.5–3 KB. Bitwise CRC32 is about 0.1–0.2 KB. The
  sketch is under 1 KB. Total ≈ 3–5 KB of 31.5 KB.
- RAM: `SimRigState_t` is 64+8+64+4+8+1 = 149 B (double = 4 B on AVR). The RX frame buffer is 12+157+4 = 173 B
  (`POLARI_RX_PAYLOAD_MAX 157` in `simrigstate_packets.h`, not 64 B; two 64-B strings dominate), plus a TX frame of
  about 173 B and our own USART ring buffers (2×64 B). Total ≈ 0.6 KB of 2 KB. **It fits.**
- If RAM tightens, a per-board knob `C_STR_MAX=32` halves the strings (a c_twin parameter, not a fork).

## 4. The BeagleV-Fire route (brd-2 / brd-2b)

Verified board facts:
- MPFS025T-FCVG484E: 4× RV64GC application cores plus 1× RV64IMAC monitor core, 2 GB LPDDR4, 16 GB eMMC
  (https://docs.beagleboard.org/boards/beaglev/fire/01-introduction.html).
- The fabric has 23K logic elements (4LUT+DFF) (https://ww1.microchip.com/downloads/en/DeviceDoc/Polarfire_SOC_Product_Overview.pdf).
- With Linux running, USB-C gives CDC-ACM serial (`/dev/ttyACM0`, 115200) plus CDC-NCM Ethernet, with the board at
  192.168.7.2 and Cockpit on :9090 (https://forum.beagleboard.org/t/connecting-beaglev-fire-to-usb-c/36485, BeagleBoard
  staff: "the usb ethernet, usb serial should be active over type-c";
  https://docs.beagle.cc/boards/beaglev/fire/demos-and-tutorials/gateware/upgrade-gateware.html).
- Images: Debian 13 IoT and Ubuntu 24.04 (https://www.beagleboard.org/distros).

**(a) Image flash: a rule finding.** The documented eMMC reflash works like this: press a key at boot, then type `mmc` and
`usbdmsc` at the HSS prompt. The eMMC appears over USB-C as mass storage ("MCC PolarFireSoC_msd"), and the host writes it
with `dd`/Etcher (https://docs.beagleboard.org/boards/beaglev/fire/demos-and-tutorials/flashing-board.html). **But the
HSS prompt is reached ONLY through the UART debug header with a 3.3 V USB-UART adapter.** No documented way exists to
enter `usbdmsc` from USB-C or from Linux (same page; a forum search found none). So the board-side half of a full reflash
breaks THE RULE.

What stays inside the rule is everything after the first boot:
- the shipped/pre-flashed image;
- `apt` updates and gateware changes FROM Linux over the USB-C network.

That makes `pol board flash fire --image` a **recovery verb** gated by D-brd-6. When run, it is idempotent: it hashes
the image, waits for the mass-storage VID:PID, `dd`s with `conv=fsync` (bmaptool only if a `.bmap` is published,
**unverified**), and reads back and compares the sha256.

**(b) Deploy over USB-C (brd-2).** `pol board deploy fire` uses the USB network: ssh to `beagle@192.168.7.2`. It installs
the Polari bridge (D-brd-3) as a systemd unit, with the board's own `/dev/ttyACM*`/fabric as its devices, and registers a
`BoardInstance` with `transport=usb-network+ssh`. The board runs Debian on RISC-V. With 2 GB RAM, the full framework is
possible on paper, but peak RSS is unmeasured, and riscv64 wheel coverage for our deps is **unverified**. Hence bridge
first.

**(c) Gateware (brd-2b, after D-brd-2).**
- The design is ours: `hwfpga`'s `polari_regblock.v` (AXI4-Lite) with hwsim-led's `LED_MATRIX` `pins_out` register,
  placed into the Fire's cape gateware. The cape gateware drives P8/P9 and all Fire gateware blocks expose an AMBA APB
  target for control/status registers
  (https://docs.beagleboard.org/boards/beaglev/fire/demos-and-tutorials/gateware/index.html). The exact default-cape
  peripheral set and APB addresses are **unverified** and read from the gateware repo in brd-2b.
- Building a PolarFire bitstream needs **Microchip Libero SoC**, which is PROPRIETARY. Its free "Silver" licence is
  renewed yearly; on Linux it is a FLOATING licence served by a licence daemon and tied to a NIC MAC
  (https://www.hackster.io/news/hackster-s-fpgadventures-investigating-licensing-and-installing-microchip-s-libero-soc-c8a8dd23b2b2).
  Silver covering the MPFS025T is reported for the FCSG325 package; for the Fire's FCVG484 package it is **unverified**.
- **There is no open-source flow to PolarFire bitstreams.** nextpnr lists iCE40/ECP5/Nexus/Gowin/NG-Ultra/GateMate
  stable plus Cyclone V/MachXO2/Xilinx-7 experimental, and no PolarFire (https://github.com/YosysHQ/nextpnr).
- BeagleBoard also builds custom gateware in its own GitLab CI from a fork, so there is no local Libero at all
  (https://docs.beagleboard.org/boards/beaglev/fire/demos-and-tutorials/gateware/customize-cape-gateware-verilog.html).
  That is a third option for D-brd-2.
- Apply from Linux: `sudo /usr/share/beagleboard/gateware/change-gateware.sh <bitstream dir>`. It writes the gateware and
  its device-tree overlays to the system controller's SPI flash and reboots (~2 min). Overlays then show under
  `/proc/device-tree/chosen/overlays/` (same two pages). This is entirely over the USB-C network, inside the rule.
- The on-board bridge reaches the register block through a UIO/`/dev/mem` mapping of the overlay's APB window (the
  mechanism is chosen in brd-2b).

**Proof on real hardware:** hwsim-led's 4x4 pattern written as a `LedMatrix4x4State` row lights LEDs on the cape header
through the real fabric, and the readback register returns it.

## 5. Twins with no hardware (brd-3)

- **AVR:** Renode does NOT support AVR (its supported-boards list has ARM/RISC-V/x86/PowerPC/SPARC families, no AVR/ATmega:
  https://renode.readthedocs.io/en/latest/introduction/supported-boards.html). **simavr** (GPL-3.0, supports
  ATmega48/88/168/328, https://github.com/buserror/simavr) is THE AVR twin. Its UART is bridged to a pty, which is the same
  pattern as the Renode pty. The UNO's very `FirmwareBuild` artifact runs in it, and the bridge attaches unchanged
  (`BoardDefinition.twin = simavr:atmega328p`).
- **BeagleV-Fire:** Renode carries BOTH `platforms/boards/mpfs-icicle-kit.repl` AND `platforms/boards/beaglev-fire.repl`
  (https://github.com/renode/renode/tree/master/platforms/boards). `beaglev-fire.repl` uses `platforms/cpus/polarfire-soc.repl`
  and models QSPI flash, system services and a user button, but **not the FPGA fabric**
  (https://raw.githubusercontent.com/renode/renode/master/platforms/boards/beaglev-fire.repl). So the twin is
  `renode:beaglev-fire` plus our Verilated regblock attached the hwsim-3 way. The icicle kit (MPFS250T) is the fallback.
- **CI:** both twins are engines in workers; the pipeline's advisory stage runs build → twin → bridge → row assertions
  with no board. Per the cost rule, each worker image is measured (size, peak RSS, CPU-s, wall time) before anything else
  builds on it.

## 6. The parts register + the 15-project ladder (brd-4, optional, lazy)

Kit contents (https://store.arduino.cc/products/arduino-starter-kit-multi-language):
- UNO, USB cable, 400-pt breadboard, 70 solid jumpers + stranded black/red, 9V snap, 40×1 male pin strip, 3 colour gels.
- 6 phototransistors, 3× 10 kΩ pots, 10 pushbuttons, 1 TMP36, 1 tilt sensor, 1 LCD 16x2.
- LEDs: 1 white, 1 RGB, 8 red, 8 green, 8 yellow, 3 blue.
- Small DC motor (6/9 V), small servo, piezo PKM22EPP-40, L293D H-bridge, 4N35 optocoupler, 2× IRF520 MOSFET.
- 3× 100 µF caps, 5× 1N4007.
- Resistors: 220 Ω ×20, 560 Ω ×5, 1 kΩ ×5, 4.7 kΩ ×5, 10 kΩ ×20, 1 MΩ ×5, 10 MΩ ×5.
- Transistors as a separate part: **unverified** on the store page; the IRF520 MOSFETs are the switching parts listed.

Each becomes an `electrodevice` row with its SPICE model where one exists. A project's breadboard becomes a netlist row.

| # | Project (book) | Polari objects exercised | Maps to existing twin field |
|---|---|---|---|
| 01 | Get to know your tools | parts rows, breadboard netlist | — |
| 02 | Spaceship interface | button in, LEDs out | `led_on` |
| 03 | Love-o-meter (TMP36) | **brd-1's sensor** | `temp_c` |
| 04 | Color mixing lamp | phototransistors → RGB PWM | `pwm_duty` (×3 → new class) |
| 05 | Mood cue (pot → servo) | ADC → servo angle | pot = ADC (new field), servo via PWM |
| 06 | Light theremin | phototransistor → piezo tone | new class |
| 07 | Keyboard instrument | resistor ladder → ADC | new class |
| 08 | Digital hourglass | tilt sensor, `millis()` | `uptime_ms` |
| 09 | Motorized pinwheel | IRF520 + 1N4007 + DC motor | `pwm_duty` |
| 10 | Zoetrope | L293D H-bridge, direction + speed | `pwm_duty` + new `direction` |
| 11 | Crystal ball | LCD 16x2 + tilt | `status` string → LCD |
| 12 | Knock lock | piezo as sensor, servo | new class |
| 13 | Touchy-feel lamp | CapacitiveSensor (1 MΩ) | new class |
| 14 | Tweak the Arduino logo | pot → Serial → host | **the bridge itself** |
| 15 | Hacking buttons | 4N35 optocoupler | new class |

Project list from https://github.com/cristianocclemente/arduino-projects-book and the book
(https://www.deanza.edu/engineering/documents/arduino_projects_book.pdf). Direct maps onto `SimRigState`: 02/08/09 (LED,
uptime, motor PWM), 03 (temperature), 14 (the serial seam). New fields or classes are generated headers, not hand C.

## 7. Decisions — ✅ ALL RULED 2026-10-01 (his words in quotes)

- **D-brd-1 toolchain delivery → ENGINES, chosen dynamically per device kind** ("Using engines dynamically per the kind of
  device we need to be using seems like it would make the most sense. for 1 and 2"). The engines ladder resolves the
  toolchain + flasher for the `BoardDefinition.programmer` kind (worker image by default, local binary when present);
  flashing resolves on the host that holds the USB port.
- **D-brd-2 Libero → the same: an ENGINE, resolved dynamically when a PolarFire device kind needs it** (proprietary, in
  its own worker, never embedded, licence recorded; BeagleBoard's GitLab CI as the zero-install fallback). EULA
  container terms to be read before brd-2b.
- **D-brd-3 what runs on the Fire → "decide based on circumstances"** — not fixed; the bridge-first measurement remains
  the default path and the full framework is a per-deployment choice.
- **D-brd-4 the next board → "Hazard is ideal"**: the Raspberry Pi Pico 2 (RP2350 / Hazard3), UF2 over USB.
- **D-brd-5 the kit's parts as rows → "yes"** (lazily, per project of the book).
- **D-brd-6 the Fire reflash → adapters are allowed**: the HSS mass-storage reflash through a USB-UART adapter is INSIDE
  the refined rule; it is a documented verb, not a recovery exception.
- **D-brd-7 module home → "new module and/or expanding on what already exists and splitting things apart into more
  sensible chunks"**: a `board` module for the new rows + verbs, and the pieces that already exist (hwmap detection,
  the bridge's C header generator, the renode twin) split where they have grown too large (file-size rule) rather than
  copied.
- **His framing of the whole chunk: "Our concern for this chunk of functionality is hardware oriented manipulation."**

### 7a. The Firmware Installer App (his, 2026-10-01) — the person-facing half

*"We should have a generalized Firmware Installer App most likely, that can install various usb and usb-c devices with
Polari compatible firmware. We should also identify usb and usb-c converters we can use to flash things that do not
inherently have usb or usb-c with polari as well."*

- **A Polari app, configured pages only** ([[no-raw-json-on-screens]] rule): plug a device in → it is detected (hwmap:
  VID:PID, by-id) and matched to a `BoardDefinition` — or to an **adapter** (§2a) and, through it, to the target it
  programs → the app shows the firmware builds available for it (the generated per-class firmware, the class list it
  carries, size vs the board's limits, the build's sha and engine digests) → DRY-RUN shows the exact flasher command →
  install needs the device present + an explicit confirm → the result (verify read-back, `BoardInstance.firmware_sha`,
  the bridge attaching, the first rows arriving) is on the same page.
- **Engines per device kind** (D-brd-1/2): `programmer` kind → engine: `avrdude-optiboot` → avrdude; `esptool` → esptool;
  `uf2` → a mass-storage copy (picotool optional); `dfu` → dfu-util; `swd`/`jtag` via a USB probe → OpenOCD / probe-rs
  (licence check) ; `wch-isp` → wchisp; `hss-usbdmsc` → the USB-UART console step + `dd`; `libero-gateware` →
  `change-gateware.sh` over the USB network. Each is a `ProgrammerKind` row naming its engine, its DRY-RUN rendering,
  and the adapter it needs (if any).
- **Adapters are first-class rows** (`AdapterDefinition`): USB-UART bridges (CP2102, CH340, FTDI FT232), USB
  SWD/JTAG probes (Raspberry Pi Debug Probe — CMSIS-DAP, open hardware; Black Magic Probe — open; ST-LINK; WCH-LinkE;
  J-Link EDU — licence terms), USB ISP dongles; each with VID:PID, what it can program (`targets`), the engine that
  drives it, openness and origin. Detection of an adapter alone yields "adapter present, no target identified" — the
  app then asks which target is wired to it (a person's answer, recorded on the `BoardInstance`).
- **"Polari-compatible firmware"** = firmware generated around the per-class packet header (§0 step 2) so the bridge
  can attach; the app refuses to install firmware whose header contract hash does not match a class the server knows.
- Slice **brd-fi** (after brd-1 proves the UNO by CLI): the app's pages over the same rows + the adapter rows; the first
  adapter proven = a USB-UART (the CP2102 already on pol-core) driving the Fire's HSS step or an ESP32's bootloader.

## 8. Cost + licences

| Component | Licence | Role | Cost (estimate until measured) |
|---|---|---|---|
| avr-gcc / avr-libc (Debian packages `gcc-avr`, `avr-libc`) | GPL-3.0+ with the runtime exception / modified BSD | C compiler + libc (the ONLY UNO toolchain under RULE 2; arduino-cli dropped) | image ≈ 150–250 MB (**unverified**) |
| avrdude | GPL-2.0 (https://github.com/avrdudes/avrdude) | flasher | ~MBs |
| simavr | GPL-3.0 (https://github.com/buserror/simavr) | AVR twin | ~10 MB (**unverified**) |
| Renode | MIT (already in use, hwsim-1) | Fire twin | portable build ≈ hundreds of MB (**unverified**) |
| HSS | MIT, payload generator MIT+GPL, OpenSBI BSD-2 (https://raw.githubusercontent.com/polarfire-soc/hart-software-services/master/LICENSE.md) | Fire bootloader (on board; not ours to ship) | — |
| BeagleV-Fire images | Debian 13 / Ubuntu 24.04 (https://www.beagleboard.org/distros) | board OS | ~4 GB image |
| Libero SoC | PROPRIETARY, free Silver licence, yearly, floating on Linux | gateware ENGINE only (D-brd-2) | install size **unverified** (multi-GB expected) |
| BeagleV-Fire gateware repo | **unverified** (git.beagleboard.org blocked the fetch) | base design we fork | — |

Nothing NC appears anywhere. Libero is the one proprietary piece, and it is quarantined as an engine.

## 8a. HIS RULING 2026-10-01 — track all, simulate few; the UNO first; the rest are ROADS marked to-do

*"I think we should track the devices and what they are useful for, but I am unsure how large these devices would end up
being in terms of object size for simulating. So I do not want to say just load all of them. We should pick a few key
ones we can simulate to start practicing. The Uno is the first thing to address since we have one on hand. The rest we
want to record as roads and mark as to do until done. Eventually we will want to make our own boards but for now we
will be simulating the boards of others and taking info from their data sheets to be able to do our own work."*

Consequences:
- **The register (`AI-Notes/designs/HARDWARE_CAPABILITY_REGISTER.md`) tracks EVERY device and its uses as rows** —
  `BoardDefinition` + `DevelopmentResource` — but a row is NOT a simulation. A device gets a twin only when it is picked.
- **A `Road` per device:** every tracked device is a road node with `status = todo | in-progress | done` and the steps
  (datasheet facts captured → BoardDefinition complete → twin → firmware template → flashed on real hardware →
  measured). The roads hang on the tech tree the suite already has (the ComputeLOD tree pattern), one node per device,
  so the picture "what is done, what is a road" is a configured display, never a list in a doc.
- **The first simulated device is the UNO** (on hand): simavr twin, the plain-C route (§3), footprint MEASURED — of the
  firmware AND of the simulation OBJECTS (rows per device: pins, registers, peripherals, timers; bytes of state per
  simulated cycle). That measurement is the yardstick for admitting the next device: a `BoardSimCost` row per twin
  (object count, state bytes, cycles/s on the device class) before another is loaded.
- **Datasheet facts as rows with provenance:** every number taken from a vendor datasheet (pin map, register address,
  memory map, electrical limit, timing) is a `DatasheetFact` row citing the document, revision, page/table — the
  derive-or-cite rule — so our own boards later inherit facts with their sources, and a wrong number is traceable.
- **Our own boards later:** the same rows describe them; nothing in the model distinguishes "theirs" from "ours" except
  `BoardDefinition.designer`. Until then we simulate others' boards from their datasheets.

## 9. Slices

| Slice | What | Proof on real hardware | Gate |
|---|---|---|---|
| brd-0 ✅ BUILT 2026-10-01, branch `dev-brd-0` | `board` module (8 classes, one per file): BoardDefinition/BoardInstance/FirmwareBuild/ProgrammerKind/AdapterDefinition/DatasheetFact/BoardSimCost/Road. Seeded from the register (snapshot `custom/register_rows.json`, re-imported by `register_import`): **33 devices + 33 roads** (all todo except the UNO's first step, in-progress), **13 adapters**, **9 ProgrammerKinds** (the §7a eight + `fpga-usb-jtag` for iCEBreaker/ULX3S), **19 UNO DatasheetFacts** (boards.txt pinned to commit 11b9130 + line), the `board-roads` tech tree (33 nodes); only the UNO `simulated` (simavr:atmega328p). RULE 1 → `usb_rule` ok (26) / undetermined (6, with the reason) / not-a-target (1, digirig); RULE 2 → every engine has a kind (c-compiler/hdl-toolchain/flasher/simulator). `requires.engines` avr-gcc/avrdude/simavr via `custom/board_engines.py` (BOARD_ENGINES_URL → local binary → provider `board.engines` → refusal naming brd-1; a FLASH refuses a remote worker). `pol board detect\|list\|roads\|facts\|engines` (+ `--push` → POST /api/board/detect upsert). c_twin `target=avr` (`?target=avr`): software binary32↔binary64 for double fields, wire unchanged, default header byte-identical (sha pinned). `/display/boards` = 6 configured tables. Proven: board selftest 40/40, c_twin 19/19 (13 encode + 22 decode cases + a 1000-value seeded sweep vs C's rounding; refuses to compile with an 8-byte double), conventions 41/41 · 61/61 · 8/8, `manifests conform board` OK, live boot 21/21 (`tests/board_liveboot_probe.py`). **Real `pol board detect` on pol-core:** both CP2102s → `cp2102-usb-uart-modules`, adapter present / target unknown (one with the by-id path; the other shares its serial string 0001, so no by-id link — told to identify by usb path); 4 devices unadmitted. **The UNO is not attached here: its proof row is faked in the selftest (2341:0043 → board present with by-id path); the real-hardware proof stays owed.** | `pol board detect` on pol-core lists his UNO as a `BoardInstance` with by-id path — **owed (UNO not attached)** | D-brd-7 ✅ |
| brd-1 ✅ BUILT 2026-10-01 on the twin, branch `dev-brd-1` | UNO end to end in PLAIN C (avr-libc, no Arduino core). **gen** (`pol board gen uno --class SimRigState [--api URL]`, `custom/gen.py`): the template `custom/firmware/uno/` (main.c, Makefile, board_config.h knobs RIG_NAME / DEVICE_ID / USART_U2X) + `simrigstate_packets.h` with c_twin `target=avr` — live from `--api`, else the pinned contract `custom/contracts/SimRigState.v2.json` (proven faithful: rendered for the host it is byte-identical to the Renode twin's committed v2 header); RULE 2 checked on the project; FirmwareBuild `generated` with the header + contract hash. Firmware: USART0 115200 8N1 with an RX ISR ring feeding the header's parser — **UBRR0 = 16 with U2X0 (+2.1 %), not the §3 UBRR0 = 8 (−3.5 %, kept as knob USART_U2X 0)** per DS40002061B Table 20-7 p.199 (what Optiboot and the 16U2 use); Timer2 CTC 1 ms → uptime_ms; ADC0/AVcc → temp_c = (mV−500)/10 (TMP36); led_on → PORTB5 (D13); pwm_duty (0..100 %) → OCR0A on D6 (Timer0 fast PWM); 10 Hz frames; commands apply actuators only. c_twin AVR mode fixed for `-Wextra -Werror` on AVR (16-bit ptrdiff_t; host header unchanged). **build** (`custom/build.py`): avr-gcc/objcopy/size through the ladder — local binary → **the worker image `prf-board-engines:trixie`** (`polari-rf-node/prf-board-engines/`, debian:trixie-slim pinned by digest; gcc-avr 14.2.0, avr-libc 2.2.1, avrdude 7.1, simavr 1.6, + `polari-avr-twin` built against libsimavr, + /capability /run worker :9830; `docker-compose.board-engines.yml`; provider `board.engines` → `prf-board-engines` in PROVIDER_PORTS / ENGINE_MODULES; a ModuleResourceProfile) → BOARD_ENGINES_URL worker; avr-size -A → **.text 4416 / .data 26 / .bss 737 = flash 4442 / 32256 B, RAM 763 / 2048 B**; refused past the cited limits; .hex sha256 identical across the image and worker rungs (deterministic); repro block complete. **flash** (`custom/flash.py`): argv rendered from ProgrammerKind `avrdude-optiboot` + the cited facts; DRY-RUN by default (`avrdude -p atmega328p -c arduino -P <by-id> -b 115200 -D -U flash:w:<hex>:i`, + the docker wrapper when the image rung would run it); a real run needs a detected BoardInstance AND `--yes`, avrdude's read-back verify (never `-V`), then stamps firmware_sha / last_flash_at (`POST /api/board/builds`); the real path unit-tested with a FAKE avrdude only. **twin** (`pol board twin uno up|down|status`, `custom/twin.py` + `twin_pty.py`): simavr 1.6's CLI has NO uart-pty flag, so `polari-avr-twin` owns USART0 via IRQs → TCP, the host pump makes a pty link; ADC0 driven from OUTSIDE (simavr's ADC_IRQ_ADC0 in mV: fixed or a ramp — no build-time knob needed); PORTB5 edges + OCR0A traced. **Proof on the twin:** `tests/board_uno_twin_probe.py` 12/12 (50 frames in 4.9 s = 10.00 Hz, uptime +100 ms/frame, temp_c 24.707 °C at 750 mV = ADC 153, a command after leading garbage → status=commanded, led_on, pwm 42 echoed; simavr PORTB5 high, OCR0A 107) and **`tests/board_uno_bridge_probe.py` 12/12 — a throwaway in-process server (HTTP + gRPC) + the GENERATED Java bridge (mvn package, source=serial at the twin's pty): the `uno-twin` SimRigState ROW follows the firmware at 9.99 frames/s, temp_c 24.707; a REST PUT {led_on:true, pwm_duty:42} rides Commands down and the row echoes status=commanded in 0.2 s; simavr shows D13 high, OCR0A 107.** **§8a cost** (`COST.md`, BoardSimCost row from `custom/sim_cost_uno.json`): 33 rows per simulated UNO (24 of them cited facts) + 3 per class; simavr core state 52 112 B (19 344 B mutable); 78.6 M cycles/s = 4.9x real time; twin 11.2 MB peak RSS. Image 534.7 MB, build 46 s, one compile 0.11 CPU-s / 30.5 MB. Selftests: board 74/74, c_twin 19/19, cause_context 41/41, outbound 61/61, manifests 8/8, conform board OK, liveboot 26/26. **Finding:** contract_hash covers field→type only, so a fresh server (v1, alphabetical tags) and the staging ledger (v2) share hash 2bcc9d1a2774ef33 but differ in wire order — gen against the server the board talks to (`--api`); the installer's hash check (§7a) should also compare header_sha256 / tag order. | **Owed on the real UNO:** `pol board detect` lists it → `pol board flash uno` (read the argv) → `--yes` → bridge at the by-id path → the TMP36 reading tracks a finger, a PUT lights D13 / dims D6, `status='commanded'` echoed; also the Optiboot window after the DTR reset (unverified) and USART_U2X 1 against the 16U2 | D-brd-1 ✅ |
| brd-2 | Fire: USB-C network detect, `pol board deploy fire` (bridge as systemd unit), recovery `flash --image` documented | the Fire's bridge pushes a row over 192.168.7.2; a PUT round-trips | D-brd-3, D-brd-6 |
| brd-2b | Fire gateware: regblock into the cape design, Libero engine (or BB CI), `change-gateware.sh` from Linux, UIO access | hwsim-led pattern lit on real fabric from a `LedMatrix4x4State` row, read back | D-brd-2 |
| brd-3 | twins in CI: simavr (same UNO artifact) + Renode `beaglev-fire` (+ Verilated regblock); worker images measured | n/a (twin parity: same rows as brd-1/brd-2 hardware runs) | cost rows |
| brd-4 | kit parts as `electrodevice` rows + the 15-project ladder, one project per step | each project's twin field moves on his breadboard | D-brd-5 ✅ |
| brd-fi ✅ BUILT 2026-10-01 on the twin, branch `dev-brd-fi` | the Firmware Installer App (§7a) for HIS intent — *"that way we can test different kinds of things on the arduino uno to see if it works"*. **Variants as rows** (`FirmwareVariant`, `custom/variants.py`; knobs validated with the reason — PWM on Timer2, LED on D0/D1, a feature the app has no code for, a build flag that is not `NAME=integer` or redefines a knob): the template split into `hal.c/hal.h` + one app per variant (`apps/sim_rig|blink|analog|echo.c` → main.c), FEATURE_* compiled in or out (no command path = receiver off). Four UNO variants, measured (live v1 contracts, avr-gcc 14.2.0 -Os, flash / static RAM): **uno-sim-rig 4532 / 763 B · uno-blink-only 1514 / 501 B · uno-adc-sweep 1394 / 528 B · uno-echo 3152 / 763 B** — blink-only is the smallest in RAM, the adc sweep the smallest in FLASH (SimRigState's one double needs the software binary32→binary64 encoder; the all-integer class does not). uno-adc-sweep speaks a NEW class `UnoAnalogState` (a0/a1/a2/name/status/uptime_ms; pinned contract v1 hash 078e20a0f939956b as a fresh server makes it) — the generator handles a second class (c_twin selftest: it compiles beside another class's header in one unit and round-trips with the Python reference both ways). `gen` without `--variant` = uno-sim-rig. **Compatibility** (`custom/compat.py`, `GET /api/board/builds/<b>/compat`): FirmwareBuild gains `header_sha256` + `tag_order_json` captured at gen; compared against the header THIS server generates now (its live exposure; the pinned snapshot only with no exposure, labelled) → compatible | stale-header | unknown-class; install refuses anything else (exit 3, both wire orders named). Proven live: a build from the pinned v2 snapshot vs a fresh v1 server — SAME contract hash 2bcc9d1a2774ef33 — is stale-header and its plan is refused. **The flow** (`custom/installer.py`, `custom/attach.py`, doors in `installer_api.py`): GET /api/board/installer · POST …/build · POST …/plan (`InstallPlan`: the argv fixed at planning, engine, adapter, compat, what will be stamped) · POST …/run {plan, confirm:true} (this server's own host only — a plan for another host is refused naming both; re-checks compat) → `InstallRecord` · POST …/attach (the GENERATED Java bridge at the port / the twin's pty; refuses while the class's gRPC exposure is off, never flips it; the worker is handed the request's cause) · GET …/result/<record>. **Page** `/display/firmware-installer`: six configured tables + ONE new component `firmware-installer-panel` (polari-platform-angular; sends names only; argv verbatim; confirm disabled until a plan; STOMP-driven result; "try another variant"). **CLI** `pol board install uno [--variant] [--twin] [--dry-run|--yes]`, `pol board variants`, `pol board result`. **Proven on the twin** (`tests/board_installer_probe.py` 25/25, a throwaway in-process server + the real engines + the generated bridge; the twin counts as the device and every record says so): all four built and compatible; four DRY-RUNs printed; installs: simavr loaded exactly the .hex's data bytes (3152 / 4532 / 1394 / 1514) — the twin's read-back; **uno-echo** a PUT {temp_c 12.5, pwm 7, led on} came back whole, status=echoed, in 0.2 s; **uno-sim-rig** 10 frames/s, temp_c 24.707, a PUT → commanded in 0.1 s, OCR0A 107; **uno-adc-sweep** UnoAnalogState rows a0/a1/a2 = 153/306/613 at 750/1500/3000 mV; **uno-blink-only** via the CLI, led_on 20 true / 20 false in the decoded frames. Selftests: board 112/112 (firmware_installer section 38), c_twin 23/23, cause_context 41/41, outbound 61/61, manifests 8/8, conform board OK, liveboot 37/37, brd-1 twin probe 12/12 + bridge probe 12/12, Angular panel spec 5/5 (+ pipeline 10/10), ng build OK. **Findings:** (1) simavr 1.6 converts ADC with ·1023, the datasheet says ·1024 — the twin reads 1 LSB low (306 vs 307); (2) grpcbridge Push drops default-valued fields (proto3, no presence), so a board reporting led_on=false / pwm 0 never clears the row (blink's row stays true) — a grpcbridge fix (proto3 `optional`) is owed; (3) the C rx parser drops a frame whose start falls inside a rejected header (no rescan) — one lost frame after such garbage. | **Owed on the real UNO:** `pol board detect --push` → the page lists it → `pol board install uno --variant uno-blink-only` (read the avrdude argv) → `--yes` → D13 blinks; then uno-echo (the protocol over the 16U2), uno-sim-rig (TMP36 + LED + PWM), uno-adc-sweep (a pot on A0..A2, 307 at 1.5 V); then the CP2102 adapter → an ESP32 or the Fire's HSS step (§7a's adapter half, not built) | after brd-1 ✅ |
| brd-wire ✅ BUILT 2026-10-02 on the twins, branch `dev-brd-wire` (= grpc-j4, GRPC_BRIDGE_PLAN.md §grpc-j4 holds the design) | HIS ruling 2026-10-02 — *"define a mapping from the computer side to the firmware side … identifiers tying it to the hardware interface it belongs to … converted to not having that when being sent over as a struct … enum mappings … indexes … in the shortest format we possibly can"* — + his clarification (*"if we have 3 we should change, and if we have 20 we should change what our plan is too"*). **Rows** (grpcbridge, `objects/mapping/`): `HardwareInterfaceBinding` (row ↔ board instance ↔ interface/port on a bridge + the dense `instance_index`), `EnumMapping` (seeded SimRigState.status {boot, ok, commanded, echoed, fault}, UnoAnalogState.status), `WireContract` (derived: order, enums, index representation + the `packed_max_bits` knob + the suggestion, both hashes). Seeded: two bindings on bridge `uno-pair` → a 1-bit index. **Wire v2..v4** (`c_twin_v2.py`; header unchanged, version byte = the index representation: 2 none/packed, 3 index byte, 4 u16): a prelude of presence bits (+ index) then ONLY the present fields; enum fields 1 B; the struct carries no identity. **Index = f(n)**: 0/1/2/3… bits = ceil(log2 n) packed up to 16 instances, an explicit byte to 256, u16 beyond — rows tested at n = 1,2,3,4,5,8,9,16,17,20,256,257. **gRPC** `hardware_interface` (tag 2047, shared message) filled by the bridge up (from its binding k) and the server down (from the row's binding); the server picks the row by the binding (a wrong index is refused, counted), applies PRESENT fields even at default (**finding (1) fixed**), and a PUT's own values ride the command (a 10 Hz telemetry frame between the PUT and its notify no longer replaces them — polariCRUDE `note_command`). **Bridge**: `BindingRouter` (one pty/port per binding, frames tagged by port, commands routed by (class, index)); commands go down in the version the device speaks up (an old v1 board still works). **Finding (3) fixed** in the v2 C parser (slide to the next 0x4C inside a rejected candidate) and the Java parser (pushback); v1 headers untouched (sha pinned). **contract hash v2** (order + types + enums + index part); v1 kept as `contract_hash` (schema staleness); the installer's compat compares hash v2 first, then the header sha. **uno-pair** = uno-sim-rig built per instance (`--instance-index`, `SEND_NAME 0`). **One instance = no index anywhere** (his ruling 2026-10-02, *"if it is index 0 and only one instance, the struct in the firmware is not needed"*): the n=1 header has no `<C>_index_t` / `_INDEX_*` / index parameter, board_config.h no `INSTANCE_INDEX`, the frame is presence bits only (C bytes == the n=1 wire layout, c_twin selftest), the host reads index 0 by construction; the four single-instance variants regenerate with the same measured sizes (the compiler had already folded the constant away). **Analysis**: `GET /api/board/instances/<id>/interface` (row → contract → wire → binding → instance → port/adapter → definition → facts; what is missing is said), `pol board interface <id>`, the bindings table on `/display/boards`. **Sizes** (live v1 order, avr-gcc 14.2.0 -Os, flash / static RAM, brd-fi → brd-wire): uno-sim-rig 4532/763 → **4338/491**, uno-blink-only 1514/501 → **1014/302**, uno-adc-sweep 1394/528 → **1270/329**, uno-echo 3152/763 → **3022/495**, uno-pair (n=2) **4372/493**, n=3 4378–4380/493 (the status string's 64-B buffer → 1 B and the smaller RX bound). **Proven**: `tests/board_pair_probe.py` 25/25 — n=2 (seeded bindings) AND n=3 on three simavr twins + the generated bridge: each row follows ITS twin (19.824 / 24.707 / 29.590 °C at 700/750/800 mV), frames carry index 0..n-1, a PUT to the last row moves ONLY its OCR0A ([0, 107] / [0, 0, 107]), a PUT to row 0 the other way ([25, 107] / [25, 0, 107]), the row set true in-process returns to false from the next frame in 0.1 s, the chain endpoint answers; `board_installer_probe` 27/27 (blink's ROW toggles: 5 flips in 3 s); bridge 12/12, twin 12/12, liveboot 43/43; selftests board 128/128 (`mapping` 16), c_twin 42/42, contracts 34/34, serving 28/28, javabridge 25/25, cause_context 41/41, outbound 61/61, manifests 8/8, conform board + grpcbridge OK. **Also fixed**: `register_rows.json` was never committed (the framework's `*.json` ignore) — a fresh clone could not boot board; the probes now boot with the framework as cwd (`tests/board_probe_boot.py`, DB in the throwaway dir, the legacy-data migration guarded). | **Owed on real UNOs:** two UNOs (or one + its twin) on one bridge through the by-id paths; an index written at install / announced at boot instead of one build per index (designed in §grpc-j4, not built); RS-485/SPI multiplexed links (v3/v4 routing) | his ruling 2026-10-02 |

Not in scope: JTAG/SWD probes, SD-card boot flows, the BLCNC safety board, RP2040/ESP32/STM32 admission (D-brd-4 opens a
follow-on slice).
