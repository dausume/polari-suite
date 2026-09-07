# Offline builds: the template directory, the build cache, and how an offline install works

**Status 2026-09-06: SPECIFICATION (rungs off-2..off-5 in
`AI-Notes/plans/OFFLINE_INSTALL_PLAN.md` build it).** This is the
reference the pol-hub docs page ("Dependencies and offline media") is
generated from. The rulings it encodes: the offline deb is a different
package that never falls back to the network; the template is one
standard directory with a section per install need; the build cache is
inspectable on disk (gitignored) and inside Polari.

## 1. Two flavors, one version
| | online (`polari-complete`) | offline (`polari-complete-offline`) |
|---|---|---|
| where the parts come from | apt.isle / registry.isle / GitHub / PyPI at install time | the medium (or `/var/cache/isle-offline` after chunk aggregation), nothing else |
| deb control | `X-Polari-Install-Mode: online` | `X-Polari-Install-Mode: offline`, `Provides/Conflicts/Replaces: polari-complete` |
| what postinst writes | `/etc/polari/install-mode` = `online` | `/etc/polari/install-mode` = `offline`, `/etc/polari/offline-source` = pool path |
| a missing part | fetched | **refused, naming the section** — never fetched |
| version | Polari `YYYY.MM.DD[.n]`, components from their `VERSION` files | identical; the manifest carries `"flavor": "offline"` |
Both cannot coexist on one machine (dpkg conflict); changing mode =
installing the other flavor's deb. Reachability is never consulted.

## 2. The template directory (what `pol build offline <ver>` produces)
```
offline-build/                              gitignored build cache at the suite root (§4)
└── <polari-version>/                       e.g. 2026.09.06 — this whole tree is "the pool"
    ├── ISLE_OFFLINE_BUNDLE                 marker: version, flavor, sections present
    ├── manifest.json                       the ReleaseManifest + "sections": {name: {present, files, bytes, sha256}}
    ├── tree.json                           the Polari tree for this release (components → pieces → deps)
    ├── SHA256SUMS                          every file below, verified before anything is read
    ├── README.md                           human page: what installs, chunk list, the no-internet promise
    ├── debs/                               §1 isle debs: polari-complete-offline_<ver>_amd64.deb, member debs, launchers
    ├── apt/                                §2 distro closure as a flat `file:` repo: Packages(.gz), Release, *.deb, ubuntu-<rel>.txt
    ├── images/                             §3 docker images: <name>_<tag>.tar (docker save) + images.json (name, tag, digest, bytes)
    ├── router/                             §4 openwrt-<ver>.qcow2, router-image.manifest, packages/ (the opkg set)
    ├── modules/                            §5 polari-app-<m>-offline_*.deb (wheels ride INSIDE each deb)
    ├── engines/                            §6 engine debs not in apt/ + engine image tarballs + engines.json
    ├── hardware/                           §7 <app>/image.qcow2, domain.xml.j2, manifest.json (Hardware Apps)
    └── scripts/                            §8 install-offline.sh, isle-bootstrap-offline.sh, verify-offline.sh
```
Rules:
- **Every section directory always exists.** An empty one holds a file
  `EMPTY` whose one line says why (`no hardware apps in this release`).
  Absence is therefore a build error, emptiness is a statement.
- **`manifest.json` is the only index the installer trusts**, and only
  after `SHA256SUMS` verifies. Directory listings are never used to
  decide what is installable.
- **Nothing on the medium is a secret.** The CA and every key are
  minted on the device. The archive signing key for `apt/` is the
  release key, public half included.
- **Chunking to media does not change the layout**: `offline_chunker.py`
  splits by section at file boundaries; each chunk carries the marker,
  the manifest and its own `CHUNK` file; `install-offline.sh` aggregates
  into `/var/cache/isle-offline/<ver>/` and only then runs.
- **Names are derived, never typed**: image tarballs from `images.json`,
  debs from the manifest's `debs`/`modules` maps, the router file from
  `router-image.manifest`.

### 2.1 What each section answers
| Section | The install need it covers | Filled from |
|---|---|---|
| debs | the isle itself (CLI, shell, store, meta) | `build-polari-complete-deb.sh` (offline flavor) |
| apt | the deb Depends closure + docker + the core/hardware tier (qemu-kvm, libvirt, sshpass…) | `build-offline-bundle.sh --download` (pristine target container resolves the closure) |
| images | `prf-backend`, `prf-frontend`, `prf-proxy`, `isle-vlan-agent`, `isle-remote-agent`, `isle-expose-*`, `registry:2`, the sample app (prebuilt here instead of pip-at-create) | `docker save` of the release-tagged images |
| router | the OpenWrt VM + the packages `70-download-packages.sh` would otherwise fetch | the pinned qcow2 + an opkg download run on the build box |
| modules | the module app debs with their wheels | `app_deb_builder.py <m> --offline`, wheels cut from the release image's venv |
| engines | system engines a module manifest names (SPICE, ngspice, …) | the module manifests' `requires.engines` |
| hardware | VM-based apps (QEMU/KVM) | tree-1 |
| scripts | the offline installers + verifier | this repo |

## 3. How an offline install runs
1. `verify-offline.sh` (or the first lines of the installer): marker
   present, `SHA256SUMS` clean, manifest parses, every section present.
2. `apt/` is added as `deb [trusted=yes] file:<pool>/apt ./` — the
   ONLY apt source while the mode file says offline; docker + the
   closure install from it.
3. `docker load` for every entry of `images.json`; `registry.isle` is
   seeded from the loaded images, so `isle-polari-deploy --pull` pulls
   from the local registry exactly as online (the only difference is
   how the registry got filled).
4. The router VM is created from `router/`; its package step reads
   `router/packages/` instead of downloads.openwrt.org.
5. The offline deb installs; postinst writes the mode file + source path.
6. `isle core-install` (or `isle onboard` for a member) runs. Inside
   the CLI every fetch goes through one helper, `isle_source <section>
   <name>`, which returns a local path in offline mode or the URL in
   online mode and **refuses** when the section lacks the item:
   `offline: <name> not on the medium (section <n>) — add it to the
   bundle or install the online package`.
7. Polari boots with `POLARI_INSTALL_MODE=offline`: `module_fetcher`
   refuses git sources, pip runs `--no-index --find-links`, `pol modules
   get` refuses, the on-demand deb generator serves `modules/` only,
   the store's install door reads `modules/` and `engines/` for
   admission (`isle app admit <m>` / `isle store install <m>`).
8. Proof (filed in TESTING_OWED): `nmcli networking off` + an nftables
   egress counter + a pcap; counter reads 0 at the end; an install of
   something NOT on the medium refuses with the section name and the
   counter still reads 0.

## 4. The build cache (his ruling: "a build folder/cache we can inspect
that we git ignore but can look at in Polari itself")
- **On disk:** `offline-build/` at the suite root, `.gitignore`d
  (entry added 2026-09-06). One subtree per Polari version, exactly the
  layout of §2 — the deb is wrapped FROM this tree, so what the deb
  carries and what you can inspect are the same bytes. `pol build
  offline --clean <ver>` removes a version; nothing else deletes.
- **In Polari:** the framework mounts the cache read-only
  (`/srv/polari/offline-build`, via the swarm/compose files) and the
  `release` module (ver-2) reads it: rows `OfflineBuild` (version,
  flavor, builtAt, builtOn, bytes, chunkCount, verified) and
  `OfflineBuildSection` (build, section, present, fileCount, bytes,
  sha256, emptyReason) refreshed by `POST /api/release/offline-scan`
  (also run at boot). The page `/display/offline-builds` is configured
  tables only (builds → sections → files, `embeddedTable`; per the
  no-raw-JSON rule), with the section table doubling as the
  "what is missing" view (`present = no` rows carry `emptyReason`).
  The same rows feed the downloads page's offline card and the
  pol-hub docs page.
- **What it is not:** not a store of secrets, not a deploy target, not
  synced anywhere. It is the inspectable intermediate between the
  release build and the deb.

## 5. Where the pieces live (as built / to build)
| Piece | Path | State |
|---|---|---|
| builder (apt closure, marker, chunks) | `Isle-Mesh/polari-isle/build-offline-bundle.sh`, `appstore/offline_chunker.py` | exists (off-1) |
| builder sections images/router/modules/engines/hardware | `pol build offline` (polari-cli) wrapping the above | off-2 |
| module offline debs | `modules/appstore/app_deb_builder.py --offline` | exists (dl-4); wheels-from-release-image = tree-2 |
| mode file + `isle_source` + refusals | Isle-Mesh CLI lib (isle-core's Claude) + framework `POLARI_INSTALL_MODE` | off-3 |
| installers | `scripts/install-offline.sh`, `isle-bootstrap-offline.sh` | off-4 |
| build cache rows + page | framework `release` module, `/display/offline-builds` | off-5 (with ver-2) |
| docs page | `pol-hub/docs/offline.html` generated from this guide + the manifest | off-5 / tree-4 |
