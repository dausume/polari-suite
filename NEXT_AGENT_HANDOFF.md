# Next-agent handoff — 2026-07-09 (topology orchestration round COMPLETE)

The 2026-07-09 overnight session built ALL of top-1..top-8
(TOPOLOGY_ORCHESTRATION_PLAN.md) — built, committed branch-per-phase,
and live-verified on staging A + the lightweight node. Full reference
+ gotchas in memory [[topology-orchestration]].

## 0. FIRST THINGS
- **NOTHING IS PUSHED to GitHub.** Local branch stacks:
  suite `dev-top-4-multinode` (over dev-top-3 ... dev-build-security),
  polari-cli `dev-top-4-multinode`, polari-rf-node
  `dev-topology-orchestration`, polari-framework `dev-top-1-topology`,
  polari-platform-angular `dev-top-5-topology-tab`. All repos PUBLIC —
  push before any `pol deploy run` (nodes pull GitHub).
- The LIVE system now spans TWO machines: staging A (core, swarm
  manager) + lightweight (swarm WORKER running the polari-engines
  stack task). `pol topology diff` = NO DRIFT across both.

## 1. What topology orchestration now is
- **Topology = rows on the core** (`topology/` module, /api/topology/*):
  machines, instances, module assignments, dependency edges, typed
  connections (registry interconnects), desired vs observed.
  Seeds mirror staging-a truth. 52-check selftest
  (`pol modules selftest topology`).
- **CLI**: `pol topology status|graph|validate|pull|push|diff|report|
  render|apply|deploy|assign`, `pol allocate`, `pol swarm join`.
  Files (topologies/*.topology.yml, nodes.yml) are interchange; rows
  are truth. render → manifests/topology-<name>/ is byte-parity-gated
  against the generated bundles.
- **Portable packages**: topologies/staging-a.topology.yml (committed,
  credential-free). `pol topology deploy <pkg>` = push→render→apply;
  round trip proven live.
- **Multi-node**: `pol swarm join lightweight` done (node label
  polari.machine=*, topology row auto-updated). `pol allocate engines
  lightweight` moved the stack there live (image via docker save|ssh
  load; placement by label; pyscf still served through the routing
  mesh). isle-core NOT joined yet.
- **Topology tab** (/topology): drift banner (carries suggested pol
  commands incl. top-8 reallocation suggestions), validation findings,
  instance cards, connections w/ artifacts, D3 graph, CDK drag-drop
  module chips → /assign. DEPLOYED in prf-frontend.
  **⚠️ Dustin's browser/visual review pending** (assign was
  live-verified via CLI only).
- **Provider routing (top-7)**: materialsScience delegation ladders
  MSCI_ENGINES_URL (knob wins) → topology-resolved LIVE provider →
  honest refusal. The suite backend now gets pyscf WITHOUT the env
  var. Failures mark edges degraded (amber in the tab) and yield
  one-click reallocation suggestions in drift (top-8).

## 2. Live state
- staging A: combined suite (prf+psc, all healthy), twin-b, dask
  (project polari-dask), swarm manager. lightweight: swarm worker,
  runs polari-engines task (:9500 via mesh). Both nodes observed
  (pol topology report [--node lightweight]).
- ⚠️ LOCAL_IP must be exported for ANY docker compose command on
  docker-compose.staging-nip.yml (minio crash-loops otherwise).

## 3. Follow-ups (none blocking)
- Push the branch stacks; Dustin's tab review; validator render-level
  checks (ports); sustained-failure history for reallocation;
  docker-secrets for swarm; registry-based image distribution
  (replace save|load); join isle-core when wanted.

## 4. Parked application work (unchanged)
- scr-7 scorecard↔Polari wiring, scr-9..14; aqp-3 hydraulics;
  aquaponics frontend pages; live vote ingestion.

## 5. Gotchas carried forward
- prf-backend healthcheck flap on cold seed; :3000 binds after seeding.
- API-created treeObject rows need explicit saveInstanceInDB.
- docker exec python3 = fresh process — provider_registry.MANAGER only
  lives in the server; test routing via HTTP endpoints.
- ssh'd docker --format strings with inner quotes = ONE quoted string.
- Angular templates: literal `@` breaks builds — use `&#64;`.
- falcon POST bodies read request.bounded_stream.
- Host python can't import polariServer — selftests run in-container.
