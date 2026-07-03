# Distributed Compute Plan — Dask parallelism + Twin-Polari

_2026-07-03, from Dustin's directives. Queued AFTER the resource-aware layer (in flight).
Two tracks that converge on the framework trajectory's step 3 (nodes integrate and
self-configure): Dask = compute-level parallelism INSIDE a node; Twin-Polari = run/space-
level distribution ACROSS nodes._

## Track 1 — Dask with the no-code system

**Goal:** things that CAN be parallel-processed from the no-code model ARE, via Dask,
without no-code authors doing anything special.

**Architectural constraint (drives everything):** Polari's manager is a process-singleton
with in-memory objectTables. Dask workers cannot share live state — so parallelize the
PURE parts and merge results, never share the manager.

**Parallelism the no-code model already exposes (in build order):**
1. **Solution-search candidates** (first target): every attempt is an independent run of
   the same sim from its own parameter point (material T/P grid = embarrassingly
   parallel). Worker shape: an attempt executes in a Dask worker with an isolated
   lightweight manager over scratch state; the worker returns the attempt's rows + gate
   verdict; the orchestrator merges rows back (the existing idempotent row-persist path)
   and proceeds first-valid. The orchestrator's batch loop becomes
   `backend.parallel_map(attempts)` with backends: `serial` (today's behavior, default) |
   `dask-local` (LocalCluster in-container) | later `dask-distributed`.
2. **Partials within a class step**: independent by design (contributions merge by op).
   Only worth distributing when a class has many/heavy Partials — gate on the measured
   step-cost profile (the resource layer tells us when a step is compute-bound!).
3. **Scenario-comparison fan-outs** and stage searches across substances.
4. **dask.array for huge field grids** (matrix-equation exprs already vectorized via
   numpy; swap np→dask.array per size threshold) — later, driven by real need.

**Integration points:** an `execution_backend` setting (sim def or server level);
`multi_scale_search.run_stage_search` gains the backend hook first; resource layer's
per-step timing decides WHEN parallelism is even worth suggesting (another auto-suggest
kind: "this search is compute-bound — enable parallel attempts").

## Track 2 — Twin-Polari (two linked instances)

**Goal:** a `twin-polari-build` launching TWO Polari instances via docker compose, linked
over a private network, able to talk to each other — the proving ground for node
integration.

**Answer to the open question (can compose do it?): YES for the network; the supplement
needed is INSTANCE PARAMETRIZATION, not network plumbing.**
- Same-host twin: a shared external docker network (`docker network create polari-link`;
  both stacks declare it `external: true`) gives cross-stack name resolution + isolation.
  No VLAN hardware needed.
- Real 802.1Q VLAN / cross-host on the LAN: compose supports `macvlan`/`ipvlan` drivers
  bound to a physical NIC (per-host). Cross-host could alternatively ride WireGuard.
- What actually needs supplementing (the current staging setup assumes it is ALONE):
  container names (prf-backend…), compose project name, host ports, nip.io hostname
  namespace (one LOCAL_IP), TLS cert SANs, Keycloak realm/clients, data volumes.
  → parametrize staging-setup/env generation with an INSTANCE_ID (a/b): `prf-a.*` /
  `prf-b.*` hostnames, per-instance cert issuance (CA toolkit already env-aware),
  suffixed volumes + project names, distinct port blocks; plus the shared `polari-link`
  network joined by both backends.
- **First integration handshake (keep it small):** each instance gets a PeerNode
  definition row (name, base URL on the link network, status) + a `GET /api/peers/ping`
  + a startup peer-announce; prove instance A can list instance B's SimulationDefinitions
  over the link (auth: start with the internal network trust + a shared token; Keycloak
  federation later). THEN the interesting step: a coupling whose SOURCE lives on the peer
  (remote run sampled over HTTP — the coupling plumbing's `source` resolution gains a
  `peer:` scheme). That makes twin-polari immediately meaningful to multi-scale instead
  of a bare network demo.

**Sequencing:** resource-aware layer (in flight) → Dask track 1 target (parallel search
attempts, serial default preserved) → twin-polari build + ping/list handshake → peer-
sourced coupling. Each its own phase branch + Dustin checkpoint.
