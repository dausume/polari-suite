# HAL for Catoms (hal) — reference what we have, borrow and cite open HALs, flesh it out

**Date:** 2026-11-11 · **Status:** hal-0 BUILT 2026-11-11 (framework branch `dev-hal-0`, uncommitted at time of writing); the rest
PLAN. Rewritten the same day after the user's corrections. The user, 2026-11-11, on the decisions in §6: "Sounds good please start
implementation", taken as all four recommendations accepted.

**hal-0, as built:** a new `hal` module (`modules/hal/`, requires board):
- **Rows.** Six classes: `HalOperation`, `HalAccessMechanism` (both seeded), `HalBinding`, `HalCodeUnit`,
  `HalGenerationStep`, `HalCrossCheck` (all derived on every read from board's cited tables).
- **The GPIO family on both chips.** 8 operations: output, input, set_high, set_low, toggle, read, pull_up, pull_down.
  - ATmega328P: 161 units resolved (7 operations × 23 pins, Ports B, C and D). pull_down answers "unsupported", said why.
    PC6 resolves with a caveat (RESET unless the RSTDISBL fuse is programmed, Table 14-6).
  - ESP32-C3: 176 units resolved (8 operations × 22 pads).
- **Access mechanisms as data:** avr-io-bit (sbi/cbi), avr-io-byte-rmw, mem-rmw, rmw-field, w1s-alias, w1c-alias, w1c-flag,
  toggle-by-input-write, read-bit, signal-routing-matrix (setup). atomic-alias-window and bit-band are documented but not
  implemented. The generator chooses the mechanism from the register's own facts.
- **Setup before the write.** The ESP32-C3's output = OUT_SEL=128 and MCU_SEL=1 through the routing matrix, then the
  ENABLE_W1TS bit.
- **Interrupt guards** from `isr_safe`: avr-libc ATOMIC_BLOCK on the AVR, an overridable POLARI_HAL_ATOMIC on the C3.
- **Every step traced:** 11 step kinds, each with its inputs, rule, output, source module and datasheet cite.
- **Code at 8 levels:** operation, board pin, chip pin, register binding, mechanism, C statement, macro, line in the final file.
- **Cross-checks:** avr-libc address vs the datasheet's printed data address (pass); the C3's recorded ESP-IDF check, cited.
- **The final header** `polari_hal_<soc>.h`, line by line, each line tied to its unit and step.
- **Doors** `/api/hal/*` and the page **/display/hal**, with a tab per chip and per header, plus Operations and Access
  mechanisms tabs. It is linkable from a Bench Simulation: `/display/hal?tab=atmega328p&unit=atmega328p:gpio.set_high:PB5`.
- **Selftest `hal_selftest` 51/51**, including two real-compiler proofs:
  - avr-gcc -Os (prf-board-engines) emits `sbi 0x5,5` / `cbi 0x5,5` / `out 0x3` / `sbi 0x4,5` exactly where the mechanisms
    say;
  - the C3 header compiles clean with `-std=c99 -Wall -Werror`.
- **Registered in the core tables:** module_loading, feature_imports, module_endpoints, polariServer (classes, seeds,
  pages), app_taxonomy, polari-modules.json. `conform` is OK.

**hal-1 + hal-2, BUILT 2026-11-11 (same branch, uncommitted: the user's rule is no commits Mon-Fri 09-18):**
- **Unified task kinds dropped as a separate phase.** `board.custom.target_compat.compatible()` is already the single entry
  point for both chips: it hands the ESP32-C3 to `soc_functions`. The internal split stays, since refactoring it changes
  nothing visible.
- **Operations are ordered parts** `{role, action[, value]}`. Role rules match a field by pin, by signal (INTn) or by name
  from yielded variables (`PCMSK2` -> bank 2 -> `PCIE2` / `PCIF2`). `lookup` and `symbol` parts exist for vectors.
- **The interrupt family: 8 operations** (pin_change enable / disable / clear / vector, edge enable / disable / clear / vector).
  - UNO: 100 units. Edge operations only on PD2/PD3; other pins answer "unsupported: no INTn function".
  - C3: 132 units. Vectors are unsupported, said why: the interrupt matrix, so ESP-IDF attaches the handler.
- **`_INIT` macro forms:** guarded read-modify-writes get an unguarded form for init code, which runs before `sei()`. The
  rule is recorded in the trace.
- **The read form is now `(REG & mask) != 0u`.**
- **hal-2: isotopes declare `requires`** in isotope.json, per variable pin. Three isotopes are written against the HAL macros:
  read-button/pin-change-interrupt, sense-led-line/gpio-poll and sense-led-line/pin-change-interrupt.
  - `hal.custom.project` resolves the requires and refuses by name.
  - `gen` writes ONE merged `polari_hal_atmega328p.h` per project and records it as a repro input.
  - **Proof: all 9 route variants build to the byte-identical .hex of `dev`** (uno-light, -pcint, -analog, -all-pcint,
    -sense-poll, -sense-pcint, -pwm-analog, -transistor, -slow-loop).
- **Isotope fit** (`hal.custom.isotopes`; `/api/hal/isotopes`, `/api/hal/isotopes/{catom:isotope}/fit?soc=`; an "Isotope fit"
  tab on /display/hal).
  - read-button/pin-change-interrupt fits 16 of 23 UNO pins.
  - It fits 0 of 22 C3 pads, and the only thing missing is the vector. A C3 isotope that attaches through ESP-IDF is the next
    step there.
- **Knock-on changes, each covered by an existing test:**
  - Templates call operations as `{{ hal_ops.<op> }}`. `hal.` stays reserved for the catom's HAL variables, as the editor's
    converter requires.
  - `cmod.custom.glue` carries `polari_hal_<soc>.h` with the route files into graph projects. `uno-light-graph` was
    re-rendered (+ the header).
  - The UNO `polari-firmware.json` was re-conformed: only source shas and line numbers moved, every measured cost is unchanged.
  - The editor round-trip test copies `isotope.json` too.
  - Two route tests now expect `ISR(HAL_INT_PIN_CHANGE_VECTOR_<pin>)`.
- **Edge variants:** int.edge_enable_falling and int.edge_enable_rising (AVR ISCn 2 / 3, C3 INT_TYPE 2 / 1, both cited). That
  makes 18 operations. hal_selftest is 69/69.
- **Suites on the final code:** hal 69/69, cmod 1378/1378, board 1122/1122, board_variant_twin 33/33, board_light 46/46.
  - cmod is dev's 1377 + 1 new check.
  - board is dev's 1123 minus one check that only runs inside the suite checkout (it reads AI-Notes four directories up).
  - uno-light-graph was rebuilt by make alone to the same hex cf5d6e28 and re-proved equivalent on the twin (10 frames,
    raw UART identical).
- **Next proposed phase (needs review, NOT started): re-express `uno/hal.c` on the generated HAL.** It is the verbatim
  template every project copies, and its LED / button / sense pin code (DDRx / PORTx / EICRA / EIFR / EIMSK) maps onto
  units that exist now (gpio.*, int.edge_enable_falling for the INT0 button, int.edge_enable for the INT1 sense).
  - USART, Timer2, ADC, PWM and WDT need the next HAL families first.
  - **The ripple:** the UNO manifest's atoms (the parser cross-check pins 13 functions in hal.c), the three committed graphs,
    their glue records + twin proofs, pin_config_gen's ownership of the same writes, and role aliases (LED_PIN is a knob,
    so the header needs `HAL_LED_*` aliases per variant).
  - **The gate stays an identical .hex for every UNO variant.**
- **Port C: closed 2026-11-11.** The user OK'd the datasheet download. The file's sha256 matched the recorded DS40002061B
  revision (b9b9d83c…9320e). §14.4.5-7 were read into `register_fields_atmega328p`: PORTC 0x08, DDRC 0x07 (p.100), PINC 0x06
  (p.101). Bit 7 is reserved, so there are 7 bits. avr-gcc proves DDRC = `sbi 0x7,0`, PORTC = `sbi 0x8,0`, and the A0 vector is
  PCINT1 (`__vector_4`). A pin-change button on A0-A5 now resolves instead of being refused.

**Phase numbering from here:** hal-0 above was the model + generator + trace + pages. §5's hal-0..hal-5 follow as hal-1..hal-6
(unified task kinds; isotope `requires`; generated header replacing `uno/hal.c`; C3 coverage; RP2350; more catoms). Port C
field ingest is done (above).

**The user, 2026-11-11:**
- Flesh out the HAL under the Catom system from open-source HALs that already exist, borrowed and cited, "so we can more
  easily make firmware going forward, and doing the mappings properly".
- C ports of C++ sources are allowed: "based on X code".
- The catom / isotope model stays as it was. `read-button` done via a pin-change interrupt or via an analog threshold are
  two ISOTOPES (ways). One isotope may work on several boards with different HALs. The HAL sits one level below.
- The HAL handles port and register mapping.
- "We should already have ways of making and using existing HALs ... we should reference existing ones and flush them out
  further."

Output stays plain C (RULE 2).

Companions:
- REGISTER_MAPPING_PLAN.md (rm-0..5)
- HARDWARE_SYSTEM_PINS_PLAN.md (hsp, §7 HAL in no-code)
- CATOM_CONFIG_PLAN.md (catom / isotope / configuration)
- FIRMWARE_FLOW_STATES_PLAN.md (the HAL object, flow-4)
- C_MODULARIZATION_PLAN.md (atoms, conform)
- FIRMWARE_GENERATION_MODULE_PLAN.md (CIsotope templates)

## 1. The model (unchanged)

```
catom      the job + its interface          read-button: "know when the button is pressed"        catom.json
isotope    one WAY of doing the job         pin-change-interrupt | analog-threshold | gpio-poll    catoms/<job>/isotopes/<way>/
           - may run on several boards: it is written against task kinds + HAL mappings
HAL        port + register mapping, per SoC which pin is which port/bit, which pins carry INT/PCINT/ADC/OCnx,
                                            which registers + fields set each up                    rows -> C header
board      board pin names -> SoC pins      UNO D13 -> PB5                                          BoardPin / BoardPinNet
```

## 2. What we already have (inspected 2026-11-11 on framework `origin/dev-electronics` 4c4a4c10)

| layer | existing | state |
|---|---|---|
| SoC facts | `SocDefinition`, `SocPin`, `PinFunction`, `Peripheral` rows; `soc_atmega328p.py`, `soc_atmega16u2.py`, `soc_samd21.py`, the C3 pin rows; `uno_facts.py` (DatasheetFact) | cited datasheets |
| registers | `Register`, `RegisterBlock`, `RegisterField`, `RegisterSetting`, `RegisterFieldSetting`, `RegisterAddressMapping`, `RegisterAccessKind` (UVM + CMSIS-SVD names). Data: `registers_atmega328p.json` + `register_fields_atmega328p.py` (96 registers, all classified); `registers_esp32c3.py` (the drawing set: GPIO, IO MUX, matrix, strap, reset, UART0 essentials, from TRM v1.4, cross-checked field by field against ESP-IDF `soc/*.h`) | rm-0..rm-3 built 2026-10-29 |
| register meaning | `register_taxonomy.py` (domains + control/status/data roles, 43 cited rules), `register_profile.py` (pin-configuration / peripheral-operation / ...), `register_view.py` + the Registers tab on the bench | built |
| **task kinds = mapping kinds** | `target_compat.py` TASK_KINDS (digital-in/out, interrupt-in, analog-in, pwm-out, uart-rx/tx, i2c-*, spi-*, power/ground). The UNO reads them off alternate-function names; `soc_functions.py` gives the C3 the same kinds as patterns over its GPIO-matrix functions | built (two code paths) |
| isotope fit | `isotope_variants_eligibility.eligible(variant, ctx, tier)`, `button_routes.py`, `bench.py` | built for the UNO catoms |
| HAL values in no-code | `catom_variables.py` (slots per role), `hal_nocode.py` (the `hal-<variant>` solution, one card per variable), `hal_electrical.py` (judged against the bench wiring), `HalVariableState` | hsp-3c/3d built |
| HAL object | FIRMWARE_FLOW_STATES_PLAN: Pin / Serial link / Clock tick ... = one peripheral's claim + init atom + use atoms + datasheet bindings | planned (flow-0, flow-4) |
| **HAL C code** | `firmware/uno/hal.c/.h`, hand-written. **The same file is copied byte-identical** into `cmod/custom/graphs/{uno-light,uno-button-clock,uno-sim-rig}-graph/` (one md5, four places). The C3 has `apps/light_hal.h` over ESP-IDF calls | hand-written per board, duplicated |

So the mapping knowledge is already rows, cited and viewable. What is missing is mostly the step from rows to the C the
isotopes compile against, plus coverage of more chips.

## 3. The gaps this plan closes

1. **The HAL C is hand-written and copied.** No C header is generated from the Register / PinFunction rows, so every
   firmware re-types the port, bit and register choices the rows already hold. Four copies of `hal.c` drift together or
   apart by hand.
2. **Two code paths for task kinds.** The UNO's kinds are hard-coded name readings in `target_compat` (and `ladder`,
   `isotope_variants_eligibility`, `solve_needs`); the C3's are patterns in `soc_functions`. A third chip would make three.
3. **Isotopes do not declare what they need.** Eligibility is coded per catom (`button_routes`), so it does not extend to
   a new catom or a new board without code.
4. **Chip coverage is thin.** Full registers: ATmega328P. Drawing set only: ESP32-C3 (no ADC, LEDC, timers, I2C, SPI
   yet). SAMD21: electrical numbers only. RP2350 (Pico 2, the RISC-V-first pick): nothing.
5. **No upstream HAL code is referenced.** The ESP-IDF headers are already used as a cross-check for the C3 rows. That is
   the pattern to repeat: the vendor's or Arduino's open mapping files as the cross-check (and the borrowed C), the
   datasheet as the citation.

## 4. What we borrow, per SoC (licences verified 2026-11-11 from each repo's LICENSE file or SPDX headers)

| SoC | mapping files to cross-check against and borrow from | licence | also used for |
|---|---|---|---|
| ATmega328P | ArduinoCore-avr `variants/standard/pins_arduino.h` (pin -> port, bit, timer, PCINT, ADC tables); `cores/arduino/wiring_digital.c`, `wiring_analog.c`, `WInterrupts.c`, `wiring.c` | LGPL-2.1-or-later (core C files read; the `pins_arduino.h` header still to read) | isotopes: C ports of `HardwareSerial*.cpp`, `Tone.cpp`, `SPI.h`, Wire `twi.c` ("based on") |
| ATmega328P | avr-libc `avr/iom328p.h`, `util/atomic.h`, `avr/wdt.h`, `avr/sleep.h`, `avr/eeprom.h` | BSD-3-Clause style | already the toolchain |
| ESP32-C3 / P4 | ESP-IDF `components/soc/<chip>/register/soc/*.h`, `soc/<chip>/include/soc/*_channel.h`, `esp_hal_*/<chip>/*_ll.h` (the vendor's own low-level mapping layer) | Apache-2.0 (keep NOTICE) | isotopes may call `esp_driver_*` directly where that is the honest way |
| RP2350 | pico-sdk `src/rp2350/hardware_regs/include/hardware/regs/*.h`, `hardware_structs`, `hardware_gpio` function-select tables | BSD-3-Clause | the SDK is called by isotopes |
| GD32VF103 (later) | GigaDevice firmware library headers | BSD-3-Clause per file, no repo LICENSE: copy only files whose header we read | |
| nRF52840 / STM32 (later) | nrfx; STM32 HAL/LL driver repos (not the whole Cube tree) or libopencm3; CMSIS_6 | BSD-3; BSD-3 / LGPL-3.0+; Apache-2.0 | |
| SAMD21 | **held**: no official Microchip ASF4/Harmony licence found. CMSIS_6 + the datasheet rows we have; Zephyr as the driver route | | |
| API shape only | Zephyr drivers API (Apache-2.0), RIOT periph (LGPL-2.1-only), Mbed HAL (Apache-2.0) | | naming and argument shape; no code copied |

**How borrowed code is marked:**
- Each file keeps its upstream copyright lines.
- It gains an SPDX line and a header:
  `Based on <project> <path> @ <commit> (<licence>), ported to Polari HAL names`.
- Licence texts and notices go in `firmware/LICENSES/`.
- Each upstream file is also cited the way rows are cited today: project, url, path, commit, sha256, licence, and the kind
  of borrowing (verbatim / adapted / C port of C++). This uses the existing citation fields where they fit. A new row type
  is added only if they don't.

## 4a. A generalized HAL model (the user, 2026-11-11)

"we are trying to move towards a truly generalized HAL model ... existing ones as a cross reference ... HAL code we
generate should be accessible as their own objects and if there are key differences like port vs memory mapping, we have
those as a kind of data we track for how the code should be autogenerated."

So the HAL is not a per-chip C file we write. It is a **chip-independent model, held as rows**, and the C is generated
from those rows. Existing HALs (Arduino, ESP-IDF, pico-sdk, CMSIS, Zephyr) are cross-references, never the model.

**HAL objects (rows, each with its own page, citations and generated C):**

| object | what it is | example |
|---|---|---|
| `HalOperation` | a chip-independent operation in the generalized vocabulary | gpio.set_high, gpio.read, pcint.enable, adc.start, uart.put |
| `HalBinding` | that operation on one SoC: which register / field / bit / value, with the access mechanism | gpio.set_high on PB5 = PORTB bit 5 via `sbi`; on C3 GPIO8 = write 1<<8 to GPIO_OUT_W1TS |
| `HalAccessMechanism` | HOW a register is reached and changed: the data that drives code generation | see below |
| `HalCodeUnit` | the generated C for one binding (macro or inline function), with its source rows and sha256 | `#define POLARI_GPIO_SET_HIGH_PB5() (PORTB \|= _BV(5))` |
| `HalCrossCheck` | one comparison against an upstream HAL file, with its result | `pins_arduino.h` digital_pin_to_port[13] == PB |

The existing `Register`, `RegisterField`, `RegisterSetting`, `RegisterAddressMapping` and `RegisterAccessKind` stay the
source of facts. A `HalBinding` points at them. It never copies them.

**Access mechanisms are tracked data** (each one cited, with how it generates code). First set:

| mechanism | meaning | generates | chips |
|---|---|---|---|
| port-mapped I/O, bit-addressable | a low I/O-space register a single instruction can set or clear | `sbi` / `cbi` (`PORTB \|= _BV(n)` with a constant n compiles to it) | AVR, I/O-space 0x00-0x1F (data 0x20-0x3F) |
| port-mapped I/O | I/O space, byte access only | `in` / `out` | AVR, I/O-space 0x20-0x3F (data 0x40-0x5F) |
| memory-mapped, read-modify-write | an ordinary address; set means read, OR, write | `REG = REG \| m` inside an interrupt guard when shared | AVR extended I/O (data 0x60-0xFF), most MCUs |
| memory-mapped set/clear/toggle aliases | separate write-1-to-set / clear registers, atomic by design | `REG_W1TS = m` | ESP32 (GPIO_OUT_W1TS/W1TC), RP2350 SIO (GPIO_OUT_SET/CLR/XOR), STM32 BSRR |
| atomic alias windows | the same register at +offset addresses for set / clear / xor | `*(REG + SET_OFFSET) = m` | RP2040/RP2350 (+0x1000 xor, +0x2000 set, +0x3000 clear; to be cited from the RP2350 datasheet) |
| bit-band | one bit mapped to its own word address | `*BITBAND(addr, bit) = 1` | Cortex-M3/M4 |
| toggle-by-write-to-input | writing 1 to the input register toggles the output | `PINB = _BV(n)` | AVR (PINx) |
| signal routing matrix | a peripheral signal is routed to a pad through a matrix register, not fixed to a pin | write FUNCn_OUT_SEL / IN_SEL first | ESP32 GPIO matrix, RP2350 FUNCSEL |
| W1C status | a flag cleared by writing 1 | `FLAG = m`, never read-modify-write | AVR PCIFR/TIFR, ESP32 STATUS_W1TC |

The generator picks the mechanism from the binding's register (address range, access kind, alias registers present).
A person does not pick it. The same `HalOperation` then generates correct and efficient C on each chip. This is also how
interrupt safety is decided: read-modify-write on a shared register gets a guard, a set/clear alias does not.

## 5. What gets built

**hal-0: one task-kind table per SoC, derived.** This replaces the two code paths with one mapping:
`(soc, pin) -> kinds[] + (peripheral, signal, the RegisterFields that select it)`.
- The UNO's name readings and the C3's patterns become per-SoC rule tables in one module, each rule cited.
- `target_compat`, `ladder`, `isotope_variants_eligibility` and `solve_needs` read from it.
- Proof: every existing selftest unchanged, and the UNO and C3 kind tables identical to today's.

**hal-1: isotopes declare `requires`.** In `catom.json`, per isotope: the task kinds each variable's pin needs (for
example `pin-change-interrupt` needs `interrupt-in` with a PCINT, `analog-threshold` needs `analog-in`) plus the
peripherals it claims.
- Eligibility becomes generic: requires ⊆ what the board's pins offer. `button_routes` reduces to data.
- The catom page shows, per board, which isotopes fit, or which kind is missing.
- Proof: the two existing catoms give the same eligibility as today on the UNO and the C3.

**hal-2: the HAL objects and the header generated from them** (`HalOperation`, `HalBinding`, `HalAccessMechanism`,
`HalCodeUnit`, `HalCrossCheck` rows, §4a; output `hal/<soc>/polari_hal_map.h`):
- per pin: port, bit, and the PCINT/INT/ADC/OCnx numbers;
- per peripheral: the register and field names and the values a RegisterSetting chooses;
- constant-folded macros, so a fixed pin compiles to direct PORTx code.
- Cross-checked against the borrowed upstream tables: Arduino `pins_arduino.h` for the UNO, ESP-IDF `soc/` for the C3. A
  mismatch fails the check by name.
- Today's `uno/hal.c` is re-expressed on the generated header, and the four copies become one generated file per firmware
  project.
- Proof: every shipped UNO variant builds to the **same .hex**, and the twins pass.

**hal-3: ESP32-C3 coverage completed.** The rows for ADC, LEDC, systimer, I2C and SPI, read from the TRM the C3 rows
already cite and cross-checked against ESP-IDF headers. Then the generated header. Proof: the `read-button` and
`sense-led-line` isotopes build and pass on the C3 twin with no isotope change.

**hal-4: RP2350 (Pico 2), the first new SoC through the whole pipeline.** SoC, pin and register rows from the RP2350
datasheet, cross-checked against pico-sdk `hardware_regs`; the board map; the generated header. Proof: blink, button and
uart on a twin, then on a board. This is the test that adding a chip is now data, not code.

**hal-5: more catoms over the HAL,** each with at least two isotopes, based on and cited from the Arduino C files or ported
from its C++:

| catom | isotopes (ways) |
|---|---|
| drive-output | plain gpio, pwm-held |
| keep-time | Timer0 overflow tick (Arduino millis/micros), Timer2 1 ms tick (ours), system timer |
| serial-link | interrupt RX ring + polled TX, buffered TX |
| read-analog | single read, averaged, threshold |
| drive-pwm | hardware compare, software pwm |
| make-tone | timer toggle |
| measure-pulse | busy-wait count, input capture |
| shift-bits | bit-bang |
| talk-i2c | hardware TWI, bit-bang |
| talk-spi | hardware SPI, bit-bang |
| store-setting | eeprom, flash page |
| guard-watchdog | reset mode, interrupt-then-reset |
| sleep-until | idle / power-down + wake source |

**Later:** GD32VF103, nRF52840, STM32G4; SAMD21 once its licence is cleared; the HAL object canvas (flow-4) over these rows.

## 6. Decisions for the user

1. **D-hal-1, the licence of generated firmware projects.** I recommend GPL-3.0-or-later. That keeps every borrowed source
   above compatible without per-project checks.
2. **D-hal-2, RIOT (LGPL-2.1-only).** I recommend using its API shape only, no code, unless a licence-gate review clears it.
3. **D-hal-3, the order.** I recommend hal-0..2 on the UNO, then the C3 (hal-3), then Pico 2 (hal-4). Electronics proving
   stays first, and hal-0..2 are no-behaviour-change refactors that make it easier.
4. **D-hal-4, where catoms live.** I recommend moving `uno/catoms/` up to `firmware/catoms/`, since an isotope is no longer
   tied to one board.
