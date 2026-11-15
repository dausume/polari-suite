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

**Shared ledger: pol + econ** (the user, 2026-11-12: "split the work for the hal between you and econ and have an ongoing
cooperation on it"). Each phase has its own branch and is handed over as a bundle + sha in core ~/collab. The other side
reviews it before it is folded in. Weekday commit hours apply to both.

| Phase | Owner | Branch | Status |
|---|---|---|---|
| hal-1 page (firmware headers) + hal-3a (hal.c pins on roles) | pol | dev-hal-1 | COMMITTED 5633c263, then merge of r3 864a956f (onto the rel-87 line), then review fixes 06ad32a8 (2026-11-13, not pushed); bundle core ~/collab/pol-framework-dev-hal-1-r2.bundle sha 352194ac…; econ reviewed (a: 28/28 variants match; b: naming kept, collision guard added) |
| hal-3b slice 1: generator core (args, value read/write, peripheral targets, composite, derived values, inherent, wide, fail-closed) + 328P pwm family + hal.c PWM on roles | pol | dev-hal-3b | COMMITTED cfd9e1fb + 7b74c471 + f738536d (2026-11-13, not pushed); bundle core ~/collab/pol-framework-dev-hal-3b-1.bundle sha ad33ed32…; all suites green; awaiting econ review |
| hal-3b slice 2a: chip independence (PROVIDERS per soc, unknown refused, required C facts, choose() on facts only, prelude/includes as data, bit-field divider) + the access table (§4d) | pol | dev-hal-3b | COMMITTED c5905ca7 (2026-11-13 05:4x, not pushed); bundle core ~/collab/pol-framework-dev-hal-3b-2a.bundle sha 874be720…; 17/17 hex identical to slice 1; awaiting econ review |
| chipdesc_provider: any chip description -> a PROVIDERS + RULES entry; toyperiph as a third soc with zero generator changes | econ | econ/hal-chipdesc | next, on slice 2a's interface |
| hal-3b slice 2b: the CFG_ prefix migration, the 328P tick / uart / adc families + hal.c onto them | pol | dev-hal-3b | next |
| review + twin / selftest sweeps of each pol candidate (first: dev-hal-1) | econ | - | agreed |
| 3a: C3 field rows (UART0/1, LEDC, SAR ADC, systimer, interrupt matrix), TRM v1.4 sha 90ef8256…7423 evidence pattern | econ | econ/hal-c3-rows | agreed, starts on the dev-hal-1 bundle |
| 3: C3 role rules for the hal-3b families + ESP-IDF vector isotope | econ | econ/hal-c3-roles | after the hal-3b role-rule shape lands |
| 4: chip-description format. Importer: **CMSIS-SVD first** (vendor SVDs; our RTL via SystemRDL → PeakRDL → SVD; LiteX emits SVD + csr.csv), SystemRDL / IP-XACT later. It produces the register map only; roles, pins and vectors stay hand-written, cited rows. Cross-check: the C3 SVD import agrees field for field with 3a | econ | econ/hal-chipdesc | agreed; draft spec first |
| 4 proof chips, ZERO generator changes: (i) RP2350 Hazard3 (vendor SVD + datasheet; a real board exists); (ii) a LiteX VexRiscv SoC (UART, timer, GPIO) from LiteX's own SVD — the stand-in for a chip we make. Anything that forces a generator change = a finding to pol, naming the rule | econ | econ/hal-chipdesc | agreed |
| hal-iso: isotope needs + the isotope's own header + level triggers (§5a) | pol | dev-hal-3b | BUILT 2026-11-14 (hal_needs 22/22, hal 114/114); for econ review |
| hal-ui: option cards per catom (method + requirement dropdowns, §5a) | pol | - | PLAN ONLY; D-ui-1/2 for the user |
| more catoms over the HAL (hal-6) | both | - | later |

**hal-1 page + hal-3a, BUILT 2026-11-12 (framework branch `dev-hal-1` off `dev-hal-0`, + the rel-87 cst fix cherry-picked):**
- **The user, 2026-11-12:** the "final generated header" tab was misleading. It rendered every resolved unit of the chip. A
  build must only ever get the units it needs, collapsed to exactly what the board / bench / firmware specify. Operations and
  Access mechanisms come first in the tabs.
- **The page:**
  - Tab order is now Operations, Access mechanisms, `<chip> catalogue` x2, Firmware headers, Isotope fit.
  - The chip tabs are labelled CATALOGUE: what the HAL can give, never emitted on its own.
  - The per-chip header tabs are gone.
  - `/api/hal/socs/{soc}/header` with no `keys`/`pins` now answers no rows plus a note. It never renders the whole chip.
- **Firmware headers (new):**
  - `GET /api/hal/firmware` lists every variant with the units its header holds, who required them, or why it holds none.
  - `GET /api/hal/firmware/{variant}/header` gives that header line by line, with `required_by`.
  - It is the same text the build writes, through one shared function: `board.custom.gen.render_routes` (gen() and the page
    both call it). The page and the build therefore cannot differ.
- **hal-3a: `uno/hal.c` on the generated HAL.**
  - `gen.base_roles(r)` is what the shared template needs for THIS build. It uses the same conditions as board_config.h:
    - LED: output, set_high, set_low on LED_PIN.
    - The INT0 button: input, pull_up, edge_enable_falling, edge_vector.
    - The INT1 sense: input, read, edge_enable, edge_vector.
    - The PWM pin's direction.
  - The header gains a **roles** section, e.g. `#define HAL_LED_SET_HIGH() HAL_GPIO_SET_HIGH_PD6()`: the firmware's words
    pointing at the unit that plays them on this build's pin.
  - hal.c calls only roles for pins. Its LED_PORT/DDR/BIT macros and every raw DDRx/PORTx/PINx/EICRA/EIFR/EIMSK statement are gone.
  - **Gate: all 17 UNO variants build to the byte-identical .hex** (baseline vs after: 17/17).
  - The cst-0 reader expands role → unit → register.
- **hal-3b, started: the field rows the peripheral families need.** These were read from the downloaded DS40002061B:
  - TCCR0A/B, OCR0A/B, TIMSK0 (§15.9);
  - TCCR1A/B, OCR1AL/BL (§16.11);
  - OCR2A (§18.11.4);
  - ADMUX, ADCSRA, ADCL/H, DIDR0 (§24.9).
  - The value tables are the datasheet's (WGM, CS, REFS, MUX, ADPS). FIELDS went from 169 to 208.
- **hal-3b, next (design): four peripheral families.** Each is pin-keyed through the pin's alternate function, so the existing
  signal match reaches it:
  - **pwm:** OC0A/OC0B/OC1A/OC1B — connect / disconnect / set_duty(x).
  - **uart:** TXD/RXD — init(divisor), tx_ready, tx_byte(x), rx_byte, rx_enable_irq, rx_vector, errors.
  - **adc:** ADCn — init(ref, prescaler), select, start, busy, read.
  - **tick:** Timer2, instance-keyed — init(prescaler, top) from F_CPU and the tick period (derived, cited), plus vector.
  - Generator additions:
    - operations with ARGUMENTS (`NAME(x)`);
    - a `reg-write` mechanism (one store of a value);
    - a `reg-assign` configuration mechanism: init-only, writes whole registers from named field values, every other field
      at its cited reset value.
  - **DECIDED (the user, 2026-11-12): behaviour-identical, twin-proven.** "The end goal of this is to try and make this
    something we can apply later to custom risc-v chips we make ourselves, so we want to go with the more adaptive and
    intuitive options."
    - The generator keeps ONE chip-independent rule set. Field writes are field writes; no special cases imitate the old
      hand-written forms.
    - A new chip, including our own RISC-V, is described by its register rows and role rules only.
    - The gate for hal-3b: the twin suites (board_variant_twin, board_light, pinlevel, press latency, circuit states). Every
      changed .hex is re-recorded, along with the reason it changed.

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

## 4b. The hal-3b contract: operations, role rules, mechanisms (LOCKED 2026-11-12, pol + econ)

This is the one reference for pol's generator work and econ's ESP32-C3 rules (3), chip-description importer (4) and proof
chips. It was drafted by pol and reviewed by econ from the C3 + LiteX side. Econ's blocking items 1-8 are in; 9-14 have their
names reserved. The rule: **no generator branch names a chip.** Everything a mechanism branches on is a fact (access, width,
space, io address, reg_width, access_style).

**Operation** (chip-independent, `hal.custom.operations`):
`{name, family, title, target: pin|peripheral, args: [{name, ctype, meaning}], returns, c_name, intent, basis, parts: [{role, action, value?}]}`
- Key: `soc:op:<pin>` or `soc:op:<instance>` (USART0, TIMER2, ADC).
- Actions: set | clear | toggle | read | lookup | symbol, plus the new write | read_value | strobe | wait {field, until, bound, timeout}.
- Values in a part:
  - a name (looked up in the role's `values`);
  - an `{arg}` or an expression over args;
  - `@derive:divider:{x}` / `@derive:mode:<name>`, read from the CITED value table of the field;
  - `@derive:pin_number` / `@derive:signal_index:<sig>`.
- Ops pass physical quantities only ({baud}, {duty_pct}, {prescaler}), never register numbers.

**Role rule** (per chip, `RULES[soc]['roles']`):
`{registers, match: pin|signal|name|peripheral, field?, signal_re?, values?, modes?, yields?, by_action?, fields? (composite), wide?, value_expr?, vector: {kind: symbol|register|dispatch, ...}?, inherent: {cite, words}?, missing?, condition?, cite}`
- `by_action` overrides the registers / field for each action (C3 W1TS / W1TC / IN; LiteX rxtx).
- `fields` holds one logical value split over several fields: the 328P WGM over TCCRnA/B, UBRR0H/L, LiteX 8-bit CSR slices.
- `value_expr` is computed over args + named cited facts ({f_cpu}, {clk_hz}): UBRR, C3 CLKDIV + FRAG, the LEDC fractional duty.
- `inherent` = fixed by silicon: emits nothing and says why. `missing` = can't do it.
- `RULES[soc]['peripherals'] = {instance: {vars, signals, cite}}`. Chip facts: `access_style` symbol | address | accessor, `reg_width`.
- Vendor access codes map to our access facts in ONE table, which the importer uses. It reads three vocabularies:
  - TRM codes: WT, WTC, SC, SS ...;
  - SVD modifiedWriteValues / readAction: oneToClear → w1c, oneToSet → w1s, clear → rc;
  - SystemRDL properties: singlepulse → w-strobe, onwrite=woclr → w1c, onread=rclr → rc, hwclr → self-clearing.
- **Chip description** = the SVD for structure (blocks, registers, fields, offsets, dim / %s arrays expanded, with the index
  being what @derive:pin_number / signal_index land on) + a CITED ACCESS OVERLAY refining each field's access + role rules.
  - Vendor SVDs often lose access semantics. Espressif's esp32c3.svd @ be20aa12 has zero modifiedWriteValues / readAction:
    only read-write / write-only / read-only. The TRM uses 10 codes, so for the C3 the overlay is generated from the TRM.
  - The importer flags every field where the SVD and the overlay disagree on direction.
- **choose() fails closed on a coarse access fact** (econ, 2026-11-12), i.e. one with no overlay entry:
  - write-only → a plain store, never a read-modify-write;
  - `strobe` and `wait` REFUSE ("access semantics unknown: needs a cited overlay") rather than guess that a bit self-clears;
  - a coarse read-write field still gets a read-modify-write. The risk is a hidden W1C bit sharing the register, which the
    overlay exists to catch.

**Mechanisms** (data rows, chosen by `choose()` over facts):
- the existing ones;
- reg-write, field-write (runtime value), read-reg / read-field, wide-write / wide-read, composite, strobe, wait;
- vector-symbol / vector-register / vector-dispatch.
- They render through `access_style`.

**Role vocabulary:**
- pwm: pwm_mode, pwm_clock, pwm_output, pwm_duty, pwm_update.
- tick: timer_mode, timer_clock, timer_top, timer_irq_enable, timer_vector, timer_update, timer_value, timer_alarm.
- uart: uart_baud, uart_double_speed, uart_frame_bits, uart_tx_enable, uart_rx_enable, uart_rx_irq, uart_tx_ready, uart_data,
  uart_frame_error, uart_overrun, uart_rx_vector, uart_update.
- adc: adc_reference, adc_attenuation, adc_prescaler, adc_enable, adc_channel, adc_start, adc_busy, adc_done, adc_result,
  adc_digital_disable.
- routing: route_out, route_in, io_mux_func (inherent on the 328P; the C3 `setups` migrate here).

**Names** (econ's review, 2026-11-13):
- Generated macros are `HAL_<ROLE>_<OP>`. The role is the stable name the app speaks (LED, BUTTON), never the pin knob
  (led_pin).
- Several instances of one role: `<ROLE>` = the catom INSTANCE uppercased, defaulting to the role when there is one
  (HAL_LED_* now; HAL_LED1_* / HAL_STATUS_LED_* later).
- **The renderer refuses, in words,** any generated macro name equal to a RESERVED knob, a build-flag name of any seed or
  scenario variant, or a board_config.h #define.
- **Config-flag migration (its own phase, before the uart family lands):** the build/config flags that share the HAL_ prefix
  (HAL_INT0, HAL_INT1, HAL_WDT, HAL_WDT_PERIOD, HAL_UART_ERRCOUNT, HAL_MILLIS_ATOMIC, HAL_BUTTON_ROUTE, HAL_SENSE_ROUTE,
  HAL_INT0_DEBOUNCE_MS) move to a CFG_ / POLARI_ prefix in one migration. HAL_ then means generated macros only.

**Reserved (later):**
- periph_clock / periph_reset (328P PRR, with the inversion held in `values`);
- predicate yields {op, than} (C3 TXFIFO_CNT < 128; LiteX !txfull);
- sub-instance resources (LEDC channel + timer), allocated at build time like the CPU interrupt line;
- space `csr` + an `intrinsic` mechanism (global_irq_enable: sei / mstatus.MIE);
- a `call` mechanism (a cited ROM function); the ESP-IDF adc_oneshot isotope comes first.

## 4c. econ's sections: the C3 access evidence (3a), its ledger, and the chip-description plan (4)

(Written by econ 2026-11-13, sha256 10c64c44… on core; merged verbatim by pol.)

### §4b additions (econ): the access evidence, as 3a delivers it
- **Two sources, two jobs.** Espressif's SVD gives the STRUCTURE: registers, offsets, bit positions, resets. The TRM gives the
  ACCESS SEMANTICS: each field's code verbatim (R/W, RO, WT, WO, R/W/SC, R/SS/WTC, R/WTC/SS ...) and its sentence.
  ESP-IDF's soc/*_reg.h is the independent cross-check of the structure.
- **Acceptance rule (overlay v3).** A TRM code is accepted for a field only when the field NAME and the register header
  at that position in the text agree. A name-only match goes to a review queue, and choose() treats it as `missing`
  (fail closed). Reason: pdftotext prints two-register pages out of order (LEDC 32.9 / 32.10, p.840), so position
  alone borrowed codes from neighbouring fields.
- **Pages the text cannot carry** are read from the rendered page: LEDC_INT_* pp.840-841, the bit layout from the
  diagram. The row says so in page_table.
- **`trm_access`** (on every C3 field) is the code verbatim. hal-3b's access table maps from it, never from the lossy
  `access` word, which stays for existing consumers. Agreed mappings: R/SS/WTC and R/WTC/SS → `r-w1c`; WT → `w-strobe`;
  WO → `w` (plain store, never RMW; an _CLR role makes it a store of the mask); RO → `r`.
- **by_action** evidence rides in `values` with per-action keys, as the 328P's PINx rows already do. UART_FIFO
  RXFIFO_RD_BYTE: {'read': pop RX, 'write': push TX}, quoting TRM §26.4.2 pp.552-553 (trm_access 'RO'). The table
  maps it to `r-fifo-pop` / `w-fifo-push`, never RMW.
- **A field the TRM does not describe** (LEDC TIMERx_CONF.TICK_SEL: in the SVD and in ESP-IDF, 0 hits in TRM v1.4) gets
  a hand-built row: empty trm_access, notes "NO TRM access code", page_table citing SVD + ESP-IDF, values saying no
  meaning is given. choose() treats it as `missing`.
- **Values the TRM gives no code for** say so (TARGET0_TIMER_UNIT_SEL, ONETIME_ATTEN, CLK_SEL 2/3, LEDC APB_CLK_SEL 0).
  Nothing is filled in from memory or from another chip.
- **Name disagreements between sources** are resolved toward the TRM when ESP-IDF agrees with it, and the SVD's
  spelling is kept in notes (SAR ADC: TRM/IDF APB_SARADC_ADC1_DONE_INT_*, SVD APB_SARADC1_DONE_INT_*).
- **TRM slips** are quoted verbatim and flagged [sic] in notes (4 in UART 26.3-26.6).

### Ledger: 3a (econ/hal-c3-rows, on 06ad32a8; all approved by pol)
| commit | what |
|---|---|
| c604edb6 | board_hal_roles_selftest: base_roles == hal.c guards for 28 variants, 4 must-fail controls |
| dd3a54c4, c59d5581 | tools/selftest_sweep: derived sweep list (found 6 cmod suites never run), tokenize-exact |
| db0ac890 | LEDC rows (pwm) + `part` + `trm_access` on every C3 field; TICK_SEL rule |
| 26990e01 | SAR ADC1 one-shot, SYSTIMER COMP0 alarm, LEDC/APB_SARADC clock+reset bits, 3 INTMTX maps |
| 182cf18e | facts fixture + board_registers_c3_facts_selftest (SVD + IDF, field for field, 3 mutation controls) |
| 4c366517 | LEDC_INT_* (read from rendered pp.840-841) |
| f584ff0a | uart: FIFO by action (§26.4.2) + UART0_INT_* (20 events) |
C3 totals: 157 registers / 1062 fields (drawing set 91 / 761; hal-3a 66 / 301). Every hal-3a field is checked against
SVD be20aa12 + ESP-IDF v5.5.5 (the TSV pol ran: v2 sha 0069402c...). The tick needs nothing new: UNIT0_OP / VALUE_HI / LO
and TARGET0_CONF.PERIOD(_MODE) are present.
Independent sweep of the merged dev-hal-1: 385 suites; the one regression (hwnocode split record) was fixed by pol in 87ee6944.

### §4 plan: econ/hal-chipdesc (next)
1. **chipdesc format**: the chip description the generator reads: blocks, registers, fields (bits, reset, access
   code verbatim, sentence, cite), plus vector / access_style / clock facts per §4b. One format for vendor silicon and
   for our own RTL.
2. **SVD importer**: CMSIS-SVD → chipdesc structure (derivedFrom, dim/%s arrays, cluster, default resetValue), the
   access left at the SVD's coarse word and marked `svd` until an overlay supplies a cited code.
3. **Access overlay + merge**: the overlay v3 matcher as framework code (TRM text → cited codes, name+header
   acceptance, the review queue, per-chapter spelling aliases), merged onto the imported structure. Conflicts are
   reported, never silently resolved.
4. **Proof 1, ESP32-C3**: import the C3 SVD + overlay, then cross-check field for field against registers_esp32c3's hand
   rows (bits, resets, trm_access). Every difference is a finding in one of the two.
5. **Proof 2 / 3**: RP2350 Hazard3 side (vendor SVD) and a LiteX VexRiscv SoC (LiteX csr.csv / SVD export) with zero
   generator changes. Our own RTL goes SystemRDL → PeakRDL → SVD / IP-XACT into the same importer.

## 4d. The chip description (econ's §4 section, 2026-11-13; merged by pol with the R/W/SC decision)

(sha256 256a4b87… on core.)

### The format
A chip description is the row shape the generator already reads through hal.custom.soc_rules: REGISTERS + FIELDS, as
board.custom.registers_esp32c3 hand-writes them.
- REGISTERS: register, block, offset, reset, title, where (cite), undetermined (what is not ingested, in words), part.
- FIELDS: register, field, bit_hi / bit_lo / width, reset_value (a number, or words: 'undefined (resetMask)', 'undefined (no reset
  in the RDL)', 'per pad: Table ...'), description (the source's sentence), values (per value, or per action: {'read': ..,
  'write': ..}), page_table (cite), affects_pin / affects_signal, notes, part, plus the ACCESS FACTS below.
- Every source produces this one shape, so the generator never knows which source a chip came from.

### Access facts per source
| source | key on the field | meaning | produced by |
|---|---|---|---|
| a vendor manual (TRM) | `trm_access` = the code verbatim (R/W, RO, WT, WO, R/W/SC, R/SS/WTC, R/WTC/SS ...) | the manual's own word, cited to register + page | hand rows (3a) or board.custom.access_overlay (name AND register-header acceptance) |
| a vendor SVD | `svd_access` (coarse) + `svd_semantics` (modifiedWriteValues / readAction / writeConstraint, when emitted) | structure + whatever semantics the vendor emitted | board.custom.svd_import; access_overlay.from_svd maps it to a word where the SVD is the spec |
| our own RTL | `access_word` + `access_source` 'rdl' + `access_cite` (file, line, deciding properties) | the RDL's sw / onwrite / onread / singlepulse | board.custom.rdl_import |
| (SVD as the spec) | `access_word` + `access_source` 'svd' + `access_cite` | for an SVD-only chip with no manual | access_overlay.apply_svd |

**Precedence.** A cited manual code (trm_access) wins over an SVD word. The SVD keeps the STRUCTURE (bits, offsets, resets) unless a
cited source contradicts it, as with the C3 IO_MUX per-pad resets. Every contradiction is REPORTED (access_overlay.merge conflicts,
proof 1 / proof 2 reports), never resolved silently. For our own silicon, the RDL is the source and the SVD is only a cross-check.

### The access table (hal-3b reads one of the keys above, never the lossy `access` word)
| word | from a TRM code | from an SVD | from SystemRDL | choose() may |
|---|---|---|---|---|
| `rw` | R/W, R/W/SS | read-write, no semantics | sw = rw | read-modify-write (guarded where interruptible), read_value |
| `r` | RO | read-only | sw = r | read_value |
| `w` | WO | write-only | sw = w | plain store of the whole value / mask; never RMW |
| `w-strobe` | WT | NO FORM (no singlepulse in SVD) | sw = w + singlepulse | strobe (store 1; it self-clears) |
| `rw-sc` | R/W/SC | NO FORM | sw = rw + hwclr | read-modify-write (it is read-write), and `wait` may poll it until the hardware clears it (LEDC DUTY_START; the 328P's ADSC, "reads one while a conversion is in progress", §24.9.2 p.258) |
| `r-w1c` | R/SS/WTC, R/WTC/SS | read-write + modifiedWriteValues oneToClear | sw = rw + onwrite = woclr | wait (poll), clear (store the mask) |
| `r-fifo-pop` / `w-fifo-push` | RO + by-action values (UART_FIFO, §26.4.2) | none | none | read pops, write pushes; never RMW |
| (none) | review-queued, no code, absent from the manual | readAction / writeConstraint / other modifiedWriteValues | onread, woset / wot, singlepulse on a readable field | **missing**: fail closed, the reason said |
- `strobe` on a plain `w` stays refused: "self-clear not known from this source".
- R/W/SC: DECIDED by pol 2026-11-13 as its own word `rw-sc` (row above), not `rw`. The hardware clear is exactly the fact a `wait`
  needs ("poll until done"), and folding it into `rw` would lose it. choose() already accepts `rw-sc` for set / write /
  read_value / wait. The 328P's ADSC row moves to `rw-sc` with its cited sentence when the adc family lands.

### Evidence (all committed, all selftested)
- C3 hand rows: registers_esp32c3 (157 registers / 1062 fields; hal-3a 66 / 301). Facts fixture + selftest: SVD + ESP-IDF field
  for field.
- Proof 1: svd_import vs every hand row. hal-3a 301 / 301 exact. SVD defects found: IO_MUX per-pad resets and MCU_DRV absent.
- Proof 2: svd_import + access_overlay vs the hand trm_access. 0 different codes; 54 rendered-page fields, 4 TICK_SEL, and 3
  reported conflicts, all explained.
- Own RTL: toyperiph.rdl read by rdl_import (go w-strobe, done r-w1c); the hand SVD path agrees on everything SVD can say.

### Open (waits on the user: downloads / installs)
- RP2350 Hazard3 (pico-sdk's RP2350.svd) and a LiteX VexRiscv SoC (SVD export or csr.csv): proof chips with zero generator changes.
- PeakRDL: regenerate toyperiph.expected.svd with the real tool and diff it; check whether its IP-XACT export carries singlepulse
  / hwclr.

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

## 5a. The HAL tied to the isotope it is embedded in (hal-iso) + no-code option cards (hal-ui)

**The user, 2026-11-14:**
- On the direction: "we take the Firmware in no-code and we choose the isotope based on the hardware". The author picks the catom
  and its intent, and the hardware decides which isotopes are viable.
- On the tie: "the isotopes should be using the HAL and the HAL code should be set up to interact with the isotope it gets embedded
  into so that the isotope gets the data about what is needed from hardware to make it viable, this way they all tie together".
- On the UI: "no-code state UIs that match to Catoms more specifically based on HAL and Hardware detail requirements. Such as getting
  dropdowns for our different options for how to configure our interrupt for reading a button, and configuring whether we want
  it to be at 3.3V or 5V or if we do not care."

### hal-iso, BUILT 2026-11-14 (framework `dev-hal-3b`)

- **A need** = one (variable, operation) of an isotope's `requires` on one chip pin. The HAL answers each need with a record, not
  a yes/no (`hal.custom.needs`, rows `HalIsotopeNeed`, derived on every read):
  - **verdict:**
    - `fits`;
    - `chip-lacks`, a cited fact about the chip;
    - `not-recorded`, a gap in OUR tables, never presented as a chip fact (proved by a control that hides a rule);
    - `refused`.
  - **need_name:** the isotope's own word, `HAL_<ROLE>_<OP>`, with ROLE taken from the variable (`button_pin` → `BUTTON`). It is
    the same naming rule as the shared hal.c roles.
  - **settings:** register.field = value via mechanism, for every binding, with its cites.
  - **yields:** what the hardware told the generator, for example `signum = 0` and the vector `INT0_vect`.
- **The isotope's header** (`needs.header`) holds only its units, plus a role line per need name. It is refused, naming each unmet
  need and its verdict, when the chip cannot host the isotope. **Proof:** one isotope C source, written only against need names,
  compiles unchanged against the 328P header (avr-gcc -Wall -Werror) and the C3 header (host cc -std=c99 -Wall -Werror). On the
  328P, the level-low button arms INT0 (`sbi 0x1d,0`).
- **Level triggers:** `int.level_enable_low` / `int.level_enable_high`.
  - 328P: low = ISCn `00` (Table 13-2). High is `lacks`, cited: the table lists four settings and none is a high level.
  - C3: INT_TYPE 4 / 5.
  - A role rule may now carry `lacks: {value: cite}`. The generator answers `unsupported` with that cite, never "no value".
- **Doors:** `GET /api/hal/isotopes/{catom:isotope}/needs?soc=&pin=`. On /display/hal's Isotope fit tab, clicking a pin in a chip's
  fit table shows what that chip gives the isotope on that pin.
- **Selftests:** hal_needs_selftest 22/22; hal_selftest 114/114 (counts moved by +2 operations, reasons in the labels).
- **What the records already show:**
  - read-button:ext-interrupt fits PD2 on the UNO.
  - On the C3, every pin need fits, but the per-pin vector is `chip-lacks`: the interrupt matrix replaces per-pin vectors. A C3
    isotope must attach through ESP-IDF instead (econ's ledger row 3).
- **Open:**
  - `proof` stays `''` until a twin run sets it. The C3 pin twin (PIN_TWIN_PLAN.md) proves edge isotopes today. Level isotopes
    need the bare-C firmware stage (pt-5).
  - `gen.base_roles` still hard-codes hal.c's roles. Moving it onto `needs` is the next step, with the gate of 17/17 identical
    .hex files.

### hal-ui, PLAN ONLY: option cards per catom, every option derived from the HAL and the hardware

**The rule.** A dropdown never lists an option by hand. Its entries are the options whose needs all `fit` on the hardware in
scope: the Bench Solution's board and pin, or every candidate board when none is fixed yet. Options that are not viable are not
in the dropdown. They appear in a collapsed "not available here" list, each with its verdict and reason (chip-lacks plus the
cite, not-recorded, or refused), so a data gap is visible and never confused with a chip fact.

**Two kinds of option, both on the existing cfg rows** (ConfigOption / CatomConfiguration / ConfigChoice / ConfigOptionGrade,
CATOM_CONFIG_PLAN.md):

1. **Method options: how the catom does its job.** Each option is an isotope, or a choice inside one.
   - An isotope gains `choices`, for example read-button's `trigger`:

     | trigger | operation |
     |---|---|
     | `falling` | int.edge_enable_falling |
     | `rising` | int.edge_enable_rising |
     | `any_edge` | int.edge_enable |
     | `low_level` | int.level_enable_low |
     | `high_level` | int.level_enable_high |

     Each choice's operations join `requires`, so each choice has its own needs and verdict.
   - The dropdown "How the button is detected" then lists (isotope, choice) pairs:
     - "Interrupt on the falling edge";
     - "Interrupt while held low";
     - "Pin-change interrupt";
     - "Polled";
     - "Analog threshold".
   - Example: UNO D2 offers falling / rising / any / low; UNO D4 offers only pin-change, polled and analog; a C3 pad offers all five
     levels, once its ESP-IDF attach isotope exists.
   - A level choice carries its consequence in words: it re-asserts while held, so the isotope masks or clears it in the handler.
2. **Requirement options: hardware details the catom must meet**, such as the logic level: `3.3 V`, `5 V`, or `don't care`.
   - These are not isotope choices. They filter hardware, using the cited electrical rows already in board:
     - the board's logic level (`board_spec.logic_level`);
     - the pin's absolute maximum (328P `V_PIN` = VCC + 0.5 V);
     - VIH / VOH, through `electrical_check`.
   - `don't care` filters nothing.
   - On a fixed board the dropdown lists only what that board can meet. 5 V on a C3 is not offered as-is. A level shifter is
     offered as a `part`-level ConfigOption (the cfg-5 fix suggester) when the person needs 5 V.

**The card.** Each catom of a Firmware Solution gets one state card (a node kind beside `hal-variable`), with one dropdown per
option group.
- Choosing writes a ConfigChoice (`chosen_by person`, and `why` = what it gives up against the automatic choice). The value goes
  through `catom_variables.propose`, so the card is never a second copy of the data.
- The automatic choice is the best viable option.
- No raw JSON on the card. A second click deselects.

**Phases:**
- **ui-0:** isotope `choices`, needs per choice, and `GET /api/hal/isotopes/{key}/choices[?soc=&pin=]`. With no context it returns
  every option, plus a "known to work on" note. With a context it returns viable options plus the not-available list with
  reasons. Also the default policy rows and the automatic choice they derive.
- **ui-1:** requirement groups (logic level first) as ConfigOption rows, checked by `electrical_check` against board and pin, with
  the shifter as a part option.
- **ui-2:** the card on the catom configuration page, fed only by those two doors, plus its ConfigChoice write-back.
- **ui-3:** grades from twin runs. The C3 pin twin presses the button for each trigger choice, so "proved" is measured, not
  generated.

**The context decides the format (the user, 2026-11-14).** "We have two different kinds of Hardware no-code ... One which is a
generalized definition and one which is a Hardware specific definition." These are the System and Solution words already in use
(systems-vs-solutions): a System is a template with choices open; a Solution is bound to hardware. One card definition serves
both. The context passed in decides how it renders, so the same no-code works for many hardware sets.
- **No hardware context (a System, deliberately left undefined):** every option the catom's isotopes can offer is listed. None is
  hidden or greyed, because nothing is known to rule it out yet. Each option may carry an informational "known to work on"
  note (the chips whose needs fit), never a verdict.
- **Hardware context given (a Solution, or a System narrowed to a board family or a pin):** D-ui-1 applies. Only viable options
  are in the dropdown. The rest are listed beneath it with their verdict and reason.
- A context can be partial: board family only, board without pin, or pin chosen. The filter uses exactly what is known, so a
  family context shows the options that fit at least one member, each with its member list.

**Automated default selections (the user, same day: "We will also want to be capable of automating default selections").**
- A System carries a **default policy** per option group: an ordered preference list. For read-button's trigger:
  falling → any_edge → low_level → pin-change → polled. A requirement group defaults to "don't care" unless the System says
  otherwise.
- When a hardware context arrives, the first viable entry becomes the automatic ConfigChoice (`chosen_by auto`). Its `why`
  names the entries skipped and their verdicts, for example "falling: chip-lacks on PD4 (no INTn function)". The policy is
  data on the System, so changing it re-derives every Solution's automatic choice. Nothing is hand-copied.
- A person's choice overrides the automatic one and keeps its `why`. If a later context makes it non-viable (a board swap), it
  is not silently replaced: the card marks it invalid with the verdict, shows the automatic choice beside it, and the person
  keeps or switches. This matches cfg's "a person's choice turned invalid is worked out on read".
- Twin grades (ui-3) can reorder within the policy's ties, never past an explicit preference.

**Decisions:**
- **D-ui-1: RESOLVED (the user, 2026-11-14):** hide non-viable options and list their reasons beneath, but ONLY when a hardware
  context is given. With no context, all options are shown and formatted once a context is passed in.
- **D-ui-2: RESOLVED yes (the user, 2026-11-14):** a requirement the fixed board cannot meet (5 V on a C3) offers a part, such
  as a level shifter, as a `part`-level ConfigOption, instead of only refusing.

## 6. Decisions for the user

1. **D-hal-1, the licence of generated firmware projects.** I recommend GPL-3.0-or-later. That keeps every borrowed source
   above compatible without per-project checks.
2. **D-hal-2, RIOT (LGPL-2.1-only).** I recommend using its API shape only, no code, unless a licence-gate review clears it.
3. **D-hal-3, the order.** I recommend hal-0..2 on the UNO, then the C3 (hal-3), then Pico 2 (hal-4). Electronics proving
   stays first, and hal-0..2 are no-behaviour-change refactors that make it easier.
4. **D-hal-4, where catoms live.** I recommend moving `uno/catoms/` up to `firmware/catoms/`, since an isotope is no longer
   tied to one board.
