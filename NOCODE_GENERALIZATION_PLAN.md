# No-Code Generalization — Judicial Graphs + Circuit/FPGA/MCU Ladder (ncg-0..6)

## PICK UP HERE (2026-07-16) — ncg-0 ✅, ncg-1 ✅, ncg-2 built+selftested, live verify in flight

- **ncg-0 ✅ BUILT+VERIFIED** (framework branch dev-ncg-0-nocode-matrix, uncommitted):
  `testing/nocode_checks.py` (per-node variant sweep, 36 classes 0 drift; ts-parity
  callable), catalog rows + blocking overrides, `selftest_nocode_matrix` 20/20,
  spine 39/39, audit doc re-stamped. Full matrix ran DISTRIBUTED across the three
  machines (workstation + isle-core + lightweight, ~/ncg-matrix checkouts): all
  categories blocking_green; found + fixed acct-1 selftest env-coupling
  (restart-probe assertion on substrate-less hosts); found PRE-EXISTING dev failure
  selftest:aquaponics.system 12/13 (env-impact scoring) — NOT ncg, needs Dustin.
- **ncg-1 ✅ BUILT+VERIFIED**: `polariNoCode/graph_builder.py` +
  `polariNoCode/graph_compilers.py` (GraphCompilerDefinition, compile_with +
  provenance, advance() orchestrator), `selftest_graph_builder` 14/14;
  turing/composition gates MIGRATED onto the seam (16/16, 12/12 unchanged);
  nocode category 47/47. GOTCHA pinned: unknown conditionType silently → equals
  (it's `greaterThanOrEqual`, never `greaterThanOrEq`).
- **ncg-2 ✅ BUILT + SELFTESTED + LIVE-VERIFIED**: `scoring/court_case.py`
  (CourtCase, N-outcome fork compiler, advance_case edge-routing, case_report),
  routes `/api/scoring/court-cases/{create,{name}/advance,{name}}`, polariServer
  registration + SEED_GRAPH_COMPILERS ('judicial-fork'), `selftest_court_case`
  21/21, nocode category 48/48 blocking_green. LIVE on staging (docker cp +
  restart): a case walked the seeded 'sexual-assault-adjudication-framework'
  through THREE compiled fork graphs on the real engine — pretrial admissibility
  → consent → testimony-sufficiency → ACQUITTAL terminal, illegal determination
  refused with legal outcomes named, full audit trail on the row; smoke 22/22
  after. Live finding folded back: a procedure can carry continuation entries
  (from_fork='' with a named from_outcome, e.g. CONVICTION → sentencing phase) —
  the start edge is from_fork='' AND from_outcome='' (fixed + selftested).
- **ncg-3 ✅ BUILT + SELFTESTED (13/13) + LIVE**: `hwdigital/` — LogicBlockDesign/
  LogicBlockNode rows → python reference evaluator (logic_sim) → generated
  Verilog + SELF-CHECKING bench (expected values FROM the python evaluator —
  two implementations must agree, 24 seeded vectors, REAL verilated runs
  green) → REAL iCE40 synthesis (yosys synth_ice40 → nextpnr-ice40 → icepack
  bitstream + icetime: alarm gate 287.90 MHz, counter 312.50 MHz). Registered
  compiler 'hwdigital-logic' (artifact-only contract). Live: catalogue/
  evaluate/artifact routes verified on staging.
- **ncg-4 ✅ BUILT + SELFTESTED (10/10) + LIVE**: circuits as rows
  (CircuitDefinition/CircuitNetDefinition/CircuitComponentDefinition +
  'circuit-netlist' compiler). THE REGRESSION BAR HIT EXACTLY: row-expressed
  LED branch = hand renderer = 2.6123 mA. Capacitor promoted: RC t63 =
  10.000 ms = τ. Live run on staging: i(vvpin0) = −2.61227 mA.
- **ncg-5 ✅ BUILT + SELFTESTED (12/12)**: breadboards — tie-point
  connectivity IS the netlist, jumpers union nets across boards (union-find,
  ground canonical), board re-wraps as .subckt (board-as-component). Single
  board = two jumpered boards = wrapped-board composition = 2.6123 mA
  identically.
- **ncg-6 ✅ BUILT + SELFTESTED (6/6 bridge + 11/11 packs) + LIVE**:
  PinBindingDefinition (design-output bit → vsource) + drive act — LIVE on
  staging: demo-counter2 LSB blinks the breadboard LED (q=1 lit at
  2.6123 mA all-in-range, q=2 dark), weak-vdd → out-of-range verdict + knob
  suggestion. NoCodeTestCase/NoCodeTestPack + litmus pack (solution 55 +
  circuit current + logic gate — all three domains through one test
  capability).
- **ncg-7 ✅ BOTH HALVES BUILT + SELFTESTED (Dustin 2026-07-16)**: (a) node
  SPLITTING — hwdigital/electrodevice endpoint construction guarded by
  module_enabled; `selftest_ncg_split` 4/4 (two REAL gated boots: a
  hwdigital-only and an electrodevice-only instance each prove full
  presence/absence; the compiler seam stays core). (b) **MODULE OBJECTS** —
  `polariPeers/ncg_module_scopes.py` builds closure scopes per level
  (design→nodes, circuit→nets+components+devices+cards, boards→placements+
  jumpers+bindings, procedure→criteria+edges+votes+ballots, pack→cases);
  `export_module` gained a generic `classRows` scope root (+ fingerprint
  requirements); `selftest_ncg_modules` 11/11 proves the FULL loop: export
  a level as a bundle → dry-run → DYNAMIC LOAD into a running instance
  (import_bundle) → the loaded design EVALUATES on the target → PolariModule
  row records the install → idempotent re-install → remove_module. Rides
  POST /api/modules/export + /api/modules/install (existing peers surface).
- **MULTI-AGENT REVIEW DONE (5 dimension finders, all findings live-verified
  by the reviewers): ~35 findings** — highest: a case fact keyed by an
  outcome label could HIJACK the judicial verdict (engine resolves
  ReturnStatement literals context-first → fixed with a reserved
  __outcome__: prefix + reserved-key refusals, regression-pinned);
  render_board_subckt string-surgery corrupted values/dropped .ends/missed
  canonical nets (rewritten: port mapping at the PIN level through the
  shared placement walk); missing electrical params silently defaulted
  (vsource dc=0!) → now plain errors naming the row+param; drive act
  permanently mutated the authored dc → now transient snapshot/restore;
  malformed test-case JSON silently greened → now fails naming the field;
  empty enabled pack greened → skip-honest; engine failures were blamed on
  the adjudicator's determination → now honest error + retry suggestion;
  per-case advance/create races → per-case locks; payload-validation 500s
  across all new routes → honest 422s; ts-parity trusted exit code alone →
  now requires passed==total; capability drift judged one-directional →
  both directions. Fixes applied by two fork agents (electrodevice /
  hwdigital+packs) + the main session (judicial/seam/testing); every
  selftest extended with regressions.

**Written 2026-07-16 from Dustin's direction. PLANNED — phases are suggestions,
nothing auto-builds.** The goal: generalize the EXISTING no-code engine and its
surrounding machinery so ONE set of code serves both (a) the judicial
adjudication logic diagram and (b) a multi-level circuit no-code (digital logic
for FPGA, breadboard-style SPICE with MCU + FPGA, multi-breadboard scaling) —
with testing-accountability matrix integration throughout, and standing
regression proof that the old no-code and the judicial client keep working.

Companions (read before building a phase):
- `political-scorecard-node/JUDICIAL_ADJUDICATION_GRAPH_PLAN.md` — the judicial
  design + engine gotchas (slot-order branching, `from_dataset` is a silent
  None, etc.). Its isolation ladder applies to ncg-2.
- `HARDWARE_SIMULATION_PLAN.md` — hwsim-3/led/5 (all built) + hwsim-nocode
  (planned); the register-map-as-data generation pattern ncg-3 extends.
- `NO_CODE_FOUNDATIONS_AUDIT.md` — the engine gap report, now PARTIALLY STALE
  (see corrections below).
- `TESTING_ACCOUNTABILITY_PLAN.md` — the standard testing protocol (acct-0..3
  built; acct-4..6 specified). ncg-0 implements the acct-4 sliver; ncg-6 seeds
  acct-6. Coordinate: ONE implementation, not two.

---

## 0. Corrections to stale assumptions (verified 2026-07-16)

- **The audit's two worst gaps are CLOSED.** `SolutionExecutionEngine` now has
  real loop execution (loop-frame stack, back-edges) and first-class
  `SolutionInvocation` composition with a recursion-depth guard and a
  definer-vs-invoker rights field. Evidence run today on dev:
  `python3 -m polariNoCode.selftest_turing` **16/16** (iterative + recursive
  Fibonacci, the standing Turing litmus) and
  `python3 -m polariNoCode.selftest_composition` **12/12**. `FunctionCall` is
  retired loudly (points at SolutionInvocation).
- **P5 (the TS engine mirror) is COMPLETE and ON DEV — Dustin committed it
  himself** (framework fbd270d / angular f1271e7 lineage). Verified
  2026-07-16: the shared parity vectors (`polariNoCode/parity_vectors/`,
  19 files) pass on BOTH engines — `python3 -m polariNoCode.selftest_parity`
  **69/69 (Python)** and `npm run parity` **69/69 (TypeScript)**, covering
  loops, break/continue, collections, conditionals, SolutionInvocation, and
  AwaitBackendCall. Consequence for ncg: every NEW node family must either
  ship parity vectors for both engines or be DECLARED backend-only via the
  capability partitioning in `solution-engine/capability.ts` — never silently
  diverge.
- **Arbitrary components via no-code EXIST**: `polariApiServer/
  createClassAPI.py` dynamically creates + registers classes (CRUDE routes,
  state-space eligibility, inheritance) — the hwsim-nocode chain's first link.
  ncg-4/5's component/board classes should ride this where a USER defines a
  new component kind, with hand-authored classes reserved for the seeded
  standard library.
- **The judicial plan's central finding STILL HOLDS**: no pause/resume inside
  one execution. The many-small-complete-graphs + external orchestrator
  pattern remains the design for anything human-paced or device-paced.
- **Circuits today are NOT data.** `electrodevice/spice_run.py` renders
  netlists from hand-coded Python (`render_led_grid_netlist`,
  `render_switch_netlist`). Promotion to no-code (ncg-4/5) means circuits
  become rows/graphs compiled to netlists — same move the register map already
  made for Verilog/firmware in `hwfpga/`.

## 1. The generalization thesis (what is shared)

Both domains independently converged on the same two-part shape; ncg makes it
one named seam instead of two copies:

1. **Domain rows → compiled small graphs/artifacts.** Judicial:
   `LogicForkCriterion` + resolved criterion → a per-fork `SolutionDefinition`.
   Hardware: `RegisterDefinition`/`FieldRegisterBinding` rows → Verilog,
   firmware, harnesses (proven in hwsim-3). Circuits: component + net rows →
   SPICE netlists (ncg-4). One **compiler contract**, many domain compilers.
2. **Orchestration OUTSIDE the engine.** `advance_case()` steps a court case
   between judge/jury inputs; the hardware loop steps between telemetry and
   commands; a circuit sweep steps between operating points. All are the
   `evaluate_stage_gate` pattern: many complete executions, state persisted on
   a domain row between runs.

Standing rules apply everywhere: every capability is a knob + evidence-bearing
suggestion (never auto-applied); every capability maps to an object-tree node
configurable at the object; files stay small and split by concern; repos are
PUBLIC — no secrets in configs, netlists, or generated code.

## 2. Testing integration (the standard protocol, applied)

The accountability spine (acct-0..3, built) is the ONE reporting surface:
discovery-driven `testing/check_catalog.py`, matrix rows with
category/criticality, `python3 -m testing.run_matrix`, blocking vs
informational vs skip-honest. Rules for this workstream:

- **Every ncg phase ships a selftest** (in-memory manager where possible, live
  where the claim is live) that check discovery auto-registers as matrix rows.
  New categories: `nocode` (exists in spirit via acct-4 spec), `circuit`,
  `hwdigital`.
- **Regression gates pinned as blocking rows** (the "old no-code still works"
  guarantee, run before AND after every phase): selftest_turing (Fibonacci
  litmus), selftest_composition, selftest_parity (Python 69/69), the TS-side
  `npm run parity` (69/69 — needs a runner row that can reach node/npm, else
  skip-honest naming the command), selftest_display_flow, selftest_matrixop,
  selftest_engine_model_op, selftest_pendulum_embed, plus live:api-smoke
  22/22 unchanged.
- **Variant sweep row per node type** (acct-4's design): editor-authorable
  classes vs engine-executable classes, each node type a live row
  (executes-real / executes-stub / no-handler). New node families from ncg-3/4/5
  land INSIDE this sweep on arrival — drift between palette and engine stays
  permanently visible, including for circuit nodes.
- **Judicial as the generalization litmus** (Dustin's directive): ncg-2's
  selftest becomes a standing matrix row; every later ncg phase must leave it
  green. If generalizing for circuits breaks the judicial client, the matrix
  says so before a human does.
- **skip-honest** for anything needing heavy workers (Renode/Verilator/ngspice
  containers down ⇒ named skip with the compose file in the suggestion, never
  silent green).
- NOTE: acct work is STOPPED per Dustin pending review of acct-0..3. ncg-0 is
  the acct-4 sliver — confirm with Dustin that building it inside ncg is the
  intended resumption, so acct-4 isn't built twice.

## 3. Phases (branch per phase off dev, selftest green, matrix rows live)

### ncg-0 — baseline pinning + no-code matrix registration (S) [acct-4 sliver]
Register the existing seven+ polariNoCode selftests as catalog rows; pin
Fibonacci as the standing Turing litmus row; build the editor-vs-engine variant
sweep row per node class; re-stamp `NO_CODE_FOUNDATIONS_AUDIT.md` with a
2026-07-16 "state now" section (P2/P3 done, what of P1/P4/P5/P6 remains).
Acceptance: matrix answers "which node types execute for real, right now" with
evidence; all regression gates green and blocking.

### ncg-1 — the shared graph-builder + compiler seam (M)
- Promote `selftest_composition.py`'s proven `node()/solution()/entry()/
  var_src()/lit_src()` helpers into a supported module
  (`polariNoCode/graph_builder.py`) — the ONE way domain code hand-builds
  `SolutionDefinition`s. Selftests migrate to it (regression: byte-identical
  definitions or identical traces).
- Define the **compiler contract**: a domain compiler is
  `compile(domain_rows) -> SolutionDefinition (+ generated artifacts list)`,
  with provenance stamped on the output (what rows, what versions) and a
  cached-compile invalidation rule. Registry object (`GraphCompilerDefinition`
  treeObject) so compilers are object-coherent and discoverable.
- Define the **orchestrator idiom** as a documented, tested helper (not a
  framework): persist-context row + advance(input) → execute → route on
  outcome → persist. `evaluate_stage_gate` and ncg-2's `advance_case` are its
  two instances.
Acceptance: selftest for the builder + a toy compiler; existing selftests
still green through the migration.

### ncg-2 — judicial client on the seam (M) [the generalization proof]
Execute `JUDICIAL_ADJUDICATION_GRAPH_PLAN.md` AS a ncg-1 client: `CourtCase`
treeObject, per-fork compiler (via graph_builder), `advance_case()` (via the
orchestrator idiom), court-case API routes. Honor that plan's isolation
ladder: checkpoint commit on dev (ASK DUSTIN FIRST — standing rule), then
`dev-ncg-2-judicial`. Selftest with in-memory manager walks a whole case
(multiple forks, judge input between runs, terminal outcome + audit log);
matrix row `nocode:judicial-adjudication`, blocking from ncg-3 onward.

### ncg-3 — digital-logic no-code for the FPGA (M–L)
A **logic-diagram node family that compiles to Verilog** through hwfpga's
existing generation surface (the register map made HDL from rows; this makes
LOGIC from rows): gate/flop/counter/comparator/MUX/decoder node types,
authored in the same D3 editor, wired ports = typed slots. Compile:
LogicBlockDefinition rows → a Verilog module + self-checking bench (generated,
like hwsim-3's) → verilated .so attachable behind Renode. The digital-level
semantics are DIFFERENT from solution execution (combinational/clocked, not
step-walk) — the editor and rows are shared, the compiler targets HDL, and a
slow-motion trace mode MAY reuse the engine for teaching/debug (suggestion,
not the sim path). FieldRegisterBinding (hwsim-nocode item 1) rides along so
new logic blocks reach firmware without hand-written C.
**iCE40 is the synthesis target (Dustin, 2026-07-16)**: generated Verilog
must pass BOTH rungs — Verilator (sim, behind Renode, as hwsim-3 proved) AND
a real `yosys -p synth_ice40` → `nextpnr-ice40` → `icepack` flow; the full
toolchain is ALREADY ON DISK (~/tools/oss-cad-suite: yosys, nextpnr-ice40,
icepack, icetime). Acceptance grows one leg: the compiled design synthesizes
for iCE40 with timing reported (icetime), as a matrix row (skip-honest when
the toolchain dir is absent).
**The C side already exists, narrowly and correctly (Dustin's recollection
CONFIRMED)**: `grpcbridge/c_twin.py` (grpc-j3) generates per-class
`<class>_packets.h` — struct in tag order + encode/decode — i.e. "objects as
structs to the microcontroller", and hwsim-3 generates firmware C defines +
register I/O from RegisterDefinition rows; the MCU↔FPGA conversation is
those generated registers. ncg-3 does NOT invent a C generator: it composes
c_twin headers + register defines + (hwsim-nocode) generated binding
dispatch, keeping the one narrow C idiom.
Acceptance: author a small design (e.g. 2-bit counter driving the LED grid)
entirely through APIs/editor; generated bench green; verilated run live behind
Renode; matrix rows `hwdigital:*`; judicial + Turing rows still green.

### ncg-4 — circuit components promoted to data (M)
- `CircuitComponentDefinition` (kind, pins, parameters, SpiceModelCard ref) +
  `CircuitNetDefinition` (nets as edges) — circuits become graph DATA; a
  data-driven netlist generator replaces the hand-coded renderers.
  Regression: 'fpga-pin-led' re-expressed as rows must reproduce the proven
  currents (2.6123 mA legs) before the old renderer is retired.
- **Promotion protocol per component kind** (the standard ladder, hwsim-5):
  msci-derived or literature-record parameters → versioned SpiceModelCard with
  provenance + validator agreement checks; derived numbers never silently
  replace records. Promote in order: R (exists) → C (dielectric sol-gel rows)
  → diode/LED (DFT frontier-orbital rows) → transistor. Each promotion = rows
  + model card + one runnable example circuit + selftest legs (real ngspice).
Acceptance: matrix category `circuit` with per-kind rows; capability-honest
when ngspice absent.

### ncg-5 — breadboard level + multi-breadboard scaling (M–L)
The circuit-diagram no-code humans actually recognize:
- `BreadboardDefinition` (size, power rails, tie-point rows — connectivity is
  the breadboard's native "nets"), `ComponentPlacement` rows (component ref,
  tie-points occupied, orientation). Netlist GENERATES from placements —
  breadboard connectivity logic (same tie-row = same net, rails span, trench
  splits DIPs) is the compiler.
- **MCU and FPGA are placeable components**: their pins are just nets; the
  Renode/verilated twins behind them stay exactly as built (universal Device
  seam untouched). A placed MCU's GPIO driving a placed LED's anode is the
  fpga-pin-led pattern, positionally authored.
- **Multi-breadboard**: inter-board jumper rows join nets across boards; a
  populated breadboard can be re-wrapped as a subcircuit (.subckt) with named
  external pins — the circuit-world mirror of SolutionInvocation
  (solution-as-state ⇒ board-as-component). Larger circuits = more boards,
  composition stays inspectable per board.
Acceptance: LED-grid demo rebuilt as placements on one board; a two-board
version (FPGA board + LED board, jumpered) sims identically; matrix rows.

### ncg-6 — cross-level integration + authorable tests (M) [acct-6 seed]
- **Level coupling generalized**: digital outputs (ncg-3) drive breadboard
  nets (ncg-5) through a declared pin-binding row (generalizing the LED grid's
  `<register>_pins` trick) — "the FPGA design you drew drives the circuit you
  plugged", with the SPICE verdict (currents in range?) as an
  evidence-bearing suggestion on the design row.
- **NoCodeTestCase/NoCodeTestPack** (acct-6's shape): authorable test cases
  over solutions AND compiled circuits/designs (subject ref, input bindings,
  expected assertions / expected operating points), runner emits CheckRun rows
  into the SAME matrix. Litmus pack includes Fibonacci + one judicial case +
  one circuit — the capability tests itself across all three domains.
Acceptance: author a failing circuit test in the editor, watch the matrix row
red, fix a knob, watch it green — zero Python written.

## 4. Sequencing + branches

`dev-ncg-0-nocode-matrix` → `dev-ncg-1-builder-seam` → `dev-ncg-2-judicial`
(needs the checkpoint-commit confirmation) → then ncg-3 and ncg-4 are
PARALLELIZABLE (different modules, both on the seam) → `dev-ncg-5-breadboard`
(needs ncg-4) → `dev-ncg-6-integration` (needs 3+5). Each phase: selftest
green + matrix rows live + regression gates (Turing/composition/judicial/
smoke) green before the next. Branch per confirmed phase, per standing rule.

## 5. Open questions for Dustin (defaults stated, all knobs)

1. **ncg-0 vs acct review**: acct-0..3 is stopped pending your review — OK to
   build ncg-0 (the acct-4 sliver) now, or review first? Default: review first.
2. **Digital-level editor**: reuse the existing D3 solution editor with a new
   node family (default — one editor, object-coherent) vs a separate
   schematic-style canvas later as a display mode.
3. **Breadboard visual**: rows/placements are the data either way; a 2D
   breadboard widget is frontend work to schedule with you (like the LED grid
   widget in hwsim-nocode item 4).
4. **Component library seeding**: promote only components with an msci
   derivation or a cited literature record (default — provenance-first), or
   allow bare-parameter "sandbox" components flagged as unverified?
