# Prototyping views — pins · circuit states · layout (ptv) — PLAN, 2026-10-19 (nothing built)

His words (2026-10-19, quoted):
- "It is not just a single breadboard layer, the goal is to make it so that we can eventually have a general renderer for complex layouts spanning N boards
  whether they are breadboards, protoboards, or dev-boards. So our render engine for this should be keeping that in mind. We are also going to want an
  electronics simulator that pairs with these simulations."
- "But the different views need to be kept separate but bound logically so we can see things more easily per view and understand. The pins view for
  understanding pin behavior and linkages, where electronics are simplified into drive behaviors per pin and pin connection."
- "And then the electronics circuit section is something separate that we need, where we are able to determine how many electronic states exist. For
  example, when we press the button on/off is it changing the way the board is acting as an electronics circuit? We will want to track all varying
  'electronic circuit state changes' and what events in the firmware they are tied to. This way we can have a list of different electronic circuit
  simulations and have an understanding of how our spice simulations should change based on our firmware simulations. Blending the logic of the two, but
  using a dedicated circuit visualization page for doing so."
- "And then a page that is dedicated to only component, pin, and other kinds of placement, slotting components and pins to breadboards and protoboards, and
  potentially PCBs down the line. We want to be able to use this same engine to gradually iterate through all prototyping phases."

This plan is the UMBRELLA. BREADBOARD_BUILD_PLAN (bb) becomes its layout slice: bb-3's "pin-view layer" is REPLACED by the layout view below.

## 1. One model, three separate views
All three read the SAME objects: components (instances of KitParts / devices), their pins, the nets between them, the boards they sit on, and the firmware
that drives them. Each view projects one concern. A selection in one is a shared reference (`{kind, name}`), so the others can highlight it. They are linked
by URL scope (`?component=`, `?net=`, `?state=`), never merged into one picture.

| view | page | question it answers | electronics shown as |
|---|---|---|---|
| **Pins** (exists: pin-view arc) | `/display/pin-view` | which pin does what, linked to what, in which phase and stage | drive behaviours per pin and per connection (supplies / supplied / returns / high-impedance …), no values |
| **Circuit** (NEW) | `/display/circuit-states` | how many electronic states the circuit has, which firmware event moves it between them, what SPICE says in each | a schematic of components and nets, with the circuit state chosen; numbers from SPICE |
| **Layout** (NEW, the bb work generalised) | `/display/layout` | where every component and pin physically goes, on N boards of any kind, step by step | holes, rows, rails, header pins, wires; a 2-D part per component |

## 2. The circuit view — electronic circuit STATES (slice `cst`)
**What it is.** A circuit state is one assignment of every component's electrical mode. Examples:
- pushbutton open | closed (exists in ucd-0c);
- LED forward-biased | off;
- a GPIO pin driven-high | driven-low | input-pullup | high-Z;
- transistor cutoff | saturated;
- an ADC input sampling.

Two states differ when the netlist SPICE would solve differs (a switch resistance, a source's value, a pin's mode).

**Enumerating the states, without exploding.**
- The candidate space is the product of each component's modes.
- It is PRUNED to what is REACHABLE, read from the firmware's own behaviour:
  - the pin-mode timeline the twin records (cyc-0 / ScenarioRun traces);
  - the config events (pv `config_events`: init sets pin modes);
  - the external events the scenarios inject (a button press).
- Each reachable state gets a stable name, e.g. `idle-led-off`, `button-held-led-off`, `led-on`.

**Transitions.** Each transition is a row, `CircuitStateTransition`: from-state → to-state, the trigger, its timing, and the evidence run. Triggers come in three kinds:
- a firmware event (the `led_follow_state` task writes D6; `apply_command` …);
- an external event (the button pressed / released);
- a power/lifecycle phase (reset → every pin high-Z).

**SPICE pairing (the "electronics simulator that pairs").**
- **Phase 1:** each state gets one `.op` operating point run through the existing ngspice path, stored as a `CircuitRunResult` with the state's name. That gives the
  currents and voltages per state: the LED current, the pull-up current while the button is held, the pin's source current against its abs-max.
- **Phase 2 (co-simulation):** a transient run whose sources follow the firmware twin's pin timeline. The level bridge (ncg-6) already binds a logic output to a
  voltage source; here the "logic" is the simavr pin trace. SPICE then shows edges, debounce windows and the LED rise, aligned with the firmware events.

**What it feeds back.**
- Per-pin currents against `PinElectricalLimit` (rung 7 of the availability ladder: "electrical, unchecked" becomes checked).
- Per-state power, which is the Battery profile's active-current term (fsc-4).
- A state the firmware reaches that SPICE flags (an over-current, a floating input) becomes a finding on the Mission.

**The page.**
- A list of states; a schematic with the chosen state applied (open/closed switches drawn as such, active parts tinted).
- The transitions as a small state graph, each edge labelled with its firmware event.
- The SPICE numbers per state, in tables.

## 3. The layout view — a general N-board renderer (slice `lay`, absorbing bb)
**Boards are objects of one family.**
- `BoardModel` kinds: `breadboard` (half, full), `protoboard` (later), `devboard` (the UNO, the C3 devkit: their header geometry), `pcb` (later, from the pcb module).
- Each physical board is an instance. A layout = N board instances + their positions + placements (component pin → hole/pad/header) + wires (any hole or pin
  → any hole or pin, on the same board or across boards).
- The tie-point grammar extends per kind: breadboard `r<N><col>` + rails; devboard header pins = BoardPin refs; protoboard pads; PCB pads/footprints.

**One renderer.** A tiled 2-D canvas of N boards (pan/zoom), with each board drawn from its model's geometry. Parts are 2-D sprites from part geometry; wires are
curves in their effective colours (the WireColorScheme). Its layers: boards → parts → wires → highlights (the selection, the current step).

**Placement editing** (this page is ONLY placement). Slot a component or wire into holes:
- a derived placement (the placer) plus a person's overrides kept beside it;
- the netlist gate (the layout's compiled nets must EQUAL the design's nets);
- the electrical rules.

**Through the prototyping stages with the same engine.** S1 breadboard → S2 protoboard → S3 PCB. The design's nets stay the same; the boards and placements
change. A stage's layout is a new layout over the same nets, and the gate proves each one.

**Walkthrough.** The bb-2 build steps play on this renderer (step k shows steps 0..k), and confirmation comes before binding (bb-4), unchanged.

## 4. The pins view stays as it is
It stays the drive-behaviour view. It gains only the shared-selection links (a pin → its net in the circuit view → its hole in the layout view).

## 5. Slices (after the running smp agents land; one or two agents at a time)
- **ptv-0, the shared model seam:** component instances, pins and nets as the ONE reference set the three views read. These are mostly existing rows: KitPart,
  BoardPin, the circuit level's components and nets, and hsp's SystemLink. Plus the shared-selection URL scope.
- **cst-0:** the per-component mode catalogue, reachable-state enumeration from the twin traces + config events, the states and transitions as rows, and `pol circuit states <config>`.
- **cst-1:** a `.op` SPICE run per state (the existing ngspice path), stored as CircuitRunResult rows; per-pin current against the limits.
- **cst-2:** the circuit-states page (state list, schematic with state applied, transition graph, SPICE tables).
- **lay-0 (= bb-0 generalised):** the board family objects (breadboard half/full, devboard UNO; protoboard and PCB reserved); layout rows; the WireColorScheme.
- **lay-1 (= bb-1 + bb-2):** the placer for S1 + the netlist gate + the build steps.
- **lay-2:** the N-board renderer + the layout page + step mode.
- **lay-3 (= bb-4):** confirmation → bind.
- **cst-3:** the transient co-simulation driven by the firmware twin's pin timeline.
- **later:** protoboard; PCB through the pcb module.

The first proof is S1 (uno-light + sense jumper):
- its circuit states (at least: idle-off, button-held, led-on, led-on-button-held);
- the firmware events on each transition;
- a `.op` per state with the LED current and the pull-up current;
- its breadboard layout beside the UNO;
- stepping through the build;
- a click on D6 in any view lights it in the other two.

## 6. Decisions (his)
- **D-ptv-1:** The renderer is d3/SVG like the pin view, as ONE sanctioned new component (`hardware-layout-view`) and ONE for the circuit schematic. Neither is a
  per-page custom component. Recommend yes.
- **D-ptv-2:** The circuit-state definition, "two states differ when the SPICE netlist differs". Recommend yes. Purely logical firmware states that do not change the
  netlist are NOT circuit states (they stay Task Plan / Mission states).
- **D-ptv-3:** SPICE pairing order: `.op` per state first, transient co-simulation second. Recommend yes.
- **D-ptv-4:** How the views are bound: shared references + URL scope, with no merged "everything" view. Recommend yes.

## 7. Status 2026-10-19 — lay-0 + lay-1 BUILT + MERGED (electrodevice)
- Objects: `BoardModel` (breadboard half = 30 rows / 400 ties, full = 63 rows / 830 ties, 2.54 mm, counts derived from the geometry; devboard UNO from
  BoardPin rows; protoboard/pcb reserved, refused in words), `BenchBoard` (the instance: `bench-half-1` default, `bench-full-1`, `bench-uno-1`; the old
  BreadboardDefinition seeds converge onto it), hole grammar `r<N><a-j>` + `rail:<top|bottom>:<+|->:<N>` (old `r<N>L/R` kept), `BoardJumper.kind`
  jumper|header + `colour_override`, `WireColorScheme` (`wires-pin-view` seeded from the pin view's palette, copy-before-edit), `LayoutEdit`.
- Placer + netlist gate + derived build steps (never stored); doors `/api/layout/boards`, `/api/layout/<config>[?board=]`, `…/steps`, `…/edit`,
  `/api/layout/wire-colors`; `pol board layout <config> [--board] [--steps]`, `pol board wire-colors show|copy|set`.
- S1 on bench-half-1: SW1 straddles the trench (rows 3/5, e–f); R1 220 Ω rows 7–11 hole e; LED anode r11d, cathode r12d; GND rail wire black; D2→r3a grey,
  D6→r7a orange, the sense jumper D3→r7b grey (stand-in until smp lands `sense_pin`). Gate OK: 4 layout nets == 4 design nets. The backwards LED and the
  missing resistor are refused in words. Selftests: layout 89/89, electrodevice 114/114.
- Undetermined: the bench breadboard's size (default half); TMP36/transistor pinouts proven only on a synthetic design; layout knobs (spans, start row) labelled.

## 8. cst-0/1 design settled 2026-10-20 (nothing built yet — to be built in-session)
- **ngspice:** `electrodevice.circuit_api.run_netlist` runs a LOCAL binary (`NGSPICE_BIN` → PATH → `~/tools/ngspice/bin/ngspice`, present on pol-core); no
  image or worker seam exists (one is a later engines slice).
- **Limits already exist** in `board.custom.electrical_atmega328p`: `ElectricalCharacteristic` I_PIN abs-max 40 mA / recommended 20 mA, RPU 20–50 kΩ
  (DS40002061B Table 30-1 p.323); `PinGroupBudget` 200 mA VCC/GND abs-max (§29.1 p.308). There is NO `PinElectricalLimit` class — use these.
- **Rung 7 reader:** `ladder._rung7` reads only `electrical_check.check` findings → add a small reader for SPICE pin currents from `CircuitRunResult`
  rows (a `config` key in the ladder context).
- **Pin evidence:** init modes from the HAL (`hal_button_init` D2 pull-up, `hal_led_init` D6 output, `hal_sense_init` D3 input); `press_records/uno-light.json`
  (press → D6 rise, 0.013–0.023 ms); no `uno-light` cycle record (nearest `uno-light-unsensed`); `BenchInteraction` rows live only.
- **S1 states (6):** idle-led-off, button-held-led-off, led-on, led-on-button-held, reset-high-z, reset-button-held. **Transitions (~18):** press/release
  external; D6 by firmware (`led_toggle` → `led_follow_state` on a press; `apply_command` → `led_follow_state` on SET_LED); boot/reset lifecycle. Only the
  press-driven rise has twin evidence; the rest are read from the source and must say so.
- **`.op` plan:** D6 an ideal 5 V source (worst-case upper bound); the D2 pull-up through a 0 V ammeter at 20 kΩ and 50 kΩ; a 0 V ammeter in series with the
  LED; checks against 40 / 20 / 200 mA; a structural floating-input rule (a net with no driver, pull-up, or closed switch to ground); no engine → 424.
- **Files to write:** `electrodevice/custom/cst_modes.py`, `cst_sources.py`, `cst_netlist.py`, `cst_verdict.py`, `circuit_states_api.py`,
  `circuit_states_selftest.py`; rows `CircuitState`, `CircuitStateTransition` (register: feature_imports, polariServer defClassList, module_endpoints,
  manifest regenerate); the rung-7 hook; `fsc_values.active_current`; `polari-cli/scripts/circuit.sh` + index entry.
