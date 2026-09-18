# Operator guide — role-play → permission profiles

Backend only (2026-09-16); the frontend role menu is not built yet, so every step below is a `curl` call. See
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

## 7. Verify, then enforce
```
curl -sk 'https://api.prf.192.168.0.210.nip.io/api/security/observe/verify?role=journalist&group=journalist'
```
Replays every recorded class×verb through `permission_verdict` as a member of the group — allowed/denied per act.
A denial means the job would break under the new profile; widen and re-review before enforcing. Once clean:
```
curl -sk -X POST https://api.prf.192.168.0.210.nip.io/api/security/observe/roles/journalist -d '{"state": "enforced"}'
```

## Gotchas
- Only works in dev posture; a production-posture flip makes `can_roleplay` refuse outright — re-check
  `GET /api/security/observe/roles` after any posture change.
- Anonymous calls record as verdict `unauthenticated`, not against the role — need a real Keycloak login in the
  session for review to fill in meaningfully.
- The `app` column on `PermissionObservation` is still empty, so review's per-app grouping is incomplete.
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
- The observation's `actor` column holds the Keycloak `sub` UUID, not the username: `jwt_validator` returns
  `username` but `observe_permission` looks for `preferred_username`.
