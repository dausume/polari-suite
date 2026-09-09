# 3D-printing suite — licence + simulation gate (fetched 2026-09-08/09 UTC)

**Verdict: ✅ PASS for the whole proposed stack — Klipper + Moonraker +
Mainsail/Fluidd (all GPL-3.0), simulavr (GPL-2.0-or-later), Kiri:Moto
(MIT, one header caveat), Voron design files (GPL-3.0) are all
GPLv3-compatible and offline-pinnable. Nothing NC. Two RED items exist
only as things we must NOT embed: NC Viewer (proprietary web tool) and
any OctoPrint/Marlin piece (wrong stack, not licence). No open-source
physics-level FDM simulator exists at maturity — the physics rung is
ours (`waxprint`).**

Frame: whole project GPLv3 ([[project-license-gplv3]]). Method: three
sources per component — repo LICENSE file, published claim (GitHub
metadata / package manifest / README), and per-file headers — all
fetched on the dates above; tags resolved to commit SHAs via the GitHub
API; simulavr and grid-apps also shallow-cloned and grepped locally
(scratchpad). Anything not directly confirmed is marked **UNVERIFIED**.

Standing rules applied: NC = hard blocker (none found); GPL-incompatible
= blocker unless separate process (none found; AGPL handled in §3);
every adopted upstream → `dausume/` fork at a verified commit (§5).

---

## 1. Control stack in the KVM guest

| Component | Licence (3 sources) | Repo / default branch | Pin target (verified SHA) | Offline install |
|---|---|---|---|---|
| **Klipper** (host `klippy` + MCU firmware) | GPL-3.0 — `COPYING` = GPLv3 text; GitHub `GPL-3.0`; headers "may be distributed under the terms of the GNU GPLv3 license" in `klippy/klippy.py`, `src/sched.c`, `src/linux/main.c`, `scripts/avrsim.py`, `scripts/test_klippy.py` | `Klipper3d/klipper`, `master` | Latest tag **v0.13.0** (2025-04-11) = `61c0c8d2ef40340781835dd53fb04cc7a454e37a`. Master head at fetch = `8c29c0a8e205d897f765ce867b983e009cbe32a1` (2026-09-08). Klipper tags rarely; the ecosystem (Moonraker, Mainsail, virtual-klipper-printer) tracks `master`. Recommend pinning a **dated master commit**, not v0.13.0 (17 months stale). | YES. Pure Python + one C helper that `klippy/chelper/__init__.py` compiles **at first run with `gcc`** (`GCC_CMD = "gcc"`) → guest image needs gcc but no network. Python deps are exact-pinned in `scripts/klippy-requirements.txt` (greenlet, cffi, Jinja2 2.11.3, markupsafe, pyserial 3.4, python-can 3.3.4, setuptools, msgspec) → wheelhouse. MCU firmware: build `out/klipper.elf` + `out/klipper.dict` at image-build time (`avr-gcc` for the simulavr target; `arm-none-eabi-gcc` for a real Octopus/M8P); ship the artefacts. Klipper itself has no updater and makes no network calls. |
| **Moonraker** | GPL-3.0 — `LICENSE` = GPLv3; `pyproject.toml` `license = {text = "GPL-3.0-only"}`; headers "GNU GPLv3 license" in `moonraker/server.py`, `components/update_manager/update_manager.py` | `Arksine/moonraker`, `master` | **v0.11.0** (annotated tag `68db047…` → commit `985c1d0bbeb90bc057d34a232c9dc3b05e0c6c8d`, 2026-08-25 = master head at fetch) | YES. `scripts/moonraker-requirements.txt` (pip), `scripts/system-dependencies.json` (apt: python3-virtualenv, python3-dev, libopenjp2-7, libsodium-dev, zlib1g-dev, libjpeg-dev, packagekit, wireless-tools/iw, curl, build-essential), `scripts/python_wheels/` already carries zeroconf wheels. **`[update_manager]` is an optional component: omit the section and nothing is ever fetched** (its `enable_auto_refresh` default is False anyway). Also set `[machine] provider: none` in a container/guest without systemd-dbus. |
| **Mainsail** (primary UI) | GPL-3.0 — `LICENSE` = GPLv3; GitHub `GPL-3.0`; **`package.json` has no `license` field and source files carry no headers** (2 of 3 sources; LICENSE governs — acceptable, note it in the fork) | `mainsail-crew/mainsail`, `develop` | **v2.19.0** (2026-08-27) = `5fb9e77fb9f4e60cf0725d9dc7f57cf7b84bbd70` | YES. Release asset `mainsail.zip` is the prebuilt static bundle → serve from nginx in the guest; no build step. Only outbound target is Moonraker. Its embedded G-code viewer dep `@sindarius/gcodeviewer` is **LGPL-3.0-or-later** (npm 3.7.18) — fine. |
| **Fluidd** (alternative UI) | GPL-3.0 — `LICENSE` = GPLv3; `package.json` `"license": "GPL-3.0"`; GitHub `GPL-3.0`; no per-file headers | `fluidd-core/fluidd`, `develop` | **v1.37.4** (2026-08-11), annotated tag → commit `7dd4ea0794a992daf5e56a52d350cf6728b1d901` | YES. Release asset `fluidd.zip`, static, same serving model. |

Both UIs are interchangeable behind Moonraker; ship Mainsail, keep
Fluidd as a pinned alternative only if a page needs it. Whether either
UI makes any other outbound request at runtime (fonts, update banners)
is **UNVERIFIED** — check with the guest's egress blocked on bring-up.

## 2. Simulating a Voron with no printer attached

### (a) Klipper "Linux process" MCU target
- Source: `src/linux/` (GPLv3 headers). Kconfig `MACH_LINUX` selects
  GPIO, ADC, SPI, I2C, hard-PWM. Pins are named `gpiochipN/gpioM` and
  are opened through `/dev/gpiochip*` (`src/linux/gpio.c`); ADC goes
  through Linux IIO; serial is the pty `/tmp/klipper_host_mcu`.
- With `[printer] kinematics: none` the **entire stack runs**
  (klippy ↔ linux-MCU ↔ Moonraker ↔ Mainsail). Klipper's own
  `test/klippy/linuxtest.cfg` is exactly this (`serial:
  /tmp/klipper_host_mcu`, `kinematics: none`). `NoneKinematics`
  (`klippy/kinematics/none.py`) has `get_steppers() → []` and
  `check_move` = pass, so **G0/G1 X/Y/Z moves are accepted and planned
  with zero steppers** — a `virtual_sdcard` print of a real G-code file
  will "run" to completion.
- What it does NOT simulate: **no steppers** (a KVM guest has no
  gpiochip; the `gpio-mockup`/`gpio-sim` kernel modules could fake one
  — plausible, **UNVERIFIED with Klipper**), **no ADC → no thermistors
  → no `[extruder]`/`[heater_bed]`** (an `[extruder]` section needs a
  sensor pin; without it `DummyExtruder.check_move` raises "Extrude
  when no extruder present" on any G1 E… — so a real sliced file fails
  at the first extrusion unless the config carries a sensor-less
  workaround, **UNVERIFIED**), no probing, no motion, no physics.
- Proves: services, sockets, Moonraker API/WS, file upload, macros,
  Mainsail rendering — the **"stack runs" rung**. Cost ≈ zero.

### (b) simulavr (AVR MCU simulation, what Klipper's docs and the Mainsail crew use)
- **Licence: GPL-2.0-or-later — GPLv3-compatible (we take it under
  v3).** Verified: `doc/COPYING` = GPLv2 text; 56 of 60 `libsim/` +
  `app/` sources carry "either version 2 of the License, or (at your
  option) any later version" (the 4 without a GPL line are small
  helpers with no licence line at all: `spisink.cpp`, `spisrc.cpp`,
  `hwpinchange.cpp`, `pinmon.cpp`); the nongnu.org homepage returned
  HTTP 429 at fetch time, so its "GPLv2 or later" claim is via search
  snippet only — headers + COPYING settle it. **Not GPLv2-only.**
- Repo: `git://git.savannah.nongnu.org/simulavr.git` (Klipper
  `docs/Debugging.md`), HEAD `32985f745c237bf8dcd2718235d01c8b1fb0491d`
  (**2020-10-06 — dormant six years**), last tag `release-1.1.0`. Build
  = cmake with `BUILD_PYTHON` (swig) → `pysimulavr` for the guest's
  Python. Klipper: `make menuconfig` → atmega644p + "Compile for
  simulavr software emulation" (`src/avr/Kconfig` `CONFIG_SIMULAVR`,
  allowed on atmega168/328/328p/644p/1284p); `scripts/avrsim.py -m
  atmega644p -s 20000000 -b 250000 out/klipper.elf` exposes a pty;
  `printer.cfg` uses `serial: /tmp/pseudoserial`.
- **Turn-key packaging exists: `mainsail-crew/virtual-klipper-printer`
  (GPL-3.0 by LICENSE + README badge + GitHub; master
  `e272bcd1060dad6cee1598d6debdaa5d5afae3c7`, 2026-01-10).** Docker,
  `python:3.12-slim-bookworm`; supervisord runs avrsim.py, klippy,
  moonraker (+ moonraker-timelapse, mjpg-streamer dummy webcam). Its
  Dockerfile `git clone --depth 1` Klipper/Moonraker/simulavr **at
  build time with no pins** — we would rebuild it from our pinned
  forks (it is a ~120-line Dockerfile + configs, easy to own). Its
  example `printer.cfg` is **cartesian** (`addons/basic_cartesian_
  kinematics.cfg`) with EPCOS thermistors, `control: watermark`,
  `CONFIG_WANT_TMCUART=y`; we swap in a corexy config on the same
  atmega644p pins.
- Pin budget (computed, not tested): the 644p exposes 32 GPIO
  (PA0–PD7), 8 of them ADC (PA). A Voron 2.4 (X, Y, Z×4, E = 7
  steppers × step+dir + one shared enable = 15) + 2 heaters + 2 ADC +
  X/Y/Z endstops + probe + 2 fans ≈ 25 pins → fits; Trident (3 Z) fits
  with room. TMC-UART lines add one pin per driver.
- Proves: the **real MCU protocol** — config compile, step compression,
  queued step pulses executed on a simulated 20 MHz AVR, endstop/probe
  pin toggles, heater PWM output — i.e. the **"motion kinematics on the
  wire" rung**, with Mainsail showing a live print. Klipper docs warn it
  needs a desktop-class CPU.
- Does NOT simulate: **any thermal model**. simulavr's ADC returns the
  pin's analog value; an unconnected pin is `ST_FLOATING`
  (`libsim/pin.cpp`) → constant reading → a non-zero M104/M140 target
  can never converge and Klipper's `verify_heater` should shut the
  printer down after `check_gain_time` (how virtual-klipper-printer
  users live with this is **UNVERIFIED** — no patch in its Dockerfile,
  no heater issue found). Fix = a `pysimulavr` shim in `avrsim.py`
  driving `AnalogValue` on the thermistor pins from a thermal model —
  that would be **our** code, and it is where `waxprint`'s
  `bead_cooling`/`auger_melt` models could feed a fake plant. Also: no
  mechanics (steps are counted, not integrated into a physical
  position), no belt/frame compliance, no resonance.

### (c) `scripts/test_klippy.py` + Klipper batch mode
- The harness (GPLv3 header) reads `test/klippy/*.test` files (37 at
  fetch) with `DICTIONARY` (prebuilt MCU data dictionary), `CONFIG`,
  `GCODE`, `SHOULD_FAIL` directives, and runs **klippy in batch mode**
  (`klippy.py cfg -i gcode -o out -d dict`) — **no MCU, no simulavr**.
  `printers.test` feeds `move.gcode` through `config/example-corexy.cfg`
  and every board config. Pass = klippy processes the stream without
  error (or errors when `SHOULD_FAIL`).
- Batch mode (`docs/Debugging.md` "Translating gcode files to
  micro-controller commands") + `klippy/parsedump.py` yields a
  **human-readable step-by-step MCU command timeline** for a given
  printer.cfg + G-code. Docs caveat: batch mode disables some
  request/response commands, so the output is for inspection, not for
  sending to a board.
- Proves: config parses, **corexy kinematics resolve, every move in
  a sliced file becomes a valid stepper schedule** — the
  **"motion kinematics, deterministic, CI-friendly" rung**, and the
  natural motion input for the `waxprint` movement analysis. Does not
  prove MCU execution, timing, or thermals. Needs data dictionaries
  (`make` per MCU, or the tarball in Klipper issue #1438).

### (d) Marlin native simulator
- Marlin: GPL-3.0 (`LICENSE` = GPLv3; GitHub `GPL-3.0`;
  `MarlinCore.cpp` header GPLv3-or-later). **2.1.2.8** (2026-06-24) =
  `1cd56c4ccd483045eb5a92c99e3ad3b5ab1bea6d`.
- `ini/native.ini`: `[env:linux_native]` = native HAL, "No supported
  Arduino libraries, base Marlin only" (used by `linux_native_test`
  unit tests); `[env:simulator_linux_release|debug]` = SDL2 + OpenGL
  + GLM GUI via **p3p/MarlinSimUI** (LICENSE = "GNU General Public
  License … either version 2 … or (at your option) any later version"
  → GPL-2.0-or-later; GitHub `NOASSERTION`; `main.cpp` has no header —
  2 of 3 but consistent). Marlin pins it as
  `archive/29c11d4f63.zip` = `29c11d4f63dc920c445672c51f2e40f5c7f7e77a`
  (2025-10-28); master `c21399b…` (2026-02-19).
- What it proves: Marlin's own planner/stepper ISR executing G-code
  natively with a 3-D toolhead view and a socket serial. **Wrong
  firmware for a Klipper Voron** — it would only cross-check G-code
  semantics, needs a display, and adds nothing Klipper batch mode does
  not. Licence green; **not adopted**.

### (e) OctoPrint virtual printer
- OctoPrint: **AGPL-3.0** (`LICENSE.txt` = AGPLv3; GitHub `AGPL-3.0`;
  plugin header `__license__ = "GNU Affero General Public License"`).
  1.11.8 = `42be7409d4820431043da48ece30014e26b47073`. The virtual
  printer is bundled (`src/octoprint/plugins/virtual_printer`).
- Simulates the **Marlin-style serial protocol only**: ok/M115/M105
  with a simple heat-up curve (ambient 21.3 °C default), SD card
  listing, resend/checksum/line-number error injection
  (`numExtruders`, `hasBed`, `forceChecksum`, `rxBuffer`,
  `resend_ratio`). No motion, no kinematics, no physics.
- Wrong stack (OctoPrint sits where Moonraker sits). AGPL is
  combinable (§3) but there is no reason to. **Not adopted.**

### (f) G-code viewers
- **Mainsail/Fluidd already embed a viewer** (Mainsail:
  `@sindarius/gcodeviewer`, LGPL-3.0-or-later) — the in-guest preview is
  free with the UI.
- **Kiri:Moto preview**: the sliced-layer/animation preview is part of
  Kiri:Moto (MIT, §3). Whether it imports third-party `.gcode` for
  preview (as opposed to its own output) is **UNVERIFIED**.
- **hudbrog/gCodeViewer**: `LICENSE` = "Creative Commons Attribution
  4.0" (GitHub `NOASSERTION`). CC BY 4.0 is GPLv3-compatible per the
  FSF but CC itself says not to use it for software; 2012-era code.
  Not needed — **skip**.
- **NC Viewer** (ncviewer.com): "© 2024 Toolpath Labs, Inc.", no
  source, no licence, web-only → **proprietary; RED for embedding;
  external reference link at most.**

### (g) Physics-level FDM process simulators
**None mature and open-source found.** What exists are building
blocks and paper code:
- PySPH (`pypr/pysph`, BSD-3 by `LICENSE.txt`, active 2026-08) — a
  paper extends it with a thermal multi-bead extrusion model; that
  extension's code availability is **UNVERIFIED**.
- NIST `usnistgov/openfoamEmbedded3DP` (NIST public-domain notice) —
  OpenFOAM filament shapes in an *embedded support bath*, not FFF in
  air; last push 2024-01.
- OpenFOAM viscoelastic multiphase FDM solver (2018 paper) — code
  **UNVERIFIED**.
- `ORNL/AdditiveFOAM` (GPLv3 per LICENSE header) and
  `tomflint22/beamWeldFoam` (GPL-3.0) — metal LPBF/DED/welding, not
  polymer extrusion. FEniCS 2-D DED heat model (LGPL-3.0) — DED.
- Everything commercial (Abaqus/ANSYS birth-death element studies,
  Digimat) is out of scope.

So the physics rung is Polari-native: `modules/waxprint/` already has
`auger_melt`, `bead_analysis`, `bead_cooling`, `movement_analysis`,
`voxel_resolution`, `print_optimizer` (GPLv3, ours). The honest
statement for the suite: **external software proves the stack and the
kinematics; the thermal/bead/melt side is ours and must be stated as
ours, with its own calibration ladder.**

### Ranking — what each rung actually proves
| Rung | Proves | Candidate | Licence |
|---|---|---|---|
| 5 Physics (melt / bead / cooling / warp) | thermal + deposition outcome | **waxprint (ours)** — no external option | GPLv3 (ours) |
| 4 Motion on the wire (MCU executes steps) | protocol, step timing, endstops/probe toggles, heater PWM, live Mainsail | **Klipper + simulavr (atmega644p)**, packaged as our rebuild of virtual-klipper-printer | GPLv3 + GPLv2-or-later — green |
| 3 Motion kinematics (no MCU) | corexy resolves, every move schedules, diffable step timelines | **Klipper batch mode / test_klippy.py** | GPLv3 — green |
| 2 G-code protocol executes | serial semantics only | OctoPrint virtual printer / Marlin simulator | AGPL / GPL — green but wrong stack, not adopted |
| 1 Stack runs | services, API, UI, macros, virtual_sdcard | **Klipper Linux-process MCU + `kinematics: none`** | GPLv3 — green |
| 0 Visual preview | layers/toolpath as drawn | Mainsail viewer (LGPL-3), Kiri:Moto preview (MIT) | green; NC Viewer RED |

## 3. Slicer: Kiri:Moto (primary) and the AGPL desktop slicers

### Kiri:Moto — `GridSpace/grid-apps`
- **Licence: MIT, with a header caveat.** `license.md` at `master` and at
  tag `4.7.3` = the MIT text ("Copyright 2014-2018 Stewart Allen");
  `package.json` `"license": "MIT"`; GitHub `MIT`. **But** in the 4.7.3
  clone 256 of 275 `src/**/*.js` files carry `/** Copyright Stewart
  Allen <sa@grid.space> -- All Rights Reserved */` (252 outside
  `src/ext`), and `src/moto/license.js` states `COPYRIGHT: "... All
  Rights Reserved"`, `LICENSE: "See the license.md file included with
  the source distribution"`. Reading: the header is a copyright
  assertion that explicitly defers to `license.md` for the grant, so
  the grant is MIT; but under our three-source rule this is **2 of 3
  explicit + 1 deferring → AMBER-note, verdict green**. Record the
  `license.js` text and the header count in the fork's POLARI-FORK.md
  so nobody re-litigates it. The stale "2014-2018" year in license.md
  does not narrow the grant (the notice ships with every tag).
- Third-party code vendored in `src/ext/` (base64, clip2/Clipper2,
  earcut, gerber, jspoly, jszip, manifold, md5, pngjs, tween) and npm
  deps (`three`, `manifold-3d`, `@gridspace/app-server` MIT, …) — all
  believed permissive, **individually UNVERIFIED**; enumerate at fork
  time (jszip is MIT/GPLv3 dual, either is fine).
- Pin: **4.7.3** (2026-08-16) = `ff7692241c48c3495da0bb8eb7455f906f3abb2d`
  (`package.json` still says 4.7.0 at that tag; `license.js` says
  4.7.3 — cosmetic).
- **Self-hosting: yes, plain web app.** `src/dock/Dockerfile`:
  `node:22-slim`, `npm i`, `npm run webpack-ext`, `npm run pack-prod`,
  `npm i -g @gridspace/app-server`, `CMD gs-app-server`, port 8080;
  `src/dock/compose.yml` wraps it. All slicing runs in the browser
  (web workers); the server is static + a small app-server. All
  fetching is at **image build** (npm registry) → build on the build
  host, run offline. Runtime grep of the 4.7.3 tree found no calls to
  grid.space other than OG meta tags, a "Generated by" string, a
  homepage link, and a dev-server warning that only fires when
  `location.host === 'dev.grid.space'`; no telemetry seen (grep-level
  check only — **UNVERIFIED** beyond that). docs.grid.space: "does all
  processing in the browser. None of your data is sent to or stored in
  the cloud"; PWA/offline claim is from forum posts, **UNVERIFIED**
  for the self-hosted build.
- **Moonraker export exists natively** (verified in
  `src/kiri/app/export.js`): `type === 'moonraker'` → `POST
  ${host}/server/files/upload`, then optionally `POST
  /printer/print/start`; OctoPrint export too; docs nav also lists
  Duet, GridBot, GridLocal. Because the **browser** does the POST, the
  guest's Moonraker needs `[authorization] cors_domains` to include the
  Kiri:Moto origin, and `trusted_clients`/API key for the isle range.
- **Isle-app fit:** one container (our rebuild of `src/dock/`) behind
  the isle agent, exactly like other isle apps — member tier, no
  privileges. Flow: Kiri:Moto (isle-app) slices in the operator's
  browser → uploads to Moonraker in the Voron guest over the isle
  network → Polari backend polls Moonraker (`/server/files`,
  `/printer/objects/query`, job history) to create the print-job
  objects, and can push the same file into the simulavr rung first.
  Kiri:Moto also has an iframe "Frame Message API" and states it "is
  designed to be embedded in or accessible through other web-based
  applications" — embedding it in a Polari page is iframe-level, no
  code linking (MIT anyway). Modes: FDM, CAM, laser, SLA, drag-knife,
  wire-EDM — so the same isle-app serves the CNC/laser side later.

### Desktop slicers (AGPL-3.0) — kept as options, not primary
| Slicer | Licence (sources) | Latest | Note |
|---|---|---|---|
| **OrcaSlicer** | AGPL-3.0 — `LICENSE.txt` = AGPLv3; README §License; GitHub `AGPL-3.0`; sampled sources have **no per-file headers** (2 of 3 + README) | **v2.4.2** (2026-07-07) = `8500fcdccaa10b5099ac20d252af3a7c560046f1` at **`OrcaSlicer/OrcaSlicer`** (`SoftFever/OrcaSlicer` now 301-redirects there) | Ships Voron profiles. Has a CLI (`--slice`) that could run headless in a container. |
| **PrusaSlicer** | AGPL-3.0 — `LICENSE` = AGPLv3; GitHub `AGPL-3.0`; per-file `///|/ Copyright (c) Prusa Research …` headers (the AGPL line beyond the sampled 4 lines not captured — **UNVERIFIED** in-header, LICENSE governs) | **version_2.9.6** (2026-06-25), annotated tag → `b028299c770b8380ee81c921a2867d522f288123` | CLI `--export-gcode`. |
| **SuperSlicer** | AGPL-3.0 — `LICENSE`; GitHub `AGPL-3.0` | **2.5.59.13** (2024-07-01); default branch `master_27` | Two years without a release → **amber for staleness**, not licence. |

**AGPL-3.0 + GPLv3, and what "as a separate app" means for us.**
GPLv3 §13 and AGPLv3 §13 explicitly permit combining the two into one
work; the AGPL-covered part keeps AGPL §13's obligation (offer
Corresponding Source to users interacting with it over a network),
which for a fully-published project costs nothing but must be honoured
(a source link in the UI that fronts it). "Separate app" for Polari =
own repo/fork, own container or desktop package, communicating with
Polari only by files and the Moonraker HTTP API — no import/link into
GPLv3 code — so Polari stays GPLv3 and the slicer stays AGPL without
any relicensing question at all. A headless Orca/Prusa CLI container
behind the isle agent would be that. They are heavy (wx/OpenGL deps)
and desktop-shaped; Kiri:Moto stays primary because it is web-served
and already speaks Moonraker.

## 4. Voron design files — `VoronDesign` org

| Repo | LICENSE file | GitHub metadata | Pin | Contents |
|---|---|---|---|---|
| `Voron-2` (branch `Voron2.4`) | GPLv3 text | `GPL-3.0` | **V2.4r2** (2022-02-23) = `45128487e8e8e4aa113bb2cbfdf5bf6752d242d3`; head `a192410…` (2025-05-30) | `CAD/`, `STLs/`, `Drawing_DXFs/`, `Manual/`, `firmware/klipper_configurations/{Kraken,M8P,Octopus,SKR_1.3,SKR_1.4,Spider}`, `slicer_profiles/` |
| `Voron-Trident` (`main`) | GPLv3 text (present; GitHub shows no licence because it does not auto-detect it) | none shown | **VTr2** (2026-06-13) = `a8628f48546948ce1fc15511b7765b7f31f80722`; head `f04f747…` (2026-06-27) | `CAD/`, `STLs/`, `Drawings_DXFs/`, `Manual/`, `Firmware/{Kraken,M8P,Octopus,SKR…}` |
| `Voron-0`, `Voron-Stealthburner`, `VoronUsers` (community mods), `Voron-Hardware` (`LICENSE.md` = GPLv3), `Voron-Documentation` (docs site source) | GPLv3 | `GPL-3.0` | — | — |

- **Verdict: GPL-3.0 across the org — green.** Polari may reference,
  redistribute and modify the CAD (STEP), STLs, DXFs, manuals and the
  **Klipper `printer.cfg` files** (the last are directly usable as the
  guest's config — the Octopus/M8P ones for the real board, edited
  onto atmega644p pins for the simulavr rung). Conditions are the usual
  GPL ones: keep the licence + copyright notices, and if we ship
  modified STLs ship the editable source (STEP) too. GPL on
  hardware-design files is legally awkward (it reaches the files, not
  the built machine), but the grant is explicit and it is the licence
  they chose — no CC-NC anywhere.
- **BOM: not in the repos.** Both READMEs point to the **configurator
  on vorondesign.com** for the Bill of Materials; that web tool's
  output licence is **UNVERIFIED** (no repo found). Derive our own part
  list from the CAD/manual (GPLv3) and link the configurator; do not
  scrape it.
- "Voron" name/logo trademark policy — **UNVERIFIED**; use the name
  nominatively ("Voron-compatible corexy"), no logo.

## 5. Recommendation table

| Component | Role in the suite | Licence verdict | Pin target (repo @ tag/commit) | Offline-install notes | dausume/ fork |
|---|---|---|---|---|---|
| Klipper | guest control stack (host) + MCU firmware (real board **and** simulavr rung) | 🟢 GPL-3.0 | `Klipper3d/klipper` @ dated master (head at fetch `8c29c0a8e205d897f765ce867b983e009cbe32a1`, 2026-09-08); v0.13.0 = `61c0c8d2…` is the only tag and is 17 months old | wheelhouse from `scripts/klippy-requirements.txt`; gcc in guest for chelper; build `klipper.elf`/`.dict` for atmega644p (+ Octopus/M8P) in the image; no updater | **required** — `dausume/klipper`, pin commit |
| Moonraker | guest API | 🟢 GPL-3.0 (`GPL-3.0-only`) | `Arksine/moonraker` @ v0.11.0 = `985c1d0bbeb90bc057d34a232c9dc3b05e0c6c8d` | wheelhouse from `scripts/moonraker-requirements.txt` + `system-dependencies.json`; **omit `[update_manager]`**; `[machine] provider: none`; `cors_domains` for Kiri:Moto | **required** — `dausume/moonraker` |
| Mainsail | guest UI | 🟢 GPL-3.0 (no package.json licence field / no headers — note in fork) | `mainsail-crew/mainsail` @ v2.19.0 = `5fb9e77fb9f4e60cf0725d9dc7f57cf7b84bbd70` | serve release `mainsail.zip` statically (nginx); no build | **required** — `dausume/mainsail` (source) + keep the zip as a release artefact |
| Fluidd | alternative UI (pinned, optional) | 🟢 GPL-3.0 | `fluidd-core/fluidd` @ v1.37.4 = `7dd4ea0794a992daf5e56a52d350cf6728b1d901` | `fluidd.zip` static | only if adopted |
| simulavr | simulation rung 4 (MCU on the wire) | 🟢 GPL-2.0-or-later (taken under v3); ⚠ dormant since 2020 | Savannah `simulavr.git` @ `32985f745c237bf8dcd2718235d01c8b1fb0491d` | cmake `BUILD_PYTHON` + swig in the build stage; needs desktop-class CPU | **required** — mirror to `dausume/simulavr` (Savannah is not GitHub; we need a stable fetch point) |
| virtual-klipper-printer | packaging pattern for rung 4 (rebuilt on our pins, corexy cfg) | 🟢 GPL-3.0 | `mainsail-crew/virtual-klipper-printer` @ `e272bcd1060dad6cee1598d6debdaa5d5afae3c7` | its Dockerfile clones unpinned masters → replace with our fork tarballs; pysimulavr wheel built in-stage | **required** — `dausume/virtual-klipper-printer` |
| Klipper batch mode / test_klippy | simulation rung 3 (kinematics, CI) | 🟢 (part of Klipper) | same Klipper pin | needs `klipper.dict` per MCU (built in image) | covered by Klipper fork |
| Klipper Linux-process MCU | simulation rung 1 (stack-up smoke test, cheapest) | 🟢 (part of Klipper) | same Klipper pin | `make` for MACH_LINUX in guest image; `kinematics: none` | covered |
| Kiri:Moto (grid-apps) | slicer **isle-app** (FDM now; CAM/laser later) | 🟢 MIT (🟡 note: "All Rights Reserved" headers deferring to license.md; vendored `src/ext` licences to enumerate) | `GridSpace/grid-apps` @ 4.7.3 = `ff7692241c48c3495da0bb8eb7455f906f3abb2d` | build image on build host (`npm i` at build only); runs offline on :8080; Moonraker export built in | **required** — `dausume/grid-apps` |
| OrcaSlicer / PrusaSlicer / SuperSlicer | desktop or headless-CLI slicer, **separate app only** | 🟢 AGPL-3.0 (combine via §13; source link in any network-fronting UI); SuperSlicer 🟡 stale | Orca v2.4.2 `8500fcdc…`; Prusa version_2.9.6 `b028299c…`; SuperSlicer 2.5.59.13 | not offline-relevant unless containerised (heavy) | only if adopted; never linked into Polari code |
| `waxprint` (ours) | simulation rung 5 (physics) | 🟢 GPLv3 (ours) | in-tree | — | n/a |
| Voron design repos | reference data: CAD/STL/manuals/**Klipper configs** | 🟢 GPL-3.0 | `Voron-2` @ V2.4r2 `45128487…`; `Voron-Trident` @ VTr2 `a8628f48…` | vendor only what a page needs (configs, part list we derive); BOM configurator output UNVERIFIED — link, don't scrape | **required for anything vendored** — `dausume/Voron-2`, `dausume/Voron-Trident` |
| OctoPrint (+virtual printer) | — | 🟢 AGPL-3.0 but **wrong stack** | — | — | not adopted |
| Marlin + MarlinSimUI | — | 🟢 GPL-3.0 / GPL-2.0-or-later but **wrong firmware** | — | — | not adopted |
| hudbrog/gCodeViewer | — | 🟡 CC-BY-4.0 (compatible, not a software licence, obsolete) | — | — | not adopted |
| NC Viewer | external reference link at most | 🔴 proprietary (Toolpath Labs, no source) | — | — | never embedded |

### What none of this simulates
No rung above models heat: thermistor readings never move on the
Linux-MCU rung (no ADC) or the simulavr rung (floating-pin constant),
so heaters never converge and `verify_heater` must be either fed by
our thermal shim or relaxed for the simulated plant. Nothing models
melt, extrusion pressure, bead shape, layer adhesion, cooling, warping
or part failure — that is `waxprint`'s job and must be labelled as our
model with its own calibration ladder. Nothing models mechanics:
simulavr counts steps but does not integrate a physical position, so
belt stretch, frame compliance, skipped steps, resonance (input shaper
needs an accelerometer) and probe/bed-mesh physics are all absent;
`kinematics: none` has no steppers at all. Nothing produces a camera
image (the dummy webcam loops stills). And nothing here validates a
real board: the simulavr rung is an atmega644p, not the Octopus/M8P
the Voron actually runs — the real-board firmware build is proven only
by compiling it.

## Sources
- Klipper: https://github.com/Klipper3d/klipper — COPYING, `klippy/klippy.py`, `src/sched.c`, `src/linux/main.c`, `src/linux/Kconfig`, `src/linux/gpio.c`, `src/avr/Kconfig`, `src/simulator/Kconfig`, `scripts/avrsim.py`, `scripts/test_klippy.py`, `scripts/klippy-requirements.txt`, `klippy/chelper/__init__.py`, `klippy/kinematics/none.py`, `klippy/kinematics/extruder.py`, `test/klippy/linuxtest.cfg`, `test/klippy/printers.test`, `docs/Debugging.md`, `docs/Config_Reference.md`, `docs/Releases.md`, `docs/RPi_microcontroller.md`; tags via https://api.github.com/repos/Klipper3d/klipper/tags
- Moonraker: https://github.com/Arksine/moonraker — LICENSE, `pyproject.toml`, `moonraker/server.py`, `components/update_manager/update_manager.py`, `scripts/` (moonraker-requirements.txt, system-dependencies.json, python_wheels/), `docs/installation.md`, `docs/configuration.md`
- Mainsail: https://github.com/mainsail-crew/mainsail — LICENSE, `package.json`, release v2.19.0 (mainsail.zip); `@sindarius/gcodeviewer` https://registry.npmjs.org/@sindarius%2Fgcodeviewer
- Fluidd: https://github.com/fluidd-core/fluidd — LICENSE, `package.json`, release v1.37.4 (fluidd.zip)
- simulavr: https://git.savannah.nongnu.org/git/simulavr.git (shallow clone: `doc/COPYING`, `libsim/*.cpp` headers, `CMakeLists.txt`); homepage https://www.nongnu.org/simulavr/ (HTTP 429 at fetch); project https://savannah.nongnu.org/projects/simulavr
- virtual-klipper-printer: https://github.com/mainsail-crew/virtual-klipper-printer — LICENSE, README, Dockerfile, `config/simulavr.config`, `config/supervisord.conf`, `example-configs/printer.cfg`, `example-configs/addons/*`
- Marlin: https://github.com/MarlinFirmware/Marlin — LICENSE, `Marlin/src/MarlinCore.cpp`, `ini/native.ini` (2.1.2.8 and bugfix-2.1.x); MarlinSimUI: https://github.com/p3p/MarlinSimUI — LICENSE, `src/MarlinSimulator/main.cpp`
- OctoPrint: https://github.com/OctoPrint/OctoPrint — LICENSE.txt, `src/octoprint/plugins/virtual_printer/__init__.py`; docs https://docs.octoprint.org/en/master/development/virtual_printer.html
- gCodeViewer: https://github.com/hudbrog/gCodeViewer — LICENSE; NC Viewer: https://ncviewer.com/
- Kiri:Moto: https://github.com/GridSpace/grid-apps — `license.md` (master and 4.7.3), `package.json`, `src/moto/license.js`, `src/kiri/app/export.js`, `src/kiri/app/init/sync.js`, `src/dock/Dockerfile`, `src/dock/compose.yml`, `docs/kiri-moto/integrations.md`; docs https://docs.grid.space/kiri-moto/; `@gridspace/app-server` https://registry.npmjs.org/@gridspace%2Fapp-server; forum offline threads https://forum.grid.space/t/how-to-run-kiri-moto-offline/910 , https://forum.grid.space/t/using-kiri-moto-offline-and-installing-as-an-app/736
- OrcaSlicer: https://github.com/OrcaSlicer/OrcaSlicer (301 from https://github.com/SoftFever/OrcaSlicer) — LICENSE.txt, README §License, release v2.4.2; PrusaSlicer: https://github.com/prusa3d/PrusaSlicer — LICENSE, `src/libslic3r/Layer.cpp` @ version_2.9.6; SuperSlicer: https://github.com/supermerill/SuperSlicer — LICENSE, releases
- Voron: https://github.com/VoronDesign/Voron-2 , https://github.com/VoronDesign/Voron-Trident , https://github.com/VoronDesign/Voron-0 , https://github.com/VoronDesign/Voron-Stealthburner , https://github.com/VoronDesign/VoronUsers , https://github.com/VoronDesign/Voron-Hardware (LICENSE.md), https://github.com/VoronDesign/Voron-Documentation — LICENSE files, READMEs, tag refs V2.4r2 / VTr2, `firmware/` and `Firmware/` listings
- Physics building blocks: PySPH https://github.com/pypr/pysph (LICENSE.txt); NIST https://github.com/usnistgov/openfoamEmbedded3DP (LICENSE); AdditiveFOAM https://github.com/ORNL/AdditiveFOAM (LICENSE); beamWeldFoam https://github.com/tomflint22/beamWeldFoam; PySPH bead-deposition paper https://mrforum.com/product/9781644903599-8/ ; efficient FFF heat-transfer paper https://arxiv.org/pdf/2305.03455 ; OpenFOAM viscoelastic FDM solver https://www.worldscientific.com/doi/abs/10.1142/S0219876218440024
- GPL/AGPL/CC compatibility: GPLv3 §13 and AGPLv3 §13 (https://www.gnu.org/licenses/gpl-3.0.html , https://www.gnu.org/licenses/agpl-3.0.html); FSF licence list on CC BY 4.0 and GPLv2-or-later (https://www.gnu.org/licenses/license-list.html)
