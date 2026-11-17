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

### D. Findings to fold in
- The core's device list holds a stale member (last seen 2026-11-06). A packet addressed to "*" would sign it into
  the approval and wait on it until the limit. Needs a verb to retire a device, or "*" limited to recently seen ones.
- Round-88 items still open: the twin door as a store app with a catalog row; the core-only denylist.
- Backend: one-shot twin runs accept only a twin local to the backend (TWIN_DOOR_PLAN, worker 15-2 section).
