# Hardware Mission no-code, pin profiles, register profiles, and the solution search (msp arc) — plan 2026-10-17

PLAN ONLY. Nothing here is built before his go. Terminology: `SYSTEM_HIERARCHY_TERMINOLOGY.md` §8–§13. Pins: `HARDWARE_SYSTEM_PINS_PLAN.md`
(the availability ladder §2b, hsp-0/1 built).

## 0. His words (2026-10-17)

"Okay do we have an approach towards defining the mission and purposes of our project as no-code for now? And once we do so, having an
approach to run an engine that attempts to identify parts to assign to purposes to identify a viable solution out of tasks specific to a
board? We likely want to start with profiling from the purposes what pin-profiles are required per purpose, and identifying which
pin-profiles can allow overlap at all. We want to also be able to see a profile of registers on the SoCs and profile the registers that
belong to pin configurations vs those that belong to Flash or RAM"

## 1. What exists (read 2026-10-17)

| piece | today | gap |
|---|---|---|
| Purpose no-code | ✅ fgm-1: eleven declarative states, category `purpose`; the row is the truth (lifecycle stored, resolution derived); participants, criteria, observes, tasks; four seeded Purposes for the light demo | no level above it |
| Hardware Mission | terminology only (§8, ruled name) | no class, no no-code |
| Task kinds per pin | ✅ `board/custom/target_compat.py` `TASK_KINDS` (analog-in, pwm-out, uart-rx/tx, i2c-sda/scl, spi-*, digital-in/out, interrupt-in + peripheral-level kinds), cited, with `compatible(kind, pin)` | a Purpose does not state which kinds it needs; it reaches them only through its tasks' atoms |
| What a task touches | ✅ `cmod/custom/targets.py` derives each atom's targets (declared pin macros, registers → peripheral, struct fields) | not rolled up per Purpose |
| Pin sharing | ✅ `cmod/custom/claims.py`: exclusive claims with a cooperation rule; PinFunction `overrides_gpio` (§14.3) | no table saying which kinds may share one pin or one net |
| Availability | ✅ hsp-0 ladder: ten rungs per (pin, function, context) | answers one pin at a time; nothing searches |
| Registers | ✅ 96 Register rows (by peripheral: TIMER1 17, CPU 13, TIMER2 9, ADC 8 …), 97 cited RegisterFields (71 carry `affects_pin`, 37 `affects_signal`), 18 RegisterBlocks, 2 AddressSpaces | no classification into pin configuration / peripheral operation / memory / CPU-system |
| Memory | ✅ MemoryRegion flash 32 KB, SRAM 2 KB @0x0100, EEPROM 1 KB | the register file R0–R31 (0x00–0x1F) and the bootloader section (Optiboot, top 512 B of flash) are not regions |
| The search | planned as fgm-4 (typed HAL + resolver over the existing predicates, backtracking) | not started |

## 2. The approach

### 2.1 Hardware Mission as no-code (mis-0)
- `HardwareMission` (cmod, beside `CapabilityDefinition`): name, title, goal, `purposes_json` = [{purpose, importance}] (importance scale =
  D-sys-2: safety | required | important | desired), `participants_json` (roles only, hardware-agnostic, the same shape as Purposes),
  `constraints_json` (target development stage S1–S5, budget knobs, allowed board families — all optional), lifecycle stored, resolution
  DERIVED (every required Purpose resolvable on some candidate).
- No-code category `mission`, reusing the Purpose machinery (declarative doors GET/PUT `…/solution`, the row is the truth, derived cards
  read-only): states **Goal → Purposes (one per Purpose, importance on it) → Participants (roles) → Constraints → Resolution (derived)**.
  Hardware-agnostic: no pins, no boards (§8 layer 1).
- Seed: `uno-light-mission` — "Prove Polari and one board can control and observe one light in both directions" — with Initialization
  (required) and the three light Purposes (required).

### 2.2 Pin profiles per Purpose (pp-0)
A **pin profile** is what a Purpose needs from one pin, before any pin is chosen:
{kind (a `TASK_KINDS` entry), role (which participant it serves: "the button", "the LED"), direction, electrical need (drive: load class +
current; signal: threshold class + pull), timing need (edge, rate, latency from the Purpose criteria), lifecycle phases it is active in, count}.
- DERIVED, never typed: Purpose → its tasks (graph nodes) → each atom's targets (`cmod/custom/targets.py`) → kinds; electrical and timing
  needs from the Purpose's participants (the circuit parts) and criteria. A person's correction is a DerivedOverride (who/when/why), the
  same rule as everywhere else.
- Rolled up per Mission: the multiset of profiles every required Purpose needs. Light demo expected: interrupt-in (button), digital-out
  (LED drive), interrupt-in (sense), uart-rx + uart-tx (transport), plus the reserved transport/bootloader pins.

### 2.3 Which profiles may overlap (pp-1)
A cited **overlap table** per SoC family (AVR first): for each pair of kinds, at three scopes — **same pin**, **same net** (two pins wired
together), **same peripheral** — the verdict compatible | exclusive | conditional (reason) | undetermined, each with its citation. Examples
from rules already cited in the code:
- same pin: digital-out + digital-in = compatible (the input buffer reads an output pin back) · interrupt-in + digital-in = compatible ·
  pwm-out + digital-out = exclusive (an enabled alternate function overrides PORT, §14.3) · uart-rx + anything = exclusive while USART0 RX is
  enabled · analog-in + digital-in = conditional (DIDR0 turns the digital buffer off).
- same net: one driver + any number of inputs = compatible (rule (b), the D6→D3 wire); two drivers = exclusive.
- same peripheral: two channels of one timer = compatible on channels, exclusive on the timer's mode (claims' cooperation rule).
Sharing modes recorded beside it: exclusive · shared-read · time-multiplexed (time-multiplexed is a later fgm-4 claim mode).
Output per Mission: which profiles can co-locate, the minimum number of pins, and the conflicts named.

### 2.4 Register profile of a SoC (rp-0)
Classify every register FIELD (then roll up to the register): **pin configuration** (a field with `affects_pin` / `affects_signal`, or one that
enables an alternate function taking over a pin: DDRx/PORTx/PINx, COMnx in TCCRnA, RXEN0/TXEN0, SPE, TWEN, DIDR0, ISCnx/INTx, PCMSKn/PCIE) ·
**peripheral operation** (counts, compare values, baud, data registers) · **memory / NVM** (EEPROM EEAR/EEDR/EECR, flash self-programming
SPMCSR, stack pointer SP) · **CPU / system** (SREG, MCUCR, SMCR, PRR, CLKPR, OSCCAL, WDTCSR, MCUSR, GPIORn). DERIVED from the cited field rows;
a register whose fields fall in two classes is **mixed** (MCUCR: PUD disables every pull-up = pin configuration; IVSEL/BODS = CPU).
Plus the **memory map** view: register file R0–R31, I/O space, extended I/O, SRAM, flash (application + the bootloader section), EEPROM, each
as a MemoryRegion with its citation; and what a firmware uses of each (flash and RAM bytes measured at build, the bootloader subtracted).
Doors: `GET /api/board/socs/{soc}/register-profile`, `…/memory-map`; CLI `pol board registers <soc> [--class pin|peripheral|memory|cpu]`.

### 2.5 The solution search (sol-0, refines fgm-4)
Input: a Mission (+ optional stage and candidate boards). Steps:
1. Derive the pin profiles (2.2) and the overlap table (2.3).
2. For each candidate context (board × package × USB interface; every allowed one while the bench variant is pending), assign profiles to pins
   as a constraint search: each profile's candidate pins = pins whose ladder (rungs 1–9) is not blocked for its kind; the overlap table prunes
   co-location; claims and lifecycle are honoured; backtrack on conflict.
3. Prefer the least specialised pin (keep INT0/INT1, PWM, ADC pins free when a plain pin will do) and record why each pin was chosen.
4. Each viable assignment is a **Candidate**; several are compared in a **Trade study** with a **Score card** (D-sys-6: pins left free, scarce
   functions left, electrical margin, unchecked rungs). The chosen one becomes the Hardware System's pin plan; after fgm-3 it seeds the
   **Task Plan** ("Designed for" this Hardware System).
5. Every run is a recorded row (inputs by sha256, rule versions, the candidate list) — the reproducible-initial-conditions rule.
Runs in the backend (pure Python; the UNO problem is tiny), behind `POST /api/missions/{m}/solve` and `pol board solve <mission> [--board B]`.
Acceptance on the UNO: finds D2 / D6 / D3 (or an equivalent the score card explains), refuses D0/D1 for the button by name (rung 8), accepts
D7 for the LED when D6 is taken, and reports the TQFP difference.

## 3. Slices (each its own branch, proven on the econ-core test node)
| # | slice | builds |
|---|---|---|
| 1 | mis-0 | HardwareMission + `mission` no-code category + seed + doors |
| 2 | rp-0 | register field classes + roll-up + memory map (register file, bootloader region) + doors + CLI — independent of 1, can run in parallel |
| 3 | pp-0 | pin profiles derived per Purpose and per Mission + door + CLI |
| 4 | pp-1 | the cited AVR overlap table + per-Mission co-location report |
| 5 | sol-0 | the search on the UNO → Candidates + Score card; feeds fgm-3 Task Plans |

## 4. Decisions (his; my recommendation first)
- **D-msp-1** importance scale for Purposes in a Mission: safety | required | important | desired (this is D-sys-2).
- **D-msp-2** pin profiles DERIVED with DerivedOverride corrections (recommended) — or authored per Purpose.
- **D-msp-3** overlap rules cited per SoC family, AVR first (recommended).
- **D-msp-4** order: mis-0 and rp-0 in parallel, then pp-0 → pp-1 → sol-0 (recommended).
- **D-msp-5** the search runs in the backend, no new engine container (recommended; revisit when the problem stops being small).

## 5. His rulings 2026-10-17 (second message) — Purposes as states, Mission settings

His words: "Purposes should become states in the Mission No-code. We should specify settings in the mission, like aiming to accomplish the
mission with as minimum resources as possible (we want to use the least resources possible to accomplish our goal) or accomplish all purposes
completing one cycle as fast as possible (fastest cycles through all purposes possible with available resources. (one cycle per purpose is
doing all tasks relevant to the single purpose)."

**§2.1 amended — the Mission drawing's states:** Goal → **Settings** → **one state per Purpose** (each a full state: its importance, its derived
resolution, its pin-profile count, and a link into that Purpose's own drawing) → Participants (roles) → Constraints → Resolution (derived).

**Settings = the objective the solution search optimizes** (one chosen; the Purpose criteria stay as bounds either way):
| objective | minimizes | subject to |
|---|---|---|
| **minimum-resources** | resources used: pins, peripherals, flash bytes, RAM bytes, CPU share, parts on the bench | every required Purpose's criteria (latency, debounce, rate) still met |
| **fastest-cycle** | the Mission cycle time with the resources available | the resources the candidate hardware has |

Cycle definitions (his): a **Purpose cycle** = executing every task relevant to that one Purpose once; a **Mission cycle** = one cycle through every
Purpose. Times come from the twin's measured cycle counts per task (simavr), estimated from atom sizes until measured, labelled which.
Resources carry units and are measured, per the resource-cost rule. The two objectives pull apart on the UNO: fastest-cycle prefers interrupts
and hardware peripherals (INT0/INT1, USART interrupts) and dedicated pins; minimum-resources prefers polling and shared pins where the criteria
allow. The score card (§2.5 step 4) sorts by the chosen objective first and shows the other as a secondary column.

## 6. ✅ rp-0 BUILT + MERGED 2026-10-17 (framework cd40f06; cli `pol board registers | memory`; sonnet agent) — started on his go ("Go ahead and start revising work")
- 96 registers: 18 pin-configuration, 50 peripheral-operation, 9 memory-nvm, 10 cpu-system, 9 mixed (MCUCR, UCSR0B, SPCR, TWCR, TCCR0A/0B/1A/2A/2B).
  Fields from RegisterField rows (97) + cited alternate-function rules (14) + bit names from the datasheet Register Summary pp.621–624
  (committed snapshot `register_summary_atmega328p.json`, method recorded); 77 registers have no field rows ("fields not modelled").
- Memory map (MemoryRegion 3 → 8): register file 0x0000/32 B, I/O 0x0020/64 B, extended I/O 0x0060/160 B, SRAM 0x0100/2048 B (data space
  0x0000–0x08FF contiguous); flash = application + boot loader (chip default BOOTSZ 4096 B @0x7000, Table 27-13 options; on the UNO Optiboot 512 B
  @0x7E00 → application 32256 B = boards.txt upload.maximum_size); EEPROM 1 KB. Firmware use from sizes (.text+.data flash, .data+.bss RAM), else
  `unmeasured`.
- Judgement calls (cited rule entries, reversible): w1c status flags and interrupt-enable bits (TIMSKn) = peripheral-operation, not pin; FOCnx = pin.
- Doors `/api/board/socs/{soc}/register-profile`, `/memory-map`; pages `/display/register-profile`, `/display/memory-map`; Hardware home group
  "The chip's registers and memory". board 616 (worktree), cmod 698, hwnocode 163, apps 126, manifests 8/9 (unchanged).
- Undetermined: the UNO's shipped BOOTSZ fuse (boards.txt high_fuses not read); EEPROM use (no .eeprom size recorded).

## 7. His go 2026-10-17 night — "do small fixes first then move on autonomously, work through the night"
D-msp-1..5 had no explicit ruling; taken AS RECOMMENDED under this go (each reversible, his to overturn): importance scale safety | required |
important | desired; pin profiles DERIVED with DerivedOverride corrections; overlap rules cited per SoC family, AVR first; order mis-0 → pp-0 → pp-1 →
sol-0 (rp-0 already built); the search runs in the backend. Settings per §5 (his words): objective minimum-resources | fastest-cycle.
Night sequence: small pin-view fixes (sf) ‖ mis-0 → pp-0 → pp-1 → sol-0 → pv-4 configuration events, each a branch proven on econ-core.

## 8. The attempt engine: hardware × runtime tier × isotope variants (his words 2026-10-17 night)

"We also need to ensure we have an engine to run attempts with different actual hardware and then isotopes, we should pre-profile approaches by
things like 'if this seems like it would benefit from multithreading should we use FreeRTOS isotopes and profile to those? If the complexity goes
further should we go to zephyrRTOS isotopes?' Then looking at isotopes of different profiles, like if thermal sensors exist that allow readings via
analog, digital, spi, etc, all of the ways to code for those specific variants of hardware protocols would be the valid isotopes for the C atom that
has to do with communicating with the thermal sensor to get its data…. in this case we are instead using button presses and LEDs, but we should
enable and account for various ways to do it, so we can find ways to do it later on boards with only specific resources still. Like under normal
conditions SPI is maybe wasteful for a button press, but if it works and is all we have left and everything else is occupied with more important
things that may be what we have to do."

### 8.1 What exists
- The runtime ladder: `CIsotope.minimum_level` ∈ bare-c < freertos < esp-idf < zephyr (`cmod/custom/code_interface.py` LEVEL_ORDER, `level_ok` refuses
  by name); runtimes as rows (`hwnocode/custom/runtimes.py`); the ESP32-C3 RTOS variants (sc-4) prove a non-bare tier.
- Isotopes today: one per atom × binding, DERIVED by substitution — no ALTERNATIVES across protocols.
- The kit (25 KitPart rows): pushbutton, LED, resistors, TMP36 (analog), phototransistor, tilt sensor, potentiometer, piezo, LCD 16×2, servo, DC
  motor, H-bridge, MOSFET, transistor, optocoupler, diode, capacitors … — NO shift register and NO I/O expander, so an SPI- or I²C-routed button needs
  a part the bench does not have (the engine must say so, not assume).

### 8.2 Pre-profiling the approach (runtime tier) — `approach_profile(mission)`
Derived from the Mission's Purposes, never authored: count of independent triggers and their deadlines (criteria), periodic tasks with conflicting
periods, blocking operations (waits, bus transactions), data rates, the number of concurrent responsibilities per processor. Output: a recommended
tier with the reasons — **bare-c** (a superloop + ISRs meets every deadline: the light demo), **freertos** (several independent periodic/blocking
tasks whose deadlines a superloop cannot guarantee; priorities derived per terminology §D-sys-3), **zephyr** (beyond that: many drivers, stacks,
devicetree-described multi-device systems). Each tier is then CHECKED against the hardware: RAM/flash budget (FreeRTOS on the ATmega328P's 2 KB SRAM
is tight — measured, never guessed), and support (Zephyr has no AVR port → zephyr is `unavailable` on the UNO, by name). The tier filters which
isotopes are eligible (`level_ok`). Advised, never forced: a person can pick a higher tier and the engine shows its cost.

### 8.3 Isotope variants per C atom (the protocol axis)
A C atom's isotopes are ALL the ways to do its job on any hardware. Each variant declares: the pin profiles it needs (pp-0 kinds), the peripherals
it claims, the extra parts it needs (KitPart refs or "not on the bench"), its runtime tier, its costs (pins, peripherals, flash, RAM, CPU share,
latency — estimated until measured on the twin, labelled), and its status (declared · template exists · compiles · proven-on-twin ·
proven-on-hardware). Seed catalogue (declared first; templates follow in fgm-5):
| atom job | variants |
|---|---|
| read the button | GPIO poll · external interrupt (INT0/INT1) · pin-change interrupt (PCINT) · analog threshold (ADC) · analog comparator (AIN0/AIN1) · via an SPI shift register (needs a 74HC165-class part — not on the bench) · via an I²C I/O expander (not on the bench) |
| drive the LED | GPIO out · PWM (timer compare output) · via an SPI shift register (74HC595-class — not on the bench) · via an I²C expander (not on the bench) · through a transistor/MOSFET for higher current (kit has both) |
| read temperature | analog (TMP36 — on the bench) · 1-Wire digital (DS18B20-class) · I²C (TMP102-class) · SPI (thermocouple-converter class) — each part class marked on/off the bench |
| sense the LED line | external interrupt · PCINT · GPIO poll · analog read of the line |

### 8.4 The attempt engine (extends sol-0)
For each candidate HARDWARE (board × package × USB interface × bench parts available) → each eligible RUNTIME TIER (8.2) → each combination of
isotope VARIANTS (8.3): derive the needed pin profiles → resolve them with the ladder + the overlap table (pp-1) + claims → score by the Mission's
objective (minimum-resources | fastest-cycle). Variants are never excluded for being "wasteful": an SPI-routed button stays a valid candidate and
is simply scored worse (more pins/peripherals/parts) — it wins only when the better variants cannot be placed (everything else occupied by more
important Purposes, by importance). Search order: least-cost variants first, backtracking on conflict, with every pruned branch recorded with its
reason. Every run is recorded (inputs by sha256, rule versions, candidates, the chosen one, why each other lost). Output = Candidates + Trade study +
Score card (D-sys-6), and the chosen candidate seeds the Task Plan (fgm-3) "Designed for" that hardware; other hardware the same plan resolves on is
recorded "Also runs on" (terminology §8).

### 8.5 Slices (after pp-0/pp-1)
| # | slice | builds |
|---|---|---|
| iso-0 | variant catalogue | the declared isotope variants of 8.3 as rows linked to their atom jobs, with profiles / parts / tier / cost estimates / status; bench-part availability from KitPart |
| rt-0 | approach pre-profiler | `approach_profile` (8.2) + tier checks (memory measured, support by name) + door/page |
| sol-0 | the attempt engine | 8.4 over the UNO (+ the modelled ESP32-C3 as a second hardware) → candidates, score card, recorded runs, the pin view drawing a candidate's assignment (stage "candidate") |
| fgm-5 | templates | real Jinja2 templates for the most useful variants (PCINT button, PWM LED, analog-threshold button), each compiled + twin-proven, status climbing the ladder |

## 9. ✅ mis-0 BUILT + MERGED 2026-10-18 (framework 167b16a + merge 2190271, angular 21c160a; sonnet agent)
- `HardwareMission` + six states (MissionGoal / Settings / Purpose — one per Purpose, field `purpose_name` / Participant / Constraint / Resolution —
  derived, never stored); `cmod/custom/mission_{nocode,derived,text,palette,seeds,doors}.py`, `cmod_mission_api.py` (MissionAPI); doors GET
  `/api/missions`, GET/PUT `/api/missions/{name}/solution`, GET `/api/missions/{name}/resolution`; hwnocode validator category `mission`.
- Seed `uno-light-mission` (4 required Purposes, 5 participants incl. the person, objective minimum-resources, stage S1-breadboard) + its drawing
  `mission-uno-light-mission`; seed converges nothing a person sets (settings, lifecycle, importances, notes).
- Angular: category Mission (icon rocket_launch), GET/PUT drawing load/save, read-only resolution, a row of links into each Purpose's drawing
  (`mission-links.ts`). Hardware home group "Missions" → `/display/hardware-solutions?solution=mission-uno-light-mission`.
- Resolution rule: safety + required Purposes decide (else all named); none → unbound; a missing Purpose = unresolved, named. Cycle/resource
  estimates show "Not worked out yet" until sol-0.
- cmod 698 → 769, hwnocode 163, board 668, apps 127, hdr4 13, specs 13/13, ng build OK. Manifests: I fixed pv-2's unlisted files (board) → 8/9 again.

## 10. ✅ pp-0 BUILT + MERGED 2026-10-18 (framework 739cfff; cli `pol capability pins | pins-mission`; sonnet agent)
- Profiles DERIVED per Purpose from its tasks, the bench circuit rows and PinClaims, evidence per field; signal and drive in separate keys.
  initialization: transport uart-rx/tx (reserved), LED digital-out, button interrupt-in (debounce undetermined: no criterion). ensure-button-controls-light:
  button interrupt-in, pull-up, falling edge, debounce 30 ms (its criterion); LED digital-out sourcing current into LED1 via R1 220 Ω (current undetermined —
  assumed Vf; Vf-free ceiling 22.7 mA shown as "not a design target"); sense line D3 interrupt-in (origin: bench — the light graph has no sense task yet).
- Mission roll-up `uno-light-mission`: 5 distinct profiles (transport uart-rx, uart-tx reserved; the LED; the button; the sense line) with importance from
  `purposes_json`; the LED counted once across three Purposes.
- Corrections through DerivedOverride (class PinProfile added to overrides.py). Doors GET `/api/capabilities/{name}/pin-profiles`, `/api/missions/{name}/pin-profiles`,
  `/api/pin-profiles`; page `/display/pin-profiles` ("Pin profiles" group on the Hardware home). cmod 805, board 671, hwnocode 163, apps 127, manifests 8/9.
- Found and handled: `usart_send` matched D0 as uart-tx (wrong) — dropped by target_compat by name; `led_toggle` would fall back to pwm-out — folded into
  the LED digital-out with the reason in evidence.

## 11. ✅ iso-0 BUILT + MERGED 2026-10-18 (framework cbeed9d; cli `pol cmod jobs | variants`; sonnet agent)
- `AtomJob` (6: read-button, drive-led, sense-led-line, read-temperature, report-state, receive-command) + `IsotopeVariant` (22 = §8.3's 20 + the two
  transport routes). Stored: declared fields + estimated/undetermined costs; DERIVED on request: status, on-bench flags, measured costs, eligibility.
- Status today: `compiles` ×7 (INT0 button, GPIO LED, PWM LED, INT1 sense, TMP36 analog, uart-tx report, uart-rx command) — climbs to proven-on-twin /
  -hardware only from a passing ScenarioRun of a Purpose whose graph holds the route's atoms; 15 `declared`. Measured: INT0 button 210 B flash / 8 B RAM /
  17 B stack, GPIO LED 16 B, TMP36 50 B (atom sizes from uno-button-clock / manifests); the rest undetermined, lower bounds or labelled estimates.
- Eligibility on the UNO: SPI-shift-register / I²C-expander routes and the DS18B20 / TMP102 / MAX31855 sensors blocked BY THE MISSING BENCH PART (named);
  poll / INT / PCINT / ADC threshold / comparator / GPIO / PWM / transistor / TMP36 ok. Tier: zephyr blocked on AVR (RuntimeProfile row), freertos refused
  for 2 KB SRAM, esp-idf Espressif-only. ESP32-C3: GPIO/ADC/TMP36 ok; INT/PCINT/comparator/PWM/UART routes undetermined (no PinFunction rows — GPIO matrix).
- Variant `profiles_json` uses pp-0's kind/role vocabulary (selftest: every profile of uno-light-mission is offered by some variant).
- Gap for pp-1: TASK_KINDS has no comparator kind (the comparator route uses analog-in with a note).
- Doors `/api/atom-jobs`, `/api/atom-jobs/{job}/variants[?board&tier]`, `/api/atom-variants`; page `/display/isotope-variants`. cmod 896, board 671,
  hwnocode 163, apps 128, manifests 8/9.
- **mis-0 live on econ-core 2026-10-18:** `/display/hardware-solutions?solution=mission-uno-light-mission` draws Goal → Settings ("Aims at: the fewest
  resources") → four "Required: …" Purpose states → five Participants → Limits → "Can it be done here? resolved", with the link row into each Purpose's
  drawing. The page frame still carries the generic Hardware-solutions text and the Runtime picker says "Python (Backend)" on a declarative drawing
  (same known leftover as the Purpose drawings, FGM plan §8.7).

## 12. ✅ pp-1 BUILT + MERGED 2026-10-18 (framework e2e2345 + my fix 96a13d3; cli `pol board overlap`, `pol capability colocation`; sonnet agent)
- Cited overlap table for the ATmega328P, code-owned and derived on read (no stored rows that could drift): 17 kinds (incl. `transport`, `comparator-in`
  with AIN0/AIN1 + DIDR1 rules, `pin-change-in` separate from INT0/INT1) × 153 pairs × 3 scopes = 459 verdicts (218 compatible, 148 exclusive, 92 conditional,
  1 undetermined: pwm-out + comparator-in on PD6 — the datasheet is silent). Every datasheet cite = section + printed page + verbatim quote, checked against
  DS40002061B; code rules cited by name (single_output, claims, lifecycle). Modes exclusive · shared-read · shared-config · time-multiplexed-later.
- Light demo co-location: 5 profiles need 5 pins apart, 4 under the most permissive valid sharing (LED + sense on one pin is conditional: the sense would see
  the firmware's own writes — the demo deliberately uses a real wire); button + LED never share (pull-up only while input, Table 14-1; switch to ground
  would short an output); transport lines forced apart.
- My review fix: the host-link reservation now also applies at NET scope (the report had listed "transport + button could share a net, conditional").
- Note: co-location is SoC-scope (pin options include PB6/PB7/PC6 that the UNO does not expose) — board availability is the ladder's job in sol-0.
- Doors `/api/board/socs/{soc}/profile-overlap`, `/api/missions/{name}/colocation`; page `/display/profile-overlap`. board 702, cmod 909.

## 13. ✅ rt-0 BUILT + MERGED 2026-10-18 (framework 7ad6dd7 + merge afd64b2; cli `pol capability approach`; sonnet agent)
- Light demo on the UNO: 3 independent triggers (button, SET_LED, the 10 Hz report), tightest deadline 100 ms, one periodic task (telemetry 100 ms from
  TELEMETRY_HZ), one blocking op (the USART send wait ≤ 9.5 ms, estimated), 4 ISRs, 5 loop tasks → **bare-c, PROVISIONAL**: worst loop pass ≈ 10.7 ms
  (estimated upper bounds) inside the 70 ms button budget (100 ms − 30 ms debounce); apply / telemetry_send call generated code the profiler cannot bound
  → a twin cycle count closes it. Priority preview: 5 tasks tie (100 ms, required).
- Tiers: UNO bare-c available (measured 3110 B flash / 513 B RAM vs cited 32256 / 2048), freertos blocked (2 KB SRAM refusal; kernel RAM undetermined),
  zephyr blocked (no AVR in Zephyr v4.4.2). C3: bare-c blocked (no bare template), freertos + zephyr available (kernel footprints undetermined).
  Synthetic missions recommend freertos (3 conflicting periodic + a blocking bus read) and zephyr (large) — the thresholds are labelled rules of the profiler.
- Doors `/api/missions/{name}/approach[?board&tier]`; page "Approach". After the merge: cmod 956, board 702, apps 129, manifests 8/9.
- Owed: measured per-atom cycle counts on the twin (closes "provisional"); the chosen-tier DerivedOverride write path.
- **Live on econ-core 2026-10-18** (tonight's merged slices): `/api/missions` 0.18 s; `/api/missions/uno-light-mission/{pin-profiles, colocation,
  approach}` ≈ 2 s each (cold derivation); `/api/atom-jobs/read-button/variants?board=arduino-uno-r3` 0.06 s; `/api/board/socs/atmega328p/profile-overlap`
  pwm-out + digital-out at pin = exclusive with its §14.3 / Table 14-2 / compare-output cites.
- **Incident 2026-10-18 night:** pol-core's root disk filled (0 MB) while sol-0's agent ran the full cmod selftest — cause: 16 finished agent worktrees
  in the scratchpad (two Angular ones ≈ 1.7 GB each with .angular/dist caches) + the screenshot driver's Chrome profiles never deleted from /tmp.
  Fixed: finished worktrees removed (`git worktree remove`), the driver now deletes its profile after each run; 7.9 GB free. RULE kept: remove an
  agent's worktree once its branch is merged; never leave a build cache behind.

## 14. ✅ sol-0 BUILT + MERGED 2026-10-18 (framework 42c3a65 + review 3d8965a; cli `pol capability solve`; sonnet agent)
- The attempt engine over hardware (board × package × USB interface × bench parts) → eligible tier (rt-0) → isotope variants per job (iso-0) → pin assignment
  via the ladder + pp-1 + claims, backtracking, least-specialised pins first, importance when pins run out; scored by the Mission's objective with the other
  shown; undetermined costs get a stated stand-in (never zero); every pruned branch recorded; `SolveRun` (inputs by sha256, replayable, deterministic).
- UNO light Mission (280 candidates, ≈2 s warm / 12–17 s cold): **minimum-resources** → poll button + GPIO LED + poll sense on the least specialised pins (LED D9,
  button A0, sense A1); the demo's interrupt plan is #3 (+0.071 resources, −10.7 ms cycle). **fastest-cycle** → button on D2/INT0. With `prefer: bench-wiring`
  + fastest-cycle → D2/INT0, D6, D3/INT1 exactly (the bench). D0/D1 refused by name (rung 8). D6 occupied → LED to D9; INT0+INT1 occupied → PCINT (worse by ≈1 µs);
  only SPI pins left → the SPI shift-register route on D13/D12/D10, flagged "needs a 74HC165-class part NOT on the bench", ranked below every buildable plan;
  too few pins → a "desired" Purpose loses its button, named. ESP32-C3: undetermined (no BoardPin/PinFunction rows), bare-c blocked by name.
- Judgement calls (his to overturn): pin SHARING off by default (knob `share_pins`) — pp-1 would let button + sense share a pin, wrong for distinct signals;
  "least specialised" = derived scarcity (A0/D9 cheapest because every UNO pin carries something); routes without atoms timed from counted instructions
  (mixed bases, said per candidate); the USB interface is attached per package (the ladder does not read it).
- Review fix (me): SolveRun was not registered in defClassList / feature_imports (manifests 7/9) → registered; cmod 1011/1011, board 702, hwnocode 163,
  apps 130, manifests 8/9. Owed: the pin view's "candidate" stage drawing a chosen assignment; measured cycles on the twin.
- **sol-0 live on econ-core 2026-10-18:** POST `/api/missions/uno-light-mission/solve` {fastest-cycle, prefer bench-wiring, UNO} → 201 in 5.4 s: 280 candidates,
  chosen "SPDIP / bare-c / LED gpio-out, button ext-interrupt, command uart-rx-interrupt, report uart-tx, **sense gpio-poll**" (same plan on the TQFP), 9.7 ms,
  resources 1.898. Note to check: the sense line comes out POLLED here, while the agent's bench-preferred scenario reported INT1 on D3 — read the score card's
  deciding difference (probably the 10.7 ms loop vs the INT1 cost under fastest-cycle) before calling it right. Phase `reset` and config-events doors 200.
  → Checked: the top candidates all tie at 9.7 ms (the Mission cycle is bounded by the USART send wait, not the sense route), and the tie is broken on the
  secondary objective — a polled sense uses fewer resources than INT1. Correct under the stated model because the sense Purpose carries NO latency criterion;
  if the D3 sense must witness every edge within N ms, that belongs in the Purpose's criteria (then INT1 wins by rule, not by preference).

## 15. ✅ fgm-5a BUILT 2026-10-18 (framework 6f75b63; merging) — three variants made real
| variant | template | flash / RAM (vs uno-light 3100 / 513) | twin proof |
|---|---|---|---|
| `uno-light-pcint` (button D4, LED D6) | `board/custom/firmware/uno/catoms/read-button/isotopes/pin-change-interrupt/template.c.j2` | 3154 / 520 (+54 / +7) | 3 presses on D4 flip the light, counted, source=button; D2 does nothing; a bounce counts once |
| `uno-light-analog` (button A0) | `…/isotopes/analog-threshold/template.c.j2` | 3124 / 521 (+24 / +8) | ADC ramp 200→4800 mV → 3 presses = a pure model; held-high and closed-from-boot count nothing |
| PWM LED (uno-sim-rig) | hal.c (existing) | 4310 / 491 | SET pwm_duty 25/50/100 → OCR0A 63/127/255 (duty within 0.5 points); the PD6 waveform itself not sampled |
- Each proof has a negative control (the check fails on firmware lacking the behaviour). Atom-only sizes for the engine: PCINT 258 B, analog 226 B (INT0 210 B).
- iso-0: the two buttons `declared` → `compiles` with measured costs; each route reads its own acceptance Scenario (`implemented_by.proof_scenarios`) →
  `proven-on-twin` from a passing ScenarioRun (selftested with in-memory runs). OWED: record the three ScenarioRuns on a live node (`pol faults run …`).
- sol-0 with D2,D3 occupied: minimum-resources unchanged (poll button A0 / LED D9 / poll sense A1); fastest-cycle now picks the PCINT button on A0 (10.06 ms).
- Identical-hex gate green (uno-light, uno-sim-rig, uno-button-clock + all 10 manifest configurations). hal.c gained one guard (`#if HAL_INT0 && !HAL_BUTTON_ROUTE`);
  the three graph projects re-rendered/built/proved. Catom layout kept under `custom/` (manifests rule). cmod 1069, board 742, firmwarefaults 188, ucd 34.
- **Live check of the candidate stage + Task Plan on econ-core 2026-10-18:** the pin view's "Candidate" stage draws the stored run (pickers, "Why these
  pins", proposed legs); the Task Plan door answers in 0.4 s with the five Tasks (4 agree, sense unchecked). FOUND: my POST put `prefer: bench-wiring` at the
  top level; the door only read `limits.prefer` and SILENTLY ran the default search (LED on D9, sense on A0). FIXED (framework, this commit): top-level
  prefer / occupy / only_jobs accepted like the GET, unknown body keys refused 422 by name; selftest: top-level prefer places D2 / D6 / D3. 56/56.

## 16. Next slices under the night go (recorded 2026-10-18 before building)
- **cyc-0 measured cycles on the twin:** simavr counts cycles; measure each atom/route's worst-path cycles per call (ISR entry→exit, loop steps) on the UNO
  twin with a recorded harness, store them as measured costs (CFunctionAtom / IsotopeVariant cost `measured`, with the run's inputs by sha256), and feed
  rt-0 (bare-c verdict loses "provisional" when apply / telemetry_send are bounded by measurement) and sol-0's fastest-cycle model (measured replaces
  counted/estimated where present, labelled).
- **fgm-5b sense routes + link-ups:** templates + twin proofs for `sense-led-line:gpio-poll` and `sense-led-line:pin-change-interrupt` (so the sense Task is
  checkable whatever route the engine picks); `HardwareSystem.task_plan` linked to the saved TaskPlan (hwsys rows + the Hardware System door); rt-0's
  "Task Plans come in fgm-3" preview text replaced by a link to the real plan.

## 17. ✅ fgm-5b MERGED 2026-10-18 (framework 85089eb) + cyc-0 BUILT (aeaf179; merging)
- **fgm-5b:** the sense-led-line catom (same §5b layout as read-button, JSON force-added): `uno-light-sense-poll` (D3 polled, D6→D3) 13792 / 1229 B and
  `uno-light-sense-pcint` (D8 = PCINT0, D6→D8) 13866 / 1231 B, on the button-clock app (the light app has no sense field — adding one would change LightState);
  twin: 4 presses → exactly 4 counted edges; no-jumper and wrong-pin controls → 0; fail-controls on firmware lacking the route. Existing hexes identical.
  Task Plan: all five Tasks AGREE (sense = `hal_sense_poll.hal_sense_read`, loop lane). `HardwareSystem.task_plan` linked (set on POST, derived on every
  read). rt-0's preview text points at the real plan. EFFECT on sol-0: the polled sense now costs its measured loop step (+348 µs), so under fastest-cycle
  + bench wiring the INT1 sense wins and the DEMO PLAN is rank 1; minimum-resources still picks polling.
- **cyc-0:** cycles measured on the twin (`--fn-cycles` on the -fno-inline build; `--isr-latency` for ISRs; loop gaps from the shipped hex), records in
  `board/custom/cycle_records/<variant>.json` with inputs by sha256. uno-light per call: apply_command 238–310, led_toggle 48–168, hal_rx_pop 14–68,
  telemetry_send ≈175 k (CPU part 13 936 = 0.87 ms; the rest is the USART wait), INT0 98–116, PCINT2 88–155, INT1 62–65, hal_adc_read 1686–3221.
  FINDING: simavr times a USART byte at 3000 cycles vs the chip's 1360 (UBRR 16, U2X) → measured sends include a wait ≈2.2× too long; records keep the
  CPU-only part separately. Worst loop pass: 10.97 ms on the twin, 5.44 ms at the chip's byte time; rt-0's argued 10.9 ms (110 B max frame, 55 B real).
  rt-0: bare-c no longer provisional (`fits-known`: every loop task measured; INT rates still outside the CPU share). sol-0: measured cycles preferred,
  basis labelled per candidate; the chosen plan's cycle 9.70 → 10.53 ms (the CPU work the bounds had missed).
