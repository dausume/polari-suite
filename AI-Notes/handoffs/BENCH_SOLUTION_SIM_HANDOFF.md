# Bench Solution simulation (bss) - handoff, 2026-11-02

The plan is `AI-Notes/plans/BENCH_SOLUTION_SIM_PLAN.md`; this is the state at the end of the first build day, for whoever picks it up (a person or an AI).
Everything below is on `dev-electronics` in every repo (framework, rf-node, angular, cli, suite). Nothing was deployed; the Chrome pass is owed and a
deploy is the user's call.

## What exists now (all with selftests; the long suites board 1123/1123 and cmod 1377/1377 green after each slice)

| Slice | Where | What it does | Proof |
|---|---|---|---|
| bss-0 | board | Systems (templates) and Solutions (bound): `HardwareSystem` (new meaning) / `ThermalSystem` / `ThermalMitigation` / `ThermalSolution` / `BenchSystem`; `BenchSolution.system`; `HardwareSolution.system`; the WHOLE check (`board.custom.bench_solution_whole`) and doors `/api/board/bench-solutions[/{name}[/legs]]`. D-bss-1 renames: board `HardwareSystem` -> `HardwareSolution`, hwnocode `HardwareSolution` -> `HardwareNoCodeSolution` (the user vetoed CrossDomainSolution); stored rows converged by name, never deleted (`board.custom.solution_rename_converge`) | `board_bench_solution_selftest` 12/12; `board_solution_rename_selftest` 9/9 |
| bss-1 | cmod | the topology's start: root (plugged in) -> flash -> flashed -> init -> boot; `StructNode` / `Requirement` / `Execution` / `Collateral`, `StructEdge`, `StructNodePath`, `StructFieldSamples`, `HardwareEvent` (offered from the firmware's own assertions; the predicted chain), `IsotopeStepRule` (cycle record / cited / knobs); `cmod.custom.bench_topology`, `bench_events`, `isotope_step_rules`; doors `/api/cmod/bench-topology/{bs}[...]` | `cmod_bench_topology_selftest` 16/16 |
| bss-2 | cmod + prf-board-engines | ONE node test = ONE deterministic twin run from reset along a path (`cmod.custom.node_run`): `--pin-at` pulses spaced by the node's guard, required fields `--watch`ed by address (the generated header's member order), the twin's NEW `watch-change` event (twin_forcing.c) for the exact met cycle, executions counted with `--fn-cycles` in the -fno-inline build, the PD6 collateral from `wire-edge`; kept: `StructNodeRun` / `RunEdge` / `RunSignal` (the assessment, no trace) | `cmod_node_run_selftest` 14/14 on the real twin |
| bss-3 | cmod | confirmations (`StructNodeConfirmation`: twin / hardware record / person; voided on a build change), `StructEdgeCheck` (timing / tolerance / range -> checks-failed), divergence proposals (`StructNode.basis` proposed), manual `TestProfile` + items, play from a node | `cmod_confirmations_selftest` 11/11 on the twin |
| bss-4 | cmod + board | re-test the affected nodes first after a configuration / isotope change (`cmod.custom.retest`; isotopes synced from `CatomConfiguration`, route word = D-bss-13); run-row doors; the page `/display/bench-solutions` | `cmod_retest_selftest` 7/7 on the twin |
| bss-5 | cmod + hwnocode | the topology on the ONE no-code canvas, category `bench-topology` (`cmod.custom.bench_topology_nocode`; kinds `struct-node` / `hardware-event`; node -> event -> node; colours by confirmation state; write-back titles only; the SolutionDefinition row kept; GET/PUT `.../canvas`); the category in the declarative validator | `cmod_bench_canvas_selftest` 11/11 |
| bss-6 | cmod | coverage made obvious (`cmod.custom.topology_coverage`): the untested list FIRST, the strip, per-node rows, assertion coverage; doors `.../coverage[/...]`; the page `/display/hardware-events` | `cmod_coverage_selftest` 9/9 |
| bss-7a | cmod | the command edge runs: a Polari command = `--inject` of a frame built from the to-node's exact wire-field requirements | `cmod_command_edge_selftest` 7/7 on the twin |
| bss-8 | cmod + board + prf-board-engines | THE WHOLE LIGHT TOPOLOGY, EVERY ROUTE, AS DATA: a topology spec per Bench System (`custom/topologies/uno-light-bench.json`; nodes by ROLE press / command / reset / period) applied per Bench Solution (`cmod.custom.bench_topology_spec.apply`: roles -> that Solution's events, jobs -> that variant's isotopes); every light variant's assertions derived from uno-light's re-pinned by its knobs (`catom_assertions.for_variant`); the stimuli reset (`--reset-at`), period (a window of 2 periods, no stimulus) and analog level (the twin's NEW `--adc-at`); the command frame carries only the atom's own presence-tested fields; enum labels judged by their wire byte; `retest.run_all` + `.../run-all`; `GET /api/cmod/topology-specs`, `POST .../apply-spec`; inert events + chain-node crossings in coverage; the bench rows seeded in board_seed | `cmod_light_topology_selftest` 21/21 on the twin: 6 state nodes x 8 paths all reached (39 s), the untested list EMPTY; the pin-change and analog routes reach "light on" / "light off" |
| docs | pol-hub | "How Polari works for hardware" (`AI-Notes/guides/HARDWARE_NOCODE_GUIDE.md` -> `pol-hub/site/docs/hardware-nocode.html`); build-docs renders mermaid fences | `build-docs.py --check` clean |

## How to run it (from polari-framework/, `PYTHONPATH=.:modules`)
- the pure selftests: `python3 -m cmod.cmod_bench_topology_selftest`, `cmod.cmod_bench_canvas_selftest`, `cmod.cmod_coverage_selftest`, `board.board_bench_solution_selftest`
- the twin-backed ones (need the avr engines: the local `prf-board-engines:trixie` image; rebuild it from prf-board-engines/ with
  `docker compose -p board-engines -f ../docker-compose.board-engines.yml build` - there is no `pol` wrapper for it; `strings` is not in the image, grep -a the binary):
  `cmod.cmod_node_run_selftest`, `cmod.cmod_confirmations_selftest`, `cmod.cmod_retest_selftest`, `cmod.cmod_command_edge_selftest`,
  `cmod.cmod_light_topology_selftest` (bss-8: the whole topology, ~95 s; needs the image WITH `--adc-at`)
- the long suites (never two board_selftests at once): `python3 -m board.board_selftest` (~28 min), `python3 -m cmod.cmod_selftest` (~26 min)

## bss-8: how the whole topology is run (2026-11-02, second session)
- The spec is data: `modules/cmod/custom/topologies/uno-light-bench.json` (named after the Bench System; `.gitignore` exempts `custom/topologies/*.json`). Roles, not pins.
  `POST /api/cmod/bench-topology/{bs}/apply-spec` (or `bench_topology_spec.apply(manager, bs)`) resolves the roles to that Bench Solution's offered events and defines
  the nodes through the same doors the canvas writes; idempotent. Then `POST .../run-all` runs every state node by every path and returns the untested list.
- Three seeded Bench Solutions share the spec: `uno-light-on-desk` (D2, external interrupt), `uno-light-pcint-on-desk` (D4, pin-change interrupt),
  `uno-light-analog-on-desk` (A0, analog threshold). The two route variants name the VARIANT as their firmware_solution (no FirmwareSolution row yet: cfg-1
  is where the configuration drives the build). The live `uno-light` Firmware Solution's graph maps to the UNSENSED variant (cycle_records.GRAPH_VARIANT), so
  on a live server its PD6 collateral reads unmeasured until the Firmware Solution carries the sense jumper; the selftests use the fake manager (variant uno-light).
- `--adc-at cycle=N,ch=C,mv=M` is new in the twin (prf-board-engines/twin_forcing.c): the image was rebuilt (`docker compose -p board-engines -f
  docker-compose.board-engines.yml build` from polari-rf-node/, under a minute). An older image refuses the flag: the analog route's runs then fail in words.

## Gotchas found (so nobody re-finds them)
- the wire enum byte is 0 = unknown, labels[i] = i + 1 (grpcbridge.custom.wire_contract): `source = button` is 2, not the label's index 1
- in a SENSED build without the sense jumper (`--wire`), `telemetry_send` writes the sensed level (0) into led_on for the frame and restores it: the watch sees
  led_on flip at every report. With the jumper (node_run always passes it when the variant has the feature) the sensed level equals the commanded one
- the chain nodes flashed / boot are never a run's target: they count as tested by the runs that crossed them (`bench_topology_nocode.crossings`)
- the analog button rests at the pull-up's level: node_run passes `--adc0-mv 4800` (light_button.default_adc) for the adc route, else the twin's default 750 mV
  would be a press at boot
- the generated packets header declares struct members SORTED BY NAME; the layout comes from firmware_state's parsed order, not the struct map's draft order
- a line held low for ever is not a press (the UNO light toggled twice): a press is a 5 ms pulse (knob `PRESS_HOLD_CYCLES`)
- the shipped hex inlines every atom: executions are counted in the -fno-inline build and over the WHOLE run (`led_toggle` runs every loop pass)
- `pgrep -f` in a wait loop matches its own command line; wait on a PID instead
- the twin's final line reports a watched word as `final`, not `value`

## Owed / next
1. The Chrome pass of the new pages and the canvas (`/display/hardware-events`, `/display/bench-solutions`, `/display/hardware-solutions?solution=bench-topology-<bs>`): needs a deploy (the user's call).
2. ~~Stimuli still refused in words: reset, environment levels, periods~~ DONE in bss-8 (reset, period, an ADC level at a cycle). Still owed: the TMP36 "level"
   events (`level-<variable>` from CatomVariable adc.in rows carry no mV yet: a sample value on the node, StructFieldSamples) and an ADC ramp as an edge.
2b. The other LED routes (pwm, transistor: `uno-light-pwm-analog`, `uno-light-transistor`) and the sense routes (pcint: `uno-light-all-pcint`) are not seeded as Bench
   Solutions yet; the spec applies to them unchanged (routes_of maps led_route / sense_route) - seed a row and run-all to prove each. A Firmware Solution row per
   variant, with the configuration driving the build, is cfg-1.
3. The failure WaveformCapture (3c): feed the osc arc's emulated endpoint from the run's events instead of inventing a capture record.
4. A per-edge execution count needs cycle-stamped calls (`--ret-log`-style for functions): today the count is over the whole run, said.
5. Physics collaterals: net-current (ngspice at the node's CircuitState, TMAX = the node's step) and temperature (Cauer over the edge's duration) - the hooks exist (`StructNodeCollateral.engine`), the engines are not called yet; words say so.
6. ~~Seed the UNO light Bench System / Bench Solution rows~~ DONE in bss-8 (board_seed: SEED_BENCH_*); cfg-1 (the clock group's checks, the shipped UART config proof,
   a Firmware Solution per route whose configuration drives the build) is still the next catom-config slice.
7. The Structs page's samples (StructFieldSamples) have doors only through the rows; a table on `/display/bench-views` would do.
8. `modules/cmod/custom/glue_builds/uno-sim-rig-graph.json` carries an older, unrelated uncommitted change; left alone.
