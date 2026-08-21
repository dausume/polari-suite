# CNT FET full simulation — collaborative plan (Claude ⇄ ChatGPT)

**Date:** 2026-08-20 · **Status: PLANNING — DIALOGUE IN FLIGHT.**
Dustin's directive: collaborate WITH ChatGPT (he relays messages; no
browser bridge this session) to plan the path to FULLY SIMULATING CNT
FETs in the polari stack. Fab of a CNFET RISC-V MCU is the horizon
vision (ChatGPT's hierarchy: device → cells → PDK → Yosys/OpenROAD →
Ibex), NOT the near-term target. Dustin will supply: (1) his existing
CNT research paper (reference anchor, arriving later), (2) the known
functional CNT RISC-V design (2019 RV16X-NANO, ~14k CNFETs) as
precedent.

## Dialogue state

- **Round 0 (ChatGPT, received 2026-08-20):** the full hierarchy
  argument — don't design a CNT CPU transistor-by-transistor; build
  complementary CNFET primitives + a ~7-cell standard library (INV
  NAND2 NOR2 XOR2 MUX2 BUF DFF) + PDK collateral (SPICE/GDS/LEF/
  Liberty) so Yosys/OpenROAD/Ibex do the rest; variability is
  first-class in CNT tech; 7nm gate length ≠ "7nm node"; generations
  0..13 progression; RV32E stepping stone; Sunburst/OpenTitan
  peripherals later.
- **Round 1 (Claude → ChatGPT, sent via Dustin same day):** framing
  correction (near-term = full SIMULATION, not fab) + inventory of
  what polari already has + proposed S0..S4 staging + questions a-f
  (see below). Awaiting ChatGPT's reply.

## What polari ALREADY HAS (the inventory sent to ChatGPT)

- **materials→device→SPICE→circuit pipeline LIVE** (hwsim-5 rungs,
  electrodevice/ module): ngspice in the backend image; device rows
  derive parameters by EXECUTING msci models; provenance rides the
  .subckt cards; device_validator = the standards judge (derivations
  never self-bless).
- **CNT FETs exist as PERCOLATION-FILM devices** (not aligned
  arrays): CNT network in sol-gel silica, level-1 MOSFET cards (Ron
  6.29Ω / Roff 1.4e15 / on-off 2.3e14), complementary CNT inverter
  switch-test PROVEN in ngspice, switching analysis t_on 0.56ns /
  f_max 15.3MHz with honest 14mm×20µm footprints. The 7nm
  aligned-CNT regime = a DIFFERENT device, unmodeled.
- **Quantum layer:** pyscf DFT fragments (KS + UKS), doping
  classification validated (wood-ash K→n, boron→p, graphitic-N donor
  at larger fragment); ssp crystal structures/phonons/elastic/XRD
  (pymatgen worker); QE periodic DFT = unbuilt knob (ssp-5).
- **Digital co-sim:** Renode MCU twin (real firmware ↔ object model),
  Verilator AXI4-Lite co-sim, register-maps-as-data generating
  Verilog+C+benches; oss-cad-suite in toolchain (Yosys present).
- **Tech-tree seams:** electronics + materials + manufacturing trees;
  CNT-CVD ladder rung honestly gated by ATMOSPHERE not heat; mtt-2
  CNT builder = the next unbuilt materials item.
- **Constraints:** GPLv3; NC = hard blocker (fork-pin + license-gate
  discipline; reimplement-published-equations is the standard NC
  workaround — Hall/NIDDK precedent). Literature numbers = flagged,
  cited, tunable priors.

## Proposed staging (S0..S4 — sent for ChatGPT push-back)

- **S0 — license-gate research pass** (cmp-0/nmp-0 pattern) on:
  Stanford VS-CNFET (Verilog-A), CCAM (TU Dresden), Deng–Wong 2007
  Stanford model, NanoTCAD ViDES (NEGF), OpenVAF/OSDI (Verilog-A →
  ngspice ≥39), RV16X-NANO released collateral, ASAP7 as PDK
  structural template. ALL UNVERIFIED until gated; nanoHUB terms
  often academic-only. NC → reimplement equations from papers.
- **S1 — aligned-CNT device layer** in the object model: chirality →
  bandgap → per-tube I-V (virtual-source-style compact model);
  device rows = {Lg, pitch, tube count, contact metal + Rc prior,
  gate stack εr/EOT}; every parameter derived / from Dustin's paper /
  cited prior, validator-flagged.
- **S2 — variability first-class**: metallic-tube fraction,
  count/pitch variation, Rc spread → Monte Carlo over cards;
  DREAM/RINSE-style mitigations as explicit knobs.
- **S3 — circuit rung in ngspice**: inverter VTC/margins/delay/
  energy, ring oscillator, the 7-cell library → Liberty tables.
- **S4 — synthesis handshake**: Yosys → counter → RV32E core on the
  characterized cells; Verilator function, ngspice timing
  spot-checks; OpenROAD deferred to layout-era.

## Questions posed to ChatGPT (round 1)

a) Which compact model to center S1 on given GPL constraints; is
   VS-CNFET's published equation set complete enough to reimplement?
b) Minimal parameter set measured/derived vs prior for
   rank-design-choices predictivity (not silicon sign-off)?
c) How to stage film-device → aligned-device coexistence honestly in
   one library?
d) Published CNFET I-V datasets as reproduction targets for S1
   validation (beyond Dustin's paper)?
e) Liberty characterization flow with open tools only (ngspice +
   OpenSTA; any trusted open cell characterizer)?
f) Agree SRAM stays out of scope until S4 proven (DFF-array memory
   placeholder)?

## Process

Dustin relays messages between the two AIs (no Chrome bridge in this
session — extension not connected). Each round gets appended to
"Dialogue state" above. When the dialogue converges: ratify the
S-phases with Dustin (decision numbering, nmp style), then S0 runs as
a parallel research pass (the cmp-0 pattern) before any build.
Dustin's CNT paper joins as a reference the moment he downloads it —
its measured values become S1 calibration anchors.

## Grounding index

- memory: hardware-simulation (hwsim-5 CNT FET rungs — the film
  precedent), materials-tech-tree (CNT builder NEXT), solid-state-
  physics (ssp-5 QE knob), polari-simulation-framework (5-level
  resolutions), tech-tree-and-blcnc-planning.
- AI-Notes/plans/HARDWARE_SIMULATION_PLAN.md (hwsim-5 SPICE ladder)
- AI-Notes/plans/MATERIALS_TECH_TREE_PLAN.md (mtt-2 CNT builder)
- modules: electrodevice/ (devices+validator+switching),
  materialsScience/ (DFT fragments, model_execution), hwfpga/.
