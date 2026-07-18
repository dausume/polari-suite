# Next-agent handoff — 2026-07-16 (THE BIG DAY: ncg-0..7 + DMV/scorecard epistemics stack)

## ⚡⚡⚡ NEXT WORK (Dustin 2026-07-17): TOPOLOGY/TECH-TREE, then BLCNC+PVD
**This is the queued build, in Dustin's stated order — start here once the
push below lands.**
1. **Topology revamp + Tech Tree** — read `TECH_TREE_TOPOLOGY_PLAN.md`
   end-to-end. Phases tt-1..tt-7 (backend reverse-edge/transient computation →
   circle/nesting renderer → TechTree data model + completion rollup →
   4-segment render mode → seed the OSEB tree → real/business/politics
   objects → module-display convergence). Topology + tech tree are the
   cheaper build and come FIRST. Its §Open-questions list needs Dustin's
   answers (segment colors, 4-segment reading, completion gates) — ask
   or take the plan's defaults, which are marked.
2. **BLCNC + PVD proofing** — read `BLCNC_PVD_ROADMAP.md` (5 intertwined
   phases: ideal melt-voxel → theoretical chip via PVD+melt-voxel cycle →
   stochastic feasibility (locked by OS-PVD; 3.1 priors can start early) →
   BLCNC hardware in parallel → combined microfab device) + `BLCNC_PLAN.md`
   for the melt-voxel engine detail. Reuses the waxprint voxel/optimizer/
   no-code-command pattern (wp-1..8) — a `LaserOperation` twin of
   `WaxPrintOperation`.
3. **Why this matters (keep it front of mind):** BLCNC + PVD open sourcing
   is a CRITICAL part of the **Open Source Economic Baseline (OSEB)** — the
   overall end goal of the whole Polari project. The BLCNC/PVD phases are
   the worked example that flushes out the real OSEB tech tree (plan §B5):
   each phase lands as a TechNode whose theory segment is its sim modules
   and whose real segment is the Phase-4/5 CAD/hardware. Build tt-* so that
   seeding those nodes is the acceptance test.

**✅ REPO STATE: ALL GOOD — verified 2026-07-17 (late).** Every one of the 8
repos is on `dev`, working tree clean, and **0 ahead / 0 behind origin/dev**
— everything is pushed, all submodule pointers resolve on origin. Branch
hygiene done: all scratch/, rescue/, and merged feature branches deleted
after verifying their content landed on dev (each repo now carries only
`dev`, plus `main` where it existed). A fresh clone of origin/dev is the
complete, working state — the bring-up fixes above are all in it. Nothing
is waiting on a commit or push; next agent starts clean on the NEXT WORK
list at the top of this file.

## ⚡⚡ FLAWLESS BRING-UP — new workstream (2026-07-17). GOAL + open issues.
**Dustin's directive:** bringing up EVERY variation of the app must be
flawless across every route a person (or agent) might try, and it must be
*obvious* what the correct thing to do is. This is a first-class workstream,
not a cleanup afterthought.

**Canonical answer now documented (DONE 2026-07-17):** root **`README.md`**
(authoritative build/run/test guide) + root **`CLAUDE.md`** (short, auto-loaded
by instances). Both say: **use the `pol` CLI** (`polari-cli/`, installed via
`polari-cli/shells/install-cli.sh`) — do NOT hand-roll `docker compose`/`mvn`/`ng`.
Any new bring-up knowledge goes into these two files so it stays discoverable.

**The "all routes" mandate.** For every stack variation, the routes below must
each either JUST WORK or fail with a one-line pointer to the correct route:
- `pol` CLI (canonical): `pol security setup` → `pol suite up --env <tier>` /
  `pol node up --env dev|test|staging|prod|stateless`.
- Root shell launchers: `./start-staging.sh`, `./start-prod.sh`,
  `./setup-polari-security.sh`.
- Raw `docker compose -f …` (people will try this — it must work or refuse
  clearly).
- Native `npm run build` / `ng test` / `mvn` (fallback only; must not be a trap).
Acceptance: node {dev,test,staging,prod,stateless} + suite {dev,staging,prod} +
engines/twin/dask each come up clean via the documented route; test suites run;
**no route ever leaves root-owned artifacts on the host**; wrong routes give a
guided error, never a silent breakage.

**✅ ALL THREE OPEN ISSUES FIXED + LIVE-VERIFIED 2026-07-17 (this session,
per Dustin's directive "full build easy for anyone; keydb swapped in on the
political scorecard"). End-to-end proof: PSC test stack built + ran beside
the live suite (scratch `ports: !override []` overlay, port 8081 was taken
by prf-b-backend), `mvn clean verify` BUILD SUCCESS, 3/3 tests green,
`target/` fully HOST-owned. Detail:**
1. **psc-redis → KeyDB: DONE.** `redis/Dockerfile` + `Dockerfile.test` now
   build on `eqalpha/keydb` (same family as prf-keydb); the PSC confs carry
   over untouched (KeyDB reads the same ACL `user` directives — verified:
   authed PONG as psc-server-test, db-index write OK, unauthed refused).
   Bitnami startup scripts + empty ACL file deleted; redis/README rewritten.
   ⚠️ staging/prod compose `command:` was `redis-server --maxmemory…` — under
   the old swallowed-ENTRYPOINT it never ran; now fixed to
   `keydb-server /etc/keydb/keydb.conf --maxmemory…` so ACL auth survives the
   memory-cap override. Next staging up will rebuild psc-redis on KeyDB.
2. **Entrypoint mismatch: DONE.** Dockerfile + Dockerfile.suite use CMD (not
   ENTRYPOINT), so compose `command:` really runs. TRAP DEFUSED: three
   composes passed `command: ./startup_shell/startup_shell.sh` — a script
   that DOESN'T EXIST (silently swallowed before) — all now point at
   `dev_startup_shell.sh`. Host script exec bits fixed (`ug+x`; owner had
   no x-bit, which would have broken the UID-mapped container).
3. **Standalone test config: DONE.** test profile (both application-test.yml
   copies, now truly in sync — they had drifted) gains: stubbed
   `app.keycloak-admin.*` + lazy `jwk-set-uri` (no live Keycloak needed;
   env-overridable), and `app.datasource.minio.*` pointing at a NEW
   ephemeral `psc-minio-test` container in docker-compose-test.yml —
   required because DatabaseInitializer BLOCKS startup until MinIO responds
   (InitializationState.waitForDatabaseInitializations waits on the minio
   flag; a stub endpoint would hang forever, not fail).

**Already fixed + verified this session (DONE):**
- **Root-owned build artifacts.** `*-test` compose files bind-mount the repo and
  ran the build as **root**, leaving root-owned `target/` that then broke
  host-native `mvn` with "Permission denied". Fixed in
  `political-scorecard-backend/docker-compose-test.yml` with
  `user: "${UID:-1000}:${GID:-1000}"` (+ writable Maven `HOME`); verified the
  Maven build now writes `target/` (119 files incl. the file that used to fail)
  as **host-owned**, deletable without sudo. **✅ AUDIT DONE 2026-07-17:** every
  writable bind mount in every compose is covered — framework
  `docker-compose.test.yml` (test-results/) + angular `docker-compose.test.yml`
  and rf-node `docker-compose.fullstack-test.yml` (coverage/) now chown their
  output back to the host user via an EXIT trap (those tests must run as root:
  Chrome + image-owned /app); the PSC dev routes (suite/node/standalone
  backend = mvn, frontends = npm writing .angular/) now run as the host UID
  with in-container HOME. prf-backend dev was left as root deliberately — its
  persistent writes go to the prf_backend_data named volume, not the host.
  staging/prod composes have no writable source mounts (verified).
- **Frontends build clean:** psc-frontend + polari-platform-angular both
  `ng build` green (exit 0).
- Note: a full live suite was running during this work (15 containers, incl. a
  twin-B stack on 8081/8082/8083) — bring-up tests must route around live ports
  (verification used a scratch `ports: !override []` overlay) and never disturb
  a running stack.

## ⚡ XR ZONE CAPTURE — PARKED 2026-07-17 (Dustin moving topics). PICK-UP GUIDE.
Read AR_ZONE_CAPTURE_PLAN.md (status header carries the full pass
history) + memory [[ar-zone-capture]] (every gotcha). Where it stands:
- **WORKS ON DEVICE (Quest 2, built-in browser, hands + passthrough):**
  AR session grants, grayscale passthrough (normal for Quest 2), pinch
  point placement in the air, dot spheres + connecting lines + distance
  labels, HUD, wrist ring menu, 20 s auto-finalize countdown, commit
  reaches the backend (zone rows persist).
- **BACKEND: solid.** zones/ module selftest 45/45 + live on staging:
  planar (avg-height plane→floor extrusion) / hull (direct-3D) / prism
  models, calibration, rooms-vs-selections (rooms shared, selections
  tied to a simulation via simulation_ref), cube packing (lattice),
  room/site summaries (both volumes), zone→simulation bridge
  (SimSpaceDefinition '<zone>-space' + InitialConditionInterface
  'zone-ic--<zone>' carrying real constraints as setParams), AR
  Required Simulations (SimulationDefinition.xr_requirement; sample
  sim 'zone-block-filling' seeded), /display/zones + /zones-board.
- **JUST FIXED, NOT YET DEVICE-VERIFIED** (the last fix pass after
  Dustin's 2nd session found regressions): (1) hands-only point
  placement landed every dot at origin-on-floor — root cause: hand
  inputs have NO gripSpace so the grip Group never poses; placement
  now reads the index-finger-tip joint (hands) / target-ray pose
  (controllers). (2) Ring menu vanished when reaching toward it —
  root cause: ring parented to the hand WRIST JOINT, which three.js
  hides on any untracked frame and Quest drops the hand source on
  occlusion (reaching across causes exactly that); now sticky
  (fingertip-near OR 2 s grace). Also poke lateral tolerance widened.
  **NEXT HEADSET SESSION = verify these two fixes + first-ever look at
  the zone SHELL (cyan walls floor→plane, renders at commit) + pack
  outcome HUD line (silent zero-cube outcomes now always explained).**
- **KNOWN GAPS (not bugs):** hands can't cycle point kind (pad-click
  only — poke-able ring item would fix); Vive XR Elite has NO
  WebXR-AR browser path today (Vive Browser lacks immersive-ar, store
  Wolvic is Gecko, wolvic.com/dl has no Vive Chromium build — the
  in-app ar-unavailable-notice explains all this per-device);
  zone-block-filling sim is definition+ICs only (no SimState stepping
  yet — the packed lattice is its v1 output).
- **XR file reality check:** xr-zone-capture-runtime.ts/-page.ts are
  UNTRACKED (no git history); the recent-pass diffs on xr-wrist-ui.ts
  / xr-panel-system.ts are uncommitted. Poke seam (pokeFrom) and
  hand-wrist attach are opt-in — sim-space XR pages are untouched.
  Hands additions are ADDITIVE per Dustin: never override controller
  interactions.

## ⚡⚡ REVIEW GATE (2026-07-17): EVERYTHING below awaits Dustin's review.
ALL of tonight's work — authority capability, mock retirement, 9 no-code
module pages, epistemics routes + PSC pages (/survival, /court-cases,
/epistemics/*), governance CREATE UIs (/governance), staff-auth
browse/revoke, and the /worldview-scorer replacement (legacy scorer
DELETED) — is live on staging, UNCOMMITTED, and needs Dustin's browser
review + commit pass before further building. NEXT PLANNED WORK (do not
start before the review): **AR_ZONE_CAPTURE_PLAN.md** — capture 3D
zones in AR (point placement → real-distance estimation → ground area +
volume → 0.25 m cube packing with stacking → populate the zone in
AR/VR). Plan is written, phased arz-1..6, headset needed only for the
final stop line.

## ⚡ 2026-07-16/17 (latest): GROUP↔INSTANCE AUTHORITY + mock retirement + 9 no-code pages
Read **GROUP_AUTHORITY_PLAN.md** + memory [[group-authority]]. Built + LIVE
E2E-verified on staging, ALL UNCOMMITTED: (1) Polari scoring/group_authority
(grants/bindings/term-availability signals, 38/38 selftest, routes under
/api/scoring/authority/*); (2) PSC backend /api/authority/* (instance
registry, both-sides bindings, signal admission → term + provenance rows,
bearer-forwarding proxies) + /api/groups/directory + /api/terms/categories;
(3) PSC /authority hub UI + provenance badges; (4) ALL 7 PSC mock sites
retired to real data; (5) generic class-rows-table/api-json-panel display
components + seeded no-code pages: /display/{nutrition,vermicompost,tanks,
biomining,microalgae,wax-supply,supply-chain,plant-morphology,authority}.
Staging compose gotcha that BIT HARD: always `--env-file
.generated/.env.staging` AND `--no-deps` on any up -d --build; after a
backend recreate, `docker restart pol-proxy` (stale nginx upstream →
502). Keycloak realms differ (Political-Scorecard vs Polari) →
cross-side identity is payload-unverified until realms unify (Dustin
decision).

SECOND PASS same night (Dustin: "keep going on psc frontend"): the
epistemics stack is SURFACED — scoring/epistemics_api.py (29 GET routes
over the unrouted 2026-07-16 modules, live-verified), PSC court-case
proxy /api/court-cases, and PSC pages /survival + /court-cases +
/epistemics{,/proofs,/term-competition,/credibility,/sources,
/legislation} — all 200 on staging. Memory [[group-authority]] carries
the full detail.

THIRD PASS same night: mechanism-C CREATE UIs (/governance page +
/api/governance vote/ballot/edge creation; staff-auth browse/revoke +
admin list on /policy-votes) and the LEGACY CLIENT-SIDE WORLDVIEW SCORER
IS RETIRED — deleted outright, replaced by /worldview-scorer (front and
center on the home page): group-hosted concept sets + elected weights
read from ScoreGroup rows, per-concept readings + server-side
/groups/{name}/aggregate from Polari's real engine, what-if reweighting
clearly labeled local preview, group-asserted-term provenance inline.
All live-verified. Memory [[group-authority]] third-pass section.

## ⚡ POSTURE CHANGE (2026-07-16, later): NO aggressive building.
Dustin is doing a debugging + review pass. **FRONTEND_WORK_MAP.md** (suite
root) maps every missing/broken/mock-backed frontend surface across all
workstreams — work from that, at Dustin's direction. Correction: the
2026-07-09 claim below that aqp-3/7/8 have no frontend is STALE — aqp-3
(water-slice viz) and aqp-8 (plant-skeleton viz) exist and were verified;
only aqp-7 vermicompost has no UI.

## ⚡ READ FIRST
Two massive workstreams built TODAY, ALL UNCOMMITTED (55 files, framework
branch lineage dev-ncg-0-nocode-matrix → dev-ncg-5-breadboard off Dustin's
dev checkpoint), all selftest-green on 3 machines + live on staging:

1. **ncg-0..7 (no-code generalization)** — read NOCODE_GENERALIZATION_PLAN.md
   PICK UP HERE. graph_builder/graph_compilers seam; judicial CourtCase LIVE;
   hwdigital→iCE40 bitstreams; circuits/breadboards as rows (2.6123 mA
   regression); level bridge LIVE; NoCodeTestCase packs; module gating +
   PolariModule objects; 5-agent adversarial review, ~35 fixes pinned.
2. **DMV cost-of-living + scorecard epistemics** — read
   political-scorecard-node/DMV_COST_OF_LIVING_DATA_PLAN.md +
   DEMOCRATIC_SCORECARD_REVAMP_PLAN.md appendices (everything after the
   2026-07-16 sections). Source catalogs (verified URLs) + col-1/2 seeded
   LIVE; GovSource + 4 legal source types; cross-validation trust stack;
   profiler drift/discovery; policy drafts; venue patterns; legislation
   tracking; term competition; democratic proofs (18-pattern manipulation
   catalog); credibility bases + relevance voting.

Memory: [[nocode-generalization]] + [[dmv-cost-of-living]] carry every
gotcha. Matrix: format category = 6 blocking rows, nocode = 51.

**WAITING ON DUSTIN**: review/commit pass; API keys (POLARI_CENSUS_API_KEY,
POLARI_CONGRESS_API_KEY, POLARI_VA_LIS_API_KEY) for live pulls (col-3);
acct-0..3 review; manual browser pass; SEED_TERM_PROOFS demo-content pass;
model gaps (ContextualizedValue MOE fields, definition versioning, rollup
lineage, usage records). Pre-existing red: aquaponics.system 12/13 (NOT
from today's work). DO NOT COMMIT WITHOUT DUSTIN'S EXPLICIT ASK.

---

# Next-agent handoff — 2026-07-09 (AQUAPONICS PHASE 2 BUILT — tail below)

## ⚡ UPDATE 2026-07-09 (later session): aqp-3 / aqp-7 / aqp-8 ALL BUILT
All three Phase-2 phases are BUILT, committed locally, and selftest-green
(133 aquaponics checks). Branch stack in polari-framework:
`dev-aqp-3-hydraulics` → `dev-aqp-7-vermicompost` → `dev-aqp-8-growth`
(HEAD `dev-aqp-8-growth` = all three; commits 3780e28 / 48e5a20 /
054f401). rf-node worker twin on `dev-aqp-3-hydraulics` (3c09349).
Full per-phase detail + gotchas in [[aquaponics-module]] memory.

**✅ DEPLOYED + LIVE-VERIFIED this session** on
docker-compose.staging-nip.yml (prf-backend rebuilt, cold-seeded, all 8
aquaponics selftests green in-container). Live results:
- aqp-3 `GET /api/aquaponics/pots/demo-herb-pot/drains?soil=coir-perlite-mix`
  → `fidelity: fem`, drains: true, 0.044 mL/s, 8192-element mesh;
  head-field → 4225-node head field. **scikit-fem is pure-python and
  RIDES THE ALPINE BACKEND IMAGE** (as fem_engine.py's own comment
  says) — the FEM path runs IN-BACKEND, the msci-engines worker rebuild
  is NOT needed for aqp-3. (The worker `/darcy/*` routes + `darcy_solver.py`
  twin still exist as the delegation fallback; harmless, already built.)
- aqp-7 compare-modes recommends `direct`, periodic pulse peak 5.0 mg/L
  N; simulate persists the snapshot; the `nutrient-enrichment-efficiency`
  ScoreConcept resolves live.
- aqp-8 grow survives healthy (3 parts, top interaction leaf→root);
  under starved nitrate the root goes `condition: failed, limiting:
  nitrate-n, survived: false`.

**GPT-4 TAKEOVER — remaining tail (in priority order):**
1. **Optional: aqp-3 sim-as-data wrappers** (plan §aqp-3 item 4 —
   PotHydraulicsSimState + SimulationDefinition + coupling). I built the
   engine + analysis + API + scoring; deferred the runnable-sim-object
   wrappers (not in acceptance, add risk). Same for aqp-7 CompostLoopState
   / aqp-8 PlantLifetimeState if a runnable timeline object is wanted.
3. **Frontend surfaces** for the three phases (none built).
4. **Dustin browser review** + push to GitHub (repos PUBLIC — push
   before any `pol deploy run`).

Verify commands are at the bottom of this file. Nothing pushed to
GitHub (repos PUBLIC).

---

Dustin moved back to the aquaponics simulation. Phase-2 plan (now
executed): **`AQUAPONICS_PHASE2_PLAN.md`** at the suite root — three
GPT-4-executable phases (aqp-3 FEM hydraulics → aqp-7 worm-compost
enrichment loop → aqp-8 per-part plant growth/failure), ordered
HARDEST→EASIEST. Background: [[aquaponics-module]] +
`AQUAPONICS_MODULE_PLAN.md`.

## The three phases (all planned in AQUAPONICS_PHASE2_PLAN.md)
1. **aqp-3 — FEM water-flow engine** (hardest). New scikit-fem scalar
   Darcy solver (twin of `materialsScience/engines/fem_engine.py`
   `solve_steady_conduction`), runs on the msci-engines worker via the
   topology-routed remote seam. Answers "does the pot drain by gravity,
   at what rate, moisture field?" — replaces aqp-1's L0 permeability
   priors. Fidelity knob: reduced reservoir model (in-backend, always
   answers) vs FEM (worker). This is the long-standing aqp-3 phase.
2. **aqp-7 — worm-compost (vermicompost) nutrient-enrichment loop**
   (medium). Box-model bin that enriches passing aquaponic water; TWO
   modes both selectable — direct-in-loop (continuous) and controlled
   periodic flow-through (pulses + recharge). Abstract estimate OK;
   flag rate constants as literature-range priors. Couples enriched
   water into the pot's nutrient input; rankable via the scoring bridge.
3. **aqp-8 — per-part plant growth / growth-failure** (easiest; extends
   aqp-4). Makes the existing PlantPart objects GROW (logistic vs
   limiting resource) or FAIL (limiting factor named); volume-per-part
   interaction estimation (leaf↔root↔fruit coupling by volume+
   condition) as a small tunable coefficient table. Realized per-part
   volumes feed aqp-6 env-impact scoring.

## aqp status recap
aqp-1/2/4/5/6 BUILT + committed (5 stacked branches off the scoring
stack; 76 module selftest checks green; NOT yet deployed to staging).
aqp-3 was always "the one remaining phase". aqp-7/aqp-8 are NEW
(2026-07-09). Module lives at
`polari-rf-node/polari-framework/aquaponics/`; conventions + the exact
polariServer wiring points are in AQUAPONICS_PHASE2_PLAN.md §0.

## Live-verify commands for the aqp-3/7/8 endpoints
After `export LOCAL_IP=192.168.0.210` + `docker compose -f
docker-compose.staging-nip.yml up -d --build prf-backend` and the cold
seed finishes (backend serves :3000), from the suite root:

```
# in-container selftests (all 8 suites; 133 checks)
for t in pot growth_media plant atmosphere system hydraulics \
         vermicompost plant_growth; do \
  docker exec prf-backend python3 -m aquaponics.selftest_$t | tail -1; done

# aqp-3 hydraulics (reservoir until the worker carries skfem)
docker exec prf-backend python3 -c "import urllib.request as u; \
print(u.urlopen('http://localhost:3000/api/aquaponics/pots/demo-herb-pot/drains?soil=coir-perlite-mix').read())"
# aqp-7 vermicompost
docker exec prf-backend python3 -c "import urllib.request as u; \
print(u.urlopen('http://localhost:3000/api/aquaponics/compost-loops/basil-loop-direct/compare-modes').read())"
# aqp-8 growth
docker exec prf-backend python3 -c "import json,urllib.request as u; \
r=u.Request('http://localhost:3000/api/aquaponics/plants/sweet-basil/grow',\
data=json.dumps({'days':120}).encode(),headers={'Content-Type':'application/json'}); \
print(u.urlopen(r).read()[:400])"
```
Public proxy equivalent: `https://api.prf.192.168.0.210.nip.io/api/aquaponics/...`

## Deploy discipline (bit me repeatedly)
- `export LOCAL_IP=192.168.0.210` before ANY docker compose on
  docker-compose.staging-nip.yml (else pol-file-store crash-loops).
- prf-backend serves :3000 only after cold-seed (minutes; healthcheck
  flaps). Selftests run in-container: `pol modules selftest aquaponics`.
- API-created treeObject rows need explicit
  `manager.db.saveInstanceInDB(row)`.
- Angular templates: literal `@` breaks builds — use `&#64;`.
- falcon POST bodies read `request.bounded_stream`.

## Just-completed (last session): TOPOLOGY ORCHESTRATION — DONE
top-1..top-8 all built + live-verified (see [[topology-orchestration]]):
topology-as-data core (`topology/` module, /api/topology/*), `pol
topology` CLI + portable packages (parity round-trip), multi-node swarm
(**lightweight joined as a worker; the polari-engines stack now RUNS
THERE**), Topology tab (/topology, drag-drop modules — graph
autoplacement compacted + fit-to-view per Dustin), provider routing,
reallocation suggestions. **RELEVANT TO aqp-3**: the engines worker is
reachable via the topology-routed remote seam with no MSCI_ENGINES_URL
set — aqp-3's Darcy solver goes on that worker. ⚠️ Dustin's browser
review of the Topology tab is still pending.

## NOT pushed to GitHub
All local branch stacks (repos PUBLIC). Push before any `pol deploy
run`. Topology branches: suite/cli `dev-top-4-multinode`, rf-node
`dev-topology-orchestration`, framework `dev-top-1-topology`, angular
`dev-top-5-topology-tab`.

## Other parked work (unchanged)
scr-7 scorecard↔Polari wiring, scr-9..14; scoring/materials as before.
