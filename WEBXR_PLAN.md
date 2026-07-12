# WebXR VR/AR Spaces — Plan (xr-1..5)

**STATUS 2026-07-12/13: xr-1 ✅ + xr-2 ✅ — and Dustin OFFICIALLY
marked VR MOVEMENT WORKING on the Vive (Wolvic): "smooth and
intuitive" (after the nav-1..8 tuning arc: continuous drive re-unit
in Sim Radii, expo fine control, pad-click grip backup, R-HUD w/
vector-equation position + rotation matrix, zoom cap 10^1.5,
fail-safe comfort-visual colors, /xr lobby + session prompt).
Everything consolidated on ng `dev` (tag 'nav-8 visuals').
NEXT: **xr-3-min** (scoped by Dustin 2026-07-13 — see the section
BEFORE the full xr-3 spec): the FIRST ring layer of the wrist
radial menu spawning HTMLMesh panels for stepping / initial
conditions / play+scrubber — STOP LINE = "able to view (play/scrub)
a calculated simulation in VR". Plan checked + adjusted; awaiting
Dustin's go. NOT pushed.**
Goal: every 3D interface can be "entered" as a VR space through
WebXR + three.js, with ONE engine carrying all XR capability (many 3D
interfaces on screen must never each load VR machinery); controllers/
headset/hands visible; AR later for construction + hydroponics layout
planning in real rooms (surroundings + distance mapping).

Branch per phase (`dev-xr-1-engine`, …) in polari-platform-angular
(+ framework branches only where server classes appear, xr-4).

---

## 0. Facts the design stands on (frontend survey 2026-07-11)

- three `^0.169.0` + `@types/three` already installed; jsm addons
  already used (OrbitControls, ViewHelper) — the WebXR helpers
  (`three/examples/jsm/webxr/*`) live in the same folder and would
  ride the SAME lazy chunk. NO XR code exists anywhere in src/ today.
- **Renderer-per-viewer**: `ThreeSimSpaceRenderer`
  (services/sim-space-3d/three-renderer.service.ts) is the ONLY
  WebGLRenderer owner (created per `sim-space-viewer` instance in
  `attach()`, :123); each instance owns scene+camera+controls+RAF
  loop; the multi-scale page mounts one per scene panel (N at once).
  `SimSpaceRendererFactory.create()` dynamic-imports three (~600KB
  lazy chunk) — the pattern to copy for XR code.
- The renderer uses a RAW `requestAnimationFrame` loop (:589-597,
  reschedule-first hardening) and `autoClear=false` manual-clear
  compositing for the ViewHelper gizmo (:126-130) — BOTH interact
  with XR's frame model (`renderer.setAnimationLoop` is mandatory
  under XR; the gizmo pass must be skipped in-session).
- Angular 19; routes hosting 3D are lazy standalone components;
  initial-bundle budget exists — ALL XR code must stay inside the
  sim-space-3d lazy chunk.
- WebXR requires a SECURE context — staging already serves TLS
  (nip.io certs; the /cert-trust page is the headset trust hurdle
  helper).
- **One viewer hosts EVERY 3D space (survey 2026-07-11)**:
  `sim-space-viewer` is the sole 3D host — pendulum, wind,
  solid-materials selection etc. are `SimSpaceDefinition` rows
  rendered through it, not bespoke pages. Its chrome is a fixed set
  of overlays (axis legend, run panel, scene legend, scrubber,
  evaluation HUD, right-docked editor sidebar) + hover tooltip.
  The msim page's panels are already config-driven components in
  `DISPLAY_COMPONENT_REGISTRY` (msim-display-components.ts), laid
  out by the Display grid model (models/dashboards/Display*.ts).
  Renderer seams for picking exist: `pickAt`/`setHighlight`/
  `setSelection`/`getObjectScreenRect` + `setOnClick`/
  `setOnHoverChange` (sim-space-renderer.interface.ts:125-195).
  "Play" is a BATCH of backend steps (`SimulationRunService.
  runBatch`) — no continuous clock, no speed slider.

## 1. The single-engine design (Dustin's requirement, confirmed)

WHY one engine is not just nice but required:
- A device allows ONE immersive XRSession at a time — per-viewer XR
  would fight over it by construction.
- Browsers cap live WebGL contexts (~8-16); N flat viewers already
  spend contexts. XR must not multiply that.
- three.js Scenes are RENDERER-AGNOSTIC: any renderer can render any
  scene. That is the pivot the whole design stands on.

**`XrEngineService` (root singleton, lazily created, lives in
sim-space-3d/):**
- Owns AT MOST ONE XR-capable `WebGLRenderer` (`xr.enabled = true`,
  `setAnimationLoop`) + ONE XRSession, created on FIRST Enter-VR and
  disposed on exit (or kept warm — knob).
- A **scene registry**: every mounted 3D viewer registers
  `{id, scene, camera, label}` on attach and unregisters on destroy
  (a ~5-line addition to the existing attach/destroy; the flat
  per-viewer renderers stay EXACTLY as they are for desktop).
- **Enter VR on interface X** = the engine binds X's LIVE scene into
  the immersive session (GPU resources upload into the XR context on
  entry — once). The flat viewer keeps rendering (mirror) or pauses
  (knob). Exit hands back cleanly. Entering another interface swaps
  the bound scene — never a second session.
- Per-viewer cost of XR support: a registry entry + an Enter-VR
  button. ZERO XR code loads until someone enters (dynamic import of
  the XR module inside the existing lazy chunk).
- Capability honesty: `navigator.xr.isSessionSupported('immersive-vr')`
  probed once; no device → the button renders disabled with the
  honest reason (never hidden, never a dead click) —
  knobs-and-suggestions applies to UI affordances too.

## 2. Phases

### xr-1 — the engine + enter/exit (the foundation)

**✅ BUILT + LIVE-VERIFIED 2026-07-11.** What shipped: backend `xr/`
module (XrGlobalSettings singleton + seed, XrTypeDefault Q9 seeds,
XrInterfaceVariant, cascade resolver w/ provenance + raw rungs,
GET /api/xr/resolve, category/owning_module/xr_mode/xr_framing on
SimSpaceDefinition + xr_mode/xr_framing on
MultiScaleSimulationDefinition; xr = CORE package) — selftest
31/31. Frontend: three-free XrSceneRegistryService +
XrEngineService facade (dispose-on-exit) + capability probe +
XrSettingsService (resolve + CRUDE multipart knob writes);
lazy-chunk XrSessionRuntime (ONE renderer+session, rig-only scene
mutation, local-floor→local fallback, scene-swap switch); viewer
registers scenes + Enter-XR button (honesty matrix); sidebar XR
section (provenance + per-space knobs); renderer seam
getXrSceneHandle() (opaque — firewall intact). Verified: 13/13
specs incl. iwer-emulated enter/switch/exit on one session +
byte-identical restore (karma needed --enable-unsafe-swiftshader +
iwer forceInstall vs headless Chrome's native navigator.xr); live
staging — 22/22 smoke, 66-suite baseline-identical (8F/4E on the
pre-xr image too), all four cascade levels proven over the real
API, variant byte-identical through a full settings sweep,
resolve served through the TLS proxy (api.prf host). Initial
bundle unchanged; XR rides the sim-space-3d lazy chunk. Gotcha
log: CRUDE writes are multipart polariId+updateData to
/{ClassName} (per-id REST PUT 404s); staging compose needs
--env-file .generated/.env.staging or the backend boots with a
bad DB password and silently serves seeds-only.

Original spec:
XrEngineService + scene registry + Enter-XR per sim-space-viewer;
`setAnimationLoop` under XR (viewer RAF untouched for flat);
ViewHelper pass skipped in-session; reference-space `local-floor`
with fallback; exit restores the flat view byte-identically.

**The XR-mode SETTINGS CASCADE (Dustin 2026-07-11): different kinds
of simulations default to VR or AR by TYPE, with a four-level
override ladder — a directly-set lower level always beats a higher
one.** Many interfaces only make sense in one mode (a hydroponics
room layout is an AR space; an abstract simulation world is a VR
space), so the defaults live at the type level and the exceptions at
the instance level. Every value is
`'unset' | 'none' | 'vr' | 'ar' | 'both'`; resolution walks
individual → multiscale → type → global and takes the FIRST
explicitly-set value; 'unset' means "inherit upward".

| level | anchor row ([[object-coherence]]) | example |
|---|---|---|
| global | `XrGlobalSettings` singleton (framework treeObject) | force 'none' fleet-wide except chosen spaces |
| type | `XrTypeDefault` rows keyed by SimSpace CATEGORY (new explicit field, Q1b: default category DERIVED from the owning module binding, editable; explicit wins) | "hydroponics-layout spaces default 'ar'"; "msim worlds default 'vr'" |
| multiscale | `MultiScaleSimulationDefinition.xr_mode` | one msim's panels all VR |
| individual | `SimSpaceDefinition.xr_mode` | this one space is 'both' |

- The "global none except chosen" case falls out of the ladder: set
  global='none', leave everything 'unset', and explicitly set 'vr'/
  'ar' on the chosen spaces — direct-set-lower-wins does the rest.
- The RESOLVED mode always carries provenance —
  `{mode, resolvedFrom: individual|multiscale|type|global|builtin}` —
  surfaced in the viewer's config UI so "why is there no VR button"
  is always answerable (evidence, house style).
- Type defaults are SEED rows (suggestions made durable), editable
  like any row; the builtin fallback when the whole ladder is unset
  is 'none' (XR is opt-in at some level, never ambient).
- Honesty matrix = resolved mode × device capability: an 'ar' space
  on a VR-only headset shows the disabled button naming the missing
  capability — configuration says what the space IS, capability says
  what this device CAN do, never conflated.
- The ENGINE stays mode-agnostic (session mode is a request
  parameter) — xr-1 ships the cascade + the VR leg; AR-configured
  spaces are honest ("AR arrives with xr-4") rather than silent.

**Mode-specific interface configurations are SEPARATE from mode
settings and are NEVER erased by them (Dustin 2026-07-11).** A
space's interface can be configured DIFFERENTLY per presentation —
e.g. the hydroponics UI has flat-3D, VR, and AR variants (panel
layout, control placement, scale, locomotion, AR anchoring). These
live as their own rows: `XrInterfaceVariant` (treeObject:
subject space/definition ref, mode 'flat'|'vr'|'ar', config_json,
notes). The cascade only decides which variants are OFFERED right
now; flipping a setting (even global 'none') leaves every variant
row intact and dormant — re-enable the mode and the configured
interface comes back exactly as authored. Deleting a variant is a
deliberate act on the variant row itself, never a side effect of a
settings change. (Same preservation rule the per-phase textures and
per-run retention follow: configuration is data, settings are
visibility.)

**Acceptance**: multi-scale page with N 3D panels → ONE engine, one
session, enter/exit/switch between panels; cascade resolution proven
at all four levels (direct-lower beats higher; provenance names the
deciding level; global-none-except-chosen works); XrInterfaceVariant
rows survive every settings flip (selftest: author variants, toggle
global/type/individual settings through all values, variants
byte-identical after); knob + variants round-trip through CRUDE; no
per-viewer XR loading (bundle assert); iwer spec green; existing 3D
pages unregressed.

### xr-2 — seeing yourself: controllers, headset, hands

**✅ BUILT + LIVE-VERIFIED 2026-07-11 (ng dev-xr-2-input-ng 0759051;
frontend-only — the backend xr module already carried
XrInterfaceVariant).** What shipped, all inside the sim-space-3d
lazy chunk (initial bundle byte-comparable to base; the 5MB budget
warning pre-exists): xr-input-rig (controller+hand models + rays;
profiles BUNDLED LOCALLY under /assets/webxr-profiles — oculus-touch-
v3 + htc-vive + two generic fallbacks + generic-hand, trimmed
profilesList.json so matching never leaves the bundle); xr-navigation
(the grip state machine below, all Q8 defaults as knobs);
xr-entry-placement (framing-aware scale-relative entry, derived
entry_scale persisted into XrInterfaceVariant on first entry);
xr-nav-visuals (vignette + at-limit flash wearer-only via per-eye
layers 1/2; anchor ghost + command vector visible in the mirror);
xr-wrist-ui (ring-0 seed: EXIT/HOME/BACK + zoom indicator,
handedness knob, hover blocks world gestures); xr-mirror-ghost
(headset ghost on layer 3, enabled on the FLAT camera while bound,
exact mask restored on exit — byte-identical now covers camera
layers); engine + XrVariantService (real CRUDE protocol, merge
preserves unknown config keys) + sidebar XR nav section (entry
scale, vignette/snap/curve/wrist knobs, bookmarks w/ live goto).
SEMANTIC DECISION pinned in code+spec: the OTHER grip cancels an
ARMED shift (gestures dead until all grips release); both grips
inside the debounce window = world-grab start, and releasing one
grab hand never silently resumes a shift. Verified: 29/29 XR specs
(16 new: pure nav state machine incl. midpoint invariance +
clamp honesty + hysteresis; iwer session integration incl. iwer
squeeze→shift end-to-end; CRUDE protocol pins; engine bookmark
round-trip), 62/62 full frontend suite, live staging: 22/22 smoke,
profile GLBs served over the TLS proxy (oculus 650KB / vive 1.1MB),
full XrInterfaceVariant live round-trip (create 201 → bookmark
merge → global-mode flip → variant BYTE-IDENTICAL → deliberate
delete). Gotchas: replacing prf-frontend needs `docker network
connect polari-suite_polari-network prf-frontend` before pol-proxy
restarts (proxy lives on the suite network and dies on unresolvable
upstream); tsconfig gained skipLibCheck (three's GLTF loader d.ts
pulls three/webgpu, unresolvable under moduleResolution node).
Remaining for Dustin's headset pass: haptic feel, drive-speed gain,
exhibit pedestal height, wands' squeeze ergonomics.

Original spec:
- `XRControllerModelFactory` → real motion-controller models for the
  remotes (BUNDLE the webxr-input-profiles assets locally — the
  factory's default CDN fetch violates our self-contained deploys;
  include BOTH controller families for Dustin's devices:
  oculus-touch (Quest 2) + htc-vive wands — wands have grip+trigger
  so the navigation split maps cleanly); ray + grip spaces rendered.
- `XRHandModelFactory` hand-tracking models when the device reports
  hands (feature-detected, falls back to controllers honestly).
- **Headset visibility = the desktop mirror**: the wearer never sees
  their own headset; the flat viewer (and later, peers) shows a
  headset ghost + controller/hand poses streamed from the session
  (pose → the existing viewer overlay seams). Multi-user presence
  over STOMP is xr-5, but the pose plumbing lands here.
- **Navigation has its own logic (Dustin 2026-07-11) — fast,
  intuitive, dynamic. The grip buttons ARE navigation; triggers stay
  selection** (one consistent split, documented on the wrist menu's
  help ring):
  - **Two-grip world-grab zoom**: both grips held — hands toward
    each other = zoom OUT, hands apart = zoom IN (world-grab /
    Earth-VR pattern). Implemented as scaling the user RIG about the
    midpoint between hands (nausea-safe, world stays put). The
    natural companions ride the same gesture: two-grip TRANSLATE
    (move both hands together) and two-grip ROTATE about the
    vertical axis (twist) — one gesture family, three degrees of
    control.
  - **One-grip push/pull**: a single grip press records the ORIGIN
    pose; after a brief DEBOUNCE window (the "shift event" arms —
    haptic tick marks it), the vector from origin to current hand
    position drives translation — push the world away / pull it
    toward you, magnitude growing with the vector. Pressing the
    OTHER grip cancels the shift (haptic + visual origin marker
    despawn). Dead-zone radius + response curve (linear/expo) are
    knobs; the origin point renders as a small anchor ghost while
    armed so the vector is visible.
  - **Scale-relative everything**: push/pull speed AND the user's
    INITIAL size scale from the space's extent (a molecule space and
    a room space both feel person-sized on entry). Space extent
    comes from the definition/snapshot bounds; initial user scale is
    a per-space value in XrInterfaceVariant (auto-derived, then
    editable — knob over magic).
  - **Comfort + safety rails**: scale/translation soft clamps with
    an honest at-the-limit indicator (never silent stops); optional
    motion vignette (tunneling) during shifts, on by default,
    knob-off; snap-turn knob for seated use; grips do NOT navigate
    while the wrist menu is open or a panel is grabbed (input focus
    rules — one interaction at a time).
  - **Recenter + history**: a reset-view action (home pose + default
    scale — the "I'm lost" escape), a navigation history stack
    (jump back to previous viewpoints), and saveable viewpoint
    bookmarks persisted per mode in XrInterfaceVariant; a subtle
    scale indicator (current zoom vs space default) so deep zooms
    stay oriented.
  - **Exit XR is always reachable** (Dustin): three independent
    paths — a fixed wrist-menu exit item on ring 0 (never paginated
    away), the headset's system/menu button session-end (handled via
    the XRSession 'end' event), and headset-removal auto-pause; ALL
    of them restore the flat view through the same xr-1 exit path
    (placements persisted, byte-identical flat return).

### xr-3-min — FIRST ring + the three viewing panels (Dustin's scope, 2026-07-13)

The minimum slice of xr-3, planned against the LIVE frontend (all
three flat components already exist standalone):
`sim-space-simulation-run-panel.component` (run select + play/
runBatch), `run-initial-conditions-editor.component` (ICs),
`sim-space-scrubber.component` (temporal scrub — the viewer already
exposes `hasTemporal`/`temporalSampleCount` + scrub index seams).

**STOP LINE: "able to view the simulations"** — in the headset, on
a space with a CALCULATED run: open the ring → set/inspect initial
conditions → select a run → play → scrub through recorded time
points while the 3D state animates. Everything past that is full
xr-3 (below) and explicitly deferred.

Build items:
1. **Ring-1** growing from ring-0's anchor (EXIT/RE-CENTER/HELP
   untouched): three items — RUN, CONDITIONS, SCRUB. Hardcoded seed
   list SHAPED as XrSurfaceModel rows (same fields: id, label,
   xrPlacement, panelContentRef) so the later registry decoration
   is a data move, not a rewrite. ≤3 items ⇒ no pagination/tiering
   yet; content-adaptive sizing rules apply.
2. **HTMLMesh panels for RUN + CONDITIONS**: the slim /xr view page
   mounts the REAL Angular components in an off-screen host under
   `.xr-panel-context`; three's HTMLMesh renders each as a floating
   quad at a fixed comfortable spawn offset; TRIGGER = forwarded
   pointer events to the LIVE component (behavior parity is
   automatic). Re-raster cost measured + recorded in the variant
   (res-3 idiom); the canvas fallback ladder stays available but is
   NOT built unless these two panels prove too slow.
3. **Scrubber = canvas rail, not HTMLMesh** (update-heavy — already
   on the plan's day-one fallback list): a world-anchored rail
   drawing from the same temporal seams the flat scrubber uses;
   ray + trigger drags the puck. Play/pause rides the RUN panel.
4. **Interaction (minimum dispatch)**: panels are UI surfaces like
   the wrist ring — ray-hover glow, uiEngaged blocks world gestures
   while hovering, triggers click INSIDE panels, ONE-grip drag on a
   hovered panel repositions it. Two-grip resize, distance-grab,
   texture-cap tiling, flat↔XR open-panel transitions: DEFERRED to
   full xr-3. Placements persist per mode via the existing
   XrInterfaceVariant merge.
5. **Dismiss**: each panel carries a small ✕; its ring item toggles.

Acceptance: the stop-line scenario end-to-end on staging + iwer
specs (ring spawn, HTMLMesh presence + forwarded click, scrub
drives the temporal index); flat suite untouched; placements
survive exit/re-enter.

Open questions flagged for Dustin before build:
- **Q-A (play semantics)**: is playing back an ALREADY-calculated
  run the stop line (plan default), with triggering runBatch from
  VR allowed but its progress display crude?
- **Q-B (scrubber home)**: world-anchored grabbable rail (plan
  default) vs wrist-anchored?
- **Q-C (IC editing input)**: rasterized DOM text fields may not
  summon the system keyboard in Wolvic — day one, IC editing in VR
  should lean on steppers/sliders/increment controls; free-text
  entry stays a flat-mode task until proven. Acceptable?

### xr-3 — the XR interface system: wrist menus + spatial page-panels
(Dustin 2026-07-11.) The standardization phase: ONE declarative
surface model renders as docked webview chrome in flat mode and as
wrist menus + floating pages in XR — clean, equivalent transitions
both ways.

**Terminology**: the "left-wrist circle menu" style is a
**wrist-anchored radial menu** (a.k.a. pie menu / wrist menu);
multiple circles = tiered/paginated radial rings.

- **`XrSurfaceModel` — menus and panels as DATA** (the house
  config-driven-rendering idiom): every piece of SimSpace-adjacent
  chrome declares itself once —
  `{kind: 'menu-item' | 'panel', id, label/icon, action or
  panelContentRef, flatPlacement: right|top|bottom dock / tab,
  xrPlacement: wrist-ring N / spawnable-page}` — and each mode's
  renderer consumes the SAME model. No hand-maintained parallel
  menus; parity is by construction.
- **Wrist radial menus**: the flat UI's "shortened" docked menus
  (right/top/bottom toolbars) re-style into left-wrist-anchored
  radial rings — items packed ~6-8 per ring MAX, with the actual
  per-ring count CONTENT-ADAPTIVE (Q6 resolved: legibility is the
  binding constraint — button text + purpose must read at wrist
  distance, so long labels mean fewer, larger buttons); overflow
  iterating into further rings/pages exactly as Dustin described;
  partial arcs when a ring is underfull. Ray/pinch to select;
  handedness KNOB (left wrist assumes a right-hand pointer — must be
  flippable). Wrist-anchoring follows the grip/hand pose from xr-2.
- **Spatial page-panels — spend the infinite space**: the panels the
  webview crams into side sections (details, stepping + simulation
  control panel, snapshot evaluation equations, conformance findings,
  …) render in XR as FULL floating pages — each an independent quad
  the user spawns from the wrist menu, grabs, repositions, and
  dismisses.
  **Why not real webviews (Dustin asked 2026-07-11)**: inside an
  immersive session the browser composites ONLY the WebGL layer —
  live DOM cannot appear in-scene (window.open windows surface only
  after leaving immersion; DOM→texture capture is forbidden by the
  security model; DOM Overlay = one flat screen-locked overlay,
  AR-oriented; Layers API quads take WebGL/media, not DOM). This is
  a platform boundary, not a design choice.
  **Panel rendering ladder (best available fidelity, honestly
  degraded)**:
  1. **HTMLMesh rasterization of the REAL Angular panels** (three's
     jsm HTMLMesh idiom: same-origin DOM → canvas texture +
     controller-ray pointer events forwarded to the LIVE component)
     — the floating page IS the actual panel component rendered
     off-screen; behavior parity is automatic. Limits: same-origin
     only, CSS subset, re-rasterize-on-change cost.
  2. **Data-driven canvas renderer** for panels where rasterization
     is too slow (high-frequency updates: live stepping traces) or
     the CSS subset bites — draws from the same panel definitions.
  Per-panel choice recorded in XrInterfaceVariant (a knob, with the
  measured re-raster cost as its evidence — res-3 idiom).
- **XR panels expand to CONTENT size (Dustin 2026-07-11)** — unlike
  the cramped webview, an XR page grows to whatever it wants to be:
  - The off-screen host mounts under an `.xr-panel-context` wrapper
    class + provides an `XR_PANEL_CONTEXT` Angular injection signal.
    A global stylesheet scoped to that class REACTIVELY lifts the
    flat-view constraints (max-heights → none, scroll containers →
    visible, width → max-content, virtual scrolling → render-all);
    components that want structural changes (auto-expand accordions,
    show-all rows) read the injection signal — one context, two
    reaction levels (CSS for free, DI for deliberate).
  - The quad's WORLD size follows the content size (space is
    infinite; a tall panel is simply tall). Texture memory is NOT
    infinite: content within the device texture cap renders 1:1;
    beyond it the panel TILES across multiple quads seamlessly
    (never silent downscaling into unreadability — the honest
    degradation is more tiles, not blur).
- **Grab the PANEL vs move the SPACE — target-based grip dispatch
  (Dustin flagged the interaction needs thought; this is the
  resolution)**: what a grip press does is decided by what the
  controller ray targets AT PRESS TIME:
  - Ray on a panel + grip → grab THAT panel (move it with the hand;
    release drops it in place). Both grips on the same panel →
    resize/rescale the panel (the world-grab metaphor at panel
    scope — one mental model everywhere).
  - Grip in empty space → world navigation exactly as specified in
    xr-2 (zoom/shift). The xr-2 focus rule generalizes: the
    press-time target OWNS the gesture until release; mid-gesture
    retargeting never happens.
  - **Affordance preview before commitment**: ray-hover outlines the
    panel (hover glow) so the user always knows whether the next
    grip grabs the page or the world — no guessing, no misfires.
  - Optional comfort action (knob): point + grip-tap pulls a distant
    panel to arm's length (distance-grab) rather than walking to it.
  - Trigger stays selection INSIDE panels (forwarded pointer events
    to the live component) — grips never click, triggers never move.
- **Clean transitions both directions**: entering XR maps currently
  open flat panels → spawned pages (restored placements from the
  space's XrInterfaceVariant); exiting persists page placements back
  into the variant and restores the flat docks. The per-mode
  placements are exactly what `XrInterfaceVariant.config_json`
  stores (xr-1) — so a hydroponics space keeps its flat, VR, and AR
  arrangements independently, never overwritten by mode switches.
- **Interaction parity**: controller-ray picking mapped onto the
  EXISTING renderer seams (`pickAt`/`setHighlight`/`setSelection`/
  `onObjectClick`) so object selection behaves identically flat and
  immersed; enter/exit UX polish (session-end, tab-blur,
  device-sleep all restore honestly).

**The sim-space interface map (worked 2026-07-11 from the live
frontend inventory — §0 last bullet)** — the concrete answer to
"what are the XR interfaces for the simulation spaces".

The pivot: `XrSurfaceModel` does NOT invent a panel catalog. The
catalog already exists — `DISPLAY_COMPONENT_REGISTRY` entries + the
viewer's fixed chrome — so the surface model DECORATES existing
registry entries with `xrPlacement`, and the Display grid config is
the flat-placement side of the same mapping. Panel identity is
`(componentName, inputs)` in both worlds; flat placement stays in
the Display config exactly as today, XR placement lives in
`XrInterfaceVariant`. Parity by construction, no parallel catalog
to drift.

Surface-by-surface (flat anchor → XR presentation → rendering rung):

| flat surface | XR presentation | rung |
|---|---|---|
| editor sidebar (icon rail → View / Solutions / Axis labels / Scene info accordion) | wrist ring 1 = the four sections as category items; each spawns its section as a page; the View overlay toggles flatten to ring toggle-items | HTMLMesh (occasional) |
| simulation run panel (run picker, New Run, ICs, Step Once, batch Run…, traces) | SPLIT: play/step + run-status glyph pinned on wrist ring 0 (beside exit); the full panel incl. IC editor + solution traces = spawnable page | HTMLMesh; trace rows → canvas if re-raster bites |
| scrubber (timeline) | a grabbable timeline RAIL world-anchored at the space's base — trigger-drag the puck; duplicated on the run page | canvas (per-drag live) |
| axis legend | rendered AT the axes in-scene (the label lives at the thing it describes — [[object-coherence]]); wrist toggle hides it | in-scene text, not a panel |
| scene-contents legend | spawnable page | HTMLMesh |
| evaluation selector + overlay | spawnable page(s); equation grids are a named canvas-fallback candidate (§4 Q7) | HTMLMesh→canvas |
| hover tooltip (DOM overlay today) | in-scene billboard at the hovered object (DOM can't appear in-session) | canvas billboard |
| error/warning banners, scrub hint | brief head-locked toast (seconds), then a wrist notification pip — never a permanent HUD | canvas |
| msim run-control bar (Run select, Steps, Play, Step Once) | the SAME wrist ring 0 items — one stepping surface in both contexts | — |
| msim panels (IC, explainer, formulation search, family graph, graph, conformance, stage strip) | each = spawnable page straight from its registry entry; graph + family-graph are per-step live → canvas rung; the stage strip's gate glyphs also mirror as a compact wrist-ring badge | per-entry knob |
| configure editors (spaces/stages/couplings/ics/panels) | spawnable pages (static config — the natural HTMLMesh case) | HTMLMesh |
| class-main-page (the click-navigate target) | NEVER a route navigation in-session (it would tear down the world). Selection spawns the object's page as a floating panel instead | HTMLMesh |

- **Selection in XR**: trigger-select through the existing `pickAt`
  seam; `clickNavigates` is forced OFF in-session. A selected object
  gets an **object radial** (same radial idiom as the wrist,
  anchored at the object): open details (floating class-main-page
  panel), pin a readout, highlight/isolate. The selection-overlay
  registry (SelectorOverlayOrchestrator + selection-overlay-registry)
  renders as in-scene billboards positioned by world transform
  instead of `getObjectScreenRect`.
- **Pinned in-scene readouts** (confirmed Dustin 2026-07-11 — panels
  AND billboards, per-object knob): any watched property can be PINNED
  from the object radial as a small billboard AT its object. Pinning
  is deliberate, per-object, persisted in XrInterfaceVariant;
  default = none pinned. Panels remain the full data surfaces.
- **Stepping semantics**: "play" is a batch of backend steps — the
  wrist play item shows the batch spinner/status, there is no speed
  slider to port; steps-count + dt-override live on the full run
  page.
- **Framing + entry scale (confirmed Dustin 2026-07-11; rides the
  xr-1 ladder)**: a second cascaded value
  `xr_framing: 'unset'|'inside'|'exhibit'` resolved
  individual→multiscale→type→global exactly like `xr_mode`, with
  provenance. 'inside' = person-scale entry within the space (rooms:
  hydroponics layout, wind volume); 'exhibit' = the space presents
  as a pedestal-scale model you orbit/world-grab (pendulum,
  molecule, lattice). Both are only the INITIAL rig scale+pose — the
  xr-2 world-grab moves freely between them afterward.
- **The msim multi-space presentation (the new thing XR buys)**: the
  multi-scale page mounts N scene panels that flat mode crams into
  grid cells. In XR the N registered scenes present as a **gallery**
  of live exhibits arranged around the user — each on its own stand,
  labeled from its panel title, stage-gate glyphs on the stand.
  Pointing + entering one PROMOTES it to the world ('inside' at its
  resolved scale); the gallery is reachable back through the wrist
  ring. Scene promotion is the xr-1 registry scene-swap — never a
  second session. The comparison-run twin scene stands NEXT to its
  primary for side-by-side. Gallery arrangement (arc radius, stand
  height, per-space placement) persists in the msim's
  XrInterfaceVariant.

**Acceptance**: surface-model parity assert (every flat menu item
reachable in the wrist rings, count-exact; overflow paginates);
iwer-driven spec spawns/moves/dismisses pages and round-trips
placements through XrInterfaceVariant; stepping a simulation from an
XR control page equals the flat control panel's effect; handedness
knob flips the anchor wrist. Sim-space map: every registered msim
display component spawnable as a page (registry-driven,
count-exact); `clickNavigates` suppressed in-session with the object
radial offered instead; `xr_framing` resolution proven at type +
individual levels with provenance; msim gallery round-trip (N scenes
→ gallery → promote one → return to gallery) stays in ONE session
with placements persisted.

### xr-4 — AR: rooms, surroundings, distances (the destination)
`immersive-ar` sessions on the SAME engine (session mode is a
parameter, not a second engine); this phase lights up the 'ar' leg
of the xr-1 mode knob — AR-configured spaces' Enter-AR button goes
live here:
- **hit-test** + **anchors** (+ plane detection and depth where the
  device offers them; every feature detected + degraded honestly).
- **Measure tool**: two-point (and chained) real-world distance
  measurement via hit-test — the "mapping out surroundings and
  distances" capability.
- **Layout placement**: place REAL-SCALE aquaponics towers/pots/
  hydroponics fixtures (mathshapes + aquaponics geometry already
  model them) into the room; construction-planning objects likewise.
- **Capture back into Polari (object-coherence)**: a framework-side
  `ArLayoutCapture` treeObject (points, measured distances, anchor
  transforms, placed-object refs, room label) POSTed via CRUDE; a
  completed capture shows a SUGGESTION CARD offering promotion to a
  SimSpace definition (Q4 resolved: suggest, never auto-apply; the
  manual promote knob remains underneath) so simulations
  (hydroponics layout, construction) run against the MEASURED room.
  This is where AR meets the sim stack. Device honesty: neither of
  Dustin's current headsets (Quest 2, Vive) does usable passthrough
  AR — this phase's live verify waits on phone AR or future
  hardware; the honesty matrix names the gap on current devices.
- DOM-overlay UI for the AR controls (supported on the target
  browsers; falls back to in-scene controls).

### xr-5 — later, explicitly out of scope now
Full flat-rendering consolidation (one renderer + scissored
viewports for ALL panels) only if context limits bite in practice;
VR entry for OTHER 3D surfaces if any appear outside
sim-space-viewer. **Multi-user presence DROPPED (Dustin 2026-07-12:
research app for building intuition about data, not a social app)**
— the desktop-mirror ghost from xr-2 covers the demo-to-a-colleague
case; if a collaboration story ever materializes, the STOMP
per-class routing note from the original sketch still applies.

## 3. Verification strategy (no headset on the staging box)

- **iwer** (Immersive Web Emulator Runtime, Meta's JS WebXR runtime
  injection) drives automated specs: session grant, controller +
  hand pose playback, hit-test synthesis for the AR measure tool.
  This is the selftest idiom for XR — every phase ships specs that
  run headless in CI/karma.
- Live verification on real hardware is Dustin-side, on BOTH
  devices: Quest 2 browser → https://prf.192.168.0.210.nip.io after
  /cert-trust, and the Vive via a SteamVR-backed desktop Chrome/Edge
  opening the same URL (cert trust is the desktop browser's, easier).
  Phases are ordered so each ships something he can put on a headset.

## 4. Open questions — ALL RESOLVED (Dustin 2026-07-11/12;
   "other defaults are fine" confirms Q7-tail + Q8 at their stated
   defaults). Nothing blocks xr-1.

1. **Target devices**: RESOLVED — Dustin owns a **Quest 2** AND an
   **HTC Vive** (model TBD; every Vive variant reaches WebXR the
   same way: PC-tethered, SteamVR as the OpenXR runtime, the session
   served by desktop Chrome/Edge). BOTH must work; assume a full
   headset for now (no phone AR yet). Implications: bundle
   webxr-input-profiles for BOTH controller families (oculus-touch
   + htc-vive wands — wands have grip+trigger, so the xr-2
   navigation model maps cleanly); the Vive verify path is the
   staging URL in a SteamVR-backed desktop browser. AR honesty:
   NEITHER device offers usable passthrough AR — the xr-4 honesty
   matrix will say so on these devices; AR arrives via phone or
   future hardware, plan unchanged.
1b. **Type vocabulary for XrTypeDefault**: RESOLVED — SimSpaces get
   an explicit **category** field (define categories; they don't
   exist today), with the owning MODULE binding supplying the
   DERIVED default category (knobs-and-suggestions: module → 
   suggested category, editable per definition; explicit category
   always wins). `XrTypeDefault` (and the xr_framing seeds, Q9) key
   on the category; a definition with no category and no module
   binding resolves past the type level to global.
2. **Locomotion default**: RESOLVED — ignore teleport for now; the
   xr-2 grip navigation (world-grab + push/pull) is the only
   locomotion.
3. **Presence priority**: RESOLVED — NO multi-user presence. This is
   a research app for helping researchers build intuition about
   data, not a social app. The desktop-mirror ghost stays (it serves
   the researcher demoing to a colleague at the screen); the xr-5
   multi-user item is DROPPED from the roadmap.
4. **AR capture promotion**: RESOLVED — show a suggestion card for
   converting a measured room into a SimSpace definition (suggest,
   never auto-apply; the manual promote knob remains underneath).
5. **Renderer lifecycle**: RESOLVED — dispose on exit; re-entry
   pays the moment of setup, resources freed between sessions.
6. **Wrist-menu ergonomics**: RESOLVED — 6-8 per ring as the
   starting point, but capacity is CONTENT-ADAPTIVE: the binding
   constraint is LEGIBILITY — the button's text and purpose must be
   readable at wrist distance — so rings pack fewer, larger buttons
   when labels run long (measured label size drives per-ring count,
   6-8 is the cap not the target). Pagination + handedness defaults
   stand (swipeable ring pages on one anchor; left wrist +
   right-hand pointer, flippable).
7. **Panel rendering default**: RESOLVED 2026-07-11/12 — HTMLMesh
   rasterization of the real Angular panels is the default (real
   components, forwarded interaction), data-driven canvas renderer
   as the per-panel fallback knob for update-heavy panels. Day-one
   fallback list (defaults confirmed): the live graph panels
   (msim-graph-panel + msim-family-graph-panel), the scrubber rail,
   and live stepping trace rows; everything else ships on HTMLMesh.
8. **Navigation tuning**: RESOLVED at defaults (confirmed
   2026-07-12) — one-grip shift debounce ~250ms, modest dead-zone
   radius, linear response curve to start (expo as the knob's other
   value), vignette-on-shift default ON; navigation stays
   controller-grip-only until the xr-2 hand-tracking work
   stabilizes, then pinch-and-hold maps the same gestures. All of
   these remain knobs.
9. **Framing seeds**: RESOLVED (Dustin confirmed 2026-07-11) — the
   `xr_framing` cascade defaults by type: hydroponics-layout +
   wind-volume spaces seed 'inside', object-like spaces (pendulum,
   molecule, material lattice) seed 'exhibit'. Only the
   anchor-vocabulary part remains open (shared with 1b: what keys
   the type rows).
10. **msim gallery behavior**: RESOLVED (Dustin confirmed
   2026-07-11) — arc around the user; non-promoted scenes
   freeze-with-badge above ~4 live scenes (knob), refresh-on-gaze.
11. **Pinned readouts**: RESOLVED (Dustin confirmed 2026-07-11) —
   panels + per-object pinnable billboards, deliberate pin from the
   object radial, none by default. Pins are mode-independent DATA
   with per-mode visibility: they also render in the flat viewer as
   overlay chips (same preservation rule as XrInterfaceVariant —
   the pin set is configuration, mode decides presentation).
12. **Stepping quick-actions**: RESOLVED (Dustin confirmed
   2026-07-11) — play/step + status glyph pinned on wrist ring 0
   next to exit, full run panel as a spawnable page. Controller
   face-button mapping rejected (burns buttons, needs a legend).

## 5. Relation to existing work
- sim-space renderer interface + factory = the seams; nothing outside
  sim-space-3d/ touches three (firewall preserved).
- `DISPLAY_COMPONENT_REGISTRY` + the Display grid model = the flat
  side of XrSurfaceModel; msim-display-components.ts (and the msci
  twin) are the ready-made panel catalogs the wrist menu enumerates.
- aquaponics/mathshapes geometry = the AR-placeable objects.
- STOMP per-class routing (modsplit-3) = the presence/pose transport
  when xr-5 arrives.
- The 3D asset libraries (mesh/material/texture) are already root
  singletons — shared with the XR engine as-is.
