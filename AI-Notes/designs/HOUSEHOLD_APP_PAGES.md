# The Household app — every page we have, the home page, and the views still worth building

**Date:** 2026-09-02 · Written for Dustin's ask: "Think of other views
or pages that may be useful and what sort of interfaces would be most
useful and intuitive to the average user. Describe all pages we have
so far and describe the home page for the household app and how it
maps to different pages we have." Companion to `HOUSEHOLD_APP_PLAN.md`
(the hh arc) and `MEAL_PLANNING_APP_PLAN.md`.

Every page below is a seeded `DisplayDefinition` made only of
configured tables (embeddedTable over a per-object TableDefinition),
charts (embeddedGraph), the calendar (embeddedCalendar), structured
readings of analyses (api-structured-panel), and no-code FORMS whose
submit runs a seeded solution. Nothing renders raw JSON.

## 1. The pages we have (nutrition-planner app, nav "Meal Planning" / "Kitchen" / "Profile & Tracking")

| Route | What it is for | What is on it | Enter data here |
|---|---|---|---|
| `/display/mealplan` **Home** | the front door IS the calendar | the household week (layers: schedules as background, planned meals, generated purchase / bulk-purchase / pre-prep / meal-prep / eating / packing / cleanup events, intake, activity, weight); "Is the week planned?"; today's coverage steering; dashboard; events table; bulk staples + the yearly bulk proposal | drag an event (confirm → write), click → CRUD dialog; Create New on events / intake |
| `/display/mealplan/week` **Plan the week** | is every meal planned? | headline + the person × day × slot grid with MISSING cells named; per person / per day; the "Add to the week" form; the entries table | the form (meal → any slots × days, per-person portions); edit/delete entries |
| `/display/mealplan/meals?object=<person>` **Meals for me** | meals for ONE person | meals ranked for them; the slots they eat; meals + variations tables; the same "Add to the week" form pre-filled; portion fit per person with the compromise stated; the week's entries | the form; Create New meals / variations |
| `/display/mealplan/me?object=<person>` **My tracking** | ONE person over time | by-week / by-month means per logged day vs their own lines; "consistently too much / too little"; log-intake + log-weight forms; day charts (calories, weight, GL, acid); WEEK charts (kcal, carbs, sodium, GL, acid, protein); MONTH charts (kcal, sodium, weight); intake / weight / period tables; the lines | the two forms; Create New on intake / weight |
| `/display/mealplan/planner` **Planner** | the plan's analytics | entries; rollup per entry; under-target per day; cost; pantry coverage; suggestions; prep schedule + tasks; protein per $; exclusion screen + declared exclusions; condition flags + stated conditions + steering; budget; the coordinated week; triggers + firings; plans; account links | Create New on entries / exclusions / conditions / budget |
| `/display/mealplan/pantry` **Pantry** | what the household has | lots; resolved stock; unit-weight priors; shopping list; waste ledger + records; quick-add preview | Create New lots / waste; the quick-add grammar (preview) |
| `/display/mealplan/market` **Market & Prices** | where and at what price | locations (lat/lon); price observations; $/kg compare; purchase preview; nutrient content of the previewed food | Create New locations / prices |
| `/display/mealplan/household` **Household & Work** | who is where, how the work is split | members; sleep preferences; schedules (background layer); availability; timing verdicts; workload types + distribution policies (percent shares, delivery knobs); this week's allocation (both allocations, shares readout, every step, purchase vs delivery); fairness + ledger; situations + meal logistics; packing plan; skills + profiles; skills per step + safety rules; prep-time profiles; speed refinement + observations; eating time; dish strategies + policy + dish plan | Create New on every knob table |
| `/display/mealplan/trends` **Trends** | the person over time (the first tracking page) | tracking series; one day; day metrics; weights; the four day charts; intake; ratings; acidity; coverage steering; declared exclusions; the PSPP state chain | Create New intake / ratings |
| `/display/nutrition-home`, `/display/nutrition/profile`, `/meals`, `/recipes`, `/activity`, `/garden` | the nmp module pages (Kitchen / Profile & Tracking / Foundations) | profiles + thresholds, meals + templates, recipes + retention, activity, the garden loop | Create New; ⚠ still api-json-panel — the no-JSON sweep is owed |

Machinery pages (Core): `/class-main-page/<Class>` for every object
(Overview · Tables · Graphs · Displays · Maps · …) — where a
TableDefinition / GraphDefinition / EventDefinition is configured;
the no-code editor for the seeded solutions and triggers.

## 2. The Household app home page (hh-4) — one door, four ways in

The average user does not think in modules. They think: **what is
happening today, what do I need to do, what did I eat, what is
running low, who is doing what.** The home page answers those five
in order, and each answer is a door to the page that owns it.

```
┌──────────────────────────────────────────────────────────────────────┐
│  TODAY  (a strip)  Tue 2 Sep · Alex: work 09–17 · Sam: shift 12–20   │
│  next up: 17:50 prep dinner (Alex) · 18:30 eat · 19:20 dishes (Sam)  │  → the calendar rows below / Household & Work
├──────────────────────────────────────────────────────────────────────┤
│  THE WEEK  (embeddedCalendar 'household-week', layer chips)          │
│  meals · purchases · prep · chores · laundry · schedules (bg)        │  → click an event = its row; drag = move (confirm)
├────────────────────┬─────────────────────┬───────────────────────────┤
│ IS THE WEEK PLANNED│ MY TRACKING (chips) │ THE HOUSEHOLD (chips)     │
│ 16 of 18 meals ·   │ this week: kcal ↓,  │ shares on target: pre-prep│
│ 2 missing (day-3   │ sodium ok, GL ok ·  │ 70/30 ✓ · cleanup 40/60   │
│ breakfasts)        │ weight 79.9 → 79.8  │ drift +12 % (Alex) ·      │
│ [Plan the week]    │ [My tracking]       │ 3 supplies low            │  → Plan the week · My tracking · Household & Work
├────────────────────┴─────────────────────┴───────────────────────────┤
│ QUICK LOG (two small forms): "I ate …" · "My weight …"              │  → the same solutions as My tracking
├──────────────────────────────────────────────────────────────────────┤
│ NEXT PURCHASES: Sat 10:00 groceries (2 items, unpriced) · Oct 1 bulk │  → Market & Prices / Food Supply map / Pantry
│ (yearly: rice, pasta, sugar ~$120, saves ~$129)                      │
├──────────────────────────────────────────────────────────────────────┤
│ CHORES DUE (hh-2): vacuum (Sat, Sam) · sheets (Sun) · bathroom (Wed) │  → Chores page
└──────────────────────────────────────────────────────────────────────┘
```

Mapping, top to bottom: **Today strip** ← availability + the
coordinated week; **The week** ← the calendar (every arc's events);
**Is the week planned** ← `/mealplan/week`; **My tracking** ←
`/mealplan/me?object=<me>` (the logged-in person via the Keycloak
link — anonymous shows demo + an honest banner); **The household** ←
`/mealplan/household` (→ `/household/work` after hh-1); **Quick log**
← the `mealplan-log-intake` / `-weight` solutions; **Next purchases**
← the purchase / bulk-purchase events + `/mealplan/market` (+ the
Food Supply map); **Chores due** ← hh-2. Every chip is a structured
panel over an existing analysis; every "[link]" is a nav route —
no new machinery.

Interface rules for the average user (from what the pages already
taught us): one question per panel, the answer first (a headline
chip), the table under it; forms with three to seven fields and a
verb on the button; per-person pages opened from "me" (the login),
not from a picker; anything derived says where the number came from
in one line; nothing blocks — flags name a move.

## 3. Views still worth building (in the order I would do them)

1. **Food Supply map** (his ask, next): a map page centred on where
   food is bought — SourceLocation pins (grocery / farmers market /
   warehouse / workplace) with the best $/kg per food at each pin,
   click → the store's price observations; "shop on the way home"
   reads the workplace pin. Needs an `embeddedMap` wrapper (the
   calendar twin over the existing map-renderer + GeoJsonDefinition)
   — see §4.
2. ✅ BUILT 2026-09-03 (`/display/mealplan/today?object=`) — **Today** (a person's day as a list): eat / prep / pack / leave /
   dishes in time order with one tap "done" (→ WorkLedger + the
   duration prompt). The calendar's list view almost is this; a
   `?object=` page with a `listDay` embeddedCalendar + the two forms.
3. ✅ BUILT 2026-09-03 (`/display/mealplan/shoptrip`) — **Shopping trip** (phone-shaped): the purchase event's lines as a
   checklist by store aisle order (a knob on SourceLocation), prices
   editable in place → PriceObservation rows; "bought" → PantryItem
   lots (put-away).
4. ✅ BUILT 2026-09-03 (`/display/mealplan/cooknow?object=`) — **Cook now** (the recipe at prep time): the meal-prep event's
   steps with the person's minutes per step, the safety notes for
   the hazard tags, a timer per unattended step (the dish window),
   "done" → durations observed.
5. **Household settings** (the knobs in one place, grouped): members,
   shares, sleep, tools owned, situations, dish strategy — today
   spread over Household & Work; a settings page groups them by
   question ("who shops?", "what do we own?").
6. ✅ BUILT 2026-09-03 (`/display/mealplan/review`) — **Weekly review** (Sunday): what was planned vs eaten (coverage vs
   intake), cost vs budget, waste, fairness, the two or three
   "consistently" readings, and the next week's proposals — one page
   the Sunday trigger could also mail/print (ICS/export later).
7. **Recipes as cards** with the retention/yield facts and "add to a
   meal" — the nmp meals/recipes pages exist but are JSON-panel
   pages; the sweep turns them into cards + tables.
8. **Guests & situations**: a date-scoped "we have guests Friday" row
   → portions, purchase lines and packing follow (the situation
   vocabulary already exists).

## 4. Food Supply map — what exists, what is needed

Exists: `SourceLocation(name, kind, latitude, longitude, address,
region_label, household_name)`, `PriceObservation` per location,
`price_report` / `best_price_per_kg`, the demo workplace + warehouse
pins, the geojson stack (GeoJsonDefinition per object,
MapPointDefinition, TileSourceDefinition, geocoder service,
maplibre `map-renderer` with `[config] [instanceData]`), the Maps tab
on the class page. Missing: an `embeddedMap` display component (load
a GeoJsonDefinition by NAME + the class rows, render map-renderer —
the embeddedGraph shape), a seeded GeoJsonDefinition over
SourceLocation (lat/lon fields, label, kind → marker style), and a
page `/display/mealplan/supply`: the map 12-wide, the locations table
(Create New with address → geocoder), the price observations table,
the $/kg compare, purchase proposals, and "nearest store for X".
