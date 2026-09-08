# polari-jenkins — the host-tier build + publish pipeline (ci arc)

Jenkins runs **beside the isle, not inside it** (his ruling 2026-09-04: it
builds and tests isles, so it sits at the docker/host tier like docker
itself). It **polls GitHub** — no webhook, no tunnel, no inbound port: the
UI binds to `127.0.0.1` only and every publication is an outbound push.

Plan: `AI-Notes/plans/CICD_PIPELINE_PLAN.md` (§3 dev→main gate, §5 ci-6
publication routes). **No test stages yet** (his instruction 2026-09-07);
the placeholders are marked in the pipelines.

```
polari-jenkins/
├── docker-compose.yml        the controller (built-in node runs the jobs; docker socket mounted)
├── .env.example              copy to .env — paths, UID/GID, docker GID; .env is gitignored
├── controller/Dockerfile     jenkins lts + plugins + the build toolchain (docker cli, jdk21/jpackage, node, dpkg-dev)
├── casc/jenkins.yaml         Configuration as Code: local admin, no anonymous, credentials FROM secrets/, seed job
├── casc/plugins.txt          the plugin set
├── jobs/seed.groovy          Job DSL: polari-dev-build, polari-release, polari-publish (all poll, none push by default)
├── pipelines/Jenkinsfile.*   the three declarative pipelines
├── routes/<route>.sh         ACTIVE routes (no outside authority needed): github-release, apt-repo, ghcr, homebrew — every one honours DRY_RUN=1
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
are fine: the credential exists with an empty value and the route refuses
with the file name. See `secrets/README.md`.

## Run (through the CLI — do not hand-roll compose)
```
pol jenkins up          # builds the controller image on first run; UI at http://127.0.0.1:8080
pol jenkins status      # health + which secrets are present (never their values)
pol jenkins logs
pol jenkins down
```
First login: user `admin`, password = `secrets/admin/jenkins_admin_password`
(created by `pol jenkins up` if missing, printed once).

## What the jobs do
| job | trigger | does | pushes anywhere? |
|---|---|---|---|
| polari-dev-build | poll `dev` every 10 min | recursive checkout, build the debs (both flavors) + images | no |
| polari-release | poll `main` every 10 min | the same, plus `release.json` (shas of every component) and the offline medium → `pool/<version>/` | no — it triggers polari-publish with DRY_RUN=true |
| polari-publish | manual / from release | routes/*.sh per selected route | only with DRY_RUN=false AND the route's secret present |

## Not yet
Tests (his call, later), the `ReleasePublication` rows in Polari (ci-6a),
agent nodes beyond the built-in one, the throwaway-VM isle tests (ci-3).
