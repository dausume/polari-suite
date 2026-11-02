# Catom configuration plan (cfg): configurations per Bench solution, graded options, and remedies when the chip cannot

**Branch:** remote `dev-electronics` (electronics work never goes to `dev`).
**Started:** 2026-11-01 as CLOCK_CONFIG_PLAN (clk); widened the same day to catom configurations of every variable group. **Status: PLAN ONLY.**
D-cfg-1 decided by the user (Systems and Solutions); D-cfg-2..9 go with the recommendations (the user: "Go ahead and start", 2026-11-01).
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

> (2026-11-01, later) "Bench Solutions should already exist, that is just the complete combination of everything on a bench with specific
> configured firmware that is able to be run as a simulation? Or were we calling that something else? The fix ladder should be an assistive
> suggestion tool, and the configurations should be on the Catom pages, so we can configure them on a per firmware solution basis. We should be
> able to step through firmware with a Bench Solution context tied to it to be able to change configurations"

## The shift: no "clocked catom"; a catom gets configurations, per firmware solution, judged in a Bench Solution

A catom stays what it is: code with an interface, a `hal_contract` and isotopes. What changes is that **how a catom is set up in one firmware
solution** becomes a row of its own: a **catom configuration**, edited on the **catom's page**. Whether that configuration works is judged
in a **Bench Solution**: the same configuration can be ideal on an UNO alone and invalid on an UNO wired to a 3.3 V board.

- **Bench Solution:** the complete combination of everything on a bench, bound as a whole and simulated as a whole. It references a
  **Hardware Solution**, a **Firmware Solution** and a **Thermal Solution**, plus the bench's conditions. See "Systems and Solutions" below
  (the user's rule, 2026-11-01).
- **Catom configuration:** for one catom in one firmware solution: the values given to the chosen isotope's variables, and for each whether it
  was chosen automatically or by a person. Edited on the catom's page with a firmware solution picker.
- **Verdicts are per Bench Solution:** the worked-out values and every option's verdict are computed for a configuration in a Bench Solution
  context (its boards, peers, conditions). The catom page shows them for the Bench Solution in context, and lists the other Bench Solutions
  that use the same firmware solution with their verdicts, so a configuration that works on one bench and breaks on another is visible.

## Systems and Solutions (the user's rule, 2026-11-01)

> "Using Solution for specific solutions and Systems for underlying segment of that solution is probably best. Solution is usually a final
> result and solution. A Bench Solution would probably have a Hardware Solution and a Firmware solution referenced under it which are very
> specific configurations and implementations. Whereas systems are baseline templates like compositions of No-Code and Catoms and Board
> options, Systems are what we use as the baseline for composing our solutions, whereas solutions are finalized solutions used together and
> bound as a whole that can be simulated wholly. A Thermal System and Thermal Solution may also be a thing. Since solving ways to mitigate
> thermal runaway via fans, thermal sinks, and so on, is also a critical part of a solution."

- **System = a baseline template.** A composition of no-code, catoms and board options with choices still open: which isotope, which
  values, which board of a family, which mitigation. Reusable; never simulated as a whole on its own.
- **Solution = a finalized, specific result.** Every choice made (isotopes picked, configurations filled, boards and parts named), bound with
  the other solutions it is used with, and simulated as a whole.

| Segment | System (template) | Solution (specific) | Today |
|---|---|---|---|
| Hardware | **Hardware System**: board definitions, components, circuits, the stage (S1 breadboard .. S5), participants by role | **Hardware Solution**: the actual boards, module boards, parts and connections on the bench | `HardwareSystem` already reads as a template (BoardDefinitions, roles, stage), except that it lists twin sessions as participants, which are specific: those move to the Bench Solution. `HardwareSolution` exists (the no-code drawing spanning board, bridge, backend and browser; it names a board instance), so it is a solution already. |
| Firmware | **Firmware System**: the catoms composed, isotopes and values still open | **Firmware Solution**: every catom's isotope chosen and its configuration filled, for one board | the composed catoms are a `CGraph`; `FirmwareSolution` exists (graph + board -> firmware) and gains the isotope choices and configurations |
| Thermal | **Thermal System**: the heat sources, the thermal models and the mitigations one may use | **Thermal Solution**: the mitigations chosen for this bench, its ambient and enclosure, simulated | the pieces exist (`PartPowerInput`, `PartThermalModel`, the plate FEM and Foster networks, tmp-1..6); no System / Solution rows yet |
| Bench | (the Bench itself: what is on the table) | **Bench Solution**: Hardware + Firmware + Thermal Solutions + conditions, bound and simulated whole | new row |

Consequences for this plan:
- **Configurations and isotope choices belong to the Firmware Solution.** The Firmware System offers the catoms; the catom page edits them
  per Firmware Solution (as decided above).
- **Verdicts belong to the Bench Solution**, because only there is everything bound: the peers, the boards, the temperature the Thermal
  Solution produces.
- **The Thermal Solution feeds the others:** the simulated board temperature at a part becomes that part's condition. For example, the
  resonator's temperature sets the clock band the serial check uses (today tmp-6 takes temperature as a typed input).

## Thermal System and Thermal Solution (outline; its own plan on the user's go, D-cfg-9)

**Scope now: open air only (the user, 2026-11-01).** "Typically we are wanting to for now assume that Bench Solutions are always open air
because they are meant to be simplified simulations we do to ensure the baseline concept for electronics of the embedded system works before
we move on to dealing with the actual embedding process. For now we just need to be concerned with open air solutions and nothing special
yet." So a Bench Solution's thermal condition is: open air, natural convection, an ambient range, nothing else. What is built now: each
part's junction temperature in open air at the hottest ambient (the plate FEM and Foster networks as they are), the runaway loop-gain check,
and the board temperature feeding the other checks (the clock band). **Allowed in open air (the user, later the same day):** "A heat sink and fan could still be useful if it is possible to clip them into a
breadboard in the open air scenario": a clip-on or board-mounted heat sink and a small fan that plugs into the breadboard are open-air
mitigations and are in scope (each with its datasheet thermal resistance or airflow, the fan's current counted on the supply). Venting and
enclosures stay deferred. The rest of the mitigation catalogue below (pads, venting,
enclosures) is **deferred to the embedding stage**, a later kind of solution, and is kept here only so it is not lost. Until then, a part
that fails in open air is reported as invalid with its numbers; the fix suggester offers what changes the electronics (another part,
derating through a configuration, another board) and the clip-on heat sink or breadboard fan.

Mitigating heat, and thermal runaway in particular, is part of a working solution, so thermal gets the same treatment as configurations:
options graded invalid / compromise / ideal, a default chosen automatically, and the fix suggester for when nothing on hand is enough.

- **Thermal System (the template):** heat sources (`PartPowerInput`: watts, on / pulse / duty), part thermal models (`PartThermalModel`:
  datasheet Foster stages, Tj max), and a catalogue of **mitigations**, each cited:
  - heat sink: its datasheet thermal resistance to ambient, at natural convection and at stated airflows;
  - fan: its datasheet airflow against static pressure, turned into a heat transfer coefficient by a cited correlation, with its cost in power,
    noise and a moving part;
  - thermal pad or paste: its cited resistance;
  - copper area and thermal vias on a PCB, which the plate FEM already models;
  - enclosure venting;
  - firmware mitigations, which cross into the Firmware Solution: derating, duty cycling, throttling on a temperature reading (an isotope and
    its configuration).
- **Thermal Solution (the specific):** the mitigations chosen for this bench, its ambient range and enclosure. It is simulated with the
  solvers that exist: the transient plate FEM (scikit-fem) and the exact Foster networks (bob-3g), with no new engine.
- **Thermal runaway:** a part runs away when its dissipation rises with temperature faster than its path to ambient can carry it. The check is
  the loop gain, dP/dT x Rth (junction to ambient through the chosen mitigations). At or above 1 the steady state is unstable, and the verdict is
  invalid. Close to 1 is a compromise, with the margin shown. dP/dT comes from the part's datasheet (for example, leakage or forward-voltage
  temperature coefficients). Where the datasheet does not give it, it is a labelled knob, never a guess.
- **Verdicts:** invalid when Tj exceeds its maximum at the hottest ambient with the best mitigation available, or the loop runs away. Compromise
  when it holds only with a fan (power, noise, a part that can fail), with derating, or with thin margin. Ideal when passive mitigation holds
  with the full recommended margin.
- **The fix suggester:** heat-sink and fan modules as module boards or parts with `provides` (thermal resistance, airflow), each tried in a copy
  of the Bench Solution.

## The words (picked 2026-11-01; the user: "maybe you should pick the terminology")

Two levels of choice, kept apart because they behave differently:

| Word | What it is | Changing it | Row today |
|---|---|---|---|
| **Catom** | a firmware job and its interface: *what* gets done ("know when the button is pressed") | - | `CFunctionAtom` / `AtomJob`, `catom.json` |
| **Isotope** | one *way* of doing the catom's job (pin-change interrupt, analog threshold; matched-divisor UART, autobaud UART) | **changes the code**; chosen per firmware solution | `IsotopeVariant` (the route) |
| **Configuration** | the *values* the chosen isotope runs with, for one firmware solution (baud 115200, U2X 1, debounce 50 ms, ADC prescaler 128) | **keeps the code**, changes the numbers | new: `CatomConfiguration` |
| **Variable** | one named slot a configuration fills; declared by the catom (shared by every isotope) or by one isotope (the analog isotope's threshold and ADC reference; the pin-change isotope has neither) | - | `CatomVariable` (extended from pins and F_CPU to every value) |
| **Variable group** | how variables are grouped on the page and judged: clock, signal, drive, analog, timing, power, memory, rf | - | the `hal_contract` families, plus clock / power / memory / rf |
| **Option** | one candidate the checks grade invalid / compromise / ideal: either an isotope or a set of values | - | `ConfigOption` |

The rule of thumb on the page: "**Isotope:** how this catom does its job; changing it changes the code. **Configuration:** the numbers it runs
with; changing them keeps the code." Choosing an isotope comes first, because it decides which variables the configuration has. Something that
needs new code (a calibration routine, autobaud, polling instead of an interrupt) is an isotope, never a configuration value.

`CIsotope` (the generated C text of one route on one binding, with pins and values substituted) stays an internal build row: it is what an
isotope plus a configuration *produce*, not something a person picks. Its page label becomes "generated code" so the word "isotope" on screens
always means the choice.

Variable values keep the existing scope order (chip default -> board -> bench), with the **configuration** as the firmware solution's own layer
on top for values a person chooses (baud, prescalers, debounce). Pin values stay derived from the bench wiring, as today.

Clock is the first variable group built, because the evidence and the solvers are there (tmp-6). The machinery is the same for every group.

## Three verdicts and the default (the same for every group, and for isotopes)

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
registers and the conditions, (3) simulator runs at the corners (the twin, SPICE, the thermal FEM, whichever the group uses), which confirm the
formulas and catch what a formula cannot.

## Which features need configurations (the survey the user asked for)

Each row is a place where today the codebase has a fixed setting, a finding, or a hard-coded table, and where a choice with invalid /
compromise / ideal options exists.

| Variable group | What is configured | Typical invalid | Typical compromise | Exists today (fold in, do not duplicate) |
|---|---|---|---|---|
| **clock** | clock source, F_CPU, prescalers; serial baud / U2X / divisor; tick; PWM frequency; ADC clock; watchdog | U2X0 at 115200 against the 16U2 (5.9 %); ADC clock outside 50 to 200 kHz | matched divisor (works only with a matched peer); lower baud (throughput); a crystal (a part) | `timing_drift.CLOCKS`, `uart_sampling`, `clock_skew_run`, the `usart_u2x` knob, `clock.hz` |
| **signal** | logic levels across boards (5 V UNO against the 3.3 V Feather M0 / ESP32-S3 on the bench), input thresholds, bus speed against bus capacitance and pull-ups (I2C rise time), SPI clock against the slowest device | a 5 V output into a pin that is not 5 V tolerant; an I2C rise time over the mode's limit | a 3.3 V high read by a 5 V input with thin margin; a slower bus mode; a level shifter (a part) | bob-2 bench findings (over-voltage), `BenchConnection` signal data, the "FT -> 5 V, TTA -> 3.3 V" note in hsp |
| **drive** | pin current, series resistors, the load, port and whole-part totals, gate drive | a pin past its absolute maximum | within absolute max but over the recommended current; a driver part | drv-2/3: drive findings, `part_fixes.suggestions`, whole-part budgets |
| **analog** | ADC reference (AVCC / internal 1.1 V / AREF), prescaler, source impedance, thresholds (the analog `read-button` isotope) | a signal above the chosen reference; a source impedance far over the datasheet's recommendation | lower resolution at a faster ADC clock; a buffer (a part) | the analog-threshold isotope, `button_detect_registers` |
| **timing (execution)** | debounce window, ISR versus poll, the loop period, event rates against latency | an event rate above what the chosen path can service | polling with a worse latency; a longer debounce | ipb (interrupt / poll budget), `press_flag`, `debounce_ms` |
| **power** | supply rail, regulator, brown-out level against the supply, sleep modes | a load over the regulator's output; a brown-out level above the rail | a bigger regulator (a part); a lower clock at a lower voltage | drv-2 regulator suggestions, the UNO's USB budget |
| **thermal** | the temperature range to cover, derating | a part outside its rated range | derated current; a clock band only cited to a narrower range | tmp-1..6 (temperature as a condition every other group reads) |
| **memory** | flash and RAM against the isotopes and options chosen | an option set that does not fit | a smaller isotope with fewer features | firmware sizes from gen (resource-cost rule) |
| **rf** | band, power, duty cycle against the region | a transmission `tx_permitted()` refuses | a lower power or duty cycle | the no-TX-without-legality rule |

Thermal is a condition more than a configuration: every group reads the temperature range from the Bench solution. Recommended first: clock,
then signal, then drive and analog (D-cfg-3).

## When the chip cannot do it: the fix suggester (an assistive tool)

The ladder is an **assistive suggestion tool**, never an automatic change. When every option inside the chip is invalid (or only poor
compromises are left), it suggests fixes, cheapest first; each suggestion is tried in a copy of the Bench Solution in the simulator and shown
with its verdict, what it costs and its evidence. Nothing is applied until a person accepts it, and accepting is an ordinary edit (a knob on
the catom page, an isotope pick, a part or module board added to the bench), recorded like any other. (The automatic default above picks
among options inside the configuration only; it never adds a part or a board.)

1. **configuration:** different values (baud, U2X, a prescaler, a slower bus mode); the code stays.
2. **isotope:** another way of doing the job (a calibration routine, autobaud, polling instead of an interrupt); the code changes.
3. **part on the board:** a part added or swapped on a board already on the bench (a crystal for the resonator, a pull-up, a series
   resistor). Today's `part_fixes` catalogue is this level for drive.
4. **module board:** a third-party board planted on the bench and wired in through footholds. It is a board like any other (bob-5:
   `board_spec`, new boards are data), and it adds a **provides** block: what it gives the bench (a clock at a frequency and stability on a
   pin, level translation between two voltages on N channels, a UART with its own crystal, a regulated rail).
5. **another board or chip:** the Mission search's inventory step, when nothing on the bench can be made to work.

**Yes, module boards with their own oscillators are a real thing.** Candidates for the clock group (each is cited from its datasheet before it
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

The same ladder serves the other groups. Signal: level-shifter breakouts. Drive: driver and MOSFET boards. Power: regulator or buck modules.
Each is a module board with a `provides` block, and each fix is proven by re-running the same checks with the module board on the bench.

## The rows (one object per concern, small, by level; references, never copies)

The user (2026-11-01, during cfg-0): "keep clean separation between objects and keep them small and multi-level and separated conceptually so
people can learn these systems", "and prevent overlap, use references". Each row below holds one concern and names the rows it depends on; a
fact reachable through a reference is never stored twice (the cfg-0 selftest checks it).

| Level | Row | Its one concern | Fields | References |
|---|---|---|---|---|
| catalogue (code) | `cmod.custom.config_groups` | the words: variable groups, verdicts, option levels, check layers | - | - |
| definition (System) | `ConfigOption` | what a candidate would set | catom, group, level, title, sets_json, isotope, source | the catom; the isotope |
| solution | `CatomConfiguration` | which isotope one catom uses in one firmware solution | isotope, isotope_chosen_by | FirmwareSolution, catom, IsotopeVariant |
| solution | `ConfigChoice` | which option supplies one group's values, and who chose it | chosen_by, why | CatomConfiguration, ConfigOption (its group and values are the option's) |
| context | `BenchSolution` (board) | everything on a bench bound as a whole | (references only) | Bench, HardwareSolution, FirmwareSolution, Thermal Solution (later), BenchConditions |
| context | `BenchConditions` (board) | the room: air (open), ambient range, supply, aging | air, ambient_min_c, ambient_max_c, supply_v, aging_years | - |
| result | `ConfigVerdict` | whether one option works in one Bench Solution, and its score | verdict, score, why | BenchSolution, ConfigOption (not the catom or configuration: those come through the references) |
| evidence | `ConfigCheckResult` | what one check found | check, layer, outcome, margin, gives_up, why, evidence | ConfigVerdict |
| definition (later) | `ClockSource` (cfg-1) | one clock source's cited datasheet bounds | kind, nominal, tolerance, band and temperature range, aging, source | - |
| definition (later) | module board `provides` (cfg-5) | what a module board gives the bench, for the fix suggester | in `board_spec` | the board |

**Where it is edited: the catom page.** Catoms have no page of their own today; this plan adds one (`/display/catom` scoped to a catom,
configured Table definitions, no raw JSON). Its Configuration tab: a firmware solution picker, a Bench Solution picker for context, then one
isotope picker (with each isotope's verdict), then a section per variable group with the values as edit fields, the options with their verdicts and scores, the chosen one and why, and the suggester's fixes
when nothing inside the chip works. The other Bench Solutions using the same firmware solution are listed with their verdicts. The HAL drawing
(`HalVariableState`) links to the catom page instead of holding a second editor (D-cfg-4).

## Stepping through firmware in a Bench Solution, changing configurations

A person steps through the firmware with a Bench Solution as its context, and can change a configuration at a step and see the effect.

- **What exists:** `TwinSession` runs one board's locked firmware with a live control channel; `BenchInteraction` records every action with
  the twin's own CPU cycle; the twin is cycle-exact and deterministic. **It cannot pause or step today**, and it runs one board, not a bench.
- **Stepping:** the twin gains pause / run-to / step commands on its control channel (by cycle, by time, to the next bench event or serial
  frame, to a catom's function entry from the build's symbol map). simavr has a gdb stub for instruction-level stepping; event-level
  stepping is the one a person needs first. This is a C change and a rebuild of the local `prf-board-engines` image (D-cfg-6).
- **Changing a configuration at a step:** most knobs are build-time (baud, U2X, F_CPU, prescalers), and the twin's firmware is locked, so a
  change means: rebuild with the new configuration, start a fresh twin, **replay** the recorded interactions to the same point (deterministic,
  by cycle and by true time), and show both runs side by side from that step: what differs (bytes, pin levels, verdicts). World-side settings
  (the oscillator's error, the peer's clock, temperature) replay the same way. The original run is kept; nothing is edited in place.
- **The whole bench:** the session gets a Bench Solution context: the bench's boards and peers (the 16U2 model from tmp-6 first), its
  conditions, its connections; other boards on the bench join as more twins or as models, said per board (the Bench's testing column).

## The clock group in detail (carried from clk)

- **Clock source:** the thing that makes the chip's clock (resonator, crystal, internal RC, external oscillator). Datasheet bounds, used as
  bounds, never drawn as curves (the tmp-4 rule).
- **Knobs:** clock source and F_CPU, CKDIV8; baud, U2X, a UBRR override, stop bits; the tick's prescaler and compare value; PWM prescaler /
  TOP; ADC prescaler; the far end (peer) and its clock error; the sampling phase or "worst phase".
- **Worked out:** each value and its error (baud %, tick ppm, PWM Hz, ADC kHz); the clock band at the conditions; for serial the band in which
  both directions decode (`clock_skew_run.limits`) and the margin left.
- **Peer rows:** the 16U2 as arduino-usbserial sets it (built in tmp-6), "exact", a USB-serial adapter by its datasheet, another of our boards.

| Option | Level | What it costs | Note |
|---|---|---|---|
| Matched divisor (U2X, UBRR 16, as Arduino does) | configuration | works only with a peer that uses the same divisor; about +-2.5 % margin against the 16U2 | today's shipped build |
| Normal mode (16 samples, UBRR 8) | configuration | -3.5 % divisor error: invalid against the 16U2 at 115200 | wider window, worse divisor |
| Lower baud (57600 / 38400 / 9600) | configuration | throughput, worked out against the telemetry load | 9600 = 0.2 % error |
| Two stop bits sent | configuration | about 9 % less throughput | removes the fast-sender failure |
| RC + OSCCAL user calibration | isotope + part removed | +-1 % after calibration, +-10 % before | a calibration routine |
| Autobaud / a sync byte | isotope | firmware size and cycles, a sync protocol | follows the peer's clock |
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
| cfg-0 ✅ BUILT 2026-11-01 | the shape: `BenchSolution` (Hardware + Firmware Solution references; Thermal once it exists), `VariableGroup`, `CatomConfiguration` (isotope + values, per firmware solution), `ConfigOption`, `ConfigVerdict` (per Bench Solution); the verdict engine (layered checks, the automatic default, a person's choice recorded) with no group wired yet | a toy catom with two isotopes and one invalid, one compromise, one ideal option: the ideal is chosen; the override is recorded with what it gives up; the same configuration judged in two Bench Solutions gets two verdicts |
| cfg-1 | clock group, part 1: `ClockSource` and peer rows (cited); `timing_drift` reads them; the serial-link and tick checks from tmp-6 code | the UNO's shipped configuration: 117 647 Bd, +2.1 %, the 16U2 matched, margin -2.50 .. +2.56 % against a +-1.0 % band, compromise, chosen automatically; U2X0 invalid with the 5.9 % |
| cfg-2 | the catom page: `/display/catom`, its Configuration tab (firmware solution and Bench Solution pickers, knobs, options, verdicts, other Bench Solutions) | the door returns the UNO's serial configuration with both verdicts; Chrome pass needs a deploy (the user's call) |
| cfg-3 | clock group, part 2: the option catalogue graded; the simulator by configuration; the FE twin flag; `clock-skew` as a scenario step | a HAL_UART_ERRCOUNT build counts the 236 FEs tmp-6 saw; 9600 invalid for the telemetry load |
| cfg-4 | stepping: pause / run-to / step on the twin's control channel (D-cfg-6); change a configuration at a step = rebuild + replay to the same point + side-by-side difference; the session carries its Bench Solution | step to the first command byte, switch U2X 1 -> 0, replay: the command now fails to land, shown beside the original run from that step |
| cfg-5 | the fix suggester: `provides` in `board_spec`; two cited clock module boards and one UART bridge; the footholds reachability check (XTAL1 not on the UNO's headers); each suggestion tried in a copy of the Bench Solution; `part_fixes` becomes the drive group's part level | for U2X0 at 115200 the suggester lists: matched divisor (values), lower baud (values), the UART bridge board (clean), the external-clock module (needs rework), each with its verdict and evidence; nothing applied until accepted |
| cfg-6 | signal group: levels across bench boards from footholds, I2C rise time; level-shifter module boards in the suggester | the UNO wired to the Feather M0: a 5 V output into its pin is invalid; a level-shifter board is suggested and proven |
| cfg-7 | drive and analog groups, then timing, power, memory (rf when an RF catom exists) | each verdict cites its datasheet formula or measurement |
| cfg-8 | the firmware follows the choice: gen reads the configuration (baud, U2X, F_CPU, stop bits, divisor by the datasheet equation) and refuses one that is invalid in the Bench Solution being built for | `pol board gen --u2x 0` at 115200 for the UNO's USB link is refused with the reason |

## Decisions (the user's)

- **D-cfg-1: the Bench Solution.** Decided by the user: a Bench Solution references a Hardware Solution and a Firmware Solution (and a
  Thermal Solution); Systems are the templates, Solutions the bound specifics. Still open within it: twin sessions move from
  `HardwareSystem`'s participants to the Bench Solution (recommended), and the composed catoms (`CGraph`) are labelled "Firmware System" on
  screens rather than adding a new class (recommended).
- **D-cfg-2: the variable groups.** Recommend the list above, lined up with the catoms' `hal_contract` families plus clock, power, memory and rf, with
  thermal as a condition every group reads.
- **D-cfg-3: the order.** Recommend the phase order above: clock, the catom page, stepping, the suggester, then signal, drive and analog.
- **D-cfg-4: where configurations are edited.** Per the user: on the catom page, per firmware solution. Recommend the HAL drawing links there
  instead of keeping its own editor.
- **D-cfg-5: module boards.** Recommend module boards as ordinary boards (`board_spec` data) with a `provides` block, not a separate class.
- **D-cfg-6: the twin C changes** (the FE flag; pause / run-to / step on the control channel) and a rebuild of the local `prf-board-engines`
  image (a local build, not a deploy). Yes / no.
- **D-cfg-7: the `USART_U2X 0` knob.** Recommend: keep it; the clock check marks it invalid at 115200 against the UNO's 16U2, and gen refuses
  it there with the reason (it is fine against a matched peer, or at 9600).
- **D-cfg-9: thermal.** Open air only for now (the user). Recommend the open-air thermal checks ride in this plan as one phase after cfg-0;
  the mitigations get their own plan (THERMAL_SOLUTION_PLAN) when the embedding stage starts.
- **D-cfg-8: the words.** Picked in "The words" above: catom, isotope (changes the code), configuration (changes the values), variable, variable group, option, System (template), Solution (specific), Bench Solution, fix suggester, module board; `CIsotope` shown as "generated code".
