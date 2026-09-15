# Polari Modular Household Energy Apps — the refined plan (draft 2026-09-15)

Source: his plan of 2026-09-15 (from ChatGPT), refined here against what Polari already has and against an
upstream survey of Libre Solar, Open Source Ecology, PyPSA, pandapower, OpenModelica, OpenEMS and ThingSet.
The goal beyond the household: **Libre Solar and Open Source Ecology should be able to use Polari long term to
further their own work** — Polari as the open modeling, integration, simulation, optimization, evidence and control
layer between the best existing open technologies, never a "Polari inverter" or "Polari house".

## 0. The research question (unchanged)

Can a household electrical architecture be built from standardized, reusable, consumer-connectable **Energy
Cells** using plug-in solar (Solar-400 modules in 400 / 800 / 1200 W groupings; 1200 W the preferred maximum per
cell, a design hypothesis not a physical law) as its only PV input, such that a house transitions circuit-by-circuit
from grid to a complete microgrid while keeping electrical safety, reliability, winter survivability, ordinary
appliances and slow EV charging — and can a finished house expand later without replacing its original modules?

The invariant every design must respect: **GRID xor MICROGRID on a circuit, never both**, enforced by hardware
(break-before-make); Polari may request a transition, never guarantee safety. Four statuses never collapse into
one: TECHNICALLY FEASIBLE · SIMULATION VALIDATED · PHYSICALLY TESTED · REGULATORILY PERMITTED. Missing evidence
is UNPROVEN, never "safe".

## 1. What Polari already has (the refinement portion)

The plan asks for thirteen Apps (A–M). Nine of them start from rows and machinery that exist today; the table says
what each App inherits and what is genuinely new.

| plan App | starts from (existing module → rows) | what is new |
|---|---|---|
| A Energy Model (canonical objects) | `composition` (CompositionNode, InterfaceDefinition, FunctionalPartDefinition, FailureModeDefinition — parts with interfaces and DERIVED levels); `electrodevice` (CircuitDefinition, CircuitNetDefinition, CircuitComponentDefinition, SPICE cards); `pspp` (EvidenceMethod, claims-not-values, LadderRung); `scoring` (ClaimAttestation, ContextualizedValue, credibility/authority) | the energy vocabulary itself: EnergyCell, SolarModule/Array, MPPT, Battery/Pack/BMS, Inverter, Converter, TransferDevice, ThermalStorage, HeatPump, ThermalLoad, EV/EVSE, EnergyMeasurement, EnergyClaim — as rows, with `Evidence` reusing pspp/scoring, not a new evidence system |
| B Energy Cell Designer | `composition`'s design-matrix + construction-variant rows; `electrodevice`'s device validation reports (Voc/Isc/ratings live there); `microchip`'s design-level ladder pattern (device → cell → block …) | the cell-level validation rules (Voc cold, MPPT window, series/parallel, connector/conductor ratings, inverter limits); the Solar-400/800/1200 classes as rows with room for more |
| C Libre Solar Integration | `mqttbridge` (brokers, topic→object bindings, refusal ledger), `grpcbridge` (HardwareBridgeDefinition, SimRigState — Java bridges + hw sim rigs), `hardwareapps` + `hwmap` (KVM guests, ports, passthrough candidates), `techtree` (RealArtifact, TechNode) | the ThingSet/CAN adapters and the digital twin (see §3, the survey) |
| D Household Electrical Model | `household` (members, schedules, safety rules), `computers`/`computerparts` (loads: server rack, builds, dated prices), `electrodevice` circuits | HouseElectricalSystem: service, distribution, circuits, conductors, breakers, grounding; the load taxonomy with average/max/surge/daily/priority/interruptibility/deadline |
| E Microgrid Topology Designer | `composition` (variants, failure modes), `magnetics`' realization ladder pattern | the architecture search with hard rules supplied as rows separate from design variables |
| F Electrical Safety Simulator | `electrodevice` (SPICE runs: CircuitRunResult) for the DC/device level | pandapower/OpenDSS for the AC network + a SAFE / UNSAFE / UNPROVEN evaluator (§3) |
| G Energy Simulation & Optimization | `climate` (time series as objects: AtmosphericSeriesDefinition/Observation, trend fits — the pattern for hourly series), the simulation framework (SimRun, resource-aware sim, cross-instance sim) | the PyPSA adapter (§3) and the household scenario runner (24 h / 8760 h) |
| H Thermal Energy | `climate` series; `materials_science` (Material, MaterialProperty — U-values, thermal mass) | thermal rows + an RC model first, OpenModelica later (§3); the winter-survivability evaluator |
| I EV Energy Planner | nothing specific | EV as a deadline load: a small row set + a scheduler; PyPSA handles the optimization |
| J Upgrade Planner | `computerparts` (dated prices → derived build cost, feasibility), `supplychain` (PriceCitation, SupplyFlow, SourcePreferencePolicy), `techtree` business segments | the sequence search (≤ $300 increments, nothing obsoleted) with PyPSA as the evaluator |
| K Household Migration Planner | `resources` (admission advisor pattern: knobs + evidence) | circuit-conversion ordering from simulation, never hard-coded |
| L Open House Model | `mathshapes` (CSG/CAD import), `zones` (AR-captured rooms), `meshassets` (licence-gated external 3D assets) | FreeCAD import path + the house schema (House/Room/Wall/Roof/Window/PVSurface/ThermalZone) |
| M Open Technology Catalog | `techtree` (TechNode, RealArtifact, dependency edges), the licence gates (TechnologyIPRecord, licence compatibility rules), `meshassets`' provenance | TechnologyDefinition rows with repository/commit/license/files/capabilities/limits/claims/evidence — the catalogue every other energy App reads |

Cross-cutting rules Polari already enforces and the energy Apps inherit: derive or cite every number, label the
knobs; every capability is an explicit knob plus an evidence-bearing suggestion; every capability maps to an
object-tree node; no raw JSON on screens (configured Tables/Graphs); the evidence ladder (measured > mass-balance >
cited > refuse); licence gates (GPLv3 compatibility, NC = hard blocker, upstreams forked as pins).

**Provenance (plan §18) needs no new machinery:** `scoring`'s ClaimAttestation/ContextualizedValue carry source,
credibility and authority; `pspp`'s EvidenceMethod names how a number was obtained; `materials_science`'s
DataProvenance/DataSource are the same idea for data. The energy Apps add the fields the plan lists (repository,
commit, file, symbol, version, derived-from, method, validation) to ONE provenance row type reused everywhere.

## 2. The four statuses and the HIL ladder as rows

`Feasibility`/`Validation` rows carry the four statuses separately (technically feasible · simulation validated ·
physically tested · regulatorily permitted) per architecture, and the S0–S10 hardware-in-the-loop ladder is a
LadderRung sequence (pspp already has LadderRung) with a safety-review gate row between stages. The security
module's "assurance ladder" (designed → built → applied → self-tested → independently tested → insurable) is the
same shape and should share the row type.

## 3. Upstream survey — what to integrate, wrap, reference, or reimplement

(filled from the seven parallel investigations; each project under: capabilities · useful repositories · reusable
code · useful data/models · license · integration approach · gaps · recommended Polari App)


### 3.F pandapower — the Electrical Safety Simulator (survey 2026-09-15)

**Capabilities.** Balanced and unbalanced (3-phase) power flow; IEC 60909 short-circuit (3ph/2ph/1ph, max/min, inverter
sources as `sgen` current sources with a `k` ratio); switches (bus-bus, with ratings); lines with ampacity and
`loading_percent`; a protection module (overcurrent relays, fuses with IEC 60255 curves; no MCB B/C/D curves, no
RCD/GFCI, no AFCI); DC buses/lines/converters since 3.0; timeseries + controllers; topology graph (connected
components, unsupplied buses, respecting switches). No native single-phase or split-phase type: a house circuit is a
balanced positive-sequence equivalent (US 120/240 split-phase → OpenDSS's centre-tapped model if needed).

**What it answers vs what it cannot** (the UNPROVEN list is the point):

| question | pandapower | caveat |
|---|---|---|
| normal current / conductor loading | `runpp` → loading vs derated ampacity | ampacity/derating tables (IEC 60364-5-52 / NEC 310.16) are Polari-owned data |
| reverse current | sign of line/switch flow | fine |
| fault current | `calc_sc` 3ph/2ph/1ph max/min | 1ph needs zero-sequence data + an earthed transformer |
| breaker loading | switch rating + relay/fuse curves | MCB curves added as custom characteristics |
| voltage / drop | `vm_pu` | the 3 % / 5 % limits are policy rows |
| ground fault disconnection | **no** | in-house Zs loop check (IEC 60364-4-41 / NEC 250); RCD/GFCI not modelled |
| arc fault | **no** | device-level (UL 1699); arc-flash energy only via a separate lib |
| inverter fault contribution | `sgen` current source, `k` | manufacturer data; grid-forming (k≈2–3) ≠ grid-following (≈1.1–1.5) |
| source / transfer / inverter / MPPT failure | state enumeration, `unsupplied_buses`, out-of-service | static only; break-before-make TIMING not simulated; MPPT is DC control, unmodelled |
| battery isolation | DC switch in service | DC arc/fault current not in `calc_sc` |
| islanding | **no** | regulatory (IEEE 1547: cease within 2 s; UL 1741) → UNPROVEN unless a device certificate is accepted as evidence |
| loss of communications | **no** | Polari's own state-machine reasoning |

**Integration.** `PandapowerSafetyAdapter`: a bus per panel/circuit node, conductors → lines (R/X/`max_i_ka`), breakers →
switches + protective devices, each transfer device → TWO bus-bus switches (GRID side, MICROGRID side), the grid →
`ext_grid` (s_sc max/min), PV/battery inverters → `sgen` current sources, the battery DC side → `bus_dc`/`vsc`.
Enumerate every cell state {GRID, MICROGRID, OPEN}; for each, a GRAPH proof (connected components respecting
switches) that no component holds both the grid and an islanded inverter and every energised bus reaches exactly one
source; break-before-make proven by requiring the open-both state between every pair; then power flow, max/min short
circuit and the protection scenario per state. Verdict rule: SAFE only when every question has a model and passes;
UNSAFE when any modelled check fails; UNPROVEN when any question has no model.

**Licences.** pandapower BSD-3 (compatible); pandapipes BSD-3; OpenDSS BSD-3 (KLU LGPL) via `dss_python` BSD-3
(prefer over OpenDSSDirect.py's extra clauses); VeraGrid MPL-2.0; the two IEC 60364 calculators found on GitHub carry
NO licence → reference only, never copied.

**Recommended Polari App.** `electrical_safety`: rows Circuit, Conductor, ProtectiveDevice, TransferDevice, Source,
EnergyCell, TopologyState, SafetyVerdict (per-question SAFE/UNSAFE/UNPROVEN + evidence rows); the adapter; in-house
`EarthFaultLoopCheck` and `IslandingCompliance` (certificate-based); configured Tables only.

**Open questions (his).** Q-F1 jurisdiction: IEC 230 V TN/TT or NEC 120/240 split-phase (decides the OpenDSS need)?
Q-F2 inverter `k`: manufacturer data or defaults 1.2 / 2.5? Q-F3 is a UL 1741-SB / IEEE 1547 certificate acceptable
as the islanding proof or does it stay UNPROVEN? Q-F4 do cells share neutral/ground across GRID and MICROGRID states?

### 3.C Libre Solar — the physical Energy Cell (survey 2026-09-15)

**Capabilities.** BMS C1 (beta; 3–16s Li-ion, 70–100 A, bq76952 + ESP32-C3; CAN, RS-485, USB, UART, I2C, BLE, WiFi;
12–48 V nominal, 70 V max; KiCad, BOM, FreeCAD housing, manual, a v0.3 test report — PCB v0.4.2, 2026-03); BMS 8S50 IC
(3–8s, ISL94202); MPPT 2420 HC (eval; 80 V PV, 12/24 V battery, 20 A charge + 20 A load, STM32G431, CAN over RJ45 —
hardware untouched since 2021); MPPT 1210 HUS (eval; 40 V PV, 150 W, 12 V/10 A, dual USB, >98 % peak efficiency);
PWM 2420 LUS. Interfaces: LS.one (6P6C UART jack carrying ThingSet) and LS.bus (CAN on RJ45, CANopen pinout only,
ThingSet binary, "under development"). The Libre Solar Box (third-party, CC-BY-SA-4.0): MPPT + BMS + 4×72 Ah LFP,
300 W PV, 920 Wh, an optional Victron 250 W inverter. **No design carries regulatory certification.**

**Repositories.** bms-firmware and charge-controller-firmware (Zephyr; Apache-2.0; active 2026); bms-c1 and the MPPT
boards (CERN-OHL-W-2.0 hardware, CC-BY-SA-4.0 docs); esp32-edge-firmware (CAN/UART → WiFi/BLE/HTTP gateway + web UI;
early; MQTT "ToDo"; 2022); dcdc-control (Octave PID + ngspice firmware-in-the-loop; NO licence stated — ask before
reuse); the ThingSet org: thingset-node-c, thingset-zephyr-sdk (CAN/serial/WebSocket/LoRaWAN transports, native_sim),
python-thingset (`pip install python-thingset`: serial, SocketCAN, TCP), thingset-app (Flutter), C++/C# clients — all
Apache-2.0.

**Reusable.** The charger state machine (Standby/Bulk/Topping/Equalization/Float), P&O MPPT, buck/boost/nanogrid
modes; the ThingSet data objects (charger: Device/Battery/Charger/Solar/Load/USB/Nanogrid; BMS: Conf with SC/OC/temp/
cell limits + chemistry presets + OCV/SOC lookup, Meas, Input chg/dis enable, exec presets/reset/shutdown); SOC =
coulomb counting + OCV table; DFU over CAN. **Digital twin:** the BMS builds for `native_sim` and speaks ThingSet but
does NOT mock the BMS IC; the charger's unit tests run on `native_posix`; both pin Zephyr v4.4 + thingset-zephyr-sdk.
CAN layout: 29-bit ids (priority/type), ISO-TP request/response with bus + node addresses, single-frame reports with
16-bit data ids, EUI-64 address claiming, fixed 500 kbit/s — ThingSet, not CANopen.

**Data.** OCV-vs-SOC curves (lead-acid, LFP, NMC), charge-voltage tables, DC/DC design equations (learn.libre.solar,
CC-BY-SA-4.0); the BMS C1 v0.3 thermal/protection test report. No published efficiency curves or field datasets.

**Licence verdict.** Apache-2.0 firmware and libraries: one-way compatible with GPLv3 — Polari may link, vendor or wrap
(keep NOTICE, mark modified files; the combined work is GPLv3). Hardware CERN-OHL-W needs no code alignment. Avoid the
archived LGPL Arduino lib and the unlicensed dcdc-control. Fork upstreams as `dausume/` pins.

**Integration.** LibreSolarThingSetAdapter = wrap `python-thingset` (never rewrite the codec); LibreSolarCANAdapter =
SocketCAN + ThingSet CAN framing via the same lib (report subscription for telemetry, ISO-TP for config);
LibreSolarDeviceAdapter = discovery through the ThingSet schema + Device group; BMS and MPPT adapters map the groups
above (chg/dis enable as Polari knobs behind an explicit legality gate; ErrorFlags → fault rows);
LibreSolarDigitalTwin = the native_sim BMS + charger builds in a container speaking ThingSet over pty/WebSocket, with
Polari supplying the cell/PV stimulus the firmware cannot mock.

**Gaps.** No inverter, no AC transfer switch, no per-circuit GRID/MICROGRID/DISCONNECTED switching, no break-before-make
interlock, no load scheduling, no fleet/cloud, no certification, no IC emulation; LS.bus still moving.

**Recommended Polari Apps.** `energy_cell` (Hardware App, hardware tier: device registry + live ThingSet views);
`energy_cell_sim` (the twin + Polari-side PV/battery models fed from the OCV tables); `microgrid_switching` (the
Polari-owned transfer-switch objects — exactly the part Libre Solar lacks).

**What Libre Solar gains.** GitHub-first community, a Discourse forum, founder Martin Jäger (ThingSet by Libre Solar
Technologies GmbH), partner A Labs. Polari adds system-level simulation and planning, provenance-tracked configs, fleet
views, and the AC-side story they do not have.

**Open questions (his).** Q-C1 which firmware release's ThingSet ids to pin; Q-C2 a BMS-IC mock upstream (a PR
opportunity); Q-C3 the dcdc-control licence; Q-C4 first target board (BMS C1 vs the 2021-era MPPT 2420 HC); Q-C5
should Polari's switching hardware be designed under CERN-OHL-W to match.

### 3.G PyPSA — Energy Simulation and Optimization (survey 2026-09-15)

**Capabilities.** PyPSA 1.3 (MIT): buses with any carrier (AC, DC, heat, EV), generators with capacity-factor series,
loads, StorageUnit or Store + Link (the recommended battery form when energy and inverter size are independent), links
with static or time-varying efficiency and bidirectional flow, global constraints; arbitrary snapshots with
weightings; multi-year through investment periods with build_year/lifetime and discounting; linopy optimisation
(LP/MILP), capacity expansion, discrete blocks (`p_nom_mod` → integers), unit commitment on generators AND links
(binary status), pathway planning, custom constraints through linopy. "One source per circuit per hour" is
expressible: status_grid + status_inverter ≤ 1 per snapshot (MILP), or a Polari-side 0/1 schedule written into both
links' `p_max_pu` (LP). No household-microgrid notebook exists, but every piece appears in the examples: EV charging
(Store + driving Load + availability-windowed charger Link, `e_min_pu` "75 % full every morning"), heat pump + tank
(COP as time-varying link efficiency, 1 %/h standing loss), load shedding as a costly generator, modular expansion,
committable + extendable.

**Component mapping (Polari → PyPSA).** EnergyCell.pv → Generator on the cell's DC bus; MPPT → Link PV→DC (0.95–0.98);
battery → Store on the DC bus (reserve floor, standing loss; charger/discharger Links when C-rate limits matter);
inverter → Link DC→circuit AC bus (committable when exclusivity is optimised); house circuit → AC bus with its Loads;
grid service → grid bus + Generator (tariff series as marginal cost, breaker limit as p_nom) + export Link; the
GRID/MICROGRID switch → Link grid→circuit with the exclusivity constraint; curtailable load tiers → shed generators
priced at value-of-lost-load; deferrable load / EV → EV bus + Store with `e_min_pu` hitting the target at the deadline
+ driving Load + charger Link with availability; heat pump → Link AC→heat with COP(T); thermal store → Store on the
heat bus with a comfort floor; resistive backup → Link AC→heat; an upgrade step → a component copy with
build_year = month, `p_nom_mod` = kit size, annualised capital cost.

**Upgrade sequences.** Multi-period PyPSA gives build_year/lifetime and growth limits but NO per-period capex budget
for generators/stores (only for lines/links); a ≤ $300 budget is one custom linopy constraint and "nothing obsolete"
is lifetime ≥ horizon. But months × 8760 h × integer kits × switch binaries is a large MILP: the clean split is
Polari searching candidate sequences (greedy or beam over ≤ $300 steps) with PyPSA evaluating each as an LP with
fixed capacities, MILP only for short windows.

**Dependencies and licences.** PyPSA MIT, linopy MIT, atlite MIT, pvlib BSD-3, HiGHS/highspy MIT (musllinux wheels
exist, so the Alpine image just `pip install pypsa`; the geo/plot tail ≈ 300 MB); PyPSA-Eur code MIT (pattern source,
e.g. the COP(ΔT) regression); PyPSA-Earth AGPLv3 (patterns only — never imported). Weather: PVGIS hourly 2005–2023 via
pvlib (free, no key); ERA5 via atlite (needs an ECMWF key).

**Gaps.** No electrical safety, no transients/inrush/sub-hourly surges, no wear beyond a cycling-cost proxy, no thermal
derating, no forecast error unless rolling-horizon; results are cost-optimal dispatch, not a real controller's.

**Recommended Polari App.** `energy_cells` (or the plan's polari-energy-simulation): the objects per the mapping, a
`PyPSAEngineAdapter` (build → solve lp|milp → per-hour results: grid import/export, PV used/curtailed, cycles, unserved
energy, EV completion, thermal reserve, cost), scenario rows (weather year, tariff, switch policy, upgrade sequence),
the UpgradePlanner search, Table/Graph displays; pandapower alongside for the safety questions.

**Open questions (his).** Q-G1 the switch as a planning knob (schedule → LP) or an hourly decision (MILP, ~8760
binaries per circuit-year)? Q-G2 kit granularity for `p_nom_mod` (per 400 W panel vs per cell)? Q-G3 weather: PVGIS
only or atlite/ERA5 with a key? Q-G4 accept PyPSA's ~300 MB geo/plot tail in the image? Q-G5 tariff model (flat, TOU,
net metering)? Q-G6 wear proxy (cycle cost vs throughput cap)?

### 3.T ThingSet — the Energy Cell's telemetry and control interface (survey 2026-09-15)

**Capabilities.** A self-describing tree of groups and leaves, each with a 16-bit id (binary/CBOR) and a name (text/JSON)
whose prefix says what it is: `r` measurement, `w` writable control, `s` stored config, `p` protected, `c` constant, `x`
function, `t` timestamp; units in the names; subsets and records (e.g. cells). Operations aligned with CoAP: GET,
FETCH, UPDATE, EXEC, CREATE, DELETE, plus unsolicited REPORT and DESIRE (unacknowledged); per-group reporting periods.
Transports: serial, WebSocket, CAN (29-bit ids with priority/type/bus/address, masterless EUI-64 address claiming,
single-frame CBOR reports carrying the item id in the CAN id, ISO-TP for request/response), BLE; mappings for MQTT,
CoAP, LoRaWAN. Auth: a plaintext password unlocking `p` items; encryption left to the link. Spec v0.6 (Feb 2025) is
declared the last breaking revision before 1.0 (CC-BY-SA-4.0). The spec itself rejects Modbus, CANopen, J1939,
UAVCAN for not being self-describing; SunSpec is a device profile on Modbus for grid-tie inverters, OCPP is
EV-specific — neither competes for the cell-level role.

**Repositories (all Apache-2.0, verified).** thingset-node-c (v0.6 node library; DESIRE unimplemented; ztest on
native_sim; Nov 2025); thingset-zephyr-sdk (serial, shell, BLE, CAN with address claim + ISO-TP, LoRaWAN, storage;
WebSocket sample on native_sim; MQTT "under development"; Zephyr 4.4, Apr 2026); python-thingset 0.2.8 (serial, CAN,
IP; wraps python-can, can-isotp, cbor2, pyserial; Feb 2026, Brill Power authors); C++ and .NET clients (Mar 2026);
the Flutter app; a two-commit serial→WebSocket forwarder. No Rust or JS library; the old Python client is archived.
Only two companies behind it (Libre Solar Technologies GmbH, Brill Power).

**Digital twin.** A Zephyr `native_sim` node runs on Linux: WebSocket works today; CAN through `CONFIG_CAN_NATIVE_LINUX`
on a `vcan0` interface — so the SAME adapter code talks to the twin and to real hardware with no branch. Libre Solar's
BMS simulator is protocol-level only (no BMS-IC mock).

**Safety semantics: none in the protocol.** No safe-state, watchdog, heartbeat or command acknowledgement; only
request/response has a client timeout. So the plan's rule holds by construction: the GRID/MICROGRID switch is a `w`
or `x` REQUEST whose result is read back as an `r` state, the hardware interlock enforces, and Polari treats report
staleness as a fault. Auth is weak: rely on physical CAN and TLS on WebSocket.

**Integration.** `ThingSetAdapter` (Python, on the isle member): SocketCAN via python-can/can-isotp (a CANable /
candleLight `gs_usb` adapter or Libre Solar's MCP2515 Pi hat), serial, WebSocket; passive telemetry from single-frame
reports, ISO-TP for FETCH/UPDATE/EXEC; a device registry keyed by EUI-64 holding the id→path table; discovery through
FETCH-null + `_Paths`; prefixed names mapped to the canonical Battery/BMS, MPPT, Inverter → EnergyCell. Twin parity:
the same adapter against native_sim on vcan/WebSocket in the compose stack, so tests run without hardware.
**Stance: adopt ThingSet as the preferred interface for Polari-built and Libre-Solar-class cells;** SunSpec/Modbus
through OpenEMS for third-party inverters; OCPP only if an EVSE appears.

**Gaps.** No standard device profiles (no SunSpec-style models; `_Metadata` WIP); DESIRE unimplemented; MQTT in the SDK
unfinished; small ecosystem.

**Recommended Polari App.** The `energy_cell` module carries the `ThingSetAdapter` connector, a `ThingSetDevice`
registry row, the canonical classes, and a native_sim twin service on vcan in the compose stack.

**Open questions (his).** Q-T1 pre-1.0 (v0.6) acceptable now, or wait for 1.0? Q-T2 switch semantics: EXEC with
state read-back, or UPDATE of a `w` item? Q-T3 does Brill Power's involvement count as durable second-vendor adoption?
Q-T4 do any inverters exist as ThingSet nodes, or only via SunSpec/OpenEMS?

### 3.O OpenEMS — the site-level dispatcher (survey 2026-09-15)

**Capabilities.** Edge (Java 21, OSGi; the on-site controller), Backend (aggregates edges over JSON-RPC/websocket), UI
(Angular). Edge runs an input-process-output cycle (~1 s): bridges read devices into a frozen process image, a
scheduler runs controllers in priority order (earlier setpoints win), writes flush. Devices are components with typed
channels through natures (ElectricityMeter, ManagedSymmetricEss, Battery, BatteryInverter, PvInverter, Evcs/Evse,
DigitalOutput). Bridges: Modbus TCP/RTU, HTTP, MQTT, M-Bus, OneWire — **no CAN bridge**. External control: JSON-RPC
(getEdgeConfig, subscribeChannels, setChannelValue, component config, historic queries), a REST controller, an MQTT
controller, and a Modbus-slave API whose writes EXPIRE after a timeout (a fail-safe pattern worth copying). Simulators
exist (ESS, grid/production meters, EVSE, CSV datasources incl. H0 load profiles) but are behavioural stand-ins, not
physics twins. An Energy Scheduler (genetic algorithm, 15-min periods over 24 h, with predictors and tariff providers)
makes it more than purely operational — still no sizing, no what-if. Images for amd64 + arm64; ~1 GB headless is
enough, a Pi CM4-class board recommended.

**Device families.** Open-protocol and worth adapting as DATA: generic SunSpec PV inverter + meter, OCPP server, Modbus
meters (Eastron SDM, Janitza, Carlo Gavazzi, Socomec, Siemens, ABB, Schneider, Phoenix, Chint …), Modbus EVSE (KEBA,
Alpitronic, Hardy Barth, Heidelberg, Mennekes, Alfen, go-e, openWB, Webasto), relays/IO (KMtronic, WAGO, Shelly,
RevPi, GPIO), heat (SG-Ready relay controller, my-PV). Vendor-specific register maps: GoodWe, SMA, Kostal, Fronius,
SolarEdge, Victron, Huawei, KACO, Tesla Powerwall, Fenecon, Pylontech, BYD … Absent: Sungrow, Deye, Solax, Growatt,
Enphase, any CAN BMS. Controllers to reuse CONCEPTUALLY (never their Java): ESS balancing, peak shaving,
grid-optimised charge, time-of-use, EVSE single/cluster (with a phase-switch guard), heat-pump SG-Ready (four states
on two relays with minimum switch times), emergency capacity reserve, AC island, and `io.offgridswitch` (main +
grounding contactor with interlock and auxiliary-contact feedback — the closest thing to our transfer device).

**Licence — the decisive finding.** Edge and Backend are EPL-2.0 WITHOUT the GPL secondary-licence designation
(no file headers, no Exhibit A), which the FSF lists as GPL-incompatible; the UI is AGPL-3.0 (compatible, but not
wanted). Consequence: **never vendor or link OpenEMS Java into Polari.** Running Edge as its own container and
talking JSON-RPC/REST/Modbus is a separate program — no conflict. Transcribing register maps and algorithm
descriptions from the docs into Polari's own code and data is fine (facts). Ask the OpenEMS Association whether they
would add the GPL secondary licence; it would unlock vendoring.

**Integration.** `OpenEMSAdapter`: run `openems/edge` on a hosting member (arm64 fine, ~1 GB), Polari as the JSON-RPC
websocket client — getEdgeConfig materialises components as Polari rows, subscribeChannels feeds telemetry,
setpoints only through the write-expiring API pattern. Device definitions (SunSpec + selected open Modbus maps) as
Polari module initialData citing the bundle as source; proprietary vendor maps only once a member owns that
hardware. OpenEMS simulators only for adapter integration tests; physics twins stay in Polari's own sim framework.
Do NOT reimplement balancing/peak-shaving/ToU/EVSE state machines, do not fork the Java.

**ThingSet vs OpenEMS: complementary layers.** ThingSet = MCU-level BMS/MPPT/relay telemetry and control (CAN/serial);
OpenEMS = site-level dispatch of third-party inverters/meters/EVSE (Modbus/SunSpec/OCPP); Polari = topology,
per-circuit switching rules, planning and sizing simulations, provenance. Note evcc (Go, MIT, a large SunSpec/Modbus
device list) as a lighter comparison point.

**Gaps.** One site-level off-grid switch, no per-circuit ATS, no break-before-make timing model, no multi-cell
topology; telemetry without attested provenance; planning is 24 h operational only; no thermal thermodynamics
(SG-Ready is a relay hint); no CAN.

**Recommended Polari App.** The `energy_cell` module's second adapter (`OpenEMSAdapter`, JSON-RPC) beside the
ThingSet one; the nature channel vocabulary (ActivePower, Soc, AllowedCharge/DischargePower, GridMode …) is a
ready-made canonical schema to borrow for the Polari objects.

**Open questions (his).** Q-O1 does any member own SunSpec/Modbus hardware to validate against, or simulator-only at
first? Q-O2 keep OpenEMS Edge as the real-time dispatcher permanently or only until Polari's own loop is proven?
Q-O3 Polari as a Modbus slave OpenEMS pulls, or Polari pushing over JSON-RPC? Q-O4 a 1 GB JVM per hosting member
under the swarm memory caps? Q-O5 ask the OpenEMS Association for the GPL secondary licence?

### 3.H OpenModelica and the thermal libraries — winter survivability (survey 2026-09-15)

**Capabilities.** OpenModelica 1.27.1 (Sep 2026) compiles Modelica to C, simulates headless (`omc`), exports FMI 2.0
ME+CS (FMI 3 experimental, FMU import experimental). Python: OMPython (`ModelicaSystem`: parameters, simulate,
results as numpy, FMU export), OMSimulator, BuildingsPy (runs OM, reads `.mat`). Docker images
`openmodelica/openmodelica` v1.27.1 `-minimal` (278 MB) / `-ompython` (301 MB), amd64 + arm64; libraries NOT bundled.
No published 8760-h house benchmark: reduced-order RC zones + table heat pump + tank are small stiff ODEs, expect
seconds to minutes — measure before committing.

**Libraries (all BSD-3 unless noted).** Buildings (LBNL) 13 — CI-tested on OM (98 % simulate): reduced-order VDI 6007
zones, modular reversible heat pumps with 2-D COP tables, stratified storage with losses and internal HX, heat
exchangers/radiators (EN 442), DHW tank + mixing valve, TMY3/EPW weather reader. IBPSA 4 (98 % on OM). AixLib 3
("OM-ready" badge; the public coverage page is stale — verify locally). TEASER (MIT): an archetype building from year
/ area / type → RC parameters and ready models — the "house from a few numbers" tool. BESMod: modular heat pump +
storage + DHW systems. hplib (MIT): Keymark-fitted COP/P_el(T_source, T_sink) for real and six generic heat pumps,
pure Python. IDEAS is Dymola-first; BuildingSystems unreleased; ThermoPower (Modelica License 2, plant scale) — skip.

**A first pass without Modelica.** RC_BuildingSimulator (ETH, MIT + citation clause): a 5R1C zone (ISO 13790) with
window/wall/floor areas, U-values, ventilation/infiltration ACH, thermal capacitance per m², heating set-point and
system limits → hourly indoor temperature, heating demand, COP, heat-pump electricity; its core is ~200 lines — port,
do not depend. pyBuildingEnergy (EURAC, BSD-3): ISO 52016-1 hourly + EN 15316 heat pump/storage/DHW, PVGIS/EPW
weather. Modelica becomes necessary for stratified tanks, hydraulic control loops, multi-zone, sub-hourly transients.

**Weather.** PVGIS TMY (global, 2005–2023, hourly, CSV/JSON/EPW, no registration, attribution); NREL NSRDB for the
Americas (free key; the site was unreachable from this box — verify terms); ERA5 via atlite (CDS account, attribution);
Meteostat station data (CC BY 4.0, MIT library).

**Licences.** OpenModelica is OSMC-PL 1.8 = a CHOICE of AGPLv3 or the members-only EPL variant — only the AGPL mode is
GPL-compatible: run `omc` as its own container, keep an `OSMC-USAGE-MODE.txt`; Polari code that shells out is
unaffected. OMPython is BSD-3 / AGPLv3 / OSMC-PL — choose BSD-3. Exported FMUs carry the runtime under the same
triple licence. Everything else BSD-3 or MIT. Footprint ≈ 300 MB image + the Buildings sources + gcc: an engine tier,
never a core dependency.

**Integration.** Sprint 1 = a native RC engine on the canonical rows: BuildingEnvelope (areas, U-values, C/m², ACH,
g-value), ThermalZone, HeatPump (hplib map, P_max, T_supply_max), ThermalStore (kWh_th, T, P_max, T_min_useful,
loss/h), HeatExchanger (ε), ThermalLoad; a 5R1C stepper at 1 h over 8760 h emitting T_in, T_store, P_el_hp, Q_unmet —
numpy only, inside the existing backend. Sprint 2 = `OpenModelicaEngineAdapter`: render the same rows to a Buildings
model (reduced-order zone + table heat pump + stratified tank + radiator + TMY3 reader), export an FMU, run in the
`-ompython` container, read `.mat`, map back to the same result rows — engine-agnostic contract, the provider-select
pattern Polari already has. **Winter survivability** = an evaluator over the hourly rows: every hour, critical
electrical loads supplied AND T_in ≥ T_safe AND the unheated pipe zone ≥ 0 °C; report the first failing hour and the
margins (kWh_th, °C-hours). PyPSA coupling: P_el_hp[h] = Q_hp[h] / COP(T_out[h], T_sink[h]) as a load series, or a
Link with COP as time-varying efficiency plus a heat Store, so electrical and thermal balances solve together.

**Gaps.** No measured OM runtime yet; a single-zone 5R1C has no stratification and no pipe-freeze physics (the freeze
check needs an explicit unheated-space node); hplib data are EU Keymark units (US units need NREL/AHRI tables);
US weather depends on NREL reachability.

**Recommended Polari App.** `thermal_house`: the thermal rows + the native RC engine + hplib COP + PVGIS/Meteostat
readers + WinterSurvivabilityEvaluator + the PyPSA load export; the OpenModelica adapter as an optional engine tier
(Buildings 13 in the `-ompython` container).

**Open questions (his).** Q-H1 OpenModelica in AGPL mode as a separate container — confirm with the licence gate;
Q-H2 first climate: EU (PVGIS/hplib native) or US (NSRDB/AHRI); Q-H3 T_safe and the freeze node: fixed policy or
per-house knobs; Q-H4 measure an 8760-h Buildings run before committing the adapter.

### 3.OSE Open Source Ecology — the reference house (survey 2026-09-15)

**What exists.** The Seed Eco-Home lineage: SEH1 (2016 swarm build), SEH2 "Rosebud" (1000 sf, built 2022, 4×8/4×9 ft
wall panels, flat roof, slab), SEH3 (training frame), **SEH4** (1300 sf, 3bd/2ba, Maysville MO, build from Dec 2022,
sold 2026 for $212k; materials $60k incl. 6 kW PV; labour $44.6k; 1589 h; inspection and structural PDFs; an OSHWA
certification graphic), SEH5 (2000 sf, foundation 2021), SEH6 (720 → 1400 sf expandable, Sep 2025), SEH7 (engineered
trusses, Dec 2025). Incremental design is real: pre-framed hidden doors for rear additions, window modules
convertible to doors, roofs framed for a third floor. A 16×10 ft forkliftable **utility core** (kitchen, bath, heat
pump, electrical, plumbing, PV on its roof) is offered from summer 2026 (~$20k service, own land) — the earlier
"utility panel" concept: stub-out plumbing, meter/breaker panel, a two-hour electrical install.

**Electrical/PV as documented.** 26 × 230 W panels (~6 kW), a plug-on-neutral service entrance, a transfer switch, PV
combiner + DC disconnect, a "power center" wall module, a 24 000 BTU heat pump (rated to −22 °F), induction cooktop,
tankless DHW. The hybrid-inverter page is shopping research (solar-priority modes, batteryless UL 1741); no as-built
inverter/battery model is recorded; **no measured energy data anywhere** — "zero energy" is a design claim. Thermal
storage is a concept ("PV thermal battery": a heat pump charging IBC-tote water banks, 3–12 days claimed; pond
"geothermal" cooling), several concept pages cite chat-assistant links as sources.

**Assets and formats.** Wiki (CC-BY-SA-4.0; infoboxes add GPLv3 + DIN SPEC 3105); ~100 FreeCAD `.FCStd` module files
(quad modules with MEP, PV mounts, heat-pump interfaces, spreadsheet-driven module generators); the SEH4 BOM as a
public Google Sheet (717 rows: item, link, specs, qty, source, price — CSV export works) and a build-time sheet (per
item hours); GitLab `SH4` (wiring and power-center FreeCAD, the whole-house file) and `seh-2-electrical` (135 electrical
iterations, STEP, **IFC exports from 2022**, an engineer's PDF; CC-BY-SA-4.0 + DIN SPEC 3105); GitHub `iconic-cad`
(browser wall layout → JSON → FreeCAD compiler, BOM estimator, experimental IFC4 export; AGPL-3.0; active 2026),
`vcs-library` (12-ft module library: schema, compiler, meta.yaml provenance, validators; a headless `freecadcmd` mesh
pipeline; NO SPDX file), the FreeCAD 1.x library workbench and a static catalogue site (no licence stated). Working
docs: nine Google Slides decks (~1000 pages), 22 000 photos. The "Schema Canon" ontology (parts → modules →
assemblies → master files → ecosystems, each emitting CAD, fab drawing, BOM, instructions, QC) is the pattern to map
onto Polari's composition rows.

**Licences.** CC-BY-SA-4.0 → GPLv3 is one-way compatible (CC's declared list): derived geometry/BOM data can live
inside Polari under GPLv3 with attribution, each record keeping its source URL and licence; AGPL-3.0 code
(iconic-cad) forked/pinned as `dausume/` mirrors, but linking it into a served backend pulls the network clause —
read its JSON schema, do not link; `vcs-library` = "OSE / CC-BY-SA claimed, unverified" until a LICENSE lands;
CERN-OHL-S hardware files are reference only. OSE's own policy: CC-BY-SA content, CERN-OHL-S hardware, AGPL
software, NC rejected — the same stance as ours.

**Integration.** (1) FreeCAD import: `freecadcmd` headless walks the whole-house document (or vcs-library compiled
entries) → per-module BREP/mesh + placement → House, floor groups → ThermalZone, wall modules → Wall (orientation
from the exterior face), window/door modules → Window/Door, roof files → Roof, the 26-panel array → PVSurface (tilt
and azimuth from placement), heat-pump/power-center modules → EnergyCell endpoints; prefer iconic-cad's JSON layouts
as the light topology schema (no FreeCAD needed). (2) BOM/cost ingestion: the sheet as CSV with row → URL provenance;
section totals as CostClaim rows (value, source URL, retrieved, method "OSE spreadsheet"); hours as LaborClaim rows
with a photo-evidence flag. (3) A reference-house profile `SeedEcoHome4` (1300 sf, two storeys, slab, 2×6 walls, flat
roof, 6 kW PV, 24 kBTU heat pump, induction, tankless DHW, Maysville MO climate) with SEH2 and SEH6 variants, and the
IBC-tote thermal battery as an UNVALIDATED storage model to test against climate data.

**Gaps.** Most template sub-pages are empty (electronics design, wiring & plumbing, vBOM, cut list); documentation
is scattered across wiki, Drive/Slides/Sheets/Photos, two GitLab namespaces and GitHub; no as-built inverter/battery
spec; no monitored energy data; cost claims vary by outlet ($40k / 5 days in the press vs $60k + $44.6k + 1589 h in
OSE's own sheets); SEH4 was engineered, inspected and sold (strong buildability evidence) but OSE also lists a
"rural off-grid, zero inspection" tier; IFC exports are 2022 / 1000 sf only; founder dependence is acknowledged in
OSE's own Sep-2026 roadmap; the GitHub repos have 0–1 stars.

**Recommended Polari Apps.** `ose_reference_house` (ingests SEH4/SEH2/SEH6 CAD + BOM as provenance-tracked reference
houses); the `energy_cells` consumer using SEH4 as the canonical test bed with the utility core as an EnergyCell
archetype; a `thermal_storage_sim` for the IBC-tote bank claims.

**What OSE gains.** A free energy/thermal simulation of the Seed Eco-Home they currently lack; provenance-tracked
cost and hour claims (their "Replication Readiness Level" idea needs exactly this); a consumer for iconic-cad and
vcs-library outputs beyond FreeCAD; a validator for Schema Canon BOM/cost assets.

**Open questions (his).** Q-S1 which inverter/battery was actually installed in SEH4 (ask OSE; Work Doc part 6);
Q-S2 will vcs-library and the library workbench get SPDX licence files; Q-S3 is the 2026 utility-core CAD published,
where; Q-S4 does OSE want telemetry from occupied units (our privacy rules apply); Q-S5 which IFC schema to standardise
on for OSE geometry (iconic-cad's IFC4 is experimental).

## 4. Chunking the work we do not have — the proposal

### 4.0 What the survey changed in the plan

- **Integrate, wrap, reference, reimplement — settled per project.** ThingSet + python-thingset: WRAP (Apache-2.0,
  adopt as the cell interface). Libre Solar firmware: WRAP over the protocol, vendor only the OCV/config tables as data,
  run the native_sim builds as the twin. PyPSA/linopy/HiGHS, pvlib, hplib, TEASER, Buildings/IBPSA: INTEGRATE as pip
  or Modelica dependencies (MIT/BSD). pandapower + dss_python: INTEGRATE (BSD). OpenModelica: INTEGRATE as a separate
  container in AGPL mode. **OpenEMS: REFERENCE only** — EPL-2.0 without the GPL secondary licence forbids vendoring;
  run Edge as its own container and speak JSON-RPC, transcribe register maps as data. OSE: REFERENCE DESIGN + BOM /
  cost / buildability EVIDENCE + ARCHITECTURAL PRIOR (CC-BY-SA data ingested with provenance; AGPL iconic-cad read as a
  schema, never linked). The 5R1C thermal core: REIMPLEMENT (200 lines, MIT reference). The per-circuit transfer
  device and the GRID-xor-MICROGRID proof: **Polari-owned** — nobody upstream has it.
- **Two adapters, not one, at the physical layer:** ThingSet for MCU-class cells (BMS, MPPT, relays), OpenEMS for
  third-party inverters/meters/EVSE over Modbus/SunSpec/OCPP. They are complementary layers; Polari owns topology,
  switching rules, planning and provenance above both.
- **Safety is UNPROVEN by default and the list of unprovable questions is explicit** (ground faults, arc faults,
  islanding, DC faults, transfer timing, comms loss) — the SafetyVerdict row carries every question separately.
- **The upgrade search lives in Polari, not in the solver:** PyPSA evaluates a candidate sequence as an LP; Polari
  searches sequences (≤ $300 steps, nothing obsoleted). The switch is a planning knob first (LP), an hourly MILP only
  for short windows.
- **The thermal engine starts native (numpy 5R1C, hplib COP, PVGIS weather)** and OpenModelica arrives as an optional
  engine tier once an 8760-h run has been measured.
- **The reference house is OSE's SEH4**, with the utility core as an EnergyCell archetype — and OSE's own gaps (no
  measured energy data, no as-built inverter spec) become the first things Polari can give back.

### 4.1 The modules (Polari app kinds; every one a Standard Polari App with a manifest, rows one-per-file, selftests)

| module | kind · category | what it holds | upstream |
|---|---|---|---|
| `energy_core` | library · platform | the canonical energy vocabulary (§1 App A) + ONE provenance row type + the four-status Feasibility row + the S0–S10 ladder | pspp/scoring rows reused |
| `energy_catalog` | polari-app · platform | TechnologyDefinition rows (App M): project, repo, commit, licence, files, capabilities, limits, interfaces, protocols, cost/performance claims, evidence — seeded from §3 | the licence gate |
| `energy_cell` | hardware-app · Network Apps → Network Devices / Hardware | the ThingSetAdapter, ThingSetDevice registry, LibreSolar BMS/MPPT adapters, the native_sim twin service on vcan, the OpenEMSAdapter (JSON-RPC), Polari-owned TransferDevice + switching state machine | ThingSet, Libre Solar, OpenEMS |
| `energy_cell_designer` | polari-app · Materials & Devices | App B: Solar-400/800/1200 classes, the validation rules (Voc cold, MPPT window, series/parallel, ratings) | electrodevice, composition |
| `house_energy` | polari-app · Food & Living / platform | App D: HouseElectricalSystem, circuits, conductors, breakers, the load taxonomy; App L's house schema + the FreeCAD/iconic-cad import; the OSE reference-house profiles | OSE |
| `energy_simulation` | polari-app · Knowledge & Media | App G: PyPSAEngineAdapter, scenarios, the 24 h / 8760 h runner, results as Table/Graph rows; App I's EV deadlines; App J/K's sequence search | PyPSA, pvlib |
| `electrical_safety` | polari-app · Materials & Devices | App F: PandapowerSafetyAdapter, TopologyState enumeration + graph proofs, EarthFaultLoopCheck, IslandingCompliance, SafetyVerdict | pandapower, dss_python |
| `thermal_house` | polari-app · Food & Living | App H: thermal rows, the native RC engine, hplib COP, weather readers, WinterSurvivabilityEvaluator, the PyPSA load export; the OpenModelica engine tier later | RC_BuildingSimulator (ported), hplib, Buildings |
| `microgrid_designer` | polari-app · Materials & Devices | App E: hard rules as rows, architecture candidates, the search calling safety + simulation | — |

### 4.2 Sprints and gates (each sprint ends with selftests, a conform pass, a ledger section, and his gate)

1. **Sprint 1 — the vocabulary and the catalogue.** `energy_core`, `energy_catalog` (seeded with the seven projects'
   TechnologyDefinition rows from §3, provenance on every field), the SEH4 reference-house profile in `house_energy`
   from the BOM sheet (CSV + row URLs), one Libre Solar-derived device (BMS C1) in the catalogue from its repo/commit
   /datasheet. Gate: the four statuses and provenance visible on the screens; nothing typed without a source.
2. **Sprint 2 — one Energy Cell simulated.** `energy_simulation` with the PyPSAEngineAdapter; 3 × Solar-400 + MPPT +
   battery + inverter + one circuit's loads; 24 h and 8760 h with PVGIS weather; results as Graph rows. Gate: the
   solver in the image (HiGHS musllinux), runtime measured, curtailment/unserved energy/cycles honest.
3. **Sprint 3 — the house and the invariant.** `house_energy` circuits with GRID / MICROGRID / DISCONNECTED states;
   `electrical_safety`'s TopologyState enumeration and the graph proof that no state energises a circuit from both;
   the SafetyVerdict with the UNPROVEN list; the switch as a schedule in PyPSA. Gate: an UNSAFE and an UNPROVEN
   architecture both shown with reasons.
4. **Sprint 4 — the physical cell.** `energy_cell`: the ThingSetAdapter against the native_sim twin on vcan in the
   compose stack (no hardware), then against a real BMS C1 / MPPT when one exists; the Polari-owned TransferDevice
   state machine (request → read-back; staleness = fault). Gate: the same adapter code against twin and hardware.
5. **Sprint 5 — thermal and winter.** `thermal_house` native engine + hplib + weather; the WinterSurvivabilityEvaluator;
   heat-pump electricity into PyPSA. Gate: the reference house in a winter week with a grid failure, honest margins.
6. **Sprint 6 — the planners.** EV deadlines (I), the upgrade-sequence search (J), the circuit-conversion order (K)
   — all evaluated by the sprint-2 adapter. Gate: a ≤ $300-per-month sequence for the reference house with nothing
   obsoleted, and its reasons.
7. **Sprint 7 — OSE and the comparison.** The FreeCAD/iconic-cad import path; SEH2/SEH4/SEH6 profiles; the OSE
   utility core as an EnergyCell archetype; the comparison of the OSE architecture vs the Energy Cell architecture as
   evidence rows, not a verdict. Gate: what each teaches the other, written down with sources.
8. **Sprint 8 — engines.** pandapower power flow + short circuit per state; OpenModelica engine tier (after the 8760-h
   measurement); OpenEMS Edge as a container with the JSON-RPC adapter; failure simulations (battery, cell, MPPT,
   transfer). Then the architecture search (E). Gate: SAFE reachable for at least one architecture with every modelled
   question passing, UNPROVEN still listed.

Hardware-in-the-loop stages S0–S10 and the reference experiment (§21 of his plan: 8 kWh/day, Solar-400, ≤ 1200 W
cells, two EVs, the ten scenarios) are rows from sprint 1 and run from sprint 2 on; nothing physical before S2's
safety-review gate row is signed.

### 4.3 What this gives Libre Solar and OSE

- Libre Solar: system-level simulation and planning around their BMS/MPPT (they have none), provenance-tracked
  device configs, fleet views over ThingSet, the AC-side story (transfer switching) they lack; a PR opportunity — a
  BMS-IC mock upstream — and a second serious ThingSet consumer.
- OSE: the first energy/thermal simulation of the Seed Eco-Home, provenance-tracked cost and hour claims (their
  Replication Readiness Level needs exactly that), a consumer for iconic-cad/vcs-library beyond FreeCAD, a validator
  for Schema Canon BOM/cost assets, and an EnergyCell reading of their utility core.
- Both: a place where "designed / simulated / tested / permitted" are kept apart, so experimental architectures the
  codes do not yet permit can still be studied honestly.

## 5. Decisions for him

- **D-E1 Jurisdiction first:** IEC 230 V TN/TT or NEC 120/240 split-phase — decides OpenDSS vs pandapower alone,
  ampacity tables, and the ground-fault check.
- **D-E2 ThingSet as the preferred cell interface now (v0.6, pre-1.0)**, with OpenEMS for third-party inverters.
- **D-E3 The switch semantics:** EXEC with state read-back, or UPDATE of a writable item; and Polari's transfer-device
  hardware, if we design one, under CERN-OHL-W to match Libre Solar.
- **D-E4 Is a UL 1741-SB / IEEE 1547 certificate acceptable evidence for islanding, or does it stay UNPROVEN?**
- **D-E5 The switch in planning: a schedule (LP) by default, MILP only for short windows.**
- **D-E6 First climate and weather source:** EU (PVGIS + hplib native) or US (NSRDB + AHRI); the reference house is in
  Missouri.
- **D-E7 OpenModelica in AGPL mode as a separate container — accept?** (legally clean; confirm with the licence gate.)
- **D-E8 OpenEMS: ask the OpenEMS Association for the GPL secondary licence?** Until then, process boundary only.
- **D-E9 Accept PyPSA's ~300 MB geo/plot dependency tail in the engine image, or a slimmer image with the solver only?**
- **D-E10 Sprint order as above, or pull Sprint 4 (the physical cell) forward because hardware is on hand?**
- **D-E11 Contact:** open the conversation with Libre Solar (forum) and OSE (wiki/roadmap) now, or after Sprint 2
  shows something?
