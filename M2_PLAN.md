# M2 — PM-rotor motor, built out the M0/M1 way
# (executable handoff: written for ANY fresh agent, no re-derivation)

> **Dustin 2026-08-02**: "I guess I meant M2 not M3, cons 2 and 3
> are the only ones we needed ... make a handoff plan with those 2
> and also doing M2 since we tentatively finished M1." And: the
> plan should be writable "in a way that a non-fable model could
> use since the groundwork has been laid."
>
> Status: PLAN. Nothing below is built unless marked EXISTS.
> Style: every decision is PRE-MADE here; every phase names the
> file to COPY FROM; physics is given to TRANSCRIBE, not derive;
> acceptance = literal selftest lines. Read the DO/DON'T box
> before writing any code.

## THE DO/DON'T BOX (hard-won this arc — violations cost a deploy)

- DO run suites as: `cd polari-rf-node/polari-framework &&
  PYTHONPATH=modules:. python3 -m motors.selftest_m2` (files named
  `selftest_*.py` are auto-discovered by `pol modules selftest`).
- DO register any NEW treeObject class in polariServer THREE
  places: the motors try-import block (~line 882), its stub tuple
  (~line 890), and the definition-table class list (~line 2111) —
  or its seeds silently never land (PrinterAxisRequirement lesson).
- DO seed ONLY via `composition.seed_upsert.upsert_seed_pairs`
  chains in polariServer._seedSimSpace3D (legacy insert-only
  passes never converge changed rows — ten strikes + two more).
- DON'T re-import module-level names inside _seedSimSpace3D — a
  local `from x import Name` makes Name function-local and crashes
  the WHOLE admission worker (UnboundLocalError, hit twice now).
  Alias any genuinely new import (`import x as _x`).
- DO match rows by `getattr(row, 'name', '')` when reading
  manager.objectTables — LIVE tables key by id, fixtures by name.
- DO use `opt-*` MagneticMaterialOption names in part
  material_ref (a supplychain item name renders '(unresolved)').
- Deploy ritual: `pol node build backend --env staging` then
  `docker service update --force --image prf-backend:staging
  polari-node_backend`; admission ~8 min of honest 503s — poll,
  don't panic; NEVER docker cp+restart.
- Commit innermost-first: polari-framework → polari-rf-node →
  polari-suite (and polari-platform-angular beside framework),
  one phase per commit chain, all on `dev`.
- Every fact stated twice gets a two-modules-agree guard test.

## Part A — the two consolidation items (do FIRST, in order)

### cons-2 — roll staging + legend check  (30 min, mechanical)
The M1 shaft/coil material fixes are committed but not live.
1. Deploy ritual (box above), poll
   `https://api.prf.192.168.0.210.nip.io/api/motors/parts/
   reluctance-6s4p-m1` until 200 (~8 min).
2. Verify in the JSON: m1-shaft material
   `opt-galvanized-bio-steel`, m1-coils `opt-copper-magnet-wire`.
3. Browser (needs `claude --chrome`):
   /magnetics/clock-views?view=view-m1-materials-sourcing —
   the materials legend must show bio-steel + copper swatches and
   NO '(unresolved)'. Screenshot it for Dustin.

### cons-3 — THE OVERLAP DECISION  (approved direction: ADOPT)
mq-3 proved the m1 solver's first-harmonic overlap deviates up to
~17% from the exact trapezoid (`/api/motors/m1-overlap-gap`).
Adopt the exact form BEFORE building M2 on shared machinery:
1. In `modules/motors/m1_sequencing.py` `_phase_coenergy`:
   replace the `(1 + cos(POLES*u))/2` overlap fraction with the
   exact arc-overlap fraction already written in
   `modules/motors/m1_relations.py::overlap_model_gap` (transcribe
   its lo/hi/clip logic; beta_s and beta_r come from the SHAPE
   rows via `_shape_params` — import from m1_relations, do not
   restate the arcs).
2. Re-run `selftest_m1`: the hand-check angles stay (30°/step is
   topology, not overlap-shape); the PULL-IN numbers move — let
   them: update the pinned thresholds to the NEW solver values
   (print them, then pin them), and let `m1_product.GEAR_RATIO`
   re-derive (the guard test tells you the new required ratio;
   set GEAR_RATIO to it and update the two '~304:1' strings).
3. `overlap_model_gap` then reports ~0 deviation — update its
   namedGap text to say the model was ADOPTED on this date and
   the report now guards regression instead of naming a gap.
4. Suites green (m1 + motors + shape-equations), commit chain,
   deploy, re-probe `/api/motors/m1-axis/...` (dutyVerdict knobs
   will carry the new ratio).

## Part B — the M2 arc (m2-1..8)

### §1 What EXISTS for M2 (extend, do not invent)
| Piece | Where | State |
|---|---|---|
| design row `ferrite-pm-m2` | motor_basis | 6s/4p — THE SAME frame as M1 — saliency 1.0 (round PM ring), magnet 4 mm, gap 0.4 mm, 200 t 22 AWG, load_angle 90, 20 Hz |
| torque curve WITH the PM term | motor_designer.torque_curve + _phase_coenergy | EXISTS — saliency-1 kills reluctance torque, PM term takes over (already selftested) |
| stator family | motor-m1-yoke/tooth/coil shapes + m1 stator part rows | EXISTS — M2 REUSES M1's stator: same molds, same coil family. THE LADDER STORY: only the rotor changes |
| the product device | techtree: crucible-hoist powered-by m2-pm-rotor | EXISTS — "power-off holding by GEOMETRY (self-locking worm), not by a brake" |
| roles/materials | opt-sintered-hexaferrite (torque-magnet), part_roles vocab | EXISTS |
| magnet machinery | M0's press/sinter/magnetize workflow + citations + B_r bench entry | EXISTS — M2 shares M0's ONE named experiment |

### §2 Files (one per concern, all new files in modules/motors/)
- `m2_rotation.py` — solver (COPY FROM m1_sequencing.py)
- `m2_views.py` — view rows (COPY FROM m1_views.py)
- `m2_scene.py` — scene layers (COPY FROM m1_scene.py)
- `m2_composition.py` — splice (COPY FROM m1_composition.py)
- `m2_lift.py` — THE LIFT PROOF (COPY FROM m1_positioning.py)
- `m2_product.py` — product/routes (COPY FROM m1_product.py)
- bench: extend bench_campaign.py with `m2_bench_campaign`
  (COPY the m1_bench_campaign function pattern)
- `selftest_m2.py` — (COPY FROM selftest_m1.py structure)
Frontend: NONE expected — the 'replay' kind (M0's) already drives
a rotating machine; M2 seeds reuse it. If anything hardcodes
"clock", generalize the title, don't add a component.

### m2-1 — the rotation solver (m2_rotation.py)
The synchronous PM machine, quasi-static, TRANSCRIBED physics —
reuse `motor_designer._phase_coenergy(phi_rotor, phi_current,
k, params, mmfs, mu_stator, gamma)` (it already carries the PM
term and saliency): total W(phi_r, phi_c) = sum over k in 0..2.
The sim: advance the COMMUTATION angle phi_c in N equal steps of
(2π/steps_per_rev electrical); after each advance, settle phi_r
by the m1 gradient-walk pattern (copy `_settle`, potential
U = −W(phi_r, phi_c_held) + load·θ_mech, mechanical angle =
phi_r/pole_pairs) — history entries {step, phiElecDeg, thetaDeg,
thetaContinuousDeg, advancedDeg, shortfallDeg, inSync}. Facts to
carry (M2's own, the M1 inverses):
- LOSES SYNCHRONISM under overload: settled rotor lags > 90°
  electrical behind phi_c ⇒ pull-out — named per step, the
  ledger telescopes exactly as M1's (copy the crossCheck).
- COGGING IS A NAMED ABSENCE: this first-harmonic model predicts
  ZERO detent for a slotless-ideal machine — the real machine
  cogs from slotting. Do NOT fake it: `noCoggingInModel` note +
  the bench (m2-7) measures the real map. Power-off holding for
  the product comes from the WORM (the tree says so), not from
  cogging.
- back-EMF constant k_e DERIVES: k_e = pole_pairs · Φ_pm per
  phase-turn linkage — expose `back_emf_constant()` computed
  from the SAME mmfs/reluctance terms _phase_coenergy uses (no
  second copy of the magnet math; import, don't restate).
- `pull_out_load_limit` = bisect load until inSync fails (copy
  pull_in_load_limit's shape verbatim, judge on inSync).
Acceptance (selftest_m2): 1 electrical rev = 360/pole_pairs mech
degrees exactly; zero-load rotation error 0.0; overload loses
sync AND the mm... (torque ledger) balances by two paths;
saliency-1 ⇒ reluctance-only design refuses ("M2 is the PM rung
— use m1-sequence"); k_e > 0 and scales linearly with magnet
B_r (swap material via the override args, copy from m1).

### m2-2 — geometry: ONLY the rotor is new
DECISION (pre-made): M2 reuses M1's stator shapes/parts VERBATIM
(same rows, no copies). New shapes (motor_shapes.py, upsert-
converged — add to the seed_m1_product-style chain):
- `motor-m2-magnet-ring`: annular_sector? NO — full ring:
  csg difference of two cylinders (copy motor-m1-yoke's pattern),
  r_outer = 11.6 (gap 0.4 to tooth face at 12.0? NO — REUSE the
  M1 tooth face at r=12.6 ⇒ ring outer r = 12.2 for the 0.4 mm
  gap; guard test: tooth r_face − ring r_outer == gap_base_m·1e3),
  radial thickness 4.0 (== magnet_length_m·1e3, the SAME number —
  guard it), height 6.7.
- `motor-m2-rotor-carrier`: cylinder under the ring (non-magnetic
  ON PURPOSE — copy the M3 carrier's why-text argument), press-fit
  to the M1 shaft shape (reused).
- sim space `motor-m2-viz`: copy motor-m1-viz's definition,
  replace the 4 pole bodies + core with ring + carrier (bodies:
  shaft, carrier, magnet-ring, yoke, 6 teeth, 6 coils = 16).
Part rows: m2-magnet-ring (opt-sintered-hexaferrite,
why: bonded/sintered hexaferrite ring — the commercial-precedent
rotor), m2-rotor-carrier, and REFERENCES to the m1 stator part
rows (do NOT duplicate them — the composition view reads by
design_ref, so add design_ref-agnostic reuse: give M2 its own
part rows ONLY for rotor pieces and state the stator reuse in
notes + a two-agree guard that m2 stator params == m1's).
mq-1 equations emit automatically (add the new shapes to the
ShapeEquationSeed-pre convergence list); equation-parity must be
green for both new shapes.
Relations (m2 additions to m1_relations pattern, new file NOT
needed — add M2 rows + expectations to a SEED_M2_RELATIONS in
m2_composition.py): m2-rel-working-gap (tooth face quadric −
ring outer quadric == 0.4), m2-rel-magnet-thickness (ring outer −
ring inner == magnet_length_m — the design row and the shape row
are ONE fact).

### m2-3 — views as rows (m2_views.py)
Six `view-m2-*` rows (same ClockViewDefinition, sections pin
design=ferrite-pm-m2): rotation (solver + drive card + bench),
magnetics (model-validity FIRST, torque-curve, k_e), electrical
(phase electrics — the m1_phase_electrics fn already takes a
design arg; 200 t 22 AWG), mechanical (ring bond stress via
part-stress on m2-magnet-ring), materials-sourcing (role screen
on the ring: torque-magnet-active; accountability; NO
construction fork needed — the ring is bought-or-pressed, a
ROUTE question not a construction one), lift (the m2-5 proof).
Register sources in M1's SECTION_SOURCES via m2_views import in
motor_api (copy the m1_views registration comment + pattern).
Scene rows in m2_scene.py: replay layer uses kind 'replay' (M0's)
with rotorBodies [shaft, carrier, magnet-ring] and rotation about
z ADDING to base rotations (the clock-scene component already
does this for phase-replay; the plain replay path rotates about
z at origin — verify with the M0 layer first; if the M0 replay
geometry doesn't fit, reuse kind 'phase-replay' with all six
coils in one 'phase' — pre-decided fallback, no new kind).

### m2-4 — composition splice (m2_composition.py)
M2_INTERFACES (copy M1's list shape): ifm2-ring-carrier (bonded,
designed_separable False, adhesive — the promotion ALREADY in the
build), ifm2-carrier-shaft (press, separable), ifm2-working-gap
(non-contact, zero DOF — ONE gap this time, say so vs M1's two),
winding↔tooth REUSED from M1's fork (reference, don't restate).
THE M2-SPECIFIC OP: `op-m2-magnetize` — MAGNETIZE AFTER ASSEMBLY
(the gr-3 two-material lesson as an arch-4 RoutingOperation; copy
op-m1tp-cure's row shape, kind stays 'join' unless a 'magnetize'
kind exists — do NOT invent a kind). Promotion answers: the
ring-carrier bond is already fused; the gap is the machine.
Guards: interface members ⊆ m2 part rows; the movement derives
its level and MATCHES.

### m2-5 — THE LIFT PROOF (m2_lift.py)
The hoist duty as rows (class CrucibleHoistRequirement — NEW
class: registration box applies!): crucible mass 2.0 kg (prior,
retire: weigh it), drum radius 15 mm (prior), worm ratio 30:1
self-locking (prior; the SAFETY fact — power-off holding by
geometry), pulley advantage 2:1, lift speed (assumption, named).
The proof: torque at drum = m·g·r/(pulley); at the motor through
the worm = /(ratio·η_worm) with η_worm ~0.4 NAMED (worms are
lossy — that is WHY they self-lock; η and self-locking are the
same physics, say so). Drive m2-1 under that load: verdict
'lifts' iff inSync at duty with the 1.5 margin; 'holds-when-dead'
comes from the WORM row, never from cogging (assert the payload
says this). Cross-check (as-3 discipline): motor-side torque
demand computed TWO ways (chain of ratios vs energy: m·g·v /
(ω_motor·η_total)) must agree to 1e-9 — two paths, one number.
Verdict names its knob (magnet grade / turns / worm ratio).
Wire into views + API `/api/motors/m2-lift-proof` (copy the
m1-positioning-proof route pattern).

### m2-6 — product + routes (m2_product.py)
Product `m2-hoist-drive` (motor + worm stage + drum), 1 per
hoist. Routes differ on THE MAGNET (the M0 machinery returns):
pure-local = press-sinter-magnetize SrFe12O19 (THE named
experiment, shared verbatim with M0 — same workflow row, cite
it, don't copy it), commercial = bought ferrite ring magnet
(needs a PriceCitation row — leave the honest gap if uncited).
Stator route notes REUSE M1's (same molds — say so; that IS the
ladder). Workflows: press-ring, wind-six (cite m1's), worm-stage
(gr-6 planetary/worm algebra exists in gears), assemble+magnetize
(op-m2-magnetize LAST — the two-material lesson), QA
qa-lift-hold-24h (hold a suspended crucible 24 h power-off —
the safety gate; copy qa-timekeeping-24h's row shape).
GEAR-RATIO GUARD: worm ratio seeded == ceil from the LIVE
pull-out limit ×1.5 (copy the m1 GEAR_RATIO guard verbatim).

### m2-7 — bench sheet (extend bench_campaign.py)
`m2_bench_campaign`, dispatched for the m2 design (copy the m1
dispatch line). Entries: six phase R (imbalance = finding, reuse
m1_phase_electrics via design arg), BACK-EMF CONSTANT k_e —
spin by hand, scope the phases, vs the m2-1 prediction (THE
model-adjudicating measurement: it isolates the magnet+turns
product from everything else), COGGING MAP (the model predicts
zero — whatever the bench finds is pure slotting reality, a
finding by construction), B_r remanence (cite M0's entry — same
experiment), pull-out torque vs prediction, thermal at duty
(dissipation solved I²R, rise unmodeled — copy m1's honesty).

### m2-8 — nav/app splice + deploy + browser
Nav rows: M2 views under Magnetics & Motors ('M2 PM rotor —
rotation & lift') + Mechanical (lift proof) — copy the m1-8
apps_seed edits + update the nav-2 fixture count (it pins
composition-gated item counts — the m1-8 lesson). Full deploy,
probe battery (write it as m1-8's was: one python block, every
new endpoint), browser pass: the ring spinning in motor-m2-viz,
views rendering, legend clean. Update NEXT_AGENT_HANDOFF +
memory (m2 file + MEMORY.md line) at the end.

## Honesty ledger (day one)
- The MAGNET is a literature prior until press-sinter-magnetize
  happens — every torque/k_e number carries it; B_r bench entry
  is the retirement (shared with M0, one experiment, three rungs).
- Cogging: model says zero BY CONSTRUCTION (first harmonic) —
  named absence, bench measures the truth. Power-off safety is
  the WORM's geometry, never a cogging claim.
- Speed/synchronism dynamics: quasi-static, named (start-up and
  pull-in-to-sync unmodeled — the M1 speed assumption's sibling).
- Worm η ~0.4 and self-locking are the same physics — one prior,
  stated once, guarded where restated.

## Order and gate
Part A (cons-2 then cons-3) gates Part B. Spine: m2-1 → m2-5;
m2-2/3/4 interleave after m2-1; m2-6..8 close. Gate to call M2
"built out the M0 way": lift proof exact in fixture AND live
(both torque paths agreeing), k_e bound on the bench sheet, both
routes answering with the magnet experiment named, browser
showing the ring spin, suites + probes green, all committed on
dev through the pointer chains.

## Note on M3
M3_PLAN.md stays valid for AFTER M2 — its Part A is superseded by
this file; its Part B (the dual-gap thesis-as-a-row and the
traction proof) picks up where m2-8 ends.
