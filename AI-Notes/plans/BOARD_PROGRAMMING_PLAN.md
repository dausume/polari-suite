# Board programming (brd arc): program REAL boards over USB / USB-C from Polari — the Arduino UNO R3 (his Starter Kit) first, the BeagleV-Fire second; a board and its twin are interchangeable behind the same bridge seam

**Date:** 2026-10-01 · **Status: PLAN (brd-0 not started). No code changed.** Drafted by an opus agent from verified
sources, reviewed and shaped by Fable; the seam, the rule and the decisions are the design. His ask: he owns the Arduino Starter Kit
(UNO R3 + its parts) and a BeagleV-Fire and wants both as ways to program boards FROM Polari. **THE RULE (his,
2026-10-01): only boards programmable over USB or USB-C are admitted. JTAG-only and SD-card-only flows are out.** USB keeps
a board reachable from Polari with nothing but a cable. The rule becomes a selftest (brd-0).
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

## 7. Decisions (his; recommendations in bold)

- **D-brd-1 toolchain delivery.** Option one is a worker image `prf-board-engines` (avr-gcc + avr-libc + avrdude + simavr
  pinned; later picotool/esptool/dfu-util — C toolchains only, RULE 2) resolved by the ladder (knob `BOARD_ENGINES_URL`, provider module
  `board.engines`). Option two is host apt. **Recommend the worker**, so pol-core installs nothing. Flashing still
  resolves on `BoardInstance.host` with the device mapped (§2).
- **D-brd-2 Libero.** The choices:
  - (a) allow it as a proprietary ENGINE in its own worker (`prf-libero-engines`, never embedded, never in our images'
    redistribution, licence daemon + MAC recorded, the Silver licence is HIS account);
  - (b) BeagleBoard's GitLab CI builds our fork's gateware;
  - (c) no FPGA half until an open flow exists (there is none today).
  **Recommend (a) with the licence row in `LICENSES.md`**, with (b) as the zero-install fallback. Whether Libero's EULA
  permits containerised use is **unverified** and must be read before brd-2b.
- **D-brd-3 what runs ON the Fire.** **Recommend the bridge only first**, then measure RSS/CPU, then decide on the full
  framework.
- **D-brd-4 the next USB boards to admit.** The candidates are RP2040/Pico (UF2 mass storage), ESP32 (esptool) and
  STM32 (DFU). **Recommend RP2040**: UF2 is drag-and-drop over USB, the tools are open, and it is the Communication tier
  (RP2040 + iCE40) of the hardware architecture.
- **D-brd-5 the kit's parts as `electrodevice` rows.** **Recommend yes, lazily**: one per project as the ladder reaches it.
- **D-brd-6 (new, from §4a) the Fire reflash.** The HSS `usbdmsc` step needs the UART header. **Recommend keeping
  "Fire = shipped image + updates and gateware over USB-C" inside the rule, with reflash as a documented RECOVERY verb
  that names the USB-UART adapter as outside the rule.** The alternative is to drop the Fire from the arc.
- **D-brd-7 module home.** **Recommend a new `board` module** (rows, CLI, templates, `requires.engines`). It reuses
  `hwmap`'s scanner and `grpcbridge`'s header rather than growing `hwmap`.

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
| brd-0 | `board` module: Board/Instance/FirmwareBuild rows + `Road`, `DatasheetFact`, `BoardSimCost`; `BoardDefinition` seeds for EVERY register device (roads = todo; only the UNO `simulated=true`), `pol board detect` via `hwmap.scanner`, the USB rule + the C/Verilog/SV rule as selftests, the c_twin AVR mode (double conversion) | `pol board detect` on pol-core lists his UNO as a `BoardInstance` with by-id path | D-brd-7 |
| brd-1 | UNO end to end in PLAIN C (avr-libc, no Arduino core): gen → build (worker, avr-gcc) → flash (DRY-RUN then `--yes`) → monitor; sizes measured | TMP36 value in the `SimRigState` row; REST PUT lights/dims the LED; `status='commanded'` echoed | D-brd-1 |
| brd-2 | Fire: USB-C network detect, `pol board deploy fire` (bridge as systemd unit), recovery `flash --image` documented | the Fire's bridge pushes a row over 192.168.7.2; a PUT round-trips | D-brd-3, D-brd-6 |
| brd-2b | Fire gateware: regblock into the cape design, Libero engine (or BB CI), `change-gateware.sh` from Linux, UIO access | hwsim-led pattern lit on real fabric from a `LedMatrix4x4State` row, read back | D-brd-2 |
| brd-3 | twins in CI: simavr (same UNO artifact) + Renode `beaglev-fire` (+ Verilated regblock); worker images measured | n/a (twin parity: same rows as brd-1/brd-2 hardware runs) | cost rows |
| brd-4 | kit parts as `electrodevice` rows + the 15-project ladder, one project per step | each project's twin field moves on his breadboard | D-brd-5 |

Not in scope: JTAG/SWD probes, SD-card boot flows, the BLCNC safety board, RP2040/ESP32/STM32 admission (D-brd-4 opens a
follow-on slice).
