# Generic FET pages + common FET data format + 2-D sim spaces (fg arc)

Dustin 2026-08-30: "convert specific pages into more general configured paths that
pass particular FET rows in that pull a common FET data format. That way everything
we are seeing in the 90 nm display is common across all FETs we go into a detailed
view for. And we still need those 2-D simSpaces." PRIORITY after this handoff, before
the architecture level (ARCHITECTURE_LEVEL_PLAN stays parked). FETs + cells keep
getting flushed out alongside.

**Naming (Dustin 2026-08-30, ratified): it is `fet`, not `cntfet` — "we want
to dig into cntfets but we are not only doing cntfets."** Every NEW generic
surface is FET-named: the API is `/api/fet/device/{name}/…` (every
device-scoped cntfet route aliases there via `cnt_fet_summary.fet_alias`;
the `/api/cntfet/…` paths keep answering until the module split), the summary
schema is `fet-summary/1`, and the two generic pages (fg-2) are `fet` +
`fet-detail` (`display/fet?object=…`). CNT-only surfaces (catalogue, acts,
engines) stay cntfet; the silicon catalogue stays sifet.
**fg-5 (later, parked): extract a real `fet` module** — generic device
contract, scoring, summary, pages; cntfet/sifet become technology modules
registering their rows into it (registry, ModuleAssignment, initialData and
polari-module-* repos move with it). Not a blocker for fg-0..4.

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
  `display/fet?object=…`. `/links` payload emits these URLs.

### fg-2 the two generic page seeds (backend) — `cntfet/cnt_pages_seed.py`
`fet` (= today's score page rows with `{object}`) and `fet-detail`
(= detail rows incl. scenes). `score_pages()/detail_pages()` stop stamping per-device
rows; they return the two generic seeds + a per-device LINK table row for cntfet-home
/ sifet-home (name → `display/fet?object=name`). Migration: the 24 per-device
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
- Row on `fet-detail` (and a compact one on `fet`).
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

## 3. Status (2026-08-30, dev-fg-1 — framework + angular + cli; NOT pushed)

| phase | state | notes |
|---|---|---|
| naming | ✅ ratified | fet, not cntfet (header above); memory `fet-not-cntfet-naming` |
| fg-0 | ✅ BUILT | `cnt_fet_summary.py` — fet-summary/1, refusals inline, key set fixed (SUMMARY_KEYS); `/api/fet/device/{name}/…` aliases every device-scoped route (`fet_alias`); fet-overview does ONE summary fetch (per-slot = fallback). selftest_summary 14/14 |
| fg-1 | ✅ BUILT | `display/:id?object=` — display-page substitutes `{object}` in titles + componentProps inputs (nested rows too), passes `{object}` context, banner when opened without ?object= |
| fg-2 | ✅ BUILT | `cnt_compare.generic_pages()` → routes `fet` + `fet-detail` (source_class '', /api/fet paths); per-device stamping GONE (score_pages/detail_pages return the generic pair; SEED_SI_SCORE_PAGES = []); `/api/fet/devices` generic catalogue + rows on cntfet-home/sifet-home; links payload emits `fet?object=`; backfill script lists legacy per-device rows and deletes ONLY with CONFIRM_DELETE_LEGACY=yes after fet/fet-detail are live. selftest_sifet_pages 21/21 |
| fg-3 | ✅ BUILT | `cnt_parts_svg.py`: GET `/api/fet/device/{name}/parts2d?field=&vg=&vd=` — fet-parts2d/1: region rects in nm from the SAME rows the parts list names (cnt-gaa / si-planar / si-finfet templates; sketch lengths labelled), part join by regionKind, field overlay at the device's OWN Vdd (Si overlay = honest refusal until fg-4); `fet-parts-2d` component (own SVG, hover part cards, Vg/Vd sliders, refusals verbatim; `compact` on the score page); `fet-2d-{device}` SimSpaceDefinition rows (freestandingOnly) seeded for CNT + Si devices. selftest_parts2d 12/12 |
| fg-4 | ⚠️ partial | ✅ Si sequential truncation FIXED (root cause: aF CNT-sized standin caps left cdff m1 / latch-loop nodes massless vs ~350× Si currents — 'timestep too small, node xdut.m1'; NOT τ, which already scales from the device. Fix: one retry with standins scaled to the device's own input cap, recorded as `numericalAid`; CNT bit-identical, never retries. sifet.selftest_si_sequential). ✅ FreePDK45 Ioff: gap stays reported by default; NEW explicit act `POST /api/sifet/devices/{n} {"action":"apply-anchor-knob"}` applies the vfb suggestion to the ROW with the calibration cited in vfb_source (selftest_ladder 31/31). ✅ Si TRANSPORT basis: `sifet/si_transport.py` — lattice-phonon / ionized-impurity / surface-roughness mfps DERIVED from the cited [CT67]/[SZE07]/[TAK94] mobility chain via the [LUN97] relation (Matthiessen identity selftest-proven; λ_eff cross-checked vs [LUN97] 10–20 nm; regime scattered at 90 nm as physics demands); `transport_report` dispatches Si rows (one choke point → /transport, summary, fet-overview un-refuse together); CNT bit-identical (selftest_si_transport 10/10). ✅ fv-8: curve `transfer-normalized` (Vg/Vdd vs Id/Ion, both technologies, underived named) + graph seed `fet-compare-normalized` + row 13 on the `fet` page (summary selftest 16/16). ✅ Si FIELD basis: `sifet/si_fields.py` — the SAME eq.(5) analytic barrier with silicon's own cited scale length ([YAN92]/[AP97]/[SIL96] via the shape rows), charge-sheet density [SZE07], doping ROWS verbatim; F1 SKETCH and it says so (S/D degeneracy offset + depth structure = named gaps). `field_profile` dispatches Si rows; Si defaults = the device's OWN Vdd (CNT legacy defaults bit-identical); /fields handler dual-lookup + device-Vdd defaults; parts2d Si overlays NOW SERVE (x aligned with the 2-D template). selftest_si_fields 10/10; regressions fields 25/25, parts2d 12/12. **fg-4 COMPLETE** |
| fg-6 | ✅ BUILT (2026-08-30 night, from Dustin's browser pass) | 3-D + simulation: **every 3-D FET piece is a MathShapeDefinition row** (his directive — true-nm analytic boxes / x-axis cylinders / CSG shell = outer−inner coaxial cylinders; matrix-equation form via `shape_equation_rows`; scenes reference `mathshape:fet-part-*`, radial exaggeration = stated VIEW scale only); scene rename `cnt-device-3d-*` → **`fet-3d-{device}`** (old rows = legacy list); **Si 3-D scenes** (`sifet/si_scene.py`, planar/finfet stacks, FETFieldSample bound, scrub Vg); `sample-fields` device-relative (0→own Vdd, CNT bit-identical) with **SI_FIELD_BANDS** (areal cm⁻²/cm⁻³ transforms of the CNT band styles); 2-D gray-viewport fix (renderer non-uniform scale + style-normalized seeds); backfill script syncs fet-2d rows + lists legacy 3-D scenes. selftest_si_scene 12/12, fields 25/25 |
| deploy | ⏳ owed | image roll + backfill + live sample-fields for all devices + legacy deletion + browser pass (phone + desktop) |

## 3b. Decisions for Dustin (defaults stated)

1. Query param `?object=` (default) vs path segment — default query (works with the
   existing `display/:id` route and the app shell's deep links).
2. Delete the 24 legacy per-device pages after the generic pages are verified
   (default yes, confirmed in the script) vs keep as redirects.
3. Si field overlays refuse until a sifet field basis exists (default: refuse
   honestly; fg-4 builds the basis).
