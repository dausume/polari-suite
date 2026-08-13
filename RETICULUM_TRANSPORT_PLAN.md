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
