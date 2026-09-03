# The Household app: chores, cleaning, laundry, supplies — one household layer (hh arc)

**Date:** 2026-09-02 · **Status: hh-1 BUILT 2026-09-02 (the module
extraction, names unchanged) under his "use agents … surplus of tokens"
go — on `dev-mlg-1`, UNCOMMITTED (no `dev-hh-1` branch was cut: his
push ritual). D1–D10 still await ratification before hh-2. See §3a.**

## 0. Direction (Dustin 2026-09-02, verbatim)

> "should we expand this out to cleaning, laundry and other general
> chores? Turn it into a general Household app?" → my assessment: yes,
> refactor-first · his "go ahead".

## 1. Why it is cheap — what the mlg round already made generic

| Household-generic today (lives in `nutrition/`) | Meal-specific (stays in `nutrition/`) |
|---|---|
| `PersonSchedule`, `SleepPreference` (availability, sleep spacing) | recipes, templates, plans, entries, nutrition, thresholds |
| `HouseholdMember`, `WorkloadType`, `WorkDistributionPolicy` (percent shares, delivery), `WorkLedger` | pantry, prices, purchase / bulk-purchase proposals (the PATTERN generalises — the FOOD rows stay) |
| `SkillDefinition`, `PersonSkill`, `MethodSkillRequirement`, `SafetyRule`, `DurationObservation` (refinement) | pre-prep scheduler (`derive_week_plan`), `prep_time_profile`, `MealTimeProfile` |
| `DishStrategy`, `HouseholdDishPolicy`, `dish_plan` — the FIRST non-cooking chore, already riding everything | `MealSituation`, `MealLogistics`, `portability_plan` (lunchbox / cold packs) |
| `availability_windows`, `where_is`, `person_factor`, `step_minutes`, `safety_check`, `refine_speed_factors`, `assign_work`, `fairness_readout` | `meal_timing_check` (dinner→sleep), `coordinate_week` (meal spine) |
| The cal arc: `EventDefinition`, `CalendarDefinition`, `CalendarEvent`, `EventTrigger`, `AnalysisCall`, the dispatcher | the `mealplan-*` seeds |

The generic half is meal-branded only by module placement and by demo
seeds cut around `demo-alex-week`. `logistics_analysis.py` still
imports meal things in ~30 places — the extraction (hh-1) is exactly
the act of cutting that file in two.

## 2. Shape

```
modules/household/                      NEW module (own repo: polari-module-household)
  household_basis.py    HouseholdMember, WorkloadType, WorkDistributionPolicy,
                        WorkLedger, PersonSchedule, SleepPreference,
                        SkillDefinition, PersonSkill, MethodSkillRequirement,
                        SafetyRule, DurationObservation          (MOVED, same names)
  chore_basis.py        ChoreDefinition   family ∈ cleaning | laundry | maintenance |
                                          yard | pets | admin | cooking (the meal
                                          arc's own chores map here), room/zone
                                          (zones' ZoneDefinition.room_label),
                                          recurrence (`schedule`), priority,
                                          minutes prior, skills/hazards via
                                          MethodSkillRequirement (task_kind=chore)
                        ChoreMethod       the StepMethod pattern for chores
                                          (vacuum-upright / vacuum-robot;
                                          machine cycles for laundry: wash,
                                          dry, fold = attended? + cycle minutes)
                        ChoreStrategy     DishStrategy generalised (unattended-
                                          first / batch / when-full / robot)
                        HouseholdSupply   consumables stock (detergent, bags,
                                          filters): the PantryItem pattern —
                                          quantity/unit, reorder threshold,
                                          bulk offer + cadence (BulkStaple
                                          pattern → the SAME bulk-purchase
                                          triggers buy detergent yearly)
  household_analysis.py availability_windows, where_is, person_factor,
                        step_minutes, safety_check, refine_speed_factors,
                        assign_work, fairness_readout                (MOVED)
                        chore_plan(household, week)  recurrence → dated chore
                                          events sized by the assignee's skill,
                                          placed in FREE windows (availability),
                                          machine cycles as unattended windows
                                          that absorb other chores, supplies
                                          checked (low stock → a purchase line)
  household_seed.py     EventDefinitions (person-schedule moves here; chore
                        events), CalendarDefinition 'household-week' (layers:
                        schedules bg, meals, chores by family, purchases),
                        AnalysisDefinitions, SolutionDefinitions, triggers
                        (weekly chore generation; any knob → re-plan; event
                        done → WorkLedger row — the owed piece, built here)
  household_pages.py    /display/household (the calendar front door across
                        everything), /display/household/work (members, shares,
                        allocation, fairness — promoted from mealplan/household),
                        /display/household/chores, /display/household/supplies
modules/nutrition/      requires: household (+ zones optional for rooms)
  keeps meals; imports the moved names from household; `coordinate_week`
  becomes ONE contributor of events to the household week (meal-prep,
  eating, packing, dishes) that chore_plan merges before assign_work
polariapps: app row 'household' (front door = household-week); nutrition-planner
  stays a sibling app whose nav gains 'Household' links
```

Rules that bind: wrap what exists (no new engine, no new display
kind); no MealEntry/StepMethod schema changes; per-object definitions
embedded; upsert seeds + boot repoint; no JSON on screens; every
number a labeled prior; "skilled, not fast"; safety rules extend to
chemicals (mixing bleach + ammonia), ladders, sharp tools, lifting.

## 3. Phases

- **hh-0 — this plan.** ✅
- **hh-1 — extract the household module (the refactor, its own
  confirmed phase).** Create `modules/household/` (registry entry +
  `pol modules publish household` → polari-module-household, the
  pspp/foodstate precedent), MOVE the generic classes + analyses with
  their names unchanged (so live rows, TableDefinitions, triggers and
  AnalysisDefinition callable refs converge: callable_ref strings
  become `household.household_analysis:…` — the upsert rewrites them),
  nutrition `requires` household, `_feature_available('household')`
  gating, the mealplan-household page becomes /display/household/work
  with a redirect note. Selftests: the moved suites run unchanged from
  their new home; nutrition's logistics selftest still passes.
- **hh-2 — chores + laundry.** ChoreDefinition / ChoreMethod /
  ChoreStrategy vocabularies (seeded, authorable: vacuum, mop,
  bathroom, kitchen wipe-down, trash, laundry wash/dry/fold, sheets,
  yard, pet care, bills), `chore_plan` (recurrence → events in free
  windows; laundry cycles as unattended windows that absorb folding
  or another chore; skills + safety per method), the household-week
  calendar with chore layers, weekly generation trigger, done → ledger
  trigger. Selftest: a weekly vacuum lands in a free evening of the
  person whose shares are under target; a wash cycle's unattended 45
  min absorbs the bathroom chore; bleach + ammonia hazards refuse a
  novice without supervision.
- **hh-3 — supplies.** HouseholdSupply stock + reorder thresholds,
  low-stock → purchase lines on the weekly purchase event (the food
  purchase event grows a 'supplies' section — one trip), bulk cadence
  for detergent/bags via the existing bulk-purchase triggers.
- **hh-4 — the app.** 'household' app row + nav, the four pages, the
  meal planner's nav links, headless pass.
- **hh-5 — closing the owed pieces.** Event done → WorkLedger
  (trigger), "how long did it take" prompts on done (DurationObservation),
  a global (not greedy) allocation option behind a knob.

## 3a. hh-1 as built (2026-09-02)

- `modules/household/` — `household_basis.py` (13 classes + seeds
  moved VERBATIM from nutrition's logistics_basis: PersonSchedule,
  SleepPreference, HouseholdMember, WorkloadType,
  WorkDistributionPolicy, WorkLedger, SkillDefinition, PersonSkill,
  MethodSkillRequirement, SafetyRule, DurationObservation,
  DishStrategy, HouseholdDishPolicy; SKILL_LEVELS/SKILL_FACTORS moved
  in from workflow_basis; `_PROV='mlg-1'` kept so the upsert converges;
  `HOUSEHOLD_SEED_PAIRS` / `HOUSEHOLD_CLASSES`; imports nothing from
  nutrition), `household_analysis.py` (availability_windows, where_is,
  person_factor, method_requirement, step_minutes, safety_check,
  refine_speed_factors, assign_work, fairness_readout; the category →
  steps rule is now a registry: `STEP_BUILDERS` +
  `register_step_builder(category, fn, workload_type=None)` — household
  registers `purchase` and `cleanup`, nutrition registers `pre-prep`,
  `meal-prep`, `packing` at import via `MEAL_STEP_BUILDERS`),
  `selftest_household.py` 27/27 (household-only imports).
- nutrition keeps MealSituation / MealLogistics / MealTimeProfile,
  meal_timing_check, prep_time_profile, portability_plan, dish_plan,
  SLOT_TIMES, EATING_PRIORS — and RE-EXPORTS every moved name, so no
  importer changed (purchase_analysis, mealplanning_api, calendar_seed,
  mealplan_pages_seed, the selftests).
- Registration: polariServer `household` guard block (classes + both
  seed-pair lists), nutrition `requires: ["household"]` in
  `polari-modules.json` (+ `household` entry, repo "" until
  `pol modules publish household`), `module_loading.FEATURE_MODULES`
  + `FEATURE_REQUIRES['nutrition']=('household',)`; the four
  AnalysisDefinition callable refs now `household.household_analysis:…`
  (the upsert rewrites the live rows). `pol topology assign household
  prf-a` done (row) — the stack deploy carries it into POLARI_MODULES.
- NOT done in hh-1 (deferred to hh-4): the mealplan-household page →
  /display/household/work redirect; `pol modules publish household`.
- Selftests unchanged and green: nutrition logistics / planning /
  purchase / tracking_periods / mealplan_pages (only the seed loop in
  logistics+planning now iterates HOUSEHOLD_SEED_PAIRS +
  LOGISTICS_SEED_PAIRS). Pre-existing, not ours:
  `moduleService.selftest_lazy_imports` 14/15 — the cntfet guard
  blocks' stub tuples drift from their imports (14 blocks, fv arc).

## 4. Decisions (recommended defaults in bold)

| # | Question | Recommend |
|---|---|---|
| D1 | Module boundary | **new `household` module; nutrition requires it; names unchanged on the move** |
| D2 | Rooms | **zones' ZoneDefinition (room_label) when present; a free-text room otherwise** |
| D3 | Chore families | **cleaning, laundry, maintenance, yard, pets, admin, cooking — authorable** |
| D4 | Laundry model | **ChoreMethod cycles (wash 45 / dry 60 / fold 15 priors) as unattended windows; a machine is a KitchenToolDefinition-style HouseholdTool** |
| D5 | Supplies | **HouseholdSupply = the pantry pattern; low stock joins the weekly purchase; bulk via the existing cadence triggers** |
| D6 | Safety | **SafetyRule extended with chemical / ladder / lifting hazards; same floors + supervision rule** |
| D7 | Front door | **household-week calendar = meals + chores + purchases + schedules; the meal planner keeps its own front door** |
| D8 | Allocation | **greedy stays default; a global option (assignment problem) behind a knob in hh-5** |
| D9 | Ledger | **event status → done writes WorkLedger + prompts durations (hh-5)** |
| D10 | Demo | **re-cut seeds around 'demo-household' (Alex + Sam) with a week of chores; meal seeds untouched** |

## 5. Open questions (short)

1. Does the household app absorb the meal planner (one app) or stay
   a sibling (two apps sharing the layer)? Default: sibling.
2. Robot vacuum / dishwasher / washer-dryer as owned HouseholdTools
   in the demo?
3. Should kids (role child/teen) get chores with supervision by
   default? Default: yes, via SafetyRule floors.
