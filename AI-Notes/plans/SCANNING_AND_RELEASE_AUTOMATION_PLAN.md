# Scanning + release automation (scn / rel arcs): advisory-only security scanning across the pipeline and the artifacts, and real artifact releases on merges to main

**Date:** 2026-09-19 · **Status: PLAN (scn-0 / rel-0). No code changed.**

His asks, 2026-09-19:

1. *"Can we do a plan to implement those advisory only for the scans"* — a
   scanning layer covering OS-level and app-level security, across the
   pipeline AND the artifacts it makes (debs, images, source), where **no
   scan ever blocks a build or a publish**: findings are recorded, shown,
   and reviewed by a person. He asked whether ClamAV + SonarQube would be
   sufficient. **No** — ClamAV finds known malware signatures and SonarQube
   Community analyses first-party source; neither sees a vulnerable
   dependency, a leaked secret, a container base image CVE, a Dockerfile
   misconfiguration, a host OS control, a TLS setting, or a running app's
   surface. §2 proposes the tool set that does.
2. *"Then we will want to automate getting Polari to do artifact releases
   on merges to main."*

Standing rules this plan is bound by (each already a ruling, not a new
choice here):

| rule | where it comes from |
|---|---|
| Security is **WARN-ONLY** in deployments | `AI-Notes/designs/CAUSAL_TRACE_OBJECT_FLOW_DESIGN.md:448` ("security WARN-ONLY in deployments (§17)") |
| Jenkins is **host tier**, **polls** GitHub, nothing inbound | `polari-jenkins/README.md:3-6`; `CICD_PIPELINE_PLAN.md:313-320` (D2, decided) |
| Nothing needing an outside authority is active until he provides the secret | `CICD_PIPELINE_PLAN.md:506-510`; `polari-jenkins/pipelines/Jenkinsfile.publish:22` (parked routes `error()`) |
| Tools are **DRIVEN** in containers, never embedded in the product | `CICD_PIPELINE_PLAN.md:51-55` (the Jenkins licence stance) |
| GPLv3, and the licence gate is a **hard blocker** | `AI-Notes/evaluations/RETICULUM_LICENCE_GATE.md:6-9`; memory `project-license-gplv3` |
| Every capability = an explicit **knob** + an **evidence-bearing suggestion** | memory `knobs-and-suggestions` |
| **Nothing raw on a screen** — pages are configured tables/graphs | `polari-rf-node/polari-framework/modules/security/security_page.py:8` |
| People keyed by Keycloak `sub` **only** | `.../objects/apps_security/SecurityDecision.py:28-30` (the PII boundary, D18-1) |
| **No new frontend components** | memory `no-raw-json-on-screens` |

Companions, reused not duplicated: `CICD_PIPELINE_PLAN.md` (the pipeline
itself; ci-3 = the test stage, §7), `POLARI_VERSIONING_PLAN.md` (the tag
and the manifest), `DOWNLOADS_PAGE_PLAN.md` (the page that lists a
release), `ISLE_HARDENING_PLAN.md` (the rings, the assurance ladder),
`TEST_COVERAGE_PLAN.md` (tcov — testing, which scanning is NOT).

---

## 1. Verified starting point (read 2026-09-19)

### 1.1 What Jenkins does today

| job | trigger | stages (in order) | produces | dry-run? |
|---|---|---|---|---|
| `polari-dev-build` | poll `dev` every 10 min (`jobs/seed.groovy:9`) | disk guard (`Jenkinsfile.dev-build:8`) · checkout dev, top-level submodules only (`:9-16`) · debs, isle + online + offline (`:17-19`) · images, backend/frontend/reticulum (`:20-22`) · **tests deliberately absent** (`:23`) | archived `.deb` artifacts, `prf-*:staging` + `pol-reticulum:staging` images (`:25`) | publishes nothing |
| `polari-release` | poll `main` every 10 min (`seed.groovy:15`) | disk guard (`Jenkinsfile.release:7`) · checkout main (`:8-16`) · debs → pool (`:17-19`) · images → `docker save` tars + `DIGESTS.txt` (`:20-30`) · `release.json` (`:31-46`) · offline medium, parameterised (`:47-50`) · `SHA256SUMS` (`:51`) · **tests absent** (`:52`) | `pool/<version>/{debs,images,release.json,offline,SHA256SUMS}` | triggers `polari-publish` with `DRY_RUN=true` (`:55`) |
| `polari-publish` | manual, or from release | verify pool (`sha256sum -c`, `Jenkinsfile.publish:8`) · one nested stage per route (`:10-33`) | whatever each route pushes | **`DRY_RUN=true` is the parameter default** (`seed.groovy:24`) and the instance default (`casc/jenkins.yaml:29-30`) |

Routes: **ACTIVE** `github-release`, `apt-repo`, `ghcr`, `homebrew`;
**PARKED** `dockerhub`, `npm`, `pypi`, `launchpad`, `snap` — a parked
route name is a hard `error()` (`Jenkinsfile.publish:22`). Every route
sources `routes/_lib.sh`, whose `run()` renders instead of executing under
`DRY_RUN=1` (`:6`) and whose `need()` **refuses a real run with exit 3**
naming the missing secret file (`:7-12`); `record()` writes
`publishedTo[route]` back into `release.json` (`:14-21`).
`github-release.sh:9` is already idempotent (an existing tag is skipped);
`ghcr.sh:12-13` cosign-signs when `cosign_key` is present and says
"pushed UNSIGNED" when it is not. `apt-repo.sh:2` carries the standing
blocker: *"⛔ KC rotation before this host faces the web."*

Guards the scan stages must not break: `retention.sh guard` refuses to
build under 20 GB free (`retention.sh:14-16`, knob `DISK_MIN_FREE_GB`,
`casc/jenkins.yaml:34-35`); `retention.sh prune` keeps 3 pool versions
(`:17-25`, knob `POOL_KEEP`); the `polari-build` lockable resource
serialises all three jobs (`casc/jenkins.yaml:37-40`); dev-build aborts a
running build when a newer commit arrives (`Jenkinsfile.dev-build:6`).

Controller toolchain today (`controller/Dockerfile:6-20`): docker CLI +
buildx + compose, jdk21/jpackage, node 20, dpkg-dev, `gh`, `cosign
v2.4.1`, python3. **No scanner of any kind**, and the 16 pinned plugins
(`casc/plugins.txt`) include no `warnings-ng` — nothing renders SARIF in
the Jenkins UI today.

### 1.2 What scanning exists: **nothing**

A repo-wide grep over `*.py *.sh *.yaml *.yml *.groovy Jenkinsfile*` for
`clamav|sonarqube|trivy|gitleaks|semgrep|syft|grype|hadolint|lynis|openscap|dependency-check`
returns **zero hits**. There is no `pol scan` (`polari-cli/scripts/` has
no `scan.sh`; `hwmap.sh:18` has an unrelated hardware `scan` verb). ⚠
Name collision to avoid: `AI-Notes/evaluations/SCAN_ENGINES_LICENSE_GATE.md`
is the **3-D reconstruction** arc (shelved, DA3 non-commercial weights) and
has nothing to do with security scanning — this arc's gate must get a
distinct name (§2.5).

What *does* exist and is adjacent, and must be reused rather than
re-invented:

| exists | what it is | file |
|---|---|---|
| `os-security/audit.sh` | read-only host audit, `res <ring> <control> <status> <evidence>` → pass/fail/skip + verdict, `--json` | `os-security/audit.sh:10-14`, `:7`, verdict `:156`, exit `:159` |
| `pol security os audit --post <core>` | runs the audit `--json` and POSTs it | `polari-cli/scripts/security.sh:240-250`; URL built `:247` = `<core>/api/security/audit` |
| the receiving door | `/api/security/audit`, GET `:801` + POST `:806-817` | `.../modules/security/security_api.py:118` |
| `SecurityAuditRun` | one posted audit run: host, scenario, verdict, pass/fail/skip counts, `controls_json`, `containers_json`, `source` | `.../modules/security/objects/security/SecurityAuditRun.py:9-24`; the feed is functions only, `custom/security_audit_feed.py:16-88` |
| `pol deploy audit <node>` | scps `audit.sh` to the node and runs it over ssh; local fallback | `polari-cli/scripts/deploy.sh:250-259` |
| `pol prod verify` | live proof that a module can be set up through every route (console · apps/downloads · interfaces · topology), pass/fail tallied, never aborting | `polari-cli/scripts/prod.sh:333` (`do_verify`), dispatch `:1137`, checks `:343-376` |
| `AppSecurityRecord` | per-app ledger of automation steps + `audit_verdict` + `steps_complete/total` + `blocking` (22 fields) | `.../objects/security/AppSecurityRecord.py:9-35` |
| `SecurityDecision` | ct-8: one ruling an app **version** owes — 8 kinds × 6 states, `confirmed_by` = a Keycloak `sub` **only**; the proposal hash lives in `evidence_json['proposal_hash']` | `.../modules/polariapps/objects/apps_security/SecurityDecision.py:9-30,39-56`; kinds/states `.../apps_security/_shared.py:38-42`; confirm `custom/security_decisions.py:250-299` |
| ct-8 coverage | `none`/`partial`/`full`; `full` = no `open` and no `stale` | `.../modules/polariapps/custom/security_coverage.py:38,48-53,86-101`; `GET /api/apps/security/coverage` (`apps_api.py:89-90`); page `apps-security` (`apps_page.py:31`) |
| configured page helpers | `_table` (`module_pages_seed.py:26`), `_sapi` (`:64`), `_row` (`:85`), `_page` (`:93`) | imported at `.../modules/security/security_page.py:12` |
| security pages today | `security`, `security-os`, `security-network`, `security-app`, `security-threats`, `security-proxy`, `security-firewall`, `security-events`, `security-objects`, `security-owned` | `security_page.py:26,69,83,103,108,112,164,228,270-272` — **no `security-scans`** (repo-wide grep: zero hits) |

Corrections to assumptions carried into this plan:

- `os-security/audit.sh` implements **43 distinct named controls across 8
  rings** (`dac` 7, `mac` 8, `network` 5, `physical` 2, `ssh` 10,
  `handback` 6, `certs` 2, `host` 3) — **not 25** — from 65 `res` call
  sites, emitting 47 rows at runtime because the `host` `sysctl` control is
  a 5-key loop (`:150-152`).
- ⚠ **`pol deploy audit <node>` has no `--post`.** It forwards `$*` to the
  remote script (`deploy.sh:257`); only `pol deploy inventory` posts
  (`deploy.sh:47,264,272`). The docstrings claiming otherwise —
  `custom/security_audit_feed.py:4-5` and `SecurityAuditRun.py:10` — are
  **stale**. scn-3 should either add `--post` there or fix the docstrings.
- ⚠ **The audit door is unauthenticated.** `on_post_audit`
  (`security_api.py:806-817`) does no auth or role check; it validates that
  the body is a dict containing `controls` (`:811-812`) and records
  `source=request.remote_addr` (`:814`), and the global
  `AuthContextMiddleware` is "Lenient in Phase 1 — never rejects"
  (`polariApiServer/polariServer.py:485`). So any host that can reach it can
  overwrite what the security views call "today". **scn-1 must NOT copy that
  laxity**: the `ScanRun` door takes a posting-only credential from the
  start, and scn-1 should close the `SecurityAuditRun` door the same way.
- The **`cicd` mirror door does not exist**. `POST /api/islemesh/ingest/cicd`
  appears only in `CICD_PIPELINE_PLAN.md:103`; there is no `cicd` module
  (nor a `release` module) among the 60 under
  `polari-rf-node/polari-framework/modules/`. `ReleaseManifest` exists in
  Python only as a *string looked up and expected to be absent* —
  `.../modules/polariapps/custom/security_subjects.py:127` says so in a
  comment, `:131` reads the table, `:140` falls back to *"no release
  stamped (ReleaseManifest is planned, not built)"*. `ReleasePublication`:
  **zero hits in Python**. **Every "post it to Polari" step in this plan
  therefore builds its own door in the `security` module, following the
  `SecurityAuditRun` pattern, and does not wait on ci-2b.**

### 1.3 The versioning contract, and a live defect it exposes

`POLARI_VERSIONING_PLAN.md:55-60`: one Polari version = a superproject tag
`polari-vYYYY.MM.DD[.n]`; a pre-release from an untagged commit is
`YYYY.MM.DD-dev+<short sha>`. `:79-90`: the `ReleaseManifest` is the
mapping, served at `GET /api/release`, and it **records — it never
refuses**.

⚠ **Finding.** `Jenkinsfile.release:13` computes
`POLARI_VERSION = "$(date +%Y.%m.%d)+$(git rev-parse --short HEAD)"` —
e.g. `2026.09.19+0a63609`. `routes/github-release.sh:6` then makes
`TAG="polari-v$VERSION"` → `polari-v2026.09.19+0a63609`, which matches
**neither** form in the versioning plan. Nothing in `Jenkinsfile.release`
tags git at all; the tag is created as a side effect of
`gh release create ... --target "$SHA"` (`github-release.sh:10`). rel-0
fixes exactly this (§3b).

### 1.4 The first release, and what is still his

Exactly **two** tags exist (`git tag -l 'polari-v*'`): `polari-v2026.09.11`
and `polari-v2026.09.12`. The first is annotated *"Polari 2026.09.11 —
**first published release**: platform installers (isle-mesh-cli 0.1.135,
polari-shell-core 0.1.34, isle-app-store 0.1.34, polari-isle 0.1.0,
polari-complete 0.1.34)"* on commit `1ca95e1` — the **5 debs are confirmed
by name**, and the release carries exactly those 5 `.deb` assets plus
`SHA256SUMS`, published `2026-09-11T23:46Z`.

- **Published by hand — inferred, not documented.** No `.github/workflows/`
  exists anywhere in the tree and no `gh release create` exists in
  `polari-cli/`; `CICD_PIPELINE_PLAN.md:518-521` still lists the GitHub
  release token as outstanding. Nothing could have done it automatically.
- **Images were not on ghcr that day — confirmed; the reason assumed is
  wrong.** The `polari-v2026.09.11` image configs carry `created:
  2026-09-12`. The repo's explanation is a **broken first push later
  overwritten**, and the scope it names as missing is **`delete:packages`**,
  not `write:packages` (`PRODUCTION_DEPLOY_PLAN.md:884`; `write:packages`
  appears only as `ghcr_token`'s scope, `secrets/README.md:20`).
- `polari-v2026.09.12` carries the same 5 debs (*"installers unchanged"*)
  and **its** images are live (`TESTING_OWED.md:1375,1381`), which is why
  the deployment route pins it (`guides/routes/AUTOMATED_ROUTE.md:12`).

How a release is consumed today, which rel-2 must keep working: the
official release source is hardcoded to **`dausume/polari-suite`**
(`polari-cli/scripts/lib/providers.sh:91`); `release_tags_with_debs`
(`:94`) lists the last 15 releases carrying `.deb` assets and
`release_deb_urls` (`:107`) resolves their URLs — both over the
**unauthenticated** GitHub API (60 calls/h: a rate-limit footgun worth a
knob). `prod.sh:512` turns those into `release:<tag>` menu items; `:770-781`
(`stage_debs`) downloads that release's `.deb` assets into
`.generated/debs` and **dies if the release carries none** (`:780`) — so a
release's deb assets are load-bearing for `pol prod`.

Still his, before anything publishes for real (`CICD_PIPELINE_PLAN.md:470-477`,
`:518-521`): a **GitHub token** with `contents:write` (+ `write:packages`
for ghcr, and `delete:packages` if a bad tag must ever be removed), the
**apt GPG signing key** + key id, the **cosign key** + password, the
distribution host deploy key — and the **KC rotation** before the apt host
faces the web.

---

## 2. The scanning layer — advisory only

**The rule, stated once and enforced everywhere:** every scan stage exits
**0 always**. A finding is never a gate. `set +e` around each tool, the
report written whatever the exit code, the stage `catchError(buildResult:
'SUCCESS', stageResult: 'SUCCESS')`. The only thing a scan can do to a
build is cost it time and disk — which `retention.sh guard` already bounds.

### 2.1 The tool matrix

Every tool below is **driven as a pinned container or CLI**, never linked
into, vendored in, or shipped inside any Polari artifact — so the licence
question is *aggregation and use*, not derivation, the stance
`CICD_PIPELINE_PLAN.md:51-55` took for Jenkins. The GPL tools (hadolint,
Lynis, testssl.sh, ClamAV) are doubly safe: Polari is GPLv3 itself.

| tool | licence | image / source (pin a digest) | scans | stage | output |
|---|---|---|---|---|---|
| **Trivy** — the primary | Apache-2.0 | `ghcr.io/aquasecurity/trivy` | deps (lockfiles), OS packages in images, **debs**, Dockerfile + compose misconfig, secrets, licences | dev-build, release | SARIF + JSON |
| **Syft** | Apache-2.0 | `anchore/syft` | SBOM of source tree, image, deb | release (+ dev-build weekly) | CycloneDX **and** SPDX JSON |
| **Grype** | Apache-2.0 | `anchore/grype` | vulns *from the SBOM* — the cross-check on Trivy | release | JSON |
| **pip-audit** | Apache-2.0 | `pypa/pip-audit` (pip in a slim image) | Python deps of `polari-framework` | dev-build | JSON |
| **npm audit** | Artistic-2.0 (ships with npm) | `node:20` (already in the controller) | Angular + `pol`/`isle` CLI deps | dev-build | JSON |
| **OWASP Dependency-Check** | Apache-2.0 | `owasp/dependency-check` | Java deps of the scorecard backend (`political-scorecard-backend`) | dev-build (slow: cache the NVD data dir) | SARIF + JSON |
| **gitleaks** | MIT | `zricethezav/gitleaks` | secrets in the working tree **and history** | dev-build (tree), release (history) | SARIF |
| **Semgrep Community** | LGPL-2.1 (**engine**) | `semgrep/semgrep` | first-party source: Python, TS, bash | dev-build | SARIF |
| **Bandit** | Apache-2.0 | `pypa`-style slim image | Python-specific security patterns | dev-build | JSON |
| **hadolint** | GPL-3.0 | `hadolint/hadolint` | Dockerfiles | dev-build | SARIF |
| **dockle** | Apache-2.0 | `goodwithtech/dockle` | image build hygiene (CIS Docker image checks) | release | JSON |
| **docker-bench-security** | Apache-2.0 | `docker/docker-bench-security` | the **daemon + host** docker config | `pol deploy audit` (host tier) | JSON |
| **Lynis** | GPL-3.0 | `cisofy/lynis` | host OS hardening, ~250 controls | `pol deploy audit`, the ISO build | JSON (+ its own report) |
| **OpenSCAP** (`oscap`) | LGPL-2.1 | `oscap`, content from ComplianceAsCode/SSG (**BSD-3**) | Ubuntu CIS profile against a host or the ISO | `pol deploy audit`, the ISO build | ARF/XML → JSON |
| **OWASP ZAP** | Apache-2.0 | `zaproxy/zap-stable`, **baseline scan only** | the running app's HTTP surface | `pol prod verify` against the staging stack | SARIF + JSON |
| **testssl.sh** | GPL-2.0 | `drwetter/testssl.sh` | the TLS configuration of an endpoint | `pol prod verify` | JSON |
| **Falco** | Apache-2.0 | `falcosecurity/falco` | **runtime** syscall behaviour of containers | runtime, dev only by default (D5) | JSON events |
| **ScanCode toolkit** | Apache-2.0 (data CC-BY-4.0) | `aboutcode-org/scancode-toolkit` | licences and copyrights across the tree | release (and the licence gate) | JSON |
| **ClamAV** | GPL-2.0 | `clamav/clamav` | the pool, before publish: every deb, tar and offline chunk | release, last stage before publish | JSON (from `clamscan` output) |
| **SonarQube Community Build** | LGPL-3.0 | `sonarqube:community` + `sonarsource/sonar-scanner-cli` | first-party quality + a narrow security ruleset | **optional** docker service beside Jenkins (D2) | its own DB + web UI; export via web API |

**Semgrep's catch:** the **engine** is LGPL-2.1, but **rule licences
vary** — registry rules carry their own terms and some packs are not open
source. scn-2 therefore **pins the exact rule sets** into
`.polari/semgrep-rules/` (or by registry ref + commit) and **records each
ruleset's licence** in the gate. A rule whose licence cannot be
established is not used.

**SonarQube's cost:** a Community Build instance wants ~2 GB RAM plus a
database and runs continuously — on pol-core that competes with the
staging swarm and Jenkins' own `mem_limit: 2g`
(`polari-jenkins/docker-compose.yml:32`). Hence **optional, off by
default** (D2); the paid editions' taint analysis is out of scope (§7).

### 2.2 `pol scan` — the one wrapper

```
pol scan source                 # gitleaks + semgrep + bandit + hadolint + trivy fs (config)
pol scan deps                   # trivy fs (lockfiles) + pip-audit + npm audit + dependency-check
pol scan image <name>           # trivy image + dockle (+ syft sbom)
pol scan deb <file>             # trivy rootfs on the unpacked deb + clamav
pol scan host                   # lynis + oscap + docker-bench-security   (host tier)
pol scan site [<url>]           # zap baseline + testssl.sh              (a running stack)
pol scan all [--json]           # every applicable target, sequentially
```

Every subcommand: pulls a **pinned digest** from `scan-tools.lock`
(tool → image → digest → version, tracked, bumped as a deliberate commit,
the same discipline as `casc/plugins.txt`); runs read-only (`--read-only`,
`--network=none` wherever the tool allows; ZAP and the NVD feed obviously
need egress); writes `scan/<version>/<tool>.{json,sarif}` **into the
Jenkins pool beside the artifacts**, i.e. `pool/<version>/scan/`, so
`SHA256SUMS` (`Jenkinsfile.release:51`) covers it for free; and writes one
`scan/<version>/SCAN_SUMMARY.md` — a one-page human digest: per tool,
counts by severity, the top N findings, "new since `<last release>`", and
the runtime + digest of each tool used. **Exit code 0 always**, with a
`--strict` knob that is **never used by a pipeline** and exists only for a
person running it by hand.

Knobs: `POLARI_SCAN_TOOLS` (comma list, default = the scn-N set built so
far), `POLARI_SCAN_SEVERITY_FLOOR` (what the summary highlights, not what
it records — everything is recorded), `POLARI_SCAN_TIMEOUT` per tool,
`POLARI_SCAN_OFFLINE` (skip the tools that need a feed and say so).

### 2.3 The baseline — "new since the last release"

`.polari/scan-baseline.json`, **tracked in git**, one section per tool:

```
{ "trivy": { "CVE-2025-XXXXX@libfoo-1.2": {
      "state": "accepted", "reason": "not reachable: libfoo's tls path is unused; see …",
      "by": "<keycloak sub>", "at": "2026-09-19", "expires": "2026-12-19" } }, … }
```

Rules: `accepted` is a **person's ruling** and nothing else may write it;
`by` is a Keycloak `sub` when the ruling came through Polari and a git
identity when it came through a reviewed commit; an entry **expires** (a
default of 90 days, a knob) so acceptance is renewed rather than
forgotten; a finding that disappears flips to `fixed` automatically on the
next run. The summary then reads *"12 findings, 9 accepted, **3 new since
polari-v2026.09.12**"* — a **suggestion**, never a gate. `pol scan
baseline accept <tool> <id> --reason …` is the only write path, and it
refuses without a reason.

### 2.4 Polari rows, the page, and the decision kind

Two new classes in the **`security`** module (the scan is about *machines
and artifacts*; the `SecurityDecision` that reviews it is about *apps and
releases* and therefore stays in `polariapps` — the same split `_shared.py:8-13`
argues for ct-8):

| class | fields |
|---|---|
| `ScanRun` | `name`, `tool`, `tool_version`, `tool_digest`, `target_kind` (source·deps·image·deb·host·site), `target_name`, `target_version`, `target_sha`, `started_at`, `finished_at`, `critical_count`, `high_count`, `medium_count`, `low_count`, `info_count`, `new_count`, `accepted_count`, `artifact_path`, `posted_by`, `source` |
| `ScanFinding` | `name`, `run`, `rule_id`, `severity`, `title`, `location`, `package`, `package_version`, `fixed_in`, `baseline` (`open`·`accepted`·`fixed`), `accepted_by` (a Keycloak `sub` only), `accepted_at`, `reason` |

Posted through **the same door shape as `SecurityAuditRun`**
(`security_api.py:118`) — but **gated**, unlike that door today (§1.2): a
posting-only credential, **never a build-capable token**, and Polari can
never drive the builder (the acceptor discipline of
`CICD_PIPELINE_PLAN.md:98-110`, D7 at `:333-334`). `posted_by` records
which machine posted; `source` records the remote address the way
`security_api.py:814` already does.

The page: **`security-scans`**, built from the existing helpers
(`_page/_row/_table/_sapi`, `security_page.py:12`) — runs table, findings
table, a per-app × version summary panel, and a "new since last release"
panel. **No new component**; everything is a configured table or a
structured-API panel, so the "nothing raw on a screen" rule holds.

The review: a **ninth `SecurityDecision` kind, `scan-review`** —
*"a person has read this version's scan summary"* — one subject per
`(app, app_version, scan target)`, confirmed with a Keycloak `sub` + the
**hash of the summary they saw**, exactly ct-8's shape: the hash goes into
`evidence_json['proposal_hash']` (`custom/security_decisions.py:291-292`),
and `confirm()` already refuses **401** without a `sub` and **403**
without `ADMIN_ROLES` (`:266-277`) and **never overwrites** a `confirmed`
or `denied` row (`SecurityDecision.py:22-26`). Adding a kind means one
entry in `DECISION_KINDS` (`_shared.py:38-39`), one collector in
`custom/security_subjects.py`, and the coverage maths
(`custom/security_coverage.py:48-53,86-101`) follows for free.
**What ct-8 coverage then answers is whether a release was *reviewed* —
never whether it was *clean*.** The release gate **cites** it: the publish
job prints the app × version `scan-review` coverage and **continues**
either way.

### 2.5 The licence gate (blocking, before any adapter)

`AI-Notes/evaluations/SECURITY_SCAN_TOOLS_LICENCE_GATE.md` — the
three-source method of `RETICULUM_LICENCE_GATE.md:7-10` (published
metadata + repo LICENSE + source headers), per tool, plus: (a) the two
practical questions — can we publish the compose/Dockerfile that drives
it, can we distribute the built image; (b) for Semgrep, **each rule pack
separately**; (c) for OpenSCAP, the **content** licence (ComplianceAsCode
is BSD-3) as distinct from the CIS benchmark documents, which are CIS-
licensed and are **not vendored**; (d) for ScanCode, its data licence
(CC-BY-4.0). The name is deliberately distinct from the shelved
`SCAN_ENGINES_LICENSE_GATE.md` (3-D reconstruction).

### 2.6 The public wording

Automated scanning is **rung 4 evidence** on the assurance ladder —
*"the audit and the escape test run on every deployment and their results
are recorded"* (`AI-Notes/guides/security/SECURITY_OVERVIEW.md:72`). It is
**not rung 5**, which is *"a third party, not the authors, tests the
deployed system"* (`:73`). The site must say scanning is automated
self-testing by the authors' own pipeline and makes **no** assurance
claim; `SECURITY_OVERVIEW.md:78` already says so and must not be softened.

---

## 3. Release automation on merges to main

### 3a. What exists vs what is missing

| step | today | gap |
|---|---|---|
| trigger | poll `main` every 10 min (`seed.groovy:15`) | none — keep it |
| build | debs + images + offline medium (`Jenkinsfile.release:17-50`) | none |
| manifest | `release.json` with component shas (`:31-46`) | it is not a `ReleaseManifest` row and nothing serves it |
| checksums | `SHA256SUMS` over the pool (`:51`) | none |
| tag | minted implicitly by `gh release create --target` (`github-release.sh:10`) with a **malformed name** (§1.3) | rel-0 |
| publish | `DRY_RUN=true`, always (`Jenkinsfile.release:55`) | rel-0 |
| SBOM / scan assets | absent | rel-1 |
| `/api/release` + downloads | absent (no `ReleaseManifest` class anywhere) | rel-2 |
| `ReleasePublication` rows | absent | rel-2 |
| review citation | absent | rel-3 |

### 3b. The design

**(a) Trigger.** Unchanged: *a new commit on superproject `main`*, polled
— his D1 default (`CICD_PIPELINE_PLAN.md:311-312`). **A merge to main IS
the release intent**; dev→main promotion stays his explicit act via the
promote ritual (ci-1, `CICD_PIPELINE_PLAN.md:153-165`). Nothing here adds
an inbound path.

**(b) Versioning.** The release job **mints** `polari-vYYYY.MM.DD`
(`.N` for a second release the same day — resolved by asking GitHub which
tags already exist), **tags the superproject**, and records **every
submodule sha** in `release.json` — which `Jenkinsfile.release:37-39`
already collects, so this is a rename plus a `git tag` plus a push with
`contents:write`. The pre-release form `YYYY.MM.DD-dev+<sha>` stays for
dev-build's pool dirs (`POLARI_VERSIONING_PLAN.md:55-60`). **Or** — D1 —
he tags by hand and the job builds **only tagged commits** (poll main,
skip when `git describe --exact-match` fails). Default: **the job mints**.

**(c) Publishing for real.** `DRY_RUN=false` **per route, automatically,
when that route's secret is present** — `_lib.sh:7-12` already gives the
honest refusal, so the job simply asks `pol jenkins secrets` which files
exist and sets `DRY_RUN` per route accordingly, printing which routes are
live and which rendered. Order: **github-release first** (everything links
to it), then **ghcr + cosign**, then **apt-repo after the KC rotation**
(`apt-repo.sh:2`), then **homebrew**. PARKED routes stay parked
(`Jenkinsfile.publish:22` unchanged). Idempotence: a release that exists
is **updated**, not skipped — `github-release.sh:9`'s blanket skip becomes
"exists → compare each asset's sha256 against `SHA256SUMS` and re-upload
`--clobber` only what differs"; images already immutable by tag, `:latest`
re-pointed.

**(d) What a release contains.** The debs · `SHA256SUMS` · `release.json`
(the `ReleaseManifest`) · the **SBOMs** (CycloneDX + SPDX, per image and
per deb) · **`SCAN_SUMMARY.md`** and the per-tool reports as assets ·
cosign **signatures** for every image, plus the SBOM attached as a cosign
**attestation** (`cosign attest --type cyclonedx`) — the controller
already carries cosign 2.4.1 (`controller/Dockerfile:19-20`).

**(e) Consumption.** The deployed core is to serve the manifest at
`GET /api/release` (`POLARI_VERSIONING_PLAN.md:79-90`) — **which does not
exist**: a repo-wide grep for `api/release` returns **zero code hits**, all
of them prose in plans. Today `/downloads` is served by
`modules/appstore/downloads_page.py` and its version is **scraped out of
the staged deb filenames** by the regex at `:51-52` (`staged_debs()` at
`:108`, printed at `:284-285`; JSON twin `GET /api/downloads`,
`apps_api.py:383`). rel-2 replaces the scrape with the manifest and keeps
the scrape as the fallback. The `pol prod` path is **already live and must
not regress**: `prod.sh:512` lists `release:<tag>` options and `:770-781`
fetches that release's `.deb` assets, dying if there are none (`:780`).
So: **a release without deb assets breaks `pol prod`** — that is the one
hard invariant of the release job, and it is a build invariant, not a scan
gate.

**(f) Notifications, inward only.** `ReleasePublication(version, route,
url, install_command, published_at, digest, status)` rows
(`CICD_PIPELINE_PLAN.md:460-464`) through the cicd mirror door — which
**does not exist** (§1.2), so rel-2 either builds it or posts to a
`security`-module door of the same shape — plus a notice on the home
stack. Nothing in Polari can trigger a build.

**(g) Failure.** A failed stage leaves `pool/<version>/` plus a `FAILED`
marker naming the stage, and **no partial publish** (publish is a separate
job that verifies `SHA256SUMS` first, `Jenkinsfile.publish:8`). The next
poll retries; `retention.sh prune` reclaims the dir (`retention.sh:17-25`).

**(h) Rollback.** Pin an older `release:<tag>` in `pol prod`
(`prod.sh:775`). **Releases are immutable** — a bad one is superseded by
`polari-vYYYY.MM.DD.2`, never edited (deleting a ghcr tag needs
`delete:packages`, `PRODUCTION_DEPLOY_PLAN.md:884`).

**(i) The public hub.** `pol-hub` is **static** and carries no version:
`site/index.html:22,147` link to `downloads` as a plain relative href,
`build-docs.py:350` skips those links deliberately (*"a link to something
the running stack serves"*), and `pol-hub/nginx.conf:25` has no
`/downloads` location — the edge proxy routes it to the backend
(`pol-proxy/nginx.lean.conf.template:79-82`, `nginx.prod.conf.template:91-95`).
**So the hub needs no rebuild per release**; what must change is the
*backend* downloads page, reading the manifest instead of scraping
filenames. **What stays his:** the droplet deploy (memory
`test-on-home-machines-not-droplet`), the KC rotation before the apt host
faces the web, and every secret in §5 D6. ⚠ One honesty debt to clear at
the same time: the **published** site documents `POST
/api/release/offline-scan` and `OfflineBuild` rows
(`pol-hub/site/docs/offline-install.html:123`, from
`guides/OFFLINE_BUILD_TEMPLATE.md:111`) — **none of which exist in
Python**.

---

## 4. Phases

Small slices, alternating so that scanning and releasing each become
useful early. Each names what it builds, how it is proven, and what stays
advisory.

| slice | builds | proof | stays advisory |
|---|---|---|---|
| **scn-0** | `pol scan source` / `pol scan deps` + `scan-tools.lock`; Trivy + gitleaks + pip-audit + npm audit as a `scan` stage in `Jenkinsfile.dev-build` (after `images`), reports archived as artifacts | a dev-build is green with findings present; `retention.sh guard` still passes; build time delta recorded | nothing gates; no rows yet |
| **rel-0** | tag minting `polari-vYYYY.MM.DD[.N]` + `git tag`/push; `DRY_RUN=false` per route when the secret is present; idempotent asset re-upload | **the first automated GitHub release**, its debs fetched back by `pol prod debs` with `release:<tag>` | apt-repo stays dry until the KC rotation |
| **scn-1** | `ScanRun` + `ScanFinding` classes, the posting door, `pol scan --post <core>`; the `security-scans` configured page; the `scan-review` `SecurityDecision` kind | rows appear from a real dev-build; the page renders with no raw JSON; `scan-review` shows `open` for the current app versions | nothing refuses; coverage is a count |
| **scn-2** | Semgrep (pinned rule sets + their licences) + Bandit + hadolint + dockle; Syft SBOMs; `.polari/scan-baseline.json` + `pol scan baseline accept` | "new since `<tag>`" is correct across two consecutive releases; an accepted entry disappears from "new" and reappears when it expires | the baseline is a suggestion |
| **rel-1** | SBOMs + `SCAN_SUMMARY.md` + per-tool reports as release assets; `cosign attest` of the CycloneDX SBOM per image | `cosign verify-attestation` passes against a published image | a missing/failed scan does not block the release |
| **scn-3** | host tier: Lynis + OpenSCAP (Ubuntu CIS via ComplianceAsCode) + docker-bench-security driven by `pol deploy audit <node>`, posted as `ScanRun` alongside `SecurityAuditRun`; **and the `--post` that `pol deploy audit` does not have** (§1.2) | one run per home machine; the OS view shows them next to `audit.sh`'s 43 controls across 8 rings | advisory; `pol deploy audit`'s own exit code (nonzero unless `hardened`, `audit.sh:159`) is unchanged by any scan finding |
| **scn-4** | ZAP baseline + testssl.sh in `pol prod verify`, against the **staging** stack | a run against the home staging stack; findings as rows | `pol prod verify`'s verdict is unchanged by scan findings |
| **rel-2** | `ReleaseManifest` row + `GET /api/release`; downloads page fetches it at runtime; `ReleasePublication` rows + the home-stack notice; the mirror door (or its `security`-module equivalent) | a new release appears on the downloads page with **no hub image rebuild** | the manifest records, never refuses (`POLARI_VERSIONING_PLAN.md:79-90`) |
| **scn-5** | ClamAV over the whole pool as the **last** release stage before publish; **optional** SonarQube service beside Jenkins (D2), off by default | a deliberately planted EICAR test file is found and **recorded**, and the publish still runs | yes — including EICAR: it is a row, not a refusal |
| **scn-6** | Falco at runtime (dev by default, D5); ScanCode over the tree, feeding the licence gate | Falco events become rows; ScanCode's output reconciles with the existing gate documents | advisory |
| **rel-3** | the publish job **prints** the app × version ct-8 coverage and the `scan-review` state for the release, and continues; the same two numbers on the release notes and the downloads page | a release published with `scan-review` = `open` — and the log says so plainly | the citation is the whole point: it says *reviewed*, never *clean* |

Suggested order, as listed: scn-0 → rel-0 → scn-1 → scn-2 → rel-1 →
scn-3 → scn-4 → rel-2 → scn-5 → scn-6 → rel-3.

---

## 5. Decisions for him (defaults in **bold**)

- **D1 — who mints the tag.** **The release job mints
  `polari-vYYYY.MM.DD[.N]` and pushes it with a `contents:write` token**,
  vs. he tags by hand and the job builds only tagged commits. (The second
  is safer and slower; the first is what "automate releases on merges to
  main" literally asks for.)
- **D2 — SonarQube service.** **No, not yet** (a continuous ~2 GB service
  on pol-core beside Jenkins' own 2 GB limit and the staging swarm), vs.
  yes as an opt-in compose profile. Semgrep + Bandit cover most of what
  the Community edition would flag on this codebase.
- **D3 — what the public site shows.** **Counts by severity per release,
  plus whether a person reviewed it (the `scan-review` state)** — no
  finding detail, no locations, vs. nothing at all. (Publishing detail on
  unfixed findings for a live public deployment is the argument for
  "nothing"; the honesty argument is for counts.)
- **D4 — scan cadence.** **Every dev commit for the fast tools** (Trivy fs,
  gitleaks, pip-audit, npm audit — seconds to a couple of minutes) **and
  nightly for the slow ones** (Dependency-Check's NVD sync, ScanCode, full
  image scans), vs. everything on every commit (cost on pol-core, which
  already serialises on `polari-build`), vs. everything nightly only.
- **D5 — Falco.** **Dev only** (the home swarm/isle), vs. the production
  isle too. Falco wants a kernel module or eBPF and adds a continuous
  agent to a production host; the warn-only rule means it would only ever
  record.
- **D6 — the secrets he must place** (each is `polari-jenkins/secrets/<area>/<name>`,
  one file per secret, `secrets/README.md:4-8`):

  | file | needed for | scope |
  |---|---|---|
  | `github/github_token` | rel-0 — the real GitHub release, and the tag push | `contents:write` |
  | `registries/ghcr_token` | rel-0 — images on ghcr | `write:packages` (+ `delete:packages` only if a bad tag must be removed) |
  | `signing/cosign_key` + `signing/cosign_password` | rel-1 — image signatures and SBOM attestations | — |
  | `signing/apt_signing_gpg` + `signing/apt_signing_keyid` | the apt route | ⛔ **after** the KC rotation |
  | `ssh/distribution_host_key` | the apt route's rsync | ⛔ same |
  | `admin/jenkins_admin_password` | already generated by `pol jenkins up` (`polari-jenkins/README.md:44-45`) | — |

  No scanning tool needs a secret: every tool in §2.1 is free and
  unauthenticated. (An NVD API key would only make Dependency-Check's sync
  faster; it is optional and not required.)
- **D7 — does an `accepted` baseline entry need a second person?** **No —
  one person's ruling with a reason and an expiry**, vs. yes for
  `critical`/`high` only, vs. yes for everything. (The ct-8 precedent is
  one confirmer, `SecurityDecision.py:22-26`.)

---

## 6. Boundaries

- **Advisory only.** No scan stage fails a build or blocks a publish —
  ever, at any severity, including a ClamAV hit.
- **Tools in containers, pinned by digest** (`scan-tools.lock`), never
  installed into a product image, vendored or linked: the controller gains
  the ability to *run* them, not the tools themselves.
- **No publish without his secrets.** `_lib.sh:7-12`'s refusal is
  untouched; rel-0 only decides `DRY_RUN` per route from which files exist.
- **Outbound only** — pulls (tool images, vuln feeds) and pushes
  (releases, images, rows to a core on the LAN). No inbound port, webhook
  or tunnel (`CICD_PIPELINE_PLAN.md:313-320`).
- **No new engines** — no chart engine, no frontend component, no second
  page framework; `security-scans` is configured tables + `_sapi` panels.
- **Forks never republished under upstream names** (`CICD_PIPELINE_PLAN.md:378`).
- **The droplet stays his** — nothing here deploys to, scans or
  reconfigures the production VM (memory `test-on-home-machines-not-droplet`).
- **Polari mirrors, never controls** — a posting-only credential; no row
  can start, stop or gate a job (`CICD_PIPELINE_PLAN.md:98-110`, `:333-334`).

## 7. Not in scope

- **Rung 5 — independent testing** by a third party; scanning is the
  authors' own automation and cannot substitute for it
  (`SECURITY_OVERVIEW.md:73,78`). Scoping it stays `ISLE_HARDENING_PLAN.md:224` D9.
- **The paid SonarQube editions** and their taint analysis.
- **SAST of Isle-Mesh beyond what Trivy/Semgrep see from the superproject
  checkout** — isle-core's own Claude owns that code (`CLAUDE.md`), and
  `Jenkinsfile.dev-build:9-16` checks out top-level submodules only, so the
  nested submodule is out of reach either way.
- **Testing.** ci-3 / tcov is the test plan (`CICD_PIPELINE_PLAN.md:523-530`);
  a scan is not a test and discharges nothing in `TESTING_OWED`.
- **The `cicd` module** (ci-2b) as a prerequisite — it does not exist
  (§1.2) and nothing here waits on it.

---

## 8. Unverified

- **That the first release was published by hand** — inferred, not
  documented (§1.4): no CI workflow and no `gh release create` exists
  anywhere, so nothing could have done it automatically, but no note says
  so. (The tag, the date and the 5 debs **are** verified.)
- **That `pol prod debs build` produced the 09-11 debs.** That verb does
  produce exactly this five-deb set (`TESTING_OWED.md:1502,1527`), but
  nothing ties it to that run.
- **`write:packages` as the reason the 09-11 images missed ghcr** —
  **refuted as stated**: the repo cites a broken push later overwritten and
  a missing **`delete:packages`** scope (`PRODUCTION_DEPLOY_PLAN.md:884`).
  The underlying fact (no ghcr images on 09-11) is verified from the
  images' own `created` timestamps of 2026-09-12.
- Resource cost figures for SonarQube Community Build (~2 GB) are the
  upstream recommendation, **not a measurement on pol-core**. D2 should be
  decided against a measured run, not this number.
- The **licences in §2.1 are stated from general knowledge and are NOT yet
  gated.** §2.5's three-source gate is what makes them a fact; until it
  runs, treat every row of that column as a claim to verify, not a finding.
- `CICD_PIPELINE_PLAN.md` has duplicated section numbers (two `## 5.` at
  `:338` and `:358`, two `## 6.` at `:351` and `:489`) — citations above
  use line numbers rather than section numbers for that reason.
