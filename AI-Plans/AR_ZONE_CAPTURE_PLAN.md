# AR Zone Capture plan (arz) — 2026-07-17

Dustin's goal (verbatim intent): capture a 3D area ("zone") in Augmented
Reality so it can be populated with VR objects — size simulated objects,
place them in a zoned space, see what it looks like. Target simulation:
**0.25 m cubes** — an algorithm estimates the real distance between
points placed in space in AR, calculates the ground area and overall
volume, then populates the allotted space with however many cubes fit,
stacking them.

STATUS (2026-07-17, Dustin: "attempt implementing capturing points —
3 points minimum for a volume, or more to make a shape in the air"):
**arz-1..4 BUILT + LIVE-VERIFIED on staging** — zones/ module
(SiteDefinition/ZoneDefinition/ZonePoint/ZoneEstimateRecord + demo
seeds), zone_geometry (prism + hull + calibration; 3 ground points =
minimal triangle volume, 3 free points degrade honestly to a planar
triangle, 4th makes the hull volume), zone_packing (min-corner
anchored lattice, full-cell/center knob, site summary), ZonesAPI
(capture/estimate/distances/pack/calibrate/site-summary), selftest
27/27 (also in-container), /display/zones seeded. **arz-5 BUILT,
awaiting headset session**: /xr/zone-capture page + capture runtime
(immersive-ar→vr fallback, unbounded→local-floor recorded; trigger
place / grip undo / both-grips-2s commit; thumbstick-click kind
cycling; distance-label sprites; packed cubes rendered as
InstancedMesh on commit). arz-6 stop line = the headset pass.
Everything UNCOMMITTED, inside the same review gate as the PSC passes.

REWORK (same day, Dustin's refinements — all BUILT + LIVE-VERIFIED):
- **Two capture modalities.** 'planar' (the auto default): dot
  placement is assumed imperfect — heights are AVERAGED and the dots
  are forced into a horizontal plane at that height; the volume is
  that plane extruded down to an identical plane on the floor
  (planarSpreadRmsM reported as capture-quality evidence). 'hull' is
  the manual "Direct 3D" mode you explicitly switch to: free dots,
  forced into a single 3D shape on finalize, no auto-commit. 'prism'
  (fitted plane + height points) kept backend-only.
- **Rooms vs selections.** zone_role 'room'|'selection' +
  room_zone_name: packing targets the SELECTED zones; filling a whole
  room stays available by packing the room zone itself (kept
  deliberately). /api/zones/{name}/room-summary + the reworked site
  summary report BOTH volumes — the room's and the selections'
  (demo-house live: room 1.5 m³ vs selected 1.25 m³ / 80 cubes).
- **20-second debounce** in planar mode: the XR runtime auto-forms
  the plane→volume 20 s after the last dot (≥3 dots; HUD countdown
  below 15 s; any dot/undo resets; both-grips commits immediately).
  Direct 3D finalizes only manually.
- Selftest now 37/37; deploy note: adding zone_role/room_zone_name to
  already-seeded rows required the known explicit-CRUDE-PUT backfill
  (seed-field-addition gotcha).

SECOND REWORK (same day — Real Constraints ↔ Simulation + board):
- **Two named modes** (Dustin): "Real Constraints Mode" = capturing
  zones/rooms, the basis for running simulations and mapping them
  into reality; "Simulation Mode" = the other side of the swap. The
  sim-space wrist RING MENU is reused in zone capture (XrWristUi is
  data-driven) with ring items SWAP MODES + BOARD; zones will act as
  sim spaces down the line.
- **zones/zone_sim_bridge.py** (selftest 43/43, live): zone_constraints
  (reality as numbers), ensure_zone_sim_space ('<zone>-space'
  SimSpaceDefinition, xr_mode 'both', persisted), and
  ensure_zone_ic_interface — an InitialConditionInterfaceDefinition
  ('zone-ic--<zone>', choicePreset) whose single choice applies the
  captured constraints as setParams, flowing through the EXISTING
  validate→create-run→step-0 override path (and the XR CONDITIONS
  panel) untouched. Routes: GET /api/zones/{name}/constraints, POST
  /api/zones/{name}/to-simulation (the Swap-Modes act).
- **Rooms/zones board**: /zones-board route + 'zones-board' display
  component (horizontal bar of rooms → their zones with data,
  per-zone estimate drill-in; site + cube-size knobs). Deliberately
  overlay-free DOM so the SAME component renders in the web view, on
  /display/zones (seeded as the page's top row), and as an XR
  HTMLMesh panel.

## Ground rules
- Reuse the proven XR primitives (xr-1/xr-2: session entry, movement,
  controllers/hands on Vive XR Elite + Wolvic). **HTMLMesh panels WORK
  on device** (Dustin 2026-07-17 correction — the xr-3 failure is
  narrower: the scrubber, a grabbable 3D object, was not BINDING to its
  data; rendering/interaction of HTMLMesh itself is fine). So panels are
  allowed here (e.g. a zone list / commit panel) — but keep live
  data-binding INTO in-world 3D objects simple, since that binding path
  is where the known bug lives. Core capture interactions stay
  primitive: trigger = place point, grip = undo, both-grips-hold =
  commit.
- Object coherence: zones are object-tree rows (auto DB + CRUDE), every
  estimate is an evidence-bearing report, every tolerance is a knob.
- Every phase lands with a selftest + a desktop-testable surface — the
  headset is required only for the true-AR acceptance pass, never for
  development.

## Phases

### arz-1 — Zone data model (framework: new `zones/` module)
- `SiteDefinition`: name, display_name, notes — the HOUSE (or lot): a
  named collection of zones captured room-by-room, so "how much fits in
  the whole house" is a first-class question (Dustin 2026-07-17).
- `ZoneDefinition`: name, display_name, site_name (optional — zones can
  be free-standing), room_label ('kitchen', 'garage'…), capture_kind
  ('ar-headset' | 'desktop-authored'), origin_note (what the zone-local
  origin anchors to in the real room), scale_correction (default 1.0 —
  see arz-2 calibration), status ('capturing' | 'committed'),
  captured_by, notes.
- `ZonePoint`: zone_name, index, kind ('ground' | 'height' |
  'reference'), x/y/z (METERS, zone-local; WebXR local-floor space is
  already metric — y up), confidence ('tracked' | 'estimated'), notes.
- `ZoneEstimateRecord`: persisted estimate verdicts (area, volume,
  model, residuals, computed_at) so a zone's history is inspectable.
- Selftest: CRUD + ordering + kind validation. Classes into defClassList
  + seed_pairs (empty seeds; zones are runtime data).

### arz-2 — Geometry engine (`zones/zone_geometry.py`, pure python)
The "estimate real distances → area → volume" algorithm:
1. **Distances**: pairwise metric distances directly from point
   coordinates (WebXR is metric). The real error source is tracking
   drift + hand pointing, NOT units — so calibration is a first-class
   knob: the user may place two 'reference' points across a KNOWN real
   length (tape-measure a 1.000 m stick); `scale_correction =
   known/measured`, applied to all estimates, surfaced in every report
   (`identitySource`-style honesty: 'calibrated' vs 'uncalibrated').
2. **Ground plane**: least-squares plane fit over 'ground' points;
   report the RMS residual as capture-quality evidence (knob:
   max_residual_m, default 0.05 — exceeding it yields a
   suggestion-to-recapture, never a silent proceed).
3. **Footprint polygon**: ground points projected onto the fitted
   plane, ordered AS PLACED (walk-the-perimeter capture UX);
   self-intersection check refuses with the crossing pair named
   (suggestion: reorder or recapture). Knob: auto_hull (default false)
   to fall back to convex hull instead of refusing.
4. **Area**: shoelace formula on the projected polygon.
5. **Height + volume v1**: prism model — height = median of 'height'
   points' distance above the plane (knob: percentile), volume = area ×
   height. The report carries `model: 'prism'` explicitly; irregular
   ceilings are a later model, not a silent approximation.
- Selftest with exact known shapes (unit square, 2×3 rectangle, L-shape,
  tilted plane, self-intersecting refusal, calibration correction).

### arz-3 — Cube packing (`zones/zone_packing.py`)
Dustin's target simulation:
- `pack_zone(manager, zone_name, cube_size=0.25, ...)`:
  - Rasterize the footprint polygon at cube_size; a cell holds a cube
    when its FULL square lies inside the polygon (knob: fit_test
    'full-cell' | 'center' — center overestimates, full-cell is the
    honest default).
  - Layers = floor(height / cube_size); stacked identically (v1; knob
    placeholder for per-layer setback later).
  - Report: cubes_per_layer, layers, total_cubes, ground_area,
    footprint_utilization (cube area / polygon area — the honest edge
    loss), volume_utilization, and the placement lattice (origin +
    indices, NOT one dict per cube — the frontend expands it; keeps a
    10k-cube zone's payload tiny).
- API (self-registering `ZonesAPI`, authority_api pattern):
  - `GET /api/zones/{name}/estimate` → distances/area/volume verdict
  - `POST /api/zones/{name}/pack` {cube_size?, fit_test?} → packing report
  - `POST /api/zones/capture` — create zone + points in one commit
    (the headset flow's single write).
  - `GET /api/sites/{name}/summary` {cube_size?} — the HOUSE aggregate:
    per-room area/volume/cube-count breakdown + totals. Crucially this
    needs NO globally consistent coordinate frame — each zone is
    metrically sound in its own local frame, and counts/volumes sum
    regardless of where rooms sit relative to each other. (A combined
    all-rooms 3D view is the only thing that would need cross-zone
    registration — deferred, see open question 4.)
- Selftests: 1×1×0.5 m zone → 16 cubes/layer × 2 layers = 32; L-shape;
  utilization arithmetic; degenerate (<3 ground points) refusal.

### arz-4 — No-code + desktop surfaces (no headset required)
- Seeded Display page `/display/zones` (module_pages_seed pattern):
  class-rows-table of ZoneDefinition/ZonePoint + api-json-panel of the
  demo zone's estimate + packing (seed ONE demo zone with hand-authored
  points so the page renders live numbers).
- Desktop zone author/inspector in SimSpace3D: render zone points,
  fitted polygon, and packed cubes (instanced mesh from the lattice) in
  the existing three-renderer — this is ALSO the dev-loop visualization
  for arz-5 and the "see what it looks like" check without a headset.

### arz-5 — AR capture (polari-platform-angular XR)
- Session: immersive-ar (Wolvic passthrough on Vive XR Elite) with
  immersive-vr fallback (same flow floating in void; capture still
  works — the zone doesn't care which session type placed it).
- **Moving around in AR / multi-room capture**: physical walking IS the
  locomotion in AR — inside-out 6DoF tracking follows you anywhere, and
  passthrough means no guardian-style confinement (joystick/teleport
  locomotion is deliberately DISABLED in ar sessions: moving the
  virtual origin against the real world would misalign every placed
  point). Two robustness measures for house-scale walks:
  1. Request the 'unbounded' reference space when available (WebXR's
     large-area space — the runtime relocalizes as you roam) and fall
     back to 'local-floor'; record which one captured the zone on the
     row (reference_space field) as accuracy evidence.
  2. The workflow is capture-per-room regardless: commit a zone, walk
     to the next room, START A NEW ZONE (fresh local capture, points
     close together in time/space → drift stays per-room, not
     per-house). The site summary aggregates rooms without needing
     them in one frame.
- A small HTMLMesh panel (works on device per Dustin) lists the site's
  committed zones + live totals during capture; the commit gesture
  stays both-grips so the panel is never required.
- Placement: trigger places a point at the controller tip; a small
  sphere + rubber-band line + floating METER LABEL (canvas sprite, not
  HTMLMesh) gives live distance feedback point-to-point. Grip = undo
  last. Ground points first (walk the perimeter), then a mode toggle
  (thumbstick click) for height points, then reference points for the
  calibration stick if wanted.
- WebXR hit-test API for snapping ground points to detected real
  surfaces WHERE AVAILABLE; controller-tip placement is the always-works
  fallback (hit-test support on Wolvic is device-dependent — feature-
  detect, never require).
- Commit (hold both grips 2 s): POST /api/zones/capture, then the zone
  is immediately re-fetchable and packable.
- Acceptance (desktop): the same placement flow drivable in the
  sim-space viewer with mouse clicks writing the same rows.

### arz-6 — Populate the zone (the stop line)
- After pack: render the cube lattice INSIDE the zone in the live AR/VR
  session (instanced boxes, 0.25 m, passthrough-visible) and in the
  desktop viewer.
- STOP LINE (headset, Dustin): walk a real space, place ~4-8 ground
  points around it + 1 height point, commit, run pack — see the cube
  count + the stacked cubes filling the captured space overlaid on the
  real room. Then: swap cube_size knob and re-pack live. THEN the house
  flow: walk to a second room, capture a second zone into the same
  site, and read the site summary's per-room + total counts.
- Later (out of scope this plan): populating with arbitrary math-shape /
  CAD objects instead of cubes (ties into MATH_SHAPES_PLAN and the
  tower-life-support AR placement that TOWER_LIFE_SUPPORT_PLAN.md:178
  explicitly parked — arz is the prerequisite it was waiting on).

## Risks / open questions for Dustin
1. Wolvic/Vive passthrough: does immersive-ar + passthrough actually
   engage on the current Wolvic build? (xr sessions so far were vr.)
   If not: capture still works in vr against the real floor plane, just
   without seeing the room — acceptable for v1?
2. Drift over a room-sized walk: is the 1 m reference-stick calibration
   enough, or do we want per-wall reference lengths?
3. Should committed zones become SimSpaceDefinition-linked so packed
   cubes can join real simulations (mass/material via msci) immediately,
   or is visual placement enough for v1?
4. Whole-house 3D view: per-room capture + site totals need no global
   frame, but if you want ALL rooms rendered together later, we'd add
   zone-to-zone registration (shared doorway reference markers between
   consecutive zones). Worth planning now, or after v1?
5. Cubes are placeholders for future real objects — when those arrive,
   packing generalizes from a cube lattice to per-object footprints
   (math-shapes / CAD bounding volumes). The packing report's lattice
   format should stay object-shape-agnostic from day one (arz-3 keeps
   the placement lattice separate from the cube geometry for this).
