# Bombastic Laser CNC (BLCNC) — Planning

**Status: PLANNING ONLY.** This doc scopes a Polari module + simulation
for the BLCNC, building on what already exists. Nothing built yet. Feeds
the [Tech Tree](TECH_TREE_TOPOLOGY_PLAN.md) as a technology node (theory
segment = this module + sims; real segment = the CAD/hardware once proven).

> **Notes digest folded in below** from the reference notes
> (`~/Desktop/Open-Source-Economy-Notes/06-Bombastic-Laser-CNC/`, ~86
> handwritten notebook photos across 6 subfolders). isle-core holds only a
> MIRROR of the framework — no separate BLCNC design docs there.

## 1. What the BLCNC is (from the notes + [[polari-hardware-architecture]])
An open-source **multi-laser precision melt/ablation CNC**. The stationary
optical core is the **Bombastic Laser Apparatus (BLA)**. It does two
coupled jobs:
1. **Precision melt / ablation of wax(+nanoparticle) thin films in
   VOXELS** — the "melt voxel" side of the printing story (the print-voxel
   seam is already noted in `waxprint/voxel_resolution.py` lines 165-168:
   a future `melt_voxel()` removes a volume element in the SAME voxel
   vocabulary the printer places one).
2. **Nanoparticle synthesis** (LASiS — Laser Ablation Synthesis in
   Solution): FeOx/SiOx/CuOx/C nanoparticles ablated in pure water,
   already seeded as the msci nanoparticle family (msci-20b, provenance
   `prov-notebook-blcnc-04-05`).

**Laser fleet (folder 01):** up to **6 pre-collimated lasers**, microchip
wavelength-switched at ns–µs. Two documented regimes: **~405 nm violet**
(2 mm beam; full power/cost table 1 mW→2 W: 1-20 mW budget precision,
50-500 mW common, 1-2 W strict-safety) and **~1000 nm NIR** for surface-wax
melt (VCSEL 50 µW or 0.1 mW diode). Two roles: a few high-intensity **core
lasers** (20/50 mW) bring a voxel *near* melt; many low-intensity
**precision/assistive lasers** (1/5 mW) apply the final energy precisely.
Per-laser knobs: wavelength, CW/ms/µs/ns/fs pulsing, focal path, X/Y
focal-tilt, z focal-lens.

**Optics/motion (folder 02):** **Electrically Tunable Lenses (ETL)**
modulate focal z with no moving parts (1-10 µm, sub-µm with feedback); an
**Optical Modulation Envelope** compensates mechanical stage error so melts
are reliable anywhere; a **Rigid Laser Overlap Apparatus** aims N beams at
one point (N=2 ideal, N=8 realistic).

**Voxel scales (the anchor to waxprint):** **control voxel = 0.3 mm³**
(absorbs ±0.05 mm stage error), **melt voxel = 0.1 mm³**; ultimate ambition
a **≥200 nm³** overlap precision (cheap RISC-V microchip). These are the
melt-voxel counterparts to the printer's print voxel.

**Safety:** power-tiered (1-2 W = strict); the "melt leakage → 0"
requirement is both quality and safety.

**Hardware architecture (already designed, not built):**
- Tier: **high-precision** — **ECP5 FPGA + a safety MCU** (SAMD51/STM32/
  RP2040). FPGA does pulse timing/gating/interlocks; MCU does config,
  safety, net, logs. (Avoid SAMD21+iCE40 for the final design — ok as a
  test jig only.)
- **Core rule**: MCU decides, FPGA enforces timing, hardware interlocks
  override both. An MCU cannot guarantee ns pulse timing; the FPGA emits
  deterministic pulse trains (100 ns on / 900 ns off all day).
- **Safety architecture (the defining constraint)**: a hardware safety
  circuit INDEPENDENT of software — door switch / water-flow / temperature
  / e-stop feed a circuit that forces **Laser Enable LOW** so the laser
  physically cannot fire regardless of FPGA/MCU state. High-level logic
  (gRPC commands, set pulse freq/width, start/stop job) is SEPARATE from
  safety logic (e-stop, cooling fail, over-temp, enclosure open, shutter
  open, PSU fault, FPGA unresponsive → LASER OFF immediately).
- **`LaserPulseConfig`** register shape (already named):
  `{pulse_width_ns, pulse_period_ns, burst_count, energy_limit,
  interlock_mask, mode_flags}`.
- Reached via the headless **Polari Hardware Bridge** ([[grpc-bridge]]) —
  NO JavaFX; eyes = Angular via STOMP. `send an object instance to
  hardware and it acts` (proven by the grpc-j2 Commands loop).

## 2. The notes' physics/process surface (6 subfolders → sim needs)
- **01-Laser-Hardware-And-Selection** → a `LaserSourceDefinition` +
  `LaserFleetDefinition` (6-laser, core vs precision roles). Fields:
  wavelength, pulse regime, avg/peak power, spot, cost, commercial vs DIY
  route. Selection = a scored search (reuse the scoring engine; the 405 nm
  cost/photon-flux table is ready-made seed data).
- **02-ETL-And-Optics** → `OpticalPathDefinition` (ETL focal-z, overlap
  apparatus N, optical modulation envelope): focal spot, depth of focus,
  the mechanical-error compensation envelope.
- **03-Beam-Physics-And-Simulation** → **the core new engine.** Gaussian
  beam via **ABCD matrix** optics (405 nm, D≈2 mm → waist **w₀ = 2λf/πD ≈
  2.57 µm**, Rayleigh z_R≈0.0515 mm; q_out=(Aq+B)/(Cq+D) through
  free-space·ETL·free-space). A **"Green Space"** sim domain (lateral
  3·d_beam, depth 2λ). The **Photon Potential Field / ULP**: Ψ = P/(ν²·ℏ)
  — a time-invariant, wavelength-agnostic, per-voxel composable photon
  field ("latent energy, not kinetic").
- **04-Nanoparticle-Wax-Composites** → the **7 layer recipes** (already
  transcribed into `nanoparticle-wax-composite@L0`): (1) pure wax, (2) 100%
  FeOx self-structuring, (3) 10/90, (4) 30/60, (5) 60/30, (6) 100% λ-tuned,
  (7) dynamically-tuned FeOx+SiOx+CuOx+C — **recipe 7 is the sim target**
  for realistic melt profiles. Min layer ≈ wax crystallization **~1 µm**.
  Layer structure sets the "control space / probability space" of
  wavelength response.
- **05-Nanoparticle-Synthesis-And-Filtration** → the LASiS model: ablation
  rate → particle-size distribution → filtration; <0.2 mm synthesis tubes,
  alternating-ferromagnet ferrite dispersion, PVD, ultrasound-atomizer-in-
  vacuum. Fills the msci "size range TO BE MEASURED" rows in sim.
- **06-Precision-Melt-And-Testing** → the **melt-voxel** model + the
  validation metrics. Ablation budget **E_ablation = F_th · A_voxel** with
  **F_th ≈ 0.4 J/m² (30-50 mJ/cm²)** → a (100 nm)² surface ≈ 4×10⁻¹⁵ J,
  reached by a 50 µW laser in **~80 ns** (perfect-absorption bound). The
  **Single Melt Action Metrics** (over a ~20 µs barrage) are the acceptance
  gates: **Energy Dispersion Precision** (heat inside vs outside the voxel),
  **Melt Dispersion Precision** (fraction of the voxel melted — higher
  better), **Melt Dispersion Leakage** (melt outside the voxel — must be
  ≈0, else warping). These are the direct mirror of waxprint's condition
  gates. Closes the `melt_voxel()` seam in `waxprint/voxel_resolution.py`.

## 3. Polari assets to build on (don't rebuild)
- **Hardware simulation stack** ([[hardware-simulation]], hwsim-1 LIVE):
  Renode (MCU twin) + Verilator (FPGA logic) + ngspice (circuits). The
  BLCNC's FPGA pulse generator + safety MCU firmware can run in this twin
  before silicon — the pulse-train + interlock logic is exactly what
  Verilator/Renode co-sim is for.
- **msci nanoparticle family** (msci-20b, `standard_materials_seed.py`,
  provenance `prov-notebook-blcnc-04-05`): `feox/siox/cuox/c-nanoparticle`
  + `nanoparticle-wax-composite` with the **7 layer recipes transcribed
  verbatim**, tagged `blcnc`/`laser-absorber`/`lasis`; LASiS size range
  flagged as the key unmeasured quantity; executable FEM (feox-wax k_eff).
  **The code itself names the gap**: the real interest — optical
  absorption / melt-probability — "needs an absorption engine the engines
  do not have yet." **That engine is blcnc-2.**
- **Optics-adjacent material seeds**: `materialsScience/
  dielectric_optics_seed.py` (KDP/Rochelle/silica/ZnO for precision laser
  control, IR-transparency + laser-damage-threshold notes, incl. 10.6 µm
  CO₂); `electrodevice/photo_basis.py` (blue ~450 nm absorber acenes);
  `biomining/optical_seed.py`.
- **waxprint** melt-voxel seam + the whole voxel vocabulary + the
  no-code WaxPrintOperation command pattern (a `LaserOperation` sibling
  with commands: `pulse`, `ablate-voxel`, `melt-voxel`, `synthesize`).
- **grpc bridge** + hardware object model (Device: readRegister/
  writeRegister/sendPacket/reset) — the LaserPulseConfig rides it.
- **Scoring** engine for laser/optics selection; **topology** for where
  the bridge + FPGA sim run.

## 4. Proposed phases (blcnc-N, when green-lit — NOT now)
1. **blcnc-1 objects**: LaserSourceDefinition + OpticalPathDefinition +
   LaserPulseConfig + BLCNCAssemblyDefinition (math-shaped device, reuse
   mathshapes) + safety-interlock model. Seeds from the notes. Selftest.
2. **blcnc-2 beam→material engine** (the msci-named optical gap): ABCD
   Gaussian-beam propagation (w₀, Rayleigh range, ETL focal-z) + the Photon
   Potential Field (Ψ=P/ν²ℏ) over a Green-Space domain + absorption per
   composite/λ + fluence vs the F_th ablation/melt threshold → heat-affected
   zone. Validate vs the notes' analytic numbers (w₀≈2.57 µm, E_ablation≈
   4×10⁻¹⁵ J, ~80 ns @50 µW).
3. **blcnc-3 melt-voxel + ablate-voxel + Single-Melt-Action Metrics**:
   laser dwell/fluence → removed/melted voxel + the three acceptance gates
   (Energy Dispersion Precision, Melt Dispersion Precision, Melt Dispersion
   Leakage≈0). Closes `waxprint.voxel_resolution.melt_voxel()` — same voxel
   language + gate pattern as the printer.
4. **blcnc-4 LASiS synthesis**: ablation rate → particle-size distribution
   → filtration; couples to the msci nanoparticle rows (measures the
   declared-null sizes in sim).
5. **blcnc-5 safety + pulse FPGA sim**: the interlock state machine +
   pulse-train generator in the hwsim twin (Verilator/Renode); prove
   Laser-Enable-LOW on every fault. NO real laser.
6. **blcnc-6 no-code LaserOperation**: commands pulse/ablate-voxel/
   melt-voxel/synthesize (+ planned hardware fire-command stubs via the
   gRPC bridge) — mirror WaxPrintOperation so it's no-code composable and
   printer+laser share one command vocabulary.
7. **blcnc-7 sim space + msim + evaluation gates** (mirror waxprint wp-5/6).

## 5. Hard constraints / cautions
- **Safety is non-negotiable and simulation-first.** No plan step fires a
  real laser; every capability is sim + honest gaps. The independent
  hardware interlock is modeled as an always-can-override element.
- Beam-physics constants, ablation thresholds, and nanoparticle sizes are
  PRIORS until measured — flag them (same discipline as waxprint).
- Dual-use note: this is open-source fabrication/research hardware; the
  plan stays on fabrication + material synthesis + safety, sim-first.

## 6. Open questions (from the notes digest + for Dustin)
1. **The optical-absorption / melt-probability engine does not exist** —
   the explicit honest gap in `standard_materials_seed.py`. The whole
   "control space / probability space" thesis (recipe 7) is unmodeled;
   only a thermal-conductivity bound is executable today. **Biggest build
   (blcnc-2).**
2. **Nanoparticle size ranges (r_min, r_max) per type are unmeasured** —
   the notes define the quantity's shape; real LASiS batches must fill it.
   All optical tuning depends on these.
3. **`melt_voxel()` is a noted seam, not code** — write it beside the
   print-voxel functions, sharing vocabulary; connect it to the
   Green-Space/ABCD beam model + the Single-Melt-Action Metrics.
4. **Beam/ETL sim not implemented** — ABCD Gaussian propagation, the
   Photon Potential Field (Ψ=P/ν²ℏ), N-overlap geometry, and the 0.3 mm /
   0.1 mm voxel scales exist only on paper.
5. **Wavelength ambiguity to resolve** — notes carry 405 nm violet, ~1000
   nm NIR (VCSEL), AND 10.6 µm CO₂ (dielectric seed). Which λ(s) does the
   first sim target, and how do absorbers (FeOx/CuOx/C) map to each?
6. **Perfect-absorption assumption** underlies the 80 ns / 4×10⁻¹⁵ J
   numbers — real absorption efficiency per composite/λ is unquantified.
7. **Fabrication feasibility unproven** — PVD wax/Al thin films, <0.2 mm
   synthesis tubes, ultrasound-atomizer-in-vacuum, alternating-ferromagnet
   ferrite dispersion are described but not validated.
8. **The 200 nm³ / RISC-V end goal** has no bridging analysis from the
   0.1 mm melt voxel down to nm-scale lithography.
- Ops: where does the FPGA/MCU + beam sim run in the topology (isle-core)?
