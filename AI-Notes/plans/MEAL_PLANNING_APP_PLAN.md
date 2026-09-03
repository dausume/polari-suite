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

## mpc — plan the week: meals per person → entries, coverage, portions (2026-09-02, BUILT same day)

**Dustin, verbatim:** "we should have a meals page specifying meals
for individuals, and then the meals page should be able to translate
into converting that meal into meal-prep for the week. We should be
able to choose to use that meal for any number of meals of the day,
and any number of days in the week from that meal plan. We should
also have a configuration page for planning meals for the week, that
checks if all meals have been planned for the week yet." … "it should
still be able to adjust the portioning on the meal to adjust the
calories and nutrients per person to try and best-fit getting each
person what they need individually. Compromising the fact that we
cannot make a perfect meal for everyone and compromising between
needs of the household"

**Built (wrapping):** `nutrition/planning_analysis.py` —
`expected_slots` (the person's eating pattern; 3-meal default
labeled), `week_coverage` (person × day × slot grid; missing NAMED;
headline; complete flag), `portion_fit` (ONE recipe, per-person
scales = slot share of THEIR calorie target ÷ kcal per serving via
`template_rollup` + `calorie_envelope`, clamped to the variation's
`scale_min/max`; key nutrients vs the slot share of `nutrient_needs`;
the compromise stated per person with a suggestion),
`apply_meal_proposal` (slots × days → MealEntry proposals with
`serving_split_json` = the portions and `scale` = their sum; existing
entries NAMED, never overwritten; template-slot mismatch = warning).
No-code: the "Add to the week" FORM (P4 real forms, `type: 'form'`,
extraVariables) runs `mealplan-apply-meal-to-week` = FormSubscription
→ AnalysisCall(mealplan-apply-meal, pick proposals) →
GenerateEvent(targetClassName=MealEntry, eventsFrom, dedupeBy name)
→ EmitFrontendEvent refreshDisplay; the MealEntry create trigger
re-coordinates pre-prep / packing / dishes / allocation. Pages:
`/display/mealplan/meals?object=<person>` (ranked meals, slots,
templates + variations tables, the form with the person pre-filled —
display-page now substitutes `{object}` into form defaults — portion
fit panels, the week's entries) and `/display/mealplan/week`
(headline, missing table, per person / per day, the form, the grid,
the entries table); the front door shows "Is the week planned?".
Routes: week-coverage, apply-meal (preview), portion-fit,
expected-slots. Selftest `nutrition.selftest_planning`.

**Portion objective KNOB (2026-09-02, BUILT — TESTING_OWED §7
"nutrient-aware portion optimisation"):** `portion_fit(…, objective=,
weights=)` and `GET …/templates/{name}/portion-fit?objective=&weights=`.
`objective='calories'` (DEFAULT — the behaviour above, byte-identical)
or `'nutrients'`: each person's scale is the point on a 0.05 grid
inside the variation's `[scale_min, scale_max]` minimising
`J(s) = Σ_n w_n · e_n(s)²` with `e_n = (have_n·s − line_n)/line_n` for
the TARGET lines calories / protein_g / fiber_g and, for sodium_mg, a
CEILING: `e = max(0, (have·s − cap)/cap)` — excess penalised,
shortfall free. The per-slot lines are the person's own daily lines ×
the slot fraction, read from the SAME functions the tracking page
uses: `tracking_periods._lines` (calorie envelope target; sodium CDRR
2300 mg / ToleranceThreshold row) and `threshold_analysis.person_thresholds`
(the DRI/override targets that feed `intake_day`'s vsThresholds) —
nothing re-derived. A nutrient with no line or no rollup is NAMED on
the fit (`noLine`), never guessed. **Weights = labelled convention
prior** (`DEFAULT_FIT_WEIGHTS`, not evidence-derived): calories 1.0,
protein 0.7, fiber 0.3, sodium-excess 0.5; `weights=protein=0.9,sodium=0.2`
(or a JSON object) overrides per line; whatever was used is echoed
(`weights`, `weightsLabel`, `unknownWeights`). Per person the fit adds
`caloriesOnlyScale`, `objectiveValue`, `fitLines` (kind, achieved vs
line, relErrPct, ownIdealScale, weight, weightedTerm, source),
`driver` (the largest weighted term) and `story` — words: "protein
pulls the portion up (its own ideal ×2.74); calories pull it down
(×2.00) — chosen ×2.25; protein drives the compromise (−18 % vs its
line)" / "sodium caps it at ×0.64". `clamped` under this objective =
pinned on a bound while J still falls past it. Compromises carry the
driver and a driver-specific suggestion. No scipy — a bounded scan.
Selftest `nutrition.selftest_planning` 16 → 24 checks (default
unchanged; high-protein override → larger scale than calories-only;
6 g salt → sodium ceiling caps it; weights echoed; no-line named).

## mpt — per-person tracking over time (2026-09-02, BUILT same day)

**Dustin, verbatim:** "a per-person page analyzing what an individual
has ate over time, so they can track their data and weight trajectory
over time. We should be able to condense data to average or mean
values at per week and per month levels to see different views. This
way we can see if we are consistently eating too many sweets or acid
inducing foods or calories or carbs or salty foods, etc. Or if we are
eating too little" … "work on the per person page and check it in the
browser and make sure we have multiple graphs that can be gone between
and that there is a place for a user to enter data."

**Built:** `nutrition/tracking_periods.py` — `period_summary`
(week/month buckets of the day series: means per LOGGED day of
calories/protein/carbohydrate/fiber/sodium, mean max-meal GL, mean
acid share, weight mean + delta; verdicts vs the person's own lines —
calorie envelope min/max, the day rollup's targets, the sodium CDRR,
GL>20, the acid-share tolerance row; low-confidence buckets named;
CONSISTENCY across well-logged buckets; persist → `PeriodIntakeMetric`
cache rows keyed series_key '<person>:<kind>'), `intake_proposal` /
`weight_proposal` (the log forms, validated). "Sweets" are read
through GL + carbohydrate — the FDC set has no sugars column (said on
the payload). Route `/users/{person}/periods?kind=week|month`
(reading refreshes the cache). Solutions `mealplan-log-intake`,
`mealplan-log-weight` (FormSubscription → AnalysisCall → GenerateEvent
IntakeRecord/WeightObservation, dedupe by name → refresh). Page
`/display/mealplan/me?object=<person>` (nav "My tracking"): week +
month summaries and consistency, the two log forms (person
pre-filled), 4 DAY charts, 6 WEEK charts, 3 MONTH charts (the same
7 period GraphDefinitions filtered by series_key), intake / weight /
period tables (Create New), the buckets and the lines. Selftest
`nutrition.selftest_tracking_periods` 15/15.

## mps — the Food Supply map (2026-09-02, BUILT same day)

**Dustin, verbatim:** "make a Food Supply page, that will focus
around a map. We will want to use geolocations and addresses for the
places where we buy different kinds of foods and at what prices we
buy those foods."

**Built:** `embeddedMap` (angular: a GeoJsonDefinition by NAME over a
class's rows through the existing map-renderer — the map twin of
embeddedTable/Graph/Calendar), the seeded GeoJsonDefinition
`mealplan-food-sources` (SourceLocation lat/lon, DMV-centred),
page `/display/mealplan/supply` (nav "Food Supply (map)"): the map
12-wide, places + prices tables (Create New with address and
coordinates), best place per food ($/kg, price age), the next weekly
purchase, the 3-month and yearly bulk proposals, bulk staples, the
purchase events. Owed: address → coordinates through the geocoder
service on Create New (today coordinates are typed), and "nearest
store for X" / "on the way home" (the workplace pin exists).

### N2 — Today page + done → WorkLedger (BUILT 2026-09-03, selftest 28/28)
- nutrition/today_analysis.py: person_day (CalendarEvent lines for one
  person-day in time order; eating/meal-prep/pre-prep/packing/cleanup/
  purchase, availability = context; safetyNote from MethodSkillRequirement
  hazard tags × SafetyRule; nextUp; done/planned/open counts; ledger lines)
  + mark_done_proposal (status done, ONE WorkLedger row = actual minutes if
  given else planned span minutes labelled 'planned-minutes prior';
  DurationObservation ONLY with actual minutes; dedupe ledger-<event>).
- nutrition/today_seed.py: tables today-day-list/today-ledger/today-
  durations; page mealplan/today (?object=person): structured headline over
  /api/mealplanning/today/{object}, mealplan-week in listDay for the person,
  Mark done FORM, ledger + durations tables; analyses today-person-day /
  today-mark-done; solutions today-mark-done-form (writes first, then
  ModifyEvent → refreshDisplay) and today-done-to-ledger; trigger
  today-done-to-ledger (object CalendarEvent, fieldFilter status==done).
- nutrition/today_api.py: TodayAPI — GET today/{person}?day=, POST
  today/{person}/done {event, minutes} through the real engine.
- Proven on the fake manager: form path keeps actual minutes against the
  nested trigger; a CRUD status edit → trigger → planned minutes; planned
  events never fire.

### N3 — Shopping trip page (BUILT 2026-09-03, selftest 33/33)
Phone-shaped `mealplan/shoptrip`: the purchase event's lines as a checklist
in STORE aisle order; "Bought it" → PriceObservation + PantryItem lot.
- shoptrip_basis: StoreAisleOrder (per-store walk order knob; NOT on
  SourceLocation) + FoodAisleCategory (51 food→aisle convention priors:
  produce/dairy/meat/seafood/dry-goods); DEFAULT_AISLE_ORDER prior.
- shoptrip_analysis: trip_checklist (generated purchase event first, else
  the weekly proposal, source stated; store order row or convention prior;
  unknown aisle last + named; est. cost = best observed $/kg × g with age;
  bought = a lot from this store within ±6 d, a knob) and
  record_purchase_proposal (PriceObservation `<store>-<food>-<date>` never
  overwriting; lot grams via weight priors, storage by aisle prior,
  best-before from BulkStaple shelf_life_days).
- shoptrip_seed: 3 tables, 1 page (5 rows, 1–2 items each), 2 analyses,
  1 solution (Form → AnalysisCall×2 → GenerateEvent PriceObservation +
  PantryItem → refresh). shoptrip_api: GET checklist, POST bought (runs the
  seeded solution — one write path). Default plan `demo-alex-week`.

### N4 — Cook now (BUILT 2026-09-03, selftest 33/33)
Page mealplan/cooknow?object=<person>: the recipe at prep time for ONE person.
- cooknow_analysis.cook_sheet: template → Recipe steps in order; method →
  task → StepMethod via workflow_analysis.resolve_method; minutes =
  household.step_minutes (base × skill factor, never below the safety
  floor; basis on every step); unattended steps carry the timer window and
  the household's dish suggestion (dish_plan's unattended-first rule);
  safety lines = SafetyRule words per hazard tag + safety_check verdict;
  ingredients per step scaled by the person's serving split; totals +
  readyBy/startBy from a CalendarEvent span. step_done_proposal → one
  DurationObservation (dedupe <person>-<template>-<step>-<date>) + the
  refine_speed_factors suggestion AS IF counted (applied=False — PersonSkill
  stays a knob).
- cooknow_seed: 2 tables, the page (6 rows), 2 analyses, 1 solution
  (FormSubscription → AnalysisCall → GenerateEvent DurationObservation →
  refreshDisplay). cooknow_api: GET cooknow/{person}?template=, POST
  …/step-done (dry=1 previews). Speed-refinement panels reuse
  /api/mealplanning/speed-refinement.
- Observation: on the demo seeds refine_speed_factors proposes knife-work
  2.25 for demo-alex (seeded 4–5 min observations ÷ dice-knife base 2.0).

### N5 — Weekly review (BUILT 2026-09-03, selftest 32/32)
Page mealplan/review: headline api-structured-panel over GET
/api/mealplanning/review + one panel per section (?section=… pick=lines) +
the period calories/sodium graphs + "Accept next week's proposals" form
(FormSubscription → AnalysisCall next-week-proposals → GenerateEvent
CalendarEvent dedupeBy name → refreshDisplay) + WasteRecord / PlanBudget /
WorkLedger / event tables by existing name + an honesty panel (8 named
priors as records).
- weekreview_analysis: week_review composes week_coverage × IntakeRecord,
  period_summary (this-week bucket + full-history consistency),
  plan_budget_report, waste_report (windowed), fairness_readout (windowed),
  weekly + bulk purchase proposals; next_week_proposals (purchase Sat 10:00
  prior + bulk buys whose 1st falls in the Monday-start next week + next
  Sunday review); weekly_review_event_proposal (category review, Sunday
  18:00 × 45 min priors). Every section says "no data" when rows are
  missing. Default plan `demo-alex-week`.
- Trigger weekly-review-sunday (schedule SU 17:00) → the review event
  through the engine; second tick idempotent.
