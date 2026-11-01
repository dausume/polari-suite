# Temperature plan (tmp) — a PCB's circuit at a temperature

**Branch:** remote `dev-electronics` (electronics work never goes to `dev`).
**Started:** 2026-10-31.

## The ask, in the user's words

> "A number of parts have temperature tolerances and their drive and signal data may vary with temperature as well I believe, can you find if that
> is accurate and the plausibility of simulating the changes of signals and drive behavior with temperature simulation"

> "Build it starting with whole temperagure, since a background temperature being the basis is the norm anyways, then part level, and so on"

## Approach

Nothing new is modelled. ngspice's device models already carry their temperature terms. These include a diode's saturation current and band gap
(XTI, EG), a transistor's gain (XTB), a MOSFET's mobility and threshold, and a resistor's tc1 / tc2. Polari's job is only to say **which
temperature**: the whole board's (a `.temp` line), or a part's own (an instance `temp=`). The deck stays `pcb.custom.kicad_spice.build_deck`'s.
Runs are kept the way every run is (`SpiceRun` + `SpiceVector`), and each run now records its temperature.

What ngspice accepts was **probed on econ-core's libngspice** (KiCad 10.0.6) on 2026-10-31:

| Element | Per-part `temp=` |
|---|---|
| R, C, L, D, Q (BJT), J (JFET) | accepted |
| M (MOSFET), levels 1 / 2 / 3 / 6, VDMOS | accepted |
| M (MOSFET), BSIM: level 8 / 49, 14 / 54 | refused: "circuit not parsed" |
| X (subcircuit) | **crashes the library** ("ngspice.dll cannot recover"), so it is never written |

Parts that refuse a temperature of their own follow the board's, and the page says so.

An ideal R, C or L (with no tc1 / tc2) **does not change with temperature at all**. This is why a person can give a part its datasheet coefficients.

## Phases

### tmp-1 — the board's (background) temperature: BUILT 2026-10-31

**Code changes:**
- `kicad_spice.build_deck(rows, temp_c=, part_temps=, coefficients=)`:
  - adds a `.temp` line after the includes; a schematic's own `.temp` / `.options temp=` is then left out;
  - writes tc1 / tc2 on an R, C or L. A person's figure wins over the symbol's Sim.Params.
- New fields on `SpiceRun`: `temp_c`, `temp_mode` (default | board | parts), `part_temps_json`, `sweep`.
- New class `PartTemperatureBehaviour` (PCB_CLASSES = 29):
  - holds the rated operating range and tc1 / tc2 in ppm/K;
  - `given` lists what was given, because 0 is a real value;
  - a board-free row keyed by part_key applies to every matching part.
- `pcb.custom.temperature_inputs`: parts / quantities / set / clear / put_behaviour (with citation) / coefficients.
- `pcb.custom.spice_temperature`: grades / reach / run_at / sweep / compare / trend / overlay / ratings.

**Grades:**
- *commercial* 0..70 °C and *industrial* −40..85 °C are vendors' conventions, and are labelled as such.
- *automotive grades 0 / 1 / 2* are the AEC-Q100 operating-temperature grades.
- A sweep runs at the low end, 25 °C and the high end.

**Doors** (`pcb.pcb_temperature_api`):
- simulate-at, temperature-sweep (a temps list, or `/{grade}`);
- temperature-sweep GET (each net at each temperature, plus the change from 25 °C);
- temperature-reach, temperature-ratings, temperature-parts;
- temperature-inputs PUT / DELETE, temperature-behaviours POST (with citation).
- Worker-posted runs (`POST /api/pcb/{board}/runs`) may carry their `temperature`.

**Page:** a new Board Details tab, **Temperature**:
- run at one typed temperature;
- sweep a grade with its row button;
- what responds;
- each net across the sweep, with trend and overlay charts;
- each part's range and coefficients, edited in place;
- the ratings.

**Frontend:** class-rows-table gains `editSignedField`, so a row can take a negative number (−40 °C). This is the one generic change, with a spec.

**Reference runs:** `custom/reference/kicad10_sim_{rectifier,sallen_key}_temps.json`, from our own decks on econ-core.
- The rectifier's peak rises by about +1.9 mV/K, because a hot diode drops less voltage.
- The Sallen-Key passband moves by under 1e-6 from −40 to 85 °C. Its R and C are ideal, and only the op-amp model responds. The op-amp's cold response deep in the stop band differs by more than 10×.

### tmp-2 — each part at its own temperature: BUILT 2026-10-31

- `thermal_transient.transient(probe_all=True)`: every placed part without power joins as a 0 W source, so the board-over-time solve also gives the board under it. Each row also carries end-of-run rises.
- `spice_temperature.part_temperatures(ambient, mode)`: background + rise. The rise is the part's junction (board under it + datasheet Foster Zth) when a model is given, else the board under its pads.
  - mode `final`: the end of the run.
  - mode `peak`: each part's own hottest moment. This is not one instant, and the page says so.
- `run_parts`: the board at the background, and each part at its own temperature wherever ngspice allows one.
- Recorded check: D1 alone at 100 °C on a 25 °C board lands between the whole board at 85 °C and at 125 °C, within 1 mV of the straight line between them.
- **Page:** a new tab, **Parts at their own temperature**, with two run rows (end of run / own peak) and each part's temperature.

### tmp-3 — the circuit heats itself (two-way): BUILT 2026-11-01

**The ladder.**
- `materialsScience.engines.thermal_cauer.foster_to_cauer` turns a datasheet's Foster pairs into the Cauer ladder with the same Zth(t).
  It uses the textbook continued-fraction (Cauer I) expansion, computed in exact rational arithmetic.
- Checked two ways:
  - an independent eigen-solution matches Zth(t) to 1e-12 for 1, 3 and 5 stages;
  - ngspice, running the ladder as an RC circuit on econ-core, matches the Foster Zth within 1e-4 from 1 ms to 10 s.
- `fem_plate_transient(ladders=)` solves the ladder inside the board's own linear system.
  - The power enters the junction node.
  - The last R joins the board's mean temperature over the part's area.
  - The energy balance holds to 1e-12.
- `thermal_transient(form='cauer')` is now the default; `form='foster'` keeps bob-3g's form for comparison.
  - With the ladder, the board warms only as fast as the part lets the heat out.
  - A single 60 s pulse now peaks the board about 3 s *after* the pulse ends; the Foster form peaked it at 60 s.
  - Both forms end at the same steady junction.

**Each part's power.**
- `build_deck(save_power=True)` keeps the device vectors: `@q[p]` and `@m[p]` for transistors, `@d[id]` for diodes.
- A diode's `@d[p]` reads **inf** in KiCad 10's libngspice (probed 2026-11-01), so its power is (Va − Vk) × id.
- Check: the transistor's ngspice power equals V_CE·I_C + V_BE·I_B from the run's own source currents (1e-9).

**The loop.** `pcb.custom.electrothermal.settle` runs the circuit at each part's temperature, reads the powers, heats, and runs again.
- Where the heat comes from:
  - a board with a layout: the steady plate FEM plus the datasheet Rth j-board;
  - a schematic only: the datasheet Rth j-a, which is measured on the datasheet's test board (said).
- Verdicts:
  - **settled**: nothing moves more than 0.05 K;
  - **runaway**: each pass is hotter by more than the last, i.e. the loop gain is above 1. This is also the real part's stability condition, so a diverging loop is the runaway, not a numerical artefact;
  - **not settled**, **stopped** and **nothing heats** each say why.
- Knobs: tol 0.05 K, at most 12 passes, relax 1, cap 400 °C.

**Recorded on econ-core:**

| Case | Result |
|---|---|
| Rectifier, D1 with the **cited** Vishay 1N4148 R_thJA 350 K/W (Doc 81857 Rev. 1.6) | settles on pass 1 (+3 mK) |
| ngspice default NPN, fixed V_BE, synthetic 200 K/W | **runaway**: changes 15.8, 16.0, 29.2 K; gain 1.8 |
| The same with a 100 Ω emitter resistor | settles at 43.1 °C, gain 0.02 |

**Doors and page:**
- `POST/GET /api/pcb/{board}/self-heating`.
- A Board Details **Self-heating** tab: run the loop at a typed background temperature, and see each pass.
- The newest result is kept in this process; the runs themselves are kept as SpiceRuns.

**Not done:** a pulsed power's electro-thermal transient is not iterated. Thanks to time-scale separation, each pass is the circuit settled at fixed temperatures.

### tmp-4 — timing at a temperature: BUILT 2026-11-01

`board.custom.timing_drift`, cited throughout. A datasheet's *bound* over a range is used as a bound: its worst case anywhere inside the range, and **unrated** outside it. It is never drawn as a curve.

**Sources:**
- **CSTCE16M0V53-R0** (the UNO R3's ATmega328P clock): ±0.5 % initial + ±0.3 % over −20..80 °C + ±0.2 % aging, all max.
- **ATmega328P RC oscillator:** factory ±10 % at 25 °C only; user-calibrated ±1 % over −40..85 °C.
- **ATmega328P USART** (DS40002061B):
  - Table 20-1 equations;
  - Tables 20-2 and 20-3 for the receiver;
  - Table 20-7 for the 16 MHz examples.
  - The divisors derived from the equations equal Table 20-7 to its rounding.
  - The datasheet's own U2X 0, D = 8 row disagrees with itself: Rslow implies −4.64 %, but the row prints −4.54 %. The tighter −4.54 % is used, and said.
- **SN74LVC245A** (SCAS218X) and **SN74AHCT125** (SCLS264R): max t_pd per datasheet temperature column.

**Results:**
- 9600 baud fits anywhere in the rated range.
- 115.2 k with U2X is inside the receiver's window (+3.12 % worst against +3.90 %) but beyond the recommended ±1.5 %.
- At −40 or 85 °C the resonator is unrated.

**Page:** a **Timing at temperature** tab with the clock, the UART link and the logic delays, for the UNO and the two logic part boards; other boards say why there's nothing.

**Not done:** "fed into the firmware simulation" is still owed. simavr runs one exact clock, so this is a budget beside the runs (ClockSkewFault forcing is sc-3).

### tmp-5 — parts with no SPICE model: BUILT 2026-11-01

**Class and curve kinds.** New class `PartTemperatureCurve` (PCB_CLASSES = 30), with three kinds:
- **points**: a table's rows, straight lines between them, and never extrapolated;
- **linear**: one stated value plus one stated coefficient;
- **band**: a class bound, read as a low and a high corner.

**The cited catalogue** is code-owned and seeded, like the fab rules:

| Curve | Source |
|---|---|
| SQ2310ES R_DS(on) max: 0.030 / 0.045 / 0.054 Ω at 25 / 125 / 175 °C | Vishay S21-1074 Rev. C |
| TLCY5200 V_F: 2.1 V − 3.5 mV/K over −40..100 °C | Doc 81354 Rev. 1.6; the straight line is ours, said |
| X7R, X5R: ±15 % | KEMET, EIA-198 |
| C0G: ±30 ppm/K | KEMET, EIA-198 |

**In the circuit:**
- A curve can be given to a part; a part whose value is the curve's part number gets it automatically.
- `build_deck(values=)` puts an R's ohm curve, or an R/C/L band corner, into the deck.
- Recorded: the rectifier at 85 °C with C1 at the X7R low corner (85 nF).

**Doors and page:**
- Doors: `/api/pcb/temperature-curves`, `/api/pcb/{board}/temperature-curves[/{ref}[/{quantity}]]`, `/api/pcb/{board}/simulate-curves`.
- A **Temperature curves** tab.

**Also found:** the UNO's Z1/Z2 (Bourns CG0603MLC-05E) and its successor's datasheet (CGA0603MLC-05E, REV. G 05/26) both give V_C 30 V by TLP **with no current**, so they stay unmodelled. The dead datasheet URL was replaced with the live REV. E 07/20.

## Owed

- **The Chrome pass** of all five temperature tabs (Temperature, Parts at their own temperature, Self-heating, Temperature curves, Timing at temperature). It needs a deploy, which is the user's call.
- **tmp-4 into a firmware run:** needs a clock that can skew (sc-3 / Renode).
- **Live runs:** this host has no libngspice, so simulate-at / sweep refuse here in words. econ-core has it, so the next step there is the worker route or an isle deploy.
- **A real part's** cited rated range and TCR, as an example. The tests use synthetic values.
