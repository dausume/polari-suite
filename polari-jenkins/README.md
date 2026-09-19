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
whole pipeline its point: **only what was TESTED in a throwaway isle is ever
released.**

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
| 5 | the throwaway-isle target | local vs ssh, the `~/.ssh/config` block, `ssh-copy-id`, the sudoers drop-in shown verbatim and applied on yes, libvirt over ssh, the VM knobs, then a real `preflight --isle` |
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

## The release rule — only what is tested is released

The throwaway isle is what the pipeline *analyses*. `polari-isle-test` runs
every stage of `CI_ISLE_STAGES` in its **own** isle, one at a time, and
writes `pool/<version>/isle-test/results.json`. That file decides what may
leave this machine:

- **no `results.json` for a version** → every route prints
  `DRY (no isle-test results for <version> — the pipeline only releases what
  it tested)` and **the tag is not pushed**;
- **`core_ok` false** → same: the core itself is untested, so nothing ships;
- **an app whose stage result is not `pass`** → its deb is left out of the
  release assets and named under *"not released: untested/failed"* in the job
  log and in the release notes.

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
    ├── github/               github_token (releases), github_ssh_key (optional)
    ├── registries/           ghcr_token (dockerhub_* = parked)
    ├── signing/              apt_signing_gpg (armored private key), apt_signing_keyid, cosign_key, cosign_password
    ├── packaging/            (parked routes) npm_token, pypi_token, snapcraft_login, launchpad_ssh_key — not declared to Jenkins today
    └── ssh/                  distribution_host_key (deploy key for the apt/downloads VM)
```
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
pol jenkins stages                  # CI_ISLE_STAGES — what may ever be released

# 4. the secrets (value from stdin — never a shell argument)
pol jenkins secrets put github/github_token
pol jenkins secrets put registries/ghcr_token

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
| polari-dev-build | poll `dev` every 10 min | recursive checkout, build the debs (both flavors) + images | no |
| polari-release | poll `main` every 10 min | mints `polari-vYYYY.MM.DD[.N]`, builds, writes `release.json` + `SHA256SUMS` + the offline medium → `pool/<version>/`, pushes the tag **only when a github credential is present** | it triggers polari-publish with DRY_RUN=auto |
| polari-publish | manual / from release | routes/*.sh per selected route | only when the route's secret is present AND the route is in `CI_ROUTES` (DRY_RUN=auto) |
| polari-isle-test | from polari-release (and manual) | preflight → for EACH stage of `CI_ISLE_STAGES`: build that stage's app debs → a fresh throwaway isle up → install + selftest (ci-3 TODO) → the product's own uninstall (a test) → down (which wipes) → a leak check → record. Writes `pool/<version>/isle-test/results.json`, `uninstall-<n>.json`, `leak-baseline.json` and `leak-check-<n>.json` | no — it decides what everything else MAY publish |

## Data retention (an automated process must never overwhelm the host)
- `retention.sh guard` runs FIRST in every build: refuses when free disk < `DISK_MIN_FREE_GB` (20).
- `retention.sh prune` runs LAST: keeps the newest `POOL_KEEP` (3) pool versions, removes older ones and the images tagged with them, prunes dangling layers. It never touches developer images (`prf-*:staging`), anything outside `pool/`, or any Polari instance data — the pipelines deploy nothing. **Nor the offline cache** (ci-9): `pool/cache` is exempt, and `retention.sh cache-prune [--older-than DAYS]` (= `pol jenkins cache prune`) is its only deleter, removing only entries whose `last_used` is older than the knob.
- Job history: dev-build keeps 5 runs / 2 artifact sets; release 10 / 3. Workspaces are cleaned after every run.
- ONE build at a time: a global `polari-build` lock across dev-build, release and publish; a newer dev trigger aborts the running dev build (latest commit wins).

## Tests
`bash polari-jenkins/selftest.sh` — the ci-7/ci-7b/ci-8/ci-9 tests, **235/235**. They
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
refused). It prints `N/N`.

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
