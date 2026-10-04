# Handoff — the board + firmware-fault arcs (brd, sc), state on 2026-10-02

_Written while he was at work ("work autonomously on this"). Everything below is on PHASE BRANCHES, pushed, NOT
merged; nothing touched dev/main, the droplet, or the running stacks. His merge word is owed for the whole stack._

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
