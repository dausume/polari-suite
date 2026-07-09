# Next-agent handoff — 2026-07-09 (PIVOT BACK TO AQUAPONICS)

Dustin is moving back to the aquaponics simulation. **START HERE:
`AQUAPONICS_PHASE2_PLAN.md`** at the suite root — three fully-detailed,
GPT-4-executable phases (aqp-3 FEM hydraulics → aqp-7 worm-compost
enrichment loop → aqp-8 per-part plant growth/failure), ordered
HARDEST→EASIEST per Dustin. Do them one at a time, branch per phase,
selftest green before moving on. The plan is self-contained; read it
first. Background context: [[aquaponics-module]] +
`AQUAPONICS_MODULE_PLAN.md`.

## The three phases (all planned in AQUAPONICS_PHASE2_PLAN.md)
1. **aqp-3 — FEM water-flow engine** (hardest). New scikit-fem scalar
   Darcy solver (twin of `materialsScience/engines/fem_engine.py`
   `solve_steady_conduction`), runs on the msci-engines worker via the
   topology-routed remote seam. Answers "does the pot drain by gravity,
   at what rate, moisture field?" — replaces aqp-1's L0 permeability
   priors. Fidelity knob: reduced reservoir model (in-backend, always
   answers) vs FEM (worker). This is the long-standing aqp-3 phase.
2. **aqp-7 — worm-compost (vermicompost) nutrient-enrichment loop**
   (medium). Box-model bin that enriches passing aquaponic water; TWO
   modes both selectable — direct-in-loop (continuous) and controlled
   periodic flow-through (pulses + recharge). Abstract estimate OK;
   flag rate constants as literature-range priors. Couples enriched
   water into the pot's nutrient input; rankable via the scoring bridge.
3. **aqp-8 — per-part plant growth / growth-failure** (easiest; extends
   aqp-4). Makes the existing PlantPart objects GROW (logistic vs
   limiting resource) or FAIL (limiting factor named); volume-per-part
   interaction estimation (leaf↔root↔fruit coupling by volume+
   condition) as a small tunable coefficient table. Realized per-part
   volumes feed aqp-6 env-impact scoring.

## aqp status recap
aqp-1/2/4/5/6 BUILT + committed (5 stacked branches off the scoring
stack; 76 module selftest checks green; NOT yet deployed to staging).
aqp-3 was always "the one remaining phase". aqp-7/aqp-8 are NEW
(2026-07-09). Module lives at
`polari-rf-node/polari-framework/aquaponics/`; conventions + the exact
polariServer wiring points are in AQUAPONICS_PHASE2_PLAN.md §0.

## Deploy discipline (bit me repeatedly)
- `export LOCAL_IP=192.168.0.210` before ANY docker compose on
  docker-compose.staging-nip.yml (else pol-file-store crash-loops).
- prf-backend serves :3000 only after cold-seed (minutes; healthcheck
  flaps). Selftests run in-container: `pol modules selftest aquaponics`.
- API-created treeObject rows need explicit
  `manager.db.saveInstanceInDB(row)`.
- Angular templates: literal `@` breaks builds — use `&#64;`.
- falcon POST bodies read `request.bounded_stream`.

## Just-completed (last session): TOPOLOGY ORCHESTRATION — DONE
top-1..top-8 all built + live-verified (see [[topology-orchestration]]):
topology-as-data core (`topology/` module, /api/topology/*), `pol
topology` CLI + portable packages (parity round-trip), multi-node swarm
(**lightweight joined as a worker; the polari-engines stack now RUNS
THERE**), Topology tab (/topology, drag-drop modules — graph
autoplacement compacted + fit-to-view per Dustin), provider routing,
reallocation suggestions. **RELEVANT TO aqp-3**: the engines worker is
reachable via the topology-routed remote seam with no MSCI_ENGINES_URL
set — aqp-3's Darcy solver goes on that worker. ⚠️ Dustin's browser
review of the Topology tab is still pending.

## NOT pushed to GitHub
All local branch stacks (repos PUBLIC). Push before any `pol deploy
run`. Topology branches: suite/cli `dev-top-4-multinode`, rf-node
`dev-topology-orchestration`, framework `dev-top-1-topology`, angular
`dev-top-5-topology-tab`.

## Other parked work (unchanged)
scr-7 scorecard↔Polari wiring, scr-9..14; scoring/materials as before.
