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
