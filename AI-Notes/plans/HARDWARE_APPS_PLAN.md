# Hardware Apps (hw-app arc): the guest-network VM, the WiFi-over-Reticulum relay VM, and the receive-only SDR — PLANS ONLY

**Date:** 2026-09-08 · **Status: PLAN (hw-app-0). No code.** His go: "let's
start with making a guest network KVM app and the relay KVM for wifi via
reticulum, since that is an important one, and then record the receive
only sdr. But those we just want to plan." Design basis:
`AI-Notes/designs/STANDARD_POLARI_APP.md` §3 (the router-VM machinery a
Hardware App reuses; the `hardware-app` kind beside `library` /
`polari-app` / `isle-app` in `polari-app.json`).

## 0. What every Hardware App shares (hw-app-1, the seam — built once)
- **Isle side (isle-core's Claude, requested via NOTES-FROM-POL-CORE.md):**
  `isle vm` = `router-init-lib/40-image,50-vm,60-bridge` + the two attach
  libs extracted into `isle-cli/lib/vm.sh` (define/start/stop/undefine/
  status/attach-usb/attach-nic/console/health); the router becomes its
  first caller with no behaviour change. `agent.tier=hardware`
  (`isle onboard --host --hardware` = the router's prereq install +
  libvirt/kvm groups; a core already qualifies). `agent-manager register
  --upstream <ip:port>` beside `--container`. Health = `virsh domstate`
  + a guest probe (qemu-guest-agent or the SSH key). Boot replay via
  `isle-mesh-boot.service` exactly like the router.
- **Polari side (ours):** a module of kind `hardware-app` = a manifest
  (`app.kind: "hardware-app"`, `agentTier: "hardware"`), a `<x>_catalog.py`
  with `IsleCatalogEntry` rows carrying the VM fields (`vm_image_ref`,
  `image_sha256_raw`, `domain_template`, `memory_mb`, `vcpus`,
  `passthrough` = DeviceLink names, `guest_kind`), an `install_plan` →
  `isle app admit <name>` (render XML from the entry + DeviceLink rows →
  `isle vm define/start` on the pinned device; refused without the tier),
  a `<x>_basis.py` for the app's own state rows (the twin), a `<x>_page.py`
  (configured tables only), and a `<x>_selftest.py` whose XML-render leg
  is pure and whose `virsh` leg skips honestly. `MeshAppRealization`
  kind `kvm` enforced (the mover refuses), `DeviceLink.owner` set on
  attach / cleared on detach (exclusivity becomes a fact).
- **Images:** every guest image is manifest-pinned by RAW sha like the
  router's, fetched cache → mesh → release → build, staged under
  `/var/lib/libvirt/images/` (the AppArmor rule), and carried by the
  offline medium's `hardware/<app>/` section with the guest's package
  set — never a booted image.
- **The kernel-adaptive part:** the domain's passthrough list and the
  guest's driver/package set are rendered from `DeviceLink`/`DeviceModel`
  rows; a device plugged into the host becomes a `hostdev` entry and a
  module in the guest, by data.

## 1. hw-app-2 — `isle-guestnet`: the guest-network VM
**What:** a SECOND OpenWrt guest (same image manifest as the router, zero
new image work) that owns a WiFi adapter (USB `hostdev`, the existing
`add-usb-wifi` path) or a spare NIC (macvtap `interface-direct`) and
serves an ISOLATED guest network: its own SSID/VLAN, DHCP, DNS
forwarding, `forward=REJECT` to the isle zone, an allow-list of isle
apps exposed to guests (each exposure = an `AppVpnExposure`-style ledger
row, the VPN arc's rule: every exposure is a row). Use cases: visitors,
IoT quarantine, a "public" face for `.arch` later.
**Rows:** `GuestNetworkDefinition` (ssid, vlan, cidr, dhcp range, dns
mode, exposures[], captive note), `GuestNetworkState` (twin: clients,
leases, rx/tx, uptime — pushed by the guest via the same push-to-polari
cadence). Page: guest networks + exposures + clients tables.
**Steps:** catalog row + manifest → `isle app admit isle-guestnet` renders
XML (router template + the adapter hostdev) → `isle vm define/start` →
UCI profile pushed over the SSH key (the `isle-vlan-router-config-lib`
idiom, a second profile: `guest` zone, `forward=REJECT`, dnsmasq
forwarder to the router for allowed names only) → registration with an
IP upstream → `/display/guestnet`.
**Acceptance:** a phone on the guest SSID reaches only the allow-listed
app; `isle status` shows the VM, its adapter owner, and the exposure
rows; `isle app put-away` stops it and the adapter's `DeviceLink.owner`
returns to `host`; offline install from `hardware/isle-guestnet/`.
**Decisions:** D1 AP inside the guest (adapter passthrough, needs an
AP-capable chipset — `DeviceLink.ap_capable` is measured, not assumed)
vs the guest as a wired VLAN only; D2 client isolation default ON.

## 2. hw-app-3 — `isle-relay`: WiFi over Reticulum (the important one)
**What:** a guest that is a RETICULUM RELAY NODE with its own WiFi: it
owns a WiFi adapter, runs the pinned MIT stack (our forks) and speaks
the archipelago's bearers — AutoInterface/TCP over the WiFi it serves to
neighbours, TCP to the isle's own sidecar — so two households share a
connection over Reticulum "as the routing" (Phase E, now with a body).
It applies the traffic classes and relay policy of RETICULUM plan §5c-e
(C0 control always; C1 baseline messaging = the `relay_baseline` knob;
C2 `.mesh` and C3 `.arch` by allow-list and tier floor) and the
`arch-relay` app kind of §5c-b when an archipelago grows past the relay
threshold. Isolation is the point: the radio/WiFi bearer and the
Reticulum transport live in the guest; the host keeps only the
`tx_permitted()` gate and the policy rows.
**Rows:** `RelayNodeDefinition` (bearers[], relay policy ref, floor
tier, identity = the guest's static Reticulum identity — §5c-c R1),
`RelayNodeState` (twin: peers heard, per-class bytes/drops per bearer,
link RTTs — the §5c-d measurements), `RelayPolicy` (from §5c-e).
Pages: relay nodes + bearers + per-class counters + measured routes.
**Guest:** Alpine/Debian minimal, sha-pinned; packages: hostapd or
wpa_supplicant (AP or client side of the neighbour link), the sidecar
image's Python stack (rns/lxmf from the forks) as a service, nftables
for the class queues; the control channel to the host = SSH key +
`/status`-style JSON on a virtio-serial or the isle-agent-net leg.
**Steps:** shares hw-app-2's plumbing; adds the sidecar-in-guest service
+ the policy renderer (rows → sidecar config + nft queues). Acceptance =
Phase E repeated THROUGH the relay: two isles exchange messages with
the relay as the only path, per-class counters move, the relay's
identity persists across a guest restart, a barred class is refused with
the measurement cited.
**Decisions:** D3 the guest OS (Alpine for size vs Debian for parity
with the sidecar image); D4 whether the relay AP is the same SSID as
guestnet (one VM, two roles) or a separate guest.

## 3. hw-app-4 — `isle-sdr-rx`: the receive-only SDR (RECORDED, not planned in detail)
A Debian/Alpine guest owning one USB SDR dongle (`DeviceModel` class
`sdr-rx`), receive only — no transmit path exists in the guest, so the
TX-legality gate is untouched by construction. It produces evidence
rows (spectrum/airtime/noise-floor measurements over time) that the
Reticulum floors (§5c-d) and the HAM-band caution need; it is the
smallest useful Hardware App and the cleanest test of the seam after
guestnet. Rows: `SdrCapture`, `SpectrumMeasurement`. Pages: measurements
as graphs (sci-xy-chart, the ONE chart home). Recorded here so it is
next after the relay; details when it is picked up.

## 4. Order + gates
hw-app-1 (seam, both halves) → hw-app-2 guestnet → hw-app-3 relay →
hw-app-4 sdr-rx. Gates: his D1–D4; isle-core's `isle vm` extraction;
the manifest kind `hardware-app` exists already (sap-1) so the first
module can be scaffolded the day the seam lands.

## 6. Status 2026-09-08 (evening) — the Polari half of hw-app-1/2/3 BUILT
His rulings: hardware apps = KVMs with "shell-ish handling"; the router IS
one but stays woven into the isle; reticulum = a `hardware-extension-app`
(extends the relay guest); build the relay and guest versions of the KVM.
- Standard: `app.kind` gains `hardware-extension-app` + `app.extends`;
  hardware kinds require `agentTier: hardware`; `generate` preserves a
  hand-set app block. reticulum's manifest: kind hardware-extension-app,
  extends isle-relay.
- Catalog: `CATALOG_KINDS` + `HARDWARE_KINDS`; `IsleCatalogEntry` gains
  requires_tier / guest_kind / vm_image_ref / image_sha256_raw / memory_mb
  / vcpus / passthrough_json / extends; `install_plan` for both kinds
  (isle vm define/start/status; status/extend).
- `hardwareapps` (library): `HardwareAppDefinition` / `HardwareAppState`,
  `custom/domain_xml.py` (the router template generalised; named
  refusals: sha pin, memory, bridges, extension apps render no guest),
  `custom/uci_profiles.py` (relay: forward ACCEPT + bearer port; guestnet:
  REJECT, wan-only, allow-list rules, client isolation; PSK deploy-time),
  `/api/hardwareapps[/render/<name>|/state]`, `/display/hardware-apps`.
- `isle_relay` (RelayNodeDefinition/State, seed relay-1 + the guest row +
  the store row, `/api/isle-relay/summary`, `/display/isle-relay`) and
  `isle_guestnet` (GuestNetworkDefinition/Exposure/State, seed guest-1, no
  exposures by default, `/api/isle-guestnet/summary`, `/display/isle-guestnet`).
- Proven: selftests 10/10, 6/6, 6/6; lazy guard 23/23; 52/52 manifests
  conform; test-build boot with the six modules: both guests listed with
  the honest refusal "image_sha256_raw is empty" (pin at deploy), UCI
  renders (2.1 KB), pages seeded, 0 tracebacks.
- Isle half requested: NOTES-FROM-POL-CORE.md 2026-09-08 (`isle vm`
  verbs, tier, state push). "Shell-ish handling" on the store = the
  install plan steps + `requires_tier` (the store refuses without libvirt).

## 7. Status 2026-09-08 night — the map, the printer, the slicer, the suite (all Polari-side, proven in test builds)
- **hwmap** (hwm-1): scanner + mapping rules + rows + ingest/query API +
  page + `pol hwmap scan|push|devices|ports|candidates`; fixtures from all
  three boxes; selftest 15/15. Real: isle-core hardware-tier ready.
- **voron** (built by an agent on the standard, 16/16): PrinterDefinition /
  PrinterBoard / PrinterState, printer.cfg renderer (Voron 2.4/Trident
  reference pins for Octopus 1.1 + EBB36/42, refusals for unmeasured
  boards), Debian provisioner (Klipper `8c29c0a8`, Moonraker v0.11.0,
  Mainsail v2.19.0 — pinned from PRINTER_STACK_GATE.md; update_manager
  omitted; sim mode = Klipper linux-process MCU, `kinematics: none`).
- **kirimoto** (isle-app, MIT, pinned `ff769224`): Dockerfile from the pin,
  SlicerInstance/SlicerProfile rows, store row (`isle app deploy kirimoto
  --image polari/kirimoto:ff7692241c …`).
- **suiteapps** + **printing_suite** (sa-1/2): suite-app kind, parts,
  contracts, placement; the production suite placed 6/8 in the test
  build — printer + relay wait for a hardware-tier device (isle-core
  qualifies once its scan is pushed to the live instance).
- Licence gate: `AI-Notes/evaluations/PRINTER_STACK_GATE.md` — whole stack
  green; simulation ladder recorded (stack-runs → kinematics batch mode →
  simulavr on the wire; no open-source physics FDM sim — the physics rung
  is waxprint).
- Still isle-core's: `isle vm` (define/start/status/extend/attach), tier
  onboarding, state pushes. Still ours: printcam + dryer extensions,
  Kiri:Moto → Moonraker upload wiring (cors_domains), the SliceJob →
  GcodeArtifact hand-off automation, the physics rung.

## 8. 2026-09-09 morning — his rulings applied: suite app (D6 ✓), print camera (D7 ✓), the automation (D8)
"Automate the process of enabling just defining what you want in Polari:
upload a CAD design, define what material you want the object made of, it
runs the mold nesting automation, you get the outermost nested PLA or wax
filament mold from the simulation, that mold is passed to the slicer and
sent to the printer, cached at each step so we can print again or retry."
- **ProductionRun** + **RunStepRecord** (printing_suite): a run walks
  design → material → nesting → mold → slice → print → measure through
  `custom/pipeline.py`; each step's result is a cached, checksummed
  record (rows + artifact bytes in MinIO or the data dir); `retry`
  re-runs one step and invalidates later records; `reprint` reuses the
  cached gcode. Real adapters (`custom/adapters.py`): casting's
  `plan_nesting`, mathshapes' `export_shape` (STL), the Kiri:Moto CLI in
  the built container, Moonraker's upload API on the guest's ip from
  `HardwareAppState`. Every absent dependency is a named refusal.
  API: `POST /api/printing-suite/runs`, `…/{name}/advance|retry|reprint`,
  `GET …/runs`. The "outermost nested mold" = the lowest-sequence
  CastingStageDefinition whose mold material is the printable feedstock;
  its MoldDefinition body shape is what gets exported and sliced.
- Proof: pipeline selftest 10/10 (fake adapters, every refusal path,
  retry/reprint); live test build: a run created through the API passed
  design + material against real rows and stopped at nesting with the
  planner's own refusal (the seeded CAD row had no real shape) — three
  cached records, 0 tracebacks.
- **printcam** (hardware-extension-app, extends voron-printer): USB camera
  passthrough (need `usb role=camera`; the map tags UVC devices),
  ustreamer service, Moonraker `[webcam]`, nginx `/webcam/`, timelapse
  component at a pinned commit (PIN ME until gated). Store plan `isle vm
  extend voron-printer --with printcam`. 5/5.
- Still to do for a real print: a CAD import through the CAD worker (the
  design step then names a real shape), the voron guest image pin, the
  isle's `isle vm` verbs, a camera plugged into isle-core.
