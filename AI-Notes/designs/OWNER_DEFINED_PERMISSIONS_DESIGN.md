# Owner-defined permissions (op arc) — per-object rules the owner controls, opted in per class

**Date:** 2026-09-18 · **Status: DESIGN ONLY — nothing in this file is built.** Plan
`AI-Notes/plans/ISLE_HARDENING_PLAN.md` §17e. Sits beside the class × verb
profiles (`AppPermissionProfile`, §17b, built), the role grant routes
(designs/ROLE_GRANT_ROUTES_DESIGN.md, design) and causal tracing
(designs/CAUSAL_TRACE_OBJECT_FLOW_DESIGN.md, design).

His ask (2026-09-18, verbatim intent): "We also are going to want owner
defined permissions for some objects, not just object defined permissions.
Owner defined permissions would be something we typically want specifically
enabled per object though, not something we enable by default. Things like
votes would likely be an owner defined permission, other people do not have
the permission to alter the data on their vote, they only have partial read
access and only to the contents of the vote and groups the vote corresponds
to, not who specifically made that vote."

## 1. Two families, and which one is the default

| family | decided by | granularity | today |
|---|---|---|---|
| **object-defined** | the app / the permissions admin, per CLASS | class × verb, instance-wide, for a Keycloak group | `AppPermissionProfile` + `crude_permission_gate` — built, advisory on the home stack |
| **owner-defined** | the OWNER of one instance, inside bounds the class sets | per instance, per verb, per FIELD, per grantee | nothing — no instance carries an owner, no gate sees an instance |

Object-defined stays the default for every class. Owner-defined is **opt-in
per class**: a class carries no owner and no owner rules until an
`OwnedClassPolicy` row (or the manifest stanza in §7) turns it on. Turning it
on does three things: instances of the class get an `owner` stamped at
create, the CRUDE gate gains a second, instance-level check for that class,
and the owner may (if the policy allows) write per-instance grants.

What exists to build on, and what does not:

- `crude_permission_gate(manager, request, response, verb, class_name)`
  (`accessControl/app_permissions_gate.py:41`) runs BEFORE any instance is
  resolved — it cannot see an owner. The instance-level check has to sit
  after resolution, in `polariCRUDE.on_get` (`:212`), `on_put` (`:378`),
  `on_delete` (`:741`) and the collection variants.
- CRUDE create (`on_put_collection`, `:481`) stamps nothing about the
  caller onto the new row. The owner stamp is new, and per D18-1 it is the
  Keycloak `sub` alone.
- Field profiles (`polyTyping.fieldProfiles`, `setFieldProfileEntry`,
  `excludeFields`; served by `on_get_field_profile` `:286`) are the one
  existing "named subset of fields" mechanism, but they shape *reference
  resolution* for everyone, not visibility per caller. The partial read in
  §3 is a projection applied per caller after serialisation, not a field
  profile.
- `UserAppPreference` (§57) is already keyed by `sub` and is de facto
  owner-only, enforced by its door rather than by the gate. It is the
  natural first class to opt in.

## 2. The rows

**`OwnedClassPolicy`** — one per opted-in class, set by an admin or the
manifest (§7):

| field | meaning | vote example |
|---|---|---|
| `class_name`, `enabled` | the opt-in | `Ballot`, true |
| `owner_verbs` | what the owner has on their own instances, regardless of the class profile | read, update, delete |
| `others_verbs` | what a caller who holds the class-level grant gets on instances they do not own | read |
| `others_fields` | the fields a non-owner may see (a list; everything else is dropped) | election_id, choice, groups |
| `owner_visible` | whether the `owner` column itself is readable by non-owners | **false** |
| `owner_may_grant`, `grantable_verbs`, `grantee_kinds` | whether the owner can widen access per instance, to what, to whom (`group` and/or `person`) | false — a ballot is not shareable |
| `frozen_when` | a condition on a related row after which the owner loses `update`/`delete` (`VoteRecord.state in (tallied, certified)`) | set |
| `transfer` | who may change `owner`: `nobody` / `admin` / `owner` | nobody |
| `anonymised` | shorthand for `owner_visible: false` + the broadcast and trace suppressions in §5 | true |

**`OwnerGrant`** — per instance, written by the owner within the policy's
bounds (only when `owner_may_grant`): `class_name`, `object_id`, `grantee_kind`
(`group` | `person`), `grantee` (a group name, or a `sub` — never a name),
`verbs` ⊆ `grantable_verbs`, `fields` ⊆ the class's fields, `valid_until`,
`granted_by` (the owner's `sub`). A household member sharing one meal plan
with one other person is this row; a ballot never has one.

**The `owner` column** — a `sub`, present only on opted-in classes,
stamped at create from the request's identity (the same `actor_of()`
resolution §53 made the one door). Anonymous creates on an owned class are
refused: an instance with no owner has no owner-defined rule to apply.

## 3. The verdict — who sees and touches which instance, and which fields

Order of evaluation for a request on class C, verb V, resolved to instance I
(or a list of them):

1. **Class gate first, unchanged.** `crude_permission_gate` decides C × V
   for the caller's groups (admins pass). A caller with no class-level grant
   is refused before any instance is touched — owner-defined never widens
   beyond the class door for *others*.
2. **Owner floor.** If the caller's `sub` == `I.owner`, the verbs in
   `owner_verbs` are allowed on this row — unless `frozen_when` holds, which
   strips `update`/`delete`. **Corrected 2026-09-18 (as built, op-0):** the
   class gate in step 1 has already run, so the owner floor never exceeds
   the group's class-level grant either; what it does is keep the verb on
   the owner's OWN rows while step 3 narrows everyone else. A voter's group
   therefore needs `update` on `Ballot` at class level, and the owner rules
   confine that update to the voter's own ballot. Owner-defined narrows;
   it never widens for anyone.
3. **Others' ceiling.** Otherwise V must be in `others_verbs` or in an
   `OwnerGrant` naming the caller (by `sub`) or one of their groups. Reads
   are **projected**: the response carries `others_fields` (∪ the grant's
   `fields`) and nothing else; `owner` is dropped unless `owner_visible`.
   `update`/`delete` on another's instance is refused unless a grant says
   otherwise.
4. **Lists.** A collection read applies 2–3 per instance: own rows whole,
   others' rows projected, rows the caller may not read at all omitted —
   never a 403 for the whole list because one row is private.

The gate follows the same `off | advisory | enforce` answer as the class gate
(`POL_PROD_APP_PERMISSIONS`); in `advisory` a refused verb still runs and the
response carries `X-Polari-Owner-Advisory: would-deny <Class>:<id>:<verb>`,
and a projected read carries `X-Polari-Owner-Advisory: would-project
<Class>:<id>` while still returning the whole row — so a dev instance shows
what enforcement would hide without hiding it (§17: dev warns, never
blocks). Every verdict is evidence-bearing like `permission_verdict`: which
rule decided (`owner-floor`, `others-ceiling`, `grant:<id>`, `frozen`) and
the knob that would change it.

## 4. The vote, end to end (the correction to the role-grant design)

The role-grant design's `VoteRecord` keeps `ballots_json` inside the election
row. His rule makes a ballot an **owned object**, so that changes:

- **`Ballot`** (governance module, with rg's election slice): `election_id`,
  `choice`, `groups` (the group(s) in whose election it was cast — "the
  groups the vote corresponds to"), `owner` (the voter's `sub`, hidden),
  `cast_at`. One row per voter per election; a re-cast while voting is open
  is an `update` by the owner, not a second row.
- **`OwnedClassPolicy` for `Ballot`:** the vote example column in §2. Others
  see `election_id`, `choice`, `groups` — enough to audit the count and see
  which constituency a vote belongs to — and never `owner`. `cast_at` is
  **not** in `others_fields`: an exact timestamp beside a public "who was
  online" signal is a way to unmask a voter, so the tally view coarsens it
  or omits it (§8).
- **`VoteRecord`** keeps the tally, quorum, threshold and verdict, all
  DERIVED by counting `Ballot` rows; `ballots_json` goes away. Certifying the
  record sets the state that `frozen_when` reads, so every ballot becomes
  read-only for its owner too — the vote is over.

So: other people cannot alter your vote (others' ceiling = read), they can
see its contents and its groups (projection), and not who made it (owner
hidden, plus §5 so the id and timing leak nothing either).

## 5. Anonymised classes — the side channels

Hiding the `owner` column is not enough on its own; three other paths name
the person, and an `anonymised` policy closes each:

- **Change broadcast.** `transport_mux.publish_change` sends `className,
  operation, instanceIds` to any STOMP subscriber (unauthenticated today —
  ct-6). For an anonymised class the payload carries the class and
  operation only, no ids, so "a Ballot was created at 14:02:07" cannot be
  paired with "demo-journalist was on the page at 14:02:07".
- **The trace journal** (ct arc). A journal row pairs the cause's `actor`
  with the effect's `object_id` — for a ballot that pairing IS "who voted".
  For an anonymised class the journal keeps class + verb and drops both
  `actor` and `object_id`; the map is class-level and unaffected. Arming
  such a class as a trace target says so in the target's status.
- **Security events and observations.** `SecurityEvent.target` for a refused
  act on an anonymised class names the class, not the instance id.

## 6. Doors and the page

- `GET /api/security/owned` — the opted-in classes and their policies;
  `POST /api/security/owned/{class}` (ADMIN_ROLES) sets or changes one.
- `GET /api/security/owned/{class}/{id}` — the caller's verdict on one
  instance, evidence-bearing (what they may do, which fields they see, why).
- `GET`/`POST`/`DELETE /api/security/owned/{class}/{id}/grants` — the
  owner's per-instance grants (only when `owner_may_grant`; grantees by
  group name or `sub`).
- On the object's own page (his per-object display rule): a **Sharing** tab
  rendered from a configured table definition over `OwnerGrant` filtered to
  that instance, with the policy's bounds shown — no new component, nothing
  raw. A ballot's page has no Sharing tab because its policy forbids grants.

## 7. Manifest stanza (the app half)

The Standard Polari App manifest gains `app.owned`: a list of
`{class, owner_verbs, others_verbs, others_fields, owner_visible,
owner_may_grant, grantable_verbs, grantee_kinds, frozen_when, transfer,
anonymised}` entries — the same keys as the row — validated by
`moduleService.manifests` like `app.roles`, converged into
`OwnedClassPolicy` rows on every read exactly as `app.roles` becomes
`RoleAppBinding`, and **never overwriting a policy an administrator set**.
The governance module ships `Ballot` this way.

## 8. Decisions

None is open. Everything below follows from his ask, his PII rule, or the
code, and is taken as the default; say so if any should change:

- `owner` exists only on opted-in classes (his "not by default", and the
  per-class schema freeze).
- The owner floor does NOT exceed the class profile (corrected as built:
  the class gate runs first, always). A voter's group holds `update` on
  `Ballot` at class level; the owner rules confine it to the voter's own
  row. Nobody, owner included, exceeds the class door.
- Correlatable fields such as `cast_at` are omitted from others' view; a
  policy may list a coarsened field explicitly.
- Transfer defaults to `nobody`; never for anonymised classes; a class may
  opt in to `admin` or `owner`.
- Ballots are `Ballot` rows; the tally is derived (the role-grant design is
  corrected accordingly).
- The owner gate sits inside the CRUDE responders after resolution, one
  place for every owned class.
- Anonymised classes broadcast the class and operation without ids; the
  broadcast is not dropped entirely because subscribers still need to
  refresh.

## 9. Slices (op-0 … op-4)

| slice | builds | proof |
|---|---|---|
| **op-0** the policy + the stamp + the gate | `OwnedClassPolicy`; `owner` stamped at create (sub only, anonymous refused); the instance-level check in the six CRUDE paths with projection; advisory headers; evidence-bearing verdict; selftests; `UserAppPreference` opted in as the first class | own row whole, other's row projected, other's update refused (advisory header first, enforce in the selftest) |
| **op-1** owner grants | `OwnerGrant` + the grants doors; grantee by group or sub; `valid_until`; the Sharing tab as a configured table | a meal plan shared with one person by sub; expiry removes it |
| **op-2** anonymised | `owner_visible`, `anonymised`, `frozen_when`, `transfer`; broadcast id suppression; trace-journal pairing suppression; `SecurityEvent.target` = class | a created row of an anonymised class broadcasts no id; the journal row has no actor/object pair |
| **op-3** the vote | `Ballot` rows + policy in governance; `VoteRecord` tally derived; the rg design corrected | two voters, one re-cast, one certified election: contents and groups visible to all voters, owners never |
| **op-4** manifest | `app.owned` stanza, validation, convergence, admin rows preserved | a module ships an owned class and its policy appears without an admin touching it |

Rules that hold: security WARN-ONLY in deployments; every person keyed by
Keycloak `sub` alone; owner-defined never widens what *others* may do beyond
the class door; nothing raw on a screen; no new reusable component; commit
innermost-first, push every repo; keep the handoff current.
