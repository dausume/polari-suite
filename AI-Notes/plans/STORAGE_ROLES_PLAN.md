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

## 6. Where the disks stand (pol, 2026-11-18)

| Disk | Class | Today | First assignment proposed |
|---|---|---|---|
| 119 GB SSD | fixed | the system disk; Docker's store | none (system disk) |
| 466 GB HDD, 6.3 years powered on | fixed | one filesystem: the package replica (20 GB) and an image archive (8 GB) | whole disk = `package-repo`; the image archive moves to a `distribution` partition |
| 233 GB SSD | dock | one filesystem, empty | whole disk = `backup` (R5) |
| 1.8 TB HDD | dock | four empty partitions of 683 GB, no filesystem; passed a full overwrite test 2026-11-10 | `distribution`, a second `package-repo` partition, `scratch`, one left unassigned |

Nothing here needs a shrink or a move of live data. Where `blob`, `git` and `assets` live is decision 3.

## 7. Decisions for the user

1. Naming. "Role" now means the purpose of a partition. The ruling of 2026-11-12 used "disk roles: core,
   removable"; proposed: those become the device class (fixed, dock, flash) and "role" keeps one meaning.
2. Section 3: each dataset whole on one partition and no pooling (recommended), or partitions pooled into one
   larger space per role.
3. The home of primary copies (`blob`, `git`, `assets`). Econ's draft puts them on pol's old internal disk. Pol's
   caution, not a ruling: that disk is old and single; a primary there should have a verified second copy from
   the first write. Alternatives: the core's internal disk, or a new disk.
4. Econ's draft adds a second backup copy on the core's disk. R5 keeps the removable SSD as the home; say whether
   the second copy is wanted as an addition.
5. The 2 TB disk: the first assignment in section 6, or retire it.
6. Docker's store as a role. It is the largest consumer on all three machines and what filled pol's system disk;
   the migration handoff of 2026-11-09 said never to move it. Leave it out, or plan it as a late step.
7. From econ's draft: design files through the forge with large-file storage; "images for distribution" as two
   roles (`registry` for container images, `distribution` for operating-system images).
