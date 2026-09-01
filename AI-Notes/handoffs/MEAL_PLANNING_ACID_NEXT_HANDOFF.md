# Next-session handoff: meal planning + acid management

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
