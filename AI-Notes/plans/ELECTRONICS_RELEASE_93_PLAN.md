# Release 93 and 94: the full electronics simulation on the isle — plan, 2026-11-22

**The user's words (2026-11-22):** "we need to get board simulations and hal fully working so we can prep loading to real
boards"; "yeah we need to do a deployment to ensure everything is up for the full simulation"; "so plan the next deployment and
fix anything that needs fixed".

State words used here, never merged: source-tested → staged → installed → live-verified.

Companions: `TWIN_DOOR_PLAN.md` (the door and its install records), `ELECTRONICS_DISTRIBUTION_PLAN.md` (which worker on which
device), `PIN_TWIN_PLAN.md` (the C3 pin model), `RELEASE_RUN_PLAN.md` (the one-command release), `TESTING_OWED.md` §80 (evidence).

## 1. What is live now (release 92, read 2026-11-22)

Release 92 is installed on all three devices. On it, the simulated UNO light works end to end on the isle:

- A twin session on the board worker (econ, store app `board-engines` `2026.11.15-2`) started from pol's instance `polari-pol`.
- By CLI: `pol board twin` drives the button pad low and high, and the LED pad follows.
- In the browser: `https://electronics.isle/` → Sim bench, config `uno-light`, "Press and hold: SW1 (D2)" lights LED1. A
  recording of that is in the user's Downloads folder (`uno-light-sim-bench-button-toggles-led.gif`).

Six findings from that proof:

| # | Finding | Where it is fixed |
|---|---|---|
| 1 | No bridge worker is installed anywhere, so no path from the page to a real board | release 94 (a store app on pol) |
| 2 | A click on SW1 in the picture selected a wire instead of pressing the button | frontend source, in release 93 |
| 3 | Escape unbound the session from the page | frontend source, in release 93 |
| 4 | `hal` is not a module of `polari-pol` (an update drops it), so `/api/hal/socs` answers 404 | release 93 (`module-add`) |
| 5 | C3 configs are offered, and no ESP worker is installed | release 94 (a store app) |
| 6 | The page description is shown twice | not looked into yet |

## 2. Release 93: what it carries

Packet `cli-release-93`, built on pol from Isle-Mesh commit `9580e457c638` (clean checkout, 546 files compared byte for byte).
Run id `3a52a74a2d8e457e89bd1c6f5d9ada9f3864e837b144c629b7851e73d8d4390b`. 1.5 GB.

| Part | Contents | How it was made |
|---|---|---|
| Backend image of the core and of every instance | `polari-framework/prf-backend:2026.11.22-release93-candidate`, framework `dev` at `bdad7efb` (HAL merged, the pin twin rows, the C3 pin-model client) | `pol build image backend`: the published image's 34 layers plus one layer of source. No download. |
| Frontend image | `polari-framework/prf-frontend:2026.11.22-release93-candidate`, angular `dev` at `ecf869f` (findings 2 and 3) | `pol build image frontend`: 16 of 19 layers are the published image's. The base came from the core. |
| Agents | unchanged (`core-agent:release92`, `remote-agent:release92`); the packet carries no archive for them | the release-92 images already hold this commit's agent scripts |
| Packages | `isle-mesh-cli 0.1.213+release93`, `isle-app-store 0.1.93+release93`, `polari-complete-offline 0.1.93+release93` | built from the commit |
| Steps, every device | device-backup, then update | |
| Steps, pol only | `module-add hal` to `polari-pol` (finding 4) | |
| Verify, each device, 200 | `api.polari.isle/api/islemesh/updates`, `apt.isle/InRelease`, `api.polari.isle/api/health`, `polari.isle/`, `electronics.isle/` | |

Also in the CLI of this release, source-tested only: putting a device-backup back; the wait on an instance's own backend after
`module-add`; the wait when a backend answers 503 during its boot; a packet with several store apps; `--store-app` (§4).

The command, once the gates of §3 hold, on the core:

```
sudo isle release run ~/isle-release-93 --expect 3a52a74a2d8e457e89bd1c6f5d9ada9f3864e837b144c629b7851e73d8d4390b
```

Costs and limits:

- pol's backend boots twice (the update, then the module): about 250 s each. The electronics pages answer 503 meanwhile.
- The runner that executes a device's steps is the one installed BEFORE the release. So the new waits hold from release 94 on.
  On 93, the `module-add` step is checked by the release-92 runner.
- The core's update has once raced its own backend's boot (`TWIN_DOOR_PLAN.md` finding 9). If the run stops on the core at
  that point, the same command again continues it.
- No verify on `api.polari-pol.isle`: econ and the core would have to reach it at the right moment of pol's boot.

Rollback: the release-92 runtime manifest and packages (`~/isle-release-92` is still on the core), and the device-backup the
run takes first on each device.

## 3. Gates before the command is handed over

| Gate | Result |
|---|---|
| Source tests of the builder and the runner | passed: release-run 118, release-build 27, named-images 11, agent-images 17, store-build 21, store-apps 6 |
| Backend image holds the commit | passed: 4,912 files identical, none missing, one stale `.gitignore` |
| Frontend image starts and serves its pages with the network off | passed by hand. The committed verb's byte-for-byte page check was NOT run for this image |
| The packet is on the core as `~/isle-release-93` and valid there and on pol (`isle release check`, no sudo) | passed on both: 7 files match, the plan reads as in §2 |
| Every module self-test in the backend image, against the same run on the published image | 385 run, 344 pass. Of the 41 others, 31 fail the same way on the published image. The 10 that differ: 7 are one missing manifest line (fixed in source, framework `2a36311b`; no effect on a running backend, so the image was not rebuilt), 1 passes alone, 1 is a new check that needs a board engine, 1 hit the time limit. Detail: `TESTING_OWED.md` §80 |

## 4. Release 94: the workers as store apps

What the full simulation still lacks after 93 is workers, and one piece of code. Each worker is a store app, installed by a
step of a release run. The store knows all of them (`isle store show <app>`), and none but the board worker has a published
release.

| Worker | Image on pol now | Device (`ELECTRONICS_DISTRIBUTION_PLAN.md`) | Open |
|---|---|---|---|
| `esp-engines` (C3 builds and runs) | `prf-esp-engines:noble` (2026-10-29: no pin model, an older `polari-c3-run`); a local test image that holds the tree's files and the pin model, in no release | econ | The tracked image with the pin model needs a build that downloads. The user's word. |
| `scope-engines` | `prf-scope-engines:trixie` (its service file is the tree's) | econ | Not needed yet: without a worker the instruments module runs the emulator in-process. As an isle app its waveform data would need raw SCPI sockets across devices, which the agent does not carry. A design question, not a deployment. |
| `bridge-engines` (real boards) | none built for the isle | pol (the boards are here) | needs the isle trust bundle and the USB devices in its compose file |
| `formal-engines`, `pcb-engines` | `prf-formal-engines:trixie` on pol | econ, the core | not needed for the light proof |

**The piece of code (read in the source 2026-11-22):** a live twin session is AVR only (`board/custom/twin_sessions.py`, one
MCU, the board worker's sessions and its door). The ESP worker answers batch requests only (build, run a scenario). So once
`esp-engines` is installed, the C3 light is built and proved from the Electronics app with the pin model, and a button on the
Sim bench still cannot press a C3 pad. That needs: sessions in the ESP worker (QEMU with the pin port open), a door for the pin
channel as the board worker has for ctl and uart, and `twin_sessions` choosing the worker by the config's chip. Finding 5 is
therefore two steps: the worker (release 94), then the C3 session (its own slice, `c3g`).

Built for this (Isle-Mesh `6ba55fe`, source-tested, in no packet yet): `isle release build --store-app <device>:<folder>`. It
takes the folder `isle store build` left, puts it into the packet, adds the publication, and gives the device its install step
with the manifest sha256 the core will store (a test publishes the packet's folder and compares). Without `--previous` it
builds a packet of store apps alone, so workers do not have to wait for a CLI release.

Order of work:

1. The user's word on building the ESP worker image with the pin model (decision 3 in §7). Then the tracked build.
2. A store definition for `esp-engines` in `Isle-Mesh/isle-cli/releases/esp-engines/`, modelled on the published board worker
   (limits, `deploy.engine: esp`, health path `/capability`). `bridge-engines` the same way once its compose file is settled.
3. `isle store build <definition> <folder>` (no pull), then `isle release build <out> --store-app econ-core:<folder>`, stage,
   check, one command.
4. Live proof of 94: the C3 light built and proved from the Electronics app on the isle's worker (a batch run on modelled pads).
5. The C3 session slice, then the proof the UNO has today: a button on the Sim bench, a C3 pad, the LED.

## 5. The proof after release 93 is installed

1. `https://api.polari-pol.isle/api/modules/status`: 16 modules online, `hal` among them. `/api/hal/socs` answers 200.
2. Sim bench, `uno-light`: a click on SW1 in the picture presses the button and LED1 follows (finding 2).
3. Escape on the page keeps the session (finding 3).
4. The CLI session as in §1.

## 6. Open, not part of 93

- `TWIN_DOOR_PLAN.md` findings 1, 2, 3, 4, 6, 8 (DNS for an app without a catalog entry; an install while a publish is in
  transit; the 15 minutes from publish to replica; `curl -skf` in `dns-reconcile.sh`, isle-core's lane; `isle dns help`; a
  runtime-only release still needs a package publish).
- Storage is not allocated by role on any device (no device registered, no partition with a role). The registry and the file
  store wait on that. Planned as one run of the user's, not a list of sudo steps.
- The 24.04 dependency set is staged on the core and not run.
- Tracked scripts of the old swarm stack in `polari-cli` (`scripts/swarm*.sh`, `scripts/lan-ip-selftest.sh`, six files in
  `shells/`) hold addresses of a private network that the privacy list matches (34 places). They were there before this
  work. Replacing them with made-up addresses is a small fix of its own; the history keeps the old values either way.

## 7. The user's decisions

1. Running release 93 (the command in §2).
2. Which workers release 94 installs, and on which device (the table in §4 is the proposal: the ESP worker on econ first).
3. Whether the ESP worker image may be built with the pin model (a download: apt packages and the espressif/qemu clone).
4. Whether `pin_shim 0` becomes the light's default once every ESP worker holds the pin model.
5. Regenerating the C3 access evidence (a download of the SVD and the TRM).
6. Plugging in a UNO or a C3 for a real flash, after the simulation proof.
7. The old swarm stack on pol, and the stale `prf-board-engines:trixie` tag there.
