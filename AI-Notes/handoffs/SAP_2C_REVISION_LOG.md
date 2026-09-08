# sap-2c revision log — the compromise layout (one class per file under objects/), worked autonomously 2026-09-08

His instruction: "go ahead and work it out and then work autonomously on
the revision … track your work and give me a report at the end so I can
revise the logic if needed. I will need to look through a few different
samples of the code to make sure the structuring makes sense."

Design: `AI-Notes/designs/STANDARD_POLARI_APP.md` §7. This file is the
running log; the final report is at the bottom.

## Log
- Restored materials_science to the hand-written per-class taxonomy under
  `objects/` (160 files from git, taxonomies intact, core rows at the
  objects root); `materials_science_basis.py` is now an INDEX
  re-exporting 116 classes from 116 files; selftest 5/5, all files import.
- Wrote `standardize_layout split-objects[-dry]`: per basis file, each
  class → `objects/<group>/<ClassName>.py`; module-level constants/seeds
  the classes use → `objects/<group>/_shared.py`; code that references
  the classes stays in the index after the re-exports; classes that
  reference each other stay in one file (strongly connected groups);
  the basis file becomes the index. A file whose helper both uses and is
  used by its classes is KEPT WHOLE and named in the report.
- First dry run flagged 15 keep-whole files; 11 were false positives
  (attribute names like `row.name` mistaken for helper references) —
  detection now counts bare names only and direct module-level bindings.
- Pilot on vpn: 6 class files + `_shared.py` (VPN_MIRROR_CLASSES) + the
  index keeping `VPN_CLASSES` after the re-exports; selftest 89/89.
- Applied to every module (see the split count below); the manifest
  scanner lists `objects/` (nested) as its own concept and `conform`
  reports multi-class object files and unsplit basis files as info.
- Wrote `moduleService/scaffold.py` — `pol modules new <id>` and
  `pol modules add-object <module> <Class> [--under a/b] [--base X]
  [--fields …]` (per-class file with the docstring template, taxonomy
  __init__ re-export, index line).
- Verification of the first full split FAILED (kept honest): (1) a
  comprehension `X = [cls for … in SEED_PAIRS]` in the shared file used a
  name bound by after-code → the AFTER partition is now transitive; (2)
  a basis file that imported a seed from a sibling used to re-export it
  implicitly and the index had dropped the original imports → the index
  keeps them verbatim. Reverted the split (materials untouched), fixed,
  re-ran.
- Second full split: 206 basis files → 456 class files (4 seed-only
  basis files kept). A comprehension variable (`s`) leaked into a
  re-export list → the bound-name walker no longer descends into
  comprehensions/lambdas; zones re-split. Then: server imports on the
  host, boot proof on 13 modules clean (health 200, 0 tracebacks, every
  probed CRUDE/API route 200), 1482/1482 files import, lazy guard 23/23,
  49/49 manifests conform, selftest_manifests 8/8.
- Registration parity PROVEN: the committed pre-split tree booted from a
  git worktree with the same 10 modules registers the identical class
  set (142 distinct, 403 gated) as the split tree — the earlier "677"
  was a counting artifact, not a regression.
- Two selftests updated for the layout, not for behaviour:
  `nutrition/mealplan_pages_selftest` now scans `objects/**` when it
  resolves a table's class; `json_seeds.load_export_hook` looks in
  `custom/` too (the hook had moved in sap-2 and mealoptions' privacy
  suite had been failing since — now "all mealoptions privacy checks
  passed").
- His dev-tools direction recorded as `AI-Notes/plans/POLARI_DEV_TOOLS_PLAN.md`
  (dt-0): rules → linter, scaffolds for modules AND apps, `pol dev admit`
  to bring a custom/no-coded module online on an installed Polari.

## REPORT (for his review — read this first)

**What changed (uncommitted until the final commit below):**
1. **materials_science is back to your hand-written split**, one class per
   file with the taxonomies intact, now under `objects/`:
   `modules/materials_science/objects/properties/thermal/meltingPoint/meltingPoint.py`
   is verbatim your file. `materials_science_basis.py` is an index that
   re-exports the 116 classes. The seven consolidated files I made
   earlier today are gone.
2. **Every other module got the same shape mechanically**: 206 basis
   files → 456 per-class files under `objects/<group>/<ClassName>.py`
   (group = the old basis file's stem), `_shared.py` for the constants
   and seeds the classes use, the basis file left as an INDEX so every
   existing `from pkg.x_basis import Class` still works. Classes that
   reference each other stayed in one file (the report lists none
   today); four seed-only basis files stayed as they were.
3. **Scaffold for humans**: `pol modules new <id>` and
   `pol modules add-object <module> <Class> --under a/b --fields "…"`.
4. Tooling: `standardize_layout split-objects[-dry]`, manifests list
   `objects/` (763 files, 559 classes), conform flags stray dirs and
   reports multi-class object files as info.

**Samples to look at (three shapes):**
- Hand-written, restored: `modules/materials_science/objects/properties/thermal/meltingPoint/meltingPoint.py`,
  `modules/materials_science/objects/properties/__init__.py` (your taxonomy doc),
  `modules/materials_science/materials_science_basis.py` (the index).
- AI-generated, split: `modules/gears/objects/gear/GearTrainDefinition.py`,
  `modules/gears/objects/gear/_shared.py`, `modules/gears/gear_basis.py`
  (index: docstring, original imports, re-exports, then `GEAR_*` seed
  pairs that reference the classes); the bigger one:
  `modules/household/objects/household/` (13 classes) with
  `household_basis.py` keeping `HOUSEHOLD_SEED_PAIRS` after the re-exports.
- Scaffolded from nothing (the shape a downstream developer gets): run
  `pol modules new sap_demo` then `pol modules add-object sap_demo MeltingPoint --under properties/thermal --fields "celsius:float=0.0,method:str"`
  and read `modules/sap_demo/objects/properties/thermal/MeltingPoint.py`
  (docstring template: what it is / related concepts / how measured);
  delete the module afterwards.

**Things you may want to change in the logic:**
- The per-class file header is generic ("Row class X of the module —
  one class per file"); the class's own docstring is the explanation.
  If you want the file docstring to BE the explanation (your style), the
  splitter can hoist the class docstring into it.
- `objects/<group>/` uses the old basis file's stem as the taxonomy
  (`gear`, `household`, `vpn`); a real taxonomy (your `properties/thermal/…`)
  is a human decision the scaffold's `--under` supports but the splitter
  cannot invent.
- `_shared.py` holds seeds AND constants together; if seeds should live
  in `<pkg>_seed.py` instead, that is a second mechanical pass.
- Class files are named exactly as the class (CamelCase); your files
  were camelCase (`meltingPoint.py`). Both are accepted; pick one for
  the scaffold (today it writes the class name).

**Verification:** 1482/1482 module files import; boot on 13 modules
clean (health 200, 0 tracebacks, CRUDE + API routes 200); registration
PARITY with the committed pre-split tree proven from a git worktree
(same class set); lazy-import guard 23/23; 49/49 manifests conform;
selftest_manifests 8/8; the module selftest sweep (28 modules) matches
the baseline, with two suites updated for the layout (not behaviour).
Deployed images predate the layout (next image build picks it up).
