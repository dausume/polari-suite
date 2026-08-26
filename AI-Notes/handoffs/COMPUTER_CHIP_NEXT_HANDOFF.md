# Next-session handoff: computer composition ∥ microchip (2026-08-25)

**SUPERSEDED for the chip arc 2026-08-26: both arcs are now
COMMITTED + MERGED to local dev; the live entry point is
MICROCHIP_CELLS_NEXT_HANDOFF.md (cells focus, his directive).
This file stays as the record of sessions 1–2.**

**SESSION 2 (2026-08-26, "everything crashed" turned out to be
nothing — stack was healthy, the arcs just had NO NAV APPS):**
- Nav apps seeded MODULE-LOCAL (climate_app pattern):
  `computers/computers_app.py` → app-computer-assembly,
  `cntfet/cnt_app.py` → app-microchips; two seed passes added in
  polariServer.py after AppsNavSeed. 14 apps live-verified.
  ⚠ polariServer.py (a dev-cmpc-1 file) now carries the CHIP
  app's seed pass too — flag at the commit split.
- **cmp-c-6 BUILT** (his directive: visual part selection +
  viable-interconnect mappings + comms parts embedded/usb +
  usb-enablement parts): computers_ports.py (Interconnect-
  Definition + ports_provided/required engine + port-budget
  gates), PART_KINDS +comms/+usb-expansion, API interconnects
  routes, page row 3, selftests 30/30 + 14/14. Deployed live via
  docker cp + restart (code is BAKED in the image — no repo
  mount; host tree = source of truth, next pol rebuild
  converges).
- **cmp-c-7 = the visual workbench, PLANNED not built** (plan
  §8): reuse no-code Slot/Connector layers or topology-graph-view
  + sim-space-selector palette; it is ANGULAR work and the
  angular tree currently holds dev-chip-1's uncommitted set —
  branch it at/after his commit split.
- File-set delta for the split: dev-cmpc-1 grows
  computers_app.py, computers_ports.py, computers_{seed,api,
  gates,pages_seed,selftest}.py edits, computerparts/parts_basis
  .py; dev-chip-1 grows cnt_app.py.

**SESSION 1 DONE (2026-08-25, same day): chip-1 ∥ cmp-c-0..4
BUILT, all UNCOMMITTED on the dev working tree (no-git rule).
Read the plan's BUILD STATUS block + TESTING_OWED §000 first.**

Commit split at his evening go (file sets are disjoint):
- `dev-chip-1`: modules/cntfet/* (incl. the a1/a2 eq.(5) BUG FIX
  — flag in review), AI-Notes/plans/CNT_FET_SIMULATION_PLAN.md.
  PLUS polari-platform-angular working tree (its own dev-chip-1),
  FINAL SHAPE per Dustin's two corrections ("we have no-code
  graphing" → "replace with configurable ones based on the
  original graphs design"): figure replicas are seeded
  **GraphDefinition rows** (SEED_CNTFET_FIGURE_GRAPHS in
  cnt_figures.py, wrapped graphConfig form = Graphs-editor
  round-trip) rendered by the ORIGINAL machinery — angular
  changes: models/graphs/{plotFigure,NamedGraphConfig}.ts extend
  the model layer (long-form seriesDimension/styleDimension/
  error dims, log axes, lazy longForm marks in the same render
  pipeline), graph-definition.service.ts +loadConfigByName,
  NEW generic/named-graph-panel.component.ts (one named
  GraphDefinition + optional dataPath, refusals verbatim,
  settings link into the Graphs editor), registration swap.
  The bespoke figure-chart component was DELETED. Data feed =
  /api/cntfet/figures/{id}/points (long-form rows matching the
  seeded dimensions). charts/sci-xy-chart.component.ts keeps
  small additive marks (errorbar/dash/logX) for its ssp
  consumers + the cnt-2 convergence.
  ⚠ generic-display-components.ts is ALSO touched by unmerged
  dev-cnt-2 (cntfet-iv-chart registration) — both-keep merge, and
  per [[frontend-graphing-capability]], cntfet-iv-chart must
  CONVERGE onto the graphs design at that merge.
- `dev-cmpc-1`: modules/computerparts/ (NEW on dev — ported from
  dev-ai-1 fefe6fd+05c8144, re-wired to dev's inline polariServer
  pattern), modules/computers/ (NEW), polariApiServer/
  polariServer.py, moduleService/module_loading.py,
  modules/polari-modules.json, modules/appstore/planner_page.py
  (cmp-c-5 v1: per-class 'concrete build' pointer to
  /display/computers; planner selftest 13/13).
- Shared docs (either branch): TESTING_OWED.md, this file,
  COMPUTER_COMPOSITION_PLAN.md.

**SESSION 1 AFTERNOON (his day directives, autonomous)**: figure
replicas (/api/cntfet/figures — proofing graphs on the cited
papers' own axes; refusing entries name undigitized figures);
cell-1 (cnt_cell_library.py: data-driven cells, generated
variants, NOR2, multi-cell Liberty, D11 crosscheck REAL — OpenSTA
v3.1.0 live via docker wrapper ~/.local/bin/sta); pol-core
cleanup 96%→62%; all-3-device probe; distribution + cell roadmap
+ chip-4 correspondence = CHIP_COMPUTE_DISTRIBUTION_PLAN.md
(4 new decisions §6). All still UNCOMMITTED, dev-chip-1 file set
grew accordingly (+ cnt_figures.py, cnt_cell_library.py).

Next build steps: cell-2 (lctime executor for DFF setup/hold,
AOI/OAI, x4, energy tables), cell-3 (parasitic grade-up),
dist-1 (engine-worker package + CNTFET_WORKER_HOST ssh
dispatch), cmp-c-5 (dl-6 planner links), composition
materialization (assembly.node_ref), chip-3 (S6), chip-4 seam
(deferred — but the §5 correspondence table is its ratifiable
contract).

---- Original planning handoff below ----

Entry point AFTER Dustin's dev push of the downloads arc.
Governing plan (READ FIRST): AI-Notes/plans/COMPUTER_COMPOSITION_PLAN.md
— PLANNING RATIFICATION PENDING (his 4 decisions at the bottom).

## The ask, verbatim-close

Continue microchip functionality AND, in parallel, computer
composition as its OWN app — assembly + components SEPARABLE from
microchip creation/levels. Components: storage (HDD/SSD), graphics,
RAM, etc. Computer PROFILES per use-case: standard user ·
assistive-AI dedicated · high-capacity storage bound to dedicated
databases · FPGA · more as data. Assess against what exists.

## Where to start

1. Get his answers to the plan's 4 decisions.
2. cmp-c-0 survey (computerparts + composition seams) on
   dev-cmpc-1; chip-1 (F3 Poisson) on dev-chip-1 — parallel
   branches, separate modules, never crossed.
3. Existing assets: modules/computerparts (ai-8 — dated parts,
   builds, assembly checks), modules/composition (arch — EBOM,
   derived levels, DFA gates, seed_upsert), cnt arc on dev
   (cntfet/microchip/hwdigital/hwfpga), dl-6 planner perf classes,
   ai-6 hosting gauge, object-ownership/databases arc for the
   DB-binding profile.

## Standing context

- Downloads arc dl-1..9 + off-1 machinery CONSOLIDATED on dev
  (framework 9d4e3cb, rf-node bb10455, Isle-Mesh a5a7667, suite
  dev) — his push via ./push-all-dev.sh (suite-root wrapper →
  polari-cli/shells/push-all-dev.sh) --with-isle --push.
- Preview server (threaded) http://192.168.0.210:8090/downloads.
- Gates untouched: framework dev-nmp-1 (nutrition), angular
  dev-cnt-2, dev-dyn-1 merge (unblocks dl-4 admit wiring).
- Dustin's open queue: TESTING_OWED item 18 (installs, browser
  passes), offline decisions 3+4, dyn merge.
