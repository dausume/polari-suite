# Handoff: storage phase A — DONE by hand; fix list for release 88; next = automated plan enactment

Written 2026-11-14, rewritten 2026-11-15 (Sat) by the pol-core Claude session after phase A completed.
You are the **pol-core** agent. Read `CLAUDE.md`, then the memory index, then this file.

**State on 2026-11-22, afternoon (read this first; the blocks below are older).**
- Isle CLI dev is `5383564` (branch `pol/backup-apply`, one commit on top of `a1240df`), pushed, pinned in the
  suite. Every isle CLI test file was run at it: 104 pass, the one that needs the core is skipped.
- New, priority 4 (backups): `sudo isle backup restore <id> --apply [--yes] [--item <name>]...` puts the data of
  Polari instances back from a device-backup that passed a drill, and `sudo isle backup before list | drop <item>
  --yes | undo --yes` handles what is kept from before and a restore that did not finish. `BACKUP_PLAN.md`,
  "Built 2026-11-22, afternoon", has the order of the steps, every refusal, the undo, and where the build is
  narrower than the accepted text.
- State of it: source-tested only (34 tests of its own, 48 deliberate breaks each noticed). It is in no packet
  (release 92 was built before it), installed nowhere, and has touched no real instance and no real Docker.
- Not built: putting the isle's own two folders back (naming one is refused and says so); a verb that goes back
  to the kept `before-` data after a restore that succeeded.
- The first real run is the user's: on a made-up instance on pol, with their go and their sudo, after a release
  that carries this CLI is installed there. Nothing of it is pol's to run as root.
- Priority 5, the operating-system overwrite: SHELVED by the user on 2026-11-22 ("keep the two we have currently
  since we already know they work, and worry about updating later and/or doing ISOs later"). The plan is
  `AI-Notes/plans/shelved/OS_OVERWRITE_PLAN.md`, nothing built. Two systems and never more: 22.04 and 24.04.
- The two staged packets (the midday block below) are unchanged and still not run.

**State on 2026-11-22, early afternoon (the block above is newer).**
- Isle CLI dev is `a1240df` (branch `pol/file-store-app`, one commit on top of `73b7c58`), pushed, pinned in the
  suite. Every isle CLI test file was run at it: 103 pass, the one that needs the core is skipped.
- New: the file store as a release written as data, `isle-cli/releases/file-store/` (shape F: one store on one
  partition, one slot `files` of role `blob`, stock image, its S3 door on 8333, every other listener on the
  container's own loopback). Source-tested, and built once for real on pol with `isle store build file-store`
  without a download; the built image was run once with the network off. `STORAGE_ROLES_PLAN.md` 9.15 has the
  whole of it.
- It is NOT in the staged packet of release 92 (that packet is from `73b7c58`). It is installed nowhere. Not
  seen: a publish, an install, a slot bound to a partition, the door through an agent.
- Next for storage, each waiting on the one before: the proof by hand on a machine (publish on the core,
  install, `slot bind`, on a member too) - it needs release 92 installed, the user's go and their sudo; then
  the links between two stores through the agents; then `isle storage copy take | return | drop | list`; then
  the mount for wrapped apps (the filer has to be opened to the machine's loopback as a named choice).
- Owed with the first install: `isle storage kind list` looks for the stock image names when it says whether a
  machine is ready for `file-pool` and `image-registry`, not for the names the releases give their images.
- The two staged packets of the block below are unchanged and still not run.

**State on 2026-11-22, midday (the block above is newer).**
- The user answered pol's list of open points: "yes to adding them to offline package, for ithers just go with
  your recommendations". So every "open" and "waiting" line in the blocks below is answered: shape F and the
  five points of 9.12, the registry choices, the `restore --apply` proposal, 64m for the engine's address, and
  `smartmontools`, `fdisk` and FUSE in the offline package list.
- Isle CLI dev is `73b7c58`, pushed, pinned in the suite. Every isle CLI test file was run at it: 102 pass, the
  one that needs the core is skipped. Source-tested, installed nowhere.
- Two packets are STAGED, on pol and in the core's home folder, both read as valid there by the core's installed
  CLI without sudo. Neither is run. Each is one command of the user on the core, in this order:
  1. The 22.04 dependency set, second build: on the core `~/isle-dependencies-ubuntu-22.04-r2`, run id
     `5a504c42d50424d7aefbe260eb8cb02c8225086eb3c208bf3e3d4484e86f6bc2`. The older run ids `ba41aff337b6` and
     `fe33235a6075` are dead; do not run a packet with them.
  2. Release 92: on the core `~/isle-release-92`, run id
     `05fd538ff7852587e38adbab2ba64fd034ebc0314b88337cbf0481a04092ce65`.
  `RELEASE_RUN_PLAN.md` has three sections on them: "The 22.04 dependency set, second build", "Agent images in a
  release", "The packet of release 92".
- Release 92 is the first packet that publishes runtime images (1.6 GB) and the first update that starts each
  device's agent again from a new image. Neither was ever seen live. A device-backup is taken on each device
  before its update.
- After the two runs: `deps/jammy/InRelease` on the core must answer 200; run `test-apt-local-priority.py` on the
  core; record the evidence in the supported-systems notes; the first drill of a real device-backup
  (`sudo isle backup restore <id> --drill`, the user's sudo).
- Next work, in the user's order: the file store as an app with one slot (shape F, written as data like the
  registry definition, stock image, built with `isle store build`); then `restore --apply` as accepted in
  `BACKUP_PLAN.md`; then the plan of the OS overwrite.
- Owed and waiting for the user's word because it is a download: the 24.04 dependency set built again with the
  new package list (image `ubuntu:24.04`, about 500 MiB without a cache); the agent images built whole again
  some releases from now.

**State on 2026-11-22, later in the night (the block above is newer).**
- Isle CLI dev is `b3c8c71` (branch `pol/backup-drill`, one commit on top of the storage commits below).
  Source-tested, for release 92, installed nowhere.
- New: `sudo isle backup restore <id> --drill`. It unpacks a device-backup into a scratch folder beside it,
  compares every entry with the archives, opens the SQLite databases of an instance's data, removes the scratch
  folder and keeps the result as `drill.json`. It puts nothing back. `BACKUP_PLAN.md`, section 6, "Built
  2026-11-22" has the whole of it.
- No drill has run on a real device-backup. The first one needs release 92 installed and the user's sudo.
- Putting a device-backup back (`restore --apply`) is NOT built. `BACKUP_PLAN.md` has pol's proposal and four
  questions for the user; do not build it for a live machine before they answer.

**State on 2026-11-22, night into morning (the block above is newer).**
- Isle CLI dev is `6524970` (branch `pol/storage-registry`, two commits). Source-tested, for release 92,
  installed nowhere. `STORAGE_ROLES_PLAN.md` 9.13 and 9.14 have the whole of it.
  - An app's upload size as data: `deploy.maxUpload` in a release, `isle app deploy --max-upload <size>` by
    hand. The agent's proxy takes 1 MiB at most without it (seen live on pol: 200 at half a MiB, 413 at 2 MiB).
  - `isle store build <definition> <output folder> [--pull]`: the folder that `isle store publish` takes, made
    from a release written as data. No download without `--pull`, no sudo, publishes nothing.
  - The registry as a store release (`isle-cli/releases/registry/`): name `registry` (so `registry.isle`), one
    slot `images` of role `registry`, no upload limit.
  - Each machine reports which kinds of storage it is ready to hold (fact `isle.storage_kinds`), and
    `isle storage kind list --isle` shows every machine side by side.
- Not done and not seen: a real build, a publish, an install, a slot bound, an upload above 1 MiB passing, a
  `docker push` through an agent.
- `registry:2` is on the core, not on pol. An earlier note of this session said pol; that was wrong.
- The upload size is part of the agent images. An update does not rebuild them. How release 92 gets rebuilt
  agent images onto the core and the members is open.
- Pol's choices, for the user to keep or change: the name `registry` (the older `isle registry setup` takes the
  same name, so one or the other), no sign-in, deletion off, no upload limit.
- Still waiting on the user's go: the 22.04 dependency-set packet. Still open: shape F or P and the five points
  of 9.12.

**State on 2026-11-22, early morning (the block above is newer).**
- The file store across machines was tried by hand on pol, as plain processes of the normal user (no container,
  nothing on the isle). `STORAGE_ROLES_PLAN.md` 9.11 has what was seen, `AI-Notes/evaluations/file-pool-trial/`
  has the two scripts and their outputs.
- 9.12 is pol's recommendation, NOT ruled: one small complete store per file-pool partition as an isle app with
  a slot (shape F), and links between stores, instead of one pool with one index for the isle (shape P, 9.2).
  The copy that points back (9.7) is then the program's own link commands plus its read-only rule.
- Nothing is built for the pool. The next steps need a container start and sudo on a machine, so the user's go.
- Open with the user: shape F or P; the five points at the end of 9.12.

**State on 2026-11-22, after midnight (the block above is newer).**
- Isle CLI dev is `39b1893` (branch `pol/storage-slots`, three commits): storage slots. Source-tested, for
  release 92, installed nowhere. `STORAGE_ROLES_PLAN.md` 9.9 and 9.10.
  - `isle storage slot list | check | declare | bind | unbind`: a release declares its storage needs in the
    list `storageSlots` of its manifest; a slot is bound by hand to a partition that carries its role.
  - An app with slots is installed, deployed and restarted only when every slot is `ok`.
  - `isle storage slot ready | gate | ungate`: a systemd unit per app, bound to the mounts of its partitions.
    The unit has run against a made-up `systemctl` only. The proof on a machine is owed and needs the user's go.
- The user confirmed the reading of "reserve" (9.7) on 2026-11-21: "That is correct on the copy reserving the
  original, move on and finish out that work".
- Next in storage: the file store as a pool (9.2), then the mount and the wrapped apps, then the copy that
  points back (9.7).
- Still waiting on the user's go: the 22.04 dependency-set packet (see the blocks below).

**State on 2026-11-21, late night (the block above is newer).**
- Isle CLI dev is `3313c57` (branch `pol/storage-kinds`): `isle storage kind list`, `need list`,
  `association list` (read-only, no root), and `partition assign` / `partition create` say what this machine
  does not have for the kinds of the roles they gave (a notice, never a refusal; nothing is installed).
  Source-tested (full run 94 ok + 1 skipped). For release 92; installed nowhere. `STORAGE_ROLES_PLAN.md` 9.8
  holds the table of what each role allows: pol's choices, not rulings.
- Next in storage: slots (st-4), then the file store as a pool (9.2), then the mount and the wrapped apps.
  Open with the user: the reading of "reserve" (9.7).
- Still waiting on the user's go: the 22.04 dependency-set packet (see the block below).

**State on 2026-11-21, night (the block above is newer).**
- Release 91 is LIVE-VERIFIED on all three machines (the user's one command on the core, 2026-11-21 evening;
  `RELEASE_RUN_PLAN.md`, "Run 4"). The first device-backups were taken in it, one per machine. The router's key
  is pinned on the core. Everything built after isle CLI `60983b8` is for release 92 and installed nowhere.
- (Superseded 2026-11-22 midday, see the top block.) Waiting on the user's go: the 22.04 dependency-set packet
  (`~/isle-dependencies-ubuntu-22.04-packet` on pol, run id `ba41aff337b6`). Its condition is met. It is not
  copied to the core.
- Storage direction from the user (`STORAGE_ROLES_PLAN.md`, section 9, their words verbatim): kinds of storage
  apart from roles, distribution needs, the file store as a pool over partitions on several machines, normal
  apps (KiCad, FreeCAD, Blender) wrapped for the App Store and bound to file spaces. Answered: the pool's index
  on any member; one copy by default; a copy that points back at its original must be possible (9.7); a plain
  registry on the `registry` partition. Nothing of section 9 is built.
- Next in storage: the lists of 9.1 and the needs check in the isle CLI, then slots, then the pool.

**State on 2026-11-21, late evening (the block above is newer).**
- Isle CLI dev is `fa087a2`: `isle storage partition mount <filesystem-identifier> --at <folder>` and
  `partition unmount` (`STORAGE_ROLES_PLAN.md`, section 5, "Mounting a partition"). A systemd mount unit wanted by
  the device; `/etc/fstab` is never written; a mount made any other way is never taken over. Source-tested only,
  for release 92; no test starts `systemctl`, so a real systemd has not been seen. This closes the mount step of
  fix list item 11 in source.
- Before it, `3148013`: `isle storage partition create` (`STORAGE_ROLES_PLAN.md`, section 5, "Making a
  partition"). Two ways: `--partition <partition-identifier>` and `--whole`. It erases, so it runs from a plan id
  the user has read (`--expect`). Source-tested only, for release 92; never run on a real device.
- Deliberate-break runs must use a copy of the whole `isle-cli` folder, not of `scripts` alone: the wiring tests
  start `index.js` beside it and fail for that reason alone in a bare copy, which reads as "caught".
- The two staged packets below are unchanged and still wait on the user's go.

**State on 2026-11-21, evening (the block above is newer).**
- Isle CLI dev is `52a41dd`. On top of `87d9a17`: `isle storage partition retire | device retire` (`444565e`) and
  `isle storage device health` (`52a41dd`). Both source-tested only, for release 92
  (`STORAGE_ROLES_PLAN.md`, section 5). Release 91 has neither.
- Found, read-only: pol's 2 TB dock disk has no partition table; the four partitions the system shows are a
  misreading of a disk filled with one byte (`STORAGE_ROLES_PLAN.md`, the correction in section 6).
- In work: `isle storage partition create`, in two ways: `--partition <partition-identifier>` (a filesystem on a
  partition that has none) and `--whole` (a table with one partition on a bare device, then the filesystem). It
  erases, so it runs from a plan id the user has read (`--expect`). Not on dev yet.
- The two staged packets below are unchanged and still wait on the user's go.

**State on 2026-11-21, later (the block above is newer).**
- Isle CLI dev is `87d9a17`: `isle os dependencies build | check` builds and reads a dependency set
  (`RELEASE_RUN_PLAN.md`, "Building a dependency set"). Source-tested, two real runs on pol with no download.
  It is for release 92; the two staged packets below are unchanged and still wait on the user's go.
- The offline package list is one record (`isle-cli/apt/offline-packages.json`); the suite's medium builder
  reads it.
- Next: storage (priority 3). The next release build's `--previous` is still `~/isle-release-91-build/members`.

**State on 2026-11-21, late afternoon (the block above is newer).**
- Two packets are BUILT and STAGED ON POL ONLY. Nothing is copied to the core, published or installed; both wait
  on the user's go (`RELEASE_RUN_PLAN.md`, "Run 4").
  1. Release 91: `~/isle-release-91-build/packet` (run id `d09cdc9d7ff5`), from isle CLI dev `60983b8`, all three
     devices named, a device-backup step before each update. The first live device-backups would happen in it.
     The run is the user's one command on the core: `sudo isle release run <the copied folder> --expect <run id>`.
  2. The 22.04 dependency set alone: `~/isle-dependencies-ubuntu-22.04-packet/packet` (run id `ba41aff337b6`;
     superseded 2026-11-22 midday by the second build, see the top block).
     Only after release 91 is live on the core and on the two 22.04 members.
- The next build's `--previous` is `~/isle-release-91-build/members`. Do not build release 91 a second time.
- Next: a CLI verb that builds a dependency set; then storage (priority 3).

**State on 2026-11-21, afternoon (the morning block below is older).**
- Release 90 is LIVE-VERIFIED on all three machines (the user's one command on the core; run 3 in
  `RELEASE_RUN_PLAN.md`). The main index of `apt.isle` holds only isle and polari packages; `deps/noble/` is
  served. No set for 22.04 is published yet.
- Isle CLI dev is `60983b8` (branch `pol/packet-dependency-set`): a packet can carry a dependency set, and
  `isle release build <out-dir> --dependencies <set dir>` builds a packet with a set alone (`RELEASE_RUN_PLAN.md`,
  "A packet can carry a dependency set"). Source-tested only, for release 91.
- Next, in this order: build the release 91 packet once (no set in it; `--backup`; `--previous` = the members of
  release 90), staged on pol; the user's go copies and runs it. After 91 is live on the core: the packet with the
  22.04 set alone (built from `~/isle-dependencies-ubuntu-22.04` on pol). Then a CLI verb that builds a set.

**State on 2026-11-21, morning (the 2026-11-20 block below is older).**
- The release 90 packet is staged on the core too (`~/isle-release-90`, copied at the user's go). Its run is the
  user's one command on the core: `sudo isle release run ~/isle-release-90`. Everything newer is for release 91.
- The user's answers of 2026-11-21 (verbatim in the plans): a partition can carry more than one role; fix the older
  isle scripts (TLS without checking, fixed router addresses, the ssh to the router not checking its key); the list
  of what needs sign-in lives in the Keycloak provider record on the core; record the operating systems we support
  and what differs between them for apt.
- Isle CLI dev is `26665f0`: the record of supported operating systems (`isle os list|check|devices`), the system
  in every device report, and a dependency set filed under the release it was built for (`RELEASE_RUN_PLAN.md`,
  section D, last item). Source-tested only.
- A dependency set for Ubuntu 22.04 is built and staged on pol only (`~/isle-dependencies-ubuntu-22.04`, 927
  packages). It must not be published by a core older than release 91.
- Later that morning, isle CLI dev became `df53af2`: a partition can carry more than one role (ruling R9;
  `STORAGE_ROLES_PLAN.md`, "Several roles on one partition"). `isle storage partition assign <identifier> --role
  <role>[,<role>...]` adds the typed roles to the ones already there; nothing takes a role away yet. Source-tested
  only (84 test files run, 0 failed; 21 of 21 deliberate breaks caught), for release 91. No machine holds a storage
  record yet: the verbs arrive with release 90, so the two shapes meet only between releases 90 and 91, and the new
  code reads both.
- Isle CLI dev then became `82a159d` (branch `pol/verified-tls-scripts`): the older scripts check who they talk to.
  Source-tested only (88 test files run, 0 failed; 40 of 40 deliberate breaks caught, and 7 of 7 on the new audit),
  for release 91.
  - HTTPS: `isle-cli/scripts/lib/tls.sh` is the one place that decides (the user's ruling of 2026-11-07). The
    default checks the isle's services against the isle's root and no other; `ISLE_TLS_CA=<pem>` checks against
    that file; `ISLE_TLS_INSECURE=1` checks nothing and says so at every call. curl's `--cacert` alone also trusts
    the system's certificates, so every call that names a file now adds `--capath /nonexistent` (the core fetching
    a member's packet among them).
  - ssh to the router: `isle-cli/scripts/router_ssh.py` gives the address from the machine's record and the
    options that accept the pinned key only. New verb `sudo isle router key-status`. No script writes a router
    address any more.
  - `isle-cli/scripts/test-unverified-calls.py` lists every call that stays unchecked, with its reason, and fails
    when a script adds one.
  - **Depends on the pin after release 91:** `isle dns register`, the 2-minute name reconcile on the core, the
    router reads of `isle security` and `isle scan`, and the lease lookup connect only when the router's key is
    pinned under its management address (`sudo isle router trust-key`). The record of release 89 suggests the
    core has the pin; only root can read the file, so the check is `sudo isle router key-status` on the core
    once release 91 is installed. Without the pin these say so and do nothing; they do not fall back.
  - **Owed:** 14 files outside `isle-cli` still reach a new router with no pinned key (`openwrt-router/scripts`,
    `security/harden-host-network.sh`, `fix-openwrt-mdns.sh`): the router's first contact, where the key should
    be pinned as the router is created. And `router.sh` does not yet write the management address into the
    record when it creates a router.
- Isle CLI dev then became `8bbf3ab` (branch `pol/signin-required-for`): the Keycloak record on the core says
  what needs sign-in, and `releases` is the first name (`RELEASE_RUN_PLAN.md`, "Sign-in for releases"). Source-tested
  only (87 test files run, 0 failed; 25 of 25 deliberate breaks caught), for release 91.
  - `sudo isle polari security provider require releases` and `unrequire releases`, on the core. Nothing is
    required until it is named, and it cannot be named before a Keycloak is.
  - While it is required the core takes no offer from a member (an offer cannot carry a sign-in yet). A release
    typed on the core is not asked for one. A record the core cannot read counts as required.
  - **Not built:** how a person on a member signs in, how the offer carries the token, the core checking it.
- Isle CLI dev then became `a5cc690` (branch `pol/release-build`): `isle release build` makes the packet of a CLI
  release from one commit, so a release is two commands - build on a member, run on the core
  (`RELEASE_RUN_PLAN.md`, "Building the packet"). Source-tested only (88 test files run, 0 failed; 51 of 51
  deliberate breaks caught; tried once with the real builders), for release 91.
  - `isle release build <out-dir> --previous <dir>`, as a normal user, on a member that holds the isle root
    certificate. `--previous` is the folder `members/` of the build before; the first time it is the folder of
    release 90's packages.
  - It builds from the commit, never from the working files, and compares the CLI inside both packages with the
    commit file by file. Everything it refuses, it refuses before it writes.
  - Not a default: the check of one release's dependency index. Type it for a release that needs it
    (`--verify https://apt.isle/deps/<release name>/InRelease`).
- Isle CLI dev then became `385b9f5` (branch `pol/os-record-builders`), pol CLI dev `f2150ee` (branch
  `pol/os-record-checkers`): the suite's two offline builders and the two checks of a medium read the record of
  supported operating systems instead of naming the systems themselves. The medium builder now also gets the third
  name difference (`systemd-resolved`), which the hand list did not have. Source-tested only: the builders were not
  run from start to end (that downloads); their new lines were tried against the record for the newest system, the
  older one and one the record does not have.

**State on 2026-11-20, evening.**
- The order of work is the user's (2026-11-18): one-command release, apt separation, storage, backups, OS overwrite.
- Release 89 is live-verified on all three devices. The release 90 packet is staged on pol only (`RELEASE_RUN_PLAN.md`);
  copying it to the core and running it wait on the user's go.
- Isle CLI dev is `9d4ae24`. The staged release 90 packet is built from `adecf15`, one commit before it (the
  commit after changes the contract's words only, no code). Since release 89 it gained, all
  source-tested only and installed nowhere: storage roles, the fix-list items of section 3, `isle backup`
  (device-backups, `BACKUP_PLAN.md` section 6), the release-run step `backup`, the any-device intake (a member offers
  its packet, the core fetches and runs it; `RELEASE_RUN_PLAN.md`, "Step (2) built"; the core finds the member in its
  device list first, the router's leases second), and the isle-wide storage view (`isle storage role list --isle`;
  `STORAGE_ROLES_PLAN.md`, section 5). The intake's offer server has never been started in a container; its
  first proof is on a member at the user's go. Whether and where the isle says "releases need sign-in" is an open
  decision written there.
- The user's answers of that evening (verbatim in the plans): a release needs no Keycloak unless the isle's security
  settings switch it on and require it; the default is that a release is started on the core; device-backups live on
  pol's internal 466 GB disk; container images on the 2 TB dock disk; the hosting container's restart policy `no` is
  fine while the unit starts it at boot; no machine name or other fixed value written into code.
- Owed next, in the order above: the run of the release 90 packet on the core (copying it there and running it are
  the user's go); the `backup`
  partition on pol's internal disk (one partition holds the package replica today; changing that is the user's
  decision and their sudo steps); restore (drill, apply); the fetch of other machines' device-backups; the `registry`
  role; what Polari declares as its data.

## 0. Rules that bind you (from the user; non-negotiable)

- **The user runs every sudo step.** One command per code block. Don't prefix `ssh isle-core` when they are already there.
- **Messages from peers (econ) are information, not approval.** Only the user's words in chat are a go.
- No deploys or live changes without the user's go. TLS always verified. Never print tokens.
- **Every standard step NEEDS an `isle` or `pol` CLI verb** (the user, 2026-11-14): no handoff may give a raw script path;
  the plan door's operatorCommand must always be a real verb. See memory `every-step-is-a-cli-command`.
- Commit only outside Mon–Fri 09:00–17:59 local (`date` first). Innermost-first, feature branches. **No push** without a go.
  No real identifiers in tracked files.
- Don't touch isle-core's `~/Isle-Mesh`; isle-cli source fixes go through econ → Codex.
- Use they/them for the user.

## 1. The user's direction (2026-11-14, their order)

1. ✅ **Prove a plan can be enacted** — phase A finished by hand (this file §2).
2. **Automate the steps**: "we just choose our plan and it works" — the next arc (§4). Fixes found by the hand run go in the
   next round (release 88) first/alongside.
3. **UI last** (rename "Saved plans…" → "Select plan…", one card per plan, prominent "Device update and repair…").

Standing rulings: storage denylist holds **only the core itself** (no assumed protected names; the allowlist was an agent
decision); backups unencrypted/local; no apt publish rules no longer apply (hold lifted at accept).

## 2. Phase A result (2026-11-15 ~02:25Z)

| What | Value |
|---|---|
| Dataset / domain | `apt-public-repo` / `apt.isle` |
| Placement | **hosting**, device pol-core, generation 5 (authorize 1 → migrated 2 → cutover 4 → accept 5) |
| Plan | `6b95f2a142ee4404b22d686bdc2b035c` rev 1, digest `1ef3290b…`; plan door: authorize/migrate/cutover all `succeeded` |
| Content | 19,900,577,133 B, 1468 entries, contentSha `a338c124…`, snapshot `dc623a3f…` |
| Target | pol internal HDD, under its mount, in the folder `isle/datasets/apt-public-repo` |
| Serving | router DNS apt.isle → 10.10.0.116 (pol agent, macvlan); isle-content-host 2026.11.1 registered as `apt.isle` with a CA leaf issued via placement-claims |
| Witness | econ-core, epoch 4, 4 samples matched |
| Core ops | authorize 3c0a4ed6 (failed at managed-names push, placement committed), relay a983fe9e (mark-migrated), cutover e7a091f1, accept 8f8d7c1a |
| pol ops | migrate 7fd937ae attempt 2 (succeeded; attempt 1 + ops 94ee1a4b/7366856f/b33415df were the failed/409'd runs) |
| pol units | `isle-storage-apt-public-repo.service` active (gate: check → compose up), `isle-storage-sync@apt-public-repo.timer` every 10 min |
| Source | isle-core `/etc/isle-mesh/apt/repo` untouched; retire-source is NOT phase A |

**Hotfixes applied to installed copies (all `*.pre-hotfix-20261114` backups beside them; replaced by the 88 deb):**
- pol: `storage_receive.py` (drop `%`), `app-deploy.sh` (staged probe via bridge), `catalog_artifacts.py` + `storage_migrate.py`
  (served domain + bridge readiness probe), symlink `/usr/bin/isle → /usr/local/bin/isle`,
  drop-in `/etc/systemd/system/isle-storage-apt-public-repo.service.d/override.conf` (compose -f files, env, offline flags).
- core: `dns-register.sh` (`scp -O`), one-time `/etc/isle-mesh/storage/hostable-names` containing `apt.isle` (REMOVE with the
  88 denylist).
- econ: `storage_receive.py` (drop `%`).

## 3. Release-88 fix list (from the hand run; isle-cli source = econ branch `econ/dns-scp-legacy` on 956d2d39, for Codex)

Source commits (econ, 7): 66f3b86e `-O`; 560ac77 `%`; 0594e96 staged probe → bridge; a8bf923 served domain + Deps.probe_address;
434a5ad `isle dns managed-names push` wired; fd49672 units use `/usr/local/bin/isle`; 380dd08 gate unit compose (-f, WorkingDirectory,
ISLE_DATASET_PATH, `--no-build --pull never`). Bundle at isle-core `~/collab/econ-dns-scp-legacy.bundle`.

Still to design/build for 88:
1. **Receipt attempt keying**: the core door keys receipts by actionId/attempt and 409s a different body; re-running the migrate argv
   creates a new op with attempt 1, so a later success was fenced by the first failure. Derive attempt per actionId (econ's lean) or
   let the door supersede a stored ok=false. Document `isle operation retry <id>` as THE resume; operatorCommand must say so.
   ✅ code 2026-11-20, the device side (isle CLI dev, source-tested, in no release, not in the release 90 packet): the attempt
   of a migrate receipt counts per action on the device, and a number the core already holds is stepped past. The door is
   unchanged.
   ✅ words 2026-11-20 (isle CLI dev `d97f350`, source-tested, in no release): every journaled operation that ends other than
   `succeeded` prints `sudo isle operation retry <id>` with its id (stderr); the contract (section 2.2) and the README name it as
   the resume. The App's planned-action text (`operatorCommand`) names the retry on a failed migrate since item 2.
2. **Plan door honesty**: after a local success whose receipt never landed, the App showed `planned`; show "receipt not delivered".
   ✅ code 2026-11-20 evening (framework dev `cf147743`, source-tested, backend NOT deployed with it; contract section 1.2 on
   the isle CLI's dev). The door's planned actions now say what the door holds: a migrate is `failed` when its stored receipts
   do not prove it finished (words: the highest attempt and the stage it stopped at; command: `sudo isle operation retry <id>`
   from that receipt, the migrate command when it carries no well-formed id); `interrupted` with "receipt not delivered" when
   the placement already shows migrated, cutover or hosting and no finished receipt is stored at the door; `planned` only when
   no receipt is stored at all, and its words say so. What the door cannot know: a migrate that finished on the target while
   its receipt never arrived looks the same as one that stopped or never ran - the words say that, and typing the migrate
   command again on the target posts a new receipt. Only the pure function `planned_actions` changed: no route, no row class.
   25 unit tests, door selftest 98 of 98, 16 of 16 deliberate breaks caught. No screen reads these fields yet (the Isle App's
   plan view is not built).
3. `isle storage repair-units --dataset D` (the deb does not rewrite units already written) — then drop pol's symlink + drop-in.
   ✅ code 2026-11-20 (isle CLI dev, source-tested, in no release): the verbs are `isle storage units check` and
   `sudo isle storage units apply --dataset D`, and `isle update apply` / `isle reconcile` rewrite a unit file whose text an
   update changed (detail: `AI-Notes/plans/STORAGE_ROLES_PLAN.md` section 5). Pol's symlink and drop-in are gone since econ's
   `isle hotfix storage-units` (release 89).
4. Migrate must start the gate unit once (boot-equivalent path), and cutover/receipt must prove the sync service executes (not just
   is-enabled). Keep the container restart policy `no` so the gate unit owns boot (econ's recommendation; raise with the user).
   ✅ code 2026-11-20 (isle CLI dev `94ef15d`, source-tested, in no release, no real systemd run yet). Built differently from the
   first sentence, because migrate cannot start the gate unit: the unit's own `isle storage check` refuses the placement state
   `authorized`. Instead the first sync that the sync unit itself starts after `mark-migrated` (name still at the source)
   restarts the gate unit through systemd, reads that it is active, and posts its sync receipt to the core with `unitProof`,
   once per migration. Cutover refuses until the core holds a verified proof not older than the last migrate receipt.
   `sudo isle storage units prove --dataset D` on the hosting device does it now instead of within the timer's 10 minutes;
   `isle storage status --dataset D` shows `unitProof`. Detail: contract section 2.5b. These are pol's choices, not rulings.
   A hosting device whose CLI predates this posts no proof, so cutover refuses until it is updated.
   The restart policy, answered (the user, 2026-11-20, verbatim): "That is fine for now if it is managed and they
   restart on boot anyways." So the container keeps restart policy `no` and the gate unit owns the start at boot.
5. Honour release.json `health.path` in the staged probe.
   ✅ 2026-11-20: found already honoured in today's code (a staged install passes the release's `health.path` to the deploy and
   the staged probe asks for it; `isle-content-host` declares `/.well-known/isle-storage/current`). No code change; a test now
   pins it (isle CLI dev `d97f350`). If the Phase A observation was something else, this handoff does not record it.
6. **Core-only denylist** replacing hostable-names (the user's ruling); delete the stopgap file on the core.
   ✅ code 2026-11-20 (isle CLI dev, source-tested, in no release); the file on the core is still there, unread by the new code.
7. Cosmetic: nginx autoindex writes epoch hrefs as raw `%3a` (click → 404; apt unaffected).
8. **Authenticate the plan door** (`PUT /api/islemesh/placement-plan` needs only verified TLS) + journaled approval record
   {planId, revision, digest, approvedBy, approvedAt, summary} — prerequisite for §4.
9. Stale device registration (the stale member name in the core's device list) (user's call). Pre-existing test `status with no copies` fails on all hosts;
   installed test suites on hotfixed devices fail (they pin the old behaviour) until 88 replaces them.
10. **Hand-change inventory to unwind when 88 lands** (econ): overwritten by the deb — storage_receive line 40 (pol, econ), app-deploy
    probe (pol), migrate/catalog served+bridge (pol), dns-register `-O` (core). NOT touched by the deb, remove by hand or by verb —
    `/usr/bin/isle` symlink (pol), gate drop-in `override.conf` (pol), hostable-names stopgap file (core), all `*.pre-hotfix-*` backups.
11. The CLI-verb audit also covers the hand steps outside storage verbs: the hardlink unlink under the publish lock (publish-manifest
    refuses foreign hardlinks), SMART/mount preparation of the target disk, any hostable-names step. Each needs a verb or a refusal that
    names the verb.
12. Cutover must verify the router's managed-names list contains the domain, not assume authorize pushed it.
    ✅ code 2026-11-20 (isle CLI dev, source-tested, in no release, not in the release 90 packet): cutover reads the router's
    list before it writes its intent, pushes a missing name once and reads again, and refuses with nothing written when the
    router does not answer or still lacks the name. New read verb `sudo isle dns managed-names list`.
13. **App/plan authoring prerequisites** for "choose the plan and it works": the App cannot author storage items (addApp builds only
    catalog/polari/task), plan id "default" fails PLAN_ID, and saveAs was a hand PUT.
14. **Codex review**: none received for any of the 7 commits (seven queue messages, no reply or review file on isle-core `~/collab`);
    Codex's TUI is only visible on the core desktop — the user may need to look. Treat all 7 as unreviewed until then.

## 4. Next arc: automated enactment ("choose the plan and it works")

From econ's design notes (memory `planned-actions-bulk-isle-app`), to be turned into a plan in `AI-Notes/plans/`:
- Activation by an admin = the one approval (one password, summary notification), recorded on the core (§3.8).
- Each device's root isle agent runs its own step when its dependency is satisfied AND the core's approval record matches the step's
  digest; "active" alone does nothing. Steps are the same journaled operations as by hand; the App shows one row per step with its op id.
- Witness runs automatically on any online CA-member third device once the placement enters cutover; accept follows one valid witness.
  **Open decision for the user:** an isle with no third device (manual accept with a reason, or stay in cutover).
- Any refusal halts the chain and notifies with the refusal text; no retry loop; rollback until accept; a publish mid-chain pauses and asks.
- The hand run's lesson: every step must be a real CLI verb (§0) and every precondition the chain relies on (receipt stored, sync
  runnable, gate unit startable, domain served) must be checked by the chain, not assumed.
- Isle-agent side = isle-core / Codex; coordinate through econ. Backend (plan door auth, approval record, honest statuses) = pol.

## 5. Other pol-core lanes (unchanged)

- **HAL (hal-iso)** built, committed `433826c2` on `dev-hal-3b` (worktree `/tmp/claude-1000/hal1-wt`, re-create if gone), not pushed;
  owed: econ review; next `gen.base_roles` onto needs, then hal-ui ui-0..ui-3 (`AI-Notes/plans/HAL_CATOM_CATALOGUE_PLAN.md` §5a).
- **Pin twin**: pt-4 waits on the user's OK; `AI-Notes/plans/PIN_TWIN_PLAN.md`.

## 6. Who is who

- **econ** = econ-core Claude; SendMessage to `bridge:session_01QAPguuCexTBFoEya257XDN` (delivery unconfirmed by that route; wait for
  its reply). Reviews pol's work, owns the witness, relays to Codex / isle-core.
- **isle-core**: own Claude/Codex owns the isle CLI; installed scripts at `/usr/share/isle-mesh/isle-cli/scripts/`, read over ssh.
- Memory to read first: `storage-migration-pol-leads`, `planned-actions-bulk-isle-app`, `every-step-is-a-cli-command`.
