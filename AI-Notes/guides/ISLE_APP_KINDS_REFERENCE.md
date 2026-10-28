# Isle app kinds — the shared reference (v1, 2026-10-28)

Held by all three agents (Claude on pol-core, Codex on isle-core, Codex on econ-core) and kept near the front of memory.
Dustin's rule (2026-10-28): "the right way to expose things in the isle is to convert them into an app as data … a Polari App should be
installed locally to act as the local node for those to be installed onto … for Mesh Apps there is a utility tool for wrapping existing
docker compose". Everything below is read from the installed CLI 0.1.162+offline6 and framework dev c11eacd (`modules/islemesh/custom/
islemesh_constants.py`, `modules/islemesh/islemesh_catalog.py`, `modules/<m>/polari-app.json`), not invented. Gaps are marked ⚠.

## 0. Three separate states of a device, never conflated

| State | Meaning | How it is reached | Proof |
|---|---|---|---|
| **network member** | the device has an isle address on the wire | DHCP from the router on the isle cable (NM profile) | a 10.x lease, router + core agent ping, beacon seen |
| **app access** (use) | the device can open isle apps by name with trust | isle CA in system + browser store; `.isle` split DNS to the router | `https://whoami.isle` 200 with system trust |
| **hosting** (one ability per kind, below) | the device runs apps for others | `isle join --interface <nic>` → the remote agent (nginx proxy on a macvlan) and then per-kind prerequisites | the agent healthy with its own lease; per-kind acceptance |

Device **tiers** (store-setup.sh `--tier`): `access` = use only (launchers; needs only the CA + DNS); `member` = `--host`, runs an agent, hosts
apps; `hardware` = member + libvirt/KVM for guests (⚠ the CLI 0.1.162 has no hardware tier yet — it joins as member and warns).

## 1. The kinds (catalog `CATALOG_KINDS`) — what each IS, how it is MADE as data, how it is PUT ON the isle, what the isle must PROVIDE

### mesh-app — any container workload as an `.isle` app
- **Made:** from an existing docker-compose (`isle app scaffold <compose.yml>` / `isle app init -f`) or a bare image; the catalog row carries
  `source_ref` (compose path/URL or image), `service`, `port`, `domain`, optional `provides_engine`.
- **Put on:** `isle app deploy <name> [--compose <ref> | --image <ref>] [--service S] [--port P] [--domain D] [--engine E]` on the HOSTING
  device → containers up (orchestrator `compose` today; `swarm` = mac-4, ⚠ not built) + `agent register` → nginx fragment → `<name>.local`
  → `<name>.isle`.
- **Isle must provide:** a member device with Docker + a healthy agent; the image reachable (⚠ `registry.isle:5000` does not exist yet;
  interim = image already present on the device); a TLS leaf for `<name>.isle` (only the core holds the signing key → ⚠ member needs a
  CSR→core→leaf path); the router `.isle` record (written by the core's dns-reconcile from the catalog instances — one owner per bare name);
  RAM/disk per the row's cost line.
- **Polari tie-in:** `provides_engine` makes it an engine provider; a Polari instance binds it through `EngineProviderBinding` (knob →
  binding row → worker URL). Examples: `whoami`, `board-engines` (:9830, 512 MiB, UNO simavr + C3 QEMU twins, no KVM), `scope-engines`
  (:9880), `cad-engines`, `msci-engines`, `dask`.

### polari-instance — a Polari NODE on a device (the local node Polari apps install onto)
- **Made:** it IS the runtime (prf-backend + prf-frontend compose seeded from `polari-isle/`), parameterised by `--name` and `--modules`.
- **Put on:** `isle polari instance deploy [--name <n>] [--modules a,b,c]` on the hosting device → auto-names (polari-2…), compose up behind
  the device's agent, registers `<name>.isle` + `api.<name>.isle`.
- **Isle must provide:** a member device with Docker + agent; prf images from `registry.isle:5000` (`--pull`) or already local / the offline
  release `images/`; two TLS leafs (⚠ same member-issuance gap: the verb's "leaf issuance hook" calls `certs issue`, which fails off-core);
  two `.isle` records; ~1.1 GB of images + data volumes; the core's catalog reachable (`api.polari.isle`) for module/store resolution.
- **Enables:** `polari-module` installs and `polari-app` launchers that point at it. One per device is the normal case.

### polari-module — a module installed INTO a Polari instance
- **Made:** the module's `polari-app.json` (classes, pages, endpoints, `requires.modules`, `requires.engines`, selftests, security).
- **Put on:** `isle module install <mod>` → the `polari-module-<mod>` .deb from apt.isle (mac-8, ⚠ not published yet) else
  `/api/topology/assign` on the local instance + redeploy with `POLARI_MODULES` (today: the instance's `--modules` list IS the install).
- **Isle must provide:** a local `polari-instance`; the module's `requires.modules` on the same instance; its `requires.engines` either as
  system binaries on that device (e.g. `make`, `kicad-cli`) or as mesh-app workers bound by `EngineProviderBinding`; apt.isle once debs exist.

### polari-app — a Polari app USED from a device (native-feeling launcher)
- **Made:** a module whose `app.kind = polari-app` (46 of our modules; `agentTier` member or core) — the data is the same polari-app.json.
- **Put on:** `isle shell launcher --name <n> --title <t> --url <instance url> --install` (store kind `polari-app`) or `pol apps shell <app>`
  which builds the launcher .deb from the app's registration (sep-3).
- **Isle must provide:** `polari-shell-core` on the device (shared JCEF runtime), app ACCESS (CA + `.isle` DNS) to an instance that hosts the
  module — the device itself hosts nothing. The `access` tier suffices. This is "use", not "host".

### hardware-app, realization `kvm` — a KVM guest the isle defines and starts
- **Made:** Polari rows (`hardwareapps` module: `HardwareAppDefinition` → domain XML + UCI profile rendered by `/api/hardwareapps/render/<n>`);
  `app.kind = hardware-app`, `realization = kvm`, `agentTier = hardware`.
- **Put on:** `isle vm define <name> --from-polari` → `isle vm start <name>` → `isle vm status <name>` (refused without the hardware tier).
- **Isle must provide:** a device with VT-x/`/dev/kvm` + libvirt/qemu (econ-core and the core have it; pol-core has NO KVM), the guest image
  (`vm_image_ref`), USB/PCI passthrough rows when the guest owns hardware, a Polari instance to render from. Examples: `isle-relay`,
  `isle-guestnet`, `voron-printer`.

### hardware-app, realization `bridge` — a Hardware Bridge App (board over USB, or its simulated twin)
- **Made:** `app.kind = hardware-app`, `realization = bridge`, `agentTier = member` (e.g. `uno_core_demo`: requires board, cmod, electrodevice,
  grpcbridge, hwnocode); `grpcbridge.HardwareBridgeDefinition` carries the source: `simulated` (a twin worker) or `serial` (a real board).
- **Put on:** three pieces, independently installable, one grouped install: (i) its modules into a local Polari instance (`isle module
  install`), (ii) the twin worker as a mesh-app (`board-engines`) on any member, bound by `EngineProviderBinding`, (iii) the native panel
  = `pol apps shell <app>` launcher (opens the app-shell HardwareBridge panel, Depends avrdude) on the device that holds the USB board.
- **Isle must provide:** NO KVM. For simulation: a member for the worker + the instance. For real hardware: USB device access on the
  launcher's device (dialout / udev; the bridge's serial source). Simulation readiness and real-device readiness are reported separately;
  a simulated run never proves passthrough or flashing.

### hardware-extension-app — functionality pushed INTO a running hardware-app guest
- **Made:** `app.kind = hardware-extension-app`, `extends = <hardware-app>`, `agentTier = hardware`. **Put on:** `isle vm status <host>` →
  `isle vm extend <host> --with <name>`. **Isle must provide:** the host guest installed and up on a hardware-tier device. Example:
  `pol-reticulum` on `isle-relay`.

### isle-vpn — the Link / Bridge VPN listings (vpn module on the core); out of the testing path for now.

Other `app.kind` values in polari-app.json that are NOT installable on their own: `library` (9 modules; pulled in by `requires.modules`),
`suite-app` (1), `isle-app` (1). `catalogKinds` on a row lists the catalog kinds one module may surface as.

## 2. Who can host what today (2026-10-28)

| Device | Member | Agent | CA signing | KVM | Disk free | Can host |
|---|---|---|---|---|---|---|
| isle-core (core) | core | vlan-agent | YES (intermediate) | yes (router VM) | — | everything; keep workers off it by choice |
| pol-core | yes (01:17Z) | remote-agent 10.10.0.116 | no | **NO** (vmx absent) | **3.5 GB** | polari-instance (on local images), polari-module, mesh-app (small), launchers; no kvm hardware-apps |
| econ-core | joining (cleared) | — | no | yes (N95, /dev/kvm) | 72 GB | mesh-app workers (board-engines first), polari-instance, bridge sims; kvm guests later (no VM for now, his call) |

## 3. Isle-wide dependencies still missing (the testing loop hits these first)
1. `registry.isle:5000` (image registry on the core) — `pol dev deploy` pushes to it, `isle polari instance deploy --pull` pulls from it.
2. Member TLS leafs — CSR on the member, signed on the core, leaf + chain returned (never the CA key).
3. `polari-module-<mod>` debs in apt.isle (mac-8) — until then module install = topology assign + redeploy.
4. Hardware tier in the CLI (libvirt/KVM detection + `isle vm` on a member) — today falls back to member.
5. Swarm orchestrator for mesh-apps (mac-4 converter) — today compose only; pol-core's existing swarm stack is separate from this.
6. One owner per bare `.isle` name on the router (the reconciler fix was the first piece; a conflict rule is still owed).
7. Store eligibility across the isle: per-kind requirement descriptor × per-device observed facts → `/api/islemesh/catalog/<name>/targets`
   (ready / requires setup / incompatible / offline-or-unknown, with reasons and evidence time) — backend door owed (Claude).

## 4. First vertical slice under this model: `uno_core_demo`
polari-instance on pol-core (`--modules board,cmod,electrodevice,grpcbridge,hwnocode,uno_core_demo`) + `board-engines` mesh-app on econ-core
+ `pol apps shell uno_core_demo` launcher; acceptance = the uno-light twin run from pol-core's instance page returning the cycle record.
