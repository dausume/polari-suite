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
| docs | pol-hub | "How Polari works for hardware" (`AI-Notes/guides/HARDWARE_NOCODE_GUIDE.md` -> `pol-hub/site/docs/hardware-nocode.html`); build-docs renders mermaid fences | `build-docs.py --check` clean |

## How to run it (from polari-framework/, `PYTHONPATH=.:modules`)
- the pure selftests: `python3 -m cmod.cmod_bench_topology_selftest`, `cmod.cmod_bench_canvas_selftest`, `cmod.cmod_coverage_selftest`, `board.board_bench_solution_selftest`
- the twin-backed ones (need the avr engines: the local `prf-board-engines:trixie` image; rebuild it from prf-board-engines/ with
  `docker compose -p board-engines -f ../docker-compose.board-engines.yml build` - there is no `pol` wrapper for it; `strings` is not in the image, grep -a the binary):
  `cmod.cmod_node_run_selftest`, `cmod.cmod_confirmations_selftest`, `cmod.cmod_retest_selftest`, `cmod.cmod_command_edge_selftest`
- the long suites (never two board_selftests at once): `python3 -m board.board_selftest` (~28 min), `python3 -m cmod.cmod_selftest` (~26 min)

## Gotchas found (so nobody re-finds them)
- the generated packets header declares struct members SORTED BY NAME; the layout comes from firmware_state's parsed order, not the struct map's draft order
- a line held low for ever is not a press (the UNO light toggled twice): a press is a 5 ms pulse (knob `PRESS_HOLD_CYCLES`)
- the shipped hex inlines every atom: executions are counted in the -fno-inline build and over the WHOLE run (`led_toggle` runs every loop pass)
- `pgrep -f` in a wait loop matches its own command line; wait on a PID instead
- the twin's final line reports a watched word as `final`, not `value`

## Owed / next
1. The Chrome pass of the new pages and the canvas (`/display/hardware-events`, `/display/bench-solutions`, `/display/hardware-solutions?solution=bench-topology-<bs>`): needs a deploy (the user's call).
2. Stimuli still refused in words: reset (`--reset-at`), environment levels (`--adc0-mv` / ramp), periods. Then the TMP36 "level" events and the samples block get a real run.
3. The failure WaveformCapture (3c): feed the osc arc's emulated endpoint from the run's events instead of inventing a capture record.
4. A per-edge execution count needs cycle-stamped calls (`--ret-log`-style for functions): today the count is over the whole run, said.
5. Physics collaterals: net-current (ngspice at the node's CircuitState, TMAX = the node's step) and temperature (Cauer over the edge's duration) - the hooks exist (`StructNodeCollateral.engine`), the engines are not called yet; words say so.
6. Seed the UNO light Bench System / Bench Solution rows (today the selftests build them in a fake manager); cfg-1 (the clock group's checks, the shipped UART config proof) is still the next catom-config slice.
7. The Structs page's samples (StructFieldSamples) have doors only through the rows; a table on `/display/bench-views` would do.
8. `modules/cmod/custom/glue_builds/uno-sim-rig-graph.json` carries an older, unrelated uncommitted change; left alone.
