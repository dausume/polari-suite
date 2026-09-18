# Handoff — dev-mode observe, permission observations, ROLE-PLAY → profiles (2026-09-16, emergency handoff)

Written while the Fable budget was running out. Everything below is on `dev` and pushed. The home staging stack
(`https://api.prf.192.168.0.210.nip.io`, `https://prf.192.168.0.210.nip.io`) runs in **dev posture** (answer
`POL_PROD_POSTURE=dev` in `.generated/prod-answers.env`; `pol prod apply` renders `POLARI_POSTURE=dev`). Put it back
with `POL_PROD_POSTURE=production` + `pol prod apply`.

## His rules (verbatim intent, 2026-09-15/16)

1. Dev builds: security deliberately does NOT block, it WARNS; everything testable via APIs; dynamic connections form
   without breaking on security. Dev apps = a variant where security does not work, on purpose. (§17, built.)
2. "Track in dev mode which permission profiles and roles perform what actions — the primary route of working out
   permission profiles for app-level security." (built: PermissionObservation)
3. "Observations should count how many times they occurred and not duplicate themselves." (fixed + proven across a restart)
4. "Enable and disable that functionality on the fly." (built: the knob)
5. Frontend tracking under ROLE-PLAY: "if I go into a frontend role-playing as a Journalist … it should track that
   while I am in dev mode and have it enabled, and when I review the Journalist role/group it should show all of the
   apps and pages and functionality and objects used … passed to a permissions admin to concrete into a solid
   Journalist Permissions Role/Group that gets enforced. Then after the enforcement we ensure they can still do their job."
6. "Prototype roles: role-playing as one lets you do anything and records your actions to build the profile as a
   template. A role menu in the upper right of the header with the login information. The role-play permission is
   its own unique permission that can apply to any non-admin role; holders can act as any role."
7. Record documentation + planning, maintain this handoff, orchestrate non-Fable agents wherever possible.

## What exists (backend — polari-framework, all pushed)

| piece | where | state |
|---|---|---|
| posture switch | `moduleService/posture.py` (`state/posture/is_dev`; env `POLARI_POSTURE`, else `/etc/polari/posture.json`, expiry honoured) | built, tested |
| observe mode | `modules/security/custom/security_observe.py`: `decide()`, `OBSERVED_CONTROLS` / `INVARIANT_CONTROLS`, `SecurityEvent` rows | built; threaded into the CRUDE permission gate (`accessControl/app_permissions_gate.py`), peer admission (`polariPeers/agreements_api.py`), join-flow TLS (`polariPeers/join_flow.py`) |
| permission observations | `PermissionObservation` rows (groups × class × verb, counted; verdict granted-by-profile / admin / would-deny / unauthenticated / ungated) — recorded by the CRUDE gate in dev even with `POLARI_APP_PERMISSIONS=off` | built; **proven live: counts, no duplicates, survive a restart** |
| the knob | `knob_state/set_recording/recording_on`; file `<data>/security/observe.json` (`POLARI_OBSERVE_KNOB` override); default ON in dev, never in production | built, tested |
| role-play sessions | `ObservationSession` rows; `start_session/end_session`; header `X-Polari-Roleplay: <role>` plumbed by `accessControl/roleplay_observer.py` (middleware registered in `polariServer.py`); the gate attributes acts to `roleplay:<role>` beside the real groups | built, tested |
| usages | `UsageObservation` rows (role × kind × item; kinds app/page/component/action/endpoint/object); endpoints recorded by the middleware, the rest POSTed by the frontend | built, tested; frontend half NOT built |
| prototype roles | `RolePrototype` rows (prototype → concreted → enforced); `create_prototype/mark_prototype/prototypes` | built, tested |
| the role-play permission | `can_roleplay(user_info)`: admins always; dev instance with no `roleplay_groups` set → everyone; with a list → those KC groups; production → nobody. Set with `POST /api/security/observe {"roleplay_groups": [...]}` | built, tested |
| review / verify | `review(role)` = apps, pages, components, actions, endpoints, objects×verbs, acts, would-deny-today, `proposed_profile` (AppPermissionProfile shape), the handoff text; `verify(role, group)` replays every recorded class×verb through `permission_verdict` as a member of the group → allowed / denied / verdict | built, tested |
| surfaces | `/api/security/events`, `/api/security/observations`, `/api/security/observe` (GET/POST), `/observe/session` (POST/DELETE), `/observe/usage` (POST, batch `items`), `/observe/review?role=`, `/observe/verify?role=&group=`, `/observe/roles` (GET/POST), `/observe/roles/{name}` (POST state); page `security-events` (events, observations, derived profiles, usages, sessions); notice `observe-mode`; audit control `ssh/observe-mode` | built |
| dev variants of apps | store form `dev` → `polari-dev-<m>` (preinst refuses on a production route / outside dev posture); manifest `security.devVariant` | built; `polari-dev-gears` generated live |
| selftests | security 88/91 (the 3 failures — ledger mac_enforced, mac profiles, expired internal certs — fail identically before this arc: environment), appstore apps_api 37/37, iso 51/51, manifests 8/8 | run: `cd polari-rf-node/polari-framework && PYTHONPATH=.:modules python3 modules/security/security_selftest.py` |

Security module class count is now 31 (`security_selftest` asserts it; bump when adding rows; register every new row
in `security_basis.py`, `objects/security/__init__.py`, `security_seed.py`, `polariApiServer/feature_imports.py:1243`,
`polariApiServer/polariServer.py:~1210`, then `PYTHONPATH=.:modules python3 -m moduleService.manifests generate security`).

## UPDATE 2026-09-16 (later the same day): the frontend half IS BUILT and DEPLOYED

A non-Fable agent built it from the spec below: `src/app/services/roleplay.service.ts`, `src/app/interceptors/roleplay.interceptor.ts`
(registered after AuthErrorInterceptor), `src/app/components/header/roleplay-menu.component.ts` (in `header.html` left of the
login/user button; renders only when the API says `can_roleplay`), page/app usage posted from `AppComponent`'s NavigationEnd
handler, menu-panel styles in `src/styles.css` (theme tokens). `ng build --configuration=production` passes. Commits:
polari-platform-angular `0f86756`, polari-rf-node `75e9ba1`, suite `c20b021`. Deployed with `pol prod apply`; the live bundle
carries `X-Polari-Roleplay`; `/api/security/observe/roles` answers `can_roleplay: true` on the dev-posture stack; a usage POST in
the service's exact wire shape landed in the journalist review. NOT DONE: an action directive (`{kind: 'action'}`, optional) and
a BROWSER PASS by eye (the Chrome extension was not connected) — the menu layout, the inline "new prototype role" form inside the
mat-menu overlay, and dark mode are unconfirmed visually. The backend `app` column now fills (class → module) and the review
carries `objects_by_app`. Ledger §49 has the live backend proof.

## The original frontend spec (built as above; kept for reference)

Repo: `polari-rf-node/polari-platform-angular` (Angular, NgModule style; interceptors via `HTTP_INTERCEPTORS` in
`src/app/app.module.ts:441`; backend base URL from `PolariService.getBackendBaseUrl()`; the header is
`src/app/components/header/header.{ts,html}` (standalone, imports Material modules); the login area is the
`<ng-container *ngIf="currentUser">` block at `header.html:80`; `AppComponent` subscribes `NavigationEnd` at
`src/app/app.component.ts:146` and exposes `currentApp: AppNav | null`; `AppsNavService.appForUrl(url)` maps a URL to
the app; `ThemeService` (`src/app/services/theme.service.ts`) is the localStorage idiom to copy).

Build (in this order; `ng build` must pass — `Dockerfile.prod` runs `ng build --configuration=production`):

1. `src/app/services/roleplay.service.ts` (`providedIn: 'root'`): `role$: BehaviorSubject<string>` from
   `localStorage['polari-roleplay']`; `state$` = the last `GET {base}/api/security/observe/roles` (fields:
   `roles[]`, `can_roleplay`, `why`, `open_sessions[]`) refreshed on load and every 5 min;
   `start(role)` → `POST /api/security/observe/session {role}` then set `role$`; `stop()` → `DELETE
   /api/security/observe/session?role=<role>` then clear; `createPrototype(name, title, description)` → `POST
   /api/security/observe/roles`; `usage(items: {kind, item, app?, page?, detail?}[])` → `POST
   /api/security/observe/usage {items}` (fire-and-forget, batched every 2 s, dropped when no role is active).
   Only ever talk to the backend when `state$.posture === 'dev'` is implied by `can_roleplay` being present.
2. `src/app/interceptors/roleplay.interceptor.ts`: when `role$` is set and the request URL starts with the backend
   base URL, add header `X-Polari-Roleplay: <role>`. Register after `AuthErrorInterceptor` in `app.module.ts`.
3. Page/app usage: in `AppComponent`'s `NavigationEnd` handler (after `bindAppContext`), when a role is active post
   `{kind: 'page', item: urlAfterRedirects, app: currentApp?.name}` and, when the app changed, `{kind: 'app',
   item: currentApp.name}`. Component/action usage: a tiny `RoleplayUsageDirective` (`[polariAction]="'publish-article'"`)
   posting `{kind: 'action', item, app, page}` on click — wire it only where cheap; the page + endpoint record already
   covers "functionality".
4. `src/app/components/header/roleplay-menu.component.ts` (standalone, Material): rendered in `header.html`
   immediately BEFORE the `currentUser` block; visible only when `state$.can_roleplay` is true. A `mat-flat-button`
   with `theater_comedy` icon: "Acting as: <role>" (accent colour when active) opening a `mat-menu`: one item per
   prototype role (`roles[]` from the API; a check mark on the active one), "Stop role-play", a divider, "New
   prototype role…" (a prompt-less inline `mat-form-field` in the menu or a small dialog: name, title). Tooltip:
   "Dev mode: everything you do as this role is recorded to build its permission profile". Nothing renders in
   production (the API says `can_roleplay: false, why: 'role-play exists only on a dev-posture instance'`).
5. A "Review" link in the menu to `/display/security-events` (the page with the usages + sessions tables), and the
   API URLs `/api/security/observe/review?role=<role>` for the admin.
6. Rebuild + deploy: `pol prod apply` from the suite root rebuilds prf-frontend and prf-backend from the tree and
   forces the services onto the new images (run detached: `setsid nohup pol prod apply > /tmp/x.log 2>&1 &`; poll
   the log for "stack polari-lean deployed"). Then open `https://prf.192.168.0.210.nip.io`, act as a role, and check
   `https://api.prf.192.168.0.210.nip.io/api/security/observe/review?role=<role>` fills in.

## The workflow (for the plan and the docs)

prototype role → act as it in dev (the role menu; the header travels on every request; the frontend posts the pages/apps/
actions; the backend counts the endpoints and the objects×verbs) → review (`/observe/review?role=`) → the permissions
admin narrows and creates the `AppPermissionProfile` (kc_groups_json = the KC group the role maps to) and marks the
prototype `concreted` → set `POLARI_APP_PERMISSIONS=enforce` (or advisory first) → verify (`/observe/verify?role=&group=`:
every recorded act replayed; denied = the job would break) → mark `enforced`.

## Gotchas learned
- Rows must be constructed as tree objects (`cls(manager=..., **fields)`); anything else in a manager table breaks the
  CRUDE view of the class. Test doubles go to `_FALLBACK`, never into the table.
- Persist with ONE trailing timer per burst (`_schedule_persist`), never a per-name rate limit (lost counts).
- `pol …` expands `$(...)` in remote commands locally; pass plain commands to `pol iso ssh … -- cmd`.
- The swarm rejects a bind mount whose host directory does not exist (dropped `/etc/polari` from the swarm stacks;
  `POLARI_POSTURE` env is the source of truth there; the isle compose can mount it).
- Poll patterns: `reboot: ` matched `secureboot:`; anchor patterns.
- `pol prod apply` REWRITES `prod-answers.env` from its known keys — a new answer must be in `save_answers` (POSTURE is).

## Where the documentation lives
- Plan: `AI-Notes/plans/ISLE_HARDENING_PLAN.md` §16 (postures), §16a–c, §17 (dev apps / observe mode), §17b (role-play → profiles; to be written by the docs agent).
- Ledger: `AI-Notes/ledgers/TESTING_OWED.md` §45–§48 (+ addenda) and §49 (role-play; to be written).
- Memory: `~/.claude/projects/-home-user-Desktop-polari-suite/memory/isle-hardening.md`, `polari-iso.md`.
- ISO arc state: `AI-Notes/handoffs/SECURITY_ARC_HANDOFF.md` and ledger §45–§47; the installed guest runs on isle-core
  (`/tmp/polari-vm/disk.qcow2`, ssh forwarded 2222 → the guest; `pol iso ssh d0177dfddeb3ac99 --host isle-core --port 2222 -- hostname`).

## 2026-09-17 — REAL LOGINS (Keycloak) on the lean demo: IN PROGRESS by a delegated agent

His ask: "incorporate keycloak and actual login capabilities into demo". Decision taken (Fable): keep the LEAN profile and add
Keycloak + its own small MariaDB to it behind the existing `POL_PROD_AUTH=keycloak` answer, with a NEW answer
`POL_PROD_PROFILE=lean|full` (default keeps today's behaviour: keycloak → full). The full profile (MinIO + scorecard + Odoo) is
too heavy for the demo box. The spec given to the builder (an opus agent, running when this was written):

- `prod.sh`: POL_PROD_PROFILE answer (save_answers/load_answers/guide); lean env gains POLARI_AUTH=keycloak, AUTH_URL, KC_HOSTNAME,
  KC_DB_PASSWORD + MARIADB_ROOT_PASSWORD (generated once, kept), POLARI_KEYCLOAK_ISSUER_URI/JWKS_URI/ADMIN_URL/REALM/ADMIN_CLIENT_ID,
  CORS incl. auth.$D, COMPOSE_PROFILES=logins; the lean runtime-config JSON gains the `keycloak` stanza (authority
  https://auth.$D/realms/Polari, clientId polari-frontend, redirectUri https://prf.$D/<callback route>); `pol-keycloak/keycloak-admin.env`
  generated from the example with a random admin password (gitignored); lean image list adds pol-keycloak + pol-mariadb.
- `docker-compose.lean.yml`: services `pol-keycloak` + `pol-kc-mariadb` under compose profile `logins` (KC_PROXY_HEADERS=xforwarded,
  KC_HTTP_ENABLED=true, limits 1024M/384M, healthcheck); prf-backend gets the POLARI_KEYCLOAK_* env via `${VAR:-}`.
- proxy lean template: `auth.$D` → pol-keycloak:8080 with forwarded headers + big proxy buffers, only when logins are on.
- realm: `configure_clients.sh` registers https://prf.$D/* redirect + web origin + post-logout; a `groups` claim mapper on
  polari-frontend; demo accounts seeded by `pol-keycloak/startup_shells/seed_demo_users.sh` (groups journalist / data-scientist /
  operators; users demo-admin (polari-admin), demo-journalist, demo-scientist, demo-viewer; one shared password in
  `.generated/demo-users.env`, gitignored; e-mails @example.invalid).
- docs: guide section "Real logins on the lean demo"; ledger §50.
- apply on the home stack with POL_PROD_AUTH=keycloak, POL_PROD_PROFILE=lean, POSTURE=dev; verify: OIDC discovery at
  https://auth.192.168.0.210.nip.io/realms/Polari/.well-known/openid-configuration, the runtime-config stanza, a password-grant
  token for demo-journalist carrying groups ["journalist"], the bearer accepted by the backend, an observation row with group journalist.

If the agent's report is missing when you read this: check `git log --oneline -8` in polari-cli and the suite root for "keycloak"
commits, `docker service ls` for pol-keycloak / pol-kc-mariadb, the apply log at
/tmp/claude-1000/-home-user-Desktop-polari-suite/c5ebcd1c-e979-4661-82e7-f0766a8351e3/scratchpad/prod-apply-kc.log, and ledger §50.
The BROWSER login pass (click Login on https://prf.192.168.0.210.nip.io, sign in as demo-journalist, see the name in the header, act as
a role) is HIS to do or a Chrome-connected session's; nobody has done it. Known follow-ups once logins work: set
`roleplay_groups` to a real KC group; concrete the journalist profile against the real `journalist` group; verify.

## What to do when the Fable budget is gone
Everything is pushed on dev. Continue with non-Fable agents (opus for builds, sonnet for docs): the owed items are listed in ledger
§45–§50 and in this file. Rules that must hold: security stays WARN-ONLY in deployments (his ruling); never real identifiers in
tracked files; deploy only via `pol prod apply` (detached + polled); commit innermost-first and push every repo; keep this handoff
current.

## Proven loop (2026-09-17) — his full ask, end to end, with a REAL login

The Keycloak work above landed, and the whole cycle he described has now been run against it on the home swarm
in dev posture, entirely through the APIs: a password-grant login as `demo-journalist` (claims carry
`groups: ["journalist"]`) → the role-play permission granted to the REAL KC group (`roleplay_groups:
["journalist","developers"]`, so `can_roleplay` is true *because of group membership*, false with no bearer)
→ a role-play session with `X-Polari-Roleplay: journalist` on eight reads plus three posted usages → a review
that fills in properly (4 object classes across 3 apps via `objects_by_app`, 6 endpoints, the pages and
actions, and a `proposed_profile`) → the permissions admin (`demo-admin`) creating the real
`AppPermissionProfile` through CRUDE (multipart, one `initParamSets` field) and marking the prototype
`concreted` → `verify?role=journalist&group=journalist` returning **"the role can still do everything it was
recorded doing"** with nothing denied and nothing needing to be widened → the prototype marked `enforced`.
Every observation row carries both the real `journalist` group and `roleplay:journalist`, with
`actor=demo-journalist` (a one-line fix to `observe_permission()` shipped first: it read only
`preferred_username`, so real logins were recorded as the KC `sub` UUID).

Enforcement itself now has an answer: `POL_PROD_APP_PERMISSIONS=off|advisory|enforce` (added to `prod.sh`
exactly as `POL_PROD_POSTURE` was, and passed to `prf-backend` by both compose files; default `off`). The stack
runs `advisory`: in-profile reads come back clean, out-of-profile reads come back 200 carrying
`X-Polari-Permission-Advisory: would-deny <Class>:read`. It was deliberately NOT switched to `enforce` — his
ruling that security stays warn-only in deployments stands.

Three defects surfaced and are recorded in ledger §51, none fixed: a profile concreted shortly before a
`pol prod apply` is **silently lost** (CRUDE writes reach sqlite only on a later flush; proven by losing one
and then proving a flushed one survives a second deploy); `/api/security/observations?groups=<name>` is exact
string equality against the whole joined groups field, so it can never match a multi-group row; and an expired
bearer degrades to "would-deny everything" rather than saying "unauthenticated" — harmless under advisory,
a 403 storm under enforce.

**2026-09-18 — those three defects are FIXED, selftested and proven live** (framework `9a093bd`, node `a8ee1ef`,
suite `85b6772`, redeployed with `pol prod apply`; posture still `dev`, gate still `advisory`): CRUDE
create/update/delete now schedule one trailing `persistTree` per burst through the new core helper
`polariApiServer/persist_debounce.py` (which `security_observe._schedule_persist` delegates to) and the backend
flushes once on SIGTERM, so a profile concreted 75 s before a forced redeploy survives it in both the API and the
sqlite file; `?groups=journalist` is a membership test and now answers 2 rows instead of 0; an expired bearer
answers `X-Polari-Auth: invalid-or-expired` and the advisory header reads `unauthenticated <Class>:<verb>` rather
than `would-deny`. New selftest `polariApiServer/selftest_persist_debounce.py` 13/13, security 94/97 (the 3 known
environment failures). Ledger §51 addendum has the numbers — **and TWO NEW defects found on the way and NOT
fixed**: `persistTree` is DELETE+REPLACE per class from `objectTables` (a redeploy landing inside the ~60 s flush
still loses the row — that is how §51's original profile died), and a CRUDE DELETE of one row empties the whole
class from the live view. Read the addendum before touching the DB layer.

What remains is the BROWSER pass, and it is his: sign in at `https://prf.<D>`, use the role menu in the header,
act as the role by clicking rather than by curl, and follow the Review link. Nothing below the API layer has
been seen by eye.

## Next arc: role grant routes (design only)

His 2026-09-18 ask — self-claim (D17-5, being built now) is fine for some roles, but others need an approval
process, an appointment by another role, an election with a voting record and a term, or an invitation, and apps
need to add their own custom routes — is designed, not built, in `AI-Notes/plans/ISLE_HARDENING_PLAN.md` §17c
and `AI-Notes/designs/ROLE_GRANT_ROUTES_DESIGN.md`: one `RoleGrant` ledger row per person × role × route with
Keycloak membership materialised from it by a reconciler, a `RoleGrantPolicy` per role, a manifest `roles:`
stanza for app-defined routes, and — per his ruling on D18-1 — every such row keys the person by their Keycloak
`sub` only (never a username/e-mail), which surfaces a correction owed against this arc's own `.actor` columns
(design §8, slice rg-0a) before any of the new ledger work lands.

**rg-0a is BUILT (2026-09-18, framework `7101480`, ledger §53): the PII boundary is applied.** Every actor
resolution in the security module, the role-play middleware and the CRUDE gate now yields the Keycloak `sub`
alone — `security_observe.actor_of()` is the one resolution, `security_api._actor()` is gone, and the role-play
session no longer takes an `actor` from the request body. The four ledgers keep the column name `actor`; it holds
a sub. A name is resolved live through the ONE gated door `GET /api/security/people/{sub}` (admin, your own sub,
or a group in the new `people_viewers` knob; 401 / 403 / 503 "no identity provider" otherwise) and is never cached
into the tree. Rows written before the rule are cleared by a one-shot idempotent boot scrub logging
`[security] PII scrub: N actor values cleared (D18-1)`. Security selftest 126/129 (the 3 known environment
failures). rg-0 may now build on these tables.

## 2026-09-18 — SELF-CLAIMABLE ROLES (his ask, built and deployed)

His words: *"I see no way, upon registering, to simply assign myself a role in the Polari interface. Or a way to go
from Polari to Keycloak to grant oneself permissions that anyone can just self-claim. It should not be the case all
roles can be taken by anyone, but self-proclaimable roles should be a thing, especially in dev mode."* Decided as
**D17-5** (plan §17b) and built the same day: a role IS a Keycloak group, so claiming one puts the caller's `sub`
into that group through the `polari-backend` service account — nobody opens the Keycloak admin console.
**Dev posture: every prototype role is claimable, in any state, unless an admin explicitly said no. Production:
only rows flagged `self_claimable` plus the `claimable_groups` knob. Admin roles — `ADMIN_ROLES`, `Polari
Administrators`, `Polari Developers`, and unflagged `polari-*` names — never, in either posture.** The rule is
`modules/security/custom/security_claims.py`, the Keycloak client is `modules/security/custom/kc_admin.py` (urllib
only, timeouts, never raises; 503 naming `KEYCLOAK_POLARI_BACKEND_CLIENT_SECRET` when there is no credential), the
doors are `GET /api/security/roles/claimable` and `POST`/`DELETE /api/security/roles/claim`, and the UI is "Claim a
role…" + "Manage account" in the header's signed-in user menu (`claim-role-dialog.component.ts`,
`role-claims.service.ts`, `AuthSessionService.renewSession()`). **His PII rule the same day — Keycloak exists to
keep personal data away from Polari — is honoured throughout: every row, event and knob write keys the person by
the opaque Keycloak `sub` alone, never a username or e-mail.** Security selftest 111/114 (the 3 known environment
failures). Ledger §52 has the build table, the live proof and what is owed; the guide has "Claiming a role
yourself". **STILL HIS: the browser pass** — the dialog has never been seen by eye, and whether `signinSilent`
re-issues a token carrying a just-claimed group is unproven in a browser (the API proof re-minted with a password
grant instead).

## 2026-09-18 — the two deep defects are FIXED (ledger §51 addendum 2)

The two defects §51 addendum found and left ("read the addendum before touching the DB layer") are fixed, selftested
and proven live on `polari-lean` — framework `4d9f864`, node `bc86fa4`, suite `57feb05`, posture still `dev`, gate
still `advisory`. The class-wipe was **not** `deleteTreeNode`: `getListOfInstancesByAttributes` handed the query
engine `self.objectTables[className]` itself and the engine narrows by `pop()`-ing the non-matches out of the dict
it is given, so merely *resolving* `targetInstance={"name":"x"}` deleted every sibling from the live tree before the
delete even started — the fix is that the engine narrows a copy. The legacy CRUDE access matrix, which gave an
anonymous caller C/R/U/D/E and an authenticated one only R/E, now returns the same open matrix from both branches,
with the invariant written down (the real per-profile gate is `accessControl/app_permissions_gate.py`, and this
matrix must never grant anonymous more than authenticated). `persistTree` now serializes every row outside any
transaction and writes the whole tree in ONE transaction with a `polari_persist_state` marker, so a reader sees the
old tree or the new tree and a process that finds another pid mid-flush declines instead of writing its own older
reading back; measured live, the window a reader could see anything partial fell from the whole flush (28–134 s) to
the write alone (typically **under a second**; 0.23 s on the first live flush). New selftests
`polariApiServer/selftest_crude_delete_blast.py` 21/21 and `polariDBmanagement/selftest_persist_atomic.py` 21/21;
everything else unchanged (debounce 13/13, batched 17/17, quiesce 27/27, security 94/97). Live: two throwaway
profiles created through CRUDE, **one deleted with the demo-admin bearer answering 200** (it used to 405 with a
bearer and succeed without one), the other throwaway and the real `journalist` still there before and after a
`docker service update --force`. **One thing needs his say-so:** `stop_grace_period` on `prf-backend` is Docker's
default 10 s while the SIGTERM flush needs 30–134 s to serialize, so that flush is killed on every redeploy of a
full instance — the one-line fix is `stop_grace_period: 180s` in `docker-compose.lean.yml` / `.prod.yml`, not
applied here because it changes his running stack.
