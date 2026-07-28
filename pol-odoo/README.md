# pol-odoo / pol-odoo-postgres — Odoo ERP service pair (od-1)

Odoo 18 Community + PostgreSQL 16, the backbone of business SIMULATIONS
(`odoo_sim`) and REAL business ops (`odoo_ops`). Full plan:
`ODOO_INTEGRATION_PLAN.md` at the suite root. **The hard invariant: sim
and ops are separate databases and must never blur.**

## Bring-up (the only supported path is the `pol` CLI)

```bash
pol security setup            # generates the credential files (once)
pol odoo up --env staging     # build + start odoo-postgres + odoo
pol odoo init-db sim          # create odoo_sim (base modules, no demo)
pol odoo init-db ops          # create odoo_ops
pol odoo sso-setup            # od-2: Keycloak OIDC in every odoo_% DB
pol odoo status               # health, DBs, backup receipts
```

Both services sit behind the compose profile `odoo`, so a plain
`pol suite up` does NOT start them. Intended host: **econ-core**
(the business-ops/economics core — od-0 decision).

- Web: `https://odoo.<BASE_DOMAIN>/web/login?db=odoo_sim` (or `odoo_ops`).
  Database-manager operations are refused (`list_db = False`; the manager
  page shell still renders, but list/create/drop RPCs return Access
  Denied) — pick the DB via the `?db=` query parameter; `pol odoo urls`
  prints the login URLs.
- Dev tier exposes `:8069` (web) and `:8072` (websocket) directly.

## Credentials — and the DRIFT TRAP (read this before touching them)

`setup-polari-security.sh` (via `pol security setup`) generates ONE
shared secret into two gitignored files that must stay in sync:

- `pol-odoo-postgres/odoo-postgres.env` — `POSTGRES_PASSWORD` (server side)
- `pol-odoo/odoo.env` — `PASSWORD` (client side)

Knob: `POLARI_ODOO_DB_PASS`. The files are SKIP-IF-EXISTS: postgres
bakes the password into the `odoo-db-data` volume at FIRST init, so
regenerating the env files later does NOT change the live DB password —
the exact credential-drift class that took Keycloak down on 2026-07-27.

**Rescue procedure** (env files and volume disagree — symptoms: odoo
logs show `password authentication failed for user "odoo"`):

1. Do NOT delete the volume. Take a receipt first if any DB exists:
   `pol odoo backup sim` / `pol odoo backup ops`.
2. Reset the live password to match the env files:
   ```bash
   docker exec -it odoo-postgres psql -U odoo -d postgres \
     -c "ALTER USER odoo WITH PASSWORD '<value of POSTGRES_PASSWORD in odoo-postgres.env>';"
   ```
   (postgres trusts local socket connections inside the container, so
   this works even while password auth is failing over TCP.)
3. Restart the server: `pol odoo down && pol odoo up`.
4. Only if the volume is disposable (no data worth keeping): remove the
   `odoo-db-data` volume and let first-init re-bake the current env.

## Files

- `pol-odoo/Dockerfile` — pinned `odoo:18.0-20260723` (dated tag; version
  bumps migrate the DB and are their own receipted move, never silent).
- `pol-odoo/odoo.conf` — checked in, NO secrets: proxy_mode, workers=2,
  gevent :8072, `list_db = False`, `dbfilter ^odoo_(sim|ops)$`, memory
  ceilings sized to the 1G container limit.
- `pol-odoo-postgres/Dockerfile` — pinned `postgres:16.14`.
- `*.env.example` — shape of the generated credential files.

## Backups

`pol odoo backup <sim|ops>` → `pg_dump` receipt in `.generated/backups/`
(gitignored — NEVER commit dumps; the repos are public). This is the only
sanctioned way to touch ops data until od-6 lands the full guardrails.

## SSO (od-2)

`pol odoo sso-setup` is idempotent and never hand-clicked: it ensures
the confidential Keycloak client `odoo` in realm **Polari** (admin API
from inside the pol-keycloak container; redirect
`https://odoo.<domain>/auth_oauth/signin`), then installs the OCA
`auth_oidc` addon (pinned wheel, baked into the image) and upserts the
`auth.oauth.provider` row in every existing `odoo_%` database — the
client secret flows Keycloak → odoo DB in one pass and is never
written to a file. Endpoint split follows the PRF-backend pattern:
browser-facing auth/logout = public `https://auth.<domain>`,
server-to-server token/jwks/userinfo = in-network
`http://pol-keycloak:8080`. Requires pol-keycloak running; re-run any
time (e.g. after creating a new DB or changing the domain).

## Honest gaps (v1)

- KC-role → Odoo-group mapping is MANUAL: users arriving via SSO
  follow Odoo's signup rules; promote to internal/admin inside Odoo.
  The admin password printed at `init-db` remains the break-glass
  local login.
- The browser SSO round-trip needs pol-proxy serving `odoo.<domain>`
  (direct :8069 access builds an http:// redirect_uri that Keycloak
  rightly rejects — proxy_mode only trusts the proxy's headers).
- The odooconnect framework module (JSON-RPC bindings) is od-3.
- Movers (`pol swarm relocate odoo|odoo-postgres`) are od-6; until then
  the pair lives where `pol odoo up` ran.
- Community edition: no Odoo Studio, limited accounting localizations —
  a paid decision for later, not a workaround to build.
