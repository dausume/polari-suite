# The Standardized Polari App (sap arc) — what a module IS, from the evidence, and the KVM app kind

**Date:** 2026-09-08 · **Status: DESIGN (sap-0 survey done; nothing changed in
code).** His framing: "so we can start working on testing as well as making
it easier for other users to develop their own polari app, we need to look
through our existing polari modules and try to see what a 'Standardized
Polari App' looks like … also think of some simple but useful or critical
KVM app use case … leveraging the same machinery from inside isle-core and
the way we are trying to generalize hardware and its simulation."

Companions: POLARI_TREE_PLAN (Container App vs Hardware App, the `hardware`
agent tier), CICD_PIPELINE_PLAN (tests land on this standard), the module
initialData convention (json_seeds), MODULE_PROJECTS (one repo per module).

## 1. What the survey found (49 module dirs, verified 2026-09-08)

**The intersection — what every module actually has:**
1. a package `modules/<pkg>/` with `__init__.py`, importable by its bare name
   from either root (`module_loading.module_code_dir`);
2. classes that subclass `treeObject` under `@treeObjectInit`, first field
   `name: str = ''`;
3. nothing else.

**Everything else is optional and lives in TEN hand-written core tables**,
each maintained separately, and no two agree on the module set:
`polari-modules.json` (48 entries; `video`, `scanning` absent; two legacy dirs
registered under other names) · `FEATURE_MODULES` (39; `casting`,
`composition`, `foodstate`, `pspp`, `video` missing although they have
blocks) · `FEATURE_REQUIRES` · `FEATURE_IMPORT_BLOCKS` (67 entries) ·
`MODULE_ENDPOINT_CONSTRUCTORS` (41) · `feature_derived` (3, and `sifet`
exists ONLY there) · `polariServer.defClassList` (one giant literal) · the
seed-pairs literal in polariServer · the `SEED_*_PAGE_DISPLAYS or []`
concatenation · `appstore.ENGINE_MAP`.

**Naming:** the canonical names the code implies are `<pkg>_basis.py`,
`<pkg>_api.py`, `<pkg>_seed.py`, `<pkg>_page.py`, `selftest_<pkg>.py`. Only
`vpn` and `appstore` follow all five. Twenty-five modules use a concept
prefix instead (`gears`→`gear_*`, `motors`→`motor_*`, `cntfet`→`cnt_*`);
seven have no basis file; seven no api; seventeen name selftests by topic;
page files have five different naming patterns. **No module has a
README.md.** The `"""@module <dotted>"""` docstring header is the de-facto
doc convention (1046 of ~1300 files).

**Seeding:** the good path exists — `<PKG>_SEED_PAIRS` + `<PKG>_CLASSES` in
`__init__.py`, `composition.seed_upsert.upsert_seed_pairs` (upsert, never
insert-by-name — "bitten ten times"), `initialData/<Class>.json` via
`json_seeds` — but only 4 modules use seed pairs, 5 carry `initialData/`,
and pages are seeded through `module_pages_seed._page/_table/_sapi` (the
no-raw-JSON rule lives there; the `_api` json panel is still callable).

**Selftests:** 235 files, 233 with a private copy of `check()`; discovery is
a pure glob on `selftest_*.py`; the runner parses the final `X/Y` line. The
one machine-checked contract is `selftest_lazy_imports.py` (single-module
import blocks, `construct_<m>_endpoints(polServer)` importing only its own
package).

**Packaging:** `app_deb_builder` needs only a registry row + present code;
requirements are SCANNED (imports → distributions) and unioned with the
registry `requires`; engines come from a hand-curated `ENGINE_MAP` in
appstore, absent for most modules ("an honest gap, not a claim of zero").
Catalog kinds (`IsleCatalogEntry.kind`) are an open enum: `mesh-app`,
`polari-app`, `polari-module`, `polari-instance`, `isle-vpn` (added by vpn),
`polari-app-option`, `ai-tool`.

**Scaffold:** `moduleService/moduleScaffoldGenerator.py` exists and produces
the LEGACY shape (`polari<Pascal>Module/`, one file per class,
`register*.py`, `seedData.py`) — exactly the two dirs that conform to
nothing today. `POST /modules/create` still calls it.

## 2. The standard — ONE manifest in the module, ten tables derived

The divergence is not in the modules; it is in the tables. So the standard
is: **a module declares itself once, in its own package, and every core
table is generated from that declaration** (the AST regeneration of
`feature_imports.py` on 2026-09-05 already proved tables can be derived).

### 2.1 The anatomy (canonical names; a conformance report, not a gate)
```
modules/<pkg>/
  polari-app.json          THE MANIFEST (§2.2) — the only file the core reads to learn the module
  README.md                what it is, the pages, the objects, how to run its selftest (his "easier for other users")
  __init__.py              """@module <pkg>""" docstring; re-exports; <PKG>_SEED_PAIRS, <PKG>_CLASSES
  <pkg>_basis.py           the treeObject classes (split <pkg>_<concept>_basis.py when large — reticulum's 9 are fine)
  <pkg>_api.py             class <Pkg>API(treeObject) registering /api/<pkg>/* in __init__
  <pkg>_endpoints.py       def construct(polServer) — imports ONLY from <pkg>; the core table maps to it
  <pkg>_seed.py            SEED_* rows (Analysis/Solution/Table/Graph definitions), upserted
  <pkg>_page.py            SEED_<PKG>_PAGE_DISPLAYS via module_pages_seed (_table/_sapi/_page only — NEVER _api)
  <pkg>_engine.py          pure functions (no manager, no DB) — the testable core
  <pkg>_remote.py          optional: the *_remote resolution ladder for an external engine/sidecar
  <pkg>_catalog.py         optional: IsleCatalogEntry rows + install_plan for app kinds the module adds
  initialData/<Class>.json module-initial-data/1 rows (non-regenerable data only)
  selftest_<pkg>.py        the ONE required suite; more as selftest_<pkg>_<topic>.py; shared check() from moduleService
```
Concept prefixes stay legal (`gear_basis.py`) — the manifest names the
files, so the core never guesses from names again.

### 2.2 `polari-app.json` (module-initial-data style, schema `polari-app/1`)
```json
{ "schema": "polari-app/1",
  "id": "gears", "title": "Gears", "description": "…",
  "version": "0.1.0",                       ← the repo's VERSION (ver-1)
  "kind": "official",                       ← provenance (registry kind)
  "app": { "realization": "container",      ← container | hardware (§3) | library (no app, objects only)
           "family": "",                    ← e.g. "isle-vpn"; empty = the module's own
           "catalogKinds": [] },            ← kinds this module ADDS to IsleCatalogEntry
  "requires": { "modules": ["composition"], ← replaces registry requires + FEATURE_REQUIRES
                "libraries": [],            ← declared pip deps (the scan still measures; a mismatch is a finding)
                "engines": [ {"name": "ngspice", "kind": "system", "probe": "ngspice"} ],  ← replaces ENGINE_MAP
                "agentTier": "member" },    ← member | core | hardware (POLARI_TREE_PLAN)
  "classes": ["Gear", "GearTrain", …],      ← replaces defClassList's entry for this module
  "imports": [ ["gears.gear_basis", ["Gear", "GearTrain", "SEED_GEARS"]], … ],   ← replaces FEATURE_IMPORT_BLOCKS
  "endpoints": "gears.gear_endpoints:construct",                                  ← replaces MODULE_ENDPOINT_CONSTRUCTORS
  "seedPairs": "gears:GEARS_SEED_PAIRS",    ← the upsert list; replaces the polariServer literal
  "pages": "gears.gear_page:SEED_GEARS_PAGE_DISPLAYS",
  "derivedSeeds": null,                     ← the feature_derived statements, if any, as a module function name
  "initialData": true,
  "selftests": ["selftest_gears"],
  "coreRequired": false,
  "repo": "https://github.com/dausume/polari-module-gears.git" }
```
Rules: every path is `<pkg>.<file>:<symbol>` inside the package (the
single-module rule becomes structural); anything absent is absent (no
guessing); `pol modules conform <m>` prints the table of what the manifest
claims vs what the files contain vs what the ten core tables currently say.

### 2.3 What the core does with it (sap-1, non-breaking)
- `moduleService/manifests.py`: `load(pkg)`, `validate(manifest)`,
  `all_manifests()`.
- The ten tables become **generated** from the manifests by
  `pol modules render-tables` (writes `feature_imports.py`,
  `module_endpoints.py`, the registry, `FEATURE_MODULES/REQUIRES`, the
  defClassList and seed-pairs blocks between markers, `ENGINE_MAP`) —
  exactly how `feature_imports.py` was regenerated on 2026-09-05, now from
  a declaration rather than an AST scrape. `pol build parity` checks that
  the rendered tables equal the manifests (drift = a build failure, the
  same posture as the compose parity check).
- Modules without a manifest keep working through the existing tables until
  sap-3 migrates them; `conform` marks them "legacy: no manifest".

### 2.4 Selftests on the standard (what Jenkins will run later)
- `moduleService/selftest_check.py`: the ONE `check(label, cond, extra='')`
  + `finish()` printing `X/Y checks passed` and exiting 0/1 — the runner's
  contract, imported instead of copied.
- Required per module: `selftest_<pkg>.py` covering (a) the manifest
  validates and matches the files, (b) every class in `classes` constructs
  with defaults, (c) seed pairs upsert twice with `unchanged` the second
  time (idempotence), (d) pages contain no `api-json-panel`, (e) the engine
  functions' own checks. `pol modules selftest <m>` unchanged; ci-3 runs
  the same command in the throwaway isle.

### 2.5 The scaffold (sap-2) — `pol modules new <id> --realization container|hardware|library`
Writes the §2.1 tree with the manifest filled, a passing selftest, one
page with one table (so the no-JSON rule is met from minute one), a
README, and (for `hardware`) the §3 realization files. Replaces the legacy
scaffolder; `POST /modules/create` calls the new one. The two legacy dirs
(`polariAgroForestryModule`, `polariMaterialsScienceModule`), `video`
(unregistered) and the empty `scanning/` are the first migration targets.

## 3. The Hardware App (KVM) kind — the machinery already exists, written router-specifically

### 3.1 What the isle already does for ONE VM (verified 2026-09-08, all in Isle-Mesh)
- **Domain from a template**: `openwrt-router/templates/libvirt/base-vm.xml`
  (`{{VM_NAME}} {{MEMORY}} {{VCPUS}} {{IMAGE_PATH}}`, q35, host-passthrough
  CPU, virtio disk, EIGHT spare pcie-root-ports "for device expansion", two
  bridge NICs br-mgmt/isle-br-0, pty console, VNC on loopback) + fragments
  `interface-bridge.xml`, `interface-direct.xml` (macvtap of a physical NIC),
  `usb-passthrough.xml` (`hostdev` usb by vendor/product). Rendered by
  `router-init-lib/50-vm.sh` to `/etc/isle-mesh/router/<vm>.xml`, `virsh define`.
- **Image pinned by RAW sha** (`router-image.manifest`: qcow2 packing is not
  byte-stable; never publish a booted image), fetched by the 4-step chain
  cache → mesh → release → build (`get-router-image.sh`), staged to
  `/var/lib/libvirt/images/<vm>.qcow2` owned `libvirt-qemu:kvm` because
  AppArmor cannot read a disk under the deb's `/usr/share` (50-vm.sh:39-53).
- **Lifecycle**: `virsh define/start/autostart`, AppArmor self-heal on first
  start failure, `router.sh up|down|delete|destroy|status`, ephemeral bridges
  re-created by `ensure_bridges_for_vm`, boot replay by `isle-mesh-boot.service`.
- **Attach live**: USB `hostdev` (`add-usb-wifi-lib/30-virsh-pass.sh`), NIC
  (`add-ethernet-connection-lib/40-virsh-attach.sh`, idempotent by MAC),
  udev rules that fire `isle hotplug` / `isle-port-event` — no polling.
- **Talk to the guest**: SSH key at `/etc/isle-mesh/router/ssh/`, key-first
  then sshpass fallback, `scp -O` for Dropbear; UCI rendering for OpenWrt.
- **Rows that already model it**: `MeshAppRealization(kind='kvm',
  hardware_pin_device)` — "the mover REFUSES to move a pinned realization";
  `DeviceLink.owner` = 'host' or a named VM — "passthrough is EXCLUSIVE";
  `IsleDevice.hosts_router/router_running`; `DeviceModel` (openness,
  interop, class) for what a KIND of device is.
- **What does not exist**: any second VM; `agent.tier`; catalog kind
  `hardware-app` (install_plan answers "unknown catalog kind"); PCI/vfio
  passthrough; registration of a non-container upstream (nginx fragments
  are `<container>:<port>`); a VM health source. `hotplug.sh:48` even
  defines "core" as "the router VM exists".

### 3.2 The generalization (hw-app arc): one `isle vm` library, apps are rows
**Isle side (isle-core's Claude — the boundary stands):** extract
`router-init-lib/40-image,50-vm,60-bridge` + the two attach libs into
`isle-cli/lib/vm.sh` with verbs `isle vm define|start|stop|undefine|
status|attach-usb|attach-nic|console|health <name>`, the router becoming
its first caller (no behaviour change). `agent.tier` gains `hardware`
(`isle onboard --host --hardware` = the router's own prereq install +
libvirt/kvm groups). `agent-manager register --upstream <ip:port>` beside
`--container`. Health = `virsh domstate` + a guest probe (qemu-guest-agent
or the SSH key), reported into the same registry the nginx fragments read.
**Polari side (ours):** catalog kind `hardware-app` with entry fields
`vm_image_ref, image_sha256_raw, domain_template, memory_mb, vcpus,
passthrough (DeviceLink names), guest_kind (openwrt|debian|alpine),
requires_tier='hardware'`; `install_plan` → `isle app admit <name>` (=
render XML from the entry + the DeviceLink rows → `isle vm define/start`
on the pinned device; refused without the tier); `MeshAppRealization`
kind 'kvm' enforced (mover refuses), `DeviceLink.owner` set to the VM on
attach and cleared on detach (exclusivity becomes a fact, not a comment);
the reticulum page shows owner per device. Offline: the medium's
`hardware/<app>/` section = image + domain template + the guest's
driver/package set, exactly as `router/packages/` does for OpenWrt.

**"Bind adaptively with the kernel, pull what is needed into the isle"**
(his phrase) is the DeviceLink → guest mapping: the domain XML's passthrough
list, the guest's module/package set and the udev rules that hand a device
to the VM are all RENDERED from the device rows (DeviceModel class →
driver set), so a Hardware App is a generic image plus a per-device profile
that is data — the same ladder as the hardware sim seam, where one `source`
knob moves a rig from simulated → Renode pty → `/dev/ttyACM0` with nothing
above the seam changing. A Hardware App is that seam's last rung made
deployable: the guest owns the silicon; the row is still the twin.

### 3.3 KVM app candidates — simple, useful or critical, ordered by risk
| # | app (kind `hardware-app`) | what it owns | why it matters | new work beyond §3.2 |
|---|---|---|---|---|
| 1 | **isle-relay** — a SECOND OpenWrt guest from the SAME image manifest: a guest-network AP, a sensor VLAN, or the `arch-relay` kind (Reticulum §5c-b) | a USB WiFi adapter (the existing `add-usb-wifi` path) or a spare NIC | proves the generalization with ZERO new image work; the first Hardware App that is not the router; gives the archipelago relay a body | a second UCI profile; DNS/DHCP delegation from the router |
| 2 | **isle-sdr-rx** — receive-only SDR appliance (rtl-sdr class, `DeviceModel` class `sdr-rx`) | one USB SDR dongle | RECEIVE ONLY = no TX-legality gate at all (the standing rule stays untouched); produces evidence rows (spectrum/airtime measurements) the reticulum arc's floors and the HAM-band caution need; small guest, one package | a Debian/Alpine guest image (sha-pinned like the router's) + an ingest route for measurement rows |
| 3 | **isle-lab** — the hardware ladder's real rung: a guest owning the MCU/FPGA board + programmer (`/dev/ttyACM0`, iCE40 programmer) | the SAMD21/STM32 rig + FPGA programmer over USB | the Renode-proven bridge (hwsim-1/3, grpc-j2) talks to real silicon through the UNCHANGED serial seam; firmware flash and FPGA bitstream load happen inside the guest; the host never holds the programmer | grpc-4 / hwsim-4 `Device` interface real backend; flash/bitstream verbs; the VM pins to the bench device |
| 4 | **isle-radio** — the Reticulum RNode/LoRa node as a guest | the RNode board (`DeviceLink.owner` = the VM, exclusive) | the only process that can key the radio lives in the guest; the host's `tx_permitted()` gate is the ONLY door to it; the pinned MIT stack rides in the guest, not the host | the TX gate as a virtio-serial/SSH control channel; ret-6 hardware legs |
| 5 | **isle-kernel-twin** — a minimal Linux guest whose kernel modules/initramfs/cmdline are GENERATED from the DeviceLink inventory | whatever is plugged in | the literal "adaptive with the kernel" experiment: the guest carries only the drivers its rows name; a udev fact on the host becomes a module in the guest | a generator (rows → package list + modprobe set); later than 1–3 |
Recommendation: **1 → 2 → 3**. One proves the plumbing with nothing new to
trust; two is the first useful app and is legally inert (receive only);
three is the critical one for the hardware arc and needs the bench.

### 3.4 Testing on the standard (what makes this "start working on testing")
Every Hardware App is a module under §2 with its `polari-app.json`
`realization: "hardware"` and a selftest that: renders the domain XML from
rows (pure, always runs); validates the image manifest sha fields; checks
`install_plan` refuses without the tier and without a pinned device; and
has a `virsh` leg that skips honestly when libvirt is absent (the
`skip-honest` marker the runner already counts). The isle side gets the
same shape in `isle vm selftest`. Jenkins (ci-3) runs both in the
throwaway isle VM, where nested KVM decides whether the `virsh` leg runs
or skips — recorded either way.

## 4. Phases + decisions
- **sap-0** this survey + design ✅ (2026-09-08).
- **sap-1** `polari-app.json` + `moduleService/manifests.py` + `pol modules
  conform` (report only) + `render-tables` with parity; the shared
  `selftest_check`; vpn, gears, household, reticulum as the first four
  manifests (four different shapes: full, concept-prefixed, library-only,
  multi-basis).
- **sap-2** `pol modules new` scaffold (container|hardware|library) + the
  module README convention; replace the legacy scaffolder in `POST
  /modules/create`; migrate the two legacy dirs, `video`, `scanning`.
- **sap-3** every module carries a manifest; the ten tables are generated
  only; `selftest_lazy_imports` becomes a manifest-parity check.
- **hw-app-1** catalog kind + rows + install_plan + exclusivity (ours);
  `isle vm` + `agent.tier=hardware` + upstream registration (isle-core's,
  requested through NOTES-FROM-POL-CORE.md).
- **hw-app-2** isle-relay; **hw-app-3** isle-sdr-rx; **hw-app-4** isle-lab.
- Decisions for him: D1 manifest file name (`polari-app.json` vs
  `module.json`); D2 keep concept prefixes or normalise on migration;
  D3 the first Hardware App (relay vs sdr-rx); D4 whether `POST
  /modules/create` stays (no-code module creation) once the scaffold is a
  CLI verb; D5 `requires.libraries` declared AND scanned (mismatch =
  finding) vs scanned only.

## 5. Status 2026-09-08 — sap-1 + sap-2 BUILT (his rules applied)
- **His rules:** hardware KVM apps are a KIND beside the others → manifest
  `app.kind ∈ library | polari-app | isle-app | hardware-app`; POSTFIX names
  take precedence and are the standard; module-name PREFIXES only for
  custom code; custom code that fits no concept lives in `modules/<pkg>/custom/`;
  the overall logic unchanged.
- **Done (moduleService/manifests.py, moduleService/standardize_layout.py):**
  848 files renamed/moved by `git mv` (postfix concept names; 290 into
  `custom/`), the two legacy dirs → `materials_science` / `agro_forestry`,
  1046 files had references rewritten (dotted, path, `from pkg import
  module`, and `__file__`-relative data paths in moved files); 48
  `polari-app.json` generated from the ten core tables + AST; 48 first
  `README.md`; `pol modules conform|manifests {conform,generate,list,
  readme,selftest}`; `moduleService/selftest_manifests.py` (7/8 — the two
  legacy modules have no selftest, a real gap); selftest runners accept
  `<topic>_selftest.py` (the standard) and the old prefix.
- **Verified:** 818/818 module files import (same as before); the
  lazy-import drift guard 23/23; 64 module selftest suites re-run with
  identical results to the baseline; a one-off backend boot on the
  migrated checkout (see TESTING_OWED §17).
- **Not yet:** the ten tables are still hand-written (sap-3 generates them
  from the manifests); AI-Notes references to old file names are stale
  (the code is not); `scanning/` (empty) removed; `video` registered.

## 6. Status 2026-09-08 (later) — sap-2b: stray subpackages folded, 49/49 conform
His ruling: "they should be folded under custom and if possible be
reworked to adhere more to new patterns." Done: `standardize_layout
fold-subpackages` (generic: any top-level subdir that is not custom/ or
initialData/ → custom/<sub>/ with references rewritten) applied to
grpcbridge (`custom/renode_twin/`, the firmware/Renode/Verilator assets)
and nutrition (`custom/vendor/`, the licence-clean CSVs; the loader path
follows). materials_science REWORKED: its seven object subpackages
(one legacy class per file) consolidated into standard
`dataProvenance_basis.py`, `formulation_basis.py`, `materialAdditives_basis.py`,
`materialSourcing_basis.py`, `rawMaterials_basis.py`, `referenceMaterials_basis.py`,
`targetProfiles_basis.py` (15 row classes); the plain-class taxonomies
(properties, purposes, devices, resolutions + the non-row halves of
referenceMaterials / materialSourcing, 90+ files) fold under `custom/`
unchanged. The two legacy modules gained selftests. `manifests.classify`
lists nested custom code; `conform` flags stray subdirectories.
Verified: 826/826 imports, 49/49 conform, selftest_manifests 8/8, the
dependent suites (nutrition activity/data, grpcbridge contracts/c_twin,
hwfpga, materials_science 5/5, agro_forestry 3/3) pass.
