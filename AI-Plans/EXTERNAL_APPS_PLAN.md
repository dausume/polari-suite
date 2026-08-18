# External-accessing apps — plan (DRAFT, written for Dustin's review)

**Date:** 2026-08-10 · **Status:** PLAN ONLY — no build yet.
Depends on: exposure/URL work (MESH_APP_CONVERGENCE_HANDOFF §44–§45b),
the JCEF app-shell (polari-app-shell), the app store (§polari-app-store).

## 0. The goal (Dustin, verbatim intent)

Prove that apps OUTSIDE the isle can work at all. Build "external
accessing apps" in two phases:

1. **External JCEF apps** — more JCEF desktop apps that reach a
   service **through the exposure port over wifi**, NOT through
   isle-mesh routing (no `.isle` DNS, no isle CA, no membership).
   The minimal conceptual test: *can a non-member app reach an
   isle service through the door?*
2. **Android + iPhone apps** — mobile apps that access the same way
   from outside, mirroring the JCEF result.

This is a deliberate probe of the concept before investing in the
mobile surface.

## 1. What exists to build on

- **The exposure door** (`isle url expose <internal>.isle --port P
  --user U`, §45/§45b): a gateway container on a DESIGNATED
  entrypoint device publishes `0.0.0.0:P` and proxies INTO the isle
  through the agent (SNI = the internal name), with level-1 basic
  auth. PROVEN reachable from pol-core AND econ-core over the home
  LAN (`http://192.168.0.24:18080` → 200, 401 without creds). The
  door proxies WebSocket Upgrade headers already.
- **The JCEF app-shell** (polari-app-shell): builds a native window
  onto a URL from a ShellConfig — CA pinning, reachability probe,
  OIDC/PKCE, per-app launcher debs, WM_CLASS/icon identity. Today
  every shell points at a `.isle` URL (internal, mesh-routed, isle
  CA).
- **Mobile shells** (§polari-app-store): android phone/VR APKs +
  iOS sources exist, currently mesh-oriented (isle CA + on-mesh).
- **URL bindings model** (§44, designed): services can carry
  EXTERNAL URLs mirroring the internal format under an exposure
  domain; deployments depend on URL info (dependency tracking).

## 2. THE MODEL (Dustin's correction, 2026-08-10)

External apps target the **ADDITIONAL EXPOSED URLs** — the whole
point of the additional-URL capability (§44/§45): a `.isle` service
gains a mirrored external name (`api.polari.isle` → `api.polari.org`
under a chosen exposure domain). **Those specifically-exposed
additional URLs are what is made available externally — nothing
else.** Two rules define the model:

1. **Additional URL, ON TOP OF the exposure.** The exposure port is
   the transport; the additional external URL is the named surface
   layered on it. An external app references the EXTERNAL URL
   (`api.polari.org`), which resolves off-mesh to the exposure —
   never a `.isle` name (`.isle` stays internal, agent-only). So an
   externally-served instance's `runtime-config` uses its ADDITIONAL
   URLs; that is not a new mechanism to invent, it is the reason the
   additional-URL capability exists.
2. **Real internet TLDs, proxy-enforced.** `.isle` is NEVER
   externally accessible — full stop. External names are real
   internet-valid domains we specifically add (`.org`, `.com`,
   …: `api.polari.org`). **The nginx proxies are the enforcement
   point**: they are configured so the added external names are the
   ONLY server_names answered on the external side; a request for
   any `.isle` name (or any name without an added external mapping)
   is not served externally. The allowlist is the proxy config
   itself, not a convention.
3. **Keycloak-only gating, at EVERY level.** Access to the exposed
   external URLs is gated through Keycloak ONLY (OIDC/forward-auth) —
   there is NO separate credential store. The two levels differ
   only in the allow-rule Keycloak checks:
   - **Level 1** = a SINGLE Keycloak user is allowed (one person).
   - **Level 2** = a Keycloak GROUP is allowed (its members).
   Same mechanism (authenticate via KC → check the allow-rule), one
   or many identities.

> **CORRECTION to §45b (built):** the `isle url expose --user`
> door I built uses an htpasswd/basic-auth file — a SEPARATE
> credential store. That does NOT match this model and must be
> reworked: the door authenticates against KEYCLOAK
> (oauth2-proxy / nginx `auth_request` → KC), with level 1 = allow
> exactly one KC user, level 2 = allow a KC group. The htpasswd
> path is retired once KC-backed gating lands. (Prerequisite:
> Keycloak reachable at its own external URL.)

**Allowlist by construction:** only services you explicitly mint an
external TLD URL for are reachable externally (the proxy answers
only those names), and each is KC-gated (level 1 or 2). Everything
else stays `.isle`-only and internal.

Consequence for the SPA: an externally-served polari references its
additional URLs (`polari.org` / `api.polari.org` / the KC external
name) instead of `.isle` — so it loads AND works off-mesh, and its
login rides the same Keycloak. Keycloak therefore needs its own
additional external URL too (its own isle citizen + external
binding, §44).

## 3. Phase 1 — external JCEF app (the concept test)

Prerequisites (the model, §2): (i) the nginx proxy answers the
added external TLD name(s) and NOTHING `.isle` on the external side;
(ii) Keycloak reachable at its own external URL as the gate;
(iii) KC-backed door gating (level 1 = one KC user).

Sequence smallest-proof-first:

### 1a. Transport proof (a service with an external TLD URL)
- Give a simple service (`whoami`) an external TLD name via the
  proxy (`whoami.<exposure-domain>`); build a JCEF shell whose
  ShellConfig `webUrl = https://whoami.<exposure-domain>`,
  `accessibility_scope = external`, NO isle CA. Gate it with KC
  (level 1 — one user) or prove ungated transport first, then add
  KC (decision below).
- Success: the JCEF window renders the service over wifi, as a
  non-member, via the external TLD name (never `.isle`). Confirms
  the proxy-answers-only-external-names rule + JCEF + WebSocket
  upgrade traverse the boundary.

### 1b. SPA proof (polari via its external URLs, KC-gated)
- Serve a polari instance whose `runtime-config` uses its EXTERNAL
  TLD URLs (`polari.<dom>` / `api.polari.<dom>` / the external KC
  name), not `.isle`; the proxy answers exactly those externally.
- Build a JCEF shell pointed at the frontend external URL; verify
  Keycloak login (OIDC/PKCE — the shell already does this), API
  calls, STOMP/wss all work from the non-member client, gated by KC
  ONLY (level 1, one user, to start).
- Hard prerequisites: polari, its api, and keycloak each need an
  external TLD name + UrlBinding + a proxy server_name.

### Design decisions to settle (Phase 1)
- **TLS posture**: external TLD URLs should be HTTPS with a real
  cert for the external name (cert-mode knob). Decide whether the
  on-wifi concept proof may start on HTTP or must be HTTPS from the
  first external URL.
- **KC gating sequencing**: gate 1a too (KC from the very first
  external app), or let 1a be an ungated transport smoke-test and
  introduce KC at 1b? (Model = KC-only always; only sequencing is
  in question. Level 1 = one KC user for the concept test.)
- **"External" scope today**: the proxy binds the entrypoint's LAN
  IP — the external name is reachable off-MESH (non-member over
  wifi) but not yet off-LAN. TRUE internet reach = router-forward +
  public DNS for the exposure domain + real certs (§45). Phase 1
  proves the non-member concept over wifi; off-LAN is a later step.
- **Registry model**: `accessibility_scope = external` on the
  ShellConfig instance; probe = the external URL; auth = KC; no
  isle CA pin. Keep external + mesh shells distinguishable.

### Phase 1 success criteria
A JCEF app on a device that is NOT an isle member, over wifi, opens
an isle-hosted service via its EXTERNAL TLD URL (proxy-served,
KC-gated) — first a simple service (1a), then a full polari instance
with login + live data (1b).

## 4. Phase 2 — Android + iPhone external apps (mirror)

- Reuse the external ShellConfig shape from Phase 1 in the mobile
  shells (they already exist for the mesh case): point them at the
  external TLD URL(s), KC auth, no isle CA.
- The external-URL work (§2) is shared — mobile gets it for free
  once the proxy serves the external names + runtime-config uses
  them.
- iOS build needs a Mac (standing constraint — Dustin has iOS
  phones, no Mac); Android buildable here.
- Success: an Android (then iPhone) app reaches the same isle
  service via its external TLD URL, KC-gated, mirroring the JCEF
  proof — ideally off-LAN once the router-forward + public-cert
  step lands.

## 5. Dependency ladder (what must exist, in order)

1. External TLD names on the nginx proxy — the proxy answers the
   added `.org`/`.com` server_names externally and NOTHING `.isle`
   (§2 rule 2). Plus the served content's runtime-config referencing
   those external URLs.
2. Keycloak reachable at its own external TLD URL (its own isle
   citizen + binding, §44) — the gate.
3. KC-BACKED door gating (retires the §45b htpasswd door):
   oauth2-proxy / nginx `auth_request` → KC; level 1 = one KC user,
   level 2 = a KC group.
4. External JCEF ShellConfig variant (accessibility_scope=external,
   external TLD URL, KC auth, no isle CA).
5. (for off-LAN) router port-forward + public DNS for the exposure
   domain + real certs (§45).
6. Mobile shells reuse #1–#5.

## 6. Open questions for Dustin (decide before build)

- HTTPS from the first external URL, or start the on-wifi proof on
  HTTP?
- One proxy vhost with path routing (frontend + api + auth behind
  /paths on one external name) vs one external name per service
  (`api.` / `auth.` mirroring)? (Path routing = one name, simpler
  DNS/cert; per-name = cleaner mirror of the internal structure.)
- Is Phase 1 "non-member over the home wifi" enough to call the
  concept proven, or must it be genuinely off-LAN (router forward)
  to count?
- Rework the §45b door to KC-backed BEFORE Phase 1a (KC gating from
  the first external app), or after the transport smoke-test?

## 7. Explicit non-goals (this plan)

- No new networking/routing in the isle (the door already exists).
- Not building it yet — this is the plan for review.
- Off-LAN/internet exposure is scoped but deferred to after the
  on-wifi concept proof.
