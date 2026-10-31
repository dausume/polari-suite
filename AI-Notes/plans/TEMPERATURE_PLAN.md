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

### tmp-3 — two-way coupling: NEXT, not built

- The run's powers would change the temperatures, iterating until they settle. This catches self-heating and thermal runaway.
- It needs the datasheet network in Cauer form (Foster stages are not physical nodes), plus a relaxation loop: SPICE → powers → board FEM → temperatures → SPICE.
- The electrical (µs–ms) and thermal (s–min) time scales separate, which is why a relaxation loop is plausible.

### tmp-4 — timing drift into the firmware simulation: planned

- Crystal ppm vs temperature (curves from datasheets), internal RC oscillator drift (datasheet % over temperature and voltage), and logic propagation delay vs temperature.
- These would be fed into the firmware / bench simulation, so a hot or cold board can show UART baud error or a missed timing.

### tmp-5 — parts with no SPICE model: planned

- Datasheet curves entered as cited tables, then applied by interpolation. Examples: normalised R_DS(on) vs T_j, V_GS(th) vs T, LED V_F and light output vs T, capacitor derating (X7R / Y5V).
- This is the same "derive or cite" rule as the Foster stages.

## Owed

- **The Chrome pass** of both tabs. It needs a deploy, which is the user's call.
- **Live runs:** this host has no libngspice, so simulate-at / sweep refuse here in words. econ-core has it, so the next step there is the worker route or an isle deploy.
- **A real part's** cited rated range and TCR, as an example. The tests use synthetic values.
