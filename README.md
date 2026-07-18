# Polari Suite — Build & Run

**Start here.** This is the top-level guide for building, running, and testing the
Polari suite in its various configurations. The suite is orchestrated by one CLI —
**`pol`** — which fronts credential/cert setup, the compose stack lifecycles, the
build pipeline, and (later) swarm + ssh deploys.

> If you only read one thing: use **`pol`**. Don't hand-roll `docker compose` /
> `mvn` / `ng` commands — the CLI knows the env tiers, the compose file family,
> the credential substrate, and the gotchas. `pol help` is always current.

---

## 1. Prerequisites

- Docker + Docker Compose v2, Node 20+, and (for native frontend work) `npm`.
- The `pol` CLI on your PATH:
  ```bash
  cd polari-cli
  ./shells/install-cli.sh      # symlinks this checkout as `pol`
  pol help                     # verify
  ```
  Out-of-tree installs: export `POLARI_SUITE_ROOT=/path/to/polari-suite`.

## 2. Quick start (combined suite, staging)

```bash
pol security setup            # generate ALL credentials + certs (random, no prompts, skip-if-exists)
pol suite up --env staging    # bring up the combined pol-infra + PRF + PSC stack
pol suite urls                # print the staging nip.io URLs
pol suite down                # stop it
```

Single-command shell equivalents also exist at the root for the common paths:
`./start-staging.sh`, `./start-prod.sh`, `./setup-polari-security.sh dev`.

## 3. Configurations (env tiers)

Two stack **roles**, each with env tiers — pick ONE at a time (they share
container names):

| Role | Command | Env tiers |
|---|---|---|
| **Standalone PRF node** | `pol node up --env <tier>` | `dev` · `test` · `staging` · `prod` · `stateless` |
| **Combined suite** (infra + PRF + PSC) | `pol suite up --env <tier>` | `dev` · `staging` · `prod` |

`dev`=`docker-compose.yml`, `test`=`docker-compose.fullstack-test.yml`,
`staging`=nip.io, `prod`=real domain, `stateless`=no persistence.
**The `test` tier exists only at the node level.**

Independent service deploys and single services:
```bash
pol compose engines up                 # msci-engines worker alone
pol compose node up backend            # just the PRF backend
pol compose suite build psc-backend    # rebuild one image
```

## 4. Building

```bash
pol build render      # render the jinja-script compose family into jinja-build/
pol build parity      # verify generated compose files == hand-written (semantic diff)
pol build promote     # copy rendered bundles over the deployable root files
pol build clean       # remove rendered jinja-build/ mirror
```

Frontends (Angular) build natively once `node_modules` are installed:
```bash
cd polari-rf-node/polari-platform-angular   # or political-scorecard-node/political-scorecard-frontend
npm ci        # first time only
npm run build # AoT production/dev build (type-checks the whole app)
```

## 5. Testing

| What | How |
|---|---|
| **Full-stack integration** (PRF node) | `pol node up --env test` |
| **Framework unit suite** (Python) | `cd polari-rf-node/polari-framework && docker compose -f docker-compose.test.yml up --build --abort-on-container-exit` (runs `python3 -m testing.run_matrix`) |
| **One module's selftest** | `pol modules selftest <module>` (e.g. `scoring`, `aquaponics`, `materialsScience`) — runs INSIDE the prf-backend container |
| **Module dependency check** | `pol modules deps` |
| **Angular frontend** | `cd <frontend> && npm test` (Karma) or `npm run build` for a type-check-only pass |
| **Java backend (PSC)** | `cd political-scorecard-node/political-scorecard-backend && docker compose -f docker-compose-test.yml up --build --abort-on-container-exit` |

> Run test suites through their **Docker compose files** (or `pol`), not raw
> `mvn` / `run_tests.py` on the host — the containers carry the right DB, Keycloak,
> Python/Java deps, and env. See `polari-rf-node/TESTING.md` for the full matrix.

## 6. Repo layout (git submodules)

```
polari-suite/                     ← you are here (superproject)
├── polari-cli/                   ← the `pol` CLI (docs/ has full reference)
├── polari-rf-node/               ← standalone PRF node
│   ├── polari-framework/         ← Python/Falcon backend + sim/no-code engines
│   └── polari-platform-angular/  ← Angular frontend
└── political-scorecard-node/     ← the Democratic Scorecard app
    ├── political-scorecard-frontend/  ← Angular
    └── political-scorecard-backend/   ← Java / Spring Boot
```

All are on the `dev` branch for active work. Submodule pointers in a superproject
must be committed after committing inside the submodule (innermost-first).

## 7. Gotchas & cleanup

- **Root-owned build artifacts (FIXED — keep it that way).** Compose services
  that bind-mount the repo used to run builds as **root**, leaving root-owned
  `target/` (PSC backend), `test-results/`, `coverage/`, `.angular/` on the
  host that broke later native builds with `Permission denied`. Every such
  service now either runs as the host user (`user: "${UID:-1000}:${GID:-1000}"`
  + a writable in-container `HOME`) or chowns its output dir back to the host
  user on exit (framework/Angular test composes, whose tests must run as root).
  If you add a compose service with a writable bind mount, apply one of those
  two patterns. Leftovers from before the fix: `sudo rm -rf <repo>/target`.
- **PSC cache is KeyDB.** `psc-redis` / `psc-redis-test` build on
  `eqalpha/keydb` (the old `bitnami/redis` base was removed from Docker Hub and
  broke every build). Same Redis protocol, same ACL users, same Spring config.
- **PSC backend test stack is self-contained.** `docker-compose-test.yml`
  carries its own MariaDB, KeyDB, and MinIO (startup blocks until MinIO
  responds), and the `test` profile stubs Keycloak (JWKS is fetched lazily, so
  no live Keycloak is needed). To test against a real realm, set
  `KEYCLOAK_JWKS_URI` / `KEYCLOAK_ADMIN_URL`.
- **One stack at a time.** `pol node` and `pol suite` share container names — run
  only one.
- **Staging cold-start flap.** On the first `pol suite up --env staging`, the
  prf-backend healthcheck can flap on a cold seed and block `pol-proxy` — just
  re-run `pol suite up` once it's healthy.

## 8. Where to go next

- `pol help`, `pol <module> help` — always-current built-in docs.
- `polari-cli/docs/` — `INDEX.md`, `QUICK-REFERENCE.md` (every command on one
  page), `CLI-ARCHITECTURE.md`, `EXTENSION-GUIDE.md`.
- `BUILD_SYSTEM_PLAN.md` — the jinja-script build revamp the CLI fronts.
- `*_PLAN.md` at the root — per-feature design/roadmap docs.
