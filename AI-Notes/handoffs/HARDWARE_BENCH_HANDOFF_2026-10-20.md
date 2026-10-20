# Hardware bench handoff — 2026-10-20

## Where everything is
- **main == dev** on all five repos (suite, polari-rf-node, polari-framework, polari-platform-angular, polari-cli).
- **Live pol-core** and the **test node (econ-core)** run the same images: twin sessions, hosted bridges, the curated sample, the layout and sim-bench pages.
- **isle-core** runs the five engine workers (board :9830 with sessions 9832–9863, formal :9840, esp :9850, pcb :9860, bridge :9870) and every selftest run.
- Plans: `HARDWARE_BENCH_CONVERGENCE_PLAN.md` (the umbrella; §12 = the next iteration), `PROTOTYPING_VIEWS_PLAN.md` (§8 = the circuit-states design),
  `BREADBOARD_BUILD_PLAN.md`, `FIRMWARE_SCORE_PROFILES_PLAN.md` (§13–14 the curated sample), `UNO_CORE_DEMO_PLAN.md` (the sweep + owed list).

## Proven (all four Purposes on each own build)
S1 `uno-light` (sense jumper D6→D3), S2 `uno-light-all-pcint`, S3 `uno-light-pwm-analog`, S4 `uno-light-transistor` on live and the test node;
S5 `esp32c3-light` on the C3 twin from isle-core. F1 `uno-light-unsensed`, F2 `uno-light-slow-loop` are the two sample failures.

## Owed (in order; §12 of the umbrella plan has the detail)
1. ins-0/1: the Sim install | Real install toggle on the installer + the confirmed-sim gate.
2. fst-0..2: the firmware state-objects page.
3. sim-bench follow-ups: the firmware table can start a firmware that does not match the picture; the Whole-build toggle; the header's app group on direct URLs.
4. smp-2 on branch `dev-smp-2` (the bundle graph gains the sense line; blocker = the compiled-in check in `cmod/custom/graph.py` must accept route-rendered `hal_sense_*`).
5. cst-0/1 (design in PROTOTYPING_VIEWS_PLAN §8), then lay-3/sim-4, brg-1..3, cst-2.

## Rules that bit this iteration
- No agents unless he says so (overall limit tighter than the Fable limit). Builds, suites, merges, Chrome checks in-session.
- `pol deploy selftest isle-core --ref <branch> --modules …` (per-run worktrees; cap 7200 s; prints FAIL lines). Never heavy suites on pol-core.
- `python3 -m moduleService.manifests generate board` EMPTIES the hand-written `requires.engines` block — restore it from git afterwards.
- Help text in CLI scripts: escape backticks (an unescaped one in `pol deploy help` ran `pol prod apply --yes`).
- Chrome checks: `scratchpad/cdp-shot.js` / `cdp-debug.js` with `WS_MODULE=<angular>/node_modules/ws`; subscribe to a session's events BEFORE injecting.
- The test node reaches workers by knob (`pol-build/manifests/nodes.yml` `engines:`), not by topology; `pol allocate` needs `POLARI_CORE_URL` to target it.
- Stop every twin session and hosted bridge you start (`pol board twin session stop`, `pol grpc hosted stop`); check the workers list none.

## His bench
S1 wiring: button D2→GND, D6 → 220 Ω → LED → GND, jumper D6→D3 (`pol board layout uno-light --steps` for the hole-by-hole words); Detect + flash from `/display/firmware-installer`.
