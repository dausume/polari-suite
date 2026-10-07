# Handoff — the board + firmware-fault arcs (brd, sc), state on 2026-10-02

_Written while he was at work ("work autonomously on this"). Everything below is on PHASE BRANCHES, pushed, NOT
merged; nothing touched dev/main, the droplet, or the running stacks. His merge word is owed for the whole stack._

## MERGED TO DEV 2026-10-04

His merge word landed. `dev-hw-test` is merged into `dev` in all five repos, innermost-first (framework, angular →
rf-node → cli → suite), by plain `git merge --no-ff` + plain `git push origin dev` (no force anywhere). `dev-hw-test`
is now == dev content — everything below in this handoff describes work that is on `dev`, not a staging branch. New
`dev` tips:

| repo | new dev tip |
|---|---|
| polari-framework | a61fc510fdb9b662b61919ff3de802b8d19e95f0 |
| polari-platform-angular | ea13f2cf1f0221d9d35f71345ed07205ef651751 |
| polari-rf-node | ed5fa4ce4ef40daf4a6dddeb4422d014de376546 |
| polari-cli | 74064583ddf63dd902af38936bd8626f1d06a574 |
| polari-suite | 4612003236325ca39ad0b29bde17fa71e4e0b8a0 |

The test guide `AI-Notes/guides/HARDWARE_ARC_TEST_GUIDE.md` keeps working — its branch line now says `dev`.

## The branch stack (innermost-first; each builds on the previous)

| phase | branch | framework | rf-node | cli | suite | angular |
|---|---|---|---|---|---|---|
| brd-0 board module + register rows + detect + c_twin AVR | `dev-brd-0` | 9a33888 | 24de932 | ed50341 | b4cb88a | — |
| brd-1 plain-C UNO firmware, worker image, simavr twin | `dev-brd-1` | f24d4c9 | 8905f99 | eecbc90 | 1d811ae | — |
| brd-fi Firmware Installer App (variants, compat, page) | `dev-brd-fi` | efdbc13 | 102fa55 | a13cbf2 | fb2845d | e38a41f |
| brd-wire computer↔firmware mapping (index, enums, presence) | `dev-brd-wire` | 1c003dc | d47bc19 | 411a81d | 21483b1 | — |
| sc-0 firmwarefaults module + scenario 1 proven | `dev-sc-0` | b7f8ae5 | 9c6bd0a | a6beac0 | 3762123 | — |
| sc-1 five scenarios (S2–S6) + watchdog + statistics | `dev-sc-1` | 82f9e30 | a8980bc | 4333a48 | db76fe5 | — |
| sc-4 the scenario pairs as an ADVISORY stage in polari-test (suite polari-jenkins only) | `dev-sc-4` | — | — | — | 78b4be7 | — |
| sc-2 + 2b campaigns (rates → likelihood), CBMC/cppcheck engines, owed flags, the worker output fix, `tests/scenarios_stage.py` | `dev-sc-2` | 0d00445 | 0638ea7 | 84a68d7 | 03516e2 (carries sc-4) | — |
| sc-2c Frama-C Mthread in the formal engines (unbounded race verdicts; image +185 MB) | `dev-sc-2c` (from sc-2) | fcc7fee | 82b2f20 | 1ac0681 | ce97238 | — |
| cmod-0 C modularization: `cmod` module, pycparser atoms, `polari-firmware.json` conform over the UNO firmware (34 atoms; .hex byte-identical; make alone builds) | `dev-cmod-0` (from sc-2) | 3af175c | e0c0142 | 500c9a5 | dbdb3b9 | — |
| sc-3 the RTOS scenarios on the ESP32-C3 (Espressif QEMU twin, ESP-IDF 5.5.5 worker 1.8 GB): priority inversion 12.2 ms → 2.1 ms with a mutex; two-lock deadlock at tick 370 → lock ordering / back-off; campaigns 40 %→0, 70 %→0 | `dev-sc-3` (from sc-2) | 0d4b4d1 | 821fa05 | 795de58 | 3dde68a | — |
| cmod-1 one no-code graph → generated plain-C glue; rendered .hex BYTE-IDENTICAL to the hand-written sim-rig; 40 twin frames identical on every field; a negative control catches changes | `dev-cmod-1` (from cmod-0) | a311580 | 4f22a06 | 554ff96 | 764a1c7 (its plan edit b5c6dbf is cherry-picked onto dev — merge the branch without that file conflicting) | — |

Merge order when he says so: fast-forward to `dev-hw-integration`, then merge `dev-hn-0` → `dev-brd-bo` → `dev-pcb-0`
(framework 3794756 / rf-node 370ac76 / cli e6a0942 / suite 3aa61ab; each stacks on the previous), then the device-binding
branches: suite `dev-topology-isle-engines` (e215759; rf-node 918e5b9) and polari-cli `dev-swarm-hw-engines` (f047b92) →
`dev-swarm-fw-handshake` (beba330), both off dev — independent of the hardware stack (plan files are small add/add conflicts, take dev's + the branch's section; plan files are small add/add conflicts, take dev's + the branch's section). Older detail: brd-0 → brd-1 → brd-fi → brd-wire → sc-0 → sc-1 → sc-2 (carries sc-4) → then the three
siblings off sc-2: sc-2c, cmod-0 (+ cmod-1 after it), sc-3 (cmod-0 independent; sc-2c and sc-3 both APPENDED to firmwarefaults_selftest main(),
polari-app.json, README/COST, the probe, faults.sh and the plan's status line → expect small textual conflicts there;
rehearse the merge first as before) + framework
`dev-hwmap-fixture`. Plans on dev: BOARD_PROGRAMMING, FIRMWARE_SCENARIO, C_MODULARIZATION.

⚠ 2026-10-02 incident: an agent pushed suite `dev` from a stale worktree and dropped nine docs commits; recovered the
same hour by rebuilding dev from the last good tip + its two commits (`--force-with-lease`), nothing lost. Rule now: agents
never push `dev`; only Fable does, and from a worktree based on `origin/dev` fetched that minute. The first real pipeline run of the
scenarios stage happens on econ-core after that merge; sc-4 found the engines worker truncating tool output (scenario 1
red through the worker) — fixed on dev-sc-2.

## Plans and designs (on dev)
`AI-Notes/plans/BOARD_PROGRAMMING_PLAN.md` (rules, D-brd-1..7 all ruled, §7a the installer app, §8a track all /
simulate few), `AI-Notes/plans/FIRMWARE_SCENARIO_PLAN.md` (fault objects, module, open tools, scenario 1 corrected),
`AI-Notes/designs/HARDWARE_CAPABILITY_REGISTER.md` (devices, adapters, cores, organisations, capability matrix),
`AI-Notes/plans/GRPC_BRIDGE_PLAN.md` §grpc-j4 (the wire mapping).

## What is proven (all on the simavr twin — no UNO was attached)
- UNO firmware in plain C: 4338 B / 491 B; the twin at 10 Hz; a PUT reaching the firmware through the generated Java
  bridge; four variants installable through the installer flow; compat by header sha + field order (the order-blind
  contract hash case refused).
- Two and three twins on one bridge routed by a 1- and 2-bit index; single instance = no index machinery at all;
  presence mask → a row returns to false/0.
- Scenario 1 (torn millis read): forced IRQ at PC 0x01be → 511 for 255 → REFUTED; with ATOMIC_BLOCK → WITNESSED;
  cost +6 B, +3 cycles, +14 cycles worst ISR latency; natural tear rate 3.12 % per carry over 60 seeds, 0 after.
- sc-2: campaigns with intervals for all five (the debounce's limit measured at 20 ms; lost-ack hangs 47.5 % at p 0.5 →
  0); CBMC as an engine (409 MB image): the atomic read decided-bounded, the non-atomic one REFUTED with a trace, the
  64-slot ring bounded k=4; cppcheck finds style only — it does not catch the torn read, CBMC does. The engines
  worker's output truncation is fixed (it had made scenario 1 red through the worker).
- sc-1: lost ack → hang vs timeout state machine; INT0 bounce → double count vs debounce; UART bit errors → the
  parser's residual loss (0.23 % at BER 1e-3) vs the keep-tail parser (0); reset mid-EEPROM-write → half record vs
  write-then-commit; a hang vs the watchdog. Every technique's cost in bytes, RAM and cycles is on the rows. The RTOS
  scenarios (priority inversion, two-lock deadlock) wait for the ESP32-C3 or SAMD21.

## Merge rehearsal (2026-10-02, throwaway worktrees, nothing pushed)
Every repo's `dev` is a strict ancestor of its branch tip → `git merge --no-ff origin/dev-sc-2` (angular: dev-brd-fi) is
conflict-free in all five repos. On the merged result every suite is green: framework conventions 41/61/8, conform
68/68, board 128, firmwarefaults 141, c_twin 44 + wire 21 + contracts 34 + javabridge 25, mathproofs 83, computelod
157, tensormath 68, all drift guards, board live boot 43/43, firmwarefaults probe 55/55 with REAL simavr + CBMC (zero
skips); cli prod-forge 112; suite jenkins 1105/1105, forge 218; angular dev build clean. ONE pre-existing failure,
unrelated to the stack: `hwmap_selftest` needs `modules/hwmap/custom/fixture_pol_core.json`, never committed (blanket
`*.json` ignore) — FIXED on framework branch `dev-hwmap-fixture` (fe5b87a, from dev): the file never existed anywhere — a synthetic fixture
with placeholders only (no real identifiers; grepped against the denylist), a `.gitignore` exemption, and the selftest
skips with a named reason when absent (15/15 with it, 7/7 without). Merge it with the stack.
Harness note: several selftests resolve sibling paths relatively, so rehearsal worktrees must mirror the submodule nesting.

## Frama-C evaluated (`AI-Notes/evaluations/FRAMA_C_EVALUATION.md`)
Mthread is the only piece worth adopting (reports the exact race, recognises the protected build, UNBOUNDED); EVA and WP
cannot settle these properties; Alt-Ergo's current build is non-commercial → excluded. A small bridge (cli/sei → Mthread
mutex calls) is owed before scenario 1 can be restated as a race query. Not built.

## ✅ THE INTEGRATION BRANCH (2026-10-03) — one merge word, nothing left to resolve
`dev-hw-integration` in all five repos = dev + the whole stack, conflicts resolved, gitlinks set, every suite green on
the merged tree (board 163, firmwarefaults 190, cmod 100, probes with real simavr + CBMC + Mthread + the C3 QEMU twin
77/77, jenkins 1105/1105, forge 218, angular build clean):

| repo | dev-hw-integration |
|---|---|
| polari-framework | a9885f8 |
| polari-platform-angular | 1deb1da |
| polari-rf-node | 3cc2254 |
| polari-cli | 75d923f |
| polari-suite | 965959b |

To merge: fast-forward each repo's `dev` to that tip, innermost-first (framework, angular → rf-node → cli → suite), e.g.
`git checkout dev && git merge --ff-only origin/dev-hw-integration && git push origin dev` in each; then
`pol jenkins promote test` from econ-core for the pipeline's own verdict (expect the new advisory scenarios stage to
run for the first time there).

## Hardware no-code plan (2026-10-03, dev 5f308e4)
`AI-Notes/plans/HARDWARE_NOCODE_PLAN.md`: one no-code model across frontend, backend and hardware on the existing
canvas; a §1a survey of 24 prior items; the C / FreeRTOS / Zephyr suggestion engine with measured evidence; ten
hardware variants as scenarios; D-hn-1..6 his; slices hn-0..5. D-hn-1..6 ruled 2026-10-03. ✅ hn-0 BUILT on `dev-hn-0` (from dev-hw-integration: framework 17b99ef / angular d563892 /
rf-node c7cd269 / cli 13de99c / suite d06100f): the `hwnocode` module, the two node kinds on the ONE canvas with a
data-driven palette, the split app over the UNO peripheral proven on the twin (glue byte-identical, backend node at
10 Hz on tmpfs, chart with both series, PUT echo 0.15 s), suggestion = bare C with evidence. 🔑 Finding: on this disk
sqlite commits cost 10.8 ms and the engine saves ~14 rows per frame synchronously inside the gRPC push path → 2.65 Hz;
a shared-engine change (batched/async saves) is owed before 10 Hz solutions run on real disks. Merge note: the plan
file is an add/add on dev (take dev's + hn-0's §7 edits).

## Two more plans on dev (2026-10-03, a1fa198)
`DESIGN_LEVEL_VIEWS_PLAN.md` (a page per level, one level-view component, ties, the zoom composed last; dlv-0 must fix
ingestion: `polari_block` is never stamped and lod1 strips attributes) and `PCB_FROM_SCRATCH_PLAN.md` (KiCad as the
engine, design as rows, DKRed constraints cited, the UNO shield first). Decisions D-dlv-1..5 and D-pcb-1..6 are his.
Also his rule today: develop ACROSS devices — the engine workers are moving to isle-core (see memory
develop-across-devices); isle-core's outage was a power cut, not the OS (memory other-machines-ssh).

## brd-bo — THE BOARD OBJECT (2026-10-03, `dev-brd-bo` from dev-hn-0: framework c2d8451 / rf-node 1637522 / cli bd5ec58 / suite b628529)
One board definition shared by KiCad, Zephyr, ESP-IDF, bare C and Polari, built around `BoardPin`; seeds cited
(ATmega328P datasheet, Arduino's UNO pinout, Zephyr v4.4.2's C3 board dir ingested with its licence); four proofs on
isle-core's workers: UNO builds byte-identical with pins now coming from rows; the C3 overlay round-trips and its image is
byte-identical; a conflicting ingest leaves the rows alone; one pin moved changes every view together. `pol board
render|ingest|pins|conflicts|assign`. Engines now run on isle-core (topology rows + swarm join in progress).

## Engines on isle-core, bound by topology + swarm (2026-10-03)
isle-core joined pol-core's swarm as a worker (`pol swarm join isle-core`); the three engine workers (board 9830,
formal 9840, esp 9850) run as stack `polari-hw-engines` pinned to it (`polari-rf-node/docker-compose.hw-engines.yml`
on `dev-topology-isle-engines`); the home topology carries the three instances + assignments (`board.engines`,
`board.esp-engines`, `firmwarefaults.formal`) on suite `dev-topology-isle-engines` and in the live core, so the engines
ladder resolves them with no env knobs. GAP: pol-core's ufw blocks isle-core on 2377/7946/4789 → the routing mesh never
formed, so the topology-built URLs (manager address) refuse while isle-core's own address answers. The twins still need
a local process (owed: a remote twin verb). ✅ polari-cli `dev-swarm-hw-engines` (f047b92): `pol swarm deploy hw-engines`,
`pol swarm ports [<node>]`, mesh report in `join`, swarm-selftest 34/34 (swarm.sh had none). ✅ `dev-swarm-fw-handshake`
(beba330, his ruling "account for this as an inherent need to bridge devices"): `pol net needs <binding>`, consent
handshake in `join`/`ports --apply` (source-scoped `ufw allow from <peer>` through sudo; never in CI/non-TTY; idempotent;
firewalld = print only), hand-back journal `~/.polari/handback/firewall.jsonl` replayed by `pol net handback --apply` /
`pol swarm leave`; selftest 91/91. OWED: only node→manager is probed, so only manager-side rules auto-apply.

## pcb-0 — KiCad as the engine (2026-10-03, `dev-pcb-0` from dev-brd-bo: framework 3794756 / rf-node 370ac76 / cli e6a0942 / suite 3aa61ab)
Worker `prf-pcb-engines` (Debian trixie + kicad 9 + symbols/footprints, 1.23 GB, :9860 ON ISLE-CORE, no display needed;
kicad-cli verbs 0.2–0.8 s / 109–236 MB RSS; a whole-board ingest 7.9 s). Module `pcb` (13 row classes, requires board;
knob `PCB_ENGINES_URL` + the topology rung). Ingested KiCad's own `ecc83-pp` demo (GPL-2.0-or-later via kicad-demos
9.0.2 — chosen over the RP2040 Minimal design whose licence rests on a forum post): 11 parts / 8 symbols / 6 footprints /
2 layers / 13 nets / 15 placements; ERC 0 violations; DRC 2 silk-edge warnings + 1 footprint/symbol parity warning; DKRed
rule rows all pass; 34 export files byte-stable across two ingests (6 names match DKRed's table, 11 don't, 3 differ between
his screenshot and the page text). UNO shield `.kicad_sch` written directly from brd-bo rows: ERC exit 0 with 38 violations
listed (26 unconnected header pins by design). Pages board-schematic/-layout/-bom/-fab = class-rows-table with artifact
links. `pol pcb ingest|render-schematic|…`. Tests pcb_selftest 35/35, pcb_probe 30/30 (real engine), board 198/198
unchanged. Pre-existing unrelated: `resources.profiles_selftest` has one failure. Build time of the image unknown (the
first agent was killed mid-slice by an API error; a second finished it on the same worktrees).

## CLOSE OF 2026-10-04 — state + the scoped TODO (his: "save what we went through as a plan and as a to do … not too much scope drift")
**2026-10-05 03:00 — his design direction + fwsol-0 (dev: suite 283ee39 · rf-node 68f8939 · framework 26537a7 · angular ae893ae):** "twin" → `uno-digital-twin`; per-state purposes on the page; connectors fixed (the renderer needs connector.id/slots — the seed lacked them); `HWNOCODE_HARDWARE_MODE` = digital-twin | hardware read in one place and reported. PROPOSAL awaiting his go: DEMONSTRABLES_PLAN §9 — **Firmware Solution** (tasks = atoms, schedule lane, register map on the pin map; BoardDefinition in → FirmwareBuild out, flash or digital twin) + **Cross-Domain Solution** (bridging/relay states only: Firmware Run with the mode knob, Bridge, Relay, API call, Frontend emit); migrate uno-temp-split into uno-sim-rig (firmware) + uno-temp-split (cross-domain) + temp-analysis (backend); slices fs-0..3; **D-fs-1** schedule lane derived from ISR/tick annotations or authored; **D-fs-2** register assignment on the pin map or a table; **D-fs-3** may a Cross-Domain solution contain any compute. ✅ HIS GO 2026-10-05 03:40 ("go with your picks"): D-fs-1 derived, D-fs-2 drag on the pin map, D-fs-3 bridging-only. ✅ fs-0 MERGED 04:30 (dev: suite e3bcb68 · rf-node 476707e · framework 6f0d7f1 · cli 4b2eb9c): FirmwareSolution/ScheduleSlot/RegisterAssignment + FirmwareRunState (Cross-Domain category) + derivations/validation + `/api/firmware` + `pol firmware` + /display/firmware-solutions; `uno-sim-rig` seeded (derived schedule: 3 ISRs, 5 init, loop, tick; A0/D6/D13/D0/D1 bound; temp_c exposed); cmod 133/133. ✅ fs-1 MERGED 2026-10-05 07:00 (dev: suite 635a6f9 · rf-node 0e3fe11 · framework 623685e · angular 89bc784 · cli 4b2eb9c): migration (uno-temp-split = 5 cross-domain states → uno-sim-rig; temp-analysis backend solution; identical frames proven), `firmware-solution-panel` first on /display/firmware-solutions (task list · derived lanes · pin map with bound pins), the drag → `/assign`, links both ways, installer table with `run_command`. ✅ P1 + fs-2c MERGED 2026-10-06 late (dev: suite b43e6f0 · rf-node 0509c91 · framework 64c4e1a · angular 2d33f3a · cli 12f4b24): CapabilityDefinition widened (goal, tasks by runtime, acceptance Scenario kind, DERIVED status, validator), seeds temp-sensor-to-os + blink-on-command, `/api/capabilities`, Capabilities tables; the firmware panel's ruled UX (Tasks = all tasks grouped by Capability; one selection model; symmetric highlighting; selection-then-confirm Register/Unregister; ranked Target details; toggle + Escape); `pol capability`; faults_cli persists acceptance runs before printing. ✅ LIVE 2026-10-07 (dev d0019c7, framework 3b0e6c8): `temp-sensor-to-os` reads proven-on-twin on the stack (proof run on pol-core with the local twin image, pushed through the new `POST /api/capabilities/<n>/runs`; the server's prove door 409s when its engines cannot run a twin). LEFT: HIS browser pass of /display/firmware-solutions (the ruled UX), then **P2 = the UNO on the bench** (guide §4; the stopgap flash path) — the first time anything meets silicon; then the samples backlog from the kit-parts register (fs-2d: "parts without a sample yet") and **cmod-2** (author an atom's body in no-code — C_MODULARIZATION_PLAN cmod-2, D-cmod-6/7 his). DEBT: `modules/cmod/custom/glue_builds/uno-sim-rig-graph.json` is a tracked record that a proof mutates (proven_at) — move run timestamps to module_home.
✅ fs-2 MERGED 2026-10-06 (dev: suite a9bd155 · rf-node 13473f7 · framework 7aa110a · angular 263b3c6): cited compatibility table (15 rules, board module), pin detail + valid-targets doors (adc → A0–A5, pwm → D3 D5 D6 D9 D10 D11, D13 refused "no Output Compare function"), `/assign` refuses with the reason; the panel = four collapsible sections + presets, Unregistered/Registered Tasks, green/grey/amber targets from the door, Target details with the register view, keyboard. HIS: the browser pass of /display/firmware-solutions. **PLANNED, NOT BUILT (his ask 2026-10-06, his go required for exp-0): the export arc `AI-Notes/plans/FIRMWARE_EXPORT_PLAN.md` (dev f25e217; one flash path through the shell app, flash.py's docker route = stopgap DEBT; CONNECTED mode isle-only, OFFLINE everywhere — home swarm = offline until it is an isle; connected mode's first proof = isle-core) — exp-0 firmware export dir + rebuild-verify lib; exp-1 bridge deb lib; exp-2 the **Polari Firmware Installer** (ONE new JavaFX app on polari-app-shell — D-exp-3 RULED; offline + connected modes; it IS the hardware bridge on a host: the only process touching USB/serial, hosting the generated gRPC bridge; the backend never opens a USB port in production); §2b `BridgingCapability` per shell app with a proven_by self-test; RULE: Java's configurable surface = bridging only (validator); exp-3 forms; exp-4 UI. D-exp-1/2/4/5 as recommended unless he rules otherwise. The flash gate (no flash without a reviewed, independently rebuilt export) is the point.** **TODO item 1 now:** the live validate→build→run door inside the installer panel (should go THROUGH the export gate once exp-0 exists); (the conflict guard now asks the valid-targets door, so cooperation is honoured — closed); a boot-time budget pass (backend boot grew 6.5 → 11 min with the new modules) AND a frontend-only roll path (`pol swarm deploy node` re-renders the stack and bounces the backend even when only the frontend image changed → ~11 min downtime per frontend roll; use `docker service update` alone when the rendered stack is unchanged); then demo-2 (the live board sim-space on the pin map).
**2026-10-05 02:00 — the no-code regression and its fixes (selfix 1–3):** his report "I do not see anything and even the other solutions that were previously working are broken now" → the canvas panel poisoned the shared solution state (a synthesized solution saved to the backend + the user's remembered selection written from a display page; a dotless solution name blanked the object; seeded states lacked the fields the renderer reads). Fixed on dev (angular b0669b5 / framework 19877f2 / rf-node 8b3824a / suite 4a9f7f3) and VERIFIED in the browser: main canvas healthy after visiting the hardware pages, hardware-solutions opens uno-temp-split by itself with its 8 states drawn, ONE Runtime select with the 6 runtimes. Leftovers → TODO 3: visible lane bands/colours; uno-temp-split → Object.solution rename (lockstep with bridge/twin config); c-canvas visual check; the embedded canvas needs a scroll on short viewports. Ledger C14.
**dev tips (2026-10-04 ~21:00):** suite 9b4885e · rf-node 984a2c3 · framework e7f1d96 · angular 9518443 · cli 46b8c11 (adds rtfix: Runtime registered + the defClassList gap guard). Before that: suite 4016c0d · rf-node b9abbea · framework 17cd2da — adds loopfix (the c-canvas reload storm; the ecc83 title block) and demo-4b (RUNTIMES as rows — his ruling: "these should be their own runtimes" — lanes + legend + crossing list in the canvas, the C atoms as REAL nodes on /display/c-canvas, uno-temp-split first on /display/hardware-solutions). Earlier: suite e286130 · rf-node 88238e8 · framework bc6f000 · angular ff67866 (app-shell ad2af35, proof 092151a, torch 1973a04). main NOT promoted.
**Pipeline:** polari-test PASSED on suite 126f2bf (89/89 + the isle stage, fresh-baked base). dev moved after it (demo-1b, demo-4, artifact urls, pinfix, module_home) → `pol jenkins promote test` again before main; `promote main` = his.
**Home stack:** rolled from dev all day (last roll e286130 VERIFIED: ten pages 200, drawings persist under /app/data, pin maps for UNO + C3, pin-roles 8 rows, c-canvas first item = c-graph-canvas-panel, 16 targets, in-container board 249 · pcb 46 · cmod 115): descriptions on every page/table, readiness split, the UNO/C3 pin maps + pin-roles table, inline schematic/layer SVGs (files now under /app/data via module_home), `/display/c-canvas` (the C graph in the no-code canvas, target definitions, the temperature-sensor capability ×2). Engines on isle-core through the mesh (route-src fix, NOT persistent).
**Plans written today:** DEMONSTRABLES_PLAN (demo arc, his order: C canvas first), TOPOLOGY_NETWORK_BRIDGING_PLAN (tnb, his rulings D-tnb-1..5), the guide, the barriers ledger (`AI-Notes/ledgers/BARRIERS_AND_SOLUTIONS.md`).

### TODO — in this order, nothing else
0. **Priorities + CapabilityDefinition clarity + the pin-interaction UX rework are now planned in
   `AI-Notes/plans/HARDWARE_DEV_PRIORITIES.md`** (P1 capability fields/validator → P2 the UNO on the bench → P3 demo-2
   → P4 the installer's live door → P5 demo-3 + sc-5 → P6 dlv; the export arc stays its own later iteration) — read it
   before resequencing anything below.
1. **demo-2** the UNO as a live 2D board sim-space on the pin map (the twin's frames → pin states/ADC/LED/UART; replay fallback) — `level-view` renderer `board`; page /display/firmware-installer above the panel; bind CapabilityInstances to pins here (two temperature sensors).
2. **demo-3** fault scenarios as a cycle trace view (`level-view` renderer `trace`, BEFORE/AFTER side by side) on /display/firmware-faults.
3. **demo-4 leftovers:** real build/prove through the canvas buttons (not mocked); atom picker in the overlay; installer + hwnocode pages default to USABLE boards; a per-object "pin map" tab on BoardDefinition detail (check the node-detail pattern first); demo-4b leftovers: cross-lane edges drawn dashed IN the canvas (today a text list), each crossing tied to its HardwareInterfaceBinding/TargetDefinition, a browser-kind state so the typescript-browser lane has a node, `GET /api/hwnocode/runtimes`; `pol pcb ingest --api` must accept the module-relative path.
4. **Seeds:** Connector/ConnectorPin rows for the ESP32-C3 (today it draws from bare BoardPins); descriptions reviewed by him for accuracy.
5. **tnb-0** (when he reopens topology): MachineAddress/MachineFirewall/NetworkEdge/AppliedRule rows in file + rows; findings advertise-address-drift / route-source-mismatch / address-not-stable / edge-data-plane-dead; `--json`; the durable .210 (static + reservation) is the first finding to raise.
6. **Pipeline:** promote test → main (his); register the pre-existing defClassList gaps the new guard found (pspp: BenchmarkCase, PrecursorSource, ResearchTool, ThresholdReactionWindow; testing: Acct1ParityProbe) — `selftest_manifests` is 7/9 until then (the pipeline's core suite may flag it); audit other verify checks for PASS-over-Traceback; `pol modules new` scaffold adds the taxonomy entry + the .gitignore exemption.
7. **Shared layer (his decision):** quote identifiers in `makeSQLiteTable` (25 reserved-word columns remain); artifacts to the file store instead of /app/data.
8. **Owed, unchanged:** remote-twin verb; `pol swarm deploy` retiring a same-port ad-hoc container; `pol pcb ingest --api` upload; the UNO on the bench (guide §4).

## STATE 2026-10-04 evening — everything merged to dev, deployed at home, promoted to test (main NOT promoted)
- dev tips: suite 025d10e · cli 46b8c11 · rf-node 2a96dfa · framework 38e8d56 · angular ea13f2c · app-shell ad2af35 · proof-tools 092151a · torch-tools 1973a04.
  Contents since the morning merge: swarm advertise/data-plane checks (cli 195f220), the pipeline apt-lock flake fix (suite d879381),
  the tnb plan (f615ab0), the nine deploy follow-ups (placement in compose, firmwarefaults columns site/position/check_name, honest
  probes, modules-env closure from the checkout, lan_ip prefers the swarm address, pcb ingest --api paths, pcb in app_taxonomy),
  gitignores (board-home/, desktop/bin/, __pycache__/) and the in-container SKIPs in the firmwarefaults selftests.
- HOME STACK: rebuilt + redeployed from dev twice today; placement constraint FROM THE STACK; `pol suite urls` = .210 on its own;
  pages 9/9; engines = 4 tasks on isle-core incl. KiCad; the backend reaches them by DIRECT address (knobs exported at render —
  DEBT row). Mesh data plane PROVEN 2026-10-04 evening after his route-src change (non-persistent; durable = static .210 + router
  reservation = tnb-0's first finding). `pol swarm ports` now explains both the drift and the data plane.
- PIPELINE: 933b326 FAILED (pcb missing from app_taxonomy = regression, fixed; isle stage = the unattended-upgrades dpkg-lock
  flake, fixed at the bake + a lock wait); econ-core pulled d879381, controller refreshed, prepared base cleared; `pol jenkins
  promote test` → 025d10e (2026-10-04 afternoon) — verdict pending; main waits for a PASSED verdict (`pol jenkins promote main`).
- NEXT: his route-src + the browser pass (guide `AI-Notes/guides/HARDWARE_ARC_TEST_GUIDE.md`, now on dev) + the UNO on the bench;
  his D-tnb-1..4 → tnb-0; the 25 reserved-word columns (TESTING_OWED §79) = his shared-layer decision.

## DEBT: proved by hand on 2026-10-04 → must become `pol` verbs / topology rows (his rule: the average person, AIs and GUIs get it through Polari)
| hand-applied fix | where | wrap as |
|---|---|---|
| `ip addr add 192.168.0.210/24` + NM `+ipv4.addresses` (the swarm manager's advertised address had drifted from DHCP .212) | pol-core | topology machine row: advertised vs current vs route-source address; `pol topology validate` finding + consented action; rule: the manager's advertise address = its stable primary address |
| route `src 192.168.0.210 metric 600` (VXLAN frames left from .212 → `VXLAN_ENTRY_EXISTS` drops on isle-core; found with bpftrace) — ✅ APPLIED by him 2026-10-04 evening: all four engine ports answer through pol-core in ~0.1 s, mesh proven both ways; NOT persistent (NM restores the DHCP src) | pol-core | tnb-0 finding `route-source-mismatch` + `address-not-stable` → static .210 + router reservation |
| two ufw lines (4789/7946 udp) — NOT needed, ufw is inactive; harmless | pol-core | topology: observed firewall state per machine (`pol topology report`), rules derived from edges, applied with consent + hand-back journal (`pol net` → fold INTO topology) |
| `docker service update --constraint-add node.labels.polari.machine==pol-core` ×6 | pol-core swarm | compose/render placement (dev-hw-followups #1) |
| `BOARD/ESP/FORMAL/PCB_ENGINES_URL` + `LOCAL_IP` exported in the shell before the render | pol-core | topology edges resolve the URLs (the mesh) or the render writes them from rows; never a shell export |
| `pol topology assign grpcbridge prf-a` by hand (closure computed from the old image) | core rows | modules-env closure from the checkout (dev-hw-followups #6) |
| `pol pcb ingest /app/modules/...` (in-container path) | staging backend | the CLI sends module-relative paths / uploads (dev-hw-followups #8) |
| rm of untracked `desktop/bin`, `__pycache__` to let `pol jenkins promote test` run | checkout | .gitignore lines in polari-app-shell / proof-tools / torch-tools |
| `board/custom/flash.py` flashes via `docker run --device` from the engines image (a stopgap from before the installer existed) | pol-core | ONE flash path = the Hardware Shell App's bridging (the Polari Firmware Installer); `pol board flash|install` DELEGATE to the running shell app or REFUSE; retire the docker route when exp-2 ships, never extend it (his correction 2026-10-06) |
| `docker rm -f prf-pcb-engines` on isle-core, then `pol swarm deploy hw-engines` | isle-core | the stack owns the worker now; `pol swarm deploy` should offer to retire a same-port ad-hoc container |

## His, when back
1. Plug in the UNO: `pol board detect` → `pol board install uno --variant uno-echo --yes` → open
   `/display/firmware-installer`; then `pol faults run torn-millis --both` on silicon.
2. The merge word: fast-forward dev to `dev-hw-integration` in the five repos (table above).
3. ✅ Confirmed 2026-10-02: the RTOS board is the ESP32-C3; Mthread joins the formal engines (sc-2c building). In flight
   also: cmod-0 (C modularization plan + the atom parser over the UNO firmware, branch dev-cmod-0).
4. The register's open cells (adapter USB IDs get captured the first time each is plugged in).
5. The swarm mesh: `pol swarm ports isle-core --apply` on pol-core (branch dev-swarm-fw-handshake) and answer y — or the three ufw lines by hand.

## Owed / found
- Pair first-PUT echo slow (1.9 s n=2, 4.7 s n=3 vs 0.1 s single) — cause unknown.
- simavr ADC reads 1 LSB low; the parser's residual frame-loss case (S4 measures it).
- align-at-pc forcing, the 2D trace viewer (design-lod-viewer), silicon replay, module repos
  polari-module-board / -firmwarefaults not created.

## dev-hw-test (2026-10-04)

A TEST-ONLY integration branch so the whole hardware arc can be hand-tested from one checkout — it does NOT change
the merge order above (brd-0 → … → cmod-1, then the three siblings). Branched from `dev-pcb-0` in all five repos
(itself `dev-hw-integration` → `dev-hn-0` → `dev-brd-bo` → pcb-0), then merged: polari-cli ← `dev-swarm-fw-handshake`
(carries `dev-swarm-hw-engines`); polari-rf-node ← `dev-topology-isle-engines` rf-node tip (adds
`docker-compose.hw-engines.yml`); suite ← `dev-topology-isle-engines` (adds the isle-core topology rows).

Tips: framework `3794756` (= dev-pcb-0, unchanged) · angular `d563892` (= dev-hn-0, unchanged) · rf-node `05f504e`
· cli `d781413` · suite (this commit).

What it adds beyond dev-pcb-0:
- **polari-cli**: `pol swarm hw-engines`/`ports`/`join` handshake/`leave`, `pol net`, `scripts/swarm-selftest.sh`
  (91/91 passing) — merged cleanly, no conflicts.
- **polari-rf-node**: `docker-compose.hw-engines.yml` gains a fourth service, `pcb-engines` (image
  `prf-pcb-engines:trixie`, :9860, pinned `node.labels.polari.machine == isle-core`, mem cap 1024m — same shape as
  board/formal/esp-engines; image id **UNVERIFIED**, only its 1.23 GB size is recorded in
  `prf-pcb-engines/cost.json`). `docker-compose.staging-nip.yml`'s backend now passes `BOARD_ENGINES_URL`,
  `ESP_ENGINES_URL`, `FORMAL_ENGINES_URL`, `PCB_ENGINES_URL` through, same style as the existing
  `ORFS_ENGINES_URL` line (unset = local binary/image → topology provider → honest refusal).
- **suite**: `topologies/staging-a.topology.yml` gains the `pcb-engines` instance + `pcb.engines@pcb-engines`
  ModuleAssignment, plus five new top-level ModuleAssignment rows — `board@prf-a`, `cmod@prf-a`,
  `firmwarefaults@prf-a`, `hwnocode@prf-a`, `pcb@prf-a` (all `state: enabled`) — so `pol topology push` +
  `pol topology modules-env prf-a` (or `GET /api/topology/modules-env/prf-a`) derive these five modules into
  POLARI_MODULES at deploy time; `hwnocode`'s FEATURE_REQUIRES pulls in `grpcbridge` through the requires-closure
  with no explicit row needed. Confirmed: the framework's `topology/provider_registry.PROVIDER_PORTS` already carries
  `'prf-pcb-engines': 9860` on dev-pcb-0 (pcb-0's own claim checks out, no change needed).
- Conflicts (add/add, `AI-Notes/plans/HARDWARE_NOCODE_PLAN.md` and `PCB_FROM_SCRATCH_PLAN.md`): both sides are
  different-dated snapshots of the same two plan docs — `dev-pcb-0`'s copy is a strict superset of
  `dev-topology-isle-engines`'s older snapshot (the hn-0/pcb-0 "BUILT" sections are the only difference). Resolved by
  keeping the `dev-pcb-0` side; verified the resolution's diff against `dev-pcb-0` is empty, so nothing from either
  side was lost.

Tests run from the worktrees (host, no docker): `bash -n` on every `.sh` file the cli merge touched (5 files, all
OK); `polari-cli/scripts/swarm-selftest.sh` 91/91; `python3 -c "import yaml; yaml.safe_load(...)"` on
`staging-a.topology.yml` OK; `docker compose -f docker-compose.hw-engines.yml config -q` exit 0 (parses clean with
the new service). Framework selftests (`PYTHONPATH=.:modules`, all unchanged from dev-pcb-0): `board_selftest`
198/198, `cmod_selftest` 100/100, `firmwarefaults_selftest` 190/190, `hwnocode_selftest` 54/55 (the 1 failure
pre-exists at dev-hn-0 per the plan's own note — a gitignored split record), `selftest_manifests` 8/8,
`selftest_lazy_imports` 23/23, `accessControl.selftest_cause_context` 41/41.

**Found (pre-existing on `dev-pcb-0`, not caused by this branch — framework worktree is byte-identical to
`origin/dev-pcb-0`, no diff):**
- `pcb_selftest` crashes at check 21/35 (`FileNotFoundError`:
  `modules/pcb/custom/upstream/kicad-demos-9.0.2/SOURCE.json`). Root cause: `modules/pcb/.gitignore`'s blanket
  `*.json` rule has no per-file exemption for that path, unlike `modules/board/.gitignore`'s
  `!modules/board/custom/upstream/**/SOURCE.json` — so the file was silently never committed. Same failure class the
  hwmap fixture gap on `dev-hwmap-fixture` already fixed (one `.gitignore` exemption line); pcb's analogue was never
  added. Not fixed here (pcb-0's own slice, out of this branch's scope) — 20/20 checks pass before the crash.
- `polariApiServer.selftest_outbound` is 60/61, not the 61/61 the pcb-0 BUILT section claims: a new unwrapped send at
  `modules/pcb/custom/pcb_engines.py:100` (`urllib.request.urlopen` in the `ImportError` fallback branch) isn't in
  `KNOWN_STRAGGLERS`. `board.custom.board_engines` has no such gap. Not fixed here, same reasoning as above.
