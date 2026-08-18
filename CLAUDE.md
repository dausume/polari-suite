# Polari Suite — instance guide

**Read `README.md` first** — it is the authoritative build/run/test guide.
This file is the short version for AI instances.

## How to build / run / test — use the `pol` CLI

Do **not** hand-roll `docker compose` / `mvn` / `ng` invocations on the host.
The suite is orchestrated by one CLI, `pol` (installed via
`polari-cli/shells/install-cli.sh`). `pol help` and `pol <module> help` are
always current. Key paths:

- Credentials/certs: `pol security setup`
- Run combined suite: `pol suite up --env staging` (tiers: dev|staging|prod)
- Run standalone node: `pol node up --env dev|test|staging|prod|stateless`
- Integration tests: `pol node up --env test`
- Module selftests: `pol modules selftest <module>` (runs in-container)
- Build pipeline: `pol build render|parity|promote|clean`
- Run ONE of node/suite at a time (they share container names).

Run test suites through their Docker compose files or `pol` — the containers
carry the right DB/Keycloak/deps. Raw host `run_tests.py` / `mvn` is a fallback
only and boots a full server per test class (slow, noisy).

## Known gotcha — root-owned build artifacts (FIXED, keep it that way)

Compose services that bind-mount the repo used to run builds as root, leaving
root-owned `target/`, `test-results/`, `coverage/`, `.angular/` on the host
that broke native builds with `Permission denied`. All such services now run
as the host UID (`user: "${UID:-1000}:${GID:-1000}"` + in-container `HOME`) or
chown their output back to the host user on exit. Any NEW service with a
writable bind mount must use one of those two patterns. Also: PSC's cache is
**KeyDB** (`eqalpha/keydb`; the bitnami/redis base is dead — never reintroduce
it), and the PSC backend test stack is self-contained (own MariaDB/KeyDB/MinIO,
stubbed Keycloak). See README §7.

## Plans

All `*_PLAN.md` / `*_HANDOFF.md` / roadmap / evaluation docs live in
**`AI-Plans/`** (moved 2026-08-17) — older references to "<X>_PLAN.md at
suite root" mean `AI-Plans/<X>_PLAN.md` now.

## Repo shape

Superproject with submodules — EVERYTHING is inside the suite:
`polari-cli`, `polari-rf-node` (`polari-framework` = Python/Falcon backend,
`polari-platform-angular` = Angular), `political-scorecard-node`
(`political-scorecard-frontend` = Angular, `political-scorecard-backend` =
Java/Spring), `polari-app-shell` (native shells, PRIVATE repo), and
`Isle-Mesh` (isle networking + isle CLI + store plumbing + the versioned
`polari-isle/` deployment sub-project). Active work is on `dev`. Commit
submodule contents before the superproject pointer (innermost-first);
`polari-cli/shells/push-all-dev.sh --with-isle` sweeps the whole forest.
NOTE: the LIVE Isle-Mesh working copy is `~/Isle-Mesh` on isle-core
(`ssh isle-core`, its own Claude) — when editing isle code there, keep the
suite's submodule pin synced to isle-core's dev tip; a fresh dev checkout
starts with `./bootstrap-dev.sh` (piece-wise pull of all sub-projects).
