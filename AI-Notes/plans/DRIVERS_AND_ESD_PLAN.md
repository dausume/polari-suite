# Drivers and ESD plan (drv / esd)

**Branch:** remote `dev-electronics`.
**Started:** 2026-10-31.
**Status:** drv-0 + drv-1 BUILT 2026-10-31 (with mounting by position); drv-2 (four more cited parts, judged fixes, Mount here) + drv-3 (whole-part budgets) BUILT 2026-10-31; esd-0 .. esd-5 BUILT 2026-10-31.

## The ask, in the user's words

> "Okay another thing to account for are Drivers (meaning current deivers and converters, that handle correcting needs for drive in terms of
> currents) as a type of component we can put into place to fix issues with drive. And then we also need to be able to flag different pieces as ESD
> protection areas, which we need to establish simulations for testing where we emulate ESD events and check that the drive conditions handle it
> smoothly and do not break the circuits"

## Where this attaches (what exists today)

- **Bench checks** (`board.custom.bench_nets.check`): work on footholds only. They report:
  - `supply-conflict`;
  - `supply-to-ground`;
  - `over-voltage`.

  There is **no current-demand check**: a foothold carries what it can *give* (`source_ma` / `sink_ma`), not what it *draws*.
- **Board-level circuit checks** (`board.custom.electrical_check`, `electrical_hw`) already find drive problems on a board:
  - (a) LED current vs the pin's cited max mA;
  - (f) VOH under load;
  - (g) pin-group budgets.
- **A PCB's circuit** runs in ngspice from Polari's own deck (`pcb.custom.kicad_spice.build_deck`), with temperature from tmp-1 / tmp-2. Every run is kept (`SpiceRun` / `SpiceVector`).
- **Existing ESD facts:** the UNO's ESD varistors are already cited in `board.custom.uno_schematic_paths`: Z1 / Z2, CG0603MLC-05E on D− / D+.

## Drivers (drv)

**What a driver is here:** a part placed between a weak source and a demanding load, or between two voltage domains, that corrects the drive.

| Kind | Fixes |
|---|---|
| Low-side switch / Darlington array (ULN2003A) | load current far above a pin's limit |
| Level shifter (unidirectional buffer with TTL inputs, or bidirectional) | `over-voltage`, a too-low logic level |
| Buffer / line driver | fan-out, a long line |
| Gate driver | a MOSFET gate's charge |
| Constant-current LED driver | an LED string at a set current |
| High-side switch | switching the supply side |
| Converters: LDO, buck, boost | a supply at the wrong voltage, or not enough current |

**D-drv-1 — RULED 2026-10-31.** The user: "I suppose yes, that way we can define custom drivers like mini boards and enable placin boards with footprints onto other boards?" A placed driver IS A BOARD ON THE BENCH, under a new definition kind `part`. Its footholds come from its datasheet contract, per channel:
- **input side:** direction `in`, the cited on-threshold, and the cited input current as a new foothold field `draw_ma`;
- **output side:** direction `out`, with its cited sink / source limits;
- **supply / common pins:** direction `supply`.

The existing net checks then apply unchanged. A level shifter's two sides are two separate nets, so an `over-voltage` between them disappears. This matches the ruling that dev boards, breadboards and PCBs are equal Boards: a driver breakout is the same kind of thing.

### Phases

**drv-0 — classes and the first cited catalogue part**
- New class `DriveComponent`: kind, part number, channels, per-side contract (on-threshold V, input current mA, output sink / source mA, output voltage limit, supply range), the group budgets, rated temperatures, and `document` / `page_table` / `url` / `origin`.
- First part, cited from TI **SLRS027T** (ULN200x / ULQ200x, December 1976, revised March 2025):
  - **Darlington arrays:** 7 channels, open collector with common-cathode clamp diodes to COM; the ULx2003A has a 2.7 kΩ series base resistor "for operation directly with TTL or 5V CMOS devices" (§3).
  - **§5.1 absolute maximums:**
    - collector-emitter voltage 50 V;
    - input voltage 30 V;
    - peak collector current 500 mA;
    - output clamp current 500 mA;
    - **total emitter-terminal current −2.5 A** (a group budget across channels);
    - operating free-air temperature −40..70 °C (ULN200xA);
    - junction temperature 150 °C.
  - **§5.6 ULN2003A at 25 °C:**
    - V_I(on) max 2.4 V at I_C 200 mA, 2.7 V at 250 mA, 3 V at 300 mA (V_CE = 2 V);
    - V_CE(sat) typ 1.0 / max 1.3 V at I_C 200 mA, I_I 350 µA;
    - input current 0.93 typ / 1.35 max mA at V_I 3.85 V;
    - clamp V_F typ 1.7 / max 2 V at 350 mA.
  - **§5.2 ESD ratings:** HBM ±2000 V (ANSI/ESDA/JEDEC JS-001); CDM ±500 V (JESD22-C101). These are used by esd below.
  - **§5.4:** R_θJA 88.6 °C/W (SOIC-16). This also feeds the thermal tabs (bob-3c / bob-3g).
- Further catalogue parts each need their own datasheet before entry: a TTL-input buffer for 3.3 → 5 V, an LED driver, an LDO and a buck. Nothing is entered from memory.

**drv-1 — drivers on the Bench**
- Definition kind `part` added to `board.custom.footholds.KINDS`, with footholds derived from a `DriveComponent`.
- `BenchBoard` rows for a placed driver.
- A new foothold field `draw_ma` (−1 = unknown), and a new net finding, `drive-shortfall`: what the net's members draw is more than what its driving member can give. The finding names both numbers and their sources.
- Group-budget finding: the sum of channel currents against the part's total. For the ULN2003A that is 2.5 A.

**drv-2 — suggestions**

For each `over-voltage` / `drive-shortfall` / supply finding, list the catalogue drivers whose cited contract fixes it, each with the evidence (knobs and suggestions rule). Placing one is a single action on the Bench page.

**drv-3 — drivers inside a PCB**

In a KiCad design a driver is an ordinary part with a SPICE model, either the vendor's or a cited subcircuit. Its deck runs as today, and the temperature tabs apply.

### Built 2026-10-31 (drv-0, drv-1)

**Classes and catalogue**
- `PartBoard`: drivers, loads and modules. It holds the cited seed `uln2003a-n` and custom definitions (`POST /api/board/parts`, origin custom).
- Definition kind `part`: footholds come from the pins, with the new foothold fields `draw_ma`, `on_volts` and `max_volts`.

**Mounting by position:** `board.custom.bench_mount`.
- A child Board is put at x, y and a rotation on a parent Board. Every pin lands on the parent foothold under it, or the mount is refused in words. A refusal names pins that land nowhere, two pins in one hole, or pins the parent joins: a DIP that does not straddle the trench shorts opposite pins.
- This one mechanism covers a DIP on a breadboard, a breakout on a PCB header footprint, and a shield on a dev board.

**Net findings**
- `drive-shortfall`: the draw against the driving pin's source current, or its sink current for an open collector.
- `under-voltage`.
- `over-voltage` against `max_volts`.

**Suggestions:** drive fixes from the catalogue, each with its evidence.

**Doors**
- `/api/board/parts`;
- `/api/board/benches/{bench}/parts`, `/mount` and `/drive-fixes`.

**Pages**
- Bench page: a "Drivers and parts" tab.
- Board Details: summary and pins for a part.

**Selftest:** `board_part_boards_selftest`. The UNO D6 (20 mA) driving a synthetic 300 mA load is a shortfall. With a ULN2003A mounted across the trench, both nets come back clean.

**Still owed**
- Group budgets (the 2.5 A total needs per-channel currents, so drv-3 / SPICE).
- More cited catalogue parts.
- A mount form on the page (the API only for now).
- The Chrome pass.

## ESD protection areas (esd)

**What gets flagged:** a new class `EsdProtectionArea` on any Board definition. It records:
- the scope (a foothold, a net, or a part's pins);
- the protection parts in that area (TVS diodes, varistors — refs, e.g. the UNO's Z1 / Z2);
- the standard and level it must survive;
- the protected pins' absolute maximum (cited, or −1 with the reason) and the chips' own cited ESD ratings (e.g. the ULN2003A's HBM ±2 kV);
- the recovery criterion.

**ESD source models.** Each is an established network named by its standard, not invented:

| Model | Network | Levels |
|---|---|---|
| **HBM**, ANSI/ESDA/JEDEC JS-001 | 100 pF discharged through 1.5 kΩ (τ = 150 ns) | 500 V / 1 / 2 / 4 kV |
| **IEC 61000-4-2** (system-level contact / air) | storage 150 pF, discharge 330 Ω | contact 2 / 4 / 6 / 8 kV (levels 1-4); air 2 / 4 / 8 / 15 kV |
| **CDM** (JESD22-C101 / JS-002) | the device itself charged | later |

- **HBM:** for parts handled during assembly.
- **IEC 61000-4-2:** what a product's connector has to survive in use. A plain 150 pF / 330 Ω network reproduces the standard's main discharge but **not its sub-nanosecond first current peak**. The page will say so until a published, waveform-matched gun network is adopted and cited (esd-4).
- **CDM:** a different mechanism; later.

**The simulation** runs on a PCB's deck, built from Polari's rows:
- The source network is added on the flagged net. ngspice voltage-controlled switches (`S` elements, model `sw`) let the capacitor charge before the event and discharge into the net at `t_event`, so the circuit starts from its real operating point.
- A **baseline** run of the same deck without the event is kept beside it.

**The checks** answer the user's two questions:
1. **"Do not break the circuits":** each protected node's peak voltage against its absolute maximum, and each protection part's peak current and energy against its cited rating (e.g. I_PP). Any exceedance is a refusal, naming the number and its source.
2. **"Handle it smoothly":** recovery. After the event, every protected net returns to within a tolerance of the baseline by `t_recover`. This is a knob (D-esd-2), shown with the waveform.

### Phases

**esd-0 — classes and source models**
- `EsdProtectionArea`, the source-model table (above, each with its standard named), and run fields for an ESD event: model, level, net, `t_event` and the baseline run.

**esd-1 — events on a PCB deck**
- Injection, baseline, evaluation; runs recorded on econ-core's libngspice for the selftest (the tmp-1 pattern).
- Expected first result on the rectifier demo: C1 (100 nF) on /rect_out absorbs a 2 kV HBM charge (100 pF × 2 kV = 0.2 µC → about 2 V), while /signal_in sees the full spike through R1. To be confirmed by the run, not assumed.

**esd-2 — the Board Details "ESD" tab**
- The areas (flag a net, foothold or part; edit in place), "run an event" (model × level per area, row button), results per protected node, and the waveform chart against the baseline.

**esd-3 — protection parts from datasheet numbers**
- A TVS diode as a diode model with breakdown BV / IBV from the datasheet's V_BR at I_T, checked against its V_C at I_PP. A varistor modelled the same way, or by a vendor model.
- Every number cited; the CG0603MLC-05E already referenced for the UNO is the first candidate.

### Built 2026-10-31 (esd-0, esd-1, esd-2)

**Areas**
- New class `EsdProtectionArea` on any definition: scope net / foothold / part; the test (model, level); `abs_max_v`; the recovery knobs (5 % / 50 mV / 10 µs).
- `board.custom.esd_areas`: flag, click-toggle, unflag, edit one number. Doors: `/api/board/esd-areas/...`. An area's name carries its net, which can contain a slash, so the doors take names in the body.

**Events** (`pcb.custom.esd_events`)
- The standard network is switched in at `t_event`, a quarter of the deck's own `.tran` by default. A 0 V meter in series measures the discharge current.
- A baseline run uses the same deck with the network charged to 0 V. Both runs are kept, with a new `SpiceRun.event_json` field.
- Results are recomputed from the kept vectors: each node's peak, its rise over the baseline, the break check against the abs max (undetermined when none is given), the recovery time against the criterion, and an overall verdict.
- Chart: every solver point within 50 µs of the event, plus a stride elsewhere.
- Doors: `/api/pcb/esd-models`, `/api/pcb/{board}/esd-run`, `/api/pcb/runs/{run}/esd-results|esd-chart`.

**Board Details "ESD" tab:** pieces to flag (Flag / unflag), areas (Run event, which then selects the new run), the area's numbers, the networks, the runs, the verdict, each node, and the chart.

**Checked on econ-core's libngspice:** the deck's own time step resolves the HBM event. It gives the same peak and current as a forced 2 ns step: 1.332 A = 2000 V / 1500 Ω.

**Recorded rectifier results** (reference `kicad10_esd_rectifier.json`)
- /rect_out: C1 (100 nF) swallows the 0.2 µC, so the node rises about 2 V. It is still about 0.47 V high at the end of the run, so it does not recover in 10 µs.
- The diode anode peaks at 3.43 V and comes back within the criterion after milliseconds.

**Still owed**
- esd-3: TVS / varistor models from cited V_BR / V_C / I_PP, plus the protection part's own current.
- esd-4: the waveform-matched IEC network.
- esd-5: foothold-level events for dev boards.
- The Chrome pass.

### Built 2026-10-31 (esd-3, esd-4, esd-5; drv-2, drv-3) — the user: "go ahead on those"

**esd-3 — protection parts** (`ProtectionPart`, `board.custom.protection_parts`)
- Cited seed: **SMBJ5.0A** (Bourns SMBJ datasheet REV. 09/20: V_BR 6.40 / 7.00 V at 10 mA, V_C 12.0 V at I_PP 326.5 A for 8/20 µs, V_F 3.5 V at 50 A) and the UNO's **CG0603MLC-05E** (Bourns REV. A 11/18: V_T 300 V and V_C 30 V typical, by TLP).
- The TVS's ngspice diode is DERIVED: BV = V_BR max, IBV = I_T, RS and N solved so the model lands exactly on the 8/20 µs clamping pair and on the forward pair (checked to 1 mV). No capacitance is modelled (it's given only as a graph), which, if anything, overstates the peak.
- Refused in words: a snapback polymer (the CG0603), a bidirectional TVS and a varistor. Each needs the vendor's model.
- An area's `protection_parts` are placed from the shocked net to ground in both runs, each through a 0 V meter, and each peak is checked against its I_PP. Decks with a clamp use Gear integration: the trapezoidal rule rang ±0.2 A around the 1.33 A HBM current.

**esd-4 — IEC 61000-4-2's own current** (`iec-contact-waveform`)
- The standard's equation (2008 edition, §6.2, under Figure 2) reproduces Table 3 at 4 kV: 14.9 A peak, 0.81 ns rise, 8.0 A at 30 ns, 4.0 A at 60 ns.
- It is sampled as a PWL source. On econ-core's libngspice the measured peak is 14.92 A against Table 3's 15 A.
- Caveat: it is a forced current, so it overstates the voltage at a high-impedance net.

**esd-5 — dev-board pins** (`board.custom.esd_footholds`): on a board with no circuit, a foothold area runs on the pin alone.
- The circuit is the pin's capacitance (`pin_cap_pf`, a knob, default 10 pF), held at its own level through `hold_ohm` (a knob, 1 MΩ).
- The area's protection parts and the same source and baseline are added. The absolute maximum is the area's, otherwise the foothold's `max_volts`.
- Doors: `POST /api/board/esd-areas/run` (any area), `/protection` (toggle a part) and `GET|POST /api/board/protection-parts`.

**Recorded runs** (`kicad10_esd_protection.json`)
- **Rectifier with the SMBJ5.0A:** the 100 nF holds the net at 2.8 V, below breakdown, so the TVS carries picoamps.
- **The UNO's DIGITAL_L:7, pin alone, HBM 2 kV:** 1814 V, so it breaks.
- **The same pin with the SMBJ5.0A:** 7.15 V, the TVS carries about 1.3–1.5 A (0.46 % of its I_PP), and it **still breaks** against the ATmega328P's 5.5 V absolute maximum. A 5 V TVS clamps above a 5 V chip's maximum.

**drv-2 — four more cited parts, in D-drv-2's order:**
- SN74AHCT125 (SCLS264R);
- TLC5916 (SLVS695D);
- LM1117-3.3 (SNOS412Q);
- LM2596-5.0 (SNVS124G).

Supporting changes:
- **New fields:** `PartBoard.out_volts`, `needs`, and role `regulated`.
- **Per-pin overrides:** for example, the TLC5916's SDO is 1 mA, and a regulator's VIN has its own minimum.
- **Net checks:**
  - a regulator's input below its minimum is under-voltage;
  - with no driving pin, the one rail that gives current is held to its source_ma.
- **Fixes are judged against every number, with `fits`.** For example, the AHCT125 fixes 3.3 V into the TLC5916's 3.5 V input but not 5 V into a 3.6 V pin. The LDO fixes a starved 3V3; the bare LM2596 does not (5 V, and it needs its inductor).
- **Mount here:** `bench_mount.placements` (a spatial index) lists every clean position. The ULN2003A has 46 on a half breadboard (23 columns × 2 orientations); the LM2596 has none (1.7 mm pitch).
- **Doors:** `GET /mount-options?child=` and `/part-budgets`.

**drv-3 — whole-part budgets** (`part_boards.budgets`): seven 400 mA loads on a ULN2003A are fine pin by pin but total 2.8 A, over its 2.5 A, so each gets a group-budget row.

**Selftests**
- `pcb_esd_protection_selftest` (8 checks);
- `board_part_catalogue_selftest` (8 checks).

**Still owed**
- Bidirectional TVS and varistor models (vendor models);
- CDM;
- a down-shifter in the catalogue (74LVC-family, 5 V-tolerant inputs);
- a buck MODULE as a part;
- the Chrome pass.

**esd-4 — the IEC 61000-4-2 waveform-matched gun network** (a published one, cited), replacing the plain RC for system-level levels. Built as the standard's own current equation (above).

**esd-5 — foothold-level ESD for dev boards** (no deck)
- The foothold's protection part + the chip pin's cited input capacitance and ESD rating, as a small deck per foothold.
- The Bench then flags footholds that are exposed (a connector on the bench edge) with no protection.

## Decisions — RULED 2026-10-31

D-drv-1: the user's words are quoted above. For the rest, the user said "go with your recommendations otherwise". So D-drv-2, D-esd-1, D-esd-2 and
D-esd-3 are as recommended in the table below.

## Decisions (as recommended)

| Decision | Recommendation |
|---|---|
| **D-drv-1** a placed driver is a Board on the Bench (definition kind `part`) | yes |
| **D-drv-2** the catalogue order after the ULN2003A | TTL-input 3.3 → 5 V buffer, constant-current LED driver, LDO, buck |
| **D-esd-1** standards first | HBM (JS-001) + IEC 61000-4-2 contact; CDM later |
| **D-esd-2** default recovery criterion (a knob) | within 5 % of the baseline (or 50 mV, whichever is larger) by 10 µs after the event |
| **D-esd-3** where ESD areas live | on the Board definition (all three kinds), with the Bench reading them for exposed footholds |

## Order

esd-0/1 and drv-0/1 are independent; build them in parallel slices. drv-2 and esd-2 follow. esd-3/4/5 and drv-3 deepen the models.
