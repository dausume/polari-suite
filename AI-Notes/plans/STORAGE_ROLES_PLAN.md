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
    isle storage partition list | create | mount | unmount | assign | check | retire
    isle storage role      list | show <role>      (--isle: every machine's report, side by side)
    isle storage slot      list | check | declare | bind | unbind      (built 2026-11-21, section 9.9)
    isle storage slot      ready | gate | ungate                       (built 2026-11-22, section 9.10)
    isle storage kind list | need list | association list              (built 2026-11-21, section 9.8)
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

#### Mounting a partition, built 2026-11-21 (source-tested, isle CLI dev `fa087a2`, for release 92)

A filesystem made by `partition create` is not mounted, and everything else (the marker check, datasets, the
backup role) needs it mounted whole. Mounting was a hand step (fix list item 11).

    sudo isle storage partition mount <filesystem-identifier> --at <folder>
    sudo isle storage partition unmount <filesystem-identifier> [--with-datasets]

- Without sudo each runs every check and prints the sudo line to type.
- What `mount` does: it writes one systemd mount unit that names the filesystem by its identifier (never a name
  like `sdb1`), reloads systemd, enables the unit and starts it. systemd makes the folder when it is not there.
- The unit is wanted by the device, not by the start of the machine. The partition is mounted each time the disk
  is present. A dock disk that is away holds nothing up.
- It erases, formats and moves nothing. `/etc/fstab` is read and never written. The storage records are not
  touched: the unit file is the only record of the mount.
- `mount` refuses, with nothing changed:
  - an identifier this machine does not see, or sees on two partitions;
  - a partition of the running system, or a device that is not registered;
  - a partition that is mounted already in any other way. A mount made by hand or by `/etc/fstab` is not taken
    over;
  - a filesystem or a folder that `/etc/fstab` names;
  - a folder that is `/`, is reached through a link, is not a folder, is not empty, or has something mounted on
    it;
  - a unit file for that folder that this verb did not write, and a second folder for a partition that has a unit
    of this verb already.
- Typed again for a partition it mounted, it says so and changes nothing.
- After the unit is written a failed step prints `FAILED:` and what is there (the unit written, or written and
  enabled, and the partition not mounted by it). The same command goes on from there.
- What `unmount` does: it stops that unit, disables it and removes the file. The folder stays. No data changes.
  The roles stay recorded, and `partition check` shows the partition as not mounted.
  - It only touches a unit that `mount` wrote (the first line of the file says so). A partition mounted another
    way is refused and left alone.
  - A partition that holds a dataset of this machine is refused unless `--with-datasets` is typed. What serves
    the dataset is bound to the mount and stops with it.
  - It also removes the unit of a disk that is away.
  - When systemd cannot stop the mount (something on it is in use) it prints `FAILED:`, keeps the unit, and says
    that what depends on the mount may have been stopped.
- pol's choices, not ruled:
  - `--at` is typed every time. No folder name is built into the CLI.
  - No mount option is set (the filesystem's own defaults, so read and write).
  - The verb runs with sudo on the machine itself. It does not go through the core's plan door (fix list item 8).
  - A filesystem that `/etc/fstab` mounts is left to `/etc/fstab`. Read-only look on pol: its two data
    filesystems are mounted by `/etc/fstab` lines, so this verb refuses both and nothing about them changes.
    Moving them to units is not built and not proposed.
- Files: `storage_mounting.py` (new, 231 lines), `test-storage-mounting.py` (37 tests), the dispatch in
  `storage_roles.py`, `storage_devices.py`, `storage.sh`, the CLI's README.
- Proof: 37 new tests on fixtures (made-up disks, made-up answers of `systemctl`, the unit folder and the fstab in
  a temporary folder). 108 of 108 deliberate breaks caught. Every test file of the CLI: 93 ok, 1 skipped (it needs the core), 0 failed.
- Not proven: systemd itself. No test starts `systemctl`. That a unit wanted by the device unit is mounted when the
  disk is plugged in and at a start of the machine is how systemd is documented, not something a test here saw.
  The first real run is the user's.
- For the user on pol, once release 92 is installed there and the 1.8 TB disk has its filesystem (the identifier
  is from `isle storage partition list --table`, the folder is their choice):

      sudo isle storage partition mount <identifier of the new filesystem> --at <folder>

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
  recorded class and role. (`retire`, `health`, `create` and `mount` are built since 2026-11-21, see the four
  blocks above.)
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

## 9. Kinds of storage, the file pool, and normal apps bound to the isle (the user, 2026-11-21) - PLAN; only 9.8, 9.9, 9.10, 9.13 and 9.14 are built, 9.11 was seen by hand

Verbatim: "Maybe we should define different kinds of storage types and partitions, for normal polari the seaweed
FS file storage is the best option, and for long term storage it may also be one of our best options. The
question would be how do we assign the partitions to be for the seaweedFS and make seaweedFS available despite it
potentially having partitions across multiple machines assigned to it. And the. as you said Images shoumd be tied
to docker itself likely (I think you implied that?) so different partition types require different things to be
installed on that machine. And different apps may need different kinds of file storage. Would seaweedFS work as
the file storage solution for things like Kicad and FreeCad and Blender? Could we bind it to mounted volumes tied
to those apps so we could by default access the seaweedFS storage? We would want to wrap installations of kicad
and freecad and blender so they can be installed via Polari App store, but our install versions would wrap then
and bind then to seaweedFS with specific tags signifying which normal app they are bound to. This is how we can
bind normal apps to the isle. We started planning and building this out before, but I wanted to ensure the way we
are building our partitions is also leading towards that capability that way we are bringing everything together."

Everything below is pol's proposal for that. Nothing in it is ruled and nothing is built.

### 9.1 Separate distinctions, not one word

The user, same day, after reading the first draft of this section: "So perhaps think of different levels of
distinctions aside from roles, like dependency/association for different kinds of storage and distribution need
typing."

So a role stays only a purpose. Four more things are named apart from it, each a short fixed list, and a body of
data points at one entry of each.

**Kind of storage: what serves the data, and so what the machine depends on.**

| Kind | What serves it | What the machine must have | Roles that use it first |
|---|---|---|---|
| plain folder | a web server on a folder, or nothing | nothing more than today | `package-repo`, `distribution`, `backup`, `scratch`, `transfer` |
| file pool | one SeaweedFS storage process per partition | the file store's image, or its one program | `blob`, `assets` |
| image registry | a container registry, its data folder on the partition | Docker and the registry image | `registry` |
| git | the forge | the forge's image | `git` |

**Distribution need: how the data has to reach the devices that use it.**

| Need | Meaning | Example |
|---|---|---|
| kept | used only on the machine it sits on | device-backups, scratch |
| served | one copy, every device reads it by an isle name | the package store, the image registry, git |
| pooled | pieces on several machines behind one isle name | file spaces, the blob store |
| cached | the primary stays where it is; a device keeps a bounded copy while it uses it and drops it by itself | a mounted file space, pulled images |
| installed | a copy must sit on every device that runs it | packages and images once installed |
| carried | moved by hand on a disk or a stick | install media, `transfer` |

**Association: what the data belongs to.** The isle (shared by all), one app (a file space), one machine (its
device-backups), or one release (its packet). An app's file space is tied to both its app and the isle, as in
section 8.

**Copies: how many, and on how many machines.** One, or two on two machines. Set per body of data.

**Lifetime: how long it is kept.** Until removed, per release, or scratch.

- The kind decides the dependencies. `partition assign` checks that the machine has what the kind needs and says
  what is missing, the way `device health` says `smartctl` is missing. It installs nothing by itself.
- The distribution need decides what the plan has to do: nothing (kept), give it a name (served), start storage
  processes (pooled), mount with a cache (cached), run an install on each device (installed).
- Which kinds and needs a role allows is a fixed table in the CLI. No record or marker that is built changes; the
  marker keeps naming roles only.
- In Polari each of these is a small row class of its own that the others point at, not one wide row.
- Backups stay plain folders that are kept. A restore must not need the pool to be running.

### 9.2 Partitions on several machines as one file pool

- One place on the isle holds the index of the pool (which machine holds which piece), the list of file names,
  and the S3 door. It has one isle name. It holds no file content, so it is small and may be on the core.
- Each partition with a file-pool role runs one storage process that joins that index. It stores in a folder of
  the partition and is labelled with its machine and its role.
- The storage process is tied to the partition's mount unit (`partition mount`, section 5). When a dock disk
  leaves, that one process stops and the rest of the pool keeps serving.
- Number of copies is set per file space. One copy means no duplication, and those files are away while their
  disk is away. Two copies on two machines costs the space twice and survives one machine being off.
- Today the file store is one process per Polari node that names itself by the loopback address
  (`polari-rf-node/prf-file-store/entrypoint.sh`). A pool needs that changed: the parts must name themselves by
  isle addresses and speak to each other over TLS from the isle's own certificate authority.
- Read from the pinned version's own help (4.47, run without a network): a storage process takes several
  folders, a free label for the kind of disk, a rack and a data-centre name, and the address of the index; the
  index takes a default number of copies. Not seen: a pool that really spans two machines.
- 2026-11-22: the mechanics were tried by hand on one machine (9.11). After that pol recommends another shape
  than this section (9.12). Not ruled.

### 9.3 KiCad, FreeCAD and Blender on the pool

- The file store can show one of its folders as an ordinary folder on a machine (its `mount` command). KiCad,
  FreeCAD and Blender open ordinary files, so they need nothing else. The same folder is a bucket on the S3 door,
  so Polari and the simulations read the same files with no second copy.
- Read from the same help: the mount takes the index's address, the folder to show, a local folder for a cache
  and its size in megabytes, and a number of copies. The cache is what gives "copy it here while it is needed,
  then drop it": the pool keeps the primary, the machine keeps a bounded cache and empties it by itself.
- Not tested, and to be tested before this is promised:
  - Without the network the mounted folder is not usable. The cache is not an offline copy.
  - Two people saving the same file: the last save wins. Nothing merges.
  - Speed with large Blender files and with many small KiCad files.
  - The machine needs the FUSE package and the file store's program outside a container.
- ownCloud and Nextcloud (section 8) answer the offline case with a synced copy on each machine, which is the
  duplication this section avoids. The comparison is still owed.

### 9.4 Normal apps wrapped for the Polari App Store

- One file space is one bucket. Its name carries the app and the isle, and that is the tag that says which normal
  app it is bound to.
- A wrapped app is an App Store entry that says: which package installs the real app, which file spaces it
  needs (each one a slot: a role, a number of copies, a size), and how it is started.
- Installing it: the package comes from the isle's own package store; the plan binds each slot to the pool; the
  file space is mounted as a folder; a launcher starts the real app with that folder as its place for projects.
- In Polari a file space is a row (app, bucket, role, copies, who may reach it) of a row class, so the engine
  makes its table and API. No hand-written routes. Access goes through the door that exists: the signed-in
  person's own temporary keys, and no sign-in needed on an isle that has it switched off.
- Found already built in the engine, to build on and not beside: the object-store connection
  (`polariDBmanagement/managedObjectStore.py`), the store browse page, the App Store module's own use of the
  store, and the CAD import of the shapes module that keeps its files there.

### 9.5 Does what is built lead there

- Yes for the base: a partition known by its filesystem identifier, a marker with its roles, a mount unit tied
  to the disk, and one isle-wide report of roles are what 9.2 stands on.
- Three things are missing, in this order:
  1. the lists of 9.1 (kind, distribution need, association) and the needs check: small, in the isle CLI
     (BUILT 2026-11-21, source-tested, see 9.8);
  2. slots, the binding of an app's storage need to a role (st-4 in section 5)
     (BUILT 2026-11-21 and 2026-11-22, source-tested, see 9.9 and 9.10; the proof on a machine is owed);
  3. the file store run as a pool (9.2), then the mount and the wrapped apps (9.3, 9.4)
     (2026-11-22: its mechanics seen by hand on one machine, 9.11; the shape is open, 9.12; nothing built).
- This replaces "a verb reads a role to place data" as the next piece of storage work.

### 9.6 Choices - answered by the user, 2026-11-21

Verbatim: "it can live on any member, no duplication but we should be capable of making copies that reference
back to the original that reserve the original and ensure edits done remotely get applied to it again if that
makes sense, a plain registry on the registry partition should be fine, will go with your recommendations go
ahead on 91"

| # | Choice | Answer |
|---|---|---|
| 1 | Where the pool's index lives | on any member. Nothing ties it to the core; which machine is a setting of the plan. |
| 2 | Copies by default | one. No duplication. But a copy that points back at its original must be possible (9.7). |
| 3 | Container images | a plain registry with its data folder on the `registry` partition. |
| 4 | Long-term storage | left to pol: no role of its own for now. It is `assets` data with the lifetime "until removed". |

### 9.7 A copy that points back at its original (the user, 2026-11-21) - PLAN, only the word `taken` is built

- The requirement, in the user's words: copies "that reference back to the original that reserve the original
  and ensure edits done remotely get applied to it again".
- Pol's reading, CONFIRMED by the user on 2026-11-21 ("That is correct on the copy reserving the original, move on
  and finish out that work"):
  - A device takes a copy of a file or a folder of a file space onto its own disk. The copy records which
    original it came from and the state of the original when it was taken.
  - While the copy is out, the original is reserved: everyone can still read it, and nobody else changes it.
  - Edits made on the copy are applied back to the original. Then the reservation ends and the copy can be
    dropped. The original stays the only lasting copy.
  - This is also the answer for a device that is away from the isle: the mounted folder of 9.3 needs the
    network, a copy taken beforehand does not.
- It is a new distribution need beside those of 9.1, "taken": a copy on one device that owes its edits back.
- Settled: "reserve" means that others cannot change the original while the copy is out, and can still read it.
- Open, for the design: what happens to a copy that never comes back; whether the edits return by themselves when
  the device is on the isle again or by a command. What the file store's own commands give for both: 9.11, 9.12.
- As everywhere: each step is an `isle` verb (take, return, drop, list), and Polari holds one small row per
  copy that points at the original.

### 9.8 Built (2026-11-21): the lists of 9.1 and the needs check - source-tested, for release 92

Item 1 of 9.5. Isle CLI dev `3313c57` (branch `pol/storage-kinds`). Installed nowhere.

- Three read-only verbs, no root: `isle storage kind list`, `isle storage need list`,
  `isle storage association list` (each with `--table`). The listing verb is `need`, because `distribution` is
  already the name of a role.
- The lists and the table of what each role allows are fixed in the CLI (`storage_kinds.py`). No record and no
  marker holds them: they keep naming roles only, so nothing already written changes.
- `kind list` also says whether this machine has what a kind needs: `ready`, `not ready`, or `not known` when
  Docker did not answer the user who asked. The look is two questions and nothing else: is a program on the
  path, and does `docker image ls` show an image of a repository (any tag). It never pulls, starts or installs.
- `partition assign` and `partition create` say, after the roles are given, what this machine does not have for
  the kinds of those roles. It is a notice: the roles are recorded all the same and the exit status stays 0.
- `role list` names the kind of each role; `role show <role>` names its kind, distribution needs and
  associations.

The table as built. These are pol's choices, not rulings; the user can change any line:

| Role | Kind | Distribution needs | Belongs to |
|---|---|---|---|
| package-repo | plain-folder | served | isle |
| distribution | plain-folder | served, carried | isle, release |
| registry | image-registry | served, cached | isle |
| blob | file-pool | pooled | isle, app |
| git | git | served | isle |
| assets | file-pool | pooled, cached, taken | app, isle |
| backup | plain-folder | kept | machine |
| scratch | plain-folder | kept | machine |
| transfer | plain-folder | carried | isle |

What a machine must have: `plain-folder` nothing more; `file-pool` the program `weed`, or Docker with an image
of the file store; `image-registry` Docker with an image of `registry`; `git` Docker with an image of the forge.

Also pol's choices: a missing program or image never refuses a role (the user may assign first and install
after); "installed" is in the list of needs and no role uses it yet (it is for the wrapped apps of 9.4);
"taken" (9.7) was added to the list of needs once the user confirmed the reading of "reserve" (2026-11-21), and
`assets` is the one role that allows it; nothing takes or returns such a copy yet; the lists of copies and of
lifetimes are in slots (9.9), where they are first used.

Not done: no plan reads a distribution need yet; nothing starts a storage process, a registry or a mount. (Which
kinds a machine is ready for is in the device report and the isle-wide view since 9.14.)

Tests: `test-storage-kinds.py`, 31 tests on a made-up machine with a made-up path and a made-up Docker. 115
deliberate breaks, 114 caught; the one left changes nothing while no kind's name is part of another's.


### 9.9 Built (2026-11-21): storage slots, and an app started with them - source-tested, for release 92

Item 2 of 9.5. Isle CLI dev `d4a396a` (branch `pol/storage-slots`: `19fe4b2` the slot verbs, `d4a396a` the app's start).
Installed nowhere.

A storage slot is one storage need of one app: a folder the app sees, the role of the partition that has to
hold it, and whether the app writes to it.

- A release declares its slots in the list `storageSlots` of its release manifest. (`storage` in a manifest is
  already the dataset bind of a hosting app, so the slots have their own key.) Each slot: `name`, `role`,
  `target` (the plain absolute path inside the app), and optionally `service`, `writable` (false when left
  out), `owner` (`<user>:<group>` as numbers), `distribution`, `association`, `copies` (1 or 2), `lifetime`
  (`until-removed`, `release`, `scratch`), `sizeBytes`. Any other key is refused. The kind comes from the role.
- What an app declares is kept with the app: `/etc/isle-mesh/apps/<app>/storage-slots.json`.
- A binding is kept in the machine's storage record, beside the partition's roles: slot, role, filesystem
  identifier, when. No second store.
- The data is one folder at the root of the partition: `isle-slots/<app>/<slot>`. A folder that is there
  already is kept with what is in it, so a disk carried from another machine is taken up as it is.

Verbs:

- `isle storage slot list [--table]` and `isle storage slot check [--app <app>] [--table]` - no root. `check`
  exits 1 unless every slot is `ok`.
- `sudo isle storage slot declare <app> --from <release.json>` - keeps the list; binds, makes, starts nothing.
- `sudo isle storage slot bind <app> <slot> --partition <filesystem-identifier>` - makes the folder, writes
  the binding.
- `sudo isle storage slot unbind <app> <slot>` - takes the binding out; the folder and its data stay.

States a slot can be in: `ok`, `not bound`, `not declared`, `declaration cannot be read`, `partition away`,
`partition needs attention`, `role taken away`, `declared with another role`, `folder missing`,
`mounted read-only`.

What is refused, with nothing changed: binding a slot the app does not declare; a partition that is away, does
not carry the role, or needs attention; a written slot on a partition mounted read-only; less free space than
`sizeBytes`; something at the folder's name that is not a folder of the partition itself (a link is never
followed); a slot bound to another partition already; a release that drops a bound slot or changes its role;
`partition retire --role` while a slot is bound under that role; `partition unmount` without
`--with-datasets` while a slot is bound to the partition.

How an app is started with its slots:

- `isle store publish` refuses a release whose `storageSlots` cannot be read. `isle store install` refuses one
  that names a service its compose file lacks, before any image is loaded.
- An install keeps what the release declares and then, before anything is deployed, refuses unless every slot
  is `ok`. So the first install of an app with slots is a refusal that says which slot to bind; after the
  `slot bind` commands the same install goes through.
- `isle app deploy` runs `slot check --app <app>` before it writes or starts anything. The app's overlay then
  gives each slot's folder to its service at `target`, read-only unless the slot is `writable`. Docker is told
  never to make a missing folder, so an absent partition fails the start and nothing is written to the system
  disk in its place.
- `isle reconcile` (the restart at an update) leaves an app alone when its slots are not all `ok`, or when its
  overlay does not give exactly the folders that are bound now.
- An app without `storage-slots.json` is started exactly as before.

pol's choices, not rulings; the user can change any of them:

1. The manifest key `storageSlots`, and the fields and their defaults (not written, one copy, kept until
   removed, the role's first distribution need, belongs to the app when the role allows it).
2. The folder name `isle-slots/<app>/<slot>` at the root of the partition.
3. A slot is bound by hand, one command per slot. The CLI never picks the partition. (A plan that picks it from
   the roles is the natural next step; it is not built.)
4. The first install of an app with slots refuses and keeps the declaration, instead of installing the app
   without its folders.
5. `unbind` never removes data, and no verb removes a slot's folder.
6. Two slots may sit inside one another (`/a` and `/a/b`), and a slot may sit on top of a volume of the app's
   own compose file; only two folders at the very same place in one service are refused.

Not done:

- The unit that stops an app when its partition goes away was built after this: 9.10.
- A second copy: `copies: 2` is recorded and shown, no more. Moving a slot's data between partitions.
- `lifetime` and `distribution` are recorded and shown; nothing acts on them yet.
- A binding whose declaration file was removed by hand is shown as `not declared` by `slot list`, and the
  deploy does not look at it.
- The pool (9.2), the mount with a cache (9.3), the wrapped apps (9.4) and the copy that points back (9.7).

Tests: `test-storage-slots.py` (62 tests) and `test-storage-slot-start.py` (24 tests) on the made-up machine;
4 more in `test-catalog-artifacts.py`. The deploy script is never run whole: only its slot lines, with a
made-up check. Deliberate breaks: 161 of the slot verbs and 80 of the app's start, every one caught by a test. Whole isle CLI test run: 96 ok, 1 skipped (`test-apt-local-priority.py`, which needs the core), 0 failed..

### 9.10 Built (2026-11-22): an app stopped and started with its partitions - source-tested, for release 92

The rest of item 2 of 9.5 (st-4 in section 5). Isle CLI dev `39b1893` (branch `pol/storage-slots`). Installed
nowhere. The unit it writes has run against a made-up `systemctl` only, on no machine.

- `isle storage slot ready <app>` - no root, changes nothing. Exit 0 when every slot of the app can be used and
  the app's overlay gives exactly the folders that are bound now; exit 1 with the reason. An app that declares
  no slot is ready.
- `sudo isle storage slot gate <app>` - writes the unit `isle-app-<app>.service`, enables it and starts it.
  - The unit is bound to the mount units of the partitions the app's slots are bound to (the units of
    `partition mount`, section 5). A partition that goes away stops the app. A partition mounted again by its
    unit starts it.
  - The unit is wanted by those mounts and never by the start of the machine, so a disk that is away holds
    nothing up at boot.
  - Before each start the unit asks `slot ready`. The start is the deploy's own compose call from the app's
    folder, with no build and no pull. The stop is a compose stop: containers are kept, not removed.
  - Refused, with nothing changed: an app that is not deployed, declares no slot, hosts a dataset (the
    dataset's own unit starts and stops it already), is not ready, or has a unit of that name which this verb
    did not write.
  - Typed again with nothing to do, it says so and changes nothing.
- `sudo isle storage slot ungate <app>` - takes the unit away and leaves the app as it is, running or not.
- `isle app undeploy <app>` takes a unit of `slot gate` away first. Without that, the next mount of the
  partition would start an app that was taken down.
- `slot list` and `slot check` say when an app's unit no longer names the partitions its slots are bound to
  now, and print the command that writes it again (`unitsOutOfDate` in the JSON). The exit code of
  `slot check` is not changed by it.

pol's choices, not rulings:

1. The unit is wanted by the mounts, not by the machine's start.
2. `gate` starts the app if it is not running. `ungate` never stops it.
3. No install and no deploy gates an app. The verb is typed once per app. (Doing it in the install is one line
   once the unit has been seen to work on a machine.)
4. `undeploy` ungates first, and stops with an error if that fails.

Not done, and not proven:

- The proof on a machine: an app stops cleanly when its partition is unmounted and starts when it is mounted
  again. It needs a deployed app with a slot, a partition that may be unmounted, and the user's go.
- `ungate` leaves the app running by first putting a unit in place that stops nothing, then stopping that.
  This rests on how systemd treats a unit changed while it is active. Seen only against the made-up
  `systemctl`.
- A partition mounted by hand, without its mount unit, does not start the app. `slot gate <app>` typed again
  does.

Tests: `test-storage-slot-gate.py`, 30 tests with a made-up `systemctl` and temporary folders; the undeploy
lines are run alone with a made-up `sudo`. 122 deliberate breaks, every one caught. Whole isle CLI test run:
96 files ok, 1 skipped (`test-apt-local-priority.py`, needs the core), 1 failed: in `test-apt-repo-publication.py` one
step ran past its own 15-second limit. That file was run again alone on the same commit and passed (25 tests). The
commit does not touch what it tests; the likely cause is other work on the machine during the run.

### 9.11 Seen by hand (2026-11-22): the file store's own mechanics, on one machine

The first step for the pool, by hand, before any verb. Nothing here is built into the CLI and nothing ran on the isle.

How it was done:

- The pinned file store program (4.47) was copied out of the image that is already on pol. No image was pulled and no
  container was started.
- It ran as plain processes of the normal user, on loopback ports, in a scratch folder. One trial had one process
  answer on the address of Docker's own bridge, a private address that only pol itself reaches.
- The two scripts are kept in `AI-Notes/evaluations/file-pool-trial/` so the trials can be run again.

**Trial 1: one pool.** One index, three storage processes, each on its own folder. The folders stand for three
partitions: two on a made-up machine A, one on a made-up machine B.

| Question | Seen |
|---|---|
| One copy: where do 60 files go | Spread over A's and B's partition (24 and 36). No file on both. |
| B's partition goes away | A's files read. B's files answer with an error (500). Nothing is lost. |
| New one-copy files while B is away | Written, onto A. |
| B's partition comes back | All 60 files read again, nothing to repair. |
| A rule "two copies on two machines" for one file space | Its 20 files are on both. They read with B away. |
| A new two-copy file while B is away | No answer in 45 seconds. A file space with two copies needs both machines to write. |
| A partition labelled `assets`, and a rule that sends one file space to that label | Its 20 files are on that partition only. No other file landed there. |
| The S3 door | Gives the same bytes as the list of names. |
| A file space shown as an ordinary folder (`mount`) | Lists, reads and saves work. A change made elsewhere shows in the folder. |
| Two saves of one file, one in the folder and one elsewhere | The later one stays. No notice. |
| The folder when the list of names is away | A file read before reads again. A file not read before gives no answer (stopped after 15 seconds). |
| The read-only rule on one folder (for 9.7) | A change, a new file and a new name are refused through the list of names and through the S3 door. Taking a file away is NOT refused, through either. |
| The same rule seen through the mounted folder | A save over the original is refused and the original is unchanged. Taking a file away and giving it another name both go through. |
| The S3 door's own hold on an object (object lock) | Not usable for this. A change is accepted as a new version, and the two doors then show different content for the same name. |

**Trial 2: two separate stores, and a folder of one that is a link to a bucket of the other.** Store A holds the
originals. Store B links a folder to A's bucket through A's S3 door (the program's own `remote.*` commands).

| Question | Seen |
|---|---|
| B after the link, nothing read | Lists the 12 names. Holds no content (0 bytes). |
| A file read through B | Fetched from A, the same bytes. B then keeps that one file's content. |
| Take the whole folder (`remote.cache`) | B holds all the content (3.6 MB, as A). |
| A away | B reads the taken files, and saves changes and new files. |
| A back, the return process started only now (`filer.remote.sync`) | The edits made while A was away reach A, and the new file too. |
| An edit and a removal on B with A present | Both reach A within seconds. |
| A changed while the copy is out | B does not see it by itself. It sees it after asking A for the names again (`remote.meta.sync`). |
| A and B both change one file | B's edit is written over A's. No notice. This is what "reserve" has to prevent. |
| A holds the folder with the read-only rule while B edits | Someone else's change on A is refused. B's edit waits: the return process tries again and again. |
| The rule is taken away | B's waiting edit reaches A by itself, and later edits follow. |
| Drop the copy (`remote.uncache`) | B keeps the names and no content. A is whole. A read through B fetches from A again. |
| Take the link away (`remote.unmount`) | B's folder is gone. A is whole. |
| The program's guard on where a link may fetch from | By default it refuses an endpoint on a private or a loopback address. Every isle address is private, so on the isle this guard has to be switched off by its named option on the store that fetches. |

Not seen, and not to be claimed:

- Anything across two real machines, through a device's agent, with the isle's certificates, or in a container.
- TLS between the parts of one pool. Read, not tried: the program's TLS between its parts is mutual, and the isle's
  certificates are issued for server use only (`certs.sh`), so one pool across machines would need a new kind of
  certificate.
- Speed, large files, many small files.
- The door's sign-in. In both trials the S3 door was open.
- Also read, not tried: the S3 door of 4.47 opens two more listeners by default (a table catalog and a namespace
  server). The trials switch both off. Whether the Polari node's file store has them open is to be checked.

### 9.12 What 9.11 means for the pool, the folders and the copy - pol's recommendation, NOT ruled

Section 9.2 proposed one pool: one index for the isle, and a storage process on every file-pool partition that
joins it. The user's answer 1 of 9.6 (the index on any member) was given to that proposal. After 9.11 pol
recommends a different shape. It is put here for the user to accept or turn down. Nothing is built for either.

**Shape P, as in 9.2: one pool for the isle.**

- It is the literal reading of "partitions across multiple machines assigned to it", and it works (trial 1).
- The parts on different machines speak to each other on several ports of their own, outside the agents. The
  agents carry one HTTP port per app.
- Its TLS between parts is mutual, so the isle would issue a new kind of certificate.
- The one index is needed for every file. When its machine is off, a file on your own disk is away too.
- A disk carried to another machine brings content that means nothing without the index.

**Shape F, recommended: one small complete store per file-pool partition, and links between stores.**

- A store is one isle app with one storage slot. Its index and its content are both on the partition.
- It is started and stopped with the partition by `slot gate`, reached by one isle name through the device's
  agent, with a certificate of the kind the isle issues today. All of that is built (9.9, 9.10) or exists.
- This is also how the Polari node's file store runs today: one process, one folder.
- A file is kept once, on its home partition. Every device reads it by the isle name of that store. No duplication.
- A device that wants a file space as its own folder links it. It then holds the names and fetches content when
  it is read. This is the cached need of 9.1.
- The copy that points back (9.7) is the same link, with the content taken. See below.
- A dock disk carried to another machine brings its whole store, names included.
- A store that is off takes only its own files away.
- What it does not do: spread one file space over several partitions. A file space lives on one partition. When
  it outgrows it, it is moved. The isle-wide list of file spaces (which store is the home of which) is a report
  of the isle CLI and rows in Polari, not one index.
- Shape P stays possible inside one machine later: several partitions of one machine behind one index need no
  network between machines.

**The same in both shapes:**

- A device needs a small store of its own to hold a taken copy, and to show a file space as a folder.
- The folder for KiCad, FreeCAD and Blender (9.3) is always a mount of the device's own store, never of a store on
  another machine. A file space from elsewhere is a link in the local store.
- The guard of 9.11 has to be switched off on a store that links, by its named option. To be recorded as a setting.

**The copy that points back (9.7), with the program's own commands.** No new mechanism is written.

| Step | What it is | In the file store program |
|---|---|---|
| take | the device links the folder and takes its content; the home store holds the original | `remote.configure`, `remote.mount`, `remote.cache` on the device; the read-only rule on the home store |
| work | edits on the device's copy, with or without the isle | the device's own store |
| return | the hold ends; the edits are written to the original | the read-only rule taken away on the home store; `filer.remote.sync` on the device |
| drop | the device keeps no content | `remote.uncache`, then `remote.unmount` |
| list | the copies that are out | one row per copy; the link list of the device's store |

Answers that 9.11 gives to the open points of 9.7:

- Do the edits return by themselves or by a command: both are possible. The return process can run all the time.
  While the original is held it only waits, and the edits go back the moment the hold ends. So `return` is the
  one command that ends the hold, and the writing follows by itself.
- A copy that never comes back: the original stays held and readable. Ending the hold on the home store without
  the device is one command there, and the device's edits are then refused or written over whatever came after.
  To be ruled: who may do that.

Open, for the user or for the proof on machines:

1. Shape F or shape P.
2. The hold does not stop a file being taken away (9.11). Pol's proposal: accept it. The device's copy has the
   whole content, so `return` writes a missing original back and says so. Stopping it fully needs the door's
   sign-in (people who may only read), which an isle without sign-in does not have.
3. The hold is put on by the home store's machine, the copy is taken on another. So `take` is two steps on two
   machines, or one planned action that the core sequences. The second fits "one command, any device".
4. The store's program on the machine itself (not in a container) for the mount, and the FUSE package: both are
   things to install, so both wait for the user's word on package lists and release content.
5. Which image the store app runs. The stock image is on machines that run Polari. A machine without Polari
   needs it carried in a release (about 530 MB).

Next, in this order:

1. The store as an app with one slot, written as data, and proven by hand on one machine: deploy, `slot gate`,
   read and write through its isle name. Needs a container start and sudo, so it needs the user's go.
2. A link between two stores on two machines, by hand, through the agents.
3. Then the verbs: `isle storage copy take | return | drop | list`, and the mount for the wrapped apps.

### 9.13 Built 2026-11-22: an app's upload size, `isle store build`, and the registry as a store release

State: **source-tested** on pol, isle CLI dev `0074cd2` (every test file of the CLI: 99 passed, 1 skipped because
it needs the core, none failed). It is for release 92. It is in no release and installed nowhere. Nothing was
built for real, published, installed or bound. No container was left running.

**Why the upload size came first.** Every app on the isle is reached through its device's agent, and the agent's
proxy takes a request body of 1 MiB at most (nginx's own default; nothing set it). Seen live on pol, through pol's
own agent, over verified TLS: a body of half a MiB was answered 200, a body of 2 MiB was answered 413. A registry
behind an agent could not take an image layer, and the file store of 9.12 could not take a file above 1 MiB.

**The upload size, as data.**

- A release says it as `deploy.maxUpload`. A deploy by hand says `isle app deploy --max-upload <size>`.
- A size is `0` (no limit) or a whole number with `k`, `m` or `g`: `64m`, `2g`.
- `isle store publish` refuses a size it cannot read. So does an install, before anything is fetched.
- The agent keeps it on the app's entry in its registry (`maxBody`). Its generator writes it for that app only,
  and switches off request buffering for that app, so a large upload is passed on while it arrives.
- An app that declares none keeps 1 MiB. A deploy typed again without the option puts 1 MiB back.
- Polari's own registrations were not changed. What size they should get is the user's.

**`isle store build <definition> <output folder> [--pull]`.** The step between a release written as data and
`isle store publish` was done by hand until now. This verb is that step.

- A definition is a folder: `release.json`, its compose file, its files. Each image is written
  `<release>/<label>:PIN-AT-BUILD` with digests of zeros, and names the image it is built from.
- The build names the image `<release>/<label>:<version>`, saves it for linux/amd64, reads the identity out of the
  saved archive, and writes the output folder with the real name and digests. The definition is never changed.
- Without `--pull` nothing is downloaded. An image that is not on the machine stops the build.
- It prints the sha256 that `isle store publish` will give the release. A test publishes the built folder into a
  temporary repository and reads the same sha256 back.
- It publishes nothing and starts nothing. Any user who may use Docker can run it; no sudo.
- A definition the CLI carries is named by its bare name: `isle store build registry <output folder>`.
- Everything an install would refuse (a slot, an upload size, a port, a compose file that runs another image) is
  refused before Docker is asked anything.

**The registry release** (`isle-cli/releases/registry/`), the user's answer 3 of 9.6.

- Name `registry`, so it answers at `registry.isle`. The CLI already accepts images only from that name.
- One image, built from `registry:2`. One storage slot, `images`, of role `registry`, on `/var/lib/registry`.
- `deploy.maxUpload` is `"0"`. Health is read at `/v2/`. The compose file opens no host port and keeps no data
  outside the slot.
- The order on a machine: install (the declaration is kept and the install refuses), `sudo isle storage slot bind
  registry images --partition <filesystem identifier>`, install again.
- `registry:2` is on the core and not on pol. So the build can run on the core with no download, once release 92
  is there. On pol it refuses without `--pull`.

**Not seen, and what stands between this and a registry in use.**

1. No real build. The tests use a made-up `docker` that writes real archives.
2. No upload above 1 MiB was seen to pass. nginx accepted the generated text in one throwaway container with no
   network; that is all.
3. The proxy text is part of the agent images. An update does not rebuild an agent image or recreate an agent
   container. So the upload size reaches a machine only when its agent image is rebuilt and its agent recreated.
   How release 92 carries that to the core and to the members is open.
4. No `docker push` to `registry.isle` through an agent was tried, and Docker on each device has to trust the
   isle's CA for that name.
5. `docker compose config` of the built compose file is run by the install, not by the build.

**Pol's choices here, not rulings.**

- The name `registry`. The older verb `isle registry setup` (a container on a host port of the core, data under
  the settings folder) takes the same name. One or the other; which stays is the user's.
- No sign-in: any device on the isle may push and pull. This is pol's reading of "a plain registry".
- Deleting images is left at the registry's default, which is off.
- No limit on an upload (`"0"`), and the version `2026.11.1`.

Tests: `test-store-build.py` (21), `test-upload-size.py` (16), `test-catalog-artifacts.py` (16). Each refusal of
the build was broken on purpose once, and a test caught every one.

### 9.14 Built 2026-11-22: which machine is ready for which kind, seen from any machine

State: **source-tested** on pol, isle CLI dev `6524970`. For release 92. In no release, installed nowhere.

The registry and the file store have to be put on a machine that can hold them. Until now that was asked on each
machine by itself (`isle storage kind list`, 9.8).

- Each machine adds one fact to the device report it already sends to the core, `isle.storage_kinds`: one word
  for each kind (`ready`, `not ready`, `not known`). No program, image or path is in it.
- `isle storage kind list --isle [--table]`, from any machine: one line for each machine and one column for each
  kind.
- `isle storage role list --isle` and `role show <role> --isle` add the kind of each role and what the
  partition's machine said about it. The table names a machine that holds a partition for a kind it is not ready
  for.
- It goes the same way as the partitions report of st-1: a fact in the engine's device rows, read from the
  core's device list over verified TLS. No backend change, no route made by hand, no second store. Polari reads
  the same rows (R8).
- A report, not a check. Nothing is installed or refused because of it. A machine with an older CLI is shown as
  having said nothing. What a machine lacks is asked on that machine.
- Read once on pol from the source tree, against the real path and the real Docker (looking only): pol is ready
  for `plain-folder`, `file-pool` and `git`, and not ready for `image-registry`.

Tests: `test-storage-isle.py`, 30 tests (14 new). 33 deliberate breaks, 32 caught; the one left removes a check
that the next line makes again.

Not done: no plan picks a machine from this report. A person reads it and binds the slot.
