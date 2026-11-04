# HANDOFF — 2026-11-03: mech ↔ FreeCAD desktop work for Codex Astra (autonomous, on the desktop)

**To Codex Astra, in one paragraph:** Polari now has a `mech` module (standard mechanical parts, materials, assemblies and a 1-DOF
motion engine, all as rows) and a FreeCAD 1.1.4 headless relay that was verified on econ-core. What it does NOT yet have is the
FreeCAD side done by someone who can drive FreeCAD as a desktop application: models built and inspected in the GUI, saved as
`.FCStd`, their Assembly / Motion / BOM / mass-property outputs recorded as reference files, and every one of those compared against
what Polari's rows and engines say for the same parts. That is your work. Everything you produce must also be reproducible headless
by a `FreeCADCmd` script you leave behind, and every comparison lands as data (CSV/JSON with a `REFERENCE.json`), never as a claim.
Dustin's framing (2026-11-03): *"do a handoff to codex astra, for them to do work on desktop apps (freeCAD models) based on your work
to further develop and compare against polari … using the desktop for astra to use autonomously."*

Companions (read, do not duplicate): `AI-Notes/plans/MECH_FREECAD_INTERCHANGE_PLAN.md` (the arc: sections 1–9, decisions D-mxc-0..14),
`AI-Notes/plans/MECH_KIT_PARTS_CATALOGUE.md` (what the parts are), `KICAD_INTERCHANGE_PLAN.md` (the ruling this arc copies),
framework `modules/mech/README.md`. Shared folder on econ: `~/collab/mech-freecad/` (copies of both plans, the probe script, the
reference CSV, this file). Reply channel: a file in `~/collab/codex-outbox/` on econ-core (task `MECH-FREECAD-20261103`, Id CX-035).

## 0. Rulings you work under (his words; not up for re-litigation)

- **Polari is the source of truth** (2026-10-30, kxc, carried to FreeCAD unchanged — D-mxc-0): "keep polari as the source of truth, but
  make it so we ensure we encapsulate everything … so we can ingest files coming from [the tool] … make what exports we can from polari …
  possible, but keep polari and our structuring as the focus." FreeCAD is an input and an output, never a peer to sync with.
- **FEM is Polari's, never FreeCAD's** (2026-11-03, D-mxc-7): "Our FEM engines in Polari are likely a lot more robust than FreeCAD so be
  careful not to duplicate work there." Do not run CalculiX / the FEM workbench for any Polari comparison. If a model you open carries
  FEM results, they are ingested as artifacts only.
- **No custom APIs** (2026-11-03, D-mxc-14): "polari fully automates away api creation so long as functionality and engines are wrapped
  by polari properly." Anything you add on the Polari side is rows + pure functions wrapped as `AnalysisDefinition` rows
  (`modules/mech/mech_analysis_seed.py`, `custom/analyses.py` show the shape). No Falcon routes.
- **Regenerate geometry, never store solids** (D-mxc-3): a Polari row holds parameters + generator name + version; a `.FCStd`/STEP is a
  transient worker output whose sha is recorded on the run that made it. Your reference files are the ONE exception, kept small and
  sha'd under `modules/mech/custom/reference/`.
- **Non-proprietary only** (2026-11-03): no vendor CAD portals, no NC-licensed uploads; prefer parts that bolt together (T-slot) over
  welding. Every file you take from elsewhere gets a `SOURCE.json` (url, commit, licence + where stated, sha256 per file).
- **Derive or cite; knobs with basis**: every number you write into a Polari row carries its basis (`cited` | `measured` | `derived` |
  `knob`); every μ, rating and tolerance is a knob until a measured run replaces it; refusals name the gap and the knob.
- **FreeCAD pinned to 1.1.4** (D-mxc-2) and `engine_version` recorded on every run and reference.

## 1. State as of this handoff (econ-core, 2026-11-03)

- Branch `dev-mech` in both repos, merged with `origin/dev-electronics` (Codex's own electronics + isle integration): framework
  `c071b62b` (mech + ms-anchor commit `9ee30725` + merge), suite `0b6f246`. Push to origin follows the board suite's run; if the branch
  is not on origin when you start, it is on econ at `~/mech-fw` (framework worktree) and `~/mech-suite` (suite worktree).
- **Rows** (all auto-CRUDE + persisted; seeds upserted by name): catalogue 25 families / 401 variants / 1277 features
  (`mech_catalog_seed.py`, from Fasteners WB `fddd07a`, NopSCADlib `00ec289`, gridfinity-rebuilt `910e22d` under
  `modules/mech/custom/upstream/*` with SOURCE.json + licences); 53 `MechMaterialOption` + 35 `MechMaterialPreference`; fixtures
  `mfx-1` (2020 beam L300 + 2 inner brackets + 4 sliding T-nuts M4 + 4 ISO 4762 M4x10), `mfx-2` (2×2 Gridfinity bin on a 2×2 baseplate,
  4 magnet seats as `grid` joints), `mfx-3-drawer-cassette` (cabinet member, 2 drawer slides L300, drawer box, 2×2 baseplate; slider joint
  `mfx-3-slide` dof tz 0–250 mm); load cases `mfx-3-empty`, `mfx-3-8-bins`; motion cases `open-position-100t` (formula `100*time`,
  0–1.5 s), `open-pull-5n`, `open-pull-loaded`, `legacy-wooden-runner`.
- **Engines** (pure, `modules/mech/custom/`): `dof_solver.solve_dof` (rigid-group Grübler COUNT: mfx-1 mobility 0, mfx-2 0, mfx-3 1),
  `fit_checks.check_assembly` (thread engagement, ISO 273 clearance, slot/T-nut, grid occupancy, cantilever vs slide rating),
  `compatibility.check_pairing`, `motion_engine.integrate` (one 1-DOF engine, linear or rotary; velocity-Verlet; Karnopp stick/slip; hard
  stops at the joint limits; detent), `motion_runs.run_polari` (writes `MechMotionRun` + core `SimulationRun` + `MechMotionSimState` per
  step + `MechMotionVector`; `inputs_sha256`; checks: opens fully / smooth / no bind / hand effort / stays closed), `motion_runs.compare_to_freecad`.
  Numbers the selftests pin: unloaded drawer opens 250 mm under 5 N in 0.390 s (minimum constant pull 3.353 N); loaded (box 1.2 kg + 8 bins
  × 0.18 kg) needs 3.777 N, tip moment 3.816 N·m vs 220.7 N per-slide rating; the wooden runner 62.47 N and no detent.
- **The engines as rows**: 9 `AnalysisDefinition` + 9 `SolutionDefinition` (`mech-catalogue-family/-variant`, `mech-pairing(s)`,
  `mech-material-preference`, `mech-assembly-dof/-check`, `mech-motion-run`, `mech-freecad-compare`), callable by name through
  `polariNoCode.analysis_calls.call_analysis(manager, 'mech-assembly-dof', {'assembly': 'mfx-1'})` and through the generic
  solution-execution routes. Use these; do not add routes.
- **FreeCAD relay, verified headless on econ** (`modules/mech/custom/freecad_motion.py`, reference `custom/reference/mfx0_motion_econ.csv`
  + `REFERENCE.json`): build two `Part::Box`es, `Assembly::AssemblyObject` + `JointGroup`, `GroundedJoint`, a Slider joint
  (`JointObject.Joint(obj, JointObject.JointTypes.index('Slider'))` — the INDEX, not the name), `asm.solve()`; a `Assembly::SimulationGroup`
  → a `App::FeaturePython` Simulation with `App::GroupExtensionPython` (aTimeStart / bTimeEnd / cTimeStepOutput as PropertyTime,
  fGlobalErrorTolerance, jFramesPerSecond) holding a Motion (Joint, Formula, MotionType) in its `Group`; `asm.generateSimulation(sim)` →
  `numberOfFrames()` → `updateForFrame(i)`. Findings you should CONFIRM in the GUI and explain: (a) `CommandCreateSimulation` is Qt-bound
  and does not import headless — is the property-built Simulation identical to what the GUI command creates? (b) frame 0 is the pre-motion
  placement and frame f ≥ 1 is t = (f−1)·cTimeStepOutput, numberOfFrames = t_end/step + 2; (c) the Motion solver IGNORES the joint's
  LengthMax (z reaches 300 mm at 3 s on a 0–250 joint) and never updates `joint.Distance` per frame — is that a GUI-visible limitation,
  a missing flag (EnableLengthMax?), or a 1.1.4 defect worth reporting upstream?; (d) `min()` / `max()` are not in the formula language
  (0 frames, no error) — what IS the formula grammar (document it from the GUI's editor or the source).
- **FreeCAD installs**: econ `~/opt/freecad/bin/freecad` (GUI) and `~/opt/freecad/bin/freecadcmd` (headless) — FreeCAD 1.1.4, Revision
  20260928, extracted AppImage (econ has no libfuse2); isle-core has FreeCAD installed (version to be recorded on first use — pin 1.1.4).
  Addons you may install into your own user profile only: Stu142/FreeCAD-Gridfinity-Workbench (LGPL-2.1), shaise/FreeCAD_FastenersWB
  (GPL-2.0), and nothing non-free.

## 2. The work — parts A–G, each with its deliverable and its acceptance

Work in the GUI to discover, then SCRIPT it: no part is done until `~/opt/freecad/bin/freecadcmd <script>` reproduces the model
and its outputs byte-for-byte (STEP sha, CSV) on a clean profile. Scripts live under framework `modules/mech/custom/freecad/`
(one file per fixture or probe, `@module` docstring, env-var inputs since freecadcmd passes no argv — see `freecad_motion.py`).
Reference outputs under `modules/mech/custom/reference/<fixture>/` with a `REFERENCE.json` (what, FreeCAD version + revision, machine,
date, script name + sha, every file's sha256 + bytes, the numbers you read off). Comparisons under the same dir as `COMPARE.json`
({polari: …, freecad: …, tolerance, verdict, note}).

**A. Verify the relay findings (a)–(d) above in the GUI.** Deliverable: `REFERENCE.json` notes + a short section in your findings doc
with screenshots' file names (keep screenshots out of the repo; name them in `~/collab/mech-freecad/shots/`). Acceptance: each of
(a)–(d) answered with evidence (a property dump, a source line, or a GUI observation), and the LengthMax question answered.

**B. Build the three fixtures as FreeCAD models from the Polari rows.** mfx-1, mfx-2, mfx-3 — parts from the catalogue dims
(`mech-catalogue-variant` gives every number: ISO 4762 M4x10 dk 7 / k 4 / s 3; 2020 profile W 20 / slot cw 6; sliding T-nut 4.7 high;
Gridfinity bin 2×2×6 footprint 83.5 / height 42 / base profile 0.8-1.8-2.15; baseplate 84 × 84 × 4.75; drawer slide 45 × 12.7 × 300),
Spreadsheet-driven (one Spreadsheet per model whose cells are the Polari parameters by name), placed with Assembly joints matching the
Polari `MechJoint` rows (fixed ↔ Fixed, `grid` ↔ Fixed + the magnet seat offsets, slider ↔ Slider with LengthMin/Max). Carry the Polari
identity on every object as a `Polari` property group (PolariRow = `<Class>:<name>`, PolariVariant, PolariFeature) — the hidden-field
convention from kxc. Deliverables: `mfx-1.FCStd`, `mfx-2.FCStd`, `mfx-3.FCStd` + STEP + the script that rebuilds each. Acceptance:
Assembly solves with 0 remaining DOF for mfx-1 and mfx-2 and exactly the drawer's one for mfx-3 (FreeCAD's solver report), the STEP
re-imports, and the rebuild script's STEP sha equals the GUI-saved model's STEP sha.

**C. The comparison matrix (the point of the exercise).** For each fixture, a `COMPARE.json` with these rows, each a number from
FreeCAD beside the number from Polari's analysis of the same rows, a tolerance, and a verdict:
1. DOF: FreeCAD Assembly solver's remaining DOF vs `mech-assembly-dof` mobility (expect 0 / 0 / 1). Where they differ, say which is
   right and why (Polari's is a COUNT, not a rank test — its note lists what it cannot see; FreeCAD's solver sees geometry).
2. Fit: anything FreeCAD's Check Geometry / interference detection finds vs `mech-assembly-check` conflicts (expect none on all three;
   then DELIBERATELY break one — M5 screws into the M4 bracket of mfx-1 — and show both sides catching it or not).
3. Motion: FreeCAD Motion position(t) for `open-position-100t` on mfx-3 vs Polari's run (`mech-motion-run` then `mech-freecad-compare`;
   expect ≤ 1e-9 mm over 16 frames). Then two more position formulas of your choice (a sine, a two-term polynomial) — same expectation.
   Force-driven cases have no FreeCAD counterpart: record that as a row with verdict `no-freecad-form`, do not fake one.
4. Mass: FreeCAD mass properties (volume × density, density from `MechMaterialOption.properties_json.density_kg_m3` for the material the
   instance resolves to) vs Polari's `MechLoadCase.resultant_json` total mass for `mfx-3-8-bins` (box 1.2 kg is a KNOB in Polari — report
   what a 3 mm PLA box of the drawer's dims actually weighs in FreeCAD; that number becomes the row's basis `derived`).
5. BOM: FreeCAD's BOM (the Assembly BOM object) vs the composition node's members (`CompositionNode.members_json` for node-mfx-1/2/3):
   same part list and quantities.
6. Geometry: for three catalogue variants of your choice (one screw, one extrusion, one bin), the volume and bounding box of the model
   built from Polari's dims vs the same part from the Fasteners WB / Gridfinity workbench (installed in your profile) — the catalogue's
   numbers must reproduce the workbench's part within 1 % volume; where they do not, the catalogue row is wrong and you say which field.
Acceptance: all six rows filled for all three fixtures (or `no-freecad-form` with a reason), every divergence explained, and a list of
the Polari rows whose numbers you corrected (basis `derived`, your REFERENCE as the source) — give that list in the findings doc; do not
edit `mech_catalog_seed.py` by hand (it is generated: fix `custom/catalog_import.py` or add a hand table in it, regenerate, run
`mech.mech_catalog_selftest`).

**D. Gridfinity through the workbench.** Generate bins (1×1×3, 2×2×6, 3×2×6) and baseplates (2×2, 3×2) with Stu142's workbench; compare
footprint, height, base profile, magnet/screw pockets against the catalogue's `gridfinity-*` rows and the spec constants in the plan
(42 / 7 / 41.5 / 4.75 / r 3.75 / wall 0.95 / magnet Ø6.5 × 2 / screw Ø3). The catalogue has no 3×2 baseplate and a hand-derived lid:
tell us what the workbench generates for those so the importer can carry them with basis `derived`. Deliverable: `COMPARE.json` under
`reference/gridfinity/` + the generating script. Acceptance: every constant matched or the mismatch named with the workbench's value.

**E. The desk + drawer prototype as a parametric FreeCAD model (what mxc-5's generator must reproduce).** One Spreadsheet-driven model:
inputs desk W×D×H, drawer grid X×Y per cassette, cassette rows, height units per drawer, slide family (ball-bearing side-mount vs
printed UHMWPE runner on a T-slot), material per role (top: birch plywood 18 / MDF; frame: 2020 / 2040; box: 3 mm PLA / 6 mm plywood).
Build the frame from catalogue extrusions + inner brackets + T-nuts, the cassettes, drawers, slides and a 2×3 baseplate per drawer; emit a
CUT LIST (profiles by length) and a PRINT LIST (bins, baseplates, fronts) as CSV from the model. Deliverable: `desk-proto.FCStd`, the
script, the two CSVs, and `DESK_PARAMETERS.md` — the exact parameter list with units, defaults and ranges, which is the contract mxc-5's
Polari generator will take (it becomes the first `MechSystemDefinition`, D-mxc-13). Acceptance: changing W, X×Y or the slide family in the
Spreadsheet regenerates a consistent model and lists; the cut list sums match the frame geometry.

**F. MathShapes ↔ FreeCAD bridge probes (plan section 8).** Two probes only: (1) the M5 internal thread that mathshapes' anchored
offset tool seeds (`demo-m5-internal-thread`: ISO 68-1, P 0.8, D 5, D1 4.134; the tool samples it as an implicit field) built in FreeCAD as
a Part::Helix sweep / the Fasteners WB's modelled thread — compare minor diameter, pitch and the volume removed over 4 cm with the field's
sample (`ms-offset-sample` analysis); (2) a planar pad from `ms-offset-result` (square, side 2, t 0.5 on demo-cylinder's top) exported as a
Pad on a sketch — same volume. Deliverable: `reference/mathshapes/COMPARE.json` + scripts. Acceptance: volumes within 2 % or the reason named
(the field's march step is in the row's `method`).

**G. Findings + gaps, as data for Dustin.** `AI-Notes/handoffs/MECH_FREECAD_DESKTOP_FINDINGS.md`: what FreeCAD does that Polari's rows
cannot express yet (each as a proposed row/field with the plan section it belongs to), what Polari catches that FreeCAD does not, the
corrected catalogue numbers, and decisions for him numbered `D-astra-1..n` (recommend, don't decide). Also update plan section 2's "Verified
headless" paragraph and section 4's mxc-3 row with what you learned (quote your evidence; mark anything unverified as such).

## 3. How to work autonomously here (the loop)

1. Start from `dev-mech`; make your branch `codex/mech-freecad-desktop` in the framework (and the suite for the two docs). Commit
   innermost-first, often, with the attribution the repo uses; never push to `dev-electronics` or `dev`; do not rebase anyone else's branch.
2. Before any Polari-side change and after every one: `cd <framework> && PYTHONPATH=.:modules python3 -m mech.mech_catalog_selftest`,
   `…mech_assembly_selftest`, `…mech_motion_selftest`, `…mech_analysis_selftest`, and `python3 -c "from moduleService.manifests import
   conform; print(conform('mech'))"` must stay green / ok. A new script or data dir must be named in `modules/mech/polari-app.json`
   (`files.custom`) or conform reports it.
3. Every number you produce goes into a `REFERENCE.json` / `COMPARE.json` with the FreeCAD version + revision, the script's sha and the
   date. A verdict without the two numbers beside it is not a verdict.
4. Work in the GUI freely (econ's wrapper is `~/opt/freecad/bin/freecad`; use your own `~/.local/share/FreeCAD` profile), but nothing counts
   until the headless script reproduces it. If the GUI does something the API cannot (you will hit this with the Simulation command), say
   exactly what, with the property dump of the GUI-made object beside the script-made one.
5. Budget: parts A–C first (they decide whether the relay is trustworthy), then D, E, F, G. If a part cannot be done, finish the others
   and say what blocked it. Do not widen scope into FEM, rendering, or new Polari modules.
6. Reply as a file in `~/collab/codex-outbox/` on econ-core when A–C are done and again at the end; Claude on econ reads it and relays to
   Dustin and pol-core. Questions only Dustin can answer go in the findings doc as `D-astra-n`, not in chat.

## 4. What NOT to do

No CalculiX / FEM workbench runs for comparisons (D-mxc-7). No stored solids in Polari rows (D-mxc-3). No Falcon routes or `*_api.py`
(D-mxc-14). No hand edits to generated seeds. No NC-licensed or vendor-portal models (if a part needs one, say so and stop at the gap).
No FreeCAD other than 1.1.4 without recording the version on every output. No pushes to shared branches. No deletion of the existing
reference run (`mfx0_motion_econ.csv`) — add beside it.
