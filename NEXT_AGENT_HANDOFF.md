# ⚡ DEVICE RENAME — 2026-07-27 (roles = accountability)

**Machines renamed so the name IS the mandate** (Dustin):
- **pol-core** (was staging-a, this HP box) — RESEARCH/Polari core;
  the node stack lives here.
- **isle-core** (unchanged) — ISLE-MESH/infra/hardware-integration
  core; science engines; its own Claude instance.
- **econ-core** (was lightweight, the DNB20) — BUSINESS-OPS/ECONOMICS
  core; the Odoo host (od-0 answered: sims FIRST, real ops much
  later).
Applied LIVE: swarm node labels + ALL service constraints swapped
(everything healthy), topology machine/instance rows repointed
(+roles in notes), nodes.yml keys+roles, ssh alias econ-core added
(legacy 'lightweight' still works), CLI defaults POLARI_LOCAL_NODE
-> pol-core, manifests re-rendered parity-OK. ⚠ Cleanup TODO: two
TOMBSTONE machine rows ('staging-a', 'lightweight' — notes say
renamed-to) remain in the topology table; delete via the Topology
UI/CRUDE when convenient. The TOPOLOGY itself is still NAMED
'staging-a' (deployment name, not a device) — renaming it to e.g.
'pol-core-deploy' is a separate decision. Deploy-command examples in
older sections below still say staging-a — read them as pol-core.

---

# ⚡⚡⚡⚡⚡⚡⚡ NEXT WORK: ODOO INTEGRATION — 2026-07-27 (READ FIRST)

**Dustin's next arc, handed to the NEXT AGENT: integrate Odoo as the
backbone of BOTH business simulations AND real business ops.** The
full plan is `ODOO_INTEGRATION_PLAN.md` (suite root) — od-0..7 with
the architecture (one Odoo server, TWO databases sim/ops, the hard
sim/ops separation invariant, Keycloak SSO, JSON-RPC connector module
`odooconnect`, bindings-as-data, gm mover coverage for odoo +
odoo-postgres, the wax-print micro-business as the first scenario).
Start at od-0 (Dustin decisions: version pin, host machine, ops
accounting now-or-later), then od-1 service bring-up modeled on
pol-keycloak/pol-mariadb service defs. Everything below this section
(gm/mlb/glass) is DONE and on dev — it is the machinery the Odoo
work rides on (movers, quiesce, lazy boot, receipts, topology).

## ✅ src-7 CITATION SWEEP + NEW INTERMEDIARIES — 2026-07-28
Seven citations closed flagged gaps (ferrous sulfate est, SLS EXACT
15.84/lb, rice hulls est, EPK kaolin 21.50/50lb, stearic 40.19/5lb,
candelilla est, soda ash est — cited for the FUSED waterglass route
but NOT wired into the digestion recipe: different process, needs a
melt furnace). RIPPLES (the system did its job): metakaolin now
MAKEABLE (calcine kaolin 0.86 yield → 1.10/kg vs 2.04-2.91 bought)
→ geopolymer cascade = 1.11/kg, ~77% under the GPI kit with BOTH
waterglass and metakaolin self-made; RHA makeable (burn hulls,
7.35/kg — temperature win not price win, said so); ferrite coprecip
UN-REFUSED at 20.11/kg and BUYING (9.70) honestly wins ~2x; wax
optimizer switched hardener to stearic → 6.95/kg, ~68.5% under
MachinableWax; CNT dispersions gained the optional cited SLS role.
49/49 + full sweep green. REMAINING uncited: rice-bran-wax, TEOS,
acetic-vinegar, waste-glass-fines, ferric-chloride, fly-ash, slag,
silica-gel-desiccant, exact SWCNT grade, MachinableWax exact,
+ exact re-cites for the est-flagged seven.

## ✅ src-6 SOL-GEL + FERRITE + CNT COST LAYERS — 2026-07-28
yield_fraction landed on ProductFormula (output-basis costing —
sol-gel drying loses mass; refuses outside (0,1]). SOL-GEL:
silica-xerogel via waterglass+citric (cited est 5.73/kg)+water,
yield 0.16 → 35.79/kg bought-waterglass vs 10.67/kg SELF-MADE —
first two-level cascade proven (xerogel <- waterglass <- sand/
NaOH/tap). FERRITE: magnetite pigment CITED EXACT 9.70/kg
(Walmart $21.99/5lb); coprecipitation recipe seeded but refuses to
cost until iron salts cited (ferrous-sulfate garden channel /
ferric-chloride etchant channel = the hunts) — catalog shows the
refusal as the research ask. CNT: making-from-scratch = EXPLICIT
far-off assumption (polari-cnt-lab potential, no powder formula on
purpose; techtree CNT-builder models structure not production);
grades cited: MWCNT 375/kg vs SWCNT 500/g low-end electronic
(orders of magnitude ON RECORD), dispersion market 185/kg mid;
2wt% MWCNT dispersion from BOUGHT powder = 7.50/kg (~96% under
market; sonication excluded; surfactant gap noted). 49/49 formula
+ 23/23 sourcing (rank-1 check generalized: two polari labs now)
+ all suites green. NEXT hunts: ferrous sulfate, SDS surfactant,
RHA, exact SWCNT grade quote.

## ✅ src-5 WATERGLASS = MAKEABLE INTERMEDIARY — 2026-07-28
Dustin: waterglass is critical in multiple processes and is an
INTERMEDIARY — account for local production via different routes.
Built: sodium-silicate-solution ProductInputRequirement (silica-
source 24-32% {sand CITED, rice-husk-ash*, waste-glass-fines*},
alkali 12-18% {NaOH}, water 52-62% {tap-water CITED — published 2026
utility tariff $11.63/1000gal = 0.0031/kg; municipal-water-utility
source is the clean rank-4 local-closed example}) + recipe
waterglass-hydrothermal-v0 (28/15/57) = 1.54/kg vs 8.85 purchased
(-83%, digestion energy EXCLUDED loudly; RHA route = the sol-gel
sg-community low-temp path once cited). NEW CASCADED COSTING in
formula_analysis: make_cost (seeded recipes only), effective_unit_
price (min buy/make, recursive + cycle-guard), cascaded_cost
(breakdown tags via made/cited; madeIntermediates carry the energy
caveat); product_cost_comparison surfaces formula-with-made-
intermediates rows; /api/supplychain/sourcing/cascaded-cost/{name}.
CHAIN RESULT: geopolymer castable 2.65 → 1.48/kg with self-made
waterglass → ~69% cheaper than the GPI kit. Tech tree: sol-gel node
description names the production-routes seam (first-class
waterglass-production node = deliberate follow-up; data_deps
resolve against DigitizedDataset so they were the wrong hook).
40/40 formulas + 61/61 techtree + all suites green.

## ✅ src-4b METAKAOLIN EXACT-CITED — Dustin's screenshots 2026-07-28
Clay Art Center bot-blocks automated fetch; Dustin captured the real
prices by phone: metakaolin $5/1lb weigh-out, $66.00/50lb bag EXACT,
volume tiers to $46.20/bag at 40+ bags. Cited as TWO citations: the
single bag (2.91/kg exact) and the 40-bag tier with amount=2000lb so
the pack size SHOWS the commitment the price demands (2.04/kg).
Geopolymer numbers moved: v0 = 2.65/kg, optimized = 1.85/kg vs GPI
kit 4.85/kg → making beats buying ~45-62%. Pattern for the future:
when a site blocks fetch, a user screenshot IS a valid citation
(note says so + who captured it). 31/31 green.

## ✅ src-4 GEOPOLYMER MAKE-VS-BUY — 2026-07-28 (Dustin's spec)
Same pattern as the wax: geopolymer-mix (DIY-local castable) gets
its full feedstock space + real dated citations vs buying the GPI
kit. Roles: precursor 30-50% {metakaolin CITED 2.81/kg est,
fly-ash-class-f*, ggbfs-slag*}, silicate-activator 10-22%
{waterglass $46/gal EXACT Sheffield, mass-inferred 8.85/kg
as-solution}, alkali 1-6% {NaOH 9.64/kg exact — CAUSTIC/PPE caveat},
aggregate 30-55% {play sand 0.33/kg exact Home Depot}. (* = uncited
gap; industrial byproducts, often cheap-to-free locally.) v0
40/16/3/41 = 2.96/kg; optimizer 34/10/1/55 = 2.11/kg. Substitute =
geopolymer-kit (GPI) 4.85/kg, caveats cut BOTH ways (closed formula,
heavy shipping — but hydroxide-free = friendlier than DIY NaOH).
VERDICT: MAKING BEATS BUYING ~39-56% — the reverse of the wax
economics (where bulk pellets beat blending). /compare/
geopolymer-mix serves the table. 31/31 formula selftests. v2:
dry-basis silicate cost, mix water, cure validation; hunt local
fly-ash/slag citations.

## ✅ src-3 SUBSTITUTE BENCHMARK — MachinableWax 2026-07-28
The current commercial alternative for 3D-printing wax, accounted
honestly: SupplySourceProfile machinable-wax-com (commercial,
NON-eco — paraffin+polyethylene plastics blend, fume emission when
overheated, ventilation required); ProductInputRequirement gained
substitutes_json (WHOLE-product substitutes with caveats-as-data,
distinct from role candidates); citation ~$10/lb flagged is_estimate
(store TLS-unreachable at observation — forum-referenced figure,
re-cite when reachable) → 22.05 USD/kg. product_cost_comparison
(/api/supplychain/sourcing/compare/{item}): formulas vs optimizer vs
substitutes sorted cheapest-first WITH caveats attached + verdict —
our optimized natural blend 7.79/kg beats machinable wax by ~64.6%
(v0 10.78/kg beats it by ~51%). So: natural blending loses to bulk
commercial soy pellets (6.0/kg) as raw input but CRUSHES the
dedicated commercial print-wax substitute — the business case for
blending in-house is real TODAY vs MachinableWax, and gets better
with bulk/farm sourcing. 24/24 formula selftests.

## ✅ src-2 FORMULA LAYER — BUILT + TESTED 2026-07-28 (Dustin's spec)
Products map to their FULL feedstock space: ProductInputRequirement
(roles with fraction ranges + ALL candidate item_refs per role —
uncited candidates surface as researchGaps, never silently omitted;
natural-print-wax-blend seeded: base-wax 60-85% {soy, rice-bran*,
candelilla*}, toughener 10-30% {beeswax}, hardener 5-15% {carnauba,
stearic*, candelilla*}; * = uncited gap). ProductFormula = concrete
blend rows. formula_analysis: formula_cost validates (fraction sum,
role ranges, candidate legality, uncited components REFUSE with a
citation suggestion) then costs from citations with per-component
source/citation/date breakdown AND emits the material-cost-per-kg
SCORING TERM block (is_positive=False, evidence=citations) so
simulation results can score affordability directly; cheapest_blend
= greedy min-cost feasible fractions as a SUGGESTION demanding
print-validation. REAL numbers: v0 (70 soy/20 beeswax/10 carnauba)
= 10.78 USD/kg; optimizer 85/10/5 = 7.79 USD/kg (-28%) — and both
sit ABOVE the 6.0/kg commercial-pellet price scenario v1 pins,
which is the honest economics finding retail-sourced blending has
to beat (bulk pricing / farm-grown source = the path). API
/api/supplychain/sourcing/requirements/{item}|formulas|formula-cost/
{name}?sources=cheapest|preferred|cheapest-blend/{item}. 18/18
selftests + all suites green. Follow-up: seed the matching
ScoreTerm row in the scoring module (kept out of this pass to avoid
destabilizing its count-asserting suites).

## ✅ src-1 SOURCING LAYER — BUILT + TESTED 2026-07-28 (Dustin's spec)
Costs become CITED DATA (supplychain module): SupplySourceProfile
(overlap-capable booleans open/commercial/local/polari/eco — a
source CAN be several at once; availability available|potential;
demands_json = the customer side, so mutual supply loops are one
row: the hydroponics farm supplies wax-source-biomass AND wants
geopolymer-self-watering-pot + geopolymer-pot-shelf), PriceCitation
(price + amount/unit + observed_at datetime + citation_url +
is_estimate — ranges/'from' prices are FLAGGED, never silently
exact), SourcePreferencePolicy (the definable ladder, seeded to
Dustin's order: polari-open-local(1) > polari-open(2) >
open-non-polari-IF-eco(3) > local-closed(4) > commercial(5);
first-match-wins predicates over the flags — edit rules, not code).
REAL web-researched citations 2026-07-28: GPI GeoCement kits
$34.95(10lb)-$110(50lb) (range->size mapping flagged estimate),
Aztec LP402 soy $109/50lb exact, bulkbeeswax floor $8.99/lb
(flagged), carnauba 5lb $78.36 (aroma-depot) vs $92.99 (oilscenter).
Analysis (sourcing_analysis): normalization to USD/kg (dimension
mixing refused), price_compare with spread + PREFERENCE PREMIUM,
preferred_source (better-ranked potential sources fire develop-
suggestions, never auto-picks), scenario_price_drift — found the
real thing immediately: scenario v1 pins drymix 1.8/kg vs GPI cited
4.85/kg = +169% drift, surfaced as a deliberate-edit suggestion.
API /api/supplychain/sourcing/sources|prices/{item}|preferred/
{item}|scenario-drift. 23/23 selftests; all prior suites green;
scenario products now carry item_ref links into the citation
vocabulary. NEXT: repin scenario prices from citations (Dustin's
call — the suggestion is on record), scenario 2 (farm), natural-
print-wax-blend recipe costing from the 3 wax citations.

## ✅ od-5 BUSINESS SIMULATIONS — BUILT + END-TO-END VERIFIED 2026-07-28
THE PAYOFF: the economy tree got its first NUMBERS. Dustin's scoping
("businesses that do whatever they can with the tools they have"):
scenario v1 = wax-print molds + geopolymer goods micro-business with
TWO explicit assumptions in assumptions_json (feedstock from a
purely commercial supplier — the local hydroponic wax-source farm is
scenario 2; a working wax 3D printer exists; labor/energy/
amortization excluded from v1 economics). BusinessScenarioDefinition
= scenarios as DATA (seed spec: 3 partners, 4 products, 2 BOMs —
mold=0.35kg pellets, pot=2kg drymix+0.1 mold amortized; driver: 2
cycles of buy->receive->make->sell->deliver; outcome spec names the
business model). odoo_scenario_engine: plan-first step list; the
SIM-ONLY guard refuses ops configs before anything; create/archive
return exact pol-CLI commands (DB ops are host ops — never
pretended); seed idempotent by x_polari_ref; run drives Odoo's REAL
mrp/purchase/sale logic; harvest reads origin='polari:<scenario>'
docs only -> BusinessOutcome + BusinessModelDefinition (honestly not
self_sustaining). CLI: scenario-init/scenario-drop (odoo_scn_* prefix
guard; final pg_dump receipt before EVERY drop). API: /api/odoo/
scenarios + /api/odoo/scenario/{plan|create|seed|run|harvest|archive}.
ACCEPTANCE: real throwaway DB, 10 driver steps green (4 POs, 6 molds
+ 40 pots manufactured state=done, 2 SOs delivered), metrics revenue
720 / materials 264 / margin 456, outcome 'succeeded'; TWICE from
fresh DBs -> identical metrics; ops untouched proven at DATA level
(md5-of-dump is INVALID — pg_dump 16 embeds a random \restrict token
per dump). 20/20 scenario selftests + all prior suites green.
LESSON: Odoo 18 MOs park 'to_close' unless component moves are
picked before button_mark_done — engine sets them + verifies
state==done, refusing otherwise. NEXT: od-6 ops guardrails (backup
cron, restore drill, movers) or scenario 2 (hydroponic farm grows
the wax source — vertical integration), od-7 frontend surface.

## ✅ od-4 BINDINGS + SYNC — BUILT + VERIFIED 2026-07-28 (same branches)
OdooModelBinding (bindings are DATA: odoo_model<->polari_class +
field_map_json + direction + instance_ref; a binding can never widen
an instance's permissions) + OdooSyncReceipt (every run receipted).
odoo_sync.pull: provenance odoo:<inst>:<model>:<id>@<write_date>,
row name '<prefix>-<odoo_id>' idempotent, same-prov skip / older-prov
update / FOREIGN-prov conflict-report-never-touch; class resolution
via objectTypingDict.getCreateMethod() (CRUDE path) so a gated-off
class refuses naming POLARI_MODULES. odoo_sync.push: x_polari_ref
ensured on demand (ir.model.fields create = itself a guarded write),
found->write absent->create, explicit row_names required, confirm
string forwarded into the client guards. API: /api/odoo/bindings|
pull|push|receipts. Seeds: partners->SupplyNode, product.template<->
WaxFeedstockDefinition (both), mrp.bom->SupplyChainDefinition
(refuses until mrp installed). TESTS: 26/26 selftest_odoo_sync vs the
shared stub_odoo.py (stub starts WITHOUT x_polari_ref — ensure path
exercised for real); 27/27 od-3 suite still green. REAL acceptance
on the local pair: pulled hand-seeded products with exact provenance,
pushed a Polari row into odoo_sim (custom field created live,
round-trip verified, re-push updated not duplicated), ops write
refused AT THE GUARD (knob named) while ops reads flowed. Local
odoo_sim now has the 'product' app + test rows (verification
artifacts). NEXT: od-5 BusinessScenarioDefinition + wax-print
micro-business scenario (installs product/mrp/sale in scenario DBs).

## ⚡ ODOO LIVE ON ECON-CORE — 2026-07-28 (its mandated home)
Shipped WITHOUT pushing repos (Dustin: ssh route OK): images
docker-save|ssh-load'd, minimal runtime dir ~/polari-odoo-runtime on
econ-core (compose file + pol-odoo{,-postgres} configs + .generated
env copied; .generated/odoo-ports.yml override publishes 8069/8072/
5432 on the LAN until the proxy runs there) — run with
`docker compose -p polari-suite ...` so containers/volumes are named
EXACTLY as a future real checkout expects (polari-suite_odoo-db-data
adopts seamlessly). Both DBs created (base only, no product app yet),
admin passwords set + shown once in-session. Login:
http://192.168.0.66:8069/web/login?db=odoo_sim . SSO not configured
there (needs pol-keycloak reachable). The local pol-core pair still
exists (volumes kept) as the dev/verification copy.

## ✅ od-3 ODOOCONNECT MODULE — BUILT + VERIFIED 2026-07-27 (same branches)
Framework module modules/odooconnect/ (waxsupply anatomy):
OdooInstanceConfig treeObject (mode sim|ops, base_url + url_env
override, auth_password_env = env-var NAME never a secret,
push_enabled default False, read_only), stdlib JSON-RPC odoo_client
(OdooHandle bound to ONE row — sim/ops can never blur in a handle;
{ok:False, refusal, suggestion} everywhere; NO write retries;
READ_SAFE_METHODS allowlist so unknown methods are guarded), duck-
typed odoo_analysis, /api/odoo/status + /configs (OdooConnectAPI,
gated by _feature_available), seeds odoo-sim (push free) + odoo-ops
(read_only, push_enabled=False, typed phrase 'PUSH TO OPERATIONS
odoo-ops' required per write). Wired: polari-modules.json wave 2,
FEATURE_MODULES, polariServer guarded import + defClassList +
seed_pairs + endpoint block. TESTS: 27/27 selftest_odoo against an
in-process stub JSON-RPC server (auth, paging, refusal shapes, all
guard permutations, handle separation, status over fake manager) +
module suites green (registry 10/10, lazy-imports 15/15, lazy-boot
34, deps 13/14 = pre-existing xr miss). REAL round-trip verified
against the od-1 pair (18.0-20260723, uid 2, live partners).
Env knobs: ODOO_SIM_URL/ODOO_OPS_URL, ODOO_SIM_RPC_PASSWORD/
ODOO_OPS_RPC_PASSWORD (backend-side). Deviation: provider_registry
/capability probing skipped (odoo has none) — /api/odoo/status is
the probe surface. NEXT: od-4 OdooModelBinding + pull/push sync.

## ✅ od-2 SSO — BUILT + VERIFIED 2026-07-27 (same branches)
OCA auth_oidc 18.0.1.1.0.2 wheel PINNED into pol-odoo/Dockerfile;
`pol odoo sso-setup` (polari-cli scripts/lib/odoo-sso.sh) is the
idempotent, never-hand-clicked flow: admin-API-inside-pol-keycloak
ensures confidential client 'odoo' in realm Polari (redirect
https://odoo.<domain>/auth_oauth/signin — auth_oidc reuses the
auth_oauth route), then installs auth_oidc + upserts the
auth.oauth.provider row in EVERY odoo_% DB (flow id_token_code;
secret flows KC->odoo DB, never a file). Endpoint split = the PRF
pattern: browser auth/logout public https://auth.<domain>, token/
jwks/userinfo in-network http://pol-keycloak:8080. VERIFIED live
(pol-mariadb+pol-keycloak brought up from the existing volume, then
downed): client created+updated idempotently, both login pages
render 'Log in with Polari SSO' with a correct code-flow link.
GOTCHA fixed en route: docker exec needs -i for bash -s stdin
scripts. Honest gaps: browser round-trip + gm-4 KC-move-mid-session
check wait for pol-proxy serving odoo.<domain> (prf-proxy owns :443
on pol-core); KC-role->Odoo-group mapping MANUAL v1 (init-db admin
password = break-glass local login). Topology: odoo->pol-keycloak
keycloak-client-secrets connection seeded (16 connections, 52/52).
NEXT: od-3 odooconnect module (stdlib JSON-RPC, OdooInstanceConfig/
OdooModelBinding rows, stub-server selftests, /api/odoo/status).

## ✅ od-1 SERVICE BRING-UP — BUILT + VERIFIED 2026-07-27
Branches `dev-od-1-odoo-bringup` (suite + polari-cli + framework),
NOT pushed. `pol odoo up|down|build|status|logs|init-db <sim|ops>|
backup <sim|ops>|urls` works end-to-end: pair healthy in ~30s on the
staging tier, odoo_sim + odoo_ops created (admin password printed
ONCE at init-db), login forms serve, db-manager RPCs refuse
(list_db=False), pg_dump receipts (3.3M) in .generated/backups/.
Key shapes: images PINNED (odoo:18.0-20260723 / postgres:16.14, own
Dockerfile dirs pol-odoo/ + pol-odoo-postgres/); compose profile
'odoo' in ALL tiers so plain suite up NEVER starts the pair; proxy
odoo.<domain> routes are VARIABLE proxy_pass + resolver (a static
upstream would stop nginx booting while the profile is down),
/websocket -> :8072, friendly 503 JSON when down; ONE shared DB
secret in pol-odoo-postgres/odoo-postgres.env + pol-odoo/odoo.env
(setup-polari-security.sh 3b, knob POLARI_ODOO_DB_PASS, skip-if-
exists — drift rescue documented in pol-odoo/README.md); topology
seeds gained odoo + odoo-postgres instances on econ-core + 3 typed
connections (erp-api-seam key added), machine seed 'lightweight'
RENAMED to econ-core, topology_render.py got the odoo shape (52/52
+ 25 + 45/45 + 19/19 topology selftests green); registry entries +
suite trio re-rendered byte-parity OK; pol proxy render/check/
promote green (pol-proxy wasn't running — prf-proxy owns :443 on
pol-core — so browser-through-proxy verification waits for a suite
deploy; nginx -t validated the config). Verification pair was
brought up on pol-core then downed; volumes odoo-db-data/
odoo-filestore kept. NEXT: run `pol odoo up` on econ-core once code
syncs there (repos unpushed), then od-2 SSO (KC client + auth_oidc
addon in pol-odoo/Dockerfile), od-3 odooconnect module.

---

# ⚡⚡⚡⚡⚡⚡ CONSOLIDATED ON dev — 2026-07-27 (Dustin's call)

**ALL WORK IS NOW ON THE BASE `dev` BRANCHES** in all five repos
(framework fa475f3, angular 744d925, cli 88497c3, rf-node 34be606,
suite 2e55cb5) — pure fast-forwards (every feature branch was an
ancestor; nothing left behind, verified with --no-merged). Submodule
pointers coherent. Feature branches remain as historical markers.
NOT pushed — repos are PUBLIC; pushing stays Dustin's manual step.
Selftest sweep re-run green from the dev checkouts; live swarm
stack verified unaffected (same content).

---

# ⚡⚡⚡⚡⚡ GM-1 GRACEFUL ENGINE MOVES — 2026-07-27 (NEWEST)

**✅ gm-1 + gm-2-lite BUILT + ACCEPTANCE PASSED same day** (Dustin:
"the capability to move engines dynamically... ensure it can meet the
same criteria" as mlb — explicit trigger, topology-frontend tie-in,
tracked, prior-knowledge timing). Plan: GRACEFUL_MOBILITY_PLAN.md
(gm-1 automated; gm-2 landed as the moves-as-data slice; quiesce +
gm-3..5 stateful movers remain). Branches: framework
`dev-gm-1-engine-moves` (off dev-mlb-lazy-boot, a861f05), polari-cli
`dev-gm-1-graceful-allocate` (off dev, f5a7110), angular
`dev-gm-moves-ui` (off dev-mlb-frontend, 3dac0a3). NOT pushed.

- `pol allocate <instance> <machine> --graceful` = the gm-1 blue-
  green: image check/ship (save|ssh load, sized receipt) -> label
  check -> `docker service update --update-order start-first` +
  constraint swap (routing mesh keeps :9500 answering) ->
  /capability readiness gate -> probe-cache invalidation (NEW POST
  /api/topology/providers/reprobe; cache was 30s-TTL-only) ->
  verify. Needs POLARI_CORE_URL on swarm (be_call's docker-exec
  fallback expects the compose container name).
- MOVES AS DATA: MoveOperation rows (topology/move_operations.py) —
  planned step list shown BEFORE running, per-step receipts +
  server-measured durations, EXPECTED step durations = median of
  prior verified moves (failed moves never teach; no history = {}).
  API /api/topology/move-operations (+/step, /finish) + STOMP
  /topic/MoveOperation. plan_move's engine hand-back now suggests
  the --graceful command first.
- ✅ ACCEPTANCE (the plan's exact criterion): isle-core ->
  lightweight -> isle-core, 55 polls @1s against /capability, ZERO
  failures. Both moves 'verified' (7.6s / 10.2s total); move #2 ran
  with expected durations from move #1. Engines image now ALSO on
  lightweight (kept). Topology row for 'engines' updated + renders
  parity-OK (this also fixed the stale machine_name row).
- FRONTEND: "Graceful moves" panel atop /topology — step tables with
  receipts, measured vs expected durations, 3s poll while running.
  ng build green; frontend rolled; NO browser pass yet.
- Selftests: topology.selftest_move_operations 15 + topology 52/52 +
  lazy-imports 15/15.
## ⚡ SAME DAY 2nd pass: gm-2 QUIESCE + gm-5 SQLITE INSTANCE MOVE
("just keep moving" — framework d312d8f, cli 01d4d6e)
- gm-2 FULL: POST /api/quiesce (gate FIRST, persistTree flush, then
  the receipt — nothing mutates after it returns) + /status +
  /release; QuiesceMiddleware 423s mutations, reads + receipts flow;
  failed flush keeps the gate UP. In-process state ON PURPOSE
  (relocated instances boot unquiesced). selftest_quiesce 16.
- gm-5: `pol swarm relocate <machine>` moves the BACKEND (owned
  sqlite): sync-image (image-ID compare — same tag != same code
  across swarm nodes, learned the hard way) -> short-poll quiesce ->
  snapshot -> double-pass tar copy + PRE-BOOT file verify ->
  stop-first constraint swap -> placement-gated boot-ready with
  measured downtime -> dedup-aware verify (tables + stable tables +
  the marker MoveOperation row that travels INSIDE the copied DB) ->
  retire (old volume = rollback).
- ✅ LIVE: backend moved staging-a -> isle-core -> staging-a. Marker
  proof worked BOTH ways; return downtime ~71s (lazy boot!); final
  state: backend home on staging-a, engines on isle-core, rollback
  volumes on both boxes. Move rows: backend@1785164149 (forward,
  marked failed — verify raced, fixes applied) + backend@1785165052
  (return, VERIFIED with full receipts).
- ⚠ TWO MEASURED FINDINGS (the real gm-5 lessons):
  1. persistTree flush took 2758s on isle-core (row-by-row REPLACE +
     sqlite lock contention vs concurrent readers; OOPS handler
     recovered 4 lock failures). mlb-5b BATCHED FLUSH is now the
     gating item for gm-5 GA — the mover works, the flush is the
     bottleneck.
  2. Post-boot row totals SHRINK legitimately (restore dedupes
     historical duplicate rows then persistTree rewrites clean) —
     raw-total is the WRONG invariant; the mover now checks the
     copied FILE pre-boot + stable tables + marker post-boot.
## ⚡ SAME DAY 3rd pass: mlb-5b BATCHED FLUSH (fw 4540f6d, cli c0d960c)
Dustin: "sensible batches, module by module, per object type."
- managedDB.saveClassBatch = ONE transaction per object type (scoped
  DELETE + executemany REPLACE, uniform full-column rows — REPLACE
  NULLs unnamed columns either way so byte-equivalent to per-row);
  ok=False -> row-by-row OOPS fallback, never silent loss.
- persistTree = MODULE-ORDERED (core first, then dependency order),
  one batch per class, per-class progress callback, per-class
  fallback. Quiesce engage now ASYNC (gate up instantly, flush in a
  thread, /api/quiesce/status streams currentModule/currentClass/
  classesDone/rowsDone; wait=true = inline for tests).
- ✅ A/B ON THE LIVE RELOCATION (same data/boxes): flush 2758.5s ->
  53.2s (staging-a) / 104.4s (isle-core slow disk) — 26-52x. BOTH
  relocation directions ran FULLY AUTOMATED + verified,
  backend@1785179128 + backend@1785179320, downtime ~69-71s,
  expected-vs-actual populated from history. Final state: backend
  home on staging-a, engines isle-core, rollback volumes both boxes.
- selftest_batched_persist 17 (+PYTHONPATH=modules) +
  selftest_quiesce 20; full regression sweep green.
## ⚡ SAME DAY 4th pass: gm-SAFETY (fw fa3b07a, cli 24534f4)
Dustin's invariants: no failure point may lose data; delete only
after confirmation; be able to finish or reverse (target full /
connection drop); interrupted transfers discoverable after a crash.
- Mover: PREFLIGHT (target reachable + >=3x free space, fail early)
  -> STAGED copy into .incoming-<move>/ (live target data untouched
  by mid-copy failure; re-run resumes — quiesce engage is now
  idempotent per moveName) -> staged file verified row-for-row
  BEFORE the swap -> displaced generation kept in .previous-<move>/
  -> retire deletes ONLY target .previous + journal, after verify.
  The SOURCE volume is never deleted; its journal is rewritten
  'retired-moved-to-<target>' so any later boot of it declares
  where the live data went.
- .move-journal.json in BOTH volumes (phase copying->swapped) =
  crash-durable transfer record; /api/health surfaces
  staleMoveArtifacts (journal/.incoming/.previous) with meaning +
  action. selftest_quiesce -> 27.
- ✅ LIVE: staging-a -> isle-core -> staging-a fully automated +
  verified (downtime ~71s/~82s; flush 28.9s); planted-journal test
  surfaced + cleared on /api/health.
- ⚠ OPERATIONAL LESSON (recorded the hard way): never start a move
  while a service update is converging — a raced attempt
  (backend@1785180981, marked failed honestly) had its in-process
  gate wiped by the restart; no data touched (copy hadn't started).
  A pre-move 'no update in progress' check is a cheap future guard.
## ⚡ SAME DAY 5th pass: GUARD + gm-3 MinIO MOVER (fw a847479, cli ceac47c)
- GUARD (the raced-deploy lesson, enforced): relocate AND graceful
  allocate refuse to start while the moved service (or the backend
  carrying receipts) has a swarm update converging.
- `pol swarm relocate [backend|file-store|keydb] <machine>` — the
  staged-copy mover parameterized per service. MinIO (gm-3): verify
  = user-object count (.minio.sys volatile + move journal excluded);
  all data ops volume-level via alpine (MinIO image lacks tar/find);
  sidecar moves RELEASE the quiesce gate at retire (backend did not
  move). keydb-move shares the plan, refuses honestly until a stack
  deploys KeyDB (replica-promote zero-cold-cache = refinement).
- ✅ LIVE: prf-file-store staging-a -> isle-core -> staging-a,
  downtime ~12s/~11s, seeded 76KB object md5-intact after the round
  trip (read cross-node mid-flight), receipts complete
  (prf-file-store@1785184034 + @1785184115 verified). Bonus proof:
  the FIRST attempt refused at staged-verify (journal counted) with
  live data untouched and clean resume — the safety design working.
## ⚡ SAME DAY 6th pass: gm-4 KEYCLOAK MOVER (fw 05e2152, cli b142753,
## rf-node f94611f) + AUTH OUTAGE FOUND & FIXED
- ⚠ FOUND LIVE (pre-move probe): Keycloak had been CRASH-LOOPING
  since the mlb-0 stack redeploy — generated DB credentials DRIFT:
  stack re-renders inline CURRENT env files, but the MariaDB volume
  keeps the passwords it was INITIALIZED with (kc + root both
  mismatched). FIXED via rescue container (--skip-grant-tables on
  the volume, ALTER USER to the current rendered values — password
  reset only, zero data touched; 2 realms intact). JWKS 200 again.
  SYSTEMIC NOTE: any credential regeneration between deploys will
  re-break DB-backed services — the render/secrets pipeline needs a
  stable-credentials story (docker secrets refinement).
- gm-4 `pol swarm relocate keycloak <machine>`: SERVER-ONLY move
  (realms/keys live in MariaDB which does NOT move; keycloak+DB in
  one step refused via db-check). Blue-green start-first with a
  SELF-HEALING readiness healthcheck (first attempt measured the
  outage: an ungated JVM container is "running" in seconds, serves
  minutes later — the mover now applies a /dev/tcp realm healthcheck
  if absent; compose source carries it for future renders). Verify =
  SIGNING-KEY (kid) identity — access tokens expire in ~60s, shorter
  than any move, so kid comparison is the honest continuity check.
- ✅ ACCEPTANCE: isle-core -> staging-a, 223 JWKS polls @1s, ZERO
  failures (both servers visibly overlapped mid-swap), kids
  unchanged, receipts complete (prf-keycloak@1785187634 verified).
  KC image now also on isle-core (kept). Forward attempt receipts
  honestly record the two design lessons (token-lifetime verify +
  missing healthcheck outage).
## ⚡ SAME DAY 7th pass: gm-5 MARIADB MOVER (fw 18de28c, cli 88497c3)
## — EVERY gm MOVER (gm-1..5) IS NOW AUTOMATED
- `pol swarm relocate mariadb <machine>` — v1 correct-before-clever:
  writers-drain (Keycloak scaled 0, auth window MEASURED) ->
  mariadb-dump --single-transaction to .generated/backups/ (backup
  AND semantic baseline) -> quiesce-db (scale 0, volume still) ->
  staged volume copy verified pre-swap -> constraint swap + health-
  gated scale-up -> verify counts vs receipt + KC recovery + JWKS ->
  retire keeps source volume AND dump. mv_fail re-issues scale-1 on
  DB + writers — a failed DB move never strands auth down. v2
  replica-promote = documented refinement.
- ✅ ACCEPTANCE both directions: DB window ~62s/57s, auth window
  ~145s/141s, counts 2 realms/16 clients/3 users/88 tables identical
  both ways (prf-mariadb@1785189969 + @1785190199 verified); auth ran
  CROSS-MACHINE mid-flight (KC staging-a, DB isle-core, JWKS 200).
  All images (backend/engines/keycloak/mariadb/file-store) now on
  BOTH staging-a and isle-core — any split is a constraint swap away.
- THE MOVER SET IS COMPLETE: engines (blue-green), backend (sqlite
  staged), MinIO (staged), Keycloak (server-only blue-green), MariaDB
  (drain+dump+staged). All share: MoveOperation receipts + expected
  durations, staged-copy/no-deletion-before-confirmation, dual-volume
  journals + /api/health stale-artifact surfacing, update-in-progress
  guard, resumable quiesce.
## ⚡ SAME DAY 8th pass: gm-6 KIND-AWARE MOVE FLOWS — GM SEGMENT
## COMPLETE (gm-1..6 all built; fw fa475f3, ng 744d925, rf 34be606)
- Backend: MOVE_SUBJECTS catalog + move_plan() preview + GET
  /api/topology/move-operations/plan (?subject=&machine=) — planned
  steps, expected durations from history (LIVE: predicts 184s for a
  mariadb move from today's real receipts), statefulness, exact
  command. selftest_move_operations 25.
- Frontend /topology "Plan a graceful move…": subject+machine ->
  step plan + per-step ETAs (no history = 'no ETA, never a guess')
  -> STATEFUL subjects demand typing the subject name -> copy-ready
  command. Running moves PULSE; when a watched move verifies, the
  graph repaints AND the foundational ping pass auto-runs + paints.
  Execution stays the human-run command (knobs-and-suggestions).
  Deployed; NO browser pass yet (planner + pulse + verify strip).
- gm REFINEMENTS (all named, none built): UI-triggered execution
  (needs a host-side executor agent), KeyDB replica-promote, MariaDB
  binlog v2, docker-secrets (kills the credential-drift class),
  local registry (replaces save|ssh-load).

---

# ⚡⚡⚡⚡ MLB LAZY BOOT — 2026-07-27 (read with the section below)

**✅ mlb-0..5a BUILT + DEPLOYED + CROSS-DEVICE VERIFIED same day**
(Dustin: "start on mlb and keep going autonomously"; asks folded in:
multi-device splits over SSH, dynamic module moves, topology tie-in,
enabled/disabled tracking, and time-to-online-after-deps history).
Plan + wiring survey: MODULE_LAZY_BOOT_PLAN.md (PREP section has the
file:line map). Branches: framework `dev-mlb-lazy-boot` (off
dev-mtt2-solgel, 99e1c9e), angular `dev-mlb-frontend` (off
dev-gsp-structure-ui, becd09b), rf-node/suite dev-swarm-msci-deploy.
NOT pushed.

## What runs now (all live-verified)
- POLARI_LAZY_BOOT=on (default off = monolithic, byte-compatible):
  Phase 0 = typing+routes, LISTEN in ~10s; admission worker (daemon,
  mesh-autoconfig idiom) does core data then modules dependency-
  ordered. SWARM staging-a: core 56s / ALL msci modules online 107s
  on the real volume (was 15-25min + kill-loops). Healthcheck now
  hits /api/health (200 at core-ready; long grace kept for the
  monolithic fallback).
- Honest 503s while loading (middleware resolves CRUDE apiObject ->
  class -> module; custom APIs by package; Retry-After 5). /api/
  health + /api/modules/status (phase, per-module rows, %/times).
- POLARI_MODULES gate live on the swarm: msci set (materialsScience,
  pspp,techtree,simulations,polariapps) online; the other 18 modules
  visibly 'disabled' — enabled/not-enabled is tracked, never hidden.
- TIMING HISTORY (Dustin's ask): ModuleBootRecord rows persist each
  module's duration AFTER ITS DEPS came online, per boot+instance;
  warm boots restore history in the core phase and stamp
  expected_online_s ETAs (median; no history = NO ETA shown).
  PolariModule carries boot_status/timestamps/seeded/error/eta.
- FRONTEND /modules/bringup (angular): live tiles pending->loading->
  online/failed/blocked (STOMP /topic/PolariModule + poll fallback),
  progress bar, time-to-core/full, per-module ETA + last duration,
  disabled dashed; linked from /topology. NO browser pass yet.
- CROSS-DEVICE SPLIT EXPERIMENTS (via SSH): prf-backend:staging
  shipped to isle-core (image KEPT there). isle-core ran the AGRO
  family (aquaponics+plant_morphology+scoring): dependency order
  proven numerically (deps finish before aquaponics starts;
  deps_ready_at == last dep's online time); msci disabled there /
  agro disabled on staging-a = complementary split. DYNAMIC MOVE
  rehearsal: warm restart with techtree ADDED -> techtree admits
  fresh (no ETA), the 3 prior modules PREDICTED their durations from
  history (scoring ETA 1.076s vs actual 1.1s); warm core 24s.
- mlb-5a: POLARI_DB_LOG=quiet default ([DB-Save] stream gated, 17
  sites; warnings/errors always loud). Node compose carries all 3
  knobs render-time (${POLARI_MODULES:-} etc.).
- Selftests: moduleService.selftest_lazy_boot 34 (order/cycle/drift-
  pin/ETA-math/503+health via falcon TestClient/stubbed worker incl.
  LOUD failure + blocked deps) + selftest_db_log_quiet 16 +
  lazy-imports drift guard 15/15. Dependency edges: polari-modules.
  json is authoritative (FEATURE_REQUIRES pinned subset).

## Deploy cmd that WORKS (constraints + knobs at render)
  export LOCAL_IP=192.168.0.210
  C="node.labels.polari.machine==staging-a"
  POL_STACK_CONSTRAINTS="backend=$C frontend=$C prf-file-store=$C \
    prf-keycloak=$C prf-mariadb=$C prf-proxy=$C" \
  POLARI_LAZY_BOOT=on POLARI_MODULES=materialsScience,pspp,techtree,\
  simulations,polariapps POLARI_DB_LOG=quiet pol swarm deploy node
  (then force both service images as usual)

## mlb NEXT
- Browser pass: /modules/bringup + topology link (+ glass tab etc.).
- Derive POLARI_MODULES from ModuleAssignment rows automatically
  (pol topology/allocate emits the env; today it's typed at render).
- Nav gating sweep (mlb-4 second half): pages owned by a not-yet-
  online module render "loading — Nth in queue" (an HTTP interceptor
  on the 503 module-loading body); pspp pages already render
  refusals so v1 is acceptable.
- mlb-5b: batch seed inserts per class in one transaction; per-module
  persistence replay so Phase A restore shrinks further.
- Second swarm boot will show ETAs on /modules/bringup (history now
  exists on the volume). tt-16 blue-green module handover rides
  ModuleBootRecord + the move rehearsal above.

---

# ⚡⚡⚡ HANDOFF — 2026-07-26 (READ THIS SECTION FIRST; supersedes below)

**✅ REVIEW PASSED (Dustin) + ✅ ALL COMMITTED (later same day) +
✅ mtt-2 SOL-GEL BUILT.** Prepared for a context clear: this section
+ the plan files + the memory entries are the full pick-up.

The live target is a SWARM-based msci-focused instance, NOT the
compose suite. Full state in memory: [[swarm-msci-instance]],
[[geopolymer-structure-sampling]], [[materials-tech-tree]],
[[styling-theme-tokens]]. Plans at suite root:
MATERIALS_TECH_TREE_PLAN.md, MTT2_SOLGEL_SINTERING_PLAN.md,
GEOPOLYMER_STRUCTURE_SAMPLING_PLAN.md, FRONTEND_THEMING_PLAN.md,
MODULE_LAZY_BOOT_PLAN.md.

## ✅ COMMITS DONE 2026-07-26 (branch-per-phase, innermost-first, NOT pushed)
- framework (off dev-ssp-3-symmetry-xrd): `dev-gsp-structure` →
  `dev-mtt-1-materials-tree` → `dev-mtt2-solgel` (stack top).
- angular (off dev-ssp-2-lattice-view): `dev-sty-2-theming` →
  `dev-gsp-structure-ui` (stack top).
- rf-node: `dev-swarm-msci-deploy` (swarm nginx/grace fixes + both
  submodule pointer bumps). suite: `dev-swarm-msci-deploy`
  (stackify swarm-schema fix + session plans + rf-node pointer).
- Do NOT push — Dustin's manual step, repos are PUBLIC.

## ✅ mtt-2 Part A SOL-GEL BUILT (framework `dev-mtt2-solgel`, 6e9c188)
sg-1..5 per MTT2_SOLGEL_SINTERING_PLAN.md — a pure DATA library
(CMC-seed precedent), ZERO schema changes (condition gates already
key on arbitrary descriptors; the pH gate is just window rows):
- solgel_network.py: alkoxide species (generic Si(OR)4 + TEOS/TMOS;
  Al/Ti/Zr honest species-only), hydrolysis + water/alcohol
  condensation + growth rules on the SHARED siloxonate-q0..q4 ledger;
  pH catalysis-fork gates (acid→polymeric/spinnable,
  base→colloidal/dense; coarse neutral boundary, noted) + R gate +
  spinnability quality window; solgel_inventory (stoichiometry).
- solgel_process.py: sol→gel-point→aging→xerogel/aerogel FORK→
  densified-glass stages; 3 POINTS-EMPTY provisional Brinker datasets
  (gel-time-vs-pH, NMR Qn-vs-time, shrinkage-vs-T) that REFUSE until
  photographed — the refusal names the data ask.
- solgel_structure.py: stepped Q-groups under {pH,R} gates (shared
  new helper structure_groups.inventory_q_fractions); acid/base route
  demos through the gsp sampler/halo — acid Q4 0.0 vs base 0.5,
  polymeric XOR colloidal reachability, halo present both.
- API: GET /api/pspp/solgel/routes (+?route=acid|base), POST
  /api/pspp/solgel/stepped. polariServer seeds concatenate SOLGEL_*
  (guarded imports + stubs; drift guard 15/15).
- 58 new checks (24+15+19) green host AND in-container; full pspp
  sweep green; fixed pre-existing selftest_pspp_views red (rule count
  pinned 17 → tracks seed list). techtree sol-gel node SHELL→BUILT
  (⚠ changed seed row: live volumes keep the old text until row
  deletion + restart — cosmetic).
- Backend rebuilt + swarm service updated same day (cold seed ~10-15
  min; verify GET /api/pspp/solgel/routes?sample=false answers).

## ✅ mtt-2 sg-community BUILT + deployed (framework `dev-mtt2-solgel`, 857ba2d)
Dustin's ask: prove COMMUNITY-ACCESSIBLE sol-gel from common materials
(citrus/citric acid, rice husk, water glass), AND keep the industrial/
lab routes as REFERENCE so the lab->common SUBSTITUTION MAP is explicit
data. His steer: accessibility = a recorded PROPERTY of every
precursor/route, never a gate that hides one.
- solgel_network: alkoxide-FREE water-glass chemistry (sodium-silicate
  + citric-acid + silicate-acid-gelation rule + waterglass_inventory).
- solgel_sourcing.py (NEW `PrecursorSource` class): tiers household /
  common-industrial / lab-reagent; substitution_map (citrus juice <-
  mineral acid; water glass / rice husk <- TEOS); route_accessibility
  (route = worst precursor); route_report. COMMUNITY_ROUTES =
  waterglass-citrus, ricehusk-citrus, teos-citrus, teos-ammonia-lab.
- API: GET /api/pspp/solgel/sources, GET /solgel/community-routes
  (+?route=<name> full report). PrecursorSource wiring mirrors
  BenchmarkCase (module auto-registers; NOT in defClassList).
- ⚠ NOTHING claimed "proven". Tiers = qualitative CITED claims (real
  papers found via web, none were previously in the repo: lemon
  bio-waste sol-gel, Sustainable Chemistry 2021; rice-husk silica;
  acid-initiated sodium silicate, Gels 2024 / JMRT 2020). Numeric
  performance REFUSES until digitized. The water-glass MORPHOLOGY fork
  is OPPOSITE the alkoxide one (acidic water glass = dense small
  particles) — route_report refuses to assert a winner for it.
- 25 new checks (host + in-container). DATA ASKS to quantify: digitize
  sodium-silicate gel-time/morphology-vs-pH, rice-husk yield, lemon
  acid content.

## The running system (verify first: `docker service ls`)
- Swarm stacks: `polari-node` (all services pinned staging-a) +
  `polari-engines` (msci worker pinned isle-core, :9500 via ingress).
- App: https://prf.192.168.0.210.nip.io  API: https://api.prf.192.168.0.210.nip.io
- Deploy loop that WORKS: edit → `pol node build backend`(and/or
  frontend) → `docker service update --image prf-<x>:staging --force
  polari-node_<svc> --detach` → wait ~10-15 min cold seed (backend
  start_period is 1800s; routes 404 until endpoint construction ends,
  then answer). Bring up from cold with the constraint env — see
  swarm-msci-instance memory for the exact POL_STACK_CONSTRAINTS line.
- In-container selftests (swarm names differ from `pol modules
  selftest`): `docker run --rm -v $PWD/polari-framework:/app -w /app
  -e PYTHONPATH=/app:/app/modules prf-backend:staging python3 -m
  <module>.selftest_<x>`.

## What got built this session (all live-verified unless noted)
1. Swarm msci instance + 4 real deploy fixes (stackify swarm-schema,
   nginx lazy upstreams, backend grace/cpu). See memory.
2. Theming (pspp + materials-science + shared layout): tokens (sty-2)
   THEN three root-cause fixes verified in-browser by Dustin —
   (a) Material's prebuilt DARK palette leaked its near-white default
   into any uncolored text → fixed with `:host{color:var(--text-on-bg)}`
   anchor + SVG `fill` tokens; (b) DARK-MODE PAGE BACKGROUND: template
   has no <mat-sidenav-content>, so Material auto-generates an implicit
   `.mat-drawer-content` that never used our token → GLOBAL rule in
   styles.css ties `.mat-drawer-content/.mat-sidenav-content` to
   `--surface-app-background` (fixes bg app-wide, not just pspp);
   (c) /pspp/structure XRD page-freeze (getter→stable field render
   storm). Context-semantic tokens added: `--text-on-card{,-muted}` /
   `--text-on-bg{,-muted}` (pick by SURFACE); `--text-on-bg`=#000 light.
   FRONTEND_THEMING_PLAN.md has the rules; sty-3 sweep (app-wide, ~20
   dirs) must do :host anchor + SVG-fill audit + surface-token, not
   just hex→token. Light + dark both confirmed good on /pspp.
3. gsp-1..5 + 2b (GEOPOLYMER_STRUCTURE_SAMPLING_PLAN.md): Q-groups
   (reference/state/stepped modes) + deterministic ensemble sampler
   + /pspp/structure 3D page + Debye halo validation + density knob.
   70 selftest checks green. Halo validation caught a real sampler
   collapse bug (fixed). Optional follow-on: gsp-2 ring-statistics
   bias so more seeds land the halo in the gel band.
4. mtt-1 (MATERIALS_TECH_TREE_PLAN.md): new `materials-science` tech
   tree, 12 nodes (statistical/discrete/encapsulation hubs + 9 cores;
   stainless equiv = galvanized-bio-steel). Live.
5. smt-1: new `simulation-methods` tech tree, 9 method nodes. Live.
   techtree selftest 52/52.

## ✅ mtt-2 tech-tree DATA GAPS + Part B SINTERING ENGINE BUILT (dev-mtt2-solgel, 8ddf80e + 4f49cdc)
- GAPS ACCOUNTING (Dustin: account for the gaps in the tech tree):
  structural (theory) completion vs DATA completeness are now SEPARATE
  axes. Every sol-gel/community data ask is a first-class provisional
  DigitizedDataset; TechNode.data_dependencies_json + techtree_analysis
  .node_data_gaps DERIVE a warn gap for any referenced dataset that is
  missing/provisional/points-empty (carries the dataset's DATA ASK;
  digitize -> gap auto-clears; does NOT move completionLevel). sol-gel
  node declares 6 datasets, ceramics node 2. techtree 59 checks.
- SINTERING ENGINE (the genuinely-new Part B one): pspp/sintering_
  engine.py analytic Master Sintering Curve. Θ = ∫(1/T)exp(−Q/RT)dt
  (holds exact, ramps Simpson; isothermal closed form self-check);
  relative_density Θ->ρ via a master-curve DigitizedDataset (returns Θ,
  REFUSES ρ without a ready curve / in-range Θ); grain_size mean-field
  d^n law. HONEST SPLIT: Θ pure math, ρ(Θ)+kinetics are calibration
  data that refuse — no invented Q/curve/kinetics. sintering_structure
  .py plan-first L2 rows (grain-domain+pore-network) feeding the gsp-4
  seam. API POST /api/pspp/sinter/fire + GET /sinter/master-curves. 35
  new checks.

## ✅ mtt-2 CERAMICS SAMPLES + ESCALATION LADDER + FURNACE TECH TREE (dev-mtt2-solgel, 202391a)
Dustin's asks: locally-producible ceramic samples, "gradual escalating
temperature resistance", olivine carbon-negative track, and an
escalation ladder geopolymer-oven -> steelmaking — with tech trees
TRACKING it (his steer: a Manufacturing Tool / Furnace tree, "thermal
strain of material refinement").
- ceramics_samples.py (CeramicSample): earthenware->stoneware->fireclay
  firebrick->cordierite(thermal-shock champ)->mullite->alumina->SiC +
  TWO steelmaking basic refractories: LOCAL dolomitic (carbon-positive)
  and NON-LOCAL olivine forsterite (carbon-negative). feedstocks+tier,
  literature-approximate temps (temp_claim_status), thermal_shock,
  refractory_class (basic=steel-slag-resistant), carbon_profile.
- ceramics_ladder.py (LadderRung): the furnace bootstrapping (each rung
  built from the last one's output) + a CNT-CVD BRANCH honest that its
  gate is ATMOSPHERE not heat. validate_ladder proves consistency
  (lining fireable-below + survive-here) and surfaces the real
  mullite-firing gap as warns. steelmaking rung LINING-gated (not
  hotter); unlocks bio-galvanized-steel.
- olivine: new 'mined-nonlocal' accessibility tier; Mg2SiO4 + 2CO2 ->
  2MgCO3 + SiO2 (exact); provisional REFUSING carbonation dataset.
- NEW manufacturing-tools tech tree (6 furnace nodes; deps = the
  bootstrapping; cross-refs to linings + unlocked materials; data deps
  carry the gaps). techtree 60 checks. API /api/pspp/ceramics/samples
  (+minTemp/local/carbonNegative) + /ceramics/ladder. 28 new checks.

## ✅ GEOPOLYMER->CERAMIC/GLASS TRANSITION + /pspp/ceramics FRONTEND (dev-mtt2-solgel 1bc0b60 + angular dev-gsp-structure-ui 0065b66)
- geopolymer_ceramic_transition.py: DATA-BACKED (Table 8.8, Perera &
  Trautman 2005 — measured porosity + XRD phases). Amorphous
  geopolymer to ~1000C, kalsilite crystallizes at 1000C, leucite at
  1200C, distorted kalsilite stable to 1400C (no melting); each stage
  cites its reaction_network crystallization rule. Glass branch >1400C
  = honest above-range refusal. + 2 geopolymer-derived CeramicSamples
  (leucite-ceramic, kalsilite-ceramic).
- sinter_stages: sample a firing at N checkpoints (partial firings) ->
  Theta/rho/grain per stage, each refusing in place uncalibrated. API
  POST /api/pspp/sinter/stages + GET /ceramics/geopolymer-transition.
- FRONTEND /pspp/ceramics (angular, theme-token compliant, ng build
  green): 4 tabs — Samples+precursors (temp-ladder bars, steelmaking
  filter, feedstock inspector) / Furnace ladder (rungs+warns) /
  Geopolymer->ceramic (porosity bars + XRD + glass refusal) / Sinter
  sampler (fire a schedule -> logTheta plot + per-stage density REFUSED
  without a curve + grain). Route + home nav card.
- Backend + frontend both rebuilt; backend live-verified. FRONTEND
  DEPLOY: was building at handoff — confirm `docker service update
  --image prf-frontend:staging --force polari-node_frontend --detach`
  ran + /pspp/ceramics loads (needs a browser pass by Dustin).

## ✅ CHARACTERIZATION (FTIR+XRD) + RESEARCH-TOOLS TREE + /pspp/research (dev-mtt2-solgel 2bb873f + angular 2bb... /research commit)
Dustin: add FTIR alongside XRD (better for our amorphous materials +
locally/safely doable), explain what/how in plain language, and add
RESEARCH TOOLS as a category with its OWN tech tree (goal accountability).
- characterization.py: XRD + FTIR as data, plain-language what/how +
  diagnostic signals. FTIR reads BONDS (works on amorphous gels; XRD
  only sees a halo) + the carbonate band VERIFIES olivine carbon-neg.
  simulated_ftir: Si-O-T main band shifts LOWER with more Al (approx,
  cited anchors; direction reliable, intensities+exact pos REFUSE).
  Honest safety: XRD radiation hazard/not-DIY, FTIR safe/ambitious.
  Provisional FTIR band-calibration dataset = the data ask.
- research_tools.py (ResearchTool): buildable instruments easiest-first
  — red-cabbage pH (trivial), visible spectrometer (DVD+webcam, FTIR's
  accessible cousin), colorimeter, Brix (sugar direct; mineral/health
  = CORRELATION only), EC/TDS (direct minerals), thermocouple logger
  (bridges to furnace ladder), turbidity, DIY microscope, open-source
  FTIR (high). Parts carry accessibility tiers.
- NEW research-tools tech tree (7th, parallel to manufacturing): 9
  nodes, FTIR deps visible-spectrometer, thermocouple cross-refs
  furnaces, FTIR carries the band data gap. techtree 61 checks.
- FRONTEND /pspp/research (3 tabs: methods explainer / FTIR sampler /
  research tools). API /characterization/methods + /ftir +
  /research-tools. 31 new backend checks. ng build green.
- DEPLOY: backend rolled; frontend building at handoff — confirm
  `docker service update --image prf-frontend:staging --force
  polari-node_frontend --detach` ran + /pspp/research loads.

## ✅ mtt-2 GLASS CORE: REFINEMENT WINDOWS + VISCOUS SINTERING (2026-07-27, dev-mtt2-solgel + angular dev-gsp-structure-ui)
Dustin confirmed BOTH halves ("a viscous sintering variant would be
useful so likely both"). Closes the "glass windows" item from the
remaining mtt-2 cores.
- glass_refinement.py: viscosity FIXED POINTS as data (log-η values
  are DEFINITIONS — 10^3 working / 10^6.6 Littleton / 10^12 anneal /
  10^13.5 strain / ~10^1 practical melting; soda-lime TEMPERATURES
  literature-approximate, Shelby 2005). fit_vft = EXACT closed-form
  VFT solve through 3 anchor points, ZERO free parameters, other
  points reported as honesty residuals (soda-lime lands A≈-3.0,
  B≈4990K, T0≈206C — classic territory; residuals ≤0.43 log units).
  viscosity_at refuses outside the fitted span. 4 banded
  condition-gate windows (fining <10^2 / forming 10^3..10^6.6 /
  annealing 10^12..10^13.5 / soda-lime devit-risk zone 560..1040C).
  process_map grades every gate at a probed temperature. 3 new
  datasets: viscosity points READY; devit TTT + glass-frit viscous
  master curve provisional-REFUSING (the data asks).
- viscous_sintering.py: the glass variant of Part B. Λ = ∫γ/(η(T)r)dt
  reduced viscous work (pure math over cited γ default 0.30 N/m
  Scholze 1991 — surfaced in assumptions, overridable — + the VFT fit
  + particle radius; schedule above the fitted span REFUSES, time
  below the rigid floor contributes 0, stated). Frenkel early stage
  y=(3/8)Λ valid to y=0.10 — past it the refusal names BOTH ways
  onward (digitize the frit master curve, or measure a closed-pore
  checkpoint); Mackenzie-Shuttleworth final stage runs ONLY from a
  MEASURED checkpoint (ρ≥0.9 + pore radius). plan_viscous_structure
  = amorphous-matrix + pore L2 rows, NO grain row (glass has no
  grains — the absence is the point). viscous_fire orchestrates,
  every piece honest in place. The mid-stage gap (Frenkel→closed
  pores) is a REAL model gap (Scherer is the cited bridge) — refused,
  not papered over.
- API: GET /api/pspp/glass/refinement (+?temperature=<C> process
  map; reads live dataset/window rows when edited), POST
  /api/pspp/sinter/viscous. /api/pspp/sinter/master-curves now lists
  BOTH kinds (log10Theta='solid-state', log10Lambda='viscous').
- Seeds concatenated in polariServer (GLASS_DIGITIZED_DATASETS +
  GLASS_THRESHOLD_WINDOWS, guarded import + stub names); drift guard
  15/15. techtree glass node: description BUILT + 3 data_deps
  (⚠ changed seed row: live volumes keep old text until row deletion
  + restart — cosmetic, same as the sol-gel node). techtree 61/61.
- FRONTEND: 5th tab "Glass (viscous)" on /pspp/ceramics — viscosity
  ladder bars, VFT fit + residuals line, temperature probe grading
  the gates (open/closed/warn chips, refusals rendered), viscous
  frit-firing form (Λ + ρ + MS + structure-plan note, refusals
  rendered). pspp.service +glassRefinement/+sinterViscous. ng build
  green (pre-existing warnings only). NO browser pass yet.
- 68 new checks (selftest_glass_refinement 32 + selftest_viscous_
  sintering 36, green host AND in-container); FULL pspp sweep green
  (32 suites). ✅ DEPLOYED + LIVE-VERIFIED same day: both images
  rebuilt, both services rolled, backend answered ~5 min post-roll —
  GET /glass/refinement 200 (points + exact VFT fit), POST
  /sinter/viscous Λ matches host to full precision, ?temperature=
  process map grades, frontend /pspp/ceramics 200. Browser pass on
  the new tab still pending (Dustin).
- DATA ASKS added: digitize a soda-lime devit TTT/growth-rate curve
  (turns the risk zone into hold-time budgets) + a glass-frit
  ρ vs log10 Λ master curve (unlocks mid/final-stage ρ without a
  measured checkpoint) + replace approximate fixed-point temps with
  a measured batch viscosity curve (upgrade, not unlock).

## NEXT (Dustin's stated order)
- Browser pass on /pspp/ceramics + /pspp/research (theming + tabs)
  — now ALSO the new Glass (viscous) tab.
- Remaining mtt-2 cores: CNT builder, silicon grades (glass DONE).
- Research-tool ideas suggested beyond Dustin's 3 (in case he wants
  more built): visible spectrometer, EC/TDS, colorimeter, thermocouple
  logger, turbidity, DIY microscope — all seeded already.
- sinter-5 (phase-field/kMC spatial microstructure) DEFERRED per plan
  — only if mean-field proves insufficient.
- DATA ASKS that turn refusals into predictions (each is now a tree
  data gap): alumina/zirconia densification master curve + fitted Q
  (unlocks sinter ρ); grain-growth (n,k0,Qg); sol-gel gel-time-vs-pH,
  29Si NMR Qn-vs-time, xerogel shrinkage-vs-T (also sinter calib),
  sodium-silicate morphology-vs-pH, ricehusk yield, lemon acid
  content; GLASS: soda-lime devit TTT curve + glass-frit ρ vs log10 Λ
  viscous master curve (+ optional measured batch viscosity curve).
- then variant layers: carbon-negative (geopolymer) → magnetic/
  conductive → thermal → structural → nanocomposite semiconductors.
- Open decisions for Dustin: sub-domain labels (statistical/discrete
  vs stochastic/particulate — seed-only, cheap to rename).
- ⚡ mlb LAZY-BOOT IS PREPPED (Dustin asked 2026-07-27): full wiring
  survey with file:line refs is now the PREP section atop
  MODULE_LAZY_BOOT_PLAN.md — boot order mapped (listen is strictly
  LAST today; health route is net-new; [DB-Save] prints unconditional
  in managedDB.py), STOMP + frontend module grid already exist,
  dependency-edge DRIFT flagged (FEATURE_REQUIRES vs
  polari-modules.json — pick one source in mlb-1). Precondition
  (swarm healthy, seed verified end-to-end) is MET via the glass
  deploy. Start with mlb-0 (POLARI_MODULES env in
  pol-services/compose/services/prf-backend.yml; proposed msci set in
  the PREP section — Dustin confirms the list) then mlb-1+2.

## Commit note
✅ DONE — see "COMMITS DONE" at top. Nothing is pushed; pushing is
Dustin's manual step (repos are PUBLIC).

---

# ⚡ PSPP HANDOFF — 2026-07-19 (READ THIS SECTION FIRST)

## ⚡⚡ UPDATE 2026-07-19 (later session): pspp-8 FULL + THRESHOLD WINDOWS BUILT
Handoff items 3+4 below are DONE (the geopolymer-simulation +
experiment-guidance capability). Framework branch
`dev-pspp-8-network-stepping` (off the pspp-5 head c651f39), NOT
merged/pushed — review gate stands. 340 checks green across 17 pspp
suites (4 new: threshold_windows 36, network_stepping 37,
cure_checkpoints 20, experiment_guidance 14); lazy-imports guard
15/15. Full detail: 2026-07-19 UPDATE block atop PSPP_MATERIALS_PLAN.
Short version:
- `threshold_windows.py` ThresholdReactionWindow: banded asymmetric
  grading (p.193 preferred bands + crack thresholds seeded, supersede
  the binary patent rows in merged grading) + condition-GATE rows
  (MR<1.20 Q0 threshold as data).
- `network_stepping.py` (pspp-8 full): solution_inventory from
  Table 5.6 (Q motifs = dynamic resources), applicable_rules
  (species/site/cation/gate — NEW cation_family + condition_windows_json
  on ReactionRule), stoichiometric step_once, kinetics-free
  reachable_frameworks (rule chains, hypothesis floors, competing
  branches). I5 stands — rates still refuse.
- `cure_checkpoints.py`: plan-first promotion of measured cure
  completions → TRANSFORMATIVE execution edge + MaterialState +
  reactionExtent StructureClaim; apply is the explicit knob.
- `experiment_guidance.py` + API: POST /api/pspp/guide (grade +
  pathways + cure + gap-list-as-experiment-plan), GET
  /api/pspp/pathways, POST /api/pspp/checkpoint.
- Verify: add these to the loop below —
  `threshold_windows network_stepping cure_checkpoints
  experiment_guidance`.
- NOT deployed to staging yet (backend rebuild needed for the new
  routes/class; seeds are idempotent-by-name — new rows only, no
  changed rows, so no volume surgery needed).
- Remaining NEXT (order): Dustin review · V3 visuals · pspp-11 wax
  half · pspp-6 split decision · new data asks (a K glass→solution
  table would light up K pathways; calibrated kinetics rows would
  unlock time-resolved stepping — both refuse with those exact asks
  today).

### ⚡⚡⚡ SAME DAY, 3rd pass: V3 VISUALS + pspp-11 WAX HALF BUILT (rough-
### functionality mode per Dustin: "foundational approach, debug later")
Backend (framework `dev-pspp-8-network-stepping`, +commit 70fbb4f):
- `wax_states.py` (pspp-11 wax half): every WaxFeedstockDefinition
  derives its 4-stage VIRTUAL state route (solid→softened→melt→
  superheated) from its own temperatures — zero writes, zero behavior
  change; GET /api/pspp/wax-states. selftest 10/10.
- `benchmark_cases.py` (V3): 3 Ch.8 BenchmarkCase rows + measured-vs-
  predicted overlay — windows + framework reachability genuinely
  predict (all 3 cases verdict MATCH incl. kalsilite via the NEW
  ortho-sialate-formation-k twin rule; phillipsite/leucite correctly
  absent — Q0 gate); strength/cure refuse per I5. GET
  /api/pspp/benchmarks + /{name}/overlay. selftest 12/12.
Frontend (angular `dev-pspp-v3-visuals` off dev-pspp-v-visual-
proofing, commit 1be9165, ng build green):
- /pspp/benchmarks (overlay wall, verdict chips), /pspp/guide
  (experiment-guide form; gap list = experiment plan), /pspp/states
  (state-DAG SVG viewer + wax routes dropdown; `pspp-state-dag` also
  registered as a mountable no-code component with [material]).
- Grader renders BANDED p.193 gauges (per-band colors) + edit links;
  network detail panel links to ReactionRule/ChemicalSpecies CRUDE
  pages — "editable on canvas" v1 = riding /class-main-page/:class.
- Service +pathways/guide/checkpoint/benchmarks/waxStates; routes +
  registry entries added.
⚠ ROUGH-BUILD CAVEATS (debug list): NOT deployed/live-verified (no
browser pass, no staging rebuild); benchmark JSON panels are raw
pretty-print; state-DAG layout is naive depth-columns; guide K-cation
pathway section refuses by design (Na-only Table 5.6); banded gauge
untested against live payload shapes. Total pspp checks now 362
across 19 suites (all green at commit time).

**⚠ PSPP PARKED HERE (Dustin 2026-07-19, moving topics). Architecture
is CLOSED for geopolymers — every remaining gap is data entry, an
engine behind a registered seam, or debug/polish. THE canonical
to-address list is PSPP_MATERIALS_PLAN.md §4b GAP REGISTER:
A1-A5 engine gaps (kinetics execution, gel-structure evolution,
degradation engines, strength-as-selectable-model, amount-weighted
reachability) · B1-B6 data asks (K solution table, kinetics
calibrations, Fig 5.22 re-shoot, Ch.6/7/CMC pages, setting-class
completions, p.191 cut-off text) · C1-C7 debug/polish (staging
deploy + browser pass first) · D1-D3 Dustin decisions (pspp-6 split,
spatial sims, UQ). Pick up with C1, then work the register.**

## What PSPP is
A **generic reactive-material engine** inside Polari (module `pspp`), built
2026-07-18/19 from a three-way design dialogue (Dustin ↔ Claude ↔ ChatGPT, which
ingested Davidovits *Geopolymer Chemistry and Applications* + a CMC book ToC).
Core thesis: a material is NOT a property sheet — it is an identity with a DAG of
durable states; processes are edges; chemistry is a library of species +
graph-rewrite rules (competing hypotheses, cited, kinetics-free until calibrated);
book figures live as DigitizedDataset rows that every chart derives from.
Swap the library (sol-gel, cement, oxidation…) — never redesign the engine.

## Read these, in order
1. `PSPP_MATERIALS_PLAN.md` (suite root) — architecture, 8 invariants (I1 canonical
   state, I2 declared ExecutionEffect, I5 no invented kinetics, I6 curves-as-data…),
   phase table with status.
2. `PSPP_VISUAL_PROOFING_PLAN.md` — the visuals/no-code slice (V1 done, V2 done,
   V3 = next).
3. `PSPP_DIGITIZED_DATASETS.json` (suite root) — the book transcription RECORD:
   20 qualitative claims, 3 benchmark cases, as-printed anomalies (Table 5.6 sums,
   H2O/Na2O 17.20-vs-15.45). Operational form = `modules/pspp/datasets_seed.py`.
4. `polari-rf-node/polari-framework/modules/pspp/` — 30 small files, one concern
   each; every `selftest_*.py` runs via
   `PYTHONPATH=modules python3 -m pspp.selftest_<name>` from polari-framework/
   (sitecustomize covers server entrypoints only, NOT host `-m` runs).
5. Memory: `pspp-materials.md` (+ MEMORY.md index) has the compressed history.

## Branch topology (NOT merged, NOT pushed — Dustin's review gate)
polari-framework, stacked off dev:
`dev-pspp-1-evidence-claims` → `2-material-states` → `3-structure-layer` →
`7-q-distribution` → `4-process-layer` → `v-visual-proofing` →
`5-scale-transfers` (head also carries pspp-9 + pspp-11 commits: c651f39).
polari-platform-angular: `dev-pspp-v-visual-proofing` (1 commit, ng build green).
⚠ Branch names lag content after pspp-4 — commits landed on the current head
branch rather than new ones per phase. Verify with `git log --oneline dev..HEAD`.

## What is DONE (all selftested, 233 checks green total)
- Evidence/claims/EvidenceMethod vocabulary; DigitizedDataset + ONE generic
  interpolation engine (bands, UNSUPPORTED extrapolation refusals).
- 13 datasets (Ch.5 tables/figures incl. Figs 5.4/5.5 Q-curves, Fig 5.20/5.21/5.22,
  Tables 5.4/5.5/5.6/5.8; Ch.8 curing kinetics trio + Table 8.8 thermal phases).
- MaterialState DAG (implicit-virtual canonical `#as-defined`, sync-on-need, NO
  boot backfill); ProcessingStage rows; `state_resolution` = THE name→state path.
- Structure layer (5-descriptor mandatory core incl. reactionExtent∈[0,1]; L2
  multi-domain; `require_descriptors` gate).
- composition_math (book-pinned MR/WR 1.032/1.568, Baumé, oxide ratios incl.
  H2O/Al2O3); reaction_windows (8 patent rows, Tables A/C; p.193 graded bands
  recorded in notes — asymmetric variant NOT yet modeled).
- Process layer (ExecutionEffect I2, heating deposition models, thermal-window
  admissibility) + reaction network as data (17 rules: Na two-phase Fig 8.21
  surface→albite / interior→nepheline, phillipsite 6a/6b, K kalsilite/leucite
  analogues; site_constraint; competing hypotheses).
- q_distribution engines; progress_engine v1 (measured curves only, refusals name
  the dataset to enter); scale transfers (wax retrofit rows cite live msim models);
  exposure + performance scenarios v1 (elastic-bounds via mixture_bounds,
  water-transport via descriptors→Darcy pointer); CMC library through EXISTING
  classes (the zero-schema-change generality proof).
- `/api/pspp/*` (6 endpoints) + Angular `/pspp` pages (proofing chart wall from
  rows via Observable Plot, reaction-network SVG where styling=evidence, grader,
  progress) + no-code registry + seeded published page (module_id `pspp`).

## Verify before building anything
```
cd polari-rf-node/polari-framework
for t in evidence_claims digitized_datasets material_states material_structure \
  composition_math reaction_windows q_distribution material_processes \
  reaction_network pspp_views scale_transfers performance_scenarios cmc_library; \
  do PYTHONPATH=modules python3 -m pspp.selftest_$t | tail -1; done
cd ../polari-platform-angular && npm run build   # green, pre-existing warnings only
```
Live proofing: bring the stack up (`pol node up --env staging`), open
`/pspp/proofing` with the book — charts should match Figs 5.4/5.5, 8.18, 8.20,
5.20, 5.22, Tables 5.4/5.5/8.8.

## NEXT work, in priority order
1. **Dustin's review of the stack** — nothing merges until then.
2. **V3 visuals**: benchmark measured-vs-predicted overlays (3 benchmark cases in
   the JSON → rows), state-DAG + transfers view on the material detail page,
   no-code editing of rules/windows on the canvas.
3. **Threshold/asymmetric ReactionWindow variant** (p.193 preferred bands 1.3-1.52
   / 4.0-4.2 + crack thresholds <1.1 / <3.7 — currently notes only).
4. **pspp-8 full**: reaction-network stepping (rules consume/produce species,
   Q-distribution as dynamic resource), promote cure checkpoints to MaterialState
   rows via TRANSFORMATIVE executions.
5. **pspp-11 wax half**: map waxprint feedstocks onto states (wax ProcessingStages
   already seeded), zero behavior change.
6. **pspp-6 remainder**: geopolymer module glue (`modules/geopolymer/` was folded
   into `modules/pspp` — decide whether to split per module-projects idiom).
7. Data asks (only if Dustin photographs more): Ch.6 Fig 6.6 molecule types,
   Ch.7 kaolinite steps 1-7 pages, CMC chapter equations.

## Gotchas
- Never rescale as-printed book anomalies (Table 5.6 sums 92/110; H2O discrepancy).
- `pspp` imports as TOP-LEVEL package (modules/ is an import root).
- Seeds are idempotent-by-name: changed seed content needs row deletion + restart
  on existing volumes (standing gotcha).
- All 8 repos are PUBLIC — book data enters as cited transcriptions only, never
  scanned pages.
- Keep every capability = knob + evidence-bearing refusal; absence is honest data.

---

# Next-agent handoff — 2026-07-16 (THE BIG DAY: ncg-0..7 + DMV/scorecard epistemics stack)

## 🎯🎯 CURRENT STATE (Dustin 2026-07-19): MODULE PROJECTS DONE + EVERYTHING ON dev
**GRACEFUL_MOBILITY_PLAN.md is SHELVED for now (Dustin's call) — do
NOT start gm-1..6 until Dustin re-opens it.**
Module Projects mp-2+mp-3+mp-4 are EXECUTED, not just prepped —
Dustin ran the module-projects/ batches himself:
- ALL 22 feature modules live in modules/ (waves 1-6, pure renames,
  register paths updated) AND each is split to its own PUBLIC repo
  https://github.com/dausume/polari-module-<name> — remote main ==
  local `git subtree split` hash VERIFIED for all 22. In-tree copies
  stay AUTHORITATIVE; `pol modules publish <m>` re-pushes.
- Staging rebuilt on the full new layout: ~65 suites green; 3 reds
  triaged (aquaponics 12/13 = known pre-existing; testing double-
  import via the modules. namespace prefix = fixed; resources
  topology-character drift = re-pinned to tanks).
- **EVERYTHING IS MERGED TO dev in every repo** (2026-07-19, at
  Dustin's direction): framework dev = 3c1a28c (tt-1..15 backend +
  mp-1..4 + fixes, 29 commits ff), angular dev = aaa56f6 (tt-2..15
  UI, 12 commits ff), cli dev = c3f9892 (tt-12 apps + mp rails),
  rf-node dev carries both pointers (d6d870a), suite dev carries
  the batch scripts + plans. The old review-gate branch stacks are
  now redundant with dev (safe to delete after push). NOT pushed to
  origin — push is Dustin's manual step, repos are PUBLIC.
- Follow-ups parked for later phases: in-tree retirement of split
  modules (makes get/drop the real workflow), db_backend/rows
  reconcile, twin+dask stacks still DOWN, staging-nip parity diff.

## ⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡ 2026-07-18 (earlier): mp-2/mp-3 PREP + module-projects/ BATCHES — BUILT+LIVE
Dustin's ask: do all Module-Projects preparation an agent can, then
hand over SMALL BATCHED COMMAND FILES for the git/GitHub/deploy steps
only a human should run. Both delivered — read the STATUS block atop
**MODULE_PROJECTS_PLAN.md** (full detail) and
**`module-projects/README.md`** (the batch order Dustin runs).
Short version:
- **mp-3 lazy core BUILT+LIVE**: polariServer's 113 feature-module
  imports → 30 guarded blocks (absent code stubs SEED_*→[]/None +
  honest [ModuleLoading] boot line; downloaded-but-broken still
  raises); feature endpoints gate on feature_available; /modules +
  detail + Polari-Apps plans answer 'not downloaded — pol modules
  get <m>'. Seam: moduleService/module_loading.py. Drift guard
  selftest_lazy_imports 15/15 (ast-pins imports↔stubs). PROOF:
  in-container import of polariApiServer.polariServer with
  modules/biomining hidden succeeds.
- **Register FILLED**: all 20 feature modules + waves 1-6 +
  requires (cross-import survey) + required_by_core (xr, resources).
- **mp-2 rails BUILT**: pol modules publish (subtree split+push,
  prints its git) / register (--vendor) / get-drop refusals
  (requires + required_by_core) / sizes in registry.
- **module-projects/ batches (Dustin runs)**: 00-preflight →
  01-split-already-moved → 10-wave.sh <1..6> → 20-split-module.sh →
  90-verify-all.sh. env-file + pol-proxy gotchas baked in. gh is NOT
  authed on this machine (gh auth login is step one).
- **Two pre-existing reds found+fixed while verifying**: (1)
  SimulationDefinition.xr_requirement was assigned but never a
  parameter — EVERY SimulationDefinition CREATE raised NameError
  (5 seed sims failed every boot since the zones work); (2)
  managedFiles.openFile ignored self.Path — 304 'outside of path
  scope' boot lines, now 0.
- Branches: framework `dev-mp-3-lazy-core` (off
  dev-mp-1-module-projects), cli `dev-mp-2-publish-cli` (off
  dev-mp-1-modules-cli). NOT on dev, NOT pushed (review gate).
  GRACEFUL_MOBILITY_PLAN gm-1..6 remains queued after this.

## 🎯 NEXT AGENT STARTS HERE (Dustin 2026-07-18, end of session)
**⚠️ SUPERSEDED by the 2026-07-19 block above: item 1 (graceful
mobility) is SHELVED; item 2 (module projects) is DONE.**
Module moves between containers are smooth and CONFIRMED by Dustin.
The queued build, in order:
1. **GRACEFUL_MOBILITY_PLAN.md** (NEW — read end-to-end): move
   ENGINES / INFRASTRUCTURE (keydb, minio, mariadb, owned-sqlite
   instances) / AUTH (keycloak) between devices with warm-swap
   discipline (start new → ready-gate → swap refs/ports → quiesce,
   no in-flight actions, no data loss → retire old). gm-1 engine
   blue-green (swarm start-first) → gm-2 quiesce seam +
   MoveOperation receipts → gm-3 keydb/minio → gm-4 keycloak →
   gm-5 mariadb/sqlite → gm-6 kind-aware UI flows. Every phase ends
   with the ping/selftest verification paint.
2. **MODULE_PROJECTS_PLAN.md mp-2..mp-5** (EXECUTION APPENDIX added):
   subtree-split each moved module into polari-module-<name> repos
   (PUBLIC — no secrets), fill registry repo fields (get/drop rails
   go live automatically), `pol modules publish`, mp-3 lazy
   seed/endpoint imports so the CORE boots without downstream, then
   the mp-4 migration waves in the listed leaf-first order.
Both plans build on live, verified substrate — sixteen tt/mp phases
deployed on staging today, all on the review branch stacks below,
NOTHING on dev, NOTHING pushed (Dustin's review gate stands).

## ⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡ 2026-07-18: mp-1 MODULE PROJECTS SLICE 1 — LIVE
**Read MODULE_PROJECTS_PLAN.md** (new, suite root) — Dustin's
direction: the project is getting enormous; keep the basis, make
downstream modules their own downloadable sub-projects; feature
modules outside modules/ was a mistake — move them iteratively.
Slice 1 BUILT+LIVE:
- modules/ is a second IMPORT ROOT (server insert + sitecustomize +
  PYTHONPATH=/app/modules in the backend image) — moved modules keep
  their import names, zero import rewrites.
- FIRST MOVES: biomining + microalgae → modules/ (git mv, history
  kept). Live: import from /app/modules, 44 rows seeded, pol modules
  selftest biomining 33/33 from the new home.
- REGISTER: modules/polari-modules.json — kind official|vendor|self,
  repo ('' until mp-2 split), downloaded flag RE-DERIVED from the
  filesystem every read. moduleService/module_registry.py; user
  Create-Module flow auto-registers kind 'self'; GET
  /modules/registry; `pol modules registry` prints it; `pol modules
  get|drop` = the git rails (honest refusal until repos split in
  mp-2; drop refuses on uncommitted work).
- All discovery dual-root: selftest discovery, pip-suggest
  exclusions, /modules list + drill-in, pol modules list/selftest.
- KNOWN COSMETIC: 'File Instance ... outside of path scope' log
  lines for modules-dir classes (source-file tracker only knows the
  framework root — fix alongside mp-3).
NEXT: mp-2 repo split (per-module git repos + registry repo fields +
real get/drop/publish), mp-3 lazy seed/endpoint imports so the CORE
boots without downstream. Branches: framework
`dev-mp-1-module-projects`, cli `dev-mp-1-modules-cli` (stack tops).

## ⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡ 2026-07-18: tt-15 MOVE-BUTTON FIX — LIVE
Dustin's bug ('move aquaponics to prf-b — nothing happens'): the
drawer's move only worked on /topology; /testing + Module Management
embed the same drawer with no listener → silent no-op. Fixed:
topology-graph-view EXECUTES the move itself (inline outcome in the
drawer, self-refetch so the circle moves immediately, (moved) event
for hosts — wired on all three pages). Live round trip verified:
aquaponics → prf-b (ghost at prf-a) → back to prf-a (ghost at
prf-b, left visible). Drawer states runtime semantics honestly:
same-image moves need NO container replacement (both backends carry
the code; routing follows rows instantly).
**ROADMAP (Dustin's ask, NOT built): graceful blue-green module
handover** — for engine relocations / module-gated builds: start the
new container, warm it, swap references/ports the moment it's ready,
quiesce in-flight actions on the old one (no data loss/lag), then
retire it. Candidate tt-16; touches swarm deploy + provider routing
+ a drain seam in polariServer.
Branch: angular `dev-tt-15-move-fix` (stack top).

## ⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡ 2026-07-18: tt-14 TOPOLOGY COHERENCE + VISIBILITY — LIVE
Dustin's semantic corrections (screenshots) encoded end-to-end:
- **Placement coherence**: only POLARI instances receive modules
  (workers/engines ARE Polari — a Polari wrapped the engine from the
  beginning); psc + infra + AUTH containers are non-adaptive
  integrated apps — placement_check refuses them in plan_move AND
  /assign; engine capabilities (msci fem/dft,
  ENGINE_CAPABILITY_MODULES) restrict to engine/worker hosts; the
  move picker only OFFERS coherent targets (device moves = engine
  modules only; sim machine rows excluded; live-verified: move to
  psc-a refused with the honest sentence).
- **Visibility**: appKind category colors (polari indigo /
  integrated-app teal / auth purple / infra brown) + per-container
  service DOTS (keycloak purple, mariadb/keydb amber, frontend vs
  backend distinguishable) + legend; NAMED storage identity per
  Polari card ('sqlite-<name> (owned)' vs 'pol-mariadb (shared)');
  /modules/{id} + module-details show WHICH database each class's
  rows live on. FOUND LIVE: prf-a's row claimed sqlite while the
  backend runs mariadb:polari_objects — corrected to combo; the
  other instance rows' db_backend may drift the same way
  (observation-reconcile is a follow-up).
- **Machine pings fixed**: isle-core now pings GREEN (node-addressed
  http://192.168.0.25:9500/capability); lightweight row corrected to
  swarm worker + honestly 'unpingable — nothing serving' instead of
  a scary 404; sim rows marked synthetic.
- **UI fixes**: light-mode white-on-white text swept to explicit
  dark colors (topology/testing/tech-tree/apps); wrapped-label
  packing pads for WIDTH so labels can't collide; machines endpoint
  500 fixed (junk roles_json).
DEFERRED (Dustin's asks, planned not built): sqlite dive-in
(per-file object inventory across containers), fe↔be login
capability matrix, cross-instance per-class DB map, class ownership
across modules (transient coherence of classes).
Branches: framework `dev-tt-14-coherence`, angular
`dev-tt-14-coherence-ui` (stack tops). selftests 45+19+52
in-container.

## ⚡⚡⚡⚡⚡⚡⚡⚡⚡ 2026-07-18: tt-13 DYNAMIC TOPOLOGY MOVES — LIVE
Click any module circle on /topology → drawer shows where it lives
(container + host + state) + a Move picker. plan_move knows MOVING
AN ENGINE ≠ MOVING A MODULE: container target = module reassignment
(former enabled placements become 'transient' GHOSTS — new
ASSIGNMENT_STATES entry, dashed+faded in the graph, EXCLUDED from
resolution/tests, one click back); device target = engine relocation
(the single-purpose provider instance re-pins machine+constraint;
stack redeploy stays the human pol command, returned as text);
device target for a multi-home module refused honestly. POST
/api/topology/move ({plan:true} previews). PERSISTENCE PROVEN LIVE:
moved mathshapes prf-a→prf-b (ghost left at prf-a — VISIBLE NOW on
/topology for review), restarted prf-backend, rows came back exactly
(and engines stayed pinned to isle-core). Engine-relocation
correctly plans engines isle-core→lightweight (plan-only, not
executed). selftests 33/33+19/19+52/52 in-container. Branches:
framework `dev-tt-13-dynamic-moves`, angular `dev-tt-13-moves-ui`
(stack tops).

## ⚡⚡⚡⚡⚡⚡⚡⚡ 2026-07-18: tt-12 POLARI-APPS + ISLE-CORE SWARM SPLIT — LIVE
Two things, both live on staging:
- **Swarm split across isle-core + staging-a (Dustin's ask).** All
  stacks brought down; isle-core (dustin-etts-mesh-core — was
  ALREADY a swarm node) labeled polari.machine=isle-core; the 4.5GB
  prf-msci-engines:staging image shipped lightweight→isle-core
  (gzip ssh pipe, 3m51s); InstanceDefinition 'engines' repointed
  (machine_name=isle-core + constraint) via the topology API;
  redeployed via POL_STACK_CONSTRAINTS + pol swarm deploy (NOTE:
  bare `pol swarm deploy engines` does NOT read stacks.yml — the
  constraint env comes from pol topology apply / pol allocate
  paths). RESULT: the cross-dependent pair is SPLIT between hosts —
  multiscale@prf-a (staging-a) → fem/dft on isle-core, ping-green
  through the routing mesh at :9500 (http, plaintext notated).
  Suite back up on staging-a; twin + dask stacks left DOWN.
  ⚠️ `pol topology render` shows a PRE-EXISTING suite-bundle PARITY
  DIFF on docker-compose.staging-nip.yml — check with Dustin.
- **tt-12 Polari-Apps.** polariapps/ + /api/apps + `pol apps` +
  /apps page: an app = a module configuration for a use-case;
  deployment is PLAN-FIRST + EXPORTABLE (polari-app-package JSON;
  `pol apps deploy <file.json>`), apply writes ModuleAssignment
  rows ONLY. Seeded: wax-print-shop (wax sims + auger shapes via
  mathshapes), judicial-lean, dmv-policy-analysis. LIVE round trip
  proven: plan 33% → export → deploy file → rows written
  (waxprint/mathshapes/waxsupply/supplychain → prf-a) → plan 100%.
  selftest_apps 20/20. Branches: framework `dev-tt-12-apps`, cli
  `dev-tt-12-apps-cli`, angular `dev-tt-12-apps-ui` (stack tops).

## ⚡⚡⚡⚡⚡⚡⚡ 2026-07-18: tt-11 TESTING OVER TOPOLOGY — BUILT+LIVE
Dustin: tie testing into topology so the graph visualizes test
progress. Built + deployed:
- **Backend** topology/topology_testing{,_api}.py: TopologyTestRun
  (subprocess selftest runs, parsed X/Y tallies, output tails) +
  IntegrationPing (FOUNDATIONAL connectivity only — machines via
  system_info_url, dep edges via top-7 provider routing = the real
  cross-node check, config-artifact connections honestly
  'static-artifact') — protocol + secured/how notated on every row.
  GET /api/topology/testing + POST run {module|all} + POST ping.
  selftest_testing 19/19. Module states: pass/fail/never-run/
  no-suites; partial runs are NOT green; instance/host rollups.
- **/testing page** (route+nav): wraps topology-graph-view with
  [testing] — modules/hosts red on fail, green on all-pass; pinged
  edges recolor + '· http ⚠'/'· https 🔒' labels; run/ping controls +
  suites/links tables. LIVE-verified: topology suites 3/3 pass
  in-container via the API; engines dep-edges ping OK cross-node
  (http, plaintext notated); isle-core/lightweight system-info URLs
  honestly FAIL 404 (real finding for Dustin); 18 links recorded.
- **Layout (Dustin review feedback)**: connector limit TRIPLED
  (gutter cap 6× largest circle diameter, gaps rewidened);
  module/engine labels WORD-WRAP (≤3 lines) with packing padded so
  labels never collide.
- **Module Management fix (Dustin's screenshots — 'only two modules
  configurable')**: GET /modules now lists ALL 39 modules (37
  boundary ones with classes/rows + boundary flag → card shows
  'loaded in-process · placement → Topology' instead of a dead
  toggle). Also KILLED the bogus '24 missing packages: pip install
  aquaponics ... topology' suggestion (framework dirs excluded from
  installable candidates; dependency selftest 14/14).
Branches (stack tops): framework `dev-tt-11-testing`, angular
`dev-tt-11-testing-ui`.

## ⚡⚡⚡⚡⚡⚡ 2026-07-18 (later): tt-9 CROSS-TREE ZOOM + tt-10 MODULE DRILL-IN — BUILT+LIVE
Dustin's follow-ups, all deployed to staging:
- **tt-9 cross-tree refs (NO edges)**: TechNode.cross_refs_json →
  dotted '↗ node · tree' chips + drawer rows naming the ref's HOME
  TREE; click = switch tree + center/select the target (focusNode/
  zoomRef seam). 18 refs seeded both directions across electronics ↔
  raw-supply-chain (+economy→3d-printing); boot backfill stamped
  pre-tt-9 rows (live: filled 18). Dangling refs = warn findings,
  red-dotted unclickable chips.
- **topology parity + layout (Dustin's connector complaint)**: dep
  connectors now run module circle → OWN CONTAINER BORDER → partner
  border → circle (modules stay physically inside; only the
  border-to-border run is external); inter-host gutter capped at 2×
  the largest module circle's diameter; instances barycenter-ordered
  + hosts vertically shifted to align with partners. Clicking a
  dashed transient copy zooms to the instance holding the primary.
- **tt-10 drill-in**: GET /modules/{id} now serves EVERY framework
  directory module (boundary fallback — registry only knew 2 legacy
  modules) with pages / real apiRoutes (text-scanned add_route, both
  spellings) / selftests + per-class row counts. module-details page
  gains a 'Navigate' tab (Pages/Data/Functionality/Selftests);
  topology drawer module chips + tech-tree theory ✓-chips (moduleId
  from PolariModule.source_ref) deep-link there. Live-verified:
  aquaponics 19cls/78rows/36routes, topology, techtree, waxprint.
Branches (stack tops): framework `dev-tt-10-module-map` ←
`dev-tt-9-cross-refs` ← `dev-tt-8-domain-trees`; angular
`dev-tt-10-drillin-ui` ← `dev-tt-9-zoomto` ← `dev-tt-8-domains-ui`.
selftest_techtree 50/50 in-container; builds green; pages 200.

## ⚡⚡⚡⚡⚡ 2026-07-18: tt-8 DOMAIN TREES — Dustin's revision, BUILT+LIVE
The single tech tree split into THREE DOMAIN TREES whose combination
is the OSEB (see the 2026-07-18 STATUS block atop
TECH_TREE_TOPOLOGY_PLAN.md for the full node list + numbers):
electronics 'Electronics / Microelectronics' (24 nodes; PVD is now
ITS OWN roadmap — OSPVD_ROADMAP.md — needing vacuum-pump +
piezoelectric-sputter prerequisites; expandable dielectrics →
Precision Laser Apparatus required by BOTH real-BLCNC and first-class
LASiS; CNT production via CO reduction; silicon refinement
grade-scale), raw-supply-chain 'Raw Supply Chain' (15 shells incl.
nanoparticle/CNT/p-doped/n-doped/silicon-grade/sol-gel/geopolymer/
wax/wax-nanocomposite supply streams), os-economy-politics 'Open
Source Economy & Politics' (4 shells: judicial, policy tracking,
business-logic models, micro-business tailoring). GET
/api/techtree/baseline + baseline strip on /tech-tree = the combined
OSEB (LIVE: 54.5%; electronics 51.7 / economy 75 / supply 36.7).
Legacy 'oseb' rows retired at boot (live: 78 rows removed, 14 hints
remapped; idempotent). 46/46 selftest in-container; deployed to
staging; pages 200. Branches: framework `dev-tt-8-domain-trees`,
angular `dev-tt-8-domains-ui` (both HEAD of their stacks).

## ⚡⚡⚡⚡ 2026-07-17: TOPOLOGY REVAMP + TECH TREE — tt-1..tt-7 ALL BUILT
Read the STATUS block atop **TECH_TREE_TOPOLOGY_PLAN.md** (branches,
defaults taken, live-verify detail) + memory [[topology-techtree-build]].
Short version:
- **tt-1** module graph: reverse edges/degrees, consumer/provider/
  hybrid/independent/data-only classification, STABLE transient/primary
  designation on ModuleDependencyEdge; PolariModule gained data_only +
  tech_node_ref; boundary_graph bidirectional; GET
  /api/topology/module-graph (26/26).
- **tt-2** renderer revamp: module CIRCLES packed in instance rects in
  HOST rects (toggle), deps nested in circles (depth 2), dashed =
  transient copy, connections = thin colored lines, dep edges anchor
  to circles. Pure geometry in topology-graph-layout.ts.
- **tt-3** techtree/ module: 5 data classes, DERIVED completion rollup
  (first-cut done-tests, evidence-bearing gaps), /api/techtree/* (37/37
  incl. tt-5/6 suites).
- **tt-4** /tech-tree page: segment-banded technology rects (blue/red/
  yellow/purple, only-if-populated, weight-sized, completion-filled),
  completion rings, dashed transient edges + dep chips, gaps table.
- **tt-5** OSEB seed: 19 nodes (13 domains + OS-PVD + BLCNC/PVD P1-P5
  per BLCNC_PVD_ROADMAP), theory wired to 14 genuinely-installed
  PolariModule rows; unbuilt 'blcnc'/'ospvd' refs stay honest gaps.
  **Baseline computes 62.7%.**
- **tt-6** RealArtifact/BusinessModelDefinition/BusinessOutcome/
  PolicyDefinition + honest examples filling all 4 segments on
  oseb/3d-printing (25% — unproven printer, unevidenced model+policy).
- **tt-7** Module Management embeds the circle/nesting renderer;
  /tech-tree gains per-org '+ new tree' creation.
**LIVE on staging NOW** (prf-backend+frontend rebuilt via `pol suite
build`/`up`, cold-seed + pol-proxy-restart gotchas both hit and
handled): /topology, /tech-tree, module-graph + techtree APIs all 200.
⚠️ REVIEW GATE: Dustin's browser pass pending (esp. tt-2 circles +
tt-4 bands). NOT merged to dev, NOT pushed — branch stacks in plan
STATUS block. NEXT after review: BLCNC_PVD_ROADMAP.md P1 (the blcnc
module — its TechNode + theory assignment already wait in the seed).

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
