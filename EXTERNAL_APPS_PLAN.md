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

## 2. THE load-bearing insight (why this isn't just "open a port")

Opening a port makes the TRANSPORT reachable. But an app's CONTENT
must reference URLs the external client can actually reach:

- **Static/simple services** (whoami) work through the door
  immediately — no internal URL references.
- **The polari SPA does NOT**: its `runtime-config.json` hardcodes
  `api.<instance>.isle` for the backend + `wss://…isle` for STOMP.
  An external client that loads the frontend through the door then
  tries to reach `api.polari.isle` — which it CANNOT resolve (no
  `.isle` DNS off the mesh). The page loads; the app is dead.

So external access = the door **+** the served content referencing
**external-reachable URLs**. That ties directly to the UrlBinding /
exposure-domain-mirroring work (§44/§45): an external app needs an
external backend URL, not the `.isle` one. Two ways to supply it:

- **(a) per-exposure runtime-config**: the door (or a frontend
  variant behind it) serves a `runtime-config.json` whose backend
  points at the EXTERNAL door for the API (e.g.
  `http://<entrypoint>:<apiPort>`), not `.isle`. Cleanest; makes
  the door self-contained.
- **(b) shell-injected config**: the JCEF shell overrides the
  backend URL client-side. Shell-only; doesn't help browsers/mobile.

Plan picks **(a)** as the durable path (works for JCEF, browser,
AND mobile); (b) stays a possible shell shortcut.

## 3. Phase 1 — external JCEF app (the concept test)

Sequence smallest-proof-first:

### 1a. Transport proof (a service with no internal URL refs)
- Expose `whoami` (or a static page) on a port; build a JCEF shell
  whose ShellConfig `webUrl = http://<entrypoint-ip>:<port>`,
  `accessibility_scope = external`, NO isle CA, basic-auth
  credential supplied/prompted.
- Success: the JCEF window renders the service over wifi, as a
  non-member, through the door. Confirms JCEF + door + auth +
  (for polari later) WebSocket upgrade all traverse the boundary.

### 1b. SPA proof (polari through the door)
- Stand up an external-facing runtime-config for a polari instance:
  backend + ws URLs = the EXTERNAL door(s), not `.isle`. Needs TWO
  doors (frontend port + api port) OR one door with path routing.
- Build a JCEF shell pointed at the frontend door; verify: login
  (OIDC — Keycloak must ALSO be reachable externally → ties to
  "keycloak as its own isle citizen, re-basable" §44), API calls,
  STOMP/wss all work from the non-member client.
- This is where the URL-manager work becomes a hard dependency:
  polari + its api + keycloak each need an external binding.

### Design decisions to settle (Phase 1)
- **TLS posture**: Phase-1 doors are plain HTTP on the LAN (fast
  concept proof) — HONEST that it's unencrypted; real external =
  HTTPS with a cert for the external name (cert-mode knob) BEFORE
  any off-LAN use. Decide: prove on HTTP first, or go straight to
  HTTPS on the exposure domain?
- **Auth surface**: level-1 basic auth (door) vs level-2 Keycloak
  group (§45b). The polari SPA wants OIDC anyway → Phase 1b likely
  needs KC external. Basic-auth suffices for 1a.
- **"External" scope today**: the door binds the entrypoint's LAN
  IP — "external to the ISLE" (non-member over wifi), not yet
  internet. TRUE off-LAN needs router port-forward + public DNS +
  real certs (the api.polari.org mirroring, §45). Phase 1 proves
  the non-member-client concept; off-LAN is a later step.
- **Registry model**: `accessibility_scope = external` on the
  ShellConfig instance; probe = the door URL (200 after auth), no
  isle CA pin. Keep external + mesh shells distinguishable.

### Phase 1 success criteria
A JCEF app on a device that is NOT an isle member, over wifi,
opens an isle-hosted service through the exposure port — first a
simple service (1a), then a full polari instance with login + live
data (1b).

## 4. Phase 2 — Android + iPhone external apps (mirror)

- Reuse the external ShellConfig shape from Phase 1 in the mobile
  shells (they already exist for the mesh case): point them at the
  external door URL(s), external auth, no isle CA.
- The runtime-config-external work (§2a) is shared — mobile gets it
  for free once the door serves external URLs.
- iOS build needs a Mac (standing constraint — Dustin has iOS
  phones, no Mac); Android buildable here.
- Success: an Android (then iPhone) app reaches the same isle
  service externally, mirroring the JCEF proof — ideally off-LAN
  once the router-forward + public-cert step lands.

## 5. Dependency ladder (what must exist, in order)

1. Per-exposure external runtime-config (§2a) — the enabler.
2. Keycloak reachable externally (its own binding, §44) — for the
   polari SPA login (Phase 1b+).
3. External JCEF ShellConfig variant (accessibility_scope=external,
   door URL, basic/KC auth, no isle CA).
4. (for off-LAN) router port-forward + public DNS + real certs on
   the exposure domain (api.polari.org mirroring, §45).
5. Mobile shells reuse #1–#4.

## 6. Open questions for Dustin (decide before build)

- HTTP-on-LAN first, or HTTPS-on-exposure-domain from the start?
- One door with path routing (frontend + api + auth behind /paths)
  vs a door per service? (Path routing = one port, simpler DNS;
  per-service = cleaner mirroring of `api.` / `auth.` names.)
- Is Phase 1 "non-member over the home wifi" enough to call the
  concept proven, or must it be genuinely off-LAN (router forward)
  to count?
- Level-1 basic auth acceptable for the concept test, or require
  level-2 (Keycloak group) from the start?

## 7. Explicit non-goals (this plan)

- No new networking/routing in the isle (the door already exists).
- Not building it yet — this is the plan for review.
- Off-LAN/internet exposure is scoped but deferred to after the
  on-wifi concept proof.
