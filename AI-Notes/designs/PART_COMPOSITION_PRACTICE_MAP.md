# Part composition — map to professional design practice

**Companion to `PART_COMPOSITION_HANDOVER.md` (2026-07-31).**
That document records what the mag-1..26 arc *observed*; this one maps
each of our abstractions onto the established engineering-practice
concept it corresponds to, so the new data structures can borrow shapes
that industry has already debugged — and so we know precisely where we
are deliberately departing from practice, and why.

The headline: **almost nothing in the handover is exotic.** Nearly every
abstraction Dustin specified has an exact, named professional
counterpart, several with standards behind them. The few places we go
finer than practice (per-property evidence, graded predicates with
stated penalty) are deliberate and worth keeping.

---

## 1. The hierarchy → product structure (BOM), and one standard that
##    nails promotion

Our four levels (part component / part / sub-assembly / assembly,
distinguished by separability) are the industry's **product structure**
— the EBOM tree every PLM/PDM system maintains. But the sharpest match
is a drawing standard:

**ASME Y14.24 (Types of Engineering Drawings)** distinguishes exactly
our boundary:

- **detail (monodetail) drawing** — one piece part → our *part component*
- **inseparable assembly drawing** — items joined by welding, brazing,
  soldering, bonding, riveting such that they **cannot be disassembled
  without destruction** → our *promoted part*. This is the standard's
  own language, and it is the separability test verbatim.
- **assembly drawing** — separable members, designed interfaces → our
  *assembly*

So "promotion" has a professional name: producing an **inseparable
assembly** (a weldment, a potted/encapsulated assembly, an overmold).
Industry practice attached to that name, which our structure should
inherit:

1. **An inseparable assembly gets a NEW part number.** The
   form-fit-function (FFF) rule: when interchangeability changes,
   identity changes. Promotion is not a flag on the assembly row — it
   creates a new part identity with a **genealogy link** to the
   assembly it consumed. This cleanly resolves handover §5.3 (retiring
   the assembly's interface equations): the equations were attached to
   the *old* identity, and the new identity never had them. Retirement
   by construction, not by remembering to ignore.
2. The constituent list survives as the new part's **make-from /
   consumed-items** record (industry: the routing's material issue
   list), which is where "what it gave up" (§1.1 requirement) lives.

### 1.1 EBOM vs MBOM — the split our construction variants already need

Industry keeps **two linked views** of the same product:

- **EBOM** (engineering BOM): the *functional* decomposition — what the
  design needs ("a stator with N turns of gauge G").
- **MBOM** (manufacturing BOM): the *process-ordered* structure — how it
  is actually built, including intermediates that exist only
  mid-process (a wound-but-unpotted stator), which PLM calls
  **phantom assemblies**.

Handover §1.2 requirement 1 ("a construction variant is a first-class
alternative of one functional part, not a different part") *is* this
split. The three stator constructions are one EBOM node with three MBOM
realizations. PLM vocabulary for the variant machinery:
**alternates/substitutes**, **effectivity**, configurable ("150%") BOM.
Fill factor being a property of the construction (requirement 2) falls
out naturally: it is an MBOM-side property.

### 1.2 Process history (open question §5.1) — practice has answered this

Industry stores process history in two places, and we should copy both:

- **Material condition/temper designations**: copper C11000-H02
  ("half-hard") is a *different property row* from C11000-O60
  (annealed) under the same base material. Drawn-then-annealed vs
  as-cast is a **condition axis on the material**, and properties are
  specified per (material, condition) — not per material with a
  process note. This matches how `MagneticMaterialOption` already
  carries per-value provenance; it adds one key.
- **The routing/traveler**: the ordered operation list that produced
  the part. Configuration management then distinguishes
  **as-designed / as-planned / as-built** views. Our promotion record
  (process, DOF removed, modes deleted/introduced, reversibility
  spent) is one operation row on the routing — which means promotion
  and ordinary processing share a schema, differing only in that
  promotion's operation consumes an assembly and emits a part.

---

## 2. Interfaces → ICDs, mates, and the FMEA boundary

mag-26's finding — **promotion attaches to a named interface set,
never to a whole assembly** — lands on three professional practices at
once:

- **Interface Control Documents (ICDs)** / SysML **ports and
  connectors**: interfaces are first-class objects with their own
  identity, owner, and requirements. Systems engineering learned long
  ago that interfaces are where projects fail, so they are named,
  numbered, and controlled. Our interface rows should be too.
- **CAD mates/joints**: an interface is characterized by the **degrees
  of freedom it removes**. The handover's promotion record item (b)
  "the DOF it removes" is exactly a mate definition; storing it that
  way makes the interface machine-checkable against the kinematics.
- **FMEA boundary diagrams**: a DFMEA starts by drawing the block
  boundary, and interface failure modes (fretting, preload loss,
  fastener back-out — the Shigley bolted-joint catalogue) are
  enumerated *per interface*. Promotion redraws the boundary: interface
  modes are deleted with the interface row, bulk modes attach to the
  new part identity. Failure modes therefore live **on interfaces and
  on parts, never on assemblies as a whole** — which is also why
  reliability practice treats joints as the dominant failure sites,
  and why promotion is attractive at all.

Repairability spend is **maintainability engineering** (MTTR, design
for serviceability), priced through **life-cycle cost (LCC)** — which
`lifecycle_cost.py` already implements. The DFA tradition
(**Boothroyd–Dewhurst**) even gives the decision procedure for *when*
to promote: a member may be consolidated into its neighbor unless it
(1) must move relative to it, (2) must be a different material, or
(3) **must be separable for service**. Those three criteria are the
professional test for whether an interface is allowed to be promoted,
and they should gate the operation in our structure.

---

## 3. Characteristic equations → machine elements, Axiomatic Design,
##    and parametrics

Three traditions converge on the handover's §2:

- **The machine-elements tradition** (Shigley, Roark): mechanical
  engineering has organized itself for a century around exactly what
  Dustin is calling *part archetypes* — springs, shafts, gears,
  fasteners, bearings, each a chapter with its governing ("sizing")
  equations, characteristic failure modes, and a selection procedure.
  An archetype = {parameter set, characteristic equations, failure
  mode catalogue, selection procedure}. That is the schema, and it is
  why the next phase should be called what Dustin called it.
- **Axiomatic Design (Suh)** — the formal home of the cancellation
  insight. The **Independence Axiom** says maintain independence of
  functional requirements; the **design matrix** mapping functional
  requirements to design parameters is classified **uncoupled**
  (diagonal — every knob moves one outcome), **decoupled** (triangular
  — a valid tuning *order* exists), or **coupled** (iterate forever).
  The M0's structure is decoupled, not uncoupled: gauge → voltage is
  clean, but turns = f·W/A_wound depends on gauge too — so the tuning
  *order* (gauge, then window, then turns) is part of the design and
  worth storing. §2.5's "a characteristic equation set is well-formed
  when you can state it like that" becomes: **store the design matrix,
  and its classification is the well-formedness check.** A coupled
  matrix is precisely §3.2's silent-requirement-motion hazard, surfaced
  mechanically. The **Design Structure Matrix (DSM)** is the same idea
  as a dependency graph over parameters, and comes with an extra gift —
  see §6.
- **SysML parametric diagrams / constraint blocks**: MBSE attaches
  equations to blocks at each level of the product structure as
  configuration, not code — which is exactly what
  `EquationDefinition` + `physics_equations.py` already do. We are
  aligned with practice here; the extension is to add the design-matrix
  metadata (which knobs, which outcomes, what cancels) to each
  equation row.

---

## 4. Roles/tags → Ashby material selection; predicates → threshold
##    & objective

`part_roles.py` is an implementation of the **Ashby methodology**
(the basis of Granta Selector): translate function → constraints →
objectives → free variables, then **screen** by property limits and
**rank** by material indices. Our roles are the function-to-constraints
translation, stored as data; `screen_candidates` is the screening step.
Two of the handover's hard-won distinctions map onto practice:

- **Graded predicates (§3.6)** — professional requirements practice
  (DoD KPP language) states every performance requirement as a
  **threshold** (minimum acceptable — our *functional floor*) and an
  **objective** (desired — our *good target*), with the gap priced.
  Our addition — reporting the *penalty* (≈40× current at µ≈2.2) —
  is a **margin statement**, and margins management is standard
  practice. So the predicate row shape is: `threshold`, `objective`,
  `penalty_expression`.
- **Requirement vs disqualifier (§3.5)** — this one is *ours*.
  Materials databases handle missing data explicitly (Granta
  distinguishes "no data" from "not applicable"), but the
  requirement/disqualifier mode split — *must prove* vs *rejected only
  if stated over the limit* — is sharper than common practice and
  fixed a real bug (the permanent-magnet pinion). Keep it, and keep it
  as a declared mode on every predicate.

**Weibull derate and wear bands (§2.1)** are the **design allowables**
tradition: aerospace never designs to mean properties but to
**A-basis/B-basis** statistical allowables (MMPDS for metals, CMH-17
for composites), each value carrying its statistical pedigree. Our
per-property provenance is the same discipline.

---

## 5. Realization ladder → TRL/MRL and qualification

- theoretical → literature-demonstrated → recipe-seeded →
  made-and-measured is a **Technology Readiness Level** scale
  (NASA/DoD TRL 1–9), and the capability rungs (W0–W3) are
  **Manufacturing Readiness Levels (MRL)**. §3.2's requirement that
  an optimisation declare its capability rung = "state the MRL your
  design assumes", which is standard design-review practice.
- Our refinement — evidence **per property**, not per material — is
  finer than TRL and matches the allowables-pedigree practice above.
  Keep it.
- "Promotion needs a named act" (§3.9) = **qualification testing** /
  **first article inspection** (AS9102): readiness is earned by a
  specific witnessed measurement, never by relabelling. mag-12 already
  implements this as suggestion-over-evidence.
- Open question §5.5 (do assemblies get realization levels?) —
  practice says yes: system-level TRL exists precisely because
  qualified parts do not make a qualified system, and **Integration
  Readiness Levels (IRL)** grade the *interfaces*. Since our
  interfaces are first-class rows (§2), IRL slots in naturally:
  realization level on parts *and* on interfaces.

---

## 6. The remaining observed behaviours, each with its practice name

| Handover § | Our observation | Professional concept |
|---|---|---|
| §3.3 | model validity is data, with the adjudicating measurement | **V&V** — the model's *validation domain* (ASME V&V 10/20); the measurement is a *validation experiment* |
| §3.7 | dependency cycles stored with their break | **DSM tearing** — the literal technical term for choosing where to cut a cycle so iteration becomes ordering |
| §3.8 | industrial specs are economic, not physical | requirements **flowdown with rationale** — every derived requirement records *why* (rate/yield/tolerance/physics) so it can be re-derived at our volume |
| §2.4 | shippability = every composed check passing, blockers named | **compliance matrix** / verification cross-reference matrix — the certification-basis artifact |
| §3.1 | one parameter feeds both terms of a ratio | a **coupled design matrix** entry (§3 above) — the structure must let one parameter appear in both numerator and denominator roles |
| §3.4 | coating build enters as a square | tolerance/geometry **stack-up** across levels; coating as a distinct spec (industry: wire *build* grades — single/heavy/triple — are ordering codes separate from the conductor spec, confirming the attribute split) |
| §5.4 | tunable-toward-purpose: part or part-in-design? | **requirements allocation**: practice separates a part's *capabilities* (intrinsic) from *requirements allocated to it* in a given design context. Tunability-toward is allocation-side — a property of the slot, not the casting |

---

## 7. What this implies for the data structure (the borrowed shapes)

1. **Two linked structure views** — functional (EBOM) and construction
   (MBOM) — not one tree trying to be both. Construction variants,
   fill factors, phantom intermediates, and process step counts live
   on the construction side; purposes, allocated requirements, and
   characteristic equations live on the functional side.
2. **Interfaces are rows** with identity, DOF-removed, failure-mode
   list, and (later) their own realization level. Assemblies are thin:
   members + interface rows.
3. **Promotion is a routing operation** that consumes an assembly and
   named interface rows, emits a **new part identity** with a genealogy
   link, and records the Boothroyd–Dewhurst justification (why these
   members were allowed to consolidate). Old-identity equations retire
   by construction.
4. **Material condition is a key**, not a note: properties bind to
   (material, condition), and the routing is what moves a component
   between conditions.
5. **Equations carry design-matrix metadata**: knobs in, outcomes out,
   cancellations, and the uncoupled/decoupled/coupled classification —
   with decoupled sets storing their tuning order. Coupled = surfaced
   loudly, per §3.2.
6. **Predicates keep our two refinements** (requirement/disqualifier
   mode; threshold/objective/penalty) — these are at or beyond current
   practice and both fixed live bugs.
7. **Archetypes** (the named next phase) follow the machine-elements
   schema: parameter set + characteristic equations + failure-mode
   catalogue + selection procedure, as data. `part_roles.py` roles are
   the *material-facing* half of an archetype; the equations table is
   the *behaviour-facing* half; the archetype row is what joins them.

Where we intentionally diverge from practice, in both cases by being
*stricter*: evidence per property rather than per material, and
predicates that can refuse with "unassessed" rather than defaulting to
pass. Both earned their keep in this arc; neither should be traded away
for conformance.
