# Cross-Instance References + Single-Writer Multiscale Simulation
# (xsim-1..6)

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
- User CRUDE edits are NOT locked (object-coherence stays live). Open
  edge case, default v1: allowed + the run report warns when a row in
  the run's read-set changed mid-run (journal makes this detectable).

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
  (simulation_api runs, solution executions, stage searches). Live:
  start sim A, sim B queues; break-lease event path.
- **xsim-3**: cross-instance READ — shared-DB rung + PeerAgreement
  scope check + GenericRemoteObject hydration from polyTyping for an
  uninstalled class. Live proof against instance b.
- **xsim-4**: automated remote WRITES under lease + write journal +
  stale-token refusal proof (simulated zombie).
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
- read-set row externally edited mid-run → run-report warning

## Relation to existing work

- PeerAgreement/join flow (mesh convergence) = the auth substrate.
- POLARI_SHARED_OBJECT_DB two-instance proof = rung-3 substrate.
- Topology-as-data = the address book for authority.module.
- SchemaStabilityProfile = schemaVersion source; residency demotion
  (stable objects) becomes rung 2 of THIS ladder when built.
- grpc bridge ProtoContractVersion = same versioning idea, reuse.
