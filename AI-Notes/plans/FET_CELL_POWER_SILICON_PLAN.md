# FET + cell: power limits, silicon (sol-gel) transistors, optimization classes, complementary pairs, silicon refinement, circuit + boolean-logic diagrams (fp arc)

Written 2026-08-27 from Dustin's brief (verbatim intent): "account for
power dissipation limits. Static power dissipation, leakage power …
simulate traditional Silicon and doped Silicon semiconductor
transistors while leveraging sol-gels … digital-optimized and
analog-optimized transistors, also referred to as Switching-Optimized
and Signal-Optimized … different FET shape types, whether or not they
are made to be complementary FETs and what their specific
complementary fet is … the logic for why they are complementary and
how that helps. Linear Region & Saturation Region, BdSat … the
sub-threshold region … Silicon refinement … open research … up to the
PV-level quality; for semiconductor grade … a novel approach. …
Circuit diagrams and boolean logic diagrams … generated for different
cells via no-code configuration … boolean logic visualizations from d3
… step through the state spaces to proof them. … categorize by input,
output, and transfer characteristics … frontend components … intuitive
… weaving together pages and alternate views for FETs … for the
average person."

Binding rules as in FET_VIEWS_PLAN (config-driven graphs, per-object
surfaces, rows for every concept, explicit knobs, honesty strings,
licence gates — every adopted equation cites; sol-gel and refinement
routes cite open literature or are labelled PRIOR/novel).

## 0. Reuse (the fv/fi machinery is model-agnostic)
Everything downstream of `device_model(manager, name) → (id_fn, p,
device, refusal)` — states, regimes, scoring, validity gate, transport,
fields, characteristics, compare — works for ANY device whose model
yields the VS parameter dict `p`. The VS model IS a MOSFET model
([KHA09] was written for silicon): a silicon device therefore only
needs `build_si_vs_params` (Vt from doping/flat-band, Cinv from a
planar/fin/GAA Cox and the depletion capacitance, μ from doping
(Caughey–Thomas), v_xo from Si injection velocity × ballisticity,
n_ss = 1 + Cdep/Cox, DIBL from the scale length of the SHAPE). Cells
likewise reuse `cnt_cell_library` netlists with a different card.

## 1. Phases (agents on disjoint files; integrator wires)
### fp-1 power — `cntfet/cnt_power.py`
- FET: static/leakage power P_static = Vdd·Ioff (subthreshold; gate
  leakage = named gap at S1 — no tunnelling model; GIDL likewise),
  its dependence on Vt/SS/T (Ioff ∝ 10^(−Vt/SS)), dynamic
  E = C·Vdd² per transition, P_dyn = α·f·C·Vdd².
- Cell: leakage per INPUT STATE from the off-network (stack effect
  knob), averaged over states → P_static; Liberty `leakage_power()`
  blocks with `when`; dynamic from the cell-2 energy tables ×
  activity × f; `PowerBudget` rows (limits: per-cell leakage, per-area
  density W/cm², thermal) with CHECKS naming which limit fails; Score
  terms fet-static-power / cell-static-power / cell-dynamic-energy
  feed the existing concepts. Endpoints `/power` (FET) and
  `/cell-power`.
### fp-2 silicon FET on sol-gel — `sifet/` (sibling module, THIN)
- Rows: `SiliconDopingProfile` (type, N_A/N_D, method: implant/
  diffusion/in-situ), `SolGelDielectric` (precursor TEOS/HfCl4-
  alkoxide → SiO2/HfO2, anneal, k, thickness, leakage prior — open
  literature cited), `SolGelProcess` (spin/dip, cure), `SiliconMOSFET`
  device row (shape ref, doping refs, dielectric ref, W/L, T) and
  `si_model.build_si_vs_params(...)` → VS `p`; `device_model` adaptor
  so EVERY fv/fi surface works on it; seeds: planar NMOS/PMOS 90 nm-
  class, FinFET-class, each with a sol-gel dielectric variant.
### fp-3 taxonomy — `cntfet/cnt_taxonomy.py`
- `FETOptimizationClass` rows: switching-optimized (digital: Ion/Ioff,
  SS, delay, leakage) vs signal-optimized (analog: gm/Id, gds →
  intrinsic gain gm/gds, linearity, noise, matching) — with the SCORE
  CONCEPT each maps to (a second concept `fet-signal-quality` with
  gm/gds, gm/Id, Vdsat headroom terms) and the operating REGION each
  prefers (switching: sub-threshold ↔ saturation swing; signal:
  saturation with Vds > Vdsat + margin).
- `FETShapeType` rows (planar bulk, SOI, FinFET, GAA nanowire, GAA
  nanosheet, CNT-GAA, TFET) with the electrostatic scale-length
  formula as data and typical n_ss/DIBL priors.
- `ComplementaryPair` rows: n ↔ p, the LOGIC (pull-up conducts when
  pull-down is off → no static path, rail-to-rail, noise margins),
  the CONDITIONS (|Vt_n| ≈ |Vt_p|, drive match via W_p/W_n ≈ μ_n/μ_p
  or CNT twin symmetry), and per-device `complementary_of`
  resolution + a check report. Regions summary per device: linear /
  saturation / sub-threshold with Vdsat (BdSat) boundaries — cites
  fi-0/fv-1.
### fp-4 silicon refinement — `sifet/si_refinement.py`
- Route rows MG-Si → UMG-Si → SoG-Si (PV) → EG-Si (semiconductor):
  carbothermic reduction, slag/acid leaching, directional
  solidification (Scheil segregation, k_eff per impurity — the
  characteristic equation), Siemens TCS / FBR silane, zone refining
  (passes), FZ. Each row: inputs, outputs, purity in/out (N-count),
  energy, licence/openness status (`open-research` with citations vs
  `novel-needed`), and a computable model (`scheil_pass` etc.).
  PV-grade = documented open routes; semiconductor-grade = the novel
  section with candidate directions as labelled PRIOR rows. Report
  endpoint `/api/sifet/refinement` + grade ladder as data.
### fp-5 circuit + boolean logic diagrams — `cntfet/cnt_logic.py` + angular d3
- From CELL_LIBRARY: transistor-level netlist GRAPH (nodes: nets +
  devices; edges) → `cell-schematic` (d3); boolean AST from
  `liberty_function` → gate-level DAG → `cell-logic-diagram` (d3,
  interactive: click inputs to toggle, watch gate outputs, or step
  through every input vector); truth table; switch-level PROOF:
  evaluate the transistor netlist per input vector (pull-up/pull-down
  conduction) and compare with the boolean function — every cell
  proven or a named counter-example; sequential cells: state
  transition graph stepping. Endpoint `/api/cntfet/cell/{name}/logic`.
  Survey the existing spice/verilog no-code (cnt_verilog_a, cnt_osdi,
  electrodevice) and the d3 no-code editor before building.
### fp-6 categorization + weaving (integrator)
- `FETCharacteristic.category` ∈ {input, output, transfer} on every
  row + plain-language `explain` (average-person) + `navigation`
  row on every FET page (home ↔ score ↔ detail ↔ silicon twin ↔
  complementary partner ↔ cells that use it).

## 2. Decisions for Dustin (defaults stated)
1. Gate leakage / GIDL: named gaps at S1 (no tunnelling model) — or adopt a cited empirical prior?
2. Power budget defaults (per-cell leakage 1 nW, density 100 W/cm²) — knobs.
3. Silicon model = VS parameterization (shared downstream) rather than a BSIM port — accepted?
4. Sol-gel dielectric priors (k, leakage) from open literature until a measured row exists.
5. Semiconductor-grade refinement: which novel direction to pursue first (rows are candidates, none endorsed).

## 3. Status — ALL SIX PHASES BUILT 2026-08-27 (dev-fi-1)

| Phase | Landed | Numbers / honest limits |
|---|---|---|
| fp-1 | `cnt_power.py`: FET static = Vdd·Ioff (gate leakage + GIDL = NAMED unmodelled gaps), dynamic C·Vdd², Vt/T sensitivity; cell leakage per input state by switch-level off-network with the stack effect ([NAR01]); Liberty `leakage_power() { when }` emitted by `characterize_cells`; `PowerBudget` rows + per-limit checks; 3 score terms; `/power`, `/cell-power`; 3 graphs | S1: Ioff 0.83 nA → 0.50 nW static (under the 1 nW prior); −50 mV Vt → ×6.9; E_switch 1.5 aJ; NAND2 leakage 00/01/10/11 = 0.5/1/1/2 Ioff. 20/20 |
| fp-2 | `sifet/` (si_basis, si_model, si_device): SiliconMOSFET rows on thermal-SiO2 / sol-gel SiO2 / sol-gel HfO2, planar + FinFET shapes, doping profiles; VS parameterisation from Si physics (Sze Vt, Caughey–Thomas μ, Taur–Ning / Suzuki / Auth–Plummer scale lengths); `si_device_model` satisfies the SAME contract → every fi/fv/fp surface works; `device_model` dispatches by class; `/api/sifet/devices` (+ derive), `/capability` | NMOS planar Vt 0.33 V, SS 72.6 mV/dec, Ion/Ioff 1e5 at 1 V; HfO2 sol-gel Cinv ×2.3; **cross-technology ranking: Si NMOS 0.71 > CNT S1 0.69 > Si FinFET-HfO2 0.68**. ⚠ v_xo uses a kT-layer fraction prior; sol-gel priors 'to verify'; CNT-only surfaces (transport context, field regions) refuse by name for Si. 25/25 |
| fp-3 | `cnt_taxonomy.py`: FETOptimizationClass (switching-/signal-optimized with aliases digital/analog), second concept `fet-signal-quality` (gm/Id, gm/gds, Vdsat headroom, linearity), FETShapeType ×7 (scale-length formulas as data), ComplementaryPair (logic + evaluated conditions), regions summary (linear / saturation / sub-threshold with Vt, Vt+Vov_min, Vdsat = BdSat); `/taxonomy`, `/signal-score` | S1 signal 0.32 vs switching 0.69 → switching-optimized; pair s1↔s1-p symmetric under the explicit mirror. 26/26 |
| fp-4 | `sifet/si_refinement.py`: grades MG/UMG/SoG/EG, 11 steps with computable models (Scheil, multipass zone, evaporation), routes `pv-open-route` (open-research), `siemens-route` (industrial-proprietary), `eg-novel-route` (novel-needed, 3 PRIOR directions); `/api/sifet/refinement[/route]`; 2 graphs | MG feed B 40 / P 30 ppmw → open route B 0.107 / P 0.108 → **SoG reached**, 48 kWh/kg; EG NOT reachable by any open chain (B k_eff 0.8 is the wall) → the novel section. 31/31 |
| fp-5 | `cnt_logic.py`: boolean AST → gate DAG, truth tables, placed transistor netlist, switch-level PROOF (union-find over conducting devices, inputs as drivers for pass gates), state space (cdff transition graph parsed from the subckt); `/api/cntfet/cell/{cell}/logic`, `/cells/logic`; angular `cell-logic-diagram` (click inputs / step / play, PROVEN badge) + `cell-schematic` (conducting path per vector); page `/display/cntfet-cells` (10 cells × both) | ALL 12 combinational cells prove, zero contention / floating. 23/23; tsc + ng build clean |
| fp-6 | `FETCharacteristic.category` input/output/transfer/structure + plain-language `explain` on all 22 rows (explorer shows both first); `/links` weave + nav rows on score/detail pages; polarity → `ptype` in `device_model` (own-frame evaluation, card gets ptype 1) | main selftest 125/125 |

### 3b. cells-2 + FET-set flush-out (2026-08-27, later)
- **Cells (25 total, 75 seed rows):** + XNOR2 (10T, NAND2→OAI21), AND3/OR3, NAND4/NOR4 (4-stack: all-low leaks 0.125·Ioff), AOI22/OAI22, MUX4 (3×MUX2, 12 arcs), XOR3, **HA + FA** (28T mirror adder — multi-output schema `outputs[]` + `liberty_functions{}`, one Liberty `pin` block per output), **TBUF** (`three_state "(!EN)"`, Z is the EXPECTED output in the proof), **D latch** (state space 8 transitions incl. hold; own-loop setup/hold/D→Q: 0.318 / −0.080 / 0.69 ps; `{action: characterize-latch}`). Payload contract v2 (additive). ALL 24 combinational cells + the latch PROVE. Characterized on S1: XNOR2 ~1.6–2.2 ps, NAND4 fall 3.3–3.6 ps (stack), FA S 1.5–2.6 ps. `parse_liberty` keys multi-output arcs `<out>:<pin>|<when>`.
- **FETs:** + `si-pmos-finfet-solgel-hfo2`, `si-nmos-planar-solgel-sio2`, `si-pmos-planar-solgel-hfo2` (7 Si + 5 CNT); Si complementary pairs `si-planar-90-pair` (Vt ±0.323, Ion ratio 0.76, W_p/W_n to match 1.31) and `si-finfet-hfo2-pair` (2 p-fins per n-fin); `shape_of` resolves Si shape rows; `sifet-home` page + per-Si score/detail pages; **cells characterize on silicon** with pair-aware p cards (the p card is the real hole device, μ_p 111 vs μ_n 289); the validity gate and score frame use the device's OWN Vdd (`device_knobs`); `/api/sifet/refinement/{route}/points`; `/links` for Si names; `si_refinement._rows` live-manager fix.
- Suites: main 125, cells-2 20, sifet-pages 21, sifet 25, refinement 31, taxonomy 26, power 20, logic 23, more-cells 11.

His one command still: `enable-cntfet-prf-a.sh` (now also derives the silicon FETs and verifies power / taxonomy / logic proof / refinement / cross-tech ranking). Browser passes owed: cells page, detail page. §2 decisions await him.

### 3c. Speed from the cell layer + device-relative sweeps + the ladder (2026-08-30)

Dustin's refinement of the ChatGPT exchange, RATIFIED as built:

- **Division**: FET page = device physics (primitives: Ion/Ioff/SS/gm/Cg, at its OWN
  Vdd); cell page = switching performance (FO4, transition energy, leakage per cell);
  architecture page = CPU-level estimates (future). Speed is **owned by the cell layer**
  (`cntfet/cnt_fo4.py`): FO4 = delay of the characterized INVX1 driving 4×Cin at its
  own output slew (fixed point on the Liberty grid); `f_est = 1/(N_FO4·t_FO4)` with
  **configurable N_FO4** — default bands 12 aggressive / 15 moderate / 20 relaxed /
  30 conservative, or `?fo4_per_cycle=12,15,20,30` on `GET /api/cntfet/device/{name}/fo4`
  (`?fanout=`). The headline is a RANGE ("1.9–4.8 GHz for 30–12 FO4/cycle"), never one
  number. E_transition = the MEASURED supply energy of the switching edge (∫Vdd·Idd dt,
  leakage baseline subtracted — cnt_cell_library) + C_load·Vdd², not a bare CV². Every
  payload carries the caveat verbatim: *intrinsic-grade estimate; excludes extracted
  interconnect, clock tree, SRAM, IR drop, and package effects.* Surfaces: Speed card in
  `fet-overview` (labelled "from the cell layer"), row 11 of every score page
  (`score-{d}-fo4`, pick=clock). Live: Si planar-90 FO4 17.5 ps → 1.9–4.8 GHz.
- **Device-relative sweeps**: all FET plots run V_G 0→V_DD and V_D→V_DD of the device's
  own `vdd_v` (`cnt_device_viz.device_vdd/_windows`; transport at Vg=Vd=own Vdd).
  A separate NORMALIZED cross-device view (V_G/V_DD, I/I_on) is planned, not built
  (fv-8 in FET_VIEWS_PLAN).
- **Open-silicon ladder** (`sifet/si_ladder.py`, plan `FET_LADDER_PLAN.md`): two
  INDEPENDENT axes per rung — `rights_class` {incorporable-open, clean-room-
  reconstructable, reference-oracle, encumbered, unresolved} × `fabrication_evidence`
  {measured-fabricated-device, reconstructed-from-published-silicon, calibrated-
  predictive, predictive-only, hypothetical}; `manufacturable` is NEVER inferred from a
  predictive PDK (asserted). Rungs 90 → 65 → 45 → 32 → 22 → 15/14 → 7. Frontier =
  FreePDK45 (Apache-2.0, PTM-45 calibrated to Fujitsu silicon); predictive frontier =
  ASAP7 (BSD-3, predictive-only); manufacturable frontier = none. FreePDK15 is
  ENCUMBERED (CC-BY-NC-SA design rules); PTM32 UNRESOLVED (terms unverified). New devices
  `si-nmos/pmos-freepdk45-class` vs documented anchors: NMOS Ion 0.75×, Ioff 25× under
  (gap; nearest knob vfb −0.93→−0.98 suggested, NOT applied); PMOS within tolerance.
  Routes `/api/sifet/ladder`, `/ladder/points?curve=ion-vs-node`,
  `/devices/{name}/anchors`; sifet-home rows 6–7.
