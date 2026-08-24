# CNT FET simulation — S0 license + reference gate (D1-D14 ratified plan)

**Date:** 2026-08-20 · **Arc:** cnt-fet-sim (CNT_FET_SIMULATION_PLAN.md)
· **Status: S0 COMPLETE — 6 parallel research agents, primary-source
verified.** Summary verdicts in the plan's "S0 verdicts" section; this
file is the durable detail. Project gates: GPLv3; NC = hard blocker;
license verified via API claim + LICENSE file + headers; papers enter
repos ONLY with explicit CC BY/BY-SA/CC0 (else cite+link+values).

---

# S0 — NEGF engine gate (agent report, 2026-08-20)

**VERDICT: Incorporate Kwant (BSD-2-Clause, verified from LICENSE file) as the F3 kernel — fork-pin OK, GPLv3-compatible, active (1.5.0, June 2024), Python/CPU, tight-binding wave-function scattering ≡ coherent NEGF; Poisson is user-supplied (couple Polari's own solver, or the MIT-licensed NanoNet NEGF as a complementary pinned dep). Fallback oracle: NanoTCAD ViDES — CONFIRMED BSD-4-clause WITH advertising clause → GPL-INCOMPATIBLE, external-process oracle ONLY, and effectively unmaintained.**

| Tool | License (verified) | Verdict | Fit | Poisson | Python | Maintenance |
|---|---|---|---|---|---|---|
| Kwant | BSD-2 (LICENSE.rst, GitLab + PyPI) | ✅ INCORPORATE | CNT = rolled-graphene TB lattice; S-matrix ≡ NEGF coherent; per-mode transmission native | ❌ user-supplied | native | ✅ 1.5.0 2024-06 |
| NanoTCAD ViDES | BSD-4-CLAUSE (license.txt read: advertising + endorsement clauses) | ⛔ linking blocked → EXTERNAL ORACLE ONLY | best physics match (NEGF + self-consistent 3D Poisson, CNT-native) | ✅ built-in | driver | ⚠ dead-ish (mirror 2020-03; site TLS broken) |
| sisl + TBtrans | sisl MPL-2.0; TBtrans GPL-3.0-only (SIESTA 5.4.1 2025-09) | ✅ license-wise; heavier | large-scale TB NEGF, Fortran file-driven | ⚠ no general device Poisson standalone | sisl yes | ✅ active |
| OpenMX | GPLv3 (site; tarball COPYING UNVERIFIED) | ✅ license-wise | DFT-NEGF overkill — skip | ✅ | ❌ | active-ish |
| GPAW | GPL-3.0-or-later (LICENSE) | ✅ license-wise | not a device simulator — skip (old gpaw.transport gone from docs, UNVERIFIED) | ❌ | ✅ | active |
| NEMO5 | Purdue academic NC, no redistribution; Silvaco commercial post-2017 | ⛔ HARD BLOCKED (NC binds USE — not even oracle) | — | — | — | — |
| NanoNet (freude/NanoNet) | MIT (GitHub spdx) | ✅ incorporate-eligible complement | pure-Python TB + recursive-GF NEGF, 1D-periodic; CNT example UNVERIFIED | ❌ | ✅ | ✅ pushed 2026-08-13 |
| pybinding | BSD-2 (license.md) | ✅ but no NEGF device solver — aid only | TB builder + KPM | ❌ | ✅ | slow |
| libNEGF (+DFTB+) | LGPL-3.0-or-later | ✅ (LGPL→GPLv3 fine); Fortran, bindings ours | real NEGF core | via DFTB+ | ❌ | active |
| PESCADO / QT Poisson_Solver | license UNVERIFIED (arXiv 2502.15897 / 2507.03131; gitlab.kwant-project.org/qt/Poisson_Solver) | TBD — verify before pinning | self-consistent quantum electrostatics designed for Kwant | ✅ | ✅ | papers 2025 |

**Recommended shape:** F3 = dausume/kwant fork-pin; CNT TB lattice + mode-resolved transmission; outer self-consistent loop vs a Polari-owned CYLINDRICAL Poisson solver (gate-all-around symmetry) — or PESCADO if its license verifies. Optionally pin NanoNet (MIT) as the GF-formalism sibling (path to phonon self-energies later). ViDES = optional separately-installed external-process cross-validation oracle, flagged 4-clause-BSD in the license ledger, never vendored/linked. Kwant is coherent-only — incoherent scattering later needs self-energy extensions (noted honestly).

Key URLs: kwant-project.org · gitlab.kwant-project.org/kwant/kwant (LICENSE.rst) · github.com/aravindhk/Vides (license.txt) · vides manual gianlucafiori.org/articles/ViDESmanual.pdf · github.com/zerothi/sisl · docs.siesta-project.org TBtrans · github.com/freude/NanoNet · github.com/libnegf/libnegf · licensing.prf.org/product/nemo5

---

# S0 — OpenVAF / OSDI gate (agent report, 2026-08-20)

**VERDICT: GO.** Use OpenVAF-Reloaded (GPL-3.0, active — original pascalkuthe/OpenVAF dormant since end-2023) to compile clean-room Verilog-A → .osdi, loaded in ngspice ≥42 (current ngspice-47, 2026-08-11) via `pre_osdi`. OSDI = ngspice's officially recommended compact-model route; ADMS deprecated/being removed; XSPICE not a compact-model path. Compiler GPL-3.0 does not constrain the model's license (build tool).

## Licenses (verified)
- OpenVAF + OpenVAF-Reloaded: GPL-3.0 (+ MIT rustc-derived carve-outs). Reloaded = arpadbuermen/OpenVAF (bleeding edge; OpenVAF/OpenVAF-Reloaded mirror lags); ~824 commits, LLVM 18-21, OSDI 0.4 API, fixes by Coram/Warning; binaries linux+windows only (no macOS).
- **BSIM-BULK 107.2.1, BSIM-CMG v111/112, EKV 2.6 = ECL-2.0** (raw LICENSE files in dwarning/VA-Models) — Educational Community License 2.0 = Apache-2.0 with narrowed patent grant, OSI-approved, FSF GPLv3-COMPATIBLE. "CMC went Apache" claims are imprecise — it's ECL-2.0. Si2 has NO blanket relicense. → legitimate STRUCTURE templates to read (clean-room equations still ours).
- PSP 103/104: custom royalty-free, NOT OSI-named, GPL-compat UNVERIFIED → reference-only.

## Unsupported Verilog-A constructs (gate the model to this subset)
- Events: ONLY @(initial_step)/@(final_step); no named/monitored events, no cross().
- No arithmetic bit-shift operators (no plans). No module-internal arrays; no genvar/generate.
- Treat as unavailable (absence-of-mention, partially UNVERIFIED): hierarchical instantiation, AMS/digital, absdelay/laplace_*/transition filters, table models, most $-functions beyond $temperature/$vt (Reloaded adds $fatal/$finish/$stop, fixes $bound_step).
- Extensions: ddx(x,$temperature), ddx(x,V(a,b)). Target = Verilog-AMS LRM 2.4.0 analog subset.
- Practical gate: single flat module, scalar params, static contributions (I(a,b) <+ ..., ddt, white/flicker noise) — the subset every CMC model compiles with.

## ngspice OSDI facts
- OSDI since 39 (2023-01); OSDI NOISE since 42 (2023-12); OSDI 0.3+0.4 since 44; current 47 (2026-08-11).
- Load: openvaf model.va (~2s) → .control: pre_osdi model.osdi (paths resolve vs NETLIST not cwd); self-built ngspice needs --enable-osdi (+--enable-predictor per README_OSDI).
- OP/DC/AC/TRAN/PZ solid; noise fine ≥42 (SPICE OPUS "pending" page stale).
- ngspice website still links original openvaf.semimod.de; community moved to Reloaded (VA-Models targets it; FSiC 2025 slides). Manual ch.13 naming Reloaded: UNVERIFIED.

Sources: github.com/pascalkuthe/OpenVAF · github.com/arpadbuermen/OpenVAF · openvaf.semimod.de/docs/details/verilog-a-standard/ · ngspice.sourceforge.io/osdi.html · github.com/imr/ngspice README_OSDI.md · github.com/dwarning/VA-Models (raw LICENSEs) · si2.org/cmc-standard-models · bsim.berkeley.edu/models/bsimbulk · cea.fr PSP 103.8 summary · wiki.f-si.org FSiC2025 ngspice slides

---

# S0 — Stanford/CCAM/papers gate (agent report, 2026-08-20)

**VERDICT: zero papers found under CC → NOTHING commit-direct; everything cite-values-only. Clean-room-from-papers unobstructed: all key papers legally readable free (arXiv + author PDFs). No open-license CNFET compact model exists anywhere — ours would be the FIRST.**

| Item | Verdict |
|---|---|
| Stanford VS-CNFET code (nanoHUB pub 42 v1.0.1, Verilog-A) | ⛔ BLOCKED — **NEEDS Modified CMC License** (NOT the expected single-user NC; refuted): grants modify/copy/redistribute BUT "users agree not to charge for the code itself" (price restriction GPLv3 cannot carry) + product-doc acknowledgment clause (GPLv3 §7 additional restriction). Never read the source. |
| Lee/Wong 2015 VS-CNFET Part I | cite-values-only. IEEE TED 62(9):3061-3069, DOI 10.1109/TED.2015.2457453; FREE legal full text: arXiv:1503.04397 (arXiv nonexclusive-distrib license, NOT CC) + poplab.stanford.edu/pdfs/Lee-VSmodelCNFETp1-ted15.pdf |
| Part II (extrinsic) | cite-values-only. DOI 10.1109/TED.2015.2457424; arXiv:1503.04398 + PopLab PDF p2 |
| Deng & Wong 2007 Part I/II | cite-values-only, PAYWALLED (no OA found). DOIs 10.1109/TED.2007.909030 (pages 3186-3194 UNVERIFIED vs Crossref) / 10.1109/TED.2007.909043 (Crossref-verified, 3195-3205). Stanford HSPICE code on 403'd page = blocked, terms UNVERIFIED. |
| CCAM code (nanoHUB pub 62 v2.2.0, DOI 10.4231/D34F1MK28) | ⛔ BLOCKED — identical NEEDS Modified CMC License. Commercial USE fine, selling code not → still GPL-incompatible. Manual PDF free on nanoHUB = reference-only. Key paper: Schroter et al. IEEE TED 62(1):52-60 (2015), DOI 10.1109/TED.2014.2373149, paywalled, cite-values-only. |
| RV16X-NANO (Hills et al., Nature 572:595-602 (2019), DOI 10.1038/s41586-019-1493-8) | scientific-reference-only CONFIRMED: Unpaywall is_oa=false; data "on reasonable request"; NO design repo; Supplementary Info PDF (63-cell library schematics/layouts) under Springer standard terms. Legal free background: MIT thesis DSpace handle 1721.1/127349. |
| **CNFET-OCL / CNFET7 & CNFET5** (github.com/uec-hpc-lab/CNFET-OCL) | ✅ **BSD-3-Clause** — first open 7nm/5nm CNFET CELL LIBRARIES (Liberty/LEF/QRC), Shi et al. ASP-DAC 2023 DOI 10.1145/3566097.3567939. Does NOT redistribute VS-CNFET code — artifacts built with it. Usable + precedent that params-from-papers is fair game. Fork-pin candidate. |
| GitHub sweep | nothing else qualifies: ArtemFediai/CNTFET_simple (GPL-3 but content UNVERIFIED), leobrowning92/networksim-cntfet (MIT, percolation network sim — kin to OUR film device, not a compact model), dwarning/VA-Models has NO CNT models. |

Caveats: nano.stanford.edu pages 403'd (click-through wording UNVERIFIED; nanoHUB license = the verified current channel); NEEDS-license wording from two consistent nanoHUB fetches — re-fetch verbatim before any legal write-up.

---

# S0 — ASAP7 + characterization stack gate (agent report, 2026-08-20)

**VERDICT: fully open, Cadence-free characterization stack exists and is license-clean**: ASAP7 (BSD-3, LICENSE file verified) as structural PDK template → CharLib (GPL-2.0, ngspice-driven) for combinational NLDM → lctime (AGPL-3.0-or-later) for sequential setup/hold/recovery/removal → OpenSTA (GPL-3.0) standalone Liberty validation → Yosys (ISC) + OpenROAD (BSD-3).
⚠ CharLib + libretto = GPL-2.0 (only-vs-or-later UNVERIFIED): GPL-2.0-only is INCOMPATIBLE for code combination with GPLv3 — subprocess/CLI use + standalone dausume/ fork-pin fine; never merge code.
⚠ CharLib 2.0.0 (Dec 2025) DEPRECATED sequential characterization ("will be reimplemented") — released CharLib = combinational-only; recovery/removal never offered; power WIP (#14/#102/#106).

| Tool | License (verified) | Impact |
|---|---|---|
| ASAP7 superproject + asap7sc7p5t_28 | BSD-3 (raw LICENSE; sub-repos asap7sc6t_26/asap7_sram_0p0 UNVERIFIED individually; citation requested not required) | template |
| CharLib (stineje/CharLib) | GPL-2.0 (raw LICENSE + pyproject) | subprocess/pin only |
| libretto | GPL-2.0 (badge) | fallback only |
| lctime (codeberg librecell/lctime) | AGPL-3.0-or-later (pyproject SPDX; test_data Apache-2.0) | ✅ sequential characterizer; active Apr 2026, v0.0.28 |
| OpenSTA (parallaxsw/OpenSTA canonical now) | GPL-3.0 dual-licensed | ✅ standalone Liberty acceptance gate |
| Yosys ISC / OpenROAD BSD-3 | confirmed | ✅ |

ASAP7 structure (CNT-PDK template): asap7_pdk_r1p7 {BSIM-CMG SPICE models, techfiles, DRC/LVS, DRM} + per-track-height cell libs {CDL, GDS, LEF, TechLEF, Liberty NLDM+CCS, Verilog, QRC, datasheets} × RVT/LVT/SLVT + asap7_sram_0p0. Minimal CNT PDK = {SPICE models + techfile} + {CDL/SPICE, LEF, TechLEF, GDS, Liberty NLDM, Verilog}; CCS/QRC later. Calibre decks separate download (terms UNVERIFIED; irrelevant to open flow).

CharLib detail: 604 commits, last push 2026-08-20; releases 0.9→1.0.0→2.0.0 (Dec 2025), main at v2.1.0-dev; inputs = per-cell SPICE + YAML; drives ngspice via CUSTOM PySpice fork infinitymdm/PySpice (upstream PySpice unmaintained — pin BOTH); Xyce also. Missing: Verilog model gen (#57), function extraction (#56), derating (#59), SRAM (#60). Docs' "sequential" claim = roadmap, not release.

Recommended stack: ASAP7 layout template → CharLib+ngspice (dausume/CharLib + dausume/PySpice pins) for combinational → lctime for sequential → OpenSTA report_checks acceptance → Yosys/OpenROAD.
Sources: github.com/The-OpenROAD-Project/asap7 (LICENSE) · github.com/stineje/CharLib (+releases, MWSCAS 2024 paper 10658687, FSiC 2025 slides) · github.com/snishizawa/libretto · codeberg.org/librecell/lctime · github.com/parallaxsw/OpenSTA · YosysHQ/yosys · The-OpenROAD-Project/OpenROAD

---

# S0 — CNFET calibration-anchor gate (agent report, 2026-08-20)

**VERDICT: no primary anchor paper is CC-licensed — 100% cite+link+extracted-values bucket. Free legal full text exists for every priority anchor (author PDFs/arXiv/mirrors) → digitize curves into cited rows. Conditional gold: nanoHUB VS-CNFET bundle SHIPS the experimental calibration data files (NEEDS Modified CMC License — read at download; likely extract-values-only like the code).**

**Premise CORRECTION (verified from arXiv Part I):** VS-CNFET's v_xo anchor = **Franklin & Chen 2010** (ref [51]): Lg 15nm/300nm/3µm on the SAME tube (d=1.2nm, Rs=5.5kΩ, SS=135mV/dec assumed) → v_xo = 3.8/1.7/0.47 ×1e7 cm/s. Franklin 2012 9nm device calibrated the PREDECESSOR Luo et al. IEEE TED 2013 (v_xo=3e7 at 9nm).

Prioritized anchors (all cite-values-only):
1. Franklin & Chen, Nat Nano 5:858 (2010), 10.1038/nnano.2010.220 — author PDF free (franklin.pratt.duke.edu). Id-Vg subthreshold ×3 Lch; Id-Vds; Rtot vs Lch (mfp); Id vs CONTACT length; 2Rc vs Lc curve. G≈0.7G0, gm=40µS @15nm.
2. Franklin et al., Nano Lett 12:758 (2012), 10.1021/nl203701g — author PDF free. 9nm: SS=94mV/dec, Ion=2.41mA/µm(diam-norm)@0.5V; Id-Vg ×4 Lch; Id-Vd.
3. VS-CNFET Parts I/II TED 62:3061/3070 (2015) — arXiv 1503.04397/98. Full param set, v_xo/µ vs d,Lg equations, calibration recipe (§II + Fig7 Part I).
4. nanoHUB VS-CNFET bundle DOI 10.4231/D3BK16Q68 (manual 10.4231/D38W3835S) — MACHINE-READABLE experimental calibration data + MATLAB exerciser; NEEDS license, account needed; review before ANY vendoring (expect extract-only).
5. Qiu et al., Science 355:271 (2017), 10.1126/science.aaj1628 — 10nm & 5nm Lg, n AND p, SS=70mV/dec both, Ion=17.5µA/tube@0.4V, graphene contacts, CMOS inverter; free mirror PDF exists.
6. Cao et al., Science 350:68 (2015), 10.1126/science.aac8006 — END-BONDED Mo contacts: Rc SIZE-INDEPENDENT vs Lc (contrast anchor 1 Pd side-contacts); author PDF free.
7. Cao et al., Science 356:1369 (2017), 10.1126/science.aan2476 — 40nm-footprint pFET: 0.9mA/µm pitch-norm @0.5V, SS=85.
8. Liu et al., Science 368:850 (2020), 10.1126/science.aba5980 — aligned arrays 100-200 CNT/µm: Ion=1.3mA/µm, gm=0.9mS/µm @1V, RO >8GHz. Per-curve biases UNVERIFIED (paywall).
9. Lin et al., Nat Electron 6:506 (2023), 10.1038/s41928-023-00983-3 — aligned sub-10nm-node: Ion=2.24mA/µm, gm=1.64mS/µm; 6T SRAM 0.976µm². UNVERIFIED details (paywall).
10. Hills 2019 RV16X-NANO — VARIABILITY distributions (Extended Data) only; device data request-only.
11. Franklin et al., ACS Nano 8:7333 (2014), 10.1021/nn5024363 — Rc(Lc) compilation for SIX metals (Pd,Pt,Au,Rh,Ni,Ti) — the contact sub-model table.
12. Wildöer 10.1038/34139 + Odom 10.1038/34145 (1998) — STM/STS bandgap anchors: Eg = 2γ0·a_cc/d, γ0=2.7±0.1eV, a_cc=0.142nm → Eg≈0.77 eV·nm/d (0.4-0.7eV measured). Wildöer PDF free (ceesdekkerlab.nl).

Machine-readable: only the nanoHUB bundle (conditional) + Zenodo 10161590 (CC BY but biosensor recordings — not an anchor). PMC12113874 + PMC10833444 reviews possibly CC BY (UNVERIFIED) — their compiled benchmark tables vendorable IF verified.
Scratch PDFs for digitization saved under ~/.claude/.../tool-results/ (webfetch-*.pdf: Qiu mirror, Franklin 2010/2012, VS Part I) — extraction copies, NOT vendorable, NOT in repo.
Caveats: Liu/Lin per-curve conditions unverified; arXiv v-copies may differ from TED versions of record — cite TED DOIs, extract from arXiv.

---

# S0 — F2 quasi-ballistic literature gate (agent report, 2026-08-20)

**VERDICT: F2 IMPLEMENTABLE from papers alone — cleanly.** Rahman/Guo/Datta/Lundstrom 2003 (IEEE TED 50(9):1853, DOI 10.1109/TED.2003.815366; FREE author PDF nanohub.org/resources/122) publishes the COMPLETE top-of-the-barrier set: N = ∫D(E)[f(E−EF1)+f(E−EF2)]/2 dE; U_scf = −q(αG VG + αD VD + αS VS) + q²ΔN/CΣ; fixed-point iteration; I = forward−reverse Landauer fluxes. Natori 1994 (10.1063/1.357263, paywalled) = ballistic-flux derivation; Guo/Lundstrom/Datta APL 2002 (10.1063/1.1474604, paywalled) = CNT specialization (2 spin × 2 valley); Guo et al. 2004 multiscale = OA arXiv cond-mat/0312551 (hyperbolic E(k)=±√((Eg/2)²+(ħvF k)²) ⇒ m*=Eg/2vF²≈0.05-0.08 m0); Lundstrom EDL 1997 (10.1109/55.596937) = T=λ/(λ+L) quasi-ballistic lift (kT-layer for saturation via Lundstrom&Ren 2002, 10.1109/16.974760). No paywalled step load-bearing. All cite-only (none CC).

**FETToy: license NOT CONFIRMED OPEN** — nanoHUB metadata says "open source" but license text is login-gated (Purdue policy prefers NCSA-style, unconfirmed). Do NOT copy code; use published equations + published I-V curves as validation targets. jguoufl/FETToy on GitHub = black-phosphorus variant, NO license → unusable. nanoHUB MOSCNT (resources/1989) = F3 NEGF, login-gated license.

**mfp anchors (all OA):** Javey PRL 92:106804 (2004) (arXiv cond-mat/0309242): λ_acoustic≈300nm, λ_optical≈15nm (ħω_OP≈0.16-0.2eV); Park Nano Lett 4:517 (2004) (cond-mat/0309641): λ_ac≈300nm low-bias, λ_op≈10-15nm high-bias; Perebeinos/Tersoff/Avouris PRL 94:086802 (2005) (cond-mat/0411021): acoustic mfp ∝ diameter, mobility ∝ d²/T — use for d,T-scaling of λ, not a constant.

**Bandstructure primitives (cite-only):** zone-folding 1992 trio — Saito/Fujita/Dresselhaus APL 60:2204 DOI 10.1063/1.107080 (⚠ search-suggested 10.1063/1.106898 is WRONG) + Hamada PRL 68:1579 ((n−m) mod 3 rule, Eg ∝ 1/d); Mintmire & White PRL 81:2506 (1998) universal 1D DOS + Eg magnitude; Wildöer/Odom 1998 STS experiment (Eg≈0.7-0.9 eV·nm/d, γ0≈2.5-2.9eV); Marulanda & Srivastava pssb 245:2558 (2008) analytical m*(d,chirality). Saito/Dresselhaus BOOK not required.

**CC BY (commit-direct ELIGIBLE, re-confirm tag on-page):** MDPI Nanomaterials 2025 10.3390/nano15151168; Micromachines 15:817 (2024) PMC11278681; Electronics 9:2199 (2020) compact-model paper.

**Open implementations: nothing worth adopting — clean-room confirmed.** ArtemFediai/CNTFET_simple (GPL-3.0 MATLAB) = bare Landauer, fixed 2-subband, NO self-consistent electrostatics — below F2; cross-check only. No Python/open ToB-CNT implementation exists on GitHub.

UNVERIFIED: FETToy license text; Guo 2004 journal DOI; MDPI per-article CC tags; VS-CNFET code license claim.
