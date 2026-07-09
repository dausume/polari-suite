# Next-agent handoff — 2026-07-09 (build-system round complete)

The 2026-07-08→09 session pivoted (per Dustin) from scorecard/hydroponics
to the BUILD SYSTEM. That round is now functionally COMPLETE (bld-1..7
v1). Full log in memory [[polari-build-system]]; design in
BUILD_SYSTEM_PLAN.md. Scorecard (scr-7, scr-9..14) + aquaponics (aqp-3)
remain parked exactly as the previous handoff described.

## 0. FIRST THINGS
- **NOTHING IS PUSHED.** All work is in LOCAL commits on: suite
  `dev-build-security`, rf-node `dev-jinja-family`, polari-cli `dev`.
  All repos are PUBLIC ([[public-repos-hygiene]]) — the branch stacks
  also still hold the older scr-*/aqp-* work unpushed. `pol deploy run`
  pulls from GitHub, so PUSH BEFORE any remote deploy.
- The `pol` CLI is installed at ~/.local/bin/pol (symlink to
  polari-cli/index.js). `pol help` + `pol <module> help` are the living
  docs; polari-cli/docs/QUICK-REFERENCE.md is the cheat sheet.

## 1. What the build system now is
- **Every compose file (13) is a GENERATED artifact.** Sources:
  pol-services/ (suite + polari-rf-node) — isle-mesh jinja-script idiom
  (comment-jinja, `## variation:` notes). WORKFLOW: edit pol-services/*,
  `pol build render [--project suite]`, `pol build promote`. Byte-parity
  gates catch drift. NEVER hand-edit the root compose files.
- **Credentials**: all setup-generated or knob-supplied (skip-if-exists,
  volume-baked passwords never regenerate). `pol security setup`
  (dev=random; prod=per-password choice; prod --auto=all random).
  Leaked prf KC client secret was rotated; env files untracked.
- **Proxies**: nginx configs generate in-pipeline (`pol proxy
  render|check|promote`; check = containerized nginx -t). Byte-parity
  with the old sed outputs; sed path still exists in setup scripts
  (retire once prod domain flows through: POLARI_PROD_DOMAIN knob).
- **Swarm (isle-mesh stand-in)**: `pol swarm deploy engines` PROVEN E2E
  on staging A (single-node swarm, overlay net, service answering on
  :9500 — left RUNNING as polari-engines stack). suite/node stacks
  render to .generated/stack-*.yml but refuse to deploy while their
  compose twins hold ports 80/443. v1 inlines creds via compose-config;
  docker-secrets is the queued refinement.
- **ssh deploys**: `pol deploy nodes|preflight|run` per
  pol-build/manifests/nodes.yml (isle-core + lightweight; lightweight
  preflight verified live, suspend disabled so it's headless-safe).
- **Shorthands**: `pol start|rebuild|stop|last` replay the recorded
  last-build approach (works for compose AND swarm — currently records
  swarm/engines). Missing-state/missing-render cases explain the
  pipeline instead of failing.
- **Registry**: pol-build/registry/services.yml = 19 service kinds +
  interconnects (instance-wiring artifacts incl. the scr-7 seam).
  `pol registry check` green. `pol config service <kind>` for nested
  per-service views; `pol db` (twin sqlite<->combo switching live);
  `pol modules` (list/deps/selftest inside prf-backend); `pol cert`
  (prod choice: self-signed vs Let's Encrypt walkthrough + cron
  auto-renew — all open source).

## 2. Live state on staging A (192.168.0.210)
- Combined compose suite UP (prf+psc, all 200 — scoring + aquaponics
  data intact). Single-node swarm ACTIVE with the polari-engines stack
  running (:9500). twin-b/dask compose projects still up (8081-8083).
- Suite .env + credential env files exist with LEGACY dev values
  (admin/kcpassword era) — expected: skip-if-exists protects the live
  volumes. Fresh installs get random everywhere.

## 3. Remaining build refinements (none blocking)
- docker-secrets mounting for swarm (replace compose-config inlining).
- Segment/assembly decomposition of the proxy sources (isle-mesh
  segments model) + retire the sed path from setup scripts.
- rf-node core-five service sources could merge more line-level (they
  group per-env where blocks differ — correct but coarse).
- multi-node swarm: join lightweight/isle-core (`pol swarm join-token`,
  `pol deploy`), then real placement.
- `pol build render --topology swarm` flag (today stacks derive from the
  compose bundles via stackify, which is equivalent for v1).

## 4. Parked application work (unchanged from previous handoff)
- scr-7 scorecard↔Polari wiring, scr-9..14 (SCORING_ACCOUNTABILITY_PLAN).
- aqp-3 hydraulics (AQUAPONICS_MODULE_PLAN; isle-core has NO earlier
  spec — searched 2026-07-08, rebuilt plan is canonical).
- Aquaponics frontend pages; live vote ingestion seam.

## 5. Gotchas carried forward
- prf-backend healthcheck flap on cold seed → re-run `pol suite up`.
- `##` author comments strip only INSIDE `# jinja-start` blocks.
- registry.sh check maps compose names→kinds via its ALIASES dict.
- Angular templates: literal `@` breaks builds — use `&#64;`.
- falcon POST bodies must read `request.bounded_stream`.
- Host python can't import polariServer (PyJWT) — selftests run inside
  the prf-backend container (`pol modules selftest <mod>`).
