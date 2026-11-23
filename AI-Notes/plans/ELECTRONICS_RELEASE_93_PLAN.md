# Release 93 and 94: the full electronics simulation on the isle — plan, 2026-11-22

**The user's words (2026-11-22):** "we need to get board simulations and hal fully working so we can prep loading to real
boards"; "yeah we need to do a deployment to ensure everything is up for the full simulation"; "so plan the next deployment and
fix anything that needs fixed". On the ESP worker (decisions 2 and 3 of §7): "yes to both 2 and 3, incorporate them into 93".

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
| 5 | C3 configs are offered, and no ESP worker is installed | the worker: release 93 (a store app on econ). A live C3 session: its own slice (§4) |
| 6 | The page description is shown twice | not looked into yet |

## 2. Release 93: what it carries

Packet `cli-release-93`, built on pol from Isle-Mesh commit `d6e7f2522fdb` (clean checkout, 552 files compared byte for byte).
Run id `3f217807400de9a29f91c73087b256830e8723ef1b7eb39fbd354400f62956e9`. 3.4 GB.

This is the second packet of release 93. The first (commit `9580e457c638`, run id `3a52a74a…`, 1.5 GB, no ESP worker) was staged
and never run; the packet on the core was replaced by this one, so the first command no longer matches anything.

| Part | Contents | How it was made |
|---|---|---|
| Backend image of the core and of every instance | `polari-framework/prf-backend:2026.11.22-release93-candidate`, framework `dev` at `bdad7efb` (HAL merged, the pin twin rows, the C3 pin-model client) | `pol build image backend`: the published image's 34 layers plus one layer of source. No download. |
| Frontend image | `polari-framework/prf-frontend:2026.11.22-release93-candidate`, angular `dev` at `ecf869f` (findings 2 and 3) | `pol build image frontend`: 16 of 19 layers are the published image's. The base came from the core. |
| Agents | unchanged (`core-agent:release92`, `remote-agent:release92`); the packet carries no archive for them | the release-92 images already hold this commit's agent scripts |
| Packages | `isle-mesh-cli 0.1.213+release93`, `isle-app-store 0.1.93+release93`, `polari-complete-offline 0.1.93+release93` | built from the commit |
| Store app | `esp-engines` `2026.11.22-1` (manifest `91e9bbea00f7…`), image `esp-engines/esp-engines:2026.11.22-1`, 1.9 GB: the tracked `prf-esp-engines` build with the QEMU pin model, worker files of rf-node `cc25fb5` | `isle store build` from `Isle-Mesh/isle-cli/releases/esp-engines/` (no pull), then `--store-app econ-core:<folder>` |
| Steps, every device | device-backup, then update | |
| Steps, econ only | `store-install esp-engines 2026.11.22-1`, after its update | |
| Steps, pol only | `module-add hal` to `polari-pol` (finding 4) | |
| Verify, each device, 200 | `api.polari.isle/api/islemesh/updates`, `apt.isle/InRelease`, `api.polari.isle/api/health`, `polari.isle/`, `electronics.isle/` | |

Also in the CLI of this release, source-tested only: putting a device-backup back; the wait on an instance's own backend after
`module-add`; the wait when a backend answers 503 during its boot; a packet with several store apps.

The command, once the gates of §3 hold, on the core:

```
sudo isle release run ~/isle-release-93 --expect 3f217807400de9a29f91c73087b256830e8723ef1b7eb39fbd354400f62956e9
```

Costs and limits:

- pol's backend boots twice (the update, then the module): about 250 s each. The electronics pages answer 503 meanwhile.
- The core publishes a 1.9 GB image archive, and econ fetches and loads it (econ had 25 GB free).
- The runner that reads the packet and executes a device's steps is the one installed BEFORE the release. So the new waits hold
  from release 94 on, and on 93 the `module-add` and `store-install` steps are checked by the release-92 runner.
- That runner reads a store app's files from the ROOT of the packet. The builder first put the app into `catalog/esp-engines/`,
  and `isle release check` of release 92 refused that packet. Now a packet's only store app lies at its root (several: a folder
  each, which needs a release-93 runner; the build says which).
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
| The packet is on the core as `~/isle-release-93` and valid there and on pol (`isle release check`, no sudo, the installed release-92 CLI) | passed on both: 10 files match, the plan reads as in §2 |
| ESP worker: a long run through the member's agent (its 60 s read limit) | passed with the network off, through the agent's nginx and its own location block. Keep-alive off: 504 at 60 s (the control). On: 200 and the whole answer (1 CPU 182 s; 3 CPUs 69 s). The worker sends one space every 20 s until the run is over (`WORKER_KEEPALIVE_S`), then the same JSON. `test_keepalive.py` 5 of 5 |
| ESP worker image: the C3 light self-test on it | `board.board_light_c3_selftest` 31 of 31 (from-scratch build 62 s on pol) |
| ESP worker limits, measured | peak memory 907 MiB (limit 2 GiB), 159 MB in `/tmp`, an 11.4 MB answer (upload limit 32m), 3 CPUs |
| Every module self-test in the backend image, against the same run on the published image | 385 run, 344 pass. Of the 41 others, 31 fail the same way on the published image. The 10 that differ: 7 are one missing manifest line (fixed in source, framework `2a36311b`; no effect on a running backend, so the image was not rebuilt), 1 passes alone, 1 is a new check that needs a board engine, 1 hit the time limit. Detail: `TESTING_OWED.md` §80 |

## 4. The workers as store apps: the ESP worker in 93, the others in 94

What the full simulation still lacks after 93 is the other workers, and one piece of code. Each worker is a store app, installed by a
step of a release run. The store knows all of them (`isle store show <app>`), and only the board worker has a published
release until 93 publishes the ESP worker.

| Worker | Image on pol now | Device (`ELECTRONICS_DISTRIBUTION_PLAN.md`) | Open |
|---|---|---|---|
| `esp-engines` (C3 builds and runs) | `prf-esp-engines:noble`, rebuilt 2026-11-22 from the tracked Dockerfile with the pin model (the user's word; 13.5 min, apt packages and the espressif/qemu clone). The 2026-10-29 image is kept as `:noble-2026-10-29` | econ | In release 93. A per-app read timeout in the agent stays open (the keep-alive makes it unnecessary for this worker) |
| `scope-engines` | `prf-scope-engines:trixie` (its service file is the tree's) | econ | Not needed yet: without a worker the instruments module runs the emulator in-process. As an isle app its waveform data would need raw SCPI sockets across devices, which the agent does not carry. A design question, not a deployment. |
| `bridge-engines` (real boards) | none built for the isle | pol (the boards are here) | needs the isle trust bundle and the USB devices in its compose file |
| `formal-engines`, `pcb-engines` | `prf-formal-engines:trixie` on pol | econ, the core | not needed for the light proof |

**The piece of code (read in the source 2026-11-22):** a live twin session is AVR only (`board/custom/twin_sessions.py`, one
MCU, the board worker's sessions and its door). The ESP worker answers batch requests only (build, run a scenario). So once
`esp-engines` is installed, the C3 light is built and proved from the Electronics app with the pin model, and a button on the
Sim bench still cannot press a C3 pad. That needs: sessions in the ESP worker (QEMU with the pin port open), a door for the pin
channel as the board worker has for ctl and uart, and `twin_sessions` choosing the worker by the config's chip. Finding 5 is
therefore two steps: the worker (release 93), then the C3 session (its own slice, `c3g`).

Built for this (Isle-Mesh `6ba55fe`, then `d6e7f25` for the place in the packet; used for release 93): `isle release build --store-app <device>:<folder>`. It
takes the folder `isle store build` left, puts it into the packet, adds the publication, and gives the device its install step
with the manifest sha256 the core will store (a test publishes the packet's folder and compares). Without `--previous` it
builds a packet of store apps alone, so workers do not have to wait for a CLI release.

Order of work:

1. Done 2026-11-22: the tracked image build, the store definition in `Isle-Mesh/isle-cli/releases/esp-engines/` (limits,
   `deploy.engine: esp`, `deploy.maxUpload: 32m`, health path `/capability`), `isle store build`, the packet (§2).
2. After 93 is installed: the C3 light built and proved from the Electronics app on the isle's worker (a batch run on modelled
   pads), §5.
3. The C3 session slice, then the proof the UNO has today: a button on the Sim bench, a C3 pad, the LED.
4. `bridge-engines` as a store app once its compose file is settled (release 94).

Found on the way, open: `isle store build` reads a relative definition path against the CLI's own folder (an absolute path works).

## 5. The proof after release 93 is installed

1. `https://api.polari-pol.isle/api/modules/status`: 16 modules online, `hal` among them. `/api/hal/socs` answers 200.
2. Sim bench, `uno-light`: a click on SW1 in the picture presses the button and LED1 follows (finding 2).
3. Escape on the page keeps the session (finding 3).
4. The CLI session as in §1.
5. `isle store status` on econ: `esp-engines` on `2026.11.22-1`. `https://esp-engines.isle/capability` answers 200 with its engines.
6. `pol engines sync --api https://api.polari-pol.isle`, then `pol engines list --api https://api.polari-pol.isle`: the `esp`
   engine is bound to the isle's worker.
7. A C3 light build and a pin-model run through that worker, from the Electronics app or `pol`.

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
2. Which workers are installed, and on which device. Answered 2026-11-22 for the ESP worker: on econ, in release 93. The
   others (table in §4) are open.
3. Whether the ESP worker image may be built with the pin model (a download: apt packages and the espressif/qemu clone).
   Answered 2026-11-22: yes. Built.
4. Whether `pin_shim 0` becomes the light's default once every ESP worker holds the pin model.
5. Regenerating the C3 access evidence (a download of the SVD and the TRM).
6. Plugging in a UNO or a C3 for a real flash, after the simulation proof.
7. The old swarm stack on pol, and the stale `prf-board-engines:trixie` tag there.
