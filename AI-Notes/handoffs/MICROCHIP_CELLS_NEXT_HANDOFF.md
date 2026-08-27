# Next-session handoff: microchip arc → the CELL stage (2026-08-26)

> **UPDATE 2026-08-26 (autonomous late session, his directive:
> "characterization and scoring of FETs and Cells"):** **fi-2 +
> fi-3 + cell scoring BUILT on `dev-fi-1`** (framework + angular,
> see FET_INTUITION_PLAN.md §4 for built-vs-planned):
> - `cntfet/cnt_scoring.py` — 6 FET ScoreTerms (SS, on/off decades,
>   DIBL, gm/G0, |g_on/G0−0.7|, |Vt−Vt_target|) whose IDEALS are
>   computed from the device's own model frame; concept
>   `fet-switching-quality`; ScoreSubject per seeded device
>   (object_ref → the row); ContextualizedValue rows bound by
>   objectRef to `AlignedCNTFETDevice.figures_of_merit` (a live
>   property, cnt_basis) so the GENERIC engine's
>   `score_concept('fet-switching-quality')` lands on the same
>   number as `GET /api/cntfet/device/{name}/score` (selftest
>   proves equality). S1 nominal score 0.687.
> - `cnt_montecarlo.monte_carlo(score=True)` — every functional
>   sample scored → quantiles, per-term spread, best/worst case
>   with sampled process values + per-term attribution vs nominal;
>   Id(Vg) envelope (min/p05/p50/p95/max). S1: p05–p95 0.65–0.72;
>   worst case moved by `fet-g-on-distance` (Rc lognormal tail).
> - `cntfet/cnt_cell_scoring.py` — cell terms as RATIOS to the
>   driving FET's intrinsic limits (delay/τ_int, transition/τ_int,
>   E_supply/(C_L·Vdd²), FETs/min; ideal 1), read back from the
>   latest library run row's own Liberty (existing rows score
>   without a re-run); `GET …/cell-scores`; refuses by name
>   without a run. Real cell-2 Liberty: INVX1 0.86 … OAI21X1 0.76.
> - graphs (config only): `cnt-device-score-terms`,
>   `cnt-device-transfer-envelope`, `cnt-device-cell-scores`;
>   cntfet-home rows 7–8 (page now 10 graph panels / 21
>   components) — ⚠ INSERT-BY-NAME ⇒ CRUDE PUT backfill on the
>   live node. Angular: long-form `hguide` style (ruleY + label)
>   and categorical x kept as strings (NamedGraphConfig.ts +
>   plotFigure.ts; tsc clean).
> - points endpoint knobs: `?samples=` (MC count behind
>   score-terms/transfer-envelope, default 100, 0 = nominal only)
>   `?seed=`; score endpoint knobs `vt_definition`, `off_decades`,
>   `vov_decades`, `g_on_target_over_g0`, `samples`.
> - Selftest 107/111 on the HOST (the 4 misses = the `sta` docker
>   wrapper cannot read host /tmp workdirs — pre-existing, passes
>   in-container). NEXT: fi-4 (per-object display config on the
>   device rows, backfill, library_report links), then cell-3.

> **UPDATE 2026-08-26 (late session, HIS go):** the dev box was
> purged and rebuilt on **docker swarm** (dev = swarm, app/deb route
> = production — see memory `dev-swarm-prod-app-route`): `polari-node`
> on pol-core, `polari-cnt-engines` (:9700) on isle-core,
> `polari-engines` (msci :9500) on econ-core.
> **cell-2 + dist-1 COMMITTED** (framework `dev-cell-2` 9b7b36e → dev,
> 95/95 live against the isle-core worker; this branch had been left
> UNCOMMITTED by a session the systemd-oomd VS Code kills dropped).
> **New arc opened: FET intuition** — `AI-Notes/plans/FET_INTUITION_PLAN.md`;
> fi-0 (states as data + qualifying criteria, `/api/cntfet/device/{name}/states`)
> and fi-1 (band/guide long-form styles, state-annotated curves, cntfet-home
> row 6) BUILT on `dev-fi-1` (framework 9d31eee, angular ace38c7), selftest
> 100/100. NEXT: fi-2 scoring by characteristic equations, fi-3 MC
> best/worst case, fi-4 per-object surfaces; then cell-3 / cell-4 below.
> Deploy loop on swarm: `docker compose -f .generated/stack-node.yml build
> backend|frontend` + `docker service update --image … --force`; selftests via
> `docker cp` into the `polari-node_backend` task (cell-2 run ≈ 30 min).

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

1. **fet-viz ✅ BUILT same session (2026-08-26)**: "in-page
   visualizations and characterizations of our existing FETs."
   cnt_device_viz.py — GET /api/cntfet/device/{name}/points
   ?curve=transfer|output (long-form rows, Id in µA) + …/
   characterization (cnt_metrics family + fidelity string +
   refusals verbatim); 2 seeded GraphDefinition rows
   (cnt-device-transfer log-Y / cnt-device-output) reused across
   devices via dataPath; cntfet-home row 5 (S1 device panels);
   selftest 85→89. Committed dev-chip-2 → dev. Per-device pages
   for OTHER devices = point the same graphs at their paths.
   The original sketch (kept for the next device):
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
