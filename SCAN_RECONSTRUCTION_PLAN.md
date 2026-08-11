# 3D scanning + reconstruction — plan (DRAFT v2, investigated)

**Date:** 2026-08-10 · **Status: PLANNING ONLY — nothing built.**
v1 mapped Dustin's brief (via ChatGPT) onto Polari from memory. This v2
is grounded in a code investigation of the module system, the app
store/shell, and the storage/job/compose infrastructure, and is
reorganized around the standing goal Dustin set on 2026-08-10:
**modularize as much as possible — everything should be pullable /
installable only when needed.**

Companion: `LIVEKIT_COLLABORATION_PLAN.md`. The two converge at the
Polari scene/asset layer and must not depend on each other directly.

## 0. The modular decomposition — four deliverables, each optional

Nothing in this arc goes into the core backend, the base shell binary's
required path, or the default `up`. The split, in dependency order:

| # | deliverable | kind | installed when |
|---|---|---|---|
| 1 | `scanning` backend module | registry module (pure Python, light) | assigned to an instance via `pol topology assign` |
| 2 | `prf-recon-engines` worker | own image + own compose file | brought up only on a host that reconstructs (`pol compose recon up`) |
| 3 | shell camera capability | optional Gradle module `:capture-desktop` (+ android/ios later) | linked into a shell build only when an app declares it |
| 4 | `capture` app | `PolariAppDefinition` + `AppShellDefinition` seeds | downloaded from the app store like any app |

Each layer degrades honestly without the one below it: the capture app
without the camera capability shows "this shell has no camera
capability"; the `scanning` module without a reachable recon worker
returns the provider-registry refusal `{ok:false, suggestion:{knob,
action, evidence}}` (the `cad_remote` pattern); an instance without the
`scanning` module 503s/omits the routes entirely (module gating).

**Honest caveat about layer 1:** module *activation* is per-instance
and rows-derived, but module *code* is not currently modular — the
backend `Dockerfile` does `COPY . /app`, so all 37 module directories
ride in every image, and `pol modules drop` structurally cannot succeed
(it requires `modules/<m>/.git`, which in-tree modules don't have).
The `scanning` module will be "installable" in the same sense every
existing module is: present everywhere, ACTIVE only where assigned.
That is the established convention today. **Making module code itself
dynamic — fetch + admit + put-away at runtime — is now its own
PRIORITY arc, `DYNAMIC_MODULES_PLAN.md` (Dustin, 2026-08-10), which
runs BEFORE this one**; the `scanning` module should be built as the
first new module on that machinery (a dyn-1 manifest from day one, no
new inline blocks in `polariServer.py`). Independent of that arc, what
this plan keeps genuinely off uninvolved machines is the heavy part —
the engines image (#2), where virtually all the weight lives.

## 1. ⛔ LICENSE GATE — before any adapter (blocking)

The PlantMap3D lesson (`PLANTMAP3D_EVALUATION.md`): check **all three —
the API/docs claim, the LICENSE file, and the source headers**. Since
all our repos are public, this bounds what we can *ship*, not just run.

| engine | expected | the actual risk |
|---|---|---|
| Open3D | MIT | low |
| COLMAP | BSD | GPU/SIFT paths + bundled deps historically more restrictive than the top-level license |
| RTAB-Map | BSD | the transitive ROS/PCL/OpenCV surface |
| OpenScan | unverified | firmware/hardware/cloud pieces may differ from each other |

A permissive top-level license over a vendored GPL dep is not
redistributable. Because the engines live in their own *image* (not our
source tree), the practical question per engine is "can we publish a
Dockerfile that builds it + can we distribute the built image", which
is a weaker requirement than vendoring source — note this in the gate
verdict per engine.

## 2. Layer 1 — the `scanning` module (schemas + storage)

A pure-Python registry module: classes, MinIO presign endpoints, job
rows, provenance. No native deps, no COLMAP import, ever.

**Classes** (registered treeObjects — the standing gotcha: import in
`polariServer.py` + `defClassList` + `seed_pairs`, all three, or the
class silently gets no table): `ScanProject`, `CaptureSession`,
`ReconstructionJob`, `ReconstructionAsset`.

**The storage template already exists — copy `VideoAsset`**
(`modules/video/video_basis.py`): row = identity + parameters + status
+ bucket/key fields; bytes never transit the backend. Presigned upload
exactly like `video_api.py`'s `GET .../upload-url` (presign PUT, stamp
the key on the row). Storage tiers as settled: MinIO = captures/clouds/
meshes/textures; object DB = rows with *references*; KeyDB = previews/
LOD/thumbnails. sqlite is local by construction — a cross-instance scan
pipeline wants mariadb (and `mariadb+keydb` already implies the cache).

Known traps, all already encoded in code — reuse, don't re-learn:

- **SigV4 binds the Host header** — presign against the public
  endpoint via a separate client (`managedObjectStore._presign_client`;
  region pinned `us-east-1` so presigning never needs a live bucket
  lookup through the untrusted-CA public endpoint).
- **⚠ The staging proxy caps uploads at 100M**
  (`client_max_body_size` on the `s3.` server block in
  `nginx.staging.conf.j2`). Scan image sets and dense clouds will
  exceed this routinely — raising it (or exempting the s3 block) is a
  Phase-2 task, not a surprise for later.
- **Blob-backed classes need their own DELETE route.** Generic CRUDE
  delete orphans storage objects (no per-class delete hook); the video
  module's dedicated delete (`video_api.py`) is the pattern —
  `remove_prefix` then `deleteTreeNode`.
- Public-URL env knobs are currently inconsistent across modules
  (`MINIO_PUBLIC_URL` vs `POLARI_S3_PUBLIC_URL`/`MINIO_SERVER_URL`) —
  use the `managedObjectStore` one and note the drift (§8).

**Buckets:** `scan-captures` (raw, immutable), `scan-derived`
(clouds/meshes/textures), previews in KeyDB not MinIO. Raw captures
are never overwritten — re-runs write new derived objects (§4).

## 3. Layer 2 — `prf-recon-engines`, an own-image capability worker

COLMAP + Open3D must not enter the core backend image: boot time is the
fought-for constraint (core ~56s; prf-a was scaled 22→8 modules to get
807s→385s), and the backend image is Alpine — these are heavyweight
Debian-native builds.

**The pattern exists and has been walked twice** (msci-engines,
cad-engines). A recon worker is the same eight mechanical steps, no new
machinery:

1. `polari-rf-node/recon-engines/{Dockerfile,recon_service.py}` —
   Falcon service: `GET /capability` (honest availability: which
   engines compiled in, GPU present or not) + compute endpoints; a
   `resources` block self-declaring res-2 numbers (`imageMb`, `ramMb`,
   `minThreads`, `threadCeiling`) like `msci-engines/engines_service.py`.
2. `polari-rf-node/docker-compose.recon-engines.yml` — copy the
   cad-engines file: external `polari-link` network, host-published
   port (next free: **9700**), `mem_limit`, the documented
   `docker save | ssh | docker load` swarm path in the header.
3. The jinja twin under
   `polari-rf-node/jinja-templates/pol-services/compose/bundles/`.
4. A `recon)` case in `polari-cli/scripts/compose.sh`
   (`pol compose recon up|down|build|ps|logs`).
5. A `- kind: prf-recon-engines` entry in
   `pol-build/registry/services.yml` (⚠ cad-engines is missing from
   that registry today — don't copy the omission, and fix cad's while
   there, §8).
6. `'prf-recon-engines': 9700` in
   `topology/provider_registry.py` `PROVIDER_PORTS`.
7. Backend delegation inside the `scanning` module following
   `mathshapes/cad_remote.py`: `RECON_ENGINES_URL` env knob wins →
   topology resolution via `ModuleAssignment`/`ModuleDependencyEdge`
   (first *reachable* candidate) → honest refusal with suggestion.
8. A declared `ModuleResourceProfile` + a `topology_seed.py` machine
   pin (`ENGINE_CAPABILITY_MODULES`/`ENGINE_HOST_KINDS` already
   express "this only runs on worker/engine hosts").

Build knobs like `WITH_QE=1`/`WITH_FREECAD=1` are the precedent for
`WITH_RTABMAP=1` — RTAB-Map's ROS/PCL surface stays out of the default
recon image, and possibly becomes its own `prf-slam-engines` later if
its footprint or license posture demands it. That decision belongs to
phase 7, not now.

**GPU is genuinely greenfield.** Zero GPU/`nvidia`/`device` config
exists anywhere in compose, `ModuleResourceProfile` (RAM/disk/threads
only), or the admission advisor. First target is **CPU COLMAP** —
correct, just slow — with a GPU dimension added to res-2 + compose as
its own small step when a GPU host actually exists.

## 4. Reconstruction jobs — proposals, then a thread + a durable row

Investigated: there is no general job framework to ride. What exists:
thread + row-status (video conversion — the dominant pattern), an
in-memory 202 job dict (tile generator — lost on restart, don't copy),
`SimulationQueueEntry` (persisted queue, explicitly pump-driven, no
runner thread), and Dask `parallel_map` (120s bounded wait — wrong
shape for a 30-minute COLMAP run; right shape *only* if we later fan
out per-image feature extraction).

So a `ReconstructionJob` is:

- **proposed, not auto-run**: a new `_OP_LEVEL` entry in
  `polariApiServer/ai_actions.py` (level 4, like `storage_connect` —
  expensive network-service work) + the matching MCP propose tool.
  Execution stays human-confirmed, riding the existing provenance log.
- **executed** by the video-module shape: flip `status`, spawn a daemon
  thread in the `scanning` module that *calls the recon worker over
  HTTP* and streams/polls; write `status='ready'|'failed'` +
  `error_message` back. The heavy process runs in the worker container;
  the backend thread only supervises.
- **durable**: the job row carries engine + version, every parameter,
  input/output asset ids, log tail, and — new fields, nothing has them
  today — `wall_clock_s` and peak resource cost. Re-running with new
  settings creates a NEW asset + job row; never overwrites.
- optionally **queued** through `SimulationQueueEntry` + its pump when
  contention appears; not before.

## 5. Scale is a measurement, not a property

Unchanged from v1, and load-bearing: photogrammetry reconstructs up to
an arbitrary similarity transform. `scale` on `ReconstructionAsset` is
value + method + uncertainty (scale bar, calibrated rig, RGB-D metric
depth), and simulation linkage must **refuse** an asset with
unvalidated scale rather than default it to 1.0 — a guessed scale
silently corrupts every downstream mass/stress/volume. Same
capability-honest posture as ngspice/ffmpeg.

## 6. Layers 3+4 — capture rides the app shell (Dustin, 2026-08-10)

Decision: the capture client is a normal Polari app delivered through
the proven store loop, and the shell grows a **camera capability**.
Investigation sharpened what that touches:

**Why native capture, not `getUserMedia` — now with a second reason.**
Photogrammetry wants full-res stills, locked focus/exposure, and
per-shot intrinsics/EXIF; a webview stream gives video-res frames, no
EXIF, and AF/AE drift. Additionally: the desktop shell trusts
self-signed instances by proceeding through `onCertificateError`, and
Chromium treats a cert-error origin as non-secure — which blocks
`getUserMedia` in-page *regardless* of permission handlers. Native
capture sidesteps the whole class.

**The bridge today** (`polari-app-shell`): `BridgeRouter` dispatches
`{"v":1,"id","type","payload"}` messages; handlers are registered
ad-hoc per platform; **there is no capability registry, no permission
model, and no camera/media code anywhere** (grep-verified). The one
security precedent to imitate is `HostInstall`: validate inputs against
a strict shape → fixed argv/API call → never execute a page-supplied
string. The shell also has **no HTTP-to-MinIO client at all** — the
upload path is new code on every platform.

**Making the capability OPTIONAL (the modularization requirement).**
One shared shell binary serves every app launcher on a machine, so
"optional" must be designed, not assumed:

- **Build seam:** a new Gradle module `:capture-desktop` (guarded in
  `settings.gradle.kts` like `:android` already is), so shells can be
  built without it. ⚠ Two lists must learn about any new module: the
  root `srcDistTar` include-list (it currently ships ONLY `core/**` +
  `desktop/**` — android/ios sources are *not* store-delivered and are
  prebuilt-only uploads) and the settings include guard.
- **Declaration seam:** a `capabilities` field on `AppShellDefinition`
  (backend) flowing into the registration document — and
  `polari-shell.schema.json` + `appstore_payloads.registration_document`
  move **in lockstep** (the repo's own stated rule). At runtime the
  bridge refuses `shell.camera.*` unless the active app's registration
  declares the capability: declared-but-missing → "not built into this
  shell"; undeclared → refused by policy. That's the first real
  per-app capability gate in the shell, and it's deliberately minimal.
- **Bridge messages:** `shell.camera.capabilities`,
  `shell.camera.session.start/shoot/end` in `docs/BRIDGE_CONTRACT.md`
  (its phase-2 list currently has no media entry) + `BridgeRouter`
  tests next to `BridgeAndTrustTest`.

**Known contract drift to fix while in there** (§8): the documented
`window.PolariShell.request()` polyfill exists only on iOS; desktop
exposes raw `cefQuery`, Android raw `PolariShellNative.request()`
(synchronous), and the Angular `ShellBridgeService` speaks only the
desktop dialect. A multi-shot capture session needs the normalized
async bridge the contract already *claims* — build it as promised
rather than adding a fourth dialect.

**Per-platform reality:**

- **Desktop JCEF (Linux)** — provable NOW: a webcam is attached to
  pol-core (Dustin, 2026-08-10). End-to-end rig: capture → presigned
  MinIO PUT → `CaptureSession` row → recon worker. Webcam optics make
  mediocre scans; the pipeline proof doesn't care.
- **Android** — best capture hardware (CameraX, Camera2 intrinsics),
  but currently the WebView has no `WebChromeClient`, the manifest has
  only INTERNET/NETWORK_STATE, and no runtime-permission plumbing
  exists; and Android shells are prebuilt-only via
  `POST /api/appstore/artifacts`. Buildable, not self-testable —
  Dustin carries iOS.
- **iOS** — his actual phone; needs `NSCameraUsageDescription` in
  `ios/project.yml` + AVFoundation + async response plumbing (the
  current Swift bridge is a synchronous 2-case switch). Blocked on the
  Mac/Xcode path.
- **VR (Wolvic/Quest)** — not a capture target (passthrough camera
  restricted); consumer of results only.

**The capture app itself:** a `PolariAppDefinition` seed (pages/nav as
data, `modules_json: ['scanning']`) + an `AppShellDefinition` seed with
`scope:'app'` and the new `capabilities: ['camera']` — the
`wax-print-shop-shell` row is the exemplar. Guided-capture UX
(coverage rings, overlap hints) lives in the web layer.

## 7. Suggested order (v2)

1. **License gate** (§1). Blocking. Verdict per engine, including the
   image-distribution question.
2. **`scanning` module** — registry entry (with `requires`), the four
   classes (triple-registered), buckets, presigned upload/download,
   the dedicated DELETE route, selftests. Includes the proxy
   `client_max_body_size` fix.
3. **Shell camera capability (desktop) + capture app** — `:capture`
   Gradle module, `capabilities` declaration end-to-end
   (AppShellDefinition → registration doc → schema → bridge gate),
   `shell.camera.*` messages, MinIO upload from the shell, the
   normalized async bridge, capture-app seeds. Proven against the
   pol-core webcam.
4. **`prf-recon-engines` worker (CPU COLMAP + Open3D)** — the eight
   steps of §3; `ReconstructionJob` as proposal + thread + durable row
   (§4); scale designed here (§5). First real reconstruction from a
   webcam capture set.
5. **Open3D post-processing endpoints** on the same worker — clean /
   transform / merge / export, proven on the phase-4 output.
6. **Generic image-set import** (the surviving OpenScan leg) — an
   image directory + metadata into a `CaptureSession` without the
   shell, so datasets from any camera can enter.
7. **RTAB-Map on recorded datasets** (`WITH_RTABMAP=1` or a separate
   worker — decide by license + footprint then). → 8. live sensors →
   9. Three.js/WebXR export (LOD derivation — the LiveKit convergence
   point) → 10. simulation linkage (scale-refusal enforced) →
   11. Android/iOS capture as the shell paths unblock.

## 8. Pre-existing issues found during investigation (not this arc's
work, but recorded so they're not re-discovered)

- `modules/mathshapes/cad_minio.py` `presigned_get` signs against the
  **internal** client (`pol-file-store:9000`) — those URLs are unusable
  from a browser. Fix when touching presign code.
- `pol-build/registry/services.yml` has no entry for
  `prf-cad-engines` — `pol registry check` accountability gap.
- Registry drift: `pspp` and `magnetics` declare `requires:
  ["materialsScience"]` but the registry key is `materials_science`
  (and the actual package lives at the framework root, unregistered) —
  those dependency edges currently resolve to nothing in
  `dependency_order()`. The `video` module is on disk and gated but
  absent from both `polari-modules.json` and `FEATURE_MODULES`.
- Bridge contract drift (§6): iOS-only polyfill, desktop-only Angular
  service, documented-but-unimplemented `polari-shell` DOM events.
- Public-URL env knob inconsistency across MinIO presign call sites.

## 9. Open questions for Dustin

- ~~Which physical scanning hardware?~~ **Answered 2026-08-10:**
  cameras behind the app shell (§6); a webcam is attached to pol-core;
  OpenScan reduced to the generic import path (§7 phase 6).
- Is the first real target an OBJECT (a part, for casting/materials)
  or an ENVIRONMENT (the workshop, for XR collaboration)? Object-first
  favours COLMAP, environment-first RTAB-Map — the v2 order assumes
  object-first; say so if wrong.
- Which host gets `prf-recon-engines`? It wants disk + cores (GPU
  later); the topology seed should pin it before we find out by
  collision.
- Does a scanned asset become a `Part` in the existing
  composition/EBOM model, or a new thing referencing one?
  (Casting/composition already has an opinion about what a part is.)
