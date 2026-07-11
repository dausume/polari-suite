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

**The per-space mode KNOB (Dustin 2026-07-11): a sim-space is
CONFIGURED as an AR space or a VR space** — many interfaces only
make sense in one of the two (a hydroponics room layout is an AR
space; an abstract simulation world is a VR space).
[[object-coherence]]: the knob lives ON the definition —
`SimSpaceDefinition.xr_mode: 'none' | 'vr' | 'ar' | 'both'`
(framework field + migration-free default 'none'; editable through
the definition's existing CRUDE/config surfaces like dimensionality
is). The viewer renders the enter affordance FROM the knob:
- 'vr' → Enter VR only; 'ar' → Enter AR only; 'both' → both buttons;
  'none' → no XR affordance at all (flat-only spaces stay clean).
- Honesty matrix = knob × device capability: a space configured 'ar'
  on a VR-only headset shows the disabled button naming the missing
  capability (and vice versa) — configuration says what the space IS,
  capability says what this device CAN do, and the UI never conflates
  the two.
- The ENGINE is mode-agnostic (session mode is a request parameter,
  one engine serves both) — xr-1 ships the knob + the VR leg;
  the AR leg's session plumbing arrives with xr-4 but the knob,
  affordances, and refusals are complete from xr-1 so AR-configured
  spaces are honest ("AR arrives with xr-4") rather than silent.

**Acceptance**: multi-scale page with N 3D panels → ONE engine, one
session, enter/exit/switch between panels; xr_mode knob round-trips
through CRUDE and drives the affordances (all four values); no
per-viewer XR loading (bundle assert: XR code absent from initial +
flat chunks); iwer-driven spec (below) green; existing 3D pages
unregressed.

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
- Basic locomotion knob: teleport (controller ray + squeeze) and/or
  orbit-at-scale; default teleport, both feature-flagged.

### xr-3 — interaction parity inside VR
Controller-ray picking mapped onto the EXISTING renderer seams
(`pickAt`/`setHighlight`/`setSelection`/`onObjectClick`) so selection
behaves identically flat and immersed; a minimal in-VR label/HUD
(sprite-based, no new heavy deps) surfacing the same object labels
the flat overlays show; enter/exit UX polish (session-end events,
tab-blur, device-sleep all restore honestly).

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
1b. **Default xr_mode for EXISTING sim spaces**: all start 'none'
   (explicit opt-in per space), or should the seeds classify the
   obvious ones (msim worlds → 'vr', aquaponics layout spaces →
   'ar') as suggestions to accept?
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

## 5. Relation to existing work
- sim-space renderer interface + factory = the seams; nothing outside
  sim-space-3d/ touches three (firewall preserved).
- aquaponics/mathshapes geometry = the AR-placeable objects.
- STOMP per-class routing (modsplit-3) = the presence/pose transport
  when xr-5 arrives.
- The 3D asset libraries (mesh/material/texture) are already root
  singletons — shared with the XR engine as-is.
