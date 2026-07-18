# Frontend work map — 2026-07-16

> **UPDATE 2026-07-16/17 (same evening):** several sections below are now
> COVERED (see GROUP_AUTHORITY_PLAN.md + memory group-authority):
> **A2** PSC mock debt — all 7 sites retired to real data (+ both
> hardcoded user-ids fixed). **B3** — nutrition, vermicompost (aqp-7),
> tanks, biomining, microalgae, wax, supply-chain, morphology + authority
> each have a seeded no-code page at /display/<route>, built from two new
> generic display components (class-rows-table, api-json-panel). NEW: the
> group↔instance authority capability + PSC /authority hub + term
> provenance. **B1 is now also COVERED** (second pass, same night):
> epistemics_api.py routes the whole 2026-07-16 stack (29 GETs), and the
> PSC has /survival, /court-cases, and /epistemics + 5 section pages —
> all live on staging. **Third pass: the CREATE UIs are DONE too**
> (/governance: logic-fork votes + ballots + decision-procedure edges;
> staff-auth browse/revoke + admin list), and the **legacy client-side
> worldview scorer is RETIRED** — replaced by /worldview-scorer running
> on Polari's real engine over group-hosted concept sets. Still open:
> A1 WebXR debugging (parked per Dustin), A3 browser reviews, B2
> no-code-generalization editor surfaces, B4 infrastructure surfaces,
> and the API-health matrix category.
>
> **REVIEW GATE 2026-07-17:** all three passes above await Dustin's
> review (browser + commit) — that review now heads section A3 and
> gates new builds. Next planned work after review:
> AR_ZONE_CAPTURE_PLAN.md (AR zone capture → area/volume → cube
> packing), planning complete, nothing built.

Posture change: no longer building aggressively. Dustin is doing a debugging +
review pass; this doc maps every place frontend work is missing, broken, or
mock-backed so it can be addressed deliberately. Compiled from a 4-agent sweep
of all plan docs + both Angular repos (polari-platform-angular on `dev`, clean;
political-scorecard-frontend on `dev`, clean — **no uncommitted frontend work
exists anywhere**; every gap below is unbuilt, not lost).

---

## A. DEBUG FIRST — frontend that exists but is broken or lying

### A1. WebXR xr-3-min — scrubber DATA BINDING broken; HTMLMesh itself WORKS
> CORRECTION (Dustin 2026-07-17): HTMLMesh is largely working on device.
> The failure is narrower than this section (compiled from the plan's
> pre-headset notes) suggests: the scrubber — a grabbable 3D VR object —
> was not binding to its data. Debug target = the scrubber's
> data-propagation path, not the HTMLMesh panel stack.
Code shipped (commit `f79476e`, in dev history), iwer specs 82/82 green, but
Dustin's headset session found the scrubber and MOST features fail in practice
(WEBXR_PLAN.md:10-20, :363-364). Stop line that currently fails: wrist ring →
set ICs → pick run → play → scrub while 3D animates (:312-316).
Known-broken pieces, in the order the stop line exercises them:
1. **XrScrubRail** world-anchored scrubber (`sim-space-scrubber` seams) — flagship failure.
2. **HTMLMesh panels** of live run-panel + IC-editor (`xr-panel-host.component`,
   lazy `XrPanelSystem`): off-screen mount under `.xr-panel-context`,
   trigger→mouse forwarding, re-raster on resize. Known risk points: mat-select
   can't rasterize (cdk overlay renders at document.body → replaced by ◀▶ run
   cycler), ±decade steppers on numerics/dt.
3. **Ring-1** (RUN/CONDITIONS/SCRUB from `XR_SURFACE_SEED`) + forwarded-trigger dispatch.
4. Interaction dispatch: ray-hover glow, `uiEngaged()` gesture blocking,
   one-grip drag reposition, drop-flatten, XrInterfaceVariant placement persistence.
5. Per-quad dismiss ✕ + ring toggle.
Files: `components/xr-lobby/xr-panel-host.component.ts`, `xr-view-page.component.ts`,
`xr-direct-entry-page.component.ts`, `components/sim-space/sim-space-viewer/
sim-space-scrubber.component.ts`, `services/xr/`. (xr-2 also owes a headset
pass: haptics, drive-speed gain — WEBXR_PLAN.md:240.)

### A2. PSC residual mock/stub debt — pages that render but aren't real
The score-computation path was migrated to live Polari, but these still read
`src/app/state/mock-data/`:
- `services/scoring/worldview-scoring.service.ts` — the 568-line client-side
  weighted-sum engine over `MOCK_CONTEXTUALIZED_TERMS`; the thing the revamp
  plan exists to retire. Present, reachable.
- `components/worldview-ballot/worldview-ballot.component.ts` — original mocked
  ballot editor, superseded by `polari-votes/*` but still reachable.
- `services/api/terms-api.service.ts` — returns `of(MOCK_TERMS)`.
- `components/terms/view-term/view-term.component.ts` — mock contextualized terms.
- `components/legislation/legislation-annotator/...` — mock category/group pickers.
- `components/users/user-groups/{professional,political}-groups/...` — fully mocked.
Also: polari-vote topic create/close/sync UI self-labels "not role-gated yet"
(revamp plan :382-386); hardcoded currentUserId noted in scr-7 parked items.

### A3. Pending Dustin browser-review passes (existing UI, unverified)
- Topology tab (`/topology`) — built + live-verified by agents, never eyeballed.
- Materials science msci-27 material detail view + md/meso/fem/dft config pages.
- Solid-materials selection UIs (phases A-E).
- All new PSC pages from the 2026-07-14 build (revamp plan :781-784).
- Testing accountability acct-0..3 (review pending before acct continues).

---

## B. UNBUILT SURFACES — backend live, zero frontend (build when ready)

### B1. Political scorecard / epistemics stack (largest block)
~16 capabilities built 2026-07-16 (uncommitted, in polari-framework) with NO
PSC frontend; ~14 also have NO bespoke HTTP route yet (only `court_case/*` and
`survival/*` are routed in scoring_api.py — the rest are generic-CRUDE only,
so most need a route pass before UI):
- **DMV cost-of-living page** — plan explicitly: survival endpoints "have NO
  frontend today — first consumer" (DMV plan §7 :182-184). Persona × DMV
  jurisdiction baseline-vs-reported survival reports. Most plan-prioritized.
- **Court-case (ncg-2) surface** — routed + live, no UI: create/advance/report,
  judge-jury input between runs, audit trail.
- CREATE UIs for logic-fork votes, decision-procedure edges, assertions
  (revamp :779-781 — all mechanism-C surfaces are read-only today).
- Staff-authorization browse/revoke (grant-only UI exists) (:1031-1033).
- API-health matrix category (profiler endpoints as live check rows) (§7 :471).
- Trust/epistemics stack, all backend-only: GovSource registry + glossary,
  legal source types, cross-validation/provider reliability, profiler
  drift/discovery, policy drafts, venue-mismatch patterns, Polari-side
  legislation tracking, term competition, democratic term proofs + 18-pattern
  manipulation catalog, credibility bases (per-basis breakdown, never
  flattened), assertion credibility voting, relevance/qualification voting,
  PolicyIntent, DataGatheringSolutions.

### B2. No-code generalization (ncg-0..7) — frontend is greenfield
Only P5 TS engine mirror exists (`services/no-code-services/solution-engine/`).
Missing, with the plan's own priorities:
- **ncg-6 in-editor test authoring** — most behaviorally specified: "author a
  failing circuit test in the editor, watch the matrix row red, fix a knob,
  watch it green" (plan :314-317). No NoCodeTestCase/Pack UI.
- **ncg-5 2D breadboard widget** — explicitly "frontend work to schedule with
  you" (open question 3, :337-339).
- **ncg-3 digital-logic node family** — editor-vs-schematic-canvas decision is
  open question 2 (:333-336); no gate/flop/MUX family in `custom-no-code/states/`.
- ncg-4 circuit node family + component-library/SpiceModelCard browser (OQ4).
- ncg-6 pin-binding UI + SPICE verdict rendered as evidence-bearing suggestion
  on the design row (:308-309).
- ncg-1 GraphCompilerDefinition discoverability; ncg-7b bundle export/install
  (module-management UI exists but only calls `/api/modules/dependencies/*`,
  not `/api/modules/export|install`).

### B3. Household-nutrition module family — entire family has no UI
All APIs built + live-verified, zero Angular surfaces:
- **nutrition/** (largest dashboard-shaped gap): foods, nutrients, person BMR/
  needs, household needs, garden-plan coverage + suggest.
- tanks/ (balance/yield/suggest), biomining/, microalgae/ (sustainability/
  decarbonization/recommend/loops), waxsupply/, supplychain/ (inventory/
  carbon/dependencies), plant_morphology/ (geometry/roots/confinement —
  partially surfaced via aquaponics skeleton viz only).
- Aquaponics analytical APIs: atmosphere state/exchange, system survival +
  env-impact, media/nutrient-profile analysis, plant capture/budget — the 3D
  pot track does not surface any verdicts/scores.
- **aqp-7 vermicompost** — the one aqp-3/7/8 phase truly without UI
  (compare-modes + simulate; NEXT_AGENT_HANDOFF's "none built" for aqp-3/8 is
  STALE: water-slice and plant-skeleton viz exist and were verified).

### B4. Framework infrastructure surfaces
- **Testing accountability page** — CheckRun × capability matrix ("msci
  scale-presence idiom", TESTING_ACCOUNTABILITY_PLAN.md:249) + acct-6 no-code
  Tests tab. Entirely unbuilt.
- **Cross-instance sim frontend tail** — queue page, "locked by run X" chips,
  ref inspector (CROSS_INSTANCE_SIM_PLAN.md:89-90); backend all done.
- **Resource capacity/admission overlay on Topology tab** — per-node capacity/
  headroom + admission-advisor verdicts; zero references to admission/headroom
  in the Angular repo (RESOURCE_AWARENESS_PLAN.md:193, :372).
- **hwsim-1 item 4** — no-code binding-row editor state + live LED-grid widget
  over existing STOMP (HARDWARE_SIMULATION_PLAN.md:231; "with Dustin").
- **Multi-scale sim page, Milestone B wiring** — material picker still presets
  (ice/wood/steel/lead), to wire to real Material objects (design doc :429-434);
  plus retention-window scrubber honesty when that opt-in lands (:403-408).

---

## C. DEFERRED-BUT-PLANNED aquaponics viz extensions (named in plans, not owed yet)
- Per-part shape/growth **equation inspector** (POT_SHAPE plan :134, Dustin-deferred).
- **Light-field visualization** (Phase 8 backend done, viz deferred).
- **Time-stepped frontend simulation** over water batches/levels (":291 'a
  robust frontend simulation'"; flagged NOT started at :317, :413, :517).
- Per-organ hover tooltips / pickable sub-meshes (:706).
- Kratky-pot + float-valve printable geometry (nutrition plan :316, deferred).

## D. EXPLICITLY DO-NOT-BUILD
- Tower life-support AR spatial placement — "explicitly OUT of scope … Do not
  build UI for it" (TOWER_LIFE_SUPPORT_PLAN.md:178-181); backend also incomplete.
- P6 no-code node families — parked with their backend (foundations audit :29-31).
- gRPC bridge — no Angular work until a grpc-web/Envoy decision (plan :241-242).
