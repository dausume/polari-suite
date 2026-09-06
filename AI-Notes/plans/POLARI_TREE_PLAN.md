# The Polari tree (tree arc): app kinds (Container App vs Hardware App), agent tiers, offline dependencies through the agent, and a build-generated version + dependency tree with its documentation

**Date:** 2026-09-06 · **Status: PLAN (tree-0). No code changed.** His
framing: apps and the dependencies they need when installed OFFLINE, and
how "the deb launch would interact with the agent to load the extra
dependencies into polari overall"; documentation pages on the static
polari-systems site distinguishing a QEMU/KVM-based app ("Hardware
App") from a standard docker-swarm containerized app; a hardware app
needs the heavier agent "or upgrade to it, despite not being the
isle-core"; and at build time "a versioning and dependencies of the
pieces of polari and all of their dependencies and their versions …
how polari branches into its pieces, and then how those branch into
more pieces, and then their dependencies … robust and intuitive
documentation … the versioning will dynamically update as we update
things." Ruling the same hour: tracking only — no mismatch checkers
while experimental.

Companions: POLARI_VERSIONING_PLAN (the VERSION files + release
manifest this tree is generated from), PRODUCTION_DEPLOY_PLAN (prd-3b
core-only server, prd-5 release build), CICD_PIPELINE_PLAN (ci-2 runs
the release build), POLARI_SYSTEMS_ORG_PLAN pub-5 (the documentation
section of `pol-hub/`), DOWNLOADS_PAGE_PLAN (dl-4/dl-7 manifests).

## 1. What exists (verified 2026-09-06)

- **Agent tiers, three today:** `isle-vlan-agent` (the core: nginx
  ingress + registry watcher, `agent.mode=core`), `isle-remote-agent`
  (a member: same ingress on its own macvlan lease, `agent.mode=remote`,
  brought up by `isle onboard --host` → `isle join`), and
  `isle-host-agent` (a systemd mDNS relay, not a container). Both
  container tiers can HOST containers — `isle app deploy` accepts
  either (`app-deploy.sh:61-63`). Only the core registers `.isle` names
  on the router's dnsmasq; members get split DNS. A device without an
  agent is reach-only (store installs refused, `onboard.sh:141-143`).
- **KVM today = the router VM on the core only.** `create.sh:59,168-185`
  probes `virsh`, offers `apt-get install qemu-kvm libvirt-daemon-system
  libvirt-clients`, and skips the router when absent; the VM lifecycle
  is `router.sh` (all `virsh`); the OpenWrt image is pinned by sha in
  `router-image.manifest`; USB/ethernet passthrough XML exists for the
  router only. **No QEMU/KVM app kind exists.** Polari's
  `REALIZATION_KINDS` carries `'kvm'` as DELIVERY METADATA
  (`MeshAppRealization.hardware_pin_device`: "the mover refuses to move
  a pinned realization") — a model, no runtime.
- **App kinds in the catalog:** `mesh-app` (compose today; `swarm`
  named in `ORCHESTRATORS` but no swarm implementation on the isle —
  the mac-4 converter is still owed), `polari-app` (launcher),
  `polari-instance`, `polari-module`, `isle-vpn`.
- **App deb ↔ agent: no link.** The dl-4 module debs carry ONLY a
  control file (no postinst), nothing in Isle-Mesh or the shell
  references `/var/lib/polari`, and the manifest says "admission is a
  manual step". The backend container mounts `backend-data:/data`, not
  `/var/lib/polari`.
- **Dependency accounting is DERIVED, not declared:**
  `module_requirements.py` scans a module's real imports → installed
  distributions → full requires-closure with MEASURED bytes; engines are
  curated per module with a probe (`ENGINE_MAP`: python vs system); the
  registry `requires` gives the Polari-module edges. Every generated deb
  manifest already lists libraries (name, version, bytes), engines
  (probe, present, note), `polariRequires`, `delivery` and, offline, the
  `wheels`. FINDING: the offline wheels are cut from the BUILDER HOST's
  venv (vpn-offline carried `cryptography 46.0.4` while the framework
  now pins 50.0.1) — they must come from the release image's environment.
- **The static site is `pol-hub/`** (plain HTML: `index.html`,
  `docs.html`, `assets/app.js`), no generator; pub-5 already plans the
  documentation section (four pillars, `doc_ref` cross-links,
  `llms.txt`, a build-time machine index). The downloads page is
  server-rendered by Polari, not part of pol-hub.
- **Tree renderers exist:** `topology-graph-layout.ts` (d3 pack layout:
  modules nested in consumers, host ▸ container ▸ modules, dashed
  transient copies) fed by `topology_module_graph.module_graph()`, and
  `tech-tree-view.component.ts` (d3 zoom, nodes with completion rings).

## 2. App kinds and agent tiers (the documentation's spine)

| Kind (catalog id) | What it is | Where it runs | Agent tier needed | Data | Moves? |
|---|---|---|---|---|---|
| **Container App** (`mesh-app`) | a compose/image app behind the isle agent; swarm orchestration once mac-4 lands | any hosting member or the core | member (`isle-remote-agent`) or core | its volumes on that device; the netledger allocates pools/ports | yes, unless pinned |
| **Hardware App** (`hardware-app`, NEW) | a QEMU/KVM virtual machine that owns physical hardware through passthrough (USB, PCI, a NIC, a serial adapter — the hardware-operations work Polari needs: radios, FPGA programmers, lab instruments) | the device the hardware is plugged into | **hardware tier** = a member or core WITH libvirt/KVM (NEW: `isle onboard --host --hardware` installs `qemu-kvm libvirt-daemon-system libvirt-clients`, adds the user to `libvirt`, and records `agent.tier=hardware`); a core already has it because of the router VM | a qcow2 + a domain XML rendered from the catalog entry; images pinned by sha like the router's | **never** — `hardware_pin_device` (the existing rule) |
| Polari app (`polari-app`) | a launcher door into a Polari page | any device with the shell | none (reach-only is enough) | none | n/a |
| Polari instance (`polari-instance`) | another backend+frontend behind a device's agent | hosting member or core | member or core | its own sqlite / volumes | yes |
| Polari module (`polari-module` / the dl-4 `polari-app-<m>` debs) | code + data admitted into a running Polari | the Polari instance | none itself; needs the instance | seeds + initialData | with the instance |
| Isle VPN (`isle-vpn`) | the Link / Bridge kinds (vpn arc) | the isle side | core (gateway kinds) or member | keys on the device | no |

The "heavier agent" he refers to is therefore not a different
container image but the **hardware tier**: the same remote agent plus
libvirt/KVM on the host, exactly what the core carries for its router.
Upgrading a member in place is `isle onboard --host --hardware`
(idempotent: installs what is missing, keeps the agent). The catalog
entry for a Hardware App declares `requires_tier: hardware` and the
passthrough devices it needs (vendor:product or PCI address); the store
refuses to install it on a device without the tier and says which
verb adds it; the coherence assessment (`islemesh_coherence`) flags a
Hardware App whose pinned device no longer reports the USB device.

## 3. Offline dependencies through the agent (the flow that does not exist yet)

Today a module deb stages and stops. The flow to build (tree-2):

1. **The deb installs the payload** (`/var/lib/polari/apps/<m>/` with
   `manifest.json`, `wheels/` in the offline flavor) — unchanged.
2. **postinst calls the agent when the CLI is present:** `isle app
   admit <m>` (new verb; absent CLI → the deb prints the manual step, as
   today). This keeps the deb dpkg-clean (no docker socket in a
   maintainer script) and puts the act on the isle side, where
   authority lives.
3. **`isle app admit`** reads the manifest, then:
   - **engines of kind `system`** (ngspice, ffmpeg, verilator …): apt
     from the isle's repo — online: the distro; offline: the offline
     media's apt pool (`build-offline-bundle.sh` gains the engine
     packages named by the manifests it carries) — the agent never
     invents a binary;
   - **engines of kind `image`** (NEW in `ENGINE_MAP`: the engines
     workers such as `prf-cnt-engines`, `prf-msci-engines`): `docker
     load` from the media or pull from `registry.isle`, then
     `isle app deploy` them as Container Apps declaring `--engine
     <kind>` (the existing IsleEngine binding);
   - **python libraries**: passed to Polari as part of admission (next
     step) — the agent does not pip into the container;
   - **the payload reaches the container** through a bind mount added to
     the isle's compose (`/var/lib/polari/apps:/var/lib/polari/apps:ro`)
     so the framework's `file`-kind fetch can copy it.
4. **Admission:** `POST /modules/<m>/fetch-admit {"sourceKind":"file",
   "sourceRef":"/var/lib/polari/apps/<m>","installDeps":true}` — the
   dyn-4 path; `installDeps` with an offline payload runs
   `pip install --no-index --find-links /var/lib/polari/apps/<m>/wheels
   -r <closure>` inside the container's venv, online it pips from the
   index; then un-stub + admit (dyn-2). The response names every
   library/engine it installed or found present — the manifest's
   accounting becomes the receipt, written as a `ModuleInstallRecord`
   row (module, Polari version, flavor, libraries installed, engines
   found/missing, seconds).
5. **Uninstall:** `isle app remove <m>` → put-away (dyn-3, tables kept),
   the payload removed by `apt remove`; libraries stay (shared venv —
   removal is a separate, later knob).
6. **Wheels are cut from the release image** (the `prf-backend` image's
   venv, the same one that will import them), never from the builder's
   host venv — fixes the finding above; the offline deb records the
   image version it was cut against.

For Hardware Apps the same verb handles the VM: `isle app admit
<hardware-app>` = `virsh define` from the rendered XML + `virsh start`
on the pinned device, refused without the hardware tier.

## 4. The Polari tree — generated at build, never hand-maintained

**What it is.** One graph per release, rooted at `Polari <version>`:

```
Polari 2026.09.06 (tag polari-v2026.09.06, superproject <sha>)
├─ Polari Research Framework
│  ├─ prf-backend 0.2.0  (image ghcr…:2026.09.06 @sha256:…, 951 MB)
│  │  ├─ python: falcon 4.2.0, cryptography 50.0.1, numpy 2.1.3, … (each: version, bytes, licence, from requirements.txt vs transitive)
│  │  ├─ system: ngspice, ffmpeg (apk), python 3.12-alpine base
│  │  └─ modules (registry): 46 → each module node ↓
│  ├─ prf-frontend 0.2.0 (image …, 92.6 MB) → npm: @angular/core 19.x, three, d3, … (version, bytes, licence)
│  └─ prf-proxy (image …)
├─ Isle-Mesh 0.3.0 → isle-mesh-cli deb 0.3.0; agents (vlan/remote/host images); router VM (OpenWrt 23.05.3 @sha); deps: nodejs, jq, openssl, hostapd, iw, socat, curl; libvirt/qemu-kvm (hardware tier)
├─ Polari App Shell 0.2.0 → polari-shell-core deb (JDK 17 runtime, JavaFX, JCEF); isle-app-store deb; launcher debs
├─ pol CLI 0.2.0 → nodejs
├─ Political Scorecard → psc-frontend, psc-backend (Spring 3.5.0, MariaDB, KeyDB)
└─ modules (46) — e.g. vpn 0.1.0+g363301e197
   ├─ requires: islemesh, composition          (registry edges)
   ├─ python: cryptography 50.0.1 (13.6 MB)     (measured closure)
   ├─ engines: cryptography (python, present)   (ENGINE_MAP)
   ├─ debs: polari-app-vpn / -offline (wheels: …)
   └─ data: initialData/*.json (bytes)
```

**Where each fact comes from (all derived):** the superproject pins +
`VERSION` files (ver-1); `requirements.txt` + `importlib.metadata` in
the RELEASE IMAGE (python dists, versions, sizes, licences);
`package.json` + `package-lock.json` (npm); the deb control files
(Depends); `ENGINE_MAP` + probes (engines); image labels + digests;
`router-image.manifest` (VM images); the registry `requires` +
`module_requirements` closure (modules); `initialData` sizes; the
mesh-asset licence check for licences. Every node carries
`{name, kind, version, source, bytes, licence, sha/digest}`; every edge
carries `{kind: contains|requires|depends|engine|image}`.

**Where it lives.** `pol build release <ver>` (prd-5) writes
`release.json` (the manifest, ver-2) AND `tree.json` next to the pool;
the framework serves `GET /api/release` and `GET /api/release/tree`
(+ `?module=<m>` for a subtree) from the manifest row seeded at boot;
pol-hub's build step renders `tree.json` into a static docs page.
Because the tree is regenerated on every release build from those
sources, it "dynamically updates as we update things" with no file
anyone edits by hand — the only hand-edited inputs are the `VERSION`
files and the curated `ENGINE_MAP`.

**How it is shown (no new chart engine):**
- in Polari: `/release` page = the existing d3 pack layout
  (`topology-graph-layout.ts`: components as enclosing circles, their
  pieces nested, modules nested in the framework, dashed copies for
  shared dependencies) with a click-through table per node (version,
  bytes, licence, source file:line); the tech-tree view is the
  alternative if a hierarchy with "completion rings" (built / verified
  / published per node) reads better — one of the two, decided in
  tree-3, both are configured displays of the same `tree.json`;
- on pol-hub: a static page per release (`/docs/releases/<ver>/`) with
  the same tree as collapsible HTML (no JS needed), the per-component
  tables, the deb list with online/offline and sizes, and the machine
  index (`llms.txt` + `tree.json` download) that pub-5 asked for.

## 5. The documentation pages (pol-hub `docs/`, pub-5's "real documentation section")

1. **Install Polari** — the deb route (polari-complete; the three doors;
   join by fingerprint), what a normal user sees at each step, the
   online vs offline bundle.
2. **App kinds** — Container App vs Hardware App vs Polari app vs Polari
   instance vs Polari module vs Isle VPN: the table in §2, with "what
   your device needs" per kind.
3. **Agent tiers** — reach-only, member, hardware, core: what each can
   run, how to upgrade a member to the hardware tier in place, why a
   Hardware App never moves.
4. **Dependencies and offline media** — what rides in an online deb,
   what an offline deb carries (wheels), what only the media can carry
   (system engines, engine images, VM images), what the agent installs
   on admission and the receipt it leaves.
5. **The Polari tree** — the generated page per release: versions of
   every piece and their dependencies, how to read it, the JSON behind
   it.
6. **Uninstall and teardown** — member leave, core cascade, verify
   zero, the stale-launcher note.
Each page is written once from the plans above and thereafter carries
generated tables (versions, sizes, deb names) from `tree.json`, so the
prose stays and the numbers follow the build.

## 6. Phases

- **tree-0 — this plan.** ✅
- **tree-1 — Hardware App kind + hardware tier** (isle-core's Claude for
  the isle half): catalog kind `hardware-app` (entry fields:
  `vm_image_ref` + sha, `domain_template`, `passthrough_json`,
  `requires_tier`), `isle onboard --host --hardware`, `agent.tier`
  reported in the device push (`facts.agent_tier`) so
  `/display/isle-mesh` shows it, the store's refusal text, coherence
  flag for a pinned app whose device lost its hardware.
- **tree-2 — offline dependencies through the agent** (both sides):
  the compose bind mount, `isle app admit|remove` verbs, `ENGINE_MAP`
  kind `image`, `installDeps` from `wheels/`, wheels cut from the
  release image, the `ModuleInstallRecord` receipt, scenario B5's gap
  closed.
- **tree-3 — the tree generator + surfaces**: `pol build release`
  emits `tree.json`; `/api/release/tree`; the `/release` display over
  the pack layout; pol-hub's static page generation.
- **tree-4 — the six docs pages** on pol-hub, prose once, tables
  generated; `llms.txt` and the machine index (pub-5).

## 7. Decisions (defaults in bold; his call)
- D1 the kind's name: **"Hardware App"** (catalog id `hardware-app`), as
  he suggested, vs "VM App".
- D2 the tier's name: **`hardware`** (`agent.tier` values `reach | member
  | hardware | core`) vs "host+kvm".
- D3 admission trigger: **postinst calls `isle app admit` when the CLI
  exists** vs the agent watching `/var/lib/polari/apps` (a watcher
  means a daemon; the call is explicit and dpkg-clean).
- D4 tree rendering in Polari: **the topology pack layout** vs the
  tech-tree view (both are configured displays; the pack shows
  containment, the tree shows depth).
- D5 licences in the tree: **yes, per node, from the mesh-asset check
  (API + LICENSE + header)** — it makes the GPLv3 gate visible per
  release.
- D6 pol-hub generation: **a build step that writes static HTML from
  `tree.json`** (no site generator dependency) vs adopting mkdocs.

## 8. Boundaries
- isle-core's Claude: tree-1 (kind, tier, onboard flag, push fields,
  the VM lifecycle for Hardware Apps), the isle half of tree-2 (bind
  mount, `isle app admit|remove`, offline apt pool for engines).
- Ours: the catalog entry shape and coherence flags, the framework half
  of tree-2 (installDeps from wheels, receipts, wheels from the image),
  tree-3 and tree-4.
- Dustin: D1–D6, the first Hardware App to build (the radio? the FPGA
  programmer?), the pol-hub words.
