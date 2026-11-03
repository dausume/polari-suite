# KiCad and Polari electronics: shared model and sample projects

> **SHELVED 2026-11-03 — superseded by CX-033** (Polari is the source of truth; KiCad is an input and an output, not a sync peer). Its identity rules, sample order and failure controls are carried into `AI-Notes/plans/KICAD_INTERCHANGE_PLAN.md` ("Carried from the Codex KiCad/Polari plan"); the uno-light project it produced is the `polari-uno-light` kxc fixture in the framework.

Status: proposed implementation plan, grounded in the local code inspected 2026-10-29. No runtime/model changes or new electronics designs have been applied. Extends PCB_FROM_SCRATCH_PLAN.md and BOARD_PROGRAMMING_PLAN.md; does not replace their design-as-rows or person-directed placement/routing decisions.

Baseline: suite `62e2489`, polari-rf-node `8db3305`; local `kicad-cli version` reports 10.0.6. Repository documentation describes a 9.0.2 engine fixture. Treat these as different engine/library environments, not interchangeable export baselines.

## 1. Intended outcome

Build native, editable KiCad equivalents of Polari's existing electronics samples, backed by a richer Polari model that connects electrical design to firmware tasks, hardware bridge contracts, measurements and application logic. A tester should be able to traverse from a displayed state field to the firmware expression, MCU pin, connector contact, schematic terminal, PCB pad, net and relevant measured evidence.

Use an installed KiCad as a real local engine when available. Keep GUI editing, headless validation/export, analog simulation and firmware execution distinct capabilities. A successful KiCad launch does not prove ERC, SPICE, MCU execution or fabrication readiness.

## 2. Existing foundations and concrete gaps

All framework paths below are under `polari-rf-node/polari-framework/modules/`.

| Existing seam | What it actually provides | Extension needed |
|---|---|---|
| `board/custom/board_object.py`, `board/custom/board_pin_nets.py` | Board identity, SoC pins, connector pins, net bindings, signal direction; board-view conflicts | Stable design-instance identities and links to real schematic pins/pads and circuit configurations |
| `board/custom/views/kicad.py` | Deterministic KiCad `.net` view and pin assignment ingest | This is a netlist stub, not an editable complete schematic or full UNO electrical reproduction |
| `pcb/custom/schematic_writer.py` | Direct `.kicad_sch` writing, embedded symbols, deterministic UUIDs, labels and power symbols | Project/hierarchy model, layout intent, richer symbols/units, explicit optional/unknown pins and simulation properties |
| `pcb/custom/uno_shield.py` | Four UNO headers, TMP36, 220-ohm resistor, LED; derived header net assignment | Sensor pinout/MPN evidence, Arduino header geometry, complete reviewed project and PCB |
| `pcb/custom/kicad_read.py` | Schematic metadata/symbols; PCB parts, placements, pad-net counts and per-net route summaries | Full schematic terminal connectivity; stable UUID preservation; detailed copper/shape retention or native-file preservation |
| `pcb/objects/pcb/` | Part, Symbol, Footprint, LandPattern, Schematic/Sheet, PcbBoard, Placement, Route, DrcResult, FabricationExport, fab rules | Distinguish reusable definitions from placed instances; jobs, revisions, mappings, models and detailed design state |
| `electrodevice/objects/circuit/_shared.py`, `circuit_netlist_seed.py` | Circuits/components/nets as rows, SPICE renderer and runner | Bridge circuit identities to EDA instances; explicit ground/source harness, richer components and analysis configuration |
| `pcb/custom/pcb_engines.py` | Explicit worker URL -> local CLI -> local image -> topology provider -> refusal | Version/feature/library probes, structured jobs, compatibility policy and observable engine provenance |
| `pcb/custom/ingest.py` | ERC/DRC/parity, fab checks and export records | Preserve finding identities and source links, support version adapters, prevent stale results passing a changed design |
| `board/custom/variants.py`, `cmod`, `grpcbridge`, `hwnocode` | Sample firmware variants, task graphs, board twins, bridge and backend logic | Traceability contract joining configuration, electrical implementation and observable field semantics |

The stored `ecc83-pp` demo is an import/export regression fixture, not the first bench circuit to build. Its prior ERC/DRC results are repository-reported evidence, not a new run on this machine. Preserve its licence and source hashes.

## 3. Model: several coordinated views of one design

Names here are proposed concepts, not existing classes or API promises. Fit them to existing Polari classes before introducing new objects.

| Layer | Information to represent | Existing owner / proposed additions |
|---|---|---|
| Project and revision | Design ID, revision, parent, source files, configuration, KiCad format, library lock, content hashes | Extend Schematic/PcbBoard; add project/revision snapshot and source artifact manifest |
| Component definition | Function, actual MPN, ratings, tolerance, package, datasheet, provenance, simulation model | Reuse Part/ElectronicDeviceDefinition/Symbol/Footprint; separate logical definition and BOM grouping from occurrence |
| Component occurrence | Stable ID, refdes, symbol units, DNP/variant, value override, sheet instance, selected footprint | Add explicit component and symbol instances where existing classes cannot express them |
| Electrical terminals | Symbol pin number/name/type, package contact, footprint pad, stacked/multi-unit pins, power units | Link existing SocPin/PackageContact/ConnectorPin; add terminal and pad mapping with validation |
| Connectivity | Named nets, members, junctions, labels, ports, hierarchy, buses, differential pairs, intended NC | Reuse BoardNet and CircuitNetDefinition via scoped mappings; add membership/port/hierarchy concepts |
| Schematic presentation | Sheet UUID/path, symbol positions/rotation/mirror, wires, labels, graphics and annotations | Structured editable presentation plus native source artifacts for features not yet understood |
| PCB realization | Stackup, layers, outline/cutouts, holes, footprint placement, pads, tracks/arcs/vias, zones, keepouts and rules | Extend PcbBoard/Placement; retain Route summaries as derived views rather than pretending they encode copper geometry |
| Simulation | Model file/hash/licence, model terminal order, harness, stimuli, probes, analysis and expected ranges | Reuse SpiceModelCard/CircuitRunResult; add model bindings, harness and analysis/result artifacts |
| Firmware and logic | Board/config, pin claims, register/peripheral, firmware build, bridge contract/field, derived backend state | Reference existing BoardPin/BoardPinNet, FirmwareVariant, cmod graph, HardwareInterfaceBinding and contract hashes |
| Evidence | Unknown/assumed/cited/derived/simulated/measured, units, conditions, tool version and input revision | Extend existing fact/result concepts; never turn a default or inference into a measured fact |

Important identity rules:

1. Use immutable design/instance IDs; store KiCad UUID + hierarchical instance path as external identity. Refdes and net labels can change without creating unrelated objects.
2. Keep a board definition, a design configuration and a plugged-in board instance separate. Several identical UNOs must not share runtime identity.
3. Keep reusable symbol pin, physical package lead and PCB pad distinct; validate the mappings, especially for MCU packages, transistor pinouts and multi-unit symbols.
4. Store net equivalence explicitly: KiCad `GND`, circuit `GND` and SPICE `0` are related only within a declared design/harness. Do not rename global records to make a simulator run.
5. Model value and unit, tolerance, limits, source and unknown state. The importer currently creates BoardNet volts=0.0/class-from-name; these are not electrical measurements and must not become voltage facts.
6. Record commanded output, sampled pin level, measured current and derived application state separately. A high drive pin does not establish LED illumination.
7. Preserve source-to-generated UUID/row mapping and attach it to every check/export job so findings can open the correct object.

## 4. Ownership and edits between Polari and KiCad

Preserve the existing design-as-rows direction: reviewed Polari electrical intent, configuration and bindings generate KiCad views. Human placement/routing in KiCad feeds observed geometry back into Polari. KiCad-origin projects may also be imported as a new baseline with their provenance intact.

Use three-way comparison: last accepted shared revision, current Polari revision, current KiCad files. Classify a delta as presentation, geometry, electrical, part/footprint choice or unknown native feature. Show old/new values, affected firmware bindings and stale evidence before applying an electrical change. Never silently overwrite either side or auto-resolve a BoardConflict.

Until the parser understands a native feature, retain original files and flag the affected object read-only for regeneration. Do not claim lossless round-trip from the current summarizing importer. A no-change import/export must preserve either original native bytes or documented semantic equivalence; byte equality is a separate, stronger property.

Electrical changes invalidate ERC/SPICE/firmware binding evidence as appropriate; geometry changes invalidate DRC/fabrication/3D fit evidence. Old results remain attached to their old input revision.

## 5. KiCad engine contract

Extend `pcb_engines.py`, not a second unrelated KiCad dispatcher. Its existing local-binary branch already makes the installed KiCad useful. Preserve explicit worker selection and refusal on worker failure; do not silently move jobs between hosts or tool versions.

Discovery should report executable realpath/version, execution host/context, CLI verb/flag support, symbol/footprint/3D library availability and hashes, format compatibility, optional tools and writable job storage. Desktop KiCad being installed on econ does not make its binary visible inside a Polari backend container: expose it through the established authenticated engine-provider path or deliberately run the local adapter in the host context. Do not mount a Docker socket or broaden privilege merely to discover KiCad.

Separate capabilities: GUI launch/open, schematic ERC, netlist/SVG/BOM export, PCB DRC/parity, Gerber/drill/placement export, STEP with/without component models, symbol/footprint operations, and SPICE simulation. Probe the installed CLI; do not invent a simulation CLI verb from GUI availability. Continue using the ngspice seam for automated circuit analyses, with explicit model compatibility checks.

Every job records input revision/hash, requested action, exact argv, resolved provider, executable version, library/model hashes, timeout/resource limits, output paths/hashes, exit status, stdout/stderr and parsed findings. Stage in a unique job directory; reject path traversal and escaping symlinks, bound archives/results, and resolve libraries from reviewed project/library roots. Export from snapshots rather than mutate a live GUI project. Keep engine operations as separate processes.

KiCad 9 worker and KiCad 10 desktop need a compatibility matrix. Do not overwrite the pinned 9 fixture through GUI auto-migration. Test copies with each engine; retain the upgraded 10 format as a separate revision. Pin reproducibility to tool, libraries, settings and inputs. Record whether timestamp/path normalization is available; do not promise identical bytes across major versions or local jobs lacking the frozen-clock machinery.

## 6. Sample projects and order

| Order / project | Grounding in code | KiCad deliverable and key proof |
|---|---|---|
| 0. Import fixture | `pcb/custom/upstream/.../ecc83/` | Copy into an isolated workspace; parse/export/check under local 10, compare semantic net membership and findings against pinned 9 evidence; preserve original |
| 1. `uno-light` | `board/custom/variants.py`, light sample tests | UNO header/module representation, D2 button to ground with firmware pull-up, D6 -> 220-ohm -> LED -> GND, D6 -> D3 sense jumper; schematic, mappings and ERC |
| 2. `uno-button-clock` | electrodevice circuit seeds + BoardPinNet + cmod graph | Reuse hardware where exact configuration matches; map clock/button/edge fields and pins; label host-synchronized software clock, not a fictional RTC |
| 3. `uno-light-all-pcint` | sample S2 | Button on D4, sense D6 -> D8; same LED circuit, distinct configuration; prove pin remap reaches firmware and schematic |
| 4. `uno-light-pwm-analog` | sample S3 | 10k pull-up A0 -> +5V, switch A0 -> GND, D6 LED and D3 sense; record 1500/3500mV thresholds and current on/off-only PWM semantics |
| 5. `uno-light-transistor` | sample S4 | Actual selected transistor/verified lead order, base resistor design, load path and models; distinguish D6 command sense from collector/LED-current measurement |
| 6. `uno-sim-rig` / UNO shield | existing `uno_shield.py` | TMP36 A0, LED/PWM D6 and all headers; resolve sensor symbol/pinout/footprint and header geometry; first manually placed/routed shield after schematic proof |
| 7. `rc-lowpass-demo` | electrodevice circuit seeds | 10k/1uF native schematic and simulation harness; compare transient behavior to the row-based run under identical stimuli/initial conditions |
| 8. `led-branch-row` | electrodevice circuit seeds | Preserve derived CNT resistor subcircuit identity; explicit model-only/device abstraction where no physical purchasable part exists; compare operating point rather than invent a footprint |
| Later: ESP32-C3 and FPGA | board runtime views and existing hardware plans | Extend only after UNO mapping/round-trip is proven; preserve 3.3V interfaces, boot/USB/UART constraints and runtime-specific pin claims |

For each sample produce progressive detail levels:

- A: functional block view, expected behaviors and configuration identity.
- B: complete electrical schematic with nets, pin types, supplies, biasing, polarity, connectors and unknowns.
- C: selected parts/BOM, ratings/tolerances, datasheets, symbols, footprints and models with provenance.
- D: declared simulation harness, states, waveforms, probes, model limitations and comparison tolerances.
- E: MCU/package/header mapping, firmware tasks/peripherals and bridge/application fields with source links.
- F: physical realization where appropriate: breadboard assembly view, board outline, placement/routing, 3D and fabrication files. A breadboard sample does not automatically need a fabricated PCB.
- G: acceptance evidence, failure controls and eventual physical measurements linked back to design revision.

Do the first sample deeply before generating the whole set. Shared circuits/configurations should reuse definitions without conflating their firmware or sensing semantics.

## 7. Electrical and simulation gaps to resolve explicitly

The existing button-clock SPICE rendering is not a running simulation: its bench omits a source for MCU D6 and uses `GND` without a SPICE-0 alias. Add a separate harness with explicit supply, GPIO source/impedance, pull-up, switch stimulus/bounce and probes; exclude those harness-only sources from production BOM/PCB. Avoid two sources accidentally driving the same net.

The switch renderer currently uses 1G-ohm/0.1-ohm resistors for static open/closed states. Keep static comparisons valid; add a timed switch/stimulus representation before claiming bounce or transient equivalence. For RC, match initial conditions and supply/startup behavior rather than relying on an unexplained solver default.

The current LED forward voltage is an assumption, not a device rating; 220 ohms and supply alone do not establish real LED current. Select and cite parts before physical/fab readiness. The shield currently borrows LM35-LP's symbol for TMP36 with unresolved package-pin evidence: resolve this before layout. UNO header positions include a nonstandard spacing; obtain a cited mechanical drawing before manufacturing.

The transistor sample's existing MCU twin sees D6, not the transistor or LED current. Add analog transistor/load evidence independently, then optional controlled co-simulation. A disconnected LED can leave D3 high if it senses D6. Report this as limited observation, not end-to-end illumination proof.

## 8. Blending into Polari logic

Proposed mapping manifest per design revision: sample/configuration, board definition and instance selector, component/terminal IDs, BoardPin/net/CircuitNet links, firmware graph/task/claim, peripheral/register, bridge class/field + contract hash/tag order, direction, units/conversion, observation meaning and evidence references.

Start with a read-only trace view and equivalence validator. Generate pin assignments from the shared rows; consume observations through existing serial/twin -> generated bridge -> Polari paths. Do not move backend logic into KiCad or invent a parallel bridge. Analog SPICE, MCU twins and application logic run separately first. Add synchronized co-simulation only when timestamps, sample periods, stepping, reset, stale values and causality are defined.

Required failure controls: missing D6->sense jumper, wrong button pin, missing pull-up, conflicting output roles, LED reversed/open, transistor wrong terminal map, missing ground, contract tag-order mismatch and stale firmware after pin reassignment. Treat the unsensed and slow-loop sample variants as intentional negative examples, not approved production defaults.

## 9. Phases and completion gates

1. **Inventory/compatibility:** probe local CLI and library paths, identify host-vs-backend context, run existing import/export fixture on a copy. Deliver a capability report and KiCad 9/10 difference record.
2. **Model contract:** document reusable definition vs occurrence, stable IDs, hierarchy/net semantics, preservation boundaries, conflict policy, units/provenance and manifest schema. Review against existing board/electrodevice/pcb objects before implementing extensions.
3. **One complete sample:** create `uno-light` native project and manifest. Open in GUI; export netlist/ERC; compare actual terminal membership to Polari; show a field-to-pin trace and a rejected conflicting edit.
4. **Import/edit/compare loop:** KiCad symbol movement retains identity; refdes rename is not deletion; pin/net edit produces reviewable delta; unsupported features survive untouched. Re-ingest cannot erase native board details.
5. **Simulation + variants:** add harness and model bindings, then button-clock/PCINT/analog/transistor samples. Compare circuit results and MCU/Polari semantics without overstating co-simulation.
6. **First physical shield:** resolve part/geometry unknowns; manually place/route in KiCad, ingest geometry, ERC/DRC/parity, BOM and fab exports. Manufacturing is a separate user action.
7. **Polari workflow:** shared native-app launch, project/artifact navigation, engine selection, capability reporting and job history. Use existing Polari app/data deployment conventions and Isle placement; installed desktop app and remote engine provider remain distinct.

Use existing `pol pcb` / `pol board` / module selftest paths for implementation verification. Avoid starting production services or deploying workers just to write this plan. New validation should test meaningful invariants: actual connectivity, terminal-to-pad mapping, conflict preservation, version boundaries, electrical limits and observed-vs-commanded state. Do not equate a parser self-check or zero process exit with design correctness.

First proposed implementation slice: local-engine capability/version report + revision/mapping schema + one complete `uno-light` schematic, with no PCB fabrication, firmware flashing or runtime deployment. Completion means it opens in installed KiCad, exports the expected net membership, has explained ERC results, and maps its signals back to the existing Polari sample.

## 10. Decisions still needed during implementation

Choose actual LED/transistor/sensor parts before a physical-ready revision; confirm whether the first delivery is breadboard documentation or a shield (recommend breadboard schematic first); establish whether Polari's running backend can invoke this host's provider; agree native project save/import behavior and KiCad-major-version policy. These do not block the initial model and capability work.
