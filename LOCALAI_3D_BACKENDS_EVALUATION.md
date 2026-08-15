# LocalAI 3D backends — evaluation (2026-08-15)

Source: Richard Palethorpe's post (LocalAI team) on their 17
standalone C++/ggml inference backends. Dustin flagged the 3D ones
as possibly filling the SCANNING gap (arc shelved 2026-08-12:
sparse-only SfM clouds of small low-texture objects ≠ usable
models; named revival path = dense MVS (openMVS) → phone camera →
meshing). License gate = GPLv3-COMPATIBILITY (project is GPLv3;
GPL deps fine; blockers = unlicensed / non-commercial /
GPL-incompatible). Checked repo LICENSE + README claims + upstream
model cards — all three surfaces, per the standing rule.

## 1. depth-anything.cpp — ✅ GREEN, the scanning-gap fit

- **Repo**: github.com/mudler/depth-anything.cpp (mirror:
  localai-org/depth-anything.cpp), ~1,033 stars.
- **Code license**: MIT ✔ (GPLv3-compatible).
- **Weights** (Depth Anything 3, ByteDance — per HF model cards):
  - DA3-SMALL, DA3-LARGE-1.1, DA3METRIC-LARGE: **Apache-2.0** ✔
  - ⛔ **DA3-LARGE (the 1.0 large) is CC-BY-NC-4.0** — the same
    trap shape as DA2. USE THE -1.1 OR METRIC VARIANTS, pin the
    exact model name in any config (licence pins, never "latest").
- **What it does**: from-scratch C++17/ggml port — dense METRIC
  depth + per-pixel confidence + camera extrinsics/intrinsics +
  back-projected 3D point cloud from ONE image; multi-view mode
  (`--input a.jpg --input b.jpg`) for consistent depth + pose
  across frames; exports **glb / COLMAP / PLY** (dependency-free
  writers, parity-checked).
- **Hardware**: CPU-FIRST (tinyBLAS/Winograd/flash-attn), 99 MB
  q8_0 model, ~320–360 MB peak RAM, faster than PyTorch on CPU.
  Runs on our boxes; no GPU, no Python, one GGUF.
- **Why it fills the gap**: sparse SfM failed BECAUSE feature
  matching starves on low-texture objects. DA3 is learned monocular
  depth — no feature matching at all — so every frame yields a
  DENSE metric cloud + pose. Two revival shapes:
  (a) DA3 dense clouds fused directly → meshing (openMVS's own
  depth-estimation stage becomes unnecessary), or
  (b) DA3's COLMAP export FEEDS openMVS as the dense prior.
  Either way the phone-camera path in the scan memory becomes
  concrete. Could stand as an isle ENGINE tile later (the sep-4
  pattern: a 'reconstruction' engine kind with a data page).

## 2. trellis2cpp — ⚠ CONDITIONAL (license mostly green, hardware red)

- **Repo**: github.com/localai-org/trellis2cpp.
- **Code**: MIT ✔ (vendored third-party code also MIT). Optional
  print-wrap feature uses CGAL **GPL-3.0-or-later** — fine for us
  (we ARE GPLv3).
- **Weights**: TRELLIS.2-4B-GGUF marked MIT ✔; ⚠ the DINOv3
  encoder GGUF carries the **"DINOv3 License"** (Meta custom, not
  OSI) — needs a proper read before vendoring anything.
- **What**: single image → watertight textured 3D mesh (PBR).
- **Hardware**: ⛔ effectively GPU-bound — 512³ ≈ 110 s on a 16 GB
  RTX 50-series; 1024³ needs ~10 GB VRAM + 14 GB RAM spike; CPU
  mode "slow; mainly for debugging". Not practical on current
  suite hardware. Also note: it GENERATES plausible geometry from
  one image — that is asset generation, not measurement; for
  scanning fidelity DA3's measured depth is the honest tool.

## 3. free-splatter.cpp — ⚠ NOT PUBLIC YET

- Named in the post ("pose-free 3D reconstruction, a handful of
  photos → 3D Gaussians, no poses, no GPU") but no public repo in
  mudler/ or localai-org as of 2026-08-15.
- Upstream (TencentARC/FreeSplatter, ICCV 2025): Apache-2.0 with
  Tencent policy riders; ⚠ upstream deps Hunyuan3D-1 and BRIAAI
  RMBG-2.0 are NON-COMMERCIAL — whether the .cpp port avoids them
  is unknowable until it publishes. WATCH, don't plan on it.

## Verdict

**depth-anything.cpp is the find**: license-clean (MIT +
Apache-2.0 weights if the NC large-1.0 variant is avoided),
CPU-only, tiny, and aimed exactly at the failure mode that shelved
scanning. Recommended revival experiment (when scanning revives —
still Dustin's call): phone photos of the same small object →
`depth-anything-cli` multi-view → fused PLY → compare against the
scan arc's sparse clouds; then meshing via openMVS or direct
Poisson. The scan-arc machinery (module, worker, jobs, placements,
aggregation UI on dev-scan-1) plugs in unchanged — only the
reconstruction engine swaps.

Sources: the mudler/depth-anything.cpp README + LICENSE, the
localai-org org listing, localai.io 3D-generation docs,
HF depth-anything model cards, TencentARC/FreeSplatter README.
