# FET intuition: states, scoring by characteristic equations, best/worst case (fi arc)

> **STATUS 2026-08-26 (late, autonomous session):** fi-0 + fi-1
> BUILT (earlier session); **fi-2 + fi-3 + fi-2(cells) BUILT** on
> `dev-fi-1` — `cntfet/cnt_scoring.py` (FET terms/concept/subjects/
> live-bound values, `/api/cntfet/device/{name}/score`),
> `cntfet/cnt_cell_scoring.py` (cell terms as ratios to the driving
> FET's intrinsic limits, parsed from the run row's own Liberty,
> `/api/cntfet/device/{name}/cell-scores`), `cnt_montecarlo`
> per-sample scoring (best/worst case + attribution) and the Id(Vg)
> envelope, three new device graphs (`score-terms`,
> `transfer-envelope`, `cell-scores`), cntfet-home rows 7–8,
> generic long-form styles `hguide` + categorical x (angular).
> Selftest 107/111 on the host (the 4 misses are the pre-existing
> host-side OpenSTA wrapper path issue; 95/95-class on the node).
> §4 below records what was built against the plan; §2 decisions
> gained one knob (`vt_definition`). **fi-4 (per-object surfaces on
> the device rows + CRUDE PUT backfill of cntfet-home) is NEXT.**

Written 2026-08-26 from Dustin's brief (verbatim intent): "developing
graphs via configuration in the way we have already defined how to
configure graphs for pages so that people can build intuition about
how and why the FETs work, what are the different states and what
qualifies them to be considered in those states … what are qualities
that are ideal scoring wise … characteristic equations should show
what those values are for particular solutions of the FET, and we
should understand best and worst case solutions for the FETs based
on their stochastic definitions … a solid foundation on which we are
building our logic … intuitive graphing and state transitions that
are well outlined and scoring systems that are defined by
characteristic equations."

Standing rules that bind this arc: [[frontend-graphing-capability]]
(sci-xy-chart + seeded GraphDefinition + named-graph-panel = THE
path; never a new chart engine), [[per-object-display-config]]
(surfaces belong to the device's own page), [[object-coherence]]
(every concept = an object-tree row), [[knobs-and-suggestions]]
(criteria and weights are explicit knobs; refusals name the knob).

## 0. What already exists (ride, don't rebuild)

| Need | Asset |
|---|---|
| Id(Vg,Vd) for any engine | `cnt_metrics.extract_metrics(id_fn)` — SS, Vt(cc) lin/sat, DIBL, Ion/Ioff, gm_pk, g_on, each with its definition + refusals |
| device curves as long-form rows | `cnt_device_viz` `/api/cntfet/device/{name}/points?curve=` + `SEED_CNT_DEVICE_GRAPHS` (`graphConfig` wrapped, seriesDimension/styleDimension) |
| chart marks | `sci-xy-chart`: line/scatter/**band**(lo,hi)/stick/errorbar, logY, zeroLine, categorical **xTicks with vertical guides** |
| config → marks | `NamedGraphConfig.ts` long-form builder (styleDimension 'dot' else line; `dash` col; errorLo/Hi) |
| stochastic population | `cnt_montecarlo.monte_carlo` → per-metric `_quantiles` (p05/p50/p95/mean/sigma) + yield/kills over process-set distributions |
| scoring over arbitrary objects | `scoring.scoring_basis` ScoreTerm (is_positive, unit, normalization_json) · ScoreContext · ScoreSubject(object_ref_json) · ContextualizedValue(data_ref objectRef) · `score_concept.ScoreConcept` · `scoring_engine.score_concept()` (every normalized value travels with its spec; absences named) |
| page seeds | `cnt_pages_seed.SEED_CNTFET_PAGE_DISPLAYS` rows via `_figure`/`_api`/`_table` helpers; INSERT-BY-NAME ⇒ CRUDE PUT backfill for edits |

## 1. Phases

### fi-0 — operating STATES as data + the qualifying criteria
- `FETOperatingState` treeObject rows (seeded, editable): `name`,
  `order`, `description` (the physics "why"), `criteria_json` — a
  list of characteristic-equation predicates over the metric family
  and the bias point, e.g.
  - `off/subthreshold`: `Vgs < Vt_cc(Vd)`; Id ∝ exp(q(Vgs−Vt)/(n kT)) — SS governs
  - `transition-on (near-threshold)`: `Vt_cc ≤ Vgs < Vt_cc + Vov_min` where `Vov_min` = knob (default 3·n·φt·ln10 ≈ 3 decades above Ioff floor)
  - `on/linear`: `Vgs ≥ Vt+Vov_min` and `Vds < Vdsat` (`Vdsat = knob: Vgs−Vt` for the VS model's saturation criterion, or v_xo-limited per [FC10])
  - `on/saturation`: `Vgs ≥ Vt+Vov_min` and `Vds ≥ Vdsat`
  - `transition-off`: the mirror band on a falling Vgs sweep (hysteresis-free in the F1 model → same bounds, stated)
- `cnt_states.py`: `state_at_bias(manager, device, vg, vd)` →
  `{state, criteria: [{expr, lhs, rhs, passed}], metrics_used}`; and
  `transitions_on_sweep(device, vd)` → ordered boundary list
  (`Vt_cc`, `Vt+Vov_min`, `Vdsat(Vg)`) — the "what qualifies" list,
  numbers never bare (fidelity string rides along, F1 today).
- endpoint `/api/cntfet/device/{name}/states?vd=` (+ `?vg=&vd=` for a point).
- selftests: monotone ordering of boundaries; the nominal S1 device
  lands in the expected state at (0, 0.6), (0.6, 0.05), (0.6, 0.6);
  refusal when device is underived.

### fi-1 — intuition graphs, 100% GraphDefinition config
Generic (tiny) frontend extension in the long-form builder, no new
engine: two more `styleDimension` values —
`band` (rows carry `lo`,`hi` → areaY) and `guide` (rows carry `x`,
`label` → ruleX + label). Then everything else is seeded rows:
- `cnt-device-transfer-states`: log-Y Id(Vg) at Vd_lin and Vdd, with
  the fi-0 state bands shaded (band rows spanning the y-range per
  state) and guides at Vt_cc / Vt+Vov_min; the SS decade band
  [1e-3,1e-6]·Ion as a second band (why SS is measured there).
- `cnt-device-gm`: gm(Vg) with a guide at gm_pk (why "peak").
- `cnt-device-output-states`: Id(Vd) per Vg with the linear/saturation
  boundary as a dashed `Vdsat` locus series.
- `cnt-device-ss-fit`: the two-point/decade log-slope fit drawn over
  the data (the SS characteristic equation made visible).
- panels on `cntfet-home` (new row) and reused per device via dataPath.

### fi-2 — scoring by characteristic equations
- Seed `ScoreTerm` rows for the metric family; each `description`
  states the characteristic equation AND the ideal/limit value:
  SS (ideal = φt·ln10·n, n=1 → 59.6 mV/dec at 300 K; lower better),
  Ion/Ioff (higher better, decade-log normalized), DIBL (0 ideal),
  gm_pk (higher), g_on vs 0.7·G0 [FC10] (closer better), Vt vs
  target (closer better). `normalization_json` = explicit min-max on
  physically-motivated ranges (knobs).
- `ScoreConcept` `fet-switching-quality` (weighted-mean, weights =
  knobs) + `ScoreSubject` per device (object_ref) + `ContextualizedValue`
  rows bound by objectRef to the metrics (no stored numbers — resolved live).
- endpoint `/api/cntfet/device/{name}/score` → `scoring_engine`
  result: per-term raw → normalized (with spec) → weighted; plus an
  "ideal vs this solution" table (term, ideal, actual, distance).
- graph seed `cnt-device-score-terms` (stick per term: normalized
  value, guide at 1.0 = ideal).

### fi-3 — best / worst case from the stochastic definitions
- `monte_carlo` extended to keep the sample params of the p05/p50/p95
  and the extreme (score-min/score-max) devices; envelope rows
  (lo/hi of Id at each Vg across samples) as a `band` series over
  the nominal curve → `cnt-device-transfer-envelope`.
- score the best/worst-case samples with fi-2 → score range + which
  process distribution moved it (per-term attribution).
- graph `cnt-device-score-spread`: quantile sticks per term (p05/p50/p95).

### fi-4 — page composition, per-object surfaces, docs
- device rows' display config (per-object) carries the fi-1/2/3
  panels; `cntfet-home` gets one "intuition" row; CRUDE PUT backfill.
- selftests for each endpoint; `library_report` links.

## 2. Decisions for Dustin (defaults stated; build proceeds on them)
1. `Vov_min` default 3 decades above Ioff (≈ 3·n·φt·ln10) — or a fixed overdrive (e.g. 0.1 V)?
2. `Vdsat` criterion for the VS model: `Vgs − Vt` (textbook) vs the v_xo saturation-function knee (Fsat) — default: Fsat knee, textbook shown as the dashed alternative.
3. Score weights (default equal) and normalization ranges — knobs; ratify or edit on the Graphs/scoring pages.
4. Whether ScoreTerms are cntfet-local seeds or promoted to a shared "device figures of merit" set the motors/materials arcs can reuse.

5. `vt_definition` for the Vt-target term: `model` (Vt(Vdd) from the VS parameters — the fi-0 boundary; default so score and states agree) vs `constant-current` (the 1 nA crossing, which on S1 sits at the Ioff level, Vgs ≈ 0). Both ride in the frame.
6. Cell terms are RATIOS to the driving FET's own limits (delay/τ_int, transition/τ_int, E_supply/(C_L·Vdd²), FETs/FETs_min; ideal 1) with device-independent ranges [1,20]/[1,20]/[1,5]/[1,4] — ratify or edit on the scoring page. Leakage/area terms wait on cell-3 parasitics + layout-backed area.

## 4. Built vs planned (2026-08-26)

| Phase | Planned | Built | Deviation |
|---|---|---|---|
| fi-2 | ScoreTerm seeds w/ equations + ideals; concept; subjects; live ContextualizedValues; `/score`; graph `score-terms` | all — ideals are COMPUTED per device (SS ideal = φt·ln10; on/off ceiling = Vdd/SS_ideal; Vt target = midpoint of the fi-0 feasible window); generic engine reaches the numbers via `AlignedCNTFETDevice.figures_of_merit` (a live property, invisible to persistence) | Vt-target defaults to the MODEL Vt (decision 5) |
| fi-3 | MC keeps extreme samples; envelope band; score best/worst + attribution; `score-spread` graph | `monte_carlo(score=True)`: per-functional-sample fi-2 scores → quantiles, per-term spread, best/worst with sampled process values + per-term delta vs nominal (largest first); `envelope` (min/p05/p50/p95/max on the viz grid); curves `transfer-envelope` + `score-terms?samples=` (spread merged into the score graph as lo/hi + best/worst dots) | one graph instead of two (same rows) |
| cells | (not in the original plan; Dustin's directive "characterization and scoring of FETs and Cells") | `cnt_cell_scoring`: latest library run's Liberty parsed back → mid-grid delay/transition/energy → ratios to τ_int and C_L·Vdd²; concept `cell-switching-quality`; subjects per CNTCellDefinition; `/cell-scores` + graph `cell-scores`; refuses by name without a run | scores existing rows without a re-run |
| fi-4 | per-object surfaces, backfill, docs | NOT yet | next |

## 3. Sequencing vs the cells arc
cell-2 (uncommitted `dev-cell-2`) is gated on its selftest; commit it
first. fi-0/fi-1 start on `dev-fi-1` off dev. cell-3/cell-4 continue
after fi-1 — the intuition layer is the foundation the cell rungs
cite.
