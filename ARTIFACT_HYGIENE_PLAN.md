# Artifact hygiene + router-image delivery — plan

**Date:** 2026-08-10 · **Status:** §3a/§3b/§5 BUILT + VERIFIED
(2026-08-10). §3c (publish) and §3d (history purge) remain, and both
now depend on the security finding below. Triggered by: binary
artifacts committed to git (esp. the 28 MB router qcow2, re-committed
~6× ≈ 170 MB+ of history already on origin — the "takes up space,
costs money" problem).

## 0a. ⚠ SECURITY FINDING (2026-08-10) — this is no longer only about size

The committed `openwrt-isle-router.qcow2` is **not a build artifact**.
It is a **booted, provisioned router's disk**. Mounting its rootfs and
diffing it against a clean upstream conversion shows it carries:

- `/etc/dropbear/dropbear_ed25519_host_key` + `dropbear_rsa_host_key`
  — the router's **private SSH host keys**
- `/etc/shadow` with a **real root password hash** (MD5-crypt `$1$`;
  a pristine image has an empty root password)
- `/etc/uhttpd.key` — the **private TLS key** for the router web UI
- `/etc/dropbear/authorized_keys` + `/root/.ssh/authorized_keys`
  (`isle-router-key`), `urandom.seed`

All of it published in a **public** repo, in ~6 copies of history. And
because every isle router is cloned from this template, they all
**share one host identity and one root password hash**.

Consequences that change the plan:

1. **The purge (§3d) is credential remediation, not housekeeping** —
   and it does not, by itself, remediate anything. Anything already
   cloned or cached still has the keys.
2. **Rotate the exposed material** — router host keys, the root
   password, the uhttpd TLS keypair, and the `isle-router-key` pair.
   Rotation is what actually fixes this; the purge only stops further
   distribution.
3. **Never publish this image** (§3c). A prebuilt copy for the mesh or
   a public release must be built by `build-router-image.sh` from
   upstream — pristine, no keys. The manifest's
   `ROUTER_IMAGE_PUBLISHED_SHA256` stays empty until such an image is
   built, and the fetch steps refuse to trust an unpinned artifact.

**Why untracking is safe:** the provisioning that produced that state
is done at runtime by `router-init` against the booted VM, not baked
into the image. Verified end to end (below) — a pristine image boots,
accepts the bootstrap, and takes its per-install key. The baked-in
credentials were never required.

## 0b. What was built and verified (2026-08-10)

On isle-core, `dev`, commit `d964153`. The live isle was never
touched: the boot test ran under plain userspace QEMU, never libvirt.

- **Untracked** the 28 MB qcow2, the 11 MB upstream base and 20 `.ipk`
  files; `.gitignore` now refuses artifact types by extension. Files
  stay on disk. `git ls-files` shows **no tracked binaries**.
- **`get-router-image.sh`** — the §2 chain, each step checksum-gated
  and independently skippable.
- **`build-router-image.sh`** — step 4, the build-from-upstream path.
- **`router-image.manifest`** — the tracked source of truth.
- **`40-image.sh`** delegates to the chain, keeping a self-contained
  build-from-upstream fallback for bundled/standalone runs.
- **`pack.sh` fixed** — it resolved its own root directory wrong, so
  the tracked bundle could not be regenerated at all.
- **Pre-push guard** (§5) in `polari-cli/shells/push-all-dev.sh`,
  covering the suite repos and the Isle-Mesh repo over SSH.

Tests that actually ran:

| test | result |
|---|---|
| upstream base vs openwrt.org published sha256 | **exact match** — provably re-downloadable |
| build from an empty images dir | image built; **raw content sha matches the manifest** (reproducible) |
| fresh `git clone` → `get-router-image.sh` | no images in the clone; chain builds one from upstream |
| cache hit / verified fetch / **checksum mismatch** | uses cache; accepts pinned artifact; **discards mismatch and falls through to build** |
| mesh configured but manifest pins no sha | **refuses to trust it** |
| pristine image boots + provisioning bootstrap | dropbear auth OK, key install OK, passwordless SSH OK |
| `download_image()` in chain mode / bundled mode | both produce an image |

Not yet done: §3c (publish a pristine prebuilt image to mesh/release),
§3d (history purge), and credential rotation.

## 0. Goal (Dustin)

Stop committing large build artifacts to git, AND give others a way
to **download the artifact and/or build it themselves from a more
commonly-available base** when ours isn't online — a fallback
chain, never a hard dependency on our hosting.

## 1. Findings (what to fix)

Tracked binaries on origin (Isle-Mesh):
- `openwrt-router/scripts/router-setup/images/openwrt-isle-router.qcow2`
  — **28 MB**, the BUILT router VM image; ~6+ copies in history.
- `.../images/openwrt-23.05.3-x86-64-generic-ext4-combined.img.gz`
  — **11 MB**, the UPSTREAM OpenWRT base (re-downloadable from
  downloads.openwrt.org).
- `.../packages/*.ipk` (tcpdump, socat side-loads) — small,
  re-downloadable from the OpenWRT package repo.

Suite side: already clean (app-shell `dist/` gitignored this
session; no tracked file >300 KB).

## 2. The delivery model — a FALLBACK CHAIN (the core of the plan)

`isle create` (and any fresh clone) obtains the router image by
trying, in order, until one works:

1. **Local cache** — already present at the expected path (dev box,
   or a prior fetch). Verify by checksum; use it.
2. **Mesh-served artifact** — pull our prebuilt qcow2 from the
   mesh: the docker **registry.isle** (as an OCI artifact) or the
   **apt-on-mesh / MinIO** store (a plain HTTPS asset at a `.isle`
   URL). Offline-complete on an existing isle.
3. **Our public release asset** — a GitHub Release attachment (NOT
   git-tracked; releases don't bloat the repo) or another public
   URL, checksum-verified. For someone with internet but no isle.
4. **BUILD IT from a common base** — download the upstream OpenWRT
   **base image** from downloads.openwrt.org (the commonly-available
   artifact) and run our `build-router-image.sh` to produce the
   qcow2 locally. The ultimate fallback: needs only upstream +
   our (small, git-tracked) build script.

Every step checksum-verifies against a tracked manifest
(`router-image.sha256` + version), so a fetched or built image is
provably the right one. The chain means: our hosting down → build
from upstream; upstream moved → use a cached/mesh/release copy.

## 3. Work items (next iteration)

### 3a. Untrack + ignore (stop the bleeding)
- `.gitignore`: `openwrt-router/**/images/`, `*.qcow2`, `*.img`,
  `*.img.gz`, `*.ipk` (keep a tracked `.gitkeep` + README in the
  images dir explaining how it's populated).
- `git rm --cached` the three artifacts (files stay on disk).
- Result: future commits never re-add the 28 MB blob.

### 3b. The fetch/build tool
- `openwrt-router/scripts/router-setup/get-router-image.sh` —
  implements the §2 chain (cache → mesh → release → build), each
  step behind a flag/env so it's testable; checksum-gated;
  idempotent. `isle create` calls it instead of assuming the qcow2
  is in-repo.
- `build-router-image.sh` — the step-4 builder: fetch the upstream
  base (pinned version + sha), apply our router config/packages,
  emit the qcow2. This is the "create it themselves" path.
- A tracked **manifest**: image version + sha256 + upstream base
  URL + sha, so all four sources agree on what "the image" is.

### 3c. Publish our prebuilt image (so step 2/3 exist)
- Push the qcow2 to the mesh (registry.isle OCI artifact, or MinIO
  at a `.isle` URL) — the offline path.
- Attach it to a GitHub Release (public, non-repo-bloating) — the
  internet path. Document both URLs in the manifest.

### 3d. History purge (reclaim what's on origin — DESTRUCTIVE)
- `git filter-repo` to drop the qcow2 (+ img.gz) from ALL history,
  then force-push. Rewrites shared history:
  - coordinate with isle-core's Claude (NOTES entry) — it owns the
    repo;
  - all clones must re-clone/reset after;
  - do it in a scheduled window, once 3a–3c make the images
    fetchable so nothing breaks post-purge.
- Reclaims the ~170 MB+ of duplicated blobs on GitHub.

## 4. Sequence + safety

1. 3a (untrack+ignore) + 3b/3c (make it fetchable) TOGETHER — never
   untrack before a fallback exists, or fresh clones + `isle create`
   break.
2. Verify `isle create` works on a box with an EMPTY images dir
   (proves the chain), and the build-from-upstream path works with
   our hosting firewalled off (proves the ultimate fallback).
3. THEN 3d (history purge) in a coordinated window.

## 5. Generalize (the hygiene rule)

- Standing rule: **no build artifacts in git** — debs, apks, jars
  (except gradle-wrapper), qcow2/img, tarballs. Each gets an ignore
  + a fetch-or-build path.
- A pre-push guard (extend `push-all-dev.sh`): refuse to push if a
  new tracked file over ~1 MB of an artifact type appears — catch
  it before it hits origin.
- Apply the same fetch-or-build-from-common-base pattern to any
  other heavy artifact we add (prf images already ride the mesh
  registry — good; keep that as the template).

## 6. Open questions for Dustin

- Mesh delivery: registry.isle OCI artifact vs MinIO HTTPS asset
  for the qcow2? (registry = one supply chain; MinIO = simpler
  plain download.)
- Public copy: GitHub Release attachment acceptable, or keep the
  public fallback to "build from upstream" only (no public binary)?
- History purge now (reclaim ~170 MB) or leave history and just
  stop future growth? (Purge = force-push coordination cost.)
