# Handoff — CNT FET simulation S1 build (fresh session entry point)

**Date:** 2026-08-20 · **From:** the planning session (Claude⇄ChatGPT
collaborative plan, Dustin relaying) · **For:** the fresh session that
builds S1. **Dustin's instruction: start S1 from a /clear.** Read
this, then the two source docs, then build.

## Read first (in order)

1. `AI-Notes/plans/CNT_FET_SIMULATION_PLAN.md` — THE plan: decisions
   D1-D18 (ratified 2026-08-20), S0 verdicts table, fidelity ladder,
   dialogue ledger. Everything below is a pointer into it.
2. `AI-Notes/evaluations/CNT_FET_SIM_LICENSE_GATE.md` — the six S0
   research reports (licenses, citations, DOIs, anchor values).
3. Memory: `cnt-fet-simulation.md` (+ hardware-simulation.md for the
   existing electrodevice/ngspice seams and gotchas).

## State

- Plan RATIFIED (D1-D18), S0 license/reference gate COMPLETE, ALL
  GREEN — no architectural blockers. ChatGPT collaboration continues
  only via Dustin relaying messages; S1 does not need it.
- ⚠ Branch reality: suite + polari-rf-node + polari-framework working
  copies sit on `dev-nmp-1` (nmp = unmerged review gate; DON'T merge).
  The cnt plan/gate/handoff docs are committed on the SUITE
  `dev-nmp-1` branch — on disk for you regardless.
- **S1 code goes on a NEW polari-framework branch `dev-cnt-1` cut
  from `dev`** (branch-per-phase; keeps cnt independent of the nmp
  review queue): `cd polari-rf-node/polari-framework && git checkout
  dev && git checkout -b dev-cnt-1`. Commit docs updates to the suite
  as you go (suite is on dev-nmp-1; that's fine, they ride together).

## The S1 target (narrow, agreed with ChatGPT — do NOT widen)

ONE aligned semiconducting CNT: one chirality/diameter, one gate
stack, one temperature, one contact-resistance prior. DC Id-Vg and
Id-Vd only. Python reference implementation FIRST, then the
Verilog-A/OSDI twin with a numerical-equivalence regression. NO
variability, NO multi-tube aggregation, NO cells — those are S2+.
"The smallest possible object that can fail transparently."

Sub-rungs: S1a bandstructure/electrostatics → S1b transport reference
(F2 top-of-the-barrier serves here; heavy F3/Kwant can wait) → S1c
VS-derived compact fit → S1d ngspice implementation + equivalence.

## Build shape (the decisions that bind it)

- NEW thin module (suggest `modules/cntfet/`), decomposed per D14:
  device/object layer with NO heavy deps; fidelity kernels optional;
  capability endpoint refuses honestly when a fidelity is absent.
  Schema = decomposed objects (D2b): AlignedCNTFETGeometry,
  CNTMaterialState, GateStack, CNTContact, CNTTransportModel,
  CNTParasitics (+ later CNTVariabilityModel, process objects).
- Sibling-not-successor (D5): do NOT touch the existing film FET in
  electrodevice/ except to reuse shared CNT material primitives and
  eventually the common device interface (evaluate_dc /
  evaluate_charge / generate_spice / sample_variation / validate).
- Parameter roles (D8): physical | derived | compact-model |
  calibration | output — a role field on property rows, never flat
  constants. Rc is first-class (D9), never folded into mobility.
- Mechanisms additive (D12): no regime switches; physics_fidelity
  profiles (VS_MINIMAL first) choose what's evaluated.
- Model doc + code stay standalone-capable (D17): this is the FIRST
  open CNFET compact model anywhere (S0-verified) — equations doc
  with per-equation paper citations, validation suite, provenance.
- Reuse the existing seams: electrodevice/device_validator.py (the
  standards judge — derivations never self-bless), SpiceModelCard
  versioned rows, the ngspice capability endpoint, structured
  property records ({value, context, confidence}), DigitizedDataset
  refusal discipline, selftest-per-module convention (run via
  `pol modules selftest`).

## Physics sources (all cite-values-only; NEVER read blocked code)

- ⛔ CLEAN-ROOM ABSOLUTE: never read Stanford VS-CNFET or CCAM source
  (NEEDS Modified CMC License). Equations come from papers only.
- VS-CNFET equations: arXiv:1503.04397 (Part I intrinsic) +
  1503.04398 (Part II extrinsic) — legally free; cite IEEE TED DOIs
  (10.1109/TED.2015.2457453 / .2457424); label the implementation
  model_family="VS-CNFET-derived", implementation="independent",
  numerically_equivalent_to_stanford=false (D3).
- F2 ToB reference: Rahman 2003 (free PDF nanohub.org/resources/122,
  DOI 10.1109/TED.2003.815366); T=λ/(λ+L) Lundstrom 1997; hyperbolic
  E(k) + m*=Eg/2vF² from arXiv cond-mat/0312551.
- Anchors: Eg≈0.77 eV·nm/d (Wildöer 10.1038/34139, γ0=2.7±0.1eV);
  λ_ac≈300nm, λ_op≈10-15nm (Javey cond-mat/0309242, Park
  cond-mat/0309641; d,T-scaling Perebeinos cond-mat/0411021).
- Calibration target: Franklin & Chen 2010 (10.1038/nnano.2010.220,
  author PDF free) — the v_xo anchor (3.8/1.7/0.47e7 cm/s at Lg
  15nm/300nm/3µm, d=1.2nm). Digitized curves obey D18: keep raw
  points + figure id + axis scaling + method + error estimate +
  normalizations + fits. Scratch PDFs already saved under the
  planning session's tool-results dir (see gate doc §calibration) —
  extraction copies only, never committed.
- Papers two-bucket rule: only explicit CC BY/BY-SA/CC0 papers may be
  committed (license recorded); everything else cite+link+values.

## S1d toolchain (when you get there)

- OpenVAF-Reloaded (arpadbuermen/OpenVAF, GPL-3.0) → .osdi →
  ngspice `pre_osdi` (backend image has ngspice-46; OSDI needs ≥42;
  paths resolve vs the NETLIST). Install the binary under ~/tools.
- Verilog-A construct gate: single flat module, scalar params, static
  contributions; NO arrays/named events/cross()/bit-shifts/analog
  filters/genvar. ECL-2.0 BSIM/EKV sources (dwarning/VA-Models) are
  legitimate STRUCTURE templates — reading them is allowed.
- Mandatory D3 regression: Python reference vs OSDI over a grid of
  {Vg, Vd, Lg, diameter, T, Rc} with explicit tolerances.
- Fork-pins (dausume/, license pins never >=) owed only WHEN adopted:
  kwant, NanoNet (F3, later), CharLib + infinitymdm/PySpice, lctime
  (S5, AGPL — Dustin's veto still open, D16).

## Dustin's open items (do not block on these)

- His CNT research paper: when supplied, license-check → bucket
  (D-rule in plan §Process), then digitize its measurements as
  calibration rows.
- Optional: relay S1 progress to ChatGPT (he ferries).
- Standing elsewhere: isle-core night GUI test (findings react
  first if they arrive — see GUI_TEST_AND_DAY_WORK_HANDOFF.md), nmp
  merge gate, pub blockers. cmp arc is SHELVED (plans/shelved/).

## Definition of S1-done

Selftest-covered module where: seeded one-tube device derives
diameter/Eg/thermal quantities from cited anchors; Python reference
produces Id-Vg + Id-Vd families; F2 ToB reference implemented and
compared (validation triangle edge #1); calibration vs the digitized
Franklin & Chen 2010 curves recorded with residuals (D18 provenance);
Verilog-A twin compiles under the construct gate and passes the
equivalence regression in ngspice; device_validator grades the
device; capability endpoint reports which fidelities exist. All
literature numbers = flagged, cited, tunable priors. Honest refusals
where data is absent — never invented values.
