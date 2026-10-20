# Hardware bench handoff — 2026-10-20 (evening)

## STATE AT HANDOFF (written as the session ran out)
- **Live roll IN PROGRESS:** `prf-backend:staging` + `prf-frontend:staging` were built on pol-core from dev (framework 9f96fca, angular 22092a1, cli cd87a8b)
  and `docker service update --force` was issued on `polari-node_backend` + `polari-node_frontend`; the backend task was "Starting 4 minutes ago" with
  `/health` 503 (its boot takes 11+ min). **Check `/health` → 200, then fast-forward main to dev in all five repos** (suite e1192e7, rf-node, framework,
  angular, cli: `git checkout main && git merge --ff-only dev && git push`) — NOT done yet.
- **Gate passed at the dev tip on isle-core:** board 992/992, cmod 1369/1369, hwnocode 171/171, firmwarefaults 233/233, manifests 8/9 (the known
  pspp/testing baseline); local: fst 28/28, installer 61/61, apps 131/131; Karma installer+apps-nav 26/26 (display-page tabs + layout-view specs passed too).
- **dev-cst** (framework 85e2014 + cli b4fdd70): electrodevice 114/114, circuit states 21/21 (SPICE skipped on isle-core), layout 89/89, cmod 1369/1369;
  its board suite was running on isle-core (`scratchpad/selftest-cst-b.log` in the session's scratchpad). Merge after it passes.
- **dev-smp-2** (framework a4bbc74 + the cycle record 3e614dc): hwnocode 171/171, firmwarefaults 233/233, cmod **1347/1373 — 26 expectation drifts** to fix
  before merging: `cmod/cmod_task_plan_selftest.py` (fgm-3 init steps = the five init atoms — now six with sense_init; the sense task's steps/lanes now come
  from uno-light-graph's own sense nodes, not uno-button-clock-graph; agreement counts), `cmod/custom/selftest_cycles.py` (cyc-0: with the new
  `cycle_records/uno-light.json` sol-0 has measured parts even "as it was" — re-read the numbers), plus the rest of the list (a full-FAIL run was in
  progress on isle-core worktree `~/polari-suite-test-runs/smp2`). Its board suite is still owed.

## Where everything is
- **dev** (framework, angular, cli, rf-node, suite) carries ins-0/1, fst-0..2 and the sim-bench follow-ups; **main** is fast-forwarded to dev once the
  isle-core suite at the dev tip passes and live is rolled (see "Roll" below — if main lags dev when you read this, that step was not reached).
- **Test node (econ-core)** runs dev (deployed this session; Chrome-checked). **Live pol-core**: rolled from the same dev when the suite passed.
- **isle-core** runs the five engine workers (board :9830 with sessions 9832–9863, formal :9840, esp :9850, pcb :9860, bridge :9870) and every selftest run
  (`pol deploy selftest isle-core --ref <branch> --modules …`, own worktree per run, cap 7200 s).
- Branches NOT merged: **`dev-smp-2`** (framework; the sense line in the bundle graph — built, proven EQUIVALENT on isle-core, suites owed) and **`dev-cst`**
  (framework + polari-cli; cst-0/1 circuit states — selftest 29/29 locally, suites owed). Both branch off dev-ins ≈ dev; merge dev into them first.
- Plans: `HARDWARE_BENCH_CONVERGENCE_PLAN.md` §12 (his asks) + §13 (what was built + the Chrome results); `FIRMWARE_SCORE_PROFILES_PLAN.md` (smp-2 status at
  the end); `PROTOTYPING_VIEWS_PLAN.md` §8 (cst design) + §9 (cst-0/1 status).

## Built this session (in order he asked)
1. **ins-0/1** — the Sim install | Real install toggle on `/display/firmware-installer`; the confirmed-sim gate (`board.custom.sim_gate`,
   `SimInstallConfirmation`): a real install of a Mission config is offered only after the four Purposes passed on the twin AND a person ticked for the
   build's exact hex; otherwise the words say what is missing and offer the sim install; "install anyway" needs a reason, recorded on the plan and the
   record; a new hex voids the tick (re-read at run time). The sim bench's own confirm row action ticks the same row. `pol board install --sim|--real
   [--anyway]`, `pol board gate`, `pol board confirm-sim`. Installer selftest 61/61.
2. **fst-0..2** — `/display/firmware-state?config=<config>`: every state object derived from the config's rendered sources (wire struct, rx parser, statics,
   local statics, enums + meanings + who sets/compares, presence bits, per-field writers/readers with pointer hand-offs, findings), rows
   FirmwareStateObject/Field, doors `/api/firmware-state/{config}[/fields|/enums|/findings|/live?session=]`, `pol firmware state <config>`; the page's
   scope is seeded from the URL (`_page(scope_query=…)`). Selftest 28/28. Any UNO variant works (S2..S4 included).
3. **sim-bench follow-ups** — the picture follows the session's firmware; the header keeps the app group on direct URLs; the Whole-build toggle was fine.
4. **smp-2** (dev-smp-2) — graph.py accepts route-rendered `hal_sense_*`; glue carries the route module; render → build → prove EQUIVALENT with the jumper;
   new glue record + uno-light cycle record (force-added past `*.json` in .gitignore); D3 claimed; observe Purpose names the sense tasks; INSTALL.md
   wiring derived from the layout steps.
5. **cst-0/1** (dev-cst) — circuit states + transitions + one `.op` per state (ngspice) judged against the cited limits; rung-7 reader; `pol circuit`.

## Owed (in order)
1. Finish the roll if it was not done: `pol node build backend frontend --env staging` on pol-core → `docker service update --force --image
   prf-backend:staging polari-node_backend` (+ frontend) → `/health` 200 → `git merge --ff-only dev` on main in all five repos → push.
2. smp-2: `pol deploy selftest isle-core --ref dev-smp-2 --modules cmod.cmod_selftest,board.board_selftest,hwnocode.hwnocode_selftest,firmwarefaults.firmwarefaults_selftest`
   (after merging dev into dev-smp-2); then merge to dev, deploy the test node, roll live.
3. cst-0/1: the same for dev-cst (`electrodevice.electrodevice_selftest,electrodevice.circuit_states_selftest,board.board_selftest,cmod.cmod_selftest`);
   merge; then cst-2 (the page: states list, the schematic with the state applied, the transition graph, the SPICE tables — ONE sanctioned d3 component).
4. lay-3/sim-4 (confirm-then-bind on the real board), brg-1..3, cst-3 (transient co-simulation), wiring `fsc_values.active_current` into the scorer.

## Rules that bit this iteration
- No agents unless he says so. Builds, suites, merges, Chrome checks in-session.
- `manifests generate <module>` EMPTIES `requires.engines` AND `requires.engines_note` — restore both from git; re-dump with `ensure_ascii=False`.
- A new object class goes in THREE places or `selftest_manifests` fails: `polariApiServer/feature_imports.py` (the module's tuple), `polariServer.py`
  defClassList, the module manifest (regenerate). The known pspp/testing defClassList failure is the baseline (8/9).
- The test node's backend boot after a deploy is ~15 min CPU-bound with buffered logs; `/health` is 000 until then. Not a hang.
- `board/custom/cycle_records/*.json` are gitignored by the module's `*.json` rule — `git add -f`.
- ngspice: `GND` is the ground alias (a `Vgnd GND 0` source is a short); `;` ends a line comment; node names must not carry `-`.
- Chrome checks: `scratchpad/cdp-shot.js` / `cdp-debug.js` (copied from the previous session's scratchpad) with `WS_MODULE=<angular>/node_modules/ws`;
  `CLICK_JS` runs a page expression before the capture. Stop every twin session you start (`pol board twin session stop <id> --api …`); the worker's
  `/sessions` must list none.

## His bench
S1 wiring: button D2→GND, D6 → 220 Ω → LED → GND, jumper D6→D3 (`pol board layout uno-light --steps`); on `/display/firmware-installer` do the SIM install
first (the twin runs the hex; run the four Purposes; tick "I checked the simulated board does what the firmware says"), then the REAL install is offered.
