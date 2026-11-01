# Clock configuration plan (clk): clocked catoms, oscillator data as a knob, compromise options

**Branch:** remote `dev-electronics` (electronics work never goes to `dev`).
**Started:** 2026-11-01. **Status: PLAN ONLY.** D-clk-1..6 are the user's to decide.
**Builds on:** tmp-4 / tmp-6 (TEMPERATURE_PLAN.md: `board.custom.timing_drift`, `uart_sampling`, `clock_skew_run`), hsp-3c-hal / hsp-3d
(HARDWARE_SYSTEM_PINS_PLAN.md: `CatomVariable`, `HalVariableState`, `catom_variables.propose`), the catoms and their isotopes
(`board/custom/firmware/uno/catoms/*`, `cmod.custom.isotope_variants`).

## The ask, in the user's words

> "I would say we need to make the similator capable of accounting for this and possibly incorporate in oscillator data from data sheets as a
> variable we want to be able to pass into firmware and adjust for. We need to ensure that our signals work, and document different kinds of
> compromise options are we can choose and what trade offs we have if we choose them. Maybe make a particular kind of state specifcally for when
> we are configuring oscillator based Catoms with adjustable knobs inside it for different options to try. This way we can also adjust them in
> the simulator to explore what options within reason give use what results"

> "we want the simulation to be able to catch options that are just completely invalid, as well as give the option to do compromises with
> options and details on those compromise options while autoselecting "most ideal options" by default"

"This" = the 5.9 % mismatch tmp-6 found: the `USART_U2X 0` build (111 111 Bd) cannot talk to the UNO's 16U2 (117 647 Bd).

## Three verdicts and the default (the user's second message)

Every option, for every clocked catom, gets exactly one of three verdicts from the checks and the simulator:

- **invalid:** it cannot work, whatever else is chosen, and the simulation shows it, for example a link outside the receiver's window at
  nominal, an ADC clock outside 50 to 200 kHz, or a baud the divisor cannot reach within the window. An invalid option is never selected by
  default and is refused at build time (gen). It stays visible, greyed, with the reason and the evidence (the run's corners, the band against
  the window), so a person can see why it is out.
- **compromise:** it works, but it gives something up. Examples: a margin below the datasheet's recommended share, works only with a matched
  peer, less throughput, a hardware change, a calibration step, or a tick that is no longer exact. It can be chosen. Its details are always
  shown: what it gives up, by how much (a number, never just a word), its cost (bytes, cycles, parts, steps), and how it scored in the
  simulator.
- **ideal:** it meets every check with the full recommended margin and no cost beyond the baseline. Not every catom has one.

**The default is chosen automatically:** the best-scoring option that is not invalid, with ideal options ranked above compromises. The ranking
is competitive scoring over the valid set (the best = 100, the worst = 0), with the weights as knobs. The card says "chosen automatically" and
why: its score and what beat what. When a person picks something else, the card records it as their choice, with what it gives up compared with
the automatic one. A choice that turns invalid later (for example after another knob, the temperature range or the far end changes) is flagged,
and the automatic choice is offered again.

The checks are layered, cheapest first, so invalid options are caught fast:
1. **closed form:** the divisor error and the clock band against the receiver's window (`clock_skew_run.limits`) at the worst phase. This
   alone catches the 5.9 % case.
2. **derived ranges:** the ADC clock, PWM frequency and tick period from the registers and the datasheet formulas.
3. **simulator runs:** the twin at the band's corners, which confirms or refutes the closed form, and catches what a formula cannot (the
   firmware's own behaviour, such as whether the command took effect).

## What exists already (reuse, do not duplicate)

| Piece | Where | Use here |
|---|---|---|
| Cited clock bands (resonator, 328P RC) | `board.custom.timing_drift.CLOCKS` (a dict) | becomes seeded `ClockSource` rows (clk-0) |
| Bit-level AVR receiver, its window | `board.custom.uart_sampling` | the judge of every serial option |
| Skew forced into a twin run | `board.custom.clock_skew_run` | generalised to take a clock configuration (clk-3) |
| F_CPU as a catom variable (`clock.hz`) | `cmod.custom.catom_variables` | gains the other clock roles (clk-1) |
| One-value HAL card | `HalVariableState` (node kind `hal-variable`) | the pattern for the new state kind |
| Alternative implementations of a catom | catom isotopes (`read-button`: int0 / pin-change / analog) | compromise options that change code become isotopes |
| Variant knobs -> board_config.h | `FirmwareVariant.knobs_json`, `gen` (`usart_u2x` today) | where a chosen option lands in the firmware |

## The words

- **Clock source:** the thing that makes the chip's clock: a ceramic resonator, a crystal, the internal RC oscillator, an external oscillator. Its
  datasheet gives a nominal frequency and bounds: initial tolerance, a band over a temperature range, aging. Bounds are used as bounds, never
  drawn as curves (the tmp-4 rule).
- **Clocked catom:** a catom whose correctness depends on the clock. Each one declares which knobs it reads, the datasheet formula that turns
  the clock into its timing, and the check that says "this still works".
  - **serial-link** (UART): both directions decode at the bit level across the band, against a named far end;
  - **tick** (the 1 ms Timer2 compare): its period error (ppm), and so every firmware timeout;
  - **pwm** (Timer0 / Timer1): the output frequency against what the load needs;
  - **adc-clock** (the ADC prescaler): the ATmega328P wants 50 to 200 kHz for full 10-bit resolution;
  - **debounce** (counted in ticks): the window in true time;
  - **watchdog** (its own 128 kHz oscillator, a separate cited band).
- **Far end (peer):** the other clock on a link: the UNO's 16U2 as arduino-usbserial sets it, an "exact" reference, a USB-serial adapter by its
  own datasheet, or another of our boards.
- **Compromise option:** one way to make a clocked catom work, with what it changes and what it costs. Some change knobs only; some change code
  (those are isotopes); some change hardware (another clock source).

## The new state kind: `ClockConfigState` (D-clk-2)

One card per firmware variant on a board, node kind `clock-config`, category **HAL**, beside the `HalVariableState` cards in the HAL drawing.
The same rule as `HalVariableState`: only the knobs are typed; everything else on the card is worked out, and a knob is written through
`catom_variables.propose` into the variant's knob, so the drawing is never a second copy.

**Knobs (typed, each with a range "within reason"):**
- clock source (a `ClockSource` row) and F_CPU; CKDIV8 on / off;
- per clocked catom: baud, U2X, a UBRR override, stop bits sent; the tick's prescaler and compare value; the PWM prescaler / TOP; the ADC
  prescaler; the debounce in ticks;
- the far end (a peer row) and its clock error;
- conditions: the temperature range to cover, years of aging, and the sampling phase (or "worst phase").

**Worked out (never typed):**
- each catom's achieved value and its error (baud error %, tick ppm, PWM Hz, ADC kHz, debounce ms);
- the clock band at the conditions, from the source's datasheet;
- for serial: the band in which both directions decode (`clock_skew_run.limits`) and the margin left;
- the verdict per catom (works / works with a warning / broken) with its basis, and the newest simulator run's corners.

## Compromise options and their trade-offs (the catalogue, D-clk-4)

A code-owned, cited catalogue (`ClockCompromise` rows): what each option changes, what it costs, and when it is the right one. The simulator
scores each against the same check (competitive scoring: the best of the compared set = 100, the worst = 0).

| Option | What changes | What it costs | Note |
|---|---|---|---|
| Matched divisor (U2X, UBRR 16, as Arduino does) | knob | works only with a peer that uses the same divisor; about +-2.5 % margin against the 16U2 | today's shipped build |
| Normal mode (16 samples, UBRR 8) | knob | -3.5 % divisor error: broken against the 16U2 at 115200 | wider receiver window, worse divisor |
| Lower baud (57600 / 38400 / 9600) | knob | throughput: worked out against the telemetry load (bytes per frame x frames per second) | 9600 = 0.2 % error |
| Two stop bits sent | knob | about 9 % less throughput | removes the "next start too early" failure for a fast sender (the model has frame_bits) |
| Crystal instead of the resonator | hardware | board change, part cost, longer start-up (CKSEL / SUT fuses) | tens of ppm instead of +-1 %; the crystal datasheet is cited at build time |
| Baud-friendly crystal (14.7456 or 18.432 MHz) | hardware + F_CPU | 0 % divisor error at standard bauds, but the 1 ms tick is no longer exact; rebuild; the Arduino core assumes 16 MHz | the tick catom's check shows the cost |
| Internal RC + OSCCAL user calibration | hardware (one part fewer) + a calibration step | +-1 % after calibration (Table 29-9), +-10 % before: broken as shipped | an isotope with the calibration routine |
| Runtime calibration against the far end (autobaud / a sync byte) | code (isotope) | firmware size and cycles (measured), a sync protocol | follows the peer's clock whatever it is |

Each row carries: the knobs it sets, the isotope (if code), the parts (if hardware), its cost by the resource-cost rule (bytes, cycles, BOM,
steps), and its cited source.

## The simulator (what changes)

- **Clock as a run input everywhere:** `clock_skew_run` takes a `ClockConfigState` (or its knobs) instead of fixed corners. A sweep covers
  temperatures x band corners x options, at the worst sampling phase (the closed-form limits) and at chosen phases (the runs).
- **The far end as a row:** the 16U2 as arduino-usbserial sets it (built in tmp-6), "exact", and a USB-serial adapter by its datasheet.
- **Two stop bits** and other frame shapes on the sending side (`uart_sampling` already takes `frame_bits`).
- **Framing errors reach the firmware (D-clk-3):** a twin flag so an injected byte can carry FE (`twin_scenario_io.c`; simavr has
  `UART_INPUT_FE`, the BER path already uses it). Then a `HAL_UART_ERRCOUNT` build counts them. This needs a C change and a rebuild of the
  local `prf-board-engines` image.
- **A scenario step:** `clock-skew` becomes forcible in the step runner, so a scenario pair can carry it (owed from tmp-6).
- **The other clocked catoms' checks:** tick ppm (measured, as tmp-6 does), PWM frequency and ADC clock (derived from the registers the twin
  reports), debounce in true time.
- **Live Bench sessions:** the same boundary in a twin session on the Bench (the TCP twin), so a person can turn a knob and watch a link break.
  This comes last.

## Phases

| Phase | What | Proof |
|---|---|---|
| clk-0 | `ClockSource` rows (seeded, cited: the CSTCE16M0V53-R0, the 328P RC factory / user-calibrated, the 128 kHz watchdog oscillator; one cited 16 MHz crystal and one 14.7456 MHz crystal); peer rows (16U2 / arduino-usbserial, exact); `timing_drift` reads the rows | tmp-4's tables unchanged from the rows |
| clk-1 | clocked catoms: a `serial-link` catom.json and a `tick` catom.json with a `clock_dependence` block (knobs, formula, check); new `CatomVariable` roles (`uart.baud`, `uart.u2x`, `clock.source`, `timer.prescaler`, `adc.prescaler`); `ClockConfigState` class + derivation | the UNO's shipped card says: 117 647 Bd, +2.1 %, the 16U2 matched, margin -2.50 .. +2.56 % against a +-1.0 % band, works; the U2X 0 card says broken, with the 5.9 % |
| clk-2 | the `ClockCompromise` catalogue; each option given its verdict (invalid / compromise / ideal) by the layered checks, scored, and the default chosen automatically, with its evidence (knobs-and-suggestions); a person's other choice is recorded with what it gives up | for the UNO at 115200: normal mode is invalid (the 5.9 %); the matched divisor is chosen automatically as a compromise (it works only with a matched peer, and its margin is below the recommended share against an exact peer); 9600 is invalid for the telemetry load |
| clk-3 | the simulator: sweep by state, far-end rows, stop bits, the FE twin flag (D-clk-3), `clock-skew` as a scenario step | a HAL_UART_ERRCOUNT build counts the FEs tmp-6 saw (236 at nominal); a scenario pair with a skew step |
| clk-4 | the other clocked catoms' checks: PWM, ADC clock, debounce, watchdog | each verdict cites its datasheet formula |
| clk-5 | the page: the `ClockConfigState` card in the HAL drawing (/display/bench-views HAL tab), its knobs as edit fields, the options table with scores, the corners of the newest run; a link from Board Details -> Timing | Chrome pass (needs a deploy - the user's call) |
| clk-6 | the firmware follows the choice: gen takes baud / U2X / F_CPU / stop bits and computes the divisor with the datasheet equation, refusing a build whose serial check fails against its far end (D-clk-5); the OSCCAL and autobaud isotopes | `pol board gen --u2x 0` at 115200 for the UNO's USB link is refused with the reason |

## Decisions (the user's)

- **D-clk-1: where `ClockSource` rows live.** Recommend `board` (beside `timing_drift`, where the cited bands are today). The alternative is
  electrodevice (with the other parts).
- **D-clk-2: the state.** Recommend a new class `ClockConfigState` (one card holding a group of knobs and worked-out verdicts). The alternative
  is more `HalVariableState` cards, one per knob, which loses the "this group works together" view.
- **D-clk-3: the FE twin flag** needs a C change and a rebuild of the local `prf-board-engines` image (a local build, not a deploy). Yes / no.
- **D-clk-4: which compromise options first.** Recommend: matched divisor, normal mode, lower baud, two stop bits, crystal, baud-friendly crystal,
  RC + OSCCAL. Autobaud later (it needs a sync protocol).
- **D-clk-5: the `USART_U2X 0` knob.** Recommend: keep it, but refuse a build at 115200 whose far end is the UNO's 16U2, with the reason (it is
  fine against a peer that matches it, or at 9600). The alternatives: retire it, or keep it with a warning only.
- **D-clk-6: the word.** Recommend "clocked catom" for a catom whose correctness depends on the clock (the user said "oscillator based Catoms").
