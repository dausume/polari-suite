# PSPP Visual Proofing — plan (pspp-V)

**Status: AUTONOMOUS BUILD (Dustin 2026-07-18: "go fully autonomous… strong visuals
that match those in the book for proofing, intuitive modification, keep the Polari
trajectory"). Stacked branch dev-pspp-v-visual-proofing on the pspp stack.**

Goal: a working, visual, modifiable PSPP surface — every chart is **generated from
the DigitizedDataset rows** so a book figure can be laid beside its Polari rendering
for proofing, and editing a row (auto-CRUDE) changes the picture. No hardcoded chart
data anywhere (invariant I6 extended to pixels).

## Proofing targets (data already in rows)

| Book figure | Polari rendering |
|---|---|
| Figs 5.4/5.5 (Qn% vs MR, Na/K glass) | multi-series line chart from the two Q datasets, bands shown |
| Fig 8.18 (strength + pH vs curing time) | twin-axis line chart incl. the dip |
| Fig 8.20 (exotherm ladder) | small-multiple / line chart |
| Fig 5.20 (viscosity vs T) | log-y line chart |
| Tables 5.4/5.5 (polymerization vs MR) | line chart |
| Table 8.8 (phases + porosity vs T) | porosity line + phase-band strip |
| Fig 8.21 + §8.5/8.6 mechanism | INTERACTIVE reaction-network graph (species/rule nodes, stage columns, site-constraint styling) |
| Patent Tables A/C | window gauges grading a user-entered composition |

## Slices

- **V1 backend (this branch):** `pspp_views.py` (pure builders: dataset curve
  sampling with bands, network graph JSON, composition grading payload, state DAG),
  `progress_engine.py` (measured-curve cure-progress v1 — setting classes at 80 °C +
  the MR=1.83 exotherm ladder for temperature scaling, refusals elsewhere),
  `pspp_api.py` (falcon surface: GET /api/pspp/datasets, /datasets/{name}/curve,
  /network, /states/{material}, /progress, POST /grade), selftests, server
  registration.
- **V2 frontend:** Angular `components/pspp/` — pspp-home (dataset browser +
  provenance), pspp-proofing charts (d3 line charts, one per target, book-style
  axes), reaction-network view (d3, staged columns), composition grader (form →
  gauges). Service + routes + nav following the materials-science idiom.
- **V3 (later):** benchmark cases as rows + overlay measured-vs-predicted; no-code
  bindings (rules/windows editable on the canvas); threshold-shaped ReactionWindow
  variant for the p.193 asymmetric bands.

Principles carried through: charts read rows (edit row → chart changes); every
rendered value can show its evidence payload; refusals render as refusals (an
out-of-range query draws the validity domain, not a guess).
