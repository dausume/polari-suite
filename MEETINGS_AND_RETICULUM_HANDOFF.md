# Handoff — the meetings arc SHIPPED, Reticulum PLANNED (2026-08-12)

One session. Two things happened: the LiveKit meetings ladder was
built end to end and deployed, and the next arc (Reticulum over
OpenWRT/LoRa) was planned in detail but **not started**.

---

## 1. The Reticulum plan is FINAL (2026-08-12) — ready to RUN once two things land

`RETICULUM_TRANSPORT_PLAN.md` (ret-0..ret-9) is **FINAL** — revised
through eight rounds of Dustin's corrections in one day, with an
18-row DECIDED ledger at the top so a fresh instance does not
relitigate settled choices.

**Only two things are still owed before ret-0 starts:**
1. **`RETICULUM_LICENCE_GATE.md`** — short now that Reticulum is
   confirmed **MIT** (GPLv3-compatible); still must cover LXMF, any
   RNode firmware, and packaging.
2. **The §6 answers** — above all **what payload crosses first**,
   which decides whether ret-4 tunes for small-frequent or rare-large
   traffic.

**Hardware is NOT a start blocker any more.** ret-0..ret-5 develop on
KVM guests with no radio; two ~$20-40 LoRa boards are needed only as
ret-6 approaches, and real separate machines only at ret-9.

Answering §6 + the gate is enough to run ret-0..ret-2 without
further input. ret-0 is deliberately radio-free (two `rnsd` over TCP)
so the stack, identities and encodings are learned before RF exists.

**Decisions already settled — do not relitigate:**
- **isle-core owns OpenWRT/radio/regulatory**; we own the object model,
  gateway, encodings, gate. Router-side DNS/nftables is a written
  REQUEST, never an edit from here.
- **gRPC-over-HTTP/2 must NOT run verbatim** on a kilobit link:
  terminate at each end, carry protobuf bodies, same `.proto`/stubs.
- **STOMP is out** of mesh transport (stays the LAN channel).
- **Reticulum does not route IP** → name registry + netledger-reserved
  synthetic-IP pool + gateway that refuses unmapped addresses by name.
- **Latency is a property of the PATH, not the mesh** — measurements,
  timeouts, encodings and FEC all resolve per path at send time.
- **State replication = parent + child** (+ derived delta), keyframes
  mandatory, conflicts become PROPOSALS via the ret-8 seam.
- **HAM:** the plan states NO legal conclusions. The operator's
  ASSERTION is the only check — no internet validation, ever, because
  a radio gated by an unreachable server defeats an emergency tool.
  Conservative defaults (cleartext on amateur interfaces, `public`-only
  publication class) are design choices and knobs, not legal claims.

## 2. What shipped this session: mtg-0..6 + mtg-8

All deployed to staging, all committed on `dev-mtg-1` in FOUR repos
(framework, angular, rf-node, cli) + suite pointers. **NOTHING PUSHED**
— that stays Dustin's manual step (`push-all-dev.sh`).

| Phase | What | Proof |
|---|---|---|
| mtg-0 | UDP/media LAN proof; netledger UDP port-range kind | audio both ways, `connectionType: udp`, 0 lost |
| mtg-1 | `pol compose livekit up`; signalling behind prf-proxy (cert +SAN rolled) | re-proved on the committed stack |
| mtg-2 | `collab` module, manifest-first on dyn-1 | selftest, dyn lifecycle 13/13, live token accepted |
| mtg-3 | `/meetings` Angular client + moderation | LIVE, browser-verified |
| mtg-4 | versioned realtime wire protocol | 4 compatibility rules proven between two browsers |
| mtg-5 | avatars as licence-carrying rows; scene math | 12/12 headless specs; seeds live |
| mtg-6 | `<meeting-dock>` — voice alongside the model | bound page shows it, unbound renders NOTHING |
| mtg-8 | drag commits become PROPOSALS | selftest 77/77; 401 live |

**mtg-7 was REMOVED** from the ladder and shelved with the scanning
arc (Dustin) — it depended entirely on shelved capability. Recorded in
both the plan and `SCAN_RECONSTRUCTION_HANDOFF.md` §7b. Consequence:
nothing else supplies a shared spatial anchor, so mtg-5's ring seating
is permanent, not a stopgap.

**Four blockers, all needing a human, none unbuilt code:**
1. **A signed-in join** (Keycloak credentials) — everything up to the
   auth wall is verified; real mic/camera and moderation against a
   live peer are not.
2. **A second physical device** — the phone join closing mtg-0/1
   (room `mtg1`, links in the scratch rig's `JOIN_LINKS.txt`).
3. **A headset session** — immersive entry, avatar rendering, and the
   Wolvic + self-signed-CA trap.
4. **The 3D drag gesture** — mtg-8's commit seam is proven; the viewer
   interaction is not, and wants a design pass on what is draggable.

## 3. Gotchas this session paid for — do not re-learn

1. 🔑 **`hostname -I` LISTS DOCKER BRIDGES FIRST.** Creating one
   compose network reordered it, and `pol swarm deploy node` stamped
   `172.20.0.1` into every `${LOCAL_IP}` knob (MSCI_ENGINES_URL and the
   LiveKit URLs) **while reporting success**. Fixed at the root:
   `lan_ip()` in `polari-cli/scripts/lib/log.sh` uses the default-route
   source address, applied across all 9 autodetecting scripts.
   **Suspect this whenever a new docker network appears.**
2. **`docker service update` says "update paused"** (Address already in
   use) on stop-first rollover and then SUCCEEDS — verify the RUNNING
   task's image digest, never trust the update status.
3. **`pol swarm deploy node` did NOT move the frontend** to a rebuilt
   image; needed `docker service update --force --image`.
4. **CRUDE list GET envelope** is
   `[{Class:[{class,varsLimited,data:[…]}]}]` — a wrong guess renders
   "no rows" SILENTLY. Use the `CrudeClassService` unwrap. CRUDE POST
   is multipart `initParamSets`, not JSON (415 otherwise).
5. **Check identity BEFORE row existence** in endpoints, or 401-vs-404
   lets an unauthenticated caller enumerate which rows exist.
6. **Headless Chrome cannot getUserMedia** (131, both modes, fake-device
   flags AND CDP-granted permission). Use WebAudio oscillator →
   `createMediaStreamDestination()` → `publishTrack`.
7. **CORS blocks a scratch-origin test page** — run live browser proofs
   from the SPA origin (`docker cp` into the frontend task; test-only,
   discarded on respawn).
8. **`pgrep -f`/`pkill -f` from the agent shell kills the wrapper**
   when the pattern matches its own command line (exit 144) — use
   fresh ports instead.
9. Frontend `npm run build` runs the theme + responsive guardrails
   FIRST; grids must be `repeat(auto-fit, minmax(min(100%, Npx), 1fr))`.

## 4. Live state at handoff

- `pol-livekit` up; backend + frontend on staging at current digests.
- Sessions seeded live: `lan-standup`, `m2-review` (bound to
  `SimSpaceDefinition/motor-m2-viz`), room `mtg1` from the proofs.
- Working trees clean on `dev-mtg-1` ×4; suite on `dev`. The
  `polari-app-shell` pointer is left MODIFIED exactly as found
  (pre-session, the scan arc's — not ours to commit).
- Scratch rig (throwaway, not committed):
  `…/scratchpad/mtg0-rig/` — tokens, proof pages, `JOIN_LINKS.txt`.

## 5. Suggested next move

Either close the four human blockers above (an hour with credentials,
a phone and a headset would finish the meetings arc properly), or
answer `RETICULUM_TRANSPORT_PLAN.md` §6 and write the licence gate so
ret-0 can start. The two are independent.
