# Bench Solution simulation: Systems, Solutions, and stepping a whole bench (bss) - plan 2026-11-01

The user (2026-11-01): "we need the different solutions setup and to make it feasible to have complete systems and solutions based off of those
systems. That way we can step through the simulation of an operation of a particular Bench Solution, and see the firmware, physics (thermal
simulation and electrical flow at appropriately small stepping, smaller than the smallest thing that needs to be seen same rule as an
oscilloscope)." Then: "A Bench Solution should show what its stepping time is and what variable was the lowest resolution time-step that caused
that overall resolution."

Naming follows [systems-vs-solutions]: a System is a template with its choices still open; a Solution has every choice made, is bound to
the other Solutions, and can be simulated as a whole. A child row is named after its parent. Rows stay small and name each other; they never copy fields.
Bench Solutions are open air for now. A clip-on heat sink and a breadboard fan are allowed.

PLAN ONLY. The decisions in section 5 are the user's to make.

---

## 1. What exists (read 2026-11-01; reuse it, do not rebuild it)

| Piece | Where | What it is today | Its place in this plan |
|---|---|---|---|
| `BenchSolution`, `BenchConditions` | board (cfg-0) | references to a bench, a hardware solution, a firmware solution, a thermal solution (''), and the conditions | the whole that is stepped |
| `FirmwareSolution` | cmod | a `CGraph` + a board -> a build; the configurations (cfg) hang off it | Firmware Solution as-is |
| `CGraph` | cmod | catoms composed, with isotopes still open | the Firmware System (template) as-is |
| `HardwareSystem` + `SystemLink` | board | a SPECIFIC assembly (UNO + 16U2 + resistors + LED), participants and links | **misnamed by the rule**: it is a Hardware Solution (D-bss-1) |
| `HardwareSolution` | hwnocode | one no-code solution spanning hardware, bridge, backend and browser | **name clash**: it is cross-domain, not the bench's hardware (D-bss-1) |
| `Bench`, `BenchBoard` | board, electrodevice | the boards on the table | the Bench Solution's `bench` |
| twin (simavr) | board.custom.twin*, twin_sessions | the same .hex free-running at 16 MHz; pins injected, edges streamed | the firmware engine; free-running today, not cycle-stepped |
| ngspice | electrodevice.custom.ngspice_shared / spice_run, pcb decks | transient decks with `.temp` and per-part `temp=` (tmp-1..5) | the electrical engine |
| thermal | pcb `PartThermalModel` (Foster -> Cauer, tmp-3), plate FEM, electrothermal.settle | per-part temperature, the self-heating loop | the thermal engine |
| skew at the boundary | board.custom.clock_skew_run + uart_sampling (tmp-6) | the twin at f(1+e), UART bytes re-sampled bit by bit | already a two-domain coupling; it becomes one stepper's link |
| scope | instruments (osc arc): `ScopeChannel`, `WaveformCapture`, the emulated units | probes on bench lines; captures | the stepping view's traces use the same probe rows |

## 2. The rows (small, by level, referencing)

| Level | Row | Its one concern | References |
|---|---|---|---|
| template | `HardwareSystem` (new meaning, D-bss-1) | a board family + a circuit with part choices open (for example "an UNO-class board, an LED with R in 220..1k") | - |
| template | `CGraph` (exists) | the Firmware System: catoms composed, isotopes open | - |
| template | `ThermalSystem` | the open-air template: which mitigations are allowed (none / clip-on sink / breadboard fan), ambient range | - |
| template | `BenchSystem` | which Hardware, Firmware and Thermal Systems compose one bench concept | the three Systems |
| solution | `HardwareSolution` (D-bss-1) | the specific boards, parts and nets (what `HardwareSystem` holds today) | its `HardwareSystem` |
| solution | `FirmwareSolution` (exists) | the specific graph + board + configurations -> one .hex | its `CGraph` |
| solution | `ThermalSolution` | the specific mitigations (a named sink part with its cited Rth, a fan with its cited airflow, or none) | its `ThermalSystem`, `PartThermalModel` rows |
| solution | `BenchSolution` (exists; gains `system`) | the three Solutions bound + the conditions | its `BenchSystem`, the three Solutions, `BenchConditions` |
| derived | `BenchSolutionStep` | **the step it runs at, and the variable that set it** (section 3) | its `BenchSolution` |
| derived | `BenchSolutionStepTerm` | one candidate: one watched variable, its smallest feature, the rule, the step it asks for | its `BenchSolutionStep` |
| run | `BenchSolutionRun` | one stepped run: the locked .hex sha256, the step, the window, checkpoints | its `BenchSolution` |
| run | `BenchSolutionRunFrame` | the state at one recorded instant (only at breakpoints and checkpoints; traces are in captures) | its `BenchSolutionRun` |

**Complete**: a Bench Solution is "whole" only when each of its three Solutions exists and is complete, and each names a System that the
Bench System also names. What is missing is said in words and derived on read, never stored.

## 3. The step rule, and showing what set it (the user's second message)

"Smaller than the smallest thing that needs to be seen, same rule as an oscilloscope."

- **What needs to be seen** = the watched variables. The default is every line the firmware drives or reads, every net with a probe, and every
  part with a thermal model. A person can narrow or widen the watch list (a knob).
- **Each watched variable gives its smallest feature, by domain:**
  - firmware: one CPU clock cycle, 1/f_clk (62.5 ns at 16 MHz). Firmware is discrete, so this is a floor and not subject to the scope rule.
  - electrical: the fastest edge on the net (rise or fall time), derived from the driver's output resistance and the net's load capacitance
    (`t_10-90 ≈ 2.2·R·C`), from a cited datasheet edge time, or from the smallest RC time constant on the net.
  - thermal: the smallest time constant in the part's Cauer ladder (tmp-3), or the sink's and fan's own time constants.
- **The scope rule** turns a feature into a step:
  - bandwidth `BW ≈ 0.35 / t_rise` (single-pole);
  - sample rate `≥ k · BW`, giving step `Δt ≤ t_rise / (0.35 · k)`;
  - k is a labelled knob (default 5).
  - These are oscilloscope-practice numbers; they are cited before any code is written (derive or cite).
- **The Bench Solution's step** is the smallest step any watched variable asks for. `BenchSolutionStep` shows:
  - `step_s`;
  - `set_by`, the `BenchSolutionStepTerm` that won, in words. For example: "12.5 ns, set by D6 (LED line) rise time 22 ns: R_out 25 Ω ×
    C 400 pF, scope rule k=5".
  - every domain's own step beside it, so the person can see what would happen if that variable were unwatched.
- **Multirate**: each domain still steps at its own rate (thermal at its tau/10, not at 12 ns). The overall step is the finest RECORDED resolution
  and the rate at which the domains synchronise around events. Section 4 explains why this is feasible.
- A change to the watch list, a part, a configuration or the conditions re-derives the step. The step is never typed.

## 4. Stepping the three domains together (feasibility)

| Domain | Engine | How it steps | Couples to |
|---|---|---|---|
| firmware | simavr (as the twin; add cycle stepping: `avr_run` per instruction, and the GDB stub for breakpoints on source lines) | per instruction, i.e. per cycle count | electrical: pin levels out, analog levels and pin inputs in |
| electrical | ngspice as a shared library: EXTERNAL voltage sources driven by the firmware's pins, with the sync callbacks the ngspice manual documents for this (to be read and cited before code) | its own adaptive step, capped at TMAX = the step from section 3 | firmware (inputs/ADC); thermal (power per part) |
| thermal | the Cauer ladder (tmp-3) per part + the ThermalSolution's sink and fan; slow | at its own tau/10 | electrical: temperature fed back into part parameters (tmp-2's `temp=` / curves) at each thermal step |

- **Feasibility.** One second at 12.5 ns is 8×10⁷ points: too many to record whole.
- **The fix is a time window, as on a scope.**
  - A run has a window (start, length). Inside it, everything is recorded at the step.
  - Outside it, the firmware runs free (as the twin does today) and the electrical side holds its DC operating point.
  - ngspice's adaptive stepping spends effort only around edges anyway.
  - Checkpoints (simavr state + the circuit's operating point + temperatures) at the window's start make stepping backwards a deterministic replay.
- **The engines run where they already run**: simavr in prf-board-engines, ngspice on econ-core's libngspice, the thermal solve in-process
  (Cauer is cheap).

## 5. Decisions (recommended option first; each is the user's)

- **D-bss-1 - the two clashing names.**
  - (a, recommended) The board `HardwareSystem` (specific today) becomes `HardwareSolution`. The hwnocode `HardwareSolution` (cross-domain no-code) becomes
    `CrossDomainSolution`, a name its own docstrings already use. `HardwareSystem` is then free for the template. That is 13 + 8 non-test references
    to move, with a convergence step for stored rows.
  - (b) Keep both old names and add new rows `BenchHardwareSystem` / `BenchHardwareSolution`. Nothing moves, but the rule is broken in two places.
- **D-bss-2 - the default watch list.** (a, recommended) Every firmware-touched line + every probed net + every part with a thermal model. (b) Only probed nets.
- **D-bss-3 - the scope-rule k.** (a, recommended) 5, a labelled knob. (b) 10, the stricter SPICE habit.
- **D-bss-4 - cfg-4 (stepping with replay in CATOM_CONFIG_PLAN).** (a, recommended) It merges into bss-4 here, so stepping lives in one place.

## 6. Phases (each its own commit series on dev-electronics; selftests green; no deploy)

| Phase | What | Proof |
|---|---|---|
| bss-0 | names (D-bss-1) + the template rows `HardwareSystem` / `ThermalSystem` / `BenchSystem` + `ThermalSolution`; each Solution names its System; the "whole" check | the UNO light bench: Bench System `uno-light-bench`, Bench Solution `uno-light-on-desk` whole; remove the thermal solution -> "not whole: no Thermal Solution", in words |
| bss-1 | the step rule: `BenchSolutionStep` + terms, derived; shown on the Bench Solution | the UNO light: step and `set_by` named; unwatch that line -> the next variable sets it; a fan changes the thermal term only |
| bss-2 | the stepper: simavr cycle stepping + ngspice EXTERNAL sources + Cauer per part, synchronised; a window and checkpoints | a button press in a window: firmware edge at cycle N -> the LED net's rise traced at the step -> the LED's junction temperature after; replay from a checkpoint is identical |
| bss-3 | `BenchSolutionRun` doors: step / run-to / breakpoints (source line, a net crossing, a temperature) / back (replay); the views: source line + registers, scope traces (probe rows), part temperatures | a breakpoint on the LED write stops with the source line, D6 trace and the LED's temperature at that instant |
| bss-4 | a configuration change while stepping = rebuild + replay from the window's checkpoint (cfg-4, D-bss-4) | change the debounce mid-run -> new .hex sha, replay, the difference shown |
| bss-5 | the Bench Solution page: the whole check, the step and what set it, the stepping controls (theme tokens, click-toggle, no raw JSON) | the Chrome pass is owed and needs a deploy, which is the user's call |

## 7. Rules this plan keeps
Every number is derived or cited, otherwise it is a labelled knob. Established open solvers only (simavr, ngspice, the Cauer ladder). Small rows that reference each other.
Children are named after their parent. No real identifiers. Electronics work stays on dev-electronics. No deploys.
