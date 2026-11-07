# Topology layers: Polari vs isle (tpl)

**Status:** PLAN, 2026-11-06; D-tpl-1..3 taken; tpl-0 + tpl-1 INSTALLED on core (boot3); tpl-4 source-accepted (3ba6b8fc, not built); tpl-6 BUILT as source 2026-11-07 (plan-only live); tpl-2 design written (AI-Notes/designs/TOPOLOGY_PEERING_DESIGN.md, for the user's review); `pol topology --api / --json / isle-needs / example-rows` built (polari-cli 974d14c, 79abde8). The user's go for the plan and for tpl-0/tpl-1/tpl-3 source work (steps 1, 3, 4 of the proposal).
Nothing live changes without a separate go.

## The ask (the user, 2026-11-06)

> Polari topology is supposed to be a real independent topology that shows a deeper layer of topology ... available on the
> Isle App. So we would be able to switch between the topology focused on the isle/actual networking setup, and the view
> focused on Polari modules and apps interconnecting and their logic ... able to operate mostly at the polari level without
> the isle.

> it is fine for the isle and polari to be co-dependent to some extent on some features where it makes sense but we should
> have clarity that certain information needs an isle to be usable and build that in. We just need a clean plan for where
> they should be fully separate, and where there is overlap but certain features live primarily on the polari side or isle side.

## Two layers

| Layer | Answers | Lives in | Works without the other? |
|---|---|---|---|
| **Isle** (network) | Which devices exist, their agents, addresses, names, certificates, routes, router, installed isle apps, updates | Isle CLI + agents; mirrored in Polari by the `islemesh` module (`/api/islemesh/graph`) | Yes. The isle runs with no Polari backend at all. |
| **Polari** (logic) | Which Polari instances exist, which modules each runs, which module needs which, which engine serves which capability, which service wires to which, who owns which object, which Polari Apps are composed of what | `topology/` rows (`/api/topology/*`, the `/topology` page) | **Must** be yes. Today it is no (see Gaps). |

The Polari side KEEPS ITS OWN `/topology` page, standalone. The user, 2026-11-06: "the Polari side Topology should also
retain it's own page as well so it is still possible to spin them up via specific docker compose files and them be able to
work". A compose-only stack (no isle) opens `/topology` directly and it works; the Isle App tab embeds that same page.

The Isle App's topology screen gets **tabs**: **Isle Topology** (the network layer, the DEFAULT tab) and **Polari Topology**
(the logic layer). The user, 2026-11-06: "the topologies get multiple tabs, where one is for the Polari and one is for the Isle
Topology where the Isle Topology is the default". Selecting a
Polari instance on the Network view opens its Polari view; selecting an engine edge on the Polari view highlights the
devices it crosses.

## Separation map

### Fully Polari (no isle needed, ever)
- Instances, module assignments, module dependency edges (`InstanceDefinition`, `ModuleAssignment`, `ModuleDependencyEdge`).
- Object ownership chain (class -> module -> instance -> database).
- Polari Apps (module compositions, plan-first deploy as rows).
- Engine resolution ladder: knob -> local binary -> local image -> binding row -> topology provider -> refusal.
- Service connections between Polari services (`ServiceConnection`) and their generated artifacts.
- Drift (desired rows vs reported observation), reallocation suggestions, testing over topology.
- Benches, simulations, everything that consumes the above.

### Fully isle (no Polari needed, ever)
- Devices, agents, DHCP leases, `.isle` DNS, the CA and certificates, proxy routes, the router, segments.
- The isle app registry, `isle store install`, `isle update plan/apply`, `isle reconcile`, operation status/retry.
- Trust distribution (system store, NSS, Firefox policy).

### Overlap: Polari primary (isle feeds or caches)
| Feature | Authority | The isle's role |
|---|---|---|
| Module placement | `ModuleAssignment` rows (`topology/placement_truth.py`, already the rule) | Its registry `modules:` strings are a cache refreshed from `placement_report()` |
| Engine binding | `EngineProviderBinding` row on each backend | Announces engines it hosts (`/api/islemesh/ingest/engine`); never decides the binding |
| Resource ledger (consumed vs available) | `topology/device_resources.py` | Agents report device capacity as observations |

### Overlap: isle primary (Polari records)
| Feature | Authority | Polari's role |
|---|---|---|
| Deploying a Polari instance onto a device | `isle polari instance deploy` | Records the `InstanceDefinition` + its observation; never executes on a device itself |
| Cross-device reachability (names, trusted HTTPS) | isle DNS + CA | Records edges and their health; reports failures as findings |
| Discovering engines on other devices | isle registry | Binds what the isle announces |
| Executing topology changes from the app | the Isle App via `pkexec isle ...` | Web views stay show-only (D-tnb, 2026-10-04) |

### Needs an isle (built in as an honest state, not an empty panel)
These features declare `requiresIsle: true` with a reason; with no isle the UI shows **"Needs an isle: <reason>"** and the
no-isle fallback, never blank or stale data.

| Feature | Without an isle |
|---|---|
| Automatic discovery of other devices and their Polari instances | Peers listed by hand (tpl-2) or `pol topology report` over ssh |
| Auto-routing to an engine on another device with no URL knob | Set the `*_ENGINES_URL` knob |
| Trusted HTTPS names for cross-device calls | The user's own TLS / plain dev URLs |
| Agent-observed device resources | `pol topology observe` over ssh, or "capacity unknown" |
| Running a placement change from the app | `pol allocate` / manual steps (suggestions only) |
| The Network view itself | Hidden; the Polari view still works |

## Gaps (found 2026-11-06 on the Electronics backend)

1. **Seeded fiction.** `topology/topology_seed.py` writes the 2026-07-09 dev snapshot (3 machines, 11 instances, 13
   assignments, 16 connections) into EVERY backend as reality. The Electronics backend shows instances that exist nowhere.
2. **No self-identity.** The isle's generator never sets `POLARI_INSTANCE_NAME`, so the backend calls itself `local` and
   has no `InstanceDefinition` for itself; its real modules appear in no assignment row.
3. **No observer on an isle.** The only correction path is `pol topology report` (dev CLI). The boot observation exists
   (`record_placement_observation`) but it attaches to `local`, not to a row the page shows.
4. **Engine bindings are invisible in the topology.** The `board` binding to the board-engines worker is a row, but no
   dependency edge or connection shows it.
5. **The isle feed failed.** The core's frontend deploy printed "topology report skipped (api unreachable)".
6. **Stale isle device.** The core's isle graph still lists a device under an old hostname next to its current name.
7. **No peering.** Without the isle, a backend cannot learn of any other Polari backend.

## Phases

- **tpl-0 Self-identity + no fiction** (Polari, source). ✅ BUILT 2026-11-06 (framework c5c7ec21, local): selftest 19/19,
  topology/islemesh regressions green, fresh isolated boot = self rows only + 6 benches applied, restart idempotent. The backend derives its instance name (knob
  `POLARI_INSTANCE_NAME`, else the deployment name, else the hostname) and upserts its own `InstanceDefinition`,
  `PolariNodeMachine` and one `ModuleAssignment` per running module at boot (idempotent). The July snapshot is seeded only
  when knob `POLARI_TOPOLOGY_SEED=example` (dev tiers keep it); default `none`. On a fresh backend this also applies the
  Bench topology specs (manual fix 13). Selftest: fresh manager -> only self rows; second boot -> no duplicates.
- **tpl-1 Engines and connections as edges** (Polari, source). ✅ BUILT 2026-11-06 (framework 0d239c0b, local): 30/30
  selftest; fresh boot + engine ingest + restart -> worker, resolved edge, frontend connection, validate clean. Rows appear at
  boot; econ's fix-11 consumer is asked to call describe_links on every bind/unbind. Each `EngineProviderBinding` and each configured frontend
  origin becomes a dependency edge / service connection marked `source: binding` / `source: config`, with live health from
  the existing ping.
- **tpl-2 Polari peering without the isle** (Polari; DESIGN FIRST, for the user's review). A backend publishes its
  self-description at `/api/topology/self`; peers come from a knob list (no isle) or from the isle registry (isle present);
  each backend merges peers' self-descriptions as rows marked `source: peer:<name>`, with age. Auth: the existing
  peer-token connection kind. DESIGN written 2026-11-07: AI-Notes/designs/TOPOLOGY_PEERING_DESIGN.md (reuses polariPeers'
  agreement handshake + PeerNode rows; decisions D-tpl2-a..c TAKEN 2026-11-07: /self open for now, peers from the agreement AND a
  configured list/file for pre-made configurations, peer wins for its copies). ✅ BUILT as source (framework df3077ae, 36/36).
- **tpl-3 Isle feed merged** (shared). Isle ingest writes rows marked `source: isle`; fix the core's report failure;
  retire stale device names (isle side, Codex). Each row shows where it came from.
- **tpl-4 Needs-an-isle states** (Polari UI). ✅ BUILT 2026-11-06 (framework a3e58cdd GET /api/topology/isle-needs, selftest 49/49;
  angular: the /topology panel + `?embed=1`; tsc/ngc clean for these files; not built into an image). The `requiresIsle` flags above, the honest panel text and the fallbacks.
- **tpl-5 The Isle App topology tabs** (isle side, Codex). Two tabs: Isle Topology (default, opens first) and Polari
  Topology, which embeds `/topology?embed=1&instance=<name>` for a chosen backend; cross-links as described above. More
  tabs may follow (the tab strip is the extension point).
- **tpl-6 Clean the live rows** (needs the user's go). Remove the July rows from the Electronics backend once tpl-0 ships.
  ✅ BUILT as source 2026-11-07 (framework c74a2442; selftest 41/41; Codex gate 8): GET /api/topology/example-rows (dry-run plan +
  provenance), POST .../retire {planDigest} (verified backup first, review-bound), .../backups, .../restore; CLI
  `pol topology example-rows`. Live dry run over the exports: polari-pol retire 49 / keep 0; core retire 48 / keep 6 / move 5.
  Order: pol member update (tpl-0 rows) -> plan per backend -> the user's go -> retire. Not in any image yet.
  Codex review fixes (framework e657e6ca, selftest_example_retire_durable 58/58): durable first, the first failure stops with
  retryPlanDigest (memory == database; restart + retry converge); restore keeps rows written since and is an exact inverse;
  execute doors fail closed (host operator via docker exec / sudo / pkexec, or a Polari admin identity). The user's ruling
  2026-11-07: un-appliable changes are PLANNED actions the Isle App runs in bulk after one password, with a summary
  notification; every plan carries plannedAction (the Isle half is Codex's). Staged on econ's cut/topology-20261106.

## Decisions

All three TAKEN 2026-11-06 (the user: "This sounds good"): the recommendations below.


- **D-tpl-1 Who aggregates the Polari view on an isle?** Recommendation: no hub; every backend merges its peers (tpl-2), so
  any backend shows the whole Polari layer and the core has no special role. Alternative: the core aggregates.
- **D-tpl-2 The July snapshot.** Recommendation: seeded only on dev (`example`), importable anywhere from
  `topologies/staging-a.topology.yml`.
- **D-tpl-3 Peering transport.** Recommendation: HTTPS pull of `/api/topology/self` on a timer plus the existing STOMP topic
  as a change signal; Reticulum later for off-isle peers.

## Ownership

Polari side (Claude): tpl-0, tpl-1, tpl-2, tpl-4, tpl-6. Isle side (Codex): tpl-5, the isle half of tpl-3 (report failure,
stale devices). The ingest contract in tpl-3 is agreed by both before either edits it.
