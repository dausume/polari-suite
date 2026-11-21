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
| R9 | A partition can have more than one role. | 2026-11-21 |

Reported by econ from its own session with the user (2026-11-17), not said to pol: purposes named were where the
blob store puts files, the package store for distribution, images for distribution, git; SATA is the standard and
ordinary USB flash drives must also work; a dedicated page manages it and shows how storage maps to the
storage-heavy apps; the reason is design files (Blender, FreeCAD) that cannot live on GitHub without paying.

## 2. The model

| Thing | What it is | Identified by | Rule |
|---|---|---|---|
| Device | one physical disk or stick | hardware serial | has a declared class: fixed, dock or flash |
| Partition | one filesystem; may cover the whole device | filesystem identifier, plus a marker file at its root | carries ONE OR MORE roles (R9); its size is the hard limit, shared by all its roles |
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
    isle storage role      list | show <role>      (--isle: every machine's report, side by side)
    isle storage slot      list | bind
    isle storage units     check | apply --dataset <name>
    (existing) isle storage authorize | migrate | cutover | witness | accept | rollback | sync | status
    isle backup plan | create | list | verify | release-hold      writes to the partition with the role `backup` (BACKUP_PLAN.md)

- `partition assign` adopts an existing filesystem: writes the marker and the record, moves no data.
- `partition create` erases. It runs only from an approved plan that names the device serial, the size and the
  role; it refuses the machine's system disk, a partition that carries a dataset, and a device that is not
  registered. As built (2026-11-21, section 5): the plan is the one the verb prints, and the approval is its id
  typed back with sudo. It is stricter than this line: it refuses any partition or device that holds a filesystem
  at all.
- Records: on the machine, a device list and the marker at each partition root (one scheme: the dataset's
  existing on-disk binding file is kept inside it, not beside it). On the core, the placement record gains
  partitions and roles, and the plan gains partition items.
- The split of 2026-11-12 (`pol backup` for the export and the restore) is overtaken by the user's ruling of
  2026-11-20: the isle CLI is responsible for storage, Polari only has to be aware of it. The verbs are
  `isle backup ...`; a running instance is held still through the engine's write gate. Detail: BACKUP_PLAN.md.

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

### st-1 built (2026-11-20): the records of one machine

State: source-tested, on the isle CLI's dev. In no release, installed nowhere, run with sudo nowhere. The proof of
st-1 (the role listing on pol) waits for the next CLI release, because the verbs are not in the installed CLI.

- `sudo isle storage device register <serial> --class fixed|dock|flash` - declares a disk that is present. The
  same class again changes nothing; another class corrects it and says what it was.
- `sudo isle storage partition assign <filesystem-identifier> --role <role>` - adopts a mounted filesystem. It
  writes the marker `isle-partition.json` at the root of the partition and one entry in the machine's record, and
  nothing else: no file is moved, created or erased. The same role again changes nothing, or writes a missing
  marker again. A partition marked on another machine is recorded without rewriting its marker.
- `isle storage partition check [--table]` - read-only. Record against marker for each recorded partition; exit 1
  when one needs attention. A partition of a dock or flash device that is away is reported and is not an error; one
  of a fixed device that is away is.
- `isle storage role list [--table]`, `isle storage role show <role> [--table]` - read-only. The partitions of a
  role with device serial, class, size, free space and the datasets bound on them.
- `device list` and `partition list` now print the recorded class and role.
- Refused with nothing written: a device that is not registered or has no serial; a second role (taking one away is
  `partition retire`, built 2026-11-21, below); two partitions with one identifier; a marker that names another filesystem (a
  block copy); a file of the marker's name that is not a marker; a filesystem not mounted whole where it can be
  reached. A link at the marker's name is never followed. A damaged record stops every verb.
- Records: `/etc/isle-mesh/storage/device-records.json` on the machine (devices by serial, partitions by filesystem
  identifier, so a partition that is away is still known) and the marker on the partition. One more than section 4
  said ("a device list and the marker"): the record also lists the partitions.
- Files: `isle-cli/scripts/storage_roles.py`, `test-storage-roles.py` (34 tests, made-up reports and temporary
  folders only), `storage_devices.py`, `storage.sh`, the CLI's README.
- Read on pol with the new code, without sudo: the listings work on the real disks, no role is recorded, `assign`
  refuses because the disk is not registered, `register` prints the sudo command. Nothing was written.

Pol's choices in this step, not ruled, for the user to correct:
1. `assign` refuses a partition that carries the running system (`/`, `/boot`, `/home`, `/var` ...). One line to lift.
2. These verbs are not journaled operations. They hold their own lock on the record. The journal is built around
   one dataset per operation, and these verbs have none.
3. A dock that reports its own serial instead of the disk's is not detected. Two disks with one serial are refused.
   A partition found behind another serial is shown as `on another device`, and `assign` with its role records it
   where it is.

Not in st-1, still owed: the core's placement record does not hold partitions or roles yet, and no verb reads a
role to place data. The isle-wide view is built as a report (next paragraph).

#### The isle-wide view, built 2026-11-20 evening (source-tested, on the isle CLI's dev, in no release)

- `isle storage role list --isle [--table]` and `isle storage role show <role> --isle [--table]` - read-only, from
  any machine. They print what every machine reported, side by side: device, role, filesystem identifier, class,
  size, free space, state, datasets, and how long ago that machine reported.
- How it gets there: each machine adds its partitions that carry a role to the device report it already sends to
  the core (one more fact, `isle.storage_partitions`). The view reads the core's device list. No backend change,
  no hand-made route, no second store. The hardware serial is not reported.
- R8 ("Polari just needs to be capable of being aware of it"): the report sits in the engine's device rows
  (`IsleDevice`), which is where Polari reads devices from. A Polari page or plan that uses it is not built.
- It is a report, not a check. A machine with an older isle CLI shows as "no storage report yet". Read once from the
  source tree against the real device list: no machine reports yet, because no installed CLI carries this.
- Pol's choices, for the user to correct: the report is not an engine row class of its own (`IsleStoragePartition`
  would be the next step if plans need to point at one partition); the serial stays on the machine.
- Files: `storage_isle.py` (new), `test-storage-isle.py` (new, 16 tests, 21 of 21 deliberate breaks caught),
  `capabilities.py`, `storage_roles.py`, `storage.sh`, the CLI's README.

What the user types, on any machine, once a release carries this and the roles are assigned:

    isle storage role list --isle --table

What the user types on pol once a release carries this (serial and identifier as the two listings print them):

    isle storage device list --table
    sudo isle storage device register <serial of the 466 GB disk> --class fixed
    isle storage partition list --table
    sudo isle storage partition assign <identifier of its filesystem> --role package-repo
    isle storage role show package-repo --table

A conflict to settle before `git` is placed (decision 3): the internal 466 GB disk is one filesystem, and a
partition carries one role. It holds the package replica today, so it becomes `package-repo`. `git` on the same disk
needs a second partition, and nothing is shrunk in place (section 3): the package replica would move away, the disk
be partitioned, and the replica move back. The other way is to let one partition carry more than one role, which
changes the model. Not chosen.

Settled by R9 (2026-11-21): a partition can have more than one role, so `git` and `backup` are added to that
filesystem beside `package-repo`. No second partition, no move. See the next heading.

#### Several roles on one partition (R9), built 2026-11-21 (source-tested, on the isle CLI's dev, in no release)

- `sudo isle storage partition assign <filesystem-identifier> --role <role>[,<role>...]`. On a partition that
  already carries roles it keeps them and adds the ones typed. It never takes a role away. The same roles again
  change nothing.
- What is written: with one role the marker and the record hold `role`, as before. With more they hold `roles`
  (all of them, in the order given) and `role` (the first). A CLI of release 90 therefore still reads a role it
  knows from a record or marker written by a later one.
- The marker and the record agree when they name the same roles, in any order. When they differ (the disk was
  given a role on another machine), `assign` joins them only when every one of those roles is typed, and it
  prints the command that does it. No role is taken over unasked. This is pol's choice, not ruled.
- A marker that is changed keeps who wrote it first and gains `changedAt` and `changedOn`.
- Refused with nothing written, new: a role typed twice; a role that has to be written to the marker of a
  filesystem mounted read-only; a marker or a record that changed while the command ran.
- The listings: `partition list`, `partition check` and `role show` print a `ROLES` column. A partition with
  several roles is listed under each of them. `role list` counts its free space under each role and says that it
  is one space: the roles share the partition, nothing is set aside for each. A limit per role is not built.
- The isle-wide report (`isle.storage_partitions`) keeps its shape: one row per partition and role. A core of
  release 90 reads it as it is.
- Device-backups: the home is the partition whose roles include `backup`, whatever else it carries.
- Files: `storage_roles.py`, `storage_isle.py`, `storage_devices.py`, `device_backup.py`, their four test files
  (46, 18, 14 and 33 tests; 21 of 21 deliberate breaks caught after one test was added), the CLI's README.
- Limits: the Isle App does not show roles yet. Taking a role away is `partition retire` (next heading).

What the user types on pol once release 91 is live there (the identifier as `partition list` prints it):

    sudo isle storage partition assign <identifier of the 466 GB filesystem> --role package-repo,git,backup

#### Taking a role or a device away again, built 2026-11-21 (source-tested, isle CLI dev `444565e`, for release 92)

In no release and installed nowhere. Release 91 does not have these two verbs.

- `sudo isle storage partition retire <filesystem-identifier> --role <role>[,<role>...] [--record-only] [--leave-data]`
  - Afterwards neither the marker nor this machine's record names the roles typed. A role that is not typed stays,
    in the marker and in the record. With no role left the record entry is dropped and the marker file is removed.
  - It erases, formats, unmounts and moves nothing. The marker is the only file it ever removes.
  - `--record-only`: changes the record and never looks at the marker. For a disk that is away or gone for good,
    not mounted whole, mounted read-only, with a marker that cannot be read, or a block copy. Without the option
    each of those is a refusal that names it and prints the command.
  - `--leave-data`: needed in two cases, refused without it. One: the role `backup` is taken from the partition
    that holds this machine's device-backups (after that `isle backup` keeps new ones in the state folder and no
    longer lists those). Two: the last role is taken from a partition a dataset is bound on.
  - Pol's choices, not ruled: both options, and that these two cases need the second one. They are refusals with a
    named way through, not things that are forbidden.
- `sudo isle storage device retire <serial>`: takes a device out of the record. It does not look at the disk, so a
  disk that is gone can be retired. Refused while the record holds a partition with a role on it; the refusal
  prints the `partition retire` command for each.
- Files: `storage_retire.py` (new, 180 lines), `test-storage-retire.py` (30 tests, fixtures only), the dispatch in
  `storage_roles.py`, `storage_devices.py`, `storage.sh`, the CLI's README.
- Proof: 30 new tests; 51 of 51 deliberate breaks caught (5 were missed at first: 2 by tests that were too loose,
  1 by a missing case, 1 was a doubled condition that is now removed, 1 was aimed at the wrong test file).
  Read-only run on pol with the real disks: `partition check` answers as before, the refusals and the usage print.
  Not run with sudo anywhere.
- `partition create` is built since: see the block after the next one.

#### The disk's own health report, built 2026-11-21 (source-tested, isle CLI dev `52a41dd`, for release 92)

In no release and installed nowhere. Release 91 does not have this verb.

- `sudo isle storage device health <serial> [--table]`
  - Asks the disk for its health report with `smartctl` (identity, verdict, attributes). A disk behind a USB bridge
    that gives no answer is asked a second time the way such bridges need.
  - Says the disk's own verdict (passed or failed), what needs attention (reallocated, pending or uncorrectable
    sectors and the like) and the power-on hours.
  - For a registered device it keeps the reading under the device in this machine's record: when it was read, the
    verdict, what needs attention, the power-on hours. For a device that is not registered it prints and keeps
    nothing.
  - Exit 0 only when the disk passed and nothing needs attention.
  - It needs root, because the disk answers only root.
- `device register` now keeps everything else recorded for a device when its class is changed, so a kept reading
  outlives a change of class.
- Limits, said plainly:
  - It needs `smartctl` (package `smartmontools`). Pol and the core have it; econ does not. The package is not in the
    offline package list, and adding it changes what the dependency sets hold (a rebuild, which downloads). Not
    added; that is the user's call. Where the tool is absent the verb refuses and names the package.
  - It has never run as root, so it has not read a real disk's report. The answers it was tested on are made-up
    ones in the shape `smartctl --json` gives.
  - `device list` does not show the kept reading yet, and the reading is not in what a machine reports to the core.
- Files: `storage_health.py` (new, 145 lines), `test-storage-health.py` (21 tests, fixtures only), the dispatch in
  `storage_roles.py`, `storage_devices.py`, `storage.sh`, the CLI's README.
- Proof: 21 new tests; 58 of 58 deliberate breaks caught (4 were missed at first and each got a test; one was a
  doubled condition, now removed); every test file of the CLI: 91 ok, 1 skipped (it needs the core), 0 failed.

#### Making a partition, built 2026-11-21 (source-tested, isle CLI dev `3148013`, for release 92)

In no release and installed nowhere. Release 91 does not have this verb. It has never run with root and never on a
real disk. This is the one storage verb that erases.

- Three forms:
  - `isle storage partition create <serial>`: says what the device holds and which of the two ways below fits.
  - `isle storage partition create <serial> --partition <partition-identifier> --role <role>[,<role>...] [--label <label>]`:
    a filesystem on one partition of the device that has none. The partition is named by its partition identifier
    (the one in the partition table), because a partition with no filesystem has no filesystem identifier yet.
  - `isle storage partition create <serial> --whole --role <role>[,<role>...] [--label <label>]`: for a device with
    no partition table and no filesystem, which is what pol's 1.8 TB disk is (section 6). It gets a GPT partition
    table with one partition over the whole device, then the filesystem.
- Two steps, and only the second writes:
  - Without `--expect` it reads the machine and prints the plan (what is made, what is lost), a plan id, and the
    command to type.
  - With `sudo` and `--expect <plan-id>` it reads the machine again under the storage lock and goes on only when
    the plan is still the same one. The id covers the device's serial, model, size and class, the layout (and
    for `--whole` the sizes of what the system shows under the device), the roles and the label.
- What it makes: one ext4 filesystem with 1% kept in reserve, a filesystem identifier the verb chooses, the marker
  of the roles at its root from the first moment (one `mkfs.ext4` call makes both), and the entry in this machine's
  record. It does not mount.
- What guards the data:
  - It asks the disk itself (`blkid --probe`), not only the system's report: at the device and at everything the
    system shows under it (`--whole`), and at the partition just before the filesystem is made. Anything
    recognised there stops it.
  - The partition table is written by `sfdisk` after a rehearsal that writes nothing, with wiping switched off.
    A filesystem from before that begins where the new partition begins therefore stays readable, and the verb
    stops on it instead of overwriting it.
  - There is no option to force anything.
- It refuses, and writes nothing, when: the device is not registered, is away, carries the running system or is
  read-only; two devices report the serial; the target holds a filesystem, has something stacked on it, is in use
  or is read-only; with `--whole` the device has a partition table; two partitions report the partition
  identifier; a role is typed twice; the label does not fit; one of the three tools is missing; the plan id is
  not the one of the plan as it reads now.
- After the first write a failure is not "nothing was changed". The verb prints `FAILED:` and says what the device
  holds at that point:
  - the table write had started: the device may hold a part of a table;
  - the table is written and the new partition is not shown yet, or shows something from before: it prints the
    `--partition` command that goes on from there;
  - the filesystem had started: what was on the partition is lost and it may hold a part of a filesystem;
  - the filesystem is made and the record could not be written: it prints the `partition assign` command.
- Pol's choices, not ruled:
  - ext4, 1% reserve, GPT.
  - `--whole` makes one partition over the whole device and nothing else. There is no size option, no second
    partition, and no adding a partition to a table that is there. So "a second partition for one role" in st-3
    cannot be done with this yet.
  - The approval is the plan id typed back with sudo on the machine itself. It does not go through the core's plan
    door (fix list item 8 is still open).
- Tools: `sfdisk` (package `fdisk`), `blkid` (`util-linux`), `mkfs.ext4` (`e2fsprogs`). All three machines have
  them. The offline package list names none of them, and nothing was added to it.
- Files: `storage_create.py` (new, 345 lines), `storage_table.py` (new, 56 lines), `test-storage-create.py`
  (39 tests), the dispatch in `storage_roles.py`, `storage_devices.py` (the listing now asks for the kind of
  partition table), `storage.sh`, the CLI's README.
- Proof: 39 new tests. 5 of them run the real `sfdisk`, `blkid` and `mkfs.ext4` on 64 MiB image files in a
  temporary folder, never on a device: the table is written with the chosen partition identifier, the filesystem
  reads back with the chosen identifier and the marker at its root, and an old filesystem inside the new partition
  is still seen after the table is written. 113 of 113 deliberate breaks caught. Every test file of the CLI:
  92 ok, 1 skipped (it needs the core), 0 failed. Read-only run on pol with the real disks: the 1.8 TB disk reads as a bare device, and with a made-up
  record in a temporary folder the plan for `--whole --role registry,assets` prints correctly.
- Not proven: a real device. How the system re-reads a table and shows the new partition is tested with fixtures
  only; on image files there is no device for the system to show.
- For the user on pol, once release 92 is installed there (the serial is from `isle storage device list --table`):

      sudo isle storage device register <serial of the 1.8 TB disk> --class dock

      isle storage partition create <serial of the 1.8 TB disk> --whole --role registry,assets

  The second prints the plan and the `sudo ... --expect <plan-id>` line that does it.

#### Proposed next: `partition mount` (not built; pol's proposal, nothing ruled)

A filesystem made by `partition create` is not mounted, and everything else (the marker check, datasets, the
backup role) needs it mounted whole. Mounting is a hand step today (fix list item 11).

- `isle storage partition mount <filesystem-identifier> --at <folder>`: without sudo it prints what it would
  write; with sudo it makes the folder, writes one systemd mount unit that names the filesystem by its
  identifier, and starts it.
- The unit is wanted by the device, not by the boot: the partition is mounted each time the disk is present, and
  a dock disk that is away does not hold up a start of the machine.
- `--at` is typed every time. No folder name is built into the CLI.
- It refuses a folder that holds anything, a folder something is mounted on, a partition that is mounted
  elsewhere, and the running system's partitions.
- `isle storage partition unmount <filesystem-identifier>` is the way back. It refuses while a dataset on the
  partition is in use.
- It changes a live machine, so the first run is the user's, read from the printed plan.

### Done ahead of st-0 (2026-11-18): the two listings that need no decision

On the isle CLI's dev since 2026-11-20 (source-tested). Not in release 89, not installed anywhere.

- `isle storage device list [--table]` - every disk of this machine by hardware serial: model, size, medium
  (rotational, solid-state, nvme), bus, hotplug, whether it carries the running system, partition count. A
  disk without a serial is reported as one that cannot be told from another.
- `isle storage partition list [--table]` - every partition (and a whole disk with a filesystem on it): its
  disk and that disk's serial, filesystem and filesystem identifier, state (mounted, not mounted, no filesystem
  reported, not a plain filesystem), mount, free space, whether it carries the running system, and the datasets
  bound on it today (from the copies under `/var/lib/isle-mesh/storage`).
- Read-only, no sudo. They report what the machine says; nothing is registered. Since st-1 they also print the
  recorded class and role. (`retire`, `health` and `create` are built since 2026-11-21, see the three blocks
  above.)
- Files: `isle-cli/scripts/storage_devices.py`, `test-storage-devices.py` (14 tests, fixtures only), one line in
  `storage.sh`. `isle storage list` is unchanged.
- On pol they show four partitions on the 2 TB disk that report no filesystem. Corrected 2026-11-21: those four are
  not real partitions, see the correction under the table in section 6.

The units verbs of R4 (first half of st-2), same state: on the isle CLI's dev, source-tested, not installed.

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
- Built 2026-11-20 (source-tested, on the isle CLI's dev, in no release): an update rewrites the unit files whose
  text it changed. It is one step of the reconcile that `sudo isle update apply` and `sudo isle reconcile` run.
  `isle update apply` hands over to the reconcile script of the package it has just installed, so the release
  that carries this step already uses it on every device. That is why it is neither of the two ways named
  before: an install script runs inside the package manager and cannot report well, and a new step kind of the
  release run is usable only one release later and never runs for an update a member takes by timer.
  - What it changes: a unit file that exists and whose text differs from what the installed CLI writes. The
    replaced text is kept in `/var/lib/isle-mesh/storage/<dataset>/units-replaced/<time>/`.
  - What it leaves as found and names in the output: a missing unit, a unit that is not enabled, a link in place
    of a unit file, a hand override. `sudo isle storage units apply --dataset D` stays the verb for those.
  - It enables, starts and restarts nothing. A rewritten unit is used from its next start.
  - It takes the dataset's operation lock and skips a dataset that another storage operation holds.
  - It never fails the update: a fault is one printed line.
  - Pol's choice, not ruled: a unit file someone edited by hand (the file itself, not an override beside it) is
    also "text that differs" and is rewritten. The copy of the replaced text is the way back.
  - Tests: `test-storage-units.py` (31), `test-update-shell-boundary.py` (3: the order of the reconcile steps,
    and that a failing units step does not stop the reconcile).
  - Proof owed (st-2): a release whose unit text differs from the installed one, taken with one
    `sudo isle release run`, after which `isle storage units check` answers ok on the hosting device with no
    hand step. Release 90 changes no unit text, so on release 90 the step must print nothing and change nothing.
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

Correction, 2026-11-21 (read without root, sizes only): the 1.8 TB HDD has no partition table. The "four empty
partitions" are a misreading by the system, not something on the disk.
- What the system shows: four partitions that all begin at the same place and all have the same length, each 733 GB.
  Four of those do not fit on the disk. None has a partition identifier, and the disk reports no kind of table.
- What explains it: the overwrite test of 2026-11-10 left the disk filled with one repeated byte. One of the old
  table formats the kernel still tries has no signature of its own, and a disk filled with that byte reads as four
  entries in it. A file of the same size with the same fill shows nothing at all to `blkid`.
- Not confirmed by reading the disk itself: that needs root.
- What follows: there is no empty partition to put a filesystem on. The disk needs a partition table first, so
  `partition create` needs a way that starts from a whole bare device (st-3, see section 5). That way is built
  since the same day: `--whole`, see "Making a partition" in section 5.

After the answers of 2026-11-20 (section 7) this table is partly overtaken. It is kept as the proposal it was:
- 233 GB SSD: not `backup`. Its first purpose is the isle template medium (decision 4).
- 1.8 TB HDD: `assets` for what is rarely used (decisions 3 and 5). What its other partitions carry is open.
- 466 GB HDD: `git` and the dependency stores go there (decision 3), and it is one filesystem that holds the package
  replica today. See the conflict under "st-1 built" in section 5.
- The user, 2026-11-20 evening (verbatim): "The device backup can live on the 500 GB HDD Internal. Container
  Images can be held by the 2 TB HDD." So `backup` is one more role on the 466 GB HDD, and `registry` goes on the
  1.8 TB HDD beside `assets`.
- The user, 2026-11-21 (R9): a partition can have more than one role. The 466 GB filesystem then carries
  `package-repo`, `git` and `backup` together, with no second partition. The 1.8 TB HDD has no partition table and
  no filesystem (see the correction above): `registry` and `assets` there wait for `partition create --whole`
  (built 2026-11-21, source-tested, for release 92) and for the user's run of it.

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
   - Answered 2026-11-20 evening: routine device-backups live on pol's internal 466 GB HDD (BACKUP_PLAN.md).
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
