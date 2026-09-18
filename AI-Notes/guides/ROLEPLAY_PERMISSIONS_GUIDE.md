# Operator guide — role-play → permission profiles

The frontend role menu IS built (2026-09-16) but has never been driven by eye; every step below is the `curl`
equivalent, and the whole cycle was proven this way with a real Keycloak login on 2026-09-17 (ledger §51). See
`AI-Notes/handoffs/ROLEPLAY_PERMISSIONS_HANDOFF.md` for full state + the frontend spec, and ISLE_HARDENING_PLAN
§17b for the workflow. Examples use the home staging stack, `https://api.prf.192.168.0.210.nip.io`.

## 1. Dev posture
Role-play only works in dev posture (§16b); production refuses it outright. In `.generated/prod-answers.env` set
`POL_PROD_POSTURE=dev`, then `pol prod apply` (run detached: `setsid nohup pol prod apply > /tmp/x.log 2>&1 &`;
poll the log for "stack polari-lean deployed"). Back to production: `POL_PROD_POSTURE=production` + `pol prod apply`
again. Note `pol prod apply` REWRITES the answers file from its known keys, so set posture there, not ad hoc.

## 2. Recording on/off
Default ON in dev, never in production. `GET /api/security/observe` reports the knob + open sessions.
```
curl -sk -X POST https://api.prf.192.168.0.210.nip.io/api/security/observe -d '{"recording": false}'
```

## 3. Grant the role-play permission
Its own grant, separate from any one role: admins may always; a dev instance with no `roleplay_groups` set lets
EVERYONE role-play; a list restricts it to those KC groups (production always refuses regardless).
```
curl -sk -X POST https://api.prf.192.168.0.210.nip.io/api/security/observe -d '{"roleplay_groups": ["developers"]}'
```

## 4. Create a prototype role and act as it
```
curl -sk -X POST https://api.prf.192.168.0.210.nip.io/api/security/observe/roles \
  -d '{"name": "journalist", "title": "Journalist", "description": "reporter-facing pages only"}'
curl -sk -X POST https://api.prf.192.168.0.210.nip.io/api/security/observe/session -d '{"role": "journalist"}'
```
From here every request must carry `X-Polari-Roleplay: journalist` (`curl -H "X-Polari-Roleplay: journalist"`) so
the CRUDE gate attributes and records the act. Use the product as the role would, then end the session:
`curl -sk -X DELETE '…/observe/session?role=journalist'`. Once built: a header menu (upper right, next to login)
— "Acting as: <role>", a menu of prototype roles, Stop role-play, "New prototype role…" — visible only when
`can_roleplay` is true, absent in production.

## 5. Review
```
curl -sk 'https://api.prf.192.168.0.210.nip.io/api/security/observe/review?role=journalist'
```
Returns everything touched — apps, pages, components, actions, endpoints, objects×verbs, acts, `would_deny_today`
— plus a `proposed_profile` shaped like an `AppPermissionProfile`: `kc_groups_json` (the KC group(s) it maps to),
`verbs_json` (CRUDE verbs observed per class), `extra_classes_json` (classes outside the role's home app, for the
admin to judge in or out). A suggestion only — nothing is created until the admin acts.

## 6. Concrete it
The permissions admin narrows the proposal, creates the real `AppPermissionProfile` row via CRUDE, then:
```
curl -sk -X POST https://api.prf.192.168.0.210.nip.io/api/security/observe/roles/journalist \
  -d '{"state": "concreted", "profile": "journalist"}'
```
Enforce gradually: `POLARI_APP_PERMISSIONS=advisory` first (logs would-deny without denying), then `=enforce`.

**The gate is its own `pol prod` answer (added 2026-09-17).** Do not set the container env by hand —
`pol prod apply` rewrites it. In `.generated/prod-answers.env`:
```
POL_PROD_APP_PERMISSIONS=off        # the default: the gate does nothing
POL_PROD_APP_PERMISSIONS=advisory   # verdicts computed; a would-deny rides a response header; the act STILL RUNS
POL_PROD_APP_PERMISSIONS=enforce    # a disallowed verb gets 403 (a DEV-posture build observes it instead)
```
then `pol prod apply` (detached + polled). It renders `POLARI_APP_PERMISSIONS` into `.env.lean`/`.env.prod` and
both compose files pass it to `prf-backend`. Check it landed:
`docker service inspect polari-lean_prf-backend --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' | grep APP_PERMISSIONS`

Under `advisory`, a read the profile covers returns 200 with **no** extra header; one it does not returns 200
carrying `X-Polari-Permission-Advisory: would-deny <Class>:read`. That header is the whole signal — watch for it
with `curl -D -`. **Deployed stacks stay at `advisory` or `off`** (his ruling: security is warn-only in
deployments); `enforce` is for a selftest or a deliberate, watched experiment.

**Concrete the profile well BEFORE the next deploy, then check it survived.** CRUDE writes reach the backend's
sqlite only on a later flush, so a profile row created minutes before `pol prod apply` can be lost with the
container — silently. After any deploy, re-check `GET /api/apps/permissions/profiles` before trusting the gate.

## 7. Verify, then enforce
```
curl -sk 'https://api.prf.192.168.0.210.nip.io/api/security/observe/verify?role=journalist&group=journalist'
```
Replays every recorded class×verb through `permission_verdict` as a member of the group — allowed/denied per act.
A denial means the job would break under the new profile; widen and re-review before enforcing. Once clean:
```
curl -sk -X POST https://api.prf.192.168.0.210.nip.io/api/security/observe/roles/journalist -d '{"state": "enforced"}'
```

## Claiming a role yourself (2026-09-18)

His words: *"I see no way, upon registering, to simply assign myself a role in the Polari interface. Or a way to go
from Polari to Keycloak to grant oneself permissions that anyone can just self-claim. It should not be the case all
roles can be taken by anyone, but self-proclaimable roles should be a thing, especially in dev mode."*

A role **is** a Keycloak group (the permission model reads the `groups` claim), so claiming one means joining that
group. Polari does it for you, through the `polari-backend` client's service account — you never open the Keycloak
admin console.

**The rule (plan §17b D17-5).**

| posture | what may be claimed |
|---|---|
| **dev** | EVERY `RolePrototype` row, in any state (prototype / concreted / enforced), unless an admin explicitly said no — plus whatever the `claimable_groups` knob names |
| **production** | ONLY `RolePrototype` rows flagged `self_claimable: true`, plus the `claimable_groups` knob. Nothing by default |
| **never, either posture** | `ADMIN_ROLES` (`admin`, `polari-admin`), the Keycloak groups `Polari Administrators` / `Polari Developers`, and any `polari-*` name that is not a prototype an admin flagged |

The caller must be signed in: a claim attaches to a Keycloak `sub`, so an anonymous request gets `401` and an empty
list, not a refusal to explain.

**In the browser.** Sign in, open the user menu in the header (upper right, your name) → **Claim a role…**. The
dialog lists what you may take, one Claim/Release button each, marks what you already hold, and carries a **Manage
account in Keycloak** link to the realm's own account console. The same menu has **Manage account** directly.
After a successful claim the app tries a silent re-sign-in; if that cannot be done it says so and offers
"Sign in again" — the new group only exists in a NEWLY issued token.

**Through the API.**
```
T=$(…password grant, see "Real logins" below…)
curl -sk -H "Authorization: Bearer $T" https://api.prf.<domain>/api/security/roles/claimable
curl -sk -H "Authorization: Bearer $T" -X POST https://api.prf.<domain>/api/security/roles/claim \
     -H 'Content-Type: application/json' -d '{"role": "journalist"}'
curl -sk -H "Authorization: Bearer $T" -X DELETE 'https://api.prf.<domain>/api/security/roles/claim?role=journalist'
```
`/claimable` answers `{ok, posture, authenticated, sub, roles:[{role,title,description,source,state,held,why}],
held:[…], account_url, keycloak:{ready,why}, how}`. `source` is `prototype` or `knob`. `/claim` answers
`{ok, role, group_id, group_created, note}`; the note is *"sign in again or refresh your session for the new group
to appear in your token"* — **mint a new token before checking the claim worked**, the old one still has the old
groups.

**Opening and closing roles (admin).**
```
# flag one prototype role self-claimable in production (admin bearer required — 403 otherwise)
curl -sk -H "Authorization: Bearer $ADMIN" -X POST \
     https://api.prf.<domain>/api/security/observe/roles/journalist -d '{"self_claimable": true}'
# ...or shut it off even in dev (the explicit NO lands in the observe knob, which dev posture honours)
curl -sk -H "Authorization: Bearer $ADMIN" -X POST \
     https://api.prf.<domain>/api/security/observe/roles/journalist -d '{"self_claimable": false}'
# plain KC groups (no prototype row) opened for self-service, in ANY posture
curl -sk -X POST https://api.prf.<domain>/api/security/observe -d '{"claimable_groups": ["operators"]}'
```
`self_claimable` is the only field on that route that requires an administrator: a self-claimed role must not be
able to widen its own claimability. `GET /api/security/observe` reports `claimable_groups` and `claim_denied`.

**PII — his rule, 2026-09-18.** Keycloak exists to keep personal data AWAY from Polari, so **every row and event
this arc writes identifies the person only by the opaque Keycloak `sub`** — never `preferred_username`, never an
e-mail, never a display name. The `SecurityEvent` for a claim reads
`control=role-claim, action="claim journalist", actor=<sub>, source=self-claim, would_deny=false`, and
`/api/security/roles/claimable` echoes your own `sub` rather than your name. The dialog shows your name only
because your browser already has it in your own token. (The four older observe rows still store a username —
that is a correction owed, plan §17c / design §8.)

**What the backend needs.** `POLARI_KEYCLOAK_ADMIN_URL`, `POLARI_KEYCLOAK_REALM` and
`KEYCLOAK_POLARI_BACKEND_CLIENT_SECRET` in `prf-backend`'s environment (both compose files pass them), and the
`polari-backend` service account holding realm-management `view-users` / `manage-users` / `view-realm` —
`pol-keycloak/startup_shells/configure_clients.sh` grants all three and turns `serviceAccountsEnabled` on. With no
secret the API answers **503** naming the variable rather than failing obscurely. Note the client id is pinned to
`polari-backend`, **not** `POLARI_KEYCLOAK_ADMIN_CLIENT_ID` — that variable holds `admin-cli`, a public client with
no service account, and using it answers `401 "Public client not allowed to retrieve service account"`.

**Gotchas of this section**
- A claim does not change the token you are holding. Everything that reads groups (the permission gate, `held`,
  `/api/apps/permissions/my`) keeps seeing the old set until you sign in again or the silent renew succeeds.
- Claiming a prototype role CREATES the Keycloak group if it does not exist yet — that is deliberate (D17-2 is
  answered in practice: the group appears the first time somebody takes the role).
- Release only works on roles you could have claimed. A role an administrator granted you is theirs to remove.
- `claimable_groups` is a plain list of KC group names and is NOT filtered by posture — it is the operator saying
  "these are self-service here", and it still refuses admin-shaped names.

## Names and the PII boundary (2026-09-18, his rule D18-1)

Keycloak exists to keep personal data **away** from Polari. So every person in a Polari row, event or log line is
their Keycloak **subject id** — an opaque UUID like `3f2b1c8a-9d4e-4a71-8b2c-5e6f7a8b9c0d` — and nothing else. The
`actor` column on the security-events page (SecurityEvent, PermissionObservation, UsageObservation and the
role-play sessions) holds that `sub`, not `demo-journalist`. An empty `actor` means the act was anonymous, or the
row was written before this rule and the boot scrub cleared it.

To put a name to one, ask the **one gated door** — it reads Keycloak live and Polari keeps no copy:
```
curl -s -H "Authorization: Bearer $TOK" \
  https://api.prf.<D>/api/security/people/3f2b1c8a-9d4e-4a71-8b2c-5e6f7a8b9c0d
# {"ok":true,"sub":"3f2b…","display_name":"Demo Journalist","username":"demo-journalist","why":"administrator"}
```
Who may ask: an administrator; anybody about their **own** sub; and members of a group named in the
`people_viewers` knob —
```
curl -s -X POST -H "Authorization: Bearer $ADMIN_TOK" -H 'Content-Type: application/json' \
  -d '{"people_viewers": ["approvers"]}' https://api.prf.<D>/api/security/observe
```
Everyone else gets **403** with the rule that refused; no bearer at all is **401**; a stack with no Keycloak
credential is **503 "no identity provider"** — there is deliberately no stored name to fall back on. Your own
browser showing your own name in the role menu is fine: that comes from your own token, not from Polari.

### How names appear on the security-events page (2026-09-17)

You no longer resolve subs by hand. The four `actor` columns on `/display/security-events` — SecurityEvent,
PermissionObservation, UsageObservation and the role-play sessions — are marked `actor:person`, so each cell shows
the **first 8 characters** of the subject id with the **whole id in the tooltip**, and the page resolves the names
of the rows *on screen* while it renders:

```
POST /api/security/people   {"subs": ["3f2b1c8a-…", "589384ad-…"]}     # at most 200 per call
-> {"ok": true, "people": {"3f2b1c8a-…": "Demo Journalist", "589384ad-…": null}, "denied": ["…"], "how": "…"}
```

**One call per table render**, not one per row — that is the whole point of the batch. The gate is the same one the
single door applies, *per subject id*: your own always, anybody else's only for an administrator or a member of a
`people_viewers` group. A sub you may not resolve comes back in `denied`; a sub this realm does not know comes back
`null`. Neither fails the call.

**Who sees what, then:**
- an **administrator** sees every name;
- a **`people_viewers` member** sees every name;
- **anyone else signed in** sees their own name and short subject ids for everybody else;
- **signed out**, the frontend never calls the door at all — every actor stays a short id.

A 401/403/429/503 is never shown as an error: the cell simply keeps the short id. (An operator who sees only short
ids and expected names should check the knob, not the page.)

**The cache.** Names are held in memory for **300 seconds** on each side and nowhere else:
- backend — `security.custom.security_people`, a dict in the process. Never a row, never a log line, never disk; it
  dies with `prf-backend`. `POLARI_PEOPLE_CACHE_SECONDS` changes the TTL; `0` turns caching off entirely and every
  lookup goes back to Keycloak.
- frontend — `PeopleService`'s map, for the life of the browser tab. Never localStorage, never sessionStorage.

Because of the TTL, a rename in Keycloak shows up within five minutes, and a deleted account stops resolving within
five minutes. Keycloak stays the system of record. The door also answers **60 calls a minute per caller**; past that
it is **429** with a sentence saying so and a `Retry-After` — batch, rather than asking sub by sub.

## Gotchas
- Only works in dev posture; a production-posture flip makes `can_roleplay` refuse outright — re-check
  `GET /api/security/observe/roles` after any posture change.
- Anonymous calls record as verdict `unauthenticated`, not against the role — send a real bearer (see "Real
  logins" below) so the row carries the caller's actual KC groups beside `roleplay:<role>`.
- An EXPIRED bearer is worse than none: `/api/apps/permissions/my` answers `authenticated false`, and every
  read — in-profile or not — grows the would-deny advisory header. Re-mint before concluding the profile is
  too narrow.
- `GET /api/security/observations?groups=<name>` is exact string equality against the whole comma-joined
  groups field, so it never matches a multi-group row. Fetch unfiltered and filter client-side.
- The `app` column on `PermissionObservation` fills from the feature-import table, and the review carries
  `objects_by_app`.
- Rows must be constructed as tree objects; a stray fallback to a plain object breaks the class view
  (`PolyTyping for type SimpleNamespace`) — hit once on the live stack, fixed.
- Persistence is one trailing timer per burst; counts have been proven to survive a backend restart.
- `pol …` expands `$(...)` in remote commands locally — script remote nodes with `pol iso ssh … -- cmd`, plain.

## Real logins on the lean demo (2026-09-17)

Everything above records anonymous callers as verdict `unauthenticated` until someone actually signs in. The
lean profile can now run Keycloak, so the home demo has real accounts without the full stack.

**Turn it on.** Two answers in `.generated/prod-answers.env`, then `pol prod apply`:
```
POL_PROD_AUTH=keycloak     # logins
POL_PROD_PROFILE=lean      # ...but keep the lean stack (the NEW answer; unanswered it still means "full")
POL_PROD_DEMO_USERS=on     # demonstration accounts (default: on in dev posture, off in production)
```
The stack grows from four services to six: `pol-keycloak` + `pol-kc-mariadb` (its own database, not the full
profile's shared MariaDB), about 1.4 GB. They sit behind the `logins` compose profile, so answering
`POL_PROD_AUTH=off` gives back exactly the four-service stack.

**What apply generates.** `pol-keycloak/keycloak-admin.env` (random admin password — never `admin`, which
`pol security` refuses; gitignored), `pol-keycloak/certs/pol-kc.{crt,key}` (the image will not build without
them), the Keycloak/JWKS/issuer env in `.generated/.env.lean`, the `keycloak` stanza in
`.generated/prf-runtime-config.lean.json`, and — with demo users on — `.generated/demo-users.env` holding ONE
shared password. All of it also goes to the vault (`sudo pol security vault show`).

**The accounts.** `demo-admin` (realm role `polari-admin` → `admin: true` everywhere), `demo-journalist`
(group `journalist`, role `polari-user`), `demo-scientist` (group `data-scientist`, role `polari-user`),
`demo-viewer` (role `polari-viewer`). Groups `journalist`, `data-scientist`, `operators` are created by
`pol-keycloak/startup_shells/seed_demo_users.sh` at Keycloak start. E-mails are `<name>@example.invalid`.
They all share one password and anyone who can read `.generated/demo-users.env` can sign in as the admin —
demonstration stacks only.

**A token without a browser** (the password grant is on for `polari-frontend`):
```
PW=$(grep '^DEMO_USER_PASSWORD=' .generated/demo-users.env | cut -d= -f2-)
T=$(curl -sk -X POST https://auth.<domain>/realms/Polari/protocol/openid-connect/token \
      -d grant_type=password -d client_id=polari-frontend -d username=demo-journalist -d "password=$PW" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])')
curl -sk -H "Authorization: Bearer $T" https://api.prf.<domain>/api/apps/permissions/my
```
That is how you give §4's role-play session a real identity: send `Authorization: Bearer $T` **and**
`X-Polari-Roleplay: <role>` together, and the observation lands against real groups instead of
`unauthenticated`.

**The `groups` claim.** `configure_clients.sh` now puts a group-membership mapper on `polari-frontend`
(`claim.name=groups`, `full.path=false`), because `caller_groups()` reads that claim as the grant keys and
`AppPermissionProfile.kc_groups_json` holds bare names. Without the mapper every profile grant silently misses.
Realm roles ride in `realm_access.roles` by default and also count as grant keys.

**Gotchas**
- The browser sign-in itself has NOT been eyeballed — only the discovery document, the password grant, and the
  authorization endpoint rendering its login form with `redirect_uri=https://prf.<domain>/callback` accepted.
- `redirectUri` is `https://prf.<domain>/callback` (the app's real route). The FULL profile's stanza says
  `https://prf.<domain>` and `.../silent-refresh.html`; the lean stanza uses `/callback` and
  `/assets/silent-refresh.html`, which are where the built app actually serves them.
- `modules/security/security_api.py:default_scenario()` maps `POLARI_AUTH=keycloak` to the os-security
  scenario `swarm-full`, so a lean+logins stack reads as `swarm-full` there while `pol prod harden` renders
  `swarm-lean`. Cosmetic today; do not read the security page's scenario as the stack's shape.
- The observation's `actor` column used to hold the Keycloak `sub` UUID; fixed 2026-09-17 —
  `observe_permission()` now falls back `preferred_username` → `username` → `sub`.

## Staying signed in (2026-09-18)

His report: *"my login does not seem to persist well, when I close out and reopen I am not still logged in. I do
not think a login should necessarily exist forever but accidentally closing out should not lose my login
entirely."* Two independent causes, one on each side.

**What persists, and where.** Signing in leaves three things behind:

| thing | lives in | dies when |
|---|---|---|
| access token (~15 min) | browser `localStorage`, key `oidc.user:<authority>:polari-frontend` | replaced on every renew |
| refresh token | the same entry | the SSO session below it ends |
| Keycloak SSO cookie | `auth.<domain>`, `KEYCLOAK_IDENTITY` | session cookie, unless "Remember me" was ticked |

The refresh token is what carries the login across a restart. `AuthSessionService.start()` reads the stored user
at boot; if it is expired it calls `signinSilent()` once, which redeems that refresh token straight against
Keycloak's token endpoint. No iframe and no cookie are involved, so third-party-cookie blocking cannot break it.
It never redirects on failure — the header just shows "Login".

**Cause 1 (frontend).** `oidc-client-ts` defaults its `userStore` to `sessionStorage`, which the browser destroys
with the tab, and `oidc.service.ts` never overrode it. Both tokens went with the window. `userStore` and
`stateStore` are now pinned to `localStorage`. `monitorSession` is off on purpose: Keycloak's check_session iframe
needs a third-party cookie and reports "signed out" for a live session when that is blocked.

**Cause 2 (Keycloak).** The realm's SSO idle timeout was 30 minutes, so even a kept refresh token was refused
after half an hour away. And `rememberMe` was already `true` while both RememberMe lifetimes sat at `0` — which
Keycloak reads as "fall back to the ordinary values", so ticking the box bought nothing. The lifetimes now:

| setting | value | meaning |
|---|---|---|
| `accessTokenLifespan` | 15 min | the credential on the wire — deliberately short |
| `ssoSessionIdleTimeout` | 12 h | how long a gap between visits is forgiven |
| `ssoSessionMaxLifespan` | 7 d | hard cap, active or not |
| `ssoSessionIdleTimeoutRememberMe` | 7 d | the same two, once the box is ticked |
| `ssoSessionMaxLifespanRememberMe` | 30 d | |

So: close the window and come back the same day, still signed in; tick **Remember me** and a week away is still
fine; a month is never fine. The session does expire on its own schedule — that was his own condition.

**Sign out really signs out.** The button calls `signoutRedirect()`: it drops the stored tokens *and* navigates to
Keycloak's end-session endpoint, which kills the SSO cookie. Without that second half, forgetting the tokens would
just mean the next silent renew quietly signed the person back in. If the redirect cannot be built, local storage
is cleared anyway — a half-finished sign-out must not persist across a restart now that storage is durable.

**A private/incognito window loses the login on close, by design** — the browser throws its whole `localStorage`
away. Same for "clear site data" and for a profile set to block site data (there `durableStore()` degrades to
`sessionStorage`, then to memory, rather than failing at boot).

**Resuming on landing (2026-09-18, second report).** *"hitting login seems to quickly register the login but it
does not do so automatically when I land on the site."* Two more faults. First, the restore was never running:
`app.module.ts` had two `APP_INITIALIZER`s and Angular starts them **all in one synchronous pass** — it only
`Promise.all`s the results — so `AuthSessionService.start()` ran while `runtime-config.json` was still
downloading, read "no keycloak stanza", and returned for the life of the page. Pressing Login still worked
because the `UserManager` is built lazily, by which time the config had landed. It is one chained initializer now
(`initialize().then(start)`), and `start()` also awaits `OidcService.whenConfigured()` so the race cannot come
back. Second, "no local tokens but Keycloak still has a session" was unreachable: the only route to it was
oidc-client-ts's hidden `prompt=none` iframe, and `prf.<host>.nip.io` / `auth.<host>.nip.io` are separate
**sites** (`nip.io` is on the Public Suffix List), so the SSO cookie is third-party and withheld — the frame
answers `login_required`, or times out after ten seconds, for a session that is alive. So the boot ladder is now:

| on landing | what happens |
|---|---|
| live user in `localStorage` | used as-is, no network |
| expired user **with** a refresh token | `signinSilent()` — refresh grant against the token endpoint, no frame, before any redirect |
| no usable user, `polari-sso-checked` unset | **one** top-level `signinRedirect({prompt:'none'})` — check-sso, the way Keycloak's own adapter does it when iframes can't work |
| no usable user, flag set | nothing. Anonymous, no redirect |
| no `keycloak` stanza (lean) | nothing. There are no logins here |

The return leg lands on `/callback`. A code means an ordinary sign-in and the flag is cleared. `login_required` /
`interaction_required` means nobody is signed in: the flag goes into `sessionStorage`, the person is put back on
the path they asked for, and **no error UI is shown** — they never pressed Login. `sessionStorage`, not
`localStorage`, on purpose: a new window deserves a fresh ask, which is how someone who signed in elsewhere gets
picked up. Sign-out pre-sets the flag before the end-session redirect, so "sign out, then land again" costs no
round trip. A loop fuse (two launches inside 30 s) covers the paths where the return leg cannot set the flag.

**Where it is set.** `polari-platform-angular/src/app/services/auth/oidc.service.ts` (the stores) and
`pol-keycloak/startup_shells/configure_clients.sh` (the lifetimes, re-asserted on EVERY Keycloak boot as an
idempotent read-patch-PUT of the live realm). `realm-imports/polari-realm.json` carries the same values but is
read **only when the realm does not yet exist** — never edit only that file and expect a deployed realm to change.

## Roles and apps: my apps (2026-09-18)

His words: *"We want to be able to have a primary role and additional roles. We will want to be able to tie Apps to
roles so that the user can see and navigate to the apps they need more easily. And then the user should be able to
refine that further and add apps they want to use or remove ones they do not care about."*

Three layers, in this order, and the layering is the whole design.

| layer | where it lives | who decides |
|---|---|---|
| **institutional** — role → apps | `RoleAppBinding` rows (`polariapps`) | the modules themselves (a manifest's `app.roles`), or an administrator, or an accepted role-play review |
| **held** — which of those roles are yours | the `groups` claim of your token | Keycloak. Nothing is stored in Polari, so a binding can never claim a role you do not hold |
| **personal** — your primary role, your additions, your hidden apps | `UserAppPreference` rows, keyed by your Keycloak `sub` alone | you |

**Hiding an app hides it.** It grants nothing and revokes nothing — permission stays with the
`AppPermissionProfile` gate (`accessControl/app_permissions_gate.py`). "My apps" is navigation.

**Where the bindings come from.** A module declares the roles its capability serves in its own
`modules/<pkg>/polari-app.json`:

```json
"app": { "kind": "polari-app", "…": "…", "roles": ["journalist"] }
```

Every Polari-App whose `modules_json` carries that module is then bound to the named roles. The key is hand-set
(it survives `python3 -m moduleService.manifests generate <module>`) and validated — a role name is a plain
Keycloak **group** name, so no slashes, no spaces and nothing `@`-shaped. The older `personas` list is the
**fallback**: where a persona name *is* a role name that no manifest declared (`researcher`,
`materials-scientist`, …), it becomes a binding marked `derivedFrom: personas`. A declaration always beats the
fallback, and a derivation **never** overwrites a binding an administrator set.

**In the browser.** Signed in, the side menu's first group is **My apps** — your primary role's apps first, then
your additional roles', then anything you added (pinned). The `tune` icon beside the heading, and "Edit my apps…"
at the bottom of the group, both open `/apps`; every card there carries one button (**+ add** / **− hide** /
**↺ restore**) and a chip saying which role brings it, with everything you hid listed at the top of the page ready
to restore. The header's user menu carries **Primary role: \<role\>** with a submenu of the roles you hold —
picking one reorders My apps. Someone holding no roles sees the catalogue exactly as before; an anonymous
visitor sees nothing new at all.

**Through the API.**
```
T=$(…password grant, see "Real logins" below…)
# every binding, with each one's source (manifest | admin | prototype-review)
curl -sk https://api.prf.<domain>/api/apps/roles

# your own view: held roles, primary role, the apps, what you hid, what to restore
curl -sk -H "Authorization: Bearer $T" https://api.prf.<domain>/api/apps/mine

# refine it — any combination of the four keys, all optional
curl -sk -H "Authorization: Bearer $T" -X POST https://api.prf.<domain>/api/apps/mine \
     -H 'Content-Type: application/json' \
     -d '{"primary_role": "journalist", "remove": ["judicial-lean"], "add": ["app-topology-network"]}'
curl -sk -H "Authorization: Bearer $T" -X POST https://api.prf.<domain>/api/apps/mine \
     -H 'Content-Type: application/json' -d '{"restore": ["judicial-lean"]}'
```

`GET /api/apps/mine` answers `{ok, sub, held_roles, primary_role, additional_roles, apps:[{name,title,route,via,
role,removable}], removed:[…], suggestions:[…], unboundRoles}`. `via` is `primary` | `additional` | `added`.
`primary_role` is the one you stored when you still hold it, otherwise the first held role that has a binding,
otherwise `''`. `suggestions` are the apps you hid that a role of yours still binds, so you can put them back.
**Anonymous gets `401`** — this answer is about one person, and a person is a Keycloak `sub`. Someone whose roles
bind nothing gets an empty list and no error.

**Binding a role by hand (admin).**
```
# what the role-play review says the role actually USED — a SUGGESTION, nothing is bound
curl -sk https://api.prf.<domain>/api/apps/roles/journalist/suggested

# bind it (ADMIN_ROLES only: admin, polari-admin — 401 anonymous, 403 otherwise)
curl -sk -H "Authorization: Bearer $ADMIN" -X POST https://api.prf.<domain>/api/apps/roles/journalist \
     -H 'Content-Type: application/json' \
     -d '{"apps": ["app-scorecards-data-analysis", "app-policy", "dmv-policy-analysis"]}'
```
The list is **ordered** — that is the order the person sees. An unknown app name is refused with the known list
rather than silently dropped. Once set, the binding's `source` is `admin` and the manifest derivation leaves it
alone for good; delete the row to go back to the derived one.

**The demo bindings** (`app.roles` on seven module manifests, deliberately 3–6 apps each): `journalist` ←
`scoring` + `nutrition` (judicial-lean, dmv-policy-analysis, app-policy, app-scorecards-data-analysis,
nutrition-planner); `data-scientist` ← `magnetics` + `mathshapes` (app-magnetics, app-materials-science,
app-mechanical, engine-cad, wax-print-shop); `operators` ← `waxprint` + `gears` + `bizops` (wax-print-shop,
app-magnetics, app-mechanical, app-business). Eleven more bindings come from the persona fallback.

**PII.** `UserAppPreference` has no username, e-mail or display-name column and never will: the row id **is** the
Keycloak `sub` (his rule D18-1). `RoleAppBinding.updated_by` holds a sub as well. Names are resolved at render
time through `GET /api/security/people/{sub}` and nowhere else.

## Your tailored home (2026-09-18)

His words: *"If you have my apps selected or a role selected, and apps exist that are assigned to those roles, we
should have a secondary landing page you can land on that lets you choose from your own apps. It should still be
possible to go to the main Polari Home page via another route, but when logged in as your user it takes you to
your tailored home page."*

There are now **two homes**, and one rule decides which one you get.

| route | page | who lands here |
|---|---|---|
| `/` | the main Polari home — **or** a redirect to `/home` | everybody; the redirect happens only under the rule below |
| `/home` | **your tailored home**: your own apps as cards | anybody who asks for it; it has nothing tailored to say to an anonymous visitor |
| `/polari` | the main Polari home, always, no redirect | the "Polari home" link, and anybody who wants the main page on purpose |

**The rule.** Landing on the bare `/` takes you to `/home` when **all** of these hold: you are signed in, at least
one app is in your My apps (§57 — a role of yours binds it, or you added it), you have not asked for the main page
this session, and no shell clamp (`?shellApp=`) is in force. Otherwise `/` renders the main Polari home exactly as
it always did. **A deep link is never redirected** — the guard is on the bare landing route and on nothing else —
and an anonymous visitor never even costs a round trip, because the check reads the auth session before asking the
backend anything.

**Staying on the main page.** Clicking **Polari home** on the tailored page takes you to `/polari` *and* remembers
the choice for the browser session (sessionStorage `polari-home-choice` = `polari`), so `/` stops bringing you back
until you change your mind. `?home=polari` on the landing does the same thing without the click — useful in a
bookmark. Opening `/home` yourself, or `?home=mine`, lifts the choice again. Nothing about it is stored on your
row; a new tab starts fresh.

**What the page shows.** One call — `GET /api/apps/mine` — rendered as the /apps catalogue's own cards, in three
groups: **Your primary role: \<role\>** (with the accent edge the side nav uses for the same apps), **Additional
roles** (each card chipped with the role that brings it), and **Added by you** (what you pinned). Each card opens
the app's own home, `/app/<name>`. Above them: **Polari home**, **Choose your apps** (→ `/apps`, where you add and
hide), a note of how many apps you have hidden, and — only if you hold more than one role — a **Primary role**
switch, the same call the header menu makes. Hold no roles, or roles that bind nothing, and the page says so
plainly and points at the catalogue; it is never an error.

**The logo.** The header's Polari mark is now the way home, and it asks the same question, so the logo and the
landing can never disagree: your tailored home when you have one, the main Polari home otherwise.

**A locked shell still wins.** `?shellApp=<name>` clamps the whole browser session to one app (sep-0); the clamp
guard runs first and sends `/`, `/home` and `/polari` alike to that app's home. Neither home exists inside a
clamped shell.
