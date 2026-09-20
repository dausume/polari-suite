# polari-jenkins — the host-tier build + publish pipeline (ci arc)

Jenkins runs **beside the isle, not inside it** (his ruling 2026-09-04: it
builds and tests isles, so it sits at the docker/host tier like docker
itself). It **polls GitHub** — no webhook, no tunnel, no inbound port: the
UI binds to `127.0.0.1` only and every publication is an outbound push.

ci-7 adds **the pipeline device**: the machine that hosts the throwaway isle
is now a choice (this machine, or another over ssh), with (A) a preflight
that proves the device is clear and has room, (B) a doctor that says what is
not set up and what to do about it, and (C) a secrets posture only root and
the pipeline process can read.

ci-7b adds the way in, **`pol jenkins setup`**, and the rule that gives the
whole pipeline its point: **only what was TESTED is ever released.**

**ci-12 gives that rule a shape you can see: three branches and two
pipelines.** `dev` is where you iterate; pushing `dev` to `test` wipes this
device, builds, scans and runs every test, and records ONE verdict; only a sha
whose verdict says `passed` may be promoted to `main`, and `main` is the only
branch that generates and publishes artifacts. Read **the branch model** below
before anything else — it is the map the rest of this file hangs on.

## Start here: `pol jenkins setup`

One command, one shot. It walks eight steps; each one explains the option in
plain words, checks the state **live** (by running the doctor and the
preflight — it never re-implements a check), says WHAT to set up, HOW and
WHERE to get it, then **offers to do the local part itself** and does it.

```
pol jenkins setup              the walkthrough (whiptail dialogs, or plain prompts)
pol jenkins setup --yes        answer every safe local question yes (never invents a token)
pol jenkins setup --report     READ-ONLY: the state and the "still to do, in order" list
pol jenkins setup --step isle  re-run one step
```

| # | step | what it does for you |
|---|---|---|
| 1 | this device's role | reads RAM/CPU/disk/KVM and says which roles fit ("7.5 GB: controller + builds serialised — not a concurrent isle VM…") |
| 2 | the checkout and the CLI | `apt` the missing tools, `install-cli.sh`, `usermod -aG docker`, `submodule update` |
| 3 | the network | a wired IPv4 (`nmcli con up`), github reachable; says plainly that nothing inbound is opened |
| 4 | the secrets posture | `sudo pol jenkins init-device`; then per secret: the exact URL + scopes and a hidden paste, or it GENERATES the material (cosign, gpg, ssh) and stores it |
| 5 | the throwaway-isle target | local vs ssh, the `~/.ssh/config` block, `ssh-copy-id`, **`pol jenkins isle authorize` — the PIPELINE user's own key onto that device**, the sudoers drop-in shown verbatim and applied on yes, libvirt over ssh, the VM knobs, then a real `preflight --isle` |
| 6 | the isle testing stages | `CI_ISLE_STAGES` — what each isle tests, and therefore what may ever ship |
| 7 | bring the controller up | `pol jenkins up`, the tunnel, the admin password, the four jobs |
| 8 | summary | done / still-to-do in order, a READY / NOT READY verdict, saved to `SETUP_STATUS.md` (gitignored) |

`pol jenkins status` prints one line from that file
(`setup: 4 of 8 complete (NOT READY) — pol jenkins setup --report`).
`pol jenkins guide` is kept as an alias of `setup`.

Every step is idempotent: a second run says `already: OK` and changes
nothing. A question answered **no** never touches the device — it lands on
the to-do list instead. `--report` prompts for nothing at all.

**It never invents a secret.** A GitHub token, a ghcr token and a deploy key
come from outside authority: the step prints the URL and the exact scopes,
takes the value pasted in (hidden, never echoed or logged) and stores it
through `pol jenkins secrets put`. Skipping one keeps its route DRY.

## The same walkthrough, for a machine (ci-11a)

His ask, 2026-09-19: run the pipeline as a desktop application, "guiding
people through use like a normal app", with no terminal. That needs the
walkthrough above to be readable by something other than a person, so it
gained a machine mode. **One JSON document on stdout, logs on stderr:**

```
pol jenkins setup --json                       the whole walkthrough
pol jenkins setup --json --step secrets        recompute one step
pol jenkins setup --json --step role --answer CI_MODE=app    write one answer, then recompute
pol jenkins setup --json --run preflight       run ONE unprivileged action, get its step back
pol jenkins verbs                              the ALLOWLIST any front end runs through
pol jenkins doctor --json                      the doctor's rows, machine-readable
pol jenkins preflight --isle --json            the resource guard, machine-readable
```

It works with **no Polari core running and no `device.env` at all** — a
first-run screen has something to render before anything is configured.

**ONE SOURCE OF TRUTH.** The `checks` of every step come from running that
step's own `step_<name>_check` — the very function the terminal prints — with
`check` / `explain` / `where` rebound to record instead of print
(`setup/json.sh`). A check cannot drift between the terminal and a screen:
there is only one of it. What the interactive path *asks* is declared beside
it, in the same step file, by `step_<name>_json`.

**--json never prompts, and never runs anything privileged.** A privileged
action is *described*: it is marked `privileged: true` and names a **verb id**
from `polari-jenkins/shell-verbs.json` (tracked, shipped in the deb). That
file is the whole contract — every command any front end may run on this
device's behalf, by id, with its argv **fixed** and an anchored regex for
every `{parameter}`. There is no free-form command and no verb that takes a
path. Parameters are validated on both sides: `setup/protocol.py` refuses to
offer an action whose parameters do not match, before a screen ever sees it.

**A secret value never travels in an argument.** A `secret` question carries
`present` or nothing; storing one is the `secrets-put` verb, whose value is
read from **standard input** by whoever executes it. `--answer` refuses a key
carrying a `/` (a secret name) and says why.

Three layers, three places, and nothing crosses:

| layer | where | knows |
|---|---|---|
| protocol emission | `setup.sh`, `setup/steps/*.sh`, `setup/json.sh`, `setup/protocol.py` | the device. Nothing about any front end: no branch on who is calling, no mention of how an elevation is obtained |
| the allowlist | `shell-verbs.json`, `pol jenkins verbs` | which commands exist, their argv, their regexes |
| the page | the `cicd` module's `cicd-setup` page + one Angular panel | the protocol and the bridge. It never composes a command |

A device pushes its walkthrough to Polari with `pol jenkins sync push` (or
`sync push-setup`), because a core cannot run `pol` — that mirror is what a
browser **without** the desktop application reads, read-only, with the exact
command beside each step.

## Where the settings live (ci-8) — the `cicd` Polari app

**Polari is the source of truth for everything in `device.env`.** The `cicd`
module holds it as rows (`PipelineDevice`, `PipelineStage`, `PipelineRoute`),
edited on those rows' own pages by an administrator, and `cicd-sync.sh pull`
rewrites `device.env` from them at the top of every Jenkinsfile.

    pol jenkins sync pull      GET $CI_CORE_URL/api/cicd → rewrite device.env
    pol jenkins sync push      report readiness, routes armed and secret PRESENCE back
    pol jenkins sync status    what it would do, and whether the core answers

The pull is **never fatal**: a core that does not answer leaves the
`device.env` this device already has and says so on one line. A pipeline
that stalled because a web service was down would be worse than one that
used yesterday's knobs and told you.

The device also mirrors **runs**, **isle-test stage results** and **release
records** back, through a per-device **posting-only** credential
(`polari/cicd_ingest_token`, minted once by an administrator at
`POST /api/cicd/device/token`). That credential may post those five kinds and
nothing else: it is not a Jenkins account, it cannot read or change a
setting, and no secret VALUE ever leaves this device — only names and a
boolean, and the core's door refuses a body carrying a value.

### Two modes (his addendum, 2026-09-19)

`CI_MODE=suite` (the default) builds, tests and releases the whole Polari
suite. `CI_MODE=app` maintains **one** Polari app: `CI_APP_NAME` from
`CI_APP_REPO`, with the core **pulled** from `CI_CORE_SOURCE`
(`release:<tag>` or `release:latest`) rather than rebuilt, the stages
defaulting to `core; <app>`, and only that app's deb released — to that
developer's **own** routes. A fork is never republished under an upstream
name, and the release record names the core release the app passed against.
`CI_CORE_SOURCE=build` is the escape hatch for somebody who also patches core.

**`CI_CORE_SOURCE` IS AN APP-MODE KNOB, AND ONLY AN APP-MODE KNOB** (ci-12
addendum 7). Its default is `release:latest` and that line is written into
*every* `device.env`, suite-mode ones included — so both Jenkinsfiles used to
take the release-pull path on a device that builds its own core, and
`polari-isle-test #5` refused with *"polari-cli/scripts/lib/providers.sh is not
in this checkout"* while every `polari-release` run went red at the same stage.
The condition is now `CI_MODE == 'app'` and nothing else. In suite mode the
core under test is the one **this run built**, installed out of the run's own
pool directory — `pool/test/<sha>/debs` for a test run, `pool/<version>/debs`
for a release build; `isle/core-artifacts.sh built <version>` is the one place
that resolution lives, for both jobs. `pol jenkins doctor` prints an INFO row
saying the knob is ignored, rather than leaving the line looking load-bearing.

**ci-9 made app mode real.** `pol jenkins setup`'s **first question** is now
"what does this pipeline maintain?", and answering *ONE Polari app* asks for
the module, its repository (cloned under `<pool>/apps/<name>` with `pol
project` conventions), the core release it is tested against, and
`CI_ROUTE_TARGET` — **your** owner/namespace. `isle/core-artifacts.sh
resolve|fetch` turns `release:latest` into a real tag through the same reader
`pol prod` uses, fetches that release's core debs **once** into
`<cache>/releases/<tag>/` and verifies them against the release's own
`SHA256SUMS`. An unresolvable tag is a refusal that names it — never a silent
fall back to building core, because *"tested against polari-v…"* would then be
a claim nobody could check.

```
pol jenkins core-artifacts resolve   # which release release:latest means, right now
pol jenkins core-artifacts fetch     # pull + verify its core debs into the cache, once
pol jenkins core-artifacts status    # which tags are cached
```

Two rules the routes enforce themselves, not the Jenkinsfile: an app-mode
release carries **only** that app's deb (never the core it was tested
against, never another app a stage happened to test here), and
`CI_ROUTE_TARGET` pointed at the upstream owner is a **refusal** —
`DRY_RUN=false` does not override it.

## The offline-first cache (ci-9)

> *"the jenkins pipeline should try and use offline artifacts for building
> where possible, that way we are taking less time when repeatedly using the
> same data"* — 2026-09-19

**Tier one is a directory**, `<pool>/cache`, that every builder reads first:

| area | what |
|---|---|
| `wheels` | python wheels — `pip download --find-links` first, the index only for what is new |
| `npm` | npm tarballs (tier two's verdaccio volume) |
| `apt` | the offline medium's distro closure, downloaded once |
| `images` | `docker save` tarballs of the base images a build pulls |
| `cloud` | the Ubuntu cloud image the throwaway isle boots from (moved out of `pool/images`) |
| `scanners` | **reserved** for the scanning arc's Trivy DB — the directory exists, nothing else |
| `releases` | official Polari releases fetched by tag (app mode's core) |
| `layers` | the BuildKit local layer cache, one directory per image |
| `proxies` | tier two's volumes |

Each area keeps one record per entry (`what`, `sha256`, `fetched`,
`last_used`, `bytes`) in its own `MANIFEST.json`.

**THE RULE, everywhere: the cache is an optimisation, never a precondition.**
An empty cache still builds, over the network, and says so. `CI_CACHE=off`
turns the whole thing off. Both Dockerfiles keep their network path: the
backend declares `FROM scratch AS wheels` as the default for the wheelhouse
build-context, so a plain `docker build` binds an empty directory and pip
falls straight through.

```
pol jenkins cache status                  # per area, against CI_CACHE_MAX_GB, + the last run's hit rate
pol jenkins cache prune --older-than 30   # the ONE deleter — entries nothing has used for 30 days
pol jenkins cache report [version]        # pool/<version>/cache-report.json, in a table
```

`retention.sh prune` **never** touches the cache (a cache that vanished with
yesterday's build is not a cache); `retention.sh cache-prune` is the same
deleter under the retention door.

Every build stage writes `pool/<version>/cache-report.json` — bytes served
from the cache vs bytes fetched, and seconds, per area. That report rides in
the run's `PipelineRun.summary` and in `ReleaseRecord.cache_report_json`, so
*"did the cache actually save us anything?"* is answerable from the rows.
**Until a real pipeline run has happened, every saving is EXPECTED, not
measured, and the doctor says exactly that.**

### Tier two — optional caching proxies (`CI_CACHE_PROXIES=on`)

`docker-compose.proxies.yml`: a `registry:2` pull-through (Apache-2.0),
`devpi-server` for pip (MIT), `verdaccio` for npm (MIT), `apt-cacher-ng` for
apt (**licence not verified from here — read its `COPYING` before this is
ever on by default**). All bound to `127.0.0.1`, outbound-only, no publish
path, volumes under the cache dir.

**OFF by default, and a pipeline never starts them.** The pipeline only asks
`cache.sh build-args`, which probes the ports and passes
`PIP_INDEX_URL`/`NPM_CONFIG_REGISTRY`/`APT_PROXY` when they answer and
nothing at all when they do not.

```
pol jenkins cache proxies status | up | down
```

## The branch model — dev iterate · test decide · main release (ci-12)

His ruling, 2026-09-19, and the whole of this section is it:

> "We need to create a new test branch. After pushing to the test branch we
> kick off the testing pipeline for polari and it does the builds and scans and
> runs in test mode which automates running tests for all of the modules and
> apps configured to run in that particular pipeline run. dev is a place for
> staging development work that we are rapidly iterating through. Pushing our
> dev work to test will kick off the process of wiping what we have locally and
> then running all of our tests and scans. Based on the outcome on the test
> stage, we make a decision to push changes to main. When a push to main
> occurs, we kick off the generation of artifacts and publish the artifacts.
> The test and main pipelines should likely be different pipelines."

| branch | what it means | what it starts | what it promises |
|---|---|---|---|
| `dev` | work in progress, iterated on fast | `polari-dev-build` — an **optional quick build**: debs + images, no tests, no scans, no publish | nothing. A green dev-build means "it built" |
| `test` | what we are testing | **`polari-test`** — wipe this device → build → scan (advisory) → run every configured test → record ONE verdict for the sha | that a verdict exists for this exact forest state |
| `main` | what we release | **`polari-release`** → `polari-publish` — mint the version, build the artifacts, publish them | that everything on it passed a test run, by sha |

```
pol jenkins promote test        dev → test, every repo, innermost-first, ff-only
                                (this is the push that kicks the testing pipeline off)
pol jenkins test-status [<sha>] the verdict: what built, what the tests said, what the
                                advisory scans found and did not change
pol jenkins promote main        test → main — REFUSED unless that sha's verdict is `passed`
pol jenkins queue               both queues: pending / newest sha / since / running
```

**The promote sweep is the ONE sweep.** `polari-cli/shells/push-all-dev.sh`
gained `--branch` and `--promote-from` rather than being copied: the same
clean-tree checks, artifact guard, submodule-pointer coherence and
innermost-first order that publish `dev` are what promote `test` and `main`.
A repo whose target branch is not a fast-forward of the source **stops the
promotion and is named**, and because the walk is innermost-first, nothing
outside that repo has moved when it stops. The working tree is never switched:
`git fetch . <src>:<dst>` moves a ref that is not checked out, and refuses
anything but a fast-forward on its own.

### What `polari-test` actually does

1. **May I?** — whose turn it is, and whether the forest has stopped moving
   (below). A "no" ends the build as `NOT_BUILT` and costs nothing.
2. **Checkout the TIP of `test`** — never the sha that triggered the poll.
3. **Wipe what we have locally** (`test-wipe.sh`): this sha's previous test
   directory, the ordinary pool prune, the `:staging` images this device built
   (so a cached image cannot answer for new code), then on the throwaway
   target `isle wipe` + `leakcheck baseline`. The **offline cache is not
   touched** — ci-9's cache is an optimisation, and re-downloading it every
   test run costs time and buys no honesty.
4. **Build** — the same builders, jmods JDK and cache as `polari-dev-build`.
   A test run that built differently would be testing a different artifact
   from the one anybody ships.
5. **Scan — ADVISORY** (`scan/scan.sh`, scn-0): Trivy (fs, images, unpacked
   debs) and gitleaks from pinned containers, plus `pip-audit` and `npm audit`
   when the workspace image carries them (else skipped with a line). Every
   stage exits 0, reports land in `pool/test/<sha>/scan/<tool>.json` with a
   `SCAN_SUMMARY.md` of counts by severity per tool. **No finding gates
   anything, ever** — his standing rule.
6. **Test** — two halves, because they need different machines:
   * the **module selftests** (`selftests.sh`), which need no isle: every
     module named in `CI_ISLE_STAGES` plus `core` (the framework's own
     packages), each suite run as `docker run --rm prf-backend:staging python3
     -m <suite>` in the image the build just made. The discovery expression is
     `pol modules selftest`'s own, verbatim, so the two cannot disagree about
     what a module's tests ARE.
   * the **isle stages** — `polari-isle-test`'s existing loop, with
     `VERSION=test/<sha>`, so the results land beside the verdict.
7. **The verdict** (`verdict.py` — the ONE place the arithmetic lives):

   | verdict | when |
   |---|---|
   | `passed` | every configured module selftest passed **and** the isle stages recorded `core_ok` (which already requires a CLEAN hand-back from the product's own uninstall — ci-10) |
   | `failed` | something that RAN said no |
   | `partial` | nothing said no, but something that should have answered did not |

   **Today every run is `partial`, and the verdict says why in words:** the
   install + selftest cycle inside the throwaway guest is still the marked ci-3
   TODO, so every isle stage records `skipped`, `core_ok` stays false, and
   `promote main` therefore refuses. That is the rule holding, not a defect.

   `pool/test/<sha>/verdict.json` is the product of the job. Its Jenkins colour
   is **SUCCESS when it ran to the end** — a failed test is a recorded verdict,
   not a red build — and FAILURE only when a stage could not run.

### The queue: one item deep, latest wins

His addendum, same day: *"we should only be running if we detect a change and
then do not detect any more changes elsewhere within 5 minutes… We should not
be endlessly queuing jobs… if multiple changes come in we just keep putting it
off and do the LAST one that came in for that queue."*

- **Quiet period, across the forest.** The jobs carry `quietPeriod(300)`, and
  `quiet.sh check` re-reads the superproject **and every top-level submodule
  remote** with `git ls-remote`. If anything moved inside the window the run
  ends as `NOT_BUILT` with *"changes still landing — re-polled"*, rather than
  building half a promotion. A finished `pol jenkins promote` writes
  `pool/promotions/<branch>/<sha>.json` naming the whole sha set; a live forest
  that still matches that marker is treated as quiet **immediately** — the
  marker is a promise that no more commits are coming, so the timer would only
  delay the run for nothing. Without a marker (a hand push, a push from another
  machine) the timer is the only evidence there is, and it is used.
  **The marker is device-local.** `pol jenkins promote` writes it into the pool
  of the machine it runs on. Promoting from a developer box while the pipeline
  lives on another device therefore leaves the pipeline with no marker, and it
  waits out the five minutes — correct, just slower. Promoting **on** the
  pipeline device gets the fast path. A shared marker would mean the promoting
  machine could write into the pipeline's pool, which is a door nobody has
  asked for and the timer costs five minutes.
- **One item, and it means "the newest state".** `pool/queue/<branch>.json`
  holds at most one pending item. A newer change while one is pending REPLACES
  it and restarts the clock; a newer change *during* a run sets that same
  single item rather than queuing a second. No backlog can form. Because the
  item never named a sha, the run checks out the branch **tip**.
- **A poll cannot land on the boundary.** With a five-minute tick and a
  five-minute window, the tick that should pass arrives a few seconds early —
  the pipeline device measured *"only 296s of quiet, 4s to go"* — and the run
  would then wait a whole further tick. `CI_QUIET_GRACE_S` (30) is a rounding
  allowance on the poll, not a weakening of the window. The jobs also carry **no
  Jenkins `quietPeriod`**: it would stack another five minutes on top of the one
  `quiet.sh` already enforces, and coalescing comes from the jobs being
  non-parameterised, not from the quiet period.
- **Deferral is unbounded by default** (`CI_QUIET_MINUTES=5`,
  `CI_MAX_DEFER_MINUTES=0`): a branch that keeps changing keeps getting put
  off, which is what he asked for. Setting `CI_MAX_DEFER_MINUTES` lets a run
  proceed anyway after that long, and the log calls it an override.
- **Two queues, never concurrent, alternating.** `test` and `main` are separate
  jobs, so separate queues; both take the `polari-build` lockable resource, so
  they never run at once. The Lockable Resources plugin grants waiting builds
  FIFO, which already alternates them under a steady stream; `quiet.sh turn` is
  the guard for the case FIFO cannot cover. A job that ran last and finds the
  other side pending **yields by ending** (`NOT_BUILT`) rather than sleeping —
  sleeping would hold the build lock and an executor while starving the very
  job it is trying to let through, and the pending item survives untouched.
- **Nothing is parameterised on a poll path.** Jenkins coalesces queued items
  of a non-parameterised job; two parameterised items with different values
  would both sit and both run. So `polari-release` mints its version inside the
  run and takes the offline-medium knob from the device
  (`CI_BUILD_OFFLINE_MEDIUM`); `polari-release-manual` keeps the parameters and
  nothing polls it.

## The release rule — only what is tested is released

**ci-12 changed WHERE the testing happens, not whether.** It used to be a
`polari-isle-test` run fired from inside the release job. It is now the test
branch: `pool/test/<sha>/verdict.json` is written before the decision to
promote is ever made, and `polari-release` reads it and **re-runs nothing**.
Results are carried over, because the whole point of the branch model is that
the thing released is the thing tested — re-testing at release time would test
a different moment from the one the decision was made on.

The sha is read from the release manifest the build wrote
(`release.json` → `components.superproject.sha`), and **every publish route
re-reads the verdict itself** (`routes/_lib.sh`), so triggering
`polari-publish` by hand on an untested build is safe.

- **no verdict for this sha** → every route prints
  `DRY (no passed test run for <sha> — push to test first)` and **the tag is
  not pushed**;
- **`failed` or `partial`** → same, and the route repeats the verdict's *own*
  reason rather than a generic one;
- **an app the isle stages did not record as `pass`** → its deb is left out of
  the release assets and named under *"not released: untested/failed"* in the
  job log and in the release notes.

**The rule is asked at the GATE, and its refusal is a RECORDED OUTCOME**
(ci-12 addendum 7). `quiet.sh gate main` already reads main's tip with one
`ls-remote` before any checkout, and the verdict is keyed on exactly that sha —
so `quiet.sh release-rule main <sha>` answers "may this be released?" there, for
the cost of reading one file, instead of after a full build. When it refuses:

- `pool/release/<sha>/refused.json` records the sha, the verdict it found, the
  reason and the time;
- the sha becomes **covered** — `pol jenkins queue` reads
  `main   covered <sha> (refused: no passed verdict)` — so the ten-minute tick
  does not re-run it;
- the build ends **NOT_BUILT, never FAILURE**. The colour says whether the job
  RAN; the refusal says what the rule found.

It re-arms itself in exactly two cases: **main moves**, or **that sha's test
verdict changes**. Promote the sha to `test`, let `polari-test` record `passed`,
and the next tick releases it with nobody touching `main`. (Before this,
`polari-release` #84/#85/#86 all ran on the same sha ten minutes apart, each
re-deriving the same refusal and going red for it.)

ci-10's coupling is not lost, it moved: the verdict already required the isle
stages' `core_ok`, which already required a CLEAN hand-back from the product's
own `isle uninstall --everything`. The rule is now enforced **once, where it is
computed**, instead of twice in two places that could drift.

It is a **testing** rule, not a security gate — and it is hard: `DRY_RUN=false`
does not override it. `polari-release` triggers `polari-isle-test` with
`build job: … wait: true` (the simplest Jenkins shape that works: no
upstream/downstream plumbing, just a job that takes `VERSION`) and reads the
results before the tag stage.

Plans: `AI-Notes/plans/CICD_PIPELINE_PLAN.md` (§1 shape, §2 the deployment
pipeline, §5 ci-6 publication routes) and
`AI-Notes/plans/SCANNING_AND_RELEASE_AUTOMATION_PLAN.md` (§3b release
automation). **No artefact test stages yet** (his instruction 2026-09-07);
the placeholders are marked in the pipelines.

```
polari-jenkins/
├── setup.sh                  `pol jenkins setup` — the one-shot walkthrough (it REUSES doctor + preflight)
├── setup/steps/*.sh          one file per step: role, checkout, network, secrets, isle, stages, controller
├── SETUP_STATUS.md           written by setup: done / still to do, in order (gitignored)
├── docker-compose.yml        the controller (built-in node runs the jobs; docker socket mounted)
├── .env.example              copy to .env — paths, UID/GID, docker GID; .env is gitignored
├── device.env.example        THE PIPELINE DEVICE (ci-7): where the throwaway isle goes, the floors, CI_ROUTES, CI_ISLE_STAGES
├── device.sh                 the device configuration in one place (loaded by the CLI, the doctor and the pipelines)
├── secrets.sh                WHERE the secrets live and who may read them (the two postures)
├── init-device.sh            `sudo pol jenkins init-device` — the polari-ci user + /etc/polari-jenkins/secrets
├── doctor.sh                 (B) what is configured, what is not, and what to do about each
├── mint-tag.sh               polari-vYYYY.MM.DD[.N] — the release version/tag
├── selftest.sh               the ci-7/ci-7b tests (no docker, libvirt, sudo or network needed)
├── isle/preflight.sh         (A) is the device CLEAR and does it have room? exit 4 = refused
├── isle/authorize.sh         `pol jenkins isle authorize <alias>` — the PIPELINE user's own key onto the isle device
├── isle/app-debs.sh          a stage's app debs — a THIN VERB over polari-framework's appstore/custom/app_deb_builder.py
├── isle/throwaway.sh         the throwaway isle VM: up | verify | uninstall | down | wipe | status (local or over ssh)
├── isle/guest-uninstall.sh   ci-10: the PRODUCT'S OWN `isle uninstall --everything` run inside the guest, as a TEST
├── isle/wipe.sh              ci-10: remove everything the pipeline made on the target and NOTHING else (the polari-ci- tag)
├── isle/leakcheck.sh         ci-10: baseline | check | report | snapshot — did anything survive the wipe?
├── isle/footprint.{sh,py}    "is this device clear of Polari?", read from os-security/inventory.sh
├── controller/Dockerfile     jenkins lts + plugins + the build toolchain (docker cli, jdk21/jpackage, node, dpkg-dev)
├── casc/jenkins.yaml         Configuration as Code: local admin, no anonymous, credentials FROM secrets/, seed job
├── casc/plugins.txt          the plugin set
├── jobs/seed.groovy          Job DSL: polari-dev-build, polari-release, polari-publish, polari-isle-test
├── pipelines/Jenkinsfile.*   the four declarative pipelines (dev-build, release, publish, isle-test)
├── routes/<route>.sh         ACTIVE routes: github-release, apt-repo, ghcr, homebrew — each `arm`s itself (ARMED / DRY)
├── routes/later/             PARKED routes needing an outside account/review (dockerhub, npm, pypi, launchpad, snap)
├── pool/                     build output on the host (gitignored): pool/<polari-version>/…
└── secrets/                  AUTH MATERIAL — gitignored except README + *.example
    ├── admin/                jenkins_admin_password
    ├── github/               release_token (the release pool + the homebrew tap), registry_token (the container registry), github_ssh_key (optional)
    ├── registries/           (dockerhub_* = parked)
    ├── signing/              apt_signing_gpg (armored private key), apt_signing_keyid, cosign_key, cosign_password
    ├── packaging/            (parked routes) npm_token, pypi_token, snapcraft_login, launchpad_ssh_key — not declared to Jenkins today
    └── ssh/                  distribution_host_key (deploy key for the apt/downloads VM)
```
**The names say what the token is FOR, and every listing says where it GOES**
(ci-12, his ask). `github/release_token` is the fine-grained PAT that creates
the release and pushes the tag; `github/registry_token` is the classic PAT that
writes packages — a fine-grained token cannot. `pol jenkins secrets status`, the
doctor's route rows and the setup all print
`name — destination — routes — present/absent`, and the **destination is
rendered from `routes/destinations.sh`** — the very constants the route scripts
push to, so a listing cannot promise something a route does not do, and in APP
mode it names the developer's own namespace rather than upstream's. `bash
polari-jenkins/routes/destinations.sh` prints the table on its own.

The pre-ci-12 names (`github/github_token`, `registries/ghcr_token`) are still
read by every route; the doctor WARNs once with the exact rename, and
`sudo pol jenkins secrets mv <old> <new>` does it in place, keeping mode and
owner — the value never passes through the shell.

Each secret is ONE FILE whose name is the variable Jenkins sees (mounted at
`/run/secrets`, read by Configuration as Code as `${name}`). Missing files
are fine: the credential exists with an empty value, the route stays DRY and
names the file it wanted. See `secrets/README.md` for **where** they live —
`/etc/polari-jenkins/secrets` after `sudo pol jenkins init-device`.

## A fresh pipeline device, in order (ci-7)

`pol jenkins setup` does all of the below for you, in order, asking once per
step. This is what it is doing, for when you would rather type it yourself.

The machine that runs Jenkins and the machine that hosts the **throwaway
isle** no longer have to be the same one — `device.env` decides. Setting up
a fresh box:

```
# 1. the checkout
git clone --recursive https://github.com/dausume/polari-suite.git && cd polari-suite
bash polari-cli/shells/install-cli.sh

# 2. the secrets posture (C) — creates the polari-ci system user and
#    /etc/polari-jenkins/secrets (root:polari-ci 0750, files 0640)
sudo pol jenkins init-device

# 3. where the throwaway isle goes, and what each isle tests
pol jenkins target local            # this machine (needs /dev/kvm + libvirt + RAM)
pol jenkins target ssh <alias>      # another device over ssh (an ALIAS, never an address)
pol jenkins isle authorize <alias>  # ssh target only — the PIPELINE user's own key onto that device
pol jenkins stages                  # CI_ISLE_STAGES — what may ever be released

# 4. the secrets (value from stdin — never a shell argument)
pol jenkins secrets put github/release_token    # fine-grained PAT: Contents read+write on the release repo AND the tap
pol jenkins secrets put github/registry_token   # CLASSIC PAT: write:packages + read:packages

# 5. the controller
pol jenkins up                      # UI at http://127.0.0.1:8080; runs the doctor afterwards

# 6. prove it
pol jenkins doctor                  # (B) every check, and what to do about each WARN
pol jenkins preflight --isle        # (A) is the device clear and does it have room? exit 4 = refused
```

First login: user `admin`, password = the `admin/jenkins_admin_password`
secret (generated by `pol jenkins up` if missing, printed once).

Day to day: `pol jenkins status` (compose ps + UI health + secrets + doctor),
`pol jenkins logs` (secret NAMES only, never values), `pol jenkins down`.

## The pipeline device (A) (B) (C)

**(A) `pol jenkins preflight [--isle] [--json]`** — a **resource guard, not a
security gate**. Before a run that creates a throwaway isle it proves, as a
table of `check | value | floor | verdict`: the target is reachable (and has
`sudo -n`), `/dev/kvm` and nested KVM are there, free RAM ≥ VM + headroom
(plus the controller's 2 GB and a build's 3 GB when everything is serialised
on one device), free disk on the libvirt image directory ≥ VM disk + floor,
`virt-install`/`qemu-img`/`virsh`/a cloud-init seed tool are installed, the
pool floor holds, **no VM of our name exists**, and **the device carries no
Polari/isle footprint of its own** — read with `os-security/inventory.sh`,
the same reading `pol deploy inventory` shows. A footprint on an **ssh**
target is a FAIL with the list printed: a device that is somebody's live
isle is not a throwaway. Any FAIL = exit 4.

**(B) `pol jenkins doctor [--strict]`** — every check prints `OK` or
`WARN <what is wrong> → <what to do>`; it **never refuses** (exit 0), so it
also runs at the end of `pol jenkins up` and `pol jenkins status`.
`--strict` exits non-zero on any WARN, for a gate.

**(C) the secrets** — `sudo pol jenkins init-device` creates the `polari-ci`
system user the controller runs as and `/etc/polari-jenkins/secrets`
(`root:polari-ci 0750`, files `0640`): readable by **root via sudo** and by
**the pipeline process**, by nobody else — not by the logged-in human, not by
anything they run. Until it has run, the fallback is `./secrets` and the
doctor says loudly that those are readable by every process of that user.
Details: `secrets/README.md`.

### The pipeline user's own key to the isle target (§76 addendum 3)

`init-device` also gives `polari-ci` **its own ssh key** —
`jenkins_home/.ssh/id_ed25519`, `0600`, comment `polari-ci@<CI_DEVICE_NAME>`
(the device's chosen name, never a hostname). The controller's `HOME` *is*
`jenkins_home`, so inside it a plain `ssh <alias>` finds that key, that
`config` and that `known_hosts`; nothing in `device.env` knows about keys.

**Why it exists.** Before it, the isle target was reached with the
*interactive* user's key. After `init-device` the controller runs as
`polari-ci`, which cannot read that user's `~/.ssh` at all — so
`polari-isle-test` refused at its own preflight with `target reachable …
FAIL` while `ssh <alias>` from a shell still worked perfectly (found live,
ledger §76 addendum 2).

**One verb closes it**, run by the person who already reaches the target:

```
pol jenkins isle authorize <alias>      # not sudo — it uses YOUR working alias
```

It reads the pipeline user's **public** key, resolves the alias with
`ssh -G <alias>` (so the controller's entry is the same destination a person
proved, not a second description of it), **verifies** the target's host key
against that person's own `known_hosts` and **refuses on a mismatch or on
nothing to compare against** — `ssh-keyscan` alone would make a MITM
permanent — appends the key to the target's `authorized_keys` through the
working alias, and writes `jenkins_home/.ssh/{config,known_hosts}` owned by
`polari-ci`, `0600`. A second run adds nothing, anywhere. Neither file is
ever tracked: the **address lives in `~/.ssh/config` and there only**.

Two doctor rows say whether it worked, and they are about the *pipeline*, not
about your shell:

```
OK  controller → isle target   — the pipeline user reaches <alias> with its own key, no prompt (BatchMode)
OK  controller target sudo -n  — the pipeline user's login on <alias> has passwordless sudo
```

Both are read with `docker exec polari-jenkins ssh -o BatchMode=yes <alias>
…` — asking the controller itself, because that is the only hop an isle
stage ever makes. The interactive user's key is untouched, and the
CLI-from-a-shell path keeps working exactly as it did.

**And the half no key could have fixed.** The first live doctor run on the
pipeline device answered:

```
WARN  controller → isle target — the pipeline user cannot reach <alias> (No user exists for uid 999)
```

Compose starts the controller as the *host's* `polari-ci` uid, which the
image knew nothing about — and `ssh` calls `getpwuid()` and dies before it
parses an argument, so even `ssh -V` failed inside the container. The image
now takes `JENKINS_UID`/`JENKINS_GID` as **build args** (compose passes what
`init-device` wrote into `.env`) and carries a passwd entry for that uid whose
home is `/var/jenkins_home` — `ssh` expands `~/.ssh` from `pw_dir`, **not**
from `$HOME`. Changing the arg rebuilds the layer, so `pol jenkins up` is
enough. The doctor reports that cause separately, because its fix is the
rebuild and not `authorize`.

**The throwaway VM** — `isle/throwaway.sh up|verify|down|status` (also
`pol jenkins isle …`): one script for both targets (with `CI_ISLE_TARGET=ssh`
it copies itself to the device and runs there), an Ubuntu 24.04 cloud image
cached under the pool, a qcow2 overlay, a cloud-init seed, and an ssh key
**generated per run**, kept `0600` under the pool and deleted by `down`. The
deb-install → core-install → verify cycle inside the guest is **ci-3**, marked
TODO in `pipelines/Jenkinsfile.isle-test`.

### Wiping between stages, and checking for leaks (ci-10)

*His ask 2026-09-19: "ensure we are capable of wiping the registered ssh
location and removing the isle there so we can deploy new ones each time
without causing memory issues, and we should be checking in between to make
sure we are not missing things and having leaks between things as well" — with
the addendum "we should be using the normal isle wiping functionality so that
it acts as a de jure test of that as well."*

The teardown is **three things**, in order, and they answer three different
questions:

| layer | verb | the question | whose failure | what it gates |
|---|---|---|---|---|
| 1 | `pol jenkins isle uninstall` | can the PRODUCT hand this machine back? | the product's | **the release** — `core_ok` requires a `clean` verdict |
| 2 | `pol jenkins isle wipe` (and the end of `down`) | remove what WE made, and nothing else | — | nothing; it is the cleanup |
| 3 | `pol jenkins isle leakcheck check` | did anything of ours survive the wipe? | the pipeline's | **the next stage** — a persistent leak stops the run |

**Layer 1** runs the product's real path inside the guest —
`sudo ISLE_CONFIRM_DELETE=yes isle uninstall --everything --force` (backup →
`destroy --purge` → `network-handback` → volumes → apt purge of the family →
its own zero-footprint verify) — and then the **hand-back proof**: a default
route, public DNS, `apt-get update`, and a network manager that owns the
interfaces. Verdict `clean | dirty | failed | skipped`, written to
`pool/<version>/isle-test/uninstall-<stage>.json`. **`skipped` is not a pass**:
until ci-3 installs anything, every stage is `skipped` and therefore nothing is
releasable — which is the honest reading.

**Layer 2** is scoped by the `polari-ci-` tag (`CI_WIPE_TAG`): the domain, its
disks/seeds/overlays, per-run libvirt volumes and networks, a stray
`qemu-system` still holding the guest, `/tmp/polari-ci-*`, the per-run ssh key
(shredded) and the run dir. It prints **both** lists — what it removed, and
what it found and deliberately left alone. `--dry-run` lists. The offline
cache, the pool and the directory the wipe is itself running from are never
touched.

**Layer 3** diffs the target against a baseline taken before stage 1: VMs,
networks, volumes, files (name + bytes), the Polari footprint, mounts,
listening ports, processes with RSS, `MemAvailable`, swap and free disk.
Anything NEW is a leak; so is RAM more than `CI_LEAK_RAM_TOLERANCE_MB` (512) or
disk more than `CI_LEAK_DISK_TOLERANCE_MB` (1024) below the baseline — **memory
that did not come back is exactly the "memory issues" the ask names**. A leak
re-wipes once, re-checks, and if it persists the run STOPS before the next
stage (`CI_LEAK_POLICY=continue` opts out). `pol jenkins preflight --isle`
gains a `residue from an earlier run` row that FAILs and names the wipe.

## What the jobs do
| job | trigger | does | pushes anywhere? |
|---|---|---|---|
| polari-dev-build | poll `dev` every 10 min | the **optional quick build**: debs (both flavors) + images. No tests, no scans, no publish | no |
| **polari-test** | poll `test` every 5 min | **the testing pipeline**: wipe this device → build → advisory scans → module selftests + the isle stages → ONE verdict at `pool/test/<sha>/verdict.json` | **never** |
| polari-release | poll `main` every 10 min | mints `polari-vYYYY.MM.DD[.N]`, builds, writes `release.json` + `SHA256SUMS` + the offline medium → `pool/<version>/`; reads the TEST VERDICT for the sha and pushes the tag **only when it says `passed` and a github credential is present**. Runs no tests | it triggers polari-publish with DRY_RUN=auto |
| polari-release-manual | manual only | polari-release with the two knobs exposed. Nothing polls it, so its parameters can never build a queue | as above |
| polari-publish | manual / from release | routes/*.sh per selected route | only when the route's secret is present AND the route is in `CI_ROUTES` (DRY_RUN=auto) |
| polari-isle-test | from **polari-test** (and manual) | preflight → for EACH stage of `CI_ISLE_STAGES`: build that stage's app debs → a fresh throwaway isle up → install + selftest (ci-3 TODO) → the product's own uninstall (a test) → down (which wipes) → a leak check → record. Writes `pool/<version>/isle-test/results.json`, `uninstall-<n>.json`, `leak-baseline.json` and `leak-check-<n>.json` | no — it decides what everything else MAY publish |

## Data retention (an automated process must never overwhelm the host)
- `retention.sh guard` runs FIRST in every build: refuses when free disk < `DISK_MIN_FREE_GB` (20).
- `retention.sh prune` runs LAST: keeps the newest `POOL_KEEP` (3) pool versions, removes older ones and the images tagged with them, prunes dangling layers. It never touches developer images (`prf-*:staging`), anything outside `pool/`, or any Polari instance data — the pipelines deploy nothing. **Nor the offline cache** (ci-9): `pool/cache` is exempt, and `retention.sh cache-prune [--older-than DAYS]` (= `pol jenkins cache prune`) is its only deleter, removing only entries whose `last_used` is older than the knob.
- Job history: dev-build keeps 5 runs / 2 artifact sets; release 10 / 3. Workspaces are cleaned after every run.
- ci-12: `pool/test/<sha>/` (the test runs **and their verdicts**), `pool/promotions/` (the markers the quiet-period check reads) and `pool/queue/` are **exempt** from the version prune — none of them is a version, and deleting a verdict would silently un-test a released sha. The test runs are bounded by their own count instead (`TEST_KEEP`, 5).
- ONE build at a time: a global `polari-build` lock across dev-build, **test**, release and publish. `polari-isle-test` locks `polari-isle-target` instead, because its caller already holds the build lock — it used to take `polari-build` and would have deadlocked the moment a parent waited on it.
- The poll queues are one item deep and latest-wins (`pool/queue/<branch>.json`), so no automated process can build a backlog of runs to work through.

## Tests
`bash polari-jenkins/selftest.sh` — the ci-7 … ci-12 tests, **600/600**. They
need **no docker, libvirt, sudo or network**: the scripts run against a temp
tree and PATH shims, covering the doctor's WARN wording per
misconfiguration, the preflight's PASS/FAIL arithmetic and the
device-is-clear reading, the tag minting (`.N`), the route arming, the
setup's role arithmetic and its "where to get it" table (every active
route's secret must carry a URL or a generate command), `--report` with no
terminal, setup idempotence and the skip path, the `CI_ISLE_STAGES` parsing
and its unknown/twice/empty warnings, and the tested-only release rule
(no results → all DRY · `core_ok` false → all DRY · a failed app excluded
from the assets · `DRY_RUN=false` cannot override it), and ci-8's two modes
plus the sync with Polari (a pull rewrites `device.env` from a fixture, a
core that is down or answers invalid settings leaves the file alone, and a
push carries presence and never a value), and ci-9's offline cache and app
mode (the manifest's four fields per entry, `cache-prune` dropping only what
`last_used` says is stale and KEEPING an entry whose stamp it cannot read,
the report arithmetic, the network fallback when the cache is empty or off,
`retention.sh prune` leaving the cache alone, tier two refusing to start
while its knob is off, the setup's mode question in `--report`,
`core-artifacts.sh resolve` against a fixture release list, and app-mode
release filtering — one deb, `tested_against` recorded, an upstream target
refused), and §76 addendum 3's **pipeline user's key** (authorize refusing
before `init-device` has made one, the `config` rendered from `ssh -G`, a
second run adding nothing to `authorized_keys`, the controller's `config` or
its `known_hosts`, a host key that is not the one your `known_hosts` already
trusts REFUSED with both fingerprints and nothing written, no reference to
verify against also refused, and the two `controller → isle target` doctor
rows). It prints `N/N`.

## Not yet
The `ReleasePublication` rows in Polari (ci-6a), agent nodes beyond the
built-in one, and — the big one — the **deb-install cycle inside the
throwaway isle (ci-3)**: install the core debs, `isle core-install`, verify,
install each stage's app debs, run `pol modules selftest <app>` in the
guest, uninstall and prove the hand-back. Until that exists every stage
result is `skipped`, `core_ok` stays false, and the release rule therefore
publishes **nothing**. That is deliberate — the gate is honest before it is
convenient.

⚠ One honest caveat on the LOCAL isle target: this controller is a
container and libvirt lives on the host, so `CI_ISLE_TARGET=local` needs
either the libvirt socket mounted into the controller (a posture change
nobody has authorised) or a host-tier agent. The **ssh** target has no such
problem — which is much of why ci-7 makes the device configurable.

## ci-13 — what a test run keeps, and the prepared base

- Test-built images are DISCARDED after the run (`test-wipe.sh --images-only` in `Jenkinsfile.test`'s post);
  only a release keeps its images. `CI_KEEP_TEST_IMAGES=1` keeps them for a look.
- The throwaway's prerequisites are baked ONCE into a prepared base (`<cache>/cloud/prepared-<key>.qcow2`,
  key = cloud image + `CI_ISLE_PREREQ_PKGS`); later runs skip ~6 min of apt. `CI_ISLE_PREPARED=off` boots the
  bare cloud image every time.
- A Polari installed by the pipeline says so: `/etc/polari/pipeline-test` + `POLARI_PIPELINE_TEST=1`;
  `/api/health` reports `pipelineTest: true`.
