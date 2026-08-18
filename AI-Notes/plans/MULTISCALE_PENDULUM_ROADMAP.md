# Multi-Scale Simulation — Pendulum Proof-of-Concept — Roadmap & Prep

_Written 2026-07-01 as a handoff to a fresh session (model: Claude Fable 5, given free rein to architect).
Read this first, then the memory files it references. This doc is **input for your architecture, not a
spec to execute** — Dustin wants you to own the design of this hard, long task. The build order below is a
recommendation to react to and improve, not a mandate; propose your own decomposition where you see better._

## Purpose of this document
Dustin wants to prove out **multi-scale / multi-dimensional simulation** in Polari, using the
pendulum as the test case, then modularize the samples, then advance the materials-science
framework. This doc scopes that work, points at the code that already exists, recommends a build
order, and lists the open design decisions a fresh model must resolve **with Dustin** before writing code.

**North star (why any of this exists).** BOTH the pendulum AND the wax composite are **test cases**,
not the destination. The true end goal is **Polari itself: a generalizable, maximally modular no-code
multi-scale simulation framework.** The trajectory of the framework:
1. **Done** — APIs and databases are automated away (define a class → auto DB table + CRUDE API).
2. **Now** — maximally modularize while *retaining* complex multi-scale simulation capability throughout.
3. **Next** — nodes integrate with one another and **self-configure / specialize via modules**.
4. **Eventually** — nodes **"consolidate" into their most efficient version**, shedding pieces they don't
   use. E.g. a node running only pendulum sims recognizes it needs none of the mapping/graphing logic
   and drops it; per data type, only the most-efficient formats of the APIs it actually used survive.

The concrete ladder right now: **multi-scale via the simple pendulum test case → wax composite test
case → (always) toward that generalizable framework.** The 3D-printable wax composite (Milestone F) is
the next *test case* once the pendulum PoC lands — a harder problem that stresses the same machinery.

**Architecting implication (important for every decision):** prefer designs that generalize,
modularize cleanly, and could later be *consolidated away* if unused — over one-off solutions. The
abstractions you build for the pendulum should generalize toward "compose spaces and derive/search for
a thing that meets stated goals," and should be shaped so a node not using them can shed them later.

## Where things stand (what already works — do NOT rebuild)
The single-scale Newtonian 3D pendulum is **working end to end** as of 2026-07-01:
- Reality-first vector/matrix sim (real mass/gravity, rigid rod, signed tension, derived energies),
  expressed as no-code `MatrixEquationOperation` states. Steps live via the runner and persist to DB.
- SimSpace3D renders the bob, the rod (connection), and **force-projection vector arrows**
  (gravity/net) that reposition per step; live eval/derivative equations read the run.
- Wind was always designed as "the next layer": a sibling **Partial** that adds a force to the bob's
  `f_app` accumulator with no change to the integrator. This is the natural seam for cross-scale coupling.

Relevant memory (in `~/.claude/projects/-home-user-Desktop-polari-suite/memory/`):
`polari-overview`, `polari-simulation-framework`, `newtonian_pendulum_sim`, `sim_space_3d_pendulum`,
`matrix-equation-operation-node`, `vector-sim-live-debug` (the full debug trail + the scene-scoping fix).

## The proof-of-concept Dustin described (three coupled "spaces" + a precondition)
1. **Wind-only space** — simulates a wind vector field in the 3D box; visualized as *sparse, intermittently
   appearing* arrows where the field applies. Output: a sampleable vector field.
2. **Material-defining space** — a 2D space grounded in the periodic table, accounting for ions.
   Output: element/material properties.
3. **Condensation precondition (pre-step)** — before the pendulum's inputs are even selectable, a
   *pre-simulation* determines the temperature/pressure/conditions under which the chosen element can
   condense into a **solid ball** (if a solution exists). This gates which bob inputs are valid.
4. **Enhanced pendulum space** — the existing Newtonian 3D pendulum, but the **bob** derives its
   mass/radius/density from (2)+(3), and receives wind force from (1). The **string** is a "miracle
   string" for now: infinite tension/rigidity so rotating-pendulum behavior is preserved.

The point is to prove **spaces compose and merge**: cross-space coupling (wind→force), cross-scale
property derivation (material→bob), and a gating pre-simulation (precondition→valid inputs).

## Recommended build order (smallest provable slice first)
The three spaces are a lot to build at once. Recommend proving the **coupling mechanism** on the
cheapest slice, then layering. Confirm with Dustin, but this is the suggested sequence:

**Milestone A — Wind space → pendulum coupling (do this first).**
Why first: wind is already the designed "next layer" (a Partial on `f_app`); it reuses the
vector-arrow viz that was just fixed; it's visually verifiable; and it exercises the *core*
multi-scale question — how one space's field is sampled and applied as a force in another space —
without the novelty risk of the material/precondition work. Deliverable: a wind vector field defined
no-code, visualized as sparse arrows in the box, sampled at the bob's position each step, added to
`f_app`; the pendulum visibly responds.

**Milestone B — Material space + condensation precondition → bob properties.**
The novel/risky part. A 2D periodic-table-based material space produces element properties; a
precondition sim decides whether a solid ball is achievable and under what T/P, and that result
gates/derives the bob's mass+radius. Leverage the framework's existing **5-level material
resolutions** (see `polari-simulation-framework` memory) rather than inventing a parallel model.

**Milestone C — Formalize "space composition" as a no-code/config construct.**
Once A and B work, extract the shared pattern into a first-class definition (a
`MultiScaleSimulationDefinition` / "space merge" — name TBD) so composing spaces is configuration,
not bespoke code. Do NOT build this abstraction first — derive it from two working couplings.

**Milestone D — Modularize the samples.**
Code/data will be large by now. Turn pendulum/wind/material samples into stashable modules (Polari
has a module system — see `polari-backend-scaffolding` memory). Keep files small, split by concern
(honors Dustin's file-size preference).

**Milestone E — Materials-science framework.**
Return to the materials-science module Dustin started; read what's there first. Flesh it toward
multi-scale + gradient-descent / progression simulation using batching, using experimental
simulation to "encroach upon" specified materials against property goals as the guideline. This is
the bridge from the pendulum PoC to the real target (Milestone F).

**Milestone F — 3D-printable wax composite simulation (the next, harder test case).**
Once the multi-scale pendulum PoC is complete, move on to this. It is a *test case*, not the end goal —
a harder problem that stresses the same multi-scale machinery. Goal: **use multi-scale simulation to
derive 3D-printable wax composites** — search composite wax formulations (constituents/ratios, and the
multi-scale physics that determines their bulk behavior) against **printability + property goals**,
using the batched / gradient-descent "encroach on a target material" search from Milestone E. The
pendulum's composable-spaces + cross-scale-property-derivation + precondition-gating machinery is
exactly what this needs, generalized from "one bob" to "a candidate composite." When the architecture
forces a choice, prefer the option that generalizes to material-composite search *and* keeps the true
end goal (a modular, self-consolidating framework) reachable. Scope the specific printability/property
targets and the search formulation **with Dustin** when this milestone begins.

## Open design decisions — resolve WITH Dustin before coding each milestone
- **How do spaces reference/merge?** Today a SimSpace scene binds classes via `bound_classes_json`
  and is scoped to one simulation (see the `_participating_sims_for` scene-scoping fix in
  `vector-sim-live-debug`). Multi-scale needs an explicit composition model: how does the pendulum
  space *declare a dependency on* the wind field and the material output? Is a "space" == a
  SimSpaceDefinition, or a new higher-level entity that references several?
- **Cross-space data flow / timing.** Is wind a precomputed field or stepped alongside the pendulum?
  Does the material/precondition run once up front (gating inputs) while wind+pendulum step together?
- **Precondition as a new concept.** A "pre-step simulation that determines valid inputs" doesn't
  exist yet — is it a SimulationDefinition run to completion whose result configures another sim's
  allowed initial conditions? (There's already an initial-conditions validator hook on the run panel.)
- **Sparse wind viz.** "Intermittently appearing" arrows implies sampling/decimating the field and a
  temporal/stochastic visibility rule — decide the rule before building the binding.

## Branching / progress-saving workflow (follow this)
This is a long, multi-phase build — save progress so a later mistake can't quietly erase a lot of work.
**Each confirmed phase of changes gets its own new branch off `dev`.** When a phase is confirmed working
(with Dustin), create a fresh branch based on `dev`, commit that phase's work to it, and push it. That
way each checkpoint is a durable, recoverable snapshot and something going astray later doesn't cost
more than the current phase. Name branches by phase (e.g. `dev-wind-coupling`, `dev-material-space`).
Commit/push only when Dustin has confirmed the phase (per the standing "commit only when asked" rule).

## Practical notes for the fresh model
- Node: `polari-rf-node`; backend is baked into the Docker image — code changes need
  `./rebuild-staging.sh` (add `--fresh-data` only to re-seed). Backend introspection is via
  `sudo docker exec -i prf-backend python3 - < probe.py` (read-only sqlite probes; DB file is
  `managerObject_DB.db`, not `polari.db`).
- There is still WIP debug logging to strip (commit `4a25960`: `[VECDBG]/[EVALDBG]/[VECDBG-BE]` and
  a new `[PARTDBG]`-style trail if any remain) — clean this up before/at the modularization milestone.
- **You have free rein to architect.** Dustin chose Fable 5 specifically so you can own the design.
  Treat the milestones as one candidate decomposition; if you see a cleaner factoring of "spaces that
  compose," propose it. Still surface the plan and the load-bearing design decisions to Dustin before
  building each major piece — free rein on *how*, alignment on *what/why*.
- Give the *reason* behind requests and connect work to the larger goal — Fable 5 uses intent to make
  better calls. Lead final summaries with the outcome; drop working shorthand for Dustin-facing writeups.
- Delegate freely. Fable 5 is dependable at parallel sub-agents that communicate asynchronously — use
  them for fan-out (reading subsystems, evaluating design options, verifying) rather than serial slogs.
- Use the memory dir as a durable scratchpad across sessions (this is a multi-session build): one lesson
  per file, record why it mattered, update rather than duplicate, delete what turns out wrong.
- Turns can run many minutes at high effort — that's expected on hard steps, not a hang.
- Don't build the composition abstraction before at least two concrete couplings exist; don't add
  features/refactors beyond what a step needs. Ground progress claims against actual tool results.
