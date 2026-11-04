# Mechanical parts + FreeCAD interchange (mxc) — Polari is the source of truth

DRAFT on econ-core, 2026-11-03. Not yet in the suite; nothing built. Written to the same shape as
`AI-Notes/plans/KICAD_INTERCHANGE_PLAN.md` (kxc) so the two arcs can be read side by side.
Companion data: `collab/mech-parts/MECH_KIT_PARTS_CATALOGUE.md` + `data/` (sources, sizes, materials registry, part roles).

## 1. The ruling, carried over from kxc (his words, 2026-10-30)

> "we should keep polari as the source of truth, but make it so we ensure we encapsulate everything KiCAD has as well ..."

Read "FreeCAD" for "KiCad". ASSUMED to carry over; his confirmation is D-mxc-0.

- **Polari rows are the design.** FreeCAD is an *input* (ingest an `.FCStd` / STEP) and an *output* (export an `.FCStd` with an Assembly, a STEP, a
  cut list), not a peer to synchronise with. No merge engine. Re-ingest = new revision + diff.
- **Ingest encapsulates everything.** An `.FCStd` is a zip (Document.xml + GuiDocument.xml + `*.brp` shapes + thumbnails). Every member is an
  artifact with its sha256; every object in Document.xml is a TYPED row or counted PRESERVED-ONLY in a coverage row. Nothing dropped silently.
- **Export does what it can,** validated by FreeCAD itself (the document re-opens, the Assembly solves, its BOM equals ours, its STEP re-imports to
  the same volumes). What has no FreeCAD form is said in the export report.
- **Critical data rides in FreeCAD's own places** (the kxc-5b rule): custom properties in a `Polari` property group on every exported object
  (Polari.Family, Polari.Variant, Polari.Material, Polari.Feature, Polari.Joint, Polari.Source with the row + sha), the object Label, the
  document's Comment/Company/License fields. Only what is critical: identity, material, load rating. Never a dump of every row.
- **Non-proprietary only** (his rule, 2026-11-03): no vendor CAD portals, no NC-licensed uploads. Prefer parts that bolt together with no welding
  and no machining beyond cut-to-length.

## 2. Where we are (mxc-0, 2026-11-03)

Polari today:
- `composition`: PartArchetypeDefinition, InterfaceDefinition (DOF_AXES tx..rz, RETENTION_SCHEMES incl. `fastener`), FailureModeDefinition
  (`fm-fastener-back-out` NOT MODELLED), CompositionNode. The right home for archetypes; no catalogue, no sizes, no geometry.
- `mathshapes/cad_remote.py` + `casting/custom/mesh_voxelize.py`: a trimesh + optional FreeCAD/OpenCASCADE **worker already exists** (Docker,
  `WITH_FREECAD=1`); imports FCStd/STEP, pulls the parametric parameters FreeCAD exposes. This is the seed of the FreeCAD engine selection
  (as `pcb_engines` selects kicad-cli).
- `materials_science`: resolutions + reference printable materials (PLA, PETG, ABS, nylon, TPU, PHA). The registry in `data/materials_registry.json`
  (51 materials, IARC classes, legacy→replacement) should become rows beside it, not a second system.
- `motors` holds the only threaded part (M8x1.25 rod). No T-slot, screw, nut, bearing, slide or Gridfinity rows anywhere.

FreeCAD (release 1.1.4, 2026; AppImage 820 MB; isle-core has it installed, econ can take the AppImage without sudo):
- Part / PartDesign (parametric solids), Spreadsheet (parameters), **Assembly** workbench (built in since 1.0; joints: Fixed, Revolute, Cylindrical,
  Slider, Ball, Distance, Parallel, Perpendicular, Angle, RackPinion, Screw, Gears, Belt; per joint: Reference1/2, Placement1/2, Offset1/2,
  Distance, LengthMin/Max + AngleMin/Max with Enable flags, GroundedJoint; solver = OndselSolver, open source),
  **Simulation** (1.1: Motion objects on a joint, MotionType Linear | Angular, Formula such as `5*time`; animates/solves the assembly over time —
  kinematics, not dynamics), **BOM** (BomObject/BomGroup), headless `FreeCADCmd` scripts
  (workbench modules must be imported explicitly; no GUI calls). FreeCAD also ships a FEM workbench (CalculiX) — **not used** (next bullet).
- Not in FreeCAD: forces, friction, mass-driven dynamics. Those stay Polari's own model (as the SPICE renderer is ours and libngspice the engine).
- **FEM is Polari's, not FreeCAD's** (his ruling, 2026-11-03: "our FEM engines in Polari are likely a lot more robust than FreeCAD so be careful
  not to duplicate work there"). What exists: `materialsScience/engines/fem_engine.py` (scikit-fem; `solve_elasticity_2d` returns the stress
  tensor, von Mises AND max-principal with locations, holes, tractions, fixed edges, `elasticity_mesh_convergence`; steady conduction;
  homogenisation; magnetostatics), `fem_plate_thermal.py` / `fem_plate_transient.py`, the msci-engines worker (`engines/remote.py`: sfepy for
  what Alpine cannot pip, resolved by the topology ladder), `FEMModelDefinition` rows (domain → materials → BCs → sources → mesh → solver →
  results, with objectRef bindings to live material rows), tensormath `FEMFieldState` whose P1 triangles already become MathShape polygons
  (`tensormath/custom/fem_shapes.py`), and `motors/custom/motor_stress.py` (ductile von Mises vs. brittle Rankine verdicts, load cases from
  the machine's own physics incl. the handling case). FreeCAD's role in this plan is therefore geometry, assembly, kinematic motion, BOM and
  STEP only. A `.FCStd` that arrives carrying CalculiX results is ingested as artifacts (3.6) like any other member — never run as an engine.
- **Verified headless on econ, 2026-11-03** (FreeCAD 1.1.4 extracted AppImage, `~/opt/freecad/bin/freecadcmd`): Part, Spreadsheet, Fem, STEP export,
  `Assembly::AssemblyObject` + JointGroup, GroundedJoint, `JointObject.Joint(obj, JointTypes.index('Slider'))` (index, not name), `asm.solve()`,
  and a time-driven kinematic run: `Assembly::SimulationGroup` → a FeaturePython Simulation (needs `App::GroupExtensionPython`; aTimeStart /
  bTimeEnd / cTimeStepOutput as PropertyTime, fGlobalErrorTolerance, jFramesPerSecond) holding a Motion (Joint, Formula, MotionType) in its
  `Group`; `asm.generateSimulation(sim)` → `numberOfFrames()` → `updateForFrame(i)` moves the parts. The Python Simulation module itself is
  Qt-bound and does not import headless; building the objects from properties is enough. Formula `100*time` ran (17 frames, 0–1.5 s);
  `min()` is NOT in the solver's formula language (0 frames, no error) — the drawer stop must be a joint LengthMax, not a formula clamp.
  RESOLVED in mxc-4 (re-run 7 ways, `custom/reference/REFERENCE.json`): there is NO ramp. Frame 0 is the pre-motion placement (wherever the
  assembly solve left the part); frame f ≥ 1 is t = (f−1)·cTimeStepOutput, uniform; numberOfFrames = t_end/step + 2. The probe's t_s column
  (frame/fps) was mislabelled. Also found: the Motion solver does NOT honour the joint's LengthMax (z reaches 300 at 3 s) — the end stop is
  Polari's hard stop only; joint.Distance is never updated per frame. Script: `modules/mech/custom/freecad_motion.py` (env vars, headless).

Open standard-part + Gridfinity sources (licence-checked, sizes measured — `data/sources.json`):
- FreeCAD Fasteners WB (GPL-2.0, 0.21 MB of CSV tables) · NopSCADlib (GPL-3.0, 0.92 MB of variant tuples) · BOLTS (LGPL-2.1+ data) · FrameForge (LGPL-3.0) ·
  FreeCAD-library (CC-BY-3.0, fetch the 92 MB kit subset only) · BOSL2 (BSD-2).
- Gridfinity: the spec (Zack Freedman; Printables page says private + commercial use allowed, no named licence — D-mxc-1);
  `kennetek/gridfinity-rebuilt-openscad` (MIT, 2295★; `src/core/standard.scad` is the cleanest constant table); `Stu142/FreeCAD-Gridfinity-Workbench`
  (LGPL-2.1, 170 KB of Python, verified on FreeCAD 1.0: bins, baseplates, magnet/screw bottoms, label shelves, dividers);
  `Stu142/Gridfinity-Documentation` (drawings; licence NOASSERTION — check). EXCLUDED: `smkent/modular-drawers-gridfinity` (CC-BY-NC-SA).

Gridfinity constants (from gridfinity-rebuilt `standard.scad`, cross-check against the spec drawing in mxc-1):
grid 42 × 42 mm; height unit 7 mm; base top 41.5 × 41.5 (0.5 mm gap), base profile chamfer 0.8 / vertical 1.8 / chamfer 2.15 = 4.75 mm, bridge to
7 mm; outer corner radius 3.75 (7.5/2 at the top); wall 0.95; divider 1.2; magnet pocket Ø6.5 × 2.0 (+2 layers), 8 mm from the side, crush-rib
variant Ø5.9 × 8 ribs; screw hole Ø3 (M3), 4.8 mm from the bottom edge; stacking lip 0.6 fillet / 1.2 support; baseplate screw counterbore Ø5.5 × 3.

## 3. The data model — the electronics parallel

| Electronics (board / pcb) | Mechanical (mech) | What it is |
|---|---|---|
| BoardDefinition / PartBoard (datasheet, geometry, layers) | **MechPartFamily** | one standard or geometric archetype; how its variants are picked |
| the board's package / a KiCad symbol | **MechPartVariant** | one orderable/printable size (ISO 4762 M5×12; E2020 cut 300; Gridfinity bin 2×3×6u) |
| BoardFoothold | **MechFeature** | ONE PLACE ON A PART WHERE SOMETHING CAN LAND: a thread, a slot, a bore, a face, a grid cell |
| Bench | **MechAssembly** | the design: instances + joints, grounded somewhere |
| BenchBoard | **MechPartInstance** | a variant placed in an assembly with ITS material and cut length |
| BenchConnection / SchematicNet | **MechJoint** | two features joined, with the DOF left free and its limits |
| BoardNet volts / drive | **MechContact** | a sliding or rolling pair: friction and clearance with their basis |
| BenchConditions / BenchInteraction | **MechLoadCase** + **MechMotionCase** | what is put in and what is done to it (a load of bins; a pull on the handle) |
| SpiceRun + SpiceVector | **MechMotionRun** + **MechMotionVector** | a solved time series with run provenance |
| KiCadArtifact / KiCadCoverage | **FreeCadArtifact** / **FreeCadCoverage** | every file kept, every object typed or preserved |
| the Polari.* hidden fields | the `Polari` property group | identity + critical data riding inside FreeCAD files |

Rows are `treeObject`s in the suite's style: `name` is a composed key; every number names its basis (`cited | derived | measured | knob`) or
says `undetermined`; -1 = not given; lists as `*_json`.

### 3.1 Catalogue (standards level — no design in it)

```
MechPartFamily      name='iso4762' | 'tslot-20-B6' | 'gridfinity-bin' ...
  category          frame_profile | frame_joint | slot_fastener | screw | nut | washer | insert | standoff | rod_pin |
                    retaining_ring | bearing | linear | drawer_slide | transmission | motor | gridfinity | panel | misc
  standard          'ISO 4762' | 'DIN 508' | 'Gridfinity 1.0' | '' ; standard_source (url / artifact sha)
  variant_axes_json [thread, nominal_length] | [series, slot_type, cells_x, cells_y, open_faces, cut_length] | [grid_x, grid_y, height_u, bottom, lip, dividers]
  size_key          the axis that picks a dimension row (thread | series | bearing_code | grid)
  length_rule       none | stepped(series, per-size min/max) | continuous(min, max)
  dimension_table_json  {size_key_value: {named dims}}  (ISO 4762: P, b, dk, k, s, t ...; from the Fasteners WB CSV, sha recorded)
  feature_templates_json  the MechFeatures every variant of this family exposes (see 3.2), with dims by reference ('dk', 'slot_opening')
  geometry_source   fasteners_wb | nopscadlib | bolts | gridfinity_rebuilt | stu142_wb | polari   (what generates the solid)
  licence           of the dimension data + of the generator ; licence_basis
  material_roles_json   from data/part_material_roles.json: default / alternatives / legacy  (material ids → MaterialDefinition rows)

MechPartVariant     name='iso4762:M5x12' | 'tslot-20-B6:1x1:4s' | 'gridfinity-bin:2x3x6:magnet:lip'
  family ; axis_values_json ; designation ('ISO 4762 M5x12') ; dims_json (the resolved row) ; mass_g (per material, -1 until a material is set)
  features_json     the family's templates resolved to numbers and positions in the part frame
  geometry_ref      '' | artifact sha of a generated .brp/.step (cached, regenerable) ; geometry_basis (generated | ingested)

DimensionSource     one per imported table: library, file, sha256, licence, rows_imported, rows_rejected (+ why)
```

### 3.2 MechFeature — the foothold of a part

```
MechFeature         name='<variant>:<feature>'       e.g. 'tslot-20-B6:1x1:4s:slot:+x' | 'iso4762:M5x12:thread' | 'gridfinity-bin:2x3x6:grid:bottom'
  kind              thread | slot | bore | shaft | face | hole_pattern | grid_cell | belt_tooth | rail | pocket | lip
  key               the compatibility key (the thing that must MATCH on the other side):
                      'M5x0.8' | 'slot-B6/20' | 'bore-8' | 'shaft-8' | 'GT2-6' | 'MGN12' | 'grid-42' | 'magnet-6x2' | 'slide-45-ball'
  role              male | female | channel | rider | plane | cell | socket
  frame_json        origin + axis in the part frame (x,y,z, direction) ; extent (slot length = cut length; thread engagement length)
  dims_json         what the mate needs: thread pitch + engagement; slot opening/depth; bore Ø + tolerance class (H7); face normal + area
  dof_free_json     which of tx ty tz rx ry rz the feature itself leaves free (a slot: tx; a bore: tz + rz; a face: tx ty rz)
  load_rating_json  {axial_n, shear_n, moment_nm, basis}   (-1 = undetermined; a T-nut's slip load, a slide's dynamic rating)
  basis             cited | derived | knob  — and from what
```

Compatibility is a lookup, not code per family: a `MechJoint` is valid when `key` matches and roles pair (male↔female, rider↔channel,
cell↔cell), and the joint's `dof` ⊆ the intersection of both features' `dof_free`. A 20-series T-nut (`slot-B6/20` rider, `M5x0.8` female) in a
2020 slot (`slot-B6/20` channel) taking an ISO 4762 M5 (`M5x0.8` male): two joints, both valid, thread engagement checked against `b` and the
bracket thickness.

### 3.3 Materials (registry → rows; the knob that changes mass, friction, stiffness)

```
MaterialDefinition   name = registry id ('tpu_mdi', 'al_6063', 'pom') ; cls ; status polari_preferred | polari_acceptable | legacy_harmful
  feedstocks_json {name, iarc, note} ; worst_feedstock_iarc ; end_of_life ; bio_option ; replaced_by_json ; caveats_json ; confidence
  density_kg_m3, youngs_gpa, yield_mpa, friction_json {against: mu_static, mu_kinetic, basis}   — -1 until cited (materials_science supplies)
MaterialRole         (family or part category) → default_ids, alternative_ids, legacy_ids, notes      (data/part_material_roles.json)
```
A `MechPartInstance` names ONE material; a legacy one is allowed only with `legacy_reason` set (modelling a part someone owns). The export
report lists every legacy material in the assembly.

### 3.4 Design (the Bench analogue)

```
MechAssembly         name ; kind  frame | drawer | cassette | desk | bin_set | generic ; grounded_instance ; parameters_json (the generator's
                     inputs: grid_x, grid_y, drawer_count, slide_length_mm, top_thickness_mm ...) ; generator ('' | 'gridfinity_desk' ...) ;
                     revision ; parent_assembly ('' | name)  — assemblies nest (a desk holds cassettes holds drawers)
MechPartInstance     name='<assembly>:<ref>' (ref like a KiCad reference: B1, S1, T3) ; assembly ; variant ; material ; cut_length_mm ;
                     placement_json {xyz, rotation} ; placement_basis (solved | given) ; quantity (1; a bin set may say 12) ; mass_g (derived)
MechJoint            name='<assembly>:J<n>' ; assembly ; kind  fixed | revolute | cylindrical | slider | ball | distance | parallel |
                     perpendicular | angle | rack_pinion | screw | gears | belt   (= FreeCAD JointTypes, so export is 1:1) ;
                     instance_a / feature_a ; instance_b / feature_b ; offset_json ; limits_json {length_min/max, angle_min/max} ;
                     ratio (screw pitch, gear ratio) ; preload_json {torque_nm, clamp_n, basis} ; valid ; invalid_reason
MechContact          name ; assembly ; joint ('' when not a joint, e.g. a bin resting on a baseplate) ; pair (instance_a, instance_b) ;
                     kind sliding | rolling | resting | magnetic ; mu_static ; mu_kinetic ; clearance_mm ; basis
MechConflict         (the BoardConflict analogue) ; assembly ; kind  key_mismatch | dof_overconstrained | dof_underconstrained |
                     interference | thread_engagement_short | clearance_hole_small | slide_overload | cantilever_tip ; detail_json
```

### 3.5 Loads, motion, runs (the SPICE analogue)

```
MechLoadCase         name ; assembly ; loads_json [{instance, kind mass | force | pressure, value, point_json, basis}]
                     e.g. a drawer: 8 bins × 180 g contents each, placed on the grid cells they sit in → a resultant + its moment
MechMotionCase       name ; assembly ; joint (the driven one) ; drive  position(t) | velocity(t) | force(t) ;
                     formula ('250*min(t,1)' mm — the FreeCAD Motion Formula, same syntax, so it exports) ; duration_s ; step_s ;
                     checks_json  [{name, criterion}]  e.g. 'opens fully' (reaches length_max), 'smooth' (peak jerk < knob),
                     'no bind' (side force < slide rating), 'hand effort' (pull < 20 N knob), 'stays closed' (detent force > 2 N knob)
MechMotionRun        name ; motion_case ; load_case ; engine  polari | freecad_motion ; engine_version ; worker ;
                     fem_model ('' | FEMModelDefinition name — the structural check of the same load case, run by Polari's fem_engine) ;
                     started / finished ; ok ; report_json (every check with its number) ; provenance (rows + shas) ; freecad_artifact ('' | sha)
MechMotionVector     name='<run>:<signal>' ; run ; signal  position_mm | velocity_mm_s | accel | pull_n | friction_n | side_force_n |
                     tip_moment_nm | deflection_mm | power_w ; samples_json (t, value) ; units ; basis
```

Polari's own engine (mxc-4) is 1-DOF rigid-body dynamics along the joint's free axis: m·ẍ = F_pull − F_friction(μ, N) − F_damper − F_detent,
with the normal force from the load case and the slide's geometry (full-extension cantilever → tip moment → rated-load check). FreeCAD's Motion
object runs the SAME assembly kinematically (position formula) and the run compares position(t). The structural side (panel deflection,
slide-rail stress under the tip moment) is a `FEMModelDefinition` executed by Polari's own `fem_engine` with the material rows bound by
objectRef — the drawer bottom is a region of E, ν and thickness from `MaterialDefinition`, the load case supplies the traction. Where
FreeCAD cannot express something (friction, mass, stress), the report says so; FreeCAD FEM is not an engine here.

### 3.6 FreeCAD interchange rows

```
FreeCadArtifact     path ; kind  fcstd | fcstd_member (Document.xml, *.brp, GuiDocument.xml, thumbnail) | step | stl | csv | py ; sha256 ; bytes ;
                    handling  typed | counted | preserved
FreeCadCoverage     (file, object type 'Part::Feature' | 'PartDesign::Body' | 'Assembly::AssemblyObject' | 'Assembly::JointGroup' |
                    'App::FeaturePython' (Joint) | 'Spreadsheet::Sheet' | 'App::Link' | 'Assembly::BomObject' ...) → count + handling
FreeCadObjectRow    uuid/name ; type ; label ; properties_json (ALL, with the Polari.* group split out) ; shape_sha (the .brp) ; parent
```
Export (mxc-3) = a Python script run by FreeCADCmd on the worker that builds the document from our rows: Part solids from each variant's
generator (Fasteners WB / Gridfinity WB / Polari primitives), an Assembly with our joints (Reference/Placement from the features, limits from
`limits_json`), a Spreadsheet of the assembly parameters, a BOM, the Polari property group on every object; then re-opens it, solves, exports
STEP + BOM CSV, and returns their shas with the report.

## 4. Slices

**Built 2026-11-03 on `dev-mech` (econ, worktrees ~/mech-fw + ~/mech-suite; uncommitted until Dustin says):** ms-anchor (mathshapes:
ShapeAnchor/AnchoredOffset rows, ray pick, four-way frame, offset fields, the M5 internal-thread seed; 41/41), mxc-1 (catalogue 25 families /
401 variants / 1277 features / 21 sources with shas + licences, 54/54; materials 53 options / 35 preferences registered in composition's
property lookup, 53/53), mxc-2 (assembly rows over composition, rigid-group DOF count, fit checks, fixtures mfx-1 (M4) / mfx-2 / mfx-3,
82/82), mxc-4 (one 1-DOF engine linear + rotary, runs over core simulations with sha + confirmation, FreeCAD reference match 1e-14 mm,
37/37), and the engines as rows (9 analyses + 9 solutions, 21/21 over the full seed set). Module registered (polari-app.json,
polari-modules.json, FEATURE_MODULES/REQUIRES, feature_imports); conform OK. Owed from the build: `DimensionSource` uses
`license_*` (MeshAssetSource's spelling); `PART_FUNCTIONS` gap (9.2) not yet verified; composition archetypes `at-screw`, `at-nut`,
`at-t-nut`, `at-extrusion`, `at-bracket`, `at-bearing`, `at-linear-bearing`, `at-linear-rail`, `at-leadscrew`, `at-belt`, `at-pulley`,
`at-gridfinity-bin`, `at-drawer-slide` referenced by families but not yet seeded in composition; the catalogue's `gridfinity-lid`,
`pulley-gt2-*-b8`, `leadscrew-tr8-TR8x4`, `bearing-ball-625` are hand-derived (basis flagged); IARC rows unchecked against monographs.
Next: mxc-3 (FreeCAD ingest/export + the worker on isle-core), mxc-3b, mxc-5 (the generator = the first `MechSystemDefinition`), mxc-6
(pages as DisplayDefinition rows, no code), then mxc-7 clock, mxc-8 printers.


| Slice | What | Acceptance |
|---|---|---|
| **mxc-1** catalogue + features + materials | `mech` module. Import the Fasteners WB CSVs (ISO 4762 / 7380-1 / 10642 / 4026-9 / 4032 / 4035 / 7089 / 7093, DIN 508 T-nuts) and NopSCADlib tuples (E1515–E4080 extrusions, brackets, sliding/hammer T-nuts, 608/625 bearings, MGN rails, LM bushings) as `DimensionSource` + `MechPartFamily` rows with feature templates; `MaterialDefinition` / `MaterialRole` from the registry; a Gridfinity family (bin, baseplate, lid) from the rebuilt constants; a `drawer_slide` family (ball-bearing side-mount: 45 mm high, 12.7 mm per side, lengths 250–600 step 50, 3-fold full extension; rated load as a cited knob). Compatibility lookup. | Every family has a licence + sha'd source; M2–M8 ranges equal the WB `*range` tables; T-nut ↔ slot ↔ screw lookups pass and a wrong pairing (M6 nut in a B6/20 slot) is a `MechConflict`; no family without material roles. |
| **mxc-2** assembly graph | `MechAssembly / Instance / Joint / Contact / Conflict`; the DOF solver (count free DOF per instance; over/under-constrained named); fit checks (thread engagement ≥ 1·d steel / 2·d aluminium / 2.5·d plastic — knobs; clearance holes per ISO 273; slot/T-nut pairing; grid cell occupancy). Fixture ladder mfx-1 (one 2020 beam + 2 inner brackets + 4 T-nuts + 4 M5 screws), mfx-2 (2×2 Gridfinity bin on a 2×2 baseplate with magnets). | mfx-1 has 0 free DOF with 4 valid joints; removing a screw → under-constrained, named; mfx-2 bin's bottom grid cells match the baseplate's; a 3×2 bin on a 2×2 plate is a conflict. |
| **mxc-3** FreeCAD interchange | Ingest `.FCStd` (zip members → artifacts; Document.xml → object rows + coverage) and STEP; export the assembly as above; the `Polari` property group round-trips; `FreeCadCoverage` lists every object type; the worker on isle-core (FreeCAD 1.1.x) + optionally econ (AppImage). Engine selection like `pcb_engines`. | mfx-1/2 export → re-open → Assembly solves → re-ingest reads the same Polari.* on every part; STEP volume per part within 0.1 % of ours; FreeCAD BOM = our instance list. |
| **ms-anchor** (mathshapes' own slice, not mxc) anchored offset tool (8.5) | `ShapeAnchor` + `AnchoredOffset` rows, ray pick on the field, the four-way reference toggle, offset field as a matrix equation in the anchor frame (constant / varying), executor gains atan2, mod/frac, list min/max, ∇F operand; its own API + page + selftest. Prerequisite for mxc-1's threads and pockets and for mxc-3b's Thickness/Helix mapping. | The acceptance list at the end of 8.5. |
| **mxc-3b** MathShape ↔ FreeCAD parametric bridge (section 8) | Export a `MathShapeDefinition` as a FreeCAD feature tree (primitives, booleans, extrude/revolve of planar regions, patterns, Spreadsheet knobs from `parameters_json`); ingest a FreeCAD feature tree into a MathShape where a math form exists, else `family='parametric-only'` with the artifact sha and a sampled surface, equation form refused by name. The `mech` catalogue generators are written AS MathShapes (a profile = extrude of a region; a screw = revolve + boolean), so every standard part has both forms from the start. Gap list in 8.3 becomes mathshapes slices (mq-/ms- numbering, pol-core's call). | Round trip of each primitive and CSG op is exact (volume, sampled field equal); a 2020 B-type profile and an ISO 4762 M5 both go MathShape → FreeCAD → MathShape with volume within 0.1 %; a fillet comes back as a knob + `approx` basis, a loft as `parametric-only`; nothing silently dropped (coverage row per FreeCAD feature type). |
| **mxc-4** motion + load | Polari 1-DOF engine; `MechLoadCase` from bin contents; the drawer motion checks; friction knobs by `MechContact` (ball slide μ 0.01–0.03, UHMWPE-on-aluminium 0.1–0.2, wood-on-wood 0.25–0.5; all knobs until measured); FreeCAD Motion (kinematic position) as the reference run; bottom-panel deflection and slide-rail stress as a `FEMModelDefinition` on Polari's `fem_engine` (one gap to close there, not in FreeCAD: `solve_elasticity_2d` is in-plane; a loaded drawer bottom is a plate in BENDING — add a Kirchhoff plate solve (scikit-fem's Morley element) or route a 3-D elasticity problem to the msci-engines worker, and keep the closed-form simply-supported-plate deflection as the knob-check both must bracket). mfx-3: one drawer cassette (2 slides, drawer box, front, handle, 2×3 Gridfinity baseplate inside). | Unloaded drawer opens 250 mm under a 5 N pull within the duration; loaded (8 bins, 1.5 kg) needs < 20 N and the tip moment at full extension stays under the slide rating; a legacy "wooden runner, no slide" variant needs > 20 N and is reported; Polari position(t) equals FreeCAD Motion position(t) for the same formula within 0.1 mm; Polari FEM deflection of a 3 mm PLA bottom vs 6 mm plywood differs in the direction the closed-form plate formula predicts and both sit within the mesh-convergence band; no call into FreeCAD's FEM workbench anywhere in `mech`. |
| **mxc-5** Gridfinity desks + drawers generator | `generator='gridfinity_desk'`: inputs (desk W×D×H, drawer grid X×Y per cassette, cassette rows, height units per drawer, slide family, material per role from `MaterialRole` defaults) → T-slot frame (2020/2040, brackets, T-nuts), top panel, cassettes, drawers, slides, bins; cut list (profiles by length), print list (bins, baseplates, drawer fronts by material + grams), fastener count; all legacy materials flagged. mfx-4: a 2-cassette, 3-drawer desk. | The generated assembly passes mxc-2 checks with 0 conflicts; its FreeCAD export solves; cut list lengths sum to the stock bought (6 m bars, kerf knob); changing one parameter (drawer height 6u→9u) changes only the rows it should (diffable). |
| **mxc-6** views | Catalogue browser (family → variants → features), assembly tree with joint DOF, the motion run as sci-xy-chart (position / pull / side force over t), materials panel showing status colours and the legacy list, cut + print lists. | Theme tokens, no raw JSON, click-toggle. |
| **mxc-7** clock splice (9.2) | M0 movement as a `MechAssembly`; arbors/plates/bearings from the catalogue; gear meshes as joints with `gear_mesh_ref`; rotary engine on the rotor with reflected inertia; `MotorVerificationRun.motion_run_ref`; `ShaftNodeDefinition.mech_variant_ref`; `PART_FUNCTIONS` gap verified + fixed. | 1 free DOF; ratios unchanged vs `solve_train`; missed-step / max-rate / ring-out numbers reported with the measured run beside them. |
| **mxc-8** printer splice (9.3) | `PrinterAssemblyDefinition.mech_assembly_ref`, `PrinterDefinition.assembly_ref`; M1 axis as a screw joint on the linear engine fed by `PrinterAxisRequirement`; `max_accel` as a check; printable variants as a `SliceJob.shape_class`. | M1 torque-vs-pull-in unchanged when fed by mech; a Voron 2.4 gantry at 3000 mm/s² reports belt tension and frame deflection; waxprint thermal selftests unchanged. |

## 5. Placement

Rows, catalogue import, compatibility, DOF, the 1-DOF engine, generators = framework (pure Python; numpy already there). FreeCAD runs
(export build, solve, STEP, BOM, Motion — never FEM) = the FreeCAD worker on **isle-core** (FreeCAD already installed there) — a second worker on econ
via the 1.1.4 AppImage (820 MB, user-space, no sudo) for cross-checks, the way econ is the KiCad worker. The `mathshapes/cad_remote.py`
container is the base to extend rather than a new one. Reference fixtures (mfx-1..4) + their FreeCAD-produced reference outputs (STEP shas,
BOM CSV, motion CSV) live under `modules/mech/custom/upstream/<fixture>/SOURCE.json` and `modules/mech/custom/reference/` (the pcb convention).

## 6. Decisions (his)

- **D-mxc-0** Confirm the kxc ruling applies to FreeCAD unchanged (Polari truth; ingest all; export what we can; no sync).
- **D-mxc-1** Gridfinity licence: the spec page permits private + commercial use but names no licence. Take the geometry from
  `gridfinity-rebuilt-openscad` (MIT) and cite the spec, or ask Zack Freedman for a named licence first? Recommended: MIT source + citation; log the gap.
- **D-mxc-2** FreeCAD version pin: 1.1.x (needed for Assembly Simulation/Motion; what does isle-core have?). Recommended: pin 1.1.4, record
  `engine_version` on every run as kxc does for kicad-cli.
- **D-mxc-3** DECIDED (his, 2026-11-03): regenerate geometry from parameters; no stored solids. A row holds parameters + the generator name
  + its version; a `.brp`/STEP exists only as a transient worker output (its sha recorded on the run that made it, then discarded).
  Views render from the math form (mathshapes' sampled surface / marching voxels) so no FreeCAD is needed to look at a part.
- **D-mxc-4** Dynamics engine: Polari's own 1-DOF integrator (recommended, mirrors the SPICE renderer) vs. depend on FreeCAD Motion (kinematic
  only — cannot answer "with a load").
- **D-mxc-5** Drawer running gear to seed first: steel ball-bearing slides (standard, cited ratings, legacy NBR-free but steel + zinc) vs.
  printed UHMWPE/PA runners on T-slot (no metal slide, fully in-house, friction higher). Recommended: both as families; the generator takes
  either; the motion run shows the difference.
- **D-mxc-6** Where this lives: a new `mech` module (recommended; composition keeps archetypes/failure modes and is referenced) vs. growing
  `composition`.
- **D-mxc-7** DECIDED (his, 2026-11-03): structural analysis = Polari's materialsScience FEM (`fem_engine`, `FEMModelDefinition`, msci-engines
  worker), never FreeCAD's CalculiX workbench. Mech rows reference `FEMModelDefinition` by name; the one addition this plan asks of the FEM side is
  out-of-plane plate bending (mxc-4), which belongs in `fem_engine`, not in `mech`.
- **D-mxc-8** DECIDED (routine, 2026-11-03, section 9): MechJoint is a thin row over `composition.InterfaceDefinition`; MechAssembly/Instance
  reference `CompositionNode` / `PartComponentDefinition`; no BOM row; MechPartFamily carries `archetype_ref`.
- **D-mxc-9** DECIDED (section 9): no fourth material identity — `MechMaterialOption` mirrors `MagneticMaterialOption` and registers in
  `composition.data_refs.MATERIAL_PROPERTY_CLASSES`; `MaterialRole` becomes `MechMaterialPreference` checked through `role_viability()`.
- **D-mxc-10** DECIDED (section 9): `DimensionSource` takes `MeshAssetSource`'s licence field names; `FreeCadArtifact` references
  `ImportedCadObject` and extends `cad_remote`.
- **D-mxc-11** DECIDED (section 9): motion runs ride core `simulations/` (`SimulationRun` + `MechMotionSimState` + `build_series`); one
  1-DOF engine, linear and rotary, shared by the drawer, the M1 printer axis and the clock rotor.
- **D-mxc-12** (his): order of the consumers after the desk/drawer — clock (mxc-7) before printers (mxc-8), recommended because the clock
  has measured runs to compare against and GEARS_PLAN already defers to exactly this.

- **D-mxc-14** DECIDED (his, 2026-11-03: "woah you should not be making custom apis … polari fully automates away api creation so
  long as functionality and engines are wrapped by polari properly"): mech has NO `<pkg>_api.py`. Rows are auto-CRUDE; the engines are
  `AnalysisDefinition` rows (`callable_ref` → `mech.custom.analyses:<fn>`, `fn(manager, **params) -> dict`) plus one
  DirectInvocation → AnalysisCall → ReturnValue `SolutionDefinition` each (`mech_analysis_seed.py`), run through the generic
  solution-execution routes and composable as SolutionInvocation steps. Same rule for mxc-3/5/6 and for mathshapes' anchor routes
  (done for ms-anchor too, same day: `shape_api.py` reverted to its 9 pre-slice routes; 6 analyses + 6 solutions in `shape_anchor_seed.py`, 53/53).
- **D-mxc-13** (his — Systems vs Solutions naming, his rule of 2026-11-01, raised by pol-core): a catalogue family or a `kind='clock_movement'`
  template reads as a SYSTEM; an assembly bound to specific variants reads as a SOLUTION. Recommended: `MechAssembly` stays the bound Solution
  and gains `system_ref` (added in mxc-2); the template becomes `MechSystemDefinition` (kind, generator, parameter schema, roles) in mxc-5 — the
  `gridfinity_desk` generator is the first System. Words to confirm before the rows ship.
## 7. Carried from the materials work (2026-11-03)

- Materials are chosen by role with a status; `legacy_harmful` needs a reason. The registry's IARC rows are from knowledge, not yet checked
  against the monographs — the import marks `confidence` and the view shows it.
- Bearings default to ZZ metal shields (no elastomer); 2RS seals are NBR (legacy). Belts default to MDI polyurethane. Inserts to lead-free brass.
- The "minimise steps" rule is a data property: `MechPartFamily.process_steps_json` (cut | drill | tap | print | none) so a generator can
  prefer cut-only frames and print-only bins, and a view can count the steps a design needs.

## 8. MathShapes ↔ FreeCAD parametric (his direction, 2026-11-03)

> "We do not want to replicate CAD, the purpose of mathshapes is to be customized to the physicist and mathematician. It is to allow
> interchange between them, where the mathshape is defined by math equations and/or no-code for math and programming logic. While the
> FreeCAD is defined via parametric logic."

So the bridge converts between two DEFINITIONS of the same solid, not between two CAD systems:
- **MathShape side:** a solid is an implicit field F(p) < 0 built from surfaces (quadric matrices pᵀQp, planes as degenerate quadrics) by CSG
  algebra (intersection → max, union → min, difference → max(a, −b)), plus knobs in `parameters_json`, all of it also as no-code matrix-equation
  rows the `matrix_equation_executor` evaluates (MATRIX_SHAPE_COHERENCE_PLAN mq-1). Winding shapes are parametric curves. Meshes have no equation.
- **FreeCAD side:** a solid is a feature TREE (sketch → pad → pocket → fillet → pattern …) with a Spreadsheet of parameters and an expression
  language; the result is a BRep (NURBS faces) that OpenCASCADE evaluates.

The test for "does this belong in mathshapes": can the no-code executor evaluate it from rows? If yes, it is a math form and converts exactly.
If the only representation is a NURBS face set, it is `parametric-only` and mathshapes says so (the existing HONEST ABSENCES rule).

### 8.1 Feature mapping (what converts, how, which way)

| FreeCAD feature | Math form | → FreeCAD | → MathShape | Mathshapes today |
|---|---|---|---|---|
| Part::Box / Cylinder / Sphere / Cone / Ellipsoid | primitive quadrics + planes | exact | exact | box, sphere, cylinder, cone, frustum, ellipsoid ✓ |
| Part::Torus | quartic (x²+y²+z²+R²−r²)² − 4R²(x²+y²) = 0, or revolve of a circle | exact | exact | ✗ not a quadric — needs 8.3 (3) |
| Part::Prism / Wedge | extrude of polygon / tapered box = plane intersections | exact | exact | polygon ✓ (2D), extrude ✗ |
| Part::Cut / Fuse / Common | difference / union / intersection | exact | exact | csg ✓ |
| Sketch: lines, arcs, circles | planar REGION = CSG of half-planes and disks in 2D | exact | exact | polygon only; arcs/disks ✗ |
| Sketch: B-spline | no closed form | — | approximated (polyline + `approx`) | ✗, say so |
| Sketch constraints + expressions | a system of equations over the knobs | expressions | no-code equation rows | the matrix-equation rows ✓ (new use) |
| Pad / Extrude (with draft) | F = max(F₂d(x,y) − z·tan α, \|z − c\| − h/2) | exact | exact | ✗ needs 8.3 (1)(2) |
| Revolution / Groove | F(r, z) with r = √(x²+y²): profile lines → cones/cylinders/planes, arcs → spheres/tori | exact | exact | ✗ needs 8.3 (3) |
| Pocket / Hole | difference with a pad | exact | exact | csg ✓ |
| Chamfer | intersection with extra planes | exact (as planes) | exact | ✓ expressible now |
| Fillet (3D edge) | rounding: exact only for a few cases (rounded box = offset of a smaller box); otherwise smooth-min with a radius knob | exact (radius knob → FreeCAD Fillet) | `approx` + knob | ✗ 8.3 (5) |
| Mirror / LinearPattern / PolarPattern | F(Mp); min over translates / rotations | exact | exact | ✗ 8.3 (4), cheap |
| Thickness / Offset (shell) | F(p) − t — exact only when F is a true signed distance; quadric fields are not | exact (t knob) | `approx` unless an SDF exists | ✗ 8.3 (6): a real math item |
| Loft / Sweep / Helix (threads) | parametric SURFACE S(u, v) | exact (as the FreeCAD feature) | `parametric-only` + sampled | winding = parametric CURVES only; 8.3 (7) |
| Spreadsheet cells + expressions | knobs + equations | from `parameters_json` | into `parameters_json` + equation rows | ✓ ImportedCadObject.parametric_params_json already pulls these |
| App::Link / Assembly | not a shape — section 3 MechAssembly / MechJoint | — | — | — |
| Mesh::Feature, STL | no equation | — | `imported-mesh`, refused by name | ✓ (kept) |

Direction of truth is unchanged: the MathShape (Polari row) is the design; a FreeCAD feature tree is an export of it or an ingested revision.
A feature we cannot map is PRESERVED (FreeCadCoverage) and the shape becomes `parametric-only` with the artifact sha — never faked as a quadric.

### 8.2 Why this covers the standard parts

Every catalogue family in section 3 is one of three math forms, which is why mxc-1's generators are written as MathShapes:
- **extrude of a planar region:** T-slot / V-slot profiles (polygon + arcs for the slot throat and centre bore), joining plates, brackets, T-nuts,
  nuts (hexagon − disk), washers (annulus), Gridfinity baseplates and bins (rounded rectangle = polygon ∪ 4 disks — its 2D signed distance is
  exact, so the 45° base chamfer is a draft-extrude of that SDF), drawer boxes and fronts;
- **revolve of a profile:** screw shank + head (socket = pocket of a hexagonal prism), bearing rings, shafts, pins, standoffs, magnets;
- **booleans of those:** holes, counterbores, slots, magnet pockets.
Threads are a helix sweep (parametric-only) → represented as a cylinder plus the `thread` MechFeature (pitch, engagement), as the Fasteners WB
"cosmetic thread" option does; the sweep is exported to FreeCAD only when asked (knob). Nothing in the first-goal kit needs a loft.

### 8.3 What mathshapes needs added (FreeCAD as the guideline, not the template)

Each is a math definition with a no-code row form, not a CAD feature. Order = what the desk/drawer kit needs first.
1. **Planar region** family: a 2D CSG of half-planes, disks and annular sectors (lines, arcs, circles of a sketch) with an exact 2D signed
   distance for polygons and rounded polygons. (polygon exists; arcs and disks do not.)
2. **Extrude** op: region × axis × height × draft angle × twist (twist = 0 for now). Profiles, plates, bins.
3. **Revolve** op: region × axis × angle. Gives torus (quartic) and every turned part. Add a `quartic` surface kind beside `quadric` so the
   matrix form stays honest (a torus is not a 4×4 Q; it is a degree-4 polynomial — store its coefficients, same executor pattern).
4. **Transform + pattern** CSG nodes: mirror, translate, rotate, linear and polar repeat — F(Mp) and min over copies. Fastener patterns, grids.
5. **Rounding knob** on CSG intersections (smooth-min with radius) marked `approx`; exact rounded-box as a primitive.
6. **Signed-distance normalisation** of a field — the Eikonal problem; offsets/shells and clearance checks need it. A research item for the
   mathematician (which fields admit an exact SDF; where a bound suffices), not a CAD feature to copy.
7. **Parametric surface** family S(u, v) beside winding's curves — helix/thread, sweep, loft — evaluated by sampling; no implicit field, said.
8. **`parametric-only`** shape family: FreeCAD artifact sha + sampled surface + the list of unmapped features. Exists in spirit for meshes.
9. **Anchored offset** (8.5): ray-pick an anchor, a reference toggle, an offset field in that frame that may vary with position — the user-facing form of offsets, shells, patches and threads; makes (6) needed only for `conform` on non-distance fields.

### 8.4 Rows

```
MathShapeDefinition   + family 'region' | 'parametric-only' (+ 'quartic' surface kind) ; + op nodes extrude | revolve | transform | pattern in csg_json
ShapeBridgeMap        name='<shape>:<freecad object>' ; shape ; freecad_object (FreeCadObjectRow) ; feature_type ; mapping exact | approx | preserved ;
                      knob_links_json [{param, spreadsheet_cell | expression}] ; basis
```
Acceptance beyond mxc-3b's: the matrix-equation rows of an exported shape and the FreeCAD Spreadsheet of the export name the SAME knobs, so a
physicist changing a knob in Polari and an engineer changing the cell in FreeCAD are editing one number with two names, and the re-ingest diff
shows it as one change.

### 8.5 The anchored offset tool — its own tool inside mathshapes (his direction, 2026-11-03)

His ruling: "that should be its own unique tool inside math shapes." So this is NOT a sub-feature of the FreeCAD bridge or of the mech
catalogue. It is a mathshapes tool in its own right — its own rows (`ShapeAnchor`, `AnchoredOffset`), its own API (`/api/shapes/anchor`,
`/api/shapes/offset`), its own page (pick on the rendered shape, the four-way toggle, the equation editor in the anchor frame, a live preview
of the result), its own selftest, and its own slice in the mathshapes plan (pol-core to number it: ms-anchor or similar). The mech catalogue
and the FreeCAD export are CONSUMERS of it (a thread on a screw, a magnet pocket in a bin), never its owner. The description below is what
that tool does.

> "...manually define and/or select a point/normal vector of a plane on an existing math shape based on a ray vector pointing towards it ...
> toggle whether the direction towards us, away from us, or tangential ... is the reference ... then define an Offset planar surface via a
> matrix equation ... conform to the surface or just be a normal square or circle ... define that offset to vary as it moves further from the
> normal vector ... such that we could do something like defining a thread inside a part"

The offset is measured from a FRAME the person picks on the shape, not from the whole surface. That makes it exact wherever the reference is a
plane or an axis (distance to a plane is linear; to an axis, √(u²+v²)), and leaves the Eikonal question (8.3 item 6) only for the one mode that
asks the offset to follow a non-distance field everywhere.

**Step 1 — pick the anchor by a ray.** A ray r(s) = o + s·d (the page camera, or typed) hits the shape where F(r(s)) = 0. For a quadric that is a
quadratic in s (exact); for CSG, the nearest surface among the operands' hits that lies inside the composed field; for `parametric-only`, the
sampled mesh then refined on the field where one exists. At the hit p₀ the normal is n = ∇F/|∇F| — for a quadric ∇(pᵀQp) = 2Qp, already a matrix
form, so the anchor's normal is itself a no-code row.

**Step 2 — choose the reference direction (the toggle).** With the viewer's direction d and the outward normal n at p₀:
| toggle | reference axis a | use |
|---|---|---|
| toward us | n flipped so a·d < 0 (the face looking at the viewer) | offsets that grow out of the surface |
| away from us | −(toward us) | pockets, holes, inward shells |
| tangential, most toward us | t₁ = normalise(−d − (−d·n)n), the in-plane direction leaning at the viewer | ridges, slots, patterns running across the face |
| tangential, most away | −t₁ | the same, the other way |
The frame is (a, b, c) with b = n × a (or t₂ = n × t₁ when a is tangential) and c = a × b; local coordinates (u, v, w) = ((p − p₀)·a, ·b, ·c).

**Step 3 — the offset surface as a matrix equation in that frame.** The person writes or picks a field G(u, v, w) < 0 as a matrix-equation row:
- *planar patch*: w − t = 0 bounded by a square (4 half-planes) or a disk (w − t = 0 ∩ u² + v² ≤ R²) — degenerate quadrics, exact;
- *conform*: the existing surface moved along the reference — G(p) = F(p − t·a) for a plane-like reference (exact), or F(p − t·n(p)) for a
  curved one (first-order offset; marked `approx` unless F is a distance; this is where 8.3 (6) still applies);
- *anything else*: whatever 4×4 Q or composed equation they type, in the anchor frame — the executor does not care what it describes.

**Step 4 — let the offset vary with position in the frame.** t becomes a function t(u, v, w) given as an equation row. Examples that fall out:
- constant t → a shell or a raised pad;
- t = k·w → a draft/taper;
- t = A·sin(2πu/λ) → a corrugated face;
- **a thread**: take the reference axis a as the thread axis (so w runs along it and θ = atan2(v, u) around it); the ridge is the region
  |frac((w − (P/2π)·θ)/P) − ½| < h/P between radii r and r + depth — an internal thread when subtracted from the part, external when added.
  P = pitch, h = ridge width, depth = thread depth; all knobs, all from the ISO 68-1 profile table the Fasteners WB carries.
  This needs `atan2`, `frac`/`mod` in the no-code executor's function set (a small addition, listed below).

**Rows**
```
ShapeAnchor        name ; shape ; ray_origin_json ; ray_dir_json ; hit_json (p₀) ; normal_json (n, as the ∇F row name) ; reference
                   toward | away | tangent_toward | tangent_away ; frame_json (a, b, c) ; basis exact | sampled
AnchoredOffset     name ; anchor ; mode planar_square | planar_disk | conform | custom ; surface_eq (MatrixEquationDefinition in the anchor
                   frame) ; offset_eq ('' = constant t ; else an equation row t(u, v, w)) ; t ; extent_json ; op add | subtract | intersect ;
                   result_shape (the new MathShapeDefinition, a csg node over the parent + this field) ; approx_reason ('' when exact)
```
The result is an ordinary MathShape, so it exports to FreeCAD as a feature (planar patch → Pad/Pocket on a datum plane at the anchor; conform →
Thickness/Offset; thread → Helix sweep or cosmetic thread), and the anchor rides along as `Polari.Anchor` so a re-ingest finds the same frame.

**Executor additions needed:** atan2, mod/frac, min/max over a list (patterns), a per-point normal (2Qp) as an operand. All small.

**Acceptance (joins mxc-3b):** a ray onto the unit sphere returns p₀ and n = p₀ exactly; the four toggles give the four stated axes; a planar
disk offset t = 2 on a box face has volume base + πR²·2 exactly; conform on a sphere by t gives a sphere of r + t exactly and on an ellipsoid is
marked `approx`; an M5 internal thread cut into a cylinder bore by the thread equation has the ISO 68-1 minor diameter within 0.01 mm and a
pitch of 0.8 mm measured on the sampled surface; the same shape exported to FreeCAD re-ingests with its anchor.

## 9. How mech meshes with what already exists (surveyed 2026-11-03, his ask: "check we did not flush out something similar and forgot")

Two read-only surveys of the framework (printer side: printing_suite, voron, printcam, kirimoto, waxprint, casting, meshassets; machine side:
composition, gears, motors/clock, magnetics, materials_science, instruments, mathshapes, core `simulations/`) against the rows in section 3.
Short version: **nothing anywhere has a standards catalogue, part features, a joint kind with limits, a DOF solver, friction, dynamics, or a
persisted mechanical time series** — those are genuinely new. But four of the draft's rows would have been a second copy of something that
exists, and the plan is corrected below so mech EXTENDS those rows instead. The rules that follow are decided (routine calls, his veto open).

### 9.1 Overlaps found, and the rule for each

| Draft row (section 3) | What already exists | Rule |
|---|---|---|
| `MechJoint` (kind, dof, limits, ratio, preload) | `composition.InterfaceDefinition` (`member_a/b`, `designed_separable`, `dof_removed_json` over `DOF_AXES` tx..rz, `retention_scheme` ∈ `RETENTION_SCHEMES` snap/groove/fastener/adhesive/mortar/press/wound/none, `failure_mode_refs_json`, `equation_refs_json`) — DATA ONLY, nothing computes with it; motors' `m1_composition_seed.py` (lines ~70, 81) uses `'monolithic'`, which is not in the enum (vocabulary drift; adding it heals that seed — verified by pol-core at 673fe74b) | `MechJoint` is a THIN row: `interface_ref` → an `InterfaceDefinition` it creates/updates; joint kind, feature pair, limits, ratio, preload live on MechJoint; DOF free = complement of `dof_removed_json` and the two are kept consistent by the mech API (one writer). Retention maps onto `RETENTION_SCHEMES`; add `'monolithic'`, `'magnetic'` to composition's enum and validate. Failure modes stay composition `FailureModeDefinition` (fastener back-out, preload loss, fretting are already seeded). `MechConflict` = fit checks only. |
| `MechAssembly` / `MechPartInstance` | `composition.CompositionNode` (`members_json`, nesting, `derive_level()` component/part/assembly) + `PartComponentDefinition` (`material_ref`, `shape_ref`, `quantity`); EBOM = `FunctionalPartDefinition`, MBOM = `ConstructionVariantDefinition` → members → `RoutingDefinition` | `MechAssembly.node_ref` → `CompositionNode`; `MechPartInstance.component_ref` → `PartComponentDefinition` (placement + variant are mech's). **No BOM row**: the BOM is emitted from members + construction variant; the cut list and print list are computed outputs of mxc-5 (nothing in the repo has a cut list — HOUSEHOLD_ENERGY_APPS_PLAN 393–435 lists it as a gap). |
| `MechPartFamily` | `composition.PartArchetypeDefinition` (parameters, `equation_refs_json`, `failure_mode_refs_json`, `role_refs_json`, selection procedure); `gears.GearTypeDefinition`/`GearDefinition` is the closest "type + sized body" precedent | Family stays NEW (standards, dimension tables, variants, licences exist nowhere) but carries `archetype_ref`; equations / failure modes / roles are NOT re-listed. Seed archetypes for screw, T-nut, bearing, drawer slide, shaft where missing (shaft, pinion exist). |
| `MechFeature` | nothing (no key/role matching anywhere) | New, in mech. The `InterfaceDefinition` reached through a MechJoint points at the feature pair. |
| `MaterialDefinition` | THREE material identities already (`MaterialsScienceMaterial` — the bridge, `MagneticMaterialOption` — the property-bearing row composition/motors actually read via `composition/custom/data_refs.MATERIAL_PROPERTY_CLASSES = ('MagneticMaterialOption',)`, legacy `Material`/`ReferenceMaterial`); MATERIALS_SCIENCE_MODULE_PLAN:189 already complains | **No fourth identity.** `MechMaterialOption` mirrors `MagneticMaterialOption`'s shape exactly (`msci_material_ref` by name, `properties_json {prop: {value, unit, provenance}}`, `item_ref`) and is REGISTERED in `MATERIAL_PROPERTY_CLASSES` (one data-only line) so `role_viability` / `material_prop` read it unchanged. Density, E, ν, yield, hardness, `friction_json` (per counter-material), and the registry's IARC / status / feedstocks / replaced_by fields live on it. No property class in the repo has friction or E today — this fills that. First consumers to migrate: waxprint `DeviceMaterialDefinition` refs that dangle (aluminum-6061, stainless-304, ptfe, tool-steel, borosilicate-glass match no row), casting feedstock constants, printing_suite `PrintProfile`'s datasheet constants. |
| `MaterialRole` | `composition/custom/part_roles.py` `ROLE_REQUIREMENTS` (moving, colliding, sliding, press-fitted, static-structural, … as property predicates, `role_viability()`), `magnetics.MaterialUseRole` rows (role + predicates), `FunctionalPartDefinition.allocated_role_refs_json` | **Not a third role taxonomy.** Renamed `MechMaterialPreference`: one row per part category → `default_ids`, `alternative_ids`, `legacy_ids`, `role_refs_json` naming the composition roles the part plays (a slide = sliding + static-structural), `notes`. A preference is checked by `role_viability()` against the option's properties, never by its own predicates. |
| `DimensionSource` | `meshassets.MeshAssetSource` (SPDX, licence statement, verification method, `approximation_valid`) | Same field names (`licence_spdx`, `licence_statement`, `verification_method`) + `url`, `commit`, `path`, `sha256`, `fetched` — a sibling with the same shape, not a third licence gate. |
| `FreeCadArtifact` | `mathshapes.ImportedCadObject` (`source_format` incl. fcstd/step, `minio_key`, `parametric_params_json`, `importer` trimesh/freecad) + `cad_remote.py` worker (`WITH_FREECAD`); `casting/custom/mesh_voxelize.py` consumes it | `FreeCadArtifact.cad_object_ref` → `ImportedCadObject`; the worker is `cad_remote` extended, never a parallel ingest. `FreeCadObjectRow` / `FreeCadCoverage` stay (nothing reads Document.xml today). |
| `MechMotionRun` / `MechMotionVector` | core `simulations/` (`SimulationDefinition`, `SimulationRun`, per-step `*SimState` rows, `simulation_series.build_series`) — used by the 3-D pendulum; `MotorVerificationRun` / `GearVerificationRun` are scalar-only; `WaveformCapture` is the scope's | `MechMotionRun.simulation_run_ref` → `SimulationRun`; the engine writes `MechMotionSimState` rows per step that `build_series` reads; `MechMotionVector` is the named signal extracted from them (position, pull, side force, tip moment). Add optional `motion_run_ref` to `MotorVerificationRun` / `GearVerificationRun` so bench_campaign's measured runs and sim vectors compare (mxc-7). |
| the 1-DOF engine | `motors.custom.motor_designer.clock_sim` (quasi-static co-energy, "inertia, friction and damping not modelled"), `gears.custom.gear_kinematics.solve_train` (quasi-static ratios), `motors/objects/m1_positioning` `PrinterAxisRequirement` (leadscrew lead 1.25 mm/rev, 5 N axis load, η 0.3 → torque vs pull-in) | **One engine, generalised**: `q̈ = (F_drive − F_friction(μ, N, sign q̇) − F_damper − F_load) / M` with q linear (drawer, M1 printer axis) or rotary (`J·θ̈ = T_drive − T_friction − T_load`, clock rotor with reflected inertia through `solve_train`'s ratios and the hand gravity load from `_hand_drivability`). The drawer is the FIRST consumer, not the shape of the engine. motors and gears get dynamics by calling it, not by growing their own. |

### 9.2 The clock (motors M0 + gears) as the second consumer — slice mxc-7

What the clock sim is today: a Lavet stepper settled quasi-statically per pulse → `solve_train` ratios → hand angles vs true time
(`timekeeping_proof`); `_hand_drivability` compares m·g·r_cg of the hands against shaft torque and says "friction (not modeled) is the residual
load". No escapement, no pendulum. Plates, arbors and bearings are named ABSENT (`clock_assembly_seed.py:296`); `ShaftNodeDefinition.bearing_item_ref`
is a supplychain string ('bearing-608'); shafts have no diameter or material. GEARS_PLAN 46–52 / 284–288 defer dynamics and bearing selection
explicitly — mech fills exactly that.

mxc-7 (after mxc-2 and mxc-4): the M0 movement as a `MechAssembly kind='clock_movement'`, `node_ref` = the M0 composition node; instances = the
`MotorPartDefinition` bodies and gear bodies through `component_ref`, plus the plates and arbors as catalogue variants (8 mm rod, 608 / bushing);
each arbor a revolute `MechJoint` to the plate; each `GearMeshDefinition` a `MechJoint kind='gears'` with `gear_mesh_ref` (ratio DERIVED from the
mesh, stored once). Acceptance: the DOF solver finds exactly 1 free DOF (the rotor); `solve_train` stays the ratio authority; the rotary engine
reports missed steps from inertia, maximum pulse rate, ring-out past the detent and hand settle time, with the measured `MotorVerificationRun`
beside it; worm self-lock for M2 gets a μ instead of 'unassessed'. `ShaftNodeDefinition` gains `mech_variant_ref` next to `bearing_item_ref`.
Pre-existing gap to fix on the way: `PART_FUNCTIONS` (motors `motor_parts/_shared.py:4`) lacks 'speed-reduction', 'indication', 'balance' that
`clock_assembly_seed.py` uses (coerced to 'structural' on a fresh `cls(**seed)` insert) — not run-verified; verify, then fix.

### 9.3 The printers (voron, waxprint, motors M1) as the third consumer — slice mxc-8

What the printer sims are today: waxprint is THERMAL (two-zone auger melt, Hagen-Poiseuille nozzle, bead cooling with the fan as a wind
vector, toolpath patterns judged by viscosity; its "assembly" is one extruder with flat fields; its time axis is build height); voron is a
Klipper config renderer with `max_velocity`/`max_accel` as constants and "motion physics is NOT simulated" in its own docstring; motors M1
is the only computed axis (steps/mm, screw torque T = F·L/(2πη) against pull-in, quasi-static). No CoreXY/bed-slinger dynamics, gantry
mass, belt stretch or frame stiffness anywhere; no frame, rail, belt or BOM rows. printing_suite / kirimoto are process rows (slice, print,
measure) and stay as they are.

mxc-8 (after mxc-5): (a) `PrinterAssemblyDefinition.mech_assembly_ref` and `voron.PrinterDefinition.assembly_ref` → a `MechAssembly` of
catalogue rows (2020, MGN9/12, GT2 belt + idlers, T-nuts, 8 mm rod / TR8 leadscrew); (b) the M1 axis = a `MechJoint kind='screw'` with
`ratio` = the lead, driven by the linear engine with `PrinterAxisRequirement`'s 5 N as the `MechLoadCase` — the M1 duty check stays in
motors, FED by mech; (c) `max_accel` becomes a CHECK (gantry mass × accel vs belt tension + frame stiffness) instead of a constant;
(d) mech's printable variants (bins, baseplates, drawer fronts) register as one more `SliceJob.shape_class` and mxc-5's print list points at
`PrintProfile` / `MaterialLot`. waxprint keeps every thermal engine untouched.

### 9.4 What stays exactly where it is (no mech copy)

gears' ratio solve and backlash sum; motors' co-energy stepping, Hertz/Archard wear, S-N fatigue, lifecycle cost, bench protocols;
composition's level derivation, promotion, routing, role predicates; magnetics' material options and use roles; materials_science's
FEM engines (D-mxc-7); waxprint/casting thermal and fill engines; printing_suite's process rows; meshassets' licence gate pattern;
mathshapes' CAD import worker; core `simulations/` time-series store.

### 9.5 Pointers from pol-core (verified against 673fe74b, 2026-11-03)

- **Thermal transients are not mech's.** `pcb.objects.pcb.PartThermalModel` (bob-3g) already holds a part's transient thermal impedance as
  Foster pairs with the steady Rth, read by the bss-9 temperature collateral. Bulk conductivity / specific heat stay material properties on
  `MechMaterialOption`; if a mech part ever needs a transient thermal model it REFERENCES `PartThermalModel`.
- **Part identity: two catalogues, cross-referenced.** Electronics parts live in `board` (`KitPart`, `PartBoard`; D-kxc-3 open on a discrete-part
  `PartBoard` kind for R1 / D1 / SW1). `MechPartFamily` is the mechanical sibling — kept separate (his small-separated-objects rule). Rule for a
  fastener that is also an electrical connection (chassis-ground screw, standoff, ring terminal under a nut, the bench enclosure's case): its
  dimensions, features and fit checks belong to the mech catalogue; its electrical role is a `board` row that names the mech variant by
  `mech_variant_ref` — never a mech row with electrical fields. mxc-2 fixtures carry none; the enclosure (a later bench slice) is the first case.
- **Confirmations, not a new comparison row.** The bench topology arc keeps a simulated run's confirmation (sim | hardware | person) keyed to the
  sha256 of its reproducible initial conditions and voids it when the build changes. `MechMotionRun` mirrors that (`inputs_sha256`,
  `confirmation_json` with the arc's keys — added in mxc-4); mxc-7's "measured run beside the sim vectors" is that confirmation, not a new row.
