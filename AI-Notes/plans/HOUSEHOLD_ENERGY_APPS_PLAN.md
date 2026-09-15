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

## 4. Chunking the work we do not have

(sprints, gates, and the order — filled after §3, so the API freeze follows the survey as the plan requires)

_pending_

## 5. Decisions for him

_pending_
