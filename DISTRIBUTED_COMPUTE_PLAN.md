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

## Twin-build feasibility (MEASURED 2026-07-03): YES, comfortably
Host: 15.9 GB RAM (~10 GB available), 65 GB disk free. Current stack uses ~813 MB actual
(keycloak 515 is the heavyweight; backend 108). Images are REUSED by a second instance →
zero added image disk; volumes trivial (backend-data 1.6 MB). **Shared-infra twin (the
plan): one Keycloak (two realms/clients) + one MariaDB + one MinIO (per-instance buckets)
serve both; second backend+frontend ≈ 120–450 MB RAM, ~0 disk.** Even a nothing-shared
full twin (+~813 MB) fits. Sizing note: raise backend mem_limit 384 MB → ~1 GB per
instance for in-container Dask clusters (host has headroom).

**The twin test that matters (Dustin):** Dask parallelizing the MATERIALS simulation
across BOTH instances — instance A's search farms attempt tasks to workers on A and B
(dask scheduler on A, worker containers on both, over the polari-link network; attempt
tasks are already pure/manager-free by Track-1 design, so cross-instance is "the same
tasks, remote workers").

## Track 3 — GitHub-modular samples (after the twin + cross-instance Dask work)
**Goal (Dustin):** finalize modularization so ALL samples (pendulum, wind, materials, the
demo composition) are stashed in separate GitHub projects as JSON configurations, loaded
on demand via the GitHub API as MODULES — the application transforms and gains capabilities
by pulling configuration objects from GitHub projects; unloading sheds them (trajectory
step 4, consolidation, made real; roadmap Milestone D grown up).

Design essentials:
- A module = a JSON bundle: manifest (name, version=commit SHA, dependencies between
  modules) + definition objects (sim defs, solution defs, matrix/equation defs, scenes,
  bindings, msim compositions, IC interfaces, step-0 seed rows) + CLASS DEFINITIONS IN
  CONFIGURATION FORM (the /createClass path proves classes-as-config works).
- The prerequisite work: migrate the hand-coded sample *SimState classes into
  createClass-style configuration + build the EXPORTER (walk live DB content for a chosen
  scope → module bundle JSON) — export what exists today, don't re-author it.
- ModuleSource / loaded-module registry objects; loader = fetch (GitHub contents API or
  raw), validate manifest, seed idempotently (the seeding machinery already is the
  importer); unload = remove the module's objects. Knob + suggestion per the standing
  principle (e.g. "this node never uses mapping — unload the geo module").
- **GitHub is A distribution channel, not THE one (Dustin, 2026-07-03).** Every Polari
  serves its own MODULES API — instances are module registries for each other:
    * `GET /api/modules` — installed AND installing modules (manifest summaries: name,
      version=SHA, dependencies, status) so peers can PROBE what a node has/is getting;
    * `GET /api/modules/{name}` — the full bundle JSON, so a peer can ask for a copy and
      install it. Modules are just JSON; serving them over the normal API is trivial.
  ModuleSource kinds unify: `github` | `git` | `file` | `peer` (another Polari's base
  URL) — one loader, four fetchers. The twin handshake includes the modules API from day
  one (peer-announce carries the module inventory), so "what does my peer have installed"
  is part of the first integration, and node specialization via pulling modules FROM PEERS
  becomes the native path (trajectory step 3 feeding step 4).
- **Localized-mission nuance:** no source kind is a runtime dependency — bundles cache
  locally after fetch; a fully-local deployment (file/peer/self-hosted git) never phones
  home.

Sequence confirmed with Dustin (2026-07-03): Dask track 1 (in flight) → twin build (shared
infra, INSTANCE_ID parametrization, mem bumps) → cross-instance Dask materials search →
GitHub-modular samples (exporter → sample repos → loader).

## Track 4 — Polari node network: distributed multi-scale (Dustin, 2026-07-03)

**Goal:** a parent Polari controlling member nodes so EXTRA-COMPLEX multi-scale
simulations split across servers: parts of the composition live on one Polari, parts on
another, and the multi-scale simulation works in that situation — complex simulation on
hardware the average person has (many normal machines instead of one big one).

Design pillars:
1. **Roles**: parent/coordinator + members. The COORDINATING/OVERALL MODULE — the
   MultiScaleSimulationDefinition with its stages, couplings, run-set pairings, and the
   new PLACEMENT MAP ({space/sim → node}) — lives on BOTH parent and members, so each
   node knows its responsibilities in coordinating data for the overall simulation.
2. **Placement via modules (dependency: Track 3 is a prerequisite)**: only the sub-module
   needed for computing a node's sub-section is installed there; the parent can instruct
   a member to install a module (peer-fetch in reverse / member pulls from parent).
3. **INFORMATION HIDING (Dustin's principle)**: nodes may NOT know how peers do their
   simulations at depth. The coordination contract between nodes = the COUPLING SURFACE
   (what field, sampled how, into which keys) + stage gates/derives + run pairings —
   never the peer's solutions/equations/internal state. Modules API distinguishes PROBE
   (manifests: what a node offers) from FETCH (bundles: how it computes) — permissioned
   separately. Tolerant of nodes built by different people to different depths.
4. **Distributed execution semantics**: lazy-pull couplings cross nodes via the peer:
   scheme; stage searches run on the node owning the space (its Dask/processes backend);
   the parent orchestrates run-sets (create paired runs on owning nodes, drive stepping,
   gather status/verdicts); ZOH time-alignment already tolerates network latency by
   construction (sample latest ≤ t).
5. Trust: parent-member shared tokens now (twin's mechanism), proper federation later.

Sequencing (updated): twin build (in flight) → cross-instance Dask materials search →
peer-sourced coupling (2-node, hand-placed) → Track 3 modules (exporter + loader + peer
serving) → Track 4 (placement map, parent orchestration, member install instruction,
probe/fetch permissions). The twin IS the 2-node lab for all of it.

## Convergence with Isle-Mesh (discovered 2026-07-03)
Dustin's OTHER project (on isle-core, with its own Claude instance + memory): **Isle-Mesh**
— an OpenWRT-router-VM VLAN system (`isle create/join`, `.isle` = apps within one island,
`.arch` = linked isles, `.mesh` = full mesh) — IS the network layer Track 4's "linked over
a vlan" node network should ride. Mapping: one Polari node's stack per isle (.isle DNS
names for PeerNode base_urls); the parent/member network = an archipelago; our same-host
polari-link bridge is the stand-in Isle-Mesh replaces across machines. The cross-host twin
step should target an isle (static-IP wired VLAN per Isle-Mesh's own plan) rather than raw
LAN IPs. Both projects converged on the same architecture from opposite ends.
