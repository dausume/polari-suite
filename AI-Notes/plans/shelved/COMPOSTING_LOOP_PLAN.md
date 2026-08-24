# Composting loop — waste planned WITH the food (cmp-0..cmp-7)

**Date:** 2026-08-20 · **Status: ⏸ SHELVED 2026-08-20 (Dustin, same
day) — plan RATIFIED (all 4 Qs answered, decisions 7-9) AND cmp-0
research pass DONE (all five sources GREEN; verdicts below; full
reports in AI-Notes/evaluations/COMPOSTING_DATA_LICENSE_GATE.md).
NOTHING BUILT. Revival = a Dustin go-ahead; the build starts at the
cmp-0 vendoring, straight from the recorded verdicts — no re-research
needed unless sources drift.**

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

## Research verdicts (2026-08-20, license-gated; full per-source
## reports in AI-Notes/evaluations/COMPOSTING_DATA_LICENSE_GATE.md)

**All five sources GREEN:**
| source | role | verdict |
|---|---|---|
| USDA SR28 refuse factors (`sr28asc.zip` from ARS, FOOD_DES fields Refuse/Ref_desc) | waste fraction per pantry food | US-gov public domain / CC0-per-FDC. 🔑 **FDC dropped refuse entirely** — not in the SR Legacy bulk CSV, not in the API; SR28 at ARS is the ONLY machine-readable source. Join via FDC `sr_legacy_food.csv` (fdc_id↔NDB), normalizing NDB leading zeros. Values verified by download (banana 36 skin, broccoli 39, egg 12 shell, orange 27, avocado 26; boneless fish + staples 0) |
| USDA **NRCS NEH Part 637 Ch. 2 Table 2A-1** (C:N + moisture per feedstock) | compost balancing (greens/browns) | public domain (17 USC §105) and carries the SAME numbers as NRAES-54 App. A — cite NRCS as primary, NRAES-54 as the underlying compilation. Targets: C:N 25–30:1 preferred (20–40 reasonable), moisture 50–60% (40–65). Eggshells have NO primary-source row → model as mineral amendment, not a C:N feedstock |
| Swine Health Protection Act + 9 CFR 166 (+ 21 CFR 1.227/507.12 for off-premises) | livestock-feed LEGALITY | public law, transcribed. 🔑 corrections: the household exemption is INSIDE the 166.1 *definition of garbage* (not 166.15), three prongs (own household waste + fed directly + same premises); meat-ASSOCIATED veg waste IS garbage; **the exemption dies off-premises** — the decision-9 "nearby farm" destination is the licensed-cooking pathway or BLOCK; ~23-25 states ban garbage feeding outright (state check = per-user fail-closed gate). Chickens: no federal bar, state gate only. Pets: no legality layer — toxicity only |
| per-species lists (UF/IFAS + OSU ext. for chickens; ASPCA + Merck for dogs/cats; Purdue/Iowa State + Merck for pigs) | acceptance/prohibition rows | citable facts (Feist); no data-reuse prohibitions found; never copy prose/table layouts. Grape/raisin = tartaric acid (Merck-confirmed); allium worse for cats; chicken-citrus = genuine source disagreement → `caution`; pig avocado/chocolate rows UNVERIFIED (advocacy-tier only) |
| compost-tea priors (NOSB 2004 Task Force report + S&M 2002 + Duffy 2004 + Ingram&Millner 2007 + UH/SARE manual) | tea parameters + safety | NOSB 2004 = public domain, full text retrieved (potable water; additive tea needs E. coli ≤126 CFU/100mL testing else 90/120-day PHI; no sprouts; extract <1h ≠ tea). ACT 12–24h, 1:10–1:20 v/v; DO ≥6 mg/L is practitioner-tier only. 🔑 molasses >0.2% regrows Salmonella/E. coli; regrowth rides ADDITIVES not aeration (ACT can be WORSE). NPK priors wide (N 58–315 mg/L across teas). Other containers © (UH manual, T&F) — values-only, cite DOIs |

⛔ Same gates as nmp: nothing NC/proprietary vendored; values-as-
facts cited where the container is blocked. Confirmed NC blockers
found this pass: FAO/INFOODS edible-portion data (CC BY-NC-SA) —
never vendor.

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
  rule transcription, tea parameter priors. ✅ Research pass DONE
  2026-08-20 (verdicts above; the vendoring itself = the build).
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
