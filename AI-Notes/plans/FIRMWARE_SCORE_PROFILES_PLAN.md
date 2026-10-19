# Firmware Score Profiles (fsc) — PLAN, 2026-10-18 (nothing built)

His ask (2026-10-18, quoted): "of our existing solutions we have tried, what is our scoring equation and how did we run it on the devices to find
which solution is ideal? Anything that does not fulfill all purposes is just a failure, but we should be able to have a few different scores for
different desires … cheapest … quickly … other common desired solution configurations and terms … like those in the scorecard … particular
'Mission Solutions/Firmware Solutions' and a page that compares each finished Firmware Solution against Firmware Score Profiles … weight the
scoring from terms ourselves … sample scores like profiling for just the fastest or just the cheapest … one that scores unique to the hardware
and might weight cheapness and fastness per-purpose."

## 1. What exists today (sol-0, `cmod.custom.solve_engine` / `solve_cost`)
- **Two objectives.** The Mission picks one; the other is shown as the secondary column.
  - `minimum-resources` = Σ wₖ·fractionₖ:
    - pins used / header pins (w 3)
    - on-chip blocks / 9 kinds (w 2)
    - parts to acquire, whole units (w 3)
    - part classes / 10 (w 0.5)
    - flash / limit (w 1)
    - RAM / limit (w 1)
    - CPU class / 4 (w 1)

    The weights are knobs (`limits.weights`).
  - `fastest-cycle` = Σ over Purposes of the Purpose cycle in µs. A Purpose cycle runs from the trigger to the last task. A polled trigger adds up to one main-loop pass.
- **Rank key:** rank_class (0 placed + on bench · 1 parts missing · 2 a deadline violated · 3 a Purpose lost · 4 unplaceable) → lost-Purpose weight → primary → secondary → risk points → hardware order → tier.
- **Undetermined values** are scored at a stated stand-in, never 0.
- **Where it ran:**
  - The search is a static estimator inside the backend: live pol-core, and the test node on econ-core. For the UNO it gives 40 candidates (20 plans × 2 packages).
  - Cycle figures are cyc-0 counts MEASURED on the simavr twin where the route's atoms have a cycle record; otherwise they are counted estimates.
  - The proofs are twin runs (`pol faults run`); the suites ran on isle-core.
  - Nothing has run on a real board yet.
- **Live winners, 2026-10-18:**
  - minimum-resources: poll button + poll sense, 1.777 (21.8 ms).
  - fastest-cycle: INT0 button + INT1 sense, 10.6 ms (1.847).
- **Gaps against his ask:**
  1. An incomplete candidate is ranked lower instead of being a FAILURE.
  2. "Cheapest" is chip-resource fractions, not money. No price data exists.
  3. Only two fixed objectives exist; there are no saved profiles, no per-Purpose weighting, and no per-hardware profile.
  4. Candidates are plans. Only 7 firmware configs are actually built (uno-light, -pcint, -analog, -sense-poll, -sense-pcint, sim-rig, button-clock). Nothing ties a candidate to the built FirmwareSolution that realises it.

## 2. Vocabulary
- **Mission Solution** — one solve candidate for a Mission: hardware × runtime tier × a route per job, plus its pin assignment. It is stored from a SolveRun.
- **Firmware Solution** (the existing fs-0 row) — a Mission Solution REALISED: graph + board → a built image.
  - It is **finished** when it is built AND every Purpose of the Mission is proven (on the twin now, on hardware later).
- **Failure** (his rule) — any solution that does not fulfil every Purpose. It is listed with the Purpose it fails and the reason, and NEVER gets a score.
  - Proposed failures: a lost Purpose · unplaceable · a stated deadline violated · a Purpose with no passing proof (D-fsc-1).
  - Missing parts are NOT a failure; they are a cost term.
- **Firmware Score Term** — one measurable quantity of a solution, with a direction and a normalization.
- **Firmware Score Profile** — a named, weighted set of terms. Weights can apply per Purpose and per hardware context.

## 3. Reuse the scoring module, don't invent (the scorecard pipeline is already in `modules/scoring`)
The `scoring` module already carries the Political Scorecard's math: normalize → context-match by specificity → weighted mean → levelize to 0–100, with every absent term named. Mapping:

| scorecard / `scoring` | firmware |
|---|---|
| `ScoreTerm` (is_positive, normalization_json) | Firmware Score Term (category `firmware`) |
| `ScoreSubject` (object_ref_json) | a Mission Solution / Firmware Solution (objectRef to the row) |
| `ScoreContext` | `purpose:<name>` and `hardware:<board>` contexts (new context types) |
| `ContextualizedValue` | one term value for one solution, in one context, with kind measured/estimated/cited/stand-in + basis |
| `ScoreConcept` (term_weights_json, weighted-mean, levelize) | a **Firmware Score Profile** |

There are no new score classes. The new pieces are:
- a value WRITER that turns a solve candidate or a FirmwareSolution into ContextualizedValues
- the two context types
- seeded profiles
- the comparison page

## 4. Terms (each with its basis; undetermined → stated stand-in)
| group | term | direction | basis now |
|---|---|---|---|
| Cost | **bom-cost** — money for every part the solution needs | lower | cited vendor prices with date (NEW data: `KitPart.unit_price` + a source); stand-in = undetermined |
| | **cost-to-build-now** — money for the parts NOT on the bench | lower | the same prices × parts_missing |
| | parts-to-acquire (count) | lower | exists |
| Speed | **mission-cycle** µs | lower | exists |
| | **worst-purpose-latency** µs | lower | per-Purpose cycle, exists |
| | **deadline-slack** — min over Purposes of (budget − cycle)/budget | higher | exists (deadline Purposes only) |
| | boot-to-ready µs | lower | init lane, exists |
| Headroom | flash-free %, RAM-free % | higher | measured from the ACTUAL build (avr-size) for finished ones; estimated for plans |
| | pins-free, blocks-free | higher | exists (inverse of used) |
| | cpu-idle — 1 − load class | higher | exists (ordinal); measured later |
| Power | **active-current** mA | lower | datasheet-cited per block + LED; undetermined until cited |
| | **sleep-capable** — every trigger can wake from sleep (interrupt-driven) | higher | derived from routes (polled = no) |
| Robustness | risk-points — unchecked/conditional ladder rungs | lower | exists |
| | noise-immunity — debounce/threshold margin | higher | per route (analog threshold < digital) — cited/estimated |
| | shared-resources — shared pins/nets/blocks | lower | exists |
| Evidence | **confidence** — share of the score's terms that are measured vs stand-in | higher | exists (bases counts) |
| | proof-level — twin / hardware / none per Purpose | higher | ScenarioRuns |
| Build effort | wires/joints, part count | lower | from the pin assignment + parts |
| | code size (atoms, LOC) | lower | the graph |
| Portability | also-runs-on — packages/boards with the same plan | higher | exists |

## 5. Sample profiles (seeded ScoreConcepts; his to rename / re-weight)
- **Fastest** — mission-cycle 1.0 only.
- **Cheapest** — bom-cost 1.0 only (money). Until prices are cited it falls back to cost-to-build-now + parts-to-acquire, and says so.
- **Build it today** — cost-to-build-now 0.5, wires/joints 0.3, confidence 0.2.
- **Balanced** — cycle 0.3, bom-cost 0.3, headroom 0.2, robustness 0.2.
- **Battery** — active-current 0.5, sleep-capable 0.4, cycle 0.1.
- **Room to grow** — flash/RAM/pins/blocks free 0.25 each.
- **Most trustworthy** — confidence 0.4, proof-level 0.4, risk-points 0.2.
- **Today's two objectives** reproduced as profiles (`minimum-resources`, `fastest-cycle`), so the old ranking stays one click away and is proved equal.
- **Hardware-specific (his "unique to the hardware")** — one profile per board context with **per-Purpose weights**. Example for the UNO light Mission:
  - ensure-button-controls-light: latency 0.8, cost 0.2
  - ensure-polari-can-control-light: latency 0.5, cost 0.5
  - report state: cost 0.8, latency 0.2

  The score is Σ_p αₚ · Σₜ wₜ,ₚ · norm(vₜ,ₚ) / Σw, where αₚ is the Purpose weight. Cost terms are attributed to a Purpose through the routes its jobs use; a route that two Purposes share is split evenly, and the split is stated.

## 6. Normalization (stated on every cell)
- **Absolute** where a natural bound exists: flash/RAM/pins against the chip's limits, and slack against each deadline.
- **min-max-auto across the compared set** otherwise: money, µs, mA. The breakdown names the set.
- Levelized 0–100, higher = better (is_positive inverts).
- A stand-in value shows as a hatched cell, and the profile's confidence column drops.

## 7. The page — `/display/firmware-scores` (configured tables; no raw JSON, no new custom component)
1. **Finished Firmware Solutions × Profiles.**
   - One row per finished solution, one column per profile.
   - Each cell shows a 0–100 score and its rank in that column; the best in each column is marked.
   - Click a cell → the term breakdown (term · value · kind · normalized · weight · points · basis).
2. **Failures** — a separate table: solution · the Purpose it fails · why. No score.
3. **Mission Solutions not yet built** — the same columns, marked "plan (estimated)", so the gap between built and possible stays visible.
4. **Profile editor** — weights per term (and per Purpose for a hardware profile) as a configured form.
   - Saving creates the user's own ScoreConcept; seeded profiles are copied before they are edited.
   - It follows the click-toggle rule.
5. **Term-by-solution chart** — a bar view in `sci-xy-chart` (THE chart home).

CLI (his rule):
- `pol firmware scores [--profile P] [--mission M] [--json]`
- `pol firmware profile show|create|weight`
- `pol firmware score-values refresh` (rewrites the ContextualizedValues)

## 8. Running it on the devices
- **isle-core (twin campaign).** For each finished solution: build → avr-size → cycle record → the acceptance scenarios. This MEASURES flash/RAM/cycles for the built image instead of estimating them.
  - Command: `pol deploy selftest isle-core …` or a new `pol firmware measure <solution> --node isle-core`.
  - Results are stored as ContextualizedValues of kind measured, with sha256 inputs (the reproducibility rule).
- **pol-core.** The live server holds the values and profiles and serves the page.
- **The bench (his).** Once the UNO is plugged in, the same scenarios run on hardware: proof-level → hardware. Current draw needs a USB power meter (an owner reminder); until then active-current stays cited/estimated.

## 9. Slices
- **fsc-0**
  - the failure rule
  - link Mission Solution ↔ FirmwareSolution (each built config resolves to its candidate)
  - "finished" derived
  - Term rows seeded
- **fsc-1**
  - the value writer (candidate + FirmwareSolution → ContextualizedValues, per Purpose + per hardware context)
  - the two context types
  - the old two objectives as profiles, proven to reproduce today's ranks
- **fsc-2**
  - the seeded sample profiles
  - per-Purpose weighting
  - the CLI
- **fsc-3** — the page (tables + breakdown + editor + chart).
- **fsc-4** — cited prices on KitPart (bom-cost / cost-to-build-now) and the cited current figures (active-current).
- **fsc-5** — the isle-core measurement campaign for the finished solutions (measured flash/RAM/cycles).

## 10a. His answers 2026-10-18 (quoted) → what they fix
- **D-fsc-1:** "If it is a deadline flagged as being safety critical then yes it needs to count as a failure. If it is not flagged as safety critical,
  then no, it should just be scoring based on how close it gets to it."
  - A deadline criterion in a Purpose's `criteria_json` carries `safety_critical: true|false`, default false.
  - Violating a safety-critical deadline is a FAILURE.
  - Any other deadline is scored by closeness. The `deadline-fit` term = 100 at or under budget, falling smoothly with the overrun (budget/cycle). The
    curve is a stated knob.
  - A Purpose of importance `safety` whose deadline is not flagged gets a SUGGESTION to flag it. It is never auto-flagged (the knobs-and-suggestions rule).
  - Unanswered: "finished" still needs every Purpose proven. That is my default, kept from §2.
- **D-fsc-2:** "A cited list would be ideal, accounting for the fact you can buy used or locally as well in that."
  - Prices are cited OFFERS per part class: condition new | used, channel online | local, price + currency, source + URL, and the date cited.
  - bom-cost uses the cheapest offer the PROFILE accepts. Knobs: accept used (default yes), accept local (default yes).
  - The breakdown names the offer used.
  - Local offers cite a chain's public list price, never his location (privacy rule).
- **D-fsc-3:** "Yes build on existing score module."
- **D-fsc-4:** "The sample profiles sound good."
- **D-fsc-5:** "it should be split according to weighting of the importance of a purpose maybe?"
  - A shared route's cost and time are split across the Purposes that use it, in proportion to each Purpose's importance weight.
  - The weights are knobs: safety 4 · required 3 · important 2 · desired 1.
  - Each split is stated in the breakdown.

## 10b. His correction 2026-10-18 (quoted) — scoring is COMPETITIVE; replaces §6
"scoring is meant to be done competitively, so the top scorer is normalized to the top score and the bottom score to 0 and the rest distributed in
between."

**Per term:** every term is min-max normalized across the solutions being compared. The best value scores 100, the worst scores 0, and the rest fall linearly in between.
- This replaces the absolute normalization §6 gave flash, RAM, pins and slack. The chip limits stay in the basis text only.

**Per profile:** the weighted result is normalized the same way within each profile column, so the top solution reads 100 and the bottom reads 0.
- The raw weighted value stays in the breakdown.

**Who competes:** the compared set is every non-failed solution in the view. Finished and plan rows compete together only when the view shows both, and the page says which set was used.
- Failures never enter the set.

**Edge cases, stated:** a set of one, or a term where every solution ties, scores 100 for all, and the breakdown says "no competition on this term". A stand-in value competes at its stand-in, and is marked.

**Why it matters:** sol-0's score cards show raw weighted sums (1.777, 1.847 …), which read as strange. The new page shows competitive 0–100 only.

## 10c. His page layout 2026-10-18 (quoted) — replaces the §7 grid
"there needs to be a dedicated UI page for the scores with different scores being tabs listing the top score to the bottom and the main page of the
scoring page showing just the top scorer of each category"

The dedicated page `/display/firmware-scores` has tabs:
- **Main tab (Top scorers)** — one row per profile: profile · its top solution · 100 · runner-up gap (the second-best score) · the compared set.
  Clicking a row opens that profile's tab. This is the landing view.
- **One tab per profile** (Fastest, Cheapest, Build it today, Balanced, Battery, Room to grow, Most trustworthy, the hardware profiles, and his own
  saved profiles) — every non-failed solution ranked top (100) → bottom (0).
  Columns: rank · solution · score · finished | plan · the deciding terms. Clicking a row opens the term breakdown.
- **Failures** and the **profile editor** sit as their own tabs at the end.

Each tab is a configured table: no raw JSON and no new custom component. The bar chart moves inside a profile tab.

**How tabs are built:** configured pages have NO tabs today (`module_pages_seed._page` = rows of tables), and the profile set is dynamic (his own
saved profiles add tabs). So fsc-3 adds a GENERIC display feature, not a page-specific component:
- page-level `tabs`: static tabs, each holding rows of configured tables, the same as a page;
- a `tabs_from` source: one tab per row of a list door (`/api/firmware-score-profiles`), with `{name}` templated into each table's data_path.
- The first tab is static (Top scorers); the last two are static (Failures, Profile editor).
- The selected tab is kept in the URL (`?tab=`), so a shared link opens the same tab.
- The click-toggle rule does not apply to tabs: a tab is a place, not a selection.

**Acceptance (his "make sure you check it with chrome"):** the page is checked in Chrome on the test node and then on live pol-core.
- Screenshots: the main tab; every profile tab, confirming top = 100 and bottom = 0, sorted; a breakdown opened; the Failures tab; and a weight edit
  in the editor that re-ranks.
- The screenshots go to him, and anything wrong is fixed before he is told the page is done.

Backend: `GET /api/firmware-scores/top?mission=` returns the main tab's rows. A profile tab reads `GET /api/firmware-scores?mission=&profile=`.

## 10. Decisions (his)
- **D-fsc-1** — Is a violated stated deadline a FAILURE, as his "does not fulfil all purposes" suggests, or a scored penalty? Recommend failure. Is a Purpose with no passing proof a failure? Recommend yes, for "finished".
- **D-fsc-2** — Price source: cited vendor list prices with a date (recommend), or what he actually paid (kept local, never in tracked files).
- **D-fsc-3** — Reuse `modules/scoring` (recommend) vs firmware-only score classes.
- **D-fsc-4** — The sample profile set and weights in §5.
- **D-fsc-5** — How cost is attributed to Purposes for per-Purpose weighting: an even split of shared routes (recommend), or assign each route to its most important Purpose.

## 11. Status 2026-10-18 — fsc-0..3 BUILT + MERGED, checked in Chrome on the test node
- **Merged slices:**
  - fsc-0..2 (backend, scoring module, 10 profiles, doors, `pol firmware scores|profile|score-values`)
  - fsc-0b (`initialization-acceptance` on the twin; built configs that miss a Purpose = failure rows; a Purpose is proven for a config only by
    that config's own runs)
  - fsc-3 / 3b (page `/display/firmware-scores`; generic tabs + tabs_from; editable table columns + row actions; max_height; side-by-side rows;
    `score:fixed:1`; header "More" menu)
  - chart rank order (`categoryOrder: 'data'`).
- **Chrome (econ-core test node):**
  - Top scorers lists 10 profiles, each at 100.
  - Each profile tab ranks 380 plans from 100 to 0.
  - Picking a solution fills the breakdown beside the list.
  - In the editor: Copy to edit (Balanced) → "My Balanced" picked → cost weight set to 5 → saved → the ten best re-ranked (the ESP32-C3 at $6.50 leads).
  - The tab strip wraps; the nav shows "More"; scores show 1 decimal.
- **Known, not done:**
  - Nothing is FINISHED yet. Each sense variant needs its own four Purpose runs (boot / button / command / report) on its own build.
  - A new profile's tab appears after a reload.
  - The chart panel header shows the graph's internal name.
  - Seven Angular specs fail outside the touched files: FirmwareSolutionPanel `%40`, and XR lobby/panel. Not baselined.
  - Q to him: should the sense line also serve `ensure-polari-observes-hardware-state`? The Mission data ties it to the two light-control Purposes.
- **Next:**
  - the per-config Purpose runs (the first finished solutions)
  - fsc-4 cited current figures (Battery's active-current)
  - fsc-5 measured avr-size for finished builds

## 12. 2026-10-19 — the first FINISHED solutions (fsc-6) + scl, checked in Chrome on the test node
- **Per-config proofs.** `acceptance.run(scenario, variant=V)`; the Purpose door takes `variant` only for a built config of the Mission;
  `pol firmware prove <config>`; `pol faults run --variant`.
- **The sense variants.** They are the button-clock app (ButtonClockState), so their checks use its fields: `button_presses`,
  `status=commanded`, `set_led`.
- **Test node.**
  - `uno-light-sense-poll` and `uno-light-sense-pcint` are FINISHED: all four Purposes are proven on their own builds, and they rank 16/17 under Fastest at 95.6.
  - Failures: uno-light, -analog, -pcint, -v2. None has a sense-line route, which three Purposes now need (scl-3).
- **scl.** `led_follow_state` is the only pin writer. The from-Polari proof starts from a struct write through `light-toggle`, and the frame is
  derived from it.
- **Still owed.**
  - the finished rows' sizes and cycles MEASURED from their own builds (fsc-5)
  - cited currents (fsc-4)
  - uno-button-clock prove (one command, his word)
  - two stale light-graph edge rows on the servers

## 13. 2026-10-19 — his ruling: a CURATED sample, not 384 rows (slice `smp`)
His words: "That seems like a bit too many plans and failures, I do not know if we needed that much. Maybe just 2 failure examples and success
examples for different kinds of devices and components so that this project which is just a sample project serves as a way to prove out how to
use those components along with managing the state of LEDs."

**Facts at the time (live):**
- 384 enumerated: 378 plans (estimates, never built), 2 finished, 4 failures. Only 6 were ever built and run.
- Every profile's #1 was an unbuilt plan.
- Among the built ones the top is a tie at 100: sense-poll and sense-pcint.

**The sample set** (I chose it: he could not be asked, so my recommendation stands, his to overturn).
Every success is built AND has all four Purposes proven on its own build. Each shows one kind of component or device while managing the LED state
through the struct (scl).

| # | device | components shown | outcome |
|---|---|---|---|
| S1 | UNO | button INT0 · LED gpio-out · sense polled | success (exists: uno-light-sense-poll) |
| S2 | UNO | button + sense on pin-change interrupts (PCINT) | success (build) |
| S3 | UNO | button as an ADC threshold · LED on timer PWM | success (build) |
| S4 | UNO | LED through the kit's transistor (driver stage) | success (build; the kit has 5 transistors + 2 MOSFETs) |
| S5 | ESP32-C3 | the same Mission under FreeRTOS | success on the C3 twin (build; no C3 on the bench, so twin only, said) |
| F1 | UNO | uno-light: no sense line, so Polari cannot observe the LED | failure (exists) |
| F2 | UNO | a slow polled button route against a deadline flagged `safety_critical` | failure (shows D-fsc-1) |

**Page and data:**
- The Mission carries `sample_solutions` (the S/F names).
- The scores doors default to the SAMPLE scope: the sample successes compete (100 → 0), and only F1–F2 show under Failures.
- The other built configs (pcint, analog, v2, sense-pcint) are not listed as failures; they stay as history.
- All enumerated plans move behind a "Possible plans (not built)" tab: the solver's search, kept but out of the way.
- Top scorers reads the sample.

**Slices:**
- smp-0: curation + default scope + the plans tab
- smp-1: S2–S4 + F2 built and proven (`pol firmware prove`)
- smp-2: S5 on the C3 twin
