# gRPC on Stabilized Objects — Bridge Plan

## PICK UP HERE (stamped 2026-07-11) — next agent starts grpc-3

- **STATE**: grpc-1 ✅, grpc-2 ✅ (see the phase-2 stamp below:
  dev-grpc-2-serving, 23/23 + live 10/10 on :3002), grpc-j1 ✅,
  grpc-j2 ✅ (sim-rig round trip live). **NEXT = grpc-3** (transport
  parity + measured efficiency + peer↔peer Watch), then grpc-4
  (hardware signal bridge), grpc-j3 (firmware twin header).
- **NEW CONTEXT since the phases below were written (xsim/modsplit
  work, 2026-07-10→11 — see CROSS_INSTANCE_SIM_PLAN.md):**
  - `grpcbridge/transport_mux.py` is now ALSO the STOMP publish seam
    for all CRUDE notifications (polariCRUDE delegates to
    `publish_crude_change`); the per-class ws leg is the
    `polariTreeWsEnabled` knob (default False, PUT /api-config/formats).
  - **Module gating** (`POLARI_MODULES`, polariApiServer/
    module_gating.py): grpcbridge's classes are gated like any domain
    module — an instance without it serves NO contract services and
    aborts FAILED_PRECONDITION naming the exposure knob (live-verified
    on a module-scoped instance). Instances meant to serve contracts
    need grpcbridge in their POLARI_MODULES (or the knob unset).
  - **The class directory** (`GET /api/refs/directory`, polariRefs/
    refs_api.py) advertises a per-module-provider `grpcTarget`
    (declared via PeerNode.identity_json). grpc-3's peer↔peer Watch
    should RESOLVE its target through this directory rather than
    hardcoding addresses — that makes gRPC the third
    directory-coordinated transport (CRUDE + STOMP already are).
  - Cross-instance writes now carry fencing tokens
    (X-Polari-Lease-Token; simulationLocks/lease.py validate_token,
    remote_api.validate_epoch_for_owner). grpc-4's command-down path
    for MUTATING commands should present the same token when the
    mutation originates from a simulation run (the seam is
    polariRefs/remote_writes.py — reuse, don't reinvent).
  - Single-writer object locks: hardware telemetry Push lands as
    object updates — `simulationLocks.object_locks.check_write` is the
    enforcement seam CRUDE uses; grpc-4 Push should consult it too
    (telemetry to a run-locked row = honest refusal, journal-worthy).
- **Deploy/verify conventions**: suite-level
  `docker-compose.staging-nip.yml --env-file .generated/.env.staging`;
  after EVERY `up -d --build` run `docker exec pol-proxy nginx -s
  reload` AND retry the first request (stale-upstream 504s; if they
  persist `docker restart pol-proxy`). Backend boot ~150-200s. 66-test
  suite in-container has 12 KNOWN pre-existing failures (8F+4E in
  test_api_profiler/test_crude_api) — the bar is "identical list",
  not green. Smoke: tests/live_api_smoke.py = 22/22. Branch per
  phase off `dev-modsplit-3` (the current framework HEAD lineage:
  dev-xsim-1-refs→…→dev-modsplit-3 201b72f). Repos PUBLIC — no
  secrets; NOT pushed without Dustin.

**Written 2026-07-09 as a durable, GPT-4-executable handoff (Dustin's
directive).** Goal: a **knob, not automation** —
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

**✅ BUILT + LIVE-VERIFIED 2026-07-10 (framework branch
dev-grpc-2-serving).** grpcio 1.74.0 musllinux wheel rides the Alpine
image directly — NO Debian worker needed. Descriptors are built
programmatically from the stored tag ledger (field_map_json), not by
parsing .proto text (`descriptor_build.py`); one GenericRpcHandler +
per-stream dynamic reflection serves everything. Transport MUX at the
CRUDE notify seam; `set-transport` knob act added. selftest_serving
23/23; live 10/10 on staging :3002 (reflection-learned client, Get
parity vs REST, refusals naming knobs, Watch on REST touch, Commands
full-object down); 22/22 smoke untouched.

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

## PHASE grpc-j1..j3 — Java host bridge (no-code → Java, installs on Ubuntu)

**Added 2026-07-09 from Dustin's hardware-interface conversation.** The
host-side hardware runtime is the **"Polari Hardware Bridge"** — a
lightweight headless Java app whose job is to let Polari communicate
with hardware whenever it wants to. NOT a kernel module, NOT a GUI
(no JavaFX). **Long-term this becomes an isle-app; temporarily it is
internal SIMULATION software** — the generated bridge ships with a
built-in simulated-MCU source and transitions to the real serial
device later by flipping one knob (`source: simulated | serial`),
nothing else changes. Standardize all three layers:

- **Physical**: USB-C (USB 2.0, CDC-ACM → `/dev/ttyACM0`) computer↔MCU;
  SPI MCU↔FPGA (the FPGA only sees digital signals; SPI is the
  open-ecosystem sweet spot — every MCU speaks it, easy in FPGA logic,
  low pin count).
- **Transport**: ONE universal versioned binary packet for every board
  (LED, CNC, laser, sensor): `magic u16 | version u8 | msg_type u8 |
  device_id u16 | sequence u32 | payload_len u16 | payload | crc32` —
  little-endian, CRC over header+payload. The OS just sees bytes; the
  runtime interprets them.
- **Application**: generated structs/Protocol Buffers mapping directly
  to Java (later Python/Rust/C++) APIs — generated FROM the same
  stabilization field_map the .proto came from, so firmware, Java, and
  Polari agree by construction.

The runtime is BIDIRECTIONAL — the same app serves both directions,
in simulation today and against real hardware later:

- **Telemetry up**: read packets from the device (`/dev/ttyACM0`, or
  the built-in simulated MCU) → deserialize struct payloads →
  convert to protobuf → `Push` over gRPC into Polari (grpc-2 server)
  → object tree → STOMP fan-out.
- **Commands down**: subscribe to the class's `Commands` server
  stream over gRPC (Polari decides an operation whenever it wants) →
  proto → struct payload → PolariPacket → write to the device over
  USB. The MCU applies it (in simulation: the synthetic MCU updates
  its state, which its NEXT telemetry frames reflect — the round
  trip is provable without hardware).

One seam makes the sim→real transition trivial: `DevicePort`
(read packet / send packet). `SimulatedDevice` and `SerialCdcPort`
are the only two implementations; everything above the seam is
identical.

- **grpc-j1 — the generator (THE no-code capability)**:
  `HardwareBridgeDefinition` (treeObject, the knob: bridge name,
  source `simulated | serial` (default simulated — the internal-sim
  phase), serial device + baud (used when source=serial), exposed
  classes, target gRPC endpoint, msg_type↔class map) +
  `grpcbridge/java_bridge.py` (stdlib string templating, same idiom
  as proto_gen) emits a COMPLETE buildable Maven project — the
  Polari Hardware Bridge app:
  `PolariPacket.java` (universal packet codec + CRC32, resync-safe
  framing), per-class record + binary codec from the field_map
  (int64/double LE, length-prefixed UTF-8 strings — the C-struct
  twin), the two `DevicePort` implementations (`SimulatedDevice`:
  synthetic telemetry AND command handling — a command packet
  updates its state, reflected in subsequent telemetry;
  `SerialCdcPort`: plain file I/O on ttyACM* + `stty` raw config —
  no native deps), `BridgeMain` (the bidirectional loop),
  `GrpcForwarder` (proto⇄struct conversion both directions: Push up,
  Commands-stream down; reflectively loaded so the core has zero
  gRPC deps), `pom.xml` (protobuf-maven-plugin + grpc-java, the
  generated .protos embedded — bundled as ONE `polari_bridge.proto`:
  shared messages once + every class message/service),
  `install-ubuntu.sh` + `polari-hw-bridge.service` (systemd).
  Downloadable as a tar.gz from the API. The contract service gains
  `rpc Commands (WatchRequest) returns (stream <Class>)` in grpc-1
  so the app can wire command-down the moment grpc-2 serves it.
  Acceptance: selftest generates a project for a fake stabilized
  class and COMPILES + RUNS the dependency-free core with javac when
  available (skip honestly otherwise): loopback frame round-trip,
  corrupted-CRC rejection, AND the command round-trip (send a
  command packet to the simulated MCU → its next telemetry frame
  reflects the commanded state); refusals inherit the stabilization
  gate.
- **grpc-j2 — live loop (still simulation)**: **✅ LIVE-VERIFIED
  2026-07-10 on staging: sim-rig bridge (Maven-built jar, javac 22 /
  mvn 3.6) streamed 600 synthetic frames @10.1 fps → gRPC Push into
  prf-a :3002 → ONE stable object row per class (identity = the
  `name` convention, sim-<class>) → 601 STOMP notifications observed
  through pol-proxy wss (the browser leg). REVERSE proven: REST PUT
  notes=commanded-by-polari → Commands stream → simulated MCU applied
  it → 82 subsequent telemetry frames echoed the commanded state →
  row persisted. Schema-stability interplay proven live too: sim
  strings OOPSed the trusted bool field → contract auto-flipped stale
  → pushes refused with evidence → re-stabilize + regenerate (v2, no
  retired tags) → loop clean. Measured run recorded on the bridge row
  (notes JSON). New `configure` knob act = the sim→serial transition.**
  Original spec: generated bridge runs
  on Ubuntu (systemd), source=simulated streams synthetic packets →
  bridge decodes → gRPC Push into prf-a (needs grpc-2) → object tree
  → STOMP fan-out visible in the browser; and the reverse: touch a
  row in Polari → Commands stream → bridge → simulated MCU state
  changes → telemetry confirms. Measured frames/sec + bytes recorded
  on the bridge row (res-3 idiom). Flipping source=serial against a
  pty is the transition rehearsal; real hardware later changes
  NOTHING in the app.
- **grpc-j3 — firmware twin**: generate the matching C header
  (`<class>_packets.h`, packed structs + CRC, nanopb-compatible
  naming) from the SAME field_map + run the grpc-4 embeddability lint
  on it, so "this contract runs on the SAMD21 tier" stays checkable.

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
