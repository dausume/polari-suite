# Role grant routes (rg arc) — how a person gets into a role, beyond self-claim

**Date:** 2026-09-18 · **Status: DESIGN ONLY — nothing in this file is built.** Plan
`AI-Notes/plans/ISLE_HARDENING_PLAN.md` §17c. Builds on the ROLE-PLAY → REVIEW →
CONCRETE → VERIFY arc (§17b, built) and today's self-claimable roles
(`security.custom.security_claims`, `RolePrototype.self_claimable`, D17-5 — being
built now, ledger §52).

His ask (2026-09-18, verbatim intent): "can we think of other routes people may
need to get role/group access? Claiming a role is likely fine for some
environments or roles. Other roles may need approval processes or
elections/voting records tied to them and have date-time durations. Others may
need to be appointed by other particular roles. Others may be put into an
approval queue. We will want to account for various scenarios of handling
permission allocations that are adaptive to various kinds of apps and custom
logic."

Today, self-claim is the only route, and it works by calling `kc_admin` to edit
a Keycloak group membership directly — there is no record of *why* someone
holds a role beyond a `SecurityEvent` line, no notion of a term, and no second
route at all. This design generalizes "how does a person end up in a role's KC
group" into one ledger with several pluggable routes, so approval, appointment,
election, invitation and app-derived membership are all the same shape instead
of five one-off code paths.

## 1. The model — one ledger, Keycloak is derived

A **`RoleGrant`** row is the one truth for "this person holds this role
(optionally scoped to one object), because of this route, from this evidence,
for this long." Keycloak group membership is **materialised** from the set of
`active` grants by a reconciler — added when a grant goes active, removed when
it expires or is revoked — and is never hand-edited again (`kc_admin` becomes a
function the reconciler calls, not something a route calls directly). Today's
self-claim and the eventual concreted `AppPermissionProfile` groups become
routes/rows in this same ledger (§6, rg-0) rather than a separate mechanism.

A **`RoleGrantPolicy`** row per role says which routes may grant it and with
what parameters — the same role can allow more than one route (e.g.
self-claim in dev, approval-queue in production).

## 2. The routes

| route | who requests | who decides | evidence recorded | term | typical roles |
|---|---|---|---|---|---|
| **self-claim** | the person, for themself | nobody (auto-approved by policy) | the policy that allowed it (dev-open / flagged / knob-listed) | usually none | journalist, dev-mode prototype roles |
| **approval-queue** | the person (or on their behalf) | N-of-M holders of named APPROVER ROLES | who approved, when, the stated reason | optional deadline; approval itself has no expiry unless the policy sets a term | moderator, verified-contributor |
| **appointment** | nobody requests — an appointer acts | holders of role X, appointing into role Y | the appointer's identity | optional term (renewable) | secretary of a group, delegate |
| **election** | a nomination during the nomination window | the electorate (holders of the eligible-voter role), by quorum + threshold | the `VoteRecord` tally itself | fixed term, ends the seat | chair, council seat |
| **invitation** | the invitee, redeeming a token | whoever issued the token (a holder or admin) | the token id and issuer | optional expiry on the token, optional term on the resulting grant | guest-collaborator, beta-tester |
| **derived** | nobody — recomputed from app state | the app's own data (e.g. `Household.owner`) | the source object + relation that produced it | tracks the source; disappears when the source does | household-admin (of THIS household), owner-of-X roles |

**Term + renewal** is not its own route — any route's grant may carry
`valid_from`/`valid_until`. Expiry drops the group membership on the next
reconciler sweep. Renewal is a *new* grant made through the *same* route (a
re-election, a re-approval, an appointer appointing again), so the evidence
chain stays whole instead of silently extending an old row; `renewed_from`
links the new grant back to the one it replaces.

Ties, recounts and recalls are not new routes either — they are the same
election object reaching a different verdict on its `VoteRecord` (§4).

## 3. Objects and their fields

**`RoleGrant`** (security module): `person` (the Keycloak `sub` — a UUID,
never a username or e-mail; §8), `role`,
`scope_class` / `scope_id` (both `''` for an unscoped role — §5), `route`
(one of the table above), `evidence_json` (route-shaped: approvers+reason,
appointer, election_id, invitation token id, or the source object for
`derived`), `requested_at`, `decided_at`, `valid_from`, `valid_until` (`''` =
no expiry), `state` (`pending | active | expired | revoked`), `decided_by`,
`revoked_by`, `revoked_why`, `renewed_from` (a prior `RoleGrant.name`, or
`''`).

**`RoleGrantPolicy`** (security module): `role`, `routes_json` — a list of
`{route, params}`, e.g. `{"route": "approval-queue", "params": {"approver_roles":
["moderator"], "n_of_m": "1-of-1", "reason_required": true, "deadline_hours": 72}}`
or `{"route": "election", "params": {"eligible_voter_role": "member",
"nomination_days": 7, "voting_days": 5, "quorum": 0.25, "threshold": 0.5,
"term_days": 180}}`. `defined_by` (`admin` or the app manifest that owns the
role — D18-5).

**`VoteRecord`** (new `governance` module, §5/D18-4): `election_id`, `role`,
`scope_class`/`scope_id`, `state` (`nominating | voting | tallied | certified`),
`nominees_json`, `ballots_json` (or a tally if ballots are not kept raw),
`quorum_met`, `threshold_met`, `verdict` (`elected | tied | recalled |
no-quorum`), `winner`, `closes_at`. A recount or a recall reuses the same
`election_id` with a new `VoteRecord` row rather than mutating a certified one.

> **Correction 2026-09-18 (his rule on owner-defined permissions, designs/OWNER_DEFINED_PERMISSIONS_DESIGN.md
> §4):** ballots are NOT kept in `ballots_json`. Each vote is a `Ballot` row owned by its voter
> (`owner` = the `sub`, hidden from everyone else), readable by others only as `election_id`, `choice`,
> `groups`; `VoteRecord` keeps the DERIVED tally, quorum, threshold and verdict, and certifying it freezes every
> ballot through the policy's `frozen_when`.

## 4. API doors (mirrors the `/api/security/observe*` shape §17b already set)

- `POST /api/security/roles/policies {"role", "routes": [...]}` — set a role's
  policy (admin, or generated from an app manifest's `roles:` stanza, §7).
- `POST /api/security/roles/grants {"role", "route", "scope_class?", "scope_id?", ...route params}`
  — request (self-claim: immediate; approval-queue: creates `pending`;
  appointment/derived: only an appointer/the app itself may call it).
- `GET /api/security/roles/grants?person=<sub>&role=&state=` — the queue, or
  "my requests" filtered to the caller's own `sub`.
- `GET /api/security/people/{sub}` — the ONE door that resolves a `sub` to a
  display name (live from Keycloak's admin API, never cached into the tree);
  gated to admins and to holders of a role a policy names as allowed to see
  requesters/voters (§8).
- `POST /api/security/roles/grants/{id} {"state": "active"|"revoked", "why"?}`
  — an approver deciding a `pending` row, or a revocation.
- `governance` module: `POST /api/governance/elections`, `.../elections/{id}/nominate`,
  `.../elections/{id}/vote`, `GET .../elections/{id}/tally` — each vote/tally
  writes/reads `VoteRecord`; a certified `tallied` row is what
  `POST /api/security/roles/grants` (route `election`) consumes as evidence.
- `POST /api/security/roles/invitations {"role", "ttl_hours"}` /
  `POST /api/security/roles/invitations/{token}/redeem` — issue and redeem.
- Existing `POST /api/security/roles/claim` / `DELETE .../claim` (self-claim,
  built) keep their shape but write a `RoleGrant` instead of calling `kc_admin`
  directly (rg-0).

Every route exposes the same three verbs — **request / decide / revoke** —
even where one is a no-op (self-claim's "decide" is the policy check itself;
`derived` has no "request" at all, only recompute).

## 5. Scope (a decision, not a default — D18-2)

Many roles are per-object: secretary of *this* group, admin of *this*
household. A grant carries an optional `scope_class`/`scope_id`; the
permission gate (`polariapps.objects.apps_permissions._shared.permission_verdict`)
would need to consult scope for classes marked scoped in their
`AppPermissionProfile`, matching the object being acted on rather than a bare
group membership. This changes the existing profile model (today's grants are
instance-wide), so scope is modelled on `RoleGrant` from rg-0 but the gate is
not wired to enforce it until rg-5 — a role can be scoped in the ledger well
before anything reads the scope back out.

## 6. Custom logic per app (manifest `roles:` stanza)

The Standard Polari App manifest (`moduleService/manifests.py`, schema
`polari-app/1`) gains a top-level `roles:` stanza, hand-set like `security:`
(survives `generate` regeneration, `moduleService/manifests.py:_preserve_hand_set`).
Routes are **handlers** registered by modules (a `ROLE_ROUTE_HANDLERS` table,
the same shape as `MODULE_ENDPOINT_CONSTRUCTORS`), so an app can add its own
route (certified-by-exam, paid-tier) without touching `security` or
`governance` core code — it just registers a handler exposing
request/decide/revoke and names it in its own manifest:

```json
"roles": [
  {
    "name": "certified-editor",
    "title": "Certified Editor",
    "route": "custom:certified-by-exam",
    "params": {"exam_class": "EditorExam", "passing_score": 80}
  },
  {
    "name": "household-admin",
    "title": "Household Admin",
    "route": "derived",
    "scope": {"class": "Household"},
    "params": {"source_class": "Household", "source_relation": "owner", "recompute": "on-write"}
  }
]
```

Every decision any route reaches is a **proposal a person confirms**
(knobs-and-suggestions discipline, repo memory rule) — an approver's click, an
appointer's action, a tallied election being certified — never a fully
automatic grant except `derived`, which is deliberately automatic because it
mirrors data the app already owns.

Role-play → review → verify (built, §17b) is unchanged and stays the way a
role's **profile** (which classes/verbs it needs) is worked out before its
**policy** (how someone gets *into* the role) goes live — two different
questions about the same role name.

## 7. The reconciler

A scheduled sweep (co-located with `security_observe`'s persistence pattern,
`polariApiServer/persist_debounce.py`'s one-trailing-timer discipline) walks
`RoleGrant` rows: `pending`→`active` transitions and new `active` rows get
`kc_admin.add_user_to_group`; rows crossing `valid_until` move to `expired` and
call `kc_admin.remove_user_from_group`; `revoked` rows are removed
immediately. It is the only code path allowed to call `kc_admin` for role
membership — routes only ever write `RoleGrant` rows.

## 8. The PII boundary

His ruling on D18-1 (2026-09-18): the `RoleGrant` ledger IS the truth, BUT
"largely the purpose of Keycloak is to keep PII secure and away from Polari
itself." So every person referenced in a Polari row is keyed **only** by the
Keycloak subject id (`sub`, an opaque UUID) — this applies to `RoleGrant`
(person), approvals (approver), appointments (appointer), `VoteRecord`
(ballots/eligible voters), invitations (issuer and redeemer), and every
revocation (`revoked_by`). No username, e-mail, display name or any other
claim is ever stored in a Polari row or a log line.

Pages that need a human-readable name resolve it **at render time**, through
one gated door — `GET /api/security/people/{sub}` — which looks the name up
live from Keycloak's admin API (the same admin credential `kc_admin.py`
already holds) and never caches it into the tree. That door is
permission-gated: admins, and holders of a role a policy explicitly names as
allowed to see requesters/voters (e.g. an approver seeing who is in their
queue). Nobody else resolves a `sub` to a name.

**Votes are secret by default.** The ledger keeps the tally and the
eligible-voter role, but whether an individual ballot is attributable is a
per-election policy field on `RoleGrantPolicy`'s election params
(`ballot_secrecy: "secret" | "attributable"`, recommended default `secret`) —
secret records only "voted: yes/no" per `sub` (to enforce one-ballot-per-voter
and compute quorum) and never which way; attributable keeps the full
`sub` → choice mapping for elections that want a public record (e.g. a
board's recorded roll-call vote), and must be named explicitly by the policy.

**Demo/dev postures follow the same rule** — the demo users' `@example.invalid`
addresses (handoff, "Real logins on the lean demo") live only in Keycloak; a
`RoleGrant` for `demo-journalist` is keyed by that account's `sub`, same as
production.

**Corrections owed — ✅ DONE 2026-09-18, framework `7101480` (slice rg-0a).**
Four rows built under §17b stored a human-readable `actor` instead of a `sub`:
`PermissionObservation.actor` (set in
`modules/security/custom/security_observe.py`'s `observe_permission()`,
falling back `preferred_username` → `username` → `sub`), `SecurityEvent.actor`
(`record()`, same file), `ObservationSession.actor` (`start_session()`, same
file) and `UsageObservation.actor` (`observe_usage()`, same file, and the
`preferred_username`-first fallback in `accessControl/roleplay_observer.py`).
All four now hold the `sub` alone: `security_observe.actor_of()` is the one
resolution, `security_api._actor()` is gone in favour of `_sub()`, the
role-play session no longer takes an `actor` from the request body,
`accessControl/app_permissions_gate.py` (the SecurityEvent the CRUDE gate
writes) resolves through `actor_of()` too, and `derive_profiles()`/`review()`
count DISTINCT subs. The gated door of this section exists:
`GET /api/security/people/{sub}` (§8 above), with the `people_viewers` knob.
Rows written before the rule are cleared by a one-shot idempotent scrub at
module boot, logging `[security] PII scrub: N actor values cleared (D18-1)`.
The `security-events` page needed no change — its `actor` column is a
configured table column, and it now shows the sub; resolve one by hand through
the door (see the guide's "Names and the PII boundary").

## 9. Decisions for him (D18-1…D18-6)

- **D18-1 — DECIDED (2026-09-18).** The `RoleGrant` ledger is the truth,
  Keycloak is derived from it, WITH the constraint above: Polari rows never
  hold PII, only the Keycloak `sub` — names are resolved live, on demand,
  through one gated door (§8).
- **D18-2** — model `scope_class`/`scope_id` on the grant from the start;
  gate on it only in a later slice (recommended: yes, per §5).
- **D18-3** — which two routes get built right after self-claim (recommended:
  approval-queue + appointment, then election).
- **D18-4** — do votes/elections live in the security module, or a small new
  `governance` module (recommended: `governance` — elections are an
  app-level concern with their own pages, not a security primitive).
- **D18-5** — who may define a `RoleGrantPolicy` (recommended: admins, plus an
  app manifest defining a policy for its own roles).
- **D18-6** — what happens to existing grants when a role's policy changes
  (recommended: existing grants keep the terms they were made under; a
  renewal uses the new policy, never retroactively rewriting a live grant).

## 10. Slices (rg-0a…rg-5)

- **rg-0a** — ✅ **BUILT 2026-09-18** (framework `7101480`, ledger §53). The PII
  correction, BEFORE rg-0 touches any of these tables: `PermissionObservation
  .actor`, `SecurityEvent.actor`, `ObservationSession.actor` and
  `UsageObservation.actor` are `sub`-only (§8's four call sites plus the CRUDE
  gate's own SecurityEvent), the gated door `GET /api/security/people/{sub}`
  exists with the `people_viewers` knob, and a one-shot idempotent boot scrub
  clears the usernames earlier builds wrote. Selftest: the four ledgers store
  the sub while the token carries a name and an e-mail; the scrub clears a
  non-sub actor and keeps a real one; the door answers 401 / 403 / 200 (self,
  admin, `people_viewers` member) / 503 with no Keycloak.
- **rg-0** — the `RoleGrant` + `RoleGrantPolicy` objects, the reconciler, and
  self-claim REWRITTEN to write a `RoleGrant` (route `self-claim`) instead of
  calling `kc_admin` directly (today's guardrails in `security_claims.py` —
  `NEVER_CLAIMABLE_GROUPS`, `RESERVED_PREFIX`, dev-vs-production — become the
  self-claim policy's parameters). Routes: `POST/GET /api/security/roles/grants`,
  `POST /api/security/roles/policies`. Pages: none new (existing `security-events`
  gains a grants table). Selftests: reconciler idempotency (running it twice
  does not double-add/remove), self-claim parity (same refusals as today).
  Proven vs owed: proves the ledger reproduces today's self-claim behaviour
  byte-for-byte; owed is everything past self-claim.
- **rg-1** — approval-queue + appointment. Objects: none new (routes on
  `RoleGrant`). Routes: decide (`POST /api/security/roles/grants/{id}`),
  queue listing. Pages: "my requests", "the approval queue" (per-approver-role
  filtered), "appoint someone" (a form for an appointer, Table/Graph display
  per the no-raw-JSON rule — never a JSON panel). Selftests: N-of-M approval
  math, deadline expiry to `revoked`, an appointer without the appointing role
  refused. Proven vs owed: the two most-asked-for routes usable end to end;
  owed is election and invitation.
- **rg-2** — term/expiry sweep + renewal + invitation. Objects: invitation
  token fields on `RoleGrant` evidence (or a small `RoleInvitation` row —
  decide at build time which is simpler). Routes: issue/redeem invitation,
  renewal (`POST .../grants` with `renewed_from`). Pages: "my invitations"
  (issuer side). Selftests: a grant crossing `valid_until` drops the KC group
  on the next sweep; a renewal links back and does not create a gap. Proven vs
  owed: durations work for every route that has them; owed is election.
- **rg-3** — election, in the new `governance` module. Objects: `VoteRecord`.
  Routes: nominate, vote, tally, certify. Pages: the election's own tally page
  (nominees, ballots-in so far, quorum/threshold progress, the certified
  result) — a governance-module page, not a security one. Selftests: quorum
  and threshold math, a tie producing verdict `tied` rather than a false
  winner, a certified `VoteRecord` producing exactly one `active` `RoleGrant`.
  Proven vs owed: elections work for one pilot role; owed is the manifest
  stanza and scope enforcement.
- **rg-4** — manifest `roles:` stanza + custom route handlers. Adds
  `ROLE_ROUTE_HANDLERS` (module → handler, mirroring
  `MODULE_ENDPOINT_CONSTRUCTORS`), `moduleService/manifests.py` `roles`
  findings (a `conform` check, never a gate, matching `security_findings`'
  pattern). Selftests: a manifest with a bad route name reported by `conform`;
  a custom handler's request/decide/revoke all reachable through the generic
  `/api/security/roles/grants` doors. Proven vs owed: an app can add its own
  route without touching core; owed is scope enforcement.
- **rg-5** — scope in the gate. Changes `permission_verdict` to consult
  `scope_class`/`scope_id` for classes an `AppPermissionProfile` marks scoped,
  matching the object under test rather than a bare group. Selftests: a
  household-admin grant scoped to Household A denied on Household B. Proven vs
  owed: this is the slice that turns §5's modelled-but-inert scope field into
  an enforced one; everything before it only ever recorded scope.
