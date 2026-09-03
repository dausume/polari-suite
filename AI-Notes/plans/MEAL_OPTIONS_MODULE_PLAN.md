# Meal options module (mo arc): meal data pushed up, people and places kept home

**Date:** 2026-09-03 · **Status: BUILDING (his ask, verbatim below) —
branch dev; every phase merges to dev when green so dev stays pushable.**

## 0. Direction (Dustin 2026-09-03, verbatim)

> "meal data in itself and info about it can and should be pushed up to
> a meal options module, however user and location oriented data should
> not be. Data about purchase prices without information about who did
> the purchase and if they are stripped down to only the month data,
> can be put up to the module for persistence and reference. This way
> someone can get advice about cost difference between kroger vs farmer
> market vs X, however we should distinguish between the fact that
> farmers markets are all different and owned by different people so
> they may differ unlike the monopolies. And typing local and
> independent businesses and prioritizing them over monopolies is best."

## 1. The line between "pushed up" and "kept home"

| Goes to `modules/mealoptions/` (published, seeds + initialData) | Stays in nutrition / household (never in a published module's data) |
|---|---|
| MealTemplate, VariationDefinition | MealPlanDefinition, MealEntry (a person's week) |
| Recipe, IngredientLine, CookingStep | PersonProfile, PersonThreshold, PersonExclusion, StatedCondition, ToleranceThreshold, WeightObservation, IntakeRecord, Daily/PeriodIntakeMetric, MealRating, ActivityLog |
| DishBase, IngredientRole, FoodRole, IngredientAffinity | HouseholdProfile, PantryItem, WasteRecord, PlanBudget, GardenPlanDefinition |
| KitchenToolDefinition, CookingTaskDefinition, StepMethod, StorageActionDefinition, CookingWorkflow | KitchenTool (owned), MethodPreference, ToolAdvisorDismissal |
| MealSituation (portability vocabulary), BulkStaple (shelf-life + cadence info; its demo offer loses the location pointer) | SourceLocation (address, lat/lon, household), PriceObservation (day + place), UnitWeightPrior household overrides |
| **PriceReference** — food × month × source type (× chain name only for chains) × coarse region; median/min/max $/kg; sample count; purchaser, place, day STRIPPED | everything under household/ (schedules, sleep, members, skills, ledger) |

Food and nutrient reference data (FoodItem, NutrientContent,
DietaryNutrient, NutrientReference) stays in nutrition: it is USDA
reference, not meal options, and nutrition is already its own module.

## 2. Source typing and the local-first rule

- `SourceLocation.ownership_kind` ∈ OWNERSHIP_KINDS = chain |
  franchise | online-chain | warehouse-chain | independent |
  farmers-market | coop | direct-farm | other, and `chain_name` (the
  brand, e.g. 'kroger'; BLANK for anything not a chain).
- A PriceReference for a chain carries the chain name: a Kroger price
  is a Kroger price in any region. A PriceReference for an independent
  / farmers market / coop / direct farm carries ONLY the type and the
  coarse region and `varies_by_vendor=True` with the honesty note
  "each is independently owned; prices differ by vendor and week" — no
  vendor name leaves the instance.
- `price_advice(food, local_preference_pct=10)`: ranks sources by $/kg
  with a KNOB — a local/independent source within `local_preference_pct`
  of the cheapest chain price is recommended first (labelled prior:
  "10 % convention — Dustin 2026-09-03: prioritise local and independent
  over monopolies"; set 0 for strict cheapest). The ranking states which
  rule decided. Cost engines (`best_price_per_kg`) stay numeric-min.

## 3. Phases

- **mo-1 — extract `modules/mealoptions/`** (hh-1 pattern: names
  unchanged, nutrition re-exports every moved name, registry entry,
  `nutrition.requires += mealoptions`, polariServer guard block,
  FEATURE_MODULES, selftest with mealoptions-only imports).
- **mo-2 — PriceReference + source typing + local-first advice**: the
  class, `export_price_references` (aggregate PriceObservation →
  month/source-type/chain/region rows, strip place/day/purchaser),
  `price_advice`, routes under /api/mealplanning/prices/*, the Food
  Supply page gains the advice panel + the reference table, demo rows
  typed.
- **mo-3 — the export path**: `POST /modules/export {"moduleId"}` +
  `pol modules export <module>` writing the module's non-prior rows to
  `initialData/<Class>.json` through a per-module `export_initial_data`
  hook; mealoptions' hook applies the privacy strip; a privacy selftest
  proves no person/place/day field can leave (class fields, initialData
  files, the price export).
- **mo-4 — publish**: `pol modules publish mealoptions` (his push
  ritual carries it: push-all-dev re-publishes module subtrees).

## 4. Decisions (defaults in bold)

- D1 month granularity = `YYYY-MM` string, **no day**; sample_count and
  min/median/max carry the spread.
- D2 region = the SourceLocation's free-text `region_label` **as typed**
  (no geocoding); blank = 'unstated'.
- D3 independents aggregate **per type per region per month**; chains
  aggregate per chain per region per month.
- D4 local preference knob default **10 %**, labelled convention prior.
- D5 export writes **only is_prior=False rows** (user-authored) plus the
  computed PriceReference rows; seeds stay in code.
