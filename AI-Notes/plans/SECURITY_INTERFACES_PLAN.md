# Security interfaces plan — App, Network, OS as objects, screens and automation

_2026-09-10, from Dustin's ask: "interfaces for controlling and understanding security on different proxies… snippets of functionality for proxies specific to modules or apps, adjusted via jinja when the app is brought up or down… interfaces that simplify looking at what is going on with all of the different pieces of the security as we categorize them… the 3 major categories: App, Network, and OS… record apps that have or have not gone through security automation steps… how these tie into module and app standardization… documentation of how the automation works." Planning only; phases are gated on his ratification. Builds on ISLE_HARDENING_PLAN.md (the rings; os-security/), STANDARD_POLARI_APP.md (the manifest), reg-1 (the registrar)._

## 0. The shape in one paragraph

Security in Polari becomes **one module, `security`**, that owns a fixed three-domain taxonomy (App, Network, OS), holds every concrete control as a row under one of those domains, renders the controls that are generated (proxy snippets, AppArmor profiles, firewall rules, content policies, service certificates) from jinja2 templates fed by the app manifests, and keeps a **per-app security ledger** that records which automation steps each app has been through and with what result. Nothing about an app's security lives anywhere but its manifest's `security` stanza plus the app's own `security/` folder of snippets; everything the operator sees is a Polari display of configured tables and structured panels, per object, per domain, with one overview. Every generated control follows the same lifecycle: **derived → rendered → observed → tested → enforced**, and the ledger says where each app stands on each control.

## 1. The taxonomy — fixed, three roots, everything beneath

| Domain | Areas beneath it | What the row says |
|---|---|---|
| **App** | encryption · authentication · authorization · channels (app↔app vs user↔app) · content policy (payload) · browser policy (CSP headers) | how an app proves who it is, who may call what, what a request may contain |
| **Network** | tls (scaffolding + verification) · proxy (config, per-app snippets) · firewall (ufw, DOCKER-USER, router zones) · exposure (doors, rungs) | how bytes get in, between and out, and who can forge them |
| **OS** | dac (uid, read-only, caps, groups) · mac (AppArmor, seccomp, sVirt) · groups (permission groups, hardware groups) · hardware trials (pkexec-traced first runs) | what a process can touch on the machine |

Other kinds of security (secrets/credentials lifecycle, audit logging, updates) are areas under these roots, not new roots: secrets → App/encryption (key material) and OS/dac (file modes); audit logging → OS/mac evidence; unattended upgrades → OS. The taxonomy is a seeded, read-only tree (`SecurityDomain` × `SecurityArea` rows); an operator does not add roots.

## 2. The object model (module `security`, one class per file under `objects/security/`)

**Taxonomy and inventory**
- `SecurityDomain` (name app|network|os, title, description, order).
- `SecurityArea` (name, domain, title, description, generated: bool, docs_page).
- `SecurityControl` — the row every concrete piece maps to: name, domain, area, kind (proxy-snippet|apparmor-profile|seccomp|firewall-rules|content-policy|browser-csp|service-cert|trust-channel|permission-group|hardware-trial|audit-check), owner_app (module id or fixed piece), scenario (isle|swarm-lean|swarm-full|dev|any), state (**absent|derived|rendered|observed|tested|enforced|complain|failed**), artifact (path of the rendered file), source (manifest stanza / snippet file / derivation), last_run, verdict, evidence (short text), notes. The registrar's `ModuleRegistration` is the pattern: one row per (control, app, scenario), refreshed from the live state, never hand-typed.
- `SecurityScenario` (name, route isle|swarm|compose, rings on, mode, fixed pieces) — mirrors `os-security/scenarios/*.yml`, read-only.

**App domain**
- `TrustChannel` — one row per (from, to) pair the system knows: from_kind/to_kind (user|frontend|backend|service|agent|guest), from_app, to_app, direction, transport (plain|tls|mtls|overlay-encrypted), auth (none|oidc-bearer|basic|hmac-secret|mtls-cert|api-key), key_kind (**asymmetric|symmetric|both**), key_source (keycloak|suite-ca|isle-ca|docker-secret|generated), rotation, verified (bool), evidence. Derived from: the proxy templates (user→app), `ServiceConnection` rows (app→app), the isle protocol matrix (`IsleProtocolPermit`), Keycloak clients (full profile). The point he made: **servers use symmetric material between themselves (shared secrets, HMAC, session keys under mTLS), users use asymmetric material (signed OIDC tokens, TLS server certs, no shared secret ever held by a browser)** — the row makes that explicit per channel so a symmetric key on a user channel is a finding.
- `AuthzRule` — who may call what: app, resource (class or route), role/group (Keycloak role, isle group, polari-remote/polari-app), verbs (CRUDE), source (accessControl rows, manifest). A view, not a second authority: the existing accessControl module stays the authority.
- `ContentPolicy` — the payload policy for one endpoint or class: app, target (class name or route), mode (**derived|observe|enforce**), schema (JSON Schema derived from the class's typing), limits (max body bytes, max array length, max string length, allowed content types), violations_observed, last_tested, test_verdict. Section 5 says how it is derived.
- `ContentPolicyViolation` — evidence rows in observe mode (app, target, field, reason, count, first/last seen, hashed client); the input to "does this policy break anything real".
- `BrowserPolicy` — the CSP/frame/referrer header set per frontend host (prf, psc, hub), derived from what the frontend actually loads (own origin, api origin, Keycloak origin, fonts); mode observe (`Content-Security-Policy-Report-Only`) → enforce; violations from the report endpoint.

**Network domain**
- `ProxyConfig` — one per (route, env): route (isle-agent|suite-proxy), env/scenario, template path, rendered path, guard_verdict, hardening flags (tls versions, hsts, headers, rate limits), snippets_included (count), last_rendered.
- `ProxySnippet` — one per (app, scope): app, scope (**api|site|frontend|agent**), kind (location|headers|rate-limit|mtls|upstream|deny), template (path to `modules/<app>/security/proxy/<scope>.conf.j2`), rendered (text), enabled, order, requires (e.g. `mtls` needs a client CA), state (absent|rendered|guarded|live). Section 4 says how it composes.
- `ServiceIdentity` — one per service certificate: service, hostnames (SANs), issuer (suite-ca|isle-ca|letsencrypt), path, not_after, mtls_required_by (list of peers), verifies (list of peers), cert_manifest_row. Derived from `ca/cert-manifest.conf` + `ca/issued/`.
- `FirewallRuleSet` — one per (scenario, chain): chain (ufw|docker-user|router-zone|swarm-ports), rules (rendered text), applied (bool, from audit), sources resolved (bool).
- `ExposureRow` already exists (islemesh/vpn) — linked, not duplicated.

**OS domain**
- `MacProfile` — one per AppArmor/seccomp/sVirt profile: app, kind (apparmor|seccomp|svirt), name, mode (enforce|complain|absent), loaded (bool), denials_24h, stanza_hash (so a manifest change shows as "profile stale").
- `DacPolicy` — one per app: host uid, groups, read_only, caps_add, writable paths, pids_limit, tmpfs; rendered from the stanza, compared with what the container actually runs with (`docker inspect`).
- `PermissionGroup` — polari-remote, polari-app, and the hardware groups (dialout, video, plugdev, kvm, libvirt, gpio, i2c, render, input): name, purpose, members (host), sudoers drop-in, granted_by (install-groups.sh / manifest), apps_needing (derived from stanzas and trials).
- `HardwareTrial` — one per (app, run): app, started/ended, method (pkexec|sudo|complain-only), observed_devices, observed_caps, observed_paths, observed_groups (derived: /dev/ttyUSB* → dialout, /dev/video* → video, /dev/bus/usb → plugdev, /dev/kvm → kvm, /dev/gpiochip* → gpio, /dev/i2c-* → i2c), proposed_stanza (JSON), accepted (bool), accepted_by, notes. Section 6.

**The ledger**
- `AppSecurityRecord` — **one row per app** (module id or suite app), the thing he asked to record: app, kind (polari-app|hardware-app|suite-app|fixed-piece), stanza_declared (bool + hash), stanza_conforms, mac_rendered, mac_enforced, dac_rendered, proxy_snippets (n rendered / n live), channels_declared, content_policy (none|derived|observed|enforced), content_policy_tested, browser_policy, hardware_trial (n/a|pending|done|accepted), audit_verdict (open|partial|hardened for the scenario it runs in), **steps_complete / steps_total**, last_refresh, blocking (the first missing step). Refreshed by the same verifier the registrar uses (against the live server + the rendered tree), so it is a report of what IS, never of what someone typed.

## 3. The module `security/` directory — the standard (his ask 2026-09-10)

Every module and app carries **one `security/` directory next to its manifest**, and it is the only place a developer has to look to see what the app asks of the machine and the network. The manifest's `security` stanza is the summary; the directory holds the templates and data the stanza points at. Jinja loads templates **from the module first**, then from the suite's `os-security/templates` as the base layer, so a module may extend or override a base template (`{% extends "apparmor/app.j2" %}` with a block) and never has to copy it.

```
modules/<app>/
  polari-app.json                  the summary: security stanza (profile, network, caps, writable, devices, ports,
                                   proxy, channels, content, trial, groups) — validated by conform
  security/
    README.md                      developer-facing: what this app touches and why, one paragraph per file below
    proxy/
      api.conf.j2                  location/headers/rate-limit/mtls for the app's routes on the backend host
      site.conf.j2 frontend.conf.j2 agent.conf.j2   (only the scopes the app needs)
    apparmor/
      overrides.j2                 optional: extra allow/deny lines merged into the base profile's `app_extra` block
    seccomp/
      extra.json                   optional: syscalls to add to the kind's allow-list (each with a reason)
    content/
      limits.json                  per-field caps/ranges/enum overrides for the derived policies; mode floor
      exceptions.json              routes exempt from body validation (uploads), each with a reason
    channels.json                  the app-to-app and user-to-app channels it uses (to, kind, auth, key_kind)
    trial.sh                       hardware apps: the command the pkexec-traced first run executes
    groups.json                    hardware apps: host groups the trial confirmed, with the device that needed each
    generated/                     gitignored: last rendered snippet/profile/policy for inspection (`pol project security`)
```

Rules: every file is optional; a missing file means the deny-all default. `conform` checks that every path the stanza names exists, that jinja parses each template with StrictUndefined against the documented variables, that no proxy snippet carries a forbidden directive, and that `limits.json`/`channels.json`/`groups.json` use the vocabularies. `pol modules new` scaffolds the directory with the README and an `api.conf.j2` skeleton; `pol project security` renders everything for the one module into `security/generated/` and prints the ledger row, so a developer sees exactly what their stanza becomes before it is deployed. The renderers (`os-security/render.py`, the proxy composer, the content-policy deriver) all take the module directory as a jinja search path, so what a developer inspects locally is byte-identical to what the machine applies.

## 4. Proxy snippets — per-app functionality, composed when an app goes up or down

**Where a snippet lives:** in the app's `security/proxy/` directory (§3) — and the manifest's `security` stanza names it:
```json
"security": { …, "proxy": { "api": "security/proxy/api.conf.j2", "site": "", "frontend": "", "agent": "security/proxy/agent.conf.j2" },
              "channels": [ {"to": "keycloak", "kind": "app-app", "auth": "oidc-client", "key_kind": "symmetric"} ] }
```
Scopes map to the server block the snippet is injected into: `api` (the backend host), `site` (the hub host), `frontend` (the frontend host), `agent` (the isle agent's per-app fragment — rendered by us, applied by isle-core's agent; contract in NOTES-FROM-POL-CORE.md).

**What a snippet may contain:** `location` blocks for the app's own routes (`/api/<app>/…`), extra headers, `limit_req` on its heavy endpoints, `ssl_verify_client` requirements for app↔app routes, explicit `deny` of routes that must never be public. It may NOT contain `server`, `listen`, `ssl_certificate`, `upstream`, or `include` — the composer refuses those (the same posture as `pol proxy guard`). Variables available in jinja: `app`, `domain`, `backend` (the lazy `$up_*` variable), `scenario`, `route`, `mtls_ca` (path or empty), `rate_zones`.

**How it composes:** `pol proxy template <env>` (and the isle-side fragment renderer) gathers snippets for the apps that are **up** — from the registrar (`/api/modules/health`, state online) when a core is reachable, else from POLARI_MODULES — renders each with jinja2 StrictUndefined, guards it (forbidden directives; `nginx -t` on the composed file), and substitutes the concatenation at four markers in the templates: `${APP_SNIPPETS_API}`, `${APP_SNIPPETS_SITE}`, `${APP_SNIPPETS_FRONTEND}` (staging/lean/prod) and the agent fragment file per app on an isle. The rendered snippet text and its guard verdict become the `ProxySnippet` row. **App down → re-render → the snippet is gone**, exactly as AppArmor profiles already follow apps (ISLE_HARDENING_PLAN §9). Ordering: fixed pieces first, then apps alphabetically, then a per-snippet `order` key; two apps claiming the same `location` is a composer error naming both.

**The screen:** `/display/security-proxy` — the `ProxyConfig` table (route, env, guard, hardening flags), the `ProxySnippet` table (app, scope, kind, state, order), a structured panel showing the composed server blocks with each snippet's origin marked, and per-app: the app's own page gets a "Proxy" tab (per-object display config rule) listing its snippets and their live state.

## 5. Content policies — derived from the data model, observed before enforced

He is right that the derivation already exists: the DB schema of every class is derived from the class's typed `__init__` (polyTyping → `getObjectTyping`, schema stabilization freezes it). A content policy is the **same derivation pointed at the request body**:

1. **Derive.** For each class with CRUDE and each app route with a declared body, `security/content_policy.py` builds a JSON Schema from the typing: field names (unknown fields refused), types, `polariList` element types, string length caps (default 4 KiB, overridable per field by a `limits` map in the manifest), numeric ranges where the class declares them, required fields = those without defaults, max body bytes (default 256 KiB; uploads declare their own). Enum vocabularies in the class (`KINDS`, `SCOPES`, …) become `enum`. Result: one `ContentPolicy` row per target, mode `derived`.
2. **Observe.** A Falcon middleware (`ContentPolicyMiddleware`, alongside `AuthContextMiddleware`) validates every POST/PUT/PATCH body against the policy of its target and, in observe mode, **records a `ContentPolicyViolation` and lets the request through**. Violations are aggregated (target, field, reason) with hashed clients; nothing raw is stored.
3. **Test.** `pol security content test <app>` runs the app's selftests and its live-API checks (the same ones `pol modules health` reports) with the policy forced to enforce in a throwaway process; a policy that breaks a legitimate call fails the test and stays in observe with the failing call named. This is the automation "before enforcing them and testing if they still work".
4. **Enforce.** Only a tested policy with zero legitimate violations over an observation window (default 7 days, or an operator override) may be switched to enforce, and the switch is a row change with who/when. In enforce mode a bad body gets a 400 naming the field, and the violation row still increments.
5. **Re-derive on schema change.** A class change re-derives and drops the policy back to observe (the ledger shows the app's content policy regressed and why).

Browser policy is the same cycle with `Content-Security-Policy-Report-Only` first: the frontends' actual origins (own, api, auth, fonts, websocket) are read from the proxy template, the header is rendered into the proxy config, violations arrive at `/api/security/csp-report`, and enforce flips the header name.

**The screen:** `/display/security-app` — `TrustChannel` table (with `key_kind` and `verified` columns so symmetric-on-user-channel and unverified app↔app channels stand out), `AuthzRule` table, `ContentPolicy` table (target, mode, violations, tested), `ContentPolicyViolation` table, `BrowserPolicy` table; per-app "Security" tab on the app's page showing its channels and policies.

## 6. Hardware trials — pkexec first run, tracked, then a stanza proposal

His idea, adopted: a hardware app's first run happens **elevated and watched**, and the watching produces the permission configuration instead of a human guessing it.

- `pol security trial <app> [--method pkexec|complain]` (isle side: `isle app trial <app>`, contract to isle-core):
  1. Renders the app's AppArmor profile in **complain** mode and loads it; complain mode logs every access the enforced profile would have denied, without denying.
  2. Starts the app's trial command (manifest `security.trial`: the command that exercises the hardware, e.g. open the serial port, grab a frame, define the VM) under **pkexec** (polkit prompts the person in the GUI, the rule lives in a polkit action `org.polari.hardware-trial` installed by install-groups.sh; on a headless machine `sudo` with the polari-app drop-in) so the run is not blocked by missing groups.
  3. Tracks: AppArmor `ALLOWED` audit lines for the profile (auditd/journal), `/dev` opens (from the same lines plus `strace -f -e trace=openat` when available), capabilities used (`capable` audit records), network families used.
  4. Classifies what it saw into the stanza vocabulary: devices → the `devices` list and the **host groups** that own them; caps → `capabilities` (only from the allow-list; anything else is reported as "needs a guest, not a container"); paths → `writable`; sockets → `network`.
  5. Writes a `HardwareTrial` row with the observations and a `proposed_stanza`; nothing is applied. The operator reviews on `/display/security-os`, accepts, and the accepted stanza is written into the manifest (`conform` re-runs), the profile is re-rendered in **enforce**, the groups are granted (`pol deploy grant`), and the app is re-run un-elevated as the proof. Ledger: `hardware_trial` pending → done → accepted.
- Guests (KVM hardware apps) get the same trial against the libvirt sVirt profile and the host passthrough list: the trial reports which `HardwarePort` rows were touched and which were not, so passthrough can be narrowed.
- Safety: a trial never runs on a swarm node or an internet-facing scenario (refused); pkexec requires a person; the trial's elevated process is time-boxed and its profile unloaded after.

**The screen:** `/display/security-os` — `MacProfile` table (mode, loaded, denials, stale), `DacPolicy` table (rendered vs live diff column), `PermissionGroup` table (members, apps needing), `HardwareTrial` table (observations, proposal, accept action via CRUDE on `accepted`), audit results panel for the scenario.

## 7. Network domain — TLS scaffolding that lets servers verify each other

Today: one public edge certificate; per-service step-ca certificates in the cert manifest (pol-kc, prf-backend.internal, …) exist for the compose route; the isle CA issues leaves per app and the agent's nginx offers `https-mtls`; overlays are now encrypted. What is missing is that **backends do not verify each other**: anything on the internal network that can reach a backend's port can post to it. The scaffolding:

- Every service that talks to another service gets a `ServiceIdentity` (already a cert-manifest row on compose; add the lean/prod stack rows and the isle-side per-app leaf) and **app↔app routes require a client certificate from the same CA** (`ssl_verify_client on` on those locations; the backend checks the forwarded subject against the `TrustChannel` row's `from_app`). A request without the right leaf is refused at the proxy, so a foothold on the overlay cannot inject.
- Where mTLS is impractical (STOMP over websocket, gRPC bridge), the channel uses a **symmetric per-pair secret** (docker secret, generated at deploy, HMAC over the message) — this is the "servers use symmetric keys" case, and the `TrustChannel` row says so and when it rotates.
- Users never get a shared secret: browser → proxy is TLS with the public cert, user → backend is an RS256 OIDC token verified against Keycloak's JWKS (asymmetric).
- Certificates are rows with `not_after`; renewal is `ca/renew.sh` and the screen shows days left. A cert the proxy serves that the manifest does not know is a finding.
- The dynamic part: when an app comes up, its `ServiceIdentity` is issued (isle CA leaf / step-ca cert), its proxy snippets are rendered with `mtls_ca` set, its channels are re-verified (`pol security net verify` walks every `TrustChannel` and actually connects: expects refusal without a leaf, success with one); when it goes down the identity is revoked and the rows go absent.

**The screen:** `/display/security-network` — `ServiceIdentity` table (issuer, expiry, verifies/verified-by), `TrustChannel` filtered to app↔app with the verification result, `ProxyConfig` + `ProxySnippet` summary, `FirewallRuleSet` table (chain, applied, sources resolved), exposure rows linked. `/display/security-firewall` is a sub-view of the same rows for the firewall area alone.

## 8. The overview and how everything ties to the app standard

- `/display/security` — three domain panels (controls by state, findings count), the **`AppSecurityRecord` table** (every app, steps complete / total, blocking step, audit verdict) and the scenario in force. This is the "look at what is going on with all of the different pieces" screen; each domain panel links to its domain display.
- **Standardization tie-in (STANDARD_POLARI_APP.md):** the manifest gains `security.proxy`, `security.channels`, `security.content` (limits per field, mode floor), `security.trial` (the trial command) and `security.groups`; `conform` validates them (vocabularies, referenced snippet files exist, forbidden nginx directives absent); `pol modules new` scaffolds `security/proxy/api.conf.j2` and a deny-all stanza; the module README standard (§11) documents the stanza. The registrar's verifier grows a `security` piece: informational like `selftest` (never a reason for `degraded`), reported as the app's `AppSecurityRecord`. `pol modules health` prints the security column; `pol project lint` runs the security conformance on one module.
- **Recording who has been through the automation:** `AppSecurityRecord.steps` is the fixed list: stanza declared → stanza conforms → MAC rendered → MAC enforced (or complain with a reason) → DAC rendered → proxy snippets rendered and guarded → channels declared and verified → content policy derived → observed → tested → enforced → browser policy (frontends only) → hardware trial (hardware apps only) → audit passes for its scenario. Every app appears, including the ones that have done nothing (steps 0/N, blocking = "stanza declared" is present but default; "proxy snippets: none declared" is fine and counted as n/a, not missing). The ledger is exported with the release tree (`/api/release/tree` gets a `security` summary) so the hub's app cards can show "hardened / partial / open".

## 9. Documentation (public, Security section of the site)

- `SECURITY_MODEL.md` — the taxonomy, the lifecycle (derived → rendered → observed → tested → enforced), the ledger, what "hardened" means.
- `SECURITY_AUTOMATION.md` — how each generated control is produced: manifests → jinja → guard → apply, for proxy snippets, MAC/DAC, firewall, content policies, browser policies, service identities; the observe/test/enforce cycle; how a hardware trial works and what it may and may not conclude.
- `APP_SECURITY.md` (channels, symmetric vs asymmetric, authz, content policies), and the existing `PROXY_SECURITY.md`, `FIREWALL_SECURITY.md`, `NETWORK_SECURITY.md`, `OS_SECURITY.md` gain the interface paragraphs (which screen, which CLI verb).
- `modules/README.md` §11 grows the new stanza keys with one example per kind.

## 10. Phases

| Phase | Builds | Proof |
|---|---|---|
| **sec-i-0** | the module `security/` directory standard (§3: layout, conform checks, scaffold, `pol project security`, jinja search path module → suite base) and the `security` module skeleton: taxonomy seeds, `SecurityControl`, `AppSecurityRecord`, the collector that fills both from what exists today (manifests, os-security/out, proxy templates, cert manifest, audit JSON), `/display/security` + the three domain pages (tables only) | every app has a record; counts match `pol security os audit --json`; no raw JSON |
| **sec-i-1** | Proxy snippets: manifest keys, composer in `pol proxy template` (markers in the three templates), guard, `ProxySnippet`/`ProxyConfig` rows, per-app Proxy tab; agent-fragment contract to isle-core | an app with a snippet up → block present, down → gone; forbidden directive refused; `nginx -t` clean |
| **sec-i-2** | App domain: `TrustChannel` derivation (proxy templates, ServiceConnection, protocol matrix, Keycloak clients), `AuthzRule` view, findings (symmetric on user channel, unverified app↔app) | channels table matches the running lean and full stacks |
| **sec-i-3** | Content policies: derivation from typing, `ContentPolicyMiddleware` observe, violation rows, `pol security content derive/test/enforce`, re-derive on schema change; browser policy report-only | terms + vpn modules enforced after a clean test; a bad body → 400 naming the field; the selftests still pass |
| **sec-i-4** | Network: `ServiceIdentity` rows from the cert manifest + isle leaves, app↔app mTLS on the suite proxy, symmetric secrets for STOMP/gRPC, `pol security net verify` | an unauthenticated post from a container on the overlay is refused; the verify walk passes |
| **sec-i-5** | OS: `MacProfile`/`DacPolicy`/`PermissionGroup` rows from os-security + docker inspect, hardware trials (`pol security trial`, polkit action, classifier, proposal, accept → stanza → enforce), isle contract | a hardware app (printcam or sdr-rx) trialled on isle-core: proposal names the right devices and groups; runs un-elevated after accept |
| **sec-i-6** | Standardization + ledger: manifest keys in `conform`, scaffold, registrar `security` piece, `pol modules health` column, release tree summary, hub cards | 59/59 conform; ledger exported; hub shows hardened/partial/open |
| **sec-i-7** | Docs: SECURITY_MODEL, SECURITY_AUTOMATION, APP_SECURITY, interface paragraphs; site regenerated | pages parse; every screen and verb named once |

## 11. Decisions for him

- **D1** Observation window before enforce: 7 days default, or "as soon as tested"?
- **D2** Content policy scope for v1: CRUDE bodies of every class (broad) or only module API routes that declare a body (narrow)?
- **D3** App↔app auth on the suite proxy: mTLS everywhere it can be, HMAC secret only for STOMP/gRPC (recommended), or HMAC everywhere for simplicity?
- **D4** Hardware trial elevation: pkexec (GUI, a person present) with sudo fallback headless — or refuse headless entirely?
- **D5** Should a `security` failure (e.g. profile stale, policy regressed) ever mark a module `degraded` in the registrar, or stay informational like selftest? (Recommended: informational, with the hub card colour carrying it.)
- **D6** The isle agent's per-app proxy fragments: rendered by Polari and handed to the agent (contract), or rendered by the agent from the same snippet files (isle-core owns the renderer)?
- **D7** Browser CSP for the Angular frontends: allow `'unsafe-inline'` styles (Angular needs it without nonces) or move to nonce-based styles first?
- **D8** Module-level overrides of the base AppArmor profile (`security/apparmor/overrides.j2`): allowed at all, or only additive `allow` lines reviewed on the OS screen? (Recommended: additive only, and the override text is shown on the app's ledger row.)
- **D9** Which hardware app is the trial's first proof: printcam (camera + serial) or sdr-rx (USB SDR)?

## 12. What already exists that this reuses (no new engines)

os-security/ (render/apply/audit/escape-test), the manifest `security` stanza + `conform`, the registrar and its verifier, `pol proxy template|guard`, `ca/cert-manifest.conf` + step-ca/Let's Encrypt scripts, `AuthContextMiddleware`, accessControl rows, `IsleProtocolPermit` (https-mtls), `ServiceConnection`, polyTyping/schema stabilization (the derivation), the permission groups, `pol deploy grant|audit`, `module_pages_seed` (`_page/_row/_table/_sapi`), the Security docs section.
