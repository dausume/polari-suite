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

## What is NOT built (the frontend half) — the spec for the next agent

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
