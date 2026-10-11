# Hardware arc — hand-test guide (2026-10-04)

Branch under test: `dev` (merged 2026-10-04; dev-hw-test was the staging branch). The home stack is ALREADY rebuilt and deployed from dev (2026-10-04 afternoon) and the KiCad worker is in the isle-core stack — skip sections 1–2 unless you redeploy; pol-core's stack address is .210 (`pol suite urls`). in all five repos (= dev-pcb-0 tip + the isle-core topology branch + the
pol swarm handshake branch + the four engine knobs in the staging compose + the five module assignments on prf-a).
Device labels: **[pol-core]** = this desktop (swarm manager, the home stack, the browser); **[isle-core]** = the
engine host 192.168.0.24 (board/formal/esp/pcb workers); **[bench]** = the UNO on USB at pol-core.
pol-core's LAN address moves with DHCP (today 192.168.0.212) — `pol suite urls` prints the current one; every URL
below assumes .212.

## 0. One-time prep [pol-core]

```
cd ~/Desktop/polari-suite
git status --short                        # must be clean
git fetch --all --quiet
git checkout dev-hw-test
git -C polari-cli checkout dev-hw-test
git -C polari-rf-node checkout dev-hw-test
git -C polari-rf-node/polari-framework checkout dev-hw-test
git -C polari-rf-node/polari-platform-angular checkout dev-hw-test
git submodule status | grep -v '^ ' || echo "all pointers match"
pol swarm help | grep -E 'ports|leave|hw-engines'     # pol runs from this checkout — the new verbs must show
```

## 1. Bridge the two devices (the firewall handshake) [pol-core]

```
pol net needs swarm-manager
pol swarm ports isle-core                 # expect four CLOSED rows + the ufw lines
pol swarm ports isle-core --apply         # answer y; sudo asks your password = the handshake
docker node ls                            # isle-core (dustin-etts-mesh-core) must turn Ready within ~1 min
pol swarm join isle-core                  # only if it stays Down; idempotent
docker network inspect ingress --format '{{json .Peers}}'   # both machines listed = mesh formed
curl -s http://192.168.0.212:9830/capability | head -c 300  # the worker answers THROUGH the manager now
pol net handback                          # the journal: the four rules, each with its undo
```

Then put the KiCad worker into the stack (it runs ad hoc on isle-core today, same port):

```
ssh isle-core docker rm -f prf-pcb-engines
pol swarm deploy hw-engines
pol swarm ps hw-engines                   # four services Running on isle-core
for p in 9830 9840 9850 9860; do curl -s -o /dev/null -w "$p %{http_code}\n" http://192.168.0.212:$p/capability; done
```

## 2. Rebuild the home stack from the branch [pol-core]

```
pol topology push topologies/staging-a.topology.yml   # the isle-core engines + board/firmwarefaults/cmod/hwnocode/pcb on prf-a
pol topology modules-env prf-a                        # must list board, firmwarefaults, cmod, hwnocode, pcb (+ grpcbridge)
pol topology graph | grep -E 'engines|pcb'
pol node build --env staging                          # backend + frontend images (the Angular build is the slow part)
pol swarm deploy node                                 # re-renders the proxy for the CURRENT IP, rolls the services
docker service update --force --image prf-backend:staging  polari-node_backend     # swarm does not re-pull an unchanged tag
docker service update --force --image prf-frontend:staging polari-node_frontend
docker service logs -f polari-node_backend 2>&1 | grep -E 'module|boot|ready|Traceback' # wait for the boot to finish
pol suite urls
curl -k -s -o /dev/null -w '%{http_code}\n' https://api.prf.192.168.0.212.nip.io/api/health      # 200
curl -k -s https://api.prf.192.168.0.212.nip.io/api/board/engines | head -c 400                   # the ladder resolves isle-core
pol modules selftest board; pol modules selftest firmwarefaults; pol modules selftest cmod; pol modules selftest hwnocode; pol modules selftest pcb
```

## 3. Pages, one by one [browser on pol-core]

Log in at https://prf.192.168.0.212.nip.io as usual (the staging user from `pol security setup`). Each page is
also reachable by clicking: sidebar → Displays → Published Pages → the card → Open Page.

| # | URL | what must be there |
|---|-----|--------------------|
| 1 | https://prf.192.168.0.212.nip.io/display/boards | 13 tables, each with a "what this is for / one row = / columns" blurb above it. First two are the demo1 readiness split (derived, never hand-flagged, from GET /api/board/boards/readiness): "Usable now" (UNO, and the ESP32-C3 once its scenarios are seeded — twin + firmware template + a no-code solution or scenario) and "Tracked for later" (Longan Nano, SAMD21, Hazard3/iCE boards … — readiness_why names what each is missing). Then adapters with VID:PIDs, roads, programmers, instances (empty until a detect --push), facts (cited UNO datasheet rows), bindings, SoCs, pins (the UNO's D0–D13/A0–A5 ↔ ATmega328P pin ↔ net ↔ connector pin ↔ C symbol), runtime profiles, views, conflicts |
| 2 | https://prf.192.168.0.212.nip.io/display/firmware-installer | the installer panel (pick a variant → build → DRY-RUN argv → confirm → install, confirm disabled until a plan) + the six tables variants/builds/devices/programmers/plans/records; variants = uno-sim-rig, uno-blink-only, uno-adc-sweep, uno-pair, uno-echo |
| 3 | https://prf.192.168.0.212.nip.io/display/firmware-faults | scenarios (torn-millis-read, lost-ack-hang, button-bounce-double-count, uart-residual-frame-loss, brownout-mid-eeprom-write, runaway-hang-watchdog, priority-inversion-mutex, two-lock-deadlock, …), runs, trace, claims, techniques, stats, campaigns, likelihoods, formal (CBMC + Mthread verdicts), static (cppcheck), one table per fault kind |
| 4 | https://prf.192.168.0.212.nip.io/display/c-atoms | projects (uno), 34 atoms with ports/resources/ISR-safety/cost, modules, the graph uno-sim-rig-graph with its nodes/edges, glue builds |
| 5 | https://prf.192.168.0.212.nip.io/display/hardware-solutions | solution uno-temp-split, the temperature chart panel, derived rows, the placement report (board / twin / bridge / backend / browser per node) |
| 6 | https://prf.192.168.0.212.nip.io/display/board-schematic | schematics + sheets + symbols for the ingested ecc83 board (after step 5.8 also uno-shield), ERC rows |
| 7 | https://prf.192.168.0.212.nip.io/display/board-layout | the ecc83 PcbBoard (2 layers, 13 nets), placements, routes, the per-layer SVG links (they must open) |
| 8 | https://prf.192.168.0.212.nip.io/display/board-bom | 11 parts, footprints, land patterns |
| 9 | https://prf.192.168.0.212.nip.io/display/board-fab | the DKRed rule set with its cited rules, DRC rows (2 silk warnings + 1 parity warning), the 34 export files with the naming verdicts |

Pages 6–9 fill when step 5.8 posts the ingest to the server (`--api`); before that they show the seeded rule rows only.
Also open the no-code canvas you normally use: the palette now carries `c-atom` and `hw-interface` nodes (hn-0);
drop one and open its overlay.

demo1 (2026-10-04): every page now carries a description of what it is for, what writes its data, and which
other pages it goes with; every table carries "what this is for / one row = ... / columns: ..." above it,
written from the backing class's own docstring — no table is a wall of columns with no explanation. Still
owed from this slice (not built): the per-layer SVGs rendered inline on board-layout, the schematic rendered
inline on board-schematic, and the UNO pin-map SVG on /display/boards — all three need a new generic SVG/image
panel plus (for the schematic) a worker-side `sch export svg` addition; scoped out of this pass for time.

## 4. The simulated UNO [pol-core — the twin runs here in the local prf-board-engines image; set NO BOARD_ENGINES_URL]

```
cd ~/Desktop/polari-suite
export POLARI_API=https://api.prf.192.168.0.212.nip.io
export FORMAL_ENGINES_URL=http://192.168.0.212:9840 ESP_ENGINES_URL=http://192.168.0.212:9850 PCB_ENGINES_URL=http://192.168.0.212:9860
unset BOARD_ENGINES_URL                    # a URL knob always wins and a twin refuses a remote rung

# 4.1 the register, no server needed
pol board list
pol board roads
pol board facts arduino-uno-r3
pol board engines                          # avr-gcc/avrdude/simavr → "the local image prf-board-engines:trixie"
pol board pins arduino-uno-r3
pol board render arduino-uno-r3 --as bare-c --out /tmp/uno-view && ls /tmp/uno-view
pol board render arduino-uno-r3 --as zephyr                      # REFUSED with why (no AVR arch in Zephyr)

# 4.2 gen → build → twin → bridge frames
pol board gen uno                          # uno-sim-rig around the live header from $POLARI_API
pol board build uno                        # .hex sha256, sizes, the repro block
pol board flash uno                        # DRY-RUN: the avrdude argv (no board yet)
pol board twin uno up --adc0-mv 750
pol board twin uno status
pol board install uno --variant uno-echo --twin            # DRY-RUN plan
pol board install uno --variant uno-echo --twin --yes      # installs into the twin, attaches the bridge, prints frames
pol board result
pol board interface twin:arduino-uno-r3#1
```
Browser: page 2 now lists the plan + record; page 1 → instances shows the twin instance.

```
# 4.3 faults: force, measure, prove
pol faults list
pol faults run torn-millis-read --both     # BEFORE (torn) fails with the cycle it fired at; AFTER (ATOMIC_BLOCK) passes; the cost of the technique
pol faults show <run id from the line above>
pol faults run lost-ack-hang --both
pol faults run button-bounce-double-count --both
pol faults run uart-residual-frame-loss --both
pol faults campaign list
pol faults campaign run <one from the list> --seeds 5
pol faults formal run all                  # CBMC + Mthread on isle-core — decided/refuted/inapplicable per check
pol faults static run all
```
Browser: page 3 → runs, claims, formal, campaigns fill in.

```
# 4.4 C modularization
pol cmod atoms uno
pol cmod conform uno                       # polari-firmware.json; run twice — the second must say unchanged
pol cmod show hal_millis --project uno
pol cmod graphs
pol cmod cost uno-sim-rig-graph
pol cmod render uno-sim-rig-graph
pol cmod build uno-sim-rig-graph
pol cmod prove uno-sim-rig-graph           # rendered glue vs the hand-written app on the twin: frames identical

# 4.5 hardware no-code
pol hwnocode solutions
pol hwnocode place uno-temp-split
pol hwnocode suggest uno-temp-split        # bare C / FreeRTOS / ESP-IDF / Zephyr with evidence; nothing changes
pol hwnocode runtime uno-temp-split zephyr # refused with why; bare-c accepted
pol hwnocode render uno-temp-split
pol hwnocode build uno-temp-split
pol board twin uno down
pol board twin uno up --work ~/.cache/polari-hwnocode/uno-temp-split
pol board twin uno status
```
Browser: page 5 → the chart moves while that twin runs.

```
# 4.6 the C3 (QEMU twin; the worker on isle-core builds it) — no board needed
pol board gen c3
pol board build c3
pol board twin c3 up
pol board twin c3 status                   # UART1 = the FreeRTOS trace tail
pol faults stats priority-inversion-mutex --seeds 5
pol faults stats two-lock-deadlock --seeds 5
pol board twin c3 down

# 4.7 PCB (KiCad on isle-core)
pol pcb engines
pol pcb render-schematic uno-shield --out /tmp/uno-shield.kicad_sch        # ERC: 38 violations LISTED (26 header pins unconnected by design)
pol pcb render-schematic uno-shield --api $POLARI_API                      # the same, as rows
pol pcb ingest polari-rf-node/polari-framework/modules/pcb/custom/upstream/kicad-demos-9.0.2/ecc83 --api $POLARI_API
```
Browser: pages 6–9 fill (ERC 0, DRC 2+1 warnings, 34 exports, the layer SVGs open).

```
# 4.8 the probes (the same proofs the slices ran), from the framework dir
cd polari-rf-node/polari-framework
PYTHONPATH=.:modules python3 tests/board_liveboot_probe.py
PYTHONPATH=.:modules python3 tests/board_uno_twin_probe.py --seconds 5
PYTHONPATH=.:modules python3 tests/board_installer_probe.py
PYTHONPATH=.:modules python3 tests/firmwarefaults_probe.py
PYTHONPATH=.:modules python3 tests/cmod_liveboot_probe.py --engines
PYTHONPATH=.:modules python3 tests/hwnocode_probe.py
PYTHONPATH=.:modules python3 tests/pcb_probe.py
cd -
pol board twin uno down
```

## 5. The real UNO — the light test, through the Hardware Bridge App [bench + pol-core] (ucd-3, 2026-10-11)

The firmware is `uno-light`: one light on D6 (220 Ω to GND), the kit pushbutton on D2 (to GND; the input is pulled up). Two
Purposes must end `proven-on-hardware`: `light-from-polari` (the screen switches the light) and `light-from-button` (the button
switches it and the screen learns of it). The ONLY flash path is the Hardware Bridge App — never `flash.py`.

```
# 5.1 once, with sudo: serial permission + the two debs (avrdude and a JRE come in as dependencies)
id -nG | grep -q dialout || sudo usermod -aG dialout $USER     # then log out and back in; re-check id -nG
cd ~/Desktop/polari-suite/polari-app-shell/dist
sudo apt-get install -y ./polari-shell-core_0.1.0_amd64.deb ./polari-app-uno-core-demo_0.1.0_all.deb
```
(The same two files are on the demo page's Downloads table: https://prf.<pol-core ip>.nip.io/display/uno-core-demo.)

```
# 5.2 wire, power off: LED long leg → D6 through 220 Ω, short leg → GND; pushbutton: one leg → D2, the other → GND.
#     Then plug the UNO R3 into pol-core (USB-B). Genuine R3 = 2341:0043; a clone shows 2341:0001 / 2a03:0043.
lsusb | grep -E '2341:0043|2341:0001|2a03:0043'
```

```
# 5.3 the app — "Uno Core Demo" in the launcher (or: polari-shell --config /usr/share/polari-app-uno-core-demo/polari-shell.json)
#   1 Open bundle  → "Fetch from Polari" (the newest demo bundle: firmware.hex + the bridge jar + the app definition)
#   2 Gate         → the hex's sha256 must equal the bundle's manifest; a mismatch REFUSES, anything else is advice
#   3 Detect board → the UNO by VID:PID (the two CP2102 boards on pol-core are refused by name)
#   4 Flash        → the dialog prints the exact avrdude argv; confirm; read-back verify is avrdude's own
#   5 Host bridge  → bridge.properties gets the port; the jar starts as a child; its log tails on screen
#   6 Light        → "Toggle light" PUTs led_on on the Polari row; the board follows within a frame
```
Browser: /display/uno-core-demo — the LightState row: led_on, toggles, source (command | button), seq, boot_session.

```
# 5.4 prove both directions on the real board — a person's confirmation is the record (ScenarioRun kind attested)
export POLARI_API=https://api.prf.<pol-core ip>.nip.io
#   down: press "Toggle light" twice (on, off) — the LED follows, the row shows source=command
pol capability attest light-from-polari --mode hardware --observed 'LED on D6 followed Toggle light on/off; row source=command'
#   up:   press the pushbutton twice — the LED flips each time, the row shows toggles +2 and source=button
pol capability attest light-from-button --mode hardware --observed 'two presses flipped the LED; row toggles +2, source=button'
pol capability list                                            # both: proven-on-hardware (attested by a person)
```
Browser: /display/uno-core-demo-readiness — the two Purposes read proven-on-hardware; the bridge part reads ok while the bridge runs.
Record every refusal verbatim (the app's sentences, avrdude's output, the bridge log): this is the first time any of it meets silicon.

```
# 5.5 faults against silicon — NOT built yet (sc-5): run it and record what it does
pol faults run torn-millis-read --both                         # expected: runs on the twin as before; a silicon replay is the next slice
```

## What to send back
For each numbered step: the command's last lines, and for each page a screenshot or "ok". Anything that refuses
should come back with the refusal text verbatim — refusals name the knob/image/provider they wanted.
