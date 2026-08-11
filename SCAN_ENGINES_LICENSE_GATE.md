# Scan/reconstruction engines — LICENSE GATE verdict

**Date:** 2026-08-11 · Gate required by `SCAN_RECONSTRUCTION_PLAN.md` §1
(blocking, before any adapter). Method per `PLANTMAP3D_EVALUATION.md`:
check all three — docs claim, LICENSE file, source headers/vendored
trees — per engine, plus the two practical questions (can we publish
the Dockerfile; can we distribute the built image).

**Evaluation frame (Dustin, 2026-08-11): the whole project is GPLv3.**
The gate therefore judges **GPLv3-compatibility**, not permissiveness:
GPL/AGPL/LGPL deps are non-issues; the blockers are unlicensed code
(all rights reserved), non-commercial / research-only clauses, and
patent-encumbered nonfree algorithms.

## Verdict table

| engine | top-level | gate | conditions |
|---|---|---|---|
| COLMAP | BSD-3 (COPYING + README + headers agree) | ✅ PASS | CPU/headless flags (below) keep the one landmine out |
| Open3D | MIT (wheel METADATA agrees) | ✅ PASS | ⚠ oneMKL wrinkle (below); NOTICE file |
| RTAB-Map | BSD-3 (all three agree — for the CORE only) | ✅ PASS (curated build) | `WITH_TORO=OFF` mandatory; nonfree/torch off |
| OpenScan | mixed per repo | ✅ PASS (import-only) | copy nothing from the unlicensed repos |

## COLMAP — PASS

- **Landmine: bundled SiftGPU** (`src/thirdparty/SiftGPU/SiftGPU.h`)
  is UNC "educational, research and non-profit purposes" only — no
  commercial grant. Compile-gated behind `GPU_ENABLED =
  OPENGL_ENABLED OR CUDA_ENABLED` (`cmake/FindDependencies.cmake`).
  ⚠ GUI drags OpenGL in, OpenGL drags SiftGPU in — the headless
  CPU build is what keeps the image clean.
- **Required flags:** `-DCUDA_ENABLED=OFF -DOPENGL_ENABLED=OFF
  -DGUI_ENABLED=OFF`. After build, verify SiftGPU symbols absent.
- Bundled LSD is **AGPL-3.0** and on by default → GPLv3-compatible,
  fine to keep (network-source obligation already met — repos public).
  CGAL (GPL-3), SuiteSparse GPL modules, VLFeat/PoissonRecon (BSD):
  all fine. Ship notice texts.
- Dockerfile publish: YES. Image distribution: YES (CPU flags).

## Open3D — PASS, one wrinkle to decide

- MIT top level; 47 vendored components, none research-only or
  non-commercial (verified against the actual `open3d-cpu` 0.19.0
  wheel binary). Use **`open3d-cpu`**, pinned — plain `open3d` on
  linux x86_64 is the pointless-for-us CUDA build.
- **⚠ The wrinkle: the official wheel statically links Intel oneMKL**
  (Intel Simplified Software License — proprietary but freely
  redistributable; the wheel's MIT LICENSE.txt understates this).
  ISSL is **not GPL-compatible**. If the recon worker's GPLv3 Python
  imports open3d, purists read that as a combined work containing a
  GPL-incompatible blob. Options, cheapest first:
  1. **Accept as-is** — the worker is its own image talking HTTP to
     the GPLv3 backend; treat the wheel as an aggregated dependency.
     Pragmatic, slightly arguable.
  2. **Build open3d from source with OpenBLAS** (`USE_BLAS` path, the
     ARM default) — fully GPLv3-clean, costs build time in the
     engines image. ← the clean answer if we ever care.
  **Decision (Dustin, 2026-08-11): NOT option 1 — do the OpenBLAS
  source build if Open3D is kept at all, or find a route without
  Open3D.** Candidate no-Open3D routes for phase 5: COLMAP's own
  `poisson_mesher` (BSD PoissonRecon) for meshing; `trimesh` (MIT) or
  `pymeshlab` (GPL-3 — compatible with our GPLv3) for clean/transform/
  merge/export. Decide when phase 5 starts; the official MKL wheel is
  ruled out.
- Ship a NOTICE file naming oneMKL + Apache-2.0 pieces
  (Embree/Filament/librealsense/TBB) + Qhull license text.
- Dockerfile publish: YES. Image distribution: YES with NOTICE.

## RTAB-Map — PASS only as a flag-curated build (phase 7, not now)

- Core BSD-3, but the **default** CMake build compiles vendored
  non-BSD code into `librtabmap_core`:
  - **TORO = CC BY-NC-SA** (`corelib/src/optimizer/toro3d/readme.txt`)
    — non-commercial AND GPL-incompatible. **`-DWITH_TORO=OFF` is
    mandatory.** GTSAM (BSD) is the optimizer anchor (CMake requires
    at least one).
  - Vertigo (GPLv3) + ORB-SLAM2 ORBextractor (GPLv3): **compatible
    with our GPLv3 project — may stay ON** (the upstream opt-out
    advice targets permissive users, not us).
  - **SURF stays off** (OpenCV `OPENCV_ENABLE_NONFREE`,
    patent-encumbered; never needed — defaults are GFTT/ORB/BRIEF and
    SIFT has been patent-free since 2020). **SuperPoint stays off**
    (`WITH_TORCH` — Magic Leap research-only weights).
  - g2o/CHOLMOD-GPL trap: non-issue for us. Qt LGPL: fine, but build
    headless. Camera SDKs off — recorded-data only.
- Dockerfile publish: YES (bake the OFF-flags into the `WITH_RTABMAP`
  path so nobody rebuilds the NC bits by accident). Image: YES with
  `-DWITH_TORO=OFF -DWITH_TORCH=OFF`, nonfree off.

## OpenScan — PASS for import-only

- GPL-3.0 repos (OpenScan3, OpenScan2, OpenScanCloud2): compatible —
  vendoring would even be permissible now, though the clean-room
  importer needs nothing from them.
- **No-license repos (all rights reserved): OpenScan3-Client,
  OpenScanCloud, OpenScan-Design, OpenScan-PCB, OpenScan3-Image,
  OpenScan-Doc** — copy nothing. Hardware historically CC-BY-NC.
- The output FORMAT is free to parse (facts, not expression); no repo
  claims rig output data. Format, for phase 6's generic import:
  project dir + `openscan_project.json` (created/description/uploaded/
  scans{}) + `scanNN/` each with `scan.json` (settings, camera_name,
  camera_settings, photos[], status, sizes) + photos (`.jpg`/`.dng`/
  raw; stacked JPEGs under `scanNN/stacked/`). Per-photo pose is
  DERIVED from path settings — treat as optional. OpenScan2 legacy =
  bare folder of JPEGs, no metadata.

## Gate outcome

**OPEN.** All four engines pass under the GPLv3 frame. Phase 2 (the
`scanning` module) and phase 3 (shell camera capability) never touch
engine code and were never blocked; phase 4 (CPU COLMAP worker) is
cleared with the flag set above. The only open licensing decision is
the Open3D oneMKL option (1) vs (2), and it does not block starting.
