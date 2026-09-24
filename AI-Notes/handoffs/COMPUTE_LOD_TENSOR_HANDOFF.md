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
    PYTHONPATH=.:modules python3 modules/tensormath/tensormath_selftest.py      # 56
    PYTHONPATH=.:modules python3 modules/tensortree/tensortree_selftest.py      # 63
    PYTHONPATH=.:modules python3 modules/computelod/computelod_selftest.py      # 75
    mkdir -p /tmp/tt && cd /tmp/tt && rm -rf data && PYTHONPATH=<fw>:<fw>/modules python3 <fw>/tests/tensor_liveboot_probe.py   # 83/83 on a REAL boot
    (cd polari-platform-angular && npx tsc --noEmit -p tsconfig.app.json)   # the tensor-tree-panel type-checks (tt-5)
    # re-run the tool chains (docker; nothing installed on the host):
    docker build -t polari-computelod-tools:noble modules/computelod/custom/tools     # gcc-riscv64 13.2 · yosys 0.33 · verilator · iverilog · nextpnr-ice40 · icestorm
    docker pull openroad/opensta
    PYTHONPATH=.:modules python3 -m computelod.custom.lod1_chain run              # c=a+b → gcc → add → picorv32 → yosys → iverilog
    PYTHONPATH=.:modules python3 -m computelod.custom.lod2_silicon run            # SKY130 abc mapping + OpenSTA (Liberty cached in ~/.cache/polari-lod)
    # the FPGA kernel needs a manager (see the tensormath selftest's fpga block or the probe)

Live surfaces: `/api/tensormath` (+ evaluate, operators/{name}, benchmark, fem/{case} [/materialise]), `/api/tensortree` (+ trees/{name}
/graph /validate /view, select, discover, scale/{material} [/materialise], mappings/{name}/couple), `/api/computelod` (+ rungs/{name},
walk/{rung}/{ref}, path?rung=&ref=, lod1, lod2, lod2/cnt, lod3, lod4); pages `/display/tensormath|tensortree|computelod`.

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

## tt-5 (2026-09-23): the tree in the browser

`tensor-tree-panel` (Angular, registered; d3 tree + evidence-coloured mapping arcs + dims→channel chips + the
select → discover → follow cycle) over `GET /api/tensortree/trees/{name}/view`; mounted as row 1 of the
`tensortree` page on `wind-spatial`. Plan §G.8. UNSEEN in a browser until the staging images rebuild — his pass.

## Owed (in the order I would take them)

1. ~~The σ-field visualization~~ ✅ tt-6 (plan §G.9): `FEMFieldState` row + 2-D `field` binding kind +
   d3 `colorOverride`; the plate root RESOLVES on a real boot. ✅ tt-8 (§G.14): u per node as a 2-D `vectorfield`
   binding (connections, stated exaggeration) — the tree is resolved; only true triangle cells remain open.
2. ~~A SimulationCouplingDefinition created FROM a `kind=coupling` TensorMapping~~ ✅ tt-7 (plan §G.10):
   `GET|POST /api/tensortree/mappings/{name}/couple`, derived from the nodes' tensors, refused by name.
3. ~~The CNT cell library as a second Liberty~~ ✅ lod-2b (plan §G.11): `python3 -m computelod.custom.lod2_cnt run`
   from a throwaway cwd; ngspice/OpenVAF live in `~/tools` on pol-core (the cntfet ladder finds them).
4. ~~lod-3: cells → transistors → layout~~ ✅ first slice (plan §G.12): READ from the PDK's per-cell .spice/.lef
   (1050 transistors; LEF area == Liberty area) and the CNT cell library (1016; no layout). Still open under it:
   DRC/LVS (Magic/netgen), sky130_fd_pr corner simulation.
   ✅ lod-4 first slice (plan §G.13): the `sky130` SiliconProcessNode row (sifet shape; manufacturable None →
   **D-lod4-1 his**) and fabrication → materials onto sifet's eg-si; the walk spans all eleven rungs.
5. **PyTorch** as a third implementation (D5: deferred until a workload benefits).
6. **Merge `dev-tt-0` → dev** (his word), then `pol modules publish tensormath tensortree computelod`.
