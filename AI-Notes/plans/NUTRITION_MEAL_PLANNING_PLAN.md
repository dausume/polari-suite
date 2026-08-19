# Nutrition meal planning — cooking, thresholds, activity, weight
# trajectory (nmp-0..nmp-9)

**Date:** 2026-08-19 · **Status: PLANNING ONLY (Dustin's brief; plan
written while the fresh-install exercise iterates).** Extends the
BUILT nutrition module (nut-1..4 on dev) and composes with
HOUSEHOLD_NUTRITION_PLAN's unbuilt nut-5/6 (fulfillment sim, Kratky
garden) and the saltwater food forest — this plan does NOT replace
those; it adds the meal/cooking/threshold/activity layer above them.

**Dustin's brief (verbatim intent):** nutrition planning workflows
integrated into cooking and meal plans; per-user profiles of weight,
weight goal, obesity levels, and standard healthy eating (fiber,
protein, calories, carbs, other nutrients) at per-meal / per-day /
per-week / per-month thresholds; track amounts OVER thresholds that
cause problems (e.g. too much fiber → indigestion); track intake
alongside physical activity (and activity intensity) to gauge likely
weight decrease over time; integrate with the existing hydroponics +
food-forestry systems; find public databases/guidelines and
open-source libraries/apps to leverage.

## Ground truth — what exists (reuse, never rebuild)

- `modules/nutrition/` (nut-1..4, on dev): DietaryNutrient (30
  canonical nutrients + plant_availability honesty), NutrientReference
  (NIH DRI adult bands), PersonProfile (weight, goal +
  goal_rate_kg_per_week, metabolism_factor, body_fat_fraction,
  activity PAL), BMR (Mifflin-St Jeor / Katch-McArdle) + TDEE +
  calorie_target with BMR safety floor + unsafe-pace warnings,
  per-period nutrient_needs (day/week/month), HouseholdProfile
  rollups, FoodItem + NutrientContent (per-100g) + harvest analysis
  tied to aqp-4/aqp-8 (REALIZED grow volumes → meal nutrients).
- `modules/aquaponics/` — plant definitions/growth the food side rides.
- Unbuilt-but-planned: nut-5 fulfillment sim (garden plan → nutrient
  coverage, gaps named), nut-6 Kratky garden;
  `AI-Notes/designs/SALTWATER_FOOD_FOREST_SPEC.md` (iodine/sodium/
  chloride/B12 gap-fillers); `agro_forestry` module (skeleton).
- Standing principles that bind every phase: object-coherence,
  knobs-and-suggestions (never auto-apply), honest absence, every
  literature number = a flagged, cited, tunable prior (never false
  precision), per-object displays, file-size decomposition.

## Research verdicts (2026-08-19, license-gated; full reports in the
## session — key facts recorded here as data)

**Data stack (all license-clean):**
| source | role | license |
|---|---|---|
| USDA FoodData Central (Foundation + SR Legacy + FNDDS) | food composition backbone, per-100g; API + bulk CSV/JSON | CC0/public domain |
| NASEM DRI tables + NIH ODS fact sheets | EAR/RDA/AI/**UL** per nutrient × life stage (no official machine format — transcribe ONCE into a versioned, cited seed) | public domain |
| Dietary Guidelines for Americans 2020-2025 | AMDR macro ranges, added-sugar <10%, sat-fat <10%, sodium CDRR 2,300 mg | public domain (carry edition as a column; 2025-2030 exists) |
| 2024 Compendium of Physical Activities | MET values (1,100+ activities) | free incl. commercial, attribution, values unaltered |
| Hall/NIDDK dynamic weight model (Lancet 2011 / Chow-Hall 2008) | weight trajectory from energy balance — equations PUBLISHED; implement from papers | published science (NIH's own implementation needs a license — don't use theirs) |
| USDA Nutrient Retention Factors R6 + Cooking Yields | cooking transforms nutrients — THE recipe-nutrition method | CC0 |
| ~~Open Food Facts~~ | ~~barcodes/packaged foods~~ | OUT (decision 8: base ingredients only — never needed) |

**⛔ BLOCKED (NC/unusable — do not vendor, do not scrape):** FooDB
(CC BY-NC), RecipeNLG + Recipe1M (research-only), Monash FODMAP
food database (proprietary; their published CUTOFF VALUES are usable
facts with citation), WHO guideline PDFs (NC-SA docs; the recommended
VALUES are usable facts), ACSM book. **Tandoor Recipes = AGPL +
Commons Clause — license-blocked** despite being feature-closest;
reimplement concepts independently, never read its source.

**OSS adopt/mine shortlist (licenses repo-verified):**
- ADOPT: **wger** (AGPL-3.0, Python/Django — nutrition plans vs
  targets + workouts + the open exercise DB [data CC-BY-SA,
  attribution + share-alike]; fork-pin as dausume/wger),
  **recipe-scrapers** (MIT, URL→recipe), **ingredient-parser** (MIT,
  free text → amount/unit/food), **openfoodfacts-python** (MIT),
  **FitTrackee** (AGPL, Python/Flask GPS activities — optional later).
- MINE (patterns only): Mealie (AGPL; meal-plan/shopping-list model),
  Grocy (MIT; recursive recipe rollup + stock), OpenNutriTracker
  (GPL-3; cited TDEE/MET formula chain + multi-source food merge),
  PANTS (Apache-2.0; price-per-nutrient).
- **Build-ourselves (no OSS does it)**: per-ingredient recipe-nutrition
  rollup w/ FDC matching + retention/yield factors; DRI life-stage
  targets engine; MET calorie module; the full plan-entry→recipe→
  ingredients→nutrients→vs-thresholds chain. This is where polari is
  genuinely novel — and it lands exactly on our existing seams.

## ✅ DECIDED (Dustin 2026-08-19 — meal-shape rules)

| # | Decision |
|---|---|
| 1 | **Meals are single TEMPLATES with acceptable VARIATIONS** — a MealTemplate carries a base recipe set plus allowed swaps/portion ranges; a variation is valid only inside the template's bounds |
| 2 | **Templates are STRICTLY bounded within healthy meal limits for the AVERAGE person** — authoring/validation REFUSES any template or variation that spikes a nutrient dangerously (per-meal caps derived from the general-population limits: tolerance doses, sodium/added-sugar shares, UL fractions). This is a hard GATE at template level, distinct from the soft warnings on logged intake |
| 3 | **NO special conditions modeled** — no allergies, diabetes, IBS, or medical personalization; all bounds are general-population (DRI life-stage bands are the only person-axis). The pages say so plainly |
| 4 | **Eating patterns (the person's choice)**: 2 meals/day · 3 meals/day · 3 small meals + 2 snacks |
| 5 | **Meal slots**: breakfast, lunch, dinner, brunch, linner, snack — a plan entry = pattern-consistent slot × template × variation |
| 6 | **Activity is ASKED as minutes-of-exercise-per-week**, with a detailed plain-language explanation of what counts (exertion that leaves you out of breath ≈ vigorous; brisk-but-conversational ≈ moderate — the WHO/DGA 150–300 min moderate ≍ 75–150 min vigorous framing). This replaces the abstract PAL guess as the default activity input |
| 7 | **The calorie envelope**: eating pattern + weekly activity minutes → a person's MIN and MAX healthy daily calories (BMR safety floor below, TDEE-surplus cap above) → divided by seeded pattern fractions into a PER-MEAL healthy calorie band; meal choice scales up/down along that band, never outside it |
| 8 | **Meals are built STRICTLY from base ingredients and meats** — whole produce, meats/fish, staples (grains, legumes, oils, dairy-as-ingredient); no packaged/processed products as meal components. Consequence: USDA FDC Foundation + SR Legacy (whole foods, analytic) covers the entire ingredient space; **Open Food Facts drops out of the arc** (Q2 CLOSED — not deferred, not needed), and the ODbL containment concern disappears with it |

## Design spine

ONE chain, every link a treeObject with per-object displays:

  PersonProfile (exists; + obesity class, thresholds, EatingPattern,
                 weekly activity minutes)
    ← MealPlan (day/week/month of MealEntries, pattern-consistent)
      ← MealEntry (slot × MealTemplate × chosen Variation)
        ← MealTemplate (base recipes + allowed variations, HARD-bounded
                        to the average-person per-meal limits at
                        authoring — decision 2)
          ← Recipe (IngredientLines × CookingSteps)
          ← IngredientLine (FoodItem × amount × prep)
            ← FoodItem (exists; + FDC linkage)
              ← harvest (exists: aqp grow → nutrients)
                ← GardenPlan (nut-5) / food forest (spec)

Rollups go UP the chain (ingredient → recipe-per-serving → meal → day
→ week → month); thresholds are evaluated at EVERY period level
(per-meal, per-day, per-week, per-month — Dustin's four); provenance
labels travel with every number (raw vs cooked, measured vs estimated,
which database row, which retention factor).

## Phases

- **nmp-0 — data adoption + fork-pin ledger.** Vendor the license-clean
  seeds as versioned, cited data files: FDC Foundation/SR-Legacy subset
  (only foods we reference — full FDC stays an API lookup), the
  DRI/UL transcription (nutrient × life-stage × {EAR,RDA/AI,UL} +
  jurisdiction column), DGA limits (edition-tagged), Compendium MET
  table (attribution header, values unaltered), Retention Factors R6 +
  yields (CC0 CSVs). Fork-pin adopted libs (dausume/: wger,
  recipe-scrapers, ingredient-parser) per the fork-pin ledger
  discipline; licence pins never >=. (openfoodfacts-python + OFF
  dropped — decision 8.)
- **nmp-1 — profiles grow the threshold layer.** PersonProfile gains:
  obesity_classification (BMI band + waist knob, computed with the
  honest caveats — BMI is a screening prior, body_fat_fraction wins
  when set), **eating_pattern** (2-meal / 3-meal / 3-small+2-snacks,
  decision 4) and **weekly_activity_minutes** captured by the
  plain-language question (decision 6: the form explains moderate vs
  vigorous in felt terms — out-of-breath exertion — and maps minutes
  to the activity factor, replacing the abstract PAL guess), and a
  PersonThresholds object: per-nutrient × per-period
  (meal/day/week/month) min/target/max derived from the DRI/UL + DGA
  seeds by age/sex/life-stage, every value overridable (knob) with the
  derivation shown (suggestion). ULs and CDRR become the default MAX
  side; AMDR bands the macro envelope. **The calorie envelope engine
  (decision 7)**: min/max healthy daily kcal from BMR floor + activity,
  split by seeded pattern fractions (labeled convention priors —
  meal-distribution literature is thin, say so) into per-meal bands.
  General-population ONLY (decision 3) — the single person-axis is
  the DRI life-stage band.
- **nmp-2 — tolerance/adverse-effect table (the honest one).**
  ToleranceThreshold objects seeded from the literature numbers the
  research pinned: rapid-fermenting fiber ~5-10 g/dose GI onset (no
  NASEM UL for fiber — say so), protein ~0.4 g/kg/meal diminishing
  utilization (NOT toxicity — label it), sugar-alcohol laxation
  thresholds (sorbitol/xylitol/erythritol per-kg), FODMAP per-serving
  cutoffs (Monash published values, cited), sodium CDRR, vitamin ULs.
  Each row: nutrient, period, threshold, symptom, citation, confidence.
  Evaluation produces WARNINGS with the symptom named ("this day's
  inulin-type fiber exceeds the 10 g dose literature associates with
  bloating"), never silent clamps.
- **nmp-3 — recipes + cooking.** Recipe / IngredientLine /
  CookingStep objects; per-ingredient nutrition rollup: FoodItem→FDC
  match (ingredient-parser for free text; explicit links for our
  grown foods), amount × per-100g × YIELD factor × RETENTION factor
  (per nutrient × cooking method — the R6 tables), summed to
  per-serving RecipeNutrition with a raw-vs-cooked provenance label.
  recipe-scrapers ingestion verb for URL import. This is the
  build-ourselves engine nothing OSS provides.
- **nmp-4 — meal templates + plans.** **MealTemplate** (decisions 1+2):
  base recipe set + VariationDefinitions (allowed swaps, portion
  ranges); the authoring VALIDATOR computes every variation's rollup
  and REFUSES the template if any nutrient exceeds the average-person
  per-meal caps (tolerance doses, per-meal shares of sodium/added
  sugar/UL) — hard gate, named reasons. Base-ingredients rule
  (decision 8) enforced here: template lines reference whole
  FoodItems, not products. MealPlanDefinition (person or household ×
  date range) + MealEntry (pattern-consistent slot — breakfast/lunch/
  dinner/brunch/linner/snack — × template × chosen variation, scaled
  within the slot's calorie band from nmp-1). Rollups per
  meal/day/week/month vs PersonThresholds + ToleranceThresholds:
  coverage (under-target), excess (over-max, symptom-named), AMDR
  balance. Suggestions propose variations/portions
  (knobs-and-suggestions: never auto-edit a plan). Household mode
  splits a shared meal across members' profiles by serving fractions.
- **nmp-5 — activity + intensity.** ActivityDefinition seeded from the
  Compendium (MET, category, intensity band light/moderate/vigorous by
  MET cutoffs 3/6) + ActivityLog (person, activity, duration,
  optional perceived-intensity knob scaling MET ±). kcal = MET × kg ×
  hours (cited); TDEE integration: logged activity replaces the PAL
  guess when logs exist (labeled which mode is active). wger exercise
  DB adopted (CC-BY-SA attribution) for strength-training vocabulary;
  FitTrackee integration = a later engine, not this arc.
- **nmp-6 — weight trajectory (the Hall model).** Implement the
  published Hall/Chow dynamic energy-balance equations from the papers
  (fat/lean partitioning, adaptive thermogenesis, energy density) as
  `weight_trajectory.py`: input = current profile + planned intake
  (nmp-4 rollups) + activity (nmp-5); output = projected weight curve
  over weeks/months with uncertainty band, vs the person's
  goal_rate_kg_per_week; the 3500-kcal/lb rule available ONLY as a
  labeled "naive estimate" toggle (documented as ~2× over-predicting).
  Progress tracking: WeightObservation log; observed-vs-projected
  drift shown, model priors tunable knobs.
- **nmp-7 — the garden/forest loop closes.** Recipes' IngredientLines
  reference the SAME FoodItems the harvest analyzer fills from aqp-8
  grows — so a meal plan can be priced in GARDEN terms: which
  plan-week is coverable from the hydroponic garden (nut-5's coverage
  sim consumes MealPlan demand instead of raw household needs), what
  the saltwater food forest uniquely supplies (iodine/sodium/B12 rows
  point at the spec), what must be bought (supplychain module seam).
  This phase BUILDS nut-5 (fulfillment) in its meal-plan-aware form —
  the headline HOUSEHOLD_NUTRITION deliverable, upgraded.
- **nmp-8 — pages + displays.** /nutrition app pages per the
  per-object display rule: person profile page (thresholds tab,
  trajectory tab), meal-plan calendar (day/week rollup bars vs bands,
  warning chips naming symptoms), recipe page (per-serving label,
  provenance), activity log. Exhibit-variant friendly (results
  displayable without engines — pub-2 alignment).
- **nmp-9 — selftests + TESTING_OWED.** Selftest per phase (module
  convention); cross-checks: a seeded day-plan's rollup vs
  hand-computed values, Hall-model unit tests against published
  worked examples, threshold warnings fire at documented doses.

## Boundaries

- Ours: everything above; all seeds cited + versioned.
- Dustin's: profile data entry (his own), goal confirmation, the Q1-Q4
  answers below, GUI passes.
- NOT this arc: FitTrackee/wger as running services (engine-pattern
  candidates later), barcode scanning UI, the saltwater tank build
  itself, medical claims of any kind (thresholds are literature
  priors with citations, not medical advice — the pages say so).

## Open questions (Dustin)

1. **wger relationship**: mine its models only (default), or also run
   it as an adopted engine alongside polari (AGPL service, own UI)?
~~2. Open Food Facts~~ — **CLOSED by decision 8**: base ingredients
   only → FDC covers everything; OFF out of the arc entirely.
3. **Recipe ingestion**: URL import (recipe-scrapers) in nmp-3, or
   hand-authored recipes first and import later? (Imported recipes
   would still have to pass the base-ingredients rule + template gate.)
4. **Trajectory horizon**: default projection window (12 weeks?) and
   whether household members see each other's trajectories
   (privacy default: own-profile only?).
5. **Pattern fractions**: proposed per-meal calorie splits — 3-meal
   ≈ 25/35/40%, 2-meal ≈ 45/55%, 3-small+2-snacks ≈ 25/25/30 + 10/10
   — labeled convention priors, tunable. Confirm or adjust.

## Grounding index

- modules/nutrition/ (nut-1..4 code, on dev)
- AI-Notes/plans/HOUSEHOLD_NUTRITION_PLAN.md (nut-5/6 phases this
  plan upgrades)
- AI-Notes/designs/SALTWATER_FOOD_FOREST_SPEC.md
- Research reports (this session, 2026-08-19): data-sources report +
  OSS survey — key URLs: fdc.nal.usda.gov (API + bulk),
  ods.od.nih.gov/factsheets (ULs), dietaryguidelines.gov,
  pacompendium.com, Chow & Hall 2008 PLoS CB + Hall 2011 Lancet,
  agdatacommons.nal.usda.gov (Retention Factors R6 CC0),
  github: wger-project/wger, hhursev/recipe-scrapers,
  strangetom/ingredient-parser, openfoodfacts/openfoodfacts-python,
  SamR1/FitTrackee; blocked: TandoorRecipes (Commons Clause), FooDB
  (NC), RecipeNLG/Recipe1M (research-only), Monash DB (proprietary).
- Fork-pin ledger discipline: ai-tool-linkages arc (ai-9).
