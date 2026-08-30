# Architecture level — from cells to "can this be a PC?" (arch arc)

**STATUS: PARKED (Dustin 2026-08-30) — priority is FET/cell flush-out, then the generic
FET pages + 2-D sim spaces (FET_GENERIC_PAGES_PLAN). Revive after those land.**

Drafted 2026-08-30 after Dustin's ChatGPT-assisted exploration of connecting the
FET → cell data up to whole-chip questions. Goal of the whole line of work: an
**open-source microchip at all** — so every number here is either DERIVED from our
own characterized data or CITED to an evidence row (standing rule, memory
`derive-or-cite-chip-data`). Nothing on these pages is asserted.

## 0. Division of levels (ratified 2026-08-30)

| level | page | owns | feeds up |
|---|---|---|---|
| 1 FET | `cntfet-score-{d}` / detail | device physics at its OWN Vdd (Ion/Ioff/SS/gm/Cg, validity, IP) | primitives |
| 2 cell | `cntfet-cells`, open library | switching performance: FO4, transition energy, leakage per cell (`cnt_fo4`) | FO4, E_trans, P_leak, area stand-ins |
| 3 architecture | **NEW** `arch-home`, `arch-target-{t}` | CPU-level estimates: clock from FO4 × pipeline depth, cores × leakage, energy/op; named gaps | the honest "PC-class?" answer |

Each level REFUSES upward when the level below has no data (no characterized library
on the target rung → no clock number, a refusal that says which POST fills it).

## 1. Inputs already live

- `GET /api/cntfet/device/{d}/fo4` — FO4, INV transition energy (measured), clock
  RANGE for configurable N_FO4 (12/15/20/30), exclusions verbatim.
- `GET /api/sifet/ladder` — rungs with `rights_class` × `fabrication_evidence`;
  `frontier` (FreePDK45), `predictive_frontier` (ASAP7), `manufacturable_frontier`
  (**none**). ASAP7 has NO device rows / library yet.
- `cnt_power` cell/block leakage; `cnt_blocks` (reg4/ctr4/fsm/alu4 with OpenSTA);
  `cnt_targets` DesignTarget/FETTargetMapping (target-scoped budgets pattern).
- EvidenceItem / TechnologyIPRecord / freedom_proof (US) for citations.

## 2. Phases (agents on disjoint files; integrator wires + deploys)

### arch-0 targets as rows — `cntfet/arch_targets.py`
`ArchitectureTarget` treeObject: name, display_name, isa (`rv64gc`), core_count,
core_class (`ooo-moderate` | `in-order-simple`), pipeline_fo4_band (N_FO4 knob:
20–25 OoO, 30+ simple), target_rung (ladder node name → inherits both axes),
baseline_rung (`freepdk45`), vdd policy (rung's), thread_per_core, l1/l2 sizes as
KNOBS, named_gaps_json. Seeds (Dustin, boxed):
- `rv64-8core-ooo` — **preferred**: 8 × moderately sophisticated OoO cores.
- `rv64-16core-simple` — **easier alternative**: 16 × simpler cores (design /
  verify / manufacture first).
Both carry `comparison_json`: the "$300–500 PC" column, every cell tagged
`cited` (evidence row) or `hypothetical` — no untagged numbers. Selftest.

### arch-1 clock + energy derivation — `cntfet/arch_estimate.py`
`arch_report(manager, target)`:
- clock = 1/(N_FO4 · FO4(rung device)) per band, from `/fo4` of the rung's
  characterized device; **refuses** when the rung has no library (today: ASAP7 →
  refusal names `characterize-cells` on an ASAP7-class device that does not exist
  yet — see arch-3). Interconnect derating as an explicit knob band (1.5–2×,
  cited), never silently applied.
- energy/op ≈ transitions/op (knob, hypothetical until a core exists) × E_trans;
  static = cores × cells/core (knob) × cell leakage at the rung's Vdd (measured
  from the library).
- every field tagged `derived | knob | cited | hypothetical`; `honesty` list;
  `gradeUp` (what would turn each hypothetical into derived).
Selftest with the synthetic Liberty (FO4 0.5 ps → bands).

### arch-2 comparison + named gaps — `cntfet/arch_gaps.py`
Rows for: memory controller + DDR PHY, cache hierarchy, coherent interconnect,
graphics, boot ROM/firmware, I/O — each `NamedGap` with what exists open
(cited: e.g. open RISC-V cores/SoCs as evidence rows with licence + rights_class),
what we would have to build, and which level it gates. The PC comparison table
lives here, derived from arch-1 + cited rows only.

### arch-3 ASAP7-class device rows — `sifet/si_basis.py` (append) + ladder
Reconstruct an `si-nmos/pmos-asap7-class` FinFET pair from the ASAP7 paper /
model cards (BSD-3, cited), derive, characterize the library at its own Vdd on
the engines worker, compare to documented anchors (same `compare_to_anchors`
path as FreePDK45-class). Until this lands the preferred target's clock is a
refusal, by design. `fabrication_evidence` stays `predictive-only`.

### arch-4 pages (integrator) — `cntfet/arch_pages_seed.py` + polariServer
`arch-home` (targets table, ladder frontier strip, PC comparison with tags,
gaps table) and `arch-target-{t}` (clock bands graph from FO4, energy/leakage
cards, refusals as first-class panels). Generic components only
(`api-structured-panel`, `named-graph-panel`, `fet-overview`-style card for the
target). Backfill script covers the new pages. Runbook step.

## 3. Decisions for Dustin (defaults stated)

1. Preferred target = 8-core OoO; alternative = 16-core simple (as boxed). ✔ stated.
2. Interconnect derating band 1.5–2× on intrinsic FO4 clock (cited) — default ON
   as a labelled band, not folded into the headline.
3. arch-3 ASAP7-class reconstruction is worth doing even though manufacturable
   frontier is none — it is what lets the preferred target derive instead of
   refuse. Default: yes, after arch-0..2.
4. Baseline comparison always includes the FreePDK45 rung (strongest-evidence
   rights-clean) so "design-able vs make-able" stays visible.

## 4. Gates / order

arch-0 → arch-1 → arch-2 (parallel with arch-3) → arch-4 → deploy → browser pass.
Each phase: selftest green, own commit on dev-fi-1 (or a `dev-arch-1` branch per
the branch-per-phase rule), no push. Deploy = image build + service roll + backfill
(remember: wait for the NEW task ID before probing).

## 5. Explicitly out of scope this round

Writing an RTL core; layout/area from real cells (cell-3 parasitics still stand-ins);
any manufacturability claim (ladder says none); GPU design.
