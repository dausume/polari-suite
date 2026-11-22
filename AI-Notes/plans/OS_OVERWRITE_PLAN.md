# Operating-system overwrite - pol's plan (2026-11-22)

**State: plan only. Nothing of this is built, and nothing here was tried on a machine.** Fifth in the user's order
of work (RELEASE_RUN_PLAN.md, "Priority order"), after the one-command release, the apt separation, storage and
backups. It grows out of section E of RELEASE_RUN_PLAN.md, which stays as the short version and points here.

## 1. Rulings this plan is built on (the user)

- 2026-11-18: "we will need to be capable of offering a full OS-Overwrite as an update but that should be entirely
  seperate from apt updates since it goes by different safety standards and steps".
- 2026-11-18, same conversation: the same standard approach as the ISO work ("the same way we were previously
  making iso's to be able to flash Kubuntu"), and "we would need to be capable of ensuring compatibility". So this
  builds on POLARI_ISO_PLAN.md (`pol iso`, the unattended installer, the hardware probe); it is not a second way
  of making an image.
- 2026-11-14: every standard step is a command of `isle` or `pol`, so it can be tested step by step and put into
  the Isle App.
- 2026-11-20: no hard-coded machine names or values; backups are local and never encrypted; a device-backup is
  taken on a release or an update.
- 2026-11-22: two operating systems, not more: "We do not want to be keeping tons of them in storage, we just
  wanted 2 to cross-compare. A semi-older one that still works for people who might have lsightly older
  laptops/desktops, and then the most up to dat". Today that is what the three machines run: 22.04 on the two
  members, 24.04 on the core. An overwrite is therefore not a way to bring every machine onto one release.
- The safety steps in section 4 are pol's proposal. The user has not confirmed them.

## 2. What an overwrite is

The operating system of a machine that is already in the isle is replaced by an image built with `pol iso`, and
the machine comes back as the same isle device with its data. It is not an upgrade in place (`do-release-upgrade`
is not used: that is the apt channel changing the operating system, which the ruling rules out). The system
partition is written anew; what the device is and what it holds is carried across in a device-backup.

There is no undo. The way back is a second overwrite, to the earlier release, from the same device-backup.

## 3. What exists, and what is missing

Exists (reused, not rebuilt):
- `pol iso`: `kit`, `probe`, `probes`, `bases`, `fetch-base`, `preview`, `build`, `status`, `fetch`, `ventoy`,
  `keys`, `forget`, `ssh`. The unattended installer (Ubuntu Server installer with an answer file, the desktop as
  packages), hardware compatibility derived from the target kernel's driver table against a probe of the device.
  Two installs in a VM were shown in September; Docker and the isle CLI were not on that image.
- `isle backup plan | create | list | verify | restore --drill | restore --apply` (BACKUP_PLAN.md). All
  source-tested; `create` and the drill have not run on a real machine yet, `--apply` neither.
- `isle release run`: a packet with an expected run id, steps per device, a receipt, one device at a time.
- `isle-cli/apt/supported-os.json`: which Ubuntu releases the isle runs on, as core and as member, and how far
  each is proven. Today: 24.04 (core live-verified, member source-tested) and 22.04 (member live-verified).
- The dependency set per Ubuntu release (the offline installer's Ubuntu packages) and the runtime images in a
  release packet.
- `isle storage partition list`: which partition of a machine has which roles.

Missing, each a piece of work of its own:
1. **Putting the isle's own two folders back.** They hold what the device is (its name, keys, the trust of the
   isle's certificate authority, the agent's credentials) and what it has installed. `restore --apply` refuses
   them today because on a live machine every isle service would have to stop. After an overwrite it is the easy
   case: nothing of the isle runs yet. So this is built as a first-boot mode, not as a change to a live machine.
2. **Putting an instance's data back when the instance was just deployed anew.** `--apply` asks that the instance
   is deployed and uses the volume the device-backup names. After an overwrite that is true only once a release
   run has deployed it again. The order in section 5 does it that way; it needs a proof, not new code.
3. **What a device-backup does not hold.** It holds the two isle folders and the data volume of every Polari
   instance. It does not hold: every other named Docker volume (it lists them as not covered), the databases
   and stores BACKUP_PLAN.md names as not built (MariaDB, Keycloak's database, the forge, Odoo, the file store),
   home folders, and anything a person installed by hand. On pol, looked at on 2026-11-22: the home folders and
   Docker's folder are on the system partition. An overwrite there takes all of it.
4. **The device-backup has to survive.** It lives on the machine's `backup` partition or, where none is recorded,
   in the state folder - which is on the system partition. A copy on another machine does not exist: the fetch
   by the core (the user, 2026-11-20: "Core fetching") is not built.
5. **An installer that writes only the system partition.** The answer file today lays out a whole disk. For a
   machine with data partitions on the same disk it has to name the partitions it writes and leave the rest.
6. **Software for the target release.** The isle's packages, the dependency set and the images have to be built
   and shown to work on the target. For 24.04 this exists. For 26.04 (the base the ISO plan decided on) nothing
   exists: no dependency set, no record in `supported-os.json`, no install of the isle on it.
7. **Delivery.** A stick exists (`pol iso ventoy`, `pol apps usb write`). Network boot was decided in September
   and is not built. Without it a person is at the machine, so this kind of update is not "one command from any
   device" yet.
8. **A real machine.** No install on real hardware has been done, and none with Docker and the isle CLI on the
   image.
9. **Where the record of the run lives.** A journaled operation on the device does not survive the wipe. The
   record has to be on the core (the run's receipt) and on a partition that is kept.

## 4. Safety steps (proposal; each is checked before anything is written)

1. **The approval names the plan.** `isle os plan` prints a plan id: a hash over the device, its system now, the
   target, the image's sha256, the partitions that would be written, the device-backup it relies on, and the list
   of what would be lost. The overwrite takes `--expect <plan id>`, as a release run does. If any of those change,
   the id changes and the approval no longer fits.
2. **The image fits the device.** Built for the target, its sha256 re-read; the probe of this device against the
   target kernel says it runs; the boot mode (UEFI or BIOS) matches.
3. **The software fits the target.** `supported-os.json` says the target is live-verified for what this device is
   (core or member); the core publishes the dependency set of the target; the isle's packages and runtime images
   for the target are in a packet that the core read as valid.
4. **The device-backup.** Complete, verified, drilled with the CLI version the machine runs, taken after the last
   change to the device, and on a disk the overwrite does not write. Proposed in addition: a second copy on
   another machine (needs the fetch of point 4 above).
5. **What would be lost is listed and is part of the approval.** Every Docker volume not covered, every home
   folder with its size, every package that is not Ubuntu's or the isle's. A machine whose home folders are on a
   partition that would be written is refused, unless a named option says they are given up.
6. **Only the system partition is written.** Every partition with a recorded role is kept. A partition that is
   both is a refusal: that machine needs a second partition or disk first.
7. **One device at a time. Never the core together with a member.** Never a device that holds something another
   device needs right then (the registry, the only copy of another device's backup) without the plan saying so.
8. **The way back is real before the start.** The image of the release the device runs now exists and was
   re-read, and its dependency set is published. Otherwise the plan says: there is no way back.
9. **The device proves itself.** After the restart: the isle CLI answers, the agent is connected to the core with
   the identity it had, every instance answers and its tables are those of the drill, the roles of its partitions
   are recorded again. Only then does the run on the core say done. After a time limit it says "not back" and
   what a person does at the machine.

## 5. The order of one overwrite, as verbs (names proposed)

    isle os plan --to <system id> [--json]     on the device, read-only: everything of section 4, and the plan id
    sudo isle os prepare --expect <plan id>    device-backup, drill, a copy of it and of the packet onto a kept
                                               partition (and to another machine); writes the approval record;
                                               changes nothing of the system
    pol iso build --device <name> --plan <plan id>   on the core: the installer for this device, its answer file
                                               naming only the partitions of the plan
    (the machine starts from the installer: a stick, later the network)
    sudo isle os finish                        first boot: finds the kept partition, installs the isle from the
                                               dependency set and the packet, puts the two isle folders back
                                               (nothing of the isle runs yet), starts the agent
    sudo isle release run <packet> --expect <run id>   on the core, for this device: deploys its instances again
    sudo isle backup restore <id> --apply --yes        on the device: the data of its instances
    isle os status [--json]                    where a device is in this; on the core: every device

Owners, by the user's ruling R8 (the isle links to hardware, Polari is aware of it): the image is `pol iso`'s; the
plan, the preparation and the first boot are the isle CLI's; the Isle App shows the plan and the status.

## 6. Steps of work

| step | what | proof |
|---|---|---|
| ov-0 | this plan; the user's answers to section 7 | - |
| ov-1 | `isle os plan`, read-only | on each of the three machines it says truthfully what would be written, kept and lost |
| ov-2 | the two isle folders put back at first boot; an instance's data put back after a fresh deploy | on a made-up machine in a test; then in a VM |
| ov-3 | the installer writes only named partitions; Docker, the isle CLI and the dependency set on the image | a VM with two virtual disks: one written, one kept and still whole |
| ov-4 | the core fetches a device-backup (the second copy) | a copy on the core, re-read against its record |
| ov-5 | the first real overwrite: one member, by stick, the user at the machine | the member is back with its identity and its data |
| ov-6 | network boot from the core | the same without a person at the machine |
| ov-7 | the core itself | - (not planned further yet) |

ov-1 changes nothing on any machine and could be built first. ov-2 to ov-4 are built and shown without a real
machine. ov-5 is the first step that can lose something; it needs the user's go and the user at the machine.

## 7. Questions for the user (pol's recommendation first)

1. **The first target.** pol's first recommendation here (24.04 for the two members that run 22.04) is withdrawn:
   it would have left one release, and the user wants two (section 1, 2026-11-22). Open instead: which release is
   "the most up to date" of the pair. 24.04 is what the core runs and everything of the isle exists for it; 26.04
   is the newest Ubuntu and the base the ISO plan chose, and nothing of the isle exists for it. Recommendation:
   the pair stays 22.04 and 24.04 for now, no machine is overwritten for the sake of its release, and the pair
   moves on as a whole later (26.04 comes in, 22.04 goes out, never three kept). The first real overwrite is then
   the first machine that moves to 26.04.
2. **The first delivery.** Recommendation: a stick, with you at the machine. It exists. Network boot (ov-6) after
   the first overwrite worked.
3. **Home folders and everything that is not the isle's.** Recommendation: the isle does not carry them across.
   The plan lists them with their sizes, the plan id covers the list, and a machine whose home folders would be
   written is refused unless a named option says they are given up. pol is such a machine: this suite's working
   copy is in a home folder on its system partition.
4. **A second copy of the device-backup on another machine before an overwrite.** Recommendation: required. It
   means the core's fetch (ov-4) comes before the first real overwrite.
5. **The core.** Recommendation: not in the first build. It holds the certificate authority, the apt source and
   the published releases; its overwrite needs a plan of its own.
6. **Are the nine safety steps of section 4 the ones you want?** They are the proposal of 2026-11-18 with four
   added (the plan id, the list of what is lost, only the system partition, the way back checked before the
   start).
