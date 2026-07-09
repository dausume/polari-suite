# Math-Defined Shapes + CAD Import + Tower Growth — Plan

**Written 2026-07-09 as a durable, GPT-4-executable handoff.** Dustin
wants a dedicated capability for **math-defined shapes** — surfaces and
volumes defined by MATRIX EQUATIONS — to replace the ad-hoc geometry
that makes 3D shapes "look weird" in simulations, then build on it
toward CAD import and predictive growth in an aquaponic tower.

Do the phases in order, one at a time, branch per phase
(`dev-shape-1-mathshapes`, …), selftest green before moving on. This
plan is self-contained; each phase is written so a fresh GPT-4-class
agent can execute it without re-deriving the codebase.

Order (Dustin's framing):
1. **shape-1 — math-defined shapes core** (the foundation: quadric
   matrix surfaces, primitives, CSG, properties, clean surface sampling).
2. **shape-2 — algorithmic/parametric modification** (change hole
   radius/height/count on a self-watering pot; the aquaponic TOWER).
3. **shape-3 — CAD / FreeCAD import** (import parametric CAD files as
   Polari 3D objects with pulled properties — on a worker).
4. **shape-4 — predictive root/plant growth in the tower** (couple the
   geometry to morph-1 root confinement + aqp-8 growth over time).

---

## 0. What already exists (reuse, don't rebuild)

- **aqp-1 pot geometry** (`aquaponics/pot_basis.py` PotDefinition +
  PotHole; `pot_geometry.py` validate_pot / generate_holes). The pot +
  holes are ALREADY parametric — shape-2 turns this into a math-defined
  shape so the holes can be modified algorithmically and rendered
  cleanly. The self-watering-pot invariant (gravity drainage) lives here.
- **morph-1 morphology** (`plant_morphology/organ_basis.py` OrganModel +
  RootSystemModel; `morphology_analysis.py` organ_geometry / root_spread
  / confinement_assessment). shape-4's growth prediction couples the
  tower's math-shape inner volume to `confinement_assessment` (can the
  root ball fit / be dwarfed indefinitely) and to aqp-8 `plant_growth.
  grow` (per-part logistic growth).
- **SimSpace3D + Mesh3DDefinition + Material3DDefinition** (the 3D render
  layer, `defClassList` in polariServer). shape-1's surface sampler
  should emit a Mesh3DDefinition (or its point/triangle data) so a
  math-shape RENDERS — this is the concrete fix for "shapes look weird".
- **Matrix / equation no-code infra**: MatrixDefinition,
  MatrixEquationDefinition, EquationDefinition, and the
  MatrixEquationOperation no-code node (see
  [[matrix-equation-operation-node]]). A quadric is a 4×4 matrix Q; a
  math-shape's definition SHOULD be expressible as a MatrixDefinition so
  it flows through the existing no-code editor (object-coherence).
- **Module conventions** (identical to every recent module — aquaponics/
  nutrition/ biomining/ etc.): classes are `treeObject`s with
  `@treeObjectInit`, typed kwargs, `manager=None` last; analysis files
  duck-typed manager (stdlib-only selftests); API classes register
  falcon routes; `SEED_*` idempotent-by-name; wire into polariServer
  (imports ~L158–200, defClassList ~L730, API instantiation ~L636,
  seed_pairs ~L1620–1700). Standing principles: object-coherence,
  knobs-and-suggestions, honest-absence, labels-travel-with-numbers,
  file-size-decomposition. Deploy: `export LOCAL_IP=192.168.0.210` then
  `docker compose -f docker-compose.staging-nip.yml up -d --build
  prf-backend`; cold seed takes minutes; selftests in-container.
- **numpy IS in the backend image** (skfem/Darcy run in-backend). Keep
  the ANALYSIS stdlib-only (`math`) so selftests run without numpy, but
  numpy may be used in a live-only helper (e.g. general quadric
  eigen-classification) guarded like the FEM `capability()` ladder.

New module home: `polari-rf-node/polari-framework/mathshapes/`.

---

## PHASE shape-1 — Math-defined shapes core (do first)

### Goal
A shape defined by mathematics — a **matrix equation** for surfaces/
volumes — that can be evaluated (inside/outside, surface points),
measured (volume, area, bbox, centroid), classified, and rendered
cleanly. This is the foundation the other phases build on.

### Objects (`mathshapes/shape_basis.py`)
- **MathShapeDefinition** (treeObject):
  - `name`, `display_name`, `family` — one of:
    - `quadric` — a surface/solid from a symmetric 4×4 matrix Q:
      `[x y z 1]·Q·[x y z 1]ᵀ = 0` is the surface, `< 0` the solid.
      Covers sphere, ellipsoid, cylinder, cone, paraboloid,
      hyperboloid — ALL the standard quadrics, matrix-defined. Store as
      `quadric_matrix_json` (16 numbers, row-major, symmetric).
    - `primitive` — `primitive_kind` (box / sphere / cylinder / cone /
      frustum / ellipsoid) + `parameters_json` (radius/height/size/
      radii/base_radius/top_radius, an `axis` x|y|z, a `center`). These
      have ANALYTIC volume + surface area + inside-test.
    - `csg` — `csg_json` `{op: union|difference|intersection, shapes:
      [MathShapeDefinition names]}`. A pot-with-holes = frustum
      DIFFERENCE hole-cylinders.
  - `parameters_json` — the named tunable knobs (the shape-2 seam).
  - `bounds_json` — the AABB `[[xmin,xmax],[ymin,ymax],[zmin,zmax]]`
    used to grid-sample volume for unbounded quadrics + CSG.
  - `notes`, `provenance_id`.

### Analysis (`mathshapes/shape_analysis.py`, duck-typed, stdlib `math`)
- `evaluate_point(manager, shape_name, x, y, z)` → `{inside: bool,
  value}` — the implicit value (Q form for quadric; signed inside-test
  for primitives; boolean-combined for CSG). Recurses for CSG.
- `quadric_classify(Q)` → the surface TYPE from the diagonal quadratic
  form's sign pattern (sphere/ellipsoid/cylinder/cone/elliptic-
  paraboloid/hyperboloid). Stdlib for axis-aligned (diagonal) Q; a
  live-only numpy eigen path for general Q (honest "diagonal-only"
  refusal when numpy absent, per the capability ladder).
- `shape_properties(manager, shape_name, resolution=32)` → `{volumeCm3,
  surfaceAreaCm2, boundingBox, centroid, method}` — ANALYTIC for
  primitives (sphere 4/3πr³, cylinder πr²h, frustum πh/3·(R²+Rr+r²),
  ellipsoid 4/3πabc, box), GRID-SAMPLED (deterministic N³ lattice over
  bounds, count-inside × cell volume) for quadric + CSG. `method` names
  which was used (labels travel).
- `sample_surface(manager, shape_name, n)` → a list of surface points
  (+ optionally triangles) for RENDERING — the clean-geometry fix. For
  quadrics/primitives, sample the parametric surface analytically; for
  CSG, march the grid for zero-crossings (a light marching-cubes-lite).
  Emit into a **Mesh3DDefinition** so SimSpace3D renders it.
- `csg_volume` / inside for CSG via the deterministic lattice.

### Seed (`mathshapes/shape_seed.py`)
- `unit-sphere` (quadric Q = diag(1,1,1,−1)), `demo-ellipsoid`
  (quadric), `demo-cylinder` (primitive), a `frustum-pot` (primitive
  frustum), a `hole-cylinder` (primitive, radial axis), and a CSG
  `pot-with-holes` = frustum DIFFERENCE two hole-cylinders — the seed
  that shape-2 modifies.

### API (`mathshapes/shape_api.py`)
`GET /api/shapes` (catalogue), `GET /api/shapes/{name}/properties`,
`POST /api/shapes/{name}/evaluate` `{x,y,z}`, `GET /api/shapes/{name}/
surface?n=` (mesh points), `GET /api/shapes/{name}/classify` (quadric
type).

### Acceptance
`selftest_shapes.py`: quadric classify returns sphere for
diag(1,1,1,−1) and ellipsoid/cylinder/cone for their Q; analytic volumes
match formulas (sphere 4/3πr³ within tol; cylinder πr²h); grid-sampled
sphere volume converges to analytic within a few % at resolution 40; CSG
difference (pot minus holes) has LESS volume than the pot alone;
inside/outside correct for known points; honest refusals. Green + live:
`/properties` returns volume, `/surface` returns points, `/classify`
names the quadric.

---

## PHASE shape-2 — Algorithmic / parametric modification (do second)

### Goal (Dustin's concrete example)
Modify a math shape via ALGORITHM to fit a specialized need —
"changing the height and radius of holes in a pot for a self-watering
pot in an aquaponic TOWER" — and keep it valid.

### What to add
1. `modify_parameter(manager, shape_name, param, value)` in
   shape_analysis — set a named `parameters_json` knob (hole radius,
   hole height, hole count, pot base/top radius, height), re-derive the
   CSG/primitive, recompute properties, and return before/after.
   Knobs-and-suggestions: never auto-apply beyond the requested change;
   surface the geometric consequence (new inner volume, drainage lip).
2. **Bridge from aqp-1**: `pot_shape_from_definition(manager, pot_name)`
   builds a `MathShapeDefinition` (frustum − N hole-cylinders) FROM an
   aqp-1 PotDefinition + its PotHoles, so the existing parametric pot
   becomes math-defined + renderable, and the aqp-1 gravity invariant
   (validate_pot) still gates the modification (a hole change that
   breaks drainage is REFUSED with the reason — reuse pot_geometry).
3. **AquaponicTowerDefinition** (treeObject): a vertical stack of pots
   (N tiers, spacing, shared reservoir) as a CSG/instanced math shape —
   the "aquaponic tower" context. Properties: total grow volume per
   tier, footprint, water path.
4. API: `POST /api/shapes/{name}/modify` `{param, value}`;
   `GET /api/aquaponics/towers/{name}/geometry` (the tower as shapes).

### Acceptance
Modifying hole radius up REDUCES pot solid volume and INCREASES the
opening; a modification that violates the gravity invariant is refused
naming the knob; the tower geometry sums tier volumes; selftest green;
live modify round-trips.

---

## PHASE shape-3 — CAD / FreeCAD import (do third)

### Goal
Import FreeCAD (and STEP/STL) parametric CAD files as Polari 3D objects
with pulled properties, so external designs flow into the object tree.
FreeCAD already uses parametric file definitions — a good model to mirror.

### Feasibility + where it runs (IMPORTANT)
FreeCAD's python (`FreeCAD`/`Part`, built on OpenCASCADE) is a LARGE C++
system dependency — NOT cleanly pip-installable into the Alpine backend.
Mirror the msci-engines pattern: run the CAD importer on a **Debian
worker** (like pyscf/skfem) and reach it over an HTTP seam
(`materialsScience/engines/remote.py` idiom). Lighter fallbacks that DO
pip into a worker: `trimesh` (STL/OBJ/GLTF + volume/bbox), `cadquery` /
`pythonocc-core` (STEP), `numpy-stl`. Recommended: a `cad-import` worker
service exposing `POST /cad/import` (bytes → `{volume, bbox, centroid,
meshPoints, parametricParams}`), with FreeCAD optional (build-arg like
QE) and trimesh as the always-available baseline.

### What to add
1. Worker service `cad-import/` (new, Debian) or extend msci-engines:
   `/cad/import` (STEP/STL/FCStd → geometry + properties + any exposed
   parameters), `/cad/capability`.
2. `mathshapes/cad_import.py` (backend side): posts the file to the
   worker via the remote seam; maps the result into a
   **Mesh3DDefinition** (rendered) + a `MathShapeDefinition`
   (family=`imported-mesh`, properties cached) + an `ImportedCadObject`
   row holding source metadata + pulled parametric params (so FreeCAD's
   parametric definitions become Polari knobs where exposed).
   Honest-absence when no worker/lib is reachable.
3. API: `POST /api/shapes/import` (upload → shape rows), `GET
   /api/shapes/cad-capability`.

### Acceptance
An uploaded STL yields a shape with volume + bbox + a rendered mesh;
capability is honest when the worker/lib is absent; a FreeCAD FCStd with
exposed parameters surfaces those as knobs. Selftest mocks the worker
response (stdlib) + asserts the mapping + the honest refusal shape.

---

## PHASE shape-4 — Predictive root/plant growth in the tower (do last)

### Goal (Dustin)
Predictive modelling of the growth of roots and plants in the tower —
using the math-shape geometry as the CONSTRAINT.

### What to add (couples shape-2 tower + morph-1 + aqp-8)
1. `mathshapes/growth_prediction.py` (duck-typed): given an
   AquaponicTowerDefinition (per-tier pot grow VOLUME from shape-2) + a
   plant (aqp-4/aqp-8) + its RootSystemModel (morph-1), predict over a
   timeline:
   - per-tier root-ball volume vs the pot's math-shape inner volume →
     time-to-root-bound (reuse morph-1 `confinement_assessment`);
   - per-part plant volume via aqp-8 `plant_growth.grow`, CAPPED by the
     geometric volume the tier provides (the shape is the carrying
     capacity);
   - the dwarfing / root-prune schedule to keep each tier producing
     indefinitely (morph-1 knobs);
   - a per-tier "fits / needs pruning / will fail" verdict, limiting
     factor named.
2. API: `GET /api/aquaponics/towers/{name}/growth-forecast?days=`.

### Acceptance
A well-sized tier predicts healthy growth to maturity; an under-sized
tier predicts root-bound + a prune cadence (or failure) with the tier +
factor named; bigger holes / bigger pot (shape-2 modify) shift the
forecast; selftest green.

---

## Cross-phase notes
- **The "weird shapes" fix** is shape-1's clean math definitions +
  `sample_surface` → Mesh3DDefinition: sims render exact quadric/CSG
  geometry instead of hand-built meshes.
- **Object-coherence**: a math shape's Q SHOULD be a MatrixDefinition so
  it flows through the no-code matrix-equation editor; every geometric
  capability is a configurable row.
- **Everything ties back**: shape-2 makes the aqp-1 pot math-defined +
  modifiable; shape-4 makes the tower a predictive growth constraint
  using morph-1 + aqp-8 — closing the loop from geometry to biology.
- **CAD** rides a worker (heavy C++ deps), NOT the Alpine backend —
  trimesh baseline, FreeCAD/pythonOCC optional build-args.
- Deploy discipline + branch-per-phase + local commits (nothing pushed;
  repos PUBLIC) as with every module. Update a `math-shapes` memory
  entry as each phase lands.
