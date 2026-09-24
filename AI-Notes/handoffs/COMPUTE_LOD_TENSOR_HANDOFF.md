# Handoff — the Compute LOD + Tensor arc (2026-09-23): what is built, how to prove it, what is owed

_Plan of record: `AI-Notes/plans/COMPUTE_LOD_TENSOR_PLAN.md` (three rounds with ChatGPT, relayed by Dustin; D1–D7
ratified 2026-09-23; §G.1–G.7 are the build status). Branch `dev-tt-0` in the suite, `polari-rf-node` and
`polari-framework` — UNMERGED, per branch-per-confirmed-phase; merge on his word._

## The one-line map

    tensormath   Tensor (values BY REFERENCE: matrix | dataset | engine | claim) · TensorDimension · TensorMathExpression
                 (named-dim contract/outer/reduce/norm/permute/slice; rank ≤ 2 delegates to matrices/) · TensorOperator ·
                 ComputeImplementation (the bridge) · TensorDecomposition
    tensortree   TensorTreeDefinition · TensorNode (validity LOCAL) · UnresolvedTensorSpace (typed) · LocalizedDimension
                 (eleven channels) · TensorMapping (one class, kind, two statuses) · TensorSelection · TensorDiscoveryPolicy
    computelod   ComputeLOD (eleven rungs; design_level_ref into the microchip ladder) · ComputeKind (70) · ComputeMapping
                 (down) · CharacterizationMapping (up, conditions load-bearing) · CompilerArtifact

## Prove it in ten minutes

    cd polari-rf-node/polari-framework
    PYTHONPATH=.:modules python3 modules/tensormath/tensormath_selftest.py      # 49
    PYTHONPATH=.:modules python3 modules/tensortree/tensortree_selftest.py      # 51
    PYTHONPATH=.:modules python3 modules/computelod/computelod_selftest.py      # 54
    mkdir -p /tmp/tt && cd /tmp/tt && rm -rf data && PYTHONPATH=<fw>:<fw>/modules python3 <fw>/tests/tensor_liveboot_probe.py   # 60/60 on a REAL boot
    # re-run the tool chains (docker; nothing installed on the host):
    docker build -t polari-computelod-tools:noble modules/computelod/custom/tools     # gcc-riscv64 13.2 · yosys 0.33 · verilator · iverilog · nextpnr-ice40 · icestorm
    docker pull openroad/opensta
    PYTHONPATH=.:modules python3 -m computelod.custom.lod1_chain run              # c=a+b → gcc → add → picorv32 → yosys → iverilog
    PYTHONPATH=.:modules python3 -m computelod.custom.lod2_silicon run            # SKY130 abc mapping + OpenSTA (Liberty cached in ~/.cache/polari-lod)
    # the FPGA kernel needs a manager (see the tensormath selftest's fpga block or the probe)

Live surfaces: `/api/tensormath` (+ evaluate, operators/{name}, benchmark), `/api/tensortree` (+ trees/{name}
/graph /validate, select, discover, scale/{material} [/materialise]), `/api/computelod` (+ rungs/{name},
walk/{rung}/{ref}, path?rung=&ref=, lod1, lod2); pages `/display/tensormath|tensortree|computelod`.

## What each slice proved (the honest parts are the point)

- **tt-0** the ontology; found + fixed: dep-0/1's DeployTarget/DeployRecord were missing from defClassList.
- **tt-1** `wind-field` (the wind→pendulum grid, read live) with a RESOLVED root bound to the proven
  `WindFieldGridState-3d` binding; select → discover ranks the REAL coupling first and refuses a calm-only
  hypothesis. D3 substitution stated: WaxPrintSimState is per-step scalars, not a spatial field.
- **lod-1** `c = a + b` → `add a0,a0,a1` = 0x00b50533 → PicoRV32 :1068/:1231 → rv32_add.v → 220 gates (core
  8126) → iverilog RTL == netlist. Two gaps left on purpose.
- **tt-2** σ = C:ε by named contraction == the FEM engine's σ (rtol 1e-9), E/ν from a CITED material option;
  the plate tree's root UNRESOLVED honestly (no binding for element fields).
- **tt-3** the same operator on an iCE40 HX8K: the streaming form did NOT fit (49k LUT4 vs 7,680 — kept as the
  lesson); the time-multiplexed one does (4,185 LCs, 32.3 MHz, 17 cycles/element); numpy measured on the node
  by `POST /api/tensormath/benchmark`. Two implementations, each with the evidence it actually has.
- **tt-4** a material's scale tree as a READING of msci levels + pspp ScaleTransferDefinition (by reference);
  materialise on a person's action. Paraffin wax: L0→L1, L0→L4 executed.
- **lod-2** SKY130 HD (cited, pinned, never committed): 96 cells, 855.8 µm², OpenSTA 11.94 ns worst path with
  conditions named; lod-1's gaps closed by name; cells → devices stated partial.

## Rules learned (also in memory)

- A new module wires into: manifest (`files.api` AND `files.endpoints`) → `feature_imports` → polariServer
  defClassList + seed pairs + page displays → `module_endpoints` (+ registry dict) → `polari-modules.json` →
  `FEATURE_MODULES`/`FEATURE_REQUIRES` (module_loading.py) → `app_taxonomy.DEFAULTS`. Only `objects/`, `custom/`,
  `initialData/` subdirectories. CRUDE writes = multipart `initParamSets`; routes are `/<Class>`.
- The live-boot DB is `./data/managerObject_DB.db` under the cwd: clear `data/` between runs.
- Evidence levels as ruled: a tool's own output = measured; a simulation / timing model = simulated; a cited
  line = analytical; latency derived from cycles/Fmax says DERIVED; a delay without conditions is refused.
- pol-core: sudo prompts → tools live in docker images (the toolchain image; openroad/opensta); ngspice absent.

## Owed (in the order I would take them)

1. **The σ-field visualization** — the first Angular touch: a 2-D field binding over an FEM execution row, or a
   thin panel feeding `sci-xy-chart` from `/api/tensormath/evaluate` (σ_xx along y = h/2). Then the
   plate-mechanics root resolves.
2. **A SimulationCouplingDefinition created FROM a `kind=coupling` TensorMapping** (today the wind mapping
   references the existing coupling; creating one needs the sampler equation).
3. **The CNT cell library** as a second Liberty for lod-2 (needs ngspice + a derived device → `characterize_cells`).
4. **lod-3**: cells → transistors (sky130_fd_pr SPICE) → layout (Magic/KLayout, DRC/LVS) → PSPP process rows.
5. **PyTorch** as a third implementation (D5: deferred until a workload benefits).
6. **Merge `dev-tt-0` → dev** (his word), then `pol modules publish tensormath tensortree computelod`.
