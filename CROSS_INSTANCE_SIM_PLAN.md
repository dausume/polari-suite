# Cross-Instance References + Single-Writer Multiscale Simulation
# (xsim-1..6)

**STATE 2026-07-10 (late): DESIGN CONFIRMED BY DUSTIN — fencing-token
approach approved ("roughly the same concept and more thought out,
let us just go with that"); object-lock layer added at his direction;
the strict all-sims-serialize default was flagged to him and stands
unless he flips it.**

**✅ xsim-1 COMPLETE 2026-07-10 (framework `dev-xsim-1-refs` 02f394e):
polariRefs/ (ref_format + identity_map + resolver + selftest 27/27) —
authority-carrying refs parse; local rungs live (tree via identity
map, demoted-DB RowView); remote rungs refuse naming xsim-3/xsim-6;
schemaVersion from SchemaStabilityProfile hash, mismatch names both;
component_binding delegates via a 5-line authority guard, bare path
untouched. 66-test suite identical to baseline (same 12 pre-existing
failures), 22/22 live smoke on staging. NEXT: xsim-2 on
`dev-xsim-2-locks`.**

## PICK UP HERE — execution context for a fresh session

- **Branches**: polari-framework HEAD = `dev-msci-27-md-meso-ui`
  b97052f (everything through msci-27 live) → cut `dev-xsim-1-refs`
  from it. Angular HEAD = `dev-msci-27-md-meso-ui` 4d3883f (no
  frontend work until xsim-2's queue/lock chips; cut per phase).
  Suite branch dev-prf-mariadb-combo (this plan committed 063ee77+).
- **New module layout** ([[file-size-decomposition]]): framework
  `polariRefs/` (ref_format.py, identity_map.py, resolver.py,
  selftest_refs.py) for xsim-1; `simulationLocks/` (lease.py,
  object_locks.py, sim_queue.py, locks_api.py, selftest_sim_locks.py)
  for xsim-2. treeObject classes registered in polariServer
  defClassList like every msci class.
- **Key seams (file paths)**:
  - refs today: `materialsScience/component_binding.py` — objectRef
    {className,name,path}, `find_row` = LOCAL-ONLY objectTables scan
    (~line 48); `_resolve_binding`/_section_value do dotted paths
    through JSON blobs. Bare refs must keep working UNTOUCHED.
  - CRUDE writes: `polariApiServer/polariCRUDE.py` on_put ~line 263
    (FormData polariId + updateData JSON) — object-lock refusal (423)
    goes here (+ on_post/on_delete).
  - sim entry points to gate: `simulations/simulation_api.py` (msim
    runs + stage search dispatch), `polariNoCode/
    SolutionExecutionEngine.py` (solution executes),
    `materialsScience/formulation_search_api.py` (search runs),
    `materialsScience/model_execution.py` execute_model +
    `materialsScience/scale_execution.py` execute_scale_definition
    (model/scale executes count as sims under the strict policy —
    they take short leases through the same seam).
  - shared-DB substrate: `polariDBmanagement/managedDB.py` +
    `migrate_shared_db.py` (_instance_id discriminator, composite
    PKs); peers/auth: `polariPeers/` (PeerAgreement, join_flow,
    tokens); class-shape-as-data: `polariApiServer/createClassAPI.py`
    + polyTyping + `_dynamic_class_registry`; schema versions:
    SchemaStabilityProfile rows (field_summary_json = the hashable
    shape).
- **Deploy/verify conventions**: staging deploys from the SUITE-level
  `docker-compose.staging-nip.yml --env-file .generated/.env.staging`
  (services prf-backend/prf-frontend); after EVERY `up -d --build`
  run `docker exec pol-proxy nginx -s reload` (proxy caches container
  IPs → 502s otherwise). Backend boot ~150 s. API via
  `curl -sk -H 'Host: api.prf.192.168.0.210.nip.io' https://localhost/...`
  (use --form-string for CRUDE PUT tests, -F mangles JSON). Smoke:
  `python3 polari-rf-node/polari-framework/tests/live_api_smoke.py`
  (22/22 expected). Selftests `python3 -m <pkg>.<mod>` from
  polari-framework/. Branch per confirmed phase; repos PUBLIC — no
  secrets in commits; NOT pushed without Dustin.
- **xsim-1 acceptance**: bare refs resolve exactly as before
  everywhere; authority-carrying refs parse + local rung resolves via
  identity map; non-local rungs refuse honestly naming their phase;
  selftest_refs green; no behavior change in the 66-test +
  live-smoke suites.
- **xsim-2 acceptance**: two sims → second queues (persisted row);
  fencing epoch bumps on break; zombie token refused; CRUDE edit of a
  locked row → 423 naming run + queue position; generated objects
  auto-locked + released on completion, quarantined on failure; live
  on staging.

## Dustin's directives (2026-07-10 evening)

1. Object tree growth is the concern; two relief directions already
   chosen: **modularizing across instances** and **stable objects**
   (residency demotion: off the tree, DB-only).
2. Cross-instance references must work **even for classes whose module
   is not installed locally**.
3. **Remote writes must be automated** — "that is the whole point of
   multiscale simulations."
4. Simplifying assumption we are ALLOWED to lean on: **only one
   simulation is ever running and causing mutations across the whole.**
5. Running one multiscale simulation **locks down running any other
   simulations except the ones specifically tied to it.**
6. **A queue of multiscale simulations on the core polari.**
7. Each multiscale simulation is assumed to intelligently handle its
   own data — and we **assist**: detect when a simulation definition
   attempts to parallelize work that would **touch the same objects**.
8. Purpose: make enormous simulations feasible on normal hardware.

## Design pillars

1. **One reference type, one resolution ladder.** The same lazy ref
   serves local-tree, demoted-to-DB (residency), shared-DB
   cross-instance, and remote-API objects. Never two proxy systems.
2. **Fencing-token mutation lease** (single writer, mesh-wide). The
   known-good distributed-systems pattern (ZooKeeper/Chubby fencing
   tokens) — the "novel algorithm" risk collapses to a well-understood
   one because directive 4 removes concurrency by policy.
3. **Queue on core polari**, persisted rows, honest states.
4. **Write journal per run** — every remote mutation recorded; the
   audit trail that makes "handles its data intelligently" verifiable.
5. **Overlap advisor**, not enforcer — static write-set analysis over
   simulation definitions; evidence-bearing findings + suggestions
   (serialize / partition / clone-then-merge), never auto-applied
   ([[knobs-and-suggestions]]).

## The reference format (xsim-1)

Extend the existing binding objectRef SHAPE (component_binding et al)
with an optional authority coordinate — bare refs stay valid forever
and mean "local":

    { kind: 'objectRef',
      authority: { instance: 'b' } | { module: 'materialsScience' },
      className: 'MaterialScaleDefinition',
      name|id: ..., path: 'last_result_json.percolationThreshold',
      schemaVersion: '<hash from owner SchemaStabilityProfile>' }

- `authority.module` is preferred: the topology layer
  (ModuleAssignment/PeerNode/ServiceConnection) resolves WHICH instance
  is authoritative right now — refs survive module reallocation.
- `schemaVersion` optional; when present, hydration refuses on
  mismatch naming both versions (OOPS-style widen path later).
- **Do this format extension FIRST** — before residency demotion and
  before module splits — so no bare ref ever needs retrofitting.

## Resolution ladder (xsim-1 local rungs, xsim-3/6 remote rungs)

    1. local tree        (objectTables — today's path)
    2. local DB          (residency-demoted stable object)
    3. shared-DB peer    (same MariaDB, different _instance_id;
                          permitted via PeerAgreement scope; no
                          network hop — the cheap cross-instance rung)
    4. remote API        (CRUDE GET / gRPC via peer link + token)

Hydration:
- class installed → typed instance through an **identity map keyed
  (authority, className, id)** (weakref values). Instance a row 5 and
  instance b row 5 must never collapse.
- class NOT installed → **GenericRemoteObject**: className + field
  dict typed from the owner's polyTyping data (class-shape-as-data —
  createClassAPI/_dynamic_class_registry machinery already proves the
  concept) + provenance (owning instance, module, schemaVersion).
  Read-only fields; writes go through the lease path or refuse.
- unreachable authority → honest refusal naming instance + connection
  knob. NEVER a silent None mid-simulation.
- Read staleness: on-access fetch + short TTL for live views; stage
  inputs record snapshot-with-provenance (value + authority +
  timestamp) in the run — reproducibility over liveness.

## Mutation lease — the lock (xsim-2)

One `MutationLease` singleton row on core polari:

    holder_run, token (monotonic epoch int), acquired_at,
    heartbeat_at, ttl_seconds (knob, default 120), status

- EVERY mutating simulation run acquires the lease at start (msim
  parent or standalone sim alike — simplest defensible policy: all
  simulation runs serialize mesh-wide; a "tied" child presents the
  parent's token instead of acquiring).
  POLICY DEFAULT FOR DUSTIN'S EYE: alternative is lock-only-while-an-
  msim-runs (standalone sims free otherwise); chosen the stricter
  form because directive 4 says assume ONE mutator, period.
- **Tied children**: subModel stages, engine-model executions, stage
  searches, Dask/worker jobs — the run context carries
  `{run_id, lease_token}`; children never re-acquire.
- **Fencing**: every lease-path write presents the token; the owning
  instance validates token == current epoch. A crashed sim's zombie
  worker holding epoch N cannot write after the lease was broken and
  re-issued as N+1 — refused honestly, journaled.
- **Heartbeat + expiry**: runner heartbeats; TTL lapse makes the lease
  BREAKABLE (not auto-broken) — the queue head may then break it; a
  LeaseBreakEvent row records every break, never silent. Manual admin
  break knob too. Clock authority = core's clock only (no skew games).
- User CRUDE edits to objects OUTSIDE the run's lock set stay live
  (object-coherence). Objects INSIDE it are write-locked — see below.

## Object locks — the run's working set (Dustin 2026-07-10)

> "we can put locks on all objects being used by simulations as well
> and on newly generated objects from the simulation, until it is
> done running."

On top of the global lease, the run holds **write locks on its working
set** for its whole duration:

- `ObjectLockEntry` rows: (authority, className, selector) → run_id +
  token_epoch. Selector granularity REUSES the overlap advisor's
  vocabulary — id | name | range | class-wide — so a 100k-object sweep
  is ONE class/range lock row, not 100k rows. **The advisor's write-set
  manifest IS the lock manifest** (one analysis, two consumers).
- **Acquisition**: declared read+write sets locked at run start;
  undeclared objects touched mid-run get lazy lock escalation at first
  touch (journaled as an undeclared-touch note — feeds the advisor's
  accuracy back); **newly generated objects are auto-locked at
  creation and tagged with the run**.
- **Semantics**: write locks only. Anyone may READ a locked object
  (frontend later shows a "locked by run X" chip); non-run WRITES get
  an honest refusal naming the run + queue position — refusal, not
  blocking, so no waiting and (with single-writer) NO deadlock is
  possible anywhere in the design.
- **Inputs frozen**: the read-set write-lock is what makes runs
  reproducible — supersedes the earlier "allow + warn" default for
  mid-run external edits. Admin break knob exists (LockBreakEvent
  recorded, run notified into its blocked state).
- **Enforcement seams**: the owning instance's write paths (CRUDE PUT,
  saveInstanceInDB, gRPC write) check the lock table. Shared-DB
  instances share one lock table; remote-API instances receive the
  relevant lock subset at acquisition (xsim-4).
- **Release**: run completion releases locks atomically with the lease.
  Run FAILURE quarantines instead: generated objects stay locked and
  tagged 'orphaned-by-run' with an explicit cleanup/keep knob — never
  silently deleted, never silently adopted.
- **Tree-growth tie-in**: run-tagged generated objects give the
  retention lever the resource-aware-simulation directive asked for —
  per-run retention windows / archival / residency demotion become
  possible because outputs are identifiable as a set.

## The queue (xsim-2)

`SimulationQueueEntry` rows on core: sim ref (msim or solution run),
state queued|running|done|failed|cancelled, position, submitted_by,
priority (knob, default FIFO), notes. API: enqueue / list / cancel /
promote. Runner loop: lease free → pop head → acquire → run → release.
Persisted rows = queue survives restart. Queue page later (frontend
tail; the msim page's conformance-panel idiom).

## Automated remote writes (xsim-4)

Under a valid token, proxy writes are AUTOMATED — no confirmation
prompts inside a running simulation (directive 3):

- shared-DB rung: direct SQL with the owner's `_instance_id`, token
  checked against core first.
- remote-API rung: CRUDE PUT with `X-Polari-Lease-Token` header (+
  peer token); owner validates epoch with core before applying.
- EVERY remote write appends a `WriteJournalEntry`:
  {run, authority, className, id, fields_changed, at, token_epoch}.
  Post-run review, external-mutation detection, and (later, explicit
  knob) rollback all read this ledger.
- Failure mid-run: run enters a blocked state naming the authority +
  retry/skip knobs — pause honestly rather than diverge silently.
- No cross-object transactions in v1 (journal detects partial-write
  windows; documented limitation).

## Overlap advisor (xsim-5) — the parallelization assist

`analyze_write_sets(simulation_definition)`:

- Walk stages / subModels / bindings / batch plans (Dask fan-outs,
  batch_refine partitions) and collect DECLARED write sets as
  (authority, className, selector) where selector is id | name |
  range | class-wide.
- Any two PARALLEL branches whose write sets are not PROVABLY disjoint
  → finding {level, evidence: both stage paths + the shared selector,
  suggestions: serialize these stages | partition by id/range |
  clone-then-merge}. Dynamic/unresolvable refs → conservative
  "cannot prove disjoint" note.
- Surfaces in validate_composition + the existing msim conformance
  panel (the UI seam already exists); also a pre-run gate with an
  `acceptWarnings` knob. Never rewrites the definition.

## Phases (branch per confirmed phase)

- **xsim-1**: ref format + local rungs (tree, then DB stub for
  residency) + identity map. All existing bare refs still resolve.
  Selftests.
- **xsim-2**: MutationLease + fencing tokens threaded through run
  contexts + SimulationQueueEntry + gating at the sim entry points
  (simulation_api runs, solution executions, stage searches) +
  **ObjectLockEntry local enforcement** (manifest locking, generated-
  object auto-lock, non-run write refusal, quarantine-on-failure).
  Live: start sim A, sim B queues; CRUDE edit of a locked row refused
  naming the run; break-lease event path.
- **xsim-3**: cross-instance READ — shared-DB rung + PeerAgreement
  scope check + GenericRemoteObject hydration from polyTyping for an
  uninstalled class. Live proof against instance b.
- **xsim-4**: automated remote WRITES under lease + write journal +
  stale-token refusal proof (simulated zombie) + cross-instance lock
  replication (owner-side enforcement of the run's lock subset).
- **xsim-5**: overlap advisor + conformance-panel surfacing + a
  deliberately-conflicting parallel definition in selftests.
- **xsim-6**: remote-API rung via topology address book + the
  end-to-end rehearsal: one multiscale sim spanning instance a + b
  (+ worker), remote mutations journaled, queue holding a second sim
  until release.

## Edge-case ledger (carry into selftests)

- identity map: same (class,id) from two authorities stays two objects
- bare ref back-compat everywhere bindings parse today
- lease TTL lapse mid-write; token epoch bump; zombie write refusal
- queue: cancel queued, cancel RUNNING (break + journal), starvation
  (priority knob), restart recovery of queued rows
- schemaVersion mismatch hydrate refusal (both versions named)
- uninstalled-class write attempt → refusal names module + instance +
  install knob
- peer offline at read (refusal) vs at write (blocked run state)
- non-run write to locked object → refusal names run + queue position
- lazy lock escalation on undeclared touch (journaled, feeds advisor)
- failed run → generated objects quarantined 'orphaned-by-run' (knob)
- lock-set release atomic with lease release; break knobs evented
- selector-level locks (class-wide/range) vs per-id — advisor manifest
  decides granularity; overlapping selector refusal cases

## Relation to existing work

- PeerAgreement/join flow (mesh convergence) = the auth substrate.
- POLARI_SHARED_OBJECT_DB two-instance proof = rung-3 substrate.
- Topology-as-data = the address book for authority.module.
- SchemaStabilityProfile = schemaVersion source; residency demotion
  (stable objects) becomes rung 2 of THIS ladder when built.
- grpc bridge ProtoContractVersion = same versioning idea, reuse.
