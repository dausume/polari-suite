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
- **Doors:** `GET|POST|DELETE /api/security/observe/trace` (status/arm/disarm), `GET
  /api/security/trace/edges` (the map, filterable by `?target=|cause=|effect=|means=`), `GET
  /api/security/trace/journal` (the journal, `?trace_id=|class=`), `GET /api/security/observe/closure`
  (`?profile=|event=|role=|class=`, or no parameter for the armed target).
- **Pages:** `/display/security-events` carries the Trace status/targets/edges tables and five closure panels
  (objects, solutions, events, flows, and the not-traced list) — configured tables and structured panels, no raw
  JSON (security_page.py rows for `security-trace-*` and `security-closure-*`).
- **Not built yet:** the `objects` topology view (ct-5) that `declared_flows()` was shaped to compare against;
  `ObservationSession.task` grouping for a per-person review (ct-7); a live two-instance proof that
  `X-Polari-Trace` produces matching edges on both sides; the browser pass on the Trace tables and the five
  closure panels (ledger §61, §63 OWED).

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
- **Not built yet:** the `objects` topology view that draws `declared_flows()` against the causal map's own
  `external:`/`peer:` edges as a drift report (ct-5); the browser pass on the three new panels. One named,
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

- **Doors:** `GET /api/security/owned` (the opted-in classes and their policies), `GET|POST
  /api/security/owned/{class_name}` (admin sets or replaces a policy), `GET
  /api/security/owned/{class_name}/{object_id}` (the caller's own verdict on one instance, evidence-bearing).
- **Not built yet:** `OwnerGrant` rows and the per-instance Sharing tab (op-1); the remaining anonymised side
  channels — `SecurityEvent.target`, transfer behaviour (op-2); `Ballot` rows with the governance module (op-3);
  the `app.owned` manifest stanza (op-4); and there is **no screen yet at all** for the policies themselves or a
  per-instance verdict — only the doors (ledger §60 OWED).

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

- **In progress:** the Angular client sends no bearer yet — neither on the WebSocket upgrade nor on CONNECT — so
  on a live stack every socket is still anonymous, and nothing yet reads the advisory header or handles an
  `ERROR` frame on subscribe. Until that lands, `enforce` would silently stop live updates for real users, which
  is exactly why `advisory` stays the deployed mode (ledger §65 OWED).
- **Not built yet:** a live proof with a real WebSocket client and a real Keycloak bearer (selftested only, 41/41
  — ledger §65); the browser pass confirming an advisory notice does not loop a page's refetch and a refused
  subscribe degrades to polling rather than a dead panel.

## What is not built yet, all in one place

- **ct-5** — the `objects` security topology view (declared vs. observed flows, drift report).
- **ct-7** — `ObservationSession.task`, review grouped by task.
- **op-1** — `OwnerGrant` rows and the per-instance Sharing tab.
- **op-2** — the remaining anonymised-class side channels (`SecurityEvent.target`, transfer).
- **op-3** — `Ballot` rows, with the governance module.
- **op-4** — the `app.owned` manifest stanza.
- A converge-every-app sweep for security decisions, and wiring the release gate to cite coverage.
- **The Angular STOMP bearer** and reading the three advisory headers in the frontend generally.
- **Every browser pass**: the Trace tables, the five closure panels, the traffic suggestions/policy tables, and
  the apps-security coverage page have all been driven only over the API, never seen by eye.

Operator walkthrough with curl examples for role-play, tracing, traffic and decisions:
`AI-Notes/guides/ROLEPLAY_PERMISSIONS_GUIDE.md`.
