# One-command release across the isle - pol's record (started 2026-11-17)

Econ owns the runner (`isle release run|follow|status`, `isle hotfix`, CLI release 88; econ's own plan is
`RELEASE-RUN-PLAN-20261116.md` in econ's hand-over folder). This file is pol's side: what was proved live, the
user's rulings, and the next round. Report states in the four words: source-tested, staged, installed, live-verified.

## Proved

### Run 1, 2026-11-17 - LIVE-VERIFIED (steps only, no publication)
- Packet `release-run-proof-1` (built by pol, checked with `isle release check` on pol and on the core), run id
  `ab96eb080db7...1278a`: one step per device, `hotfix hand-edit-backups`, on isle-core, pol-core and econ-core by
  name, plus two verify URLs.
- The user typed ONE command, on the core: `sudo isle release run <packet>`, one confirmation.
- Core: step done 12:58:32Z (operation `c556e361...`), approval signed (serial 1794920312), run announced.
- Members followed on their own timers with nothing typed there: pol done 13:00:03Z (operation `1c72a1c7...`), econ
  done 13:00:03Z (operation `497772a2...`). About 90 s after the core. The core's wait ended with both "done".
- Checked afterwards on all three: `isle release status` = done, `isle hotfix status` = applied, no
  `*.pre-hotfix-*` file left beside installed CLI files, both verify URLs ok.
- NOT proved by run 1: any publication (runtime images, packages, catalog apps), wait-until-served against the
  replica, `update-apply`, `store-install`, `module-add`, a failed step and its resume, the pkexec entry.
  The next real packet proves those; it must carry at least one publication.

### Before run 1 (by hand, the last hand release)
- CLI release 88 installed on the three machines with four `sudo` commands (2026-11-16/17).
- `isle hotfix apply storage-units` on pol, 2026-11-17T03:44Z: applied, sync proof exit 0, the replica still serves.

## The user's rulings (2026-11-16/17)
1. The main goal is a complete planned update from one command. Proving it live comes before building more.
2. Start from any device, IF a setting allows it: the setting is core-only or any device. (They first accepted
   core-only, "it narrows the security that needs handled", then asked for both behind a setting.)
3. On a device that may not start a run, the tool says so plainly: the run can only be started on the core. That
   warning follows the setting, on the command line and in the Isle App.
4. The storage-units repair is a standard storage operation, not a hot fix: storage devices allocated to the isle
   for a purpose get their own standard verbs.
5. Every later change ships as a release-run packet, never as a hand list of sudo steps.

## Priority order (the user, 2026-11-18)

1. One-command release (the full proof: publication, wait-served, update-apply, store-install, module-add, resume;
   then section A and B).
2. Apt separation (section D, first item).
3. Storage (section C and the storage handoff's fix list).
4. Backups (`pol backup create|restore`; unencrypted, local, on the removable SSD).
5. Operating system overwrite (section E).

The sections below keep their letters; this list is the order of work.

## Next round (one packet, not one release per item) - PLAN, nothing built, for the user's review

### A. Start setting (econ's runner; pol's backend for the intake)
- The setting lives on the core, is changed only on the core by an isle verb, default core-only.
- any-device: a member's `sudo isle release run <packet>` checks the packet, submits it to the core under the
  member's enrollment identity; the core re-verifies and runs what `run` does today. The core alone publishes and
  signs; members keep acting only on the core's signature. The submitting device is recorded in the receipt.
- Cost, stated: with any-device on, root on any enrolled member can deploy to the whole isle.
- Needs an authenticated intake on the core for large files and a root runner there. If the intake is a backend
  door it is pol's islemesh module (a backend release, shipped as a packet).

### B. The warning (CLI now, Isle App with the page)
- Release 88 fault: on a member, without sudo, `isle release run` answers "Type: sudo isle release run ..."; the
  core-only refusal is reached only with sudo. Fix: role and setting are checked before the sudo demand; the
  message names this device and the core.
- Members read the setting from the core (it rides the release notice they already read). It decides the wording
  only; the core's intake enforces it.
- Isle App: the start control on a non-core device is disabled with the same words while the setting is core-only.

### C. Storage devices and units (pol leads storage)
- `isle storage device`: allocate a device to the isle for a named purpose, list (purpose, mount, free space,
  health, datasets and units carried), retire.
- `isle storage units check|apply --dataset <name>`: compare the units on the device with what the CLI renders,
  rewrite, prove the sync starts. Run after every `isle update apply`; a release-run step kind.
- `isle hotfix storage-units` then keeps only the two one-off actions (the symlink, the hand drop-in).
- Roles on partitions (the user, 2026-11-18): partitioning and the assignment of a specific purpose stay central.
  1. A role is assigned to a partition. A partition may be a whole storage device.
  2. One role may be split across several partitions, on one device or on several.
  3. Roles are the ones the user described: where the blob store puts files, the package store for distribution,
     images for distribution, git, and so on.
  So the record is: a partition carries one role; a role owns one or more partitions. The earlier idea of folder
  quotas on one shared filesystem in place of partitions is withdrawn as the main mechanism.
- Proposed, not ruled (pol): how a role uses several partitions. Each dataset or app store lives whole on ONE
  partition of its role, and the plan says which; an app that spreads over several folders by itself (the blob
  store) is given all of them. No pooling of partitions into one filesystem, so losing a disk loses only what the
  plan placed on it. Repartitioning a disk that holds data = move its datasets to another partition of the role
  with the existing migrate and cutover verbs, then partition the empty disk. Nothing is shrunk in place.
- Econ's draft (`STORAGE-ROLES-PROPOSAL-20261117.md` in the hand-over folder on the core; device, volume, role,
  slot) fits ruling 1; it has to change from "one volume, one role, one place" to a role that owns several
  partitions. Still open and the user's to decide: where backups live in that draft (it moves them off the
  removable SSD), and whether the old internal disk may hold primary copies.

### D. Findings to fold in
- FIRST, 2026-11-18: the isle package source can replace a member's operating system libraries. The repository index
  holds 123 isle/polari packages and 1,135 Ubuntu 24.04 packages (the offline bundle's dependencies: libc6, systemd,
  apt, dpkg, docker among them), and the member source line gives it the same priority as Ubuntu's own archive. On
  econ (Ubuntu 22.04) a plain `apt install blender` therefore took 24.04 libraries, upgraded libc6 and removed the
  desktop (2026-11-17 20:22 local; the run never finished). Codex's recovery put the 22.04 packages back and blocked
  the source with a pin at -1; three libraries stayed missing on disk (libatk-bridge2.0-0, libatspi2.0-0, libasound2
  were registered as installed without their files), so the login screen still failed. The core runs 24.04 and pol
  has no isle source line, so neither is exposed today. Owed: (1) the CLI package ships a pin so a member accepts only
  isle-* and polari-* packages from the isle source; (2) Ubuntu packages leave the main index for a per-release
  offline index used only by the offline installer; (3) a check that compares a member's Ubuntu release with the
  release the offline packages were built for.
- The core's device list holds a stale member (last seen 2026-11-06). A packet addressed to "*" would sign it into
  the approval and wait on it until the limit. Needs a verb to retire a device, or "*" limited to recently seen ones.
- Round-88 items still open: the twin door as a store app with a catalog row; the core-only denylist.
- Backend: one-shot twin runs accept only a twin local to the backend (TWIN_DOOR_PLAN, worker 15-2 section).

### E. Operating system overwrite - a separate kind of update (the user's ruling, 2026-11-18) - PLAN, nothing built
Ruling: a full OS overwrite must be offerable as an update, but entirely separate from apt updates, because it goes
by different safety standards and steps. Proposed shape, for review:
- Three things that never share a channel:
  1. Isle packages: the isle apt source carries isle-* and polari-* packages only. Routine, by release-run packet.
  2. Offline dependency set: the Ubuntu packages the offline installer needs, kept per Ubuntu release, read only by
     that installer from files. Never an apt source on a member.
  3. OS overwrite: its own verbs, its own store location, its own approval. No apt source, and never a side effect
     of a package install, an `update-apply` step or a store install.
- Proposed safety steps for an OS overwrite (each a verb, checked before anything is written): the approval names
  the device and the target release; the device's current release and hardware are checked against what the image
  was built for; a backup of the device's isle state exists and was verified; one device at a time, the core never
  together with a member; the device proves itself after the restart before the run reports done; the way back is
  stated before the start.
- The user, 2026-11-18: the OS overwrite uses the same standard approach as the ISO work (Ubuntu with KDE Plasma),
  and compatibility must be ensured. So section E builds on POLARI_ISO_PLAN.md, it does not start a second method:
  - Exists (iso-1, 2026-09-15): `pol iso` verbs, the `iso` backend module, the Ubuntu Server installer with an
    unattended autoinstall and the Plasma desktop as packages (Kubuntu's own installer cannot be scripted), hardware
    compatibility derived from the target kernel's driver table against a device probe, two full installs proven in
    a VM guest. Base decided: 26.04.
  - Missing for an overwrite of a machine that is already in the isle: (1) software compatibility - the isle's
    packages, offline dependency set and images built and checked for the target release; (2) carrying the device's
    isle identity, datasets and app data across the wipe (save, verify, overwrite, restore); (3) delivery without a
    stick (network boot was decided, not built); (4) a real-hardware install, with docker and the isle CLI on the
    image (both were absent in the VM proof).
- Related: uninstall hands back a working Ubuntu (plan only).

