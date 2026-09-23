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
