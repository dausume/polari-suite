# Next-session handoff: meal planning + acid management

> **✅ 2026-09-02 (late) — NO-JSON SWEEP OF EVERY MODULE PAGE + hh-1
> HOUSEHOLD EXTRACTION + geocode/explorer frontend (agents; dev-mlg-1,
> UNCOMMITTED).** (1) 50 seed pages / 191 api-structured-panels / 0
> api-json-panel in the tree (module_pages_seed, climate, computers,
> cntfet incl. the explorer's view descriptors, sifet, appstore,
> islemesh, open-library, fet-detail); live rows converged by
> `polari-cli/shells/backfill-module-pages.sh` (re-runnable; ends by
> listing any live page still carrying a json panel — expect 0);
> headless on nutrition / profile / recipes / cntfet / sifet /
> vermicompost / plant-morphology / a score page: pre=0 unrendered=0.
> (2) `modules/household/` extracted from nutrition's logistics layer,
> names unchanged, nutrition re-exports everything (no importer
> changed), `requires: household`, `pol topology assign household
> prf-a` done, `household.selftest_household` 27/27, all nutrition +
> no-code suites unchanged — HOUSEHOLD_APP_PLAN.md §3a. D1–D10 still
> gate hh-2. (3) CRUD dialog "Find coordinates from address" (any
> class with latitude+longitude+address) + fet-characteristic explorer
> honours componentName/pick/hideKeys; frontend bundle main.e53bd9db
> rolled. (4) The me page after the cache fix: DailyIntakeMetric holds
> both logged days, weekly cache skips unlogged buckets — 26 graphs /
> 4 forms / 12 tables, 0 errors. DEPLOY: the backend image carrying
> the sweep seeds + household must roll via the STACK DEPLOY (item 3
> below: both env pins) so POLARI_MODULES picks up household — see the
> "deploy state" line at the end of this block, updated when it lands.
> Ledger: TESTING_OWED §9. Pre-existing, not ours:
> `moduleService.selftest_lazy_imports` 14/15 (cntfet stub tuples).
> DEPLOY STATE: LANDED 23:09 2026-09-02 — stack deploy (both env pins) → POLARI_MODULES carries household; backend cap 1024M→1536M (the 1024M task was OOM-killed, exit 137, during the backfill sweep; see deploy memory); live: HouseholdMember 2 / PersonSkill 12 / WorkDistributionPolicy 6 rows, 4 AnalysisDefinitions on household.household_analysis, portion-fit objective knob answering (chicken-bowl-dinner: nutrients objective ×0.85/×0.80 vs calories-only ×1.2, driver named), 69 calendar events / 15 triggers, backfill reports 0 json panels on any live page, headless mealplan / household / me / week / nutrition/profile / open-library / a cntfet detail page: pre=0 unrendered=0 json=0; frontend bundle main.e53bd9db (geocode button + explorer descriptor).

> **✅ mpt (My tracking) + mps (Food Supply map) BUILT + DEPLOYED
> 2026-09-02 (dev-mlg-1, UNCOMMITTED).** `/display/mealplan/me?object=
> <person>`: week/month means per logged day vs the person's lines,
> "consistently too much / too little" (sweets = GL + carbs; no sugars
> column), log-intake + log-weight forms, 13 charts across day/week/
> month (7 period GraphDefinitions over the PeriodIntakeMetric cache,
> filtered by series_key '<person>:<kind>'), Create-New tables.
> `/display/mealplan/supply`: the new `embeddedMap` (GeoJsonDefinition
> by name → map-renderer) over SourceLocation pins + places/prices
> tables + best $/kg + purchase/bulk proposals. The pages inventory,
> the Household home design and the next views to build:
> `AI-Notes/designs/HOUSEHOLD_APP_PAGES.md`. Owed (TESTING_OWED §8):
> browser submission of the log forms; geocoding on Create New.

> **✅ mpc WEEK PLANNING BUILT + DEPLOYED 2026-09-02 (his two asks +
> the portioning ask; dev-mlg-1, UNCOMMITTED):** new pages
> `/display/mealplan/meals?object=<person>` (nav "Meals for me") and
> `/display/mealplan/week` (nav "Plan the week"): meals ranked per
> person, the slots they eat, templates + variations, the "Add to the
> week" no-code FORM (any slots × any days → MealEntry rows through
> GenerateEvent; already-planned cells NAMED, never overwritten;
> per-person PORTIONS in serving_split_json fitted to each member's
> calorie target and clamped to the variation's bounds, the
> compromise stated), the coverage grid that says whether the week
> is planned (front door shows the headline). Live: 10/18 planned on
> the demo plan; 0 errors, no JSON. Owed (TESTING_OWED §7): a real-
> browser click of the form; nutrient-aware portion optimisation.

> **➡️ NEXT ROUND: THE HOUSEHOLD APP (hh) — PLANNED 2026-09-02 (his
> "go ahead" on the plan), awaits ratification of D1–D10.**
> `AI-Notes/plans/HOUSEHOLD_APP_PLAN.md`: refactor-first — hh-1
> extracts a `household` module (schedules/sleep, members, percent
> shares, ledger, skills + safety, refinement, allocation, fairness,
> dish strategies) out of nutrition with names unchanged (live rows +
> callable refs converge via upsert; nutrition requires household;
> publish polari-module-household), then hh-2 chores + laundry
> (cycles as unattended windows, chemical/ladder hazards), hh-3
> supplies (pantry + bulk-cadence pattern), hh-4 the 'household' app
> + pages, hh-5 done→WorkLedger + duration prompts + a global
> allocation knob. Open: one app or two siblings; robot/washer as
> demo tools; kids' chores supervised by default.

> **✅ MEAL LOGISTICS mlg-1..5 BUILT + DEPLOYED 2026-09-02 (his go;
> branch `dev-mlg-1` off dev-cal-1, framework only, UNCOMMITTED).**
> New page `/display/mealplan/household` (nav: Meal Planning →
> Household & Work): schedules (background layer on the calendar),
> sleep spacing (his 2 h default, per person), members + percent
> shares per workload type + delivery comparison, the allocation
> (fastest safe free person within shares; both allocations shown),
> fairness, situations + packing (lunchbox / cold packs, FSIS-cited),
> skill profiles with SAFETY floors + rules ("skilled, not fast"),
> prep-vs-eating profiles, refinement (never below 0.7), dish
> strategies + plan. `coordinate_week` v2 generates eating, packing
> and cleanup events with assignees; any logistics row change
> re-coordinates through the triggers. Selftest 26/26 (TESTING_OWED
> §6). REMAINING: WorkLedger auto-write from done events, "how long
> did it take" prompts, real-browser pass, TS parity/palette for the
> event nodes (cal-3 remainder).

> **(done) ➡️ NEXT ROUND: MEAL LOGISTICS (mlg) — PLANNED 2026-09-02, awaits
> his ratification.** `AI-Notes/plans/MEAL_LOGISTICS_PLAN.md`:
> people's work/sleep schedules as PersonSchedule rows (schedule
> recurrence, background calendar layer) + SleepPreference (dinner→
> sleep prior 180 min, ACG/NIDDK-cited, flags never blocks); household
> members + WorkDistributionPolicy (everyone/rotate/weighted/assigned/
> delivery with fee/markup/min-order; labor value = the household's
> own knob) + WorkLedger fairness readout; MealSituation +
> MealLogistics (workplace, insulated lunchbox, cold packs, FSIS
> bag-lunch prior; pack / freeze-packs events); SkillDefinition +
> PersonSkill + DurationObservation refinement + MealTimeProfile so
> final-prep and EATING time are per person; five analyses feeding
> coordinate_week. Phases mlg-1..5, D1–D12. Open Qs: his 3-h number,
> seed a 2nd adult, delivery model, workplace as SourceLocation.

> **✅ CALENDAR + EVENTS ARC cal-1..5 BUILT + DEPLOYED 2026-09-02
> (ratified same day; branch `dev-cal-1` in framework + angular,
> UNCOMMITTED — his push ritual).** The front door
> /display/mealplan IS the calendar now (embeddedCalendar over the
> seeded `mealplan-week` CalendarDefinition: planned meals, generated
> purchase / bulk-purchase / pre-prep / meal-prep events, intake,
> activity, weight — layer chips, click → CRUD dialog, drag → confirm
> → CRUDE PUT). Event logic is NO-CODE: 8 seeded EventTrigger rows →
> 3 SolutionDefinitions (AnalysisCall → GenerateEvent(eventsFrom) →
> EmitEvent) → CalendarEvent rows, every firing a TriggerFiring row
> (visible on the planner page). His sample: weekly purchase
> (Saturday 10:00), bulk purchases monthly/3/6/12-month on the 1st
> over 12 FoodKeeper-cited staples (shelf life refuses a too-long
> cadence), coordination purchase → pre-prep → meals → short
> meal-prep. Live probes: /api/calendar/mealplan-week/events = 18
> events; /api/calendar/triggers = 8; the seed's first coordination
> firing audited; headless front door 0 errors. Full state + gotchas:
> CALENDAR_EVENTS_PLAN.md (top block), TESTING_OWED §5, memory
> calendar-events-arc. ⚠ Deploy ritual unchanged (build image +
> `docker service update --force`; admission ~10 min); the tick
> thread runs on the backend (POLARI_EVENT_TICK_S=60).

> **(done) ➡️ NEXT ROUND OPENS ON THE CALENDAR (Dustin 2026-09-02: "make a
> calendar, we should have configurable calander and event
> capabilities … the main page of the meal planning app to be
> focused around that"). Plan = `AI-Notes/plans/CALENDAR_EVENTS_PLAN.md`
> (cal-0 audit DONE: FullCalendar MIT already vendored + popup
> dialog + temporal types + recurrence model with NO expander;
> MISSING CalendarDefinition / embeddedCalendar / Calendars tab /
> CalendarEvent / /api/calendar). His refinement the same day: WRAP
> what exists; EVENT DEFINITIONS tie object classes to datetime +
> duration fields; event generation/modification/triggering = NO-CODE
> (EventTrigger rows → SolutionDefinitions; node family wrapping
> StateChangeCommit/EmitEvent/dateutil; dispatcher on the CRUDE
> lifecycle hook + emitted events + a tick). Ratify D1–D13 → cal-1
> on `dev-cal-1`.**

> **✅ NO-JSON ROUND 2026-09-02 (after the browser pass). Dustin, on
> seeing the pages: "there should not be any json showing on the
> screens, everything should be configured tables, graphs, or
> visualizations" · "look at how we do configuration of those
> already in polari, do not create new custom code" · "they should
> be embedded into displays that are put into the app pages".**
> Built + DEPLOYED + verified headless (5 pages: `<pre>`=0,
> "unrendered fields"=0, table-load errors=0, console errors=0):
> - `polariApiServer/mealplan_pages_seed.py` REWRITTEN the Polari
>   way: 17 **TableDefinition** rows (one per meal-planning class —
>   MealPlanDefinition, MealEntry, PantryItem, UnitWeightPrior,
>   SourceLocation, PriceObservation, IntakeRecord, UserAccountLink,
>   WeightObservation, DailyIntakeMetric, PersonExclusion,
>   StatedCondition, ConditionSteering, PlanBudget, WasteRecord,
>   MealRating + a NutrientContent view; ColumnConfiguration shape,
>   instance cards, defaults for the class pages) embedded via
>   `embeddedTable` (scoped with filterField/filterValue); the 4
>   trend **GraphDefinition**s via `embeddedGraph` by name; the
>   derived verdicts (cost/coverage/budget/acidity/state chain…) via
>   the registered `api-structured-panel` with `pick`/`hideKeys`
>   tuned so nothing reaches its JSON expander. Item counts: 20
>   embedded tables, 4 charts, 27 structured panels; 0 api-json-panel
>   / class-rows-table.
> - Seeded through **composition.seed_upsert** (`seed_mealplan_pages`
>   wired in polariServer beside seed_motors_pages, nutrition-gated)
>   with boot-time **id repoint** (motors pattern) — the pages now
>   CONVERGE on edit; the mealplan entries were REMOVED from the
>   insert-by-name lists; the interim backfill script was deleted.
>   Live boot log: TableDefinition +17, DisplayDefinition ~5,
>   repointed 20.
> - `modules/nutrition/selftest_mealplan_pages.py` (7/7): allowed
>   components only, embeds name seeded definitions of the right
>   class, columns EXIST on the class (constructor signature),
>   repoint resolves every embed on a fake node.
> - ONE frontend fix in existing code (angular dev, UNCOMMITTED):
>   `class-data-table.initializeFromNamedConfig` falls back to the
>   TableDefinition's configured column `dataType` when no class
>   schema is present — display-page embeds showed "(unknown)" on
>   every header (motors pages had it too). Rebuilt + rolled
>   (bundle main.34eaa239…).
> - Backend: image rebuilt + `docker service update --force`
>   (admission ~10 min).
> ⚠ **FOLLOW-UP HIS RULE IMPLIES (not done):** 36 OTHER live pages
> still carry `api-json-panel` (the 6 nutrition/* app pages in the
> SAME nav — nutrition-home/profile/meals/recipes/activity/garden
> from module_pages_seed — plus vermicompost/tanks/biomining/
> microalgae/waxsupply/supplychain/morphology/zones/app-store/
> isle-mesh/computers/open-library/cntfet-*/sifet-home/fet-detail).
> Route = the same recipe: TableDefinitions per class + embeddedTable,
> structured panels for verdicts, and (the gotcha) those seeds are
> INSERT-BY-NAME — either adopt the upsert path per module (as here)
> or backfill. The nutrition six are the natural next slice.
> Trivial `{object}` upgrade available: display-page substitutes
> `{object}` in inputs, so these pages can become per-person /
> per-plan (`?object=`) instead of demo-hardcoded.
> UNCOMMITTED now: framework (mealplan_pages_seed.py, polariServer.py,
> selftest_mealplan_pages.py), angular (app-routing.module.ts,
> class-data-table.ts), this doc. Live DB: 17 TableDefinition rows,
> ModuleAssignment polariapps@prf-a.

> **✅ BROWSER PASS EXECUTED 2026-09-02 (fresh `claude --chrome`
> session — the extension STILL refused to attach ("Browser
> extension is not connected"; Chrome + native host both running),
> so the pass ran through HOST HEADLESS CHROME: real Chromium
> screenshots + DOM dumps + `--enable-logging=stderr` console per
> page — see memory chrome-browser-tools). All 7 items PASS after
> three fixes; 0 console errors on all 5 pages in the final run.**
>
> Findings + what was done (fix ritual followed):
> 1. ⛔→✅ **/display/mealplan/{planner,pantry,market,trends} did not
>    ROUTE** — Angular's `display/:id` matches ONE segment, so every
>    nested pageRoute (the 4 mealplan + 6 nutrition/* pages) threw
>    NG04002; only /display/mealplan worked. Fix (angular dev,
>    UNCOMMITTED): `displayPageMatcher` UrlMatcher in
>    app-routing.module.ts joins `display/a/b/…` into :id='a/b/…'
>    (DisplayPage already matched `isPage && pageRoute === id`).
>    Built `pol node build frontend --env staging` + `docker service
>    update --force --image prf-frontend:staging polari-node_frontend`
>    → bundle main.c46e5333…; all 11 nested pages load.
> 2. ⛔→✅ **polariapps was NOT in POLARI_MODULES on prf-a** →
>    /api/apps/nav 404 → no 'Meal Planning'/'Kitchen' dropdowns.
>    `pol topology assign polariapps prf-a` (row) then the stack
>    deploy below; nav now carries both groups + all 11 links.
> 3. ✅ **Frontend pin is now IN THE STACK SPEC** (the open item):
>    deployed with `CNTFET_ENGINES_URL=http://<pol-core LAN address>:9700
>    POL_STACK_CONSTRAINTS="backend=node.labels.polari.machine==pol-core
>    frontend=node.labels.polari.machine==pol-core" pol swarm deploy
>    node` — ⚠ a bare `pol swarm deploy node` DROPS
>    CNTFET_ENGINES_URL (rendered env diffed vs live before deploy;
>    that was the only other delta). Backend re-admitted in ~9 min.
> 4. ⛔→✅ **Live page rows were BEHIND the seed** (INSERT-BY-NAME
>    gotcha again): planner lacked exclusion/condition/budget/
>    protein-per-$ panels, pantry lacked waste ledger + quick-add,
>    trends lacked coverage steering + declared exclusions. New
>    `polari-cli/shells/backfill-mealplan-pages.sh` (PUT-diff-verify,
>    same pattern as backfill-cntfet-pages.sh; graphs included)
>    backfilled 3 pages, 4 graphs already identical. RE-RUN IT after
>    any page-seed edit until DisplayDefinition rides an upsert path.
> 5. ✅ **THE SEAM HOLDS**: all four embeddedGraph charts render
>    through Observable Plot with the date-STRING x-axis (ticks
>    2026-08-31 / 2026-09-01; weight scatter 08-25…09-01). Cosmetic
>    only: a FLAT series (GL 16.1 both days, acid share 0) yields a
>    single y tick printed '6.100000'/'0.000000' — 6-decimal format +
>    left-margin clipping of '16.100000'. Fix lives in the graph
>    renderer's y-tick format for degenerate domains; not the data.
> 6. Checklist values confirmed on screen: Me = honest refusal;
>    dashboard demo-alex; rice 2000 g / eggs 400 g; best chicken
>    demo-grocery 13.21/kg; dozen eggs 600 g $3.79; budget = $25.71
>    cap for the 3 plan days (the $60/wk envelope pro-rated) with
>    $18.30 headroom; posture text visible on condition flags.
> 7. Observations, not fixed: (a) 10 parallel headless loads once
>    produced `ChunkLoadError: Loading chunk 2753` (serial re-run
>    clean, chunk serves 200) — proxy under burst, watch for it;
>    (b) one run showed the "Certificate Trust Required" modal for
>    https://localhost:2096/cert-trust — the trust check read the
>    build-time backend default before runtime-config applied (1 of
>    ~15 loads); a real-browser repro would make it worth ordering
>    the check after configLoaded.
> UNCOMMITTED (his ritual): angular app-routing.module.ts (dev),
> polari-cli/shells/backfill-mealplan-pages.sh, this doc. Row
> change: ModuleAssignment polariapps@prf-a (live DB).
> Screenshots of the final pass are session-scratch only.

> **(superseded by the block above) ➡️ BROWSER PASS HANDOFF (2026-09-02, for a FRESH `claude
> --chrome` session — Dustin: "do a handoff with a fresh chrome").
> Everything is BUILT + DEPLOYED + 34/34 live-probed; this pass is
> the last verification. Execute:**
>
> 1. Open https://prf.<pol-core LAN address>.nip.io/display/mealplan — the
>    front door. Expect: Me panel (anon = honest refusal),
>    dashboard demo-alex, plans + account-links tables.
> 2. /display/mealplan/planner — entries table, rollup vs
>    thresholds, cost, pantry coverage, stock suggestions, prep
>    schedule, exclusion screen, condition flags (posture text
>    visible), budget envelope ($60/wk demo cap), protein-per-$.
> 3. /display/mealplan/pantry — lots + resolved stock (rice
>    2000 g, eggs 400 g), unit-weight priors, shopping list, waste
>    ledger, quick-add preview.
> 4. /display/mealplan/market — locations w/ lat/lon, price
>    observations, $/kg compare (best = demo-grocery chicken
>    13.21/kg), dozen-eggs purchase preview (600 g, ~$3.79).
> 5. /display/mealplan/trends — **THE SEAM: the four embeddedGraph
>    charts** (calories + weight side by side, then GL + acid
>    share). These ride the NEW graphName input; the date STRING
>    x-axis through Observable Plot is the one thing no suite or
>    probe could exercise — if a chart is blank/garbled, the fix
>    is in graph-renderer's dimension handling (angular), NOT the
>    data. Also: series panel (metricCache cached:true), day
>    panel, acidity, the PSPP state chain.
> 6. Check the nutrition-planner nav (top bar 'Meal Planning' +
>    'Kitchen' dropdowns; side menu groups) interconnects all 5
>    pages + the 6 nutrition pages.
> 7. Console: read_console_messages pattern 'error|Error' per page.
> 8. Fix ritual for frontend findings: edit angular (dev), `pol
>    node build frontend --env staging`, then `docker service
>    update --force --image prf-frontend:staging
>    polari-node_frontend` (the service now carries the pol-core
>    pin; ⚠ the STACK SPEC still lacks it). Backend findings:
>    build backend + `docker service update --force --image
>    prf-backend:staging polari-node_backend` (admission up to
>    ~14 min, poll before worrying).
> 9. Chrome-bridge note: 2026-09-02 debugging showed the bridge
>    would NOT attach to resumed sessions on this box even with
>    --chrome (extension 1.0.85→1.0.90 staged update; native host
>    respawns fine). Use a FRESH chrome window + FRESH
>    `claude --chrome` (new session, read this handoff) rather
>    than --continue.

> **AUDIT EXECUTED 2026-09-02 (his go: "make that repo and bind it
> also merge all to dev and merge the fg stack… go with the
> optional improvement… automating"):** ✅ polari-module-foodstate
> CREATED + bound + subtree pushed (the last repo:'' module —
> every official module now has a public repo); ✅ framework
> dev-mpa-1 → dev (ff, +25,840 lines incl. vendor CSVs) and
> angular dev-mpa-1 (fg stack + embeddedGraph) → dev; ✅ stale
> subtrees re-published (nutrition, polariapps); ✅ pointer chain
> rolled innermost-first (rf-node 69dabe6, suite 35ea602); ✅ the
> optional improvement AUTOMATED: foodstate/export_initial_data.py
> generates initialData/{FoodMaterial,PropertyClaim}.json from the
> seed builders (curated tables only; FDC-derived claims stay with
> nutrition's CSV) with a drift-guard selftest (14/14).
> ⚠ STILL HIS: `push-all-dev.sh --push` (framework/angular/
> rf-node/suite dev → origin — module repos are current but origin
> dev is behind them until the sweep) + the browser pass.
>
> (original audit findings below, now executed:)
> 1. ⛔ **polari-module-foodstate does NOT exist on GitHub**
>    (registry repo:"" — the ONLY module of 42 without a repo;
>    `git ls-remote` confirms 404). `pol modules get foodstate`
>    refuses honestly; fix = `pol modules publish foodstate` (+
>    commit the repo URL into modules/polari-modules.json) — HIS
>    GO, it creates a public repo (the pspp precedent).
> 2. ⛔ **dev (the publish source) carries NONE of the food work**:
>    modules/foodstate ABSENT on dev (0 files; registry entry too),
>    modules/nutrition = 15 files on dev vs 84 on dev-mpa-1, and
>    **modules/nutrition/vendor/ (the sha-pinned FDC/R6/METs CSVs)
>    is NOT on dev at all** — so the PUBLISHED
>    polari-module-nutrition currently lacks the vendor data AND
>    all nmp/mpa/mpb code. Nothing new is downloadable until
>    dev-mpa-1 (which contains dev-nmp-1 + dev-fsp-1) MERGES to
>    dev, then `push-all-dev.sh` re-publishes the stale subtrees
>    (it tree-hash-compares HEAD:modules/<m> vs each repo main;
>    empty-repo entries are silently `continue`d — foodstate needs
>    finding 1 first or the sweep skips it forever).
> 3. ⚠ **angular dev-mpa-1 (embeddedGraph graphName) unmerged**
>    (10 commits incl. the fg stack): a frontend built from dev
>    renders the seeded chart panels as an error box ('No graph
>    config ID provided'). Merge framework+angular TOGETHER.
> 4. ⚠ `pol modules get` clones ONE module (requires[] only guards
>    `drop`): getting foodstate alone leaves nutrition/pspp to
>    fetch separately — import refuses honestly, but the app-store
>    install of nutrition-planner (now requiring
>    nutrition+aquaponics+foodstate+pspp) should be verified after
>    publish.
> 5. ✓ Everything else checks out: framework tree clean, all 13
>    initialData JSONs tracked (gitignore exemptions correct),
>    vendor CSVs tracked on the branch, polari-cli clean+committed
>    (suite pointer roll = his ritual), registry requires edges
>    correct (foodstate→pspp+nutrition). Live-only state (frontend
>    node pin, ModuleAssignment rows, user data rows) survives
>    restarts via DB/volumes but NOT a full purge — by design.
> 6. Optional improvement: expose the non-regenerable FDC identity
>    mapping + pH/acid tables as modules/foodstate/initialData/*.json
>    per the module-data convention (today GET /modules/{nutrition,
>    foodstate}/initial-data 404s; data still ships via the repo).

> **UPDATE 2026-09-01 (round 2 — mpb): HIS RATIFICATION verbatim:
> "we should not be doing diagnosis in any way, what we can say is
> 'try to make meals that do not make this condition worse', all
> of the rest sounds good." ALL EIGHT buildable mpb phases BUILT
> same session on dev-mpa-1 (plan §3b; 28-suite battery green):
> exclusions (FDA major-9, declared, swap-aware) · condition
> steering (do-not-worsen flags over existing cited rows; posture
> on every payload) · nutrient-per-$ + budget envelope · waste
> ledger · rolling coverage + exclusion-safe cheapest closers ·
> plan-fed trajectory · ratings-rank · quick-add grammar. 11 new
> /api/mealplanning routes + app-page panels.
> REMAINING: REDEPLOY this round (backend image rebuilt at session
> end — roll + re-probe), composer rank-integration of
> conditions/ratings, price-trend/buy-low (needs observation
> history), trip distance, mpb-5 child-DRI transcription round.**

> **UPDATE 2026-09-01 (day 2) — THE MEAL-PLANNING APP IS BUILT
> (mpa-0..6, branch `dev-mpa-1` = dev-fsp-1 + dev-nmp-1 merged in,
> per ratified D7 "stacked"; dev itself untouched, his nmp review
> gate stands). Plan: `AI-Notes/plans/MEAL_PLANNING_APP_PLAN.md`
> (his two 2026-09-01 asks verbatim in §0; assumed defaults A1–A7
> in §3 — flag them to him).**
>
> What exists now, all suite-green (23 suites):
> - **fsp-2 v1** (mpa-0): foodstate/food_transforms.py — mass
>   balance + R6 retention; model rungs refuse (I5);
>   `template_state_chain` = meal properties as pspp claims,
>   1%-agreement guard vs the nmp rollup.
> - **meal acidity** (mpa-1): FDA/CFSAN-lineage pH claims
>   (VERIFIED-vs-TRANSCRIBED labeled per row), acid mass share vs
>   21 CFR 114 pH≤4.6 → the decision-9 tolerance row; NO combined
>   meal pH by design.
> - **market** (mpa-2): SourceLocation (lat/lon), PriceObservation
>   → $/kg, UnitWeightPrior approximate weights; purchase preview
>   assigns weight+nutrition+cost.
> - **pantry** (mpa-3): stock vs plan demand, priced shopping list
>   (unpriced NAMED), plan cost, stock-aware suggestions (never
>   auto-edit).
> - **accounts+tracking** (mpa-4): UserAccountLink (Keycloak sub/
>   username/email → person; NO silent provisioning), IntakeRecord,
>   day rollups + date series (nutrition/GL/acid-share/weight; gap
>   days NAMED).
> - **the app** (mpa-5/6): /api/mealplanning (13 routes), 5
>   interconnected /display/mealplan* pages, demo plan
>   demo-alex-week, nutrition-planner nav groups; polariServer
>   fully wired (imports/stubs/defClassList/both seed passes).
>
> **DEPLOYED 2026-09-01 (same session): 21/21 LIVE PROBES PASS** —
> modules assigned (pol topology assign pspp/foodstate/nutrition/
> composition prf-a → 16-module POLARI_MODULES), both images
> rebuilt from dev-mpa-1 trees, `pol swarm deploy node`
> (admission ~14 min — poll longer than 12 min before worrying).
> Probes covered every foodstate + mealplanning route, the live
> metric-cache upsert, and the seeded Graph/Display rows.
>
> ⚠ **DEPLOY FINDING (live-only, fixed in-session):** `pol swarm
> deploy node` did NOT roll the frontend (unchanged spec + tag-only
> image = no restart); a manual `docker service update --force`
> then BOUNCED it onto other swarm nodes (its
> .generated/prf-runtime-config.json bind exists only on pol-core)
> — Rejected loop, update paused. Fixed live with
> `--constraint-add 'node.labels.polari.machine==pol-core'` +
> force; now Running on the new bundle (main.dcf9e8ab…). 🔑 The
> constraint is LIVE-ONLY: the rendered stack spec still lacks the
> frontend pin — add it (pol allocate / stack render) or the next
> deploy can bounce again.
>
> **REMAINING (his gates + next round):** the BROWSER pass over
> /display/mealplan* (chart date-x-axis = the untested seam) —
> NOT possible this session: the Chrome extension was not
> connected; relaunch with `claude --chrome` (memory
> chrome-browser-tools) to run it;
> (superseded → deploy notes kept for the ritual: image build +
> service update,
> NEVER docker cp) → browser pass (live findings expected); the
> embeddedGraph-by-name fix IS DONE (mpa-7: graphName input +
> mealplan-weight-trend chart) AND the derived-series gap is
> CLOSED (mpa-8: DailyIntakeMetric derive-on-demand cache + 3
> trend charts on /display/mealplan/trends — reading /series
> refreshes the cache rows the charts read); fsp-2
> remainder (cited gelatinization/denaturation calibrations);
> **fsp-3 SLICE BUILT same session** (food_chemistry.py: HH
> speciation over VERIFIED pKa, exact TA, buffer REFUSES; tomato
> citric/malic claims from Agius 2018; the tomato-chain ACCEPTANCE
> PASSES 21/21 — remainder: buffer calibration, measured-TA rows,
> acids for more foods; chemistry is LIVE: backend re-rolled same
> session, speciation + tomato acidity answer 200 [TA 3.79
> meq/100g], full 21-probe battery re-passed); fsp-4/5;
> nmp merge review; publish polari-module-foodstate (registry
> repo:"" — the pspp lesson).

> (previous update) **2026-09-01 (night) — fsp-0 BUILT; that round = fsp-1 (the
> base-ingredients database, his ask verbatim: "start putting
> together a database of common base ingredients") + nmp refinement.**
>
> State: fsp direction + D1–D8 ratified; **fsp-0 built** on framework
> `dev-fsp-1` (bd23a04, off dev, NOT merged): `modules/foodstate/` —
> food stages/processes/evidence-methods as PSPP rows (zero-schema-
> change proven, selftest 14/14), FoodDomainContract ×5,
> `/api/foodstate/contracts|vocabulary`. pspp re-verified (35/35
> suites) and PUBLISHED (polari-module-pspp; registry URL on dev
> 6a62e72). ⚠ foodstate registry repo:"" — publish with the next
> sweep. ⚠ pspp + foodstate NOT in POLARI_MODULES on prf-a — assign
> both before live verification.
>
> **NEXT ROUND OPENS ON fsp-1 — the common-base-ingredients database**
> (plan §4 fsp-1, sharpened 2026-09-01):
> 1. FoodMaterial identity rows for a starter roster of COMMON BASE
>    ingredients (nmp decision 8: meals build STRICTLY from base
>    ingredients + meats, so this roster IS the meal-planning
>    vocabulary): staples across grains, legumes, vegetables, fruits,
>    meats/eggs/dairy, oils/fats, and the flavor bases (onion,
>    garlic, tomato…) — roster size ~60–100, HIS trim/extend.
> 2. Each ingredient: hand-curated FDC mapping (name → fdc_id +
>    dataset edition — non-regenerable, so it belongs in
>    `modules/foodstate/initialData/` per the module-initial-data
>    convention) → composition CLAIMS on the canonical
>    `<material>#as-defined` state (FDC CC0; provenance 'measured'/
>    'literature' with the FDC citation), incl. the fsp-0 contract
>    extensions: water first-class, starch/sugar split, organic acids
>    per species where FDC/literature carries them (D4 scope).
> 3. Ties: nutrition nut-2 FoodItem rows link to the same identities
>    (harvest loop keeps working); nmp recipes will resolve
>    ingredients against this roster (fsp-6).
> 4. Selftest + the contracts report showing per-ingredient coverage
>    HONESTLY (which contract quantities each ingredient actually
>    has vs refuses).
>
> **Meal-planning refinement queue (parallel/after)**: his gates on
> dev-nmp-1 (merge review, GUI pass on the 5 pages, live-API pass,
> profile data — TESTING_OWED §000); open Qs (wger mine-vs-run, URL
> import timing, trajectory horizon + household privacy, Q5 pattern
> fractions); named gaps (child DRI bands, added-sugar/fiber gate
> caps, fat rendering, household splits, coverage ScoreConcept).
> Acid-arc refinements ride fsp-3/fsp-5, not a separate system.

## (original 2026-08-31 planning-round content below)
(prepared 2026-08-31 night; Dustin: "shift back to meal planning and
acidic management … start our planning next round". Microchip arc TABLED —
its own entry point is MICROCHIP_LADDER_NEXT_HANDOFF.md.)

**This is a PLANNING round, not a build round** — the deliverable is a
ratifiable plan (phases + decisions), per the working style.

> **ANSWERED same night (2026-08-31): reading 1 — dietary/gastric —
> AND the architecture direction came with it: food as PSPP-style
> state evolution (FoodMaterial → FoodState DAG; gastric model
> downstream; recipes = process specs). The planning-round output is
> `AI-Notes/plans/FOOD_STATE_PSPP_PLAN.md` (fsp arc) — next round
> opens THERE: settle D1–D7 (D1 substrate = the gating call: reusing
> pspp core requires merging the parked pspp branch stack), then
> fsp-0 on his go. The agenda below is superseded except items it
> shares with the plan's decision table.**

## (superseded) FIRST QUESTION FOR DUSTIN

"Acid management" has three plausible readings in this suite — confirm
which (or which mix):
1. **Dietary acid / reflux management** (most likely — pairs with meal
   planning): the nmp arc already carries threads for this —
   decision 9 (per-meal glycemic-load caps + acid/reflux-trigger rows at
   LOWER labeled confidence) and decision 14 (meal↔exercise comfort/
   reflux windows ~2-3h after large/fatty meals, prep scheduler respects
   them). Planning would grow these into a proper arc: trigger-food
   evidence rows, per-person reflux profiles, meal-plan gating/timing.
2. Aquaponics/tank water chemistry (pH/alkalinity management) — the
   aquaponics + saltwater-food-forest line.
3. Physiological acid-base (CO₂/bicarbonate) — see memory
   `co2-bicarbonate-epistemics` for Dustin's 2026-08-06 epistemics
   corrections (model-vs-relation discipline) if this reading applies.

## Entry state — nutrition meal planning (nmp)

- **nmp-0..11 ALL BUILT 2026-08-20** on framework branch `dev-nmp-1`
  (tip `5e0b4d6`, 11 commits, exists on origin too) — **UNMERGED, his
  review gate**. 12 selftest suites green at build time.
- Plan: `AI-Notes/plans/NUTRITION_MEAL_PLANNING_PLAN.md` (decisions
  1–14 recorded). Underlying nut arc: `HOUSEHOLD_NUTRITION_PLAN.md`
  (nut-1..4 built on dev; **nut-5 fulfillment sim = the headline
  remaining deliverable**, nut-6 Kratky garden after).
- His queue (TESTING_OWED §000, ledger line ~432): merge dev-nmp-1, GUI
  pass on the 5 pages, live-API pass, profile data.
- Clean-stack rule stands: USDA FDC CC0, NASEM DRI, DGA, Compendium
  METs, Hall/Chow from the papers, USDA retention/yields. ⛔ Tandoor
  (AGPL+Commons Clause), FooDB (NC), Monash DB (values-only w/
  citation). Fork-pins exist: dausume/{wger, recipe-scrapers,
  ingredient-parser}.
- Open Qs he never answered (from the plan): wger mine-vs-run; URL
  import timing; trajectory horizon + household privacy default; Q5
  meal-pattern fractions confirm/adjust.

## Suggested planning agenda (next round)

1. Settle the acid-management reading (above) → scope the arc.
2. Decide the merge question first: plan against dev-nmp-1 AS IS
   (stacked branch) or gate planning on his review/merge of nmp.
3. If reading 1: draft the acid arc phases — evidence rows (trigger
   foods, GL, timing; cited, labeled confidence), PersonProfile reflux
   knobs (stated, never inferred), meal-template gate extensions,
   scheduler window tightening — riding the EXISTING nmp machinery
   (thresholds/tolerance/timing), not a new system.
4. Fold in nut-5 (fulfillment sim) sequencing — it is still the
   headline unbuilt piece of the nutrition line.
5. Output: a ratifiable plan doc + decision table; NO code this round.

## Standing rules that bite here

- Every threshold/symptom number = cited, labeled prior (tunable
  ledger, no false precision); general-population only, said plainly
  (nmp decision: NO special conditions modeled — an acid/reflux arc
  must restate its own boundary against medical-advice territory:
  comfort heuristics, not treatment).
- Licence gate before any new data source (⛔ NC = hard blocker).
- Branch per confirmed phase; plans in AI-Notes/plans/; his push
  ritual.
