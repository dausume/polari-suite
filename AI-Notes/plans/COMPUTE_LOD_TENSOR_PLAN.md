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

### G.3 lod-1 BUILT 2026-09-23 (same branch `dev-tt-0`)

The teaching path RUN: `custom/lod1_chain.py` (tools on the PATH or the pinned image `modules/computelod/tools/
Dockerfile` — noble's gcc-riscv64-unknown-elf 13.2, yosys 0.33, verilator 5.020, iverilog; nothing installed on
a host), PicoRV32 vendored at one pinned commit (ISC). Result rows from the committed report: C `c = a + b` →
`add a0,a0,a1` = 0x00b50533 (decoded, not copied) → PicoRV32 decode (:1068) + `alu_add_sub` (:1231) → `rv32_add.v`
→ yosys 220 gates (the core: 8126) → iverilog: RTL and gate netlist agree on 4 vectors. Netlist → standard cells
and the delay are left UNRESOLVED on purpose (lod-2 needs a Liberty). `GET /api/computelod/path?rung=&ref=` walks
it; the page shows each step with its evidence. Ordering note: the compiler rung's row is what the compiler
PRODUCED (the assembly), so the chain links ref-to-ref. NEXT (order 1→2→4→3): tt-2 continuum mechanics on the
FEM resolution; then lod-2 (Liberty: cntfet/sifet cells or SKY130; OpenSTA delay with conditions).

### G.4 tt-2 BUILT 2026-09-23 (same branch `dev-tt-0`)

Validation B on the msci FEM resolution: `fem:<case>:<field>` engine storage solves an `FEMModelDefinition`
(seeded `tt2-plate-tension`: electrical-steel plate, E/ν from the CITED magnetics material option, plane stress)
and exposes u, ε, σ, C, centroids as tensors; σ_ij = C_ijkl ε_kl by named contraction equals the engine's σ to
1e-9 — TensorMath and the FEM engine agree. The operator `stress-from-strain` has one numpy implementation whose
latency is a per-call reading (no invented benchmark; lad-5 stores those). The `plate-mechanics` tree carries
u→ε→σ→balance as mappings; its root is UNRESOLVED for the stated reason (an element field has no sim-space
binding yet — a typed visualization space names the candidates). Live boot 52/52.
NEXT (order …→6→7→5): tt-3 = the σ field's binding (a 2-D field binding over an FEM execution row, or a
sci-xy-chart profile fed from evaluate — the first slice that touches the Angular side) and the tensor-hardware
comparison (numpy vs the hwfpga kernel, lad-5 benchmark rows); lod-2 = Liberty + OpenSTA with conditions.

### G.5 tt-3 / Phase 6 BUILT 2026-09-23 (same branch `dev-tt-0`)

σ = C:ε on an open FPGA beside numpy: `tensormath/custom/fpga_kernel.py` (the pinned image gained nextpnr-ice40 +
icestorm). The streaming form (16 multipliers) did not fit an HX8K — 49k LUT4 vs 7,680 — recorded as the lesson;
the time-multiplexed kernel (one multiplier, 17 cycles/element, exact on all 64 real elements) behind a
register-bus top fits: 4,185/7,680 LCs, Fmax 32.3 MHz → 0.53 µs/element (DERIVED, labelled). `POST
/api/tensormath/benchmark` measures the numpy row here (1.64 µs/element on pol-core, median of 30). One operator,
two implementations, each with its own evidence level — the bridge of §F8, live. PyTorch deferred (D5). Selftest
49/49; live boot 55/55. The branch `dev-tt-0` holds tt-0 · tt-1 · lod-1 · tt-2 · tt-3.
NEXT (order …→7→5): Phase 7 multiscale integration (FEM/MD/DFT resolutions + PSPP ScaleTransferDefinition as
`kind=scale` mappings executed as SimulationCouplingDefinitions), then Phase 5 open silicon (lod-2: Liberty +
OpenSTA with conditions; the netlist → standard-cells mapping left unresolved by lod-1).

### G.6 tt-4 / Phase 7 (first slice) BUILT 2026-09-23 (same branch `dev-tt-0`)

The scale tree of a material as a READING (`GET /api/tensortree/scale/{material}`): nodes = its msci
`MaterialScaleDefinition` levels (fidelity ladder attached), gaps = structural unresolved spaces, mappings = its
pspp `ScaleTransferDefinition` rows as `kind=scale` by reference; `POST …/materialise` persists it as tree rows.
Live on paraffin wax (L0→L1 thermal, L0→L4 quantum, both executed). Left for Phase 7's next slice: executing
a `kind=coupling` mapping as a `SimulationCouplingDefinition` (creation from a mapping; today the wind coupling
is referenced, not created), the statistical/discrete boundary as mappings, and the σ-field visualization
(the Angular side). Selftest 51/51; live boot 59/59. The branch `dev-tt-0` holds tt-0 · tt-1 · lod-1 · tt-2 ·
tt-3 · tt-4.

### G.7 lod-2 / Phase 5 (first rung down) BUILT 2026-09-23 (same branch `dev-tt-0`)

The adder mapped onto SKY130 HD (a cited, pinned, never-committed Liberty; tt / 25 °C / 1.8 V): 96 cells (xnor2
+ maj3 ripple), 855.8 µm²; OpenSTA worst path 11.94 ns with load and slew named. lod-1's gaps close by name;
the next (cells → devices via sky130_fd_pr SPICE, then layout with Magic/KLayout and DRC/LVS) is stated as
partial. The walk from `c = a + b` now spans eight rungs. Selftest 54/54; live boot 60/60.
`dev-tt-0` holds tt-0 · tt-1 · lod-1 · tt-2 · tt-3 · tt-4 · lod-2 — every ratified phase has its first slice.
OWED across the arc: the σ-field visualization (Angular: a 2-D field binding or a sci-xy profile panel), a
SimulationCouplingDefinition created FROM a kind=coupling mapping, the CNT cell library via a real
characterization run (needs ngspice + a derived device), lod-3 (cells → transistors → layout), PyTorch (D5,
deferred), and the merge of `dev-tt-0` into dev on his word.

### G.8 tt-5 — TensorTree intuition in the browser BUILT 2026-09-23 (same branch `dev-tt-0`)

His ruling: "we definitely want frontend visualizations that give intuition about tensorTrees." The Angular
side is ONE registered panel, `tensor-tree-panel` (`components/dashboard/generic/tensor-tree-panel.component.ts`,
registered in `generic-display-components.ts`), fed by ONE read the API gained for it —
`GET /api/tensortree/trees/{name}/view` (tree meta · nodes with status/why/dims→channel+range+scale or the
unresolved kind/known dims/open questions/candidates/hypotheses · structural edges · mappings with both statuses,
evidence level, evidence_ref, loss note, validity · selections · validation · the eleven channels · the four
evidence levels) — and ONE write that already existed (`POST /api/tensortree/select`). What it draws, each a rule
of §11–§16 made visible:

- the rooted STRUCTURE as a d3 tree (d3 is the existing node-graph home — techtree / msim views — no new chart
  engine): resolved nodes solid blue, nodes that fail validation amber, unresolved spaces dashed with their kind
  (semantic|structural|visualization|mapping|validation) — a tree may be incomplete and still be useful, so the
  gaps are drawn, not hidden; a forest under construction hangs off a hidden root instead of failing;
- MAPPINGS as arcs that may cross branches, coloured by evidence level (grey none · amber analytical · blue
  simulated · green measured), dashed while only `proposed`; a mapping whose target lives in another tree is drawn
  to a stub labelled with the target and "(another tree)";
- a node's DIMENSIONS → CHANNELS as chips (x → position.x [range], T → color with its scale) — resolved means
  every dimension has a channel, and an incoherent dimension is shown red with the validator's reason;
- the cycle VISUALIZE → SELECT → DISCOVER → MAP: per-dimension lo/hi inputs prefilled from the node's ranges (or
  the last selection on it) → `POST select` writes a TensorSelection row and returns the discovery → ranked
  candidates with score bars, their evidence and loss note, the refused list with reasons (never scored) → click a
  candidate to follow the mapping to its target node (highlighted arc);
- a tree picker (chips from `GET /api/tensortree`, resolved/total per tree) and a legend.

Page `tensortree` row 1 mounts it on `wind-spatial` (the sim-space viewer of the resolved root stays as row 2).
Angular `tsc --noEmit -p tsconfig.app.json` clean; tensortree selftest 51/51; live boot 67/67 (six `/view`
checks + the page mount). Not yet SEEN in a browser: that needs the staging images rebuilt (`pol swarm deploy`
on the home stack) — his browser pass, like the earlier arcs. The σ-field visualization (owed 1) is unchanged:
plate-mechanics still draws its root as unresolved for the stated reason, which is the point of the panel.

### G.9 tt-6 — the σ field SEEN: the plate root resolves BUILT 2026-09-23 (same branch `dev-tt-0`)

Owed item 1 closed, by the route that keeps every rule: no new renderer, no raw JSON, the same viewer the
wind tree uses, and dims → channel coherent with the binding by construction.

- **The field as a row.** `tensormath` gained `FEMFieldState` (seventh class): `elements_json` = one matrix row
  per element `[cx, cy, σ_vm, σ_xx, σ_yy, σ_xy, area]`, `nodes_json` = `[x, y, u_x, u_y]` per node, plus the
  field's own σ range, u_max, the assumption and the cited material line E/ν came from. Built by
  `custom/fem_field.py` from the engine's tensorField; the SEED row is solved at seed time with no manager (seed
  case + seed material option; 64 elements, σ_vm 0.888–1.081 MPa under the 1 MPa pull, E = 200 GPa / ν = 0.29
  literature-est) — if the engine cannot solve, the seed is empty and says why; `POST /api/tensormath/fem/{case}/
  materialise` re-solves with the live rows (`GET …/fem/{case}` says whether it is drawable and why not).
- **A 2-D `field` binding kind.** `simSpace/compilers/field_projection_2d.py` + one branch in `compile_2d`:
  a matrix-valued row fans into one object per cell at its centroid with `colorOverride` = the binding's ramp at
  the scalar column over the binding's domain (the raw value, unit and domain ride `userData` for the tooltip;
  a non-numeric cell is grey and says `refused`). The 3-D twin (wind arrows) is unchanged. The object model had
  carried `colorOverride` since mag-fv; the d3 renderer now honours it (`paintOne`) as three-renderer always did.
- **Scene + binding** seeded by tensormath: `plate-mechanics-2d` binds `FEMFieldState`; `FEMFieldState-2d` is
  `kind=field, matrixField=elements_json, scalarCol=2, color={domain: PLATE_SIGMA_DOMAIN=[0.8e6, 1.1e6] Pa,
  ramp: stress}`. The tensortree dimension `plate.sigma` imports the SAME constant — one number, two readers.
- **The tree, honestly.** Root `plate` = x/y → position, σ → color, `binding_ref FEMFieldState-2d` → RESOLVED on
  a real boot. `u` moved to `plate-displacement` (x/y/u → vector) which stays UNRESOLVED for the stated reason
  (2-D has no vector channel) with a typed visualization space under it carrying the two candidate bindings and
  the open exaggeration question. The validator got stricter: when an instance holds any
  SimSpaceBindingDefinition rows, a `binding_ref` must name one of them (a resolved node is one a viewer can
  draw) — the selftest proves both directions.
- **Pages.** `tensormath` rows 4–5 (field-state table; the plate scene), `tensortree` row 3 (the plate scene
  beside the wind scene).
- **Proof.** tensormath 55/55, tensortree 54/54, pendulum3d 9/9, wind coupling 30/30, live boot **71/71**
  (root resolved; field from seed; materialise refreshes not duplicates; the snapshot of `plate-mechanics-2d`
  = 64 cells with >3 distinct colours); Angular tsc clean. Unseen in a browser until the images rebuild.
- **Next slices stated, not built:** the triangles themselves (polygon cells sized in space units, not
  markers), a 2-D `vector` kind for u, `wind-spatial`'s `wind-turbulence` space likewise.

### G.10 tt-7 — a SimulationCouplingDefinition created FROM a `kind=coupling` mapping BUILT 2026-09-23 (same branch)

Owed item 2 closed (§F6: "kind=scale|coupling ALSO written as SimulationCouplingDefinition"). The tree is where
a person declares that one node's values feed another node's step; the coupling row is what the runner
executes; `tensortree/custom/tensortree_couple.py` derives the second from the first and refuses by name
whatever it cannot derive:

- source/target `class_name` + `simulation_ref` ← each node's Tensor (engine storage `matrixfield:<Class>:…` /
  `simstate:<Class>:…`) → the class → its `simulation_definition_name` (a class that declares none is named in
  `missing`; nothing is guessed);
- `sampler_equation_ref` ← the body, else the mapping's `expression_ref` → TensorMathExpression.
  `matrix_equation_ref` (the rank ≤ 2 delegation of §9 doing real work: `wind-sample-at-bob` delegates to the
  saved no-code `field-sample-nearest`); once the instance holds MatrixEquationDefinitions the name must be one;
- `config_json` ← operands = the source field as `source_field_json` + the target's position fields from its
  dims on `position.x/y/z` (`[px, py, pz]`); inject = the mapping's `target_dims` in order as `sample_element`
  0..n; defaults 0.0 (soft-degrade: inert until a run pairs to it).
- Doors: `GET /api/tensortree/mappings/{name}/couple` = the dry run (row, `derived_from`, `missing`, notes);
  `POST` creates (201), sets `mapping.coupling_ref`, moves `proposed → implemented`, and leaves
  `evidence_level` untouched — nothing has RUN through it; a mapping only earns `simulated` when a
  SimulationRun names the coupling in `coupled_run_refs_json` and steps. Refusals: kind ≠ coupling 422; already
  coupled 409 naming the coupling (`force` to add another beside it); duplicate name 409.
- Seeds that make it real: tensor `bob-state` (`simstate:NewtonianPendulumBobSimState:*:px,…,fwind_z`), tree
  `bob-motion` with root `pendulum-bob` (px/py/pz → position, fwind → vector, the seeded wind-arrow binding →
  RESOLVED), so the cross-tree mapping `wind-grid→bob-drag` now lands on a real node; the proposed mapping
  `wind-grid→bob-wind` (expression `wind-sample-at-bob`, target dims wind_vx/vy/vz, no coupling row).
- Page `tensortree` row 8: the SimulationCouplingDefinition rows (seeded or created).
- Proof: tensortree 63/63 (refused twice by name, created once, 409 on repeat), tensormath 55/55, live boot
  **76/76** (derived from the REAL classes on a real boot; the created row is a real SimulationCouplingDefinition
  beside `wind-to-newtonian-pendulum`, same sims and sampler, its own inject keys).

### G.11 lod-2b — the SECOND Liberty: our own CNT cell library BUILT 2026-09-23/24 (same branch)

Owed item 3 closed — and the premise corrected: ngspice-46 and OpenVAF 23.5 ARE on pol-core, under `~/tools`
where the cntfet engine ladder looks (only PATH lacked them); nothing was installed. `computelod/custom/
lod2_cnt.py run` boots the server in-process, derives `cnt-aligned-s1` and its p partner `cnt-aligned-s1-p`
(a real hole device, not the mirror card), characterizes twelve combinational cells (INV/BUF/NAND2/NOR2/NAND3/
NOR3/XOR2/XNOR2/AOI21/OAI21/HA/FA, drive 1, the S5 sweep: ngspice transients through the OpenVAF-compiled VS
model, 3 slews × 3 loads) → `polari_cnt_lib.lib` (110 kB, OURS, committed under `initialData/lod2/cnt/` with
its sha256, the device, `derived_at` and the `CellCharacterizationRun` row as provenance; no failures; OpenSTA
gate LIBERTY-ACCEPTED), then maps the SAME adder netlist onto it (yosys abc: 152 cells — XOR2×47, NAND2×31,
XNOR2×16, AOI21/INV/OAI21×15, NOR2×13) and times it with OpenSTA at the library's own point: 0.6 V, 300 K, load
41.7 aF (4× an INV input, the sweep's largest grid load), slew 1.02 ps (the grid's middle) — worst path
`reg_op2[1] → alu_out[31]` **41.33 ps**, fastest 1.56 ps. Beside SKY130's 11.94 ns this is an INTRINSIC-grade
number over a DERIVED device with standin parasitics and no layout — the report, the rows and the API say so;
it is not a claim that CNT logic is 300× faster than a fabricated PDK's timing model.

Rows are NEW names beside the SKY130 ones (nothing replaced): `lod2-cnt: netlist → CNT standard cells`
(validated, simulated — a model of a model), `lod2-cnt: CNT standard cells → devices` (one-to-many, implemented,
simulated: for THIS library the step is a real reference to the AlignedCNTFETDevice rows — the cells' SPICE is
the derived VS card), and two delay characterizations in ns with the 0.6 V / 300 K conditions. What the library
does NOT carry is listed (`not_carried`): cell area (→ `area_um2: None`, not 0), leakage beyond the ioff
standin, setup/hold. `GET /api/computelod/lod2/cnt`. Seed merges by name → 10 mappings + 9
characterizations; the two propagation-delay rows carry different conditions and do not collide.

Proof: computelod 60/60, live boot **79/79**. Gotcha recorded: a `pgrep -f <pattern>` waiter matches its own
command line — the background waiter spun for 12 h after the run had finished (23:35).

### G.12 lod-3 (first slice) — cells → transistors → layout, READ from the artefacts BUILT 2026-09-24 (same branch)

The last owed rung-step, taken the honest way: not simulated, READ. `computelod/custom/lod3_cells.py run`:

- **SKY130.** For each of the seven cell types the mapped adder uses, the PDK's own `.spice` and `.lef` are
  fetched from `google/skywater-pdk-libs-sky130_fd_sc_hd` at a PINNED commit (ac7fb61f…) into the cache and
  cited per file by url + sha256 (never committed, as with the Liberty). The netlists are parsed down to every
  transistor (model, W, L — the PDK's 1e-6 scale applied: `w=1e+06u` = 1.0 µm): xnor2_1 = 10 (5 pfet_01v8_hvt +
  5 nfet_01v8), maj3_1 = 14, nand2/nor2 = 4, o21ai_0 = 6, isobufsrc = 6, xor2 = 10; every device L = 0.15 µm.
  **The adder = 1050 transistors** (525 p-hvt + 525 n). The LEF `SIZE` of every mapped cell, summed over the
  96 instances, is **855.82 µm² — identical to lod-2's Liberty area** (`yosys stat -liberty`): two independent
  PDK sources agree, which is what turns `devices → layout` into `validated`. Evidence level `analytical`
  throughout (cited files, no tool run).
- **CNT.** Each cell → its device list in cntfet's `CELL_LIBRARY` (composites expanded), the SAME topology the
  ngspice characterization netlisted: **1016 transistors** (508 p + 508 n) over `cnt-aligned-s1` + its derived
  partner; evidence `simulated` (the device is a model). **No layout exists** → `lod3-cnt: devices → layout` is
  `kind=unresolved`, stated.
- **Rows** (seed merges by name): `lod2: standard cells → devices` RESOLVED (partial → one-to-many, analytical);
  `lod3: devices → layout` (validated, the area cross-check in its notes); `lod3: layout → fabrication`
  PARTIAL (the process rows behind sky130_fd_pr — lod-4); the CNT cells → devices row now carries its
  transistor count; three characterizations (1050 / 1016 transistors, 855.82 µm² LEF area). `not_done` lists
  DRC/LVS (Magic + netgen), transistor-level simulation with sky130_fd_pr corners, fabrication, CNT layout.
- `GET /api/computelod/lod3` (summary without the per-device lists). **The walk from `c = a + b` now spans
  TEN of the eleven rungs** — C → compiler → ISA → microarchitecture → RTL → netlist → cells → devices → layout →
  fabrication (partial) — with the eleventh, materials, reachable only through the microchip ladder's process
  rows, which is lod-4's job.
- Proof: computelod 70/70, live boot **80/80**.

### G.13 lod-4 (first slice) — fabrication → materials: the ELEVENTH rung entered BUILT 2026-09-24 (same branch)

`computelod/custom/lod4_process.py` — a reading, nothing fetched:

- **layout → fabrication** RESOLVED by name onto a `SiliconProcessNode` row `sky130`, written in sifet's own
  ladder shape and vocabularies (130 nm planar bulk, 1.8 V core, `l_min_um 0.15` READ from the lod-3 netlists,
  5 metals from the PDK docs — each key number carries its source; Apache-2.0 verified on the files read →
  `rights_class incorporable-open`; `fabrication_evidence measured-fabricated-device` — a foundry process). It
  is seeded by computelod (skipped when sifet is absent) and NOT added to sifet's ratified prior nodes; on a
  live boot sifet's own `ladder_report` simply shows it as the coarsest rung, the prior nodes unchanged.
  **`manufacturable` is left None** (evidence-only) with the evidence named — SkyWater fabricates SKY130 and
  Google-sponsored open MPW shuttles (Efabless, 2020–2023) accepted designs under this PDK — because the sifet
  ladder's rule says "today: no rung qualifies" and flipping that is a person's ruling:
  **D-lod4-1 (his): does SKY130 qualify as MANUFACTURABLE under the ladder rule (current shuttle availability
  and terms to be verified)?**
- **fabrication → materials** (one-to-many, implemented, analytical): the substrate is sifet's `SiliconGrade
  eg-si` (9N–11N) reached by `RefinementRoute siemens-route` (mg-si → TCS → Czochralski; cited there [CEC12]).
  The metal stack (Al / W plugs), gate oxide/poly and the dopants are NAMED as not modelled — the rung is
  entered, not exhausted.
- The CNT branch stays blocked at LAYOUT (lod-3), not at process: its process rows (cntfet `cnt_process_basis`:
  alignment, placement, purification, contact, lithography, gate stack) are named so the gap is precise.
- `GET /api/computelod/lod4` (report + the live process-node row). **The walk from `c = a + b` now spans all
  eleven rungs** and ends at materials — the ladder's bottom, not a gap.
- Proof: computelod 75/75, sifet ladder 31/31 (unchanged), live boot **82/82**.

With G.13 every rung of the ratified ladder has at least one real reading on the SKY130 branch (C → compiler
→ ISA → microarchitecture → RTL → netlist → cells → transistors → layout → process → silicon), and the CNT
branch reaches transistors over a device this instance derived and characterized itself. What deepens each rung
from here is stated in the rows' notes (DRC/LVS, corner simulation, process steps as rows, the metal stack,
PyTorch by D5 when a workload asks for it).

### G.14 tt-8 — u per node SEEN; the plate tree fully resolved BUILT 2026-09-24 (same branch)

The displacement's honest gap from tt-6 closed without a renderer change: a 2-D `vectorfield` binding kind
(`simSpace/compilers/field_projection_2d.emit_vectorfield_2d`, one branch in `compile_2d`) fans
`FEMFieldState.nodes_json` into CONNECTIONS — node → node + k·u — on the channel the 2-D renderer already draws.
The exaggeration k is an explicit knob of the binding (`vectorScale`), carried on every line's userData with
the raw u and its unit, so the legend can say "u × 20 000" and the former unresolved space's question ("what
exaggeration is honest to draw beside a colour field whose scale is true?") has its answer: the one that is
written down. Binding `FEMFieldState-u-2d` (k = `PLATE_U_EXAGGERATION` = 20 000: |u| ≤ 1e-5 m on a 2 m plate →
~0.2 m lines) in the same scene `plate-mechanics-2d`; node `plate-displacement` binds to it → RESOLVED. On a
real boot the snapshot carries 45 lines: zero-length on the fixed left edge, longest on the pulled right edge —
the physics reads correctly. The tree's one remaining unresolved space is now the GEOMETRY (`plate-geometry`:
the triangles themselves, not markers at centroids; the open question is whether the 2-D shape library takes a
per-instance polygon or a mesh channel is needed) — a tree keeps only real gaps.
Proof: tensormath 56/56, tensortree 63/63, pendulum3d 9/9, live boot **83/83**.

### G.15 tt-9 — the mesh SEEN as a wireframe; the open question answered BUILT 2026-09-24 (same branch)

The `plate-geometry` space asked whether the 2-D shape library takes a per-instance polygon. Answer, from the
code: no — `paintShape2D` resolves a `shapeRef` from the library; vertices per object would be a renderer
change. So the triangles are seen the way the renderer already can: a `meshwire` 2-D binding kind
(`emit_meshwire_2d`) fans a mesh row (`nodes_json` + the new `FEMFieldState.triangles_json`) into its EDGES,
each once, on the connections channel (an optional `displacementCols` + the same stated `vectorScale` draws the
deformed mesh instead). Binding `FEMFieldState-mesh-2d` in scene `plate-mechanics-2d`; node `plate-mesh`
(x/y → position, edge → shape) RESOLVED. On a real boot the snapshot carries 108 distinct edges for 64 triangles
on 45 nodes — exactly Euler's V + F − 1 for a simply connected disc, an independent consistency check on the
row. The tree's one remaining space is `plate-filled-cells` (σ as filled triangles rather than a colour marker
inside a wireframe): a renderer change and a person's call whether it is worth it — stated, not pretended.
Proof: tensormath 58/58, tensortree 64/64, live boot **84/84**.

### G.16 tt-10 — the created coupling EXECUTED: a mapping earns `simulated` evidence BUILT 2026-09-24 (same branch)

tt-7 created the coupling row from the tree and left the mapping's evidence at `none` — "nothing has run through
it". `POST /api/tensortree/mappings/{name}/prove` now runs it: for the ONE coupling the mapping names, on a
target SimulationRun that pairs to a source run (default: the seeded `newtonian-pendulum-wind-run` →
`wind-field-run`), the runner's OWN pre-pass functions are called in the runner's order — baseline = the bob's
latest row (its position feeds the sampler's `target_fields`), lazy-pull the source run to cover t, take the
latest source row ≤ t, evaluate the sampler, inject — and the result is recorded: source row (class, step, time),
target row (position), sample, injected keys, what changed from the defaults. The mapping's `evidence_level`
becomes `simulated` with an `evidence_ref` naming run, source run, row and values; `mapping_status` is NOT
raised (consumption by a solution is not attributed — the keys are shared with the seeded coupling), said so.
Honesty caught by the first run: at t = 0 the seeded gust field is calm by construction (a sinusoid), so the
proof sampled a true zero; the door now defaults past t = 0 by one source step and says why. At t = 0.5 s on a
real boot: wind run advanced to step 5, cell nearest the bob at (0.5, −0.87, 0) sampled, wind (5.08, −0.93,
7.30) m/s injected as wind_vx/vy/vz. A mapping with no coupling row is a 422 that says to couple first.
Proof: tensortree 64/64, live boot **87/87**.

### G.17 lod-3b — devices → cells SIMULATED BY US, cross-checked against the Liberty BUILT 2026-09-24 (same branch)

The transistor netlists lod-3 read are now RUN: `computelod/custom/lod3_devices.py run` — ngspice-46 on the PDK's
own BSIM4 models (`sky130_fd_pr` tt: per device flavour the `mismatch.corner` + `tt.corner` + `tt.pm3` files,
six files at a pinned commit f62031a1…, cached and cited by sha256, never committed — the whole model tree was
NOT needed) — for `inv_1` A→Y and `nand2_1` A→Y, B→Y, at the Liberty's own point (tt, 25 °C, 1.8 V, 14.6 fF, 50 ps
20–80 % slew, 50 %/50 % delay thresholds) and compared to the Liberty's tables bilinearly interpolated at the
same point:

    inv_1   A   tpHL  65.2 vs  77.2 ps (−15.6 %)   tpLH 130.0 vs 117.9 ps (+10.2 %)
    nand2_1 A   tpHL  91.7 vs 106.4 ps (−13.8 %)   tpLH 132.5 vs 129.4 ps (+2.4 %)
    nand2_1 B   tpHL  93.8 vs 106.4 ps (−11.8 %)   tpLH 139.4 vs 129.4 ps (+7.7 %)

Mean |Δ| 10.8 %, max 20.8 %. The gap has a stated cause and a consistent sign: the `cells/*.spice` netlists are
SCHEMATIC (devices with W/L, no wiring parasitics) while the foundry characterized the extracted layout — so our
falls are faster on every arc. Reported, not tuned. Rows: six UPWARD `CharacterizationMapping`s devices →
standard-cells, evidence `simulated`, the Liberty value and delta inside `conditions_json`, `validated` when
within 25 %. `GET /api/computelod/lod3/devices`. First slew-matching lesson recorded: a 50 ps 0–100 % ramp is a 30 ps
20–80 % slew, which made the first run 25 % fast until the convention was matched.
Proof: computelod 81/81, live boot **88/88**. Still not done: DRC/LVS (Magic/netgen), extracted-parasitic
netlists (`.pex`), the other arcs/cells.

### G.18 lod-3c — the layout RUN: DRC · PEX · LVS through `polari-eda-tools`, its own submodule BUILT 2026-09-24

His ruling: go ahead on DRC/LVS/extraction "so long as licenses are compatible", and the tooling "in their own
sub-module". Both done.

- **`polari-rf-node/polari-eda-tools`** (new repo `dausume/polari-eda-tools`, branch dev, submodule of
  polari-rf-node): ONE image `polari-eda-tools:noble` (gcc-riscv64, yosys, verilator, iverilog, nextpnr/icestorm,
  **magic 8.3.684 built from source at a pinned tag** — noble's package 8.3.105 is older than the sky130A tech
  file requires and segfaults — netgen-lvs, ciel), `fetch-pdk.sh` (ciel enables sky130A with ONLY sc_hd + fd_pr at a
  pinned open_pdks version 1689ac3f…, ~0.9 GB into `$POLARI_PDK_ROOT`, gitignored, never in the image), `flows/`
  (`cell_check.tcl`: DRC + two extractions, LVS-flavoured and PEX; `lvs.sh`), and **`LICENSES.md`** — the audit
  per component with where each licence was verified: magic = UC Berkeley permissive (+ Juniper permissive
  parts); netgen = GNU GPL "any version" (Debian copyright, Files: *) → GPLv3-compatible, and only ever a separate
  process; ciel/open_pdks/SkyWater = Apache-2.0; everything else ISC/GPL tools. The framework's in-tree
  `computelod/custom/tools/Dockerfile` is retired (README pointer); the lod scripts read `POLARI_EDA_IMAGE`
  (default `polari-eda-tools:noble`) and `POLARI_PDK_ROOT`; `fpga_kernel.py` likewise.
- **lod-3c** `computelod/custom/lod3_layout.py run`, on the PDK's own `.mag` of `inv_1` and `nand2_1`:
  - **DRC** (sky130A full rules): inv_1 3, nand2_1 4 — every one a standalone-cell CONTEXT rule (nwell.4, LU.2,
    LU.3: taps and shared wells come from the row's tap cells). Classified as such, count kept, `real_rules = []`;
    any other rule would be a real error and would stand.
  - **PEX**: 14 (inv_1) and 23 (nand2_1) parasitic capacitors plus the source/drain junction areas the
    schematic netlists never had.
  - **LVS** (netgen vs the PDK's schematic netlist): "Circuits match uniquely", both cells.
  - `lod3: devices → layout` → `measured` (DRC + LVS are the tools' own verdicts), validated; six
    `lod3c: … (extracted)` characterizations beside lod-3b's schematic ones.
- **The parasitics hypothesis, TESTED and half-REJECTED.** Re-timing on the extracted netlists moves every delay up
  ~4–6 ps: tpHL mean −13.7 % → −9.7 % (closer to the Liberty), tpLH mean +6.8 % → +11.9 % (further). So parasitics
  explain part of the fall gap and none of the rise gap; what remains is the vendor characterization setup
  (input waveform shape, load/driver model, measurement details), which we do not have — stated in the report's
  `verdict`, not tuned. Overall mean |Δ| 10.2 → 10.8 %.
- Proof: computelod 87/87, tensormath 58/58, live boot **90/90**. Lessons: netgen guesses the format from the
  suffix (`.ext.spice` is read as magic `.ext` — name it `_lvs.spice`); LVS on the devices-only extraction, PEX
  on a second one.

### G.19 tt-11 — filled cells THROUGH THE SHAPE LIBRARY BUILT 2026-09-24 (same branch)

His ruling on "filled cells": use math shapes — "we have our own library for that, it should be able to carry
it". So no polygon bolted onto the renderer; the geometry is carried by `mathshapes` and the renderer learns one
general thing:

- **`mathshapes`**: a new primitive kind `polygon` (vertices in the xy plane, optional z/thickness): shoelace area
  and area-weighted centroid, perimeter, even-odd point-in-polygon with on-edge inclusion; `primitive_properties`
  returns the FACE area as the area (the quantity a 2-D field is defined on) and volume = area × thickness (0 for
  a pure 2-D shape — stated, not invented). `custom/shape2d_bridge.py`: a polygon MathShapeDefinition → a
  `Shape2DDefinition` (`source='svg'`, ONE `<polygon>` with points relative to the centroid, anchor center, and
  the new field **`units='space'`**); fill/stroke are NOT in the svg — they are the object's style/colorOverride
  (data), so one shape row serves any field painted on it.
- **`Shape2DDefinition.units`** (`px` = a marker at pixel size, every shape before now | `space` = drawn in the
  space's own units and scaled with the view, so it tiles the space). The d3 renderer honours it: a space-unit
  svg is drawn through `pixelsPerUnit()` with the y flip of a math coordinate system, and the style is applied
  to any element that carries no fill of its own. Nothing else in the renderer changed.
- **`tensormath/custom/fem_shapes.py`**: every P1 triangle of a field row → a polygon MathShapeDefinition (vertices
  from `nodes_json` + `triangles_json`, the field row's own area in the notes) + its 2-D shape, named
  `<field>-el-<i>`; seeded from the SAME solve as the field row (lazy, 64 + 64 for the seed case; selftest proves
  element 0's area == the field row's area column and centroid == the FEM centroid);
  `POST /api/tensormath/fem/{case}/shapes` writes/refreshes them for a live row. tensormath now REQUIRES
  mathshapes (manifest, FEATURE_REQUIRES, registry — the drift guard 23/23).
- **The `field` binding** gained `shapeRefPattern` (`<field>-el-{i}`): each cell references ITS OWN shape and
  carries no marker scale; without a pattern the rectangle marker + `cellSize` behave exactly as before.
  `FEMFieldState-2d` uses it: the plate is tiled with its own triangles, each painted by σ_vm.
- **The tree**: root `plate` gains `element → shape` (the eleventh channel's `shape` finally used);
  `plate-filled-cells` is answered and gone — the plate tree has NO unresolved space left, which is allowed:
  nothing is kept unresolved for show.
- Lesson: `LazySeedRows` filled on iteration/len but not on indexing — fixed at the source (`__getitem__`).
- Proof: mathshapes 24/24, tensormath 61/61, tensortree 64/64, lazy-import drift 23/23, Angular tsc clean, live
  boot **94/94** (64 + 64 rows exist from seed; the math-shape API answers an element's area 1/32 m² and centroid;
  the snapshot's 64 cells each reference their own space-unit shape; the shapes door refreshes without duplicating).
  Unseen in a browser until the images rebuild — his pass.

## H. What comes next (written 2026-09-24 for a fresh session; nothing below is built)

Everything in §G is on `dev-tt-0` (suite, polari-rf-node, polari-framework, polari-platform-angular, plus the
new `polari-eda-tools` submodule of polari-rf-node), UNMERGED. Two things remain that only a person with a
browser and the home machines can do, and one open ruling; after those, the lod work has natural next rungs.

### H.1 The browser pass — the frontend of this arc has NEVER been seen

Every Angular piece type-checks and every backend row/route is proven on a real boot (94/94), but no image has
been rebuilt since tt-5, and pol-core has no stack up (purge #3). The pass is: rebuild → open three pages → judge
each panel against what it must show → file what is wrong as `plate-…`/`tree-…` unresolved spaces or plain bugs.

**Rebuild.** The dev route is the home swarm (memory `dev-swarm-prod-app-route`): `pol swarm init` on pol-core
(it left the swarm), then `pol swarm deploy node` from the `dev-tt-0` working trees. POLARI_MODULES is DERIVED
from ModuleAssignment rows — the three new modules + `mathshapes` must be admitted on the core first (`pol
modules …` / a ModuleAssignment for `tensormath`, `tensortree`, `computelod`, `mathshapes`, and their requires:
`simulations, simSpace, materialsScience, pspp, magnetics, techtree, microchip, cntfet, sifet, hwfpga`), or the
pages 503 honestly. Remember the two-compose gotcha in memory `math-shapes` (deploy from the suite root). Cold
seed takes minutes: the wind/pendulum states and now the FEM solve run at boot.

**Page `/display/tensortree`** (rows in `tensortree_page.py`):
- row 1 `tensor-tree-panel` opened on `wind-spatial`: three chips (wind-spatial, bob-motion, plate-mechanics) with
  resolved/total counts; a top-down tree — `wind-grid` solid blue, `wind-slice-z0` solid, `wind-turbulence`
  dashed with "unresolved · semantic"; three arcs from wind-grid: a green (measured?) no — `simulated` blue arc to
  `pendulum-bob` labelled "coupling" (drawn to a stub "→ pendulum-bob (another tree)" ONLY if bob-motion's node is
  not in this tree's view — it is another tree, so the stub is expected), a blue "restriction" arc to the slice,
  a grey dashed "decomposition" arc to wind-turbulence. Click wind-grid: dims chips x → position.x, y, z, speed →
  color [0–12 m/s], component → vector; the select form prefilled from the seeded `gust-corner` selection; press
  discover → candidates `wind-grid→bob-drag` (score bar, simulated) then `wind-grid→slice-z0`; refused list holds
  `wind-grid→spectrum` "validity"; click a candidate → the arc highlights. PASS = all of that; anything else = a
  bug in the panel (`tensor-tree-panel.component.ts`), not in the rows (the rows are proven).
- row 2 the wind scene (`newtonian-pendulum-viz`, unchanged since Milestone A) — arrows in a 4×4×4 grid.
- row 3 the plate scene `plate-mechanics-2d`: a 2 m × 1 m plate tiled with 64 coloured TRIANGLES (blue → red over
  0.8–1.1 MPa, nearly uniform yellow/orange with structure near the fixed left edge), the mesh edges as thin lines,
  45 short displacement lines growing from left (zero) to right (longest). Hover a triangle: the tooltip must show
  its σ_vm value (userData.scalar) — if the tooltip shows nothing, that is a viewer gap to file. Zoom: the
  triangles must scale WITH the plate (units=space); the displacement lines too; if triangles stay pixel-sized the
  `units` field did not reach the frontend (`shape-2d-library.service.ts` maps `raw.units`).
- rows 4–8 the configured tables (nodes, dims, mappings, selections, policy, couplings): no raw JSON anywhere.
**Page `/display/tensormath`**: the summary panel, tensors/expressions/implementations tables (two implementations
for `stress-from-strain`: numpy measured on the node, fpga simulated), the FEM field table (one row), the plate
scene again.
**Page `/display/computelod`**: the ladder (eleven rungs), the mappings/characterizations tables — 14 mappings, 24
characterizations, the walk from `c = a + b` through all eleven rungs (`GET /api/computelod/path?rung=c-source&
ref=lod1/add.c: c = a + b`).
**What "done" means**: a short list in this section (or a new unresolved space per gap) — the panel's rules of
§11–§16 either read true on screen or they do not.

### H.2 D-lod4-1 (his) — does SKY130 qualify as MANUFACTURABLE under the sifet ladder rule?

`SiliconProcessNode sky130` (seeded by computelod, §G.13) carries `manufacturable = None` with the evidence
named: SkyWater fabricates SKY130 as a production process; Google-sponsored open MPW shuttles (Efabless,
2020–2023) accepted designs under this open PDK. The rule: True ONLY with evidence of an actually available open
process (a foundry / MPW that accepts the rules); the ladder currently says "today: no rung qualifies". His
ruling flips it or not; the row's `manufacturable_reason` records whichever.

**RULED 2026-09-26 (his): "Maybe another category? Historically proven, might be able to request manufacturing by
3rd party? Or a more abbreviated way of saying that."** → a third answer, as a vocabulary beside the bool:
`manufacturability` ∈ {`open` (manufacturable True — no rung yet), `proven-on-request` (designs under the open PDK
WERE fabricated; a third party — a shuttle or the foundry — might take a request; no standing open door verified;
manufacturable stays None), `unproven`, `not-available`} (`sifet.objects.si_ladder._shared.MANUFACTURABILITY`, a
field on `SiliconProcessNode`, asserted consistent with the bool in `_node`). sky130 = `proven-on-request`; every
sifet rung = `unproven`. Built the same day on dev (sifet ladder selftest 32/32, computelod 92/92).

**Refined the same day (his): "available should be if it is available through a third party closed source vendor,
open should be only if a fully open source option and route exists."** → `open` = a fully open-source option AND
route (no rung today; asserted); `available` = a third-party closed-source vendor takes orders (the reason must name
the vendor; asserted); the bool `manufacturable` = open OR available. sky130 stays `proven-on-request` until a
standing vendor route is verified (not verified here).

### H.3 Further lod work — the natural next rungs, with sizes

| slice | what | needs | size |
|---|---|---|---|
| ~~lod-3d~~ | **BUILT 2026-09-26 (§G.27, branch `dev-lod-3d`)** — all eight cells of the adder through lod-3b/3c: 21 arcs; the two-cell rise-gap verdict did NOT generalize (refuted claim kept, conditional restatement added) | — | done |
| ~~lod-3e~~ | **BUILT 2026-09-26 (§G.30, branch `dev-lod-3e` off dev-lod-2c)** — the whole adder placed and routed with OpenROAD-flow-scripts in its PUBLISHED image (pinned tag + digest; no source build needed), parasitics extracted, timed with and without the wires: the wires cost 2.3–2.4 % | — | done |
| ~~lod-4b~~ | **BUILT 2026-09-26 (§G.31, branch `dev-lod-4b` off dev-lod-3e)** — 8 SKY130 wafer-state stages from the PDK's documented layer stack + 8 textbook unit processes (the recipe named as absent), the CNT route's 6 + 6 by reference to cntfet; `fabrication → materials` replaced by name. The PSPP classes the concept tree already named were used (the only decision: taken as the routine one) | — | done |
| ~~lod-4c~~ | **BUILT 2026-09-26 (§G.28, branch `dev-lod-4c` off dev-lod-3d)** — Ion / Ioff / Vt / DIBL / SS per flavour from DC sweeps on the PDK models; the sky130 row carries them in sifet's key names, evidence `simulated` | — | done |
| ~~lod-2c~~ | **BUILT 2026-09-26 (§G.29, branch `dev-lod-2c` off dev-lod-4c)** — six twin cells at the CNT point (SKY130 simulated at 0.6 V) and at each library's own FO4; CNT area REFUSED (no layout, no rules) | — | done |
| ~~tt-12~~ | **BUILT 2026-09-26 (§G.32, branch `dev-tt-12`)** — the node's scene rendered inside its detail on a click (`sim-space-viewer` hosted by the panel, the node's `sim_space`); unseen in a browser until the images rebuild | — | done |
| ~~tt-13~~ | **BUILT 2026-09-26 (§G.32, branch `dev-tt-12`)** — discovery across trees with the §F3 units filter as a HARD one: same dim name + same unit → a `cross_tree` candidate (lower context term); a different unit or an unrecorded unit → inapplicable, saying which | — | done |
| ~~D5~~ | **BUILT 2026-09-26 (§G.34, branch `dev-d5`; his word: "let us move on to D5")** — PyTorch as the third ComputeImplementation, resolved through the engines ladder (a torch-engines WORKER, pinned CPU wheel; never assumed on a device); benchmarked MEASURED through the worker | — | done |

Order I would take them: ~~browser pass (H.1) → D-lod4-1 → merge → lod-3d → lod-4c → lod-2c → lod-3e → lod-4b → tt-12/13~~ — **§H.3 is complete (2026-09-26)**; D5 (PyTorch) stays his word.

## I. Mathematical proofs — the logic BETWEEN the parts of a TensorTree (revision of 2026-09-24, his ask)

> "another thing I think we still need is mathematics proofs, we will need a library for that and need to be
> able to incorporate it to form logic for describing our logic in between different parts of tensor trees"

### I.1 What is missing today, precisely

A TensorTree today carries three kinds of truth: rows that EXIST (a mapping between two nodes, with dims at both
ends, a validity domain, a loss note), EVIDENCE that something RAN (a tool's output, a simulation, a bench —
§F2's four levels), and STATUS (proposed | implemented | validated). What it does NOT carry is the reasoning
that connects them: WHY a chain of mappings is legitimate, WHAT a mapping preserves or loses, WHETHER two routes
through the tree agree, WHEN a validity domain actually covers the selection. Those are mathematical statements,
and right now they live in prose (`loss_note`, `notes`) that nothing can check. Examples on the trees we have:

- `eps→sigma` (σ = C:ε): C is symmetric in (i,j) and (k,l) → σ is symmetric whenever ε is. Stated nowhere.
- `u→eps` then `eps→sigma` then `sigma→balance`: the composition is a linear map u ↦ ∂σ/∂x; on the plate its
  weak form is what the FEM solve enforces. The chain is only prose.
- `wind-grid→slice-z0` (a restriction) followed by any mapping out of the slice: valid only where the slice's
  validity domain is inside the source's. Discovery filters dims ⊆ selection and the validity domain (§F3); it does
  not check that domains COMPOSE along a chain.
- `wind-grid→spectrum` (a decomposition with `reconstruction_error`): the claim "reconstruction error ≤ r on the
  validity domain" is a number nobody proves.
- lod-3 / lod-3b / lod-3c: "LEF area == Liberty area", "our tpHL is faster than the Liberty on every arc", "the
  parasitics hypothesis is half rejected" — checked in selftests, but the logic (an equality, an inequality
  over a set of arcs, a comparison of two deltas) is not a row anyone can re-run or contest.

### I.2 The library — chosen for licence, reach, and honesty about what each can prove

| tier | library | licence | what it proves | how it lands |
|---|---|---|---|---|
| 0 numeric witness | numpy (present) | BSD-3 | a statement holds ON THE ROWS WE HAVE (all arcs, all elements, a tolerance); never a theorem — a witness, evidence `measured` on the data | in-process |
| 1 symbolic | **SymPy 1.13** (already pinned; `simulations/equation_evaluation.py` parses LaTeX with it) | BSD-3 | identities and simplifications over symbols: σ = C:ε symmetry, index contractions, linearity of a composition, closed-form areas/centroids, derivative/integral identities | in-process |
| 2 decision procedure | **Z3 5.x** (`z3-solver`, MIT, pip; NOT installed yet) | MIT | validity of a quantified statement over reals/ints/bitvectors with a COUNTEREXAMPLE when false: domain inclusion along a chain, interval bounds (tolerances, reconstruction errors), "for all ε in the domain, the mapped σ stays in its domain", bit-exactness of the FPGA kernel's int64 arithmetic (tt-3) | in-process |
| 3 formal | **Lean 4 + Mathlib** (Apache-2.0) | Apache-2.0 | theorems, machine-checked: the ones worth the cost (a tree-composition lemma, a conservation statement) — a `.lean` file per theorem, checked by `lean`, the certificate is the file + the toolchain pin | the tooling submodule `polari-eda-tools` gets a `lean` stage (or a sibling `polari-proof-tools`; D-pf-5) — Mathlib is GBs and slow to build; cached like the PDK, never in git |

Rejected: Coq/Rocq (LGPL-2.1 — a tool, so usable, but Lean's Mathlib covers the analysis/linear algebra we need
and the Apache licence is simpler); Isabelle (BSD, heavy, no advantage here); metamath (permissive, unusable to
write by hand). The ladder is honest by construction: a claim's `proof_status` says WHICH tier established it,
and a tier-0 witness is never called a proof.

### I.3 Rows (new module `mathproofs`, D-pf-4) — one class per file, the standard shape

- **`MathClaim`** — a statement ABOUT rows: `about_refs_json` (the TensorMapping / TensorNode / TensorOperator /
  ComputeMapping / CharacterizationMapping names it speaks of), `kind` ∈ identity | inequality | domain-inclusion |
  composition | conservation | symmetry | commutation | bound | well-typed, `statement_json` (the term language of
  I.4), `statement_latex` (for people), `assumptions_json` (named, each a MathClaim or a plain hypothesis), `scope`
  (the validity domain it claims over — a dict like a mapping's `validity_json`), `proof_status` ∈ conjectured |
  witnessed | checked-symbolically | decided | proved | refuted | unprovable-here, `checker` ∈ numeric | sympy |
  z3 | lean | human, `certificate_ref` (the artifact: a sympy script, a z3 model/counterexample, a .lean file +
  toolchain sha, a human's signed note), `counterexample_json` (when refuted — the point that breaks it, kept),
  `evidence_level` (as ruled: a proof is `analytical`; a witness is `measured` on the data it ran on),
  `provenance`, `notes`.
- **`ProofRun`** — one execution of a checker on a claim: checker + version, elapsed, verdict, output tail,
  `ran_at`, the rows' state hash it ran against (so a changed row invalidates the run, never silently).
- **`InferenceRule`** — the LOGIC BETWEEN PARTS, as data: a rule that GENERATES obligations from the tree's
  structure. Seeded rules (I.5): chain-domain-inclusion, dims-compose, units-compose, evidence-monotone,
  loss-accumulates, restriction-idempotent, decomposition-reconstructs, operator-linear. A rule has a
  `pattern_json` (what structure it matches: two mappings sharing a node, a mapping of kind restriction, …), an
  `obligation_template_json` (the claim it emits), and a `checker_default`.
- **`ProofObligation`** — a claim the rules DEMANDED for a specific structure (a chain, a selection, a discovery
  result), with `discharged_by` (a MathClaim name) or `open`. Discovery (§F3) gains a hard filter: a candidate
  whose obligation is `refuted` is REFUSED with the counterexample; an `open` obligation is shown, not hidden,
  and does not lower the score (D-pf-3).

No new evidence level. A refuted claim never deletes anything: the mapping stays, marked, with the
counterexample beside it — the tree keeps only real gaps, and a refutation is a real fact.

### I.4 The statement language — small, typed, checkable by more than one tier

JSON terms over the objects that exist, never free strings the checkers must parse:

    {"forall": [{"var": "eps", "in": "domain:plate-strain"}],
     "holds": {"eq": [{"apply": "eps→sigma", "to": "eps"}, {"contract": ["C", "eps"], "dims": [["k","l"],["k","l"]]}]}}
    {"forall": [{"var": "x", "in": "validity:wind-grid→slice-z0"}], "holds": {"in": ["x", "validity:wind-grid→bob-drag"]}}
    {"symmetric": {"apply": "eps→sigma", "to": "eps"}, "in": [["i","j"]], "given": {"symmetric": "eps"}}
    {"le": [{"reconstruction_error": "wind-grid→spectrum"}, 0.05], "on": "validity:wind-grid→spectrum"}
    {"eq": [{"sum": {"lef_area": "cells:sky130_fd_sc_hd rv32_add"}}, {"liberty_area": "cells:sky130_fd_sc_hd rv32_add"}], "tol": 0.01}

Each tier lowers the same term: numeric substitutes rows and evaluates; sympy builds symbols and `simplify`s the
difference to 0; z3 encodes reals/intervals and asks for a model of the negation; Lean gets a hand-written
theorem that CITES the term (the term is the spec; the `.lean` is the proof — the bridge is a `statement_hash`
both carry). What a tier cannot lower it REFUSES by name (`unprovable-here` with the reason), never a fake pass.
LaTeX for people is derived from the term, not the other way round.

### I.5 The obligations the current trees generate (what pf-1 would discharge)

| structure | rule | claim | expected tier |
|---|---|---|---|
| plate: u→eps→sigma→balance | chain-domain-inclusion, dims-compose, units-compose | each link's target dims ⊆ next link's source dims; strain domain [0, 0.002] carried through; units 1 → Pa → N/m³ | z3 (intervals), sympy (units) |
| eps→sigma | symmetry | σ symmetric given ε symmetric and C's minor symmetries | sympy (2×2×2×2 symbols) then Lean (the general statement) |
| u→eps ∘ eps→sigma | operator-linear | the composition is linear in u | sympy |
| sigma→balance | conservation | ∂σ_ij/∂x_j + f_i = 0 holds weakly on the FEM solve — a numeric witness on the rows (residual ≤ tol) and an OPEN formal obligation, stated | numeric (measured), Lean open |
| wind-grid→slice-z0 | restriction-idempotent | restricting twice = restricting once | sympy |
| wind-grid→spectrum | decomposition-reconstructs | reconstruction_error ≤ bound on its validity [0, 5] m/s; refuted OUTSIDE it — which is what discovery already refuses, now with the counterexample as a row | z3 |
| lod-3 LEF vs Liberty area | identity with tolerance | Σ LEF = Liberty area within 0.01 µm² | numeric |
| lod-3b/3c arcs | inequality over a finite set | tpHL_ours < tpHL_liberty for all arcs; extracted − schematic > 0 for all arcs | numeric, then z3 over the finite set |
| tt-3 FPGA kernel | bound / bit-exactness | int64 σ accumulate never overflows for C in kPa, ε in nε within their domains | z3 bitvectors |
| tt-4 scale tree | evidence-monotone | a mapping's evidence never exceeds its transfer's | numeric |

### I.6 Where it plugs in (nothing new on screens beyond configured tables + one panel extension)

- `tensortree_validate`: a fourth section `logic` = the obligations of the tree with their status; a node's
  `why` can now say "chain obligation X open / refuted" beside the dims/binding reasons.
- `tensortree_discover`: refuse on `refuted`, show `open` (D-pf-3).
- `tensor-tree-panel` (tt-5): a mapping arc gets a small badge — ✓ proved/decided, ~ witnessed, ? open, ✗ refuted
  (click → the claim, its certificate or counterexample). Rule of the panel unchanged: nothing new drawn, a badge.
- `/api/mathproofs`: claims, obligations, rules; `POST /api/mathproofs/claims/{name}/check?tier=` runs one
  checker and writes a ProofRun; `POST /api/tensortree/trees/{name}/obligations` (re)generates from the rules.
- computelod: the lod cross-checks (area equality, arc inequalities, the parasitics verdict) become MathClaims
  with numeric ProofRuns — the selftests then assert the CLAIM rows, not ad-hoc arithmetic.
- The `TermProof` idea from scoring (re-runnable, accepted per scope) is echoed, not reused: a MathClaim is
  re-runnable by construction; "acceptance" here is the checker's verdict, not a vote (D-pf-6).

### I.7 Phases and decisions

- **pf-0** the `mathproofs` module: four rows, the term language + a lowering to numeric and sympy, the eight
  InferenceRules seeded, the validator's `logic` section, the API; z3 added to requirements (`z3-solver`, MIT);
  selftest + probe. Size: like tt-0 (a day).
- **pf-1** discharge I.5 on the existing trees: sympy proofs (symmetry, linearity, idempotence), z3 decisions
  (domain chains, the spectrum bound, the FPGA int64 bound), numeric witnesses (balance residual, lod
  equalities/inequalities); discovery refuses on refutation; the panel badges. Size: two days.
- **pf-2** Lean 4 tier: the toolchain stage in the tooling submodule (Lean + a pinned Mathlib, cached), the
  `statement_hash` bridge, the first two theorems (symmetry of σ = C:ε in general rank; a tree-composition lemma:
  domains compose ⇒ the chain is valid on the intersection). Size: two–three days, mostly build time.
- **pf-3** authoring: a claim written from a mapping's page (the row's own tab, per per-object-display rule),
  the LaTeX rendered from the term, a "propose obligation" door from a discovery result.
- **pf-4** proofs as knowledge: MathClaims as `TechNode`s in the compute-lod / tensor tech trees
  (prerequisites: which lemmas a rung's reading rests on), so the learning layer (§F: LearningMapping ≠
  ComputeMapping) can point at the mathematics a person needs.

Decisions (his): **D-pf-1** tier order sympy + z3 first, Lean as pf-2 (recommended) or Lean first?
**D-pf-2** the statement language is the JSON term language of I.4 (recommended: one spec, many checkers) or
sympy/LaTeX strings? **D-pf-3** a refuted obligation REFUSES the mapping in discovery (recommended), an open one
is shown and does not lower the score. **D-pf-4** a separate `mathproofs` module (recommended: tensortree,
computelod and scoring all consume it) rather than rows inside tensortree. **D-pf-5** the Lean toolchain in
`polari-eda-tools` (one "tools" submodule) or its own `polari-proof-tools` (recommended: its own — a different
cadence, a multi-GB Mathlib cache, and a proof checker is not an EDA tool). **D-pf-6** verdicts are the checker's,
not voted — but a `human` checker (a signed note) exists for what no tier can do, and is labelled as such.

### I.8 RATIFIED 2026-09-24 — D-pf-1..6 as recommended; `polari-proof-tools` is its own submodule

- D-pf-1 tiers in order: numeric → SymPy → Z3 in pf-0/pf-1; Lean 4 as pf-2.
- D-pf-2 the JSON term language of I.4 is THE statement (one spec, many checkers); LaTeX is derived from it.
- D-pf-3 a refuted obligation REFUSES the mapping in discovery (with the counterexample); an open one is shown and
  does not change the score.
- D-pf-4 a separate module `mathproofs`. Dependency direction, so nothing cycles: `mathproofs` requires NOTHING
  of the tensor/compute modules (claims name rows by class + name as strings and read them through the manager);
  `tensortree` and `computelod` SOFT-depend on it (guarded import: without mathproofs the validator's `logic`
  section says "no proof module" and discovery skips the refusal filter, stated in the response).
- D-pf-5 the Lean toolchain lives in **`polari-rf-node/polari-proof-tools`** (new repo `dausume/polari-proof-tools`,
  a sibling of `polari-eda-tools`, same discipline):
  - `Dockerfile` — ubuntu:24.04 + `elan` installing ONE pinned Lean 4 release (`lean-toolchain` file in the
    repo = the pin) + a `lakefile` depending on Mathlib at ONE pinned commit; `lake exe cache get` at build so
    the image carries Mathlib's compiled oleans (several GB — the image is big and that is the honest cost; it
    is never pulled by production, D-pf-7). `z3` is NOT here: it is a pip dependency of the framework
    (`z3-solver`, MIT) because it runs in-process at tiers 0–2.
  - `flows/check.sh <file.lean>` — runs `lake env lean` on one theorem file and prints the verdict line the
    framework parses (`POLARI_PROOF ok|error <hash>`), plus the toolchain + Mathlib pins so the ProofRun cites
    them.
  - `theorems/` — the `.lean` files the framework's MathClaims cite by `certificate_ref` (path + sha256 +
    `statement_hash`). They are SOURCE, committed here, small. Each file's docstring carries the term statement
    it proves, verbatim, so the bridge is readable by a person.
  - `LICENSES.md` — Lean 4 (Apache-2.0), Mathlib (Apache-2.0), elan (MIT/Apache-2.0), the Ubuntu base; the
    same "every tool is a separate process, nothing linked or vendored" ledger as the EDA one.
  - Knobs the framework reads: `POLARI_PROOF_IMAGE` (default `polari-proof-tools:noble`), `POLARI_PROOF_THEOREMS`
    (default the submodule's `theorems/`). `fetch-` nothing: the pins are in the image.
- D-pf-6 verdicts are the checker's; a `human` checker exists (a signed note), labelled as such, and it can only
  be written by a user the claim's OWNER permits (the owner-defined-permissions rule — per-instance, opt-in).

### I.9 Refinements that follow from the ratification

- **pf-0 detail.** Rows as I.3. Term language v0 operators: `forall`/`exists` (over `domain:<node>` |
  `validity:<mapping>` | a finite set `rows:<Class>:<filter>`), `eq` (with `tol` abs/rel, default rel 1e-9),
  `le`/`lt`/`ge`/`gt`, `in`, `and`/`or`/`not`/`implies`, `apply` (a mapping/operator to a term), `contract`
  (named-dim contraction — the tensormath op), `symmetric`/`antisymmetric` (in dim pairs), `sum`/`max`/`min`
  over a finite set, `reconstruction_error`/`lef_area`/`liberty_area`/… as READERS of row fields (each reader
  names the class + field it reads — no hidden lookups). Lowering: numeric (numpy over rows), sympy (symbols
  per dim index; `simplify(lhs − rhs) == 0`); z3 arrives in pf-1 (reals for domains/bounds, bitvectors for the
  FPGA kernel). Anything a tier cannot lower → `unprovable-here` naming the operator.
- **Staleness.** A ProofRun stores `rows_state_hash` over the rows the claim names; the validator marks a run
  `stale` when the hash differs and shows the claim as `open (stale)` — never as still proved.
- **Engines through the ladder (corrected 2026-09-24).** Tiers 0–2 are pip libraries and run in-process. Tier 3
  (Lean) is an ENGINE the module declares in its manifest and the topology places: `polari-proof-tools` serves
  `/capability` + `/check`, `mathproofs/custom/proof_engines.py` resolves it exactly as `computelod.custom.
  eda_engines` does. ProofRun rows and certificates are rows/files and travel as such.
- **Budgets.** Automatic re-checks on row change: tier 0–1 always (milliseconds); z3 with a per-claim time
  budget (default 10 s) that self-disarms on timeout and records `undecided (budget)`; Lean never automatically
  — a person (or the pipeline) runs it. Mirrors the tracing-budget rule.
- **computelod's cross-checks become claims in pf-1** (LEF == Liberty area; the arc inequalities; the parasitics
  verdict as two inequalities over the arc set) and the selftests assert the claim rows.
- **The pipeline (ci)** gets a `proofs` stage after `selftests`: tiers 0–2 on every claim, Lean on the theorems
  whose `.lean` changed — advisory (a red verdict is reported, not a build failure) until he says otherwise.

### I.10 Decisions still open (small; recommendations given)

- ~~D-pf-7 — where Lean runs~~ WITHDRAWN 2026-09-24 (his correction): a module's engines are placed by the
  topology like everything else — `mathproofs` declares `requires.engines` (`lean`), `polari-proof-tools` is an
  engines WORKER (`/capability` + `/check`), the framework resolves through the standard ladder (knob →
  local → topology provider `mathproofs.engines` → refusal), and `pol allocate mathproofs.engines <instance>`
  decides the device. No dev/prod split is assumed anywhere; certificates travelling as rows is still true, but
  it is a property of rows, not a placement rule.
- **D-pf-8 — proofs and `mapping_status`.** Recommended: proofs NEVER change a mapping's `mapping_status` or
  `evidence_level` (those are about running); the validator's `logic` section and the panel badge are the
  proof's own surface. Alternative: a `logic_status` column on TensorMapping — one more column, rejected unless
  the badge proves insufficient.
- **D-pf-9 — the z3 budget default** (10 s per claim, recommended) and whether a budget timeout counts as
  `undecided` (recommended) or `refuted` (no — absence of a decision is not a counterexample).
- **D-pf-10 — the first two Lean theorems** for pf-2. Recommended: (a) σ = C:ε symmetry in general rank from
  C's minor symmetries; (b) the tree-composition lemma: if each link's validity domain contains the next link's
  source domain, the chain is valid on the intersection. Alternative (c): restriction idempotence — trivial, a
  good smoke test but not worth a theorem.
- **D-pf-11 — the Lean/Mathlib pins**: chosen at pf-2 build time (latest stable Lean 4 release + the Mathlib
  commit that builds with it that week), recorded in `lean-toolchain` + `lake-manifest.json` in the submodule.
  Only the POLICY needs his word: track stable releases, bump deliberately, never float.

### G.20 The engines SEAM — a correction of my own assumption BUILT 2026-09-24

His challenge: "it is a module, it should be able to run on any device we want it to … I hope you did not make
the assumption that was not the case and built things circumventing or duplicating that." I had, in two places:
every lod flow (lod-1/2/2b/3c) and the FPGA kernel ran `docker run polari-eda-tools:noble …` on the LOCAL machine
directly, with no `requires.engines`, no ladder, no worker, no `pol allocate`; and plan §I's D-pf-7 hard-coded a
dev/prod split for Lean. Both corrected:

- **`computelod/custom/eda_engines.py`** — the Polari engines ladder, per engine, exactly as `cntfet.cnt_remote`
  and `materialsScience.engines.remote`: `EDA_ENGINES_URL` (always, or refusal — a declared worker never silently
  degrades) → a local binary → the pinned image on THIS device (a way of having the binary, not a worker) → the
  topology's LIVE provider for `computelod.engines` (`pol allocate computelod.engines <instance>`) → a refusal
  naming both knobs. `placement()` answers before any dispatch; `GET /api/computelod/engines` serves it.
  Execution is ARGV ONLY (engine + args; the flows' `| grep` / `> log` pipelines are Python now); the PDK is
  `/pdk/…` to the engine (a local binary gets the real root translated). ngspice goes through cntfet's existing
  ladder (`find_ngspice` / `run_ngspice`), with absolute `.include`s inlined when the worker is remote (it takes
  netlist text only).
- **`polari-eda-tools` is an engines WORKER**: `eda_engines_service.py` (`GET /capability` per engine + the PDK,
  `GET /system-info`, `POST /run {engine, args, files, files_b64, env, timeout}` → returncode/stdout/stderr/files;
  a whitelist of binaries, no shell; args are basenames in the job or the image's own read-only data
  (`/pdk/…`, `/usr/share/…`)), the image's default command on :9800; `polari-rf-node/docker-compose.eda-engines.yml`
  deploys it like cnt-engines. OpenSTA joined the image (the openroad/opensta binary copied; GPL-3 tool, ledger
  row) so ONE image = every engine.
- **Manifests** now declare `requires.engines` for computelod (riscv-gcc, yosys, iverilog, sta, magic, netgen,
  ngspice) and tensormath (yosys, nextpnr-ice40, iverilog), in the hwdigital/materials_science shape.
- **Proof**: lod-1, lod-2 and lod-3c re-run through the ladder in BOTH modes — local image, and a live worker with
  `EDA_ENGINES_URL` set (every engine `remote`, the worker's own PDK) — give IDENTICAL numbers to the committed
  reports (0x00b50533 / 220 / 8126 / PASS 4/4; 96 cells 855.82 µm² 11.9394 ns; DRC 3/4 context, LVS match,
  14/23 caps, tpHL 67.76 / 95.81 / 98.96 ps). computelod 87/87, tensormath 61/61, manifests valid, live boot
  **95/95**.

### I.11 RATIFIED 2026-09-24 — D-pf-8..11 as recommended ("decisions wise")

- D-pf-8 proofs never change `mapping_status` / `evidence_level`; the validator's `logic` section + the panel badge
  are their surface.
- D-pf-9 Z3 budget 10 s per claim (a knob), self-disarming; timeout = `undecided (budget)`, never `refuted`.
- D-pf-10 first theorems: (a) σ = C:ε symmetry in general rank; (b) the tree-composition lemma; (c) restriction
  idempotence as the toolchain smoke test only.
- D-pf-11 pins: `lean-toolchain` + `lake-manifest.json` committed in `polari-proof-tools`; track stable, bump
  deliberately with the theorems re-checked in the same commit; never float.

Nothing else gates pf-0. Branch discipline: `dev-pf-0` off `dev-tt-0` (it needs the tensortree rows, which are
not on dev yet); merged after `dev-tt-0`, in order. Still his and independent: D-lod4-1.

### G.21 pf-0 — the `mathproofs` module BUILT 2026-09-24/25 (branch `dev-pf-0` off `dev-tt-0`)

Proofs as rows, in the standard module shape, wired through the whole checklist:

- **Rows**: `MathClaim` (kind; the JSON term; derived LaTeX; `proof_status` by the vocabulary conjectured |
  witnessed | checked-symbolically | decided | proved | refuted | unprovable-here; `checker`; `certificate_ref`;
  the counterexample kept; `evidence_level` analytical for a proof/decision, measured for a witness; `statement_hash`
  — the bridge to a .lean certificate; `budget_s` = 10, a knob, D-pf-9), `ProofRun` (checker + version, verdict,
  detail, elapsed, `rows_state_hash` → a changed row makes the run STALE, shown as `<status> (stale)`),
  `InferenceRule` (pattern `chain[:k1,k2]` | `mapping:<kind>[:<op>]` | `node`; a term template with {m1} {m2}
  {node}; the checker expected), `ProofObligation` (what a rule demanded of a structure; discharged_by a claim).
- **The term language v0** (`custom/terms.py`): refs with a key path into json fields, sum/max/min/count over
  filtered row sets (`=` exact, `~` substring), add/mul, eq with rel/abs tolerance, le/lt/ge/gt, and/or/not/
  implies, finite `forall` over rows (the first failing row IS the counterexample), `subset` over interval sets
  (validity:/domain:/scope:), `dims_subset`, and `symbolic` templates. `validate` refuses malformed terms;
  `canonical`/`statement_hash`; LaTeX derived, never authored.
- **Tiers**: numeric witness (`custom/numeric.py`, measured on these rows — never a proof), interval decision
  (exact set arithmetic — decided), SymPy (`custom/symbolic.py`: `symmetry-of-contraction` for any n over free
  symbols, `linear-composition`, `restriction-idempotent` — checked-symbolically). Anything a tier cannot lower →
  `unprovable-here` by name (the continuum `forall` is the z3 tier, pf-1; lean pf-2). `custom/checkers.py`: the
  status vocabulary, a weaker tier never overwrites a stronger verdict, refuted always wins and keeps the
  counterexample; proofs NEVER touch `mapping_status` / `evidence_level` (D-pf-8, proven in the probe).
- **The eight rules** (`custom/rules.py`, seeded): chain-domain-inclusion, dims-compose (source dims ⊆ the previous
  target dims), units-compose (template-less: per-dim units do not exist — an open gap by name), evidence-monotone
  (template-less, same honesty), restriction-idempotent, decomposition-reconstructs (an UNRECORDED reconstruction
  error is refused, never passed vacuously), operator-linear (chain:operator,operator), operator-symmetry
  (mapping:operator:contract). `generate(tree)` is idempotent by name and runs the cheap tiers at once.
- **On the real trees** (live boot): plate-mechanics → 4 decided (domains + dims compose along u→ε→σ→balance),
  3 checked-symbolically (linearity ×2, σ-symmetry), 2 unprovable-here (units); wind-spatial → the proposed
  `wind-grid→spectrum` decomposition **REFUTED** (reconstruction_error 0.0: it never said what it loses) and the
  restriction idempotent; bob-motion → nothing to demand. Five standalone claims: LEF == Liberty area witnessed
  (855.82 = 855.82), every tpHL faster than the Liberty witnessed, extraction slows every arc witnessed, σ = C:ε
  symmetric in 2-D and 3-D checked-symbolically (12 / 42 free symbols).
- **The soft seam** (`tensortree/custom/tensortree_logic.py`, D-pf-4): tensortree never imports mathproofs at top
  level; the validator gains a `logic` section, discovery refuses a candidate whose obligation is refuted (with
  the counterexample) and shows open ones, `/view` mappings carry `logic` (badge + obligations); without the
  module every reader says `available: False` and why.
- **Visible on the mappings** (his ask on D-pf-8): the panel draws ✓ / ? / ✗ on the arc (title = the obligations
  and counterexamples) and in the mapping list; the `mathproofs` page has the claims / obligations / rules / runs
  tables and the summary with the **aggregate time reading** (D-pf-9: what the latest runs cost, and the worst
  case = the sum of budgets of the long-running claims) — `GET /api/mathproofs/aggregate`.
- **API**: `/api/mathproofs` · `claims/{name}` · `POST claims/{name}/check?tier=` · `rules` · `obligations?tree=|
  mapping=` · `POST|GET trees/{name}/obligations` · `aggregate`. Manifest declares `lean` as an ENGINE (resolved
  through the engines ladder when pf-2 lands — no device assumption), sympy as the library; z3 is a pip dep for pf-1.
- Proof: mathproofs 39/39, tensortree 64/64, lazy-import drift 23/23, tsc clean, live boot **103/103**.
- Not yet: obligations are generated on a person's POST (not at boot) — the panel shows `–` until then; pf-1
  (z3, the lod claims as rows in computelod's selftests, discovery on refuted through the whole cycle), pf-2 (Lean).

### G.22 The vocabulary correction — inapplicable · undetermined · refuted (his, 2026-09-25)

> "maybe saying refuses is the wrong way to talk about it. You are saying it is not defined within that state
> space, using the word refuse would seem you are implying it is falsified, but it is just that the model is
> shifting with state space differences"

Three different things had one word. Now each has its own, in the rows, the API and the panel:

- **inapplicable** — a mapping is NOT DEFINED on the selection's state space (it needs dims the selection lacks;
  the selection lies outside its validity domain). The model shifts with the state; nothing is falsified.
  Discovery reports these under `inapplicable` with a `kind` (`dims-not-in-selection` | `outside-validity`); the
  panel lists them as "not defined on this selection".
- **undetermined** — a claim cannot be evaluated because a premise fails or a value it needs was never recorded:
  the model is silent there. New verdict / `proof_status` `undetermined`; term-language `{"given": <premise>,
  "holds": t}` (three-valued) and `{"recorded": ref}`. The decomposition rule now reads: GIVEN a recorded
  reconstruction error (its `error_method` names how), it is within the bound; with none recorded the obligation
  is undetermined — so `wind-grid→spectrum` (a tt-1 hypothesis mapping, never computed) carries ∅, not ✗.
- **refuted** — a genuine counterexample exists (on the rows, or over symbols). Only this is falsification, and
  only this sets a mapping aside in discovery (`refuted`, with the counterexample).
The pre-existing `refused` key in discovery results is kept as the union of the first two-and-third lists for
readers, each entry saying which it is. Badges: ✓ ok · ? open · ∅ undetermined · ✗ refuted · – none.
Proof: mathproofs 42/42 (a decomposition with a recorded error is witnessed; the same rule with none is
undetermined; the two discovery lists differ), tensortree 64/64, live boot **104/104**, tsc clean.


### G.23 pf-1 — the Z3 tier BUILT 2026-09-25 (branch `dev-pf-1` off `dev-pf-0`)

The decision procedure, in the same term language, honest about what it decides and what it costs:

- **`mathproofs/custom/z3tier.py`** — `forall`/`exists` over a CONTINUUM (`validity:` / `domain:` / `scope:` interval
  sets: one real per constrained dim, the box as constraints, `holds` over reals with `{"ref": "x", "path": ["<dim>"]}`
  the point's coordinate and the new `{"in": ["x", <set>]}` membership); a `forall` is decided by asking for a MODEL OF
  ITS NEGATION — unsat → `decided`, sat → `refuted` with the model as the counterexample (a real point of the domain);
  `subset` is re-derived as ∀x∈A: x∈B, a second independent procedure that agrees with the interval tier on every pair
  (selftest + live). `given` premises are row facts (numeric tier) → `undetermined` when false. What it will not lower
  it refuses by name: a closed statement over row values (that is the numeric WITNESS — calling it decided would dress
  data up as a theorem), a relative tolerance over a continuum, symbolic templates, nested quantifiers (v1).
- **The tt-3 kernel's fixed-point contract as a decision** — `{"bitvector": {"template": "mac-no-overflow", …}}`:
  `products` signed products of `operand_bits` operands accumulated one at a time in `acc_bits` — EVERY PREFIX SUM
  within the signed range (a total that fits is not enough: the accumulator is sequential). Bounds are numeric TERMS
  read from rows (ε in nε = eps→sigma's validity 0.002 × 1e9 = 2·10⁶; C = the int32 port), never typed twice. Finding
  while building: the bit-blasted encoding (QF_BV, four 64-bit multipliers) needs ~19 s on pol-core — beyond the 10 s
  budget, i.e. honestly `undecided` — while the operands ARE integers, so unbounded integers with the ranges as
  constraints (QF_NIA) lose nothing and decide in 0.7 s; `encoding: "int"` is the default, `"bv"` stays selectable.
  Decided: 4 × int32·int32 in int64 never overflow (9.07 bits of headroom stated); refuted with full-range operands
  (the model names the operands, the prefix sums and the first step that overflows).
- **Budget (D-pf-9)** — each claim's `budget_s` → the solver's timeout; `unknown` → the ProofRun says `undecided`
  (budget) and the claim's status is UNTOUCHED (stays `conjectured`, no certificate). The selftest forces it through a
  seam (`_check`); the real 19 s case above is the live instance of it.
- **The knob (D-pf-9's "placeholder 0.05")** — `InferenceRule.params_json` (new field; the module has never been
  deployed, so its own schema is free): `decomposition-reconstructs` carries `{"bound": 0.05, …}`, its template reads it
  BY REF (`InferenceRule:decomposition-reconstructs.params_json.bound`) and the rule row joins the claim's `about_refs`
  — turning the knob makes every obligation under it STALE and re-generation re-checks (0.01 → the 0.03 decomposition is
  refuted); a policy change is never a silent re-verdict. Shown as a column of the rules table.
- **At boot (`custom/boot.py`, called from polariServer after the seed pass)** — every seeded tree's obligations
  generated; every never-run claim checked once through its cheapest tier (z3 inside its budget). Live: three trees,
  12 claims, 2.7 s. The panel's badges and the validator's `logic` section exist without a POST; the pass is bounded by
  the aggregate's worst case — now non-zero: 50 s (4 seeded z3 claims + the chain obligation a person asked z3 to
  re-derive, 10 s each) against 0.78 s actually spent.
- **The lod cross-checks are claim rows in computelod's selftest** — LEF == Liberty area (855.82 = 855.82), every tpHL
  faster than the Liberty, extraction slows every arc, and the parasitics verdict as TWO inequalities over the extracted
  arcs (`lod3c-extraction-narrows-every-fall-gap`: delta_pct > schematic_delta_pct, both < 0, on all three;
  `lod3c-extraction-widens-every-rise-gap`: both > 0, on all three) — asserted through `mathproofs.checkers.check` on
  the seeded characterization rows, plus a perturbed LEF row → stale → refuted with both numbers kept. Seven new
  seeded claims in all (the two above; C in kPa fits int32 for the cited electrical steel — E·10³ ≤ (2³¹−1)(1−ν²),
  a numeric witness on the material row; ε in nε fits int32 over the validity domain — z3; the int64 accumulate — z3;
  spectrum range ⊆ drag-coupling range — z3 decided; the converse — z3 REFUTED by the model speed = 6 m/s).
- **Alpine** — PyPI's `z3-solver` has no musl wheel; the framework image is `python:3.12-alpine`. Both Dockerfiles take
  the binding from apk (`py3-z3`, pure python, copied into the venv) and `libz3` from apk `z3` (16 MB, soname linked +
  `Z3_LIBRARY_PATH`); a glibc host pip-installs `z3-solver==5.1.0.0`. The image carries Alpine's 4.16.0, the host 5.1.0
  — the ProofRun records which; `requirements.txt` says why it is not pinned there.
- ProofRun names now carry microseconds (two runs in one second were one name → a false `(stale)`).
- Proof: mathproofs **60/60**, computelod **91/91** (+4), tensortree 64/64, tensormath 61/61, lazy-import drift 23/23,
  manifests valid, live boot **110/110** (from the framework dir with `data/` cleared — the probe's source-path
  resolution is cwd-relative, so a bare `/tmp/tt` cannot boot; the handoff's gotcha is corrected).
- Not done: `exists`/`forall` nesting; relative tolerances over a continuum; the units/evidence rules are still
  template-less by name; Lean (pf-2).
- **D-pf-9 amended (his, 2026-09-25): the default budget is 25 s** ("set the budget to 25s then since the highest was
  19s") — `MathClaim.budget_s` default, the seeds, the checker's fallback; the aggregate's worst case is now 125 s for the
  five z3 claims. Still a per-claim knob; still `undecided`, never refuted, on a timeout.

### G.24 pf-2 — the Lean 4 tier BUILT 2026-09-25 (branch `dev-pf-2` off `dev-pf-1`; NEW submodule `polari-rf-node/polari-proof-tools`)

The formal tier, as an engines worker, with the pins where D-pf-11 said and the bridge D-pf-2 implied:

- **`dausume/polari-proof-tools`** (public, default `dev`, submodule of polari-rf-node beside polari-eda-tools, same
  discipline): `Dockerfile` (ubuntu:24.04 + elan installing exactly `lean-toolchain`; Mathlib at the manifest's commit;
  its compiled oleans via `lake exe cache get` through a BuildKit cache mount; `lake build PolariProofs` at build — the
  image does not exist unless every committed certificate checks), **pins** `lean-toolchain` = `leanprover/lean4:v4.34.1`
  (stable, released 2026-09-24) and `lake-manifest.json` with Mathlib `d13f23b723b8a846827a245b89c10fc7d3f11612` (tag
  v4.34.1) + its eight transitive packages, `flows/check.sh` (`lake env lean <file>` → `POLARI_PROOF ok|error <hash>` +
  `POLARI_PINS`), `proof_engines_service.py` (:9810 — `GET /capability` with pins + the theorem files and the hashes
  they cite, `GET /system-info`, `POST /check {file | source+name, statement_hash, timeout}` → verdict, file sha256,
  `hash_matches`, pins, elapsed), `LICENSES.md` (Lean/Mathlib/elan Apache-2.0, all tools as separate processes),
  `docker-compose.proof-engines.yml` in rf-node. Measured: image **11.0 GB**; a check 8.3 s cold via `docker run`,
  **2.3–3.9 s** through the warm worker.
- **The theorems (D-pf-10)**, each file's header citing the JSON term verbatim and its `statement_hash`:
  `SigmaSymmetry.lean` — `sigma_symm`: σ_ij = Σ_kl C_ijkl ε_kl is symmetric for EVERY n over any commutative
  semiring given C's FIRST minor symmetry alone (the proof states the exact hypothesis it uses — less than the LaTeX
  reading assumes; ε's symmetry is not needed for this direction); `ChainComposition.lean` — `chain_subset_of_le`,
  `chain_valid_on_last`, `chain_inter_eq_last`: pairwise V_{i+1} ⊆ V_i along a chain gives V_n ⊆ V_i for all i ≤ n and
  ⋂_{i≤n} V_i = V_n — the reason the `chain-domain-inclusion` rule's PAIRWISE obligations suffice, over any type α;
  `RestrictionIdempotent.lean` — the smoke test over any index type. Lean's own corrections while building: imports
  before the doc block; `Set.subset_iInter₂` (not `subset_biInter`); `Mathlib.Data.Set.Lattice` is deprecated in
  favour of `.Indexed`; `Mathlib.Logic.Basic` no longer exists (the tactic import `Mathlib.Tactic.SplitIfs` is what
  was needed); `Fintype (Fin n)` comes with `Mathlib.Algebra.BigOperators.Fin`.
- **The framework**: `mathproofs/custom/proof_engines.py` = the engines ladder EXACTLY as `computelod.custom.
  eda_engines` (PROOF_ENGINES_URL always-or-refusal → local project `POLARI_PROOF_PROJECT` + lake → local image
  `polari-proof-tools:noble` → topology provider `mathproofs.engines`, `pol allocate mathproofs.engines <instance>`
  (generic, no CLI change) → refusal naming both knobs); `GET /api/mathproofs/engines` = the placement.
  `custom/lean_tier.py`: template → committed file (`symmetry-of-contraction n=any`, `chain-domains-compose links=any`,
  `restriction-idempotent`), `proved` ONLY when lean accepted the file AND `hash_matches`; a proof of a different
  statement → `unprovable-here` by name; lean rejecting → `error` (a proof failed — nothing is said of the statement,
  never `refuted`); timeout → `undecided`; the ProofRun's `checker_version` = the Lean toolchain + Mathlib commit +
  where it ran. The term language: `symbolic` args `"any"` name the general statement (sympy names it as the lean
  tier's and steps aside); new template `chain-domains-compose`. `auto_tier` → `lean` for the general statements;
  **boot never runs lean** (plan §I.9) — such claims are listed as awaiting a person / the pipeline.
- **Seeds**: `sigma-symmetry-general-rank`, `chain-domains-compose-lemma`, `restriction-idempotent-theorem`
  (budget 300 s: Mathlib's imports load before the check). Aggregate worst case now 1025 s (5 z3 × 25 + 3 lean × 300).
- **Proof**: mathproofs **70/70** (the ladder refusing with both knobs named; the worker faked for the four verdicts;
  the REAL smoke check through the local image, 3.0 s); tensortree 64/64, computelod 91/91, tensormath 61/61, drift
  23/23; live boot **116/116 in BOTH modes** — the local image, and the worker over `PROOF_ENGINES_URL` — all three
  theorems PROVED with the pins on the run; two real negatives through the worker: a proof of another statement →
  `hash_matches: false` (not counted), `theorem bad : 1 = 2 := rfl` → `error`.
- Not done: the CI `proofs` stage (plan §I.9 — advisory; Lean on the theorems whose `.lean` changed); pf-3 authoring;
  pf-4 proofs as TechNodes; a topology instance row for a proof-engines worker (none seeded, as with eda-engines —
  `pol allocate` needs an instance to exist).

### G.25 pf-3 — authoring doors + the pipeline's `proofs` stage BUILT 2026-09-25 (branch `dev-pf-3` off `dev-pf-2`)

His steer while building: "we have multiple samples of how to make interfaces for latex/katex already through the
app that use assistive ui panels that act as entry using the symbols as buttons and categorizing them" — so the claim
editor IS that shape (latex-edit-dialog + equation-symbol-palette), with our vocabulary:

- **The doors (`mathproofs/custom/authoring.py`, never a raw row insert)**: `POST /api/mathproofs/terms/preview`
  {statement} → the term validated (errors by path), its LaTeX DERIVED here, the tier that would speak, its
  statement_hash — the editor's live preview, one derivation, in the backend (D-pf-2 kept: LaTeX is never authored);
  `POST /api/mathproofs/claims` {name, kind, about, statement, description, scope, budget_s, from} → validated
  (kind ∈ the nine; the rows it speaks of must exist; 409 on a name that exists — claims are re-checked, not
  re-written), stored with provenance "authored by a person (…) from …", CHECKED AT ONCE through its cheapest tier —
  except a general (lean) statement, which is stored and told how to ask (plan §I.9); `POST
  /api/mathproofs/obligations/propose` {mapping, selection, via?} — the discovery result's door: the candidate's
  validity on THIS selection as a durable row (`subset(scope:<claim>, validity:<m>)`, the selection's ranges as the
  claim's scope) under the rule name `proposed-from-discovery`, and, arriving `via` a link, the chain pair the rules
  would demand (domains + dims); the interval tier decides at once, a refutation names the dim, the row goes stale
  when the mapping's validity moves; idempotent by name. Every discovery candidate now CARRIES its door (`propose`:
  method, path, body) through the soft seam; `select`/`discover` take `via`.
- **The editor (Angular, `claim-edit-dialog`, beside `latex-edit-dialog` and sharing its stylesheet)**: name / kind /
  about / description / budget; the term textarea; the palette — `equation-symbol-palette` generalised with an
  `@Input() categories` and a `SymbolPaletteEntry.insert` (the button shows the glyph, e.g. ∀, and inserts the JSON
  snippet; `filterPalette` searches the inserted text too; the LaTeX editors are unchanged) — fed the new
  `models/proofs/ClaimTermPalette.ts`: Quantifiers (∀ over rows / over a domain, ∃) · Sets & domains (⊆, ∈, dims) ·
  Comparisons (=, = ± ε, ≤ < ≥ >) · Logic (∧ ∨ ¬ ⇒, given, recorded) · Reading rows (ref, Σ max min #, + ·) ·
  Templates (σ symmetry (n), composition linear, restriction idempotent, the chain theorem, MAC never overflows), each
  with a tooltip and the proofs page as its docs link; the preview card renders the BACKEND's LaTeX (debounced
  preview call) with the tier and the hash; Save = write + check, and the verdict card shows what the tier said
  (with the counterexample when refuted) before the dialog closes.
- **Where it opens**: the tensor-tree panel — `claim` on every mapping row (about prefilled with the mapping), and
  `propose: valid on this selection` on every discovery candidate (one click through the door; the result inline;
  the mappings' badges reload). The mathproofs page's claims table renders `statement_latex` through the new
  `latex` column format of `class-rows-table` (the shared `katex-display`; no new component for that).
- **The pipeline's `proofs` stage (plan §I.9, ADVISORY)**: `polari-framework/tests/proofs_stage.py` (boot the real
  server in the built image; every claim through its cheapest tier; the Lean certificates only where the ladder
  resolves — `PROOF_ENGINES_URL` named by the pipeline device — and only the `.lean` files whose sha256 differs from
  their last recorded proof; JSON out; exit 0 always), `polari-jenkins/proofs.sh <out>` (`docker run --rm --network
  host -u host-uid -v out:/out … tests/proofs_stage.py --out /out/results.json`, the scans' rule: recorded, never a
  build failure), a stage in `Jenkinsfile.test` after the selftests, `verdict.py` (`proofs_summary`, a line in `show`)
  and `report.py` (a "Proofs (ADVISORY)" section). Proven here against a freshly built backend image with the worker
  named: 26 claims, Lean checked through the remote worker, the one red = the deliberately refuted seed, verdict
  line + report section rendered; 122 s (the boot is most of it).
- Proof: mathproofs **79/79**, tensortree 64/64, tsc clean + `ng build` clean, live boot **123/123** (preview; an
  authored claim decided by z3 at once; 409/400 by name; the candidate's door; the proposal through it — three rows
  decided; the aggregate now 30 claims / 1050 s worst case).
- Not done: pf-4 (MathClaims as TechNodes); the mathproofs page has no "+ claim" of its own (the doors live on the
  panel and the API); the discovery's `via` is only what a caller passes (the panel's follow does not yet pass it).

### G.26 pf-4 — proofs as KNOWLEDGE BUILT 2026-09-25 (on `dev-pf-3`)

- **`mathproofs/custom/knowledge.py`**: the `tensor-proofs` tech tree (techtree rows, seeded only when techtree is
  present — exactly as computelod's concept tree): ten TechNodes = the ideas the tensor trees and the compute ladder
  rest on — a witness is not a proof (the vocabulary root) · named-dimension contraction · minor symmetries of the
  stiffness · linear links compose · validity domains as boxes · pairwise inclusion makes a chain valid · restriction
  is idempotent · a decomposition must say what it loses · fixed-point arithmetic and overflow · two independent
  sources agreeing is evidence. Edges = recommended learning order; each node CITES the MathClaims that establish it
  (`cross_refs` relation `proved-by`, incl. the boot-generated obligations by their deterministic names), the rules it
  underwrites, and the compute-lod rungs / tensortree mappings it rests on; a `theory` TechSegmentAssignment per cited
  claim. Nothing is copied: the claims stay the truth.
- **`GET /api/mathproofs/knowledge`** = the tree joined LIVE: per node the cited claims with their current status, and
  `established` only while every cited claim is SETTLED — it holds (witnessed / decided / checked-symbolically /
  proved, not stale) or it is refuted by a counterexample (a refutation is knowledge too: "the converse fails at speed
  6" is a fact a person learns; listed under `refutations`); open / undetermined / unprovable-here / stale claims show
  on the node they belong to with the reason. `by_rung` = what rtl / microarchitecture / standard-cells / devices /
  layout rest on, each with its flag — the door the learning layer (§F, LearningMapping ≠ ComputeMapping) points at.
- Live after boot: fixed point, two-sources-agree, linear composition, interval domains (with its refutation)
  ESTABLISHED at once; minor symmetries and chain composition become established only once a person asked the lean
  tier (proven in the probe: they flip when the ladder resolves); the decomposition node stays NOT established because
  its claim is undetermined — and says so.
- Proof: mathproofs 83/83, live boot **126/126**.
- The proofs arc pf-0..pf-4 is now built. Left on the arc: his browser pass (§H.1 — now also the claim editor, the
  panel's `claim`/`propose` doors, the `latex` column, the tensor-proofs tree in the techtree display), D-lod4-1, the
  merge word; then §H.3 further lod.

### G.27 lod-3d — EVERY cell of the adder through devices → layout BUILT 2026-09-26 (branch `dev-lod-3d` off `dev`, framework + rf-node + suite)

The first §H.3 slice after the merge. lod-3b/3c had proved two cells (inv_1, nand2_1; three arcs); the adder uses eight.
Nothing new was installed: the same ngspice (`~/tools`, through the cntfet engines ladder), the same eda-tools image
and cached PDK, the same Liberty.

- **The arc table** (`lod3_devices.ARCS`, 8 cells · 21 arcs): per cell its output pin and Liberty `function`; per arc
  the input pin, the OTHER pins' tie values that sensitise it, and whether it inverts (= the Liberty group's
  `timing_sense`). A non-unate input (xor2_1, xnor2_1) gets one arc per tie — `A→X (B=0)` positive-unate, `A→X (B=1)`
  negative-unate — so each of the four xor/xnor arcs is compared with ITS Liberty group; maj3_1 with two pins tied
  opposite (B=1, C=0 for A); o21ai_0 (A1: A2=0, B1=1 …); lpflow_isobufsrc_1 (A with SLEEP=0; SLEEP with A=1, inverting).
- **Three honesty fixes on the way** (each would have silently produced wrong numbers on the new cells): the Liberty
  group is now chosen by (`related_pin`, `timing_sense`) over the WHOLE cell block — a non-unate pin asked without a
  sense is refused, the old code took the first `related_pin` match inside a fixed 60 kB slice (maj3_1's block is
  27 kB and the internal_power groups also say related_pin); the deck's `Xdut` line is ordered by NAME from the
  netlist's own `.subckt` (the PDK's schematic AND magic's extracted netlist), not by an assumed position; tpHL/tpLH
  are measured from the input edge the arc's unateness implies (a non-inverting arc's tpHL starts at the input FALL).
- **Row names** carry the tie between the arrow and the delay kind — `lod3: xor2_1 A→X (B=0) tpHL`,
  `lod3c: … (extracted)` — so `name~tpHL` / `name~tpHL (extracted)` quantifiers still select every row; the two lod-3b
  names are unchanged. Conditions gained `ties`, `timing_sense`, `function`.
- **Numbers (schematic netlist vs the Liberty, same slew/load, 21 arcs)**: every tpHL FASTER than the Liberty (21/21 —
  lod-3b's reading holds); mean |Δ| 14.4 %, max 39.8 % (maj3_1 C tpHL: the deepest internal nodes, the most missing
  parasitics); 4 tpHL rows beyond 25 % are `implemented`, not validated (maj3_1 ×3, xnor2_1 B (A=1) at −27.9 %).
- **Layout (magic DRC · PEX · netgen LVS on all eight `.mag`)**: DRC counts 3–10 per cell, EVERY rule a context rule
  (nwell.4 / LU.2 / LU.3 — three kinds on every cell, zero real rules); LVS "Circuits match uniquely" on all eight;
  PEX capacitors 14 (inv_1) … 58 (maj3_1), device counts == lod-3's per-cell transistor counts (a cross-check
  between magic's extraction and the PDK netlists lod-3 read).
- **The parasitics verdict, corrected by the wider data**: extraction brings tpHL closer to the Liberty on 21/21 arcs
  (mean −20.2 % → −11.3 %: ALL of the fall gap is parasitics-shaped) but tpLH closer on only 11/21 (mean −7.1 % →
  +1.1 %): where the schematic was already SLOWER than the Liberty on the rise (inv, nand2, nor2, isobufsrc SLEEP)
  extraction widens that gap; where it was FASTER (xor2, xnor2, maj3, o21ai, isobufsrc A) it moves toward and
  sometimes past it. Mean |Δ| over the 42 delay numbers 15.0 % → 8.9 %; every extracted row within 25 % (worst
  −23.3 %). The verdict sentence is now COMPUTED from per-arc counts (`closer_after_extraction`), never fixed text;
  it still rejects "parasitics are the sole cause" and names the vendor setup as what remains.
- **Claims (mathproofs)**: the two-cell statement `lod3c-extraction-widens-every-rise-gap` is now REFUTED by the numeric
  tier with a real xor2_1 row as the counterexample — kept, as his vocabulary requires (a refutation is knowledge);
  its restatement `lod3c-extraction-widens-the-rise-gap-where-already-slow` (an `implies`: schematic_delta > 0 ⇒
  delta > schematic_delta) is WITNESSED on all 21; the other four lod claims hold on 21 arcs and their `about_refs`
  name every row. mathproofs holds the 21 arcs as a LITERAL (`LOD3_ARCS`, it must not import computelod — D-pf-4);
  computelod's selftest asserts it equals its own `arcs_of` table. The knowledge node "two independent sources
  agreeing is evidence" cites the new claim and says a refuted two-cell statement is knowledge too.
- **Explain**: the `--cells` hint for lod-3b rows now names the cell (it used to print `sky130_fd_pr`).
- Proof: computelod 100/100 (was 92), mathproofs 83/83, live boot **126/126** (96 CharacterizationMappings — 12 + 42
  schematic + 42 extracted; 16 seeded claims). Committed: the two reports + 16 magic/LVS logs; nothing from the PDK.
- Not done / next on §H.3: lod-4c (Ion/Ioff from the models already run — small), lod-2c, lod-3e, lod-4b, tt-12/13.

### G.28 lod-4c — the process node's OWN numbers RUN BUILT 2026-09-26 (branch `dev-lod-4c` off `dev-lod-3d`; framework + rf-node + suite)

The sky130 SiliconProcessNode row (lod-4) carried only what was READ (L, Vdd, metals). sifet's ladder holds Ion / Ioff / Vt
per rung from documentation (FreePDK45 v1.4); for sky130 the PDK's own BSIM4 cards are on this box (lod-3b), so the numbers
are SIMULATED here, at stated conditions, by sifet's own definitions (`metric_spec`: constant-current Vt = 100 nA × W).

- **`computelod/custom/lod4_devices.py run`**: one DC deck per flavour (nfet_01v8, pfet_01v8_hvt — the two the cells use;
  W = 1 µm, L = 0.15 µm, tt, 25 °C; the p device swept with mirrored biases), two sweeps each (Vds = Vdd and 50 mV),
  `wrdata` → metrics in Python: Ion = Id(Vgs = Vds = Vdd)/W, Ioff = Id(Vgs = 0, Vds = Vdd)/W, Vt_lin / Vt_sat at the
  100 nA × W crossing, DIBL = ΔVt/ΔVds, SS = the shallowest decade between 10× and 1000× Ioff (conservative; stated).
  ngspice through the cntfet engines ladder as before; models cited by sha256, never committed; curves kept decimated.
- **Numbers (tt, 1.8 V)**: nfet_01v8 Ion 502.5 µA/µm · Ioff 2.0 pA/µm · Vt_sat 0.516 V (the card's vth0 is 0.519 — a
  sanity anchor, not a tuning) · Vt_lin 0.603 V · DIBL 49.6 mV/V · SS 92 mV/dec; pfet_01v8_hvt Ion 148.3 µA/µm · Ioff
  2.6 pA/µm · Vt_sat 0.641 V · DIBL 64.6 mV/V · SS 97.7 mV/dec. Beside them, FreePDK45's documented VTG numbers (975.5 /
  10 nA/µm at 1.0 V, 45 nm) FOR THE READING: a 130 nm low-leakage process gives about half the on-current and three to
  four orders of magnitude less leakage — a different rung, not a ranking.
- **Rows**: ten upward CharacterizationMappings fabrication → devices (`lod4c: nfet_01v8 on current` …; characteristics
  on_current / off_current / threshold_voltage / dibl / subthreshold_swing, plain words added to the explainer), evidence
  `simulated`, status `implemented` (a model of the process, not a die); the FreePDK45 value rides in conditions where
  sifet holds one. The sky130 row's `key_numbers_json` GAINS the numbers in sifet's key names + {value, unit, source, note}
  shape (`ion_ua_per_um`, `ioff_na_per_um`, `vt_v`, `dibl_mv_per_v`, `ss_mv_per_dec`, `pmos_*`) — the ladder now reads
  sky130 like its other rungs — and the seed's `_converge` carries `key_numbers_json` onto an instance that already holds
  the row. `GET /api/computelod/lod4/devices`; `/lod4` returns the row's key numbers.
- Proof: computelod 106/106, sifet ladder unchanged, live boot **128/128** (106 CharacterizationMappings).
- Not done: the regular-Vt pfet_01v8 and the lvt flavours (not used by the cells), corner/temperature spread (ss/ff),
  Monte-Carlo mismatch, gate capacitance / fT — each a sweep away, none needed for the adder's story.

### G.29 lod-2c — the two Liberties compared at the SAME conditions BUILT 2026-09-26 (branch `dev-lod-2c` off `dev-lod-4c`)

lod-2 (SKY130: 11.94 ns at 1.8 V / 14.6 fF / 50 ps) and lod-2b (CNT: 41.33 ps at 0.6 V / 41.65 aF / 1.02 ps) were two
numbers under two sets of conditions, never comparable. `computelod/custom/lod2_compare.py run` puts six TWIN cells (same
Boolean function: inv_1↔INVX1, nand2_1↔NAND2X1, nor2_1↔NOR2X1, xor2_1↔XOR2X1, xnor2_1↔XNOR2X1, o21ai_0↔OAI21X1) side by
side under one set of conditions, twice, and refuses what cannot be compared:

- **view `cnt-point`** — both at the CNT library's characterized point (0.6 V · 300 K · 41.654 aF · 1.0178 ps): the CNT
  number is an exact grid point of its Liberty; the SKY130 number is SIMULATED (the lod-3b/3d decks with the conditions
  overridden: an 801 ns window, 2 ps steps — there is no 0.6 V SKY130 Liberty to cross-check). Result: every SKY130 twin
  finished, at 19 ns (inv_1) to 179 ns (xor2_1) — four to five orders slower than the CNT cells, because the hvt p device
  (Vt_sat 0.64 V, lod-4c) is in subthreshold at |Vgs| = 0.6 V. That IS the reading: 0.6 V is not the regime those cells
  were built for; the comparison at the CNT point says so and nothing more.
- **view `own-fo4`** — each library at its OWN nominal Vdd, loaded by four of its own inverter inputs (SKY130 4 × 2.302 fF
  = 9.208 fF; CNT 4 × 10.4 aF = 41.65 aF), driven by the slew its own FO4 inverter produces, iterated twice from a start
  value with every iteration kept (SKY130 50 → 64.0 → 65.1 ps; CNT 1.02 → 1.21 → 1.25 ps). Result: SKY130 inv_1 101 ps vs
  CNT INVX1 1.17 ps; across the six twins the ratio is 58 (nand2) to 135 (o21ai), all one direction. Stated on every row:
  the CNT side is intrinsic-grade (standin parasitics, no layout), the SKY130 side a schematic netlist of a fabricated
  process — a comparison of what each library carries, not a ranking of technologies.
- **view `sky130-liberty-point`** — the SKY130 Liberty at its own point, READ (bilinear), kept beside for the reading.
- **Area REFUSED for the CNT cells**: no layout and no design rules for the aligned-CNT process exist in this instance
  (lod-3's `devices → layout` is UNRESOLVED on that branch); an area from a "layout model" would be an invention. The
  SKY130 areas are the Liberty's.
- **Liberty reading** is generic now (`timing_groups` / `read_point` / `units`): both libraries' units normalised to ps and
  fF, `when`-conditioned groups (the CNT XOR2X1 has four), a point outside the characterized grid is REFUSED, never
  extrapolated (checked: the CNT INVX1 at SKY130's 14.6 fF / 50 ps refuses). The lod-3b deck takes a `cond` override
  (voltage, temperature, load, slew, window) and now `.save`s only the two waveforms it measures (a 400k-point 0.6 V deck was
  KILLED by systemd-oomd while three heavy jobs ran beside it — empty output, no measures; the flow retries once and says
  so; one xor2_1 arc's transition measure is non-monotonic in that regime and is marked unavailable while its delays stand).
- **Rows**: 24 upward CharacterizationMappings devices → standard-cells (`lod2c: sky130 inv_1 FO4`, `lod2c: cnt INVX1
  @cnt-point`, …), each the cell's WORST arc (tpHL/tpLH worst and mean in conditions), its twin, the view and the ratio;
  evidence `simulated`, status `implemented`. Two MathClaims (mathproofs, cited by the two-sources knowledge node):
  `lod2c-cnt-twin-faster-at-own-fo4` (a conjunction of six inequalities over named rows) and
  `lod2c-sky130-twin-slower-at-the-cnt-point` (> 1000× on all six) — WITNESSED at boot, worded as statements about the
  rows and the regime, never about technologies. `GET /api/computelod/lod2/compare` (per-arc detail stays in the file).
- Proof: computelod 115/115, mathproofs 83/83 (18 seeded claims), live boot **129/129** (130 CharacterizationMappings).
- Not done: SKY130 extracted netlists at 0.6 V (lod-3c's PEX at 1.8 V moved delays 5–15 %); the regular-Vt / lvt SKY130
  flavours, which WOULD work at 0.6 V (a different library, sky130_fd_sc_lp/ls — a fetch and a re-run); the CNT library at
  a higher Vdd (its device is derived for 0.6 V — a re-derivation, not a knob).

### G.30 lod-3e — the WHOLE adder placed and routed BUILT 2026-09-26 (branch `dev-lod-3e` off `dev-lod-2c`; framework + rf-node + suite; eda-tools LICENSES)

The layout rung entered for the whole design, not a cell at a time. Sized "medium-large" for an OpenROAD source build; the
build was not needed: OpenROAD publishes its flow image (`openroad/orfs`, updated daily; pinned here at tag
`26Q3-651-gbc334a4aa`, digest recorded in the report), Ubuntu 22.04-based, 4.6 GB, carrying OpenROAD (BSD-3), ORFS
(BSD-3), yosys (ISC), the sky130hd platform files (Apache-2.0) and two GPL tools we never invoke — audited in
`polari-eda-tools/LICENSES.md` as a SECOND engine image, used as published, never rebuilt.

- **Engines seam** (`eda_engines.py`): engines `orfs` (= `make` inside the ORFS image, its tools first on the PATH — what
  its env.sh does) and `openroad`; ORFS_ENGINES resolve ONLY through the pinned image or a worker that carries it — the
  host's `make` and the eda-tools image's `make` are refused by construction (a resolve rung that would have "found" the
  wrong binary); `POLARI_ORFS_IMAGE` knob; `orfs_image_digest()`; placement lists `ladder_orfs`. The eda-tools worker's
  capability does not claim it (its table has no `orfs`), so remotely it refuses honestly.
- **`computelod/custom/lod3_pnr.py run`**: lod-2's OWN mapped netlist (rv32_add_sky130.v, 96 cells, 855.82 µm², sha256)
  in; OUR cached Liberty handed to the flow as LIB_FILES (byte-identical to lod-2's timing model; the LEF/GDS are the
  image's platform copy); a virtual 10 ns clock SDC (combinational design — the I/O paths must be constrained for the
  flow to report them; no setup violation is asked for). Two variants, because a physical flow does not leave a netlist
  alone: `as-flow` (ORFS defaults) and `cells-kept` (every switchable repair off: SKIP_CTS_REPAIR_TIMING,
  SKIP_INCREMENTAL_REPAIR, SKIP_LAST_GASP, DONT_BUFFER_PORTS, SKIP_GATE_CLONING, SKIP_PIN_SWAP, SKIP_BUFFER_REMOVAL).
  Knobs stated with why: CORE_UTILIZATION 20 % (40 % failed placement at 108 % once the flow had buffered and resized),
  LEC_CHECK 0 (the image's equivalence checker dies with an illegal instruction on this CPU).
- **What the flow did** (counted, not hidden — the census of the routed netlist against the input): in BOTH variants it
  resized the carry chain maj3_1 → maj3_2 (29 cells) and a few others (the floorplan-stage repair_design is not
  switchable — said so); as-flow buffered every port and repaired hold: 146 buffers/delay cells, 292 std cells, 50 taps,
  332 fill, 3002 µm wire, 1186 vias, core utilization 57 %; cells-kept: 17 buffers, 163 std cells, 1680 µm wire.
  Router DRC 0 on both (its own count; magic's full-rule DRC of the merged GDS is NOT run — the cell-level lod-3c check
  stands for the cells). The flow's own setup check: as-flow met, cells-kept MISSED the 10 ns clock by 0.06 ns (10.06 ns)
  — exactly what the repairs the other variant runs would have fixed.
- **Timing under lod-2's exact conditions** (OpenSTA, 1.8 V / 14.6 fF / 50 ps), the routed netlist WITH its SPEF and the
  same netlist WITHOUT it: as-flow 9.8057 vs 9.5826 ns → **the wires cost 0.223 ns, 2.3 %**; cells-kept 10.0593 vs
  9.8213 → 0.238 ns, 2.4 %. One subtraction, the netlist held fixed. Both routed numbers beat lod-2's 11.94 ns netlist
  ONLY because the flow resized the carry chain — stated on the row (`vs_lod2_note`); that difference is sizing + wires,
  never called the wire cost.
- **Rows**: two ComputeMappings `lod3e: adder cells → placed-and-routed layout (<variant>)` (standard-cells → layout,
  MEASURED — the router's DRC and the flow's metrics are tool output; validated; `loss_note` counts the resizing and
  buffers); twelve upward characterizations (per variant: routed delay with parasitics · wire delay cost · core area — a
  knob's consequence, status `implemented`, said so · wirelength · routing DRC violations · instances after P&R). One
  MathClaim `lod3e-wires-add-delay-on-the-routed-adder` (with > without, both variants) WITNESSED; cited by the
  two-sources knowledge node. `GET /api/computelod/lod3/pnr`. Plain words for wire_delay / wirelength / drc_violations.
- **Committed (ours, ~0.5 MB per variant)**: 6_final.v, 6_final.spef, 6_final.def, 6_report.json, 6_finish.rpt,
  5_route_drc.rpt, synth_stat.txt, our two OpenSTA logs, config.mk, constraint.sdc, the placement image. NOT committed:
  the GDS/ODB (they merge the PDK's cell layouts) and the 680 kB routing image (regenerable).
- Proof: computelod 124/124, mathproofs 83/83 (19 seeded claims), live boot **131/131** (16 ComputeMappings, 142
  CharacterizationMappings).
- Not done: magic DRC/LVS of the routed GDS (the merged GDS holds PDK cells — run, not committed; a flow away); the
  routed design's power (the flow reports an estimate under default activity — not a row until the activity is stated);
  the eda-tools WORKER carrying ORFS (a device that wants the flow pulls the image; a worker built FROM the ORFS image is
  the natural next step); walking the ladder past `layout` with the routed design (lod-4b, process rows).

### G.31 lod-4b — fabrication as ROWS BUILT 2026-09-26 (branch `dev-lod-4b` off `dev-lod-3e`; framework + rf-node + suite)

The last lod slice of §H.3. lod-4 had entered fabrication → materials by reference (sky130 → eg-si) and named the rest as
not modelled. `computelod/custom/lod4_steps.py run` (a reading — nothing fetched at run time; the citations are in the
report) writes the route down in PSPP's own vocabulary, the two classes the concept tree already named for the rung
(`ProcessingStage`, `MaterialProcessDefinition` — the "decision on which PSPP classes" was taken as the routine one), and
is exact about what each row rests on:

- **What the PDK publishes, and what it does not.** The docs give the LAYER STACK — every drawing layer with its purpose
  (dnwell, nwell, diff, tap, poly, nsdm/psdm, rpm, hvtp, lvtn, hvi, npc, licon1, li1, mcon, met1–met5, via–via4, nsm, pad —
  26 layers, quoted verbatim from `rules/layers.html`, read 2026-09-26), the design rules, the device models, and the
  README's stack description ("1 level of local interconnect · 5 levels of metal · …", quoted). They do NOT give
  SkyWater's recipe: temperatures, doses, gas chemistries, which isolation (LOCOS/STI), which metals (Al/Cu), plugs and
  barriers. Every SKY130 row says so (`NOT_HERE`).
- **8 SKY130 ProcessingStage rows** (family `silicon-cmos-sky130`), a chain of wafer states the documented layers imply:
  eg-si wafer → wells → active (isolation) → gate stack (two oxides: 1.8 V core and `hvi` 5 V; Vt implants hvtp/lvtn — the
  stack lod-4c's models describe: toxe 4.148 nm, vth0 0.519 V) → source/drain (+ the rpm resistor implant) → contacts +
  local interconnect → five metals + vias → passivated die. Each names its PDK layers (quoted), the materials it ADDS (Si,
  SiO2, poly-Si, B/P/As, Si3N4, W plugs, Al/Cu, TiN — NAMES, not material rows: those would need their own sources) and the
  unit processes it takes; every documented layer sits on exactly one stage (asserted).
- **8 SKY130 MaterialProcessDefinition rows**, all declared TRANSFORMATIVE (PSPP invariant I2 — declared, never inferred):
  photolithography (patterning), ion implantation (doping), thermal oxidation (film-growth, conventional heating), CVD
  deposition, plasma etch (removal, rf), metallization, CMP (planarization), anneal (heating). These are the textbook CMOS
  operations the layers require, cited to Plummer, Deal & Griffin, "Silicon VLSI Technology" (Prentice Hall 2000) —
  evidence `analytical`; `parameter_schema_json` says the recipe parameters are the foundry's, none published.
- **The CNT branch mapped the same way, by reference**: 6 stages (purified s-SWCNT solution → aligned film → placed channel
  → contacts → gate stack → patterned device) and 6 unit processes (family `aligned-cnt`), each naming the cntfet
  `cnt_process` row that carries its parameters, source and confidence (s1-target-purification [HIL19] …, the rest
  "engineering prior — TUNABLE") — the numbers stay on cntfet's rows; the PSPP rows say where they are. The branch's gap
  remains LAYOUT (lod-3), not process.
- **Mappings**: `lod4: fabrication → materials` REPLACED by name (the route as rows, the stack's materials named in the
  target, the recipe as `loss_note`); `lod4b-cnt: fabrication → materials` ADDED with status `proposed` (no line has made
  these devices here; the cntfet rows say TUNABLE). 17 ComputeMappings on a boot.
- **Seeding**: the PSPP rows ride computelod's seed pairs (guarded on pspp; prefixes sky130-/cnt- never collide with pspp's
  own seeds; description/notes/provenance converge onto an instance that already holds them). `GET /api/computelod/
  lod4/steps` returns the report and the LIVE rows from pspp's tables. Explain flows `lod4b` / `lod4b-cnt`.
- Proof: computelod 132/132, live boot **133/133** (17 ComputeMappings; 14 + 14 PSPP rows live).
- Not done / honest limits: the materials as ROWS (a materials-science source per film; a slice of its own); the process
  as MaterialState transitions with executions (PSPP's execution machinery — the definitions are there, no execution rows:
  nothing was run); the CNT branch's stages are as unmeasured as cntfet's priors.

### G.32 tt-12 + tt-13 — the scene inside the node detail; discovery across trees with the units filter BUILT 2026-09-26 (branch `dev-tt-12` off `dev-lod-4b`; framework + angular + rf-node + suite)

The two small non-lod rows of §H.3, closing the table.

- **tt-12 (Angular only)** — `tensor-tree-panel` hosts the existing `sim-space-viewer` (never a new renderer) inside the
  selected node's detail: a `scene` row shows the node's `sim_space` (the tree view already carried it per node since bp-2a)
  with a "show the scene here" door; a click renders `<sim-space-viewer [simSpaceName]=node.sim_space hideRunPanel
  clickNavigates=false>` in a 340 px host — a WebGL scene is heavy, so it opens on a click and stays open across node picks
  (the input changes, the scene follows). The page's ONE configured viewer still follows the tree SCOPE (his bp-2 rule);
  this one follows the clicked node — the "visualize" step of select → discover → follow without leaving the panel. A node
  with a binding but no `sim_space` says so instead of guessing a scene. Cross-tree candidates (tt-13) show a `cross-tree ·
  written for <node>` pill whose tooltip is the why. tsc clean; UNSEEN in a browser until the images rebuild (his pass).
- **tt-13 (tensortree only)** — `tensortree_discover.discover` gained the §F3 units filter and, with it, discovery ACROSS
  trees: a mapping written for ANOTHER node is a candidate on this selection when every dim it needs exists here by name AND
  by unit. `node_dim_units(manager, node)` reads a node's units through its LocalizedDimensions → the tensor's
  TensorDimension rows or `dimensions_json` (`''` when nothing is recorded). The filter is HARD and honest three ways: same
  name, different unit → `inapplicable` kind `units-incompatible` ("x is m here, mm there"); no unit recorded on either side →
  `inapplicable` kind `units-unknown` naming the silent side — compatibility is never assumed; dims not all present → simply
  not a candidate (no refusal row per foreign mapping). Survivors pass the same validity and obligation filters, score with
  the configured policy and a LOWER context term (C = 0.25 — a mapping written for another node, said so in `terms`), and
  carry `cross_tree`, `source_node`, `units` and `why_here`; the answer adds `cross_tree_candidates` and `units_here`.
  Own-node candidates are unchanged (their tensor is the selection's). Proof: tensortree selftest (a second tree with a
  matching node, a mm node and a unit-less node — one candidate, two inapplicables with the right words), live boot 134/134.
- Not done: a units CONVERSION (m ↔ mm) — the filter refuses, it does not convert (a conversion would be a mapping of its
  own, with evidence); the seeded trees share no cross-tree candidates today (plate has no z; the wind mappings need it) —
  the door is open, the data has not walked through it yet.

### G.33 The REPRODUCIBILITY pass — his rule 2026-09-26 (branch `dev-repro` off `dev-tt-12`; framework + rf-node + suite)

**His words:** "the main thing we should focus on keeping is the initial conditions and seeds used so it is reproducible, in
addition to the results." Saved as a standing rule (memory `reproducible-initial-conditions`). What it became:

- **`computelod/custom/repro.py`** — ONE shape for every committed report, `reproduction`: `inputs` (every file read, by
  sha256; a cached PDK/Liberty file by url + sha256), `tools` (the version line of every engine THROUGH the engines ladder —
  the binary that ran, wherever it ran — plus the ids / registry digests of the pinned images), `knobs`, `conditions`,
  `generated_files` (the decks, configs, Tcl and netlists the flow WROTE, copied beside the report and hashed — the exact
  text the tool consumed), `seeds` ({name: value} for every random element, or `deterministic: true` with WHY), `recorded_at`,
  `host`, `how_to_rerun`; `attached_after_the_fact` marks a block computed from committed artefacts for a flow not re-run.
  `complete()` checks a block; `check` walks every report; the explainer's "how to reproduce" points at the block.
- **Every flow attaches it in `run()`** — lod-1, lod-2, lod-3, lod-3b/3d (21 decks now committed under
  `initialData/lod3/decks/lod3b`), lod-3c (its re-timing decks; the PEX netlists they include stay out of git — PDK-derived —
  and are cited by sha256), lod-4, lod-4b, lod-4c (decks), lod-2c (the 0.6 V and FO4 decks), lod-3e (config.mk, SDC, DEF,
  SPEF, netlist hashed; the three ORFS seed knobs GPL_RANDOM_SEED / GRT_SEED / OR_SEED recorded explicitly as the defaults
  this run used — a seed is never implicit). Two reports not re-run got theirs `attached_after_the_fact`: lod-2b (the CNT
  characterization of 2026-09-24: the Liberty it wrote is committed and hashed; no Monte Carlo — stated) and the tensormath
  FPGA kernel (needs a live manager; nextpnr's default seed 1 named as THE seed).
- **Re-running as the test**: lod-1, lod-2, lod-4c, lod-2c and lod-3e reproduced their previous numbers exactly (lod-1's
  and lod-2's generated files byte-identical; lod-3e's DEF and netlist identical, the SPEF differing in its *DATE line only).
  Two findings: (1) lod-3b/3d — adding `.save v(a_in) v(y)` to the decks (to survive oomd beside other jobs) moved TWO of 42
  arc delays by 0.01 ps (ngspice's adaptive timestep sees a different deck): the committed decks are now the ones to
  reproduce, said so; (2) lod-3c — the extracted netlists hashed differently between the morning and the afternoon run while
  every device/capacitor count and every timing agreed to 0.01 ps: magic's `extract` REUSES an .ext newer than the .mag, and
  the work dir still held 2026-09-24's; immediate repeats from a clean dir are byte-identical (checked twice on inv_1), so
  the flow now starts every cell from a clean extraction. Both are exactly what the rule is for.
- **Selftests**: computelod asserts every committed report's block is complete (12 reports), the 21 decks exist and are
  hashed, lod-3e's seeds are explicit, lod-2b's block says it was attached after the fact; tensormath asserts the FPGA block.
- Proof: computelod 138/138, tensormath 68/68, live boot 137/137. `python3 -m computelod.custom.repro check`.

### G.34 D5 — PyTorch as the THIRD ComputeImplementation BUILT 2026-09-26 (branch `dev-d5` off `dev-repro`; framework + rf-node + suite; his word)

The bridge of §F8 gains its third row: the SAME operator (σ = C:ε, `stress-from-strain`) beside numpy einsum and the FPGA MAC.
Built the Polari way — the module never assumes a device (his 2026-09-24 rule), so torch is an ENGINE:

- **`tensormath/custom/torch_engine.py`** — the ladder: `TORCH_ENGINES_URL` → that worker, always (unreachable = refusal);
  `import torch` in the framework process; the topology provider `tensormath.engines` (`pol allocate tensormath.engines
  <instance>`); refusal naming both knobs. `evaluate()` runs `torch.einsum` on the SAME operands and the SAME contraction spec
  the numpy path derives, compares to numpy (the reference; `error_vs_numpy` = max relative), records how/where/version/
  device/threads; `torch.use_deterministic_algorithms(True)` on both rungs. `placement()` → `GET /api/tensormath/engines`.
- **The worker — its own submodule `polari-rf-node/polari-torch-tools` (his word 2026-09-26: "it should be its own module"; public repo dausume/polari-torch-tools, default branch dev)** (python:3.12-slim-bookworm + `torch==2.14.0+cpu` from the PyTorch CPU index,
  1.0 GB image; `/capability`, `/system-info`, `/evaluate` — einsum ONLY, operand size capped; `docker-compose.torch-engines.yml`
  :9820 on `polari-link`; LICENSES.md: PyTorch BSD-3-Clause; image `polari-torch-tools:bookworm`). The framework image is Alpine/musl and has no torch wheel — as
  with z3 — so the worker IS the normal way on the node stack. The same shape as eda-tools / proof-tools.
- **Row + benchmark**: `stress-from-strain/torch` seeded with NO number (evidence none, latency 0; target_ref names the
  knob and worker); `POST /api/tensormath/benchmark {"implementation": "stress-from-strain/torch"}` runs it where the ladder
  resolves — the row becomes MEASURED with latency/throughput/error and an evidence_ref recording torch's version, device,
  threads, engine placement, n, repeats, median/min/max (the reproduction record of that number); with no engine anywhere
  it is a 422 naming both knobs and the row stays evidence none. Manifest `requires.engines` gains `torch` (optional, knob,
  worker named).
- **Proof**: tensormath 68/68 (a stand-in torch exercises the local rung and the comparison without torch installed; the
  refusal wording; a declared-but-unreachable worker refuses); live boot 137/137 in BOTH modes — with the worker declared
  (benchmark MEASURED through it: torch 2.14.0+cpu, 4 threads, error vs numpy < 1e-9) and without (422). The worker runs
  on pol-core now (`prf-torch-engines`, compose project `torch-engines`).
- Not done: a topology ModuleAssignment row for `tensormath.engines` (the provider rung is code-complete, no instance
  assigned); GPU (a torch device is a knob of the worker, none here); torch for the non-contraction operations (reduce /
  norm / permute stay numpy — stated by the refusal).

### H.4 bp-2 — his second browser pass, from a phone (2026-09-25 evening): seven asks, one branch `dev-bp-2`

His words, and what each became (built the same evening; verification below once the images are rolled):

1. **"tensortree seems to be showing all simspaces and all rows in all tables … that selection should propagate to
   all of the configured tables via configuration … ideally using a configuration and no-code events for frontend"**
   → a page SCOPE set by frontend display events. The tree panel gained `scopeKey`; picking a tree dispatches
   `setScope` {key: 'tree', value, facets: {nodes, sim_space}} on the existing DisplayEventsService; the display
   page keeps a scope map and re-substitutes every `{scope:tree}` / `{scope:tree.nodes}` / `{scope:tree.sim_space}`
   placeholder in the configured items' inputs and titles (the same pass that substitutes `{object}`), re-rendering
   the page; a repeat of the current scope is ignored (no loop when the re-created panel re-announces). The
   tensortree page seed is now written in those placeholders: nodes / unresolved filter `tree`, dims / mappings /
   selections filter by the tree's node SET (`class-rows-table` treats a csv `filterValue` as membership), the ONE
   sim-space viewer shows `{scope:tree.sim_space}` (the view now carries each node's `sim_space` from
   `global_params_json`); policy and couplings stay global and say so. No page code, no new component.
2. **"the login and register buttons do not seem to be triggering"** — from the desktop the button redirects to the
   realm (seen in Chrome); the phone symptom is the realm's dev certificate not being trusted there, so the OIDC
   client's discovery fetch fails BEFORE any redirect and the failure went to the console only. Now `login()` /
   `register()` return false on that failure and the header shows a snackbar naming the realm host, why, and an
   "Open it" action (accept the certificate once, retry).
3. **"the failing to retrieve files error is not particularly user friendly"** → `friendly-error.ts`: one wording
   for every panel (401 "Sign in to see this." with a Sign in button; 403; 404; 503; unreachable; 5xx), the
   technical detail in the tooltip. Used by `api-structured-panel`, `class-rows-table`, the object page.
4. **"many fields are not fully readable, I would like to enable wrapping … configured tables … either wrapped or
   enabled wrapping or allows clicking on to expand"** → `class-rows-table` cells wrap; a long cell is clamped to
   three lines with a more/less toggle; headers read as words (`about refs`, not `about_refs_json`).
5. **"for a number of things you are directly showing json. We should define these as one kind of object or
   another … references to names of mapping or other critical objects, we should be able to click on them and see
   object detail views … auto-defining generic detail views"** → (a) `*_json` columns render as key/value lines
   (lists as values, objects as pairs) — never a JSON string; (b) column formats `ref:<Class>` (a name column) and
   `refs` (a list of "Class:name") render LINKS; (c) `/object/:class/:name` — the GENERIC detail view of any row,
   auto-defined from the row: the class in plain words, the row's interconnects as chips (every "Class:name",
   every `*_refs_json`, the well-known name columns), the record through `structured-payload-panel` with JSON
   fields parsed, a link to the class page where a configured instance display refines it. The tensortree and
   mathproofs seeds carry the formats (nodes, mappings, claims, obligations, rules, runs).
6. **"description sections that are toward the average person in most of these kinds of objects"** → the words
   live ON the class: a `plain_words` attribute on 23 classes (tensortree 7, mathproofs 5, tensormath 7,
   computelod 5); one core door `GET /api/plain?classes=…` reads them (docstring first paragraph as the flagged
   fallback); each of the four pages opens with an "In plain words" `api-structured-panel` on that door; the object
   page shows its class's paragraph.
7. **"find academic sources establishing proof types are valid if we can and cite them using our currently existing
   citation methods"** → `ProofMethodReference` (mathproofs): the suite's existing citation shape (EvidenceItem's
   fields — kind, title, parties, ref, date, url, proves, citation_key, verified, verified_via), 13 rows: Dijkstra
   1972 and QuickCheck 2000 (a witness is not a proof), Moore–Kearfott–Cloud 2009 (interval arithmetic is exact set
   arithmetic), Meurer 2017 + Richardson 1968 (symbolic checking and its undecidability limit), de Moura–Bjørner
   2008 + Kroening–Strichman 2016 (SMT decides; a model is a counterexample; bit-vectors), de Moura 2015 / de
   Moura–Ullrich 2021 / mathlib 2020 / Barendregt–Wiedijk 2005 (machine-checked proof, the de Bruijn criterion),
   Kleene 1952 (three-valued logic = undetermined), Lakatos 1976 (refutation by counterexample). `verified=True`
   only where the DOI resolved through Crossref on 2026-09-25 and title/authors/venue read back (11 of 13; Kleene
   is print-only, Lakatos read from Cambridge Core); `proves` names the tier / vocabulary word. A "Sources" table
   closes the mathproofs page (url as a link).

### H.5 bp-3 — every row explained (his ask 2026-09-25 night, same evening): "source ref and other refs and conditions
don't really make coherent sense to me … Per row we likely need a human explainable row and an understanding of what
was done and how to duplicate it"

Built the same night on `dev-bp-2`:
- **One door, `GET /api/explain?class=&name=`** (`polariApiServer/explainAPI.py`): for one row — `in one sentence`,
  `what was done`, `inputs` (the things it was done to / under, conditions in words), `result`, `how to reproduce`
  (the exact commands / API calls), `evidence`, `how far to trust it` (the evidence level in words), `related`.
- **A module explains its own rows**: `<module>/custom/explain.py` exports `EXPLAINERS = {Class: fn(manager, row)}`.
  Written for computelod (CharacterizationMapping — the flow by name prefix lod1 / lod2 / lod2-cnt / lod3 / lod3b /
  lod3-cnt / lod3c → `python3 -m computelod.custom.<flow> run`, the report file, the API walk; ComputeMapping),
  mathproofs (MathClaim, ProofRun, ProofObligation, ProofMethodReference — the vocabulary word spelled out and
  `POST /api/mathproofs/claims/{name}/check?tier=`), tensortree (TensorMapping, TensorNode). Every other class gets
  the GENERIC account: each field as a sentence labelled by the comment the class source carries beside it
  (`self.method = method  # OpenSTA | ngspice | …`) — so no bare column name ever explains itself.
- **The object page shows it first**: /object/:class/:name opens with the sentence, then What was done · With what ·
  Result · How far to trust it · Evidence · How to reproduce it (a code block), then the connected objects and the
  record. Every `name` column on the computelod and tensormath tables now links there too (formats `name:ref:<Class>`,
  rungs as `ref:ComputeLOD`).

### H.1 RESULTS — the browser pass RUN 2026-09-25 (Chrome via the extension; the node stack on the home swarm)

Bring-up (from a stripped checkout): `pol swarm init` (needs `LOCAL_IP` on pol-core), `pol security setup dev` +
`POLARI_ROTATE_KC=no pol security node-setup staging`, `pol swarm render node` with `POLARI_MODULES` exported (the core
is down: nothing to derive from), the images built, the stack deployed from `.generated/stack-node-nofs.yml` — the
file store REMOVED because **`minio/minio` no longer exists on Docker Hub** (the whole repository; quay too) so
`prf-file-store` cannot build anywhere — his decision (SeaweedFS / RustFS Apache-2.0; Garage AGPL); the backend's
`ca/root_ca.crt` bind = the proxy CA (`install -D prf-proxy/certs/ca/prf-ca.crt ca/root_ca.crt`); the proxy's
file-store upstreams pointed at loopback for the pass (nginx refuses to start on an unresolvable upstream). Chrome
trusts the dev CA through the user NSS store (`certutil -A -n "Polari Dev CA (staging pass)"`) — Chrome only reads
it at start. Display pages need no login.

**What read TRUE on screen** (every row of §H.1 that is not listed below as a gap):
- `/display/tensortree`: three chips with counts (2/2 · 1/1 · 3/4); wind-grid solid, slice solid, turbulence dashed
  "unresolved · semantic"; the three arcs (blue restriction ✓, coupling to the "→ pendulum-bob (another tree)" stub,
  grey dashed decomposition ∅); click wind-grid → tensor/binding, dims → channels (x/y/z → position, speed → color
  0–12 m/s, component → vector), the gust-corner selection prefilled; discover → ranked candidates with score bars,
  "not defined on this selection" list with the reason; **the `propose` door** → `valid-on-selection: decided` inline;
  the mappings list with badges and **the `claim` door** → the editor in the palette shape: about prefilled, the
  palette buttons render their glyphs and INSERT the term snippets (tooltip says what it inserts), the preview renders
  the backend-derived LaTeX with `TIER: Z3` and the hash, "Write the claim and check it" → `holds (z3) → decided`
  shown before closing (claim `pass-slice-z-within-band` now exists on that instance). Plate tree: root resolved
  4 dims, u and mesh resolved, ε unresolved (no localized dims — as seeded). The plate scene: 2 m × 1 m, 64 coloured
  triangles (green at the fixed edge, one red corner cell, yellow elsewhere), mesh edges, displacement lines growing
  to the right; hover = a tooltip. Tables: nodes, spaces, dims, mappings, selections, policy — configured, no JSON walls.
- `/display/mathproofs`: the claims table with the **LaTeX column rendered** (KaTeX), statuses/checkers/evidence;
  `/display/tensormath`: tensors, dims, expressions, operators, the TWO implementations, the FEM field row, the plate
  scene; `/display/computelod`: the eleven rungs, the walk from `c = a + b` through all eleven, mappings and
  characterizations; `/tech-tree`: the `tensor-proofs` tree listed and drawn (ten nodes).

**Gaps found and FIXED in the same pass** (all on `dev-pf-3`, re-verified after the rebuild — see below):
1. Panel: the dim chips and the SELECT form were keyed by the tensor dimension's name (`wind-field.wind-speed` →
   `wind-speed`; `tt2-sigma`, `xy`, `triangles`) instead of the LocalizedDimension's own short name (`speed`, `x`,
   `y`, `sigma`, `element`) — so discovery from the form could not see `speed` and the drag coupling read as
   "not defined on this selection". Rows were right; `shortDim(d.name)` now.
2. Badge: a template-less rule's `unprovable-here` (units-compose) outranked seven positive results on the plate's
   operator arcs — all showed `?`. New state **`gap` ◐** = every checkable obligation ok, the rest named gaps.
3. Summary panels on four module pages said "'a,b,c' is not in this payload": `_sapi(pick='by_status,aggregate,
   tiers')` — the structured panel took `pick` as ONE dot-path. It now takes a comma list as a subset of keys.
4. Derived LaTeX rendered names as math italics (`wind − grid → spectrum`, `rv32_addlayoutarea`): `to_latex` wraps
   row / set / dim names in `\text{}` (→, σ, ε mapped).
5. The plate tooltip showed id + position only: it now shows the cell's field value first (`σ_vm = … Pa`, the colour
   domain) — the backend already carried `userData.scalar/unit/field/domain`.
6. Login was broken in staging: the proxy cert's SAN lacked `auth.prf.<ip>.nip.io` → the browser's check-sso fetch
   failed TLS (`[AuthSession] check-sso redirect could not start`). `staging-setup.sh` SAN lists carry it now; cert
   regenerated under the same CA.
7. The wind scene carried "Class WaxPrintSimState / MoldFillSimState bound (3D) but has no instances" — other
   modules' defaultVisible 3-D bindings; `compile_3d` warns only for classes THIS scene binds.
8. The `tensor-proofs` tree evaluated its claims as MODULES ("module sigma-symmetry… has no ModuleAssignment", 20 false
   gaps, 0 %): the techtree gained a **`proof` segment kind** (done ⇔ the MathClaim is settled — holds, or refuted with
   a counterexample — read through mathproofs' status by a soft seam), the knowledge seeds use it, the payload's
   colours carry it (green).
9. Node labels truncated at 24 chars in 150-px boxes → 200 px, 32 chars with an ellipsis. Verdict-card title contrast.
10. The seed-field gotcha, met live: the first boot's rows (the `theory` segments, the old `\mathrm` LaTeX) survived the
    image roll because the core seed pass is insert-by-name. DERIVED data now converges on every boot in
    `mathproofs/custom/boot.py`: the knowledge tree's techtree rows go through `upsert_seed_pairs`, and every claim's
    `statement_latex` is re-derived from its term (never authored, so overwriting is the truth).

**Re-verified in the browser after the rebuild:** the select form keyed by `speed` and discovery from the panel ranking
`wind-grid→bob-drag` first (0.86, validated) as §H.1 expected; the plate arcs ◐ (`gap`) through `/view`; the summary
panels rendering Tiers / BY STATUS / AGGREGATE; the LaTeX column with names as text (`validity:wind-grid→bob-drag`);
the plate tooltip `von Mises = 1.00e+6 Pa (colour 8.00e+5–1.10e+6 Pa)`; the wind scene without the foreign-class
warnings; the `tensor-proofs` tree at **63 %** with `Proof` segments (fixed point 3/3, two sources 5/5, …) and exactly
three gaps, each naming its door (the two Lean theorems → `?tier=lean`, the decomposition's undetermined claim); the
auth host verifying under the CA (check-sso no longer fails). Not exercised: a login (the realm allows
self-registration, but entering credentials is not mine to do).

**Gaps left as they are (named):** the 2-D viewer has no wheel zoom (the page scrolls), so the units=space scaling
test could not be made from the browser (the triangles ARE drawn in space units — they sit on the axes' metres);
wind arrows are absent at t = 0 (calm by construction, the tt-10 finding — playback not exercised); the renderer
stalls for seconds on pages with a 3-D scene AND on the KaTeX-heavy mathproofs table (captures time out until it
settles) — a viewer performance note; the TensorNode table's `status` column reads `unresolved` for nodes the
validator resolves — the validator computes status per read and does not write it back (a small honesty gap to
decide: persist, or drop the column from the table). Proof after the fixes: mathproofs 83/83, techtree 75/75,
tensortree 64/64, tsc clean, live boot 126/126 (re-run after the last change — see the commit).
