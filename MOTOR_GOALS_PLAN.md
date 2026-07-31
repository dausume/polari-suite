# Motor goals — constraint- and goal-driven design over composition

**Dustin 2026-07-31**: restructure the M0 approach around GOALS and
CONSTRAINTS — what is possible at different scales (watch → larger
clock) with different kinds of locally made materials, tuned by
goals (clock size, material policy), using scoring and known parts
to drive what you need. **The composition scaffolding is the
foundation, not a neighbour: it provides the equations and the
tuning order.**

> **STATUS 2026-07-31 (Fable 5): goal-1..4 BUILT + live-verified**
> (`motors/scale_goals.py`, framework on `dev-arch-part-composition`).
> Motors selftest 262/262; composition probe 23/23 live.
> Remaining: goal-5 (the explorer page), deploy.

## How it composes (the point of the scaffolding)

- The **equations are `EquationDefinition` rows** — goal-2 added the
  mag-25 winding relations (`eq-coil-voltage-gauge`,
  `eq-turns-in-window`, `eq-average-current`,
  `eq-battery-life-hours`) to `physics_equations.py`, referenced by
  the `at-coil-winding` archetype, evaluated live through the
  no-code executor. The engine carries **no fallback closed form**;
  a live-edited row changes the study without a deploy.
- The **tuning order comes from the archetype's design matrix**
  (`dm-coil-winding` → classify → gauge→window→turns). If the matrix
  classified *coupled*, the engine refuses the sweep outright — the
  mag-22 failure shape, structurally prevented.
- **Known parts drive requirements**: output is a requirement card
  per archetype slot (coil / bobbin-stator / rotor-magnet / pinion),
  each with roles, material candidates under the policy, and its
  demands (gauge+turns+rung; window+tolerance; module+tolerance).
- **Materials by policy**: `local-made-only` /
  `local-plus-imported-wire` / `any`, screened by `role_viability`
  over family-filtered catalog options with realization gates
  (locally made = recipe-seeded or made-and-measured, never a
  reference row).

## Phases

| Phase | Content | Status |
|---|---|---|
| goal-1 | `ClockScaleDefinition` (5 scales, priors w/ provenance: wristwatch / desk / wall=M0 datum / station / tower) + `MotorGoalSpec` (policy, life target, rung ceilings, scoring weights — all knobs); seeds via the arch-1 upsert path | ✅ |
| goal-2 | The 4 winding relations as EquationDefinition rows; engine binds them and follows the matrix order | ✅ |
| goal-3 | `goal_feasibility` + `scale_study`: three-way verdict **feasible / unassessed / blocked** (a gap is a measurement ask, never a finding), scored with goal weights, every blocker and gap NAMED | ✅ |
| goal-4 | `/api/motors/goals`, `/goal/{name}`, `/scale-study?policy=` | ✅ |
| goal-5a / view-1 | **Discipline views as DATA** (`motors/clock_views.py`, framework 05edc20): 8 `ClockViewDefinition` rows — goal-explorer (any-scale) + mechanical (observable failure conditions w/ what-you-would-see, load cases, stress/fatigue/contact, tensor field as a NAMED gap) + electrical and magnetic as SEPARABLE views + materials-provenance/sourcing (accountability chain = the dependency trace) + mass + motion (clock sim + verification) + cost (lifecycle + cheapest config, provenance-driven). Sections dispatch into existing engines; refusals stay IN the payload; caller params modulate goal/scale/component/policy. `component_view` = one part, five disciplines. Routes `/api/motors/clock-views`, `/clock-view/{name}`, `/component-view/{part}`. Probe 32/32 live | ✅ |
| goal-5b | The Angular page rendering the view rows: discipline tabs, scale/goal knob bar, component drill-in. The registry is data, so the page is ONE renderer | pending |

## What the first study says (seed priors — knobs, not verdicts)

- **Wall clock (control): zero blockers.** One gap: the rotor
  magnet — `opt-srfe12o19` is unassessed, i.e. **the engine
  independently rediscovered mag-22's named promotion** (sinter the
  recipe-seeded powder and measure it). Chosen point 34 AWG (W2),
  13.5k turns, 0.26 V, ~6 yr on an AA.
- **Watch: BLOCKED, blockers named** — the 3 mm² window needs wire
  finer than the table covers (48–52 AWG, micron enamel — beyond
  W3) and T4 jewel-grade tolerance. Requirements to meet, if ever
  wanted: extend the wire ladder past W3 and the tolerance ladder
  past T2.
- **Desk and station clocks: unassessed** (same single rotor gap) —
  and gauge **coarsens with size** (34 → 32 → 24 AWG): local
  production *improves* as the clock grows.
- **Tower: blocked at a TABLE EDGE, not a physics wall** — MMF 400
  needs > 1.5 V at 24 AWG, and the AWG table floors there; coarser
  wire is W1-easy. (The scale row also notes the honest answer:
  weight drive, historically.)
- **Strict local (no imported wire): blocked by mag-24** — drawing
  is the wall, bare fine wire the residual import; the blocker
  names both outs (accept the import, or build the W2 drawing
  strain).
