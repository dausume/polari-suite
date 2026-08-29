# Next-session handoff: microchip arc → the CELL stage (2026-08-26)

> **UPDATE 2026-08-29 (open-source focus, his direction):**
> - **The binary, first class:** `EvidenceItem.role` (reference =
>   proves our processes/sims make sense; usable = we build with it:
>   open licences, formats) and `TechnologyIPRecord.intended_use`
>   (open-chip-candidate vs reference-only: tfet, siemens-tcs,
>   fbr-silane, gaa-nanowire). Every proof / provenance / library
>   subject carries `usage.{usable_in_open_chips, statement}` —
>   USABLE only when candidate AND proven-free (US). Proof panel and
>   evidence browser show it first.
> - **Open cell library** (`cnt_open_library.py`, `OpenCellLibrary`
>   rows): admission = every cell proven-free AND the device pair
>   proven-free. `polari-open-si-planar-90` (si-nmos/pmos-planar-90):
>   26/26 cells admitted, **open_source_ready**; `polari-open-cnt-s1`:
>   NOT ready — device pair encumbered (US 9,825,229) though the
>   circuits are free. Characterize / export (`.lib` with provenance
>   header, `.sp`, PROVENANCE.json, LICENSE GPL-3.0 artefacts, public-
>   domain circuits) / ladder cell-rung update as data.
>   `/api/cntfet/open-library[/{name}[/liberty]]`, page
>   `/display/open-library`.
> - **Cells × FETs coverage** (`cnt_cell_coverage.py`): per device,
>   which of the 26 cells (incl. cdff) have numbers from a run on
>   THAT device, what is missing (sequential setup/hold, tri-state)
>   and the POST that fills it; `/api/cntfet/cells/coverage`,
>   `/device/{n}/cell-coverage`, in `/links`.
> - **Functional blocks BUILT** (`cnt_blocks.py`, ladder rank 3):
>   reg4 (96T), ctr4 (162T), fsm-traffic (78T), alu4 (358T; 8 cell
>   kinds) — composed ONLY of library cells, proven exhaustively
>   (alu4: 2048 vectors), Verilog + SPICE netlists generated, OpenSTA
>   on alu4 over the real S1 Liberty: critical path 7.1 ps (intrinsic-
>   grade, no wires); ctr4/reg4/fsm timing refuses by name until a
>   DFFX1 Liberty row exists (`characterize-sequential`); power
>   roll-up (static per input state via cell leakage, dynamic from
>   run energies); provenance roll-up = worst of device + cells (alu4:
>   encumbered on S1, proven-free on planar Si). Routes
>   `/api/cntfet/blocks?device=`, `/block/{key}?timing=1`,
>   `/block/{key}/proof|logic|power`; page `/display/cntfet-blocks`.
>   Main selftest 129/129, blocks 32/32, open-library 22/22.
> - **LIVE (2026-08-29 evening):** Si planar pair library run
>   `si-nmos-planar-90-lib-170958` (24/26 cells; clatch/cdff via
>   their own actions), open library `polari-open-si-planar-90`
>   refreshed + EXPORTED to `/tmp/open-library/polari-open-si-planar-90/`
>   (.lib with provenance header, .sp, PROVENANCE.json, LICENSE.txt),
>   ladder `standard-cell` rung = `characterized` (data), Si cell
>   scores live with provenance + "USABLE in open-source chips".
>   Coverage matrix: S1 24/26, Si NMOS 24/26 (sequential runs in
>   flight). Cosmetic: `open_library_report().run` keys come back
>   None while the Liberty header names the run — fix the report's
>   run lookup keys.

> **UPDATE 2026-08-29 (latest): EVIDENCE + PROOF OF FREEDOM, first
> class and clickable (his ask; jurisdiction = US).**
> `cntfet/cnt_evidence.py` — 76 `EvidenceItem` rows (16 patents, 47
> papers/prior-art, 11 textbooks, 4 standards, 8 licences; 46 verified
> online via Google Patents / Crossref / OpenLibrary with
> `verified_via`) joined by name from every `TechnologyIPRecord`
> (`evidence_json`). `freedom_proof(kind, name)` applies PROOF_RULES
> (data) under US patent terms (EXPIRY_RULES: 1995-06-08 cutover;
> foreign families out of scope, stated) → proven-free /
> free-unverified / encumbered / unknown with the CHAIN and the GAPS.
> Live table: **29 proven-free** (all 26 cells + planar Si NMOS/PMOS +
> sol-gel-SiO2 NMOS), 7 free-unverified (sol-gel HfO2 devices, the
> refinement routes), **5 encumbered** (all CNT devices — gap = active
> US 9,825,229 aligned-array process; the CNT device itself is free),
> 0 unknown. A `provenance` block (verdict, status, top evidence,
> detailPath) rides score / compare / cell-scores / cell-logic /
> characteristics. Routes `/proof`, `/device/{n}/proof`,
> `/cell/{c}/proof`, `/evidence[/{item}]`. Angular
> `freedom-proof-panel` (status badge, chain, click an item → detail
> drawer with supports/citedBy/source link, gaps checklist) on every
> score + detail page; `evidence-browser` on cntfet-home and the cells
> page. Main selftest 127/127; evidence 38/38; ip 41/41.
> Known: US 9,428,830 (FBR) is GTAT, not REC, per Google Patents —
> the evidence row is right, cnt_ip's text still says REC.

> **UPDATE 2026-08-29 (later): licensing / FTO tracked as rows.**
> `cntfet/cnt_ip.py` — 26 `TechnologyIPRecord` seeds (device shapes,
> materials, processes, cells, model, tools, formats) with verdict
> green/amber/red, key patents (numbers, filing, expiry — ~15
> verified online), what we own, the self-manufacture rule (own
> fab does NOT clear an ACTIVE patent), verify_next, confidence;
> `/api/cntfet/device/{name}/ip`, `/api/cntfet/ip`; IP panel on
> every score page (backfilled live via the new
> `polari-cli/shells/backfill-cntfet-pages.sh`). Verdicts: generic
> MOSFET / CMOS / planar / FinFET / basic CNT FET / cells / our VS
> model = GREEN; GAA nanosheet, aligned-CNT array processes, FBR
> silane, sol-gel HfO2 formulations, SOI, TFET, Siemens know-how =
> AMBER; no RED. Engineering record, not legal advice — every
> payload says so. Main selftest 126/126; ip 41/41.

> **UPDATE 2026-08-29 — LIVE on the dev swarm (his assign + my
> follow-through).** cntfet + sifet are assigned to prf-a and
> booted; all 12 FETs derived; field scenes sampled; the cell
> library CHARACTERIZED on the isle-core engines worker (run
> `cnt-aligned-s1-lib-140958`, 24 cells, OpenSTA-accepted; cell
> scores/power live). Cross-tech ranking today: Si PMOS FinFET on
> sol-gel HfO2 0.73 > CNT tox2 0.70 > S1 0.69 … Learned the hard way:
> - `sifet` had to be REGISTERED in `modules/polari-modules.json`
>   (requires cntfet) before `pol topology assign sifet prf-a`
>   admits its classes (otherwise CRUDE 404 / seeds skipped).
> - `CNTFET_ENGINES_URL` is interpolated by the NODE compose file
>   from the PROCESS env at `pol swarm deploy` time — neither the
>   suite `.env` nor pol state carries it; unset ⇒ backend uses its
>   local ngspice WITHOUT OpenVAF and characterization dies half-way
>   ("no arc survived"). The runbook now exports it (+ the
>   `POL_STACK_CONSTRAINTS` pin `backend=node.labels.polari.machine==pol-core`
>   — without the pin swarm bounces the backend across nodes:
>   "invalid mount config … ca/root_ca.crt").
> - `pol swarm deploy` refuses while the core is rebooting (derives
>   POLARI_MODULES from live rows) — wait for /api/topology first.
> - The worker does not log requests; a long characterize call sits
>   behind the proxy — check worker CPU on isle-core, not logs.
> Runbook: `polari-cli/shells/enable-cntfet-prf-a.sh`
> (`CHARACTERIZE=1` opt-in for the ~30-min library run).

> **UPDATE 2026-08-27 (later, same autonomous window): the fp ARC
> is BUILT** — `AI-Notes/plans/FET_CELL_POWER_SILICON_PLAN.md` §3
> is the status table: power limits + leakage (fp-1), silicon FETs
> on sol-gel sharing the VS device contract (fp-2 — cross-technology
> ranking: Si NMOS 0.71 > CNT S1 0.69 > Si FinFET-HfO2 0.68),
> switching-/signal-optimized classes + shapes + complementary pairs
> + regions incl. BdSat (fp-3), silicon refinement routes (fp-4 —
> PV grade reachable by the open route, EG needs the novel section),
> cell logic/circuit diagrams with switch-level proofs, all 12 cells
> proven (fp-5, page `/display/cntfet-cells`), datasheet categories
> + plain-language explanations + `/links` weave (fp-6). Main
> selftest 125/125 + 7 sub-suites green; images rebuilt + rolled.
> Still gated on his `enable-cntfet-prf-a.sh` (module assignment);
> the script now also derives the silicon FETs and verifies every
> fp surface. Open: browser passes, plan §2 decisions ×5, a sifet
> transport/field basis (Si refuses those by name today), lifting
> the new citation dicts into cnt_citations.

> **UPDATE 2026-08-27 (autonomous, his 9-h window): the fv ARC
> (regimes / transport / characteristic-driven 2-D+3-D views /
> more FETs+cells) is BUILT end-to-end** — plan
> `AI-Notes/plans/FET_VIEWS_PLAN.md` §3 is the status table
> (framework `4206e99`, angular `84259e9`, both on `dev-fi-1`,
> images rebuilt + rolled on the dev swarm). Main selftest
> 120/120 + regimes 24 / transport 16 / fields 25 / more_cells 11.
> **His one command** (unattended, now also derives every
> comparator FET and samples the 3-D field scenes):
> `ssh pol-core 'bash ~/Desktop/polari-suite/polari-cli/shells/enable-cntfet-prf-a.sh'`
> then browse `/display/cntfet-detail-cnt-aligned-s1` (explorer:
> pick a characteristic → views + meaning; 3-D scenes scrub Vg).
> Known honest limits: VS model never reaches the square law
> (m ≤ ~1); F1 field profiles are SKETCHES (D13 SCF drawn beside);
> `polarity` is a label (p-row says so); scattering time profiles
> are labelled priors. Next: browser pass, ratify FET_VIEWS_PLAN
> §2, wire polarity → ptype, cell-3 parasitics.

> **UPDATE 2026-08-26 (autonomous late session, his directive:
> "characterization and scoring of FETs and Cells"):** **fi-2 +
> fi-3 + cell scoring BUILT on `dev-fi-1`** (framework + angular,
> see FET_INTUITION_PLAN.md §4 for built-vs-planned):
> - `cntfet/cnt_scoring.py` — 6 FET ScoreTerms (SS, on/off decades,
>   DIBL, gm/G0, |g_on/G0−0.7|, |Vt−Vt_target|) whose IDEALS are
>   computed from the device's own model frame; concept
>   `fet-switching-quality`; ScoreSubject per seeded device
>   (object_ref → the row); ContextualizedValue rows bound by
>   objectRef to `AlignedCNTFETDevice.figures_of_merit` (a live
>   property, cnt_basis) so the GENERIC engine's
>   `score_concept('fet-switching-quality')` lands on the same
>   number as `GET /api/cntfet/device/{name}/score` (selftest
>   proves equality). S1 nominal score 0.687.
> - `cnt_montecarlo.monte_carlo(score=True)` — every functional
>   sample scored → quantiles, per-term spread, best/worst case
>   with sampled process values + per-term attribution vs nominal;
>   Id(Vg) envelope (min/p05/p50/p95/max). S1: p05–p95 0.65–0.72;
>   worst case moved by `fet-g-on-distance` (Rc lognormal tail).
> - `cntfet/cnt_cell_scoring.py` — cell terms as RATIOS to the
>   driving FET's intrinsic limits (delay/τ_int, transition/τ_int,
>   E_supply/(C_L·Vdd²), FETs/min; ideal 1), read back from the
>   latest library run row's own Liberty (existing rows score
>   without a re-run); `GET …/cell-scores`; refuses by name
>   without a run. Real cell-2 Liberty: INVX1 0.86 … OAI21X1 0.76.
> - graphs (config only): `cnt-device-score-terms`,
>   `cnt-device-transfer-envelope`, `cnt-device-cell-scores`;
>   cntfet-home rows 7–8 (page now 10 graph panels / 21
>   components) — ⚠ INSERT-BY-NAME ⇒ CRUDE PUT backfill on the
>   live node. Angular: long-form `hguide` style (ruleY + label)
>   and categorical x kept as strings (NamedGraphConfig.ts +
>   plotFigure.ts; tsc clean).
> - points endpoint knobs: `?samples=` (MC count behind
>   score-terms/transfer-envelope, default 100, 0 = nominal only)
>   `?seed=`; score endpoint knobs `vt_definition`, `off_decades`,
>   `vov_decades`, `g_on_target_over_g0`, `samples`.
> - Selftest **111/111 on the HOST** (after adding `-w "$PWD"` to
>   `~/.local/bin/sta` — the docker wrapper mounted /tmp but never
>   set the working dir, so OpenSTA's relative `read_liberty`
>   failed; pre-existing, now fixed on pol-core).
> - **DEPLOYED to the dev swarm**: backend + frontend images
>   rebuilt (`docker compose -f .generated/stack-node.yml build
>   backend|frontend` + `docker service update --force --image …`)
>   — ⚠ `docker cp` + `docker restart` is LOST on swarm (respawn
>   from image; memory `deploy-swarm-image-rebuild` was right, the
>   earlier prf-compose note in this file is stale). Seeds landed
>   live (7 cnt-device graphs, 10 terms, 2 concepts, subjects,
>   6 live-bound values) and **cntfet-home was CRUDE-PUT
>   backfilled** (live row had only 4 rows — the fet-viz/fi-1 rows
>   5–6 had never reached it either; now 9, diffed identical).
> - ⛔ **HIS CALL — `cntfet` is NOT assigned to `prf-a`** on this
>   swarm (ModuleAssignment rows: only `cntfet.engines@cnt-engines`),
>   so `/api/cntfet/*` 404s on `api.prf.…` and the page's graph/
>   API panels refuse until `pol topology assign cntfet prf-a` +
>   `pol swarm deploy node` (adds the module to POLARI_MODULES).
>   The CRUDE surfaces (rows, seeds, page) are live regardless.
>   Note `prf.…/api/*` is the SPA fallback (index.html), not an API.
> - **fi-4 (2026-08-27, his redefinition) BUILT + COMMITTED**
>   (framework on dev-fi-1, 116/116): FET-VALIDITY GATE
>   (`cnt_scoring.fet_validity` — 5 characteristic-equation proofs;
>   any failure or underived model ⇒ score 0, proofs named) and
>   PER-FET COMPETITIVE PAGES (`cnt_compare`: `/compare`, graph
>   `cnt-device-compare`, seeded `cntfet-score-{device}` pages;
>   comparator device `cnt-aligned-s1-lg30` seeded, scores 0 as
>   UNPROVEN until `POST {"action":"derive"}`). Backend image
>   rebuilt + rolled again.
> - **HIS QUICK RUN (unattended):** `ssh pol-core 'bash
>   ~/Desktop/polari-suite/polari-cli/shells/enable-cntfet-prf-a.sh'`
>   — assigns cntfet→prf-a, `pol swarm deploy node`, waits, verifies
>   score/cells/compare. Then derive the comparator so the ranking
>   has two real FETs: `curl -sk -X POST -H 'Content-Type:
>   application/json' -d '{"action":"derive"}'
>   https://api.prf.192.168.0.210.nip.io/api/cntfet/devices/cnt-aligned-s1-lg30`.
> - NEXT: fi-4 remainder (TableDefinition per device for the
>   Tables/Graphs tabs, library_report links), then cell-3.

> **UPDATE 2026-08-26 (late session, HIS go):** the dev box was
> purged and rebuilt on **docker swarm** (dev = swarm, app/deb route
> = production — see memory `dev-swarm-prod-app-route`): `polari-node`
> on pol-core, `polari-cnt-engines` (:9700) on isle-core,
> `polari-engines` (msci :9500) on econ-core.
> **cell-2 + dist-1 COMMITTED** (framework `dev-cell-2` 9b7b36e → dev,
> 95/95 live against the isle-core worker; this branch had been left
> UNCOMMITTED by a session the systemd-oomd VS Code kills dropped).
> **New arc opened: FET intuition** — `AI-Notes/plans/FET_INTUITION_PLAN.md`;
> fi-0 (states as data + qualifying criteria, `/api/cntfet/device/{name}/states`)
> and fi-1 (band/guide long-form styles, state-annotated curves, cntfet-home
> row 6) BUILT on `dev-fi-1` (framework 9d31eee, angular ace38c7), selftest
> 100/100. NEXT: fi-2 scoring by characteristic equations, fi-3 MC
> best/worst case, fi-4 per-object surfaces; then cell-3 / cell-4 below.
> Deploy loop on swarm: `docker compose -f .generated/stack-node.yml build
> backend|frontend` + `docker service update --image … --force`; selftests via
> `docker cp` into the `polari-node_backend` task (cell-2 run ≈ 30 min).

**Entry state (this session's consolidation, HIS go): both arcs
COMMITTED and MERGED to local dev — framework `dev-chip-1`
(0b92bff) + `dev-cmpc-1` (57c6ebc) → dev b7b7e3b; angular
`dev-chip-1` (4f35c35) → dev 536d871; rf-node pointer 5706a8f;
suite docs+pointer on dev. NOT pushed (his `./push-all-dev.sh`
ritual). Post-merge selftests green: cntfet 85/85, computers
30/30, computerparts 14/14, polariapps 45/45. The running prf
stack carries the same code via docker cp (image is BAKED — next
`pol` rebuild converges from dev).**

**FOCUS (his directive): microchip arc only — move up to CELLS.
Computer-assembly next steps (cmp-c-7 workbench etc.) stay in
COMPUTER_COMPOSITION_PLAN §8, untouched this arc.**

Governing plans: CHIP_COMPUTE_DISTRIBUTION_PLAN.md §4 (cell
roadmap; §6 decisions PENDING his ratification),
CNT_FET_SIMULATION_PLAN.md (D-boxes), COMPUTER_CHIP_NEXT_HANDOFF
(previous sessions' record).

## Build order

1. **fet-viz ✅ BUILT same session (2026-08-26)**: "in-page
   visualizations and characterizations of our existing FETs."
   cnt_device_viz.py — GET /api/cntfet/device/{name}/points
   ?curve=transfer|output (long-form rows, Id in µA) + …/
   characterization (cnt_metrics family + fidelity string +
   refusals verbatim); 2 seeded GraphDefinition rows
   (cnt-device-transfer log-Y / cnt-device-output) reused across
   devices via dataPath; cntfet-home row 5 (S1 device panels);
   selftest 85→89. Committed dev-chip-2 → dev. Per-device pages
   for OTHER devices = point the same graphs at their paths.
   The original sketch (kept for the next device):
   - Per-object rule applies ([[per-object-display-config]]):
     curves/characterization belong on the DEVICE's own page
     surfaces, configured there — not a new global page.
   - Ride the figure machinery just merged: seeded
     GraphDefinition rows + `named-graph-panel` (angular) +
     long-form points endpoints — NO new chart engine
     ([[frontend-graphing-capability]]).
   - Shape: a device-scoped curves feed (e.g.
     `/api/cntfet/device/{name}/points?curve=transfer|output`,
     long-form rows matching seeded dimensions) + a
     characterization summary payload (SS, gm, Ion/Ioff at
     DECLARED bias points, each value carrying its fidelity
     string F1/F2/F3/F3_NEGF_SCF — never a bare number) + seed
     rows onto the cntfet page AND the device rows' display
     config. Refusals verbatim (undigitized/uncomputed = named
     refusal, not an empty chart).
   - Existing assets: AlignedCNTFETDevice/CNTFETSimResult rows,
     cnt_api actions (iv/transfer/f3-oracle), cnt_figures.py
     seed pattern (SEED_CNTFET_FIGURE_GRAPHS = the template),
     cnt_characterization.py (CellCharacterizationRun — reuse
     its sweep plumbing where it fits devices, not just cells).
2. **cell-2 — sequential + richer combinational
   characterization** (plan §4): lctime executor for DFF
   setup/hold (⚠ AGPL — absent-by-default knob, D14 licence
   gate: evidence in the plan, HIS call before any vendor/pin);
   AOI21/OAI21 + TG mux cells; x4 drive variants (GENERATED,
   never hand twins); energy-per-transition tables from the same
   transients into the Liberty.
3. **cell-3 — parasitics grade-up**: [VS2] junction capacitance
   replaces the labeled 2 aF standins; re-grade characterization
   rows (honesty strings already say intrinsic-grade).
4. **cell-4 — ladder rung flip as DATA**: microchip CELL rung
   'unbuilt' → 'characterized' citing library result rows;
   ring-oscillator + cells pages get the figure-replica
   treatment (same named-graph-panel path as fet-viz).
5. Then (NOT this arc unless he says so): chip-3/S6 synthesis,
   dist-1 engine-worker (plan §3), chip-4 seam (§5 table is the
   ratifiable contract).

## Gotchas that WILL bite again

- 🔑 Liberty without `delay_model : table_lookup` silently times
  NOTHING in OpenSTA (arcs listed, no arrivals); clockless
  netlists need a virtual clock + zero I/O delays before
  report_checks sees any path. (Both hit + fixed in cell-1.)
- 🔑 OpenSTA runs via the docker wrapper `~/.local/bin/sta`
  (openroad/opensta v3.1.0) — no sudo build; keep-or-native is
  his open call (dist plan §6.3).
- 🔑 DisplayDefinition seeds are INSERT-BY-NAME: editing an
  existing page's seed needs a CRUDE PUT backfill (multipart
  polariId + updateData, --form-string) — applied for
  computers-home this session; cntfet-home will need the same
  when fet-viz adds rows.
- 🔑 Backend code is BAKED into the image (no repo bind mount):
  deploy = docker cp changed files + `docker restart
  prf-backend` (proven ×2 this session), or full `pol` rebuild.
  Boot takes ~4 min (451 types).
- 🔑 New treeObject classes MUST be registered in polariServer's
  defClassList or seeds silently vanish.

## His open items (unchanged gates + new)

1. **Push**: `./push-all-dev.sh --push` (suite root wrapper).
   ⚠ --with-isle is legacy/dead.
2. **dev-cnt-2 (angular) still UNMERGED**: both-keep merge on
   generic-display-components.ts; cntfet-iv-chart must CONVERGE
   onto the graphs design at that merge (now easier — the
   named-graph-panel path is on dev).
3. **Review flags**: the S5-era eq.(5) a1/a2 mirror-bug fix
   (merged with dev-chip-1 — the old S5 numbers were computed on
   the mirrored barrier); polariServer.py carried both arcs' app
   seed passes (landed via dev-cmpc-1).
4. **Ratifications**: cmp-c plan decisions 1–4;
   CHIP_COMPUTE_DISTRIBUTION_PLAN §6 (incl. D14 lctime AGPL
   knob before cell-2 vendors anything).
5. Standing: nmp dev-nmp-1 + dev-dyn-1 gates untouched; browser
   passes (TESTING_OWED item 18 + the new computers-home row 3 +
   the two nav apps).
