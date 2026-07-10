# gRPC on Stabilized Objects — Bridge Plan

**Written 2026-07-09 as a durable, GPT-4-executable handoff (Dustin's
directive; PLANNED, not built).** Goal: a **knob, not automation** —
classes whose object schema has STABILIZED (see
`polariDataTyping/schema_stability*`) can be exposed over gRPC for
efficient binary transport, as a stand-in/parallel for the STOMP
websocket layer. The primary purpose is the **hardware bridge**:
hardware signals (MCU/FPGA nodes — see the polari-hardware-architecture
memory) stream into Polari over gRPC and fan out efficiently to
everywhere they are needed.

Do phases in order, branch per phase (`dev-grpc-1-contracts`, …),
selftest green before moving on.

---

## 0. What already exists (REUSE, do NOT rebuild)

- **Schema stabilization (the gate this whole plan stands on)** —
  `polariDataTyping/schema_stability.py` + `schema_stability_basis.py`:
  `SchemaStabilityProfile` per class (status
  unstable|stabilized|destabilized, `field_summary_json` = per-field
  `getDeviationSummary()` snapshot taken AT stabilization — dominant
  type + sqlite affinity + strategy typed/widenable/variant/complex),
  `SchemaDeviationEvent` (an OOPS: schema adapted + payload captured).
  `is_stabilized(manager, className)` is O(1). **A gRPC contract is
  only as stable as the schema under it — generation must key to this
  snapshot, and a destabilization must mark contracts stale.**
- **STOMP layer (the shape to mirror)** —
  `polariApiServer/stompWebSocketServer.py`: a SIDECAR asyncio
  websockets server on :3001 (`WEBSOCKET_ENABLED`/`WEBSOCKET_PORT`
  knobs), minimal STOMP 1.2 subset, module-level
  `get_stomp_server()`/`set_stomp_server()`, `publish(topic, dict)`
  (JSON bodies), topics `/topic/{ClassName}[/{formatType}]`.
  **Producers**: `polariApiServer/polariCRUDE.py
  _notify_ws_subscribers(operation, instanceIds)` (L82; called on
  create/update ~L325/L520) — frontends receive a small change
  notification and refetch over REST. This publish seam is where a
  transport MUX slots in.
- **Typing → wire-type source** — `polyTypedVariable.getDeviationSummary()`
  (dominantType/dominantAffinity), `simulations/storage_predictor.TYPE_BYTES`
  idiom for conservative sizing. The proto field mapping mirrors the
  affinity mapping the DB adapters already use (one typing rule).
- **Sidecar-service pattern for heavy deps** — msci-engines /
  cad-engines (Debian workers, `docker save | ssh | docker load`,
  swarm-pinned, `/capability` honesty). If grpcio won't ride the
  Alpine backend image, the bridge becomes a worker service instead —
  same idiom, no new invention. (grpcio publishes musllinux wheels
  since ~1.59, so in-backend is EXPECTED to work; verify in grpc-2
  before committing to a sidecar.)
- **Knobs-and-suggestions + honest absence** — standing principles.
  Exposure is a per-class KNOB row; nothing auto-enables. Refusals
  name the gate (e.g. "class not stabilized — run traffic through it
  or stabilize manually via /api/schema/stability/{class}").
- **Resource profiles / admission (res-2/4)** — a grpc bridge service
  gets a `ModuleResourceProfile` + PROVIDER_PORTS entry like every
  other service, so placement stays resource-aware.

New module home: `polari-rf-node/polari-framework/grpcbridge/`.

---

## PHASE grpc-1 — Contract layer: .proto from stabilized schemas (stdlib-only, no grpcio)

### Objects (`grpcbridge/contract_basis.py`)
- **`GrpcExposure`** (treeObject) — THE KNOB, one row per exposed class:
  `name` ('<class>-grpc-exposure'), `subject_class`, `enabled: bool`
  (default False — never auto-on), `service_name`
  ('PolariObjectSync.<Class>'), `transport_preference`
  ('stomp' | 'grpc' | 'both' — grpc-3 reads this), `proto_version:
  int`, `contract_hash` (hash of the field snapshot the proto was
  generated FROM), `contract_status` ('current' | 'stale' |
  'never-generated'), `proto_text` (the generated .proto, stored ON
  the row — object-coherence), `generated_at`, `notes`.
- **`ProtoContractVersion`** (treeObject) — immutable history row per
  generation: subject_class, version, contract_hash, proto_text,
  field_map_json (field -> proto type + tag number), generated_at,
  reason ('initial' | 'schema-adapted' | 'manual-regenerate').
  **Tag numbers are append-only across versions** (proto wire compat:
  a field never changes tag; removed fields become `reserved`).

### Analysis (`grpcbridge/proto_gen.py`, stdlib-only)
- `proto_type_for(summary)` — affinity → proto3 mapping: INTEGER→
  `int64` (bool→`bool` when dominantType is bool), REAL→`double`,
  TEXT→`string`, variant/complex/list/dict → `string` + a
  `// JSON-encoded (schema strategy: variant)` comment (HONEST: the
  wire says what it really carries).
- `generate_proto(manager, class_name)` — REFUSES unless
  `is_stabilized()` (the gate; suggestion names the stabilize knob).
  Reads the STABILIZATION snapshot (`field_summary_json`), not live
  typing — the contract matches what was trusted. Emits one
  `message <Class>` + the sync service:
  ```proto
  service <Class>Sync {
    rpc Get (ObjectKey) returns (<Class>);
    rpc List (ListRequest) returns (stream <Class>);
    rpc Watch (WatchRequest) returns (stream ChangeNotification);
    rpc Push (stream <Class>) returns (PushSummary);  // hardware in
  }
  ```
  plus shared messages (ObjectKey {id, instance_id}, ChangeNotification
  mirroring the STOMP payload shape — parity by construction).
- Tag-number ledger: reuse prior `ProtoContractVersion.field_map_json`
  so re-generation preserves tags; new fields get the next tag;
  missing fields become `reserved N`.
- `contract_hash(snapshot)` — stable hash; `check_contracts(manager)`
  — for every enabled exposure, compare hash vs the CURRENT
  stabilization snapshot → mark 'stale' + a suggestion (regenerate =
  a human/API act). **Wire into schema_stability.record_deviation**:
  destabilization flips dependent exposures to 'stale' immediately
  (failure-isolated, same pattern as the save hooks).

### API (`grpcbridge/contract_api.py`)
`GET /api/grpc/exposures` (catalogue + status),
`POST /api/grpc/exposures/{class}` {action: enable|disable|regenerate}
(enable on a non-stabilized class = refusal naming the gate),
`GET /api/grpc/exposures/{class}/proto` (text/plain .proto download).

### Acceptance
`selftest_contracts.py` (stdlib, fake manager): non-stabilized class
refused with the stabilize suggestion; stabilized class generates a
proto with correct type mapping (int→int64, float→double, str→string,
variant→string+comment); tag numbers survive regeneration (field
added → new tag, field removed → reserved); destabilization marks the
exposure stale + the event links; hash stability; knob defaults off.
LIVE: enable an exposure for a stabilized class (e.g.
PolariNodeMachine), download its .proto, `protoc --decode_raw`-level
sanity (or just structural assert), OOPS the class (the mem_gb trick)
→ exposure flips stale with evidence.

---

## PHASE grpc-2 — Serving layer: the sidecar gRPC server (grpcio)

- Add `grpcio` (+ `grpcio-reflection`) to requirements; verify the
  musllinux wheel installs on the Alpine image (it should; if the
  build fights back, pivot to a Debian `grpc-bridge` worker service —
  msci-engines pattern, `docker-compose.grpc-bridge.yml`, swarm-pinned,
  and the backend talks to it over localhost gRPC).
- `grpcbridge/grpc_server.py` — mirrors StompWebSocketServer exactly:
  sidecar thread, `GRPC_ENABLED`/`GRPC_PORT` (default :3002) knobs,
  module-level `get_grpc_server()`/`set_grpc_server()`, started by
  polariServer next to the STOMP server.
- **Generic serving, no per-class codegen at runtime**: implement
  `Get/List/Watch/Push` as GENERIC method handlers
  (`grpc.method_handlers_generic_handler`) keyed by the GrpcExposure
  rows; serialize from the object tree using the stored field_map
  (manual protobuf encoding via `google.protobuf` descriptor_pool
  built FROM the stored .proto text — `grpcio-reflection` exposes the
  contracts to clients; grpcurl becomes the live-verify tool).
- Watch stream: subscribe to the SAME notifications STOMP publishes —
  refactor `polariCRUDE._notify_ws_subscribers` into a tiny transport
  MUX (`grpcbridge/transport_mux.py`): publish(className, payload) →
  STOMP and/or gRPC watchers per the class's `transport_preference`
  knob. STOMP behavior with the knob unset stays byte-identical.
- Auth: reuse the Keycloak JWT (metadata `authorization` header,
  validated with the same accessControl machinery falcon uses).
  Hardware devices get service-account tokens (out of scope until
  grpc-4; the seam is named).

### Acceptance
selftest with grpcio if importable (skip honestly otherwise): server
starts, reflection lists enabled services only, Get/List round-trip a
stabilized class, Watch receives a change notification when a row
saves, disabled/stale exposures refuse with evidence. LIVE: grpcurl
against :3002 (reflection + Get + Watch while touching a row via the
REST API); STOMP untouched (frontend still works).

---

## PHASE grpc-3 — STOMP stand-in parity + measured efficiency

- `transport_preference='grpc'` routes a class's change notifications
  ONLY to gRPC watchers ('both' = dual-publish, the migration mode);
  the ChangeNotification proto carries the exact fields of the STOMP
  JSON payload (parity by construction, asserted in tests).
- **Measure, don't claim** (res-3 idiom): a small harness publishes N
  notifications + M object syncs over both transports and records
  bytes-on-wire + wall time into the exposure row
  (`efficiency_note_json`, labels travel). The knob stays a knob —
  the numbers inform the human's choice, nothing auto-flips.
- Frontend note (out of scope here): browsers cannot speak native
  gRPC; the Angular app KEEPS STOMP until a grpc-web/Envoy decision
  is made deliberately. grpc-3 parity is for backend↔backend,
  peer↔peer, and hardware clients.

### Acceptance
Parity assert (same payload fields both transports), dual-publish
works, grpc-only works with STOMP silent for that class, measurement
rows populated with honest labels. LIVE on the swarm: a peer backend
(twin-B) Watch-streams a class from prf-a over gRPC.

---

## PHASE grpc-4 — The hardware signal bridge (the destination)

- **`HardwareSignalDefinition`** (treeObject, `grpcbridge/hardware_basis.py`):
  maps a device signal → object field: device_name (future
  PolariNodeMachine-like row for MCU/FPGA nodes), channel/register
  (the Hardware Runtime register-map vocabulary from the hardware
  architecture memory), subject_class + field, direction
  ('telemetry-in' | 'command-out'), unit, sample_rate_hz, deadband
  (send-on-change threshold — the efficiency knob for chatty
  sensors).
- Bidirectional streaming: hardware clients call
  `Push (stream <Class>)` for telemetry; a `Commands (WatchRequest)
  returns (stream <Class>)` server-stream carries commands down.
  Incoming signals land as object-tree updates → the SAME transport
  MUX fans them out (gRPC watchers AND stomp topics — a browser
  dashboard sees hardware signals with zero extra plumbing).
- **Embeddability lint** (`nanopb_lint(proto_text)`): MCU-class
  devices use nanopb/pb subsets — the linter REFUSES contracts that
  won't embed (unbounded strings without max_size hints, maps, deep
  nesting) with evidence naming the field, so "this contract can run
  on the SAMD21 tier" is a checkable claim, not hope.
- Simulated-hardware selftest client (pure python grpc client
  streaming synthetic sensor frames) + LIVE: stream synthetic
  telemetry into a stabilized class from another swarm node and watch
  it arrive in the Topology/STOMP world.

### Acceptance
Signal definition rows round-trip; Push telemetry lands as scoped
object updates and fans out to both transports; deadband suppresses
unchanged samples (counted, honest); nanopb lint refuses an
unbounded contract naming the field; command stream reaches the
simulated device. LIVE across two swarm nodes.

---

## Cross-phase notes
- **The gate IS the feature**: only stabilized schemas get contracts;
  every OOPS (SchemaDeviationEvent) marks dependent contracts stale
  with evidence. Contract versions are append-only with preserved tag
  numbers (wire compatibility) — `reserved` for removals.
- **Knob, not automation**: enabling exposure, regenerating a stale
  contract, and flipping transport_preference are all human/API acts;
  the system only suggests.
- **Shared-DB interaction**: ObjectKey carries (id, instance_id) —
  the composite identity introduced by the shared object DB
  ([[shared-object-db]]); a hardware signal targets one instance's
  row explicitly.
- **Deps strategy**: grpc-1 is stdlib-only (ship value before the
  dependency fight); grpc-2 tries grpcio-on-Alpine (musllinux wheels),
  falls back to the proven Debian worker pattern.
- **Ports**: :3002 gRPC next to :3001 STOMP; PROVIDER_PORTS +
  ModuleResourceProfile rows if the sidecar becomes a worker service.
- Branch per phase; repos are PUBLIC — no secrets in protos or
  committed configs.
