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
