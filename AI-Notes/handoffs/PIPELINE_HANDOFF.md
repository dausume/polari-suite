# Handoff — the Polari pipeline (2026-09-21): where it stands, the uninstall plan, what remains, and the deployment-target design

_For the next session. The pipeline arc (ci-7 … ci-13, ledger §70–§78) is BUILT and PROVEN on the home devices:
econ-core is the pipeline device, isle-core the throwaway-isle target. Read this file first, then ledger §75–§78
for the live evidence. Rules that hold: security WARN-ONLY; the tested-only release rule; latest-wins queues; keep
the CLI, the shell (Java) and the Polari pages logically separate; people keyed by Keycloak `sub`; no real
identifiers in tracked files; **keep agents to a few** (his rule 2026-09-20 — do small and medium work directly)._

## 1. State on 2026-09-21

| piece | state |
|---|---|
| branch model | `dev` iterate → `pol jenkins promote test` → `polari-test` (wipe, build, advisory scans, 89 device suites, isle stages, ONE verdict per sha) → `pol jenkins promote main` (refuses without a `passed` verdict) → `polari-release` (build, tested == released by image id, publish to the ARMED routes) |
| first passed verdict | `04051ff` — passed WITH WARNINGS (the isle uninstall, by his ruling a warning: `CI_UNINSTALL_GATE=warn`, default) |
| first promotion to main | done by him 2026-09-21 (all ten repos, ff from test); GitHub bypassed its PR rule for his account as before |
| first automated release | `polari-release #209` FAILED in the optional offline medium (`No module named appstore.offline_chunker` — the module moved to `appstore.custom`; fixed on dev `212214a`, reaches main on the next cycle); `#210` re-running with `CI_BUILD_OFFLINE_MEDIUM=false` set on the device — CHECK ITS RESULT FIRST (`pol jenkins queue`, the release console, `gh release list -R dausume/polari-suite`, `gh api /user/packages?package_type=container`) |
| routes | github-release, ghcr, homebrew ARMED (`github/release_token`, `github/registry_token` in the system posture); apt-repo DRY until the signing key exists after the KC rotation |
| after the first ghcr push (HIS) | make the three new packages PUBLIC and link them to the repo, or `pol prod` elsewhere cannot pull without a token |
| prepared base | baked once on isle-core (3.4 GB, `prepared-<key>.qcow2`); the guest's prerequisite step is 13 s instead of 336 s |
| test images | discarded after every test run (`test-wipe.sh --images-only`); a release keeps its own |
| pipeline-test marker | `/etc/polari/pipeline-test` + `POLARI_PIPELINE_TEST=1` → `/api/health` `pipelineTest` (not yet read from a live throwaway) |
| the UI | Jenkins on `127.0.0.1:8080` of econ-core (admin; password in `/etc/polari-jenkins/secrets/admin/`, sudo); from elsewhere `ssh -L 8080:127.0.0.1:8080 econ-core`; from the shell `pol jenkins queue|test-status|report|promote status` |

## 2. The uninstall — what is wrong, who owns it, the plan

**Observed (ledger §75, §77, §78 addenda):** `isle uninstall --everything` exits 0 while its own verify shows a
footprint — `/usr/share/isle-mesh` and `/etc/polari` left, five images left, `polari-complete` still installed on
a NetworkManager host (isle-core, §75); on a cloud-image guest the network hand-back PASSED (route, public DNS,
apt) and nothing leaked, so the residue is files, not processes. On isle-core (NetworkManager) the hand-back also
LOST DNS: systemd-resolved was left with no per-link server; `nmcli con up <wifi>` restored it at once.

**Ownership:** the isle CLI is isle-core's code (its own Claude, contract channel `Isle-Mesh/NOTES-FROM-POL-CORE.md`
— the findings are written there verbatim). Since the purge the suite's `Isle-Mesh` submodule is the ONLY live
copy, so the fix can also be made here if he says so; until then the pipeline records it as a warning.

**The plan (un-8, in `Isle-Mesh/isle-cli/scripts/uninstall.sh` + the hand-back):**
1. **Exit status tells the truth.** `--everything` returns non-zero when its own final verify finds any footprint;
   `--verify` alone keeps its read-only semantics. Everything downstream (the pipeline, the store UI) reads the
   status before the text.
2. **Purge the whole family, by name and by what `polari-complete` Provides:** `polari-complete`,
   `polari-complete-offline`, `polari-shell-core`, `isle-app-store`, `isle-mesh-cli`, `polari-isle`, `polari-dev-*`,
   any `isle-app-*` — `apt-get purge`, then `dpkg -l | grep -E 'polari|isle-'` must be empty.
3. **Remove the directories the packages do not own:** `/usr/share/isle-mesh`, `/etc/polari`, `/etc/isle-mesh`,
   `/var/lib/polari*`, `/opt/polari*`, the user's `~/polari-isle` (root-owned files inside it — use root), the
   `isle` symlink(s) in `/usr/local/bin` and `/usr/bin`; images `docker rmi` of every `prf-*`, `pol-*`,
   `isle-*` tag; the stale `isle-mesh-boot.service` unit + `daemon-reload`.
4. **The network hand-back must PROVE DNS before saying complete:** after reverting dnsmasq/resolved/NetworkManager
   changes, `nmcli con up <the active profile>` (or `resolvectl revert <link>`), then `getent hosts deb.debian.org`
   and `apt-get update` must succeed; on failure print the one-line rescue (`nmcli con up "<profile>"`) — and
   build `isle rescue network` (offline) as his 2026-09-13 rule asks.
5. **The hand-back journal** (his rule): every install-time change appended to `/var/lib/isle-mesh/handback.journal`
   and replayed in reverse by the uninstall; the pipeline's five-check proof then reads the product's own journal
   rather than its own list.
6. **Prove it three ways:** the pipeline's isle stage (`uninstall_verdict` must read `clean`, then flip
   `CI_UNINSTALL_GATE=fail` back on), a NetworkManager desktop (isle-core) by hand, and the ISO guest.

## 3. Known unfinished work (everything OWED that is not the uninstall)

**Pipeline device (econ-core)**
- `pol jenkins up` after every pull that touches pipeline files — `promote` now REFUSES otherwise (controller stamp); the setup/README should say it in one line.
- `pol jenkins setup` must own the PROMOTION IDENTITY (install `gh` — snap needs `--classic` — `gh auth login`, `gh auth setup-git`, prove push access) and align nested submodules before the clean-tree check; the sweep now ignores nested-submodule CONTENT and promotes from ORIGIN refs.
- The pool directory is polari-ci's; git warns "could not open directory polari-jenkins/pool" on every status — exclude it in the sweep's status call.
- `pol jenkins test-status` once printed a stale `origin/test` tip although it reads `ls-remote` — not reproduced; watch it.
- Two pools on the device (the controller's `polari-jenkins/pool`, the isle scripts' `/var/tmp/polari-ci-pool` on the target) — make it one story in the docs, or one pool.
- `casc/plugins.txt` is not asserted against the DSL steps the pipelines use (`readJSON` sat uninstalled for two slices).
- Scan tool digests unpinned (`scan-tools.lock` "unresolved") — `scan.sh lock-resolve` on the device; the scan counts on the last runs: 5 critical / 156 high (advisory).
- The `cicd` Polari app is not live anywhere (no core on the device; `CI_CORE_URL` empty) — the pipeline-device prod profile admits it; nothing has rendered its pages.
- The desktop app (`polari-pipeline` deb, first-run panel, `cicd-setup` page) has never been run on a screen.
- Wired IPv4 on econ-core: the wired port answers no DHCP (likely the isle segment whose router guest is gone).
- Release: the offline medium fix (`appstore.custom.offline_chunker`) reaches main on the next cycle; set `CI_BUILD_OFFLINE_MEDIUM=true` again on the device after that. `release.json` `testedAgainst` renders the minted tag — check it names the TEST sha/verdict instead.
- The apt route: signing key after the Keycloak rotation (`pol security rotate staging` with him).
- After the first ghcr push: package visibility + repo link (his).

**Product findings the pipeline surfaced (not pipeline work)**
- The isle uninstall (§2 above) — isle-core's.
- `pol modules selftest` never matched an isle's backend container (`prf-isle-backend`) — fixed in ci-3; the general lesson: a selftest that only ever ran on the host can hide an in-image environment difference (busybox grep `--include`, the `POLARI_INSTANCE_ID` assumption).

**Security arc (separate handoff: `ROLEPLAY_PERMISSIONS_HANDOFF.md`)**
- op-3 Ballot (governance), the Sharing tab's per-instance page host, the objects view's third declared source, `app.flows` on the other modules, the converge-every-app sweep, every browser pass, `stop_grace_period` (his yes), polari-systems.org publish (his).

## 4. Deployment targets over ssh (his ask 2026-09-21) — design, not built

*"a lightweight way for us to use ssh for a deployment location so that we can automate the process of doing
updates conditionally to a deployment environment like our droplet."* His standing rule: nobody WORKS in the droplet;
this is the one sanctioned path INTO it, automated and conditional.

**Shape (dep-0 … dep-3):**
- **`DeployTarget`** — a row in the `cicd` app and a `polari-jenkins/deploy/targets.env` fallback: `name` (chosen, never
  a hostname), `ssh_alias` (an alias in the pipeline user's `jenkins_home/.ssh/config`, authorised exactly like the
  isle target: `pol jenkins deploy authorize <alias>`), `route` (`swarm` = `pol prod apply` on the target |
  `isle` = the isle deb route), `profile` (`lean|full`), `channel` (`release` = only published releases with a
  `passed` verdict | `test` = the tip of test for a staging box), `window` (a cron-shaped maintenance window or
  `any`), `min_health` (the routes that must answer before and after), `hold` (true = never auto-apply; a person
  runs `pol jenkins deploy <name> --now`).
- **The conditions, all evidence-bearing and printed:** a NEWER release than the target's current `/api/release`
  (the ReleaseManifest served by the core — rel-2), that release's verdict `passed`, tested == released (image ids),
  inside the window, the target's health OK before, disk free above a floor, no other deploy in flight (a lock like
  `polari-build`), and the `hold` flag off. Any condition false → recorded (`pool/deploy/<target>/<release>/skipped.json`)
  and nothing touches the target.
- **The apply, over ssh as the pipeline user, non-interactive:** `pol prod apply --release <tag> --yes` on the target
  (it already consumes `release:<tag>` from GitHub; images from ghcr — hence the package visibility step), then
  `pol prod verify`; on failure `pol prod apply --release <previous tag>` (releases are immutable, rollback is a
  re-pin) and a `failed.json` with both verify outputs; success = `applied.json` + a `DeployRecord` row mirrored
  into the `cicd` app (so the pages show what runs where, since when, from which release).
- **Where it runs:** a fourth job, `polari-deploy`, polled/cron like the others, one queue per target, latest-wins,
  never concurrent with a release (it takes the `polari-build` lock last). `pol jenkins deploy <name> [--now|--dry-run]`
  runs the same script by hand.
- **What must exist first:** rel-2 (`/api/release` served by the core + the ReleaseManifest row) so "what does the
  target run" is a reading, not a guess; the ghcr packages public; the pipeline user's key on the target — and the
  droplet's ssh accepting it (today it accepts no key from pol-core; that is his to add once).
- **Sizing:** the droplet is a small VM; a deploy is a pull + a stack update, not a build — nothing in this design
  builds on the target.

Slices: dep-0 the row + targets.env + `deploy authorize` + the conditions as a dry-run report; dep-1 the apply +
verify + rollback on a HOME box first (pol-core running the lean profile again, `hold` off); dep-2 the job + the
queue + the records + the cicd page; dep-3 the droplet, `hold` on, first apply by hand with `--now`, then the window.
