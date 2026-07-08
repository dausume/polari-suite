# Next-agent handoff — 2026-07-08 (evening)

Written for the agent that picks up after isle-core comes online.
Two workstreams ran this session: **context-scoring / political
accountability** and a **new aquaponics module** (self-watering pot
sim). Full logs in memory: [[context-scoring]], [[aquaponics-module]].

## 0. FIRST THING when isle-core is reachable
Dustin's ORIGINAL, fuller self-watering-pot spec never reached this
session — the `aquaponics/` module was rebuilt from his restatement.
An earlier version may live on the isle-core Claude instance.
- `ssh isle-core` (detts@192.168.0.24), read
  `/home/detts/.claude/projects/-home-detts-Isle-Mesh/memory` and any
  pot/aquaponics notes/history there.
- Reconcile against `AQUAPONICS_MODULE_PLAN.md` + the built module.
  Correct divergences (geometry, plant model, extra requirements)
  BEFORE building aqp-3, since that's where rework would cost most.

## 1. State of play

### Deployed + live-verified on staging A (192.168.0.210)
- Scoring scr-1..6, 8, 12a, 15, 16 — backend + frontend. Pages:
  `/scoring`, `/scoring/accountability`, `/scoring/survival`.
- Aquaponics aqp-1/2/4/5/6 — backend ONLY (deployed end of session;
  no frontend pages exist for aquaponics yet).

### Committed but NOT built / NOT deployed
- **aqp-3 hydraulics** — the one remaining aquaponics phase (details
  in §3).
- Scoring **scr-7** (scorecard node ↔ Polari wiring) and Part-2
  **scr-9..14** (promises, events, attribution, definitions,
  judicial) — all DESIGNED in `SCORING_ACCOUNTABILITY_PLAN.md`, none
  built.

### PSC (political-scorecard-node) — NOW RUNNING (combined stack)
- End of session the stack was SWITCHED from the prf-node-only compose
  to the **suite-root combined** `docker-compose.staging-nip.yml` (both
  nodes, shared pol-* infra, pol-proxy routing both). PSC builds clean
  after its revisions (psc-backend maven BUILD SUCCESS, psc-frontend).
  Live: psc.192.168.0.210.nip.io + api.psc.192.168.0.210.nip.io (200);
  prf.192.168.0.210.nip.io unchanged (all scoring + aquaponics intact,
  re-seeded fresh — 1533 instances, no backfill needed on a clean vol).
- The `.generated/` configs were stale (IP 10.0.0.101) — regenerated
  for 192.168.0.210 via `./nip-staging-setup.sh` (no sudo needed;
  docker works without sudo here despite the script's printed hint).
- TRADEOFFS of the combined stack vs the old prf-node stack: NO twin
  (prf-b-*), NO dask workers, NO msci-engines remote worker (those
  compose files: polari-rf-node/docker-compose.{twin-b,dask,
  msci-engines}.yml — still exist, can be run alongside; twin-b + dask
  projects were left running on their own ports 8081-8083). The
  beeswax@L1 FEM demo reads persisted last_result_json so it works
  without the msci-engines worker.
- I did NOT modify PSC source; scr-7 (scorecard ↔ Polari /api/scoring
  wiring) is still unbuilt — PSC runs on its own mocks/backends.
- Restart/stop the combined stack from suite root:
  `export LOCAL_IP=192.168.0.210 && docker compose -f
  docker-compose.staging-nip.yml --env-file .generated/.env.staging
  up -d` (or `down`). GOTCHA: prf-backend healthcheck start_period
  (45s) is shorter than a cold seed — it flaps 'unhealthy' on first
  `up` and blocks pol-proxy; just re-run `up -d` once it's healthy and
  the proxy starts. (Consider raising prf-backend start_period.)

### Branch topology — NEEDS A MERGE DECISION
Everything is STACKED on one line of dev branches in polari-framework
(each phase branched off the previous):
```
dev-scr-4-time → dev-scr-5-assertions → dev-scr-6-politicians →
dev-scr-8-voting → dev-scr-15-media-accuracy → dev-scr-16-group-bias →
dev-scr-12a-survival → dev-aqp-1-pot → dev-aqp-2-media →
dev-aqp-4-plant → dev-aqp-5-atmosphere → dev-aqp-6-impact (HEAD)
```
Angular repo: scoring UI on `dev-scr-12a-survival` (and the
scr-15/16 sections on `dev-scr-15-media-bias`). Superproject
polari-rf-node on dev-jinja-family (submodule pointers uncommitted —
normal here).
- Nothing merged to main yet. Before/with Dustin, decide: fast-forward
  the whole stack to a dev integration branch, or cherry-pick per
  feature. The stack is linear so a single merge of the aqp-6 tip
  carries all scoring + aquaponics work.

## 2. Selftests (all green) — run from polari-framework/
Scoring: `python3 -m scoring.selftest_scoring` (65), `.selftest_assertions`
(48), `.selftest_politicians` (21), `.selftest_elections` (18),
`.selftest_media` (16), `.selftest_bias` (15), `.selftest_survival` (21).
Aquaponics: `python3 -m aquaponics.selftest_pot` (20),
`.selftest_growth_media` (17), `.selftest_plant` (16),
`.selftest_atmosphere` (10), `.selftest_system` (13).

## 3. aqp-3 — hydraulics simulation (the remaining phase)
The framework has NO fluid-flow physics (materials survey confirmed).
This phase ADDS it. Design, in-idiom (sim survey findings):
1. **New engine** — a scikit-fem scalar Darcy/diffusion solver in
   `materialsScience/engines/` (structurally identical to
   `fem_engine.effective_conductivity` — Laplace/Poisson). Register a
   key in `scale_execution.ENGINE_REGISTRY` (e.g. `fem.darcy-flow`)
   + an `EngineModelTemplate` row. This finally makes the pot
   materials' `hydraulicPermeability` priors (aqp-1) real.
2. **Reduced reservoir model first** — a 1D reservoir + Darcy-through-
   soil ODE, NOT 3D CFD. Expose a fidelity knob (the MVW convection-
   knob idiom). Water level fills from input holes, drains at the
   lowest output lip (the maintained level aqp-1 already computes),
   capillary rise into the soil (aqp-2 field capacity / conductivity).
3. **As a simulation** — sims are DATA: one `*SimState` class per
   subsystem (reservoir level, soil moisture grid — use the
   `WindFieldGridState` `cells_json` matrix convention), a
   `SimulationDefinition`, no-code step SolutionDefinitions +
   `SimulationExecutionSolution` wrappers, seeded via a
   `*_seed.py` appended to the sim SEED lists + registered in
   `polariServer._seedSimulations` seed_pairs. Worked templates:
   `simulations/material_space_seed.py`, `wind_field_seed.py`.
4. **Coupling** — `SimulationCouplingDefinition` rows feed
   reservoir→soil-moisture→root-uptake, and evaporation/transpiration
   (aqp-5 VPD) back onto the reservoir. Assemble under a
   `MultiScaleSimulationDefinition`. `apply_couplings` +
   `run_stage_search` (the "batch_refine") are the machinery.
5. **The question to answer dynamically**: "does slot angle X still
   drain by gravity, and does the pot stay self-watering?" — aqp-1
   answers it statically; aqp-3 answers it in time.
6. Then feed dynamic soil-moisture / actual-uptake back into the
   aqp-6 survival + impact reports (they currently use delivery-rate
   estimates).

## 4. Other open work (lower priority, all designed)
- Aquaponics frontend pages (none exist): a pot-geometry editor +
  validation view, media/plant/atmosphere/system dashboards, and a
  SimSpace3D pot render (aqp-1 deferred the render).
- Scoring scr-7 + scr-9..14 (see SCORING_ACCOUNTABILITY_PLAN.md).
- Live vote ingestion: Congress.gov v3 key → api-profiler → POST
  /api/scoring/ingest-votes (seam is built + tested, not run live).

## 5. Deployment recipe + gotchas
From `polari-rf-node`:
`export LOCAL_IP=192.168.0.210 && docker compose -f
docker-compose.staging-nip.yml build backend frontend && docker
compose -f docker-compose.staging-nip.yml up -d backend frontend`
(~150s backend restore). API host `api.prf.192.168.0.210.nip.io`,
app `prf.192.168.0.210.nip.io` (nip.io names, NOT the bare IP).
- GOTCHA (recurring): a redeploy restores the EXISTING volume, so
  pre-existing rows only get class DEFAULTS for newly-added columns —
  backfill via CRUDE PUT (`curl -sk -X PUT $API/<Class> -F
  "polariId=<id>" -F 'updateData={"field":"json-string"}'`, ids from
  `GET /<Class>`). This bit the scoring rows (term temporal/tags,
  group member-contributors, evidence outlet_name — all patched live).
  Brand-new classes (all aquaponics) seed cleanly with no backfill.
- GOTCHA: literal `@` in Angular templates breaks the build — use
  `&#64;`.
- GOTCHA: falcon POST bodies MUST read `request.bounded_stream`
  (raw `stream.read()` blocks the WSGI worker).
- Host python can't import polariServer (PyJWT mismatch) — validate
  with per-module selftests + `ast.parse`, not a full server import.

## 6. Conventions
Branch per phase; selftest per module; labels/derived values travel
with their numbers; knobs-and-suggestions (every capability = a knob
+ an evidence-bearing suggestion, never auto-applied); object-
coherence (every capability is a configurable row); honest absence
(refusals name the knob; missing data is data). See standing memory:
[[knobs-and-suggestions]], [[object-coherence]],
[[file-size-decomposition]], [[branch-per-confirmed-phase]].
