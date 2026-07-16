# Tower Life-Support Planning — nutrition + carbon-balanced growth towers

**Written 2026-07-16 as a durable, cross-agent handoff.** Dustin is
switching execution to Fable 5 (to flesh out more plant species) while
this document captures the overall plan. Any agent picking this up —
read this file, `AQUAPONICS_POT_SHAPE_PLAN.md`, and
`HOUSEHOLD_NUTRITION_PLAN.md` in full before writing code. This is a
PLANNING document — nothing in this file has been built yet unless
explicitly marked done and cross-referenced to one of those two plans.

## The goal, verbatim (Dustin, 2026-07-16)

> The ultimate goal of a "perfect tower" is to be tuned to the number
> of people using it and slightly overproduce, all of their
> nutritional needs, as well as being able to cycle their carbon for
> the day. While resulting in a slight carbon negative capture through
> harvest cycles.

> Understand that we do detailed simulations per individual plant pot,
> and then we use the derived equations from those individual
> intensive simulations to calculate the overall behavior of a tower.

> We will also have to start accounting for the logical tube
> interconnect pathways and pot positioning in the tower to ensure all
> plants can grow to their desired harvest size. Accounting for the
> fact we can build multiple towers to meet our goals if needed, but
> each tower individually should try to achieve as much towards that
> goal as possible.

> A real world scenario will have users selecting 3D Cube spaces in AR
> in their home indoors, to use as the space to populate with towers
> to try and reach a "goal".

> We should assume cabinets and grow light use as well for these
> plants, this way day/light cycles are also controllable, therefore
> we can control and balance respiration of the plants and their
> carbon cycling so that the daily carbon cycling is stable at all
> times. (Having many plants indoors in the calibrated tower system
> overall should always produce a stable Human Healthy CO2 partial
> pressure.)

> We should account for this for both a system with external
> ventilation at particular rates for safety (an outside with slightly
> above safe CO2 levels like 1000 to 2000 ppm CO2) which would be a
> near future concern... Then a system with true isolation where
> failure is not an option and it has to work perfectly and we need
> high fault tolerance, likely for moon bases, or mars settlements.

> Oh and the third scenario of just wanting to grow food and we want
> to ensure this won't draw unsafe amounts of oxygen at night and
> accidentally create a bad indoor air quality, while trying to
> maximize nutrition needs.

Also, from the immediately preceding turn (2026-07-16, same
conversation): plants should be categorizable by optimization profile
— some species tuned more for carbon capture, others for particular
nutrient targets — so a tower's species mix can be selected toward its
goal rather than uniform.

**This is planning only** — Dustin's own words, confirmed twice in
this same exchange: nothing below should be built yet except where a
section is explicitly cross-referenced as already done in
`AQUAPONICS_POT_SHAPE_PLAN.md` or `HOUSEHOLD_NUTRITION_PLAN.md`.

## Reference values (Dustin, 2026-07-16 — use these, don't re-derive)

These replace what was an open question in an earlier draft of this
plan. Treat them as the load-bearing numbers for every tier/phase
below that touches CO2/O2 targets. Worth a real citation check before
this becomes anything more than a simulation input (these track real,
commonly-cited figures — e.g. pre-industrial ~280ppm CO2, current
ambient ~420-430ppm, OSHA/NIOSH-style 19.5%/23.5% O2 deficient/
enriched-atmosphere bounds — but confirm against a real source before
treating as authoritative for anything beyond this simulation).

**CO2 (ppm):**
- 280 — pre-industrial; the IDEAL indoor target for the "modern health
  optimization" case (Tier 1's most ambitious goal).
- 432 — current real-world ambient outdoor baseline.
- 950 — the SAFETY-MARGIN indoor target: comfortably under the 1000
  line, the minimum-acceptable outcome if 280 isn't reachable.
- 1000 — the official cited safety limit. At or below = safe. Above =
  unsafe (a health/cognitive-comfort threshold, NOT an acute-danger
  threshold — consistent with the earlier framing that a system
  failing back to ventilated-but-untreated air is still survivable,
  just unhealthy).
- 1200 — the near-future "unaddressed/exacerbated" outdoor test-case
  scenario (above the 1000 safety line) that Tier 1's ventilated
  system is specifically sized to bring back down, ideally to 280,
  minimally to 950.

**O2 (%):**
- 19.5-23.5 — the safety band (below 19.5 = oxygen-deficient/hypoxia
  risk, above 23.5 = oxygen-enriched/fire-hazard risk). Hard bounds,
  relevant to EVERY tier including Tier 0's safety-only cap.
- 20.8-21.0 — the ideal/target band for health optimization (real
  atmospheric O2 is ~20.9%, so this is a tight "don't meaningfully
  deplete it" band, not an ambitious swing like CO2's 280 target).

These numbers directly parameterize Phase 25 (new, below) and every
tier-sizing phase after it — a candidate tower/ventilation
configuration is evaluated by simulating its indoor trajectory against
these exact bands, not a vague "keeps it healthy" check.

## Architecture — four layers, don't collapse them

This is the single most important structural decision in this plan.
Do NOT try to run the tower-level or multi-tower-level math by
literally simulating every pot's full FEM/Darcy/skeleton/light/stress
pipeline at request time — that doesn't scale past a handful of pots
and defeats the whole point of the equation-derivation step Dustin
explicitly called for.

1. **Individual pot simulation (detailed, slow, ground-truth)** —
   EXISTS, this is the whole body of work in `AQUAPONICS_POT_SHAPE_PLAN.md`
   phases 1-14b: `plant_growth_normalized.py` (free-soil constants →
   constrained limits → per-part normalized growth), `plant_skeleton.py`
   (animation-bones geometry, now container-clamped + branching-correct),
   `light_field.py` (real photon-counting PPFD + absorption),
   `plant_stress.py` (per-part stress curves), `water_level.py` /
   `water_batch.py` / `nutrient_uptake.py` (water/nutrient cycling —
   phase 15/16 work below extends this), `plant_analysis.py`
   (carbon capture, temporary vs permanent), `nutrition/harvest_analysis.py`
   (harvest → human nutrient yield). This layer is expensive per-call
   (real Darcy/FEM solves, recursive skeleton walks) but authoritative.

2. **Derived equations / response surfaces (NEW, this is the bridge)**
   — for each species (and eventually each species × pot-size ×
   light-regime combination that matters), run layer 1 across a
   representative sweep of conditions (growth stage, water source,
   light schedule) and FIT or closed-form-derive compact functions:
   time-to-harvest-readiness, water/nutrient consumption rate as a
   function of growth stage, net O2/CO2 flux as a function of light
   exposure and growth stage, carbon captured (temporary vs permanent)
   as a function of harvest time and part disposition, human-nutrient
   yield as a function of harvest time. This mirrors the EXISTING
   precedent in this codebase — `plant_growth_normalized.
   closed_form_logistic()` is already an exact closed-form solve
   reused directly by `plant_growth_simplified.py` "pulling from the
   isolated single-plant model what the average constants would be at
   different ages" (Dustin's own words, phase 9) — this is the SAME
   pattern, generalized to more outputs (water, carbon, nutrition, gas
   exchange) than just growth volume. Where a real closed form isn't
   derivable, a fitted lookup/interpolation table over the layer-1
   sweep is the fallback — always label which one it is, never hide a
   fit as if it were exact.

3. **Tower-level aggregate (NEW)** — given a tower's actual pot
   layout (positions, species assigned, tube interconnects, light
   schedule per zone), sum/combine the per-pot DERIVED functions (fast,
   layer 2 — no re-running layer 1 per pot) into tower-level totals:
   total nutrient yield per week, total O2/CO2 flux over 24h (respecting
   each pot's own light schedule offset — see "light staggering"
   below), total water/nutrient-solution demand + refill cadence,
   total carbon captured (temporary + permanent) per harvest cycle.
   Also enforces the PHYSICAL constraints (below): pot positions must
   leave room for each plant's own free-soil-derived canopy
   spread/root depth at ITS intended harvest size, tube routing must
   be a valid gravity-feasible graph (reuses `aquaponics.hydraulics`
   gravity-validity conventions), and the whole assembly must fit
   within a stated bounding volume (feeds the future AR consumer,
   layer 4).

4. **Multi-tower / goal-allocation (NEW)** — given a target (N people's
   nutrition + N people's daily CO2 handling + a net-carbon-negative
   requirement), and given each candidate tower's layer-3 aggregate
   output, decide how many towers + what species/pot mix per tower
   meets the goal with slight overproduction, honoring Dustin's
   explicit constraint: "each tower individually should try to achieve
   as much towards that goal as possible" — i.e. this is NOT a
   free-form bin-packing split; prefer configurations where towers are
   each independently near-complete solutions, not several towers that
   only work in combination (a real fault-tolerance property: if one
   tower goes offline, the others should still be covering as much of
   the goal as they can on their own, especially relevant for the
   isolated/life-critical tier below).

5. **AR spatial placement (FUTURE, frontend, explicitly OUT of scope
   for the phases below)** — a user selects a 3D cube volume in AR;
   the system proposes tower configurations (from layer 4) that fit.
   This consumes layer 3's bounding-volume output. Do not build UI for
   this yet; DO make sure layer 3's tower geometry exposes real
   dimensions (footprint, height, tube clearance) so this is a
   straightforward later consumer, not a redesign.

## What already exists — read before building, don't duplicate

- **Pot/growth/water/light/stress/skeleton**: all of
  `AQUAPONICS_POT_SHAPE_PLAN.md` phases 1-14b (this session,
  2026-07-15/16). Real per-species data for sweet-basil + dwarf-pepper
  currently; everbearing-strawberry incomplete. Fable 5's plant-roster
  expansion work should follow the exact phase-12 recipe documented
  there ("dwarf-pepper brought to full parity") for each new species —
  `PlantDefinition`/`PlantPart`/`PlantGrowthModel`/`RootSystemModel`/
  `OrganModel`/`StressResponseCurve` rows, real not placeholder numbers,
  live-verified against the running backend, documented the same way.
- **Household/person/nutrition demand modeling**: `HOUSEHOLD_NUTRITION_PLAN.md`
  phases nut-1 through nut-4 are DONE (`nutrition/` module — nutrient
  vocabulary, harvest→nutrient yield, person profiler with BMR/goals,
  household roll-up). nut-5 (fulfillment simulation — the actual
  "does this garden cover this household's needs" calculator) and
  nut-6 (a garden SYSTEM model) are SPEC'D BUT NOT BUILT. **This is
  where the tower work plugs in** — nut-5/nut-6 predate this session's
  richer growth model and reference the OLD `aqp-8`/`plant_growth_simplified.
  grow()` call shape and a simpler `KratkyPotDefinition`/
  `GardenSystemDefinition` pair. When building nut-5/nut-6 (or their
  tower-scale successors below), update them to consume the REAL
  current growth/water/carbon pipeline (`PotPlanting`,
  `current_root_profile`/`current_canopy_profile`,
  `water_level_trajectory`, `plant_lifetime_capture`) instead of the
  stale `grow()` shape — do not build a second, parallel nutrient-demand
  system from scratch.
- **Carbon capture (temporary vs permanent)**: already built and
  matches Dustin's own framing closely — `PlantPart.fate`
  (harvested/senesces = temporary, soil-incorporated/standing-permanent
  = permanent) + `PlantPart.composition_json` (real per-part carbon
  fractions) + `aquaponics/plant_analysis.py::plant_lifetime_capture()`.
  Real caveat already flagged in this session's own conversation with
  Dustin and worth carrying forward in any new docs/UI: composted
  carbon is NOT 100% permanent in reality (a meaningful fraction
  off-gasses as CO2 during decomposition; the current model's
  "soil-incorporated = permanent" is a stated simplification, not
  measured). `plant_lifetime_capture` currently assumes full maturity
  — needs extending to accept a LIVE `PotPlanting`'s actual current
  growth state (see phase 15 below).
- **Carbon/oxygen gas exchange**: partially exists —
  `atmosphere_analysis.environment_gas_exchange()` +
  `plant_gas_nutrient_budget()` compute a DAILY-MEAN O2/CO2 balance
  (own docstring: "no diurnal cycle") off a STATIC per-species maturity
  flux constant. Needs the day/night split + live-growth-state +
  real-light driving described in phase 19 below.
- **Tower-level water cascade**: NOT built. Flagged as deferred since
  phase 10/11 of `AQUAPONICS_POT_SHAPE_PLAN.md` ("tower-level gravity
  water cascade" — explicitly named there as future work, confirmed
  the `AquaponicTowerDefinition` class is "purely geometric with zero
  water-flow hooks today" per phase 10's own research). This plan's
  "tube interconnect pathways" work (phase 20 below) is that deferred
  item, now scoped concretely.
- **Water-level physics (the holes/overflow conversation)**: Dustin
  confirmed 2026-07-16 that holes-only water-level control (no tube
  redesign needed) is fine IN CONCEPT — the real, confirmed bug is that
  `build_darcy_payload()`/`water_batch.py`/`water_level.py` all default
  "full" to the highest INPUT hole's height (a demo-convenience
  default) instead of `validate_pot()`'s already-correct
  `maintainedWaterLevelMm` (the lowest OUTPUT hole's lip — the real
  overflow-controlled level). This is a real, small, well-scoped fix
  (see phase 15 below) — fix it before trusting any water-cycle numbers
  from phases 17+.

## New phases (foundation, single-pot scope — do these before tower work)

These were already scoped with Dustin earlier in this same
conversation (before the tower ask arrived) and remain the correct
prerequisite order — the tower layers above are NOT buildable on real
numbers until these land:

- **Phase 15 — bridge live growth state into carbon-capture +
  nutrition analysis.** `plant_lifetime_capture()` and
  `nutrition/harvest_analysis.py::harvest_nutrients()` both currently
  assume/require a maturity-constant or an old `grow()` shape instead
  of a real `PotPlanting`'s current `current_root_profile`/
  `current_canopy_profile` state. Fix both to accept a live planting,
  so "harvest at time T" scenarios use the plant's ACTUAL state at T,
  not an assumed-mature one. Also add the missing dwarf-pepper
  `FoodItem` row.
- **Phase 16 — fix the water-level "full" default + nutrient-uptake
  calibration bug + add a real tap-water profile.** Three files
  (`hydraulics.py`, `water_batch.py`, `water_level.py`) need to use
  `validate_pot()`'s real `maintainedWaterLevelMm` instead of the
  highest-input-hole default. Separately, `nutrient_uptake.py`'s own
  docstring already flags that BOTH currently-seeded water sources
  saturate to factor 1.0 for every species (a real calibration
  mismatch from an earlier phase) — nutrient deficiency literally
  cannot bind until this is recalibrated against real `flux_json`
  numbers. Then add a real "plain tap water" `WaterDefinition` (near-
  zero N/P/K, honestly labeled as typical/illustrative, not a specific
  municipality's real water report) for the tap-vs-perfect-solution
  comparison in phase 18.
- **Phase 17 — Plant Water Cycle: optimum batch-refill solver.**
  Build on `water_level_trajectory()` (already real, decomposed
  drainage/evaporation/transpiration). New: a search over batch
  parameters (fill amount, hold duration) that minimizes stale sitting
  time while keeping the plant's own water-related stress factor above
  a stated threshold (propose 0.95 — "just starting to notice stress"
  — as the trigger point, flag as a tunable knob, not a hidden
  constant) until refill. Compute this at several representative
  growth stages (seedling / vegetative / mature) since transpiration
  demand scales with real leaf area from `current_canopy_profile` —
  the answer should genuinely differ by life stage, not be a single
  number.
- **Phase 18 — Plant Nutrient Cycle: tap water vs perfect solution.**
  Using phase 16's fixed calibration, simulate forward under both
  water sources and find: does/when does the plant cross into
  detectable stress (same threshold convention as phase 17) for a
  specific nutrient; which nutrient triggers first; how the answer
  changes across life stages. Verify during implementation whether
  `PlantPart.flux_json`'s daily need already scales with the part's
  CURRENT size (growth fraction) or is a flat absolute regardless of
  size — if the latter, that's a bug worth fixing here too (a
  seedling should not have a mature plant's absolute nutrient demand).
- **Phase 19 — Carbon/Oxygen day-night cycling.** Replace
  `plant_gas_nutrient_budget()`'s static per-species maturity flux
  constant with a real day (photosynthesis, driven by
  `light_field.py`'s real absorbed-PPFD-per-part, net O2 production)
  vs night (respiration only, net O2 consumption) split, driven by the
  plant's CURRENT growth state (real leaf area), not an assumed
  maturity number. Needs real published typical values for
  photosynthetic quantum yield / dark respiration rate per unit leaf
  area or biomass — cite the source, flag as literature-typical not
  measured-for-this-cultivar, same discipline as every other
  biological constant in this codebase. This is the direct foundation
  for the tower's CO2-stability claim (phase 21/22 below) — get this
  right before building tower-level gas-exchange math on top of it.
- **Phase 20 — Harvest scenario synthesis.** The composed report:
  "harvested at time T, compost the bottom + eat the top → carbon
  result + nutrition result", combining phases 15/17/18/19's real
  outputs per planting.
- **Phase 21 — Derive closed-form/fitted equations from phases 17-20's
  simulated data.** This is layer 2 of the architecture above, scoped
  down to single-species. Do NOT attempt this before 17-20 produce
  real data to fit — deriving equations from data that doesn't exist
  yet is exactly the kind of guessed/invented result this whole
  codebase's discipline exists to avoid.

## New phases (tower scope — after the foundation phases have real per-species equations)

- **Phase 22 — plant optimization-profile categorization.** A derived
  (not hand-authored) classification per species: given phase 21's
  equations, compute each species' carbon-capture rate per pot-volume
  and per unit time, and its nutrient-density profile (which nutrients
  it's a strong source for, from the existing `nutrition/` vocabulary),
  and label species as carbon-leaning / nutrition-leaning / balanced —
  a real ranking derived from simulated numbers, not a guessed tag.
  This is what lets phase 24's tower composer pick a species MIX
  toward a stated goal.
- **Phase 23 — tube interconnect + pot positioning model.** The
  deferred tower-level water cascade, now scoped: a graph of pot
  positions + tube connections (reuses `aquaponics.hydraulics`'s
  gravity-validity conventions — a tube run must be gravity-feasible,
  same "inputs above outputs" logic already used per-pot, extended
  pot-to-pot) + a packing check using each assigned species' REAL
  free-soil canopy-spread/root-depth ceiling (from
  `constrained_limits`) at its intended harvest size, so a tower layout
  never assigns a plant a footprint smaller than its own real target
  size needs. Exposes real tower dimensions (for the future AR
  consumer).
- **Phase 24 — light-cycle staggering for CO2 stability.** Cabinet +
  grow-light assumption means photoperiod is fully controllable per
  pot/zone — schedule DIFFERENT pots'/species' day windows so at any
  moment across 24h, a roughly stable FRACTION of the tower's total
  leaf-area-weighted photosynthetic capacity is active, flattening the
  net O2/CO2 curve instead of it swinging between a photosynthesis-
  dominated "day" and a respiration-dominated "night" for the whole
  tower at once. A real scheduling/optimization problem — start with a
  simple even-offset staggering (e.g. N staggered light groups, spaced
  24/N hours apart) before anything fancier; validate it actually
  flattens the aggregate curve using phase 19's real day/night
  functions before trusting it.
- **Phase 25 — room/enclosure gas-exchange dynamics (the ventilation
  model).** Dustin, 2026-07-16: "we will also need to account for both
  the standard ventilation input/output for the outside world, and how
  outside vs inside changes over time to become healthier." This is
  the missing piece that makes every tier below concrete instead of a
  vague "keeps CO2 below X" hand-wave: a real TIME-SERIES simulation of
  indoor CO2 ppm and O2 % as a coupled first-order system —
  `d[indoor]/dt = ACH_rate × ([outdoor] − [indoor]) + tower_net_flux(t)
  / enclosure_volume` — same "repeated independent solve" pragmatism
  already used by `water_level_trajectory` (phase 11), not a full CFD
  model. Two real inputs feed it: (1) a stated ventilation/air-exchange
  rate (reuse whichever convention `atmosphere_analysis.
  environment_gas_exchange` already assumes — Air-Changes-per-Hour is
  the standard building-science unit, don't invent a second one), and
  (2) the tower's own net O2/CO2 flux OVER TIME from phase 19+24 (which
  now varies with the light-staggering schedule, not a flat daily
  mean). Outdoor CO2 is a real input (432 ambient, or the 1200
  near-future test case — see Reference values above); outdoor O2 is
  effectively a constant ~20.9% — ventilation's role for O2 is
  replenishing what the tower/occupants consume, not correcting an
  outdoor deficit, worth stating explicitly rather than modeling a
  nonexistent outdoor O2 problem. Output: a real trajectory (not just
  an endpoint) showing how indoor levels move toward — or fail to
  reach — the target bands from Reference values, given a specific
  ventilation rate + tower configuration. This is the actual machinery
  every tier-sizing phase below calls; they differ only in which
  outdoor baseline / target band / failure policy they hand it.

Four deployment scenarios, in ASCENDING order of ambition/risk — build
and validate each before the next. Tiers 0-2 are the SAME core
sizing+dynamics engine called with different (outdoor_co2, target_band,
ventilation_policy) parameters — do not build three separate engines
for what's really one function with different inputs; Tier 3 is the
only one that also needs the extra fault-tolerance layer on top:

- **Phase 26 — tower sizing engine (Tier 0: food-first, safety-capped,
  no active air-quality goal).** Dustin, 2026-07-16: "the third
  scenario of just wanting to grow food and we want to ensure this
  won't draw unsafe amounts of oxygen at night and accidentally create
  a bad indoor air quality, while trying to maximize nutrition needs."
  The SIMPLEST tier and likely the most common real one — no ambition
  to actively improve ambient air quality at all, the ONLY carbon/gas-
  exchange requirement is a SAFETY CAP, not a target. Primary
  objective: maximize nutrient coverage for N people (same nut-5
  coverage machinery as every tier). Uses phase 25's room-dynamics
  model with ventilation rate possibly ZERO (the worst-case closed-
  door/sealed-cabinet overnight window) and checks the resulting
  trajectory never crosses the Reference-values SAFETY bounds (1000ppm
  CO2 / 19.5-23.5% O2 — the tighter "ideal" bands don't apply here,
  there's no active-improvement ambition). If the nutrition-maximizing
  population would breach the safe cap, the answer is an honest
  reported constraint ("cap at N pots, or add M L/min of ventilation")
  — never silently let the nutrition objective win over the safety
  constraint. Does NOT need phase 24's light-staggering (no active
  air-quality target to flatten toward), though staggering still helps
  here as a free byproduct if built.
- **Phase 27 — tower sizing engine (Tier 1: modern health
  optimization, current ambient → pre-industrial indoors).** Dustin,
  2026-07-16: "a new tier between 0 and 1 for trying to just pull
  modern CO2 to pre-industrial indoors." Same nutrition-maximizing
  objective as Tier 0, PLUS an ACTIVE ambition — using phase 25's room-
  dynamics model with TODAY'S real ambient CO2 (432ppm, the current
  real-world baseline, NOT the 1200ppm near-future crisis case) as the
  outdoor input, size the tower so the indoor trajectory is pulled
  toward 280ppm (pre-industrial), O2 held in the 20.8-21.0% ideal band.
  The key distinction from Tier 2 below: this tier's motivation is
  everyday health optimization in the WORLD AS IT IS TODAY, not crisis
  mitigation — it should work, and be worth building/using, whether or
  not the near-future exacerbated-CO2 scenario ever materializes. Uses
  phase 24's light-staggering (has a real active target to flatten
  toward, unlike Tier 0).
- **Phase 28 — tower sizing engine (Tier 2: ventilated, near-future
  crisis mitigation).** Same engine as Tier 1, outdoor CO2 input
  swapped to the 1200ppm near-future "unaddressed/exacerbated" test
  case (Reference values above) — the resulting indoor trajectory
  should still reach 280ppm ideally, or at minimum 950ppm (the safety-
  margin fallback, comfortably under the 1000ppm line), O2 held in the
  20.8-21.0% ideal band. A stated external ventilation rate is the
  safety backstop (system degrading to that ventilated-but-untreated
  baseline on failure, not to zero — this tier explicitly does NOT need
  to be failure-proof, per Dustin's own framing: "would still survive
  from the ventilated air if it breaks down"). Net carbon capture
  across harvest cycles should be slightly negative (net sequestering)
  — surface this as a real computed number per cycle, not asserted.
  Reuses phase 26's safety-cap check as a floor (this tier's ACTIVE
  target is strictly more ambitious than Tier 0's safety-only
  constraint, never less safe).
- **Phase 29 — tower sizing engine (Tier 3: isolated/life-critical,
  Moon/Mars).** Same sizing goal as Tier 2 (280ppm ideal / 950ppm floor
  CO2, 20.8-21.0% O2), but with NO ventilation backstop in phase 25's
  room-dynamics model — failure is not survivable, so this tier needs
  real fault-tolerance modeling: redundancy margins (how much spare
  capacity above the bare-minimum N-person target), fault detection (a
  pot/tower underperforming its phase-21 predicted equation is a real,
  checkable signal — flag it, don't wait for a hard failure), and
  degraded-mode behavior (if one tower/zone fails, do the others cover
  enough of the goal on their own per the phase-30 allocation
  constraint). This tier is explicitly the HARDEST, highest-stakes one
  — do not attempt it before Tiers 0-2 are real and validated; all four
  tiers should share the same sizing+dynamics math with a different
  safety-margin/fault-tolerance policy layered on top, not be separate
  engines.
- **Phase 30 — multi-tower goal allocation.** Layer 4 of the
  architecture above: given a goal exceeding one tower's capacity,
  propose a tower COUNT + per-tower configuration where each tower is
  independently as close to fully meeting the goal as its own capacity
  allows (not a "several towers only work together" degenerate split).
  Applies across all four tiers above. Once the Algae photobioreactor
  tanks section below exists (phases 31-36), this allocation should
  also account for the real algae-area budget from phase 36 — a
  goal's carbon/O2 gap may be closed by more towers, more algae
  surface within existing towers, or both; don't assume plant towers
  alone before that section is built.

## Explicit open questions / judgment calls (flag, don't silently decide)

- "Detectable stress" threshold for phases 17/18 (proposed: combined
  stress factor < 0.95) — a real knob, confirm or adjust.
- Human per-person nutrient reference values / respiration rate (for
  CO2 sizing) — `nutrition/nutrient_basis.py` should already have RDA-
  style references from nut-1; confirm real per-person CO2 output rate
  is sourced from real physiology (a well-known constant, ~pick a
  cited source) not guessed.
- "Slight overproduction" and "slight carbon-negative" need actual
  numeric targets (e.g. 110% of demand? which margin for carbon?) —
  propose defaults, keep them as explicit knobs, never hardcode
  invisibly.
- Grow-light spectrum/intensity assumptions for phase 24 — reuse
  `light_field.py`'s existing `LightSourceDefinition`/
  `LightSpectrumDefinition` (phase 8), don't invent a parallel system.
- Phase 29's specific fault-tolerance margin (how much spare capacity
  counts as "high" fault tolerance) is a real engineering judgment call
  that should probably get Dustin's explicit sign-off before being
  treated as load-bearing for an actual life-support claim, even in
  simulation.
- CO2/O2 target bands themselves are now ANSWERED (see Reference
  values above, Dustin 2026-07-16) — no longer open. The one piece
  still genuinely open: Phase 26's (Tier 0) worst-case no-ventilation
  window duration (proposed 8-10h for a realistic overnight-closed-door
  scenario) — confirm or adjust, keep it an explicit knob on the
  enclosure-check function either way, not hardcoded.
- Phase 25's ventilation-rate convention (ACH vs L/min/person vs
  something else) should match whatever `atmosphere_analysis.
  environment_gas_exchange` already assumes — confirm that during
  implementation rather than picking a second, inconsistent unit.

## Candidate new plant species (for Fable 5's roster expansion)

Only `sweet-basil` and `dwarf-pepper` are fully built today (real
`PlantDefinition`/`PlantPart`/`PlantGrowthModel`/`RootSystemModel`/
`OrganModel`/`StressResponseCurve` rows); `everbearing-strawberry` has
morphology-layer rows only (a real, ready-to-finish stub — use the
exact dwarf-pepper phase-12 recipe). `HOUSEHOLD_NUTRITION_PLAN.md`
Appendix B already names a real candidate roster (dwarf perennial
peppers, tamarillo, everbearing strawberries, pigeon pea, scarlet
runner bean, perennial sorrel/basil/sea parsley, wild rocket, yacon,
perennial chard/daikon, nine-star broccoli, malabar spinach, bamboo,
oyster/shiitake mushrooms, perennial buckwheat, dwarf almond/
hazelnut) and Appendix A names lentils/chia/quinoa (protein), kale/
spinach/swiss chard (vitamin-A/iron), flax (omega-3/vitamin-E) as
canonical nutrient sources not yet seeded — build those FIRST, they're
already identified, not new suggestions.

New candidates worth adding, framed by the phase-22 optimization axes
(carbon-capture-leaning vs nutrition-leaning vs balanced) — these are
PLAUSIBLE HYPOTHESES based on real botanical/nutritional literature,
not asserted classifications; phase 22 still has to DERIVE the actual
label from real simulated numbers once each species is built, same
discipline as everything else in this codebase:

- **Carbon-capture-leaning candidates**: leaf amaranth and water
  spinach (kangkong) — both real, fast-growing, C4-photosynthesis
  crops (C4 plants have a genuinely higher photosynthetic/carbon-
  fixation efficiency than C3 crops like basil under high light — a
  real, citable biological mechanism, not a guess) well suited to a
  wet aquaponic pot. Worth reframing Appendix B's bamboo entry
  (currently listed there for mushroom-substrate use) as ALSO a
  carbon-capture candidate given its own real, well-documented rapid
  biomass accumulation rate.
- **Nutrition-leaning candidates, genuinely new (not in either
  appendix)**: Moringa (Moringa oleifera) — real, frequently-cited
  micronutrient-dense candidate (vitamin A/C, calcium, potassium,
  protein), prunable to a dwarf container shrub, fast leaf regrowth
  after harvest (good repeated-cycle fit). Chaya (Cnidoscolus
  aconitifolius, "tree spinach") — similar profile, less commonly
  known but well documented in tropical home-garden nutrition
  literature. Both worth building specifically because they're
  unusually nutrient-dense per unit harvest, a real lever for the
  nut-5 fulfillment-coverage goal.
- **Balanced/dual-purpose, genuinely new**: sweet potato (Ipomoea
  batatas) — edible leaves (vitamin A/C) AND a tuberous root
  (calorie-dense), real container/hydroponic precedent, two distinct
  harvestable outputs from one planting.

**Honest calibration on the carbon side, matching Dustin's own
skepticism (validated, not talked out of it — see the Algae tanks
section below)**: even the carbon-leaning candidates above are
unlikely to make plant-towers-alone competitive with the Tier 2/3 CO2-
reduction targets. Include them for real completeness/comparison and
because a genuine (if modest) contribution is still worth having, but
don't expect them to carry the carbon-cycling goal — that's what the
new section below is for.

## Algae photobioreactor tanks — closing the carbon-cycling gap (own domain)

Dustin, 2026-07-16: "I think even attempting the carbon cycling may be
a futile effort as towers alone won't likely put a dent in it. Likely
where that will become feasible is later on once we integrate this
system with AquaCulture and Algea Tanks specialized to that
purpose... perhaps we can do individual simulation of algae tanks as
well for that purpose. And incorporate that into here. Trying to go as
far as possible without algae tanks, then incorporate algae tanks with
optimized shapes to try and actually reach the goal... we want to
optimize the shape of the tanks (they can actually even be tubes or
even long and flat) but we want to maximize the amount of algae
actively receiving sunlight and converting CO2 to oxygen per unit time
in those tanks."

This skepticism is well-founded, not just caution — it matches real
bioregenerative life-support research (e.g. algae/cyanobacteria are
the actual workhorse in most real closed-ecosystem CO2/O2 studies,
specifically because higher plants have much lower areal photosynthetic
throughput than an optimized algae culture). Treat this as its OWN
simulation domain, parallel to the plant-pot domain, not a bolt-on.

### Design freedom comes first — the effectiveness model serves the artist, not the other way around

Dustin, same day, in a follow-up specifically about HOW this gets
designed: "we are using 3D printers so one of our goals here might be
to 'beautify' our towers so they are something people actually want in
their home. We will want to optimize for algae tubes and surfaces, but
we will want to do so in a way so that a designer can use those any
way they want when building a Tower, and just calculate the
effectiveness after the fact so that it can be both good looking and
effective. So we want the raw effectiveness per utility, assuming we
'weave different tubes and surfaces of algae into the gaps of the
tower' to ensure co2/oxygen production to capture excess grow light,
while leaving room for artists to design it before it is printed."

This changes the shape of Phase 31 below from "the system picks/
generates the optimal tube-or-panel shape" to: build a PER-UNIT
effectiveness function (CO2/O2 rate per cm² of illuminated surface, or
per cm of tube length at a given local diameter), then let an artist
apply it to ANY freeform geometry they design, and score the result
AFTER the fact — the system never dictates final form, matching this
codebase's own established "Knobs and suggestions" discipline (every
capability = an explicit knob + an evidence-bearing suggestion, never
auto-applied). Two concrete implications: (1) the system should still
be able to compute a real BUDGET/TARGET (e.g. "closing this tier's gap
needs roughly N cm² of algae surface, reasonably well-lit") — a useful
number for an artist to design toward, without dictating shape; (2)
"capture excess grow light" means algae-surface light incidence should
be evaluated from the SAME light-field solve already used for the
plants (phase 8), at the algae surface's own position in the tower —
so algae naturally picks up light the plant canopy didn't absorb,
rather than assuming separate dedicated illumination.

**Real, existing infrastructure this reuses — confirmed by reading the
actual code, not assumed**: `mathshapes/cad_import.py::import_cad()`
is ALREADY almost exactly the "artist authors freeform geometry, system
computes real properties after" pattern this needs — a designer
uploads a mesh (STL/OBJ/PLY/GLTF via `trimesh`, STEP/FCStd via
FreeCAD), and the system creates a `Mesh3DDefinition` (renders) +
`MathShapeDefinition(family='imported-mesh')` + `ImportedCadObject`
(volume/bbox/centroid). This is the real artist-design pathway to
build on — do NOT invent a second, parallel "algae geometry" system.
Three real, small, well-scoped gaps found (not a redesign):
(a) surface area is never computed — the import worker's
`_trimesh_import()` never calls `mesh.area`, even though `trimesh`
provides it directly; needed for the per-unit-area effectiveness
integral. (b) no sub-region tagging — an imported mesh is one opaque
blob today, nothing marks "this tube segment / this panel region is
algae-bearing" vs. structural/decorative; needed so the effectiveness
score only integrates over the algae-bearing parts of an artist's
design, not the whole tower shell. (c) `shape_analysis.py`'s general
`shape_properties()`/`_evaluate_shape()` machinery (grid-sample
volume+surface-area, used for quadric/csg pot geometry) has NO branch
for `imported-mesh` — it silently falls through to "always outside,"
so an imported mesh's properties are a static one-time snapshot from
import, not re-queryable the way a pot's quadric geometry is. Either
add a real mesh inside-test (ray-casting/winding-number — a real
`trimesh` capability already available server-side) or explicitly
accept static-snapshot-per-design-iteration as the model — a real
judgment call, don't silently assume one.

Also confirmed: `AquaponicTowerDefinition` (`tower_basis.py`/
`tower_analysis.py::tower_geometry()`) — the EXISTING tower concept
used by `growth_prediction.py`'s "tower growth" forecasting — is a
simple parametric pot-stack with ZERO connection to CAD-imported/
artist-authored shells. An artist's freeform tower design and the
real pot-position/growth engine are two disconnected systems today;
reconciling them (so an artist's printed shell actually corresponds
to where real pots/tubes/algae surfaces sit) is real integration work,
not something to assume already works.

**What already exists for the biology itself (reuse, don't rebuild)**:
`microalgae/reactor_basis.py` — `AlgaeStrain` (real growth rate, carbon
fraction, N/P stoichiometry, `optimal_density_g_l` — the self-shading/
crash ceiling, today a flat number not a depth model) and
`AlgaeReactorDefinition` (strain, volume_l, `light_intensity` — TODAY
A FLAT 0-1 SCALAR, `co2_supply_mode`/injection rate, nutrient draw
cap, harvest fraction/period). `reactor_analysis.py`'s real entry
points: `_operating_point()`, `sustainability_assessment()`,
`decarbonization_yield()`, `recommend_reactor_for()` — a real,
reusable CO2-fixation + nutrient-coupling + sustainability model, keep
it as the biology layer underneath the new per-unit/geometry work.
`tanks/tank_basis.py::TankDefinition` is chemistry/substrate scoped
only (`volume_gal` scalar, no shape) — not reusable for geometry.

**The core missing piece, unchanged from the original framing**:
`light_intensity` is a flat scalar today, so it can't represent the
dominant real photobioreactor design constraint — light attenuates
with depth into a culture (Beer-Lambert-style, plus density-dependent
self-shading), so only a "photic layer" near an illuminated surface
photosynthesizes net-positive. This is exactly why real photobioreactors
are thin panels or tubes, never bulk tanks — Dustin's instinct is
correct and matches the field. The per-unit effectiveness function
(CO2/O2 rate per cm² surface or per cm tube-length) still needs a real
`photic_depth_cm` per strain (from `optimal_density_g_l` + a real
attenuation coefficient, flagged literature-typical if unmeasured) —
that part of the original plan is unchanged, only WHO applies it to
WHAT shape has changed (artist applies it to their own freeform design,
not the system generating a shape).

`light_field.py`'s low-level math is genuinely reusable here:
`cylinder_incidence_factor(axis, light_dir)` is pure vector geometry
(sin of incidence angle) and works on an artist-drawn algae tube's own
axis exactly as it does a plant bone's — confirmed directly reusable.
`self_shading_factor()`/`per_part_absorption()` are NOT — they're
hard-wired to the plant skeleton's own bone-list structure, so algae-
surface light incidence needs its OWN parallel orchestration reusing
the low-level incidence/spectrum math, not a direct call into the
plant pipeline.

**Sequencing, exactly as Dustin specified — don't skip the ceiling
check**: (1) compute the plants-only maximum achievable CO2 fixation/
O2 production for a given footprint, across the real species roster,
BEFORE considering algae at all; (2) compare that ceiling honestly
against the Tier 0-3 targets from Reference values — report the real
gap, don't assume plants alone close it; (3) only then compute an algae
surface-area BUDGET that would close whatever gap step (2) found, and
hand that budget + the per-unit effectiveness function to the artist-
design/scoring workflow above. This produces a genuinely useful, honest
result either way: if plants alone get surprisingly close, that's real
and worth knowing; if they fall far short (the expected case per
Dustin's own instinct), the budget number is exactly what an artist
needs to design toward.

**New phases** (continuing the numbering above; these plug into the
SAME layer-1→2→3→4 architecture as the plant-pot domain, as their own
parallel column, not a special case):

- **Phase 31 — algae per-unit effectiveness model + CAD-import
  integration.** The per-cm²/per-cm-length CO2/O2 effectiveness
  function (light incidence × local geometry/photic-depth × strain
  rate) described above, PLUS the three real CAD-import gaps: wire
  through real surface area (`mesh.area`), add sub-region tagging (so
  an artist can mark which parts of their imported design are algae-
  bearing), and resolve the imported-mesh re-queryability question
  (real inside-test vs. accepted static-snapshot model — pick one
  explicitly). Selftest against a real, hand-checkable case (confirm a
  thin panel's per-unit effectiveness exceeds a bulk tank's — the core
  physical claim this whole section rests on, prove it numerically
  before trusting anything built on top of it).
- **Phase 32 — parallel light-incidence orchestration for arbitrary
  algae geometry (reusing `cylinder_incidence_factor` + phase 8's
  spectrum math, NOT `self_shading_factor`/`per_part_absorption`
  directly).** Evaluates real light incidence at an algae surface's
  actual position within the tower, off the SAME light-field solve the
  plants use — this is the "capture excess grow light" mechanism:
  algae positioned where plant canopies already cast shadow naturally
  receive less credit, algae in genuinely unused light gets full
  credit, no separate light-budget assumption needed.
- **Phase 33 — individual algae-tank/surface simulation (layer 1,
  mirrors the per-pot plant simulation).** Real CO2 fixation/O2
  production over time for ONE artist-tagged algae region, given its
  real geometry (from phase 31's CAD-import extension), strain, and a
  real light schedule (reuses phase 24's staggering concept — algae
  can be light-cycled too).
- **Phase 34 — derived equations for algae regions (layer 2, mirrors
  phase 21).** Fit/closed-form CO2-throughput-per-unit-area/length as
  a function of local geometry/strain/light-schedule, from phase 33's
  real sweep — the fast function the budget/scoring tools actually
  call, so scoring an artist's design doesn't require re-running the
  detailed sim live.
- **Phase 35 — plants-only ceiling + gap analysis.** The sequencing
  check described above: compute the real plants-only maximum for a
  stated footprint/tier target, report the honest gap (or lack
  thereof) before phase 36.
- **Phase 36 — algae-area budget + post-hoc design scoring tool.**
  Given phase 35's gap, compute the real algae-surface-area budget
  needed to close it. Given an artist's actual CAD-imported design
  (with algae regions tagged per phase 31), score it: total achieved
  CO2/O2 throughput (phase 34's equations integrated over the tagged
  regions' real areas/lengths and phase 32's real light incidence),
  compared against the budget — reported as a real, evidence-bearing
  suggestion ("this design achieves ~62% of the Tier 2 target; ~40cm²
  more algae surface in the unlit gap near the lower-left column would
  close the rest"), never an auto-redesign. This is the tool an artist
  actually iterates against.

## Tower composition + artist-component auto-placement

Dustin, 2026-07-16, the closing piece of this planning pass: "the
tower will be partially pots, soil, water-flow pipes (both nutrient
and normal), load-bearing structures, and algae shapes all
interweaved. The artists should be able to design some load-bearing
designs that should be able to be both artistic and load bearing, as
well as algael designs, which weave together algae pipes and surfaces.
The 3D designs, then can be placed into the tower concept and
auto-allocated a location. Those locations should be somewhere on the
outside of the tower where they would be visible while the internals
of the tower likely do not need 3D designs allocated. Requiring 1 or N
designs in the tower should be an option when trying to do the
simulation/optimization run though."

**A tower's real composition, explicit** (five interwoven systems, not
one blob): plant pots + soil, a NUTRIENT-solution piping circuit, a
SEPARATE plain-water piping circuit (two distinct flow systems, not
one — matches this session's existing `WaterBatchSchedule`/nutrient-
vs-plain-water distinction from the pot-level work), load-bearing
structure, and algae surfaces/tubes. All the geometry work above
(CAD-import reuse, per-unit effectiveness, auto-placement below) has
to account for all five, not just algae.

**Two artist-design CATEGORIES, same underlying workflow, different
evaluation**: (1) load-bearing structural designs — must be BOTH
artistic and genuinely load-bearing, which means these need a real
STRUCTURAL evaluation (does this shape actually hold the intended
load), not just an aesthetic one. This is a different domain than
photosynthesis rate — check `materialsScience/` for an existing FEM/
structural-analysis capability (`FEMModelDefinition` is a real class
name seen in this codebase's own object registry earlier this session)
before building new structural-simulation machinery; unconfirmed
whether it already covers arbitrary CAD-imported shapes under load,
verify before assuming. (2) algae designs (phases 31-36 above) —
evaluated by CO2/O2 effectiveness, not structural load. Both categories
share the SAME design→evaluate→place workflow described below; only
the evaluation function differs by category.

**The real workflow, three steps — don't collapse them**:
1. An artist designs ONE component independently and reusably (via the
   existing CAD-import pathway, phase 31's extension) — a load-bearing
   piece, or an algae piece. This is a STANDALONE design, not drawn
   directly into a specific tower's final shape.
2. The system evaluates that component (structural validity for
   load-bearing designs; CO2/O2 effectiveness for algae designs, phase
   36) — real numbers, reported honestly, same discipline as
   everything else here.
3. The system AUTO-ALLOCATES a real placement location for that
   component within an actual tower's geometry — this is the genuinely
   new piece: a packing/assignment problem, not just scoring.

**Placement constraint, explicit and important**: artist-designed
components belong on the tower's EXTERIOR/visible surface — that's
the whole point of "beautify," no one sees an internal component.
Internal/hidden tower volume (deep structural members, buried piping)
does NOT need artist-designed treatment — plain/utilitarian/generated
geometry is fine there, don't waste design effort on it. This means
auto-placement first needs to identify which regions of a tower's real
geometry actually qualify as "exterior and visible" (a real
geometric query against the tower's own shell — reuses whatever
bounding/surface representation the tower ultimately uses, per the
CAD-import + `AquaponicTowerDefinition` reconciliation flagged in the
algae section above) before assigning any component to a location.
Placement rules differ slightly by category: algae placement is
constrained mainly by light exposure + visibility (loose — many valid
spots); load-bearing placement is ALSO constrained by real structural
need (a decorative-but-load-bearing panel can't just go anywhere it
looks nice, it has to go where the tower's real structure needs load
support) — so load-bearing auto-placement has to consult the real
structural requirement first, then choose among artist designs that
satisfy it, not the other way around.

**The cardinality knob, explicit, don't hardcode**: any simulation/
optimization run over a tower design must accept "how many distinct
component designs to use" as a real input — 1 (a single design tiled/
repeated across every valid exterior slot, a simpler, more uniform
aesthetic) or N (a mix of up to N distinct available designs assigned
across slots, more visual variety). This changes the allocation
problem (single-design tiling vs. a real assignment/mixing problem)
and the resulting effectiveness score, so it has to be a real,
user-facing knob on the run, not an internal default silently chosen.

**New phases** (continuing the numbering above):

- **Phase 37 — load-bearing structural component design + evaluation.**
  Reuses phase 31's CAD-import extension for the design side; the
  evaluation side needs a real structural-validity check — investigate
  `materialsScience/`'s existing FEM capability first (see
  `FEMModelDefinition`) before building new structural-simulation
  machinery. Selftest against a real, hand-checkable case (a shape
  that obviously can't hold its stated load should be flagged, not
  silently accepted).
- **Phase 38 — exterior/visible-surface identification.** A real
  geometric query against a tower's actual shell (once the CAD-import
  / `AquaponicTowerDefinition` reconciliation from the algae section
  exists) that returns which regions are genuinely exterior-and-
  visible vs. internal-and-hidden — the gate every placement decision
  below has to pass through first.
- **Phase 39 — component auto-placement / allocation.** Given phase
  38's valid exterior slots, a set of evaluated artist components
  (phase 31/36 algae, phase 37 structural), and the cardinality knob
  (1 vs N designs), assign real placements — tiling for the 1-design
  case, a real assignment problem for the N-design case (respecting
  algae's light/visibility constraint and load-bearing's real
  structural-need constraint, per the placement rules above). Feeds
  the tower-level aggregate (layer 3) and the multi-tower allocation
  (phase 30) with a real, placed, scoreable design — not just a budget
  number.

This closes the planning pass — execution moves to the other model
from here. Everything above is still PLANNING ONLY; nothing in this
file has been built.

## Discipline reminders for whoever executes this (matches every phase already built this session)

Real seed data, not invented placeholders (Fable 5's new plant species
should follow the exact dwarf-pepper phase-12 recipe). Never a silent
guess or a silently-forced nice result — an honest gap/limitation
reported is always better than a hidden assumption. Live-verify against
the running `prf-backend` (docker cp + restart, or a real image rebuild
for frontend changes — see the `disk-space-audit` memory for a real
gotcha about the frontend's `.dockerignore` and which compose file
actually owns the live containers). Full regression sweep before
declaring a phase done. Document each phase in this file (or a
successor) the same way `AQUAPONICS_POT_SHAPE_PLAN.md` documents its
own phases — verbatim quotes, real numbers, what was found broken and
fixed, what's still open.
