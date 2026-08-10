# 3D scanning + reconstruction — plan (DRAFT, for review)

**Date:** 2026-08-10 · **Status: PLANNING ONLY — nothing built.**
Source: Dustin's brief (via ChatGPT). This document maps that brief onto
Polari as it actually exists, and flags where the brief's assumptions
meet something already decided here.

Companion: `LIVEKIT_COLLABORATION_PLAN.md`. The two converge at the
Polari scene/asset layer and should not depend on each other directly.

## 0. What the brief gets right, and what this adds

The brief's core principle — Polari owns the data model and provenance;
OpenScan/COLMAP/RTAB-Map/Open3D stay behind adapters — is correct and is
the same shape as the existing module/engine boundaries. What it does not
know is how Polari specifically does this, which is most of the work:

- classes are the schema. A `treeObject` subclass registered in
  `defClassList` **becomes a table and a CRUDE API automatically**, so
  "define ScanProject/CaptureSession/ReconstructionAsset" is literally
  the Phase 1 deliverable, not a design exercise.
- ⚠ **Register new classes or seeds silently vanish** — the standing
  new-class gotcha. And a seed_pairs without a defClassList entry
  produces no table at all, with no error.
- storage tier is a decision per class, and for this domain it is the
  decision. See §2.
- provenance already exists as a first-class concern (the propose →
  execute → JSON provenance log). §6 of the brief should ride that, not
  invent a parallel one.

## 1. The engines, and the gate before any of them

⛔ **LICENSE GATE — do this before writing a single adapter.** The
PlantMap3D lesson (`PLANTMAP3D_EVALUATION.md`): three repos with no
license file meant all rights reserved, and it was only caught by
checking. Check **all three: the API/docs claim, the LICENSE file, and
the source headers** — they disagree more often than not.

Expected, but VERIFY rather than trust this table:

| engine | expected license | the actual risk |
|---|---|---|
| Open3D | MIT | low |
| COLMAP | BSD | its GPU/SIFT paths and some bundled deps have historically been more restrictive than the top-level license |
| RTAB-Map | BSD | pulls a large ROS/PCL/OpenCV surface; the transitive licenses are the question |
| OpenScan | **unverified** | firmware + hardware design + cloud pieces may be licensed differently from each other |

A permissive top-level license on a repo that vendors a GPL dependency
does not make the combination redistributable. Since all our repos are
public, this matters for what we can ship, not just what we can run.

## 2. Storage — the decision the brief does not make

Scans are large binary artifacts. This collides directly with the
hygiene rule just established (`ARTIFACT_HYGIENE_PLAN.md`): **no build
artifacts in git**, and by extension no scan artifacts in git.

The tiers already exist and each has a settled meaning:

- **MinIO (blob)** — RAW captures, dense clouds, meshes, textures.
  Object storage is already wired (`OBJECT_STORAGE_ENABLED`,
  `managedObjectStore`, buckets). Every heavy asset lives here.
- **sqlite / mariadb (object DB)** — the ScanProject/CaptureSession/
  ReconstructionAsset ROWS: identity, parameters, transforms, quality
  metadata, and a *reference* to the blob. Never the geometry itself.
- **KeyDB (cache)** — derived previews, LOD meshes, thumbnails.

⚠ sqlite is **local by construction**. A scan pipeline that matters
across instances wants mariadb, and `mariadb+keydb` already implies the
cache — declaring the cache twice is a validation error.

So: **a ReconstructionAsset row is a pointer plus provenance; the bytes
are in MinIO.** This is what makes §7 of the brief (raw / derived /
canonical) implementable rather than aspirational.

## 3. Where the heavy engines run

COLMAP and RTAB-Map are heavy native dependencies with GPU paths. They
must **not** go into the core `prf-backend` image:

- boot time is already the constraint the lazy-boot work fought
  (core ~56s; prf-a was scaled 22→8 modules to get 807s→385s);
- the backend runs on every instance, including ones that will never
  reconstruct anything.

Instead they are their own module(s) with their own image, placed by the
existing machinery: `pol topology assign`, the app-placement resolver,
and the network ledger. A reconstruction job is then work scheduled onto
an instance that actually has the hardware — which is what the
resource-awareness and distributed-compute (Dask) work is for.

⚠ **`POLARI_MODULES` DERIVES from ModuleAssignment rows** — never
`--env-add`.

## 4. Reconstruction jobs are proposals, not side effects

A reconstruction is expensive, long-running, and its parameters are the
scientific record. It fits the standing preference exactly: **every
capability is an explicit knob plus an evidence-bearing suggestion,
never auto-applied.**

So a ReconstructionJob should be a *proposed* operation carrying its
parameters, which a human executes — the same propose → execute →
provenance shape the MCP surface already uses. That gives §6 of the
brief (the processing graph) for free, because the provenance log is
already the audit trail.

Concretely, the job row keeps: engine + version, every parameter, input
asset ids, output asset ids, logs, wall-clock and resource cost, and the
verdict. Re-running with different settings creates a NEW asset with a
new job row — it never overwrites, which is what makes "rerun improved
algorithms later" real rather than a hope.

## 5. Scale is a measurement, not a property

The brief's §9 says geometry alone does not give material properties.
Sharpen that: **photogrammetry does not give scale either.** COLMAP
reconstructs up to an arbitrary similarity transform. Scale comes from a
known reference (a scale bar, a calibrated rig, RGB-D/LiDAR metric
depth), and it carries uncertainty.

That matters here more than in most projects because the materials and
simulation work consumes geometry as *measurements*. A mesh whose scale
was guessed will silently produce wrong masses, wrong stresses, wrong
everything downstream. So: `scale` on ReconstructionAsset is not a float,
it is a value + method + uncertainty, and an asset with unvalidated scale
must be **refused** by simulation linkage rather than defaulted to 1.0 —
the same capability-honest posture as ngspice/ffmpeg ("report missing
rather than crash").

## 6. Suggested order (revised from the brief)

The brief's Phase 1/2 ordering is right. The revision is to put the
license gate first and to make Open3D prove itself against a real
artifact before any adapter exists.

1. **License gate** (§1). Blocking.
2. **Schemas** — ScanProject, CaptureSession, ReconstructionJob,
   ReconstructionAsset as registered `treeObject` classes, with the
   MinIO-reference split of §2. Selftests.
3. **Open3D module** — load / clean / transform / merge / export, as its
   own module with its own image. Prove on a real point cloud.
4. **COLMAP adapter** — image set → reconstruction, as a proposed job
   with full parameter capture. This is where scale (§5) gets designed.
5. **OpenScan ingestion** — import an image directory + metadata. No
   hardware control initially.
6. **RTAB-Map on recorded datasets** — before any live sensor work.
7. Live sensors → 8. Three.js/WebXR export → 9. simulation linkage →
   10. XR headset capture.

Phases 7–10 are where this meets `LIVEKIT_COLLABORATION_PLAN.md`.

## 7. Open questions for Dustin

- Which physical scanning hardware actually exists or is intended? The
  whole OpenScan leg is speculative until there is a device.
- Is the first real target an OBJECT (a part, for casting/materials) or
  an ENVIRONMENT (the workshop, for XR collaboration)? They pull the
  order in different directions — object-first favours COLMAP, and
  environment-first favours RTAB-Map.
- Which host gets the reconstruction module? It wants GPU and disk, and
  the netledger should reserve it before we find out by collision.
- Does a scanned asset become a `Part` in the existing composition/EBOM
  model, or a new thing that references one? (Casting/composition
  already has an opinion about what a part is.)
