# Generic FET pages + common FET data format + 2-D sim spaces (fg arc)

Dustin 2026-08-30: "convert specific pages into more general configured paths that
pass particular FET rows in that pull a common FET data format. That way everything
we are seeing in the 90 nm display is common across all FETs we go into a detailed
view for. And we still need those 2-D simSpaces." PRIORITY after this handoff, before
the architecture level (ARCHITECTURE_LEVEL_PLAN stays parked). FETs + cells keep
getting flushed out alongside.

## 0. What exists (no rewrite needed)

- Every device endpoint is already model-agnostic behind `device_model()` (CNT and Si
  rows): `/score /parts /fo4 /power /taxonomy /proof /ip /links /compare /regimes
  /transport /characteristics /fields /cell-coverage /points?curve=…`.
- `fet-overview` takes `{device}` and already renders the generic card set (switching
  vs signal sub-displays chosen by the device's own data).
- Pages today: `cnt_compare.score_pages()/detail_pages()` stamp ONE definition per
  device (24+ DisplayDefinition rows whose only difference is the name baked into
  every `dataPath`). `display/:id` reads only `:id`; the renderer has a `context`.

## 1. Phases

### fg-0 common FET data format — `cntfet/cnt_fet_summary.py`
`GET /api/cntfet/device/{name}/summary` — ONE stable schema every FET row answers
(CNT or Si; refusals inline per section, never a 500): `identity` (name, technology,
polarity, vdd_v, rung, targets), `parts`, `figures` (score idealTable), `validity`,
`taxonomy` (switching/signal scores), `power` (target-scoped), `speed` (fo4 or
refusal), `proof` (usage binary + status), `links`, `curves` (the curve names this
device can serve). Versioned `schema: 'fet-summary/1'`. Selftest: S1 and planar-90
produce the same key set; a device with no library gets `speed.refusal`.
`fet-overview` switches to one `/summary` fetch (its per-slot fetches become the
fallback only).

### fg-1 object-parameterised pages (frontend) — display-page + renderer
- Route `display/:id` gains `?object=<name>` (query param; also `display/:id/:object`).
- Page context: `context.object = <name>`; the renderer substitutes `{object}` in
  every item's `inputs.*` string and `dataPath` (`/api/cntfet/device/{object}/fo4`,
  `inputs.device: '{object}'`). Unsubstituted `{object}` on a page opened without
  one → a single clear banner ("this page needs ?object=") instead of 404s.
- Links: `named-graph-panel`/structured panels/`fet-overview` links use
  `display/cntfet-fet?object=…`. `/links` payload emits these URLs.

### fg-2 the two generic page seeds (backend) — `cntfet/cnt_pages_seed.py`
`cntfet-fet` (= today's score page rows with `{object}`) and `cntfet-fet-detail`
(= detail rows incl. scenes). `score_pages()/detail_pages()` stop stamping per-device
rows; they return the two generic seeds + a per-device LINK table row for cntfet-home
/ sifet-home (name → `display/cntfet-fet?object=name`). Migration: the 24 per-device
DisplayDefinition rows are deleted by the backfill script after the generic ones are
live (list them first; `ISLE_CONFIRM_DELETE`-style confirmation in the script).
Selftests: page-count checks change (expect flips).

### fg-3 2-D sim spaces (fv-7, BUILD) — `cntfet/cnt_parts_svg.py` + angular `fet-parts-2d`
- Backend: `GET /api/cntfet/device/{name}/parts2d?field=potential|density|doping&vg=&vd=`
  → the parts list (cnt_parts) laid out as SVG regions in device coordinates
  (contact / extension / channel / oxide / gate; CNT GAA vs Si planar/FinFET
  templates chosen by `regionKind` + shape), each region carrying its part data and
  an optional field overlay sampled from `cnt_fields` (CNT) or a refusal (Si until a
  sifet field basis exists — stated, not faked). Vg/Vd default to the device's OWN
  Vdd (device-relative rule).
- Frontend: generic `fet-parts-2d` component (d3, no new chart engine — it is a
  labelled diagram, not a chart): hover = part card (material, doping, purpose, row
  link), field overlay legend, Vg/Vd sliders bound to the request, "characteristic"
  selector reusing `fet-characteristic-explorer` descriptions. Container queries, no
  width assumptions.
- Row on `cntfet-fet-detail` (and a compact one on `cntfet-fet`).
- SimSpace registration: each device's 2-D view is also a `SimSpaceDefinition` row
  (`fet-2d-{object}` generated on demand) so it appears under /sim-spaces like the
  3-D scenes.

### fg-4 flush-out continues (parallel agent, disjoint files)
Si sequential-harness truncation (scale tstop/step from the device's τ); Si
transport/field basis (phonon/impurity/surface-roughness mfps) so `/transport`,
`/fields`, and fg-3 overlays stop refusing on silicon; FreePDK45-class NMOS Ioff gap
(apply/justify the vfb knob or record why not); normalized cross-device view (fv-8).

## 2. Order + gates

fg-0 → fg-1 ∥ fg-2 → fg-3 (∥ fg-4 throughout) → deploy (image roll; wait for the NEW
task id; backfill; delete legacy per-device pages with confirmation) → browser pass
on phone + desktop. Commits per phase on dev-fi-1 (or dev-fg-1), no push.

## 3. Decisions for Dustin (defaults stated)

1. Query param `?object=` (default) vs path segment — default query (works with the
   existing `display/:id` route and the app shell's deep links).
2. Delete the 24 legacy per-device pages after the generic pages are verified
   (default yes, confirmed in the script) vs keep as redirects.
3. Si field overlays refuse until a sifet field basis exists (default: refuse
   honestly; fg-4 builds the basis).
