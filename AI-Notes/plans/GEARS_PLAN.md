# GEARS — motor-actuated gear trains as data, sim, and geometry

**Dustin 2026-07-30:** "plan out an approach of putting together
gears that are being actuated by motors as both 3D and more abstract
simulations accounting for varying types of gears so we can start
combining the motor logic with gear logic."

Status: **PLANNING**. Nothing built yet. Read this before starting
gr-1. Companion plans: `MAGNETIC_MATERIALS_PLAN.md` (the motor ladder
this docks onto), `MATH_SHAPES_PLAN.md` (the geometry seam),
`AQUAPONICS_POT_SHAPE_PLAN.md` (the precedent for
row → geometry → 3D scene → castable part).

---

## 0. The thesis, in one line

A gear train is **a graph of rotating bodies whose edges impose a
speed ratio and a torque ratio**, and every gear TYPE is a different
set of numbers on that edge plus a different geometry generator. So:
one abstract simulation over the graph, one 3D view over the same
rows, and a materials/manufacturing gate deciding which of those
rows a person can actually make in a garage.

This mirrors what the magnetics arc already proved: rows →
GraphCompiler → solver → honest refusals, with a separate geometry
layer that renders the SAME rows the mold casts. Gears are the
mechanical twin of the reluctance network — and the analogy is real,
not decorative:

| magnetics | gears |
|---|---|
| MMF source (coil) | torque source (motor shaft) |
| reluctance element | mesh (ratio + loss) |
| flux node (KCL) | shaft node (common speed) |
| flux conservation | power conservation (minus losses) |
| saturation FLAGGED | tooth-stress / backlash FLAGGED |

The motor already answers "torque at this angle, at this current."
The gear train answers "what does that torque become at the output,
how fast, how efficiently, and does the tooth survive?"

## 1. What must be true (the honesty spine)

These are non-negotiable and every phase carries them:

1. **Quasi-static first, dynamics named as absent.** v1 computes
   steady-state ratios, torques, and efficiencies. Inertia, angular
   acceleration, resonance, shock loads: OUT, and the report says so.
   The motor's `torque_curve` is already a PARTIAL-derivative,
   held-current quantity; chaining it through a gear ratio does not
   make it dynamic.
2. **Efficiency priors are PRIORS.** Published per-mesh efficiency
   bands (spur ~0.96–0.99, worm ~0.30–0.90 depending on lead angle)
   are literature ranges, flagged as such, replaced only by measured
   runs — same ladder as `MotorVerificationRun`.
3. **Tooth strength is a SCREEN, not a certification.** Lewis-form
   bending stress and a contact-stress estimate flag a design as
   *plausible* or *over-stressed*; they never certify. Our cast
   geopolymer/ceramic gears have no measured S-N data, so the report
   must say "estimated from a literature modulus, unverified for
   THIS material" every time.
4. **Manufacturability gates the rung, exactly like the motor
   ladder.** A gear you cannot mold, print, or cut is a simulation
   toy. Every gear type carries how it would be MADE in our stack
   (wax-printed mold → cast; directly printed; cut) and the tolerance
   tier (T0 cast / T1 lapped / T2 fired / T3 machined) it demands.
   Involute profile accuracy is a T-tier claim, not a given.
5. **Backlash is a first-class number, not an afterthought.** Cast
   parts at T0 have large, uneven backlash. For a clock (M0) that is
   *the* accuracy story; for a reduction drive it is lost motion. It
   gets a column, a prior, and a measured-value slot.
6. **No gear ratio invents torque.** Power in = power out + losses.
   Any report showing output torque must show the speed it was
   bought at, on the same line.

## 2. The gear-type taxonomy (the "varying types" ask, as data)

`GearTypeDefinition` rows — knobs, not code branches. Each carries
its ratio law, its axis relationship, its efficiency prior band, its
thrust behavior, its geometry generator key, and its
manufacturability note.

| type | axes | ratio law | efficiency prior | why we'd use it | make-in-our-stack |
|---|---|---|---|---|---|
| **spur** | parallel | N₂/N₁ | 0.96–0.99 | the default; simplest to cast | easiest — flat 2.5D, wax-moldable, T0 viable |
| **helical** | parallel | N₂/N₁ | 0.94–0.98 | quieter, higher load share | castable but needs a twisted mold pull; axial thrust appears |
| **internal (ring)** | parallel | N₂/N₁, same direction | 0.96–0.99 | compact, the planetary prerequisite | moldable; inner teeth are the hard cavity |
| **planetary set** | coaxial | depends on which member is fixed (see §2b) | 0.95–0.98/stage | high ratio in a small coaxial envelope; load shared over planets | the flagship hard case: needs a carrier + 3 planets at matched tolerance |
| **bevel (straight)** | intersecting 90° | N₂/N₁ | 0.93–0.97 | turn the axis | conical mold, harder pull |
| **worm + wheel** | skew 90° | N_wheel/starts | **0.30–0.90** (lead-angle dependent) | huge single-stage reduction; can be self-locking | worm is a screw — the hardest to cast, the easiest to buy |
| **rack + pinion** | rotary→linear | v = ω·r_pitch | 0.90–0.98 | rotation to linear travel | flat rack casts well; the BLCNC/actuator seam |
| **cycloidal drive** | eccentric | (N_pins − N_lobes)/N_lobes | 0.85–0.95 | very high ratio, high shock tolerance | interesting for cast materials: rolling contact, no involute teeth |

**§2b — the planetary ratio table is itself data**, not a formula in
code: (sun fixed / carrier out), (ring fixed / carrier out = 1 +
N_ring/N_sun), (carrier fixed = −N_ring/N_sun), etc. Rows, so a user
can see WHY a configuration gives its ratio.

**§2c — self-locking is a derived predicate, not a checkbox.** A worm
is self-locking when tan(lead angle) < friction coefficient; the
friction coefficient is a material pair property with an honest
unknown for cast composites. So the answer is
`self_locking: unassessed` with the named ask, not `false`.

## 3. Architecture — where it lives

**New module `modules/gears/`** (requires `mathshapes` for geometry;
OPTIONALLY couples to `motors`). Rationale, following the
magnetics/motors split Dustin already chose: gears are a general
mechanical capability (they'll serve BLCNC, the printer, tower
actuators, aquaponics valves), not a motor sub-feature. Motors
*consume* gears.

```
modules/gears/
  gear_basis.py      GearTypeDefinition, GearDefinition,
                     GearMeshDefinition, ShaftNodeDefinition,
                     GearTrainDefinition, GearVerificationRun
  gear_kinematics.py the abstract solve (ratios, speeds, torques,
                     efficiency chain, direction, backlash stack)
  gear_strength.py   Lewis bending + contact-stress SCREEN, module/
                     pitch sizing, honest material-data refusals
  gear_geometry.py   involute/cycloidal profile generation ->
                     MathShapeDefinition rows (the mold seam)
  gear_motor.py      THE SPLICE: motor torque_curve x train ->
                     output torque/speed envelope, duty check
  gear_api.py        /api/gears/*
  gear_seed.py       the type taxonomy + the sample trains
  selftest_gears.py
```

**Why a graph, not a list:** a real drivetrain branches (one motor,
two outputs; a differential; a planetary carrier). The same
`GraphCompiler` seam the magnetic netlist uses applies — shaft nodes
are the graph nodes, meshes are the edges. Reuse the seam; do not
invent a second one.

## 4. The two simulations, and how they share rows

### 4a. Abstract (the "more abstract simulation")

Input: a `GearTrainDefinition` + an input torque/speed (from a motor
row, or a bare number for teaching).

Output, per shaft node:
- angular speed (rad/s and RPM), **with direction sign** — direction
  reversal per external mesh is a classic silent bug, so it is
  asserted in the selftests
- torque, **after** cumulative efficiency
- cumulative ratio from the input
- power in / power lost per mesh / power out, summing to input
  (a conservation check that is itself a selftest)
- backlash accumulated to that node (prior or measured)
- per-mesh flags: over-stressed, undercut risk (tooth count below
  the minimum for the pressure angle), speed limit, self-lock
  unassessed

This is cheap, closed-form, and instant — it is the layer people
actually iterate designs in.

### 4b. 3D (the "3D simulation")

Same rows, rendered: each gear becomes a `MathShapeDefinition`
generated from its parameters (tooth count, module, pressure angle,
face width, profile family), placed at its true center distance,
and **rotated by the solver's own ratios** so the mesh visibly turns
at the right relative speed and direction — the same
"animation-driven-by-the-solver" discipline as the M0 clock replay,
never a canned tween.

Two honesty notes to carry on-page:
- the animation shows **kinematics**, not stress or dynamics;
- meshing is rendered as ideal (teeth do not deform, contact is not
  simulated) — this is a *visualization of the ratio*, and a
  correctly-phased one, not a contact solver.

Reuse: the freshly-generalized `SimSpaceRendererFactory` guarantees
asset libraries (materials/meshes) are loaded, and the mag-7 field
view proved the single-persistent-renderer pattern. A
`GearTrainDefinition` gets a `SimSpaceDefinition` scene row exactly
like `motor-m0-viz`.

**Tooth geometry is the interesting part.** An involute profile is a
parametric curve, and `mathshapes` already does parametric surfaces
and CSG (including the coaxial-tube special case added for the motor
coil). Approach: generate the tooth flank as an involute polyline,
sweep it to face width, array it N times around the axis, union with
the root cylinder. Cycloidal and rack variants are different
generators over the same seam. **Gate:** if the profile generator
cannot yet make a given type, the row REFUSES with the named gap and
the abstract sim still runs — sim is never blocked on geometry.

## 5. The motor splice (`gear_motor.py`) — the actual point

Given a `MotorDesignDefinition` and a `GearTrainDefinition`:

1. Take the motor's torque curve (M1–M3) or step torque (M0).
2. Apply the train: output speed = motor speed / ratio, output
   torque = motor torque × ratio × η_cumulative.
3. Report the **envelope**, not a single number: torque available at
   the output across the motor's usable speed range, with the
   ferrite-vs-NdFeB watermark from `torque_parity` traveling through
   unchanged.
4. **The honest headline this will produce:** our cast ferrite motors
   are LOW torque. Gearing is exactly how a feeble-but-cheap motor
   becomes a useful actuator — and the report must show the cost:
   the speed given up, the efficiency lost, the backlash added. That
   trade IS the deliverable.
5. Duty check: flag when required output torque exceeds what the
   motor + train can deliver, naming which side is the binding
   constraint (motor MMF, tooth stress, or self-lock).

Concrete first target: **M0's clock train.** A Lavet stepper drives a
real gear reduction to the hands — 1 pulse/second → the second hand,
then 1:60 → minute, 1:12 → hour. That is a REAL, hand-checkable,
buildable gear train whose correctness is verifiable against a clock,
exactly the same verification-by-time-progression trick that made M0
the control case. If our gear math is wrong, the clock is visibly
wrong. **That is gr-5 and it is the acceptance test for the whole
arc.**

## 6. Materials + manufacturability (gates, not decoration)

Every `GearDefinition` names a material by REFERENCE into the
existing catalogs (msci materials / magnetics options / supply-chain
items), so cost cascades and realization levels travel exactly as
they do for motor parts:

- **cast geopolymer** — cheap, brittle, T0 tolerance, big backlash;
  fine for slow high-ratio reduction, wrong for precision.
- **printed wax → cast** — the mold path already built (mold-1).
- **printed polymer (PLA/PETG)** — the honest comparator most makers
  will actually use; cite it.
- **machined metal** — the T3 benchmark; priced for honesty like
  NdFeB is in magnetics (reference-only until we have the tooling).
- **wood/plywood laser-cut** — the classic accessible gear; a real
  rung, and BLCNC-adjacent.

Bill of materials per train (per-gear volume × density × $/kg from
the cascade) reusing `layout_cost`'s shape — plus bearings and shafts
from the mag-1 cited rows (608 bearings, 8 mm shaft are already
cited).

## 7. Phases

- **gr-1 — basis + taxonomy.** The six row classes, the type
  taxonomy seeded with ratio laws/efficiency priors/manufacturing
  notes, and the abstract kinematic solve over a graph (speeds,
  directions, torques, efficiency chain, power conservation). Seed:
  a 2-stage spur reduction with hand-computed numbers pinned in the
  selftest. **Deliverable: `/api/gears/{types,trains,solve}`.**
- **gr-2 — strength + sizing screen.** Lewis bending, contact
  estimate, undercut check, module/pitch sizing helper; honest
  refusal when the material has no modulus/strength row. Flags ride
  the solve output.
- **gr-3 — geometry generator.** Involute spur first (the 80%
  case) → `MathShapeDefinition` rows; center distance derived;
  rack + internal next; cycloidal and bevel named as gaps until
  built. Selftest: generated pitch radius and tooth count match the
  row; a known module/tooth pair reproduces a hand-computed pitch
  diameter.
- **gr-4 — the 3D scene + page.** `SimSpaceDefinition` per train,
  `/mechanics/gears` page: pick a train, see it turn at solver
  ratios, read the per-shaft table, see flags in red. Reuses the
  mag-7 renderer patterns wholesale.
- **gr-5 — THE MOTOR SPLICE + the clock train.** `gear_motor.py`,
  the M0 clock reduction as the acceptance case verified against
  time, the output-envelope report, the duty check. Cross-link from
  `/magnetics/motor`.
- **gr-6 — planetary + worm.** The two high-ratio types that matter
  for real actuators, including the planetary ratio table as data
  and the self-locking predicate with its honest `unassessed`.
- **gr-7 — business/tech-tree splice.** Gear sets as bizops product
  variants (gated by realization exactly like the magnetic goods),
  a QA check row (backlash measurement + tooth-count/pitch
  dimensional check), tech-tree node under mechanical systems.

Phases 1–3 are backend-only and independently testable; 4 is the
first thing a person can look at; 5 is the payoff.

## 8. Explicitly OUT of v1 (named so nobody trips)

Gear dynamics (inertia, acceleration, resonance), tooth contact FEA,
lubrication regimes and film thickness, wear/lifetime prediction,
noise/vibration, thermal effects, profile shift/corrected gears
(named — it's how you fix undercut, and it's a v2), helical thrust
BEARING selection, harmonic/strain-wave drives, differentials
(the graph supports them; the seeds won't cover them yet).

## 9. Selftest discipline (per phase, non-negotiable)

Hand-computed pinned numbers (a 2-stage 3:1 × 4:1 = 12:1 with
torque and efficiency worked by hand); direction alternation per
external mesh asserted explicitly; power conservation asserted to
floating-point tolerance; refusal paths (missing material data,
unknown gear type, impossible tooth count, geometry generator not
yet built for a type); the live-boot probe extended with
`/api/gears/*`; and the clock train checked against elapsed time the
way `clock_sim` already is.
