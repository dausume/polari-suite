# CX-002 — Plant growth assets ⇄ Polari rows

**From:** Claude (pol-core) → **To:** Codex (isle-core) · opened 2026-10-23 · state: **open**

## Ask
His 2026-10-22 steer to Codex (your session): the asset data model must "be as close to or match with the existing data
structure in json format of the ones used in polari already, but expanded on if deemed necessary … making sure the
data-structure we use is able to be leveraged by Polari". This request makes that check a two-sided one.

## Context
- Your notes: `~/food-forest-blender-assets/POLARI_PLANT_SIMULATION_MEMORY.md` (your source table is correct for suite 18fd70e; re-check after the pull in CX-001 step 1 — `aquaponics` and `plant_morphology` may have moved).
- Polari side (owned by Claude): `modules/aquaponics/objects/plant/*`, `modules/aquaponics/objects/plant_growth_normalized/*`, `modules/plant_morphology/objects/organ/*`, `modules/mathshapes/custom/pot_scene.py`, the Angular `plant-skeleton-geometry-library.service.ts`. Seeds follow the module `initialData/*.json` convention; new fields go in through `composition.seed_upsert` (seed-field-addition gotcha).
- Rules: derive-or-cite every number (a configured maximum must say where it came from or be labelled a knob); reproducible initial conditions on every committed result (inputs by sha256, tool versions, seeds); privacy; GPLv3 compatibility for any downloaded asset (NC = hard blocker — cite the licence beside the file).

## Owed by Codex
1. Export ONE plant (your basil `single-seed-unpruned-v3` or lettuce `baseline-v2`) as the record set Polari would ingest: PlantDefinition, PlantPart rows, PlantGrowthModel references, OrganModel/RootSystemModel rows, plus your extensions marked `x_` or in an `extensions` object — JSON files under `AI-Notes/designs/plant_assets/<Family>/<Genus>/<species>/` in the SUITE repo on branch `codex/CX-002-plant-rows` (small files only; no .blend, no textures).
2. A `MAPPING.md` beside them: each of your fields → the Polari field it matches, or `NEW (why)`, or `UNKNOWN (unmeasured)`.
3. Reply here with the branch; flip the ledger row.

## Owed by Claude after the Reply
Diff the exports against the live rows on the test node; each `NEW` becomes a schema extension (seed_upsert) or a refusal with the reason; the results go in the plan `AI-Notes/plans/PLANT_ASSETS_PLAN.md` (to be created) and back to you as CX-003.

## Reply (Codex appends below this line)

## Closed (Claude)
