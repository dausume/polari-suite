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
├── isle/throwaway.sh         the throwaway isle VM: up | verify | down | status (local or over ssh)
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
deb-install → core-install → verify → uninstall cycle inside the guest is
**ci-3**, marked TODO in `pipelines/Jenkinsfile.isle-test`.

## What the jobs do
| job | trigger | does | pushes anywhere? |
|---|---|---|---|
| polari-dev-build | poll `dev` every 10 min | recursive checkout, build the debs (both flavors) + images | no |
| polari-release | poll `main` every 10 min | mints `polari-vYYYY.MM.DD[.N]`, builds, writes `release.json` + `SHA256SUMS` + the offline medium → `pool/<version>/`, pushes the tag **only when a github credential is present** | it triggers polari-publish with DRY_RUN=auto |
| polari-publish | manual / from release | routes/*.sh per selected route | only when the route's secret is present AND the route is in `CI_ROUTES` (DRY_RUN=auto) |
| polari-isle-test | from polari-release (and manual) | preflight → for EACH stage of `CI_ISLE_STAGES`: build that stage's app debs → a fresh throwaway isle up → install + selftest (ci-3 TODO) → record → down. Writes `pool/<version>/isle-test/results.json` | no — it decides what everything else MAY publish |

## Data retention (an automated process must never overwhelm the host)
- `retention.sh guard` runs FIRST in every build: refuses when free disk < `DISK_MIN_FREE_GB` (20).
- `retention.sh prune` runs LAST: keeps the newest `POOL_KEEP` (3) pool versions, removes older ones and the images tagged with them, prunes dangling layers. It never touches developer images (`prf-*:staging`), anything outside `pool/`, or any Polari instance data — the pipelines deploy nothing.
- Job history: dev-build keeps 5 runs / 2 artifact sets; release 10 / 3. Workspaces are cleaned after every run.
- ONE build at a time: a global `polari-build` lock across dev-build, release and publish; a newer dev trigger aborts the running dev build (latest commit wins).

## Tests
`bash polari-jenkins/selftest.sh` — the ci-7/ci-7b tests, **120/120**. They
need **no docker, libvirt, sudo or network**: the scripts run against a temp
tree and PATH shims, covering the doctor's WARN wording per
misconfiguration, the preflight's PASS/FAIL arithmetic and the
device-is-clear reading, the tag minting (`.N`), the route arming, the
setup's role arithmetic and its "where to get it" table (every active
route's secret must carry a URL or a generate command), `--report` with no
terminal, setup idempotence and the skip path, the `CI_ISLE_STAGES` parsing
and its unknown/twice/empty warnings, and the tested-only release rule
(no results → all DRY · `core_ok` false → all DRY · a failed app excluded
from the assets · `DRY_RUN=false` cannot override it). It prints `N/N`.

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
