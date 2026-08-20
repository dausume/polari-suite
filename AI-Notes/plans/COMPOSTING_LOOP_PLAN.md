# Composting loop — waste planned WITH the food (cmp-0..cmp-7)

**Date:** 2026-08-20 · **Status: PLAN RATIFIED same day — Dustin
answered all 4 open questions (decisions 7-9 below record them);
ready for cmp-0's research pass on a build go-ahead.**

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
|  per-species scrap guidance: poultry extension + veterinary toxic-food lists for cats/dogs (ASPCA etc.) | per-species acceptance/prohibition lists | citable; label confidence |
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

## ✅ DECIDED (Dustin 2026-08-20 — the Q1-Q4 answers)

7. **Own DEB**: composting is its OWN PolariAppDefinition + app
   (`pol apps shell composting`), not a nutrition-planner tab — its
   pages link across, but it ships and installs independently.
8. **Four feed species: pigs, chickens, cats, dogs** (pets are feed
   recipients too — household scraps as pet food, with the
   veterinary toxic-food lists transcribed per species: allium/
   grapes/chocolate/xylitol for dogs, allium/raw-dough for cats,
   etc., cited). **Streams may be MIXED with other feedstock** to
   compose an acceptable ration — mixing solves NUTRITION/ration
   balancing; the router states honestly where a legality rule
   cannot be mixed away (the swine meat-contact rule requires
   licensed COOKING or exclusion — dilution does not legalize it).
9. **Manual logging is an OPTIONAL, advised knob**: the app
   explains what logging adds (drift correction, real-vs-derived
   waste), users choose their methods — or none. **Destination is
   also the user's choice**: own livestock/pets, OR local sale/
   give-away to nearby people and farms (a FeedAllocation
   destination kind riding the supplychain module seam) — the
   router proposes both where streams qualify.

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
- **cmp-3 — the router**: stream → {system | feed | discard}
  proposals with reasons (C:N balance suggestions with greens/
  browns arithmetic; capacity honesty; the legality hard gate);
  FeedSpeciesDefinition rows for the FOUR species (pigs, chickens,
  cats, dogs) with cited acceptance/prohibition lists; RATION
  MIXING proposals (decision 8) that balance a stream against
  other feedstock — never presented as legalizing what the law
  gates.
- **cmp-4 — outputs + the return path**: CompostBatch / SoilBatch /
  CompostTeaBatch with prior profiles; FeedAllocation rows with the
  decision-9 destination kinds (own-livestock | own-pet |
  local-sale via the supplychain seam); the aqp-7 coupling for
  teas; batch maturity timelines.
- **cmp-5 — integration**: meal-plan pages gain the waste panel;
  the prep scheduler emits waste actions ("trimmings → bokashi
  bucket at session 1"); nmp-7 coverage's labeled compost term.
- **cmp-6 — pages** (pure-data displays, the nmp-8 pattern) + the
  OWN composting PolariAppDefinition (decision 7) with cross-links
  to nutrition-planner's plan pages; the advisory content for
  decision 9 (what logging adds; own-vs-nearby destinations).
- **cmp-7 — selftests** per phase (the module convention).

## Open questions — ALL ANSWERED (Dustin 2026-08-20)

1. ✅ Own deb (decision 7).
2. ✅ Pigs, chickens, cats, dogs — just those four; mixing with
   other feedstock allowed for ration composition (decision 8).
3. ✅ New thin `composting/` module importing the nutrition +
   aquaponics seams.
4. ✅ Manual logging optional + advised; destination choice
   own-vs-nearby included (decision 9).

## Grounding index

- modules/aquaponics/vermicompost*.py (aqp-7, the return path)
- modules/nutrition/ (nmp arc, dev-nmp-1 — the waste source)
- AI-Notes/plans/NUTRITION_MEAL_PLANNING_PLAN.md (pattern + gates)
- AI-Notes/plans/HOUSEHOLD_NUTRITION_PLAN.md §nut-6 (Kratky soil
  seam)
