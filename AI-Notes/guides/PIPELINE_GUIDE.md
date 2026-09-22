# The Polari pipeline — an operator's guide

This is the public guide to `polari-jenkins`, the build-test-release
pipeline for the Polari suite. It agrees with `polari-jenkins/README.md`,
which is the authoritative operator reference; this page is the shorter,
narrative version of the same rules.

## 1. What the pipeline is

The pipeline is Jenkins, run beside the isle rather than inside it: it
**polls** GitHub rather than accepting a webhook, its UI binds to
`127.0.0.1` only, and every publication it makes is an outbound push. No
inbound port is ever opened.

One device is enough, and a small one is fine. Measured floors: the
controller container is capped at 2 GB, an Angular frontend build wants
roughly 3 GB, and the throwaway isle VM the pipeline creates and destroys
defaults to 4 GB — so a 7.5 GB device runs the controller and the builds,
serialized, but not a concurrent isle VM. On a device that size, put the
throwaway isle on a second device instead (`pol jenkins target ssh
<alias>`); a 16 GB (or larger) device can host everything itself
(ledger §70 addendum).

**The rule the whole pipeline exists to enforce: only what was tested is
ever released.** A build that has not passed a recorded test run cannot
publish — not to GitHub Releases, not to the container registry, not
anywhere — no matter who runs the release job or what flag they pass
(ledger §76; `polari-jenkins/routes/_lib.sh`).

Two modes, chosen once at setup:

- **`CI_MODE=suite`** (the default) — the whole Polari suite is built,
  tested in a throwaway isle and released.
- **`CI_MODE=app`** — this device maintains **one** Polari app. The core
  is not rebuilt; it is pulled from a named Polari release
  (`CI_CORE_SOURCE=release:latest` or `release:<tag>`) and the app is
  tested against that core. Only that app's deb is released, and only to
  **your** own routes — a fork is never republished under the upstream
  name (`polari-jenkins/device.env.example`).

## 2. The branch model — dev iterate · test decide · main release

Three branches, two pipelines, one verdict per commit (ledger §76;
`polari-jenkins/README.md` "The branch model"):

| branch | means | starts | promises |
|---|---|---|---|
| `dev` | work in progress, iterated on fast | `polari-dev-build` — an optional quick build (debs + images, no tests, no scans, no publish) | nothing; a green dev-build means only "it built" |
| `test` | what we are testing | `polari-test` — wipes this device, builds, scans (advisory), runs every configured test, records ONE verdict | that a verdict exists for this exact forest state |
| `main` | what we release | `polari-release` → `polari-publish` | that everything on it passed a test run, by commit |

A push to `test` (`pol jenkins promote test`) wipes the pipeline device —
this sha's previous test output, the ordinary pool prune, the `:staging`
images this device built, and on the throwaway isle target an `isle wipe`
plus a leak-check baseline — then builds, runs advisory scans (Trivy,
gitleaks, `pip-audit`/`npm audit` where available; **no finding ever gates
anything**), runs every configured module selftest, and runs the isle
testing stages. It ends with exactly **one verdict** written to
`pool/test/<sha>/verdict.json`:

| verdict | when |
|---|---|
| `passed` | every configured module selftest passed **and** the isle stages recorded `core_ok` (which itself requires a clean hand-back from the product's own uninstall) |
| `failed` | something that ran said no |
| `partial` | nothing said no, but something that should have answered did not |

The human decision happens after that verdict: read it, and only then
decide whether to promote to `main`. `pol jenkins promote main` refuses
outright unless the sha on `test` carries a `passed` verdict — `--force-
untested` overrides it, loudly, with the sha and the reason printed in the
log, and there is no quiet way to do it.

```
pol jenkins promote test        dev → test, every repo, innermost-first, ff-only
pol jenkins test-status [<sha>] the verdict: what built, what the tests said,
                                what the advisory scans found (and did not change)
pol jenkins promote main        test → main — refused unless that sha's verdict is `passed`
pol jenkins queue               both queues: pending / newest sha / since / running
```

**The quiet period and the queue.** A run starts only once the *whole
forest* — the superproject and every top-level submodule remote — has
gone five minutes (`CI_QUIET_MINUTES`) without a new commit anywhere; any
change inside that window restarts the clock. `pool/queue/<branch>.json`
holds at most **one** pending item per branch, meaning "the newest state
of this branch" rather than a specific sha — a newer push replaces it
rather than queuing behind it, so no backlog can ever form. `test` and
`main` are separate queues and never run at the same time; when both have
work, they alternate (`pol jenkins queue` shows the last turn taken).

## 3. Setup, CLI only

From a fresh clone:

```
git clone --recursive https://github.com/dausume/polari-suite.git && cd polari-suite
sudo bash polari-cli/shells/install-cli.sh
```

`pol` must be installed **system-wide** here — the privileged verbs a
setup walkthrough runs refuse a user-local `~/.local/bin/pol`, because a
`pol` a single account can rewrite is not a program root should trust to
run on its behalf.

Then run the one-shot walkthrough:

```
pol jenkins setup
```

It walks eight steps. Each one explains the option in plain words, checks
the state **live** (by running the doctor and the preflight it already
has — never a second copy of a check), says what to set up and where to
get it, then offers to do the local part itself:

| # | step | what it does |
|---|---|---|
| 1 | this device's role | reads RAM/CPU/disk/KVM and says which roles fit |
| 2 | the checkout and the CLI | installs missing tools, runs `install-cli.sh`, adds the docker group, updates submodules |
| 3 | the network | checks a wired IPv4 exists and GitHub is reachable; states plainly that nothing inbound is opened |
| 4 | the secrets posture | runs `sudo pol jenkins init-device`, then per secret: the exact URL and scopes, a hidden paste, or generates the material itself (cosign, GPG, ssh) |
| 5 | the throwaway-isle target | local vs. ssh, the `~/.ssh/config` block, `ssh-copy-id`, the sudoers drop-in (shown verbatim, applied only on yes), then a real `preflight --isle` |
| 6 | the isle testing stages | explains `CI_ISLE_STAGES` — what gets tested, and therefore what may ever ship |
| 7 | bring the controller up | runs `pol jenkins up`, prints the tunnel command, the admin password location, and the four jobs |
| 8 | summary | a done/still-to-do list, in order, and a READY / NOT READY verdict, saved to `SETUP_STATUS.md` (gitignored) |

`pol jenkins setup --report` runs the same eight steps read-only, printing
state and the to-do list without prompting for anything. `pol jenkins
setup --step <name>` re-runs one step. Every step is idempotent — a second
run says "already: OK" and changes nothing.

Two commands worth knowing on their own, since the setup walkthrough just
calls them:

```
sudo pol jenkins init-device        # (C) the secrets posture: creates the polari-ci
                                     # system user and /etc/polari-jenkins/secrets,
                                     # root:polari-ci 0750, files 0640 — readable
                                     # by root (via sudo) and the pipeline process
                                     # only, nobody else
pol jenkins target ssh <alias>      # the throwaway-isle target: an ssh ALIAS from
                                     # ~/.ssh/config, never a raw address, with a
                                     # passwordless-sudo drop-in for the libvirt
                                     # commands and libvirt tooling on that device
```

After setup:

```
pol jenkins up                      # the controller, UI on http://127.0.0.1:8080
pol jenkins doctor [--strict]       # (B) every check: OK, or WARN with what to do
pol jenkins preflight --isle        # (A) a resource guard — is the target CLEAR
                                     # and does it have room? any FAIL = exit 4
```

The doctor never refuses on its own (exit 0), so it also runs quietly at
the end of `pol jenkins up` and `pol jenkins status`; `--strict` turns any
WARN into a non-zero exit, for use as a gate.

## 4. Tokens

Two secrets, named for what they unlock and documented by exactly where
they go (`polari-jenkins/secrets/README.md`, `routes/destinations.sh`):

### `github/release_token`

What it does: pushes the version tag (`git push refs/tags/polari-v…`),
creates the GitHub Release and uploads its assets (`routes/github-release.sh`),
and bumps the `pol` formula in the homebrew tap (`routes/homebrew.sh`). All of
that is one GitHub permission — *write the contents of those two repositories*.

**Recommended — a classic token, scope `repo`, nothing else.**

- Create it at `https://github.com/settings/tokens/new` (Tokens (classic)).
- Tick **`repo`** only. It is a *second* token: keep it apart from the
  registry one, so each can be revoked alone.
- Set an expiry and note it; the doctor prints it.

**The tighter option — a fine-grained token.**

- Create it at `https://github.com/settings/personal-access-tokens/new`.
- **Repository access:** only the two repositories this pushes to — the
  suite's own repo and the homebrew tap. Never "all repositories."
- **Repository permissions:** `Contents` — **Read and write** (Metadata —
  Read is added by itself).
- **Account permissions:** none.
- ⚠ GitHub's fine-grained UI shows a token's grants **nowhere** after it is
  made, and there is no API to ask. The first real release (2026-09-22) died
  at the tag push on a fine-grained token that could read the repository and
  not write it — nothing in the UI said so. That is why the doctor probes.

**Either way, prove it:** after `secrets put`, run `pol jenkins doctor`. Its
token rows (`routes/token-check.sh`) try a write-free `git push --dry-run`
against the release repo and the tap, read the token's kind, scopes and
expiry from its own headers, and look the tap repository up — and say
exactly what is missing. *Present is not able.*

The homebrew tap repository (`<owner>/homebrew-polari`) must exist before the
homebrew route can push; an empty repository is enough. Until it does, the
doctor says so and the route fails — take `homebrew` out of `CI_ROUTES` or
create the repository.

### `github/registry_token`

A **classic** GitHub personal access token — a fine-grained token cannot
write container packages.

- Create it at `https://github.com/settings/tokens`.
- **Scopes:** `write:packages` and `read:packages`. Not `delete:packages`,
  not `repo`.

It pushes images to `ghcr.io` (`routes/ghcr.sh`). Note: a brand-new ghcr
package is created **private** by GitHub, so after the first push it must
be made public and linked to its repository once, by hand, in the
package's own settings — after that, every later push to the same package
stays public.

### Storing a token

The value never travels as a shell argument or lands in history:

```
printf '%s' '<replace-with-token>' | sudo pol jenkins secrets put github/release_token
```

```
pol jenkins secrets status          # name — destination — routes — ARMED/DRY, per secret
sudo pol jenkins secrets mv github/github_token github/release_token   # the old→new rename,
                                                                        # keeping mode and owner
```

A missing secret never breaks anything — the route it belongs to simply
stays `DRY (secret <name> absent)`, and `pol jenkins doctor` shows the
same line before anything runs.

### Documentation only — other providers

The publish routes built today are GitHub's; the two below are recorded
here for reference only, in case a self-hosted forge becomes a route
later. Gitea/Forgejo is the light, self-hostable choice; GitLab CE is the
heavier one.

**GitLab** — User Settings → Access Tokens. Scopes: `api` and
`write_registry`.

**Gitea / Forgejo** — Settings → Applications → Generate New Token.
Scopes: `write:repository` and `write:package`.

## 5. Setup, the app route

The pipeline can also run as an ordinary desktop application, "Polari
Pipeline" — no terminal, a native first-run panel that drives the same
eight steps, with privileged actions going through `pkexec` (a normal
polkit password prompt) and any secret typed into a native password
field rather than a browser form (ledger §74; `polari-app-shell/pipeline/
README.md`, `docs/BRIDGE_CONTRACT.md`).

Building and installing it:

```
polari-app-shell/shells/build-pipeline-deb.sh    # needs polari-shell-core, the
                                                  # shared app-image, built first
sudo dpkg -i polari-pipeline_*.deb
```

Launching "Polari Pipeline" opens the same walkthrough as `pol jenkins
setup`, rendered as a native panel. Every step the panel can take is one
of a small, fixed set of allowlisted commands (`polari-jenkins/shell-
verbs.json`, the `polari-pipeline-shell/1` protocol): a privileged verb
runs only through the one `pkexec`-pinned wrapper, which re-validates it
as root, and a verb that needs a secret opens a native password field and
writes the value straight to the child process's stdin — never into the
page, an argument, or a log.

Once the controller is up, the same settings also live in Polari itself,
on the `cicd-setup` page, editable there like any other module's rows.

**This route has not yet been run on a screen.** The desktop half is
built and tested against the same contract as the CLI half, but the
first real run — installing the deb, seeing the `pkexec` prompt fire, and
watching the panel by eye — has not happened yet (ledger §74 OWED).

## 6. Day to day

Push to `dev` as often as you like — it costs nothing but an optional
quick build. When you want a verdict:

```
git push origin dev              # (or however dev usually moves)
pol jenkins promote test         # dev → test, kicks off polari-test
pol jenkins test-status          # read the verdict once it lands
pol jenkins promote main         # only works if that verdict says `passed`
```

A `main` release mints a `polari-vYYYY.MM.DD[.N]` tag, builds the release
artifacts, writes `release.json` and `SHA256SUMS`, and then walks the
publish routes — each one reading the test verdict itself, so triggering
`polari-publish` by hand on an untested build is safe by construction. An
app whose isle stage did not pass is simply left out of the release
assets, named as "not released: untested/failed" in both the job log and
the release notes.

Build output lands under `polari-jenkins/pool/<version>/` on the pipeline
device — release artifacts, scan reports, cache reports, and the isle-test
results all live there, gitignored.

The offline-first cache (`pol jenkins cache status`) is an optimization,
never a precondition — an empty cache still builds, over the network, and
says so on the way. `pol jenkins cache prune --older-than 30` is the one
thing that ever deletes from it; nothing else touches it.

`pol jenkins doctor`'s warnings each name their own fix — a missing wired
connection, an un-rotated secret name, a stale isle-target key, a
container still running yesterday's script because a bind-mounted file
changed underneath it. None of them stop a run on their own; they are the
device telling you what is worth fixing before the next one.

Between isle testing stages the pipeline wipes the throwaway isle target
(`isle wipe`, scoped to only what carries the pipeline's own tag) and then
runs a leak check that diffs the target against a baseline taken before
the stage started — memory, disk, VMs, networks, processes. Anything left
behind that should not be there stops the run before the next stage
rather than letting it start on a dirty host.

The uninstall-as-test verdict is part of the same story: before a stage's
result can ever count as `core_ok`, the product's own `isle uninstall
--everything` has to run inside the guest and hand the machine back
cleanly — a default route, working public DNS, and a working `apt-get
update`. A `dirty` or `failed` uninstall is a product test failure, not a
pipeline bug, and it holds the release rule exactly the way a failed
selftest would.

## 6a. Production as the step after publish — deployment targets over ssh

Once a release is out (the GitHub release and the registry), `polari-deploy` can
put it on a machine that runs Polari — a **deployment target** — over ssh, as the
pipeline user. Two rules bound it, and both are enforced rather than described:

**The pipeline cannot touch the target's secrets.** The pipeline user's key is
installed on the target restricted to ONE command, the deploy agent
(`restrict,command="…/prod-agent.sh"` in `authorized_keys`): no shell, no
forwarding, no `pol prod apply`, no path to the vault or the certificate. The
agent reads what it needs from the running swarm and does four things:
`stash` (every named volume of the stack, tar'd read-only, before anything
moves), `update <version>` (`docker service update --image <registry>/<name>:<version>`,
start-first, one service at a time, converged before the next — no
interruption; swarm's own rollback if a service does not converge), `verify`
(every service n/n and the local `/api/health`), `rollback <version>` (a re-pin
of the previous tags). `docker service update --image` keeps every secret and
config attached exactly as they are. The FIRST deploy of a box (no stack yet) is a
person's `pol prod apply` there; after that the pipeline keeps it current.

**Nothing deploys unless every condition holds**, and each is printed with its
evidence (`pol jenkins deploy check <name>`): the target runs an OLDER release
(read from the agent, never guessed) · the release has a passed verdict and
released == tested by image id · the routes the target consumes published FOR
REAL · inside the window · healthy before · disk above the floor · no other
deploy in flight · `hold` off · not already failed on this target (rule 4: a
failed deploy waits for a newer release or a person). Any one false → a
recorded skip, nothing touched. A failure after the update → rollback by re-pin,
`failed.json` with both verify outputs, and the stash stays on the target for a
person's `pol prod restore <stash-id>`.

```
pol jenkins deploy add public-site SSH_ALIAS=<alias> HOLD=true HEALTH="https://…/ https://…/api/health"
pol jenkins deploy authorize public-site      # the pipeline user's key, RESTRICTED to the agent, fingerprint-verified
pol jenkins deploy check public-site          # every condition, with its evidence — nothing written
pol jenkins deploy public-site --dry-run      # the exact agent verbs a run would send
pol jenkins deploy public-site --now          # a PERSON's deploy: overrides hold + window, nothing else
pol jenkins deploy list | status              # what runs where, since when, from which release
```

`SSH_ALIAS` is a Host entry in the pipeline user's ssh config, never an address;
the target's name is chosen, never a hostname. `hold=true` is the default: a new
target never deploys by itself until you say so. The targets are `DeployTarget`
rows in the `cicd` app (fallback: `polari-jenkins/deploy/targets.env`); every
deploy that touched a target is a `DeployRecord` row, on `/display/cicd-deploys`.

## 7. Known limits today

Read plainly, because the pipeline is meant to say what is true rather
than what is convenient (ledger §75, §76, §76 addendum, §76 addendum 2,
§74 OWED):

- **The in-guest install still does not exist (ci-3).** Nothing installs
  the core or app debs inside the throwaway isle yet, so every isle stage
  records `skipped`, `core_ok` never becomes true, and no verdict can
  reach `passed` from that alone.
- **After `sudo pol jenkins init-device` runs, the controller's ssh key
  to the isle target must belong to the pipeline user.** `init-device`
  moves the controller onto its own `polari-ci` system account; the ssh
  key that reaches the isle target has to be one that account can read,
  or every isle stage refuses at the preflight.
- **Eight core module-selftest suites failed on the first real test
  run** (`accessControl.selftest_cause_context`,
  `moduleService.selftest_app_taxonomy`, `moduleService.selftest_json_seeds`,
  `moduleService.selftest_lazy_boot`,
  `moduleService.selftest_module_dependencies`,
  `topology.selftest_move_operations`, `topology.selftest_testing`,
  `topology.selftest_topology`). They are not a pipeline defect — the
  pipeline found them — but until they pass, no sha can reach `passed`
  even once ci-3 lands.
- **Scan tool digests are unpinned.** `scan-tools.lock` still carries
  `unresolved` in its digest column; the scanners run by tag today, and
  the report says so.
- **The desktop app has not been seen on a screen.** Both halves (the
  CLI-side protocol and the Java shell) are built and tested against
  their shared contract, but no one has installed the deb and watched the
  first-run panel work end to end yet.
- **Publishing to polari-systems.org is manual today.** The downloads arc
  is built, but the site's own publish step is not yet wired into
  `polari-publish` as a route.
