# Resource-Awareness + Module-Admission Planning — Plan

**STATUS 2026-07-09: ✅ ALL FOUR PHASES BUILT + LIVE-VERIFIED** on the
3-node staging swarm. Branch stack (both repos, framework +
polari-rf-node): `dev-res-1-node-inventory` → `dev-res-2-profiles` →
`dev-res-3-measure` → `dev-res-4-admission`. Selftests:
node-resources 28/28, profiles 30/30, measure 15/15, admission 23/23
(+ topology 52/52 and the 22/22 live-API smoke unbroken). Live:
all 3 nodes observed (boot self-heals), admission verdicts coherent
(topology→sqlite, cad-engines→lightweight smallest-adequate,
msci-engines→isle-core biggest). Deviations from the plan text:
remote specs use a `system_info_url` KNOB (swarm mesh makes bare
ip:port ambiguous) + a push-ingest endpoint; knobs live in
topology_seed.py because staging's backend is stateless (no volume);
engine thread-benchmarking deferred (declared kept, labeled).
Working log + gotchas: memory `resource-awareness`.

**Written 2026-07-09 as a durable, GPT-4-executable handoff.** Dustin
wants Polari to (1) know the resources of the device it is hosted on
(self-awareness), (2) know how much memory/disk each module + engine
costs and the MINIMUM threads it needs, (3) know what each workload
*benefits* from (a strictly single-threaded engine gains nothing from a
big-compute server — put it on the small one), and (4) turn all that
into an **admission advisor**: when a user adds a module, Polari assesses
its optimum environment and the live topology and says one of —
"just put it here", "move things around so it lands somewhere more
efficient", "installing this will break things", or "this is mostly
data — it just goes in redis / sqlite / mariadb". This becomes the
resource basis for topology planning: what a set of modules needs to be
pulled down and run on an actual device.

Do the phases in order, branch per phase (`dev-res-1-node-inventory`, …),
selftest green before moving on. Self-contained; each phase is written
so a fresh GPT-4-class agent can execute it without re-deriving the
codebase.

Order:
1. **res-1 — Node resource inventory + device self-awareness** (bridge
   `isoSys` → `PolariNodeMachine`; per-node cores/RAM/disk, local +
   remote via `/system-info`).
2. **res-2 — Module & engine resource profiles** (requirements floor +
   scalability/benefit curve + data-vs-compute character + storage-tier
   recommendation; declared knob).
3. **res-3 — Empirical measurement** (measured RSS / disk / thread-
   scalability; measured overrides declared, honest-absence otherwise).
4. **res-4 — Admission advisor + resource-aware topology planning** (the
   headline: classify → route-or-fit → fits / reallocate / would-break;
   set-feasibility "can this run on this device?").

---

## 0. What already exists (REUSE, do NOT rebuild)

- **Host probe — `isoSys`** (`polariNetworking/defineLocalSys.py:31`, a
  `treeObject`). Uses **psutil**: `numPhysicalCPUs`, `numLogicalCPUs`,
  `total/available/used/freeMainMemoryInBytes`, swap, CPU%,
  `systemType`, `IPaddress`, `isContainerized`. `refreshMetrics()`
  re-reads live. Auto-created by the manager at boot as
  `manager.hostSys` (`objectTreeManagerDecorators.py:117`). Exposed via
  **`GET /system-info`** (`polariApiServer/systemInfoAPI.py`) — platform
  + cpu (physical/logical/usage%) + memory + swap + `bootProfile`. This
  is Polari's EXISTING device self-awareness — res-1 wires it into
  topology, and pulls REMOTE nodes' `/system-info` for their specs.
- **Resource budget + drain warnings — `simulations/resource_monitor.py`**.
  `system_resources()` reads the REAL budget: cgroup v2/v1
  (`/sys/fs/cgroup/memory.max|.current`), `/proc/meminfo` MemAvailable
  fallback, plus `shutil.disk_usage().free` (the only disk probe in the
  codebase). `project_run()` → level ok|warning|critical vs
  `WARNING_FRACTION=0.50`/`CRITICAL_FRACTION=0.85`. REUSE
  `system_resources()` for the local node's live budget (cgroup-aware —
  critical inside a container) instead of re-probing.
- **Measured-vs-static cost pattern — `simulations/`** (mirror it, do
  not duplicate): `StepCostProfile` (`step_cost_profile.py`, MEASURED
  per-step time+bytes with stat-freezing + `config_hash`),
  `step_cost_tracker.py` (EMA wall-time + persisted bytes, failure-
  isolated), `storage_predictor.py` (STATIC estimate:
  `estimate_row_bytes()` walks `manager.objectTypingDict[class].
  polyTypedVars` summing `TYPE_BYTES`). res-2 = declared/static (like
  storage_predictor); res-3 = measured (like StepCostProfile). Overlap
  ledger: **`/OVERLAP_MAP.md`** (repo root — add entries there).
- **Topology data model — `topology/`** (`treeObject`s, auto-CRUDE):
  - `PolariNodeMachine` (`topology_basis.py:26`) — a host. TODAY only
    `arch` + `mem_gb` (manual, default 0.0, "unknown until observe"),
    `roles_json`, `swarm_role`, `ssh_alias`, `repo_dir`, `source`
    (nodes.yml|manual|observed). **res-1 adds the cpu/disk/thread
    fields + auto-fills from `isoSys`/`/system-info`.** Seeded from
    `topology_seed.py:21 SEED_NODE_MACHINES` (hardcoded from
    `pol-build/manifests/nodes.yml`).
  - `InstanceDefinition` (`topology_basis.py:97`) — a deployable
    instance; has `machine_name` (pins to a node), `replicas`,
    `db_backend`, `orchestration_target`. **res-2/4 read `db_backend`
    for the storage-tier vocabulary.**
  - `ModuleAssignment` (`topology_modules.py:26`) — module→instance
    (`module_name`, `instance_name`, `state`, `topology_name`). The
    placement knob res-4's suggestions point at.
  - `ModuleDependencyEdge` (`topology_modules.py:60`), `ServiceConnection`
    (`topology_links.py`), `TopologyDefinition`/`TopologyObservation`
    (`topology_state.py` — observed stacks/services/modules per node, no
    utilization capture today).
- **Placement/reallocation logic — `topology/topology_analysis.py`**
  (the hooks): `resolve_edges()` (L221, alphabetical + reachability,
  no resource signal), **`suggest_reallocations()` (L451, only fires on
  `status=='degraded'` = provider unreachable; reachability-only)**,
  `drift_report()` (L393), `graph_payload()` (L270 — `machine_dict`/
  `instance_dict` serializers, where res-1/4 surface resource fields to
  the Topology tab). **res-4 adds resource weighting here.**
- **Provider routing — `topology/provider_registry.py`**:
  `resolve_provider(module_name)` picks a LIVE provider among candidates
  via `_probe(url) → GET {url}/capability` (30s TTL). `PROVIDER_PORTS`
  dict (`prf-msci-engines:9500`; add `prf-cad-engines:9600`). **res-4
  makes provider selection cost-aware.** Engines advertise `/capability`
  (`materialsScience/scale_execution_api.py`,
  `mathshapes/cad_remote.py`) — res-2 extends that JSON with a resource
  footprint block.
- **Module system — `polariPeers/` + `moduleService/`**: `PolariModule`
  (`polari_module.py` — `name`, `version`, `source_kind`, `status`,
  free-form `manifest_json`, `bundle_json` — NO footprint today),
  `PolariModuleDependency`, `ModuleSourceConfig`. `moduleService/
  module_dependency_tracker.py` — `FRAMEWORK_BOUNDARIES` (L39, canonical
  module list) + `boundary_graph()` (nodes: name/description/present/
  imports). APIs: `/api/modules`, `/api/modules/suggested`,
  `/api/modules/boundary-graph`, `/api/modules/dependencies/tree|
  install-plan`. **res-2 attaches a resource profile keyed to these
  module names; res-4's admission advisor reads the boundary graph +
  install-plan for "what gets pulled down".**
- **Storage tiers present in the suite**: MariaDB (`pol-mariadb`),
  Redis/KeyDB (`prf-b-keydb`, psc-redis), SQLite (`SqliteAdapter` in the
  class list). `InstanceDefinition.db_backend` already names a backend.
- **Standard module conventions** (see `topology/`, `mathshapes/`):
  `*_basis.py` (treeObject classes, `@treeObjectInit`, `manager=None`
  last), `*_seed.py` (`SEED_*` idempotent-by-name), `*_api.py` (Falcon
  routes), `*_analysis.py` (pure/duck-typed logic, stdlib selftests),
  `*_constants.py` (vocab), `selftest_*.py`. Wire every class into
  `polariApiServer/polariServer.py` (imports ~L280-290, defClassList
  ~L855-905, API instantiation ~L740-770, seed_pairs ~L1800-1820). Keep
  analysis stdlib-only where possible; psutil IS available in the
  backend image (isoSys uses it). Deploy: **suite root** `docker compose
  -f docker-compose.staging-nip.yml --env-file .generated/.env.staging
  up -d --build prf-backend` (NOT the polari-rf-node compose — wrong
  network; see the math-shapes deploy gotcha). Cold seed ~3-8 min.

New module home: `polari-rf-node/polari-framework/resources/`.

---

## PHASE res-1 — Node resource inventory + device self-awareness (do first)

### Goal
Every `PolariNodeMachine` carries the REAL resources of the device it
represents — cores, RAM, disk — auto-detected from that node's own
`isoSys`, for the local node and (over the topology's ssh/URL) remote
nodes. Fills the `mem_gb: 0.0` gap and makes topology resource-aware at
the node level.

### Objects
- Extend **`PolariNodeMachine`** (`topology/topology_basis.py`) with
  (keep `mem_gb` for back-compat, mirror into `total_ram_mb`):
  `logical_cpus: int`, `physical_cpus: int`, `total_ram_mb: float`,
  `available_ram_mb: float`, `total_disk_mb: float`, `free_disk_mb:
  float`, `cgroup_ram_limit_mb: float` (0 = unlimited/none —
  container-aware), `load_snapshot_json` (cpu% + mem% + ts),
  `resource_source: str` (observed-local|observed-remote|manual|
  unknown), `resource_observed_at`. Additive; defaults keep existing
  seeds valid.
- Optional `NodeResourceSample` (`resources/node_sample_basis.py`,
  treeObject) — a time-series row (node_name, ts, cpu_pct, ram_used_mb,
  ram_avail_mb, disk_free_mb) for trend/headroom over time. Keep light;
  can defer to res-3.

### Analysis (`resources/node_resources.py`, reuse psutil + resource_monitor)
- `local_node_specs()` → dict {logical/physical cpus, total/avail RAM
  MB, total/free disk MB, cgroup limit, arch, container?} by reading
  `manager.hostSys` (isoSys) + `simulations.resource_monitor.
  system_resources()` (cgroup-aware budget + `shutil.disk_usage`). One
  source of truth — DO NOT re-probe psutil directly.
- `refresh_local_machine(manager, node_name)` → writes those onto the
  local `PolariNodeMachine` row (`resource_source='observed-local'`,
  stamps `resource_observed_at`). Idempotent.
- `fetch_remote_specs(manager, node_name)` → resolves the node's base
  URL (from `PolariNodeMachine.ssh_alias`/topology InstanceDefinition /
  the swarm host IP) and GETs its **`/system-info`**; maps the response
  onto that node's row (`observed-remote`). Honest-absence: unreachable
  → leave `resource_source='unknown'` + a reason, never fabricate.
- `inventory(manager)` → all nodes' resource rows + a
  `headroom = available vs total` per node + a `has_specs` bool.

### API (`resources/node_resources_api.py`)
`GET /api/topology/resources` (all-node inventory),
`GET /api/topology/nodes/{name}/resources` (one node),
`POST /api/topology/nodes/{name}/refresh-resources` (re-observe;
local reads isoSys, remote pulls /system-info).
Surface the new fields in `topology_analysis.graph_payload` `machine_dict`
so the Topology tab shows per-node capacity.

### Acceptance
`selftest_node_resources.py`: `local_node_specs()` returns cores>0 +
RAM>0 + disk>0 from a duck-typed isoSys/manager; `refresh_local_machine`
populates the row + flips `resource_source` to observed-local; a mocked
`/system-info` fills a remote row (observed-remote); an unreachable node
yields `resource_source='unknown'` + reason (honest). LIVE: the local
`PolariNodeMachine` (was `mem_gb 0.0`) now shows real cores/RAM/disk;
`/api/topology/resources` lists all 3 swarm nodes (leader auto-local,
isle-core + lightweight via /system-info).

---

## PHASE res-2 — Module & engine resource profiles (do second)

### Goal
Each module/engine has a profile: its resource FLOOR (min RAM/disk/
threads — the minimum that must be available), its SCALABILITY (does it
benefit from more threads/RAM/CPU, and the parallelism ceiling), its
CHARACTER (compute / data / balanced), and — for data modules — the
recommended storage tier. Declared knob now; measured in res-3.

### Objects (`resources/profile_basis.py`)
- **`ModuleResourceProfile`** (treeObject):
  - `name` (`'<module>-resource-profile'`), `subject_name` (the module
    or service-kind), `subject_kind` ('module'|'engine').
  - `character`: 'compute' | 'data' | 'balanced'.
  - FLOOR: `min_ram_mb`, `min_disk_mb`, `min_threads` (Dustin's
    "minimum threads that should be available").
  - SCALABILITY: `thread_ceiling: int` (1 = strictly single-threaded —
    gains nothing from more cores), `cpu_benefit`/`ram_benefit`:
    'none'|'sublinear'|'linear', `scales_note`.
  - INSTALL footprint (what gets pulled down): `image_mb`, `deps_mb`.
  - DATA profile (character=data): `est_row_bytes`, `growth_rate`,
    `access_pattern` ('hot'|'warm'|'cold'), `durability`
    ('ephemeral'|'durable'), `concurrency` ('single'|'shared'),
    `recommended_backend` ('redis'|'sqlite'|'mariadb').
  - `fidelity`: 'declared' | 'measured' (res-3 flips this).
  - `provenance_id`, `notes`.

### Analysis (`resources/profile_analysis.py`, duck-typed)
- `classify_module(manager, module_name)` → 'data'|'compute'|'balanced':
  inspect the module's classes/functions via `boundary_graph()` +
  `manager.objectTypingDict` — mostly `treeObject` data classes with few
  functions → 'data'; owns an engine/worker (a `PROVIDER_PORTS` entry, a
  `/capability`, or heavy-compute deps FEM/DFT/trimesh/skfem) →
  'compute'; both → 'balanced'. Return the evidence.
- `recommend_backend(profile)` → the storage tier from the data profile:
  **redis** (hot + ephemeral + small + high-churn), **sqlite** (single-
  node + small + low-concurrency — the `SqliteAdapter` path), **mariadb**
  (shared + larger + durable + concurrent). Reuse `storage_predictor.
  estimate_row_bytes` for volume. Name the reason (labels travel).
- `declared_profile(manager, module_name)` → seed/default a profile from
  the module's `manifest_json` (a knob) or a conservative default;
  honest 'declared' fidelity.
- Engines: extend the msci + cad `/capability` JSON to also return a
  `resources` block `{min_threads, thread_ceiling, ram_mb, image_mb,
  cpu_benefit}`; `import_engine_profile(manager, service_kind)` caches it
  into a `ModuleResourceProfile(subject_kind='engine')`.

### Seed (`resources/profile_seed.py`)
Declared profiles for a few known subjects: `msci-engines` (compute,
thread_ceiling>1, RAM-heavy — FEM/DFT scales), `cad-engines` (compute,
trimesh baseline modest; FreeCAD heavy image), a DATA-heavy module (e.g.
`scoring` or `nutrition` — character data, backend mariadb/sqlite), and a
strictly single-threaded example (thread_ceiling=1) to exercise res-4's
"small node" rule.

### API (`resources/profile_api.py`)
`GET /api/modules/{name}/resource-profile`,
`POST /api/modules/{name}/classify`,
`GET /api/resources/profiles` (catalogue).

### Acceptance
`selftest_profiles.py`: a data-heavy module classifies 'data' +
`recommend_backend` names a tier with a reason; msci-engines classifies
'compute' with `thread_ceiling>1`; the single-threaded seed has
`thread_ceiling==1` and `cpu_benefit=='none'`; `est_row_bytes` matches
`storage_predictor`. LIVE: `/resource-profile` returns floor +
scalability + character; engine `/capability` carries the `resources`
block and is cached.

---

## PHASE res-3 — Empirical measurement (do third)

### Goal
Replace declared estimates with MEASURED footprint where possible, the
honest high-fidelity path (mirrors `StepCostProfile`). Measure RAM (RSS
resident + peak), disk (image + data), and — critically — thread
SCALABILITY (run at increasing threads, observe speedup → the empirical
`thread_ceiling` + benefit curve that proves "single-threaded gains
nothing").

### What to add (`resources/profile_measure.py`)
- `measure_footprint(manager, subject, mode='live')`:
  - RAM: sample RSS via `simulations.resource_monitor` /
    psutil at rest + under a representative load → `resident_mb`,
    `peak_mb`.
  - Disk: `docker image inspect` size for an engine image + install-dir
    size + observed table bytes (reuse `storage_predictor` + real row
    counts).
  - Threads: run a representative workload at N=1,2,4,… (an engine's own
    benchmark endpoint, or a module analysis under a thread pool) →
    speedup(N); derive `thread_ceiling` (where speedup plateaus) +
    `cpu_benefit` (linear/sublinear/none). A strictly single-threaded
    subject shows flat speedup → ceiling stays 1.
  - Writes `ModuleResourceProfile` with `fidelity='measured'` + a
    `config_hash`-style context tag (like StepCostProfile). Failure-
    isolated. Honest-absence: unmeasured → keep declared, labeled.
- A measurement PROBE runnable ON A SPECIFIC DEVICE (uses the 3-node
  swarm — measure an engine on the node it will actually run on, since
  RSS/threads differ per host). `POST /api/resources/measure {subject,
  node}`.

### Acceptance
`selftest_measure.py` (mock the samplers): measuring yields resident +
peak RAM and a speedup curve; a flat curve → `thread_ceiling` unchanged
at 1 with `cpu_benefit='none'`; measured overrides declared and stamps
the label; missing sampler → honest-absence keeps declared. LIVE:
measure `cad-engines` on isle-core → a real profile with RSS + image_mb.

---

## PHASE res-4 — Admission advisor + resource-aware topology planning (do last)

### Goal (Dustin's exact framing)
A user adds a module; Polari assesses its optimum environment + the live
topology and returns a verdict: **route-to-storage** (data), **fits-as-is**,
**fits-with-reallocation** (more efficient), or **would-break**. Plus a
set-level feasibility: can this set of modules be pulled down and run on
a given device?

### Analysis (`resources/admission_advisor.py`, duck-typed)
- `assess_module_admission(manager, module_name, topology_name=None)`:
  1. `classify_module` (res-2). If **'data'** → `recommend_backend`
     verdict: `{verdict:'route-to-storage', backend:'redis|sqlite|
     mariadb', reason, computeFootprint:'negligible'}` — it lands on any
     node already running that backend; no compute placement needed.
  2. If **'compute'/'balanced'** → resource-fit against res-1 inventory:
     - sum the FLOOR (min_ram/min_disk/min_threads) + install footprint.
     - per candidate node: `fits = floor <= available` (RAM, disk,
       free-threads = logical_cpus − Σ min_threads of modules already
       placed there); compute `headroom` + name the LIMITING resource.
     - BENEFIT-AWARE ranking (the core insight): if `thread_ceiling==1`
       or `cpu_benefit=='none'` → prefer the SMALLEST adequate node
       (leave big-compute nodes free); if it scales → prefer the
       biggest-compute adequate node. RAM-heavy → most-free-RAM node.
     - verdict:
       a. **`fits-as-is`** — an adequate node exists at/near the optimum
          → `{verdict, node, headroom}`.
       b. **`fits-with-reallocation`** — no free optimal spot, but moving
          an existing module A (e.g. a single-threaded one hogging the
          big node) X→Y frees the optimum → `{verdict, moves:[{module,
          from, to}], netEfficiencyGain, evidence}`. Extend/reuse
          `topology_analysis.suggest_reallocations`.
       c. **`would-break`** — no placement without violating an existing
          module's floor (RAM overcommit / thread starvation / disk
          exhaustion) → `{verdict:'would-break', conflict, limiting
          Resource, node, needed:'+X GB RAM or +1 node'}`.
- `assess_set_feasibility(manager, module_names, node_name)` → "can this
  set be pulled down + run here?": Σ install footprints (disk to pull) +
  Σ runtime floors vs the node's inventory → `{feasible:'yes|tight|no',
  limitingResource, headroom, perModule:[...]}`. Reuse the boundary-graph
  install-plan for the pull set.
- knobs-and-suggestions: EVERY verdict is a suggestion pointing at
  `ModuleAssignment`/`InstanceDefinition` knobs (emit a `pol allocate …`
  command like `suggest_reallocations` does) — NEVER auto-move. honest-
  absence when a profile or a node's specs are missing ("measure/observe
  first, then re-ask").

### Topology integration
- Extend `topology_analysis.suggest_reallocations` with a RESOURCE-
  EFFICIENCY signal beyond degraded-only: flag a single-threaded module
  on a big node while a scalable module is cramped → suggest the swap.
- Extend `provider_registry.resolve_provider` to prefer the cost-
  appropriate live provider among candidates.
- Extend `graph_payload` `machine_dict`/`instance_dict` with capacity vs
  allocated + headroom, for the Topology-tab render.

### API (`resources/admission_api.py`)
`POST /api/topology/admission {module, topology}` → the verdict,
`GET /api/topology/fit?modules=<csv>&node=<name>` → set feasibility,
`GET /api/topology/placement-suggestions?topology=` → efficiency swaps.

### Acceptance
`selftest_admission.py`: a data module → `route-to-storage` with a named
backend + reason; a compute module that fits → `fits-as-is` on the
benefit-appropriate node (single-threaded → SMALL node even when a big
one is free, with the rationale); a topology with no free optimal spot →
`fits-with-reallocation` naming the move + gain; an over-subscribed add →
`would-break` naming the conflict + limiting resource + what to add; set
feasibility returns yes/tight/no with the limiting resource. LIVE:
`POST /api/topology/admission` for a real module against the live 3-node
topology returns a coherent verdict.

---

## Cross-phase notes
- **Bridge the gap**: res-1 connects the disconnected `isoSys` (real
  auto-detected specs) ↔ `PolariNodeMachine` (topology, manual `mem_gb`
  0.0). That bridge is the foundation everything else stands on.
- **Reuse, don't duplicate**: `simulations/resource_monitor.
  system_resources()` (cgroup/meminfo/disk budget), `isoSys`/
  `/system-info` (per-node hardware), `storage_predictor` (static row
  bytes). res-2 = static/declared (like storage_predictor), res-3 =
  measured (like StepCostProfile). Add `/OVERLAP_MAP.md` entries.
- **The two placement hooks**: `topology_analysis.suggest_reallocations`
  (add resource-efficiency signal) and `provider_registry.
  resolve_provider` (add cost-aware selection). Both already exist and
  are reachability-only today.
- **Storage tiers** reuse `InstanceDefinition.db_backend` vocabulary:
  redis/keydb (hot/ephemeral), sqlite (single-node/small, SqliteAdapter),
  mariadb (shared/durable/concurrent).
- **Multi-node**: use the 3-node swarm (leader .210, isle-core .24,
  lightweight .66) — res-1 inventories all three via /system-info; res-3
  measures engines on the node they'll run on; res-4 plans across them.
- **Standing principles**: object-coherence (every profile + inventory is
  a configurable row), knobs-and-suggestions (verdicts are evidence-
  bearing suggestions pointing at topology knobs, never auto-applied),
  honest-absence / labels-travel-with-numbers (declared vs measured;
  unknown vs observed), file-size-decomposition. Branch-per-phase, local
  commits only (nothing pushed; repos PUBLIC). Update a
  `resource-awareness` memory entry as each phase lands.
