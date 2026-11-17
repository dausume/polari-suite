# Twin door plan — reaching twin sessions through the agent by name

Status: REVIEWED and answered by the user 2026-11-15 (§7). Econ's half (the worker release and the door) is INSTALLED
since 2026-11-15T15:31Z and econ reports it live-verified from econ and from the core (a real session, 13/13 each).
Pol's half (backend `2026.11.15-release87td1-candidate`, release id `05834476...6ee2eded`) is INSTALLED on the core and
on pol since 2026-11-16T00:2xZ, and the control path is LIVE-VERIFIED from pol's installed backend through the door
(§9 "Install record and live proof"). Not proved: the uart path (bridge-engines follow-on) and the Sim bench screens.
Core, pol and econ are all on that release id since 2026-11-16T01:24Z; `hal` is back on pol's instance (01:20Z).
See §9 per slice.
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
| td-0 worker door (econ) | INSTALLED 2026-11-15T15:31Z (`board-engines 2026.11.15-1` + app `twin-board-engines`), see "Install record" | polari-rf-node `econ/twin-door`, local |
| td-1 capability-driven transport | source-tested | polari-framework `dev-twin-door`, local |
| td-2 Hub over WebSocket | source-tested | same |
| td-3 sessions + hosted bridge pass `twin_uart` | source-tested | same, + `prf-bridge-engines` on polari-rf-node `dev-twin-door` |
| td-4 Java `WsDevicePort` / `IsleTrust` / `TwinPort` | source-tested (compiled and run against a fake door over wss) | same |
| D5 bridge gRPC TLS, client side | source-tested (whole jar built and run against a TLS and a plaintext recorder) | same |
| D5 bridge gRPC TLS, server / route side | NOT DONE, needs a decision (below) | - |
| td-5 Sim bench words (reached_by + transport_why on the panel; the action's answer above the table) | source-tested | polari-framework + polari-platform-angular `dev-twin-door`, local |
| td-6 live half of the session selftest over the door | not started | - |

Selftests (offline): `board_twin_transport` 20/20, `board_twin_session` 28/28, `grpcbridge_hosted` 65/65 (2 live halves
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

### Two faults found after the install (2026-11-15, both fixed at source, source-tested)

1. Handshake timeouts over TLS 1.3 with the threaded WebSocket client. Econ reported it; pol reproduced it with
   `websockets.sync.client` 13.1 through the isle agent: 2 of 40 opens from the host and 2 of 30 inside the released
   backend image ended "timed out during handshake"; 0 over TLS 1.2; 0 with the asyncio client. The threaded client
   reads on one thread while the caller writes on another. Fix (pol, `board/custom/twin_ctl_hub.py`): the door channel
   owns one asyncio loop on a thread of its own and every read and write happens there. TLS is not capped to 1.2 and
   nothing is retried. 60 opens of the installed door afterwards: 0 failures. The transport selftest gained a check
   (30 wss opens in a row over TLS 1.3). Econ's own proof client was capped at TLS 1.2; that cap is not in pol's code.
2. The generated Java bridge dialled the door once more while stopping. `BindingRouter` pumps each port on its own
   thread; when the bridge closed its port the pump called the ended stream "lost" and reopened it (about 3 runs in
   10 of the hosted selftest: a third connection, or a 4400 at the door). Fix (`grpcbridge/custom/
   java_bridge_templates.py`): `SerialCdcPort.close()` marks the port closing; `next()` and the reopen loop end
   instead of dialling. 14 runs of the JVM door checks in a row clean afterwards.

### Release candidate (pol's half, 2026-11-15)

- Branch `release/87-twin-door` in polari-framework, local: `release/87-candidate` (34ffa8f3, what the installed
  backend `2026.11.12-release87r3-candidate` was built from) merged with `dev-twin-door`. Head 359afd45, tree
  8da252b0. 25 files differ from the installed backend; `requirements.txt` is unchanged.
- Bundle `pol-framework-release87-twin-door-1.bundle` (sha256 d4ea2412...119ef4e) placed in the core's collab
  directory. Econ was asked at about 16:00Z to build the backend image from it, run the in-image selftest sweep as a delta
  against r3 and report the image identities.
- Econ built it: `polari-framework/prf-backend:2026.11.15-release87td1-candidate`, config digest
  `sha256:0d3c1a71...9702ed70`, manifest digest `sha256:03a59a35...50466a12`; archive sha256 `9ab23598...11984e1`,
  1132784128 bytes, in the core's collab directory `release87td-artifacts/` (identities checked there by pol). It is
  the r3 image plus one layer (33 of r3's layers are shared).
- Econ's in-image sweep: 368 selftests, 335 exit 0, 33 non-zero, every non-zero identical to the r3 baseline. Six
  result lines differ, none a regression (transport is new, 17/17: its three TLS checks skip because the image has
  no `openssl` binary). In the image the asyncio client opened the installed door 60 times with 0 failures; the old
  threaded client failed 9 of 60 there. The Java redial fix is NOT exercised in the image (no JDK); it rests on
  pol's source run.
- `runtime-source.json` (the release-87 manifest with only the `prf-isle-backend` entry changed) is beside the
  archive on the core (sha256 `e020ad61...d884b25`). State at 17:40Z: source-tested and STAGED. Not published,
  not installed. The published release is still `ec81fc06...8e1cc2` (backend r3).
- Scope: backend only. The frontend td-5 commit sits on a branch 7 ahead / 8 behind the released frontend
  source and rides the next frontend cut; the live ctl proof does not need it.
- The user's steps (their sudo, `isle` verbs only): core `isle update publish-runtime`, `isle apt-repo publish`,
  `isle update plan`, `isle update apply <id>`; then the same plan/apply on pol; then
  `isle polari module add hal --to polari-pol` (finding 7 below). Rollback: publish the release-87 manifest kept
  in the core's `release87-artifacts/` and apply that id.
- The live proof is a twin session started from the Sim bench on pol's backend, driven over ctl through the door
  (pin names like `PB5`).

### Install record (2026-11-15, the user's sudo steps, verified read-only by pol)

1. Core: `isle store publish <release.json>` at 14:58Z. Pol's replica of `apt-public-repo` committed it about 15
   minutes later (timer interval plus the image transfer).
2. Econ: `isle store install board-engines`. The first run, 51 s after the publish, installed the OLDER release
   `2026.11.04-1` without saying a newer one was in transit. The second run installed `2026.11.15-1`; the worker's
   `/capability` now advertises `transports` (ctl and uart, `wss://twin.board-engines.isle/sessions/{id}/...`).
3. Econ: `isle app deploy twin-board-engines ... --domain twin.board-engines.isle --health-path /health`. The first
   run stopped at "core DNS publication pending" (cause below). After step 4 the same command passed:
   "DNS published by core and verified", "Deployment verified ... trusted HTTPS".
4. Core: `isle dns register twin.board-engines.isle <econ's agent address>`, by hand. This step is NOT in the
   standard flow and should not be needed (round 88, below).

Proof of "installed" from pol at 15:32Z, certificate verified: `GET /health` 200 (also 200 from the core). A WebSocket
to `/sessions/00000000/ctl` and to `/uart` upgrades through the agent, and the door closes each with
`4404 no session 00000000 on this worker`: the door reached its worker and refused by the contract's code.
A session id is 6 to 32 lowercase hex characters; any other path gets HTTP 404 before the upgrade.

Not proved yet: a real session over the door (ctl or uart). That is the live proof and needs pol's release.

### Install record and live proof, pol's half (2026-11-15 evening local, the user's sudo steps)

1. Core, 23:3xZ: `isle update publish-runtime <runtime-source.json>`, then `isle apt-repo publish --from <the 87 debs>`
   (published 23:52Z). Pol's `apt-public-repo` replica committed it at 00:04Z. Release id
   `0583447672cabcfecfdc182edf3aced2fcdbc6890811966998a3a28a6ee2eded`: backend td1, everything else as in 87.
2. Core, 00:11Z: `isle update apply <id>`. The backend came up on td1, then the operation failed at `provider-dns`
   (finding 9). `isle operation retry <operation>` at 00:17Z succeeded. INSTALLED on the core.
3. Pol, 00:19Z: `isle update apply <id>` succeeded in one run. `prf-polari-pol-backend` runs config digest
   `0d3c1a71...`. INSTALLED on pol. Full boot took 248 s (15 modules).
4. As predicted (finding 7) the apply dropped `hal` from pol's instance: `POLARI_MODULES` no longer lists it and
   `/api/hal/socs` went from 200 to 404. Owed: `isle polari module add hal --to polari-pol` (the user's sudo).
5. `hal` back on pol: the user ran `sudo isle polari module add hal --to polari-pol`; 16/16 modules online at
   01:20Z, `/api/hal/socs` 200, a twin still starts through the door after the bounce. `deployment.json` still
   lacks `hal`, so the next apply on pol drops it again (finding 7).
6. Econ's member update: the user ran the apply on econ-core, operation `63fa3b20265549c2a168e62c4506dc9e`
   succeeded in one attempt (01:24:45Z to 01:24:59Z, a near no-op: no Polari instance there, debs and agent
   already at the release's versions). Read back by pol: operation state, plan id, identity "consistent",
   door health 200 over verified TLS.

LIVE-VERIFIED from pol at 01:08Z, certificate verified, against the installed backend (`api.polari-pol.isle`):

- `POST /api/board/twins` (`uno-light`) answers 201 in 0.9 s (it was the 502). The session row reads transport
  `door`, "read from the worker's /capability", `ctl_url wss://twin.board-engines.isle/sessions/<id>/ctl`.
- Control out: `watch`, then `set PD2` 0 / 1 / 0, each acknowledged by the twin with its own cycle count
  (134 M, 151 M, 168 M cycles one second apart: the AVR's 16 MHz in real time).
- Control back: the events stream (`/events`, SSE) delivers the twin's pin edges through the same door channel. Each
  press shows `PD2` falling and the firmware answering on `PD6` (1 after the first press, 0 after the second).
- A wrong pin (`PX9`) is refused in the twin's words ("PX9 is not a pin of atmega328p", HTTP 409) and recorded as a
  failed interaction. `stop` ends the session ("stopped by pol-live-proof"). Two sessions were run and stopped.

Not proved: the uart path (the hosted Java bridge through the door; bridge-engines is not an isle app yet, the tracked
follow-on), the Sim bench screens driving the same calls (the frontend is unchanged, td-5 rides the next frontend
cut), and the Java redial fix in a released image. Seen in the event stream: `PD2` reads 1 again
about 16 000 cycles (1 ms) after each press, before any release is sent. Econ's finding (reproduced by econ on the
installed worker `2026.11.15-1`, not verified by pol): the twin's `set` raised the pin once, and simavr recomputes a
pulled-up input to 1 at the firmware's next PORTx/DDRx write, so a set level did not stand. Econ's fix registers the
level with the port as an external drive (a set level stands until the next set of that pin); source-tested on econ,
not committed, not released. It needs a new board-engines release (the user's publish/install). No backend change.
Open for the user: a true pin release (`{"release":"PD2"}`, back to pull-up/floating) as a later contract slice.

### Worker release 2026.11.15-2 (econ's, prepared; not published, not installed)

- Econ committed the hold fix and the door log, merged `econ/twin-door` into rf-node `dev-electronics` (af4771f) and
  staged a packet on the core (`~/collab/electronics-worker-20261115-2/`, 15/15 checksums read back by pol).
- Regression in the INSTALLED worker `2026.11.15-1` (econ's finding, confirmed by pol from the worker's own usage
  text over verified TLS): its twin lacks `--masked-windows`, watch-change events, `--adc-at` and the `ret@` form of
  `--fn-cycles`, because its branch was cut from an older base. The backend's cycle_measure, cmod budget and node_run
  use them. The -2 packet puts them back. pol has not run those paths against either worker.
- Found by pol while merging: the -2 image as built still has `MAX_PINAT` / `MAX_ADCAT` 32. pol's 44fcb33 (bss-11,
  256, a bouncing press is ~14 entries) was never pushed, so it is in neither `origin/dev-electronics` nor af4771f.
  pol's rf-node merge (ac959cf = dev-twin-door + af4771f) holds it; bundles for rf-node, framework and frontend are
  staged on the core (`~/collab/twin-door-merge-20261115-pol/`). Recommendation sent to econ: rebuild -2 from that
  tree before publishing. Econ rebuilt it from ac959cf (2026-11-16T01:5xZ): config `sha256:dbbf80c8...393a9503`,
  manifest `sha256:8cd5ef72...673ab3cbc`, tar sha256 `742600ee...4f67d027`; 17/17 checksums and the source
  manifest read back by pol on the core. Econ's tests on this build: door selftest 29/29 and hold selftest 8/8 at
  build, 11/11 real-twin and 6/6 hold through the door between scratch containers, 256 `--pin-at` accepted and
  257 refused. Econ also found 2026.11.04-1 had the limit at 32, so 256 was never in a released image.
  State: source-tested, staged on the core; NOT published, NOT installed, NOT live-verified.
- Behaviour change with the hold: `--pin-at` and `--wire` levels stand too, so expected numbers recorded with the
  old bounce may move. pol's part of the proof after install: the PD2 hold through the door, then the board, cmod
  and firmwarefaults selftests from the installed backend against the new worker.
- INSTALLED 2026-11-16: the user published on the core (02:16Z) and installed on econ. The first install (02:18Z)
  ran 3 minutes before pol's replica carried the publish and silently reloaded `-1` (round-88 item 2, with
  timestamps); the rerun at 02:26Z loaded `-2`. Worker and door both on image `8cd5ef72b66d`.
- LIVE-VERIFIED, the hold, from pol's installed backend through the door (02:27:40Z, verified TLS): session
  `18123022e1ac`, press / 3 s / release, twice. PD2 0 @27236616, PD6 1 @27378807, PD2 1 @76244282 (the release),
  PD2 0 @109748296, PD6 0 @109748705, PD2 1 @158800829: no PD2=1 edge between a press and its release. Econ matched
  the session in the door's new log (open 02:27:40Z, close code 4410 after 11.9 s) and proved the same from econ by
  name (session `5366fe32b2f6`, 6/6). The worker's usage text read from pol lists the four put-back flags.
- The 28 board / cmod / firmwarefaults selftests in pol's installed backend with `BOARD_ENGINES_URL` on the worker
  did NOT prove the worker, and no failure is the worker's:
  - 21 exit 0, but the twin checks in them SKIP ("no simavr twin here - knob"): `light_twin.engine_ready`,
    `cycle_measure.measure`, `button_clock_acceptance`, `twin.py` and the C3 twins accept only a twin LOCAL to the
    backend (local binary or local image), by the 2026-10-07 proof-push rule. On an isle member whose worker is on
    another machine these one-shot twin runs refuse; only hosted twin sessions (the door) reach the worker.
  - 4 fail at their first check for the same reason (cmod node_run, command_edge, light_topology, confirmations:
    0/1, as in econ's no-network sweep).
  - board_selftest 1016/1019: two ins-1 flashing checks (no local avrdude) and one td-2 fake-door check where the
    "unknown session" refusal arrived as a 5 s timeout; the same selftest alone passed 17/17 three times after
    (a timing flake under load, for td-6). cmod_fsc 135/143 as in econ's sweep. cmod_selftest hit the 20 min limit
    with 3 failures (the twin prove gate disagreeing with the runner once the knob is set; a demo-bundle README hash).
  - NOT proved: node_run, cycle_measure and scenario runs through the remote worker's put-back flags and the 256
    limit; expected numbers under the held `--pin-at`. Nothing on a member runs them against a remote worker today.
- Not done: the superproject pointer and any push (the user's go on pol's side).

### Round-88 findings from this install

1. No core DNS for an app without a catalog entry. The core's `dns-reconcile.sh` registers only domains found in the
   catalog's `entries[].instances[]`, and `instances_of()` (`modules/islemesh/islemesh_catalog.py`) matches a reported
   app to an entry by `^<entry name>(-N)*$`. `twin-board-engines` matches no entry, so its domain was never registered
   although the registry report was accepted (200). The deploy's own message ("retry the same operation") cannot
   succeed in that case. Fix candidates: the catalog row + manifest domain field (item 5 above), or the reconcile
   publishing every accepted registry domain of a known member.
2. `isle store install` installs the previous release silently while a newer publish has not reached the replica yet.
   It should say so, or wait, or refuse.
3. The publish-to-replica time is the timer interval plus the transfer (15 minutes here), not "within 10 minutes".
4. `dns-reconcile.sh` fetches the catalog with `curl -skf` (unverified TLS). Isle-core's lane.
5. Unexplained: during the first install (14:59Z) econ's calls to `api.polari.isle` (the CORE's backend) timed out;
   the same name answered in 0.3 s from econ at 15:17Z.
6. `isle dns help` does not list `register` / `unregister`.
7. `isle polari module add <m> --to <instance>` rewrites the compose `POLARI_MODULES` and the registry note but not
   the instance's `deployment.json`. An update apply replays `polari instance deploy` from `deployment.json`, so a
   module added that way (here `hal` on `polari-pol`) is most likely dropped by the next update and has to be added
   again. Read from the installed CLI 0.1.207 and confirmed by econ from the CLI source; not yet observed live.
8. A runtime-only cut still needs `isle apt-repo publish --from <a deb directory>` to produce the release id, and
   the core's publish reaches the members only after pol's `apt-public-repo` replica has synced (finding 3). An
   `isle update plan` run before that shows the previous release.
9. The core's update apply races its own backend's two-phase boot. Release `05834476...6ee2eded`, operation
   `4427b2bb...`, 2026-11-16: the new backend container was up and the update went on to the provider step for the
   core's `electronics` frontend instance; its registry report (`POST /api/islemesh/ingest/registry`) got 503 at
   00:14:51.4Z and the `islemesh` module came online at 00:14:52.4Z. The operation failed at stage `provider-dns`,
   retryable. The readiness gate should wait for `/api/modules/status` (islemesh online), or the report should retry
   on 503. Nothing in the release touches `islemesh`; nginx only printed deprecation warnings (its test passed).
