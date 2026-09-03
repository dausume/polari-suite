# Calendars, events, and no-code event logic (cal arc)

**Date:** 2026-09-02 · **Status: cal-1..5 BUILT + DEPLOYED to staging
the same day (branch `dev-cal-1` in framework AND angular, UNCOMMITTED
— his push ritual). D1–D13 ratified with the recommended defaults
("those all sound good go agead").**

> **BUILT (2026-09-02):** cal-1 object model (`EventDefinition`,
> `CalendarDefinition`, `CalendarEvent` [span = datetime_duration,
> recurrence = schedule], `EventTrigger`, `TriggerFiring`,
> `AnalysisDefinition`), `polariNoCode/recurrence.py` (dateutil
> rrule), `calendar_events.py` (resolution, honest unresolved
> counts), `/api/calendar/*` (calendars, events window, definitions +
> temporal fields, preview, schedule expand, triggers, fire, firings).
> cal-2 node family in the engine (GenerateEvent [eventsFrom batch,
> dedupeBy], ModifyEvent, CancelEvent, ScheduleOccurrences,
> EventWindowQuery, AnalysisCall [pick]) + `event_dispatcher.py`
> (object hook on publish_crude_change, emitted-event chaining from
> engine.execute with max_depth, schedule/window tick thread
> POLARI_EVENT_TICK_S, every firing a row). cal-3 `embeddedCalendar`
> (FullCalendar; layers toggle; click → CRUD dialog; drag → confirm →
> CRUDE PUT for span/start-backed layers; derived starts refuse by
> name) registered beside embeddedTable/Graph. cal-4 nutrition:
> `BulkStaple` (+12 FoodKeeper-cited demo staples on the 1/3/6/12
> cadences), `purchase_analysis.py` (weekly purchase, bulk proposals
> with savings + shelf-life refusal, week coordination purchase →
> pre-prep → meals → meal-prep), `calendar_seed.py` (4
> EventDefinitions, `mealplan-week` calendar, 3 analyses, 3 no-code
> solutions, 8 triggers, first coordination fired at seed). cal-5
> front door = the calendar + today + events/intake tables + bulk
> knobs; planner gained coordination + triggers/firings tables.
> LIVE: 18 events on the demo week (5 meals, purchase, pre-prep,
> 5 meal-preps, 4 intakes, 2 weights), 8 triggers, the seed firing
> audited, headless front door: FullCalendar rendered, 0 errors.
> Selftests: recurrence 16/16, calendar_events 12/12,
> event_triggers 15/15, purchase 19/19, pages 7/7; regressions green.
> REMAINING (TESTING_OWED §5): TS parity vectors / palette metadata
> for the six backend-only nodes, Events + Calendars class-page tabs,
> `schedule` editor cell, real-browser drag/click pass, household
> override rows for the time priors, FoodKeeper verification.

> **The sample he set (verbatim, drives cal-4):** "as a sample we
> should make weekly reoccurring purchase events for food, we should
> also do periodic in bulk purchase events at 1 month, 3 month, 6
> month, and yearly periods that can serve as ways to buy stuff like
> rice or grains in bulk that last very long periods without decay,
> and can act as a means to save money over time. So we should be
> able to determine and coordinate between purchase events, bulk
> purchase events, cooking pre-prep events, and pre-meal prep events
> (ideally shorter if possible)."
> → cal-4 gains: `purchase` (weekly, the plan's priced shopping gap
> minus bulk-covered stock), `bulk-purchase` (1/3/6/12-month
> schedules over long-shelf-life staples — shelf life a CITED prior
> per food, savings = bulk vs retail observed $/kg over the period),
> `pre-prep` (batch cooking sessions from the prep scheduler, placed
> AFTER the purchase that supplies them), `meal-prep` (the short
> per-meal steps right before each meal, minimized by the scheduler).
> The COORDINATION is an analysis over the plan week (purchase →
> pre-prep → meal → meal-prep ordering, bulk coverage first) whose
> proposals a no-code solution turns into events.

## 0. Direction (Dustin 2026-09-02, verbatim — treat as the ask)

> "Okay we should try and simplify this process for the average user
> as well, make a calendar, we should have configurable calander and
> event capabilities. (If we do not we may have to make them) and we
> are going to want the main page of the meal planning app to be
> focused around that"

> "we should wrap what exists when defining the new object model and
> expanding the capabilities. We should define the capability to
> define events and tie object definitions to datetime events
> durations, and make no-code capabilities for generating events and
> modifying events or triggering events based on other things
> happening so we can use no-code to make our event logic."

Read as: (a) an **EVENT DEFINITION capability** — any object class
declares how its instances are events (which fields are the start,
the end or duration, the title, the recurrence); (b) **calendars** as
a configured display kind composed of those event definitions;
(c) **event logic in no-code** — generating, modifying and triggering
events are engine nodes, and "something happened" (an object changed,
an event fired, a time arrived) is a trigger that runs a
SolutionDefinition; (d) the meal-planning front door becomes that
calendar; (e) every piece **wraps** an existing Polari mechanism.

## 1. Audit — what exists, and what each new piece wraps

**His expectation, checked (2026-09-02): "datetime events and
durations should already be a defined class in the base version of
polari, calendars and events which tie together particular kinds of
data with datetimes."** What base Polari HAS is the temporal **field
types**: `date`, `datetime`, `date_duration`, `datetime_duration`,
`time`, `time_duration`, `schedule` — a duration is ONE field whose
stored value is `{"start": ISO, "end": ISO}` (TEXT column), the
calendar popup already reads that shape, and the filter chains know
`durationGreaterThan/LessThan`. So any object can already CARRY a
datetime event or a duration as a field. What base Polari does NOT
have, on any branch (`git grep` across all refs): a Calendar class,
an Event class, or a definition that ties a KIND of data to its
datetime field. Those are the tying layer this arc adds — and every
value they hold is one of the existing field types, never a new
value shape.

| Existing piece | State (verified 2026-09-02) | Wrapped by |
|---|---|---|
| Temporal FIELD TYPES `date, datetime, date_duration, datetime_duration, time, time_duration, schedule` — durations stored as `{start, end}` JSON; frontend vocabulary in `PolariFieldType.ts` (icons, labels, filter ops) | ✅ in the typing system (`createClassAPI.py`, `polariDataTyping/dataTypes.py`); editable cells for date/time; **no editor for `schedule`** (crud-dialog maps it to null) | EventDefinition points at these fields; `CalendarEvent.span` IS a `datetime_duration` field and `CalendarEvent.recurrence` IS a `schedule` field; the `schedule` editor cell (cal-3) |
| `ScheduleDefinition.ts` | ✅ RFC-5545-style recurrence JSON (frequency/interval/byDay/byMonthDay/byMonth/bySetPos/startTime/endTime/rangeStart/rangeEnd/durationDays); **no expander anywhere** | the `schedule` payload everywhere; expander = `dateutil.rrule` (python-dateutil 2.9.0 IS in the image; Apache-2.0/BSD-3 dual — GPLv3-compatible) |
| FullCalendar 6.1.20 + `calendar-view-dialog` | ✅ MIT; popup only (table header button on datetime columns), read-only | `embeddedCalendar` reuses the dialog's option builder — ONE calendar engine (the sci-xy-chart rule) |
| Per-object definitions (`TableDefinition`, `GraphDefinition`, tabs on the class page, `embeddedTable/Graph`, upsert + boot repoint) | ✅ the display route ([[per-object-display-config]]; mealplan_pages_seed is the freshest example) | `EventDefinition`, `CalendarDefinition`, Events + Calendars tabs, `embeddedCalendar` |
| No-code engine: `SolutionDefinition` (Python + TS mirror, parity 69/69), loops, `SolutionInvocation` contracts, `StateChangeCommit` (**update only** — create/delete explicitly deferred to "the data-access node family"), `EmitEvent` / `EmitFrontendEvent` terminals (`{name, payload, sourceState, channel}` in `_emitted_events`), `displayEvents$` bus, real forms/buttons (P4) | ✅ | THE event-logic unit. New nodes are engine handlers + palette entries + parity vectors (or backend-only tags), per the standing rule |
| `graph_compilers` (GraphCompilerDefinition, `compile_with`, `advance()` — "many small complete runs, domain owns persistence") | ✅ ncg-1 seam, judicial + circuits ride it | every trigger firing = ONE complete run via `advance()`; no pause/resume needed |
| CRUDE lifecycle hook `polariCRUDE._notify_ws_subscribers` → `grpcbridge.transport_mux.publish_crude_change(manager, class, op, ids)` (create/update/delete per class; never raises) | ✅ | the OBJECT trigger source: the dispatcher subscribes here |
| P6 catalog items never built: "event subscribe/trigger (other half of EmitEvent)", "timers", "data-access CRUD nodes" | ❌ | exactly this arc's node family + dispatcher |
| Meal-planning rows with time: `MealPlanDefinition(start_date, days)`, `MealEntry(day_index, slot, time_hhmm)`, `IntakeRecord(date, slot, time_hhmm)`, `ActivityLog(date, start_hhmm, duration_min)`, `CookingWorkflow` prep sessions, `WeightObservation(date)` | ✅ | cal-4 EventDefinitions — no schema change |

Nothing else is missing. The engine, the field types, the recurrence
model, the lifecycle hook and the definition route all exist; this
arc adds **five object classes, one node family, one dispatcher, one
display component, two tabs and one editor cell**.

## 2. Object model (all treeObjects; CRUDE for free; seeded via upsert)

```
EventDefinition          "instances of <class> ARE events"  (per object class)
  name, description, source_class, is_default_event
  title_field            e.g. template_name
  span_field             a `date_duration`/`datetime_duration` field ({start,end}) — OR —
  start_field            a date/datetime field   — OR —
  relative_start_json    {baseClass, baseNameField, baseDateField, offsetField, offsetUnit}
                         (MealEntry: plan.start_date + day_index days)
  time_field             optional HH:MM field joined onto a date start
  end_field | duration_field + duration_unit   (ActivityLog: duration_min)
  all_day  (bool | field)
  schedule_field         a `schedule`-typed field → recurring occurrences
  category, color_field | color_map_json, filter_json
  slot_times_json        labeled prior {breakfast:'08:00', lunch:'12:30', dinner:'18:30', snack:'15:00'}

CalendarDefinition       the DISPLAY kind (beside TableDefinition/GraphDefinition)
  name, description, source_class (optional), is_default_calendar
  definition = {calendarConfig: {layers: [{eventDefinition, visible, color}],
                defaultView, editable, weekStart, timeRange, filters}}

CalendarEvent            the generic instance event (the "average user" object)
  name, title, calendar_name, person_name, household_name,
  span (`datetime_duration` field — the base {start,end} type; an
  instant = start only), all_day, recurrence (`schedule` field — the
  base recurrence type), category, color,
  linked_class, linked_name, status (planned|done|cancelled),
  generated_by (EventTrigger name or ''), is_prior, provenance_id, notes

EventTrigger             "when X happens, run solution Y"   (the no-code hook)
  name, description, enabled
  source_kind ∈ object | event | schedule | window
    object:   {class, operations:[create|update|delete], field_filter}
    event:    {eventName, channel}        (an EmitEvent from any run)
    schedule: {schedule: <ScheduleDefinition JSON>}  (a time arrives)
    window:   {eventDefinition|calendar, relation: starts|ends, withinMinutes}
  solution_name          the SolutionDefinition to run (contract = trigger payload)
  cooldown_s, max_depth, run_as, last_fired, fire_count

TriggerFiring            every firing is a ROW (object-coherence; never silent)
  trigger_name, fired_at, source_ref, occurrence_key (idempotency),
  execution_id, status, outcome_json, error
```

Events API: `GET /api/calendar/{calendar}/events?from&to[&person]`
→ FullCalendar EventInput[] from every layer (mapped rows + recurring
occurrences + CalendarEvent rows); rows whose start cannot be resolved
are COUNTED and NAMED in the payload, never silently dropped.
`GET /api/events/definitions/{class}`; `POST /api/events/preview`
(a definition draft against live rows → what it would produce, no
write). Writes never happen in these routes — they go through CRUDE
(the UI, with confirm) or through the no-code nodes (the logic).

## 3. No-code event logic — the node family + the dispatcher

Node family (engine handlers; each ships parity vectors for BOTH
engines or is tagged backend-only in `capability.ts`):

| Node | Kind | Wraps |
|---|---|---|
| `EventTriggerEntry` | initial state; context = the trigger payload (object snapshot / emitted event / occurrence / window hit) | the entry-state registry (P1 fix pattern) |
| `GenerateEvent` | creates a CalendarEvent (or a row of any class with an EventDefinition) — the FIRST real create path | `StateChangeCommit`'s commit path, changeType='create', scoped to event-bearing classes first, generalised later (P6 item 3) |
| `ModifyEvent` | update start/end/status/fields of an event or its linked row | `StateChangeCommit` update |
| `CancelEvent` | status=cancelled (soft) — hard delete stays a human CRUDE act | `StateChangeCommit` update |
| `ScheduleOccurrences` | schedule JSON + window → list of occurrences (feeds the EXISTING ForEach loop) | `dateutil.rrule` expander |
| `EventWindowQuery` | events of a definition/calendar in [from, to] → list | the events API |
| `EmitEvent` (exists) | chains triggers (source_kind=event) | — |

Dispatcher (backend, `polariNoCode/event_dispatcher.py`):
1. **object** triggers — subscribed at `publish_crude_change` (one
   hook, never raises into CRUDE);
2. **event** triggers — reads `_emitted_events` off every completed
   execution (depth guard like SolutionInvocation's 16; cooldown);
3. **schedule** + **window** triggers — a tick thread (knob
   `POLARI_EVENT_TICK_S`, default 60; only the instance holding the
   core DB ticks under [[shared-object-db]] — a knob, stated);
   occurrences are idempotent by `occurrence_key` on TriggerFiring.
Each firing = `graph_compilers.advance()` — one complete run, its
context persisted on the TriggerFiring row; failures are rows with
the error text, and a disabled trigger refuses with a plain reason.

## 4. Phases

- **cal-0 — audit + plan** (this doc). ✅
- **cal-1 — object model + events API.** The five classes (core,
  beside the definitions), the `dateutil` expander (+ a schedule
  → occurrences selftest table incl. bySetPos/last-Friday/once+
  duration), EventDefinition resolution (fields / relative start /
  time join / duration / all-day / schedule), the events window API
  + definition preview, upsert seeds. Selftests over every
  meal-planning class mapping and the honest missing-date counts.
- **cal-2 — no-code nodes + dispatcher.** The node family above +
  engine handlers + palette entries (+ TS parity vectors or
  backend-only tags), EventTrigger/TriggerFiring runtime with the
  four source kinds, depth/cooldown guards. Selftests: object
  trigger → solution → GenerateEvent round trip through the REAL
  engine; schedule trigger idempotency; event chaining hits the
  depth guard with a plain error; every firing audited; Turing +
  composition + parity suites stay green.
- **cal-3 — frontend.** `embeddedCalendar` (FullCalendar; reuses the
  dialog's option builder), registered beside embeddedTable/Graph;
  click → existing crud-dialog on the linked row; drag/resize →
  confirm → CRUDE PUT; **Events** tab (EventDefinition config, field
  pickers limited to temporal fields from classTypeData, live
  preview) and **Calendars** tab (layer composition) on
  class-main-page, mirroring the Graphs tab; a `schedule` editor
  cell wrapping `ScheduleDefinition.ts`; EventTrigger rows edited in
  crud-dialog, their logic in the EXISTING no-code editor with the
  new palette nodes. Pages selftest pattern for the embed/repoint.
- **cal-4 — meal-planning events + triggers (seeded, all knobs).**
  EventDefinitions: `meal-plan-entry` (MealEntry, relative start +
  slot_times prior, color by slot), `intake` (IntakeRecord),
  `activity` (ActivityLog, duration_min), `prep-session`
  (CookingWorkflow sessions as blocks), `weight` (all-day dots),
  `household-events` (CalendarEvent). CalendarDefinition
  `mealplan-week` with those layers. Seeded example TRIGGERS as
  no-code solutions (his rule: proposals, never nags): (i) plan
  created/updated → (re)generate its week of meal events; (ii)
  MealEntry moved → ModifyEvent; (iii) schedule 20:30 daily → if no
  dinner IntakeRecord today, GenerateEvent "log dinner?" (status
  planned; the person closes it); (iv) prep session → prep-block
  events. Each trigger a row, each firing audited.
- **cal-5 — the front door.** `/display/mealplan` = `mealplan-week`
  calendar across 12 segments with the layer toggles, a "today"
  strip (day rollup chips vs bands, warning chips naming symptoms —
  nmp-8's spec) and three quick actions as EXISTING no-code forms
  (add meal from template → MealEntry; log what I ate →
  IntakeRecord; add event → CalendarEvent). Plans/links/pantry
  tables move to planner/pantry. Per-person via `?object=`
  (`{object}` substitution already works); anonymous = honest
  banner + demo.
- **cal-6 — optional.** Recurrence editing polish, generic
  `CreateInstance`/`DeleteInstance` nodes (finishing P6 item 3),
  reminders/notifications = NAMED GAP (no push infrastructure).

## 5. Decisions (recommended defaults in bold)

| # | Question | Recommend |
|---|---|---|
| D1 | Event model | **both**: EventDefinition-mapped rows (no duplication) + CalendarEvent for free-form/generated events |
| D2 | Where the classes live | **core** `polariApiServer` beside Table/GraphDefinition (calendars are a display kind; events + triggers are generic); the node family + dispatcher in `polariNoCode` |
| D3 | MealEntry date | **plan.start_date + day_index; time = time_hhmm else slot_times prior** (labeled; household-overridable) |
| D4 | Writes from the calendar UI | **confirm dialog → CRUDE; plan gates re-run and SHOW warnings, never block** |
| D5 | Ownership | **events carry person/household; page filters by the Keycloak-linked person; anonymous = demo + honest banner** |
| D6 | Engine | **FullCalendar (MIT) — the one calendar engine; premium plugins ⛔** |
| D7 | Recurrence expander | **`dateutil.rrule`** (already in the image) |
| D8 | Front-door composition | **calendar 12-wide + today strip + quick actions; analytics move** |
| D9 | Time zone | **local naive date/time as today; tz = named gap** |
| D10 | Trigger sources | **object · event · schedule · window** — the four in §2; webhooks/external I/O stay P6 |
| D11 | Trigger authority | **triggers run backend-trusted as DEFINER (P3 contract executionRights) and say so on the TriggerFiring row; P6 auth nodes gate them later** |
| D12 | Create path | **dedicated `GenerateEvent/ModifyEvent/CancelEvent` wrapping StateChangeCommit's commit path** now; generic Create/DeleteInstance in cal-6 |
| D13 | Scheduler | **one tick thread, 60 s default knob, core-DB holder only; idempotent by occurrence_key** |

## 6. Standing rules that bite here

- Licence gate: FullCalendar MIT ✓, python-dateutil dual Apache/BSD
  ✓; ⛔ NC = hard blocker; no new dependencies otherwise.
- Per-object definitions from the object's page; embed by reference;
  ids repointed by name at boot; upsert seeds; no JSON on screens.
- New node families ship parity vectors for BOTH engines or are
  declared backend-only; Turing 16/16, composition 12/12, parity
  69/69 stay green after every phase.
- Every firing/generation is a row with provenance; disabled =
  plain refusal; proposals, never nags; every default a labeled knob.
- Branch per phase (`dev-cal-1..5`); selftests + TESTING_OWED row;
  his push ritual.

## 7. Open questions (short)

1. D2 core vs a `calendar` module (a module would make calendars an
   app-store install; core makes them a Polari primitive).
2. D3 slot-time defaults — confirm/adjust the four prior times.
3. D11 — comfortable with backend-trusted triggers until P6 auth
   nodes land? (They are rows, audited, disable-able.)
4. Should cal-4's seeded triggers include pantry expiry events
   (needs a cited shelf-life table → licence gate)?
