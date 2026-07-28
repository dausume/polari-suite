# Odoo Integration — business sims + real business ops backbone

**Status: PLANNING ONLY (Dustin 2026-07-27) — the NEXT AGENT runs
this.** Dustin: "make a plan for integrating odoo into the suite and
making it something we can use similar to our other external assets;
it is going to be the backbone of both business simulations and real
business ops."

Everything here follows the house rules: every capability = knob +
evidence-bearing suggestion (never auto-apply); every capability maps
to object-tree rows; honest refusals where a thing is not built;
plan-first for anything that writes to REAL business data.

## Why Odoo, and the dual mandate

Odoo (Community edition, LGPL) is a full ERP: partners/CRM, products,
inventory, purchasing, sales, manufacturing (MRP/BOMs), projects,
accounting. The suite gets it for TWO distinct jobs that must never
blur:

1. **Business simulations** — the economy tree
   (`TREE_ECONOMY = 'os-economy-politics'`, techtree_seed.py:45) has
   BusinessModelDefinition / BusinessOutcome / RealArtifact /
   PolicyDefinition rows but NO transactional engine behind them.
   Odoo becomes that engine: a sim scenario seeds a THROWAWAY Odoo
   database with products/BOMs/orders/prices, the simulation drives
   transactions through Odoo's real business logic (stock moves,
   MRP, invoicing), and the outcomes flow back as BusinessOutcome
   rows + economy-tree segment evidence. The OSEB thesis (tech tree
   as Open Source Economic Baseline) finally gets numbers.
2. **Real business ops** — actual operations (selling printed parts,
   materials, kits; purchasing feedstocks; accounting). This
   instance is PRODUCTION business data: read-mostly from Polari,
   writes only through explicit, typed-confirmation flows (the gm-6
   discipline), with backup receipts before anything structural.

**The hard invariant: sim and ops are SEPARATE Odoo databases (same
server is fine — Odoo is natively multi-db) and every Polari-side
config row carries `mode: simulation | operations`. Nothing that
holds an operations handle may be driven by a simulation, ever.**

## Ground truth to build on (all live today)

- **Service integration pattern**: annotated per-env service defs in
  `pol-services/compose/services/*.yml` (jinja-start/end blocks,
  dev|staging|prod tiers — `pol-keycloak.yml` and `pol-mariadb.yml`
  are the closest templates); rendered by `pol build render` with
  byte-parity checks; swarm path via `pol swarm deploy` →
  `docker compose config | stackify.py` (constraints via
  POL_STACK_CONSTRAINTS). Root-owned-volume gotcha applies (README
  §7): any writable bind mount runs as `${UID:-1000}:${GID:-1000}`
  or chowns on exit.
- **Proxy**: nginx variable-upstream pattern (swarm DNS, lazy
  upstreams — services can boot after nginx). New subdomain =
  `odoo.<BASE_DOMAIN>` (+ `odoo-sim.` if we split servers later).
- **SSO**: Keycloak realm 'Polari' with OIDC clients; gm-4 proved
  server moves keep tokens valid (issuer hostname stable). ⚠ The
  credential-drift class (2026-07-27 outage): generated DB passwords
  drift across stack re-renders while DB volumes keep initialized
  passwords — Odoo's postgres gets the SAME trap unless creds come
  from a STABLE generated file (or the docker-secrets refinement
  lands first). Document the rescue procedure in the service README.
- **Topology + mobility**: InstanceDefinition / ServiceConnection
  (topology_links.py:22) rows; MoveOperation receipts + the gm mover
  set. Odoo lands as TWO movable subjects: `odoo` (server-only,
  gm-4 shape) and `odoo-postgres` (gm-5 database-move shape:
  writers-drain = the odoo service, pg_dump receipt, staged volume
  copy); filestore volume rides the minio-move (staged copy) shape.
  Add both to MOVE_SUBJECTS + the `pol swarm relocate` catalog.
- **Lazy boot / module gating**: the framework-side connector is a
  feature module (`odooconnect`) — registers in polari-modules.json,
  gated by POLARI_MODULES, admitted by the mlb worker with timing
  history like every other module.
- **External-API seam**: Odoo's JSON-RPC (`/jsonrpc`) — Python
  stdlib is enough (no client dependency); the same honest-refusal
  client pattern as MSCI_ENGINES_URL delegation (capability degrades
  honestly when the worker is down; provider_registry probe caching
  + reprobe endpoint).
- **Existing classes to bind to** (no schema invention needed for
  v1): SupplyNode/SupplyFlow/SupplyChainDefinition
  (modules/supplychain/chain_basis.py:37/71/102),
  MaterialsScienceMaterial + CeramicSample + WaxFeedstockDefinition
  (products), FoodItem/NutrientContent (nutrition ops),
  BusinessModelDefinition/BusinessOutcome/RealArtifact (economy
  tree), ScoreTerm/ContextualizedValue (cost/score contexts),
  ModuleResourceProfile (res-2 sizing).

## Architecture

```
                    ┌────────────────────────────┐
 pol odoo up  ───►  │  odoo (service, :8069)     │◄── odoo.<domain> via prf-proxy
                    │  ├─ db: odoo_sim     ◄──── sim scenarios (free writes)
                    │  └─ db: odoo_ops     ◄──── REAL ops (guarded writes)
                    │  odoo-postgres (:5432)     │   volumes: odoo-db-data,
                    │  filestore volume          │            odoo-filestore
                    └────────────▲───────────────┘
                                 │ JSON-RPC (external API)
                    ┌────────────┴───────────────┐
                    │ framework module odooconnect│
                    │  OdooInstanceConfig rows    │  mode=simulation|operations
                    │  OdooModelBinding rows      │  odoo model ↔ Polari class
                    │  sync engine (pull free /   │  push = knob + typed confirm
                    │  push gated)                │  provenance on every row
                    │  /api/odoo/*                │
                    └────────────────────────────┘
```

Key decisions baked in (od-0 confirms them):
- **Odoo Community 18** (LGPL; accounting basics included — Enterprise
  features like advanced reports are an honest gap, listed not hidden).
- **PostgreSQL 16** — the suite's FIRST postgres; it does NOT reuse
  MariaDB (Odoo requires postgres). One more stateful service, fully
  covered by the mover catalog from day one.
- **One Odoo server, two databases** (odoo_sim, odoo_ops) to start;
  splitting to two servers later is exactly one gm server-move +
  config row edit (that is the point of the mobility work).
- **Auth**: Keycloak OIDC for HUMANS (odoo `auth_oidc` community
  module); a dedicated API user + api-key for the connector (least
  privilege: sim user has full rights on odoo_sim only; ops API user
  starts READ-ONLY on odoo_ops).

## Phases (od-N) — each lands with its own branch off dev + selftests

### od-0 — Decisions (Dustin ANSWERED 2026-07-27)
- **Simulations FIRST; real ops much later** — od-5 is the payoff
  target, od-6 waits until the sim loop has proven out.
- **Host = econ-core** (the business-ops/economics core, renamed
  from 'lightweight' — N95 4-core / 7.5G, headless-safe). Record a
  ModuleResourceProfile once measured.
- Still open (confirm at build time): Community 18 vs pin 17;
  single-server/two-db stands as recommended.

### od-1 — Service bring-up (the external-asset baseline)
**✅ BUILT + VERIFIED 2026-07-27** (branches `dev-od-1-odoo-bringup` in
suite/cli/framework): odoo 18.0-20260723 + postgres 16.14 pinned, both
behind compose profile `odoo` (suite up never starts them); `pol odoo`
CLI; proxy routes use VARIABLE proxy_pass (static upstream would kill
nginx boot while the profile is down); topology rows + render shapes +
52/52 topology selftests; verified live on pol-core: healthy in ~30s,
both DBs, login forms, list_db refusals, 3.3M pg_dump receipts.
Deltas from the letter of the plan: healthcheck uses python3-urllib
(curl not guaranteed in the image); admin password set at init-db and
printed once; econ-core placement = run `pol odoo up` there after code
sync (repos not pushed yet).
- `pol-services/compose/services/odoo.yml` + `odoo-postgres.yml`
  (annotated, 3 tiers) — model on pol-keycloak/pol-mariadb; UID
  pattern; healthchecks REQUIRED from day one (gm-4 lesson: an
  ungated slow-boot service makes blue-green a lie — odoo boots in
  ~10-30s but gate it anyway: `curl -f localhost:8069/web/health`);
  postgres healthcheck `pg_isready`. Volumes: `odoo-db-data`,
  `odoo-filestore`. Credentials from a generated env file that is
  STABLE across renders (document the drift trap + rescue).
- Proxy: `odoo.` subdomain routes (websocket/longpolling path too:
  `/websocket` on 8072 if workers>0).
- `polari-cli/scripts/odoo.sh`: `pol odoo up|down|status|logs|
  init-db <sim|ops>|backup <db>` (backup = pg_dump to
  `.generated/backups/` — the gm-5 receipt pattern, and the ONLY
  sanctioned way to touch ops data before od-6 guardrails).
- Topology: InstanceDefinition rows (odoo, odoo-postgres) +
  ServiceConnection rows (odoo→postgres, backend→odoo, proxy→odoo) +
  stacks.yml render so `pol allocate` knows them.
- Verify: `pol odoo up` on the chosen machine; both DBs created;
  login page serves via the proxy; healthchecks green; topology ping
  pass paints the new connections.

### od-2 — SSO (humans through Keycloak)
**✅ BUILT + VERIFIED 2026-07-27** (same branches): OCA auth_oidc
18.0.1.1.0.2 wheel pinned into pol-odoo/Dockerfile; `pol odoo
sso-setup` (lib/odoo-sso.sh) ensures KC client 'odoo' idempotently and
upserts the provider row in every odoo_% DB (secret KC->DB, no file).
Verified live: both DBs render 'Log in with Polari SSO' with a code-
flow link to auth.<domain>. Deferred honestly: browser round-trip +
mid-session KC-move check need pol-proxy live; role->group mapping is
manual v1 (plan's 'minimal mapping' = signup rules + manual promote).
- Keycloak client `odoo` (confidential, redirect
  `https://odoo.<domain>/auth_oauth/signin`), scripted via the KC
  admin API (the backend already holds admin creds) — idempotent
  setup in `pol odoo sso-setup`, never hand-clicked.
- Install/configure `auth_oidc` (or `auth_oauth` with generic OIDC)
  in both DBs; map KC roles → Odoo groups minimally (admin,
  internal user, portal).
- Verify: browser login round-trip via KC on both DBs; a KC server
  move (gm-4) mid-session keeps the Odoo session valid.

### od-3 — `odooconnect` framework module (the connector)
**✅ BUILT + VERIFIED 2026-07-27** (same branches): modules/odooconnect/
(basis/client/analysis/api/seed/selftest, waxsupply anatomy) wired into
polari-modules.json + FEATURE_MODULES + polariServer (guarded import,
defClassList, seed_pairs, gated endpoint). Guards are DATA-driven from
the row: read_only -> push_enabled -> ops typed phrase 'PUSH TO
OPERATIONS <name>'; anything not in READ_SAFE_METHODS counts as a
write; no write retries. 27/27 stub-server selftests + module-layer
suites green; REAL round-trip verified against the od-1 pair
(version/auth/search_read on odoo_sim). Deviations noted honestly:
provider_registry edge-probing deferred (odoo serves no /capability —
/api/odoo/status probes configs itself via common.version); tt-11
ping-pass fold-in rides that status endpoint rather than PROVIDER_PORTS.
- New feature module `modules/odooconnect/` (registered in
  polari-modules.json; POLARI_MODULES-gated; mlb-admitted):
  - `OdooInstanceConfig` (treeObject): name, base_url, db, mode
    (`simulation|operations`), auth ref (env var NAME, never the
    secret in a row), `push_enabled` knob (default False; ops rows
    additionally require the typed-confirmation flow to flip it),
    read_only, notes. Seeded: `odoo-sim` + `odoo-ops` (ops with
    push_enabled=False, read_only=True).
  - `odoo_client.py`: stdlib JSON-RPC (authenticate, execute_kw,
    search_read, create/write) with the honest-refusal shape
    ({ok:False, refusal, suggestion}) on connection/auth/permission
    failures; timeouts; NO retries that could double-write (writes
    are idempotent-by-external-ref or refused).
  - `/api/odoo/status` (per-config probe: reachable, db, version,
    installed modules, mode, push knob state) + provider_registry
    entry so topology edges resolve/probe/reprobe like the engines.
  - ServiceConnection health folded into the tt-11 ping pass.
- Selftests against a STUB JSON-RPC server (no live Odoo needed in
  CI): auth, search_read paging, refusal shapes, mode guards
  (operations + push_enabled=False → every write refuses naming the
  knob), sim/ops handle separation.

### od-4 — Model bindings + sync v1 (pull freely, push gated)
**✅ BUILT + VERIFIED 2026-07-28** (same branches): OdooModelBinding +
OdooSyncReceipt (bindings are DATA; receipts every run), odoo_sync
pull (provenance odoo:<inst>:<model>:<id>@<write_date>, idempotent by
deterministic row name, foreign-provenance rows = CONFLICT report not
overwrite) + push (x_polari_ref ensured on demand — itself a guarded
write; found->write absent->create; explicit row_names required),
/api/odoo/bindings|pull|push|receipts. 26/26 sync selftests vs the
shared stub (which starts WITHOUT x_polari_ref so the ensure path is
real). REAL acceptance on the od-1 pair: hand-seeded products,
pulled with exact provenance, pushed a Polari row INTO odoo_sim
(x_polari_ref field created on the live server, round-trip visible,
re-push updated not duplicated), ops write refused AT THE GUARD
naming the knob while ops reads flowed. Notes: odoo_sim needed the
'product' app (base has no product.template — honest refusal until
installed); starter seeds = partners->SupplyNode, product.template<->
WaxFeedstockDefinition, mrp.bom->SupplyChainDefinition (refuses until
mrp installs, od-5); order->ContextualizedValue bindings deferred to
od-5 where sale orders first exist.
- `OdooModelBinding` (treeObject): odoo_model (`product.template`,
  `res.partner`, `mrp.bom`, `sale.order`, `purchase.order`,
  `stock.quant`, `account.move`), polari_class, field_map_json,
  direction (`pull|push|both`), instance_ref, external-id strategy
  (`x_polari_ref` custom field on the Odoo side = idempotency key).
  Bindings are DATA — new mappings are rows, not code.
- Sync engine: `pull(binding)` → Polari rows with provenance_id
  `odoo:<instance>:<model>:<id>@<write_date>` (idempotent, updates
  tracked, never silently overwrites a locally-edited row — conflict
  = an honest report row, the schema-stabilization spirit);
  `push(binding)` → REFUSES unless instance.push_enabled AND (for
  ops) the call carries the typed confirmation string; every push
  writes a receipt (what changed, ids) — the MoveOperation receipt
  discipline applied to data.
- Starter bindings (pull): partners→SupplyNode, products↔
  MaterialsScienceMaterial/CeramicSample/WaxFeedstockDefinition
  (via a `product` facet), BOMs→SupplyChainDefinition+SupplyFlow,
  purchase/sale orders→SupplyFlow instances with real quantities +
  prices → ContextualizedValue cost rows.
- Verify: seed a handful of products/BOMs in odoo_sim by hand, pull,
  see rows + provenance; push a Polari-defined product INTO odoo_sim
  (knob on); confirm ops pushes refuse.

### od-5 — Business-simulation seam (the sim half of the mandate)
**✅ BUILT + VERIFIED 2026-07-28** (same branches): BusinessScenario-
Definition (scenarios as data incl. assumptions_json — Dustin's v1
scoping: commercial feedstock buyer + working wax printer are EXPLICIT
prerequisites; the hydroponic-farm wax source is scenario 2) +
odoo_scenario_engine (plan-first; sim-only guard refuses ops configs;
create/archive = honest pol-CLI suggestions since DB ops are host ops;
seed/run/harvest over RPC, all receipted; origin tag polari:<scenario>
scopes harvests). CLI scenario-init/scenario-drop with the odoo_scn_*
prefix guard + final pg_dump receipt before every drop. ACCEPTANCE:
wax-mold-goods-v1 ran END-TO-END on a real throwaway DB — 4 POs
received, 6 molds + 40 pots manufactured to state=done, 2 SOs
delivered; harvest = revenue 720 / materials 264 / margin 456;
BusinessOutcome 'succeeded' + BusinessModelDefinition (honestly NOT
self_sustaining — labor/energy/amortization excluded, listed in
assumptions). Run TWICE from fresh DBs -> byte-identical metrics; ops
proven untouched at the DATA level (base partner count, zero business
apps, models absent). 20/20 scenario selftests. LESSONS: Odoo 18 MOs
park in 'to_close' unless component moves are picked before
button_mark_done (engine now verifies state==done and refuses
otherwise); pg_dump 16 embeds a RANDOM \restrict token so
md5-of-dump is NOT a valid untouched-check — strip those lines or
assert at the data level.
- `BusinessScenarioDefinition` (treeObject, odooconnect): names an
  OdooInstanceConfig (must be mode=simulation — enforced), a seed
  spec (products/BOMs/partners/price lists as data, reusing od-4
  bindings in push mode — sim pushes are free), a driver script ref
  (SimulationDefinition integration: sim steps execute Odoo actions
  — confirm sale orders, run MRP, receive stock, invoice), and an
  outcome spec (which Odoo reports/queries to read back).
- Scenario lifecycle: `create` (fresh odoo db per scenario via
  db-manager copy of a template db — cheap resets, the throwaway
  discipline) → `seed` → `run` (stepped; each step receipted) →
  `harvest` (P&L, stock valuation, lead times → BusinessOutcome rows
  + evidence links onto TREE_ECONOMY / materials trees segments) →
  `archive` (drop db, keep the harvest + a pg_dump receipt).
- First concrete scenario (proves the loop end-to-end): "wax-print
  parts micro-business" — feedstock purchase (waxsupply rows as
  vendors/products), BOM = printed part from feedstock (ties
  manufacturing-tools tree), sale orders at scored price points
  (ScoreTerm cost contexts), harvest margin + throughput →
  BusinessOutcome on the economy tree.
- Verify: scenario runs twice → identical outcomes (determinism where
  Odoo allows; date-dependent bits pinned); outcomes visible on the
  tech tree; sim db dropped cleanly; ops db untouched (assert by
  checksum).

### od-6 — Real-ops guardrails (the ops half)
- Backups: nightly `pg_dump` receipts (pol odoo backup, cron via the
  host or a sidecar — receipts listed in /api/odoo/status);
  RESTORE DRILL is part of acceptance, not optional.
- Mobility: `pol swarm relocate odoo <machine>` (server-only, gm-4
  shape: same postgres, blue-green with the healthcheck) and
  `pol swarm relocate odoo-postgres <machine>` (gm-5 shape:
  writers-drain = scale odoo to 0, pg_dump receipt, staged volume
  copy, semantic verify = table+row counts vs receipt); filestore
  covered by the staged mover. MOVE_SUBJECTS + planner UI entries so
  the topology page previews these with typed confirmation.
- Quiesce integration: `/api/odoo/quiesce` proxy (scale-down is the
  v1 gate — Odoo has no native write-gate; honest receipt says so).
- Ops write path v1 stays HUMAN-IN-ODOO (people use Odoo's own UI —
  it is good at that); Polari pushes to ops remain knob+confirm and
  are for master-data alignment only (products, BOMs), never
  transactions.
- Verify: backup+restore drill green; both movers round-trip with
  zero data loss (the marker technique: a canary row written pre-move
  must survive); stale-journal detection covers the new volumes.

### od-7 — Surface (frontend + tech tree filing)
- Frontend: an "Odoo" card (link-out to odoo.<domain>) + a
  `/business/odoo` status page (instances, mode badges, push knobs
  shown as knobs, sync/bindings status, backup receipts, last
  scenario harvests) — theme-token compliant; refusals rendered.
- Tech tree: economy-tree nodes gain segments backed by odooconnect
  (theory=module rows); BusinessOutcome rows from scenarios attach
  as evidence; data_deps carry "no real ops data yet" gaps honestly
  until ops go live.
- No-code: register odoo-backed read models as data sources for
  displays (read-only projection of pulled rows — they are ordinary
  Polari rows already, so this may be free).

### src-1 — Sourcing layer (Dustin 2026-07-28, built same day)
**✅ BUILT + TESTED**: supplychain gained SupplySourceProfile
(overlap-capable flags open/commercial/local/polari/eco + availability
available|potential + demands_json for the customer side of mutual
loops), PriceCitation (dated, cited, is_estimate-honest price
observations), SourcePreferencePolicy (Dustin's 5-rank ladder as
editable data: polari-open-local > polari-open > open-non-polari-if-
eco > local-closed > general-commercial). REAL 2026-07-28 citations:
GPI GeoCement $34.95/10lb-$110/50lb (range-mapped, flagged estimate;
bulk discount visible: 7.71 vs 4.85 USD/kg), Aztec LP402 soy
$109/50lb (4.81/kg exact), bulkbeeswax 'from $8.99/lb' (flagged),
carnauba 2 sources $78.36 vs $92.99/5lb (18.7% spread). Analysis:
normalize (mass->USD/kg, piece-per-unit, dimension mixing refused),
price_compare (spread + preference premium), preferred_source
(potential better-ranked sources = develop-suggestions, never
auto-picks), scenario_price_drift (drymix pinned 1.8 vs cited 4.85 =
+169% flagged as a deliberate-edit suggestion). Hydroponics farm
seeded as potential supplier of wax-source-biomass AND demander of
geopolymer-self-watering-pot + geopolymer-pot-shelf (business_model_
ref hydroponic-wax-source-farm — scenario 2 hook). API /api/
supplychain/sourcing/*. 23/23 selftests; scenario products carry
item_ref links.

### src-2 — Formula layer (Dustin 2026-07-28, built same day)
**✅ BUILT + TESTED**: ProductInputRequirement maps a product to its
FULL feedstock space — roles (base-wax 60-85%, toughener 10-30%,
hardener 5-15% for natural-print-wax-blend) each carrying ALL
candidate item_refs, cited or not (uncited = research gaps surfaced:
rice-bran-wax, candelilla-wax, stearic-acid). ProductFormula = a
concrete blend; formula_analysis costs it from citations with full
validation (fraction sum, role ranges, candidate legality, uncited
components refuse with citation suggestions) and emits the
material-cost-per-kg SCORING TERM (is_positive False — cheaper wins)
with citation evidence, so sim results can score affordability.
cheapest_blend = greedy min-cost feasible fractions (a SUGGESTION
demanding print-validation): v0 blend 70/20/10 = 10.78 USD/kg;
optimizer finds 85/10/5 = 7.79 USD/kg from the same citations (-28%).
API /api/supplychain/sourcing/requirements|formulas|formula-cost|
cheapest-blend. 18/18 selftests. Follow-up: register the matching
ScoreTerm row in the scoring module's seeds (one row; kept out to
avoid destabilizing that module's count-asserting suites this late).

### src-3 — Substitute benchmark (Dustin 2026-07-28, built same day)
**✅ BUILT + TESTED**: MachinableWax.com seeded as THE current
commercial alternative for 3D-printing wax — is_eco_friendly=False
with the caveats as DATA on the substitution entry (contains
plastics: paraffin+polyethylene blend; emits fumes when overheated,
ventilation required / non-user-friendly under some conditions).
ProductInputRequirement gained substitutes_json (whole-product
substitutes vs role candidates). Citation: ~$10/lb pelletized,
honestly flagged is_estimate (exact store price unreachable — site
TLS error at observation; forum-referenced figure; re-cite when
reachable) → 22.05 USD/kg. product_cost_comparison + /api/
supplychain/sourcing/compare/{item}: formulas vs optimizer vs
substitutes in one caveat-carrying table + verdict — OUR blend
(7.79/kg optimized) beats the substitute by ~64.6%, and the cheap
row can never hide what it costs you (caveats travel with prices).
24/24 formula selftests.

### src-4 — Geopolymer make-vs-buy (Dustin 2026-07-28, built same day)
**✅ BUILT + TESTED**: geopolymer-mix ProductInputRequirement — the
DIY-local castable's full feedstock space with REAL 2026-07-28
citations: metakaolin $70/55lb (MetaMax via pool-supply; dealer-login
price, flagged estimate) = 2.81/kg, waterglass $46/gal EXACT
(Sheffield; gallon->5.2kg mass inferred, flagged) = 8.85/kg
as-solution, NaOH $69.97/16lb exact (Essential Depot; CAUSTIC — PPE
caveat) = 9.64/kg, play sand $7.39/50lb exact (Home Depot) = 0.33/kg.
fly-ash + slag = honest UNCITED gaps (industrial byproduct channels,
often cheap-to-free locally — worth the hunt). v0 castable
(40/16/3/41) = 2.96/kg; optimizer (34/10/1/55) = 2.11/kg. Substitute
= the GPI kit at 4.85/kg with caveats cutting BOTH ways (closed
formula + shipping vs the kit's hydroxide-free chemistry being
FRIENDLIER than the DIY NaOH route). VERDICT: making beats buying by
~39% (v0) to ~56% (optimized) — opposite of the wax finding, where
in-house blending loses to bulk pellets. Both v2 refinements listed:
dry-basis silicate costing, mix water, cure validation. 31/31
formula selftests.

### src-5 — Waterglass as a makeable intermediary (Dustin 2026-07-28)
**✅ BUILT + TESTED**: waterglass is critical across geopolymer/
sol-gel/pspp and is an INTERMEDIARY, not a natural material — so it
got its own ProductInputRequirement with production ROUTES as data:
(1) hydrothermal sand+NaOH digestion (cited: sand 0.33 + NaOH 9.64 +
tap water 0.0031/kg via a published 2026 utility tariff → recipe
~1.54/kg, digestion ENERGY EXCLUDED loudly); (2) rice-husk-ash+NaOH
— the low-temp sol-gel community route, RHA uncited gap; (3)
waste-glass fines — uncited gap closing the recycling loop. NEW
CASCADED COSTING: make_cost (seeded recipes only — optimizer stays a
suggestion) + effective_unit_price (min of buy/make, recursive,
cycle-guarded) + cascaded_cost; product comparisons now surface
'formula-with-made-intermediates' rows. RESULT CHAIN: waterglass
make 1.54 vs buy 8.85 (-83%); geopolymer castable with self-made
waterglass drops 2.65 → 1.48/kg → ~69% cheaper than the GPI kit.
Tech tree: sol-gel node description now names the production-routes
seam (first-class waterglass-production node with edges = deliberate
follow-up; data_deps were wrong mechanism — they resolve against
DigitizedDataset figures). 40/40 formula + 61/61 techtree selftests.

## Risks / honest gaps (say them, don't hide them)
- **Community vs Enterprise**: no Odoo Studio, limited accounting
  localizations/reports; if ops accounting needs more, that is a
  paid decision for Dustin, not a workaround to build.
- **Credential drift** (the 2026-07-27 outage class) applies to
  odoo-postgres verbatim until docker-secrets lands — mitigated by
  stable generated env + documented rescue.
- **Upgrade path**: Odoo major upgrades migrate the DB; pin the
  image tag, upgrades are their own receipted move (not built here).
- **Public repos**: NO credentials, NO real business data, NO dumps
  in git — backups live in `.generated/` (gitignored) only.
- **Resource footprint**: measure with res-2 profiles before
  placement; the odoo+postgres pair is the biggest new tenant since
  the engines.

## Ordering & first session
od-0 (minutes, Dustin) → od-1+od-3 can go in parallel conceptually
but BUILD od-1 first (nothing to connect to otherwise) → od-2 →
od-3 → od-4 → od-5 (the sim loop is the earlier payoff) → od-6 →
od-7. A first working session should land od-1 through od-3 with
selftests + the live login page; od-4's first pull is the natural
"it works" demo.

## Verification sketch (whole-plan acceptance)
- `pol odoo up` from cold on the chosen machine: healthy < 2 min,
  both DBs, SSO login, proxy green, topology pings green.
- Stub-server selftest suite green in CI (no live Odoo dependency).
- Pull→rows-with-provenance; ops push refuses; sim push lands.
- One full scenario: seed → run → harvest → BusinessOutcome on the
  economy tree → archive; ops checksum untouched.
- Backup/restore drill + both gm movers round-trip, receipted.
