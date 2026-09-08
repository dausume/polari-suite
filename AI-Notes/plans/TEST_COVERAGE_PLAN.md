# Test coverage by app (tcov arc) — the foundation for testing and the Jenkins baseline

**Date:** 2026-09-08 · **Status: tcov-1 + tcov-2 BUILT (same day).** His
framing: "make hierarchies out of [modules and apps] so we can find the
larger apps with significant amounts of modules … identify the apps we
can isolate and choose as the means to efficiently test all of the
modules … go through all modules and look upstream for apps, count the
modules that exist in apps … benchmark the system requirements for these
'largest apps'. For anything larger than a 'standard computer' (2 core,
4 vcpu?) and over standard storage, we do not want to do the testing …
look to see if we can find smaller apps that cover those modules.
Modules that fundamentally cannot be tested without a larger computer …
confirm other docker swarm nodes or isle nodes exist that our testing
suite can access remotely … or confirm we are on a particularly large
computer." And: "this will be a foundation for how we do testing and
eventually a baseline for how Jenkins will operate too."

Companions: STANDARD_POLARI_APP (manifests are the module graph),
CICD_PIPELINE_PLAN §3/§7 (ci-3 runs this plan), the resources module
(ModuleResourceProfile, PolariNodeMachine), polariapps (the app rows).

## 1. The algorithm (`modules/testing/custom/app_hierarchy.py`, pure)
1. **Graph** from the 49 `polari-app.json` manifests: module → requires,
   class count, libraries, engines, kind.
2. **Apps** = seeded/live `PolariAppDefinition` rows (18 today) + topology
   instances (ModuleAssignment sets, kind `instance`) + one singleton per
   module (`module:<id>`, the smallest app that covers it). Each app's
   **closure** = its modules plus everything they require, transitively;
   unknown names (e.g. `materialsScience`, `simulations`, `polariNoCode`
   — not registry ids) are kept aside and shown, never dropped.
3. **Upstream index**: module → every app whose closure contains it;
   **largest apps** = by closure size (app-magnetics 10, app-mechanical
   10, nutrition-planner 8, wax-print-shop 7 …).
4. **Estimate or benchmark** per app against the
   `StandardComputerBudget` row (D1: cores 2, vcpus 4, RAM 4096 MB, disk
   32768 MB — PLACEHOLDERS on the row). Estimate = declared constants
   (base RAM + per-class RAM, base boot + per-class boot, image + wheels
   + engine images, threads from engines) labelled `declared`; an
   `AppBenchmark` row for the app wins and is labelled `benchmark`.
5. **Set cover**: among apps that FIT, greedily pick the one covering the
   most still-uncovered modules per estimated MB; then singletons for the
   rest. Verdict per module: `covered-standard` (tested through the
   chosen app) · `covered-distributed` (exceeds the budget; a swarm/isle
   node with enough RAM/CPU/disk exists — named) · `covered-large-host`
   (this host is large enough) · `uncovered` (nothing can take it).
   Every verdict carries its reason and the budget it cites.
6. **Nodes**: `docker node ls` (never this host) with specs over ssh
   through the alias in `pol-build/manifests/nodes.yml` (swarm hostnames
   are not the aliases); in the backend, `PolariNodeMachine` rows.

## 2. The benchmark (`modules/testing/custom/app_benchmark.py`)
Boots the backend with `POLARI_MODULES = the app's closure` in a
one-off container **held to the budget's cgroup limits** (`--cpus`,
`--memory`) on the host checkout, sqlite, no Keycloak; measures boot
time to `/api/health`, peak RSS (docker stats samples), class inits,
OOM-kill, image + code size; writes
`.generated/test-coverage/benchmarks/<app>.json`; `POST
/api/testing/coverage/benchmark` turns it into an `AppBenchmark` row.
A failed boot under the budget IS the answer "does not fit".

## 3. Surfaces
- Rows: `StandardComputerBudget` (seeded), `AppHierarchyNode`,
  `ModuleCoverage`, `AppBenchmark`, `TestCoveragePlan` (written by
  `POST /api/testing/coverage/recompute` — object coherence).
- API: `GET /api/testing/coverage` (+ `/apps`, `/modules`, `/nodes`),
  the two POSTs. Page `/display/test-coverage` (configured tables +
  structured panels). The `testing` module is opt-in (`POLARI_MODULES`
  must name it) — test builds only, as before.
- CLI: `pol modules testplan plan|apps|nodes|json|benchmark <app>|--all|selftest`.

## 4. First results (2026-09-08, declared model + one benchmark)
- 49 modules, 18 seeded apps; largest closure 10. Under the placeholder
  budget every module is `covered-standard`: 8 apps + 23 singletons
  chosen (many modules are in NO seeded app — the singleton is the
  honest carrier, and the list of them is the to-do for app authors).
- Nodes visible from pol-core: isle-core (6 cpu / 7.7 GB), econ-core
  (4 cpu / 7.6 GB); this host 4 cpu / 15.9 GB.
- Benchmark `app-magnetics` (10-module closure) under 4096 MB / 4 vcpus:
  see the row (boot seconds, peak RSS) — the first `benchmark`-fidelity
  estimate; the declared per-class constants get calibrated from it
  (tcov-3).

## 5. Phases
- **tcov-0** design ✅ · **tcov-1** graph + plan + rows + API + page ✅ ·
  **tcov-2** benchmark runner ✅ (one app measured).
- **tcov-3** calibrate: benchmark the largest apps + every singleton
  the plan chose (`benchmark --all`), fit the per-class constants from
  the measurements, record fidelity per app; his D1 numbers on the
  budget row.
- **tcov-4** the test runner ON the plan: for each chosen app, boot it
  under the budget and run the selftests of every module in its closure
  (`pol modules selftest`), report per module; `covered-distributed`
  modules run on the named node over ssh (the deploy.sh idiom);
  `covered-large-host` only when the host qualifies; `uncovered` is a
  named refusal.
- **tcov-5 = ci-3**: Jenkins runs tcov-4 as the test stage of
  `polari-dev-build`/`polari-release` (the retention/lock rules already
  bound it); results become `CheckRun` rows through the accountability
  API — the Jenkins baseline he named.
- Decisions: D1 the budget numbers (cores/vcpus/RAM/disk/boot timeout);
  D2 whether topology instances count as apps for coverage (default
  yes); D3 whether a singleton may be chosen at all or every module must
  belong to a real app (default: singleton allowed, reported).
