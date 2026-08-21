# Testing owed — tracker (written 2026-08-13, for Dustin's pass later today)

## 0000. New 2026-08-21 — cnt S1 BUILT (aligned-CNT FET, first open CNFET compact model)

**S1 of the ratified CNT-FET plan landed in one session on branch
`dev-cnt-1` (polari-framework, cut from dev — INDEPENDENT of the
nmp review queue). selftest_cntfet 34/34 headless, including the
LIVE OpenVAF→OSDI→ngspice equivalence leg (220-pt grid, worst rel
err 4.2e-9). NOT merged — the usual review gate.**

What only you can do:
1. **Review + merge gate**: `git log dev..dev-cnt-1` in
   polari-framework (one commit, 90d0e92); on go-ahead: merge to
   dev + pointer commits (the unin-4 flow).
2. **Your CNT research paper** (plan §Process D-rule): when you
   supply it, its license gets bucketed, then its measurements
   digitize into CNTCalibrationAnchor rows — that's what replaces
   the vt0/efsd priors with calibration.
3. **Optional relay to ChatGPT**: S1 result summary (it endorsed
   the narrow target; the equivalence number + the 3 µm
   out-of-domain residual are the headlines).
4. **Live-API pass after a deploy**: /api/cntfet/capability,
   devices, and the acts derive | iv (vs|tob) | calibrate |
   validate | equivalence on the seeded `cnt-aligned-s1`.
5. **Named gaps carried honestly** (S2+ by design): curve-level
   digitization of the [FC10] Id-Vd families (the anchor row
   REFUSES until then), optical-phonon scattering in F2, BTBT/S-D
   tunneling ([VS2]), F3 Kwant kernel, G0-convention pin for the
   0.7 G0 anchor, vt0/efsd are uncalibrated priors.

**UPDATE same day (your day-time asks, commit 0cd1a73 on
dev-cnt-1):**
6. **Your two papers are IN as cited anchors** — both license-gated
   to the cite+link+values bucket (Fiori IEDM 2005 = '(c) IEEE';
   Hills 2019 Nature = Springer exclusive licence; the PDFs stay
   off-git in ~/Desktop/Research_Papers/). 14 anchor rows with
   full citations; verify the value extractions read true to you.
   NOTE: the Fiori paper is SIMULATED (ballistic NEGF) data — it
   became the literature NEGF-oracle edge, not experimental
   calibration; curve digitization for both = S2 (refusing rows).
7. **Citations surface**: GET /api/cntfet/citations — every source
   with DOI + which rows link to it; the 'unlinked' list is the
   honesty surface and ships empty.
8. **NEW microchip module** (your ask, separable from the device
   modules): design ladder device→cell→block→core→chip +
   traversal API (/api/microchip/levels|designs|nodes/{n}), seeded
   with our ladder (device rung LIVE, uppers honestly UNBUILT
   with plan pointers) + the RV16X-NANO precedent decomposed and
   cited per node.
9. **GUI BUILT on your go (2026-08-21)**: interactive
   `microchip-ladder` component (polari-platform-angular
   dev-cnt-1, 9133929; ng build green) + seeded pages
   **/display/microchip** (design picker, level rail, click-to-
   traverse with citations/artifacts) and **/display/cntfet**
   (devices, D8 parameters, D18 anchors, capability, citation
   linkage). Framework 1f7b7ab. YOUR PASS: browser eyeball of
   both pages after a deploy — headless proof only so far.
10. **S2 VALIDATION BUILT on your "continue" (a75c3e0)** — the
    headline for your review: **[VS1] Fig.7(a) was digitized
    programmatically (58 points, ±0.26 µA, overlay-verified) and
    the clean-room model reproduces the flagship Lg=15 nm curve
    at RMS 0.295 µA — AT the digitization noise floor.** Also:
    metric family (G0 pinned = 4e²/h from the paper), F1-vs-F2
    validation triangle + adaptive-oracle targets, curve/scalar
    residuals incl. two honest misses (subthreshold leakage
    floor −90%; G_on 0.35 vs 0.7 G0 = the recorded Rs-prior
    tension). Debug-queue additions for you: (a) sanity-check the
    digitization overlay story (method in cnt_digitized_fc10
    docstring), (b) {action: triangle} + {action: calibrate} over
    live API when a stack is up, (c) decide whether the Rs
    tension warrants splitting the contact prior (rc quantum half
    vs extrinsic half) at S3.

## 000. New 2026-08-20 — nmp-0..11 BUILT (the nutrition meal-planning arc)

**The whole arc landed in one autonomous day-session on branch
`dev-nmp-1` (polari-framework, 11 commits, NOT merged to dev — the
usual review gate; say "go ahead" to merge+push like unin-4).**
All 12 nutrition selftest suites green headlessly; what only you
can do:

1. **Review + merge gate**: `git log dev..dev-nmp-1` in
   polari-framework; on your go-ahead the branch merges to dev,
   plus pointer commits in polari-rf-node + the suite.
2. **GUI pass** (after a deploy): the 5 new pages —
   /display/nutrition/profile, /meals, /recipes, /activity,
   /garden — plus the nutrition-planner app tile in the store
   (`pol apps shell nutrition-planner` builds its deb).
3. **Q-decisions ratified by default, override freely**: Q1 wger
   mine-only (fork exists either way), Q3 hand-authored recipes
   first, Q4 12-week horizon + own-profile-only trajectories, Q5
   the proposed pattern fractions (seeded as tunable priors).
4. **Live-API pass**: the ~20 new /api/nutrition endpoints
   (envelope, thresholds, tolerance-check, meal-gl, recipe
   nutrition, template validate, plan rollup, timeline,
   trajectory, coverage, prep-schedule, tool-advisor, compose,
   counterbalance) — all selftested headless, none hit over HTTP
   yet.
5. **Your own profile data**: weight/height/goal/minutes-of-
   exercise (the felt-terms question), then the envelope +
   trajectory pages become real.
6. **Fork-pins created on GitHub 2026-08-20**: dausume/wger
   (AGPL-3.0), dausume/recipe-scrapers (MIT), dausume/
   ingredient-parser (MIT) — verify the roster; no requirements
   pins yet (nothing imports them until URL-import lands).
7. **Named gaps carried honestly** (not regressions): DRI child
   bands, added-sugar + fermenting-fiber gate caps (FDC lacks the
   columns), meat fat-rendering in the rollup, household serving-
   split rollups, the coverage ScoreConcept bridge, wger exercise
   DB vocabulary.


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
3. **Remote intermediary proof (credentials are yours)**: ai-5
   put the binding flow IN the store — open the claude or openai
   tile, type your API key into the password field, hit "Select,
   save key & validate" (per-step results show inline; the key is
   never echoed). Then talk to the assistant — the tile should
   flip to ready + active and /engines/reasoning starts metering.
   The flow's wire is live-proven (select+validate on built-in);
   the credentialed pass is yours.
4. **Local-hosted proof (when you want it)**: `isle app deploy
   localai --image localai/localai:latest --service localai
   --port 8080 --engine reasoning` on any isle host — the ai-3
   binder should auto-flip every instance's assistant to
   openai_compatible at its /v1. Binder is selftest-proven; the
   LIVE end-to-end needs a real LocalAI container (models cached
   first for air-gap). Image tag/variant is your call (fork pin
   dausume/LocalAI).

**ai-4 (voice sovereignty, same session):** /ai/voice is LIVE
(honest refusal on the null provider — probed), the assistant
panel now prefers provider-backed STT/TTS with the browser path
stated as cloud-backed, and two linkage apps seeded
(ai-assistant-reasoning, ai-voice). Yours:
5. **Voice proof rides item 3/4**: once a voice-capable provider
   is active (openai with your key, or a live LocalAI with
   whisper/tts backends), push-to-talk in the assistant should
   transcribe through /ai/voice — the mic tooltip states the path
   (sovereign / remote / browser). stt_model/tts_model/tts_voice
   are settings knobs on the provider if the defaults
   (whisper-1/tts-1/alloy) don't match your backends.
6. meetings-stt linkage app deliberately NOT seeded — waits for
   the collab transcription seam (unbuilt page = dishonest tile).

**ai-6 (hosting gauge, 2026-08-16):** the localai tile now answers
"Can this isle host it?" from the live resource inventory — and
today's honest answer is **NOT realistic** (pol-core/staging-a:
RAM busy, ~5.8 GB free disk < ~20 GB models need, 4 cores < GPU
profile). Yours:
7. Eyeball the verdict panel + cloud options on the localai tile;
   hover rows for the failing numbers.
8. econ-core / isle-core / lightweight are UNOBSERVED — run the
   resource refresh (`/api/topology/resources` observed-push or
   system_info_url) if you want them in the verdict; one of them
   may fit the minimal profile.
9. If you rent a cloud box: deploy the LocalAI container there,
   then the localai tile's "Connect a remotely-hosted instance"
   (base_url + optional key → Connect & validate) binds it —
   sovereignty badge says your-cloud honestly.

**ai-7 (dated-price hosting page, 2026-08-16):** `/ai-hosting` is
LIVE — 10 researched options (DO/Hetzner/RunPod/Vast/Linode), every
price wearing its as-of date (>90 days flags ⚠ stale), source
links, derived fit chips. Monthly reality: minimal-profile CPU
hosting ≈ €6.80 (Hetzner EU) to $48 (DO/Linode); always-on GPU
≈ $85 (Vast 3090) to $285 (4090s) — per-second billing makes
intermittent use far cheaper. CHECKED FACT: the LocalAI project
sells NO hosted instances (MIT self-hosted only) — renting + the
container is the remote path; managed endpoints are intermediaries
(per-token). Yours:
10. Eyeball /ai-hosting; prices are 2026-08-16 — when you re-check
    one, bump its price_as_of (CRUDE edit on RemoteHostingOption).

**ai-8 (computerparts + buy-vs-rent, 2026-08-16):** the dedicated
parts module is LIVE (12 dated parts, 3 example builds, derived
totals, assembly checks) and /ai-hosting now leads with the
advisory: rent hourly for sparing use (with the DO destroy-after-
session warning) vs buy past break-even. Live numbers: builds pay
for themselves in ~2.3-4.8 months vs the DO RTX-4000-Ada droplet;
5-11 months vs the cheapest 4090 rental. Yours:
11. Eyeball the buy section (fit chips, assembly chip hover, parts
    lists); GPU street prices move fast — bump price_as_of when
    you re-check (CRUDE on ComputerPartDefinition).
12. Assembly checks answer only DECLARED specs (socket/ram-type/
    psu answer today; gpu-clearance honestly unverified until
    lengths are declared). Performance-BETWEEN-parts is
    deliberately unmodeled — needs measured benchmarks as rows;
    your call whether that becomes its own module when it lands.

**ai-9 (fork-pin ledger, 2026-08-16):** /ai-hosting now carries
the pinned-forks table — all 15 keeper forks VERIFIED live on
github.com/dausume (2026-08-16), the 3 forked-in-error rows shown
as delete-pending, and llama.cpp/whisper.cpp shown as NAMED
not-pinned gaps (they ride the LocalAI fork's backend mechanism).
Yours:
13. The 3 deletes still need `gh auth refresh -s delete_repo` or
    the GitHub UI (magpie-tts.cpp / vibevoice.cpp /
    face-detect.cpp).
14. Decide the llama.cpp/whisper.cpp question: is the LocalAI
    fork's own pinning of its backends sufficient, or do we want
    dausume/ pins of the inference cores too (belt-and-braces
    against upstream relicensing)?

Deploy note: both swarm rolls (backend + frontend) bounced off the
two other nodes before landing home (the known --force bounce;
`pol allocate` pin still your call). Reticulum stayed admitted.
ai-4's linkages_json change to the openai/localai rows needed the
CRUDE-PUT backfill on prf-a (composition off — 12th-strike rule
followed: PUT ×2, re-GET verified).

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
