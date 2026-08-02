# Matrix-Shape Coherence — every real shape IS its equations, via no-code

> **Dustin 2026-08-01**: "make sure all shapes are defined using
> matrix equations if possible, that way we can make correlations
> between their equations later for overall relations between parts
> in the engine. We need to be able to see the exact shape of all
> real objects if feasible, and have it rendered so we can verify
> visually what is being put into the simulations. The calculations
> should be using the real material (or those derived from material
> science simulation) properties to perform and tune their part
> roles." — and: "if possible do this via no code."
>
> Trigger observation (same session): the M1 rotor rendered as
> "four cubes, not an actual rotor" — the drawn shape did not read
> as the one-pour salient casting the composition splice declares.
>
> Status: PLAN. Nothing below is built unless marked EXISTS.

## 0. What EXISTS (reuse, do not rebuild)

| Piece | Where | State |
|---|---|---|
| quadric family: pᵀQp = 0, 4×4 Q | mathshapes/shape_basis (shape-1) | EXISTS — the true matrix-equation shape form; classify/value/properties/mesh wired; only ~2 seed shapes use it |
| primitive + csg families | shape_basis / shape_geometry | EXISTS — every MOTOR shape is built from these (boxes/cylinders/differences), no equations exposed |
| THE PRECEDENT: winding as a MatrixEquationDefinition spec, parity-pinned | mathshapes/winding_geometry (ws-1) | EXISTS — "the drawn object IS the equation"; emits expr + bindings; selftest pins drawing == equation |
| MatrixEquationDefinition / MatrixDefinition / EquationDefinition + executor + no-code node | matrices/, nocode (P1-P5, 69/69 both engines) | EXISTS — operands may reference OTHER equations: correlations are graph edges |
| exact parametric meshes vs voxel fallback | shape_geometry (tube_mesh etc.) | EXISTS for coaxial-cylinder csg; sector/wedge solids fall back to marching grid |
| material-property-driven engines | motors/* (_prop reads MagneticMaterialOption), part_report (mass from shape×density), stress/fatigue (mechanical props), role viability | LARGELY EXISTS — audit for stragglers is mq-4 |
| M1 shape rows (the four-cubes rotor) | motor_shapes SEED_M1_PART_SHAPES (mag-12) | EXISTS — box poles on a hub; faithful areas/gaps in notes, NOT in equations |

## 1. The idea, stated once

A shape is COHERENT when the thing rendered, the thing simulated,
and the thing correlated are ONE object: a set of matrix equations
(quadric matrices; planes are degenerate quadrics) combined by CSG,
stored as NO-CODE ROWS the editor can read, evaluate and relate.
The winding proved the pattern at one part; this arc applies it to
every real part, starting where it was just caught lying visually
(the M1 rotor).

Correlations between parts then need no new machinery: an
inter-part relation (an air gap, a bore fit, a window vs winding
OD, the overlap(θ) a solver assumes) is a MatrixEquationDefinition
whose operands REFERENCE the two parts' shape matrices — evaluated
by the existing executor, visible in the existing editor.

## 2. Phases (one file per concern, fixture selftests, upsert seeds)

### mq-1 — the shape→equation bridge (mathshapes/shape_equations.py)
For every MathShapeDefinition, EMIT its defining matrices as
no-code rows: per bounding surface a 4×4 MatrixDefinition (quadric
Q; planes as degenerate Q) + one MatrixEquationDefinition in the
pᵀQp form; csg shapes emit the boolean over their children's
equation refs. Shape rows gain `equation_refs_json` (upsert
delivers). PARITY PIN (the winding rule, generalized): sampled
surface points of the drawn mesh evaluate to ≈0 in the emitted
equations — the drawn object IS the equation, suite-enforced.
Refusal-honest: a shape family with no equation form (imported CAD
mesh) says so instead of pretending.

### mq-2 — M1 re-shaped as the REAL objects (motors/motor_shapes M1 rows)
Replace box-approximations with quadric-CSG of the true geometry:
- rotor = ONE casting: core cylinder ∪ four SECTOR poles (cylinder
  ∩ two half-plane quadrics), arc tips at r=12.0 facing the gap —
  renders as the salient clover the mold pours (ifm1-poles-core
  made visible), not four cubes;
- teeth with ARC faces at r=12.6 (the 0.6 mm gap is between two
  cylinder quadrics now, not a box face and a box corner);
- yoke annulus + coil annuli unchanged in form, gaining equations.
Exact meshes (extend the parametric mesher to sector solids — no
voxel fallback on a real part). TWO-MODULES-AGREE: tooth face area
from the equations == design row tooth_area_m2; pole-tip radius,
tooth-face radius and gap_base_m are ONE fact stated by two rows.

### mq-3 — correlations as no-code rows (motors/m1_relations.py)
Inter-part relations as seeded MatrixEquationDefinition rows over
the mq-1/2 matrices, evaluated live by the existing executor:
- ifm1-working-gap: g = r_tooth_face − r_pole_tip (== the solver's
  gap_base_m — three statements, one fact, guarded);
- ifm1-coil-clearance: coil bore vs pole swing radius;
- shaft/bore fit; slot window vs winding OD (the mag-9 check,
  restated at the equation level);
- overlap(θ): pole-arc ∩ tooth-arc as a function of rotor angle —
  the geometric quantity the m1-1 solver's first-harmonic model
  APPROXIMATES, now derivable exactly (and the difference between
  exact overlap and the first harmonic becomes a NAMED model gap
  with a number on it).
Markers/scene read positions from these relations instead of
seeded approximations (retires that honesty note).

### mq-4 — the materials audit (motors + mathshapes sweep)
Every number an engine uses is traced to (a) a material row value
(measured or materials-science-derived, provenance attached), (b)
a design row parameter, or (c) a NAMED prior with its retirement
measurement. Sweep the motor engines for stragglers (core-path
0.03 m prior, densities, moduli); part-role tuning reads live
properties only. The audit output is itself a payload (an
accountability report per engine), not a code comment.

### mq-5 — M0/v2 shapes join (same treatment, lower urgency)
The lavet v2 scene bodies gain equations via mq-1 automatically
where primitive/csg; any box-approximation worth re-shaping gets
it after M1 proves the pattern.

## 3. Honesty ledger

- A mesh-family shape (CAD import) has NO equation form — carried
  as a named absence, never faked.
- The first-harmonic overlap in m1_sequencing stays the SOLVER's
  model; mq-3 quantifies its distance from the exact geometric
  overlap rather than silently replacing it (model changes are
  deliberate, not side effects).
- Marker positions stop being approximations only when mq-3 lands;
  until then the existing note stands.

## 4. Order and gate

mq-1 → mq-2 are the spine; mq-3 needs both; mq-4 can interleave;
mq-5 last. Gate: the M1 rotor renders as the one-pour salient
casting; every M1 body's equations exist as no-code rows with the
parity pin green; at least the working-gap and window correlations
evaluate live through the matrix executor; the materials audit
report answers for the m1 engines.
