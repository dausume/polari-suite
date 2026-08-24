# Scan Revival on the LocalAI backbone — plan (rev-0..rev-7)

**Date:** 2026-08-16 · **Status: PLANNING ONLY (Dustin: "plan the
next arc for scan revival using the localAI backbone").**
Grounded in the shelf handoff, the backend evaluation, and the
dev-scan-1 code — nothing here is guessed; assumptions are MARKED.

**The goal, in Dustin's frame:** the critical missing piece of the
AI arc is "enabling feasibility for scanning rooms and real world
objects." The AI arc built the chassis (store citizens, linkage
vocabulary, engine binders, /engines pages, LocalAI as the
local-hosted family) but the `3d-reconstruction` linkage is
honestly `feasible`/seam-`unbuilt`. This arc builds that wire and
un-shelves the scanning machinery onto it.

## Ground truth (surveyed 2026-08-16)

- **The machinery is PROVEN and shelved, not lost**
  (SCAN_RECONSTRUCTION_HANDOFF.md, branches `dev-scan-1` ×4 repos,
  stacked on dev-dyn-1): scanning module (ScanProject /
  CaptureSession / ReconstructionJob / ReconstructionAsset,
  presigned PRIVATE buckets, immutable-after-finalize, scale gate
  with `unvalidated` default, link-sim → ImportedCadObject),
  recon worker image (prf-recon-engines: /capability /reconstruct
  /postprocess /export /merge), jobs with honest lifecycle,
  crop-to-object scaled-ICP aggregation + dispersal view, GLB/LOD
  export. selftest 51/51; E2E 15/15 in 16.5 s.
- **WHY it shelved**: sparse SfM (COLMAP sparse) starves on small
  low-texture objects — clouds too thin to read as shapes. The
  handoff's own revival order: dense reconstruction → better
  camera (phone) → real test objects → meshing.
- **The dense engines are adopted and license-clean**
  (LOCALAI_3D_BACKENDS_EVALUATION.md, fork pins under dausume/):
  - **free-splatter.cpp** (Apache-2.0 code+weights) — POSE-FREE:
    3–4 uncalibrated OBJECT photos (512×512) → dense per-pixel 3D
    gaussians. No feature matching, no orbit rig. CPU ~14 s/pass.
    Dustin: "the most important one for us." → OBJECTS.
  - **depth-anything.cpp** (MIT code; weights Apache **only for
    DA3-SMALL / DA3-LARGE-1.1 / DA3METRIC — ⛔ DA3-LARGE 1.0 is
    NC; licence-pin exact model names, never latest**) — dense
    METRIC depth + poses from single or multi-view; exports
    glb/COLMAP/PLY; 99 MB q8_0, ~360 MB RAM, CPU-first.
    → ROOMS/SCENES (and the dense prior openMVS can consume).
  - trellis2cpp: ⚠ conditional (GPU-bound; generates plausible
    geometry — asset generation, NOT measurement). Not in this arc.
- **The seam the engine swaps behind already exists**:
  `scanning.recon_remote` mirrors cad_remote — knob
  `RECON_ENGINES_URL` → topology resolve for `scanning.recon`.
  It PREDATES sep-4, so it lacks the EngineProviderBinding rung
  the msci/cad ladders gained — the revival adds it, and then
  `isle app deploy --engine` wires scanning exactly like msci/cad.
- **The ai-arc chassis is live** (AI_TOOL_LINKAGES_PLAN.md, arc
  complete): AiToolDefinition localai row claims 3d-reconstruction
  `feasible`; AI_LINKAGES names the kind with seam `unbuilt`;
  ENGINES registry + /engines/:kind pages; _BINDERS;
  islemesh catalog + store section; `pol` deploy path proven.
- **Inherited unlock**: mtg-7 (scanned environments as shared
  meeting scenes) was shelved WITH scanning — a room-scale result
  here un-blocks it (not built in this arc; stated).
- **Standing gotchas that bite here** (handoff §4): webcam dies
  through the KVM (direct-plug only); trimesh loads by file
  EXTENSION; `module_enabled()` not ImportError for absence; the
  desktop shell has no push channel (shoot-per-request only);
  shell holds no KC token — presigned URLs are the upload path.

## ⚠ The one honest unknown (rev-0 exists to kill it)

Both ports are standalone C++ CLIs AND LocalAI backends. What is
NOT verified: the exact API SHAPE LocalAI exposes for 3D backends
(there is no OpenAI-standard endpoint for reconstruction the way
/v1/audio/* covers voice). **MARKED ASSUMPTION: LocalAI can serve
both backends behind stable HTTP endpoints on our pinned fork; if
its 3D surface proves immature, the fallback shape is proven
ground — the CLIs ride IN the recon worker image (the COLMAP
slot), and LocalAI adoption for 3D waits.** Either way the
engines are the same pinned forks and the machinery is unchanged;
only the URL the worker calls differs. rev-0 settles this with a
running container before anything else builds on it.

## ✅ DECIDED (from the brief + standing rules)

| # | Decision |
|---|---|
| 1 | **LocalAI is the backbone**: the reconstruction engines are served from the isle's LocalAI deployment wherever its API surface supports them (rev-0 verdict); the recon worker keeps orchestration (fusion, meshing, export, MinIO I/O) and calls inference over HTTP |
| 2 | **Objects first, rooms second**: free-splatter object mode (3–4 photos, no rig) is the shortest path to the outcome that failed; DA3 rooms/scenes ride the same chassis one phase later |
| 3 | **Measurement over generation**: DA3/FreeSplatter measure the photos; trellis2cpp-style single-image generation is out of scope for scanning fidelity |
| 4 | **Licence pins, never latest**: exact model names in every config (DA3 Apache variants only — the 1.0-large NC trap is pre-identified); forks under dausume/ are the sources |
| 5 | **The ai-arc chassis is the wiring**: engine kind `recon` in ENGINES (+ /engines/recon page), `_bind_engine_row('recon')` in _BINDERS, the EngineProviderBinding rung added to recon_remote's ladder, a store tile with `provides_engine: recon`, and the localai tool row's 3d-reconstruction linkage flipping `proven` only when live-proven |
| 6 | **Honesty gates carry over unchanged**: scale stays `unvalidated` until measured; sim-link keeps refusing unvalidated scale; every /capability answer states which engines are actually present |

## Phases

- **rev-0 — the serving-shape survey (kills the unknown).**
  Stand up the pinned LocalAI (or the two CLIs directly) in a
  scratch container on pol-core; cache the pinned GGUFs
  (free-splatter HF, DA3 q8_0 Apache variant); run BOTH engines on
  a known photo set from the CLI and (if surfaced) LocalAI's API.
  Deliverable: a written verdict — LocalAI-served vs CLIs-in-worker
  — plus measured CPU timings on our hardware. No polari code.
- **rev-1 — un-shelve clean.** Cut `dev-scan-2` from `dev-ai-1`
  ×(framework, rf-node, app-shell, cli); merge `dev-scan-1`
  (common ancestor dev-dyn-1 is already in the ai stack); re-run
  the shelf's own proofs (scanning selftest 51/51, dyn proof,
  E2E 15/15 with the OLD sparse engine) so the merge is proven
  not-rotted BEFORE anything changes.
- **rev-2 — the engine swap.** Per rev-0's verdict: recon worker
  gains `engine: 'freesplatter' | 'da3' | 'colmap-sparse'` on
  /reconstruct (sparse kept as the honest baseline); /capability
  lists exactly which are reachable. Golden test: the synthetic
  E2E set + a REAL low-texture object set through DA3 multi-view —
  dense cloud vs the archived sparse baseline (point count,
  coverage; the comparison the evaluation prescribed).
- **rev-3 — chassis wiring (the ai-arc shapes, verbatim).**
  ENGINES['recon'] + /engines/recon page; EngineProviderBinding
  rung in recon_remote (between knob and topology resolve);
  `_BINDERS['recon'] = _bind_engine_row('recon')`; islemesh
  catalog entry (kind mesh-app, provides_engine recon) so
  `isle store install` deploys and auto-binds it; engine usage
  metering at the recon_remote seam (counts/bytes/latency only).
  AI_LINKAGES 3d-reconstruction seam → `live` naming the consumer.
- **rev-4 — THE milestone: a real object.** 3–4 phone photos of a
  small low-texture part (Dustin's photos, any transfer path) →
  FreeSplatter gaussians → stored ReconstructionAsset (new kind
  `gaussian_splat`) → surfacing to mesh (gaussians → Poisson via
  the existing trimesh worker half; openMVS added only if Poisson
  under-delivers) → GLB export → scale measurement → link-sim.
  The arc's definition of revived = this walk ends in a usable
  solid where the Brio walk did not. localai row's linkage flips
  `proven` here.
- **rev-5 — rooms/scenes.** DA3 multi-view over a room photo set →
  fused metric cloud (its COLMAP/PLY export) → mesh → room-scale
  asset class distinctions (asset kind `scene`), scale via DA3's
  METRIC output cross-checked against one tape measurement (the
  scale gate still demands the measurement — metric model output
  is a method, not a validation). Un-blocks mtg-7 (stated, not
  built).
- **rev-6 — capture UX (the phone path).** The phase-3 guided-
  capture web UX debt: a capture page (getUserMedia / file upload
  from the phone BROWSER over LAN https) → presigned PUT into a
  CaptureSession — no app build, no Mac, works on Dustin's iPhone
  today; the app-shell capture module stays the richer future
  path. Coverage hints per free-splatter's 3–4-view protocol.
- **rev-7 — store + docs closure.** The scan-capture app tile
  re-pointed at the revived flow; TESTING_OWED updated with
  Dustin's walks; handoff superseded-note; mtg-7 revival pointer
  left for the meetings arc.

## Boundaries

- Ours: framework (module merge, engine swap, chassis wiring,
  capture page backend), rf-node (worker image, compose), angular
  (capture page, splat/mesh viewing, engine page reuse), cli
  (compose recon role merge).
- Dustin's: rev-0 verdict sign-off, phone photos (rev-4/5/6), one
  tape measurement per scan, which box hosts the engines, the
  dev-scan-1-rides-dyn-1 merge acknowledgment (same stack
  convention as mtg/ret/sep/ai), repo deletes still pending from
  the fork sweep.
- isle-core's: nothing until rev-3's store tile needs
  `isle app deploy` verified for the engine image (request-doc
  note when we get there).

## Open questions for Dustin (none block rev-0/rev-1)

1. **Splats as citizens or just an intermediate?** Gaussian
   viewing in the browser needs a splat viewer the UI doesn't
   have; meshes ride the existing GLB path. Plan assumes splats
   are stored + surfaced to mesh immediately (decision 3 posture),
   viewer deferred — override if you want native splat viewing.
2. **Which box carries the engines?** CPU timings say pol-core is
   feasible (~14 s/pass FreeSplatter, DA3 sub-GB RAM); a beefier
   isle member just makes it snappier. Placement is a deploy-time
   choice; the binder follows it either way.
3. **Room capture protocol**: DA3 multi-view wants overlapping
   wide shots — is a phone sweep video (frames extracted) worth
   building in rev-6, or stills-only first? (Plan assumes stills
   first.)

## Grounding index

- SCAN_RECONSTRUCTION_HANDOFF.md (machinery table, revival order,
  gotchas §4, merge checklist §6, mtg-7 inheritance §7b)
- LOCALAI_3D_BACKENDS_EVALUATION.md (licenses, model pins, CPU
  timings, the recommended revival experiment)
- dev-scan-1: `modules/scanning/{scanning_basis,scanning_api,
  recon_jobs,recon_remote,selftest_scanning}.py`; rf-node
  `recon-engines/recon_service.py` + compose
- ai-arc chassis: `topology/engines_api.py` (ENGINES),
  `topology/engine_metering.py`, `modules/islemesh/
  islemesh_engines.py` (_BINDERS, _bind_engine_row),
  `modules/appstore/appstore_ai.py` (AI_LINKAGES),
  AI_TOOL_LINKAGES_PLAN.md (the arc this rides on)
- Fork pins: dausume/free-splatter.cpp, dausume/depth-anything.cpp,
  dausume/LocalAI
