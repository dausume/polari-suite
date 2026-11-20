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

#### Any-device intake - decisions answered 2026-11-20 (see the end of this section); nothing built, nothing live
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
  - Owed next, in this order: (1) the setting that names the isle's Keycloak, read by `isle polari security`;
    (2) the submission as an engine row class, the member's node offering the packet, the core fetching and
    checking it; (3) `isle release setting any-device` allowed once (1) is set, refused with the reason otherwise.
    Switching the gate on in the core's instance is a live change and waits for the user's go.

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
- `none` is refused while the start setting is `any-device`.
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
- `isle store list` on pol (CLI release 88) prints a Python error (`KeyError: 'provides_engine'`) before the list.
- The core's device list holds a stale member (last seen 2026-11-06). A packet addressed to "*" would sign it into
  the approval and wait on it until the limit. Needs a verb to retire a device, or "*" limited to recently seen ones.
- Round-88 items still open: the twin door as a store app with a catalog row. The core-only denylist is built
  (2026-11-20, isle CLI dev, source-tested; goes out with the next release; STORAGE_ROLES_PLAN.md, after the step table).
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

