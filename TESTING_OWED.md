# Testing owed — tracker (written 2026-08-13, for Dustin's pass later today)

## 00. New 2026-08-15 (late) — ai-0..ai-3 LIVE (the AI tools arc)

**Backend + store UI deployed to staging; everything below works
today with zero credentials (the null provider is active + ready).**
What only you can do:

1. **Answer the plan's 3 open questions** (AI_TOOL_LINKAGES_PLAN.md
   §Open questions): privacy-filter hard gate vs badge (built as
   BADGE per knob-and-suggestion); one `openai` row covering Codex
   (built as one row); reasoning engine meters counts/bytes/latency
   only, never content (built on that assumption).
2. **GUI pass**: /isle-store now has the dedicated "AI tools"
   section (4 tiles: null / claude / openai / localai) — hosting +
   sovereignty badges, and the detail pane's live readiness +
   linkage table. /engines page now lists `reasoning`.
3. **Remote intermediary proof (credentials are yours)**: pick
   claude or openai, run the tile's binding flow (select →
   set_auth → validate via /ai/providers), then talk to the
   assistant — the ai-tools page should flip that tool to
   ready + active, and /engines/reasoning starts metering.
4. **Local-hosted proof (when you want it)**: `isle app deploy
   localai --image localai/localai:latest --service localai
   --port 8080 --engine reasoning` on any isle host — the ai-3
   binder should auto-flip every instance's assistant to
   openai_compatible at its /v1. Binder is selftest-proven; the
   LIVE end-to-end needs a real LocalAI container (models cached
   first for air-gap). Image tag/variant is your call (fork pin
   dausume/LocalAI).

Deploy note: both swarm rolls (backend + frontend) bounced off the
two other nodes before landing home (the known --force bounce;
`pol allocate` pin still your call). Reticulum stayed admitted.

## 0. New 2026-08-15 — sep-0..7 (eyeball pass + the permissions knob)

**sep-7 is LIVE with the knob OFF (default — zero behavior change).**

**CORRECTION (your 2026-08-15 call): NO new Keycloak groups are
needed — never invent groups.** The 2 seeded AppPermissionProfile
rows are now UNPUBLISHED TEMPLATES bound to no groups (they grant
nothing as seeded; the live rows were backfilled the same way).
Profiles tie to KNOWN EXISTING groups through the auth section's
own machinery, which already exists:

- `GET /api/groups` — the realm's REAL groups, live from Keycloak
  (admin client; already powers Permissions → Admin in the UI).
- `GET /api/roles` — realm roles (60s cache). Roles also grant
  profiles directly, so a role-only realm needs zero group work.
- `GET /api/apps/permissions/profiles` now returns `knownGroups`
  (the same live sources) beside the profile rows, so authoring
  picks from what exists — honest note when the admin client is
  unconfigured (`POLARI_KEYCLOAK_ADMIN_URL` + secret is the knob).

Your steps for later (~10 min, no realm changes required).
The live answer is already in hand — the realm's EXISTING groups
are: **Polari Administrators, Polari Developers, Polari Users,
Polari Viewers** (roles: polari-viewer / polari-user /
polari-developer / polari-admin; `knownGroups.source =
keycloak-admin-api (live)`):
1. Decide which EXISTING group/role holds each app's access —
   e.g. bind app-climate-viewer to `Polari Viewers` (or the
   polari-viewer role) and wax-print-shop-operator to
   `Polari Users`. Nothing needs creating unless you WANT
   finer-than-existing granularity someday.
2. On each template profile row (CRUDE PUT on
   /AppPermissionProfile, or the auth section): set
   `kc_groups_json` to the chosen EXISTING names and
   `published: true`. That is the whole binding.
   (If the JWT lacks a `groups` claim, either rely on roles —
   they grant too — or enable KC's group-membership mapper on the
   polari client; the resolver prefers the claim, states which
   source matched either way.)
3. Flip `POLARI_APP_PERMISSIONS=advisory` on the backend service
   (env knob — deliberately NOT flipped by the build): responses
   gain `X-Polari-Permission-Advisory: would-deny …` headers where
   enforcement WOULD refuse, refusing nothing. Watch, then decide
   on `enforce`.
4. Log in as a single-app test user at the MAIN URL — decision
   11a auto-routes them into their one app, clamped (needs mode ≠
   off). `GET /api/apps/permissions/my` with their token shows the
   resolved grants + evidence.
Deferred inside sep-7 (recorded in memory): 11b app-prefixed
routes + 11c sticky menu-less exit — say when you want them.

## 0z. sep-0..6 (eyeball pass; sep-6 = per-app GUI walk)

**sep-6 machine half DONE**: ALL 16 apps converted (16/16 store
options show "isle app"; rows + registrations live; 14 launcher
debs built to the session scratchpad `sep6-debs/` — rebuildable
anytime with `pol apps shell <app>`, so don't archive them).
Owed = YOUR GUI pass per app (the plan's sep-6 human half): for
each app you care about, either install its deb on a desktop or
open its clamped URL in a browser
(`/<startRoute>?shellApp=<name>` — e.g.
`/magnetics/motor?shellApp=app-magnetics`, already spot-proven
headlessly) and eyeball that the menu is the app's own and
nothing foreign leaks.

sep-5 addition: `curl -sk …/api/appstore/behaviors` lists the 3
exemplar edge behaviors; a scope=app shell declaring one shows it
via the `shell.capabilities` bridge message; a registration with
`brandColor` (e.g. set branding_json on a shell row, rebuild the
launcher) colors the desktop chrome bar. All shell-side visuals
need your GUI session.

sep-3/4 additions to the pass below: `/isle-store` should show the
"Polari app options" section (16 options, markers) + the two engine
tiles; `/engines/msci` and `/engines/cad` render the honest data
pages; `/app/app-business` shows the "engine data page" chip. To see
REAL metering numbers, bring an engines worker up
(docker-compose.msci-engines.yml) and run any DFT/FEM call — the
usage table fills from the first call.

## 0a. sep-0..2 (eyeball pass, ~10 min)

sep-1 (shell passes ?shellApp=) and sep-2 (one registration
generator; deb builder consumes it) are BUILT on `dev-sep-1` ×4
repos; sep-2's backend half is DEPLOYED (capabilities on the live
registration, seed rows converged). Owed on top of the sep-0 pass
below: launch a scope=app launcher deb end-to-end on a real desktop
(`shells/build-launcher-deb.sh --registration <(curl …/wax-print-
shop-shell/registration?download=1)` → install → window opens the
clamped app). The JavaFX window itself needs your GUI session.

## 0b. sep-0 single-app clamp (eyeball pass, ~5 min)

sep-0 is LIVE on staging (branch `dev-sep-1`, angular + rf-node
pointer). Machine-proven: 7 specs green, headless-browser acceptance
passed (chrome hidden, foreign route redirected). Owed = the human
eyeball in a real browser:

- `https://prf.192.168.0.210.nip.io/?shellApp=app-archipelago` —
  expect: NO Apps/Core switchers, NO "Polari core" side-nav block,
  "Mesh Archipelago" pill + its own menu only; deep links elsewhere
  (e.g. `/topology`) bounce to the app home. The lock is
  session-sticky; a fresh tab without the param is unclamped.
- ⚠ swarm note: the staging swarm now has 3 nodes and
  `polari-node_frontend`/`backend` have NO placement constraint —
  every `--force` update bounces off the other nodes (bind mount +
  local image only exist on the leader) before converging; no
  outage, just minutes of Rejected retries. The DESIGNED fix is the
  existing machinery, not a hand-edit: constraints render from
  topology rows (`POL_STACK_CONSTRAINTS` via stacks.yml /
  `pol allocate <instance> <machine>`, node labels
  `polari.machine=*` already exist) and land on the next
  `pol swarm deploy node`. Your call which machine row prf-a pins
  to.

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
open `/arch` — blocks, peers panel, and the full planner: pick one
of your drawn map shapes, run cheapest-coverage with the RANGE
SCENARIO select (your 8-nodes pushback fixed it — optimistic now
answers 1 node/$27.99 on a 2 km square, and every plan names its
binding constraint), try an antenna upgrade and watch directional
refuse the omni mesh, build a cohort list from your three kit
profiles (counts first, percentages derived), and in fixed-locations
tick the drone-bridge box — the seeded profile REFUSES until you
record the flight-rules confirmation, which is the system working.
A real KC-authed ADJUDICATION end-to-end is the one flow that needs
your login. Prices: SH-L1A $27.99 approximate; HaLow $134.97 (ALFA,
fetched); generic lora/ham/wifi rows are unpriced references on
purpose. Deploy note: the backend service's bind
mount `polari-rf-node/ca/root_ca.crt` had been cleaned away — 
restored as a copy of `ca/.step/certs/root_ca.crt` (public cert,
gitignored); if that cleanup was deliberate, the service spec is
the thing to change.
