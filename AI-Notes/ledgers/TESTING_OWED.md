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
| kernel table LIVE | 19,261 aliases derived from the 26.04 generic kernel's modules (abi 7.0.0-31), zstd-inflated in the image, plus the built-in modules' aliases |
| this machine's verdict, derived | first read was junk (every class-only pattern claimed every device) → the matcher is exact for full modalias strings and literal vendor/device for partial ids: pol-core = 15 devices with a module (i915, e1000e, ahci, snd_hda_intel, i2c_i801, lpc_ich, mei_me, cp210x, mt76x0u, usbhid…), 13 bridges/root ports/hubs the kernel drives itself → now 'built-in', verdict compatible |
| the fresh image | `polari-member-headless-ubuntu-26.04-amd64-c673cb51f69b.iso` (builder v2: serial console on the kernel line, no null plan fields), 2.97 GB, built in ~2 min from the cached base; isle-core downloading it straight from the stack for the KVM boot |
| the VM boot on isle-core (UEFI OVMF, 3 GB, serial log) | the fresh image boots our GRUB entry unattended, subiquity partitions (LVM), extracts Ubuntu, runs curthooks (kernel, GRUB to the target), then installs the autoinstall packages one by one over the guest's NAT link: openssh-server, curl, jq, python3 fine; **zenity stalled ~35 min** (a GTK dependency chain on a server install) before the late commands ran — the test's 45-min cap ends it. Fix: zenity/policykit only for desktop shapes (headless pulls no GTK); the next run uses that image |
| second run (image 2e27193c0b9d: no GTK, the core key, report_to) | boots unattended under UEFI, partitions, extracts (slow on isle-core, ~40 min), runs curthooks — then sits in curtin's `installing-missing-packages` (efi/grub packages fetched from the archive over the guest's NAT link). The install's remaining network fetches are the weak point of a supposedly offline image: the next design step is the plan's own rule — carry an apt POOL on the ISO (`/cdrom/pool` + `apt: fallback: offline` / a local mirror) so curthooks' missing packages and our `packages` list resolve without the internet |
| OWED | the run through the late commands + first boot + the join report + `pol iso ssh` through isle-core (ssh forwarded on 2222); the offline apt pool on the ISO; the probe kit on a real Windows and Mac; Ventoy on a real stick; D-P4 join tokens |

## §46 — ssh scaffolding from the core outward (2026-09-15; his ask)

| piece | state |
|---|---|
| `pol iso keys init` | an ed25519 pair under `.polari/keys/core` (untracked), the public half staged at `.generated/keys/core.pub`; the lean/prod stacks mount it at `/app/data/keys` |
| every image | the core's public key joins the authorised keys (keys-only ssh, user `polari`); the plan the machine keeps carries `report_to` (the building core's API) and its own hash |
| first boot | POSTs `/api/iso/joined` with hash, hostname, addresses, role, shape, detections; the DeviceProbe row gains joined_at/joined_hostname/joined_addresses/joined_role/joined_shape/detected/ssh_user |
| `pol iso ssh <hash|hostname> [--jump] [--port]` | a session through the core key to the reported address |
| selftest | 44/44 (core key in the keys, plan carries report_to + hash, first boot reports, /api/iso/joined + /api/iso/core-key with doubles) |
| OWED | the live proof: an image built after the key is staged, booted in the isle-core guest with ssh forwarded (2222 → 22), the join report arriving at the core, `pol iso ssh` opening the session through isle-core; in production posture the key must land in `polari-ops` with scoped sudo (the group + sudoers file are still the isle side's) |

## §47 — the first full ISO install in a guest (2026-09-15; isle-core, KVM, UEFI, 3 GB, 2 vCPU)

The member/headless image (0bbba8f7…) went end to end: partitioning → curtin → the eleven late commands → reboot → the installed Ubuntu 26.04 booted from disk → login prompt in **16 minutes**, and the core's key opened a session on it through isle-core (`ssh -p 2222 -i .polari/keys/core polari@isle-core`). What the guest showed:

| found | fixed |
|---|---|
| `/etc/polari/plan.json` and `posture.json` landed as `{role: member, shape: headless, …}` — every double quote eaten by the nested `curtin in-target -- sh -c "printf … '{"role": …}'"`; first boot could not read its plan (`role= shape=`) and never reported | `write_file()` lands files byte-exact through base64; a selftest check refuses any late command that nests `"` inside `sh -c "…"` |
| `report_to` was `http://…` — the proxy set no `X-Forwarded-Proto` and falcon's scheme is the backend socket's; the POST would have been redirected and lost | `X-Forwarded-Proto` when present, else https unless the core is loopback |
| the `polari` user has no password (keys only, D11) AND sudo asks for one → nobody could administer the machine | keys-only install writes `/etc/sudoers.d/90-polari-iso` (`NOPASSWD`, mode 440); a password set → no drop-in |
| `polari-complete 0.1.36` installed offline from the ISO ✅ but **docker is not installed** (not carried; apt fell back offline) and **`isle` is missing** (the core role's `isle core-install` would fail) | not yet — this is the offline apt POOL slice (§45): docker-ce + the isle deb + the packages' closure on the ISO |
| subiquity's `updates: security` step fetched over the network (three minutes here; unbounded on a slow link) | not yet — with the pool on the ISO the security pocket is absent and the step is a no-op; a `security_updates` knob is the alternative |
| Secure Boot: the OVMF guest reports it disabled (no enrolled keys) — the image's `secure_boot: on` is honoured by the firmware, not the installer | nothing to fix; the real-hardware proof stays owed |

selftest 48/48 after the fixes. OWED: the second run of the same test after the redeploy (the plan readable, the join report at the core, `pol iso ssh --jump isle-core --port 2222 --host isle-core`), then the pool slice.

## §48 — DEV APPS / observe mode BUILT (2026-09-15; ISLE_HARDENING_PLAN §17, his ask: "both the dev apps and the iso functionality up so I can test them")

| piece | what exists | proof |
|---|---|---|
| the switch | `moduleService/posture.py`: `state()/posture()/is_dev()` — `POLARI_POSTURE` env, else `/etc/polari/posture.json` (mounted `:ro` into the backend by the lean + prod stacks), an expired `until` = production again | selftest: default → production; env dev; file dev with relaxations; expired → production |
| the ledger | `SecurityEvent` row (27th security class; seeded empty): control · action · target · actor · app · outcome observed/denied · reason · count · first/last seen · source | `decide()` counts the same decision on one row |
| the contract | `security/custom/security_observe.py`: OBSERVED_CONTROLS (authz, content, browser, trust-channel, certificate, peer-admission, posture-relaxation, tier) warn and never block in dev; INVARIANT_CONTROLS (the §16 six, dev-variant-on-production, iso-headless-encryption) refuse even in dev; unknown = invariant | selftest |
| enforcement points threaded | the CRUDE permission gate (`enforce` + dev build → the act runs, header `observed …`, a SecurityEvent); peer admission (`_maybe_auto_approve`: a dev build admits a join request at once, `approved_by=dev-build:observe-mode`, recorded); the join flow's TLS (a certificate failure in dev retries unverified, recorded as `certificate`) | gate proven in the selftest (dev → True + event; production → 403) |
| surfaces | `/api/security/events` (summary + events + the contract); notice-bar item `observe-mode` (dev only: "N action(s) ran that production would deny"); the `security-events` page (8th display: summary panel + SecurityEvent table); audit.sh `ssh/observe-mode` control (warn in dev, pass in production) | selftest for the notice + route |
| dev VARIANTS of apps | a third store form `dev`: `polari-dev-<m>[-offline]` = the install payload; `Polari-Variant: dev`; Provides the install name, Conflicts/Replaces both install names; preinst REFUSES on `/etc/polari/production-route`, REFUSES unless dev posture (env or unexpired posture.json), keeps the hardware refusals, prints the standing warning; postinst records `/etc/polari/dev-variants/<m>.json` (what it relaxes); manifest `security.devVariant` (validated vocabulary; default authz/content/trust-channel/certificate/peer-admission) | apps_api selftest RUNS the preinst: no posture → refused; dev → proceeds with the warning; expired → refused; production route beats even `POLARI_POSTURE=dev` |
| the catalogue | a DEV column per app (badge, the warning) on a dev-posture instance; a greyed honest note elsewhere; `/api/apps` carries `posture`, per-app `dev_variant {relaxes, offered_here, package}`, `forms` incl. dev; `?form=dev` on status/request/download | 37/37 |
| selftests | security 68/71 (the 3 failures — ledger mac_enforced, mac profiles, expired internal certs — FAIL IDENTICALLY BEFORE this change: environment-dependent), apps_api 37/37, iso 51/51, manifests 8/8 (security + iso manifests regenerated) | |

LIVE 2026-09-15 on the home staging stack in dev posture (`POL_PROD_POSTURE=dev` answer → `pol prod apply`): `/api/security/events` summary posture=dev observe=true; the notice bar carries `dev-mode` + `observe-mode` ("0 action(s) ran that production would deny" until someone trips a control); `/api/apps` says `dev_variants_offered: true`, the store shows the DEV column; `polari-dev-gears_0.1.0+g…_all.deb` generated on request (Package polari-dev-gears, Provides polari-app-gears, Conflicts both install names, Polari-Variant dev, preinst/postinst/postrm inside). OWED: a refused CRUDE verb actually going through with the header and the row (the gate is in `off` mode on this stack — POLARI_APP_PERMISSIONS); a join request admitted at once; the dev deb's preinst refusing on a production machine (proven only in the selftest run). Not built: dynamic TrustChannel rows for dev-admitted peers (the SecurityEvent carries it), content/browser policy hooks (still unwired counters), the `polari-ops` scoped-sudo landing of the core key in production posture (isle side).

**§48 addendum (2026-09-15, his ask: "track which permission profiles and roles perform what actions — the primary route of working out permission profiles for app level security"):** `PermissionObservation` (28th security class): in dev posture the CRUDE gate records EVERY act — even with `POLARI_APP_PERMISSIONS=off` — as roles × class × verb with the profile that granted and the verdict (granted-by-profile / admin / would-deny / unauthenticated / ungated), counted. `/api/security/observations` lists them (filters groups/class_name/verb/verdict), totals by verdict, and DERIVES one proposed `AppPermissionProfile` per role set in the row's own shape (kc_groups_json / verbs_json / extra_classes_json, unpublished, with the evidence: classes × verb counts, acts, what production would deny, callers) — a suggestion; creating the row is the person's act. The security-events page gained the observations table + the derived panel. Selftest 72/75 (same 3 pre-existing). OWED: live rows from real browser traffic on the dev-posture stack (needs a Keycloak login for roles; anonymous reads land as `unauthenticated`), the `app` column (class → app mapping) is still empty.

**§48 addendum 2 (2026-09-16, his: "permission observations should count how many times they occurred, and not be duplicating themselves"):** two live defects fixed. (1) Rows were created as plain objects on the live stack (an import that does not exist made the code fall through) — the class view broke (`PolyTyping for type SimpleNamespace`); rows are now constructed as tree objects like every module row, and the test-double fallback never enters the manager's tables. (2) A per-name persist rate limit dropped the trailing increments of a burst, so counts fell back after a restart (7 in memory, 4 on disk); now one trailing persist per burst. PROVEN live: five reads → count 9; forced backend restart → still 9, 3 rows, 3 unique names.

## §49 — role-play → profiles (2026-09-16)

Backend for ISLE_HARDENING_PLAN §17b (his rules 2–6: track permission profiles/roles by action; count without
duplicating; enable/disable on the fly; frontend role-play tracking reviewed into a concreted, enforced profile;
prototype roles + the role-play permission as its own grant). All below is on `dev`, pushed.

| piece | what exists | proof |
|---|---|---|
| role-play sessions | `ObservationSession` rows; `start_session`/`end_session`; header `X-Polari-Roleplay: <role>` via `accessControl/roleplay_observer.py` middleware; the CRUDE gate attributes acts to `roleplay:<role>` beside real groups | built, tested |
| usages | `UsageObservation` rows (role × kind × item; app/page/component/action/endpoint/object); endpoints recorded by the middleware | built, tested; frontend posting of the rest NOT built |
| prototype roles | `RolePrototype` rows, `prototype → concreted → enforced`; `create_prototype`/`mark_prototype`/`prototypes` | built, tested |
| the role-play permission | `can_roleplay`: admins always; dev instance with no `roleplay_groups` → everyone; a list → those KC groups; production → nobody; `POST /api/security/observe {"roleplay_groups": [...]}` | built, tested |
| review / verify | `review(role)` (apps/pages/components/actions/endpoints/objects×verbs/acts/would-deny-today/`proposed_profile`); `verify(role, group)` replays every recorded class×verb through `permission_verdict` | built, tested |
| surfaces | all eight `/api/security/observe*` doors (session, usage, review, verify, roles, roles/{name}) plus `/observe` GET/POST | built |
| selftest | security 88/91 — the 3 failures are the same pre-existing environment ones named in §48: ledger mac_enforced, mac profiles, expired internal certs | `cd polari-rf-node/polari-framework && PYTHONPATH=.:modules python3 modules/security/security_selftest.py` |

OWED:
- The live proof of a role-play session end-to-end from the browser (act as a role in the UI, confirm
  `PermissionObservation`/`UsageObservation` rows land, review fills in) — blocked on the frontend below.
- The frontend build: `roleplay.service.ts`, `roleplay.interceptor.ts`, page/action usage posting, the header
  role menu, the Review link (full spec in `AI-Notes/handoffs/ROLEPLAY_PERMISSIONS_HANDOFF.md`).
- The review filling in against real usage (apps/pages/objects populated from actual traffic, not just endpoint
  hits) — needs the frontend half and a Keycloak-authenticated role-play session (anonymous reads land as
  `unauthenticated`).
- A concreted profile + verify on a real KC group: create an `AppPermissionProfile` from a reviewed prototype,
  mark it `concreted`, run `POLARI_APP_PERMISSIONS=advisory` then `enforce`, verify against the group, mark
  `enforced` — not yet run against a live group.

**§49 live proof (2026-09-16, the backend half, home staging stack in dev posture):** `POST /api/security/observe/roles {name: journalist}` → prototype; `POST /observe/session {role: journalist}` → session + the header to send; two CRUDE reads and one `/api/apps` call with `X-Polari-Roleplay: journalist` → endpoints `GET /SecurityDomain ×2`, `GET /api/apps ×1` and object `SecurityDomain: read ×2` attributed to the role; a batch of 4 usages (app, page ×2, action) → review shows apps `[journalist]`, pages `[/journalist/articles ×2]`, actions `[publish-article]`, the session counting 2 acts / 7 usages, `proposed_profile` `{kc_groups_json: ["journalist"], verbs_json: ["read"], extra_classes_json: ["SecurityDomain"]}`; `verify?role=journalist` → "1 recorded act(s) would now be DENIED" (correct: nothing concreted yet). The `app` column now fills from the feature-import table (selftest 89/92, same 3 environment failures).

## §50 — Keycloak logins on the lean profile (2026-09-17, his ask: real logins on the home demo stack)

Until now `POL_PROD_AUTH=keycloak` meant the WHOLE full stack (Keycloak + shared MariaDB + MinIO + the
scorecard, ~3 GB) — too heavy for the home demo, so the demo ran with no accounts at all and every permission
observation landed as `unauthenticated`. Stack size is now its own answer.

| piece | what exists | proof |
|---|---|---|
| the answer | `POL_PROD_PROFILE=lean\|full` in `prod.sh` (plumbed through `load_answers` with a `case` validation, `save_answers`, `profile_save`, `do_facts`, the guide's "fresh" reset and its new "Stack size" menu, the plan line). Unanswered it defaults to `full` when logins are on and `lean` otherwise — today's behaviour, so no existing stack changes. `profile()` returns it; `logins_on_lean()` is the new lean+keycloak predicate. The old internal use of the name `POL_PROD_PROFILE` (a SAVED-ANSWERS profile name) was renamed `POL_PROD_PROFILE_NAME` | `pol prod plan` prints `profile: lean` + `logins keycloak (on the LEAN stack…)` |
| the services | `docker-compose.lean.yml`: `pol-keycloak` (1024M) + `pol-kc-mariadb` (384M, own volume `kc_lean_db`), BOTH behind `profiles: ["logins"]`. Config `keycloak_lean_conf` ← the new `pol-keycloak/environments/keycloak-lean.conf` (its own DB, HTTP only, `proxy-headers=xforwarded`, `health-enabled`). `prf-backend` gained `POLARI_AUTH` + the five `POLARI_KEYCLOAK_*` vars + `CORS_ORIGINS`, all `${VAR:-}` so a stack without logins is unchanged | `docker compose … config --services` WITHOUT `COMPOSE_PROFILES` → the original four; WITH → six |
| the swarm path | swarm has no profiles: `.env.lean` carries `COMPOSE_PROFILES=logins` (so `docker compose config` keeps them) AND `render_stack` passes `--with-profile logins` to `stackify.py` (so stackify keeps them) — the same two-key pattern odoo already used | `.generated/stack-lean.yml` lists all six services |
| credentials | `ensure_kc_admin_env()` writes `pol-keycloak/keycloak-admin.env` from the example with a random `KEYCLOAK_ADMIN_PASSWORD` / `KEYCLOAK_ADMIN_CLIENT_SECRET` / `KEYCLOAK_POLARI_BACKEND_CLIENT_SECRET` (a placeholder or the dev default `admin` is moved aside, never reused); `ensure_kc_certs()` generates `pol-keycloak/certs/pol-kc.{crt,key}` (Dockerfile.pol-kc COPYs them unconditionally); `KC_DB_PASSWORD`/`MARIADB_ROOT_PASSWORD` generated once and RE-READ from the previous `.env.lean` on every re-apply (baked into the DB volume on first boot); `vault_lean_logins()` records the lot | `git check-ignore` clean for `keycloak-admin.env` and `.generated/demo-users.env` |
| the edge | `pol-proxy/nginx.lean.conf.template` gained `auth.${PROD_DOMAIN}` on :80 and an `${AUTH_SERVER_BLOCK}` marker; `pol proxy template lean --auth keycloak` substitutes an `auth.` server block (lazy `set $up_keycloak http://pol-keycloak:8080` + resolver, `X-Forwarded-Proto https`, 128k/4×256k buffers for Keycloak's headers), and drops the marker otherwise. DECISION: plain HTTP inside the encrypted overlay, NOT the full profile's mTLS hop to :8443 — those certs come from `setup-polari-security.sh`, which the lean path never runs | `pol proxy guard lean` → nginx -t OK |
| the realm | `configure_clients.sh` adds `PRF_URL`-derived redirect URIs, DERIVES `webOrigins` from the redirect URIs (replacing the blanket `"*"` on polari-frontend only), sets `post.logout.redirect.uris="+"`, and creates/updates a **group-membership protocol mapper** (`claim.name=groups`, `full.path=false`) — without it the `groups` claim never appears and every `AppPermissionProfile` grant silently misses | KC log: `groups protocol mapper created (HTTP 201)` |
| demo accounts | `pol-keycloak/startup_shells/seed_demo_users.sh` (run last by `kc_entrypoint.sh`, COPYd by the Dockerfile): idempotent; refuses unless `POLARI_DEMO_USERS=on` AND `DEMO_USER_PASSWORD` is non-empty; creates groups `journalist`/`data-scientist`/`operators` and users demo-admin (polari-admin), demo-journalist (journalist + polari-user), demo-scientist (data-scientist + polari-user), demo-viewer (polari-viewer), e-mails `@example.invalid`, one shared password from `.generated/demo-users.env` | see below |

**PROVEN LIVE 2026-09-17 on the home swarm** (`polari-lean`, domain `192.168.0.210.nip.io`, posture dev,
images built here, tag lean; `pol prod apply` from the answers):
- `docker service ls`: pol-hub, pol-kc-mariadb, pol-keycloak, pol-proxy, prf-backend, prf-frontend — all 1/1.
- Discovery: `https://auth.<D>/realms/Polari/.well-known/openid-configuration` → `issuer` EXACTLY
  `https://auth.<D>/realms/Polari` (i.e. the proxy-headers path produces https, not http).
- `https://prf.<D>/assets/runtime-config.json` carries the `keycloak` stanza (authority, clientId
  polari-frontend, redirectUri `https://prf.<D>/callback`, postLogout `https://prf.<D>/`, code, scope
  `openid profile email roles`, silent `…/assets/silent-refresh.html`).
- Password grant as `demo-journalist` → access token whose payload has `groups: ["journalist"]`,
  `realm_access.roles` incl. `polari-user`, `iss` the https issuer, `email demo-journalist@example.invalid`.
- `GET /api/apps/permissions/my` with that bearer → `authenticated true`, `admin false`,
  `groupSources ["jwt-groups-claim","jwt-roles"]`, groups incl. `journalist`; anonymous → `authenticated false`,
  no groups. demo-admin → `admin true`; demo-scientist → `data-scientist`; demo-viewer → `polari-viewer`.
- Two CRUDE reads of `/SecurityDomain` with the bearer → `/api/security/observations` shows a row
  `default-roles-polari,journalist,offline_access,polari-user,uma_authorization | SecurityDomain read ×2`,
  verdict `would-deny` (correct: no published profile yet, and the gate is `off` so the read proceeded),
  posture dev — beside the pre-existing `unauthenticated` rows. **This is the first live evidence of a real
  identity in the observation ledger** (§48/§49 owed it).
- The authorization endpoint renders the real login form for
  `redirect_uri=https://prf.<D>/callback` (no "Invalid parameter: redirect_uri"); `/callback` and
  `/assets/silent-refresh.html` are both served 200 by the frontend.

**OWED:**
- **The browser sign-in itself has NOT been seen.** No browser was opened. The code exchange at `/callback`,
  the header login button, token storage and silent renew are all UNPROVEN by eye. That is the one check a
  person must do.
- A `POL_PROD_AUTH=off` re-apply proving the four-service stack comes back byte-identical (only the
  `docker compose config --services` half was proven; the stack was never redeployed without logins).
- The FULL profile after this change (`POL_PROD_PROFILE=full`) was not re-applied — the default path is
  unchanged by construction but untested since.
- `security_api.default_scenario()` maps `POLARI_AUTH=keycloak` → `swarm-full`, so a lean+logins stack reads
  as `swarm-full` on the security page while `pol prod harden` renders `swarm-lean`. Left alone deliberately;
  it should learn about the lean+logins shape.
- `PermissionObservation.actor` holds the KC `sub` UUID, not the username: `jwt_validator.validate()` returns
  `username` but `observe_permission()` reads `preferred_username`. One-word fix, not made here.
- The vault writes need root; on this box they logged `sudo: a password is required` and the credentials live
  only in `pol-keycloak/keycloak-admin.env` and `.generated/.env.lean` (both 600, both gitignored).
  `sudo pol security vault init` then a re-apply would land them.
- No `AppPermissionProfile` is published, so every authenticated act is `would-deny` under `advisory`/`enforce`.
  Concreting one from a role-play review (§49) against the real `journalist` group is the next step — now
  possible for the first time, because the group and a real member exist.
- Nothing was rotated: `pol security rotate` has still never been run against a live Keycloak.

## §51 — the loop proven with a real login (2026-09-17)

His ask, end to end: "role-play as a Journalist → review shows everything used → a permissions admin concretes
it into an enforced Journalist group → verify they can still do their job." Run entirely through the APIs with
a REAL Keycloak login (§50), on the home swarm `polari-lean` (`192.168.0.210.nip.io`, posture dev, gate
`advisory`). No browser was opened — that pass is still his.

| step | result |
|---|---|
| 0. the actor fix | `observe_permission()` read only `preferred_username`, so rows against a real login showed the KC `sub` UUID (§50 owed it). Now falls back through `username`. selftest 89/92 (the 3 = the pre-existing environment failures). Committed, pushed, redeployed BEFORE the run — every row below reads `actor=demo-journalist` |
| 1. real login | password grant for `demo-journalist` → claims `iss https://auth.<D>/realms/Polari`, `azp polari-frontend`, `preferred_username demo-journalist`, `email demo-journalist@example.invalid`, **`groups: ["journalist"]`**, `realm_access.roles` incl. `polari-user`. PASS |
| 2. knob | `GET /api/security/observe` → `posture dev`, `recording true` (`source "default (dev = on)"`). PASS |
| 2. the role-play grant | `POST /api/security/observe {"roleplay_groups": ["journalist","developers"]}` as demo-admin → accepted. `GET /observe/roles` **with** the demo-journalist bearer → `can_roleplay true`, why `granted by group(s) journalist`; **without** a bearer → `can_roleplay false`, why `the role-play permission is granted to ['journalist','developers']; you are in no group`. PASS — this is the first time the permission has been resolved against a real KC group instead of the dev-instance everyone-may fallback |
| 3. act as the role | stale 2026-09-16 session closed first; `POST /observe/session {"role":"journalist"}` → `journalist\|2026-09-18T00:14:15Z`. Eight reads with the bearer + `X-Polari-Roleplay: journalist` (`/api/apps?q=scorecard`, `/api/apps/nav`, `/SecurityDomain` ×2, `/PermissionObservation`, `/TermsDocument` ×2, `/PolariAppDefinition`) all 200; 3 usages POSTed (app `scorecard`, page `/app/scorecard`, action `open-policy`) → `recorded 3`; `DELETE /observe/session?role=journalist` → ended. PASS |
| 4. review | `acts 6`, `would_deny_today 6`. apps `[journalist, scorecard]`; pages `[/journalist/articles ×2, /app/scorecard, /display/security-events]`; actions `[open-policy, publish-article]`; components `[]`; endpoints `GET /SecurityDomain ×4, /TermsDocument ×2, /api/apps ×2, /PermissionObservation, /PolariAppDefinition, /api/apps/nav`; objects `{PermissionObservation:{read:1}, PolariAppDefinition:{read:1}, SecurityDomain:{read:2}, TermsDocument:{read:2}}`; **objects_by_app** `{polariapps:[PolariAppDefinition], security:[PermissionObservation, SecurityDomain], terms:[TermsDocument]}`; `proposed_profile` `{kc_groups_json:["journalist"], verbs_json:["read"], extra_classes_json:[the 4 classes], published:false, is_prior:false}`. (The review is cumulative — the `journalist`/`/journalist/articles`/`publish-article` entries are §49's synthetic run, honestly still counted.) PASS |
| 4. both groups on the row | the four observation rows carry `groups = default-roles-polari,journalist,offline_access,polari-user,roleplay:journalist,uma_authorization` — the real KC group AND `roleplay:journalist` — with `actor demo-journalist`, verdict `would-deny` (correct: nothing concreted yet). PASS |
| 5. concreted | `AppPermissionProfile` created through CRUDE (multipart, one `initParamSets` form field — `polariApiServer/polariCRUDE.py:448`; a JSON body is refused 415) with the demo-admin bearer → 201. `GET /api/apps/permissions/profiles` lists `journalist` published, kcGroups `[journalist]`, verbs `[read]`, coveredClasses the four. `GET /api/apps/permissions/my` as demo-journalist → `profiles [{profile: journalist, verbs:[read], via:[journalist]}]`, `classes` the four. Prototype marked `concreted` (profile `journalist`). PASS |
| 6. verify | `GET /observe/verify?role=journalist&group=journalist` → `recorded_acts 4`, **verdict "the role can still do everything it was recorded doing"**, `denied []`, all four allowed `via [journalist]`, why `granted by profile(s)`. **Nothing had to be widened.** Prototype marked `enforced` with that verdict. PASS |
| 7. the gate knob | `pol prod` had NO answer for `POLARI_APP_PERMISSIONS`. Added `POL_PROD_APP_PERMISSIONS=off\|advisory\|enforce` exactly as `POL_PROD_POSTURE` was done: the declaration, `load_answers` default + `case` validation, all four `POL_PROD_*` key lists (`save_answers`, `profile_save`, `do_facts`, the guide's "fresh" reset), and the env heredocs for **both** lean and prod; `docker-compose.lean.yml` + `docker-compose.prod.yml` pass `POLARI_APP_PERMISSIONS=${POLARI_APP_PERMISSIONS:-off}` to `prf-backend`. Default `off` — a stack with no concreted profiles must not start refusing reads because it was deployed |
| 7. advisory live | answer set to `advisory`, `pol prod apply` → `.env.lean` and the running service both carry `POLARI_APP_PERMISSIONS=advisory`. As demo-journalist: the four IN-profile classes → **200 with NO advisory header**; `AppPermissionProfile`, `SecurityEvent`, `ObservationSession` (out of profile) → **200 with `X-Polari-Permission-Advisory: would-deny <Class>:read`** — the act still proceeds. PASS. **Deliberately NOT switched to `enforce`** (his ruling: security stays warn-only in deployments); advisory is as far as the demo goes |

**Found on the way (all real, none fixed here):**
- **A concreted profile can be lost to a redeploy.** The row created at 00:15 was GONE after the `pol prod apply`
  four minutes later; re-created, it then survived a *second* `pol prod apply` intact. CRUDE writes reach
  `/app/data/managerObject_DB.db` only on a later flush, so a profile concreted shortly before a deploy is
  silently lost. A permissions admin has no way to know. OWED: a write-through (or an explicit "persist now")
  on CRUDE create, and a selftest for it.
- **`/api/security/observations?groups=<name>` can never match.** The filter is exact string equality against
  the whole comma-joined groups field (`security_api.py:204-207`), so `?groups=journalist` returns 0 rows while
  the row's groups plainly contain `journalist`. It should be a membership test. Every filtered result in this
  run had to be computed client-side.
- **An expired bearer degrades silently to "would-deny everything".** A stale token makes
  `/api/apps/permissions/my` answer `authenticated false` with no groups, and every read — in-profile or not —
  grows the advisory header. Under `enforce` that is a 403 storm indistinguishable from a real permission
  problem. The advisory/403 payload should say "unauthenticated" rather than "would-deny".

**Still OWED:** the browser pass is HIS (sign in on `https://prf.<D>`, the role menu in the header, act as the
role by clicking, the Review link) — nothing below the API layer has been seen by eye. Also still owed from
§50: the `POL_PROD_AUTH=off` re-apply, the full profile re-apply, the vault writes (need root), and a rotation.
`enforce` has never been run on any deployed stack, by his ruling.

## §51 addendum — the three defects (2026-09-18, fixed, selftested and proven live)

The three defects §51 recorded are fixed on `dev` (polari-framework `9a093bd`, node `a8ee1ef`, suite `85b6772`)
and the home swarm `polari-lean` was redeployed from this checkout to prove them. Posture stays `dev`, the gate
stays `advisory` — **not** `enforce` (his ruling: security is warn-only in deployments).

| defect | the fix | the proof |
|---|---|---|
| 1. a CRUDE-created row lost to a redeploy | new core helper `polariApiServer/persist_debounce.py`: `schedule_persist()` runs ONE `persistTree()` per burst (~3 s window, daemon timer, never blocking a request), `flush_now()` persists synchronously, `install_sigterm_flush()` flushes once on SIGTERM and then hands the signal back to the default handler. Called from `polariCRUDE` `on_post`/`on_put`/`on_delete` (successful writes only), from `initLocalhostPolariServer` at boot, and from `security_observe._schedule_persist`, which now delegates instead of carrying its own copy. Knobs `POLARI_PERSIST_DEBOUNCE_SECONDS`, `POLARI_PERSIST_ON_SIGTERM` | new `polariApiServer/selftest_persist_debounce.py` **13/13**: the burst semantics (6 writes → 1 flush), the failure path, a row created / updated / deleted through the REAL CRUDE handler against a fake manager (asserting the tree was persisted), a refusal persisting nothing, and SIGTERM proven in a subprocess (flushed once, process still dies with 143). LIVE: the `journalist` `AppPermissionProfile` created through CRUDE (multipart, one `initParamSets` field), left 75 s, then `docker service update --force polari-lean_prf-backend` → **present afterwards in both the API and `/app/data/managerObject_DB.db`**. The container logs `[Persist] SIGTERM flush armed` at boot |
| 2. `?groups=<name>` could never match | `security_api.on_get_observations` treats `groups` as a MEMBERSHIP test (every named group must be in the row's comma-separated set); the other filters stay exact equality | selftest check added (a real multi-group login row: exact name matches, a second group matches, an absent group does not, a combined `groups`+`verb` filter still narrows). LIVE: no filter → 5, `?groups=journalist` → **2** (was always 0), `?groups=roleplay:journalist` → 2, `?groups=nobody` → 0, `?groups=journalist&verb=create` → 0, on rows whose groups read `default-roles-polari,journalist,offline_access,polari-user,roleplay:journalist,uma_authorization` |
| 3. an expired bearer read as "would-deny everything" | the observation verdict was already honest (`unauthenticated`); the GATE was not. `auth_middleware` now sets `X-Polari-Auth: invalid-or-expired` (and `req.context.auth_failed`) when a Bearer was present and `validate()` refused it; the gate's advisory header says `unauthenticated <Class>:<verb>` instead of `would-deny`, and the `enforce` refusal answers `error: unauthenticated` with "sign in again" instead of a permission verdict. Both headers added to `Access-Control-Expose-Headers` (and `X-Polari-Roleplay` to Allow-Headers) so a browser can read them | selftest checks added (middleware with a stub validator; the gate in advisory for expired / anonymous / authenticated-without-grant; the enforce payload). LIVE on the advisory stack: expired bearer → `x-polari-auth: invalid-or-expired` + `x-polari-permission-advisory: unauthenticated AppPermissionProfile:read (token invalid or expired)`; **no** bearer → `unauthenticated AppPermissionProfile:read` with no auth header; a VALID bearer out of profile → `would-deny AppPermissionProfile:read`; a valid bearer in profile → no header at all. The observation rows separate `unauthenticated` (groups `''`) from `would-deny` (the real group set) |

security selftest **94/97** (89/92 before, +5 new checks; the 3 failures are the known environment ones — ledger
`mac_enforced`, mac profiles complain, expired internal certs). `selftest_quiesce` 27/27 and
`selftest_batched_persist` 17/17 unchanged. `moduleService/selftest_lazy_boot.py` fails to import on the host
both before and after this change (pre-existing, unrelated).

**Found on the way — two NEW defects, both reproduced, NEITHER fixed (they are deeper than this slice):**

- **`persistTree()` is DELETE+REPLACE per class from `objectTables`, so it can erase rows it does not hold, and
  two processes share one sqlite file during a rolling update.** CRUDE's own `saveInstanceInDB` commits the row
  immediately, but the whole-tree flush (9 451 instances, ~60 s on this box) empties each class table before
  rewriting it. A redeploy that starts INSIDE that window loses the row for good: the booting container reads
  the table mid-flush (it logged `[DB] Restoring 2 instances of AppPermissionProfile` when three existed) and
  its own boot flush then writes that short state back. Seen live — a `journalist` row created ~40 s before a
  forced redeploy was gone afterwards, while the same row created 75 s before one survived. OWED: make a class
  batch atomic (DELETE + insert in ONE committed transaction), refuse to flush a class whose in-memory table is
  empty while the DB has rows, and keep a booting process from overwriting a file another process is flushing.
- **A CRUDE DELETE of ONE row empties the whole class from the live view.** `DELETE /AppPermissionProfile` with
  `targetInstance={"name": "<one row>"}` answered 200 and the next `GET /AppPermissionProfile` returned `[]` —
  every sibling gone from the tree, twice in a row, and the next flush made it permanent on disk. Likely
  `managerObject.deleteTreeNode`'s "duplicates" sweep removing every sibling node of the branch (not isolated).
  This is how the three demo profiles were lost during this run; `journalist` was recreated by hand (same name,
  kc_groups `["journalist"]`, verbs `["read"]`, the four classes, published) and re-verified: `granted-by-profile`
  for `demo-journalist`, and it survives a redeploy. OWED: a failing test for the blast radius, then the fix.
- Minor, noted not fixed: `polariCRUDE.getUsersObjectAccessPermissions` gives an ANONYMOUS caller `C/R/U/D/E`
  and an AUTHENTICATED one only `R/E`, so a CRUDE delete with a valid admin bearer answers 405 while the same
  delete with no bearer at all succeeds. The legacy access matrix predates the permission gate and inverts it.

**Still OWED from §51:** the browser pass is HIS. `enforce` still never run on a deployed stack, by his ruling.

## §52 — self-claimable roles (2026-09-18, his ask: assign yourself a role from inside Polari)

His words: *"I see no way, upon registering, to simply assign myself a role in the Polari interface. Or a way to go
from Polari to Keycloak to grant oneself permissions that anyone can just self-claim. It should not be the case all
roles can be taken by anyone, but self-proclaimable roles should be a thing, especially in dev mode."*

A role IS a Keycloak group (the permission model reads the `groups` claim), so claiming one = joining that group,
done for the caller by the `polari-backend` service account. Decision recorded as **D17-5** in
`AI-Notes/plans/ISLE_HARDENING_PLAN.md` §17b; operator instructions in
`AI-Notes/guides/ROLEPLAY_PERMISSIONS_GUIDE.md` → "Claiming a role yourself".

**The rule.** DEV: every `RolePrototype` row, in any state, unless an admin explicitly said no, plus the
`claimable_groups` knob. PRODUCTION: only rows flagged `self_claimable: true`, plus the knob — nothing by default.
NEVER in either posture: `ADMIN_ROLES` (`admin`, `polari-admin`), the KC groups `Polari Administrators` /
`Polari Developers`, and any `polari-*` name that is not a prototype an admin flagged. The caller must be
authenticated (a `sub`), or the answer is 401 and an empty list.

**PII (his rule, 2026-09-18 — Keycloak exists to keep personal data away from Polari).** Every row and event this
arc writes keys the person by the opaque Keycloak `sub` ALONE: the `SecurityEvent` actor is the sub, the observe
knob records the sub as `by`, and `/api/security/roles/claimable` echoes the caller's own sub instead of a
username. `kc_admin` keeps only group ids/names — it never logs or persists a KC user object. The frontend sends
only a role name; the display name in the dialog is the browser's own token. (The four §17b observe rows that
still store a username remain a correction owed — plan §17c.)

**Built** (framework `6b120dc`, angular `98dd03b`, node `5003166`, suite pin below):

| piece | where |
|---|---|
| the flag | `RolePrototype.self_claimable: bool = False`; explicit NOs in the observe knob's `claim_denied` list (a bool column cannot hold "never decided" vs "decided no", and dev posture needs that difference) |
| the knob | `security_observe.claimable_groups` / `set_claimable_groups`, mirroring `roleplay_groups` / `set_roleplay_groups`, in the same `<data>/security/observe.json`; plus `claim_denied_roles` / `set_claim_denied` |
| the rule | `modules/security/custom/security_claims.py` — `claimable_roles`, `may_claim`, `claim`, `release`, `forbidden_reason`, `how`. Every refusal names the rule that refused |
| the mechanism | `modules/security/custom/kc_admin.py` — urllib only, timeouts, never raises into the API: `token` (client_credentials on `polari-backend`, cached, one 401 retry), `groups`, `find_group`, `create_group`, `user_groups`, `add_user_to_group`, `remove_user_from_group`, `account_url` |
| the doors | `GET /api/security/roles/claimable`, `POST` / `DELETE /api/security/roles/claim`; `POST /api/security/observe/roles/{name} {"self_claimable": …}` (ADMIN-ONLY); `POST /api/security/observe {"claimable_groups": [...]}`; `GET /api/security/observe` now reports `roleplay_groups`, `claimable_groups`, `claim_denied` |
| the UI | `src/app/services/role-claims.service.ts`; `src/app/components/header/claim-role-dialog.component.ts` (standalone MatDialog: Claim/Release per role, "held" marked, refusal inline, "Manage account in Keycloak", "Sign in again" when the silent renew fails); `header.html` user menu gains "Claim a role…" + "Manage account"; `AuthSessionService.renewSession()` (public `signinSilent` wrapper) |

**Selftests.** `modules/security/security_selftest.py` **111/114** (was 94/97; +17 checks, the 3 failures are the
known environment ones — ledger `mac_enforced`, mac profiles complain, expired internal certs). The new checks:
the dev list (every prototype, never admin / never `Polari Administrators` / never an unflagged `polari-*`), `held`
from the caller's own token groups, an unauthenticated caller getting nothing, an admin's explicit NO removing a
role from the dev free-for-all, the knob adding plain groups while still refusing an admin one, the production list
(flagged + knob only), the four refusal sentences, claim/release against a monkeypatched `kc_admin._http` (token →
group search → group create → PUT membership; second claim finds instead of creates; release DELETEs), a missing
credential answering 503 naming the env var, an admin role refused before Keycloak is touched, the SecurityEvent
ledger keyed by `sub` with no username anywhere in it, the four routes (claimable / 401 / 403 / the account URL),
and the admin-only `self_claimable` route both ways.

**Live proof (2026-09-18, home swarm `polari-lean`, dev posture, gate `advisory`, deployed with `pol prod apply`).**
Entirely through the APIs, as `demo-viewer` (password grant, `polari-frontend`):

| step | result |
|---|---|
| `GET /api/security/roles/claimable` with NO bearer | `200 {ok, posture: dev, authenticated: false, sub: "", roles: [], held: [], account_url: "https://auth.<D>/realms/Polari/account", keycloak: {ready: true}}` — nothing offered to nobody |
| token 1 for `demo-viewer` | no `groups` claim at all |
| `GET /claimable` with token 1 | `journalist` listed, `held=false`, `source=prototype`, `state=enforced` (a CONCRETED, ENFORCED role is still claimable in dev — that is the rule) |
| `POST /claim {"role":"journalist"}` | `200 {ok, role: journalist, group_id: a4ef779c-…, group_created: false, why: "dev posture: every prototype role is claimable unless an admin says otherwise", note: "sign in again or refresh your session…"}` |
| a NEW token for `demo-viewer` | `groups: ["journalist"]` — the claim really landed in Keycloak |
| `GET /claimable` with the new token | `held: ["journalist"]`, the row `held=true` |
| `DELETE /claim?role=journalist` | `200 {ok, released: true}` |
| a NEW token again | no `groups` claim — the membership is gone |
| `POST /claim` with NO bearer | **401** `"sign in first: a role is claimed for a Keycloak account, and this request carries none"` |
| `POST /claim {"role":"polari-admin"}` | **403** `"polari-admin is an administrator role — administrator roles are never self-claimable"` |
| `GET /api/security/events?control=role-claim` | two rows, `actor` = the Keycloak `sub` UUID (`820f970b-…`) and **no username anywhere**, `source=self-claim`, `would_deny=false` |
| `POST /api/security/observe/roles/journalist {"self_claimable": true}` as `demo-viewer` | **403** `"only an administrator may change whether a role is self-claimable (ADMIN_ROLES: admin, polari-admin)"` |
| the same as `demo-admin` | `200`, the row comes back with `self_claimable: true` — proving the new column reached the live sqlite schema through the ALTER-TABLE path, on a row created two days earlier |
| `https://prf.192.168.0.210.nip.io` | the served bundle `main.5a88a180c506302a.js` contains `Claim a role` |

**Defect found and fixed during the live run.** The first attempt answered
`502 … "Public client not allowed to retrieve service account"`: `kc_admin.config()` was reading
`POLARI_KEYCLOAK_ADMIN_CLIENT_ID`, which on this stack is `admin-cli` — a PUBLIC client with no service account —
while the secret it holds belongs to `polari-backend`. The client id is now pinned to the credential's own client
(`POLARI_KEYCLOAK_BACKEND_CLIENT_ID` overrides), framework `c7391d4`. No change was needed to
`configure_clients.sh`: the `polari-backend` service account already carries realm-management
`view-realm, manage-users, view-users, query-groups, query-users` (read back from its own token).

**Not redeployed after:** a cosmetic wording fix (`"claimd"` → `"claimed"` in the event reason, framework
`51fa77b`) landed AFTER the proving deploy, so the two live `role-claim` rows carry the typo until the next
`pol prod apply`. The tree is correct; the stack was not churned again for a string.

**State left on the live stack:** `journalist` is now flagged `self_claimable: true` (set by the admin-route test),
so it stays claimable if the stack is ever flipped to production posture. `demo-viewer` holds no role — the claim
was released again.

**OWED**
- **The browser pass is HIS**: the dialog has never been seen by eye — the layout, dark mode, the Material dialog
  inside the header menu overlay, and the "Sign in again" fallback are all unconfirmed visually.
- **The token-refresh behaviour in a browser is UNPROVEN.** `renewSession()` calls `signinSilent` (prompt=none);
  whether Keycloak re-issues with the new group without a full sign-in on this realm has only been reasoned about,
  not watched. The API proof used a fresh password grant instead.
- Release of a role granted by an administrator is deliberately refused (only self-claimable roles can be
  self-released) — no test that an admin-granted group survives a release attempt against the live realm.
- `claim_denied` lives in the observe knob file, not in the row. If the knob file is lost the explicit NOs are lost
  and dev posture reopens those roles. A `RolePrototype` column that can hold three states would be better; that is
  superseded anyway by §17c's `RoleGrantPolicy` (slice rg-0).
- Nothing rate-limits claims. A signed-in person can take every claimable role at once; in dev that is the point,
  in production the list is expected to be short and deliberate.

## §51 addendum 2 — delete wipe + atomic persist + the matrix (2026-09-18, fixed, selftested, proven live)

The two defects §51 addendum found and did NOT fix, plus the access-matrix inversion it noted, are fixed on `dev`
(polari-framework `4d9f864`, node `bc86fa4`, suite `57feb05`) and the home swarm `polari-lean` was redeployed from
this checkout. Posture stays `dev`, the gate stays `advisory` — **not** `enforce` (his ruling stands).

| defect | root cause (exact) | the fix | the proof |
|---|---|---|---|
| **A. a CRUDE DELETE of ONE row emptied the WHOLE class** | NOT `deleteTreeNode` — the guess in §51 was wrong. `objectTreeManagerDecorators.getListOfInstancesByAttributes` (line 1816) handed the query engine `self.objectTables[className]` **itself** (`remainingInstances = allClassInstancesDict`), and `dictAttributeRequirementsForQuery` narrows by `remainingInstances.pop(someInstId)` on every non-match. So *resolving the delete target* (`targetInstance={"name":"x"}`) permanently deleted every sibling from the live object tree; `deleteTreeNode` then removed the one survivor and the next `persistTree` made the empty table permanent. `on_event` resolves its target the same way and had the same blast radius. `_applyFieldFilter` already carried a local `dict(...)` workaround — the previous author saw the symptom and patched one call site | the query engine narrows a **copy**: `remainingInstances = dict(allClassInstancesDict)`, and the `"*"` branch returns `dict(...)` too (callers narrow what they get back) | new `polariApiServer/selftest_crude_delete_blast.py` **21/21** (11/21 before the fix): the name / id / unmatched / `"*"` queries all leave the class table whole; a DELETE of one row through the **REAL** `on_delete` against the **REAL** query engine and a real sqlite file leaves both survivors in the live table AND on disk; an unmatched target is a 404, not a wipe. **LIVE** — see below |
| **the legacy access matrix was inverted** | `polariCRUDE.getUsersObjectAccessPermissions` gave an ANONYMOUS caller `C/R/U/D/E` and an AUTHENTICATED one only `R/E`, so a CRUDE DELETE with a valid admin bearer answered 405 while the same DELETE with no bearer succeeded | both branches return the same open matrix, with the invariant written into the docstring: the real per-profile gate is `accessControl/app_permissions_gate.py`, and this legacy matrix must **never** grant anonymous more than authenticated | selftest checks (anon ⊆ auth for both the access and the permission matrix; `D` present for an authenticated caller). LIVE: the delete below ran with the demo-admin bearer and answered **200** |
| **B. `persistTree` was DELETE+REPLACE per class with a commit per class** | the file spent the whole flush partly-new/partly-old, and a class on the row-by-row fallback was visibly EMPTY between its DELETE and its last INSERT — the window a booting container read (`[DB] Restoring 2 instances of AppPermissionProfile` when three existed) before writing the short state back | three parts: (1) every row is serialized **outside** any transaction (`managedDB._buildClassRows` / `prepareClassBatch`) — that is the slow half and it holds no lock; (2) the whole tree is written in **ONE** transaction (`writePreparedBatches`: `BEGIN IMMEDIATE`, a `SAVEPOINT` per class so one bad class rolls back to its own rows only, one `COMMIT`), so a reader sees the old tree or the new tree; (3) a `polari_persist_state` marker (scope/pid/host/started_at/finished_at/classes/rows), committed BEFORE the transaction and cleared after the row-by-row fallback, lets another process see a flush is in flight — `persistTree` **DECLINES** rather than write its own older reading back. Our own pid never blocks us; an abandoned marker ages out at 600 s. sqlite connections also take `PRAGMA busy_timeout` (30 s default, knob `POLARI_SQLITE_BUSY_TIMEOUT_MS`) so a reader waits for the short write instead of erroring "database is locked". A db double without `writePreparedBatches` still takes the historical per-class path | new `polariDBmanagement/selftest_persist_atomic.py` **21/21**: 2 000 rows persisted while a second thread reads the table — the reader never sees a count between 0 and full, never sees the table empty, never hits "database is locked"; preparation writes nothing; a bad class rolls back alone; the marker's full lifecycle incl. staleness; `persistTree` declines while another pid is flushing |

**Numbers (measured, not estimated).** On a `docker cp` copy of the live DB (188 tables, 9 675 rows), running the
REAL `persistTree` code path: legacy per-class commits **3.11 s** vs one transaction **0.75 s** total, of which
write+commit — the only window a reader can see anything partial — is **0.24 s**. So the ~60 s flush §51 measured
is **NOT** sqlite commits; the DB half is ~3 s and the rest is Python-side row building. On the live instance the
new log line reports both halves, e.g.
`[DB] Persisted 10 499 instances to database in ONE transaction (96 classes, 22 707 skipped — no table, 0 errors) —
serialize 134.15s, write+commit 0.53s`. Across the flushes observed live the write window was
**0.23 / 0.53 / 0.87 / 2.07 / 4.48 / 9.16 s**, with one **53.38 s** outlier during a redeploy (two containers
contending for the file). Even the outlier is atomic — a reader sees old-or-new. The exposure window went from the
whole flush (28–134 s of serialization, every class committing as it went) to the write alone.

**LIVE PROOF (A), `polari-lean`, demo-admin bearer, gate `advisory`:**

| step | result |
|---|---|
| before | `GET /AppPermissionProfile` → 4 rows; the sqlite file inside the container agrees |
| create two throwaways through CRUDE (multipart, one `initParamSets` field) | `201`, `201` → 6 rows in the API, and **both on disk within 10 s** |
| **delete ONE** (`targetInstance={"name":"proof-a-…"}`) **with the demo-admin bearer** | **HTTP 200** — before the matrix fix this same request answered 405 with a bearer and only succeeded anonymously. `{"instancesDeleted": ["azJXuycaD"]}`. The API then shows **5 rows** — the other throwaway, the real `journalist`, `wax-print-shop-operator` and `app-climate-viewer` all intact. Before the fix this returned `[]` |
| disk after the delete | 5 rows, within 10 s |
| `docker service update --force polari-lean_prf-backend` | new container online after 75 s → API **5 rows**, disk **5 rows** — nothing lost |
| delete the second throwaway | `200`, back to the three real profiles. `journalist` never moved |

**Found on the way — NOT fixed, needs his say-so (it is deploy config, not code):**

- **`stop_grace_period` is 10 s while the SIGTERM flush needs 30–134 s to serialize.** `docker service inspect
  polari-lean_prf-backend` → `StopGracePeriod 10s`; `docker-compose.lean.yml` sets none, so Docker's default
  applies. §51's SIGTERM flush is therefore SIGKILLed mid-serialization on every redeploy of a full instance — it
  only ever lands when the tree is small. Measured directly: a row created ~10 s before a forced redeploy was gone
  afterwards; the same row created early enough for the debounced flush to reach disk (10 s, verified in the file)
  survived the redeploy intact. The one-line fix is `stop_grace_period: 180s` on `prf-backend` in
  `docker-compose.lean.yml` and `docker-compose.prod.yml`. Not applied — it changes his running stack's shutdown
  behaviour and he should say yes first.
- **The marker guards concurrency, not staleness.** If a new container's boot restore reads the file BEFORE the old
  container's flush commits, and that flush then finishes, the new container's own boot flush writes the older
  reading back — no marker is up at that moment, so nothing declines. Closing this properly needs a persist
  *generation* recorded at restore and a catch-up re-read (not a decline, or the process would never flush again).
  Largely moot if `stop_grace_period` is raised, since stop-first then leaves no overlap.
- **`persistTree` skips ~22 700 instances per flush as "no table"** — those classes never reach disk at all and
  live only in memory. Untouched here; it deserves its own look.
- The empty-class guard §51 asked for ("refuse to flush a class whose in-memory table is empty while the DB has
  rows") was deliberately NOT added: with defect A fixed, an empty in-memory class now means the last row really
  was deleted, and refusing would make that deletion un-persistable.

Counts: `selftest_crude_delete_blast` **21/21** (new), `selftest_persist_atomic` **21/21** (new),
`selftest_persist_debounce` 13/13, `selftest_batched_persist` 17/17, `selftest_quiesce` 27/27,
`selftest_db_adapters` 34, `selftest_shared_db` 16/16, `selftest_db_log_quiet` 16, security **94/97** (the 3 known
environment failures) — all unchanged from before this slice except the two new files.

- **A row deleted while a flush is in flight can be RESURRECTED by that flush.** Observed live at the end of this
  slice: two throwaway profiles deleted through CRUDE (200, gone from the API, and `_deleteFromDB` removed them from
  sqlite — no `[CRUDE-DELETE] … NOT from the database` line in the log) were back after the next redeploy. Cause:
  `persistTree` snapshots `objectTables` at the TOP (`tables = {name: dict(instances) …}`) and writes that snapshot
  minutes later, so a delete landing between the snapshot and the write is undone. This is NOT new — the snapshot
  has always been taken at the top — but the fix's long serialize phase makes the window easy to hit. The delete was
  re-issued and the three real profiles are what the stack carries now. OWED: take the snapshot per class right
  before that class is serialized, or re-check deletions against the tree at write time.

**Still OWED:** the browser pass is HIS. `enforce` still never run on a deployed stack, by his ruling.

## §53 — rg-0a: the PII boundary applied (2026-09-18, his rule D18-1)

His rule: *"largely the purpose of Keycloak is to keep PII secure and away from Polari itself."* So every person in
a Polari row, event or log line is their opaque Keycloak subject id (`sub`) and nothing else — never a
`preferred_username`, an e-mail or a display name. Names are resolved at RENDER time through ONE permission-gated
door and are never cached into the tree. Design `AI-Notes/designs/ROLE_GRANT_ROUTES_DESIGN.md` §8 (its "Corrections
owed" is now DONE) and slice rg-0a; operator instructions in the guide → "Names and the PII boundary".

**Built** (framework `7101480`, node `fc4a002`, suite pin below; no Angular change was needed):

| piece | where |
|---|---|
| the one resolution | `security_observe.actor_of(user_info)` → `sub` or `''`. `observe_permission()`'s `preferred_username` → `username` → `sub` fallback is gone (that fallback is exactly how this week's role-play tests wrote `demo-*` logins into four ledgers) |
| the call sites | `observe_permission`, `record`, `observe_usage`, `start_session`; `security_api._actor()` DELETED — every knob write, prototype, session and usage is attributed with `_sub()`; `accessControl/roleplay_observer.py` (endpoint usage) and `accessControl/app_permissions_gate.py` (the SecurityEvent the CRUDE gate writes) both resolve through `actor_of()` |
| the body no longer decides | `POST /api/security/observe/session` used to take `actor` from the request body — anyone could write any string (a name) into `ObservationSession.actor`. It is now the caller's own `sub`, always |
| distinct subs | `derive_profiles()` evidence gains `actor_count` and says "distinct Keycloak subject(s)"; `review()` gains `actors` + `actor_count` (observations + usages + sessions, deduplicated) |
| the gated door | `GET /api/security/people/{sub}` → `{ok, sub, display_name, username, why, how}`, resolved LIVE by `kc_admin.get_user()` (`GET /admin/realms/{realm}/users/{sub}`; the service account already holds `view-users`) and stored NOWHERE. No e-mail is returned at all |
| the gate on the door | admin (`ADMIN_ROLES` via `caller_groups`), OR your own sub, OR a group named in the NEW `people_viewers` knob (`security_observe.people_viewers` / `set_people_viewers`, mirroring `claimable_groups`, same `<data>/security/observe.json`; `POST /api/security/observe {"people_viewers": [...]}`). 401 without an identity, 403 otherwise, 503 `no identity provider: …` with no Keycloak credential — there is deliberately no stored name to fall back on |
| the migration | `scrub_actor_pii()` clears every `actor` in `PermissionObservation` / `SecurityEvent` / `ObservationSession` / `UsageObservation` that is not shaped like a sub (8-4-4-4-12 hex), persisted through the existing debounce; `scrub_actor_pii_once()` runs it once per process and logs `[security] PII scrub: N actor values cleared (D18-1)` |
| when it runs | scheduled by `construct_security_endpoints`, but on a daemon thread that WAITS for the module's rows: routes are built in `polariServer.__init__`, long before lazy boot's Phase B restores them, so scrubbing inline would walk an empty tree (bounded: rows-or-120 s, hard stop 300 s) |

**Selftests.** `security_selftest.py` **126/129** — the 3 known environment failures (ledger `mac_enforced`, mac
profiles complain, expired internal certs) and nothing else; `modules/polariapps/apps_selftest.py` 57/57. The new
block `_pii_checks()` proves: the four ledgers store the `sub` while the token carries `preferred_username`,
`username` AND an `@example.invalid` e-mail (and none of those strings appear anywhere in the rows); `actor_of()`
never falls back; `review()`/`derive_profiles()` count distinct subs; the scrub clears a username and an e-mail,
keeps a real sub, and clears nothing on a second run; `looks_like_sub()` accepts only 8-4-4-4-12 hex; and the door
answers 401 unauthenticated, 403 for a stranger (naming the rule and the knob), 200 for self, 200 for an admin, 200
for a `people_viewers` member, 503 with no Keycloak credential — with nothing it returned reaching a row.

**Live proof** (`polari-lean` on `192.168.0.210.nip.io`, redeployed with `pol prod apply`; posture `dev`, gate
`advisory` — neither touched):
- the backend log carries **`[security] PII scrub: 9 actor values cleared (D18-1)`** — the nine usernames this
  week's role-play and self-claim tests had written across the four ledgers;
- `GET /api/security/observations` (17 rows) and `/api/security/events` contain **zero** `demo-*` strings and
  **zero** `@` — grepped on the raw JSON;
- a `demo-journalist` password-grant bearer + `X-Polari-Roleplay: journalist` → one CRUDE read of `TermsDocument`
  (200) → the new observation row's actor is **`589384ad-d886-49e2-adb1-77aa78b139f4`**, that token's own `sub`,
  with `groups` carrying `journalist,…,roleplay:journalist` and verdict `granted-by-profile`;
- `GET /api/security/people/589384ad-…` with that same bearer → **200** `{"display_name": "Demo Journalist",
  "username": "demo-journalist", "why": "your own account"}`; with a `demo-admin` bearer → 200 (`why:
  administrator`); with a `demo-viewer` bearer → **403** naming the rule and the knob; with no bearer → **401**.

**OWED**
- **No browser has seen any of this.** The `security-events` page shows the `actor` column as a raw UUID; nothing
  in the frontend calls the people door yet, so a person reading the page must resolve a sub by hand (the guide
  says how). A render-time name lookup in the display layer is the obvious next step and is NOT built.
- The door does one Keycloak admin round trip per call, with **no rate limit and no batch form**. A page listing
  fifty subs would make fifty calls. Deliberate (no cache = no PII at rest), but a `?subs=a,b,c` batch and a
  per-caller rate limit are owed before any page resolves names in bulk.
- The **503 "no identity provider"** path is proven in the selftest only — the live stack has Keycloak. Likewise
  `kc_admin.get_user()`'s 404 (unknown sub) and 502 (Keycloak refused) branches are selftested against a fake
  `_http`, never seen against a real realm.
- `security_claims.caller()` still READS `preferred_username` for a UI echo. Nothing persists it (every call site
  discards it) but the function is one careless caller away from a leak; folding it out is owed.
- The scrub's rule is "not 8-4-4-4-12 hex → clear". An identity provider whose subject ids are not UUIDs would have
  its legitimate actors cleared. True of Keycloak nowhere, but it is an assumption, written here so it is not a
  surprise.
- The scrub is per PROCESS and waits at most 300 s for the module's rows. If a restore ever ran longer, it would
  log `0` and never retry until the next restart. No test covers that path.
- The nine cleared rows are **gone**, not reversible: their acts and counts survive, the person who performed them
  does not. That was the point, and it is stated here because no ledger row can be recovered from Keycloak.

## §54 — names at render time (2026-09-17, closing §53's first two OWED items)

§53 left the rule built and the page unreadable: `actor` was a raw UUID on four tables, nothing in the frontend
called the door, and the door had "no rate limit and no batch form — a page listing fifty subs would make fifty
calls". Both are now built. The rule itself is unchanged: **a Polari row still keys a person by the opaque Keycloak
`sub` and nothing else**; a name exists only while a page is being rendered.

**Built** (framework, angular, node pin, suite pin — see the commits below):

| piece | where |
|---|---|
| the batch door | `POST /api/security/people {subs: [...]}` (max 200, a 400 past that) → `{ok, people: {sub: display_name\|null}, denied, why, asked, resolved, cache, keycloak_calls, how}`. `security_api.on_post_people` |
| the gate, per sub | `security_api._people_gate()` computes the caller's standing ONCE (own sub / admin / a `people_viewers` group) and each sub is sorted into `people` or `denied`. One stranger's sub never fails the batch; a sub the realm does not know answers `null`, never an error |
| the cache | `modules/security/custom/security_people.py` — a dict in the process, TTL `POLARI_PEOPLE_CACHE_SECONDS` (default 300 s, `0` = off). **It is the one place a name lives in the backend and it dies with the process**: never a row, never `persistTree`, never a log line, never disk. Stated in the module docstring so the next reader does not have to infer it |
| the rate limit | 60 calls/min/caller, sliding window, in memory. Past it: **429** with a plain sentence ("this door answers 60 calls a minute per caller … one call may carry up to 200 subject ids, so batch them") and a `Retry-After` header |
| the single door | unchanged and still uncached — `GET /api/security/people/{sub}` resolves live every time, as its docstring promises |
| the column kind | `class-rows-table` gained `@Input() columnFormats` (csv of `column:format`). The one format is `person`: the cell shows `PeopleService.short(sub)` (first 8 chars) with the whole id in the `title` tooltip, and the name replaces it when one comes back. **No new component** — a formatter inside the existing cell rendering, native `title` so no new module import |
| the batching | `src/app/services/people.service.ts`. After the rows load, the component collects the distinct subs of the `person` columns *on screen* and makes ONE call (chunked at 200). The names map and the `asked` set are in memory for the tab — never localStorage, sessionStorage, a cookie or a URL. `asked` covers null and denied subs too, so a re-render never re-asks |
| the refusals | 401/403/404/503 close the door for the tab (no error UI, the short id stays); 429 does not, so the next render may succeed. The viewer must be signed in (`AuthSessionService.isAuthenticated`) before a call is made at all |
| the page | `security_page.ACTOR_FORMAT = 'actor:person'` on all four tables of `/display/security-events`: `security-events-table` (SecurityEvent), `security-observations-table` (PermissionObservation), `security-usage-table` (UsageObservation), `security-sessions-table` (ObservationSession) |
| the helper | `module_pages_seed._table(..., column_formats='')` → the `columnFormats` input. Every other caller is untouched (the default is `''`) |

**Selftests.** `security_selftest.py` **139/142** — the same 3 known environment failures (ledger `mac_enforced`,
mac profiles complain, expired internal certs) and nothing else; 10 new checks in `_people_batch_checks()` prove:
401 without an identity; a 400 for an empty body and for more than 200 subs, naming the limit; a plain signed-in
caller resolving their OWN sub while another's lands in `denied` and never in `people`; an admin resolving the whole
batch in one call with an unknown sub answering `null` and duplicates/blanks collapsed; **the cache sparing the
second Keycloak round trip** (`kc_admin.get_user` monkeypatched and counted — `keycloak_calls` 0 on the repeat);
`POLARI_PEOPLE_CACHE_SECONDS=0` turning caching off entirely; a `people_viewers` member resolving the batch with the
granting group named; **the rate limit** — 60 calls pass, the 61st is 429 with the sentence and a `Retry-After`, and
a different caller is unaffected; 503 with no Keycloak credential, while an all-denied batch still answers 200
without touching Keycloak; and that the batch wrote nothing to the manager. Unchanged beside it:
`polariapps/apps_selftest.py` 57/57, `aquaponics_pages` 5/5, `computers` 30/30, `microchip` 16/16, `cooknow` 37/37
(the `_table` helper's new keyword breaks no other page). `npx ng build --configuration=production` exits 0.

**Live proof** (`polari-lean` on `192.168.0.210.nip.io`, redeployed with `pol prod apply`; posture `dev`, gate
`advisory` — neither touched). `GET /api/security/observations` returned 18 rows carrying two distinct actor subs,
`589384ad-…` and `5cacba59-…`:
- **demo-admin** → `POST /api/security/people {"subs": [both]}` → **200** `{"589384ad-…": "Demo Journalist",
  "5cacba59-…": "Demo Admin"}`, `denied: []`, `why: administrator`, `keycloak_calls: 2`;
- **the same call again** → the same two names with **`keycloak_calls: 0`** and `cache: {entries: 2, ttl_seconds:
  300}` — the second Keycloak round trip never happened;
- **demo-viewer** asking about its own sub and the two others → **200**, `people` holds only its own
  (`820f970b-… → "Demo Viewer"`, `why: your own account`) and **both others are in `denied`** — one call, the gate
  applied per sub, no error;
- **no bearer** → **401**;
- **the 61st call in a minute** as demo-viewer → **429** *"too many name lookups: this door answers 60 calls a
  minute per caller… one call may carry up to 200 subject ids, so batch them"* with `retry_after: 59`. (So the
  429 IS proven live, not only in the selftest.)
- the **served** frontend bundle (`/9768.d9875537f48cb889.js`, 233 KB over HTTPS, 200) contains `/api/security/people`
  and `columnFormats`;
- the **served** `GET /DisplayDefinition` shows all four security-events tables carrying `columnFormats:
  'actor:person'` — `security-events-table` (SecurityEvent), `security-observations-table` (PermissionObservation),
  `security-usage-table` (UsageObservation), `security-sessions-table` (ObservationSession).

**Two defects this deploy found, both fixed and both now selftested:**
1. `add_route('/api/security/people', self, suffix='people_batch')` beside `def on_post_people`. Falcon does not
   answer 405 for a suffix with no responder — `add_route` **raises**, so `prf-backend` crash-looped at boot (0/1)
   and every selftest still passed, because they call the method directly. The responder is now
   `on_post_people_batch`, and a new check builds SecurityAPI against a fake falconServer and fails when ANY
   registered (uri, suffix) has no `on_<method>_<suffix>` — verified to catch the original mistake.
2. The page kept serving the OLD definition after the deploy: the core `DisplayDefinition` seed only INSERTS a page
   that is missing, so `actor:person` never reached an instance that already had the page (the seed field-addition
   gotcha). `security_page.seed_security_pages()` now upserts through `moduleService.seed_upsert`, scheduled by
   `start_page_converge()` on the daemon thread that waits for Phase B — the same wait the PII scrub needs.

**OWED**
- **No browser has seen this.** The whole point is how the page READS, and that is exactly what an API proof cannot
  show: whether a mixed table of names and short ids is legible, whether the tooltip is discoverable, whether the
  8-character prefix is enough to tell two actors apart. **His pass.**
- The short form is a **prefix, not an identity**. Two subs sharing their first 8 hex characters would render
  identically to a viewer who may not resolve names. Astronomically unlikely per realm, not impossible, and no
  collision detection exists.
- The frontend resolves the rows **on screen at first render only**. `class-rows-table` has no pagination and no
  re-fetch, so this is complete for it today — but any table that later grows paging must call `resolve()` again
  for each page, and nothing enforces that.
- The 429 path is proven both ways (selftest and 61 live calls). What is NOT proven is what a *browser* does with
  one: `PeopleService` deliberately does not close the door on 429, so a page that re-renders inside the same
  minute simply asks again and keeps the short ids. No test covers that loop.
- The cache makes the backend hold names for up to 300 s. That is a deliberate change to §53's "no cache = no PII
  at rest" and it should be read as such: the names are in RAM, in one process, for five minutes. A deployment that
  wants the older guarantee sets `POLARI_PEOPLE_CACHE_SECONDS=0` and pays one Keycloak round trip per sub per call.
- Nothing invalidates the cache when Keycloak changes. A rename or a deletion is invisible for up to one TTL on the
  backend and for the life of the tab on the frontend (the browser map has **no** TTL at all — a tab left open all
  day keeps the name it first resolved). No test covers a stale name.
- The rate limit is **per process**, keyed by the caller's sub. Two `prf-backend` replicas would allow 120 calls a
  minute between them, and an unauthenticated caller can never reach it (401 comes first).
- `class-rows-table`'s `person` kind is the ONLY format in `columnFormats`. The parser accepts any `column:format`
  pair and silently ignores an unknown format — a typo in a seed (`actor:persn`) renders the raw UUID with no
  complaint anywhere. No validation exists.

## §51 addendum 3 — tombstones + the serialisation hot spot (2026-09-18, fixed, selftested, proven live)

The defect §51 addendum 2 observed at its own tail and did NOT fix — **a row deleted while a flush is in flight is
RESURRECTED by that flush** — is fixed, together with the reason the window was wide enough to hit twice: the flush
spent 39-103 s of pure Python finding one column. polari-framework `3d8a7b3` + `f0b9f92`, node `f4cb617`, suite pin
below. Posture stays `dev`, the gate stays `advisory` — **not** `enforce` (his ruling stands).

### A. the resurrection — tombstones

`persistTree()` snapshots `objectTables` at the top (`tables = {name: dict(instances) ...}`), serialises for tens of
seconds, then writes that snapshot as ONE DELETE+REPLACE transaction. A delete landing in between was simply undone:
the snapshot still held the row, so the write put it back, and the next boot read it back into the tree.

**The fix.** Every removal leaves a **tombstone** `(className, instanceId)` on the manager:
`deleteTreeNode` (recorded before EITHER branch, so the in-tree and not-in-tree cases are both covered),
`purgeObjectType` (one per row of the class), and `inheritanceOrchestrator._rollbackCreatedInstances`. At WRITE time
— after serialisation, immediately before the transaction — `_dropTombstonedRows` drops every prepared row whose
`(class, id)` is tombstoned. The legacy per-class path and the row-by-row fallback apply the same filter.

Two rules keep it honest:

- **The live table is the truth, the tombstone only says where to look.** A row is dropped only when it is
  tombstoned AND still absent from the live `objectTables`, so an id deleted and RE-created before the write is
  written, not dropped. Every create also cancels the tombstone for its own key (`noteTreeMutation` from
  `treeObjectInit` and `addNewBranch`).
- **Filter, COMMIT, then clear** — a python set and a sqlite transaction cannot commit together. Only the
  tombstones this flush acted on are cleared, and only after the commit: a delete landing during the write is still
  in the set and the next flush honours it; a crash in between leaves the tombstone up and the next flush drops the
  row again.

**Found in the live log of the proving deploy and fixed in `f0b9f92`:** a delete that lands BEFORE the snapshot is
never "honoured" (there is nothing to drop), so its tombstone stood forever — the SIGTERM flush reported
`1 tombstones still up` and kept reporting it. A flush now also **SETTLES** a tombstone whose class table it rewrote
whole: the row is provably off disk either way. Only tombstones captured before the write are settled, and a key
live in the table again is never settled.

### B. the serialisation hot spot — ONE tree walk, not one per row

Profiled with cProfile against a tree shaped like the live instance's, built from a `docker cp` copy of
`managerObject_DB.db` (97 classes, 10 870 rows, **460** of them carrying a `_branch_path`, plus filler nodes
standing for the ~23 700 instances the flush skips as "no table" but which are still IN the tree — ~4 000 nodes).
That reproduction lands at **40.95 s**, inside the live band of 39-103 s, so the model is the live behaviour.

```
   ncalls      tottime   cumtime  function
42297210/10870  47.317    75.757  objectTreeManagerDecorators.py:2173(getTuplePathInObjTree)
      42297210  23.019    23.019  objectTreeManagerDecorators.py:2133(getBranchNode)
      84593960   5.421     5.421  {method 'keys' of 'dict' objects}
            97   0.142    76.125  managedDB.py:278(_buildClassRows)
         10870   0.064     0.064  objectTreeManagerDecorators.py:1534(getObjectTyping)
           460   0.000     0.003  json/__init__.py:183(dumps)
```

**Root cause, exactly.** `_buildClassRows` asks `polyTypedObject.serializeTreePath` for each row's `_branch_path`,
and that is `managerObject.getTuplePathInObjTree` — a full depth-first search of the WHOLE object tree in which
`getBranchNode` re-walks from the root at every recursion step. ~96 % of rows are not in the tree at all
(**460 of 10 870**), so those searches never short-circuit and visit every node: **42 297 210 recursive calls for
10 870 rows**, 47.3 s + 23.0 s = **99.7 %** of the flush. It is not a per-row JSON re-encode (0.003 s for all 460
paths), not the typing lookup (0.064 s), not sqlite (§51 addendum 2 already measured the DB half at 0.24-0.75 s).

**The fix.** The tree does not move while the flush serialises, so it is walked ONCE.
`managerObject.buildTreePathIndex()` indexes every node by `(className, identifiers)` **in the exact order the
recursive search checked them** (all children of a node, then each subtree in turn), keeping a **list** per key
because one key can sit at several places in the tree; `treePathFromIndex` then replays the original's decision
verbatim — a duplicate-pointer node returns its stored path, an exact instance match returns its traversal, anything
else is walked past. The index is built once per flush in `persistTree` and threaded down through
`prepareClassBatch` / `saveClassBatch` / `_buildClassRows` as a keyword with a signature check, so any db double
that predates it keeps working.

| measurement (same harness, same tree) | before | after |
|---|---|---|
| `_buildClassRows` over the whole tree | **41.25 s** | **0.10 s** (index build 0.005 s, 4 062 keys) — **423x** |
| rows written | 10 870 | 10 870, **byte-identical**, all 460 `_branch_path` values included |

**The on-disk format did not change.** The selftest asserts the written rows are identical with and without the
index, for a tree containing a duplicate pointer and two different instances sharing one `(class, identifiers)`.

### C. the generation counter, and the only-dirty flush that does NOT fall out

`persistGeneration` bumps on every create and delete; `persistTree` records it at the snapshot and prints
`tree moved under the flush: generation N -> M` when the tree changed underneath. It is **NOT** used to skip
unchanged classes, and that is deliberate: `treeObject.__setattr__` short-circuits every plain scalar straight to
`super().__setattr__` (and `restoreTreeFromDB` writes fields with `object.__setattr__` outright), so in-place field
updates never reach any hook. Skipping a class on that basis would silently drop them. Per-class dirty tracking
needs a real dirty flag at every mutation site including those bypasses — its own slice, not a free rider on this one.

### Selftests

New `polariApiServer/selftest_persist_tombstones.py` **43/43**: the bookkeeping (create bumps, delete bumps and
tombstones, a tombstoned row still live is NOT dropped, a re-created id cancels its tombstone, `clearTombstones`
drops only what was honoured); `_dropTombstonedRows` filters by the `id` column and leaves a class WITHOUT one
alone; **a delete fired from inside `prepareClassBatch`** — i.e. after the snapshot, before the write — is not
written back and stays gone on the next flush; a create fired the same way is written now or next flush, never
lost; a re-created id survives; the tombstone settles instead of piling up, but one for an untouched class is kept;
the legacy per-class path honours tombstones; the index agrees with the live search for the root / one level down /
two levels down / a second instance sharing a key / a row not in the tree / a duplicate pointer; the `_branch_path`
written is byte-identical with and without the index; and a whole flush costs **ZERO** full tree searches.

Unchanged: `selftest_persist_debounce` 13/13, `selftest_persist_atomic` 21/21, `selftest_crude_delete_blast` 21/21,
`selftest_quiesce` 27/27, `selftest_batched_persist` 17/17, `modules/security/security_selftest.py` **137/140**
(the 3 known environment failures — ledger `mac_enforced`, mac profiles complain, expired internal certs).

### LIVE PROOF (home swarm `polari-lean`, demo-admin bearer, gate `advisory`)

| step | result |
|---|---|
| before | `GET /AppPermissionProfile` → 3 rows (`app-climate-viewer`, `journalist`, `wax-print-shop-operator`); the sqlite file inside the container agrees |
| create `tomb-031131` through CRUDE (multipart, one `initParamSets` field) | `201`, and **on disk within 5 s** — the debounced flush now takes about a second, not a minute |
| **DELETE it and fire `docker service update --force polari-lean_prf-backend` immediately**, without waiting for any flush | `200 {"instancesDeleted": ["FWb11Ez10s8"]}`, API back to 3 rows |
| new container online after 70 s | **API 3 rows, DISK 3 rows — it did NOT come back.** This is the exact sequence that resurrected two profiles at the end of §51 addendum 2 |
| the outgoing container's SIGTERM flush | `[Persist] SIGTERM — flushing the object tree before we go` then `[DB] Persisted 11 282 instances … 0 rows deleted since the snapshot were dropped, 1 tombstones still up — tree-path index 0.01s, serialize 0.50s, write+commit 0.30s`. **The SIGTERM flush COMPLETED** — the whole thing inside ~0.8 s |
| the new container's flushes | `Persisted 11 478 instances … tree-path index 0.01s, serialize 0.51s, write+commit 0.29s` and `… index 0.36s, serialize 0.84s, write+commit 0.50s` |

**Serialisation, live: 39.45 / 44.89 / 53.66 / 74.97 / 77.89 / 81.14 / 97.11 / 103.45 s before → 0.50 / 0.51 / 0.84 /
0.89 s after.** That is what makes §51's SIGTERM flush mean anything: at ~0.5 s it fits inside Docker's 10 s default
`stop_grace_period`, where 39-103 s never could.

**RE-PROVED on the final code** (`f0b9f92`, a second `pol prod apply`, same script): `tomb-033514` created
(`201`, on disk in 5 s), deleted (`200 {"instancesDeleted": ["0HDhNlaaU"]}`), redeploy fired in the same breath, new
container online after 80 s → **API 3 rows, DISK 3 rows**. Flushes on the new container:
`tree-path index 0.01s, serialize 0.86s / 2.43s / 0.49s, write+commit 0.37s / 0.38s / 0.77s`. The outgoing
container's shutdown: `[Persist] SIGTERM — flushing the object tree before we go` then
`Persisted 11 490 instances … tree-path index 0.01s, serialize 0.49s, write+commit 0.47s` — **the SIGTERM flush
completes in about a second**. And **no `tombstones still up` line anywhere any more**: the settling fix is proven
live, not just in the selftest. One container killed mid-BOOT logged
`tree moved under the flush: generation 39194 -> 39927 — … serialize 4.28s`, which is the generation counter doing
exactly its job: saying out loud that the tree was still being built underneath that flush.

### OWED

- **`stop_grace_period` is still Docker's 10 s default and STILL AWAITS HIS YES.** `docker service inspect
  polari-lean_prf-backend` → `StopGracePeriod 10s`; `docker-compose.lean.yml` sets none. The flush now fits inside
  it on this instance, so the one-line change is no longer load-bearing for a 10 000-row tree — but it is the only
  thing standing between a bigger instance and a SIGKILLed flush. The exact line, on the `prf-backend` service in
  BOTH `docker-compose.lean.yml` and `docker-compose.prod.yml`:

  ```yaml
      stop_grace_period: 180s
  ```

  Not applied — it changes his running stack's shutdown behaviour and he should say yes first.
- **Per-class dirty tracking** (skip classes nothing touched) — see §C: it needs a dirty flag at every mutation
  site, `treeObject.__setattr__`'s scalar short-circuit and `object.__setattr__` bypasses included.
- **`persistTree` still skips ~25 100 instances per flush as "no table"** — carried over from §51 addendum 2,
  untouched here, still deserves its own look.
- **The boot/flush overlap** from §51 addendum 2 is still open: if a new container's restore reads the file before
  the old container's flush commits, its own boot flush writes the older reading back. Much smaller now that a
  flush is ~1 s instead of ~100 s, but not closed.
- **`treeObject.__setattr__` calls `getTuplePathInObjTree` too** (line 189, for every non-scalar assignment) — the
  same full-tree search, outside the flush path. Not touched here; the same index would fix it if it is ever hot.
- **Not seen by eye.** No browser pass on any of this; it is API and container-log evidence only.

## §55 — login persistence (2026-09-18, his report; fixed and verified over the API, browser pass OWED)

His report: *"my login does not seem to persist well, when I close out and reopen I am not still logged in. I do
not think a login should necessarily exist forever but accidentally closing out should not lose my login
entirely."* Angular `31b6125`, node `7e59093`, suite `f2090fe`, deployed to `192.168.0.210.nip.io` by
`pol prod apply` (stack polari-lean, 6/6).

### Two root causes, one on each side

**A. the tokens died with the tab.** `oidc-client-ts` defaults `userStore` to
`new WebStorageStateStore({ store: window.sessionStorage })`
(`node_modules/oidc-client-ts/dist/esm/oidc-client-ts.js:2517`), and
`oidc.service.ts:38-49` built its `UserManagerSettings` without overriding it. sessionStorage is per-tab and the
browser destroys it on close, so the access token AND the refresh token went with the window. The only recovery
path left was `signinSilent()`'s iframe fallback — a `prompt=none` authorization request against Keycloak's SSO
cookie, i.e. a third-party cookie, exactly what browsers now block. Reopening the app therefore had nothing to
resume from.

`userStore` and `stateStore` are now both on `localStorage`, behind a `durableStore()` probe that write/removes a
key before trusting a tier and degrades `localStorage → sessionStorage → InMemoryWebStorage` rather than throwing
at boot in a profile that blocks site data. With a refresh token in hand, `signinSilent()` takes the
`_useRefreshToken` branch (`oidc-client-ts.js:3113`) and redeems it straight against the token endpoint — no
iframe, no cookie.

**B. Keycloak had already dropped the session.** The live realm read
`ssoSessionIdleTimeout: 1800` — 30 minutes. Even a kept refresh token was refused after half an hour away. And
`rememberMe` was already `true` while `ssoSessionIdleTimeoutRememberMe` and `ssoSessionMaxLifespanRememberMe` both
sat at `0`, which Keycloak reads as "fall back to the ordinary values" — ticking the box bought nothing at all.

### What changed

| | before | after |
|---|---|---|
| `userStore` | sessionStorage (library default) | localStorage |
| `stateStore` | localStorage (library default) | localStorage, pinned explicitly |
| `monitorSession` | `true` | `false` |
| `accessTokenLifespan` | 300 | 900 |
| `ssoSessionIdleTimeout` | 1800 | 43200 (12 h) |
| `ssoSessionMaxLifespan` | 36000 | 604800 (7 d) |
| `ssoSessionIdleTimeoutRememberMe` | 0 | 604800 (7 d) |
| `ssoSessionMaxLifespanRememberMe` | 0 | 2592000 (30 d) |

`monitorSession` is off deliberately: Keycloak's check_session iframe needs the same third-party cookie, and when
it is blocked it reports "signed out" for a session that is alive. Leaving it on parks a false sign-out signal in
the app for the next person to wire a handler to. A sign-out that really happened at Keycloak still surfaces
within one access-token lifetime, when the refresh grant is refused.

Smaller fixes made in passing, all of which fed the same complaint: a `userLoaded` stream so a silent renew
updates `currentUser$`/`accessToken$` instead of leaving them on the pre-renew copy until a 401 resynced them;
`logout()` clearing local storage even when the end-session redirect cannot be built (durable storage makes a
half-finished sign-out survive a restart); session restore sweeping dead tokens out of storage; a 401 no longer
tearing down a session the store still says is live, and the error interceptor only reacting to calls it actually
signed; `login()`/`register()` round-tripping the full in-app URL (query + fragment) and never echoing `/callback`
back as the return target.

**The convergence problem.** `realm-imports/polari-realm.json` is read ONLY when the realm does not yet exist, so
editing it alone would have left the deployed realm on its birth settings forever. The lifetimes are therefore
also re-asserted on EVERY Keycloak boot by `pol-keycloak/startup_shells/configure_clients.sh` — an idempotent
read-patch-PUT of the live realm representation that touches these six fields and nothing else. No client secrets
or redirect URIs are involved.

### Verified over the API (no browser)

- live realm `GET /admin/realms/Polari`: `rememberMe true`, `accessTokenLifespan 900`,
  `ssoSessionIdleTimeout 43200`, `ssoSessionMaxLifespan 604800`, `ssoSessionIdleTimeoutRememberMe 604800`,
  `ssoSessionMaxLifespanRememberMe 2592000` — all six, on the LIVE realm, put there by the boot script
  (`SUCCESS: rememberMe=true, accessToken=15m, SSO idle=12h/max=7d, rememberMe idle=7d/max=30d.` in the
  `pol-keycloak` service log), not by an import.
- authorization endpoint (`client_id=polari-frontend`, `redirect_uri=https://prf.<domain>/callback`,
  `response_type=code`, `scope=openid`, S256 PKCE challenge) → HTTP 200 rendering
  `<input type="checkbox" id="rememberMe" name="rememberMe">` with label `Remember me`.
- password grant for `demo-viewer`: `expires_in 900`, access token `exp - iat = 900`; refresh token
  `exp - iat = 43200` — the 12 h SSO idle timeout, reflected.
- `grant_type=refresh_token` with that refresh token → new access token, `exp - iat = 900`,
  `preferred_username demo-viewer`, `refresh_expires_in 43200`. The renew path the restored session depends on
  works end to end.
- served bundle `https://prf.<domain>/main.6219f8f42981038c.js` (same hash as the local
  `npx ng build --configuration=production`, exit 0) contains
  `userStore:new dt({store:Qe}),stateStore:new dt({store:Qe}),automaticSilentRenew:!0,loadUserInfo:!0,monitorSession:!1`
  with `Qe` = `for(const O of[()=>window.localStorage,()=>window.sessionStorage])…`.

### OWED — his browser pass

**None of the above proves the thing he actually reported.** Every check here is an API call; the behaviour under
test is what a browser does to `localStorage` when a window closes, and that is unproven until a person tries it.

1. Sign in at `https://prf.192.168.0.210.nip.io`. Close the window entirely (not just the tab). Reopen it →
   **still signed in, no prompt.**
2. Same, with **Remember me** ticked, then leave it overnight → still signed in the next day.
3. **Sign out**, close, reopen → **signed out**, and signing in asks for the password again (proving the
   end-session call killed the Keycloak SSO cookie, not just the local tokens).
4. A private/incognito window: sign in, close it, reopen → signed out. That is by design, not a regression.
5. Leave a signed-in tab idle past 15 minutes and use the app → it should keep working silently (the access token
   renews off the refresh token); watch the console for `[OidcService] silent renew error`.

Also unproven: the 7-day and 30-day caps, which nothing short of waiting can exercise. And `monitorSession:false`
means a sign-out performed in ANOTHER browser is noticed only when the access token next renews (≤15 min), not
instantly — acceptable, but his call if it is not.

## §56 — resume on landing (check-sso) (2026-09-18, his report; fixed, Keycloak half proven, browser pass OWED)

His report, right after §55 landed: *"hitting login seems to quickly register the login but it does not do so
automatically when I land on the site."* Angular `685d18d`, node `5fbd54f`, suite `c961dc2`, deployed to
`192.168.0.210.nip.io` by `pol prod apply` (stack polari-lean).

### Two root causes

**A. the boot restore never ran.** `app.module.ts` registered two `APP_INITIALIZER`s on the assumption that the
second waits for the first. It does not. `ApplicationInitStatus.runInitializers()`
(`node_modules/@angular/core/fesm2022/core.mjs:23303-23319`) invokes **every** factory in one synchronous `for`
loop, collects the promises, and only then `Promise.all`s them. So `AuthSessionService.start()`
(`auth-session.service.ts:61`, pre-fix) was called while `RuntimeConfigService.initialize()`
(`runtime-config.service.ts:115-122`) still had its GET of `/assets/runtime-config.json` in flight.
`getKeycloakConfig()` (`runtime-config.service.ts:420-422`) reads `this.startupConfig?.keycloak ?? null` and
`startupConfig` is only assigned in the `tap` at `:138` — so it was `null`, `OidcService.isConfigured()`
(`oidc.service.ts:140-142`) answered `false`, and `start()` returned at `auth-session.service.ts:64` having
already set `started = true` at `:63`.

Consequence, for the whole life of the page: no session restore, no `userLoaded$` subscription, and
`ensureUserManager()` never called — so `automaticSilentRenew` never even started. Clicking **Login** worked
because `oidc.login()` builds the `UserManager` lazily, by which time the config had landed. That is exactly the
asymmetry he described.

Fixed twice over: ONE initializer chaining `configService.initialize().then(() => auth.start())`
(`app.module.ts:425-441`), and `start()` now awaits `OidcService.whenConfigured()`
(`oidc.service.ts`, `whenConfigured()`), which waits on `runtimeConfig.isConfigLoaded$` before answering — so a
future second registration cannot reintroduce the race.

**B. "no local user, live Keycloak session" was unreachable.** With §55's localStorage store, the
close-and-reopen case is carried by the refresh token. But a browser that has never signed in here — or one whose
storage was cleared — has no refresh token, and the only route left was oidc-client-ts's hidden `prompt=none`
iframe (`oidc-client-ts.js:3129-3146`, taken whenever the stored user has no `refresh_token`, per the branch at
`:3114`). The frontend is `prf.192.168.0.210.nip.io` and Keycloak is `auth.192.168.0.210.nip.io`; **`nip.io` is on
the Public Suffix List**, so those are two different *sites*, the KC cookie is third-party, and every current
browser withholds it from the frame. The iframe answers `login_required` — or just burns its ten-second timeout —
for a session that is perfectly alive.

Fixed with **check-sso**, the way Keycloak's own adapter does it when iframes cannot work: ONE top-level
`signinRedirect({ prompt: 'none', state: { returnTo, checkSso: true } })` on landing, when there is no usable
local user and no `polari-sso-checked` flag in `sessionStorage`. A top-level navigation carries the cookie
normally, so it gets the true answer.

### What else changed

- **the ladder is ordered.** Live stored user → used as-is. Expired **with** a refresh token → `signinSilent()`
  (refresh grant, no frame) BEFORE any redirect. Only then the one check-sso.
- `OidcService.signinSilent()` now declines the iframe fallback when there is no stored refresh token — that was
  a ten-second stall on every anonymous boot, for a call that could not have succeeded.
- `handleCallback()` returns `user | no-session | error` instead of `User | null`, so "nobody is signed in" stops
  being indistinguishable from "sign-in failed". The request `state` is an object `{returnTo, checkSso}` and is
  read off the `ErrorResponse` too — oidc-client-ts assigns `response.userState = state.data` at
  `oidc-client-ts.js:1424` *before* it throws on `response.error` at `:1429`, which is what lets the quiet branch
  find its way home. The legacy bare-string state shape is still accepted, so a redirect already in flight when
  the new bundle ships still lands correctly.
- `/callback` navigates to `returnTo` on BOTH the signed-in and the silent branch, and says *"Checking your
  session…"* rather than *"Signing you in…"* when the URL carries an `error` — no error panel for a question the
  person never asked.
- `logout()` pre-sets `polari-sso-checked` **before** the end-session redirect (a `finally` would not run —
  `signoutRedirect()` navigates away and its promise never settles), so "sign out, then land" costs no round trip.
- a loop fuse: two check-sso launches inside 30 s stand the probe down for the browser session, covering any path
  where the return leg cannot set the flag.
- the check is skipped entirely when runtime-config has no `keycloak` stanza (lean without logins).

### Verified without a browser

- `npx ng build --configuration=production` — exit 0 (bundle-budget warning pre-existing, 5.48 MB).
- the served bundle contains `prompt:"none"` and `polari-sso-checked`.
- **the branch the callback must swallow, proven at the source.** The authorization endpoint with `prompt=none`
  and no Keycloak cookie:
  `GET https://auth.192.168.0.210.nip.io/realms/Polari/protocol/openid-connect/auth?client_id=polari-frontend&redirect_uri=…%2Fcallback&response_type=code&scope=openid+profile+email+roles&state=probe123&prompt=none&code_challenge=…&code_challenge_method=S256`
  → `302 https://prf.192.168.0.210.nip.io/callback?error=login_required&state=probe123&iss=…` — exactly the
  response the `no-session` branch is written for.
- `/assets/silent-refresh.html` is served `200` at the configured `silentRedirectUri` (it is correct; it is simply
  not the mechanism that can work across this site boundary).

### OWED — his browser pass

**The half that matters is the one curl cannot do: the same request WITH a live Keycloak cookie.** That answers a
`code`, not an error, and only a browser holding `KEYCLOAK_IDENTITY` can make it.

1. Sign in at `https://prf.192.168.0.210.nip.io`. Close the tab, open the site again → **signed in with no click,
   no visible Keycloak page.** (Carried by the refresh token — no redirect at all.)
2. Clear the site's `localStorage` only (leave the `auth.` cookie alone), then land again → a brief bounce
   through Keycloak and back, **signed in**, on the path you asked for. Try it on a deep link
   (`/permissions`, say) — you must land back on that page, not on `/`.
3. **Sign out**, then land again → **stays signed out, no redirect at all**, no error panel, no loop.
4. A private/incognito window → exactly **one** `prompt=none` round trip, then anonymous. Reload → no further
   redirects (the `polari-sso-checked` flag holds).
5. Watch the address bar across 3 and 4 for any sign of bouncing. One trip is correct; two is a bug.

Unproven either way until he looks: whether the brief blank page during the check-sso redirect reads as a flash
or as a normal load.

---

## §57 — primary role, roles → apps, my apps (2026-09-18, his ask; built, selftested, live proof below)

His words: *"We want to be able to have a primary role and additional roles. We will want to be able to tie Apps to
roles so that the user can see and navigate to the apps they need more easily. And then the user should be able to
refine that further and add apps they want to use or remove ones they do not care about."*

### What was built

| piece | where | state |
|---|---|---|
| `RoleAppBinding` row | `modules/polariapps/objects/apps_roles/RoleAppBinding.py` | role (a KC **group** name) → ORDERED app names, `source` = manifest \| admin \| prototype-review, `derived_from` = app.roles \| personas |
| `UserAppPreference` row | `modules/polariapps/objects/apps_roles/UserAppPreference.py` | `primary_role`, `added_apps_json`, `removed_apps_json`, `updated_at` — keyed by the Keycloak `sub` ALONE (D18-1); no username column exists |
| the read model | `modules/polariapps/custom/apps_roles.py` | derivation, convergence, suggestions, my-apps resolution, the update |
| manifest vocabulary | `moduleService/manifests.py` — `ROLE_NAME_MAX`, `role_findings()`, `roles` added to `_preserve_hand_set`, `validate()` calls it | `app.roles: [...]` is hand-set, survives `generate`, and a bad name is a validation problem, not a mystery |
| routes | `modules/polariapps/apps_api.py` | `GET /api/apps/roles`, `POST /api/apps/roles/{role}` (ADMIN_ROLES), `GET /api/apps/roles/{role}/suggested`, `GET`/`POST /api/apps/mine` |
| registration | `apps_roles_basis.py`, `objects/apps_roles/__init__.py`, `feature_imports.py` (`polariapps` block), `polariServer.py` defClassList, regenerated `modules/polariapps/polari-app.json` | the five places a polariapps row class must appear |
| frontend service | `src/app/services/apps-nav.service.ts` — `mine$`, `ensureMineLoaded()`, `refreshMine()`, `clearMine()`, `saveMine()` | one round trip per change; the POST answers the whole new view |
| side nav | `src/app/app.component.{ts,html,css}` — the **My apps** group ABOVE the app map | primary role's apps first, then additional, then added (pinned); a `tune` edit affordance + "Edit my apps…" both open `/apps` |
| catalogue = the editor | `src/app/components/apps/apps-home.component.{ts,html,scss}` (**extended, no new component**) | per-card **+ add / − hide / ↺ restore**, a `via` chip, and a "Hidden by you" strip at the top |
| header | `src/app/components/header/header.{ts,html}` | **Primary role: \<role\>** with a submenu of the roles you HOLD. The auth services were not touched (another agent owned them) |

**Where the rows live, and why polariapps rather than security:** these rows are about APPS. `polariapps` already
owns `PolariAppDefinition`, the persona index, `/api/apps/nav` and `AppPermissionProfile`; a binding is
**navigation**, not enforcement, and hiding an app grants and revokes nothing. `security` owns roles as a security
concept (prototypes, claims, observations) and is read here only for the review SUGGESTION, through a guarded
import, so polariapps still works on an instance carrying no security module.

### Decisions taken where the spec was silent

1. **A module manifest's `app.roles` binds every APP that carries the module.** The manifest is per-module and the
   bound thing is a `PolariAppDefinition`, so the bridge is app → `modules_json` → manifest → roles. Module names
   are matched against the manifest's id, package and directory name (apps name modules by whichever the seed used).
2. **A new field `derived_from` rather than a fourth `source`.** The spec's vocabulary is
   manifest \| admin \| prototype-review; the persona fallback is still a derivation from module-declared data, so
   it is `source: manifest, derived_from: personas` — honest without widening the enum.
3. **Bindings converge on every read, not at seed time.** `ensure_bindings()` is idempotent and runs inside
   `GET /api/apps/roles` and `GET /api/apps/mine`, so editing a manifest reaches a live instance without a seed
   pass — and an `admin` row is left alone for good.
4. **Anonymous gets 401 on `GET /api/apps/mine` too**, not just the POST: the answer is about one person.
5. **The app's route is `/app/<name>`** (its own home), which exists for every app — never a guessed nav item.
6. **`primary_role` falls back rather than erroring**: the stored one if still held, else the first held role that
   has a binding, else `''`.
7. **Removal is hiding.** Stated in the payload's own `note` field so a consumer cannot mistake it for a revoke.

### The demo bindings (deliberately 3–6 apps per role)

| role | manifests carrying `app.roles` | apps bound |
|---|---|---|
| `journalist` | `scoring`, `nutrition` | judicial-lean, dmv-policy-analysis, app-policy, app-scorecards-data-analysis, nutrition-planner (5) |
| `data-scientist` | `magnetics`, `mathshapes` | app-magnetics, app-materials-science, app-mechanical, engine-cad, wax-print-shop (5) |
| `operators` | `waxprint`, `gears`, `bizops` | wax-print-shop, app-magnetics, app-mechanical, app-business (4) |

Eleven further bindings come from the **persona fallback** (business-operator, researcher, policy-analyst,
network-engineer, electrical-engineer, mechanical-engineer, materials-scientist, software-engineer, cloud-engineer,
household-cook, meal-planner) — proof the fallback works without anybody declaring anything.

`materialsScience`, `simulations` and `polariNoCode` appear in app `modules_json` but have **no registry entry or
module directory** (they are legacy/core feature names), so no manifest can declare roles for them. That is why
`data-scientist` rides `magnetics` + `mathshapes` rather than the materials-science manifest.

### Selftests

| suite | before | after |
|---|---|---|
| `modules/polariapps/apps_selftest.py` | 58/58 | **82/82** (24 new: manifest + persona derivation, the 3–6 budget, idempotent convergence, admin-only POST 401/403, unknown-app refusal, ordered admin binding, derivation never overwrites admin, review suggestions ordered/filtered/never-bound, anonymous 401, no-bound-role empty, two held roles + primary default, primary-first ordering, unheld primary refused, primary switch reorders, remove → removed + suggestion, add → via=added, restore round trip, unknown-app refusal, two D18-1 checks that no row holds a username or `@`, and one that Keycloak's own plumbing never reaches the menu) |
| `moduleService/selftest_manifests.py` | 7/8 (pre-existing drift) | **8/8** — `modules/security/polari-app.json` was stale since `92e0ab1` and did not list `custom/kc_admin`, `custom/security_claims`, `custom/security_people`; regenerated |
| `modules/security/security_selftest.py` | 139/142 | **139/142** (the 3 known environment failures) — unchanged |
| `moduleService/selftest_lazy_imports.py` | 23/23 | **23/23** |
| `npx ng build --configuration=production` | clean | **clean**; the served bundle contains "My apps" |

The falcon route gotcha from §54 was checked explicitly: all thirteen `/api/apps*` routes register with
`falcon.App().add_route(..., suffix=...)`, so the backend cannot crash-loop at boot on a suffix with no responder.

### Live proof — `polari-lean` on the home swarm, entirely over the API (2026-09-18)

Framework `ee002fd`, node `7097589`, suite `0b96a6c`; two `pol prod apply` runs (the second carried the
held-roles fix below). Posture `dev`, gate `advisory` — **neither touched**. Bearers minted by password grant
against `https://auth.192.168.0.210.nip.io/realms/Polari` (client `polari-frontend`).

| what | result |
|---|---|
| `GET /api/apps/roles` (anonymous) | **14 bindings**, every one `source: manifest` — 3 `derivedFrom: app.roles` (journalist, data-scientist, operators) and 11 `derivedFrom: personas`, each app resolved to `{name, title, route}` |
| `GET /api/apps/mine` · demo-journalist | `held_roles ["journalist"]`, `primary_role "journalist"`, `additional_roles []`, and its five bound apps — app-policy, app-scorecards-data-analysis, dmv-policy-analysis, judicial-lean, nutrition-planner — each `via: primary`, each with `/app/<name>` |
| `POST {remove: ["judicial-lean"]}` then `GET` | the app leaves `apps`, appears in `removed`, and comes back as a **suggestion** (`why: "bound to a role you hold"`) |
| `POST {add: ["app-topology-network"]}` | an app **no role of theirs binds** joins the list as `via: added` |
| `POST {restore: ["judicial-lean"]}` | back under `via: primary`; `removed` and `suggestions` both empty again |
| `POST {primary_role: "operators"}` | **400** — *"'operators' is not a role you hold — your primary role must be one of your own roles (they come from your token, not from this row)"*, `held_roles ["journalist"]` |
| `POST {primary_role: "journalist"}` | `ok`, and the stored row now reads `primary_role: 'journalist'` |
| `GET /api/apps/mine` · demo-viewer | `ok: true`, `held_roles ["polari-viewer"]`, `primary_role ''`, `apps []`, `unboundRoles ["polari-viewer"]` — **empty, no error** |
| `GET /api/apps/mine` · anonymous | **401** *"sign in first — /api/apps/mine answers for the signed-in person, who is identified by their Keycloak subject id"* |
| `POST /api/apps/roles/journalist` · anonymous | **401** |
| `POST /api/apps/roles/journalist` · demo-journalist | **403** *"administrators only (ADMIN_ROLES: admin, polari-admin) — your own view is POST /api/apps/mine"* |
| `POST /api/apps/roles/demo-binding-check` · demo-admin | `ok`, `source: admin`, order preserved `["judicial-lean", "app-policy"]`; an unknown name refused with `knownApps`. The throwaway row was then **deleted through CRUDE** (multipart `targetInstance`) and `/api/apps/roles` is back to 14 — no residue, and `journalist` is still `source: manifest` |
| `GET /api/apps/roles/journalist/suggested` | `ok`, `suggested: []` (no role-play review has been recorded on this stack since the redeploy), `boundNow` = the five apps, `note` carries "SUGGESTION ONLY" |
| `UserAppPreference` over CRUDE | **one row**, fields `name` and `sub` both the Keycloak subject id and nothing else; no `demo-` string and no `@` anywhere in it (D18-1 holds on the live tree) |
| the served bundle | `https://prf.192.168.0.210.nip.io/main.ccb0fdaaa6082993.js` contains **"My apps"** |

**One defect found and fixed on the way (framework `ee002fd`).** The first deploy answered demo-journalist
`held_roles ['default-roles-polari', 'journalist', 'offline_access', 'polari-user', 'uma_authorization']`:
`caller_sub_and_groups` borrowed `apps_permissions._shared.caller_groups`, which deliberately UNIONS the
`groups` claim with realm/client roles so an ungroomed realm still grants permissions. Right for deciding what
somebody may TOUCH, wrong for a MENU — the header would have offered `uma_authorization` as a primary role. It
now takes the `groups` claim when the token carries one, realm roles only as the no-group-mapper fallback, and
in either case drops Keycloak's own plumbing (`offline_access`, `uma_authorization`, `account`,
`default-roles-*`). Selftest 81/81 → 82/82; redeployed; `held_roles` is now exactly `["journalist"]`.

The live stack is left with demo-journalist's preference row holding `primary_role: journalist` and
`added: ["app-topology-network"]` — **deliberately**, so his browser pass has something pinned under "Added by
you" to see and un-pin.

### OWED — his browser pass

Nothing below the API layer has been seen by eye. Sign in at `https://prf.192.168.0.210.nip.io` as
demo-journalist and look at:

1. **The side nav's first group, "My apps"** — is the heading legible, is the `tune` icon beside it obviously
   an edit affordance, and do the five journalist apps plus the pinned app-topology-network read as a list
   somebody would actually use? The role label between the groups is small caps in `--nav-text-faint`; check it
   is readable rather than invisible on the dark drawer.
2. **Dark AND light theme** on that group, and the accent edge on the primary role's items
   (`--brand-indigo`) — it has never been rendered.
3. **`/apps`** — the bar at the top (primary role chip, additional roles, the count), the per-card
   **+ add / − hide / ↺ restore** button and the `via` chip beside the title (the card head now carries four
   things; check it does not squeeze on a narrow window — `flex-wrap` is on, but it is unproven by eye).
4. **The "Hidden by you" strip** — hide an app, confirm it appears there and one click restores it.
5. **The header user menu → "Primary role: journalist"** and its submenu. A one-role person sees a submenu of
   one; sign in as demo-scientist (data-scientist) or claim a second role first to see it with two, and confirm
   picking one visibly reorders My apps.
6. **Somebody with no roles** (demo-viewer) — the side nav must show no "My apps" group at all and `/apps` must
   say "you hold no roles yet", not an error.
7. **Anonymous** — nothing new anywhere.

Also owed, and cheap once a review exists: act as the journalist role in the role menu for a few pages, then
`GET /api/apps/roles/journalist/suggested` and confirm the review's apps come back as suggestions with counts.

## §58 — the tailored home (2026-09-18, his ask; built, selftested, live proof below)

His words: *"If you have my apps selected or a role selected, and apps exist that are assigned to those roles, we
should have a secondary landing page you can land on that lets you choose from your own apps. It should still be
possible to go to the main Polari Home page via another route, but when logged in as your user it takes you to
your tailored home page. I feel like we may have built this out before."*

### Prior art — what was found, and what it was made of

He was right that pieces existed; none of them was this page, and all of them were reused rather than duplicated.

| prior art | what it actually is | how §58 uses it |
|---|---|---|
| `GET /api/apps/mine` + `AppsNavService.mine$` (§57, yesterday evening) | the whole read model: held roles, primary role, the person's apps already ordered primary → additional → added, what they hid, what to restore | **the only call the page makes.** No new door, no new row, no new service |
| the **My apps** side-nav group (§57) | the same list as a menu | the page is the same data at landing scale; both read one subject, so they cannot disagree |
| `/apps` = `AppsHomeComponent`, the catalogue **and** the My-apps editor (§57) | every app on the instance, a deployment plan per card, export/build, persona chips, + add / − hide / ↺ restore | its **stylesheet is this page's first stylesheet**, so the cards are literally the same CSS; "Choose your apps" links to it as the editor |
| `AppHomeComponent` at `/app/:name` | one app's own home — every app has one | every card's destination; nothing guesses a nav item |
| `/api/apps/nav` **personas** | a discipline filter over the catalogue ("I am a…"), not a person's own page | left alone — personas are a filter, roles are held. §57 already uses persona names as the binding *fallback* |
| sep-0's clamp `lockTo` / `shellAppGuard` | `?shellApp=` locks the session to one app | decides first, and wins: the clamp guard is a `canActivateChild` on the parent route, so it runs before this one |
| sep-7's `autoRouteIfSingleApp` | a landing behaviour that already existed: grants covering exactly ONE app enter it clamped | untouched; it clamps, and a clamp has no tailored home |
| `XrCapabilityService`'s headset banner on the main home | the house style for "suggest, never redirect" | the opposite decision here, taken deliberately and made escapable — see the session choice |

**No persona/dashboard/landing component existed.** `components/home` is the static Polari Research Framework
page; the only other "home" is `app-home.component.ts`, one app's front door.

### What was built

| piece | where | state |
|---|---|---|
| the page | `src/app/components/apps/my-apps-home.component.{ts,html,scss}` | `/home`: three groups of cards — **Your primary role: \<role\>**, **Additional roles**, **Added by you** — plus "Polari home", "Choose your apps", the hidden count, and the primary-role switch when more than one role is held |
| the landing rule | `src/app/guards/tailored-home.guard.ts` | a `canActivateFn` on the **bare `''` route and nothing else** |
| the routes | `src/app/app-routing.module.ts` | `''` → main home (guarded), `polari` → the same main home unguarded, `home` → the tailored page |
| where "home" points | `AppsNavService.homeRoute()` / `tailoredHomeApplies` / `polariHomeChosen` / `choosePolariHome()` / `chooseTailoredHome()` / `whenMineLoaded()` | ONE question, asked by both the guard and the header |
| the logo | `components/header/header.{ts,html,css}` | the Polari mark is now the way home, keyboard-reachable, and follows the same rule |
| the card's missing line | `modules/polariapps/custom/apps_roles.py` — `app_index()` gains `useCase` | the only backend change: the `use_case` string `GET /api/apps` already publishes, so the card says what the app is *for* |

**A page component, not a mode on the catalogue** — stated, because the brief asked for the reason. The catalogue
is every app on the instance with a deployment plan, an export, a build link and a persona filter per card; a
landing page is only yours, with none of that. A `mine` flag on `AppsHomeComponent` would have been a second page
hidden inside the first. **No new reusable component was introduced** — the cards, chips and buttons are the
catalogue's existing CSS, listed first in `styleUrls` so the two surfaces cannot drift apart.

### The rule, exactly

Landing on the bare `/` redirects to `/home` **only** when all of: signed in (a synchronous read of
`AuthSessionService`, which the single chained `APP_INITIALIZER` has already settled — the auth services were NOT
touched), **and** `mine` holds ≥ 1 app, **and** no session choice of the main page, **and** no shell clamp.

- **Never on a deep link** — by construction, not by a check: the guard is on `''` alone.
- **Never for anonymous** — and it costs them no round trip; the auth read comes first.
- **Never when My apps is empty.**
- **Escapable, per browser session:** "Polari home" goes to `/polari` *and* sets sessionStorage
  `polari-home-choice` = `polari`; `?home=polari` does it without the click; `?home=mine`, or opening `/home`,
  lifts it. Nothing is stored on the person's row.
- **The clamp wins.** `shellAppGuard` (a `canActivateChild` on the parent route) runs first and sends `/`,
  `/home` and `/polari` alike to the locked app; `tailoredHomeApplies` also refuses under a lock, so neither
  direction can undo it.
- **A backend that does not answer renders the main home** after 4 s rather than holding a blank page.

### Selftests

| suite | before | after |
|---|---|---|
| `modules/polariapps/apps_selftest.py` | 82/82 | **84/84** (2 new: every app in `/api/apps/mine` carries the `{name,title,useCase,route}` a card needs; a hidden app and its suggestion carry the same shape) |
| `src/app/services/apps-nav.service.spec.ts` (Karma, headless Chrome) | 9/9 (sep-0) | **15/15** (6 new §58: unasked → main; anonymous 401-shaped → main; signed in with no apps → main; one app → `/home`; the session choice and its lifting; the clamp always wins) |
| `npx ng build --configuration=production` | clean | **clean** (only the pre-existing CommonJS and 5 MB budget warnings) |

### Live proof — `polari-lean` on the home swarm (2026-09-18, entirely over the API)

Framework `6e19d03`, node `a305ee6`, suite `5a60d85`; one `pol prod apply`, 6/6 services, backend `online`
6/6 modules. Posture `dev`, gate `advisory` — **neither touched**.

| what | result |
|---|---|
| `GET /home` on the site | **200**, the SPA shell (`<app-root>`), as does `GET /polari` |
| the served runtime | `main.7d16a63a2931d578.js` carries `path:"home",loadComponent:…MyAppsHomeComponent` and `path:"polari",…HomeComponent`, and the string `polari-home-choice` |
| the tailored page's own chunk | `6720.a9908330210afc95.js` (the hash the served runtime names) carries **"Your primary role"**, **"Additional roles"**, **"Added by you"**, **"Polari home"** and **"Choose your apps"** |
| `GET /api/apps/mine` · demo-journalist | `held_roles ["journalist"]`, `primary_role "journalist"`, six apps — five `via: primary` (app-policy, app-scorecards-data-analysis, dmv-policy-analysis, judicial-lean, nutrition-planner) and app-topology-network `via: added`, the row §57 left pinned on purpose. **Every one carries a non-empty `useCase`** alongside name/title/route, so the cards render from this one call |
| `GET /api/apps/mine` · anonymous | **401**, unchanged |
| `apps_selftest.py` in the live container | **83/84** — the one failure is `sep-7 gate: ENFORCE refuses with the verdict (403)`, which flips `POLARI_APP_PERMISSIONS=enforce` against the container's own grant state; it is unrelated to §58 (nothing here touches the permissions gate) and passes 84/84 on the host |

**The redirect itself is HIS to see.** Every check above is an API or a bundle check; whether landing signed-in
actually lands you on your own page, whether "Polari home" holds for the session, and whether the page reads
well in either theme cannot be proven without a browser. See OWED below.

### OWED — his browser pass

Nothing about the REDIRECT has been seen by eye, and it is the half only a browser can show:

1. **Land signed in.** Open `https://prf.192.168.0.210.nip.io/` as demo-journalist in a fresh tab — it should
   land on the tailored home, with the five journalist apps under "Your primary role: journalist" and
   app-topology-network under "Added by you" (§57 left it pinned on purpose).
2. **"Polari home"** — click it: the main Polari page, and then going back to the bare URL must *stay* on the
   main page for the rest of that tab's session. Open `/home` again and the bare URL should tailor once more.
3. **A deep link is untouched** — `…/scoring/survival` or `…/display/security-events` in the same signed-in
   session must go straight there, no bounce.
4. **Anonymous** — a private window on the bare URL must show the main Polari home, unchanged, with no flicker
   through the tailored page.
5. **The logo** — it is now clickable; check it goes where the rule says and that the focus ring and the round
   crop read acceptably in both themes.
6. **Dark AND light** on the page itself: the group headings in `--text-on-bg-muted`, the primary group's
   `--brand-indigo` left edge, the role chips. It has never been rendered.
7. **Narrow window** — the card grid is the catalogue's `auto-fill, minmax(360px, 1fr)`; check the header's row
   of links wraps rather than squeezing.
8. **demo-viewer** (roles that bind nothing) — the bare URL must render the MAIN home, and `/home` typed by hand
   must explain itself rather than error.

## §59 — ct-0: the cause context (2026-09-18, built, selftested)

`CAUSAL_TRACE_OBJECT_FLOW_DESIGN.md` §11 row ct-0 — the CAUSE that travels with execution, and nothing else
(no `TraceTarget`, no `CausalEdge`, no journal: those are ct-1).

| piece | where | state |
|---|---|---|
| the contextvar + `push/pop/current/child/root_cause` | `accessControl/cause_context.py` (new, 200 lines) | built |
| the API root cause + `X-Polari-Trace` adoption | `accessControl/cause_middleware.py` (new) | built |
| middleware registration | `polariApiServer/polariServer.py:374, 474-481` — CORS → CORSExtraHeaders → **Auth → Cause** → Roleplay → ModuleLoading → Quiesce | built |
| trigger cause + firing stamp | `polariNoCode/event_dispatcher.py` `_record`, `fire()`, `tick()` | built |
| solution cause | `polariNoCode/SolutionExecutionEngine.py` `execute` → new `_execute_caused` | built |
| simulation cause | `simulationLocks/gate.py` `push_cause_for_run`, beside `push_run` | built |
| `trace_id` / `parent_id` columns | `polariNoCode/event_triggers.py` `TriggerFiring`; `ExecutionTrace` gains `trace_id` (+ `traceId` in `to_dict`/`from_dict`) | built |
| the thread inventory + its guard | `accessControl/selftest_cause_context.py` `KNOWN_THREAD_SITES` | built |

**Selftests.** `accessControl/selftest_cause_context.py` **41/41**. No regressions:
`modules/security/security_selftest.py` **139/142** (the 3 known environment failures, unchanged);
`polariNoCode/selftest_event_triggers.py` 15/15, `selftest_calendar_events.py` 12/12, `selftest_graph_builder.py`
14/14, `selftest_composition.py` 12/12, `selftest_parity.py` 69/69, `selftest_nocode_tests.py` 14/14,
`selftest_recurrence.py` 16/16, `selftest_display_flow.py` 13/13, `selftest_engine_model_op.py` 8/8,
`selftest_matrixop.py` 4/4, `selftest_turing.py` 16/16, `selftest_pendulum_embed.py` 9/9;
`simulationLocks/selftest_sim_locks.py` 40/40, `selftest_advisor.py` 11/11.

**Gotchas learned.**
1. Falcon routes AFTER `process_request`, so `req.uri_template` is None when the root cause is minted. The
   entry_ref is refined in `process_resource` (same cause, in place, no second push) — otherwise every map node
   would have carried an instance id instead of the template.
2. The design's dict has no id of its own, but `parent_id = current id` needs one; the cause carries an `id`
   beside the eight named fields.
3. The design's §4 table names SEVEN thread sites; the tree actually has **14** (initLocalhostPolariServer ×2,
   stompWebSocketServer, app_deb_builder, stub_odoo, iso_api, iso_builder ×2, video_api are the extras). The
   guard is seeded with all 14 and fails BOTH ways — an unlisted new site, and a listed site that vanished.
4. A gated SOLUTION run would otherwise get a phantom `simulation:solution:X` node on top of its own `solution`
   cause; `push_cause_for_run` skips that one case.

**OWED.**
- No browser/live proof: nothing renders yet (ct-1 brings the doors and the tables). Not seen on `polari-lean`.
- The tick thread's root cause is proven by calling `tick()` directly, not by the live `polari-event-tick` thread.
- `tileGeneratorAPI`, `video_api` and `quiesce` threads are LISTED but not yet handed a cause — ct-1 owes that.
- `ExecutionTrace.trace_id` has no TypeScript parity yet (the TS engine's trace model is untouched).

## §60 — op-0: owner-defined permissions — policy, stamp, gate (2026-09-18, built, selftested)

Design `AI-Notes/designs/OWNER_DEFINED_PERMISSIONS_DESIGN.md` §9 slice op-0. His ask (2026-09-18): *"other
people do not have the permission to alter the data on their vote, they only have partial read access and only
to the contents of the vote and groups the vote corresponds to, not who specifically made that vote."*
Owner-defined permissions are OPT-IN per class; nothing on a stock instance changes.

| built | where | what it is |
|---|---|---|
| `OwnedClassPolicy` | `modules/security/objects/security/OwnedClassPolicy.py` | the per-class opt-in; lists as `*_json` columns; `owner_field` names the column that holds the owner's `sub` |
| the model | `modules/security/custom/security_owned.py` | `policy_for` / `stamp_owner` / `owner_verdict` / `project` / `frozen` / `set_policy` / `verdict_for_id` |
| the CRUDE gate | `accessControl/owner_gate.py` | `owner_gate_read` (lists), `owner_gate_write` (update/delete), `owner_gate_stamp` (create, with rollback) |
| 5 call sites | `polariApiServer/polariCRUDE.py` | `on_get`, `on_get_field_profile`, `on_put`, `on_delete`, `on_post` — 1–4 lines each |
| 3 doors | `modules/security/security_api.py` | `GET /api/security/owned`, `GET|POST /api/security/owned/{class_name}`, `GET /api/security/owned/{class_name}/{object_id}` |
| registration | `security_basis`, `objects/security/__init__`, `security_seed`, `feature_imports` (~:1246), `polariServer` (~:1226), `polari-app.json` regenerated | 31 → 32 row classes, 31 → 32 seed pairs |
| first class in | `security_seed.SEED_OWNED_CLASS_POLICIES` | `UserAppPreference` (§57): owner read/update/delete, `others_verbs []`, `owner_visible false`, `owner_field: sub` |

**Selftests.** `modules/security/security_selftest.py` 170/173 (was 139/142 — +31 new checks, all passing).
The 3 failures are the known environment ones and are unchanged: ledger `mac_enforced`, mac profiles, expired
internal certs. `modules/polariapps/apps_selftest.py` 84/84, no regression.
`python3 -m moduleService.manifests conform --all` 61/61 OK. `polariApiServer.polariServer` imports clean.

**Gotchas found / kept.**
- The design calls `on_put_collection` the create path; CRUDE's real create is `on_post` — the collection
  responders (`on_get_collection`, `on_put_collection`, `on_delete_collection`) are `pass` STUBS that no route
  reaches. The stamp went into `on_post`; each stub now carries a comment saying what it must call when built.
- `UserAppPreference` keys its person by `sub`, not `owner`. Adding a duplicate `owner` column to a live class
  would violate the per-class schema freeze, so the POLICY names the column (`owner_field`, default `owner`).
  That is op-0's one addition to the design's §2 field list.
- An enforce-mode refusal at create happens AFTER the create loop has already built the rows, so
  `owner_gate_stamp` rolls them back out of the tree — otherwise the refusal would leave exactly the ownerless
  instance it exists to prevent.
- A malformed `frozen_when` is treated as NOT frozen (a policy typo must never lock every owner out of their
  own rows) and lands in the SecurityEvent ledger so it stays visible.
- `security_owned._rows` goes through `security_observe._all_rows`, so test doubles live in `_FALLBACK` and
  never in the manager's own table (the §54 "PolyTyping for type SimpleNamespace" gotcha).

**OWED.**
- op-1: `OwnerGrant` + the grants doors (grantee by group or `sub`, `valid_until`, the Sharing tab as a
  configured table). `owner_may_grant` / `grantable_verbs` / `grantee_kinds` are STORED and honoured by nothing.
- op-2: the anonymised side channels — broadcast id suppression, trace-journal actor/object suppression,
  `SecurityEvent.target` = class. `anonymised` and `transfer` are stored columns with no behaviour yet.
- op-3: `Ballot` rows + policy in governance; `VoteRecord.ballots_json` replaced by a derived tally.
- op-4: the `app.owned` manifest stanza, its validation and convergence (never overwriting an admin's row).
- No live proof and no browser pass: nothing here has run on `polari-lean`, and there is no page for the
  policies or a per-instance verdict yet. `frozen_when` has only been exercised against in-memory doubles.
- The `events` verb is in `OwnedClassPolicy.OWNER_VERBS` but `on_event` carries no owner gate yet.

## §61 — ct-1: trace target, causal-edge map, effect journal (2026-09-18, built, selftested)

Design `AI-Notes/designs/CAUSAL_TRACE_OBJECT_FLOW_DESIGN.md` §2/§3/§11 row ct-1, on top of §59's cause context
(ct-0) and §60's owner policies (op-0). His asks: *"trace different events and functions … and track the kinds
of changes that occur due to those events"*, *"only ever tracing one kind of object at a time"*, *"limits on how
many tracing objects we generate"*, *"tracing should not occur in production"*.

| built | where |
|---|---|
| `TraceTarget` — the ONE armed class, its budgets, its live counters, `active` | `modules/security/objects/security/TraceTarget.py` |
| `CausalEdge` — Ledger A, one counted row per `cause\|effect\|means` | `modules/security/objects/security/CausalEdge.py` |
| the model: `arm` / `disarm` / `status` / `touch` / `record_edge` / `record_effect` / `record_outbound` / `coverage` / `edges` / `journal` / `prune_map` | `modules/security/custom/security_trace.py` (643 lines) |
| Ledger B: `WriteJournalEntry` gains `trace_id`, `cause_ref`, `verb`, `origin`, `actor`, `target`; `journal_fields`, `prune_journal` (ring `POLARI_TRACE_JOURNAL_ROWS`, 20 000) | `polariRefs/write_journal.py` |
| seam (a) the CRUDE gate: `touch()` then `endpoint:<entry_ref> → object:<Class>:<verb>` (`crude`) | `accessControl/app_permissions_gate.py:74-88` |
| seam (b) creates/deletes + the delete CASCADE, one journal row each under one cause | `objectTreeManagerDecorators.py:672-729` (`_traceEffect`, `noteTreeMutation`, `noteTreeDeletion`, `_traceDeleteCascade`), called at `deleteTreeNode` `:1528` and `:1632` |
| seam (c) updates: the field NAME, never the value, behind a module-level armed flag read FIRST | `objectTreeDecorators.py:36-73` (`set_trace_armed`, `_trace_setattr`) + `:153-154` in `treeObject.__setattr__` |
| seam (d) trigger-fire + solution-run edges with `run_as` | `polariNoCode/event_dispatcher.py:151-179` (`_trace_edges`), called from `_record` `:198` |
| doors `GET\|POST\|DELETE /api/security/observe/trace`, `GET /api/security/trace/edges`, `GET /api/security/trace/journal` | `modules/security/security_api.py:86-88`, `:551-614` |
| the Trace tables on `security-events` (TraceTarget with `started_by:person`, CausalEdge), converged by `seed_security_pages` | `modules/security/security_page.py:125-133` |
| registration in all five sites + manifest (32 → 34 classes) | `objects/security/__init__.py`, `security_basis.py`, `security_seed.py`, `feature_imports.py:1246`, `polariServer.py:1238`, `polari-app.json` |

**Selftests.** `modules/security/security_selftest.py` **186/189** (was 167/173 with the same 3 failures — +16
new ct-1 checks, all passing): production arms nothing; a second arm refused naming the active one; the scope
rule (a chain on another class writes nothing); counted + deduped edges; `max_edges` → self-disarm +
`stopped_because` + ONE SecurityEvent + `dropped` counting; the journal's columns; the anonymised rule; the
journal cleared on the next arm; the window; the restart rule; the map ceiling; the `__setattr__` seam; the
three doors + the §54 route guard. The 3 failures are the known environment ones (ledger `mac_enforced`, mac
profiles, expired internal certs). `accessControl/selftest_cause_context.py` 41/41 (no new thread site).
`modules/polariapps/apps_selftest.py` 84/84. noCode: event_triggers 15/15, graph_builder 14/14, parity 69/69,
turing 16/16, recurrence 16/16, nocode_tests 14/14, composition 12/12, calendar 12/12, display_flow 13/13,
engine_model_op 8/8, matrixop 4/4, pendulum 9/9. `persist_debounce` 13/13, `persist_tombstones` 43/43,
`crude_delete_blast` 21/21, `quiesce` 27/27. `manifests conform --all` 61/61.

**The `__setattr__` cost when NOT armed** (200 000 scalar assignments × 7 runs, median of runs, same box, one
`_TRACE_ARMED` global read added): **with the hook 0.1337 s (668 ns/assignment), without it 0.1359 s
(680 ns/assignment)** — the hooked build measured 12 ns *faster*, and the run-to-run spread within each build
was ±60 ns. The hook is inside the noise; it is one `LOAD_GLOBAL` + truth test, and everything else (the class
comparison, the lazy import, the recorder) is behind it.

**Gotchas found / kept.**
- Traced-ness is keyed by **trace_id**, not by the cause dict: ct-0's `child_cause()` builds a FRESH dict at
  every seam, so a `traced` flag written into the cause would be lost one frame down. The chain is traced, not
  the frame.
- A constructor's own assignments all pass through `__setattr__`, so one create would have landed as a create
  row plus N update rows. `_CREATED` (bounded, cleared on arm) suppresses the updates for an id created in the
  same chain — those field values ARE the create.
- `arm()` clears only `origin='local'` journal rows. The remote-write journal (xsim-4's cross-instance audit
  trail) shares the class and is not this arc's to delete.
- The restart rule is the SIMPLER of the two the design allows, chosen deliberately: a knob naming a target this
  process did not arm disarms it with `stopped_because='restart'`. The counters (persisted rows) survive and
  read honestly; the live state (the armed flag, the traced-chain set) does not, and saying so beats resuming.
- `_STATE` is one process-global arming, which is right for one manager and is why the selftest's per-check
  manager doubles must be disarmed in order.
- op-2's OWED line "trace-journal actor/object suppression" is now DONE for the journal half (design §5, one
  `if` against `OwnedClassPolicy.anonymised`); the broadcast-id and `SecurityEvent.target` halves remain op-2's.

**OWED.**
- ct-2: the remaining event edges — `emit`, nested solutions, `ws-publish`, and the simulation / boot root
  causes. Only `crude`, `trigger-fire` and `solution-run` are recorded today.
- ct-3: `polariApiServer/outbound.py` adoption — `record_outbound()` is built and callable and NOTHING calls it
  yet on this branch (the wrapper is a concurrent build).
- ct-4: the closure doors (`/observe/closure?profile=|event=|role=`), `review` + `verify` gaining the
  transitive verdict, and the closure tables on the page.
- No live proof: nothing here has run on `polari-lean`, and no browser has seen the Trace tables. `max_traces`,
  `max_journal_rows` and `max_depth` are honoured in code but only `max_edges` is proven by a check.
- The CRUDE seam records one edge per act in dev regardless of `POLARI_APP_PERMISSIONS`; "after its verdict" in
  the design means after the observation, since with the gate `off` there is no verdict to be after.

## §62 — ct-3: the outbound wrapper, adoption, the straggler guard (2026-09-18, built, selftested)

`polariApiServer/outbound.py` is now the ONE seam every call to another system
passes. `send(kind, name, means, fn, payload_classes=…)` runs `fn` and records
the edge either way; `http_request(…, lib='requests'|'urllib')` keeps each
site's own library, timeout and return type; `wrap(kind, name, means, classes)`
is the context manager / decorator for SDK sends (OpenAI, minio, paho).
`X-Polari-Trace: <trace_id>/<parent_id>` is added ONLY for `system_kind ==
'peer'` and only when a cause exists — the actor's `sub` and the groups never
cross the wire, and production posture mints no cause so it carries no header.
Recording goes to `security.custom.security_trace.record_outbound` by LAZY
import inside try/except: an absent or exploding recorder cannot change a
result, and the outcome (`ok` / the exception's type name) rides as `detail`
only when the recorder's signature accepts it (inspected once — a `TypeError`
from inside the recorder must never become a duplicate row).

### Migrated sites — file → kind / name / means / payload classes

| site | kind | name | means | payload classes |
|---|---|---|---|---|
| `accessControl/keycloak_client.py:77,117,154,184` (token, roles, groups, role-mappings) | keycloak | realm | rest | — |
| `polariApiServer/authMeAPI.py:107` (JWKS probe) | keycloak | realm | rest | — |
| `modules/odooconnect/custom/odoo_client.py:76` (`jsonrpc`, the ONE Odoo wire seam) | odoo | config row name | json-rpc | binding `polari_class` on a push, else — |
| `modules/odooconnect/custom/odoo_sync.py:285,292` (push write/create) | odoo | config row name | json-rpc | the binding's `polari_class` |
| `modules/collab/livekit_remote.py:114,185` (reachability, RoomService) | livekit | livekit | probe / rest | — |
| `modules/reticulum/rns_remote.py:72,91,144` (reachable, status, `_sidecar_json`) | reticulum | sidecar | probe / rest | — (LXMF carries free text, not rows) |
| `materialsScience/engines/remote.py:92,120` (capability, `remote_post`, `_meter` kept) | engine | msci | probe / rest | caller-supplied |
| `modules/mathshapes/cad_remote.py:75,100` | engine | cad | probe / rest | caller-supplied |
| `modules/cntfet/cnt_remote.py:82,143` | engine | cnt | probe / rest | caller-supplied |
| `topology/provider_registry.py:70` (`_probe`) | provider | capability-probe | probe | — |
| `polariPeers/peers_api.py:88` (`_http_get_json`) | peer | PeerNode name | rest | `SimulationDefinition` on the sim pull |
| `polariPeers/join_flow.py:91,103` (`_http_post_json`, incl. the dev-TLS retry) | peer | `''` (not a PeerNode yet) | rest | — |
| `polariRefs/remote_api.py:45` (`_http_json`: rung-4 resolve / apply-write / core epoch) | peer | target instance, `core` | rest | `ref['className']` |
| `polariApiServer/ai_actions.py:86,96` (HTTP-to-self executors) | self | polari-api | rest | the path's class segment |
| `polariApiServer/ai_tools.py:86` (read tools) | self | polari-api | rest | the path's class segment |
| `polariApiServer/reasoning_provider.py:110,167` (Anthropic + OpenAI-compatible SDK) | provider | provider name | sdk | — |
| `polariApiServer/voiceAPI.py:155,184` (STT/TTS — audio bytes NEVER recorded) | provider | voice-stt / voice-tts | sdk | — |
| `polariDBmanagement/managedObjectStore.py:62,127,138` (connect, put, get) | s3 | endpoint | s3 | — (blobs, not rows) |
| `modules/appstore/custom/appstore_minio.py:83` (artifact get) | s3 | endpoint | s3 | — |
| `modules/mqttbridge/mqtt_api.py:122` (explicit test publish) | mqtt | broker row name | mqtt | — |
| `polariApiProfiler/endpoint_fetch.py:142` (`default_fetcher`) | profiler | api-endpoint | rest | — (URL never recorded: apikey-query) |

### KNOWN_STRAGGLERS (`polariApiServer/selftest_outbound.py`) — 25 files, each with a reason

| file | reason |
|---|---|
| `modules/security/custom/kc_admin.py` | **owned by ct-1's agent this round** — migrate in the slice that lands `security_trace` |
| `moduleService/dyn_proofs/*.py` (9) | dyn proof harnesses — they dial a LIVE server on purpose |
| `modules/testing/custom/{twin_http,twin_fixtures,check_runners,app_benchmark}.py` | the testing module IS the harness |
| `topology/topology_testing_api.py` | topology self-test probes, not a product send |
| `moduleService/json_seeds.py` | boot-time seed fetch — design §3's `boot` root cause is ct-1/ct-2 |
| `modules/iso/custom/iso_builder.py` | Ubuntu archive downloads during ISO build (host build step) |
| `modules/iso/custom/iso_autoinstall.py` | the `urlopen` is inside a TEMPLATE STRING run on the INSTALLED machine |
| `polariNetworking/managedSink.py` | httpx ASYNC client — `outbound.send` is synchronous; an async seam is its own slice |
| `polariApiProfiler/apiProfiler.py`, `api_discovery.py` | the legacy profiler engine; `endpoint_fetch.py` is the migrated seam |
| `polariApiServer/tileGeneratorAPI.py` | tile fetch on its OWN thread (design §4) — needs the cause handed in first |
| `modules/printing_suite/custom/adapters.py`, `modules/resources/custom/{node_resources,profile_analysis}.py`, `modules/dmvdata/custom/census_pull.py`, `modules/cntfet/custom/cnt_snapshot.py` | product sends NOT in design §5's list — named, not forgotten |

The guard fails on a NEW unlisted hit (by path) **and** on a listed file that
has disappeared, so the table can never quietly describe a tree that moved on.
`tests/`, `*selftest*.py`, `node_modules`, vendored and build dirs are skipped.

### Selftests — before (HEAD 8526439, clean worktree) → after

```
NEW polariApiServer/selftest_outbound.py           —      → 51/51
accessControl/selftest_cause_context.py         41/41    → 41/41
modules/odooconnect/odoo_selftest.py            27/27    → 27/27
modules/odooconnect/odoo_sync_selftest.py       26/26    → 26/26
modules/odooconnect/odoo_orders_selftest.py     20/20    → 20/20
modules/odooconnect/odoo_scenarios_selftest.py  20/20    → 20/20
modules/collab/collab_selftest.py          crash(schema) → crash(schema)  [pre-existing, identical]
modules/reticulum/reticulum_selftest.py        183/184   → 183/184        [pre-existing 1 fail]
modules/mqttbridge/mqttbridge_selftest.py       10/10    → 10/10
modules/cntfet/cntfet_selftest.py              858/…     → 858/…          [pre-existing]
modules/cntfet/snapshot_selftest.py               9/9    → 9/9
modules/mathshapes/shapes_selftest.py           24/24    → 24/24
materialsScience/selftest_engine_models.py      40/40    → 40/40
topology/selftest_engines.py                    18/18    → 18/18
topology/selftest_topology.py                   47/52    → 47/52          [pre-existing 5 fails]
topology/selftest_testing.py                    18/19    → 18/19          [pre-existing]
polariPeers/selftest_peers.py                   15/15    → 15/15
polariPeers/selftest_agreements.py              23/23    → 23/23
polariPeers/selftest_modules.py                 24/24    → 24/24
polariPeers/selftest_mesh.py                    12/12    → 12/12
polariRefs/selftest_refs.py                     51/51    → 51/51
polariRefs/selftest_directory.py                13/13    → 13/13
polariDBmanagement/selftest_shared_db.py        16/16    → 16/16
polariDBmanagement/selftest_db_adapters.py      pass     → pass
polariApiServer/selftest_quiesce.py             pass     → pass
polariApiServer/selftest_persist_debounce.py    13/13    → 13/13
modules/appstore/appstore_selftest.py           85/85    → 85/85
polariApiProfiler/selftest_profiler_drift.py    21/21    → 21/21
```
`PYTHONPATH=.:modules python3 -c "import polariApiServer.polariServer"` clean.
Nothing regressed.

### Gotchas found

- **Two selftest stubs had frozen transport signatures.** `polariPeers/
  selftest_peers.py` patched `_http_get_json` with `lambda url:` and
  `polariRefs/selftest_refs.py` with `def _fake_http(method, url, body,
  headers)`. Both broke the moment the real seam gained `peer_name` /
  `payload_classes`. Fixed by absorbing extra kwargs (`*_a, **_k` / `**_kw`) —
  the assertions are untouched. Any future stub of an injectable transport
  should absorb kwargs from the start.
- **`polariApiServer/__init__.py` is empty**, so `from polariApiServer import
  outbound` is safe from `accessControl`, `modules/*`, `polariDBmanagement`,
  `polariRefs` and `topology` with no import cycle. Verified by importing all
  21 migrated modules and `polariServer`.
- **The manager.** There is no process-wide manager accessor in core except
  `topology.provider_registry.MANAGER` (injected at `polariServer.py:768`).
  `outbound.process_manager()` reads that ATTRIBUTE (never an imported copy)
  and tolerates None.
- **`_meter` kept.** `materialsScience/engines/remote.py` metering (sep-4) and
  the wrapper record DIFFERENT things — bytes/latency for capacity vs. what
  left for the map. Both fire; neither was folded into the other.
- **`apiProfiler.py` matches the guard on two PRINT statements** containing the
  literal `requests.request()`. It is a straggler anyway, so no special case
  was added — a line-level exemption would have been a lie.
- The URL is accepted by `send()` but deliberately **not recorded**: an
  `apikey-query` endpoint carries its secret in the URL (`endpoint_fetch.redact`).

### OWED

1. **`modules/security/custom/kc_admin.py:86`** — migrate once ct-1's
   `security_trace` lands; remove the row from `KNOWN_STRAGGLERS` (the guard
   fails if the row stays after the hit goes, which is the point).
2. **`X-Polari-Trace` proven on two live instances** — the ct-3 proof in design
   §11 ("an Odoo push and a peer lease-write appear as edges on BOTH
   instances") is unproven: it needs `record_outbound` writing real
   `CausalEdge` rows and a two-node run. Only the header-emission half is
   selftested here.
3. **The peer module-install edge carries no classes** — `peers_api.py`'s
   bundle fetch cannot name `manifest.requiredClasses` until the bundle has
   landed. Naming them needs a second record after the fetch, i.e. a ct-1
   recorder call outside the wrapper. Left `()`, noted in the code.
4. **ct-9 traffic policies** — `OutboundPolicy` / `InboundPolicy`,
   closed-by-default, suggested from what this seam observes. Deliberately NOT
   built here; the wrapper only observes.
5. The 6 "not in §5's list" product stragglers (tiles, printing, resources ×2,
   census, cnt snapshot) and the async `managedSink` should each get a slice or
   a standing ruling.

## §59–§62 addendum — live proof on `polari-lean` (2026-09-19 00:00Z, framework `3314792`, posture dev, gate advisory)

Deployed with `pol prod apply` (detached; the sudo prompts it cannot answer without a terminal are the known vault/cert
steps and did not stop the image builds); backend answered 200 after ~110 s of lazy boot. Entirely over the API with
password-grant tokens for `demo-admin`, `demo-journalist`, `demo-viewer`:

| step | result |
|---|---|
| anonymous `GET /api/security/observe/trace` | 401 |
| admin arms `AppPermissionProfile` (max_edges 50) | `ok`, `started_by` = the admin's Keycloak `sub` (no username anywhere), posture `dev`, `tracing: true` |
| second arm (`RolePrototype`) while armed | refused, naming the active target, its class, when and by whom |
| journalist `GET /AppPermissionProfile` ×2 (CRUDE) | ONE `CausalEdge` `endpoint:GET /AppPermissionProfile → object:AppPermissionProfile:read` (means `crude`) with `count: 2` — counted, not duplicated |
| journalist `GET /RolePrototype` (untraced class) | nothing written — the scope rule holds |
| journal after reads | 0 rows (reads write nothing) |
| status | `traces_opened 2, edges_written 2, journal_written 0, dropped 0`; `coverage` lists the class with `started_at` |
| manual `DELETE` | disarmed; `stopped_because: manual`, `stopped_at` set; coverage row kept, `active: false` |
| `GET /api/security/owned` | mode `advisory`; `UserAppPreference` enabled, `owner_field: sub`, owner read/update/delete, others `[]` |
| journalist `GET /UserAppPreference` | 200, their own row whole, **no** owner advisory (the owner floor) |
| viewer `GET /UserAppPreference` | 200 (advisory), `X-Polari-Owner-Advisory: would-deny UserAppPreference:<id>:read` (the others' ceiling) |
| both, class gate | `X-Polari-Permission-Advisory: would-deny UserAppPreference:read` — the class gate decides FIRST; the owner rules only narrow |

**Found on the way:** (1) `X-Polari-Owner-Advisory` is not in `Access-Control-Expose-Headers` (only `X-Polari-Auth` and
`X-Polari-Permission-Advisory` are), so a browser cannot read it — one line in `CORSExtraHeadersMiddleware`, owed.
(2) The design's "owner floor may exceed the class profile" was a contradiction with its own step 1; as built the class
gate always runs first and the owner rules only narrow — design §3/§8 corrected to say so. NOT proven live: counters
surviving a restart (selftested only), budget-disarm (selftested), the Trace tables on the `security-events` page by eye.

---

## §63 — ct-2 + ct-4: the remaining edges and the closure (2026-09-18, built, selftested)

Design `AI-Notes/designs/CAUSAL_TRACE_OBJECT_FLOW_DESIGN.md` §3 (seams), §6 (the closure), §11 rows ct-2 / ct-4.
ct-1 gave the target, the map (`CausalEdge`) and the journal; ct-3 gave the outbound wrapper. **ct-2** fills in the
seams ct-1 left, **ct-4** reads the map back. NO new row classes — the security class count stays **34**.

### ct-2 — the remaining event edges (every hook: lazy import, never raises, no-op unless armed AND traced)

| edge | means | hook |
|---|---|---|
| `solution:S → event:E` | `emit` | `polariNoCode/event_dispatcher.py:_trace_emits`, called from `dispatch_trace_events` **before** the EventTrigger guard — an event nothing listens to is still on the map |
| `solution:caller → solution:callee` | `solution-run` | `polariNoCode/SolutionExecutionEngine.py:_trace_nested_solution`, at the `SolutionInvocation` handler, `run_as` = the callee's declared `executionRights` |
| `object:C:verb → event:topic:C` | `ws-publish` | `modules/grpcbridge/custom/transport_mux.py:_trace_publish` in `publish_change` — COUNT only, no ids; `touch` first (a broadcast can be the first seam) |
| `<cause> → peer:N:shared-db` | `shared-db` | `polariRefs/remote_hydration.py:_trace_shared_db`, on the successful rung-3 read, class in `detail` |
| `<cause> → peer:X:bundle-export/-install` | `bundle-*` | `polariPeers/module_exporter.py:trace_bundle`, called from `export_module` and from `peers_api.on_post_modules_install` (never on a dry run) |
| `ai` ROOT cause | — | `polariApiServer/ai_actions.py` `execute()`; `_record` writes `trace_id`/`parent_id` into `data/ai_provenance.jsonl` |
| `boot` ROOT causes | — | `moduleService/seed_upsert.py:upsert_seed_rows` (a root SEVERS the chain on purpose: seeded rows are never a person's) and `polariApiServer/lazy_boot.py:AdmissionWorker.run` (module boot) |

Also built here (design §5, one `if`): the change BROADCAST of a class whose `OwnedClassPolicy.anonymised` is set
drops `instanceIds` — subscription to `/topic/<Class>` is unauthenticated until ct-6, so a deliberately unlinkable
class must not announce which rows a person just wrote. Class + operation stay (a subscriber still knows to re-read).

### ct-4 — the closure

`modules/security/custom/security_closure.py` (new, in the manifest) holds the walk; **`security_trace.closure(manager,
start_nodes, *, max_depth=None)` is the STABLE public name** — ct-8 reads it by lazy import. Cycle-safe BFS over
`CausalEdge`, hop-bounded (`MAX_HOPS` 32), returning `objects / events / solutions / peers / external / other /
edges / coverage / not_traced / counts / start`, every item with `origin` (`observed | closure | declared`),
`definer_only` and `evidence` `{count, first_seen, last_seen, min_depth, sample_trace_id, target, seen}`.
`definer_only` = EVERY path reaching the node crossed a `solution-run` edge whose `run_as` is `definer`.

- `GET /api/security/observe/closure` — `?profile=` (`explicit` / `reachable` / `implicit = reachable − explicit`),
  `?event=` (the solution and AS WHOM), `?role=` (the role-play recording's observed acts), `?class=`, or no
  parameter = the ONE armed target's class. 401 anonymous; 404 names the profiles that do exist.
- `review(role)` gains `closure`; `verify(role, group)` gains `transitive: {covered, total, definer_only,
  not_traced, uncovered, reading}` — *"the profile covers N of M transitively-touched class × verb pairs; K are
  reached only through triggers running as definer"*. Both defended: the direct answer stands if the closure cannot
  be computed. **Nothing enforces or widens itself** — disclosure only; the person's confirmation is ct-8's.
- `security-events` page: five configured structured panels over the closure door (objects, solutions, events,
  flows, and the NOT-TRACED list). No raw JSON, no new component.

### Selftests (all run, nothing regressed)

`modules/security/security_selftest.py` **200/203** (was 186/189 — +14 checks; the same 3 known environment
failures: ledger mac_enforced, mac profiles, expired internal certs) · `accessControl/selftest_cause_context.py`
**41/41 for this slice** (see gotcha 1) · `polariApiServer/selftest_outbound.py` 51/51 ·
`polariRefs/selftest_refs.py` 51/51 · `modules/polariapps/apps_selftest.py` 84/84 · `modules/composition/
composition_selftest.py` 75/75 · the 12 noCode selftests (incl. parity 69/69) · grpcbridge contracts 31/31,
serving 23/23, c_twin 7/7 · `modules/testing/stomp_selftest.py` 6/6 · the 6 polariPeers selftests ·
`python3 -m moduleService.manifests conform --all` **61/61**. The nocode/peers suites were re-run with
`PYTHONPATH=.` alone to prove every new hook is silent when the security module is not on the instance.

### Gotchas

1. **`selftest_cause_context` reads 40/41 in the working tree** — the unlisted thread site is
   `modules/polariapps/apps_page.py`, an UNTRACKED file from the concurrent ct-8 build, not this slice. It was
   deliberately NOT added to `KNOWN_THREAD_SITES`: the table's own staleness check fails when a listed site does
   not exist, so listing another agent's uncommitted file would break this commit on its own. ct-8 adds it.
2. Manifest drift is real and silent until `conform` runs: a new `custom/*.py` must be added to
   `modules/security/polari-app.json` (`security_closure` was, 60/61 → 61/61).
3. `HOW_CLOSURE` is a MODULE constant, not a `SecurityAPI` class attribute — the tree's identifier scan walks a
   treeObject's attributes and logs anything it cannot type as an invalid instance value on every pass.
4. A start node the map has never recorded still appears in the answer with `evidence.seen = false`. That is
   deliberate: "this verb of the armed class has produced no edges yet" is an answer, not a gap.

### OWED

- **ct-6** the STOMP subscribe gate (`ws-subscribe` edges; subscription follows the CRUDE `read` verdict under the
  same mode). Until it lands, WHO subscribes is unknown and is not guessed — only the publish edge is recorded.
- **ct-7** `ObservationSession.task`, review grouped by task, `app.flows` validation.
- **Live proof, none of it done:** arm a class on the home staging stack, drive a real chain (request → trigger →
  solution → broadcast → peer read) and read `/api/security/observe/closure?profile=` and `?event=` against it;
  confirm the `ai` root cause and the `trace_id` in `data/ai_provenance.jsonl` from a real `/act` confirm;
  confirm the anonymised broadcast drops `instanceIds` on the wire (selftested against a captured publish only).
- **Browser pass:** the five closure panels on `/display/security-events` — that they read as tables and not as a
  JSON wall, and that NOT TRACED is legible as an answer rather than as an empty list.

## §64 — ct-8: security decisions per app × version, coverage, the human confirmation (2026-09-18, built, selftested)

Design `AI-Notes/designs/CAUSAL_TRACE_OBJECT_FLOW_DESIGN.md` §6 ("Accountability" + "Coverage accounting", his
rulings: *"track how many objects have any kind of security coverage and how much if any"*, *"track security
policy decisions of different types and how many have been covered per app, since security must be worked on at
a per-app basis and per each version release"*). Built in **`modules/polariapps/`**, not `security/`: the rows
are about APPS and RELEASES, exactly as §57 put `RoleAppBinding`/`UserAppPreference` there. Everything read out
of the security module goes through a guarded import or a bare table name, so polariapps still enumerates and
still counts on an instance carrying no security module.

### Build

| file | what |
|---|---|
| `objects/apps_security/SecurityDecision.py` | the row: `app`, `app_version`, `release`, `kind`, `subject`, `state`, `evidence_json`, `derived_from`, `confirmed_by` (a Keycloak `sub` ONLY), `confirmed_at`; `name` = `app\|app_version\|kind\|subject` |
| `objects/apps_security/_shared.py` | the 8 kinds, the 6 states, `decision_name()` |
| `apps_security_basis.py` | the sap-2c index (re-export) |
| `custom/security_subjects.py` | `enumerate_subjects()` + per-kind collectors, `app_version()`, `current_release()` |
| `custom/security_decisions.py` | `converge()`, `changed_subjects()`, `bump_version()`, `confirm()`, `decisions()` |
| `custom/security_coverage.py` | `coverage()` — by kind × state, instance counts, none/partial/full |
| `custom/security_confirm.py` | `confirm_profile()` — THE one human confirmation on the concrete step |
| `apps_page.py` | `/display/apps-security` (configured tables + structured panels) + `seed_apps_pages` converge |
| edits | `apps_api.py` (5 doors), `feature_imports.py`, `polariServer.py` (class + page seed), `module_endpoints.py` (page converge), `polari-app.json` (regenerated: 7 classes, 25 files), `accessControl/selftest_cause_context.py` (`apps_page.py` thread site) |

**Enumeration sources, per kind** — subjects come FROM THE APP, so `open` is a real gap: `profile-verb` =
classes × 5 verbs × groups (`AppPermissionProfile` for the app + `PermissionObservation` groups; `*` only where
nothing names a group) · `owner-policy` = every class (absent `OwnedClassPolicy` row = open) · `trigger-run-as`
= `EventTrigger` rows whose source/inputs/solution name a class, carrying `run_as` · `flow-declared` = manifest
`app.flows` (§9 — no manifest writes it yet) + one `flow:undeclared:<system>` finding per observed system ·
`role-binding` = `app.roles` + personas + `RoleAppBinding` · `outbound` = `CausalEdge` `external:`/`peer:` edges
caused by the app's classes (`outbound.py` publishes `SYSTEM_KINDS`/`MEANS` but no site registry — stated) ·
`inbound` = `InboundPolicy` rows (ct-9 builds them; empty and says so) · `trace-coverage` = `TraceTarget` rows
plus ct-4's `security_trace.closure` when present.

**Doors** (401 anonymous on reads and writes, ADMIN_ROLES on the writes): `GET /api/apps/security/decisions?
app=&kind=&state=` · `POST /api/apps/security/decisions/confirm` · `POST /api/apps/security/confirm-profile`
(verify → hash the proposal → one `confirmed` row per class × verb × group → THEN
`security_observe.mark_prototype(role, 'concreted', profile, by=sub)` by lazy import) · `POST /api/apps/security/
bump?app=&from=&to=` · `GET /api/apps/security/coverage?app=`.

### Selftests

`modules/polariapps/apps_selftest.py` **125/125** (was 84/84; +41 ct-8 checks) · `modules/security/
security_selftest.py` **200/203, untouched by this slice** (the same 3 known environment failures: ledger
mac_enforced, mac profiles, expired internal certs) · `accessControl/selftest_cause_context.py` **41/41** ·
`moduleService.selftest_lazy_imports` 23/23 · `python3 -m moduleService.manifests conform --all` **61/61** ·
`python3 -c "import polariApiServer.polariServer"` clean.

### Gotchas

1. **The app page has no seedable slot.** `/app/<name>` is `AppHomeComponent`, an Angular component over
   `GET /api/apps/nav/{app}` — not a Display row — so the coverage tables went to the polariapps MODULE page
   `/display/apps-security` (design asked for "each app's own page"; giving `AppHomeComponent` a seedable slot
   is frontend work, and faking it with a new component is against his rule). Stated in `apps_page.py`.
2. **Subject shape deviates for `profile-verb`**: `Class:verb@group`, not the design's bare `Class:verb` — two
   groups' rulings on the same class × verb would otherwise collide in the dedup key.
3. **A Polari-App has no manifest version of its own** (it is a configuration of modules), so `app_version()`
   digests the module SET as `set-<8 hex>` with the source string spelling out `pkg@version` — a module bump
   therefore changes the app version, which is exactly when last release's rulings must be re-examined.
   `release` is `''` until `ReleaseManifest` (planned, not built) or `POLARI_RELEASE` says otherwise.
4. **Converge must preserve the bump's own evidence.** The first build lost `inherited_from` /
   `stale_because` / `confirmed_by_previously` because the converge that follows a bump refreshed the evidence
   blob; `CARRIED_EVIDENCE_KEYS` now survives a refresh.
5. `from security.custom import security_trace` binds the package attribute and ignores a `sys.modules` stand-in
   — `importlib.import_module` is what makes the guarded closure read testable with a fake.
6. Adding a thread (the page converge) breaks `selftest_cause_context` until the site is listed in
   `KNOWN_THREAD_SITES` — done here, which also clears ct-4's gotcha 1.

### OWED

- **ct-9** the policy ROWS (`OutboundPolicy` / `InboundPolicy`): the `outbound`/`inbound` kinds enumerate today
  from observed edges and from nothing respectively. Once the rows exist, the inbound subjects stop being empty.
- **The release gate does not cite these counts yet** — `coverage()` returns `stale`/`open` per app × version,
  but nothing in the build/release path reads it. Wire it into the manifest findings.
- **Live proof, none of it done:** converge on the home staging stack against a real app, confirm a real profile
  through `/api/apps/security/confirm-profile` and check the `RolePrototype` flips to `concreted`, then bump a
  module version and see `stale` appear.
- **Browser pass:** `/display/apps-security` — that the coverage panel reads as a table (per app × version, kind
  × state, instance counts) and not as a JSON wall, and that `confirmed_by` resolves through the `person` format.

## §65 — ct-6: STOMP subscribe follows the CRUDE posture (2026-09-19, built, selftested)

His ruling 2026-09-18 (design §10): *"STOMP should just follow from the CRUDE security posture … they should be
the same."* Until now ANY socket could subscribe to ANY `/topic/<Class>` — the one door in the instance with no
identity and no verdict. It now asks the same question the CRUDE gate asks, of the same function, under the same
knob.

| what | where | note |
|---|---|---|
| identity on the socket | `accessControl/stomp_identity.py` | `StompConnection` (`__slots__`: websocket, client_id, user_info, auth_failed — it *cannot* hold a name); bearer read from the WS upgrade `Authorization`, then `Sec-WebSocket-Protocol: bearer.<token>` / `access_token.<token>` (the browser convention — the JS WebSocket API cannot set headers), then the CONNECT frame's `Authorization` or STOMP's own `passcode`. `login` is never read. Validated by `JwtValidator.get()` — the middleware's own singleton, never a second implementation. `scrub_principal()` keeps `sub` + roles + the `groups` claim and drops username/email on the floor (D18-1). |
| the verdict | `accessControl/stomp_gate.py` | `subscribe_verdict()` = `permission_verdict(manager, user_info, class_name, 'read')` — the SAME function, the same admin bypass, the same profile resolution. `events` is stamped on the returned dict as `derivedFrom: read`, never granted separately. No `AppPermissionProfile` table → `None`, reported as `no-profile-table`, allow (today's behavior, stated) exactly as the CRUDE gate does. |
| the mode | same file, `gate_subscribe()` | `gate_mode()` from `app_permissions_gate` — one knob, `POLARI_APP_PERMISSIONS=off\|advisory\|enforce`. |
| the seam | `polariApiServer/stompWebSocketServer.py` `handle_subscribe()` (:143), called from `_handler`'s `SUBSCRIBE` branch (:205) | the sync half is separated on purpose so the whole decision is testable with no socket. |
| the manager | `initLocalhostPolariServer.py:160-164` | `StompWebSocketServer(..., manager=localHostedManagerServer)`; `set_manager()` for a lazy boot. Reference only — the sidecar is still not on the tree. |
| the edge | `stomp_gate.record_subscribe()` | dev posture only; mints its OWN root cause (`api`, `SUBSCRIBE /topic/<Class>`) because contextvars do not cross the STOMP thread (design §4 — the site was already listed in `KNOWN_THREAD_SITES` as "ct-6"); `touch(manager, Class, 'read')` then `record_edge('endpoint:SUBSCRIBE /topic/<Class>', 'object:<Class>:read', 'ws-subscribe', detail='<groups, comma-joined>')`. The counterpart to ct-2's `ws-publish`, which deliberately left "who subscribes" here. |
| the observation | same function | `security_observe.observe_permission(manager, user_info, Class, 'events', verdict=<the read verdict>)` — the existing public function, called by lazy import with the vocabulary verb, so derived profiles include what a role *subscribed* to and not only what it read over HTTP. No security file was edited. |

**The notice mechanism (the "how does a STOMP server set a header" question), answered with what the server
already had.** A STOMP server can say three things: MESSAGE, ERROR, RECEIPT. All three are used and nothing is
invented.
- **advisory** (the deployed mode — security warns, never blocks, §17): the subscription *is* registered, and the
  client gets a `MESSAGE` frame on the destination it just subscribed to, carrying
  `X-Polari-Permission-Advisory: would-deny <Class>:read` as a frame header and the evidence-bearing verdict as
  its JSON body, marked `"polariNotice": "permission-advisory"` so a client can tell it from a change
  notification. If the SUBSCRIBE asked for a `receipt`, the same header also rides the `RECEIPT` frame — the
  closest thing STOMP has to the HTTP response header the CRUDE gate sets.
- **enforce**: an `ERROR` frame with the same header, `message: permission refused` (or `unauthenticated`), the
  verdict as the body, `receipt-id` when asked for — and the socket is NOT added to the topic.
- **off**: nothing computed, nothing sent, byte-identical to before.
- §51 holds on the socket too: an EXPIRED bearer answers `unauthenticated <Class>:read (token invalid or
  expired)` + `X-Polari-Auth: invalid-or-expired`, never `would-deny`.

**Selftests.** `PYTHONPATH=.:modules python3 polariApiServer/selftest_stomp_gate.py` → **41/41** (no network:
the sync `handle_subscribe` is driven with a fake connection and a fake profile table). Regression set, all green:
`accessControl/selftest_cause_context.py` **41/41** (the thread table needed no change — the STOMP site was
already listed "ct-6"); `python3 -m testing.stomp_selftest` **6/6** (the wire, unchanged — default knob is `off`);
`modules/grpcbridge/contracts_selftest.py` **31/31**; `modules/grpcbridge/serving_selftest.py` **23/23**;
`PYTHONPATH=.:modules python3 -c "import polariApiServer.polariServer"` clean.

**Gotchas.** (1) `modules/testing/transports_selftest.py` reads 8/10 — the two reds are PRE-EXISTING and nothing
to do with ct-6: it shells `python3 -m testing.selftest_stomp` / `testing.selftest_formats`, and the files are
named `stomp_selftest.py` / `formats_selftest.py`. Worth a one-line fix in that runner. (2) `polariServer.py`
imports clean only with `PYTHONPATH=.:modules`. (3) A gate error can never close a socket: every failure path in
`gate_subscribe` degrades to allow with the reason on the advisory.

**OWED.**
- **Live proof with a real websocket client:** on the home staging stack (dev posture, `POLARI_APP_PERMISSIONS=advisory`),
  connect with a real Keycloak bearer as a demo-viewer, subscribe to an out-of-profile class, and see the MESSAGE
  advisory arrive; flip to `enforce` and see the ERROR frame and an empty subscriber list in `/wsStatus`. Then arm
  a `TraceTarget` on that class and check one `ws-subscribe` edge appears in `/api/security/trace/edges` with the
  subscriber's groups in `detail` — pairing with ct-2's `ws-publish` edge to close the loop.
- **Frontend half, not built:** the Angular STOMP client sends no bearer today (neither on the upgrade nor on
  CONNECT), so on a live stack every socket is still anonymous; and nothing yet reads `polariNotice` /
  `X-Polari-Permission-Advisory` or handles an ERROR frame on SUBSCRIBE. Until that lands, `enforce` would
  silently stop live updates for real users — which is exactly why advisory is the deployed mode.
- **Browser pass:** that an advisory notice does not make a page refetch in a loop, and that a refused subscribe
  degrades to polling rather than a dead panel.

## §63–§64 addendum — live proof on `polari-lean` (2026-09-19, framework `f1fd6cc`, posture dev, gate advisory)

Second `pol prod apply`; backend 200 after ~70 s. Over the API with `demo-admin` / `demo-journalist`:

| step | result |
|---|---|
| `GET /api/security/observe/closure` (armed class, no parameter) | five start nodes for `AppPermissionProfile` with `seen` true only for `read` (the one edge recorded) — "no edges yet" is an answer, not silence |
| `?profile=journalist` | `explicit` = the profile's 4 class × read grants, `implicit []`, counts all zero except objects 4 — nothing beyond the explicit list has been traced, and it says so |
| `review?role=journalist` / `verify` | `closure` block present (10 keys); `transitive {covered 0, total 0, definer_only 0, not_traced [], reading …}` |
| `GET /api/apps/security/coverage?app=app-policy` | version `set-862f3c1e`, **436 subjects**: profile-verb 310 (62 classes × 5 verbs), owner-policy 62, role-binding, trace-coverage; 434 `open` + 2 `suggested`; coverage `none`; instance counts per class |
| confirm one `owner-policy` subject | anonymous 401, journalist 403, admin `ok` → row `confirmed`; coverage → `partial` (433 open / 2 suggested / 1 confirmed); totals across apps agree |
| `Access-Control-Expose-Headers` | now lists `X-Polari-Owner-Advisory` |

**Found:** `GET /api/apps/security/coverage` with no `app` answers only apps already converged (one after this proof) — converge runs per app on read; a "converge every app" sweep is owed (ct-8 OWED). `review?role=journalist` answers "nothing recorded for this role yet" on this instance — the role-play observations of §51 are not on the live tree after the redeploys; not this arc's regression, but worth a look before the browser pass.

## §66 — ct-9: traffic policies — outbound + inbound, closed by default, suggested from dev traffic (2026-09-19, built, selftested)

His rulings (2026-09-18): *"Outbound guard should be tracked in dev as well, and it should be closed by default;
we should suggest outbound and inbounds based on our monitoring of traffic in and out of polari … we just know we
cannot track objects outside of polari."* Design `CAUSAL_TRACE_OBJECT_FLOW_DESIGN.md` §5a (with §6 and §7 as the
consumers). Security row classes 34 → **36**.

| built | where |
|---|---|
| `OutboundPolicy` — `kind\|system\|means`, `payload_classes_json`, `state`, `derived_from`, `confirmed_by` (a `sub`), `count`, first/last seen | `modules/security/objects/security/OutboundPolicy.py` |
| `InboundPolicy` — `source_kind\|source` (peer name / `scheme://host` / `anonymous` / `ip-literal`), `paths_json` (TEMPLATES, capped 50) | `modules/security/objects/security/InboundPolicy.py` |
| the model: `outbound_verdict`, `inbound_verdict`, `note_inbound_path`, `confirm_outbound/inbound`, `policies`, `suggestions`, `declared_flows`, `summary` | `modules/security/custom/security_traffic.py` (new, 468 lines) |
| the inbound gate + the advisory sink + the classifier (`classify`, `normalise_origin`) | `accessControl/traffic_middleware.py` (new, 279 lines), registered right after `CauseContextMiddleware` (`polariServer.py:493`) |
| the outbound wrapper consults the policy BEFORE `fn()`; `OutboundRefused` | `polariApiServer/outbound.py:54` (the exception), `:149` `_policy_check` / `:169` `_refuse_if_enforced`, `send()` and `wrap.__enter__()` |
| `X-Polari-Traffic-Advisory` drained onto the response | `accessControl/cause_middleware.py:97` (+ the CORS expose list, `polariServer.py:420`) |
| four doors | `modules/security/security_api.py:120-123` routes, `:825-863` responders |
| three page rows on `security-events` (suggestions panel, the two tables, declared flows) — seed_upsert convergence, no raw JSON, no new component | `modules/security/security_page.py:145-158` |
| five registration sites + manifest (`37 classes`) | `objects/security/__init__.py`, `security_basis.py`, `security_seed.py` (seeded EMPTY on purpose), `feature_imports.py:1253`, `polariServer.py:1257` |

**The ladder — posture × mode.** One knob, `POLARI_APP_PERMISSIONS`, the same one every other gate reads.

| | `off` | `advisory` | `enforce` |
|---|---|---|---|
| **dev** (rows written) | verdict computed, a `suggested` row created/bumped, nothing acted on | row written; send/request proceeds; `would-deny …` on the header; one counted `SecurityEvent` | row written; send raises `OutboundRefused`, request is 403 from `process_request` |
| **production** (NO rows written) | verdict computed, nothing written, nothing acted on | proceeds + header + `SecurityEvent` | **closed by default**: anything without a `confirmed` row is refused, `SecurityEvent` outcome `denied` |

`confirmed` allows · `denied` refuses · `suggested` is a PROPOSAL and refuses · no row at all refuses ·
no security rows on the instance → `no-security`, allowed and stated. The ONE write production permits is a
person's `confirm_*` — a decision, not an observation. The home stack runs `advisory`, so there it warns and
never blocks (§17).

**Where inbound is classified.** `TrafficPolicyMiddleware.process_request` → `classify(manager, req)`: a
registered `PeerNode.base_url` matching the Origin or Host gives the peer's NAME; an `X-Polari-Trace` with no
registered sender is `peer|unregistered`; an Origin becomes `origin|<scheme>://<host>` with port, path and query
stripped, and an IP-LITERAL Origin collapses to the class `origin|ip-literal` (a raw address never lands in a
row); everything else is `anonymous|anonymous`. The endpoint TEMPLATE is added in `process_resource`, where
falcon has routed — `path_template()` deliberately does NOT fall back to `req.path` (ct-0 may, a policy row may
not: `/api/MealEntry/m-1` carries an instance id). `/api/health` and `/api/security/traffic*` are never refused,
stated: gating the confirmation door behind the confirmations would lock an admin out on the first `enforce`.

**Doors.** `GET /api/security/traffic` (signed in: policies + suggestions + declared + mode + posture) ·
`GET /api/security/traffic/declared` (the confirmed rows as §7 declared edges: `direction`, `system`/`source`,
`means`, `classes`, `node`) · `POST /api/security/traffic/outbound/{name}` and `/inbound/{name}`
`{"decision": "confirmed"|"denied"}` — 401 without a `sub`, 403 without an admin role, 400 on any other decision,
404 on a row nothing proposed.

**Selftests.** `PYTHONPATH=.:modules python3 modules/security/security_selftest.py` → **219/222** (+19 ct-9
checks; the same 3 known environment failures as before — the two live-MAC-profile reads and the expired-cert
probe). `polariApiServer/selftest_outbound.py` → **61/61** (+10: enforce refuses and `fn` never runs, `wrap`
refuses on the way in and records once, advisory/off proceed, a confirmed row goes through, a BLOWN-UP or ABSENT
policy never blocks a send). Regression set all green: `accessControl/selftest_cause_context.py` **41/41**,
`modules/polariapps/apps_selftest.py` **125/125**, `polariRefs/selftest_refs.py` **51/51**,
`python3 -m moduleService.manifests conform --all` **61/61**, `import polariApiServer.polariServer` clean.

**Gotchas.** (1) The advisory cannot ride the cause dict alone — production posture mints NO cause (ct-0), so the
sink is a contextvar in `traffic_middleware` and the cause dict is a mirror; `process_request` drains first so a
line can never leak into the next response. (2) `_peer_names` reads the manager's OWN `PeerNode` table: the
security module's `_FALLBACK` test rows are invisible to a core-resident gate (cost one red in the selftest).
(3) Seeding an allow-list would be a grant nobody made — both tables seed EMPTY and the selftest asserts 36 pairs.

**OWED.**
- **Live proof** on the home staging stack (dev, advisory): watch `GET /api/security/traffic` fill with suggestions
  from real frontend and Keycloak traffic, confirm one of each direction as `demo-admin`, check the row carries the
  `sub` and that `X-Polari-Traffic-Advisory` stops appearing for it; then one `enforce` window to see a refusal.
  Expect noise first: every unconfirmed source adds a header line to every response in dev.
- **The `objects` topology view (ct-5)** is what `declared_flows` was shaped for — `compare(declared, observed)`
  against the causal map's `external:`/`peer:` edges is the drift report, and nothing draws it yet.
- **Browser pass** on the three new `security-events` rows (suggestions panel, the two tables, declared flows):
  that `paths_json` / `payload_classes_json` render as lists and not as raw JSON strings.
- **The straggler table** still lists `modules/security/custom/kc_admin.py`: an unwrapped send is a send this
  policy cannot see, so it is also a hole in the outbound allow-list, not only in the map.

## §65–§66 addendum — live proof on `polari-lean` (2026-09-19, framework `4a2b75b`, posture dev, gate advisory)

Third `pol prod apply`. Over the API:

| step | result |
|---|---|
| request with `Origin: https://prf.<D>` | 200 + `X-Polari-Traffic-Advisory: would-deny inbound origin:https://prf.<D>`; the header is in `Access-Control-Expose-Headers` |
| anonymous request | 200 + `would-deny inbound anonymous:anonymous` |
| `GET /api/security/traffic` (admin) | mode `advisory`, posture `dev`; inbound rows `anonymous|anonymous` (count 7) and `origin|https://prf.<D>` (count 1), both `suggested` — the monitoring IS the suggestion list |
| any inbound row with a bare IP | none |
| confirm `anonymous|anonymous` (admin) | 200 |
| confirm `origin|https://prf.<D>` (admin) | **404 — DEFECT:** the name rides the URL path and contains `://`; URL-encoding does not help (Falcon decodes before routing). Fix handed back to the ct-9 builder: a body-addressed `POST /api/security/traffic/{outbound,inbound}` |
| `GET /api/security/traffic/declared` | 0 flows (nothing confirmed yet), the `how` text explains the shape |
| outbound rows | **0** although Keycloak/JWKS sends happen — likely boot-time sends find no process manager and write nothing; being checked by the builder, else OWED |

ct-6 (STOMP) is deployed but NOT proven live: it needs a websocket client sending a bearer, and the Angular client sends none yet (advisory keeps live updates working).

### §66 addendum — two defects the live proof on `polari-lean` found (2026-09-19, fixed, selftested)

The ct-9 live proof on the home stack (dev posture, gate advisory) proved the whole slice — origin/anonymous
classification, `suggested` rows counting up, `X-Polari-Traffic-Advisory` present and on the expose list, no raw
IPs anywhere — and found two things.

1. **A policy name a URL path cannot carry.** An inbound row is named `origin|https://<host>`; falcon
   percent-DECODES before routing, so `%2F%2F` is `//` by the time the router sees it and
   `POST /api/security/traffic/inbound/origin|https://…` is a 404 no encoding can fix. (`anonymous|anonymous`
   confirmed fine at 200 — the path form works for every simple name.) **Fix:** two more doors,
   `POST /api/security/traffic/outbound` and `/inbound`, taking `{"name": …, "decision": …}` in the BODY
   (`security_api.py:122-123` routes, `:879-895` responders). The `{name}` form stays. Same function, same
   refusals, one extra 400 when no name is given. Proven against falcon's own `CompiledRouter`: the `{name}`
   route does not match a name holding `://`, the body route does.
2. **Outbound rows were 0 although Keycloak/JWKS sends demonstrably happen.** `outbound.process_manager()`
   answers None until `polariServer` injects the manager (`polariServer.py:780`), and the EARLIEST sends run
   before that — so exactly the sends a person most wants to rule on were the ones never written. **Fix:** a
   bounded in-process buffer (`security_traffic._PENDING`, 200 subjects, counted, classes merged) parks a send
   with no tree and `flush_pending()` turns it into rows at the first verdict or door read with a real manager;
   in production the buffer is cleared and nothing is written, so production still derives nothing. The send is
   allowed meanwhile — a guard with nowhere to write must not block a boot.

**Selftests.** `modules/security/security_selftest.py` **222/225** (+3: the body door with a `://` name — admin
ok, journalist 403, anonymous 401, no-name 400 — plus the park-and-flush and its production drop; the same 3
known environment failures). `polariApiServer/selftest_outbound.py` **61/61**,
`accessControl/selftest_cause_context.py` **41/41**, `modules/polariapps/apps_selftest.py` **125/125**,
`manifests conform --all` **61/61**, `import polariApiServer.polariServer` clean.

**Still owed** (unchanged from §66): the `objects` topology view (ct-5), the browser pass on the three new page
rows, and `kc_admin.py` — still an unwrapped straggler, so still a hole in the outbound allow-list. New: re-run
the live proof to confirm boot-time Keycloak/JWKS sends now appear as `keycloak|…` suggestions after the first
request.

## §66 addendum — live re-proof after the fourth deploy (2026-09-19, framework `6c15288`, posture dev, gate advisory)

| step | result |
|---|---|
| body door `POST /api/security/traffic/inbound {name: "origin\|https://prf.<D>", decision: confirmed}` | journalist 403, anonymous 401, admin `ok` → `state confirmed`, `confirmed_by` a 36-char sub |
| `GET /api/security/traffic/declared` | 1 flow: the confirmed origin |
| a request from that origin | no `X-Polari-Traffic-Advisory` any more (the exposed header list still carries it) |
| `SecurityDecision` confirmed row (app-policy) and `TraceTarget` coverage row | **survived two redeploys** |
| `InboundPolicy` `anonymous\|anonymous`, confirmed before deploy 4 (count 50) | **DEFECT: back to `suggested` (count 9)** — the traffic rows do not persist the way the other new rows do |
| outbound rows after boot + authenticated requests | **DEFECT: still 0** — the pending-buffer flush does not surface the Keycloak/JWKS sends |

Both handed back to the ct-9 builder with live access; see "§66 addendum 2" for the root causes.

### §66 addendum 2 — the restore race and the empty outbound table (2026-09-19, root-caused live, fixed, selftested)

Both defects were investigated on the LIVE `polari-lean` stack (dev posture, gate advisory), not guessed.

**1. A confirmed `InboundPolicy` did not survive a redeploy — the RESTORE RACE (§66b).** The backend log gave
it away: `[DefRestore] InboundPolicy: 1 instances already in objectTables, skipping`. Lazy boot serves requests
while the definition tables are still being restored, and `_restoreDefinitionInstances`
(`polariServer.py:1820`) deliberately skips a class that already holds instances. The ct-9 inbound middleware
runs on EVERY request, so the first request of a boot created `anonymous|anonymous` row 1 — and restore then
discarded everything `InboundPolicy` had persisted, a person's `confirmed` ruling included, which is why it
came back `suggested` (count 9, then 27). `SecurityDecision` and `TraceTarget` survived the same redeploy
because nothing writes them during boot. **This was a hazard for every ledger the middleware touches, including
`SecurityEvent`.** Fix: `polariServer` sets `manager.definitionsRestored = False` in its constructor and `True`
after restore (`polariServer.py:532`, `:1753`); `security_traffic.tree_ready()` reads it, and a manager that
never carries the attribute (a test double, a module's own) is ready by definition. When the tree is not ready
the observation is PARKED in the §66a buffer, the traffic is allowed, and the parked counts land ON the
restored rows at the first request afterwards — so a boot adds to a ruling instead of replacing it.

**2. Outbound rows were still 0 — and ct-9 was not the bug (§66c).** Proven live: `GET /auth/jwks-health`
(the one diagnostic that does go through the wrapper) produced `keycloak|Polari|rest suggested count 1`
immediately. The wrapper, the flush and the door all work. The rows were empty because **no wrapped send
happens on a running instance**: token validation uses PyJWT's `PyJWKClient` (an internal urllib call neither
the wrapper nor the straggler regex can see), and `/api/security/people` and the role claims go through
`modules/security/custom/kc_admin.py` — the last LISTED straggler of design §5. Fix: `kc_admin._http` now
sends through `outbound.urlopen('keycloak', <realm>, req, …)` — one line at its single choke point, the same
open response returned, and its catch-all turns an `enforce` refusal into the `(0, 'OutboundRefused: …')` it
already returns for every other failure. Removed from `KNOWN_STRAGGLERS`, added to `MIGRATED`.

**Selftests.** `modules/security/security_selftest.py` **225/228** (+3: the boot-time write being parked and
landing on the restored confirmed row, `tree_ready`'s three answers, and `kc_admin` through the seam; the same
3 known environment failures). `polariApiServer/selftest_outbound.py` **61/61** (the import test now purges the
stub `security` package the fakes install, or it would shadow the real tree),
`accessControl/selftest_cause_context.py` **41/41**, `modules/polariapps/apps_selftest.py` **125/125**,
`polariRefs/selftest_refs.py` **51/51**, `manifests conform --all` **61/61**, `polariServer` imports clean.

**Still owed.** `PyJWKClient`'s JWKS fetch cannot be wrapped without replacing the library's own HTTP — it is a
real, named gap in the outbound picture, not an oversight. The `objects` topology view (ct-5) and the browser
pass on the three page rows remain. Next live proof: redeploy, confirm a row, redeploy AGAIN and check it is
still `confirmed`; and check `keycloak|<realm>|rest` now appears from ordinary `/api/security/people` traffic.

## §66 addendum 2 — live re-proof after the fifth deploy (2026-09-19, framework `5303398`, posture dev, gate advisory)

| step | result |
|---|---|
| outbound rows after boot | `keycloak\|Polari\|rest` `suggested` — the empty outbound list is gone (§66c: `kc_admin.py` onto the wrapper; `PyJWKClient`'s own urllib stays a named gap) |
| confirm `anonymous\|anonymous`, wait 90 s, `docker service update --force prf-backend` | the confirmed row **survived** (`confirmed`, count 14) — the restore race (§66b) no longer discards it |
| the same listing after the restart | **DEFECT: a second `anonymous\|anonymous` row** (`suggested`, count 7) beside the confirmed one — boot-time observations still create a duplicate instead of landing on the restored row; handed back (see "§66 addendum 3") |
| the origin row confirmed under the deploy-4 image | gone — lost by the pre-fix image's restore race, as expected |

### §66 addendum 3 — one row per name (2026-09-19, fixed, selftested)

The §66b fix held on `polari-lean` — a `confirmed anonymous|anonymous` (count 14) SURVIVED a
`docker service update --force` — but the read then showed that name TWICE: ('confirmed', 14) beside
('suggested', 7). So the parked counts landed BESIDE the restored row instead of on it.

**Root cause.** `definitionsRestored` is one flag for the whole restore pass, and that pass is not one pass:
`ensureDefinitionTables` runs several times over a lazy boot (six times in the live log). So the flag can read
True while the restore of *this* class is still to come; the flush's `_find` legitimately finds nothing, writes
its own row, and the class's restore then adds the persisted one beside it. Chasing per-class boot ordering is
the wrong fix — a name is either the key or it is not.

**Fix (§66d).** The name is now enforced as the key at every lookup and every read.
`security_traffic._find()` collapses duplicates before answering; `heal_duplicates(manager, direction)` does the
same for a whole table and is called from `_rows()` (so `policies`, `suggestions`, `declared_flows` and the
doors all heal) and from `flush_pending()` (so a parked count lands on the restored row). `_collapse()` keeps
the row a PERSON ruled on — `confirmed`/`denied` outrank `suggested`, ties go to the oldest `first_seen` — SUMS
the counts, unions the payload classes and the paths, keeps `confirmed_by`/`confirmed_at` untouched, and
deletes the losers from the tree with `noteTreeDeletion` so a persist in flight cannot write them back. An
instance that already has duplicates (the live tree does) heals on the next door read; no migration.

**Selftests.** `modules/security/security_selftest.py` **227/230** (+2: a restore landing AFTER the flush ends
as ONE row, `confirmed`, count 14 + 7 = 21 with the confirmer intact; and three pre-existing duplicates
collapsing on a door read — counts summed, paths unioned, oldest `first_seen` kept, rows removed, and a second
heal removing nothing. Same 3 known environment failures.) `selftest_outbound` **61/61**, `cause_context`
**41/41**, `apps_selftest` **125/125**, `selftest_refs` **51/51**, `conform --all` **61/61**, `polariServer`
imports clean.

**Owed.** Next live proof: restart and confirm ONE `anonymous|anonymous` at count 21-ish; re-confirm
`origin|https://prf.<D>` (lost under the pre-fix image, expected) and restart again to prove it holds. The
`PyJWKClient` JWKS gap, the ct-5 `objects` view and the browser pass are unchanged.

## §66 addendum 3 — live re-proof after the sixth deploy, and the CORE root cause (2026-09-19, framework `a34da5e`)

| step | result |
|---|---|
| listing after boot | ONE `anonymous\|anonymous` row (`confirmed`, 47) — the duplicates healed on the read (§66d) |
| confirm the origin row, wait 90 s | both rows `confirmed` |
| `docker service update --force prf-backend` | **both confirmed rows GONE**; a fresh `suggested` anonymous row (8) |

**Evidence (container logs + the sqlite file):** the old container's SIGTERM flush ran and persisted 93 classes — the
traffic, trace and decision classes all have tables. The new container's boot then printed
`[DefRestore] InboundPolicy: 1 instances already in objectTables, skipping` — and the same for `OutboundPolicy`,
`TraceTarget` and `SecurityDecision` (438). `_restoreDefinitionInstances` (`polariServer.py:~1820`) DISCARDS every
persisted row of any class that already holds one instance when its restore comes round, and lazy boot serves requests
(and converge-on-read, and the boot/tick roots) before every class is restored. The new process's first persist then
overwrote the tables with the boot-time rows — the sqlite file now holds `anonymous\|anonymous suggested 14` and no
confirmed row. §66b's `definitionsRestored` flag narrowed the window but did not close it: the restore is several
passes, not one. **This is a CORE hazard for every class written during boot, not a ct-9 one**; the fix handed back is
a MERGE in the restore (persisted row = truth, count-like fields summed, the boot-time duplicate removed) with a core
selftest — see "§66 addendum 4". Until it lands, a ruling confirmed shortly before a restart can be lost on any
class that is touched during boot.

### §66 addendum 4 — the restore merge (core) (2026-09-19, fixed, selftested)

After a confirm + 90 s + `docker service update --force`, BOTH confirmed traffic rows were gone again although
the old container's SIGTERM flush had persisted 93 classes and the tables were all present. The new
container's boot said why:

    [DefRestore] SecurityDecision: 438 instances already in objectTables, skipping
    [DefRestore] TraceTarget/OutboundPolicy/InboundPolicy: 1 instances already in objectTables, skipping

**What wrote the boot-time rows.** Requests served during lazy boot. The swarm's own health probe hits
`/api/health` every few seconds and it is anonymous, so the ct-9 traffic middleware counts it — which is
exactly the `anonymous|anonymous` row — and ct-8's converge-on-read accounts for `SecurityDecision`'s 438. The
log shows them accumulating across the boot (`InboundPolicy: 1 instances` → `2 instances` → `3 instances` on
successive passes), so the §66b `definitionsRestored` guard narrowed the window but never closed it: the flag
is one boolean for a restore that runs many times, and a writer that beats `polariServer.__init__` sees no
flag at all.

**The core defect, which is not ct-9's.** `_restoreDefinitionInstances` SKIPPED any class that already had one
instance. One boot-time write therefore made every persisted row of that class unreachable — not corrupted,
never loaded — and the next persist wrote the half-booted tree over them. Any class an observer can touch
during boot was exposed.

**The fix (§66e, `polariServer.py:1826-1930`).** Restore MERGES. Every persisted row is inserted. A row already
in memory with the SAME `id` IS that persisted row (an earlier pass put it there) and is left alone — that is
what keeps the repeated passes idempotent instead of doubling every counter. A row with the same `name` and a
different id is a BOOT-TIME row: the persisted row wins every field, absorbs its count-like fields
(`count`, `traces_opened`, `edges_written`, `journal_written`, `dropped` — `RESTORE_COUNT_FIELDS`), and the
boot-time row is deleted through `noteTreeDeletion` so a persist in flight cannot write it back. A boot-time
row whose name matches nothing in the DB survives — it is a real observation nobody had persisted yet. Rows
with no id fall back to "leave what is there" rather than guess. The log line now reads
`merged N persisted rows, M boot-time rows folded[, K already restored]`.

**Selftests.** NEW `polariApiServer/selftest_restore_merge.py` **17/17** (the live case folded, a new boot-time
name surviving, a plain restore unchanged, three repeat passes idempotent, empty/missing tables, two racing
boot rows folding together, and a nonsense counter not taking a boot down — no server, no DB: the real methods
are bound to a double). Regression: security **227/230** (same 3 env failures), outbound **61/61**,
cause_context **41/41**, apps **125/125**, refs **51/51**, persist_debounce **13/13**, persist_tombstones
**43/43**, crude_delete_blast **21/21**, quiesce **27/27**, conform **61/61**, import clean.

**Owed.** The main restore path (`objectTreeManagerDecorators.restoreFromDatabase`) has its own present-rows
logic and was NOT touched — it skips by matching ids, so it looks sound, but it deserves the same read before
the next arc trusts it. And the deeper question stands: an instance that answers requests before its tree is
loaded will keep producing races like this one; the merge makes them harmless rather than making them stop.

## §66 addendum 4 — live proof of the restore merge after the seventh deploy (2026-09-19, framework `f9a893a`)

| step | result |
|---|---|
| after boot | one `anonymous\|anonymous` row (`suggested`, 11 — the pre-fix image had already overwritten the table), outbound `keycloak\|Polari\|rest` |
| confirm anonymous + origin (body door), wait 90 s | both `confirmed` (17 and 1) |
| `docker service update --force prf-backend` | **both still `confirmed`, one row per name**; anonymous count 27 = 17 persisted + 10 boot-time probes folded in; the origin row intact; outbound row intact |
| the new container's restore log | `[DefRestore] InboundPolicy: merged 0 persisted rows, 0 boot-time rows folded, 1 already restored` — the repeat passes are idempotent |

The core hazard of addendum 3 is closed on this instance. OWED from it: the same read of
`objectTreeManagerDecorators.restoreFromDatabase` (its own present-rows logic, unreviewed); a re-check that
`SecurityDecision` confirmations survive a restart now that converge-on-read runs during boot (expected yes — same
merge); `PyJWKClient`'s own JWKS fetch stays a named gap in the outbound map.

## §67 — ct-5 + ct-7: the `objects` topology view, and tasks + needs (2026-09-19, built, selftested)

Design `AI-Notes/designs/CAUSAL_TRACE_OBJECT_FLOW_DESIGN.md` §7 (the object topology), §8 (what particular
individuals need), §9 (the `app.flows` manifest stanza), §11 rows ct-5 / ct-7. On top of §61 (ct-1 the map),
§63 (ct-2/ct-4 the closure), §64 (ct-8 decisions) and §66 (ct-9 the traffic policies — whose
`declared_flows()` had been written and left unused, *waiting for this view*).

His asks these two slices answer: *"we are going to want to make topologies of objects that track how object
instances may propagate between systems"* (ct-5), and *"what sort of things are needed for particular
individuals"* (ct-7). **NO new row classes** — the security class count stays **36**.

### ct-5 — the `objects` view

| built | where |
|---|---|
| the view itself: `build` / `observed` / `declared` / `policy_flows` / `manifest_flows` / `drift` / `simulate` / `compare` | `modules/security/custom/security_objects_view.py` (new, 684 lines, in the manifest) |
| the dispatch: `OBJECT_VIEW`, `ALL_VIEWS = VIEWS + ('objects',)`, `build/simulate/compare` gain `manager=` and delegate | `modules/security/custom/security_topology.py:29-36, 305-320, 327-333, 350-360` |
| the ONE schema change design §7 allows: `SecurityTopologyEdge.payload` — *what* crosses (`MealEntry×12`) | `modules/security/objects/security/SecurityTopologyEdge.py` |
| the fourth `SecurityDomain` row + two `SecurityArea` rows (`object-flow`, `trace-coverage`) | `modules/security/security_seed.py:26-34, 47-51` |
| doors: `?view=objects` on `/topology`, `/simulate`, `/compare` (the manager is handed through), plus `GET /api/security/objects/drift` and `/objects/flows` (401 anonymous) | `modules/security/security_api.py:105-107, 175-190, 955-985` |
| the page `security-objects`: 8 rows of configured structured panels + 2 configured class tables (`CausalEdge`, `TraceTarget`); no new component, nothing raw | `modules/security/security_page.py:159-224` |

**The two provenances, one vocabulary.** *declared* = the modules' manifest `app.flows` stanzas (the app
author's statement, at the level an author can honestly make one — a system KIND, never a host) **plus** the
`OutboundPolicy`/`InboundPolicy` rows a PERSON confirmed (`security_traffic.declared_flows`, the deployment's
statement). *observed* = the causal map's `external:` / `peer:` effects and the two `ws-*` means, with the
payload classes the wrapper recorded in `detail`. A `crude` or `trigger-fire` edge is deliberately NOT a flow:
causation inside the instance is ct-4's answer and this view does not repeat it.

**The modes, for this view** (they mean the traffic policy's ladder, not the machine's rings): `stock` = an
instance with no policy at all, every flow leaves · `today` = `POLARI_APP_PERMISSIONS` × the rows' states ·
`complain` = dev, confirmed allowed and everything else LOGGED and proceeding (warn, never block) · `enforce` =
production, closed by default. The chain named per edge is `app-flows → traffic-policy → outbound-wrapper →
causal-map` (and `app-permissions → …` for a broadcast, which ct-6 decides per subscriber, so the view says
LOGGED and names the gate rather than inventing one verdict for everybody).

**The drift report** (`/api/security/objects/drift`): `observed_not_declared` (the finding — dev warns, never
blocks), `declared_not_observed` (noise to prune, *unless* its classes were never traced), `by_app` with a
`coverage` of none/partial/full, and `not_traced` / `not_traced_detail`. Matching is at two levels on purpose:
a manifest declaration covers a system KIND, a confirmed policy row covers the configured system AND the wire.

### ct-7 — tasks + needs

| built | where |
|---|---|
| the task model: `clean_task`, `tasks_of` / `bump_task` (the `{task: count}` map), `session_tasks` / `state_task`, `current_task`, `group_by_task`, `verify_tasks` | `modules/security/custom/security_tasks.py` (new, 287 lines, in the manifest) |
| `ObservationSession.task` + `tasks_json` (the stated-task history) | `modules/security/objects/security/ObservationSession.py` |
| `PermissionObservation.tasks_json`, `UsageObservation.tasks_json` — `{task: count}` on the SAME counted row | the two class files |
| `start_session(..., task=)`: posting the same door again CHANGES the task mid-session and keeps the history | `security_observe.py:412-440` |
| the recorders attribute every act and every door to the open session's task | `security_observe.py` (`observe_permission`, `observe_usage`) |
| `review(role)` gains `tasks` — tasks → doors → objects × verbs → closure per task (reusing `security_closure`) | `security_observe.py:review` + `security_tasks.group_by_task` |
| `verify(role, group)` gains `tasks`, `tasks_broken`, `tasks_verdict` — which TASKS enforcement would break | `security_observe.py:verify` + `security_tasks.verify_tasks` |
| `app.flows` (design §9): `FLOW_TARGETS` / `FLOW_DIRECTIONS` / `FLOW_CLASSES_MAX` / `flow_findings`, wired into `validate()`, and `flows` joins the HAND-SET keys `generate` preserves | `moduleService/manifests.py:56-127, 421-425, 458` |
| the first two real declarations: `security` → keycloak carrying NO rows, `odooconnect` → odoo | `modules/{security,odooconnect}/polari-app.json` |
| `task` on the sessions table of `security-events` | `security_page.py:124` |

### Selftests — exact numbers (all run; nothing regressed)

| suite | before | after |
|---|---|---|
| `modules/security/security_selftest.py` | 227/230 | **250/253** (+23 checks; the same 3 known environment failures) |
| `accessControl/selftest_cause_context.py` | 41/41 | 41/41 |
| `polariApiServer/selftest_outbound.py` | 61/61 | 61/61 |
| `polariApiServer/selftest_restore_merge.py` | 17/17 | 17/17 |
| `modules/polariapps/apps_selftest.py` | 125/125 | 125/125 |
| `python3 -m moduleService.selftest_manifests` | 8/8 | 8/8 |
| `polariApiServer/selftest_stomp_gate.py` | 41/41 | 41/41 |
| `python3 -m moduleService.manifests conform --all` | 61/61 | 61/61 |
| `import polariApiServer.polariServer` | clean | clean |

The 3 failures are the known environment ones and the ONLY ones: ledger `mac_enforced`, mac profiles, expired
internal certs. (`moduleService.selftest_app_taxonomy` reads 8/9 both with and against a stashed tree — a
pre-existing `iso` category gap, not this slice.)

The +23 checks: ct-5 — the fourth view builds for every mode and is deliberately absent from `VIEWS`; the
manifest declared half; the confirmed-policy declared half (and a `suggested` row is NOT a declaration); the
observed half and what it excludes; the four modes against a confirmed and an unconfirmed flow; the drift both
ways; coverage none/partial/full with `not_traced`; **no instance ids, no addresses, no hostnames anywhere on
the view**; `simulate` for `this instance` / `class:<C>` / `profile:<name>` and its refusals; `compare`'s mode
axis; the five doors incl. the anonymous 401s; the §54 suffix-vs-responder route guard; the page's components.
ct-7 — the `app.flows` vocabulary matching `outbound.SYSTEM_KINDS`, seven refusal shapes, `validate()` carrying
them and `generate` preserving a hand-set stanza; the task stated, changed mid-session and kept in history; one
act under two tasks = ONE row naming both; the review's task grouping incl. the unattributed bucket; the
per-task closure; the per-task break verdict; the door's D18-1 rule (a body-supplied `actor` is still ignored).

### Gotchas found / decisions taken where the design was silent

1. **The task does NOT go in a row's name.** The observation ledgers are counted rows keyed by the act
   (`groups|class|verb`, `role|kind|item`) — that is what keeps them readable. Putting the task in the key would
   multiply every row by the tasks that touch it; a plain `task` column would let the last task silently claim
   acts belonging to the one before. So each row carries `tasks_json`, a `{task: count}` map, capped at
   `MAX_TASKS_PER_ROW` (24) with the overflow COUNTED under a named bucket rather than dropped.
2. **`objects` is in `ALL_VIEWS`, not in `VIEWS`.** `security_seed._view_rows()` walks `VIEWS` and seeds a
   node/edge row per view × scenario. The objects view is derived from the INSTANCE (manifests, confirmed
   policies, causal map) and needs a manager, so seeding it at import time would write four copies of one answer
   taken from an empty tree. The doors accept `ALL_VIEWS`; the seed walks `VIEWS`. **Consequence:** the objects
   view's rows are NOT persisted as `SecurityTopologyNode`/`Edge` — the page reads the door. Writing them from a
   GET would be a side effect on a read, and the rows would go stale the moment a policy is confirmed.
3. **`compare('objects')` puts the MODES on the columns, not the scenarios** (`axis: 'mode'`, and `scenarios`
   carries the mode names so the configured panel lines up unchanged). An object flow belongs to the instance,
   not to the machine layout a scenario describes; four identical scenario columns would read as a finding.
4. **`simulate('objects', actor='profile:<name>')`** is how design §7's *"from a person with a given profile,
   what can leave this instance"* is delivered — the profile is expanded to its explicit classes through ct-4's
   `profile_start`, and the answer is the union of those classes' flows. `this instance` means EVERYTHING that
   leaves, not only the calls carrying no class.
5. **A broadcast is not a send.** `ws-publish`/`ws-subscribe` edges appear on the view (the classes really do
   leave the instance) but are excluded from the drift: nothing in `app.flows` declares a STOMP topic, and ct-6's
   permission gate is what governs them. Saying so beats listing every broadcast as an undeclared flow.
6. **`_classes_of` is a split on `detail`, defended.** `record_outbound` writes the payload classes comma-joined
   into `CausalEdge.detail` and `_detail_accepted(record_outbound)` is False today (§62), so `detail` is the class
   list — but the view still filters to plausible class names so a future `detail='ok'` cannot invent a class.
7. **`manifest_flows()` is cached per process** (~60 JSON reads, and `compare` builds the view four times).
   `refresh=True` re-reads after a `manifests generate` in a long-running dev loop.
8. **Two real `app.flows` declarations, not a demo.** `security` → keycloak with `classes: []` (kc_admin resolves
   a sub to a name and manages group membership; NO Polari row leaves — names live in Keycloak, D18-1) and
   `odooconnect` → odoo with `classes: []` (the classes are a deployment's `OdooModelBinding` rows, not the
   module's, so the confirmed `OutboundPolicy` row is where a deployment names what it really sends). Everything
   else declares nothing, which is the truthful state and is exactly what the drift report is for.
9. `odooconnect/polari-app.json` is indented with 2 spaces while `manifests.write()` writes indent=1 — running
   `manifests generate odooconnect` reindents the whole file. The stanza was added by hand at the file's own
   indent instead, so the diff is 8 lines rather than 256.

### Deviations from the design, and why

- **Design §7's node list** ("each `PeerNode`, each configured external system — `OdooInstanceConfig`, the
  Keycloak realm, each S3 bucket/provider row") is **not** enumerated: nodes come from flows only, so a peer or
  an Odoo config that has never flowed and that nothing declares does not appear. Enumerating configuration rows
  is a third declared source (with §7's knobs: `GrpcExposure`, `apiFormatConfig.*WsEnabled`,
  `OdooModelBinding.direction`, `PeerAgreement.scope`, shared-DB co-residency) and is listed under OWED rather
  than half-built. Today a node with no edge would be noise.
- **Design §7's `chain`** (`[PeerAgreement, MutationLease token, ObjectLockEntry, GrpcExposure, direction knob,
  permission_verdict]`) is the consent chain the group-authority plan describes; only two of those rings exist as
  code that decides an object flow today. The chain built is the honest one — `app-flows`, `traffic-policy`,
  `outbound-wrapper`, `causal-map` (and `app-permissions` for a broadcast) — each naming what it really consults.
- The `objects` view's boundary systems are LOCAL to the view rather than added to `security_facts.SYSTEMS`:
  those are the machine's rings and each one gets a `SecurityControl` row per scenario, which would say the same
  thing five times for a Polari code path.
- ct-7's design line *"a module that declares nothing gets a FINDING the first time something flows"* is
  delivered by the drift report's `observed_not_declared` (and ct-8's `flow:undeclared:<system>` subject, which
  already existed) — **not** by a `conform` finding, because an absent stanza is not wrong until something
  actually flows.

### OWED

- **No live proof.** Nothing here has run on `polari-lean` and no browser has seen `/display/security-objects`.
  A live proof should check, in this order:
  1. `GET /api/security/topology?view=objects` — the two declared manifest flows (keycloak, odoo) appear with
     `provenance: declared` and an empty payload, and `drift.counts.observed` is 0 before anything is armed.
  2. Arm a real class (`POST /api/security/observe/trace {"class_name": "UserAppPreference"}`), drive a real
     chain that leaves the instance (a Keycloak name resolution through `/api/security/people/{sub}` is the
     cheapest), then re-read: an OBSERVED keycloak edge, matched by the `security` manifest declaration, so it
     is in NEITHER side of the drift.
  3. Drive something nothing declares (an S3 artifact fetch, or a peer read) and confirm it lands in
     `observed_not_declared` with its `finding`, and that NOTHING was refused (posture dev, gate advisory).
  4. `?mode=enforce` on the same read: the unconfirmed flow reads `blocked`, the confirmed one `allowed` — and
     the instance is still serving, because the mode is a READING and not an apply.
  5. `/api/security/objects/drift` `by_app` — an app whose classes have never been armed reads coverage `none`
     and names them in `not_traced`, NOT an empty list.
  6. ct-7: `POST /api/security/observe/session {"role":"journalist","task":"publish an article"}`, act, POST the
     same door with `"task":"score a source"`, act again, then `GET /api/security/observe/review?role=journalist`
     — two task buckets with the right counts, one row per act (check `PermissionObservation` row count did NOT
     grow), and each task's own closure.
  7. `GET /api/security/observe/verify?role=journalist&group=journalist` after publishing a narrow profile —
     `tasks_broken` names the task, not just a verb count.
  8. **Restart check** (the §66 addenda's lesson): confirm `tasks_json` on a session and on an observation row
     survives a forced restart, i.e. the new columns are persisted and restored by the merge, and that a session
     open across the restart still attributes acts to its task.
- **The third declared source** (§7's configuration knobs: `PeerNode`, `OdooInstanceConfig`/`OdooModelBinding.direction`,
  `GrpcExposure`, `apiFormatConfig.*WsEnabled`, `PeerAgreement.scope`, shared-DB co-residency from
  `object_ownership._storage_identity`) — not built. Until it is, a knob that declares a flow is invisible here
  and an observed flow it permits still reads as undeclared.
- **`app.flows` on the other 59 modules.** Two are declared. Every module that the ct-3 migration table (§62)
  shows sending — collab/livekit, reticulum, materialsScience, mathshapes, cntfet, appstore, mqttbridge,
  polariPeers, the AI/provider/voice paths — should declare its own, and until they do the drift report will name
  them the first time they flow. That is the design's intent, but the sweep is owed.
- **The objects view's rows are not persisted**, so no configured table shows an objects-view
  `SecurityTopologyEdge` and the `payload` column is exercised only through the API and the class constructor. If
  a durable row is wanted, it needs a converge step with an owner (a POST, or the page-converge thread), not a
  write on a GET.
- **Browser pass (his):** `/display/security-objects` — that the 8 panels read as tables rather than a JSON wall,
  that NOT TRACED is legible as an answer rather than an empty list, and that the mode columns on the compare
  table are understandable without the `axis` key.
- ct-7's review/verify are not on a page (both need a `?role=`); the only ct-7 surface a browser sees today is
  the `task` column on the sessions table.
- `MAX_TASK_CLOSURES` (12) bounds how many tasks get a closure in one review; the rest say why. Unproven at
  scale — nobody has role-played 12 tasks.

## §68 — ct-6 / op-0 frontend: the socket has a name, and the browser reads what security said (2026-09-19, built, unit-tested)

§65 closed the backend half of ct-6 and left three things open, all of them in the browser: the Angular STOMP
client sent **no bearer**, so every live socket on a deployed stack was anonymous and `advisory` was the only
honest mode; nothing read the `polariNotice` / `X-Polari-Permission-Advisory` frame the gate sends; and nothing
read the four HTTP advisory headers the CRUDE, owner and traffic gates have been setting since §51/op-0/ct-9 —
the instance had been talking to a browser that was not listening. All three are built.

| what | where | note |
|---|---|---|
| the bearer, on every (re)connect | `polari-platform-angular/src/app/services/stomp.service.ts` `clientConfig()` / `connectHeaders()` | RxStomp `beforeConnect` re-reads the token from `AuthSessionService` and sets `connectHeaders: {Authorization: 'Bearer <token>'}`, so it rides the **STOMP CONNECT frame** — exactly the third place `accessControl/stomp_identity.py` looks. Verified in `@stomp/stompjs` that `connectHeaders` is read *after* `await this.beforeConnect()` (`client.js:422` then `:450`), so a token set inside the hook is the one sent. `Sec-WebSocket-Protocol` was deliberately NOT used: that route needs the server to echo one of the offered subprotocols in the handshake or the browser closes the socket, and it buys nothing here. Signed out = no header = an anonymous socket, byte-identical to before. NO second refresh mechanism: the token in hand at connect time is used, and the next reconnect picks up a fresher one. |
| telling a notice from a change | `src/app/services/stomp-notices.ts` (new, 95 lines) | `gateNoticeOf(frame, refusedFrame?)` — reads `X-Polari-Permission-Advisory` (case-insensitively) and/or the body's `polariNotice`, and answers `{notice, refused, advisory, className, destination}`; `classOfDestination()` is the TS twin of `stomp_gate.class_of_topic` (`/topic/X` and `/topic/X/flatJson` are both `X`). A transport-free file so it is testable with plain objects. |
| the notice never causes a refetch | `stomp.service.ts` `watchTopic()` → `divertNotice()` | the advisory MESSAGE arrives on the *very destination just subscribed to*, so it is filtered out at the ONE chokepoint every watcher (`watchChanges`, `crude-class-service.subscribeToChanges`, the three direct `watchTopic` callers) passes through, and handed to `SecurityAdvisoryService` instead. A notice can therefore never make a panel refetch, and never loop. |
| a refused subscribe degrades, it does not kill | `stomp.service.ts` `wireGateErrors()` + `refusedFallback$()` | stompjs hands an ERROR frame to `onStompError` and does **not** close the connection (`stomp-handler.js:79`); RxStomp only fails a watch when `correlateErrors` says so, and that is **deliberately left unset** — so one refused destination cannot tear down the other subscriptions. Instead the class is recorded in `refusedClasses$` (a BehaviorSubject carrying a new `Set` each time, so a panel that starts watching *after* the refusal is armed too), and `watchChanges()` merges a `timer(60s, 60s)` tick carrying a `StompChangeNotification {operation:'update', instanceIds:[], fallback:true}` — the shape every existing consumer already treats as "refetch". `switchMap` on the arming signal means a refusal seen again (reconnect → re-SUBSCRIBE → ERROR again) restarts the one timer rather than stacking timers. The panel keeps its last data and keeps updating, slowly. |
| the four HTTP advisory headers | `src/app/services/security-advisory.service.ts` (new, 190 lines) | ONE `providedIn: 'root'` service, a deduped **counted** list keyed `header × value`, each entry `{kind, header, value, outcome, subject, count, firstSeen, lastSeen, path}`, capped at **200** (past the cap the least recently seen entry goes). Reads `X-Polari-Permission-Advisory`, `X-Polari-Owner-Advisory`, `X-Polari-Traffic-Advisory`, `X-Polari-Auth`. `recordStompNotice()` is the socket door into the same list (kind `subscribe`). URLs are reduced to a path — a query string is not something to park in a notice bar. Nothing is persisted and nothing identifies a person: the values carry class / verb / row id only. |
| the interceptor | `src/app/interceptors/advisory.interceptor.ts` (new) + `src/app/app.module.ts` | registered **LAST** in `HTTP_INTERCEPTORS` (after Auth, AuthError, Roleplay) so it observes the response every other interceptor has had its turn with. Read-only by construction: it clones nothing, swallows nothing, and records off the **error** path too — an enforcing verdict IS a failed request. Wrapped in try/catch: an advisory is never worth an exception in the HTTP path. |
| where a person sees it | `src/app/components/demo-notice/system-notice.component.ts` (the EXISTING bar, already mounted at `app.component.html:5`) | one summarised line — *"Security advisory (dev): 3 would-deny, 1 would-project (seen 42 times) — click for details"* — expanding to the counted list (`×count · outcome · subject · header · path`) with a "Clear" button and a standing sentence that **nothing was blocked**. No new reusable component, no raw JSON. The bar is absent, not empty, when there is nothing to say — which on a production instance (advisories off) is always. Amber (`--color-warn-*`) when anything but `would-project` is present, info blue (`--color-info-*`) otherwise; theme tokens only, rule colours derived with `color-mix(… currentColor …)`, `@container` for the narrow layout. |
| CORS | `polariApiServer/polariServer.py:418-420` — **no edit needed** | `Access-Control-Expose-Headers` already lists all four (`X-Polari-Auth, X-Polari-Permission-Advisory, X-Polari-Owner-Advisory, X-Polari-Traffic-Advisory`) — `X-Polari-Owner-Advisory` came in with f1fd6cc and the other three were already there. `prf-proxy/nginx.{staging,prod}.conf.template` set no `Expose-Headers` of their own and hide none, so the upstream header passes through. **Nothing in `polari-framework` was changed by this slice**, so no framework selftest was re-run. |

**Build.** `cd polari-platform-angular && ng build --configuration=production` → **PASSES** (what `Dockerfile.prod` runs). Initial total 5.50 MB / 962.09 kB transfer — the same budget warning as before (bundle initial exceeds the 5 MB budget by ~496 kB), unchanged by this slice.

**Tests.** `CHROME_BIN=/usr/bin/google-chrome ng test --watch=false --browsers=ChromeHeadless`:
the three touched specs → **25/25 SUCCESS**
(`security-advisory.service.spec.ts` new — 10 specs: four headers off one response, outcome/subject split, dedupe-and-count over 40 responses, distinct values kept apart, the 200 cap dropping the least recently seen, the STOMP half incl. the refused marker, the summary line's outcome tallies and info-vs-warning level, blanks and a headers object that *throws*, `clear()`, `pathOf()`;
`advisory.interceptor.spec.ts` new — 4 specs: success response, ERROR response *with the error still surfacing*, a silent response recording nothing and passing the body through, counting across repeated requests;
`stomp.service.spec.ts` extended — 11 specs: the original four, plus bearer-present / bearer-absent `connectHeaders`, an advisory MESSAGE that never reaches the refetch path while a real change does, the advisory landing in `SecurityAdvisoryService` instead, an ERROR frame marking one class refused while another watch stays alive, and the wire-shape helpers).
Whole suite: **168 SUCCESS / 5 FAILED / 15 skipped (188)**. The 5 reds are `XrLobbyPageComponent` and are **PRE-EXISTING** — proven by `git stash -u` + re-run: 5/5 fail identically with this slice removed.

**Gotchas.**
1. `correlateErrors` is the RxStomp knob that maps an ERROR frame to a destination and **errors that watch's observable**. It is tempting and it is wrong here: the gate's ERROR frame says `destination: /topic/<Class>` with no format segment, so a `/topic/<Class>/flatJson` watch would never correlate, and a watch that *did* correlate would be killed rather than degraded. Left unset (its default is `() => undefined`, i.e. no watch is failed) and the refusal handled out-of-band.
2. An advisory MESSAGE rides the **same destination** as a change notification, and `message-id: permission-advisory` is the only other tell. Without the filter, a panel that refetches on any frame would refetch because security spoke — and if a refetch re-subscribed, forever. This is why the filter lives in `watchTopic`, not in `watchChanges`: two of the three direct `watchTopic` callers would otherwise parse a notice as their payload.
3. `AuthSessionService.refreshAccessToken()` is used rather than the cached `accessToken` subject, because `automaticSilentRenew` swaps the token in oidc-client-ts storage on its own schedule; the cached subject is the fallback when that call is unhappy.
4. The fallback tick is on `watchChanges` only. The three direct `watchTopic` consumers (`equation-execution.service`, `module-bringup`, `api-config`'s WS test) get the *notice filtering* but not a synthetic frame — a fabricated `IMessage` would be parsed by those callers as their own payload shape.

**OWED — the browser pass, on the home staging stack (a person, by eye).**
1. **Signed-in socket.** `pol prod apply` the rebuilt frontend, sign in as a demo-viewer, open devtools → Network → WS → the frames tab: the **CONNECT frame carries `Authorization: Bearer …`**; the container log line reads `connected (STOMP protocol, identity <sub>)` and not `identity anonymous`. Then sign out and reload: the CONNECT frame has no Authorization and the log says `anonymous` — live updates still work.
2. **Advisory notice, advisory mode** (`POLARI_APP_PERMISSIONS=advisory`, the deployed mode). Open a page whose class is outside that viewer's profile. Expect: the panel still updates live; the notice bar shows *"Security advisory (dev): 1 would-deny — click for details"*; expanding shows `×1 · would-deny · <Class>:read · STOMP SUBSCRIBE · /topic/<Class>`. **The key negative:** watch the Network tab for 60 seconds and confirm the panel does **not** refetch on the notice and does not settle into a refetch loop.
3. **HTTP advisories.** On the same page, confirm entries appear for `X-Polari-Permission-Advisory` and (on an owned class) `X-Polari-Owner-Advisory: would-project <Class>:<id>`, with `count` **climbing rather than the list growing** as the page polls. Confirm the bar reads amber with a would-deny present and info-blue with only would-project, in **both** light and dark mode.
4. **Enforce.** Flip the stack to `POLARI_APP_PERMISSIONS=enforce` (temporarily — the standing rule is warn-only in deployments). Expect: the ERROR frame in the frames tab; `/wsStatus` shows an empty subscriber list for that topic; the panel **keeps its last data** and refetches about once a minute; every OTHER panel on the page keeps its live subscription; the socket does not reconnect in a storm (the frames tab should show no repeated CONNECT). Put the knob back to `advisory`.
5. **Cross-origin headers.** On the nip.io staging host (frontend and API on different names), confirm in devtools that the four `X-Polari-*` headers are actually *readable* — i.e. that `Access-Control-Expose-Headers` survives the nginx hop. This is the one thing the unit tests cannot prove.
6. **Expired token.** Leave the tab open past token expiry, then force a reconnect (stop/start the backend): the new CONNECT must carry the **fresh** token, and `X-Polari-Auth: invalid-or-expired` must not be sitting in the advisory list afterwards.

**OWED — code.**
- A fallback path for the three direct `watchTopic` consumers, if `enforce` ever becomes a deployed mode (gotcha 4).
- `REFUSED_FALLBACK_POLL_MS` (60 s) is a guess, not a measurement — it wants his number, or a knob.

## §66 addendum 5 — the OTHER restore path (`restoreFromDatabase`), and the SecurityDecision restart re-check (2026-09-19)

The read §66 addendum 4 owed. `objectTreeManagerDecorators.restoreFromDatabase` → `_restoreTableRows` is NOT
"skip by id": its present-rows logic is `identifySeedDBIds()`, a property FINGERPRINT — any DB row matching a
live instance on ≥ 60 % of comparable columns is dropped from the restore as a re-created seed. It runs FIRST at
every module admission (`lazy_boot._admit`: `restoreTables()` then `ensureDefinitionTables()`), it covers the same
classes as the definition merge (the merge's docstring saying otherwise is out of date), and lazy boot serves
requests while it runs. Three defects, two fixed (framework commit "§66 addendum 5 core"):

| defect | evidence | state |
|---|---|---|
| **D1 — it crashed module admission.** The fingerprint walked the LIVE `objectTables` (and the live per-class dict); a boot-time write adding a key mid-walk raised `RuntimeError: dictionary changed size during iteration` out of `restoreTables()`, failing the whole module | `[LazyBoot] islemesh FAILED …` at 01:39, 02:11, 02:17 and `polariapps` at 01:44 on `polari-lean` — every `/api/apps/security/*` door 503 until a restart | FIXED: both loops iterate a snapshot (the one `_mergeRestoredRows` already takes) |
| **D3 — a duplicate the merge refused to fold.** When the fingerprint did NOT match, the persisted row was restored beside the boot-time row (same name, different id); the merge then saw the persisted id present, counted it "already restored" and skipped the fold | `[DefRestore] SecurityDecision: … 438 already restored` is the branch that actually runs live | FIXED: `_foldNameDuplicates()` shared by both merge branches |
| **D2 — the fingerprint drops a persisted row that DIVERGED.** A boot-time observation and a person's ruling agree on the descriptive columns and differ only on `state` / `confirmed_by` / `confirmed_at` / the counter — 60 % is cleared, so the PERSISTED row is treated as a seed and never loaded; the next persist writes the boot-time row over it | every boot logs `[DB] Found 1 seed IDs for InboundPolicy` and never restores that table; the two `confirmed` ct-9 inbound rows (anonymous 79, origin) live at 02:05 were `suggested` 30 / gone after the restarts, in the API and in sqlite; `OutboundPolicy` likewise. `SecurityDecision` survived only because its table restored while the class had no live instance yet | **NOT FIXED in the addendum-5 commit** — see the next section for the fix |

(b) The path is purely additive: it never pops `objectTables`, never calls `noteTreeDeletion`, never writes the
DB, reads no tombstones and skips `polari_persist_state`. One indirect interaction, described not tested: every
restored instance passes `treeObjectInit` → `noteTreeMutation`, which CANCELS a tombstone — harmless at boot, but
`restoreTables()` also runs mid-life at admission, so a row deleted before its module came online is re-created.
(c) Both paths run back to back on the same class at every admission; the merge heals D2 only for classes in
`defClassList` and only when the fingerprint let the row through.

**Selftests.** NEW `polariApiServer/selftest_restore_from_database.py` **15/15** (6/15 against the shipped code:
D1 raises, D3 leaves two rows; the real methods bound to doubles in the live admission order); restore_merge
17/17; persist_debounce 13/13; persist_tombstones 43/43; crude_delete_blast 21/21; quiesce 27/27; outbound 61/61;
cause_context 41/41; apps 125/125.

**Item 2 — a `SecurityDecision` confirmation survives a forced restart: YES** (stack `polari-lean`, posture dev,
gate advisory, image WITHOUT the addendum-5 fixes). demo-admin bearer → coverage for `app-policy` = 438 subjects
(432 open / 4 suggested / 1 confirmed) → `POST /api/apps/security/decisions/confirm {app, kind: owner-policy,
subject: AccuracyPolicy, decision: confirmed}` 200 → 432/4/2 → wait 100 s → `docker service update --force` →
**both confirmations intact with confirmer + timestamps, 438 rows, 438 distinct names, 432/4/2 identical, sqlite
`[('confirmed', 2), ('open', 432), ('suggested', 4)]`**. Boot log: `[DefRestore] SecurityDecision: merged 0
persisted rows, 0 boot-time rows folded, 438 already restored` and `[DB] Restoring 438 instances of
SecurityDecision` — the table restore gets there first.

**REGRESSION FOUND on the way (ct-9):** the confirmed traffic rows §66 addendum 4 proved surviving do NOT survive
today — D2 above. Re-prove after the D2 fix deploys.

### §66 addendum 5 — the D2 fix: one rule for both restore paths (2026-09-19, fixed, selftested)

D1/D3 stopped the main restore path crashing and taught the merge to fold duplicates on its already-restored
branch, but the two paths still disagreed about what "this row is already here" means: `identifySeedDBIds`
(`objectTreeManagerDecorators.py:~1186`) decides by a ≥ 60 % property FINGERPRINT, the merge by id and name. A
persisted row that has DIVERGED from its boot-time twin — a person's `confirmed` ruling beside an observer's
`suggested` guess — matches on the descriptive half and is dropped as if it were a re-created seed. Live on
`polari-lean` every boot: `[DB] Found 1 seed IDs for InboundPolicy`, and no restore of that table. Where the
merge runs afterwards it puts the row back; where it does not — a module whose admission died between
`restoreTables()` and `ensureDefinitionTables()`, which D1 did four times — the ruling is gone and the next
persist writes the half-booted tree over it.

**The fix** (framework commit "§66 addendum 5 D2 core"): `polariServer` publishes the merge's remit to the
manager (`_noteMergeGovernedClasses`, called where the def classes are registered and again in
`ensureDefinitionTables` so dyn-2 live admissions are covered), and `identifySeedDBIds` SKIPS those classes
entirely — they restore by id and the §66e name-merge folds the boot-time twin (persisted wins every field,
counters summed, twin tombstoned). One rule governs both paths for every `defClassList` class; every other class
keeps the fingerprint byte-for-byte, because a pure seed whose code definition changed must still lose to the
code and only the merge can make that call by name. The generic rule ("any differing column ⇒ not a seed") was
considered and rejected: it is that same changed-seed case, and without a name-merge behind it, it duplicates
the seed permanently.

**Selftests.** `polariApiServer/selftest_restore_from_database.py` **25/25** (22/25 with the exemption patched
out — the three D2 checks, including "the ruling survives an admission that dies before the merge"); it also pins
the bound: a pure seed duplicate of a non-merge class is still dropped, and a pure seed of a merge-governed class
is deduplicated by the merge rather than by resemblance. Regression: restore_merge 17/17, persist_debounce
13/13, persist_tombstones 43/43, crude_delete_blast 21/21, quiesce 27/27, outbound 61/61, cause_context 41/41,
apps 125/125, security 250/253 (the 3 known env failures), import clean, `selftest_lazy_boot` 33/34 (the
pre-existing manifest-drift pin).

**OWED:** unproven live — the image on `polari-lean` carries none of addendum 5, so the ct-9
`InboundPolicy`/`OutboundPolicy` confirmations lost across today's restarts are to be re-checked after the next
rebuild; the `restoreTables()`-cancels-a-tombstone resurrection is described, not tested.

## §69 — op-1 + op-2 + op-4: owner grants, anonymised classes, and the `app.owned` stanza (2026-09-19, built, selftested)

Design `AI-Notes/designs/OWNER_DEFINED_PERMISSIONS_DESIGN.md` §2 (the rows), §3 step 3 (the verdict), §5 (the
anonymised side channels), §6 (the doors and the Sharing tab), §7 (the manifest stanza), §8 (the decisions), §9
rows op-1 / op-2 / op-4. On top of §60 (op-0: the policy, the stamp, the CRUDE gate). **op-3 (`Ballot` in the
governance module) is NOT in this slice** — it waits for that module to exist; everything op-3 needs from the
mechanism is now built and proven against a `Ballot` double.

His ask this whole arc answers (2026-09-18): *"other people do not have the permission to alter the data on
their vote, they only have partial read access and only to the contents of the vote and groups the vote
corresponds to, not who specifically made that vote."* op-0 built the first half of that sentence; op-2 closes
the three ways the second half ("not who") leaks anyway.

**One new row class: `OwnerGrant`. The security class count goes 36 → 37, seed pairs 36 → 37, pages 9 → 10.**

### op-1 — the owner's per-instance grants, and the Sharing tab

| built | where |
|---|---|
| `OwnerGrant` — one owner sharing ONE of their own instances; `name` = `class\|id\|kind\|grantee` (the dedup key, so re-granting rewrites rather than doubles) | `modules/security/objects/security/OwnerGrant.py` (new, 62 lines) |
| the model: `grants_for` / `grant` / `revoke` / `match` / `may_grant` / `prune_expired` / `expired` / `sharing` / `sharing_tab` | `modules/security/custom/security_owner_grants.py` (new, 487 lines, in the manifest) |
| the verdict honours grants (design §3 step 3): verbs ∪ `others_verbs`, fields ∪ `others_fields`, evidence `grant:<id>` | `security_owned.owner_verdict` + `_grants_match` |
| 3 doors: `GET` / `POST` / `DELETE /api/security/owned/{class}/{id}/grants` | `modules/security/security_api.py` (`on_get/post/delete_owned_grants`) |
| `GET /api/security/owned/{class}/{id}` extended with `grants` + `sharing` (the tab's whole answer in one door) | `security_owned.verdict_for_id` |
| the Sharing tab as DATA: a configured `class-rows-table` over `OwnerGrant`, `filterField: object_id` | `security_owner_grants.sharing_tab` |

**A grant never widens the class door.** `crude_permission_gate` decides C × V for the grantee's groups before
any instance is resolved; a grant only restores a verb `others_verbs` withheld and widens a projected read.
The bounds are all checked at the door, never in the row class: `owner_may_grant` on, the caller is the OWNER
(or an admin), `verbs ⊆ grantable_verbs`, `grantee_kind ∈ grantee_kinds`, `fields ⊆ the class's own columns`,
never the owner column of an anonymised class, never a username where a `sub` belongs, and **never to
yourself** (that is the owner floor written down twice).

**Expiry is checked by the verdict, not by the prune.** A grant is dead the instant `valid_until` passes —
`match()` skips expired rows — and `grants_for()` prunes them on the next read so the table does not grow a
tail of dead permissions, writing a `SecurityEvent` per pruned row. A `valid_until` already in the past is
refused at the door ("that is a revoke, not a grant"); an *unreadable* `valid_until` is refused at the door too,
rather than silently becoming "never expires" once written.

### op-2 — anonymised classes, `frozen_when`'s structured form, `transfer`

| built | where |
|---|---|
| `anonymised` normalised where the policy is READ: forces `owner_visible` false **and** `transfer` `nobody` (`transfer_declared` keeps what the row says) | `security_owned.policy_for` |
| `frozen_when`'s structured shape `{"class","field","in"\|"eq"\|"ne","via"}` beside op-0's sentence grammar, in the same column | `security_owned._frozen_structured` / `frozen` |
| `transfer_owner()` + `POST /api/security/owned/{class}/{id}/transfer {"to": "<sub>"}` | `security_owned.py` + `security_api.on_post_owned_transfer` |
| side channel 3: `event_target()` — the CLASS NAME alone for an anonymised class — and the owner gate now ledgers refused writes through it | `security_owned.event_target`, `accessControl/owner_gate.py::_event` |
| side channel 1 (broadcast, built by ct-2) and 2 (trace journal, built by ct-1) — **verified**, not rebuilt | `grpcbridge/custom/transport_mux.py::publish_crude_change`, `security_trace._anonymised` |

**The three side channels were never selftested together until now.** ct-2 dropped `instanceIds` for an
anonymised class and ct-1 dropped the journal's `actor`/`object_id` pairing as they were built, but nothing
proved either, and the third (`SecurityEvent.target`) did not exist. "Closed" is only true of the three at
once, so §69 proves all three in one check block against one anonymised `Ballot` policy.

**Transfer, and why this door refuses in every gate mode.** `advisory` makes the CRUDE gate warn instead of
blocking *an app doing its job* — security is learning what it would stop. A transfer is not that: its only
effect IS to move the ownership the gate reads, so a warning that proceeded would have done the thing it
warned about. The admin policy door (`POST /api/security/owned/<Class>`) set this precedent in op-0. `nobody`
refuses an administrator too, with the reason: change the policy first, on the record, then transfer.

### op-4 — the `app.owned` manifest stanza

| built | where |
|---|---|
| the vocabulary + `owned_findings()` (mirrors `role_findings` / `flow_findings`), wired into `validate()` | `moduleService/manifests.py:168-292, 660` |
| `owned` joins the HAND-SET keys `generate` preserves, beside `roles` and `flows` | `manifests._preserve_hand_set` |
| `OwnedClassPolicy.source` (`manifest` \| `admin` \| `''`) + `derived_from`; `SOURCES` | `objects/security/OwnedClassPolicy.py` |
| the convergence: `declarations()` / `ensure_policies()` / `summary()` / `start_owned_converge()` | `modules/security/custom/security_owned_manifest.py` (new, 196 lines, in the manifest) |
| converged on every read of `GET /api/security/owned` (via `policies(converge=True)`) and once at boot | `security_owned.policies`, `security_endpoints.construct_security_endpoints` |
| the ONE real declaration: `polariapps` declares `UserAppPreference` | `modules/polariapps/polari-app.json` `app.owned` |
| `SEED_OWNED_CLASS_POLICIES` emptied — the security module ships the mechanism and opts in nobody else's class | `modules/security/security_seed.py:128-146` |

**Which source of truth wins, and why (the question op-0's seed left open).** The **manifest** wins for
`UserAppPreference`, and the seed row is gone. A policy is a statement *about a class*, and the only place it
can be kept beside the thing it describes is the module that defines the class — `polariapps`. A seed in
`security` would go stale the moment `polariapps` changed `UserAppPreference` and nothing would say so; keeping
both would be two sources of truth for one sentence, exactly the drift §57 removed from role→app bindings. The
ladder is therefore:

- `source: admin` — a person POSTed it. **Never** overwritten; the manifest declaration is reported as a named
  `conflict` instead of applying (the `RoleAppBinding` discipline, §57).
- `source: manifest` — re-derived on every read, so editing a manifest reaches a running instance with nobody
  acting.
- `source: ''` — an op-0 **seeded** row, written before the stanza existed. Treated as re-derivable, because
  the seed IS this derivation's earlier spelling of the same sentence. **Consequence for the live stack:** the
  existing `UserAppPreference` row on `polari-lean` converges *in place* (identical content, `source` set to
  `manifest`) rather than a second row appearing for one class.

### Screens

`_page('security-owned', …)` in `modules/security/security_page.py` — 6 rows, `api-structured-panel` and
`class-rows-table` only, **no new component, nothing raw**: the gate mode + opted-in classes; the
`OwnedClassPolicy` table (with `source` / `derived_from`); the modules' declarations beside the last
convergence and its conflicts; the `OwnerGrant` table; the parsed policies; and the owner gate's own
`SecurityEvent` rows (where the anonymised `target` = class is visible). A `SecurityArea` row
(`owner-permissions`, domain `app`) names the arc in the taxonomy on `/display/security`. It converges through
the existing `seed_security_pages` / `start_page_converge` (the §54 gotcha: the core seed only INSERTS).

### Selftests — exact numbers (all run; nothing regressed)

| suite | before | after |
|---|---|---|
| `modules/security/security_selftest.py` | 250/253 | **283/286** (+33 checks; the same 3 known environment failures) |
| `accessControl/selftest_cause_context.py` | 41/41 | 41/41 (the new converge thread listed in `KNOWN_THREAD_SITES`) |
| `modules/polariapps/apps_selftest.py` | 125/125 | 125/125 |
| `python3 -m moduleService.selftest_manifests` | 8/8 | 8/8 |
| `python3 -m moduleService.manifests conform --all` | 61/61 | 61/61 |
| `polariApiServer/selftest_crude_delete_blast.py` | 21/21 | 21/21 |
| `polariApiServer/selftest_outbound.py` | 61/61 | 61/61 |
| `polariApiServer/selftest_stomp_gate.py` | 41/41 | 41/41 |
| `polariApiServer/selftest_restore_merge.py` | 17/17 | 17/17 |
| `import polariApiServer.polariServer` | clean | clean |

The 3 failures are the known environment ones and the ONLY ones: ledger `mac_enforced`, mac profiles, expired
internal certs.

The +33 checks, by slice. **op-1** (`_grant_checks`, 13): a class that forbids grants has no tab; *the* proof —
a meal plan shared with ONE person by sub, refused before and projected-to-the-granted-fields after, with the
verdict naming `grant:<id>`; nobody else in the same group gains anything; the sub stored in its own column;
**expiry removes it** (past refused at the door, live grant dies on the clock, dead row pruned on read); the
seven bound refusals each with its reason; a group grant and the fields UNION; revoke; the admin path and the
404; the Sharing tab as a configured table with both `person` columns holding subs only; the four doors incl.
the query-string revoke. **op-2** (`_anonymised_checks`, 11): `anonymised` normalised at the read; the
projection; **all three side channels** — broadcast without ids (and a non-anonymised owned class keeping
them), journal with no actor/object pair, `SecurityEvent.target` = class; no actor on the gate's own rows;
`frozen_when` structured (open → certified → frozen, read survives, a spec with no operator is not frozen);
transfer under `nobody` / `owner`, refused for a username, for self, for a non-owner, and always for an
anonymised class; the door refusing in every gate mode. **op-4** (`_owned_manifest_checks`, 7): a well-formed
stanza and the vocabulary matching the row class; eleven refusal shapes; `validate()` carrying them and
`owned` surviving a regeneration; the one real declaration; the convergence creating the row with nobody
touching an admin door, idempotently; an admin row never overwritten and reported as a conflict; a seeded
(`source: ''`) row re-derived in place rather than doubled. Plus the three count checks (37 classes, 37 seed
pairs, 10 pages) and the §54 route guard extended to five owner doors.

### Gotchas found / decisions taken where the design was silent

1. **`grantee` is TWO columns, not one.** The design names one `grantee` field holding *a group name, or a
   `sub`*. A single column would put a Keycloak subject id and a Keycloak group name in one place, and §54's
   `person` column format shortens a cell to 8 characters to resolve it live — so the first group grant would
   render `household-members` as `househol` on the security-owned page (`PeopleService.short()` truncates
   blindly; it does not check the value is sub-shaped). The row therefore keeps `grantee_group` and
   `grantee_sub`, exactly one of which is ever set; the DOOR keeps the design's `{grantee_kind, grantee}`
   shape and routes the value; the dicts carry `grantee` as the design spells it. Both `person`-formatted
   columns (`granted_by`, `grantee_sub`) then hold a sub and nothing else.
2. **There is no per-instance surface to hang a Sharing tab on, and none was invented.** `class-main-page`'s
   tabs are hardcoded `mat-tab`s at the CLASS level; `components/instance/` has no tabs and reads no
   `DisplayDefinition`; pages are route-level (`/display/<pageRoute>`) with no instance in scope. So op-1 built
   the whole backend half and the tab itself as DATA: `sharing()` answers the grants, the bounds,
   `show_tab`, `you_may_share` + why, and `table` — a complete `class-rows-table` item
   (`className: OwnerGrant`, `filterField: object_id`, `filterValue: <id>`,
   `columnFormats: granted_by:person,grantee_sub:person`) ready to render. **What the frontend needs** is in
   the OWED list below; it is a host, not a component.
3. **`class-rows-table`'s filter is an EXACT CRUDE match on one field**, so the per-instance scope is
   `object_id`, not a prefix of the composite `name`. (And explicit `columns` bypass the `includeJsonFields`
   filter, which is why `verbs_json` / `fields_json` can be named.)
4. **`anonymised` is normalised in `policy_for`, not at each consumer.** Design §2 calls it *shorthand for
   `owner_visible: false` + the §5 suppressions*. Resolving it at the single read point means a row saying
   `anonymised: true, owner_visible: true, transfer: owner` comes back with `owner_visible` false and
   `transfer` `nobody` — the owner cannot leak through whichever half of the pair a consumer forgot to check.
   `transfer_declared` keeps what the row literally says, so the contradiction is visible rather than erased.
5. **Refused list READS are not ledgered.** Design §5 says a refused act on an anonymised class names the
   class. That is implemented for WRITES (`owner_gate_write`). A private list of a thousand rows would
   otherwise write a thousand events, and an omitted or projected row is not an act somebody took — the
   advisory header already tells the caller what enforcement would have hidden.
6. **The owner gate records no `actor` on its own rows.** The person refused is the one the owner rules are
   protecting a row *from*, and who performed which class × verb is already counted by `PermissionObservation`.
   One ledger per question.
7. **A grant is never a widening, and the code says so twice** — once in `OwnerGrant`'s docstring and once in
   the door's `how`. The class gate has already run; a grant cannot reach past it. This matters because the
   obvious misreading ("I'll grant a group `delete` on my row") would otherwise look like a privilege
   escalation path.
8. **The structured `frozen_when` shares op-0's column.** A JSON object in `frozen_when` is read as the
   structured form; anything else goes to the sentence grammar. JSON is what a *manifest* can declare (op-4),
   and a person can still type the sentence. Both failure modes are identical and deliberate: a malformed or
   unresolvable condition is **NOT frozen**, and lands in the ledger.
9. **Two converges per request, fixed.** `GET /api/security/owned` reads the manifest summary (which
   converges) and then `policies(converge=False)` — one derivation per request.
10. **`accessControl/selftest_owner_gate.py` does not exist** (op-0's gate selftest lives inside
    `security_selftest._owned_checks`); the new checks went beside it in the same file, and the cause-context
    thread-site guard needed the new converge worker listed or it fails.

### OWED — the live proof on the home stack, and the browser pass

Nothing in §69 has run on `polari-lean`. The exact steps, in order, once the framework pin moves and the swarm
image is rebuilt (`pol swarm deploy` — the stack respawns from the IMAGE, so an in-place edit proves nothing):

1. **The manifest declaration appears with nobody touching an admin door** (op-4's own proof).
   `GET /api/security/owned` → `manifest.declared` names `polariapps` / `UserAppPreference`,
   `manifest.converge.created` (fresh) or `.updated` (the existing seeded row converged *in place*), and the
   policy row reads `source: manifest`, `derived_from: polariapps`, `owner_field: sub`. Then
   `pol modules health` / a restart, and confirm there is still exactly ONE `OwnedClassPolicy` row for that
   class — the seeded-row-converged-in-place case is the one that can go wrong on a live tree.
2. **Opt a real class in and share one row by sub.** As an admin,
   `POST /api/security/owned/MealPlan {"enabled": true, "owner_verbs": ["read","update","delete"],
   "others_verbs": [], "owner_may_grant": true, "grantable_verbs": ["read"], "grantee_kinds": ["person"]}`
   (this row will read `source: admin`, and step 1's convergence must then leave it alone — check
   `manifest.converge.conflicts` is empty because nothing declares `MealPlan`, and that the row is not
   rewritten on the next read). Create a meal plan as person A; confirm `owner` holds A's `sub` and nothing
   else. As person B, `GET /api/MealPlan/<id>` — refused/omitted (advisory: the whole row plus
   `X-Polari-Owner-Advisory: would-deny`). As A,
   `POST /api/security/owned/MealPlan/<id>/grants {"grantee_kind":"person","grantee":"<B's sub>",
   "verbs":["read"],"fields":["title","servings"]}`. As B, read again → the projected row, and
   `GET /api/security/owned/MealPlan/<id>` shows `rule: grant:<id>`.
3. **Expiry removes it.** Re-grant with `valid_until` two minutes out; read as B (allowed), wait, read again
   (refused), then `GET …/grants` and confirm the row is gone and a `SecurityEvent` says why.
4. **A transfer.** Set `MealPlan`'s policy `transfer: owner`; as A,
   `POST /api/security/owned/MealPlan/<id>/transfer {"to": "<B's sub>"}`; confirm the `owner` column moved,
   that A now reads the row as *others* do, and that the same call with a username instead of a sub is a 400
   naming D18-1.
5. **An anonymised class broadcasts no id.** Opt a throwaway class in with `anonymised: true`, subscribe a
   STOMP client to `/topic/<Class>`, create a row, and confirm the frame carries `className` + `operation`
   with `instanceIds: []` — while a non-anonymised owned class still carries its ids. Then arm that class as a
   `TraceTarget`, create another row, and confirm the journal row has neither `actor` nor `objectId`. Then
   refuse a write on it as a non-owner and confirm the `SecurityEvent.target` is the class name alone on
   `/display/security-owned`.
6. **The browser pass.** `/display/security-owned` renders: the summary chips, the policy table with
   `source` / `derived_from`, the declarations and the convergence panels, the grants table with `granted_by`
   and `grantee_sub` resolving to names through the gated people door (and a *group* grant showing its group
   name in full, unshortened — the reason for gotcha 1), and the owner-gate events. Confirm no `api-json-panel`
   and no raw JSON anywhere on it, and that the page CONVERGED rather than being inserted (the §54 gotcha).
7. **The Sharing tab — still OWED, and it needs a frontend host.** `GET /api/security/owned/<Class>/<id>`
   already returns `sharing.table`, a complete `class-rows-table` item filtered to the instance, plus
   `show_tab` / `you_may_share` / `bounds`. What is missing is a per-instance page that reads
   `DisplayDefinition`-style items — the same treatment `class-main-page` gives a class, given to one row — so
   that a "Sharing" tab can render `sharing.table` and hide itself when `show_tab` is false (a ballot's page
   must have no tab at all). No new component: the table component already exists and already takes
   `filterField` / `filterValue` / `columnFormats`. Until that host exists there is nothing to click.
8. **Also still open:** op-3 (`Ballot` + the derived `VoteRecord` tally) waits for the governance module; the
   `events` verb is in `OWNER_VERBS` and `on_event` still carries no owner gate (§60's last OWED item, not
   closed here); and `frozen_when` has still only been exercised against in-memory doubles in both spellings.

## §67–§69 + §66 addendum 5 — live proof on `polari-lean` after the eighth deploy (2026-09-19, framework `dcf221b`, angular `621d299`, posture dev, gate advisory)

_Report by the live-proof agent, verbatim but with the home stack's address written `<lan>`; the sqlite inside the container was read for every persistence claim._

### The report

- Date: 2026-09-19, 03:00–03:35 UTC
- Stack: swarm `polari-lean`, posture **dev**, gate **advisory**, `POL_PROD_POSTURE=dev`
- Pins verified live: `polari-rf-node/polari-framework` = **dcf221b**, `polari-platform-angular` = **621d299**
- Health before starting: `phase: online`, `onlineCount 6 / moduleCount 6` (appstore, islemesh, iso, polariapps, security, terms), `secondsToFull 103.692`
- No tracked file edited, nothing committed, no image rebuilt. Three forced backend restarts via `docker service update --force polari-lean_prf-backend`.
- `/app/data` confirmed to be a **named volume** (`polari-suite_prf_lean_data`), so the sqlite DB survives a container replacement — every "persisted" claim below was checked against `/app/data/managerObject_DB.db` inside the running container, not inferred from the API.

**Headline:** 5 of 6 sections pass. **One hard defect** (§66 addendum 5 D2 is NOT closed for `InboundPolicy`), **one privacy defect** (a hostname on the objects view), and **two OWED steps that cannot be run as written**.

---

### A. Restore (§66 addendum 5)

| step | request | result | verdict |
|---|---|---|---|
| A1 boot log — exemption | `docker logs <prf-backend>` after each boot | 6 occurrences per boot, e.g. `[DB] 70 classes exempt from the seed fingerprint — the definition merge governs them and restores them by id (§66 addendum 5)` (also at 33/36/41/46/49 classes as modules are admitted) | **PASS** |
| A2 boot log — `[DefRestore]` | same | present for every def class, e.g. `[DefRestore] SecurityDecision: merged 0 persisted rows, 0 boot-time rows folded, 438 already restored`, `[DefRestore] InboundPolicy: merged 0 persisted rows, 0 boot-time rows folded, 1 already restored` | **PASS** |
| A3 no `dictionary changed size` (D1) | `grep -c "dictionary changed size"` on all 4 boot logs | **0** on every boot | **PASS** |
| A4 no `[LazyBoot] … FAILED` | `grep -c "LazyBoot.*FAILED"` on all 4 boot logs | **0**; all 6 modules reach `online` every boot | **PASS** |
| A5 D2 fix visible | `grep "seed IDs for InboundPolicy"` | **no hits** — `InboundPolicy`/`OutboundPolicy` are now in the exempt set and restore by id (`[DB] Restoring 1 instances of InboundPolicy`), vs. the addendum-5 report's `[DB] Found 1 seed IDs for InboundPolicy` | **PASS** |
| A6 ct-9: both inbound rows exist | `GET $API/api/security/traffic` (demo-admin) | `anonymous\|anonymous` (suggested, count 30) present at once; the `origin\|https://prf.<D>` row appeared after 3 requests carrying `Origin:` | **PASS** |
| A7 body-addressed door confirms both | `POST $API/api/security/traffic/inbound {"name": …, "decision":"confirmed"}` ×2 | both 200, `"state": "confirmed"`, `"confirmed_by": "5cacba59-…"`, `confirmed_at` stamped. The door accepts the `origin` name containing `://`, which the `/{name}` path form cannot carry (§66a) | **PASS** |
| A8 the ruling reaches the DB | sqlite `SELECT name,state FROM InboundPolicy` | **7 seconds** after the POST: `[('anonymous\|anonymous','confirmed'), ('origin\|https://prf.…','confirmed')]` | **PASS** |
| A9 the ruling is stable while running | DB + API polled every 15 s for **200 s**, no restart | both rows stay `confirmed` in DB *and* API the whole time, counts tracking (24→43) | **PASS** |
| A10 **survives a forced restart** | `docker service update --force` at 03:14:49, all-online 03:17:08, re-read | **`anonymous\|anonymous` is back to `suggested` (confirmed_by empty, count reset to 17/18) and the `origin\|…` row is GONE ENTIRELY.** sqlite agrees: `[('anonymous\|anonymous','suggested',17)]`. Reproduced a second time at 03:26:16→03:28:40 | **DEFECT — see D-1** |
| A11 coverage before/after | `GET /api/apps/security/coverage?app=app-policy` | before `{open 432, suggested 4, confirmed 2, denied 0, inherited 0, stale 0}`; after **identical**; unchanged again after the 2nd and 3rd restarts | **PASS** |

### D-1 — the confirmed `InboundPolicy` rulings do not survive a restart (§66 addendum 5 is not closed)

Reproduced **twice**, each time with the DB verified `confirmed` *before* the restart.

Timeline of the clean run:

```
03:14:28  POST …/traffic/inbound {"name":"anonymous|anonymous","decision":"confirmed"}   -> 200 confirmed
03:14:28  POST …/traffic/inbound {"name":"origin|https://prf.<D>","decision":"confirmed"} -> 200 confirmed
03:14:35  sqlite: [('anonymous|anonymous','confirmed'), ('origin|https://prf.<D>','confirmed')]
03:14:49  docker service update --force polari-lean_prf-backend
03:17:08  all 6 modules online
03:17:1x  GET /api/security/traffic  -> inbound: [('anonymous|anonymous','suggested',18)]   (origin row absent)
03:17:1x  sqlite:                    -> [('anonymous|anonymous','suggested',17)]
```

The decisive discriminator, from the third restart (03:26:16 → 03:28:40):

```
outbound: [('keycloak|Polari|rest', 'confirmed', 12)]      <- SURVIVED
inbound:  [('anonymous|anonymous',  'suggested', 24)]      <- LOST, and origin|… deleted
```

`OutboundPolicy` — same class family, same exemption, same merge — **keeps** its confirmation across the very same restart. `PermissionObservation` (15 rows) and `ObservationSession` (3 rows) also survive intact (section C). So the exemption and the merge work; **`InboundPolicy` alone is lost.**

The boot log points at the cause. On every boot the first read of the table already sees only one row:

```
17923:[DB] Restoring 1 instances of OutboundPolicy
17930:[DB] Restoring 1 instances of InboundPolicy         <- 2 rows were in the DB at shutdown
17934:[DB] Restoring 15 instances of PermissionObservation
17948:[DB] Restoring 3 instances of ObservationSession
18088:[DefRestore] OutboundPolicy: merged 0 persisted rows, 0 boot-time rows folded, 1 already restored
18090:[DefRestore] InboundPolicy:  merged 0 persisted rows, 0 boot-time rows folded, 1 already restored
```

`SELECT * FROM InboundPolicy` at restore time returns **one** row when the DB held **two** at shutdown, and the surviving one carries `count 17` — i.e. the count of requests observed *during this boot*, not the 43 it had before. That is a fresh boot-time row, not the persisted one. The `derived_from` of the row that comes back says it in words:

> `observed before the tree was restored (boot-time; flushed at the first request — §66a/§66b)`

**Reading:** the §66a/§66b boot-time inbound flush writes its `suggested` row *and persists it* before `restoreTables()` reads the table, so the restore has nothing left to restore and the merge (`merged 0 persisted rows, 0 boot-time rows folded`) never sees the twin it is supposed to fold. This is the §66 addendum 2 restore-race shape, still live on the one class that observes traffic at boot. The addendum-5 D2 exemption fixes *which* rows are eligible to restore; it does not stop the table being rewritten before the restore runs.

**Consequence:** the ct-9 inbound half is not durable. A person's `confirmed` inbound ruling is silently discarded at the next restart, and a second inbound row is deleted outright — under `enforce` that would close a door a person had opened.

---

### B. ct-5 — the `objects` topology view (§67 OWED steps 1–5)

| step | request | result | verdict |
|---|---|---|---|
| B1 declared manifest flows | `GET $API/api/security/topology?view=objects` (demo-admin) | both present with `provenance: declared` and empty payload: `this instance -> external:odoo` (`app.flows:odooconnect declares it`) and `this instance -> external:keycloak:realm` (`app.flows:security declares it`). `drift.counts.observed` = **0** before anything armed | **PASS** |
| B2 drift door anonymous | `GET $API/api/security/objects/drift` no bearer | **401** | **PASS** |
| B3 drift door signed in | same with bearer | `['ok','observed_not_declared','declared_not_observed','by_app','coverage','not_traced','not_traced_detail','counts','reading','how']`; `by_app` has one entry per app with `coverage`/`reading`; `not_traced` present (empty — see N-1) | **PASS (shape)** |
| B4 arm a TraceTarget | `POST /api/security/observe/trace {"class_name":"UserAppPreference"}` | 200, `armed: true`, budgets `max_traces 200 / max_edges 500 / max_depth 8 / window 3600` | **PASS** |
| B5 one target at a time (his rule) | `POST …/observe/trace {"class_name":"RolePrototype"}` while armed | refused: `a trace target is already armed: UserAppPreference … Only one class is traced at a time — DELETE /api/security/observe/trace first.` | **PASS** |
| B6 the tracer records | `GET /UserAppPreference` while armed | new edge `endpoint:GET /UserAppPreference\|object:UserAppPreference:read\|crude`, target row `traces_opened 1, edges_written 1` | **PASS** |
| B7 **an observed keycloak edge** | `GET /api/security/people/<sub>` with `UserAppPreference` armed; then `DELETE /api/security/roles/claim?role=journalist` with `RolePrototype` armed | the keycloak send demonstrably happened (`x-polari-traffic-advisory: would-deny outbound keycloak:Polari` on both responses) but **no observed edge was recorded** — `traces_opened 0, edges_written 0`, `drift.counts.observed` stays 0 | **NOT RUNNABLE — see N-2** |
| B8 `mode=enforce` reads `blocked` | `GET …/topology?view=objects&mode=enforce` | with everything unconfirmed: `counts {allowed 0, logged 2, blocked 2}` — `external:odoo` and `external:keycloak:realm` read **blocked** | **PASS** |
| B9 `mode=enforce` reads `allowed` for a confirmed flow | confirmed `OutboundPolicy keycloak\|Polari\|rest`, re-read | `counts {allowed 1, logged 2, blocked 2}`; `external:keycloak:Polari` → **allowed**, `decided_by: outbound-wrapper`, why `OutboundPolicy (confirmed by 5cacba59-…) declares this call` | **PASS** |
| B10 the mode is a reading, not an apply | during/after the enforce reads | `GET /api/health` 200, `GET /api/security/people/<sub>` 200 (a real keycloak call still succeeds); `mode=stock` reads `{allowed 4, logged 0, blocked 0}` | **PASS** |
| B11 disarm | `DELETE /api/security/observe/trace` | `armed: false`; left disarmed at the end of the run | **PASS** |

### D-2 (privacy) — the objects view prints a hostname, contrary to its own contract

The view's own `description` says:

> *"Classes and counts only — an instance id never appears here."*

and its `this instance` node says *"no hostname and no address appears on this view"*. §67 lists among the selftested checks: *"**no instance ids, no addresses, no hostnames anywhere on the view**"*.

But once an `origin` `InboundPolicy` row is confirmed — the normal outcome of a browser using the stack — the view carries the origin URL verbatim, as a node, an edge target, a drift entry and a summary row:

```
node    : {"node": "external:origin:https://prf.<lan>.nip.io", "kind": "external",
           "layer": 3, "title": "external:origin:https://prf.<lan>.nip.io",
           "description": "an external system: origin"}
edge    : this instance -> external:origin:https://prf.<lan>.nip.io
drift   : {"kind": "origin", "name": "https://prf.<lan>.nip.io", …,
           "declared_by": "InboundPolicy (confirmed by 5cacba59-…)"}
```

On this stack that string is a hostname **and** a LAN IP (nip.io encodes the address in the name). The selftest cannot have caught it because the declared sources it exercises carry no origin row. This also brushes the standing *privacy: no real identifiers* rule for anything copied off the page.

### N-1 — §67 OWED step 5 (`coverage: none` + a populated `not_traced`) cannot be exercised here

Both real `app.flows` declarations (`security` → keycloak, `odooconnect` → odoo) declare `classes: []` by design, and the two confirmed `InboundPolicy` rows carry no classes either. So every app reads `coverage: full` with `classes: []` and `not_traced: []`:

```
(deployment) | coverage full | undeclared 0 | unexercised 3 | not_traced []
odooconnect  | coverage full | undeclared 0 | unexercised 1 | not_traced []
security     | coverage full | undeclared 0 | unexercised 1 | not_traced []
reading: 5 declared flow(s), 0 observed; 0 observed flow(s) nothing declares … 5 declaration(s) nothing has exercised.
          no class has crossed a boundary yet, and none is declared
```

The OWED wanted *"an app whose classes have never been armed reads coverage `none` and names them in `not_traced`, NOT an empty list"*. Until a declaration on this instance names a class, that branch is unreachable live. (It is also arguably wrong that an app that declared nothing and traced nothing reads `full`.)

### N-2 — §67 OWED step 2's recipe cannot produce an observed flow (code reason)

The step says: arm `UserAppPreference`, then drive `/api/security/people/{sub}` ("the cheapest" keycloak send), then expect an observed keycloak edge. It cannot work, and the reason is in the framework:

- `polariApiServer/outbound.py:132` imports **only** `record_outbound` — not `touch`. An outbound send therefore never *opens* a trace.
- `security_trace.record_outbound` → `record_edge`, and `record_edge` (`modules/security/custom/security_trace.py:464-475`) is a **no-op unless the current chain is already traced**:

```python
cause = current_cause()
if not cause or not is_traced(cause.get('trace_id', '')):
    return None
```

- A trace opens only where `touch` is called — `accessControl/app_permissions_gate.py:80` (the CRUDE gate), `stomp_gate.py:273`, `event_dispatcher.py:157`, `transport_mux.py:75`, `remote_hydration.py:168`.

So an observed external edge requires **one request that passes the CRUDE gate for the armed class and then sends outbound**. `/api/security/people/{sub}` touches no Polari class. I also tried `DELETE /api/security/roles/claim?role=journalist` with `RolePrototype` armed — `security_claims.may_claim` reads `RolePrototype` directly, not through the CRUDE gate, so `traces_opened` stayed 0. No door on this instance does both. `drift.counts.observed` therefore stayed 0 for the whole run, and steps 2–3 (the observed half, and `observed_not_declared`) are **unproven**.

### N-3 — the manifest's keycloak and the real keycloak are two different nodes

`app.flows:security` declares system name **`realm`**; the actual send is recorded and policed as **`Polari`**. They appear as two separate nodes (`external:keycloak:realm` and `external:keycloak:Polari`), and under `enforce` the manifest-declared one reads **blocked** while the confirmed one reads **allowed**. The manifest declaration will therefore never match the real traffic, and `declared_not_observed` permanently lists `keycloak:realm` as *"DECLARED, NEVER OBSERVED"*.

### N-4 — a confirmed inbound flow can never read `allowed`

Under `enforce` the two person-confirmed inbound rows read `logged`, not `allowed`, because the `app-flows` chain step logs first:

```
== external:anonymous:anonymous
   app-flows        -> logged   | NO manifest declares this flow (design §9): a finding, never a block — dev warns
   traffic-policy   -> allowed  | a person confirmed this flow
   outbound-wrapper -> allowed  | the call passes the one wrapper …
   causal-map       -> n/a      | NOT TRACED: no TraceTarget has ever been armed on these classes …
```

Since `app.flows` is an *outbound* vocabulary, no module can ever declare an inbound origin, so every inbound edge carries a permanent finding. Behaviour may be intended; the §67 OWED's wording ("the confirmed one `allowed`") does not match what the view says for inbound.

---

### C. ct-7 — tasks + needs (§67 OWED steps 6–8)

| step | request | result | verdict |
|---|---|---|---|
| C1 roleplay permission | `GET /api/security/observe/roles` as demo-journalist | `can_roleplay: true`, `why: "granted by group(s) journalist"`, `roleplay_groups: ["journalist","developers"]` — no admin knob needed | **PASS** |
| C2 open session with a task | `POST /api/security/observe/session {"role":"journalist","task":"publish an article"}` + `X-Polari-Roleplay: journalist` | `session journalist\|2026-09-19T03:25:23Z`, `already_open false`, `task "publish an article"`, `task_changed true`, `tasks [{task, at}]` | **PASS** |
| C3 3 reads under task 1 | `GET /RolePrototype`, `/UserAppPreference`, `/PolariAppDefinition` | all 200 | **PASS** |
| C4 change the task mid-session | `POST` the same door with `"task":"score a source"` | `already_open **true**`, `task "score a source"`, `task_changed true`, and `tasks` keeps **both** with timestamps | **PASS** |
| C5 2 reads under task 2 | `GET /RolePrototype`, `/SecurityEvent` | both 200 | **PASS** |
| C6 review → two task buckets + closure each | `GET /api/security/observe/review?role=journalist` | `tasks` = 3 buckets: `publish an article` (acts 3, usages 3, would_deny_today 2, objects PolariAppDefinition/RolePrototype/UserAppPreference ×1), `score a source` (acts 2, objects RolePrototype/SecurityEvent ×1), and the unattributed `''` bucket (acts 0). **Each carries its own full `closure`** with `reading`, `coverage`, `not_traced` | **PASS** |
| C7 verify names the TASKS | `GET /api/security/observe/verify?role=journalist&group=journalist` | `tasks_broken: ["publish an article","score a source"]`; `tasks_verdict: "2 task(s) would BREAK under this profile: 'publish an article', 'score a source'"`; per-task `allowed`/`denied`/`breaks`/`reading` (e.g. *"the task 'publish an article' would BREAK: 2 of 3 recorded class × verb act(s) would now be denied (RolePrototype:read, UserAppPreference:read)"*) | **PASS** |
| C8 rows did **not** multiply | `GET /PermissionObservation` before/after | 9 rows → 13 rows. The 5 acts across 2 tasks produced **4** new rows (one per distinct `groups\|class\|verb`), and the row touched by both tasks is ONE row naming both: `…roleplay:journalist…\|RolePrototype\|read` → `tasks_json {"publish an article": 1, "score a source": 1}`, `count 2` | **PASS** |
| C9 **restart check** | DB verified, restart 03:26:16 → all-online 03:28:40 | `ObservationSession journalist\|2026-09-19T03:25:23Z` keeps `task "score a source"` and the full `tasks_json` history; all 4 observation rows keep their `tasks_json` and counts | **PASS** |
| C10 a session open across the restart still attributes | read `/SecurityEvent` as journalist after the restart | the row's `tasks_json` went `{"score a source": 1}` → `{"score a source": 2}` | **PASS** |
| C11 end the session | `DELETE /api/security/observe/session?role=journalist` | `{"ok": true, "ended": ["journalist\|2026-09-19T03:25:23Z"]}` | **PASS** |

### N-5 — `/api/security/observations` does not project `tasks_json`

The ct-7 column is on the row and correct (proved above through `GET /PermissionObservation`), but the security door reports it as `null` for every row:

```
/api/security/observations : …|RolePrototype|read  | count 2 | tasks_json None
/PermissionObservation      : …|RolePrototype|read  -> '{"publish an article": 1, "score a source": 1}' | count 2
```

Cosmetic, but it means the ct-7 answer is invisible on the one door named for observations.

---

### D. §68 frontend half

| step | request | result | verdict |
|---|---|---|---|
| D1 served bundle | `curl $FE/` → `main.a2f1460ff4a92e46.js` (5,194,984 B) | contains `X-Polari-Permission-Advisory` ×2, `Security advisory (dev)` ×1, `X-Polari-Owner-Advisory` ×1, `X-Polari-Traffic-Advisory` ×1, `X-Polari-Auth` ×1, `polariNotice` ×1, `permission-advisory` ×1, `connectHeaders` ×23 | **PASS** |
| D2a ws path | `.generated/nginx.lean.conf` `map $http_upgrade $prf_api_target { default http://prf-backend:3000; websocket http://prf-backend:3001; }` + `stompWebSocketServer.py` `port=3001` | the socket is `wss://api.prf.<D>/` on **any** path — the Upgrade header alone routes it | **PASS** |
| D2b STOMP CONNECT with a bearer | python3 `websockets` 13.1, raw STOMP frames, demo-viewer token on the CONNECT frame | `CONNECTED\nversion:1.2\nserver:polari-stomp/1.0\nheart-beat:0,0` | **PASS** |
| D2c SUBSCRIBE to a class outside the profile | `SUBSCRIBE /topic/AppPermissionProfile` | `MESSAGE` with `X-Polari-Permission-Advisory: would-deny AppPermissionProfile:read`, `message-id: permission-advisory`, body `{"polariNotice": "permission-advisory", "className": "AppPermissionProfile", "verb": "events", "derivedFrom": "read", "mode": "advisory", "authenticated": true, "verdict": {"allowed": false, "why": "no granted profile covers AppPermissionProfile:read …"}}` | **PASS** |
| D2d backend says `identity <sub>` | `docker logs … \| grep "STOMP protocol"` | `[STOMP] Client afb7e363 connected (STOMP protocol, identity 820f970b-5578-442a-bdf4-fac357509c9b)` — demo-viewer's sub, **not** anonymous | **PASS** |
| D2e anonymous control | same probe, no Authorization header | `[STOMP] Client ff9767c8 connected (STOMP protocol, identity anonymous)` and the frame changes to `X-Polari-Permission-Advisory: unauthenticated AppPermissionProfile:read`, body `"authenticated": false`, `"auth": "no-token"` | **PASS** |
| D3 headers exposed through nginx | `curl -D - -H "Origin: https://prf.<D>" $API/api/health` | `access-control-expose-headers: X-Polari-Auth, X-Polari-Permission-Advisory, X-Polari-Owner-Advisory, X-Polari-Traffic-Advisory`; also `access-control-allow-origin: https://prf.<D>`, `access-control-allow-credentials: true`. All four survive the nginx hop — this closes §68 OWED item 5 | **PASS** |

Also observed live: `X-Polari-Traffic-Advisory: would-deny outbound keycloak:Polari` on `GET /api/security/people/<sub>` — a real ct-9 advisory header on a real response.

**Not run:** §68 OWED items 1 (sign-out reload), 2 (the 60-second no-refetch negative), 3 (light/dark amber-vs-blue), 4 (`enforce` flip + ERROR frame + 60 s fallback tick), 6 (expired-token reconnect). All six need a browser with devtools and a person; I have no browser on this box and the negative ("does not refetch in 60 s") cannot be shown from curl.

---

### E. op-1 / op-2 / op-4 (§69 OWED)

| step | request | result | verdict |
|---|---|---|---|
| E1 the manifest declaration, no admin door touched | `GET /api/security/owned` | `manifest.declared: [{module: polariapps, class: UserAppPreference, duplicate_of: ""}]`; `manifest.converge: {created: [], updated: [], kept: ["UserAppPreference"], conflicts: [], duplicates: []}`; the policy reads `source: **manifest**`, `derived_from: polariapps`, `owner_field: sub`, `owner_verbs [read,update,delete]`, `others_verbs []` | **PASS** |
| E2 exactly ONE row after restarts | same, after 3 forced restarts | still one `UserAppPreference` policy, `kept` (converged in place, never doubled) — the seeded-row case §69 flagged as the risky one | **PASS** |
| E3 a `UserAppPreference` row exists | `GET /api/apps/mine` as demo-journalist, then `GET /UserAppPreference` | one row, `id Qp11Da7u5z`, `sub 589384ad-…` (the journalist's sub, D18-1: sub only) | **PASS** |
| E4 `sharing.table` on the per-instance door | `GET /api/security/owned/UserAppPreference/Qp11Da7u5z` as the owner | `sharing` carries `ok/class/id/owned/show_tab/you_may_share/why/grants/yours/bounds/table/how`; `table` is a complete `class-rows-table` item: `className OwnerGrant`, `filterField object_id`, `filterValue Qp11Da7u5z`, `columnFormats granted_by:person,grantee_sub:person` | **PASS** |
| E5 the grants door refuses, naming the bound | `POST …/UserAppPreference/<id>/grants` as the owner | **403** — `"UserAppPreference does not allow per-instance sharing: OwnedClassPolicy[UserAppPreference].owner_may_grant is false (a ballot is the design's example of a class that never has a grant)"`; `show_tab false`, `you_may_share false` | **PASS** |
| E6 transfer refused (`transfer: nobody`) | `POST …/UserAppPreference/<id>/transfer` | `"OwnedClassPolicy[UserAppPreference].transfer is \`nobody\` — this class's instances never change hands. An administrator may set it to \`admin\` or \`owner\`."` | **PASS** |
| E7 throwaway policy that allows grants | `POST /api/security/owned/TraceTarget {enabled, owner_field: started_by, owner_may_grant: true, grantable_verbs: ["read"], grantee_kinds: ["person"]}` as admin | 200, `source: **admin**`; a later `GET /api/security/owned` shows `manifest.converge.conflicts: []` (nothing declares TraceTarget) and the admin row untouched | **PASS** |
| E8 before the grant | `GET /api/security/owned/TraceTarget/MUste2hgr` as demo-viewer | `you_are_the_owner false`, `may []`, `fields_you_see null` | **PASS** |
| E9 the owner grants read | `POST …/TraceTarget/MUste2hgr/grants {grantee_kind: person, grantee: <viewer sub>, verbs: [read], fields: [name, class_name]}` | 200 `created: true`, grant `gOkABdJAt`, `name TraceTarget\|MUste2hgr\|person\|820f970b-…`, `grantee_sub` holds the sub and `grantee_group` is empty (gotcha 1 honoured) | **PASS** |
| E10 the grantee's read carries no advisory | `GET …/TraceTarget/MUste2hgr` as demo-viewer | **no `X-Polari-Owner-Advisory` header**; `may ["read"]`, `fields_you_see ["name","class_name"]`, verdict `rule: "grant:gOkABdJAt"`, why *"…an OwnerGrant the owner made … allows read, and a read is projected to ['name','class_name'] (the owner column is dropped)"* | **PASS** |
| E11 nobody else gains anything | same read as demo-journalist | `may []`, `fields_you_see null` | **PASS** |
| E12 a past `valid_until` is rejected | grant with `valid_until: 2020-01-01T00:00:00Z` | **400** — `"valid_until '2020-01-01T00:00:00Z' is already in the past — that is a revoke, not a grant"`, and the live grant is untouched | **PASS** |
| E13 the other bounds | grant to self; grant `delete` | `"a grant to YOURSELF is the owner floor written down twice — you already hold owner_verbs ['read','update','delete'] on your own rows"`; `"verbs delete are not in OwnedClassPolicy[TraceTarget].grantable_verbs ['read'] — an owner may only share what the class made shareable"` | **PASS** |
| E14 DELETE revokes | `DELETE …/grants?grantee_kind=person&grantee=<sub>` | 200; viewer's read is back to `may []`, `fields_you_see null`; a second DELETE is **404** `"no such grant on TraceTarget MUste2hgr"` | **PASS** |
| E15 anonymised normalises at the read | `POST /api/security/owned/TraceTarget {anonymised: true, transfer: "owner", owner_visible: true}` | comes back `anonymised true`, **`owner_visible false`**, **`transfer "nobody"`**, `transfer_declared "owner"` — the contradiction is kept visible, not erased | **PASS** |
| E16 transfer on an anonymised class refused | `POST …/TraceTarget/MUste2hgr/transfer {"to": <sub>}` | **403** — `"TraceTarget is an ANONYMISED class: its owner is never transferred. A transfer names the old owner and the new one in one act, which is exactly what anonymised exists to prevent (design §8)."` | **PASS** |
| E17 `sharing.table` on a shareable class | `GET …/TraceTarget/MUste2hgr` as the owner while granted | `show_tab true`, `you_may_share true`, `grants 1`, `table.filterValue MUste2hgr`, `columnFormats granted_by:person,grantee_sub:person` | **PASS** |
| E18 the two pages answer 200 | `GET https://prf.<D>/display/security-owned`, `…/security-objects` | both **200** | **PASS** |
| E19 the display door lists them | `GET $API/DisplayDefinition` | both present as `name`+`pageRoute`; `security-objects` = **8 rows** (`api-structured-panel` ×11, `class-rows-table` ×2), `security-owned` = **6 rows** (`api-structured-panel` ×4, `class-rows-table` ×3). **No `api-json-panel`, no raw-JSON panel on either** | **PASS** |

### Cleanup performed

- `OwnedClassPolicy[TraceTarget]` — **there is no delete door** (`DELETE /api/security/owned/TraceTarget` → **405 Method Not Allowed**), so I set it `enabled: false` with every field cleared and the note *"THROWAWAY from live proof round 5 — DISABLED after the proof"*. It reads `TraceTarget | enabled False | source admin` in the listing; `UserAppPreference` is untouched and still `enabled True / source manifest`.
- The `OwnerGrant` row `gOkABdJAt` was revoked; `GET /OwnerGrant` carries no `TraceTarget|` row.
- The trace target is disarmed (`armed: false`).
- The role-play session was ended.

**N-6 — an `OwnedClassPolicy` cannot be removed.** The door offers `POST` only; `DELETE` is 405. A throwaway or mistaken opt-in is permanent (disable-only), and the disabled row stays in `GET /api/security/owned`'s `count`. §69's own OWED step 2 ("opt a real class in…") has no stated way back out.

**Not run from §69's OWED:** steps 2–4 as written (they need a `MealPlan` class, which this lean stack does not carry — I substituted `TraceTarget`, which covers the same doors but is not a domain row); step 3's *wall-clock* expiry (a live grant dying on the clock — only the past-`valid_until` door refusal and the `match()` bound were exercised); step 5's anonymised STOMP broadcast (`instanceIds: []` on a create) and the anonymised trace-journal row; step 6 the browser pass; step 7 the Sharing-tab host (still absent by design).

---

### F. The site

| step | request | result | verdict |
|---|---|---|---|
| F1 the page answers | `GET https://<lan>.nip.io/docs/app-security.html` | **200**, 35,398 bytes, contains `Application security` (3 occurrences) | **PASS** |
| F2 the sidebar links it | `GET …/docs/security.html` | **200**; line 66: `<a href="docs/app-security.html">Application security</a>`; the layer table and the status blockquote both link `app-security.html` | **PASS** |

---

### Defects, in priority order

1. **D-1 (hard, ct-9 durability).** A person-confirmed `InboundPolicy` ruling does not survive a backend restart, and a second inbound row is deleted outright. Reproduced twice with the DB verified `confirmed` beforehand and stable for 200 s under observation. `OutboundPolicy`, `SecurityDecision`, `PermissionObservation` and `ObservationSession` all survive the same restart, so the exemption and the merge work — `InboundPolicy` alone is lost. Evidence points to the §66a/§66b boot-time inbound flush persisting its `suggested` row before `restoreTables()` reads the table (`[DB] Restoring 1 instances of InboundPolicy` when the DB held 2; the restored row's `count` equals this boot's request count). **§66 addendum 5 is not closed.**
2. **D-2 (privacy).** The `objects` topology view prints the confirmed origin's URL — `external:origin:https://prf.<lan>.nip.io` — as a node title, an edge target, a drift entry and a summary row, contradicting the view's own description, the §67 selftest claim, and the standing no-real-identifiers rule.
3. **N-6.** `OwnedClassPolicy` has no delete door (405); an opt-in is disable-only and permanent.
4. **N-5.** `/api/security/observations` reports `tasks_json: null` although the row carries it.
5. **N-3.** `app.flows:security` names keycloak `realm` while the real traffic is `Polari` — two nodes for one system; the declaration can never match, and under `enforce` the declared one reads `blocked`.
6. **N-4.** A person-confirmed *inbound* flow can never read `allowed` on the objects view, because `app.flows` has no inbound vocabulary so the `app-flows` step always logs a finding first.

### Could not run, and why

| item | why |
|---|---|
| §67 OWED step 2–3 (an **observed** flow edge, `observed_not_declared`) | `record_edge` no-ops unless the request's chain is already traced, and `outbound.py` never calls `touch`. No door on this instance both passes the CRUDE gate for an armable class and then sends outbound. See N-2. |
| §67 OWED step 5 (`coverage: none` + populated `not_traced`) | every declaration on this instance carries `classes: []`, so the branch is unreachable. See N-1. |
| §68 OWED 1, 2, 3, 4, 6 (browser pass) | need a browser with devtools and a person: the signed-out reload, the 60-second **no-refetch** negative, amber-vs-blue in light and dark, the `enforce` flip with its ERROR frame and fallback tick, and the expired-token reconnect. No browser on this box; the key checks are negatives that curl cannot show. |
| §69 OWED 2–4 exactly as written | `MealPlan` is not on this lean stack; substituted `TraceTarget` (same doors, not a domain row). |
| §69 OWED 3 wall-clock expiry | only the door-level past-`valid_until` refusal was exercised, not a live grant dying on the clock. |
| §69 OWED 5 (anonymised broadcast / journal) | needs a create on an anonymised class with a STOMP client attached and a TraceTarget armed on it; not attempted to avoid writing domain rows on the shared stack. |
| §69 OWED 6–7 (browser pass, Sharing-tab host) | needs a browser; the per-instance host does not exist yet by design. |

### Residual state left on the stack (nothing tracked was written)

- `OutboundPolicy keycloak|Polari|rest` is now **confirmed** by demo-admin (needed for B9). The door offers `confirmed|denied` only, so there is no way back to `suggested`; the stack is in `advisory`, so nothing is enforced.
- `InboundPolicy anonymous|anonymous` is `suggested` (my three confirmations were each lost to D-1).
- `OwnedClassPolicy[TraceTarget]` exists with `enabled: false` (no delete door).
- Three `TraceTarget` rows (AppPermissionProfile, UserAppPreference, RolePrototype), all inactive.
- `PermissionObservation` gained four `roleplay:journalist` rows; the role-play `ObservationSession` is ended.
- demo-admin was passed through `DELETE /api/security/roles/claim?role=journalist` twice (to drive a keycloak send). It was never in that group — `held: []` before and after — so group membership is unchanged.
- Stack final state: `phase online`, 6/6 modules, `mode advisory`, `posture dev`, trace disarmed, `git status` clean.

### §66 addendum 6 — D-1: the persist that beat the restore (2026-09-19, root-caused, fixed, selftested)

The round-5 live proof (§A above) found the one hard defect: a person-confirmed `InboundPolicy` ruling does not
survive a restart, reproduced twice with the DB verified `confirmed` beforehand and stable for 200 s under
observation. `OutboundPolicy`, `SecurityDecision`, `PermissionObservation` and `ObservationSession` all survive
the same restart — so the §66 addendum 5 exemption and the §66e merge both work, and `InboundPolicy` alone is
lost. **This is not ct-9's bug and it is not the restore's; it is the PERSIST's.**

**The mechanism, with the code.** `persistTree` is DELETE + REPLACE per class: it snapshots `objectTables` and
rewrites each table from that snapshot (`objectTreeManagerDecorators.persistTree:1042` and its snapshot at `:1088`,
`_persistTreeAtomic` the prepare/write, `managedDB.writePreparedBatches` the DELETE+REPLACE). That is right
once the tree IS the tree, and catastrophic before it. The chain live:

1. `lazy_boot.run` Phase A (`lazy_boot.py:527`) calls `jumpstartDatabase(skip_restore_tables=feature_names)` —
   every **module-owned** table is DEFERRED, `InboundPolicy` among them, and restored later at admission
   (`lazy_boot._admit:636` → `restoreTables()` → `ensureDefinitionTables()`).
2. `polariServer.ensureDefinitionTables(only_classes=core_names)` finishes and sets
   `manager.definitionsRestored = True` (`polariServer.py:1772`). §66b's readiness flag now reads READY — for
   the CORE restore. `InboundPolicy` belongs to the **security module** and has not been read at all.
3. The swarm's anonymous health probe hits `/api/health` seconds into the boot. `TrafficPolicyMiddleware`
   → `security_traffic.inbound_verdict` → `tree_ready()` said True → `_observe_inbound` creates ONE `suggested`
   row and calls `_schedule_persist(manager)`.
4. Three seconds later (`persist_debounce.DEFAULT_DELAY`) `persistTree()` runs and rewrites the whole
   `InboundPolicy` table from the one boot-time row in memory. **The two rows on disk, a person's `confirmed`
   ruling among them, are gone before anything has read them.**
5. Security is admitted; `restoreTables()` reads the table and finds the ONE row the flush left
   (`[DB] Restoring 1 instances of InboundPolicy` for a table that held two at shutdown), and the merge
   reports `merged 0 persisted rows, 0 boot-time rows folded, 1 already restored` — there was nothing left to
   merge. The restored row's `count` is this boot's probe count and its `derived_from` still says
   *"observed before the tree was restored (boot-time; flushed at the first request — §66a/§66b)"*.

**Why `OutboundPolicy` differs, and it is only timing.** Nothing goes through `polariApiServer.outbound`'s
wrapper until an authenticated request reaches Keycloak, which is after admission; `security_traffic._PENDING`
parks the earlier boot-time sends (§66a) rather than writing them. So its table was never rewritten before its
restore. Same class family, same exemption, same merge — **the hazard is the write ordering, not the class**,
and it is live for any class an observer can touch during a lazy boot.

**The fix, at the core, in the smallest honest shape.** A persist never writes a class whose persisted rows this
process has not read back.

| built | where |
|---|---|
| `restoredClasses()` / `noteClassRestored()` — the classes this process HAS read back, `__dict__`-resident (the `_persistState` idiom, so it never becomes a typed attribute) | `objectTreeManagerDecorators.py:757-768` |
| `armRestoreTracking()` / `restoreTrackingArmed()` — armed by `restoreFromDatabase` and nowhere else, so a FRESH database and every manager double behave byte-for-byte as before | `objectTreeManagerDecorators.py:771-778`, armed at `:465` |
| `classesPendingRestore(names)` — of those names, the ones whose DB table still holds rows nobody has read. A table known to be EMPTY is cleared immediately (nothing to overwrite); a table that cannot be READ stays pending, because not knowing what is on disk is not a licence to replace it | `objectTreeManagerDecorators.py:780-818` |
| `persistTree` HOLDS BACK those classes, with one log line naming them and how many rows stayed in memory | `objectTreeManagerDecorators.py:1095-1119` (both the atomic and the legacy per-class paths inherit it, and a held-back class's tombstones are NOT cleared, because it was not rewritten) |
| both restore paths mark their decisions — read, deliberately declined (`constructor requires …, re-created at runtime`), or provably absent. The two branches that do NOT mark are a table whose class is not registered yet (that is what a definition class looks like to the main pass) and a read error | `objectTreeManagerDecorators._restoreTableRows:517-672`, `polariServer._restoreDefinitionInstances:1893-1918` |
| the ct-9 half: `tree_ready(manager, table)` is now PER CLASS — `definitionsRestored` is one flag for the core restore, and the policy tables are the security module's. The probe is PARKED for those few seconds and the parked count then lands ON the restored ruling through `_find` (§66d) instead of beside it | `security_traffic.tree_ready`, `_verdict`, `flush_pending`, `note_inbound_path` |

The bookkeeping degrades exactly like the §51 addendum 3 tombstones: `_managerPendingRestore` /
`_managerNoteRestored` swallow anything a double has not been taught, so the selftests that bind `persistTree`
and `_restoreTableRows` onto a `SimpleNamespace` keep their old behaviour.

**Selftests.** NEW `polariApiServer/selftest_persist_before_restore.py` **26/26** (**13/26** against the shipped
behaviour, with `classesPendingRestore` patched to answer "nothing" — the two confirmed rows are overwritten by
the boot-time row and the restore then loads only that row, which is the live defect exactly). A REAL
`managerObject` with a REAL `managedDatabase` over a temp sqlite file: the rows on disk are read back with plain
sqlite, so no double can flatter the result. It pins the live sequence end to end (confirm → restart → four
probes with a flush each → restore → flush: both rulings intact, the second inbound row not deleted) and the
four bounds — a fresh database is never held back, an empty table is not held back, an unreadable table IS, a
class with no table at all is not, one held-back class never stalls the others, and a held-back class keeps its
tombstones. Regression: `selftest_restore_merge` **17/17**, `selftest_restore_from_database` **25/25** (its
`FakeManager` now binds the five new real methods, so the marking under test is real),
`selftest_persist_debounce` **13/13**, `selftest_persist_tombstones` **43/43**, `selftest_quiesce` **27/27**,
`selftest_crude_delete_blast` **21/21**, `selftest_persist_atomic` **21/21**, `selftest_batched_persist`
**17/17**, `selftest_lazy_boot` 33/34 (the pre-existing manifest-drift pin). Security selftest +2 ct-9 checks
(the per-class hold, and that it is per class rather than a boot-wide stop).

**What a live re-proof must check.** Redeploy, then:
1. The boot log carries `[DB] Persist HELD BACK for N classes whose persisted rows this process has not
   restored yet (…)` naming `InboundPolicy` — that line IS the fix working, and its absence on a warm boot
   means nothing raced the restore this time, not that the guard is off.
2. `[DB] Restoring N instances of InboundPolicy` where N is what sqlite held at shutdown (two, not one).
3. Confirm BOTH inbound rows (`anonymous|anonymous` and the origin row) through the body door, verify them in
   `/app/data/managerObject_DB.db` with sqlite, wait past the debounce, `docker service update --force`, and
   re-read: both still `confirmed`, one row per name, the confirmer and timestamp intact, and the count equal
   to persisted + this boot's probes rather than this boot's alone.
4. The *second* restart (the live proof lost the origin row outright on every one) — it must still be there.
5. `OutboundPolicy`, `SecurityDecision`, `PermissionObservation`, `ObservationSession` unchanged: the guard
   must not have stopped anything persisting. Check `GET /api/apps/security/coverage?app=app-policy` reads the
   same before and after, and that new rows written after boot DO reach sqlite.
6. Nothing in the log says a class stayed held back after its module came online — a class that is still
   pending once `phase: online` is reported would be a class that never persists again, and that is the one
   way this fix could hurt.

---

### §67 addendum — D-2 and the objects-view findings (2026-09-19, fixed, selftested)

**D-2 (privacy) — the view printed a hostname, contrary to its own contract.** Once an `origin` `InboundPolicy`
row is confirmed — the normal outcome of a browser using the stack — `external:origin:https://prf.<lan>.nip.io`
appeared as a node, a node TITLE, an edge target, a drift entry and a summary row, while the view's own
`description` promises *"no hostname and no address appears on this view"* and §67 lists that among its
selftested checks. On a nip.io host that string is a hostname **and** the LAN address it encodes. The selftest
could not have caught it: its declared sources carried no origin row at all.

The row itself is right to hold `scheme://host` — a person confirming a source has to tell one browser origin
from another, and that door is behind an admin bearer. This VIEW is not that door. So the origin is rendered at
the only resolution a topology needs:

| built | where |
|---|---|
| `own_origins()` — the hosts this deployment calls its own, from `api.cors_origins` (the CORS allow-list IS the statement "these front ends are mine"), plus `frontend.url` / `backend.url`. Cached per process; an instance that configures none calls every origin `other`, which is the safe answer | `security_objects_view.py` |
| `coarsen_source(kind, name)` — an `origin` becomes `<scheme>:this-instance` or `<scheme>:other`; a shape it cannot read becomes `other`; every other source kind is already a NAME or a CLASS (a `PeerNode` name, `anonymous`, `ip-literal`) and passes through untouched | same |
| applied where the flow is BUILT (`policy_flows`), so the node, the title, the edge target, the drift entry and the summary row are all coarse by construction rather than by five separate scrubs | same |
| the state lookup no longer needs the exact name: `declared_flows()` emits CONFIRMED inbound rows and nothing else, so the state is known without it (the raw source is therefore not carried through the view at all, and `/api/security/objects/flows` cannot leak it either) | `build()` |

The exact origin stays where a person rules on it: `GET /api/security/traffic` and `/traffic/declared`, signed
in. The view's `description`, its `this instance` node and `HOW_OBJECTS` all say so now instead of promising
something they did not deliver.

**N-3 — the manifest's keycloak and the real keycloak were two nodes.** `app.flows:security` declared
`name: "realm"` while the traffic is named `Polari`, so `external:keycloak:realm` stood beside
`external:keycloak:Polari`, the declared one read **blocked** under enforce, and `declared_not_observed`
listed it as *DECLARED, NEVER OBSERVED* for ever. A manifest speaks at system-KIND level by design — an app
author cannot know which realm a deployment runs — so the `name` is dropped from the declaration
(`modules/security/polari-app.json`; `odooconnect` already had none) and `build()` matches a declaration with
NO name against every system of that kind the instance really talks to. One node, carrying both statements.

**N-4 — a confirmed inbound flow could never read `allowed`.** `app.flows` is an OUTBOUND vocabulary (design
§9), so no module can ever declare who may CALL a deployment; the `app-flows` chain step therefore logged a
finding first and every person-confirmed inbound edge read `logged` under enforce. Design §7 counts *"a traffic
policy a person confirmed"* as a declaration in its own right, and for an inbound flow it is the only one there
can be — so a confirmed `InboundPolicy` IS the declared side for its own edge, and the chain step says exactly
that instead of reporting a finding nobody could ever answer.

**N-5 — `/api/security/observations` reported `tasks_json: null`.** The column was on the row and the CRUDE
listing showed it; `OBS_KEYS` (and `USAGE_KEYS`) simply left it out of the projection the door sends. Both now
carry `tasks_json` beside the parsed `tasks` map.

**N-2 — the observed half of the objects view was unreachable.** `record_edge` no-ops unless the chain is
already traced (`security_trace.py:464-475`), a chain becomes traced only where `touch` is called, and `touch`
lived at the CRUDE gate, the STOMP gate, the dispatcher, the transport mux and remote hydration — none of which
an outbound send passes (`outbound.py:132` imports `record_outbound` and not `touch`). So an observed external
edge needed one request that BOTH passed the gate for an armed class AND sent outbound, and no door did both:
`/api/security/people/{sub}` reads no Polari class, and the claim doors read `RolePrototype` **directly**, not
through CRUDE. `security_claims.trace_prototype_read()` is that seam, in the same shape as the CRUDE gate's —
touch first (the scope rule decides), then record the endpoint → object edge — called from `claimable_roles`
and `may_claim`, so a claim or release with `RolePrototype` armed records the keycloak edge and the observed
half becomes provable with a single request.

**Selftests.** `modules/security/security_selftest.py` **296/299** (from 283/286; +13 checks, the same 3 known
environment failures — ledger `mac_enforced`, the two live MAC-profile reads, the expired-cert probe). The new
checks: `coarsen_source`'s six cases; a fixture carrying TWO confirmed origin rows (one of this instance's own
hosts, one a nip.io host with an address in it) and the whole of `build` / `drift` / `simulate` / `compare`
walked RECURSIVELY for anything host-like or IP-like — the live defect was in five places at once and a spot
check on two of them would have passed; that the traffic door still carries the exact origin; N-3's one
keycloak node with the manifest's `app-flows` step reading `allowed` on it; N-4's confirmed inbound edge
reading `allowed` under enforce with the reason named; N-5's `tasks_json` on both projections; N-2's armed
`RolePrototype` claim recording both the endpoint edge and the keycloak flow, with `drift.counts.observed` ≥ 1.
Regression: `selftest_manifests` **8/8**, `manifests conform --all` **61/61**, `apps_selftest` **125/125**,
`selftest_outbound` **61/61**, `selftest_cause_context` **41/41**, `selftest_stomp_gate` **41/41**,
`selftest_refs` **51/51**, `import polariApiServer.polariServer` clean.

**What a live re-proof must check.**
1. Confirm an `origin|https://prf.<lan>.nip.io` row, then `GET /api/security/topology?view=objects`,
   `/api/security/objects/drift`, `/api/security/objects/flows`, `?view=objects&mode=enforce` and the compare
   door — grep every response for the host, for `nip.io`, for `://` and for a dotted quad. Nothing.
   The node must read `external:origin:https:other` (or `:this-instance` if the origin is the stack's own
   frontend, which on `polari-lean` it is — `CORS_ORIGINS` names it, so expect `this-instance` there).
2. `GET /api/security/traffic` still shows the exact origin for the same row.
3. `?view=objects` shows ONE `external:keycloak:Polari` node and no `external:keycloak:realm`; under
   `mode=enforce` its `app-flows` step reads `allowed` and `declared_not_observed` no longer names `realm`.
4. Confirm an inbound row, re-read `?view=objects&mode=enforce`: that edge reads **allowed**, and the
   `app-flows` step's note names the confirmed `InboundPolicy` rather than a finding.
5. `GET /api/security/observations` carries `tasks_json` for every row, matching `GET /PermissionObservation`.
6. §67 OWED step 2, now runnable: `POST /api/security/observe/trace {"class_name": "RolePrototype"}`, then
   `DELETE /api/security/roles/claim?role=journalist`, then re-read the trace target and the objects view —
   `traces_opened ≥ 1`, `edges_written ≥ 2`, an OBSERVED `keycloak` edge, and `drift.counts.observed` ≥ 1.
   Disarm afterwards.

---

### §69 addendum — N-6: an `OwnedClassPolicy` can be removed (2026-09-19, fixed, selftested)

The live proof's cleanup could not clean up: `DELETE /api/security/owned/{class}` was **405**, the door offered
`POST` only, and the best a person could do with a throwaway opt-in was set `enabled: false` — leaving the row
in `GET /api/security/owned`'s `count` for ever. §69's own OWED step 2 ("opt a real class in…") had no stated
way back out.

| built | where |
|---|---|
| `delete_policy(manager, class_name, by=)` — removes the row, tombstoned through `noteTreeDeletion` so a persist in flight cannot write it back, and ledgered as a `SecurityEvent` like every other owner-policy act | `modules/security/custom/security_owned.py` |
| `DELETE /api/security/owned/{class_name}` (ADMIN_ROLES, like the POST: removing a policy changes what every caller may do to every instance, exactly as setting one does) | `security_api.on_delete_owned_class` |
| the refusal that matters: **409** for a class a manifest still declares, naming the module and the act that really removes it — op-4 converges `app.owned` into a row on every read of `GET /api/security/owned`, so a delete here would look like it worked and come straight back | same |

404 for a class nobody opted in; 403 for a non-admin. The falcon `suffix=` gotcha is covered by the §54 route
guard, extended to assert the class door answers all three verbs — a suffix whose responder is missing raises
out of `add_route()` and takes the backend down at boot.

**Selftests.** +4 checks in `_owned_checks` (the 403, the 404, the 409 with the manifest-declared class still
present afterwards, and a real removal of an admin-set throwaway that leaves `policies()` and `policy_for()`
agreeing it is gone) plus the extended route guard. Whole suite **296/299** as above.

**What a live re-proof must check.** `POST /api/security/owned/TraceTarget {…}` → `DELETE
/api/security/owned/TraceTarget` → 200 and `GET /api/security/owned` no longer counts it; then `DELETE
/api/security/owned/UserAppPreference` → **409** naming `polariapps` and `app.owned`, with the policy still
present and still `source: manifest`. And a restart afterwards: the removed row must not come back from the
database.

## §66 addendum 6 + §67/§69 addenda — targeted live re-proof after the ninth deploy (2026-09-19, framework `ec1f5f7`, posture dev, gate advisory)

_Report by the re-proof agent, verbatim but with the home stack's address written `<lan>`. D-1 and D-2 are CLOSED live; the three "secondary observations" at the end are OWED (the `SecurityDecision` inbound mirror lags the confirmed rows and its names embed the exact origin URL; observed edges carry `declared_by: ""`; the objects view's `traced` flag keys on a different class set than the flow)._

### The report

- Date: 2026-09-19, 04:06–04:19 UTC
- Stack: swarm `polari-lean`, posture **dev**, gate **advisory**
- Pin verified live: `polari-rf-node/polari-framework` = **ec1f5f7** (`ec1f5f7b07330d762de88aca50b7270caf60968f` — *"§66 addendum 6 core + §67/§69 addenda: a persist never rewrites a class whose persisted rows it has not read yet; the objects view coarsens origins; the live-proof minors"*)
- Health at start: `phase online`, `onlineCount 6 / moduleCount 6`, `secondsToFull 129.064`
- No tracked file edited, nothing committed, no image rebuilt. `git status` clean at the end.
- Two forced backend restarts (`docker service update --force polari-lean_prf-backend`).
- Every persistence claim read out of `/app/data/managerObject_DB.db` inside the running container with plain sqlite (read-only URI), not inferred from the API.
- `docker service logs` hangs on this swarm (confirmed again) — all log reads via `docker logs <container>`.

**Headline: every checked item passes. D-1 is CLOSED, D-2 is CLOSED, all five minors pass.** Three secondary observations recorded below (none is a regression; none blocks).

---

### 1. D-1 — the confirmed `InboundPolicy` ruling now survives a restart (§66 addendum 6)

### The boot-log evidence

The new addendum-6 line is present on **all three** boots inspected (deploy boot, restart 1, restart 2), at line 1698 each time, immediately after the CRUDE endpoint registration and before the first `SELECT * FROM …`:

```
[DB] Deferred restore of 62 module-owned tables (lazy boot — restored at admission). Until each one is restored a persist will NOT rewrite it (§66 addendum 6)
```

The `[DB] Persist HELD BACK for N classes …` line did **not** appear on any boot. Per the ledger's own reading ("its absence on a warm boot means nothing raced the restore this time, not that the guard is off") this is the expected outcome — and the log proves *why* nothing raced it: on every boot the only `[DB] Persisted …` lines come **after** the restore.

| boot | restore line # | first persist line # |
|---|---|---|
| deploy (04:05:58) | 19490 | 20675 |
| restart 1 (04:12:58) | 20261 | 21458 |
| restart 2 (04:16:37) | 21039 | (after restore) |

So the ct-9 half of the fix (per-class `tree_ready`, probe parked) is what is carrying the load live; the `classesPendingRestore` hold-back is the belt behind it and was not needed on a warm boot.

### The restore counts

| step | request | result | verdict |
|---|---|---|---|
| D1-a | `docker logs` boot-0, grep restore | `[DB] Restoring 1 instances of InboundPolicy` — sqlite at that moment held **1** row (the previous run's residue; the origin row had been lost to the old defect). N matches disk | **PASS** |
| D1-b | boot-1 (after restart 1) | `[DB] Restoring 2 instances of InboundPolicy` / `[DefRestore] InboundPolicy: merged 0 persisted rows, 0 boot-time rows folded, 2 already restored` — disk held **2**. *This is the line that read `1` in round 5 and is the headline fix* | **PASS** |
| D1-c | boot-2 (after restart 2) | `[DB] Restoring 2 instances of InboundPolicy`, `[DefRestore] … 2 already restored` | **PASS** |
| D1-d | `grep -c "LazyBoot.*FAILED"` / `grep -c "dictionary changed size"` on boot-1 and boot-2 | **0 / 0** on both | **PASS** |
| D1-e | nothing still held back once `phase: online` | no hold-back line on any boot, and every module reaches `online` (6/6) | **PASS** |

### The rulings

| step | request | result | verdict |
|---|---|---|---|
| D1-1 | `GET /api/security/traffic` (demo-admin) | only `anonymous\|anonymous` (suggested, count 164). The origin row was gone | (expected) |
| D1-2 | 3 × `GET /api/health` with `Origin: https://prf.<lan>.nip.io` | `origin\|https://prf.<lan>.nip.io` appears, `suggested`, count 3 | **PASS** |
| D1-3 | `POST /api/security/traffic/inbound {"name":"anonymous\|anonymous","decision":"confirmed"}` | 200, `state confirmed`, `confirmed_by 5cacba59-a133-4663-9181-c32cb861a9c6`, `confirmed_at 2026-09-19T04:09:21Z` | **PASS** |
| D1-4 | same for `origin\|https://prf.<lan>.nip.io` (body door — the `/{name}` path form cannot carry `://`) | 200, `state confirmed`, same confirmer/timestamp | **PASS** |
| D1-5 | sqlite 9 s later | `('anonymous\|anonymous','confirmed','5cacba59-…','2026-09-19T04:09:21Z',167,…)` and `('origin\|https://prf.…','confirmed','5cacba59-…','2026-09-19T04:09:21Z',3,…)` | **PASS** |
| D1-6 | wait 102 s (04:09:21 → 04:11:03), re-read sqlite | both still `confirmed`, counts 182 / 3 | **PASS** |
| D1-7 | **restart #1** 04:11:07 → all-online 04:13:43; sqlite + API | sqlite `('anonymous\|anonymous','confirmed','5cacba59-…','04:09:21',201)` and `('origin\|https://prf.…','confirmed','5cacba59-…','04:09:21',3)`. API agrees (`confirmed`, count 202/3). **One row per name.** Count 182 → 201 = persisted 182 + this boot's 19 probes folded onto the SAME row (`first_seen` still `03:27:54`, i.e. the persisted row, not a fresh one) | **PASS** |
| D1-8 | **restart #2** 04:14:42 → all-online 04:17:32; sqlite + API | sqlite `('anonymous\|anonymous','confirmed','5cacba59-…','04:09:21',225)`, `('origin\|…','confirmed','5cacba59-…','04:09:21',3)`. API: `confirmed` / count 228 / 3. One row per name, confirmer and `confirmed_at` intact across both restarts | **PASS** |
| D1-9 | `OutboundPolicy keycloak\|Polari\|rest` throughout | `('keycloak\|Polari\|rest','confirmed','5cacba59-…','2026-09-19T03:24:35Z',12,…)` byte-identical before, between and after both restarts — the guard stopped nothing persisting | **PASS** |
| D1-10 | `GET /api/apps/security/coverage?app=app-policy` before / after restart 1 / after restart 2 | `{open 432, suggested 4, confirmed 2, denied 0, inherited 0, stale 0}` — **identical all three times** | **PASS** |
| D1-11 | other exempt classes restored | boot-1: `Restoring 19 instances of PermissionObservation`, `3 instances of ObservationSession`, `1 instances of OwnedClassPolicy`, `1 instances of OutboundPolicy`; boot-2 the same | **PASS** |

**D-1 verdict: CLOSED.** Reproduced in the positive direction twice. The one hard defect of round 5 is gone.

---

### 2. D-2 — the objects view no longer prints a hostname (§67 addendum)

Driven with an `origin|https://prf.<lan>.nip.io` row **confirmed** (the exact condition that leaked in round 5).

Scrub method: each response parsed as JSON and walked **recursively** over every dict key, dict value, list element and nested string, matching `192\.168`, `nip\.io`, `\bprf\.`, `https?://<host-char>`, and a bare dotted quad.

| step | request | result | verdict |
|---|---|---|---|
| D2-1 | `GET /api/security/topology?view=objects` (19,330 B) | **0 hits** | **PASS** |
| D2-2 | `GET /api/security/objects/drift` | **0 hits** | **PASS** |
| D2-3 | `GET /api/security/objects/flows` | **0 hits** | **PASS** |
| D2-4 | `GET /api/security/simulate?view=objects&actor=this%20instance` | **0 hits** | **PASS** |
| D2-5 | `GET /api/security/compare?view=objects` | **0 hits** | **PASS** |
| D2-6 | the origin flow's rendering | node / title / edge target / compare / simulate all read **`external:origin:https:this-instance`** — the expected `this-instance` (this stack's `CORS_ORIGINS` names its own frontend) | **PASS** |
| D2-7 | the view says so in words | topology `description` now contains *"… and neither does a hostname: an inbound origin reads …"* | **PASS** |
| D2-8 | re-scrub AFTER the observed keycloak flows existed (§e below) | all five doors **0 hits** again | **PASS** |
| D2-9 | the exact origin is still available where a person rules | `GET /api/security/traffic` → `origin\|https://prf.<lan>.nip.io \| confirmed \| count 3` | **PASS** |

**D-2 verdict: CLOSED.**

---

### 3. Minors

### (a) N-3 — one keycloak node, the declaration matches the observed system

| check | result | verdict |
|---|---|---|
| node list | exactly four externals: `external:anonymous:anonymous`, **`external:keycloak:Polari`**, `external:odoo`, `external:origin:https:this-instance`. **No `external:keycloak:realm`** — `grep -c "keycloak:realm\|\"realm\""` = **0** across all six objects-view responses | **PASS** |
| the manifest declaration's `name` | `declared_not_observed` entry for keycloak carries `name: ""` (the name was dropped from `app.flows:security`), so it matches any keycloak the instance talks to | **PASS** |
| `app-flows` chain step on the declaration edge, `mode=enforce` | `app-flows -> allowed \| "app.flows:security declares it"` | **PASS** |
| once the observed flow exists | `declared_not_observed` no longer lists keycloak at all (it is matched); `observed_not_declared` is `[]` | **PASS** |

Note: it is one NODE carrying two edges — `declared (both)` from `app.flows:security` and `rest (push)` from the confirmed `OutboundPolicy` — which is the shape the addendum describes ("one node, carrying both statements"). The declaration edge still reads `blocked` under enforce at the `traffic-policy` step (`"closed by default: only a CONFIRMED row allows, and this one is not proposed at all"`), which is the designed posture, not the N-3 symptom.

### (b) N-4 — a confirmed inbound flow reads `allowed` under enforce

`GET /api/security/topology?view=objects&mode=enforce` → `counts {allowed 3, logged 0, blocked 2}` (round 5 read `{allowed 1, logged 2, blocked 2}`).

Chain on `this instance -> external:anonymous:anonymous`:

```
app-flows        -> allowed  | InboundPolicy (confirmed by 5cacba59-…) IS the declaration for an inbound
                              flow: `app.flows` is an OUTBOUND vocabulary (design §9), so no module can
                              declare who may CALL a deployment — design §7 counts the traffic policy a
                              PERSON confirmed as the declaration instead
traffic-policy   -> allowed  | a person confirmed this flow
outbound-wrapper -> allowed  | the call passes the one wrapper …
causal-map       -> n/a      | NOT TRACED: no TraceTarget has ever been armed on these classes …
verdict: allowed
```

Same for `external:origin:https:this-instance`. **PASS** — the note names the confirmed `InboundPolicy` instead of a finding nobody could answer.

### (c) N-5 — `/api/security/observations` carries `tasks_json`

19 rows returned; **0 with `tasks_json: null`**. The three roleplay rows carry real maps, matching `GET /PermissionObservation`:

```
…roleplay:journalist…|RolePrototype|read   | count 2 | tasks_json '{"publish an article": 1, "score a source": 1}'
…roleplay:journalist…|SecurityEvent|read   | count 2 | tasks_json '{"score a source": 2}'
…roleplay:journalist…|…                    | count 1 | tasks_json '{"publish an article": 1}'
```

Non-roleplay rows carry `'{}'` (an empty map, not null) beside a parsed `tasks {}`. **PASS**

### (d) N-6 — an `OwnedClassPolicy` can be removed

| step | request | result | verdict |
|---|---|---|---|
| before | `GET /api/security/owned` | `count 2`: `TraceTarget \| enabled False \| source admin` (round 5's disabled throwaway), `UserAppPreference \| enabled True \| source manifest` | — |
| delete the throwaway | `DELETE /api/security/owned/TraceTarget` (admin) | **200** `{"ok": true, "removed": true, "class": "TraceTarget", "how": "the class is no longer owned: no owner is stamped on a create, the owner gate does not run for it, and any OwnerGrant rows it had are inert … POST /api/security/owned/TraceTarget opts it back in."}` | **PASS** |
| delete the manifest-declared class | `DELETE /api/security/owned/UserAppPreference` | **409** — *"UserAppPreference is DECLARED by the module **`polariapps`** in its **`app.owned`** stanza, and op-4 converges that declaration into a row on every read of GET /api/security/owned — deleting the row here would come straight back. Set `enabled: false` on the manifest entry, or remove the `app.owned` entry, and the declaration stops being made at all."* | **PASS** |
| after | `GET /api/security/owned` | `count 1`: `UserAppPreference \| enabled True \| source manifest` — untouched | **PASS** |
| does it come back? | after restart 1 **and** restart 2: sqlite `SELECT class_name,enabled,source FROM OwnedClassPolicy` → `[('UserAppPreference', 1, 'manifest')]`; `[DB] Restoring 1 instances of OwnedClassPolicy`; the door reads `count 1` | **PASS** |

### (e) N-2 — the observed half is now reachable

Trace target armed and disarmed around a single claim/release (his one-class-at-a-time rule respected; nothing else was armed during the run).

| step | request | result | verdict |
|---|---|---|---|
| e-1 | `GET /api/security/observe/trace` before | `armed false`, `target null` | — |
| e-2 | `POST /api/security/observe/trace {"class_name":"RolePrototype"}` (admin) | 200, `armed true`, budgets `max_traces 200 / max_edges 500 / max_depth 8 / window 3600`, `started_at 2026-09-19T04:17:55Z` | **PASS** |
| e-3 | `GET /api/security/roles/claimable` (demo-viewer) | 200 | **PASS** |
| e-4 | `POST /api/security/roles/claim {"role":"journalist"}` (demo-viewer) | 200, `group_id a4ef779c-…`, `why "flagged self_claimable"` | **PASS** |
| e-5 | `DELETE /api/security/roles/claim?role=journalist` (demo-viewer) | 200, `released true` | **PASS** |
| e-6 | target counters | `traces_opened 3`, `edges_written 10` (round 5: 0 / 0) | **PASS** |
| e-7 | `GET /api/security/trace/edges` — a keycloak `external:` edge | **two** of them: `endpoint:POST /api/security/roles/claim\|external:keycloak:Polari\|rest` (count 3) and `endpoint:DELETE /api/security/roles/claim\|external:keycloak:Polari\|rest` (count 2); plus the `security_claims.trace_prototype_read()` CRUDE edges `endpoint:{GET claimable,POST claim,DELETE claim}\|object:RolePrototype:read\|crude` | **PASS** |
| e-8 | `?view=objects` — an OBSERVED keycloak flow | two edges to `external:keycloak:Polari` with `flow_provenance: observed`, counts 3 and 2; `drift.counts` = `{declared 5, **observed 2**, undeclared 0, unexercised 3, classes 0, not_traced 0}` (round 5: observed 0) | **PASS** |
| e-9 | matched by the declaration, in NEITHER drift side | `observed_not_declared: []` and `declared_not_observed` = only `odoo`, `anonymous`, `origin` — **keycloak is in neither list**. `reading: "5 declared flow(s), 2 observed; 0 observed flow(s) nothing declares … and 3 declaration(s) nothing has exercised."` | **PASS** |
| e-10 | disarm | `DELETE /api/security/observe/trace` → `armed false`, `stopped RolePrototype` | **PASS** |
| e-11 | demo-viewer's groups restored | before `["default-roles-polari","offline_access","polari-viewer","uma_authorization"]`, `held []`; after **identical**, `held []` | **PASS** |

---

### 4. Secondary observations (not defects against this checklist; recorded for the ledger)

1. **The `SecurityDecision` inbound mirror lags the `InboundPolicy` state.** Both `InboundPolicy` rows read `confirmed`, but sqlite `SELECT name,kind,state FROM SecurityDecision WHERE kind='inbound'` gives:
   ```
   ('app-policy|set-862f3c1e|inbound|inbound:anonymous:anonymous', 'inbound', 'suggested')
   ('app-policy|set-862f3c1e|inbound|inbound:origin:https://prf.<lan>.nip.io', 'inbound', 'suggested')
   ```
   and `coverage?app=app-policy` `byKind.inbound` accordingly reads `{suggested 2, confirmed 0}` while `owner-policy` carries the 2 confirmed. The 432/4/2 total is unaffected and stable (that is what the checklist pins), so this is cosmetic / a separate mirror concern — but confirming an inbound row does not move its `SecurityDecision`. Also note the `SecurityDecision` **name** carries the exact origin URL; that is a stored row, not a view, and the D-2 contract is about the objects view, so it is out of scope here — flagging it only because it is one more place the host string lives.
2. **The observed keycloak edges carry `declared_by: ""`.** They are correctly matched (absent from both drift sides) but the edge itself does not name the declaration that matched it, so a reader of `/api/security/objects/flows` sees `flow_provenance: observed` with no pointer back to `app.flows:security`.
3. **Every edge reads `traced: false`** on `?view=objects`, including the two whose existence came from the causal map (`flow_provenance: observed`, counts 3 and 2), and the `causal-map` chain step still says *"NOT TRACED: no TraceTarget has ever been armed on these classes"* — while a `RolePrototype` target had just written 10 edges. The drift counters do see it (`observed 2`), so this looks like the `traced` flag / chain note keying on a different class set than the flow itself.

---

### 5. Residual state left on the stack

- `InboundPolicy` — **both** rows `confirmed` by demo-admin (`5cacba59-a133-4663-9181-c32cb861a9c6`, `2026-09-19T04:09:21Z`): `anonymous|anonymous` and `origin|https://prf.<lan>.nip.io`. The door offers `confirmed|denied` only, so there is no way back to `suggested`; the stack is `advisory`, so nothing is enforced.
- `OutboundPolicy keycloak|Polari|rest` — still `confirmed` (from the previous run; untouched).
- `OwnedClassPolicy` — **`TraceTarget` removed** (round 5's residue cleaned up, as the checklist asked). Only `UserAppPreference` remains, `enabled True / source manifest`, exactly as the manifest declares.
- `TraceTarget` rows: three coverage entries (AppPermissionProfile, UserAppPreference, RolePrototype), all **inactive**; nothing armed.
- `CausalEdge`: 8 rows, now including the two keycloak `external:` edges and three `RolePrototype:read` CRUDE edges from this run.
- `InboundPolicy anonymous|anonymous` count is climbing normally with the swarm health probe (248 at the end).
- demo-viewer's Keycloak groups are exactly as found (`polari-viewer` only; the `journalist` claim was released).
- Final stack state: `phase online`, **6/6** modules, posture `dev`, gate `advisory`, trace disarmed. `git status` clean — no tracked file edited, nothing committed, no image rebuilt.

### Artefacts (scratchpad)
`boot0.log`, `boot1.log`, `boot2.log` (full container logs per boot), `d2_*.json` / `e2_*.json` (the five objects-view doors before and after the observed flow), `topo_enforce.json`, `sim_enforce.json`, `topo_obs.json`, `edges.json`, `cov1.json`, `sq.sh` (the sqlite reader).

## §70 — ci-7: the pipeline device — target choice, preflight, doctor, the secrets posture

His ask, 2026-09-19: *"Make it configurable to choose between the pipeline
device being where the throwaway isle goes, vs another device via ssh.
However, we want a way to determine (A) if the device is clear and has
sufficient space before running the pipeline that has the throwaway isle;
(B) the configuration was set properly, and we warn the user if it is not
and what was not set up properly; (C) that we have a way to do the
automated deployment of the artifacts, and that the secrets involved in it
are only accessible via either sudo or the pipeline process itself, never a
third party."*

Built on `dev`, **uncommitted**. Nothing was deployed, no VM was started,
no container was brought up, nothing was pushed. `pol jenkins doctor` and
`pol jenkins preflight --isle` were run for real on pol-core against both
targets (isle-core read-only).

---

### What, and where

| what | where | notes |
|---|---|---|
| the device configuration | `polari-jenkins/device.env.example` (tracked) + `device.env` (gitignored, new `.gitignore` line) | `CI_ISLE_TARGET=local\|ssh`, `CI_ISLE_SSH_HOST` (an **alias**, never an address), `CI_ISLE_SSH_USER`, `CI_ISLE_VM_NAME/RAM_GB/VCPUS/DISK_GB`, `CI_ISLE_NESTED=auto\|required\|off`, `CI_ISLE_POOL`, `CI_ISLE_IMAGE_URL`, `CI_MIN_FREE_GB=20`, `CI_MIN_RAM_HEADROOM_GB=1`, `CI_EXECUTORS=1`, `CI_ROUTES` |
| the one loader/validator | `polari-jenkins/device.sh` | sourced by the CLI, the doctor, the preflight and the throwaway script. Precedence: an exported `CI_*` → `device.env` → defaults. `on_target` runs a snippet locally or over `ssh -o BatchMode=yes`. |
| **(A) preflight** | `polari-jenkins/isle/preflight.sh` + `pol jenkins preflight [--isle] [--json]` | rows `check \| value \| floor \| verdict`; any FAIL = **exit 4**; header says explicitly it is a **resource guard, not a security gate** |
| the "device is clear" reading | `polari-jenkins/isle/footprint.sh` + `footprint.py` | reuses `os-security/inventory.sh` (the same JSON `pol deploy inventory` shows); counts only Polari/isle things — docker, sshd, containerd, libvirtd are not a footprint |
| the throwaway VM | `polari-jenkins/isle/throwaway.sh` (`up\|verify\|down\|status`) | ONE script for both targets: `CI_ISLE_TARGET=ssh` scp's itself + `device.sh` to the device and re-runs there with the config in the environment (never in a file on that device). Ubuntu 24.04 cloud image cached under `<pool>/images`, qcow2 overlay, cloud-init NoCloud seed, **an ssh key generated per run**, `0600` under the run dir, shredded by `down`. Idempotent. |
| **(B) doctor** | `polari-jenkins/doctor.sh` + `pol jenkins doctor [--strict]` | `OK` / `WARN <what is wrong> → <what to do>`; **never refuses** (exit 0) so it runs at the end of `pol jenkins up` and `pol jenkins status`; `--strict` exits 1 on any WARN |
| **(C) the secrets posture** | `polari-jenkins/secrets.sh`, `polari-jenkins/init-device.sh`, `pol jenkins init-device \| secrets put \| rm \| status` | `sudo pol jenkins init-device` creates the `polari-ci` system user (nologin, in `docker`), `/etc/polari-jenkins/secrets` **root:polari-ci 0750, files 0640**, MOVES anything already in the checkout there, chowns `jenkins_home/` + `pool/`, writes `JENKINS_UID/GID/POLARI_SECRETS_DIR` into `.env` |
| the controller follows | `docker-compose.yml` | `user: "${JENKINS_UID:-${UID:-1000}}:${JENKINS_GID:-${GID:-1000}}"`, `${POLARI_SECRETS_DIR:-./secrets}:/run/secrets:ro`, the `CI_*` knobs passed through, `isle/`, `device.sh` and `mint-tag.sh` mounted |
| **(C) the automated half** | `routes/_lib.sh` `arm()`, all four routes, `Jenkinsfile.publish`, `seed.groovy` | `DRY_RUN=auto` is now the default: a route publishes for real only when **its secret is present AND it is in `CI_ROUTES`**. Each route's first line is `ARMED` / `DRY (secret <name> absent)` / `DRY (not in CI_ROUTES)`. `DRY_RUN` is a `choiceParam auto\|true\|false`. |
| the tag, fixed | `polari-jenkins/mint-tag.sh` + `Jenkinsfile.release` | `polari-vYYYY.MM.DD`, `.2/.3…` for a second release the same day, read from `git ls-remote` so a shallow CI checkout counts right. The malformed `polari-v2026.09.19+sha` is gone; the sha stays in `release.json`. A new `tag the superproject` stage pushes **only** when `github/github_token` or `github/github_ssh_key` is present, else prints the tag it would have made and carries on in dry. |
| the isle-test pipeline | `pipelines/Jenkinsfile.isle-test` + a `polari-isle-test` job | preflight (FIRST stage, `--isle` then `--json` archived) → `throwaway.sh up` → `verify` → `down` in `post { always }`. The deb-install → core-install → verify → uninstall cycle is a clearly marked **ci-3 TODO**. |
| casc | `casc/jenkins.yaml` | `numExecutors: ${CI_EXECUTORS:-1}` (was a hard `2`), `POLARI_ISLE` env, a `github_ssh_key` credential |
| the CLI | `polari-cli/scripts/jenkins.sh` (rewritten dispatcher, ~95 lines) + `polari-cli/scripts/lib/jenkins-device.sh` (device/guide/secrets half) | `pol jenkins help` is current; `index.js`'s one-line description updated |
| docs | `polari-jenkins/README.md`, `polari-jenkins/secrets/README.md` | fresh-box order: checkout → `sudo pol jenkins init-device` → `pol jenkins target …` → `secrets put` → `up` → `doctor` → `preflight --isle` |
| tests | `polari-jenkins/selftest.sh` | **56/56**, no docker, libvirt, sudo or network |

---

### The real outputs (pol-core, 2026-09-19)

`pol jenkins doctor` — **local target** (7 WARN, exit 0):

```
polari-jenkins doctor — what is configured, and what is not (read-only; it changes nothing)
device: this machine   user: user   secrets posture: repo

-- the pipeline device (device.env)
OK    device.env                 — …/polari-jenkins/device.env — present
OK    CI_ISLE_TARGET             — local — the throwaway isle is created on this machine
OK    CI_ISLE_VM_RAM_GB          — 4        … CI_ISLE_VM_DISK_GB 30, CI_MIN_FREE_GB 20, CI_EXECUTORS 1
OK    CI_ROUTES                  — github-release,ghcr,homebrew,apt-repo — routes that may publish for real

-- the controller (.env, compose)
WARN  .env                       — absent → pol jenkins up writes it from .env.example
OK    port binding               — 127.0.0.1 only (compose)
OK    listening                  — nothing on port 8080 (controller down)
OK    numExecutors               — casc follows CI_EXECUTORS (=1)

-- state directories
WARN  jenkins_home               — absent → pol jenkins up creates it
OK    pool                       — user:user 775 (repo posture — the host user owns it)

-- secrets — (C): reachable by sudo or the pipeline process, by nobody else
WARN  posture                    — REPO — secrets are readable by every process of user user
                                   (…/polari-jenkins/secrets) → sudo pol jenkins init-device — it creates the
                                   polari-ci user and moves them to /etc/polari-jenkins/secrets (root:polari-ci 0640)
OK    modes                      — every secret is 0600
OK    git                        — no real secret is visible to git

-- publication routes — ARMED (publishes for real) vs DRY (renders only)
OK    route github-release       — DRY (secret absent: github/github_token)
OK    route ghcr                 — DRY (secret absent: registries/ghcr_token)
OK    route homebrew             — DRY (secret absent: github/github_token)
OK    route apt-repo             — DRY (secret absent: signing/apt_signing_gpg signing/apt_signing_keyid ssh/distribution_host_key)
OK    routes parked              — dockerhub npm pypi launchpad snap (routes/later/ — they need an outside account)

-- the docker socket — membership is root-equivalent
OK    docker group               — user (1 member(s); membership is root-equivalent)

-- virtualisation on this machine
WARN  /dev/kvm                   — absent, and CI_ISLE_TARGET=local — the throwaway isle cannot be created here
                                   → pol jenkins target ssh <alias> to put the isle on a device with KVM
WARN  libvirt client             — virsh absent and the isle target is local
                                   → apt install libvirt-clients virtinst qemu-utils cloud-image-utils

-- network
WARN  wired IPv4                 — only a wireless interface carries an address ( wlx…) — builds will pull over Wi-Fi
                                   → plug the device in: a release build pulls gigabytes and a dropped Wi-Fi link fails the run
OK    git origin                 — reachable — polling works (public repos need no token)

-- the pool
WARN  pool floor                 — [retention] REFUSED to build: only 14 GB free, floor is 20 GB
                                   → bash polari-jenkins/retention.sh prune, or lower CI_MIN_FREE_GB knowingly

doctor: 7 warning(s) above — each says what is wrong and what to do. (Nothing was changed.)
```

`pol jenkins doctor` — **ssh target `isle-core`** (5 WARN; the isle half all OK):

```
-- the isle device over ssh
OK    ssh target                 — isle-core reachable (BatchMode — no prompt)
OK    target sudo -n             — passwordless
OK    target /dev/kvm            — present
-- virtualisation on this machine
OK    /dev/kvm                   — absent here, but the isle target is ssh:isle-core
OK    libvirt client             — not needed here (the isle target is remote)
```

`pol jenkins preflight --isle` — **local** (exit 4):

```
polari-jenkins preflight — RESOURCE GUARD (not a security gate): it refuses a run
that would exhaust the device or build a throwaway isle on a device that has a real one.
target: this machine   vm: polari-ci-isle 4GB/2vcpu/30GB   isle checks: on

check                              value                  floor        verdict
target reachable                   local                  -            PASS
pool free (retention guard)        only 14 GB             20GB         FAIL
/dev/kvm on the target             absent                 present      FAIL
nested KVM                         unreadable             Y            FAIL
free RAM on the target             8GB                    10GB         FAIL   ↳ short by 2GB
  RAM budget                       VM 4 + controller 2 + build 3 + headroom 1   10GB   PASS
free disk on …/polari-jenkins/pool 14GB                   50GB         FAIL   ↳ short by 36GB
virt-install on the target         absent                 present      FAIL
qemu-img on the target             absent                 present      FAIL
virsh on the target                absent                 present      FAIL
cloud-init seed tool               present                …            PASS
no VM named polari-ci-isle         none                   none         PASS
device is clear of Polari          NOT clear              nothing      WARN
  ↳ this is the pipeline device itself — a local throwaway VM coexists, but the VM name must stay unique.
    Found: containers:6 stacks:1 images:5 checkouts:1 volumes:2 pol-cli

REFUSED: 8 check(s) FAIL, 1 warn — fix the rows above (exit 4)
```

`pol jenkins preflight --isle` — **ssh `isle-core`** (exit 4; the device is
fit but is NOT a throwaway, which is exactly the FAIL he asked for):

```
target: ssh:isle-core   vm: polari-ci-isle 4GB/2vcpu/30GB   isle checks: on

target reachable                   isle-core              -            PASS   ↳ ssh BatchMode
target sudo -n                     yes                    yes          PASS
pool free (retention guard)        only 14 GB             20GB         FAIL   (pol-core's pool, not isle-core's)
/dev/kvm on the target             present                present      PASS
nested KVM                         Y                      Y            PASS
free RAM on the target             5GB                    5GB          PASS
free disk on /var/lib/libvirt/images 826GB                50GB         PASS
virt-install on the target         absent                 present      FAIL   ↳ install libvirt/qemu on ssh:isle-core
qemu-img on the target             present                present      PASS
virsh on the target                present                present      PASS
cloud-init seed tool               present                …            PASS
no VM named polari-ci-isle         none                   none         PASS
device is clear of Polari          NOT clear              nothing      FAIL
  ↳ ssh:isle-core carries a real Polari/isle installation — a throwaway run would fight it; pick an empty device.
    Found: debs:1 containers:4 images:5 units:4 checkouts:1 guests:1 volumes:1 /etc/isle-mesh /etc/polari isle-cli /usr/share/isle-mesh

REFUSED: 3 check(s) FAIL, 0 warn — fix the rows above (exit 4)
```

(The LAN address of neither machine appears anywhere: the config carries an
ssh **alias**; `<lan>` is never written into a tracked file.)

### selftest

```
polari-jenkins selftest — no docker, no libvirt, no sudo, no network
-- mint-tag: polari-vYYYY.MM.DD, .N for a second release the same day
-- routes: ARMED vs DRY (secret absent) vs DRY (not in CI_ROUTES)
-- preflight: the arithmetic, and the device-is-clear reading
-- doctor: one WARN per misconfiguration, each naming the fix

56/56
```

6 tag-minting cases (base, `.2`, `.3`, a peeled `^{}` ref counted once,
another day ignored, no `+sha`), 8 arming cases, 20 preflight cases
(RAM/disk shortfalls with "short by", missing KVM/nested/tools, a leftover
VM, a dirty vs clear device, unreachable target, no `sudo -n`, exit 0 vs 4,
`--json` shape), 22 doctor cases (each misconfiguration's wording, the
`--strict` exit, and a check that no secret VALUE is ever printed).

---

### Gotchas found and fixed while building

- **`set -euo pipefail` in a sourced file changes the caller's shell.**
  `device.sh` / `secrets.sh` / `footprint.sh` now apply strict mode only
  when executed directly; every executable sets its own.
- **`grep` in a `$(…)` pipeline under `pipefail` kills the script** when it
  matches nothing — this silently truncated the doctor's output at the
  "git" check on the first run. Every such pipeline now ends `|| true`.
- **A non-numeric reading crashed the preflight's arithmetic**: `[ "$x" -ge
  "$y" ]` with a path in `$x` aborted the remaining checks and still
  reported "clear to run" — a false PASS. `cmp_row` now treats anything
  non-numeric as `unknown` and marks it FAIL.
- **`python3 - <<'PY'` feeds the SCRIPT on stdin**, so a heredoc'd analyser
  cannot also read piped JSON — the footprint summariser silently returned
  "unreadable". It is now `isle/footprint.py`, a real file (and testable).
- **`VAR=x "$@" cmd`** does not treat `"$@"` as assignments; the selftest's
  harness needs `env`.
- `pol jenkins logs` verified to print secret **names** only
  (`controller/entrypoint.sh:16`) — no value reaches a log.
- Compose nested defaults (`${JENKINS_UID:-${UID:-1000}}`) do interpolate
  correctly here (`docker compose config` → `user: 1000:1000`), so the
  fallback posture still works before `init-device` has run.
- `POLARI_SECRETS_DIR` is deliberately left **empty** in `.env.example`: a
  non-empty default would make docker create `/etc/polari-jenkins/secrets`
  as root on a box where `init-device` never ran, which reads like the
  system posture without being it.

---

### OWED

1. **The econ-core move is his** — bootstrap the checkout there, `sudo pol
   jenkins init-device`, then put the secrets in
   (`github/github_token` `contents:write`, `registries/ghcr_token`
   `write:packages`; cosign and the apt pair later). Nothing in ci-7 does
   that for him, by design.
2. **`throwaway.sh up` has never run against real libvirt.** pol-core has
   no `/dev/kvm`; isle-core is not clear (correctly refused). The first
   real bring-up needs a KVM box that is empty — econ-core once it is set
   up, or isle-core with `CI_ISLE_VM_NAME` unique and the footprint FAIL
   knowingly overridden (there is no override flag today: the honest path
   is an empty device).
3. **ci-3: the install cycle inside the guest** — deb → `isle core-install`
   → verify (incl. the router guest on nested KVM) → `isle uninstall
   --everything` + `--verify` + the default-Ubuntu hand-back proof. Marked
   TODO in `Jenkinsfile.isle-test`.
4. **The local-target libvirt caveat**: the controller is a container and
   libvirt is on the host, so `CI_ISLE_TARGET=local` needs either the
   libvirt socket mounted in (a posture change — his call) or a host-tier
   agent. The ssh target avoids it entirely.
5. `isle-core` lacks `virt-install` (it has `virsh` + `qemu-img` +
   `cloud-localds`) — one `apt install virtinst` on that box, when/if it is
   ever the target.
6. Nothing is committed. `polari-jenkins/device.env` on pol-core is
   currently `CI_ISLE_TARGET=local` and is gitignored.

### §70 addendum — setup + stages + the tested-only release rule

His asks, 2026-09-19 (three, in the order they came):

1. *"Our setup command for the pol jenkins should walk us through our
   options and tell us how and what we should be setting up and where to
   get everything to work."*
2. *"this way pol jenkins setup is a one shot setup."*
3. *"we should also be able to configure what all apps outside core we want
   built and tested in the testing isle. Though default to only core I
   believe."* … then: *"the testing isle being what the pipeline is
   analyzing. The pipeline should only generate artifact for things that
   are tested. We should also be able to setup Isle Testing stages, for the
   case where we are space limited but still want to test as much as we
   can. So for example we may have stage 1 being just core, then stage 2
   testing household app, then stage 3 being electronics, and so on."*

Built on `dev`, **uncommitted**. Nothing was deployed, no VM was started, no
container was brought up, no `init-device` was run, nothing was pushed.
`pol jenkins setup --report`, `doctor`, `preflight --isle` and the selftest
were run for real on pol-core.

---

#### What, and where

| what | where | notes |
|---|---|---|
| **the walkthrough** | `polari-jenkins/setup.sh` (~300 lines, the driver) + `setup/steps/0{1..7}-*.sh` | 8 steps: role · checkout · network · secrets · isle · stages · controller · summary. `--yes` · `--report`/`--non-interactive` · `--step <name>` · `--help` |
| the CLI door | `pol jenkins setup` (`guide` kept as an alias) in `polari-cli/scripts/jenkins.sh` + `lib/jenkins-device.sh` (`jd_setup`, `jd_setup_line`) | the old 20-line `jd_guide` is GONE — its six questions are now step 5's |
| **the shared dialogs** | NEW `polari-cli/scripts/lib/tui.sh` | `tui_available/menu/input/yesno/msg/password/checklist`; whiptail when there is a tty, numbered plain prompts otherwise; `POL_TUI=plain` forces plain. Sourced by `jenkins.sh`; `setup.sh` finds it via `POL_TUI_LIB`. **prod.sh untouched** — its own `tui_*` copies stay (OWED 1) |
| the status file | `polari-jenkins/SETUP_STATUS.md` (gitignored, new `.gitignore` lines) | done/to-do table + the release rule + the verdict; `pol jenkins status` prints one line from it |
| **the stages knob** | `CI_ISLE_STAGES` in `device.env(.example)`, parsed and validated in `device.sh` | `;` between stages, `,` inside one, the literal `core` = core debs only. Default `core`. `stages_list/count/apps/all_apps/known_apps/app_known/print` |
| the ONE device.env writer | `device.sh device_env_set` + `device_reload` | `jd_set` now delegates; `device_reload` exists because plain re-sourcing keeps a stale value (device_load treats an already-set `CI_*` as an explicit override) |
| the doctor learns 8 new rows | `doctor.sh` | `submodules` · `pol CLI` · `host tools` · `target libvirt` · `CI_ISLE_STAGES` (+ `isle stages (twice)` / `(empty)`) · `isle target for tests` · `isle-test results` |
| the stage loop | `pipelines/Jenkinsfile.isle-test` (rewritten) + a `VERSION` param in `jobs/seed.groovy` | preflight → per stage: `app-debs.sh` → `throwaway up` → `verify` → *(ci-3 TODO: install + selftest)* → record → `throwaway down`; a failing stage records and the next still runs; writes `pool/<version>/isle-test/results.json` |
| the app debs | NEW `polari-jenkins/isle/app-debs.sh` | **THIN VERB** — reuses `polari-rf-node/polari-framework/modules/appstore/custom/app_deb_builder.py` (`python3 -m appstore.custom.app_deb_builder <mods>` with `PYTHONPATH=.:modules`, pool pointed at the run dir via `POLARI_APP_DEBS_DIR`), the same implementation `Isle-Mesh/isle-cli/scripts/apps.sh:37-52` calls. No second deb writer |
| **the release rule** | `routes/_lib.sh` (`tested_state` `tested_apps` `release_assets` `release_excluded`, consulted inside `arm`) + `Jenkinsfile.release` + `routes/github-release.sh` | hard: no results → every route DRY and the tag NOT pushed; `core_ok` false → same; an app not `pass` → its deb left out of the assets and named under "not released: untested/failed" in the log and the release notes. `DRY_RUN=false` does **not** override it |
| the Jenkins shape | `Jenkinsfile.release`: `build job: 'polari-isle-test', wait: true, propagate: false` + a `when { environment RELEASE_TESTED == 'yes' }` on the tag stage | chosen for being the simplest that works: no upstream/downstream plumbing, no fingerprints — isle-test is a normal job taking `VERSION`. `propagate:false` so a failed stage still leaves its results behind; the gate decides what ships, not the job's colour |
| docs | `polari-jenkins/README.md` (setup is now the entry point, with a step table and a "release rule" section), `pol jenkins help`, `polari-cli/index.js` | |
| tests | `polari-jenkins/selftest.sh` | **120/120** (was 56/56) — still no docker, libvirt, sudo or network |

#### What each step actually DOES (his "one shot")

| step | it explains | it checks LIVE | it offers to do |
|---|---|---|---|
| 1 role | controller 2 GB, build ~3 GB, VM 4 GB/2 vCPU/30 GB, nested KVM | `/proc/meminfo`, `nproc`, `df`, `/dev/kvm`, the nested module param | nothing (read-only by design) |
| 2 checkout | docker-group membership is root-equivalent | doctor rows `submodules` `pol CLI` `host tools` + the group | `apt-get install` the missing tools · `install-cli.sh` · `usermod -aG docker` · `submodule update --init --recursive` |
| 3 network | outbound only; a dropped Wi-Fi link fails a gigabyte build | doctor rows `wired IPv4` `git origin` + `nmcli con show` | `nmcli con up "<the wired connection>"` |
| 4 secrets | the two postures, verbatim | `secrets_mode`, `secrets_have` per route secret | `sudo pol jenkins init-device` · paste (hidden) each outside-authority token · GENERATE cosign / gpg / ssh material and store both halves |
| 5 isle | local vs ssh + the local-target caveat | doctor rows `ssh target` `target sudo -n` `target /dev/kvm` `target libvirt`, then the real `preflight --isle` | `pol jenkins target …` · `ssh-keygen` · `ssh-copy-id` · the sudoers drop-in over `ssh -t` (shown verbatim, `visudo -c`'d) · libvirt over ssh · the VM knobs |
| 6 stages | the space trade-off, the cost per app, the release rule | `CI_ISLE_STAGES` against `modules/*/polari-app.json` | build the stage list (a checklist per stage) and write the knob |
| 7 controller | 127.0.0.1 only, `ssh -L`, the admin password, the four jobs, `DRY_RUN=auto` | `.env`, `jenkins_home`, the UI's HTTP code | `pol jenkins up` |
| 8 summary | — | doctor warning count + `preflight --isle` verdict | writes `SETUP_STATUS.md` |

#### WHERE to get each secret (the table the selftest checks for completeness)

| secret | kind | where | how |
|---|---|---|---|
| `github/github_token` | paste | https://github.com/settings/personal-access-tokens/new | fine-grained → repo `dausume/polari-suite` → **Contents: Read and write** (releases + the tag push); a classic token with `repo` also works |
| `registries/ghcr_token` | paste | https://github.com/settings/tokens | **classic** (fine-grained cannot do packages) → `write:packages` + `read:packages`; `delete:packages` only to remove a bad tag |
| `signing/cosign_key` + `cosign_password` | generated here | cosign is in the controller image; binaries at https://github.com/sigstore/cosign/releases | `cosign generate-key-pair`, else `docker run --rm -v "$PWD":/w -w /w ghcr.io/sigstore/cosign/cosign generate-key-pair`; a random 24-char passphrase; `cosign.pub` → `polari-jenkins/cosign.pub` (tracked, it is public — `.gitignore` gained `!cosign.pub`) |
| `signing/apt_signing_gpg` + `apt_signing_keyid` | generated here, **BLOCKED** | nothing to fetch | `gpg --quick-generate-key "Polari apt signing <apt@polari.invalid>" ed25519 sign 2y` then `--armor --export-secret-keys`; **blocked until the Keycloak rotation (CICD §5.4)** — offered with default NO, the route stays DRY |
| `ssh/distribution_host_key` | generated here, **BLOCKED** | its `.pub` goes in the downloads host's `authorized_keys` | `ssh-keygen -t ed25519 -C polari-ci-apt` |
| `github/github_ssh_key` | optional | the repo → Settings → Deploy keys → Allow write access | `ssh-keygen -t ed25519 -C polari-ci`; the public half printed for pasting |
| parked | — | — | `dockerhub npm pypi launchpad snap` — each needs an outside account; **parked by his rule, nothing is asked** |

Nothing above ever prints, echoes or logs a VALUE. Generated material is
stored through `pol jenkins secrets put`, so it lands in
`/etc/polari-jenkins/secrets` (root:polari-ci 0640) when the system posture
is in force and in the checkout with a loud warning when it is not.

#### The real `pol jenkins setup --report` (pol-core, 2026-09-19)

```
┌──────────────────────────────────────────────────────────────────────────┐
│ pol jenkins setup — the pipeline device, one step at a time              │
└──────────────────────────────────────────────────────────────────────────┘
   device: this machine   secrets posture: repo   mode: report
   READ-ONLY: this run changes nothing. It prints the state and the to-do list.

══ step 1/8 — this device's role
   [ok]   measured here: 15.5 GB RAM, 4 vCPU, 14 GB free: controller + builds serialised — not a concurrent isle VM; put the isle on another device (pol jenkins target ssh <alias>) or add RAM
   [ok]   controller: yes — the controller is capped at 2 GB
   [ok]   builds: yes — controller 2 GB + one build ~3 GB, serialised
   [--]   isle-here: no — no /dev/kvm on this machine
   [--]   isle-only: no — no /dev/kvm on this machine
   [--]   nested KVM: unreadable (the isle's router guest runs INSIDE the throwaway VM)

══ step 2/8 — the checkout and the CLI
   [ok]   submodules: all five populated (polari-cli, polari-rf-node, political-scorecard-node, polari-app-shell, Isle-Mesh)
   [ok]   pol CLI: /home/user/.local/bin/pol
   [ok]   host tools: docker python3 git curl whiptail — all present
   [ok]   docker group: user can talk to the docker socket

══ step 3/8 — the network — outbound only
   [--]   wired IPv4: only a wireless interface carries an address ( <lan>) — builds will pull over Wi-Fi
   [ok]   git origin: reachable — polling works (public repos need no token)
   [ok]   inbound: nothing is opened — the UI binds 127.0.0.1 and every publish is an outbound push

══ step 4/8 — the secrets posture, and the secrets
   [--]   posture: REPO — /home/user/Desktop/polari-suite/polari-jenkins/secrets, readable by EVERY process of user
   [--]   github/github_token — absent: the github-release and homebrew routes: create the release, upload its assets, push the version tag
   [--]   registries/ghcr_token — absent: the ghcr route: push the release images to ghcr.io/dausume
   [--]   signing/apt_signing_gpg — absent (BLOCKED until the Keycloak rotation (CICD_PIPELINE_PLAN §5.4): the apt/downloads route may not be armed before it. Generate the material if you like — the route stays DRY.)
   [--]   signing/apt_signing_keyid — absent (BLOCKED until the Keycloak rotation (CICD_PIPELINE_PLAN §5.4): the apt/downloads route may not be armed before it. Generate the material if you like — the route stays DRY.)
   [--]   ssh/distribution_host_key — absent (BLOCKED until the Keycloak rotation (CICD_PIPELINE_PLAN §5.4): the apt/downloads route may not be armed before it. Generate the material if you like — the route stays DRY.)
   [ok]   signing/cosign_key — absent (optional: signs the release images and the checksums so a downloader can verify them)
   [ok]   signing/cosign_password — absent (optional: the passphrase of the cosign private key (generated with it))
   [ok]   github/github_ssh_key — absent (optional: OPTIONAL alternative to github_token for the tag push only (a deploy key))
   [ok]   parked routes: dockerhub npm pypi launchpad snap — each needs an outside account; parked by his rule, nothing is asked for them

══ step 5/8 — where the throwaway isle goes
   [ok]   target: this machine (device.env: CI_ISLE_TARGET=local)
   [ok]   VM: polari-ci-isle — 4 GB / 2 vCPU / 30 GB, nested=auto
   [--]   KVM here: absent, and CI_ISLE_TARGET=local — the throwaway isle cannot be created here
   [--]   libvirt here: virsh absent and the isle target is local
   [--]   LOCAL-TARGET CAVEAT: the controller is a CONTAINER and libvirt lives on the host, so a local target needs the libvirt socket mounted in (a posture change nobody has authorised) or a host-tier agent. The ssh target has no such problem.
   [--]   testable: the target is this machine and it has no /dev/kvm — NOTHING can be released until an isle target exists
   [--]   preflight --isle: FAIL — pol jenkins preflight --isle shows the table

══ step 6/8 — isle testing stages — what gets tested, and so what ships
  stage 1  core only
   [ok]   CI_ISLE_STAGES=core — 1 stage(s), run one after another, each in its OWN throwaway isle
   [ok]   every app named is a real module (modules/<name>/polari-app.json)
   [ok]   THE RELEASE RULE: core publishes only when the isle test recorded core_ok; an app deb ships only when its stage result is pass; no results.json for a version = NOTHING published, tag not pushed

══ step 7/8 — bring the controller up
   [--]   .env: absent
   [--]   jenkins_home: absent
   [ok]   port binding: 127.0.0.1 only (compose)
   [--]   nothing answers on 127.0.0.1:8080 — the controller is down
   [ok]   admin password: /home/user/Desktop/polari-suite/polari-jenkins/secrets/admin/jenkins_admin_password (generated by pol jenkins up, printed once)
   [ok]   reach it from another machine: ssh -L 8080:127.0.0.1:8080 <alias>, then http://127.0.0.1:8080 — nothing is ever exposed

══ step 8/8 — summary

   done:
     ✓ this device's role — 15.5 GB RAM, 4 vCPU, 14 GB free: controller + builds serialised — not a concurrent isle VM; put the isle on another device (pol jenkins target ssh <alias>) or add RAM
     ✓ the checkout and the CLI — checkout, pol, docker and the host tools are all in place
     ✓ isle testing stages — what gets tested, and so what ships — 1 stage(s): core

   still to do, in order:
      1. [network] put this device on a wire — a release build pulls gigabytes and a dropped Wi-Fi link fails the run
         → nmcli con show   then   nmcli con up "<the wired connection>"
      2. [secrets] move the secrets out of the checkout (the posture (C) asks for)
         → sudo pol jenkins init-device
      3. [secrets] put github/github_token in place
         → https://github.com/settings/personal-access-tokens/new
      4. [secrets] put registries/ghcr_token in place
         → https://github.com/settings/tokens
      5. [isle] this machine has no /dev/kvm — the isle cannot be built here
         → pol jenkins target ssh <alias>, or enable VT-x/AMD-V in firmware
      6. [isle] the preflight refuses this device
         → pol jenkins preflight --isle   (each FAIL row names its own fix)
      7. [controller] start the controller
         → pol jenkins up

   THE RELEASE RULE — the pipeline only generates artifacts for things it 
   TESTED in a throwaway isle. Stages now: core. Core debs and images 
   publish only when the isle test recorded core_ok; an app's deb ships only 
   when its stage result is pass; with no isle-test/results.json for a 
   version NOTHING is published and the tag is not pushed.

   NOT READY — 7 thing(s) stand in the way; the first is: put this device on a wire — a release build pulls gigabytes and a dropped Wi-Fi link fails the run
   steps: 3 of 8 complete   ·   full state: pol jenkins setup --report
   saved: /home/user/Desktop/polari-suite/polari-jenkins/SETUP_STATUS.md (gitignored)
```

(The wireless interface name is written `<lan>` above; no address, hostname
or e-mail is written anywhere — `SETUP_STATUS.md` is gitignored and names
only "this machine" or an ssh alias.)

#### selftest

```
polari-jenkins selftest — no docker, no libvirt, no sudo, no network
-- mint-tag: polari-vYYYY.MM.DD, .N for a second release the same day
-- routes: ARMED vs DRY (secret absent) vs DRY (not in CI_ROUTES)
-- preflight: the arithmetic, and the device-is-clear reading
-- doctor: one WARN per misconfiguration, each naming the fix
-- setup: the role arithmetic, the where-to-get-it table, --report, idempotence
-- stages: parsing, the twice/unknown/empty warnings, and what may be released

120/120
```

64 new cases on top of ci-7's 56:
- **11** role-fit arithmetic (16 GB fits everything · 7.5 GB fits builds but
  not a concurrent isle and the sentence says so and names the ssh way out ·
  no KVM → no isle role · 4.5 GB hosts the VM but cannot build · too little
  disk → no isle here · the headline carries RAM/vCPU/disk);
- **11** the where-to-get-it table (every ACTIVE route's secret carries a URL
  **or** a generate command — the completeness check; the fine-grained token
  page and its exact permission; `write:packages`; cosign's two methods; the
  `.invalid` address; both apt items marked blocked; the Deploy keys page; no
  `-----BEGIN` can appear in the table);
- **12** `--report` with no terminal (READ-ONLY, all 8 steps, the to-do list,
  the release rule, a verdict, the URL, the step count, `SETUP_STATUS.md`
  written with the verdict and the count, no secret value) + idempotence
  (a second run changes no configuration and reports the same count) + the
  skip path (answering nothing leaves `device.env` alone and says
  `already: OK`);
- **13** stage parsing (`core` → one stage with no apps · `;` · `,` ·
  whitespace anywhere · `core` inside a stage is implicit · an empty stage is
  a line, not dropped) and the warnings (unknown name + the known list ·
  tested twice · empty stage · no stage at all → FAIL · the stage builder's
  rendering);
- **17** the release rule (`core_ok` + secret + CI_ROUTES → ARMED · a
  not-passed app held back and NAMED · `core_ok` false → DRY · no results
  file → DRY with his wording verbatim · `DRY_RUN=false` cannot force it ·
  `release_assets` keeps the core deb and the passed app deb and drops the
  untested one).

#### Gotchas found and fixed while building

- **Re-sourcing `device.sh` keeps the STALE value.** `device_load` captures
  every already-set `CI_*` as an "explicit override" and wins it back after
  reading the file — so a caller that had loaded once could never see what it
  had just written. Hence `device_reload` (unset, then load). The same trap
  is why `jd_setup` no longer calls `jd_export_for_compose` first: exported
  `CI_*` would shadow everything setup writes.
- **`$(…)` strips the trailing newline, so `while read` silently drops the
  last line.** The role step printed 3 of its 4 roles. `printf '%s\n'` plus a
  `[ -n "$role" ] || continue` guard.
- **`read` failing under `set -u` leaves the variable UNBOUND**, not empty —
  `tui_yesno` died with `c: unbound variable` the moment stdin hit EOF. Every
  helper now declares `local c=""` and `_tui_read` ends `|| true`.
- **`/dev/tty` can exist and still not be openable** (`-r` passes, the open
  fails with "No such device or address"). The test is now
  `{ : </dev/tty; } 2>/dev/null`, not `[ -r /dev/tty ]`.
- **The isle CLI's module path is stale**: `Isle-Mesh/isle-cli/scripts/apps.sh`
  invokes `appstore.app_deb_builder`, but the file lives at
  `modules/appstore/custom/app_deb_builder.py` and only
  `appstore.custom.app_deb_builder` imports. `app-debs.sh` uses the working
  path (OWED 3).
- `local v() ; v() { … }` is not valid bash — a helper inside
  `setup_role_headline` had to become three plain `awk` extractions.
- Adding the release rule to `arm()` retroactively made every ci-7 arming
  test DRY; the selftest now seeds a passing `results.json` for those cases
  and tests the gate separately. That is the rule working, not a regression.
- `CI_ISLE_STAGES=` empty can never reach the "no stage at all" FAIL through
  `device.env` (the `:=` default fills it), so that guard is tested by
  clearing the variable after `device_load` — it stays as defence, not dead
  weight.

#### OWED

1. **`prod.sh` still carries its own `tui_menu/input/yesno/msg`** (lines
   ~166-190). They are now duplicated by `polari-cli/scripts/lib/tui.sh`.
   Deliberate for this slice — prod.sh was declared untouched — but it is a
   real duplication and should collapse into `lib/tui.sh` next time prod.sh
   is opened. The Textual guide (`prodguide`) has no `jenkins` equivalent and
   none is planned.
2. **ci-3 is still the blocker, and now it blocks RELEASES.** The install +
   selftest body inside the guest is a marked TODO, so every stage records
   `skipped`, `core_ok` stays false, and the release rule therefore publishes
   **nothing** and pushes no tag. That is the honest state — but it means the
   pipeline cannot release at all until ci-3 lands. Flagging it loudly: this
   is a behaviour change for anyone who expected `polari-release` to publish.
3. **`Isle-Mesh/isle-cli/scripts/apps.sh` names a module path that does not
   import** (`appstore.app_deb_builder` vs `appstore.custom.app_deb_builder`).
   One-line fix on isle-core's working copy; not touched from here.
4. **`app-debs.sh` has never run.** It needs a framework checkout (present)
   and the builder's own preconditions (the module registry); no deb was
   generated in this slice — nothing was built, per the brief.
5. **`polari-release` now waits on `polari-isle-test`.** On a device with no
   isle target that inner job REFUSES at the preflight (exit 4), the release
   still completes the build, and nothing publishes. Correct, but it makes
   the isle target a hard prerequisite for any release — the doctor says so
   (`isle target for tests`).
6. The `gh release upload` change uses `mapfile`, so the github-release route
   now needs bash (it already had `#!/bin/bash`).
7. Nothing is committed. `polari-jenkins/device.env` on pol-core is unchanged
   (`CI_ISLE_TARGET=local`, no `CI_ISLE_STAGES` key, so the default `core`
   applies) and is gitignored.

## §71 — ci-8: the `cicd` app — pipeline settings as rows, runs mirrored in

His ask, 2026-09-19: *"We may want a CICD app as well that is always enabled
with the pipeline that can allow us to read and modify the settings of the
pipeline."*

His addendum, same day: *"some people will also be using this pipeline as a
way to maintain their own Polari Apps and will only be testing the one app
they are developing."*

Built on `dev`, **uncommitted**. Nothing was deployed, no container was
brought up, `pol jenkins up` was never run, no VM was started, nothing was
pushed. `polari-jenkins/device.env` and `SETUP_STATUS.md` on pol-core are
untouched (both gitignored). The two selftests were run for real.

---

### The design, in one paragraph

**Polari is the SOURCE OF TRUTH for the pipeline's configuration.**
`polari-jenkins/device.env` is the fallback, and it is rewritten from the
rows by `cicd-sync.sh pull` at the top of every Jenkinsfile — never fatally:
a core that does not answer leaves the file the device already has and says
so on one line. **Edits happen on the rows' own pages** (his per-object
display rule), which are configured `class-rows-table` / `api-structured-panel`
items — **no new frontend component, no Angular at all**. **Runs, isle-test
stage results, releases and secret PRESENCE are mirrored IN** through a
per-device **posting-only** credential that can reach one door and nothing
else; it is not a build credential and is not a Jenkins account of any kind.

### Two modes (his addendum)

| | `suite` (default) | `app` |
|---|---|---|
| what is built | the whole Polari suite | ONE Polari app (`CI_APP_NAME`, from `CI_APP_REPO` — the `pol project` standalone loop) |
| the core | built here | **pulled**, never rebuilt: `CI_CORE_SOURCE=release:<tag>` / `release:latest` (`build` is the escape hatch for somebody who also patches core) |
| stages default to | `core` | `core; <app>` |
| the release is | the suite's artifacts | that app's deb alone |
| published to | upstream Polari's routes | the developer's OWN (`PipelineRoute.target`); an app-mode route targeting `dausume` is a validation **FAIL** — a fork is never republished under an upstream name |
| the record says | the version it built | **`tested_against`**: the CORE release the app passed against. An app-mode `release` ingest with no `tested_against` is **refused** — a deb that passed against an unnamed core is an unfalsifiable claim. |

The release rule is unchanged in both: only what a stage TESTED, and passed,
may ship.

---

### What, and where

| what | where | notes |
|---|---|---|
| **the module** | `polari-rf-node/polari-framework/modules/cicd/` (new, 17 files, ~1 900 lines incl. the selftest) | `polari-app.json`, `__init__.py`, `cicd_basis.py`, `cicd_api.py`, `cicd_endpoints.py`, `cicd_seed.py`, `cicd_page.py`, `cicd_selftest.py`, `README.md`, `objects/cicd/*.py` (7), `custom/*.py` (5) |
| the 7 rows | `modules/cicd/objects/cicd/` one class per file | `PipelineDevice` `PipelineStage` `PipelineRoute` (the SETTINGS a person owns) · `PipelineSecretPresence` `PipelineRun` `IsleTestResult` `ReleaseRecord` (MIRRORED in). `cicd_basis.CICD_CLASSES` splits them, and the selftest asserts the count is 7 |
| **the ONE rule set** | `modules/cicd/custom/cicd_validate.py` (~330 lines) | `device.sh device_validate` + `device_validate_stages` ported to python, same row shape `(key, value, status, message)`. It is a PORT, not a call: the core is not on the pipeline device and cannot source a shell file beside a `device.env` it has never seen. Kept honest by feeding both copies the same cases |
| the stage parser | `modules/cicd/custom/cicd_stages.py` | `parse`/`render`/`rows_to_stages` — the exact counterpart of `stages_list` (`;` between stages, `,` inside one, the literal `core` dropping out, an empty stage kept as a line) |
| the two credentials | `modules/cicd/custom/cicd_auth.py` | `ADMIN_ROLES` (from `polariapps…_shared`, literal fallback) for a person; `hash_token`/`mint_token`/`device_for_token` (sha256 + `hmac.compare_digest`) for the pipeline |
| the mirror's refusals | `modules/cicd/custom/cicd_ingest.py` | the five kinds; `VALUE_LIKE` deep scan; the loopback-URL rule; the alias-is-not-an-address rule; the app-mode `tested_against` rule; job/status vocabularies |
| the reads | `modules/cicd/custom/cicd_rows.py` | `everything()` = the ONE read `pull` makes; `MODE_SUITE`/`MODE_APP`/`RELEASE_RULE` in words |
| **the pages** | `modules/cicd/cicd_page.py` | `/display/cicd`, `cicd-stages`, `cicd-runs`, `cicd-releases`. Only `class-rows-table` + `api-structured-panel`; the settings tables ARE the editing surface |
| the write gate | `modules/cicd/cicd_seed.py` | `cicd-settings` (published, `["polari-admin"]`, all verbs, the three settings classes) and `cicd-observer` (the shipped TEMPLATE convention: unpublished, no group bound, read-only). Guarded import — a core without polariapps admits the module fine |
| **the sync** | `polari-jenkins/cicd-sync.sh` (NEW, ~250 lines) | `pull` · `push` · `push-secrets` · `run` · `isle-test` · `release` · `status` |
| the CLI | `polari-cli/scripts/jenkins.sh` (`sync` case + the help block), `polari-cli/scripts/lib/jenkins-device.sh` (`jd_sync`) | `pol jenkins sync pull\|push\|status` |
| the device's new keys | `polari-jenkins/device.sh` (`DEVICE_KEYS`, defaults, `device_validate`, `device_validate_stages`), `device.env.example` | `CI_MODE` `CI_APP_NAME` `CI_APP_REPO` `CI_CORE_SOURCE` `CI_CORE_URL` `CI_DEVICE_NAME` (21 keys, was 15) |
| the doctor learns 3 rows | `polari-jenkins/doctor.sh` §"the settings' source" | `cicd core` (matches / DIFFERS / no row / down) · `cicd module` (a core that answers but has no `/api/cicd`) · `cicd credential` |
| the pipelines | all four `polari-jenkins/pipelines/Jenkinsfile.*` | a `sync settings from Polari (non-fatal)` first stage; `run` at start and in `post always` (`currentBuild.currentResult.toLowerCase()`); `isle-test` per stage as it finishes; `release` from `release.json` |
| compose | `polari-jenkins/docker-compose.yml` | `cicd-sync.sh` + `secrets.sh` mounted into the controller |
| **admission** | `polari-cli/prod-profiles/pipeline-device.env:12` — `POL_PROD_MODULES=polariapps,appstore,islemesh,terms,security,iso,cicd` | `pol prod profile use pipeline-device --apply`. The doctor checks it live and names that command when a core answers without `/api/cicd` (`doctor.sh:95-97`) |
| core registration | `polariApiServer/feature_imports.py:1262-1269` · `polariApiServer/module_endpoints.py:526-529,533` · `moduleService/module_loading.py:38` · `polariApiServer/polariServer.py:1282-1285` (defClassList), `:2362-2363` (pages), `:3261` (seed pairs) | the same six points `iso` uses |
| docs | `modules/cicd/README.md` (new), `polari-jenkins/README.md` §"Where the settings live (ci-8)", `polari-cli/prod-profiles/README.md` (the profile table) | |

### The doors

    GET  /api/cicd                  settings + stages + routes + readiness + the rendered device.env, in ONE read
    GET  /api/cicd/device           the settings and their validation (+ token_set, never the hash)
    POST /api/cicd/device           ADMIN — change them; a FAIL refuses the WHOLE post, nothing partial
    POST /api/cicd/device/token     ADMIN — mint the posting-only token, SHOWN ONCE; only sha256 stored
    POST /api/cicd/stages           ADMIN — replace the ordered stages (a shorter list loses its tail rows)
    POST /api/cicd/routes/{route}   ADMIN — {"enabled": …} (+ optional {"target": …})
    POST /api/cicd/ingest           the MIRROR — the posting-only token; five kinds
    GET  /api/cicd/runs  /results  /releases

`GET /api/cicd` is deliberately unauthenticated: it holds knobs and verdicts,
no secret value exists anywhere in the answer, and a pipeline that also had
to hold a READ credential would be one more secret on the device for nothing.

### Why a token and not a Keycloak service account

A pipeline device commonly points at a **lean** core where `POL_PROD_AUTH=off`
and there is no Keycloak at all (`docker-compose.lean.yml:136`). A credential
that only existed when Keycloak did would work on one deployment and silently
not on another. The token is per device (`hmac.compare_digest` against that
device's hash alone), so a leak is revoked by re-minting **one** device's and
every other is untouched; and it can post the five kinds and nothing else.

---

### Exact numbers

* `modules/cicd/cicd_selftest.py` — **128/128**
  (`cd polari-rf-node/polari-framework && PYTHONPATH=.:modules python3 modules/cicd/cicd_selftest.py`)
* `polari-jenkins/selftest.sh` — **152/152** (was 120/120; +32 for ci-8)
* `modules/security/security_selftest.py` — **296/299**, unchanged
* `python3 -m moduleService.manifests generate cicd` then `conform cicd` — **1/1 conform, OK**
* `PYTHONPATH=.:modules python3 -c "import polariApiServer.polariServer"` — clean
  (the two pre-existing `RelayNodeDefinition` / `GuestNetworkDefinition`
  "no assigned manager" lines are unchanged from before this slice)
* 7 row classes, 9 doors, 4 pages, 5 ingest kinds, 21 `DEVICE_KEYS` (was 15),
  19 keys rendered into `device.env` (`CI_CORE_URL` and `CI_DEVICE_NAME` are
  device-local and preserved by a pull, never written by the core)

The 32 new shell cases: 11 mode cases (suite/app, the two FAILs when an app
mode names neither app nor repo, the app-mode stage default, "another app is
tested but never released here", no stage tests the app it maintains, an
unknown mode read as suite, the three `CI_CORE_SOURCE` shapes), 8 pull cases
(rewrites the file, the mode keys land, `CI_CORE_URL` survives, the trailing-
newline trap, a core that is down keeps the file, a core answering FAIL-ing
settings keeps the file, no `CI_CORE_URL` says so plainly), 13 push cases
(the device kind with its mode and armed routes; the secrets kind with the
name and the boolean; and four separate assertions that **no secret value and
no posting token** appear in any posted body or in `status`).

The 128 python checks cover: the rows and the class-count assertion, the
value-shaped-field audit of **every** class by `inspect.signature`, the
device.sh parity cases, ci-8's own alias-is-not-an-address rule, the stage
parser both ways, all of the two modes, the mirror's refusals (401 with no
credential, 401 with a wrong one, 400 naming the five kinds, 400 naming the
value-shaped field **with nothing stored**, 400 for a non-loopback URL / an
unknown job / an unknown status, 403 for one device's token posting for
another), REPORT-not-override and ADOPTION, the token shown once and revoked
by re-minting, the admin refusals (401/403), the stage tail removal, the
parked/unknown route refusals, the §54 route guard, the pages' component
audit, the seed (nothing about a machine or a build is seeded), and the
manifest + the admission knob **by file** (`pipeline-device.env`'s
`POL_PROD_MODULES` must end in `,cicd`).

---

### Gotchas found and fixed while building

* **`python3 - <<'PY'` feeds the SCRIPT on stdin** — the §70 gotcha, hit
  again in `cicd-sync.sh do_pull`: the heredoc'd analyser could not also read
  the piped response body, so every pull silently reported "the core answered
  but not with a usable settings set". The body now goes through a file and
  an argv path. Caught by the new selftest, not by inspection.
* **`$(…)` strips the trailing newline**, so the LAST pulled key ran into the
  appended one: `CI_ISLE_STAGES=core; householdCI_CORE_URL=…`. `printf '%s\n'`,
  always — and there is now a selftest case for exactly that line.
* **A settings change was refusable by an empty stage list.** `validate_settings`
  FAILs on "no testing stage at all" (correctly — `device.sh` does too), which
  made `POST /api/cicd/device` refuse a RAM change on a device nobody had
  written stages for yet. The stage FAILs are now excluded from that door's
  refusals (they belong to `POST /api/cicd/stages`) and still appear in the
  rows. Wrong coupling, found by the selftest.
* **Rows are keyed by their generated tree id, not by `name`.** The selftest's
  first pass looked rows up as `objectTables['PipelineDevice']['pipe-1']` and
  found nothing; a `_named()` helper does what a door does.
* **A fake manager needs `idList`** (and a `noteTreeMutation` no-op) or
  `treeObject.makeUniqueIdentifier` raises — `security_selftest` sidesteps it
  by using `SimpleNamespace` rows; this one instantiates the real classes, so
  it provides them.
* **`CICD_DEVICE_NAME` must not default to `hostname`.** The first draft did,
  which would have written the machine's real hostname into a row that is
  persisted, rendered on a page and served by an API — his privacy rule. It is
  now `CI_DEVICE_NAME`, default `pipeline`, with the reason in
  `device.env.example`.
* **A device push must REPORT, not override.** The obvious implementation
  (write what the device sent) would have quietly made `device.env` the source
  of truth again — the exact thing this slice exists to stop. A push writes
  only the reported columns; the one exception is ADOPTION, a device the core
  has never seen, whose own file is the only configuration that exists.
* `del <expr> if … else None` is not valid Python (`cannot delete conditional
  expression`) — a leftover from sketching the adoption case.
* **A latent defect in the security module, found in passing:**
  `modules/security/security_api.py:210` imports
  `polariApiServer.seed_upsert`, which **does not exist** (the module is
  `moduleService.seed_upsert`). Every `SecurityAPI._upsert` therefore falls
  into its `except` branch and constructs a raw object instead of upserting —
  so a re-posted audit run or ssh inventory INSERTS a duplicate rather than
  converging. `cicd_api._upsert` uses the correct path. Not fixed here (out of
  this slice's scope), flagged as OWED 4.

### Deliberate deviations from the brief

1. **`pol jenkins doctor` does not pull before reading.** The doctor's own
   contract, printed in its header, is "read-only; it changes nothing", and a
   pull rewrites `device.env`. It COMPARES instead — `cicd core — device.env
   matches the rows` / `…DIFFERS → pol jenkins sync pull` — and `pol jenkins
   setup` remains the interactive path that may change things. Say the word
   and it becomes a pull.
2. **The mirror inside the controller container is one-way-effective today.**
   `device.sh`'s precedence is "an exported `CI_*` beats the file", and
   `pol jenkins up` exports the whole set into compose — so a pull *inside*
   the controller writes the file but the stale export still wins for that
   process. `do_pull` now prints one `⚠ <KEY>: the core says X but an exported
   value Y is in force` line per divergent key rather than pretending
   otherwise. OWED 1.

---

### OWED

1. **The pulled file does not yet outrank the compose export inside the
   controller.** Either `pol jenkins up` stops exporting `CI_*` (and the
   container reads the mounted `device.env`), or `device.sh` grows a
   "`the file was written by a pull`" precedence. Today the divergence is
   printed, loudly, per key — which is honest but not yet right.
2. **The live proof on the home stack has not happened.** Nothing was
   deployed: the pages have never been rendered in a browser, `GET /api/cicd`
   has never been served by a real backend, and no admin has minted a token
   through the real door. Needs `pol prod profile use pipeline-device --apply`
   (or `cicd` added to the running stack's `POLARI_MODULES`) and a browser
   pass over the four pages.
3. **The first real sync from a pipeline device has not happened.** Every
   `cicd-sync.sh` path is proven against a scripted `curl`; none has talked to
   a Polari instance. The first real run should be: `pol jenkins sync status`
   → `push` (adoption) → change a knob on `/display/cicd` → `pull` → confirm
   `device.env` followed.
4. **`security_api.py:210` imports a module that does not exist**
   (`polariApiServer.seed_upsert` vs `moduleService.seed_upsert`), so every
   security upsert silently degrades to a raw insert. One-line fix; not taken
   in this slice.
5. **ci-3 still blocks everything downstream.** The install cycle inside the
   guest is still a marked TODO, so every stage records `skipped`, `core_ok`
   stays false, and the release rule publishes nothing — which means the
   `IsleTestResult` and `ReleaseRecord` tables will be honest and empty until
   ci-3 lands. `app` mode inherits that exactly: a developer's app deb cannot
   ship until a stage can actually pass.
6. **`CI_CORE_SOURCE=release:<tag>` is a SHAPE, not a fetch.** Nothing
   resolves the tag yet; pulling an official release's core debs and images
   into a pool for an app-mode run is not built. `pol prod`'s
   `POL_PROD_DEBS=release:<tag>` reader is the obvious place to reuse.
7. **`app` mode's isle-test body is not narrowed yet.** `Jenkinsfile.isle-test`
   still walks `CI_ISLE_STAGES` generically; "install the core from
   `CI_CORE_SOURCE`, then run only this app's selftests" is part of the same
   ci-3 body.
8. **Scan/SBOM assets for an app release** (mentioned in his addendum) are not
   built — `ReleaseRecord.released_json` carries whatever `release.json` names.
9. Nothing is committed, nothing is pushed.

**§71 review note (Fable):** the latent `security_api._upsert` defect the build found is FIXED in the same commit — it imported a `polariApiServer.seed_upsert` that never existed, so every posted audit / inventory / ssh row was CONSTRUCTED anew instead of converged (a duplicate per POST); it now calls `moduleService.seed_upsert.upsert_seed_rows` and returns the live row by name. Security selftest unchanged at 296/299.

## §72 — ci-9: offline-first builds, the suite|app question, core artifacts from a release

His asks, 2026-09-19 (two, verbatim):

1. *"the jenkins pipeline should try and use offline artifacts for building
   where possible, that way we are taking less time when repeatedly using the
   same data"*
2. *"some people will also be using this pipeline as a way to maintain their
   own Polari Apps and will only be testing the one app they are developing"*

Built on `dev`, **uncommitted**. Nothing was deployed, no container was
brought up, `pol jenkins up` was never run, no VM was started, no proxy was
started, nothing was pushed. `pol jenkins setup --report`, `doctor`, `cache
status`, `cache prune`, `isle status`, `core-artifacts resolve|status` and
both selftests were run for real on pol-core. `docker build --check` was run
against all three Dockerfiles; **no image was built.**

---

### The two halves, in one paragraph each

**The cache.** One directory under the pool — `<pool>/cache` — that every
builder reads FIRST and folds what it fetched back into: wheels, npm
tarballs, distro debs, saved base images, the throwaway isle's cloud image,
fetched Polari releases, and the BuildKit layer cache. One record per entry
(`what`, `sha256`, `fetched`, `last_used`, `bytes`). **The rule, everywhere:
the cache is an OPTIMISATION, never a precondition** — an empty cache still
builds, over the network, and says so. `retention.sh prune` is now forbidden
to touch it (it walked `pool/*/` and would have deleted it as an old
version); `pol jenkins cache prune --older-than N` is its only deleter and
removes only entries whose `last_used` is older than the knob. Tier two —
four caching proxies on 127.0.0.1 — exists, is off by default, and a pipeline
never starts it.

**App mode.** ci-8 gave `CI_MODE=app` its keys and its validation; nothing
asked, and `release:<tag>` resolved to nothing. Now `pol jenkins setup`'s
FIRST question is *"what does this pipeline maintain?"*, answering *ONE
Polari app* asks for the module, its repo (cloned under `<pool>/apps/<name>`
with `pol project` conventions), the core release, and `CI_ROUTE_TARGET`;
`isle/core-artifacts.sh` resolves `release:latest` through the same reader
`pol prod` uses and fetches + SHA256-verifies that release's core debs once
into `<cache>/releases/<tag>/`; the isle test installs THAT core and records
`tested_against`; and the release carries **only** that app's deb, to the
developer's own target — with an upstream target a hard refusal.

---

### What, and where

| what | where | notes |
|---|---|---|
| **the cache library** | NEW `polari-jenkins/cache.sh` (~290 lines) | sourced by the builders, executed by `pol jenkins cache`. `cache_area/hit/put/touch/fetch/wheels/images_warm/images_save/layers_args/build_args/status/prune`. 9 areas: `wheels npm apt images cloud scanners releases layers proxies` |
| the bookkeeping | NEW `polari-jenkins/cache-manifest.py` (~230 lines) | `put touch get list prune sweep report report-show`. **A real file, not a heredoc** — the §70/§71 gotcha (`python3 - <<'PY'` feeds the SCRIPT on stdin) twice bit this codebase; everything takes argv |
| the manifest shape | `<cache>/<area>/MANIFEST.json` | ONE index per area, one RECORD per entry. A per-entry sidecar file would double the inode count of a wheelhouse — the cache is supposed to shrink work, not create it. Documented at the top of the file |
| **the knobs** | `device.sh` (`DEVICE_KEYS` 21 → **26**), `device.env.example`, `device_validate_cache`, `device_validate_route_target` | `CI_CACHE=on\|off` (default on) · `CI_CACHE_DIR` (default `<pool>/cache`) · `CI_CACHE_MAX_GB=40` · `CI_CACHE_PROXIES=off\|on` · `CI_ROUTE_TARGET` |
| the one deleter | `retention.sh` — `prune` gained a `grep -vx cache` exemption + a line saying so; NEW `cache-prune [--older-than DAYS]` | `prune` walked `ls -1dt */` of the pool. `cache` matched. It would have deleted the whole cache with the third-oldest version — found by writing the test, not by reading |
| **pip** | `app_deb_builder._fetch_wheels` (+`POLARI_WHEEL_CACHE`, `POLARI_PIP_INDEX_URL`); `polari-framework/Dockerfile` | the builder now passes `--find-links <cache>/wheels` and copies what it fetched back. The Dockerfile gained `ARG PIP_INDEX_URL=` / `ARG PIP_FIND_LINKS=` and a **bind mount from the named build context `wheels`** |
| the wheelhouse, optional | `polari-framework/Dockerfile`: `FROM scratch AS wheels` | the trick that makes it optional: a named build context OVERRIDES a stage of the same name, so `--build-context wheels=<dir>` supplies it and a plain `docker build` / `docker compose build` binds the empty `scratch` stage and pip falls straight through. No flag anyone must remember |
| npm | `polari-platform-angular/Dockerfile.prod` **and** `Dockerfile` | `.prod`: `# syntax` moved to line 1, `ARG NPM_CONFIG_REGISTRY=`, `--mount=type=cache,target=/root/.npm`, **`npm ci --prefer-offline`** (lockfileVersion 3, verified in sync with package.json). The DEV `Dockerfile` — which is what `docker compose build frontend` and therefore the release job actually build — got the same ARG and `--prefer-offline`, keeping `npm install` |
| apt | `build-offline-bundle.sh` (+`POLARI_APT_CACHE`) | the closure's `xargs curl` loop now copies a cached deb and downloads only the misses, into the cache, and prints `[cache-report] apt cached_bytes=… fetched_bytes=…`. Unset = the old behaviour, byte for byte |
| base images | `cache.sh images warm\|save`, used by `build-images.sh` | `docker save`/`load`, digest-checked and idempotent: an image already on the daemon is neither saved nor loaded again |
| **docker layers** | NEW `polari-jenkins/build-images.sh` | `DOCKER_BUILDKIT=1`; with buildx → `docker buildx build --cache-from/--cache-to type=local,dest=<cache>/layers/<image>` + `--build-context wheels=…`; **without buildx → plain `docker compose build`, one line saying so, and the build still works** |
| the cloud image | `isle/throwaway.sh` | moved from `pool/images` to `<cache>/cloud`, so `retention.sh prune` can no longer take it. An image an earlier run left in `pool/images` is **adopted (moved), not re-downloaded**. `cache.sh` + `cache-manifest.py` now travel over the ssh hop so an ssh target caches on its own disk |
| scanners | `<cache>/scanners` | the directory and its one-line description, reserved for the scanning plan's Trivy DB. Nothing else — by the brief |
| **the report** | every build stage → `pool/<version>/cache-report.json`; `cache.sh report\|report-show` | bytes from cache vs bytes fetched, and seconds, per area, plus a `hit_rate`. It rides in `PipelineRun.summary` (the `cicd-sync.sh run` call in both Jenkinsfiles) and in `ReleaseRecord.cache_report_json` |
| the doctor | `doctor.sh` §"the offline cache" + §"app mode" | cache size vs `CI_CACHE_MAX_GB`, the last hit rate, tier-two reachability; and in app mode: `CI_APP_NAME`/`CI_APP_REPO` WARNs, `release:<tag>` **resolved live** or a WARN naming the tag, `build` as an INFO |
| **tier two** | NEW `docker-compose.proxies.yml` + `cache-proxies.sh` + `cache/verdaccio-config.yaml` | `registry:2` pull-through · devpi · verdaccio · apt-cacher-ng. 127.0.0.1 only, outbound-only, no publish path, volumes under the cache dir. `up` REFUSES while `CI_CACHE_PROXIES=off`. The pipeline only calls `cache.sh build-args`, which probes and returns nothing when they do not answer |
| **the setup question** | `setup/steps/01-role.sh` (title now "what this pipeline maintains, and this device's role") | `setup_ask_mode` runs BEFORE the role arithmetic: suite\|app → app name (validated against `modules/<name>/polari-app.json`) → repo (offered a shallow clone into `<pool>/apps/<name>`, refused unless it carries a `polari-app.json` at its root — `pol project` conventions) → core (`release:latest` \| a pinned tag \| `build`, resolved live) → `CI_ROUTE_TARGET` (the upstream owner refused at the prompt) → the `core; <app>` stage default |
| **the pulled core** | NEW `polari-jenkins/isle/core-artifacts.sh` (~180 lines) | `resolve \| fetch \| status`. `release:latest` = the newest release that actually CARRIES debs. Fetch verifies every deb against the release's `SHA256SUMS` and **empties the directory on any mismatch**; a release with no SHA256SUMS is cached with an `UNVERIFIED` marker and said so. Images: `IMAGES_FROM` when ghcr has the tag, else the literal line *"images not published for <tag> — the isle test installs from the debs only"* |
| the ONE providers reader | `polari-cli/scripts/lib/providers.sh` — NEW `release_asset_urls <repo> <tag> [suffix]`; `release_deb_urls` now delegates to it | one generalisation, no second GitHub reader. `pol prod`'s path is unchanged |
| the pipelines | `Jenkinsfile.dev-build` · `.release` · `.isle-test` | a core-artifacts stage in app mode; the deb stage exports `POLARI_WHEEL_CACHE`/`POLARI_APT_CACHE`; images go through `build-images.sh`; in app mode the release builds ONLY the app deb and skips images entirely; `release.json` gained `mode`, `appName`, `routeTarget`, `testedAgainst`, `cacheReport` |
| **the release rules** | `routes/_lib.sh` | `release_assets` in app mode returns the ONE app's deb — not the core it was tested against, not another app a stage tested here. `route_target_state()` is a second HARD gate beside the release rule: no target, or the upstream owner, → every route DRY. `DRY_RUN=false` overrides neither |
| the rows | `modules/cicd/objects/cicd/PipelineDevice.py` (+5 columns), `ReleaseRecord.py` (+2), `custom/cicd_validate.py` (`validate_cache`, `validate_route_target`, 5 more `device_env` pairs, `settings_from_device`), `custom/cicd_ingest.py`, `cicd-sync.sh` | the five settings keys are RENDERED, so a `pull` ADDS them to an older `device.env` instead of erasing them — and `CI_CACHE` renders `on` by default, so a pull from a core that never heard of ci-9 cannot silently turn a device's cache off |
| the CLI | `polari-cli/scripts/jenkins.sh` (`cache`, `core-artifacts` + help), `lib/jenkins-device.sh` (`jd_cache`) | `pol jenkins cache status\|prune\|proxies\|dir\|report` · `pol jenkins core-artifacts resolve\|fetch\|status` |
| compose | `polari-jenkins/docker-compose.yml` | `cache.sh`, `cache-manifest.py`, `cache-proxies.sh` mounted; `CI_CACHE*`, `CI_MODE`, `CI_APP_*`, `CI_CORE_SOURCE`, `CI_ROUTE_TARGET` passed through |
| docs | `polari-jenkins/README.md` (two new sections + the retention and tests paragraphs), `modules/cicd/README.md`, `pol jenkins help` | |
| tests | `polari-jenkins/selftest.sh` **235/235** (was 152/152, +83); `modules/cicd/cicd_selftest.py` **140/140** (was 128/128, +12) | still no docker, libvirt, sudo or network |

---

### The real outputs (pol-core, 2026-09-19)

`pol jenkins cache status` — a device that has never built:

```
polari-jenkins cache — offline-first builds (ci-9). CI_CACHE=on
directory: /home/user/Desktop/polari-suite/polari-jenkins/pool/cache

nothing cached yet — the first build fills it.
```

`pol jenkins cache prune --older-than 30` (after `cache status` and
`core-artifacts status` had created two area directories):

```
[cache] prune — dropping only entries unused for more than 30 day(s)
[cache] (retention.sh prune never touches this directory; this verb is the only deleter)
-- cloud
   0 removed, 0.0 MB freed, 0 kept (no readable last_used)
-- releases
   0 removed, 0.0 MB freed, 0 kept (no readable last_used)
[cache] now 0.0 GB
```

`pol jenkins doctor` — the two new sections (suite mode, 9 WARN, exit 0):

```
-- the offline cache — build once, reuse (ci-9)
OK    cache                      — nothing cached yet (…/polari-jenkins/pool/cache) — the first build fills it
OK    cache hit rate             — no cache-report.json yet — every build stage writes one; until a real run
                                   the savings are EXPECTED, not measured
OK    cache proxies              — tier two off (the default) — tier one is a directory and needs nothing running
```

…and with an app-mode `device.env` (a scratch file; pol-core's own is
untouched):

```
-- app mode — ONE app, a pulled core, YOUR routes
OK    CI_APP_NAME                — household
OK    CI_APP_REPO                — https://example.invalid/polari-module-household.git
OK    core source                — release:latest → polari-v2026.09.12 (fetched once into the cache:
                                   bash polari-jenkins/isle/core-artifacts.sh fetch)
```

**That last row is a LIVE resolution against the real GitHub API**:
`pol jenkins core-artifacts resolve` printed `polari-v2026.09.12` — the
newest published Polari release that actually carries `.deb` assets. It is
the first time `CI_CORE_SOURCE=release:latest` has ever meant a real tag.

`pol jenkins setup --report` — step 1, suite mode:

```
══ step 1/8 — what this pipeline maintains, and this device's role
   [ok]   maintains: the whole Polari suite — core, apps and images are all built here
   [ok]   measured here: 15.5 GB RAM, 4 vCPU, 14 GB free: controller + builds serialised — not a
          concurrent isle VM; put the isle on another device (pol jenkins target ssh <alias>) or add RAM
   …
```

…and step 1 with the app-mode scratch `device.env`:

```
══ step 1/8 — what this pipeline maintains, and this device's role
   [ok]   maintains: ONE Polari app — household
   [ok]     the module is in this checkout (modules/household/polari-app.json)
   [ok]     repository: https://example.invalid/polari-module-household.git
   [ok]     core: release:latest (pulled, never rebuilt)
   [ok]     releases go to: some-developer
   …
   [ok]     the core release is resolved and fetched once per tag: bash polari-jenkins/isle/core-artifacts.sh status
```

`pol jenkins isle status` — the cloud image has moved into the cache:

```
base img: …/polari-jenkins/pool/cache/cloud/ubuntu-24.04-server-cloudimg-amd64.img (not cached)
```

(The wireless interface name that appears in the doctor's `wired IPv4` row is
written `<lan>` here; no address, hostname or e-mail is in any tracked file.
The app-mode `device.env` above is a scratch file under the session
scratchpad — pol-core's real one is unchanged and gitignored.)

### The `docker build --check` runs

```
cd polari-rf-node
DOCKER_BUILDKIT=1 docker build --check -f polari-framework/Dockerfile polari-framework
DOCKER_BUILDKIT=1 docker build --check -f polari-platform-angular/Dockerfile.prod polari-platform-angular
DOCKER_BUILDKIT=1 docker build --check -f polari-platform-angular/Dockerfile      polari-platform-angular
```

Both frontend files: *"Check complete, no warnings found."* The backend: the
two **pre-existing** `UndefinedVar` warnings on `$LD_LIBRARY_PATH` (lines 72
and 143, untouched by this slice) and nothing else — the `FROM scratch AS
wheels` stage, the `--mount=type=bind,from=wheels` and the two new `ARG`s all
parse. **No image was built** (the brief's dry-checks-only rule), so the
named-context override is proven to PARSE, not to RUN — see OWED 1.

### selftests

```
polari-jenkins selftest — no docker, no libvirt, no sudo, no network
-- mint-tag · routes · preflight · doctor · setup · stages · modes
-- cache: the manifest, prune by last_used, the report arithmetic, the network fallback
-- app mode: the setup question, the pulled core, and a release of ONE deb to YOUR routes

235/235
```

```
cd polari-rf-node/polari-framework && PYTHONPATH=.:modules python3 modules/cicd/cicd_selftest.py
140/140 checks passed
```

83 new shell cases:

* **7** the manifest (the four fields the brief names, plus `bytes`; an absent
  entry exits 1; `list` is one line per entry);
* **6** `cache-prune` (a 90-day-old entry dropped and NAMED with its age, the
  file really gone, a fresh entry untouched, an entry whose `last_used` is
  unreadable **KEPT** rather than guessed at, nothing inside the window
  touched);
* **4** `retention.sh` (prune says the cache is EXEMPT, the cache directory
  survives `POOL_KEEP=0`, `cache` is not listed as a pool version,
  `cache-prune` is the cache's one deleter);
* **6** the report arithmetic (hit rate = cached/(cached+fetched) = 0.8,
  bytes and seconds accumulate across stages, the sentence, the TOTAL row, a
  missing report reported rather than invented);
* **5** the network fallback (`CI_CACHE=on` offers `--find-links`, `off` adds
  **nothing**, `PIP_INDEX_URL` appends only when set, a miss is a miss not a
  refusal, `off` says so and hands the build back to the network);
* **5** `cache status` (the directory, every area, what each is for including
  the reserved Trivy home, the EXPECTED-not-measured honesty, and the OFF
  wording);
* **7** tier two (off unless the knob, no build-args, `up` refuses and says
  nothing was started, the licences stated, the one that is NOT verified said
  so, loopback-only ports, nothing published on all interfaces);
* **6** the device knobs through the doctor;
* **10** the setup's mode question in `--report` (step 1 asks what the
  pipeline MAINTAINS before anything else; app mode names the app, the repo,
  the core and the target; `build` is an INFO; a missing repo WARNs; an
  upstream target is refused in the settings too);
* **6** `core-artifacts.sh resolve` against a fixture release list
  (`release:latest` → the newest release that CARRIES debs, skipping a newer
  one with no assets; an exact tag verified; a tag with no debs REFUSED and
  named; no silent fall back to building core; `build` resolves to `build`
  and `fetch` then says it has nothing to fetch);
* **11** app-mode release filtering (only the app's deb, never the core,
  never another app; the line naming the one deb and its target; no target →
  DRY naming why; the upstream owner → DRY; `DRY_RUN=false` cannot force
  either; suite mode unaffected; the mirror carries the RESOLVED
  `tested_against`, the `route_target` and the cache report);
* **10** the Dockerfiles (the `scratch` default for the wheels context, the
  pip cache mount kept, `PIP_INDEX_URL` honoured, the npm cache mount,
  `--prefer-offline`, `NPM_CONFIG_REGISTRY`, and `# syntax` as line 1 of
  both).

12 new python checks: the three `CI_ROUTE_TARGET` verdicts (absent in app
mode = FAIL, the upstream owner = FAIL, set in suite mode = WARN), the six
cache verdicts (on/off/unknown, a non-numeric max, proxies on/off, the empty
dir explained), and three on `device_env` (24 keys, all five ci-9 keys
rendered, `CI_CACHE=on` by default so a pull cannot silently disable a cache).

---

### The numbers, honestly

**Nothing is measured yet.** No pipeline run has happened on this box — there
is no `/dev/kvm`, no controller is up, and the brief forbade building
anything. So every figure below is an EXPECTATION with its reasoning, and the
doctor and `cache status` both say so in those words until a real
`cache-report.json` exists.

| area | what is reused | why it should help |
|---|---|---|
| pip wheels | the offline deb's whole wheel payload | `_fetch_wheels` already had a per-module TTL directory; the cache makes it **shared across modules and across runs**, and pins nothing new |
| npm | `node_modules` for the Angular build | the single biggest download in the suite; `--prefer-offline` + a BuildKit cache mount means the second build asks the registry only for changed packages |
| apt | the distro closure of the offline medium (~dozens of debs) | it barely moves between runs; today every `--flavor offline` build re-downloads all of it |
| base images | `python:3.12-alpine`, `node:20`, `nginx:alpine` | only helps a cold daemon, which is exactly what a pruned CI box is |
| docker layers | both Polari images | the largest single win when buildx is present, and nothing when it is not |
| cloud image | the ~600 MB Ubuntu qcow2 | it was already cached — but under `pool/images`, where `retention.sh prune` deleted it with the third-oldest version. That was a **re-download per prune**, silently |
| releases | app mode's core debs | fetched once per tag rather than once per run |

The one number that IS real: `release:latest` resolves, live, to
`polari-v2026.09.12`.

---

### Gotchas found and fixed while building

* **`retention.sh prune` would have eaten the cache.** It lists `pool/*/` by
  mtime and drops everything past `POOL_KEEP`. `pool/cache` is a directory in
  `pool/`. The cache would have survived exactly two more releases and then
  vanished — and, being a cache, nothing would have failed; builds would just
  have got slow again for no visible reason. Found by writing the test.
* **`|` cannot appear in a `device.sh` validation message.** `_row` uses `|`
  as its field separator and strips it (`${1//|/ }`), so `"unknown value →
  on|off"` reached the doctor as `on off`. Both new FAIL messages say "on or
  off". The python port is unaffected (different transport) and deliberately
  still reads `on|off`.
* **A log line on stdout ends up inside a captured variable.** The first
  `core-artifacts.sh` printed its progress with `printf` to stdout and
  returned the directory the same way, so `DIR="$(fetch_release …)"` captured
  six lines of prose. Every log line now goes to **stderr**, and `fetch_release`
  sets `CORE_DIR` rather than printing it. The kind of bug that only shows up
  on the first real run.
* **A backtick in a test NAME is a command substitution.** Two selftest
  descriptions containing `` `proxies up` `` and `` `fetch` `` tried to run
  those as commands. Single quotes now.
* **The syntax directive must be line 1.** `# syntax=docker/dockerfile:1`
  placed after the banner comment in `Dockerfile.prod` is an inert comment,
  not a parser directive. Moved.
* **`docker-compose.yml`'s backend/frontend services carry no `image:` key**,
  so a compose build names them after the compose project — which is why
  `Jenkinsfile.release`'s `docker tag prf-backend:staging …` has never been
  able to find them. `build-images.sh`'s buildx path tags them directly.
  Pre-existing, found in passing, fixed on that path only (the compose
  fallback still has the old shape).
* **The brief's premise about the backend Dockerfile was stale**: it already
  had `# syntax=docker/dockerfile:1` and `RUN --mount=type=cache,target=
  /root/.cache/pip`, and the DEV frontend `Dockerfile` already had the npm
  cache mount. What was missing was the wheelhouse, the ARGs, and
  `--prefer-offline` — that is what was added.
* **`--build-context` needs a DEFAULT or it is a flag every caller must
  remember.** `FROM scratch AS wheels` gives the named context a stage to
  fall back to, so `docker compose build` binds an empty directory instead of
  failing to resolve an image called `wheels`.
* **`npm ci` was only safe because the lock is in sync** — checked
  (`lockfileVersion: 3`, zero `package.json` deps missing from the lock root)
  before changing `Dockerfile.prod`. The DEV `Dockerfile` keeps `npm install`
  deliberately: a dev image that dies on a drifted lock is worse than a slow
  one, and `.prod` is where it should fail loudly.
* **`CI_CACHE_DIR` defaults to EMPTY, not to an absolute path.** An absolute
  default would have been wrong over the ssh hop: `throwaway.sh` re-runs
  itself on the isle target, and the cloud image must land on **that** box's
  pool. Empty → `<pool>/cache` → correct on both sides. The same reasoning
  keeps it empty in compose.
* **`release:latest` must mean "the newest release that carries debs"**, not
  "the newest release". The fixture list in the selftest has a newer tag with
  no assets precisely to pin that.

---

### OWED

1. **The named build context has never RUN.** `docker build --check` proves
   the Dockerfile parses; it does not prove that `--build-context
   wheels=<dir>` overrides `FROM scratch AS wheels` on this docker
   (27.3.1 / buildx 0.17.1), nor that a bind mount from an empty `scratch`
   stage behaves. Both are documented BuildKit behaviour and neither could be
   exercised under "docker build of nothing". **First real build must check
   the `pip: N wheel(s) offered from the pipeline cache` line appears.**
2. **A measured before/after has not happened.** It needs a KVM/pipeline box:
   `pol jenkins up`, one `polari-dev-build` with a cold cache, then a second
   with a warm one, and the two `cache-report.json` files side by side. Until
   then every saving in this section is EXPECTED and is labelled so in the
   doctor, in `cache status` and in the README.
3. **`apt-cacher-ng`'s licence is not verified.** No network lookup was made
   and its `COPYING` was not read. It ships in Debian and upstream calls it
   BSD-style; that is hearsay. Nothing depends on the answer yet (the service
   is off, nothing starts it, no image is redistributed, and running a
   service is not linking), but the licence gate must read the file before
   tier two is ever on by default.
4. **Tier two has never been started.** Four compose services, `--check`ed as
   YAML and as a compose config, never run. `devpi` and `apt-cacher-ng`
   install their package on first start (deliberately, rather than trusting a
   third-party image nobody audited) — that first start needs network and has
   not been proven.
5. **`core-artifacts.sh fetch` has never fetched.** `resolve` is live-proven
   against the real API; `fetch` is proven only against the selftest's curl
   shim. The SHA256 verification path, the `UNVERIFIED` marker and the
   `images not published for <tag>` line are all untested against a real
   release.
6. **App mode's isle-test body is still ci-3.** The stage now knows WHICH
   core to install and records `tested_against`, but the install + selftest
   cycle inside the guest is still the marked TODO — so every result is
   `skipped`, `core_ok` stays false, and an app developer's deb cannot ship
   either. ci-3 remains the blocker for everything downstream.
7. **The app checkout is cloned by `setup`, not by the pipeline.** `pol
   jenkins setup` clones `CI_APP_REPO` into `<pool>/apps/<name>`; the release
   job's app-mode branch builds the app deb from the modules in the CHECKOUT
   (`app-debs.sh`), not from that clone. For an app that lives only in its own
   repo the pipeline still needs a "pull the app project and point
   `POLARI_FRAMEWORK_DIR`/the module path at it" step. Named here rather than
   half-built.
8. **`PipelineDevice` gained five columns and `ReleaseRecord` two** — a
   deployed core with existing rows will read the defaults for them until
   something writes. No migration exists (none has ever existed for these
   rows); the first `push` from a device fills them.
9. **The `npm` and `scanners` cache areas are empty shells.** `npm` is only a
   home for tier two's verdaccio volume (tier one's npm reuse is the BuildKit
   cache mount, which BuildKit owns), and `scanners` is a reserved directory
   by the brief. Neither is a bug; both would read as one without this line.
10. Nothing is committed, nothing is pushed. `polari-jenkins/device.env` and
    `SETUP_STATUS.md` on pol-core are gitignored; `device.env` was not
    modified (the app-mode run used a scratch file).

## §73 — ci-10: the product's own uninstall as the teardown test, the host wipe, and the leak check

His ask, 2026-09-19: *"we need to ensure we are capable of wiping the registered
ssh location and removing the isle there so we can deploy new ones each time
without causing memory issues, and we should be checking in between to make sure
we are not missing things and having leaks between things as well"*

His addendum, same day: *"we should be using the normal isle wiping functionality
so that it acts as a de jure test of that as well."*

Built on `dev`, **uncommitted**. Nothing was deployed, no VM was started or
destroyed, no container was brought up, `pol jenkins up` was never run, nothing
was pushed. Against `isle-core` only READ-ONLY commands ran: two
`leakcheck` snapshots, one `preflight --isle`, one `wipe --dry-run` (which
removes nothing by construction) and one `isle status`.

---

### The shape: the teardown is THREE things, and they answer three questions

His addendum splits what was going to be one layer into two, and they must stay
two, because they are different kinds of failure:

| layer | verb | the question | whose failure | what it gates |
|---|---|---|---|---|
| 1 | `pol jenkins isle uninstall` | can the **PRODUCT** hand this machine back? | the product's | **the release** — `core_ok` requires a `clean` verdict |
| 2 | `pol jenkins isle wipe` (and the tail of `down`) | remove what **WE** made, and nothing else | — | nothing; it *is* the cleanup |
| 3 | `pol jenkins isle leakcheck check` | did anything of ours survive the wipe? | the **pipeline's** | **the next stage** — a persistent leak stops the run |

A dirty hand-back blocks a release and does not stop the run. A leak stops the
run and does not block a release. Conflating them would let our own mess look
like a product defect, and a product defect look like housekeeping.

---

### What, and where

| what | where | notes |
|---|---|---|
| **layer 1** — the product's own uninstall, run as a TEST | `polari-jenkins/isle/guest-uninstall.sh` (new, sourced by `throwaway.sh`), verb `throwaway.sh uninstall [--stage N] [--json <path>]` | ONE fenced snippet over the per-run key: `sudo ISLE_CONFIRM_DELETE=yes isle uninstall --everything --force` (the real path — backup → `destroy --purge` → `network-handback` → volumes → apt purge of the family → its own zero-footprint verify, `Isle-Mesh/isle-cli/scripts/uninstall.sh`), then `isle uninstall --verify` when the CLI survived, then the **hand-back proof**. Nothing here re-implements the product's checks; it reads its words. |
| the hand-back proof (his rule) | same file | five rows: a default route · public DNS resolves · `apt-get update` succeeds · a network manager is active and owns the interfaces · NetworkManager has an active connection (`n/a` on a server cloud image, said so) · plus `/etc/isle-mesh`, `/usr/share/isle-mesh`, `/etc/polari` gone |
| the verdicts | `uninstall_verdict` in `results.json`, `uninstall-<stage>.json` | `clean` \| `dirty` \| `failed` \| `skipped`. **`skipped` is not a pass** — nothing was installed, so the hand-back was never exercised. Until ci-3 lands that is every stage's verdict, and therefore nothing is releasable. Honest before convenient. |
| **layer 2** — the scoped wipe | `polari-jenkins/isle/wipe.sh` (new), verb `throwaway.sh wipe [--dry-run]`; `down` now ends in it | domain (`destroy` → `undefine --nvram --remove-all-storage`, with the older forms as fallbacks) · tagged qcow2/img/raw/iso under the images dir and the pool's `ci-isle` tree (bytes reported) · tagged libvirt storage volumes in every pool · a per-run libvirt network · a stray `qemu-system` still holding the guest · `/tmp` + `/var/tmp` leftovers · the per-run ssh key (shredded) · the run dir |
| the scope rule | `wipe.sh` `wipe_ours()` | ours = the configured `CI_ISLE_VM_NAME`, or anything carrying `CI_WIPE_TAG` (`polari-ci-`). Everything else it SEES is printed under **"found but NOT removed"**, named, and left. A VM name that does not carry the tag gets a loud line saying the scoping then rests on that exact name alone. |
| **layer 3** — the leak diff | `polari-jenkins/isle/leakcheck.sh` (new): `baseline \| check \| report \| snapshot` | ONE read-only snippet through `device.sh`'s `on_target`, so `local` and `ssh` are the same code path. Reads: VMs · libvirt networks · storage volumes · files (name + bytes) · the Polari footprint via `isle/footprint.sh` → `os-security/inventory.sh` · mounts (loop/iso9660/nbd) · listening TCP+UDP · processes matching `qemu\|libvirt\|isle\|polari` with RSS · `MemAvailable` · swap used · free disk on the images dir and `/` |
| what counts as a leak | `leakcheck.sh` `_diff` | anything NEW since the baseline (VM, file, volume, network, mount, port, process identity, footprint item), a process count that GREW, `MemAvailable` more than `CI_LEAK_RAM_TOLERANCE_MB` (512) below the baseline, or free disk more than `CI_LEAK_DISK_TOLERANCE_MB` (1024) below it. **exit 5.** |
| what is explicitly NOT a leak | same, and it is printed every run | the offline cache (`<pool>/cache` — it holds the base image on purpose, ci-9) · `<pool>/isle-test` (the RESULTS live there; a diff that counted its own bookkeeping would leak by running) · a thing that ENDED · anything the baseline already had |
| the pipeline loop | `pipelines/Jenkinsfile.isle-test` | `leakcheck baseline` ONCE → per stage: `up` → `verify` → (ci-3 TODO) → **`uninstall`** → `down` (which wipes) → `leakcheck check`. A LEAK does not abort: it re-wipes once, re-checks, and if it persists records `leak_verdict: leaked-after-rewipe` and STOPS before the next stage (which would start on a dirty host — the log says so), unless `CI_LEAK_POLICY=continue`. |
| the coupling | `routes/_lib.sh` `tested_state()`, the Jenkinsfile, and `cicd_ingest.isle_test_row` | three doors, same rule: `core_ok` AND a `clean` uninstall. A `results.json` that claims `core_ok` with **no** uninstall verdict is refused as "an unfalsifiable claim (re-run polari-isle-test)". |
| the preflight | `isle/preflight.sh` | new row **`residue from an earlier run`**: any `polari-ci-*` VM, network, file or `qemu-system` process on the target = FAIL naming `pol jenkins isle wipe`. The pool and the cache carry the tag by design and are not residue. |
| the doctor | `doctor.sh` | two new rows from the newest pool version: the last **leak verdict** (with the signed RAM/disk deltas) and the last **uninstall verdict** — the latter saying in words that a dirty hand-back is *a FAILURE OF THE PRODUCT, not of the pipeline*. |
| the row class | `modules/cicd/objects/cicd/IsleTestResult.py` | `+ uninstall_verdict, uninstall_json, leak_verdict, leaks_json, ram_delta_mb, disk_delta_mb`, plus `UNINSTALL_VERDICTS` / `LEAK_VERDICTS` as declared tuples |
| the mirror | `cicd-sync.sh isle-test`, `custom/cicd_ingest.py`, `cicd_api.py` `/api/cicd/results` | the fields travel; the door ANDs `core_ok` with a clean uninstall on the way IN too, so no re-post can claim a core for an isle that could not leave |
| the page | `cicd_page.py` (`cicd-runs`, `cicd-devices`) | configured columns only — `uninstall_verdict, uninstall_json, leak_verdict, leaks_json, ram_delta_mb, disk_delta_mb`. No new component, no raw-JSON panel (his rule). |
| the CLI | `polari-cli/scripts/jenkins.sh` | `pol jenkins isle uninstall [--stage N] [--json f]` · `isle wipe [--dry-run]` · `isle leakcheck baseline\|check\|report\|snapshot` ; `pol jenkins help` carries them |
| the knobs | `device.env.example` (documented as ENVIRONMENT knobs, deliberately NOT device.env keys) | `CI_WIPE_TAG=polari-ci-` · `CI_LEAK_RAM_TOLERANCE_MB=512` · `CI_LEAK_DISK_TOLERANCE_MB=1024` · `CI_LEAK_POLICY=stop` |
| docs | `polari-jenkins/README.md` | a "Wiping between stages, and checking for leaks (ci-10)" section with the three-layer table |
| tests | `polari-jenkins/selftest.sh`, `modules/cicd/cicd_selftest.py` | **235/235 → 316/316** and **140/140 → 154/154** |

---

### The real reading — `isle-core`, read-only, 2026-09-19

`pol jenkins isle leakcheck baseline` then `check --stage 1`, with
`CI_ISLE_TARGET=ssh CI_ISLE_SSH_HOST=isle-core` and `CI_LEAK_DIR` pointed at a
scratch directory (never the pool). isle-core carries a **live** isle, so this is
the reader working against a real target, not a fixture:

```
leak baseline taken BEFORE the first stage: <scratch>/leak-baseline.json
target: ssh:isle-core   vm: polari-ci-isle
EXCLUDED: /var/tmp/polari-ci-pool/cache — the offline cache holds the base image on purpose (ci-9); it is never a leak
read: footprint 11, net 1, port 2, proc 8, vm 1
     MemAvailable 5195 MB, images-dir free 844978 MB, / free 844978 MB
```

```
leak check — stage 1, target ssh:isle-core, against the baseline of 2026-09-19T10:22:26
EXCLUDED: /var/tmp/polari-ci-pool/cache — the offline cache holds the base image on purpose (ci-9) — never a leak
tolerances: RAM 512 MB, disk 1024 MB (a reading below them is a LEAK: memory that did not come back)

kind               item                                           baseline         now              verdict
------------------ ---------------------------------------------- ---------------- ---------------- -------
footprint item     /etc/isle-mesh                                 present          present          ok
footprint item     /etc/polari                                    present          present          ok
footprint item     /usr/share/isle-mesh                           present          present          ok
footprint item     checkouts:1                                    present          present          ok
footprint item     containers:4                                   present          present          ok
footprint item     debs:1                                         present          present          ok
footprint item     guests:1                                       present          present          ok
footprint item     images:5                                       present          present          ok
footprint item     isle-cli                                       present          present          ok
footprint item     units:4                                        present          present          ok
footprint item     volumes:1                                      present          present          ok
libvirt network    default                                        present          present          ok
listening port     tcp                                            <lan>:22         <lan>:22         ok
listening port     udp                                            <lan>:546        <lan>:546        ok
process            bash                                           x1, 2 MB RSS     x1, 2 MB RSS     ok
process            dnsmasq                                        x2, 2 MB RSS     x2, 2 MB RSS     ok
process            isle-host-agent                                x3, 5 MB RSS     x3, 5 MB RSS     ok
process            libvirtd                                       x1, 21 MB RSS    x1, 21 MB RSS    ok
process            mesh-mdns-broad                                x2, 3 MB RSS     x2, 3 MB RSS     ok
process            python3                                        x1, 31 MB RSS    x1, 31 MB RSS    ok
process            qemu-system-x86                                x1, 1042 MB RSS  x1, 1042 MB RSS  ok
process            qemu-system-x86(openwrt-isle-router)           x1, 94 MB RSS    x1, 94 MB RSS    ok
VM                 openwrt-isle-router                            present          present          ok
memory             MemAvailable (did the RAM come back?)          5195 MB          5223 MB          ok
disk               free on the images dir                         844978 MB        844978 MB        ok
disk               free on /                                      844978 MB        844978 MB        ok
memory             swap used                                      1043 MB          1043 MB          ok

CLEAN: nothing new survived the wipe. RAM delta +28 MB, images-dir disk delta +0 MB — the memory came back.
```
(exit 0. Two readings with nothing in between must diff clean, and they do —
including the 1 GB qemu of isle-core's own router guest, which is *present in the
baseline* and therefore not a leak. That is the whole design: the diff measures
what WE left, never what the device carries.)

`pol jenkins isle wipe --dry-run` against the same live isle — the "would NOT
remove" list is the point of the exercise:

```
[throwaway:polari-ci-isle] wipe — scope: the VM 'polari-ci-isle' and anything tagged 'polari-ci-'  (DRY RUN — nothing is removed)

removed: nothing — the target carries no residue of this pipeline (idempotent: a second wipe says exactly this)

found but NOT removed (no 'polari-ci-' tag — this wipe never touches what it did not make):
  VM openwrt-isle-router (not ours — no 'polari-ci-' tag)
  pid 852395 (a qemu process that is not ours — left running)
  pid 852396 (a qemu process that is not ours — left running)
  pid 3353907 (a qemu process that is not ours — left running)
  leftover /tmp/polari-ci-isle.862278 (it holds the pool, the offline cache or this very run — left alone)
  leftover /var/tmp/polari-ci-pool (it holds the pool, the offline cache or this very run — left alone)
the offline cache (/var/tmp/polari-ci-pool/cache) is EXCLUDED by design — it holds the base image on purpose (ci-9)
```

`pol jenkins preflight --isle` against isle-core, the new row:

```
no VM named polari-ci-isle         none                   none         PASS
residue from an earlier run        none                   none         PASS
                                     ↳ nothing on the target carries the polari-ci- tag
device is clear of Polari          NOT clear              nothing      FAIL
```

(No LAN address, hostname or e-mail is written anywhere: the config carries an
ssh **alias**, and the two link-local port rows above are rendered `<lan>` here.)

---

### Gotchas — three of them found LIVE, and two were real bugs

1. **`throwaway.sh` had never actually worked over ssh.** The first real
   `pol jenkins isle wipe --dry-run` against isle-core died with
   `throwaway.sh: /tmp/device.sh: No such file or directory`. On an ssh target
   the script and its libraries are scp'd into ONE directory, so `J="$HERE/.."`
   is whatever `/tmp` happens to be — but `device.sh` is the *sibling*.
   `cache.sh` had always resolved itself sibling-first; `device.sh` had not.
   ci-7 only ever exercised the LOCAL path, so the break was latent.
   **Fixed:** prefer `$HERE/device.sh`, fall back to `$J/device.sh`.

2. **The wipe would have removed its own working directory, and the pool.** The
   `/tmp` + `/var/tmp` tag globs matched `/tmp/polari-ci-isle.<pid>` (the
   directory the hop had just scp'd the script into — an `rm -rf` of its own
   cwd mid-run) and `/var/tmp/polari-ci-pool` (the POOL, **which contains the
   offline cache**). The cache exclusion did not save either: neither path is
   *inside* the cache. **Fixed:** a `_protected()` predicate — a path that IS or
   CONTAINS the pool, the cache root, `$HERE` or `$PWD` is named and left alone.
   Selftested in four directions so it cannot come back.

3. **The preflight's residue probe matched itself.** Its own `ps | grep` command
   line carries both `qemu-system` and `polari-ci-`, so a clean isle-core read as
   having residue. **Fixed:** the snippet carries a marker (`: ci-10 residue
   probe`) and filters it out — the same marker the selftest's ssh shim keys on.

4. **The §70 heredoc trap, again.** `python3 - <<'PY'` feeds the SCRIPT on
   stdin, so the uninstall analyser could not also read the guest log from a
   pipe: every verdict came back `skipped`. The log now goes through a FILE and
   an argv path. Third time this has bitten in this sub-project (cicd-sync.sh
   §70, and it is called out in both files now).

5. **The leak diff leaked by running.** On a device with no `/var/lib/libvirt`
   the images dir falls back to the pool itself, and `find` then swept in
   `<pool>/isle-test/leak-baseline.json` and every `leak-check-N.json` — each a
   "new file that survived the wipe". Excluded by PATH, not by name, and said so
   in the header.

6. **`net-list --all --name` contains `list --all --name`.** The selftest's
   virsh shim matched domains for a network query until the patterns were
   reordered. Worth remembering for any future virsh shim.

---

### The numbers

| suite | before | after |
|---|---|---|
| `polari-jenkins/selftest.sh` (no docker, libvirt, sudo or network) | 235/235 | **316/316** |
| `modules/cicd/cicd_selftest.py` | 140/140 | **154/154** |

The 81 new shell checks cover: wipe scoping in both directions (a `polari-ci-*`
disk removed and a `customer-vm` disk named under "not removed", the same for
VMs, networks and storage volumes) · the four protected paths · an idempotent
second wipe · `--dry-run` removing nothing · the leak diff on a REAL local target
(a new file is a LEAK with exit 5, a file that is gone is not, a file appearing
in the cache is not counted at all) · the RAM/disk arithmetic against the
tolerances, signed · all five uninstall verdict paths including "skipped is not a
pass" · the release-rule coupling in four states (clean → ARMED, dirty → DRY
naming the product's own finding, skipped → DRY, absent → "predate") · the
preflight residue row in both directions · the doctor's two new rows. The 14 new
python checks cover the row's two vocabularies, the ingest's `core_ok ∧ clean`
coupling, that a leak is recorded but never blocks a release, that an unreadable
delta becomes 0 rather than crashing the mirror, and that the page shows it all
as **configured columns**.

---

### OWED

- **The first real `up → uninstall → down → wipe → leakcheck check` cycle on a
  KVM box.** Everything above is proven in four places — the selftests, the
  scripts' own logic, a read-only reading of a live isle, and a dry-run wipe
  against it — but **no throwaway VM has ever been created**. pol-core has no
  `/dev/kvm`; isle-core has KVM but is somebody's real isle (the preflight FAILs
  it on purpose) and lacks `virt-install`. The cycle needs a third box, or
  isle-core knowingly borrowed with `virt-install` installed.
- **What "the memory came back" measures, measured.** The `+28 MB` above is two
  readings of an idle machine. The number that matters is
  `MemAvailable(after wipe) − MemAvailable(before stage 1)` across a real 4 GB
  guest's life, and whether 512 MB is the right tolerance once qemu, page cache
  and libvirt have all had their turn. Expect to tune `CI_LEAK_RAM_TOLERANCE_MB`
  after the first real run, and record the observed value here.
- **A real `dirty` verdict.** Every uninstall path is unit-tested, but the
  product's own `isle uninstall --everything` has never run inside a throwaway
  guest. Until ci-3 installs something, every stage is `skipped` — which is why
  the release rule currently publishes nothing.
- **A deliberate leak, on purpose.** Nobody has yet left a VM behind and watched
  the pipeline catch it, re-wipe, fail again, and stop the next stage. That is a
  half-hour test once a KVM box exists: `up`, kill the wipe, `leakcheck check`.
- **`isle rescue network` and the hand-back JOURNAL do not exist yet.** His
  2026-09-13 rule wants an install-time journal replayed in reverse and an
  offline `isle rescue network`; the product today has
  `network-handback.sh` + `uninstall --verify` and no journal. The hand-back
  proof here is therefore *our* five checks against the product's behaviour, not
  a reading of the product's own journal. When the journal lands,
  `guest-uninstall.sh` should read IT and stop deriving the proof itself.
- **The uninstall verdict is stage 1's only** in `results.json.core_ok`, matching
  how `core_ok` already worked. If a later stage's hand-back goes dirty while
  stage 1's was clean, the release rule will not see it. Decide whether that
  should be ALL stages (probably yes) once more than one stage runs for real.
- Nothing is committed and nothing is pushed.

## §74 — ci-11: the pipeline as a desktop app — (a) the setup protocol, the verb allowlist, the page

**His ask (2026-09-19):** turn the Polari pipeline (Jenkins) into a desktop
application "similar to how the isle mesh is working", guiding people through
use like a normal app, using pkexec the way the store shell does, eliminating
the terminal. *"Yes let us go ahead."*

**His rule, the same day:** *"Make sure to keep different pieces logically
separate, like CLI vs JavaFX."*

ci-11a is the half that lives in this repo: the machine protocol, the verb
allowlist, and the Polari page. The Java half (the bridge, pkexec, the deb)
was built concurrently in `polari-app-shell/` against the same contract.

---

### THE THREE LAYERS, AND WHERE EACH BOUNDARY IS

His rule is enforced by *what each file is allowed to know*, not by a comment:

| layer | files | knows | does NOT know |
|---|---|---|---|
| **protocol emission** | `polari-jenkins/setup.sh`, `setup/steps/0N-*.sh`, `setup/json.sh`, `setup/protocol.py`, `doctor.sh --json`, `isle/preflight.sh --json` | the device | that any desktop application exists. No branch on who is calling, no mention of how an elevation is obtained, no Java-shaped output. An action is marked `privileged: true` and names a verb id — that is the whole of it |
| **the allowlist** | `polari-jenkins/shell-verbs.json` (tracked, shipped in the deb), `pol jenkins verbs` | which commands exist, their fixed argv, an anchored regex per `{parameter}` | what a step is, what a page looks like |
| **the page** | `modules/cicd/` (the `setup` ingest kind, `GET /api/cicd/setup`, the `cicd-setup` page) + ONE Angular panel | the protocol and the bridge message names | the CLI. It never composes a command; it names a verb and the shell resolves it |

The grep that proves it: the only occurrences of `pkexec` / `JavaFX` /
`cefQuery` / `PolariShell` anywhere under `polari-jenkins/` are three
quotations of his rule inside comments — not one line of behaviour. And the
Angular panel contains no `exec`/`spawn` and no `pol` invocation except the
*display* strings shown to a person in a browser who has no shell
(`commandFor()`), which are text, not execution.

---

### (a) THE PROTOCOL — `polari-pipeline-setup/1`

```
pol jenkins setup --json                       the whole walkthrough (8 steps)
pol jenkins setup --json --step secrets        recompute one step
pol jenkins setup --json --step role --answer CI_MODE=app
pol jenkins setup --json --run preflight       ONE unprivileged action + its recomputed step
pol jenkins verbs
pol jenkins doctor --json                      polari-pipeline-doctor/1   (NEW — it had none)
pol jenkins preflight --isle --json            polari-pipeline-preflight/1 (protocol field added)
```

**ONE SOURCE OF TRUTH, and it is the interactive path.** Every step's `checks`
come from running that step's own `step_<name>_check` — the very function the
terminal prints — with the four rendering verbs (`check`, `explain`, `howto`,
`where`) *rebound* to record instead of print (`setup/json.sh`). There is no
second implementation of a check anywhere, so terminal and screen cannot
drift. What the interactive path *asks* (the `tui_menu` / `ask_value` calls,
which cannot run unattended) is declared beside it, in the same step file, by
a new `step_<name>_json` per step.

`doctor_check()` was the one place that needed a hand: the doctor's WARN
message is already `"<what is wrong> → <what to do>"`, so it now hands that
second half through as the check's `fix`. One edit, every step benefits.

**Stdout purity is a property of the file, not a promise every future step
has to keep.** Steps print — `stages_print` writes to stdout, a step has a raw
`echo`, a tool chatters. So in `--json` mode stdout is moved out of their
reach for the entire computation (`exec 3>&1 1>&2`), the document is written
to a temp file, and `setup.sh` prints *that file* and nothing else.
(Gotcha found the hard way: a command substitution `DOC="$(json_main …)"`
re-captures stdout inside the subshell and defeats the redirection entirely —
the file handoff is why it works.)

**`--json` never prompts and never runs anything privileged.** `ask` returns
NO unless `--run <id>` named that exact action, which *is* the consent.

**The state rule is stated once**, in `protocol.py`: `done` = every check OK
and every question answered; `blocked` = a FAIL with an undone privileged
action; `skipped` = the step does not apply; `todo` otherwise. The page and
the shell read the field; neither re-derives it.

**First run with nothing:** proven to answer all 8 steps with no `device.env`
and no Polari core running.

### (b) THE ALLOWLIST — `polari-pipeline-shell/1`, 11 verbs

`polari-jenkins/shell-verbs.json`. Fixed argv, anchored regex per parameter,
documented per verb, printed by `pol jenkins verbs`:

`init-device`, `secrets-put`, `apt-install-tools`, `docker-group`, `wired-up`
(privileged) · `doctor`, `preflight`, `setup-step`, `setup-answer`,
`setup-run`, `up` (unprivileged).

No free-form command, no verb taking a path, exactly one verb reading stdin
(`secrets-put`, `stdin: "secret"`). **Validated on BOTH sides:**
`setup/protocol.py` refuses to *offer* an action whose verb is unknown, whose
parameters are undeclared or missing, whose regex is unanchored, or whose
value fails that regex — it lands on the to-do list naming why, and the page
never sees it. The executor validates again where it substitutes.

**Question bindings.** A non-secret question carries
`"action": {"verb": "setup-answer", "params": {"step": …, "key": …, "value": "{answer}"}}`
— `{answer}` is the one placeholder the executor fills with what the person
typed or chose, and the regex is checked there. The binding is *derived* in
`protocol.py` from the question itself, not re-declared per step. **A `secret`
question binds to nothing**: its value goes to `secrets-put` on stdin, through
the executor's own native prompt.

### (c) THE PAGE — `/display/cicd-setup`

* New row class **`PipelineSetupStep`** (mirrored, not settings) + three
  document-level columns on `PipelineDevice` (`setup_blocking`,
  `setup_todo_json`, `setup_at`).
* New ingest kind **`setup`** (six now) and **`GET /api/cicd/setup`**, which
  reassembles the protocol document from the rows and answers `live: false` —
  it is a mirror of the last push, never a live reading, and says so.
* `cicd-sync.sh push-setup` (and `push`, which now does both) posts it. The
  core cannot run `pol`, and should not be able to; only the device can.
* Page `cicd-setup` = the one panel + a structured readiness panel + two
  configured tables (the steps, and secret presence with where-to-get).

**ONE new Angular component, and why it had to be one.** The task said to try
extending the store's bridge component first. It cannot be extended:
`app-isle-store` is a *routed page* with **zero `@Input()`s**, ~460 lines of TS
that fetch the catalogue, hold master/detail state, and carry unrelated
AI-tool binding — retrofitting a `mode` onto it would be a rewrite, and the
result would still be a page, not a panel a Display can place. So
`pipeline-setup-panel` follows the `security-threat-sim` shape instead (a
registered panel with typed inputs), exactly as `security-threat-sim` was
justified in sec-i. The **shared** `ShellBridgeService` *was* extended rather
than duplicated: three new methods, `pipeline.available` / `pipeline.run` /
`pipeline.privileged`.

The panel's contract with itself: with a shell it re-runs each step live and
replaces it; without one it reads the mirror, marks itself read-only, disables
every button, and prints the exact command under each step and each question.
It never composes a command and has no field a secret could be typed into.

---

### NUMBERS

| suite | before | after |
|---|---|---|
| `polari-jenkins/selftest.sh` | 316/316 | **364/364** (+48: 43 in the ci-11a block, 5 on the push) |
| `modules/cicd/cicd_selftest.py` | 154/154 | **183/183** (+29) |
| `pipeline-setup-panel.component.spec.ts` | — | **10/10** (new) |
| `ng build --configuration=production` | — | passes (pre-existing 5.5 MB budget warning only) |
| `check-theme-tokens.mjs` / `check-responsive.mjs` | — | both pass |

Live readings on this box: `setup --json` → 8 steps, 42 checks, 8 questions,
16 actions, 10 `where` entries, 8 to-dos, `1 of 8 complete`, blocking
`install the pol CLI`; `doctor --json` → 50 rows.

That `blocking` line is the new system-wide-`pol` check firing on this very
box: `pol` here is `~/.local/bin/pol`, which the doctor now WARNs about — see
OWED. It is the protocol reporting a real finding, not a bug.

### FILES

*suite* — `polari-jenkins/`: **new** `shell-verbs.json`, `setup/json.sh`,
`setup/protocol.py`; **changed** `setup.sh`, `setup/steps/01..07`, `doctor.sh`,
`isle/preflight.sh`, `cicd-sync.sh`, `selftest.sh`, `README.md`.
*polari-cli* — `scripts/jenkins.sh` (`verbs`, the `--json` usage lines).
*polari-rf-node/polari-framework* — `modules/cicd/`: **new**
`objects/cicd/PipelineSetupStep.py`; **changed** `cicd_api.py`, `cicd_page.py`,
`cicd_basis.py`, `__init__.py`, `custom/cicd_ingest.py`, `custom/cicd_rows.py`,
`objects/cicd/PipelineDevice.py`, `polari-app.json`, `cicd_selftest.py`,
`README.md`.
*polari-rf-node/polari-platform-angular* — **new**
`components/dashboard/generic/pipeline-setup-panel.component.ts` + `.spec.ts`;
**changed** `services/shell-bridge.service.ts`,
`components/dashboard/generic/generic-display-components.ts`.
`polari-app-shell/` was not touched (the Java agent's half).

### GOTCHAS

1. **`$( )` defeats `exec 1>&2`.** A command substitution re-captures the
   subshell's stdout, so redirecting stdout to stderr before calling a
   function does nothing if you then capture that function. The document goes
   through a temp file.
2. **The ingest door's value-shaped-key guard refuses the word `key`** — and a
   protocol question's field is literally `key`. That is *why* a step's
   sub-structures are posted as JSON strings (`checks_json`, `questions_json`,
   `actions_json`, `where_json`) rather than nested objects. The door refuses a
   nested post explicitly, naming the four columns it should have used.
3. **`python3 - <<'PY'` cannot also read a pipe** (the §70 gotcha again): the
   record file reaches `protocol.py` by argv, never on stdin.
4. **A todo emitted before the first step record was dropped** by the
   record reader's "inside a step" guard — a refused `--answer` produces
   exactly that, so `todo` is now handled ahead of the guard.
5. **Key generation refuses under the SYSTEM secrets posture.** Writing to
   `/etc/polari-jenkins/secrets` needs an elevation an unattended call cannot
   answer, so `--run generate-*` says so and exits 3 instead of hanging on a
   prompt. It writes into the REPO posture only, and says that too.

### OWED

* **`pol` must be system-wide on a pipeline device.** The Java half refuses to
  run a `pol` that is not (`~/.local/bin/pol` under root is an escalation: the
  owner of that file would choose what root does). `polari-cli/shells/
  install-cli.sh` *does* have a system mode — `cli-paths.sh` prefers
  `/usr/local/bin/pol` and falls back to `~/.local/bin/pol` only when
  `/usr/local/bin` is unwritable and passwordless sudo is absent — so
  `sudo bash polari-cli/shells/install-cli.sh` is the fix. **On this box it is
  currently the fallback** (`~/.local/bin/pol`). ci-11a adds a doctor WARN
  naming that exact command; the pipeline deb must place the system-wide link
  itself. NOT yet done.
* Nothing was deployed, committed or run: no `pol jenkins up`, no images
  rebuilt. **The page has not been seen in a browser** — it needs an image
  rebuild, and the bridge half needs the Java shell running.
* The live end-to-end (`pipeline.available` answering true, a privileged verb
  actually prompting) is untested across the two halves: each side is tested
  against the contract, not against the other.
* `--run` of `sync-push` posts to a core; untested against a live core.
* The `skipped` step state is implemented and asserted but no step emits it
  yet — it exists for a mode that does not apply to a step.
* `ng test` was run for the new spec only, not the whole suite.

### §74 (b) — the shell: the bridge family, pkexec + polkit, the first-run panel, the deb

His ask, 2026-09-19: turn the Polari pipeline (Jenkins) into a desktop app
*"similar to how the isle mesh is working"*, guiding people through use like
a normal app, using pkexec the way the store shell does, eliminating the
terminal. *"Yes let us go ahead."*

Built on `dev` in `polari-app-shell/`, **uncommitted**. Nothing was
installed, no deb was installed, no pkexec/polkit/sudo ran, no container or
VM was started, nothing was pushed. `./gradlew build` (offline) and the
wrapper selftest were run for real on pol-core.

---

#### What, and where

| what | where | notes |
|---|---|---|
| **the allowlist** (loader + model) | `core/src/main/java/org/polari/shell/core/pipeline/VerbCatalog.java`, `VerbSpec.java` | parses `polari-pipeline-shell/1`; refuses a wrong protocol, a bad verb id, a bad parameter name, an uncompilable regex, an empty argv, a `{param}` with no declared parameter, a `stdin` that is not `secret`. Declaration ORDER is kept (a UI lists verbs in the file's order). Path: `/usr/share/polari-pipeline/shell-verbs.json`, overridable only by the `polari.pipeline.verbs` JVM property |
| **the boundary** | `core/…/pipeline/VerbCommand.java` | `resolve` (validated argv), `unprivileged` (refuses a privileged verb), `privileged` (refuses a non-privileged one; returns `pkexec <wrapper> <id> name=value…`). `ARGV0_ALLOWED = pol, apt-get, usermod, nmcli` — the hard-coded second allowlist. Timeouts: 600 s when argv[0] is `apt-get`, 120 s otherwise |
| the secret handling | `core/…/pipeline/SecretScrub.java` | char[]-based search (never a String of the secret), `MASK`, `wipe` |
| **the bridge family** | `desktop/src/main/java/org/polari/shell/desktop/pipeline/PipelineBridge.java` | `pipeline.available` / `pipeline.run` / `pipeline.privileged`; four lines of plumbing each, every rule delegated to `core.pipeline`. Non-string params are replaced with a value that cannot match any regex |
| the executor | `desktop/…/pipeline/PipelineRunner.java` | catalog → core builds argv → `HostProcess` runs it → `{ok, exitCode, output, json}`. `discover()` degrades to an EMPTY catalog when no file is installed (`available:false`), never to an invented verb set |
| the native password box | `desktop/…/pipeline/SwingSecretPrompt.java` (+ `SecretPrompt` interface) | `JPasswordField` — the one control whose value lives in a `char[]` the caller can zero |
| **the first-run panel** | `desktop/…/pipeline/PipelineSetupPanel.java`, `PipelineSetupWindow.java`, `SetupDoc.java` | Swing, not the browser. Renders `explain` / `checks` / `questions` (choice·text·confirm·checklist·secret) / `actions` / `todo` / summary; runs each declared verb through the SAME two paths the page uses; "Open the pipeline (anyway)" leaves the bootstrap |
| the process runner | `desktop/…/HostProcess.java` (widened) | now `public`, with a `run(argv, timeout, char[] stdin)` overload that writes the secret as bytes, zeroes the buffer and closes the pipe. The store path is byte-for-byte unchanged (`stdin == null`) |
| the wiring | `ShellFrame.buildBridge()` (+5 lines), `DesktopMain` (`--pipeline-setup <step>`) | ShellFrame only REGISTERS the handlers; DesktopMain only routes the flag |
| **the privileged wrapper** | `pipeline/privileged-run` + `pipeline/verb-argv.py` | installed 0755 root at `/usr/lib/polari-pipeline/`; re-validates as root against the same JSON, resolves argv[0] to a root-owned, non-group/other-writable absolute path, then `exec`s. Selftest escapes (`POLARI_PIPELINE_SELFTEST` / `_DRY`) apply only when euid ≠ 0 |
| **the polkit action** | `pipeline/org.polari.pipeline.policy` | ONE action `org.polari.pipeline.run`, `exec.path` pinned at the wrapper, `auth_admin_keep` active / `auth_admin` otherwise |
| the launcher | `pipeline/pipeline-launch.sh` | the `.desktop` `Exec`. Asks the pipeline itself (`pol jenkins setup --json`) whether it is ready and what the first step is called, then `exec`s the shell with or without `--pipeline-setup` |
| **the deb** | `shells/build-pipeline-deb.sh` | `polari-pipeline`, `Depends: polari-shell-core, policykit-1, python3`, `Recommends: polari-cli`; ships the allowlist, the wrapper pair, the policy, the launcher, the registration (`scope=app`, `appName=cicd`, `startRoute=/display/cicd-setup`), the polari mark icon, a `.desktop` named **Polari Pipeline**. It REFUSES to build a `shell-verbs.json` the shell would refuse |
| docs | `pipeline/README.md`, `docs/BRIDGE_CONTRACT.md`, `README.md` | the boundary table, why the wrapper exists, the two allowlists, the secret rule |
| tests | `core/src/test/.../PipelineVerbsTest.java` (+ two fixtures), `desktop/src/test/.../PipelineBridgeTest.java`, `SetupDocTest.java`, `pipeline/selftest.sh` | see numbers |

#### The security argument, in five lines

1. A page passes a verb **id** and string **parameters** — never an argv, a
   flag, a path or a secret; the id must exist in the shipped allowlist and
   carry the matching `privileged` flag, and every `{param}` must match that
   verb's own regex (control characters refused outright).
2. The resolved `argv[0]` must be one of **four** programs hard-coded in the
   shell, in `verb-argv.py` and again in `privileged-run` — so replacing
   `shell-verbs.json` buys only a rearrangement of `pol`/`apt-get`/
   `usermod`/`nmcli`, each still behind its regexes.
3. pkexec never sees the real command: the polkit action pins `exec.path` at
   `/usr/lib/polari-pipeline/privileged-run`, so the password authorises
   *"one allowlisted setup step"*, not *"this command line as root"*.
4. The wrapper re-validates **as root, from the file on disk**, and refuses
   an argv[0] that is not a root-owned, non-group/other-writable absolute
   path in a system bin dir — a `pol` in `~/.local/bin` is exactly the
   escalation this stops.
5. A secret is typed into a native `JPasswordField`, written to the child's
   stdin and zeroed: never an argv, an env var, a log, or anything the page
   sees — and the command's output is scrubbed of it before the reply.

#### The boundary, and what crosses it (his rule: CLI vs JavaFX)

| side | owns |
|---|---|
| **bash / CLI** (`polari-jenkins/`, `pol jenkins …`, `pipeline-launch.sh`) | what a step means, what a check checks, where `device.env` lives, **what the steps are called**, whether the device is ready |
| **Java** (`core.pipeline`, `desktop.pipeline`) | validate a verb · run it · draw a setup document. No step name, no check, no config path appears in any `.java` file |

Exactly three things cross, and nothing else: **`shell-verbs.json`** (the
allowlist), **the setup document** (`polari-pipeline-setup/1`, one JSON
document per run — the shell parses nothing else from stdout), and **the
bridge envelope** (`pipeline.*`).

Two consequences worth naming: the panel learns the first step id from the
LAUNCHER (`--pipeline-setup <step>`), which learns it from
`pol jenkins setup --json` — so no step name is hard-coded on either side;
and the panel finds the "run an action" verb by SHAPE in the allowlist (one
unprivileged verb, one placeholder, `--run` in its argv), not by name.

#### Numbers

```
./gradlew --offline build          BUILD SUCCESSFUL   (JDK 22 on PATH, release 17)
:core:test        49 tests, 0 failures   (33 before + 16 new)
:desktop:test     14 tests, 0 failures   (new source set: 9 bridge + 5 document)
pipeline/selftest.sh                23/23   (no sudo, no pkexec, no network)
shells/build-pipeline-deb.sh        built: polari-pipeline_0.1.0_all.deb (148K)
```

The 16 core cases: the loader (the shipped list, its privileged flags, its
placeholders) · a wrong protocol · non-JSON · no verbs object · an empty
argv · an undeclared placeholder · an uncompilable regex · a bad verb id ·
a bad `stdin` · an unknown id on both paths · 7 parameter values failing
their regex · a missing parameter · an undeclared parameter · substitution
(own element, two in one element, a value with a space) · a privileged verb
refused on `pipeline.run` (all five) · an unprivileged verb refused on
`pipeline.privileged` · the pkexec argv shape · **the tampered fixture**
(`bash` refused, an absolute `/usr/bin/pol` refused, a `^.*$` regex still
cannot reach argv[0], and the honest verb in the same file still works) ·
the four-program list · scrubbing (two occurrences, edges, wipe) · the
secret never in an argv · an absent allowlist.

The 23 wrapper cases mirror them at the root side and add: a parameter given
twice, a parameter that is not `name=value`, a control character, a file
that is not the protocol / not JSON / absent, and the root-owned-program
rule (on this box `pol` is `~/.local/bin/pol`, so the wrapper refuses it
with the reason — which is the correct answer and is asserted as such).

The deb was built against the FIXTURE allowlist
(`core/src/test/resources/pipeline/shell-verbs.json`) because
`polari-jenkins/shell-verbs.json` is the other half's file and did not exist
yet; the output went to a scratch dir and was **not installed**. Building
the tampered fixture is refused by the builder, as designed.

#### Gotchas found and fixed while building

- **`Map.copyOf` randomises order.** The catalog listed its verbs in a
  different order every run, which would have made `pipeline.available` and
  the panel's verb lookup non-deterministic. Both the catalog and each
  verb's params are now unmodifiable `LinkedHashMap`s.
- **`Optional.orElseThrow()` before the validating call** produced
  `NoSuchElementException: No value present` instead of
  `refused: unknown verb 'x'` — the page would have seen a Java exception
  string as the refusal reason. Core now refuses first; it owns every "why
  not" message.
- **A NUL-separated argv cannot be read back in POSIX `sh`.** The validator
  therefore prints one element per line, and proves first that no element
  carries a control character — so splitting on `IFS=$'\n'` is exact and a
  value with spaces stays ONE element (asserted for `nmcli con up
  "Wired conn 1"`).
- **`$` in Java/Python regexes matches before a trailing newline.** Java's
  `matches()` and Python's `fullmatch()` both require the whole input, but
  the control-character check runs first anyway — belt and braces, because
  the regexes come from a file.
- **pkexec sanitises the environment, so `pol` on `~/.local/bin` is
  invisible to root** — and running a user-writable binary as root would be
  an escalation. The wrapper resolves only root-owned, non-group/other-
  writable files in system bin dirs and says so when it refuses.
- **`polari-shell-core` is the runtime.** There is no per-app jpackage step:
  `build-pipeline-deb.sh` follows `build-launcher-deb.sh`, so the pipeline
  app costs ~148 KB, not another bundled JRE. (`build-shared-shell.sh`
  remains the one jpackage invocation, unchanged.)
- **`DesktopMain.launcherPackageName`** would have turned `polari-pipeline`
  into `isle-app-polari-pipeline` (wrong icon, wrong WM_CLASS); a name that
  already starts `polari-` now passes through.
- The deb builder VALIDATES the allowlist it is about to ship (protocol,
  verb ids, argv[0] against the same four programs, compilable regexes,
  declared placeholders) — a mismatch between the two halves fails the
  BUILD rather than the first click.

#### OWED

1. **The first real run of the deb on a desktop is untested.** Nothing was
   installed here: no `dpkg -i`, no polkit action registered, no pkexec
   prompt, no JCEF window, no `auth_admin_keep` behaviour observed. The deb
   was built and its contents listed, nothing more.
2. **The two halves have never met.** This side was built against a FIXTURE
   `shell-verbs.json` and a fixture setup document; `polari-jenkins/
   shell-verbs.json` and `pol jenkins setup --json` are the other agent's.
   First joint step: build the deb with `--verbs polari-jenkins/
   shell-verbs.json` (the builder refuses a mismatch) and run
   `pipeline/selftest.sh` pointed at the real file.
3. **`pol` must be installed system-wide** for any privileged verb to run —
   the wrapper refuses `~/.local/bin/pol` by design, and **no `polari-cli`
   deb exists yet**. Until one does, `Recommends: polari-cli` is a promise
   nothing fulfils; the postinst says so out loud.
4. **The panel's `{answer}` convention** (a question's `params` value of
   `{answer}` is replaced with what the person typed/chose) is this side's
   invention and needs the bash half to emit it — otherwise text/choice
   answers are shown but cannot be applied, and the panel says "(terminal)".
   Worth a line in the setup protocol doc.
5. `PipelineRunner.discover()` re-reads the allowlist per `buildBridge()`
   (i.e. per instance switch), not once per process. Harmless, but it is not
   what "reads it at start" literally says.
6. **The panel has never been seen on a screen.** It is unit-tested through
   `SetupDoc` and constructed headless; no Xvfb on this box and no window
   was opened on his desktop. Layout, wrapping and the password dialog are
   unproven visually.
7. `srcDistTar` does not include `pipeline/` or `shells/` — the store's
   source archive still builds only the shell, which is correct today but
   means a source download cannot build the pipeline deb.
8. Nothing is committed.

**§74 meet-in-the-middle (Fable review):** the two halves were built against the same contract and checked against each other after both landed — `shells/build-pipeline-deb.sh` built `polari-pipeline_0.1.0_all.deb` against the REAL `polari-jenkins/shell-verbs.json` ("11 verbs, all argv[0] allowlisted"), and the root-side validator `pipeline/verb-argv.py` accepts `apt-install-tools` and `docker-group` with their declared parameters, refuses an extra parameter, a parameter failing its regex (`area=../etc`), any unprivileged verb offered to pkexec, and — on this box — every `pol` verb, because `pol` here is user-local (`~/.local/bin`), which is the designed refusal. Neither half has run on a screen or under a real pkexec prompt.

## §75 — the home devices cleared for the pipeline run (2026-09-19, his ask): the swarm gone, the isle's own uninstall run as a test — DIRTY

**pol-core:** `docker stack rm polari-lean` → the two named volumes (`polari-suite_kc_lean_db`, `polari-suite_prf_lean_data` —
today's live rulings and observations went with them; the ledger holds the proofs) → container/image/builder prune →
`docker swarm leave --force`. After: swarm `inactive`, 0 images, 0 containers, 0 volumes, 0 build cache (15.96 GB
reclaimed). `.generated/` (the deploy answers) kept.

**isle-core — the product's own uninstall as the test (his rule, §73 layer 1):** `sudo ISLE_CONFIRM_DELETE=yes isle
uninstall --everything --force` exited 0 in 3 min 47 s; then `isle uninstall --verify` exited **1**:

    [!] images remaining: 3 (harmless; docker rmi to clear)
    [✗] /usr/share/isle-mesh still present
    [✓] network owner: NetworkManager (active)
    [✗] footprint remains (above)

and the hand-back proof: route OK, **public DNS FAIL**, apt FAIL (no DNS). Findings against the product — **verdict
`dirty`**, which under the §73 rule means core is NOT releasable until the uninstall is clean:
1. `apt purge of every isle package` left `polari-complete 0.1.34` installed (so `/usr/share/isle-mesh` and the
   `isle` symlink stayed); `/etc/polari` (install-mode, posture.json) and the user's `~/polari-isle` (root-owned
   files) were not removed; 3 images remained.
2. **The network hand-back lost DNS again** (the 2026-09-13 failure, unchanged): NetworkManager owned the network
   and the Wi-Fi profile was DHCP with auto-DNS, but systemd-resolved had NO DNS server on ANY link — the isle's
   hand-back cleared resolved's per-link DNS and did not re-apply the connection. A stock `dnsmasq` service was
   still bound on 127.0.0.1:53 beside resolved's stubs. FIX that worked: `nmcli con up <wifi profile>` — resolved
   re-learned the DHCP servers at once (`Current DNS Server` populated, `getent` + `apt update` OK). The uninstall
   should end with exactly that re-apply (or `resolvectl revert <link>` + `nmcli con up`) and PROVE DNS before
   printing "complete". `isle rescue network` still does not exist.
The remainder was cleared by hand (apt purge polari-complete, rm the three dirs, rmi, rm the symlink) and libvirt +
virt-install installed so isle-core becomes the throwaway target. After: 0 packages, 0 containers, 0 images, 0
volumes, 0 VMs, 0 units, DNS OK, 5.4 GB available. These two findings go to isle-core's contract note (the isle
CLI is isle-core's code); the pipeline's teardown (§73) would have recorded exactly this `dirty` verdict.

**econ-core:** empty before (Odoo gone since the 09-13 purge; two old deb folders on the desktop left alone); the
suite cloned on dev at `545bd5c` with polari-cli + polari-rf-node bootstrapped; a `polari-ci_ed25519` key + an
`isle-core` ssh alias (user-level config, never tracked) authorised on isle-core; the hop + `sudo -n` proven.

### §75 addendum — the FIRST REAL RUNS on the pipeline device (2026-09-19, econ-core → isle-core)

| step | result |
|---|---|
| `pol jenkins preflight --isle` (target ssh:isle-core) | 14/14 PASS after the stale `isle-mesh-boot.service` (left by the 09-13 purge) was removed — "clear to run" |
| `pol jenkins up` on econ-core | controller image built over Wi-Fi, `Jenkins is fully up`, UI 200 on loopback, 4 jobs seeded, doctor 4 WARN (wired IPv4, repo secrets posture, no `init-device`, user-local pol) |
| cycle 1: `isle up` | **FAIL** — `virt-install`: `Cannot access storage file …/ci-isle/polari-ci-isle/disk.qcow2 (as uid:64055) Permission denied` — the run dir was 0700 and the hypervisor runs as `libvirt-qemu`. FIX (`3c2b54c`): the dir gets traverse and the two files rw for the hypervisor user via ACLs (the key keeps 0600) |
| cycle 2: `isle up` | VM up with an address in 21 s; `verify` **refused** (`Connection refused`) — an address arrives before sshd. FIX: `up` waits until the guest answers over ssh (`CI_ISLE_SSH_WAIT_S`, default 240) |
| cycle 3 | **`up` 26 s (5 s of ssh wait) → `verify` inside the guest (hostname polari-ci-isle, 2 vCPU, 3.8 GB, 27 GB free, /dev/kvm present) → `uninstall` = `skipped` (nothing installed — ci-3) → `down` (run dir removed, wipe: nothing else, nothing foreign touched) → `leakcheck check` CLEAN**: MemAvailable 5310 → 6323 MB, images-dir −598 MB (the cached cloud image, on the same filesystem, inside the tolerance), swap 848 → 833 MB |
| a leftover the baseline exposed | a 3 GB `qemu-system-x86_64` launched by hand from `/tmp/polari-vm` (the ISO arc's test guest, up 3.8 days) was still running on isle-core — not the isle's, not ours; killed by PID (`pkill -f` with the pattern in my own ssh command line killed the SESSION first — the handoff's gotcha, again) |
| `polari-dev-build` #1 (triggered through the loopback API; the admin password file carries a trailing newline — trim it) | **FAILURE** in the debs stage: `jlink failed with: Error: Module jdk.management.jfr not found` — the controller image (`jenkins/jenkins:lts-jdk21`, Temurin) ships NO jmods, so the shell's jpackage cannot link a runtime and `polari-complete` refuses to bundle without `polari-shell-core`; plus a non-fatal `BrokenPipeError` from `cicd-sync.sh` |
| `polari-release` (its own poll of main) | **FAILURE to compile**: `Duplicate build condition name: "always"` — two `post { always }` blocks from today's stacked edits. FIXED (`3c2b54c`), not yet re-run |

Owed from here: the controller needs a JDK with jmods for the deb builders (and the dev-build re-run to green), the
BrokenPipe in cicd-sync, `polari-release` re-run after the compile fix (expected: builds, then every route DRY —
no isle-test results yet), then ci-3 so a stage can install and the uninstall verdict stops being `skipped`. HIS:
wired IPv4 on econ-core, `sudo bash polari-cli/shells/install-cli.sh`, `sudo pol jenkins init-device`, the tokens.
