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

Merge order when he says so: brd-0 → brd-1 → brd-fi → brd-wire → sc-0 → sc-1 → sc-2 (each repo innermost-first; the
suite's dev-sc-2 already carries sc-4's commits, so sc-4 needs no separate merge). The first real pipeline run of the
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
`*.json` ignore) — being fixed on `dev-hwmap-fixture` with a SANITISED fixture (no real identifiers) + a skip-with-reason.
Harness note: several selftests resolve sibling paths relatively, so rehearsal worktrees must mirror the submodule nesting.

## His, when back
1. Plug in the UNO: `pol board detect` → `pol board install uno --variant uno-echo --yes` → open
   `/display/firmware-installer`; then `pol faults run torn-millis --both` on silicon.
2. The merge word for the stack above.
3. Confirm "STM32-C3" meant ESP32-C3 (the RTOS scenarios S6 target it).
4. The register's open cells (adapter USB IDs get captured the first time each is plugged in).

## Owed / found
- Pair first-PUT echo slow (1.9 s n=2, 4.7 s n=3 vs 0.1 s single) — cause unknown.
- simavr ADC reads 1 LSB low; the parser's residual frame-loss case (S4 measures it).
- align-at-pc forcing, the 2D trace viewer (design-lod-viewer), silicon replay, module repos
  polari-module-board / -firmwarefaults not created.
