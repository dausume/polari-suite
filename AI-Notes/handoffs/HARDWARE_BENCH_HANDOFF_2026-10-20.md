# Hardware bench handoff — 2026-10-20 (evening)

## STATE AT HANDOFF (written as the session ran out)
- **LIVE ROLLED + MAIN == DEV (done at the very end):** pol-core's `polari-node_backend` / `polari-node_frontend` run the dev images (framework 9f96fca,
  angular 22092a1, cli cd87a8b); verified through the proxy at `https://api.prf.192.168.0.210.nip.io` (`/api/health`, the installer document with
  modes sim|real, `/api/firmware-state/uno-light/fields` 200; frontend 200). NOTE: the live API hostname is the nip.io one — `api.polari.isle` answers 503
  from this stack's proxy and is not a roll failure. main was fast-forwarded to dev in all five repos.
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

## dev-smp-2 cmod FAIL lines (isle-core, full run; the labels only)
  [PASS] …a subsequent MEASURED run — even a FAILURE — always wins over an earlier attestation (the newest evidential run rule, unchanged): status downgrades HONESTLY to planned, proof_kind repo
- the UNO template parses over its 13 configurations (11 seeded variants + 2 coverage; smp-1: + uno-light-unsensed) into 71 atoms (fgm-5a: + the 8 atoms of the two rendered button files; fgm-5b: + the
- the 31 POLARI_NODE annotations attach to their functions (hal 10, sim_rig 2, echo 1, scenario_rig 3, button_clock 10, light 5; scl: + led_follow_state in button_clock and light) ['apps/light.sense_p
- the UNO's polari-firmware.json is committed beside its Makefile, validates, schema polari-firmware/1, 71 atoms []
- every atom carries ports (a list), resources (a list) and a measured cost: text bytes as a node > 0 for all 69 72
- seeds = the committed manifest projected: 1 project, 11 modules (ucd-0e2b: + apps/button_clock_defs header; ucd-light: + apps/light + its defs header), 71 atoms (fgm-5a: + 8 rendered-button atoms; f
- GET /api/cmod → the uno project with 71 atoms, the parser named {"ok": true, "parser": {"engine": "pycparser", "version": "2.21", "runs": "in this process"}, "projects": [{"name": "uno", "kind": "
  [PASS] read-button:pin-change-interrupt: a FAILED run lifts nothing 
  [PASS] read-button:analog-threshold: a FAILED run lifts nothing 
  [PASS] drive-led:pwm: a FAILED run lifts nothing 
  [PASS] sense-led-line:gpio-poll: a FAILED run lifts nothing 
  [PASS] sense-led-line:pin-change-interrupt: a FAILED run lifts nothing 
- pp-0: the control Purpose has the transport rx (reserved), the LED and the sense line; the observe Purpose the transport tx (reserved) plus, since scl, the LED and the sense line (the sensed level i
- pp-0: the Mission roll-up of the light Purposes is exactly: transport uart-rx + uart-tx (reserved), the LED digital-out, the button interrupt-in, the sense line interrupt-in [('the LED', 'digital-ou
- pp-0: the real seeded HardwareMission uno-light-mission (live row and pure seed) rolls up to the 5 light profiles, importance per Purpose from purposes_json (6, 6)
- pp-0: with the REAL mis-0 MissionAPI on one falcon.App (its first): /api/missions/{name}/solution, /resolution, the /api/missions list and my /pin-profiles all answer (200, '{"mission": "uno-light-m
- pp-0: with the REAL mis-0 MissionAPI on one falcon.App (mine first): /api/missions/{name}/solution, /resolution, the /api/missions list and my /pin-profiles all answer (200, '{"mission": "uno-light-
- pp-0: ?purposes=a,b names the Purposes when no Mission row exists (works before mis-0 merges); an unnamed Mission without it is a 404 (200, 6)
- pp-0: the page doors answer {ok, rows} in plain words: every light Purpose, the 5-profile Mission, and the unresolved tasks (39, 6, 42)
- pp-1: the light Mission co-location reads pp-0's 5 profiles (transport rx + tx reserved, the LED, the button, the sense line) ['the transport', 'the LED', 'the button', 'the sense line']
- pp-1 LIGHT DEMO: the transport pair is reserved - each on its own pin, never grouped; the minimum is 4 pins for 5 profiles (the LED and the sense line share one pin, with the self-interrupt conditio
- pp-1 DOORS: GET /api/missions/{name}/colocation[?purposes=&view=pairs|groups|apart] and /api/board/socs/{soc}/profile-overlap ADD on a real falcon.App with EVERY cmod door (mis-0 solution/resolution
- pp-1 DOORS: GET /api/missions/{name}/colocation[?purposes=&view=pairs|groups|apart] and /api/board/socs/{soc}/profile-overlap ADD on a real falcon.App with EVERY cmod door (mis-0 solution/resolution
  [PASS] a FAILED run lifts nothing 
- rt-0: concurrency from the schedule lanes and pp-0: 6 interrupt vectors (fgm-5a/5b: the ISR atoms of the project, hal_button_pcint.PCINT2_vect and hal_sense_pcint.PCINT0_vect among them), 6 loop tas
- rt-0: UNO bare C is AVAILABLE: the recorded build (3132 B flash, 514 B static RAM, MEASURED; scl moved them from 3110 / 513) fits the cited limits (32256 B after Optiboot, 2048 B) [{'what': 'flash',
- rt-0: the light Mission's six loop tasks (scl: + led_follow_state) all tie (100 ms, required) and the preview says the order is only the schedule order 7 task(s) tie on both deadline and importance,
- rt-0: ?view=priorities answers flat plain-words rows for the page table {"ok": true, "view": "priorities", "mission": "uno-light-mission", "board": "arduino-uno-r3", "count
- sol-0 / fgm-5b: the polled sense line is priced by its own atoms now - under fastest-cycle it costs loop time (cycle + ... us) against the INT1 sense and ranks below it, and the score card says so 1
  [PASS] fsc-0 FAIL RULE: a normal candidate (placed, all Purposes kept, no flagged deadline) does not fail 
  [PASS] fsc-0 FAIL RULE (his D-fsc-1): an UNFLAGGED deadline violation is NOT a failure (scored by closeness) but is listed 
  [PASS] fsc-0 FAIL RULE: the SAME violation on a deadline flagged safety_critical IS a failure, naming the Purpose and the reason 
  [PASS] fsc-0 FAIL RULE: a lost Purpose fails, naming it 
  [PASS] fsc-0 FAIL RULE: pins that cannot be placed fail 
  [PASS] fsc-0 FAIL RULE: MISSING PARTS are not a failure (a cost term): drive-led:gpio-out, read-button:i2c-expander, receive-comman needs PCF8574-class I2C I/O expander 
  [PASS] fsc-0b FAILURES: uno-light-unsensed, uno-light-pcint, -analog and -v2 (built for this Mission, no route for sense-led-line) are FAILURES: the Purposes that job serves (derived from the Missio
  [PASS] fsc-0b FAILURES: a failing config never appears among the records (so it is never scored or compared) and is counted in counts.failed (5) 
  [PASS] fsc-0 FINISHED: a LATER FAILED run takes the proof away again (a stale pass is never carried forward) 
  [PASS] fsc-0b DOOR scores: GET /api/firmware-scores?mission=uno-light-mission lists the four built light configs as FAILED rows (name, Purpose failed, why, no score) and never ranks them: ['uno-ligh
  [PASS] fsc-0 FAIL RULE end to end: with the deadline tightened but NOT flagged, nothing fails - the polled plans are scored by closeness (deadline-fit below 100) and the miss is listed 
  [PASS] fsc-0 FAIL RULE end to end: the SAME deadline flagged safety_critical -> the plans that miss it FAIL (80), each naming the Purpose and the reason; the survivors (60) all meet it 
  [PASS] fsc-2 FAILURES (door): failed solutions are listed after the ranked ones with state `failed`, the Purpose and the reason, NO score and NO rank, and never enter the compared set (60 ranked, 85
  [PASS] fsc-2 FAILURES (door): the breakdown of a failed solution says failed with the Purpose and reason and a null score, and the top tab counts the failures 
  [PASS] fsc-6 DOOR: a LATER FAILED run of a config leaves the Purpose's own status alone too 
  [PASS] smp-0 CLI: `pol firmware scores` defaults to the sample - it names the curated sample, prints S1.., lists F1 and F2 as FAILED and names the history 
- fgm-3: steps are the graph's atoms in graph order - init: the five init atoms; the button task is fed by INT0_vect; the command task by USART_RX_vect; the report task by the tick (TIMER2_COMPA_vect)
- fgm-5b: the polled sense task's step is the route's read atom, whose lane (loop) is read from the shipped atom it replaces (called by sense_isr in uno-button-clock-graph); its init atom belongs to t
- fgm-3: the demo candidate (button INT0, sense INT1 on D3) gives a sense task fed by INT1_vect: its steps are the route's atoms with lanes read from the graph that schedules them (uno-button-clock-gr
- cyc-0: with the records off sol-0 is as it was (0 measured parts, the ~9.7 ms estimate); with them the same plan costs 10.59 ms - 0.78 ms of measured CPU work the upper bounds had left out (9808.6, 
