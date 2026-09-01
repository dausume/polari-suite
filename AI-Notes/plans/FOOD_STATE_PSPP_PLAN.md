# Food process–structure–property–physiology (fsp arc)

**STATUS: DIRECTION RATIFIED (Dustin 2026-08-31, his PSPP-for-food
message verbatim below); phases DRAFT pending decisions D1–D8. This is
the planning-round output — NO code yet. Entry handoff:
`MEAL_PLANNING_ACID_NEXT_HANDOFF.md` (its "which acid reading" question
is ANSWERED: dietary/gastric, via this model).**

## 0. Direction (Dustin, condensed; treat as ratified)

Model food as **state evolution, not a static nutrition label**:

```
Cooking/Preparation → Food Structure → Chemical + Physical Properties
                                     → Nutrition / Digestion / Gastric Effects
```

- The ingredient is the base material; **each preparation step produces
  a new FoodState** (parent chain + processing history): raw tomato →
  chop → simmer → concentrate → tomato sauce. Each arrow = a
  ProcessingStep; each node = a materially distinct state.
- **Cooking never writes headline labels** ("acidity = high"); it
  changes underlying quantities/structures (denaturation,
  gelatinization, cell-wall breakdown, water evaporation, Maillard,
  acid degradation…) and measurable properties FOLLOW.
- **Composition ≠ structure**: same grams of starch+water behave
  differently gelatinized vs intact granules. Chemistry (pH, buffer
  capacity, titratable acidity, speciation) is its own block.
- The **gastric/digestive model is DOWNSTREAM** of
  composition+structure+chemistry+physics — never baked into the food.
- Every property value carries provenance: **MEASURED / CALCULATED /
  PREDICTED / CONDITIONAL_PREDICTION** with method/model, confidence,
  and conditions.
- **Recipes are process specifications**, so "steam instead of fry?" =
  swap a node in the process graph and recompute the resulting state.
- Final P renamed for food: **Physiological / Functional Performance**
  (stomach acidity, glycemic behavior, bioavailability, satiety,
  storage life, texture, meal-planning suitability) — kept distinct
  from intrinsic properties.

## 1. Ground truth — this architecture already half-exists (REUSE)

**`modules/pspp/` (materials framework — architecture CLOSED; ⚠ the
"branches unmerged" note in older memories is STALE: pspp IS MERGED on
dev and has grown since — 35 selftest suites, mtt-2 ceramics/glass +
cast-3 work on top; seeds fully transcribed into code (datasets_seed.py
= the operational form of the root JSON, no runtime file reads). Two
real 2026-09-01 findings: pspp is the ONE official module with an
EMPTY registry repo — polari-module-pspp does NOT exist on GitHub, so
the download-as-module path fails until it is published (his go) —
and pspp is NOT in POLARI_MODULES on prf-a (assign when fsp goes
live). See PSPP_MATERIALS_PLAN.md):**
- MaterialState DAG owned by the material; canonical `#as-defined`
  state; state_resolution as THE name→state path (canonical-state
  invariant protected existing consumers with zero call-site edits).
- `ExecutionEffect: OBSERVATIONAL | TRANSFORMATIVE` — measuring pH
  ATTACHES A CLAIM to a node; simmering CREATES AN EDGE. This is
  exactly the measured-pH-on-state-184 example.
- **Claims not values**: value + EvidenceMethod + assumptions +
  validity. One shared EvidenceMethod vocabulary.
- ProcessingStage separate from ThermodynamicPhase; recipes are
  process INPUTS (Formulation → process constraint), not materials.
- **I5: no invented kinetics** — model interfaces stay
  registered-unimplemented until a cited calibration is loaded.
- pspp-11 (planned generality proof): "wax states + CMC schema-as-data
  must need ZERO schema changes." **Food is this proof, writ large.**

**`modules/nutrition/` + nmp (dev-nmp-1, UNMERGED, review gate):**
- FoodItem + NutrientContent (per-100g), 30 nutrients, DRI bands,
  person/household needs, harvest loop (nut-1..4, on dev).
- nmp-3 retention/yield engine (USDA R6 + Cooking Yields, CC0 — the
  cited bulk transform); decision-12 method resolution ALREADY selects
  the matching retention row (bake ≠ fry); nmp-10 uniform STEP
  CONTRACT (inputs+state → outputs+state, duration, equipment) with
  workflows as graphs-as-data on the existing no-code editor;
  decision-9 glycemic-load caps + reflux-trigger rows (lower labeled
  confidence); decision-14 comfort/reflux timing windows.
- fam-1 precedent (microchip): contracts-as-data SHELLS before any
  class schema freeze.

## 2. Architecture mapping (his vocabulary → suite concepts)

| his term | suite concept |
|---|---|
| FoodMaterial | material identity (FoodItem-linked; base ingredient) |
| FoodState (parentState, processingHistory) | MaterialState-DAG pattern; raw ingredient = canonical `#as-defined` state → existing nut/nmp consumers keep resolving unchanged |
| ProcessingStep | nmp-10 step contract + TRANSFORMATIVE execution (edge); measurements = OBSERVATIONAL (claim on node) |
| composition / structure / physical / chemical / physiological blocks | CLAIMS grouped by property domain — never bare values |
| EvidenceProfile (MEASURED/PREDICTED/…) | EvidenceMethod vocabulary + confidence; ADD `CONDITIONAL_PREDICTION` (direction + conditions list) |
| recipe | process specification: a workflow graph whose terminal node is the PreparedFoodState |
| "steam instead of fry" | swap node → recompute chain (derive-on-demand) |

## 3. The transform honesty ladder (per quantity, per step)

1. **MEASURED** row for this state (method, temperature).
2. **CALCULATED** — deterministic mass balance: chop (structure only),
   water loss/evaporation, concentration (acid amount ÷ less water),
   dilution, mixing. No model needed, exact bookkeeping.
3. **PREDICTED** — cited mechanistic model behind an I5-style
   registered interface (starch gelatinization fraction, protein
   denaturation fraction, cell-integrity loss): implemented ONLY when
   a cited calibration is loaded; confidence carried.
4. **USDA Retention Factors R6 + Cooking Yields** (CC0) — the cited
   bulk fallback for micronutrients per cooking method (already wired
   in nmp-3/decision-12; becomes the ladder's rung 4, labeled as such).
5. **REFUSE**, naming the gap and what data would fill it (the
   pspp guide pattern: the gap list IS the experiment plan).

**The acid chain (the proof case):** FDC/literature organic-acid
amounts (citric/malic) → simmer = water loss CALCULATED → acid
CONCENTRATION calculated; pH/titratable acidity/buffer capacity =
measured rows where published, Henderson–Hasselbalch speciation
CALCULATED where pKa values are cited, else refuse; gastric response =
CONDITIONAL_PREDICTION only (direction + conditions like meal_size /
protein_load / fat_load + confidence) — comfort heuristics, explicitly
NOT medical advice (restated on every payload; nmp decision-3 boundary
holds).

## 4. Phases (each = own branch on confirmation)

- **fsp-0 — vocabulary + contracts as data** (fam-1 shell pattern):
  FoodMaterial / FoodState / FoodProcessingStep / property-domain
  CONTRACTS as rows first ({quantity, unit, provenance-kinds, why});
  no class freeze until D1 lands. Includes the D8 rename.
- **fsp-1 — composition backbone = the COMMON-BASE-INGREDIENTS
  DATABASE** (his 2026-09-01 ask verbatim): a starter roster
  (~60–100 staples across grains / legumes / vegetables / fruits /
  meats-eggs-dairy / oils / flavor bases — nmp decision 8 makes this
  roster the meal vocabulary) of food-material identities; per
  ingredient a hand-curated FDC mapping (name → fdc_id + dataset
  edition; non-regenerable → `modules/foodstate/initialData/` per the
  module-initial-data convention) yielding composition CLAIMS on the
  canonical `#as-defined` state with FDC citations; constituent
  extension beyond the 30 nutrients (water first-class, starch vs
  sugars split, organic acids by species, caffeine/capsaicinoids —
  D4); nut-2 FoodItem rows link to the same identities; per-
  ingredient contract-coverage report (has vs refuses, honestly).
- **fsp-2 — transform engine v1**: rungs 2+4 fully (mass balance +
  retention-factor fallback riding nmp-3), rung 3 for 2–3 CITED
  models only (gelatinization, denaturation) behind registered
  interfaces; every transform writes underlying quantities, never
  headline labels.
- **fsp-3 — chemistry block**: pH/TA/buffer claims + speciation calc;
  the tomato → chop → simmer → concentrate → sauce chain END-TO-END as
  the acceptance test (with the state-184-style measured-pH example).
- **fsp-4 — recipes as process graphs**: FoodState chains over the
  nmp-10 workflow graphs (no new editor); steam-vs-fry recompute demo;
  states DERIVED-ON-DEMAND + cached (level-scenes upsert precedent) —
  never a boot-seeded state explosion (D5).
- **fsp-5 — physiological/functional performance v1**: conditional
  gastric predictions (acid-secretion direction w/ conditions),
  glycemic-kinetics CLASS from gelatinization + particle size (feeds
  decision-9's GL gate honestly), satiety heuristics (labeled);
  upgrade nmp reflux-trigger rows from hand-rows to DERIVED-where-
  possible (hand rows stay as fallback with their lower confidence).
- **fsp-6 — integration + pages**: meal plans consume terminal
  FoodStates; per-object state-DAG page (pspp /states SVG DAG pattern
  exists); nut-5 fulfillment sim sequencing folds in here or after.

## 5. Decisions (his)

| # | decision | options / default |
|---|---|---|
| D1 | **Substrate** | ✅ **RATIFIED 2026-09-01 ("using pspp for food if it works then let us go with that")**: food = pspp CLIENT / the pspp-11 generality proof. The merge worry was moot — pspp is already ON dev; the "works" gate = the 35-suite selftest run + the empty-repo/publish fix |
| D2 | module home | default: new `modules/foodstate/` requiring `nutrition` (file-size-decomposition) |
| D3 | proof foods for fsp-2/3 | default: tomato-sauce chain, boiled vs raw potato, steamed-vs-fried chicken breast |
| D4 | v1 constituent scope | default: water, starch/sugar split, citric+malic+acetic+lactic acids, caffeine, capsaicinoids |
| D5 | state persistence | default: derive-on-demand + cached rows (upsert-on-GET precedent), never boot-seeded grids |
| D6 | gastric model v1 depth | default: DIRECTION + conditions + confidence only — no magnitude claims |
| D7 | relation to unmerged dev-nmp-1 | plan assumes STACKED on it (uses retention/method/step machinery) — confirm, or merge nmp first |
| D8 | final-P rename | "Physiological / Functional Performance" — his call, RECORD as ratified |

## 6. Non-goals

- No medical/treatment claims — comfort + general-population framing,
  said plainly on every physiological payload.
- No proprietary data (Sydney GI DB out — published GI papers only;
  Monash values-only with citation; ⛔ NC = hard blocker).
- No new graph editor, no rebuilding nut/nmp machinery, no relitigating
  the pspp core architecture (extend via data + engines behind
  registered interfaces).

## 7. Status

| item | state |
|---|---|
| direction (PSPP-for-food, §0) | ✅ RATIFIED 2026-08-31 |
| D8 rename | ✅ ratified (record) |
| D1 substrate = pspp client | ✅ RATIFIED 2026-09-01 |
| D2–D7 | ✅ defaults ACCEPTED 2026-09-01 ("the other recommendations") |
| pspp operational re-confirmation | ✅ 2026-09-01: **35/35 suites, 0 failures (~665 checks)** on dev; seeds self-contained in code |
| pspp module publish | ✅ 2026-09-01 (his go): polari-module-pspp created + dev subtree pushed (tree hashes match); registry URL committed on dev (6a62e72) so push-all-dev tracks it |
| **fsp-0** | ✅ **BUILT 2026-09-01** on branch `dev-fsp-1` (off dev): `modules/foodstate/` — food stages/processes/evidence-methods as PSPP ROWS (zero pspp schema changes, proven in selftest), FoodDomainContract shells (5 domains), GET /api/foodstate/contracts\|vocabulary, registered (requires pspp+nutrition). selftest_foodstate 14/14; pspp suites unaffected. ⚠ foodstate registry repo:"" — publish polari-module-foodstate with the next sweep (the pspp lesson). DEPLOY: needs pspp+foodstate assigned on prf-a when going live |
| **fsp-1** | ✅ **BUILT 2026-09-01** (dev-fsp-1): 49-ingredient roster (FoodMaterial; identity resolved FROM the vendored sha-pinned FDC subset) + 949 FDC-cited PropertyClaims on `#as-defined` subjects + `/api/foodstate/ingredients[/{slug}]` with per-ingredient coverage naming the D4 gaps. Vendor data files pulled from dev-nmp-1 (data-only; nmp code merge = his gate). selftests 12/12 + 14/14 |
| fsp-2 | ⚠ v1 BUILT 2026-09-01 as mpa-0 on `dev-mpa-1` (off dev-fsp-1 + dev-nmp-1 merged in — D7 stacked): rungs 2+4 live (mass balance + R6 retention), rung 3 refuses by name; cited gelatinization/denaturation calibrations still to load (the fsp-2 remainder). See MEAL_PLANNING_APP_PLAN.md |
| fsp-3 (partial) | pH literature priors landed (mpa-1, food_ph_seed) — TA/buffer/speciation + the tomato-chain acceptance still open |
| fsp-6 (partial) | template_state_chain (mpa-0) + meal-acidity/cost/pantry surfaces (mpa arc) consume the states; the /states DAG page still open |
| fsp-4..5 | planned, not started |
