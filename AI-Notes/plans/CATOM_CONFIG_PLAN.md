# Catom configuration plan (cfg): configurations per Bench solution, graded options, and remedies when the chip cannot

**Branch:** remote `dev-electronics` (electronics work never goes to `dev`).
**Started:** 2026-11-01 as CLOCK_CONFIG_PLAN (clk); widened the same day to catom configurations of every kind. **Status: PLAN ONLY.**
D-cfg-1..8 are the user's to decide.
**Builds on:** tmp-4 / tmp-6 (TEMPERATURE_PLAN.md: `timing_drift`, `uart_sampling`, `clock_skew_run`), hsp-3c-hal / hsp-3d
(HARDWARE_SYSTEM_PINS_PLAN.md: `CatomVariable`, `HalVariableState`, `catom_variables.propose`), the catoms' `hal_contract` families
(drive / signal / protocol / register / execution), catom isotopes, bob-0..5 (BENCH_BOARDS_PLAN.md: footholds, `BenchConnection`, bench
findings, `board_spec`), drv-2/3 (DRIVERS_AND_ESD_PLAN.md: `part_fixes.suggestions`), ipb (INTERRUPT_POLL_BUDGET_PLAN.md).

## The ask, in the user's words

> "I would say we need to make the similator capable of accounting for this and possibly incorporate in oscillator data from data sheets as a
> variable we want to be able to pass into firmware and adjust for. We need to ensure that our signals work, and document different kinds of
> compromise options are we can choose and what trade offs we have if we choose them. Maybe make a particular kind of state specifcally for when
> we are configuring oscillator based Catoms with adjustable knobs inside it for different options to try. This way we can also adjust them in
> the simulator to explore what options within reason give use what results"

> "we want the simulation to be able to catch options that are just completely invalid, as well as give the option to do compromises with
> options and details on those compromise options while autoselecting "most ideal options" by default"

> "I think we need to look for other features where we may need things similar to this. Also, how would we suggest replacements for making
> timing work if a chip fundamentally cannot manage it? Planting boards or Module Boards (modules from third parties) with external
> oscillators that can work with the chip to "make it work"? If that is a thing? And rather than making a specific clocked Catom, I would
> rather just start making Catom configurations a thing, where the Catom configuration are specific to a Bench solution. Clocks make sense as
> well, but also perhaps, signal configurations, or think of other things?"

The trigger was the 5.9 % mismatch tmp-6 found: the `USART_U2X 0` build (111 111 Bd) cannot talk to the UNO's 16U2 (117 647 Bd).

## The shift: no "clocked catom"; a catom gets configurations, per Bench solution

A catom stays what it is: code with an interface, a `hal_contract` and isotopes. What changes is that **how a catom is set up for one Bench
solution** becomes a row of its own: a **catom configuration**. The same `read-button` catom can be configured one way on an UNO alone and
another way on an UNO wired to a 3.3 V board; the catom does not change, its configuration does.

- **Bench solution:** one solution (a `HardwareSolution` and its firmware variant) set up on one Bench: these boards, these connections,
  these conditions (temperature range, supply). D-cfg-1 decides its home.
- **Catom configuration:** for one catom in one Bench solution, and one **configuration kind** (clock, signal, ...): the typed knobs, the
  worked-out values, the verdict of every option, which option is chosen and whether it was chosen automatically or by a person.
- **Configuration kind:** a catalogue entry saying which knobs a kind has, how its values are worked out (the datasheet formulas), and which
  checks judge it. Kinds line up with the `hal_contract` families the catoms already declare, plus clock and power (D-cfg-2).

Clock is the first kind built, because the evidence and the solvers are there (tmp-6). The machinery is the same for every kind.

## Three verdicts and the default (the same for every kind)

- **invalid:** cannot work whatever else is chosen, and the checks show it. Never selected by default; refused at build time (gen); shown
  greyed, with the reason and the evidence.
- **compromise:** works, but gives something up: margin below the recommended share, a matched peer required, throughput, a part, a
  calibration step, a rework. Can be chosen. What it gives up is always a number, with its cost (bytes, cycles, parts, steps) and its score.
- **ideal:** every check with the full recommended margin, no cost beyond the baseline. Not every configuration has one.

**The default is chosen automatically:** the best-scoring option that is not invalid, ideal above compromise, by competitive scoring over the
valid set (best = 100, worst = 0; weights are knobs). The card says "chosen automatically" and why. A person's other choice is recorded with
what it gives up against the automatic one. A choice that turns invalid later (a knob, the conditions, a board on the bench changes) is flagged
and the automatic choice offered again.

**Checks are layered, cheapest first:** (1) closed form (formulas against cited limits; catches the 5.9 % alone), (2) derived ranges from the
registers and the conditions, (3) simulator runs at the corners (the twin, SPICE, the thermal FEM, whichever the kind uses), which confirm the
formulas and catch what a formula cannot.

## Which features need configurations (the survey the user asked for)

Each row is a place where today the codebase has a fixed setting, a finding, or a hard-coded table, and where a choice with invalid /
compromise / ideal options exists.

| Kind | What is configured | Typical invalid | Typical compromise | Exists today (fold in, do not duplicate) |
|---|---|---|---|---|
| **clock** | clock source, F_CPU, prescalers; serial baud / U2X / divisor; tick; PWM frequency; ADC clock; watchdog | U2X0 at 115200 against the 16U2 (5.9 %); ADC clock outside 50 to 200 kHz | matched divisor (works only with a matched peer); lower baud (throughput); a crystal (a part) | `timing_drift.CLOCKS`, `uart_sampling`, `clock_skew_run`, the `usart_u2x` knob, `clock.hz` |
| **signal** | logic levels across boards (5 V UNO against the 3.3 V Feather M0 / ESP32-S3 on the bench), input thresholds, bus speed against bus capacitance and pull-ups (I2C rise time), SPI clock against the slowest device | a 5 V output into a pin that is not 5 V tolerant; an I2C rise time over the mode's limit | a 3.3 V high read by a 5 V input with thin margin; a slower bus mode; a level shifter (a part) | bob-2 bench findings (over-voltage), `BenchConnection` signal data, the "FT -> 5 V, TTA -> 3.3 V" note in hsp |
| **drive** | pin current, series resistors, the load, port and whole-part totals, gate drive | a pin past its absolute maximum | within absolute max but over the recommended current; a driver part | drv-2/3: drive findings, `part_fixes.suggestions`, whole-part budgets |
| **analog** | ADC reference (AVCC / internal 1.1 V / AREF), prescaler, source impedance, thresholds (the analog `read-button` isotope) | a signal above the chosen reference; a source impedance far over the datasheet's recommendation | lower resolution at a faster ADC clock; a buffer (a part) | the analog-threshold isotope, `button_detect_registers` |
| **timing (execution)** | debounce window, ISR versus poll, the loop period, event rates against latency | an event rate above what the chosen path can service | polling with a worse latency; a longer debounce | ipb (interrupt / poll budget), `press_flag`, `debounce_ms` |
| **power** | supply rail, regulator, brown-out level against the supply, sleep modes | a load over the regulator's output; a brown-out level above the rail | a bigger regulator (a part); a lower clock at a lower voltage | drv-2 regulator suggestions, the UNO's USB budget |
| **thermal** | the temperature range to cover, derating | a part outside its rated range | derated current; a clock band only cited to a narrower range | tmp-1..6 (temperature as a condition every other kind reads) |
| **memory** | flash and RAM against the isotopes and options chosen | an option set that does not fit | a smaller isotope with fewer features | firmware sizes from gen (resource-cost rule) |
| **rf** | band, power, duty cycle against the region | a transmission `tx_permitted()` refuses | a lower power or duty cycle | the no-TX-without-legality rule |

Thermal is a condition more than a configuration: every kind reads the temperature range from the Bench solution. Recommended first: clock,
then signal, then drive and analog (D-cfg-3).

## When the chip cannot do it: the remedy ladder

When every option inside the chip is invalid (or only poor compromises are left), the configuration offers **remedies**, cheapest first. A
remedy is graded with the same three verdicts, by the same checks, after it is applied in the simulator.

1. **knob:** a different setting (baud, U2X, a prescaler, a slower bus mode).
2. **code:** another isotope (a calibration routine, autobaud, polling instead of an interrupt).
3. **part on the board:** a part added or swapped on a board already on the bench (a crystal for the resonator, a pull-up, a series
   resistor). Today's `part_fixes` catalogue is this rung for drive.
4. **module board:** a third-party board planted on the bench and wired in through footholds. It is a board like any other (bob-5:
   `board_spec`, new boards are data), and it adds a **provides** block: what it gives the bench (a clock at a frequency and stability on a
   pin, level translation between two voltages on N channels, a UART with its own crystal, a regulated rail).
5. **another board or chip:** the Mission search's inventory step, when nothing on the bench can be made to work.

**Yes, module boards with their own oscillators are a real thing.** Candidates for the clock kind (each is cited from its datasheet before it
is seeded, so no number here is final):

- **An external clock into the chip:** the ATmega328P accepts an external clock on XTAL1 (the "external clock" CKSEL setting). A canned
  oscillator, or a programmable clock-generator breakout such as one built on the Si5351, can feed it. The catch on an UNO: XTAL1 is wired to
  the resonator and is not on a header, so the footholds check says "needs rework" (a compromise with a rework step). On a bare 328P on a
  breadboard it is a clean option.
- **A UART that has its own clock:** an I2C or SPI to UART bridge breakout (for example one built on the SC16IS750, with a baud-friendly
  14.7456 MHz crystal). The serial link then depends on the bridge's crystal, not the chip's resonator. It costs pins, a driver isotope and
  bus traffic.
- **A USB-serial adapter with an accurate clock** in place of the UNO's 16U2. On an UNO the 16U2 shares D0 / D1, so the check must also see
  that conflict.
- **A temperature-compensated real-time clock breakout** (such as one built on the DS3231) for timekeeping. It fixes long-term time, not the
  baud rate, and the plan says so on the card.

The same ladder serves the other kinds. Signal: level-shifter breakouts. Drive: driver and MOSFET boards. Power: regulator or buck modules.
Each is a module board with a `provides` block, and each fix is proven by re-running the same checks with the module board on the bench.

## The rows (one object per concern, small)

| Row | Fields (short) | Notes |
|---|---|---|
| `BenchSolution` (D-cfg-1) | name, bench, hardware_solution, firmware_variant, conditions (temperature range, supply, aging years) | the scope of every configuration |
| `ConfigKind` | name, hal_family, knobs, derived fields, checks, simulator | code-owned catalogue: clock, signal, drive, analog, timing, power, memory, rf |
| `CatomConfiguration` | bench_solution, catom, kind, knobs_json, derived_json, chosen_option, chosen_by (auto / person), why, flagged | one per (bench solution, catom, kind); knobs written through `catom_variables.propose` |
| `ConfigOption` | kind, name, rung (knob / code / part / module-board / board), sets, isotope, parts, module_board, costs, source | the compromise and remedy catalogue (the clock rows are the clk table below) |
| `ConfigVerdict` | configuration, option, verdict, margin, gives_up, score, evidence (run ids, corners) | written by the checks, never typed |
| `ClockSource` | name, kind, nominal, tolerance, band and temperature range, aging, source | the first kind's cited data (clk-0) |
| module board `provides` | in `board_spec` | what a module board gives the bench, for remedies |

**The card:** one state node kind, `catom-config` (`CatomConfigState`), category HAL, in the HAL drawing beside the `HalVariableState`
cards (D-cfg-4). One card per catom per Bench solution, with a section per kind: the knobs as edit fields, the options with their verdicts and
scores, the chosen one and why, and the remedies when nothing inside the chip works.

## The clock kind in detail (carried from clk)

- **Clock source:** the thing that makes the chip's clock (resonator, crystal, internal RC, external oscillator). Datasheet bounds, used as
  bounds, never drawn as curves (the tmp-4 rule).
- **Knobs:** clock source and F_CPU, CKDIV8; baud, U2X, a UBRR override, stop bits; the tick's prescaler and compare value; PWM prescaler /
  TOP; ADC prescaler; the far end (peer) and its clock error; the sampling phase or "worst phase".
- **Worked out:** each value and its error (baud %, tick ppm, PWM Hz, ADC kHz); the clock band at the conditions; for serial the band in which
  both directions decode (`clock_skew_run.limits`) and the margin left.
- **Peer rows:** the 16U2 as arduino-usbserial sets it (built in tmp-6), "exact", a USB-serial adapter by its datasheet, another of our boards.

| Option | Rung | What it costs | Note |
|---|---|---|---|
| Matched divisor (U2X, UBRR 16, as Arduino does) | knob | works only with a peer that uses the same divisor; about +-2.5 % margin against the 16U2 | today's shipped build |
| Normal mode (16 samples, UBRR 8) | knob | -3.5 % divisor error: invalid against the 16U2 at 115200 | wider window, worse divisor |
| Lower baud (57600 / 38400 / 9600) | knob | throughput, worked out against the telemetry load | 9600 = 0.2 % error |
| Two stop bits sent | knob | about 9 % less throughput | removes the fast-sender failure |
| RC + OSCCAL user calibration | code (isotope) + part removed | +-1 % after calibration, +-10 % before | a calibration routine |
| Autobaud / a sync byte | code (isotope) | firmware size and cycles, a sync protocol | follows the peer's clock |
| Crystal instead of the resonator | part | rework on an UNO, part cost, longer start-up (fuses) | tens of ppm |
| Baud-friendly crystal (14.7456 / 18.432 MHz) | part + F_CPU | the 1 ms tick no longer exact; the Arduino core assumes 16 MHz | the tick check shows the cost |
| External oscillator / clock generator into XTAL1 | module board | a fuse change; rework on an UNO (XTAL1 not on a header) | clean on a breadboard 328P |
| UART bridge with its own crystal | module board | pins, a driver isotope, bus traffic | the link no longer depends on the resonator |

**Simulator changes for clock:** `clock_skew_run` takes a configuration instead of fixed corners; far-end rows; frame shapes (stop bits);
framing errors reach the firmware through a twin flag (D-cfg-6: a C change in `twin_scenario_io.c` and a rebuild of the local
`prf-board-engines` image, not a deploy), counted by a `HAL_UART_ERRCOUNT` build; `clock-skew` forcible as a scenario step; live Bench
sessions last.

## Phases

| Phase | What | Proof |
|---|---|---|
| cfg-0 | the shape: `BenchSolution`, `ConfigKind`, `CatomConfiguration`, `ConfigOption`, `ConfigVerdict`; the verdict engine (layered checks, the automatic default, a person's choice recorded) with no kind wired yet | a toy kind with one invalid, one compromise, one ideal option: the ideal is chosen; the override is recorded with what it gives up |
| cfg-1 | clock kind, part 1: `ClockSource` and peer rows (cited); `timing_drift` reads them; the serial-link and tick checks from tmp-6 code | the UNO's shipped configuration: 117 647 Bd, +2.1 %, the 16U2 matched, margin -2.50 .. +2.56 % against a +-1.0 % band, compromise, chosen automatically; U2X0 invalid with the 5.9 % |
| cfg-2 | clock kind, part 2: the option catalogue graded; the simulator by configuration; the FE twin flag (D-cfg-6); `clock-skew` as a scenario step | a HAL_UART_ERRCOUNT build counts the 236 FEs tmp-6 saw; 9600 invalid for the telemetry load |
| cfg-3 | the remedy ladder and module boards: `provides` in `board_spec`; two cited clock module boards and one UART bridge; the footholds reachability check (XTAL1 not on the UNO's headers); `part_fixes` becomes the drive kind's part rung | the UNO's remedy list shows the external-clock module as "compromise, needs rework" and the UART bridge as a clean option, each proven by a re-run with the module on the bench |
| cfg-4 | signal kind: levels across bench boards from footholds, I2C rise time from bus capacitance and pull-ups; level-shifter module boards | the UNO wired to the Feather M0: a 5 V output into its pin is invalid; a level-shifter board makes it valid |
| cfg-5 | drive and analog kinds, reading drv-2/3 and the analog isotope | each verdict cites its datasheet formula |
| cfg-6 | timing, power, memory (and rf when an RF catom exists) | each verdict cites its formula or measurement |
| cfg-7 | the page: the `CatomConfigState` card in the HAL drawing, options and remedies with scores, the newest run's corners; links from Board Details | Chrome pass (needs a deploy, the user's call) |
| cfg-8 | the firmware follows the choice: gen reads the chosen configuration (baud, U2X, F_CPU, stop bits, divisor by the datasheet equation) and refuses a configuration that is invalid | `pol board gen --u2x 0` at 115200 for the UNO's USB link is refused with the reason |

## Decisions (the user's)

- **D-cfg-1: where "Bench solution" lives.** Recommend a small new `BenchSolution` row (bench + hardware solution + firmware variant +
  conditions), since `HardwareSolution` is already large. The alternative: a `bench` field and conditions on `HardwareSolution`.
- **D-cfg-2: the kinds.** Recommend the list above, lined up with the catoms' `hal_contract` families plus clock, power, memory and rf, with
  thermal as a condition every kind reads.
- **D-cfg-3: the order.** Recommend clock, then the remedy ladder, then signal, then drive and analog, then the rest.
- **D-cfg-4: the card.** Recommend one `CatomConfigState` per catom per Bench solution with a section per kind. The alternative: one card per
  (catom, kind).
- **D-cfg-5: module boards.** Recommend module boards as ordinary boards (`board_spec` data) with a `provides` block, not a separate class.
- **D-cfg-6: the FE twin flag** needs a C change and a rebuild of the local `prf-board-engines` image (a local build, not a deploy). Yes / no.
- **D-cfg-7: the `USART_U2X 0` knob.** Recommend: keep it, but the clock check marks it invalid at 115200 against the UNO's 16U2, and gen
  refuses it there with the reason (it is fine against a matched peer, or at 9600).
- **D-cfg-8: the words.** "catom configuration", "configuration kind", "Bench solution", "remedy", "module board". ("Clocked catom" is
  dropped, per the user.)
