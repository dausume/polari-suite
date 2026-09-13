# Polari ISO plan — computers that are Polari from the first boot (iso-0, 2026-09-12)

_His direction (2026-09-12): "developing out ISOs so we can just make computers that use Polari from the start and have a full isle on the OS install, and/or profile-based installs that the core isle can derive and push to other systems. Ubuntu with KDE Plasma so it can be adaptive for both headless and normal desktop situations, giving different look and feels according to what people want." Plan only; nothing built._

## 0. The shape in one paragraph

One image builder, `pol iso build --profile <name>`, produces a bootable Ubuntu image whose unattended install ends with the isle installed and the machine in its role, with Polari's security rings on from the first boot. A **profile** is what a machine is meant to be — core isle, member, hardware tier, reach node, a server, a bare desktop — expressed as an autoinstall answer file plus a package set plus a look-and-feel; the core isle can **derive** a profile for a device (from what the topology says that device should be) and **push** it: onto a USB stick, or over the isle by network boot from the router VM. KDE Plasma is the desktop; the same image serves headless by not starting the display manager, and the desktop look is a Plasma global theme chosen per profile (a Polari theme generated from the frontend's own tokens, or the user's own).

## 1. Base and tools (facts to decide on)

- **Base: Ubuntu 24.04 LTS** (what isle-core and the swarm run; docker's repo covers it; the debs are built for it). 26.04 when it is LTS.
- **Two build shapes (corrected 2026-09-13, his check "using subiquity we can wrap the startup"):**
  1. **The installer ISO** = the Ubuntu **Server live ISO** (subiquity) + our `autoinstall.yaml` + the offline apt pool, with the desktop task added through autoinstall's `packages`. NOT a remaster of Kubuntu's ISO: Kubuntu 24.04 installs with **Calamares**, which does not read autoinstall. For the downloadable image and USB installs.
  2. **Preinstalled images** with `ubuntu-image classic` (an `image-definition.yaml`: seeds, packages, hooks) — no installer at all; everything happens at first boot. For pushed profiles, network boot and VMs.
  Alternatives rejected: `live-build` (more maintenance), Cubic (interactive, not reproducible). Both shapes build in a container on the hardware-tier box.
- **Wrapping the startup, two stages:** *install time* — autoinstall `early-commands` / `late-commands` (chroot into `/target`: install the isle deb from the pool, place keys, grant the command set's sudoers groups, enable or disable SDDM, mask services), `ssh` (server + authorized keys), `packages`; *first boot* — a once-only `polari-firstboot.service` (`ConditionFirstBoot=yes`, placed by late-commands) that runs the join-by-fingerprint or become-core step and records the result — preferred over cloud-init `runcmd` (one-shot, harder to make idempotent); cloud-init `user-data` stays for users/keys on preinstalled images.
- **Install: subiquity autoinstall** (the `autoinstall` YAML embedded in the image, or served per device by the core): storage, identity, network, ssh, packages, the late-commands above.
- **Desktop: `kubuntu-desktop`** task (KDE Plasma, SDDM). Precisely (his question 2026-09-12): Plasma does NOT adapt to headless by itself — when no graphical session starts (multi-user target, SDDM disabled) none of it runs and its RAM/CPU cost is zero; what an installed-but-disabled desktop still costs is disk (~2–3 GB), update volume, and the services the desktop task drags in that DO run without a screen (cups, avahi, bluetooth, power-profiles, packagekit …) unless masked per profile. So the desktop task is a per-profile choice: desktop / hardware / core profiles install it; reach and server profiles do not, and gain it later from the offline pool with one command (which means the pool must carry it — a bigger image — if that is wanted on headless profiles: D3).
- **Offline first:** the image carries the apt pool it needs (our `apt.isle` publisher tree + the platform debs, the existing offline chunk sets from dl-5), so a machine installs with no internet and joins the isle for updates.

## 2. Profiles

| profile | what the machine becomes | desktop | notes |
|---|---|---|---|
| `isle-core` | the core isle: agent, router VM (KVM), apt/registry, Polari on the isle | Plasma | needs virtualization; hardware tier |
| `isle-member` | joins an existing isle (QR / fingerprint trust flow) | Plasma or headless | the common household machine |
| `isle-hardware` | a member with the hardware tier (libvirt, VFIO, hardware groups) | either | printers, cameras, the workbench |
| `reach` | a small member that only relays (Reticulum / VPN) | headless | a Pi-class box or a VM |
| `server` | the swarm route: docker, swarm, `pol prod` from an answers profile | headless | the home server; the droplet is NOT built this way |
| `desktop` | Polari as a desktop app (the store, the shell) without an isle | Plasma | the "older person" route from the deployment docs |

A profile = `autoinstall.yaml` (answers) + `packages` (the task list) + `ssh` (his ask 2026-09-12: reachable from the first boot — autoinstall installs the ssh server and places the core's and the owner's public keys before anyone has logged in; the `polari-remote` sudoers group lands with it, so remote setup needs no password from day one) + `commands` (which command surfaces the machine exposes and to whom — a chosen SET, not everything: `isle` CLI · `pol` CLI · the store's doors (`polari-app` group) · remote operations (`polari-remote` group) · shell only; each set = packages installed + sudoers groups granted; the guided installer walks the choice, a pushed profile answers it) + `security` (which rings, all on by default here: the ISO route is where "applied by default" is true from the first boot; §ISLE_HARDENING_PLAN §15) + `look` (a Plasma global theme + wallpaper + panel layout) + `first-boot` (join or become core).

**Derived by the core:** `isle profile derive <device>` reads the topology (`PolariNodeMachine.tier`, role, the assignments) and writes the profile; `isle profile push <device> --usb /dev/sdX | --netboot` writes the image to a stick or registers the device for PXE from the router VM (dnsmasq on OpenWrt can serve it) so a fresh box on the isle VLAN boots straight into its install. Identity at first boot: the device's key pair is generated on the device; the core signs the leaf (the existing isle CA flow); the profile carries the core's fingerprint for the trust step.

## 2b. Why KDE Plasma over Ubuntu's GNOME (his question 2026-09-12)

Same base, kernel, apt and LTS; only the desktop differs, and on headless profiles neither runs. The benefits are for the desktop profiles: Plasma's look is files (global themes, panels, colour schemes) that a profile can ship and switch, where GNOME's look is fixed and changing it means extensions that break on upgrades; the KDE kiosk framework locks settings and actions down per profile (the tool for a locked household or workbench machine — GNOME has no equivalent short of policy files); a lighter idle footprint by a few hundred MB; Qt matches the instrument/CAD tooling world and KDE Connect ties phones to the isle. Costs: GNOME is the polished newcomer default with more documentation; Plasma's knobs mean a locked profile is deliberate work. Decision stands: KDE, because per-profile looks and lockdown are goals.

## 3. Look and feel

- A **Polari global theme** for Plasma (`lookandfeel` package) generated from the frontend's theme tokens (memory: tokenize by property, `--brand-*` with text pairs), so the desktop and the web app match; light and dark.
- Per-profile defaults, per-user override: Plasma's own settings stay the user's; the profile only sets the default.
- A headless profile becomes a desktop by installing the desktop task from the pool and enabling SDDM — not by having it installed and idle (see §1).

## 4. Phases

| phase | build | proof |
|---|---|---|
| iso-0 | this plan; decisions below | — |
| iso-1 | `pol iso build --profile isle-member` with ubuntu-image + autoinstall + the offline apt pool; the image boots in KVM on isle-core and installs unattended | a VM comes up with the isle deb installed and `isle status` answering |
| iso-2 | first-boot: join by fingerprint (member) or become core (`isle-core` profile with the router VM) | a second VM joins the first over the isle VLAN |
| iso-3 | profiles derived and pushed by the core (USB; PXE from the router VM) | a device registered in the topology boots its own profile |
| iso-4 | KDE: the Polari global theme, headless/desktop switch, per-profile defaults | the theme installs; sddm toggles |
| iso-5 | CI: the throwaway-VM test boots every profile's image and runs the security audit + escape test (rung 4 of the ladder from the first boot) | green in Jenkins |
| iso-6 | release: images as release artifacts beside the platform debs (built at home, published with the release; the server only hands them out) | the downloads page lists them with checksums |

## 5. Decisions for him

- **D1** Base: 24.04 LTS now, 26.04 at its LTS — or 26.04 already (the droplet runs it)?
- **D2** Build shapes: the Server-live + autoinstall installer ISO for downloads and USB, preinstalled `ubuntu-image` images for pushed profiles / PXE / VMs (recommended: both, one profile format feeding both) — or only one of them first?
- **D3** The desktop task per profile: installed on desktop / hardware / core, absent on reach / server (recommended), or installed everywhere with SDDM disabled (costs disk, updates and the desktop's background services on headless boxes)? And does the headless image's offline pool carry the desktop packages for a later switch (bigger image) or not?
- **D4** Unattended install by default (autoinstall, the machine is wiped) vs a guided installer with Polari's questions added? (Recommended: unattended for pushed profiles, guided for the downloadable desktop image.)
- **D5** Network boot from the router VM (PXE/iPXE on OpenWrt) in scope for iso-3, or USB only first?
- **D6** Secure Boot: sign nothing (installs with Secure Boot off), or use Ubuntu's signed shim/kernel and keep our packages unsigned (works with Secure Boot on)? (Recommended: Ubuntu's shim; we add no kernel modules.)
- **D7** Where images are built: isle-core (hardware tier, KVM for the proof) — and are they release artifacts like the platform debs (yes, recommended)?
- **D8** Disk encryption by default on desktop profiles (LUKS with a passphrase; TPM-bound is a later piece)?
- **D9** The Polari Plasma theme: generated from the web tokens (recommended) or hand-made?
- **D10** Command sets: the five above as the fixed menu (recommended), or free-form per profile? And is `shell only` allowed on a member at all (it cannot join the isle by itself)?
- **D11** Keys at first boot: the core's key always, the owner's key by profile — and a per-device key generated on the device for the isle CA (recommended), never a shared key baked into the image.

## 6. What this reuses (no new engines)

The apt publisher (`apt.isle`), the platform debs and their release pipeline, the offline chunk sets (dl-5), the isle trust flow (fingerprint, `isle trust fetch`), the topology's tier labels (`pol deploy tier`), the router VM (dnsmasq for PXE), the os-security rings (applied at first boot), the CI throwaway-VM test, Canonical's ubuntu-image and autoinstall.
