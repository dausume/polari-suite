# LiveKit collaboration sessions — plan (v2: GROUP MEETINGS arc)

**Date:** 2026-08-10, **v2 2026-08-11** · **Status: NEXT ARC, ready to
execute — nothing built.** Source: Dustin's brief (via ChatGPT); v2
scoped by Dustin 2026-08-11: *"group meetings for both web/video and
VR using LiveKit"* — which answers §8's first question (MEETINGS
first, a working group call is the milestone) and pulls VR forward as
a first-class client rather than a phase-8 afterthought. Companion:
`SCAN_RECONSTRUCTION_PLAN.md` — converges at the scene/asset layer
(now real: scan-9's GLB/LOD export exists), no direct dependency.

## v2 — the mtg-1..8 ladder (execution order)

Everything in the original §§0–7 stands (identity KC-only; the
ephemeral-vs-authoritative line with teeth; two installable pieces;
recording off by default pending the §7 governance choice). What v2
adds is the concrete ladder and what this week's scan arc settled:

- **mtg-0 — UDP/media LAN proof (BLOCKING, unchanged §3).** Two
  browsers on the wifi exchanging audio through self-hosted LiveKit
  with the Polari CA trusted. Includes the two infra firsts: `/udp`
  port publishing (none exists suite-wide) and the netledger's UDP
  port-range resource kind. Media bypasses nginx; only
  signalling/HTTP proxies (odoo variable-proxy_pass precedent).
- **mtg-1 — `pol-livekit` service**, the walked-twice worker pattern
  (now walked three times by prf-recon-engines, whose files are the
  freshest template): own compose + `pol compose livekit` case +
  `services.yml` entry + `ModuleResourceProfile` + topology seed.
  Placement per Dustin's standing rule: the resource ledger decides
  (⚠ the ledger has no BANDWIDTH dimension yet — add it or note it).
- **mtg-2 — `collab` module, the SECOND module born manifest-first
  on dyn-1** (scanning proved the recipe end-to-end today, admit/
  put-away included). Classes: `CollaborationSession` (room identity,
  scope local|web, moderation state) + `MeetingRecord` (§7's
  persistent record: participants, decisions, artifact links — no
  audio). Token endpoint: KC-authenticated → short-lived LiveKit JWT
  (HS256 against the service's API key — pure-python signing, NO
  LiveKit SDK in the backend image), grants derived from KC groups
  via the group-authority mapping. Capability endpoint with the
  recon_remote-style refusal ladder (LIVEKIT_URL knob → topology →
  suggestion).
- **mtg-3 — the Angular group-meeting client** (THE milestone): join
  by session row, audio + video + screenshare, participant list,
  mute/kick moderation from the session's moderator (KC-group
  derived). `livekit-client` is Apache-2.0 (license-gate it properly
  anyway — three sources, per the standing method). Useful the day
  it lands: staff meetings on the LAN.
- **mtg-4 — versioned realtime message schemas** (§6.5 unchanged —
  BEFORE any VR client; pose/presence/preview are a wire protocol).
- **mtg-5 — VR meeting client**: the app-shell android-vr APK
  (Wolvic) joining the SAME CollaborationSession — WebXR scene,
  avatar heads + hands from mtg-4 messages, spatial-ish audio
  (LiveKit pan by pose is enough at first). Avatars = a NEW small
  asset class (§8 answer: nothing existing fits; keep it a row +
  GLB reference like every other asset). ⚠ Wolvic + self-signed CA
  trust is the known trap; the store shell's CA-pinning path is the
  door. VR captures nothing (no passthrough) — consumer only.
- **mtg-6 — simulation pages join a session** (voice alongside the
  model — the original phase 4).
- **mtg-7 — scanned environments in the room**: place scan-9 GLB/LOD
  assets (they exist now, with scale-honesty carried on the row) as
  the shared scene. The convergence §5 promised, cashed in.
- **mtg-8 — authoritative shared manipulation**: drag previews over
  LiveKit, commits through the normal propose/execute path — the §2
  rule made tangible.

**Decisions inherited from this week:** LAN-first (`scope: local`;
off-LAN = EXTERNAL_APPS ladder + TURN, its own later step);
recording stays OUT of v1 (the MeetingRecord row is the durable
thing); every new service/module optional-by-design (dyn-1 manifest
+ own compose); the shell capability gate (scan-3) is the precedent
if the DESKTOP shell ever needs native mic access — browsers in-page
getUserMedia should suffice for mtg-3 since pages run over the
trusted CA, unlike the shell's cert-error webview case.

**Still open for Dustin (trimmed):** (a) does the resource ledger
grow a measured bandwidth dimension for media placement, or do you
just name the host? (b) v1 participant cap to size the media host
(a family-sized 4–8 vs workshop 15+)? (c) is `web` scope wanted at
all this year, or is LAN the whole 2026 story?

---

*Original plan (v1, 2026-08-10) below — §§0–8 remain the design's
foundations and constraints.*

## 0. The brief's central call is right

"Do not build Polari Video Meetings and later Polari VR Meetings; build
Polari Collaboration Sessions" — agreed, and it matches how the rest of
the system is factored (one object, many display definitions; one app
definition, many shells). A `CollaborationSession` is the object;
browser meeting, simulation-side voice, and VR are display/client
surfaces over it.

What follows is mostly what the brief could not know: the parts of this
that Polari has already decided.

## 1. Identity — already settled, and it constrains the design

Keycloak is the identity authority and the standing rule from the
external-apps work is **Keycloak-only gating at every level** (L1 = one
KC user, L2 = a KC group). There is no separate credential store; the
§45b htpasswd door is already marked as a mismatch to rework.

So LiveKit tokens are minted by Polari from a KC-authenticated session,
short-lived, with grants derived from the caller's KC group membership —
never issued to a client that Polari has not just authorized. This is the
brief's §2, and it is not optional here; a second credential store would
repeat a mistake already identified.

Group-derived roles map onto the existing group-authority work rather
than a new role table.

## 2. The one hard architectural line

The brief's §5 (ephemeral vs authoritative) is the whole design, and it
deserves to be stated as a rule with teeth:

> **Nothing that arrives over LiveKit may mutate Polari state.**

LiveKit carries: head/hand pose, gaze, cursor, speaking state, drag
*previews*, presence. All of it is transient, lossy, and unvalidated.

Polari carries: identity, permission, ownership, committed transforms,
votes, annotations, audit history. Every one of those goes through the
normal backend path and lands in the object DB.

This is the same split the propose → execute → provenance surface
already enforces, and the same reason it exists: a consequential change
is a proposal a human or an authorized service commits, not a message
that happened to arrive on an authenticated socket. A dragged object
moves smoothly for everyone via LiveKit and *becomes* moved via Polari.

## 3. What "self-hosted" costs, honestly

The brief says "deploy self-hosted LiveKit" as Phase 1 as though it were
a docker run. On this infrastructure it is not, and the reasons are
already-known ones:

- **LiveKit needs UDP.** WebRTC media wants a UDP port range, not just
  443. Every existing exposure — the isle agent, the nginx proxies, the
  `isle url expose` door — is HTTP/TLS over TCP. **None of the current
  exposure machinery carries this.** This is the single biggest unknown
  and it should be proven before anything else is built.
  *Confirmed by code investigation 2026-08-10:* there is not a single
  `/udp` port mapping in any compose file or jinja template, no nginx
  `stream {}` block anywhere, and the netledger
  (`islemesh_netledger.py`) models CIDR pools and published **TCP**
  ports only. The one UDP precedent in the whole suite is WireGuard
  (`pol remote` writes `wg0.conf` and tells the human to forward one
  UDP port manually). So Phase 0 concretely means: `/udp` port
  publishing on the LiveKit service, and media that bypasses nginx
  entirely (WebRTC media is not proxyable by an HTTP proxy; only
  LiveKit's signalling/HTTP goes behind the proxy).
- **The netledger exists for exactly this — but must grow a UDP-range
  concept first.** Today it reserves CIDRs and TCP ports; a UDP port
  range is a new resource kind, a small honest extension rather than a
  workaround. Register the range there, or it collides at scale.
- **TLS.** Browsers require secure contexts for getUserMedia; the LAN
  story is the self-signed Polari CA (see `LAN_ACCESS_HOME_TEST.md`), so
  a device must trust that CA before a meeting will work at all — the
  same trust step, with the same iOS "enable full trust" trap.
- **LAN vs internet stays distinct.** A LiveKit room reachable on the
  wifi is `reachability.scope: local`. Making it reachable off-LAN is the
  `EXTERNAL_APPS_PLAN.md` problem plus a TURN server, and should not be
  smuggled in as a side effect of "deploying LiveKit".

**Suggested Phase 0, ahead of the brief's Phase 1:** prove two browsers
on the home wifi can exchange audio through a self-hosted LiveKit with
the Polari CA trusted. If UDP through the current network shape does not
work, everything downstream changes, and it is far cheaper to learn that
now.

## 4. Where it runs — and the modular split

Per the standing modularization goal (2026-08-10: split things apart so
they can be pulled down or installed only when needed), this arc is
**two separately-installable pieces**, not one:

1. **`collab` backend module** — pure Python, light, a normal registry
   module: `CollaborationSession` (+ later the persistent meeting
   record of §7) and the KC-gated token-minting endpoint. Active only
   on instances it's assigned to (`pol topology assign`), like every
   module. No LiveKit SDK weight in the core image beyond the token
   signer.
2. **`pol-livekit` service** — LiveKit's own image, its own compose
   file, never part of the default `up`. The suite already has the
   exact convention: a separate compose file + a role case in
   `pol compose` (msci-engines/cad-engines walked this path twice), an
   entry in `pol-build/registry/services.yml`, and — for its HTTP/
   signalling side behind nginx — the odoo precedent of a *variable*
   `proxy_pass` with the docker resolver, so the proxy keeps booting
   when the optional service is down. Media ports are `/udp` published
   directly (§3), not proxied.

LiveKit is a media server: CPU, bandwidth, and a wide port range. It
must not ride in the backend image. It is placed deliberately on a host
chosen for bandwidth — the same placement story as the reconstruction
engines, through the same topology/ledger machinery (a
`ModuleResourceProfile` for it, a topology seed pin, and the
provider-registry ladder: env knob → topology resolution → honest
refusal with a suggestion). Later optional pieces — recording/egress,
transcription, an AI participant — are each **their own additional
service**, installed only if §7's governance decision ever says yes;
none of them may be a reason to fatten the base two pieces.

Keycloak's own reachability is a prerequisite (a VR or mobile client must
reach the KC external/LAN name to log in at all).

## 5. Convergence with scanning — the shared layer

The two briefs converge at the **Polari scene/asset** layer, and that is
the right boundary:

    scan pipeline  →  canonical Polari asset  ←  collaboration session
                          (scene / object)

A reconstructed workshop becomes an environment; a scanned part becomes
an object placed in it; a session is people present around those objects.
Neither subsystem imports the other. The asset model in
`SCAN_RECONSTRUCTION_PLAN.md` §2 is the contract.

⚠ Practical consequence: a raw reconstruction is far too heavy to ship
to a headset. The LOD/collision derivation is not a nice-to-have, it is
the thing that makes shared VR possible at all — and the simplified mesh
must reference the high-resolution asset it came from rather than
replacing it (the brief's §8, and the same "one renderer, one truth"
posture already applied to graph exports).

## 6. Suggested order (revised)

0. **UDP/media reachability proof on the LAN** (§3). Blocking.
1. LiveKit self-hosted, with a URL binding + netledger entry.
2. KC-derived short-lived token issuance; `CollaborationSession` as a
   registered class (schema first, as always).
3. Angular meeting client — audio, video, screen share, participants,
   moderation. Useful on its own, and the honest milestone.
4. Simulation pages join an existing session (voice alongside the model).
5. **Versioned realtime message schemas** — do this before VR, not after.
   Pose/presence/preview messages are a wire protocol; versioning them
   later is expensive.
6. Three.js participants → 7. WebXR avatars → 8. mixed desktop/VR →
   9. shared objects + screen surfaces → 10. authoritative collaborative
   manipulation → 11. spatial audio → 12. scanned environments.

Recording, transcription, E2EE and AI participation stay last, and §7
below says why they are not merely "later".

## 7. Recording, E2EE, and the thing to decide early

The brief treats E2EE as deferrable. It is deferrable, but the *choice*
is not, because E2EE and every server-side feature are mutually
exclusive: encrypted media the server cannot read means no server-side
recording, transcription, moderation, or AI participant — unless a
participant or a trusted service is given the key, which is a governance
decision, not a technical one.

Given the repos are public and the accountability model is explicit,
recording deserves the stronger treatment: **a session is ephemeral by
default; a recording is a deliberate, consented, audited act.** The
persistent meeting record (participants, decisions, artifacts, links to
resulting assets) is a Polari object and is valuable on its own — it does
not require capturing anyone's audio.

## 8. Open questions for Dustin

- Is the first real use a working meeting (two people talking), or
  collaboration around a simulation? Phase 3 vs Phase 4 — and the
  meeting one is genuinely useful much sooner.
- Which host has the bandwidth to be the media server?
- LAN-only to start (consistent with everything else right now), or is
  off-LAN a Phase-1 requirement? Off-LAN pulls in TURN plus the whole
  external-apps ladder.
- Do you want recording at all in v1? Deciding "no" now simplifies §7
  considerably and can be revisited.
- Avatars: is there an existing representation to reuse, or is that a
  new asset class?
