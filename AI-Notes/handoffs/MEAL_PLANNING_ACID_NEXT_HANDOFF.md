# Next-session handoff: meal planning + acid management — PLANNING round
(prepared 2026-08-31 night; Dustin: "shift back to meal planning and
acidic management … start our planning next round". Microchip arc TABLED —
its own entry point is MICROCHIP_LADDER_NEXT_HANDOFF.md.)

**This is a PLANNING round, not a build round** — the deliverable is a
ratifiable plan (phases + decisions), per the working style.

## FIRST QUESTION FOR DUSTIN (settle before planning)

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
