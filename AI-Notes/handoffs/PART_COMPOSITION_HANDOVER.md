# Part composition, promotion, and characteristic equations

**Handover to Fable 5 — 2026-07-31.**
Written at the end of the mag-1..25 + wire-1 arc. Fable 5 is building
the new data structures; this document is the *context and observed
behaviour* those structures have to accommodate. It is deliberately
not a schema — where it names a shape, it names one that something
in this session already broke without.

Everything cited here was built, deployed and live-verified on
`dev-mag-a-magnetic-materials` (framework `8999a77`, rf-node
`04a01aa`, suite `f7e6985`; **not pushed**).

---

## 1. The four levels, and the operation between them

Dustin's decomposition, restated so the boundaries are testable:

| Level | Definition | Test that distinguishes it | Example |
|---|---|---|---|
| **Part component** | a single-material element | it has ONE material row and no internal interfaces | the copper wire; the spool core |
| **Part** | components processed into one whole serving a purpose, *tunable toward* that purpose | it has a purpose you can optimise against, and internal interfaces that are **not** designed to be separated | the stator; the rotor |
| **Sub-assembly / assembly** | parts held together | members are **separable**, and the interfaces are designed | the movement; the movement + train + hands |

The distinguishing question at every boundary is **separability**, not
size or complexity. A stator is a part because you are not meant to
get the wire back off it. A movement is an assembly because you are.

### 1.1 The promotion operation — the load-bearing idea

An assembly can be **processed into a part**, irreversibly:

- screw two parts together, then melt the screw so it cannot come apart;
- **sol-gel over an already-spooled winding**, so the stator becomes one
  solid body with no internal movement.

This is not a relabelling. Promotion changes which equations apply:

```
BEFORE promotion (assembly)      AFTER promotion (part)
  interface friction               —  gone
  fretting / turn-to-turn wear     —  gone
  fastener preload + loosening     —  gone
  thermal expansion mismatch       →  becomes internal STRESS
  per-member failure               →  bulk failure of a composite
  repairable / disassemblable      →  NOT repairable
```

**Promotion trades interface failure modes for bulk failure modes, and
spends repairability to do it.** Both sides of that trade must be
representable, because both showed up in this session:

- the sol-gel case is a *real* candidate for our stator (mag-24) and its
  blocker is exactly the bulk mode it introduces: the film is **brittle**,
  and a crack in a potted winding is a short. We recorded that as the
  thing to test, not to assume.
- the repairability loss is a **lifecycle-cost** term. `lifecycle_cost.py`
  already prices per lifespan-unit; a promoted part cannot be repaired,
  so its whole cost amortises over one life instead of several.

**Requirement:** promotion must be a first-class, recorded *operation*
with (a) the process that performs it, (b) the DOF it removes, (c) the
failure modes it deletes, (d) the failure modes it introduces, (e) the
reversibility it destroys. A promoted part that does not name what it
gave up is indistinguishable from an assembly that was drawn badly.

---

## 1.2 Worked example — three stator constructions (mag-26)

Dustin's variant family, built and live-verified
(`modules/motors/stator_construction.py`,
`/api/motors/stator-variants`). Same functional part, three points on
separability — **not** a difficulty ranking:

| Construction | Level | Promoted interfaces | Separable | Repairable | Steps |
|---|---|---|---|---|---|
| **Simple** — enamelled wire on a spool | assembly | none | wire from spool | yes | 1 |
| **Bound** — wound, then sol-gel over | **part (promoted)** | wire-to-wire, wire-to-spool | none | **no** | 3 |
| **Layered bound** — grooved layers, bound per layer, snapped concentrically | **part with separable sub-parts** | wire-to-groove *within each layer* | layer from layer | no | 4 |

### This settles open question §5.2 — promotion IS partial

The layered variant is internally promoted **per layer** (wire fused
into sol-gel, irreversible) while the layers themselves **snap apart**.
One object, two separability regimes. So:

> **Promotion attaches to a NAMED INTERFACE SET, never to a whole
> assembly.**

### What each promotion buys and spends

Binding **deletes** turn-to-turn fretting and crossover abrasion
outright — not reduces them, and a clock runs 3.2e8 cycles. It also
makes the coil *structural*, so the bobbin flanges no longer carry the
winding alone and can be thinner, giving back some of the window the
coating cost. It **spends** repairability (whole cost now amortises
over one life) and swaps interface failure for a bulk one: sol-gel
silica is brittle, and a crack in a potted winding is a short.

### The finding that came out of modelling it

Layering is *for* fill factor — grooves force ordered packing, and fill
multiplies turns directly (`turns = f·W/A_wound`). But groove **walls
consume window**, and that is the mag-24 square-law again:

> **Grooving beats scramble winding only while the wall stays under
> ~14% of the WOUND wire diameter** — derived, not asserted. At 32 AWG
> that is a 33 µm wall; at a realistic 50 µm the grooved winding is
> *worse* than scramble (0.527 vs 0.600).

And a second, sharper result about the snap-on geometry specifically:

> **A layer that snaps on is a rigid floor, and rigid floors forbid
> nesting.** Nested layers settle into the valleys below (radial pitch
> 0.866·d, ceiling 0.907); layers on a rigid floor sit squarely (pitch
> d, ceiling 0.785) *before any wall is charged*. The snap-on
> construction therefore forfeits ~13% of the fill an ordered winding
> would otherwise reach — most of the benefit it was adopted for.

**So choose snap-on layering for per-layer INSPECTABILITY and yield —
a defective layer is discarded instead of a whole coil — not for
packing.** If packing is the goal, offset the grooves and let layers
nest instead of snapping.

### An unresolved conflict, recorded rather than glossed

A snap fit needs **elastic deflection** to engage. Fired ceramic and
geopolymer are **brittle** — they crack instead of flexing. This
conflicts directly with the field-inert ceramic the spool otherwise
wants, and nothing in this session resolves it. Either the snap
features need a tougher material than the body (a two-material part),
or the layers need a different retention scheme.

### Requirements this adds to the model

1. A construction variant is a **first-class alternative** of one
   functional part, not a different part.
2. Fill factor is a **property of the construction**, not of the wire —
   scramble, ordered-on-rigid-floor, and ordered-nested are three
   different numbers from the same components.
3. Retention features (snap, groove) carry their own **material
   requirements**, which may conflict with the body's. A part may need
   more than one material for reasons that are not electrical.
4. Process step **count** is a cost axis: 1 → 3 → 4 here, per layer.

---

## 2. Characteristic equations, by level

The point of levelling the equations is **tuning**: at each level a
small number of knobs move a small number of outcomes, and the useful
structure is *which variables cancel*. Cancellation is what makes two
knobs independent, and independence is what makes tuning tractable.

All 16 equations below already exist as `EquationDefinition` rows
evaluated through `polariNoCode.equation_executor` (sympy/LaTeX) —
see `modules/motors/physics_equations.py` (mag-20). They are
configuration, not code, and Fable 5 should extend that table rather
than start a new one.

### 2.1 Part-component level (one material)

Knobs: material choice, dimension.

| Quantity | Equation | Note |
|---|---|---|
| design strength | `S·(−ln P)^(1/m)` | Weibull derate — brittle parts fail from the **worst flaw**, so the mean is never the design number |
| life at stress | `(S/σ)^n` | subcritical crack growth; the exponent is why small margin changes move life by orders |
| wear volume | `k·F·s/H` | Archard — `k` spans six orders, so evaluate a **band**, never a value |
| wound wire area | `π((d + build)/2)²` | **build enters as a SQUARE** — see §3.4 |

### 2.2 Part level (components processed into a whole)

Knobs: geometry, turns, winding window, material assignment.

| Quantity | Equation | **What cancels** |
|---|---|---|
| coil voltage | `MMF·ρ·MTL / A_copper` | **TURNS CANCEL.** Gauge alone sets voltage. |
| turns in a window | `f·W / A_wound` | — |
| inductance (circuit) | `N²/ℛ` | — |
| inductance (field) | `2W/i²` | from FEM stored energy |
| time constant | `L/R` | — |
| current rise | `(V/R)(1 − e^(−tR/L))` | — |
| tooth load | `T/r` | — |
| contact pressure | `√(F·E/(π·R))` | Hertz line contact |

The voltage cancellation is the single most useful result of the whole
arc (§3.2). It is a *part-level* characteristic equation, and it is what
separates "how it is driven" from "how long it runs".

### 2.3 Assembly level (parts held together)

Knobs: stage ratios, part selection, duty.

| Quantity | Equation / relation | Note |
|---|---|---|
| train ratio | product of stage ratios | `gear_kinematics.solve_train` |
| planetary ratio | `1 + R/S` (ring fixed), `−R/S` (carrier fixed) | sign is the design point |
| step condition | `coil_amp / detent_amp` above threshold | **a RATIO — see §3.1** |
| average current | `I · pulse · rate` | duty |
| battery life | `capacity / I_avg` | charge, not energy |
| hand imbalance | `m·g·r` | sets the largest drivable face |

### 2.4 Product level

Knobs: everything above, plus lifespan unit.

- **true price** = cost per sensible lifespan unit (`lifecycle_cost.py`),
  not instantaneous cost. Upfront cost answers a *different* question
  (low budget, urgency) and both are kept.
- **shippability** = every composed check passing, with blockers named
  (`clock_product.product_datasheet`).

### 2.5 The tuning structure Fable 5 should preserve

For the M0 the levers factor cleanly, and this is the shape worth
generalising:

```
GAUGE   -> voltage        (can a cell drive it?)
TURNS   -> battery life   (charge per pulse is MMF·t/N)
WINDOW  -> turns          (at a given gauge)
```

Three knobs, three outcomes, no cross-terms. **A characteristic
equation set is well-formed when you can state it like that.** When you
cannot, the cross-coupling is the thing to surface — because that is
exactly where optimising one objective silently moves another (§3.2).

---

## 3. Observed behaviours — the part Dustin flagged as critical

These are things this session actually hit. Each one is a constraint on
the new data structures, not an anecdote.

### 3.1 A stronger magnet makes the motor WORSE

Upgrading the rotor from bonded (0.12 T) to sintered hexaferrite
(0.39 T) *degraded* the drive: coil/detent fell 4.81 → 3.42, so it
needed **more** current, not less. In a Lavet motor the magnet that
makes the torque also makes the detent you must overcome.

**Why it generalises:** performance was a **ratio of two terms driven by
the same parameter**. Any structure that stores "B_r ↑ ⇒ torque ↑" as a
monotone improvement will get this class of case wrong. Characteristic
equations must be able to express *both* terms a parameter feeds.

### 3.2 Optimising the wrong objective silently moves requirements

mag-22 optimised power, landed on 15,000 turns of 46 AWG, and thereby
dragged the project into ultrafine drawing, diamond dies and an HPHT
press. Nothing announced this. Only when the objective was corrected to
*manufacturability* did it emerge that 46 AWG needs **4.14 V against a
cell's 1.5 V** — the design had been silently carrying a step-up
converter whose quiescent draw was never in the budget.

**Requirement:** a design must declare the **capability rung** it
assumes, not only its numbers. `simple_first.py` does this (`W1/W2/W3`
from `techtree.wire_ladder`). Optimisation output should be
inadmissible without it.

### 3.3 Models have regime boundaries, and they do not degrade gracefully

FEM vs the lumped reluctance network agree to a constant **1.41** once
µ_r ≥ 200, and diverge by **4.6×** at µ ≈ 2. A core that barely beats
air does not *confine* flux — it crosses the window directly, and a
reluctance network has no branch for that. The model does not get
noisier; **it stops applying** (`motors/inductance.py model_validity`).

This matters because **our locally producible materials are exactly the
low-µ ones.**

**Requirement:** validity regime must be **data on the model**, with the
measurement that would adjudicate it. Ours: one LCR reading on a wound
core.

### 3.4 Geometry–property coupling is often a square law

Insulation build adds to *diameter*, so its effect on the window goes as
the square. At 46 AWG (0.0399 mm bare) even commercial 0.025 mm enamel
makes the wound area **2.6× the copper area**; cotton covering at
0.075 mm needs **3.1× the window**. Cotton — the most locally available
fibre there is — is ruled out by arithmetic, not preference.

**Requirement:** a part component's *coating/covering* is a distinct
attribute from its material, with its own thickness, because it changes
the geometry a level up.

### 3.5 Predicates are of two kinds, and confusing them is a real bug

`field-inert` checked permeability but not remanence. When mag-23 gave
sintered hexaferrite its recoil permeability (µ_rec ≈ 1.1, correct), the
material sailed through and the route search proposed **a permanent
magnet as the field-inert pinion**.

The fix was a new predicate mode:

- **requirement** (`min`/`max`) — the material must *prove* it complies;
  a missing property is **unassessed**, never a pass.
- **disqualifier** (`max-if-stated`) — a stated value over the limit
  rejects, but *absence does not*. A structural ceramic states no
  remanence because it is not a magnet, and silence is not evidence of
  guilt.

**Requirement:** every predicate must declare which kind it is.

### 3.6 Continuous physics needs graded predicates, not binary ones

`flux-carrying` demanded µ_r ≥ 100, which declared *no locally
producible stator possible* — false, since the M0 demonstrably steps at
µ ≈ 2.2. Regraded as functional-from-1.5 / good-from-100, reporting the
penalty (≈40× the current) rather than a verdict.

**Requirement:** thresholds over continuous quantities carry a
*functional* floor and a *good* target, and report degree.

### 3.7 Circular dependencies are usually ordering problems

Three real loops surfaced: kiln→thermocouple→wire→die→press;
CVD→tungsten filament→drawing→die; PCD→graded grit→fine sieve→fine
wire→PCD. **All three break**, on pyrometric cones, on choosing HPHT,
and on sedimentation grading respectively — and the first break was
already how our own ceramics rung was specified.

**Requirement:** a dependency cycle must be storable **with its break**.
A loop with a documented entry point is an ordering constraint; only a
loop without one is a blocker.

### 3.8 Industrial specifications are economic, not physical

"In-line annealing", "chilled coolant", "die life 10–30×" are throughput
features that keep a *production line* running fast and unattended. We
need **210 m of wire, once**. Batch annealing and a reservoir with
thermal mass are sufficient.

**Requirement:** a process requirement should record *what it is for*
(rate / yield / tolerance / physics) so it can be re-derived against our
actual volume instead of inherited wholesale.

### 3.9 Evidence level is per-property, and promotion needs a named act

The realization ladder — theoretical → literature-demonstrated →
recipe-seeded → made-and-measured — is carried **per property**, with
provenance, not per material. The mag-22 route depends on exactly one
promotion (sinter the recipe-seeded SrFe12O19 powder), and it is stored
as a **named experiment with the measurement that earns it**, never as a
relabelled row.

**Requirement:** reachable ≠ achieved, and the difference is a specific
act somebody has to perform.

### 3.10 Two failure modes I introduced, both worth designing against

- **A silent identity masquerading as a cross-check.** I computed `a·f`
  and called it flux linkage, but for a linear system `a·K·a ≡ a·f`, so
  it re-derived the energy answer. If two "independent" routes agree
  suspiciously well, verify they are not the same identity.
- **A uniform mesh silently shorted a 0.8 mm gap** — elements straddling
  it took the *core* permeability from their centroid and inductance came
  back 150× high with nothing looking wrong. Fixed **structurally**
  (align the mesh to region boundaries) rather than by detection, which
  made it both correct at any refinement and cheaper.

Generalisation: **prefer making a failure impossible over detecting it.**

### 3.11 The gotcha that has now bitten ten times

Polari's seeding only INSERTS by name; it never diffs an existing row
against the current seed. Adding a property, changing a value, or
flipping a default **does not reach live rows**. Same shape as a Python
default argument binding at definition time — which also bit this
session, in `winding_report`, where patching a module global changed
nothing and every insulation candidate silently returned the same figure.

**Requirement for the new structures:** if composition rows will be
seeded, design the **upsert-changed-fields** path now. The
CRUDE-PUT-after-deploy workaround has held ten times and should not have
to hold an eleventh. Payload shape, which is not obvious:
`PUT /<ClassName>` with `--form-string 'polariId=<id>'` and
`--form-string 'updateData={"field": "value"}'` — no `/api` prefix.

---

## 4. What already exists — reuse, do not rebuild

| Concern | Where | Note |
|---|---|---|
| role vocabulary | `motors/part_roles.py` | 10 roles over 5 domains (mechanical / magnetic / electrical / thermal / intersectional), with `checks`, `graded`, `requires_evidence` |
| material screening by role | `part_roles.screen_candidates` | **use this for "relevant materials by tag"** — the roles *are* the tags, and they already carry their predicates |
| concrete part instance | `MotorPartDefinition` (mag-11) | `shape_ref`, `shape_units`, `material_ref`, `function`, `purpose`, `why_this_material`, `field_buffer_mm`, `quantity` |
| equations as configuration | `motors/physics_equations.py` | 16 rows, sympy/LaTeX, `evaluate_named()` prefers the LIVE row over the seed |
| geometry | `MathShapeDefinition` + `shape_properties` | ⚠ **units are per-part** (`shape_units`) — a mm/cm confusion once reported a 1.1 **kilogram** clock motor |
| material properties + evidence | `MagneticMaterialOption.properties_json` | per-property `value`/`unit`/`provenance`/`note` |
| capability rungs | `techtree/wire_ladder.py` | W0–W3 with tooling gates, 8 consumers across 4 trees, loops+breaks |
| FEM | `materialsScience/engines/fem_engine.py` | elasticity **and** magnetostatics; both refuse rather than guess |
| lifecycle cost | `motors/lifecycle_cost.py` | cost per lifespan unit |

**Do not invent a parallel tag system.** Roles already encode what a
material must do, with the predicates attached; a tag without a
predicate is a label, and labels do not screen.

---

## 5. Open questions for the new design

1. **Where does a part component's *process history* live?** Drawn-then-
   annealed copper differs from as-cast. Property + process, or
   process-derived property rows?
2. ~~**Can promotion be partial?**~~ **ANSWERED by mag-26 (§1.2): yes.**
   The layered bound stator is promoted per layer while its layers stay
   separable. Promotion applies to a *named interface set*, never to a
   whole assembly.
3. **How do characteristic equations compose across a promotion?** The
   assembly's interface equations must be *retired*, not merely ignored,
   or a stale wear calculation will keep answering.
4. **Is "tunable toward a purpose" a property of the part, or of the
   part-in-a-design?** The M0 stator is tunable toward flux; the same
   casting in a different machine might not be.
5. **Do assemblies get realization levels too?** A design of
   made-and-measured parts is still an unbuilt assembly.

---

## 6. The one thing most worth carrying forward

Every substantive finding in this arc came from **a check refusing**, not
from a calculation succeeding: the pinion that failed fatigue, the sim
that would not run without a permeability, the route search that proposed
a magnet as an inert pinion, the winding model that reported the coil did
not fit. The refusals were informative because they distinguished *"this
is wrong"* from *"I do not know"* — a data gap was never reported as a
finding, and a finding was never softened into a gap.

Build the new structures so they can still say **"I do not know, and here
is what would tell us."**
