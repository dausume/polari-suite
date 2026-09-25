# Handoff — the Compute LOD + Tensor arc (2026-09-23/25, after pf-4): what is built, how to prove it, what is owed

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
    PYTHONPATH=.:modules python3 modules/computelod/computelod_selftest.py      # 91 (the lod cross-checks as claim rows, pf-1)
    PYTHONPATH=.:modules python3 modules/mathproofs/mathproofs_selftest.py      # 83 (pf-0 + pf-1 z3 + pf-2 lean + pf-3 doors + pf-4 knowledge)
    rm -rf data && PYTHONPATH=.:modules python3 tests/tensor_liveboot_probe.py   # 126/126 on a REAL boot (branch dev-pf-3) — from the framework dir, data/ cleared
    (cd polari-platform-angular && npx tsc --noEmit -p tsconfig.app.json && npx ng build --configuration development)   # the claim editor + panel doors compile
    CI_SELFTEST_IMAGE=<built image> PROOF_ENGINES_URL=http://localhost:9810 bash ../../polari-jenkins/proofs.sh /tmp/proofs   # the pipeline's proofs stage, by hand
    pip install --user z3-solver==5.1.0.0      # once, on a glibc host (the image takes z3 from apk — see G.23)
    (cd ../polari-proof-tools && docker build -t polari-proof-tools:noble .)    # the Lean tier: 11 GB once (Mathlib's cache); then the probe proves the 3 theorems via the local image
    (cd .. && docker compose -p proof-engines -f docker-compose.proof-engines.yml up -d)   # …or as the WORKER; PROOF_ENGINES_URL=http://localhost:9810 makes the probe use it
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

## State at handoff (2026-09-25, after pf-3)

pf-3 on `dev-pf-3` (framework + angular + suite/polari-jenkins): the doors, the editor, the panel buttons, the
proofs stage — plan §G.25. Merge order now `dev-tt-0 → dev-pf-0 → dev-pf-1 → dev-pf-2 → dev-pf-3` (angular:
`dev-tt-0 → dev-pf-0 → dev-pf-3`).

## State at 2026-09-25, after pf-2

pf-1 on `dev-pf-1` (the z3 tier, boot-time obligations, the knob, the lod claims asserted in computelod, the Alpine
z3 route; budget 25 s — plan §G.23) and pf-2 on `dev-pf-2` (the Lean tier through the new `polari-proof-tools`
submodule and worker — plan §G.24). Everything below from the 2026-09-24 state still holds.

## State at 2026-09-24 evening

Every item of the original owed list is closed except PyTorch (D5, deferred by ruling). Built and proven on a real
boot (94/94): tt-0..11, lod-1, lod-2, lod-2b, lod-3, lod-3b, lod-3c, lod-4 — plan §G.1–G.19. The toolchain lives
in its own submodule `polari-rf-node/polari-eda-tools` (image + pinned PDK fetcher + LICENSES.md); build it and
fetch the PDK before re-running any lod-3c/3b/2/1 flow:

    cd polari-rf-node/polari-eda-tools && docker build -t polari-eda-tools:noble . && ./fetch-pdk.sh
    docker pull openroad/opensta

## What is left, and who does it (order as of 2026-09-25, after pf-3)

Branches: `dev-tt-0` (tt-0..11, lod-1..4 incl. 2b/3b/3c, the engines seam), `dev-pf-0` on top (pf-0, the
vocabulary correction), `dev-pf-1` (pf-1: the z3 tier, boot-time obligations, the knob, the lod claims in
computelod's selftest, the Alpine z3 route; budget 25 s), `dev-pf-2` (pf-2: the Lean tier — NEW submodule
`polari-rf-node/polari-proof-tools` on its own `dev`, the ladder, three theorems proved live) — in the suite,
polari-rf-node, polari-framework (no Angular change since dev-pf-0: the angular branch stays dev-pf-0); the
submodules `polari-eda-tools` and `polari-proof-tools` are on their own `dev`; `dev-pf-3` (pf-3: the authoring doors,
the claim editor in the palette shape, the pipeline's `proofs` stage) in the suite (incl. polari-jenkins), rf-node,
framework AND angular (the angular branch is `dev-pf-3` off `dev-pf-0` — pf-1/pf-2 had no Angular change). All
pushed, none merged. Live boot on dev-pf-3: **123/123**.

1. ~~pf-1~~ **BUILT 2026-09-25** — plan §G.23. Everything in the former item landed: `custom/z3tier.py` (continuum
   forall/exists with the model as the counterexample; `subset` re-derived and agreeing with the interval tier;
   the tt-3 kernel's int64 MAC decided over exact integers — the bit-blasted encoding needs 19 s, over the budget,
   so `encoding: "int"` is the default and `"bv"` selectable), `budget_s` → `undecided` with the claim untouched,
   the decomposition bound as `InferenceRule.params_json.bound` read by ref (a knob change = stale, never a silent
   re-verdict), boot-time generation of every tree's obligations + one check of every never-run claim
   (`custom/boot.py`, 2.7 s live), seven new seeded claims (one REFUTED by a model: speed = 6 m/s), the five lod
   cross-checks asserted as claim rows in computelod's selftest, the aggregate's worst case now 50 s vs 0.78 s spent.
   z3 in the image comes from apk (no musl wheel) — both Dockerfiles changed; an image build proves it (see below).
2. ~~pf-2~~ **BUILT 2026-09-25** — plan §G.24: `dausume/polari-proof-tools` (Lean v4.34.1 + Mathlib d13f23b7 pinned,
   11 GB image, worker :9810), `mathproofs/custom/proof_engines.py` (the ladder) + `lean_tier.py` (the statement_hash
   bridge; proved only when lean accepts AND the hash matches), the three D-pf-10 theorems PROVED live through the
   local image and through the worker (2.3–3.9 s each). Not done: the CI `proofs` stage; a topology instance for
   the worker. The former item's text follows for reference:
   **pf-2 — Lean 4 through `polari-proof-tools` (as planned).**
   ~~pf-3~~ **BUILT 2026-09-25** — plan §G.25: the three doors (`terms/preview`, `POST claims`, `obligations/
   propose`), the claim editor in the app's LaTeX-palette shape with the term language as the categories (his
   steer), the panel's `claim` / `propose` buttons, the `latex` table column, and the pipeline's ADVISORY `proofs`
   stage (proofs_stage.py, proofs.sh, Jenkinsfile.test, verdict/report).
   ~~pf-4~~ **BUILT 2026-09-25** (same branch) — plan §G.26: the `tensor-proofs` tech tree (ten TechNodes citing the
   claims), `GET /api/mathproofs/knowledge` joined live (established = every cited claim settled; a refutation counts
   as knowledge). **The proofs arc pf-0..4 is complete**; what remains on the whole arc is his (items 3–5) and §H.3. A NEW repo `dausume/polari-proof-tools`, submodule of
   polari-rf-node beside polari-eda-tools, in the SAME shape (Dockerfile: elan + ONE pinned Lean release +
   Mathlib at ONE pinned commit with oleans cached in the image; `lean-toolchain` + `lake-manifest.json`
   committed — D-pf-11; `proof_engines_service.py` = an engines WORKER: `/capability` + `/check`; `theorems/`
   committed sources; LICENSES.md), `docker-compose.proof-engines.yml`; the framework resolves `lean` through
   `mathproofs/custom/proof_engines.py` = the engines ladder exactly as `computelod.custom.eda_engines`
   (PROOF_ENGINES_URL → local → topology provider `mathproofs.engines` → refusal) — NEVER a device assumption;
   the `statement_hash` bridge; the first two theorems (D-pf-10): σ = C:ε symmetry in general rank; the
   tree-composition lemma; restriction idempotence as the toolchain smoke test.
3. **His: the browser pass** (plan §H.1 — nothing of this arc's frontend has been seen: the tree panel with its
   proof badges, the plate scene with filled triangles / wireframe / displacement lines, the space-unit shapes; since
   pf-3: the claim editor (palette + backend-derived LaTeX preview) from a mapping row's `claim`, a candidate's
   `propose`, the mathproofs page's rendered LaTeX column, the `tensor-proofs` tree in the techtree display).
4. **His: D-lod4-1** — is SKY130 manufacturable under the sifet ladder rule? (`lod4_process.py: SKY130_NODE`).
5. **His: the merge word** — `dev-tt-0` → dev first, then `dev-pf-0`; innermost-first (eda-tools already on
   its dev; framework, angular, rf-node with the submodule pointer, suite); `push-all-dev.sh --with-isle`;
   then `pol modules publish tensormath tensortree computelod mathshapes mathproofs`.
6. **Further lod after the merge** (plan §H.3, sized): lod-3d the other adder cells through DRC/PEX/LVS;
   lod-4c Ion/Ioff for the sky130 row from the models already run; lod-2c CNT vs SKY130 at the same conditions;
   lod-3e the whole adder placed-and-routed (OpenROAD into the eda-tools image, BSD-3); lod-4b the process as
   PSPP rows; tt-12/13 (panel: a node's scene inside its detail; cross-tree discovery with a units filter).

## Where a fresh session starts

    cat AI-Notes/plans/COMPUTE_LOD_TENSOR_PLAN.md          # §G.1–G.22 what is built, §H next, §I proofs
    (cd polari-rf-node/polari-eda-tools && docker build -t polari-eda-tools:noble . && ./fetch-pdk.sh)
    cd polari-rf-node/polari-framework && PYTHONPATH=.:modules python3 modules/mathproofs/mathproofs_selftest.py   # 60
    rm -rf data && PYTHONPATH=.:modules python3 tests/tensor_liveboot_probe.py   # 110/110 (from the framework dir; data/ is gitignored and empty)
    # then: his browser pass / D-lod4-1 / the merge word (items 3–5); §H.3 further lod after the merge

## Gotchas a fresh session will hit (all in memory too)

- Live-boot probe: run FROM THE FRAMEWORK DIR with `rm -rf data` first (the sqlite DB is `./data/`, gitignored).
  A bare throwaway cwd (`/tmp/tt`) does NOT boot: polyTyping resolves class source paths relative to the cwd
  (`/tmp/tt/polariApiServer` → IndexError in getCreateMethod) — found 2026-09-25, the older note was wrong.
- z3 on the host: `pip install --user z3-solver==5.1.0.0` (not in requirements.txt — no musl wheel; the image
  takes apk `py3-z3` + `z3`, Alpine's 4.16.0; the ProofRun records the version it ran with).
- z3 encodings: bit-blasted 64-bit MACs (QF_BV) take ~19 s here; exact integers (QF_NIA) 0.7 s — prefer `int`.
- Lean: `import` lines must precede the `/-! … -/` doc block; the worker/ladder read `POLARI_STATEMENT_HASH` from
  the file's first 40 lines. Mathlib names move between releases (Set.subset_iInter₂; Data.Set.Lattice.Indexed;
  Mathlib.Logic.Basic is gone) — the image build IS the check (lake build PolariProofs). A pin bump = lean-toolchain
  + the mathlib rev in lakefile.toml + a fresh lake-manifest.json extracted from the image, theorems re-checked.
- The lean tier is never automatic: boot lists such claims as awaiting a person; `?tier=lean` runs one; the merge
  of a bumped submodule pointer is where the pipeline's `proofs` stage (not built) would re-check them.
- `gh repo create --source .` from the snap gh says "not a git repository" here — create bare, then add the
  remote and push (done that way for polari-proof-tools).
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
