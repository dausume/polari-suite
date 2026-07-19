# Graceful Mobility — move ANYTHING between devices/containers

**Status: PLANNING ONLY (Dustin 2026-07-18) — the NEXT AGENT runs
this.** Module moves between Polari containers are DONE and smooth
(tt-13/tt-15: rows-only, instant, transient ghosts, persisted).
This plan extends mobility to everything else — ENGINES,
INFRASTRUCTURE (databases/storage/proxy), and AUTH — with the
discipline Dustin specified: start the new container, warm it, swap
references/ports the moment it is ready, ensure NO ACTIVE ACTIONS
are in flight between backends, no data loss, minimal lag, then
retire the old one.

## Ground truth to build on (all live today)
- Module moves: `plan_move`/`POST /api/topology/move` — rows only,
  ghosts, placement coherence (tt-14: psc/infra/auth NEVER receive
  modules; engine capabilities → engine hosts only).
- Engine relocation is PLANNED but hand-finished: the move re-pins
  the instance row + constraint and hands back
  `pol topology render` + `pol allocate <instance> <machine>`; the
  isle-core migration proved the manual path (image save|load, label,
  POL_STACK_CONSTRAINTS + `pol swarm deploy`).
- Verification exists: testing-over-topology's foundational pings
  (protocol+security notated) and module selftest runs — every move
  should END by running these and painting the result.
- Quiesce raw material exists: MutationLease / ObjectLockEntry /
  WriteJournalEntry (shared-object-db + schema-stabilization work) —
  the "no active actions, no data loss" seam rides these, not new
  magic.
- The register (mp-1) knows what code exists where; PolariNodeMachine
  rows know devices; the service registry (pol-build/registry)
  knows service kinds + interconnects.

## The move taxonomy (what moves ≠ how it moves)
| Kind | State | Strategy |
|---|---|---|
| Module (Polari↔Polari) | none (code in both) | rows only — DONE |
| Engine instance (msci-engines, cad-engines) | stateless compute | blue-green swarm relocation (gm-1) |
| KeyDB (cache) | soft state | replica on target → sync → promote → repoint (gm-3) |
| MinIO (files) | hard state | mirror → verify checksums → cutover (gm-3) |
| Keycloak (auth) | DB-backed | new instance on SAME db → realm-ready probe → proxy upstream swap; issuer hostname stays stable so tokens survive (gm-4) |
| MariaDB (shared db) | hard state | v1: quiesce → dump/restore (backup receipt) → repoint → resume, honest downtime; v2: replica + promote (gm-5) |
| Polari instance w/ OWNED sqlite | hard state (one file) | quiesce instance → copy file → start on target → verify row counts/journal → cutover → retire (gm-5) |

## Phases (gm-N)

### gm-1 — Engine relocation, automated blue-green
Automate what the isle-core migration did by hand, triggered by the
EXISTING engine-relocation move (UI drawer or `pol allocate
<instance> <machine> --graceful`):
1. Image presence on target: check `docker node`/ssh; ship via
   `docker save | ssh load` (automated, sized + logged) — a local
   registry service is the later refinement, note not blocker.
2. Ensure node label (`pol swarm join` idiom).
3. Swarm service update with `--constraint-rm/--constraint-add` and
   **`update_config order: start-first`** — swarm starts the NEW
   task on the target, and only stops the old one when the new one
   runs → the routing mesh keeps :9500 answering throughout (this
   IS the smooth container replacement for stateless engines).
4. Readiness gate: poll the provider's `/capability` THROUGH the
   mesh until the new task answers; then invalidate
   provider_registry's probe cache (small POST endpoint) and
   re-resolve edges.
5. Verify: foundational ping pass; paint the edges. Old task is
   gone via swarm itself; nothing manual left.
Acceptance: relocate engines isle-core→lightweight→isle-core with
zero failed requests in a loop calling /capability during the move.

### gm-2 — Quiesce seam + moves as DATA
- `MoveOperation` rows (topology module): kind, subject, from → to,
  planned steps, per-step status/receipts (image-ship time, dump
  path, checksums), verification outcome. The Topology tab shows an
  in-progress move on the graph (pulsing node) and its step list —
  moves become observable data like everything else.
- polariServer quiesce endpoints: `POST /api/quiesce` (stop
  accepting mutations via the lease machinery, flush
  WriteJournalEntry, report in-flight=0) + `/api/quiesce/status` +
  release. This is the enforceable "no active actions between
  backends" gate every stateful move calls before touching data.
- All gm movers write MoveOperation receipts; nothing stateful runs
  without one.

### gm-3 — KeyDB + MinIO movers
- KeyDB: deploy target instance → `REPLICAOF old` → wait
  master_link_status:up + offset sync → quiesce writers (gm-2, brief)
  → `REPLICAOF NO ONE` on new → repoint consumers (env/runtime-config
  re-render + container restart or runtime reconfig where supported)
  → retire old. Honest note: cache entries written in the cutover
  window on the old master are lost — quiesce makes that window ~0.
- MinIO: `mc mirror --preserve` old→new → quiesce uploads → final
  mirror pass → checksum sample verification (receipt) → swap
  MINIO endpoints in generated config → retire.

### gm-4 — Auth (Keycloak) mover
Keycloak state (realms, clients, KEYS) lives in its database — keep
the DB constant, move the SERVER: deploy new keycloak on target
against the same DB → readiness = realm endpoint + JWKS answers →
swap the proxy upstream (pol proxy render + reload — the nip.io
issuer HOSTNAME never changes, so existing tokens stay valid) →
drain old (connection grace) → retire. Refuse honestly when someone
asks to move keycloak AND its DB in one step — that is two moves,
DB first (gm-5), then this.

### gm-5 — Database movers (the careful ones)
- MariaDB v1 (correct before clever): quiesce ALL writers (every
  backend on the shared db — gm-2 fan-out) → `mysqldump` to a
  RECEIPT file (this is also the backup) → restore on target →
  row-count + checksum verification vs receipt → re-render db-
  credentials/config to the new host → release quiesce → verify
  pings + one CRUDE write/read probe → retire old. Downtime =
  dump+restore, measured and reported honestly in the receipt.
- MariaDB v2: binlog replica on target → catch-up → brief quiesce →
  promote → repoint. Same receipts, seconds of quiesce.
- Owned-sqlite Polari instance move: quiesce that ONE instance →
  copy the sqlite file (it is the whole object state — the mp-1
  register named these deliberately) → start instance on target
  (image ship as gm-1) → verify table counts vs receipt → cutover
  (proxy/runtime-config/ports) → retire. The transient-ghost idiom
  applies to the INSTANCE card during the move.

### gm-6 — UI: kind-aware move flows
The tt-13 drawer grows up: selecting an infra/auth/engine subject
shows the PLANNED STEP LIST (from gm-2 plan data) before anything
runs; stateful moves demand a typed confirmation naming the subject;
execution shows per-step progress + receipts inline; the graph
pulses the moving subject and repaints from the verification pass.
Placement rules extend (tt-14 stays true): infra/auth still NEVER
receive modules — but they gain "move to device" as their one
legal move. Every flow ends with the suggested-verification
(pings + selftests) run and painted.

## Ordering & risk
gm-1 (pure win, stateless) → gm-2 (the safety seam everything else
needs) → gm-3 (bounded state) → gm-4 (server-only move) → gm-5
(hard state, receipts + backups mandatory) → gm-6 polish throughout
(each mover lands with its drawer flow). Every phase live-verifies
on staging + isle-core/lightweight and ends with the ping/selftest
paint. Honest refusals everywhere a capability is not yet built.
