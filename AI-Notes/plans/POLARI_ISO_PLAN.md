# Polari ISO plan — computers that are Polari from the first boot (iso-0, 2026-09-12)

_Status: iso-0 CLOSED 2026-09-13 — every decision D1–D15 made; §6 says how it meets the interfaces. His direction (2026-09-12): "developing out ISOs so we can just make computers that use Polari from the start and have a full isle on the OS install, and/or profile-based installs that the core isle can derive and push to other systems. Ubuntu with KDE Plasma so it can be adaptive for both headless and normal desktop situations, giving different look and feels according to what people want." Plan only; nothing built._

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

## 1b. Choose at build, detect at deploy (his ruling 2026-09-13)

Every choice is made when the image is built; the image carries the union of what was chosen; when it lands on a device it **detects** what the device is and **discards** what that device does not need. No question is asked on the machine. This is what makes a deployment plan pushable to many machines at once.

**Detection at deploy** (in the installer's early-commands / the preinstalled image's first boot; each a fact recorded on the device's row and reported back to the core):
- *display capability*: a GPU with display connectors (`/sys/class/drm/card*/card*-*/status` exists; a connector `connected` = a monitor is attached now). Capable → the desktop variant (desktop task installed, SDDM enabled — a capable box without a monitor today still gets the desktop, so plugging one in later just works). Not capable (no connectors: server boards, VMs without a virtual GPU) → headless; the desktop packages are not installed. Later change: `isle desktop enable|disable` (installs from the pool or removes) for the rare wrong guess.
- *virtualization*: `/dev/kvm` + IOMMU groups → the hardware tier is possible (libvirt installed only then).
- *network*: more than one NIC → router-capable (the OpenWrt router app offered); wifi present → the wifi pieces.
- *TPM present* → TPM-bound disk unlock possible (D8); *disk layout* (count, size, NVMe) → the storage answer; *RAM/CPU* → the resource labels the topology uses.
- *encryption on a headless device* is refused: at build when the headlessness is known, at deploy when it is detected (D8) — the install fails on purpose with the reason, never installs unencrypted.
- *a display-capable box chosen headless on purpose* is still possible: the choice `desktop: never` at build time wins over detection (a rack box with a GPU for compute).

**What "discard" means:** the image's offline pool holds every package any chosen variant needs (the desktop task included when any variant may be a desktop); the installer installs the subset the detections select; after install the pool is kept as a local apt mirror on `core` and `control` (they serve others) and removed on members (disk back), unless the choice says keep.

**Deployment plans:** `DeploymentPlan` = the set of machines in a topology, each with its role and choices, derived from the topology's rows (`PolariNodeMachine`, tiers, assignments) or written ahead of the hardware existing; `pol iso build --plan <name>` produces the images the plan needs (one per distinct choice set, not one per machine — detection does the per-machine part) and `isle plan push <name>` puts them on sticks or the netboot server so every machine in the plan can be (re)flashed in one go. This is the "plan of an overall deployment of systems, pushed to them all" he described; it is the goal iso-3 builds toward.

## 2. Profiles

| profile | what the machine becomes | desktop | notes |
|---|---|---|---|
| `isle-core` | the core isle: agent, router VM (KVM), apt/registry, Polari on the isle | Plasma | needs virtualization; hardware tier |
| `isle-member` | joins an existing isle (QR / fingerprint trust flow) | Plasma or headless | the common household machine |
| `isle-hardware` | a member with the hardware tier (libvirt, VFIO, hardware groups) | either | printers, cameras, the workbench |
| `reach` | a small member that only relays (Reticulum / VPN) | headless | a Pi-class box or a VM |
| `server` | the swarm route: docker, swarm, `pol prod` from an answers profile | headless | the home server; the droplet is NOT built this way |
| `desktop` | Polari as a desktop app (the store, the shell) without an isle | Plasma | the "older person" route from the deployment docs |

**Two axes, not one list (his ruling 2026-09-13):** a profile is a **role** × **desktop or headless**. A headless machine may be the core or the hardware tier; a desktop machine may be a plain member. Roles: `core` (the core isle: agent, router VM, apt/registry, Polari), `control` (NEW — has control over the isle like the core, but is not the core and has no hardware tier: it drives the core remotely through the manager app / the isle CLI), `member`, `hardware` (a member with the hardware tier), `reach` (relay only), `server` (the swarm route), `desktop` (Polari as a desktop app, no isle). **Rule: the apps that manage the isle overall (the manager app, the core/control verbs of the isle CLI, `pol deploy …`) are installed and granted only on `core` and `control` profiles**; members get member verbs only (join, status, their apps). The command set (§ below) is how the rule is applied: it is derived from the role, not chosen against it. **Headless management is terminal-first by construction:** every manager-app action is a wrapper over the same `isle` / `pol` verbs, so a headless server or a headless control box is fully managed over ssh; the two GUI-only conveniences (the store shell, the pkexec consent dialog) have terminal equivalents (`isle trust fetch --fingerprint`, `pol deploy grant`, the store's verbs) and a headless profile simply has no GUI half.

A profile = `autoinstall.yaml` (answers) + `packages` (the task list) + `ssh` (his ask 2026-09-12: reachable from the first boot — autoinstall installs the ssh server and places the core's and the owner's public keys before anyone has logged in; the `polari-remote` sudoers group lands with it, so remote setup needs no password from day one) + `commands` (which command surfaces the machine exposes and to whom — a chosen SET, not everything: `isle` CLI · `pol` CLI · the store's doors (`polari-app` group) · remote operations (`polari-remote` group) · shell only; each set = packages installed + sudoers groups granted; the guided installer walks the choice, a pushed profile answers it) + `security` (which rings, all on by default here: the ISO route is where "applied by default" is true from the first boot; §ISLE_HARDENING_PLAN §15) + `look` (a Plasma global theme + wallpaper + panel layout) + `first-boot` (join or become core).

**Derived by the core:** `isle profile derive <device>` reads the topology (`PolariNodeMachine.tier`, role, the assignments) and writes the profile; `isle profile push <device> --usb /dev/sdX | --netboot` writes the image to a stick or registers the device for PXE from the router VM (dnsmasq on OpenWrt can serve it) so a fresh box on the isle VLAN boots straight into its install. Identity at first boot: the device's key pair is generated on the device; the core signs the leaf (the existing isle CA flow); the profile carries the core's fingerprint for the trust step.

## 2b. Why KDE Plasma over Ubuntu's GNOME (his question 2026-09-12)

Same base, kernel, apt and LTS; only the desktop differs, and on headless profiles neither runs. The benefits are for the desktop profiles: Plasma's look is files (global themes, panels, colour schemes) that a profile can ship and switch, where GNOME's look is fixed and changing it means extensions that break on upgrades; the KDE kiosk framework locks settings and actions down per profile (the tool for a locked household or workbench machine — GNOME has no equivalent short of policy files); a lighter idle footprint by a few hundred MB; Qt matches the instrument/CAD tooling world and KDE Connect ties phones to the isle. Costs: GNOME is the polished newcomer default with more documentation; Plasma's knobs mean a locked profile is deliberate work. Decision stands: KDE, because per-profile looks and lockdown are goals.

## 3. Look and feel — the interface for composing a desktop (his ask 2026-09-13)

**What Plasma gives us.** The whole look is files: a **global theme** (a "Look and Feel" package: colour scheme, Plasma style, icons, cursors, window decoration, splash, fonts, and a `layouts/layout.js` that builds the panels and widgets) applied with `plasma-apply-lookandfeel -a <id>`; single knobs applied with `plasma-apply-colorscheme`, `plasma-apply-desktoptheme`, `plasma-apply-cursortheme`, `plasma-apply-wallpaperimage`, `kwriteconfig6` for the rest; a panel layout re-built at any time by evaluating a layout script through plasmashell's D-Bus interface. So a look is DERIVED and APPLIED, never hand-clicked — the same shape as every other generated control in Polari.

**The interface: preset → fine-tune → steps.**
- `DesktopLookPreset` (seeded, four): **Plasma default** (Plasma as KDE ships it — the reference the others are measured against), **Mac-like** (top bar with global menu, centred floating dock with icons-only tasks, launcher at the left of the bar, light/dark, rounded decorations), **Microsoft-like** (bottom panel, start-style launcher at the left, tasks with labels, tray and clock at the right, desktop icons on), **Ubuntu-like** (left vertical dock with icons-only tasks and favourites, top bar with clock centred and tray right, no desktop icons). Presets emulate LAYOUT and BEHAVIOUR only — never another company's icons, logos or trademarks: icon sets are Breeze/our own, wallpapers ours.
- `DesktopLookKnob` (the fine-tuning, each a typed knob with a default from the preset): panel position/height/floating, launcher kind, task manager style (icons-only / labels / grouping), global menu on/off, desktop icons on/off, tray items, clock format, colour scheme + accent, Plasma style, icon theme, cursor theme, window decoration + button order, fonts + scale, wallpaper, single- vs double-click, hot corners, virtual desktops, the meta-key action, night colour, animations speed (and off for reduced motion).
- `DesktopLook` (per user, per profile default): preset + the knobs the person changed. It **renders** to (a) a Look-and-Feel package (`org.polari.look.<name>`) with its `layout.js`, (b) the ordered list of `DesktopLookStep`s (each one command: `plasma-apply-…`, `kwriteconfig6 …`, the layout evaluation) — the "setup steps" he asked to see composed, shown as a table before they run, applied with one button or `isle look apply <name>`, re-applied idempotently, and (c) the profile's `look` field for the ISO / pushed image (the package is installed and set as the default at install time; a user's own later changes are theirs).
- **Where the interface lives:** on a desktop profile, a page of the store / manager app (a Polari display: presets as cards, knobs as a configured form, the steps table, a "preview" that applies to a throwaway Plasma activity before committing); in the guided installer, the same preset choice as one question; for a pushed profile, answered in the profile.
- Light/dark follows the web app's tokens (the Polari theme, D9) unless the person picks another colour scheme.

## 3b. Installing debs like a desktop user expects (his ask 2026-09-13)

- **Double-click a `.deb` → its store page with an Install button.** Plasma's store, **Discover**, does this natively: the MIME type `application/vnd.debian.binary-package` is associated with Discover (`plasma-discover --local-filename <file>`), which shows the package's page and installs through PackageKit with the polkit consent dialog. What makes the page good rather than bare: the deb must carry **AppStream metadata** (`/usr/share/metainfo/<id>.metainfo.xml` with name, summary, description, icon, screenshots, licence) and our apt repository must publish **DEP-11** component data (`appstreamcli`/`appstream-generator` in the `apt.isle` publisher) — then Discover shows Polari apps with icons and screenshots, and a local deb's page names its dependencies from our pool. Both are deb-builder and publisher work, no desktop code.
- **Right-click a `.deb` → "Install package" that just works.** A KDE **service menu** (`/usr/share/kio/servicemenus/polari-install-deb.desktop`, MIME `application/vnd.debian.binary-package`) with two actions: *Install* (`pkexec /usr/lib/polari/install-deb <file>` — a small root helper that runs `apt-get install ./<file>` so dependencies resolve from the pool/apt.isle, shows the result in a notification; a polkit action gives the consent dialog) and, for Polari app debs, *Install into the isle* (`isle app install <file>`, the store's door). "Just works" is then a property of the deb: correct `Depends`, the pool carrying them, and the helper never asking a terminal question.
- On headless profiles none of this exists; `apt install ./file.deb` and `isle app install` are the same operations by hand.

## 3c. Look and feel, before this section was written

- A **Polari global theme** for Plasma (`lookandfeel` package) generated from the frontend's theme tokens (memory: tokenize by property, `--brand-*` with text pairs), so the desktop and the web app match; light and dark.
- Per-profile defaults, per-user override: Plasma's own settings stay the user's; the profile only sets the default.
- A headless profile becomes a desktop by installing the desktop task from the pool and enabling SDDM — not by having it installed and idle (see §1).

## 4. Phases

| phase | build | proof |
|---|---|---|
| iso-0 | this plan; decisions below | — |
| iso-1 | `pol iso build --profile isle-member` (Server-live + autoinstall + the offline apt pool); the image boots in KVM on isle-core and installs unattended; the build refuses encryption + headless; an encrypted image refuses to install on a headless VM | a VM comes up with the isle deb installed and `isle status` answering; the two refusals show their messages and leave the disk untouched |
| iso-2 | first-boot: join by fingerprint (member) or become core (`isle-core` profile with the router VM) | a second VM joins the first over the isle VLAN |
| iso-3 | deployment plans: `DeploymentPlan` from the topology, `pol iso build --plan`, `isle plan push` (USB; netboot from the router app); detection at deploy proven on a headless VM and a desktop VM from ONE image | every machine in a plan (re)flashes from the plan; the same image lands headless on one VM and desktop on the other |
| iso-4 | KDE: the look interface (three presets, the knobs, `DesktopLook` → Look-and-Feel package + steps table, `isle look apply`), the Polari global theme, per-profile defaults; deb handling (AppStream metainfo in every deb, DEP-11 in the apt publisher, the Discover association, the right-click service menu + root helper) | on a desktop VM: each preset applies by command and re-applies idempotently; a Polari deb double-clicked opens its Discover page with Install and installs; right-click installs; headless unaffected |
| iso-5 | CI: the throwaway-VM test boots every profile's image and runs the security audit + escape test (rung 4 of the ladder from the first boot) | green in Jenkins |
| iso-6 | release: images as release artifacts beside the platform debs (built at home, published with the release; the server only hands them out) | the downloads page lists them with checksums |

## 5. Decisions for him

- **D1 — DECIDED 2026-09-13 (his): Ubuntu 26.04.** (isle-core and the home swarm run 24.04 today; the images target 26.04 and the home machines follow when they are reflashed from them.)
- **D2 — DECIDED 2026-09-13 (his): both shapes.** The Server-live + autoinstall installer ISO (downloads, USB) AND preinstalled `ubuntu-image` images (pushed profiles, PXE, VMs), one profile format feeding both; `pol iso build --profile <p> --shape installer|preinstalled`. Order: the installer ISO in iso-1, preinstalled images with the pushed profiles in iso-3.
- **D3 — DECIDED 2026-09-13 (his): desktop is an axis, not a role, and it is DETECTED at deploy** (display capability, §1b), with `desktop: never` as the build-time override. The image's pool carries the desktop task whenever any chosen variant may be a desktop; the installer installs it only where detected. New role `control` (above).
- **D4 — DECIDED 2026-09-13 (his): unattended, always.** Every choice is made when the image is built (the choices are the interface — `pol iso build` walks them, a plan answers them); the machine asks nothing and detects the rest (§1b). The downloadable desktop image is simply a build with the desktop-friendly choices made.
- **D5 — DECIDED 2026-09-13 (his): network boot, yes** — for quick setups and quick reflashing of whole systems. In iso-3 with the pushed profiles.
- **D6 — DECIDED 2026-09-13 (his): Secure Boot stays ON by default** (Ubuntu's signed shim + kernel, no kernel modules of ours). Turning it off is a DELIBERATE build-time choice in `pol iso build`: the builder shows a warning and requires the legitimate reason to be written down (recorded on the profile and the device's row), e.g. "this hardware app needs an unsigned kernel module <name>"; the image then documents on its first-boot notice that Secure Boot must be off in the firmware and why.
- **D8 — DECIDED 2026-09-13 (his): disk encryption is an OPTION, OFF by default.** When a build turns it on, the builder shows the warning in plain words: "This puts a second password on the machine itself, asked at every start before anything else. If that password is lost, nothing on the machine can be recovered — the disk can be wiped and reinstalled, but everything on it is gone. In return, the data on the disk cannot be read by anyone who takes the drive or the machine." (Precision kept in the text: the hardware is not bricked, the DATA is unrecoverable; the assurance is that the data cannot be read, not that the machine cannot be taken.) **Headless is excluded (his ruling, same day):** the option is disabled for headless. At BUILD time, encryption together with `desktop: never` (or a plan whose machine is known headless) is refused with "Disk encryption does not work on headless devices: nobody is there to type the password at start-up." At DEPLOY time, if an image built with encryption lands on a device detected as headless (§1b), the installer STOPS before touching the disk and reports the same reason — it never silently installs unencrypted; the device row records the refusal and the core sees it. TPM-bound unlock is a later piece and would lift the rule only when built and proven. **Undo (his question 2026-09-13): yes, WITH the passphrase.** LUKS2 decrypts in place (`cryptsetup reencrypt --decrypt`), so `isle disk decrypt` (and `isle disk encrypt` to turn it on later, `--encrypt --reduce-device-size`) is a planned verb: it checks the passphrase, warns ("takes as long as writing the whole disk; keep a backup; do not power off"), and for the root disk runs from our ISO's recovery boot. Without the passphrase there is no undo — that is the guarantee the warning describes. **His confirmation:** encrypt and decrypt are doors of the installed store/manager app (`polari-app` group → `isle disk encrypt|decrypt`), in place, no reinstall and no new ISO; the verb owns the root-disk care (initramfs, the boot entry, a recovery boot when the running root cannot be re-encrypted online).
- **D9 — DECIDED (his "whichever seems best", 2026-09-13):** the Polari Plasma theme is generated from the web app's theme tokens.
- **D13 — DECIDED 2026-09-13 (his): four presets** — Mac-like, Microsoft-like, Ubuntu-like, Plasma default; layout and behaviour only, never another company's icons or marks.
- **D14 — DECIDED 2026-09-13 ("whichever seems best"): the store / manager app on the desktop profile is the interface** (the door people already use, and it runs where the desktop is); the same `DesktopLook` rows are also a Polari display, so a control box can prepare a look for another machine and push it with its profile. One object, two doors, no duplicate logic.
- **D15 — DECIDED 2026-09-13 (his): the helper only** — right-click installs go through our pkexec helper, no extra steps; double-click keeps Discover's page for the people who want to read before installing.
- **D12 — DECIDED (his "managed only by terminal over ssh", 2026-09-13):** a headless control box is first-class; the CLI is the substance, the manager app a wrapper.
- **D10 — DECIDED (from his words, 2026-09-13):** command sets are DERIVED FROM THE ROLE (isle-management verbs only on core/control; member verbs on members), a fixed menu, no free-form; `shell only` is not a member variant (a member must carry the isle CLI to join) — it exists only for the plain `desktop` and `server` roles.
- **D11 — DECIDED (his "ssh from the beginning", 2026-09-13):** the core's key and the owner's key placed at install; a per-device key generated on the device for the isle CA; never a shared key baked into an image.

## 6. How the ISO arc meets the interfaces (finalised 2026-09-13; iso-0 closed)

Everything the builder asks and everything a device reports is a Polari object, shown on the screens that already exist or are planned — no ISO-only UI.

| ISO piece | object(s) | screen / door |
|---|---|---|
| a profile (role × desktop/headless, choices, ssh keys, command set, look, security, first-boot) | `DeviceProfile` (module `deployplans`, new) | `/display/deployment-plans`; `pol iso build --profile` reads it; the store's "Create my own isle" door writes one |
| a deployment plan (machines × profiles, from the topology or ahead of the hardware) | `DeploymentPlan`, `PlannedDevice` → the existing `PolariNodeMachine` rows once real | the topology page (drag a planned device to a role); `pol iso build --plan`, `isle plan push` |
| choices at build (Secure Boot off + reason, encryption on, desktop never, pool kept …) with their warnings | fields on `DeviceProfile` with the warning text seeded as `SecurityControl` notes | the builder's walk (Textual, like `pol prod guide`) and the same form on the display |
| detections at deploy (display capability, KVM, NICs, TPM, disks) and the refusals | `DeviceDetection` rows reported to the core; a refusal = a `SecurityEvent` (sec-5) on the device row | the device's own page (per-object rule); the security overview counts refusals |
| the desktop look (preset + knobs → package + steps) | `DesktopLook`, `DesktopLookPreset`, `DesktopLookKnob`, `DesktopLookStep` (module `desktoplook`, new; desktop profiles only) | the store / manager app's Look page (D14); the profile's `look` field |
| the rings on from first boot | the existing `SecurityControl` rows: state `enforce` from the first boot on the ISO route, per scenario | `/display/security` and the three views — the ISO route is where "applied by default" (rung 3) reads true |
| Secure Boot and disk encryption as chosen | two new OS-domain systems (`secure-boot`, `disk-encryption`) in the security module, audited on the device (`mokutil`, `lsblk` crypt) | the OS view's physical-access actor and its two threats (§ security module) |
| deb installs on the desktop | AppStream metainfo in every deb (the deb builder), DEP-11 in `apt.isle`, the service menu + helper (packaged in `polari-desktop`) | Discover's page; the right-click menu; the app's own page lists what the deb carries |
| command sets | derived from the role: packages + sudoers groups (`polari-remote`, `polari-app`) | the profile's row shows the set; `pol deploy grant` is the same grant on an existing machine |

Order of building: iso-1 (the build command + the installer ISO + the VM boot proof + the two refusals) → iso-2 (first boot: join / become core; the `deployplans` module's `DeviceProfile` + `DeviceDetection` rows and their display) → iso-3 (plans, preinstalled images, netboot with isle-core) → iso-4 (`desktoplook` module, the look interface, deb handling) → iso-5 (CI) → iso-6 (release artifacts). The security arc continues in parallel; the ISO route consumes its rings and never re-implements them.

## 7. What this reuses (no new engines)

The apt publisher (`apt.isle`), the platform debs and their release pipeline, the offline chunk sets (dl-5), the isle trust flow (fingerprint, `isle trust fetch`), the topology's tier labels (`pol deploy tier`), the router VM (dnsmasq for PXE), the os-security rings (applied at first boot), the CI throwaway-VM test, Canonical's ubuntu-image and autoinstall.

## Addendum 2026-09-13 — the app stick and the ISO (his ruling)

The USB app stick (`pol apps usb write`; layout `polari-apps/index.json` schema polari-app-stick/1 + the platform
deb + offline app debs + a presence-checked installer) and the ISO are INDEPENDENT deliverables: a stick installs
onto any Ubuntu (apps only, or all of Polari as an app alongside other apps, or a bulk set), and the ISO installs an
OS. Later, at build time, the ISO may ROLL UP the app portion — the same `polari-apps/` folder copied onto the ISO
and handed to the first-boot unit, which runs `install-apps.sh` after the platform (presence-checked, so a re-run
never installs anything twice). Both keep working on their own: the ISO without the folder is a plain Polari OS
install; the stick without the ISO is an app installer. Decision knob at build: `--apps <stick dir|none>`.

## §P — the PROBE STICK: diagnose first, plan on the core, install from the same stick (his idea 2026-09-15)

**The flow.** One USB stick, prepared once, carries (1) the Polari Probe for Windows, macOS and Linux, (2) the probe
cache, (3) the ISOs Polari builds, (4) each device's install plan. A person probes a machine (or many, one at a
time), plugs the stick into any Polari, assigns each probed device a role (core / member / hardware / access) and the
ISO options (shape, encryption, look preset, posture), Polari renders the autoinstall per device and copies the ISO
and the plan onto the stick, the person boots the target from the stick, first boot installs Ubuntu + Polari and
joins the isle as pre-selected, the core's topology shows it arrive.

**The stick base: Ventoy (GPL-3.0, compatible).** Ventoy makes the stick bootable once and boots any ISO copied onto
its exFAT data partition; the data partition holds the probe apps, the cache and the plans, so "flashing" an ISO is a
file copy and nothing is destroyed per device; several ISOs and several devices' plans ride together. Ventoy's
auto_install plugin injects subiquity autoinstall; first boot matches the device's hardware hash to `plans/<hash>/`.
Licence gate: verify the pin (dausume/ fork if needed) before vendoring anything.

**The probe: one JSON, three launchers.** Windows = PowerShell over WMI/CIM (Win32_Processor, _BaseBoard, _DiskDrive,
_VideoController, _NetworkAdapter, Get-PnpDevice for PCI/USB IDs, Confirm-SecureBootUEFI, Get-Tpm, BitLocker status,
RAID/AHCI from the storage controller, Fast Startup); macOS = `system_profiler -json` (SPHardware, SPPCI, SPUSB,
SPStorage, SPNetwork; FileVault via fdesetup; Apple silicon detected → NOT COMPATIBLE, stated plainly); Linux = the
hwmap scanner (usb, pci, IOMMU groups, serial). All write the same report keyed by a hardware hash (DMI UUID + board
serial hashed); cached at `probe/cache/<hash>.json`. Scripts first (`.ps1` + `.bat`, `.command`, `.sh`; no signing,
inspectable); signed binaries later for SmartScreen/Gatekeeper.

**Compatibility is DERIVED.** For each ISO Polari can build it holds the kernel's `modules.alias` and the
`linux-firmware` file list; every PCI/USB id in a report maps to: in-kernel · needs firmware · needs a third-party
driver (bcmwl, nvidia) · no driver. Plus a short curated trap list (T2 Macs, RAID mode, BitLocker, Fast Startup,
32-bit UEFI, Secure Boot + NVIDIA). The verdict per device: compatible with <ISO> / compatible with notes / not
compatible — with the evidence. Never a hand-typed HCL.

**On the core (mostly built).** The stick watcher already finds sticks; a probe stick's cache becomes `DeviceProbe`
rows; the planner suggests roles from evidence (always-on + most memory → core; IOMMU + KVM → hardware; laptops →
access) as knobs with reasons; the person confirms; Polari renders the autoinstall (hostname, tier, posture, join
token, CA fingerprint, the ISO plan's D-decisions), copies ISO + plan to the stick, and waits: the device row turns
from "planned" to "joined" when it arrives. Fleet planning = probing every machine first with one stick.

**Not promised.** "Re-check you plugged it back in" cannot run on a powered-off target; instead the probe app offers
"restart from the stick now" (Windows: a one-time firmware boot entry via bcdedit; Intel Macs: Option-key boot, or
`bless --nextonly`). Apple silicon Macs are out of scope (Ubuntu does not run there).

**Secrets on the stick.** A plan carries a join token: one-time, burned by the install, revocable by the core if the
stick is lost; the plans folder encrypted with a passphrase the installer asks for once (headless: the same passphrase
typed at the console). Decide before the first token is written.

**His decisions:** D-P1 Ventoy as the base · D-P2 scripts first, signed apps later · D-P3 one stick for probe +
install (Ventoy makes it possible) or two · D-P4 token handling · D-P5 Apple silicon out of scope. Not started.

### §P decisions 2026-09-15 (his)
- **D-P1 DECIDED: Ventoy is the base.** Requirement: USER-FRIENDLY end to end — a `README.html` at the stick's root
  that opens in any browser with one big button per OS ("I am on Windows" / "I am on a Mac" / "I am on Linux"),
  each launching its probe with the fewest clicks that OS allows (Windows: a `.bat` that runs the `.ps1` with the
  policy bypass; macOS: a `.command` plus the one Terminal line for a FAT stick; Linux: the shell script); plain-
  language verdicts ("Ubuntu will run on this computer; the WiFi needs one extra driver, the installer adds it");
  never a raw ID list without the sentence that explains it.
- **The Apple silicon message (his ruling 2026-09-15: blunt, and inside the line — facts we can source, opinion
  labelled as ours, no claims about intent, no "only chips").** The probe on an Apple silicon Mac stops and shows:
  *"This is an Apple silicon Mac. Apple publishes no hardware documentation and no drivers for these chips, and
  dropped Boot Camp when it introduced them, so no open-source operating system supports them. The one Linux that
  runs here exists because volunteers spent years reverse-engineering the hardware, and it is still incomplete.
  Ubuntu does not run on this computer, and Polari cannot be installed on it. Nearly every other computer sold today
  runs Ubuntu out of the box. In our view, a computer that will not let you run free software is one you rent, not
  one you own. To run Polari, use one built on open documentation: any PC, or an Intel Mac."*
  Rules for any edit: every factual sentence must stay sourceable (no docs/drivers; Boot Camp dropped; Asahi is
  volunteer reverse engineering and incomplete; Ubuntu runs on nearly every other computer); the opinion stays
  marked "in our view"; never assert Apple's motives; never "the only"; name Apple, never use its logo. A lawyer's
  glance before it goes on the public site.
- D-P2 (scripts first) · D-P3 (one stick) · D-P4 (tokens) · D-P5 (Apple silicon out of scope — now a message, not a
  silence) remain his; the first build starts when he says so.
