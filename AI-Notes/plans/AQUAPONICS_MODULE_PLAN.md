# Polari Aquaponics Module — Self-Watering Pot Simulation

**Status 2026-07-08**: SPEC CAPTURED, design in progress. This is a new
first-class Polari MODULE (`aquaponics/`, sibling of `materialsScience/`
and `scoring/`) — Dustin 2026-07-08. First deliverable: a multiscale
self-watering pot simulation. Nothing built yet; this doc is the
durable spec so it survives across sessions.

> Context note: an earlier description of this work did not reach the
> current session — this plan is rebuilt from Dustin's 2026-07-08
> restatement. If an earlier, fuller spec exists (possibly on the
> isle-core Claude instance), reconcile against it.

## Dustin's directive (2026-07-08, verbatim intent)

Simulate a self-watering pot.

- **Pot material**: ceramic OR geopolymer, a WATERPROOF variant of the
  material.
- **Holes**: at least two in the side (more with pot size). Higher
  holes = water INPUT, lower holes = water OUTPUT, on OPPOSITE sides.
- **Multiscale soil definitions** and **multiscale water definitions**,
  each with **nutrient profiles**.
- Water source assumed **aquaponic or hydroponic**; nutrient profiles
  **tunable**.
- **Tunable**: pot size; input/output slot diameter, height, and
  number. Slot ANGLES tunable but LIMITED — water must still flow
  through by GRAVITY.
- **Plant profile PER PART** analysing the PERMANENT structure of the
  plant and its composition → assess PERMANENT capture of carbon and
  other nutrients over the lifetime, BY VOLUME per part.
- Assess NEEDED and MIN–MAX nutrient input/output per part, INCLUDING
  CO₂ and O₂ → environmental impact over a lifetime for the individual
  plant + survival conditions.
- Fully simulate ATMOSPHERIC conditions.

## Module framing

`aquaponics/` module (module boundaries + ModuleSourceConfig idiom, per
[[materials-science-module]] modules-as-projects). Reuses, does not
rebuild:
- **Materials science** for the pot material (ceramic/geopolymer as
  MaterialsScienceMaterial + scale definitions; waterproofing =
  porosity/permeability property), and for multiscale soil/water as
  materials with per-scale nutrient properties.
- **Simulation framework** (SimulationDefinition/Runner/
  ExecutionSolution, SimSpace3D) for the flow + growth + atmosphere
  simulation; coupling machinery (wind→pendulum pattern) to couple the
  scales/spaces.
- **Scoring** (the just-built context-scoring engine) for environmental
  impact scoring — carbon capture, nutrient balance, survival-condition
  concepts are ScoreConcepts over per-part / per-lifetime values.
- Standing principles: [[object-coherence]] (every capability maps to a
  configurable object), [[knobs-and-suggestions]] (every tunable = an
  explicit knob), [[file-size-decomposition]], [[branch-per-confirmed-
  phase]].

## Object model (draft — refine against the sim/materials survey)

Every one of these is a treeObject → auto-CRUDE + persisted + tunable
at its row (object-coherence).

### Pot geometry + material
- **PotDefinition**: parametric vessel — outer/inner diameter, height,
  wall thickness, base thickness, shape profile (cylinder/tapered),
  material ref (→ a waterproof ceramic/geopolymer material). Knobs all
  tunable.
- **PotHole** (child rows of a pot): kind (input/output), diameter,
  height-up-the-wall, azimuth (side), angle (tunable but CLAMPED to a
  gravity-valid range so output stays gravity-fed), count generated or
  enumerated. Constraint engine: input holes ABOVE output holes, on
  opposite sides; validate that every path is downhill for outputs.
- **PotMaterial**: a MaterialsScienceMaterial (ceramic/geopolymer)
  with a waterproofing treatment → porosity/permeability property
  (near-zero permeability = "waterproof variant"). Multiscale via the
  existing scale-definition ladder.

### Soil + water (multiscale + nutrient profiles)
- **SoilDefinition** (multiscale): particle/pore structure per scale
  (grain L-levels), water-holding capacity, field capacity, wilting
  point, hydraulic conductivity, cation exchange; **NutrientProfile**
  attached.
- **WaterDefinition** (multiscale): the aquaponic/hydroponic solution —
  dissolved O₂, pH, EC, temperature; **NutrientProfile** attached
  (tunable). Multiscale = molecular ↔ bulk-flow properties.
- **NutrientProfile** (shared, reusable): concentrations per nutrient
  species (N species — NO₃/NH₄, P, K, Ca, Mg, S, micros, dissolved
  CO₂/O₂). One profile row, referenced by soil, water, and plant I/O
  targets. Tunable knobs.

### Plant (per-part structure, composition, nutrient I/O)
- **PlantDefinition**: species-level identity + lifetime model
  (germination → growth → maturity → senescence timeline).
- **PlantPart** (root / stem / leaf / flower / fruit / …): rows per
  part with
  - PERMANENT structure fraction + composition (what stays sequestered:
    lignin, cellulose, structural C, mineral content) → carbon +
    nutrient captured BY VOLUME per part over the lifetime.
  - Nutrient I/O per part: needed + MIN–MAX input/output per species,
    INCLUDING CO₂ (uptake) and O₂ (root demand / photosynthetic
    release). These drive the environmental-impact + survival reads.
- **PlantLifetimeState**: the growing part-volumes over time (the sim
  integrates part growth against nutrient/water/atmosphere
  availability).

### Atmosphere
- **AtmosphereDefinition**: full atmospheric state — CO₂, O₂, humidity,
  temperature, pressure, light (PAR), airflow. Tunable; can be driven
  by a controlled environment (like the fridge-ambient knob in the MVW
  print sim). Couples to plant CO₂/O₂ exchange and to
  evaporation/transpiration.

### The simulation itself
- **SelfWateringPotSimulation** (a SimulationDefinition subtype):
  couples the spaces —
  1. **Hydraulics**: gravity flow through input→soil→output holes;
     reservoir/wicking behaviour that makes it "self-watering";
     water level, drainage, capillary rise into soil.
  2. **Transport**: nutrient + dissolved-gas transport in the water/
     soil (advection through flow + diffusion), delivered to roots.
  3. **Plant growth**: per-part volume integration vs nutrient/water/
     light/CO₂ availability and min–max survival bands.
  4. **Atmosphere exchange**: CO₂/O₂/water-vapour exchange between
     plant, water surface, soil, and the AtmosphereDefinition.
  - Outputs: per-part permanent carbon/nutrient capture by volume over
    lifetime; per-part + whole-plant environmental impact (net CO₂,
    net O₂, nutrient draw); survival-condition verdicts (in/out of
    min–max bands, with the limiting factor named — the honest-absence
    idiom).

## Multiscale decomposition (scales × environment)

Mirrors the MVW print sim's A/B/C-scale + environment layout:
- **Scale A — vessel (mm, continuum)**: pot geometry, hole hydraulics,
  bulk water level + gravity drainage. FEM-style or reduced 1D reservoir
  model.
- **Scale B — soil/root zone (particle ↔ pore)**: multiscale soil,
  capillary rise, nutrient transport to root surfaces, root uptake.
- **Scale C — plant part (tissue, composition)**: per-part growth,
  permanent-structure accretion, nutrient/gas I/O against min–max.
- **Environment**: AtmosphereDefinition (controllable), light, the
  aquaponic/hydroponic source feeding the input holes.

Coupling: reservoir level (A) → capillary/moisture (B) → uptake &
growth (C) → transpiration/CO₂-O₂ back to atmosphere → evaporation pulls
on A. The wind→pendulum coupling pattern is the template for wiring
space-to-space feeds.

## Scoring / accountability tie-in (reuse the context-scoring engine)
Environmental impact + survival are SCORES over sim outputs:
- ScoreTerms: net-carbon-sequestered (per-part, by volume), net-CO₂,
  net-O₂, nutrient-use-efficiency, water-use per gram of permanent
  biomass, survival-margin.
- ScoreConcepts compose them per plant / per lifetime; Contextualized
  Values resolve LIVE from sim results via the objectRef/resolve_binding
  seam (same as the beeswax@L1 FEM demo). Lets a pot+plant+water config
  be RANKED for environmental impact the same way materials are.

## Open design questions (resolve during build)
- Fidelity of the hydraulics: full 3D CFD is overkill for a first cut —
  start with a reduced reservoir + Darcy-flow-through-soil model, expose
  an h-coefficient-style fidelity knob (the MVW convection-knob idiom),
  answer "does angle X still drain?" by simulation not assumption.
- Plant growth law: mechanistic (per-part source/sink) vs empirical
  growth curves — likely a declarable PlantDefinition knob with a
  conservative default and honest "prior until measured" flags (MVW
  blend-melt idiom).
- Eutectic/interaction effects in nutrient chemistry: model as
  independent species first, flag interactions as a known simplification.

## Build phasing (branch per confirmed phase)
- **aqp-1 BUILT** (dev-aqp-1-pot, 22ecbcb): PotDefinition + PotHole with
  the gravity-clamp constraint validation, two waterproof pot materials
  (geopolymer/ceramic) as materials-science rows + 3 hydraulic property
  meanings, generate_holes, API. selftest_pot 20/20. (SimSpace3D render
  deferred.)
- **aqp-2 BUILT** (dev-aqp-2-media, e7cd7bf): NutrientSpecies vocab +
  NutrientProfile + SoilDefinition + WaterDefinition (multiscale,
  tunable) + aquaponic/hydroponic sources; media analysis (available
  water, N:P:K, dissolved-gas checks; aquaponic Fe/K deficiency shows).
  selftest_growth_media 17/17.
- **aqp-3 NOT BUILT** — the dynamic hydraulics. Needs a NEW scikit-fem
  scalar Darcy/diffusion engine (materials survey confirmed no fluid
  physics exists) + *SimState classes + SimulationCouplingDefinition +
  a MultiScaleSimulationDefinition. The reduced reservoir + Darcy-
  through-soil model with a fidelity knob; answers "does slot angle X
  still drain?" dynamically. THE remaining phase.
- **aqp-4 BUILT** (dev-aqp-4-plant, 7f403df): PlantDefinition +
  PlantPart (permanent structure + fate, composition, per-part
  nutrient/CO₂/O₂ flux w/ min-max); part_capture, lifetime capture
  (CAPTURED vs PERMANENTLY-SEQUESTERED by fate — refuses greenwash),
  gas/nutrient budget. selftest_plant 16/16.
- **aqp-5 BUILT** (dev-aqp-5-atmosphere, b210e44): AtmosphereDefinition
  (open/controlled, CO₂/O₂/T/RH/light/ventilation); VPD by Tetens +
  plant↔air gas exchange (open unlimited / sealed depletes / ventilated
  steady-state CO₂). selftest_atmosphere 10/10.
- **aqp-6 BUILT** (dev-aqp-6-impact, 3ab1e76): PotSystemDefinition binds
  pot+soil+water+plant+atmosphere; system_survival (supply-vs-demand,
  limiting factor named — tent VPD-stressed, sealed chamber fails on
  CO₂) + system_impact (lifetime permanent carbon, N/P/K removed from
  the loop, water throughput); scoring bridge = pot-environmental-impact
  ScoreConcept ranking systems live via objectRef into
  impact_result_json. selftest_system 13/13.

**Status 2026-07-08 (evening)**: aqp-1/2/4/5/6 BUILT + committed (5
stacked branches off the scoring stack; 76 module selftest checks
green; scoring parity intact). NOT deployed to staging yet. aqp-3
(hydraulics engine) is the one remaining phase.

## Conventions
Branch per phase (dev-aqp-1…); selftests per module; staging deploy per
the rebuild-staging convention (LOCAL_IP=192.168.0.210, nip.io hosts);
knobs-and-suggestions; object-coherence; labels/derived-values travel
with their numbers (the scoring-engine honesty idiom).
