# Testing owed — tracker (written 2026-08-13, for Dustin's pass later today)

## 000. New 2026-08-25 — chip-1 (D13 Poisson) ∥ cmp-c (computers app) — ✅ COMMITTED+MERGED to local dev 2026-08-26 (his go; NOT pushed)

**2026-08-26 ADDENDUM (session 2, live-deployed via docker cp +
restart into the running prf stack): (a) NAV APPS — both arcs
were unreachable by browsing (pages seeded, NO PolariAppDefinition
rows); fixed with module-LOCAL app rows: computers/computers_app.py
(`app-computer-assembly`) + cntfet/cnt_app.py (`app-microchips`),
polariServer seed passes; 14 apps LIVE-VERIFIED. (b) cmp-c-6
INTERCONNECTS AS DATA on his directive: InterconnectDefinition
vocabulary (17 rows), ports_provided/required declarations,
viable_links/interconnect_matrix/port_budget_gates joined into the
gate report, comms + usb-expansion PART_KINDS + taxonomy + 3
UNPRICED example parts, /api/computers/interconnects{,/build/x},
page row 3. computers selftest 22→30 (host AND in-container),
computerparts 14/14 green. (c) cmp-c-7 visual workbench PLANNED
(plan §8, D3 reuse survey done — no new graph engine). OWED: the
computers-home DisplayDefinition CRUDE PUT was applied live
(insert-by-name gotcha) — verify row 3 renders in the browser
pass; polariServer.py now carries both arcs' app-seed passes
(flag at the commit split).**

**Two parallel arcs built in one session, working tree only (your
no-git-during-work rule) — the file sets are DISJOINT and split
cleanly at commit time: `modules/cntfet/*` + the CNT plan doc →
`dev-chip-1`; `modules/computerparts/` (ported from dev-ai-1) +
`modules/computers/` + polariServer/module_loading/registry edits
→ `dev-cmpc-1`. selftests: cntfet 72/72, computers 22/22,
computerparts 14/14, lazy-imports 15/15 — all HEADLESS; no
live-boot proof (no containers up post-purge).**

What only you can do:
1. **Evening git pass**: create `dev-chip-1` + `dev-cmpc-1` off
   dev and commit the two file sets (git status is clean-split;
   the session handoff lists the exact paths).
2. **🔑 REVIEW THE F3 BUG FIX**: the S5-era eq.(5) barrier had
   a1/a2 SWAPPED (mirrored ramp + ~Vd steps at the gate edges) —
   caught by the new discrete-vs-analytic pin, fixed in
   kwant_worker.py. Merged-dev F3 numbers (5.6×/3.8× subthreshold,
   40% on-state) were computed on the mirrored barrier; the
   corrected fixed-mode numbers shift. Decide whether the plan's
   S5 report needs a correction note beyond the one added.
3. **cmp-c decisions 1–4 ratification**: the build proceeded on
   the plan's recommendations (new `computers` module; 4+1
   profiles; DB-binding declare-only; chip-4 seam deferred) —
   override any and the seeds/rows converge via upsert.
4. **Xeon build honesty check**: the DB-bound profile fit
   honestly REFUSES your owned build (2 TB seed SSD < 4 TB
   floor) — confirm the 4 TB floor is what you want, or edit the
   profile row.
5. **Live pass after next deploy**: /api/computers (catalog +
   fit matrix), /api/computers/assembly/assembly-xeon-6338n,
   /display/computers page; cntfet {action: f3-oracle, scf: true}
   (~4 min for 2 points at default knobs).

**SAME-DAY CONTINUATION (your day directives, autonomous):**
6. **Figure replicas built** (your "graphs similar to the cited
   studies" ask): /api/cntfet/figures registry — vs1-fig7a full
   replica (digitized points + error bars + model on the paper
   axes, flagship RMS 0.295 µA at the noise floor), vxo-vs-Lg
   (3 µm misfit PLOTTED), Fig.9 model-only, Fiori/FC10-original
   refusing entries; page row added. Frontend SVG overlay = a
   small extension of dev-cnt-2's cntfet-iv-chart at its merge.
7. **Cell stage: cell-1 BUILT** — cnt_cell_library.py (cells as
   data, generated x1/x2 variants, NOR2 added, multi-cell
   Liberty via characterize_cells, actions characterize-cells +
   d11-crosscheck, CNTCellDefinition rows). **OpenSTA is LIVE
   via docker** (openroad/opensta v3.1.0 behind ~/.local/bin/sta
   — no sudo build) and the **MANDATORY D11 SPICE-vs-STA
   composed-path box now runs for real**. Your call: keep the
   docker wrapper or native-build later (plan §6.3).
8. **Cleanup + probes + distribution plan**: pol-core disk
   96%→62% (docker cache+images pruned; volumes + purge backup
   untouched); isle-core/econ-core probed; the dist/cell/chip-4
   plan = AI-Notes/plans/CHIP_COMPUTE_DISTRIBUTION_PLAN.md with
   4 decisions for you (§6).

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
    wiring).
    **dl-3 PAGE SIDE + dl-4 + dl-5 BUILT 2026-08-24 (autonomous
    session on your go)** — framework `dev-dl-1` d2aef34/62cb902/
    0fc6b38 + Isle-Mesh `dev-dl-1` bfd0c5b, ALL UNMERGED:
    (a) dl-3 page: polari-complete staged → "Option A — one file
    installs everything" hero (pre-prepped provenance: built date,
    version source, instant) vs demoted "Option B — piece by
    piece" with the can't-coexist note; no-combined fallback =
    dl-1b layout; NEW appstore/downloads_shared.py = shared page
    shell + transparency components (what-is-this <details>
    explainers, prepped/on-demand provenance lines) reused by all
    three surfaces. Selftest 6→16.
    (b) dl-4: appstore/app_deb_builder.py — pure-python deb
    writer (ar+tar.gz, REAL dpkg-deb -I/-c accepts the output),
    payload → /var/lib/polari/apps/<module>/ + honest
    manifest.json naming the dyn admit gap; content-hash version
    = cache key inside POLARI_APP_DEB_TTL (default 1 h, 0 =
    delete-after-delivery); shared-payload factoring into
    polari-app-shared-* debs (symlinks + pinned Depends, ≥4 KB
    floor); named refusals (unknown/not-downloaded/deb-name
    collision both sides); DebGenerationRecord JSONL ledger →
    median "usually ~Ns" estimates, honest "never generated yet";
    POLARI_APP_DEB_PREBUILD knob. /downloads/apps lists the
    REGISTRY (ghost modules render named-unavailable), steps
    named BEFORE the click, zero JS. Selftest 19/19. isle CLI:
    `isle apps build-debs` thin verb (locates checkout or
    backend container; proven end-to-end on real gears deb).
    (c) dl-5: appstore/offline_page.py — /downloads/offline
    renders staged chunks.json sets (documented contract) with
    per-disk lists + write-the-media steps, or the honest
    not-built-yet page; manifest-is-the-truth serving, streamed;
    open signing decision stated honestly. Selftest 6/6.
    /downloads footer now LINKS offline + apps pages. All four
    appstore selftests green (16+19+6+36).
    **off-1 MACHINERY BUILT same day (second pass)** — framework
    24b54eb (offline_chunker: deterministic FFD packing, named
    refusals, piece-by-piece emit, chunks.json = the exact
    offline_page contract; 10/10) + suite 43e1c0a
    (build-offline-bundle.sh: pristine-container closure
    resolution, honest SKELETON mode without --download, per-disk
    self-identifying ISOs). Proven here: 101-deb closure, 2-chunk
    ISO set from the real debs, sums OK, page renders it.
    YOUR PASSES pending: real polari-complete install (test box);
    one real app-deb install (e.g. gears) + eyeball
    /var/lib/polari/apps/; browser pass of the three pages;
    dev-dl-1 review ×3 repos (framework + Isle-Mesh + suite);
    dev-dyn-1 merge decision (then dl-4 admit wiring session);
    offline decisions 3+4, then --download bundle on a roomy box.
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

- `https://prf.<pol-core LAN address>.nip.io/?shellApp=app-archipelago` —
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

## 5. Calendar + events arc (cal-1..5, built 2026-09-02, branch dev-cal-1)

Plan: `AI-Notes/plans/CALENDAR_EVENTS_PLAN.md`. Every phase ships a
check()-style selftest that runs WITHOUT a server (fake manager, REAL
engine):

- `polariNoCode.selftest_recurrence` 16/16 — the `schedule` type
  expands (weekly / 1-3-6-12-month / yearly / bySetPos / once+duration
  / datetime spans / excludes / plain refusals).
- `polariNoCode.selftest_calendar_events` 12/12 — every
  EventDefinition reading (span, start, relative start + slot prior,
  time join, duration, all-day, recurrence, filters), honest
  unresolved counts, CalendarDefinition layer merge.
- `polariNoCode.selftest_event_triggers` 15/15 — object trigger →
  solution → GenerateEvent (dedupe), emitted-event chaining + depth
  guard, schedule trigger idempotency, disabled/cooldown refusals,
  Modify/Cancel/ScheduleOccurrences/EventWindowQuery, missing-solution
  failure row.
- `nutrition.selftest_purchase` 19/19 — his sample: weekly purchase
  proposal (bulk-covered lines removed), bulk proposals on all four
  cadences (demand vs stock, bulk vs retail $/kg, savings only where
  retail is observed, shelf life REFUSING a too-long cadence by name),
  week coordination (purchase Saturday-before → pre-prep → meals →
  15-min meal-prep; rules named), the seeded no-code solutions fired
  by the seeded triggers through the real engine, the mealplan-week
  calendar merging it all.
- `nutrition.selftest_mealplan_pages` 7/7 — pages use only
  embeddedTable / embeddedGraph / embeddedCalendar /
  api-structured-panel; every embed names a seeded definition; table
  columns exist on their classes; boot repoint resolves every embed.
- Regression kept green: turing 16/16, composition 12/12,
  display_flow 13/13, parity (Python) 69/69, graph_builder 14/14.

OWED (his gates):
- TS-engine parity vectors for the new node family are NOT written —
  the six nodes (GenerateEvent, ModifyEvent, CancelEvent,
  ScheduleOccurrences, EventWindowQuery, AnalysisCall) are declared
  BACKEND-ONLY in all three registries (StateBuildingBlock.py,
  capability.ts, state-space-class-registry.ts) per the standing rule;
  no frontend palette metadata yet (they run, they are not yet
  draggable in the editor) — cal-3 remainder.
- Events / Calendars tabs on the class page + the `schedule` editor
  cell — cal-3 remainder (definitions are editable through CRUDE
  today).
- A real-browser pass of the front door (drag → confirm → CRUDE PUT,
  click → CRUD dialog) — headless verifies render + console only.
- FoodKeeper shelf lives are TRANSCRIBED priors (confidence
  'transcribed') — verify against the app before quoting.
- Slot-time / purchase-time / pre-prep-time / meal-prep-minutes are
  labeled priors on the definition and the analysis; no household
  override row yet.

## 6. Meal logistics arc (mlg-1..5, built 2026-09-02, branch dev-mlg-1 off dev-cal-1)

Plan: `AI-Notes/plans/MEAL_LOGISTICS_PLAN.md` (D2/D4/D9/D13–D16 ratified
by him; D1/D3/D5–D8/D10–D12 at the recommended defaults).

- `nutrition.selftest_logistics` 26/26 — schedules expand (sleep
  across midnight), where-is, timing check (his 120-min default per
  person; an early bedtime FLAGS with a latest-start move, never
  blocks), skill profiles (experienced ×0.8 vs novice ×1.3), SAFETY
  bounding speed (floor wins, named), safety rules (alone /
  supervised with reasons), refinement (median of 3; below-floor
  observations = a safety question, factor stays at 0.7), prep-vs-
  eating profile, portability (pack at leave − pack − 10 min, cold
  packs frozen the night before, missing tools named), dishes
  (unattended windows first; after eating + cooldown), the
  allocation (shares within tolerance, both allocations, purchase vs
  delivery comparison, assignees on events, eating is not work),
  fairness (drift + suggestion), a PersonSchedule change re-
  coordinating through the no-code trigger (inputs win over the
  payload), background schedule layer on the calendar.
- Kept green: purchase 19/19, pages 7/7 (now 6 pages), workflow,
  pantry, turing 16/16, composition 12/12, display_flow 13/13,
  parity 69/69, graph_builder 14/14, recurrence 16/16,
  calendar_events 12/12, event_triggers 15/15.

OWED (his gates):
- Real-browser pass of /display/mealplan/household and the front
  door's background schedule layer (headless verifies render only).
- The IntakeRecord / event CRUD dialogs do not yet ASK "how long did
  it take" — DurationObservation rows are CRUDE-entered today.
- WorkLedger rows are not yet written automatically from events
  marked done (a trigger on CalendarEvent status → done is the
  natural next step; the fairness readout reads whatever is there).
- The allocation is greedy (fastest safe person under target, in
  timeline order), not a global optimum; the pure-minimum column
  makes the gap visible.
- Cited priors to verify: ACG/NIDDK ~3 h (shown beside his 2 h
  default), FSIS bag-lunch 2-hour rule, kitchen-safety rules
  (transcribed), eating-time priors (household numbers, no
  literature).

## 7. Week planning (mpc — meals per person → entries, coverage, portions; 2026-09-02)

- `nutrition.selftest_planning` 14/14 — expected slots (pattern /
  3-meal default labeled), the coverage grid (2 × 3 × 3 = 18; 10
  planned; 8 missing NAMED; headline), portion fit (ideal scales per
  person from THEIR targets; the small demo dinner clamps both to the
  variation max → the compromise STATED with a suggestion; key
  nutrients vs slot share), apply-meal (slots × days; already-planned
  named; template-slot mismatch = warning; unknown meal / out-of-range
  day refuse plainly; one person + fixed scale), the seeded FORM
  solution through the real engine (FormSubscription → AnalysisCall →
  GenerateEvent MealEntry → refreshDisplay) writing 3 lunch entries,
  coverage rising to 16/18, idempotent re-run, the entry trigger
  firing. Pages 7/7 (8 pages; forms link seeded solutions).
- Live: coverage 10/18 on the demo plan; portion-fit shows both
  clamped (452 kcal vs ~900–1000 kcal slot targets) with 2 named
  compromises; apply preview 3 lunches; /display/mealplan/meals?
  object=demo-alex and /display/mealplan/week render their forms +
  tables with no JSON, `{object}` resolved, 0 console errors.

OWED (his gates):
- A real-browser SUBMISSION of "Add to the week" (headless verifies
  the form renders and the same solution runs through the execution
  API; the button click itself is untested in a browser).
- Portion fit reads calories only for the scale; nutrients are
  REPORTED, not optimised (a second objective — protein-per-portion —
  is the natural next knob).
- Replacing an already-planned entry from the form is refused by
  design (edit/delete in the entries table); a "replace" mode would
  need ModifyEvent per cell.
- The meal ranking on the meals page is the mpb ratings rank; it does
  not yet fold in exclusions/conditions (planned composer work).

## 8. Tracking over time (mpt) + Food Supply map (mps) — 2026-09-02

- `nutrition.selftest_tracking_periods` 15/15 — week/month buckets,
  means per logged day, verdicts vs the person's lines, low-confidence
  named, consistency (3 salty weeks → "consistently too much"), duck
  manager skips the cache and says so, the log forms' proposals
  (every problem named) and their solutions through the real engine
  (dedupe by name), the new log appearing in the week means.
- Pages 7/7 (ten pages; embeddedMap allowed).
- Live: periods route writes 4 PeriodIntakeMetric rows; the me page
  renders 13 embedded graphs (day / week / month), 2 forms, 3 tables,
  0 console errors.

OWED: a real-browser submission of the log forms; the map page's
Create New should geocode an address (geocoder service exists);
the period charts show two points on the demo — more logged days
make the views meaningful; ~~sugars need a nutrient column before
"sweets" can be read directly~~ — LANDED 2026-09-03 (N6): `sugars-total`
(FDC 269/269.3, values from the same bulk CSVs, 4 API-cross-checked)
cited for **24 of 49** pantry foods (25 honest absences, named in
vendor/README.md); each period bucket's `sweets.basis` says
`sugars-total` or `gl+carbohydrate`; the sugars line is a DERIVED
DGA-share ceiling labelled conservative, never a target
(`selftest_tracking_periods` 23/23, `selftest_data` +8 checks).

## 9. Module-pages no-JSON sweep + household extraction (hh-1) + frontend follow-ups — 2026-09-02

- Sweep (agent): 30 `api-json-panel` items → `api-structured-panel`
  across module_pages_seed (nutrition / vermicompost / tanks /
  biomining / microalgae / wax / supply-chain / morphology / zones),
  climate (10→14), computers (5→6), cntfet home/blocks/characteristics
  (+ the `_api` view descriptors), sifet (4→6). Cross-seed check: 50
  pages, 191 structured panels, 0 json panels, rows sum to 12, ids
  unique. Selftests: sifet pages 21/21, cntfet 131/131, blocks 32/32,
  computers 30/30, climate 237/237. Dead path found:
  `/persons/demo-alex/needs` is POST-only (the old panel was dead) →
  repointed to `/thresholds?period=day`.
- Live backfill `polari-cli/shells/backfill-module-pages.sh`: 48
  pages converged (PUT+diff), co2-health/co2-eras missing on prf-a
  (seed on their node's boot). Headless on the live routes (nutrition,
  nutrition/profile, nutrition/recipes, cntfet, sifet, vermicompost,
  plant-morphology, cntfet-score-cnt-aligned-s1): pre=0 unrendered=0
  json=0, tables render. The last four pages (app-store-home,
  isle-mesh-home, open-library, fet-detail) are a second agent's pass —
  see the handoff for its result.
- hh-1: `household.selftest_household` 27/27; nutrition suites
  unchanged (logistics / planning / purchase / tracking_periods /
  mealplan_pages); polariNoCode recurrence 16/16, calendar_events
  12/12, event_triggers 15/15. Pre-existing: lazy_imports 14/15
  (cntfet stub tuples, fv arc — not this round).
- Frontend (agent, tsc clean): CRUD dialog "Find coordinates from
  address" (any class with latitude+longitude+address/display_name;
  fills region_label when the geocoder returns a region; errors
  inline); fet-characteristic explorer honours the descriptor's
  componentName/pick/hideKeys (api-structured-panel by default).

OWED: a real-browser click of the geocode button on
/display/mealplan/supply Create New (headless can only prove the DOM);
the cntfet stub-tuple drift (14 guard blocks) so lazy_imports goes
15/15; `pol modules publish household`; the household page redirect
(hh-4); sugars column before "sweets" reads directly.

## 10. Meal options export path (mo-3, 2026-09-03) — the privacy line, proven on the reverse of seed

- Built: `json_seeds.export_rows` (+ `out_dir`, hook discovery via
  `modules/<pkg>/export_hook.py`: include_classes / include_prior_classes /
  strip_fields / filter_row), `POST /modules/export {"moduleId","classes"?}`,
  `pol modules export <module> [--api <base>]`, `mealoptions/export_hook.py`
  + `seedData.py` + `initialData/README.md`.
- `mealoptions.selftest_privacy` 51/51 proves: a fake manager's is_prior=False
  MealTemplate/Recipe/BulkStaple + PriceReference (kept regardless of is_prior)
  export to a temp dir with NO stripped field name (household/person/location/
  bulk_location/observed_date/lat/lon/address/purchaser ∪ PriceReference's
  PRIVACY_STRIPPED_FIELDS) as a key in any written file; the prior template is
  excluded; a template carrying household_name='x' is DROPPED and reported;
  BulkStaple's trio is blanked then stripped; months match ^\d{4}-\d{2}$; and
  statically no MEALOPTIONS class (nor PriceReference) declares a stripped
  field beyond BulkStaple's declared trio. `moduleService.selftest_json_seeds`
  21/21 = export→apply round trip on a temp package (customized rows never
  clobbered, stale exporter file removed, refusal without hook/class list).
  Re-run: mealoptions 16-class suite passes, lazy_imports 15/15.

OWED: `pol modules export mealoptions` against a RUNNING backend (the handler
was exercised bare, not through falcon), then `pol modules publish mealoptions`
— needs the GitHub repo (`gh repo create polari-module-mealoptions --public`,
`--repo` the first time) and is his push ritual (push-all-dev re-publishes the
subtree). A real user-authored row on prf-a before the first export so the
files are not empty.

## 11. Night run 2026-09-03 (unattended; his "finish the meal planning stuff through the night")

- mealoptions: selftest_mealoptions (17 pairs), selftest_price_reference
  33/33, selftest_privacy 51/51, moduleService.selftest_json_seeds 21/21,
  nutrition.selftest_market 28/28, lazy_imports 15/15, lazy_boot 34/34.
- Pages: selftest_today 32, selftest_shoptrip 36, selftest_cooknow 37,
  selftest_weekreview 34, selftest_planning 29, selftest_tracking_periods
  27 (sugars basis), selftest_data 38, tracking 18, acidity 14; pages 7/7;
  polariapps 45/45.
- Live (second deploy 05:49, after the seed-pair crash fix): all four
  pages render (pre=0 unrendered=0 json=0), nav carries them, geocoder
  prior seeded, SourceLocation demo rows typed, /prices/publish wrote 7
  references, /modules/export stripped 9 private fields, sweets basis =
  sugars-total on the logged week. Real-browser (CDP) pass of the forms
  before the fixes: add-to-week creates rows, log intake/weight write
  rows + charts refetch, calendar views + event dialog work.

OWED: the post-fix browser check of the feedback line (see the night
ledger's last row); N7 guests & situations (not started); `pol modules
publish mealoptions` (GitHub repo — his push ritual); real-store aisle
rows; per-store `StoreAisleOrder` from real shops; a phone-width pass of
the shopping trip page; the backend RSS still climbs ~170 MB across a
page sweep and does not come back (cap now 1536M).

## 12. VPN arc vpn-1 — Polari half (2026-09-03 afternoon, branch dev-vpn-1; his "I approve of the plan", then away for hours)

- Headless: `vpn.selftest_vpn` 75/75 (vocabulary/labels, ledger
  allocation, Link rendering mesh N−1 / hub member 1 / hub all, exit
  masquerade ONLY with knob + exit kind, Bridge Peer subnet in AllowedIPs,
  federation routes active-only, nftables text, Bridge refusals until
  step-ca, proposal validation incl. key-material refusal, the two-isle
  demo, seed shapes); `islemesh.selftest_islemesh` 69/69 (INGEST_KINDS +
  matrix `.vpn` column); `moduleService.selftest_lazy_imports` 15/15,
  `selftest_module_registry` 10/10 (`selftest_module_dependencies` 13/14 =
  pre-existing waxprint/xr boundary miss, same on clean dev).
- Live on prf-a (image rebuilt 13:35, node stack rolled by
  `enable-vpn-prf-a.sh`; boot took ~30 min — the CRUDE-registration cycle
  ran 61 times at ~16 s each before the seed phase; health 200 at 14:06):
  `/api/vpn/kinds` 10 kinds with the right labels; catalog carries the ten
  `isle-vpn` listings, six with `provides_engine vpn-gateway`;
  `POST /api/vpn/demo` 23/23 (two Link Gateways mirrored; `.vpn` option on
  isle-a, ABSENT on isle-c the Link Node; federation proposal filed
  without touching the mirror; anonymous apply refused; operator apply
  flips it and the link row goes ACTIVE; render carries the remote
  gateway + its subnets with the private-key placeholder only; revoke →
  peer gone in one push + render drops it; a push with `private_key` and
  a proposal with `preshared_key` refused whole); `/api/vpn/matrix` +
  `/exposure-options` agree; `/api/islemesh/matrix` shows `whoami.vpn`
  with its label; CRUDE export of all six classes: zero key-material
  hits; `POST /modules/export {"moduleId":"vpn"}` exports 0 rows (mirror
  + inbox rows are never user-authored seeds). VpnNocodeSeed created the
  analysis + six solutions on first boot.
- Real browser (headless Chrome over CDP, `scratchpad/cdp_vpn.js`,
  17/17 at 14:09): `/display/vpn` renders as 4 structured panels + 6
  class tables + 5 forms, pre=0 unrendered=0 api-json-panel=0, mock
  banner + kinds + Blind/Sees-traffic + the demo rows visible; form
  "Propose a network" with a duplicate name → "Refused: network
  'arch-demo' already exists on this isle — propose a peer or a rule
  instead" on the form, proposal count unchanged; a new name → "Proposed
  network browser-… (vpn-link-gateway, mesh, 10.60.4.0/24, port 51821)
  for isle-a. Apply on the isle with `isle vpn apply vp-…`", a
  VpnProposal row filed (cidr + port allocated, applied_by empty) and NO
  VpnNetwork row; the `.vpn` exposure form on isle-c → "Refused: the .vpn
  rung is not available on this isle — no gateway-kind VPN app…";
  `/display/isle-mesh` matrix shows `whoami.vpn`. Zero console errors.
  FOUND on the first run only: the two summary panels reported "Http
  failure … 0 Unknown Error" seconds after boot (transient — CORS headers
  verified by curl, second run clean).
- OWED: the ISLE half I-1..I-5 (isle-core; contract in
  `Isle-Mesh/NOTES-FROM-POL-CORE.md`); a REAL push from isle-core through
  `push-to-polari.sh` replacing the mock rows; the boolean form knobs
  (forward/masquerade) were not exercised by the browser pass; `pol vpn`
  verbs were syntax-checked and `help` run, the read verbs only exercised
  through the API they wrap; `pol modules selftest vpn` in-container (host
  run only); `pol modules publish vpn` (repo '' in the registry — his
  ritual). The demo left mock-flagged rows (isle-a/b/c) and one
  `browser-*` proposal on prf-a — the banner says so; a real push for
  those device names replaces them.

## 13. VPN arc vpn-3 — the trust bridge (2026-09-03 afternoon, branch dev-vpn-3 off dev-vpn-1)

- Headless: `vpn.selftest_vpn` 89/89 (section 8: join request →
  PeerAgreement pending + proposal awaiting-consent; idempotent re-ask;
  a request failing VPN validation makes NO agreement; approve → proposed
  with the mirror untouched; isle push → applied; revoke → exactly ONE
  tear-down proposal, proposed, and a repeated revoke files nothing;
  federation request → vpn-federation; deny → rejected; non-vpn
  agreements ignored; listener registered ONCE across repeated endpoint
  constructions); `polariPeers.selftest_agreements` 23/23, `selftest_peers`
  15/15, islemesh 69/69, lazy_imports 15/15.
- Live on prf-a (three rolls; each boot ~30 min): runbook step 8 —
  `POST /api/vpn/join-request` → awaiting-consent + agreement; approve via
  `/api/peers/agreements/{id}/approve` → the proposal is `proposed`
  (note: "consent: agreement … approved by runbook"); the isle push with
  `applied_by` → applied; revoke → ONE `revoke` proposal `proposed` for the
  peer; `/api/vpn/agreements` lists both runbook agreements revoked.
  Demo 23/23 again (now tolerant of DB-restored rows), matrix / options /
  isle-mesh column / key-material sweep all as in §12.
- Real browser (CDP) 17/17 on the final deploy: `/display/vpn` now 5
  structured panels + 7 class tables (the PeerAgreement table + the
  agreements panel) + 5 forms; refusal / success / rung-refusal messages
  as in §12; `/display/isle-mesh` `.vpn` column.
- FOUND LIVE and fixed in the same session: (1) the listener was a bound
  method per VpnAPI instance and polariServer constructs its endpoints on
  every boot cycle → 61 listeners → 61 tear-down proposals, all then
  self-rejected by the revoke event (first run); now a module-level
  function registered once + the revoke event skips `revoke` kinds +
  one tear-down per target (idempotent). (2) the new page row did not
  land: DisplayDefinition rides the insert-by-name seed pass — `vpn-home`
  now upserts through composition (log: `"vpn-home" updated: definition`).
  (3) the live demo counted a DB-restored isle-c row (fixed: isle-a/b
  only). The first run's 61 rejected `revoke` rows for agreement
  e0fb1ca3… are still in the VpnProposal table (mock-flagged, harmless —
  delete with CRUDE if they bother the page).
- OWED: the requester-side flow (another instance's `join_flow` posting a
  VPN join request and fetching its conf from ITS isle); `.arch` over the
  tunnel (vpn-4, isle-heavy); DDNS + step-ca (vpn-6); the isle half
  I-1..I-5 unchanged. `pol vpn` verbs exercised LIVE at the end: status,
  agreements, proposals --status, options --device, matrix, peers
  --device, render --peer self all print (the first run of every list
  verb died: fmt_table's python rode a heredoc that replaced the JSON
  stdin — fixed to `python3 -c`); `join` only through its API.

## 14. Bring-to-dev 2026-09-04 — the August phase branches merged (his "check to ensure all should be merged … and make everything merge")

- Merged into `dev` (framework, via `dev-merge-1`): `dev-ai-1` (the
  stacked chain dyn-1..9 → mtg-0..8 → ret-0..3 → sep-0..7 → ai-0..9),
  `dev-ret-7`, `dev-lad-1` (⊃ fg-0..4), `dev-mqtt-1`, `dev-vpn-3`
  (⊃ vpn-1). NOT merged: `dev-cnt-2` (superseded — the bespoke I-V chart
  behind the 2026-08-25 chart rule; fet-viz serves the curves) and
  `dev-scan-1` (shelved, NC weights). polari-cli: `dev-vpn-3` merged.
  Angular: nothing (cnt-2's component dropped with cnt-2). New modules
  now on dev: collab, reticulum, mqttbridge, vpn (registry rows with
  `repo: ''` — `pol modules publish` is his ritual).
- The structural reconciliation: dyn-1 had turned polariServer's guarded
  import blocks + endpoint gates into data tables; dev had added ~30
  blocks and 17 gates since. Both tables were REGENERATED by AST from
  every side (feature_imports 67 entries incl. 'name as alias' — new
  replay support in module_loading; module_endpoints 40 constructors),
  every dev endpoint construction verified present, and the 30 derived
  seed computations that lived inside the blocks (cntfet score/cell/
  block pages + configs, scene rows, part shapes; sifet; foodstate)
  recovered into the new `polariApiServer/feature_derived.py`, run
  after the table replay and after live un-stubbing (values verified:
  SEED_CELL_CONFIGS 364, block configs 56, scene rows 28, part shapes
  35 + 72, food materials 49).
- Headless sweep of ALL 264 selftest suites on the merged tree: 251
  green; 6 exit-1 suites IDENTICAL on the dev baseline (module_
  dependencies boundary miss, topology 10→5 fails after the seed fix,
  food_materials, node_resources, aquaponics.system, move_operations);
  7 heavy suites exceed the 90–250 s limits with zero FAIL lines on
  both trees (cells2, casting, cntfet, testing, si_sequential (dev
  baseline could not even import it), logic (green at 104 s), blocks).
  Drift guard 23/23, polariapps 57/57 (union expectations: 8 use-case
  apps, 18 nav), vpn 89/89, server imports with zero missing modules.
- Live: the merged image booted in a one-off container in 40 s with
  polariapps, appstore, islemesh, vpn, collab, reticulum, mqttbridge,
  computerparts, techtree; `/api/vpn/kinds`, `/api/islemesh`,
  `/api/collab/capability`, `/api/reticulum/arch`, `/api/mqttbridge`,
  `/api/peers/agreements`, `/api/apps/nav` (app-archipelago present) all
  200; **`POST /modules/household/admit` admitted household live and
  `/HouseholdMember` answered 200** — dyn-2 works on the merged tree.
- Fixed on the way: topology selftest counts now derive from the seeds;
  isle-core's seed swarm_role was 'none' (stale — it has been a swarm
  worker since 08-26), econ-core stays 'none' as the negative case.
- OWED: the readiness gate's live half (CICD plan §3a: swarm redeploy of
  the merged image with the full prf-a module set + the CDP passes; the
  fresh isle-core deb install); `pol modules publish` for the four new
  modules; the 6 pre-existing failing suites (none from this merge);
  the still-uncommitted Isle-Mesh note; NOT pushed anywhere.

### 14b. Swarm re-proof of the merged tree (2026-09-04/05, his "you should be able to do the swarm testing yourself")
- prf-a now carries 24 modules (collab, reticulum, mqttbridge assigned
  too); the merged image booted in ~33 min; RSS 604 MiB at idle.
- Live: the vpn runbook (demo 23/23 + trust bridge) and the vpn CDP
  pass 17/17 green on the merged deploy; `/api/collab/capability`,
  `/api/reticulum/arch`, `/api/mqttbridge`, `/api/peers/agreements`,
  `/api/apps/nav` (19 apps, app-archipelago present), `/api/fet/devices`
  (14) all 200.
- FOUND + FIXED: dyn-1's `polariServer.endpointConstructed` was a
  Python set on the object CRUDE serves — every frontend
  `GET /polariServer` poll 500'd ("Object of type set is not JSON
  serializable"); now a list (d8595b2), image rebuilt + rolled.
- FOUND, NOT fixed (design): `POST /modules/gears/admit` on the FULL
  24-module prf-a re-ran the registration cycles at 140 % CPU, memory
  climbed 0.6 → 1.23 GiB against the 1.5 GiB cap and the task
  restarted ~7 min in (the dyn proofs ran on a small gated server).
  Live admission is a core-only-server feature (prd-3b) — do not admit
  on the full staging instance until the cap or the admission cost is
  addressed. The one-off container proved admit works (household in
  seconds with 9 modules).
- The all-pages CDP sweep (89 seeded page routes) was cut short by
  that restart; re-run after the fixed roll. Early results: pages
  whose module is NOT on prf-a (app-store → appstore, biomining) show
  honest 404 panels (config, not merge); cntfet detail pages carry a
  `<pre class="equation">` in the characteristic explorer — intended,
  the sweep now excludes it; `/display/cntfet-cells` says "payload has
  no netlist" for cell `cdff` (to check against the pre-merge deploy).
- Fixed-roll results (2026-09-05, image with the list fix): `GET
  /polariServer` 0 errors since boot; vpn runbook + vpn CDP 17/17 green
  again; the meal-planning "add to week" form scenario runs (already-
  planned slot kept); nav 19 apps; collab / reticulum / mqttbridge /
  fet / islemesh routes 200; RSS 604 MiB idle → ~950 MiB during the
  sweep (the known non-returning climb, now larger with 24 modules —
  prd-3's gunicorn recycling is the answer).
- **All-pages CDP sweep, 89 seeded routes: 60 clean outright; the 29
  "fails" classify as** 17 cntfet-detail pages whose only `<pre>` is
  the characteristic explorer's equation block (intended; the sweep
  now excludes `pre.equation`); 2 transient `ERR_NETWORK_CHANGED`
  (sifet, cntfet-score-…-lg30 — both clean when re-checked alone);
  8 pages whose module is NOT assigned to prf-a (app-store, biomining,
  computers, microalgae, supply-chain, tanks, wax-supply, zones —
  honest CRUDE 404 panels; assign the modules or hide the pages —
  config, not code); 2 intended refusals shown in the error state
  (cntfet-cells: cell `cdff` is a sequential DFF with no combinational
  netlist; cntfet-score-si-pmos-…: pmos-keyed characterization
  deliberately not run); 1 auth-gated panel on /display/mealplan (no
  Keycloak identity in the headless browser); 1 REAL bug on
  /display/mealplan/planner — `/plans/{name}/availability` 500'd
  because a second `on_get_availability(person)` shadowed the plan
  handler (pre-existing since mlg-1; fixed, rolled); 1 to look at:
  /display/mealplan/household renders one structured panel in raw
  mode with an empty payload (no API failed; which panel is owed).
  Net: 79/89 genuinely fine, 8 config, 1 fixed, 1 owed.

## 15. Dependabot 2026-09-05 — the two cryptography advisories he forwarded, and the other 15
`gh api …/dependabot/alerts` listed 17 open alerts on Polari-Framework,
all in requirements.txt: cryptography ×7 (incl. CVE-2026-69249 and
CVE-2026-69247, patched at 49.0.0 / 50.0.0), pip ×5, setuptools ×2,
urllib3 ×2, requests ×1. Pins bumped to cryptography 50.0.1, pip 26.2.1,
setuptools 84.0.0, urllib3 2.7.0, requests 2.34.2 (each ≥ its patched
version). Image rebuilt: RS256 JWT round-trip on 50.0.1, vpn 89/89,
islemesh 95/95 in-container; rolled to prf-a. The alerts close only when
`dev` (or main) is pushed — his ritual. Note for prd-2: pip + setuptools
should not ship in the runtime venv at all.

## §17 — sap-1/sap-2 layout migration proof (2026-09-08)
Migration: `moduleService/standardize_layout.py apply` + `rewrite-from-git`
(848 files git-mv'd: postfix concept names, 290 into `custom/`, two legacy
dirs renamed; 1046 files' references rewritten incl. `from pkg import
module` forms and `__file__`-relative data paths in moved files).
| check | before | after |
|---|---|---|
| every module file imports (`standardize_layout import-all`) | 818/818 | 818/818 |
| `selftest_lazy_imports` drift guard | 23/23 | 23/23 |
| module selftest suites (16 modules, 64 suites) | recorded | identical results (vpn 89/89, gears 68/68, reticulum 184/184, islemesh 95/95, techtree 74/74, appstore 7 suites, nutrition 32 suites all PASS/0 failures, …) |
| `selftest_manifests` | — | 7/8 (agro_forestry + materials_science have no selftest — real gap) |
| `manifests conform --all` | — | 46/48 (the same two) |
| one-off backend boot on the migrated checkout (prf-backend:staging image, host checkout at /app, 10 modules) | — | `/api/health` 200 in ~10 s, `/polariServer` 200, `/api/gears/types` `/api/reticulum/capability` `/api/islemesh/catalog` 200, CRUDE `/GearDefinition` `/VpnNetwork` 200, 677 class inits, 0 tracebacks; legacy dynamic modules report `disabled` as before |
Not proven here: a full 24-module staging boot and the browser sweep on
the new layout (unchanged logic, but run them at the next deploy); docs
in AI-Notes still cite old file names.

## §18 — sec-1a, Polari side (2026-09-12, branch dev-sec-1; ISLE_HARDENING_PLAN §13)

His rules: warn-only everywhere; one piece; re-test each. ⛔ NOT the droplet (his correction, same day): tests across pol-core / econ-core / isle-core via app deployments. All live runs below = isle-core (root over ssh), throwaway profiles loaded and unloaded in the same script; every isle container up before and after (5/5); nothing left on the machine.

| piece | machine | check | result |
|---|---|---|---|
| deny-in-complain probe | isle-core | `deny /tmp/x r` under `flags=(complain)` | ENFORCED (Permission denied, no log line) → template rewritten as an allow-list |
| render | pol-core | 4 scenarios, `--apps-from-manifests` | swarm-lean/full: 0 app profiles, 59 modules folded, docker-default + stock copy; isle: 59 apps + 6 fixed; dev: 59 |
| parse | pol-core | `apparmor_parser -Q --skip-cache` | 142/142 (complain); swarm-lean enforce 6/6 |
| apply dry-run | pol-core | `apply.sh --scenario swarm-lean --dry-run` | docker-default step + 4 fixed profiles in complain; rings printed |
| allowed.py | pol-core | `--selftest`; `--since 1d` (adm) | PASS 5 groups; 0 lines locally |
| audit | pol-core | `audit.sh --scenario swarm-lean` | partial 10 pass / 7 fail / 3 skip (no root) |
| docker-default swap | isle-core | swap in complain → plain container writes /usr/bin → revert to stock | attached live (complain section), 3 ALLOWED lines under `docker-default` with rules, stock deny (sysrq) still enforced, revert = enforce stock, no file left |
| escape-test full, complain | isle-core | 14 probes, python image | 9 blocked, 0 escaped, **5 BROKEN**: python cannot start under the `worker` seccomp list ("Error relocating python3") |
| escape-test profile-only, complain | isle-core | `--alone` | 5 blocked (docker's masks/caps), 7 escaped as expected, 43 ALLOWED accesses harvested (34 = python `__pycache__` writes into the image, `/usr/bin/pwned`, `capability sys_chroot`) |
| escape-test profile-only, ENFORCE | isle-core | `--alone`, real enforce (`--mode` now overrides fixed_mode); probes repaired and re-run | **11 blocked** (socket, mount, sysrq, sysctl, module, ptrace, raw socket, userns, image write, chroot, firmware), 3 escaped (host bind read → DAC/userns D1; keyctl, bpf → seccomp), 0 broken; harvest 8 DENIED lines |
| pol prod verify / modules health | — | not run: no deployment was changed | — |

Test-tool bugs found and fixed on the way (each had made an earlier "proof" vacuous): busybox `nc -U` socket probe hangs forever; 3 probes needed python3 absent from alpine; `PIPESTATUS` lost in `$(…)`; parser cache skipped a same-name reload ("same as current profile"); `--mode enforce` left fixed pieces in complain; keyctl/bpf probes read the wrong errno; tmpfs noexec broke the chroot probe. The 2026-09-10 "14/14 blocked under an enforced profile" is therefore re-read as: the container flags blocked 14/14; the profile's own share was never measured until today.

Owed: the warn-only apply on the home swarm (pol-core manager, needs his sudo) + a day's `pol prod harden report`; the app-surface ring in the lean stack file (his go); seccomp warn mode (sec-1c) before any list touches the musl backend; audits before/after on all three machines; `pol prod verify` after each; isle-core's Claude told about the allow-list template + `--skip-cache` (NOTES-FROM-POL-CORE).

**Baseline audit across the three home machines (2026-09-12, `pol deploy audit <node>`, no root on pol-core/econ-core → MAC controls skipped there):**

| machine | verdict | pass / fail / skip | the fails |
|---|---|---|---|
| pol-core (swarm leader, docker 27.3.1) | partial | 10 / 7 / 3 | userns-remap, a docker.sock mount, a writable rootfs, sudo groups, DOCKER-USER empty, kptr_restrict=1, no auditd |
| isle-core (worker + the isle, docker 29.1.3) | open | 12 / 13 / 1 | + 5 containers root inside, /etc/isle-mesh 755, no isle-app-* profiles, all on stock docker-default, builtin seccomp, ufw inactive, sshd on all interfaces |
| econ-core (worker, docker 29.1.3) | partial | 9 / 8 / 3 | userns-remap, a root container, 2 writable rootfs, sudo groups, DOCKER-USER empty, sshd on all interfaces, kptr_restrict=1, no auditd |

These are the "before" rows the loop compares against after each warn-only apply on the home swarm.

## §19 — sec-1c + the loop across the home machines + the hardware-app notice (2026-09-12 evening, dev-sec-1; plan §14)

| piece | machine | check | result |
|---|---|---|---|
| seccomp LOG lists | isle-core | python:3.12-alpine workload (threads, subprocess, sqlite, ssl, asyncio, multiprocessing, tempfiles) + nginx under `worker.json` (SCMP_ACT_LOG) | ran; harvest: ONE syscall outside the list, `open` ×20 (python3, nginx, docker-entrypoint) |
| seccomp ENFORCE lists, before the fix | isle-core | same under `worker.enforce.json` / `web-app` / `gateway` | python "Error loading shared library libpython3.12 … Operation not permitted"; nginx "can't open /docker-entrypoint.sh" |
| seccomp ENFORCE lists, after adding `open` | isle-core | same | python workload ok; nginx serves a page under web-app and gateway lists; 0 seccomp lines |
| allowed.py selftest | pol-core | 7 groups incl. seccomp by name | PASS |
| render all scenarios | pol-core | 4 scenarios | 144 profiles parse; `.enforce.json` twins; `stack.security.yml` per scenario; isle renders the node union (`node_profile: true`) |
| `pol deploy harden --dry-run` | isle-core, econ-core | remote ship + dry-run | both print the full plan (isle: 65 profiles + union; econ-core: swarm-lean union + 4 fixed); econ-core sudo prompts for the real run |
| `pol deploy harden isle-core` (REAL, warn-only) | isle-core | apply + audit | union docker-default loaded in complain (live), 65 isle-app-* in complain, seccomp staged, firewall/host/DAC printed; audit open 12 pass / 14 fail / 0 skip (baseline was 12/13/1; the new no-audit-lines-24h control counts today's test lines: 377); all 5 isle containers up |
| apply.sh warn-only aborts | pol-core | seccomp dir / unit drop-in dirs created only under --enforce, files installed regardless (`set -e`) | fixed: seccomp staged as inert files; unit drop-ins enforce-only |
| hardware-app notice | pol-core | `hardware_reach` unit check per route (voron, printcam, hwmap) | swarm/dev: "polari-side-only" + sentence; isle: ok; non-hardware: none; py_compile of the 5 touched files |
| `pol prod verify` / a real module admission with the notice | — | not run: no core rebuilt/deployed with the new code today | owed at the next image build |

Owed: the first real harvest from isle-core after a day (`pol deploy harden isle-core --report --rules`); the same warn-only apply on econ-core + pol-core (his sudo); the stack overlay deployed on the home swarm (his go, then `pol prod verify`); the notice seen live (rebuild core image → `pol modules health`, fetch-admit voron, /downloads/apps card); isle-core's Claude: set `POLARI_DEPLOY_ROUTE=isle` in polari-isle/docker-compose.yml.

## §20 — the `security` module: three security topology views + simulations (2026-09-12 night, dev-sec-1; SECURITY_INTERFACES_PLAN §13)

| check | result |
|---|---|
| module selftest (host, `PYTHONPATH=.:modules`) | 19/19 |
| seed counts | domains 3 · areas 13 · scenarios 4 · controls 92 · nodes 285 · edges 413 |
| API handlers smoked without a server (request/response doubles) | `/api/security` (dev here, 3 views, 28 systems); scenarios (isle security_opt/containers; swarm-* docker-default/in-core); topology os/swarm-lean today; simulate prf-isle-backend on isle (3 logged, 8 blocked); visitor on lean (API open) vs full (refused); compare by role |
| manifest conform | after moving the helpers under `custom/`: custom files must be listed — see the commit |
| in-container boot with the module in POLARI_MODULES, the four displays in a browser, CRUDE on the six classes | OWED (next image build; the classes are in polariServer's literal and the endpoint table) |

## §21 — threat simulations on the topology (2026-09-12 night, dev-sec-1; SECURITY_INTERFACES_PLAN §13 addendum)

| check | result |
|---|---|
| module selftest | 28/28 — stock: image backdoor, raw sniff and the socket (if mounted) get THROUGH; today: the socket is blocked by the mount policy; enforce: blocked with the policy named; every counterexample path reaches its target; isle has guest-escape and an open device counterexample, the swarm has none; lean's anonymous API is allowed and says so, full blocks it at Keycloak; the animation path stops at the block |
| seed | SecurityThreat 45 rows (4 scenarios) |
| manifest conform | OK after `manifests generate` refilled `imports` |
| frontend `npx tsc --noEmit -p tsconfig.app.json` | passes with the new panel + registry entry |
| in a browser | OWED (next frontend image build) |

## §22 — physical access: Secure Boot + disk encryption in the security module (2026-09-13)

| check | result |
|---|---|
| module selftest | 32/32 — encryption off → the drive is readable; Secure Boot stops a tampered kernel but not a live USB; enforce on a desktop profile → encryption blocks the drive and the USB; enforce on a headless profile → encryption stays OFF (never on headless); both physical threats carry counterexamples |
| audit on pol-core (dev, no root) | `physical secure-boot` and `physical disk-encryption` report (this box: see the run) |
| on isle-core / econ-core (`pol deploy audit`) | OWED next session |

## §23 — the security module's remaining rows, ledger, live feed, write-back (2026-09-13)

| check | result |
|---|---|
| module selftest | 39/39 (ledger blocks nothing at conform; the isle backend blocks at mac_enforced; Keycloak public clients asymmetric / confidential symmetric, no symmetric user channel; the isle union complain today, swarm unions rendered; expired internal certs reported; proposal: /app/data + CHOWN + open proposed, pycache ignored, /etc write / sys_admin / mount not expressible; audit feed: loaded+not-enforcing → complain, ufw pass → live, secure-boot fail → off) |
| derivations on the real tree | MacProfile 151 · DacPolicy 140 · PermissionGroup 12 · ProxyConfig 5 · ProxySnippet 60 (all absent) · ServiceIdentity 12 (internal certs EXPIRED −25/−9 d — a real finding for `pol cert renew`) · FirewallRuleSet 8 · TrustChannel 19 · AuthzRule 1 · BrowserPolicy 6 · AppSecurityRecord 260 |
| manifest conform | OK (23 classes) |
| CLI `pol security os audit --post`, `propose --profile --accept` | syntax-checked; not run against a live core yet |
| POST /api/security/audit, /propose; the pages | OWED: a core booted with the module (next image build) |

## §24 — certificate notices (2026-09-13)

| check | result |
|---|---|
| notices reduction (selftest) | expired → error + renew action; expiring ≤14 d → warning; auto-renew absent → info; internal expired → warning; unreachable host → info (40/40) |
| audit `certs` ring on pol-core | edge-cert skip (nothing on :443 here); auto-renew pass (1 systemd timer) |
| frontend `app-system-notice` | tsc passes; unseen in a browser (image rebuild) |
| the live probe against a real instance | OWED (home swarm lean deploy) |

## §25 — inventory of the three home machines + ssh as a vector (2026-09-13; role names only, per the privacy rule)

| machine | what is installed, in what form | ssh surface |
|---|---|---|
| pol-core (swarm leader, 22.04, docker 27.3.1, no KVM) | the 20 GB dev checkout on dev-sec-1; `pol` in ~/.local/bin; 40 Polari images (ghcr release tags + local builds), 10 Polari volumes, NO stacks up; only the Jenkins container running; no debs, no isle files, no AppArmor/sudoers rings; a certbot timer | NO sshd (nobody can ssh in; this box is the hub: it holds the ed25519 key and the client config for isle-core / econ-core) |
| isle-core (24.04, kernel 7.0, docker 29.1.3, KVM + IOMMU) | `polari-complete` 0.1.33 deb; `isle` + `pol` in /usr/local/bin + /usr/share/isle-mesh; the 5 isle containers (agent, apt, prf-isle backend/frontend, sample app); the OpenWrt router guest; isle-host-agent + mesh-mdns units, polari-isle-push timer; /etc/isle-mesh + /etc/polari; 66 AppArmor files (the warn-only rings from yesterday); a 514 MB suite checkout on dev + ~/polari-isle; NO apt.isle source configured on itself | sshd on ALL interfaces; **PasswordAuthentication yes** and **PermitRootLogin without-password** (findings); 1 ed25519 key for the owner; passwordless sudo for that user; no fail2ban; ufw inactive; 0 failed logins in 24 h; edge cert 361 days left; **no auto-renew scheduled** |
| econ-core (22.04, docker 29.1.3, KVM + IOMMU) | the Odoo pair (odoo + postgres, up 6 weeks); 5 images incl. a 4.5 GB engines image; a 1.2 GB suite checkout on dev and an Isle-Mesh checkout on dev-consolidation; NO pol, NO isle CLI, no debs, no isle files, no rings | sshd on all interfaces; auth methods unreadable without root (sudo prompts); 2 ed25519 authorized keys; no private key, no outbound relationships; no fail2ban; **no auto-renew** |

Audit `ssh` + `certs` rings ran on isle-core and econ-core through `pol deploy audit` (rows above). Owed: `pol deploy inventory <node> --post` against a live core (the rows and the isle topology panels), `PasswordAuthentication no` + `PermitRootLogin no` on isle-core (isle-core's Claude / his call), fail2ban or `ufw limit 22` everywhere, `pol cert auto-renew install` on isle-core.

## §26 — the third full purge (2026-09-13, his go)

| step | result |
|---|---|
| git gate | dev-sec-1 → dev (ff) in 5 repos; the suite's Isle-Mesh store door committed; econ-core's uncommitted Isle-Mesh work salvaged to `econ-core-salvage-2026-09-13` (pushed from pol-core: econ-core has no GitHub credentials); `push-all-dev.sh --push` (15 module subtrees re-published); every repo verified ahead=0 behind=0 dirty=0 before any deletion |
| pol-core docker | stacks/services/containers gone (Jenkins included), images 0, build cache 0 (14.8 GB reclaimed); the 14 named volumes and the two down workers removed by HIM, `docker swarm leave --force` by him → swarm inactive, 0/0/0 |
| isle-core | rings reverted (stock docker-default, isle-app-* removed), `isle uninstall --everything --force` (its own backup under /var/backups), polari-complete purged, swarm left, docker 0/0/0, the router guest undefined, all polari/isle paths removed; the stale isle-mesh-boot unit removed by him; disk 4 % |
| econ-core | Odoo containers + images gone, swarm left, every Polari directory removed; the 3 named volumes removed by him |
| pol-core checkout | precious gitignored files backed up (~/polari-checkout-backup-2026-09-13: privacy denylist, prod profiles + answers, AI-Notes/local, .claude, CA keys, credential env files) → `git clean -xdf` in the suite and every submodule → .polari / AI-Notes/local / .claude restored; 805 MB of source; disk 95 % → 59 % |
| the AI reaching the public site | home, /downloads, prf, api health (online 4/4), apt — all 200 with valid TLS; /downloads/apps offers 16 modules (the core-baked ones) and refuses 43 as "registered but its code is not downloaded on this instance" — the catalogue gap (memory offline-app-debs) |
| **hand-back finding** | after the uninstall isle-core could not resolve names: NetworkManager held the router's DNS but systemd-resolved had no scope on the wifi link (a transient: the resolver pieces restarted under a live connection, DNS never re-pushed). Fixed by `nmcli connection up SETUP-CCD1`. RULE (memory uninstall-hands-back-default-ubuntu): the uninstall must re-apply the network itself (`nmcli device reapply`), prove a public name resolves + route + apt before printing "complete", keep an install-time journal and an offline `isle rescue network` |

## §27 — HIS TEST: install the deb from the production website on a wiped machine and make an isle (2026-09-13)

| step | result |
|---|---|
| download from https://polari-systems.org/downloads | `polari-complete_0.1.34_amd64.deb`, 55 MB, valid deb (Depends: curl hostapd iw jq libnss3-tools nodejs openssl policykit-1 socat zenity) |
| install (`apt-get install ./…`, non-interactive) | OK — 2 extra distro packages; postinst prints the two doors (core-install / onboard) |
| `isle core-install --help` (as a user) | **BUG**: the flag is ignored and a real install STARTS; it runs the prerequisite checks as non-root and fails only at writing /etc/dnsmasq.d/split-dns.conf ("Permission denied"). Left no residue. Unknown flags must never start an install; non-root must refuse first |
| `sudo ISLE_ASSUME_YES=1 isle core-install --skip-security` (unattended) | 1/7 networking OK (router VM, agent, bridges, mDNS, sample app, discovery mode); 2/7 isle CA minted; **3/7 FAILED**: the shipped `polari-isle/docker-compose.yml` hardcodes `prf-backend:staging` / `prf-frontend:staging` (local build names) → `pull access denied` — a deb from the website could never bring Polari up without a local image build. The published images exist on ghcr (`polari-v2026.09.12`, `-core`, `-all`) |
| after pointing the seeded compose at `ghcr.io/dausume/prf-*:polari-v2026.09.12-core` and re-running | 3/7 OK: prf-isle up, polari.isle + api.polari.isle registered, .isle DNS, pusher timer, `api/health` 200, polari.isle 200; **4/7 WARN**: no isle-app-store deb staged (~/polari-shells) — the "complete" installer does not carry the store shell deb; **5/7 FAIL**: apt-on-mesh publish has no deb source → https://apt.isle and the JOIN DOOR do not exist; 6/7 verify OK (hub answers, store 25 apps); 7/7 skipped by flag. Exit 0, join info printed |
| manipulate it | `isle agent status` (core mode, host agent + vlan agent healthy), `isle router status` (VM running, bridges) — but `arp: command not found` → router IP undetectable (also in `isle status`); `isle app list` prints the docker-group warning even under sudo; `isle dns list` prints an empty list although polari.isle/api.polari.isle were registered; Polari: 20 modules online / 53 disabled; 4 containers up |
| audit of the fresh isle (`pol deploy audit isle-core`) | open, 16 pass / 18 fail / 1 skip — the same baseline as before the purge (nothing hardened by the install itself, as designed until the rings apply by default) |
| inventory | polari-complete deb; 4 containers; router guest; ssh: passwords on, root-with-key, no fail2ban (unchanged findings) |

Fix landed in the suite's Isle-Mesh copy (the live copy now): `polari-isle/docker-compose.yml` images default to the PUBLISHED `ghcr.io/dausume/prf-*:polari-v2026.09.12-core`, overridable through `polari-isle/.env` (`POLARI_IMAGE_REPO`, `POLARI_IMAGE_TAG`); the deb build should stamp the release tag into that `.env` (owed). For isle-core's Claude (contract note): the `--help` bug, the non-root partial run, `arp` (net-tools) missing, `app list` under sudo, `dns list` empty, the store-shell deb not shipped in polari-complete (→ apt-on-mesh + join door absent), status "Could not determine router IP".

## §28 — the app-deb API (2026-09-13; his ask: status / request / download, online vs offline first-class)

| check | result |
|---|---|
| `modules/appstore/apps_api_selftest.py` (host, real generation into a temp pool) | 12/12: catalogue lists every registered module with both flavours; unknown → 404 sentence; online/offline differ in what they carry; space check with numbers; not-generated before a request; download before request → 409 with the request URL; offline names system engines as NOT inside; request → 202 with URLs; generation ready with bytes + sha256; download streams with `X-Polari-Sha256`; request when ready → 200 "already available"; `/api/downloads` answers |
| routes | `GET /api/apps` · `GET /api/apps/{m}/status?flavor=` · `POST /api/apps/{m}/request?flavor=` (fetches the repository when the code is absent, refuses 507 on space) · `GET /api/apps/{m}/download?flavor=` (200 deb / 202 generating / 409 request first) · `GET /api/downloads` |
| CLI | `pol apps status|request|fetch <module> [--flavor] [--from <core>] [-o file]` (fetch waits, downloads, verifies the sha256) — syntax-checked, not run against a live core |
| manifest conform (appstore) | OK |
| against a live core / the production server | OWED (image rebuild; the request route's repository fetch needs a manager → live only) |

## §29 — the downloads interface revised (2026-09-13; his rulings 1 + 4)

| check | result |
|---|---|
| `/downloads` | ONLINE / OFFLINE are the top-level tabs of the page itself; under each: the installer (online: one-file + the stepped option; offline: the offline installer when staged, else the honest note), then EVERY registered app as a card for that flavour, then the first-start, explainers, plan link; the offline media set (staged chunks or the honest "not built yet") under Offline. Renders with tabs and 59 app cards even when no platform installer is staged |
| every official app on production | a registered module whose code is not on the instance gets "Generate & download" with the note "Fetched first: … pulls it from its repository, then packages it"; the HTML status route calls the API's `ensure_code` before generating; only a module with no repository (or a refusal) still says "Not available here" |
| selftests (host) | downloads 16/16 (+ the tabs/apps/media check) · app_debs 19/19 · offline 6/6 · apps_api 12/12 · appstore manifest conforms |
| on the production server / a live core | OWED (image rebuild): the fetch-first cards need a manager; the 43 refused modules on the site become offered |

## §30 — the self-sufficient offline app deb, as it applies to app debs (2026-09-13; his ruling 2)

Fact that sets the scope: Polari runs inside its backend image, which BAKES the system engines in (Dockerfile apk: ngspice, ffmpeg); host-level engines (docker, libvirt, qemu, wireguard-tools) belong to the platform installer / the offline media set, not to an app deb. So for an app deb "carry and install all dependencies" = the pip wheels, consumed at admission.

| check | result |
|---|---|
| admission with a staged offline deb (`<module>/wheels/` present) | `pip install --no-index --find-links wheels/ …` — never the internet; already-present packages skipped (pip's "Requirement already satisfied", reported as `skippedPresent`); a package neither carried nor present = an honest failure, never a download (`module_dependency_tracker.install_packages(find_links=…)`, `live_admission._install_module_deps`) |
| the API's flavour statement | offline: "installed from the carried wheels, skipping what is already present"; engines classified `in_runtime_image` / `host_level` / `not_available_anywhere_yet` (verilator for hwdigital/hwfpga is a named gap: in no image and no installer) |
| selftest | apps_api 15/15 (incl. the presence-checked offline install against an empty wheel dir: `pip` skipped as present, an unknown package refused with --no-index) |
| OWED | the platform installer's own offline flavour with the apt closure (the off-1 pool builder, target release/arch, signed) — the media set; verilator into the runtime image or an engines image; a live admission of a staged offline deb on a core |

## §31 — the swarm proof on the home swarm (2026-09-13; his ask: "ensure this can work on the docker swarm deployment we will be putting out on the droplet")

The lean stack deployed on pol-core from THIS checkout (`pol prod apply --profile home-lean --yes`: images built here, self-signed cert, no logins — the droplet's shape), verified through the proxy as a user or a script would:

| check | result |
|---|---|
| `/downloads` and `?flavor=offline` through the edge | 200; the top-level Online / Offline tabs; 59 app cards under each (headless Chrome render checked by eye: the tabs are the first choice on the page, self-describing; the installer form is a small secondary pair) |
| `GET /api/apps` through `api.prf.<domain>` | 59 modules, both flavours, free-space probe |
| the fetch-first path, live | with `gears` removed from BOTH the image copy and the data volume and its pool file purged: `POST …/request` → `fetched: True` (cloned from GitHub inside the container into `/app/data/modules/gears`), generated, `GET …/download` 200 with the checksum — the path the droplet's `-core` image (which lacks the 43 optional modules) will take |
| downloads stream | the file is streamed (never read into the backend's memory) with `X-Polari-Sha256` + Content-Length |
| security on the lean stack | `security` added to the lean floor set (compose default + every shipped prod profile): `/api/security` = scenario swarm-lean, three views; `/api/security/notices` probed the stack's own hosts (level ok) |
| the fetched-modules volume | `POLARI_FETCHED_MODULES_DIR=/app/data/modules` was MISSING from the lean/prod stacks (fetched code would have vanished on restart) — added to both |
| `pol prod verify --module mealoptions` | 10/10 (the earlier run with `--module gears` failed only because gears requires mathshapes — not a regression) |
| the backend image build | one `curl … 404` inside the freetype fetch step (a mirror; the Dockerfile falls back to the next host) — benign |
| state left | the lean stack is UP on pol-core (ports 80/443, swarm re-initialised, single node) as the home proof; `pol prod down` removes it |

What is NOT proven here: the droplet itself (his rule — never test there); the offline flavour's wheel fetch on the droplet's outbound network; the app-store deb in polari-complete (the isle side).

## §32 — the USB app stick (2026-09-13; his rulings: Polari looks for a stick, the stick is the advised path, always offline)

| check | result |
|---|---|
| `pol apps usb list` | finds mounted removable drives (lsblk), marks the ones carrying `polari-apps/index.json` as app sticks with the install command |
| `pol apps usb write <dir> --apps gears,terms --from <the home lean stack> --insecure` (a temp dir stood in for the mount) | 2 offline debs (35 KB, 887 KB) generated by the stack, downloaded, sha256 verified; index.json (schema polari-app-stick/1, flavour offline, per-app carries/engines/hardware notice); install-apps.sh copied; 0 installers (none staged on the home stack) |
| `install-apps.sh` | refuses without root as designed; presence-checked (`dpkg -s`) per package, offline `apt-get install ./deb` |
| `--insecure` | added to `pol apps` verbs and the stick writer for a self-signed home core (verification stays the default) |
| a real stick + the store door | OWED: the isle side (contract note) and a physical stick |
| (later, same day) his three cases: apps only / all of Polari as an app alongside apps / bulk from one stick + no duplicate installs | `pol apps usb write <dir> --apps gears,terms,mathshapes --from <home stack> --insecure`: the platform deb polari-complete_0.1.34 (55 MB) pulled from polari-systems.org because the home core stages none (`--platform auto`; `yes` fails loudly, `no` = apps only); 3 apps verified; `index.json` records each app's wheels + `shared_wheels` (0 here: disjoint closures); files already on the stick are kept, never re-downloaded; `install-apps.sh` installs the platform first only if dpkg lacks it, then each app only if absent (`--no-platform` for apps only); libraries inside each app go in through pip `--no-index` which skips present ones. Rendered `/downloads?flavor=offline` leads with "The advised path: a Polari USB stick". OWED: a physical stick + a real install on a wiped machine; the ISO roll-up (POLARI_ISO_PLAN addendum). |
| (later) his ask: the stick PROMPTS on insert (Install / Not now / Wipe), configurable; wipe when the install is confirmed finished | Built: root `autorun.sh` → `polari-apps/on-insert.sh` (zenity/kdialog, else terminal; pkexec/sudo; `--answer` for scripts), `install-apps.sh --verify` = confirmed finished (every package present, else the missing list), `wipe-stick.sh` (removable/USB only, refuses the disk holding / /boot /home, names device+size, `--yes` required, `--polari-only`, `--fs ext4|vfat --owner`), policies `--on-insert ask|none` + `--after-install ask|wipe|keep` in index.json, host `pol apps usb config`, `pol apps usb watch [--enable]` (systemd --user; polls lsblk 3 s; prompts once per newly mounted stick), `pol apps usb prepare /dev/sdX --fs ext4`. Proven on pol-core: GLib tree detection of the stick root = `x-content/unix-software` (the desktop's own pre-prompt check; autorun-x-content-start-app on by default); scripted "no" leaves the stick; `--verify` honest (4 missing); the system-disk refusal (rc 3) without root; `pol apps usb config`. FACT: udisks mounts vfat with `showexec`, so a FAT stick can never self-start — ext4 for a self-prompting stick (Linux only), else Polari's watcher. PROVEN on isle-core (user ssh + sudo) with a 64 MB loop image: system-disk refusal as root (rc 3), the plan without --yes (rc 2), --polari-only (0 entries left), full wipe to ext4 labelled + owner 1000:1000 mode 755. `--verify` on a stick with NO packages is 'nothing to verify' (rc 1), never a vacuous pass that would wipe. OWED (a real stick + a desktop): the live desktop prompt, the watcher as a unit, kdialog on Plasma. |

## §33 — ssh + permission-level tracking and assurance (2026-09-14; his asks)

| check | result |
|---|---|
| security selftest | the 8 new assurance/levels checks + 2 notice checks pass; class/seed counts 26. 3 pre-existing FAILs on this host since the purge (ledger mac_enforced, mac union, expired internal certs) — environment, not code |
| inventory.sh on isle-core | allow_groups '', groups sudo|<user>, 4 sudoers grants incl. a blanket NOPASSWD ALL for the user, posture null, no root Match drop-ins |
| audit posture-assurance on isle-core | FAIL "UNSECURED: passwords accepted — no posture allows that"; ssh-groups FAIL; sudo-scoped FAIL |
| OWED | a live core with the new image: POST inventory → SshPermissionLevel rows + the isle topology panels + the notice bar showing dev-mode; a node under a declared dev posture (posture.json) reading DEV |

## §34 — his questions 2026-09-14: the website deb on two machines, and the member tier choice

| question | answer today |
|---|---|
| website deb → isle-core core-install | tested §27: install OK; core-install as PUBLISHED fails at 3/7 (hardcoded prf-*:staging images); after the compose fix in this checkout the isle came up and was driven. The website STILL serves that 0.1.34 — a fresh download fails the same way until the deb is rebuilt (build now stamps the ghcr tag into polari-isle/.env) and republished |
| the same deb → econ-core as a HARDWARE member connecting to the core | NOT tested, and not possible yet: the isle side has no hardware tier (`isle onboard` = plain or `--host` only; agent.tier=hardware + `isle vm` requested 2026-09-08, open); econ-core is wiped since the purge |
| does non-core setup ask "hardware, heavier" vs "lighter, no hardware"? | NO. The CLI has only `--host`; the store's door 2 shows text with `[--host]` and wraps nothing. Design recorded (contract note): `isle onboard --tier light|host|hardware`, interactive three-way question in plain words, the store door = the same three cards wrapping the verb (his rule: CLI verbs first, UI wraps them) |
| owed | republish the deb; isle side: the tier verb + hardware tier + door 2 wrapper; then the two-machine test with econ-core as HARDWARE |

## §35 — the store setup flow revised around the new choices (2026-09-14; his ask: CLI verbs wrapped by the UI via pkexec)

| check | result |
|---|---|
| doors | Create (mode Production/Development + dev warning) · Join (tier Light/Host/Hardware + fingerprint + core address) · Install apps from a USB stick · Set up a public server · Just browse; a plugged-in stick is offered first even on a member |
| `store-setup.sh` dry runs (DRY=1) | core-install --mode dev: posture written, dev warning printed, falls back to plain `isle core-install` with a WARN when the CLI lacks --mode; join --tier hardware: fetches the bootstrap from the core, prints its sha256 for the out-of-band compare, falls back to --host with an honest WARN; join without --fingerprint refuses; posture production OK; stick with no stick refuses with the make-one hint; usage on no verb |
| packaging | build-store-deb.sh ships store-setup.sh; compose files (isle, lean, prod) pass POLARI_POSTURE (default production) |
| OWED | the dialogs themselves on a desktop (zenity flows unclicked); a rebuilt isle-app-store deb; the isle CLI's --mode / --tier so the fallbacks stop; a polkit .policy for a friendlier prompt text |

## §36 — the Access-only tier + the `access-app` kind (2026-09-14; his ruling: shells only, no hosting of swarm or KVM apps)

| check | result |
|---|---|
| `python3 -m moduleService.selftest_tier_reach` | three tiers; every manifest kind has a lowest tier; access-app runs everywhere; polari/isle/library need host; hardware kinds need hardware; the access-only notice names the shell; the access form = the launcher package |
| apps API (apps_api 15/15, app_debs 19/19) | `hosts_on`, `access_form`, `notice_on_access` per app (status + catalogue); gears → hosts_on host/hardware with the ACCESS ONLY notice; the downloads card says "Runs on: host / hardware members — on an Access-only computer install the app's shell instead" |
| store flow | the tier door says "Access only" (shells only, hosts nothing); `store-setup.sh join --tier access` = plain onboard; 'light' alias |
| OWED (isle side) | `isle onboard --tier`, the store listing shells only on an access member, `isle app install` refusing hosting kinds there, the launcher deb's `Polari-Kind: access-app` |

## §37 — two forms per app, install-time refusals, access apps that find their target (2026-09-14; his rulings)

| check | result |
|---|---|
| apps_api selftest (host, real generation) | 25/25: status/request/download with `form=access` (a launcher deb < 200 KB: .desktop, executable open.sh, access.json, Depends polari-shell-core online); `/api/access` + `/api/access/{m}` answer url + candidates; preinst for an expansion refuses without its base and on a lightweight isle in his words; a hardware app's preinst names both refusals; a software app carries none; grouping nests expansions under their base |
| page selftests | app_debs 19/19 · downloads 16/16 · offline 6/6 after the card rewrite (two form columns, grouped sections) |
| rendered `/downloads` app section (this checkout, 58 modules) | Software apps / Hardware apps (3: isle_relay, isle_guestnet, voron) with Expansions subsections (reticulum under isle_relay, printcam under voron); every card = Install + Access only side by side |
| manifests | isle_relay + isle_guestnet → hardware-app (tier hardware), printcam extends voron, hardwareapps → library; conform re-run after `manifests generate` |
| CLI | `pol apps access <m>`, `--form` on status/request/fetch, `pol apps usb write --forms install,access` — syntax-checked; NOT run against a live core (the home stack still runs the previous image) |
| REAL on isle-core (sudo) | `dpkg -i polari-app-reticulum` (install form, fetched from the live stack): preinst printed "REFUSED: reticulum expands isle-relay, which is not installed here — install isle-relay first, then this expansion", dpkg aborted at pre-installation, no payload staged, status not-installed (purged). `polari-access-gears` extracted, `open.sh` run headless: found `https://polari.isle/app/gears` by probing the candidates (isle-core's older Polari has no /api/access), wrote gears.url + gears.json, then exec'd the shell (present there from polari-complete) |
| OWED | a hardware app's preinst refusing on pol-core (swarm-only; needs sudo there) and on a non-hardware member; the pick-list branch (needs a machine where nothing resolves); offline access deb carrying polari-shell-core (needs the shell deb staged); the isle side (contract note) |

## §38 — the home stack redeployed from this checkout; the day's surfaces LIVE (2026-09-14; his ask: assessable later, security stays WARN)

| check | result |
|---|---|
| `pol prod apply --profile home-lean --yes` | backend + frontend + pol-hub images rebuilt, stack redeployed; backend BOOT COMPLETE 5/5 modules (security online); the old task's exit 137 was the replacement, not a crash |
| `/downloads?flavor=offline` on the API host | top-level tabs, the USB-stick section first, 61 cards each with Install + Access-only side by side, Software apps (54) / Hardware apps (3) with Expansions of Isle Relay (1) and Expansions of Voron (1) |
| `/downloads?flavor=online` | offers the rebuilt `isle-app-store_0.1.36_all.deb` (the revised setup doors + store-setup.sh inside; staged under .generated/debs) |
| `/api/apps/gears/status?form=access`, `/api/access/gears`, `/api/downloads` | answer live: the access package name, group, title; the app's address candidates; the staged installer |
| inventories posted (`/api/security/inventory`) | pol-core CLOSED (no sshd) · isle-core UNSECURED (passwords accepted; root with key; no AllowGroups; blanket sudo — 3 permission-level rows) · econ-core UNKNOWN (no root there: auth methods unreadable) |
| audits posted (`/api/security/audit`) | isle-core (sudo): 38 controls, 16 pass / 22 fail, verdict open · pol-core (no sudo): 25 controls, 12 pass / 9 fail / 4 skip, verdict partial — every ring WARN-ONLY, nothing enforced anywhere |
| notices | `ssh-unsecured` (error) now shows on the live core for isle-core |
| `pol prod debs build` | the five platform debs rebuilt and staged (.generated/debs): polari-complete 0.1.36 (53 MB, the compose defaults to the published ghcr images — the fix the website's 0.1.34 lacks), polari-shell-core 0.1.36, isle-mesh-cli 0.1.151, isle-app-store 0.1.36 (the revised doors), polari-isle; `/api/downloads` lists all five; the script's final `syntax error` line came from editing prod.sh while bash was still reading it (bash -n clean after) |
| offline ACCESS deb from the live stack | `pol apps usb write --forms install,access`: polari-access-gears-offline (54.7 MB) CARRIES polari-shell-core_0.1.36 under deps/ (Depends curl, python3; Recommends polari-shell-core; Polari-Kind access-app) — the offline flavour of the access form is self-sufficient once the shell deb is staged |
| `pol prod verify` after the redeploy | 10/10 |
| NOT done | a browser pass (the Chrome extension was not connected this session): the security screens, the threat animation, the isle topology ssh panels, the notice bar — unseen; econ-core needs a root-capable run for its ssh reading |

## §39 — the dev posture verb (2026-09-14; plan §16)

| check | result |
|---|---|
| `posture.sh dev --for 30m --relax ssh.root-key-from-isle` on isle-core (sudo) | no isle interface → the LAN of the default route taken as the isle subnet (WARN, `--cidr` narrows); sshd drop-in written (Match Address + PermitRootLogin prohibit-password, `sshd -t` checked, reloaded); posture.json = dev until +30m; `polari-posture-revert.timer` armed; the standing dev warning printed |
| `posture.sh status` | posture, until, relaxations, by; the timer's next elapse; the drop-in's text |
| `posture.sh production` | drop-in removed, sshd reloaded, timer + units removed, posture.json = production |
| fixed on the way | the timer pointed at the /tmp copy pol deploy removes → the script now installs itself to /usr/local/lib/polari/posture.sh for the timer |
| the timer fired for real | `dev --for 2m` on isle-core: four seconds after the expiry the `polari-posture-revert.service` ran (journal: Started → Deactivated successfully), posture.json = production (applied_by root, the timer), the sshd drop-in and the timer units gone |
| OWED | `production-route` marker on a real-domain deploy (prod.sh writes it; no real-domain deploy on the home machines); a base `PermitRootLogin no` on isle-core so the isle-scoped Match is the ONLY root door (his call: his machine) |

## §40 — the hand-back ring and the Dependabot fix (2026-09-14)

| check | result |
|---|---|
| audit `handback` ring (his rule 2026-09-13: a working default Ubuntu after uninstall) | six controls: default-route, public-dns, resolver-upstream, apt-reachable, nm-connections, no-isle-residue (skip while the isle is installed, fail on residue after uninstall). pol-core: 6 pass. isle-core: 5 pass + residue skip (isle installed) |
| Dependabot (Polari-Framework) | all six open alerts were PyJWT < 2.13.0 in requirements.txt → pinned `PyJWT[crypto]>=2.13.0` (2.14.0 on PyPI); takes effect at the next image build. GitHub closes the alerts once the default branch carries the pin (main == dev is his go) |
| OWED | running the handback ring right after a real `isle uninstall` (the CI test the rule asks for) |
| (later) PermissionGroup tie-in | on a posted inventory the designed PermissionGroup rows (sudo/admin/docker/libvirt/kvm, polari-*) get `members` per device (merged, this device's segment replaced) and `installed`; unknown polari-* groups become observed rows. Selftest 54/57 (the 3 host-state FAILs unchanged). LIVE only after the next image build |

(§38 correction, his ruling: the line stays 0.1.X. My hand-passed `--version 0.2.0` on the store deb had pulled the bundle to 0.2.0 — both removed, `pol prod debs build` re-run: versions are 0.1.<commit count> per repo and polari-complete takes the store member's: now isle-app-store 0.1.36, polari-complete 0.1.36, isle-mesh-cli 0.1.151, polari-shell-core 0.1.36; the store deb carries store-setup.sh; `/api/downloads` lists the five.)

## §41 — the all-variants sweep on the live stack (2026-09-14; his question: will it serve and generate every variant?)

| variant | asked | result |
|---|---|---|
| install · online | 59 | 59 ready |
| access · online | 59 | 59 ready |
| install · offline | 59 | 47 ready, 12 REFUSED — every refusal = a junk pip requirement from the import scanner (`json,` `hashlib,` `tempfile,` from `import a, b` lines; `—` `x\`` `keeps` `lands` from docstring prose; `paho` for paho-mqtt; `java`; `simulationlocks`, a framework-internal package) |
| access · offline | 3 (each carries the 55 MB shell runtime) | 3 ready |
| total | 180 in 394 s | 168 ready |

Fix (same day): `moduleService.moduleDiscovery.scan_python_imports` parses with `ast` (real import statements only; a
line-pattern fallback with identifiers only when a file does not parse); `module_scan` drops names that are packages
or files under the framework root (internal) and maps well-known import→distribution mismatches when the library is
not installed here (paho→paho-mqtt, yaml→PyYAML, cv2, PIL, sklearn, serial, usb, dateutil, bs4, jwt, grpc, RNS, LXMF …).
The 12 modules now scan clean (appstore: argon2/falcon/minio/…; mqttbridge: paho-mqtt; grpcbridge: grpcio/protobuf;
composition/mealoptions/nutrition/resources: none). Page render: 25–70 s → 4.6 s cold / instant warm (§ caching).
RE-SWEEP after the redeploy (with `pol prod apply` now forcing services onto the rebuilt local images): all 12 offline installs READY → 180/180 variants generated. The human page: 7.6 s cold after boot, 0.3 s warm. Pool after the sweep: 180 files, 448 MB of the 2 GiB cap.

## §42 — the deb pool policy (2026-09-14; his rulings + the refinements he asked me to advise)

His policy: track when each deb was requested (a re-request refreshes); measure download times over a slow connection;
predict the slow download from the size and hold the deb at least THREE times that; after the hold, remove only when
room is needed for another requested deb; cap the pool's space; free everything untouched for over a day.
Refinements folded in: downloads refresh the hold too and a deb in flight is never evicted; the slow speed is the
slower of a knob (250 KB/s) and the slow quartile of measured downloads; the hold is floored at ten minutes; the cap is
the knob (2 GiB) bounded by free disk minus the margin; a full pool refuses with 507 naming the earliest hold; the
idle purge is per file. Advised, not changed: offline access debs each carry the same 55 MB runtime — carry it only
when no installer is staged (his call).

| check | result |
|---|---|
| `apps_api_selftest` (32/32) | the ledger knows requested_at/requests/hold; hold(55 MB) = 3 × size / slow_bps; a re-request refreshes; make_room refuses while in flight or inside the hold (blocked_by + the earliest hold); after the hold it evicts least-recently-accessed first; the idle purge frees a day-old deb inside a long hold; pool_status carries used/max/free + knobs |
| `app_debs_selftest` (19/19) | a 2-hour-old deb is KEPT by the policy; an explicit ttl still purges by age |
| API | status carries requested_at, requests, downloads, hold_until, hold_remaining_seconds, evictable, retention sentence, pool {used,max,free,slow_bps}; request answers 507 when the pool is full past every hold; the download stream is tracked (in flight, timed, counted) |
| knobs | POLARI_APP_POOL_MAX_BYTES (2 GiB), POLARI_SLOW_DOWNLOAD_BPS (250000), POLARI_APP_DEB_TTL=0 = delete after delivery |

## §43 — the app taxonomy and the apps catalogue page (2026-09-14; his rulings)

His rulings: installing Polari (complete / step-by-step) and installing apps are SEPARATE pages; apps are sortable and
searchable; three major categories — Polari Apps (normal web apps), Network Apps (VPN, Reticulum, isle guests,
bridges), Hardware Apps — with sub-categories beneath; ONE primary category per app, N sub-categories; search all
or inside the category (two interfaces / a switch); Business & Work = bizops, odooconnect, collab only; pspp is
materials first.

| check | result |
|---|---|
| vocabulary | `moduleService/app_taxonomy.py`: 3 categories, 15 sub-categories (7 Polari, 4 Network, 4 Hardware); every polari-app.json now declares category / subcategories / tags (60 written; conform checks the vocabulary; regeneration preserves them) |
| `selftest_app_taxonomy` 9/9 | every module mapped; cross-listing (isle_relay: network, secondary hardware); the two rulings; search by property; the kind fallback |
| `/downloads/apps` (rendered on this checkout) | Polari 8 groups (Materials 9 · Making 12 · Food 5 · Environment 9 · Business 3 · Knowledge 11 · Platform 8); Network: VPN 1 · Mesh 1 · Isle guests 3 · Bridges 3; Hardware: Fabrication 5 · Network devices 4 · Chip design 3 (Robotics empty → hidden); search "wifi" all → 2; "gears" inside Network → nothing, scope all → found; sort by requests/size/recent |
| `/downloads` | Install Polari only: installers, USB stick, media set, and an "Add apps" signpost with the three categories' counts and a search-all box |
| API | `/api/apps` rows carry category/subcategories/secondary/tags/runs_on; `?q=&category=&subcategory=&kind=&tier=&sort=` filter and sort the same way; `taxonomy` in the answer |
| page suites | downloads 16/16 · app_debs 19/19 · module_requirements 14/14 · apps_api 32/32 |
| LIVE after the redeploy | /downloads 1.2 s; /downloads/apps 7–9 s cold then instant; Network page 0.08 s; search 0.06 s; API q=wifi → isle_guestnet, isle_relay; business-work → bizops, collab, odooconnect |
| OWED | a browser pass of the controls (a form, zero JS) |

## §44 — his corrections from the phone (2026-09-14): dark-mode colours, no scope radios, the tier rules

| item | result |
|---|---|
| dark mode | links/chips/tabs take the theme tokens (`a{color:var(--accent)}`, chips + tabs `--ink`); search box / selects / button use `--card`/`--ink` |
| scope radios | removed — the All apps / category tabs ARE the scope (a search runs inside the open tab; All apps searches everything) |
| "runs on" (tier) | never hides an app; it changes the FORMS: access → access form only; isle member → install for web apps only (hardware + core-exclusive apps show "Install — not on this member" + their access form: remote control); hardware member → everything except core-exclusive; isle core → everything. Tiers are now access / member / hardware / core (host = alias of member). Core-exclusive apps declare `agentTier: core` (9 platform modules; one manifest field to change) |
| checks | selftest_tier_reach 13/13 (his rule table); rendered: platform-operations under access → 0 installs / 9 access; member → 0 installs (all core-only); core → 8 installs; Hardware category on a member → 6 installs off, all access forms present |
| store | Join door: Access only / Isle member / Hardware (core = Create my own isle) |
| LIVE (Hardware category, 12 listings) | access → 0 installs offered, 12 access forms · isle member → 5 installs (the web apps cross-listed here), 6 off · hardware member → 10 installs, 1 off (the core-only hardwareapps) · isle core → 11 installs · no radios; dark-mode rule present; `/api/apps?tier=member` marks install false for isle_relay/isle_guestnet/hardwareapps and true for hwdigital/hwfpga/kirimoto |

## §45 — the ISO module: probe → choose → install (2026-09-15; his go: "start building out the iso capabilities and interface module")

Built as `modules/iso` (a core-exclusive Polari app, in the LEAN FLOOR SET so the production deployment carries it):
rows IsoBase / DeviceProbe / IsoBuild; `custom/iso_compat.py` (compatibility DERIVED from the kernel's modules.alias +
the trap list; the Apple silicon message verbatim), `custom/iso_autoinstall.py` (subiquity autoinstall per D1–D15:
unattended, ssh keys from the first boot, Secure Boot on unless chosen off with its warning, encryption off unless chosen
with its warning and REFUSED on headless — at build and at deploy, the platform installed OFFLINE from the ISO, the
posture and the plan written, first boot detects and becomes the core or joins), `custom/iso_probe_kit.py` (README.html
with one button per OS + the Windows/Mac/Linux launchers writing one report shape), `custom/iso_builder.py` (bases
discovered from Ubuntu's SHA256SUMS and cached with the checksum verified; the kernel table from the archive; the
overlay tree; xorriso assembly with genisoimage fallback; the ISO pool under the deb-pool policy with an 8 GiB cap);
`/downloads/iso` (three steps, server-rendered) + `/api/iso/*`; `/display/iso`; `pol iso kit|probe|probes|bases|fetch-base|preview|build|status|fetch|ventoy`;
`pol apps usb write --probe`; the Dockerfile gains xorriso; `/downloads` signposts "A brand-new computer?".

| check | result |
|---|---|
| `python3 -m iso.iso_selftest` | 36/36: ids normalise (Windows PnP → modalias); derived statuses in-kernel / third-party / no-driver; traps (RAID, BitLocker, Secure Boot + NVIDIA); unchecked when no kernel table; Apple silicon = the message, no motives, no "only"; suggested role with evidence; D8 refusal at build and at deploy; the three warnings; D11 keys-only ssh; offline platform install + posture + plan + first boot; the kit; the overlay tree; the ISO pool holds; the API with doubles; the human page |
| conform | 61/61 (the manifest regenerated; category platform-operations, agentTier core) |
| LIVE on the home stack | the iso module online (after wiring it into the server's class list, seeds, pages and endpoint constructors — the lazy-boot gate admits only modules owning gated-in classes); `/downloads/iso` 200; `/api/iso` reports xorriso present and polari-complete 0.1.36 staged; the Linux probe run on pol-core → 28 device ids, suggested role member (no IOMMU), verdict UNCHECKED until the kernel table exists; `ubuntu-26.04-live-server-amd64.iso` (2.78 GB) cached with Ubuntu's checksum verified |
| a REAL image | `pol iso build --role member --shape headless --target <pol-core's hash> --ssh-key …` → `polari-member-headless-ubuntu-26.04-amd64-998907c38b79.iso`, 2.97 GB, assembled by xorriso in the container; inspected: El Torito BIOS + UEFI boot images kept from the base, casper kernel/initrd/squashfs intact, `/nocloud/user-data` (cloud-config, autoinstall v1, keys-only ssh, hostname), `/polari/debs/polari-complete_0.1.36_amd64.deb`, `/polari/plans/<hash>.json`, first-boot script + unit, GRUB entry booting `autoinstall ds=nocloud` |
| fixed on the way | the API re-hashed the stored row to find the job (defaults differ) → lookup by id, and a finished pool image is recognised after a restart; `modules.alias` is NOT shipped in the kernel deb (depmod makes it) → derived from every module's `.modinfo` alias strings, zstd-inflated (zstd added to the image); plans never carry null; the GRUB line gets a serial console (headless installs watchable, D12); the build id carries a builder version |
| OWED | the VM boot on isle-core through to first boot (script staged); the kernel table derived live (after the zstd image); the probe kit on a real Windows and Mac; Ventoy on a real stick; D-P4 join tokens |
