# Shelved plans — the accountability ledger

**Created 2026-08-20 (Dustin's instruction: shelve the composting
plan and account for everything else shelved).** A plan lives here
when its work has been DELIBERATELY set aside — not merely blocked
on a review gate or a Dustin session. Every entry records what
stands, what is owed, and the revival path, so nothing silently
rots. When an arc revives, `git mv` its plan back to `plans/` and
update this table.

Convention: ⏸ = shelved by decision · ⛔ = shelved as not-fit-for-use
· dates are when the shelving happened, not when work stopped.

## Shelved plans (in this directory)

| plan | arc | shelved | state when shelved | revival path |
|---|---|---|---|---|
| COMPOSTING_LOOP_PLAN.md | cmp | ⏸ 2026-08-20 | Plan RATIFIED (decisions 1-9) + cmp-0 research pass DONE same day — all 5 data sources GREEN (evaluations/COMPOSTING_DATA_LICENSE_GATE.md). NOTHING built. | Dustin go-ahead → build starts at cmp-0 vendoring straight from the verdicts; deps (nmp dev-nmp-1, aqp-7) already built |
| SCAN_RECONSTRUCTION_PLAN.md | scan | ⛔ 2026-08-12 | Machinery E2E-proven (dev-scan-1 ×5 repos) but sparse clouds ≠ usable end product — Dustin notated NOT FUNCTIONAL for end use | SCAN_REVIVAL_PLAN.md (rev-0..7); ⛔ DA3 1.0-large weights are NC — Apache variants only |
| SCAN_REVIVAL_PLAN.md | scan (revival) | ⏸ 2026-08-16 | PLANNING ONLY by instruction — rev-0..7 scoped, nothing built | Dustin go-ahead on rev-0 |
| AR_ZONE_CAPTURE_PLAN.md | arz | ⏸ ~2026-07-17 | Backend 45/45 + live; last fix pass NOT device-verified (phone session never happened) | Dustin iOS device session to verify capture; then remaining arz phases |
| WAX_MOLD_NESTING_PLAN.md | wax/casting | ⏸ 2026-08-05 | Backend DEPLOYED + verified; parked pending FRONTEND (handoffs/CASTING_FRONTEND_HANDOFF.md). NOT pushed | cert-accept + /casting eyeball + wizard UI pass (Dustin) → build the frontend half |
| PSPP_MATERIALS_PLAN.md | pspp | ⏸ ~2026-07-18 | pspp-1..11 + V3 built; gaps recorded in §4b | pick up §4b gaps; visual review owed |
| PSPP_VISUAL_PROOFING_PLAN.md | pspp (V3) | ⏸ ~2026-07-18 | V3 visual proofing built under the autonomous run; parked with the pspp arc | rides pspp revival |
| TOWER_LIFE_SUPPORT_PLAN.md | tower | ⏸ 2026-07-16 | PLANNING ONLY — cross-agent handoff doc; nothing built | Dustin picks the arc back up (reads this + AQUAPONICS_POT_SHAPE_PLAN.md) |
| BLCNC_PLAN.md | blcnc | ⏸ ~2026-07-18 | PLANNING ONLY — module + simulation scoping | Dustin go-ahead; read with BLCNC_PVD_ROADMAP.md |
| BLCNC_PVD_ROADMAP.md | blcnc/pvd | ⏸ ~2026-07-18 | PLANNING — revises BLCNC_PLAN into 5 phases | rides blcnc revival |
| OSPVD_ROADMAP.md | pvd | ⏸ ~2026-07-18 | PLANNING SHELL — PVD folded into BLCNC_PVD_ROADMAP.md | rides blcnc revival (or delete on ratify) |
| WEBXR_PLAN.md | xr | ⏸ ~2026-07-13 | xr-1/2 + xr-3-min built, UNCOMMITTED in repos — awaiting Dustin headset session | headset session → commit or fix; xr-3 full |
| MATH_SHAPES_PLAN.md | shapes | ⏸ ~2026-07-09 | shape-1..4 built; superseded in practice by matrix-shape-coherence (mq arc). Remainder UNBUILT: CAD/FreeCAD import + predictive root growth | only if CAD import / root growth become wanted — else fold into mq |

## Parked remainders + superseded (plan stays in `plans/` — arc partially live or plan is history)

- **HARDWARE_SIMULATION_PLAN.md** — hwsim-1 LIVE (Renode/Verilator/ngspice); hwsim-2..5 PARKED. Plan serves the live half.
- **MD_MESO_ENGINES_PLAN.md** — marked "superseded — kept for history" in the file itself; engines were parked WIP.
- **MVW_PRINT_SIM_PLAN.md** — 2026-07-06 directive; in practice absorbed by the wp waxprint build (WAX_PRINT_VOXEL_PLAN.md, wp-1..8 done) — inference, not a recorded decision.
- **MESH_APP_CONVERGENCE_PLAN.md** — DRAFT; planning happens WITH Dustin by instruction (queued, not shelved).
- **Focus switch 2026-08-05** — 15 prf modules shelved onto prf-b at RUNTIME (reversible topology move, not a plan) — see memory focus-switch-2026-08-05. Predates the 2026-08-17 full purge.

## Gated, NOT shelved (active review queue — accountability pointer only)

These wait on a Dustin gate and must not drift into this directory:
nmp dev-nmp-1 merge (TESTING_OWED §000) · unin-4 GUI pass + live-isle
verb proof · night GUI install test findings · pub-0 KC rotation +
DNS/droplet · testing-accountability acct-0..3 review · group
authority review · dynamic-modules frontend half (dev-dyn-1) ·
no-code generalization ncg review · DMV cost-of-living review ·
mtg signed-in join + headset pass · Odoo/climate browser passes.
Master ledger: ledgers/TESTING_OWED.md.
