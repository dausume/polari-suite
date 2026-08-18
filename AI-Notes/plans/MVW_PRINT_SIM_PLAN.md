# MVW Print Simulation — Multiscale Plan (for the next instance)

**Dustin's directive (2026-07-06, end of the msci run):** test the MVW (Minimum
Viable Wax) formulations via multiscale simulation of a screw-auger pellet
extruder printing them. Feed is assumed ("magically" supplied pellets — no
hopper dynamics). Assign materials to the screw auger and heating tube.
Parametric assembly SIZE to study size→flow effects. Multiple test beds,
choosable bed conditions + nozzle size, sweep temperatures, and CONTROLLED
AMBIENT temperature (e.g. printing inside a fridge — physically doable, so
simulate it). **Optimization objective: accurate, thin walls.**

On fans: Dustin suspects a fan just adds instability. Agree for an
uncontrolled fan (asymmetric convective noise); model convection as an
h-coefficient KNOB with presets (still-air / fridge-still / gentle-ducted)
so the question is answered by simulation rather than assumption.

## What this run provides as inputs (all live)
- **Formulations**: strict fossil-free MVW blend (beeswax base + carnauba 10%
  + rosin 17.5% + grog-1µm 2.5%, score 0.610) and the 'any'-policy reference
  (PE-wax variant, 0.616) from `/api/msci/composites/refine`. Sourcing policy
  knob decides which family is under test.
- **Thermal data**: ThermalProcessingProfile rows (notebook + Dustin-dictated
  rosin + labeled literature fills). Blend compounding window [150, 184]°C;
  print temp is the BLEND melt — my window model is component-conservative
  and does NOT do eutectics, so blend melt is a parameter with prior
  ~90–120°C until measured (flagged honestly in the sim).
- **Viscosity(T)**: notebook MFI estimates + Dustin's η = K/MFI relation
  (notebook IMG_2825). K is a knob per his note (temperature + load
  dependent).
- **Machinery to reuse**: MaterialCondensationState (Newtonian cooling +
  melt line — IS the bead-solidification physics), multi_scale_stages gates,
  multi_scale_search + batch_refine (condition optimization), FEM engine
  (barrel conduction, already validated), SimSpace3D + per-phase textures
  (bead visualization), coupling machinery (wind→pendulum pattern),
  msci-engines worker + dask (parallel condition sweeps), resource-aware
  batch guard (sweeps will be big).

## Multiscale decomposition (3 scales + environment)

### Scale A — device (mm, continuum): screw + barrel + nozzle
- **SimState classes** (new, simulations/ module conventions):
  ExtruderDeviceState — screw geometry (diameter, pitch, RPM), barrel
  (length, bore, wall thickness), nozzle (diameter 0.2–1.2 mm knob, land
  length), all scaled by ONE `assembly_scale` knob (Dustin: test size→flow).
- **Device materials are objects** (object coherence): screw + heating-tube
  materials get MaterialsScienceMaterial identities with level-1
  MaterialScaleDefinitions carrying thermal conductivity (stainless ~15,
  brass ~110, aluminum ~205 W/m·K — literature-labeled). Barrel wall
  gradient via the existing `fem.conduction` EngineComputation path.
- **Flow model, no-code-visible where possible** (matrix equations, like the
  melt-line): screw drag flow Q ≈ ½·π²·D²·N·h·sinφ·cosφ (simplified,
  magic-feed assumption), nozzle Hagen-Poiseuille ΔP = 8·η(T)·L·Q/(π·r⁴),
  η(T) from K/MFI with MFI(T) interpolated from the notebook estimates.
  Outputs: melt exit temperature, volumetric flow, pressure (compare against
  the profile's ExtrusionPressure target band — this DEFINES that metric).
- **Gate** (existing thermal machinery): barrel max wall temperature must
  stay inside the formulation's processing window (volatile refusals reuse
  thermal_windows verbatim).

### Scale B — bead/road (sub-mm): deposition onto bed or previous layer
- BeadDepositionState: bead leaves nozzle at exit temp with width =
  nozzle⌀ × flow multiplier; slump/spread rate ∝ 1/η(T) while above
  solidification; **wall accuracy metric = final width deviation from
  commanded thin-wall width + sag before solidification**.
- Cooling: Newtonian with h from the ambient preset + conduction into
  substrate (bed material for layer 1, previous wax layer above). This
  operationally DEFINES Dustin's AirSolidificationRate (1/ms): the fitted
  rate constant of the bead's cooling-to-solid — closing the metric gap the
  worksheet left open.
- **Reuse MaterialCondensationState**: the bead is the condensation ball
  with different geometry + boundary conditions; phase gate = solidified
  before next-layer arrival time (printing speed knob).

### Scale C — microstructure (µm): crystallization quality
- Per Dustin's processing-knob notes: cooling RATE → grain character
  (fast quench → fine grains → better walls). First pass: qualitative
  banding (quench / moderate / slow) derived from Scale-B cooling curves,
  attached to the wall-quality score; full CGMD is a later
  MaterialScaleDefinition level-2 row, not this plan.

### Environment (the knobs Dustin listed)
- `ambient_temp_c` (fridge 4°C / cellar 12 / room 22 / warm 30) — the
  controlled-fridge scenario is a first-class preset.
- `bed`: material rows (glass, aluminum, wax-coated, painter's-tape/paper)
  each with conductivity + surface energy note; `bed_temp_c` knob
  (chilled beds allowed — fridge scenario).
- `convection_h`: still-air / fridge-still / gentle-ducted (the fan
  question, answered with data).
- `nozzle_temp_c`, `print_speed`, `layer_time`.

## Optimization (the point): accurate thin walls
Condition vector = (nozzle_temp, bed, bed_temp, ambient, nozzle_⌀,
assembly_scale, speed). Objective = thin-wall score: width error + sag +
"solidified before next layer" gate + adhesion floor (LayerAdhesionStrength
from the formulation data). Engine = batch_refine's adaptive stepping over
the condition vector (it optimizes any scored vector, not just wt%) with
multi_scale_search's parallel/dask backend for sweeps; every refusal
evidence-bearing per knobs-and-suggestions. Deliverable: per-formulation
"print recipe" (conditions + predicted wall accuracy + trajectory).

## Phases for the next instance (branch-per-confirmed-phase, off dev-msci-11…)
1. **msim-print-1**: Scale-A device sim (states + matrix-equation flow +
   fem barrel gradient + window gate). Selftest vs hand-computed
   Hagen-Poiseuille numbers.
2. **msim-print-2**: Scale-B bead deposition (condensation-machinery reuse,
   AirSolidificationRate defined + emitted). Selftest vs analytic Newtonian
   cooling.
3. **msim-print-3**: coupling + stages (A feeds B like wind fed pendulum),
   SimSpace3D wall scene (bead rows, per-phase textures), msim page panels.
4. **msim-print-4**: condition optimization runs (both sourcing policies),
   size-scaling study, fridge-vs-room comparison, fan question. Report.
5. Later/optional: Scale-C beyond banding; measured blend-melt correction
   (one DSC-style measurement replaces the eutectic prior).

## Cautions for the next instance
- Blend melt point is a PRIOR (~90–120°C), not data — surface it as an
  explicit assumption on every result until measured.
- η = K/MFI: K is per-device per his note — make it a calibration knob the
  first real print will pin.
- Resource-aware guard ON for sweeps (StepCostProfile machinery exists).
- Live-verify per phase on staging; twin-B runs the combo DB mode; heavy
  sweeps can use the lightweight machine's worker (192.168.0.66:9500 up,
  dask profile available in docker-compose.remote-worker.yml).
