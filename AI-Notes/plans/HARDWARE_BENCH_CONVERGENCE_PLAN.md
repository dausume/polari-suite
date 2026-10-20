# Hardware bench convergence (hbc) — how it all comes together — PLAN, 2026-10-19

His words (2026-10-19, quoted): "work on the plan for all of this coming together autonomously first, finish up what we have now, then move forward" ·
"make it possible for a bridge java app with polari ui embedded defined via no-code to be able to be configured to interact with the simulated devices as
well" · "for active simulated devices, we are going to want there to be an interactable visualization as well where the firmware is fully locked and installed
and components that are meant to be interacted with physically are treated as UI components as overlays on the visualization of the breadboard or protoboard
or pcb or whatever. This way we can test both App UI interaction with firmware as a user and physical interaction with sensors and buttons as a user."

He converted this session to Fable and said: go with my own recommendations for now; he revises later. Every decision below marked **(taken)** is mine, his to
overturn. The agent rule stays: one or two non-Fable agents at a time, each briefed from this plan.

## 1. The pipeline, end to end (what exists · what this adds)
```
Mission (no-code)  →  solve → scores → the curated SAMPLE  →  twin proofs (per config)   →  LAYOUT walkthrough → person confirms → BIND → real board
   exists              exists   exists   smp (building)        exists (fsc-6)                  lay (new)             lay-3 (new)     exists (installer)
                                                                   │
                                        ┌──────────────────────────┴──────────────────────────────┐
                                   CIRCUIT STATES + SPICE per state (cst, new)            INTERACTIVE SIM BENCH (sim, new):
                                                                                           the twin, firmware locked, parts as UI overlays,
                                                                                           the App UI beside it  ← the bridge app reaches it too (brg)
```
Three separate views over one model (PROTOTYPING_VIEWS_PLAN): **pins** (exists) · **circuit states** (cst) · **layout** (lay). The sim bench is the layout
view with a LIVE twin bound; the real bench is the same page with a real board bound (the Firmware Installer / bridge path).

## 2. What already exists that this builds on (read from the code, 2026-10-19)
- **The twin is already a long-lived device with a network port.** `polari-avr-twin` (prf-board-engines, GPL-3 simavr): USART0↔TCP (default 9831), ADC0 stimulus
  (`--adc0-mv`, `--adc0-ramp`), PORTB5 trace, `--pin-at` events, `--wire`, `--poke`, `--watch`, `--trace-vcd`, `--irq-at`. `pol board twin uno up|down|status`
  runs it as `prf-board-twin-<board>` on THIS docker, TCP on 127.0.0.1 only; `twin_pty` pumps it to a pty so the Java bridge attaches with `source=serial`.
  Gap: pin events are batch (`--pin-at` at a cycle), not live; no control socket; bound to localhost; one twin per board name.
- **The Java bridge** (generated, grpcbridge): `DevicePort` with `SimulatedDevice` (synthetic frames) and `SerialCdcPort` (USB CDC / a pty). Gap: no TCP port kind.
- **The desktop shell** (polari-app-shell): a CEF (Chromium) frame = the embedded Polari UI; HostInstall/pkexec; the demo bundle already carries
  `app-definition.json` (the Hardware App + the cross-domain solution). The Polari Firmware Installer (exp-2) is planned, not built; today's bridge app deb exists.
- **The demo page** `/display/uno-core-demo`: the LightState row + the "Turn the light on / off" button (runs `light-toggle`: the struct is altered, relayed down).
- **electrodevice**: circuits as rows, ngspice `.op`/`tran` runs, `CircuitRunResult`, the breadboard level (ncg-5), the level bridge (logic → voltage source).
- **The pin view** (d3): boards, packages, dies, parts, stages, filters, click/Escape.

## 3. The interactive simulated bench (slice `sim`) — (taken) design
- **sim-0 — twin SESSIONS with a live control channel.** Extend `polari-avr-twin` with a control socket (JSON lines, one connection per client):
  `{"set":"PD2","level":0}` (press/release), `{"adc":0,"mv":750}`, `{"watch":["PD6","PB5"]}` → `{"pin":"PD6","level":1,"cycle":…}` events, `{"run":true|false}`,
  `{"status":…}`. The USART TCP stays as is. A session = one twin process with (hex sha, board, ports, token, owner, TTL); started/stopped through the board
  engines worker (`/sessions` door on the worker, placed by topology on isle-core), reachable on the LAN under a per-session token (the twin leaves 127.0.0.1;
  the token is the gate). Resource cost measured (image, RSS, CPU-s) per the cost rule. `pol board twin` grows `session start|list|stop`.
- **sim-1 — the backend door + rows.** `TwinSession` rows (`/api/board/twins`): start from a built config (the hex is the LOCKED firmware: its sha is shown, no
  edits while a session runs), inject/watch proxied through the backend for the browser (a WebSocket or SSE fan-out of pin events; inject = POST). A session
  is a participant of the Hardware System ("twin:arduino-uno-r3#0" already exists as a board_instance name).
- **sim-2 — the server-hosted bridge for a session.** The generated Java bridge, run as a process beside the session with the new `TcpDevicePort`
  (`source=twin-tcp`, host:port:token), so the LightState row on the server follows the twin and `light-toggle` reaches it. This is what makes the web page
  alone a complete test (no desktop app needed). Placement: the bridge runs where the twin runs (isle-core), as a topology-placed service.
- **sim-3 — the page `/display/sim-bench?config=&session=`.** The layout renderer (lay-2) with the session bound:
  - parts "meant to be interacted with physically" become UI overlays, from the KitPart's interface kind: pushbutton → press/hold/release (mouse down/up =
    level 0/1 on its pin); potentiometer → a slider (→ ADC mv); TMP36 → a temperature slider (°C → mv, the TMP36 formula, cited); tilt sensor → a toggle;
    photoresistor → a light slider. Outputs follow the twin: the LED lights from the watched pin (and dims by PWM duty when the trace shows it), the piezo shows a tone marker.
  - the firmware panel: the installed hex sha, the config, "locked" (no edits, no reflash from here); a "stop session" control.
  - the App UI beside it: the configured demo page's own tables (the LightState row + "Turn the light on / off") embedded as rows of the same page, so one
    screen exercises BOTH paths: the App UI → the struct → the bridge → the twin → the report back; and the "physical" press → the twin → the report → the row.
  - every interaction is an event row (who, what, when, the twin cycle), so a session can be replayed as a ScenarioRun (a person's manual test becomes evidence;
    `proof_kind=attested` exists for human-confirmed proofs).
- **sim-4 — the same page on a REAL board.** Bound through the installer/bridge instead of a session: the overlays become read-only indicators (the real button
  is pressed by hand), the LED state comes from the sensed line (S1's sense jumper is why it exists). Same page, same model, no second component.

## 4. The bridge app with the embedded no-code UI against simulated devices (slice `brg`) — (taken)
- **brg-0 — `TcpDevicePort`** in the generated Java bridge (`source=twin-tcp`); the same frames, codecs and lifecycle as the serial port. The bridge
  self-test (BridgingCapability `proven_by`) runs against a twin session — the proof the bridge works, without a board.
- **brg-1 — a device picker in the bridge app.** The shell's hardware screen lists: real USB devices (Detect, exists) AND the simulated sessions Polari knows
  (`/api/board/twins`); picking a session writes `bridge.properties` (`source=twin-tcp`) and starts the hosted bridge in the app. Connected mode stays isle-only for
  the Polari API (his earlier ruling); the twin port is a DEVICE transport like USB, so a home-swarm app may use it (D-hbc-2, taken).
- **brg-2 — the embedded UI defined via no-code.** The app's CEF frame opens the Hardware App's display (`app-definition.json` → `/display/<route>`, the
  configured page), so the app's UI IS the no-code page (tables, the light button, the sim bench itself). No app-specific UI code; the shell is the frame.
- **brg-3 — the app tested as a user.** A ScenarioRun kind "app-session": the app's own interactions (the button on the embedded page, a press on the sim bench)
  recorded as a run, with the bridge's frames as evidence. This is the "test App UI interaction with firmware as a user" path.

## 5. The views (ptv), circuit states (cst), layout (lay) — decisions taken
- D-ptv-1..4 taken as recommended: two sanctioned d3 components (`hardware-layout-view`, `circuit-schematic-view`); a circuit state = a distinct SPICE
  netlist; `.op` per state first, co-simulation second; shared refs + URL scope, no merged view.
- D-bb-3..5 taken: bind after confirmation with a recorded "bind anyway"; a tick per step + the final check; an optional photo in the file store.
- The sim bench's pin events (sim-0's `watch`) are also the circuit-state enumerator's input (cst-0): one trace feeds both.

## 6. Order (after "finish up what we have now")
**Finish first (now):** smp (UNO samples; uno-light gains the sense line = S1) and smp-c3 land → merge → deploy test node + live → prove → Chrome → the no-code
canvas fixes from the 2026-10-19 sweep (UNO_CORE_DEMO_PLAN owed list items 2–5) → the demo exports re-checked → his bench links.

**Then, in this order, one or two agents at a time:**
1. **sim-0 + sim-1** (the twin session with a live control channel; the backend door). Proof: a session of S1 on isle-core; a press injected over the socket flips the LED
   pin in the watch stream; the USART report says source=button.
2. **brg-0 + sim-2** (`TcpDevicePort`; the hosted bridge beside the session). Proof: the LightState row on the test node follows the session; `light-toggle` lights the twin's LED.
3. **lay-0 + lay-1** (board family objects, WireColorScheme, the placer + netlist gate + build steps for S1). Proof: S1's layout nets == its design nets; a backwards LED refused.
4. **lay-2 + sim-3** (the N-board renderer; the sim bench page with overlays + the App UI beside it). Proof in Chrome: press the overlay button → the LED overlay lights and
   the row's `source` reads button; press the page's light button → the LED lights and `source` reads command.
5. **cst-0 + cst-1** (circuit states from the twin trace; `.op` per state). Proof: S1's four states with LED and pull-up currents.
6. **lay-3 + sim-4** (confirmation → bind; the same page on the real board — his bench).
7. **brg-1..3** (the app's device picker, the embedded no-code UI, app-session runs).
8. **cst-2, cst-3**, protoboard, PCB.

**Device split (his "split work across devices via swarm"):** pol-core = the live stack, merges, Chrome checks; econ-core = the test node (`pol deploy run`);
isle-core = engines, twin sessions, the hosted bridges, SPICE, every selftest run (`pol deploy selftest`, per-run worktrees). New services (twin sessions, hosted
bridges) are placed by topology on isle-core, never ad-hoc.

## 7. Decisions taken (his to overturn)
- **D-hbc-1:** twin sessions are TOPOLOGY-PLACED services on the engines host with a per-session token on the LAN (not localhost-only). Why: the bridge app
  on a desktop and the backend both need the port.
- **D-hbc-2:** the twin port is a device transport (like USB), usable by the bridge app on the home swarm; the app's Polari-API connection keeps the isle-only rule.
- **D-hbc-3:** overlays are derived from KitPart interface kinds (no per-part UI code); a part with no interaction kind draws as a plain sprite.
- **D-hbc-4:** a manual session is recordable as a ScenarioRun (`proof_kind=attested`), never auto-promoted to a proof.
- **D-hbc-5:** the sim bench embeds the configured App page rows beside the layout; no second UI for the app.

## 8. sim-0 / sim-1 technical spec (read from the code 2026-10-19, so the build brief is exact)
**The twin binary** (`polari-rf-node/prf-board-engines/polari_avr_twin.c`, 327 lines + twin_forcing.c + twin_scenario_io.c): ONE TCP listener (`--tcp`, the
USART, one client, `listen_tcp` / `poll_tcp` in the `avr_run` loop), ADC via `avr_raise_irq(ADC_IRQ_ADC0+ch, mv)`, `--pin-at cycle=,pin=,level=` (forcing), `--watch`,
the PORTB5 edge trace, JSON status lines on stdout (`{"t":"ready"…}`, status every `--status-ms`). Realtime pacing or `--free`.
- **sim-0 adds `--ctl PORT`:** a second listener polled in the same loop; JSON lines both ways:
  - in: `{"set":"PD2","level":0}` (the same path as `--pin-at`, at the current cycle) · `{"adc":0,"mv":750}` · `{"watch":["PD6","PB5"]}` ·
    `{"run":false|true}` (pause/resume stepping) · `{"status":1}` · `{"reset":1}` (the existing power-rail reset path).
  - out: `{"t":"pin","pin":"PD6","level":1,"cycle":N}` on every watched edge (`avr_irq_register_notify` on the IOPORT pin irq, as the PB5 trace does) ·
    `{"t":"status",…}` · `{"t":"ack","of":…}` · refusals in words (`{"t":"refused","why":"PX9 is not a pin of atmega328p"}`).
  - One ctl client at a time; a token on the first line (`{"token":"…"}`) when the session was started with one.
- **The worker** (`board_engines_service.py`, falcon under gunicorn `-w 1 -t 600`): `/run` is one subprocess per request, so sessions must be DETACHED processes:
  `POST /sessions {hex_b64, board, mcu, freq, ttl_s, token}` → `Popen(polari-avr-twin --hex … --tcp P1 --ctl P2 --free|realtime)` with ports from a range, state in
  `/srv/sessions/<id>.json` (pid, ports, hex sha, started, ttl, owner); `GET /sessions` · `GET /sessions/{id}` (status from the twin's stdout) · `DELETE /sessions/{id}`;
  a reaper on each request kills sessions past their TTL. The Dockerfile `EXPOSE`s a port range (9832–9863) and `docker-compose.hw-engines.yml` publishes it on
  isle-core (placement label unchanged). Cost (image delta, RSS per session, CPU-s/s realtime) recorded in `modules/board/COST.md`.
- **sim-1, the backend:** `TwinSession` rows (`board`), doors `GET/POST /api/board/twins`, `DELETE /api/board/twins/{id}`, `POST /api/board/twins/{id}/inject`
  ({set|adc|reset}), `GET /api/board/twins/{id}/events` (SSE fan-out of the ctl stream), the hex taken from the config's committed build (its sha = the LOCKED
  firmware). `pol board twin session start <config>|list|stop <id>`. The session is a participant `twin:<board>#<n>` of the Hardware System.
- **Proof for sim-0/1:** start a session of S1 on isle-core from the test node; `inject set PD2 0` then `1` → the events stream shows PD6 rising; the USART
  report says `source=button`; `adc 0 750` is reflected in the next status; the TTL reaper ends an abandoned session; the cost block is measured.

## 9. Status 2026-10-19 — sim-0 + sim-1 BUILT, MERGED, LIVE on the swarm worker
- `polari-avr-twin --ctl PORT [--ctl-token T | POLARI_TWIN_CTL_TOKEN]`: JSON lines (token · set · adc · watch · run · status · reset → ack · pin · status ·
  refused). The worker's `/sessions` (ports 9832–9863 minus 9840/9850/9860, cap 8, TTL default 1800 s / max 14400 s, reaper). Image
  `prf-board-engines:trixie` rebuilt on isle-core (+22 KB; `trixie-pre-sim` kept); COST.md: 2.78 MB RSS and 0.37–0.45 CPU-s per realtime second per session.
- Backend: `TwinSession` rows, `GET/POST /api/board/twins`, `GET/DELETE …/{id}`, `POST …/{id}/inject`, `GET …/{id}/events` (SSE, bounded queues), the
  session as participant `twin:<board>#<n>`; `pol board twin session start|list|show|stop|inject|events`.
- The hw-engines stack is rolled (compose publishes the session ports); `GET /capability` on the worker shows the sessions block.
- Proof, live from pol-core against the swarm worker: 35/35 — uno-light session (firmware locked by sha), PD2 0→1 (66 ms apart) → PD6 rises in the
  events stream → the USART report says `led_on=True toggles=1 source=button`; adc reflected; pause/resume; reset; bad pin / wrong token / second client
  refused in words; the abandoned session reaped; no twin left behind.
- Known: the twin's own `peak_rss_kb` inherits gunicorn's high-water mark (use /proc); the USART tcp port stays raw (only ctl is token-gated).
- **Test node (econ-core) 2026-10-19:** sessions start through its own backend (`pol board twin session start uno-light --api <test node>`) now that a
  standalone node reaches the worker by knob (`nodes.yml` `engines:` → `<FAMILY>_ENGINES_URL`, resolved at deploy time); a press injected through the backend
  lights PD6 in the SSE stream. Finding: the events door is LIVE fan-out only — an edge raised before a subscriber connects is not replayed (the page will
  subscribe on open, so this is fine; a small replay ring, e.g. the last 100 events, is a follow-up for sim-3). The "no worker" refusal is 424 (a 503 is masked
  by the proxy as "Backend unavailable").

## 10. Status 2026-10-19 — brg-0 + sim-2 BUILT, MERGED, the bridge worker LIVE on the swarm
- `TcpDevicePort` (`source=twin-tcp`, `twin.host/port/connect_timeout_s`): the serial port's lifecycle over a socket (backoff 0.5→8 s, snapshot on
  attach); one port shared by all bindings (the twin takes one client). The regenerated uno-light bridge compiles; the bridge self-test has a twin-session mode.
- `prf-bridge-engines` (isle-core, :9870; openjdk-21-jdk-headless + maven; 505.6 MB; jar 18.4 MB, cached build 0.3 s): `/bridges` (start from a session,
  files = the generated project, grpc_target optional → log-only; cap 6; TTL reaper; logs; RSS/CPU in the detail). `HostedBridge` rows + `GET/POST
  /api/grpc/hosted-bridges`, `…/{name}`, `…/{name}/logs`, `/api/grpc/hosted-engines`; `pol grpc hosted start|list|show|stop|logs|engines`; 424 refusals.
- Topology: instance `bridge-engines`, assignment `grpcbridge.engines@bridge-engines` (allocated on live and on the test node); compose service in
  `docker-compose.hw-engines.yml`; knob `BRIDGE_ENGINES_URL` (nodes.yml `engines.bridge` for the test node). The hw-engines stack is rolled: 5 workers.
- Proof both ways (from pol-core, session on isle-core, bridge → the test node's :3002): press → the test node's `LightState` row reads `led_on=True
  toggles=1 source=button` in **146 ms**; `light-toggle` on the test node → the twin's PD6 falls **31 ms** after the POST; next report `source=command`.
  Selftest 47/47 with the server leg; isle-core: hosted 23/23 (+3 skipped), sessions 25/25, javabridge 51, contracts 34, serving 28, c_twin 44.
- Undetermined: the worker's online Maven fallback; bridge CPU under continuous reporting; the edge status reads `unresolved` until a live backend resolves it.
- **Test node, through its OWN doors, in Chrome (2026-10-19):** `pol board twin session start uno-light --api <test node>` → `pol grpc hosted start
  <session> --api <test node>` (the bridge on isle-core pushes to the test node's :3002) → a twin press makes the demo page's row read `led_on=True toggles=1
  source=button`; the page's "Turn the light on / off" button makes the twin's LED follow (`toggles 2 → 3, source=command`, the report count climbing). This is
  the App-UI path and the "physical" path on one simulated device, before any sim-bench page exists. Both stopped afterwards; no session or bridge left.

## 11. Status 2026-10-19 — lay-2 + sim-3 BUILT + MERGED (the renderer and the sim bench)
- `hardware-layout-view` (d3, generic/layout-view/): N boards from BoardModel geometry, 2-D sprites (resistor bands from value, LED polarity, button,
  pot, TMP36, transistor, generic), wires in their effective colour, pan/zoom/fit, hole/part/wire click → net + strip (click-toggle), shared scopes
  (`config`, `board`, `scheme`, `component`, `net`, `rev`), step mode (`?step=`), Whole build. The SCENE is derived on the server
  (`electrodevice/custom/layout_scene.py`: each part's interaction/output from its KitPart interface kind + the watch list) — no per-part browser code.
- `/display/layout?config=&board=` (build mode + steps + gate verdict + wire-colour schemes, copy-before-edit) and `/display/sim-bench?config=&session=`
  (sessions table with start/stop; the renderer in bench mode subscribes to `…/events?replay=100` BEFORE any inject, then sets `watch` to every output
  pin; overlays: press (pointer/Space), toggle (tilt), sliders (pot % → mV, TMP36 °C → 500 + 10·°C mV), LED from the watched pin (PWM dim only with a
  duty figure), piezo tone marker; the firmware panel with the LOCKED sha; the demo page's LightState table embedded via `light_state_table()`; a Bridge
  row with "Attach a bridge"; `BenchInteraction` rows; "Record this session as evidence" → a ScenarioRun `kind=attested`, never auto-promoted).
- New doors: `/api/layout/steps|verdict|models`, `/api/board/twins?name=`, `…/twins/interactions`, `…/twins/evidence`, `…/twins/light-state`,
  `POST …/twins/{name}/stop|record`. Both pages are TABBED (a non-tabbed page would recreate the component on every scope change and drop the stream).
- Tests: Karma 54 (23 math + 31 mounted); isle-core layout 89, hwnocode 171, apps 131, bench 46 (new `board.board_bench_selftest`), twin-session 25.
- Undetermined: the photoresistor overlay (its divider is unknown to this layer); the UNO outline is schematic beyond the pin pitch; scheme/board picks are not
  kept in the URL; the KitPart TMP36 note's "500 mV at 25 °C" wording looks wrong (the formula gives 750 mV) — left for the circuit slice to cite.
- **Chrome on the test node 2026-10-20 (sim-3):** `/display/sim-bench?config=uno-light&session=<s>` → "Live: connected to the simulated board"; "Press and
  hold: SW1 (D2)" → `LED1 (D6): lit — pin high`, two BenchInteraction rows with the twin cycles; "Attach a bridge" then the App-UI "Turn the light on / off"
  → the LED followed (dark). `/display/layout?config=uno-light` draws the UNO + half breadboard with step mode (step 3: SW1 outlined, the ground wire dimmed).
  **Follow-ups:** the bench's "Firmware you can run" table lists EVERY variant, so "Start a session" can bind a firmware that is not the picture's config
  (I started uno-sim-rig under uno-light's picture) — filter it to the page's config family or refuse the mismatch in words; "Whole build" did not take from a
  click after step mode (check the toggle); the layout/bench pages show no app group in the header on a direct URL (the known nav follow-up).

**Live pol-core rolled 2026-10-20:** everything on dev (sim-0/1, brg-0/sim-2, lay-0..2, sim-3, the curated sample, the fixes); S1–S4 proven FINISHED on live, S5 proven from isle-core. Owed: smp-2 (dev-smp-2 WIP), cst-0/1 (design in PROTOTYPING_VIEWS_PLAN §8), the sim-bench follow-ups above, lay-3/sim-4, brg-1..3, cst-2.


## 12. Next iteration (his asks 2026-10-20) — PLAN
His words: "a page dedicated to tracking all state objects in a particular piece of firmware (Structs, Enums, etc)" and "for the install page we need an
obvious toggle for switching between a Sim install and a Real Install, which makes it clear to the user. Validation via a sim install is a step we want
confirmed by a user before moving to a real install."

### fst-0..2 — the firmware state-objects page, `/display/firmware-state?config=`
Derived, never typed, from sources the arc already has:
- Rows `FirmwareStateObject` (one per struct / enum / enum-like define group) and `FirmwareStateField` (one per field or enum value): name, C type, size,
  where it lives (wire struct from the pinned contract via `grpcbridge.custom.wire_contract`; the firmware's own statics such as `state`, `g_sensed`,
  `g_seq`, `rx`; generated packet structs; EEPROM-persisted fields such as `boot_session`), the enum values with their meaning (`LIGHTSTATE_SOURCE_*`,
  `LIGHTSTATE_STATUS_*`, message types, presence flags), command vs telemetry, and the pin or task the field controls (the struct-controls-the-hardware rule).
- Readers and writers per field: from the parsed atoms (`POLARI_NODE` in/out/uses annotations + the atom bodies) → "written by apply_command, led_toggle;
  read by led_follow_state, telemetry_send". Unwritten or unread fields are findings.
- Live values: bound to a twin session (its decoded reports) or to the bridge's row, beside the static picture.
- Page = configured tables with tabs: Structs · Enums · Fields (readers/writers) · Live; doors `GET /api/firmware-state/<config>[/fields|/enums|/live?session=]`;
  `pol firmware state <config> [--json]`. Selftest: uno-light's `LightState` fields, the two enums, `led_on` written by both mutators and read by the
  follow task and the report; a field nobody writes is reported.

### ins-0..1 — Sim install vs Real install on the installer, with a confirmed sim step
- An OBVIOUS two-state toggle at the top of `/display/firmware-installer`: **Sim install** (the twin) | **Real install** (a detected board). It replaces
  the small "Where it goes" radio; the rest of the page re-labels itself to the chosen mode (the button text, the target line, the dry-run words).
- The gate: Real install is offered for a config only after a **sim install validated and confirmed by a person**: the sim install runs the config's four
  Purposes on the twin (the existing acceptance runs) AND the person ticks "I checked the simulated board does what the firmware says" — stored as a
  `SimInstallConfirmation` row (config, hex sha, who, when, the ScenarioRun names). Until then the Real install side shows, in words, what is missing and
  offers the sim install. A changed hex voids the confirmation. Overriding is possible only through an explicit "install anyway", recorded with the reason
  (the advise-never-block rule; D-bb-3 applies).
- The readiness page and the sim bench link to it: after a bench session is recorded as evidence, the same confirmation can be ticked there.
- Doors `GET/POST /api/board/installer/sim-confirmations`, `pol board install --sim|--real`, and the installer document carries `install_mode` + the
  gate verdict per config. Selftest: real install refused in words without a confirmation; offered after; voided by a new hex.

### Order for the next iteration (no agents unless he says so)
1. ins-0/1 (the toggle + gate) — it changes his bench path first.
2. fst-0..2 (the state-objects page).
3. The three sim-bench follow-ups (firmware-table mismatch, Whole-build toggle, nav group), then smp-2 (dev-smp-2) and cst-0/1 (PROTOTYPING_VIEWS_PLAN §8).
4. lay-3/sim-4 (confirm-then-bind on the real board), brg-1..3, cst-2.

## 13. Status 2026-10-20 — ins-0/1 + fst-0..2 + two sim-bench follow-ups BUILT (branch `dev-ins` in framework / angular / cli)
- **ins-0/1 (`board.custom.sim_gate`, `SimInstallConfirmation`):** the installer's document carries `modes` (sim = the twin, real = a detected board),
  `default_mode` (real when a board is seen), `attest` and a `gate` per build; `plan()` stamps `install_mode` and, for a REAL plan of a Mission config, the
  gate verdict: offered only when fsc_link reads every Purpose `proven-on-twin` for THAT config's own ScenarioRuns AND a valid confirmation exists for the
  build's exact hex. Otherwise the plan is REFUSED in words that name what is missing and offer the sim install; `install_anyway` + `reason` plans it with
  `gate=overridden`, the reason on the plan and the record. `run()` re-reads the gate (a tick voided by a new hex refuses at run time). Doors: GET
  `installer/gate`, GET/POST `installer/sim-confirmations`, POST `installer/sim-install` (runs the four Purposes here when the host has a local twin, else
  refuses with the exact `pol firmware prove <config> --api …`), POST `twins/{name}/record {confirm_sim}`; the sim-bench page gained a confirm row action,
  the installer page the confirmations table. CLI: `pol board install uno --sim|--real [--anyway REASON]`, `pol board gate`, `pol board confirm-sim`.
  Panel: the two-state toggle at the top; everything below re-labels; the Real side shows the gate words + "Do the sim install first" + "Install anyway"
  (ticked + a reason); the Sim side adds step 5 (the four Purposes, the tick). Selftest (installer 61/61): refusal in words, offer after runs + tick,
  voiding (also at run time), install anyway needs a reason, the bench tick. Bench variants (uno-echo, blink) are not gated — the words say why.
- **fst-0..2 (`board.custom.firmware_state`, `/display/firmware-state?config=`):** every state object of a config DERIVED from its rendered sources
  (cmod's preprocessor + pycparser), the pinned wire contract and the generated header text: the wire struct (91 B, tags, C types, command vs
  telemetry, the pin a field controls through its reader atom's `uses`, EEPROM persistence through the minting atom), the rx parser (9 fields), every
  static of the app / defs header / hal / sense route, local statics, enum blocks (meaning from the EnumMapping; who SETS and who COMPARES each value),
  presence bits + framing constants (word matches in function bodies — defines are gone after preprocessing), per field WHO WRITES / WHO READS it with
  pointer hand-offs followed ("polari_rx_feed (via main hands it over)"). Findings: uno-light → rx.device_id / rx.sequence never read; uno-blink-only →
  pwm_duty / temp_c written by nobody beyond zeroing. Rows FirmwareStateObject / FirmwareStateField (BOARD_CLASSES 62), doors
  `/api/firmware-state/{config}[/fields|/enums|/findings|/live?session=]` + `/configs`, five tabs of configured tables, `pol firmware state <config>`.
  The page's scope comes from the URL: `_page(scope_query=[...])` → `scope_from_query`, seeded by the display page (a general no-code gain).
  Selftest 28/28.
- **sim-bench follow-ups:** the bench picture now FOLLOWS the session's firmware (a session of another config redraws the layout for it, the URL's
  `?config=` moves with it); the header keeps the app group on a direct URL (`appForUrl` ignores a nav item's own `?config=`). The Whole-build toggle
  reads correctly in code (stepView/null → every part shown, no dimming) — to be re-checked in Chrome on the test node.
- Gotchas met: `manifests generate board` also drops `requires.engines_note` (restored with `requires.engines`); new object classes go in THREE places
  (feature_imports board list, polariServer defClassList, the manifest) or selftest_manifests fails; `pol deploy selftest` needs the branch pushed.
