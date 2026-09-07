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

---

## 2026-09-06 — the standard offline template, the offline flag, the no-fallback rule, the proof (his rulings; supersedes "Medium layout (draft)" above)

**His rulings:** "a standard format for how to pre-build the directories
that would act as the template for the deb for offline builds … sections
for different portions of install needs … the deb itself should have a
flag to indicate it is an offline install so it knows to search for
offline resources instead of running the standard online route … an
offline deb should NOT try to switch to online automatically … test an
offline install route of a base Polari install, and confirm no internet
access occurs during it … alternate scripts and/or code for handling
online vs offline builds."

### A. Every network touch of a base install today (the sections come from this list)
Verified 2026-09-06 in the isle scripts — each one is a SECTION the
template must carry, or the offline install cannot exist:
1. **apt** — the deb Depends closure (nodejs, jq, openssl, curl, iw,
   hostapd, socat, libnss3-tools, policykit-1, zenity) + docker
   (`docker.io`/`containerd`/`runc`) + the hardware/core tier
   (`qemu-kvm qemu-system-x86 qemu-utils libvirt-daemon-system
   libvirt-clients bridge-utils acl yad sshpass wget`, `create.sh:173,193`,
   `20-prereqs.sh:76-82`) — `build-offline-bundle.sh` already resolves
   this closure in a pristine target container (`repo/CLOSURE_URIS.txt`).
2. **docker images** — `prf-backend`, `prf-frontend` (+ `prf-proxy` for
   the compose route), the isle agent images (`isle-vlan-agent`,
   `isle-remote-agent`, the `isle-expose-*` gateway), `registry:2` for
   `registry.isle`, and the sample app — which today is BUILT at
   `isle create` time with `pip install` inside a Dockerfile
   (`create.sh:716`): offline it must be a prebuilt image on the medium.
3. **router** — the OpenWrt qcow2 (sha-pinned in `router-image.manifest`)
   AND the OpenWrt packages that `70-download-packages.sh` fetches from
   `downloads.openwrt.org` at setup — offline it reads a `router/packages/`
   directory instead.
4. **the isle debs** — polari-complete-offline (or the members), the
   launcher debs.
5. **modules** — the `polari-app-<m>-offline` debs with their `wheels/`
   (cut from the RELEASE IMAGE's venv, never the builder host).
6. **engines** — system engines as distro debs (in section 1's pool) and
   engine images (section 2), named by the module manifests.
7. **hardware apps** — VM images + domain templates (tree-1).
8. **trust and scripts** — `isle-bootstrap-offline.sh`, `install-offline.sh`,
   the CA is minted on the device (never on the medium), the archive
   signing key for the local pool.
Anything not in a section is, by definition, an online resource; an
offline install that reaches for it must FAIL with the section name.

### B. The template — one directory standard, built by `pol build offline`
```
offline/<polari-version>/                 (the pool; chunked to media by offline_chunker — unchanged)
  ISLE_OFFLINE_BUNDLE                     the marker (exists today) — now carries the version + sections present
  manifest.json                           the release manifest (ver-2) + flavor:"offline" + sections:{name:{present, bytes, sha}}
  tree.json                               the Polari tree for this release (tree-3)
  SHA256SUMS                              every file
  debs/                                   section 4: polari-complete-offline_<ver>_amd64.deb, members, launchers
  apt/                                    section 1: flat file: repo — Packages(.gz), Release, the closure .debs, ubuntu-<rel>/
  images/                                 section 2: <name>_<ver>.tar (docker save), images.json (name, tag, digest, bytes)
  router/                                 section 3: openwrt-<ver>.qcow2 + router-image.manifest + packages/ (the opkg set)
  modules/                                section 5: polari-app-<m>-offline_*.deb (+ their wheels are INSIDE the debs)
  engines/                                section 6: engine debs that are not in apt/ + engine image tarballs
  hardware/                               section 7: <app>/image.qcow2 + domain.xml.j2 + manifest (tree-1)
  scripts/                                section 8: install-offline.sh, isle-bootstrap-offline.sh, verify-offline.sh
  README.md                               the human page: what this medium installs, chunk list, the no-internet promise
```
Rules: every section directory is present even when empty (with an
`EMPTY` file naming why), so a missing section is visible, not
ambiguous; nothing on the medium is a secret; `manifest.json` is the
only index the installer trusts (after `SHA256SUMS` verifies).
`pol build offline <ver>` (the online/offline split below) fills each
section from the release build's outputs; `--download` keeps its
meaning (fetch the apt closure on a roomy box).

### C. The offline flag and the no-fallback rule
- **The deb is a different package**: `polari-complete-offline`
  (`Provides/Conflicts/Replaces: polari-complete`, the module-deb
  convention). Its control carries `X-Polari-Install-Mode: offline`.
- **postinst writes the mode ONCE:** `/etc/polari/install-mode` =
  `offline` plus `/etc/polari/offline-source` = the pool path (the
  mounted medium or `/var/cache/isle-offline` after chunk aggregation).
  The online deb writes `online`. The file is the single source of
  truth every later step reads: `isle core-install`, `isle onboard`,
  `isle-polari-deploy`, `isle apt-repo publish`, `isle app admit`,
  `isle store install`, the router setup, and Polari itself
  (`POLARI_INSTALL_MODE` passed into the container; `module_fetcher`
  refuses `git` sources; pip runs `--no-index --find-links`; the
  on-demand deb generator serves from `modules/` only; `pol modules
  get` refuses).
- **No automatic fallback, ever.** In offline mode a step that would
  need the network does not try it: it fails with `offline: <thing>
  not on the medium (section <n>) — add it to the bundle or install the
  online package`. Switching to online is an explicit operator act:
  `sudo isle install-mode online` (which requires the online deb to be
  installed — the debs conflict, so the switch is a reinstall, never a
  silent flip). The reverse (online → offline) is the same act with the
  offline deb.
- **Detection of the medium** is by the marker + manifest at
  `/etc/polari/offline-source`, never by "is the internet reachable" —
  reachability is not a mode.

### D. Online vs offline: separate scripts, shared core
- Builders: `build-polari-isle-deb.sh` / `build-polari-complete-deb.sh`
  (online) stay; `pol build offline <ver>` wraps `build-offline-bundle.sh`
  and adds sections 2–8. Both read the same `VERSION` files and write
  the same manifest shape (`flavor` differs).
- Installers: `isle-bootstrap.sh` (online, fetches from apt.isle) and
  `install-offline.sh` (from the medium: verify sums → mount the apt
  pool as a `file:` source → install docker + the closure → `docker load`
  every image → stage router + packages → install the offline deb →
  mode file → `isle core-install` or `isle onboard`, which now branch on
  the mode file). Shared logic lives in the isle CLI's lib; the two
  entry scripts differ only in where things come from.
- In the CLI, the branch is one helper: `isle_source <section> <name>`
  returns a local path in offline mode or the URL in online mode, and
  refuses (never falls back) when the section lacks the item.

### E. The proof — a base Polari install with zero internet
Target: a fresh Ubuntu 24.04 VM (or isle-core after `isle uninstall
--everything --verify`), medium = the `offline/<ver>/` pool on a USB
(or the chunk set). Steps:
1. Before touching the medium: `sudo nmcli networking off` (or unplug
   the uplink; the isle VLAN stays local) and start the evidence:
   `sudo tcpdump -ni any -w /tmp/offline-install.pcap 'not net 10.0.0.0/8 and not net 192.168.0.0/16 and not net 172.16.0.0/12 and not host 127.0.0.1'`
   plus an nftables egress counter+drop for anything not RFC1918:
   `sudo nft add table inet offproof; nft add chain inet offproof out { type filter hook output priority 0 \; }; nft add rule inet offproof out ip daddr != { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 127.0.0.0/8 } counter drop`.
2. Run `sudo bash <medium>/scripts/install-offline.sh` → core-install
   (or onboard) to completion; polari.isle answers; the store opens;
   admit one offline module deb (`isle app admit techtree`, tree-2).
3. Evidence: the nft counter reads 0 packets; the pcap is empty; every
   log line that names a URL is `.isle`, `127.0.0.1` or a `file:` path
   (`grep -hE 'https?://' /var/log/isle-mesh/*.log | grep -v '\.isle'`
   must be empty); `cat /etc/polari/install-mode` = `offline`;
   `isle uninstall --verify` after teardown = zero.
4. Negative proof: with the mode file `offline`, `isle store install
   whoami` (an image NOT on the medium) must refuse with the section
   name and the counter must still read 0 — the no-fallback rule
   observed, not assumed.
The same run with `networking on` and the nft drop rule in place must
behave identically — the medium, not the network, decides.

### F. Rungs (replace the old off-2/off-3 wording)
- **off-2 — the template + `pol build offline`**: sections B, the
  manifest/marker fields, `EMPTY` files, chunking unchanged; the sample
  app + agent images prebuilt into section 2; the router package set
  into section 3; wheels from the release image (tree-2).
- **off-3 — the mode file + the branch**: `polari-complete-offline`,
  `/etc/polari/install-mode`, `isle_source`, every network touch in §A
  branched, the named refusals, `isle install-mode` as the only switch;
  Polari's container reads `POLARI_INSTALL_MODE`.
- **off-4 — `install-offline.sh` + the proof** (§E) run on a clean
  target, the pcap + counters filed in TESTING_OWED; then the member
  path (`isle-bootstrap-offline.sh`).
- **off-5 — the downloads page + pol-hub docs page** ("Dependencies and
  offline media", tree-4) generated from the manifest's sections.

### G. Decisions (defaults in bold; his call)
- D5 the mode's home: **`/etc/polari/install-mode` (one file, both
  flavors write it)** vs a deb-only marker.
- D6 the medium marker: **keep `ISLE_OFFLINE_BUNDLE` (exists) and extend
  it** vs a new name.
- D7 switching modes: **only by installing the other flavor's deb** vs a
  runtime toggle.
- D8 proof tooling: **tcpdump + nft counter, both filed** vs one of them.
