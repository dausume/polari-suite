# Hardware arc — hand-test guide (2026-10-04)

Branch under test: `dev` (merged 2026-10-04; dev-hw-test was the staging branch) in all five repos (= dev-pcb-0 tip + the isle-core topology branch + the
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
| 1 | https://prf.192.168.0.212.nip.io/display/boards | 12 tables: devices (UNO, Longan Nano, C3, SAMD21, Hazard3/iCE boards …), adapters with VID:PIDs, roads (UNO first step done), programmers, instances (empty until a detect --push), facts (cited UNO datasheet rows), bindings, SoCs, pins (the UNO's D0–D13/A0–A5 ↔ ATmega328P pin ↔ net ↔ connector pin ↔ C symbol), runtime profiles, views, conflicts |
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

## 5. The real UNO [bench + pol-core]

```
# 5.1 once: serial permission (the flash runs in the image AS YOUR USER with the port mapped in)
id -nG | grep -q dialout || sudo usermod -aG dialout $USER     # then log out and back in; re-check id -nG

# 5.2 plug the UNO R3 into pol-core (USB-B cable from the kit)
lsusb | grep -E '2341:0043|2341:0001|1a86:7523'                 # genuine R3 = 2341:0043; a CH340 clone = 1a86:7523
ls -l /dev/serial/by-id/ /dev/ttyACM* /dev/ttyUSB* 2>/dev/null
pol board detect                                               # "board present: arduino-uno-r3" (never guessed)
pol board detect --push --api $POLARI_API                      # the BoardInstance row
```
Browser: page 1 → instances shows the real board.

```
# 5.3 first flash: the blink variant (nothing wired)
pol board install uno --variant uno-blink-only                 # DRY-RUN: the docker run … --device /dev/ttyACM0 … avrdude argv
pol board install uno --variant uno-blink-only --yes           # flash + read-back verify; the on-board L LED blinks
pol board result

# 5.4 echo: the bridge attaches over the real serial port
pol board install uno --variant uno-echo --yes                 # frames print; a PUT {temp_c,pwm_duty,led_on} comes back status "echoed"
pol board result

# 5.5 the sim rig on the kit parts (power off while wiring):
#   TMP36 flat face toward you: left pin → 5V, middle → A0, right → GND
#   LED long leg → D6 through 220 Ω, short leg → GND (D13's L LED needs nothing)
pol board install uno --variant uno-sim-rig --yes
pol board result                                               # temp_c tracks a thumb on the TMP36; PUT led_on / pwm_duty → D13 lights, D6 dims; next frame status "commanded"
pol board interface <the instance id printed by detect --push>
```
Browser: page 2 → repeat 5.3 from the panel (pick → build → confirm → install); the record arrives over STOMP.

```
# 5.6 faults against silicon — NOT built yet (sc-5): run it and record what it does
pol faults run torn-millis-read --both                         # expected: runs on the twin as before; a silicon replay is the next slice
```

## What to send back
For each numbered step: the command's last lines, and for each page a screenshot or "ok". Anything that refuses
should come back with the refusal text verbatim — refusals name the knob/image/provider they wanted.
