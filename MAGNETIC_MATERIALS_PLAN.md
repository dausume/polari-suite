# MAGNETIC MATERIALS + BLOCK-BASED MAGNETIC CIRCUITS + 3-PHASE MOTORS
*(plan drafted 2026-07-28 — Dustin: "capability to make magnetic
geopolymer and magnetic sol-gel materials, which we can use to make
magnetic circuits and 3-phase motors", block-based per the circuit
work; PLANNING ONLY, nothing built yet)*

## 0. Where the pieces already are (provenance)

**The block-based design pattern** Dustin pointed at lives in the
`electrodevice` module (ncg-4/ncg-6) — present locally AND in the
`~/ncg-matrix/polari-framework` checkout on isle-core (no separate
prose note found there; the module IS the note):

> CircuitDefinition owns CircuitComponentDefinition rows (blocks,
> pins wired by NET NAME) + CircuitNetDefinition rows (declared
> nets = documentation + drift visibility). The netlist GENERATES
> from rows through the GraphCompilerDefinition seam; params come
> from derived device rows or explicit values with the row as the
> honest record; undeclared nets are suggestions riding the result;
> missing capability (ngspice) refuses honestly. level_bridge binds
> logic designs onto physical boards (PinBindingDefinition).

Magnetic circuits mirror this 1:1 through the classical analogy
(Hopkinson's law): MMF ↔ voltage, flux Φ ↔ current, reluctance
R = l/(µA) ↔ resistance, permeance ↔ conductance. Same rows→
compiler→solver→refusals shape; different physics constants.

**The materials are half-built already** (msci-22/23, the k↔µ
Laplace-analogy homogenization):
- geopolymer-ferrite µ_eff **2.196** @35 vol% (≈88% of cast
  ferrite-ceramic 2.484 — the feasibility datum)
- sol-gel-ferrite µ_eff **1.714** @25 vol%
- wax-ferrite (printable magnetics) @30 vol% — LIVE µ_eff row
- validity notes already on the rows: linear magnetostatics only,
  hysteresis/remanence out of scope, ferrite L4 = spin-DFT gap.

**The costs are half-cited already** (src-6/7): magnetite pigment
**9.70/kg EXACT buy** vs coprecipitation make 20.11/kg — buy wins
~2x, honestly. CNT dispersions costed. Geopolymer 1.11/kg cascade,
sol-gel xerogel 10.67/kg self-made-waterglass route.

**The drive side is designed** ([[polari-hardware-architecture]]):
FPGA does pulse gen / motor timing / PWM; MCU supervises; hwsim-1
runs real STM32 firmware. electrodevice runs SPICE circuits as rows.
BLCNC_PLAN already names "alternating-ferromagnet ferrite
dispersion" as a fabrication idea. Tech-tree topology table has the
**Electromagnetic systems** row sitting at TODO — this plan fills it.

## 1. Physics honesty, up front (constraints the plan obeys)

1. **Our composite µ_eff ~1.7-2.5 is LOW.** Laminated steel and
   sintered soft ferrites run 10²-10⁴. Cast composite cores are NOT
   drop-in motor iron; they suit air-gap-dominated magnetics:
   inductor/sensor cores, flux guides, pole shoes, high-frequency
   parts (composite = low eddy loss is a real advantage — magnetite
   conductivity needs checking, though: percolation engine says
   conductive fillers percolate).
2. **Magnetite is a SOFT-ish magnet** (low coercivity): good filler
   for cores and flux paths, **not a permanent magnet**. Real PMs
   need hard ferrite (SrFe₁₂O₁₉ / BaFe₁₂O₁₉) powder — buyable as
   bonded-magnet feedstock AND **makeable locally from pottery
   chemicals (§1b Rung 1: rust + strontium carbonate + kiln, with
   a citrate sol-gel route matching our stack)**. Bonded
   hard-ferrite magnets are exactly how cheap commercial BLDC/fan
   motors are made, so the route is proven at industry scale.
3. **Firing upgrades exist**: geopolymer-ferrite → ceramic-ferrite
   via the Table 8.8 path (kiln energy excluded-loud, as always);
   sintered ferrite is the µ escalation rung. The ceramics
   escalation ladder already models this shape.
4. **Motor consequence**: v1 torque numbers will be SMALL and the
   reports must say so. Two realistic first targets:
   - **(A) ferrite-PM BLDC/synchronous** — bonded hard-ferrite
     rotor ring + wound stator; the commercial-precedent route.
     Gated on the SrFe₁₂O₁₉ citation + a bonding formula.
   - **(B) pure reluctance rotor** — works with TODAY's costed
     materials (no PM), torque scales with saliency (L_d−L_q),
     honestly feeble at µ~2 but it CLOSES THE LOOP end-to-end
     with zero new feedstock.

## 1b. THE LOCAL TORQUE-MAGNET LADDER (Dustin 2026-07-28: "make
everything fully locally no matter how complex, overcoming rare
materials with materials science and nanoparticle/nanostructure
physics" — the answer is YES, and it's rung-by-rung honest)

**Rung 1 — sol-gel hexaferrite (SrFe12O19), the realistic local
route.** Hard ferrite is not just buyable — it is MAKEABLE from
pottery-channel chemicals we already know how to source:
  SrCO3 + 6 Fe2O3 -> SrFe12O19 + CO2
- Feedstock: strontium carbonate $1.40-2.87/lb and red iron oxide
  $1.99-2.25/lb from the SAME ceramic-supply channel as our
  metakaolin (Evans/Clay King/Sheffield/Laguna — 2026-07-28
  pre-hunt, exact cites = mag-1). Stoichiometric feed ~0.14 kg
  SrCO3 + 0.90 kg Fe2O3 per kg product ≈ **under $5/kg feedstock**
  vs the $1.5/kg bulk-industry figure — the premium is small and
  the chain is FULLY local.
- Route A (matches our stack EXACTLY): citrate sol-gel
  auto-combustion — iron salts (ferric chloride/ferrous sulfate
  ALREADY cited) or dissolved oxide + Sr salt + citric acid
  (cited) -> gel -> combust -> calcine ~800-1000°C = nanoscale
  hexaferrite powder at POTTERY-KILN temperatures. This is the
  sol-gel module + ceramics ladder doing what they were built for.
- Route B (bulk): solid-state — mix oxides, calcine 1100-1250°C,
  mill. Cone 8-10 territory; coarser powder, simpler chemistry.
- Then: bond into matrix (isotropic bonded magnet, our mortar/
  block system) or press + sinter ~1200°C (stronger, ceramic
  rung); ANISOTROPIC grade = press/cure in an aligning field —
  which needs...
- **The magnetizer/aligner is itself a buildable tool**: a pulsed
  capacitor-bank coil (electrodevice circuit rows + a magnetics
  block-matrix fixture — the stack BOOTSTRAPS its own tooling; a
  manufacturing-tools tree node). Every sintered/bonded magnet
  needs a magnetizing pulse anyway.
- Verification: the EXISTING characterization stack — XRD
  plain-language check for the hexaferrite phase, FTIR carbonate
  band for calcination completeness, then hall-probe B_r.

**Rung 2 — semi-hard nanostructure (shape anisotropy)**: aligned
magnetite CHAINS — the msci ferrite-chaining rows (λ=12, 20 nm)
are literally this physics; field-align during matrix cure ->
weak-but-real permanent moment from a dirt-common oxide.
Research-grade, honest ceiling: WEAK vs hexaferrite; useful for
bearings-assist/sensing bias, not main torque.

**Rung 3 — aspiration nodes (nanostructure physics vs rare
elements, named honestly as research)**:
- α″-Fe16N2 — iron + ammonia-derived nitrogen, low-temp nitriding
  (~150-200°C!), giant magnetization; metastable nanoscale control
  is the hard part; actively commercialized (Niron) = the flagship
  proof that nanostructure physics CAN beat rare elements.
- MnAl τ-phase — dirt-common elements, metastable quench+anneal
  metallurgy; modest real-world (BH)max so far.
- Alnico — high B_r, low H_c, needs foundry (~1600°C) + field
  heat-treat; cobalt = semi-scarce (not rare-earth). Later
  metal-casting tree.
- Exchange-spring nanocomposites (hard hexaferrite + soft
  magnetite at ~10 nm coupling length) — the sol-gel/nanoparticle
  toolkit's long-run target; theory gains real, processing window
  narrow; mag-2t models the ASPIRATION honestly (true exchange
  coupling is beyond mean-field homogenization — flagged as the
  L4-class gap it is).

**Ladder honesty**: every rung's row carries its (BH)max class vs
bought sintered ferrite vs NdFeB, so torque_parity() prices the
local-vs-bought-vs-rare-earth tradeoff explicitly.

## 1c. THE MATERIAL OPTION CATALOG (baked-in seeds — Dustin
2026-07-28: "account for all of those as option materials we can
simulate and use even if we cannot make them in the short term")

**The REALIZATION LADDER (data, mirrors the biz-4 compliance-level
pattern)** — every catalog row carries `realization_level`:
  `theoretical` -> `literature-demonstrated` (others made it,
  properties from papers, est-flagged) -> `recipe-seeded` (WE have
  a costed formula) -> `made-and-measured` (our rows: XRD/hall/
  inductance measurements exist).
Plus the orthogonal flag `buyable_cited` (a PriceCitation exists).
GATES: **simulation is open at EVERY level** (the watermark travels
on every result); **costing** needs buyable_cited OR recipe-seeded;
**business/planner use** needs made-and-measured (readiness for
materials, exactly like product readiness is EARNED). Escalating a
row up the ladder is evidence-driven, never declared.

**SOFT MAGNETIC (magnetic-conductor role)** — seeds:
| option | realization @seed | notes |
|---|---|---|
| magnetite powder (Fe3O4) | recipe-seeded + buyable_cited | buy 9.70/kg beats make 20.11 (src-6/7) |
| carbonyl/atomized iron powder | buyable (cite in mag-1) | commercial powdered-iron cores ARE this + binder; higher B_sat than oxides — likely our best cheap core filler |
| maghemite (γ-Fe2O3) | literature | magnetite oxidation product; acicular = semi-hard, equiaxed = soft (both noted) |
| NiZn ferrite powder | buyable (cite) + literature sol-gel route | insulating, high-frequency soft ferrite |
| MnZn ferrite powder | buyable (cite) | higher µ, lower frequency |
| fired/sintered ferrite ceramic | recipe-seeded (Table 8.8 rung) | the µ escalation of any cast composite |
| electrical steel (lams) | buyable REFERENCE | benchmark row for parity math, not our route |
| composites: each powder × {geopolymer, sol-gel, ceramic, wax} × vol% | derived | msci-22 engine predicts; mag-2t sweeps |

**HARD MAGNETIC (torque-magnet role)** — seeds:
| option | realization @seed | notes |
|---|---|---|
| SrFe12O19 powder | literature + buyable(quote) -> recipe-seeded AT mag-1 (§1b Rung 1) | THE local route: pottery chemicals, sol-gel or solid-state |
| BaFe12O19 powder | literature | same chemistry; barium carbonate toxicity caveat AS DATA |
| bonded hexaferrite (in geopolymer/sol-gel/wax) | derived once powder lands | isotropic first; anisotropic needs the aligner |
| sintered hexaferrite | literature + buyable_cited (finished ring magnets = the make-vs-buy benchmark) | pottery-kiln sinter rung |
| aligned magnetite chains | literature/msci rows (chaining physics live) | semi-hard, honest weak ceiling; bias/bearing-assist |
| α″-Fe16N2 | theoretical (literature-demonstrated by others) | iron+ammonia nanostructure flagship; the mag-2t poster child |
| MnAl τ-phase | theoretical/literature | common elements, metastable metallurgy |
| MnBi | theoretical | bismuth availability note |
| alnico | literature + buyable REFERENCE | foundry rung; cobalt semi-scarce note |
| exchange-spring hexaferrite/magnetite | theoretical (L4-flag: beyond mean-field) | the nanocomposite long-run |
| NdFeB | buyable REFERENCE ONLY | the parity benchmark torque_parity() compares against; against the local ethos for USE, priced for HONESTY |

**ELECTRIC CONDUCTORS** — seeds: copper magnet wire (power; cite),
aluminum wire (power-lite, common, cite), ferrite-CNT composite
(signal, msci-23 σ row), CNT dispersion traces (signal, costed
src-6), graphite/carbon-black composite (signal/resistive — the
CHEAP common conductor, cite powder), CNT yarn (theoretical).

**CONTAINMENT / STRUCTURAL / BEARING** — seeds: plain geopolymer +
fired ceramic + glass (mtt-2 rows) as structural & flux-fence;
high-µ soft composite as µ-shunt shield; hexaferrite PM rings
(magnetic-bearing, Earnshaw note); alumina (jewel/pin contact —
msci row exists); PTFE/graphite dry-slide pads (cite, the humble
constrained-axis option).

Every row gets: roles (mag-2r predicates decide viable/unassessed),
forms, property values with per-value provenance (measured | vendor
| literature-est | theoretical), and — where applicable — its
composite derivatives auto-derived rather than hand-listed. The
catalog IS mag-1/mag-2's seed spec; counts land in selftests.

## 2. Phases — grouped into FOUR SECTIONS (Dustin 2026-07-28:
"electric motors should be their own section")

- **SECTION A — MAGNETIC MATERIALS** (supplychain + msci seam):
  mag-1 sourcing/formulas, mag-2 properties-as-data, mag-2r role
  taxonomy + use-case tag search, mag-2t theoretical powder
  designer, ferrite-CNT conduction honesty.
  **✅ BUILT 2026-07-29** (framework b96d72e, deployed live).
- **SECTION A2 — FIELD VIEWS IN SIMSPACES** (Dustin 2026-07-29,
  the intermediate section): mag-fv — E/B fields of devices
  displayed as threshold-gated VECTOR DISPERSIONS or as grouped
  THRESHOLD SHAPES (math-shapes, color+alpha per band). See §A2
  below. Definitions land before Section B; renders honestly from
  whatever field source exists (analytic first, mag-3 solves as
  they land).
- **SECTION B — BLOCK MATRIX + MAGNETIC CIRCUITS** (in module
  `magnetics/`): mag-3 reluctance blocks, mag-4 slot-matrix
  assembly (varying block sizes, selective magnetic mortar).
- **SECTION C — ELECTRIC MOTORS, OWN SECTION** (new module
  `motors/`, requires magnetics): mag-5 designer + parity, mag-6
  SimpleFOC drive, structural containment.
- **SECTION D — SURFACE + BUSINESS**: mag-7 visuals, mag-8 splice.

### mag-0 — Decisions (Dustin ANSWERED 2026-07-28, remainder defaulted)
1. Motor approach: **APPROVED** ("sounds good") — reluctance-first
   proof, ferrite-PM once the hard-ferrite citation lands; same
   block library serves both.
2. **THE MORTAR MODEL (Dustin's addition, now central)**: "make
   blocks and fill them in with sol-gel as a mortar, similar on the
   winding, so the finalized motor built almost becomes a single
   solid object (where it makes sense for it to)". See §2b below —
   joints are elements, windings are potted, monolith per
   SUB-assembly (stator solid, rotor solid, the working air gap
   stays FUNCTIONAL and is never mortared shut).
3. Tolerance/complexity escalation: **CONFIRMED** ("escalating up
   different levels of complexity and tolerance requirements for
   the motors makes sense, yes") — see §2c, the ladder is DATA the
   solver prices.
4. **END-GOAL TOPOLOGY (Dustin 2026-07-28)**: 3-phase DUAL-STATOR
   — "maximum force and control, applicable to cars, cheaper
   materials in a smaller space to reach parity with more
   expensive ones". See §2d — dual-gap axial flux is the geometry
   that makes the cheap-material parity argument QUANTITATIVE.
5. **CONTROLLER (Dustin 2026-07-28)**: SimpleFOC (open-source FOC
   stack) drives the motor — see mag-6; it replaces custom drive
   firmware at stage 0/1 and sits at preference-ladder rank open-
   source-non-polari. FPGA timing stays the escalation rung.
6. **MOTORS ARE THEIR OWN SECTION (Dustin 2026-07-28)**: two
   modules — `magnetics/` (blocks, matrix, circuits) and `motors/`
   (motor design, drive, containment; requires magnetics). Keeps
   files small and lets magnetics serve transformers/inductors/
   sensors without dragging motor code along.
7. Defaults unless objected: gaussmeter = cheap hall-sensor buy
   SUGGESTED (knob, never auto-purchased); solver = python primary
   + ngspice-analogy parity.

### §2b — THE MORTAR / MONOLITH ASSEMBLY MODEL (from Dustin's spec)
- **Blocks + mortar = the physical design language.** Cast magnetic-
  geopolymer blocks are the bricks; SOL-GEL is the mortar filling
  the joints and potting the windings. The finished stator (and
  separately the rotor) cures toward ONE solid object.
- **Every mortar joint IS a circuit element.** A joint between two
  magnetic blocks is a thin series reluctance: thickness t_joint,
  area A, µ of the MORTAR. Two mortar grades as formulas from day
  one: plain sol-gel mortar (µ≈1 — magnetically a gap: use where
  flux should NOT couple) and **sol-gel-ferrite mortar** (the
  msci-22 1.714 row — the flux-continuity mortar between core
  blocks). Choosing the mortar grade per joint is a DESIGN knob the
  solver prices; the block circuit therefore maps 1:1 onto the
  physical assembly, joints included. Nothing about the physical
  build is invisible to the model.
- **Windings potted in mortar**: coils wound on/around cast teeth
  or bobbins, then encapsulated. Gains: no housing, vibration-proof,
  thermally coupled to the mass. DATA-GAPS to test before trusting:
  (1) enamel magnet-wire insulation vs ALKALINE geopolymer contact
  — chemistry compatibility unknown; sol-gel (washed, near-neutral)
  potting is the safer bet and is exactly Dustin's mortar; state it,
  test it (a QA check row). (2) potted-coil heat path is good but
  thermal LIMITS stay out of v1 (§4) — the report says unmeasured.
- **"Where it makes sense" rules (the honesty of the monolith)**:
  the working air gap is functional — rotor and stator are separate
  monoliths, never mortared to each other; bearings/shaft seats
  stay serviceable (mortar-free zones as block attributes);
  anything expected to be replaced (a sacrificial sensor pocket)
  gets a plain-mortar release boundary, mirroring the mold-1
  release-agent rule.

### §2c — TOLERANCE / COMPLEXITY ESCALATION LADDER (as data)
Each level = a row with joint-thickness + gap-accuracy priors the
reluctance solver consumes, so every level gets a PREDICTED
performance delta and a cost delta — the escalation is quantified,
never vibes:
- **T0 cast-as-is**: wax-printed molds, no post-work. Joint prior
  ~0.5-1 mm, gap accuracy loose. Cheapest; most torque lost to
  parasitic gaps (the solver shows exactly how much).
- **T1 lapped faces**: flat-lap mating faces by hand (sandpaper on
  glass — stage-0-compatible labor). Joint prior ~0.1-0.3 mm.
- **T2 fired blocks**: geopolymer→ceramic firing (Table 8.8 rung)
  — higher µ AND better dimensional stability; kiln energy
  excluded-loud as always.
- **T3 machined/ground**: needs the manufacturing-tools tree
  (BLCNC / surface grinding) — named, not built.
Priors start est-flagged; MEASURED joint thicknesses (calipers, a
QA dimensional check) replace them per the measured-rates pattern.

### §2d — DUAL-STATOR AXIAL FLUX: the target geometry + the parity math
- **Topology**: two stator DISKS (each a mortared monolith of cast
  pie-segment teeth blocks + potted windings) sandwich one rotor
  disk (ferrite-PM ring segments, or salient reluctance disk for
  the no-PM proof). TWO working gaps.
- **Why it fits us exactly**:
  1. Force scales with GAP AREA × B² — dual gaps double active
     area in the same envelope. Low-B cheap materials compensate
     with geometry: that IS Dustin's parity thesis, made physics.
  2. Flat disk faces are CASTABLE and LAPPABLE (T1 rung is
     sandpaper-on-glass) — axial geometry wants exactly the
     manufacturing we have; radial laminations want exactly what
     we don't.
  3. Yokeless variants (YASA-shape) MINIMIZE soft-core path length
     — with µ~2 core material the less core the flux must cross,
     the better; dual-stator lets flux go tooth→gap→magnet→gap→
     tooth with almost no yoke. Our weakest material property gets
     designed AROUND.
  4. Dual stator = redundancy + control authority (two independent
     3-phase sets can run staggered/failover — the 'maximum
     control' half).
- **PARITY REPORT (a mag-5 analysis function, honest by
  construction)**: torque_parity(cheap_material, reference) →
  the area/radius multiplier needed for torque parity (PM torque
  ~ B_gap × loading × gap area × radius; ferrite Br ~0.2-0.4 T vs
  NdFeB ~1.2-1.4 T → roughly 3-6x more gap area OR bigger radius
  at equal loading — dual gaps supply a clean 2x of it, diameter
  and stacking supply the rest). Every parity claim in any report
  MUST come from this function with its assumptions printed.
- **CARS = the aspiration rung, said honestly**: ladder is bench
  demo (prove blocks+mortar+SimpleFOC) → e-bike/cart class
  (hundreds of W) → in-wheel automotive class (the axial-flux
  research lane; ferrite-PM axial machines are a real published
  answer to rare-earth-free EV motors). Reports name their rung;
  nothing claims car-class until measured rows exist.
- Stacking rule: dual-stator units MODULE-STACK on one shaft
  (another 'blocks' axis — torque adds per stack, the small-space
  parity lever after diameter).

### mag-1 — Sourcing + formulas (supplychain; the "make" capability)
- ProductInputRequirement rows: `magnetic-geopolymer-mix`
  (matrix role = geopolymer-mix CASCADED at 1.11/kg self-made;
  filler role = magnetite 20-60 wt%), `magnetic-solgel-composite`
  (silica-xerogel cascade + magnetite), `wax-ferrite-feedstock`
  (print wax blend + magnetite — printable magnetics; BLCNC's
  alternating-ferromagnet dispersion idea rides this).
- **vol%↔wt% honesty**: msci rows speak vol% (35 vol%), recipes
  weigh wt% (magnetite ρ≈5.2 vs geopolymer ≈2.0 → 35 vol% ≈ 58
  wt%). The conversion lives ONCE in analysis code, densities as
  data, refusing when density is missing.
- ProductFormula rows per composite + formula_cost / cascaded make
  vs buy: our magnetic-geopolymer $/kg vs commercial soft-ferrite
  CORES (cite Fair-Rite/Amidon toroids + C-cores $/kg) and bonded
  magnets (cite ceramic magnet retail) — the same
  make-vs-buy-honest verdict pattern as wax/geopolymer.
- CITATION HUNTS: strontium-ferrite bonded-magnet powder
  (2026-07-28 pre-hunt: bulk literature figure ~$1.5/kg; retail
  small-lot via Stanford Advanced Materials / American Elements /
  magnet-powder.com needs a quote — est-flag until pinned); magnet
  wire (AWG enamel copper, $/kg — REQUIRED for any motor, uncited);
  Hall sensors + AS5600 magnetic encoder (~$3 class, SimpleFOC's
  standard position sensor); SimpleFOC Shield (~$35-50 street,
  simplefoc.com/shop + eBay/Amazon; MakerBase clone cheaper) or
  DRV8302 class driver; bearings + shaft stock; commercial ferrite
  ring magnets (the make-vs-buy benchmark for the PM rotor).
  PLUS the Rung-1 magnet feedstocks (§1b): strontium carbonate +
  red iron oxide EXACT from the pottery channel (Evans 1lb $2.25 /
  50lb $1.40/lb; Clay King Fe2O3 $2.10/lb tiers — pin exact rows),
  barium carbonate as the SrCO3 alternate (same shops; toxicity
  caveat as data), ammonia/urea (Fe16N2 aspiration node, cite when
  that node activates, not before).
  Est-flag anything bot-blocked, screenshots valid.

### mag-2 — Magnetic properties as data (materials seam) — seeds
the §1c catalog with REALIZATION_LEVELS
('theoretical'|'literature-demonstrated'|'recipe-seeded'|
'made-and-measured') + buyable_cited; gates: sim=always,
cost=cited-or-recipe, business=made-and-measured.
- Extend the supplychain/materials seam so items carry magnetic
  data columns: mu_r (from the msci L1 ladder — object coherence:
  reference the msci row, don't copy numbers), B_sat, coercivity,
  remanence, density. Unknown = None + characterization ASK, never
  a guess.
- Soft/hard grade split on ferrite rows (msci-22 has both in one
  row; the circuit blocks need them distinct).
- research-tools tree: gaussmeter + inductance-test nodes,
  easiest-first, honest difficulty; QA hooks (a wound-core
  inductance test IS a QualityCheckDefinition — µ verification per
  batch lands in the biz-4 QA machinery for free).

### mag-2r — FUNCTIONAL ROLE TAXONOMY + USE-CASE TAG SEARCH
(Dustin 2026-07-28: "different kinds of properties we need
addressed by different materials... tagging for materials, one of
the tags should be viable use cases... search casually the
different material options when making a cube or mortar")
- `MaterialUseRole` rows — the role vocabulary as DATA, each with
  required-property PREDICATES (JSON thresholds, editable knobs)
  so viability is DERIVED from property rows, never hand-stamped:
  - `electric-conductor` — two grades: power (σ near copper-class;
    today only magnet wire qualifies) and signal (σ above the
    ferrite-CNT percolation band — in-matrix traces qualify).
  - `magnetic-conductor` — soft flux guide: min µ_eff, LOW
    coercivity (magnetite composites, fired ferrite).
  - `torque-magnet` — hard PM doing work: min B_r + min H_c
    (SrFe12O19 bonded/fired; magnetite honestly FAILS this
    predicate — the taxonomy itself enforces the soft/hard split).
  - `flux-containment` — TWO mechanisms, both viable, mechanism
    tagged on the match: high-µ shunt (routes stray flux) vs
    non-magnetic fence (µ≈1 boundary courses in the matrix).
  - `structural-containment` — rotor physical containment: needs
    strength/toughness data (msci mechanical rows); unassessed
    until the data exists, honestly.
  - `magnetic-bearing` — PMs holding the rotor centered "so it is
    frictionless": hard-PM predicate + an **Earnshaw honesty note
    that travels with every match**: passive PM levitation is
    unstable in at least one axis (theorem, not opinion) — real
    designs center radially with PM rings and constrain ONE axis
    with a tiny mechanical point (jewel/pin, near-frictionless) or
    active/diamagnetic assist. The role is viable; 'fully
    floating passive' is not, and the row says so.
  - `in-matrix-sensing` — ferrite-CNT σ band + castable form.
  - `potting-encapsulant`, `mortar-joint` — the mortar-side roles.
- **Form axis separate from role axis**: castable-block (cube),
  mortar, wire, powder, potting — a material can be viable for a
  role in one form and not another; the (form, role) pair is what
  the search filters on.
- Derivation: viable/unviable/UNASSESSED per (material, role) from
  the property rows vs predicates — missing data = unassessed with
  the measurement/citation ask (never assumed viable); admin
  override is a knob row with its reason.
- **Casual search** (the UI ask): on the magnetics pages a
  role+form picker — "mortar, magnetic-conductor" → the viable
  list with the deciding numbers shown (µ_eff, σ, B_r, $/kg from
  supplychain) — riding msci-22's existing category/tag chips +
  click-to-filter browser; ELECTRONIC use cases are a top-level
  tag family there. Choosing a cube or mortar material during
  mag-4 layout editing opens this same filtered picker.

### mag-2t — THEORETICAL MAGNETIC POWDER DESIGNER (Dustin
2026-07-28: "simulate theoretical magnetic powders we can add to
geopolymers, sol-gels, and ceramics")
- `MagneticPowderDefinition` rows: is_theoretical FLAG + the
  property set (intrinsic µ_i, B_sat, H_c, B_r, density, particle
  size, electrical conductivity). Real powders cite; THEORETICAL
  powders are watermarked hypotheses — allowed everywhere in
  SIMULATION, refused everywhere in COST/BUSINESS (no citation can
  exist; the refusal names the sourcing hunt that would make it
  real).
- Composite predictor: powder row + matrix choice (geopolymer /
  sol-gel / ceramic / wax) + vol% → predicted composite µ_eff,
  density, $/kg-if-real. Quick analytic Maxwell-Garnett/Bruggeman
  estimate lives in `magnetics/`; the VALIDATED msci
  fem.effective-permeability engine is the L1 confirmation run
  (object coherence: reference the registry entry, don't fork the
  physics). Percolation engine covers the conductivity axis for
  conductive powders (CNT, magnetite).
- The §1c catalog is the sweep space: design studies run over ALL
  realization levels at once — "best magnet for purpose P" returns
  a LADDERED answer (best made-and-measured, best recipe-seeded,
  best buyable, best theoretical) so the short-term build and the
  long-term research target appear in one report, each watermarked.
- Design studies: sweep powder properties → "what powder WOULD hit
  µ_eff X at vol% Y in matrix Z" → when a theoretical powder wins,
  the output IS the sourcing ask (find/cite a real powder in that
  property box — SrFe12O19, NiZn, MnZn ferrite powders are the
  real boxes to check first).

### FERRITE-CNT CONDUCTION (Dustin: "ferrite CNTs should also be an
effective means of conduction") — the honest scoping
- Dual-property composites (magnetic + conductive) are REAL and
  simulable today: ferrite filler sets µ (k↔µ analogy), CNT
  loading sets σ (msci-23 percolation: 227 S/m @2 vol%, medium-
  independent above threshold). A `ferrite-cnt-geopolymer` /
  `ferrite-cnt-solgel` family joins the material rows.
- **Conductivity honesty**: 227 S/m is ~5 orders below copper
  (6e7 S/m). Ferrite-CNT conduction therefore targets: sensing
  electrodes/traces cast INTO blocks, shielding + static
  dissipation, resistive damping paths, electrode surfaces —
  NOT power windings and NOT induction-rotor cages until a
  measured row says otherwise (the report prints the copper gap
  every time). Power current stays in magnet wire; the mortar can
  carry SIGNALS through the monolith — that is the near-term win:
  sensor wiring disappears into the matrix like everything else.
- CNT costs already on record (src-6: MWCNT dispersion make 7.50
  vs 185 market); dispersion-in-mortar formula rides mag-1.

### §A2 / mag-fv — FIELD VIEWS IN SIMSPACES (Dustin 2026-07-29:
"define magnetic and electric fields in devices to be displayed in
simSpaces as either vector-fields where we have dispersed vectors
(which appear only in dispersions through the spaces where threshold
values are defined), or we define threshold spaces where we define
math-shapes that are varying colors and levels of transparent and
group them so we can alternate view of what the different important
electric and magnetic field flows in a device look like")

- **`FieldViewDefinition` rows** — one named view of ONE field of a
  device: device_ref (a MagneticCircuitDefinition / BlockLayout /
  electrodevice circuit), field_kind (B | H | E | J), source_ref +
  source_kind (see honesty below), display_mode:
  - `vector-dispersion`: vector glyphs SAMPLED through the SimSpace
    volume, drawn ONLY where |field| falls inside the view's
    threshold bands — sparse dispersions, not a dense hairball;
    sample density + seed = knobs on the row.
  - `threshold-shapes`: each threshold band becomes a REGION
    rendered as math-shapes (quadric/CSG rows via the mathshapes
    module) with per-band color + alpha — nested translucent
    shells showing where the field is strong/weak.
- **`FieldThresholdBand` rows** — {view_ref, min_value, max_value,
  color, alpha, label}; bands are DATA (edit the ladder, not code);
  units carried on the band (T, A/m, V/m).
- **`FieldViewGroup` rows** — named sets of views with an ordering:
  THE alternation ask — cycle/toggle which field flow of the device
  is shown (B-flow vs E-flow vs J-paths); a group is what the
  SimSpace scene binds, not a single view.
- **Source honesty (the watermark travels on every render)**:
  - `analytic`: exact closed forms (dipole, finite solenoid,
    straight wire, ring magnet on-axis) — available IMMEDIATELY,
    before any solver lands.
  - `reluctance-solve` (mag-3): per-element flux/B along the
    circuit's paths — renders as flux TUBES along element
    geometry, honestly 1D-per-path (no off-path field claimed).
  - `fem-2d` (msci fem engine): 2D field maps extruded with the
    stated symmetry.
  - Full 3D field maps = a later engine rung; views REFUSE a
    source that doesn't exist rather than faking one.
- **Module seams**: rows + sampling + band logic live in
  `magnetics/field_views.py`; mathshapes integration is
  FEATURE-GATED (mathshapes requires aquaponics+plant_morphology —
  heavy chain): with mathshapes absent, threshold-shape views
  refuse honestly naming the module, vector-dispersion views work
  everywhere; SimSpace binding rides the existing
  SimSpaceBindingDefinition pattern (object coherence).
- Selftests: analytic solenoid field vs hand values, band
  classification exactness, dispersion sampling respects
  thresholds + density, group cycling order, mathshapes-absent
  refusal, watermark presence per source_kind.

### mag-3 — BLOCK-BASED MAGNETIC CIRCUITS (the electrodevice mirror)
- New rows (mirroring circuit_basis 1:1):
  - `MagneticCircuitDefinition` — analyses_json: `op` (static flux
    solve), `sweep` (parameter/angle sweep).
  - `MagneticElementDefinition` — kinds: `mmf-coil` (N turns, I
    amps or drive ref), `core-segment` (material ref + length +
    area — µ from mag-2 data, refusal names the missing row),
    `air-gap` (length, area, fringing-factor knob), `magnet`
    (hard-grade material ref → Thevenin MMF source H_c·l_m +
    internal reluctance), `leakage-path`, `flux-probe`. Terminals
    wired by FLUX-NODE NAME.
  - `FluxNodeDefinition` — declared nodes; undeclared = suggestion
    riding the result (drift visibility), exactly like nets.
- `magnetic_netlist.py`: rows → reluctance network through a new
  `magnetic-netlist` GraphCompilerDefinition; pure-python nodal
  solve (numpy lstsq on the permeance matrix); returns flux per
  element, B = Φ/A per element, MMF drops.
- **Saturation honesty**: linear solve ALWAYS, then per-element
  check B vs B_sat — exceeded elements come back FLAGGED with the
  suggestion (bigger area / lower drive / better material), the
  run never silently lies. (Nonlinear µ(B) iteration = later rung,
  data-gated on B-H curves.)
- Optional parity: render the same network as a SPICE resistor
  netlist via the analogy and run through the EXISTING run_netlist
  — two solvers, one truth, regression-pinned (the spice_run
  promotion protocol replayed).
- Seeds: a gapped toroid inductor, a C-core + coil + gap, a
  horseshoe + keeper — each with hand-computable expected flux
  (selftest pins the math).

### mag-4 — SLOT-MATRIX ASSEMBLY: configurable blocks -> slotted
matrix -> thin selective mortar (Dustin 2026-07-28: "configure
block sizes (sometimes varying block sizes in one design) and then
'slot' them into place to make a matrix that is solidified by a
thin sol-gel mortar which we selectively make to be magnetic or
not")
- `BlockSizeVariant` rows: a small vocabulary of block geometries
  per design (brick, half-brick, tooth, wedge, arc-segment, disk-
  sector...) — MIXED sizes in one layout are first-class, exactly
  like masonry bonds.
- `BlockLayoutDefinition` + `BlockPlacement` rows: a slot grid
  (2D layers stacked to 3D) where each placement names its slot,
  its block variant, its MATERIAL (magnetic composite / plain
  structural / ferrite-CNT sensing / theoretical-watermarked), and
  interlock features (tongue/groove, dowel pockets) so blocks
  SLOT rigidly before mortar — dry-fit is a real assembly step.
- **Selective mortar per JOINT**: every adjacency in the layout
  gets a mortar assignment — magnetic (sol-gel-ferrite: flux
  passes) or plain (sol-gel: flux fence). The layout compiler
  derives the reluctance network FROM the matrix: flux paths are
  DESIGNED by placing magnetic blocks + magnetic joints and walled
  by plain ones. "Carefully control the magnetic field flowing
  through" is literally the layout: field routing by construction,
  containment by non-magnetic boundary courses (an outer flux-
  fence course doubles as stray-field shield).
- The mag-3 element rows GENERATE from the layout (placement →
  core-segment elements, joint → joint elements, coil pockets →
  mmf-coil sites) — hand-authored circuits stay possible, but the
  matrix is the primary authoring surface.
- Block library rows carry printable/castable GEOMETRY: C-core
  halves, E-core, toroid segments, pole shoes, rotor disks — tied
  into waxprint: **print the wax mold, cast magnetic geopolymer in
  it** (mold-1 strategies apply: release agent mandatory, reclaim
  loop cuts cost, fire-to-ceramic upgrade for µ).
- Per-block cost = volume × density × formula $/kg (+ mold ladder
  amortization from the biz-1 planner priors) + MORTAR cost per
  joint (joint volume × mortar formula $/kg). A designed magnetic
  circuit therefore prices itself part-by-part AND joint-by-joint —
  the same cost-per-part discipline as the order planner.
- Assembly steps as data: block → dry-fit (slotted, interlocked) →
  mortar (per-joint grade) → cure → (T1+) lap → wind → pot. Each
  step a workflow row (biz-1 ProcessWorkflowDefinition shape) so
  the planner can cost motor BUILDS the way it costs pots.
- **STRUCTURAL CONTAINMENT (Dustin: "contain and control the
  positioning of the stators and rotors rigidly")**: the matrix is
  simultaneously the magnetic circuit AND the frame. Bearing
  seats, shaft bores, and stator-to-stator alignment features are
  BLOCK VARIANTS in the same layout (non-magnetic structural
  blocks + plain mortar), so rotor/stator positioning rigidity
  comes from the same masonry that routes the flux — one solid
  object per sub-assembly, gap geometry held by construction, not
  by brackets. Alignment tolerance rides the §2c ladder (T0 slop
  → T1 lapped seats → T2 fired stability).

### THE MOTOR LADDER (Dustin 2026-07-29: "going from simple motors
with lower tolerances to more advanced ... with the end goal being
the dual stator; lower end and intermediate goals are also a good
idea")
- **M0 — CLOCK MOTOR (the control case)**: a Lavet-type single-
  phase stepper — the mechanism in every quartz clock: ONE coil,
  one tiny PM rotor, asymmetric stator notches that make detent
  positions, alternating-polarity pulses step it 180 deg at 1 Hz.
  Chosen exactly per Dustin's spec: smallest possible, low power
  (real ones run on uA-class pulses), LOW tolerance demands (mass-
  produced clock movements are deliberately sloppy — T0-friendly),
  and **verification = TIME ITSELF**: drive N pulses, count steps,
  compare accumulated rotation against wall-clock progression —
  missed steps over hours ARE the honest quality metric, no
  instrument needed beyond a clock face. Industrial precedent =
  billions of units.
- **M1 — reluctance demo** (6-slot/4-pole radial): closes the loop
  with ZERO permanent magnets (all-costed materials today);
  honestly feeble torque at mu~2, T0/T1.
- **M2 — small ferrite-PM rotor motor** (single-stator BLDC
  class): bonded/sintered hexaferrite rotor + wound stator, the
  commercial-precedent route; T1.
- **M3 — DUAL-STATOR AXIAL FLUX (the end goal, §2d)**: two stator
  disks sandwich one rotor; reluctance-disk variant first,
  ferrite-PM ring for torque; T1->T2; torque_parity() carries
  every parity claim.
Rungs are DATA (ladder_rung on the design row); each rung names
its tolerance tier and its verification method; nothing claims a
higher rung until the lower one has rows.
**BUILDER AXIS (Dustin 2026-07-29: "start as simple as we can and
go to more advanced, both in terms of tolerances and in terms of
samples people can build")**: every rung is a SAMPLE a person can
build, easiest first — the design row carries
build_requirements_json (tools, materials w/ catalog refs, skills,
rough hours) exactly like the research-tools tree carries honest
difficulty; M0 needs only a wound coil, two small castings, a
magnetizing pulse, and any 1 Hz pulse source (a 555/Arduino
class part). The walkthrough/bizops seam can turn a rung into a
shopping list the same way it does for pots.

### mag-5 — 3-PHASE MOTOR DESIGNER (SECTION C — module `motors/`,
motors are their OWN section per Dustin)
- `MotorDesignDefinition` rows: topology (radial/axial), pole
  count, slot count, phase winding map (which mmf-coil blocks
  belong to phase A/B/C, turns, wire gauge → resistance from
  magnet-wire citation), rotor type (reluctance salient /
  ferrite-PM ring), geometry params.
- The designer GENERATES the magnetic circuit rows: stator teeth =
  core-segments, gaps = air-gap elements parameterized by rotor
  angle θ, rotor poles/magnets per type. One motor = a FAMILY of
  magnetic circuits over θ.
- **Torque via virtual work over the reluctance network**: sweep θ,
  W(θ) from the solved network at 3-phase excitation (A/B/C
  currents at electrical angle), torque ≈ dW/dθ. Quasi-static v1 —
  no dynamics, no back-EMF waveform fidelity; the report SAYS SO
  and states the validity window. Outputs: static torque curve,
  torque ripple, stall torque estimate, kt/kV rough bounds.
- L2 escalation (data/deps-gated): scikit-fem 2D magnetostatics
  cross-section validation (the fem engine + worker already exist
  in msci); L4 = spin-DFT ferrite gap already named by msci-22.
- Every material slot in a motor design NAMES ITS ROLE (mag-2r):
  winding = electric-conductor:power, teeth = magnetic-conductor,
  rotor magnets = torque-magnet, bearing rings = magnetic-bearing,
  shell courses = flux-containment + structural-containment. A
  design with a role filled by a non-viable/unassessed material
  FLAGS it (suggestion: pick from the viable list) — wrong-
  material-in-role becomes visible at design time, not build time.
- torque_parity() analysis (§2d) ships WITH the designer — every
  'parity with expensive materials' statement traces to it.
- Seeds: (1) a 6-slot/4-pole RADIAL reluctance motor as the
  simplest hand-checkable case; (2) the FLAGSHIP: dual-stator
  axial-flux row (12-tooth per stator / 8-pole rotor class) sized
  to a 3D-printable mold envelope — reluctance-disk variant runs
  today, ferrite-PM variant REFUSES until the hard-ferrite
  citation + bonding formula land (the refusal is the shopping
  list).

### mag-6 — Drive: SimpleFOC first, FPGA as the escalation rung
- **SimpleFOC is the v1 controller** (Dustin 2026-07-28): the
  open-source Arduino/STM32 FOC stack + SimpleFOC Shield class
  driver (~$35-50; MakerBase clone cheaper) + AS5600 encoder.
  Rank: open-source-non-polari on the preference ladder — exactly
  what stage 0/1 should buy, not build. DUAL-stator = two 3-phase
  sets: v1 wires them in parallel (one controller), v2 runs two
  synchronized controllers (the control-authority/failover story).
- Rows: MotorControllerProfile (SimpleFOC board, firmware params —
  pole pairs, sensor type, current limits — as DATA so a design
  generates its SimpleFOC config snippet), plus the electrodevice
  inverter circuit rows for understanding/teaching (ngspice runs
  the half-bridge TODAY) — the bought shield replaces building it,
  the circuit rows keep the theory inspectable.
- `PhaseBindingDefinition` (level_bridge mirror): motor phase →
  shield terminal → (escalation) FPGA PWM channels per the
  hardware architecture (FPGA = timing; MCU = safety supervisor).
  hwsim (Renode STM32) can exercise commutation/SimpleFOC firmware
  before hardware exists — later rung, named not promised.
- Honest seam: simulation-only until hardware tiers say otherwise;
  every hardware-facing row is a knob + suggestion, never auto.

### mag-7 — Visuals (/magnetics)
- Angular page: circuit editor over the rows (same no-code display
  pattern as /pspp pages), flux-path view (element list with B,
  flagged saturations red), motor cross-section SVG with per-θ
  torque chart, cost-per-part panel from mag-4.
- SimSpace3D scene for the assembled motor (mathshapes primitives
  suffice for v1 geometry).

### mag-8 — Business + tech-tree splice
- Products: inductor cores, sensor cores, flux-guide sets, motor
  kits → bizops: PRESTAGE_VARIANTS entries, readiness EARNED per
  variant, QA checks (crack + inductance/µ verification +
  dimensional fit), compliance: honest-labeling applies (no
  medical/EMC claims without certification — same voluntary-claim
  gating shape as plant-safe).
- Tech tree: fill the **Electromagnetic systems** TODO row —
  theory segments = msci ferrite family + magnetics module; data
  gaps = B-H curves, hard-ferrite citation; escalation = cast →
  fired → sintered.
- Partnerships/deal shape: magnet wire + hard ferrite are the new
  supply flows; deal_price_window applies unchanged.

## 3. Selftest discipline (every phase)
Fixture-manager selftests per module file (check() pattern), pinned
hand-computed physics (gapped-toroid flux, two-solver parity,
vol%↔wt% conversions, θ-sweep symmetry: torque period = 2π/poles),
refusal paths (missing µ, missing B_sat, PM without hard-grade
data, motor without magnet-wire citation), and the in-process
live-boot probe extended with /api/magnetics routes.

## 4. Explicitly OUT of v1 (named so nobody trips)
Eddy currents/core loss numbers, hysteresis loops, thermal limits,
dynamic (dq-frame) SIMULATION (the real dq control runs in
SimpleFOC on hardware — we don't duplicate it in v1 sim),
acoustic/vibration, self-wound coil winding machines (a later
manufacturing-tools node), rare-earth magnets (against the
accessible-materials ethos and unnecessary for the proof —
ferrite-PM axial flux is the published rare-earth-free lane),
automotive-class claims of any kind until measured rows exist.
