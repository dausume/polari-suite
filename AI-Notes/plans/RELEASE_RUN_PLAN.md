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

### Run 2, 2026-11-20 - LIVE-VERIFIED (a publication and `update-apply`; CLI release 89)
- Packet `release-run-proof-2` (packet 2a below), run id `668a123d4f5f`. The user typed ONE command, on the core.
- Core: published 3 package files (with the release-88 publisher; the scan of the whole package store took about
  20 minutes), read the release id `ed83e4c84a94`, waited until it was served, updated itself (operation
  `441098aa...`), signed the approval (serial 1795199348). Package `polari-complete-offline 0.1.89+release89`.
- Members followed on their own timers, nothing typed there: econ (operation `0110f199...`) and pol (operation
  `0a14e819...`), both `isle-mesh-cli 0.1.209+release89`. The core's member table shows both done.
- Checked afterwards, read-only, on all three: `isle release status` = done with the three verify URLs ok;
  `isle apt-repo pin check` = in place; `isle release setting` = core-only (the members say the core publishes no
  setting, the core says any-device is not available yet); on both members `isle release run` WITHOUT sudo is
  refused with the device named and the core named (the release-88 fault of section B is gone).
- Proved now, beyond run 1: a packages publication, wait-until-served against the replica, `update-apply` with
  `releaseId: published` on the core and on both members.
- NOT proved yet: a runtime-image or catalog publication, `store-install`, `module-add`, a failed step and its
  resume, the pkexec entry. Not there yet, as stated in D item (2) limit (a): the separate index for operating
  system packages appears at the first publication after this one. `isle store list` still prints the Python
  error on the members (the fix is not in 89). `test-apt-local-priority.py` was not run on the core (it starts a
  container there).

### Run 3, 2026-11-21 - LIVE-VERIFIED (packet `cli-release-90`; the per-release dependency index)
- The user typed ONE command, on the core: `sudo isle release run ~/isle-release-90`. Run id `7c80beaaa025`.
- Core: published 3 package files, read the release id `3ac16d2188ec`, waited until it was served, updated
  itself (operation `637adc7b...`), signed the approval (serial 1795284669). Package
  `polari-complete-offline 0.1.90+release90`.
- Members followed on their own timers, nothing typed there: econ and pol (operation `cb9705b0...`), both
  `isle-mesh-cli 0.1.210+release90` and `isle-app-store 0.1.90+release90`. The core's member table shows both done.
- Checked afterwards, read-only: `isle release status` = done on all three, on the core with the four verify URLs
  ok, `https://apt.isle/deps/noble/InRelease` among them. The main index of `apt.isle` lists 129 packages, every
  one `isle-*` or `polari-*`; `deps/noble/Packages` lists 1135 operating system packages and none of the isle's.
  `deps/jammy/InRelease` answers 404: no set for 22.04 is published yet (it comes after release 91, below).
  `isle store list` prints the store on both members, without the Python error. `isle release setting` =
  core-only.
- Proved now, beyond run 2: a second publication and update of all three devices from one command; the separate
  signed index for the operating system packages of one release (priority 2), made by the release-89 publisher.
- NOT proved yet: as after run 2 (a runtime-image or catalog publication, `store-install`, `module-add`, a failed
  step and its resume, the pkexec entry), and a `backup` step, the any-device intake, a dependency set in a
  packet. Not checked after this run: what the units step printed on pol.

What the packet was (written before the run):
- Built on pol from the isle CLI's dev (commit `adecf15`, the dev tip; third build, 2026-11-20 evening - the
  earlier ones were from `a45e0b7` and `6287d2a`). Three packages, as every CLI release:
  `isle-mesh-cli 0.1.210+release90`, `isle-app-store 0.1.90+release90`, `polari-complete-offline 0.1.90+release90`.
- Same shape as run 2: the core publishes the three files, every device does `update-apply` of the published
  release. One verify URL is added: `https://apt.isle/deps/noble/InRelease` answers 200.
- Checked: the CLI inside the combined package is file for file the dev tree; against release 89 the combined
  package has the same dependencies and a new version; `isle release check` with the installed release-89 CLI
  says the packet is valid (run id `7c80beaaa025`; the earlier builds' were `f58332896e64` and `b2a28893659b`).
- First release that carries: the storage listings, device classes and partition roles (`isle storage device
  list|register`, `partition list|assign|check`, `role list|show`); `isle storage units check|apply` and the
  rewrite of changed unit files at an update; the core-only denylist for storage moves; the setting that names
  the isle's Keycloak (`isle polari security provider`); the fix of `isle store list` on members.
  And since the rebuild: cutover's check of the router's managed-names list and `isle dns managed-names list`;
  the per-action numbering of migrate receipts; the proof that the hosting device's units run
  (`isle storage units prove`); the resume command printed by a failed operation; `isle backup` (device-backups)
  and the runner's step `backup`. The packet itself does not carry a `backup` step: the release-89 runner that
  reads it does not know one. The first packet that can take a device-backup before it changes a device is the
  one after this.
  And since the third build: the any-device intake (`isle release setting`, `isle release offer`, `isle release
  intake`, the core's timer - installed, never enabled by the package; "Step (2) built" below) and the isle-wide
  storage view (`isle storage role list --isle`; every device starts to report its partitions with a role).
  The setting stays `core-only` until someone changes it on the core, so this run itself is started on the core.
- What this run would prove beyond run 2:
  1. A second publication and update of all three devices from one command.
  2. The first publication made by the release-89 publisher, so the separate signed index for operating system
     packages (priority 2). The added verify URL is that proof: every device reads it after its own update.
  3. `isle store list` without the Python error on the members.
  4. The units step prints nothing and changes nothing on pol (release 90 changes no unit text).
- To know before the go:
  1. After this publication the main index of `apt.isle` lists only isle and polari packages. The operating
     system packages are listed under `deps/noble/` only. There is still no set for a 22.04 device, as before.
     An installed device needs none of them for this update: the dependencies are the same as in release 89.
  2. In run 2 the publisher's scan of the whole package store took about 20 minutes.
  3. Read in the code, not run: with no Keycloak named, the core's reconcile finds no changed setting and does
     not re-create the backend.
- After it is live, the storage proof of st-1 is typed on pol (STORAGE_ROLES_PLAN.md, section 5).

### Run 4, 2026-11-21 evening - LIVE-VERIFIED (packet `cli-release-91`; the first device-backups; a packet built by the verb)
- The user typed ONE command, on the core: `sudo isle release run ~/isle-release-91 --expect <run id>`. Run id
  `d09cdc9d7ff5`.
- Core: published 3 package files, read the release id `cc5ad46c66d2`, waited until it was served, took its
  device-backup ("taken and read back"), updated itself (operation `e9ce25fa...`), signed the approval (serial
  1795303958). Package `polari-complete-offline 0.1.91+release91`.
- Members followed on their own timers, nothing typed there: on econ and on pol first the device-backup step,
  then the update; both `isle-mesh-cli 0.1.211+release91` and `isle-app-store 0.1.91+release91`. The core's member
  table shows both done.
- Checked afterwards, read-only: `isle release status` = done on all three with the four verify URLs done; the
  three URLs and `deps/noble/InRelease` answer 200 over verified TLS from pol; the main index serves
  `polari-complete-offline 0.1.91+release91`; `isle release help` names `build` on the core and on pol (a verb
  that release 90 did not have). `deps/jammy/InRelease` still answers 404: the 22.04 set is the next packet.
  The user ran `sudo isle router key-status` on the core: the router's key is pinned and the router shows it.
- Proved now, beyond run 3: a `backup` step live on three devices (the first device-backups ever taken); a packet
  built by `isle release build` and run with `--expect`; a third publication and update from one command.
- NOT proved yet: a restore from a device-backup; a dependency set in a packet; a runtime-image or catalog
  publication, `store-install`, `module-add`; a failed step and its resume; the any-device intake; the pkexec
  entry. Not looked at: the content of the three device-backups (`sudo isle backup list` is the user's), and what
  the units step printed.
- The next build's `--previous` stays `~/isle-release-91-build/members` on pol: those are the packages now served.

What was written before the run:
- The user's go, 2026-11-21 evening: "go ahead on 91". The packet folder was copied to the core as
  `~/isle-release-91` (154 MiB). Checked there without sudo: every file matches `SHA256SUMS`, and the core's
  installed `isle release check` says the packet is valid with the same run id. Nothing is published or installed.
- The run, typed by the user on the core:

      sudo isle release run ~/isle-release-91 --expect d09cdc9d7ff5e000f5379121a31ded00b107965e863610e5a0f159b469286bd9

- What follows is as written when it was built and staged on pol.
- Built once, by the verb (`isle release build`, run from the checkout because the installed CLI is release 90
  and has no `build`), from the isle CLI's dev tip `60983b8`. About four minutes, no sudo, nothing published.
  Folder on pol: `~/isle-release-91-build` (`packet/`, `members/`, `build.json`, `build.log`, `source/`).
- Packages: `isle-mesh-cli 0.1.211+release91`, `isle-app-store 0.1.91+release91`,
  `polari-complete-offline 0.1.91+release91`. Run id `d09cdc9d7ff5`.
- Shape: the core publishes the three files; each of the three devices, named, first takes a device-backup
  (`backup`), then does `update-apply` of the published release. Four verify URLs, as in run 3. No dependency set.
- Checked: the verb compared the 504 files of the CLI in the commit, in the CLI package and in the combined
  package (byte for byte); the installed release-90 `isle release check` says the packet is valid with the same
  run id; against release 90 all three packages have the same dependency fields and the same install scripts;
  the `--previous` packages were the ones the core serves (sha256 against `https://apt.isle/Packages`).
- Found by the comparison: the release 90 CLI package, built by hand, carried a stray build folder
  (`shells/build/store-deb/`). A build from the commit does not pack it.
- To know before the go:
  1. No device-backup has ever been taken live. Step 1 on each device is the first one, run by the installed
     release-90 code (it differs from 91 in one line, the reading of a partition's roles). On the core and on pol
     the Polari instance is copied behind its write gate. `isle backup plan` says "Ready" on all three (300, 606
     and 257 MiB); no machine records a `backup` partition, so each goes to that machine's state folder.
  2. Order on the core: publish, wait until served, its own steps, then the signed approval. If the core's
     device-backup fails, release 91 is published but installed nowhere and no member is approved; the rerun
     resumes. A write gate left up is lowered with `sudo isle backup release-hold`.
  3. What release 91 changes for a running isle: the handoff, "Depends on the pin after release 91" (the name
     reconcile and the router reads connect only when the router's key is pinned; `sudo isle router key-status`
     on the core says whether it is).
- SUPERSEDED 2026-11-22 by the second build of the set (run id `5a504c42d504`, see "The 22.04 dependency set,
  second build" below); the packet named here was never copied to the core and is not to be run.
  After it is live on the core: the second packet, staged on pol too (`~/isle-dependencies-ubuntu-22.04-packet`,
  run `dependencies-ubuntu-22.04`, run id `ba41aff337b6`): the 22.04 dependency set alone, 927 package files,
  515 MiB, the two 22.04 members named so each asks for `deps/jammy/InRelease`. The installed release-90 CLI
  refuses it as a whole ("unknown kind"), as designed. The core needs 771 MiB free where it keeps its runs.

### Building the packet (`isle release build`) - SOURCE-TESTED (2026-11-21, isle CLI dev `a5cc690`), for release 91
Until release 90 the packet was put together by hand from a scratch script. It is a verb now, so the standard
steps of a CLI release are two commands: `isle release build` on a member, `sudo isle release run` on the core.

    isle release build <out-dir> --previous <dir> [--source <checkout>] [--commit <ref>]
        [--combined-builder <file>] [--device <name>]... [--verify <url>]... [--backup]

- Run as a normal user on a member that holds the isle root certificate (the store package carries it). About
  four minutes. Nothing is published and nothing on the isle changes.
- `--previous` holds the packages of the release before. The verb takes the next versions from them (CLI and
  store: patch and release number, each +1), rebuilds the CLI, the store and the combined package, and copies the
  packages that do not change.
- It builds from the commit (default: HEAD of the checkout the command runs from), not from the working files.
  Uncommitted files are left out, and how many is said and written into `build.json`.
- It compares every file of the CLI inside the CLI package and inside the combined package with the commit.
- The folder it writes: `packet/` (what `isle release run` takes; read back with the same check the run uses),
  `members/` (the `--previous` of the next build), `build.json` (commit, versions, sha256 of every package),
  `build.log`, `source/`.
- With no `--device` the packet is for every device ("*"); the stale member in the core's device list makes that
  wait, so name the devices. `--backup` puts a device-backup step before each device's update.
- It refuses, before it writes anything: root; a folder that is not empty; a `--previous` without exactly one CLI
  and one store package, or with two different release numbers; a commit that is not found; a missing combined
  builder; an unreadable root certificate; a device name or check address the run would refuse.
- Not a default: the check that one release's dependency index answers. For a release that should prove it, type
  `--verify https://apt.isle/deps/<release name>/InRelease`.
- Proof so far: 21 tests with fake packages, git and builders; 51 of 51 deliberate breaks caught; one trial with
  the real builders (a release 91 packet the installed `isle release check` reads as valid, 502 files compared).
- Owed: the build still needs the suite's combined builder beside the checkout.

### A packet can carry a dependency set - SOURCE-TESTED (2026-11-21, isle CLI dev `60983b8`), for release 91
The operating system packages one system needs offline (a dependency set) reach the core the same way a release
does: in a packet, by `sudo isle release run`. Nobody types a publication by hand.

    isle release build <out-dir> --dependencies <set dir> [--device <name>]... [--verify <url>]...
    sudo isle apt-repo publish --only-dependencies --dependencies-from <dir>     (what the run calls on the core)

- A packet may hold one entry `{"kind": "dependencies", "dir": "<dir>"}`. Every file of that folder is listed in
  the packet's `SHA256SUMS`; the run record holds one line for the folder, so the notice stays small and the run
  id still names every byte and every file name.
- The set has to say its one system with a file `<system id>.txt`, and the record of supported systems has to know
  it. Otherwise the packet is refused by `isle release check`, before anything changes.
- In the run the core adds the set first and alone (`--only-dependencies`: no isle package is looked for, and a set
  that holds an `isle-*` or `polari-*` package is refused, so the release the core announces cannot change). Then
  it waits until the index of that release lists every package file with its checksum and every file answers. Only
  then is anything else of the packet published. A rerun resumes at the step that stopped.
- The build verb has a second form for a set alone: no commit, no builder, no isle package. It checks the set
  (one known system, no isle package, only regular files, the same files as the set's own `SHA256SUMS`) and copies
  it into the packet. `--dependencies` can also be added to a release build.
- A packet with a set alone gives no device a step, and the runner asks a check without a device only of a device
  with steps. So the proof is the core's own wait; with `--device` each named device also asks for the index of
  the set, and `--verify` without `--device` is refused.
- Limits, said by the verb and in the README:
  1. The core's INSTALLED CLI runs a packet. A core older than this change refuses the kind and changes nothing.
     So the release 91 packet carries no set; the 22.04 set goes in its own packet after release 91 is live on the
     core. A member whose CLI is older refuses the run record: name only devices that are on release 91.
  2. The core copies a packet before it runs it: the size of the set and 256 MiB more must be free where it keeps
     its runs (the 22.04 set is 515 MiB).
- Proof so far: runner 115 tests, 14 of 14 deliberate breaks caught; publisher 25 tests, 4 of 4; build verb 27
  tests, 21 of 21; every isle CLI test file run (88 run, 0 failed; one needs the core and is skipped). One trial of the second form with the real 22.04 set
  (927 package files, 15 seconds), into a scratch folder; nothing was published.
- The CLI verb that builds a set is the next section (it was the hand recipe of section D).

### Building a dependency set (`isle os dependencies build`) - SOURCE-TESTED (2026-11-21, isle CLI dev `87d9a17`), for release 92
The set itself was still built by a hand recipe. It is a verb now, so the whole path is commands:

    isle os dependencies build <out-dir> --system <system id> --packages <dir> [--bundle-builder <file>] [--cache <dir>]
    isle os dependencies check <set dir>
    isle release build <out-dir> --dependencies <set dir>            (the packet; section above)
    sudo isle release run <the copied packet> --expect <run id>      (on the core, the user's go)

- `build` is run without sudo and publishes nothing. `--packages` is the folder `members` of a release build. The
  set is resolved in a fresh container of that system's image, from what the isle's own packages declare and from
  the offline package list, by the suite's `build-offline-bundle.sh` (beside the checkout, or `--bundle-builder`).
  Every file is checked against the size and sha256 the signed package index names. The set keeps only the files
  that list names; each is read again after it is moved.
- `--cache` is a folder of package files kept between builds. A file from it is used only with that size and
  sha256. Without it one system is about 500 MiB of fetching.
- Refused before anything is fetched or written: run as root; an out folder that is not empty; a system the
  record does not have; `--packages` with no package or with one that is not the isle's; no builder. A stopped
  builder leaves no set; its last lines and its log are named; the next build removes the work folder.
- `check` reads a set against its own lists (one system, no isle package, every package file the one
  `SHA256SUMS` lists and the one the resolve names, none missing, none added) and changes nothing.
- The offline package list is ONE record now, `isle-cli/apt/offline-packages.json` (`install`, `cacheOnly`),
  written with the names of the newest system. The suite's `build-offline-medium.sh` reads it
  (`supported_os.py offline-packages <system id> install|cache-only`) and no longer keeps the list itself. Its
  two lists come out byte for byte as before, for both systems, with and without `--closure` / `--cache-only`.
- Proof: 15 tests of the verb (fake builder, no network, no container), 3 more of the record code, 39 of 39
  deliberate breaks caught, every isle CLI test file run (89 pass; the one that needs the core is skipped).
  Two real runs on pol with downloading made impossible (a stand-in for `curl` that refuses):
  1. cache filled with a copy of the hand-built 22.04 set: 927 package files, 0 MiB fetched, the three lists of
     the resolve and every package file byte for byte the hand-built set. Only `SHA256SUMS` differs: same lines,
     now in byte order of the names. A packet was built from it into scratch and removed.
  2. empty cache: the builder stopped at the first file, the verb said so in 19 seconds and wrote no set.
- Limits:
  1. Release 91 is built already and does not have this verb. Until release 92 it is run from a checkout.
  2. The verb needs the suite's builder (and through it the framework's chunker and docker). It is a verb for a
     building machine, not for every member. Same debt as `isle release build` and its combined builder.
  3. Written 2026-11-21: the staged 22.04 packet (`ba41aff337b6`) stays the one to run. No longer so: the
     offline package list changed on 2026-11-22, the set was built again, and its packet (`5a504c42d504`) is the
     one to run. See the next section.

### The 22.04 dependency set, second build - STAGED on pol and on the core (2026-11-22), not run
The user, 2026-11-22: "yes to adding them to offline package, for ithers just go with your recommendations". "them" are
`smartmontools`, `fdisk` and the FUSE package, which the storage verbs use (isle CLI dev `b02e524`).

- The set: `~/isle-dependencies-ubuntu-22.04-r2` on pol, built by `isle os dependencies build` from a checkout,
  with the first set as its cache. 930 package files, 515 MiB. Three files more than the first set: `fdisk`,
  `libfdisk1`, `smartmontools`. `fuse3` was in the first set already. Fetched from the internet: under 1 MiB.
  An earlier note of this session said a rebuild fetches about 500 MiB; that is true only with an empty cache.
- The packet: `~/isle-dependencies-ubuntu-22.04-r3-packet/packet` on pol, run `dependencies-ubuntu-22.04`,
  run id `5a504c42d50424d7aefbe260eb8cb02c8225086eb3c208bf3e3d4484e86f6bc2`, 936 files. It names the two 22.04
  members, as the first packet did: no device has a step, and each of the two asks for `deps/jammy/InRelease`
  from where it is.
- A packet built first without naming a device (run id `fe33235a6075`) was replaced by this one before anything
  was run. In it only the core's own wait proved the set; no member asked.
- On the core: copied to `~/isle-dependencies-ubuntu-22.04-r2` and checked there with the installed CLI, without
  sudo ("Packet is valid: 936 file(s) match SHA256SUMS. Nothing was changed.").
- Not run. The run is the user's one command on the core. Today `deps/jammy/InRelease` answers 404 there.
- The CLI package of release 92 does not name `smartmontools` as a package it needs, so release 92 does not need
  this set first. They are two packets because two things in them were never seen live: a dependency set in a
  packet, and a publication of runtime images. One at a time shows which one failed.
- Owed: the 24.04 set on the core is older than the package list. Building it again needs the image
  `ubuntu:24.04` on the building machine and, without a cache of the 24.04 package files, about 500 MiB from the
  Ubuntu archive. Not done; both are downloads and wait for the user's word.

### Agent images in a release (`isle release build --agents`) - SOURCE-TESTED and built once for real (2026-11-22, isle CLI dev `7dadd52`), for release 92
Until now an update changed packages only. What an agent's proxy does is in the agent image, so a change to the
agent's scripts reached no machine (the upload size of an app, `STORAGE_ROLES_PLAN.md` 9.13, was the first such
change). A release can now carry the two agent images.

    isle release build <out-dir> --previous <dir> ... --agents [--all-images] [--runtime-archives <dir>]

- `--agents`: for the core's agent and the members' agent, take the image the isle runs now and put the commit's
  agent scripts on top, as one more layer. The new image is named `<repository>:release<number>`.
- It is made with the network switched off (`docker build --pull=false --network none`): nothing is downloaded,
  and no package inside the image changes. The image the isle runs comes from Docker on the building machine, or
  from the folder `--runtime-archives` names (the published `runtime/` folder; pol has a copy of it).
- An image whose scripts are already the commit's is not built again; the published one is kept.
- The packet gets a publication of kind `runtime` before the packages. The core publishes it
  (`isle update publish-runtime`), and each device takes its own image with its update: load, then its agent is
  started again from the new image, then a wait until it answers. This is the path every runtime image takes
  (`runtime_reconcile.py`); nothing new runs on a device.
- A row of an image that does not change can be written as "kept": its address under `apt.isle/runtime/`, its
  sha256 and its size, with no file in the packet. The core checks before anything is published that it serves
  that file with that size.
- `--all-images` puts every image into the packet as a file instead. **Release 92 needs it**: the core runs a
  packet with the CLI it has installed (release 91), and that CLI refuses a row without a file. Kept rows are for
  the releases after 92.
- Proof in source: 17 tests of the image code and 5 of the publication, more in the tests of the run and of the
  reconcile, 24 of 24 deliberate breaks caught, every isle CLI test file run at `73b7c58` (102 pass; the one that
  needs the core is skipped).
- Proof with real Docker on pol (27.3.1), by the real build of the release 92 packet:

  | Question | Seen |
  |---|---|
  | The layers of the new images | 17 each; the published ones have 16 |
  | Entrypoint, command, environment, ports, user, volumes | The same as the published images |
  | The scripts in the new images | Byte for byte the commit's; against the running images only `generate-nginx-configs.sh` differs |
  | A build with the network off, from an image that is only on this machine | Works |
  | `docker image save --platform` | Docker 27.3.1 does not know the option; the coded second try without it works |
  | The proxy of each new image, in a one-shot container with the network off, a made-up registry and made-up certificates | `nginx -t` passes (nginx 1.31.8). An app with no size: 2 MiB is refused (413). An app with `64m` and one with `0`: 2 MiB is passed on |

- Not seen: the images on a device of the isle. An agent started again by an update has not been seen since the
  agents became images of their own; this is what the run of release 92 tests.
- Each release that changes an agent script adds one layer to the image. After some releases the images should be
  built whole again; that build fetches packages (`apk add`), so it is a download and was not done.

### The packet of release 92 - STAGED on pol and on the core (2026-11-22), not run
- Built by `isle release build` on pol from isle CLI dev `73b7c58`, with `--backup --agents --all-images`, the
  three devices release 91 named, and `--previous` = the packages of release 91. No sudo, nothing published.
- `~/isle-release-92-build/packet` on pol: run `cli-release-92`, run id
  `05fd538ff7852587e38adbab2ba64fd034ebc0314b88337cbf0481a04092ce65`, 9 files, 1.6 GB.
- Versions: `isle-mesh-cli 0.1.212+release92`, `isle-app-store 0.1.92+release92`,
  `polari-complete-offline 0.1.92+release92`. The 537 files the CLI package packs are the same, byte for byte, in
  the commit, in the CLI package and in the combined package.
- The core publishes, in this order: the runtime images (the engine's two images as they are published today,
  1080 MiB and 238 MiB, and the two new agent images, 70 MiB and 71 MiB), then the three packages.
- Each of the three devices: a device-backup, then the update. With the update its agent is started again from
  the new image. The checks after it: the update list, `apt.isle/InRelease`, the engine's health address.
- The installed CLI of release 91 reads the packet as valid, on pol and on the core
  ("Packet is valid: 9 file(s) match SHA256SUMS. Nothing was changed."). On the core it is `~/isle-release-92`.
- The core needs 1461 MiB and 256 MiB more free where it keeps its runs; it has far more.
- The next build's `--previous` is `~/isle-release-92-build/members`. Do not build release 92 a second time
  unless the packet is thrown away: another build gives another run id.
- What release 92 carries, all source-tested only until the run: the storage verbs after release 91 (kinds,
  slots, the slot gate, the app upload size, `isle store build`, the registry release), the restore drill, the
  dependency-set verb, `isle release build --agents`, the 64m for the engine's address at the next
  `isle polari deploy`, and no home folder of one machine in the AppArmor profiles and two scripts.
- Order for the user, each one command on the core: first the dependency packet, then release 92.

## Proof packet 2 - for the user's review (2026-11-18). Packet 2a RUN 2026-11-20, see Run 2 above.

Purpose: prove what run 1 did not, with a packet that is also real work (CLI release 89).

| Part of the packet | What it carries | What it proves |
|---|---|---|
| `publish` kind `debs` | the CLI package of release 89 | publish-debs, the release id, wait-until-served on pol's replica |
| step `update-apply` `published`, on all three devices | CLI 89 installed by the run itself | update-apply on the core and on both members |
| `publish` kind `catalog` + step `store-install` | one store app at a new version | catalog publication, store-install with the manifest and image checks |
| step `module-add` | one module not yet on one instance | module-add |
| `verify` | the release notice, the repository `InRelease`, the api health URL (each must answer 200) | the verify list after real changes |

CLI release 89 = econ's 6ec5b78 (role refused before the sudo demand; "*" = devices heard from within 24 h) plus,
from pol: the apt pin, the two package indexes, the pin at bootstrap (section D) and the start setting (sections A
and B). After the run, on each device: `isle apt-repo pin check` answers "in place", `isle release setting` answers
core-only, and `isle release run` typed on a member without sudo names the setting and the core.

Resume, in two parts:
- Interrupted run: the user stops the command on the core during the wait for the replica and types the same
  command again. Expected: the publication is skipped as done, the wait continues, the run ends "done".
- Failed step: needs a fault that a second run can pass, without breaking anything. Proposed: a registered
  hot fix `proof-fail-once` (fails the first time on a device, passes the second, writes only its own marker),
  as one step on one member. Not built; it is runner code (econ's lane).

BUILT on pol and STAGED on the core, 2026-11-18 (the user: pol takes over the build; "implement those remaining
things for 89 and then rebuild"; then "stage it there"). Packet `cli-release-89`, run id `668a123d4f5f...`, in
the folder `release-run-proof-2` of the core's hand-over folder (a copy is `isle-release-89` in the home folder on
pol). `isle release check` answers valid on pol and on the core (4 files match). State: SOURCE-TESTED, built,
STAGED. Not published, installed nowhere, nothing live-verified. The user's one command on the core is owed.

| Package in the packet | sha256 (start) | For |
|---|---|---|
| `isle-mesh-cli` 0.1.209+release89 | `22d3b79c90ca` | the members (pol, econ) |
| `isle-app-store` 0.1.89+release89 | `98ede20f9f94` | the members; unchanged content, version only (it sets the version of the combined package) |
| `polari-complete-offline` 0.1.89+release89 | `c554420c6a0e` | the core |

Found while staging, and why the packet has three packages and not one:
- THE CORE TAKES ITS CLI FROM THE COMBINED PACKAGE. On the core `isle-mesh-cli` is not installed as its own
  package; the CLI files belong to `polari-complete-offline` (0.1.88+release88 before this run). `isle update`
  selects the combined package there (`update.py`, `selected_packages`). A packet with only the CLI package would
  have moved pol and econ to 89 and left the core on 88, with no two indexes, no setting verb and no notice key.
  A release that changes the CLI must always carry: the CLI package, the store package at the new release
  version, and the combined package built from them (plus the unchanged shell and `polari-isle` members).
- The full set was built on pol the way releases 87 and 88 were built on the core: CLI builder, store builder
  (same isle root certificate on pol and the core, compared by checksum), the shell package of release 86 and
  `polari-isle` 0.1.0 taken checksum-verified from the release 88 packet, then the suite's combined-package
  script, offline flavour. Compared with the published release 88 combined package: only the CLI files of this
  work differ, plus the version and the two maintainer-script changes for the pin. The store package differs in
  the version line only. The CLI files in the combined package equal the CLI package, and both equal the tested
  tree. Upgrade 88 to 89 of the combined package tried in a container without network: installs, pin in place,
  setting verb present.
- The verify URL of the first draft (`https://apt.isle/updates`) answers 404; the notice lives at the api. The
  packet now verifies the notice at the api, the repository `InRelease`, and the api health URL (all 200 today).
- Earlier builds (CLI sha256 `4f076c9c...`, `9f735269...`; run id `ff180434...`) are replaced and must not be
  used. The CLI package was rebuilt in the same build as the combined package, so its checksum changed; its
  content is the same tree.
- Not proven before the run: the update step on econ under its own blanket block on the isle source (the update
  installs the downloaded files by path with the device's own apt; a path install under that block passed in
  the pin test, in a container). The run itself is the live test.
- What 89 adds to release 88: econ's 6ec5b78; the apt pin; the main index without operating system packages and
  a dependency index per Ubuntu release; the pin written at bootstrap before any package work; the start setting
  (verb, notice key, the member's refusal). Details in sections A, B and D.
- Tests on pol, all on the tree the package was built from (the package content was compared file by file with
  the tree): release runner 106 passed; release notice 10; publication 19 (stand-in tools); index split 6;
  bootstrap pin all pass; apt pin all pass on apt 2.8 and 3.0; `test-apt-deps-index.py` (real publish, real apt,
  the real installer, no network) all pass on apt 2.8 (Ubuntu 24.04) and 3.0, with the host's apt 2.4 for the
  index checks; module record 4. `test-guided-join.py` has one failure that is the same on the commit before
  this work (not caused by it, not fixed here).
- Not tested: an Ubuntu 22.04 container (no such image on pol; pulling one needs the user's word), so on apt 2.4
  only the index, signature, by-hash and download were checked, not the installer. `test-apt-local-priority.py`
  cannot run on pol (it needs the offline installer medium on the core); it is owed on the core after the install.
- The package is built from the branch plus uncommitted work (16 files; a patch copy is beside the packet folder).
  The commit follows after 18:00 and must match the package content, else rebuild.
- `release_run.py`, `release.sh` and `release_notice.py` are econ's lane; pol changed them for the start setting
  on the user's instruction. Econ is to be told.
- The packages-only packet (2a) proves publication, wait-until-served, update-apply and the interrupted-run
  resume. Store install, module add and the failed step need a second packet (2b) once items 2 to 4 are settled.

Open before the packet can be written:
1. DONE (see above): who builds the CLI 89 package. Source for 89 is on pol only (branch `pol/apt-separation`,
   on no remote).
2. Which store app gets the new catalog version. Recommended: `board-engines` on econ (econ's example packet
   already describes release 2026.11.15-2 with manifest and image digest), or the twin door as a store app (still
   owed from round 88). Not the demo app `whoami`: its catalog entry names an outside image by a moving tag.
3. Which module on which instance. Checked 2026-11-18: pol's instance records 15 modules and `hal` is not among
   them, so `hal` on `polari-pol` is a real candidate. Still to check: that the released backend image carries
   `hal` (the hal work is partly not on dev).
4. `proof-fail-once`: build it, or prove the failed step later when a real one happens.

The user's part stays one command on the core: `sudo isle release run <packet>`.

## Next round (one packet, not one release per item) - PLAN, nothing built, for the user's review

### A. Start setting (econ's runner; pol's backend for the intake)
- The setting lives on the core, is changed only on the core by an isle verb, default core-only.
- IN RELEASE 89 (source-tested, see proof packet 2): `isle release setting` shows it on any device;
  `sudo isle release setting core-only|any-device` changes it, on the core only. The record is a root-owned file
  on the core; the release notice carries it as `startSetting` (written at once and again at every publication),
  so members read it where they already read the release. `any-device` is REFUSED with the reason until the
  core has the packet intake below; a hand-written `any-device` record is ignored. A member that reads
  `any-device` from a later core still refuses and says this CLI cannot hand a packet over.
- NOT in 89: everything below (the intake, the submission, the receipt entry).
- any-device: a member's `sudo isle release run <packet>` checks the packet, submits it to the core under the
  member's enrollment identity; the core re-verifies and runs what `run` does today. The core alone publishes and
  signs; members keep acting only on the core's signature. The submitting device is recorded in the receipt.
- Cost, stated: with any-device on, root on any enrolled member can deploy to the whole isle.
- Needs a way for the packet to reach the core, proof of which member sent it, and a root runner on the core.
  See "Any-device intake" below: PARKED 2026-11-18, three decisions wait on the user.

#### Any-device intake - decisions answered 2026-11-20; built as "Step (2)" below (source-tested), nothing live
- What was built first, and why it was dropped. Pol built the core's side as four hand-made backend routes in the
  islemesh module plus a private database file for the submissions, and the CLI side against them (source-tested
  only: runner tests 106 of 106, intake tests 13 of 13, backend selftest 102 of 102). The user, 2026-11-18: "do not
  duplicate those capabilities we have already automated away, you should not be messing with falcon since the
  polari engine handles automating api creation and networking them. If you create them manually it is likely to
  cause problems". The routes and the private database are removed from the framework worktree (branch
  `dev-release-intake` is back to dev). Copies are kept on pol in `~/isle-intake-parked/`, outside every repository.
- What stays valid, whatever carries the packet (CLI side, `isle-cli/scripts/release_intake.py`, uncommitted): the
  core acts only on its own root-owned setting; the sender must be a listed member; the copied files are checked
  (exact set, no links, sizes, sha256); the full packet check runs again on the core; the run id must be equal;
  one run at a time under the run lock; the receipt names the submitting device (`submittedBy`); a timer verb
  `sudo isle release intake run [--auto]`. The transport part of that file must be rewritten.
- The engine way, as far as it reaches today. A submission is one row class (`IsleReleaseSubmission`) in
  `objects/islemesh/`, listed in the module's `polari-app.json`. The engine then creates the table and the
  create/read/update/delete door for it. No route and no database of pol's own.
- Measured on the core, 2026-11-18, read-only:
  - The engine's generated doors are live there and answer without any credential (`IsleStorageReceipt`,
    `IsleDevice`: 200). The permission gate is off (`POLARI_APP_PERMISSIONS` unset), there is no identity provider
    and no file store in the core's Polari instance.
  - A release packet is 154 MB (release 89). Rows are the wrong place for that; the engine's place for bytes is
    its file store, which the core does not run.
  - The fingerprint of a member's enrollment credential is stored in rows any device in the isle can read, and it
    is the same value the core's member list holds. A field in a row therefore cannot prove which member wrote it.
- Second cost, stated: whatever software carries the packet on the core becomes part of what a release trusts,
  unless the packet itself is signed by the sending device.
- Three decisions for the user. Nothing of the core's side is built until 1 and 2 are answered.
  1. How the core knows which member sent a packet.
     (a) A key pair per device, certified by the isle root at enrollment; the member signs the packet. The carrier
         then needs no trust at all, and the second cost above is closed. No device key exists today: enrollment,
         the member list and a re-enrollment step for the three devices would change.
     (b) The engine's permission gate switched on in the core's instance, with an identity per device. Needs an
         identity provider on the core, which it does not run.
     (c) The engine's own node-to-node consent record (`PeerAgreement`: approved by the parent, one revocable
         token per child, only the hash stored). Fits if each member's local Polari node is the sender. The
         second cost stays.
     Pol's recommendation: (a).
  2. How 154 MB travel.
     (a) The engine's file store added to the core's Polari instance (one more service on the core, and its
         data needs a storage role - priority 3).
     (b) The member's own local node offers the packet and the core fetches it (members would have to serve; today
         only the core serves).
     With 1(a) either one is safe, because the core checks the signature after the copy.
  3. Separate from releases: the generated doors on the core accept writes and deletes from any device in the isle
     without a credential. Whether that stays as it is, is the user's call.
- The user, 2026-11-18, on decision 1 (verbatim): "keycloak should be the identity provider we should not require
  identity provviders to have base functionality though since in some cases we are only running the isle privately
  with no external exposure".
  - What it settles: where an identity is needed, it comes from Keycloak, through the engine's own gate. That is
    1(b). Pol's recommendation 1(a) (a key pair per device) is withdrawn: it would build a second identity system
    beside the one the engine already has.
  - What must keep working with no Keycloak anywhere: everything an isle does today - enrollment, updates, the
    store, storage, and the release run started on the core (`core-only`, the default).
  - Pol's reading, NOT yet confirmed by the user: `any-device` is an addition that needs Keycloak on the core's
    instance and the gate switched on; on an isle without Keycloak, `isle release setting any-device` is refused
    with that reason and `core-only` is unaffected. The other reading (any-device must also work without
    Keycloak) would need a second proof of the sender and is not planned unless the user asks for it.
  - Decision 3, pol's reading, NOT yet confirmed: the gate stays a setting. Off on a private isle (as today);
    switched on together with Keycloak where the isle is exposed.
  - The user, right after (verbatim): "we already have a keycloak app configured to be our identity provider".
    Found, and to be used as it is: the suite's Keycloak (`polari-rf-node/prf-keycloak`, realm import included;
    it runs on pol today; in `pol prod` it is the answer "logins = keycloak or off", on the lean stack the
    compose profile `logins`), the engine's side of it (token check, permission gate, the `security` module), and
    on the isle side `isle polari security status|enable|disable|require --feature <name>|release`, where a
    feature that needs sign-in declares itself. Any-device would be one such feature
    (`require --feature release-any-device`). Nothing of this is rebuilt.
  - Measured 2026-11-18: the core's own instance is the lean one, with no Keycloak by design, and the isle store
    on the core lists no Keycloak app.
  - Still open: decision 2 (how the bytes travel), and which Keycloak the core's instance should trust (the one on
    pol, or one beside the core's instance) and when it is switched on (a deploy; none without the user's go).
- Release 89 is not touched by any of this: `any-device` is refused there, as tested.
- The user, 2026-11-20, on the open points:
  - How the packet travels (verbatim): "Core fetching that way we do not necessitate the core having large storage".
    So 2(b): the member's node offers the packet and the core fetches it. No file store on the core for this.
  - Which Keycloak (verbatim): "we should be able to configure which keycloak we trust but it should be able to be
    anywhere on the isle, we should not need more than one keycloak instance for now, just specify one". So: one
    Keycloak for the isle, named by a setting, on any device. Today that is the one on pol.
  - Pol's two readings above (any-device needs Keycloak and is refused without it; the gate stays a setting) were
    left to pol ("The rest I defer to your decisions") and stand.
  - Lanes (verbatim): "Don't be worried about econ they are on totally different tasking now, there are no split
    concerns right now". Pol works in the runner files as needed; nothing is owed to econ for it.
  - OVERTAKEN the same evening, see "The user, 2026-11-20 evening" below: any-device does not need Keycloak.
  - Owed next, in this order: (1) the setting that names the isle's Keycloak, read by `isle polari security`;
    (2) the submission as an engine row class, the member's node offering the packet, the core fetching and
    checking it; (3) `isle release setting any-device` allowed once (1) is set, refused with the reason otherwise.
    Switching the gate on in the core's instance is a live change and waits for the user's go.

- The user, 2026-11-20 evening (verbatim): "We do not require keycloak for releases unless it is enabled and
  required by security settings for the isle. The default can just be that you are required to run the release
  command from the core."
  - So pol's reading above is withdrawn. The default stays `core-only`. `any-device`, once the intake exists, works
    on an isle with no Keycloak. Sign-in is asked of a release only where the isle's security settings both switch
    Keycloak on and require it for releases (`isle polari security require --feature release-any-device`).
  - Changed in the code for this (isle CLI dev `6287d2a`, source-tested): `provider none` is no longer refused
    because the start setting is `any-device`.
  - Still to build, with the intake (step 2): the core's check of a submission asks for a signed-in sender only
    when that requirement is set. Open in it: the requirement is written today into one frontend's settings file
    named by hand (`--config`), so the core has no single place to read "releases need sign-in" from; the intake
    needs one. And `any-device` stays refused until the intake exists.
  - Without sign-in, what proves which member sent a packet is the open point it was on 2026-11-18 (the claim that
    the enrollment identity can carry it has to be checked in the code before anything is built on it).

#### Step (1) built: the setting that names the isle's Keycloak (2026-11-20)

State: **source-tested** on pol, on the isle CLI's dev. In no release, installed nowhere, nothing live changed.

    isle polari security provider                                    show it (core: its record; member: what the core publishes)
    sudo isle polari security provider <https://host/realms/name>    name it (core only); --client <id> when it is not polari-frontend
    sudo isle polari security provider none                          name none (core only)

- The record is one file on the core, `/etc/isle-mesh/identity/provider.json`: issuer, realm, address of the
  signing keys, client id, when and on which device it was set. No secret is in it.
- Naming one checks, in this order and before anything is written: this device is the core; the address is HTTPS,
  has no user name, query or fragment and ends in `/realms/<name>`; the Keycloak at that address answers its
  discovery document over verified TLS (no redirect followed) and names itself with exactly that address; its
  signing keys are offered over HTTPS on the same host. Then it asks for sudo by naming the full command.
  The address is kept letter for letter as typed, because a sign-in token must name it letter for letter.
- Members learn it from the core's release notice (key `identityProvider`, served unchanged by the engine at
  `/api/islemesh/updates`), the same way they learn the start setting. Each publication carries it again.
- `none` was refused while the start setting is `any-device`; that refusal is removed (the user, 2026-11-20
  evening: releases do not need Keycloak unless the isle's security settings switch it on and require it).
- Who reads it:
  - a backend deployed with `isle polari deploy` is given `POLARI_KEYCLOAK_ISSUER_URI`, `POLARI_KEYCLOAK_JWKS_URI`,
    `POLARI_KEYCLOAK_REALM` and `POLARI_KEYCLOAK_FRONTEND_CLIENT_ID` (the names the engine reads);
  - the core's own backend is given the same at an update (the runtime reconcile);
  - `isle polari security enable|require` write address, client and realm into the frontend's file first.
- What it does not do: it switches no rule on. The engine's sign-in check never rejects a request by itself, and
  the permission mode (`POLARI_APP_PERMISSIONS`) is not touched and stays off.
- Files (isle CLI): `identity_provider.py` (new), `test-identity-provider.py` (new, 29 tests, a fake device and a
  fake Keycloak, no network; 18 of 18 deliberate breaks caught), small changes in `polari.sh`,
  `polari-security.py`, `polari-component-config.py`, `runtime_reconcile.py`, `release_run.py` (the notice writer
  may replace this one more key), `release_notice.py`, `test-runtime-reconcile.py`, `README.md`.

Not done and not proven (said plainly):
- The core's own backend takes the setting at the next `sudo isle reconcile` (read in the code and in the core's
  published release, which lists that backend; not run). A backend on another device keeps what it started with
  until its instance is deployed or updated; no verb re-creates it on its own.
- Whether a backend container can fetch the signing keys (trust bundle and isle DNS inside the container) has not
  been tried against a real Keycloak. No Keycloak runs on the isle today.
- The sign-in switch on the Isle App's page (`security-toggle.py`) does not read the setting yet; only the CLI does.
- The redirect addresses a Keycloak client must allow for each instance frontend are not handled.

Found in the engine while mapping this, bearing on steps (2) and (3):
- The engine has no way to say "this one API needs a signed-in sender". The permission gate is one mode for the
  whole instance: `off` (today: everything open), `advisory`, or `enforce` (everything refused unless a permission
  profile allows it). So "the core's submission API needs sign-in, the rest of a private isle stays open" cannot be
  expressed today. It needs an answer inside the engine's permission model (a per-class rule, as owner-defined
  permissions already are per class), never a hand-wired check.
- How a member's CLI obtains a sign-in token for the person typing the command is not designed (a browser sign-in
  on the device, or Keycloak's device flow).
Both are questions for the user before step (2) is built.

#### Step (2) built: a member offers its packet, the core fetches and runs it (2026-11-20)

State: **source-tested** on pol, on the isle CLI's dev (`b58242d`). In no release, installed nowhere, nothing live
changed. The part that serves the packet on a member has never been started in a container (see "Not proven").

What the person types, and nothing else:

    sudo isle release setting any-device       core, once: allow it (prints the cost; switches the core's timer on)
    sudo isle release run <packet-dir>         member: check the packet, offer it, wait for the core's answer
    isle release offer                         member: what this device offers, and what the core answered
    sudo isle release offer withdraw           member: take the offer down and remove its copy
    isle release intake                        any device: whether the core takes packets, and its answers
    sudo isle release intake run               core: look at the members now (the timer does this every minute)
    sudo isle release setting core-only        core: back to the default (switches the timer off)

How it works, in order:
1. The member checks the packet exactly as the core would (`isle release check`), shows the summary and asks for
   the confirmation. It copies the packet, root-owned, into its state folder and checks the copy again.
2. The member serves that copy as an ordinary isle app named `release-offer-<its paired name>`, through the same
   verb every app uses (`isle app deploy`, staged). The server is the nginx inside the device's own running agent
   image, read-only, GET only. No image is pulled and nothing is installed.
3. Every minute the core's timer looks. For each member in the certificate authority's member list it asks the
   authority's record who was issued the name `release-offer-<member>.isle`. Only when that is the same member does
   it fetch, from the address the router leased to that member, over TLS checked against the isle's root, with no
   redirect followed and a size limit per file.
4. The core checks what it fetched (exactly the offered files, plain files only, sizes), runs the full packet
   check again, and compares the run id with the offered one. Then it runs the packet the way `isle release run`
   on the core does, under the same lock. The receipt names the offering member (`submittedBy`).
5. The core publishes its answer (`taken`, `running`, `done`, `failed`, `refused`, with the last lines of the run)
   in its release notice. The member reads it there, prints it, takes the offer down and removes its copy. Exit 0
   only for `done`. After 30 minutes without a final answer the command ends with exit 3 and the offer stays up;
   the same command picks it up again.

The user's rulings this follows: the core fetches, so the core needs no large store ("Core fetching that way we do
not necessitate the core having large storage"); core-only stays the default; no Keycloak is needed unless the
isle's security settings switch it on and require it; no machine name is written into the code (every name comes
from the pairing record, the authority's lists and the router).

Pol's own choices, for the user to correct:
- What proves which member offers: the certificate authority issues a service name to one paired member only and
  the key never leaves that member. So a TLS answer under `release-offer-<member>.isle` can only come from that
  member. This uses the enrollment that exists; it adds no key, no token and no second identity system. The
  authority now also refuses to issue a `release-offer-` name to anyone but the member it names, so no device can
  block another's offer by taking the name first.
- No hand-made backend route and no backend change at all: the engine already serves the whole release notice to
  members, and the answers travel in it under the key `intake`.
- The offer is not yet an engine row. A row class (`IsleReleaseOffer`) belongs to the Isle App step, when a page
  has to list offers; the CLI does not need it.
- One packet per pass, members in name order. A take that is interrupted is tried again 3 times, then answered
  `failed`. A final answer is never taken again; offering again makes a new offer.

The cost, as the setting prints it: with any-device, root on any paired member can release to the whole isle. The
core checks which member offers a packet and that the packet is intact; the review is done by the person typing
the command on that member. While a packet is offered, every device on the isle can read its files from that member.

Sign-in for releases - the first half BUILT 2026-11-21 (source-tested, for release 91); the user accepted the
recommendation that day ("everything else do as you say", "the rest as you recommend").
- Where it is said: the isle's Keycloak record on the core gains the list of what needs a signed-in person. One
  place, written by root on the core, published in the notice with the rest of the record.
      sudo isle polari security provider require releases
      sudo isle polari security provider unrequire releases
  `isle polari security provider` shows the list on the core and on a member. `releases` is the one name today.
- Nothing is required until it is named, and it cannot be named before a Keycloak is. `provider none` is refused
  while the list is not empty; naming another Keycloak keeps the list.
- What it does today: an offer cannot carry a sign-in yet, so while releases are required the core answers every
  offer `refused` before it fetches anything, `isle release setting any-device` and `isle release intake` say so,
  and a member is told before it offers. The release is then started on the core.
- A release typed on the core is not asked for a sign-in. Sudo on the core is what allows it, and the CLI has no
  way to carry a token yet: asking for one there would lock releases out of the isle.
- A record the core cannot read counts as required (no offer is taken), never as "nothing required". A name in
  the list that this CLI does not know is kept, not dropped, so an older CLI does not lose a requirement.
- `isle polari security require --feature release-any-device` (one frontend's settings file) is unchanged and is
  not what the core reads.
- NOT built, the second half: how the person typing on a member signs in (a browser sign-in on the device, or
  Keycloak's device flow), how the offer carries the token, and the core checking it against the named Keycloak.
  Until then "required" means "from the core only".
- Proof: `test-identity-provider.py` (40 tests) and `test-release-intake.py` (23), 25 of 25 deliberate breaks caught.
  Not tried against a real Keycloak; none runs on the isle today.

Not proven, and owed:
- The offer server has never run. Starting a container on pol was not permitted in this session, so the first
  real proof is on a member, at the user's go: that nginx in the agent image starts with the written settings and
  that the agent routes the name to it.
- A member in offline mode can only start images its offline rule accepts. Today only the core is offline, and the
  core never offers. Not handled for a future offline member.
- Done 2026-11-20 evening (source-tested): where the core asks for a member. First the address the member's agent
  reported to the core's device list (every app deploy reports it, so it is fresh when an offer goes up); the
  router's leases only for a member the list has no usable address for. Either one only says where to ask; the
  certificate of the offer name proves the member. `setting any-device` is allowed when one of the two can be read.
- An offer whose member is switched off stays recorded on that member until `offer withdraw` or the next run there.
- Taking an offer down depends on the app removal check answering; if it does not, the command says so and the
  offer stays up.
- While any-device is on, the core asks once a minute every member that ever put an offer up (it holds the offer
  name); the router is asked only then. The offer shows as an app in the topology while it is up.
- Done 2026-11-20 evening (source-tested): the lease lookup reads the router's address from the core's own record
  of its network (`host_network.management_gateway`), no longer a value written in `storage_core.py`. Still from
  before this work, and a finding for the user: the lookup's ssh to the router does not check the router's host
  key, and other scripts of the isle CLI (`security.sh`, `scan.sh`, `dns-reconcile.sh`, `router.sh`, `create.sh`,
  `dns-register.sh`) keep a fixed router address as their default.
- Fixed 2026-11-20 evening (source-tested), found by a new test: a packet that was replaced by another valid one
  while the member copied it left its copy behind on the member. The copy is now removed whatever stops the offer.
- The last lines of a run are published to the whole isle in the notice. They are the lines `isle release run`
  prints; no secret is printed there today, and it has to stay that way.
- The Isle App's warning (section B) for this setting is not built.

Files (isle CLI): `release_offer.py` (new, the member's half), `release_intake.py` (new, the core's half),
`test-release-intake.py` (new, 17 tests: both halves against each other over a fixture isle - no network, no
docker, no sudo; 18 of 18 deliberate breaks of the checks caught, and 11 of 11 of the address lookup's), `isle-release-intake.service` and `.timer` (new; the package never enables the timer by
itself), changes in `release_run.py`, `release_notice.py`, `release.sh`, `cert-authority.py`, `storage_core.py`,
`build-cli-deb.sh`, `destroy.sh` and their tests. Runner tests 107 of 107, authority tests 6 of 6. All 83 test files
of the isle CLI exit 0 on pol except `test-apt-local-priority.py` (it needs a Docker bind source pol does not have).

Release 90, staged on pol, carries this since its third build (from `adecf15`). It changes nothing by being
installed: the setting stays `core-only` and the core's timer is not enabled until `sudo isle release setting
any-device` is typed on the core.

#### Fixed or checked on the way (2026-11-18)
- `isle store list` Python error (section D): fixed in the worktree with a test (`test-store-list.py`),
  source-tested, uncommitted, NOT in release 89.
- `hal` for the module-add proof of packet 2b: the backend image of pol's isle instance already contains the `hal`
  module; it is not among the 15 switched on. A module add needs no new image.
- Files of econ's lane changed by pol and still to be told to econ (held for the user's word): `release_run.py`,
  `release.sh`, `release_notice.py`, `test-release-run.py`.

### B. The warning (CLI now, Isle App with the page)
- Release 88 fault: on a member, without sudo, `isle release run` answers "Type: sudo isle release run ..."; the
  core-only refusal is reached only with sudo. Fix: role and setting are checked before the sudo demand; the
  message names this device and the core.
- Members read the setting from the core (it rides the release notice they already read). It decides the wording
  only; the core's intake enforces it.
- IN RELEASE 89 (source-tested): the member's refusal follows the published setting, in three cases: the value
  is known; the core did not answer (refused, and it says so); any-device but this CLI cannot submit.
- Isle App: the start control on a non-core device is disabled with the same words while the setting is core-only.
  NOT BUILT. The value is in the release notice the app already reads, so the page needs no new door.

### C. Storage devices and units (pol leads storage)
- `isle storage device`: allocate a device to the isle for a named purpose, list (purpose, mount, free space,
  health, datasets and units carried), retire.
- `isle storage units check|apply --dataset <name>`: compare the units on the device with what the CLI renders,
  rewrite, prove the sync starts. Run after every `isle update apply`; a release-run step kind.
- `isle hotfix storage-units` then keeps only the two one-off actions (the symlink, the hand drop-in).
- Roles on partitions (the user, 2026-11-18): a role is assigned to a partition, a partition may be a whole
  device, and one role may be split across several partitions. The full storage design now lives in
  `STORAGE_ROLES_PLAN.md` (revamped the same day); this section keeps only the two verbs above.

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
  - Item (1), SOURCE-TESTED 2026-11-18 (Isle-Mesh branch `pol/apt-separation`, commit 01debe6, on pol only, not
    built as a package, not installed anywhere): the pin file `isle-mesh.pref` (isle-* and polari-* at 500,
    everything else from origin isle-mesh at -1); `isle apt-repo enable` writes it before the source line; new verb
    `isle apt-repo pin check|apply`; `isle apt-repo status` reports source line and pin; the CLI package writes it
    on install, purge removes it; `isle apt install` does not read host pins (it is the one reader of the offline
    set). Test `test-apt-isle-pin.py`, real apt with no network: without the pin the foreign library is the
    candidate; with it a full upgrade leaves the library alone, upgrades the isle package and has no candidate for
    a foreign-only package. Same result on apt 2.4 (the members' version, candidates only), 2.7 and 3.0. The test
    fails when the pin's isle record or the installer's two lines are taken out. A throwaway package built from
    the branch, in a container with no network: install writes the pin, remove keeps it, purge removes it.
  - Checked against the live index the same day: 9 first-party package names, all `isle-*` or `polari-*`.
  - Where the source line is on today: the core (24.04, no pin; same release as the offline set, so not exposed)
    and econ (22.04, behind the recovery block). Pol has none.
  - Econ's recovery block and the pin work together: block alone = no candidate for anything from the source,
    isle packages included (installs by file path and by named version still work); block plus pin = isle and
    polari packages are candidates again, everything else stays blocked.
  - Known limits of item (1): a named version (`apt install name=version`) still installs from the source; with
    the pin, `isle update apply` gets missing Ubuntu dependencies only from Ubuntu's own archive.
  - Item (2), IN RELEASE 89, SOURCE-TESTED 2026-11-18 (same branch, uncommitted until 18:00): `isle apt-repo
    publish` scans once and writes two signed indexes. The main index (what the source line reads) lists only
    isle-* and polari-* packages, by the same name rule as the pin. Every other package goes to
    `deps/<Ubuntu release name of the core>/`, with its own origin (`isle-mesh-deps`), signature and by-hash
    files; the package files stay where they are. Both indexes are built before either is put in place, the
    dependency index first. Publication is refused, repository unchanged, when the core's release name cannot be
    read. `isle apt install` adds the dependency index only for the device's own release: the core from its
    disk, a member after asking the core over verified TLS whether `deps/<its release>/` is served (the live
    core answers 404 for a missing path, checked). A device of another release is never offered it. The pin now
    applies inside `isle apt install` too; the one exception is a core whose repository still has the single old
    index (before its first publication with 89), where its own dependency packages are still in that index.
  - Bootstrap, IN RELEASE 89, SOURCE-TESTED: `isle-bootstrap.sh` writes the pin right after it trusts the archive
    key, before the source line and before any package work, on the join and on the update path. A test holds
    the embedded copy equal to `apt/isle-mesh.pref` and the order.
  - Item (3) is covered by item (2): the release the set was built for is the directory name, and the installer
    asks for its own release only. No separate check verb was built.
  - Limits of item (2), stated: (a) the two indexes appear on the core only at the first publication AFTER the
    core runs 89 (the run that ships 89 still publishes with 88), so until then the pin is the only guard;
    (b) from that publication on, a member still on CLI 88 gets no operating system packages from the core
    (its installer reads the main index only) until it runs 89; (c) a 22.04 member gets no dependency set at
    all (none is built for 22.04): missing dependencies come from Ubuntu's archive or the offline medium, as the
    pin already made it; (d) every dependency package in the repository is filed under the core's CURRENT
    release, so after an operating system upgrade of the core the old ones would be filed wrongly until the
    offline set is rebuilt; (e) a device's own blanket block on the isle host (econ's recovery block) also
    blocks the dependency index there.
  - Supported operating systems and one set per release, SOURCE-TESTED 2026-11-21 (the user's ask: "We should
    record the different OS's we are supporting and variations in the apt seperation."; Isle-Mesh dev `26665f0`,
    for release 91; installed nowhere):
    - The record is the file `isle-cli/apt/supported-os.json`: per system its release name, architectures, how far
      it is proven as a core and as a member (live-verified / source-tested / not proven), the image a dependency
      set is resolved in, the apt and python versions, the package names that differ, and the place every value
      was read. Today: ubuntu-24.04 (noble; core live-verified, member source-tested) and ubuntu-22.04 (jammy;
      member live-verified, core not proven). Three names differ on 22.04: `libgtk-3-0t64` is `libgtk-3-0`,
      `libasound2t64` is `libasound2`, and `systemd-resolved` is part of `systemd`.
    - Verbs, all read-only: `isle os list` (the record), `isle os check` (this machine: its system, whether the
      record has it, whether the core serves a set for its release; exit 1 when it is not in the record),
      `isle os devices` (what every machine of the isle last reported). Every machine adds `host.os_release` and
      `host.os_codename` to the device report it already publishes; Polari reads the same rows.
    - Limit (d) is closed in source: `isle apt-repo publish --dependencies-from <dir>` files the set under the
      release it was built for - the one typed with `--dependencies-release`, else the one the directory is
      marked with (`<system id>.txt`, as the offline medium writes it), else the core's own release. A release that
      is not in the record, a directory marked for two systems, and a typed release that differs from the mark are
      refused with the repository unchanged. A later publication keeps every package file in each
      `deps/<release>/` index that already lists it, so the noble set stays when a jammy set is added.
    - Limit (c), half done: a 22.04 set is BUILT and STAGED on pol only (2026-11-21; 927 packages, 539 MB, every
      one checked against Ubuntu's signed index; `ubuntu:22.04` image, permitted pull). The first try failed on
      `systemd-resolved`, which is how the third name difference was found. It must NOT be published by a core
      older than release 91: release 89 and 90 would file it under noble. So: release 91 first, then the set.
    - Done 2026-11-21 (isle CLI `385b9f5`, pol CLI `f2150ee`, source-tested): the suite's two offline builders
      and the two checks of a medium read the record (`supported_os.py base-image|package-names <system id>`)
      instead of naming the two systems themselves. The medium builder had two of the three name differences
      by hand; it now gets all three from the record.
    - Owed: a release packet cannot carry a dependency set yet (the publication step passes no
      `--dependencies-from`), so after 91 the set is one typed publication or a new packet kind; no `pol` or
      `isle` verb builds a dependency set (it is `build-offline-bundle.sh` by hand);
      `test-apt-local-priority.py` on the core; part F of `test-apt-deps-index.py` needs an image with python3.
- `isle store list` on pol (CLI release 88) prints a Python error (`KeyError: 'provides_engine'`) before the list.
- The core's device list holds a stale member (last seen 2026-11-06). A packet addressed to "*" would sign it into
  the approval and wait on it until the limit. Needs a verb to retire a device, or "*" limited to recently seen ones.
- Round-88 items still open: the twin door as a store app with a catalog row. The core-only denylist is built
  (2026-11-20, isle CLI dev, source-tested; goes out with the next release; STORAGE_ROLES_PLAN.md, after the step table).
- Backend: one-shot twin runs accept only a twin local to the backend (TWIN_DOOR_PLAN, worker 15-2 section).

### E. Operating system overwrite - a separate kind of update (the user's ruling, 2026-11-18) - PLAN, nothing built
SHELVED by the user on 2026-11-22: the isle keeps the two systems its machines run now (Ubuntu 22.04 and 24.04);
updating a system comes later. The longer plan is shelved/OS_OVERWRITE_PLAN.md. This section is the short version.

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

