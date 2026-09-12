# Wax 3D-Printer ("magic 3D printer") — Voxel Print Sim

**Dustin 2026-07-17:** simulate a pellet-fed **auger-screw** wax extruder
printing an engineered all-natural wax. Control the **auger-screw** and
**hotend/spout** temperatures separately; emulate pellets going in and
**liquid** coming out per the wax's computed material properties. Optimize
over nozzles, temperature combinations, and **fan wind-vector** effects.
Identify ideal print approaches, nozzles, and **bed / nozzle / melt-chamber
/ auger materials**. Prove the core physics ("this should be 3D-printable
this way"), prove the **basic printer movement patterns** are viable, and
find **what print-VOXEL resolution** is reachable **under what conditions
and at what build height** — repeatable, with small margins of error.
Respect the wax **melt-safety range**. Later: **melt voxels** (laser
ablation) in the same voxel language.

New module: `polari-rf-node/polari-framework/waxprint/`. Built on the
[[materials-science-module]] engines, the `MaterialCondensationState`
cooling physics, the `mathshapes` geometry, and the aquaponics module
wiring pattern. Branch `dev-wp-1-auger-melt` (all four phases in the
working tree; see "commit note").

## Status — ALL FOUR PHASES BUILT + SELFTEST-GREEN (78 checks)
Also verified **in the live prf-backend Alpine image** (pure-python, no new
deps): auger_melt 25/25, bead_voxel 21/21, movement 17/17, optimizer 15/15.
NOT redeployed to staging (would cold-reseed the running stack); NOT pushed.

### wp-1 — two-zone auger melt + wax safety gate (`auger_melt.py`, `melt_analysis.py`)
Screw drag conveying (magic feed) → residence times per zone → a
**lumped-capacitance pellet with a latent-heat ENTHALPY plateau**
integrated through the auger zone then the hotend zone (the plain
exponential is only valid with no phase change — the melt STALLS the
temperature rise). Honest **Biot-number** gate: a 3 mm wax pellet is
thermally thick (Bi≈0.5), so lumped melt fraction is flagged an optimistic
bound (radial FEM is the upgrade). Molten exit → Arrhenius η(T) →
**Hagen-Poiseuille** nozzle pressure. **Safety** = evidence-bearing
refusals: hotend above the wax degradation ceiling, below melt margin,
under-melted, and a **part-material service-temp** axis (a PTFE-lined
nozzle fails long before the wax does). Validated vs hand-computed
conveying, closed-form cooling, energy conservation, and the plateau map.

### wp-2 — bead → print VOXEL + the fan question (`bead_cooling.py`, `voxel_resolution.py`, `bead_analysis.py`)
Deposited bead cools by Newtonian convection + substrate conduction (bed
material k matters) with the latent plateau in reverse. **The fan is a
WIND VECTOR**: forced convection via the **Hilpert Nusselt** correlation
raises h (speeds freeze, less spread → finer voxel) but adds a **warp
asymmetry** (windward vs sheltered) — so "gentle ducted good, bare fan
warps" is computed, not assumed. Gravity **viscous spread** (lubrication
h³ leveling) sets the final bead width. A **print voxel** = (bead width,
layer height); **margin** = the repeatability band from a ±3 °C
temperature-control wobble. `resolution_profile()` gives the
**resolution-at-height** table (heat accumulates → warmer substrate →
coarser voxel up high). Validated vs an analytic no-latent cooling closed
form (0.03 %). *Melt-voxel (laser) seam noted for later.*

### wp-3 — movement-pattern viability (`movement_patterns.py`, `movement_analysis.py`)
Seven standard toolpaths scored from the bead result with physical
criteria + named limits: **perimeter** (thin-wall accuracy), **infill
raster** (bonding/turnaround), **travel/retraction** (low-viscosity
stringing), **sharp corner** (blob), **small circle** (min radius ≈ 1.5
voxels), **bridge** (sag before freeze), **z-hop/layer** (top solid before
next). Worst-wins roll-up, optionally **at a build height**.

### wp-4 — trials/optimizer + report (`print_optimizer.py`)
Sweeps ephemeral trial conditions × assemblies × feedstocks through
wp-1→wp-2→wp-3; scores fineness + repeatability + movement − warp, subject
to the safety gate (unsafe/unprintable **excluded**, not scored); trial
cap logged, never silent. Report answers: best recipe, best per resolution
class, **fan verdict**, **fridge-vs-room**, and **nozzle / bed / chamber /
auger / feedstock material rankings**.

## Headline result (seeded sweep, 192 trials)
**Best recipe: carnauba-rich wax on the demo auger extruder, fridge +
gentle ducted fan, hotend 110 °C / auger 90 °C, 0.25 mm brass nozzle,
20 mm/s → voxel 0.282 mm (fine class), repeatability margin 0.6 µm, all 7
movement patterns viable.** A controlled fan HELPS; fridge beats room;
brass nozzle > hardened-steel > PTFE; carnauba > MVW blend (harder, more
viscous, wider safe window). Room-temperature still-air printing scores
poorly (slow freeze → spread, blobs, sag, stringing — only 2/7 patterns).

### wp-5 — registered multiscale sim space + SimSpace3D scene (`sim_state.py`, `sim_runner.py`, `sim_seed.py`)
The printer is now a first-class **registered** simulation you can view in
3D. `WaxPrintSimState` = one persisted step whose "time" axis is BUILD
HEIGHT; the `sim_runner` populates a run's rows from the wp-1..3 physics
(the validated Python engine drives it, like the msci engines — not the
no-code step engine). A `SimulationDefinition` (`wax-print`) + a
`MultiScaleSimulationDefinition` (`wax-print-multiscale`) + a **SimSpace3D
scene** (`wax-print-wall`) render a stacked column of bead voxels
colour-coded by print state (red=unsafe, amber=printable-coarse,
green=meets-target), scale ∝ voxel width. **Two baseline runs are
pre-computed at seed time and render side by side**: a room-temp demo
(amber, voxel 0.63→1.12 mm — resolution visibly degrading with height) and
a cooled fine recipe (green). An IC picker + a display page (`/wax-print-sim`)
present it. All seeds append to the shared framework lists on import.

### wp-6 — condition-evaluation gates + live equations + range runs (`sim_evaluation.py`, `sim_api.py`)
Seven **condition gates** as data — thermally-safe, fully-molten, printable,
voxel-meets-target, margin-within-tolerance, movements-viable,
resolution-holds-with-height — each reporting met/not-met with the worst
value, threshold, failing steps, and a knob. Five **SimSpaceEvaluationEquation**
overlays (LaTeX + field bindings) show live values on the scene (melt
fraction, voxel headroom `t−x`, margin, movement fraction, warp). Runs:
`POST /sim/run` (one initial condition), `POST /sim/run-range` (a range,
ranked by gates met), `GET /sim/evaluate?run=`. On the seeded runs the room
demo meets 4/7, the fine recipe 6/7; a swept range gives room 4 → fridge 5
→ fine-voxel 6.

### wp-7 — `WaxPrintOperation` no-code node (`commands.py` + engine dispatch + registries)
A no-code Operation state (cloned from msci-18 `EngineModelOperation`) that
runs one wax-printer **command** from a solution graph. `commands.py` is
the single dispatch surface (`run_command(manager, command, inputs)`); the
engine branch in `SolutionExecutionEngine.py` resolves `inputBindings` →
runs the command → writes outputs as `waxprint.<key>` + `resultKeyMap`.
Registered in all three mirrored partitions (backend
`BACKEND_ONLY_RUNTIME_CLASSES` + the two TS sets) plus a palette
`registerClass` entry (Physics/Chemistry).

**As much as feasible is manipulable from no-code:**
- **7 computable commands** — `melt`, `bead-voxel`, `movement`,
  `print-step`, `optimize` (sweep → best recipe), `resolution-profile`
  (→ finest/coarsest/degradation), `evaluate-run` (→ condition gates met).
- **Every physics command accepts scalar OVERRIDES** (`OVERRIDE_INPUTS`:
  hotend/auger temp, rpm, nozzle diameter, ambient/bed temp, print speed,
  layer height, convection preset, fan `wind_mm_s`) layered on the named
  condition — so a graph can vary ANY knob and see the effect without
  editing a row (the seam for shape-optimization loops).
- **3 declared printer-control commands** (`move-to`, `set-temp`,
  `extrude`) refusing honestly until the gRPC bridge is wired.
- **Discovery**: `GET /api/waxprint/commands` returns the vocabulary +
  overrides so an author knows what's manipulable.
- The config objects (assemblies/feedstocks/conditions/materials) are
  already auto-CRUDE, so they're editable in no-code too.

`selftest_wax_print_op` runs the commands + overrides through the real
`SolutionExecutionEngine` (11/11): a graph-supplied finer-nozzle+fridge+fan
override drops the voxel 0.63→0.34 mm; honest refusals for unknown/planned
commands and missing rows.

### wp-8 — no-code sim step + Polari Module registration
- **No-code step** (`sim_step_seed.py`): a SolutionDefinition
  `SimulationStateStep → WaxPrintOperation(print-step) → SimStepNextState`
  + a `SimulationExecutionSolution` row, so the standard `SimulationRunner`
  advances the sim **entirely through the no-code engine** — the operation
  runs the physics, the terminator projects its outputs onto the next
  `WaxPrintSimState` row (config refs carried on the row make it
  self-contained). `selftest_sim_step` drives the full graph through the
  same engine the runner uses (9/9): voxel/melt/safety project onto the row,
  and an over-ceiling condition projects `thermally_safe=0`.
- **Module**: `waxprint` is now a first-class **Polari Module** — a
  `FRAMEWORK_BOUNDARIES` entry (so "Wax-3D-Printing" appears in the
  module-dependency explorer with auto-scanned edges) **and** a
  `PolariModule` identity row (name `Wax-3D-Printing`, manifest listing the
  no-code commands + sim space + planned printer-control) surfaced via
  `GET /api/modules`.

**Toward direct printer control:** the command layer is the seam — a
simulated toolpath and a printed one speak one vocabulary. Shape-optimize
→ toolpath → `move-to`/`set-temp`/`extrude` commands (sim-predicted now,
gRPC-bridge machine instructions later) is the roadmap the stubs establish.

## API (`waxprint_api.py` + `sim_api.py`, `/api/waxprint`)
`GET /capability|/materials|/assemblies|/feedstocks|/conditions`,
`POST|GET /melt`, `GET /voxel`, `GET /resolution-profile`, `GET /movements`
(`?height=`), `POST /optimize`, `POST /sim/run`, `POST /sim/run-range`,
`GET /sim/evaluate?run=`, `GET /sim/runs`.

## Objects (all auto-CRUDE + seeded, `waxprint_basis.py`, `waxprint_seed.py`)
`DeviceMaterialDefinition` (nozzle/auger/chamber/bed — k, max service temp,
adhesion), `WaxFeedstockDefinition` (props + **safety window**, links to
materialsScience wax + waxsupply source), `PrinterAssemblyDefinition`
(two-zone auger extruder, `assembly_scale` size knob, math-shape ref),
`PrintConditionDefinition` (two temps, rpm, nozzle, ambient/bed, **fan
vector**, speed, layer). Seeds: 8 device materials, 4 waxes, 3 assemblies,
6 conditions.

## Everything is a PRIOR until the rig measures it
Wax thermophysical values, the wall→pellet coupling h, viscosity K, the
spread constant k_spread, and the movement thresholds are labelled
calibration knobs (flagged in `notes` and carried into results). The blend
melt point is the ~90–120 °C eutectic prior. First real print pins them.

## Commit note
polariServer.py wiring shares the file with ~301 lines of uncommitted
ncg-2..5 work already in the tree, so the phases are NOT committed
separately (would entangle). All `waxprint/` files are new + self-contained.
Branch `dev-wp-1-auger-melt`.

## Next
1. Dustin review + browser check; then a staging redeploy (suite-root
   `docker-compose.staging-nip.yml`, `LOCAL_IP=<pol-core LAN address>`, cold seed,
   `pol-proxy nginx -s reload`) to live-verify the endpoints + seeds.
2. Scoring bridge: a `print-resolution-quality` ScoreConcept ranking
   persisted conditions (aqp-6 objectRef idiom) — deferred to avoid
   touching the scoring seed schema blind.
3. Radial-FEM pellet melt (kills the Biot caveat); device geometry as a
   `mathshapes` CSG (screw+barrel+nozzle) + a SimSpace3D wall scene;
   frontend page; **melt-voxel** (laser) sibling in `voxel_resolution`.
4. Angular UI: assembly/feedstock/condition editors, the resolution-at-
   height table, the movement-pattern verdict panel, the optimizer report.
