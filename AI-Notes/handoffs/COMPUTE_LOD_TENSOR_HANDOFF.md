# Handoff — the Compute LOD + Tensor arc (2026-09-23/24): what is built, how to prove it, what is owed

_Plan of record: `AI-Notes/plans/COMPUTE_LOD_TENSOR_PLAN.md` (three rounds with ChatGPT, relayed by Dustin; D1–D7
ratified 2026-09-23; §G.1–G.19 are the build status; §H is what comes next; §I is the proofs revision). Branch `dev-tt-0` in the suite, `polari-rf-node`,
`polari-framework` AND `polari-platform-angular` — UNMERGED, per branch-per-confirmed-phase; merge on his word._

## The one-line map

    tensormath   Tensor (values BY REFERENCE: matrix | dataset | engine | claim) · TensorDimension · TensorMathExpression
                 (named-dim contract/outer/reduce/norm/permute/slice; rank ≤ 2 delegates to matrices/) · TensorOperator ·
                 ComputeImplementation (the bridge) · TensorDecomposition
    tensortree   TensorTreeDefinition · TensorNode (validity LOCAL) · UnresolvedTensorSpace (typed) · LocalizedDimension
                 (eleven channels) · TensorMapping (one class, kind, two statuses) · TensorSelection · TensorDiscoveryPolicy
    computelod   ComputeLOD (eleven rungs; design_level_ref into the microchip ladder) · ComputeKind (70) · ComputeMapping
                 (down) · CharacterizationMapping (up, conditions load-bearing) · CompilerArtifact
    + tensormath FEMFieldState (the σ/u/mesh field written down) · simSpace 2-D kinds `field` (cells coloured by a
                 scalar), `vectorfield` (node → node + k·v), `meshwire` (edges once) · angular `tensor-tree-panel` (d3)
                 · a `sky130` SiliconProcessNode seeded in sifet's shape (manufacturable = None → D-lod4-1)

## Prove it in ten minutes

    cd polari-rf-node/polari-framework
    PYTHONPATH=.:modules python3 modules/tensormath/tensormath_selftest.py      # 61
    PYTHONPATH=.:modules python3 modules/tensortree/tensortree_selftest.py      # 64
    PYTHONPATH=.:modules python3 modules/computelod/computelod_selftest.py      # 87
    mkdir -p /tmp/tt && cd /tmp/tt && rm -rf data && PYTHONPATH=<fw>:<fw>/modules python3 <fw>/tests/tensor_liveboot_probe.py   # 95/95 on a REAL boot
    (cd polari-platform-angular && npx tsc --noEmit -p tsconfig.app.json)   # the tensor-tree-panel type-checks (tt-5)
    # re-run the tool chains (docker; nothing installed on the host):
    (cd ../polari-eda-tools && docker build -t polari-eda-tools:noble . && ./fetch-pdk.sh)   # the toolchain SUBMODULE + engines WORKER: gcc-riscv64 · yosys · verilator · iverilog · nextpnr/icestorm · OpenSTA · magic (source) · netgen · ciel → sky130A (0.9 GB, cached)
    # engines resolve through the Polari ladder (computelod/custom/eda_engines.py): EDA_ENGINES_URL → local binary → local image → `pol allocate computelod.engines <instance>` → refusal; GET /api/computelod/engines shows the placement
    docker pull openroad/opensta
    PYTHONPATH=.:modules python3 -m computelod.custom.lod1_chain run              # c=a+b → gcc → add → picorv32 → yosys → iverilog
    PYTHONPATH=.:modules python3 -m computelod.custom.lod2_silicon run            # SKY130 abc mapping + OpenSTA (Liberty cached in ~/.cache/polari-lod)
    # the FPGA kernel needs a manager (see the tensormath selftest's fpga block or the probe)

Live surfaces: `/api/tensormath` (+ evaluate, operators/{name}, benchmark, fem/{case} [/materialise | /shapes]), `/api/tensortree` (+ trees/{name}
/graph /validate /view, select, discover, scale/{material} [/materialise], mappings/{name}/couple [/prove]), `/api/computelod` (+ rungs/{name},
walk/{rung}/{ref}, path?rung=&ref=, lod1, lod2, lod2/cnt, lod3, lod3/devices, lod3/layout, lod4); pages `/display/tensormath|tensortree|computelod`.

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
- **tt-5** the tree in the browser: ONE registered d3 panel over ONE `/view` read — structure, evidence-coloured
  mapping arcs, dims → channels, select → discover → follow. Unseen until the images rebuild (his pass).
- **tt-6** the σ field SEEN: FEMFieldState row (seed-solved), a 2-D `field` binding kind, the d3 renderer honouring
  `colorOverride`; plate root RESOLVED; one constant for the colour domain on both sides.
- **tt-7** a SimulationCouplingDefinition CREATED from a kind=coupling mapping — derived from the nodes' tensors,
  refused by name for anything underivable; evidence untouched until a run pairs to it.
- **lod-2b** the second Liberty: our own CNT cells characterized here (ngspice/OpenVAF are in `~/tools`), 152
  cells, 41.33 ps at 0.6 V/300 K — intrinsic-grade, stated, NOT "faster than SKY130".
- **lod-3** cells → transistors → layout READ from the PDK's per-cell .spice/.lef: 1050 transistors, LEF area ==
  Liberty area (855.82 — two sources agree); CNT 1016 transistors, no layout (unresolved row).
- **lod-4** fabrication → materials by reference: `sky130` process row (manufacturable None → D-lod4-1), eg-si via
  the Siemens route; the walk from `c = a + b` spans ALL ELEVEN rungs.
- **tt-8** u per node SEEN (2-D `vectorfield`, stated exaggeration 20 000); 45 lines, zero on the fixed edge.
- **tt-9** the mesh SEEN as a wireframe (`meshwire`; 108 edges = V + F − 1); filled cells = a renderer change, his call.
- **lod-3b** the PDK's transistor models RUN by our ngspice for inv_1/nand2_1 and cross-checked against the Liberty
  at the same slew/load: mean |Δ| 10.8 %, falls faster everywhere (schematic netlist vs extracted layout — stated).
- **lod-3c** the PDK's layout RUN through the new `polari-eda-tools` submodule: DRC (context rules only), PEX, LVS
  match; extraction fixes part of the fall gap and widens the rise gap — the parasitics hypothesis half-rejected.
- **tt-11** filled cells THROUGH the shape library (his ruling): mathshapes `polygon` + a bridge to space-unit
  Shape2DDefinitions; the renderer learned only `units='space'`; the plate is tiled with its own triangles.
- **tt-10** the created coupling EXECUTED through the runner's own pre-pass → simulated evidence; t = 0 was a true
  zero (calm by construction) → default past it, stated.

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

## State at handoff (2026-09-24 evening)

Every item of the original owed list is closed except PyTorch (D5, deferred by ruling). Built and proven on a real
boot (94/94): tt-0..11, lod-1, lod-2, lod-2b, lod-3, lod-3b, lod-3c, lod-4 — plan §G.1–G.19. The toolchain lives
in its own submodule `polari-rf-node/polari-eda-tools` (image + pinned PDK fetcher + LICENSES.md); build it and
fetch the PDK before re-running any lod-3c/3b/2/1 flow:

    cd polari-rf-node/polari-eda-tools && docker build -t polari-eda-tools:noble . && ./fetch-pdk.sh
    docker pull openroad/opensta

## What is left, and who does it

1. **The browser pass — his, or a session with Chrome attached.** Plan §H.1 is the procedure: rebuild the home
   swarm from the `dev-tt-0` trees (admit the four modules first), open `/display/tensortree`, `/display/tensormath`,
   `/display/computelod`, judge each panel against the listed expectations, file gaps. Nothing of this arc's
   frontend has been seen yet: `tensor-tree-panel`, the plate scene (filled triangles, wireframe, displacement
   lines), the `units=space` shapes.
2. **D-lod4-1 — his ruling** (plan §H.2): is SKY130 manufacturable under the sifet ladder rule? Set the row's
   `manufacturable` + `manufacturable_reason` accordingly (`computelod/custom/lod4_process.py: SKY130_NODE`).
3. **Merge `dev-tt-0` → dev — his word.** Innermost-first: polari-eda-tools is already on its own `dev`;
   polari-framework, polari-platform-angular, polari-rf-node (pointer + the new submodule), then the suite.
   `polari-cli/shells/push-all-dev.sh --with-isle` sweeps the forest once merged. Then `pol modules publish
   tensormath tensortree computelod mathshapes`.
4. **Mathematical proofs — plan §I (his ask, 2026-09-24; PLAN ONLY, nothing built):** a `mathproofs` module
   (MathClaim / ProofRun / InferenceRule / ProofObligation), a JSON term language lowered to numeric → SymPy
   (present) → Z3 (MIT, pip) → Lean 4 + Mathlib (Apache-2.0, a toolchain stage); obligations generated from the
   tree's structure by seeded rules; discovery refuses on refutation; badges on the panel's arcs. Phases
   pf-0..pf-4. ✅ D-pf-1..6 RATIFIED 2026-09-24 (`polari-proof-tools` = its own submodule of polari-rf-node,
   §I.8); §I.9 refinements; §I.10 = the small decisions still open (D-pf-7..11, recommendations given).
   Order: pf-0 right after the merge, before further lod work.
5. **Further lod work** — plan §H.3, a sized table; my order after the merge: lod-3d (the other adder cells
   through DRC/PEX/LVS — small), lod-4c (Ion/Ioff for the sky130 row from the models we already run — small),
   lod-2c (CNT vs SKY130 at the same conditions), lod-3e (the whole adder placed-and-routed — needs OpenROAD in
   the image), lod-4b (the process as PSPP rows).

## Gotchas a fresh session will hit (all in memory too)

- Live-boot probe: run from a throwaway cwd or `rm -rf data` between runs (the sqlite DB is `./data/`).
- A `pgrep -f <pattern>` waiter matches its own argv — use `pgrep -f "[l]od2_cnt run"` or a pidfile.
- ngspice-46 + OpenVAF 23.5 are on pol-core under `~/tools` (not PATH); the cntfet ladder finds them.
- sky130 slew convention is 20–80 %: a 50 ps 0–100 % ramp is a 30 ps slew (25 % fast).
- netgen infers the netlist format from the suffix (`.ext.spice` is read as magic `.ext`): name it `_lvs.spice`.
- noble's `magic` (8.3.105) segfaults on the sky130A tech (needs ≥ 8.3.411) — the image builds 8.3.684 from source.
- A standard cell alone always fails nwell.4 / LU.2 / LU.3 (taps from the row) — classified, not hidden.
- The snapshot route is `/api/simspace/{name}/snapshot`, payload wrapped `{success, data}`.
- `LazySeedRows` fills on iteration, len AND indexing now; the seed loop iterates.
- The 2-D shape library takes a `shapeRef`; per-instance geometry goes through mathshapes → `Shape2DDefinition
  units='space'`, never a polygon on the object.
- NEVER `docker run <tool image>` from a module directly: declare `requires.engines`, resolve through the engines
  ladder (a worker + knob + topology provider), argv only. A remote ngspice worker takes netlist text only —
  inline absolute `.include`s.
