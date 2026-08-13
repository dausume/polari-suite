# Reticulum as a Polari transport — plan (ret-0..ret-9)

**Date:** 2026-08-12 · **Status: PLANNING ONLY, nothing built.**
Source: Dustin's brief — "leverage Reticulum as one of our main forms
of communication via OpenWRT… convert signals from arbitrary internet
protocols and detect when they are being routed to a Reticulum address
in the router… send data in JSON or gRPC… gRPC over LoRa… another isle
that is OpenWRT-based and uses Reticulum with LoRa, and they could talk
to each other."

Companions: `MESH_APP_CONVERGENCE_HANDOFF.md` (isle/app convergence),
`ISLE_ONBOARDING_HANDOFF.md` (apt-on-mesh, `isle core-install`),
`LIVEKIT_COLLABORATION_PLAN.md` (whose §2 rule this plan inherits
wholesale), and the `grpcbridge` module (grpc-1/2/j1/j2 built).

---

## 0. The boundary this plan must not cross

⛔ **Isle networking lives on isle-core, with its own Claude** (standing
instruction, restated in the isle route-priority handoff). OpenWRT
packaging, radio configuration, antenna/RF work, regulatory duty-cycle
compliance and physical deployment are ITS work, not this repo's.

So the arc splits in two, and the split is the first design decision:

| Belongs to POLARI (this repo) | Belongs to ISLE-CORE (OpenWRT box) |
|---|---|
| The object model (identities, destinations, bindings, measured link facts) | The OpenWRT package + init scripts for `rnsd` |
| The gateway service that maps app traffic ⇄ Reticulum | Radio hardware, RNode firmware, antenna, placement |
| Encodings (protobuf/CBOR/JSON) + the gRPC-over-Reticulum bridge | Regulatory duty cycle, band plan, TX power |
| `pol` CLI surface, honest refusals, provenance | `isle` CLI surface, nftables/DNS on the router |
| The propose/execute gate on inbound remote traffic | Physical link bring-up between two isles |

Anything in the right column is a REQUEST to isle-core, carried as a
document, never edited from here.

## 1. Blocking gate: the licence check (repo standing rule)

Before any code: `RETICULUM_LICENCE_GATE.md`, checked the standing
three-source way (published metadata + LICENSE file + source headers),
against the GPLv3 frame ([[project-license-gplv3]] — GPL deps are fine;
blockers are unlicensed / non-commercial / GPL-incompatible).

To check, at minimum: the Reticulum stack itself, LXMF (the messaging
layer), any RNode firmware we would flash, and any OpenWRT packaging.
⚠ My recollection is that the stack is permissive and some companion
tools are GPL — **that recollection is not evidence.** The gate decides.

## 2. The honest physics, up front

Every number below is a PLACEHOLDER until measured on our own hardware
(the repo's standing rule after the CO₂ arc: an unfetched number is not
a fact). They are here to size the design, not to be quoted.

- **LoRa gives kilobits, not megabits.** Order 0.3–37.5 kbps raw
  depending on spreading factor and bandwidth; real payload throughput
  after framing and duty cycle is a fraction of that.
- **Duty cycle is a hard budget**, not a guideline — in some bands 1%.
  Airtime is THE scarce resource on this link.
- **Reticulum's MTU is small** (order hundreds of bytes) and latency is
  seconds, not milliseconds.

**Consequence that shapes everything: gRPC-over-HTTP/2 must not be run
verbatim over LoRa.** HTTP/2's preface, SETTINGS, HPACK state and
stream framing assume a fat, low-latency pipe. Insisting on it would
produce a technically-true demo that is useless in practice — the same
failure mode the scan arc was shelved for.

**What we do instead (ret-5):** terminate HTTP/2 at each end and carry
only the protobuf message bodies over Reticulum. Same `.proto`, same
generated stubs, same service definitions — different transport
underneath. A caller writes an ordinary gRPC call; the bridge decides
whether it goes over IP or over the mesh. That is "gRPC over LoRa" in
the sense that matters, and it is honest about the sense in which it
is not.

## 3. Addressing: the actual hard part

Reticulum does not route IP. Destinations are cryptographic hashes
derived from an identity plus an app/aspect name — there is no `A`
record, no port, no TCP handshake to intercept. "Detect when traffic is
being routed to a Reticulum address" therefore means building the
mapping that does not exist yet:

1. **A name registry as ROWS** (object coherence): a human/app-facing
   name ⇄ RNS destination hash, with the identity that owns it.
2. **A synthetic IP range** handed out by the router's resolver for
   names in a reserved suffix (proposal: `*.rns.isle`), from a range
   reserved in the **netledger** — which already models CIDR pools and,
   as of mtg-0, UDP port ranges. A synthetic-IP pool is the same kind
   of scarce resource and belongs in the same ledger.
3. **A gateway daemon** that owns that range: packets to a synthetic IP
   are matched to a destination row and handed to Reticulum; nothing
   is guessed, and an unmapped address gets an honest ICMP/refusal
   rather than a silent black hole.

⚠ The DNS + nftables half of (2) runs ON the router: an isle-core
request, not our edit.

## 4. Object model (ret-1)

Classes in a new `reticulum` module (manifest-first on dyn-1, the
third module born that way after `scanning` and `collab`):

- `ReticulumIdentity` — an identity we hold or trust. **Keycloak stays
  the authority for PEOPLE** (the mtg-2 lesson: never a second
  credential store); this row BINDS a KC subject to an RNS identity
  rather than replacing it. Private keys never land in a row.
- `ReticulumDestination` — name, app/aspect, destination hash, scope
  (`local` | `mesh` | `web`), direction (in/out/both).
- `ReticulumInterface` — one physical/logical link (RNode-LoRa, TCP,
  UDP, serial), its declared parameters, and its MEASURED facts kept
  separate from its declared ones (fidelity, the resources-module
  idiom).
- `TransportBinding` — "this app protocol/endpoint reaches that
  destination", the row that makes ret-3's detection data rather than
  code.
- `LinkMeasurement` — measured throughput, RTT, loss, airtime consumed.
  This is what turns §2's placeholders into facts, and it is the gate
  that later phases read.
- `AirtimeBudget` — duty-cycle accounting per interface. The netledger
  analogue for spectrum: airtime is the scarce resource, so it is
  ledgered, not assumed.

## 5. Phases

- **ret-0 — BLOCKING PROOF, no radio.** Two `rnsd` instances on this
  LAN over Reticulum's TCP interface exchanging a payload both ways,
  with our own encoding, measured. Proves the stack, the identity
  handling and our encode/decode before any RF variable exists. If
  this is awkward, everything downstream is worse — learn it cheap.
- **ret-1 — the object model** (§4), manifest-first, with selftests.
- **ret-2 — `pol-reticulum` service**: its own compose file + `pol
  compose reticulum` role + `services.yml` entry + resource profile +
  topology seed. The walked-four-times worker pattern (msci → cad →
  recon → livekit); never part of the default `up`.
- **ret-3 — the gateway**: synthetic-IP range from the netledger, the
  name registry, and the mapper. Ships with the honest refusal ladder
  (knob → topology → suggestion) and refuses unmapped addresses by
  name. The router-side DNS/nftables half goes to isle-core as a
  written request.
- **ret-4 — encodings as a knob with evidence**: protobuf / CBOR /
  JSON, chosen per binding, with MEASURED bytes-on-the-wire reported
  beside the choice. JSON is permitted and honestly labelled as the
  expensive one; nothing silently picks for you.
- **ret-5 — gRPC over Reticulum** (§2): terminate HTTP/2 at each end,
  carry protobuf bodies, reuse `grpcbridge`'s existing service
  definitions. Unary calls first; streaming only if ret-6's numbers
  say it is possible.
- **ret-6 — measure the real link**: the `LinkMeasurement` battery over
  TCP first, then over LoRa hardware. **This phase decides whether
  ret-5 streaming, and any interactive use, is real.** Publish the
  numbers whether or not they flatter the design.
- **ret-7 — store-and-forward for app data**: a link that is down for
  hours is the normal case, not an error. Reticulum's messaging layer
  (LXMF) is the natural primitive; the row model must carry queued,
  deferred and expired as first-class states with reasons.
- **ret-8 — THE §2 RULE, INHERITED VERBATIM**: *nothing arriving from
  another isle over Reticulum may mutate Polari state.* A remote isle
  is not authorized merely by being on the mesh. Inbound app data
  becomes a PROPOSAL through the ordinary `ai_actions` path — exactly
  the seam mtg-8 just built and proved — and applying stays a
  confirmed act in the same provenance log.
- **ret-9 — isle-to-isle**: two OpenWRT isles, each with Reticulum +
  LoRa, running a real Polari exchange end to end. The milestone
  Dustin named. Depends on isle-core for both boxes.

## 5b. Answers to Dustin's three questions (2026-08-12)

### Is protobuf actually much smaller than JSON, once HTTP/2 is gone?

Yes — expect **3–10× on the small structured messages this link is
for**, and the ratio COMPOUNDS on a duty-cycled link because bytes
become packets and packets become airtime and retransmits. Where it
comes from: field numbers as varint tags instead of quoted key names,
varints instead of decimal digits, no quotes/commas/braces, and no
base64 for binary (JSON pays +33% there). A tractor telemetry frame
(id, timestamp, 5 floats, a state enum) is roughly 120–180 bytes as
JSON and 30–45 as protobuf — the difference between one Reticulum
packet and three or four.

Three honest qualifications:
- **Compression narrows it, but not on small messages.** deflate/zstd
  need a dictionary; a 100-byte message gives them nothing to work
  with. Protobuf keeps its edge exactly where our traffic lives.
- **CBOR/msgpack is the middle option** — self-describing like JSON,
  binary like protobuf, typically ~half of JSON. The right choice when
  a schema is genuinely not shared.
- **Protobuf costs a shared schema.** We already have that (both ends
  are ours, and `grpcbridge` already carries the `.proto` files), so
  this is a cost we have already paid.
- ⚠ These are ESTIMATES. ret-4 reports measured bytes-on-wire per
  binding beside the choice, and ret-6 measures the airtime.

### Can we tolerate loss and make up lost packets?

Yes, but the mechanism must match the link, and there are three
distinct layers people usually conflate:

1. **Reticulum's own reliability** — Links carry sequencing and
   retries, and the Resource mechanism handles larger transfers with
   retransmission. Point-to-point loss is largely handled. *(Verify
   against the source in ret-0; this is recollection, not evidence.)*
2. **ARQ degrades badly here.** A retransmit costs a full RTT — seconds
   — plus the airtime of resending. At a few percent loss that is
   fine; at 20% on a marginal link, latency and airtime collapse.
3. **FEC is how you "make up" a lost packet with no round trip.**
   Erasure coding (Reed–Solomon, or a fountain code like RaptorQ) sends
   k data fragments plus m parity; ANY k of the k+m reconstruct the
   message. You pay the overhead always instead of paying an RTT
   sometimes. **The decision is measurable, not aesthetic:** when
   `loss_rate × retransmit_cost > FEC_overhead`, FEC wins. ret-6
   produces those numbers and the choice becomes a knob with evidence
   behind it, per binding.

**The design point that matters more than either:** for telemetry and
control, **send state snapshots, not deltas.** A lost snapshot is
superseded by the next one; a lost delta corrupts state permanently
and silently. Deltas are a trap on a lossy link.

⚠ **And for anything that moves** (the tractor): a link with seconds of
latency and real loss must never sit inside a closed control loop.
Command + ack + timeout, with the machine holding a LOCAL safe state
(deadman/failsafe on its own MCU) when the link goes quiet. The mesh
carries intent and telemetry; it does not carry a steering command in
real time. This belongs with the safety-MCU tier of the hardware
architecture, not with the transport.

### TWO formats over the mesh — gRPC and JSON (Dustin 2026-08-12)

**STOMP is OUT of scope for Reticulum transport.** It was the worst
natural fit — text framing, per-frame headers, and heartbeats that
would spend duty cycle saying nothing — and carrying it would have
meant a topic-id registry and a heartbeat override existing only for
this path. Dropping it removes a whole subsystem for no lost
capability.

⚠ This does NOT remove STOMP from Polari. It stays the LAN realtime
channel it already is (`@stomp/rx-stomp` in the frontend); it simply
does not cross the mesh. An app that wants STOMP semantics over
`.arch` sends a gRPC or JSON message instead, and the local STOMP
broker fans it out on the far side — which is the termination pattern
applied one layer higher, and needs no transport support.

So, two encodings, same termination trick — preserve app semantics,
compact the wire form:

- **gRPC** → terminate HTTP/2, carry protobuf bodies (§2). The
  default for anything structured or frequent.
- **JSON** → permitted, honestly labelled the expensive one, and the
  right answer when a human needs to read what crossed or the schema
  genuinely is not shared. (CBOR stays available as the middle option
  if ret-4's measurements say JSON is too costly for a binding that
  cannot use protobuf.)

Each `TransportBinding` therefore carries an admission POLICY —
max message size, max rate, priority, encoding — and the gateway
**refuses or queues by name** when a binding would exceed its airtime
budget. That is the "ensure and manage what is being sent" half, and
it is what stops LoRa from being quietly oversubscribed.

## 5c. `.arch` — the archipelago (ret-1a, Dustin 2026-08-12)

A Polari module tracking the Reticulum nodes we can actually reach and
mapping them into a **`.arch`** namespace (archipelago): named,
trusted addresses treated as an EXTENSION of our isle. Motivating
cases in Dustin's words: three isles across town sharing data over
LoRa, and a remote-controlled tractor (the Open Source Ecology
pattern).

Rows:
- `ArchipelagoNode` — `<name>.arch` ⇄ a `ReticulumDestination`, plus
  what it IS (peer isle | device | relay), who vouches for it, and
  **measured reachability** (last heard, hop count, link quality) kept
  separate from declared trust.
- `ArchipelagoTrust` — GRADED, never a boolean: what this peer may
  ASK for. Trust is a reason to accept a proposal for consideration,
  not permission to write. **ret-8 still applies to trusted peers** —
  an archipelago node is authorized to PROPOSE, and a higher trust
  grade may raise the auto-approval level for named low-authority
  operations (telemetry ingest, gossip), never for irreversible ones.
  "Extension of our isle" describes routing and naming, not authority.
- Reachability is a MEASUREMENT with a timestamp, so `.arch` can
  answer "who can I actually reach right now" honestly rather than
  listing hopeful names — the same declared-vs-measured split the
  resource profiles use.

`.arch` also gives §3's synthetic-IP mapping its human surface: a name
in `.arch` is what a person and an app both use, and the gateway
resolves it to a destination hash.

## 5d. LoRa is one bearer, not THE bearer (Dustin 2026-08-12)

Reticulum is bearer-agnostic on purpose, and the plan must be too:
LoRa, **LoRaWAN**, ordinary **WiFi**, **WiFi HaLow (802.11ah)**,
Ethernet/TCP backhaul, and serial all sit under the same stack. So
`ReticulumInterface` (§4) is the class that carries the differences,
and NOTHING above it may assume LoRa's constraints — an app binding
that only works at 1 kbps is fine, but one that BREAKS at 20 Mbit
would be a bug.

The differences that actually change decisions, per bearer:

| Bearer | Rough order | What changes |
|---|---|---|
| LoRa (RNode) | kbps | duty cycle, tiny MTU, seconds of RTT — the hard case, so design here |
| LoRaWAN | kbps, **via a network server** | ⚠ not peer-to-peer: it assumes gateways + a join server, so it is a different trust and addressing story, not just a slower radio |
| WiFi HaLow | hundreds of kbps–Mbps, km range | the interesting middle: real bandwidth AND real range; likely the best isle-to-isle backhaul where hardware allows |
| WiFi / Ethernet | Mbps+ | no airtime budget; the honest fast path, and what ret-0 proves on |

Consequences the design must carry:
- **Bearer selection is a routing decision with evidence.** When two
  bearers reach the same `.arch` node, pick by measured link quality
  and cost, and SAY which was chosen — a binding that silently fell
  back to the kilobit path is how "why is this slow" becomes a
  mystery. `LinkMeasurement` per interface is what makes that
  answerable.
- **Admission policy is per-bearer, not global.** The same
  `TransportBinding` may be fine over HaLow and refused over LoRa;
  the refusal names the bearer and the budget it would have blown.
- ⚠ **LoRaWAN is not a drop-in.** Its star-of-stars topology, gateway
  dependence and join-server model conflict with the peer-to-peer
  assumption everything else here makes. Treat it as its own
  investigation, gated on a real use case, not as "LoRa with more
  letters".
- **FEC and snapshot-vs-delta (§5b) are LoRa-shaped answers.** On a
  fat bearer they are wasted overhead — so they are knobs on the
  binding, chosen against the measured bearer, never global defaults.

## 5e. THE MESH IS HETEROGENEOUS — a path, not a network property
## (Dustin 2026-08-12)

The same Reticulum network will be fast in places and slow in others,
and **a multi-hop path is as slow as its worst hop.** So no capability,
budget or timeout may be a property of "the mesh"; every one of them is
a property of **the path to a specific `.arch` node right now**.

What that forces, concretely:

- **`LinkMeasurement` is per PATH, not per interface.** A fast local
  HaLow interface tells you nothing about a peer three hops away whose
  last hop is LoRa. The row that answers "can I do this" is keyed on
  (destination, bearer-path), with hop count and the worst hop named.
- **Every binding decision reads the measured path.** Encoding, FEC vs
  ARQ, snapshot vs delta, admission policy, timeout — all of them
  resolve at send time against THIS path's numbers, not against a
  global default. Same message to two peers may legitimately go out
  encoded differently, and the provenance says which and why.
- **Timeouts must be derived, never constant.** A 5-second timeout is
  generous on WiFi and absurd on a four-hop LoRa path; a constant one
  guarantees false failures at the far end of the mesh. Derive from
  measured RTT with a margin, and REFUSE (with the number) rather than
  silently waiting when a request's deadline cannot be met by the path
  it would take.
- **Capability is answered per peer.** `.arch` should be able to say
  "gRPC unary: yes; gRPC streaming: no, this path is 1.2 kbps at 4
  hops; JSON: only under 2 KB"
  — the same honest-refusal shape used everywhere else in the suite,
  with evidence, knob and action.
- **Degradation must be visible, not silent.** When a path gets worse
  and a binding drops to a cheaper encoding or starts queueing, that
  is a reported event with the measurement behind it. Silent
  degradation is how a mesh becomes untrustworthy.
- **Stale measurements are not measurements.** Every path fact carries
  a timestamp; past a freshness horizon the honest answer is "unknown,
  measure first", not the last good number.

⚠ This also bounds §5b's snapshot advice: on a fast path, deltas are
fine and cheaper. The rule is not "always snapshots" — it is "the path
decides, and the row records which it chose".

## 5f. STATE REPLICATION — parent state + child state (ret-7b)
## (Dustin 2026-08-12)

Choose objects to be WATCHED; keep their state; transmit it. The model
Dustin named — **the most recent parent state transmitted to us, and
the child state** — is the right one, and it is the same shape git
uses: keeping the last-known-common ancestor beside your own working
state is what makes divergence detectable instead of catastrophic.

**The two states (at least two — three in practice):**
- `parent_state` — the last state we RECEIVED from upstream, stored
  verbatim with its version and hash. Never edited locally; it is
  evidence of what the other side believes.
- `child_state` — our local state, which may have moved on.
- (derived) `pending_delta` — child minus parent. This is what we owe
  the link, and it is what makes send-only-the-diff possible.

**What holding both buys, and why one state would not:**
- **Diffs instead of snapshots** — send `parent → child` rather than
  the whole object, the single biggest airtime saving on a slow path.
- **Conflict DETECTION rather than silent clobbering.** If the arriving
  parent version is not the parent we hold, both sides moved. That is
  the case a one-state design silently destroys.
- **Rollback** — parent is a known-good point to return to.
- **An honest "am I in sync?"** answer, with a timestamp.

**Rows (in the same `reticulum` module, object-coherent):**
- `WatchedObject` — WHICH objects are replicated: by class, by name, or
  by query; plus direction (publish | subscribe | both), the bearer
  policy from §5d, and the cadence.
- `ObjectStateVersion` — parent/child versions with content hashes and
  a monotonic counter. Hash + version make a REPEAT a no-op, which is
  what makes a lossy link safe to retry on.
- `StateConflict` — a detected divergence, carrying both sides.

**Conflict policy is a knob per watched object, never a global
default**: `parent-wins`, `child-wins`, `newest-wins`, or —
the one that fits this suite — **`propose`**, where a conflict becomes
a PROPOSAL through the ret-8 seam and a human adjudicates. A remote
isle overwriting local rows because it spoke last is exactly what the
§2 rule exists to prevent.

**Keyframes are mandatory, not an optimisation.** A receiver whose
parent version is unknown or too far behind cannot use a delta, so the
publisher sends a periodic FULL snapshot (a keyframe) alongside
deltas. This is what makes a late joiner, a rebooted node, or a
receiver that missed a burst able to recover at all — and on a
one-way link it is the ONLY recovery mechanism.

⚠ **Receive-only paths are a first-class case.** Over broadcast HAM
there may be no return channel at all: no acks, no retransmit
requests, no negotiation. Design consequence — the publisher cannot
know what any receiver holds, so cadence and keyframe interval are
publisher-side decisions, FEC (§5b) replaces ARQ entirely, and every
message must be independently interpretable. A protocol that assumes
it can ask "what version do you have?" does not work here.

### ⚠ HAM BANDS — why the DEFAULTS are conservative

**Framing (Dustin 2026-08-12): this plan states no legal conclusions.**
Rules vary by jurisdiction and change; the operator is responsible for
compliance. What follows is why our DEFAULTS are cautious — a
conservative default is a design choice we can justify without
claiming to know the law, and every one of them is a knob the operator
can set for their own jurisdiction.

If any of this crosses amateur radio, the rules are not a formality
and they bite this specific design:

- **Encryption is prohibited on amateur bands** in the US (Part 97
  forbids messages encoded to obscure their meaning) and similarly in
  many jurisdictions. **Reticulum encrypts by default.** So a plain
  Reticulum link over ham spectrum is likely NOT LAWFUL as-is.
- **Signing is not encrypting.** Authentication and integrity
  (signatures, hashes) do not obscure meaning and are generally
  acceptable — so an authenticated-but-cleartext mode is the shape a
  lawful ham path would need.
- Station **identification** (callsign at intervals), **no commercial
  use**, and content restrictions also apply, and a control link for a
  machine may face additional rules.
- **ISM (e.g. 915 MHz LoRa) has no such content restriction** — which
  is why ISM, not ham, is the default assumption everywhere else in
  this plan.

**Consequence for the plan:** a `ReticulumInterface` must declare its
**regulatory domain** (`ism` | `amateur` | `licensed-other`), and the
gateway must REFUSE to route encrypted payloads over an interface
marked `amateur`, by name, with the rule cited. That refusal is a
feature: it is the difference between a mesh that is merely clever and
one that can be operated lawfully. ⚠ None of the above is legal
advice, and it is my recollection rather than a checked citation —
**ret-0 must verify the current rules for the actual jurisdiction and
bands before any ham transmission**, exactly as the licence gate
verifies software terms.

## 5g. The HAM broadcast core — Dustin's topology, and what it needs
## (2026-08-12)

Dustin's model, and it is a good one: a licensed operator broadcasts
app state UNENCRYPTED over amateur spectrum as a long-range one-to-many
"core"; the local encrypted mesh (ISM LoRa / HaLow / WiFi) picks it up
and redistributes it; changes trickle back toward the HAM core. Long
range where you need reach, encryption where you are allowed it.

**Where the belief is correct:**
- **RECEIVING is unrestricted.** No licence is needed to listen to
  amateur spectrum — it is public by design. So a **receive-only
  Polari node needs no licence at all**, which makes RX-only the safe
  default posture for any node we ship.
- **TRANSMITTING requires a licence**, and the licence is per-operator,
  not per-device.
- **Unencrypted amateur transmission is lawful** for a licensed
  operator, which is exactly what makes the broadcast core viable.

**Is there an unencrypted Reticulum mode? Yes — and it is the hinge.**
Reticulum destinations come in kinds, and one of them (`PLAIN`) is
explicitly unencrypted; the encrypted-by-default behaviour belongs to
single/group destinations and to Links, which negotiate ephemeral keys.
So the lawful ham shape is: **PLAIN destinations, packet broadcast, no
Links.** *(⚠ ret-0 must confirm this against the source — the mode's
existence is recollection, and the exact framing matters when the
consequence is legality.)* Signatures stay allowed: signing proves who
sent a thing without obscuring what it says, so integrity survives even
where confidentiality cannot.

**Consequences the module must own:**

1. **Licence handling: RECORD IT, TRACK EXPIRY, ASSUME NOTHING.**
   (Dustin 2026-08-12 — scope deliberately narrowed so the software
   makes no legal claims.)

   The module records **facts the operator gives us**, ties them to a
   Keycloak user, and surfaces them. It does not interpret regulations,
   does not assert what is or is not lawful in a jurisdiction, and does
   not enforce a legal conclusion.

   - `OperatorLicense` — **the operator's own ASSERTION that they hold
     a licence**, recorded: callsign, licence class, issuing authority,
     jurisdiction, issue/expiry dates, the KC subject it belongs to,
     and when the assertion was made. It is a self-declaration with an
     author and a timestamp — that is precisely what it claims to be,
     and the software never pretends it is more. Identity stays
     Keycloak's (the standing rule); this row ANNOTATES a user, it
     does not become a second account system.
   - **The assertion is the ONLY check.** Nothing is validated against
     an external service, ever — no lookup, no phone-home, no
     "verified" badge that depends on being online. A system meant to
     work when the infrastructure is gone cannot have its radio gated
     by a server it cannot reach.
   - **Expiry is tracked and surfaced** — approaching and past expiry
     are visible states with dates, since a lapsed licence is the
     failure mode a busy operator will actually hit.
   - **No licence on file, or an expired one, produces a clear
     WARNING naming what is missing** — not a legal verdict, and not
     a gate that would break the emergency case.
   - ⚠ **No network dependency, at all.** These apps exist partly for
     emergencies; nothing here may require internet reachability, and
     no online registry check gates anything. (An advisory lookup
     could return later as an explicit opt-in; it is out of scope now
     and would never be required.)
   - The operator is responsible for compliance in their own
     jurisdiction. The software's honest role is to hold the record,
     show it, and say when it has lapsed.
2. **Automatic station identification.** Callsign at the required
   interval, sent in clear, is something the gateway should emit on its
   own rather than leaving to an operator to remember.
3. **🔑 THE HAM SEGMENT IS A PUBLIC, PERMANENT BROADCAST.** Anyone with
   an SDR receives it, forever. This is a bigger design constraint than
   the encryption ban: **state crossing the ham core must be explicitly
   marked publishable.** So `WatchedObject` gains a
   `publication_class` (`public` | `mesh-only` | `local-only`)
   defaulting to the most restrictive, and the gateway REFUSES to put
   anything but `public` on an amateur interface, by name. Encryption
   being illegal there is precisely why we must not rely on it.
4. **The trickle-back path needs a licensed operator too.** Uplink into
   the ham core is a transmission: it faces the same licence, the same
   cleartext rule and the same publication test. A mesh node without a
   licensed operator can consume the core and redistribute locally, but
   it cannot answer upward.
5. ⚠ **Third-party traffic.** Relaying messages on behalf of unlicensed
   people is its own regulated category — broadly permitted
   domestically in the US, restricted internationally by agreement.
   Dustin's "average user's state reaches the HAM core" is exactly that
   case, so ret-0's legal check must cover it specifically, not just
   the encryption question.
6. **No commercial use**, plus content restrictions, apply to whatever
   crosses. A publication class is also where that judgement lives.

**This makes the bearer split a design principle, not a workaround:**
ham carries public state, far, in clear, one-way; the encrypted mesh
carries everything else, bidirectionally, locally. The gateway's job is
to enforce that boundary and to say plainly when it refuses.

⚠ Still recollection, not legal advice: ret-0 verifies the current
rules for the actual jurisdiction and bands (encryption, ID interval,
third-party traffic, control links) BEFORE any amateur transmission.

## 5h. Hardware routes — what the USB options actually resolve to
## (Dustin 2026-08-12: MIT licence confirmed; no RNode boards owned)

**Licence:** Reticulum is **MIT** — GPLv3-compatible, so the gate
should clear for the stack itself. ret-0's gate still checks LXMF, any
RNode firmware we would flash, and OpenWRT packaging separately: one
component being MIT says nothing about the others.

**Reticulum is bearer-agnostic through its interface types**, so the
question is only which interface each USB route lands on.

- **USB-WiFi → works today, no new concepts.** It is just an IP link:
  TCP/UDP interfaces, or link-local autodiscovery between isles on the
  same network. **This is the ret-0 path** — it needs nothing we do not
  already own, and it proves the stack, identities and encodings before
  any radio exists. WiFi HaLow USB adapters are rarer and pricier but
  are the same interface story with far better range.
- **USB-LoRa → is the RNode path, not an alternative to it.** ⚠ Worth
  knowing before shopping: "USB LoRa" dongles are almost always a dev
  board (ESP32/STM32 + SX127x/SX126x) exposed as USB serial, and the
  way Reticulum speaks to one is by **flashing RNode firmware onto it**
  (`rnodeconf`). So "we do not own an RNode-flashable board" and "we
  want USB LoRa" are the same requirement. **The good news: this is a
  ~$20–40 board** (LilyGO T-Beam / T3, Heltec LoRa32, RAK), not exotic
  hardware — the blocker is an order, not a project. Buy TWO; one radio
  proves nothing.
- **USB-SDR → the awkward one, and the only route I would not plan
  around.** Three separate problems: (1) the cheap ones (RTL-SDR) are
  **receive-only** — they physically cannot transmit; (2) TX-capable
  SDRs (HackRF/LimeSDR/Pluto) have **no native Reticulum interface** —
  you must put a modem between them, e.g. GNU Radio or a soundmodem
  (Direwolf) presenting **KISS**, which Reticulum does speak; (3) that
  modem layer is CPU-hungry and a poor fit for a router.
  ⚠ **But note the shape:** SDR/soundmodem + KISS is exactly the route
  a HAM packet link would take, so it belongs to the §5g broadcast-core
  investigation rather than to everyday transport — and an RTL-SDR
  makes a fine RECEIVE-only node, which §5g already says needs no
  licence.

⚠ **OpenWRT sizing is its own constraint** (an isle-core question, but
it decides feasibility): Reticulum is Python, and a typical consumer
router with 16 MB flash / 128 MB RAM will not hold Python plus crypto
dependencies comfortably. A capable device — x86 OpenWRT, or a router
with real storage and RAM — is fine. **Confirm the target device's
flash/RAM before assuming "add-on to OpenWRT" is a small ask**; on a
constrained box the honest alternative is running `rnsd` on an
attached SBC and giving the router only the gateway rules.

**Consequence for phase order:** ret-0 through ret-5 need NO radio —
USB-WiFi or plain TCP carries all of it. Only ret-6 (measurement) and
ret-9 (isle-to-isle over LoRa) need the boards. So the hardware order
is not blocking the start; it is blocking the proof.

### KVM/VMs instead of a second box (Dustin 2026-08-12)

Running the second (and third) isle as **VMs on hardware we already
own**, with cheap USB devices passed through, is the right cost move
and it changes what we must buy: one machine can host several OpenWRT
guests, so "three isles across town" is developed as three VMs and
only *deployed* to separate hardware once it works.

What this buys and what it does NOT:
- ✅ **Everything through ret-5 is fully testable on VMs.** Multiple
  `rnsd` instances, the object model, the gateway, `.arch` naming,
  encodings, state replication, the propose-gate — none of it needs a
  radio, and virtual networking exercises multi-hop honestly.
- ✅ **USB passthrough is well-trodden** for exactly this: a LoRa board
  or WiFi adapter is a USB-serial/USB device handed to one guest. It
  lets ONE physical radio serve whichever VM is being tested.
- ⚠ **A VM cannot fake the physics.** Airtime, duty cycle, real loss,
  RF range and multi-second RTT are precisely what ret-6 exists to
  measure, and a virtual link will report flattering numbers. Any
  measurement taken on VMs must be **labelled as such** — the
  declared-vs-measured split the resource profiles already use. Do not
  let a VM number become the basis for an encoding or FEC decision.
- ⚠ **Passthrough is exclusive.** One USB radio serves one guest at a
  time, so a two-VM radio test needs two boards (or a serial-over-IP
  bridge). This is the same "buy two" conclusion from a different
  direction.
- 🔑 **KVM + USB has bitten this project before**: the scan arc lost
  time to a webcam that enumerated but failed UVC probe control behind
  a KVM switch, and only worked direct-plugged. Different meaning of
  "KVM", same lesson — **when a USB device misbehaves, test it
  direct-plugged before debugging the software.**

**So the honest hardware plan:** develop ret-0..ret-5 on VMs with no
radio at all; buy two cheap LoRa boards when ret-6 approaches; deploy
to real separate hardware only for ret-9, where the point IS the
distance.

## 5i. RECEIVE-FIRST, and devices as a first-class surface
## (Dustin 2026-08-12)

### The majority case is a RECEIVER — so build that first

"In the vast majority of cases people will just want receivers for
HAM." That reorders the work, and it is the cheapest correct thing we
could do:

- **RX-only needs no licence** (§5g), so it ships to everyone with no
  legal exposure, no attestation, no warnings at the moment of use.
- **RX-only hardware is the cheap hardware** — an RTL-SDR is the one
  USB-SDR case that works well (§5h), precisely because receiving is
  all it can do.
- **It is the safe default posture for anything we ship**: a node
  listens unless someone deliberately, knowingly enables transmit.
- It makes §5g's topology useful on day one: one licensed operator
  broadcasts public state; **everyone else just receives it** and
  redistributes over the encrypted local mesh.

So `ReticulumInterface` carries `direction` (`rx` | `tx` | `both`) as a
DEVICE FACT, not a preference — an RTL-SDR is `rx` because it cannot
be anything else — and every surface reads it. A device that cannot
transmit never offers a transmit control; that is honest UI, not a
missing feature.

**Bearer priority, in Dustin's order:** HAM receive → **LoRa** →
LoRaWAN → WiFi → WiFi HaLow. (WiFi stays FIRST for development
convenience per §5h/ret-0, but it is not the point of the arc.)

### A device-connection capability + frontend (ret-2b)

Connecting hardware should be a page, not a config file. `DeviceLink`
rows describe an attached device — bus/USB id, what we think it IS
(LoRa board, WiFi adapter, HaLow adapter, SDR, serial/KISS), which
`ReticulumInterface` it backs, which VM (if any) currently owns it,
and its measured direction/bearer facts kept separate from declared
ones.

The page shows: what is plugged in, what each device can honestly do
(receive only / transmit capable / needs firmware flashed / unknown),
which isle or VM has it, and the honest refusal when something is
claimed but absent. **Detection must degrade honestly** — an unknown
USB id is reported as unknown with its ids shown, never guessed into a
capability.

### ⚠ REUSE the virtualization machinery — do not rebuild it

KVM/QEMU + OpenWRT guests, with USB passthrough, is a solved problem
with mature tooling (libvirt/QEMU, OpenWRT's own images and build
system). **We orchestrate it; we do not reimplement it.** Concretely:

- Drive guests through libvirt/QEMU rather than writing a VM manager;
  the Polari side is ROWS describing which guest exists, what it runs
  and which device it owns, plus the `pol` verbs to apply them.
- Use OpenWRT's published images and package feeds; the OpenWRT-side
  work stays isle-core's (§0).
- **Check `HARDWARE_SIMULATION` first** — this suite already has a
  hardware-simulation arc (hwsim-1 live: Renode/Verilator/ngspice,
  hwsim-2..5 parked). If it already models "a device attached to a
  simulated machine", ret-2b EXTENDS it rather than starting a second
  device abstraction beside it. Two device models in one repo is the
  kind of duplication that quietly doubles maintenance.
- Same rule for placement: the resource ledger and topology rows
  already decide where things run — a VM is another placement target,
  not a new placement system.

## 5j. The real target: USB devices on isle-mesh UBUNTU, not OpenWRT
## (Dustin 2026-08-12 — this simplifies a lot)

The general deployment target is **USB devices attached to Ubuntu
machines that already have isle-mesh installed** — not Reticulum
squeezed onto a consumer router. That resolves the §5h sizing worry
and removes a whole class of problem:

- **No flash/RAM constraint.** Python plus crypto dependencies are
  nothing on Ubuntu; the "16 MB router won't hold it" caution and the
  attached-SBC fallback both stop mattering for the common case.
- **The install path already exists.** isle-mesh onboarding is BUILT
  and proven — `isle core-install`, apt-on-mesh at `apt.isle`
  (see `ISLE_ONBOARDING_HANDOFF.md`). **Reticulum should be another
  package on that path**, not a new installer: an isle package that
  pulls `rns`, drops config, and registers the service. Reusing the
  installer we already have beats writing a second one.
- **udev, not guesswork.** On Ubuntu a USB device announces itself;
  ret-2b's `DeviceLink` rows can be populated from real udev events
  with stable by-id paths, instead of scanning and inferring. A LoRa
  board replugged into another port keeps its identity.
- **Permissions are the predictable snag:** serial devices need group
  membership (`dialout`) or a udev rule. Name it in the install step
  so it is a documented step rather than a mysterious "permission
  denied" at first transmit.
- **OpenWRT becomes a case, not the platform.** It stays supported for
  routers that genuinely are the isle edge (and stays isle-core's
  work, §0), but the plan's DEFAULT target is Ubuntu + USB. Anywhere
  the two disagree, Ubuntu is the one we build and test first.
- **KVM/QEMU (§5i) still applies** — Ubuntu hosts are where the guests
  and passthrough live, and multiple isles on one machine is still how
  ret-0..ret-5 get developed without buying anything.

### Does Reticulum actually NEED OpenWRT? No. (clarified 2026-08-12)

Worth stating plainly, because the earlier draft implied a dependency
that does not exist: **Reticulum has no OpenWRT component.** It is a
Python stack that runs on any Linux — Ubuntu included — and the
association with OpenWRT is cultural (routers are where off-grid mesh
people put things), not technical. Running it on plain Ubuntu with no
OpenWRT anywhere is a completely normal deployment.

**The only thing OpenWRT would give us** is the ROUTER role: if the
box that sees a site's traffic is a router, that is the natural place
for §3's gateway pieces (the resolver handing out synthetic IPs, and
the nftables rules steering them). But Linux has all of that too —
Ubuntu can run its own resolver and nftables perfectly well — so on an
Ubuntu isle the gateway simply lives on the Ubuntu box.

So the honest position:
- **Default: Ubuntu + USB, no OpenWRT.** Simplest, fewest moving
  parts, and it is where the isle-mesh install path already works.
- **OpenWRT KVM guests are for the ROUTER CASE** — developing and
  testing against a real router edge, or a deployment whose isle edge
  genuinely is an OpenWRT device. Useful, not required.
- Nothing is lost by skipping OpenWRT if the site's edge is an Ubuntu
  machine.

**What the earlier "must not assume OpenWRT" line was trying to say,
concretely:** do not write code that only runs on a router — no `uci`
calls, no `/etc/config/network` edits, no `opkg` assumptions in the
Polari half. Where platform-specific work IS needed, it belongs behind
a platform field on the interface/device row and stays isle-core's
(§0). That is the whole of it; the rest of the module is ordinary
Linux.

## 5k. THE DECISION: separate Reticulum container, thin OpenWRT hook
## (Dustin 2026-08-12 — everything on isle-mesh is a container or KVM,
## and an OpenWRT is always present)

Two candidates: (A) a Reticulum-specific Ubuntu container/KVM doing
the gRPC/JSON conversion and relay, talking to OpenWRT; or (B)
Reticulum as an OpenWRT add-on.

**Recommendation: (A), with a deliberately thin piece on OpenWRT.**
Five reasons, in the order they matter:

1. **The conversion work is APPLICATION logic, not router logic.**
   gRPC/protobuf, JSON/CBOR, the state replication engine, the
   propose-gate — these want our Python dependencies, our test suite
   and our release cadence. Coupling them to a router firmware's
   package set and upgrade cycle would make every encoding change a
   firmware event. That is the wrong seam.
2. **It matches the boundary already drawn (§0).** OpenWRT does
   routing, firewall and DNS — isle-core's domain. The container does
   Reticulum and conversion — ours. The split we already agreed for
   PEOPLE reasons happens to be the right split for TECHNICAL ones,
   which is usually a sign it is the real seam.
3. **It is the pattern this suite already walks.** `pol-livekit`,
   `prf-recon-engines`, `prf-msci-engines`, `prf-cad-engines`: an
   optional service with its own compose file, its own resource
   profile, its own topology row, never in the default `up`.
   `pol-reticulum` is the fifth walk, so it inherits placement,
   refusals and lifecycle for free instead of inventing them.
4. **Dependencies and size stop being a fight.** Python plus crypto
   plus protobuf on Ubuntu is unremarkable; the same on OpenWRT is a
   flash-space negotiation (§5h).
5. **USB attaches where the radio is used.** Pass the device straight
   to the container/VM that runs `rnsd` — not through OpenWRT, which
   would add a hop and a passthrough dependency for no benefit.

**What stays on OpenWRT — and it should stay SMALL:**
- DNS answers for the `.arch` names (§5c).
- The route/nftables rule steering the synthetic-IP range (§3) to the
  container.
That is it. Both are declarative, both are the router's actual job,
and both are isle-core's to apply from a written request.

**Container or KVM?** Default to a **container**: Reticulum is
userspace Python, USB passes in as a device, and it fits the compose
pattern above. Reach for a **KVM** only when something genuinely needs
its own kernel or network stack — a TUN/TAP arrangement that fights
the host, a driver the host kernel lacks, or an isle-mesh standard
that mandates VMs. Decide per deployment; the row records which, so
`pol` and the ledger treat them the same way.

⚠ **One thing to verify early (ret-2):** whether the OpenWRT instance
is itself a guest on the same host. If so, USB passthrough targets the
Reticulum container/VM directly and OpenWRT never touches the radio —
which is the simpler topology and worth confirming before wiring
anything.

## 5l. Passthrough is a SHELL CAPABILITY (ret-2c)
## (Dustin 2026-08-12)

A web page cannot attach a USB device to a container — that needs host
privilege. The JavaFX shell already runs on the host and already has
the machinery for exactly this: **scan-3 built a capability-gated
native bridge** (`:capture-desktop`, ServiceLoader-discovered, with
`shell.camera.*` refused unless the active registration DECLARES the
capability). Device passthrough is that pattern's second walk, not new
machinery:

- A `:device-passthrough` Gradle capability module in
  `polari-app-shell`, discovered the same way, exposing
  `shell.device.*`.
- Declared in `AppShellDefinition.capabilities_json` → the
  registration document → `polari-shell.schema.json` → the bridge
  gate. **Undeclared means refused**, and a shell built without the
  module reports "not built into this shell" honestly rather than
  failing obscurely.

### The correspondence rule Dustin asks for

**A device may only be attached to a container that the ROWS say may
claim it.** The shell never takes a free-form "attach X to Y":

- `DeviceLink` (§5i) names the device and the `ReticulumInterface` it
  backs; the interface's instance/service row names the container.
  The shell asks to satisfy THAT binding, by name.
- The helper validates the target is a registered Reticulum service
  container before acting, and **refuses by name** for anything else —
  so the capability cannot become a general-purpose "attach any device
  to any container" tool, which is what would make it dangerous.
- Every attach/detach is recorded with who asked and which binding it
  satisfied, in the provenance log the rest of the suite already uses.

### ⚠ The security detail: do NOT hand the shell the docker socket

The naive implementation gives the desktop app docker (or libvirt)
access. **Docker socket access is root-equivalent** — anything holding
it can start a privileged container and own the machine. Granting that
to a GUI app to plug in a radio is a bad trade.

Instead: the shell REQUESTS, and a **small privileged helper performs
only the narrow operation** — attach/detach this device id to that
allowlisted container — via a systemd unit or a polkit action scoped
to that one verb. The helper holds the privilege and the allowlist;
the shell holds neither. This keeps the blast radius the size of the
feature instead of the size of the machine.

⚠ Also inherited from scan-3: **the shell holds no Keycloak token**
(Strategy A). If an attach needs to be authorized against a user
rather than a local operator, that is the same wall scan-3 hit, and
the answer is the same — either a presigned/narrow grant, or Strategy
B tokens, decided when it actually blocks something.

## 6. Open questions for Dustin

- **Hardware:** do we own any LoRa radios (RNode-flashable boards) yet,
  and which band? ret-6 and ret-9 are blocked on hardware, not code —
  and after the scan arc, naming a hardware blocker early is the
  lesson, not a formality.
- **Second site:** is the second isle a real other location, or a
  second box on this desk for bring-up? Both are useful; they prove
  different things.
- **First real payload:** what should actually cross the link first —
  a scorecard sync, module/topology gossip, meeting presence, file
  transfer? The answer decides whether ret-4 optimises for small
  frequent messages or rare large ones.
- **Identity binding:** should an RNS identity map 1:1 to a KC user, or
  to an INSTANCE (with users authorized behind it)? Instance-level is
  simpler and matches how isles already federate; user-level is what
  end-to-end accountability would want.
- **Scope of "arbitrary internet protocols":** the honest near-term
  target is *our own* app traffic plus a named handful (HTTP GET, gRPC
  unary). Truly arbitrary IP over a kilobit link is a promise the
  physics cannot keep, and I would rather say so now than build a
  demo that says otherwise.
