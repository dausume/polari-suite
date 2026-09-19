# Application security in Polari

The application ring decides who may call which class × verb, who owns which row, what leaves and enters over
the wire, and what a role's actions really cause. Unlike the OS, proxy, firewall and network rings described
elsewhere in this section, this ring is **built, selftested, pushed and live-proven** on the home staging stack
(ledger sections cited throughout are `AI-Notes/ledgers/TESTING_OWED.md`). It runs `advisory` under `dev`
posture there and enforces nothing. Every door below answers over the live API; none of its screens has had a
browser pass yet — that gap is named at the end of each part.

## Dev posture and observe mode

One knob, `POLARI_APP_PERMISSIONS`, set to `off | advisory | enforce`, gates every check in this ring — CRUDE
reads and writes, STOMP subscriptions, outbound sends, inbound requests. **Deployed stacks stay at `off` or
`advisory`; `enforce` is never the deployed mode** (ledger §51). Under `advisory` a refused action still runs,
and the response carries a header naming what would have been denied and why — the evidence is there to read,
nothing is hidden and nothing is blocked.

Recording (observe mode) is on by default in `dev` posture and never in production. It underlies the role-play
recording below, and separately, causal tracing (its own on/off switch, one class at a time — see below).

## Role-play → review → concrete → verify

An operator acts as a prototype role (`RolePrototype`) while Polari records every app, page, component, action,
endpoint and class × verb the role touches. A **review** turns that recording into a proposed permission
profile; an administrator **concretes** it into a real `AppPermissionProfile`; a **verify** pass replays the
whole recording against the concreted profile before anyone considers `enforce`. Full walkthrough with curl
examples: `AI-Notes/guides/ROLEPLAY_PERMISSIONS_GUIDE.md` (ledger §51 and after).

Causal tracing (below) now feeds the same review: `review(role)` carries a `closure` block and `verify(role,
group)` carries a `transitive` verdict — "the profile covers N of M transitively-touched class × verb pairs; K
are reached only through triggers running as definer" (ledger §63).

## Causal tracing — what an event really causes

His rule: trace one kind of object at a time, with limits on how much tracing data can pile up, and never in
production (ledger §61). Nothing is recorded until a `TraceTarget` — one class, with budgets on traces, edges,
journal rows, depth and a time window — is **armed**. A second arm is refused, naming the class already active.
The first budget hit **disarms itself**, records why (`stopped_because`), and writes one `SecurityEvent`; the
journal is cleared the next time a target is armed.

- **The causal-edge map** (`CausalEdge`, Ledger A) — a counted, class-level row per `cause → effect` pair and
  the means that connected them: a CRUDE act, a trigger firing, a nested solution run, an event emitted, a
  change broadcast over STOMP, a shared-database read from a peer, a module bundle export/install, or a send to
  an external system through the outbound wrapper (ledger §59, §61, §63, §62).
- **The effect journal** (`WriteJournalEntry`, Ledger B) — instance-level, dev-only, a ring buffer: which
  specific rows a traced chain actually wrote. An anonymised class (see owner-defined permissions, below) keeps
  the class and verb in the journal and drops which actor wrote which instance.
- **The closure** — `security_trace.closure()` walks the map from a starting point (an `AppPermissionProfile`,
  an event, a role-play recording, or the one armed class) and answers what it *really* reaches, transitively:
  `explicit` (the profile's own grants), `reachable` (everything the map can walk to), and `implicit = reachable
  − explicit` — the permissions an event or profile grants without saying so (design
  `CAUSAL_TRACE_OBJECT_FLOW_DESIGN.md` §6, built ledger §63). Every item in a closure carries its `origin`
  (`observed | closure | declared`), whether it is reached **only** through a trigger running as the class's
  definer (`definer_only`), and its evidence (counts, first/last seen, a sample trace id to look the instance up
  with). **Coverage is explicit:** a class nobody has ever armed answers `not_traced`, never "nothing reaches
  it" — those are different claims and the map never conflates them.
- **The `objects` topology view** (ct-5, ledger §67) — a fourth view alongside `os`/`network`/`app`:
  `?view=objects` on `/api/security/topology`, `/simulate` and `/compare`, plus `GET /api/security/objects/drift`
  and `GET /api/security/objects/flows`. **declared** = the modules' manifest `app.flows` stanzas (a system KIND
  an app author can honestly state, never a host) **plus** the confirmed `OutboundPolicy`/`InboundPolicy` rows a
  person ruled on; **observed** = the causal map's `external:`/`peer:` edges and the two `ws-*` means, carrying
  the payload classes on the new `SecurityTopologyEdge.payload` column. The drift report answers
  `observed_not_declared` (a live finding — dev warns, never blocks), `declared_not_observed` (noise to prune,
  unless never traced), a per-app `coverage` of none/partial/full, and `not_traced` — **"NOT TRACED" is itself
  the answer, never an empty list**, the same discipline the closure above already keeps. Page `security-objects`
  (8 configured panels + 2 class tables, no raw JSON). The view's rows are derived fresh on every read and are
  **not persisted** as `SecurityTopologyNode`/`Edge` rows — writing them from a `GET` would be a side effect on a
  read that goes stale the moment a policy is confirmed.
- **Tasks** (ct-7, ledger §67) — a role-play session now carries a `task` (posting `/api/security/observe/session`
  again changes it mid-session and keeps the history); every counted observation row gains a `{task: count}` map
  rather than multiplying rows per task. `review(role)` groups the whole recording by task with a **per-task
  closure**; `verify(role, group)` names which **tasks** enforcement would break, not just a verb count. The
  manifest gained an `app.flows` stanza (design §9) with its own vocabulary — `to` one of `keycloak`, `odoo`,
  `livekit`, `reticulum`, `engine`, `provider`, `peer`, `self`, `s3`, `mqtt`, …; `direction` `push`/`pull`/`both`;
  up to 50 `classes` — wired into `validate()` and preserved by `generate`. `security` (→ keycloak, `classes: []`
  — names live in Keycloak, D18-1) and `odooconnect` (→ odoo, `classes: []`) are the first two real declarations.
- **Doors:** `GET|POST|DELETE /api/security/observe/trace` (status/arm/disarm), `GET
  /api/security/trace/edges` (the map, filterable by `?target=|cause=|effect=|means=`), `GET
  /api/security/trace/journal` (the journal, `?trace_id=|class=`), `GET /api/security/observe/closure`
  (`?profile=|event=|role=|class=`, or no parameter for the armed target).
- **Pages:** `/display/security-events` carries the Trace status/targets/edges tables and five closure panels
  (objects, solutions, events, flows, and the not-traced list) — configured tables and structured panels, no raw
  JSON (security_page.py rows for `security-trace-*` and `security-closure-*`).
- **Not built yet:** the objects view's third declared source (§7's configuration knobs — `PeerNode`,
  `OdooInstanceConfig`/`OdooModelBinding.direction`, `GrpcExposure`, `apiFormatConfig.*WsEnabled`,
  `PeerAgreement.scope`, shared-DB co-residency); `app.flows` on the other 59 modules (two declared so far); a
  live two-instance proof that `X-Polari-Trace` produces matching edges on both sides; the browser pass on
  `/display/security-objects` and on the Trace/closure panels (ledger §61, §63, §67 OWED).

## Traffic policies — outbound and inbound, closed by default

His rule: outbound is tracked in dev too, and both directions are **closed by default** — Polari suggests
allow-list rows from what it actually observes crossing its own boundary, and a person confirms or denies each
one (ledger §66). `OutboundPolicy` (keyed by system × wire) and `InboundPolicy` (keyed by peer name, origin
scheme+host, or `anonymous` — **never a raw IP address**) hold the rows. The `outbound.py` wrapper — the one
seam every call to another system passes through — checks policy before sending; a `TrafficPolicyMiddleware`
classifies every inbound request the same way.

The ladder is posture × mode: in `dev`, `off` computes and writes nothing acted on, `advisory` proceeds with a
`suggested` row and a header, `enforce` refuses anything without a `confirmed` row. In production no rows are
written at all except a person's confirm, and `enforce` there is closed by default: nothing unconfirmed gets
through. The home stack runs `dev` + `advisory` — it warns, it never blocks.

- **The header:** `X-Polari-Traffic-Advisory`, drained onto the response by the cause middleware and exposed to
  browsers via CORS.
- **Doors:** `GET /api/security/traffic` (policies + suggestions + mode, signed in), `GET
  /api/security/traffic/declared` (confirmed rows as declared flows for the object topology), `POST
  /api/security/traffic/outbound/{name}` and `/inbound/{name}` (`{"decision": "confirmed"|"denied"}`, admin
  only), plus **body-addressed** `POST /api/security/traffic/outbound` and `/inbound` (`{"name": …, "decision":
  …}`) for names that hold `://` and cannot ride a URL path (found live, fixed — ledger §66 addendum).
  `/api/health` and `/api/security/traffic*` are never refused, so an admin can never be locked out by their own
  gate on the first `enforce`.
- **Pages:** `/display/security-events` carries a suggestions panel, the outbound and inbound tables, and a
  declared-flows panel (`security-traffic-*` rows in `security_page.py`).
- **Now feeds the `objects` topology view** (ct-5, ledger §67): `declared_flows()` is compared against the
  causal map's own `external:`/`peer:` edges as the drift report described under Causal tracing, above.
- **Not built yet:** the browser pass on the three traffic panels and on `security-objects`. One named,
  permanent gap: `PyJWKClient`'s own JWKS fetch inside token validation cannot be wrapped without replacing the
  library's own HTTP client, so it stays invisible to this map (ledger §66 addendum 2).

## Security decisions per app × version

His rule: security is worked per app and per version release, and coverage is counted (ledger §64). Every kind
of security ruling an app needs — profile grants, owner policies, outbound/inbound, which role a trigger runs
as, declared flows, role bindings, trace coverage — is enumerated as a `SecurityDecision` row: **8 kinds**
(profile-verb, owner-policy, outbound, inbound, trigger-run-as, flow-declared, role-binding, trace-coverage) ×
**6 states** (open, suggested, confirmed, denied, inherited, stale). Subjects are enumerated *from the app
itself*, so `open` is a real, countable gap rather than silence. A version bump inherits its predecessor's
rulings; a subject that changed under the bump goes `stale` instead. A human confirms a decision with their
Keycloak `sub` and a hash of the proposal they approved — never a rubber stamp on an unseen change.

- **Doors:** `GET /api/apps/security/decisions?app=&kind=&state=`, `POST
  /api/apps/security/decisions/confirm`, `POST /api/apps/security/confirm-profile` (the one door that hashes
  the proposal and records the confirming `sub`), `POST /api/apps/security/bump?app=&from=&to=`, `GET
  /api/apps/security/coverage?app=` — coverage as none / partial / full, by kind × state and by live instance
  count.
- **Page:** `/display/apps-security` — coverage per app × version, totals across kinds and states, and an
  "open" panel filtered server-side (design intended each app's own page; `AppHomeComponent` has no seedable
  slot, so the tables live on the polariapps module page instead — stated in `apps_page.py`, ledger §64
  gotcha 1).
- **Not built yet:** a sweep that converges every app (today converge only runs on read, so `GET
  /api/apps/security/coverage` with no `app` answers only apps already touched); the release gate does not yet
  cite these counts; the browser pass on the coverage panel (ledger §64 OWED).

## Restarts keep rulings

A confirmed ruling — a `SecurityDecision`, a confirmed `OutboundPolicy`/`InboundPolicy` row — used to be at risk
of quietly vanishing across a restart, not from anything that deleted it, but from two different restore paths
disagreeing about what "this row is already here" means. One path matched a restored row by id and name; the
other matched by a property fingerprint, and a persisted row that had **diverged** from its boot-time twin (a
person's confirmed ruling sitting beside an observer's earlier suggested guess) matched closely enough on the
descriptive columns to be dropped as if it were a re-created seed — the ruling was gone, and the next boot wrote
the half-decided tree back over it. Both restore paths now restore persisted rows **by id**, for every class the
definition merge governs, and fold any boot-time duplicate into the persisted row rather than replacing it. This
is proven live for security decisions: a confirmed `SecurityDecision` survives a forced restart with its
confirmer and timestamp intact (ledger §66 addendum 5). **Re-proof is still owed for traffic rows** — the
confirmed `OutboundPolicy`/`InboundPolicy` rows this fix specifically targets have not yet been re-checked
against a rebuilt image that carries the fix.

## Owner-defined permissions

His rule: some classes need permissions the **instance's owner** controls, opt-in per class, never something
every class gets by default — a vote is the example: others may read its contents and which group it belongs
to, never alter it, never see who cast it (ledger §60, design `OWNER_DEFINED_PERMISSIONS_DESIGN.md` §3). An
`OwnedClassPolicy` row opts a class in: an **owner floor** (verbs the owner keeps on their own rows), an
**others' ceiling** (verbs and a field projection for everyone else), whether the owner is visible at all, and
whether ownership can be transferred. `owner` is a Keycloak `sub`, stamped at create, on opted-in classes only —
nothing about a stock class changes.

**The order always runs class-gate-first: owner-defined rules never widen past the class door, only narrow
it** — corrected during the build from the original design, which had allowed the owner floor to exceed the
class profile (ledger §59–§62 addendum, design §3 step 1). So an owner's own row still needs the class-level
grant to begin with; owner-defined permissions decide what happens *within* that grant, per instance. The gate
runs inside the CRUDE responders after the instance resolves: own rows come back whole, others' rows are
projected to `others_fields`, unreadable rows are simply omitted from a list rather than failing the whole
read. The advisory header is `X-Polari-Owner-Advisory: would-deny <Class>:<id>:<verb>` (or `would-project
<Class>:<id>`), following the same `off | advisory | enforce` posture as everything else.

**Anonymised classes** close three side channels a hidden `owner` column alone would leave open: the STOMP
change broadcast drops instance ids for such a class (class and operation only), the trace journal drops the
actor/object pairing, and a `SecurityEvent` names the class rather than the instance.

The first class opted in is `UserAppPreference` — proven live: a person sees their own row whole with no
advisory, another person sees the same row under `advisory` mode with `would-deny …` on the response, and the
class gate is checked first in both cases (ledger §59–§62 addendum).

- **Doors:** `GET /api/security/owned` (the opted-in classes, their policies, and the manifest's declarations +
  convergence), `GET|POST /api/security/owned/{class_name}` (admin sets or replaces a policy), `GET
  /api/security/owned/{class_name}/{object_id}` (the caller's own verdict on one instance, plus its `grants` and
  `sharing` block — the Sharing tab's whole answer in one door), `GET|POST|DELETE
  /api/security/owned/{class_name}/{object_id}/grants` (op-1), `POST
  /api/security/owned/{class_name}/{object_id}/transfer {"to": "<sub>"}` (op-2).

**Grants** (op-1, ledger §69) — an owner shares ONE of their own rows with a group or a Keycloak `sub` through an
`OwnerGrant` row (deduped on `class|id|kind|grantee`; re-granting rewrites rather than doubles). **A grant never
widens the class door:** the class gate decides verb × group first, and a grant only restores a verb
`others_verbs` withheld, or widens a projected read, for that grantee alone. Every bound is checked at the door:
`owner_may_grant` must be on, the caller must be the owner (or an admin), `verbs ⊆ grantable_verbs`,
`grantee_kind ∈ grantee_kinds`, `fields` may never include the owner column of an anonymised class, and a grant
to yourself is refused. **Expiry is a verdict check, not a background job** — a `valid_until` in the past is dead
the instant the verdict is asked, and pruned (with a `SecurityEvent`) the next time the row is read; an
unreadable or already-past `valid_until` is refused at the door rather than silently becoming permanent. The
Sharing tab exists today as **data only**: `sharing.table` is a complete `class-rows-table` item (`OwnerGrant`,
filtered to the instance) ready to render, because there is no per-instance page host anywhere in the frontend to
hang a tab on — that host, not a new component, is what remains owed.

**Anonymised classes, finished** (op-2, ledger §69) — all three side channels a hidden `owner` column would
otherwise leave open are now proven together in one check block: the STOMP broadcast drops instance ids (class
and operation only), the trace journal drops the actor/object pairing, and a `SecurityEvent` now names the
**class alone** (`event_target()`) rather than the instance — the owner gate's own refused writes ledger through
it. `anonymised: true` is normalised at the single read point (`policy_for`) to force `owner_visible` false
**and** `transfer` `nobody` together, so a row declaring them inconsistently can never leak through whichever
half a consumer forgot to check. **Transfer** (`POST …/transfer {"to": "<sub>"}`) moves ownership under the
policy's `transfer` mode (`nobody`/`admin`/`owner`) and refuses in **every** gate mode, including `advisory` — a
transfer's only effect is moving what the gate reads, so warning-and-proceeding would do the very thing being
warned about.

**The `app.owned` manifest stanza** (op-4, ledger §69) — a module declares an owner-defined policy for its own
class the same way `app.flows`/`app.roles` work: `class`, `enabled`, `owner_field`, verb lists
(`owner_verbs`/`others_verbs`/`grantable_verbs`, vocabulary `read|update|delete|events`), `others_fields`,
`owner_visible`/`owner_may_grant`/`anonymised`, `frozen_when`, `transfer`. `OwnedClassPolicy.source` records
`manifest | admin | ''` (a pre-stanza seed): an **admin-set** policy is never overwritten by a manifest
declaration — reported as a `conflict` instead — a **manifest** declaration re-derives on every read, and a bare
**seed** converges in place to `manifest` the moment its module declares the stanza. `polariapps` →
`UserAppPreference` is the one real declaration; the security module ships the mechanism and seeds nobody else's
class.

**Screen:** `/display/security-owned` (op-4, ledger §69) — the gate mode and opted-in classes, the
`OwnedClassPolicy` table with `source`/`derived_from`, the modules' declarations beside the last convergence and
its conflicts, the `OwnerGrant` table, the parsed policies, and the owner gate's own `SecurityEvent` rows (where
an anonymised class's `target` is visible). Configured panels and tables only, nothing raw.

- **Not built yet:** `Ballot` rows with the governance module (op-3 — waits for that module to exist); the
  per-instance Sharing tab's frontend host (op-1); the browser pass on `security-owned` (ledger §69 OWED).

## STOMP subscribe follows the CRUDE posture

His rule: STOMP should just follow the CRUDE security posture — they should be the same (ledger §65). Until this
built, any socket could subscribe to any live-update topic with no identity and no verdict at all. Now a
subscribe asks the exact same `permission_verdict(…, 'read')` question the CRUDE gate asks, under the same
knob, with the bearer read from the WebSocket upgrade, the `Sec-WebSocket-Protocol` header (the browser
convention, since the JS WebSocket API cannot set arbitrary headers), or the CONNECT frame. `login` is never
read, and only the `sub` and `groups` claim ever reach the socket. `events` is derived from `read`, never
granted separately.

**advisory** (the deployed mode) registers the subscription anyway and sends a `MESSAGE` frame on the topic
carrying `X-Polari-Permission-Advisory: would-deny <Class>:read`, marked so a client can tell it apart from a
real change notice. **enforce** sends an `ERROR` frame with the same header and never adds the socket to the
topic. **off** computes nothing, byte-identical to before.

- **Built** (ct-6 frontend, ledger §68) — the Angular STOMP client now sends the bearer on every (re)connect:
  `beforeConnect` re-reads the token and rides it on the **CONNECT frame**, the third place
  `accessControl/stomp_identity.py` looks; signed out = no header = an anonymous socket, byte-identical to
  before. An advisory `MESSAGE` frame (`X-Polari-Permission-Advisory` and/or the body's `polariNotice`) is
  diverted at the one chokepoint every watcher passes through, so it can never trigger a refetch or a loop. A
  refused SUBSCRIBE **degrades, it does not kill**: the class is marked refused and `watchChanges` merges a 60 s
  tick, so that one panel keeps its last data and keeps updating slowly while every other subscription on the
  page stays live. The four HTTP advisory headers (`X-Polari-Permission-Advisory`, `X-Polari-Owner-Advisory`,
  `X-Polari-Traffic-Advisory`, `X-Polari-Auth`) are read by an interceptor (registered last, after every other
  interceptor) into `SecurityAdvisoryService` — a deduped, counted list capped at 200 — and surfaced as **one**
  counted line on the existing system-notice bar (*"Security advisory (dev): 3 would-deny, 1 would-project (seen
  42 times)"*), expandable, coloured amber or info-blue by outcome, in both light and dark mode. `enforce` is
  still not a deployed mode (his rule) — it is simply no longer unsafe for live updates once this ships.
- **Not built yet:** the browser pass on the home stack — the signed-in socket carrying the bearer, the advisory
  notice under real load, the HTTP advisories climbing rather than growing the list, `enforce` flipped
  temporarily and put back, the four headers surviving the nginx hop cross-origin, and a reconnect past token
  expiry (ledger §68 OWED); a fallback path for the three direct `watchTopic` consumers if `enforce` ever
  becomes a deployed mode; `REFUSED_FALLBACK_POLL_MS` (60 s) is a guess, not a measurement.

## What is not built yet, all in one place

- **op-3** — `Ballot` rows, with the governance module (waits for that module to exist).
- **The Sharing tab's per-instance page host** — the backend and the tab's data (`sharing.table`) are complete;
  there is no per-instance page anywhere in the frontend to render it on (op-1).
- **The objects view's third declared source** — configuration knobs (`PeerNode`,
  `OdooInstanceConfig`/`OdooModelBinding.direction`, `GrpcExposure`, `apiFormatConfig.*WsEnabled`,
  `PeerAgreement.scope`, shared-DB co-residency) that declare a flow without a manifest stanza or a confirmed
  traffic policy (ct-5).
- **`app.flows` on the other 59 modules** — `security` and `odooconnect` are declared; the rest will show as
  undeclared the first time they flow, which is the design's intent until the sweep runs (ct-7).
- A converge-every-app sweep for security decisions (today converge only runs on read), and wiring the release
  gate to cite coverage.
- **Every browser pass**: the Trace tables, the five closure panels, `security-objects`, the traffic
  suggestions/policy tables, `security-owned`, the apps-security coverage page, and the STOMP advisory notice bar
  under real load have all been driven only over the API or unit-tested, never seen by eye.

Operator walkthrough with curl examples for role-play, tracing, traffic and decisions:
`AI-Notes/guides/ROLEPLAY_PERMISSIONS_GUIDE.md`.
