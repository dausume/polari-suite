# Testing Accountability — Plan (acct-0..6)

**Written 2026-07-11 from Dustin's directive. STATUS: PLAN ONLY —
nothing built. Ordering (Dustin): FIRST base functionality +
cross-instance + database/transport integrations (acct-0..3), THEN
no-code capability + engines (acct-4..5), THEN unit-testing VIA
no-code — the capability to test modules (acct-6).**

**TEST-BUILD GATING (Dustin 2026-07-11): test objects are loaded and
run ONLY in dedicated test builds — never in normal runtime.** All
of acct-0..6 lives in a `testing/` module that is simply absent from
a normal build's `POLARI_MODULES`: no CapabilityCheck/CheckRun/
NoCodeTestCase classes registered, no tables created, no
/api/accountability route, no frontend page, zero test machinery in
production images. A TEST BUILD (compose profile + env knob, the
Dockerfile.test lineage) includes the module and runs the full
matrix — "full test suite" is a build target, not a runtime mode.
The frontend Testing page registers only when the class directory
reports the testing module (the modsplit directory idiom), so a
normal frontend never shows a dead menu item.

Goal: durable, runnable **accountability for critical functionality
and integrations** — not a pile of ad-hoc scripts, but a capability
matrix where every critical seam (KeyDB, MariaDB, SQLite, gRPC,
STOMP, JSON + the specialized JSON formattings, twin-instance module
splitting, no-code Turing-completeness + variants, engines) has a
named check with a live status and evidence. Then: unit testing AS a
no-code capability, so modules can carry their own test packs.

---

## 0. Facts the plan stands on (survey 2026-07-11)

What already exists — the plan REUSES these, never re-invents:

- **66-test container suite** (`run_tests.py`/`testAll.py`, docker
  Dockerfile.test) — object tree, CRUDE, contracts, honesty, sweep,
  createclass, mathshapes, modules-smoke, profiler. Proven identical
  on sqlite AND MariaDB (prf-db-combo 2026-07-09).
- **`tests/test_api_sweep.py`** — the full API-variant sweep (every
  falcon route × method; zero-5xx + CRUDE protocol pin;
  auto-covers future endpoints).
- **`tests/live_api_smoke.py`** — 22/22 live smoke against staging.
- **Per-module selftests** — every module ships one (aqp 133 checks,
  msci, xr 31, nutrition 38, …). The no-code engine has SEVEN:
  `selftest_turing` (P1+P2 repairs; **iterative Fibonacci(20)=6765
  litmus ALREADY EXISTS and passes** — loops/Break/Continue/
  Filter/Map/Reduce were repaired after the 2026-07-03 audit),
  `selftest_composition`, `selftest_display_flow`,
  `selftest_matrixop`, `selftest_engine_model_op`,
  `selftest_parity`, `selftest_pendulum_embed`.
- **`polariNoCode/assertionEvaluator.py`** — evaluates
  `ExecutionStepAssertions` against an `ExecutionTrace`. This is the
  SEED of no-code unit testing (acct-6 builds on it, not from zero).
- **Specialized JSON formats** — `apiFormatConfig.py`: `polariTree`,
  `flatJson`, `d3Column`, `geoJson` (+ STOMP per-format topics via
  `watchChanges(className, formatType)`).
- **Twin/module-split machinery** — modsplit-1..3 (POLARI_MODULES
  gating, class directory w/ wsUrl/grpcTarget, addressable
  tie-break), xsim-1..6 (ref ladder, locks/fencing, agreement-scoped
  reads, remote writes + journal, overlap advisor, **two-instance
  rehearsal — live-proven but MANUAL**; demo m/n containers still
  running). `docker-compose.twin-b.yml`, `docker-compose.dbcombo.yml`
  exist.
- **gRPC bridge** — grpc-1/2 built (:3002 sidecar, MUX, reflection,
  Java sim loop); **grpc-3 (parity measurement + peer↔peer Watch) is
  the stamped next backend workstream** — acct-2's gRPC checks land
  there, not in a parallel effort.
- **NO_CODE_FOUNDATIONS_AUDIT.md** (2026-07-03) — PREDATES the
  P1/P2 engine repairs; its gap table is stale on loops/validation/
  events but still authoritative on: FunctionCall subroutines,
  frontend/TypeScript execution, display event wiring,
  solution-as-generic-state re-wrapping.
- **Accountability page idiom** — msci scale-presence matrix API +
  per-level pages: capability × status × evidence as tree objects
  with a UI. acct-0 generalizes exactly this.

## 1. The accountability spine (the design, [[object-coherence]])

Every check is an OBJECT in the tree, not a line in a log:

- **`CapabilityCheck`** (treeObject): `name`, `category`
  (`substrate | transport | format | twin | nocode | engine |
  module`), `kind` (`in-process | live | compose`), `criticality`,
  `runner_ref` (which callable/selftest/pytest implements it),
  `last_status` (`pass | fail | skip-honest | never-run`),
  `last_evidence` (the assert detail / error / skip reason),
  `last_run_at`, `last_duration_ms`.
- **`CheckRun`** (treeObject): one execution of the whole matrix or a
  category — timestamped, environment-stamped (which DB dialect,
  which containers were up), rows of per-check results.
- **`GET /api/accountability`** — the matrix; filterable by category.
  A frontend page (msci scale-presence idiom) renders capability ×
  status with the evidence inline; "why is this red" is always
  answerable.
- **Knobs-and-suggestions**: checks that CANNOT run in the current
  environment (no MariaDB up, no gRPC sidecar, no twin) report
  `skip-honest` with the reason and a suggestion card naming the
  compose file/knob that would make them runnable — never silently
  green, never silently missing.
- Runners WRAP the existing suites (the 66-suite, api-sweep,
  selftests) — one registration layer, zero test duplication.
- **Pipeline-readable YAML report (Dustin 2026-07-11)**: every
  `CheckRun` also SERIALIZES to a `test-report.yaml` written to a
  stable, volume-mountable path (`test-results/test-report.yaml`,
  plus a timestamped copy per run) so a CI pipeline can read the
  outcome without touching the API. The YAML is a faithful
  projection of the same objects — never a second bookkeeping
  system:

  ```yaml
  run:
    id: <CheckRun id>
    started_at / finished_at: <ISO-8601>
    build: {kind: test, image: ..., git: {framework: <sha>, ng: <sha>}}
    environment: {db_dialect: mariadb|sqlite, containers_up: [...]}
    totals: {pass: N, fail: N, skip_honest: N, never_run: N}
    blocking_green: true|false   # substrate+transport+twin verdict
  checks:
    - name: <CapabilityCheck name>
      category: substrate|transport|format|twin|nocode|engine|module
      criticality: blocking|informational
      status: pass|fail|skip-honest
      duration_ms: N
      evidence: <assert detail / error / skip reason + suggestion>
  ```

  `blocking_green` is the single field a pipeline gates on; exit
  code of the test-build runner mirrors it. Schema changes are
  versioned (`report_version: 1` at the top) so later pipelines can
  evolve without breaking older readers.

## 2. Phases

### acct-0 — the spine + inventory
Build the `testing/` module (test-build-gated, see header):
`CapabilityCheck`/`CheckRun` + `/api/accountability` + the
registration layer; register the EXISTING suites as the first rows
(66-suite categories, api-sweep, live smoke, each module selftest,
each no-code selftest). Acceptance: a TEST build renders the matrix
with real statuses from one `CheckRun`; every existing test surface
appears exactly once; an unrunnable check shows `skip-honest` +
suggestion; a NORMAL build has no testing classes, tables, routes,
or page (asserted — the absence is itself a pinned behavior); the
run emits `test-results/test-report.yaml` (schema above) and the
runner's exit code mirrors `blocking_green`.

### acct-1 — substrate: databases + cache
- **SQLite**: CRUD + auto-table-generation + polyTyping round-trip
  (largely wrapping existing 66-suite tests as named checks).
- **MariaDB**: reachability (ping, credential honesty — the
  wrong-password-boots-healthy gotcha becomes a CHECK), dialect
  parity (the dbcombo proof re-run as a repeatable check: same suite,
  both dialects, identical failures), schema stabilization + OOPS
  round-trip (dev-schema-stability-1 behaviors), shared-object-DB
  boot (`POLARI_SHARED_OBJECT_DB` instance isolation probe).
- **KeyDB (redis protocol)**: reachability + set/get/expire
  round-trip + what the framework actually uses it for (session/
  cache paths) exercised end-to-end, not just PING.
- Restart-persistence probe (volume-backed data survives a container
  bounce) as a compose-kind check.
Acceptance: matrix rows green on staging; unplugging each substrate
flips its row red with the real error as evidence.

### acct-2 — transports + serialization formats
- **JSON/CRUDE**: already pinned by api-sweep — register as checks.
- **Specialized formattings**: per-format pins for `polariTree`,
  `flatJson`, `d3Column`, `geoJson` — for a reference class, each
  format's shape is asserted (golden-shape tests), plus the
  format-specific STOMP topics deliver on change.
- **STOMP**: connect, subscribe, CRUDE-write → change-notification
  round-trip; per-class ws knob (`polariTreeWsEnabled`) honored;
  multi-connection routing per owning backend (modsplit-3 behavior).
- **gRPC**: sidecar reachability + reflection, Push/Watch round-trip,
  JSON↔gRPC parity measurement — **lands as part of grpc-3** (the
  stamped pickup); acct-2 defines the check names + registers them,
  grpc-3 implements the meat. Fencing-token + object-lock gating on
  the gRPC path asserted (the xsim integration notes).
Acceptance: every transport row carries a round-trip proof; format
golden shapes fail loudly on drift.

### acct-3 — twin coherence: module splitting across containers
Turn the MANUAL xsim-6 rehearsal into a repeatable, compose-driven
integration suite (pytest orchestrating docker compose):
- **Boot**: core + m + n from `POLARI_MODULES` splits; class
  directory correct on all three (owning instance, wsUrl,
  grpcTarget).
- **Separation of object concerns**: a module-owned class exists ONLY
  on its owner; foreign-instance direct writes are refused (honest
  refusal, not silent accept); core resolves m's classes through the
  directory.
- **Traversal**: the 4-rung ref ladder walks objects BETWEEN
  instances coherently (local → agreement-scoped peer read → remote
  ref) — same object identity, no duplication.
- **Writes**: automated remote writes with dual-side journal;
  fencing lease + object locks hold under a competing writer; zombie
  fencing (a fenced instance's late write is rejected).
- **Frontend routing** (spec-level): ClassDirectoryService routes
  per-class CRUDE + STOMP to the owning backend.
- **Teardown/exit**: the suite leaves NO demo containers running
  (also: fold the still-running xsim demo m/n containers into this —
  they become the suite's fixtures, not permanent residents).
Acceptance: one command runs split → verify all behaviors → clean
teardown; the matrix gains a `twin` category that is red when any
coherence property breaks.

### acct-4 — no-code capability matrix (Turing + variants)
- Register the seven no-code selftests as checks; **Fibonacci is the
  standing Turing litmus** (already green — keep it pinned).
- **Variant coverage sweep**: enumerate every state class the EDITOR
  can author vs every class the ENGINE executes — the audit's
  34-vs-executable gap becomes a LIVE matrix row per node type
  (executes-real / executes-stub / no-handler), so editor/engine
  drift is permanently visible. Re-audit against the repaired
  engine; the 2026-07-03 audit is stale on loops/validation/events.
- Known-open gaps become named red rows (honest debt, visible):
  FunctionCall/subroutines, frontend/TypeScript execution + display
  event wiring, solution-as-generic-state re-wrapping. Fixing them
  is separate work ([[no-code-foundations]]); acct-4 makes the debt
  countable.
### acct-5 — engines
- Per-engine checks: equation/sympy, matrix/numpy, EngineModelOperation,
  FEM (skfem in-backend), DFT / MD / meso (worker containers), CAD
  workers, Dask scheduler+workers — presence, a smoke evaluation with
  a known-good expected value, and `skip-honest` when the engine's
  container isn't up (with the compose file named in the suggestion).
Acceptance (4+5): the matrix answers "which no-code node types and
which engines actually work RIGHT NOW" with evidence per row.

### acct-6 — unit testing VIA no-code (the module-testing capability)
The audit + design phase Dustin asked to "check on and plan if
needed" — checked: the SEED exists (`assertionEvaluator.py`,
`ExecutionStepAssertions` × `ExecutionTrace`), but there is no
authorable test object, no runner surface, no module packs. Build:
- **`NoCodeTestCase`** (treeObject): subject solution ref, input
  bindings (arrange), expected assertions (the existing assertion
  shapes — act/assert on the trace), tags, owning module.
- **`NoCodeTestPack`**: a module's set of cases — modules become
  testable units; packs ride module packaging like any other rows.
- **Runner**: execute pack → per-case results as `CheckRun` rows in
  the SAME accountability matrix (`nocode` category) — one spine,
  not a parallel reporting system.
- **Editor surface**: author a test case FROM a solution in the
  no-code editor (capture current inputs/outputs as the expected
  baseline — suggestion card, never auto-saved); a Tests tab on the
  module + accountability pages.
- **Litmus pack**: a `polariNoCode` self-pack whose cases include
  Fibonacci — the engine tests itself through its own test
  capability (the recursion is the point: it proves the capability).
Acceptance: author a failing case in the editor, watch it red in the
matrix, fix the solution, watch it green — full loop with zero
Python written by the user.

## 3. Sequencing + branches

Branch per phase off dev ([[branch-per-confirmed-phase]]):
`dev-acct-0-spine` → `dev-acct-1-substrate` → `dev-acct-2-transports`
→ `dev-acct-3-twin` → `dev-acct-4-nocode-matrix` +
`dev-acct-5-engines` (parallelizable) → `dev-acct-6-nocode-tests`.
acct-2's gRPC rows coordinate with grpc-3 (same seam, one
implementation). Each phase: selftest green + matrix rows live +
22/22 smoke unchanged before the next.

## 4. Defaults chosen (say so if any should differ)
Previously open questions — now resolved with stated defaults, all
of them knobs:
1. **Where the results page lives**: a top-level "Testing" menu item
   that only exists in test builds (gating decides visibility, so
   placement is uncontroversial).
2. **When checks run**: only when a test build is launched — no
   scheduling machinery. "Run the full suite" = start the test
   build; it runs the matrix and reports.
3. **How the twin suite gets its containers**: fresh throwaway
   compose instances every run, torn down after (clean over fast).
4. **What a red row means**: substrate, transport, and twin rows
   must be green before a phase is called done; no-code and engine
   rows are visible debt that doesn't block until acct-6 makes them
   testable per module.
