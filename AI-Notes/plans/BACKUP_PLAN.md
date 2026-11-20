# Backups - pol's plan (2026-11-18)

Pol owns `pol backup create|restore`, the list of what a backup holds and the device-backup record (the split of
2026-11-12). Built so far: only the read-only listing (section 6, "Done ahead of bk-0").

**The word (the user, 2026-11-20): "Jusst call it a device-backup instead of a set, there are a lot of things called
sets, it is too generic."** A device-backup is one backup of one machine taken at one time. The word "set" is not
used for it anywhere: not in this plan, not in a verb, not in a file name. Fourth in the user's order of work (RELEASE_RUN_PLAN.md, "Priority order"):
after the one-command release, the apt separation and storage. It is step st-5 of STORAGE_ROLES_PLAN.md and a
precondition of the operating-system overwrite (section E of the release plan: "a backup of the device's isle
state exists and was verified").

## 1. Rulings this plan is built on (the user)

| # | Ruling | Date |
|---|---|---|
| B1 | Backups are never encrypted and there is no knob for it. | 2026-11-12 |
| B2 | Local only, never cloud by default. | 2026-11-12 |
| B3 | Each backup belongs to the Polari instance responsible for the data, so that instance can restore it. | 2026-11-12 |
| B4 | The home is the removable 250 GB SSD (`pol-ssd`). It holds releases and backups only, never Docker's store or live data. | 2026-11-12 |
| B5 | A removable disk is in mode `backup` (a full copy) or `export` (a fresh isle modelled on this one; no secrets, only module-defined data, names kept). | 2026-11-12 |
| B6 | Every step is an `isle` or `pol` verb; a plan is approved once and then runs. | 2026-11-14 |
| B7 | Do not duplicate what the engine already automates; no hand-wired routes. | 2026-11-18 |

This plan covers mode `backup`. Mode `export` needs a label on every data class (proposed 2026-11-13, not
ruled) and follows as its own step.

## 2. What exists and is reused (nothing of it is rebuilt)

| Piece | Where | Used for |
|---|---|---|
| Write gate with flush: `POST /api/quiesce`, `GET /api/quiesce/status`, `POST /api/quiesce/release` | engine, `polariApiServer/quiesce.py` | a still, fully written instance database while it is copied; reads keep working |
| Restore of an object tree from a database file | engine, `restoreFromDatabase` (the normal warm start) | a restore is "put the files back, start the instance" |
| Database dump inside one transaction, row counts before and after as the receipt | `pol swarm relocate` (the database mover) | MariaDB and Keycloak's database |
| Staged copy, check, swap, keep the previous generation, a journal file in the volume | same mover; the engine reports a left-over journal on `/api/health` | restore never writes over the only good copy |
| Restore drill: restore into a scratch database, compare counts, change nothing | `pol odoo restore-drill` | the proof that a device-backup can be restored |
| Volume archive before removal | `pol purge` | the plain file copy of a volume |
| Odoo dump and nightly timer | `pol odoo backup`, `backup-cron` | stays as it is; a device-backup calls it as one item |
| Journaled operation under a lock, with resume | `isle-cli/scripts/operations.py` | `create` and `restore` are operations, not loose scripts |
| Partition with the role `backup`, its marker and health | STORAGE_ROLES_PLAN.md (not built yet) | the target; until then the SSD is checked by its filesystem identifier |

## 3. What there is to back up (measured 2026-11-18, read-only)

| Machine | Polari instance data | Isle state | Not in a backup (proposed) |
|---|---|---|---|
| core | lean instance, one volume, 15 MB (sqlite) | settings and CA under `/etc/isle-mesh` (about 160 MB without the package store), state under `/var/lib/isle-mesh` (small without the two large folders) | package store 22 GB (public packages; a replica is on pol), release files 8.8 GB (they are releases, mirrored by the release run), operation journals 2.8 GB (decision 3) |
| pol | swarm instance: backend 162 MB, MariaDB 111 MB (Keycloak's database is in it), file store under 1 MB; the isle-deployed instance 10 MB; the forge 63 MB (stopped); volumes of a lean stack that is not running, 108 MB | settings 18 MB, state small | release files 4.4 GB, journals 1 GB, the package replica (a placed dataset) |
| econ | backend 109 MB, MariaDB 98 MB, file store under 1 MB; Odoo when it runs | settings under 1 MB, state small | release files 1.3 GB, journals 1 GB |

All three machines together are under 1 GB per round of device-backups without journals. The SSD has 217 GB free. Docker images are
never in a backup: they come from a release.

## 4. A device-backup

One folder per device-backup on the target: `backups/<device>/<id>/`. Inside: one file per item and
`device-backup.json`.

- `device-backup.json`: id, slot (`release` or `long-term`, section 4a), device name, instance names, time, release number and CLI versions, and for every item its
  kind, source, method, size, sha256 and receipt (row counts for a database). Names only, no addresses.
- Items and how each is taken:
  - instance database and data volume: gate up through the quiesce door, copy the volume, gate down. If the
    gate cannot be raised the item fails; nothing is copied from a moving database.
  - MariaDB, Keycloak's database: a dump inside one transaction, counts recorded.
  - file store, forge: archive of the volume.
  - isle state: archive of the listed folders, read as root.
  - Odoo: `pol odoo backup`, its receipt recorded.
- A device-backup is complete only when every item was re-read from the target and its sha256 matched. An
  incomplete one is marked so and never offered for restore.
- Files are owned by root, mode 0600. No secret appears in a file name.

## 4a. When one is made and how many are kept (the user, 2026-11-20)

Verbatim: "We only need 2 Backups, 7 is far too many. Only on a release or an update should we do a backup. One
Backup should be a longer term backup (weekly, so if we find a issue that carried through releases we can fall back
to something older) and then per-release so that if a release goes badly we can roll back easily."

- Two device-backups are kept per device, in two slots:
  - `release`: taken right before a release or an update changes the device. It is what a bad release rolls back to.
  - `long-term`: an older one, about a week old or more, for a fault that went unnoticed through several releases.
- A device-backup is made only as part of a release or an update. There is no timer and no nightly run.
- Pol's reading of "weekly" together with "only on a release or an update" (not ruled, said to the user): no
  timer makes the long-term one. When a release makes a new `release` device-backup and it is verified, the
  previous `release` one is not deleted if the `long-term` one is 7 days old or older (or absent): it becomes the
  new `long-term` one and the old `long-term` one is deleted. Otherwise the previous `release` one is deleted.
  So the long-term one is always older than the release one, and it moves forward at most once a week.
- Nothing is deleted before the new device-backup is complete, so three exist for a moment and two afterwards.
- `pol backup create` by hand stays possible for a test; it fills the `release` slot by the same rule.

## 5. Verbs

    pol backup plan                       read-only: what a device-backup of this machine would hold, sizes, the target and its free space
    pol backup create                     root, journaled: writes one device-backup, verifies it, then applies the two-slot rule
    pol backup list                       the device-backups on the target, their slot, complete or not
    pol backup verify <id>                re-reads every file against device-backup.json
    pol backup restore <id> --drill       restores into scratch copies, compares receipts, changes nothing
    pol backup restore <id> --apply       root, journaled: staged copy, check, swap; the instance is stopped first, the previous generation is kept

- `restore --apply` refuses a device-backup that is incomplete, one of another device, and one that has not
  passed a drill on this CLI version.
- A release-run step kind `backup`: every packet that changes a device takes a device-backup of it first (the
  user, 2026-11-20: "Only on a release or an update"). This is also what the overwrite needs. Pol builds it in
  the release runner; econ is on other work and no lane is in the way (the user, same day).

## 6. Steps (each ships as a release-run packet)

| Step | What | Proof |
|---|---|---|
| bk-0 | The decisions in section 7 | the user's words |
| bk-1 | `pol backup plan` (read-only) | it lists on each machine what section 3 measured by hand |
| bk-2 | `create`, `list`, `verify` for one machine, target on the same machine (pol) | a complete device-backup on the target; a file changed by hand is caught by `verify`; the two-slot rule holds over three runs a week apart (clock injected) |
| bk-3 | `restore --drill`, then `restore --apply` on a test instance | one restore actually performed, counts equal |
| bk-4 | The other two machines (decision 2) | one complete device-backup per machine on the target |
| bk-5 | The release-run step kind | a release takes the device-backup itself before it changes a device, and stops if that fails |
| bk-6 | Mode `export` | a fresh isle set up from an export, names kept, no secret carried |

bk-1 needs no decision except where the verb lives (decision 1); it reads only.

### Done ahead of bk-0 (2026-11-18): `pol backup plan`

Source-tested on pol; on the pol CLI's dev since 2026-11-20 (pushed); in no release, installed nowhere.

- `pol backup plan [--target <mount point>] [--table]` - read-only, no sudo. Lists the named Docker volumes it
  has a rule for (instance data, MariaDB, file store, forge, Odoo) with size, the running containers that use
  each, and how each would be taken (a volume nobody runs on is a plain copy); the isle's settings and state
  folders; what is left out and why, with sizes; a volume with no rule under "Not covered", never dropped
  silently; the total; and whether the named target could take it (a folder, its own mount point, not the
  system filesystem, free space at least twice the device-backup). `ready` is true only when all of that holds.
- `create`, `list`, `verify`, `restore` answer "not built yet" and change nothing.
- Files: `scripts/backup.sh`, `scripts/lib/backup_plan.py`, `scripts/test-backup-plan.py` (20 tests, fixtures
  only; 17 of 17 deliberate breaks caught), one line in `index.js`.
- Read on the three machines (on the core and econ from the source file, nothing installed there):

  | Machine | In the device-backup | Left out |
  |---|---|---|
  | core | instance data 15 MB (in use), settings 169 MB, state under 1 MB | package store 22.9 GB, release files 9.4 GB, journals 2.9 GB |
  | pol | 7 volumes, 453 MB together, settings 19 MB, state under 1 MB | release files 4.7 GB, journals 1.0 GB |
  | econ | backend 109 MB and MariaDB 98 MB (neither in use: that instance is not running), file store, settings and state under 1 MB | release files 1.4 GB, journals 1.0 GB |

  With `--target` set to the SSD's mount point on pol: usable. Sizes of the isle folders are incomplete without
  root (one to three entries per machine cannot be read), and the verb says so.
- Not seen by the listing yet, to be added before `create`: the router's virtual machine on the core (its
  definition and its disk image), the instance's runtime folder on the core (compose file and runtime config in
  the home folder), and credential and certificate files that live in a suite checkout and not in a volume.
- Found on the way, bearing on decision 1: `pol` refuses to start without a suite checkout beside it. The core
  has neither `pol` nor a checkout.

## 7. Decisions - the user's answers, 2026-11-20

1. Where the code lives. The user (verbatim): "I think isle should be responsible for storage since it has to link
   to hardware, polari just needs to be capable of being aware of it since planning goes through polari as well as
   isle." Pol's reading, left to pol: the target partition, its checks and the copy to disk are `isle` verbs;
   Polari says what its data is and holds its database still while it is copied. `pol backup plan` as built keeps
   the listing of Polari's data; its target check moves to the isle CLI.
2. How the other machines' backups reach the backup disk (left to pol): each machine writes its own locally and
   the machine that holds the backup partition fetches it over the isle. The transport is still to be chosen.
3. Operation journals: OUT (the user: "B3 Out"). The package store, release files and Docker images stay out too.
4. The CA key (left to pol): it stays in a full copy.
5. How many are kept: two per device (the user, 2026-11-20). Section 4a.
6. When one is made: only on a release or an update (the user, 2026-11-20). Section 4a.

New from the same message, changing section 1 (B4): the 233 GB SSD is first of all the isle template medium (a
completely new isle, new names and new security, set up from the SSD with no network; offline updates). "We
should be capable of transforming it into a backup as well". So mode `export` is the main mode and bk-6 moves
up. Where routine backups live when the SSD is a template medium is open; pol's proposal is one partition of the
2 TB dock disk with the role `backup`. Full text in STORAGE_ROLES_PLAN.md section 7, item 4.
