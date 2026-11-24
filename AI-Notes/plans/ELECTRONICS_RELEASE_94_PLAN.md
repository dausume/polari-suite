# Release 94: the fixes release 93 showed, and the C3 on the Sim bench

Written 2026-11-23 on pol. State words: source-tested, staged, installed, live-verified.

**State 2026-11-23: a plan. Nothing of release 94 is built, staged or installed.** Everything it would carry is
source-tested on pol and not committed yet (a working day). Release 93 is installed on all three devices; what it
proved and what failed is in `ELECTRONICS_RELEASE_93_PLAN.md` §5.

The user's direction: "we need to get board simulations and hal fully working so we can prep loading to real boards".

## 1. Why a release 94

| From | What | State in source |
|---|---|---|
| 93, finding 3 | Escape with a wire selected also unbound the session. The installed fix does not hold on the real page | fixed again (the picture marks the key as spent), browser tests pass |
| 93, finding 6 | The page text was shown twice on the Sim bench and the Layout | fixed, the bench self-test checks it |
| 93, §5 | No CLI verb for the chip-HAL build; the C3 proof refused a worker on another device | `pol board gen c3 --knob`, the proof takes a worker over the engine ladder |
| The run of 93 | The waits said "still missing" and never that it was resolved; the package publish was silent for 22 minutes | the "resolved after" notice (pushed), progress lines in the publish step |
| `C3_SESSION_PLAN.md` | A button on the Sim bench cannot press a C3 pad | sessions in the ESP worker, the backend by chip family, the picture for a C3: all source-tested |
| `C3_INSTALL_PLAN.md` | The installer takes the UNO only; a C3 reaches a board past the gate | planned (ins-c3-1), not built |

## 2. What it would carry

| Part | Contents | Needs |
|---|---|---|
| Backend image | framework `dev` after today's commits: finding 6, the sessions by chip family, the layout for a C3, the C3 proof over the ladder, and ins-c3-1 if it is done and passes | `pol build image backend`, no download |
| Frontend image | angular `dev` after today's commits: the Escape fix, the picture for any development board | `pol build image frontend`, no download |
| Packages | the isle CLI with the resolved notice and the publish progress; the store; the offline package | built from the commit |
| Store app `esp-engines 2026.11.23-1` and the door app `twin-esp-engines` | the worker with sessions (`polari_c3_twin.py`, `board_sessions.py` with the C3 kind), advertising `wss://twin.esp-engines.isle`; the door is the same image with `twin_door.py` | image BUILT on pol 2026-11-23 (`prf-esp-engines:noble`; the toolchain from cache, the one download the `websockets` wheel by hash; the previous image kept as `:noble-2026-11-22`). In-image: twin 10/10, sessions 8/8, door 5/5, keep-alive 5/5; `board_light_c3_selftest` 35/35 on it. Definition on Isle-Mesh `dev-c3-door`; `isle store build` at packet time |
| Steps, every device | device-backup, then update | |
| Steps, econ only | `store-install esp-engines 2026.11.23-1`, after its update; then `isle app deploy twin-esp-engines --compose twin-door/docker-compose.yml --service twin-door --port 9864 --domain twin.esp-engines.isle` (the board door needed a hand `isle dns register` in round 88, finding 1: check whether that still holds) | |
| pol's own CLI | `pol board gen c3 --knob`, the help texts | pol's CLI runs from the source tree on pol: no packet part |

**Two shapes.** With the user's yes on D-c3g-1 and D-c3g-2, one release carries all of it. Without it, 94 carries
everything but the new `esp-engines` release: the fixes go live, the UNO is unchanged, and the Sim bench offers a C3
config that the installed ESP worker cannot hold a session for. The backend refuses that in words (`resolve_sessions`: no
worker lists twin sessions, and which image does). The C3 session then goes into the release after.

**What 94 does not change for the run itself.** The CLI that runs a release on the core is the one installed before
it. So the run of 94 is done by release 93's CLI: the "resolved" notice and the publish progress are first seen in
the run after 94. Whether a packet should be run by its own runner (it is held to the `--expect` number already) is
a design question, open in §5.

## 3. Gates before a command is handed over

| Gate | How |
|---|---|
| Everything committed and on `dev` | after 18:00 local, innermost first, each diff and commit text scanned |
| The whole board module self-test on the changed tree | 1,250 of 1,250 on 2026-11-23 with ins-c3-1 and ins-c3-2 in; electrodevice 139 of 139 |
| Browser tests | 131 of 131 on the changed tree (2026-11-23) |
| Backend image holds the commit; every module self-test in the image against the same run on release 93's image | as for 93 (§3 there) |
| Frontend image serves its pages with the network off; the byte check of the pages | the byte check was not run for 93: run it for 94 |
| ESP image (if rebuilt): `test_c3_twin.py`, `test_c3_sessions.py`, the keep-alive test, `board.board_light_c3_selftest` on it | in the image, network off |
| A session through the member's agent: the door's lines from another device | the door on econ, a client on pol, network as on the isle |
| Source tests of the builder and the runner; `isle release check` on pol and on the core | as for 93 |

## 4. The proof after it is installed

1. Sim bench, `uno-light`, a wire selected, Escape: the wire is cleared and the session stays (finding 3).
2. Sim bench and Layout: the page text once (finding 6).
3. `pol firmware prove esp32c3-light --api https://api.polari-pol.isle`: the four Purposes stored on the isle. This
   stores runs: the user's go first.
4. With the new `esp-engines`: Sim bench, `esp32c3-light`, a click on the button in the picture, and the LED follows.
   The same from the CLI: `pol board twin session start esp32c3-light`, a press on GPIO3, GPIO0 follows.
5. With ins-c3-1: `pol board install c3 --real --dry-run --api https://api.polari-pol.isle` prints esptool's command
   and the four checks, and flashes nothing.

## 5. Open

- D-c3g-1, D-c3g-2: ANSWERED 2026-11-23, the user: "for 1 and 2 yes". `websockets` pinned by hash in the ESP
  image, the door as a second container of the `esp-engines` app, the image rebuilt from the tracked Dockerfile
  (its downloads approved). So 94 takes the one-release shape of §2.
- The C3 board: ANSWERED 2026-11-23, the ESP32-C3-DevKitM-1 the seeds already draw ("that is what we already had and
  confirmed").
- `bridge-engines` and the backend's gRPC. What was already built, found 2026-11-23:
  - The struct-to-object layer is general and needs no work per class. It includes `WireContract`,
    `HardwareInterfaceBinding`, `EnumMapping` (brd-wire, 2026-10-02) and `StructObjectMap` / `PolariBridgeInstance`
    (hsp-3a, 2026-10-28). The backend's one generic handler serves `/polari.sync.<Class>Sync` for every exposed
    class (grpc-2).
  - The bridge's gRPC leg was proved live both ways on 2026-10-19 on the swarm: a bridge on isle-core pushed to the
    test node's published :3002 (146 ms up, 31 ms down).
  - The 2026-11-15 twin door fixed the bridge-to-twin leg (wss, the isle trust bundle). It also added the bridge's
    client-side `grpc.tls` knob.
  - Still open, as the twin-door plan already says (§9, "server / route side NOT DONE"): on an installed isle app the
    backend's gRPC is plaintext :3002 and the agent serves HTTPS by name only, so nothing routes it. And the hosted
    start takes its target from `<host the server was reached at>:3002` (`export_demo.grpc_target`), not from the
    bridge's `PolariBridgeInstance.polari_node_url`, which already names the node's isle URL.
  - The Polari half was built the same evening (source-tested, `grpcbridge.custom.bridge_link`). A bridge started for
    an instance pushes to `grpc.<node>.isle:443` with verified TLS, whether the far end is a cabled board or its twin.
    The isle half is a request to isle-core: `ISLE_GRPC_ROUTE_REQUEST.md`. Both land in a release after 94, not in 94,
    because the route needs an isle change first.
- Should a packet be run by its own runner, so a fix to the run is seen in the release that brings it?
- The publish step still reads every package on every release (25 GB on the core). A kept index, or pruning old
  releases. Not started.
- `core-install.sh` shows only the last two lines of the publish step.
