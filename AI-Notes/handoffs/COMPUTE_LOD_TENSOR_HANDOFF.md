# Handoff — the Compute LOD + Tensor arc (2026-09-23/26, after lod-4b — the lod half of §H.3 complete): what is built, how to prove it, what is owed

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
    PYTHONPATH=.:modules python3 modules/computelod/computelod_selftest.py      # 106 (lod-3d: 8 cells · 21 arcs; lod-4c: Ion/Ioff/Vt; the lod cross-checks as claim rows, pf-1)
    PYTHONPATH=.:modules python3 -m computelod.custom.lod4_devices run          # lod-4c: two DC decks, seconds
    PYTHONPATH=.:modules python3 -m computelod.custom.lod2_compare run          # lod-2c: six twins at the CNT point + own FO4 (~10 min; the 0.6 V decks are long)
    docker pull openroad/orfs:26Q3-651-gbc334a4aa && PYTHONPATH=.:modules python3 -m computelod.custom.lod3_pnr run   # lod-3e: the adder placed + routed, both variants (~1 min)
    PYTHONPATH=.:modules python3 -m computelod.custom.lod4_steps run             # lod-4b: a reading (nothing fetched); the PSPP rows seed at boot
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

## State at handoff (2026-09-26, after lod-4b; branch `dev-lod-4b` off `dev-lod-3e`; FIVE stacked UNMERGED branches)

lod-4b BUILT (plan §G.31): `computelod/custom/lod4_steps.py run` — the fabrication route as PSPP rows: 8 SKY130 wafer-state
stages from the PDK's documented 26-layer stack (quoted, cited, read 2026-09-26) + 8 textbook unit processes (Plummer/Deal/
Griffin; the recipe named as absent on every row), the CNT route's 6 + 6 by reference to cntfet's cnt_process rows; `lod4:
fabrication → materials` replaced by name, `lod4b-cnt: …` added (proposed). The PSPP rows ride computelod's seed pairs
(guarded on pspp). `GET /api/computelod/lod4/steps`. **The lod half of §H.3 is complete** (lod-3d, 4c, 2c, 3e, 4b — all
2026-09-26). Merge word for FIVE branches is his, innermost-first per repo: `dev-lod-3d` → `dev-lod-4c` → `dev-lod-2c` →
`dev-lod-3e` → `dev-lod-4b` (framework → rf-node → suite; eda-tools dev already pushed). Remaining on §H.3: tt-12 (the plate
scene inside the node detail — Angular) and tt-13 (cross-tree discovery with a `units` filter — tensortree), both small.

## State at handoff (2026-09-26, after lod-3e; branch `dev-lod-3e` off `dev-lod-2c`; FOUR stacked UNMERGED branches)

lod-3e BUILT (plan §G.30): `computelod/custom/lod3_pnr.py run` — the whole adder (lod-2's own 96-cell netlist) placed and
routed by OpenROAD-flow-scripts in its PUBLISHED image (pinned `openroad/orfs:26Q3-651-gbc334a4aa` + digest; `docker pull` it
first — 4.6 GB; no source build), two variants (as-flow / cells-kept), router DRC 0, parasitics extracted, timed under lod-2's
conditions with and without the SPEF: **the wires cost 2.3–2.4 %**; the flow's resizing of the carry chain is counted on
every row (that, not the wires, is why 9.8/10.06 ns beat lod-2's 11.94). Engines `orfs`/`openroad` in the ladder resolve ONLY
via that image or a worker. eda-tools LICENSES.md gained the image's audit (committed on its dev). Merge word for FOUR
branches is his, innermost-first per repo: `dev-lod-3d` → `dev-lod-4c` → `dev-lod-2c` → `dev-lod-3e` (framework → rf-node →
suite; eda-tools dev already pushed). §H.3 continues lod-4b (process as PSPP rows) → tt-12/13.

## State at handoff (2026-09-26, after lod-2c; branch `dev-lod-2c` off `dev-lod-4c`; three stacked UNMERGED branches)

lod-2c BUILT (plan §G.29): `computelod/custom/lod2_compare.py run` — six twin cells of the two Liberties at the CNT point
(SKY130 SIMULATED at 0.6 V: 19–179 ns, hvt p in subthreshold — stated) and at each library's own FO4 (SKY130 inv 101 ps vs
CNT 1.17 ps; ratios 58–135, the CNT side named intrinsic-grade on every row); CNT area REFUSED; 24 `lod2c:` rows; two
witnessed MathClaims; `GET /api/computelod/lod2/compare`. The Liberty reader is generic (units normalised, `when` groups,
outside-the-grid refused). Merge word for the THREE branches is his, innermost-first per repo: `dev-lod-3d` → `dev-lod-4c`
→ `dev-lod-2c` (framework → rf-node → suite). §H.3 continues lod-3e (OpenROAD into the eda-tools image — medium-large) →
lod-4b → tt-12/13.

## State at handoff (2026-09-26, after lod-4c; branch `dev-lod-4c` off `dev-lod-3d`, both UNMERGED)

lod-4c BUILT (plan §G.28): `computelod/custom/lod4_devices.py run` — Ion / Ioff / Vt / DIBL / SS for nfet_01v8 and
pfet_01v8_hvt from DC sweeps on the PDK's tt BSIM4 cards (W = 1 µm, L = 0.15 µm, sifet's constant-current Vt), ten
`lod4c:` characterizations fabrication → devices (simulated, implemented), the sky130 row's `key_numbers_json` gaining the
numbers in sifet's key names (converged onto existing rows), `GET /api/computelod/lod4/devices`. Proof: computelod
106/106, live boot 128/128. Merge word for BOTH branches is his: `dev-lod-3d` then `dev-lod-4c` (framework → rf-node →
suite). §H.3 continues lod-2c → lod-3e → lod-4b → tt-12/13.

## State at handoff (2026-09-26, after lod-3d — the first §H.3 slice; branch `dev-lod-3d`, UNMERGED)

lod-3d BUILT on `dev-lod-3d` (framework; rf-node + suite carry the pointer) off the merged `dev`: every cell of the adder
(8 cells, 21 arcs) through the lod-3b schematic run and the lod-3c DRC/PEX/LVS + extracted re-timing — plan §G.27. What
a fresh session must know: (1) the two-cell parasitics verdict did NOT generalize — extraction narrows every fall gap
(21/21) but the rise gap only where the schematic was already slower than the Liberty (11/21 closer); the seeded claim
`lod3c-extraction-widens-every-rise-gap` is now REFUTED at boot with an xor2_1 row as the counterexample and KEPT, and
`lod3c-extraction-widens-the-rise-gap-where-already-slow` (an `implies`) is the statement that holds; (2) the Liberty
group is picked by (related_pin, timing_sense) — a non-unate pin without a sense is refused; decks order pins by the
netlist's `.subckt` names; (3) mathproofs holds the 21 arcs as the literal `LOD3_ARCS` (asserted equal to computelod's
`arcs_of` in computelod's selftest); (4) counts moved: computelod 100 checks, live boot 126/126 with 96
CharacterizationMappings and 16 seeded claims (aggregate 31). Also this session: political-scorecard-node's `dev` was
one commit behind the suite's pin (`dev-fs-1`) — fast-forwarded and pushed. Left: HIS merge word for `dev-lod-3d`
(framework → rf-node → suite, innermost-first; `pol modules publish computelod mathproofs` after the repos exist — open
item 1 below); then §H.3 in order lod-4c → lod-2c → lod-3e → lod-4b → tt-12/13. Open items unchanged: the four new
modules have no polari-module-* repos (his call); sky130 → `available` needs a verified vendor route.

## MERGED 2026-09-26 (his word: "Merging to dev on origin should be good")

Every branch of this arc fast-forwarded onto `dev` and pushed: framework, angular, rf-node, suite (`dev-bp-2`),
polari-cli and the PSC backend (`dev-fs-1`); eda-tools / proof-tools were already on their own dev. dev == origin/dev
everywhere. main is NOT promoted (the 2026-09-23 shelving stands). He also said the pages "look good enough for
now" after his revision notes (bp-2 / bp-3). D-lod4-1 RULED the same day (his: "Maybe another category? Historically proven, might be able to request
manufacturing by 3rd party?") → `manufacturability` vocabulary beside the bool: open | proven-on-request | unproven |
not-available; sky130 = proven-on-request, bool stays None (plan §H.2). Landed on existing instances through the
seeder's new `_converge` marker (code-owned fields follow the seed). Remaining on this arc: §H.3 further lod only.

## State at handoff (2026-09-25 late night, after bp-2 — his second browser pass, from a phone)

He looked at the pages from his phone and gave seven asks (plan §H.4 has his words and what each became). All
seven were BUILT the same night on `dev-bp-2` (framework, angular, rf-node, suite — stacked on `dev-fs-1`) and
seen live on the home swarm: the tensortree page is ONE tree at a time (the tree panel's chip sets a page SCOPE
through a `setScope` display event; `{scope:…}` placeholders in the configured panels follow it — tables, titles,
the ONE sim-space viewer), tables wrap / clamp / render JSON as key-value lines / link references, every page
opens "In plain words" (a `plain_words` attribute on 23 classes through `GET /api/plain`), `/object/:class/:name`
is the generic detail view of any row (interconnect chips + the record), the mathproofs page closes with the 13
cited sources behind the proof tiers (`ProofMethodReference`, 12 verified through Crossref), panel errors are
human ("Sign in to see this." + a button), and a Login/Register that cannot reach the realm now says so with the
host to open. Two gotchas fixed on the way, both worth knowing: (1) a module's page seed was NEVER re-applied to
an instance whose DB held the first copy — the seeder now upserts a changed page (POLARI_SEED_PAGES_UPSERT=no keeps
the old skip); (2) a new row class needs FOUR registrations — the module's `*_CLASSES` list, its manifest's
`objects` + `classes` + `imports`, the core `feature_imports.py` import tuple, AND the explicit class list in
`polariServer.py` (~line 1300) — miss the last two and boot prints "not in objectTypingDict, skipping".
Merge word now ends `… → dev-fs-1 → dev-bp-2` (angular the same; polari-cli / PSC backend stop at dev-fs-1).
bp-3 the same night (plan §H.5): every row EXPLAINED — `GET /api/explain?class=&name=` (module explainers in
`<module>/custom/explain.py`, generic field-comment fallback) and the object page opens with it: in one sentence, what
was done, with what, result, trust, evidence, how to reproduce (commands). Left for HIM: look again from the phone (the
same links; open any row's name to read its explanation), D-lod4-1, the merge word. Screenshots from the
extension time out on the pages with a 3-D viewer (renderer busy) — read the page text instead.

## State at handoff (2026-09-25 night, after the file-store detour — THIS arc is untouched by it)

A detour happened after the browser pass: minio was gone upstream, so the store became SeaweedFS (fs-1, his call
D-fs-1) and, because its UI had no login, the store is now browsed THROUGH Polari as the signed-in person (fs-2).
That work lives on `dev-fs-1` — stacked on top of `dev-pf-3` in the framework, angular, rf-node and the suite, plus
polari-cli and the PSC backend — and is documented in `AI-Notes/plans/FILE_STORE_PLAN.md`, not here. What it changes
for THIS arc: (a) the node stack on pol-core's swarm now has SIX services including `prf-file-store` (rendered by
`pol swarm render node`, not the old `stack-node-nofs.yml`); (b) the merge word now ends one branch later:
`dev-tt-0 → dev-pf-0 → dev-pf-1 → dev-pf-2 → dev-pf-3 → dev-fs-1` (angular: `dev-tt-0 → dev-pf-0 → dev-pf-3 →
dev-fs-1`; polari-cli and PSC backend: `dev-fs-1` alone), innermost-first as before. Nothing in items 3–6 below moved:
the next steps on this arc are still HIS — look at the pages (item 3), D-lod4-1 (item 4), the merge word (item 5) —
and §H.3 further lod comes after the merge. A fresh session on this arc starts at "Where a fresh session starts".

## State at handoff (2026-09-25 evening, after the browser pass)

The node stack is UP on pol-core's single-node swarm (`polari-node`; at that moment five services and no file store
— superseded above) from `.generated/stack-node-nofs.yml`; Chrome's NSS store trusts the dev CA ("Polari Dev CA
(staging pass)"). The pass and its fixes: plan §H.1 RESULTS. Everything below still holds.

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
3. ~~His: the browser pass~~ **RUN 2026-09-25 by me with Chrome attached** (plan §H.1 RESULTS): every §H.1 row read
   true except nine gaps, all FIXED the same day on `dev-pf-3` (dim keys, the ◐ gap badge, the summary panels' CSV
   pick, `\text{}` names in the LaTeX, the tooltip's field value, the auth-host SAN, the scene warnings, the techtree
   `proof` segment kind, label widths) + the boot pass converging derived rows. Left for him to LOOK at (not judge
   again): the pages as they stand on the home swarm (`pol swarm ps node`; https://prf.<LOCAL_IP>.nip.io/display/
   tensortree|mathproofs|tensormath|computelod, /tech-tree). The original text follows:
   **His: the browser pass** (plan §H.1 — nothing of this arc's frontend has been seen: the tree panel with its
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
    PYTHONPATH=.:modules python3 -m computelod.custom.lod3_devices run && PYTHONPATH=.:modules python3 -m computelod.custom.lod3_layout run   # lod-3b/3c/3d: 21 arcs, 8 cells (~10 min; ngspice from ~/tools, magic/netgen via the image)
    # then: his merge word for dev-lod-3d; §H.3 continues lod-4c → lod-2c → lod-3e → lod-4b

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
- 🔴 **`minio/minio` is GONE from Docker Hub (found 2026-09-25 bringing the node stack up for the browser pass):**
  `pol-file-store/Dockerfile` is `FROM minio/minio:latest`; the Hub API answers "object not found" for the whole
  repository (and quay.io/minio/minio too), so `prf-file-store` cannot build anywhere — the same class of upstream
  death as bitnami/redis (memory). For the pass the stack was deployed from `.generated/stack-node-nofs.yml` (the
  rendered node stack minus the file-store service; a throwaway). HIS decision: the replacement (candidates with
  GPLv3-compatible licences: SeaweedFS Apache-2.0, RustFS Apache-2.0 S3-compatible, Garage AGPL-3.0; or pin a MinIO
  release built from source under its AGPL) — a licence-gate row + a `pol-file-store` rewrite, not a one-liner.
  → DECIDED + BUILT the same day: SeaweedFS (D-fs-1) — `AI-Notes/plans/FILE_STORE_PLAN.md`, branch `dev-fs-1`.
- Bring-up from a stripped checkout (this pass): `pol security setup dev` + `POLARI_ROTATE_KC=no pol security
  node-setup staging` create `.generated/.env.staging`; `LOCAL_IP` must be set on pol-core (two IPv6 addresses on
  the wifi interface make `docker swarm init` refuse to pick one); `POLARI_MODULES` must be exported (the core is
  down, so the rows cannot be derived) — the probe's list is the arc's list; the realm allows self-registration, so a
  throwaway user can be made at the login page.
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
