# Polari Compute LOD + Tensor Architecture — COUNTER-PLAN (Polari side, 2026-09-23)

_Written as correspondence to the ChatGPT planning thread. The first draft ("Polari Compute LOD + Tensor
Architecture Revision Plan", Dustin ↔ ChatGPT) is accepted as the frame; this document is the reply from the
side that knows what Polari has actually built, and it is meant to be pasted back for the next round. Sections:
A what already exists (so the plan lands on it instead of beside it), B the amendments, C the merged plan with
slices, D open decisions, E questions for ChatGPT._

---

## To ChatGPT — from the Polari codebase side

Thank you for the draft. I agree with its objective, its eight questions, its "mappings not containment" rule,
the ComputeMapping/LearningMapping split, the TensorTree structural rules, UnresolvedTensorSpace, the
VISUALIZE → SELECT → DISCOVER → MAP cycle, and TensorOperator → ComputeImplementation[]. Those stand.

What follows is grounded in the code. Polari already has, in production modules: a matrix module, a
multi-scale materials module with five resolution levels, a PSPP materials framework, a ratified microchip
design ladder, transistor/standard-cell/RTL/FPGA work, a tech tree with dependency edges, and a no-code engine
with a matrix-equation node. The draft was written as if those did not exist; most of its objects are either
already there under another name, or must be built as extensions of what is there. Polari's standing rules
also constrain some of it (a display is a configured table/graph/registered component, never a raw-JSON panel;
the chart home is one component; every capability is an explicit knob plus an evidence-bearing suggestion;
every number derived or cited; specialization is a KIND at an existing rung, never a new ladder; everything
goes through the object-tree standard for DB + API).

So the counter-plan does three things: names what to REUSE, lists the AMENDMENTS, and re-sequences the phases
so every slice is provable on existing pages with existing data.

---

## A. What Polari already has (the plan must land on these)

**A1 — Matrix module (`polari-framework/matrices/`, numpy-backed):** `MatrixDefinition` (name, `shape_json`,
`element_type`, `element_matrix_ref` — a matrix of matrices, `values_json`, `computation_json`, `is_template`),
`MatrixEquationDefinition` (LaTeX + `operation_json` + `operands_json`), `MatrixAPI` / `MatrixEquationAPI`,
executors; and the no-code node `MatrixEquationOperation` (binds operands to RUNTIME context, not stored
entities — the "passed in new ways" model). This IS the draft's MatrixModule. TensorMath delegates to it.

**A2 — Sim spaces = the existing DimensionVisualization:** `SimSpaceDefinition` (2d/3d, coordinate system,
viewport, LaTeX axis labels) + `SimSpaceBindingDefinition` (per class + dimensionality, `binding_json` maps
FIELDS → position / shape / style channels), rendered by `sim-space-2d` / `sim-space-viewer` (3D, three.js;
vector-arrow fields proven in the wind→pendulum coupling). The draft's TensorNode "DimensionVisualization"
with channels X/Y/Z/color/size/glyph/vector is what a binding already is; the plan extends the binding vocabulary
(color ramp, glyph, texture, opacity, animation/time) rather than defining a second visualization object.

**A3 — Charts and graphs:** `sci-xy-chart` is THE home for line/scatter/band/stick/errorbar plots (Observable
Plot); the Graphs main page + `graph-renderer` + `GraphDefinition` rows are the no-code graph authoring path.
Rule: never a new chart engine. Rank-1 and rank-2 slices of a tensor render through these; rank-3 spatial fields
render through the sim space; the "influence"/"kernel" visualizations are glyph/arrow bindings in the sim space.

**A4 — Multi-scale materials (`modules/materials_science/objects/resolutions/`):** five `ResolutionCategory`
levels — experimental (mm–m), continuum/FEM (`consistentFiniteElementMaterial`), mesoscale/CGMD, atomistic/MD
(`molecularDynamicsMaterial`), quantum/DFT — under one `Material`; plus `MultiScaleSimulationDefinition`
(members, couplings, primary sim) and `SimulationCouplingDefinition` (source sim/class → target sim/class via a
`sampler_equation_ref`, `config_json`) — a real, running cross-space coupling (wind field → pendulum force).
The draft's TensorScaleMapping / TensorCoupling ARE couplings; they get a tensor-aware kind, not a new class
family. The STATISTICAL vs DISCRETE representation split (pspp/gsp engine vs msci/ssp engine) is already the
engine boundary; encapsulation is the transform edge between them.

**A5 — PSPP (`modules/pspp`, merged, 35 selftest suites):** `MaterialState` DAG with `ProcessingStage` rows,
Property / Structure / ValidationClaim with `EvidenceMethod` provenance, DigitizedDataset with an
"UNSUPPORTED extrapolation" refusal. The draft's Fabrication Process (materials → processing → structure →
properties → performance) is literally PSPP; the Materials level is the msci/pspp data. Nothing new is built
there — the compute ladder's two bottom rungs POINT at PSPP rows.

**A6 — The microchip design ladder (ratified 2026-08-31, `modules/microchip`):** `device → standard-cell →
functional-block → subsystem → die → package/chiplet-assembly`, ending there; rank 6 exports ONE black-box
part into `composition` (computers, motors, RF nodes are composition clients). Specialization = KINDS at
existing rungs (subsystem kinds cpu-core / gpu-compute-unit / npu-tensor-array / sim-engine / memory-controller;
bitcells are rank-2 cells). lad-5 = workload-profiled sim chips from real `MatrixEquationOperation` usage. THIS
IS the draft's hardware half of the Compute LOD, already ratified: transistors = device rung, standard cells =
cell rung, logic/netlist = functional-block rung, microarchitecture = subsystem rung (kinds), die, package.
The draft must not introduce a second ladder; it ADDS the software rungs above (RTL as the description language
of rungs 3–5, then ISA, compiler, C) and the physical rungs below (layout, fabrication = PSPP, materials = msci).

**A7 — Transistors, cells, FETs (`cntfet`, `sifet`, fi/fv/fp arcs):** a model-agnostic `device_model` (VS-CNFET
compact model + Si physics), 7 Si devices + CNT devices, 25 standard cells proven at switch level (INV…FA, TBUF,
latch), d3 `cell-logic-diagram` + `cell-schematic` (step-through proofs), Liberty as the truth for nom_voltage,
FO4/clock-range ladder, `FETTargetMapping`, Verilog-A/OSDI twin, SPICE via ngspice, OpenSTA; compute delegates to
the cnt-engines worker (dist-1). The draft's Transistors and Standard Cells levels exist with evidence rows.

**A8 — RTL / FPGA (`hwfpga`, `grpcbridge/custom/renode_twin`):** RTL is GENERATED from `RegisterMapDefinition`
+ `RegisterDefinition` rows (`render_core` → `polari_regblock.v` Verilog-2001 AXI4-Lite; `render_sim_top`;
`render_testbench` → `tb.sv` SystemVerilog under `verilator --binary`; `sim_main.cpp` co-sim with Renode;
`<map>_regs.h` firmware twin). `hwdigital` exists. Tools present or planned and all open: Verilator, Renode,
Yosys, nextpnr, ngspice, OpenVAF, OpenSTA; OpenROAD/OpenLane/Magic/KLayout and SKY130 are the open-silicon
ladder's named targets (fp arc). RISC-V open cores are admissible under the licence gates (PicoRV32 ISC, Ibex
Apache-2, VexRiscv MIT, CVA6 Solderpad, Rocket/BOOM BSD).

**A9 — Tech tree (`modules/techtree`):** `TechTreeDefinition`, `TechSegment`, `TechNode` (`depends_on_json`,
`cross_refs_json` into other modules' rows, `data_dependencies_json`, layout hints), `TechDependencyEdge`
(`is_primary`, `is_transient`). Trees exist for electronics / raw-supply-chain / os-economy-politics; the
materials-science tree (mtt-1) is planned. The draft's ComputeConcept + LearningMapping layer is a tech tree:
concepts are TechNodes, prerequisite edges are TechDependencyEdges, and `cross_refs_json` is the link from a
concept to the compute object it is about.

**A10 — Composition + computers (`composition`, `computerparts`, `computers`):** parts, assemblies, profiles,
gates (fit engine); `hwmap`, `electrodevice`, `motors`, `magnetics`, `printing_suite`/`voron` = the "electronics
beyond computers" examples the draft asks for, already as modules.

**A11 — The no-code engine (`polariNoCode`):** `SolutionDefinition` graphs, `SolutionExecutionEngine`,
`CalculusOperation`, `MatrixEquationOperation`, `EquationDefinition` (SymPy). Audit 2026-07-03: not Turing
complete in practice (loops/function-call stubs); frontend execution is a label. A TensorOperator node must
follow the `MatrixEquationOperation` pattern (registry entry + dispatcher + overlay) and must not pretend the
engine can do what the audit says it cannot.

**A11b — Facts the code survey added (2026-09-23), each of which REMOVES a new class from the draft:**
- `MatrixDefinition` is already rank-N: its docstring says "matrix/**tensor**", `shape_json` accepts `[2,3,4]`,
  `element_type` includes `matrix` (block composition) and `equation`; values are JSON on the row, numpy at
  runtime. So the literal storage of a small tensor IS a MatrixDefinition row (B4 amended below).
- `MultiScaleSimulationProfile` already carries `scale_levels_json`, a **`fidelity_ladder_json`** (rung, level,
  engines, costClass cheap|moderate|expensive, purpose screening|verification|evidence) and
  `coupling_shapes_json` `[{from,to,mechanism derive|coupling}]`; `MaterialScaleDefinition` (`<material>@L<n>`,
  scale_level 0–4, status defined|partial|planned, derivation_method) + `scale_presence.presence_matrix` /
  `level_accountability` are the multi-scale accountability already in place.
- PSPP already has **`ScaleTransferDefinition`** (`source_state_key, source_scale, target_state_key,
  target_scale, transfer_method, transported_json, assumptions_json, validity_json, uncertainty_json, status,
  validation_evidence_json`) — that is the draft's TensorScaleMapping for materials, column for column; and
  `PropertyClaim.value_json` is documented as the home of tensor-valued properties; `LadderRung.tech_node` links
  PSPP to the tech tree.
- `microchip` has `DesignLevelDefinition` (`rank`, `scale_axes_json`, `artifact_classes_json`, status),
  `MicrochipDesignNode` (`level`, `parent`, artifact refs, citation, metrics) and `DeviceFamilyDefinition`
  (physics, contract, composes) with the `microchip-ladder` panel — the hardware rungs of ComputeLOD are these
  rows by reference (the ladder ends at package by ruling; ComputeLOD is a separate ordered list that points
  at them).
- `techtree` has `TechSegmentAssignment` with `segment_kind` theory|real|business|politics whose `ref_name`
  resolves to a module id / RealArtifact / BusinessModel / Policy, and `TechNode.data_dependencies_json` →
  DigitizedDataset names. A ComputeConcept's "tools/languages/example projects" are segment assignments.
- `electrodevice` has `PinBindingDefinition` (`level_bridge_basis.py`) — the MCU-pin → circuit bridge the
  draft's "electronics beyond computers" chain needs — plus `SpiceModelCard`, `CircuitDefinition`,
  `DeviceValidationReport`; `sifet` has `SiliconProcessNode` (the process-node ladder).
- The frontend panel registry (`ComponentRegistry.ts`) lists 49 registered components incl. `sim-space-viewer`,
  `microchip-ladder`, `pspp-state-dag`, `named-graph-panel`, `class-rows-table`, `api-structured-panel`;
  `sci-xy-chart` is consumed by components, not registered itself; `api-json-panel` is deprecated.
- No `Tensor` class exists anywhere; the only tensor code is in the FEM engine (real stress tensors,
  `MeshTri.init_tensor`) and the meso engine (gyration tensor) — Phase 3's data is already computed there.

**A12 — Rules that bind (Dustin's):** object coherence (every capability maps to an object-tree node);
knobs + evidence-bearing suggestions; derive-or-cite every number; per-object display config; no raw JSON on
screens; keep files small, split by concern; module = `polari-app.json` + `objects/<pkg>/<Class>.py` one class
per file + `<mod>_basis.py` + `_page.py` (configured tables/panels) + `_seed.py` + `_selftest.py` with the class
count asserted; each confirmed phase = its own branch off dev.

---

## B. Amendments to the draft

**B1 — One ladder, extended; not a parallel "Compute LOD" list.** The canonical stack becomes ONE ordered
list, `ComputeLOD`, whose hardware rungs ARE the ratified microchip ladder rungs (same names, same rows), with
software rungs above and physical rungs below:

    C  →  compiler  →  ISA  →  microarchitecture (= ladder rank 4 subsystem, KINDS)  →  RTL (the description of
    ranks 3–5)  →  logic/netlist (= rank 3 functional-block)  →  standard cells (= rank 2)  →  transistors
    (= rank 1 device)  →  layout  →  fabrication (= PSPP ProcessingStage chain)  →  materials (= msci/pspp rows)

  `die` and `package` stay as ladder rungs between microarchitecture and layout for the ASIC path; the FPGA path
  ends at "FPGA resources" (a kind of rank-5/6 part). Firmware complexity H1–H4 is a KIND on the C rung, not a
  rung.

**B2 — Mappings are rows with evidence, and the reverse is a different row.** `ComputeMapping` (downward:
"how is this implemented") and `CharacterizationMapping` (upward: "what does this produce") are two classes,
both carrying `kind` (one-to-one / one-to-many / many-to-one / approximate / alternative / unresolved /
partial), `validity_json`, `loss_note`, `uncertainty_json`, `evidence_ref` (an `EvidenceMethod`/ValidationClaim
or a benchmark row), `status` (theoretical | implemented | measured). A mapping with no evidence is allowed and
is rendered as theoretical. This is the same shape `FETTargetMapping` already has.

**B3 — LearningMapping = tech-tree edges; do not build a second graph.** `ComputeConcept`, `ComputeLanguage`,
`ComputeTechnology` are TechNode KINDS in a new tree `compute-lod` (segments = the rungs). Prerequisites are
`TechDependencyEdge` rows (`is_primary` = required, `is_transient` = recommended). The concept → object link is
`cross_refs_json`. "Learning order ≠ implementation order" is then free: the tree's edges and the ladder's
mappings are different rows.

**B4 — Tensor is a first-class row; its VALUES live where they already can.** `Tensor` (rank, `shape_json`,
dtype, `dimensions_json` naming each axis — `unknown` allowed, units, semantics, `storage_kind`, `storage_ref`).
Storage kinds: `matrix` = a `MatrixDefinition` row (already rank-N, JSON values, numpy at runtime — the small
case, up to the D2 floor); `dataset` = a `DigitizedDataset` / file reference (the large case; never megabytes
in a JSON column); `engine` = a live engine state (FEM/meso mesh tensors, sim state fields) read on demand;
`claim` = a `PropertyClaim.value_json`. No `TensorStorage` class. Rank-≤2 operations delegate to the matrix
executors; higher-rank named-dimension operations are `tensormath`'s numpy code. Matrix-of-matrices
(`element_type=matrix`) is the block-tensor case and stays in the matrix module.

**B5 — TensorNode visualization = sim-space bindings.** A `TensorNode` owns `LocalizedDimension` rows and ONE
`SimSpaceBindingDefinition` (extended `binding_json` vocabulary: position x/y/z, color ramp, intensity, opacity,
size, glyph, vector, texture, orientation, time/animation, label). The invariant "every localized dimension has
a coherent visualization" is a validator on that binding (unbound dimension → the node is not resolved; it
degrades to an UnresolvedTensorSpace with the binding as a candidate). Rank-1/2 views render in `sci-xy-chart`
via a GraphDefinition; rank-3 spatial views render in the 3D sim space. No new renderer.

**B6 — TensorMapping kinds are a `kind` column, plus couplings.** One class `TensorMapping` with `kind` ∈
{projection, reconstruction, decomposition, aggregation, restriction, scale, basis-transform,
coordinate-transform, operator, kernel, coupling}, `source_node`, `source_dims_json`, `target_node`,
`target_dims_json`, the B2 evidence columns, and `expression_ref` (a `TensorMathExpression` or a
`MatrixEquationDefinition`). `kind=scale`/`coupling` mappings are ALSO written as `SimulationCouplingDefinition`
rows (the sampler is the mapping's expression) so the existing runner executes them — tensor-aware couplings,
not a second coupling engine. For MATERIAL scales specifically, a `kind=scale` TensorMapping is a
`ScaleTransferDefinition` (PSPP) by reference — same validity/uncertainty/status columns, one row, not two — and
the fidelity/cost of taking it comes from `MultiScaleSimulationProfile.fidelity_ladder_json`.

**B7 — TensorSelection is a row, and discovery is a query with evidence.** `TensorSelection` (node, per-dimension
ranges, created-from-display ref). "Discover compatible mappings" = the mappings whose `source_dims_json` are
satisfiable by the selection's dimensions, ranked by evidence status (measured > implemented > theoretical),
returned as an evidence-bearing SUGGESTION list — the user picks (knobs + suggestions rule). The click on a
sim-space or chart is wired through the existing display event path (a display item emitting a selection,
which today is the weak part of the no-code frontend — see A11 — so slice 2 builds it as a backend-created row
from an explicit "select" panel action, not as a frontend-executed solution).

**B8 — TensorGraph is a view, not a table.** `GET /api/tensortree/<tree>/graph` = structural edges + all
TensorMappings; rendered by the existing node-graph views (msim composition graph / techtree renderer). No
TensorGraph rows.

**B1a — The hardware rungs are `DesignLevelDefinition` rows by reference.** `ComputeLOD` rungs carry
`design_level_ref` where a microchip rung exists (device, standard-cell, functional-block, subsystem, die,
package); the software rungs (C, compiler, ISA) and physical rungs (layout, fabrication, materials) are
ComputeLOD rows with `design_level_ref` empty and `pointer` to the owning module (PSPP / msci). The
`microchip-ladder` panel renders the middle; the compute-lod page renders the whole list around it.

**B9 — TensorOperator → ComputeImplementation[] lands on lad-5.** `ComputeImplementation` (target rung/kind,
precision, shapes_json, latency, throughput, memory, energy, error, configuration overhead, `evidence_ref` =
a benchmark row from a REAL run — derive-or-cite). The CPU implementation is the matrix module's numpy path
measured on the running node; PyTorch is optional and gated (a knob + licence check); the FPGA kernel is the
`hwfpga` render path with a tensor-kernel register map. lad-5's WorkloadProfile rows (profiled
MatrixEquationOperation usage) become the workload side of the same comparison.

**B10 — Validation problems, re-based on existing data.** A (3-D temperature field) uses the wax print/cure
thermal state that already exists as a sim (waxprint); B (continuum mechanics) uses the FEM continuum resolution
of msci with a real material's C_ijkl (cited, Liberty-style provenance); C (Green/kernel) uses the wind→pendulum
coupling as the first kernel (sampled field → force), then a heat kernel; D (decomposition) uses numpy CP/Tucker
on A's field with error metrics as rows.

**B11 — The cross-level demonstration is a TEST, in the repo, gated.** σ = C:ε traversed to gates on one open
core: PicoRV32 (ISC) for `add`, Verilator + Yosys (`synth` → netlist → cell count against the cntfet/sifet cell
library rows), OpenSTA for timing; the SKY130 path via OpenROAD/OpenLane is Phase 5. Every rung's row must be
producible from a script the selftest runs (Yosys and Verilator in the backend image are already there for
hwfpga); nothing hand-drawn.

**B12 — Language choice at the RTL rung.** Keep the generated synthesizable RTL Verilog-2001 (widest tool
reach: Yosys, all vendor tools, Icarus) with SystemVerilog for testbenches (Verilator) — the state today. SV RTL
is a `ComputeLanguage` alternative on the same rung, not the default; Chisel/Amaranth/SpinalHDL are later
languages on the same rung with a `generates → Verilog` mapping.

**B13 — Scope discipline.** No PyTorch/GPU rung is required for Phase 6; a GPU is a `ComputeImplementation`
target that exists only when a benchmark row exists. No new visual channel is "hard-coded to a quantity" — a
binding is data, per B5. Nothing from the draft's technology lists is installed until the slice that needs it.

---

## C. The merged plan — slices (each = one branch off dev, provable on pages with seeds)

**Phase 1 — Ontology (tt-0, ~1 slice).** New modules, each in the standard shape (A12):
- `tensormath`: `Tensor`, `TensorDimension`, `TensorStorage`, `TensorMathExpression` (named-dimension
  expression: contraction/product/permute/slice/reshape/reduce/derivative/integral; `matrix_equation_ref` when
  rank ≤ 2), `TensorOperator`, `ComputeImplementation`, `TensorDecomposition` (CP/Tucker result rows).
- `tensortree`: `TensorTreeDefinition` (one root), `TensorNode`, `UnresolvedTensorSpace` (known dims/semantics/
  constraints/candidate mappings/candidate bindings/hypotheses/evidence/open questions — all columns),
  `LocalizedDimension`, `TensorMapping`, `TensorSelection`. Structural rules 1–6 as validators in
  `custom/tensortree_validate.py` (one root, one structural parent, acyclic; mappings may cross).
- `computelod`: `ComputeLOD` (the ordered rungs; `design_level_ref` for the six microchip rungs),
  `ComputeMapping`, `CharacterizationMapping`; the `compute-lod` tech tree seed (concept / language /
  technology as TechNode kinds; edges = prerequisites; tools and example projects as `TechSegmentAssignment`
  rows of kind `real`/`theory`).
- Pages: configured tables per class + the tree/graph views through the existing node-graph renderer. Selftests
  assert class counts, the validators, serialization round-trips, and "unknown semantics is a valid Tensor".

**Phase 2 — Small executables (tt-1).** Tensor storage + named dims + contraction/slice/reduce via numpy with
matrix delegation proven (rank-2 ops produce the same `MatrixEquationDefinition` result); a 3-node TensorTree over
the waxprint thermal field; bindings (x/y/z→position, T→color) rendered in the 3D sim space; a `TensorSelection`
created from a panel action; mapping discovery returning ranked suggestions. Validation A.

**Phase 3 — Physics (tt-2).** Continuum mechanics on the msci FEM resolution: displacement → strain
(derivative mapping) → stress (rank-4 contraction, C_ijkl cited) → force balance; rank-2 views in sci-xy-chart,
the σ field in the sim space; interop with the matrix module for the Voigt form. Validation B; C via the
existing wind→pendulum coupling re-expressed as a `kind=kernel` TensorMapping; D via decomposition rows.

**Phase 4 — Compute mapping, one operation (lod-1).** `c = a + b`: C source row → GCC/LLVM row →
`add x5,x6,x7` (RV32I) → PicoRV32 ALU/regfile (subsystem-kind rows) → the core's RTL module row → Yosys netlist
row (cell histogram) — each edge a `ComputeMapping` with status; the reverse `CharacterizationMapping` edges
(cell delay → adder timing via OpenSTA → instruction latency) for the ones we can measure. The concept tree
for each rung seeded with prerequisites. Navigable on the compute-lod pages.

**Phase 5 — Open silicon (lod-2).** Netlist → standard cells (existing cntfet/sifet cell rows + SKY130 Liberty
rows) → transistor rows (device_model) → layout via OpenROAD/OpenLane in the engines worker (dist-1 pattern) →
SKY130 process as PSPP ProcessingStage rows → materials rows. The fp arc's open-silicon ladder is this phase.

**Phase 6 — Tensor hardware (tt-3 / lad-5).** σ = C:ε as a `TensorOperator` with three `ComputeImplementation`
rows: numpy (measured on the node), optional PyTorch (knob), `hwfpga` tensor-kernel register map → RTL → Verilator
cycle count (measured). The comparison page = the lad-5 workload-profile page. Benchmarks are rows with provenance.

**Phase 7 — Multiscale integration (tt-4).** FEM / MD / DFT resolutions, PSPP, TensorTrees, ComputeLOD joined
by explicit `TensorMapping kind=scale|coupling` rows executed as `SimulationCouplingDefinition`s; the
STATISTICAL/DISCRETE boundary and encapsulation edge appear as mappings with their validity domains.

Order of value: Phase 1 + 2 first (they make every later row displayable), then 4 (the teaching path Dustin
described), then 3, then 6, 5, 7.

---

## D. Decisions for Dustin (the plan does not assume them)

- **D1** The ONE ladder (B1) — confirm the software rungs sit above the ratified microchip ladder and the physical
  rungs point at PSPP/msci, with no second ladder. (Recommended yes.)
- **D2** Tensor storage floor: inline `values_json` up to N elements (suggest 4096), file/dataset reference above.
- **D3** The first spatial field for Phase 2: waxprint thermal (recommended — exists) vs a synthetic T(x,y,z).
- **D4** The open core for Phase 4: PicoRV32 (smallest, ISC) vs Ibex (Apache-2, pipelined — closer to "real").
- **D5** Whether PyTorch is admitted at all (BSD-3, fine by the gates; heavy dependency) or Phase 6 compares numpy
  vs FPGA only.
- **D6** SV RTL as default (B12) — recommended NO for now; Verilog-2001 generated, SV testbenches.
- **D7** Where the compute-lod pages live: a new `computelod` module (recommended) vs extending `microchip`.

---

## E. Questions back to ChatGPT (for the next round)

1. Given B1, propose the exact `ComputeLOD` rung list with each rung's KIND vocabulary (e.g. microarchitecture
   kinds: in-order / pipelined / OoO / vector / tensor-array) so kinds never become rungs.
2. For `CharacterizationMapping` (B2): which upward mappings are worth building first — the delay/power chain
   cell → block → instruction is measurable with OpenSTA + Verilator today; what is the minimum evidence each row
   must carry to be more than a label?
3. For TensorMapping discovery (B7): a ranking rule that uses evidence status, dimension compatibility and
   validity domain — proposed as a scoring formula we can implement as one function and test.
4. A minimal `binding_json` vocabulary for the visual channels (B5) that covers Validation A–D without inventing a
   channel we cannot render in Observable Plot or three.js.
5. For Phase 4: the smallest honest `c = a + b` chain — should the compiler rung show the LLVM IR row too, or is
   C → ISA enough for the first slice?
6. Anything in the draft that this counter-plan drops that you believe is load-bearing.

---

## F. Round 2 (2026-09-23) — ChatGPT's answers to E1–E6, merged; the plan of record from here

_ChatGPT accepted A/B/C and answered E1–E6; the Polari side accepts those answers with the notes below. D1–D7
are now RECOMMENDED BY BOTH SIDES and await Dustin's ratification (§G)._

### F1 — The ComputeLOD ladder (E1): eleven conceptual rungs; die/package hang off microarchitecture

    SOFTWARE / FIRMWARE      1 C / Source · 2 Compiler · 3 ISA / Machine Instructions
    HARDWARE ARCHITECTURE    4 Microarchitecture · 5 RTL
    DIGITAL IMPLEMENTATION   6 Logic / Netlist · 7 Standard Cells · 8 Transistors / Devices
    PHYSICAL IMPLEMENTATION  9 Layout · 10 Fabrication Process · 11 Materials

`die` and `package` are NOT rungs of this ladder: they answer "how are physical artifacts assembled", not an
abstraction transition. Rung 4 (and 6/7/8) carry `design_level_ref` into the microchip ladder
(functional-block / subsystem / die / package stay authoritative there). Amends B1/B1a accordingly.

**KIND vocabulary (initial; a KIND specializes within a rung and never creates a rung):**

| rung | kinds |
|---|---|
| C | direct-firmware, freertos, zephyr, linux-kernel |
| Compiler | frontend, optimizer, backend, assembler, linker |
| ISA | base-isa, extension, privilege, vector, matrix-tensor, custom |
| Microarchitecture | single-cycle, multicycle, in-order, pipelined, superscalar, out-of-order, vector, tensor-array, gpu-like, memory-controller |
| RTL | datapath, control, register-map, bus-interface, accelerator, core |
| Logic/netlist | combinational, sequential, arithmetic, memory, control, interconnect |
| Standard cell | inverter, buffer, logic-gate, mux, sequential, arithmetic, clock, bitcell |
| Device | mosfet, cnfet, diode, capacitor, resistor, interconnect-device |
| Layout | cell-layout, block-layout, macro-layout, die-layout |
| Fabrication | lithography, deposition, etch, doping, anneal, planarization, metallization, packaging-process |
| Materials | semiconductor, conductor, dielectric, resist, dopant, substrate, packaging |

Polari note: kinds are a `kind` column validated against a per-rung list seeded as rows (`ComputeKind`), so a
new kind is a row, never a code change; the microchip subsystem kinds (cpu-core, npu-tensor-array, sim-engine…)
remain the microchip ladder's and map onto rung-4 kinds by `design_level_ref`.

### F2 — CharacterizationMapping columns (E2)

Every non-theoretical characterization carries: `source_ref, target_ref, characteristic, method, conditions_json
(voltage, temperature, load, process/corner — load-bearing), result, units, evidence_ref`, and TWO statuses:
`mapping_status ∈ {proposed, implemented, validated}` and `evidence_level ∈ {none, analytical, simulated,
measured}`. An OpenSTA/ngspice number is `simulated`, never `measured`; `measured` is reserved for fabricated
hardware. The same two columns go on `ComputeMapping` and `TensorMapping` (amends B2/B6). First upward chain:
device → cell timing/power → block → microarchitecture timing → instruction latency/throughput.

### F3 — TensorMapping discovery (E3): hard filters, then a configured score

Candidate only if required dimensions ⊆ selection dimensions, units/types compatible, and the selection lies
inside the mapping's validity domain — an invalid mapping is never rescued by scoring. Rank survivors by
`Score = 0.30·E + 0.25·D + 0.25·V + 0.10·C + 0.10·(1−U)` (E evidence quality, D dimension-match quality, V
validity coverage, C contextual relevance, U normalized uncertainty), with the evidence map measured 1.00 /
validated-simulation 0.85 / implemented 0.65 / analytical 0.40 / proposed 0.20. Weights and the evidence map
are CONFIGURATION rows (`TensorDiscoveryPolicy`), not constants — the knobs rule. Implemented as one function
with its own selftest.

### F4 — Visual channel vocabulary (E4): small, with scales inside the channel

`position.x, position.y, position.z, color, opacity, size, shape, orientation, vector, label, time`. No
texture/glyph/surface-deformation in the first vocabulary. `shape` selects registered renderable geometry;
`vector` is the proven arrow; `color` carries its scale: `{"field": "temperature", "channel": "color", "scale":
{"kind": "continuous", "domain": [300, 900]}}`. This is the `SimSpaceBindingDefinition.binding_json` extension
(B5). Coverage: A T→color; B u→vector, σ principal direction→orientation + magnitude→size/color; C influence→
vector/size/color; D through charts (sci-xy-chart) not 3D.

### F5 — The compiler rung in lod-1 (E5)

C → Compiler → ISA stays the canonical path. LLVM IR is an artifact of ONE compiler implementation, so it is a
`CompilerArtifact` row (`kind ∈ AST, IR, assembly, object`) attached to the Compiler rung only when a slice
needs it. lod-1 uses GCC for PicoRV32 and shows: C `c = a + b` → GCC → RISC-V assembly `add …` → the encoded
machine instruction `0x…` → PicoRV32 decode → register file → ALU → writeback. That is the teaching path.

### F6 — Four protections during implementation (E6)

1. **Local, not subtree, validity:** a TensorNode is valid by its own visual coherence; an unresolved space
   below it does not invalidate it (the validator checks the node's own bindings only).
2. **Typed unresolvedness:** `UnresolvedTensorSpace.unresolved_kind ∈ {semantic, structural, visualization,
   mapping, validation}` (a column; subclasses later if ever) — different research tasks.
3. **Information loss kept:** projection/decomposition mappings carry `reconstruction_error` (‖X−X̂‖/‖X‖) and
   `error_method` next to the evidence columns.
4. **Trees stay plural:** `Tensor ↔ TensorTree*` — spatial, scale, modal, decomposition, operator trees over the
   same tensor; no canonical-tree column on Tensor.

### F7 — Decisions D1–D7, both sides' recommendation

- D1 one conceptual ladder referencing authoritative module objects — YES.
- D2 no element-count threshold; storage by representation/persistence need (matrix | dataset | engine | claim).
- D3 waxprint thermal first.
- D4 PicoRV32 first; Ibex later as a second microarchitecture for the same ISA.
- D5 PyTorch optional and deferred; numpy → FPGA proves the abstraction.
- D6 Verilog-2001 generated RTL + SystemVerilog testbenches.
- D7 a new `computelod` module; `microchip` stays authoritative for its ladder.
- Phase order: **1 → 2 → 4 → 3 → 6 → 7 → 5** (Phase 5's physical-design toolchain only when a microchip
  milestone needs it).

### F8 — The bridge to protect

    TensorOperator → ComputeImplementation → ComputeLOD

A scientist clicking σ_ij = C_ijkl ε_kl moves sideways through its TensorTree (what it means) or downward
through ComputeImplementation (how it becomes instructions, RTL, gates, transistors, materials). Both
navigations are rows; the intersection is one row class.

---

## G. Ratification + first slice

**RATIFIED by Dustin 2026-09-23** ("this all sounds good for all of the D decisions") → **tt-0 (Phase 1, ontology)** starts on `dev-tt-0`:
modules `tensormath` (Tensor, TensorDimension, TensorMathExpression, TensorOperator, ComputeImplementation,
TensorDecomposition), `tensortree` (TensorTreeDefinition, TensorNode, UnresolvedTensorSpace, LocalizedDimension,
TensorMapping, TensorSelection, TensorDiscoveryPolicy) and `computelod` (ComputeLOD, ComputeKind,
ComputeMapping, CharacterizationMapping, CompilerArtifact), the eleven rungs + kinds seeded, the `compute-lod`
tech tree seeded with the rung concepts, validators (one root, one parent, acyclic, local validity, typed
unresolvedness), the discovery function with its policy row, configured pages, selftests with class counts.
Estimated as one slice; nothing installed (no core, no toolchain) until lod-1.

### G.1 tt-0 BUILT 2026-09-23 (branch `dev-tt-0` in suite / rf-node / framework; unmerged — his confirmation)

Three modules in the standard shape, 18 row classes, 77 selftest checks + core guards + a real-boot probe
(`tests/tensor_liveboot_probe.py`, 33/33: classes typed, eleven rungs + 70 kinds + the compute-lod tree + the
default policy seeded, routes answer, CRUDE creates an uninterpreted tensor, three pages seeded). Proven in code:
σ_ij = C_ijkl ε_kl by named contraction against the closed form; local validity (a resolved node below an
unresolved space); discovery refuses before it scores, and a policy row change flips the ranking. Found and
fixed on the way: dep-0/1's DeployTarget/DeployRecord were never in defClassList (could not type/persist).
NEXT tt-1: a real Tensor over the waxprint thermal state (storage_kind=engine), a 3-node tree, bindings rendered
in the 3D sim space, a TensorSelection from a panel action, discovery live. Merge tt-0 to dev on his word.

### G.2 tt-1 BUILT 2026-09-23 (same branch `dev-tt-0`)

`storage_kind=engine` reads live simulation state (a grid field on one row, or a sim-state series); `wind-field` =
the wind→pendulum coupling's 4×4×4 grid as a rank-4 tensor and `waxprint-series` as the rank-2 time series (D3's
waxprint thermal field is per-step scalars, not spatial — stated, not papered over); the seeded tree `wind-spatial`
with a RESOLVED root bound to the proven `WindFieldGridState-3d` binding, a resolved slice, a typed unresolved
space, and three mappings incl. the REAL coupling by reference and a proposed calm-only decomposition;
`POST /api/tensortree/select` creates the selection row and returns its discovery; the page hosts the existing
sim-space viewer. Live boot 42/42: the coupling ranks first, the calm-only hypothesis is refused on the gusty
selection. NEXT: lod-1 (the teaching path C → GCC → RISC-V add → PicoRV32 → Yosys netlist) per the order
1→2→4→…; then tt-2 (continuum mechanics on the FEM resolution).
