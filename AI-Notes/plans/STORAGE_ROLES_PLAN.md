# Storage roles on partitions - pol's plan (revamped 2026-11-18)

PLAN ONLY, nothing built. Pol leads storage. Third in the user's order of work (RELEASE_RUN_PLAN.md, "Priority
order"): after the one-command release proof and the apt separation. Replaces section C of that plan as the home
of the storage design. Builds on what exists (one read-only dataset, `apt-public-repo`, placed on pol by the
plan door, with a fail-closed gate unit) and on econ's draft of 2026-11-17 (in the hand-over folder on the core).

## 1. Rulings this plan is built on

| # | Ruling (the user) | Date |
|---|---|---|
| R1 | A role is assigned to a partition. A partition may be a whole storage device. | 2026-11-18 |
| R2 | One role may be split across several partitions. | 2026-11-18 |
| R3 | Partitioning and the assignment of a specific purpose stay central. No softer substitute. | 2026-11-18 |
| R4 | Storage devices allocated to the isle for a purpose get standard verbs: `isle storage device`, `isle storage units check\|apply`. | 2026-11-16 |
| R5 | Backups are never encrypted, local only, on the removable SSD. A removable disk is in `backup` or `export` mode. | 2026-11-12 |
| R6 | The denylist of what may never be moved holds only the core itself. | 2026-11-14 |
| R7 | Every step is an `isle` or `pol` verb; a plan is approved once and then runs. | 2026-11-14 |
| R8 | The isle is responsible for storage, because storage is tied to hardware. Polari only has to be aware of it, since planning goes through Polari as well as the isle. | 2026-11-20 |

Reported by econ from its own session with the user (2026-11-17), not said to pol: purposes named were where the
blob store puts files, the package store for distribution, images for distribution, git; SATA is the standard and
ordinary USB flash drives must also work; a dedicated page manages it and shows how storage maps to the
storage-heavy apps; the reason is design files (Blender, FreeCAD) that cannot live on GitHub without paying.

## 2. The model

| Thing | What it is | Identified by | Rule |
|---|---|---|---|
| Device | one physical disk or stick | hardware serial | has a declared class: fixed, dock or flash |
| Partition | one filesystem; may cover the whole device | filesystem identifier, plus a marker file at its root | carries exactly ONE role; its size is the hard limit |
| Role | a purpose | a word from a fixed list | owns ONE OR MORE partitions, on one device or several, on one machine or several |
| Dataset or store | one named body of data of one role | its name | placed by the plan on a partition of its role |
| Slot | one storage need of one app | app name + slot name | declared in the app's release manifest; the plan binds it |

Roles (first list): `package-repo`, `distribution` (install and operating-system images, large release files),
`registry` (container images), `blob`, `git`, `assets` (design files), `backup`, `scratch`, `transfer`.

## 3. How a role uses several partitions (PROPOSED, not ruled)

- Each dataset or app store lives whole on one partition of its role. The plan names the partition.
- An app that spreads over several folders by itself (the blob store does) is given every partition of its role.
- Partitions are never pooled into one filesystem. Losing a disk then loses only what the plan placed on it, and
  only the gates of those datasets close.
- A role grows by adding a partition to it. A dataset moves between two partitions of its role with the verbs
  that exist today (authorize, migrate, cutover, witness, accept).
- A disk that holds data is repartitioned by moving its datasets away first, then partitioning the empty disk.
  Nothing is shrunk in place.
- A second copy of a dataset is a placement on another partition of the same role on a different device.

## 4. Verbs

    isle storage device    list | register | health | retire
    isle storage partition list | create | assign | check | retire
    isle storage role      list | show <role>
    isle storage slot      list | bind
    isle storage units     check | apply --dataset <name>
    (existing) isle storage authorize | migrate | cutover | witness | accept | rollback | sync | status
    pol backup create | restore      writes to and reads from partitions with the role `backup`

- `partition assign` adopts an existing filesystem: writes the marker and the record, moves no data.
- `partition create` erases. It runs only from an approved plan that names the device serial, the size and the
  role; it refuses the machine's system disk, a partition that carries a dataset, and a device that is not
  registered.
- Records: on the machine, a device list and the marker at each partition root (one scheme: the dataset's
  existing on-disk binding file is kept inside it, not beside it). On the core, the placement record gains
  partitions and roles, and the plan gains partition items.
- `isle storage backup` from econ's draft is not taken: the storage layer owns the partition with the role
  `backup` and its health; the app-consistent export and the restore stay `pol backup` (the split of 2026-11-12).

## 5. Steps (each ships as a release-run packet)

| Step | What | Proof |
|---|---|---|
| st-0 | The decisions in section 7 | the user's words |
| st-1 | Records and read-only verbs; register the disks; `partition assign` for what exists. No data moves. | `isle storage role show package-repo` lists pol's partition and the dataset on it |
| st-2 | `units check\|apply`; the open items of the phase A fix list (retire-source on the core, core-only denylist, sync proof at cutover) | units match after an `isle update apply` with no hand edit |
| st-3 | `partition create` on a disk with nothing to lose (the 2 TB disk), a second partition for one role, one dataset moved between two partitions of its role | R2 shown live |
| st-4 | Slots with writable binds behind the same gate; the first role an app writes to live | an app stops cleanly when its partition is absent, starts when it returns |
| st-5 | Backups (fourth in the order of work) write to the role `backup` | one restore actually performed |
| st-6 | Isle App storage page: read-only first, then the verbs as actions | the page shows devices, partitions with roles, apps with slots, protection |

Done ahead of st-2 (2026-11-20), the core-only denylist: source-tested, on the isle CLI's dev, in no release. `authorize`
no longer reads a list of movable names. It refuses one name, the core itself, and moves any other name whose source
device owns it. Pol's reading of "the core itself" (not ruled): the address the members reach the core at,
`api.polari.isle`, because the isle's own configuration calls that address the core (`ISLE_CORE_API`). No other name is
protected: not the CA, not the router, not `polari.isle`. The old file `/etc/isle-mesh/storage/hostable-names` on the
core is not read any more once the core runs this CLI; removing it is a job for `units apply`, not a hand step.

### Done ahead of st-0 (2026-11-18): the two listings that need no decision

Source-tested on pol, not committed, not in release 89, not installed anywhere.

- `isle storage device list [--table]` - every disk of this machine by hardware serial: model, size, medium
  (rotational, solid-state, nvme), bus, hotplug, whether it carries the running system, partition count. A
  disk without a serial is reported as one that cannot be told from another.
- `isle storage partition list [--table]` - every partition (and a whole disk with a filesystem on it): its
  disk and that disk's serial, filesystem and filesystem identifier, state (mounted, not mounted, no filesystem
  reported, not a plain filesystem), mount, free space, whether it carries the running system, and the datasets
  bound on it today (from the copies under `/var/lib/isle-mesh/storage`).
- Read-only, no sudo. They report what the machine says; nothing is registered. Roles and the declared class
  are not printed until the records exist (decisions 1 and 2), and the verbs `register`, `health`, `retire`,
  `create`, `assign`, `check` answer "not in this CLI" rather than doing anything.
- Files: `isle-cli/scripts/storage_devices.py`, `test-storage-devices.py` (14 tests, fixtures only), one line in
  `storage.sh`. `isle storage list` is unchanged.
- On pol they show what section 6 says: the four partitions of the 2 TB disk report no filesystem.

The units verbs of R4 (first half of st-2), same state: source-tested on pol, not committed, not installed.

- `isle storage units check [--dataset D]` - read-only, no sudo. For each dataset bound on this machine: the
  gate unit, the sync service and the sync timer against the text the installed CLI writes today (matches,
  differs, missing, a link); drop-in overrides; enabled or not. Exit 1 when anything is off. Whether the gate
  is running is reported and does not decide the result.
- `sudo isle storage units apply --dataset D [--overrides keep|remove]` - rewrites what does not match, reloads
  systemd, enables the gate and the timer. It never starts, stops or restarts the host; a rewritten gate unit
  is used from its next start. Overrides stay unless `--overrides remove` is given. It runs as a journaled
  operation under the dataset lock, as `units-apply` (one new row in the contract's table of verbs, section 2.1).
- Files: `isle-cli/scripts/storage_units.py`, `test-storage-units.py` (23 tests; 11 of 12 deliberate breaks
  caught, the twelfth is a doubled guard), `storage.sh`, `storage_contract.py`,
  `docs/STORAGE-MIGRATION-CONTRACT.md`.
- Read on pol today with the new code: all three units of `apt-public-repo` match, no overrides, enabled.
  `apply` has not been run anywhere (it needs sudo).
- Open, for st-2: nothing calls `units apply` after an update yet. Two ways: the package's install script runs
  it for every bound dataset, or it is a step kind of the release run. Not chosen.
- Fixed on the way: `test-storage-receive.py` asked the core for the placement view and read this machine's
  own operation journal, so it failed on a device that hosts the dataset. It now reaches neither.

## 6. Where the disks stand (pol, 2026-11-18)

| Disk | Class | Today | First assignment proposed |
|---|---|---|---|
| 119 GB SSD | fixed | the system disk; Docker's store | none (system disk) |
| 466 GB HDD, 6.3 years powered on | fixed | one filesystem: the package replica (20 GB) and an image archive (8 GB) | whole disk = `package-repo`; the image archive moves to a `distribution` partition |
| 233 GB SSD | dock | one filesystem, empty | whole disk = `backup` (R5) |
| 1.8 TB HDD | dock | four empty partitions of 683 GB, no filesystem; passed a full overwrite test 2026-11-10 | `distribution`, a second `package-repo` partition, `scratch`, one left unassigned |

Nothing here needs a shrink or a move of live data. Where `blob`, `git` and `assets` live is decision 3.

## 7. Decisions - answered by the user, 2026-11-20

"The rest I defer to your decisions" covers 1, 2 and 7; pol's recommendation is taken there.

1. Naming (left to pol): "role" is the purpose of a partition. Fixed, dock and flash are the device class.
2. Several partitions per role (left to pol): each dataset lives whole on one partition; no pooling.
3. Primary copies, ruled (verbatim): "The old internal disk for git, code dependencies, and the like. For rendering
   and CAD assets I think the external 2 TB HDD would be ideal, and for assemblies, since we will not use the
   frequently and they take up a lot of space. They can be loaded into the internal where needed when they are
   actively being used."
   - So: `git` and the dependency stores on pol's internal 466 GB disk; `assets` (renders, CAD, assemblies) on the
     2 TB dock disk; an asset in active use is copied to the internal disk and is not the primary there.
   - Pol's caution stands, not ruled: that internal disk is old and single, so `git` wants a verified second copy.
4. The 233 GB SSD, ruled (verbatim): "rather than a backup copy I more so want that to be used as a way to refresh
   and create a totally new isle from scratch, because part of what I am testing here is my abaility to create
   Isle Templates for people to use, which means easily being able to make new isles with new names and security
   from scratch automatically. And the 250GB SSD is a perfect test case for that since it is large enough to fit
   most plausible Isle use cases for small businesses, it is a good way to proof out what plans are viable for
   cheap sellable pre-formatted Isles. We should be capable of transforming it into a backup as well, but that is
   the main way we are going to be wanting to do updates or installing fresh isles offline is 250 GB SSD via Docks."
   - So the SSD's first purpose is the isle template medium: a fresh isle, new names, new security, set up from
     the SSD with no network, and offline updates. This is mode `export` of R5, now the main mode. It can be
     turned into a backup disk as well. No second backup copy on the core.
   - Open after this answer: where routine device-backups live when the SSD is a template medium (BACKUP_PLAN.md).
5. The 2 TB disk, ruled: "We want to use the 2 TB for miscellaneous storage of assets we do not use frequently."
6. Container images, ruled (verbatim): "I think that may make sense to specify being somewhere specific as well
   like allocating images to live primarily on the HDD since it is not used often and takes up a lot of space
   across the isle, that way we are not duplicating images across each device and make it feasible for each docker
   to ping that for the images as they need them, then get rid of them after creating the container they are
   going to use."
   - So: a role `registry`, one place on the isle that holds the images; a device fetches an image when it needs it.
   - A limit of Docker, to be said to the user before this is built: a container is stored as a thin layer on top
     of its image, so the image cannot be removed while the container exists. What a device can drop is every
     image no container uses (old versions, apps not installed there). That is where the space went on pol.
   - Open: which HDD. A registry must be reachable whenever a device needs an image, and a dock disk can be unplugged.
7. From econ's draft (left to pol): yes to both. Design files go through the forge with large-file storage;
   `registry` (container images) and `distribution` (operating-system images) are two roles.

## 8. File spaces (the user, 2026-11-20) - PLAN, nothing built

Verbatim: "I think we should also have generalized isle-partitions and app-specific file-spaces linked to both an
app and an isle. Like kicad and freecad having defined partitions of file spaces specific to them that are
accessible by the isle as a volume. We will want to implement functionality like with OneCloud (maybe integrate
onecloud to enable this? or whatever the open source solution was?) or if we can leverage our existing file-store
system with a simpler equivalent that would be good as well. But the goal would be to be able to centralize
storage of the isle in certain places so that such files can be accessible both to the apps for manipulation and
to the isle itself for simulation purposes, while being distributed throughout the isle."

- The requirement: a file space belongs to one app and to the isle; it is stored in a named place (a partition
  with a role); the app opens it as ordinary files; the isle's own services (simulation) read the same files;
  every device of the isle can reach it.
- What exists: the suite's file store (SeaweedFS, `polari-rf-node/prf-file-store`), already the engine's place
  for bytes, with buckets per app and Keycloak-issued temporary keys where sign-in is on.
- Pol's first lean, to be checked before anything is built: one file space = one bucket of that file store, its
  data on a partition of the right role, mounted into the app as a folder. The open-source products of the kind
  the user means are ownCloud and Nextcloud; they add desktop sync and a sharing page, and bring a second
  application with its own database and accounts.
- Owed: a comparison on this isle's terms (how KiCad and FreeCAD open the files, offline behaviour, licence, what a
  second copy costs), then the user's choice.
