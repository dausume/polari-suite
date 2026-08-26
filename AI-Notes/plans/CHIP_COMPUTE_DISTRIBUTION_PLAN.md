# Chip compute distribution + cell-stage roadmap (dist / cell arcs)

Written 2026-08-25 (Dustin's directive: "fully building out chip
capabilities … clean up resources and make a plan to distribute
compute load and engines across all 3 [devices] while developing
this, because chips and computers are quite demanding to
simulate" + "fully flesh out the cell stages and their variants …
thinking through how the stages correspond to and will be bound
together with the parts we need for computer assembly").

## 0. Ground truth (probed + measured 2026-08-25)

| device | host | cores | RAM | disk free | today |
|---|---|---|---|---|---|
| pol-core | (this box) | 4 | 15 GB | 43 GB / 117 GB | dev + suite home |
| isle-core | dustin-etts-mesh-core | 6 | 7.6 GB | **832 GB** / 915 GB | isle networking (own Claude) |
| econ-core | dausume-DNB20-series | 4 | 7.5 GB | 193 GB / 234 GB | Odoo |

- **Cleanup done on pol-core**: 96% → 62% disk (45 GB reclaimed:
  23.8 GB docker build cache + 13.6 GB stale images, both 100%
  reclaimable post-purge). Volumes kept (26, 817 MB — Odoo data
  among them); `~/polari-purge-backup-2026-08-17` untouched.
- **⚠ NOTHING is installed on any device** (full purge
  2026-08-17) — this plan doubles as the rebuild topology.
- **The owned Xeon Gold 6338N (32c/64t) is not yet a machine.**
  Until Dustin builds it (`build-xeon-6338n` in computerparts —
  gates all pass), the fleet ceiling is 14 modest cores. The
  distribution machinery below is the bridge; the Xeon is the
  destination F3/S6 workhorse and slot-in replaces isle-core as
  worker #1 with zero plan changes (it's just a bigger
  ModuleAssignment target).

## 1. Workload profile (what is actually demanding)

Measured on pol-core (4 cores):

- **F3 NEGF, fixed potential**: ~0.12 s/energy solve, ~7 s/bias
  point (60 energies, 2816 atoms). Single-threaded per point;
  embarrassingly parallel ACROSS bias points.
- **F3 self-consistent Poisson (chip-1, new)**: ~2 min/2 points
  at reduced knobs; plan prior = min–tens-of-min per point at
  full settings. Same parallel shape (continuation chains within
  a sweep, so the unit is a per-Vd curve, not a single point).
- **S3 Monte Carlo**: pure-python per-sample; trivially parallel.
- **Cell characterization (S5b, new)**: independent ngspice
  transients — arcs × grid × variants (the 2-cell × 2-drive
  selftest sweep is ~50 transients); process-level parallel.
- **S6 synthesis (queued)**: yosys/nextpnr runs — oss-cad-suite
  is a portable tarball, already in ~/tools.
- **Storage**: result rows are small; the bulk is docker images +
  model artifacts + (future) waveform/characterization archives —
  that is isle-core's 832 GB.

## 2. Machinery to ride (built, not rebuilt)

- **ModuleAssignment placement + `pol allocate`** (sep arc):
  which node hosts which module is ALREADY row-truth; POLARI_
  MODULES derives from it (never --env-add).
- **dyn-1..9 live admit** (dev-dyn-1, ⚠ UNMERGED — Dustin's
  merge gate): admit a new device + place modules at runtime.
- **Dask companion stack** (`polari-rf-node/docker-compose.dask.yml`
  + twin-polari-build.sh; distributed-compute arc proved
  Dask + twins + cross-instance).
- **res arc** observed-resources inventory + the ai-6 verdict
  ladder (a dispatch target without OBSERVED resources refuses).
- **D14 subprocess isolation**: the kwant worker already speaks
  one-JSON-in/one-JSON-out on stdin/stdout — it is remotable
  WITHOUT code surgery.

## 3. Distribution plan (dist arc)

- **Roles**: pol-core = orchestrator + interactive node +
  source of truth. isle-core = engine worker #1 + bulk artifact
  store (its 832 GB). econ-core = engine worker #2, Odoo
  co-tenant (nice/cpu caps; Odoo keeps priority).
- **dist-0 rebuild baseline**: GETTING_STARTED_DEV on pol-core
  (suite up), isle bootstrap on isle-core per its own Claude —
  coordination note: isle NETWORKING stays isle-core's domain;
  we only place polari engine workers there.
- **dist-1 engine-worker package**: one deb/app
  (`polari-engine-worker`) bundling the kwant venv recipe,
  ngspice-46, openvaf, oss-cad-suite pointer + the worker
  scripts. Ships via the isle apps machinery (dl-7 app-deb
  generator exists). v1 dispatch = the EXISTING JSON protocol
  over ssh: a `CNTFET_WORKER_HOST` knob makes cnt_kwant run
  `ssh <host> <venv-python> kwant_worker.py` instead of the
  local venv — refusal (host unreachable / venv absent) rides
  the capability report like every other absent engine.
- **dist-2 sweep fan-out**: Dask overlay for MC populations,
  F3 bias sweeps (unit = one continuation chain) and
  characterization grids — scheduler on pol-core, workers on
  isle-core + econ-core (docker-compose.dask.yml).
- **dist-3 data placement**: result rows stay in the node DB;
  bulk artifacts (Liberty archives, waveform dumps, digitization
  renders, image registry mirror) go to an isle-core store
  (Isle-Mesh store plumbing). sqlite is LOCAL BY CONSTRUCTION —
  anything shared rides the API or the store, never a shared
  file.
- **dist-4 placement truth + honesty**: engine workers appear as
  ModuleAssignment rows; the capability endpoint reports WHERE
  each fidelity would run; dispatch refuses (never silently
  runs local) when the declared worker is absent — the
  cmp-c db-binding profile's declare-then-verify shape, applied
  to compute.
- **Gates/blockers**: dev-dyn-1 merge (live admit); KC rotation
  only if any of this leaves the LAN; the no-git-during-work
  rule holds throughout.

## 4. Cell-stage roadmap (cell arc) — "fully flesh out"

- **cell-1 ✅ BUILT 2026-08-25**: `cnt_cell_library.py` — cells
  as DATA (device-list topology rows), variants GENERATED
  (drive xN = N parallel devices, never hand twins), NOR2 added
  (the D10 set's missing mirror), `characterize_cells` sweeps
  every combinational arc (non-controlling ties as data) into
  ONE multi-cell NLDM Liberty, and the **MANDATORY D11
  SPICE-vs-STA composed-path cross-check** runs against the
  REAL OpenSTA (docker `openroad/opensta` behind a
  `~/.local/bin/sta` wrapper — no sudo build needed).
  CNTCellDefinition rows registered + seeded;
  `/api/cntfet/cell-library`; actions `characterize-cells`,
  `d11-crosscheck`. **First D11 numbers: SPICE 0.900 ps vs STA
  1.126 ps on the INV→INV path (+25%, tolerance 35%,
  PASS)** — two emitter gotchas caught live and fixed: Liberty
  without `delay_model : table_lookup` silently times NOTHING
  (defaults to generic_cmos, arcs listed but no arrivals), and a
  clockless netlist needs a virtual clock + zero I/O delays
  before report_checks sees any path.
- **cell-2**: sequential characterization — lctime executor
  (AGPL, absent-by-default, D14 knob) for cdff setup/hold;
  richer combinationals (AOI21/OAI21, TG mux); x4 drives;
  energy-per-transition tables from the same transients.
- **cell-3**: parasitics grade-up — [VS2] junction capacitance
  replaces the labeled 2 aF standins; characterization results
  re-graded (the honesty strings already say intrinsic-grade).
- **cell-4**: the microchip ladder's CELL rung flips
  'unbuilt' → 'characterized' as a DATA update, citing the
  library result rows; ring-oscillator + cells pages get the
  figure-replica treatment.
- **cell-5 (distribution tie-in)**: characterization sweeps are
  the first dist-2 tenant — grids fan out per-arc.

## 5. Ladder ↔ computer-parts correspondence (the chip-4 design)

Thought through NOW as design; built LATER (decision 4 kept:
one interface table, no shared code paths).

| microchip ladder rung | computers/computerparts side | binding |
|---|---|---|
| device (cntfet) | — no purchasable part; materials/process domain | none |
| cell (library) | — feeds every part below; no direct part | none |
| block: memory array | `ram` / `storage` (controller) part classes | chip-4 declaration |
| block: SIMD/GPU block | `gpu` part class | chip-4 declaration |
| block: FPGA fabric | `fpga-accelerator` part class | chip-4 declaration |
| block: MAC/PHY | `nic` part class | chip-4 declaration |
| core (RV16X-NANO precedent) | `cpu` part class | chip-4 declaration |
| chip (packaged) | the purchasable part ITSELF | chip-4 declaration |

**The load-bearing design decision**: the computers taxonomy's
`declared_specs_json` vocabulary (vram_mb, capacity_mb, luts,
speed_gbps, cores, …) IS the chip-4 declaration schema. A
chip-ladder artifact reaching component maturity declares
`fulfills: <part_class>` + specs in THAT vocabulary — so the
assembly gates and profile fits score a designed chip exactly
like a purchased part, with `condition: 'designed'` and honest
`unverified` for anything simulation cannot yet state (yield,
price). cmp-c-1 therefore already built half the seam; chip-4 is
one table + one status field when a block-level artifact exists.

## 6. Decisions for Dustin

1. dist-1 worker transport v1: ssh dispatch (recommended — zero
   new infra) vs straight-to-Dask?
2. econ-core participation: engine worker alongside Odoo
   (nice-capped) or data-replica only?
3. OpenSTA: keep the docker wrapper (works today, v3.1.0) or
   native build once you can sudo apt the deps?
4. Ratify the §5 correspondence as the chip-4 contract shape.
