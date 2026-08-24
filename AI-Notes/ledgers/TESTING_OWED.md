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
21. **dev-cnt-1 MERGED to dev on your go (2026-08-23; framework
    cda27f0, angular 9b7edb6, pointers pushed). Presentation
    upgrade BUILT on `dev-cnt-2` ×2 repos (your "JSON instead of
    real graphs" finding; framework f8edfdb, angular 0ed81f3,
    UNMERGED)**: (a) `cntfet-iv-chart` — real SVG line chart over
    stored I-V families (run picker, Id-Vg/Id-Vd, log/linear,
    crosshair tooltip, legend; palette validator PASS light+dark);
    (b) `api-json-panel` now renders nested payloads as readable
    tables/sections on EVERY module page — raw JSON demoted to a
    collapsed details block; (c) new GET /api/cntfet/results[/{n}]
    read-side; (d) IV result names carry a fidelity suffix (same-
    second collision fix). selftest 70/70; headless eyeball of
    /display/cntfet + /display/microchip both GREEN. YOUR PASS:
    browser eyeball (hover/toggles/dark mode), then merge gate.
    GOTCHA carried: DisplayDefinition seeds are insert-by-name —
    an EXISTING instance keeps the old cntfet-home layout until
    the row is CRUDE-PUT (done on the preview) or reseeded fresh.
20. **ret-7 COMPLETE both halves (your wifi-LXMF ask,
    2026-08-23)** — receive reticulum messages ON polari + send
    over wifi via LXMF: (a) backend half (framework `dev-ret-7`
    off dev-ret-1, 1feed77, 178/178): GET/POST
    /api/reticulum/messages (+ refusals, policy) proxying the
    sidecar with the refusal ladder intact; 🔑 the PIN-ISOLATION
    NOTE rides every response — 'normal' modern RNS >= 1.0
    clients (current Sideband/NomadNet) CANNOT link with our
    pinned MIT mesh; wifi LXMF works between OUR nodes (another
    polari sidecar / pre-1.0 client). (b) sidecar wifi bearer
    (rf-node `dev-ret-7`, c13c69f): AutoInterface added to the
    config template — zero-config LAN/wifi peering; ⚠ template
    seeds FIRST START ONLY, existing volumes need the block added
    to the live copy. YOUR LIVE PASS: two sidecars on the wifi
    (or pol-core + isle-core), announce, then POST a message
    through /api/reticulum/messages and watch it arrive in the
    other's store. A chat page (composer UI) is the remaining
    frontend nicety.
19. **LXMF + MQTT FOUNDATIONS BUILT (your greenlight,
    2026-08-23)** — own-stack only, no third-party gateway code
    referenced (your call: these are foundational). Also
    CORRECTED the record on your question: LoRa IS bridged —
    E220 SerialInterface path proven over real RF 2026-08-13/14
    (battery + remote control); only RNode-class hw support is
    absent, and pin-isolation makes ecosystem interop impossible
    anyway. (a) mqtt-1: NEW mqttbridge module (framework branch
    `dev-mqtt-1`, 69a827f, UNMERGED): brokers/bindings/ledger as
    rows, enabled=False defaults, explicit connect act, ingest
    with named+ledgered refusals, paho-mqtt==2.1.0 pinned under
    the EDL-1.0 edge; selftest 10/10. (b) ret-7 sidecar half
    (polari-rf-node branch `dev-ret-7`, efaed13, UNMERGED): LXMF
    store-and-forward on the isle identity — whitelist +
    rate-limit policy gate with refusal ledger, jsonl persistence,
    honest send refusals, /lxmf* endpoints + /status facts;
    selftest 10/10 (injected fake stack). REMAINING ret-7 half:
    backend /api/reticulum/messages proxy + STOMP notify + a chat
    page — rides the framework dev-ret-1 review queue. YOUR
    QUEUE: merge gates for dev-mqtt-1 + dev-ret-7 (+ dev-dl-1),
    then a live pass: mosquitto container against the bridge, and
    the two-dongle desk rig for an LXMF round trip.
18. **DOWNLOADS PAGE BUILT + OFFLINE PLAN STAKED (your
    clarified ask, 2026-08-23)** — dl-1: the PUBLIC /downloads
    page for the internet demo (polari-framework branch
    `dev-dl-1`, 4ca1dd9, UNMERGED — small review): server-rendered
    HTML, one current version headlined, staged debs as ordered
    download links, click-only install instructions (Downloads
    folder -> double-click -> Install, in order; distro deps come
    from the internet during install), traversal-safe serving,
    POLARI_DOWNLOADS_DIR staging knob, honest empty state.
    Selftest 6/6 + live HTTP proof. DEPLOY NOTE: stage
    .generated/debs into the downloads dir on the droplet.
    **dl-1b (2026-08-23 evening, e82f8c4 on dev-dl-1): the page
    now LOOKS like a product download page** — per-deb cards with
    plain-language names/blurbs + Download buttons, install-order
    ordinals, numbered step cards, light+dark, phone-responsive;
    still zero-JS; 6/6 unchanged; light+dark screenshots eyeballed
    with the real .generated/debs staged. NOTE: this box stages
    only 3 of 4 debs (polari-shell-core missing from
    .generated/debs) — the droplet staging step should build the
    full bundle first.
    **dl-3/4/5 PLAN RATIFIED 2026-08-24 ("sounds good as is") +
    your on-request refinement folded in** (debs generated when
    asked, deleted after delivery/TTL, prebuild = explicit knob;
    offline chunks generate piece-by-piece onto the medium —
    no pre-built pool): AI-Notes/plans/DOWNLOADS_PAGE_PLAN.md.
    **dl-3 BUILD SIDE DONE same day** (suite `dev-dl-1` 46ff661):
    polari-complete merged deb PROVEN (0.1.25_amd64, 53 MB, 440
    files, Provides/Conflicts members) + shell-core dist-fallback
    in the bundle script. Session CLEARED on your call —
    fresh-session entry point =
    **AI-Notes/handoffs/DOWNLOADS_NEXT_HANDOFF.md** (dl-3 page
    side → dl-4 on-request generator → dl-5 offline page; the
    dev-dyn-1 merge stays YOUR gate and unblocks dl-4 admit
    wiring). YOUR PASSES pending: real polari-complete install;
    dev-dl-1 review.
    dl-2: AI-Notes/plans/OFFLINE_INSTALL_PLAN.md — the
    internet-install vs offline-install flavor split; offline =
    version-matched piecewise bundle on DVD/USB (our debs + full
    dep closure as a file: apt repo + docker image tars + router
    VM artifacts + signed manifest), media probe in core-install
    with all-or-nothing version guard; mega-deb recommended
    AGAINST (reasons in plan). 4 OPEN DECISIONS for you in the
    plan: target distro pinning, DVD/USB-first vs CD chunking,
    signing anchor, whether app images ride the base medium.
17. **FINDING #9 FIXED + the download page LIVE (2026-08-23)** —
    your ask: test the page an average user hits for the debs.
    It DIDN'T EXIST: (a) core-install's 'publish | tail -2' ate
    the exit status so a failed publish looked green (why your
    isle had none); (b) the core can't reach its own agent and
    apt.isle was never hairpin-pinned; (c) https://apt.isle/ was
    a bare-nginx 403 wall; (d) non-root 'isle' commands died on a
    644-in-git watch.sh (exec bit is cosmetic — scripts run via
    bash — validator softened, bits fixed in git). ALL FIXED at
    source (Isle-Mesh 79a8de1, CLI 0.1.126 deployed): publish now
    generates a HUMAN landing page (join instructions with the CA
    fingerprint as the stated trust anchor, member apt route, the
    served debs) + pins the hairpin itself. VERIFIED live:
    https://apt.isle/ by name with SYSTEM trust -> 200, serving
    the current one-version-per-package set. YOUR EYEBALL: open
    https://apt.isle in a browser on isle-core (note: a browser
    with its OWN trust store, e.g. Firefox/NSS, may still warn —
    system-trust browsers won't; the page itself explains the CA).
    **FOLLOW-UP #10 RECORDED**: the app-deploy topology report
    never reached the catalog (hosts-reconcile had nothing to
    pin) AND the catalog holds DUPLICATE device aliases
    (dustin-etts-mesh-core vs isle-core — the same instance
    twice; your dedup rule applies to the topology reporter).
16. **REINSTALL-DEDUP RULE BUILT IN (your ask, 2026-08-23)** —
    "ensure duplication does not occur with re-installs", swept
    structurally at every layer we could name:
    (a) shell registry: same-id/same-URL re-merge REFRESHES in
    place (one entry, new fields live — this is what heals stale
    registrations); now PINNED by test; (b) trust store: identical
    CA arriving by several roads (caPem + both caFile paths)
    dedups by content hash — one entry per distinct CA; (c) deb
    output dir: the bundle build now PRUNES to one version per
    package (stale piles made every *_glob install ambiguous —
    bit us live); (d) the twin build tools: canonical copies live
    ONLY in polari-app-shell/shells; the bundle build AUTO-SYNCS
    them into the Isle-Mesh vendored set (which had silently
    drifted a whole feature generation — the launcher twin was
    pre-sep-2 with live on-isle callers), so divergent twins
    cannot exist; assets are layout-agnostic (SELF_DIR).
    app-shell 2377259, Isle-Mesh 60a01f3, suite dev 9182f5d +
    dev-nmp-1 ba83733, all pushed; isle-core loop rerun to prove
    sync+prune live. Also idempotent already-verified: trust.sh
    (cmp-before-copy), store postinst, dpkg desktop entries.
15. **GUI-TEST FINDING #8 FIXED AT SOURCE (2026-08-22)** — your
    install was flawless but the FIRST store open failed PKIX and
    needed 'open anyway' + trust-twice. Root causes: (a) the store
    deb bakes its config BEFORE the isle exists → tls.caPem empty
    (the CA is minted BY core-install); (b) CertTrustHandler
    cached NEGATIVE trust verdicts, so the pre-CA failure outlived
    the CA's arrival = the trust-twice bug. Fix: tls.caFile — the
    config now ships the canonical CA PATHS
    (/etc/isle-mesh/ca/isle-root.crt + system-trust copy) and the
    shell resolves them at every trust build (probe, CEF pinned
    handshake, enroll); only positive verdicts cache. app-shell
    2cf2534 + Isle-Mesh c6c55bd + suite dev 86d260c, ALL PUSHED;
    isle-core pulled + debs rebuilt/reinstalled. YOUR VERIFY:
    reopen the Isle App Store — it should land on https://polari.isle
    trusted, first try, zero clicks. (Bootstrap re-pull quirk also
    noted: stale local dev branches shadow origin/dev on repeat
    pulls — worked around with explicit ff; candidate fix later.)
14. **EVENING PASS DONE (your "1 should be okay" + take-next-task,
    2026-08-21)**: git pass EXECUTED — S5/F3 committed (60390d7),
    suite docs (51f5ac3), dausume/lctime MIRROR live (branches +
    tags; codeberg pull-ref rejection is normal), OpenVAF-1
    renamed → **dausume/OpenVAF-original**. NOTHING pushed from
    the suite repos. THEN **[VS2] extrinsics BUILT (e436ad7,
    67/67)**: Rc(Lc,d) transmission-line model HITS the paper's
    70 kΩ pin (71.4) — 🔑 and RESOLVES your recorded Rs tension:
    long FC10-style contacts ≈ 4.4 kΩ/terminal (0.7 G0
    compatible) vs 35 kΩ at Lc=12.9 nm — the tension was contact
    LENGTH, not physics (polarity gotcha caught live: the
    calibrated constants are Pd-on-p, barrier-free); additive
    SDT (exponential in Lg: 0.03 nA @15 → 281 nA @5 nm) + BTBT
    (exactly 0 below Vds=Eg) + VS_FULL profile with per-point
    decomposition ({action: iv, profile: VS_FULL}); OSDI twin
    stays thermionic (analytic recast is in the blocked manual —
    labeled). YOUR EYES: the Rs-tension resolution note, and
    whether to adopt Rc(Lc,d) as the contact default (currently a
    derived suggestion beside your 5.5 kΩ prior). Remaining
    rungs: F3 self-consistent Poisson (D13), CharLib executor
    wiring, OpenSTA install, S6 synthesis, parasitic-cap models.
13. **S5 + F3 + fork-pins BUILT (2026-08-21 day) — committed
    during the evening pass as 60390d7.**
    Working-tree manifest on polari-framework dev-cnt-1
    (selftests 61/61 incl. live S5 + F3 legs):
    modified: cnt_api.py, cnt_capability.py, selftest_cntfet.py,
    polariServer.py; new: cnt_characterization.py, cnt_kwant.py,
    kwant_worker.py (+ this ledger, plan, CNTFET_MODEL.md,
    memory).
    What landed: **(a) fork-pins created BEFORE your no-git
    instruction**: dausume/{kwant, NanoNet, CharLib, PySpice,
    CNFET-OCL, asap7, OpenVAF, OpenVAF-1} — OpenVAF-1 = the
    ORIGINAL pascalkuthe repo (auto-name; consider renaming);
    **(b) S5 first rung**: CellCharacterizationRun schema (D11/
    D16, ours above any executor) + own-loop INV characterization
    (3×3 grid monotone, 343 fs–1.84 ps, Liberty emitted, OpenSTA
    gate = recorded refusal, not installed); **(c) F3 Kwant
    kernel LIVE**: subprocess venv (~/tools/kwant-venv, numpy<2 —
    kwant 1.5 breaks on numpy 2), atomistic zigzag tube self-pins
    gap+valleys, {action: f3-oracle} spends F3 at the triangle's
    disagreement points → F3 lands BETWEEN F2 and F1 in
    subthreshold (tunneling real, smoothing over-predicts).
    **QUEUED GIT ACTIONS for your evening go**: commit the
    manifest above; lctime codeberg→GitHub mirror; optional
    OpenVAF-1 rename; push nothing until you say.
    Also queued: install OpenSTA (closes the D11 STA gate);
    [VS2] extrinsics = the remaining rung not started.
12. **S4c BUILT on your second "go" (a69650b)** — the D10 minimal
    cell set INV/NAND2/BUF/DFF is fully DEMONSTRATED on the OSDI
    card: NAND2 truth table exact, BUF rail-to-rail, TG
    master-slave DFF captures on 4 consecutive edges + holds
    through mid-cycle D flips ({action: cells} = the battery).
    Two testbench catches armored: labeled 2 aF parasitic
    stand-in caps (S1 has no junction parasitics — [VS2] scope)
    + truncated-transient refusal. selftest 58/58. NEXT DECISION
    for you: S5 characterization (CharLib/lctime — needs
    dausume fork-pins created) vs F3 Kwant kernel vs [VS2]
    extrinsics.
11. **S3 + S4a + S4b BUILT on your "keep going" (fae36b5,
    1860c63)** — the chip arc now runs device→population→circuit:
    **(a) Monte Carlo variability**: six D7 process classes as
    distribution objects, `{action: montecarlo}` → 68.5%
    functional yield on the seeded target line, dominant
    limitation named (on/off-ratio via the Vt-σ prior — every
    unmeasured σ is a flagged TUNABLE prior for you to override);
    **(b) the complementary INVERTER works in ngspice** through
    the OSDI card (VM = VDD/2, gain −19.7, swing 99.996%);
    **(c) the 5-stage RING OSCILLATOR oscillates — 637 GHz / 157
    fs per stage, intrinsic-only** (labeled: no parasitics, 50/50
    charge partition because the Ward-Dutton derivation is in the
    license-blocked manual). Debug-queue adds: try {action:
    inverter}, {action: ring-oscillator}, {action: montecarlo}
    over live API; review the six process priors (they're YOUR
    knobs now); decide S4c (NAND2/DFF) vs S5 (CharLib/lctime
    characterization) vs F3 (Kwant) for the next go-ahead.
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
