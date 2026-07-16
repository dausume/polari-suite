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

## Transparency defaults flipped + Phase 3 (water-flow visualization) — DONE + VERIFIED (2026-07-15)

Dustin, after confirming phases 1/2/4/5's only remaining visual issue
was "the hole cylinders not being fully transparent by default":
*"Continue work on the water simulation and visualization in the pot
(default cylinders for holes to fully transparent, the pots and soil
only mostly transparent so we can see the water flow) this simulation
should be separate from the pot with soil that lacks water flowing
through."* — resolving phase 3's only open question (approximate
repeated-steady-state vs true-transient) in favor of the simpler
option the plan itself already flagged as the pragmatic first pass.

**Transparency defaults**: `PotDefinition.wall_transparent`/
`soil_transparent` now default `True` (were `False`) — a fresh pot is
see-through by default, opaque is the opt-out. Holes get a NEW
dedicated `matte-gray-transparent` Material3D row (opacity 0.08) and
`pot_scene.py`'s `HOLE_STYLE_REF` now points at it UNCONDITIONALLY —
holes were never gated by either toggle before and still aren't, they
just render at the transparent variant now instead of opaque. Kept as
its own row rather than lowering the shared `matte-gray`'s own
default, which other non-pot scenes use at full opacity. **Real gotcha
hit and fixed**: flipping the class default only affects NEW rows —
the already-seeded `demo-herb-pot`/`demo-broken-pot` had `False`
persisted from when they were first created under the old default;
fixed with an explicit CRUDE PUT on both live rows (confirmed via
`from-pot` re-derive afterward that both now report `wallTransparent`/
`soilTransparent: true`). Worth remembering for any future default
flip on an already-seeded class.

**Phase 3 — water-flow visualization, a SEPARATE scene**:
`ensure_pot_water_viz_scene()` (`mathshapes/pot_scene.py`) builds
`{pot_name}-water-viz` as a genuinely different `SimSpaceDefinition`
row from the static `{pot_name}-viz` (confirmed live: editing one
never touches the other) — ALWAYS renders shell/soil transparent
regardless of the pot's own toggles (seeing the water is this scene's
whole point), plus one new freestanding entry for the live water
slice. Both scenes are reachable through the existing generic
`/sim-spaces/:name` route with zero new routing — `{pot}-viz` and
`{pot}-water-viz` are just two different SimSpace names.

**The water mesh itself**: `aquaponics/hydraulics.py::water_slice_mesh()`
runs the existing steady-state Darcy solve and 3-D-positions the
result as a flat plane through the pot's real input→output azimuth
line, in the SAME (cm, z-through-center) frame the pot's own wall/
soil/hole meshes already render in — no extra transform needed on the
frontend. **Stated plainly, not hidden**: this is a flat 2-D
cross-section (the Darcy engine's own documented fidelity ceiling),
not a full 3-D volume, and "time-stepping" is repeated independent
steady-state solves at a rising `water_level_mm` — NOT a true
transient formulation. `darcy_engine.py` (+ its worker twin
`msci-engines/darcy_solver.py`, kept in sync per the module's own
instruction) now also returns `headFieldTriangles` (mesh.t
connectivity) — needed to have a real triangulated surface at all,
previously only scattered points were exposed.

New route: `GET /api/aquaponics/pots/{name}/water-slice?waterLevelMm=
&refine=`. Frontend: `WaterSliceGeometryLibraryService` (mirrors
`MathShapeGeometryLibraryService`'s deferred-population trick, keyed
by pot name so the SAME BufferGeometry updates in place across ticks
rather than reallocating), a new `waterslice:` shapeRef prefix in
`ThreeSimSpaceRenderer.buildMeshFor`, and a self-contained fill
animation (`startWaterAnimation`, `ThreeSimSpaceRenderer` itself, NOT
the generic viewer component — same architectural call as the
shapeRef-prefix dispatch already living there) that ramps
`water_level_mm` 0 → the maintained level over ~2.8s the moment a
`waterslice:` object appears in a snapshot, then holds — a
self-watering pot's reservoir fills once and stays maintained, it
doesn't repeatedly fill/drain, so this deliberately animates once per
scene view rather than looping.

**Verified live, full chain**: backend selftests 48/48 (17
`selftest_pot_transparency` — rewritten for the new default direction
+ new water-scene coverage; 31 `selftest_hydraulics` — 8 new
`water_slice_mesh` checks including hand-verified 3-D positioning
math), run both against the mocked engine AND the REAL local skfem
solver (81 nodes / 128 triangles for `demo-herb-pot` at refine=4, a
genuine triangulated mesh, not empty). Live curl against the running
backend: `water-slice` endpoint returns real geometry
(`waterLevelMm: 200`, real `outflowRateMlS`); `from-pot` on the live
`demo-herb-pot` confirms both scenes exist with the exact expected
per-layer styles (holes transparent in BOTH scenes; shell/soil opaque
in the static scene per its own toggle, transparent in the water
scene regardless). Frontend: full `ng build` clean, `prf-frontend`
redeployed, both `/sim-spaces/demo-herb-pot-viz` and `.../demo-herb-
pot-water-viz` serve 200, new code (`startWaterAnimation`,
`WaterSliceGeometryLibraryService`) confirmed present in the deployed
bundle, CORS confirmed correct on the new endpoint.

**Not yet done — no browser available in this environment**: the
actual visual result (does the fill animation read as "water flowing"
rather than a static plane, is the flat 2-D slice's honest
simplification acceptable in practice, does the pot look right at
"mostly transparent") is unverified beyond automated
build/deploy/API-shape checks — same standing caveat as every other
phase of this plan. This is the one thing that most needs Dustin's
own eyes on a headset-free screen next.

## Phase 6 — plant growth simulation (normalized growth + animation-bones skeleton), DONE + VERIFIED (2026-07-15)

Dustin, after confirming the water simulation's input-hole-in /
output-hole-out / re-solved-per-frame model was correct: *"What we
want to do after this... would be simulating a plant actually being
put into the pot... simulate the growth of the plant over time and
simulate based on the conditions of the constraints of the pot and
the conditions of the soil and amount of water available."* Refined
across several more rounds of direction (verbatim quotes kept in
`aquaponics/plant_growth_normalized.py`'s own module docstring, since
they're load-bearing for the whole design): species-level "Free Soil
Constants" first, "Constrained Limits" (does it survive stabilizing
growth in THIS pot) second; normalized growth (a 0-1 volume fraction)
replacing age, with a hard sane-ceiling safety valve; growth tracked
PER PLANT PART, not one whole-plant scalar; an "animation bones"
vector-graph geometry representation (chosen specifically so a future
real-scan reverse-mapping function has a well-posed target); explicit
SHAPE-equation vs GROWTH-equation split, both part-specific. The
stress-TYPE-differentiated matrix-equation layer (atmospheric/soil/
water multivariable space) Dustin described in the same conversation
is deliberately NOT built here — flagged as its own dedicated design
pass, to be done after this checkpoint.

**New/changed files**:
- `plant_morphology/organ_basis.py` — `RootSystemModel` gained
  `soil_root_density_g_per_cm3`, `root_core_diameter_mm`,
  `root_taper_exponent`, `root_hair_diameter_mm` (Free Soil Constants
  additions).
- `aquaponics/plant_basis.py` — `PlantDefinition` gained
  `normalized_growth_rate_per_day` (a FALLBACK rate only, used when a
  part has no `PlantGrowthModel` row of its own — aqp-8's existing
  per-part `growth_rate` is the primary source).
- `aquaponics/plant_growth_normalized.py` (new) — `free_soil_constants()`
  (Stage 1, read straight off existing rows), `constrained_limits()`
  (Stage 2, reuses `plant_morphology.morphology_analysis.
  confinement_assessment()` unchanged), `PotPlanting` (the missing
  instance state — `part_growth_json` per part, `random_seed` for
  reproducible geometry), `advance_growth()` (closed-form
  logistic-with-ceiling solve per part, real conditions control RATE,
  confinement controls CEILING — two separate knobs, never collapsed),
  `current_root_profile()`/`current_canopy_profile()` (the SHAPE
  equations).
- `aquaponics/plant_skeleton.py` (new) — `generate_skeleton()`: two
  independent recursive walks (roots down, canopy up) off one shared
  core point, reusing `RootSystemModel.pattern`/`OrganModel.
  arrangement` as branching-behavior knobs, `random.Random(seed)` for
  reproducibility, two independent hard caps
  (`max_generations`/`max_bones`) as a computational safety valve
  distinct from `SANE_MAX_LINEAR_MM`'s physical-dimension cap — both
  reported in the response, never silently truncated.
- `aquaponics/plant_growth_normalized_seed.py` (new) — one real demo
  `PotPlanting` (`demo-herb-pot-basil-1`, sweet-basil in
  demo-herb-pot, `random_seed=8241`), reusing real seeded rows across
  every module this feature spans rather than fixture-only data.
- `aquaponics/plant_growth_normalized_api.py` (new) — the HTTP
  surface: `GET .../plants/{name}/free-soil-constants`,
  `GET .../pots/{name}/plants/{plant_name}/constrained-limits`,
  `GET .../plantings/{name}` (overall + both shape profiles),
  `POST .../plantings/{name}/advance` (the one mutating action),
  `GET .../plantings/{name}/skeleton`.
- `polariApiServer/polariServer.py` — `PotPlanting` registered in both
  `defClassList` AND `seed_pairs` (the standing "registered in only
  one of the two = silent 404s" lesson applied); the new API endpoint
  class instantiated alongside the other aquaponics endpoints.
- `aquaponics/selftest_plant_growth_normalized.py` (new) — 38 checks
  against REAL seed data (sweet-basil / demo-herb-pot, not
  fixture-only rows), covering both stages, the safety ceiling,
  per-part `advance_growth` (including the never-collapsed
  rate-vs-ceiling distinction), both shape equations, and the bone
  generator (connectivity, direction, reproducibility, the two
  independent caps). 38/38 passing.

**Three real bugs found + fixed while writing/running the selftest**
(the same "write the test, let it find real bugs" discipline as every
prior phase):
1. `constrained_limits()` read `confinement['indefinite']`, but
   `confinement_assessment()` actually returns
   `canKeepIndefinitely` — a `KeyError` on every real call, caught
   immediately by the first Stage-2 test.
2. `plant_skeleton.generate_skeleton()`'s terminal-organ (leaf/flower/
   fruit) attachment looked organs up by `organs_by_part[part_name]`
   where `part_name` was the STRUCTURAL AXIS's own part (`'stem'`) —
   but a leaf organ's growth-tracking part is `'leaf'`, never
   `'stem'`, so the lookup could never find it; worse, it was
   self-matching the stem organ onto itself. Fixed by attaching ALL
   non-axis organs (not filtered by matching part name) along every
   bone of the one structural axis, with each organ's `currentCount`
   pre-divided by a geometric-series estimate of the axis's total bone
   count (`_estimate_axis_bone_count`) so the sum across the whole
   axis approximates the real plant-wide count instead of placing the
   full count at every single bone.
3. The seed fixture (`plant_growth_normalized_seed.py`) initially
   omitted `part_growth_json`/`condition`/etc. — since selftests build
   `SimpleNamespace(**row)` directly (bypassing `PotPlanting.__init__`
   entirely), an omitted key is a missing ATTRIBUTE, not a
   silently-applied constructor default. Same standing lesson as the
   pot-transparency fixture bug in phase 3 — now stated explicitly
   in-file so it isn't rediscovered a third time.

**Route-naming gotcha, new this phase**: Falcon's compiled router
requires the SAME field name for every route sharing a trie node.
`plant_growth_normalized_api.py`'s first draft used `{plant_name}`/
`{pot_name}` where `plant_api.py`/`pot_api.py`/`hydraulics_api.py`
already use `{name}` at the same `plants/`/`pots/` path level — this
crashed the ENTIRE backend at boot with
`falcon.routing.compiled.UnacceptableRouteError`, not a per-route
404. Fixed by matching the existing `{name}` convention at both outer
segments (the deeper, previously-unused `plants/{plant_name}` segment
under `pots/{name}/` didn't need to change). Worth remembering for any
future aquaponics endpoint: check what field name existing routes
already use at that path prefix before picking a new one.

**Live-verified against the running `prf-backend`** (not just the
selftest): all 4 GET endpoints curled successfully with real
DB-backed data (`free-soil-constants`/`constrained-limits` off the
real `sweet-basil`/`demo-herb-pot` rows; `/plantings/{name}` and its
`/skeleton` off the real seeded `demo-herb-pot-basil-1` — the
skeleton response showed a real connected bone graph rooted at
`coreOriginMm: [0, 0, -125]`, matching demo-herb-pot's known
floor height). The mutating `POST .../advance` endpoint was called,
its effect confirmed via a SEPARATE follow-up GET (proving the write
round-tripped through the real MariaDB, not just in-process state),
then the demo planting was reset back to its pristine seed state via
CRUDE PUT (`part_growth_json: '{}'`, `condition: 'healthy'`,
`last_advanced_at: ''`) so it stays a clean starting point for future
frontend work.

**Not yet done**: the frontend geometry layer (a pot-plant SimSpace
view consuming `/skeleton`'s bone graph — same "live-computed, not a
stored shape row" pattern as the water slice) — explicitly deferred,
this checkpoint was scoped to the backend engine + API + live
verification only. Also explicitly deferred per Dustin's own framing:
the stress-type-differentiated matrix-equation layer + a diagnostic/
evaluation interface for inspecting shape/growth equations per part
at different ages — a substantial enough addition to warrant its own
dedicated design pass rather than being folded into this checkpoint.

## Phase 7 — stress-type-differentiated growth equations, DONE + LIVE-VERIFIED (2026-07-15)

Dustin, immediately after phase 6's checkpoint: *"these equations can
vary based on different kinds of stress conditions... an interface
specifically for looking through and evaluating how these are
functioning... these should be interconnected matrix equations that
define multivariable spaces based on atmospheric and soil and water
inputs."* Researched first (forked, read-only) whether this codebase
already had reusable no-code equation infrastructure before designing
anything — it does: `matrices/matrix_equation_definition.py`
(`MatrixEquationDefinition`) + `matrices/matrix_equation_executor.py`
(`evaluate_equation(eq_def, binding_values, manager)`) is a real,
general, already-built multivariable equation engine (operands can be
matrices, other matrix-equations, or scalar `EquationDefinition`s;
`{"kind": "expr", "expr": "..."}` runs a sandboxed NumPy expression
over named bindings) — reused directly rather than reinventing a
second equation system. Also confirmed real atmosphere/soil/water data
already exists (`AtmosphereDefinition`: co2_ppm/o2_pct/temperature_c/
relative_humidity_pct/light_ppfd_umol_m2_s/...; `WaterDefinition`:
temperature_c/ph/electrical_conductivity_ds_m/dissolved_oxygen_mg_l/
...) — no new atmospheric/water fields needed for a first pass.

**Two-tier design** (`aquaponics/plant_stress.py`, new): TIER A — a
`StressResponseCurve` row's min/optimalLow/optimalHigh/max fields
define a standard trapezoidal response over ONE real scalar (the same
shape real crop models like DSSAT/APSIM use) — always available, no
equation authoring required, so every species gets a real answer on
day one. TIER B — a curve can instead set `equation_ref` (a real
`MatrixEquationDefinition` name) + `input_bindings_json` (symbol ->
{source, field}) for genuine multivariable/interconnected behavior,
falling back to Tier A if unset. Curves are keyed by (plant_name,
part, stress_type) — Dustin's "vary based on the plant part" applies
for real: sweet-basil's ROOT curves read WATER fields (oxygen/pH/
salinity), its STEM/LEAF curves read ATMOSPHERE fields (temperature/
humidity/light/CO2) — never the same equation forced onto every part;
LEAF even gets its OWN (tighter) temperature curve, separate from
STEM's.

**Combining stress types**: Liebig's Law of the Minimum (`min()`
across whatever stress-type curves resolved for that part) — a
standard plant-physiology principle for co-limiting factors, and a
deliberate correction from the OLD `water_supply_factor *
soil_supply_factor` product model (a product punishes several mildly-
suboptimal-but-not-actually-limiting factors far more harshly than
real plants do).

**Wiring into `advance_growth()`** (`aquaponics/plant_growth_normalized.py`):
signature changed from `water_supply_factor=1.0, soil_supply_factor=1.0`
to `=None, =None` — an explicit override still wins exactly like
before (manual, uniform-across-parts, 100% behavior-preserving for
every existing call site); when NEITHER is passed and the planting's
NEW `PotPlanting.system_name` field (references a real
`aquaponics.pot_system.PotSystemDefinition`) is set, PER-PART stress
factors are auto-computed from that system's real atmosphere/water/
soil rows instead — genuinely different parts can now get genuinely
different growth rates from the same tick. No system_name -> honest
1.0 for every part, never a guessed penalty.

**Demo data**: reused the REAL, already-seeded `aquaponics.
pot_system_seed`'s contrasting pair (`basil-aquaponic-tent` healthy-
ventilated vs `basil-aquaponic-sealed` degraded — aqp-6 built this
pair specifically "so survival + impact have a live pass/fail
contrast"). Added a SECOND demo `PotPlanting`
(`demo-herb-pot-basil-sealed`, same pot/plant, bound to the sealed
system) alongside the existing `demo-herb-pot-basil-1` (now bound to
the healthy system) so a live check can compare them side by side.
8 real `StressResponseCurve` rows seeded for sweet-basil across its 3
parts (`aquaponics/plant_stress_seed.py`) — checked against the two
systems' REAL numbers, not designed to force a contrived result: ROOT
and STEM come out IDENTICAL between the two systems (they only read
fields that don't differ, or read the shared water row); LEAF
genuinely differs (light 250 vs 350 PPFD, CO2 800 vs 420 ppm — both
mildly limiting in the sealed chamber, light the worse of the two).

**New HTTP surface** (`aquaponics/plant_growth_normalized_api.py`):
`GET .../plantings/{name}/stress` (every part's full per-stress-type
breakdown against the bound system — the diagnostic view), `GET
.../stress-curves/{name}/sweep?steps=<n>` (Tier-A curves only —
samples factor-vs-input across the curve's own range, independent of
any live data row; Tier-B equations are diagnosed via the no-code
matrix-equation editor's own existing run-overlay instead of
duplicating that UI here).

**New Falcon route-trie gotcha, same class as phase 6's**: no new
conflicts this time (checked `{name}` at every shared segment before
writing routes), but worth restating since it WILL recur: any new
route sharing a literal path prefix with an existing one MUST reuse
that existing field name.

**One real repeat of the phase-3/6 "new field on an existing seeded
row" gotcha**: `demo-herb-pot-basil-1` already existed from the phase-6
deploy (seeding is idempotent-by-name — it does NOT retroactively
apply newly-added seed-dict fields to an already-persisted row), so
its brand-new `system_name` field stayed empty after this deploy even
though the seed file said `'basil-aquaponic-tent'` — caught
immediately via the live `/stress` endpoint returning `mode:
"no-linkage"` when `"stress-equations"` was expected. Fixed with the
same CRUDE PUT pattern as before. **Third occurrence of this exact
class of gotcha this session — worth internalizing as a standing
habit: after ANY seed-dict field addition to an existing named row,
always CRUDE-PUT the live row too, don't assume the new deploy alone
covers it.**

**Selftests**: `aquaponics/selftest_plant_stress.py` (new, 32/32) —
trapezoid math (including a genuine near-zero-span division-guard
case, not a provably-unreachable one), Tier-A against real seeded
rows, Tier-B against a REAL `MatrixEquationDefinition` (including its
own clamp actually engaging on an unclamped raw ratio > 1), Liebig's-
Law combination, the real root/stem-identical vs leaf-different
contrast, the sweep diagnostic, and `advance_growth`'s three modes
(manual/stress-equations/no-linkage). `selftest_plant_growth_
normalized.py` re-run clean at 38/38 with zero changes needed (the
manual-override path is untouched; the one call using neither factor
now takes the no-linkage fallback since that test's fixture has no
`PotSystemDefinition` table, exercised gracefully). Zero regressions
across all 8 suites touched this session.

**Live-verified against the running `prf-backend`**: `GET .../stress`
on both real demo plantings after the system_name fix — leaf
`combinedFactor` 1.0 (healthy) vs 0.85 (sealed, `limitingStressType:
"light"`), root `combinedFactor` 1.0 for BOTH (same water row); `GET
.../stress-curves/{name}/sweep` returned a real 8-point trapezoid
sample set; `POST .../advance` on both real plantings showed the
sealed planting's leaf growing measurably less (0.07366 vs 0.0918
normalizedGrowth over the same 10 days) while root growth was
IDENTICAL between them (0.07643 both) — real per-part physics
reaching the actual growth numbers, not just reported diagnostics.
Both plantings reset to pristine `part_growth_json: '{}'` afterward,
`system_name` bindings left in place.

**Not yet done**: the frontend diagnostic UI (a plant-growth-specific
wrapper around the existing matrix-equation run-overlay, pre-
populating operand bindings from a planting's bound system) —
explicitly lower priority per Dustin's own softer phrasing ("would be
a good idea," not a requirement) and consistent with this session's
established rhythm of shipping the backend solidly first. A genuine
range/plot-over-a-range UI for Tier-B equations also doesn't exist yet
anywhere in this codebase (the no-code editor's run-overlay only
evaluates one binding set at a time) — would be new UI work, not a
reuse of an existing sweep view, if ever built.

## Phase 6b — plant skeleton visualization (the geometry payoff), DONE + LIVE-VERIFIED (2026-07-15)

Immediately after phase 7's checkpoint — the growth engine's output
was still only visible as API JSON, and Dustin's ORIGINAL framing for
this whole thread was "What will that growth look like?" — so the
next piece was giving `generate_skeleton()`'s bone graph an actual 3D
home, mirroring the water-flow visualization pattern exactly (a THIRD
`shapeRef` resolution scheme, alongside `mathshape:`/`waterslice:`).

**Backend** (`mathshapes/pot_scene.py`): new
`ensure_pot_plant_viz_scene(manager, planting_name, pot_name, ...)` —
creates/refreshes `{planting_name}-plant-viz`, deliberately keyed by
PLANTING not pot: a pot can have more than one `PotPlanting` bound to
it (this session's own real seed data does — the same demo-herb-pot
under two different what-if `PotSystemDefinition`s), and two plants
can't physically occupy one pot, so a pot-keyed scene would be
ambiguous the moment a second planting exists. Same always-transparent
shell/soil as the water-viz scene (seeing the plant/roots through the
pot is the point) plus one `plantskeleton:{planting_name}` freestanding
entry. `mathshapes/shape_api.py`'s `on_post_from_pot` now creates one
plant-viz scene per `PotPlanting` bound to the re-derived pot
(`result['plantSimSpaces']`, a list) — never fails the whole re-derive
if a planting is malformed, an honest per-planting gap. New
`plant-green` material (`simSpace3D/seed_data.py`, opaque `#43a047`).

**Frontend** (`plant-skeleton-geometry-library.service.ts`, new): same
deferred-population `THREE.BufferGeometry` cache pattern as
`WaterSliceGeometryLibraryService` — but a skeleton isn't a
pre-triangulated mesh, it's a LIST OF BONES (start/end point + radius,
mm), so this is the first geometry-library service that actually
BUILDS a mesh rather than just loading backend-provided vertices: one
`THREE.CylinderGeometry` per bone (rotated from +Y onto the bone's real
direction via `Quaternion.setFromUnitVectors`, translated to its
midpoint), merged into a single geometry via three's own
`BufferGeometryUtils.mergeGeometries` (reused, not hand-rolled vertex
merging). Bone points are mm; the pot's own meshes are cm
(`water_slice_mesh`'s own convention) — divided by 10 so a skeleton
drops into the same scene with no separate transform. `three-renderer.
service.ts` gained a `plantskeleton:` prefix branch (single-sided,
unlike the two plane/shell branches above it — bones are real solid
volumes) and `sim-space-renderer-factory.service.ts` threads the new
service through the constructor, matching the existing pattern exactly.

**A genuine pre-existing test bug found via the regression sweep, not
introduced this phase**: `mathshapes/selftest_shape2.py`'s "re-deriving
refreshes not duplicates" check asserted `len(SimSpaceDefinition) == 1`
— stale since phase 3 added the SEPARATE `{pot}-water-viz` scene (should
have been `== 2` from that point on) but was never caught because this
test file wasn't part of phase 3's own verification sweep. Fixed
(`== 2`, exact key-set check) and extended with real positive/negative
plant-viz-scene coverage. 51/51 passing (was 47).

**Live-verified against the running `prf-backend` + rebuilt
`prf-frontend`**: `POST /api/shapes/from-pot/demo-herb-pot` returned
`plantSimSpaces: ['demo-herb-pot-basil-1-plant-viz', 'demo-herb-pot-
basil-sealed-plant-viz']` — one real scene per real demo planting;
fetched `demo-herb-pot-basil-1-plant-viz`'s stored definition directly
and confirmed the exact expected freestanding list (transparent shell/
soil/holes + one `plantskeleton:demo-herb-pot-basil-1` entry, styled
`plant-green`). `ng build` clean (zero new errors beyond the
pre-existing unrelated baseline), `prf-frontend` redeployed (copied
around a busy bind-mount at `assets/runtime-config.json` — copied every
other path individually instead of the whole tree), confirmed the new
`PlantSkeletonGeometryLibraryService`/`plantskeleton` code is present
in the actual served JS chunk via a real HTTP GET (not just a file
read), and `/sim-spaces/demo-herb-pot-basil-1-plant-viz` serves 200.

**Still not visually verified — no browser in this environment.**
Same standing caveat as every other phase: build/deploy/API-shape
verified, not eyes-on. This is now the single most valuable thing left
for Dustin's own screen time across the WHOLE plant-growth-sim thread
— does a rendered skeleton actually read as a recognizable root/stem/
leaf plant shape, do the tapered cylinders look reasonable at typical
seedling sizes (very thin radii — MIN_RENDER_RADIUS_MM=0.15mm/10=
0.015cm floor exists specifically so a just-germinated plant doesn't
render as literally invisible slivers), does the always-transparent
pot read as "look, there's a plant in there" the way it's intended to.

## Phase 8 — direct-light field simulation, DONE + LIVE-VERIFIED (2026-07-15)

Dustin, immediately after phase 6b's checkpoint: *"something I forgot
to account for here was sunlight, or light simulation in general via
FEM. We should define the direction of sunlight or a growth light in
general and be able to convert its incidence on a plant into a value
it absorbs and applies to growth equation. We should have an
independent capability to simulate light vector fields of both
particular wavelengths, and defined spectrum equations of light (like
the standard light from the sun on the surface of the earth for
example)."* Researched first (forked): `PhotoAbsorberDefinition`/
`SolarLayerDefinition`/`SolarStackDefinition` (electrodevice/) turned
out to be a false lead — photovoltaic bandgap/absorption-edge
matching, not a spatial light field. But `electrodevice/
photo_derive.py` had a genuinely reusable numeric TECHNIQUE: a
blackbody-photon-flux quadrature (`E^2/(exp(E/kT)-1)`-style
integration) already proven for solar-cell efficiency math. Also
found: the codebase's generic FEM engine (`materialsScience/engines/
fem_engine.py`) solves DIFFUSION PDEs — the right tool for scattered/
diffuse skylight through a dense canopy, but the WRONG tool for direct
sunlight, which is a straight-line vector/occlusion problem. Proposed
this distinction to Dustin explicitly rather than mislabel vector math
as "FEM"; he confirmed: *"doing it via direct light would be much
simpler for now, later on we will also need to be able to do diffuse
light however. So perhaps both. We should start with direct as you
proposed and account for the shapes of the different plant parts in
that as well later."* — direct light now (this phase), diffuse
(FEM-based, reusing fem_engine.py) and per-part-SHAPE-specific
incidence (a real leaf-blade normal instead of the cylinder-projection
proxy below) both EXPLICITLY deferred, not silently skipped.

**Data model** (`aquaponics/light_basis.py`, new): `LightSpectrumDefinition`
— 'monochromatic' (a specific wavelength ± bandwidth, e.g. a red LED)
or 'blackbody' (a Planck's-law thermal curve at temperature_k — THE
standard model for "sunlight at Earth's surface," 5778K default, the
same constant photo_derive.py's own solar-cell math uses). Both are
Tier-A/always-available — a custom equation-driven spectrum
(`equation_ref`, mirroring phase 7's Tier-B pattern) is real future
work, deliberately NOT built this pass per Dustin's own "much simpler
for now." `LightSourceDefinition` — 'directional' (sun-like, azimuth/
elevation, parallel rays) or 'point' (a grow light, a fixed position —
no inverse-square falloff modeling yet, an honest stated
simplification), a broadband intensity_w_m2 magnitude, a spectrum
reference. `PotSystemDefinition` gains an optional `light_source_name`
(mirroring how it already binds atmosphere/water/soil).

**Engine** (`aquaponics/light_field.py`, new) — three independently
testable pieces:
  1. `spectrum_ppfd()` — a source's broadband W/m^2, filtered through
     its spectrum, converted to a REAL PPFD (umol/m^2/s) via PHOTON
     COUNTING (adapting photo_derive.py's exact quadrature technique
     from eV/bandgap-threshold framing to nm/PAR-band framing) — not
     an approximate energy-to-photon fudge constant. For a 5778K
     blackbody this gives a PAR energy fraction of ~36.75%, a
     physically sane number matching the well-known solar-PAR-fraction
     ballpark (computed, not looked up).
  2. `cylinder_incidence_factor()` — since plant-part bones have no
     flat face/normal today (plain tapered cylinders), incidence is
     modeled as sin(angle between the bone's own axis and the light
     direction) — the correct projected-area law for a CYLINDER
     (broadside-on intercepts the most light, edge-on almost none).
     Explicitly flagged as the thing to replace once real per-part
     shapes exist.
  3. `self_shading_factor()` — a reduced-fidelity check: every OTHER
     bone is a bounding SPHERE at its own midpoint; an occluded target
     gets `AMBIENT_SHADE_FRACTION` (0.15), never a hard 0 — a real
     shaded leaf still receives scattered light, an honest bridge to
     the future diffuse-light phase rather than an unphysical cliff.
`per_part_absorption()` combines all three against a planting's REAL,
freshly-generated skeleton (same "always live-computed" pattern as
`water_slice_mesh`) into a per-part absorbed-PPFD value. **Documented
known limitation**: self-shading only checks OTHER BONES, not soil —
a root bone underground shows a nonzero computed incidence despite
being physically shielded by opaque soil; this has NO growth effect
today because no species seeds a 'light' `StressResponseCurve` for its
'root' part (roots aren't light-sensitive in the first place), but the
raw per-bone numbers shouldn't be read as physically accurate for
buried parts. Interestingly, live data showed root bones getting a
LOW (0.15, shaded) factor anyway — an emergent, not-designed-in
coincidence: the stem's own base bones near the shared core point
happen to occlude the downward ray to most root bones.

**Wired into `advance_growth()`** (`aquaponics/plant_growth_normalized.py`):
when a bound system names a `light_source_name`, `per_part_absorption()`
runs ONCE per tick (not per-part — one skeleton walk computes every
part's absorption together), then overrides just the 'light' stress
type's input value for `plant_stress.evaluate_curve()` — a new
`light_value_override` parameter, applied ONLY to `stress_type ==
'light'` curves without an `equation_ref`, everything else completely
unchanged. Explicit `water_supply_factor`/`soil_supply_factor`
overrides still bypass this entirely (backward compatible with every
existing call).

**Demo data**: `sunlight-5778k` (blackbody) + `red-led-660nm`
(monochromatic) spectra; `demo-herb-pot-grow-light` (a point source
40cm overhead demo-herb-pot). `intensity_w_m2` (207.71) was NOT a
guess — solved from the real `spectrum_ppfd()` computation to land at
~350 PPFD, matching the healthy system's existing static
`AtmosphereDefinition.light_ppfd_umol_m2_s` so the two independent
light-modeling paths (static field vs computed field) tell a
consistent story. Bound only to `basil-aquaponic-tent` (the healthy
system) — `basil-aquaponic-sealed` deliberately left unbound, so its
planting keeps using the OLD static-field path unchanged, a real,
live A/B demonstration that the override is optional and backward
compatible, not a forced migration.

**New HTTP surface** (`aquaponics/light_field_api.py`, new):
`GET .../plantings/{name}/light-absorption` (the full per-bone +
per-part breakdown, auto-resolving the planting's own bound source or
accepting an explicit `?lightSource=` override) and
`GET .../light-spectra/{name}/ppfd?intensityWm2=<n>` (a spectrum's
real computed PPFD at a given magnitude — the "how much usable light
does this spectrum actually deliver" diagnostic).

**Same recurring gotcha, applied proactively this time**: `basil-
aquaponic-tent` already existed from an earlier phase, so its new
`light_source_name` field stayed empty after deploy — this time
checked and CRUDE-PUT immediately rather than discovered via a failed
live-verify call, applying the standing lesson
([[seed-field-addition-gotcha]] memory) instead of relearning it a
fourth time.

**Selftests**: `aquaponics/selftest_light_field.py` (new, 28/28) —
real photon-counting math (including the PAR-boundary-straddling
partial-fraction case), pure vector-geometry sanity checks (overhead
light points straight down, perpendicular-vs-parallel incidence),
self-shading (occluder between/behind/off-axis), the full pipeline
against real seed data, and `advance_growth`'s three-way behavior
(light-field-bound / static-field-fallback / manual-override-bypass).
Zero regressions across all 8 other suites touched this session
(258+ total checks).

**Live-verified against the running `prf-backend`**: both spectrum
PPFD endpoints (207.71 W/m^2 blackbody -> 349.99 PPFD, matching the
solved target within rounding; the LED spectrum's full-PAR-overlap
case); the light-absorption endpoint against the real
`demo-herb-pot-basil-1` planting showed real per-bone incidence/
shading/absorption numbers, root bones naturally low (the emergent
shading noted above); `POST .../advance` showed 'light' as the REAL
live-computed limiting stress type for leaf growth (factor 0.5028,
genuinely lower than temperature/co2's 1.0) — the full pipeline
reaching actual growth numbers, not just a diagnostic. Planting reset
to pristine state afterward.

**Not yet done, explicitly deferred per Dustin's own confirmed
sequencing**: diffuse/scattered light (would reuse
`materialsScience/engines/fem_engine.py`'s existing diffusion solver —
the RIGHT tool for that specific problem, unlike direct light);
per-part-SHAPE-specific incidence (a real leaf-blade normal for
Lambert's cosine law, replacing the cylinder-projection proxy); a
Tier-B custom equation-driven spectrum; soil occlusion for buried
parts; inverse-square falloff for point sources; a frontend light-
source editor/diagnostic view.

## Phase 9 — source-sink nutrient TRANSPORT + one-model consolidation, DONE + LIVE-VERIFIED (2026-07-15)

Dustin: *"Are there nutrient propagation mechanisms from part to part
inside the plant we may not yet be accounting for?"* Audited first
(forked, read every real growth-related file rather than trusting
memory): confirmed NO — every part's growth was fully independent
(own rate × own local stress factor × own ceiling), in BOTH growth
pipelines that existed (this session's `plant_growth_normalized.py`
AND the older aqp-8 `plant_growth.py`, which turned out to already
have a labeled-but-INERT hint of the right idea — a `PART_INTERACTIONS`
table naming "root uptake supports shoot growth" etc., computed only
as a post-hoc report, never fed back into the simulation). Dustin's
response set TWO directives at once: *"source, sink model would be
appreciated"* AND *"we should have only one model for plant growth and
it should be the more robust one which I think would be normalized
plant growth... The other plant growth model may be the 'simplified
model'... for mass evaluations at higher scales, where we are taking
constants that are based on the real growth model, and simplify them."*

**Part A — real source-sink transport, built into
`plant_growth_normalized.py`** (`transport_factor()`, new): real
plants are ONE coupled transport system — XYLEM carries water/minerals
ROOT → shoot, PHLOEM carries photosynthate LEAF → every sink tissue
(including roots, which don't photosynthesize for themselves). Modeled
as a SEED-RESERVE-FLOORED Liebig's-Law minimum of a root CAPACITY
(driven by current root SIZE only) and a leaf CAPACITY (driven by
current leaf SIZE × REAL absorbed light, phase 8's `light_field`,
distinct from the 'light' stress CURVE's 0-1 optimality read — this is
a magnitude signal, "how much sugar is actually being made"),
multiplying EVERY part's effective rate this tick — not replacing each
part's own local stress factor, a genuinely separate whole-plant
bottleneck layered on top. `SEED_RESERVE_FLOOR` (0.15) exists because
without it a fresh planting could never leave epsilon (both root and
leaf start tiny, so their capacities are both ~0) — a real seed's own
stored reserves bootstrap initial growth before root/leaf apparatus
exists, a genuine botanical fact, not an arbitrary patch. Deliberately
NOT double-counting: root capacity is SIZE-only (root's own oxygen/pH/
salinity stress is already applied separately, in the per-part loop).
Real, stated v1 simplifications: all minerals lumped into one
undifferentiated root-capacity number; water/mineral capacity has no
live soil-moisture-magnitude driver yet (the same gap phase 6b already
flagged); allocation across sink parts is UNIFORM, not priority-
ordered (real plants favor roots/leaves over fruit under scarcity) —
future work, not built here. Scoped to `stress-equations` mode only
(a bound `PotSystemDefinition`), same precedent as the light field —
manual-override and no-linkage modes are 100% unchanged.

**A real evidence-naming ambiguity found + fixed while writing the
selftest**: the first cut conflated "which capacity was smaller" with
"was the floor actually applied," so a badly-stunted part's identity
got silently replaced by a generic `'seed-reserve-floor'` label
whenever the floor engaged — losing real information. Fixed by
reporting both independently: `limitingCapacity` (which raw capacity
was smaller, always named) and `flooredBySeedReserve` (a separate
boolean).

**Part B — ONE real growth model, the old one redefined + rebuilt**
(`aquaponics/plant_growth_simplified.py`, `git mv`'d from
`plant_growth.py` to preserve history): audited EVERY real consumer
first (forked) before touching anything — 3 real backend routes
depended on it (`aquaponics/plant_growth_simplified_api.py`'s
`/grow`+`/interactions`, `mathshapes/growth_prediction.py`'s
`tower_growth_forecast` — genuinely already the exact "mass evaluation
at scale, many tower tiers" use case Dustin described — and
`nutrition/harvest_analysis.py`'s `harvest_mass_g`, which has a
concrete field-shape dependency on the return value). None had a
frontend caller (safe to reshape return fields where the new semantics
genuinely differ). The rebuilt module has NO independent growth model
of its own anymore — it pulls per-part rate/ceiling CONSTANTS straight
from `plant_growth_normalized.free_soil_constants()` and evaluates
`plant_growth_normalized.closed_form_logistic()` (promoted from a
private helper to public, since this reuse is now deliberate and
sanctioned) DIRECTLY at each requested age — mathematically EXACT
(the closed form is time-invariant/autonomous), not approximated, and
far cheaper than iterating since every age point is one independent
closed-form call, matching Dustin's own framing exactly: *"we can know
from the original model that after a certain amount of time it most
likely is fully grown, and the simplified model pulls from the
isolated single-plant model what the average constants would be at
different ages."* `supply_factor`/`supply_factor_by_part` became
simple overall 0-1 scalars (not the detailed model's per-species-flux
machinery) and a new `count` parameter scales one representative
trajectory across a POPULATION — *"if we had a whole forest of these
fully grown, what yield are we getting based on what we know about the
singular case."* The old `PART_INTERACTIONS`/`estimate_interactions()`
volume-scaled priors were KEPT (still a cheap aggregate-scale sanity
check) but their own docstring/note now explicitly says they are NOT
the real mechanism, pointing at `transport_factor()` for that.

**All 3 real consumers updated** to the new module path + new
field/param names (`supplyFactor`/`supplyFactorByPart`/`count` over
the old `supply`/`supply_by_part`; `failureSummary[].reason`, a human
string, over the old per-species `limitingSpecies`/`day` pair, since
that granularity now genuinely lives in the detailed model). A
genuine, pre-existing test-fixture gap surfaced by the consolidation
(not introduced by it): `mathshapes/selftest_shape4.py`'s manager
fixture never seeded a `PlantDefinition` row (the old model didn't
need one; `free_soil_constants()` does) — fixed by adding one
per species, each using `PlantDefinition.normalized_growth_rate_per_
day` as its fallback rate (deliberately keeping this fixture
independent of `PlantGrowthModel`/aqp-8 specifics). `tests/
test_mathshapes.py`'s `GrowthForecastTests` needed no changes (already
used real seed data with a real `PlantDefinition`).

**Selftests**: `aquaponics/selftest_plant_transport.py` (new, 15/15)
— the pure `transport_factor()` geometry/capacity math, the real
light-magnitude driver, and THE key integration proof: a stunted leaf
measurably slows STEM growth (a THIRD, unrelated part) through
`advance_growth`, with root equally affected by the SAME shared
factor — genuine whole-plant coupling, not each part still suffering
independently. One real, informative finding surfaced while writing
this test (not a bug): the real demo grow-light's computed absorption
(after incidence/self-shading losses) is low enough relative to
`REFERENCE_SATURATING_PPFD` (600) that the seed-reserve floor is
almost always the active constraint for THAT specific light source —
worth revisiting if `demo-herb-pot-grow-light`'s intensity is ever
retuned. `aquaponics/selftest_plant_growth_simplified.py` (rewritten,
19/19, was 15) — constants genuinely equal the real detailed model's
own numbers, the closed-form evaluation is bit-for-bit identical to a
hand-computed call, `count` scales exactly and `fractionOfMax` stays
population-invariant. Zero regressions across every other suite
touched this session (331+ total checks, 13 suites + the
`tests/test_mathshapes.py` unittest module).

**Live-verified against the running `prf-backend`**: `POST /api/
aquaponics/plants/sweet-basil/grow` with `count=500` returned exactly
500× a single plant's volumes; `GET /api/aquaponics/towers/demo-herb-
tower/growth-forecast` (the real tower consumer) returned a real
per-tier verdict summary; `POST .../advance` on the real demo planting
showed a real, live-computed `transport` block (`limitingCapacity:
"leaf-photosynthesis"`, `transportFactor: 0.15`) applied identically
to both root and stem's `transportFactor`. Planting reset to pristine
state afterward.

## Phase 10 — water batching + real nutrient uptake, DONE + LIVE-VERIFIED (2026-07-15)

Dustin: *"a robust frontend simulation accounting for this sort of
growth and deriving nutrients from different nutrient rich water
sources needs to be derived and accounted for. as well as the option
to have varying water source options, and batching/controlling water
flow into the pots... we simulate this at the per pot level to prepare
for the tower level where one type of water goes through the whole
system via gravity at a time and we batch different water sources to
optimize growth or purposefully stress plants in particular ways
without killing them."* Researched first (forked): confirmed real,
structured nutrient-concentration data already existed
(`NutrientProfile.concentrations_json`, mg/L, aqp-2) with TWO real
water sources already carrying genuinely different profiles
(`hydroponic-reservoir` rich, `tilapia-aquaponic-loop` deliberately
Fe-deficient — "the classic aquaponic gap," per its own seed
description) — but nothing anywhere connected that concentration data
to actual root uptake; also confirmed the frontend already has a
fully generic time-scrubber component with zero sim-specific coupling
(`sim-space-scrubber.component.ts`), directly reusable for a future
growth-over-time view without building new timeline UI. Proposed a
time-window water-batching design; Dustin corrected it: *"water
batching should be 'go until full' then leave to sit for N hours
and/or N days."* — a real fill/hold/drain cycle, which maps cleanly
onto the pot's ALREADY-established "full" convention (the input hole
height, `build_darcy_payload`'s own default) rather than needing a new
target-level field.

**Built, backend only this pass** (frontend simulation explicitly
NOT started — see "Not yet done" below):

1. **`aquaponics/water_batch.py`** (new) — `WaterBatchSchedule`: an
   ORDERED, optionally-repeating cycle of `{waterName, holdHours,
   holdDays}` batches. `active_batch()` resolves which source governs
   a pot at a given elapsed time, wrapping around on repeat or holding
   at the final batch otherwise. Deliberately schedule-name-agnostic
   (not hardcoded to one pot) so a future TOWER-level binding — one
   schedule shared across every tier, since gravity means one water
   type flows through the whole cascade at a time — can reuse this
   resolver directly rather than needing a second one; the tower class
   itself (`AquaponicTowerDefinition`) was confirmed purely geometric
   with zero water-flow hooks today, so that binding is real future
   work, not started.

2. **`aquaponics/nutrient_uptake.py`** (new) — real, concentration-
   driven root uptake: `NutrientProfile.concentrations_json` (mg/L) ×
   the pot's own real standing water volume (reusing the same formula
   `plant_morphology.morphology_analysis._pot_inner_volume_l` already
   uses for confinement math) gives an available mg per species,
   compared against `PlantPart.flux_json`'s existing `needed` mg/day
   — Liebig's Law across whatever species both datasets name. **A real
   mid-build correction**: the first version used
   `WaterDefinition.flow_rate_l_per_hr × 24` (daily throughput) as the
   available-mass basis — discovered via the selftest that this always
   saturates to 1.0 regardless of water source, because a single small
   basil root's real daily nutrient need is tiny relative to ANY
   realistic day's continuous flow volume. Switched to the pot's
   standing water volume (a STOCK, not a FLOW) — physically correct
   for "go until full, then sit," where the root draws on what's
   ALREADY in the pot, not a full day's throughput.

3. **A second, real, honestly-documented finding**: even with the
   corrected stock-based basis, sweet-basil's real aqp-4 `needed`
   values (e.g. iron-fe = 0.3 mg/day) are small enough relative to
   typical aqp-2 mg/L concentrations that BOTH real demo water sources
   currently saturate to factor 1.0 for every species — a genuine
   calibration mismatch between two independently-seeded datasets from
   EARLIER phases, not a bug in this new code. Stated plainly in
   `nutrient_availability_factor()`'s own docstring rather than hidden
   or papered over; a synthetic, realistically-scaled selftest
   scenario proves the underlying Liebig's-Law logic itself correctly
   discriminates (iron-fe correctly named as the limiting species for
   the deficient source) once given demand numbers at a comparable
   scale — future work: recalibrate `flux_json` needed values or the
   `NutrientProfile` concentration scale so real deficiencies bind for
   small pot-grown herbs specifically.

4. **Wired into `plant_growth_normalized.py`**: `PotSystemDefinition`
   gains `water_batch_schedule_name` (mirrors `light_source_name`'s
   pattern) — when bound, `advance_growth()` resolves the pot's
   elapsed time (`planted_at` to `now`, computed once and reused for
   both this resolution and the final persistence stamp) through the
   schedule, and the RESOLVED active water source feeds BOTH the
   existing water-quality stress curves (phase 7, pH/EC/DO) AND the
   new nutrient factor — the same water governs both effects, since
   physically it's the same water in the pot. The nutrient factor
   feeds `transport_factor()`'s root capacity as a THIRD input
   alongside root size (already present) — `rootNutrientFactor`, a new
   evidence field, multiplying root capacity the same way leaf
   capacity already combines size with real light magnitude (phase 8).
   No schedule bound → falls back to the static `water_name` exactly
   as before, 100% backward compatible with phases 6-9.

**Demo data**: `basil-fe-stress-cycle` (4 days rich `hydroponic-
reservoir`, 1 day deliberately Fe-deficient `tilapia-aquaponic-loop`,
repeating) — exactly "optimize growth or purposefully stress plants...
without killing them." Bound to a THIRD demo system,
`basil-water-batched` (not overloading the existing healthy/sealed
pair, which have their own distinct roles) — same pot/plant/atmosphere
/light as the healthy reference, water source cycling instead of
static. A third matching demo planting,
`demo-herb-pot-basil-batched`.

**Selftests**: `aquaponics/selftest_water_batch.py` (new, 26/26) — the
fill/hold/repeat cycle resolution (including wraparound at large
elapsed times and holding at the final batch when `repeat=False`),
real nutrient computation against real seed data (including the
honestly-asserted saturation finding), the synthetic-scale Liebig's-
Law logic proof, and `advance_growth`'s full wiring (batch-resolved
`activeWaterName`, `nutrientAvailability`, `rootNutrientFactor`
reaching the transport evidence). Zero regressions across every other
suite touched this session (353+ total checks).

**Live-verified against the running `prf-backend`**: `GET .../water-
batches/basil-fe-stress-cycle/active` at elapsedDays=0 and 4.5 showed
the correct batch switch (rich → Fe-deficient); `GET .../nutrient-
availability` on the real `demo-herb-pot-basil-batched` planting
(real elapsed time since its real `planted_at`) correctly resolved to
whichever water source the schedule says should be active RIGHT NOW;
`POST .../advance` showed `activeWaterName`, a real
`nutrientAvailability` factor, and `rootNutrientFactor` all reaching
the actual transport computation. Planting reset to pristine state
afterward.

**Not yet done, explicitly separate from this pass**: the frontend
simulation (Dustin's own first-listed ask) — reusing the confirmed-
generic `sim-space-scrubber.component.ts` to drive `advance_growth`-
equivalent state at each scrub position needs a new NON-MUTATING
"preview trajectory" function (running the real per-tick stress/
light/transport physics forward in memory without touching persisted
state — distinct from both `advance_growth`, which persists, and the
phase-9 simplified model, which deliberately skips per-tick realism)
— scoped but not built this pass, since the backend batching/nutrient
piece was substantial enough on its own. Also not built: tower-level
water propagation (the gravity-cascade, one-source-through-the-whole-
system-at-a-time mechanism) — explicitly deferred per Dustin's own
"prepare for the tower level" framing, though `active_batch()`'s
schedule-agnostic design means the resolver itself won't need
rework when that's built; a live water-LEVEL decay signal during a
batch's hold period (reusing `aquaponics.hydraulics.reservoir_model`'s
existing outflow math) — a natural, ready-to-wire extension, flagged
but not built, since the explicit ask was nutrient availability, not
yet a new water-level-driven stress type.

## Phase 11 — decomposed water-level trajectory (drainage/evaporation/transpiration), DONE + LIVE-VERIFIED (2026-07-15)

Dustin, immediately after phase 10: *"so we can see how long it takes
it to be absorbed or dissapate due to heat and atmosphere or other
factors and the plant absorbing the water obviously."* — exactly the
"ready-to-wire, not built" item phase 10's own docs had flagged.
Built it: `aquaponics/water_level.py`, a real water-LEVEL trajectory
during a batch's hold period, decomposed into THREE independently-
computed, separately-reported loss mechanisms (never one lumped
"water disappears" number):

  1. **Drainage** — reuses `aquaponics.hydraulics.reservoir_model()`/
     `build_darcy_payload()` completely unchanged, re-evaluated at
     each simulated level — the exact same gravity-through-the-output-
     hole physics the water-flow visualization (phase 3) already uses.
  2. **Evaporation** — from the standing water's own surface, driven
     by REAL vapour-pressure-deficit. Found and reused
     `aquaponics.atmosphere_analysis.saturation_vapour_pressure_kpa`
     (Tetens equation) — VPD was ALREADY computed elsewhere in this
     codebase (as a finding driver in `atmosphere_state()`), just never
     used as a rate driver before; reused directly rather than
     re-derived.
  3. **Transpiration** — "the plant absorbing the water," modeled as
     a genuine volumetric term: the SAME VPD, scaled by the plant's
     REAL current leaf surface area (`current_canopy_profile()`) and
     gated by a real light-driven stomatal-activity proxy (reusing
     phase 8's light_field absorption — stomata open in response to
     light) — ties phase 9's own "XYLEM transport" docstring language
     to an actual computed volume for the first time.

1mm of depth over 1m² of surface = 1L exactly — the standard
agronomic ET/irrigation shortcut, used throughout instead of a
separate conversion constant. `EVAPORATION_MM_PER_DAY_PER_KPA`/
`TRANSPIRATION_MM_PER_DAY_PER_KPA` are documented, approximate
empirical coefficients (real agronomic ballparks, not a full Penman-
Monteith energy-balance solve, which would need wind/radiation data
this codebase doesn't model) — stated plainly, not hidden.

**`current_water_level_fraction()`** resolves a planting's bound
batch schedule's elapsed hold time (reusing `active_batch()`'s own
`timeIntoBatchDays`) and simulates forward from a fresh "full" fill
for that long, giving "how full is the pot RIGHT NOW" as a real,
live-computed fraction. **A real logic gap found + fixed while
testing**: the first version always ran a (near-instant) trajectory
even when no batch schedule was bound, instead of short-circuiting to
the honest neutral default — meaning an unbatched planting got a
technically-real-but-pointless ~1.0 read instead of a clean "not
modeled here" `None`. Fixed to check `schedule_name` first.

**Wired into `transport_factor()`** as a FOURTH input to root
capacity (`water_level_factor`), alongside size, nutrient factor
(phase 10), all multiplied together — a root sitting in a nearly-
empty pot has less to draw from regardless of that water's nutrient
concentration or the root's own size, a genuinely separate axis.
Scoped to only compute when a `water_batch_schedule_name` is actually
bound (same precedent as light/nutrient) — no schedule means no water-
level computation at all, not just a hidden 1.0.

**New HTTP surface**: `GET .../plantings/{name}/water-level?hours=&
sampleHours=` — the full decomposed trajectory, exactly what Dustin
asked to "see."

**Selftests**: `aquaponics/selftest_water_level.py` (new, 21/21) —
real decomposed physics against real demo-herb-pot geometry (level
decreases, drainage/evaporation/transpiration all named + non-
negative, a fresh seedling's transpiration is proportionally tiny
since it has almost no leaf area yet — proving the plant-absorption
term genuinely depends on real leaf area rather than a fixed
constant), a long-horizon empties the pot with `timeToEmptyHours`
honestly reported, the real logic-gap fix, and `advance_growth`'s
full wiring (`rootWaterLevelFactor` reaching the transport evidence,
manual/no-schedule modes unaffected). Zero regressions across every
other suite touched this session (374+ total checks).

**Live-verified against the running `prf-backend`**: `GET .../water-
level` on the real batched planting returned a real trajectory
(200mm → 188mm over 24h, drainage 205.74mL / evaporation 113.71mL /
transpiration 0.19mL — drainage dominant for this self-watering pot,
exactly as physically expected); `POST .../advance` showed
`rootWaterLevelFactor: 0.9465` — a real, live-computed value reaching
the actual transport computation, not just a diagnostic. Planting
reset to pristine state afterward.

**Not yet done**: tower-level water-level propagation (still explicitly
deferred, same as phase 10); the frontend simulation (still the same
scoped-but-not-built item from phase 10 — a non-mutating preview-
trajectory function feeding the existing generic scrubber); a full
Penman-Monteith energy-balance evaporation model (would need wind-
speed/radiation data not modeled anywhere in this codebase today).

## Phase 12 — a second full-parity species (dwarf-pepper), DONE + LIVE-VERIFIED (2026-07-15)

Dustin: *"do we have full growth and growth rate under optimum
conditions and equations for animation bones defined for all of our
plants we have currently?"* Audited every real seed file directly
(not memory) before answering: THREE species existed at the
morphology layer (`RootSystemModel`, morph-1 era) — sweet-basil,
dwarf-pepper, everbearing-strawberry — but `PlantDefinition`/
`PlantPart` (aqp-4) and `PlantGrowthModel` (aqp-8), the rows
`free_soil_constants()` actually requires, existed ONLY for sweet-
basil. `free_soil_constants('dwarf-pepper')` refused immediately. A
second, independent gap: `OrganModel` was missing a stem/branch axis
organ for BOTH other species — `generate_skeleton()`'s canopy walk
needs one to build any above-ground bones at all, so even with growth
data neither would ever produce a canopy. Answer: **only sweet-basil
had the full pipeline.** Dustin: *"let's try to have at least two
robust variants that we can compare against each other."*

**Brought dwarf-pepper to full parity** (chosen over everbearing-
strawberry — it already had richer morphology data: 2 organs
including fruit, a distinct taproot pattern, a distinct confinement
tolerance, needing the least genuinely-new invented data for the
richest comparison):

- **`aquaponics/plant_seed.py`** — a real `PlantDefinition`
  (perennial, `normalized_growth_rate_per_day=0.03`, deliberately
  SLOWER than basil's 0.045 — a woodier perennial vs a fast annual
  herb, not a rescaled copy) + 4 `PlantPart` rows (root/stem/leaf +
  **fruit**, the first species in this codebase to actually use that
  `PLANT_PARTS` entry). Volumes scaled from the REAL RootSystemModel
  geometry ratio vs basil (depth x spread², ~3.4x). Fates
  DELIBERATELY differ, not just numbers: pepper's root/stem are
  `standing-permanent` (a perennial's structure persists) vs basil's
  `soil-incorporated`/`harvested` (an annual's doesn't) — a real,
  meaningful contrast, not cosmetic.
- **`aquaponics/plant_growth_seed.py`** — 4 matching `PlantGrowthModel`
  rows, `max_volume_cm3` mirroring each `PlantPart` exactly (basil's
  own convention), growth rates slower across every part.
- **`plant_morphology/morphology_seed.py`** — the missing
  `dwarf-pepper-stem-organ` (closes the animation-bones gap directly).
- **`aquaponics/pot_system_seed.py`** — `dwarf-pepper-tent`, bound to
  the SAME pot/soil/water/atmosphere/light as `basil-aquaponic-tent`
  — isolating the species variable for a genuine apples-to-apples
  comparison, not a confound of also-different conditions.
- **`aquaponics/plant_growth_normalized_seed.py`** —
  `demo-herb-pot-pepper-1`, same `planted_at` as basil's reference
  planting, for a fair same-starting-point comparison.

**A second, deeper gap found while writing the comparison selftest**:
dwarf-pepper had ZERO `StressResponseCurve` rows — `combined_stress_
factor()` found nothing to evaluate and silently returned a PERFECT
1.0 every tick, an unfair advantage that would have made pepper look
artificially more robust than basil for the wrong reason (no stress
modeling, not real resilience). Fixed by adding pepper's own 8 curves
(`aquaponics/plant_stress_seed.py`) — bounds shifted warmer + higher-
light than basil's own (a real Capsicum/fruiting-plant preference),
not a rescaled copy. Once both species had real, comparable stress
modeling, the growth-rate comparison flipped to the physically correct
result (basil genuinely faster).

**Selftests**: `aquaponics/selftest_plant_species_comparison.py` (new,
14/14) — `free_soil_constants` resolves for pepper where it refused
before; a real, non-contrived contrast in root volume/rate/confinement
tolerance/prune-cadence between the two species; `generate_skeleton`
produces a real canopy for pepper (not just roots) with a genuinely
different root-branching SHAPE (taproot vs fibrous); `advance_growth`
under IDENTICAL conditions shows basil measurably outpacing pepper —
a real growth-rate comparison, not a labeled diagnostic. One real test
-logic fix found along the way: a fresh seedling genuinely has zero
fruit yet (`currentCount` rounds to 0 at `GROWTH_SEED_EPSILON`) — not
a bug, real biology, matching pepper's own `growth_stages_json` not
calling its 'fruiting' stage until day 120; the fruit-bone check now
runs after a realistically longer horizon. Zero regressions across
every other suite touched this session (388+ total checks).

**Live-verified against the running `prf-backend`**: `GET .../plants/
dwarf-pepper/free-soil-constants` returns real `partRefs` for all 4
parts (previously would have 404'd); `GET .../constrained-limits`
shows a real lower ceiling + a real 365-day root-prune cadence (basil
names none); `GET .../plantings/demo-herb-pot-pepper-1/skeleton`
returns a real 132-bone graph with BOTH root and stem/canopy parts
present, taproot pattern; `POST .../advance` on both real plantings
under identical conditions showed basil (0.02532) growing measurably
faster than pepper (0.02141) over the same 20 days — the actual
comparison this whole phase was built to enable. Both plantings reset
to pristine state afterward.

**Not yet done**: everbearing-strawberry is still incomplete (only
has a leaf `OrganModel`, no `PlantDefinition`/`PlantPart`/
`PlantGrowthModel`/stem organ either) — a natural third species to
complete later if a broader comparison set is wanted, using the exact
same recipe this phase just established.

## Phase 13 — real per-organ shapes + root-tip tessellation, DONE +
LIVE-VERIFIED (2026-07-15)

Dustin, verbatim: "Have we properly defined the leaves for these
plants as math shapes? Also what are the cones at the bottom of the
roots? They look abnormal and out of place, there may be a legitimate
reason for them but it is not clear." A third request in the same
message (two alternate plant views — a technical/hoverable one and a
realistic one) was explicitly SCOPED OUT of this phase and left for a
follow-up (see Related below) — the leaf-shape gap and the root-cone
artifact were the concrete, immediately-fixable half of the ask, and
both turned out to share one root cause.

**The gap**: every `OrganModel` row already carries a real
`shape_primitive` field (`lamina`/`ellipsoid`/`cone`/`cylinder` —
sweet-basil-leaf='lamina', dwarf-pepper-leaf='ellipsoid',
dwarf-pepper-fruit='cone') and `current_canopy_profile` (phase 6) was
already computing it per organ — but `plant_skeleton.py`'s
`_attach_organs` discarded it, so EVERY organ rendered as the same
generic tapered cylinder regardless of what it actually was. The
"cones at the bottom of the roots" are real root-tip bones (correctly
tapered, correctly `cylinder`) rendered with only 6 radial segments
(`RADIAL_SEGMENTS` in `PlantSkeletonGeometryLibraryService`) — a
steeply-tapered short hexagonal cylinder visually reads as a literal
geometric cone rather than an organic root tip.

**Fix — backend** (`aquaponics/plant_skeleton.py`): `_BoneBuilder.add`
gained a `shape_primitive` parameter (default `'cylinder'` — root/
stem/branch AXIS bones always pass this explicitly, a real physical
taper); `_attach_organs` now reads the organ's own real
`organ.get('shapePrimitive', 'ellipsoid')` instead of discarding it.
One field threaded through, no new computation.

**Fix — frontend** (`PlantSkeletonGeometryLibraryService`):
`buildBoneGeometry` now dispatches on `bone.shapePrimitive` — lamina
-> a real flat `BoxGeometry` blade (width x length x thin constant
thickness), ellipsoid -> a `SphereGeometry` stretched non-uniformly
into an ellipsoid, cone -> `ConeGeometry` (apex at the bone's tip,
base at its attachment point), cylinder (unchanged) -> the existing
tapered `CylinderGeometry` path. `RADIAL_SEGMENTS` bumped 6 -> 10 so
root-tip cylinders read as organic tapers, not geometric cones — the
real taper DATA is untouched, only tessellation smoothness changed.

**New selftest assertions** (`selftest_plant_species_comparison.py`,
now 18/18): stem axis bones are explicitly `'cylinder'`; a matured
pepper's fruit bones are explicitly `'cone'`; pepper's leaf bones are
explicitly `'ellipsoid'`; basil's leaf bones are explicitly
`'lamina'` — a genuinely different real shape from pepper's leaves,
proving the fix isn't a coincidence of shared defaults. Full
regression sweep (388+ checks across every touched suite) still
100% passing, zero regressions.

**Live-verified against the running `prf-backend`**: `GET .../
plantings/demo-herb-pot-pepper-1/skeleton` returns leaf bones as
`ellipsoid`, root/stem as `cylinder`; the SAME endpoint for
`demo-herb-pot-basil-1` returns leaf bones as `lamina` — a real,
observable difference between the two species' actual API responses,
not just internal state. Advancing pepper 200 days and re-fetching
the skeleton shows fruit bones as `cone`. Planting reset to pristine
state via CRUDE PUT afterward (found the CRUDE route is bare
`/PotPlanting`, keyed by the internal `id`, not `/api/aquaponics/...`
— looked this up via `?filter_name=` since the polariId is NOT the
seed row's own `name` field). All 4 `{planting}-plant-viz` SimSpace
scenes re-derived (`POST /api/shapes/from-pot/demo-herb-pot`) so the
live scenes reflect the new geometry.

**Deploy detour, worth recording**: the frontend rebuild
(`polari-rf-node/rebuild-staging.sh frontend`) repeatedly failed/
hung — root-caused to TWO real, unrelated bugs found along the way,
both now fixed (see [[disk-space-audit]] for the full writeup):
(1) `polari-platform-angular/.dockerignore` didn't exclude `.angular`
(Angular's own incremental-build cache, found at 5.9GB and growing),
so every build shipped gigabytes of irrelevant cache into the docker
build context — fixed by excluding `.angular`/`dist`/`coverage`;
(2) `rebuild-staging.sh` targets `polari-rf-node/docker-compose.
staging-nip.yml`, a DIFFERENT, non-live compose stack from the one
actually running the suite (`/home/user/Desktop/polari-suite/
docker-compose.staging-nip.yml`, service names `prf-frontend`/
`prf-backend`) — a real frontend container swap needs the suite-level
compose file directly, not the rf-node script. Backend hot-fixes
(`docker cp` + `docker restart`) were unaffected since they bypass
compose entirely. Disk pressure (83% -> 54%, 20G -> 52G free) cleared
as a side effect of the .dockerignore fix + a scoped prune.

## Related

The technical/hoverable-vector-view vs realistic-plant-view split
Dustin also asked for in the same message is a genuinely separate,
larger piece of work (per-bone pickability needs the skeleton mesh
restructured from one merged geometry into individually-hoverable
sub-meshes, plus a tooltip UI) — explicitly NOT built this phase,
flagged as the next natural step. The existing hover/click/pick
infrastructure in `three-renderer.service.ts` (`onHoverChange`/
`onClick`/`mesh.userData['polariSimSpaceId']`) is confirmed already
generic enough to support it without new plumbing.

Unfinished from the PRIOR session, deliberately shelved (not part of
this thread): WebXR pointer/HUD fixes + EQUATIONS/LEGEND/NO-CODE
panels + direct-entry route + 2D-as-HTMLMesh — see
[[webxr-plan]] memory, branch `dev-xr-3-min-ng`, all uncommitted,
awaiting Dustin's next headset session (unrelated to this pot work,
just also mid-flight).

## Phase 14 — root geometry hard-clamped to the real pot interior, DONE + LIVE-VERIFIED (2026-07-16)

Dustin, looking at the phase-13 screenshots: "the growth seems strange
and they look like they are growing according to an 'ideal conditions
with infinite ground' scenario, rather than a real constrained pot
scenario... those seem to be straight down 'tap roots' at the
bottom." Confirmed with real numbers before touching any code (not
guessed): sweet-basil's `constrained_limits` returned
`normalizedGrowthCeiling` (dwarfFactor) = **1.0** — "not confined at
all" — even though its free-soil root spread radius (120mm) is
LARGER than the pot's own physical inner radius (~92mm). Dwarf-pepper
scored 0.865 (some dwarfing) but its constrained root depth (259.5mm)
STILL exceeded the pot's real usable depth (220mm = 40mm reservoir +
180mm soil).

**Root cause, two distinct bugs**: (1) `confinement_assessment`'s
dwarf factor is a BIOLOGICAL estimate (dense root-BALL material
volume vs container volume — "will this become root-bound") — a
valid question, but NOT the same question as "does the root's actual
SPATIAL ENVELOPE fit the container," so a sparse, wide-spreading free
-soil root system can score as fully unconfined by that metric while
its rendered spread/depth is far larger than the physical pot. This
metric was left AS-IS (it's answering a real, different, legitimate
question about root-bound survival, not wrong on its own terms).
(2) The skeleton's seed/core origin was the pot's ABSOLUTE floor
(`-height_mm/2`, which doesn't even account for `base_thickness_mm`
— literally placing the origin inside the solid base slab), so canopy
had to visually tunnel through the ENTIRE water+soil column before
"emerging" above ground, and root had nowhere further down to go
without exiting the container through the bottom.

**Fix** (`aquaponics/plant_skeleton.py`): replaced `_pot_core_point_cm`
with `_pot_planting_geometry_mm`, which places the origin at the SOIL
SURFACE (interior floor + reservoir_height_mm + soil_fill_height_mm,
using the real `wall_bottom_z` from `_pot_core_dimensions` — the
already-existing shared pot-geometry helper, not a new computation)
and returns `maxRootDepthMm`/`maxRootRadiusMm` as HARD geometric
ceilings, independent of whatever the growth/dwarf math wants.
`_walk_root` gained a new `_clip_length_to_container` check (solves
for where a bone's path crosses the pot's inner radius — a quadratic
in the travel parameter — or its floor — a straight z check) applied
to EVERY bone before it's added; a bone that gets clipped stops
recursing (real roots deflect at a wall, they don't punch through
solid material and keep branching). `generate_skeleton` also clamps
the OVERALL root-depth budget passed into the walk, and reports
`rootDepthClampedToContainer` honestly (never a silent clamp) plus
the real `maxRootDepthMm`/`maxRootRadiusMm` used.

Canopy was deliberately left UNCLAMPED horizontally — real above-
ground foliage genuinely does spread wider than its own pot; that
part of the original shape was correct, not a bug, and Dustin's own
message flagged it as "maybe it is correct" rather than as a
complaint.

**New assertions** (`selftest_plant_species_comparison.py`, now
24/24, was 18/18): `_pot_planting_geometry_mm`'s numbers match the
pot's real dimensions exactly (220mm depth, not a guess); EVERY root
bone endpoint for BOTH species stays within the pot's real physical
radius/floor, including basil specifically DESPITE its dwarfFactor=
1.0 "unconfined" biological score — proving the geometric clamp is
independent of and stronger than that metric; the seed origin is
now measurably above the floor (at the soil surface). Full regression
sweep (410+ checks across every touched suite) still 100% passing,
zero regressions.

**Live-verified against the running `prf-backend`**: real demo
plantings now show `coreOriginMm` z=107mm (the real soil surface, was
-125mm/the absolute floor before this fix) and root bones whose
minimum z lands EXACTLY at the pot's real interior floor (-113mm,
also corrected from the old -125mm which ignored `base_thickness_mm`)
— a bone that reaches the boundary stops there rather than continuing
through solid material. Both `{planting}-plant-viz` scenes
re-derived.

**Side effect, worth noting**: moving the origin to the soil surface
also resolves the earlier phase-13 observation that some leaf organs
were attaching below ground (inside the water/soil column) — the
canopy's generation-0 bone now starts exactly at ground level instead
of at the pot's old, incorrect sub-floor origin, so there's no more
below-ground canopy segment for organs to attach to in the first
place.

**Not built this phase**: a per-part (rather than whole-plant)
confinement response — `constrained_limits`'s own docstring already
flags this as future work, unrelated to today's geometric fix.

## Phase 14b — taproot lateral branching + chain-reach length budgeting, DONE + LIVE-VERIFIED (2026-07-16)

Dustin, immediately after seeing phase 14's containment fix: "for the
peppers, is the behavior of only a single root straight down really
accurate?" Confirmed via direct code + data inspection (not assumed):
`ROOT_PATTERN_KNOBS['taproot']['children']` was hardcoded to `1`, and
`_walk_root`'s "reduce children by 1 sometimes" mechanic bottoms out
at `max(1, 1-1)=1` — meaning a taproot pattern was STRUCTURALLY
incapable of ever branching, by construction, regardless of
randomness. Real pepper roots do put out lateral roots off the
primary taproot as they mature — a permanently-unbranched single line
understates real root architecture.

**A second, deeper interaction found while fixing it**: even after
adding lateral-branch support, dwarf-pepper's live skeleton STILL
showed only 1 bone. Root-caused: phase 14's depth clamp feeds the
FULL depth budget into generation 0 as ONE bone; every later
generation (primary continuation AND any new lateral) starts from
THAT bone's tip, already sitting exactly at the container floor, so
its own length immediately clips to 0 and vanishes. This was a LATENT
issue in the whole recursive length model (every pattern's total
reach was always somewhat larger than any one generation's stated
length, via chained tip-to-tip extension) that only became visible
once a hard floor made "gen-0 alone reaching the boundary" a real,
common case for taproot's single-chain shape specifically. Basil's
fibrous pattern wasn't affected (children=3 at every generation means
plenty of branches exist well before any one of them individually
hits a boundary) — confirmed by NOT touching fibrous/spreading/
rhizomatous at all, avoiding any regression risk to the already-
approved basil look.

**Fix** (`aquaponics/plant_skeleton.py`): (1) `ROOT_PATTERN_KNOBS
['taproot']` gained `lateralChance`/`lateralLengthFrac`/
`lateralAngleDeg`/`lateralDownwardBias` — `_walk_root` now spawns a
real, thinner, more-horizontal side root at a per-generation
probability (0.55), independent of and in addition to the primary
tap's own `children` continuation; the lateral recurses through the
SAME `_walk_root`, so it can spawn its own finer sub-laterals too,
same as a real root system. (2) new `_chain_reach_factor` (geometric
series in `lengthFrac`, same technique `_estimate_axis_bone_count`
already used for canopy organ counts) — for single-chain patterns
only (`children==1`), generation-0's own length is now the total
depth budget DIVIDED by the chain's reach factor, so the WHOLE
chain's cumulative reach (not gen-0 alone) lands on the real budget,
leaving genuine room for the primary continuation and laterals to
exist before hitting the floor.

**Live-verified**: pepper's real demo planting (advanced well past
its own confinement ceiling) now shows 13 root bones with 4 real
branch points (was 1 bone, 0 branches) — still fully within the
pot's real physical bounds (phase 14's containment guarantee holds
simultaneously with the new branching). New assertions
(`selftest_plant_species_comparison.py`, now 26/26, was 24/24) prove
a real branch point exists on a well-grown pepper taproot AND that
the branched system stays within container bounds. Full regression
sweep still 100% passing, zero regressions. Scene re-derived.
