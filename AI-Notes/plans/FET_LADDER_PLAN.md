# FET LADDER PLAN — the open-silicon rungs (2026-08-30)

Dustin's direction (2026-08-30): the best silicon FET we can
LEGITIMATELY reconstruct from public / openly licensed material is not
"90 nm" — climb the ladder, but keep TWO INDEPENDENT AXES on every rung
and never let a predictive 7 nm PDK look better proven than a measured
90 nm die. Code: `polari-framework/modules/sifet/si_ladder.py`
(`SiliconProcessNode` rows, anchors, evidence, IP, `ladder_report`),
selftest `sifet/selftest_ladder.py`.

## 1. The two axes (+ one evidence-only flag)

| axis | field | vocabulary |
|---|---|---|
| rights (what we may DO) | `rights_class` | incorporable-open · clean-room-reconstructable · reference-oracle · encumbered · unresolved |
| evidence (how REAL the numbers are) | `fabrication_evidence` | measured-fabricated-device · reconstructed-from-published-silicon · calibrated-predictive · predictive-only · hypothetical |
| manufacturability | `manufacturable` | True ONLY with evidence of an actually available open process (MPW / foundry accepting the rules). **An open predictive PDK is not such evidence. Today: no rung qualifies** — every row carries `manufacturable_reason`. |

The report shows both columns and never collapses them. GPLv3
direction: Apache-2.0 and BSD-3-Clause are one-way compatible INTO a
GPLv3 project (the combined work is GPLv3); NC / research-only terms
are a HARD BLOCKER per the suite licence gate.

## 2. The ladder

| node | rung (`name`) | arch | rights_class | fabrication_evidence | licence (verified?) | GPLv3 | manuf. | model | what we can use | what to search |
|---|---|---|---|---|---|---|---|---|---|---|
| 90 | `polari-si-90-class` (ours) | planar bulk | clean-room-reconstructable | reconstructed-from-published-silicon (textbook physics, **un-anchored**) | GPL-3.0 (ours) | yes | False | VS | everything — Vt/Cox/µ/v_xo/λ from [SZE07]/[TN09]/[KHA09] | a published 90 nm bulk NMOS Id–Vg/Id–Vd figure (IEDM 2002-03) to digitize as an anchor |
| 65 | `lit-65-planar` | planar bulk | reference-oracle | measured-fabricated-device | — | to-verify | False | none | headline Idsat / Ioff as oracle once verified; PTM 65 card as 2nd oracle | Bai et al. IEDM 2004 (Intel 65 nm, 35 nm Lg) — DOI + numbers; PTM 65nm_HP |
| 45 | **`freepdk45`** (S1) | planar bulk | **incorporable-open** | **calibrated-predictive** (PTM 45 tuned to Fujitsu IEDM 2007 silicon) | Apache-2.0 (verified 2026-08-30, eda.ncsu.edu/freepdk/freepdk45) | yes (one-way) | False ("generic, not a foundry process") | BSIM4 | numbers + design rules as CALIBRATION ANCHORS for OUR VS device; PDK artefacts incorporable with NOTICE; the BSIM4 card is compared against, not shipped as ours | Miyashita et al. IEDM 2007 pp.251-254 (measured curves); FreePDK45 variation files |
| 45 | `lit-45-planar` | planar HKMG | reference-oracle | measured-fabricated-device | — | to-verify | False | none | measured-silicon oracle FreePDK45 should be judged against | Mistry et al. IEDM 2007 (Intel 45 HKMG); Miyashita IEDM 2007 |
| 32 | `ptm32` | planar bulk | **unresolved** (terms not fetched; ptm.asu.edu unreachable 2026-08-30; only an "acknowledge this URL" condition found) | calibrated-predictive (Zhao & Cao TED 2006 "<10 %" — to verify) | none found | to-verify | False | BSIM4 | local oracle in ngspice; NO redistribution until terms read | fetch ptm.asu.edu terms verbatim; 32nm_HP.pm header |
| 32 | `lit-32-planar` | planar HKMG | reference-oracle | measured-fabricated-device | — | to-verify | False | none | measured oracle | Natarajan et al. IEDM 2008 (Intel 32); TSMC/GF 28 nm VLSI 2010 |
| 22 | `lit-22-trigate` | tri-gate | reference-oracle | measured-fabricated-device | — | to-verify | False | none | fin geometry as a PRIOR for `finfet-class` once verified | Auth et al. VLSI 2012 (Intel 22 tri-gate); PTM-MG 20 nm |
| 15 | `freepdk15` | FinFET | **encumbered** | predictive-only | BSD-3 (code) **+ CC-BY-NC-SA-4.0 (design-rule kit)** — verified 2026-08-30 | **no** | False | BSIM-CMG | CITE only; NC half = hard blocker; vendor nothing | nothing until NCSU relicenses; PTM-MG 14/16 as oracle |
| 14 | `lit-14-finfet` | FinFET | reference-oracle | measured-fabricated-device | — | to-verify | False | none | measured FinFET oracle | Natarajan et al. IEDM 2014 (Intel 14); PTM-MG 14 nm |
| 7 | `asap7` | FinFET | **incorporable-open** | **predictive-only** (ASU: "not tied to any specific foundry") | BSD-3-Clause (verified 2026-08-30, OpenROAD LICENSE: "Copyright 2020 Lawrence T. Clark, Vinay Vashishtha, or Arizona State University") | yes (one-way) | False (no foundry, no MPW, cannot tape out) | BSIM-CMG | PDK + cell libs + cards as a RESEARCH AID: characterize our cells on it; compare our finfet-class VS device to its cards | Clark et al. 2016 §2 device assumptions (Lg/fin/pitch numbers to verify on the PDF) |

### Verified licence / DOI facts (fetched 2026-08-30)
- FreePDK45: "This information may be freely used, modified, and distributed under the open-source Apache License (see the file APACHE-LICENSE-2.0.txt in the root install directory)" — https://eda.ncsu.edu/freepdk/freepdk45/ ; v1.4 (2011-04-07); models = "45nm Nano-CMOS Predictive Technology Model (PTM)", "tuned according to the Bulk-Si, poly-gate technology from Fujitsu" (Miyashita et al. IEDM 2007). Device table (nominal, 1.0 V): VTL NMOS 1246 µA/µm @ 100 nA/µm, PMOS −801 @ −100; **VTG NMOS 975.5 µA/µm @ 10 nA/µm**, PMOS −650.3 @ −10; VTH NMOS 570 @ 0.2, PMOS −379.2 @ −0.2. POLY.1 = 50 nm drawn, "it is assumed that the actual gate length is 45nm". Paper: Stine et al., MSE 2007, DOI 10.1109/MSE.2007.44 (IEEE Xplore 4231502).
- PTM 45 nm HP card (mirror: vtr-verilog-to-routing `vtr_flow/tech/PTM_45nm/45nm.pm`): header "PTM High Performance 45nm Metal Gate / High-K / Strained-Si", Vdd 1.0 V; NMOS toxe 1.25 nm / toxp 1.0 nm, vth0 0.46893 V, ndep 3.24e18, rdsw 155; PMOS toxe 1.30 nm, vth0 −0.49158 V, ndep 2.44e18. Paper: Zhao & Cao, IEEE TED 53(11):2816-2823 (2006), DOI 10.1109/TED.2006.884077. **PTM model-file terms: NOT verified** (site unreachable).
- ASAP7: README "ASAP7 PDK and libraries have a BSD 3-Clause license"; LICENSE = BSD 3-Clause, https://github.com/The-OpenROAD-Project/asap7 ; PDK v1.7. Paper: Clark et al., Microelectronics J. 53:105-115 (2016), DOI 10.1016/j.mejo.2016.04.006 — "not tied to any specific foundry".
- FreePDK15: "FreePDK15 code files have been open sourced under the New BSD Licence"; "The Free PDK Design Rule Kit is licensed under Creative Commons Attribution-NonCommercial-ShareAlike 4.0"; "commercial use could require a commercial license" — https://eda.ncsu.edu/freepdk/freepdk15/ → NC blocker.
- BSIM4 4.8.3 (2025-05-19) / BSIM-CMG 112.1.0 (2026-04-28), bsim.berkeley.edu: pages point to an "Agreement for Use" that was NOT fetched; the "BSIM code is BSD-licensed" claim is **to-verify** (ngspice's bundled bsim4 carries a UC BSD-style header — check it). Recorded as `std-bsim4` / `std-bsim-cmg` with verified=False.

## 3. S1 = FreePDK45 — the decision

- It is the ONLY rung that is both rights-clean (Apache-2.0, verified,
  one-way GPLv3-compatible) AND tied to silicon (calibrated-predictive:
  PTM tuned to Fujitsu IEDM 2007). ASAP7 is rights-clean but
  predictive-only; PTM 32 is unresolved; every literature rung is
  oracle-only (doping / work-function never published).
- What we take: the documented numbers as **anchors**
  (`SEED_SILICON_ANCHORS`, CNTCalibrationAnchor rows, extraction
  "documented value") and the design rules / cells for the cell layer.
  What we do NOT take: the BSIM4 card as "our model". Our device
  `si-nmos-freepdk45-class` / `si-pmos-freepdk45-class` is our
  VS-parameterised reconstruction (shape `planar-45nm-class`, doping
  `si-channel-p-3.24e18-ptm45` / `si-channel-n-2.44e18-ptm45`, dielectric
  `freepdk45-highk-nominal` EOT 1.25 nm, Vfb prior chosen for the PTM
  vth0) — `compare_to_anchors` reports the gap honestly (Ion ratio /
  Ioff ratio / verdict) and exposes a one-parameter KNOB suggestion
  (Vfb or the kT-layer fraction) when it would close the gap; nothing
  is fitted silently.
- First gap report (NMOS VTG, 1.0 V): Ion 736 vs 975.5 µA/µm (0.75×,
  within-2x); Ioff 0.39 vs 10 nA/µm (off-by-25×) → nearest knob
  suggestion vfb_v −0.93 → −0.98 (Ion 797, Ioff 1.97 — inside ±30 % /
  10×). PMOS: Ion 661 vs 650.3
  (1.02×), Ioff 2.8 vs 10 (off-by-4×) → within tolerance.
  The Ioff gap is the honest statement that our SS/Vt pair is not the
  card's — a knob, not an auto-apply.

## 4. How the cell layer consumes each rung UNCHANGED

1. Each rung is a `SiliconProcessNode`; each rung with a Polari device
   row (today: 90-class, freepdk45-class) yields the same device_model
   contract (`si_device_model`) → every fv/fi/fp consumer runs as is.
2. Characterize the SAME INV / NAND / DFF library per rung
   (cnt_cell_library / cnt_characterization on the rung's device pair)
   → FO4 per rung → clock per rung (cnt_ring_oscillator / cnt_sequential
   timing) — no per-rung code.
3. The question the ladder answers: "what would THIS RISC-V run at on
   the best open silicon of 2005 (65-class oracle) / 2010 (FreePDK45)
   / 2015 (FreePDK15 — blocked; ASAP7 as the predictive stand-in)".
   The report's `frontier` (both axes) vs `predictive_frontier`
   (rights only) vs `manufacturable_frontier` (none today) are the
   three honest answers.

## 5. Search protocol (per node, recorded in `search_json`)

published **dimensions + materials + doping/work-function + EOT +
measured Id–Vg/Id–Vd + capacitance + variability + temperature** ⇒
enough to instantiate a defensible transistor model ourselves
(`clean-room-reconstructable`, evidence reconstructed-from-published-
silicon); anything less ⇒ `reference-oracle` (cite + compare only).
Every literature rung lists what exists, what is missing, and
`search_next` — the report names the REAL frontier from these rows,
not from the node number.

## 6. Integrator wiring (not done here — no git, new files only)
- register `SiliconProcessNode`; seed `SEED_SILICON_PROCESS_NODES`,
  `SEED_SILICON_ANCHORS` (→ CNTCalibrationAnchor),
  `SEED_LADDER_EVIDENCE` (→ EvidenceItem), `SEED_LADDER_IP`
  (→ TechnologyIPRecord), `SEED_SI_LADDER_GRAPHS` (→ GraphDefinition);
- route `GET /api/sifet/ladder` → `ladder_report(manager)`,
  `GET /api/sifet/ladder/points?curve=ion-vs-node` → `ladder_ion_rows`,
  `GET /api/sifet/devices/{name}/anchors` → `compare_to_anchors`;
- `sifet/selftest_sifet_pages.py` hard-codes `len(SI_DEVICE_NAMES) == 7`
  → becomes 9 with the two freepdk45-class devices (their score/detail
  pages are seeded automatically from SEED_SI_DEVICES).
