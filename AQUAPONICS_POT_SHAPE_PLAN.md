# Self-watering pot as a math-defined SimSpace — pickup plan

Stamped 2026-07-13. Dustin's directive (verbatim intent): the aqp-1
self-watering pot (water enters holes on one side, drains out lower
holes on the opposite side) should render as a math-defined shape,
displayed like a SimSpace using the same rendering engine, with a
custom Display for editing hole elevation/size and pot size. Then:
water-flow visualization, soil visualization, a transparency toggle,
and — much later — a plant growing in the pot.

**Dustin's own reordering (explicit instruction, follow this order):**
"1, 2, 4, 5 are the simpler ones so reorder those to come first. 3 and
6 are the most complex and should come last." Phase numbers below are
his numbering, kept stable so this note and future ones stay
consistent — just execute 1 → 2 → 4 → 5 before ever starting 3 or 6.

Session ended here because Dustin is clearing context to save tokens,
NOT because of a blocker. This file is the durable handoff — read it
before touching anything, and prefer it over assumptions.

## Status right now

**Research done, verified against actual code (not memory) this
session** — the news is good, most of the hard math already exists:

- Pot geometry (`aquaponics/pot_geometry.py`): `PotDefinition` +
  `PotHole` (kind input/output, `diameter_mm`, `height_mm`=elevation,
  `azimuth_deg`, `angle_deg`) are already fully parametric CRUDE rows.
  `validate_pot()` already enforces: every input above every output,
  opposite sides (circular-mean azimuth check), gravity-downhill bore
  angle. `generate_holes()` is a tunable generator. **Nothing to build
  here** — this is exactly Dustin's "water in one side, drains out the
  opposite side lower down" model, already real and CRUDE-editable.
- `aquaponics/pot_api.py` already exposes: `GET /api/aquaponics/pots`,
  `GET /api/aquaponics/pots/{name}/validate` (the gravity/geometry
  report — USE THIS for before/after feedback in the future Display),
  `POST /api/aquaponics/pots/{name}/generate-holes` (preview only).
- FEM hydraulics (`aquaponics/hydraulics.py` +
  `materialsScience/engines/darcy_engine.py`, skfem): solves a 2-D
  vertical cross-section Darcy problem and returns `headField`
  (per-node scalar head values), `outflowRateMlS`, `fluxStats`,
  `meshMeta`. **STEADY-STATE ONLY** — `water_level_mm` is a fixed
  input per call, no time-stepping exists. This is phase 3's gap
  (deferred, do not start yet).
- Math-shapes module (`mathshapes/`) is far more built than old memory
  suggested — shape-2 is DONE, not just shape-1:
  - `shape_basis.py`: `MathShapeDefinition` (family
    quadric/primitive/csg; `parameters_json` knob seam; `csg_json` =
    `{op, shapes:[names]}`).
  - `shape_analysis.py`: `evaluate_point`, `quadric_classify`,
    `sample_surface(n=)` → render mesh, `shape_properties`.
  - `shape_modify.py`: **`pot_shape_from_definition(manager, pot_name,
    persist=True)`** already builds the pot as CSG (frustum body
    DIFFERENCE its holes) directly FROM `PotDefinition`+`PotHole` rows
    (mm→cm), carrying `gravityValid`/`gravityFindings` from
    `validate_pot`. **`modify_pot_hole(manager, pot_name, param,
    value, hole_index=)`** edits a DERIVED hole primitive's
    radius/height, gated by the (pre-change) gravity invariant.
    ⚠️ **Important gotcha, not yet handled**: `modify_pot_hole`/
    `modify_parameter` mutate the EPHEMERAL `MathShapeDefinition` rows
    that `pot_shape_from_definition` creates — they do **NOT** write
    back to the durable `PotDefinition`/`PotHole` CRUDE rows. Re-
    deriving the shape later would silently lose any edit made only
    through `modify_pot_hole`. **The correct edit flow for the future
    Display is: write hole/pot fields via standard CRUDE PUT on
    `PotDefinition`/`PotHole` (already auto-generated, no new backend
    code needed) → call the new from-pot route again to re-derive
    fresh geometry.** Use `modify_pot_hole`/`modify_parameter` only if
    you specifically want to preview a hypothetical change without
    touching the durable pot (not the primary path).
  - `shape_api.py`: `GET /api/shapes` catalogue, `/{name}/properties`,
    `POST /{name}/evaluate`, `GET /{name}/surface?n=` (mesh
    points+triangles), `/{name}/classify`, `POST /{name}/modify`.
  - `shape_seed.py`: an existing `pot-with-holes` DEMO seed (both
    holes at the same elevation — a fixture, not the real derived
    pot).
- ⚠️ **Real geometry gotcha, not yet worked around**:
  `sample_surface()` gives PROPER triangulated meshes for `primitive`-
  family shapes (via `axial_mesh`/`ellipsoid_mesh`/`_box_mesh`), but
  for `csg`-family shapes (which is what the pot's own
  `{pot_name}-shape` row is — a difference of frustum minus holes) it
  falls through to `_march_points`: a marching-grid boundary-point
  sampler that returns **`triangles: []`** — a point cloud, not a
  mesh. Rendering the CSG result directly would only give a dotted
  cloud, not a solid pot.
  **Planned workaround (reasoned through, NOT yet implemented)**:
  don't render the CSG shape itself — render its CONSTITUENT
  PRIMITIVES separately, which each already have real triangulated
  meshes: fetch `/api/shapes/{pot_name}-body/surface?n=32` (the
  frustum body) and `/api/shapes/{pot_name}-hole-{i}/surface?n=16`
  for each hole (cylinders), and draw them as separate meshes. This
  is a VISUAL APPROXIMATION (holes render as distinct cylinder
  markers at their bore position, not true boolean-subtracted
  cavities in the wall) rather than a watertight CSG mesh — flagged
  to Dustin as a deliberate simplification for phase 1, not hidden.
  A true CSG-to-triangle-mesh algorithm (marching cubes or similar)
  would be a much bigger, separate lift if he wants the real thing
  later.
- SimSpace (`simSpace/sim_space_definition.py` +
  `sim_space_binding_definition.py`): `bound_classes_json` is a LIST —
  multiple `*SimState` classes can each bind into one SimSpace with
  their own shape+style ref and independent visibility. **Pot shell /
  soil (later: water) as separate, independently-toggleable layers is
  the NATIVE pattern already — no new SimSpace plumbing needed for
  that part.**
- Transparency: already a material-level field. `Material3D` has
  `opacity`/`transparent`; `three-material-builders.ts` already
  consumes them (`transparent: def.transparent || def.opacity < 1`).
  Phase 5 just needs per-layer style refs + a toggle UI (mirror the
  existing `overlayVisible` axes/legend/evaluations toggle pattern in
  `sim-space-editor-sidebar.component.ts`) — no renderer work.
- Display registry: `DISPLAY_COMPONENT_REGISTRY` +
  `registerDisplayComponent()` (`models/dashboards/ComponentRegistry.ts`,
  wired in `app.module.ts`'s `registerDisplayComponents()`) is the
  established, low-friction pattern — feature modules self-register in
  their own file (see `multi-scale/msim-display-components.ts`,
  `materials-science/msci-display-components.ts` as models). A new
  `aquaponics-display-components.ts` is the natural home for phase 2's
  editor. `run-initial-conditions-editor.component.ts` is GENERIC
  (auto-discovers per-class fields) — worth checking whether it
  already produces usable numeric controls for a pot SimState class
  before investing in a fully bespoke editor.
- **Frontend: zero existing code touches aquaponics OR mathshapes.**
  Confirmed via repo-wide grep — no component, no service, no
  SimSpaceRenderer tie-in. This is where essentially all of phases
  1/2/4/5's actual new engineering effort lives.

## Implemented + VERIFIED 2026-07-13 (still uncommitted)

**Backend change, now confirmed working end-to-end:**

`polari-rf-node/polari-framework/mathshapes/shape_api.py`:
- Added route `POST /api/shapes/from-pot/{pot_name}` → calls the
  already-existing `pot_shape_from_definition(self.manager, pot_name)`
  and returns its result (`{ok, shapeName, bodyShape, holeShapes,
  gravityValid, gravityFindings, solidFrustumVolumeCm3,
  potSolidVolumeCm3, ...}`), 404 on `ok: false`.
- Added the import (`pot_shape_from_definition` from
  `mathshapes.shape_modify`) and route registration in `__init__`.
- Docstring updated to document the new route + the CRUDE-edit-then-
  re-derive contract.

**Verification performed**: `prf-backend` (staging) doesn't
bind-mount source, so the file was `docker cp`'d into the running
container + the container restarted to test live (source-of-truth
edit is still the repo file on disk; this was just how it got
exercised). Live curl against seeded `demo-herb-pot`:
```
POST /api/shapes/from-pot/demo-herb-pot
→ ok: true, bodyShape: "demo-herb-pot-body",
  holeShapes: [4 hole names], gravityValid: true
GET /api/shapes/demo-herb-pot-body/surface?n=32
→ method: "parametric frustum mesh", family: "primitive",
  triangles: 64 (non-empty — confirmed the primitive path, not the
  CSG point-cloud fallback)
```
Also added 4 new checks to `mathshapes/selftest_shape2.py` (calling
`MathShapesAPI.on_post_from_pot` directly as an unbound method against
a mocked manager, matching this file's existing test style): route
builds the CSG pot ok, names body+hole shapes correctly, the derived
body has a real triangulated mesh, and it 404s on an unknown pot.
**21/21 selftest_shape2 checks passing.**

## Phases, IN DUSTIN'S REORDERED SEQUENCE

### Phase 1 — math shape rendering + SimSpace wiring — BUILT 2026-07-13,
NOT visually verified (no browser tool available this session)

**Design resolution for the open question** ("does binding need a NEW
*SimState wrapper class, or can PotDefinition bind directly?"): NEITHER.
A pot is one object made of several math-shape primitives (body + N
holes); SimSpaceBindingDefinition's per-class binding emits exactly one
SimSpaceObject per class instance, which can't express "one row → many
meshes." Used the SimSpaceDefinition `definition.freestanding` list
instead (`freestandingOnly: true`) — the SAME mechanism the 3D
selection-space scenes (material-choice etc.) already use for a
curated, hand-placed shelf of shapes independent of any class binding.
No new backend class, no binding-schema changes.

**Built:**
- `mathshapes/pot_scene.py` (new) — `ensure_pot_viz_scene(manager,
  pot_name, body_name, hole_names)`. Idempotently creates/refreshes a
  `{pot_name}-viz` SimSpaceDefinition whose freestanding list has one
  entry per body/hole shape, `shapeRef: "mathshape:{shapeName}"`
  (body styled `matte-blue`, holes `matte-gray`). **Ephemeral by
  design**, same pattern as the MathShapeDefinition rows
  `pot_shape_from_definition` derives — written directly into
  `manager.objectTables['SimSpaceDefinition']`, NOT persisted via
  CRUDE/DB. Does not survive a backend restart; re-POST from-pot to
  rebuild it. Flagged in the module docstring for whoever wants it
  durable later.
- `mathshapes/shape_api.py`'s `on_post_from_pot` now also calls
  `ensure_pot_viz_scene` and returns the scene name as `simSpace` in
  its response.
- Frontend: new `services/sim-space-3d/math-shape-geometry-library.service.ts`
  — the math-shape analog of `three-texture-builders`' texture cache.
  `get(shapeName, n)` returns a shared `THREE.BufferGeometry`
  SYNCHRONOUSLY (empty on first call), fetches
  `/api/shapes/{name}/surface?n=` in the background, and mutates that
  SAME geometry's attributes in place once the response lands — the
  renderer's continuous 60fps loop repaints automatically next frame,
  no explicit invalidation needed (mirrors how `THREE.TextureLoader`
  already works for the material/texture path).
- `three-renderer.service.ts`'s `buildMeshFor`: a `shapeRef` prefixed
  `mathshape:` now resolves via the new service instead of
  `Mesh3DLibraryService`/`buildGeometry` (which stay untouched — no
  Mesh3DDefinition catalogue involvement at all, deliberately, see
  gotcha below). `SimSpaceRendererFactory` and its one construction
  site updated to thread the new service through.

**Gotcha discovered + worked around**: generic CRUDE GET (the endpoint
`Mesh3DLibraryService.load()` would have used) reads through
`manager.getListOfInstancesByAttributes`/`getJSONdictForClass` — typed
machinery that does NOT see rows written directly into
`objectTables[class]` the way `/api/shapes` and `/api/simspace` do
(confirmed empirically: an ephemeral MathShapeDefinition row was
invisible via `GET /MathShapeDefinition` but visible via the custom
`GET /api/shapes` catalogue). This is why Mesh3DDefinition rows were
NOT used as the indirection layer for math-shapes — the `mathshape:`
shapeRef prefix resolves directly to the mathshapes API instead,
sidestepping the whole problem. SimSpaceDefinition's OWN custom routes
(`/api/simspace`, `/api/simspace/{name}/snapshot`) read `objectTables`
directly, matching `/api/shapes` — confirmed ephemeral SimSpace rows
DO show up there, and in the `/sim-spaces` list page (uses the same
service).

**Verified this session:**
- `mathshapes/selftest_shape2.py`: 25/25 passing, incl. 4 new checks
  for the viz-scene (created, freestandingOnly + right shape count,
  `mathshape:`-prefixed refs, idempotent re-derive doesn't duplicate).
- Live curl: `POST /api/shapes/from-pot/demo-herb-pot` →
  `simSpace: "demo-herb-pot-viz"`; `GET
  /api/simspace/demo-herb-pot-viz/snapshot` → 5 objects (1 body + 4
  holes), correct `mathshape:`-prefixed shapeRefs, correct styleRefs.
- `npx tsc --noEmit` on the Angular project: 18 PRE-EXISTING errors
  (all in unrelated files — no-code editor, dashboards, dataseries,
  geojson — none touch anything this session edited), ZERO new errors
  from the 3 touched/new frontend files.

**`prf-frontend` rebuilt + redeployed 2026-07-13** (`docker compose
--env-file .generated/.env.staging -f docker-compose.staging-nip.yml
build prf-frontend` then recreated the container — the old one had no
compose labels, had to be stopped/removed by name first before compose
would recreate it). Build succeeded, only pre-existing warnings, and
confirmed the served bundle contains the `mathshape:` code
(`grep -l 'mathshape:' *.js` hit chunk `539.2299f5aa4d59c5f0.js`, the
three-renderer chunk). Confirmed reachable:
`https://prf.192.168.0.210.nip.io/sim-spaces/demo-herb-pot-viz` → 200.

**Dustin looked at it (screenshots, 2026-07-13) — it was badly wrong.**
The rendered pot looked like a single flapping, torn, one-sided sheet
of fabric, not a vessel. Root causes + full redesign below.

## Geometry model redesign 2026-07-13 (post-screenshot feedback)

Dustin's diagnosis + directive, verbatim intent:
- The pot was a SOLID frustum with no wall at all — "the outside is a
  single surface, it should be between two surfaces (cylindrical) and
  act as a 3D equation defining a volume." → the side wall must be the
  volume BETWEEN an outer and an inner tapered surface.
- "Another pair of surfaces should define the volume equation that
  composes the bottom of the pot" → the base is its OWN solid slab,
  not part of the same block as the wall.
- Holes were a full-diameter bore straight through the pot's own axis
  (spanning almost the whole diameter) — wrong. "The holes should be
  defined via small cylinders just big enough to go fully through the
  volume definition of the pot-sides-shape on ONE side of it… one hole
  on each side, output below input."
- "Pay attention to how textures are being applied — that is causing
  visualization issues."
- Mid-session addition: minimum wall/base thickness = 3mm, minimum
  hole diameter = 1mm.

**Root cause of the "flapping sheet" look** (found by reading
`mathshapes/shape_geometry.py`): `axial_mesh()` — the mesh builder
EVERY cylinder/cone/frustum in this module uses for rendering — only
ever built the LATERAL surface (a base ring + top ring), with NO end
caps at all. A "solid" pot body rendered as a completely open tube
with nothing at top or bottom; viewed close-up (the pot is bigger than
the default camera framing) that reads exactly as an open, torn sheet.
This was a latent bug in EVERY primitive rendered through this path,
not pot-specific — the pot was just the first shape big enough, close
enough to the camera, to expose it.

**Fixed, built, and reverified (backend fully live-tested, 34+24+20
selftests passing; frontend rebuilt+redeployed but still not
eyeballed — see below):**

- `mathshapes/shape_geometry.py`: `axial_mesh()` gained `cap_base`/
  `cap_top` (triangulated fan discs, OFF by default so open tubes —
  holes, wall lateral surfaces — stay open) and `inward` (reverses
  triangle winding, hence the outward-pointing normal, so a surface
  meant to be viewed from the axis side — the wall's INNER face —
  isn't back-face-culled from inside the vessel). Verified the winding
  math by hand (cross-product of both lateral triangles AND both new
  cap triangles all point away from the solid, i.e. correctly outward)
  before trusting it.
- `mathshapes/shape_analysis.py`: `sample_surface` reads `cap_base`/
  `cap_top`/`inward` out of a primitive's own `parameters_json` and
  passes them through — render-only flags, ignored by the volume/
  inside-test math in `shape_geometry.py` (those still treat every
  primitive as fully solid, which is correct — capping is a visibility
  concern, not a geometry concern).
- `mathshapes/shape_modify.py`'s `pot_shape_from_definition` — FULL
  REWRITE. Now derives FIVE parts instead of one body + holes:
  - `{pot}-wall-outer` / `{pot}-wall-inner`: two concentric tapered
    frustums (outer radius profile from `outer_top/base_diameter_mm`;
    inner = outer minus `wall_thickness_mm`, clamped to the 3mm
    floor), spanning from just above the base slab to the rim. Neither
    is capped (open tube, by design) — the inner one carries
    `inward: true`.
  - `{pot}-bottom-slab`: its own solid frustum occupying
    `base_thickness_mm` (clamped to 3mm) at the very bottom, BOTH ends
    capped (needs to read as solid, not a tube).
  - `{pot}-hole-{i}`: SHORT cylinders now — length = wall thickness +
    a small margin (`HOLE_LENGTH_MARGIN_CM = 0.4`), positioned
    radially at the wall's mid-thickness at the hole's own
    (azimuth, elevation) via a new `_axis_and_sign_for_azimuth` helper
    (replaces the old `_axis_for_azimuth`, which only picked an axis,
    not which SIDE of it) — no longer spans the pot's own axis at all.
    Diameter clamped to the 1mm floor.
  - Volume bookkeeping stays CSG-based (nested: `{pot}-wall-shell` =
    difference(outer, inner); `{pot}-solid` = union(wall-shell,
    bottom); `{pot}-shape` = difference(solid, holes)) — confirmed the
    shared grid-sample evaluator already supports `union` (not just
    `difference`), so this nests cleanly with NO new bounds_json
    needed (`_shape_bounds` already recurses correctly). This also
    means `modify_parameter`'s existing "resize a hole → dependent pot
    loses volume" consequence-reporting mechanism keeps working
    unchanged (holes are still directly in a difference op's
    `shapes[1:]`) — verified via selftest, not just assumed.
  - Response contract changed: `bodyShape`/`solidFrustumVolumeCm3`/
    `potSolidVolumeCm3` → `wallOuterShape`/`wallInnerShape`/
    `bottomShape`/`potMaterialVolumeCm3`, plus new
    `wallThicknessMm`/`baseThicknessMm`/`wallThicknessClamped`/
    `baseThicknessClamped`/`holeDiametersClamped`. Nothing outside
    this session's own code consumed the old names (Phase 2's Display
    doesn't exist yet), so this was a clean rename, not a compat
    break.
- `aquaponics/pot_basis.py`: new `MIN_WALL_THICKNESS_MM`/
  `MIN_BASE_THICKNESS_MM` (3.0) / `MIN_HOLE_DIAMETER_MM` (1.0).
  `pot_geometry.py`'s `validate_pot` gained matching findings
  (`wall-too-thin`/`base-too-thin`/`hole-too-small`) so a clamp in the
  derived shape is NEVER silent — knobs-and-suggestions.
- `mathshapes/pot_scene.py`: `ensure_pot_viz_scene` now takes all 3
  vessel-part names + holes, emits 3 freestanding entries at
  `VESSEL_STYLE_REF` ('matte-blue' — outer/inner/bottom are the same
  physical material) + N at `HOLE_STYLE_REF` ('matte-gray' — holes are
  empty space; a gray marker is the best available placeholder for
  "nothing is here", not a real fix — flagged, not hidden).
- Frontend `three-renderer.service.ts`: the "textures" issue Dustin
  flagged is a material-sidedness issue, not literally textures — a
  `mathshape:`-sourced mesh now gets `material.side = THREE.DoubleSide`
  unconditionally (confirmed `buildMaterial()` returns a fresh,
  unshared `THREE.Material` instance per call — mutating `.side` here
  can't leak onto any other mesh). Combined with the `inward` winding
  fix above, the inner wall surface should now be visible from inside
  the vessel/through the open top, and the whole vessel should no
  longer disappear from certain angles.
- New selftest coverage: `mathshapes/selftest_shape2.py` now 34/34
  (was 25/25) — added checks for wall-thickness-is-real (outer radius
  > inner radius at both ends), inner-surface-is-inward, bottom-slab-
  is-capped, hole-is-short-not-full-diameter, and the full clamp-to-
  minimum path (thin wall/base + tiny holes still build, report
  `*Clamped: true`, and `validate_pot` flags all three). `aquaponics/
  selftest_pot.py` now 24/24 (was 20/20) — added the three new
  physical-minimum findings. `mathshapes/selftest_shapes.py` (20/20)
  and `selftest_shape3/4.py` (15/15, 18/18) re-run clean — confirmed
  `axial_mesh`'s new default-off cap/inward kwargs don't change any
  EXISTING shape's point/triangle count (frustum-pot's surface sample
  is still exactly 48pts/48tris, byte-for-byte the same as before this
  session).
- `prf-backend` + `prf-frontend` both rebuilt/restarted/redeployed
  with all of the above; live-curled the full chain again
  (`from-pot` → 5-part response with real clamped-or-not flags →
  each part's `/surface` gives a real capped-or-open triangulated mesh
  with the RIGHT bounding box math (hand-verified: outer radius 10cm,
  inner 9.2cm = 10 − 0.8cm wall thickness, exactly) → SimSpace snapshot
  lists all 7 objects (3 vessel parts + 4 holes) with correct
  `mathshape:`-prefixed refs and styles).

~~**Known, deliberate simplification NOT addressed this pass** (the
wall's open top edge has no rim cap — a gap rather than a flat annulus
of material at the rim; fixing it needs a new annulus primitive kind).~~
**SUPERSEDED — this was true of round 2's design (wall-outer/wall-inner
as two separate primitive objects with nothing connecting them at the
rim) and was never true of anything actually shipped**: `mathshapes/
shape_geometry.py`'s `hollow_frustum_shell_mesh` (built as PART of
round 2's rewrite, in the SAME session, right after this note was
written and never updated) already stitches outer+inner into ONE mesh
WITH a top rim annulus connecting them (`# Top rim annulus` in the
source) — this note describing "no rim cap... a real but small
follow-up" is describing a design that was already dead by the time it
was written. Round 3 added a matching bottom rim too. Left this
strikethrough in place (rather than deleting) as a marker that this
note was checked and found stale during 2026-07-13's adversarial
review pass, not silently dropped.

**STILL NOT visually verified — no browser tool in this environment.**
Data-level checks (curl, bounding-box math, selftests) all check out,
but nobody has looked at the actual render with eyes since this
redesign. **Next thing to do, this needs an actual human/browser**:
open `https://prf.192.168.0.210.nip.io/sim-spaces/demo-herb-pot-viz`
and confirm it now reads as an actual hollow vessel — visible wall
thickness, a solid-looking base, short hole bores on two opposite
sides (one higher, one lower) — not the flapping-sheet look from the
screenshots. Also check devtools console for
`[MathShapeGeometryLibraryService]`/`[ThreeSimSpaceRenderer]` warnings.

## Round 2 of visual feedback (Dustin, 2026-07-13) — geometry model rebuilt

Screenshots showed a single flapping, one-sided, torn-looking blue
sheet — not remotely a pot. Two rounds of follow-up directive, in
order:

**Round 2a** — "the siding shape ... should be integrated ... into a
single solid shape like the bottom" + "the cylinders that form the
holes should subtract from the siding object."

**Round 2b (mid-fix redirect)** — "we should be leveraging either
matrix equations or our latex equations in defining the integration
equations that form these surfaces ... to form volumetric shapes."
Asked Dustin to pick between quadric-matrix-as-source-of-truth,
LaTeX-as-source-of-truth, both, or finishing the procedural approach
first — **he picked "both": quadric matrices as source of truth,
LaTeX as a derived (non-authoritative) display.**

### Root cause of the original "flapping sheet" (found, fixed)

`mathshapes/shape_geometry.py`'s `axial_mesh()` — the mesh builder
EVERY cylinder/cone/frustum in this module renders through — only
ever built the LATERAL surface (a base ring + top ring), with NO end
caps at all, ever, for anything. A "solid" pot body rendered as a
completely open tube; up close (the pot is bigger than the default
camera framing) that reads exactly as a torn, one-sided sheet. This
was a LATENT bug across the whole module, not pot-specific — the pot
was just the first shape big/close enough to expose it.

**Fixed**: `axial_mesh()` gained optional `cap_base`/`cap_top`
(fan-triangulated end discs — hand-verified outward winding via
cross-product before trusting it) and `inward` (reverses triangle
winding for a surface meant to be viewed from the axis side, e.g. a
hollow wall's inner face — without this an inner-wall mesh built the
same way as the outer one would have its front face pointing INTO the
solid, invisible from inside with a single-sided material). Both
default OFF, so every other shape's existing point/triangle count is
byte-for-byte unchanged (confirmed: `frustum-pot`'s surface sample is
still exactly 48pts/48tris in `selftest_shapes.py`, 20/20 still
green).

### Full geometry rewrite: quadric matrix equations as source of truth

`mathshapes/shape_geometry.py` gained the actual equation machinery:
- `cone_quadric_matrix(base_radius, top_radius, height, axis, center)`
  — builds the 4x4 matrix (pᵀQp form) for the cone/cylinder whose
  lateral surface matches a given base/top radius and height. A
  frustum's lateral surface IS exactly a bounded slice of a cone
  quadric; a straight-walled hole is the degenerate cylinder case
  (slope=0) of the SAME formula — no special-casing needed, verified
  by hand (the general formula naturally reduces to `x²+y²=r²` when
  base_radius==top_radius).
- `radius_at_z(Q, axis, z)` — the exact algebraic inverse: evaluates
  the equation's radius at a given z. Used to DERIVE every numeric
  render/mesh parameter FROM the equation (never independently
  specified) — round-trip-verified in the selftest (the wall render
  mesh's radii match `radius_at_z` applied to the stored Q to within
  1e-6).
- `cone_quadric_latex(...)` — a DERIVED, non-authoritative LaTeX
  string for the SAME surface (e.g. `x^2 + y^2 = (9.1 + 0.09(z -
  -11.3))^2`), using the correct PERPENDICULAR axis symbols for a
  hole bored along x/y (not hardcoded x/y regardless of bore axis —
  an early draft got this wrong, caught before it shipped).
- `hollow_frustum_shell_mesh(params, n_lon, n_stack)` — the answer to
  "integrated single solid shape" + "holes subtract": ONE grid-
  stitched mesh (outer lateral + inner lateral, inward-wound, + a top
  rim annulus closing the open mouth) built from a SINGLE shared
  vertex grid, so it reads as one continuous object rather than two
  floating surfaces. Each hole (a plain cylinder-primitive param dict,
  identical shape to a standalone hole's own parameters) is CUT: any
  grid quad with a corner inside that hole's cylinder
  (`primitive_inside('cylinder', ...)` — the SAME equation the hole's
  own standalone primitive renders from) is dropped, punching a real
  opening through both surfaces at once. The dropped region is a
  blocky (grid-resolution-limited) approximation of a circle, not a
  true boolean cut — this module still has no general mesh-boolean/
  marching-cubes engine, flagged not hidden. The hole's own standalone
  cylinder primitive (rendered alongside, unchanged) is what gives the
  opening its visible depth/bore lining — no separate collar-stitching
  code needed.

**Two real bugs found and fixed while building this** (both via
hand-verification against worked examples, not just "the selftest
passed"):
1. `classify_axis_aligned`'s cone/hyperboloid split checked the RAW
   constant term's sign — correct only when the quadric happens to be
   centered at its own apex (true for every quadric this classifier
   had ever been fed before). A cone translated away from the origin
   (e.g. `cone_quadric_matrix`'s pot-local frame, centered at the
   wall's own base, not its true geometric apex) misclassified as
   'hyperboloid'. Fixed by completing the square (recentering) before
   reading the constant's sign — a no-op for already-centered
   quadrics, so zero behavior change for every existing seeded shape
   (verified: `selftest_shapes.py` still 20/20 including its 4 direct
   `classify_axis_aligned` diag-matrix checks).
2. Found the SAME bug, pre-existing, in `quadric_as_ellipsoid` (an
   extra `+ 2·Σ Q[i][3]·c_i` term in its completing-the-square formula
   that only vanishes when the quadric is already centered — which is
   all it had ever been tested against). Hand-verified with a sphere
   of radius 2 centered at (1,0,0): the buggy formula computed radius
   ≈2.449 instead of 2. Fixed the same way. This means an off-center
   ellipsoid quadric anywhere else in the platform was silently
   mis-sized before this session — now correct.
3. (Caught mid-session, not shipped) `quadric_matrix_json` must be a
   FLAT 16-number list (`shape_analysis._quadric_matrix`'s parser
   requires it) — first draft stored the nested 4x4 `cone_quadric_
   matrix()` return directly, which silently parsed as "not 16
   elements" → `Q=None` → every point tested "outside" → 0.0 reported
   volume. Fixed by flattening before `json.dumps`.
4. (Also caught) the quadric bounds_json's `xy_cap` was originally
   `3×radius + 5cm` ("safely large") — reasonable-sounding, but wrong:
   `bounds_json` only sizes the CSG grid-sample SCAN region (a fixed
   grid-cell COUNT across that region), so padding it out 3x+5cm
   relative to a wall that's ~8mm thick starved the sampler enough to
   report 0.0 material volume even with a mathematically-correct
   equation and correct flat encoding. Fixed by using the EXACT
   radius (matching how the old primitive-family bounds worked — zero
   padding) for wall/bottom, and a small hole-scale cap (not the
   pot-scale one) for each hole's own equation row.

### Rebuilt `pot_shape_from_definition` (shape_modify.py)

Per pot, now derives:
- `{pot}-wall-outer-eq` / `{pot}-wall-inner-eq` / `{pot}-bottom-eq` —
  family='quadric', a real Q matrix + `bounds_json` (tight, scan-only)
  + a derived LaTeX equation in `notes`. THE authoritative geometry.
- `{pot}-wall-shell-mesh` — family='primitive', kind='hollow_frustum',
  the ONE combined renderable wall object; every numeric radius
  DERIVED via `radius_at_z` from the two wall equations above, holes
  list built from the same hole geometry as the standalone hole
  primitives.
- `{pot}-bottom-slab` — unchanged in spirit (a capped solid frustum,
  Dustin: "the bottom ... looks like it is a single piece" — kept
  exactly that shape), radii now DERIVED from `{pot}-bottom-eq`.
- `{pot}-hole-{i}-eq` (quadric, cylinder-degenerate) + `{pot}-hole-{i}`
  (primitive cylinder, unchanged from round 1 — short, wall-thickness-
  only bore) — holes stay simple primitives for rendering/CSG (already
  natively finite, no bounding trick needed) with a parallel equation
  row for documentation/LaTeX only.
- Volume bookkeeping: nested CSG directly over the EQUATION rows
  (`{pot}-wall-shell` = difference(outer-eq, inner-eq); `{pot}-solid` =
  union(wall-shell, bottom-eq); `{pot}-shape` = difference(solid,
  hole-eqs)) — no more box-intersection layer needed once bounds_json
  is set directly on each equation row.
- Response contract changed again: `wallOuterShape`/`wallInnerShape` →
  `wallOuterEquation`/`wallInnerEquation`/`bottomEquation` (the source-
  of-truth rows) + `wallShape` (the ONE render mesh, was two objects)
  + unchanged `bottomShape`/`holeShapes`.
- `modify_pot_hole`'s docstring updated to flag an honest limitation:
  since it targets the RENDER cylinder primitive (family='primitive'
  is all `modify_parameter` supports) and volume bookkeeping now runs
  through the separate `-eq` quadric row, an edit there is cosmetic-
  preview only — doesn't move the authoritative volume, doesn't
  survive a from-pot re-derive. Consistent with this function's
  pre-existing "preview only, not the primary edit path" contract
  (CRUDE PUT + re-POST from-pot is still the real path) — just more
  honestly documented now that it's ALSO decorative for volume math,
  not only for persistence.

`mathshapes/pot_scene.py` + `shape_api.py` updated to match: the
SimSpace freestanding list is now wall (1) + bottom (1) + holes (N) —
4 objects for demo-herb-pot, down from 5 (was outer+inner+bottom+
holes) and 7 originally.

### Verified this session
- Hand-worked the winding math for BOTH the axial_mesh caps AND the
  hollow_frustum_shell_mesh's rim annulus (cross-products, by hand,
  before trusting the code) — all four new triangle patterns confirmed
  outward-normal-correct.
- Hand-worked the sphere-radius counter-example that caught bug #2
  above.
- `mathshapes/selftest_shape2.py`: 42/42 (was 25 in round 1) — new
  checks include: equation rows are real quadrics with a parseable
  matrix; demo-pot's genuinely-tapered wall classifies as 'cone' (not
  the previously-buggy 'hyperboloid'); a straight hole classifies as
  'cylinder'; LaTeX is present and human-readable; wall render radii
  round-trip through `radius_at_z` to the stored equation; holes
  measurably REDUCE the wall mesh's triangle count vs. the same wall
  with no holes cut (976 < 1008 for demo-pot, 2 holes); the reported
  material volume is positive and non-zero.
- `mathshapes/selftest_shapes.py` (20/20), `selftest_shape3.py`
  (15/15), `selftest_shape4.py` (18/18), `aquaponics/selftest_pot.py`
  (24/24) all re-run clean — zero regressions from the
  classify/ellipsoid bug fixes or the axial_mesh signature change.
- Live curl against the real seeded `demo-herb-pot`: `from-pot` →
  correct multi-part response; `/classify` on its wall-outer-eq
  correctly reports 'cylinder' (demo-herb-pot is NOT tapered, unlike
  the selftest's deliberately-tapered `demo-pot` fixture — consistent,
  not a bug); the combined wall mesh (`wall-shell-mesh`) returns 1088
  points / 2096 triangles, `method: "parametric hollow_frustum mesh"`;
  the SimSpace snapshot lists exactly 6 objects (1 wall + 1 bottom + 4
  holes).
- `prf-frontend` did NOT need rebuilding this round — the
  `mathshape:`-prefix rendering path is shape-name/count-agnostic (it
  just fetches whatever `/surface` returns), so the already-deployed
  build from round 1 (with the DoubleSide fix) picks up the new
  backend geometry automatically. Confirmed the page still loads
  (200) at the same URL.

**STILL NOT visually verified — no browser tool in this session
either.** Every data-level check passes and the geometry is now
mathematically principled (equations, not hand-picked numbers) with
real bugs caught and fixed along the way, but nobody has looked at the
actual pixels since this rewrite. Open
`https://prf.192.168.0.210.nip.io/sim-spaces/demo-herb-pot-viz` and
check: does the wall now read as one continuous solid vessel (not two
separate floating surfaces, not a flapping sheet)? Do the 4 holes look
like real openings with visible depth, not gray rods poking through a
solid wall? Is the bottom still solid-looking (it should be unchanged
from round 1, which Dustin already confirmed looked right)?

## Round 3 of feedback (Dustin, 2026-07-13) — sides+bottom looked good, three fixes

Sides and bottom now read as real shapes (round 2's rewrite worked for
those). Three follow-ups:

1. "the top of the bottom shape should be flush with the bottom of the
   siding shape" — the two were ALREADY mathematically coincident
   (same z, same radius, verified: both derive `wall_bottom_outer_r`
   from the identical input value) — the visible gap was that
   `hollow_frustum_shell_mesh` only ever built a TOP rim annulus,
   never a bottom one, leaving the wall's own bottom edge as an open
   ring. **Fixed**: added a bottom rim (mirrored winding, hand-
   verified outward-down normal via the same cross-product technique
   as the top rim) that sits exactly on the bottom-slab's top face.
   New selftest check confirms the coincidence numerically to 1e-6.

2. "the cylinders should not be hollow, they should be defined volumes
   like the other shapes" — the hole markers were rendered via
   `axial_mesh` with no `cap_base`/`cap_top` (the module-wide default),
   so they were open tubes. **Fixed**: hole primitives now set
   `cap_base: true, cap_top: true` — same closed-solid treatment as
   the bottom slab. Doesn't change what gets subtracted (see #3) —
   just makes the marker itself a proper solid.

3. "You subtracted a random section of the siding, what was supposed
   to be subtracted was the volume of the solid cylinder-defined-
   holes ... a defined volume subtracting from the defined volume of
   the siding" — this was a REAL bug, not just polish. The wall mesh's
   cut used a UNIFORM angular/height grid (~32×16 for the whole wall);
   a ~1cm hole is roughly 2% of the wall's circumference/height, so it
   spanned under 2 grid columns — the "cut" was one ragged wedge-
   shaped quad-drop, not a recognizable circular hole. **Fixed**:
   `hollow_frustum_shell_mesh` now builds a NON-uniform grid — the
   base coarse resolution everywhere, plus `hole_local_samples` (14)
   extra angular AND height samples densely clustered around EACH
   hole's own (azimuth, elevation), computed from the hole's actual
   radius and radial position (with a safety margin). This resolves
   each hole's actual round footprint at hole-scale instead of wall-
   scale, while leaving the rest of the wall at coarse resolution (so
   total triangle count stays bounded — demo-herb-pot's wall mesh
   went from 1088 pts/2096 tris to 5400 pts/10448 tris with 4 holes,
   not the 10-100x a naive globally-finer grid would cost). Handles
   the phi=0/2π wraparound correctly (holes at azimuth 0°, a common
   case here, insert samples on both sides of the seam — verified this
   doesn't break the ring-closing logic). Still a blocky (not
   analytically exact) cut — no general mesh-boolean engine exists in
   this module — but now resolved at the right scale. New selftest
   check: a 4x-bigger hole radius measurably removes MORE wall
   triangles than a smaller one, on the SAME refined grid (proves the
   cut scales with the actual hole volume, not a fixed/random chunk —
   the direct fix for what Dustin flagged).

**Verified**: `mathshapes/selftest_shape2.py` 44/44 (was 42) — new
checks for the flush coincidence, capped holes, and hole-size-scaled
cutting. `selftest_shapes.py` (20/20), `selftest_shape3.py` (15/15),
`selftest_shape4.py` (18/18), `aquaponics/selftest_pot.py` (24/24) all
still clean. Live curl against `demo-herb-pot`: wall mesh now 5400
points/10448 triangles; a hole's own surface now returns 34 points/64
triangles (was 32/32 uncapped) confirming the cap landed. `prf-frontend`
did NOT need rebuilding (shape-name/topology-agnostic rendering path),
confirmed still reachable (200).

**STILL NOT visually verified — no browser tool in this session.**
Open the same URL again and check: does the wall-to-bottom transition
now look seamless (no visible gap/step)? Do the holes look like solid
gray plugs sitting in a CLEAN, recognizably round cutout (not a
jagged/random notch)?

## Phase 2 — pot geometry editing Display, BUILT 2026-07-13 (Dustin
driving, said "throw out what you want" — picked this since it's the
natural next step and, unlike Phase 1, doesn't depend on visual review
of the mesh internals)

Built the editing Display per the original plan's Phase 2 spec:

- Checked `run-initial-conditions-editor.component.ts` first (the
  plan flagged this as worth checking before building bespoke) — NOT
  a fit, it's deeply tied to *SimState/SimulationRun machinery
  (per-run overrides, field save policies, storage estimates), none
  of which applies to a PotDefinition's static geometry. Confirmed a
  bespoke editor was the right call, as the plan suspected.
- New `components/aquaponics/pot-geometry-editor.component.ts` —
  standalone Angular component. Loads `PotDefinition` + its
  `PotHole` rows via the generic `CRUDEservicesManager`/
  `CRUDEclassService` (the SAME mechanism `class-main-page.ts` uses —
  `readAll()`, `update(id, data)`), plus `GET .../validate`. Edits:
  5 pot-level fields (top/base diameter, height, wall/base thickness)
  + 4 per-hole fields (diameter, elevation, azimuth, bore angle).
  Save flow: CRUDE PUT → reload → re-fetch validate → POST
  `/api/shapes/from-pot/{name}` to re-derive the render — matches the
  documented "CRUDE-edit-then-re-derive" contract exactly (does NOT
  use `modify_pot_hole`/`modify_parameter`, the mathshapes preview-
  only path). Validation findings (evidence + suggestion) always
  shown, matching knobs-and-suggestions.
- New `components/aquaponics/aquaponics-display-components.ts` —
  registers `pot-geometry-editor` with the Display registry, wired
  into `display-page.ts` alongside the msci/msim registrations
  (same lazy-load-on-display-page pattern).
- New `aquaponics/aquaponics_pages_seed.py` (backend) — seeds a REAL
  `pot-geometry` DisplayDefinition page (mirrors
  `materialsScience/msci_pages_seed.py`'s pattern exactly), defaulting
  to `demo-herb-pot`. Wired into `polariServer.py`'s seed_pairs
  alongside `SEED_MSCI_PAGE_DISPLAYS`. Reachable at
  `/display/pot-geometry` (same `/display/:id`-resolves-pageRoute
  mechanism as `/display/materials-basis`) — NOT left as a component
  that exists but has no page to find it on.
- New `aquaponics/selftest_aquaponics_pages.py` (5/5) — mirrors
  `selftest_msci_pages.py`: page seeds parse, hosted componentName
  matches the frontend registration (string contract), defaults to a
  REAL seeded pot name (not a typo-able literal).

**Verified without needing a browser** (same reasoning as Phase 1's
backend — the CRUDE PUT contract is independently checkable via curl):
live-tested the EXACT protocol the component's `CRUDEclassService`
calls use (multipart form: `polariId` + `updateData` for PUT) against
`demo-herb-pot`'s real `PotDefinition` row (edited `wall_thickness_mm`
8→9, confirmed via re-GET, confirmed `/validate` and `/api/shapes/
from-pot/` both reflected it, reverted cleanly) and a `PotHole` row
(`angle_deg` 2→3, same round-trip). `npx tsc --noEmit`: zero new
errors (still the same 18 pre-existing, unrelated ones). Backend
selftests all green: `selftest_aquaponics_pages` 5/5,
`aquaponics/selftest_pot` 24/24, `mathshapes/selftest_shape2` 44/44,
`materialsScience/selftest_msci_pages` 10/10 (confirms the
`polariServer.py` seed-wiring edit didn't disturb the existing msci
pages). `prf-frontend` rebuilt + redeployed (confirmed the new
component's code shipped in the bundle); `prf-backend` restarted
(confirmed the `pot-geometry` DisplayDefinition row seeded correctly
via curl). Both `/display/pot-geometry` and the API are reachable
(200).

**STILL NOT visually verified — no browser tool available.** The
backend contract this UI depends on is now proven correct end-to-end,
but nobody has looked at the actual form. Next: open
`https://prf.192.168.0.210.nip.io/display/pot-geometry`, edit a field,
confirm the save/validate/re-derive flow works and the SimSpace at
`/sim-spaces/demo-herb-pot-viz` reflects the edit.

## Phase 4 — soil shape, BUILT 2026-07-13 (Dustin: "keep going as far
as you reasonably can", 9 hours unsupervised — continuing per his own
explicit reordering: 1, 2, 4, 5 first, 3 and 6 last)

New `mathshapes/soil_modify.py`: `soil_shape_from_definition` derives
the soil fill from the SAME geometry `pot_shape_from_definition`
already computed — refactored `shape_modify.py` to extract
`_pot_core_dimensions(pot)` (all the derived H/radii/wall z-range/
clamped-thickness numbers) and `build_quadric_eq_row(...)` (the
quadric-row-construction contract) as shared module-level functions,
so soil's floor and radius profile are READ from the identical
numbers the wall uses — cannot drift apart, no re-derivation, no
duplicate clamping logic. Confirmed the refactor itself was
behavior-preserving (44/44 selftest_shape2 unchanged) before building
soil on top of it.

Soil design: a SOLID capped frustum (not hollow, like the bottom
slab), sitting exactly on the wall's own floor (`wall_bottom_z`),
radius bounded at every height by the wall's OWN inner-surface taper
(linearly interpolated from the same `wall_bottom_inner_r`/
`wall_top_inner_r` the wall uses) — physically cannot poke through the
wall. Its equation is a genuine quadric (same `cone_quadric_matrix`/
`build_quadric_eq_row` machinery as the wall/bottom — "source of
truth" carries through consistently), with a derived LaTeX display.
Fill height is a NEW explicit knob, `PotDefinition.soil_fill_height_mm`
(added to `aquaponics/pot_basis.py`, default 180mm) — never a hidden
fraction — clamped to the usable interior height
(`wall_height`) when it would otherwise reach the rim, reported via
`fillHeightClamped` (never silent). Refuses honestly (naming the knob)
if the fill height resolves to ~0.

Wired into `POST /api/shapes/from-pot/{pot}`: auto-derives soil right
after the wall/bottom (soil failing doesn't fail the whole re-derive —
surfaced in the response's `soil` key instead), and
`pot_scene.ensure_pot_viz_scene` now takes an optional `soil_name` and
adds it to the freestanding scene list with a new seeded material
(`simSpace3D/seed_data.py`'s `soil-brown`, `#5d4037`) — omitted
entirely (not a placeholder) if soil derivation failed. Phase 2's
`pot-geometry-editor` component gained the `soil_fill_height_mm` field
(same edit→validate→re-derive flow as everything else).

**Verified**: new `mathshapes/selftest_soil.py` 16/16 (equation
identity checks, floor/radius consistency with `_pot_core_dimensions`
via hand-computed tolerances, capped-solid mesh, clamp behavior at an
absurd 5000mm fill height, honest refusal at 0mm, from-pot
auto-derivation + scene wiring). Zero regressions: `selftest_shape2`
44/44 (one assertion updated — scene now has 5 objects not 4, an
expected/correct change, not a bug), `selftest_shapes` 20/20,
`selftest_shape3` 15/15, `selftest_shape4` 18/18, `aquaponics/
selftest_pot` 24/24, `selftest_aquaponics_pages` 5/5,
`materialsScience/selftest_msci_pages` 10/10. Live-verified on BOTH
seeded pots (`demo-herb-pot`: soil `ok`, 180mm unclamped, styled
`soil-brown`, real 50pt/96tri capped mesh; `demo-broken-pot`: soil
derivation works independently of the pot's OWN gravity validity —
correct, soil doesn't care about drainage). New schema column
(`soil_fill_height_mm`) confirmed migrating cleanly onto the EXISTING
staging volume (no data loss, default value applied) — checked this
explicitly since it's a real persisted CRUDE class, not an ephemeral
row. Both containers rebuilt/redeployed; both pages reachable (200).

**STILL NOT visually verified.**

## Phase 5 — transparency toggle, BUILT 2026-07-13 (Dustin: "keep going
as far as you reasonably can", 9hrs unsupervised — completes his own
explicit reordering: 1, 2, 4, 5 all now done; 3 and 6 deliberately
deferred, see below)

Two new PotDefinition knobs (`wall_transparent`, `soil_transparent` —
`aquaponics/pot_basis.py`, both default False/opaque, never a silent
see-through default), each swapping ONE layer's render style between
its opaque seed material and a new `-transparent` variant
(`simSpace3D/seed_data.py`: `matte-blue-transparent` opacity 0.3,
`soil-brown-transparent` opacity 0.4 — reused the SAME `opacity`/
`transparent` Material3DDefinition fields `wax-liquid`/`water-liquid`
already established a precedent for). `pot_shape_from_definition`
reads both straight off the pot row and reports them
(`wallTransparent`/`soilTransparent`); `pot_scene.ensure_pot_viz_scene`
picks the style variant per layer — wall+bottom (the vessel "shell")
share ONE toggle, soil its own, holes untouched by either. Exposed as
two checkboxes in Phase 2's `pot-geometry-editor` (same edit→validate→
re-derive flow, no new machinery). No renderer changes needed —
confirmed opacity/transparent were already consumed by
`three-material-builders.ts` back in round 1.

**Verified**: new `mathshapes/selftest_pot_transparency.py` 10/10
(default-opaque, each toggle affects ONLY its own layer — explicitly
checked wall_transparent doesn't leak into soil's style and vice
versa, holes never affected, both-together case). Zero regressions:
`selftest_shape2` 44/44, `selftest_soil` 16/16, `selftest_shapes`
20/20, `selftest_shape3` 15/15, `selftest_shape4` 18/18, `aquaponics/
selftest_pot` 24/24, `selftest_aquaponics_pages` 5/5. New schema
columns confirmed migrating cleanly onto the existing volume (both
default False). Live-verified on `demo-herb-pot`: toggled
`wall_transparent` on via CRUDE PUT, re-derived, confirmed the
SimSpace snapshot shows wall+bottom on `matte-blue-transparent` while
soil stays `soil-brown` and holes stay `matte-gray` — reverted
cleanly. Both containers rebuilt/redeployed; both pages reachable.

**STILL NOT visually verified.**

## Status: phases 1, 2, 4, 5 all built — Dustin's own reordering
complete. 3 and 6 remain, DELIBERATELY NOT started:

- **Phase 3** (water flow) has an explicit open question Dustin asked
  to be consulted on before starting: approximate repeated-steady-
  state vs a true-transient Darcy formulation. Starting it unilaterally
  would violate that direct instruction, even under a broad "keep
  going" grant — this is a design decision he specifically reserved.
- **Phase 6** (plant simulation) is "not scoped at all yet" per the
  original plan — no concrete spec exists to build against.

Given both remaining phases are explicitly gated on Dustin's input (not
just "hard," but *waiting on a decision only he can make*), continuing
into either would be guessing at his intent rather than executing a
clear instruction — different in kind from phases 1/2/4/5, which had
enough specification to build, test, and iterate against his feedback
without needing new decisions from him. Stopping here on this thread
for new phases — but see below: with Dustin gone for hours and nobody
else able to review, the responsible next move was a genuine
adversarial self-review of everything built today, not starting new
gated work.

## Adversarial self-review pass, 2026-07-13 (Dustin gone 9hrs, "keep
going as far as you reasonably can" — used the time to check today's
own work rather than pile on more unreviewed code)

Forked an independent review agent over the full day's diff (backend +
frontend, phases 1/2/4/5) with explicit instructions to hand-verify
the geometry math rather than trust the docstrings' own "verified"
claims, and to look for edge cases (degenerate pots, boundary
azimuths, division-by-zero risk, race conditions). It hand-re-derived
`cone_quadric_matrix`/`radius_at_z` against concrete numbers, redid
the `classify_axis_aligned` recentering fix's arithmetic independently
apex included, cross-product-verified the NEW bottom-rim winding this
round added (nobody had checked that one before), and traced the
phi=0°/360° wraparound case by hand. All of that came back correct —
reported explicitly, not just "looked fine."

**Real findings, fixed all of them:**

1. **HIGH — stale 3D geometry after editing, silently, within the
   same browser session.** `MathShapeGeometryLibraryService` is an
   app-lifetime singleton caching by shape NAME; `invalidate()`
   existed but was called from nowhere (confirmed by grep). Since
   re-deriving a pot reuses the SAME shape names, the 3D viewer would
   keep serving PRE-edit geometry after a Phase 2 save until a hard
   page reload — silently defeating the entire point of the editor.
   **Fixed**: `pot-geometry-editor.component.ts`'s `rederive()` now
   calls `mathShapeGeometryLib.invalidate()` on every shape name the
   from-pot response touched (wall/bottom/holes/soil) right after a
   successful re-derive.
2. **MEDIUM — clearing a numeric field and clicking Save silently
   wrote 0.** `Number('')` is `0` in JS; backspacing a field left it
   eligible to submit as a real value (clamped server-side, but not
   what the user meant). **Fixed**: `potFieldChanged`/
   `holeFieldChanged` now treat an emptied buffer as "no change" (not
   submitted) — and `saveHole`'s payload loop, which turned out to use
   a DIFFERENT, weaker inclusion check than the one guarding the
   "changed" indicator, now uses the same fixed check.
3. **MEDIUM — no upper bound on `wall_thickness_mm` let a hole's bore
   punch through BOTH sides** (the exact defect round 3 fixed,
   reachable again through an unvalidated Phase 2 input rather than
   the original code path). **Fixed two ways**: (a) `hole_length` in
   `pot_shape_from_definition` is now hard-capped so the bore can
   never reach past the pot's own central axis, regardless of how
   large wall thickness is set; (b) new `validate_pot` finding
   `wall-too-thick` (+ `MAX_WALL_THICKNESS_FRACTION = 0.4` in
   `pot_basis.py`) flags a wall that's eaten more than 40% of the
   pot's own radius — same knobs-and-suggestions honesty as the
   existing MIN_* floors, just for the other extreme.
4. **LOW — `soil_modify.py`'s docstring claimed a
   `POST /api/shapes/from-soil/{pot_name}` route that was never built**
   (soil actually derives as a side effect inside `on_post_from_pot`).
   Fixed the doc to say so.
5. **LOW — unguarded division by zero** in
   `hollow_frustum_shell_mesh` if `hole_local_samples` were ever set
   to 1 (not reachable through any current caller, but a real keyword
   parameter, not just an internal constant). Clamped to a minimum of
   2 at the top of the function.
6. **LOW — `ensure_pot_viz_scene`'s scene `description` froze at
   first creation**, only `.definition` updated on re-derive.
   Harmless today (Phase 2 can't add/remove holes yet) but would
   silently drift if that changes. Fixed to recompute on every call.

**Verified all six**: new/extended selftest coverage for each
(`selftest_pot.py` +2 checks for `wall-too-thick`, `selftest_shape2.py`
+3 checks for the hole-length cap and the `hole_local_samples=1`
guard), `tsc --noEmit` still exactly the same 18 pre-existing/
unrelated errors, and the FULL backend regression sweep re-run clean:
`selftest_pot` 26/26, `selftest_shape2` 47/47, `selftest_soil` 16/16,
`selftest_pot_transparency` 10/10, `selftest_shapes` 20/20,
`selftest_shape3` 15/15, `selftest_shape4` 18/18,
`selftest_aquaponics_pages` 5/5 — **157/157 checks passing** across
everything touched today. Live-reverified `demo-herb-pot` still
derives cleanly (valid, no findings) after all fixes. Both containers
rebuilt/redeployed once more; both pages still reachable (200),
confirmed the `invalidate` fix actually shipped in the served bundle.

The frontend fixes (cache invalidation, blank-field guard) are
type-checked and logically verified by the review but — same
limitation as everything else today — NOT visually confirmed, since
there's still no browser tool in this environment. This is genuinely
the most important thing left to check when someone's back at a
screen: **does editing a field in `/display/pot-geometry` and then
visiting `/sim-spaces/demo-herb-pot-viz` actually show the updated
geometry without a manual page reload?** That's exactly what finding
#1 was about, and it's the one most worth a human's eyes on.

Original Phase 1 scope notes (superseded by the above where they
conflict):
- Decide + build the pot's SimState class(es) so a SimSpace can bind
  to it. Open design question not yet resolved: does binding need a
  NEW lightweight *SimState wrapper class, or can `PotDefinition`
  itself serve as a bindable class directly? Check how SimSpace
  binding actually resolves `className` → row data before deciding;
  this wasn't nailed down this session.
- New `SimSpaceDefinition` — pick an intuitive name (not yet decided
  with Dustin; "self-watering-pot" or "aquaponic-pot-viz" were
  floated but never confirmed — ask or just pick one, it's easy to
  rename later).
- New frontend geometry-builder: given a math-shape's `/surface`
  response (`points`/`triangles`), build a real `THREE.BufferGeometry`
  and feed it into the existing SimSpace 3D rendering path. This is
  the single biggest net-new piece — read `three-geometry-builders.ts`
  and `mesh-3d-library.service.ts` first as the model for how meshes
  are currently built/registered, then add a path that consumes
  math-shape surface data instead of (or alongside) the existing
  built-in primitive/GLTF sources.
- Use the body+holes-as-separate-primitives approach documented above
  (NOT the CSG shape directly) to get real triangulated meshes without
  needing new backend geometry algorithms.

### Phase 2 — custom Display for editing pot geometry
- New `aquaponics-display-components.ts`, registered via
  `registerDisplayComponent`.
- Form fields: hole elevation (`height_mm`), hole diameter
  (`diameter_mm`), pot size (`outer_top/base_diameter_mm`,
  `height_mm`). Writes via standard CRUDE PUT to
  `PotDefinition`/`PotHole` (already works, no new backend route).
- Call `GET /api/aquaponics/pots/{name}/validate` before/after each
  edit for gravity-validity feedback (matches this codebase's
  knobs-and-suggestions convention — surface the consequence, never
  silently apply something that breaks drainage).
- After a successful edit, `POST /api/shapes/from-pot/{name}` again to
  refresh the derived geometry, then re-fetch `/surface` for
  phase-1's renderer to redraw.
- Worth a quick check first: does the GENERIC
  `run-initial-conditions-editor.component.ts` already produce basic
  numeric controls for these fields for free, before writing a fully
  bespoke editor?

### Phase 4 — soil shape derived from pot geometry
- Not yet designed this session. Likely: a new mathshapes helper
  (parallel to `pot_shape_from_definition`, maybe
  `soil_shape_from_definition`) that shrinks the pot's interior by
  `wall_thickness_mm`/`base_thickness_mm` and fills to some level —
  probably another `primitive` (frustum) shape so it gets a real
  triangulated mesh for free via the same phase-1 rendering path.

### Phase 5 — transparency toggle
- Smallest phase. Per-layer style refs (pot shell / soil, water
  later) each with their own `opacity`/`transparent` on their
  `Material3D`/style def, plus a toggle UI mirroring the existing
  `overlayVisible` pattern in `sim-space-editor-sidebar.component.ts`.
  No renderer changes needed — this field is already consumed.

## Deferred — LAST, per Dustin's explicit instruction (most complex)

### Phase 3 — water flow visualization
- Needs a NEW time-stepping layer over the existing steady-state
  Darcy solve — open question for Dustin, not yet decided: repeated
  steady-state solves as water level/conditions change over simulated
  time (simplest, reuses what exists, an approximation) vs. a true
  transient Darcy formulation (bigger, more physically real). Ask
  before committing effort here.
- Then: convert each step's `headField` mesh into something
  phase-1's renderer can draw (a math-shape-compatible surface, or a
  custom point/volume visualization) that updates per simulation tick.

### Phase 6 — plant simulation in the pot
- Not scoped at all yet. aqp-4/aqp-8 (plant parts, growth/failure)
  already exist in `aquaponics/` per memory — worth reading those
  before starting, likely the natural base to extend into the visual
  SimSpace once phases 1/2/4/5 prove the rendering pipeline works.

## Open questions for Dustin (ask before deciding unilaterally)

1. SimSpace name for the pot visualization.
2. Phase 3: approximate (repeated steady-state) vs true-transient
   water simulation — deferred, no rush, but flag before starting it.
3. Phase 1: does the pot need its own new *SimState wrapper class, or
   can `PotDefinition` bind directly? (Technical question — may not
   need Dustin's input, just needs investigation before coding.)

## File map (everything found/touched this session)

Backend:
- `polari-rf-node/polari-framework/aquaponics/pot_geometry.py` —
  `PotDefinition`, `PotHole`, `validate_pot`, `generate_holes`.
- `polari-rf-node/polari-framework/aquaponics/pot_api.py` — pot CRUDE
  + validate + generate-holes-preview routes.
- `polari-rf-node/polari-framework/aquaponics/hydraulics.py` +
  `materialsScience/engines/darcy_engine.py` — steady-state Darcy FEM.
- `polari-rf-node/polari-framework/mathshapes/shape_basis.py` —
  `MathShapeDefinition`.
- `polari-rf-node/polari-framework/mathshapes/shape_analysis.py` —
  evaluate/classify/sample_surface/properties; CSG surface = point
  cloud only (see gotcha above).
- `polari-rf-node/polari-framework/mathshapes/shape_modify.py` —
  `modify_parameter`, `pot_shape_from_definition`, `modify_pot_hole`.
- `polari-rf-node/polari-framework/mathshapes/shape_api.py` — **edited
  this session**, new `from-pot` route, unverified.
- `polari-rf-node/polari-framework/mathshapes/shape_seed.py` — demo
  `pot-with-holes` seed (fixture, not the real derived pot).
- `polari-rf-node/polari-framework/mathshapes/selftest_shape2.py` —
  existing test style/harness to extend.
- `polari-rf-node/polari-framework/simSpace/sim_space_definition.py` +
  `sim_space_binding_definition.py` — SimSpace/binding model.

Frontend (all reference points only — nothing built yet):
- `services/sim-space-3d/mesh-3d-library.service.ts`,
  `services/sim-space-3d/three-geometry-builders.ts` — mesh-building
  model to extend for math-shape surfaces.
- `services/sim-space-3d/material-3d-library.service.ts` — opacity/
  transparent fields already there.
- `models/dashboards/ComponentRegistry.ts` — `DISPLAY_COMPONENT_REGISTRY`
  / `registerDisplayComponent`.
- `components/multi-scale/msim-display-components.ts`,
  `components/materials-science/msci-display-components.ts` — example
  feature-scoped Display registration files to model
  `aquaponics-display-components.ts` on.
- `components/sim-space/sim-space-viewer/run-initial-conditions-editor.component.ts` —
  generic auto-discovering IC editor, check before building bespoke.
- `components/sim-space/sim-space-viewer/sim-space-editor-sidebar.component.ts` —
  `overlayVisible` toggle pattern to mirror for phase 5.

## Related

Unfinished from the PRIOR session, deliberately shelved (not part of
this thread): WebXR pointer/HUD fixes + EQUATIONS/LEGEND/NO-CODE
panels + direct-entry route + 2D-as-HTMLMesh — see
[[webxr-plan]] memory, branch `dev-xr-3-min-ng`, all uncommitted,
awaiting Dustin's next headset session (unrelated to this pot work,
just also mid-flight).
