# Offline install — CD/DVD/USB media flavor (dl-2)

**Date:** 2026-08-23 · **Status: PLANNING — decisions 1+2
RATIFIED same day (Dustin: "Ubuntu and multi-disk or
multi-usb chunking"): target = Ubuntu (amd64, 24.04 first,
22.04 next), and CHUNKING IS IN-SCOPE — the bundle must split
across multiple CDs/USBs with the installer prompting per medium
(copy-to-staging aggregation: each medium's payload lands in
/var/cache/isle-offline, verified against the manifest, install
runs once all chunks are present; partial sets refuse with which
chunk ids are missing). Decisions 3 (signing anchor) + 4 (app
images on the base medium) still open.** Companion to the
internet downloads page (dl-1, appstore/downloads_page.py, built
same day).

## The two flavors, named explicitly

- **internet-install** (exists today): the small piecewise debs
  (isle-mesh-cli → polari-shell-core → isle-app-store →
  polari-isle) from /downloads or apt.isle; the distro's own
  repositories supply docker/zenity/polkit/qemu during install;
  docker pulls images from registries. Piecewise BY DESIGN — small
  downloads, always-current deps.
- **offline-install** (this plan): ONE physical medium (USB / DVD;
  CD only via chunking, see sizing) that carries EVERYTHING,
  version-matched, so a machine with zero network installs
  completely. The normal install process DETECTS the medium and
  uses it; no separate installer to learn.

## Recommendation against the mega-deb

One giant deb vendoring docker/qemu/etc. inside itself is the
wrong shape: it fights the distro's own packages (conflicts,
upgrades, security patches), balloons every rebuild, and can't be
partially reused. The offline medium should instead be a
**version-matched piecewise bundle** — exactly Dustin's chunked
alternative: our four debs PLUS the real distro dependency debs
(the transitive closure) as a signed flat apt repo on the medium,
plus docker images as tarballs, plus the router-VM base artifacts.
`apt` installs from `file:` sources natively; `docker load` eats
tarballs natively. Nothing is reinvented.

## Medium layout (draft)

    ISLE_OFFLINE_BUNDLE          <- marker file (probe target)
    manifest.json                <- bundle version, target
                                    release/arch, per-file
                                    name/version/sha256, image
                                    digests, created-at
    sha256SUMS
    repo/                        <- flat signed apt repo:
      *.deb  Packages(.gz)  Release  InRelease
      isle-archive-keyring.gpg   (our debs + FULL dep closure)
    images/
      *.tar                      <- docker save output
    vm/
      router-base.qcow2 (+ ovmf/etc as inventoried by off-0)
    README.txt                   <- human: what this is, how to
                                    verify, the GUI + terminal
                                    routes

## Install-time behavior (core-install + onboard)

1. **Probe**: scan `/media/*/*`, `/run/media/*/*` (and a
   `--media PATH` flag) for `ISLE_OFFLINE_BUNDLE`.
2. **Verify**: sha256SUMS against manifest; version-match GUARD —
   the reinstall-dedup rule extended: a bundle installs
   ALL-OR-NOTHING at its recorded versions; mixed media/network
   versions REFUSE with the honest sentence, never blend.
3. **Use**: add `deb [signed-by=<media keyring>] file:<media>/repo ./`,
   `apt update` (file source only), install our debs + deps from
   the medium; `docker load images/*.tar`; router build takes
   `vm/router-base.qcow2` instead of downloading.
4. **Honesty**: every network step that was skipped is named in
   the output ("satisfied from medium: ..."); if the medium lacks
   something the target needs (wrong release/arch), the step
   REFUSES with what to fetch — no silent half-offline installs.

## Builder (off-1): `build-offline-bundle.sh`

Suite root, next to build-polari-isle-deb.sh (which it calls
first — the prune + vendor-sync rules ride along):

1. Our debs from `.generated/debs` (one version per package,
   already guaranteed).
2. **Dependency closure** for the pinned target: resolved in a
   PRISTINE container of the target release (`docker run
   ubuntu:24.04 apt-get install --print-uris ...` style), so the
   closure is what a fresh machine actually needs — not what this
   dev box happens to have. Downloaded into repo/, indexed +
   signed with the same conventions as apt-repo.sh.
3. **Docker images**: enumerated from the compose files the
   install actually deploys (agent, nginx:alpine, prf images…) —
   off-0 inventories the exact list — `docker save` each.
4. **VM artifacts**: whatever core-install's router step fetches
   (off-0 inventories).
5. manifest.json + sha256SUMS + marker + README.
6. Output: a directory bundle always; `--iso` additionally wraps
   it with genisoimage/xorriso for burnable media.

## Sizing (rough, to be measured in off-0)

shell-core 51M + cli/store/meta ~1M + docker.io/containerd
~100-150M + qemu-system + OVMF ~300-500M + images (nginx:alpine
~20M, prf images if included: hundreds of M) + router base qcow2
(hundreds of M) → realistically **1.5-3 GB: a DVD or USB stick.**
A single CD (700 MB) cannot carry this; CD support = multi-disc
chunking (manifest already carries per-file chunk ids in the
design; the installer would prompt per disc). RATIFIED (Dustin 2026-08-23): chunking is IN-SCOPE from the
start — multi-disc CD and multi-USB sets are first-class; the
manifest's per-file chunk ids drive an insert-medium-N prompt
loop with copy-to-staging aggregation.

## Flavor separation on the downloads page

/downloads grows a second section later: "Offline installer
(DVD/USB image)" with its own sha256 + the printed CA/key
fingerprint as the verification anchor. The internet debs stay
exactly as they are. The page already names the offline flavor as
not-yet-available (honest placeholder shipped with dl-1).

## Rungs

- **off-0** — instrumented inventory: run core-install on a clean
  target while recording EVERY network fetch (apt, docker pulls,
  VM artifacts) → the authoritative bundle content list + real
  sizing. (No design risk; pure measurement.)
- **off-1** — the builder script (closure in pristine container,
  images, vm, manifest, iso option). **✅ MACHINERY BUILT
  2026-08-24** (framework dev-dl-1 24b54eb chunker + suite
  dev-dl-1 43e1c0a builder; skeleton mode proven here — 101-deb
  closure resolved pristine, 2-chunk ISO set from the real debs,
  /downloads/offline renders the output). REMAINING: --download
  run on a roomy box; images/vm await off-0 + decision 4.
- **off-2** — media probe + verify + file-source install path in
  core-install; refusal semantics; "satisfied from medium" output.
- **off-3** — member path: isle-bootstrap/onboard accept the same
  medium.
- **off-4** — downloads-page offline artifact section + docs.
- **off-5** — FOLDED INTO off-1/off-2 (chunking ratified in-scope).

## Open decisions (Dustin)

1. Target pinning: which distro releases/arches does the offline
   bundle promise? (Recommend: ubuntu-24.04 amd64 first, one
   bundle per target.)
2. DVD/USB first with CD-chunking deferred — agreed?
3. Signing anchor for media built before any isle exists: a
   polari release key in the repo keyring + printed fingerprint
   (recommended), or sha256SUMS-only for v1?
4. Do prf app images ride the base bundle (bigger medium, richer
   offline demo) or a second "apps" medium?
