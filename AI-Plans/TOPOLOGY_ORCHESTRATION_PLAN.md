# Topology Orchestration Plan — core-instance topology context, CLI-driven
# swarm allocation, and the Topology tab

_Dustin 2026-07-09 (planned for the next instance): the CORE Polari
instance carries the FULL CONTEXT of the overall swarm/compose topology
and all configurations, tied directly into the pol CLI logic. Dual
capabilities: author complete configurations expressing ANY combination
of swarm logic, and BUILD any such combination through the CLI once
swarm nodes are connected — allocating services from the CLI. A
top-level TOPOLOGY tab in Polari configures the number of prf/psc/other
instances, database kinds, and the connections between them; tracks the
MODULES per polari-rf instance and their interdependencies (e.g. one
rf carries FEM, another DFT, the core carries multi-scale models that
depend on both); drag-and-drop dependencies between instances with
processing shifting around intelligently._

## 0. Substrate this stands on (all built + verified 2026-07-08/09)

| Piece | Provides |
|---|---|
| `pol-build/registry/services.yml` | 19 service kinds + `interconnects:` (instance-wiring artifacts) — the STATIC vocabulary of the topology |
| `pol-build/manifests/*` + render.py + stackify.py | ANY declared bundle → compose file or swarm stack, byte-parity-gated |
| `pol` CLI (compose/swarm/deploy/db/modules/config/registry) | the actuator: single-node swarm proven (polari-engines live), ssh deploys w/ preflight (nodes.yml), start/rebuild/stop state |
| Credential substrate | every instance self-generates its secrets on setup — new instances need NO secret distribution |
| `polariPeers/` (PeerAgreement, mesh_facts) | instance↔instance admission + trust (twin proven; peer-token interconnect) |
| `moduleService/` (moduleDiscovery, module_dependency_tracker) | module inventory + dependency edges INSIDE an instance |
| msci-engines / dask delegation | the "processing shifts" seam: MSCI_ENGINES_URL-style delegation that degrades to an honest suggestion when the target is absent; cross-instance dask proven (5/5 split) |
| Angular DisplayDefinition + D3 no-code editor | config-driven pages + an existing drag/drop node-graph surface to build the Topology tab on |

## 1. Principle: topology is DATA in the object tree (object-coherence)

Desired state lives as CRUDE-exposed classes on the CORE instance;
files (`registry/services.yml`, `manifests/*.yml`, `nodes.yml`) become
the INTERCHANGE format the CLI renders FROM those rows (and can seed
INTO them for bootstrap). Observed state is reported, never guessed;
drift between desired and observed is surfaced, never auto-corrected
(knobs-and-suggestions).

### Data model (new module `topology/`, sibling of scoring/aquaponics)
- **PolariNodeMachine** — a physical/VM host: ssh alias, arch, mem,
  roles, swarm membership (manager/worker/none). Seeded from nodes.yml.
- **OrchestrationTarget** — compose | swarm | isle (future), per group.
- **InstanceDefinition** — one prf/psc/other instance: kind (registry
  service-kind ref), count/replicas, env tier, host binding (machine or
  swarm placement constraint), DB BACKEND choice (sqlite | mariadb |
  mariadb+keydb — the pol db vocabulary), image tag.
- **ModuleAssignment** — module (materialsScience.fem, .dft, scoring,
  aquaponics, simulations, …) → InstanceDefinition; carries
  enabled/planned state. (Module enable/disable per deployment is a
  KNOWN missing knob — this is where it gets built; `pol modules`
  currently refuses honestly.)
- **ModuleDependencyEdge** — moduleA@instanceX DEPENDS-ON moduleB —
  resolved to a PROVIDER instance (e.g. multiscale@core → fem@rf-2,
  dft@rf-3). Mirrors module_dependency_tracker edges, lifted to the
  cross-instance level.
- **ServiceConnection** — typed by the registry `interconnects:` keys
  (db-credentials, keycloak-client-secrets, peer-token, scorecard-api-
  seam, …): which generated artifact wires the two endpoints.
- **TopologyDefinition** — the whole desired graph (instances,
  assignments, edges, connections, target mode) + validation state.
- **TopologyObservation** — what's ACTUALLY running (per node: stacks,
  services, tasks, module inventory), timestamped, reported by the CLI.

## 2. Dual capability A — author ANY combination (config → build)

1. `topology/` module + seeds mirroring today's reality (core suite on
   staging A, engines swarm stack, twin/dask, isle-core+lightweight
   machines) so the first Topology page shows TRUTH, not placeholders.
2. Exporter: TopologyDefinition → `pol-build/manifests/topology-<name>/`
   (bundle manifests + a stack-set manifest + nodes slice). Pure data →
   the EXISTING render/stackify pipeline builds it. Any instance count,
   any db mix, any module split expressible.
3. Validator (evidence-bearing findings, aqp-1 idiom): port collisions,
   db backend vs volume state, module dependency edges without a
   provider, swarm placement onto machines not in the swarm — each
   finding NAMES the knob/action that fixes it.
4. `pol topology pull|push|render|diff` — CLI ↔ core-instance sync over
   the CRUDE API (`/api/topology/...`): pull rows → files, push files →
   rows, render → manifests, diff → desired vs observed drift report.
5. **PORTABLE EXPORT (Dustin 2026-07-09)**: `pol topology export <name>`
   emits a SELF-CONTAINED, CREDENTIAL-FREE topology package —
   `topologies/<name>.topology.yml` (single file: instances, module
   assignments, dependency edges, connections, db choices, node
   requirements + a schema version) — the durable artifact of a
   manually-made configuration (Topology-tab-built or hand-authored).
   `pol topology deploy <file|name> [--plan]` re-deploys it ANYWHERE:
   validate → push to the core as rows → render manifests → ensure
   credentials on targets (self-generating setup) → apply. Round-trip
   guarantee: export(deploy(X)) == X (parity-gated like everything
   else). Packages are safe to commit/share — secrets always
   regenerate on the target, never travel in the package.

## 3. Dual capability B — build/allocate through the CLI (build → run)

1. `pol swarm join <node>` — drives nodes.yml machines into the swarm
   (ssh + join-token; preflight exists). Multi-node swarm on
   lightweight + isle-core is the acceptance test.
2. `pol allocate <service-or-module> <instance|node>` — writes the
   ModuleAssignment/InstanceDefinition change (via topology push),
   re-renders the affected manifests, and does a TARGETED deploy
   (stack update or per-node compose up). Placement constraints emitted
   into stackify output (`deploy.placement.constraints`).
3. `pol topology apply [--plan]` — reconcile desired → running:
   ordered actions (render → secrets/env ensure on target → stack
   deploy/update → verify endpoints), `--plan` prints without acting.
   Reuses record_build so start/rebuild/stop keep working.
4. Observation reporter: `pol topology report` (cron-able) posts
   TopologyObservation to the core; suite/psc/rf instance health via
   existing healthchecks.

## 4. Topology tab (top-level page, like Materials)

- Menu entry `/topology`. DisplayDefinition-driven; graph surface reuses
  the D3 no-code editor interaction model (the drag/drop + node LOD
  machinery already exists — see matrix-equation node work).
- **Instances view**: cards per InstanceDefinition (kind, count
  steppers for prf/psc/other, db-backend picker, env tier, host/
  placement). Adding an instance = new card → validate → export/apply
  via the CLI seam (page never shells out; it writes rows; the CLI or a
  backend runner applies).
- **Modules view**: module chips ON instance cards; DRAG-AND-DROP a
  module chip between instances → rewrites ModuleAssignment +
  re-resolves ModuleDependencyEdges; edges render as arrows with
  status color (provider reachable / missing / degraded). The
  FEM/DFT/multiscale example is the seed demo: multiscale@core shows
  red edges until fem and dft chips land on reachable instances.
- **Connections view**: ServiceConnections typed by interconnect;
  clicking one shows the generated artifact that wires it (from the
  registry) — full accountability of "what config makes this link".
- **Drift banner**: desired vs latest TopologyObservation; every drift
  row carries the suggested `pol` command (suggestion, never auto-run).

## 5. Intelligent processing shift

Phased honestly:
1. **Routing (auto, safe)**: cross-instance module calls resolve the
   provider FROM ModuleDependencyEdges (registry of provider URLs
   replaces hardcoded MSCI_ENGINES_URL). If a provider is down, degrade
   to the existing honest-suggestion behavior. Load-aware choice among
   MULTIPLE providers of the same module (dask-style) — runtime routing
   may auto-pick; it changes no configuration.
2. **Reallocation (suggested, one-click)**: when observations show
   sustained imbalance/unreachability, emit a SUGGESTED reallocation
   (move dft@rf-3 → rf-2, evidence attached: latency/failure counts).
   Applying = the same `pol allocate` path. Never auto-applied.
3. **(later) Automatic shift policies** — opt-in per TopologyDefinition
   knob, only after 1+2 have history to justify trust.

## 6. Phases (branch per confirmed phase)

- **top-1** backend `topology/` module: classes + selftests + seeds
  mirroring current reality; CRUDE routes `/api/topology/*`.
- **top-2** `pol topology pull|push|diff` + observation reporter
  (CLI-side; files as interchange).
- **top-3** exporter+validator: TopologyDefinition → manifests →
  render/stackify parity for the CURRENT topology (round-trip proof:
  exported manifests reproduce today's 13 bundles + engines stack) +
  the PORTABLE PACKAGE format: `pol topology export|deploy` with the
  export(deploy(X))==X round-trip test — current staging topology
  exported as `topologies/staging-a.topology.yml` is the first package.
- **top-4** multi-node swarm: `pol swarm join` lightweight (+isle-core),
  placement constraints, `pol allocate` targeted deploys. ⚠️ push
  branches to GitHub first — remote nodes pull the public repos.
- **top-5** Topology tab v1: instances + connections views (read/write
  rows, validation findings, drift banner).
- **top-6** modules view + drag-and-drop assignment + dependency edges;
  FEM/DFT/multiscale seed demo (msci-25/26/27 L2/L3 engines stay ON
  HOLD — the demo uses the EXISTING fem/dft engine split).
- **top-7** provider routing (registry-resolved delegation URLs) +
  degraded-state surfacing.
- **top-8** suggested reallocation (evidence-bearing, one-click apply).

## 7. Standards
Knobs-and-suggestions (no auto-apply of config changes, ever);
object-coherence (every capability = a row on the tree, configurable at
the object); honest absence (missing provider/unjoined node = named
refusal + the exact command); file-size discipline (one class family
per file; topology/ mirrors scoring/'s layout); selftest per module;
byte/semantic parity gates for everything the exporter generates.
