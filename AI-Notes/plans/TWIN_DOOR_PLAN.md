# Twin door plan — reaching twin sessions through the agent by name

Status: REVIEWED and answered by the user 2026-11-15 (§7). Both halves are SOURCE-TESTED; econ's half is also packaged.
Nothing is staged on the core, installed or live. See §9 for the state per slice.
Authors: econ Claude (worker + release half, §4), pol Claude (framework half, §5).
Date: 2026-11-15. This is the one merged file (econ draft + pol's §5, §5a, D4, D5; merged by econ). The user reviews this one.

## 1. The problem

The Sim bench on pol cannot reach a twin session on econ's board-engines worker.

- The Electronics backend dials `Hub(host, ctl_port, token)` as plain TCP on a per-session port in 9832-9863
  (`polari-framework/modules/board/custom/twin_sessions.py:147-162`).
- `board-engines.isle` resolves to econ's agent. The agent serves 80/443 only. The worker container exposes
  9830-9863 but publishes nothing on the host. The dev compose works only because it publishes the range.
- Seen 2026-11-15 from the Sim bench: `POST /api/board/twins` → 502 "the session started on the worker but its control
  port could not be reached from here (board-engines.isle:9833 … Connection refused); it was stopped."

## 2. The standard we follow (verified live 2026-11-15)

Each purpose is its own app with its own name. `polari` = `polari.isle:4200`, `polari-api` = `api.polari.isle:3000`.
Each gets its own leaf certificate, its own nginx block, and is published by the core's DNS sync.
So the twin door is one more app with one more name. No change to certificates, DNS or the agent.
From econ: `api.polari.isle` resolves by the isle router DNS to its agent address, HTTPS 200, certificate verifies.

## 3. The door contract (worker-generic, belongs in the board engines contract)

Name: one per worker purpose — `twin.board-engines.isle` now, `twin.esp-engines.isle` when pt-4 lands.
Not per chip: one worker hosts several chips, and the first twin needed is the UNO.

Two streams per session, both WebSocket over HTTPS on 443:

| Path | Carries | Frames | Dialled by |
|---|---|---|---|
| `/sessions/<id>/ctl` | the Hub control line (newline-JSON) | text, one JSON line per frame | Electronics backend |
| `/sessions/<id>/uart` | the firmware serial stream | binary, raw bytes | hosted bridge (Java), on any machine |

A third path (`/pins`) can be added later for the pin-twin GPIO channel without a new name.

Rules:
- The first frame on either path is `{"token": "..."}`. The token never appears in a URL.
  On `ctl` the door checks it and passes it on (the twin acks it, as today). On `uart` the door checks and consumes it.
- A wrong token, unknown id or ended session closes the socket with a reason before any twin byte flows.
- The door sends a WebSocket ping every 20 s (the agent drops a proxied connection after 60 s of silence; a UART can be
  silent longer; the ctl line never is: the twin pushes status every 500 ms).
- One connection per stream per session; a new one replaces the old (the backend re-dials lazily).
- The worker's `GET /capability` advertises the transports it offers, e.g.
  `"transports": {"ctl": "wss://twin.board-engines.isle/sessions/{id}/ctl", "uart": "wss://…/uart"}`.
  Callers pick a transport from that, never by guessing from the URL. Plain TCP stays for the dev compose.

### 3a. Contract details fixed while building (econ, 2026-11-15)

- `transports` is a top-level key of `GET /capability` (beside `sessions`), present only when the worker has a door
  configured (`TWIN_DOOR_URL`). `{id}` is the literal placeholder.
- ctl frames: the door sends each twin line as one text frame WITHOUT the trailing newline, and accepts client frames
  with or without it. A binary frame on ctl, or a text frame on uart after the token, closes the socket.
- The token frame must arrive within 5 s. On ctl the twin's own `{"t":"ack"}` comes back as the first frame.
- Close codes: 4400 bad first frame, 4401 no token in time, 4403 wrong token, 4404 unknown session, 4410 session ended
  or twin closed the stream, 4409 replaced by a newer connection, 4502 the twin's port could not be reached.
- Before the upgrade: a path that is not `/sessions/<id>/ctl|uart` is HTTP 404; `GET /health` is HTTP 200 (the
  release's health path).
- The door listens on 9864 inside its own container (9831 is taken by the dev `pol board twin` container).

## 4. Econ half — the worker door and its release

Facts read from source (`polari-rf-node/prf-board-engines`):
- The worker is a falcon app under gunicorn (one sync worker). It cannot accept WebSocket upgrades itself,
  so the door is its own small process.
- Sessions are files under `/srv/sessions` (id, ports.tcp, ports.ctl, token, expires).
- The twin binds both session ports on all interfaces. The uart port has no token check today, so any
  container on the worker's networks can already open it. The door closes that gap for outside callers.

Work:
1. `twin_door.py` in prf-board-engines: a WebSocket server on one port that implements §3 and joins each
   accepted socket to the session's internal TCP port.
2. A token check the door can use: `POST /sessions/<id>/check` on the worker (204 or 403), or reading the
   session file directly when the door shares the worker's container (see D1).
3. `/capability` gains the `transports` block.
4. Release: the door ships as an app named for its domain, deployed with the standard `isle` release verb.
   Registration, leaf certificate and DNS publication then happen exactly as for any app.
5. Tests: a selftest that starts a twin session, joins both paths through the door, proves the wrong-token,
   unknown-id and ended-session refusals, and proves a 90 s silent uart stays up.
6. (from pol, see §5a) Generated bridges need the isle trust bundle to verify `wss://`. Read from isle source: the
   bundle is not baked into images; the Polari backend gets it as a host mount (`/etc/ssl/certs:/etc/isle-trust:ro`
   plus `SSL_CERT_FILE`) written by the isle's Polari component config. Engine releases get no such mount today
   (the installed board-engines compose has no volumes). So this is a release-compose change for bridge-engines,
   not an image change.
7. bridge-engines is not an installed isle app on econ or core today (econ has board-engines only). The uart path can
   be source-tested and proved with a test client, but the live bridge proof in §6 step 5 needs bridge-engines
   released somewhere first. See D6.

## 5. Pol half — the framework (polari-framework, pol's lane)

Facts read from source and from the running 87 images (2026-11-15):
- `board.custom.twin_ctl_hub.Hub` (:57-185): newline-JSON request/reply + pushed events; `_dial` (:71-77) is the single
  socket seam and already runs under `outbound.wrap('engine','board','twin-ctl')`; the reader thread splits on `\n`;
  `close()` only uses `SHUT_RDWR` to wake its own reader. Nothing else assumes a raw socket.
- `twin_sessions.py`: rows keep `host`, `tcp_port`, `ctl_port` (:80, :151-152); `HUBS[name] = Hub(host, ctl_port, token)`
  at start (:155) and lazily (:216); the status view prints `ports: serial report N, control M` (:82).
- `grpcbridge.custom.hosted_bridges.start` (:139-158) hands `twin_host` + `twin_port` to the bridge-engines worker; the
  generated Java bridge opens them with `TcpDevicePort`/`TcpOpener` (`java_bridge_templates.py:520-536`), implementing
  `DevicePort { next(); send(); close() }` (:194-202).
- Backend image (prf-polari-pol-backend, 87): Python 3.12, **`websockets` 13.1 already installed** (sync client present),
  and the default SSL CA file is `/etc/isle-trust/ca-certificates.crt` (the isle root is in the bundle) → `wss://` with
  verification works with no new dependency and no trust knob.
- bridge-engines image: openjdk-21-jdk-headless, generated pom targets release 17 → `java.net.http.WebSocket` (JDK 11+)
  is available with **no new Maven dependency**. The image has only Debian `ca-certificates`; the isle root is NOT in the
  JVM's cacerts, so a `wss://` opener must build its own `SSLContext` from a PEM bundle (see §5a).
- Also seen, out of scope but recorded: the generated bridge's gRPC channel is `ManagedChannelBuilder.forTarget(target)
  .usePlaintext()` (`java_bridge_codegen.py:486-487`) — the bridge→backend leg is plaintext today.

Work (each item = one slice with its selftest; names are suggestions):
1. **td-1 capability-driven transport.** `board_engines` capability reader keeps `transports` (dict or absent). A new
   `twin_transport.py` picks, per session, `ctl` = `transports.ctl` with `{id}` filled when present, else
   `tcp://host:ctl_port`; same for `uart`. The choice and its reason are stored on the TwinSession row
   (`ctl_url`, `uart_url`, `transport_why`) and shown in the status view instead of "control M". No URL sniffing.
2. **td-2 Hub over WebSocket.** `Hub(url, token)` replaces `Hub(host, port, token)`; `_dial` returns a small
   line-oriented adapter: for `tcp://` the socket as today; for `wss://` `websockets.sync.client.connect(url,
   ssl=ssl.create_default_context())` (verified against the isle bundle), sending `{"token"}` as the first text frame,
   then one JSON line per frame both ways; `close()` closes the websocket (no SHUT_RDWR). Reader thread, replies queue,
   `recent`, subscriptions, `request()` timeouts unchanged. Keepalive is the door's ping; the client answers pongs.
   Refusal words keep the same shape ("the twin control channel <url> is unreachable: …").
3. **td-3 sessions + hosted bridge.** `twin_sessions` stores `ctl_url`/`uart_url` (keeps `host/tcp_port/ctl_port` for the
   TCP fallback and for the existing receipts); `hosted_bridges.start` passes `twin_uart` (a URL) beside the old
   `twin_host/twin_port` so an older bridge worker still works; the bridge worker request schema gains the field.
4. **td-4 Java WebSocket device port.** `WsDevicePort implements DevicePort` beside `TcpDevicePort` in
   `java_bridge_templates.py`: `java.net.http.HttpClient` with an `SSLContext` built from the PEM bundle at
   `ISLE_TRUST_BUNDLE` (default `/etc/isle-trust/ca-certificates.crt`), `newWebSocketBuilder().buildAsync(uri, listener)`,
   first text frame `{"token"}`, then binary frames ↔ the same `SerialCdcPort` framing TcpDevicePort wraps today
   (`inner` over a pipe), so `next()`/`send()` are unchanged. The opener is chosen by the `twin_uart` URL scheme
   (`tcp://` → TcpOpener, `wss://` → WsOpener); `source=serial` for real boards is untouched.
5. **td-5 Sim bench words.** The bench shows which transport a session uses and why (from the row), and the 502-class
   refusals are shown where the user can see them (the UI review item: the action message is rendered below the table
   inside the scroll box; move it above the table). The frontend half is the same lane (pol).
6. **td-6 selftests.** `board_twin_transport_selftest` (capability → choice, with/without transports, malformed URL
   refused), `twin_ctl_hub` fakes gain a WebSocket twin (token ack, watch, events, refused token, server close → `closed`
   event), `hosted_bridges` fake asserts `twin_uart` is passed, a Java template compile check for `WsDevicePort`
   (the existing template compile gate), and the negative: a worker advertising `transports` whose door is down → the
   session is refused with the door's URL in the words (never a silent fallback to TCP when a door is advertised).

Not changed: `twin_pty` (dev only, TCP), `TcpDevicePort`, the real-board serial path, the packet framing, the SSE
`/events` door the browser uses.

### 5a. What pol needs from econ's half

- The bridge-engines worker must mount or copy the isle trust bundle at a known path (`/etc/isle-trust/…` as the
  backend image does) and pass `ISLE_TRUST_BUNDLE` to the bridge JVM; otherwise `wss://` from the bridge fails to verify.
- The door's `uart` path must accept binary frames of any size and preserve byte order (no line splitting).
- The `transports` block in `/capability` is the contract the backend keys on; its exact JSON shape is fixed in §3.

## 6. Order of work

1. User reviews this plan and answers §7.
2. Source work on both halves, each with its selftest. State: source-tested.
3. Build the image(s) and release on econ. State: staged.
4. User runs the `isle` deploy on econ. State: installed.
5. Live proof from pol: start a session from the Sim bench, see pin events arrive, flash and run a bridge over
   the uart path. State: live-verified.
Each step is reported in those words, never merged. Every step the user runs is an `isle`/`pol` CLI verb.

## 7. Decisions for the user

ANSWERED 2026-11-15 (the user, in the pol session, relayed by pol): "for 5 fold tls in, will go with recommendations.
For 7 yes we need to live prove the control path first, then track needing to have it as something to incorporate.
I think we can try to release it and prove it as a release, the releases are our way of testing currently so when we
develop things doing the release is required to be able to test".
Read as: D1 (a) own release and container. D2 (a) the `websockets` package. D3 `twin.board-engines.isle`. D4 refuse,
never fall back silently. D5 fold bridge gRPC TLS into td-4 now. D6 (a) live-prove the control path first; bridge-engines
is tracked as a follow-on, then released and proved as a release. Rule restated: a release is how we test, so
source-tested is never the end state.

D1. How the door is packaged.
- (a) Its own small release and container (`board-engines-twin` → `twin.board-engines.isle`), same image,
  different command. Follows the `polari` / `polari-api` precedent exactly. Needs no isle change. Recommended
  for proving it by hand.
- (b) A second process inside the worker container, with the release declaring two named doors for one
  container. Tidier at runtime (the twin ports could then bind to loopback only), but the isle release format
  and registration handle one name per app today, so this is an isle change for the 88 round.

D2. The WebSocket code in the door.
- (a) The `websockets` Python package, pinned by sha256 like pyvcd. One PyPI download to approve. Recommended
  (pol note: the backend image already ships `websockets` 13.1, so the same package on both ends).
- (b) A hand-written minimal server on the standard library. No download, about 150 lines we then own.

D3. The name: `twin.board-engines.isle` (per worker purpose, both Claudes recommend) or a chip name such as
`esp32-twin.isle`.

D4 (pol). When a worker advertises `transports` but its door is unreachable, refuse the session with the door's URL in
the words (recommended: a declared door never silently degrades, same rule as BRIDGE_ENGINES_URL), or fall back to TCP?

D5 (pol, out of scope, flagged): the generated bridge's gRPC leg to the backend is plaintext (`usePlaintext()`). Leave
for a later round, or fold TLS-with-the-isle-bundle into td-4 since the SSLContext work is the same?

D6 (econ). bridge-engines is not deployed on the isle as an app. Either (a) live-prove the ctl path first (Sim bench
pin events from pol) and release bridge-engines as its own later step — recommended, it unblocks the bench soonest —
or (b) release bridge-engines in the same round so both paths are live-proved together.

## 8. Not doing

Passing raw encrypted TCP through the agent's 443 by name (nginx stream / ssl_preread). It would change how
every agent serves 443 for one consumer.

## 9. State (2026-11-15, written by pol)

States used: source-tested → staged → installed → live-verified. Never merged.

| Slice | State | Where |
|---|---|---|
| td-0 worker door (econ) | source-tested + packaged on econ (`board-engines 2026.11.15-1`) | polari-rf-node `econ/twin-door`, local |
| td-1 capability-driven transport | source-tested | polari-framework `dev-twin-door`, local |
| td-2 Hub over WebSocket | source-tested | same |
| td-3 sessions + hosted bridge pass `twin_uart` | source-tested | same, + `prf-bridge-engines` on polari-rf-node `dev-twin-door` |
| td-4 Java `WsDevicePort` / `IsleTrust` / `TwinPort` | source-tested (compiled and run against a fake door over wss) | same |
| D5 bridge gRPC TLS, client side | source-tested (whole jar built and run against a TLS and a plaintext recorder) | same |
| D5 bridge gRPC TLS, server / route side | NOT DONE, needs a decision (below) | - |
| td-5 Sim bench words (reached_by + transport_why on the panel; the action's answer above the table) | source-tested | polari-framework + polari-platform-angular `dev-twin-door`, local |
| td-6 live half of the session selftest over the door | not started | - |

Selftests (offline): `board_twin_transport` 19/19, `board_twin_session` 28/28, `grpcbridge_hosted` 65/65 (2 live halves
skipped), `javabridge` 51/51, `board_bench` 45/46 (the one failure, 5 board models expected, is on dev before this
branch), cmod demo-bundle parts 24/24 (the generated bridge jar still builds), frontend `class-rows-table` spec 9/9.

Added to the contract while building (econ's as-built, pol's client follows it):
- Further close codes: 4503 the door could not ask the worker; 1003 wrong frame kind; 1009 a frame over 1 MiB.
- Pin names on ctl are three characters (`PB5`, not `B5`).
- The door may close (4404, 4403) before the client's token frame is written. The client reports the door's own close
  reason in that case, not a send error.

The uart token (td-3/td-4):
- The backend derives the session token and sends it to the bridge worker in the POST body only when the uart is a door.
- The worker hands it to the bridge's process in the environment variable `TWIN_TOKEN` and keeps it nowhere else.
  The selftest proves it is in no state file, properties file, command line, answer, row, view or log.
- A door bridge needs no `twin_host` / `twin_port`.
- A bridge worker older than the door is detected (its answer does not repeat `twin_uart`), its bridge is stopped and the
  start is refused with 424. Never a silent fall back to TCP (D4).

D5 as built: the knob is `grpc.tls` in `bridge.properties`. `verified` is the jar's default when the key is absent.
The generated properties write `grpc.tls=plaintext` explicitly, because the backend's gRPC server is plaintext today.
Any other value is refused in words. An ending bridge now finishes its Push streams, so the last frames are delivered.

Open, for the user and econ (bridge-engines follow-on):
1. The backend's gRPC server is plaintext on 3002 (`grpcbridge/custom/grpc_server.py`, `add_insecure_port`) and is not
   routed by the isle agent. `grpc.tls=verified` has nothing to verify against until that is decided: either a TLS port
   on the backend with an isle leaf certificate, or a named app in front of it.
2. bridge-engines needs the isle trust bundle mounted (`/etc/isle-trust`) and is not an installed isle app anywhere.
3. A refused token ends the bridge in words, but the process exit code is probably 0. The worker would show "exited".
4. Pre-existing: after a gRPC push error the bridge does not re-open its Push stream (a backend restart ends pushes).
5. Round 88: a domain field in the release manifest and an `islemesh_catalog.py` row for the door (econ's item).
