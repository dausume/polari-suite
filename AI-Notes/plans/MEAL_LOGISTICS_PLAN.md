# Meal logistics: schedules & sleep, work split & cost shift, portability, prep-vs-eating time (mlg arc)

**Date:** 2026-09-02 · **Status: mlg-1..5 BUILT the same day on
`dev-mlg-1` (framework; angular untouched — the background layer is
a FullCalendar event property the cal-3 component already passes
through), DEPLOYED to staging, UNCOMMITTED (his push ritual). His go:
"Are you able to go through building all that out". Ratified: D2
(2 h default), D4/D13 (percent shares, minimise total work), D9/D14
(skill profiles, skills on steps), D15 (safety bounds speed), D16
(dishes are work); the rest at the recommended defaults; open
questions answered as: the second adult is the existing demo-sam,
delivery = the three knobs, the workplace is a located SourceLocation.**

> **BUILT (2026-09-02):** `nutrition/logistics_basis.py` — 16 classes
> (PersonSchedule, SleepPreference, HouseholdMember, WorkloadType,
> WorkDistributionPolicy, WorkLedger, MealSituation, MealLogistics,
> SkillDefinition, PersonSkill, MethodSkillRequirement, SafetyRule,
> DurationObservation, MealTimeProfile, DishStrategy,
> HouseholdDishPolicy) + demo seeds (Alex + Sam schedules, 70/30
> pre-prep shares, delivery knobs, Sam's packed shift dinner, 7
> skills incl. kitchen-safety + food-safety, per-method skills and
> safety floors, 7 cited safety rules, 3 dice observations, eating
> priors, 5 dish strategies). `nutrition/logistics_analysis.py` —
> availability_windows, where_is, meal_timing_check,
> prep_time_profile, step_minutes (max(method × factor, safety
> floor)), safety_check, refine_speed_factors (floor 0.7, safety
> questions), portability_plan, dish_plan, assign_work (greedy:
> fastest free safe person under target ± tolerance; both
> allocations; purchase-vs-delivery), fairness_readout.
> `coordinate_week` v2 carries all of it (meal-prep sized per person,
> eating blocks, packing, dishes, assignees, timing flags). 8 new
> `/api/mealplanning/*` routes, 8 AnalysisDefinitions, 7 object
> triggers (any logistics knob → re-coordinate; trigger inputs win
> over the payload), the `person-schedule` EventDefinition drawn as
> a BACKGROUND layer on mealplan-week, the `/display/mealplan/
> household` page (16 tables + the allocation / timing / packing /
> dish / fairness / refinement panels) + nav entry, workplace +
> warehouse SourceLocations, lunchbox / cold-pack / dishwasher tool
> definitions. Selftest 26/26 (TESTING_OWED §6); regressions green.

## 0. Direction (Dustin 2026-09-02, verbatim — treat as the ask)

> "we should also do tracking of people's work and other schedules,
> this way meal prep can be planned around that, and account for
> sleeping preferences. That way we can try to space meals so that
> there is enough time between eating dinner and going to sleep so
> people do not have an upset stomach.
>
> We will also want to devise splitting the work of meal prep and
> purchase trips. So for example, if we have a 2 adult household it
> may be the case that they both always go on all purchasing trips.
> Alternatively they may order supplies delivered and have a shift in
> costs due to that. We should be able to configure how we want to
> shift around cost and work distribution in respect to the work on
> pre-prep or on the meal prep itself.
>
> We should also track if that meal needs to be able to be taken to a
> workplace and if you need a lunchbox that keeps it cold prepared,
> and maybe something like cold-packs to keep the insulated lunch box
> cold when going to work or staying at work.
>
> We want to account for the various situations we need to be able
> to prepare meals for and we want to distinguish between eating the
> meal itself and how much time that usually takes people vs how much
> time it takes to do final prep for a meal based on pre-prep that
> was done. And understanding that it may vary per person and based
> on what the prep method is and the skill needed for the task and
> skill of the person and that there may be various skills and
> cooking tools needed. Let us think through all of this"

Five areas, one spine: **where each person IS and when** (their
schedules) decides **which situation a meal is eaten in**, which
decides **what must be prepared, by whom, with what tools, how long
it takes, and when it must be finished** — and all of it becomes
events on the calendar the triggers already generate.

## 1. Audit — what exists, and what each area wraps

| Area | Already in Polari (verified 2026-09-02) | Gap |
|---|---|---|
| Schedules & sleep | `ActivityLog(date, start_hhmm, duration_min)`; the Compendium vocabulary INCLUDES `sleeping` (code 07030); `REFLUX_WINDOW_H = 2.5` — the cited ~2-3 h comfort window (decision 14, meal↔exercise) in `activity_analysis`; the `schedule` field type + expander (cal arc); `PersonProfile.eating_pattern`; calendar layers | no RECURRING commitments per person (work / commute / sleep), no location ("at workplace"), no dinner→sleep spacing |
| Work split & cost | `HouseholdProfile.member_names_json`; `MealEntry.serving_split_json`; `PersonProfile.cooking_skill`; `MethodPreference(person)`; purchase / pre-prep / meal-prep events with `person_name` (cal-4); delivery = nothing | no member roles, no distribution POLICY, no assignment of an event to people, no delivery cost model, no work ledger |
| Portability | `KitchenToolDefinition` + `KitchenTool` inventory (user-authorable, decision 13); `StorageActionDefinition(safety_window_days, quality_window_days, duration_min, citation)` — FSIS windows as rows; `tool_advisor` (would-be savings → suggest a tool) | no meal SITUATION (home / workplace / packed), no lunchbox / cold-pack requirement, no "freeze the packs" step, no cold-hours safety prior |
| Prep vs eating time | `StepMethod(base_min, per_100g_min, skill_floor, attended, tool_name, duration_fidelity)` × `SKILL_FACTORS` (novice 1.3 / intermediate 1.0 / experienced 0.8, "refined per person from observed durations" — stated, never built); `resolve_method` (tools × time × skill, refusals named); `derive_week_plan` (batched pre-prep sessions, ACTIVE minutes the score); `IntakeRecord(time_hhmm)`; cal-4 meal-prep = a flat 15-min prior | no EATING duration, no per-person observed durations, one scalar skill instead of skills, no "final prep from this pre-prep" computation feeding the meal-prep event |
| Situations | slots (breakfast … snack), `MealTemplate.slots_json` | no situation vocabulary tying place + portability + reheat availability to a meal |
| The spine | cal arc: `EventDefinition`, `CalendarDefinition` layers, `CalendarEvent(person_name, linked_*, payload_json)`, `EventTrigger` → `SolutionDefinition` (AnalysisCall → GenerateEvent), `coordinate_week` | the analyses below plug into the SAME coordination |

Nothing here needs a new engine, a new display kind, or a new trigger
source. It needs **eight object classes, five analyses, and a handful
of cited priors** — and every number is a labeled knob.

## 2. Object model (all wrapping; per-object, CRUDE for free)

```
PersonSchedule            "when and where a person is committed"
  person_name, kind ∈ work | commute | school | sleep | care | other
  recurrence (schedule field — the base type: weekdays 09:00–17:00,
              sleep 23:00–07:00 crossing midnight)
  location_kind ∈ home | workplace | away | transit
  location_name (SourceLocation.name when it is a place with lat/lon)
  flexibility_min (how far it may move — 0 = fixed)
  is_prior, provenance_id, notes
  → EventDefinition 'person-schedule' (schedule_field=recurrence, all
    kinds) drawn as a BACKGROUND layer on mealplan-week; sleep is a
    PersonSchedule, not a special case

SleepPreference           the digestion spacing, per person (a knob)
  person_name, bedtime_hhmm, wake_hhmm (defaults from the sleep
  PersonSchedule), dinner_to_sleep_min (DEFAULT 120 — Dustin
  2026-09-02: "people can configure their own sleep preference but
  default to 2 hours"; the citation below says ~3 h, so the row
  carries both: the default is the product's, the citation is the
  literature's, and the person's own number wins),
  late_snack_ok, stated_reason
  → coordinate_week places dinner ≤ bedtime − dinner_to_sleep_min and
    FLAGS (never blocks) an entry that violates it: "try to make
    meals that do not make this condition worse" — his posture
  Citation for the prior: ACG clinical guideline (Katz 2022) /
  NIDDK GERD lifestyle guidance — avoid lying down within ~3 h of a
  meal; the existing REFLUX_WINDOW_H (2.5 h, meal↔exercise) is the
  sibling row. Comfort heuristic, general population, not treatment.

HouseholdMember           who is in the household and what they do
  household_name, person_name, role ∈ adult | teen | child | guest
  purchase_participation ∈ always | rotate | never | driver-only
  prep_share_weight (1.0), meal_prep_share_weight (1.0)
  can_drive, has_workplace_meals (bool), notes
  (HouseholdProfile.member_names_json stays; members become rows)

WorkloadType              the DISTINCT kinds of meal-prep work (Dustin
  2026-09-02: "distinguish between the different workload types")
  — a seeded, user-authorable vocabulary: purchase-trip, put-away,
  pre-prep (batch cooking), meal-prep (final prep), packing,
  cleanup; display_name, description, default_skills_json

WorkDistributionPolicy    the configurable split — one per workload type
  household_name, workload_type (WorkloadType.name)
  mode ∈ everyone | rotate | shares | assigned | delivery
  shares_json  {person_name: percent}  — "distribute workloads as
     PERCENTAGES" (must sum to 100 for mode=shares; a person absent
     from the map has 0 %); share_tolerance_pct (PRIOR 10 — how far
     the optimiser may drift from the targets to save total work)
  assigned_person, rotation_order_json
  delivery_fee, delivery_markup_pct, delivery_min_order, delivery_lead_days
  labor_value_per_hour (PRIOR — the household's own number; '' = do
     not monetise time), travel_min_per_trip, travel_cost_per_trip
  → assign_work(): the ALLOCATION — every step of every generated
    purchase / pre-prep / meal-prep / packing event is given to a
    person so that TOTAL person-minutes is minimised (a step's
    minutes = the method's time × the assignee's factor for the
    skills that step needs), subject to availability (mlg-1) and the
    percentage targets within share_tolerance_pct; the result shows
    BOTH the pure-minimum allocation and the share-respecting one
    with the minutes each costs, and the purchase-vs-delivery
    COMPARISON row (trip time × people × labor value + travel vs fee
    + markup) — never a decision

WorkLedger                what actually happened (from events marked
  done or logged): household_name, person_name, kind, minutes,
  event_name, date → the fairness readout ("Alex 70 % of pre-prep
  this month") + a rebalance SUGGESTION; never auto-reassigns

MealSituation             the vocabulary (user-authorable, seeded)
  name ∈ at-home | at-workplace-cold | at-workplace-reheat | packed-
     no-cooling | travel | outdoor | guest…
  eaten_at ∈ home | workplace | away, reheat_available (bool)
  needs_container (KitchenToolDefinition.name, e.g. insulated-lunchbox)
  needs_cold_pack (bool), cold_pack_count, cold_hours_required (PRIOR,
     cited: FSIS "Keeping bag lunches safe" — perishables ≤ 2 h above
     40 °F; an insulated bag + frozen gel packs holds until lunch)
  pack_minutes (PRIOR), pack_when ∈ night-before | morning

MealLogistics             a MealEntry's situation (NO MealEntry schema
  change — the seed-field gotcha): entry_name, situation_name,
  person_name (who eats it where), container_tool_name,
  cold_pack_count, pack_when, is_prior, notes
  → the coordination generates: 'pack' events (pack_minutes before
    leaving = the PersonSchedule commute/work start), 'freeze-packs'
    the night before (a StorageActionDefinition-style step), and
    asks the tool inventory for the lunchbox / cold packs (missing =
    NAMED, tool_advisor pattern)

SkillDefinition + PersonSkill   SKILL PROFILES (decision 13; Dustin
  2026-09-02: "higher skill levels equate to faster meal prep times
  per skill type")
  SkillDefinition: name (knife-work, heat-control, baking, pressure-
     cooking, packing, …), display_name, description, is_prior
  PersonSkill: person_name, skill_name, level ∈ SKILL_LEVELS,
     speed_factor (PRIOR from SKILL_FACTORS by level — novice 1.3 /
     intermediate 1.0 / experienced 0.8 — REFINED per person × skill
     from DurationObservation, fidelity labeled)
  StepMethod gains skills_json [{skill, floor}] — "adding skills
     needed for particular steps" is a row edit (authorable); the
     single skill_floor stays as the fallback; a CookingTaskDefinition
     may also declare default skills for its task kind
  → resolve_method / prep_time_profile use the PERSON's factor for
    THAT step's skills (the slowest required skill governs); the
    allocation (assign_work) uses the same factors to find who is
    fastest at each step

KITCHEN SAFETY — the skill that BOUNDS speed (Dustin 2026-09-02:
"we should not be encouraging people into being overconfident and
rushing in a way that would compromise food safety or personal
safety (increase odds of burns, cutting yourself, etc)")
  SkillDefinition 'kitchen-safety' (personal safety: knives, hot
     surfaces/oil/steam, pressure, lifting) and 'food-safety'
     (FSIS clean / separate / cook / chill) are seeded FIRST-CLASS
     skills every person has a level for (default novice — the
     honest default, not a judgement)
  StepMethod gains safety_floor_min (the minutes a step needs to be
     done SAFELY at any skill — deglazing, draining boiling water,
     handling raw poultry, pressure release) and hazard_tags_json
     (knife | hot-oil | steam | pressure | raw-meat | heavy)
  SafetyRule rows (cited priors, authorable): hazard_tag →
     required kitchen-safety / food-safety level, supervision rule
     (a person below the floor may do the step only with a
     'supervised' flag, never alone), FSIS temperature / time rules
     (cook-to temperatures, the 2-hour rule, cool-before-store)
  → the optimiser's time for a step is max(method × factor,
    safety_floor_min): being skilled makes a step faster ONLY down
    to its safety floor, never below; a speed_factor is NEVER
    refined below 0.7 from observations ("observed faster than the
    floor" is reported as a SAFETY QUESTION, not as skill); hazard
    steps go only to people at or above the SafetyRule floor (else
    'supervised' or unassigned + NAMED); the readout wording is
    "skilled, not fast" — no "hurry", no countdowns; food-safety
    windows (FSIS rows) stay HARD constraints the allocation cannot
    trade away for minutes

DISHES + CLEANUP — a workload with STRATEGIES, not an afterthought
(Dustin 2026-09-02: "timing and strategies for doing dishes and
workloads for that in addition to just cooking")
  DishStrategy vocabulary rows (seeded, authorable): wash-as-you-go
     (in unattended windows), batch-after-meal, soak-then-wash,
     dishwasher-when-full (needs the 'dishwasher' KitchenTool; cycle
     minutes + unload minutes), rinse-and-stack-for-later; each with
     minutes priors per LOAD UNIT and the tool it needs
  Load estimate: the tools/pans/containers the planned steps use
     (StepMethod.tool_name + pack containers + plates per eater) →
     load units per session / per meal; put-away minutes
  Household knob: HouseholdDishPolicy (strategy per workload type —
     pre-prep sessions vs meals; dishwasher present; who, via the
     same WorkDistributionPolicy 'cleanup' shares)
  → dish_plan(): cleanup events placed in the scheduler's UNATTENDED
    windows first (a 20-min simmer is a free dish window — the
    StepMethod.attended flag already exists), else after eating
    (eating block end + a cool-down prior), dishwasher runs as
    duration events (cycle) with an unload event; assigned through
    assign_work like any workload; the fairness readout counts
    cleanup minutes as work (they are)

DurationObservation       the refinement loop the design promised
  person_name, kind ∈ prep-step | final-prep | eating | packing,
  method_name / entry_name / slot, observed_min, date, source
  → per-person factors REFINED from observations (median of ≥ 3,
    else the prior, fidelity labeled 'estimate' | 'observed')

MealTimeProfile           eating time, per person × slot (PRIORS:
  breakfast 15, lunch 30, dinner 40, snack 10 min — no literature
  worth citing; labeled household priors, refined by observations)
```

## 3. Analyses (AnalysisCall rows) and how the coordination grows

| Analysis | Reads | Proposes |
|---|---|---|
| `availability_windows(person, from, to)` | PersonSchedule recurrences → busy blocks; free windows; location at any time | the free/busy timeline + "where is X at 12:30 on Tuesday" |
| `meal_timing_check(plan, week)` | SleepPreference, PersonSchedule, MealEntry times, the reflux/late-meal rows | per-entry verdicts: dinner→sleep gap (minutes, vs prior), meal inside a work block at home (impossible → situation must be packed), late large meal flag; suggested times (never applied) |
| `prep_time_profile(entry, person)` | StepMethod × PersonSkill × DurationObservation, StorageAction durations (reheat/assemble from pre-prep), MealTimeProfile | final-prep minutes (from THIS pre-prep), eating minutes, fidelity per number; tools + skills needed; missing NAMED |
| `portability_plan(plan, week)` | MealLogistics/MealSituation, PersonSchedule locations, KitchenTool inventory | pack events, freeze-packs events, container/cold-pack needs, missing tools |
| `safety_check(steps, people)` | SafetyRule, PersonSkill (kitchen-safety, food-safety), StepMethod hazard_tags / safety_floor_min, FSIS rows | per-step floors + who may do it (alone / supervised / not yet); the minutes the floors add back; any refinement that would go below the floor reported as a safety question |
| `dish_plan(sessions, meals, household)` | DishStrategy, HouseholdDishPolicy, KitchenTool (dishwasher), StepMethod.attended windows, MealTimeProfile (eating end) | cleanup events in unattended windows first, else after eating; dishwasher run + unload events; load units + minutes per event |
| `assign_work(events, household)` | WorkloadType, WorkDistributionPolicy (shares %, tolerance), HouseholdMember, PersonSkill factors, StepMethod skills, availability windows, WorkLedger | per-STEP assignees minimising total person-minutes within the share targets; the pure-minimum vs share-respecting allocations with their minutes; per-person totals vs their % target; purchase-vs-delivery comparison; fairness readout |

`coordinate_week` (cal-4) becomes the caller of all five: it already
orders purchase → pre-prep → meals → meal-prep; it will (1) size the
meal-prep block per person from `prep_time_profile` instead of the
15-min prior, (2) add eating blocks (so the calendar shows "cook
18:15, eat 18:30–19:10"), (3) move/flag dinner by `meal_timing_check`,
(4) insert pack / freeze-packs events from `portability_plan`,
(5) stamp assignees from `assign_work`. Triggers: PersonSchedule /
SleepPreference / MealLogistics / policy rows changed → re-coordinate
(object triggers, cooldown), plus the existing Sunday schedule.

## 4. Phases

- **mlg-0 — this plan.** ✅
- **mlg-1 — schedules & sleep.** PersonSchedule, SleepPreference,
  the `person-schedule` EventDefinition as a background layer,
  `availability_windows`, `meal_timing_check` (dinner→sleep gap with
  the cited prior; late-meal flag rides the existing chrononutrition
  row), coordinate_week moves/flags dinner. Seeds: demo-alex works
  weekdays 09:00–17:00 at 'demo-workplace' (a SourceLocation),
  sleeps 23:00–07:00; demo-bo (2nd adult) works shifts. Selftest.
- **mlg-2 — prep-vs-eating time, skills, SAFETY, tools.**
  SkillDefinition (incl. kitchen-safety + food-safety) + PersonSkill
  + StepMethod.skills_json / safety_floor_min / hazard_tags_json,
  SafetyRule rows (cited FSIS + burn/cut prevention priors),
  `safety_check`, DurationObservation + refinement (median-of-3,
  floor 0.7, below-floor observations → safety question),
  MealTimeProfile, `prep_time_profile` (max(method × factor, safety
  floor)); the meal-prep event sized per person, an eating block
  added; the IntakeRecord CRUD dialog gains "how long did it take"
  (two numbers) → DurationObservation rows. Selftest incl. the
  refinement loop flipping fidelity AND refusing to go below the
  floor, a novice kept off a hot-oil step (supervised), FSIS windows
  unbreakable by the optimiser.
- **mlg-2b — dishes + cleanup.** DishStrategy vocabulary,
  HouseholdDishPolicy, load estimate from the planned steps' tools +
  eaters, `dish_plan` (unattended windows first, then after eating;
  dishwasher cycle + unload events), the 'cleanup' WorkloadType
  wired into shares + the fairness readout. Selftest: a 25-min
  simmer absorbs the session's dishes; a household without a
  dishwasher gets batch-after-meal; the cleanup minutes appear in
  the ledger.
- **mlg-3 — situations & portability.** MealSituation vocabulary
  (seeded, authorable), MealLogistics per entry, the lunchbox /
  cold-pack KitchenToolDefinitions + the FSIS-cited cold-hours prior,
  `portability_plan` → pack + freeze-packs events, missing tools
  NAMED (tool_advisor pattern). Selftest.
- **mlg-4 — work split & cost shift.** WorkloadType vocabulary,
  HouseholdMember, WorkDistributionPolicy (everyone / rotate /
  shares % / assigned / delivery, share_tolerance_pct),
  `assign_work` = the allocation: per-step assignees minimising
  total person-minutes through the skill profiles, within the %
  targets; both allocations reported with their minutes; the
  purchase-vs-delivery comparison; WorkLedger from done events +
  the fairness readout (actual % vs target %) and rebalance
  SUGGESTION. Selftest: the 2-adult "both always shop" case, the
  delivery case, pre-prep shares 70/30 where the 30 % person is the
  faster knife-worker (the optimiser gives them the chopping and
  the other the unattended simmering, and the report names the
  minutes saved vs a naive split), tolerance exceeded → named.
- **mlg-5 — pages.** mealplan-week gains the background schedule
  layer + assignee colouring; a `/display/mealplan/household` page:
  members, policies, ledger/fairness, situations, tools, sleep
  preferences — all configured tables (the no-JSON rule);
  meal_timing_check verdicts and the delivery comparison as
  structured panels. Headless + real-browser pass.
- **mlg-6 — refinement (optional).** Per-person method preferences
  by skill; commute-aware purchase trip placement (the trip's
  SourceLocation vs the workplace: "shop on the way home"); a
  household calendar export (ICS) — needs no new engine.

## 5. Decisions (recommended defaults in bold)

| # | Question | Recommend |
|---|---|---|
| D1 | Where schedules live | **PersonSchedule rows with a `schedule` recurrence; sleep is a PersonSchedule kind** (one vocabulary, one expander, one background layer) |
| D2 | Dinner→sleep spacing | ✅ **RATIFIED 2026-09-02: default 120 min, each person configures their own** (SleepPreference row); the ACG/NIDDK "~3 h" guidance stays as the citation on the row (shown beside the default, not silently swapped); sibling of REFLUX_WINDOW_H; verdict FLAGS + suggests, never blocks; posture text on every payload |
| D3 | Members | **HouseholdMember rows** (member_names_json kept for compatibility) |
| D4 | Work split modes | ✅ **RATIFIED 2026-09-02 (shares as PERCENTAGES per workload type): everyone / rotate / shares % / assigned / delivery — one policy row per WorkloadType** (purchase-trip, put-away, pre-prep, meal-prep, packing, cleanup — authorable) |
| D13 | Allocation objective | ✅ **RATIFIED: minimise TOTAL person-minutes using per-person, per-skill speed factors, within the % shares ± share_tolerance_pct (prior 10); show the pure-minimum and the share-respecting allocations side by side with their minutes** |
| D15 | Safety bounds speed | ✅ **RATIFIED 2026-09-02: kitchen-safety + food-safety are first-class skills; step time = max(method × factor, safety_floor_min); factors never refined below 0.7; hazard steps only at/above the SafetyRule floor (else supervised / unassigned, NAMED); FSIS windows are hard constraints; wording "skilled, not fast"** |
| D16 | Dishes are work | ✅ **RATIFIED 2026-09-02: DishStrategy vocabulary + HouseholdDishPolicy; dish_plan fills unattended windows first, else after eating; dishwasher runs are events; cleanup minutes count in shares and fairness** |
| D14 | Skills on steps | ✅ **RATIFIED: StepMethod.skills_json (per method) + CookingTaskDefinition default skills; a person's PersonSkill.speed_factor per skill (level prior, refined from observations); the slowest required skill governs a step** |
| D5 | Valuing time | **labor_value_per_hour is the household's own knob; '' = compare minutes only, never invent a wage** |
| D6 | Delivery | **a cost SHIFT row (fee, markup %, min order, lead days); purchase-vs-delivery shown as a comparison, the policy mode decides** |
| D7 | Situations | **MealSituation vocabulary rows (seeded, authorable); MealLogistics per entry (no MealEntry schema change)** |
| D8 | Cold-chain prior | **FSIS bag-lunch guidance: perishables ≤ 2 h unrefrigerated; insulated bag + frozen gel packs; cold_hours_required per situation, cited, confidence 'transcribed'** |
| D9 | Skills | ✅ **RATIFIED (skill profiles): SkillDefinition + PersonSkill(level, speed_factor); StepMethod.skills_json; cooking_skill stays the fallback** |
| D10 | Eating time | **MealTimeProfile priors (15/30/40/10 min) labeled household priors; refined from DurationObservation (median of ≥ 3)** |
| D11 | Final-prep time | **computed from the pre-prep actually planned (reheat/assemble steps × person factor), replacing the 15-min prior; fidelity labeled** |
| D12 | Fairness | **WorkLedger readout + rebalance SUGGESTION only; never auto-reassign** |

## 6. Open questions (short)

1. ~~D2's prior~~ — ANSWERED: default 2 h, per-person configurable.
2. Should a 2nd demo adult (demo-bo) be seeded so the split /
   rotation cases render on the demo week?
3. Delivery: model a specific service's fee schedule, or the three
   knobs (fee, markup %, min order)?
4. Do we want the workplace as a SourceLocation (lat/lon) so
   "shop on the way home" (mlg-6) can use distance?

## 7. Standing rules that bite here

- No diagnosis: spacing meals from sleep is a comfort heuristic with
  a citation and a confidence, worded "do not make it worse".
- Never reward rushing: skill shortens a step only to its safety
  floor; food-safety windows are never traded for minutes; the
  optimiser's language is "skilled, not fast".
- Every time/cost number a labeled prior; observed beats prior only
  with ≥ 3 observations; fidelity shown.
- Wrap what exists (schedule type, StepMethod, SKILL_FACTORS,
  StorageActionDefinition, KitchenTool, CalendarEvent, triggers);
  no MealEntry schema change (seed-field gotcha).
- Licence gate: FSIS / ACG / NIDDK guidance are public-domain or
  citable; no new dependencies.
- Branch per phase (`dev-mlg-1..5` off dev-cal-1); selftests;
  TESTING_OWED rows; his push ritual.
