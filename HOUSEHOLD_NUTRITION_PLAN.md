# Household Nutrition → Hydroponic Fulfillment Plan

**Written 2026-07-09 as a durable, GPT-4-executable handoff.** The goal
(Dustin): build the capability to (1) analyze any plant's HARVEST in
terms of the nutrients it yields for meals, (2) profile a PERSON (body
weight, weight-loss goal, per-day/week/month nutrient needs, accounting
for metabolism and factors the user may not name), (3) roll people up
into a HOUSEHOLD profile, and (4) SIMULATE what it takes to fulfill all
of a household's nutritional needs from a hydroponic system — naming the
gaps a hydroponic garden cannot cover (iodine / sodium / chloride, B12)
and pointing at the saltwater food forest that supplies them.

**Priority order (Dustin's directive):** nutrition goal FIRST, then the
freshwater/hydroponic garden build, then the saltwater food forest
(`SALTWATER_FOOD_FOREST_SPEC.md`). Do phases one at a time, branch per
phase (`dev-nut-1-vocab`, …), selftest green before moving on.

This extends the existing **aquaponics module**
(`polari-rf-node/polari-framework/aquaponics/`) — reuse its objects and
conventions, do NOT rebuild them. Read the "What already exists" section
before touching anything.

---

## 0. What already exists (reuse, don't rebuild)

The aquaponics module (aqp-1..8, all built + live-verified 2026-07-09;
see `AQUAPONICS_PHASE2_PLAN.md` + the `aquaponics-module` memory) gives
you the foundation this plan builds on:

| Piece | Reuse for |
|---|---|
| **aqp-4** `PlantDefinition` + `PlantPart` (part, `mature_volume_cm3`, `dry_density_g_cm3`, `dry_matter_fraction`, `permanent_fraction`, `fate`, `composition_json` {element: mass-fraction}, `flux_json`) | The plant + per-part model the HARVEST analysis attaches to. NOTE: `composition_json` is ELEMENTAL (C/N/P/K… for carbon capture) — human nutrition needs a RICHER food-nutrition layer (vitamins + bioavailable minerals per 100 g edible). nut-2 adds that, keyed to the part, not replacing the elemental composition. |
| **aqp-8** `PlantGrowthModel` + `plant_growth.grow()` → realized per-part volumes + condition (healthy/failed) | The REALIZED harvest mass: edible-part volume × density × dry-matter → grams of food produced per plant per cycle. |
| **aqp-2** `NutrientSpecies` vocabulary, `NutrientProfile`, `WaterDefinition` (`flow_rate_l_per_hr`) | The hydroponic nutrient-water source model; the garden's reservoir feeds Kratky pots. |
| **aqp-6** `PotSystemDefinition` + scoring bridge (objectRef into `*_result_json`, `beeswax@L1` idiom) | The pattern for making a household+garden config RANKABLE (coverage score). |
| **aqp-7** `CompostLoopDefinition` enrichment | An optional nutrient-water source feeding the garden reservoir. |
| **scoring** `ScoreTerm/ScoreSubject/ContextualizedValue/ScoreConcept` | Coverage-per-nutrient as a scorable, rankable concept. |

### Module conventions (ALL new phases MUST follow — same as aqp)
- Classes are `treeObject`s: `from objectTreeDecorators import
  treeObject, treeObjectInit`; `@treeObjectInit` on `__init__`; every
  field a typed kwarg with a default; `manager=None` LAST; body is pure
  `self.x = x`. The `__init__` signature IS the DB schema. Cross-class
  refs are JSON-string fields BY NAME, resolved from
  `manager.objectTables['ClassName']`.
- Analysis/math files take `manager` duck-typed so selftests run
  stdlib-only with `SimpleNamespace` rows + a fake manager.
- API classes `class XAPI(treeObject)` with `@treeObjectInit def
  __init__(self, polServer)`; register routes; falcon POST bodies read
  `json.load(request.bounded_stream)`. Newly-created rows via the API
  need explicit `manager.db.saveInstanceInDB(row)`.
- Seeds: `SEED_*` lists of plain dicts, idempotent-by-name.
- polariServer wiring: import classes+seeds near the aquaponics imports
  (~lines 158–195); add to `defClassList` (~line 730, aquaponics block);
  instantiate the API next to `AquaponicsCompostAPI` (~line 636); add
  `(name, cls, SEED_*)` tuples to `seed_pairs` in `_seedSimSpace3D`
  (~lines 1620–1640), dependency order (referenced rows first).
- Selftests run in-container: `docker exec prf-backend python3 -m
  aquaponics.selftest_<name>`. Standing principles: object-coherence,
  knobs-and-suggestions (every tunable = knob + evidence-bearing
  suggestion, NEVER auto-apply), file-size-decomposition, honest-absence
  (missing data = a NAMED refusal carrying the knob), labels-travel-
  with-numbers.
- Deploy: `export LOCAL_IP=192.168.0.210` before ANY compose on
  docker-compose.staging-nip.yml; backend serves :3000 only after cold
  seed (minutes). Branch per phase; commit locally (nothing pushed —
  repos PUBLIC).

### Where these files live
New submodule folder alongside `aquaponics/`:
`polari-rf-node/polari-framework/nutrition/` (own module — nutrition is
a distinct concern from the pot/tank physics; file-size-decomposition).
It DEPENDS on `aquaponics` (imports PlantDefinition/PlantPart/growth).

---

## PHASE nut-1 — Nutrient vocabulary + RDA reference data (do first)

### Goal
The shared vocabulary of the ~30 nutrients a household must hit, each a
tunable row carrying its unit and its Recommended Daily Allowance basis
(so per-person needs in nut-3 scale from a single sourced table, not
magic numbers).

### Objects (`nutrition/nutrient_basis.py`)
- **DietaryNutrient** (treeObject): `name` (kebab, 'vitamin-c'),
  `display_name`, `category` (macro / vitamin / mineral / electrolyte /
  trace / fatty-acid), `unit` ('mg'/'µg'/'g'/'kcal'/'IU'), `role`
  (free-text — "immunity & collagen"), `plant_availability`
  ('common'/'hard'/'none' — flags B12/iodine/sodium/chloride as NOT
  plant-native, honest-absence), `notes`.
- **NutrientReference** (treeObject): the RDA/AI basis, keyed to a
  DietaryNutrient BY NAME + a demographic band: `nutrient_name`,
  `sex` ('any'/'male'/'female'), `age_min`/`age_max`, `rda_per_day`,
  `upper_limit_per_day` (toxicity ceiling), `source` ('NIH DRI 2020'),
  `is_prior` (flag literature/estimate). Multiple rows per nutrient
  cover the demographic bands.

### Seed (`nutrition/nutrient_seed.py`)
Seed ALL nutrients from Dustin's list (the canonical set — do not drop
any): calories(kcal), carbohydrate, protein, healthy-fat, vitamin-a,
vitamin-b1/b2/b3/b5/b6/b7/b9/b12, vitamin-c, vitamin-d, vitamin-e,
vitamin-k, iron, calcium, magnesium, omega-3, potassium, sodium,
chloride, zinc, selenium, copper, manganese, iodine, chromium,
molybdenum, boron, silicon. `plant_availability='none'` for
vitamin-b12/iodine/sodium/chloride (the saltwater/fermentation gaps).
Seed NutrientReference rows for the standard adult bands (male/female
19–50, 51+) from NIH DRI — flag `is_prior=True` where a value is an AI
not an RDA. Keep the numbers in ONE place; nut-3 reads them.

### Selftest / acceptance
`selftest_nutrient.py`: vocabulary complete (all ~30 present), every
nutrient has ≥1 reference row, plant-unavailable ones flagged, units
consistent. Green.

---

## PHASE nut-2 — Plant harvest → nutrient yield (the harvest analyzer)

### Goal
Given a plant + which parts are EDIBLE + a realized grow run (aqp-8),
answer: **how many grams of each nutrient does one harvest of this plant
yield?** This is the food-side of the ledger.

### Objects (`nutrition/food_basis.py`)
- **FoodItem** (treeObject): an edible harvest product. `name`
  ('kale-leaf'), `plant_name` (→ aqp-4 PlantDefinition), `edible_parts_json`
  (list of PlantPart names that are eaten), `preparation` ('raw'/
  'cooked'/'flour'/'fermented' — fermentation is how B12 appears,
  honest), `moisture_loss_fraction` (fresh→prepared), `notes`.
- **NutrientContent** (treeObject): the food-nutrition composition,
  RICHER than aqp-4's elemental composition. `food_name`,
  `nutrient_name` (→ DietaryNutrient), `amount_per_100g_edible`, `unit`,
  `is_prior` (USDA FoodData Central value vs estimate). One row per
  (food, nutrient) — the transparent, tunable food-nutrition table.

### Analysis (`nutrition/harvest_analysis.py`, duck-typed manager)
- `harvest_mass_g(manager, food_name, grow_result=None)` — realized
  edible mass: for each edible part, volume (from aqp-8 grow_result if
  given, else aqp-4 `mature_volume_cm3`) × `dry_density_g_cm3` ×
  (fresh/dry factor), minus `moisture_loss_fraction`. Returns grams +
  which parts + whether it used realized-vs-mature volume (label travels).
- `harvest_nutrients(manager, food_name, grow_result=None)` — mass ×
  NutrientContent/100g → grams/µg of each nutrient per harvest, with
  the prior flags carried. Refuses honestly if NutrientContent rows are
  missing, naming the knob.
- `food_catalog(manager)` — every FoodItem with its headline nutrients
  (the "what does this plant give me" browse).

### Seed the plant→nutrient SOURCE MAP (Dustin's list — canonical)
`nutrition/food_seed.py`: FoodItems + NutrientContent for the identified
core sources (see **Appendix A** below — reproduce it faithfully;
map each plant to the nutrients Dustin assigned it). Values are
literature/USDA priors, flagged.

### Acceptance
`selftest_harvest.py`: harvest mass scales with realized volume;
nutrient yield scales with mass; a plant rich in a nutrient (kale →
vitamin-a/vitamin-k/iron/calcium) reports it; missing content refuses
with the knob named. Green. Live: `GET /api/nutrition/foods/{name}/
nutrients` returns per-harvest yield.

---

## PHASE nut-3 — Person profiler (BMR + goals + per-period needs)

### Goal (Dustin, verbatim intent)
Profile a person by body weight + weight-loss goals → nutrients needed
per day / week / month, **accounting for metabolism rate and other
factors the user may not know** (surface those as knobs, don't hide
them).

### Object (`nutrition/person_basis.py`)
- **PersonProfile** (treeObject): `name`, `display_name`, `sex`,
  `age_years`, `weight_kg`, `height_cm`, `activity_level`
  ('sedentary'/'light'/'moderate'/'active'/'very-active' → PAL factor),
  `goal` ('maintain'/'lose'/'gain'), `goal_rate_kg_per_week` (weight-
  loss pace → calorie deficit), and the FACTORS-you-may-not-know as
  explicit tunable knobs with honest defaults: `metabolism_factor`
  (1.0 default; thyroid/genetics multiplier on BMR — flagged as a knob
  the user can tune when they know it), `body_fat_fraction` (optional →
  enables the Katch-McArdle BMR variant), `pregnant_or_lactating`
  (raises several nutrient needs), `notes`.

### Analysis (`nutrition/person_analysis.py`, duck-typed, stdlib-only)
- `bmr(person)` — Mifflin-St Jeor by default (needs weight/height/age/
  sex); switch to Katch-McArdle when `body_fat_fraction` is set (more
  accurate — recommend it via a suggestion when absent). Multiply by
  `metabolism_factor`. Return value + which formula + the inputs it used
  (labels travel).
- `tdee(person)` — BMR × PAL(activity_level).
- `calorie_target(person)` — TDEE adjusted for goal: a 0.5 kg/week loss
  ≈ −550 kcal/day (7700 kcal/kg fat / 14), clamped to a safe floor
  (never below BMR × a safety knob) with an evidence-bearing WARNING
  when the requested pace would breach it (knobs-and-suggestions).
- `nutrient_needs(manager, person, period='day')` — for every
  DietaryNutrient, the person's need scaled from nut-1 NutrientReference
  (matched to sex/age band) × any life-stage multipliers × period
  (day/week/month). Protein scales with body weight (g/kg knob);
  calories from `calorie_target`. Returns {nutrient: {amount, unit,
  basis, flaggedPriors}} — a full per-person requirement vector.

### Acceptance
`selftest_person.py`: BMR matches hand-computed Mifflin-St Jeor for a
reference person; higher activity → higher TDEE; a lose-weight goal
lowers the calorie target but never below the safety floor (warns
instead); metabolism_factor scales BMR; nutrient_needs returns all ~30
scaled to the demographic band and period. Green. Live: `POST
/api/nutrition/persons/{name}/needs` body `{period}`.

---

## PHASE nut-4 — Household profile (roll people up)

### Goal
Aggregate PersonProfiles into a household's TOTAL nutrient demand per
day/week/month.

### Object (`nutrition/household_basis.py`)
- **HouseholdProfile** (treeObject): `name`, `display_name`,
  `member_names_json` (list of PersonProfile names), `notes`.

### Analysis (`nutrition/household_analysis.py`)
- `household_needs(manager, household_name, period='week')` — sum each
  member's `nutrient_needs` over the period; return the aggregate
  requirement vector + the per-member breakdown (so a household can see
  who drives which need). Honest refusal if a member is missing.

### Acceptance
`selftest_household.py`: a 2-person household's demand = sum of members;
period scaling consistent; missing member refuses. Green. Live: `GET
/api/nutrition/households/{name}/needs?period=week`.

---

## PHASE nut-5 — Fulfillment simulation (the headline deliverable)

### Goal (Dustin, verbatim intent)
Simulate what it takes to fulfill ALL of a household's nutritional needs
using a hydroponic system: match household demand (nut-4) against a
garden's plant roster + realized harvest yields (nut-2/aqp-8) → coverage
per nutrient, GAPS named, and knob-driven suggestions ("grow N more kale
for vitamin-a"; "iodine/sodium/chloride NOT coverable by hydroponics →
saltwater food forest"; "B12 needs fermentation").

### Object (`nutrition/fulfillment_basis.py`)
- **GardenPlanDefinition** (treeObject): binds a HouseholdProfile + a
  set of {FoodItem: plant_count} + a harvest cadence → ONE runnable,
  rankable config (mirrors PotSystemDefinition). `household_name`,
  `plantings_json` ({food_name: count}), `harvest_period_days`,
  `coverage_result_json` (persisted snapshot for scoring), `notes`.

### Analysis (`nutrition/fulfillment_analysis.py`)
- `coverage(manager, garden_plan_name, period='week')` — total nutrient
  SUPPLY = Σ over plantings of (count × per-harvest yield × harvests per
  period); DEMAND = household_needs. Per nutrient: coverage ratio =
  supply/demand, status ('met'/'partial'/'gap'/'uncoverable'). Nutrients
  with `plant_availability='none'` are 'uncoverable' by design — name
  the saltwater/fermentation source. Overall: limiting nutrient named
  (honest-absence). Persist the snapshot.
- `suggest_plantings(manager, garden_plan_name)` — for each under-covered
  nutrient, the evidence-bearing suggestion: the highest-yield FoodItem
  for it + how many MORE plants close the gap (knobs-and-suggestions —
  suggest counts, never auto-apply). Flag uncoverable nutrients toward
  the saltwater plan.
- **Scoring bridge**: `nutritional-coverage` ScoreConcept ranks
  GardenPlanDefinitions by fraction-of-needs-met (weighted; uncoverable
  nutrients excluded from the hydroponic score but LISTED). objectRef
  into `coverage_result_json`, beeswax@L1 idiom.

### Acceptance
`selftest_fulfillment.py`: a well-stocked garden covers the coverable
nutrients; removing kale drops vitamin-a/k to 'gap' naming kale as the
fix; iodine/sodium/chloride always 'uncoverable' pointing at saltwater;
suggest_plantings returns counts that would close a gap; two plans rank
by coverage. Green. Live: `GET /api/nutrition/garden-plans/{name}/
coverage?period=week` + `/suggest`.

---

## PHASE nut-6 — Hydroponic garden system model (the "freshwater" build)

### Goal
Model the actual low-cost hydroponic garden that GROWS the roster: the
modified-Kratky system (Kratky pots + side-mounted float valve + gravity
reservoir of nutrient water), so the fulfillment sim runs against a REAL
buildable system, and growth couples to aqp-8 + the aqp-2 water model.

### Objects (`nutrition/garden_basis.py`)
- **KratkyPotDefinition** (treeObject): `name`, `volume_l`,
  `net_cup_diameter_mm`, `has_float_valve` (bool), `float_trigger_level_frac`,
  `plant_name` (what grows in it), `notes`. (The 3D-printable pot + float
  valve knobs — object-coherence for the future printable-geometry work,
  mirroring aqp-1 PotDefinition/PotHole.)
- **GardenSystemDefinition** (treeObject): `name`, `reservoir_volume_l`,
  `nutrient_water_name` (→ aqp-2 WaterDefinition; can be fed by an aqp-7
  CompostLoop or a freshwater source), `pot_names_json` (KratkyPot rows),
  `gravity_fed` (bool), `notes`.

### Analysis (`nutrition/garden_analysis.py`)
- `reservoir_demand(manager, garden_name, days)` — total nutrient-water
  draw from the pots' plant transpiration/uptake over `days` → refill
  cadence + the "raise the flag / refill" advisory (the manual-fallback
  knob Dustin described). Honest priors flagged.
- `garden_growth(manager, garden_name, days)` — run aqp-8 `grow()` for
  every pot's plant under the garden's water supply → realized yields
  that feed nut-2/nut-5. Ties the whole loop together.

### Acceptance
`selftest_garden.py`: reservoir demand scales with plant count + days;
float-valve pots vs manual flagged; garden_growth returns per-pot yields
that nut-5 consumes. Green. Live: `GET /api/nutrition/gardens/{name}/
reservoir?days=7` + `/grow`.

### Deferred (note it, don't silently drop)
3D-printable Kratky-pot + float-valve GEOMETRY (like aqp-1's parametric
pot) is a later phase — the KratkyPotDefinition knobs are the seam for
it. The perennial-replacement plant roster (Appendix B) is data, seed it
as PlantDefinitions incrementally.

---

## Cross-phase notes
- **Dependency chain**: nut-1 (vocab) → nut-2 (food yield, needs aqp-4/8)
  + nut-3 (person needs, needs nut-1) → nut-4 (household, needs nut-3) →
  nut-5 (fulfillment, needs nut-2+nut-4) → nut-6 (garden, feeds nut-5's
  realized yields). Build in order; each is independently selftestable
  with fake managers.
- **The gap story is the point**: hydroponics CANNOT supply iodine,
  sodium, chloride (and B12 without fermentation). nut-5 must name these
  as 'uncoverable' and point at `SALTWATER_FOOD_FOREST_SPEC.md` (Dulse/
  Kelp/Sea Lettuce/Red Ogo supply iodine/sodium/chloride; the tanks add
  protein diversity via scallops/mussels/anchovies/sardines). That
  cross-link is what unifies the three builds.
- **Everything is scorable**: person needs, household demand, and garden
  coverage all ride the scoring engine's objectRef seam so configs RANK
  (best garden for THIS household).
- **Honesty**: every RDA, food-composition, and metabolism number is a
  literature prior — flag them; the value is a transparent, tunable
  ledger the household can correct, not false precision.

---

## Appendix A — Plant → nutrient SOURCE MAP (Dustin's identified cores)

Seed these as FoodItem + NutrientContent (nut-2). Canonical — preserve.

- **Calories/carbs**: Perennial Buckwheat, Dwarf Almond, Dwarf Hazelnut
  (→ flour for soda breads).
- **Protein**: Lentils, Chia, Quinoa, beans.
- **Vitamin A**: Kale, Spinach, Swiss Chard.
- **Vitamin B (B1–B9)**: Lentils, Quinoa, Mushrooms, Buckwheat.
- **Vitamin B12**: NOT plant-native — via FERMENTATION (flag).
- **Vitamin C**: Dwarf Bell Peppers, Dwarf Tomatoes, Basil, Strawberries.
- **Vitamin D**: Sun-exposed Mushrooms (Shiitake, Oyster).
- **Vitamin E**: Dwarf Hazelnuts, Flax Seeds.
- **Vitamin K**: Spinach, Watercress, Parsley.
- **Iron**: Spinach, Kale, Swiss Chard, Lentils, Parsley.
- **Calcium**: Kale, Basil.
- **Magnesium**: Chia, Spinach.
- **Omega-3**: Chia, Flax-seeds, Dwarf Walnut.
- **Potassium**: Tomatoes, Bell Peppers, Mushrooms, Buckwheat, Swiss Chard.
- **Zinc**: Mushrooms, Lentils, Buckwheat.
- **Selenium**: Mushrooms.
- **Copper**: Hazelnuts, Mushrooms.
- **Manganese**: Hazelnuts, Chia, Buckwheat.
- **Chromium**: Mushrooms.
- **Molybdenum**: Lentils, Beans.
- **Boron**: Hazelnuts, Spinach.
- **Silicon**: Horsetail, Bamboo Shoots, Oats.
- **NOT covered by hydroponics (→ saltwater)**: Iodine, Sodium,
  Chloride → Dulse, Kelp, Sea Lettuce, Red Ogo.
- **Vitamin-D substrate note**: grow Dwarf Bamboo (Buddha's Belly,
  Dwarf Whitestripe) as mushroom-growth substrate.

## Appendix B — Perennial / indoor roster (compact, prunable)
Dwarf Perennial Peppers (Capsicum frutescens) · Dwarf Tree Tomato
(Tamarillo) · Everbearing Strawberries · Pigeon Pea (dwarf) · Scarlet
Runner Bean · Perennial Sorrel · Perennial/Greek Basil · Perennial/Sea
Parsley · Wild Rocket (perennial mustard) · Dwarf Yacon · Perennial
Chard · Perennial Daikon · Nine Star Perennial Broccoli · Malabar
Spinach. Bamboo (mushroom substrate): Bambusa Ventricosa 'Buddha's
Belly', Pleioblastus fortunei 'Dwarf Whitestripe'. Mushrooms: Oyster,
Shiitake. Soda-bread grains: Perennial Buckwheat, Dwarf Almond, Dwarf
Hazelnut.

## Appendix C — Low-cost hydroponic method (nut-6 build target)
Modified Kratky: Kratky pots + side-mounted float valve (opens when
water drops below a set level) + gravity nutrient-water reservoir. Float
trip can raise a PHYSICAL FLAG for manual refill when no automation is
installed. A freshwater food-forest / aqp-7 compost loop can BE the
nutrient-water source. Works for perennials + long-lived plants too
(centralized watering). Commercial ref: Kiicii Kratky kit / Vevor DWC.
Local build: 3D-printable Kratky pots + float valves + reservoir + food-
grade piping (deferred geometry phase; KratkyPotDefinition is the seam).
