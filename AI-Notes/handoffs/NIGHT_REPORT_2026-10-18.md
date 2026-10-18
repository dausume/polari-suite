# Night report — 2026-10-17/18 ("do small fixes first then move on autonomously, work through the night")

Everything below is merged into `dev` (framework, angular, cli, rf-node, suite pointers) unless marked otherwise, each slice proven by its
selftests and most checked live on the econ-core test node (`pol deploy run econ-core --role node`). Decisions I took without an explicit ruling
are marked **(taken, yours to overturn)** — all were my recorded recommendations.

## What you can look at
| page / command | what |
|---|---|
| `/display/pin-view` | the d3 pin view: concentric die → package → board, All · Drive · Signal modes, protocol/drive filters, phases (power-up … runtime) with the "after every reset the pins are blank" banner, an event timeline, and the **Candidate** stage drawing a solution the engine found |
| `/display/hardware-solutions?solution=mission-uno-light-mission` | the Hardware Mission drawing (Goal → Settings → one state per Purpose → Participants → Limits → Resolution) |
| `/display/pin-profiles`, `/display/profile-overlap`, `/display/isotope-variants`, Approach, Solutions found, Task plan, `/display/config-events`, `/display/register-profile`, `/display/memory-map` | the data behind it, as configured tables |
| `pol capability pins | pins-mission | colocation | approach | solve | tasks`, `pol cmod jobs | variants`, `pol board overlap | registers | memory | pin-view | events | exposure | reach | ladder | systems | links | paths` | the same from the CLI |

## The chain built tonight (MISSION_PROFILE_SOLVER_PLAN §9–16, FIRMWARE_GENERATION_MODULE_PLAN §9–11, PIN_VIEW_PLAN §9–11)
1. **Hardware Mission no-code** — Purposes as states (your ruling), objective setting minimum-resources | fastest-cycle (your cycle definitions).
2. **Pin profiles** per Purpose / per Mission — the light Mission needs 5 (transport rx/tx reserved, LED, button, sense line).
3. **Isotope variant catalogue** — 22 routes for 6 jobs; status DERIVED (declared → compiles → proven-on-twin); SPI/I²C routes blocked on your bench by the missing part (named).
4. **Overlap table** — 459 cited verdicts (pin / net / peripheral) for the ATmega328P; per-Mission co-location.
5. **Runtime recommender** — bare-c on the UNO (provisional until cycles are measured — cyc-0 running); FreeRTOS blocked by 2 KB SRAM, Zephyr by no AVR port.
6. **Attempt engine** — hardware × tier × variants → pins, scored by the Mission's objective; every pruned branch has a reason; deterministic + replayable; with bench-wiring preference it reproduces D2 / D6 / D3; wasteful routes scored worse, never excluded (your words).
7. **Task Plans** — five Tasks derived from the chosen candidate, deadline-monotonic priorities with importance ties, agreement check vs the code's schedule lanes, your edits kept beside derived values, Designed for written once.
8. **Three variants made real** — PCINT button, analog-threshold button, PWM LED: templates, compiled, twin-proven (with negative controls).
9. **Command confirmation (LightState v2)** — command ids echoed, confirmed only by its own id in the same boot session, reboot → "unknown, resend"; twin-proven. Built as a NEW variant beside v1: **your bench path (v1 firmware, Hardware Bridge deb, demo bundle) is untouched and still the default** — the switch-over list is in FGM plan §10.1.
10. **ESP32-C3 pin functions** — cited from Espressif's datasheet/TRM/module/devkit docs; the engine now places the light Mission on the C3 under FreeRTOS.

## Decisions taken (yours to overturn)
- D-msp-1..5: importance scale safety | required | important | desired; profiles derived with corrections; overlap rules per SoC family; slice order; search in the backend.
- Engine knobs: pin SHARING off by default; "least specialised pin" = derived scarcity; strapping pads penalised on the C3.
- v2 as a parallel contract/variant (not a v1 change).

## Things to know
- **Disk incident:** pol-core's root disk hit 0 MB mid-night (finished agent worktrees + screenshot Chrome profiles). Cleaned; rules added; ~5.7 GB free now (95 %).
- **The `*.json` ignore** cost one set of files (rebuilt + force-added). Rule now in every brief.
- **A silent-push trap** (selftests churn glue-build timestamps → a "clean tree" guard skipped a push) — caught; rule added.
- **Found + fixed live:** the solve door silently ignored a top-level `prefer` (now accepted, unknown keys refused); the transport could be paired onto the bridge's net in the co-location report (now reserved at net scope); the pin view's first read after a backend boot failed (now one retry); the stale command-id hazard in v2.
- **Test-node boot is ~31 min** (healthcheck grace raised to 60 min); debts recorded in HARDWARE_SYSTEM_PINS_PLAN.

## Still open / owed
- cyc-0 (measured cycles) and fgm-5b (sense-route templates + Task Plan / Hardware System link) are building now.
- Record the fgm-5a / v2 ScenarioRuns on the live stack; roll the night's work to pol-core (last roll had rp-0 … pv-2).
- The sense Purpose has no latency criterion, so the engine polls D3 (cheaper); add one if every edge must be caught within N ms.
- The C3 board's header map (rung 3), the N4/N4X variant; v2 switch-over (your word); the atoms → "steps" page sweep; your reminders ledger (part photos, fuses, the UNO plugged in for Detect).
