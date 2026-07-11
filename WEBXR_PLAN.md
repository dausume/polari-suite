# WebXR VR/AR Spaces — Plan (xr-1..5)

**Written 2026-07-11 from Dustin's directive; PLANNED, not built.**
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
| type | `XrTypeDefault` rows keyed by simulation/space kind | "hydroponics-layout spaces default 'ar'"; "msim worlds default 'vr'" |
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
- `XRControllerModelFactory` → real motion-controller models for the
  remotes (BUNDLE the webxr-input-profiles assets locally — the
  factory's default CDN fetch violates our self-contained deploys);
  ray + grip spaces rendered.
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
  radial rings — items packed ~6-8 per ring (comfort), overflow
  iterating into further rings/pages exactly as Dustin described;
  partial arcs when a ring is underfull. Ray/pinch to select;
  handedness KNOB (left wrist assumes a right-hand pointer — must be
  flippable). Wrist-anchoring follows the grip/hand pose from xr-2.
- **Spatial page-panels — spend the infinite space**: the panels the
  webview crams into side sections (details, stepping + simulation
  control panel, snapshot evaluation equations, conformance findings,
  …) render in XR as FULL floating pages — each an independent quad
  the user spawns from the wrist menu, grabs, repositions, and
  dismisses. Rendered from the same panel DEFINITIONS the flat app
  uses (canvas-texture panel renderer over the panel's data — NOT
  DOM capture, which browsers don't allow into WebGL); interactive
  controls (step, play, scrub) fire the same service calls as their
  flat twins.
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

**Acceptance**: surface-model parity assert (every flat menu item
reachable in the wrist rings, count-exact; overflow paginates);
iwer-driven spec spawns/moves/dismisses pages and round-trips
placements through XrInterfaceVariant; stepping a simulation from an
XR control page equals the flat control panel's effect; handedness
knob flips the anchor wrist.

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
  knob-guarded promotion turns a capture into a SimSpace definition
  so simulations (hydroponics layout, construction) run against the
  MEASURED room. This is where AR meets the sim stack.
- DOM-overlay UI for the AR controls (supported on the target
  browsers; falls back to in-scene controls).

### xr-5 — later, explicitly out of scope now
Full flat-rendering consolidation (one renderer + scissored
viewports for ALL panels) only if context limits bite in practice;
multi-user presence (headset/hand pose ghosts shared over STOMP —
the directory already routes per-class notifications, so presence
rows ride the existing transport); VR entry for OTHER 3D surfaces if
any appear outside sim-space-viewer.

## 3. Verification strategy (no headset on the staging box)

- **iwer** (Immersive Web Emulator Runtime, Meta's JS WebXR runtime
  injection) drives automated specs: session grant, controller +
  hand pose playback, hit-test synthesis for the AR measure tool.
  This is the selftest idiom for XR — every phase ships specs that
  run headless in CI/karma.
- Live verification on real hardware is Dustin-side (Quest browser →
  https://prf.192.168.0.210.nip.io after /cert-trust); phases are
  ordered so each ships something he can put on a headset.

## 4. Open questions for Dustin (answer before xr-2/xr-4)

1. **Target devices**: Quest 2/3 browser first? Phone AR (Chrome
   Android) for the hydroponics layout use case, or Quest 3
   passthrough — or both?
1b. **Type vocabulary for XrTypeDefault**: what IS the "kind" key —
   SimSpaceDefinition's kind/dimensionality, the simulation intent
   (observe/search/calibrate), the owning module (aquaponics/msim/
   msci), or a new explicit space-kind field? The seeded type
   defaults (msim worlds → 'vr', hydroponics layout → 'ar') need the
   right anchor before xr-1 builds the rows.
2. **Locomotion default**: teleport vs orbit-the-model (museum mode)
   — matters for sim spaces that are "objects on a table" vs "rooms".
3. **Presence priority**: is seeing ANOTHER user's headset/hands
   (multi-user) wanted early, or is the desktop-mirror ghost enough
   until the collaboration story matures?
4. **AR capture promotion**: should a measured room auto-suggest a
   SimSpace definition (suggestion card), or stay a manual promote
   knob only?
5. Keep the XR renderer warm between sessions (faster re-entry, holds
   a GPU context) or dispose on exit (frees resources)? Default:
   dispose.
6. **Wrist-menu ergonomics**: items per ring (default ~6-8), partial
   arcs vs full circles for underfull rings, and whether ring
   pagination is spatial (stacked rings up the forearm) or temporal
   (swipe between ring pages on one anchor). Handedness default:
   left wrist + right-hand pointer, flippable.
7. **Panel content fidelity**: the canvas-texture panel renderer
   redraws panel DATA (tables, values, equations, controls) — it is
   not a pixel-perfect copy of the webview CSS. Acceptable, or should
   heavy panels (e.g. equation displays) get bespoke XR layouts in
   their XrInterfaceVariant from day one?
8. **Navigation tuning**: debounce window length for the one-grip
   shift (default ~250ms?), dead-zone radius, response curve
   (linear vs expo), vignette default on/off, and whether hand
   tracking (no grips) maps the same gestures to pinch-and-hold —
   or navigation stays controller-only until xr-2 hand work
   stabilizes.

## 5. Relation to existing work
- sim-space renderer interface + factory = the seams; nothing outside
  sim-space-3d/ touches three (firewall preserved).
- aquaponics/mathshapes geometry = the AR-placeable objects.
- STOMP per-class routing (modsplit-3) = the presence/pose transport
  when xr-5 arrives.
- The 3D asset libraries (mesh/material/texture) are already root
  singletons — shared with the XR engine as-is.
