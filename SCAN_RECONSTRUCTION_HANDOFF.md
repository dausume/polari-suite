# Handoff — 3D scanning via photogrammetry: BUILT, how to TEST, what's NEXT

**Date:** 2026-08-11 · **Status: phases 1–6 + 9 + 10 BUILT + PROVEN in
containers; NOT merged, NOT pushed, superproject pointers NOT
committed — Dustin's review gate. Never deployed to the live stack.**

**Branches (all named `dev-scan-1`):**
- `polari-framework` — stacked on unreviewed `dev-dyn-1` (Dustin's
  explicit call): scanning module, recon delegation/jobs, appstore
  capabilities, topology/resources wiring, proofs.
- `polari-rf-node` — recon-engines image + compose, s3 proxy cap fix.
- `polari-app-shell` — :capture-desktop + the capability gate.
- `polari-cli` — `pol compose recon` role. *(uncommitted at writing —
  see §6)*
- suite root `dev` — license gate doc, plan status, this handoff,
  LiveKit v2 plan, polari-mcp propose tool.

Plan: `SCAN_RECONSTRUCTION_PLAN.md` · Gate: `SCAN_ENGINES_LICENSE_GATE.md`
(GPLv3 frame — [[project-license-gplv3]] rule: gates check
GPLv3-COMPATIBILITY).

## 1. What exists now (the whole surface)

| Piece | What | Proven |
|---|---|---|
| `scanning` module | 4 classes, presigned upload/download, finalize-from-listing, immutable-after-finalize, dedicated DELETEs, PRIVATE buckets | selftest 51/51; admit 1.0s / put-away 410 / re-admit 0.8s (`dyn_proofs/scanning_proof.py`) — the FIRST module born manifest-first on dyn-1 |
| `prf-recon-engines` image | CPU COLMAP 3.11.1 source-built with the gate flags + trimesh 4.5.3, 569MB; gate check IN the Dockerfile (build fails if SiftGPU code or GL linkage ever appears) | built; real reconstruction of a 20-view synthetic set → 1 model, sparse PLY |
| recon worker service | `/capability` (honest engines+resources), `/reconstruct` (COLMAP sparse → presigned PUT out), `/postprocess` (trimesh clean/transform/scale), `/export` (GLB/PLY/OBJ + LOD decimation) | smoke + E2E below |
| jobs (scan-4) | ReconstructionJob rows: proposed → explicit run → daemon thread supervises worker over HTTP; wall_clock_s, log tail, honest `failed`; re-runs = NEW rows | **E2E 15/15 PASS** (`dyn_proofs/scanning_e2e.sh`): 20-image job → `ready` in **16.5s** wall (in-network MinIO); GLB export, scale refusal→measurement→link, gated-module 503, live `admit?withDeps` all in one walk |
| proposals | `recon_run` = level-4 network-service in ai_actions (+ `polari_propose_recon_run` MCP tool) — AI cannot self-approve a run | code path shared with the human run route |
| import (scan-6) | server-local dir under `POLARI_SCAN_IMPORT_ROOT`; recognizes OpenScan3 layout (format facts from the gate doc — zero OpenScan code) | E2E imports the synthetic set this way |
| scale (scan-5) | value+method+uncertainty; `unvalidated` default; `POST .../scale` is the ONLY door out; export CARRIES the method (never launders) | E2E |
| sim link (scan-10) | `POST .../link-sim` → ImportedCadObject (mathshapes); REFUSES unvalidated scale (409); refuses honestly when mathshapes absent (503) | E2E incl. a live dyn-5 `admit?withDeps` of mathshapes |
| shell camera (scan-3) | optional `:capture-desktop` Gradle module (ServiceLoader discovery, settings guard, in srcDistTar); `shell.camera.*` bridge surface GATED on the registration's declared `capabilities`; fixed-argv ffmpeg v4l2 stills; direct presigned PUT under pinned-CA trust | gradle green: core 4 + capture 5 new tests; :desktop compiles. ⚠ live webcam BLOCKED (§4) |
| capabilities decl | `AppShellDefinition.capabilities_json` → registration doc → `polari-shell.schema.json` (lockstep) → bridge gate; catalog shows per-shell capabilities | appstore selftest 37/37 |
| seeds | `scan-capture` app + `scan-capture-shell` (first capability-declaring shell); recon InstanceDefinition + `scanning@prf-a` + `scanning.recon@recon` assignments + edge; resource profile | topology 52/52, apps 45/45 |
| proxy | s3 blocks `client_max_body_size 100M → 0` (staging+prod sources), rendered/validated/promoted; live `/root-ca.crt` block ported into the annotated source (promote would have clobbered it) | nginx -t OK |

## 2. How to TEST it (in this order)

```
cd polari-rf-node/polari-framework
python3 -m moduleService.selftest_lazy_imports                  # 23/23
# in-container (see CLAUDE.md): topology 52/52, apps 45/45,
#   refs 51/51, resources.selftest_profiles 31/31, appstore 37/37
PYTHONPATH=$PWD/modules:$PWD python3 -m scanning.selftest_scanning  # 51/51

# lifecycle (dyn machinery on the new module):
docker run --rm -u 1000:1000 -e HOME=/tmp -e PROOF_REPO=/app \
  -v $PWD:/app -v $PWD/moduleService/dyn_proofs/scanning_proof.py:/p.py:ro \
  -w /app --entrypoint python3 prf-backend:staging /p.py

# the WHOLE pipeline (MinIO + worker + backend, ~4 min):
#   first: generate the synthetic set (any dir):
docker run --rm -v <dir>:/data prf-recon-engines:staging \
  python3 /data/gen_views.py /data/synthscan     # script in session scratchpad; also inline-able
bash moduleService/dyn_proofs/scanning_e2e.sh <dir>

# shell:
cd ../../polari-app-shell && ./gradlew :core:test :capture-desktop:test
```

Then the live loop (after review): `pol compose recon up`, redeploy
prf-a with the merged branch (scanning@prf-a is seeded — placement
rows will activate it), restart the proxy (s3 cap), and capture from
the shell once the webcam works (§4).

## 3. Deferred phases — and why (honest)

- **Phase 7 (RTAB-Map):** deferred by DESIGN — object-first confirmed
  (Dustin 2026-08-11), and RTAB-Map is the environment-first engine.
  When wanted: gate verdict says flag-curated build only
  (`WITH_TORO=OFF` mandatory — vendored CC BY-NC-SA; GPLv3 Vertigo/
  ORBextractor fine for us; SURF/SuperPoint off). Its own image
  (`prf-slam-engines`) is the likely shape; the recon-engines
  Dockerfile is the template.
- **Phase 8 (live sensors):** no RGB-D/LiDAR hardware exists on any
  box. Blocked on hardware, not code.
- **Phase 11 (Android/iOS capture):** Android = buildable but
  prebuilt-only artifact path + no test device; iOS = Dustin's phone
  but blocked on the Mac/Xcode path. The bridge contract + capability
  gate are platform-neutral, so these are implementations of an
  existing seam, not new design.
- **Phase 3's guided-capture web UX** (coverage rings, overlap
  hints): frontend half — belongs with the Angular consumption of
  the dyn directory (the standing frontend debt, dyn handoff §4).
- **Open3D:** MKL wheel RULED OUT (gate). trimesh covered everything
  phase 5/9 needed; if a future step genuinely needs Open3D, build
  from source with OpenBLAS.

## 4. Gotchas found this run (do not re-learn)

1. **The webcam does NOT work through the KVM switch** — behind the
   KVM the Logitech Brio 100 enumerates but UVC probe control EPIPEs
   (`-32`) and init fails (`-5`); direct-plugged into pol-core it
   initializes cleanly (RESOLVED 2026-08-11, Dustin re-seated it).
   Two capture facts learned live and baked into the fixed argv:
   default v4l2 negotiation gives 640×480 (must request
   `-video_size 1920x1080`), and the first frames are black while
   auto-exposure converges (keep the ~11th frame). Real 1080p JPEG
   captured with the exact production argv. **ffmpeg is still not
   installed on the HOST** — the shell capability reports that
   honestly; the containers carry their own.
2. **`pol build render` EXTRACTS templates FROM the annotated
   working files** in `pol-services/` — editing the `.j2` gets
   silently reverted. Sources are the annotated `.conf` files
   (hash-space `# ` prefix on every line, even blank ones).
3. **The promoted `.generated/nginx.staging.conf` carried a live
   `/root-ca.crt` block that existed in NO source** (LAN-access work
   landed live-first). Ported to the source; any promote before that
   fix would have clobbered LAN onboarding.
4. **Debian's colmap package claims SiftGPU is MIT** — contradicts
   the research-only header in the upstream tree. We build from
   source with the gate flags instead of trusting the packager; the
   Dockerfile's gate check enforces it forever.
5. **`strings | grep -i siftgpu` is the WRONG gate check** — COLMAP
   compiles SiftGPU-*mentioning* help/error text into every clean
   build, and `grep -i libgl` matches libGLOG/libjxrGLue. The real
   check: SiftGPU's GL internals (ProgramGLSL/ShaderMan/PyramidGL/
   CreateContextGL) + exact `libGL\.so|libGLX|libOpenGL|libEGL`
   linkage patterns.
6. **COLMAP 3.11 requires OpenGL headers at CONFIGURE time even with
   everything GL turned off** (`find_package(OpenGL)` unconditional)
   — GLVND dev packages in the build stage only; nothing links.
7. `/api/modules` **omits downloaded-but-gated-out modules entirely**
   (builds from legacy polari*Module dirs + post-gate classes +
   not-downloaded registry entries). Pre-existing honesty gap for
   every module, not just scanning; the dyn-8 directory
   (`/api/refs/directory`) is the surface that answers correctly
   (`state: not-admitted` + bringUp).
8. **The desktop shell has NO push channel to the page** (no
   executeJavaScript anywhere) and the bridge is synchronous — a
   multi-shot capture UX will want the async/event half of the
   bridge contract eventually; shoot-per-request works today.
9. The shell holds NO Keycloak token (Strategy A) — presigned URLs
   are why capture upload works anyway. Anything else the shell
   uploads will hit the same wall until Strategy B tokens exist.
10. **`ImportError` is NOT an absence check** — module CODE ships in
   every image (dyn), so `from mathshapes... import` succeeds for a
   GATED-OUT module and would have written rows for a disabled one.
   `module_gating.module_enabled('<m>')` is the honest guard (fixed
   in link-sim; caught by the E2E, step 13).
11. **trimesh picks its loader from the file EXTENSION** — saving a
   downloaded artifact under a made-up name (`in.mesh`) makes export
   fail as "File type: mesh not supported". The worker now saves
   under the caller-declared `inputFormat`.

## 5. Known pre-existing defects (unchanged from the dyn handoff)

pspp defClassList gap (4 classes), cad_minio internal presign,
registry drift (materialsScience key), video module unregistered,
MOVE_SUBJECTS odoo, launcher-deb blank probe identity, root compose
parity DIFF (trap-chown line — predates this arc).

## 6. Merge checklist when review passes

```
polari-framework:  dev <- dev-dyn-1 <- dev-scan-1   (in that order)
polari-rf-node:    dev <- dev-scan-1
polari-app-shell:  dev <- dev-scan-1
polari-cli:        commit + merge the compose.sh recon case
then superproject pointers innermost-first; push-all-dev.sh --push = Dustin.
After deploy: pol compose recon up; proxy restart; re-run §2's live loop.
```

## 7. NEXT ARC — group meetings (web/video + VR) on LiveKit

Planned and ready: `LIVEKIT_COLLABORATION_PLAN.md` **v2** — the
mtg-0..8 ladder. mtg-0 (UDP/media LAN proof) is blocking and
deliberately small; the `collab` module is the second manifest-first
module on dyn-1; the VR client rides the existing android-vr shell;
scan-9's GLB/LOD assets are the shared scene at mtg-7. Three trimmed
questions for Dustin sit at the end of the v2 section.
