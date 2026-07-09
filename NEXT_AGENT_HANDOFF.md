# Next-agent handoff — 2026-07-09 (AQUAPONICS PHASE 2 BUILT — tail below)

## ⚡ UPDATE 2026-07-09 (later session): aqp-3 / aqp-7 / aqp-8 ALL BUILT
All three Phase-2 phases are BUILT, committed locally, and selftest-green
(133 aquaponics checks). Branch stack in polari-framework:
`dev-aqp-3-hydraulics` → `dev-aqp-7-vermicompost` → `dev-aqp-8-growth`
(HEAD `dev-aqp-8-growth` = all three; commits 3780e28 / 48e5a20 /
054f401). rf-node worker twin on `dev-aqp-3-hydraulics` (3c09349).
Full per-phase detail + gotchas in [[aquaponics-module]] memory.

**✅ DEPLOYED + LIVE-VERIFIED this session** on
docker-compose.staging-nip.yml (prf-backend rebuilt, cold-seeded, all 8
aquaponics selftests green in-container). Live results:
- aqp-3 `GET /api/aquaponics/pots/demo-herb-pot/drains?soil=coir-perlite-mix`
  → `fidelity: fem`, drains: true, 0.044 mL/s, 8192-element mesh;
  head-field → 4225-node head field. **scikit-fem is pure-python and
  RIDES THE ALPINE BACKEND IMAGE** (as fem_engine.py's own comment
  says) — the FEM path runs IN-BACKEND, the msci-engines worker rebuild
  is NOT needed for aqp-3. (The worker `/darcy/*` routes + `darcy_solver.py`
  twin still exist as the delegation fallback; harmless, already built.)
- aqp-7 compare-modes recommends `direct`, periodic pulse peak 5.0 mg/L
  N; simulate persists the snapshot; the `nutrient-enrichment-efficiency`
  ScoreConcept resolves live.
- aqp-8 grow survives healthy (3 parts, top interaction leaf→root);
  under starved nitrate the root goes `condition: failed, limiting:
  nitrate-n, survived: false`.

**GPT-4 TAKEOVER — remaining tail (in priority order):**
1. **Optional: aqp-3 sim-as-data wrappers** (plan §aqp-3 item 4 —
   PotHydraulicsSimState + SimulationDefinition + coupling). I built the
   engine + analysis + API + scoring; deferred the runnable-sim-object
   wrappers (not in acceptance, add risk). Same for aqp-7 CompostLoopState
   / aqp-8 PlantLifetimeState if a runnable timeline object is wanted.
3. **Frontend surfaces** for the three phases (none built).
4. **Dustin browser review** + push to GitHub (repos PUBLIC — push
   before any `pol deploy run`).

Verify commands are at the bottom of this file. Nothing pushed to
GitHub (repos PUBLIC).

---

Dustin moved back to the aquaponics simulation. Phase-2 plan (now
executed): **`AQUAPONICS_PHASE2_PLAN.md`** at the suite root — three
GPT-4-executable phases (aqp-3 FEM hydraulics → aqp-7 worm-compost
enrichment loop → aqp-8 per-part plant growth/failure), ordered
HARDEST→EASIEST. Background: [[aquaponics-module]] +
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

## Live-verify commands for the aqp-3/7/8 endpoints
After `export LOCAL_IP=192.168.0.210` + `docker compose -f
docker-compose.staging-nip.yml up -d --build prf-backend` and the cold
seed finishes (backend serves :3000), from the suite root:

```
# in-container selftests (all 8 suites; 133 checks)
for t in pot growth_media plant atmosphere system hydraulics \
         vermicompost plant_growth; do \
  docker exec prf-backend python3 -m aquaponics.selftest_$t | tail -1; done

# aqp-3 hydraulics (reservoir until the worker carries skfem)
docker exec prf-backend python3 -c "import urllib.request as u; \
print(u.urlopen('http://localhost:3000/api/aquaponics/pots/demo-herb-pot/drains?soil=coir-perlite-mix').read())"
# aqp-7 vermicompost
docker exec prf-backend python3 -c "import urllib.request as u; \
print(u.urlopen('http://localhost:3000/api/aquaponics/compost-loops/basil-loop-direct/compare-modes').read())"
# aqp-8 growth
docker exec prf-backend python3 -c "import json,urllib.request as u; \
r=u.Request('http://localhost:3000/api/aquaponics/plants/sweet-basil/grow',\
data=json.dumps({'days':120}).encode(),headers={'Content-Type':'application/json'}); \
print(u.urlopen(r).read()[:400])"
```
Public proxy equivalent: `https://api.prf.192.168.0.210.nip.io/api/aquaponics/...`

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
