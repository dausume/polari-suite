# M3 — dual-stator axial flux, built out the M0/M1 way
# ⚠ SUPERSEDED IN ORDER (Dustin 2026-08-02): M2 comes FIRST — see
# M2_PLAN.md (which also owns the consolidation Part A). This
# file's Part B remains the M3 pick-up for after m2-8.

> **Dustin 2026-08-02**: "should we move on to m3? Make a plan for
> moving forward or on how we should consolidate work first before
> moving forward for a handoff."
>
> Status: PLAN. Nothing below is built unless marked EXISTS.

## Why M3 next (and not M2) — the recommendation

YES, M3 — for three reasons that came out of the repo, not
preference:
1. **Extend-don't-invent favors M3.** M3 already has 7 part rows,
   7 shape rows and the motor-m3-viz sim space (mag-12, the SS2d
   flagship). M2 has ONLY a design row — no shapes, no parts. M3
   is the rung where the M0/M1 machinery has something to grab.
2. **M3 is the thesis rung.** Dual gaps double active area inside
   the envelope — the §2d ferrite-parity argument the whole ladder
   points at. And with mq-1..3 in place, that claim can now be an
   EQUATION ROW: the two gap areas derived from the two stator
   disks' quadrics, the doubling as algebra, live.
3. **Its product is already named.** The tree says mini-traction
   is powered-by m3-axial-flux, and dt-1 already computed the
   duty: ~100 W per axle, twelve identical units per 2 t train —
   the traction proof and the batch story are waiting.

What M2/M2b keep for later (unblocked, not skipped-forever): the
commercial-precedent BLDC story and THE DRILL on the bootstrap
chain. NOTE the shared gate: M0, M2 and M3 all stand on the SAME
physical experiment — press, sinter, magnetize SrFe12O19. One
bench act unlocks three rungs; no software reorders that.

## Part A — consolidation first (the handoff gate)

### cons-1 — push the trailing commits
Three chain commits (M1 shaft steel + coil ref) and this plan sit
local-only. `polari-cli/shells/push-all-dev.sh --push`. EXISTS.

### cons-2 — roll staging + legend check
One backend roll converges the material rows (upsert); browser
check that the materials legend shows bio-steel/copper instead of
'(unresolved)'. Five minutes, closes the loop Dustin opened.

### cons-3 — THE OVERLAP DECISION (before any new solver work)
mq-3 quantified the m1 solver's first-harmonic overlap at ~17%
worst deviation from the exact trapezoid. DECIDE it now: adopt the
exact arc-overlap in m1_sequencing's landscape, re-pin the
selftests, and let the guards re-derive pull-in and the gear
ratio (they exist precisely so this cannot drift silently). M3's
solver reuses this machinery — build on the better model, not the
one with a known 17% hole. (A model change is a decision: this
plan RECOMMENDS yes; it does not do it.)

### cons-4 — derive the core path from the shape equations
The audit's biggest named prior (0.03 m, stated twice) retires:
mean flux path from the yoke annulus + tooth + pole quadrics.
Sharper L predictions flow straight into the m1-7 bench sheet.

### cons-5 — handoff refresh
NEXT_AGENT_HANDOFF.md top block: consolidated-on-dev state, the
push script, the mq machinery (a new agent must know shapes emit
equations and relations are drift alarms), the M3 pick-up pointer
to this plan. Memory index one-liners updated to push-ready.

Gate to start Part B: pushes clean, legend verified, cons-3
decided (either way), handoff block current.

## Part B — the M3 arc (m3-1..8, the proven skeleton)

What EXISTS: design row `dual-stator-axial-m3` (PM rotor
opt-sintered-hexaferrite between two wound geopolymer stator
disks, dual_gap true), 7 part rows, 7 shapes + motor-m3-viz,
torque_curve handles the doubled area, role slots wired, tree
node + powered-by. Honesty inherited: speed an assumption; the
MAGNET is the named experiment; mu~2 stators by design.

- **m3-1 — the rotation solver** (m3_rotation.py): the M1 pattern
  on the synchronous PM machine — 3-phase excitation, settle/step
  or continuous quasi-static rotation with load torque; history =
  the replay contract. M3's OWN facts (M1's inverses): a PM rotor
  HAS unpowered detent (cogging — holds when dead), has back-EMF,
  and loses SYNCHRONISM under overload (pull-out, the M1 pull-in
  lesson's sibling). Bisect analogs reuse.
- **m3-2 — real geometry + equations**: the 7 shapes get the mq-2
  treatment (disks and magnet ring segments are annular_sectors —
  the primitive already exists); mq-1 emission is automatic. THE
  RELATIONS: two gap equations from the two stator disks' + rotor
  disk's quadrics, and `m3-rel-dual-gap-area`: total gap area =
  2x single — THE §2d THESIS AS A ROW, judged live. (This absorbs
  most of mq-5.)
- **m3-3 — views as rows + scene**: six view-m3-* rows; scene
  layers reuse part-coloring/markers; replay drives from m3-1
  (the existing 'replay' kind fits a rotating machine — at most
  one styles tweak, no new renderer kind expected).
- **m3-4 — composition splice**: magnet-ring↔rotor-disk bond,
  TWO working gaps as designed non-contact interfaces, the
  MAGNETIZE-AFTER-ASSEMBLY op (the gr-3 two-material lesson
  formalized as an arch-4 operation), carrier explicitly
  non-magnetic (already in the part row's why).
- **m3-5 — THE TRACTION PROOF**: dt-1's per-axle duty as rows
  (wheel radius, tractive share, ~100 W at speed) → drive the
  m3-1 solver under wheel-reflected load → torque/power envelope
  vs demand, exact-or-named; cross-check against
  /api/motors/distributed-traction (two modules, one duty).
  Verdict names its knob (magnet grade / turns / gearing).
- **m3-6 — product + routes**: the mini-traction unit; routes
  differ on the MAGNET (pressed-local vs bought — the M0 magnet
  citation machinery reused); batch = 12 identical units per
  train (the batch story after M1's 4).
- **m3-7 — bench sheet**: TWO-GAP SYMMETRY (unequal gaps is the
  axial machine's signature defect — a finding only measurement
  makes), back-EMF constant vs prediction, cogging/detent map,
  holding + thermal. Record-back seams as always.
- **m3-8 — splice + deploy + browser**: nav rows, full roll,
  probes, the browser showing the axial machine spinning between
  its two stators.

## Honesty ledger (day one)
- Magnet remanence stays a literature prior until the press-
  sinter-magnetize experiment lands — every torque number carries
  it; the bench sheet's B_r entry is the retirement.
- Synchronous dynamics (start-up, pull-in to sync) unmodeled —
  quasi-static, named, exactly as M1's speed assumption.
- Two-modules-agree everywhere a fact is stated twice (duty ↔
  dt-1, gaps ↔ shapes ↔ design row, parts ↔ bodies).

## Order and gate
Part A gates Part B. Within B: m3-1 → m3-5 spine; m3-2/3/4
interleave after m3-1; m3-6..8 close. Gate to call M3 "built out
the M0 way": traction proof exact in fixture AND live, dual-gap
thesis row judged live, bench sheet bound, both routes answering,
browser showing the spin.
