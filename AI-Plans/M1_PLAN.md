# M1 — switched reluctance, built out the M0 way

> **Dustin 2026-08-01**: "move onto M1, make a plan for building
> out M1 in a similar fashion to how we built out M0, with it
> needing to be modularized and split apart into different
> coherent views and components."
>
> Status: PLAN. Nothing below is built unless marked EXISTS.

## 0. What "the M0 way" means (the checklist M0 earned)

M0 ended as: a physics solver that steps → discipline VIEWS as rows
→ 3D scene LAYERS on one canvas → composition (parts, interfaces,
failure modes, promotion) → genuine assembly with real masses → an
END-TO-END PROOF against the thing the product is for → two
sourcing routes → business workflows + the sell-iterate loop → a
bench campaign with live predictions and record-back seams. Every
piece: data-first, refusal-honest, seeded via the upsert path,
two-modules-agree guards where facts are stated twice.

M1 gets the same skeleton. The differences all flow from one fact:
**M1 has no magnet and no clock — its product is POSITION.** The
target device is the wax printer's axis motors (tree:
manufacturing-devices/wax-3d-printer, powered-by
electric-motors/m1-switched-reluctance), so "keeps time" becomes
"lands on the commanded position through a leadscrew."

## 1. What EXISTS for M1 already (extend, do not invent)

| Piece | Where | State |
|---|---|---|
| design row `reluctance-6s4p-m1` | motor_basis | 6s/4p, saliency 3.0, 300 t/coil 26 AWG, mu~2 materials — honestly feeble, the loop-closer |
| geometry + scene `motor-m1-viz` | motor_shapes (mag-14) | 19 bodies, tooth/pole arrayed by scene rotation |
| part rows (yoke, teeth, poles, core, shaft) | motor_parts | with why-this-material in the M0 voice |
| torque curve | motor_designer | reluctance network; SPEED IS AN ASSUMPTION (named) |
| drive profile | motor_drive (mag-6) | simplefoc binding, phase table, honesty rider |
| roles | part_roles / mag-17 | M1 poles = torque-producing, want SOFT material; bio-steel viable |
| tech nodes | electric-motors/m1-…, devices/wax-3d-printer | deps + powered-by in place |

## 2. Modularization — one file per concern (the M0 rule)

New files live in `modules/motors/`, each owning ONE concern, each
seeded via the upsert path, each with fixture selftests:

- `m1_sequencing.py` — the M1 solver (the clock_sim analog)
- `m1_views.py` — M1 view rows (reuses ClockViewDefinition +
  view_payload verbatim — they are already design-parameterized)
- `m1_scene.py` — scene layers for motor-m1-viz (reuses
  ClockSceneLayerDefinition + the layer kinds; adds one kind)
- `m1_composition.py` — M1 interfaces + failure modes + part→body
  map (the composition splice, M1's own M0_INTERFACES analog)
- `m1_positioning.py` — the POSITIONING PROOF (timekeeping-proof
  analog) + printer-axis requirement rows
- product routes / workflows / bench: EXTEND product_routes.py,
  bench_campaign.py with M1 entries (same shapes, new rows)

Frontend: zero new components expected — clock-scene, the views
page, and the app shell are all data-driven; M1 arrives as rows.
(If a page hardcodes "clock", generalizing the title is the fix,
not a new component.)

## 3. Phases

### m1-1 — the sequencing solver (the physics spine)
`m1_sequencing.py`: quasi-static co-energy stepping of the 6s/4p
machine — excite phase k, rotor settles to the aligned position,
sequence phases → 30°/step (6·4 topology; the arithmetic is a
selftest). Outputs the STEP HISTORY (the replay contract clock_sim
established): per-step phase, settled angle, stepped/missed under
load torque. Named gaps carried loudly: no dynamic model (speed
still an assumption), no mutual coupling between phases, mu~2
saturation unmodeled. Bisect `minimum_drive_current` reuses as-is
(it already takes a design). Acceptance: hand-checked step angle;
missed-step behavior under excess load torque; refusals for
non-reluctance designs.

### m1-2 — views as rows
Six M1 views seeded (same class, `design` arg = m1): sequencing
(the solver + drive card), magnetics (reluctance network + torque
curve + model-validity — the mu~2 caveat leads), electrical (six
windings: per-phase R/L, the winding_report per coil),
mechanical (pole/tooth stress + fatigue via the existing engines),
materials-sourcing (accountability; bio-steel vs cast decision as
the lead), positioning (the m1-5 proof). Every section: lead +
links (nav-4 idiom). Acceptance: views assemble in fixture;
refused sections stay named.

### m1-3 — scene layers
`scene_json` for the M1 views on base `motor-m1-viz`. Layers:
- `m1-sequence-replay` (NEW kind or replay-with-phases): coils
  colored by which phase is EXCITED while the rotor steps — the
  flip that makes reluctance legible; drives from m1-1 history.
- part-coloring: stress / materials / mass (existing kinds — only
  the part→body map row differs).
- markers: M1 interfaces from m1-4.
Acceptance: layers stack on one canvas; browser pass shows the
phase sequence visibly walking around the stator.

### m1-4 — composition splice
M1 interfaces (tooth↔yoke, winding↔tooth, rotor↔shaft, the TWO
air gaps as designed non-contact interfaces) + failure modes +
the part→body map as data. The promotion question M1 actually
poses: are wound teeth PROMOTED into the stator (sol-gel, the
op-bound-cure trade) or separable bobbins? Both constructions as
ConstructionVariantDefinition rows, mirroring the mag-26 stator
family. Acceptance: composition view renders; two-modules-agree
guard between part rows and scene bodies.

### m1-5 — the POSITIONING PROOF (the product's "keeps time")
`m1_positioning.py`: printer-axis requirements as ROWS
(steps/mm via leadscrew pitch, axis load force, holding torque,
travel speed) → drive N commanded steps through the m1-1 solver
under the axis load → position error in mm vs commanded. EXACT
when nothing misses; every missed step = a named position error.
Cross-check (the as-3 discipline): mm error and the solver's own
missed count must be the same number via different paths. THE
verdict: can this M1, with today's materials, hold the printer's
axis duty — and if not, WHICH knob (bio-steel stator, more turns,
gearing) moves it. Acceptance: exact-agreement pinned; weak-drive
case loses exactly its missed steps; duty verdict names its knob.

### m1-6 — product routes + business splice
M1b product design if m1-5 demands retuning (the mag-25
discipline: solve, then seed the solved numbers). Routes: the
SAME two (pure-local / commercial) — M1's route difference is the
STATOR (cast mu~2 vs galvanized bio-steel vs fired), not the
magnet (there is none — that is M1's whole point). Workflows: the
batch build of FOUR identical units per printer (the first real
batch; feeds sell-iterate); purchase formula per unit ×4.
Acceptance: both routes answer; blockers named; the four-unit
batch is explicit in the workflow rows.

### m1-7 — bench campaign
Same shape as bench-1, M1 entries: per-phase R and L (six of
each — phase IMBALANCE is itself a finding), holding torque at
rated current vs the network's prediction, step-angle accuracy
over a full revolution (the positioning proof's physical half),
thermal rise at duty (named prior). Record-back: the same
verify/QA seams. Acceptance: predictions bind live; the L
measurements feed the same mag-23 adjudication.

### m1-8 — nav/app splice + deploy
M1 studies into app-magnetics + app-mechanical nav rows (upsert
delivers); the views page needs at most a title generalization.
Full deploy + browser pass + live probes, the M0 verification
discipline throughout.

## 4. Honesty ledger (carried from day one)

- SPEED IS STILL AN ASSUMPTION — m1-1 is quasi-static; the
  dynamic model is a named gap on every payload that touches
  speed, until someone builds it.
- mu~2 materials make M1 "honestly feeble" BY DESIGN — the rung's
  point is closing the cast→wind→drive→spin loop, and the
  bio-steel decision is a first-class fork in m1-6, not a fix
  applied silently.
- Phase mutual coupling and saturation: unmodeled, named.
- Every stated-twice fact (part↔body, view↔scene, requirement↔
  duty) gets a two-modules-agree guard — the wire-ladder lesson.

## 5. Order and gate

m1-1 → m1-5 are the spine (solver before views before proof);
m1-2/3/4 can interleave after m1-1; m1-6..8 close the product.
Gate to declare M1 "built out the M0 way": the positioning proof
exact in fixture AND live, the bench sheet bound, both routes
answering, and the browser showing the phase sequence walking.
