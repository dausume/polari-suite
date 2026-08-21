# CNT FET full simulation — collaborative plan (Claude ⇄ ChatGPT)

**Date:** 2026-08-20 · **Status: ✅ RATIFIED (D1-D18) + ✅ S0
COMPLETE + ✅ S1 BUILT 2026-08-21 (see the S1 build report below;
polari-framework branch `dev-cnt-1`, review gate = Dustin —
TESTING_OWED §0000). S2+ = a separate go-ahead.**

## S1 build report (2026-08-21, one session, branch dev-cnt-1)

The ratified narrow target landed: ONE aligned semiconducting CNT
((16,0), d 1.253 nm, Lg 15 nm GAA HfO2 t_ox 3 nm, 300 K, Rc prior
5.5 kΩ/terminal), DC Id-Vg + Id-Vd. `modules/cntfet/` (framework
commit 90d0e92), selftest 34/34 headless. Sub-rung outcomes:

- **S1a** bandstructure/electrostatics from chirality: Eg 0.680 eV,
  m* 0.064 m0 (inside the [GUO04] window), GAA Cox eq.(1), scale
  length eq.(7) λ=1.43 nm → n_ss 1.003 / DIBL 0.003 (a
  well-tempered 15 nm device). Metallic chirality → honest refusal.
- **S1b** F2 ToB reference (Rahman 2003) implemented, k-space
  integration, closed-form ≡ numeric integral to 4e-9; triangle
  edge #1 live: ToB (intrinsic, no Rc) lands within 2× of the VS
  path at on-state, [LUN97] ballistic>quasi-ballistic ordering
  holds.
- **S1c** VS-CNFET-derived compact model from the published
  equations only: eq.(9) reproduces the [FC10] v_xo anchors (1%/2%
  at 15/300 nm); the 3 µm anchor misfits −40% and is FLAGGED
  out-of-domain (l≈Lg stated for Lg<30 nm) — recorded, not hidden.
  gm in the anchor's own back-gate context: within 2× of the 40 µS
  record. D8 roles stamped as CNTFETParameterRow rows; D18 anchors
  as rows incl. an explicitly REFUSING undigitized-curves row.
- **S1d** generated construct-gated Verilog-A twin → OpenVAF →
  OSDI → ngspice-46 `pre_osdi` → **D3 equivalence: EQUIVALENT, 220
  points over {Vg,Vd,Lg,d,T,Rc}, worst rel err 4.2e-9** (tol 1e-4).
  Two live catches: (1) damped fixed-point Rc solve oscillates at
  20 kΩ → bisection on the monotone residual; (2) constants.vams
  CODATA values differ from exact SI-2019 → visible subthreshold
  mismatch until both implementations pinned the same constants.
  Toolchain gotcha: OpenVAF-Reloaded binaries need glibc ≥ 2.36;
  original openvaf 23.5.0 (OSDI 0.3) is the older-host fallback
  (ngspice ≥ 44 loads both).
- **D14/D17**: capability endpoint refuses absent fidelities
  (F3-NEGF names its S2+ status); module ledger records deps +
  licenses; CNTFET_MODEL.md is the standalone-capable equations
  doc — every equation cited, Stanford source never read.

## Same-day additions (Dustin's day-time asks, commit 0cd1a73)

- **His two reference papers arrived + license-gated** (both
  cite+link+values; PDFs off-git at ~/Desktop/Research_Papers/):
  Fiori/Iannaccone/Klimeck IEDM 2005 (10.1109/IEDM.2005.1609397,
  ballistic-NEGF CNFET study by the ViDES group — now the
  NEGF-ORACLE-LITERATURE anchor set: (11,0) d=0.9 nm doped-
  extension devices, Ion ~7×/6× ITRS hp32/hp22, Ioff 15× over
  requirement via drain-side hole tunneling into valence bound
  states, off-current f-sensitivity ~2 decades) and Hills 2019
  Nature RV16X-NANO (10.1038/s41586-019-1493-8 — system-precedent
  anchors: 14,702 CNFETs, 63-cell library, VDD 1.8 V, 10 kHz
  measured/1.19 MHz EDA, 15-25 CNTs/FET at pS 99.99%, DREAM 10⁴×
  purity relaxation, RINSE >250×, NOR yield 14400/14400).
- **Citation linkage as a queryable surface** (his rule: proper
  citation actions for linkages): /api/cntfet/citations = source →
  {citation, DOI, linked constants/anchors/parameter rows} + an
  unlinked-rows honesty list (ships empty; the check caught two
  rows live and they were fixed with a [ZF92] tag).
- **NEW `modules/microchip/`** (his ask; SEPARABLE from the
  foundational device modules): the design-level ladder
  device→standard-cell→functional-block→core→chip as
  DesignLevelDefinition rows (each rung names its scale axes — the
  device rung carries manufacturing_regime (D6) ⊥ physics_fidelity
  (D12)), concrete hierarchies as MicrochipDesignNode trees with
  {module,class,name}/anchor references (soft — no device-code
  imports, honest degradation when absent). Seeded: our
  polari-cnt-ladder (S1 device LIVE + film sibling; cell/block/
  core/chip rungs UNBUILT with S4/S6/S7 pointers) and the
  rv16x-nano-precedent tree (every node cited to [HIL19]).
  Traversal API live; GUI traversal page = future frontend pass.
  This module is where S4+ artifacts will hang without bloating
  the device modules.

## S0 verdicts (2026-08-20, license-gated; full per-source reports in
## AI-Notes/evaluations/CNT_FET_SIM_LICENSE_GATE.md)

| gate | verdict |
|---|---|
| NEGF engine (D13) | ✅ **Kwant BSD-2** (LICENSE verified, active 1.5.0) = INCORPORABLE F3 kernel — fork-pin dausume/kwant; CNT = rolled-graphene TB lattice, mode-resolved transmission, coherent-only (honest limit); Poisson user-supplied → Polari-owned cylindrical solver (or PESCADO if its UNVERIFIED license passes). **NanoNet MIT** (active 2026) = complementary GF-formalism pin. ⛔ ViDES = CONFIRMED 4-clause-BSD (advertising clause read in license.txt) → external-process oracle ONLY, unmaintained. ⛔ NEMO5 = NC binds use — excluded entirely. sisl(MPL-2)+TBtrans(GPL-3) = viable heavier fallback. |
| Verilog-A route | ✅ GO: **OpenVAF-Reloaded** (GPL-3.0, active; original dormant since 2023) → OSDI → **ngspice ≥42** (noise ≥42, OSDI 0.4 ≥44; current 47; our image carries 46). Construct gate for the clean-room model: single flat module, scalar params, static contributions — NO arrays/named events/cross()/bit-shifts/analog filters/genvar. 🔑 **BSIM-BULK/CMG + EKV 2.6 are ECL-2.0** (Apache-derivative, FSF GPLv3-compatible) = legitimate structure templates. ADMS deprecated; XSPICE not a compact-model path. |
| Blocked code | ⛔ Stanford VS-CNFET + CCAM both under **NEEDS Modified CMC License** (verified from nanoHUB license pages — NOT the expected single-user NC: redistribution allowed but "not to charge for the code itself" = GPL-incompatible price restriction). Never read their source. RV16X-NANO: no released collateral, data on-request → scientific reference only. **No open CNFET compact model exists anywhere — ours is the first.** ✅ **CNFET-OCL/CNFET7** (BSD-3): open 7nm/5nm CNFET CELL LIBRARIES (Liberty/LEF) built with VS-CNFET — usable artifacts + precedent. |
| Papers | ZERO CC-licensed primaries → ALL cite+link+extracted-values (none commit-direct). VS-CNFET Part I/II legally free (arXiv 1503.04397/98 + PopLab author PDFs); Deng-Wong 2007 paywalled (DOIs recorded); Rahman 2003 ToB paper free via nanoHUB resources/122. CC BY candidates (MDPI reviews, re-confirm on-page) may commit. |
| Characterization (S5) | ✅ open stack exists: **ASAP7 BSD-3** (LICENSE verified) = structural PDK template (its artifact inventory recorded); **CharLib GPL-2.0** (subprocess/pin only — never merge; ⚠ 2.0.0 DEPRECATED sequential characterization; pin its infinitymdm/PySpice fork too) + **lctime AGPL-3.0-or-later** (active) for setup/hold/recovery/removal; **OpenSTA GPL-3** standalone Liberty gate; Yosys ISC / OpenROAD BSD-3. |
| Calibration anchors (S2) | 12-anchor prioritized list recorded (full detail in the gate doc). 🔑 CORRECTION: VS v_xo anchor = **Franklin & Chen 2010** (Lg 15nm/300nm/3µm same-tube; v_xo 3.8/1.7/0.47e7 cm/s), NOT Franklin 2012 (that calibrated Luo 2013). Rc: Franklin 2014 six-metal Rc(Lc) + Cao 2015 end-bonded size-independence. Aligned arrays: Liu 2020 + Lin 2023 (per-curve biases UNVERIFIED, paywalled). Bandgap: Wildöer/Odom Eg≈0.77 eV·nm/d, γ0=2.7±0.1eV. nanoHUB VS bundle SHIPS the calibration data files (NEEDS license — extract-only expected). No CC primary I-V data exists → digitize curves into cited rows. |
| F2 literature | ✅ IMPLEMENTABLE from papers alone: Rahman 2003 publishes the complete ToB equation set; hyperbolic E(k) from Guo 2004 (arXiv OA); T=λ/(λ+L) Lundstrom 1997; mfp anchors λ_ac≈300nm / λ_op≈10-15nm (Javey/Park 2004, arXiv OA) with Perebeinos 2005 d,T-scaling. FETToy license login-gated UNVERIFIED → equations+published-curves only. No adoptable open ToB implementation exists. |
Dustin's directive: collaborate WITH ChatGPT (he relays messages; no
browser bridge this session) to plan the path to FULLY SIMULATING CNT
FETs in the polari stack. Fab of a CNFET RISC-V MCU is the horizon
vision (ChatGPT's hierarchy: device → cells → PDK → Yosys/OpenROAD →
Ibex), NOT the near-term target. Dustin will supply: (1) his existing
CNT research paper (reference anchor, arriving later), (2) the known
functional CNT RISC-V design (2019 RV16X-NANO, ~14k CNFETs) as
precedent.

## Round 5 refinements (ChatGPT + Dustin, 2026-08-20 — post-S0):
## decisions D15-D18

ChatGPT accepted all S0 verdicts and corrections. New decisions:

15. **F3 = two implementations under ONE interface**: Kwant =
    default incorporable NEGF-kernel path; NanoNet = complementary
    formalism/reference implementation; ViDES is NOT architecturally
    central — it remains a legally isolated reproduction oracle
    where useful.
16. **Characterization executors are swappable behind the Polari
    schema**: CharLib only for the combinational arcs it supports
    well; lctime for setup/hold + sequential arcs; BOTH must emit
    into the same Polari CellCharacterizationRun schema — no
    external tool defines our data model. **AGPL ruling (Dustin's
    question, answered with recommendation):** AGPL is NOT NC-like —
    commercial + government use fully permitted, and the §13 network
    clause never reaches Polari users because (a) lctime's OUTPUTS
    (Liberty files) are not covered by its license, and (b)
    subprocess isolation (required anyway for GPL-2.0 CharLib) keeps
    it a separate work. Caveat = perception: some org policies ban
    AGPL internally → lctime is OPTIONAL, separately-installed,
    subprocess-isolated, flagged absent-by-default in the D14
    ledger; exit paths = CharLib's sequential reimplementation or
    our own loop. ⏳ Dustin may still veto AGPL outright — nothing
    blocks before S5.
17. **The compact model is a standalone-capable research artifact**:
    since no open CNFET compact model exists, the clean-room GPLv3
    VS-derived implementation (equations doc, implementation notes,
    validation suite, provenance) stays modular enough to live
    independently of Polari later (own-repo candidate).
18. **Digitization provenance is a PERMANENT rule**: every digitized
    literature curve retains the raw digitized points AND the full
    transformation history — figure identifier, axis scaling,
    extraction method, estimated digitization error, normalizations,
    and any subsequently fitted parameter — so calibration
    disagreements trace to graph-extraction vs physics. (Extends the
    DigitizedDataset discipline.)

**S1 first concrete target (narrowed, agreed):** ONE aligned
semiconducting CNT — one chirality/diameter, one gate stack, one
temperature, one contact prior — DC Id-Vg and Id-Vd only, Python
reference + cross-checked Verilog-A, BEFORE any variability or
multi-tube aggregation. The smallest object that can fail
transparently. **No remaining architectural blocker — S1 starts on
Dustin's go-ahead.**

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
  (see below).
- **Round 2 (ChatGPT, received same day) — the substantive answers:**
  - REFRAME accepted by us: goal = "predictive design-space
    simulation with explicit uncertainty," not signoff-sense "full
    simulation."
  - **S0 license findings (ChatGPT-reported — OUR S0 STILL
    RE-VERIFIES ALL OF THESE):** OpenVAF + OpenVAF-Reloaded =
    GPL-3.0 (clean); ASAP7 = BSD-3-Clause (usable as template);
    NanoTCAD ViDES = old-BSD-style WITH ADVERTISING CLAUSE (⚠ Claude
    note: 4-clause BSD is GPL-INCOMPATIBLE for linking — external
    oracle only, never vendored, pending exact text); Stanford CNFET
    + VS-CNFET packages = non-transferable single-user NC license on
    the old user guide → ⛔ reference-only until relicense proven;
    CCAM = "NEEDS Modified CMC License" on nanoHUB → ⛔ blocked
    pending exact terms; RV16X-NANO collateral = no trustworthy
    redistribution license found → scientific reference only.
  - (a) Center S1 on a CLEAN-ROOM implementation of the VS-CNFET
    equations (Part I intrinsic I-V/Q-V + Part II extrinsic:
    Rc, S/D tunneling, BTBT, parasitics; calibrated to 15nm
    experimental devices; older Deng-Wong has known sub-100nm
    pathologies) with a SWAPPABLE transport kernel
    (virtual_source | landauer_quasiballistic | NEGF_reference).
    VS = the compact CIRCUIT model, not the source of truth; NEGF/
    experiment validate it. Label honestly: model_family
    "VS-CNFET-derived", implementation "independent",
    numerically_equivalent_to_stanford=false. Papers suffice for a
    scientifically useful reimplementation, NOT for numerical
    identity with Stanford's Verilog-A.
  - (b) Minimal parameter set: {chirality/diameter, Lg, tube
    count/pitch, gate topology, EOT (tox+εr), VDD, contact length +
    effective Rc, Vt/work-function offset, transport param (mfp or
    vxo), T}. Derived: diameter→Eg (inverse-diameter), Cq, Cox,
    ballistic limits. Priors: Rc, vxo, mobility, mfp, DIBL,
    fringe C, BTBT, S/D tunneling. Monte-Carlo distributions: Rc,
    count, pitch, diameter/chirality, metallic fraction, Vt. 🔑 Rc
    must NEVER hide inside effective mobility — at 7nm it dominates
    ranking. Schema = decomposed objects (Geometry, MaterialState,
    GateStack, Contact, TransportModel, Parasitics,
    VariabilityModel), not one giant row.
  - (c) Film and aligned = SIBLING device classes over shared
    CarbonNanotube material primitives with a common interface
    (evaluate_dc/evaluate_charge/generate_spice/estimate_geometry/
    sample_variation/validate). Never scale the 14mm film result to
    infer aligned devices. Film device becomes the regression test
    proving multiple CNT regimes coexist without conflation.
  - (d) Validation = 3 layers: VS-CNFET calibration-device
    experimental I-V (µm → 15nm); Deng-Wong papers as independent
    quasi-ballistic benchmark (papers, not code); NEGF oracle
    (ViDES-class) on sparse sweeps → compact-vs-NEGF error surface.
    Validate Id-Vg/Id-Vd families, SS, Ion, Ioff, gm, DIBL, Cgg/Qg,
    Rc sensitivity, Lg + diameter scaling — not one headline
    on/off. Sub-rungs S1a electrostatics → S1b quantum-transport
    reference → S1c compact fit → S1d ngspice (so convergence ≠
    validation).
  - (e) Liberty: ngspice → testbench generator → measurements →
    Liberty → Yosys → OpenSTA. Investigate **CharLib** (2025 open
    Python cell characterizer) before writing our own loop; keep a
    Polari CellCharacterizationRun schema ABOVE the executor. Sparse
    grid first (slew fast/nom/slow × load FO1/2/4/8; rise/fall cell
    + transition arcs; setup/hold/clk→Q for sequential). MANDATORY
    cross-check: composed-gate SPICE vs Liberty+OpenSTA path delays
    — abstraction must fail loudly before any CPU.
  - (f) SRAM out until synthesis proven; DFF register file/RAM for
    first machines; SRAM later as its OWN arc (stability/margins/
    assist/sense — a bad SRAM abstraction would slander the logic
    platform).
  - REORDERED ROADMAP S0..S8: S0 license+reference gate (papers/
    datasets/equations/executables tracked separately) → S1 single
    aligned CNFET (a..d above) → S2 DEVICE VALIDATION (before
    variability — else Monte Carlo around the wrong mean) → S3
    variability → S4 circuits (INV/NAND2/RO/DFF then rest) → S5
    characterization (Liberty + SPICE-vs-STA regression) → S6
    synthesis (counter → ALU → FSM → RV32E) → S7 physical-design
    abstraction (LEF-ish, wire RC, OpenROAD) → S8 SRAM.
  - Minimal library before synthesis = INV NAND2 BUF DFF (universal
    logic + state); XOR/MUX = optimization cells, later.
  - Architectural principle: separate physical / derived-physics /
    compact-model / calibration / simulation-output parameters —
    never all flat fields on the transistor. Enables "which MCU
    conclusions depend on measured physics vs semi-empirical
    calibration?"
- **Round 2b (Dustin's steer, same day):** add 1-2 INTERMEDIATE CNT
  device tiers by MANUFACTURING SCALE/difficulty — we are developing
  the manufacturing methods as we go.
- **Round 2c (ChatGPT, integrating Dustin's steer):** 5-tier
  manufacturability ladder: percolation film (have) → coarse aligned
  (µm–multi-100nm Lg, tens-hundreds of tubes, alignment/density/
  purification/contacts are the research questions; FIRST tier where
  the aligned compact model is relevant) → fine aligned (~50-200nm
  Lg; pitch control, Rc + electrostatics + overlay start dominating;
  first fabricable cell-library tier) → aggressively scaled
  (~10-30nm; S/D tunneling, BTBT, short-channel, contact-length
  scaling enter) → ~7nm target. Implementation: ONE AlignedCNTFET
  class + `manufacturing_regime` knob (NOT separate classes — same
  physics), plus MANUFACTURING PROCESS OBJECTS contributing
  DISTRIBUTIONS not ideal values (CNTAlignmentProcess angle σ,
  CNTPlacementProcess pitch σ + missing-tube prob,
  CNTPurificationProcess metallic fraction, ContactFormationProcess
  Rc µ/σ + min contact length, LithographyProcess feature/overlay,
  GateStackProcess tox/εr distributions) → transistor declares
  target_pitch, process predicts pitch±σ → Monte Carlo generates
  the device population. Feedback loop: manufacturing method →
  measured process capabilities → process model → device MC →
  circuit yield → dominant limitation → improve method. Circuit
  milestones advance WITH manufacturing tier (film→inverter; coarse→
  inverter/NAND/RO; fine→small test chip/counter; scaled→synthesized
  blocks; 7nm→RISC-V-scale).
- **Round 3 (Claude → ChatGPT, sent via Dustin):** convergence +
  Polari-idiom mapping + ViDES GPL-incompatibility catch + remaining
  questions g-i + the proposed decision list D1-D11 for Dustin's
  ratification (below).
- **Round 4 (ChatGPT, received 2026-08-20):** endorses all 11
  decisions + two amendments (folded in below as amended D3 + new
  D12). Answers:
  - **(g) YES to the intermediate rung — full fidelity ladder
    F0..F4:** F0 analytical/material derivation → F1 VS-CNFET
    compact → F2 Landauer/top-of-barrier quasi-ballistic
    (I=(4q/h)∫T(E)[fS−fD]dE; T≈1 ballistic, T≈λ/(λ+L)
    quasi-ballistic, then energy-dependent backscattering) → F3
    mode-space self-consistent NEGF → F4 atomistic NEGF. F2 is cheap
    enough to sweep AND interpretable — the validation triangle
    NEGF / quasi-ballistic / (VS compact ↔ experiment): each
    disagreement edge teaches something different.
  - **NEGF budget:** no credible literature prior for our exact
    geometry/grid/CPU — provision as ENGINEERING PRIORS ONLY (F2
    ms–s per bias sweep; F3 fixed-potential s–min per point; F3
    self-consistent Poisson+NEGF min–tens-of-min per point; F4
    longer) and REPLACE with measurements. ViDES tutorials include a
    10nm-channel/30nm-total CNT with 2 modes — CPU-only is not
    absurd. **First benchmark deliberately tiny**: 1 chirality, Lg
    10nm, Vd {0.05, 0.3}, Vg {off, ~Vt, on} = 6 points; collect
    wall/CPU time, peak RAM, NR + NEGF iterations, energy points,
    mode count, residual. Use CONTINUATION (solution(Vg_n) seeds
    Vg_n+1). **Adaptive oracle sampling = first-class**: spend NEGF
    points where VS/F2 disagree, skip where they agree with low
    uncertainty.
  - **(h) BOTH implementations, different roles** (amendment 2):
    Python = canonical scientific/reference implementation (owns
    parameter derivation, provenance, validation, fitting,
    uncertainty, F2/NEGF/experiment comparison, parameter
    manifests; slow + transparent). Clean-room Verilog-A = the
    circuit-execution implementation, compiled via OpenVAF → OSDI →
    ngspice (the preferred modern ngspice route; proper Jacobians —
    NOT B-source graphs long-term). Both implement the SAME equation
    revision + MANDATORY automated numerical-equivalence regression
    (grid over Vg, Vd, Lg, diameter, T, Rc with explicit
    tolerances). .model cards stay non-opaque via generated run
    bundles: cntfet.osdi + device-model.sp + parameter-manifest.json
    (parameter/value/unit/role/source_row/citation/confidence/
    derived_from/equation_revision, hashed set) + provenance.json.
    ⚠ OpenVAF documents unsupported Verilog-A corners — S0 also
    gates the LANGUAGE CONSTRUCTS the clean-room model uses.
  - **(i) NEVER switch physics at regime boundaries** (amendment 1):
    mechanisms are ADDITIVE (I_total = I_channel + I_SD_tunnel +
    I_BTBT + …; C_total likewise) and vanish naturally where
    negligible — no Lg=30.1nm OFF / 29.9nm ON cliffs. The
    cost/convergence concern is solved by the ORTHOGONAL
    physics_fidelity axis with profiles: VS_MINIMAL (channel+Rc+
    basic parasitics), VS_FULL (+BTBT+S/D tunneling), QUASI_
    BALLISTIC (Landauer channel), NEGF (mechanisms emerge/modelled —
    with the nuance that "emerges" depends on Hamiltonian).
    Same equations, different physical consequence per regime
    (coarse: I_SDtunnel/I_total ~1e-20; aggressive: ~0.31 of Ioff).
    Convergence = numerical techniques (smooth differentiable
    expressions, bounded exponentials, safe log/exp, continuation,
    voltage stepping, parameter homotopy) — never physics switches.
  - **Architecture summary accepted:** materials → manufacturing
    process (distributions+σ) → device geometry → physics fidelity
    (VS | quasi-ballistic | NEGF) → prediction+uncertainty →
    experiment → residual/recalibration; and NEGF NEVER enters the
    digital inner loop — it bounds/improves the compact model that
    ngspice executes millions of times. "The most important
    architectural decision left before S1."

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

## Proposed decisions (Dustin ratifies/edits — nmp numbering)

1. **Goal**: predictive design-space simulation with explicit
   uncertainty — never signoff prediction; no simulated 7nm result
   is ever presented as a fabrication prediction.
2. **Roadmap = S0..S8** (ChatGPT's reorder, accepted): license gate →
   single aligned CNFET (S1a electrostatics → S1b NEGF reference →
   S1c compact fit → S1d ngspice) → device VALIDATION → variability
   → circuits → characterization → synthesis → physical-design
   abstraction → SRAM last.
3. **Compact model**: clean-room VS-CNFET-DERIVED from the published
   Part I/II equations; swappable transport kernel; labeled
   independent + numerically_equivalent_to_stanford=false; never
   called "Stanford VS-CNFET". *(Amended round 4:)* **Python is the
   canonical scientific/reference implementation; clean-room
   Verilog-A (OpenVAF → OSDI → ngspice) is the circuit-execution
   implementation; both implement the same equation revision and
   must pass automated numerical-equivalence regression tests.**
   Generated run bundles (osdi + model card + hashed
   parameter-manifest + provenance JSON) keep .model cards
   non-opaque.
4. **License gates**: Stanford model packages + CCAM = ⛔ blocked
   (reference-only) unless S0 proves otherwise; OpenVAF(-Reloaded) +
   ASAP7 = candidates pending OUR verification; ViDES = EXTERNAL
   ORACLE process only (advertising-clause BSD is GPL-incompatible
   for linking) pending exact license text; RV16X-NANO = scientific
   reference only; CharLib added to the S0 gate list. All
   ChatGPT-reported statuses re-verified by us (API + LICENSE +
   header, all three).
5. **Device taxonomy**: CNTPercolationFilmFET (exists) and
   AlignedCNTFET = SIBLING classes over shared CarbonNanotube
   primitives with a common device interface; film result never
   geometrically scaled to infer aligned behavior; film device =
   the standing regression test.
6. **Manufacturing regimes (Dustin's steer)**: ONE AlignedCNTFET
   class + manufacturing_regime knob (coarse_alignment |
   fine_alignment | aggressively_scaled | target_7nm); regime
   thresholds are data, not code forks.
7. **Manufacturing processes as first-class objects contributing
   DISTRIBUTIONS** (alignment σ, pitch σ + missing-tube prob,
   metallic fraction, Rc µ/σ, litho feature/overlay, gate-stack
   spread); devices declare targets, processes predict populations,
   Monte Carlo instantiates them; the manufacturing feedback loop is
   the point. Ties into the manufacturing-tools tech tree +
   accessibility tiers; process capabilities ride DigitizedDataset
   refusal discipline (unmeasured → prior-flagged or refusing).
8. **Parameter roles separated as schema**: physical | derived |
   compact-model | calibration | output — enabling "which
   conclusions rest on measurement vs calibration" queries.
9. **Rc is first-class** — never folded into effective mobility.
10. **Minimal cell set before synthesis**: INV NAND2 BUF DFF;
    XOR/MUX later as optimization cells; SRAM = S8, its own arc;
    DFF-array memory for first synthesized machines.
11. **Characterization**: Polari CellCharacterizationRun schema
    above any executor (CharLib if it gates clean, else our own
    loop); sparse grid first; the SPICE-vs-(Liberty+OpenSTA)
    composed-path regression is MANDATORY before any CPU work.
12. **Manufacturing regime ⊥ physics fidelity** *(added round 4)*:
    manufacturing_regime describes what a process can plausibly
    produce; physics_fidelity (F0 analytical → F1 VS compact →
    F2 Landauer quasi-ballistic → F3 mode-space NEGF → F4 atomistic
    NEGF; profiles VS_MINIMAL/VS_FULL/QUASI_BALLISTIC/NEGF)
    describes how accurately/expensively the device is evaluated.
    Physical mechanisms are ADDITIVE and never switch
    discontinuously at regime boundaries; convergence is solved
    numerically (smoothing/continuation/homotopy), never by physics
    switches. Corollaries: the F2 rung is built (cheap, sweepable,
    interpretable — completes the NEGF/F2/VS-experiment validation
    triangle); NEGF runtimes enter as engineering priors REPLACED by
    a measured tiny benchmark (6 bias points, continuation,
    wall/RAM/iteration telemetry) before any production grid;
    adaptive oracle sampling is first-class (NEGF spend goes where
    VS/F2 disagree); NEGF never enters the digital inner loop.
13. **Prefer an INCORPORABLE open-source NEGF engine** *(Dustin's
    ratification amendment, 2026-08-20)*: S0 searches for a
    GPLv3-compatible quantum-transport/NEGF engine suitable for
    INCORPORATION into polari's own simulation capabilities (vendored
    or fork-pinned as the F3 kernel + comparison backend), not just
    external-oracle use. Candidates to gate: Kwant, NanoTCAD ViDES
    (exact license text), sisl + TBtrans, SIESTA/TranSIESTA, OpenMX,
    GPAW, others found. Incorporation preferred where the license
    passes; external-oracle-process is the fallback for
    GPL-incompatible-but-usable tools; ⛔ NC/academic-only stays
    blocked entirely. Fit criteria: CNT/1D tight-binding mode-space
    transport, self-consistent Poisson (or coupleable), Python
    integration, CPU-only viable.
14. **Rigorous modularization with accountability** *(Dustin,
    2026-08-20, mid-S0)*: the CNT sim capability is built as
    separable modules so an instance carries ONLY what it needs at
    any given time — the standing "sims know only what they need to
    know" directive applied here. Concretely: (a) the device/object
    layer (geometry, processes, parameter rows) is a thin module
    with no heavy deps; (b) each fidelity kernel (F1 compact / F2
    quasi-ballistic / F3 NEGF) is an OPTIONAL engine behind a knob —
    F3's engine + its dependency stack live on a worker (the
    msci-engines swarm pattern), never as a hard import of the core
    module; (c) the Verilog-A/OSDI + characterization tooling is its
    own module, needed only by circuit-phase instances; (d)
    ACCOUNTABILITY: a per-module dependency/capability ledger (which
    fidelities/features each module provides, which external
    tools+licenses it pulls in, which instances carry it) — tracked
    the tech-tree data_dependencies way so "what is loaded where and
    why" is queryable data, and honest capability endpoints report
    what an instance can/cannot evaluate (refusal, not silent
    fallback, when a fidelity isn't present).

## Original proposed staging (round 1, S0..S4 — SUPERSEDED by
## decision 2's S0..S8)

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

**Paper-storage rule (Dustin 2026-08-20, refined same day):** the
suite repos are PUBLIC, so committing a paper = redistributing it.
- **Explicitly open papers MAY be committed directly**: only when
  the paper itself carries a license permitting redistribution
  (CC BY / CC BY-SA / CC0 or an equivalent explicit open-access
  grant), VERIFIED per paper — being on arXiv is NOT sufficient
  (arXiv's default license grants only arXiv distribution rights);
  check the license statement on the paper/landing page. Record the
  license alongside the stored PDF.
- **Everything else = citation + link + extracted values only**:
  paper stays off-git (local disk); what enters git is the standing
  values-as-facts pattern (Monash/WHO precedent) — cited data rows
  with value, unit, DOI/authors/year, figure/table number,
  confidence, plus the link. NC-licensed papers stay in this bucket
  too (project NC discipline).
Applies to VS-CNFET Part I/II, Deng-Wong, and every S0 reference;
S1 calibration anchors from Dustin's paper enter per whichever
bucket its license puts it in — values-as-rows either way.

## Grounding index

- memory: hardware-simulation (hwsim-5 CNT FET rungs — the film
  precedent), materials-tech-tree (CNT builder NEXT), solid-state-
  physics (ssp-5 QE knob), polari-simulation-framework (5-level
  resolutions), tech-tree-and-blcnc-planning.
- AI-Notes/plans/HARDWARE_SIMULATION_PLAN.md (hwsim-5 SPICE ladder)
- AI-Notes/plans/MATERIALS_TECH_TREE_PLAN.md (mtt-2 CNT builder)
- modules: electrodevice/ (devices+validator+switching),
  materialsScience/ (DFT fragments, model_execution), hwfpga/.
