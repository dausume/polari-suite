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

Merge order when he says so: brd-0 → brd-1 → brd-fi → brd-wire → sc-0 → sc-1 → sc-2 (carries sc-4) → then the three
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

## His, when back
1. Plug in the UNO: `pol board detect` → `pol board install uno --variant uno-echo --yes` → open
   `/display/firmware-installer`; then `pol faults run torn-millis --both` on silicon.
2. The merge word: fast-forward dev to `dev-hw-integration` in the five repos (table above).
3. ✅ Confirmed 2026-10-02: the RTOS board is the ESP32-C3; Mthread joins the formal engines (sc-2c building). In flight
   also: cmod-0 (C modularization plan + the atom parser over the UNO firmware, branch dev-cmod-0).
4. The register's open cells (adapter USB IDs get captured the first time each is plugged in).

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
