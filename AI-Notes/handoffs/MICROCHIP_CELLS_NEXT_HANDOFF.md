# Next-session handoff: microchip arc → the CELL stage (2026-08-26)

**Entry state (this session's consolidation, HIS go): both arcs
COMMITTED and MERGED to local dev — framework `dev-chip-1`
(0b92bff) + `dev-cmpc-1` (57c6ebc) → dev b7b7e3b; angular
`dev-chip-1` (4f35c35) → dev 536d871; rf-node pointer 5706a8f;
suite docs+pointer on dev. NOT pushed (his `./push-all-dev.sh`
ritual). Post-merge selftests green: cntfet 85/85, computers
30/30, computerparts 14/14, polariapps 45/45. The running prf
stack carries the same code via docker cp (image is BAKED — next
`pol` rebuild converges from dev).**

**FOCUS (his directive): microchip arc only — move up to CELLS.
Computer-assembly next steps (cmp-c-7 workbench etc.) stay in
COMPUTER_COMPOSITION_PLAN §8, untouched this arc.**

Governing plans: CHIP_COMPUTE_DISTRIBUTION_PLAN.md §4 (cell
roadmap; §6 decisions PENDING his ratification),
CNT_FET_SIMULATION_PLAN.md (D-boxes), COMPUTER_CHIP_NEXT_HANDOFF
(previous sessions' record).

## Build order

1. **fet-viz (his 2026-08-26 directive, do FIRST)**: "in-page
   visualizations and characterizations of our existing FETs."
   - Per-object rule applies ([[per-object-display-config]]):
     curves/characterization belong on the DEVICE's own page
     surfaces, configured there — not a new global page.
   - Ride the figure machinery just merged: seeded
     GraphDefinition rows + `named-graph-panel` (angular) +
     long-form points endpoints — NO new chart engine
     ([[frontend-graphing-capability]]).
   - Shape: a device-scoped curves feed (e.g.
     `/api/cntfet/device/{name}/points?curve=transfer|output`,
     long-form rows matching seeded dimensions) + a
     characterization summary payload (SS, gm, Ion/Ioff at
     DECLARED bias points, each value carrying its fidelity
     string F1/F2/F3/F3_NEGF_SCF — never a bare number) + seed
     rows onto the cntfet page AND the device rows' display
     config. Refusals verbatim (undigitized/uncomputed = named
     refusal, not an empty chart).
   - Existing assets: AlignedCNTFETDevice/CNTFETSimResult rows,
     cnt_api actions (iv/transfer/f3-oracle), cnt_figures.py
     seed pattern (SEED_CNTFET_FIGURE_GRAPHS = the template),
     cnt_characterization.py (CellCharacterizationRun — reuse
     its sweep plumbing where it fits devices, not just cells).
2. **cell-2 — sequential + richer combinational
   characterization** (plan §4): lctime executor for DFF
   setup/hold (⚠ AGPL — absent-by-default knob, D14 licence
   gate: evidence in the plan, HIS call before any vendor/pin);
   AOI21/OAI21 + TG mux cells; x4 drive variants (GENERATED,
   never hand twins); energy-per-transition tables from the same
   transients into the Liberty.
3. **cell-3 — parasitics grade-up**: [VS2] junction capacitance
   replaces the labeled 2 aF standins; re-grade characterization
   rows (honesty strings already say intrinsic-grade).
4. **cell-4 — ladder rung flip as DATA**: microchip CELL rung
   'unbuilt' → 'characterized' citing library result rows;
   ring-oscillator + cells pages get the figure-replica
   treatment (same named-graph-panel path as fet-viz).
5. Then (NOT this arc unless he says so): chip-3/S6 synthesis,
   dist-1 engine-worker (plan §3), chip-4 seam (§5 table is the
   ratifiable contract).

## Gotchas that WILL bite again

- 🔑 Liberty without `delay_model : table_lookup` silently times
  NOTHING in OpenSTA (arcs listed, no arrivals); clockless
  netlists need a virtual clock + zero I/O delays before
  report_checks sees any path. (Both hit + fixed in cell-1.)
- 🔑 OpenSTA runs via the docker wrapper `~/.local/bin/sta`
  (openroad/opensta v3.1.0) — no sudo build; keep-or-native is
  his open call (dist plan §6.3).
- 🔑 DisplayDefinition seeds are INSERT-BY-NAME: editing an
  existing page's seed needs a CRUDE PUT backfill (multipart
  polariId + updateData, --form-string) — applied for
  computers-home this session; cntfet-home will need the same
  when fet-viz adds rows.
- 🔑 Backend code is BAKED into the image (no repo bind mount):
  deploy = docker cp changed files + `docker restart
  prf-backend` (proven ×2 this session), or full `pol` rebuild.
  Boot takes ~4 min (451 types).
- 🔑 New treeObject classes MUST be registered in polariServer's
  defClassList or seeds silently vanish.

## His open items (unchanged gates + new)

1. **Push**: `./push-all-dev.sh --push` (suite root wrapper).
   ⚠ --with-isle is legacy/dead.
2. **dev-cnt-2 (angular) still UNMERGED**: both-keep merge on
   generic-display-components.ts; cntfet-iv-chart must CONVERGE
   onto the graphs design at that merge (now easier — the
   named-graph-panel path is on dev).
3. **Review flags**: the S5-era eq.(5) a1/a2 mirror-bug fix
   (merged with dev-chip-1 — the old S5 numbers were computed on
   the mirrored barrier); polariServer.py carried both arcs' app
   seed passes (landed via dev-cmpc-1).
4. **Ratifications**: cmp-c plan decisions 1–4;
   CHIP_COMPUTE_DISTRIBUTION_PLAN §6 (incl. D14 lctime AGPL
   knob before cell-2 vendors anything).
5. Standing: nmp dev-nmp-1 + dev-dyn-1 gates untouched; browser
   passes (TESTING_OWED item 18 + the new computers-home row 3 +
   the two nav apps).
