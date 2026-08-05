# Handoff — wax-mold simulation and the nested casting chain

**To:** Fable 5 · **From:** Opus 5 · **Date:** 2026-08-05
**State:** all five repos clean on `dev`, nothing pushed.

This is the **general direction and the next steps**, deliberately not
a phased plan. Dustin asked for the plan to come after. Read this,
then write `WAX_MOLD_NESTING_PLAN.md` with him.

---

## 1. What we are building (Dustin's words, kept intact)

> Simulate "magically" having a perfect wax-filament or CNC-able wax
> mold for a part. Then simulate making a geopolymer part using that
> wax mold. After that, nesting: take a ceramic part we want, and do
> wax → geopolymer mold → ceramic; then another nesting
> wax → geopolymer → ceramic → metal. Develop the capability to make
> arbitrary math-shapes out of any kind of material makable locally,
> and automate the process of making easy-to-remove sprues.

Two things that are explicitly **in scope as assumptions, not
problems to solve**:

- The wax master is **given, and perfect**. We are not simulating the
  wax printer's fidelity here. `waxprint` already simulates that in
  detail (beads, melt, cooling) and it is a *separate* concern — the
  point of "magically" is to unblock the casting chain from the
  fabrication chain. Keep the seam explicit so a real
  `WaxPrintSimState` can be swapped in later where the magic is.
- "Any material makable locally" means the local-makability question
  is already answered elsewhere (tech tree routes, pure-local vs
  commercial, blockers named). Consume that verdict; do not re-derive
  it.

---

## 2. The idea the whole thing turns on

**Every casting stage inverts the geometry.** A mold is a negative; a
part cast in it is a positive. So a chain is an alternating
positive/negative sequence, and that has a consequence worth stating
plainly:

> **The parity of the chain determines whether the wax master must be
> a positive or a negative — and it flips with every stage you add.**

- `wax → geopolymer part` (1 stage): the wax is the **mold** (negative).
- `wax → geopolymer mold → ceramic` (2 stages): the wax is a
  **positive**, geopolymer is the negative, ceramic is the positive.
- `wax → geopolymer → ceramic → metal` (3 stages): the wax is a
  **negative** again.

Get this wrong and you produce a confidently-computed inside-out part.
It must be **derived from the chain depth, never hand-set** — that is
exactly the kind of thing Polari should compute and refuse on rather
than leave to whoever is typing. This is the single most important
correctness property in the whole feature.

**The second constraint is thermal ordering.** Each mold material must
survive the process temperature of the material cast into it, and the
sacrificial material must NOT survive (that is how it leaves). So:

- wax is sacrificial — it melts/burns out on purpose;
- geopolymer must survive its own cure, and survive firing if it is
  the thing being converted to ceramic;
- ceramic must survive molten metal.

`materialsScience` already carries melt/service temperatures and a
sintering/ceramics ladder, and `pspp/characterization.py` already
names *"the geopolymer→ceramic path"* (XRD crystallization onset when
a geopolymer is fired). **A chain that violates thermal ordering
should be refused with the offending pair named**, not silently
simulated. Do not invent new temperature data — bind to what exists.

---

## 3. What already exists (build on it; do not rebuild)

Verified present in `polari-rf-node/polari-framework`:

| Area | Where | What it gives you |
|---|---|---|
| Math shapes | `modules/mathshapes/` — `shape_basis`, `shape_geometry`, `shape_equations`, `shape_modify`, `cad_*` | Shapes as matrix equations; **`shape_modify.py` already does algorithmic geometry modification** (the pot-hole work) — the natural home for sprue attachment |
| Wax printing | `modules/waxprint/` — bead/melt/cooling/voxel sim, `sim_api` | The fabrication sim we are deliberately stubbing past, and the seam to reconnect later |
| Wax materials | `modules/waxsupply/` — `WaxSourceDefinition` | Already ranks waxes **for use `mold`**, carnauba/candelilla as the lost-wax feedstock. Real melt points |
| Process chains | `modules/composition/` — **`RoutingDefinition` + `RoutingOperation`** (16 live rows) | ⚠ **The process-chain spine already exists.** The nesting chain should be routing operations, NOT a parallel chain model |
| Part structure | `modules/composition/` — archetypes, EBOM/MBOM, PROMOTE, interfaces | Parts, separability, and the derived-level machinery |
| Geopolymer / ceramic | `modules/pspp/` — sol-gel, structure validation, characterization; `materialsScience/` — sintering, ceramics ladder, standard materials | The materials science and the geopolymer→ceramic transition |
| Local makability | `techtree/` — `manufacturing-devices` chain, route verdicts | Whether a material/process is locally achievable, with blockers named |

**Genuinely greenfield** — grepped, nothing exists: `sprue`, `mold`
(as geometry), `investment`, `lost-wax` (as a process object),
`casting run`. The *materials* vocabulary is there; the *geometry and
process* of molding is not. That is the new work.

---

## 4. General next steps (coarse, in dependency order)

Not tasks — the shape of the work. Sizing and sequencing is the plan's
job.

1. **Make the inversion a first-class operation.** Shape → its
   negative, as an object in the tree, with the cavity, the parting
   consideration, and shrinkage/allowance as declared parameters
   rather than baked constants. Everything else composes from this.
   Start here; it is the primitive.

2. **One casting stage, end to end, honestly.** `wax mold →
   geopolymer part`. Deliberately the simplest case (Dustin's first
   ask) and the one that proves the primitive. It should produce a
   real part shape with real material properties and **name what it
   does not model** rather than quietly assuming perfection.

3. **The chain as data, with parity and thermal ordering derived.**
   Generalize one stage to N. This is where §2 lands: depth →
   wax parity, and the material sequence → thermal feasibility, both
   computed and both able to REFUSE with the reason named. Ride
   `RoutingOperation`.

4. **Sprues and gating, automated.** Feed and vent paths generated
   from the geometry, placed so removal will not damage the part, with
   "easy to remove" as an evaluated property (attachment
   cross-section, access, and the material's brittleness/ductility —
   a ceramic sprue and a metal sprue do not break the same way).
   `shape_modify.py` is the place. Expect this to be the hardest and
   most interesting piece.

5. **Close the nestings Dustin named.** `wax→geopolymer→ceramic`, then
   `wax→geopolymer→ceramic→metal`. If steps 1–4 are right these are
   configuration, not new code. **If they require new code, that is
   the signal the chain model is wrong** — treat it as a design test,
   not a chore.

6. **Arbitrary shape × any locally-makable material.** The general
   capability: take any math-shape, ask what it can be made from
   locally, and get the routes with blockers named. This is the payoff
   and it should mostly be composition of the above plus the tech
   tree's existing verdicts.

---

## 5. Decisions to put to Dustin before building

- **Where the module lives.** New `modules/casting/` (or `molding/`)
  versus extending `waxprint`/`composition`. The ownership page at
  `/topology/databases` now shows exactly one module owning each
  object — whatever is chosen, one module must own the new classes.
  Recommend a new module; this is a distinct concern from printing.
- **Resolution.** Voxel (reuses `waxprint`'s machinery) versus
  analytic on the matrix-equation shapes (reuses `mathshapes`, exact,
  and matches "arbitrary math-shapes"). This is the biggest technical
  fork and it shapes everything downstream. Lean analytic, drop to
  voxel only where it must.
- **How much physics in v1.** Shrinkage, thermal contraction, cure
  distortion, draft angle, undercuts. All real; all can be *named as
  unmodelled* initially. Per house style, an honest absence beats an
  invented number — but Dustin should choose which ones matter first.
- **What "easy to remove" means numerically.** Needs a definition he
  agrees with before it can be optimised against.

---

## 6. House rules that bite in this area

- **Knobs + evidence-bearing suggestions; never auto-apply.** Every
  capability is an explicit knob, and suggestions carry their
  evidence.
- **Refuse rather than invent.** A chain that cannot work should say
  which pair fails and why. Absent data is reported absent — this
  codebase has repeatedly been bitten by plausible defaults.
- **New `treeObject` classes must be registered in polariServer's
  explicit class list**, or seeds run clean and the rows silently
  never appear. See `m1-reluctance-build` memory. This will happen to
  you otherwise.
- **Adding a FIELD to an existing seeded class** is the ten-strikes
  trap — `_syncTableColumns` handles the column, but seeds do not
  update existing rows. Verify live, do not assume.
- **Per-object displays, not raw JSON.** Configure tables/graphs from
  the object's own page tabs and seed them as module data. Raw JSON
  dumps are a known regression in this codebase.
- Keep files small, split by concern. Branch per confirmed phase.

## 7. Build / run / verify

`pol` only — never hand-rolled compose/mvn/ng (see `CLAUDE.md`).

```
pol node build backend|frontend      # then: docker service update --force polari-node_<svc>
pol modules selftest <module>        # in-container
```

Backend is a **swarm service** — `docker cp` is discarded on restart.
Live API `https://api.prf.192.168.0.210.nip.io` (https; http 301s).
Selftests can be run directly in the container:
`docker exec <backend> python -m modules.<mod>.selftest_<x>`.

## 8. Where this session left off

Last work was topology/storage and theming, all committed and
live-verified, unrelated to this feature:

- `/topology/databases` — object → owning module → responsible
  instance → its database; all three storage tiers assignable.
- Nav chrome unified as one token set across the top and side menus.

Suite pointer `7cf00a2`. Nothing pushed — pushing is Dustin's manual
step via `polari-cli/shells/push-all-dev.sh`.
