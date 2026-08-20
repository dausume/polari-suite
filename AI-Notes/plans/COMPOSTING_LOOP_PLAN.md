# Composting loop — waste planned WITH the food (cmp-0..cmp-7)

**Date:** 2026-08-20 · **Status: PLANNING ONLY (Dustin's brief,
same-day as the nmp build; written for his refinement — the nmp
pattern: decisions ratify, then a go-ahead builds).**

**Dustin's brief (verbatim intent):** build a composting app for
making new soil and compost-teas that feed back into hydroponics;
COMBINE food planning with composting so the waste parts we do not
eat (from plants/fruits we use) are planned AT THE SAME TIME as the
meals, routed through different composting systems into growing new
food — or as livestock feed for various livestock.

## The core idea — waste is DERIVED from the meal plan

The nmp arc already knows, per plan-week: every IngredientLine's
food, grams, and prep. The waste plan is the same rollup read from
the other side: inedible fractions + prep trimmings + plate-side
scraps become WasteStreams the moment the meal plan exists — you
plan the handling when you plan the food, not after.

## Ground truth — what exists (reuse, never rebuild)

- **aqp-7 vermicompost (BUILT)**: CompostBinDefinition +
  VermicompostProfile (casting release per NutrientSpecies) +
  CompostLoopDefinition coupling a bin into a pot system's water
  (direct/periodic modes; kinetics box-model; literature-prior
  discipline). This IS the hydroponic return path — the composting
  app FEEDS it, never re-implements it.
- **nmp-0..11 (BUILT, dev-nmp-1)**: meal plans + rollups (the waste
  source), FDC pantry with per-food identity, the garden loop
  (nmp-7 coverage — compost-grown supply eventually joins it), the
  prep scheduler (trimmings happen AT prep sessions — the waste
  timeline rides nmp-10's sessions).
- **aqp-4 PlantPart**: edible vs non-edible parts — harvest waste =
  the parts harvest_analysis does NOT count.
- Standing principles bind: knobs-and-suggestions, honest absence,
  cited priors, per-object displays, seed-upsert, CSV-not-JSON
  vendoring (the `*.json` gitignore), fork-pin/license gates.

## Data sources to license-gate in cmp-0 (research pass owed)

| candidate | role | expected status |
|---|---|---|
| USDA FDC/SR refuse factors (percent inedible per food) | waste fraction per pantry food | CC0 — verify column availability per dataset |
| Cornell WMI / extension C:N + moisture tables for feedstocks | compost balancing (greens/browns) | citable published values — verify per table |
| USDA/FDA + Swine Health Protection Act (9 CFR 166) | livestock-feed LEGALITY (esp. food scraps to swine; meat-contact rules) | public law — transcribe the RULES, cited |
| state/extension poultry + rabbit scrap guidance | per-species acceptance/prohibition lists | citable; label confidence |
| compost-tea brewing literature (aeration, time, ratios) | tea parameter priors | published papers; label ranges honestly |

⛔ Same gates as nmp: nothing NC/proprietary vendored; values-as-
facts cited where the container is blocked.

## Proposed decisions (Dustin ratifies/edits — numbered like nmp's)

1. **Waste is derived, never logged first**: WasteStreams compute
   from the meal plan + prep sessions + harvests; manual logging is
   a correction knob on top, not the entry path.
2. **Routing is suggested, a human applies**: the router PROPOSES
   stream → system/livestock/discard with named reasons; legality
   rules (swine/meat) are the ONE hard gate (law, not preference).
3. **Livestock feed legality transcribed, cited, fail-closed**: a
   stream with any meat/animal contact never routes to swine unless
   the cooked-per-law flag is explicitly set; unknown streams route
   to compost, not feed.
4. **Systems are data**: vermicompost (adopts aqp-7), hot/thermal
   pile, bokashi, leaf mold, compost-tea brewer — each a
   CompostSystemDefinition with feedstock acceptance, capacity,
   cycle time, output kind; user-authorable (decision-13 spirit).
5. **Outputs carry prior-until-measured nutrient profiles**: soil
   batches + teas get literature-range profiles flagged is_prior;
   measurements replace priors, never silently.
6. **The loop closes through existing seams**: teas/castings →
   aqp-7 enrichment; soil batches → growing media (nut-6 Kratky /
   future soil beds); compost-supplied nutrients eventually appear
   in nmp-7 coverage as a LABELED supply term (off by default until
   measured).

## Phases

- **cmp-0 — data adoption**: refuse-fraction table for the 49-food
  pantry (vendored CSV, cited; labeled estimate where FDC lacks the
  factor), feedstock C:N/moisture table, the livestock legality
  rule transcription, tea parameter priors. Research pass first
  (license verdicts recorded like nmp-0's).
- **cmp-1 — waste derivation**: WasteStream objects computed from a
  MealPlan (inedible fraction × line grams + prep trimmings) + the
  harvest side (non-edible PlantParts mass); `waste_rollup(plan)`
  companion to plan_rollup — the "planned at the same time" seam;
  streams timestamped to nmp-10 prep sessions.
- **cmp-2 — systems as data**: CompostSystemDefinition (+ adopts
  the aqp-7 bin as the vermicompost kind), HouseholdCompostSetup
  (which systems this household runs, capacities).
- **cmp-3 — the router**: stream → {system | livestock | discard}
  proposals with reasons (C:N balance suggestions with greens/
  browns arithmetic; capacity honesty; the legality hard gate);
  LivestockDefinition + per-species acceptance rows (cited).
- **cmp-4 — outputs + the return path**: CompostBatch / SoilBatch /
  CompostTeaBatch with prior profiles; FeedAllocation rows; the
  aqp-7 coupling for teas; batch maturity timelines.
- **cmp-5 — integration**: meal-plan pages gain the waste panel;
  the prep scheduler emits waste actions ("trimmings → bokashi
  bucket at session 1"); nmp-7 coverage's labeled compost term.
- **cmp-6 — pages** (pure-data displays, the nmp-8 pattern) + the
  composting app front doors joining nutrition-planner (or its own
  PolariAppDefinition — Dustin's call, Q1 below).
- **cmp-7 — selftests** per phase (the module convention).

## Open questions (Dustin)

1. **App shape**: composting inside the nutrition-planner app, or
   its own `composting` PolariAppDefinition (own deb)? (Proposal:
   pages join nutrition-planner now; split later if it grows.)
2. **Which livestock first**: chickens/pigs/goats/rabbits/worms —
   which do you actually plan for? (Drives which legality tables
   get transcribed first.)
3. **Module home**: new `composting/` module vs growing
   `nutrition/` + `aquaponics/`? (Proposal: new module, thin,
   importing both seams — file-size-decomposition rule.)
4. **Manual waste logging**: worth a correction knob in cmp-1, or
   derived-only until real use shows drift?

## Grounding index

- modules/aquaponics/vermicompost*.py (aqp-7, the return path)
- modules/nutrition/ (nmp arc, dev-nmp-1 — the waste source)
- AI-Notes/plans/NUTRITION_MEAL_PLANNING_PLAN.md (pattern + gates)
- AI-Notes/plans/HOUSEHOLD_NUTRITION_PLAN.md §nut-6 (Kratky soil
  seam)
