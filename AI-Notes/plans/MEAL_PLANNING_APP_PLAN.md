# Meal-planning app over base ingredients + PSPP (mpa arc)

**Date:** 2026-09-01 · **Status: BUILD ROUND (his go, verbatim below);
branch `dev-mpa-1` off `dev-fsp-1` with `dev-nmp-1` MERGED IN (D7
"stacked" was ratified with the fsp defaults 2026-09-01 — dev itself
stays untouched; his nmp merge-review gate stands).**

## 0. Direction (Dustin 2026-09-01, verbatim — treat as ratified)

1. "please continue work on food planning based on base ingredients
   and using pspp to establish foundational properties and nutrition
   of meals when meal planning and accounting for minimizing meal
   prep timing as well as cost. We will want to be able to account
   for buying at particular prices from different geolocations, as
   well as establishing and assigning nutritional information and
   weight approximately for things that are purchased and being able
   to adjust plans based on available food."
2. "continue working on it for as long as you can and try to make an
   intuitive meal planning app composed of sets of displays, we
   should be able to interconnect displays to make it seem like it's
   own app and be able to tie users and their information to
   keycloak login accounts and tracking their information and doing
   meal planning for them and tracking their nutrition, meal
   acidity, and other important metrics, over time"

## 1. Ground truth (reuse, never rebuild)

- fsp-0/fsp-1 (dev-fsp-1): FoodMaterial roster (49, slug = vendor
  FDC slug), 949 composition PropertyClaims on `#as-defined`,
  domain contracts, food process vocabulary as pspp rows.
- nmp-0..11 (merged in from dev-nmp-1): recipes + retention/yield
  engine (nmp-3), templates/plans + the hard gate (nmp-4), GL +
  tolerance table incl. the low-confidence acid/reflux rows (nmp-2,
  decision 9), the prep scheduler minimizing total-active-minutes
  (nmp-10 — the "minimize meal prep timing" half ALREADY EXISTS),
  affinity composer (nmp-11), Hall trajectory + WeightObservation
  (nmp-6), 5 display pages + the nutrition-planner app row.
- Slug identity: FoodMaterial.name == FoodItem.name ==
  IngredientLine.food_name (all derive from the vendored CSV).
- Auth: request.context.user_info {sub, username, email} via the
  existing Keycloak JWT middleware (/auth/me pattern).
- Displays: pure-data pages (class-rows-table / api-json-panel rows
  in module_pages_seed) + app rows with nav_json (apps_seed).

## 2. Phases

- **mpa-0 — fsp-2 transform engine v1 (foodstate)**: derive a new
  FoodState from a stated transform — mass balance (stated or
  R6-cooking-yields water/mass loss; concentration arithmetic
  exact) + R6 retention rung riding nmp-3; structure/model rungs
  REFUSE naming I5 (no invented kinetics). `template_state_chain`:
  a MealTemplate's process graph → terminal prepared-food state
  claims per-100g — "PSPP establishes the meal's foundational
  properties". Pure-compute first; persistence via
  composition.seed_upsert (derive-on-demand, D5).
- **mpa-1 — chemistry priors + meal acidity (foodstate+nutrition)**:
  literature pH priors (FDA/CFSAN approximate-pH table, public
  domain) as PropertyClaims on `#as-defined` for the roster's
  acid-relevant foods, range in value_json; acid-category rows.
  `meal_acidity(portions)`: high-acid mass share (feeds the seeded
  `meal-acid-share` tolerance row), per-ingredient pH list
  (mass-weighted indicator labeled NON-pH-arithmetic honest), the
  decision-9 trigger flags. Gastric framing stays D6:
  direction+conditions, no magnitudes, not medical advice.
- **mpa-2 — market layer (nutrition)**: SourceLocation (store +
  geolocation lat/lon + region label), PriceObservation (food ×
  location × package price + package amount → $/kg normalized,
  observed_date staleness shown), UnitWeightPrior (food × unit
  label → approx grams, cited/tunable — "assign weight
  approximately for things that are purchased"). Best-price and
  price-compare reports across locations.
- **mpa-3 — pantry + availability + cost (nutrition)**: PantryItem
  (household × food × grams-approx × storage state × acquired/
  expiry-window × source). Plan services: `plan_ingredient_demand`
  (grams per food per plan), `plan_cost` (demand × chosen/best
  price with store attribution), `shopping_list` (demand − pantry,
  priced per location option), `availability_report` + suggestions
  (which entries are coverable now; variation swaps that consume
  available stock — knobs-and-suggestions, never auto-edit).
- **mpa-4 — accounts + tracking over time (nutrition)**:
  UserAccountLink (keycloak sub/username/email → person_name +
  household_name; explicit row, no silent auto-provision).
  IntakeRecord (person × date × slot × template/variation/scale —
  planned-vs-eaten honesty). `tracking_series`: per-person
  date-series of calories/protein/fiber/sodium/GL/meal-acidity vs
  thresholds + weight observations — the "over time" surfaces.
- **mpa-5 — the app (api + pages + nav)**: `/api/mealplanning/*`
  (me, dashboard, plan cost/shopping/availability, prices, pantry,
  series, acidity, transform demos) + display pages (dashboard,
  planner, pantry, market, trends) as pure-data rows +
  nutrition-planner app row grows nav_json groups (top+side menus)
  interconnecting every page — "seems like its own app".
- **mpa-6 — selftate wiring + suites**: polariServer registration
  (imports, stubs, defClassList, seed pairs legacy+upsert,
  endpoints), selftest per phase, full nutrition+foodstate+pspp
  suite run.

## 3. Defaults assumed (flag to Dustin; every one a knob)

| # | default |
|---|---|
| A1 | currency = USD; prices are user-entered observations (no store APIs / scraping — license + ToS territory) |
| A2 | geolocation = lat/lon + free label on SourceLocation; no geocoder dependency in v1 |
| A3 | unit weights = cited convention priors (FDC portion conventions where known), tunable per household |
| A4 | keycloak link = explicit UserAccountLink row; `/api/mealplanning/me` reports link-or-honest-absence; no auto-provision (a knob later) |
| A5 | acidity metric = acid-share + pH priors + trigger flags; NO gastric magnitude claims (fsp D6 holds) |
| A6 | intake tracking starts from plan confirmation ("ate as planned" default with per-entry edits) |
| A7 | all mass-loss in mass-balance v1 attributed to water unless stated otherwise — assumption named on every claim |

## 3b. Round 2 (mpb) — budget + tailoring (RATIFIED 2026-09-01)

Dustin (verbatim): "we should not be doing diagnosis in any way,
what we can say is 'try to make meals that do not make this
condition worse', all of the rest sounds good."

So: **conditions are STATED by the person, never inferred or
diagnosed; the system only steers toward meals that avoid known
aggravators of the stated condition** — comfort steering, not
treatment; the posture restated on every payload. Decision 3's
no-diagnosis core stands; this narrows what "personalization"
may ever mean here.

Phases (priority order):
- **mpb-1 — allergen/intolerance exclusions**: FDA major-9
  allergen flags per roster food (identity-derived data rows);
  PersonExclusion (allergen or food × stated reason × hard/soft);
  plans + composer + suggestions filter/refuse with the violation
  NAMED. A safety filter, not medical advice.
- **mpb-2 — stated-condition comfort steering**: StatedCondition
  rows (reflux / sodium-sensitive / glycemic-sensitive /
  fodmap-sensitive…) mapping to the EXISTING evidence rows
  (decision-9 acid+fat+trigger, CDRR, GL cap, FODMAP cutoffs) —
  per-person elevation of those warnings in ranking + per-meal
  flags ("this would likely aggravate your stated reflux:
  citrus/tomato share 0.6"). No diagnosis; no magnitudes (D6).
- **mpb-3 — cost-per-nutrient + budget envelope**: $/g-nutrient
  rankings from prices × per-100g; MealPlan weekly budget knob;
  plan rollup shows spend vs budget; counterbalance suggestions
  ranked by cheapest-closer.
- **mpb-6 — coverage steering over time**: rolling 7/30-day
  under-target report from the tracking series + cheapest closers
  that fit the person's dishes (affinity-filtered).
- **mpb-4 — price trends/buy-low + waste ledger + trip distance**
  (honest refusals under thin observation history).
- **mpb-7 — trajectory feedback** (observed-vs-projected drift →
  suggested envelope adjustment, never auto-applied).
- **mpb-8 — meal ratings → affinity overlay**; **mpb-9 —
  quick-add text entry** (deterministic grammar, refuses rather
  than guesses); **mpb-10 — API/pages/wiring/deploy**.
- **mpb-5 — child/teen DRI bands**: DEFERRED to its own
  transcription round — every value must be fetched+cited
  (derive-or-cite), not typed from memory.

**mpb STATUS (2026-09-01, same session as the go):** mpb-1
(exclusions, 17/17) · mpb-2 (condition steering, 13/13) · mpb-3
(nutrient-$/budget, 13/13) · mpb-4 waste half (8/8) · mpb-6
(coverage steering, 12/12) · mpb-7 (plan-fed trajectory route) ·
mpb-8 (ratings, 8/8) · mpb-9 (quick-add, 11/11) ALL BUILT on
dev-mpa-1; 11 new API routes + panels on the app pages; full
28-suite battery green. ✅ REDEPLOYED same
session: backend rebuilt + rolled, **34/34 live probes pass**
(all mpa + mpb routes on staging). NOT yet: mpb-4
price-trend/buy-low half (needs observation history), trip
distance, mpb-5, composer rank-integration of conditions/ratings
(surfaces exist; wiring into nmp-11 ranking = next), the browser
pass (`claude --chrome` relaunch).

## 4. Non-goals

- No store price scraping/APIs, no barcodes, no medical claims,
  no new chart engine (sci-xy-chart stays THE home; pages use the
  generic data components until the embeddedGraph-by-name frontend
  fix lands), no relitigating nmp/fsp/pspp architecture.

## 5. Status

| phase | state |
|---|---|
| mpa-0 | ✅ BUILT 2026-09-01 (dev-mpa-1): foodstate/food_transforms.py — mass-balance + R6 retention rungs, model rungs REFUSE (I5); template_state_chain agrees with the nmp-4 rollup within 1% (guard); 25/25 |
| mpa-1 | ✅ BUILT: food_ph_seed (FDA/CFSAN-lineage ranges, VERIFIED vs TRANSCRIBED labeled per row) + acidity_analysis (acid mass share vs 21 CFR 114 pH≤4.6; no combined meal pH by design); 14/14 |
| mpa-2 | ✅ BUILT: market_basis/market_analysis — SourceLocation (lat/lon), PriceObservation → $/kg, UnitWeightPrior approx weights (household-overridable), purchased-item weight+nutrition+cost; 15/15 |
| mpa-3 | ✅ BUILT: pantry_basis/pantry_analysis — stock, plan demand, covered/partial/missing, priced shopping list (unpriced NAMED), plan cost, stock-aware suggestions (never auto-edit); 17/17 |
| mpa-4 | ✅ BUILT: account_basis (explicit Keycloak links, no silent provisioning) + intake_basis + tracking_analysis (day rollup + date series with NAMED gap days + weight); 16/16 |
| mpa-5 | ✅ BUILT: mealplanning_api (13 routes) + 5 display pages (/display/mealplan[...]) + demo plan + nutrition-planner nav groups (top+side) |
| mpa-6 | ✅ BUILT: polariServer wiring (imports/stubs/defClassList/legacy+upsert seed passes/endpoint/pages); FULL BATTERY GREEN: foodstate 3 suites, nutrition 15, apps 45/45, pspp smoke 3 |
| mpa-7 | ✅ BUILT: the embeddedGraph-by-name frontend fix (angular dev-mpa-1: graphName input riding the existing loadConfigByName) + mealplan-weight-trend GraphDefinition + the chart panel on /display/mealplan/trends + demo WeightObservations. Derived series (calories/GL/acid per day) still render as tables — charting them needs a cached-rows class or an API-fed graph component (named gap) |
| mpa-8 | ✅ BUILT: derived day-series chartable — DailyIntakeMetric derive-on-demand cache (upserted when /series is read; duck managers skip loudly), 3 trend GraphDefinitions (calories / max-meal GL / max-meal acid share) + chart panels beside the weight chart on the trends page |
| deploy | ✅ **DEPLOYED 2026-09-01**: pspp+foodstate+nutrition+composition assigned to prf-a (`pol topology assign`, POLARI_MODULES now 16 modules), BOTH images rebuilt from the dev-mpa-1 trees, `pol swarm deploy node`, admission ~14 min — **21/21 LIVE PROBES PASS** (all foodstate + mealplanning routes, metric cache upserts live, Graph/Display rows present). Probe script: `pol suite`-side scratch, battery recorded in the handoff |
| redeploy 2 | ✅ backend re-rolled same session with the fsp-3 chemistry slice — speciation + tomato acidity live (TA 3.79 meq/100g), 21/21 battery re-passed; frontend live on the new bundle (by-name charts), pinned to pol-core (LIVE-ONLY constraint — stack spec still needs the pin) |
| browser pass | ⚠ pending — the visual pass over /display/mealplan* (chart rendering esp. date-x-axis on the trend charts is the untested seam); this session had no Chrome extension — relaunch `claude --chrome` |
