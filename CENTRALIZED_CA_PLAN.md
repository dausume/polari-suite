# Centralized CA plan — one root to trust, optional public-brand cert for remote

Status: **plan / investigation**, no code changed. Prep for **remote access to the
Polari interface** — today's self-signed certs throw browser warnings, and there
are three separate roots to accept.

## 1. Where we are (from the repo)

- **TLS terminators:** nginx proxies — `pol-proxy`, `prf-proxy`, `psc-proxy` — plus
  **Keycloak terminates its own HTTPS on :8443** (`https-certificate-file=/opt/certs/pol-kc.crt`).
- **Cert issuance:** plain `openssl` in `setup-polari-security.sh` (suite) →
  `generate-prf-certs.sh` / `generate-psc-certs.sh` (subnodes, `--shared-ca` flag) +
  `nip-staging-setup.sh` (nip.io wildcard). CA = 10yr, leaves = 825d.
- **THREE roots:** `pol-ca`, `prf-ca`, `psc-ca` (each `*-proxy/certs/ca/`). `--shared-ca`
  copies the suite root into a subnode, but it's still manual and per-tier.
- **Distribution:** certs are **COPY-baked into images** at build (Dockerfiles), not
  runtime-mounted → renewing a cert today means rebuilding.
- **Trust gap:** the roots aren't in any browser/OS store → "connection not private"
  on every browser-facing service (prod `*.polari-systems.org`, staging `*.nip.io`).
- **Internal traffic** is plaintext HTTP over the docker network (no mTLS). Not a
  goal here; noted as a later option.

The user's ask, in two stages:
1. **Centralize** so accepting **one** cert makes **all** Polari certs valid.
2. **Later**, optionally get a **publicly-trusted (brand) cert** so browsers don't
   warn at all — specifically for remote access.

## 2. The key insight — two trust planes

There are two *different* trust problems, and they want *different* answers:

| Plane | Names | Can a public CA issue? | Answer |
|---|---|---|---|
| **Public/remote** | `polari-systems.org` + subdomains | **Yes** (real DNS) | **Let's Encrypt** (ACME) → browser-trusted, **zero import** |
| **Internal/dev/staging** | container hostnames, `*.internal`, raw IPs, `*.nip.io` | **No** (no domain validation) | **Private root (step-ca)** → import **once** |

So the end state is a hybrid, and **`step-ca` is the unifying engine** for both:
it runs a private CA (one root → import once) *and* a built-in ACME server (auto
issue/renew like Let's Encrypt, but private), and it's the natural bridge to real
Let's Encrypt for the public leaf.

## 3. Target architecture

```
                 ┌────────────────────────────┐
                 │  Polari Root CA  (step-ca)  │   ← the ONE cert the user imports
                 │  offline-ish, long-lived    │
                 └─────────────┬──────────────┘
                               │ signs
                 ┌─────────────▼──────────────┐
                 │  Intermediate CA (step-ca)  │   ← does the actual signing; rotatable
                 └─────────────┬──────────────┘
        ┌──────────────────────┼───────────────────────┐
        │ ACME / step CLI       │                        │
   ┌────▼────┐           ┌──────▼──────┐          ┌──────▼──────┐
   │ pol-*   │           │  prf-*      │          │  psc-*      │   ← all nodes, one root
   │ proxy/kc│           │  proxy/kc   │          │  proxy      │
   └─────────┘           └─────────────┘          └─────────────┘

   PUBLIC remote edge (polari-systems.org): Let's Encrypt leaf on the public
   proxy — browser-trusted, no import. step-ca root still covers everything else.
```

- **One root.** Replaces `pol-ca` + `prf-ca` + `psc-ca`. Trust it once → every
  internal Polari cert across all three nodes validates. This is the literal
  "accept one cert for all" deliverable.
- **One intermediate** signs the leaves (root stays put). Rotating the intermediate
  never forces a re-import of the root.
- **Short-lived leaves + auto-renew** (step-ca default ~24h–30d) via ACME or
  `step ca renew` — kills the 825-day manual openssl regen.

## 4. Phased implementation

### Phase 1 — stand up step-ca (additive, nothing removed yet)
- New service `pol-ca` (image `smallstep/step-ca`) in the suite compose, on the
  docker network, **CA material in a named volume** (never baked into an image).
- `step ca init` → root + intermediate + `ca.json`. Provisioners:
  - **ACME** (for nginx/Keycloak auto-enroll + renew),
  - **JWK** (for scripted `step ca certificate` issuance).
- Export `root_ca.crt` (this is *the* file users import).

### Phase 2 — issue service certs from step-ca
Swap the openssl blocks for step issuance, same output paths the Dockerfiles/nginx
already expect (so configs barely change):
- `setup-polari-security.sh` — replace the `pol-kc` / `pol-proxy` openssl/CSR/x509
  blocks with `step ca certificate "<CN>" cert.crt cert.key --san ... --provisioner acme|jwk`.
  Reuse the existing SAN lists (lines ~484–500) verbatim.
- `generate-prf-certs.sh` / `generate-psc-certs.sh` — same; **drop the per-node
  `openssl genrsa ... -x509` root generation entirely** (the `else` branch) and the
  `prf-ca`/`psc-ca` concept. Every node points at the one step-ca.
- `nip-staging-setup.sh` — issue the `*.nip.io` wildcard from step-ca too.

### Phase 3 — distribute the single root (the "one cert" win)
- Ship `root_ca.crt` as the only trust anchor:
  - **Browsers/OS (the user + anyone remote on the private plane):** import once —
    Linux `update-ca-certificates`, Firefox/Chrome cert store. Document both.
  - **nginx proxies:** mount root as `ssl_trusted_certificate` (and for upstream
    verify if/when internal TLS is added).
  - **Keycloak:** add the root to its truststore (it currently imports none) so
    backchannel/issuer checks pass. `pol-keycloak/Dockerfile.pol-kc` +
    `keycloak-suite.conf`.
- **Switch certs from build-time COPY → runtime volume mounts** so renewals take
  effect without rebuilding images (prod compose currently bakes them in). This is
  the one structural change with real blast radius — call it out for review.

### Phase 4 — auto-renew
- ACME against step-ca's ACME endpoint via `certbot`/`acme.sh`/`step` in a small
  renewer sidecar or systemd timer; nginx `reload` on renew. Replaces manual regen.

### Phase 5 — public brand cert for remote (the "after" step)
- For `polari-systems.org` + subdomains on the **public** proxy: get the leaf from
  **Let's Encrypt** (or Google Trust Services — both are free ACME) using
  **DNS-01** (works behind NAT, supports wildcards) via the domain's DNS API.
  → Browser-trusted, **no import for remote users**.
- Keep step-ca for everything Let's Encrypt can't issue (IPs, `*.nip.io`,
  `*.internal`, container names).
- Net remote UX: `https://prf.polari-systems.org` shows a clean padlock to anyone;
  internal/staging needs the one-time root import only on dev machines.

## 5. Why step-ca over "just consolidate to one openssl root"

A single hand-rolled openssl root would technically satisfy "accept one cert," but
step-ca buys the things that matter for **remote, multi-node, ongoing** use:
- ACME ⇒ auto issue + **auto-renew** (no more 825-day cliffs, no rebuilds),
- one root across all nodes with **rotatable intermediates**,
- the same tool **bridges to public Let's Encrypt** for Phase 5,
- revocation + short lifetimes ⇒ a leaked leaf isn't a 2-year problem.

## 6. Decisions needed (when you're back)

1. **Root lifetime / storage** — root in a volume on the suite host is fine for now;
   do you want the root key kept offline (issue only via the intermediate)? (Best
   practice: yes.)
2. **One intermediate, or one per node/tier** (revoke a tier independently)? Lean
   one root + one intermediate to start.
3. **Public cert provider** — Let's Encrypt (default) vs Google Trust Services; and
   **which DNS provider** hosts `polari-systems.org` (determines the DNS-01 plugin).
4. **Build-time COPY → runtime mount** for certs — OK to make that change? It's
   required for hands-off renewal.
5. **mTLS between internal services** — out of scope for the browser-trust goal;
   want it on the roadmap or dropped?
6. **Scope now** — start with the *remote-facing public proxy* (Phase 1→3 + 5 for
   `polari-systems.org` only), or do the full three-node internal migration in one
   pass?

## 7. Suggested first cut (smallest useful step)

If the immediate need is "look at the interface remotely without scaring people":
**Phase 1 (step-ca up) + Phase 5 (Let's Encrypt on the public proxy for
`polari-systems.org`)** gets a browser-trusted remote endpoint fast, while the
internal three-root → one-root consolidation (Phases 2–4) follows without blocking
remote access.

## 8. Staging concretization (decided 2026-06-22)

**Deployment facts:** registrar = **Namecheap** (`polari-systems.org`); also using
**DigitalOcean** (prod VM). **Staging runs on the DEV DEVICE, not the VM**,
remote-accessed by **one person** for testing, with the **proxy restricting access**.
Prod runs on the DO VM.

**Implication — staging needs NO step-ca and NO cert import.** A real subdomain with
a **Let's Encrypt** cert is publicly trusted, so the one remote tester sees a clean
padlock with zero setup. step-ca/Phases 1-4 are only needed later for *internal*
names (container hosts, IPs, `*.internal`) and prod's internal mesh — they do **not**
block remote staging.

**Recommended staging path (fits the existing subdomain-routing proxy):**
1. Subdomain scheme under the real domain, e.g. `*.staging.polari-systems.org`
   (so `auth.staging`, `prf.staging`, `psc.staging`, `api.prf.staging`, ... map onto
   the proxy's existing subdomain routes — no proxy rework).
2. **One Let's Encrypt wildcard cert `*.staging.polari-systems.org` via DNS-01.**
   Wildcards REQUIRE DNS-01, and DNS-01 also works behind home NAT (no inbound :80
   needed for issuance) — both reasons point the same way.
3. nginx on the dev device terminates with that wildcard cert; the proxy limits
   access to the one tester (IP allowlist / basic-auth / client-cert — separate from
   the server cert).

**DNS-01 provider — delegate to DigitalOcean, don't use Namecheap's API.**
Namecheap's ACME/API path is painful: IP allowlisting + account eligibility
(20+ domains or $50 balance/spend) + only third-party certbot plugins.
**DigitalOcean DNS** has a first-class `certbot-dns-digitalocean` / `acme.sh dns_dgon`
plugin and you already run DO. So:
- Move the zone (or just delegate a `staging` subdomain via NS records) to **DO DNS**,
  then DNS-01 is a single DO API token. Prod on the DO VM benefits from DO DNS too.
- Wildcard issuance: `certbot certonly --dns-digitalocean -d '*.staging.polari-systems.org' -d staging.polari-systems.org`.

**Reaching the dev box (Option B, the recommended one above):** port-forward router
:443 -> dev device. Home IP is likely dynamic -> script the `A` record via the DO API
(tiny DDNS cron); DNS-01 issuance itself is unaffected by IP changes.

**Alternative (Option A) — Tailscale**, if you'd rather not port-forward / expose the
home IP: put the dev box + the tester on a tailnet; `tailscale cert` gives a real
LE-backed cert for the `*.ts.net` MagicDNS name, access limited to the tailnet (the
one person), zero firewall changes. **Trade-off:** Tailscale gives ONE hostname per
device, which clashes with the proxy's *subdomain* routing (`auth.`/`prf.`/`psc.`) —
you'd rework routing to paths or use Tailscale Serve. Because of that mismatch,
**Option B preserves the current architecture and the prod path; Tailscale is the
fallback if port-forwarding is the dealbreaker.**

**One thing to confirm when back:** OK to move DNS for `polari-systems.org` (or just a
`staging` subdomain) to **DigitalOcean DNS**? That unlocks clean DNS-01 and is the
only real prerequisite for the recommended path. → **Confirmed "likely fine" 2026-06-22.**

### Why not step-ca for the remote "accept every cert" problem?
A fair question — step-ca *would* solve it: chain frontend/backend/keycloak certs to
one root, and the remote user accepts **once**. But that "once" = **installing a
custom root CA into their trust store** — manual, per-device, per-browser, often
forbidden on managed machines, and scarier than a self-signed warning (they're
trusting your CA for *any* site). Let's Encrypt makes them accept **zero** times (the
signer is already trusted everywhere). The multi-cert problem is then solved by **one
wildcard `*.staging.polari-systems.org`** that frontend + backend + keycloak all
present — public, so no import, no warnings. step-ca is right for the **internal**
plane (container hosts, IPs, `*.internal`) that a public CA can't sign and where
importing the root on *your own* machines is fine; it's the wrong tool only for
untrusted remote browsers.

**Keycloak caveat:** it currently self-terminates TLS on `:8443` with its own cert.
To share the one wildcard, either front it with the nginx proxy (terminate there,
forward to KC) or give KC the same wildcard cert file. Proxy-fronting is cleaner —
one termination point for the whole suite.

## 9. Chosen direction (2026-06-22): configurable step-ca-everywhere + LE edge

Decision: **step-ca is the universal internal CA** (replaces the 3 self-signed roots,
one root); **Let's Encrypt sits on top only at the public edge** (the prod parent
node's public-facing nginx). Configurable at setup so the same scripts cover dev /
staging / prod.

**Trust per hop (the precise model):**
- **Browser -> edge nginx:** edge presents the **LE** cert; browser trusts LE natively
  -> no warning, no import. This is the ONLY cert the public ever sees.
- **Edge -> internal services:** edge re-encrypts and validates each upstream's
  **step-ca** cert against the step-ca root (the edge trusts step-ca).
- **Internal / cross-node:** all step-ca, one root.
- LE and step-ca own *different hops*; they don't trust each other. (Common phrasing
  trap: LE *issues* the edge cert — it doesn't "trust" it.)

**Keycloak is browser-facing** (`auth.` = OIDC redirect target), so the edge's LE cert
must be a **wildcard `*.polari-systems.org`** presented for every public subdomain the
browser touches (`prf./psc./auth./api.*/files./s3.`); KC moves *behind* the edge
(step-ca internally) instead of self-terminating on :8443.

**Configurable setup surface** (`setup-polari-security.sh`):
- `CERT_BACKEND=step-ca` (always — universal internal issuer)
- `PUBLIC_EDGE=letsencrypt|none` (on for prod parent; off for dev/staging by default)
- `PUBLIC_EDGE_NODE=<node>` ; `LE_DOMAIN=polari-systems.org`
- `LE_DNS_PROVIDER=digitalocean` (+ token) ; `LE_WILDCARD=true`
- `INTERNAL_TLS=bridge|terminate` (the fork below)

Dev/staging => step-ca only (import the root once). Prod parent => step-ca internal +
LE wildcard edge. Flip `PUBLIC_EDGE=letsencrypt` on staging later for zero-import.

**The scope fork — how far step-ca reaches internally:**
- `bridge` ("step-ca for everything"): edge re-encrypts; EVERY internal service
  terminates TLS with a step-ca cert (incl. container-to-container). Most secure /
  mTLS-capable, but every service needs a cert + renewal + config. Bigger lift.
- `terminate` (**recommended default**): edge terminates LE; internal stays plaintext
  on the docker network; step-ca covers only what already self-terminates TLS
  (Keycloak) + **cross-host/cross-node** links. Full user-facing win + one-root
  consolidation, far fewer moving parts. `bridge` is the opt-in upgrade.

## 10. No wildcards — explicit SANs from a cert manifest (2026-06-22)

Decision: **no `*.` wildcard certs.** A wildcard's one key impersonates every present
or future subdomain, can't be constrained to the hosts actually run, and is flagged by
common security baselines. Instead, **config enumerates the exact hostnames per cert**,
and that single list drives BOTH issuers:
- step-ca: `step ca certificate <cn> ... --san h1 --san h2 ...`
- Let's Encrypt: setup **auto-generates** `certbot certonly --dns-digitalocean -d h1 -d h2 ...`
  from the same list. DNS-01 handles explicit multi-name certs (one `_acme-challenge.<name>`
  TXT per `-d` via the DO API).

**Cert manifest** (lifts the hardcoded `KC_SANS`/`PROXY_SANS` out of
`setup-polari-security.sh` into one declarative source the issuance iterates):
```
# cert-name        issuer       SANs (explicit — no wildcards)
pol-proxy-public   letsencrypt  polari-systems.org, www.polari-systems.org,
                                auth.polari-systems.org, prf.polari-systems.org,
                                psc.polari-systems.org, api.prf.polari-systems.org,
                                api.psc.polari-systems.org, files.polari-systems.org,
                                s3.polari-systems.org
pol-kc             step-ca      pol-keycloak, keycloak.internal
prf-backend        step-ca      prf-backend.internal
...
```
Add a service => add a line + reissue (no implicit wildcard coverage — the intended
posture).

**Granularity:** public edge = ONE cert whose SANs are exactly the public names;
internal = **per-service** step-ca certs scoped to their own hostname(s) (cheap to
issue + auto-renew, maximum isolation).

**Why no-wildcard is the right call (the substantive reason):** blast radius on key
compromise — a per-host explicit cert means a leaked key impersonates only *that*
host; a wildcard key impersonates every subdomain. That's real security, not
obscurity.

**Naming is NOT secret, by design (open source).** The threat model assumes the
attacker knows every hostname, route, and the source itself (Kerckhoffs). So the fact
that explicit SANs appear in public CT logs is a non-factor — we don't rely on hiding
names. The manifest's `issuer` column is therefore chosen purely by **exposure**:
browser-facing => `letsencrypt`; internal-only => `step-ca` (because it's unreachable,
not because it's hidden). Security comes from there being no actual entry path:
per-service keys (containment), short-lived auto-rotated certs (a leak expires in
days), the edge access restriction, and a public CA at the edge.

## 11. Implementation shape — CA sub-shells driven by the setup shells (2026-06-22)

Everything comes up via docker compose, so the setup shells must prepare all cert
material **before** `up` → bring-up "just works." Mirror the existing pattern
(`setup-polari-security.sh` → `generate-prf/psc-certs.sh`): a focused **`ca/`** dir of
small, single-purpose sub-shells, called by the setup shells, each **idempotent** and
**preflight-gated** (and honoring the small-files/structured-dirs rule).

**`ca/` layout:**
```
ca/
  cert-manifest.conf       # declarative: cert-name | issuer | explicit SANs (the §10 source of truth)
  lib-ca-common.sh         # sourced: logging, prompt/confirm, idempotency + expiry checks,
                           #   manifest parser, SAN→(--san …)/(-d …) builders
  setup-step-ca.sh         # init/connect step-ca (root+intermediate+provisioners); export root_ca.crt
  issue-internal-certs.sh  # iterate manifest issuer=step-ca rows → per-service certs (explicit --san)
  setup-letsencrypt.sh     # edge: preflight + walkthrough, then auto-build certbot -d … from manifest
  walkthrough.sh           # interactive guidance for the human-only steps (below)
  renew.sh                 # step ca renew + certbot renew; reload nginx (cron/sidecar)
```

**Call graph** (`setup-polari-security.sh` reads `CERT_BACKEND`/`PUBLIC_EDGE`/… and dispatches):
```
setup-polari-security.sh
  └─ ca/setup-step-ca.sh           (always — universal internal CA)
  └─ ca/issue-internal-certs.sh    (always — per-service step-ca certs)
  └─ ca/setup-letsencrypt.sh       (only if PUBLIC_EDGE=letsencrypt, e.g. prod parent)
prod-setup.sh / nip-staging-setup.sh call the same sub-shells with their env's flags.
```

**Docker-compose integration:**
- New `pol-ca` service (step-ca container), CA material in a **named volume** (never baked).
- Certs land in host paths/volumes the proxy + Keycloak services **mount at runtime**
  (the build-COPY → runtime-mount switch). So issuance is decoupled from image builds;
  renewals take effect on `nginx -s reload`, no rebuild.
- The `ca/` sub-shells run in the setup phase (or a one-shot compose init service /
  profile) so certs exist before the proxies start → valid TLS on first `up`.

**Walk-the-user-through (interactive, each gated by a preflight check that fails LOUD
with the fix, never a half-broken bring-up):**
- **DO API token** — prompt if absent; validate with a test API call; store in `.generated/.env.*`.
- **DNS delegation** — `dig NS <domain>` → confirm DigitalOcean nameservers; if not,
  print the exact Namecheap "point NS to DO" steps and pause until confirmed.
- **Domain + LE account email** — prompt, persist.
- **Port-forward (staging dev box)** — remind to forward :443 inbound (issuance via
  DNS-01 doesn't need it; only remote *access* does).
- **step-ca root import** — after issuance, print the root path + OS/Firefox/Chrome
  import steps (for the internal plane / the one staging tester).
- **Re-run safety** — idempotent: valid cert present → skip; near expiry → renew; only
  issue when missing.

**Run modes:** interactive by default (prompt only for a *required* value that's
missing); `--non-interactive`/env-driven for unattended/CI (fail fast if a required
value is absent). A `--dry-run` prints the exact `step`/`certbot` commands + the
resolved SAN lists without issuing — reviewable before anything hits LE's rate limits.
