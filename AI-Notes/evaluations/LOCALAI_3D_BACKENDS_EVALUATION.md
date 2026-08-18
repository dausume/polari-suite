# LocalAI backends — evaluation (2026-08-15)

**⛔ STANDING RULE (Dustin, 2026-08-15): NOTHING with a
non-commercial clause, ever — the project's purpose is to empower
small businesses, so commercial use is not optional. NC weights
block a backend even when its code is MIT.**

**FORK ROSTER (Dustin 2026-08-15: fork "the ones that meet our
criteria in terms of licensing and otherwise") — pins under
github.com/dausume/ (the rns relicensing lesson: upstream can
relicense; a fork cannot be retroactively changed):**

Kept (criteria-passing):
- **free-splatter.cpp** — "the most important one for us"
- depth-anything.cpp, trellis2cpp (the first two taken)
- parakeet.cpp, moss-transcribe.cpp, moss-tts.cpp, voxtral-tts.c
  (speech in/out — Apache/CC-BY-4.0 family)
- LocalVQE, ced.cpp, voice-detect.cpp (meeting-audio companions)
- rf-detr.cpp, animate-any-mesh.cpp (vision/mesh — weights
  re-check at adoption for animate-any-mesh)
- privacy-filter.cpp, vllm.cpp (isle-sovereign text)

Never forked / to delete (criteria-failing):
- ⛔ locate-anything.cpp — NVIDIA weights NON-COMMERCIAL (never
  forked)
- 🗑 magpie-tts.cpp — NVIDIA Open Model License (gated, custom);
  Apache TTS alternatives exist. FORKED IN ERROR before the
  criteria clarification — delete dausume/magpie-tts.cpp
- 🗑 vibevoice.cpp — MIT text but Microsoft's card says "research
  purpose"; ambiguity we don't build a business on. Delete
  dausume/vibevoice.cpp
- 🗑 face-detect.cpp — no fit + privacy posture. Delete
  dausume/face-detect.cpp
- (deletes need `gh auth refresh -s delete_repo` or the GitHub UI
  — the CLI token lacks the scope; Dustin's step)

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

## 3. free-splatter.cpp — ✅ GREEN, ADOPTED (Dustin: the most
##    important one for us)

- **Resolved 2026-08-15** (first look wrongly concluded
  not-public — the code is at **github.com/localai-org/
  free-splatter.cpp**; the earlier 404 was the wrong org, and the
  GGUF weights live on HF at LocalAI-io/free-splatter.cpp).
- **Code**: Apache-2.0 ✔. **Weights**: Apache-2.0 ✔ (derivative of
  TencentARC/FreeSplatter, itself Apache-2.0). The upstream NC
  worry (Hunyuan3D-1, RMBG-2.0) DOES NOT APPLY — the port carries
  neither; only FreeSplatter + bundled ggml.
- **What it does**: POSE-FREE reconstruction — N plain photos
  (2 scene views, or 3–4 OBJECT views at 512×512) → per-pixel 3D
  Gaussians (position, SH color, opacity, scale, rotation),
  standard splat-viewer compatible. No camera poses, no Python.
- **Hardware**: CPU-feasible — ~14 s/forward-pass on 12 threads;
  ~0.22 s with Vulkan/CUDA. Runs on our boxes.
- **Why it is the most important**: the scan arc died on small
  low-texture OBJECTS — and object-mode FreeSplatter takes 3–4
  uncalibrated photos of exactly that and answers with a dense
  gaussian representation, no feature matching, no pose estimation,
  no orbit rig. It is the shortest path from "phone photos of a
  part" to "viewable 3D"; depth-anything.cpp complements it for
  metric SCENES/depth (and where meshes are needed, gaussians →
  surfacing is the follow-on step to design at revival time).
- **Fork (pin)**: https://github.com/dausume/free-splatter.cpp

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

## 4b. LocalAI ITSELF (the server) — ✅ GREEN, and Polari is
##     already wired for it

Evaluated 2026-08-15 at Dustin's ask ("a locally hostable AI we
could enable via self-hosting in some places in polari").
Fork (pin): **https://github.com/dausume/LocalAI**.

- **What**: MIT-licensed, OpenAI/Anthropic/ElevenLabs-compatible
  API server over 60+ backends (llama.cpp, whisper.cpp, vLLM, the
  17 C++ ports above...). "No GPU required"; CUDA/ROCm/oneAPI/
  Metal/Vulkan optional. Modular: lightweight core + per-backend
  containers pulled on demand. Fully offline/air-gapped once
  models are cached — "your data never leaves your infrastructure".
- **The load-bearing discovery — ZERO new code for the chat half**:
  Polari's reasoning-provider layer
  (polariApiServer/reasoning_provider.py) already ships an
  `openai_compatible` provider whose registry entry has
  `needs_base_url: True` and "key optional for local servers", and
  whose docstring literally anticipates "a future local open-weight
  server". Wiring the in-app assistant to a LocalAI container is
  CONFIG, not code: deploy LocalAI, set the managed reasoning
  config to provider `openai_compatible` +
  `base_url=http://<localai>:8080/v1` + a model name. Tool-calling
  (the assistant's gated proposals) rides the same OpenAI wire
  format LocalAI serves.
- **Where it slots beyond chat**:
  1. **Assistant voice sovereignty** — today the panel uses browser
     Web Speech APIs (Chrome's STT is CLOUD-backed). LocalAI's
     /v1/audio/transcriptions (whisper/parakeet backends) +
     /v1/audio/speech (TTS) make voice local; the Realtime API
     covers speech-to-speech later.
  2. **Meetings** — transcription/diarization endpoints for
     MeetingRecord rows (the parakeet/moss backends run INSIDE
     LocalAI, so adopting the server covers those without separate
     services).
  3. **Privacy gate** — privacy-filter as a LocalAI backend before
     any text leaves the isle.
  4. **Embeddings** (/v1/embeddings) for future search over rows.
- **The Polari-native shape (when built — a small sep-4-pattern
  follow-up, NOT built yet)**: LocalAI as an isle app + engine —
  IsleCatalogEntry (kind mesh-app, `provides_engine: 'reasoning'`),
  a `_bind_reasoning` binder that writes the managed reasoning
  config (provider openai_compatible + base_url) the way
  _bind_odoo writes OdooInstanceConfig, an ENGINES registry entry
  so /engines/reasoning shows placement/reachability/usage, and a
  store tile. Deploying LocalAI anywhere on the isle would then
  auto-wire every instance's assistant.
- **Hardware honesty**: pol-core (HP ProDesk, no GPU) runs small
  quantized models (3–8B) at modest tokens/sec — usable for the
  assistant's short gated-proposal turns, not for long generation.
  Engine PLACEMENT is the existing answer: run the LocalAI engine
  on whichever isle member has the muscle; the binder pattern makes
  the assistant follow it.

## 4. The REST of the 17 — sweep against our active arcs

Green = code AND weights commercial-clean as checked 2026-08-15;
fork-at-adoption applies to all of them.

| Backend | Licenses | Fits | Verdict |
|---|---|---|---|
| **parakeet.cpp** | MIT code + **CC-BY-4.0** NVIDIA NeMo weights (commercial OK w/ attribution) | Meetings (mtg) transcription; the in-app AI assistant's VOICE INPUT (ai-assistant-panel is live app-wide) | ✅ useful, green |
| **moss-transcribe.cpp** | localai-org port; OpenMOSS MOSS-Transcribe-Diarize (Apache-2.0 family — PIN exact weight license at adoption) | Meetings: who-spoke-what → MeetingRecord rows (diarization) | ✅ useful, verify-then-green |
| **LocalVQE** | Apache-2.0 | Meetings audio: real-time echo cancellation / noise suppression — directly upstream of the LiveKit mic path | ✅ useful, green |
| **vllm.cpp** | Apache-2.0 (weights per-model — pick Apache/MIT models) | LOCAL LLM serving for the in-app assistant — isle-sovereign, no external API | ✅ useful, green |
| **privacy-filter.cpp** | localai-org port; OpenAI privacy-filter model **Apache-2.0** | Gate before ANY text leaves the isle (assistant calls, PSC publishing, public-repo hygiene posture) | ✅ useful, green |
| **rf-detr.cpp** | Apache-2.0 (RF-DETR weights Apache-2.0, Roboflow) | Scan capture: crop-to-object BEFORE reconstruction (the static-background hijack fix, done properly); plant monitoring (aquaponics); AR zones | ✅ useful, green |
| **locate-anything.cpp** | MIT code, ⛔ **NVIDIA LocateAnything-3B weights = NON-COMMERCIAL** | (would have fit AR zones / NL object location) | ⛔ **BLOCKED — NC weights** |
| magpie-tts / moss-tts / vibevoice / voxtral-tts | unchecked in depth; NVIDIA magpie weights SUSPECT (NVIDIA TTS often NC) — check before any adoption | assistant voice OUTPUT | ⚠ check at adoption |
| face-detect.cpp | unchecked | no current fit; privacy posture argues against | — skip |
| ced.cpp / voice-detect.cpp | unchecked | marginal (sound classification / VAD) | — later if meetings wants VAD |

Priority order if adopted: LocalVQE + parakeet/moss-transcribe
(meetings arc is LIVE and owed its human audio pass anyway) →
privacy-filter (cheap, guards everything) → vllm.cpp (assistant
sovereignty) → rf-detr (scanning revival companion).

Sources: the mudler/depth-anything.cpp README + LICENSE, the
localai-org org listing, localai.io 3D-generation docs,
HF depth-anything model cards, TencentARC/FreeSplatter README,
mudler/parakeet.cpp README (CC-BY-4.0 weights note),
nvidia/LocateAnything-3B HF LICENSE (non-commercial),
OpenMOSS/MOSS-TTS + MOSS-Transcribe HF cards, localai-org/
privacy-filter.cpp (OpenAI model, Apache-2.0).
