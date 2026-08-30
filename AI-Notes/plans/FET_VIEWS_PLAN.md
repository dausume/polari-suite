# FET regimes, transport, characteristic-driven views (fv arc)

Written 2026-08-27 from Dustin's brief (verbatim intent): "ensure we
are tracking different regimes in mosfets, like linear and square
regimes. IV characteristics. … tracking if the transistor has
electron velocity that is Scattered, Semi-Scattered, Quasi-Ballistic,
or Ballistic. And if scattered then what are the contributors to that
scattering and properties enforced by it over time. Continue flushing
out more cells and FETs as needed, and … different useful 2D and 3D
views of the fets using our sim-space and configuration capabilities
… material composition view, Voltage Potential across the Transistor
at an instant in time, Gate Voltage, Drain Voltage, and Electron
Density as well as n-doping density and p-doping density … coherent
to trying to understand particular characteristics of a FET … select
FET characteristics and get appropriate views and description of them
and what they mean for the performance of a FET."

Session constraint: autonomous, ~9 h, 20 % of the weekly budget —
backend phases run as parallel agents on DISJOINT files; the
integrator wires routes/seeds/selftest and deploys.

Binding rules: [[frontend-graphing-capability]] (GraphDefinition +
named-graph-panel; no new chart engine), [[per-object-display-config]]
(views belong to the device's page), [[object-coherence]] (every
regime / mechanism / characteristic = a row), [[knobs-and-suggestions]]
(bands and thresholds are knobs; refusals name them), honesty strings
on every payload (F1 compact model → any spatial field is an ANALYTIC
SKETCH labelled as such; F3/NEGF row-backed profiles stay the truth
where they exist).

## 0. Existing assets (ride, don't rebuild)
| Need | Asset |
|---|---|
| states + criteria-as-data | `cnt_states.FETOperatingState`, `frame_at`, `classify`, `transitions_on_sweep` |
| model params | `cnt_device_viz.device_model` → (id_fn, p, device); `p` has lg_m, mu, vxo, n_ss, dibl, lambda_nm (scale length), phit |
| mean free paths | `cnt_constants.LIT`: lambda_v_nm 440 (VS ballistic), lambda_ap_nm 300, lambda_op_nm 12.5, hw_op_eV 0.18, lambda_mu_nm 66.2 |
| process rows | `cnt_process_basis` (purity, alignment angle, contact Rc) — scattering contributors' knobs live there |
| scoring | `cnt_scoring` FET_TERMS + validity gate; `cnt_compare` per-FET pages |
| cells | `cnt_cell_library` CELL_LIBRARY (generated variants), `characterize_cells` |
| spatial truth | `cnt_figures` d13-scf-profile (row-backed SCF barrier), `cnt_charge`, `cnt_kwant` |

## 1. Phases

### fv-1 — regimes as data + IV regime map (`cntfet/cnt_regimes.py`)
- Sub-regimes of "on" as NEW `FETOperatingState`-style rows in a
  `FETRegime` class (criteria_json over an extended frame):
  `subthreshold-exponential` (Id ∝ exp), `linear-triode` (Id ∝ Vds,
  Vds < Vdsat), `square-law` (long-channel: local exponent
  m = d ln Id / d ln Vov ≈ 2 at Vds ≥ Vdsat), `velocity-saturated`
  (m ≈ 1, Fsat → 1), `dibl-tilted-saturation` (dId/dVds ≠ 0 in
  saturation, attributed to DIBL). Frame gains `vov_exponent`
  (central-difference log-slope at fixed Vd), `gds_over_gm`, `fsat`.
- `regime_map(p, vg_grid, vd_grid)` → long-form rows (one series per
  regime, style dot, x = Vd, y = Vg) = the IV regime MAP graph;
  `iv_regime_curves` = Id–Vg with exponent guide bands; Id–Vd family
  with the regime of each point as series. Graph seeds
  `cnt-device-regime-map`, `cnt-device-exponent`.
- Endpoint `/api/cntfet/device/{name}/regimes?vg=&vd=` (map + point).
- Knobs: exponent bands ([1.7, 2.3] square-law, [0.8, 1.2] velocity-
  saturated), grid steps. Selftest `selftest_regimes.py`.

### fv-2 — transport regime + scattering contributors over time (`cntfet/cnt_transport.py`)
- `ScatteringMechanism` rows (seeded): acoustic-phonon (λ_ac ∝ d/T,
  300 nm at d0/300 K), optical-phonon (λ_op 12.5 nm, ACTIVE only when
  the carrier gains ħω_op = 0.18 eV: qVds ≥ ħω_op), defect/impurity
  (λ_def from purification purity + a prior; knob), contact-interface
  (Rc vs RQ/2 → an effective transmission), tube–tube/alignment
  (angle sigma → effective length). Each row: `lambda_formula`
  (data), `bias_condition`, `temperature_scaling`, `time_profile_json`
  (e.g. defect density grows with dose/aging: λ_def(t) = λ_def0 /
  (1 + t/τ) — PRIOR, labelled), `enforced_properties_json` (what it
  does to Ion, v_inj, μ_app, SS).
- Matthiessen: 1/λ = Σ 1/λ_i(bias, T, t). Transmission T = λ/(λ+Lg)
  (Lundstrom); ballistic efficiency B = T/(2−T); the VS model's own
  v_xo/vB = λ_v/(λ_v+2Lg) reported beside it.
- `TransportRegime` rows with criteria as data over T: Ballistic
  (T ≥ 0.9), Quasi-Ballistic (0.6–0.9), Semi-Scattered (0.3–0.6),
  Scattered (< 0.3) — KNOBS.
- `transport_report(manager, device, vg, vd, t_hours)` → λ_i,
  contributions (fraction of 1/λ), λ_eff, T, B, regime with the
  criterion, enforced properties (Ion = Ion_ball·B, v_inj = v_T·B …),
  and a TIME SERIES (t = 0 … horizon) of λ/T/regime/Ion factor.
- Graphs: `cnt-device-transport-vs-lg` (T(Lg) with regime bands,
  this device as a guide), `cnt-device-scattering-contributions`
  (per mechanism, categorical x), `cnt-device-transport-over-time`
  (T and Ion factor vs t, regime bands). Endpoint
  `/api/cntfet/device/{name}/transport?vg=&vd=&t=&horizon=`.

### fv-3 — the FET-characteristic registry (`cntfet/cnt_characteristics.py`)
- `FETCharacteristic` rows: key, name, description (physics),
  performance_meaning (what it means for a FET), equation,
  regime/transport links, `views_json` = ordered list of
  {kind: graph|api|simspace, graphName, dataPath, simSpaceName,
  title, why-this-view}, related terms (ScoreTerm names) and states.
  Seeded set: transfer-characteristic, output-characteristic,
  subthreshold-swing, threshold, dibl, on-off, transconductance,
  on-conductance, regime-map, transport-regime, scattering,
  material-composition, potential-at-instant, gate-voltage,
  drain-voltage, electron-density, n-doping, p-doping, switching-
  states, stochastic-spread, score.
- Endpoints `/api/cntfet/device/{name}/characteristics` (list) and
  `…/characteristic/{key}` (views resolved to THIS device's paths +
  live numbers + the description).

### fv-4 — 2D/3D device views (sim-space + config) (`cntfet/cnt_fields.py`, `cnt_scene.py`)
- Device geometry as REGIONS (GAA cylinder: source contact Pd /
  n-doped extension / intrinsic CNT channel / HfO2 shell / gate
  metal / drain), materials from the component rows (composition
  view = regions coloured by material, with the row references).
- Fields along x (and radially where meaningful), served as
  long-form (x, y, value) rows AND as sim-space scalar fields:
  potential U(x) at an instant (analytic VS sketch: source barrier at
  x0, drop over the scale length λ, Vds across the channel — F1
  SKETCH label; the D13 SCF row-backed profile drawn beside it where
  present), electron density n(x) (semi-classical from Qxo and U(x)),
  n-doping (extension doping from Efsd through the 1-D DOS),
  p-doping (0 for the n-FET; the p-twin mirrors), gate/drain voltage
  as the boundary values that set U(x).
- Rendered through whatever the sim-space survey shows is
  CONFIG-DRIVEN (scene rows + DisplayDefinition items) — never a
  bespoke 3D component. 2D cross-section = the same fields on a graph.

### fv-5 — characteristic explorer (frontend, generic)
- One component `fet-characteristic-explorer` (registered in the
  generic ComponentRegistry): inputs {listPath, itemPathTemplate};
  lists characteristics, on select renders the resolved views via
  the EXISTING named-graph-panel / api-json-panel / sim-space
  components + the description and performance meaning. Seeded onto
  a per-device detail page `cntfet-detail-{device}`.

### fv-6 — more FETs and cells
- Devices: `cnt-aligned-s1-lg10` (aggressive), `cnt-aligned-s1-tox2`
  (thinner oxide), `cnt-aligned-s1-p` (p-type twin) — comparator set
  for the competitive pages (each derives; unproven → 0 until then).
- Cells: NAND3/NOR3 (3-input), AND2/OR2 (composed inverter stage),
  XOR2 (composed), generated variants × drives; library_report
  lists them; characterize on the engines worker.

### fv-7 — 2-D SVG parts view, generic over FETs (PLANNED 2026-08-29, not built)
Dustin: "a generic way to pull data for FETs in general so that across
multiple FETs their 2D svg-defined parts can be pulled with
appropriate data and be visualized." Foundation already built:
`cnt_parts.device_parts(manager, device)` — the ORDERED parts list
(part, purpose, material, doping, dimensions, process, row,
`regionKind` ∈ contact / extension / channel / oxide / gate) for any
FET (CNT or Si). Plan:
1. **`FETPartTemplate` rows (config, per shape kind):** one SVG
   template per `FETShapeType` (planar-bulk, finfet, gaa-nanowire,
   cnt-gaa …) stored as a row: `svg_template` with named `<g
   data-region="channel">` groups, a `layout_json` mapping
   `regionKind` → the group + which dimension keys scale it
   (lg_nm → width of the channel group, t_ox_nm → oxide thickness,
   l_ext_nm …), and `legend_json` (fill by doping type: n / p /
   undoped / metal / insulator — fixed palette tokens).
2. **Resolver endpoint** `/api/cntfet/device/{name}/parts-view` →
   {template (svg), regions: [{regionKind, part, material, doping,
   fill class, label, dims, row, dataPaths: {field profile for the
   region, part-specific graph}}], scale}. Data pulled through the
   SAME generic parts list — nothing per device.
3. **Component `fet-parts-view`** (generic registry): renders the
   template SVG, colours regions by doping type, sizes them from the
   dims, labels + hover tooltip (material, doping statement, row
   link), click → the region's detail (parts row + field profile
   graph for CNT: potential / density along that region; for Si:
   refusal-by-name until a Si field basis exists). Optional overlay
   mode: shade regions by a scalar (potential / density band) from
   `/fields` — the 2-D slice of the fv-4 3-D scenes.
4. Seed onto every score + detail page (row above the parts table);
   Si shapes get their own templates (planar with S/D junctions and
   body; FinFET cross-section).
5. Later: the same regions become the 2-D `SimSpaceDefinition`
   (dimensionality '2d', Shape2DDefinition rows) so the sim-space
   scrubber can drive them — but the SVG template route ships first
   because it is config + one component, no compiler work.

## 2. Decisions for Dustin (defaults stated; build proceeds)
1. Regime exponent bands and transport-T bands — knobs (defaults above).
2. Time profiles of scattering (aging/dose) are PRIORS labelled low-confidence until a measured series exists.
3. Spatial fields from F1 are analytic sketches (label "F1 SKETCH"); D13/F3 rows are the truth where present — promote when NEGF fields land.
4. Which characteristics get sim-space (3D) vs graph (2D) by default.

## 3. Status — ALL SIX PHASES BUILT 2026-08-27 (framework 4206e99, angular 84259e9, dev-fi-1)

| Phase | Landed | Numbers / decisions |
|---|---|---|
| fv-1 | `cnt_regimes.py` — 10 `FETRegime` rows (adds `near-threshold`, `contact-limited-sublinear` (m < 0.8, Rc eats Vov), `super-square`, `exponent-undefined` so the map has no holes); frame + `vov_exponent`; map / exponent / output-by-regime graphs; `/regimes` | S1 at Vdd: m = 0.81 → velocity-saturated. ⚠ the VS model CANNOT reach m ≈ 2 (Vdsat independent of Vov) — square-law is a row that no VS device will occupy; stated in the row, the verdict and the check. 24/24 |
| fv-2 | `cnt_transport.py` — 5 `ScatteringMechanism` rows (acoustic; optical ACTIVE when qVds ≥ 0.18 eV; defect prior from purity with 1-yr aging; contact T_c = (RQ/2)/Rc; misalignment Lg/cos σ), 4 `TransportRegime` rows; Matthiessen λ_eff, T, B; enforced properties; time series; `/transport`; 3 graphs | S1: Vds 0.05 → T 0.94 BALLISTIC (acoustic-limited); Vds 0.6 → optical branch, T 0.45 SEMI-SCATTERED; T_c 0.59 reported beside (regime_on channel\|total knob); VS ballisticity 0.936 beside ours. 16/16 |
| fv-3 | `cnt_characteristics.py` — 22 `FETCharacteristic` rows × ordered views; `/characteristics`, `/characteristic/{key}`; unbuilt views named, never dropped | groups iv / switching / transport / fields / quality |
| fv-4 | `cnt_fields.py` + `cnt_scene.py` — regions from component rows; F1 SKETCH potential (kwant_worker.analytic_ec) / density / n,p-doping via the 1-D DOS; `FETFieldSample` + `FETFieldBand` rows, banded Material3D seeds, one 3-D scene per device (`cnt-device-3d-{device}`, cylinders along x, fixed orthographic camera), one binding, rows selected by `?run=fet-fields:{device}:{field}` (compile_3d's only filter); `{action: sample-fields}`; `/fields`; 4 graphs | S1 barrier 0.393 eV (Vg 0) → −0.061 eV (Vg 0.6) — the negative value is the sketch's no-pinning limitation, which is why the D13 SCF row is drawn beside it; n_ext 5.3e8 /m. 25/25 |
| fv-5 | angular `fet-characteristic-explorer` (generic registry; graph → named-graph-panel, api → api-json-panel, simspace → sim-space-viewer WITH run); `cntfet-detail-{device}` page seeds (explorer + 3 scenes + 2 profiles) | tsc clean; ng build OK; browser pass owed |
| fv-6 | devices lg10 / tox2 / p (⚠ `polarity` is a LABEL today — build_vs_params pins ptype 0; the p-row says so); cells NAND3, NOR3, AND2, OR2, XOR2 (10T) — compose accepts list inputs; 36 cell rows | lg10 DIBL 15 mV/V vs S1 2.6; tox2 Cinv +11 %; XOR2 arcs 1.6–2.2 ps. 11/11 (real ngspice + OpenSTA) |

Integrator: `cnt_device_viz.extra_curve_builders()` / `extra_graph_seeds()`
registry; polariServer guards each fv module separately (an absent
phase never stubs cntfet). Main selftest 120/120.

OPEN (his): browser pass of `/display/cntfet-detail-cnt-aligned-s1`
after `enable-cntfet-prf-a.sh` (which now also derives every
comparator and samples the field scenes); ratify §2 defaults; the
p-polarity plumbing (make `polarity` drive ptype in derive) is a
real gap the p-row names.
