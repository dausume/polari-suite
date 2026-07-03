# GAP REPORT: Polari No-Code Foundations Audit

_2026-07-03. Read-only audit of `polari-framework/polariNoCode/` (engine),
`polari-framework/polariApiServer/` (solution APIs), and
`polari-platform-angular/src/app/` (editor, services, display rendering), commissioned by
Dustin's directive: the no-code should be Turing complete, generate code for backend AND
frontend (display events/validation known-suspect), support re-wrapping solutions into
generic states, and be comprehensive + intuitive._

## Executive verdict

The no-code system is a **single-runtime, straight-line-graph interpreter with real
conditional branching but stubbed loops, no subroutines, and no working frontend execution
or display event wiring**. Roughly **15 of the 34 node types the editor lets you author
have zero execution handler** in the engine — including every frontend/event/validation
node Dustin flagged. "TypeScript frontend" is a label plus dead code-generation; it never
runs. Displays render forms/buttons as static placeholders that fire nothing. It is **not
Turing complete in practice**, and the "solution-as-reusable-state" abstraction does not
exist.

## 1. Turing-completeness of SolutionExecutionEngine

The engine (`polariNoCode/SolutionExecutionEngine.py`) walks a state graph from an initial
node, one node per `while` iteration, capped at `max_steps = 1000` (line 555). Dispatch is
a big `if/elif` on `state_class` inside `_evaluate_state` (lines 677–1332).

Full executable-handler inventory:

| State class | Line | Status |
|---|---|---|
| InitialState / DirectInvocation / SimulationStateStep | 693 | Real (entry logging + param merge) |
| VariableAssignment | 759 | Real (writes `context[var]`) |
| ConditionalChain | 781 | **Real branching** (sets `branch_taken`) |
| ForLoop | 846 | **STUB** — sets `context[iterator]=start`, "full loop execution in v2" |
| WhileLoop | 856 | **STUB** — records condition string only |
| ForEachLoop | 861 | **STUB** — binds `collection[0]` only, no iteration |
| FunctionCall | 871 | **STUB** — `context[result_var]=None` placeholder |
| ReturnValue / ReturnStatement | 880 | Real (terminal) |
| LogOutput | 896 | Real |
| MathOperation | 905 | Real |
| CalculusOperation | 950 | Real (saved EquationDefinition via sympy) |
| MatrixEquationOperation | 1121 | Real (numpy path) |
| SimStepContribution / SimStepNextState | 1194 / 1274 | Real (sim terminators) |
| FilterList | 1318 | **STUB** — "Basic filtering - pass through for now" |
| anything else | 1328 | Pass-through: `"State X - no evaluation"` |

**Conditional branching — EXISTS and works.** `ConditionalChain` evaluates
`links`/`conditions` and sets `branch_taken` (0=true, 1=false; lines 812–817).
`_get_next_state` (1374–1415) indexes the node's output slots by `branch_taken`
(line 1393) and follows that slot's connector. For all non-conditional nodes it blindly
follows the *first* output connector (1408–1414).

**Loops — MISSING in practice.** All three loop nodes are stubs: they neither iterate nor
create a back-edge. The only iteration mechanism is that `_get_next_state` will follow a
connector pointing to an already-visited node — a human could *hand-wire* a cycle
(back-edge + `ConditionalChain` exit + `MathOperation` increment) and the walk loop (559)
re-walks it — but bounded by `max_steps=1000`, and no loop node produces such a back-edge
automatically. `BreakStatement`/`ContinueStatement` exist in the palette with no handler.

**Subroutines — MISSING.** No `SolutionInvocation` exists. The intended primitive is
`AwaitBackendCall` (codegen template `await self.call_solution(...)`,
`solutionCodeGeneratorAPI.py:33`; registry block `StateBuildingBlock.py:516`), but it has
**no engine handler** (pass-through). `SolutionProcessLink` is *not* a call mechanism —
it is a documentation record (manual-process step + code snippet/line-range annotation).
No solution can invoke another at execution time. No recursion.

**Variables / collections — flat.** Context is one flat dict (line 546), no scoping. Lists
can be *built* via the `array` value-source (222–233) and JSON matrices decoded/encoded
(245–271), but there are **no working list-mutation ops**: `FilterList` is pass-through,
`MapList`/`ReduceList` aren't in the engine at all. No dict manipulation ops.

**Verdict: NOT Turing complete in practice.** Present: sequencing, mutable named
variables, arithmetic, predicate branching. Missing: (a) working iteration/back-edges
from loop nodes, (b) subroutine/recursion, (c) unbounded execution (hard 1000-step cap),
(d) mutable collections. Hand-wired cycles approximate a *bounded* automaton only.

## 2. Solution-as-state / abstraction (composition)

Essentially absent.

- `SolutionDefinition` — thin record (name, function_name, target_runtime, definition
  JSON). No notion of being embeddable as a node.
- `SolutionVersion` — snapshot record: definition + `generated_code`
  (`{"python":…, "typescript":…}`) + version chaining. Pure versioning; created by
  `solutionVersionAPI.py`, which regenerates code for both runtimes (74–80).
- `SolutionProcessLink` — despite the name, a traceability/annotation object
  (`code_snippet`, `code_line_start/end`, `code_runtime`), not runnable composition.
- `LogicFlowEntry` ("invoked by a parent solution", `StateBuildingBlock.py:211`)
  advertises child-solution composition, but there is no caller side.

**Re-wrapping a solution into a reusable generic state needs:** a first-class
`SolutionInvocation` node (ref + input-param mapping + result binding), an engine handler
running a nested `SolutionExecutionEngine.execute()` and merging return/trace, an explicit
parameter/return **contract** on `SolutionDefinition`, and recursion-depth guards. None
exist today.

## 3. Frontend execution + codegen — the reality

**`target_runtime='typescript_frontend'` does almost nothing at execution time.** It is
only passed to `ExecutionTrace(...)` as a label (line 507); `_evaluate_state` never reads
it. A "frontend" solution executes as the same Python graph walk — and the
frontend-specific nodes no-op through. **No TypeScript execution engine exists.**
`solution-execution.service.ts` POSTs to `/executeSolutionStepped` and replays the Python
trace for the stepping UI (93–162); it does not execute TS.

**Codegen** (`SolutionCodeGeneratorAPI` + `generate_code_from_solution`): emits source
text via per-node string templates — `PYTHON_TEMPLATES` (16–43), `TYPESCRIPT_TEMPLATES`
(45–69). Heavily lossy: unknown placeholders → `...` (154); unknown node classes → bare
comments (307); **CalculusOperation / MatrixEquationOperation / FilterList have no
template** → vanish from generated code; conversely templates exist for `EmitEvent`,
`StateChangeCommit`, `AwaitBackendCall` that the engine can't execute. Codegen and
execution are **different, drifting inventories.** Generated code is returned/stored
(`SolutionVersion.generated_code`) — **never compiled, deployed, or run.**
`/executeSolution` (the UI run-button's endpoint) is codegen-only: comment at
`solutionExecutionAPI.py:87` "Phase 1: Generate code (execution engine to come later)";
returns `status:'code_generated'` and never touches the engine (88–99).

**Source-of-truth sprawl:** node→template knowledge re-implemented in FOUR places —
backend inline maps (`solutionCodeGeneratorAPI.py`), the backend
`StateBuildingBlockRegistry` (its `get_template_map` at 168 is **unused** by
`generate_code_from_solution`), and two full Angular generators
(`python-code-generator.service.ts` 728 lines, `typescript-code-generator.service.ts`
871 lines).

**`DisplayDefinition.linkedSolutions` triggers at runtime: it doesn't.** Read only for
counting/labeling in the editor (`displays.component.ts:100`, `class-main-page.ts:717`).
`solution-invoke-button` (the one component that *can* run a solution) is declared in
`app.module.ts` but **used in zero templates** — and even it calls the codegen-only
`/executeSolution` (`solution-manager.service.ts:183`).

## 4. Display events + validation (the known-suspect area) — broken end-to-end

**Event/validation node kinds authored in the editor** (`state-space-class-registry.ts`):
`FormSubscription` (246), `FormValidation` (544), `InitialConditionsValidatorEntry` (404),
`ValidationResult` (1263), `EmitEvent` (1141), `EmitFrontendEvent` (1452),
`AwaitBackendCall` (1420), `ReactiveTransform` (1387), `StateChangeCommit` (1107),
`BackendStateChange` (312), `LogicFlowEntry` (280) — each with a full editor
model/overlay. **Every one has zero engine handler** (verified by grep — pass-through at
`SolutionExecutionEngine.py:1328`).

**The intended chain** (from `solutionSeedData.py`, `User.detectChanges`, 229+):
`FormSubscription` (watch `userForm$`) → `FormValidation` (per-field output slots, 305) →
`AwaitBackendCall` → `ReturnStatement`. `DisplayItem` (`DisplayItem.ts:7`) supports
`'form'`/`'button'` types with `linkedSolutionName` + `submissionMode` (28–37, 100).

**Actual state:**
- **Rendering is a placeholder.** `dashboard-renderer.html` `'form'` case (37–47): icon +
  literal "Linked to: {name}" — no input fields, no form group. `'button'` case (49–55):
  a `<button>` with **no `(click)` handler**. No `executeSolution` logic in
  `dashboard-renderer.ts` at all.
- **No submit/click → solution bridge exists.** `submissionMode`/`linkedSolutionName` are
  stored and shown, never subscribed or invoked.
- **The engine can't run the authored flow anyway.** Static repro on the shipped seed
  `User.detectChanges`: `FormSubscription` is in `INITIAL_STATE_CLASSES` (54) but untyped;
  `FormValidation` → pass-through, **no validation runs**, and non-conditional
  `_get_next_state` follows the FIRST output connector ("All Valid"), so flow proceeds
  *ungated* regardless of validity; `AwaitBackendCall` → pass-through, the backend call
  never happens; `ReturnStatement` returns "void". The whole "validate then save"
  solution is inert.
- **Hard error:** `InitialConditionsValidatorEntry` is an entry node in the palette but
  **absent from `INITIAL_STATE_CLASSES`** (54–58) → any solution entered by it fails with
  `"No initial state found in solution"` (542). Mismatched editor/engine contract.
- **Terminal mismatch:** `ValidationResult` and `EmitEvent` are authored as end-states but
  not in `TERMINAL_STATE_CLASSES` (61–77) — traversal ends silently; verdicts/events lost.

## 5. Editor comprehensiveness / intuitiveness (palette ↔ engine parity)

Palette = 34 node classes; engine executes ~14 meaningfully.

**Authorable but NOT executable:** FormSubscription*, LogicFlowEntry*,
BackendStateChange* (*recognized entries, untyped), FormValidation,
InitialConditionsValidatorEntry (breaks entry detection), ValidationResult, EmitEvent,
EmitFrontendEvent, AwaitBackendCall, ReactiveTransform, StateChangeCommit, MapList,
ReduceList, BreakStatement, ContinueStatement. **Authorable-but-stubbed:** ForLoop,
WhileLoop, ForEachLoop, FunctionCall, FilterList.

**Executable but weakly authorable:** CalculusOperation and MatrixEquationOperation
execute but have no codegen template (drop out of generated code).

Rough edges: (a) no palette signal that a node is a no-op → users author flows that
silently do nothing; (b) four drifting template/registry sources; (c) ConditionalChain
branch semantics encoded positionally (slot order) in exactly one engine line — fragile;
(d) several node types ship only a `.model.ts` with no overlay editor; (e) the display
run-button maps to codegen, not execution — "Run" appears to succeed while executing
nothing.

## 6. Recommended fix / build phases (ordered, sized)

- **P1 — Parity + honesty pass (S).** Palette tells the truth: tag registry blocks with
  `execution_status` (real/stub/codegen-only), surface in the editor. Add
  `InitialConditionsValidatorEntry` to `INITIAL_STATE_CLASSES`; add
  `ValidationResult`/`EmitEvent` to `TERMINAL_STATE_CLASSES` (or give handlers). Collapse
  the four codegen sources toward one. *Unblocks trust; no new semantics.*
- **P2 — Real control flow → close the Turing gap (M).** Genuine iteration for
  ForLoop/WhileLoop/ForEachLoop (loop-frame stack, real back-edges, exit predicates);
  honor Break/Continue; per-frame iteration budgets instead of the flat 1000-step cap;
  implement Filter/Map/ReduceList + basic dict ops. *Makes "code anything" real.*
- **P3 — Solution-as-state / composition (M–L).** First-class `SolutionInvocation` node +
  nested-engine handler, explicit input/return contract on SolutionDefinition,
  recursion-depth guard, trace nesting; repurpose `LogicFlowEntry` as callee entry.
  *Dustin's re-wrapping abstraction; the key to modularization.*
- **P4 — Display event/validation repair (M).** Real reactive form groups for `'form'`
  items; `(click)` on `'button'` items calling the EXECUTION path with
  `linkedSolutionName` + collected inputs; wire `submissionMode`; engine handlers for
  FormValidation/ValidationResult/FormSubscription/EmitEvent so validation gates flow and
  events emit; `linkedSolutions` drives subscription setup on display init.
- **P5 — True frontend execution runtime (L).** Either a real TS mirror of the engine
  (paired AwaitBackendCall/EmitFrontendEvent on both sides) or formally one backend
  interpreter with `target_runtime` as a capability filter; make generated code actually
  consumed or demote codegen to a reference view. *Do after P2/P3 stabilize semantics.*

Suggested order: **P1 → P2 → P3 → P4 → P5.**
