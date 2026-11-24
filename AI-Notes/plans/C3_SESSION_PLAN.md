# C3 twin sessions (c3g): a C3 the Sim bench can press

Started 2026-11-23 on pol. The user's direction: "we need to get board simulations and hal fully working so we can prep loading to real boards".

The UNO has a live session: the page starts one, a click on the pushbutton presses a pin, the LED follows.
The C3 has a build, a run of a fixed scenario, and a pin model in QEMU (`PIN_TWIN_PLAN.md`), but no session.
This plan gives the C3 the same session, through the same parts the UNO uses.

States are the four words: source-tested, staged, installed, live-verified. Nothing here is in a release yet.

## 1. The shape

One rule decides the rest: **the C3 twin speaks the AVR twin's control line.**
Then one sessions module, one backend hub, one door contract and one bench picture serve both chips.

| Part | UNO today | C3 |
|---|---|---|
| Twin process | `polari-avr-twin --hex .. --tcp .. --ctl ..` | `polari-c3-twin --image .. --layout .. --wires .. --tcp .. --ctl ..` |
| Worker sessions | `prf-board-engines/board_sessions.py` | the same file, `SESSIONS_KIND=c3` |
| Worker | board-engines | esp-engines |
| Door | `twin.board-engines.isle` | `twin.esp-engines.isle` (named in `TWIN_DOOR_PLAN.md` §3) |
| Backend | `board/custom/twin_sessions.py` (UNO only) | the same file, by chip family |
| Page | Sim bench, config `uno-light` | Sim bench, config `esp32c3-light` |

Differences the control line carries in words, never silently:

- Pads are named `GPIO<n>`. Which pads exist is what the pin model reports when its channel opens.
- A pin event carries `ns` (QEMU's virtual time). The AVR twin's `cycle` has no counterpart, so none is sent.
- A pad can float: `"level": null, "z": true`. `{"set": "GPIO3", "level": "z"}` lets a pad go.
- Pause, reset and ADC are refused in words. The C3 twin has none of them yet.

QEMU's own pin channel has no token and takes one client. In a session it is a UNIX socket inside the twin's
own folder (mode 0700), and the twin is its one client. It is never on the network.

## 2. Phases and gates

| Phase | What | Gate | State |
|---|---|---|---|
| c3g-1 | `prf-esp-engines/polari_c3_twin.py`, the twin behind the control line | A real chip-HAL light image in the pin-model QEMU: two presses on the button pad over the control line change the LED pad twice. No network. | source-tested 2026-11-23 |
| c3g-2 | Sessions in the ESP worker: `board_sessions.py` by kind, the worker's routes and capability block, the image's copy lines | The worker's own app starts a session from a posted image; two presses over the session's control port change the light twice; stop and time-out take the twin and its QEMU and leave no file. The AVR door and hold self-tests still pass on the changed module. | source-tested 2026-11-23 (in a trial image, see §3) |
| c3g-3 | Backend by chip family: `twin_sessions.py`, `twin_session_worker.py`, `board_engines.resolve_sessions(family)`, fakes, an offline self-test, CLI help | A C3 config starts a session against a made-up worker and twin; inject, events, record and stop work as for the UNO; every UNO check still passes. | source-tested 2026-11-23 (§3) |
| c3g-4 | The door for the ESP worker | A session's control line is reached through `wss://` with the token as first frame, as for the board worker. | built 2026-11-23 (D-c3g-1 A): `websockets` 15.0.1 by hash in the ESP image, `test_c3_door.py` in the image 5/5. By hand on pol: worker and door as two containers of the image, a real light session through the door, two presses: GPIO0 0 → 1 → 0. Store app `esp-engines 2026.11.23-1` + door app `twin-esp-engines` defined (Isle-Mesh `dev-c3-door`), not published |
| c3g-5 | The Sim bench for a C3 config: the picture, the pad names, the parts that have no C3 counterpart yet (potentiometer, TMP36: no ADC) said in words | The page shows a C3 session, a press lights the LED, Escape and click rules hold. | source-tested 2026-11-23 (§6) |
| c3g-6 | Release and live proof | On the isle: start a C3 session from the Sim bench, press, the LED follows. Then `pol board flash c3` (dry run first) for the real board. | needs the user's go |

## 3. What was measured (2026-11-23, pol, no network)

- c3g-1: `test_c3_twin.py`, 10 of 10 in the local ESP image. The real half: GPIO0 was 0, two presses on GPIO3
  gave GPIO0 = 1 then 0. QEMU 9.2.2, the pin-model build.
- c3g-2: `test_c3_sessions.py`, 7 of 7 on a stand-in QEMU (host, and inside the image at build time), and the real
  one in the image: the worker took the 4 MB image as one request (5.6 MB of base64), the session was ready
  0.6 s later, two presses changed the light twice, and one session held 64 MiB (the twin and its QEMU).
  Eight sessions (the limit) are about 512 MiB; the worker's limit is 2048 MiB.
- The AVR side on the changed sessions module, in the released board image: door self-test 29 of 29, hold
  self-test 8 of 8.

- c3g-3: `board/board_twin_session_c3_selftest.py`, 33 of 33, on the host with no worker, no QEMU and no
  network (a made-up esp worker and a made-up C3 twin that speak the real ones' words). On the changed backend
  the UNO checks are unchanged: session 28 of 28, transport 20 of 20, bench 48 of 48, hosted bridge 65 of 65.
  What the backend does for a C3, in one place (`board/custom/twin_kinds.py`):
  - the config's chip picks the worker: a C3 goes to the esp worker only, a UNO to the board worker only;
  - a C3 config with no pads, and `free`, are refused in words before anything is built or asked;
  - the request carries the image, the pin layout as the chip rows export it, and the LED-to-sense jumper;
  - `set GPIO3 z` lets a pad go; ADC, reset and pause come back refused in the twin's own words;
  - `pol board twin session events` prints a C3 edge with its virtual ns; `show` prints the driven pads.

  Known limits, said here so nobody finds them by surprise:
  - The first build of a C3 source on an engine image takes minutes, and the start request waits for it.
    After that the build store answers at once. Whether a wait that long gets through the isle's agent as
    one request is not proven (the agent's read time-out is owed).
  - A recorded press of a C3 has no cycle count ("not reported by the twin"). The twin's `ns` is on the pin
    event but is not kept on the interaction row yet.

**The image.** The heavy layers of the ESP image were not in the build cache, and a build with no network stops
at the first package step. So the proof ran in a trial image: the local released image plus exactly the tracked
Dockerfile's late lines (the copies, the two tests at build time). The tracked Dockerfile itself was not rebuilt.
A real rebuild fetches again what the first build fetched (packages, ESP-IDF, the QEMU source). That was allowed
once, for that build; doing it again is the user's word (§4).

The build command changed: the sessions module is taken from the board worker's folder, never copied into the
ESP folder.

    docker build --build-context sessions=../prf-board-engines -t prf-esp-engines:noble .

The dev compose file names the same context.

## 4. The user's decisions

**D-c3g-1. How the door reaches the ESP worker.** The door (`prf-board-engines/twin_door.py`) needs the Python
`websockets` package, version 13 or newer. The board image has it from its own distribution. The ESP image is
built on Ubuntu 24.04, whose package is 10.4: too old.

| | Choice | Cost |
|---|---|---|
| A (recommended) | Add `websockets` to the ESP image, pinned by sha256 as the board image pins `pyvcd`. The door is then a second container of the ESP image inside the `esp-engines` store app, exactly as the board worker does it. | One small download at image build (pure Python, about 200 kB), inside the rebuild below. |
| B | The `esp-engines` app carries the board image as well, only to run the door. | No download, but about 1 GB more in the app's packet, and two apps carrying one image. |
| C | The installed board door learns to serve several workers under one name. | No download, but it breaks the contract's "one name per worker" and couples the two apps' releases. |

**D-c3g-2. Rebuilding the ESP image.** Release 94 needs the ESP image rebuilt from the tracked Dockerfile, with
the same downloads as its first build. One yes covers A and the rebuild.

## 5. Not in this plan

- Pause, reset and ADC on the C3 twin (the pin model has no analog pads yet).
- The serial stream through the door for a generated bridge: it follows the board worker's `uart` path unchanged
  once the door exists.
- A server-side C3 build through the installer API (the UNO's path); c3g-3 builds with the shipped pipeline.

## 6. c3g-5: the Sim bench picture for a C3 (design, 2026-11-23)

Read in source first. Two findings shaped it:

- The picture already follows the session. When the picked session runs another config, the view asks the
  layout door for that config. So the page needs no new setting; a C3 session only needs the layout door to
  answer for `esp32c3-light`.
- The layout engine refuses every board but the UNO ("layouts are built for the arduino-uno-r3 only so far"),
  and names the UNO in a handful of places: the circuit, the pin label, the header board, the supply label,
  the twin pin name, the connectors, the step words.

**The rule: two small tables, nothing typed per config.**

| Table | Holds | Where |
|---|---|---|
| Layout facts per board | circuit, bench header board, pin label, supply label, connectors, where a pin sits, the words for the board | `electrodevice/custom/layout_boards.py` (new) |
| Twin facts per chip | pad name, release (a level or let go), the clock of an edge (cycle at 16 MHz, or ns), ADC or none | `board/custom/twin_kinds.py` (exists since c3g-3) |

The layout engine reads the first; the scene reads both. A third board is a row in each, not code.

**What a C3 picture is.**

- The circuit rows `c3-light` (seeded 2026-10-29: the same kit parts, LED on GPIO0 through 220 ohm, button
  GPIO3 to GND, jumper GPIO0 to GPIO1).
- The board is the ESP32-C3-DevKitM-1, the reference board whose headers `board_c3.HEADERS` cites from
  Espressif's user guide. A header pin is named by its BoardPin (`GPIO0`); the words add what is printed
  (`IO0`, `TX`).
- **No C3 board is on the bench.** The bench board row `bench-c3-1` says so, and so does the layout's note.
  The picture is the design and the twin; the header order of a real board is checked when one arrives.
- A press drives the pad to 0; a release lets the pad go (`z`), as a real pushbutton does. The chip's own
  pull-up then decides the level.
- An edge is stamped in ns. The browser reads the clock from the scene, so PWM duty works for either chip.
- A let-go pad is drawn dark with the words "let go: nothing drives it", never as low.
- The C3 twin has no ADC. A knob or a temperature part wired to a C3 gets no control and says why.
- The LED at 3.3 V: (3.3 V - 2.0 V assumed) / 220 ohm = about 5.9 mA. The forward voltage is the same
  assumption as the UNO circuit's. The pad's drive limit is not cited here, and the note says so.

**The contract between the door and the browser** (additions to `scene`; the UNO's values are unchanged in
meaning):

| Key | UNO | C3 |
|---|---|---|
| `scene.clock` | `{"unit": "cycle", "hz": 16000000}` | `{"unit": "ns", "hz": 1000000000}` |
| `interaction.released_level` (press, toggle) | `1 - pressed_level` | `"z"` |
| `scene.adc_max_mv` | 5000 | 0 (no ADC) |
| `boards[0].connectors[]` | the four headers and ICSP | `J1`, `J3`: `labels` (BoardPin names and power labels), `silk` (what is printed) |
| pin event | `level`, `cycle` | `level` or null, `z`, `ns` |

The browser draws the UNO's headers as today. Any other development board is drawn generically: the first
connector along the edge that faces the breadboard, the second along the far edge, pins one pitch apart.

**Gate.** Offline: `layout_place('esp32c3-light')` passes the netlist gate on the half breadboard, with the
scene above; every existing layout, bench and page self-test is unchanged. Browser tests: a C3 scene draws,
a press sends 0 and a release sends `z`, a let-go pad is not shown lit or low. Live (c3g-6): the page.

**Measured (2026-11-23, pol, no network).**

- The C3 layout: 4 nets equal to the design's, on the half breadboard; wires from `GPIO0`, `GPIO1`, `GPIO3` and
  `GND` of `bench-c3-1`. `electrodevice.layout_selftest` 110 of 110, of which 18 are the C3's
  (`layout_c3_selftest.py`); the electrodevice module 139 of 139.
- The UNO layout is byte-for-byte the same: `sha` and `steps_sha` of `uno-light` did not change. Its scene only
  gained the new keys.
- Bench 48 of 48, sessions 28 of 28 (UNO) and 33 of 33 (C3), the page module 171 of 171.
- Browser tests 131 of 131 (layout view, pin view, the table's Escape). The generic board is 12 pitches tall, so
  six-letter labels at both edges and the title do not meet.
- A side effect worth knowing: a development board's allowed header pins are now its own. Before, every
  development board also took the UNO's labels, so a C3 wire from `D6` would have passed the check.

- The whole board module on the changed tree (c3g-3, c3g-5, finding 6, the C3 proof over the ladder), run on pol
  2026-11-23 before the installer work began: 1,198 of 1,198 checks in 28 minutes, with no engine worker and no
  network. One check says it is skipped on this device (the gate's refusal with no twin, because pol has a local
  twin). An earlier run was cut off by a 25-minute limit and is not counted.
- The two halves together, once, by hand: the layout the engine really builds for `esp32c3-light` took the
  made-up scene's place in the mounted view's tests; all 40 passed. It is not kept as a fixture.

Not proven: the page in a real browser against a live session; the header order against a real board; a slider
part on a C3 (no C3 circuit has one).
