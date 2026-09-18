# Causal tracing and object flow (ct arc) — what an event really touches, and where objects go

**Date:** 2026-09-18 · **Status: DESIGN ONLY — nothing in this file is built.** Plan
`AI-Notes/plans/ISLE_HARDENING_PLAN.md` §17d. Builds on the ROLE-PLAY → REVIEW →
CONCRETE → VERIFY arc (§17b, built), the no-code event dispatcher
(`polariNoCode/event_dispatcher.py`, built), the remote-write journal (xsim-4,
`polariRefs/write_journal.py`, built) and the security topology views
(sec-i-1, `modules/security/custom/security_topology.py`, built).

His ask (2026-09-18, verbatim intent): "What we want to start doing is thinking
through what sort of things are needed for particular individuals. We also need
to think through if it is possible to implement the capability to trace
different events and functions (so long as they are going through Polari, else
we just notate what external system we are sending it to and how) and then
also being able to track the kinds of changes that occur due to those events.
This way we can do a complete mapping of what all is affected and triggered in
terms of both events and object instances. This way we can see what implicit
permissions we may be granting by granting event permissions. And because we
are going to want to make topologies of objects that track how object
instances may propagate between systems."

**Is it possible?** Yes, and cheaply, because the framework already funnels the
three things that matter through one place each: every trigger firing goes
through `EventDispatcher.fire()` and writes a `TriggerFiring` row that carries
its source and depth; every tree-object creation passes `treeObject.__init__`
and every delete passes `noteTreeDeletion`; and every API request passes one
middleware chain. What is missing is a **cause** that travels with execution
from the entry point down to those seams, a **map** that accumulates
cause → effect edges without duplicating itself, and a **wrapper** around the
outbound calls, which today are twenty ad-hoc `requests`/`urllib` sites with
nothing in common. The one hard boundary is real: a thread started with
`threading.Thread` does not inherit a contextvar, so every background worker
must be handed its cause explicitly — there are seven of them and they are
listed in §4.

## 1. What today's rows answer, and what they cannot

| row | answers | cannot answer |
|---|---|---|
| `PermissionObservation` (groups × class × verb, counted) | who acts on which class directly | what that act went on to cause |
| `UsageObservation` (role × app/page/action/endpoint) | which doors a role walks through | what is behind the door |
| `TriggerFiring` (`source_ref`, `depth`, `execution_id`) | that trigger T fired because of `MealEntry:x:update` at depth 2 | which request or person was at depth 0; what the solution then wrote |
| `ExecutionStepSnapshot.ObjectChange` (per-node before/after diff) | exactly which instances a solution step changed | anything outside that one execution; it is trace-scoped memory, not a ledger |
| `WriteJournalEntry` (remote writes only) | every automated cross-instance write and its outcome | any local write |
| `OdooSyncReceipt`, `IsleIngestReceipt` | what one external sync moved | the same question for every other external system |
| `SecurityTopologyEdge` (os/network/app views) | who can reach what, by which means, under which mode | where **objects** go — no view has a payload column |

The permission model is strictly **class × verb, instance-wide**
(`modules/polariapps/objects/apps_permissions/_shared.py:4` `CRUDE_VERBS`). The
`events` verb is in the vocabulary and the gate says out loud that it is not
enforced (`accessControl/app_permissions_gate.py:20-21`); STOMP subscription to
any `/topic/{Class}` is unauthenticated (`stompWebSocketServer.py:140-145`); and
an `EventTrigger` runs its solution as the **definer** (`event_triggers.py:50`,
`run_as`). So today a `read` grant on class X silently covers X hydrated from a
peer, X carried out in a module bundle, and X broadcast over STOMP; and an
`update` on a class with a trigger on it silently runs somebody else's solution
with somebody else's authority. That is the implicit grant he is asking to see.

## 2. The model — one target, one cause, two ledgers, one wrapper

**His rule (2026-09-18): "we should always only be doing tracing for one kind
of object at a time and be able to put limits on how many tracing objects we
generate at a time, or we could easily overwhelm ourselves in terms of
data."** So recording is OFF unless exactly one **`TraceTarget`** is armed,
and the target is one class:

| field | meaning |
|---|---|
| `class_name` | the ONE class being traced; a second `POST` while one is armed is refused naming the active one |
| `verbs` | which verbs on that class open a trace (default all five) |
| `max_traces` | distinct trace ids this target may open (default 200) |
| `max_edges` | map rows this target may write or bump (default 500) |
| `max_journal_rows` | instance-level rows this target may write (default 5 000) |
| `max_depth` | how far down a chain recording follows (default 8, the trigger default) |
| `window_seconds` | the target disarms itself after this long (default 3 600) |
| `started_by`, `started_at` | the arming person (Keycloak `sub` only) and when |
| `stopped_at`, `stopped_because` | `budget-traces` / `budget-edges` / `budget-journal` / `window` / `manual` |
| `traces_opened`, `edges_written`, `journal_written`, `dropped` | live counters, persisted through the debounce |

**Scope rule.** A chain becomes *traced* at the first seam that touches the
target class — the CRUDE gate sees `class_name`, `noteTreeMutation` sees the
class, the dispatcher sees the class in `source_ref`. From that point the
edge that reached the target (so we know *what reaches T*) and everything
downstream of it (so we know *what T reaches*) are recorded, to `max_depth`.
A chain that never touches the target writes nothing: the cause context is
still minted (a dict, cheap) but both ledgers ignore it. This is the
per-class closure he wants, gathered one class at a time.

**Budget rule.** Every write first checks the target's counters. The first
budget hit disarms the target, stamps `stopped_because`, and raises one
`SecurityEvent` (the `observe-mode` notice pattern) so the stop is seen, not
silent. `dropped` counts everything the ledgers declined after the stop
inside the window, so a map read as "complete" can be checked against it.
The map as a whole also has a ceiling (`POLARI_TRACE_MAP_MAX_ROWS`, default
5 000; oldest `last_seen` pruned) so twenty targets over a year cannot grow
it without bound. Journal rows carry the target's id and are **cleared when
the next target is armed** — the journal is evidence for the current
question, the map is what is kept.

**Coverage, not silence.** Because only traced classes have edges, every
closure answer (§6) and the object topology (§7) carry a `coverage` block:
which classes have ever been a target and when. A closure over an untraced
class answers **"not traced"**, never "nothing reaches it".

**Dev only (his ruling 2026-09-18): "tracing should not occur in production,
only finalized security posture rows derived from them."** A `TraceTarget`
cannot be armed outside dev posture (the `can_roleplay` pattern: production
→ refused, with the reason), neither ledger is written there, and the cause
context is not minted. What reaches production are the DERIVED rows that
already exist as ordinary objects — `AppPermissionProfile`, `OwnedClassPolicy`,
the traffic policies of §5a, `RoleAppBinding` — carried the way any row is
carried (seed, manifest stanza, or a module bundle), each keeping the
`derived_from` evidence that names the dev review it came from.

**A `CauseContext`** is a small dict that travels with execution: `trace_id`,
`parent_id`, `entry_kind` ∈ api | trigger | schedule | solution | simulation |
peer | ai | boot, `entry_ref` (e.g. `PUT /api/MealEntry/{id}`, `trigger:daily
rollup`, `solution:score-article`), `actor` (Keycloak `sub` ONLY — D18-1, never
a name), `groups`, `roleplay`, `depth`. It is a `contextvars.ContextVar`
modelled exactly on `simulationLocks/run_context.py` (`push_run` /
`pop_run` / `current_run`), which the tree already reads from deep inside
`objectTreeDecorators.py:106` and `polariCRUDE.py:363`. A child cause is pushed
whenever execution crosses one of the seams in §4, with `parent_id` set and
`depth + 1`, so the chain is recoverable without any global registry.

**Ledger A — `CausalEdge`** (the MAP; aggregate, counted, never duplicated —
his rule from §17b): one row per **(cause node, effect node, means)** with
`count`, `first_seen`, `last_seen`, `min_depth`, `max_depth`, `run_as` and a
`sample_trace_id`. Nodes are strings of the form `kind:ref`:

| kind | ref | example |
|---|---|---|
| `endpoint` | METHOD path-template | `endpoint:PUT /api/MealEntry/{id}` |
| `object` | Class:verb | `object:MealEntry:update` |
| `event` | trigger or emitted-event name, or a STOMP topic | `event:trigger:daily-rollup`, `event:topic:MealEntry` |
| `solution` | no-code solution name | `solution:score-article` |
| `peer` | PeerNode name + mechanism | `peer:kitchen-node:lease-write` |
| `external` | system kind + configured name | `external:odoo:main`, `external:keycloak:admin`, `external:s3:appstore` |
| `schedule` | trigger name | `schedule:nightly-compost` |

`means` is how the edge was crossed: `crude`, `trigger-fire`, `emit`,
`solution-run`, `ws-publish`, `ws-subscribe`, `shared-db`, `lease-write`,
`bundle-export`, `bundle-install`, `send` (external, with the wire in `detail`:
json-rpc, rest, s3, grpc, mqtt). Class-level only: an instance id never
appears in this ledger, so it stays small (hundreds of rows, not millions) and
survives restarts through the same debounced persist the observations use.

**Ledger B — the effect journal** (per trace, instance-level, retained for a
window): `WriteJournalEntry` generalised from "remote writes only" to every
write, with four new columns — `trace_id`, `cause_ref`, `verb`, `origin`
(local | remote) — and the existing `class_name`, `object_id`,
`fields_changed_json`, `outcome` kept. This is the evidence behind a map
edge and the answer to "which instances did *that* request change". It is
**dev-posture only**, like the map and the target (his ruling, §2 above),
ring-buffered (`POLARI_TRACE_JOURNAL_ROWS`, default 20 000) and swept by the
same one-shot boot scrub pattern as §53's PII scrub. Production has neither
ledger; it holds only the finalized rows derived from them.

**The outbound wrapper** — one function every call to another system goes
through: `outbound.send(system_kind, system_name, means, payload_classes,
fn)`. It records `external:` (or `peer:`) edges under the current cause,
adds `X-Polari-Trace: <trace_id>/<parent_id>` to requests bound for another
Polari instance (never the actor — the sub stays home), and is a no-op
recorder when there is no cause. Beyond the wrapper Polari cannot see, and
does not pretend to: the edge says **what left, to which system, by which
wire**, which is exactly his "else we just notate what external system we are
sending it to and how".

## 3. What is recorded where — the seams

| seam | file:line today | what it records |
|---|---|---|
| mint the root cause | new `CauseContextMiddleware` right after `AuthContextMiddleware` (`polariServer.py:470`), before `RoleplayObserverMiddleware` | `api` cause: endpoint, actor sub, groups, roleplay |
| the CRUDE gate | `app_permissions_gate.py:41` `crude_permission_gate(manager, request, response, verb, class_name)` — the 6 call sites in `polariCRUDE.py` | edge `endpoint → object:Class:verb` (means `crude`); today's `PermissionObservation` call is already here |
| creates | `objectTreeDecorators.py:97` `noteTreeMutation(cls, id)` from `treeObject.__init__` | journal row (create) under the current cause |
| updates | `objectTreeDecorators.py:115` `treeObject.__setattr__` — gains a `noteTreeMutation` call it does not make today | journal row (update, field) |
| deletes | `objectTreeManagerDecorators.py:681` `noteTreeDeletion`; cascades from `deleteTreeNode:1467` (`instancesDeleted`, `migratedInstances` already computed) | journal rows for the whole cascade under one cause |
| trigger firing | `event_dispatcher.py:173` `fire()` / `:151` `_record` | push a child cause (`trigger`); `TriggerFiring` gains `trace_id` + `parent_id`; edge `object:X:verb → event:trigger:T` (means `trigger-fire`), and `event:trigger:T → solution:S` (means `solution-run`, `run_as` recorded) |
| emitted events | `SolutionExecutionEngine.py:681/706` → `dispatch_trace_events` | edge `solution:S → event:E` (means `emit`) |
| nested solutions | `SolutionExecutionEngine.execute:665` (`_invocation_chain` already threads through) | child cause per nested run; edge `solution → solution` |
| change broadcast | `transport_mux.publish_change:56` → `stompWebSocketServer.publish:214` | edge `object:X:verb → event:topic:X` (means `ws-publish`); subscriptions counted as `ws-subscribe` per group once STOMP knows the caller (ct-6) |
| schedule / window ticks | `event_dispatcher.tick:274` on the `polari-event-tick` thread (`:331`) | a ROOT cause per tick (`schedule`), passed explicitly — no request to inherit from |
| simulations | `simulationLocks/gate.py:55` `push_run` / `simulation_runner.run_step:54` | a `simulation` cause pushed beside the run context; every row `run_step` creates (`:1125`) journals under it |
| remote writes | `polariRefs/remote_writes.py` → `journal_write:40` | already journaled; gains the cause and becomes a `peer:` edge (means `lease-write`) |
| shared-DB reads / hydration | `polariRefs/remote_hydration.py:162`, `managedDB.py:677/707/730` | edge `endpoint → peer:N:shared-db` with `payload_classes` |
| bundle export / install | `polariPeers/module_exporter.py`, `peers_api.py:372` `POST /api/modules/install`, `module_data_move.py:226` | edge `peer` (means `bundle-export` / `bundle-install`) with the class list from `manifest.requiredClasses` |
| inbound from a peer | `polariPeers/*_api.py` responders | the middleware reads `X-Polari-Trace` and mints a `peer` root cause with `parent_id` = the remote id, so the map on the receiving side joins the sender's chain |
| external sends | the wrapper, adopted by the twenty sites in §5 | `external:` edges |
| AI executors | `polariApiServer/ai_actions.py:181` `_record` (already writes `data/ai_provenance.jsonl`) | mint an `ai` cause carrying the `proposal_id`; the provenance line gains the `trace_id` |
| seeds / boot | `moduleService/seed_upsert.py:53/107`, module boot | a `boot` root cause so seeded rows are never attributed to a person |

## 4. The thread boundary (the one honest limitation)

Contextvars follow synchronous execution and nothing else. Seven places start
a thread today and each must be handed the cause by argument or mint its own
root: `persist_debounce.py:90` (persist — no cause needed, it writes what was
already caused), `event_dispatcher.py:331` (tick — root `schedule` cause),
`quiesce.py:265`, `lazy_boot.py:635` (root `boot`), `tileGeneratorAPI.py:179`
(child of the request that asked), `security_observe.py:137` (PII scrub —
root `boot`), `security_page.py:175`. A selftest lists every
`threading.Thread(` / `Timer(` in the tree and fails when one appears that is
not in the known table — the same "stated, not silent" idiom as §17's
`INVARIANT_CONTROLS`.

## 5. Outbound sites to bring under the wrapper

Two libraries side by side, no shared timeout/retry/log:
Keycloak (`accessControl/keycloak_client.py:69,109,146,174`;
`modules/security/custom/kc_admin.py:85`; JWKS `authMeAPI.py:104`), Odoo
(`modules/odooconnect/custom/odoo_client.py:61`), LiveKit
(`modules/collab/livekit_remote.py:112,174`), Reticulum
(`modules/reticulum/rns_remote.py:70,88,130`), materials engines
(`materialsScience/engines/remote.py:88,110`, the only one with metering), CAD
and CNT remotes, the provider probe (`topology/provider_registry.py:62`),
polariPeers (`peers_api.py:78`, `join_flow.py:83,92`), HTTP-to-self AI
executors (`ai_actions.py:57`, `ai_tools.py:82`), LocalAI / OpenAI-compatible
(`reasoning_provider.py:126`, `voiceAPI.py` — audio content is never logged,
and the wrapper records payload *classes*, never payloads), MinIO
(`managedObjectStore.py:44,187`, `appstore_minio.py:43`), MQTT
(`mqttbridge/mqtt_api.py:118`). The wrapper is adopted site by site; a guard
selftest greps for `requests.` / `urllib.request` outside `outbound.py` and
lists the stragglers, so the migration is visible rather than assumed (the
same shape as the build-docs privacy guard).

## 5a. Traffic policies — closed by default, suggested from monitoring

His ruling (2026-09-18): the outbound guard is tracked in dev as well, it
is **closed by default**, and outbound AND inbound allow-lists are
**suggested from monitoring traffic in and out of Polari**, the same way
acts inside Polari are observed and turned into a proposed profile — with
the one honest limit that objects cannot be tracked once they are outside.

- **`OutboundPolicy`** — one row per (system kind, system name, wire):
  `payload_classes` allowed, `state` (`suggested` | `confirmed` | `denied`),
  `derived_from` (the dev observation that proposed it), `confirmed_by`
  (a `sub`), `confirmed_at`. The wrapper of §2 consults it: production
  refuses any send with no `confirmed` row (closed by default); dev posture
  records the send, raises a `would-deny` advisory and lets it through
  (§17: dev warns, never blocks — this is the reading taken; if outbound
  should block even in dev, say so and the dev branch becomes `enforce`).
  Every observed send with no row creates a `suggested` row, so the
  suggestion list IS the monitoring.
- **`InboundPolicy`** — one row per (source kind, source): a `PeerNode`
  name, a CORS origin, `anonymous`, or a configured external caller;
  `paths` (endpoint templates observed), `state`, `derived_from`,
  `confirmed_by`. The middleware records inbound callers in dev the same
  way (never a raw address in a row — the peer's name, the origin host,
  or a class such as `anonymous`), proposes rows, and production refuses
  what no confirmed row allows.
- Both are **finalized posture rows** in his sense: derived in dev,
  confirmed by a person, enforced in production, and both feed the
  `objects` topology view as `declared` edges beside the knobs of §7.
- The code-level guard (bare `requests`/`urllib` outside the wrapper)
  stays: it lists stragglers in dev and fails the selftest once the twenty
  sites are migrated, because an unwrapped call is a send the policy
  cannot see.

## 6. The closure — implicit permissions made explicit

`closure(start_nodes)` walks Ledger A from a set of start nodes and returns
everything reachable, grouped: `objects` (class × verb), `events`,
`solutions` (with `run_as`), `peers` (with mechanism and payload classes),
`external` (system, wire, payload classes), each with the evidence (count,
last seen, min depth, sample trace), plus the `coverage` block from §2 so
an empty branch reads "not traced" where that is the truth. The target
itself has its own door — `GET`/`POST`/`DELETE /api/security/observe/trace`
(status with counters; arm one class with budgets; disarm) — and the
`security-events` page gains a Trace tab showing the one armed target, its
counters and the coverage list. Three doors use the closure:

- **`GET /api/security/observe/closure?profile=<name>`** — start nodes are the
  profile's explicit class × verb grants. `implicit = reachable − explicit`.
  This is *what you are really granting* when you publish that profile.
- **`?event=<trigger or topic>`** — start node is one event. This is *what
  an event permission means*: the solution it runs and as whom, everything
  that solution writes, and everything those writes trigger in turn.
- **`?role=<role>`** — the role-play review (`review(role)`, §17b) gains a
  `closure` block, so the permissions admin concreting a profile sees the
  transitive effects beside the direct ones, and `verify(role, group)` gains
  a second verdict: *"the profile covers N of M transitively-touched class ×
  verb pairs; K are reached only through triggers running as definer"*.

**Accountability (his ruling 2026-09-18).** Every item the analysis proposes
for enforcement — a class × verb, a trigger and the solution it runs, a
peer or external edge — carries its evidence (counts, first/last seen,
sample trace, which role-play session and task) and its origin
(`observed` | `closure` | `declared`), and the proposal is applied by a
PERSON: the concrete step (§17b) is a confirmation with a `confirmed_by`
sub and the proposal's hash, never an automatic write; nothing widens
itself and nothing flips to `enforce` on its own. Under `advisory` the
response carries the closure's would-deny set as today's advisory header
does.

**Coverage accounting (his rulings 2026-09-18: "track how many objects have
any kind of security coverage and how much if any" and "track security
policy decisions of different types and how many have been covered per
app, since security must be worked on at a per-app basis and per each
version release").** Security is a per-app, per-release job, so the unit
of accountability is a **decision** and the unit of coverage is an **app
version**:

**`SecurityDecision`** — one row per subject that needs a ruling:

| field | meaning |
|---|---|
| `app`, `app_version` | the Polari-App and its manifest version (`polari-app.json`); `release` = the Polari calendar tag it shipped in |
| `kind` | `profile-verb` (class × verb for a group) · `owner-policy` (a class opted in or explicitly not) · `outbound` · `inbound` (§5a) · `trigger-run-as` (a trigger's solution and the authority it runs with) · `flow-declared` (`app.flows`) · `role-binding` (`app.roles`) · `trace-coverage` (the class has been traced) |
| `subject` | `Class:verb`, `system:name:wire`, `trigger:name`, … |
| `state` | `open` (subject exists, nobody has ruled) · `suggested` (the analysis proposed, with evidence) · `confirmed` · `denied` · `inherited` (carried from the previous version, subject unchanged) · `stale` (inherited but the subject changed in this version) |
| `evidence`, `derived_from` | counts, sample trace, the review/session/task that produced it |
| `confirmed_by`, `confirmed_at` | the person (a `sub`) — required for `confirmed` and `denied`; nothing confirms itself |

Subjects are **enumerated from the app, not from what happened to be
observed**: every class the app carries × five verbs × the groups that
touch it, every class as an owner-policy candidate, every trigger, every
outbound site the wrapper knows, every inbound source seen. So `open`
rows are real gaps, not silence. On a new app version the previous
version's rows carry forward as `inherited`; a subject the version
changed (a new or altered class, trigger or flow) flips to `stale` and
must be re-ruled, so a release never ships on last release's rulings for
something it changed.

**Coverage per app × version** is then a count, by kind: subjects total,
and how many are `confirmed` / `denied` / `inherited` / `suggested` /
`open` / `stale`, plus the instance count under each class so "how many
objects" is answered in rows of data as well as in classes. `coverage`
for the app version reads `none` / `partial` / `full` (full = no `open`
or `stale` rows of any kind). The totals sit on the security page and on
each app's own page as configured tables (no raw JSON, no new component),
and the release gate can cite them: a release with `stale` rows says so
in the manifest's findings. `verify` and the review cite the same rows,
so a suggestion never claims more than the ledger shows.

## 7. The object topology — a fourth security view

`SecurityTopologyNode`/`SecurityTopologyEdge` already carry `view`,
`scenario`, `mode`, `source`, `target`, `means`, `chain`, `decided_by`,
`provenance`, `verdict`, `why`, and the builders are a dispatch table
(`security_topology.py:302` `BUILDERS`) with `simulate()` and `compare()`
behind them. An **`objects` view** is a fourth entry in that table plus a
fourth `SecurityDomain` row; the only schema change is one new edge column,
`payload` (class names + counts), because no existing view says *what* flows.

- **Nodes:** this instance, each `PeerNode`, each configured external system
  (`OdooInstanceConfig`, the Keycloak realm, each S3 bucket/provider row), and
  the classes as a `layer` beneath the instance.
- **Edges, two provenances:** `declared` — what the knobs say may flow
  (`GrpcExposure`, `apiFormatConfig.*WsEnabled`, `OdooModelBinding.direction`,
  `PeerAgreement.scope`, shared-DB co-residency from
  `object_ownership._storage_identity`); and `observed` — Ledger A's `peer:`
  and `external:` edges. `compare(declared, observed)` is the drift report:
  a class that flows with no knob declaring it is a finding; a knob that
  declares a flow never seen is noise to prune.
- **`simulate(actor, grant)`:** from a person with a given profile, what can
  leave this instance and to where — the same per-actor reach the os/network/
  app views compute, over object flow instead of process reach.
- **Chain:** `[PeerAgreement, MutationLease token, ObjectLockEntry,
  GrpcExposure, direction knob, permission_verdict]` — the consent chain the
  group-authority plan calls "defined on both sides", now visible per edge.

The `security-threat-sim` panel and the existing page tabs render it; no new
component (his rule). Instance ids never appear on the topology — classes and
counts only; the journal is where an instance is looked up.

## 8. What particular individuals need

A person's needs are the union of the tasks their held roles perform (§57:
primary role + additional roles), and a task's needs are the closure of the
doors it walks through. That gives one concrete change to the role-play
loop: an `ObservationSession` gains a `task` label ("publish an article",
"reconcile last week's meals"), usages and edges recorded during the session
are attributed to it, and `review(role)` groups by task, so a role's profile
reads as *tasks → doors → closure* instead of a flat class list. Because
tracing is one class at a time, a role's full closure is gathered in rounds:
the review lists the classes the role touches, marks which have been a
target, and names the **next target** (the most-used untraced class in the
role's observations) so the admin arms them one after another rather than
guessing. The
personas the demo already seeds, and what tracing has to give each:

| person | tasks (examples) | what they need from this arc |
|---|---|---|
| journalist | write, score, publish | to keep doing the job after enforce — `verify` including the closure |
| data scientist | run a sim, read peer rows, export a bundle | to see which peers and buckets a run reaches before running it |
| operator (household / kitchen) | log meals, approve a plan | a small profile whose triggers do not run as someone with more authority |
| permissions admin | concrete + verify a profile | the closure beside the direct list; the drift report; a would-deny set before flipping to enforce |
| app author | ship a module with triggers and connectors | a manifest that can declare its own flows (`app.flows`, §9) and a selftest that says when the observed map exceeds the declaration |
| peer-instance operator | accept an agreement | what the other side may pull, by class, before signing (`PeerAgreement.scope` finally means something) |
| the person whose data it is | none of the above | the `sub`-only rule holds in every new row; names resolve through the one gated door (§53) |

## 9. Manifest stanza (the app half)

The Standard Polari App manifest gains `app.flows`: a declared list of
`{to: "odoo" | "peer" | "s3" | "provider", classes: [...], direction:
push|pull|both}`. It is the `declared` half of §7 for an app, validated by
`moduleService.manifests` like `app.roles` is, and the drift report compares
it with the observed map. Apps that declare nothing get a finding the first
time something flows, not a block — dev posture warns, never blocks (§17).

## 10. Decisions — all taken (his rulings 2026-09-18)

- **Tracing in production:** none. Neither ledger, no target, no cause
  context. Production holds only the finalized posture rows derived in dev
  (§2).
- **STOMP:** follows the CRUDE posture — the same `permission_verdict`, the
  same profile, the same `off | advisory | enforce` answer. Subscribing to
  `/topic/<Class>` is allowed exactly when `read` on that class is; the
  `events` verb stays in the vocabulary for compatibility and is derived
  from `read`, not granted separately (ct-6).
- **Enforcement:** the proposal accounts for everything, direct and
  transitive, with evidence; a person confirms; nothing enforces itself
  (§6).
- **Coverage:** counted per class and per instance, shown as none /
  partial / full (§6).
- **Outbound and inbound:** closed by default; observed in dev; suggested
  rows confirmed by a person; enforced in production (§5a).
- **Triggers as definer:** kept; every definer-run edge is shown in the
  closure and is part of what the person confirms.
- Defaults that follow from earlier rules: `X-Polari-Trace` carries trace
  ids only, never the sub; a second target is refused naming the active
  one; budgets 200 / 500 / 5 000 / depth 8 / one hour, editable; journal
  cleared on the next arm, map kept; the object topology is a fourth
  security view.

## 11. Slices (ct-0 … ct-9)

| slice | builds | proof |
|---|---|---|
| **ct-0** cause context | `CauseContext` contextvar + middleware; `trace_id`/`parent_id` on `TriggerFiring` and `ExecutionTrace`; the thread table + its selftest | a request → a trigger → a solution share one trace with depths 0/1/2 |
| **ct-1** the target, the map, the journal | `TraceTarget` (one armed class + budgets + counters) and `CausalEdge` rows (security module; bump the class count and the five registration sites); the scope rule at the CRUDE gate, `noteTreeMutation`/`noteTreeDeletion`, `__setattr__`; journal columns; `/observe/trace` doors; the map ceiling; persisted through the debounce; nothing records with no target armed | counts, no duplicates, survive a restart (the §17b proof rerun); a chain on another class writes nothing; `max_edges` hit → target disarmed, `stopped_because` set, one SecurityEvent, `dropped` counting |
| **ct-2** event edges | fire / emit / nested-solution / ws-publish edges with `run_as`; schedule + simulation + boot root causes | the closure of one trigger lists its solution and every class it writes |
| **ct-3** outbound + peers | `outbound.py`, adoption of the §5 sites, `X-Polari-Trace` both ways, the straggler guard | an Odoo push and a peer lease-write appear as edges on both instances |
| **ct-4** closure doors + review | `/observe/closure` (profile / event / role); `review` gains `closure`, `verify` gains the transitive verdict; tables on `security-events` via configured displays | the journalist review shows what its triggers reach; nothing raw on screen |
| **ct-5** the `objects` view | fourth `SecurityDomain` + builder + `payload` column; declared vs observed; simulate/compare | drift report on `polari-lean` after a role-play session |
| **ct-6** STOMP = CRUDE posture | the subscribe path calls the same verdict as CRUDE `read` under the same mode; `ws-subscribe` edges | demo-viewer subscribing to an out-of-profile class carries the advisory header; enforce refuses it |
| **ct-7** tasks + needs | `ObservationSession.task`; review grouped by task; `app.flows` validation | the journalist profile reads as tasks → doors → closure |
| **ct-8** decisions + coverage | `SecurityDecision` rows enumerated per app × version by kind; inherited/stale on a version bump; `confirmed_by` required; totals per app × version on the security page and the app page; the release gate cites them | publishing a profile confirms its rows; a class added in a new version shows `open`; a changed trigger shows `stale`; a concrete without a confirmer is refused |
| **ct-9** traffic policies | `OutboundPolicy` / `InboundPolicy`, suggested from the wrapper and the middleware in dev, confirmed by a person, closed by default in production; declared edges on the topology | an unconfirmed Odoo push is advisory in dev and refused in production; the suggestion row appears from one observed send |

Rules that hold throughout: security WARN-ONLY in deployments (§17); every
person keyed by Keycloak `sub` alone (D18-1); nothing raw on a screen; no new
reusable component; commit innermost-first, push every repo; keep the
handoff current.
