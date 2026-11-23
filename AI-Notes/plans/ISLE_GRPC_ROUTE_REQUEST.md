# Request to isle-core: carry a Polari node's gRPC on the isle (`grpc.<node>.isle`)

Written 2026-11-23 on pol, for isle-core's own Claude/Codex, who own `~/Isle-Mesh`. pol changes no isle code.
State words: source-tested, staged, installed, live-verified.

## 1. What the user asked

The user, 2026-11-23: "an isle route request would be ideal. It should act identical to how we would bridge to real
hardware with a mapping of structs that go into the engine to a mapping of object instances on the polari side."
Also: "this is not a public app yet". The route is isle-internal: a `.isle` name behind the agent, with no public
exposure.

## 2. Why

A Polari Hardware Bridge reads a board's structs and keeps the matching Polari objects current over gRPC (Push up,
Commands down, Watch). Which structs become which objects is data: `WireContract`, `HardwareInterfaceBinding`,
`EnumMapping` (brd-wire), and `StructObjectMap` + `PolariBridgeInstance` (hsp-3a). The backend's one generic handler
serves `/polari.sync.<Class>Sync` for every exposed class, so the route needs nothing per class.

A bridge for a twin is the same bridge as one for a cabled board: the same instance, definition and maps, and the same
node. Only its far end differs (a twin session's line instead of a serial port). That already works up to the
backend's door. It was proved live both ways on 2026-10-19 on the swarm, against an open port 3002.

On an installed isle app nothing carries that port. The backend's gRPC server listens in plaintext on 3002 inside
its container, and the agent serves HTTPS by name only. So neither a cabled board's bridge nor a twin's can reach
an installed node.

## 3. What pol built (source-tested 2026-11-23, polari-framework `dev-bridge-link`)

- `grpcbridge.custom.bridge_link`: a bridge's target comes from its `PolariBridgeInstance`. For node `<n>` that is
  `grpc.<n>.isle:443` with `grpc.tls=verified`, checked against the isle trust bundle (the generated bridge's
  `IsleTrust`). No host or port is written by hand, and the name follows the node's name. An instance that is not
  bound, or that names no definition, is refused in words.
- `POST /api/grpc/hosted-bridges {session, instance}` and `pol grpc hosted start <session> --instance <name>`. These
  run the instance's own bridge beside a twin session, pushing to the instance's node. A target or a bridge name given
  beside an instance is refused. A bridge worker that does not repeat `grpc_tls` in its answer has its bridge stopped,
  and the start is refused (424). It is never left to dial the isle in plaintext.
- `prf-bridge-engines/bridge_hosted.py`: accepts `grpc_tls` (`verified` | `plaintext`), writes it into the bridge's
  properties and repeats it.
- Without an instance nothing changes. A dev stack's explicit `host:3002` with the generated `grpc.tls=plaintext` still
  works, said aloud.

## 4. What is asked of the isle

1. **A gRPC protocol in the agent's service config.** Today `generate-nginx-configs.sh` writes
   `proxy_pass ${SVC_PROTOCOL}://…` with `proxy_http_version 1.1`. A service registered with `--protocol grpc` would
   then need:
   - a `location /` with `grpc_pass grpc://<upstream>;` on the existing `listen 443 ssl http2` server;
   - no `Upgrade` or `Connection` headers;
   - long `grpc_read_timeout` / `grpc_send_timeout` values, because Watch and Commands are long-lived streams. Sixty
     seconds would cut them, so perhaps an hour, with the bridge reconnecting after that;
   - `client_max_body_size` left at its default, since frames are small.

   The leaf certificate is issued by the existing hook for the name. `nginx -t` on the candidate stays the gate.
2. **The node's gRPC name, as data.** `isle polari instance deploy --name <n>` registers `<n>.isle` and
   `api.<n>.isle` today. It should also register `grpc.<n>.isle` → the backend container's gRPC port (3002) with
   protocol `grpc`, and its DNS entry, the same way as `api.<n>.isle`. It is a door of the node itself, not a
   hand-made upstream. If the release format grows declared doors (for example `deploy.doors: [{name, port,
   protocol}]`), this is a natural first user, but that is the isle's choice.
3. **Not asked:** passing raw TCP through 443 by SNI (TWIN_DOOR_PLAN §8 still holds), or any public route.

## 5. Open for the isle (its call, said back to pol)

- The name. `grpc.<n>.isle` is recommended: one name per door, so the agent's one-name-per-service shape holds. The
  other option is routing `application/grpc` on `api.<n>.isle` itself. If the isle picks another spelling, pol
  changes `bridge_link.grpc_name`, which is one function.
- The stream timeout value.

## 6. Owed elsewhere (pol / econ, not this request)

- `bridge-engines` as a store app: the isle trust bundle mounted at `/etc/isle-trust` (or `ISLE_TRUST_BUNDLE`), its
  image build (downloads, needs the user's word), its release.
- After a gRPC push error the generated bridge does not re-open its Push stream (TWIN_DOOR_PLAN §9 open 4). A stream
  timed out by the agent would show the same gap, so this should be fixed before the live proof.
- The live proof, after an isle release carries the route. Start a twin session and
  `pol grpc hosted start <session> --instance <bridge> --api https://api.<n>.isle`. A press then reaches the node's
  row, and a command from the node reaches the twin. The same instance later runs on a cabled board with no change but
  its far end.

## 7. How pol tested its half

Offline, with fake workers and the real bridge worker module: `grpcbridge.grpcbridge_hosted_selftest` 79 of 79 (14
new link checks), `grpcbridge.bridges_selftest` 9 of 9, `grpcbridge.javabridge_selftest` 51 of 51. Not tested: a TLS
gRPC call through a real agent (no route exists yet).
