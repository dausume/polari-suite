# Testing owed — tracker (written 2026-08-13, for Dustin's pass later today)

Everything below is BUILT and machine-verified as far as automation can
go; each item now needs a human, a credential, or a device. Ordered by
how much one sitting closes.

## 1. Meetings arc (mtg) — four blockers, ~1 hour with the right gear

From `MEETINGS_AND_RETICULUM_HANDOFF.md` §2; code all on `dev-mtg-1`
×4 repos, deployed to staging.

| # | Test | Needs | Where |
|---|---|---|---|
| 1 | **Signed-in join** — real mic/camera + moderation against a live peer | Keycloak credentials | `/meetings` on staging |
| 2 | **Second-device join** — phone joins room `mtg1` | Dustin's phone | links in scratch rig `JOIN_LINKS.txt` (`…/scratchpad/mtg0-rig/`) |
| 3 | **Headset session** — immersive entry, avatar rendering | headset; expect the Wolvic + self-signed-CA trap | `/meetings` → XR entry |
| 4 | **3D drag gesture** — mtg-8 seam is proven server-side; the viewer interaction needs a design pass (what is draggable?) | Dustin's design input, then a build session | commit-drag → proposal (202) already live |

Everything up to the auth wall is verified; item 1 is the highest-value
single test (it exercises mtg-2/3/4/6 with a real user).

## 2. Standing review gates (older, still open)

- **dyn-1..9 (dynamic modules)** — backend complete + proven on
  `dev-dyn-1` (8 commits), NOT merged/pushed, explicit review gate.
  The mtg and ret work stack on it, so this review unblocks the most.
- **Push sweep** — CONSOLIDATION note: `push-all-dev.sh` ready
  (dry-run default); pushing is Dustin's manual step. Many arcs are
  "NOT pushed".
- **Wax-mold casting frontend** — cert-accept + `/casting` eyeball +
  wizard UI walkthrough (CASTING_FRONTEND_HANDOFF.md).
- **Climate app** — browser pass + graph tuning; re-ingest after any
  redeploy until the sqlite flush is fixed.
- **WebXR xr-1/2** — UNCOMMITTED, awaiting a headset session (can share
  the sitting with mtg item 3).

## 3. New tonight (Reticulum, ret-0..ret-3 built) — decisions owed to YOU

Everything machine-provable was proven (selftests 61/61 + 79/79, dyn
proof 14/14, sidecar live + transport-routing proven). What needs
Dustin:

1. **⚠ THE LICENCE FINDING (5 min read, one decision):** "Reticulum
   is MIT" is STALE — it relicensed 2025-04-15 to a restricted,
   GPLv3-incompatible licence. I proceeded on the assumption in
   `RETICULUM_LICENCE_GATE.md`: **pin the last MIT pair rns==0.9.4 +
   lxmf==0.6.3** (options weighed there). Confirm or choose
   differently — everything built honours the pin either way.
2. **§6 assumptions** (marked in the plan): first payload =
   module/topology gossip; identity per INSTANCE; 915 MHz ISM; desk
   bring-up first. Each names its reversal cost; all cheap to flip.
3. **`pol-reticulum` was LEFT RUNNING on staging-a** (512 MB cap,
   idle) — `pol compose reticulum down` if unwanted.
4. **`RETICULUM_ISLE_CORE_REQUEST.md`** — hand it to isle-core's
   Claude when convenient (router DNS/steering; nothing blocks on it).
5. ~~Hardware order~~ RESOLVED: the SH-L1A pair is identified,
   legally configured (your recorded approval), measured, and
   catalogued.

## 4. DEPLOYED while you were at work (2026-08-13 afternoon) — a
## browser pass is now possible

Backend + frontend ROLLED on staging; reticulum module admitted live
(106 s); `RETICULUM_URL` knob set; every surface verified from
inside: capability (pins, sidecar REACHABLE), peers (sidecarLive,
honestly empty), arch-topology (local isle + local-tcp), meshsim
(live plan from the SH-L1A row, disclaimer riding). **Your pass:**
open `/arch` — blocks, peers panel, and the now-CONFIGURABLE planner:
pick one of your drawn map shapes (the picker lists your real
MapPolygonDefinition rows), try cheapest-coverage on it, click nodes
onto the SVG for fixed-locations, set a population mix with a kit
row (e.g. 2×lora+wifi+ham-rx), watch LoRaWAN come back isolated with
its reason. A real KC-authed ADJUDICATION end-to-end is the one flow
that needs your login. SH-L1A price is APPROXIMATE ($27.99, Amazon
refused a headless fetch) — re-check before purchasing at scale. Deploy note: the backend service's bind
mount `polari-rf-node/ca/root_ca.crt` had been cleaned away — 
restored as a copy of `ca/.step/certs/root_ca.crt` (public cert,
gitignored); if that cleanup was deliberate, the service spec is
the thing to change.
