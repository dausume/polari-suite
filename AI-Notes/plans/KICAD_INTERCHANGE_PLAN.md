# KiCad interchange (kxc) — Polari is the source of truth

## 1. The ruling (his words, 2026-10-30)

> "we should keep polari as the source of truth, but make it so we ensure we encapsulate everything KiCAD has as well, so we can
> ingest files coming from KiCAD, since it sounds like fully two way design is not feasible. We should make what exports we can
> from polari to kiCad possible happen, but keep polari and our structuring as the focus"

Context: econ Codex's assessment (econ `~/collab/electronics-kicad-review-2026-10-30/ASSESSMENT.md`, CX-032) recommended the
opposite (KiCad's native files authoritative, Polari a sidecar). His ruling overrides it. What we keep from that review: its gap
list, its fixture ladder, and "never silently drop — say what was not understood".

So:
- **Polari rows are the design.** KiCad is an *input* (ingest) and an *output* (export), not a peer to synchronise with.
- **Ingest encapsulates EVERYTHING.** Every file of a KiCad project is kept byte for byte (an artifact with its sha256). Every element of
  every `.kicad_sch` / `.kicad_pcb` is either a TYPED Polari row or counted as PRESERVED-ONLY in a coverage row. Nothing is dropped
  silently. Typed coverage grows slice by slice until preserved-only is empty for the things a design needs.
- **Export does what it can.** Polari → KiCad files (schematic, symbols with Sim fields, netlist, an unrouted `.kicad_pcb`), each
  validated by KiCad itself (ERC/DRC, netlist re-export compared to our graph). What cannot be expressed is said in the export's report.
- **No sync.** Re-ingesting an edited KiCad project produces a NEW ingested revision plus a diff against the Polari design; a person
  (or a later rule) adopts changes into the Polari rows. No merge engine, no native-file editing in place.

### His addition (2026-10-30): encode what has no direct conversion

> "note if there are not direct conversions between KiCAD and polari data, we can attempt to encode that data into standard label and description
> data in KiCAD, for things where it is critical"

So, on EXPORT, Polari data with no KiCad equivalent but critical to keep rides in KiCad's own standard places: hidden symbol PROPERTIES with a
`Polari.` prefix (as KiCad itself keeps `Sim.*`: Polari.Board, Polari.Definition, Polari.Connector, Polari.Drive - logic V / source and sink mA and
their basis, Polari.Firmware - which variable uses the pin and how, Polari.Source - the row and its sha), net LABELS (names) and the title block's
comments / the symbol Description. On INGEST those fields are read back (they already survive: SchematicSymbol.properties_json keeps every property),
so a Polari export that went through KiCad comes back with its identity and its critical data. Rule: only what is CRITICAL (safety, identity, drive),
never a dump of every row.

## 2. Where we are (kxc-0, 2026-10-30)

- Board netlists checked against KiCad 10's own libraries; importer goes by package pin number; C3 netlist names KiCad parts;
  `board_c3.kicad_devkit_pin`; `board_kicad_libs_selftest`.
- Headless on econ: kicad-cli 10.0.6 → SPICE → libngspice (no ngspice binary there).
- Known gaps (inventory + Codex): schematic nets only counted; reused child sheets skipped after the first instance (walk by filename);
  placed-symbol properties mostly dropped (Sim.* included); `.lib` / `.wbk` / `.kicad_prl` not read; ingested net volts default 0.0
  (must be UNKNOWN); pads summarised (pad 1 only); tracks summarised per net; zones counted; net classes only by name regex;
  `.kicad_dru` read by ingest but not as rows; sources DC only; analyses `.op`/`.tran` only; `spice_run` needs an executable;
  writer = one sheet, no rotation/mirror, no wires; no `.kicad_pcb` writer; round trip compares net names only.

## 3. Slices

| Slice | What | Acceptance |
|---|---|---|
| **kxc-1** preserve + identify ✅ BUILT 2026-10-30 | `read_dir` takes EVERY project file (bounded to the project dir; 3D models listed by sha, not read). `KiCadArtifact` row per file (path, kind, sha256, bytes, handling). `KiCadCoverage` row per (file, element kind): count + handling (`typed:<Class>` / `counted` / `preserved`). Sheets walked by INSTANCE (uuid path, ancestor-cycle check) — a child sheet used twice yields two instances. `SchematicSymbol` row per PLACED instance: uuid, instance path, ref, unit, lib_id, value, footprint, position/rotation/mirror, in_bom/on_board/dnp, ALL properties (Sim.* split out). Ingested net volts = unknown (-1, said). | Every file of a project is an artifact; coverage lists every element kind of every file; a twice-used sheet → 2 instances with distinct refs; Sim.* of the UNO sim project survive; no `volts 0.0` invented. |
| kxc-2 electrical graph ✅ BUILT 2026-10-30 | Our own connectivity from the schematic (pins, wires, junctions, labels local/global/hierarchical, power symbols, no-connects, buses) → `SchematicNet` + `NetEndpoint` (instance uuid path + pin) with ERC pin types. Cross-checked against `kicad-cli sch export netlist` when the worker is there. | UNO fixture endpoint sets equal KiCad's netlist; reversed LED caught; a dangling pin reported; reused sheets scope their local nets. |
| kxc-3 simulation (part a ✅ BUILT 2026-10-30: deck + runner) | `SimulationModel` rows (Sim.Device/Type/Params/Pins/Library, the `.lib`'s sha + text kept as artifact), directives, the `.wbk` (analyses, probes, signals). Our renderer gains PULSE/PWL/SIN/AC sources and `.ac`/`.dc`/`.noise`; `spice_run` runs libngspice as well as an executable (in a bounded worker process). Full waveforms stored (sci-xy-chart), with run provenance. | KiCad-exported and Polari-rendered decks of the same circuit agree within stated tolerances (amplitude, timing, current sign); reversed-LED control fails as expected. |
| kxc-4 PCB complete ✅ BUILT 2026-10-30 | Pads per footprint (number, shape, size, position, layers, net, drill); tracks/arcs/vias as geometry rows; zones (polygons, net, layer, fill rules); net classes + assignments from `.kicad_pro`; custom rules from `.kicad_dru` as rows; dimensions/text/graphics counted→typed as needed. | A routed fixture with back-side parts, vias, arcs, zones and custom rules: every element typed or preserved, counts equal KiCad's `pcb export stats`. |
| kxc-5 export (part a ✅ BUILT 2026-10-30: the Bench as a schematic) | Polari → KiCad: multi-sheet `.kicad_sch` with symbols, rotations, wires or labels, Sim fields; netlist; an unrouted `.kicad_pcb` (footprints placed from our placement rows, nets assigned, outline from our board shape). Every export run through kicad-cli (ERC/DRC/netlist) and compared with our graph; an export report lists what had no KiCad form. UNO/C3 bench circuits export with the DevKitM-1 / UNO parts. | Exported projects open in KiCad 10, ERC clean except stated, re-exported netlist = our graph; C3 bench circuit uses RF_Module:ESP32-C3-DevKitM-1 pins via `kicad_devkit_pin`. |
| kxc-6 views | Pages for the ingested/exported objects: coverage table, schematic net navigator, pad-level footprint view, simulation waveforms with probes/cursors (Codex part C informs). The board-level breakdown (layers, circuits in the layers, thermal, silkscreen, footprints) is the single-Board design simulation view, BENCH_BOARDS_PLAN bob-3. | Theme tokens, no raw JSON, click-toggle. |

### kxc-1 as built (2026-10-30)
- `pcb/custom/kicad_cover.py`: artifacts / coverage / sheet_instances / symbol_rows. Classes KiCadArtifact, KiCadCoverage, SchematicSymbol
  (registered as PcbKiCadArtifact / PcbKiCadCoverage / PcbSchematicSymbol). `read_dir` takes every UTF-8 file (hidden dirs, `*-backups`,
  caches, lock files and links leaving the directory skipped); `binaries_in` lists the rest by sha + size. Ingested BoardNet volts = -1.
- Fixtures added from Debian kicad-demos 9.0.2 (GPL-2+, same stanza as ecc83): `complex_hierarchy/` (ampli_ht used twice: the old walk
  saw 73 symbols, now 119) and `simulation/rectifier/` (Sim fields + diode.mod). Ubuntu's KiCad 10 demos on econ say "GPL v2" only
  (no "or later") — NOT vendored.
- Tests: pcb 55/55 (7 new), manifests 25/25, `tests/kxc1_liveboot_probe.py` 8/8 (real boot, POST /api/pcb/ingest stores the rows).

### kxc-2 as built (2026-10-30)
- `pcb/custom/kicad_connect.py`: our own nets from the .kicad_sch (library pin tips transformed by mirror + rotation, wires with T-joins, junctions,
  local / global / hierarchical labels per sheet INSTANCE, global power symbols = a (power) symbol with power_in pins — PWR_FLAG joins nothing by
  name, shared unit pins counted once). Classes `SchematicNet` (scope, aliases, ERC pintype counts, kicad_check) + `NetEndpoint` (ref, unit, pin,
  name, ERC type, instance path, position, no-connect).
- **Our nets = KiCad's, 69 of 69**, groups AND names, on the three fixtures (ecc83 13, rectifier 4, complex_hierarchy 52 across both sheet
  instances); references = `kicad-cli sch export netlist` (KiCad 10.0.6 on econ) in `pcb/custom/reference/kicad10_nets_*.tsv`. The ingest marks
  every SchematicNet same / differs whenever the engine's netlist is in the record (`ingest.ours_vs_kicad`).
- Buses not expanded yet (coverage says preserved).

### kxc-3 (part a) as built (2026-10-30)
- `pcb/custom/kicad_spice.py`: the deck from OUR rows — Sim.Device / Sim.Type / Sim.Params / Sim.Pins / Sim.Library + Sim.Name (subcircuit ports
  read from the library's .subckt line; .model kind → D/Q/M/J), sources DC / SIN / PULSE / EXP / SFFM / AM / PWL + AC, passives inferred from the
  reference letter, KiCad's value reading (1M → 1Meg), the schematic's text directives, model files included by name. `parse_deck` reads any deck.
- `electrodevice/custom/ngspice_shared.py` + `ngspice_shared_runner.py`: libngspice (what KiCad ships; econ has it, pol-core has neither) run in
  its own bounded process; capability says executable vs shared library separately. Doors `GET /api/pcb/{board}/spice-deck`,
  `POST /api/pcb/{board}/simulate` (`pcb_sim_api.py`).
- **Our decks = KiCad's**: every element of rectifier (5) and sallen_key (8) equal in nodes, node order and value except sallen_key V1
  ("DC ac=1 AC 1" KiCad vs "DC 0 AC 1" ours); **run on econ: identical vectors** (rectifier max diff 0 over 10008 points, sallen_key 5.6e-15
  over 61 frequencies). References: `pcb/custom/reference/kicad10_spice_*.cir`, `kicad10_sim_*.json`. Fixture sallen_key added (GPL-2+).
- ~~Still open in kxc-3: waveform storage + the chart~~ -> kxc-3b below; still open: the econ worker binding (deploy = his go), the projection of
  results onto footholds (rail / logic volts).

### kxc-3b as built (2026-10-30, his "go agead on those")
- Composed like the board model (his rule: no object overwhelming with fields): `SpiceRun` (one run: board, deck sha256, plot, points, engine, source
  local | worker | reference, host, ok / refused) + `SpiceVector` (one per result vector, naming its run: role scale | value, unit DERIVED from ngspice's
  names - time s, frequency Hz, #branch A, else V - values verbatim, AC as magnitude + phase). PCB_CLASSES 26.
- `pcb/custom/spice_runs.py`: store / runs / vectors / chart (long form x, y, series; a plain stride, said). /simulate now keeps every run (a refusal too,
  with its reason); POST /api/pcb/{board}/runs takes a worker's result (econ's libngspice); GET /api/pcb/{board}/runs, /api/pcb/runs/{run}/vectors,
  /api/pcb/runs/{run}/chart.
- Board Details: a `runs` part + a Simulation tab (runs -> scope run -> vectors + a named-graph-panel over GraphDefinition `pcb-spice-run`, seeded by
  board_seed). Checked with econ's recorded reference runs (rectifier tran, sallen_key AC). Chrome pass owed.

### kxc-3c / bob-3c as built (2026-10-30, his "keep working on those")
- PROJECTION (`spice_runs.projection`): a run's results on the board's nets - each net's node vector (kicad_spice.node_name, lower-cased as ngspice
  names it): transient min / max / final, AC peak |V| and its frequency; GND 0 V by definition; a net the run did not save says so; the PCB footholds on
  each net listed. GET /api/pcb/runs/{run}/projection; Board Details Simulation tab gains "the selected run on the board's nets"; the Bench pin rows of a
  PCB foothold carry a note "simulated (transient): V a..b, final c (run ...) - not a cited limit" (simulated numbers never replace cited ones).
- THERMAL (`pcb/custom/thermal.py`): per-part power from a kept TRANSIENT run - R by Ohm's law on the node voltages, V by what it delivers (branch
  current), ideal C / L 0 W average by definition, anything else undetermined (the run holds no current for it); the ENERGY BALANCE (delivered -
  counted = the power in the undetermined parts); the board's mean rise dT = P / (h x 2A) from the PcbBoard outline, h = 10 W/(m2 K) a knob inside the
  cited free-convection range (Incropera & DeWitt Table 1.1, 2-25). Radiation / mounting left out - a first-order mean, not a hot-spot map. Board
  Details Thermal tab (estimate + power per part). An AC run is refused (small-signal). Spreading: bob-3d below.

### bob-3d as built (2026-10-30, his "finite element model simulations are already well defined")
- NO NEW MODEL: the textbook thin-plate (fin) problem -div(K grad T) + 2hT = q'' solved by the EXISTING FEM engine (scikit-fem):
  `materialsScience/engines/fem_plate_thermal.py` (solve_plate_conduction_2d, plate_mesh_convergence; reuses fem_engine's capability + feature-aligned
  mesh). Built-in checks on every solve: energy balance (power in = 2h integral of T) and mean rise = the lumped P / (h 2A).
- `pcb/custom/thermal_spread.py` maps a board's own rows onto it: plate = Edge.Cuts box; K = sum k t - stackup dielectric at FR-4 in-plane 0.81 W/(m K)
  (Azar & Graebner, SEMI-THERM 1996, a knob) + each copper pour / teardrop (PcbZone) at k_Cu 401 (Incropera Table A.1) x layer thickness x fill
  fraction; sources = each part's run power over its pads' box (PcbPad); unplaced / unaccounted power listed, never guessed. Tracks and pads not
  counted (peaks read high). GET /api/pcb/{board}/thermal-spread (summary, hotspots, field map); Board Details Thermal tab gains "Where the heat sits" +
  "Hot spots per part".
- Proof (pcb_thermal_spread_selftest, 7 checks): the analytic K0 plate solution within 2%, energy balance, uniform heat = q/2h exactly, refusals; ecc83's
  GND pour roughly thirds the peak with the mean unchanged; mesh convergence.
- Still open: drawing the field map (the pin view could colour the board by it); tracks + vias in K; non-rectangular outlines solved as their box.

### kxc-4 as built (2026-10-30)
- `pcb/custom/kicad_geometry.py` + classes `PcbPad` (every pad: type, shape, size, drill, layers, net, ERC type/function, board position + angle),
  `NetGeometry` (ONE row per net — D-kxc-2 as recommended, his to confirm: segments / arcs / vias lists, length, layers), `PcbZone` (pours,
  keep-outs, teardrops: outline, outline area, FILLED area, thermal relief), `PcbNetClass` (.kicad_pro classes + their nets by assignment /
  pattern / Default), `PcbDesignRule` (.kicad_dru rules), `PcbLayerGraphics` (silkscreen / fab / courtyard / edge / user drawings per layer +
  item kind: count + bbox, board-level and in footprints). Coverage: footprint, segment, arc, via, zone, gr_* now TYPED.
- **= pcbnew's** on both demo boards: pads 165 / 33, segments 364 / 59, zones 166 / 1, per-net routed length exact, every zone's filled area
  within 0.002 mm² (reference `pcb/custom/reference/pcbnew_geometry_*.json`).
- Not yet: dimensions, groups, text strings as rows (still preserved in the kept file); geometry drawn (kxc-6 / bob-3 design view).

### kxc-5 (part a) as built (2026-10-30)
- `pcb/custom/bench_export.py`: a Bench (Boards on the Bench + BenchConnection rows) → the writer's design: every header-like foothold group of a dev
  board or PCB = ONE generic KiCad header (Conn_01xNN; Conn_02xNN_Odd_Even when its footholds' positions are a 2 x N grid), pinned exactly as the
  footholds; breadboards = nets only; nets = each board's own joins + the connections; a power name is global in KiCad so only ONE bench net may
  carry it (a second, unjoined rail becomes +5V_2). Door `POST /api/pcb/export/bench/{bench}` (libraries from the KiCad worker; refused in words
  without one).
- **KiCad reads it the same**: on econ, kicad-cli 10.0.6 re-exported the netlist of the test bench's schematic → 11 of 11 multi-pin nets equal ours,
  none extra; ERC: 29 unconnected pins (= the writer's list) + 5 single-pin labels (a pin whose breadboard strip holds nothing KiCad can draw).
  References `pcb/custom/reference/kicad10_bench_export.json` + the nine symbols used (`kicad10_symbols_bench_export.txt`, CC-BY-SA-4.0 + exception).
- His correction (BENCH_BOARDS_PLAN): the Bench is pins, not a netlist; this export is of the bench NETLIST view (its popup), a board-level
  artifact - the main bench never shows it.
- Done the same day: the C3 as KiCad's own RF_Module:ESP32-C3-DevKitM-1 (cited pin map); KiCad re-read it 11/11, ERC clean of power clashes.
- **kxc-5b ✅ 2026-10-30 (his "encode critical data in standard label / description data"):** every exported part carries hidden
  Polari.Board / Polari.Definition / Polari.Connector / Polari.Drive (per pin: direction, volts, source / sink mA) / Polari.Firmware (per pin:
  variable + role); the ingest reads them back into SchematicSymbol.polari_json. **Round trip proven:** our export → KiCad 10 re-saved it
  (`kicad-cli sch upgrade`, its format 20260306) → our ingest: the same fields for all six parts, nets equal, no problems; KiCad's own netlist
  carries the fields too. Reference `pcb/custom/reference/kicad10_resaved_bench_export.kicad_sch`.
- Open in kxc-5: ingested schematics re-exported; an unrouted .kicad_pcb.

### Boards on the Bench (his ruling 2026-10-30, BENCH_BOARDS_PLAN.md)
An ingested (or Polari-designed) PCB is a **layers + physics board definition** — one of the definition kinds a Board on the Bench can point
at, equal to a datasheet-defined dev board and a geometry-defined breadboard. kxc feeds that definition; the Bench reads only the PCB's
footholds (its connector pads, with node / drive / signal derived from kxc-2 connectivity and kxc-4 pads).

## 4. Placement

Ingest/parse/rows = framework (pure Python, no KiCad needed). kicad-cli + libngspice runs = the KiCad worker on econ-core (plan only
until his deploy go; `pcb_engines` already selects worker URL / local / image / topology). GUI walkthroughs and reference projects =
econ Codex (CX-032).

## 5. Decisions (his)

- D-kxc-1: raw artifact bytes live in the file store (SeaweedFS) with the row holding sha + path, or as text in the DB row? Recommended:
  text files ≤ 1 MB in the row (deterministic tests), larger + binary in the file store.
- D-kxc-2: geometry as rows (kxc-4) — every track segment a row, or one geometry row per net with the segment list? Recommended: per-net
  geometry rows (a routed board has 10^4 segments).
