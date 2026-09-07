# Reticulum as a Polari transport — plan (ret-0..ret-9)

**Date:** 2026-08-12 · **Status: ✅ FINAL — design settled with Dustin,
nothing built.** Revised through eight rounds of his corrections the
same day; the sections below are decisions, not options.

## ✅ DECIDED (do not relitigate — each was settled deliberately)

| # | Decision | Where |
|---|---|---|
| 1 | isle-core owns OpenWRT/radio/regulatory; we own the model, gateway, encodings, gate | §0 |
| 2 | ~~Reticulum is MIT~~ **FALSIFIED BY THE GATE 2026-08-13**: relicensed 2025-04-15 to a restricted "Reticulum License" (GPLv3-INCOMPATIBLE); we pin the last-MIT pair `rns==0.9.4` + `lxmf==0.6.3` — see `RETICULUM_LICENCE_GATE.md` | §1, §5h |
| 3 | gRPC-over-HTTP/2 must NOT run verbatim — terminate at each end, carry protobuf bodies | §2 |
| 4 | **Two encodings only: gRPC and JSON.** STOMP is out of mesh transport (stays LAN) | §5b |
| 5 | protobuf ≈3–10× smaller than JSON here; ret-4 MEASURES rather than assumes | §5b |
| 6 | Loss: RNS retries + **FEC** where RTT is dear; **snapshots, not deltas**; nothing that moves sits in a closed loop | §5b |
| 7 | Reticulum does not route IP → name registry + netledger synthetic-IP pool + gateway that refuses unmapped by name | §3 |
| 8 | **`.arch` archipelago**: named nodes, GRADED trust, measured reachability; trust ≠ authority | §5c |
| 9 | LoRa is one bearer; LoRaWAN is NOT peer-to-peer and is its own investigation | §5d |
| 10 | **Latency is a property of the PATH, not the mesh** — everything resolves per path at send time | §5e |
| 11 | State = **parent + child** (+ derived delta); keyframes mandatory; conflicts become PROPOSALS | §5f |
| 12 | HAM: plan states **no legal conclusions**; operator's ASSERTION is the only check; never gated on internet | §5g, §5f |
| 13 | HAM segment is a PUBLIC permanent broadcast → `publication_class`, default most restrictive | §5g |
| 14 | **RECEIVE-FIRST** — RX needs no licence, is the majority case, and is the default posture | §5i |
| 15 | Target is **USB on isle-mesh Ubuntu**; Reticulum needs no OpenWRT (router role only) | §5j |
| 16 | **`pol-reticulum` is its own container**, thin declarative hook on OpenWRT | §5k |
| 17 | USB passthrough is a **gated shell capability**; helper holds the privilege, never the docker socket | §5l |
| 18 | Develop ret-0..ret-5 on KVM guests with no radio; two boards at ret-6; real distance only at ret-9 | §5h |
| 19 | **IDLE RADIOS ARE SILENT** (Dustin 2026-08-13): nothing transmits — announces included — without an active declared use; RF interfaces default `idle_policy='silent'` (not even attached when unused), `rx-hold` listens without announcing, `hold-open` is the operator's deliberate exception | ret-6 |
| 20 | **THE APP ACCESS LADDER** (Dustin 2026-08-13, naming settled same day): **`.isle` → `.arch` → `.mesh` → web** — the reserved isle-mesh suffixes plus the internet's endpoints; per-app exposure is ROWS (one per level, several at once), each carrying OUR ROLE for that app (observer/user/relay-only/server, default observer); `.mesh` consumers are tracked SOLELY by Reticulum identity, KC linkage opt-in and NEVER required | §5n |
| 21 | **`.mesh` is the wider-mesh namespace** (Dustin 2026-08-13): heard peers are ADJUDICATED — `.arch` when we recognize our own device, `.mesh` for strangers we still want to see; unadjudicated peers are neither. Lighthouse broadcast runs over ALL bearers, not just HAM — the publication×regulatory gate stays PER-INTERFACE | §5o |

## What starts ret-0 — ✅ BOTH DELIVERED 2026-08-13 (overnight)

1. ✅ **`RETICULUM_LICENCE_GATE.md`** — WRITTEN, three-source verified.
   ⚠ It found the "MIT" premise STALE: rns/lxmf relicensed 2025-04-15
   to a restricted, GPLv3-incompatible licence. **Conditional pass on
   the pinned MIT pair `rns==0.9.4` + `lxmf==0.6.3`** (assumption for
   Dustin to confirm; options weighed in the gate doc). RNode firmware
   is GPLv3 — fine.
2. ✅ **The §6 answers** — taken as marked ASSUMPTIONS (§6), per
   Dustin's overnight authorization. First payload assumed
   **module/topology gossip** → ret-4 tunes small-frequent.

ret-0 is radio-free (two `rnsd` over TCP or USB-WiFi); hardware blocks
the PROOF (ret-6/ret-9), not the work.

---
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

✅ **GATE RUN 2026-08-13** (`RETICULUM_LICENCE_GATE.md`): conditional
pass on `rns==0.9.4` + `lxmf==0.6.3` (the last MIT releases); current
releases carry a restricted, GPLv3-incompatible licence. **Pins are
licence pins — never `>=`.**

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

  ✅ **PROVEN 2026-08-13** (rig: scratchpad `ret0-rig/`, two containers
  on the default bridge — deliberately NO new docker network, per the
  `hostname -I` gotcha). `rns==0.9.4` + `lxmf==0.6.3` (the licence
  pins). Results, all first-try, 0 errors:
  - Path resolved in 0.2 s (1 hop); Link established; **25/25 gossip
    envelopes answered with responder-authored payload** (both ways,
    not an echo).
  - **Our envelope** (`PR` + version + kind): binary 56 B vs JSON
    163 B for the same gossip message → **JSON 2.91× larger** — the
    small-message end of §5b's 3–10× estimate, now measured.
  - **Resource mechanism confirmed** (plan §5b item 1 recollection →
    evidence): 50 KB blob transferred, sha256 verified identical both
    sides, 0.02 s.
  - **PLAIN destination confirmed** (§5g hinge recollection →
    evidence): unencrypted broadcast packet sent and received —
    `RNS.Destination.PLAIN` exists and works in 0.9.4.
  - RTT median 0.84 ms binary / 1.96 ms JSON — ⚠ VM/TCP numbers,
    labelled as such; they say nothing about LoRa (ret-6 measures).
  - Unknown envelope magic/version is REFUSED by name in decode —
    the honest-refusal shape reaches the wire format too.
- **ret-1 — the object model** (§4), manifest-first, with selftests.

  ✅ **BUILT + PROVEN 2026-08-13** (branch `dev-ret-1` off `dev-mtg-1`,
  framework): `modules/reticulum/` — 13 classes across four basis
  files by concern (core §4 + `.arch` §5c + replication §5f +
  operator/device §5g/§5i), pure rules beside them (admission with
  three-key refusals, may_route lawfulness gate, derived timeouts,
  per-path capability, replication algebra, licence-expiry ladder),
  `rns_remote` (fifth walk of the *_remote ladder, licence pins
  surfaced as facts), API (capability / .arch honesty / the ret-8
  inbound→proposal seam at level 4, identity-before-existence).
  ALL FIVE registrations + `rns_inbound` in both _OP_LEVEL tables.
  Proof: **selftest 61/61**; drift guards untouched (lazy-imports
  23/23, collab 77/77, islemesh 74/74); **dyn lifecycle 11/11
  in-container** (admit 2.9 s, put-away keeps tables, 410, re-admit,
  seed survives). The module itself NEVER imports RNS — the licence
  boundary is the process boundary, and the selftest pins that.
- **ret-2 — `pol-reticulum` service**: its own compose file + `pol
  compose reticulum` role + `services.yml` entry + resource profile +
  topology seed. The walked-four-times worker pattern (msci → cad →
  recon → livekit); never part of the default `up`.

  ✅ **BUILT + LIVE-PROVEN 2026-08-13**: sidecar image (python-slim +
  the licence pins, `reticulum/sidecar.py` — the ONLY process that
  imports RNS), `docker-compose.reticulum.yml` (identity in a NAMED
  volume: no root-owned host artifacts, and it SURVIVED a container
  recreate — same hash `765aa9a9…` before and after), `pol compose
  reticulum up|down|build|ps|logs`, honest `/status` on :4285
  (version, pins, per-interface online/bitrate), `services.yml`
  entry, topology instance + `reticulum.mesh@reticulum` assignment +
  dependency edge + resource profile + `PROVIDER_PORTS`. Backend
  ladder proven live from a container: `rns_remote.reachable()` True,
  status parsed. **Transport proof: two peers, each dialing ONLY the
  sidecar, reached each other THROUGH it (path in 1.2 s, 2 hops,
  25/25 replies, 50 KB resource sha-verified)** — the sidecar is a
  real Reticulum transport node, not just a stack holder. Topology
  selftest re-pinned 52/52; resources 31/31, admission 23/23.
  pol-reticulum LEFT RUNNING on staging-a.
- **ret-3 — the gateway**: synthetic-IP range from the netledger, the
  name registry, and the mapper. Ships with the honest refusal ladder
  (knob → topology → suggestion) and refuses unmapped addresses by
  name. The router-side DNS/nftables half goes to isle-core as a
  written request.

  ✅ **POLARI HALF BUILT + PROVEN 2026-08-13**: netledger gains its
  FOURTH kind — synthetic-IP pools (`synthetic_pool_conflicts` incl.
  the dangerous synthetic-vs-real case, `free_synthetic_pool` default
  space 10.77.x.0/24, assess branch, coherence surface; islemesh
  selftest 79/79). Name registry live:
  `GET /api/reticulum/resolve/{name}` answers destinations and .arch
  names, **refuses unmapped by name** (proven in the dyn proof, now
  14/14: 404+knob for `nope.arch`, 200 after a CRUDE create).
  `RETICULUM_ISLE_CORE_REQUEST.md` written (DNS `*.rns.isle`,
  steering, pool reservation as data; explicitly requests, never
  edits; warns isle-core off "helpfully" bumping the licence pins).
  **REMAINING for ret-3**: the packet-plane mapper in the sidecar
  (synthetic-IP packets → destination rows) — wants the router half
  applied first so there is real steering to receive.
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

  ⚙ **HARDWARE BRING-UP 2026-08-13** (desk, pol-core): the owned pair
  = DSD TECH SH-L1A (rebadged EByte E220-900T22, LLCC68) — full
  identity, restrictions, evidence and setup steps in the seeded
  `DeviceModel` row `dsd-tech-sh-l1a`. First measurements at factory
  settings: RNS link over the air (path 2.0 s, 56 B gossip RTT
  median 2.25 s), single frames to 500 B intact, but back-to-back
  packets overflow the modem's 400 B unflow-controlled buffer (JSON
  0/2, Resource failed) — the buffer, not the frame size, is the
  constraint. ⚠ **Both units SHIPPED on CH23 = 873.125 MHz, OUTSIDE
  US ISM** — caught by the licence-gate habit applied to registers;
  Dustin's rule "never transmit without confirming legality first"
  is now the `tx_permitted()` gate + a standing memory.
  **OPERATOR CONFIRMATION RECORDED: Dustin approved TX 2026-08-13**
  on the basis: 915.125 MHz (CH65) @ 22 dBm, LoRa/LLCC68, US 902–928
  ISM under FCC 15.247; module carries no end-product FCC cert
  (deployer's burden, accepted). Both units reconfigured PERSISTENT
  and verified by register readback: CH65 + 62.5k air + 115200 UART
  (raw `00 00 E7 00 41 03 00 00`).

  ✅ **ret-6 DESK BATTERY, LEGAL CONFIG — 2026-08-13, fidelity
  measured-real** (RNS 0.9.4 SerialInterface over the pair, desk
  range, 15/15 replies, 0 errors):
  | metric | 2.4k air (factory) | 62.5k air + 115200 UART |
  |---|---|---|
  | path discovery | 2.0 s | **0.4 s** |
  | 56 B gossip RTT (n=10) | 2 249 ms median | **222.8 ms median** |
  | 163 B JSON RTT (n=5) | LOST 2/2 | **303.5 ms median** |
  | 5 KB Resource | failed (buffer overflow) | **6.09 s = 821 B/s, sha-verified** |
  | loss | 3/7 pkts + resource | **0** |
  - The JSON-vs-binary RTT delta (+80.6 ms for +107 B) is ret-4's
    evidence in miniature: ~0.75 ms/byte on this path — encoding
    choice is measurably airtime, not taste.
  - PLAIN broadcast again confirmed under the legal config.
  - ⚠ Desk range ≠ distance: RSSI margin, real loss and multi-hop
    behaviour still need ret-9's separation. These numbers say the
    STACK and the config are sound, not that the field link is.
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

**WiFi dongles carry an ASSIGNMENT knob (Dustin 2026-08-14, refined
same day):** a device is `reticulum`-only, `onboarding-ap`-only, or
dual — never implicitly both, defaulting `unassigned` (nothing
claims a device silently). The dual case has THREE physical flavors
the model distinguishes: `dual-one-network` (the AP hosts the SSID
and RNS rides it as ordinary IP — no switching, the preferred dual),
`dual-ap-sta` (simultaneous AP+client, a MEASURED chipset fact via
`iw` interface combinations, refused until measured), and
`dual-switched` (time-shared; a switch interrupts the other use, so
it is a deliberate act with provenance, never automatic).
`DeviceLink.wifi_assignment` + `ap_capable`/`ap_sta_capable`
(unmeasured-empty until the isle agent's `iw` ingest — request items
5-6); `wifi_use_allowed()` rules it, selftest-pinned. `iw`/AP
tooling installs WITH isle-mesh on all devices (isle-core's half).
Infrastructure-WiFi bearer proven pol-core↔econ-core 2026-08-13.

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

**Licence:** ⚠ superseded by the gate (2026-08-13) — Reticulum was MIT
only up to `rns 0.9.4`; later releases are under a restricted,
GPLv3-incompatible licence. We pin `rns==0.9.4` + `lxmf==0.6.3`
(`RETICULUM_LICENCE_GATE.md`). RNode firmware is GPLv3-or-later: fine
at any version (stale MIT v1.x tags notwithstanding).

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

## 5m. THE `.arch` TOPOLOGY VIEW (ret-1b, Dustin 2026-08-13)

Isles become BLOCKS the way devices are blocks in the isle topology —
one level up. Inside each isle block: its RADIOS (LoRa / WiFi / HAM,
each showing bearer, rx/tx direction and catalog model) and its APPS.
Between blocks: MEASURED path latency (per bearer, freshness-honest).
Per app: what it is ASKING for — its TransportBindings' demand per
unit time (bytes × rate), declared vs measured kept separate. Per
device: bandwidth per unit time (declared air rate AND measured
effective) plus the airtime budget. Per isle: demand vs capacity with
an honest verdict — oversubscription is a named finding with
evidence, never a silent slowdown.

Sources (all existing rows): ArchipelagoNode + LinkMeasurement
(blocks + edges), ReticulumInterface + DeviceLink + DeviceModel
(radios), TransportBinding (+ new app_name field — an app's asks),
AirtimeBudget, islemesh IsleDevice/apps (what runs where).
Backend: `assemble_arch_topology()` pure + GET
/api/reticulum/arch-topology. Frontend: `/arch` page, nested blocks +
latency matrix (drawn edges can come later; a matrix is honest and
readable first).

✅ **BUILT 2026-08-13** (backend selftest 88/88, dyn proof 15/15
live, apps 45/45; angular `dev-ret-1` build green under both
guardrails, 8 headless view-rule specs): blocks with device chips
(HAM label wins over bearer when regulatory domain is amateur — an
operator cares about the band), per-app declared asks, demand bar
clamped at 100% with the overflow stated in the verdict's evidence,
NO bar when capacity unknown, stale matrix rows dimmed with age,
module-absent refusal card. Mesh Archipelago = the tenth discipline
app (`/arch`, requires reticulum). REMAINING: deploy (backend image
rebuild + frontend) and a browser pass = the arc's next deploy
window; metered (vs declared) app demand = named follow-up; drawn
edges when the matrix earns them.

## 5n. THE APP ACCESS LADDER — .isle → .arch → .mesh → web
## (ret-1c, Dustin 2026-08-13; naming settled same day: the reserved
## isle-mesh suffixes; 'open-sea' survives only as prose metaphor,
## the relay keeps its LIGHTHOUSE name. Roles added: an exposure row
## also says what WE are for that app at that level — observer /
## user / relay-only / server — default observer, and an app may
## hold exposure rows at several levels at once.)

Apps gain an ARCHIPELAGO-level accessibility knob, and beyond it a
zero-trust tier. Three rungs, each a deliberate enablement, default
always the most restrictive (DECIDED row 20):

1. **isle** — the app is reachable only on its own isle (today's
   default, unchanged).
2. **arch** — the app is archipelago-accessible: apps inside the
   `.arch` effectively talk as their own network. Dustin's motivating
   picture: *a farmer's market — vendors mesh their isles so
   customers move between stalls as one network.* Exposure is a ROW
   (`AppArchExposure`), not a config file: app ⇄ scope ⇄ which
   archipelago, enable/disable at will.
3. **mesh (`.mesh`)** — untrusted / ZERO-TRUST state relays for mesh-app-
   centric communication: arbitrary people connect, and the core
   mesh-app server broadcasts the app's CURRENT (and optionally
   prior) state. Consumers are not peers and are not trusted — they
   receive state and send returns; nothing they send mutates
   anything except through the ret-8 proposal seam like everyone
   else.

**The relay tier's machinery (rows + algorithms):**
- `MeshAppRelay` — the broadcast core for one app: which
  WatchedObject's state it fans out (reusing §5f verbatim — parent/
  child versions, keyframes mandatory), current cadence between
  bounds, how many prior states ride along, expected user count.
- `MeshConsumer` — a consumer tracked **solely by Reticulum identity
  hash** (pseudonymous first-class). `kc_link_mode` on the relay:
  `disabled` (default) | `optional` — a consumer MAY link a signed
  or anonymous identity on the mesh-app's local Keycloak and let it
  know their RNS id, but **`required` deliberately does not exist**:
  a zero-trust tier that demands enrolment is not zero-trust.
- **Adaptive cadence** (`adaptive_cadence()`): the publisher adjusts
  send rate to what the CONSUMERS COLLECTIVELY demonstrate — pace to
  the median consumer's return interval with headroom, clamped by a
  floor (airtime budget, DECIDED row 19 still applies) and a
  ceiling (staleness). Evidence-bearing: every adjustment names the
  numbers that drove it.
- **User census** (`user_census()`): accountability of how many
  users SHOULD exist vs how many distinct RNS identities were
  actually seen in the window — over/under/as-expected is a named
  finding, because a relay that silently gains a thousand consumers
  is a different thing than the one you configured.

**Inter-archipelago relay of state:** each archipelago holds the
FULL state (keyframes land at arch level, so any local consumer gets
wholeness from its own arch), while BETWEEN archipelagos only STATE
DELTAS travel, gRPC/protobuf-encoded (§2/ret-5) for maximal wire
efficiency. `ObjectStateVersion.source_arch_name` already keys
versions per archipelago; the delta algebra is §5f's
(`delta_usable`, `repeat_is_noop`, conflicts → proposals).

Build order: rows + pure rules now (ret-1c); the relay daemon lives
in the sidecar and follows ret-5 (gRPC bodies) + ret-7 (LXMF store-
and-forward for consumers that sleep).

✅ **DELTA BROADCASTING BUILT + TCP-PROVEN 2026-08-13** (sidecar,
radios dark): deltas = changed keys + removed list vs prior payload,
keyframes MANDATORY (every Nth / forced / non-dict payloads), byte
savings MEASURED and exposed (162 B delta vs 334 B keyframe = 49% on
a realistic payload; 96% on a toy one where the envelope dominates —
the facts say which). Late joiner missed deltas (counted), recovered
EXACTLY on the next keyframe; repeats no-op'd; final states
byte-identical on both consumers. 🔑 **MTU finding: a keyframe over
~450 B cannot fly as one PLAIN packet (RNS ~500 B MTU)** — the state
POST now refuses 413 WITH the numbers instead of spinning; larger
state rides ret-7 (LXMF/Resource fragmentation). JSON deltas v1;
gRPC/protobuf bodies remain ret-5.

## 5o. PEER DISCOVERY + ADJUDICATION — .arch or .mesh
## (ret-1d, Dustin 2026-08-13)

"We need to be able to see potential peer broadcasts and choose if
they become part of the archipelago (we know it is one of our own
devices) or if we should treat it as part of the wider mesh."

- **`PeerSighting`** — every announce/broadcast HEARD becomes an
  observation row: identity + destination hashes, aspects, which
  interface/bearer it arrived on, first/last heard, count. Status
  `unadjudicated` until a human decides; sightings are MEASURED
  facts, never trust.
- **Adjudication** (KC-verified act, recorded with who/when):
  `archipelago` — "this is ours": creates the ArchipelagoNode and
  enters `.arch` naming/routing (trust GRADES stay separate rows —
  admission is routing, not authority, §5c). `mesh` — a stranger we
  still want to see: enters **`.mesh`**, reachability-tracked,
  interactions capped at the .mesh rung (proposals, data rules,
  census). `ignored` — heard, noted, not shown again.
- **Broadcast over ALL bearers** (row 21): the lighthouse speaks
  PLAIN over whatever interfaces its exposure allows — LoRa, WiFi,
  TCP, HAM alike (PLAIN is proven on TCP and LoRa already). The §5g
  gate is unchanged and PER-INTERFACE: amateur carries public-only
  cleartext; ISM/wired carry any publication class, encrypted or
  not. HAM is one bearer of the broadcast core, not its definition.
- The sidecar LISTENS (announce handler) and surfaces peers-heard in
  /status; ROWS are created only by the adjudication act on the
  backend — hearing is not admitting.

## 5p. MESH SIMULATION — spacing, relay allowance, scenarios
## (ret-1e, Dustin 2026-08-13)

Simulate isle-meshes with KNOWN devices (DeviceModel rows) across a
map, before anyone buys hardware or walks a field.

- **Propagation modes are a fidelity ladder**: `flat-assumed` (v1 —
  link-budget/declared-range math on assumed flat terrain, EVERY
  result carrying the disclaimer), `measured` (LinkMeasurement rows
  overlay/anchor the prediction), and `ideal-elevation` /
  `average-elevation` which REFUSE with the disclaimer for now —
  ⚠ **terrain accounting is deliberately NOT built yet** (Dustin:
  advanced feature, much later; we say so rather than pretend).
- **Spacing + relay allowance**: for a target per-peer bandwidth
  across the WHOLE mesh at a given size, compute the node spacing
  (max spread with the smallest node count — hex packing at a
  safety-margined range) and the RELAY ALLOWANCE each node must
  carry (forwarding others' traffic: per-peer target × average hops
  × peers / nodes, spatial-reuse factor as a conservative knob).
  Assumptions are LISTED in the result, never buried.
- **Scenarios as rows**: bearer sets — lora-only, wifi-halow-only,
  lora+halow, +HAM broadcast mesh-apps, and CONFINED variants
  (wifi-only-mesh-app-broadcasting: lighthouse traffic strictly on
  wifi so LoRa transport is never crowded out; halow+HAM only).
- **Per-app spread allowance**: each app's broadcast carries which
  bearers it may traverse, a max airtime share per bearer, and a
  max hop radius — "how much spread is allowed per app" is a
  policy, and oversubscribed policies are refused with arithmetic.
- **Interference inference**: irregular reach patterns (measured
  reach by bearing falling far short of the mode's prediction in
  some sectors but not others) become NAMED interference
  suspicions with the evidence — derived, never asserted.
- **Spread policy forms** (Dustin, same conversation): max hops,
  max distance, or a BOUNDARY SHAPE (geojson polygon) — and the
  shape derives max hops PER DIRECTION (distance to the edge along
  a bearing over node spacing). All present limits apply; a policy
  with no limits refuses (unbounded spread must be impossible to
  state by accident).

✅ **BUILT + PROVEN 2026-08-13** (`meshsim_basis.py` + wiring):
selftest **125/125**, dyn proof **19/19** — meshsim computed a
lora-only 9-node plan from the SH-L1A catalog row live (range 1000 m
declared, relay verdict fits, disclaimer riding every response) and
`ideal-elevation` refused 400 WITH the disclaimer. DeviceModel
gained `rx_sensitivity_dbm` + `declared_range_m` (SH-L1A: −129 dBm,
1000 m mid-vendor); catalog seed also rides the legacy pass so
composition-gated boots still get it. `POST /api/reticulum/meshsim`.

## 5q. CONFIGURABLE MAP SIMULATIONS — placement, population, cost
## (ret-1f, Dustin 2026-08-13)

The §5p simulator becomes configurable against real geography and
real prices:

- **Population build mixes**: percentages of people carrying
  particular builds (lora / ham / wifi / wifi-halow / lorawan). The
  interop matrix does the honest work: LoRaWAN builds cannot peer
  (star-of-stars, DECIDED row 9), HAM-rx builds LISTEN to a licensed
  HAM core without transmitting (§5g receive-first), closed-framing
  models pair only with themselves — so a mix report says who
  actually interconnects, who is reachable one-way, and who is
  ISOLATED, never just a percentage pie.
- **Reach modes**: `max-spread` (hex fill from a point/area — max
  coverage, fewest nodes) vs `linear` (a corridor chain along the
  shape's long axis — roads/rivers; the chain is the relay STRESS
  case, avg hops ~n/3, and the math says so).
- **Drawn geolocation shapes**: geojson polygons (lon/lat converted
  to local meters at the centroid — equirectangular, fine at mesh
  scales, stated as an assumption; terrain still disclaimed).
- **(A) Cheapest optimal placement**: given the shape + device
  profiles WITH PRICES (DeviceModel gains price_usd + dated
  evidence; unpriced/unranged models REFUSE to be costed), rank
  candidate types by total cost of feasible coverage (spacing →
  count → price × count, relay-allowance feasibility gate), return
  the winner's actual node positions.
- **(B) Fixed-locations feasibility**: given specified locations,
  can the shape be covered — uncovered gaps NAMED with centroids,
  disconnected nodes NAMED — with what types and what bandwidth to
  every node (graph-aware hops), then cost-optimized per node
  (greedy v1, stated).
- **Resilience** (proposed, built): remove each node in turn —
  articulation nodes whose loss partitions the mesh or uncovers
  area are single points of failure, named with what they'd take
  down.
- **Proposed for later** (plan-only): growth curves (per-peer
  bandwidth vs mesh size), duty-cycle saturation vs population
  activity, store-and-forward latency for sleeping nodes (ret-7),
  cost-vs-coverage Pareto sweeps, HAM-core one-to-many coverage
  for majority-RX populations.
- ⛔ **DRONE BRIDGE RELAYS — SHELVED 2026-08-13 (Dustin: "remove
  drones for now, I do not want to deal with those legal
  complications").** Was built and proven the same evening
  (DroneBridgeProfile, drone_bridge_plan, per-gap feasibility,
  flight-rules-assertion gate) then surgically removed; the ANTENNA
  work from the same wave stays. Revival: the code lives in git
  history — framework commit `7201c0a`, angular commit `7acbb12` —
  restore from there, not from memory.

- **Node LOADOUTS** (Dustin, same conversation): a node may carry
  MULTIPLE devices — several LoRa or HAM units to raise bandwidth
  (units multiply capacity on DISTINCT channels, range unchanged;
  same-channel units contend and buy nothing — stated), and mixed
  kits (lora + wifi + ham-rx on one node) whose connectivity is the
  UNION of their parts. The real rows already model this (one
  ReticulumInterface per device); the sims learn kits: cheapest-
  coverage may answer "fewer nodes × more units" where bandwidth,
  not range, binds; population mixes become kit percentages.

✅ **BACKEND BUILT + PROVEN 2026-08-13** (`meshsim_placement.py`):
selftest **139/139**, dyn proof **21/21** — live cheapest-coverage
put 8 SH-L1A nodes across a 2 km square for $223.92 with positions
returned, and a polygon-less placement refused 400 naming the knob.
Fixed-locations reports coveredPct + gaps by centroid + isolated
nodes + BFS-measured hops (not the heuristic — the result says
which); resilience names articulation nodes with what they take
down; population mixes report peers / one-way listens / isolated
per build (lorawan needs-a-gateway, ham-rx one-way, §5g note).
DeviceModel gains `price_usd` (0 = unstated → refuses costing);
SH-L1A priced $27.99 APPROXIMATE with dated evidence ("re-check
before purchasing at scale" — Amazon serves no price to
non-browser fetches).

## 5r. REMOTE DEVICE CONTROL over Reticulum/LoRa (ret-1g,
## Dustin 2026-08-14)

"Flashing a device with an address for Reticulum and controlling it
remotely" — microReticulum (C++ RNS for ESP32-class MCUs) is the
flash target, UNDER LICENCE-GATE RESEARCH (upstream's relicensing
makes lineage the deciding question). **For now: a SIMULATED device,
controlled over the REAL LoRa pair** — the protocol and safety seams
proven before any firmware exists.

The §5b rules made concrete (a seconds-latency lossy link NEVER
closes a control loop):
- **Command + ack + derived timeout**: versioned envelopes; every
  command idempotent-keyed (commandId; repeats no-op); controller
  timeouts derive from measured RTT (§5e), never constants.
- **The device holds its own safety**: declared SAFE STATE per
  actuator + a DEADMAN — controller silence past the deadman window
  reverts actuators locally, logged as an event. The mesh carries
  intent and telemetry; the machine protects itself.
- **Binding is identity, not hope** (Dustin 2026-08-14: "controllable
  only from a particular address" — and identity is STRONGER than
  address: addresses spoof, identities don't without the key): the
  device is provisioned with its controller's identity hash; commands
  arrive over an RNS Link whose initiator has IDENTIFIED
  (link.identify) — an unbound identity's commands are REFUSED by
  name and recorded. On real hardware "flashing with an address"
  means flashing THREE things: the device's own identity, its
  destination name, and its CONTROLLER'S public key.
- **THE OWNER IS THE ISLE** (Dustin 2026-08-14): the flashed owner
  identity is the INSTANCE identity (§6 binding — the one the
  sidecar already persists in its volume, e.g. pol-core's
  `765aa9a9…`), never a person's. Humans command THROUGH the isle:
  KC-authed acts with provenance decide when the sidecar keys up;
  the device only ever knows "my owner is isle X". Staff and
  laptops rotate without re-flashing the tractor; only deliberately
  re-keying the isle (wiping the sidecar volume) changes the owner.
  ⚠ Two enforcement mechanisms, chosen by firmware completeness
  (microReticulum research decides): (1) identified Links — replay
  dies free with the link's ephemeral session keys; (2) signed-
  command envelopes verified against the flashed controller key —
  works on minimal firmware but MUST add explicit replay protection
  (monotonic counter / signed timestamp), because LoRa is receivable
  by anyone and a recorded valid frame can be re-broadcast.
- **Rows later this arc**: ControlledDevice (actuators + safe
  states + deadman + bound controller) and DeviceCommandRecord
  (command→ack trail with measured latency) — commanding from the
  UI will be a KC-authed act with provenance; inbound telemetry
  stays ret-8 (proposals).

✅ **SIMULATED DEVICE, REAL LoRa — PROVEN 2026-08-14** (rig
`sim_device.py`/`sim_controller.py`, SH-L1A pair at the legal
config, fidelity measured-real):
| seam | result |
|---|---|
| command → ack | `set_speed 3` / `implement lowered` executed, **RTT ~245 ms** |
| state query | read back correctly over the air |
| identity binding | a ROGUE identity's command **refused by name** (link identification, not honor) — state untouched |
| deadman | 25 s controller silence → device **autonomously reverted to safe state** (speed 0, implement raised), confirmed by post-silence query |
Command-to-ack ~245 ms at 62.5k air is comfortably interactive for
command/ack semantics — and still NEVER a closed loop (the deadman
is the proof the machine protects itself).

**RESEARCH VERDICT 2026-08-14 (gate addendum has the detail):**
microReticulum is **Apache-2.0-clean** (GPLv3-ok, translation-
provenance caveat noted) and DOES implement identified Links (landed
0.3–0.5.0, interop-tested vs RNS 1.2.9) — so mechanism (1) is
available on MCU in principle. BUT: no LXMF, no E220/UART driver in
ANY implementation (E220 hardware cannot become an RNode — closed
EByte firmware), provisioning wire format still churning, links two
months old, and 🔑 **our 0.9.4 pin cannot link with RNS 1.x** (gate
addendum). **TWO-TRACK DECISION:**
1. **Near-term field device = Pi-Zero-class Linux + our pinned
   Python rns + a small custom E220 serial interface** (~100 lines
   of framing over transparent UART; needed on BOTH ends of an E220
   link regardless) — licence-clean, protocol-identical to our mesh,
   LXMF store-and-forward available. ~0.6–1.5 W continuous is the
   honest cost vs an MCU's milliwatts.
2. **Watch microReticulum, don't bet yet** — revisit when it grows
   LXMF/stable provisioning, or when we un-pin (RetiNet, AGPL-3.0,
   is the gated exit).

**Dustin authorized overnight assumptions (2026-08-13, "make
assumptions… go through as many tasks as you can"). Each answer below
is an ASSUMPTION with its reversal cost named — confirm or correct;
none is treated as settled the way the 18 DECIDED rows are.**

- **Hardware:** do we own any LoRa radios (RNode-flashable boards) yet,
  and which band? ret-6 and ret-9 are blocked on hardware, not code —
  and after the scan arc, naming a hardware blocker early is the
  lesson, not a formality.
  - ✅ **ANSWERED (Dustin 2026-08-13): TWO USB LoRa devices are owned**
    and can go on two isle devices for testing — ret-6/ret-9's
    hardware blocker is RESOLVED. Band still assumed **915 MHz ISM**
    (US) until the boards are identified (band is printed on
    board/antenna and confirmed at flash time; a 433/868 unit would
    just change the row field). Bring-up order: identify via udev →
    DeviceLink rows → flash RNode firmware (rnodeconf ships inside
    the pinned rns 0.9.4, MIT; the firmware itself is GPLv3 at any
    version) → RNodeInterface in a sidecar → ret-6 battery.
- **Second site:** is the second isle a real other location, or a
  second box on this desk for bring-up? Both are useful; they prove
  different things.
  - **ASSUMED:** VMs/containers on hardware we own for ret-0..ret-5
    (already DECIDED row 18); the "second site" is treated as a desk
    bring-up first, real distance only at ret-9. *Reversal cost: none —
    this only sequences purchases.*
- **First real payload:** what should actually cross the link first —
  a scorecard sync, module/topology gossip, meeting presence, file
  transfer? The answer decides whether ret-4 optimises for small
  frequent messages or rare large ones.
  - **ASSUMED: module/topology gossip** — small, frequent, structured,
    entirely our own schema (protobuf-ready), it is what `.arch`
    reachability and the directory already produce, and it exercises
    the ret-8 proposal seam naturally. So ret-4 tunes for
    **small-frequent** first. *Reversal cost: low — encoding/FEC/cadence
    are per-binding knobs, so a rare-large binding (file transfer via
    LXMF) adds a binding, not a redesign.*
- **Identity binding:** should an RNS identity map 1:1 to a KC user, or
  to an INSTANCE (with users authorized behind it)? Instance-level is
  simpler and matches how isles already federate; user-level is what
  end-to-end accountability would want.
  - **ASSUMED: INSTANCE-level** (the plan's own lean): one RNS identity
    per Polari instance, users authorized behind it by ordinary KC
    auth; `ReticulumIdentity.kc_subject` stays NULLABLE so a per-user
    binding (e.g. an operator's HAM identity) can be added without
    schema change. *Reversal cost: low — the row already carries both.*
- **Scope of "arbitrary internet protocols":** the honest near-term
  target is *our own* app traffic plus a named handful (HTTP GET, gRPC
  unary). Truly arbitrary IP over a kilobit link is a promise the
  physics cannot keep, and I would rather say so now than build a
  demo that says otherwise.
  - **ASSUMED as written:** own traffic + named handful. The gateway
    refuses unmapped/unnamed protocols by name (§3), which is also
    what makes widening the set later a data change.

## 5c-b. What an archipelago IS — his definition (2026-09-07), and what it changes

"An archipelago is a mesh network that is high speed enough to allow
direct access to websites over .arch, even if you are not on the same
isle. Being on the same isle is being on your own private LAN and fully
trusted. An archipelago is a specified set of Reticulum nodes where
speeds are internet-like (probably would want to define a specific
latency speed). Some archipelago apps may become too slow (due to high
traffic and too large of an archipelago) to where it then makes sense to
suggest converting to a .mesh despite being on the same archipelago. Or
it may be we need to build in relay apps in parts of the archipelago if
it gets too large."

Consequences (amend §5c; ret-8 and DECIDED row 8 stand):
1. **Membership is a measured property, not a label.** A node is IN an
   archipelago only while its measured path meets the archipelago's
   service floor: `ArchipelagoDefinition` gains knobs `max_rtt_ms`
   (default **150** — the interactive-web threshold; his number to set),
   `max_loss_pct` (default 1) and `min_bitrate_kbps` (default 1000), and
   every `ArchipelagoNode` carries the last `LinkMeasurement` against
   them (`meets_floor`, `measured_at`). Trust (row 8) and floor are two
   axes: a trusted node below the floor is still trusted, but `.arch`
   names for it render with the "slow" state and the site is not
   promised to load.
2. **`.arch` = direct web access across isles.** The `.arch` rung
   (RETICULUM row 20 ladder `.isle → .arch → .vpn → .mesh → web`) means:
   an app exposed at `<app>.<isle>.arch` is reachable by any member whose
   path meets the floor, over the Reticulum bearer (ret-5 gRPC/HTTP-2
   termination is what makes that real; until it lands, `.arch`
   resolution answers and the transport proof is LXMF + resources).
3. **Degradation is a suggestion, never a silent change.** When an
   archipelago app's measured latency crosses the floor for
   `degrade_window` (default 10 min), the topology emits a
   `TopologySuggestion` with evidence (the measurements, the node count,
   the traffic) and TWO options: (a) convert that app's exposure to
   `.mesh` (the store-and-forward rung, where slowness is the design), or
   (b) place **relay apps** — a new app kind `arch-relay` (the same
   shape as the VPN relay kinds: Blind, forwards only) — at the
   partition points the measurements name. Applying either is a human
   act (ret-8 / mtg-8 seam).
4. **Size has a cost the plan did not account for.** Announce and path
   traffic grow with the node count; the relay kind and a
   `max_nodes_before_relay_suggestion` knob (default 24) carry that.
   The number is a placeholder until ret-6-style measurement on a real
   multi-node archipelago replaces it.
5. **Rung: ret-10 — archipelago health.** Floor knobs + measured
   membership + the degrade suggestion + the `arch-relay` app kind +
   `/display/reticulum` archipelago table with the floor state per node
   (configured tables only). The first measurement on a real pair of
   isles is Phase E of `DEB_TOPOLOGY_TEST_SCENARIOS.md` (2026-09-07):
   two isles over wifi, RTT recorded, so the default floor is set from a
   number rather than a guess.

**Ruling 2026-09-07 — the actor on the lightweight tier.** "Naming a
peer should not require Keycloak. A single static isle identity for the
Reticulum should be sufficient; we can enable multiple Keycloak-tied
Reticulum identities, but the default can be an isle identity for more
lightweight isles." BUILT the same day: `discovery_basis.resolve_actor`
+ `ReticulumAPI._actor` — a KC user always wins; otherwise the isle's
sidecar identity acts (`isle:<hash>`; the instance name stands in,
stated, when the sidecar is down); `RETICULUM_ACTOR_MODE=keycloak`
restores the strict tier. Applied to `POST /peers/{name}/adjudicate` and
`POST /inbound` (still a proposal, never a write). Selftest +6.
KC-tied per-person Reticulum identities = the later option (ret-10).

## 5c-c. Two standing requirements (Dustin 2026-09-07) — what exists, what ret-5 must become

**R1 — static isle identities, always on.** "The static Reticulum
identities need to be maintained for routing purposes and so that the
isle identities can be used for .arch and .mesh app access at all times,
and so they can act as relays even when someone is not logged in."
- Exists: the sidecar's identity lives in the named volume
  `pol-reticulum-data` (survives restarts/recreates — proven ret-2),
  the container restarts `unless-stopped`, and `enable_transport = True`
  makes every isle a Reticulum TRANSPORT node — it already forwards for
  others with nobody logged in. The isle identity is now the default
  actor (5c-b ruling).
- Missing (ret-10a): the identity as a first-class Polari row bound to
  the isle (`ReticulumIdentity` ↔ islemesh `IsleDevice`, `role='isle'`,
  `static=True`), re-announced on a cadence (today: once at start —
  announce cadence knob, default 10 min, silent on RF bearers per row 19
  unless declared), backed up/restored with the isle (`isle uninstall`
  must NOT wipe it without `--everything`; export in the isle's trust
  bundle), and the `.arch`/`.mesh` name → identity binding served by the
  isle's dnsmasq (the ret-3 router half, still isle-core's request).
  Per-person KC-tied identities are ADDITIONAL identities on the same
  node, never replacements.

**R2 — real websites over Reticulum, indistinguishable from normal
web.** "We can run actual website access over Reticulum nodes with the
routing and experience being no different from normal websites."
This is the target ret-5 was pointing at; restated as the acceptance:
a browser on isle B opens `https://<app>.<isle-a>.arch`, gets the isle
A app's page with all assets, and the user cannot tell it crossed a
Reticulum path (within the archipelago floor, 5c-b).
- The honest physics (§2 stands): Reticulum packets are ≤ 500 B, a
  Link costs ~3 RTTs to set up, and there is no TCP inside. Over the
  LAN/wifi TCP bearer (Phase E) RTTs are milliseconds, so "no
  different" is achievable there; over LoRa it is not, which is exactly
  why the archipelago is defined by a measured floor.
- Shape of ret-5 (the web gateway), four walks:
  - **ret-5a names.** `*.arch` resolves on the isle's dnsmasq to a
    synthetic IP (ret-3 pool, netledger-allocated) owned by the LOCAL
    gateway; `.mesh` names resolve the same way but the gateway answers
    with the store-and-forward page (queued/deferred states).
  - **ret-5b transport.** The gateway terminates HTTP/1.1 and HTTP/2 at
    each end and carries request/response over ONE persistent Link per
    (isle pair) with multiplexed streams (Reticulum Channel/Buffer),
    bodies as Resources (fragmented, sha-verified, resumable). Keep-alive
    is the whole game: one Link, many requests, no per-request setup.
    WebSocket/STOMP ride the same Buffer.
  - **ret-5c TLS.** The browser sees a certificate for `*.arch` issued
    by the isle CA (already trusted on every member — `isle trust`);
    the gateway terminates it, the Reticulum Link is the encrypted hop,
    the far gateway re-originates to the app over the isle's own TLS.
    End-to-end TLS to the origin is impossible through a proxy and is
    not claimed; the trust chain is isle-CA → isle-CA, stated on the
    page's cert.
  - **ret-5d measured.** Page-load time and bytes for the same app
    direct vs over `.arch`, per archipelago pair, as `LinkMeasurement`
    rows on the reticulum page; the number, not the claim, says
    "indistinguishable". Degradation feeds the 5c-b suggestions
    (`.mesh` conversion, `arch-relay` placement).
- Boundary: the gateway is a Polari-side engine (the sidecar container
  grows the proxy, still the only RNS importer — licence boundary
  unchanged); dnsmasq/synthetic-IP steering on the router is isle-core's
  half (RETICULUM_ISLE_CORE_REQUEST.md).

## 5c-d. Archipelago metrics: what Reticulum can measure, per route and per app, and the tiered thresholds (Dustin 2026-09-07)

**What the stack can measure (rns 0.9.4, verified against the API we pin):**
| Metric | How | Scope |
|---|---|---|
| round trip (RTT) | `Link.get_rtt()` — measured at link establishment (request → proof); repeated probes (the `rnprobe` idiom: a packet with proof requested, timed) give a series → median + jitter | per destination = per ROUTE (Reticulum picks the path; we record which) |
| hops + next hop | `Transport.hops_to(dest)`, next-hop interface name from the path table | per route; a hop-count change = a re-route event, logged |
| throughput | a `Resource` transfer of N bytes timed at both ends (ret-0/ret-6 already did 50 KB sha-verified); `Link.get_establishment_rate()` as the cheap first estimate | per route, per direction |
| reliability | probe success ratio over a window, Link teardowns/timeouts per hour, Resource retransmit counts | per route |
| interface bitrate | `Interface.bitrate` is DECLARED (nominal), not measured — never treat it as throughput | per bearer |
What Reticulum cannot give: per-app numbers. Those come from OUR
gateway (ret-5): request latency, page-load time, bytes, success ratio
per `(app, route)` — measured where the HTTP is terminated. So: route
metrics from the stack, app metrics from the gateway, both as
`LinkMeasurement` rows (the ret-6 battery generalised: `kind` =
probe|resource|app-request, `route` = dest + hops + next-hop, `app`).

**Measurement cost is real traffic.** On LAN/wifi bearers probes are
free; on RF bearers a probe is a transmission — row 19 (idle radios are
silent) and the TX-legality gate apply: probes run only on bearers with
a declared use, at a cadence the airtime budget allows, never as a
background "health check" on a dark radio. Cadence knobs per bearer;
measurements older than `stale_after` (default 15 min) render as stale.

**Tiers: thresholds gate KINDS of functionality, not membership.** A
route is not "in or out"; each functionality class has its own floor
and an app declares which class it needs (a knob on the app's
`IsleCatalogEntry`/`AppVpnExposure`-style exposure row; default from the
app kind). Defaults (placeholders until Phase E and later multi-node
runs replace them with measured numbers):
| Tier | Functionality | RTT (median) | jitter | throughput | probe success | loss |
|---|---|---|---|---|---|---|
| T0 | store-and-forward: LXMF messages, deferred app data (`.mesh`) | any | any | any | any | any — queued is the design |
| T1 | polled status / small JSON API, dashboards refreshing every few seconds | ≤ 2 s | — | ≥ 50 kbit/s | ≥ 90 % | ≤ 10 % |
| T2 | interactive web pages over `.arch` (the R2 target) | ≤ 150 ms | ≤ 50 ms | ≥ 1 Mbit/s | ≥ 99 % | ≤ 1 % |
| T3 | live streams: STOMP/WebSocket pushes, sim streaming, LiveKit voice/video | ≤ 50 ms | ≤ 20 ms | ≥ 5 Mbit/s | ≥ 99.5 % | ≤ 0.5 % |
| T4 | real-time hardware control | isle only — never over an archipelago route (refused by name) |
Per `(app, route)` the gateway renders one of: **available** (all floors
met), **degraded** (met within 2× — served, with the measurement shown
and the 5c-b suggestion queued), **barred** (below floor — refused by
name with the numbers; T0 fallback offered where the app supports it).
A route can be T2 for one app and barred for a T3 app at the same time;
that is the point of tiers. Thresholds are knobs on the
`ArchipelagoDefinition` (per tier), overridable per app; every refusal
cites the measurement row it came from.

**Rung placement:** the metrics + rows = ret-6b (extend the battery,
route-scoped, cadence/legality-gated); the tiers + per-app state + the
page = ret-10 (with 5c-b's degrade suggestions and relay placement);
the per-app numbers arrive with the gateway (ret-5d). Phase E gives T2's
first real RTT on a wifi route; T3 numbers need a live stream to
measure (LiveKit between isles is the natural test).

## 5c-e. Traffic classes, relay/use policy, duty cycles, and the fork question (Dustin 2026-09-07)

**The question:** split baseline Reticulum messaging traffic from
mesh-app traffic from archipelago-app traffic; control which apps we
USE vs which we RELAY; opt in to relaying normal Reticulum messaging;
and whether a fork at the last MIT point can do all of it while still
enabling normal messaging.

### Four classes (recommendation)
Reticulum itself has NO traffic classes or QoS: a transport node
forwards every packet it has a path for. The split is therefore OURS,
enforced in the fork (below) at two points — the forwarding decision
and the per-bearer outbound queue:
| Class | What | Identified by | Default relay knob |
|---|---|---|---|
| C0 control | announces, path requests/replies, link keepalives | packet type | always (a transport node that drops control is not a node) |
| C1 baseline messaging | LXMF delivery for ANYONE (Sideband/MeshChat-style users), third-party destinations we know nothing about | destination hash not in our tables; announce aspect `lxmf.delivery` | `relay_baseline` ON for wifi/LAN, OFF for RF bearers until the operator declares the use (row 19) |
| C2 mesh apps (`.mesh`) | store-and-forward app data: Resources, deferred proposals, lighthouse state | destination hash learned from an announce whose app_data names a Polari mesh app | `relay_mesh_apps` = allow-list of app kinds (default: the kinds this isle also USES) |
| C3 archipelago apps (`.arch`) | interactive Links: the ret-5 gateway streams | destination hash of a known `.arch` gateway/app + Link traffic | `relay_arch_apps` = allow-list + the route must meet the app's tier floor (5c-d) — relaying a T2 app over a route that cannot carry T2 is refused, stated |
Classification keys on the DESTINATION HASH learned from announces (the
only per-app fact a forwarded packet exposes; payloads are encrypted
end to end and we never look inside). Unknown destination → C1.

### USE vs RELAY are two columns, not one
Per isle, per app kind (and per bearer): `use` (we run/consume it) and
`relay` (we forward it for others). All four combinations are valid:
relay a mesh app we never run (a good neighbour), run an app we refuse
to relay (a heavy one on a thin bearer). `RelayPolicy` row: bearer,
class, allow-list, share, burst, `declared_use` (the row-19 gate for RF).
Receiving is never rate-limited — listening is free and legal; what we
STORE/process is gated by the existing LXMF policy (whitelist + per-
sender window) and the app-data rules (ret-1c).

### Duty cycles (per bearer, per class) — weighted fair queue with floors
- Each bearer has a budget: on LAN/wifi effectively its measured
  throughput; on RF the `AirtimeBudget` row (legal duty cycle first —
  e.g. 1 %/10 % sub-bands in EU 868 — then the operator's share).
- Classes get **shares** of that budget as a weighted fair queue with a
  guaranteed minimum each: defaults C0 10 % (priority, pre-emptive),
  C3 40 %, C1 30 %, C2 20 %; unused share flows to others; C2 (bulk)
  never starves and never blocks — Resources are already fragmented,
  so they yield between fragments.
- Strict priority only for C0; everything else is weighted, because a
  strict-priority C3 would let one interactive session silence
  messaging for everyone behind the relay.
- Per-class token buckets (rate + burst) at the outbound queue of each
  interface, plus a global "relay ceiling" (`relay_max_share`, default
  50 % of the bearer) so our own traffic is never crowded out by what
  we forward for others.
- All of it is knobs with evidence: the reticulum page shows per bearer
  the measured bytes per class per window beside the shares, and the
  drops per class with reasons (ceiling / tier / not-allowed / airtime).

### The fork — what it can and cannot do (facts from RETICULUM_LICENCE_GATE.md)
- **Yes to the fork, from the exact last MIT commits**: `rns 0.9.4`
  (2025-04-15, tag LICENSE = MIT, published before the licence commit)
  + `lxmf 0.6.3`. Forked as `dausume/reticulum` + `dausume/lxmf` pins
  per the standing rule (adopted upstreams forked as dausume pins);
  verify the LICENSE file AT THAT COMMIT + headers before the first
  pin (the gate's three-way check). Nothing from any post-relicence
  commit may be copied in — patches are ours, from scratch.
- **Yes to everything above**: classes, use/relay policy, duty cycles
  are stack-level patches (a forwarding-policy hook in Transport + a
  per-interface class queue) and are exactly why a fork is needed —
  stock Reticulum, any version, has none of it.
- **"Still enable normal messaging" — two different things:**
  1. LXMF messaging BETWEEN OUR NODES and any peer on the pinned
     stack: yes, unchanged (ret-7 proven).
  2. Messaging with the LIVE ECOSYSTEM (people running current
     Sideband/MeshChat on rns 1.x): **NO, today.** The gate ledgered
     it: 0.9.5→1.0.0 moved links to AES-256 and 1.0.0 REMOVED the
     AES-128 handlers, so a 0.9.4 node cannot form a Link with any
     1.x node. Relaying their traffic (C1) is possible only where
     forwarding needs no Link with us — announces and packets pass
     through a transport node without a Link to it — but any
     Link-bearing exchange that terminates or is proxied at us fails.
     So "help relay normal Reticulum messaging" is honest ONLY as
     pass-through, and even that must be tested against a 1.x node
     before it is claimed.
- **The clean way to real interop: implement the 1.x link crypto
  ourselves in the fork.** The change is a cipher/handshake version,
  not a licence problem — the wire format is a fact, not code; we
  re-implement it from the protocol (documented publicly) without
  copying post-relicence source, dual-mode (accept 0.9.4 links from
  our own old nodes, speak 1.x links to the ecosystem). RetiNet
  (AGPL-3.0 fork, "RNS 1.0 compatible") is the gate's named fallback
  if we would rather adopt than write; AGPL + GPLv3 combine, gate it
  first. microReticulum's dual-mode is untested against 0.9.4.
- **Verification before any claim (ret-11a):** a current-version
  `rnsd` in a throwaway VM peered with our fork: (a) announces cross,
  (b) a 1.x↔1.x LXMF exchange relayed THROUGH our node succeeds,
  (c) a Link 1.x→us fails today and succeeds after the crypto patch.
  Numbers into TESTING_OWED; no interop sentence in any doc until (b).

### Rungs
- **ret-11 — the fork + traffic classes**: dausume pins of the MIT
  commits; forwarding-policy hook + per-interface class queues;
  `RelayPolicy`/`AirtimeBudget` wiring; use/relay columns on the app
  rows; the page's per-class bytes/drops table.
- **ret-11a — ecosystem interop**: the 1.x link-crypto re-implementation
  (dual-mode) + the throwaway-VM proof above; until it lands the pin-
  isolation note stays on every messaging response.
