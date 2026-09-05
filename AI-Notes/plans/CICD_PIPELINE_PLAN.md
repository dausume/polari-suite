# CI/CD pipeline (ci arc): Jenkins at the host tier ALONGSIDE the isle, GitHub-triggered, deployment first — images, apt repo, deb store on merge to main; builds AND tests isles; a Polari module mirrors it

**Date:** 2026-09-04 · **Status: PLAN (ci-0). No code changed.** His
framing: "we primarily do our work on github … a jenkins pipeline that
interacts with github and enables analyzing the code and we can also use
it to update images on a docker image repository as well as potentially
the apt repository and deb app store … focusing on just the deployment
portion first which should trigger when we merge to main. We will want
the jenkins instance itself to be able to be a module and isle app as
well, this way it can be on the isolated isle and be used on the
internet without exposing the underlying systems as much." — then his
correction the same hour: "maybe Jenkins does not actually make sense to
turn into an isle app in that case, it belongs at the same level as
docker and is the thing performing building. The pipeline we use should
not be incorporated into the isle but run alongside it then. Since part
of its purpose is to build and test isles." **RULING: Jenkins is a
HOST-TIER service (like docker and libvirt) on the build box, running
ALONGSIDE the isle, never inside it; it builds images and debs AND
creates/tests/destroys isles. The Polari `cicd` module stays as a
MIRROR of its runs; the isle-app pairing is dropped.**

Companion: `PRODUCTION_DEPLOY_PLAN.md` (prd) — its prd-5 release script
is exactly what the deployment pipeline runs; this plan makes it
automatic. Precedent copied deliberately: the islemesh acceptor
discipline (the builder pushes run state, Polari mirrors, nothing in
Polari can drive the builder). The Odoo isle-app pairing was the first
draft's model and is dropped with his correction.

## 0. Verified starting point

- No CI exists: no `.github/workflows` in any of the eight repos, no
  Jenkins/Actions mention in AI-Notes. Pushes are his ritual
  (`polari-cli/shells/push-all-dev.sh --push [--with-isle]`).
- `origin/main` is far behind `dev` (last main commits: "implementing
  changes to fix prod setup - 6"); all work lands on `dev` and phase
  branches. A "merge to main" trigger therefore implies a **dev → main
  promotion ritual** that does not exist yet (§3, ci-1 defines it).
- Build/publish pieces that exist and the pipeline will call, never
  reimplement: `pol node build backend frontend` (compose build),
  `pol build render|parity|promote` (bld-1), `./build-polari-isle-deb.sh`
  + `build-polari-complete-deb.sh` (the five platform debs; need docker
  + JDK 17 with jpackage), `build-offline-bundle.sh`, `pol modules
  publish <m>` (module repo split/push), `isle apt-repo publish` (signed
  flat repo for `apt.isle`), `isle app deploy --image … --engine …` (a
  third-party image as an isle app with an engine declaration →
  IsleEngine row → the consuming module's provider config, the odoo
  path), `isle url expose <name.isle> --port N` (an outside door through
  the agent, gated by the entrypoint flag, basic-auth, ledgered and
  pushed to Polari), `POLARI_TEST_BUILD` test image + `pol node up --env
  test` (integration tests), every module's `selftest_*.py`.
- Licence gate: Jenkins is MIT (core + the GitHub/Docker/Pipeline
  plugins are MIT/Apache-2); we DRIVE it as a separate container image
  and never copy its source — same stance as WireGuard/OpenVPN/Odoo
  (LGPL). Registry: `registry:2` (Apache-2, already proven as
  `registry.isle:5000`) or GHCR. Nothing NC anywhere in this stack.

## 1. Shape

```
GitHub (dausume/*)                 build box (pol-core / a builder; owned hardware, bare metal or nested-virt)
   main merged ◀──poll (ONLY)───── jenkins (HOST TIER: systemd or a host docker container next to
   (no webhook, no tunnel)         dockerd + libvirtd; JENKINS_HOME on the host; NOT an isle app)
                                       │ runs jobs on the SAME box (host executor) or on a
                                       │ second host-tier agent; the box has docker, libvirt/KVM,
                                       │ JDK 17, pol, the isle CLI, the registry credential,
                                       │ the apt signing key
                                       ├─ builds images ──▶ image repo (GHCR / registry.isle mirror)
                                       ├─ builds debs, publishes apt ──▶ apt.polari-systems.org + the pool
                                       ├─ BUILDS + TESTS ISLES: throwaway VMs → deb install →
                                       │    isle core-install → verify → isle uninstall --everything
                                       └─ pushes run state ──▶ polari (cicd module: mirror rows,
                                                                /display/cicd, downloads manifest)
```

- **Host tier, alongside the isle.** Jenkins is installed on the build
  box the way docker is (a systemd unit, or `jenkins/jenkins:lts` as a
  host container with `JENKINS_HOME` on a host volume) and is a member
  of nothing: not a mesh-app, not behind the isle agent, not in a
  compose stack of ours. It is the thing that BUILDS the isle debs and
  images and then PROVES them by creating an isle in a throwaway VM and
  destroying it — which is why it cannot live inside an isle (an isle
  cannot create, test and uninstall itself) and why the build box must
  have libvirt/KVM (pol-core and isle-core qualify; a cloud VM without
  nested virtualization does not).
- **Nothing inbound, ever (his ruling 2026-09-04).** Jenkins polls
  GitHub (the git plugin's SCM polling, every 2–5 min); every other
  connection the pipeline makes is outbound (fetch, image push, rsync
  and apt publish to the droplet over ssh, HTTPS to Polari on the LAN).
  No webhook, no tunnel, no router forward, nothing on the LAN is
  reachable from the web. The isle's containment rule is untouched
  because Jenkins is not on the isle.
- **Least power, still.** The job that touches the docker socket, the
  registry credential, the signing key and libvirt is the host
  executor; if a second agent is added it is host-tier too. Jenkins'
  own web UI is LAN/isle-reachable only (bind to the build box's LAN
  address; browse it from inside the isle like any LAN service) —
  there is no public Jenkins URL in this design.
- **Polari mirrors, never controls** (unchanged): the `cicd` module
  holds `PipelineDefinition`, `PipelineRun`, `PipelineStage`,
  `ReleaseArtifact` (image tag / deb / apt index / pool upload / isle
  test VM result, with digests + versions + dates) and
  `ReleaseManifest` rows; the job POSTs run state to
  `POST /api/islemesh/ingest/cicd` at every stage; `/display/cicd` is
  tables + structured panels; the downloads page reads
  `ReleaseManifest` for version + date. Polari never holds a
  build-capable Jenkins token; a "run it" wish is a proposal row the
  job polls, the operator triggers on the Jenkins side. The odoo-style
  engine binding is NOT used (there is no isle app to declare an
  engine); the module's `CicdInstanceConfig.base_url` is set by hand
  (a knob) or from the first ingest.

## 2. The deployment pipeline (ci-2, the part he wants first)

Trigger: GitHub `push` to `main` of the SUPERPROJECT `polari-suite`
(submodule pointers are the release contract; module repos re-publish
from the framework push as today). Stages, each recorded as a
`PipelineStage` row with duration + result:

1. **checkout** — superproject at the pushed SHA, `git submodule update
   --init --recursive` (the pins), `polari-cli/shells/install-cli.sh`.
2. **version** — `<yyyy.mm.dd>-<short sha>` (calendar + sha; the
   downloads page shows both); written to `ReleaseManifest`.
3. **build images** — `pol node build backend frontend` for
   `prf-backend` (prd-2 adds the `-core` variant), `prf-frontend`,
   `prf-proxy`; tagged `<ver>` and `latest`.
4. **gate** — in-container selftests of every downloaded module
   (`pol modules selftest <m>` on the fresh image, the module list from
   `polari-modules.json`), `moduleService` drift tests, `pol build
   parity`; ci-3 adds `pol node up --env test` integration tests and
   the CDP browser pass. A red gate stops the pipeline; images built
   but not pushed are pruned.
5. **push images** — to the image repository of prd D3 (GHCR
   `ghcr.io/dausume/<image>:<ver>` by default; `registry.isle:5000`
   mirror for the home mesh) with digests recorded.
6. **platform debs** — `./build-polari-isle-deb.sh` +
   `build-polari-complete-deb.sh` on the agent (JDK present), versions
   stamped, `dpkg-deb --info` verified, sha256 recorded.
7. **apt + pool** — `isle apt-repo publish` pointed at the distribution
   server's pool (rsync over ssh with a deploy key; the server is the
   prd droplet), the pool manifest + `ReleaseManifest` updated, the apt
   index re-signed with the key that lives only on the agent.
8. **notify** — the run's final state pushed to Polari; the downloads
   page shows the new version + date; failures are rows with the
   failing stage's log tail, never a silent red.

Rollback = the previous `ReleaseManifest` (images are immutable tags;
the apt pool keeps N previous versions; `apt install
polari-complete=<ver>` works).

## 3. Phases

- **ci-0 — this plan.** ✅
- **ci-1 — dev BECOMES main, behind a readiness gate.** His ruling
  2026-09-04: "we are going to need to just make dev become the main
  because of how far behind main is. Before doing that we need to
  ensure everything is in a working state and that both docker swarm
  and deb routes both work still." So ci-1 is (a) the READINESS GATE
  (§3a) and (b) the one-time promotion: for the eight repos
  innermost-first, `git branch -f main dev && git push --force-with-
  lease origin main` (old main kept as `main-2026-pre-dev` tags), then
  the standing ritual `polari-cli/shells/promote-main.sh` = fast-
  forward main to dev, refuse if any submodule pin is not on its own
  main, tag `<ver>`; protect `main` on GitHub (PR-only, the pipeline a
  required check once ci-2 exists). No Jenkins yet — this is what
  "merge to main" will mean from then on.
- **ci-2 — Jenkins at the host tier + the deployment pipeline.**
  `polari-cli/shells/install-jenkins-host.sh` (host container or
  systemd unit on the build box, `JENKINS_HOME` on a host volume,
  plugins pinned in `plugins.txt`, UI bound to the LAN address, SCM
  polling of the superproject's `main`); the `Jenkinsfile` at the
  superproject root (declarative, stages 1–8 above; one job, `main`
  only); credentials (registry push, apt signing key, droplet deploy
  key) in the host Jenkins credentials store. Acceptance: a merge to
  main produces pushed images, five platform debs, an updated apt index
  and pool on the droplet, and a `ReleaseManifest` row — with no human
  in the loop after the merge and nothing listening on the internet.
- **ci-2c — build and test ISLES (the reason it lives at the host
  tier).** A stage that provisions a throwaway Ubuntu VM with libvirt
  (cloud-image + cloud-init, KVM on the build box), installs the freshly
  built `polari-complete` deb, runs `sudo isle core-install`
  unattended, verifies (the 7-step green of FRESH_INSTALL_DEBUG_HANDOFF
  turned into assertions: router VM up, agent up, polari.isle answers,
  apt.isle serves, CA minted), then `isle uninstall --everything
  --verify` and destroys the VM. Nested virtualization is required
  inside that VM for the isle's own router VM — the build box exposes
  it (`kvm_intel nested=1`); if it cannot, the stage runs the
  no-router variant (prd-7) and says so. Result rows = `ReleaseArtifact`
  kind `isle-test`. This is the "build and test isles" half of his
  purpose statement.
- **ci-2b — the `cicd` Polari module.** Rows + ingest + `/display/cicd`
  + engine binder + `pol cicd status|runs|artifacts`; the downloads page
  reads the manifest. (The pipeline works without it; it makes the
  pipeline visible inside Polari.)
- **ci-3 — the analysis pipeline (his "analyzing the code").** On PRs
  to dev and main: selftests, drift tests, `pol build parity`, the
  `pol node up --env test` integration suite, the CDP page pass, licence
  gates (LICENSE + header + API check — the mesh-asset rule), a
  dependency audit (the 16 dependabot vulns are a standing item), and
  size budgets (image sizes, frontend bundle budgets from prd-2) — all
  reported as rows, PR status checks, never auto-merge.
- **ci-4 — module repos.** The framework push re-publishes stale module
  subtrees today (`push-all-dev.sh`); the pipeline does it on main, and
  builds per-module debs into the pool so the store's on-demand builder
  finds them pre-built when they exist (the prd §2c pool option).
- **ci-5 — hardening.** Agent as a dedicated builder box; controller
  backups (`JENKINS_HOME` on an isle volume, in the isle backup set);
  the door's basic-auth rotated with `pol security rotate`; job
  timeouts; a "pipeline paused" knob when the droplet is unreachable.

### 3a. The readiness gate for "dev becomes main" (ci-1a)

Both routes proven from the SAME dev tip, recorded in TESTING_OWED,
before main is moved:
1. **Every phase branch decided**: merged to dev, or shelved with a
   ledger row (`AI-Notes/plans/shelved/README.md`). Nothing unmerged
   that main is expected to carry (the inventory is in §3b).
2. **Headless green**: every module's selftests in-container on the
   dev image (`pol modules selftest <m>` for the registry list), the
   moduleService drift tests, `pol build parity`.
3. **Swarm route**: `pol swarm deploy node` from a clean `.generated`
   on the 3-node home swarm (or 1-node), health 200, the live API
   passes of the last arcs (vpn runbook step 4–8, mealplan pages), the
   CDP browser passes (vpn 17/17, the mealplan forms) — the same checks
   that exist, run once against the promotion candidate.
4. **Deb route**: the FRESH_INSTALL flow on isle-core from pure code
   (`clone --branch dev` → `bootstrap-dev.sh` → `pol node build backend
   frontend` → `./build-polari-isle-deb.sh` → `sudo isle core-install`
   → 7 steps green → `https://polari.isle` answers → `isle uninstall
   --everything --verify` zeros). isle-core was fully purged 2026-08-26
   and the last green fresh install is 2026-08-19, so this must be
   re-proven, not assumed.
5. **Compose try-out** (the occasional route): `pol node up --env
   staging` boots and answers health — no full pass needed.
6. **Docs**: README / GETTING_STARTED_DEV say `main` where they say
   `dev` for a user, and the handoffs say which branch is which.

### 3b. Branch inventory at the time of the ruling (2026-09-04) — verified by CONTENT, not ancestry

**DONE the same day (his "make everything merge"):** every tip in the
table below except cnt-2 (superseded) and scan-1 (shelved) is merged
into `dev` (framework via `dev-merge-1`, cli, rf-node + superproject
pointers); results in TESTING_OWED §14. §3a step 1 is satisfied; steps
2–6 remain (the live swarm + deb re-proofs). NOT pushed.

His challenge ("all of that in theory should have already been merged
into dev … many of those things should also have been primarily in
module projects") was checked three ways: (1) `--no-merged` ancestry,
(2) whether each branch's NEW files exist anywhere on dev by basename
(survives the mp-4 moves into `modules/`), (3) whether the module
repos on GitHub carry them. Result: the work is genuinely absent from
dev AND from the module projects — because module repos are published
FROM dev (`push-all-dev.sh` re-publishes stale subtrees after the
framework push), a module whose branch never reached dev was never
split or published. Evidence: on dev `modules/collab/` holds one schema
file, `modules/scanning/` and `modules/mqttbridge/` are empty, none of
collab / reticulum / scanning / mqttbridge / video are in
`polari-modules.json`, GitHub has 42 `polari-module-*` repos = exactly
the registry (no collab / reticulum / mqttbridge / scanning), and
`polari-module-cntfet` (74 files) lacks fg-1/lad-1's
`cnt_fet_summary.py` / `cnt_block_pages.py` / `cnt_cell_pages.py`.
The mid-August deployments of these arcs were `docker cp` into the
running staging stack (memory: "swarm respawns from IMAGE — docker cp
is LOST") and the FULL PURGES of 08-17 and 08-26 removed them; the
running system today carries none of it.

The branches are STACKED, so the real merge set is five tips, not ten:

| Tip | Contains | Ahead of dev | Module code inside (would become module projects on publish) | Proposed |
|---|---|---|---|---|
| `dev-ai-1` | dyn-1 → mtg-1 → ret-1 → sep-1 → ai-1 | 49 | `modules/collab` (LiveKit meetings), `modules/reticulum`, `polariapps` / `appstore` / `islemesh` / `resources` changes, `accessControl/app_permissions_gate.py`, `polariApiServer/{feature_imports,live_admission,module_endpoints}.py` (dyn-1), `topology/baseline_profile.py` | **merge the chain via its tip** (one merge; conflicts in polariServer.py / polari-modules.json expected once) |
| `dev-ret-7` | ret-1 + 1 commit (the LXMF messages API) | 37 | `modules/reticulum` | **rebase the 1 commit onto the merged chain, then merge** |
| `dev-lad-1` | fg-1 → lad-1 | 17 | `modules/cntfet` pages (fet-summary, block/cell pages, level scenes, parts SVG, fam-1 families) | **merge** |
| `dev-cnt-2`  |  —  |  1  |  `modules/cntfet/cnt_results.py` + angular IV chart row | **NOT merged — superseded**: its bespoke I-V chart is the duplicate chart engine behind the 2026-08-25 standing rule (sci-xy-chart is the chart home), and fet-viz (merged 08-26) serves the curves as configured GraphDefinition rows over `/device/{name}/points`. Branch kept; nothing owed. |
| `dev-mqtt-1` | — | 1 | `modules/mqttbridge` (knob-gated, own stack) | **merge** |
| `dev-vpn-3` | vpn-1 | 2 | `modules/vpn` | **merge** after his review |
| `dev-scan-1` | dyn-1 + scan | 26 | `modules/scanning` (DA3 weights NC) | **shelve** — keep the branch, ledger row, never on main; delete nothing |

**Why each was never merged (from the plans, handoffs and memory —
his question 2026-09-04):** none records a technical blocker. The
standing rule was "commit on the phase branch; merge to dev = his go;
push = his ritual", and dev's merge history shows only arcs he asked
for by name (dl-1 on 08-24, cnt-1 / chip-1 / chip-2 / cmpc-1 on 08-26).
Per arc: dyn-1 "NOT merged — Dustin's review gate; 'might put changes
up after' = his call" (handoff has the merge checklist ready); mtg-1
complete, four blockers all human proofs (a signed-in join, a phone,
a headset, a drag design pass); ret-1/7 the licence finding was
resolved by pinning rns 0.9.4 / lxmf 0.6.3, the radio is a hardware
order — built overnight under authorized assumptions, awaiting review;
sep-1 all phases live 08-15, owed = his TESTING_OWED §0 walk; ai-1
complete, pending his three plan answers + credentialed proofs; fg-1
deployed + live-verified 08-31, suites 30/30, owed = his browser pass;
lad-1 (fam-1) built 08-31 on top of fg-1, "NOT merged/pushed — his
ritual"; cnt-2 one commit left out of the 08-26 consolidation with no
reason recorded; mqtt-1 one knob-gated commit with no plan of its own.
What hid it: the mid-August work was LIVE by `docker cp` and felt
present; the 08-17 and 08-26 purges removed it and nobody re-raised
the merges. A second effect: every image rebuilt from dev since (the
09-03 night run, the 09-03/04 vpn rolls) dropped fg-1/lad-1's pages
from the running system — branch-only work does not survive a rebuild.

After the merges: `pol modules publish collab|reticulum|mqttbridge|
vpn` splits the four new modules into their own repos (the mp-2
ritual) so the module-project rule holds again; the registry rows get
their `repo` URLs. Angular: merge `dev-cnt-2` (1), shelve `dev-scan-1`
(11). polari-cli: merge vpn-3, shelve scan-1. rf-node: `dev-nmp-1`,
`dev-ret-7`, `dev-scan-1`, `dev-vpn-*` are pointer branches — verify
each pin is covered, then delete.

## 4. Decisions (defaults in bold; his call)

- D1 trigger: **superproject main push** (submodule pins = the release)
  vs any repo's main (noisy; module repos re-publish anyway).
- D2 trigger transport: **DECIDED 2026-09-04 — Jenkins polls GitHub;
  no inbound, no tunnel, nothing on the LAN reachable from the web**
  ("if we can do everything needed for cicd without exposing our lan
  to the web that is the best option"). Everything the pipeline needs
  is OUTBOUND: git fetch from GitHub, image push to the registry, rsync
  over ssh TO the droplet, apt publish TO the droplet, HTTPS to
  Polari's acceptor on the LAN. Polling latency (2–5 min) is the
  accepted cost; a webhook is not planned.
- D3 image repository: **GHCR under `dausume/`** (free for public,
  same org as the repos) vs a `registry:2` on the distribution droplet
  vs DO's registry. `registry.isle:5000` stays the home mirror either way.
- D4 the build box: **pol-core** (docker, libvirt, the checkout, the
  isle CLI, bare metal) vs isle-core vs a dedicated builder. Must have
  KVM with nested virtualization for ci-2c.
- D5 versioning: **calendar + sha** vs semver (nothing consumes semver
  yet).
- D6 Jenkins image: **`jenkins/jenkins:lts-jdk17`** with plugins pinned
  in a `plugins.txt` baked into a derived image, vs configuration-as-
  code (JCasC) from day one (adds YAML but makes the controller
  reproducible — recommended in ci-5 if not ci-2).
- D7 the Polari-side write path: **Jenkins pushes to the acceptor
  (mirror only)**; Polari never holds a build-capable Jenkins token.
- D8 Jenkins UI reach: **LAN/isle-only** (browse from inside) vs a
  tunnelled public URL with SSO (later, if remote operators need it).

## 5. Boundaries

- Ours: the Jenkinsfile, `promote-main.sh`, `install-jenkins-host.sh`,
  the isle-test VM stage, the `cicd` module, the pipeline's use of the
  existing builders/publishers.
- isle-core's Claude: an unattended `isle core-install --yes` path (no
  interactive credential walkthrough — the deploy-time credentials come
  from a file) and `isle uninstall --everything --verify` exit codes the
  stage can assert on; both are small.
- Dustin: main-branch protection, the registry namespace (D3), the apt
  signing key ceremony, nested-virt on the build box, the droplet (prd)
  as the pool target, D1–D8.

## 6. Not in scope

Deploying to the home swarm from the pipeline (dev stays `pol swarm
deploy`), multi-branch Jenkins jobs, nightly builds (the night-run
sessions do that job today), Jenkins as an isle app or module-hosted
service (ruled out: the builder must sit above the isle it builds).
