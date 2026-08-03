# ➡️ START HERE (2026-08-02, session 3): THE CLIMATE CHANGE &
# ATMOSPHERE MODULE IS BUILT on REAL fetched data — co2-A, xpt-1,
# co2-0/1, co2-2, co2-3/4, co2-5, co2-H, co2-7/8, co2-X are DONE
# and committed on dev in polari-framework. NOT deployed, NOT
# browser-verified, NOT pushed.
#
# REMAINING in CO2_HEALTH_PLAN.md: co2-6 (carbon sinks), co2-B
# (the NHANES bicarbonate/PHQ-9 correlation), co2-9 (the
# simulation binding), then DEPLOY + a browser pass.
# M3_PLAN.md stays queued behind it.
# Push tool: polari-cli/shells/push-all-dev.sh (dry-run/--push).

## THE HEADLINE: the plan said every number was a placeholder.
## They are not placeholders any more.

Network reached every source. Every URL on every `APIEndpoint`
row was fetched live on 2026-08-02 and returned the real payload;
`verifiedOn` records that date.

- NOAA Mauna Loa annual mean, 1959-2025, n=67. **2025 = 427.35
  +/- 0.12 ppm.**
- NOAA's OWN published growth rate (the velocity term, not
  derived by us).
- Antarctic ice-core composite (Bereiter et al. 2015, NCEI study
  17975), n=1901, -803719..2001 CE.
- NHANES `BIOPRO_D.xpt` parsed: **LBXSC3SI n=6349, mean 24.556466
  mmol/L** — bicarbonate column confirmed against the real file.
- CDC life expectancy (Socrata JSON), 1900 = 47.3 years.

### Two independent paths agree
Fitted velocity **2.1972 ppm/yr** vs NOAA's published growth rate
**2.2058 ppm/yr** over the same 30 years — 0.4% apart. Quadratic
acceleration **0.0336 +/- 0.0011 ppm/yr2** (30 sigma).

## FINDINGS THE DATA PRODUCED (not remembered)

1. **Humans have never breathed this air.** Across the 800,000
   years before the last millennium CO2 never exceeded **298.6
   ppm** (glacial low 173.7). Today is **1.43x** the whole-record
   maximum. Homo sapiens emerged at 185-236 ppm; behavioural
   modernity at 216-240; agriculture began at 248-270;
   pre-industrial 273-283.
2. **ASHRAE 62.1 is a DIFFERENTIAL, and that is the answer to
   "when did 1000 ppm indoors become the norm".** The criterion
   is 700 ppm ABOVE OUTDOOR, and ASHRAE states plainly that its
   IAQ standards do not use indoor CO2 to judge air quality. So a
   FULLY COMPLIANT room sat at 980 ppm absolute when outdoor was
   280 and sits at **1127 ppm today**. Nothing about the room
   changed; the baseline moved under it. `is_differential` +
   `absolute_ppm()` are the only sanctioned way to put
   differential and absolute thresholds on one axis.
3. **10 threshold-room pairs are ALREADY past a line today.** At
   427 ppm outdoor: closed bedroom 3093 ppm, classroom 2093,
   car cabin 2093, open-plan office 877, well-ventilated public
   building 689.
4. The mechanism is bounded honestly: 420 ppm is 0.319 mmHg,
   **0.8% of a 40 mmHg alveolar pCO2**. Going 280 -> 420 ppm
   narrows the elimination gradient by 0.27%; 1000 ppm by 1.38%.

## THREE THINGS A FRESH AGENT MUST NOT UNDO

- 🔑 **THE INGEST RIDES `polariApiProfiler`, NOT NEW CODE.** An
  API-profile system already existed (APIDomain -> APIEndpoint ->
  APIProfile, CRUDE-registered, seeded, with Angular UI). This
  arc EXTENDED `APIEndpoint` with the fields a real data file
  needs (responseFormat / contentSignature / rejectSignature /
  minBytes / paramsTemplate / fieldMapJson / citationText /
  verifiedOn) and added ONE generic executor,
  `polariApiProfiler/endpoint_fetch.py`. Adding a source is a
  ROW. Do not write a second fetch path.
- ⚠ **A 200 IS NOT A SUCCESS.** Observed live against two
  agencies: census.gov serves 'Missing Key' HTML with HTTP 200
  (already known here), and wwwn.cdc.gov serves RETIRED NHANES
  paths as HTTP 200 with a 20905-byte 'Page Not Found' page —
  byte-identical for two different files. Status-code checking
  alone would have ingested a webpage as a lab result. Content
  signatures are why that cannot happen.
- 🔑 **ONE EQUATION, TWO CALLERS.** Indoor CO2 reuses aquaponics'
  `environment_gas_exchange` with the source term's sign flipped
  (a crop depletes, people emit). `guard_two_callers()` pins the
  symmetry to 1e-9. Do not write a second CO2 mass balance.

## TWO REAL DEFECTS FOUND AND FIXED

1. `APIEndpoint.authConfig` held `env:VAR` POINTERS that were
   sent **literally** — every keyed endpoint transmitted the
   string `env:POLARI_CENSUS_API_KEY` as its credential. The
   seeded dmvdata rows assumed a resolver that did not exist.
   `resolve_secret()` now resolves them and refuses by name when
   the knob is unset.
2. `crossing_band` returned `ok=True` with `low`/`high` = None
   when neither fit reached the target — a success carrying no
   answer, i.e. how a null reaches a published page as the word
   "None". It now REFUSES and names both sides' reasons.

## HONESTY THAT IS CARRIED IN ROWS, NOT PROSE

- Thresholds are **graded**: a ventilation standard is not a
  health study is not an occupational limit. The two ASHRAE rows
  are `standard-or-guideline` and share a deliberately
  off-severity colour because they are INDICATORS, not harms.
- The cognitive rows are `contested-controlled-study` and carry
  `contested_by` naming Rodeheffer 2018, Scully 2019 and Du 2020
  beside Satish 2012. The page shows both or it is advocacy.
- The **negative row** exists (280 ppm, no evidence of effect) —
  a page listing only harms implies harm everywhere.
- `COGNITION_QUESTION` refuses the prehistoric-cognition question
  in BOTH directions and names what would actually be evidence.
- **Life expectancy is context, never a regressor.** No
  prehistoric life-expectancy number is seeded at all
  (`life_expectancy_at_birth = 0.0` with the reason on the row).
- **Law Dome is registered WITHOUT a parser, on purpose.** It is
  the one archive with no '#' comment markers — prose followed by
  several stacked tables — so the generic signature would have
  accepted it and the generic parser would have read the wrong
  columns. Its CO2 column must be identified from the file's own
  header before any ingest.
- A car-cabin ACH prior produced a 20000 ppm steady state; the
  implausibility was caught before it shipped and the prior was
  corrected to 6.0 ACH. The history stays on the row: the
  equation was right, the guess was wrong.

## SOURCE TRACING IS STRUCTURAL

    AtmosphericObservation.span_ref
      -> SourceCoverageSpan  (which archive, which years, what
                              resolution, what uncertainty)
        -> APIEndpoint       (how it was fetched)
          -> GovSource       (who publishes it)
            -> SourceRetrieval (when WE copied it, sha256, bytes)

So a chart cites exactly the spans it shows, and the ice-core /
instrumental seam is DATA. `splice_series` never drops a segment:
where two overlap it reports the mean difference as a
CROSS-CHECK, which is what makes the spliced curve a measurement
rather than an assumption.

## EXPORT (co2-X)

`climate_export.py`: **markdown** (the Medium format —
self-contained, tables + citations, no external assets), **csv**
(one provenance column per point: span, measurement kind,
archive, instrument, resolution, citation — a bare year,value CSV
is number laundry), **json** (config + data + spans, the
sim-binding document). **svg REFUSES** with a reason: the chart is
already an SVG in the DOM and a second server-side plotter would
disagree with the picture the reader saw. One renderer, one truth.
`export_view_markdown` exports refused sections AS refusals.

## FILES (modules/climate/, ~6600 lines, one file per concern)

climate_basis (11 classes) | climate_series | climate_sources |
series_parsers | series_ingest | xpt_reader | co2_trend |
co2_physiology | co2_thresholds | co2_indoor | co2_crossing |
climate_history | climate_views (9 sections as rows) |
climate_pages (5 GraphDefinition rows + the /co2/health
DisplayDefinition) | climate_app | climate_export | climate_api |
selftest_climate

Registrations done: FEATURE_MODULES + FEATURE_REQUIRES
(aquaponics, dmvdata), polari-modules.json, polariServer
try-import + stub tuple + defClassList + endpoint construction +
a gated upsert seed pass. Suites green: apps 45/45, composition
75/75, aquaponics atmosphere 10/10, lazy-import drift 15/15.

## WHAT IS LEFT

1. **co2-6 carbon sinks** — the Global Carbon Budget is NOT a
   simple file fetch (globalcarbonbudgetdata.org/latest-data.html
   404s; the data lives on ICOS/Zenodo as xlsx). Find a stable
   machine-readable endpoint and add it as an APIEndpoint row.
2. **co2-B the correlation** — bicarbonate (BIOPRO_*) and PHQ-9
   depression (DPQ_*) are published for THE SAME NHANES cycles
   and the same sampling frame, which is what makes them
   comparable at all. Both file families verified reachable.
   Run it as a QUESTION with the confounders named (assay
   changes between cycles, age structure, altitude, kidney
   disease, diet); a population mean moving inside the reference
   interval is not a diagnosis.
3. **co2-9 the simulation binding** — point aquaponics'
   `AtmosphereDefinition.outside_co2_ppm` at the live series as
   an optional reference (seeded constant stays the fallback, the
   row says which it used). Small phase, large meaning.
4. **DEPLOY + browser pass.** Nothing here has been deployed or
   seen in a browser. Every prior arc in this repo had live
   findings the suites could not produce — expect the same.
   Deploy ritual and the /co2/health page are in CO2_HEALTH_PLAN
   and the DO/DON'T box.
5. **The frontend gaps the display explorer found** and this arc
   did NOT fix: `embeddedGraph` resolves a graph by runtime ID
   (unusable from a seed — `graph_data()` resolves by NAME
   instead as the workaround); `showLegend` is stored but never
   passed to Plot.plot(); there is no reference-line/threshold
   band on 2D charts (the threshold bands are rows already, so
   this is a renderer change); and no `payload.series` shape-gated
   renderer exists beside the `headline` table.


# ➡️ (previous session) START HERE (2026-08-02, session 2): M2 IS BUILT — cons-2,
# cons-3 and m2-1..8 are DONE, committed on dev through the
# pointer chains, deployed, 25/25 live probes, browser-verified.
# NOT pushed.
#
# NEXT WORK: the CLIMATE CHANGE & ATMOSPHERE APP —
# read CO2_HEALTH_PLAN.md and start at co2-A (the object model).
# M3_PLAN.md stays queued behind it.
# Push tool: polari-cli/shells/push-all-dev.sh (dry-run/--push).

## What this session finished (M2, the PM rung)

**cons-2**: the M1 shaft/coil material fixes are LIVE and the
materials legend renders three real swatches with no
'(unresolved)' (browser-verified).

**cons-3 — THE ADOPTION CAUGHT THE GEOMETRY.** The m1-1 solver
now runs on the EXACT tooth/pole arc overlap. A smooth
first-harmonic stand-in gives every geometry torque everywhere,
so it had been hiding a machine that could not start: the seeded
tooth arc was 27.55 deg against a 30 deg step angle, meaning
ZERO overlap exactly where each step begins (4 of 12 steps
landed). That is the textbook SRM arc rule, now a live report
(`/api/motors/m1-arc-rule`, a card on the M1 magnetics view) and
a suite guard. Arcs widened to 32.02 / 36 deg; tooth_area_m2
followed the geometry (4e-5 -> 4.718e-5); pull-in/holding moved
0.32 -> 0.17; GEAR_RATIO 304 -> 265 with the guard tightened to
EQUALITY.
Second finding, free: the exact profile has a flat zero-torque
alignment `beta_r - beta_s` wide, so rest is a BAND. One-way
steps stay exact (proven by running the control at 2N steps —
same error, not double), but a REVERSAL costs the band as
backlash: 0.0138 mm on the printer axis, inside the 0.2 mm
tolerance row, and now a bench entry a printed protractor can
falsify (no material property enters the prediction).

**m2-1..8**: `m2_rotation` (synchronous solver — load angle
delta = phi_c + gamma - phi_r, torque as sin(delta), pull-out at
90 deg, k_e derived from the same magnet MMF and loop reluctance
the torque uses), `m2_scene`/`m2_views` (six view rows, five
layers, NO new mechanism), `m2_composition` (one designed gap
where M1 had two; the rotor already promoted BY BOND not by
mold; the winding fork INHERITED by reference; op-m2-magnetize
last), `m2_lift` (THE LIFT PROOF), `m2_product`, the m2 bench
sheet, nav rows, and `selftest_m2` (77/77).

Numbers worth knowing: the bare motor STALLS on the sketched
30:1 worm (5.69x short) and names the 6:1 stage that closes it;
as shipped it lifts at 66 deg of load angle; it HOLDS WHEN DEAD
because the worm self-locks, never because of cogging (the model
predicts exactly zero cogging by construction and the payload
refuses to borrow any). And the reduction creates a contradiction
that is NAMED rather than buried: 180:1 total demands 92x the
commutation rate the design row assumes — either the crucible
rises 92x slower, or the drive commutates faster than anything on
this rung has shown. Only the bench can say which.

Suites: selftest_m2 79/79 (new), m1 98/98, motors 331/331,
composition 75/75, apps 45/45, gears 68/68, techtree 74/74,
magnetics 51/51, shape-equations 16/16, bizops 85/85.
DEPLOYED + 25/25 LIVE PROBES + BROWSER PASS DONE.

**Three things the browser pass caught and fixed** (the pattern
holds: a live pass finds what suites cannot):
1. THE REPLAY BUG — the scene component hardcoded
   /api/motors/m1-sequence for every phase-replay layer, so M2's
   layer (which DECLARES historySource 'm2-rotation') silently
   ran the RELUCTANCE solver on the PM design. At saliency 1.0
   that model has no torque, so on screen the coils lit and the
   rotor sat still at 0 deg. Now routed by historySource, with
   the M2 history carrying the replay contract's own keys.
2. fm-bond-line-shear was NAMED on the bonded rotor interface
   with no FailureModeDefinition row behind it — the marker layer
   reported it as modeRowsMissing, the gap-naming machinery
   catching its own author. Row written.
3. The proofs rendered as RAW JSON (the view renderer only tables
   known shapes). Both proofs now emit a `headline` list and the
   renderer tables it, shape-gated like the rest.

## ➡️ NEXT WORK: CLIMATE CHANGE & ATMOSPHERE APP
## READ `CO2_HEALTH_PLAN.md` — it is the complete plan

Dustin queued this mid-session and then twice widened it. The
final shape (his words, in order):

1. "implementing the capability to ingest xpt file format data
   from api's. Particularly Bicarbonate data per year from the
   CDC... also carbon dioxide levels indoors increasing over
   time, and carbon dioxide in ppm and partial pressure in the
   means it affects the lungs. And then also velocity and
   acceleration of co2 over time. And also rates of decline in
   carbon sinks. We will want to make an overall page for
   analysis of co2 and the way it is affecting human health. We
   should also indicate different thresholds on that page for
   human health impacts. Like when 800 or 1000 ppm outdoors will
   be reached, or when it became the norm for 1000 ppm inside to
   be the norm from ventilation, and when we will hit more health
   thresholds. A page pulling from official sources to analyze
   this."
2. "we should also implement tracking of different known health
   thresholds of co2 and derive the times we would hit those
   thresholds for both indoor and outdoor levels based on
   analyzing trends in influence on co2 levels indoor and outdoor
   together with co2 velocity and acceleration."
3. "we should probably actually make a Climate Change &
   Atmosphere App, and we will want to turn all of this data with
   it's sources into real polari objects we can use down the road
   with simulations."

So it is an APP + an OBJECT MODEL + the CO2/health study on top —
not a page. The plan's §-1 states that shape; §1 is the object
model; §7 is the coupled indoor/outdoor crossing projection (the
heart); §9b is the app row and nav.

**Three things a fresh agent should not have to rediscover:**
- 🔑 THE INDOOR EQUATION ALREADY EXISTS.
  `aquaponics/atmosphere_analysis.py::environment_gas_exchange`
  solves steady-state indoor CO2 under ventilation for a crop
  that DEPLETES it. A room full of people is the same equation
  with the sign flipped. Generalize it with a signed source term;
  do not write a second CO2 mass balance.
- Provenance machinery exists: `GovSource` + `SourceRetrieval`
  (dmvdata) and the `census_pull.py` ingest shape (injectable
  fetcher, redacted URLs). Reuse both.
- ⚠ EVERY NUMBER IN THE PLAN IS A PLACEHOLDER the plan's author
  could not verify (no network). Thresholds, growth rates, NHANES
  column names — all of them. The plan's top rule is that the
  ingest is what makes them real, and that engines REFUSE to
  project from an unfetched series. This is health information;
  a confidently wrong page is the failure mode.

M3_PLAN.md (the axial-flux rung) stays queued behind this.

# ➡️ HANDOFF (2026-08-01, session 2): M1 BUILT OUT THE M0 WAY —
# m1-1..8 COMPLETE, DEPLOYED, 9/9 LIVE PROBES + BROWSER PASS DONE

**State**: the whole M1 arc (M1_PLAN.md m1-1..m1-8) is BUILT,
COMMITTED (dev-arch-part-composition, framework+angular+rf-node+
suite pointer chains per phase, NOT pushed), DEPLOYED to staging
and LIVE-VERIFIED (9/9 probe battery). selftest_m1 75/75 (new,
auto-discovered), motors 330/330, composition 75/75, apps 45/45.

**BROWSER PASS DONE** (same day, --chrome relaunch): the phase
walk visibly walks (theta +30/step, lit pair A→B→C), layers stack
(materials/stress/markers on one canvas, real SF numbers in the
legend), nav deep-links land, positioning + materials views render
every card. Four MORE live-caught fixes shipped during the pass:
the requirements-template shape collision (a same-named payload
field killed sibling cards — renderers now gate by SHAPE), marker
z-hover + radii scaled to the M1 extent (interior joints were
occluded/half-size), and the M1 parts joining PART_ROLE_ASSIGNMENTS
(the stator fork's role screen refused; now 4 viable options incl.
bio-steel, suite-guarded). M1 GATE (M1_PLAN §5) FULLY MET.

**Files (one per concern)**: m1_sequencing (solver + holding +
pull_in_load_limit + bisect), m1_views, m1_scene, m1_composition,
m1_positioning (PrinterAxisRequirement rows + THE PROOF),
m1_product (axis-drive, 304:1), bench m1 sheet in bench_campaign,
selftest_m1. Seeds all on upsert chains in polariServer.

**FINDINGS the live probes forced (already fixed + committed)**:
- NEW CLASS GOTCHA: a brand-new treeObject class must be
  registered in polariServer's EXPLICIT class list (import + stub
  tuple + definition-table list) or its seeds silently never land
  (upsert errors don't print). PrinterAxisRequirement caught it.
- PULL-IN SIZES DRIVETRAINS: the pull-in load limit is ~0.32x
  holding torque (flat landscape between poles); the holding-
  sized 98:1 reduction still lost steps — pull_in_load_limit()
  is the engine, 304:1 the honest ratio, and axis duty verdicts
  now judge by it. A motor that holds what it cannot step under
  positions nothing.
- SRM misses SLIP a pole pitch backward (no detent) — the proof
  names slips; "loses exactly its missed steps" is M0 physics,
  not M1's.

Older context below.

# ➡️ (superseded) HANDOFF (2026-08-01): BEGIN M1 — read M1_PLAN.md FIRST, start m1-1

**Pick-up**: `M1_PLAN.md` at the suite root is the complete plan.
Start at **m1-1 (the sequencing solver, `modules/motors/m1_sequencing.py`)**
and follow the phase order; §1 lists what M1 already has (design row
`reluctance-6s4p-m1`, scene `motor-m1-viz`, part rows, torque curve,
simplefoc profile) — extend, do not invent. §2 fixes the file layout;
§4 is the honesty ledger to carry from day one. Branch: continue
`dev-arch-part-composition` ×4 repos (polari-cli has its own branch of
that name), or a fresh `dev-m1-reluctance` off it if Dustin prefers.

## What this session finished (all LIVE + verified, NOT pushed)
The whole navigation revamp (nav-0..6: 8 discipline apps, top+side
menus, /api/apps/nav tri-state, absent-module probe), module
enablement as ROWS (never `--env-add` again — `pol topology
modules-env`), layered 3D clock scenes (8 stackable layer kinds),
the Lavet AIR GAP fix, the WINDING as a parity-pinned matrix-equation
math object + the spool→bobbin→gear COUPLED CASCADE + the toothed
gear (undercut/tip refusals), the ISOLATED gear-train scene w/ solved
motion + hands w/ orientation vectors, the GENUINE assembly (real
masses; counterweighted seconds hand DRIVABLE) + the TIMEKEEPING
PROOF (exact live; weak drive loses exactly its missed seconds),
**M0 COMPLETE AS A PRODUCT** (clock-lavet-m0b, mag-25 winding
verbatim, datasheet verdict "every composed check passes" — ZERO
blockers, was NOT-SHIPPABLE ×3) with pure-local + commercial
sourcing routes, 5 bizops workflows + ProductFormula + sell-iterate
loop, the W2 BENCH CAMPAIGN (5 live-bound predictions + record-back
seams — the physical build is M0's only remaining act), TWO NEW
TREES (electric-motors ladder incl. M2b brushed = the drill;
manufacturing-devices bootstrap chain clock→printer→hoist→drill→
mini-traction→train), and DISTRIBUTED TRACTION as math (per-axle
sweep + adhesion ceiling). Suites at handoff: motors 330/330,
gears 68/68, winding+gear 31/31, techtree 74/74, apps 45/45,
bizops 85/85; probes apps_nav 11/11.

## Operational facts a fresh agent needs (details in memory files)
- Deploy: `pol node build backend|frontend --env staging` +
  `docker service update --force --image prf-…:staging
  polari-node_<svc>`; NEVER docker cp+restart; in-container server
  listens on :3000; module admission takes ~5-7 min after a roll
  (endpoints 503 honestly meanwhile — poll, do not panic).
- Seeds: wire ANY new/changed seed table through the upsert path
  (guarded blocks in polariServer `_seedSimSpace3D`; ClockAssembly/
  Product/GearScene/V2Shape/AppsNav/ScaleGoals precedents). Brand-new
  rows can drop a field on FIRST boot (shape_units/function flavor)
  — a respawn heals it via the upsert; check before debugging.
- In-process probes: set POLARI_LAZY_BOOT=off or everything 503s.
- Don't re-import module-level seed names inside `_seedSimSpace3D`
  (UnboundLocalError crashed a deploy once).
- Two-modules-agree: any fact stated twice gets a guard test.
- In-container selftests: docker cp the module into the running
  task + `python3 -m <module>.selftest_…` (test-only; discarded on
  respawn — deploys still go through the image).

# ➡️ HANDOVER TO FABLE 5 (2026-07-31): PART COMPOSITION +
# CHARACTERISTIC EQUATIONS — read PART_COMPOSITION_HANDOVER.md FIRST

Dustin is handing the next phase to Fable 5: new DATA STRUCTURES for
part composition. The full context document is
**`PART_COMPOSITION_HANDOVER.md`** at the suite root. Summary of what
it carries:

- **FOUR LEVELS**, distinguished by SEPARABILITY (not size):
  part component (one material) -> part (components processed into
  one whole, tunable toward a purpose, NOT meant to come apart) ->
  sub-assembly -> assembly (members separable, interfaces designed).
- **THE PROMOTION OPERATION** is the load-bearing idea: an assembly
  can be PROCESSED into a part irreversibly (melt the screw; sol-gel
  over a spooled winding). Promotion TRADES INTERFACE FAILURE MODES
  FOR BULK ONES and spends repairability. Both sides showed up here
  — the sol-gel stator is a real candidate whose blocker is exactly
  the bulk mode it introduces (brittle film, a crack is a short).
- **CHARACTERISTIC EQUATIONS BY LEVEL**, with emphasis on WHICH
  VARIABLES CANCEL, because cancellation is what makes knobs
  independent and tuning tractable. The M0 factors cleanly:
  GAUGE->voltage, TURNS->battery life, WINDOW->turns, no cross terms.
- **11 OBSERVED BEHAVIOURS** that constrain the design, each from
  this arc: ratio-driven performance (a stronger magnet makes it
  WORSE), objectives silently moving requirements, model regime
  boundaries that do not degrade gracefully, square-law geometry
  coupling, requirement-vs-disqualifier predicates, graded
  thresholds, loops storable WITH their breaks, industrial specs
  being economic rather than physical, per-property evidence levels,
  fake cross-checks, and the seed-upsert gotcha (10 strikes).

⚠ **Reuse, do not rebuild**: `part_roles.py` roles ARE the tags and
already carry predicates — `screen_candidates` is the "relevant
materials by tag" answer. 16 equations already exist as
EquationDefinition rows via `physics_equations.py`. Full inventory
table in §4 of the handover doc.

⚠ **Design the seed UPSERT path before seeding composition rows.**
The CRUDE-PUT-after-deploy workaround has held ten times and should
not have to hold an eleventh.

# ⚡ SESSION 2026-07-31 (cont 2): mag-25 SIMPLEST-CASE-FIRST +
# wire-1 DRAWING STRAIN — deployed + live-verified. READ THIS FIRST.

## 🔑 THE CORRECTION THAT MATTERS MOST
Dustin: the M0 exercise was always about "a simple magnetic engine
that does not use complex processes". mag-22 optimised for POWER,
chose 46 AWG, and dragged the project into ultrafine drawing,
diamond dies and an HPHT press. **Optimising the wrong objective
does not announce itself — it quietly moves the requirements.**

THE PHYSICS WE MISSED: coil voltage is `MMF*rho*MTL/A_copper` —
**TURNS CANCEL**. Gauge alone decides whether a cell can drive the
movement. At 46 AWG the coil needs **4.14 V** against a cell's 1.5 V,
so mag-22's design was silently carrying a STEP-UP CONVERTER whose
quiescent draw was never in the power budget.

GAUGE sets voltage. TURNS set battery life. WINDOW sets turns. They
are INDEPENDENT levers, so the only price of coarse wire is a bigger
bobbin — and on a wall clock volume is the cheapest thing we have.
Same 4 years on one AA, direct drive, no converter:
    32 AWG  0.16 V  24.6 mm square   (W2 — carbide dies)
    38 AWG  0.65 V  13.7 mm square   (W2 ceiling)
    40 AWG  1.03 V  11.4 mm square   (last gauge on one cell)
    46 AWG  4.14 V   7.1 mm square   NEEDS A CONVERTER
Finer wire buys SIZE and nothing else that matters here.
`/api/motors/simplest`, `/api/motors/road-to-advanced`.

## ✅ wire-1: the DRAWING STRAIN of manufacturing-tools
NOT a new tree — `manufacturing-tools` already declares itself as
cross-cutting apparatus many domains pull on (furnace ladder = its
THERMAL strain). Drawing is the same argument in another axis.
`/api/techtree/wire-strain`.

8 consumers across 4 trees. **W2 unlocks 5 of them — including both
the THERMOCOUPLE that makes the kiln controllable AND the clock
coil.** The rung that makes the furnace work is the rung that makes
the movement. W3 is justified by sieve mesh, strain gauges and small
instrument coils — not by this clock.

THREE BOOTSTRAP LOOPS, each carried WITH its break:
- kiln -> thermocouple -> wire -> die -> press → breaks on
  PYROMETRIC CONES (already how our ceramics rung is specified)
- CVD -> tungsten filament -> drawing -> die → breaks on HPHT, or
  one bought filament
- PCD -> graded grit -> fine sieve -> fine wire -> PCD → breaks on
  SEDIMENTATION grading, which reaches finer than sieving anyway

The diamond chain has a shortcut at EVERY step except BORING THE
DIE. That is the capability to attack, and to rehearse at a coarse
gauge where failure costs one coil. Industrial specs quoted at us
(die life 10-30x, in-line annealing, chilled coolant) exist to keep
a LINE running fast and unattended — **we need 210 m of wire once**,
so batch annealing and a reservoir suffice.

⚠ CONSISTENCY BUG CAUGHT IN LIVE VERIFICATION: wire_ladder had
magnet wire at W3 while mag-25 had moved it to W2 — two live
endpoints contradicting each other. Fixed + guard test. **When two
modules written in one session assert the same fact, test that they
agree.**

⚠ SELFTEST FILE NEARLY DESTROYED: `t[:marker] + add + t[marker:]`
with `marker = None` duplicates the ENTIRE file. Restored via git.
Assert the marker exists before splicing.

TESTS: motors 233/233, techtree 68/68, FEM elasticity 41/41,
magnetics 51/51, gears 62/62, meshassets 36/36.

## NEXT — Dustin named it explicitly, DO THIS NEXT:
**PART ARCHETYPES.** "account for particular kinds of common parts
and part components, like electric-wire, and stator spool... build
out data structure for those such that we account for manufacturing
constraints and difficulty levels for particular criteria, as well
as identifying relevant materials for them based on their tags."
Design sketch: an archetype layer BETWEEN `part_roles.py` (abstract
requirement) and `MotorPartDefinition` (concrete instance). Each
archetype declares (a) its ROLES — reuse `role_viability` /
`screen_candidates` for material screening rather than a new tag
system, (b) a manufacturing chain with rungs, (c) DIFFICULTY PER
CRITERION (dimensional tolerance, surface finish, aspect ratio,
process temperature, concentricity) so the BINDING criterion is
reported rather than one difficulty number. Starter set:
electric-wire, stator-spool/bobbin, magnetic-core, rotor-magnet,
pinion/gear, shaft, bearing-jewel, frame-plate. Candidate home is
beside `part_roles.py`, but it generalises past motors — note the
promotion path.

Also still open: M0 design row still states 1500 turns / 12 mm2
window (seed an M0b with the mag-25 winding); the LCR bench
measurement that would settle the mag-23 4.6x reluctance-model
disagreement; no frontend for mag-22..25; mag-20 migration
unfinished.

# ⚡ SESSION 2026-07-31 (cont): mag-23 INDUCTANCE SOLVED BY FEM,
# mag-24 LOCAL MAGNET WIRE ROUTE — deployed + live-verified

## ✅ mag-23: INDUCTANCE, actually solved (framework 9288bc8)
Dustin: "do genuine simulation of inductance using fem and config."
mag-22 had NAMED inductance as its largest risk and not modelled it.

NEW ENGINE: `materialsScience/engines/fem_engine.py` gained 2D
MAGNETOSTATICS — `solve_magnetostatic_2d()`, vector potential A_z,
variable-nu Poisson, regions as DATA. L from stored energy,
cross-checked against an independent flux CUT. Validated against a
gapped C-core closed form (lands 1.66x the ideal-gap formula, above
it because the formula omits fringing + window leakage).

ANSWER: tau = 12 us at the M0 winding, only 110 us at 20000 turns,
against a 30 ms pulse = 274 time constants, 100% of final current.
INDUCTANCE DOES NOT BREAK mag-22. `/api/motors/inductance`,
`/api/motors/inductance-turns`.

⚠ TWO TRAPS WORTH INHERITING:
- A UNIFORM MESH SILENTLY SHORTS A GAP. Elements straddling the
  0.8 mm gap take the CORE mu from their centroid; L came back 150x
  too high with nothing looking wrong. Fixed STRUCTURALLY — the
  mesh is now ALIGNED to every region boundary
  (`_mesh_aligned_to_features`), so no element spans two materials
  at any refinement. Correctness no longer depends on refine, and
  380 dofs now lands within 7% of converged.
- A CROSS-CHECK CAN BE FAKE. I computed `a @ f` and called it flux
  linkage — but for a linear system `a.K.a == a.f`, so it WAS 2W and
  re-derived the energy route. Real check = flux cut via
  Phi = A_z(P1) - A_z(P2).

🔑 THE FINDING BEYOND INDUCTANCE (`/api/motors/model-validity`):
FEM vs the LUMPED RELUCTANCE model agree to a constant 1.41 once
mu_r >= 200, and diverge 4.6x at mu ~ 2. A core that barely beats
air does not CONFINE flux — it crosses the window directly and a
reluctance network has no branch for it. **The model does not get
noisier, it STOPS APPLYING — and our locally producible materials
are exactly the low-mu ones.** Ratios computed the same way (the M0
step condition) partly cancel it; absolute flux/torque/inductance do
not. ONE LCR MEASUREMENT on a wound core would settle it.

## ✅ mag-24: local magnet wire research route (framework 3e23d89)
Copper wire was mag-22's one import. It is TWO capabilities:
- INSULATING = TRACTABLE. Oleoresinous varnish (tung oil + natural
  resin) WAS magnet wire insulation until 1939 — "plain enamel" —
  and vegetable-oil alkyds held on into the 1950s. Dip tank + 180 C
  oven vs a 400 C tower.
- DRAWING to fine gauge = THE WALL. Carbide reaches ~30 AWG; 46 AWG
  needs diamond dies + in-line anneal + chilled coolant.

THICKNESS decides, not chemistry — build adds to DIAMETER so it
enters as a SQUARE. At 15000 turns of 46 AWG: sol-gel silica 41 mm2
window (0.50x commercial), oleoresinous/silk 125 mm2 (1.52x), cotton
259 mm2 (3.13x — ruled out by arithmetic). Sol-gel is thinnest and
BRITTLE; bending it round a 3 mm former is the one-afternoon test
that opens or closes the best local option.
`/api/motors/{wire-insulation,local-wire-route}`.

⚠ FIXED: `winding_report` took insulation build only as a module
constant read into a DEFAULT ARGUMENT — defaults bind at definition
time, so patching the global changed nothing and every candidate
returned the same figure. Now an explicit `enamel_mm` parameter.
Same family as a flipped seed default never reaching a live row.

TESTS: motors 224/224, FEM elasticity 41/41, magnetics 51/51, gears
62/62, meshassets 36/36.

NEXT ON THIS THREAD:
- The LCR bench measurement is now the highest-value single act in
  the whole magnetics stack — it adjudicates a 4.6x model
  disagreement on the material we plan to use.
- M0 design row still states 1500 turns / 12 mm2 window; seed an M0b
  with the solved winding or mag-22 stays a report, not a design.
- No frontend for mag-22/23/24 (all API-only).
- mag-20 migration still unfinished: motor_stress, motor_fatigue,
  contact_wear, lifecycle_cost still compute in Python rather than
  calling evaluate_named().

# ⚡ SESSION 2026-07-30/31: mag-22 LOCALLY PRODUCIBLE CLOCK ROUTE
# SOLVED + DEPLOYED + LIVE-VERIFIED — read this section first

## ✅ mag-22: A LOCAL ROUTE TO A WORKING CLOCK EXISTS
## (framework 9b62b50 + rf-node pointer 2c48d77, dev-mag-a-magnetic-
## materials; NOT pushed)

Dustin: "a locally producible route to an electric motor clock that
will work here, at least one solution to that." Everything before
mag-22 ANALYSED a fixed design; `motors/local_route.py` SEARCHES.

THE ANSWER (`GET /api/motors/producible-clock`):
  1. FIRE the stator (opt-fired-ferrite-ceramic) and pinion
     (opt-fired-ceramic) — a pottery kiln, cone 8-10.
  2. PRESS + SINTER the rotor magnet from the recipe-seeded
     SrFe12O19 powder, then magnetise. THE ONE DEMONSTRATION the
     route rests on — carried as a named experiment, not relabelled
     data.
  3. WIND 15000 turns, not 1500 — 2.0 mA, on an ~83 mm2 bobbin
     window (the design states 12 mm2 and holds NO candidate coil,
     not even today's).
Result: 4.03x a commercial wall movement, ~4.7 yr on one AA, vs 40x
and 0.47 yr today. Copper wire is declared IMPORTED, never quietly
counted as local.

FOUR FINDINGS THAT CHANGED THE ANSWER — each from a check refusing:
- THE STATED 20 mA WAS NEVER SOLVED FOR. `minimum_drive_current()`
  bisects the EXISTING clock_sim step condition: 14.3 mA for present
  materials. Every power figure we had rested on a guess.
- A STRONGER MAGNET MAKES POWER **WORSE**. In a Lavet the magnet
  that makes the torque also makes the detent (coil/detent 4.81 ->
  3.42 going bonded -> sintered). Remanence buys structural margin
  and COSTS current. The intuitive guess was backwards.
- BOBBIN IS THE BINDING CONSTRAINT — hidden by MY OWN BUG:
  turns_sweep read a `fits` key that does not exist on
  winding_report, so `.get` defaulted True and non-fitting coils
  were reported viable. ⚠ LESSON: when reading another module's
  payload, VERIFY THE KEY EXISTS; `.get(k, True)` on a typo is a
  silent false pass.
- field-inert CHECKED PERMEABILITY BUT NOT REMANENCE. A sintered
  magnet has mu_rec ~1.1 and sailed through; the search proposed a
  PERMANENT MAGNET as the pinion. New `max-if-stated` test mode =
  a DISQUALIFIER (silence is not evidence of guilt) vs `max` which
  demands proof.

ALSO: `flux-carrying` was binary at mu>=100, which declared no local
stator possible — false, the M0 demonstrably steps at mu~2.2. Now
GRADED (functional 1.5 / good 100) reporting the penalty. The
rotor's magnetic role (`torque-magnet-active`) was MISSING, which is
how copper passed as a rotor magnet.

DATA: mu_r_eff added to 5 hard-magnet rows. alnico = 4.0 (the family
EXCEPTION, ~2-6; ceramic and NdFeB are ~1.1) — stated per material
because a family-wide value would be wrong there specifically.

⚠ SEED-FIELD GOTCHA, 10th STRIKE: properties_json changes do NOT
reach live rows. Backfilled by CRUDE PUT and DIFFED against the seed
BEFORE declaring live. NOTE THE PAYLOAD SHAPE — it is not obvious:
  PUT /<ClassName>  --form-string 'polariId=<id>'
                    --form-string 'updateData={"field": "value"}'
(CRUDE apiName is '/' + ClassName — there is NO /api prefix.)

⚠ DEPLOY NOTE: the backend is a SWARM service. `docker restart` on a
task makes swarm respawn from the IMAGE and your `docker cp` is
LOST. Deploy = `pol node build backend --env staging` then
`docker service update --force --image prf-backend:staging
polari-node_backend`. Live host is `api.prf.192.168.0.210.nip.io`.

TESTS: motors 200/200, magnetics 51/51, gears 62/62, meshassets
36/36 — all IN CONTAINER. Endpoints live-verified:
/api/motors/{local-route,producible-clock,turns-sweep} and
/api/motors/product/{design} which now carries the route past its
own blockers.

NEXT ON THIS THREAD:
- INDUCTANCE is the largest risk to the power claim and is NOT
  modelled: 15k turns is many henries and a 30 ms pulse may not
  reach final current. Treat the deep-turns end as an upper bound.
- The M0 design row still states coil_turns 1500 / 12 mm2 window.
  Either seed an M0b variant with the solved winding, or the route
  stays a report rather than a design.
- No frontend for mag-22 yet (the analysis is API-only).
- mag-20 migration still unfinished: motor_stress, motor_fatigue,
  contact_wear, lifecycle_cost still compute in Python instead of
  calling evaluate_named().

# ⚡⚡⚡⚡⚡⚡⚡⚡ SESSION 2026-07-28/29: TASK 1 DEPLOYED+API-VERIFIED,
# MAGNETICS SECTION A BUILT (mag-1 + mag-2/2r/2t) — read this first

## ✅ mag-7 REMAINDER (motors) BUILT + DEPLOYED + BROWSER-VERIFIED
## 2026-07-30 (framework 02295cf dev-mag-a-magnetic-materials,
## angular 450eb76 dev-mag-7-motor-ui, pointers committed; NOT pushed)
- CSG TRIANGULATION closed (mathshapes): sample_surface special-
  cases difference-of-COAXIAL-cylinders -> exact parametric TUBE
  mesh (tube_mesh in shape_geometry — the M0 coil ring, 192 tris
  live); everything else CSG/general-quadric now gets a VOXEL-FACE
  mesh from the marching grid (closed renderable surface, method
  string says 'blocky — exact only as N grows'; the old point
  cloud drew NOTHING in three.js).
- CYLINDER CAPS: cap_base/cap_top requested on motor solid rows
  (rotor disc, shaft, coil outer). ⚠ SEED-FIELD GOTCHA (5th time):
  3 live rows needed CRUDE PUT backfills of parameters_json
  (--form-string, polariId from GET /MathShapeDefinition) — disc
  was 48 tris (band) until then, 96 after.
- SCENE ROW: motor-m0-viz SimSpaceDefinition SEEDED (motor_shapes
  SEED_MOTOR_SIM_SPACES -> polariServer 3D seed group);
  freestandingOnly, six parts, coil = the CSG RING. The page loads
  its SNAPSHOT (/api/simspace/motor-m0-viz/snapshot) and overlays
  rotor rotation + coil polarity from the solver replay — scene =
  data, motion = runtime; hard-coded layout kept only as labelled
  fallback. Browser: caption cites the row, animation steps, coil
  flips green/amber, ring has a real bore, disc reads solid.
- VERIFICATION SEAM: motors/motor_verify.py — MotorVerificationRun
  rows never seeded, this is the one way in. clock_error_s DERIVES
  from missed/rate_hz, duration defaults commanded/rate LOUDLY,
  taken>commanded / bad kind / unknown design REFUSE.
  made-and-measured EARNED by kind='measured' rows only; sim
  replays are 'provenance, not proof' (rider on every record).
  /api/motors/verify/{design} GET summary + POST record;
  design_report carries a verification block. UI card: counts +
  earned chip + runs table + one-click record-sim-replay +
  measured-bench form. Live: 2 sim runs recorded (60/60 API,
  30/30 via the page button), madeAndMeasured honestly false.
- DRIVE CARD on /magnetics/motor: mag-6 simplefoc_config surfaced
  (board/profile/pole pairs, phase table w/ FPGA named-not-wired,
  generated Arduino snippet, honesty rider); M0 shows its no-FOC
  refusal as the drive story. Browser-verified on M1.
- Suites: selftest_motors 33->44, selftest_shapes 20->24,
  magnetics_liveboot_probe 32->39 (probe now boots +scoring,
  plant_morphology,aquaponics,mathshapes and hits the snapshot +
  tube surface through the real routes). magnetics 37/37, all
  mathshapes + aquaponics suites green. ⚠ PRE-EXISTING failure
  (not this change, verified against stashed tree):
  aquaponics.selftest_system 12/13 'environmental-impact concept
  scores both systems'.
- Both images rebuilt + force-rolled (same-tag gotcha), 15
  modules online, light+dark themes hold.
- STILL NEXT (mag arc): circuit editor + field-view renderer in
  SimSpaces (the non-motor mag-7 remainder), fem-2d field-map
  export, mathshapes Shape-row emission seam. ngspice still
  absent on pol-core (parity refusal correct).

## ⚙️ NEW ARC STARTED 2026-07-30: GEARS (gr-1 + gr-5 LIVE)
## framework 09728e1, pointers committed. Plan = GEARS_PLAN.md
- **Dustin's ask:** "gears actuated by motors as both 3D and more
  abstract simulations accounting for varying types of gears so we
  can start combining the motor logic with gear logic."
- NEW `modules/gears` (wave 4, requires mathshapes for the gr-3
  geometry that is NOT built yet — coupling named so a drop refuses
  honestly later). A train is a GRAPH: shaft nodes carry one speed,
  mesh edges impose ratio+torque = the mechanical twin of the mag-3
  reluctance network, riding the same rows-then-solve discipline.
- 8 seeded TYPES as data (spur/helical/internal/planetary/bevel/
  worm/rack-pinion/cycloidal): ratio law, BOTH ends of the
  literature efficiency band (worm 0.30-0.90 wide on purpose),
  direction behavior, thrust, self-lock capability, and how each
  would be MADE in our stack (spur easiest to cast, worm = buy it,
  cycloidal genuinely interesting for brittle cast parts).
- SOLVE: speeds WITH DIRECTION (external reverses, internal does
  not — asserted), torque after the cumulative efficiency chain,
  centre distances (sum vs difference), accumulated backlash, and a
  power-conservation CHECK. Unchainable types REFUSE with their
  ratio law named; two disagreeing paths into one shaft refuse
  (a differential needs its own solve); undeclared shafts are
  SUGGESTIONS not failures.
- gr-5 SPLICE LIVE: `/api/gears/motor-drive/{train}` — M0's speed
  is EXACT (180 deg/pulse => 30 rpm at 1 Hz) and the clock train
  lands **1.0 turns/hour** verified live; M1-M3 torque transforms
  exactly but SPEED is an honest ASSUMPTION (quasi-static motors
  don't predict it). Envelope = mean/peak/worst-case, never one
  flattering number; a duty met only at PEAK counts as UNMET;
  `priceOfTheRatio` (speed divided, efficiency lost, backlash
  added) never omitted. LIVE duty check on M1 vs 1 Nm honestly
  reports needing ~13,100x more torque.
- ⚠ DEPLOY NOTE: gears was added to the LIVE service env via
  `docker service update --env-add POLARI_MODULES=...` (16 modules,
  14 online). The DURABLE path is a ModuleAssignment row +
  `pol topology render staging-a` — NOT done, because re-rendering
  carries the machine==staging-a-vs-pol-core constraint gotcha
  documented at the top of this file. Do that deliberately.
- Suites: selftest_gears 53/53, NEW gears_liveboot_probe 11/11.
- ALSO fixed generally (Dustin: "make fixes more general"):
  * **Scene assets**: `SimSpaceRendererFactory.create()` now awaits
    `ensureSceneAssets()` (2D shapes+styles / 3D meshes+materials+
    textures) before returning a renderer. The "load the library
    first" bug had shipped TWICE (mag-7b parts untinted, mag-7
    shells drawn as cubes) = the wrong layer owned it. Pages
    dropped their hand-loads.
  * **Rounding**: `_sig()` (significant figures) replaced every
    fixed-decimal `round()` in the gear solver. Fixed-decimal
    rounding is wrong for any payload that mixes scales, and a
    drivetrain mixes scales BY DEFINITION — round(x,9) ate the
    clock's 1/60 rpm, round(x,12) then ate a 4e-6 Nm torque, and
    mag-3 hit it a third time on flux density. Now guarded by its
    own selftests.
  * Pre-existing `selftest_lazy_imports` 14/15 -> 15/15 (motors
    stub tuple).
- NEXT (gears): gr-2 strength screen, gr-3 involute geometry
  generator -> MathShapeDefinition rows, gr-4 `/mechanics/gears`
  3D page (reuse the mag-7 single-renderer pattern), gr-6
  planetary/worm algebra, gr-7 business+tech-tree splice.

## ⏰ mag-21 LIVE 2026-07-30: THE CLOCK AS A PRODUCT
- ⚡ **"Is this a wristwatch?" — NO, and by the numbers.** The ROTOR
  is watch-scale (2 mm), which is why the question is fair. But the
  widest wheel is **180 mm** (so the movement alone is wider than a
  pocket watch), it drives a 260 mm face, and **power settles it**:
  20 mA for a 30 ms pulse at 1 Hz = 3% duty = **0.6 mA average**
  against ~15 µA for a commercial wall movement and ~1 µA for a
  watch — **40× a wall clock, 600× a watch**. A watch cell lasts
  4 DAYS; an AA lasts **5.7 months** where a bought movement gives
  years.
- **The cause was already on record**: µ~2 castings make a coarse
  detent needing mA where laminated steel needs µA. **The power
  draw IS the permeability gap, arriving as a battery bill.**
  `movement_class` says HOW to make it a watch (more, smaller
  stages + close the permeability gap) rather than only saying no.
- **`product_datasheet` composes NINE analyses** — classification,
  power/battery, train, face, hand drive, BOM, winding, pinion
  fatigue, true price — and computes nothing new on purpose. A
  section that can't resolve reports its own absence, so the
  product never looks complete when it isn't.
- ⚡ **VERDICT: NOT SHIPPABLE**, three blockers named: pinion fails
  fatigue at SF 0.39; power is 40× commercial; two parts can't be
  costed/massed.
- Headline: *a wall-clock movement driving a 260 mm face, 1.15 g of
  parts, 0.6 mA average, 5.7 months on an AA.*
- Honesty: composed caveats **COMPOUND** — it says it is a design
  review, not a datasheet for a buyer.
- `/api/motors/product/{design}`; selftest_motors 173 → **181**.

## 🧮 mag-20 LIVE 2026-07-30: PHYSICS AS CONFIGURATION, not code
⚠️ **Dustin's correction, and it was fair**: we have configurable
equations + existing engines, so CONFIGURE and REUSE rather than
writing custom code — prevents bloat and duplication. mag-15..19
hard-coded closed-form physics in Python while EquationDefinition
rows and a sympy/LaTeX executor already existed.
- **12 formulas now live as CONFIGURATION**: Hertz p_max + surface
  tensile, SCG life (inverted AND forward), Weibull derate, Archard
  wear, eddy loss, Maxwell pull, 2 planetary ratios, hand
  imbalance, tooth load. Each carries LaTeX, what every symbol
  MEANS, and what it returns. They seed as real EquationDefinition
  rows and `evaluate_named` prefers the **LIVE row over the seed**,
  so an edited formula takes effect **without a deploy**.
- **The migration is VERIFIED, not asserted** — configured formulas
  reproduce the Python numbers they replace (SCG life 200.85,
  Weibull 0.5627, planetary 12.0), and those equalities are
  selftests.
- **What legitimately STAYS in code**, as a decision not an excuse:
  refusals (policy, not arithmetic); **criterion selection** (von
  Mises vs max-principal is a decision about WHICH formula
  applies — exactly what a formula can't encode); role predicates;
  units/plumbing; and calls into existing engines, because using
  scikit-fem and re-implementing it are opposite acts.
- ⚠ **LESSON**: bind π EXPLICITLY as a symbol. Left as `\pi` the
  executor returns a symbolic expression — the first Hertz eval
  came back `4180707·sqrt(1/pi)` instead of 2.36e6 Pa.
- `/api/motors/equations` (catalog, and
  `?evaluate=<name>&<symbol>=<v>`); selftest_motors 165 → **173**.
- ⚠ **NOT FINISHED**: motor_stress / motor_fatigue / contact_wear /
  lifecycle_cost still compute in Python. They should call
  `evaluate_named`. This commit builds and PROVES the seam; it does
  not complete the migration. **That is the next job on this
  thread.**

## 🕰️ gr-6 LIVE 2026-07-30: planetary + WHAT SIZE CLOCK
Dustin asked what a planetary driving all the hands looks like, and
what size clock this motor is meant for. Three computed answers:
1. **Planetary table is now DATA** (gr-1 refused to guess it): which
   member is HELD sets ratio AND direction — ring-fixed
   `1+N_r/N_s` (workhorse), sun-fixed `1+N_s/N_r` (mild),
   carrier-fixed `-N_r/N_s` (**REVERSED**, and the minus is the
   point). Buildability CHECKED: planet must fit the annulus as a
   whole tooth count, and equal spacing needs (ring+sun) % planets
   == 0. A 12:1 set is sun 12 / planet 60 / ring 132.
2. ⚡ **But a planetary is probably WRONG here**, by numbers not
   taste: that 12:1 needs a ring **11× the sun diameter**. The
   classical **MOTION WORKS** gets the same exact 12:1 from two
   small offset meshes (12→36, 10→40 = 3×4) and is **already
   concentric** — the hour wheel rides as a TUBE over the cannon
   pinion. Coaxial output is what a planetary would be chosen for,
   and the motion works already has it, more compactly.
3. ⚡ **THE SIZE ANSWER, from our own torque**: an unbalanced hand
   is T = m·g·r_cg. At the 1.7e-3 Nm this train delivers — 100 mm
   hand SF 4.8 ✓, 120 mm the longest clearing SF 3, 150 mm SF 2.2
   ✗, 200 mm SF 1.2 ✗. **A face ~260 mm across: an 8–10 inch WALL
   CLOCK, not a tower clock.**
   **Counterbalancing more than doubles it (~620 mm)** — a balanced
   hand has ~zero gravity imbalance, leaving only bearing friction,
   which is why large dials use counterweighted hands. A knob, not
   an assumption.
- NOT modelled and named: hand aerodynamics, and **STICTION** — the
  real limit, because a stepper must break it EVERY step and a
  missed step never catches up.
- `/api/gears/{planetary,clock-face/{train}}`; selftest_gears 53 →
  **62**.

## 💰 mag-19 LIVE 2026-07-30: THE TRUE PRICE per lifespan unit
Dustin: cheapest is not instantaneous cost — determine the most
sensible LIFESPAN UNIT for a product, then cost per one of those.
Upfront matters on a low budget / urgent use; lifetime usage is the
true price. BOTH are computed and BOTH kept.
- **STEP 1, the unit, is the modelling decision** and its reasoning
  travels on every report. A clock produces TIME KEPT →
  `year-of-timekeeping`; NOT runtime hours (it never stops) and NOT
  mass (it consumes nothing). Also seeded: rotating-machine →
  million-revolutions, gear-train → million-tooth-engagements,
  mould → casts (what mold-1 already records), vessel →
  growing-seasons. An undefined kind REFUSES.
- **STEP 2, life**: the brittle fatigue law is **INVERTED** —
  N_fail = (S/s)^n with S Weibull-derated first — instead of
  passing/failing a fixed horizon.
- ⚡ **THE HEADLINE**: the cast geopolymer pinion costs **1 cent
  upfront** and needs **~1.58 MILLION replacements in ten years** →
  a true price near **$1600 per year-of-timekeeping**. The cheapest
  part is by far the most expensive product. Fired ceramic: 8 cents
  upfront, **$0.008/year** — five orders cheaper to OWN while 8×
  dearer to BUY.
- Candidates are **ROLE-SCREENED first** (mag-17): a material that
  cannot do the job is not made a bargain by being cheap. Both
  orderings are produced so they CAN disagree, and disagreement is
  reported as the finding.
- **Two honesty guards**: extrapolation CAPPED at 1e12 cycles (n=45
  on a 6× margin predicts 1e85 — arithmetic, not knowledge; past
  the cap the honest statement is "not fatigue-limited"), and
  capped/prior-based lifespans are FLAGGED so an unearned number
  cannot quietly win. Trust the ORDERING, not the absolute value.
- `/api/motors/true-price/{design}/{part}`; selftest_motors 155 →
  **165**.

## 🔬 mag-18 LIVE 2026-07-30: contact / wear / eddy — roles delivered
The three analyses mag-17's roles NAMED as not-built are now built.
- **CONTACT** (colliding role): Hertz line contact. The whole tooth
  load rides a **0.42 micron** patch at 2.5 MPa — that concentration
  IS why the role demands hardness over bulk strength. A brittle
  tooth is judged by the **surface TENSILE stress at the trailing
  edge** (0.50 MPa), not peak pressure, which is compressive and
  would flatter a ceramic 10-20x. On that criterion contact PASSES
  at SF 8.0 — so contact is not the threat here; fatigue is.
- **WEAR** (sliding role): Archard as a **BAND**, because k spans
  SIX orders across pairs/lubrication. ⚡ A **dry cast-on-cast**
  pinion loses **0.15-1.5 mm³ in ten years against a ~7 mm³ part**
  — the upper band is a FIFTH OF THE PINION. Lubricated metal is
  ~4 orders better: why clock pivots are oiled, and a second
  independent argument for brass.
- **EDDY DRAG** (field-buffered role): evaluated AT THE STATED
  BUFFER, as promised. At 2.6 mm the field falls to 0.057x and —
  since loss goes as **B²** — the loss to 0.0032x = 1.3e-18 W/m³,
  negligible. The buffer argument holds quantitatively. Weakest
  link NAMED: the 1/r³ decay is an approximation; the upgrade is to
  read B from the mag-fv field views. A part with no stated
  `field_buffer_mm` REFUSES the check.
- `/api/motors/contact/{design}/{part}`; selftest_motors 145 →
  **155**.

## 🎭 mag-17 LIVE 2026-07-30: ACTIVE ROLES BY DOMAIN
Dustin: parts perform generic ACTIVE roles; moving parts need all
stresses+fatigue; a colliding gear tooth is its own role; a
mechanical part in a magnetic motor must not interact with the
fields. Then: isolate roles by CATEGORY, with INTERSECTIONAL ones.
- Roles carry a **DOMAIN** (mechanical / magnetic / electrical /
  thermal / intersectional); a part is judged against the **UNION**
  of its roles. The same property is demanded in OPPOSITE
  directions by different domains — `flux-carrying` wants mu>=100,
  `field-inert` wants mu<=1.2 — so one material is excellent in one
  role and disqualified in another. That is the point.
- **INTERSECTIONAL exists for a real reason**: brass fails a strict
  field-inert test on conductivity, yet every real clock uses a
  brass pinion — because it sits OUTSIDE the gap where dB/dt is
  small. That is GEOMETRY, which a property-only screen cannot
  argue. So `field-buffered` **demands `field_buffer_mm` be stated
  on the part row** — otherwise the role is a loophole, not an
  argument.
- ⚡ **FIXES the copper-pinion bug**: copper is now UNVIABLE on
  hardness (50 HV brinells as a tooth face). LIVE pinion viable set
  = fired ceramic, alumina, **brass** — what real movements use.
- ⚡ **GALVANIZED BIO-STEEL, both axes**: **VIABLE for the stator**
  (mu~2000 = three orders better flux path than our mu~2 castings,
  AND a real fatigue endurance limit no brittle casting has);
  **UNVIABLE for the pinion** (ferromagnetic + conductive). Same
  material, opposite verdicts, decided by the ROLE.
- **BIO ROUTES, not overclaimed**: biochar-reduced iron is real and
  historically the ONLY route, but the ZINC is not bio-produced
  (bioleaching RECOVERS zinc from tailings) — so it is bio-CARBON
  steel. Copper IS bio-reachable: Acidithiobacillus bioleaching is
  ~20% of world production and the **biomining module already
  seeds that agent** — so "bioleached copper", not "bio brass".
- `/api/motors/{roles,role-screen}/{part}`; selftest_motors 137 →
  **145**.
- NEXT on roles: Hertzian contact stress, eddy-drag at the stated
  buffer, and wear — all three are NAMED in the role definitions as
  not-built rather than silently skipped.

## ♻️ mag-16 LIVE 2026-07-30: FATIGUE reverses the static answer
- A clock steps ONCE PER SECOND = 3.2e8 cycles in ten years. TWO
  models, because the physics differs by class:
  * **brittle-scg** (ceramics, cast geopolymer): **NO endurance
    limit**. Subcritical crack growth, sigma(N) = strength x
    N^(-1/n); low n (cement ~15) far worse than high n (alumina
    ~45).
  * **ductile-endurance-limit** (steel): real limit ~0.45 UTS.
  * **ductile-no-endurance-limit** (copper): S-N keeps falling —
    surviving 1e7 is not a promise about 1e9.
- **Second, non-optional derate for brittle**: strength is
  WEIBULL-distributed (fails from the worst flaw, not the mean), so
  design to a survival PROBABILITY: strength x (-ln P)^(1/m). Our
  castings m~7, alumina ~15. **The derates MULTIPLY.**
- ⚡ **THE FINDINGS — fatigue reverses static**:
  stator SF **10.53 static -> 1.48 fatigue** (FAILS);
  pinion SF **2.53 -> 0.39** (fails outright). A cast geopolymer
  keeps ~15% of its strength over ten years. The static check alone
  would have shipped a stator that looked comfortable.
- `substitution_search` holds geometry+load FIXED and varies only
  the MATERIAL: steel 95.9x, alumina 76.8x top it — which is what
  real movements use for pinions. **Makeable answer: FIRED FERRITE
  CERAMIC at 7.6x** = the Table 8.8 fire-the-casting rung we
  already have. The fix is a PROCESS we own, not a purchase.
- ⚠ **KNOWN GAP**: the search ranks by fatigue SF ONLY. Live it
  returns `bestMakeable = opt-copper-magnet-wire (40.9x)` — copper
  would pass fatigue and WEAR OUT as a pinion, and magnet wire is
  not a structural part at all. It needs a role/suitability filter
  (mag-2r roles already exist — wire them in).
- Model honesty: no S-N measured on any of our castings; MOISTURE
  accelerates crack growth in silicates (a clock lives in room
  air) so real n is likely WORSE; a part failing EVERY material is
  telling you the DESIGN is wrong, not the shelf.
- `/api/motors/{fatigue,substitutes}/{design}/{part}`;
  selftest_motors 126 -> **137**.

## 🧱 mag-15 LIVE 2026-07-30: FEM STRESS — will it break?
Dustin: "account for von mises and stress tensors ... to ensure the
apparatus will not break performing it's expected actions",
"using FEM".
- ⚠⚠ **THE CRITERION CORRECTION, read this first.** von Mises is a
  DUCTILE-metal criterion (distortion energy, deliberately blind to
  hydrostatic stress). That is right for copper/steel and **WRONG
  for our cast geopolymers and ceramics**, which are BRITTLE and
  fail by crack opening in TENSION. Judging a cast stator by von
  Mises would PASS a part that is already cracking. So brittle rows
  are judged by **MAX PRINCIPAL (Rankine)**, ductile by von Mises —
  both numbers always reported, only the verdict differs, and every
  verdict names the criterion and why.
- The argument is quantified, not asserted: 10 material rows gained
  E, nu, compressive_mpa, tensile_mpa, failure_class — and the
  compressive/tensile ASYMMETRY is the argument: **14.3x**
  (geopolymer-ferrite), 15.0x (bonded hexaferrite), 17.1x
  (sintered) vs **1.0x** copper. E and nu did not exist ANYWHERE
  before; FEM elasticity was blocked on them.
- **FEM engine extended** (scikit-fem linear elasticity): full
  tensor (sxx/syy/sxy/szz), von Mises, both principals + szz,
  max/min principal and max shear each WITH the location they peak
  (where a crack starts). Rectangle + optional OFF-CENTRE hole (the
  stator's end-bore). **Kirsch proves the solver**: SCF 2.836 →
  2.985 → 3.020 → 3.034 across refinement, monotone from BELOW.
  Exceeding the textbook 3.00 is CORRECT — 3.00 is the infinite
  plate; at d/W=0.1 Howland gives ~3.03. plane-stress vs
  plane-strain is a required knob and they differ.
- **LOADS derive from the machine**: tooth load F = T/r_pitch off
  the gear train it drives, magnetic pull B²A/(2µ₀) with B taken as
  remanence (deliberately conservative), self weight, and HANDLING.
- ⚡ **THE HONEST HEADLINE**: operating loads peak at **0.069 N**
  against a 5 N finger press. **ASSEMBLY GOVERNS** — it will not
  break doing its job, it will break being BUILT.
- ⚡ **THE ACTIONABLE FINDING, live**: stator **SURVIVES SF 10.5**;
  **rotor pinion AT RISK, SF 2.53** vs the 4.0 required for an
  unmeasured brittle casting. Small, cast, brittle — a firm thumb
  during assembly is enough.
- SF 4.0 not 1.5 on purpose: brittle strength scatters (Weibull),
  our castings are untested, strengths are literature-est.
- NOT modelled and said so: **fatigue** (a clock steps ~31.5
  MILLION times a year), fracture toughness/flaws, contact stress
  at the tooth flank, creep, thermal, cure-shrinkage residual.
- `/api/motors/{stress/{design}/{part},loads,criterion}`;
  selftest_motors 107 → **126**; selftest_fem_elasticity **41**.
- ⚠ **9th SEED-FIELD STRIKE**: the new properties went onto EXISTING
  live rows, so every stress call refused until 10 CRUDE PUTs. The
  rule was already written and still not followed — it is now a
  STEP: after any seed edit, GET a row and diff it before calling
  the feature live.
- NOT WIRED: ENGINE_REGISTRY has no `fem.elasticity` entry, so a
  MaterialScaleDefinition cannot point at the solver yet.

## ⚙️ mag-10c: the REALISTIC v2 Lavet motor now RUNS
Off-origin rotation solved exactly, not faked: math-shape geometry
carries ABSOLUTE coordinates (the v2 rotor is at x=-9.5) and
three.js composes world = position + R·vertex, so rotation alone
swings the part in an arc about the world origin. Rotating about an
axis through `a` means position = a − R·a; verified a point on the
axis stays fixed at every angle. Both geometries stay behind a
toggle that says what each is FOR. If the v2 scene row is missing
the card REFUSES rather than showing the schematic under a
"realistic" label.

## 🚀 mag-12/13/14 LIVE 2026-07-30 (three parallel agents, all green)
- **mag-14 M1 + M3 GEOMETRY**: M1 (6s/4p reluctance — shaft, hub,
  salient pole, stator tooth, yoke + coil as coaxial-cylinder
  differences so they take the EXACT tube mesh) and M3 (dual-stator
  axial flux: two 12-tooth disks about one 8-pole rotor, showing
  the TWO gaps that are the §2d thesis). Dimensions DERIVE from
  each design's params_json and the selftests check the arithmetic
  (tooth face 40.2 mm² vs stated 4e-5 m²; r=12.6 minus r=12.0
  reproduces the 0.6 mm gap). Arrayed by placing ONE tooth row 6×
  and ONE pole 4× via scene rotation — the mechanism that already
  spins the M0 rotor — not 14 near-identical rows. 13 part rows
  with physics in the M0 voice (M1's poles are torque-producing
  with NO magnet and want SOFT material — the opposite of M0's
  rotor). Scenes `motor-m1-viz` (19 bodies) / `motor-m3-viz` (36).
  ⚠ DELIBERATE GAPS: M3 has NO coils drawn — an axial coil is a
  trapezoidal wedge and a tube big enough to clear a 23 mm tooth at
  12 teeth on a 33 mm pitch circle would intersect its neighbours;
  the scene says so and a selftest asserts the absence AND the
  reason. M2 still has no geometry.
- **mag-12 REALIZATION PROMOTION as SUGGESTION**: evidence →
  suggested rung, never a mutation. Made-and-measured needs DIRECT
  evidence (a QA record naming the option); a measured
  MotorVerificationRun is only SYSTEM corroboration — a clock
  keeping time proves the rotor was magnetic enough, not that its
  B_r is what the row claims. Sim rows never count; reference-only
  rows never promote; bought commodities flag `vendorAttested` and
  the tool DECLINES to have an opinion. **The blind-spot rule holds
  again**: with QualityCheckRecord unreadable it reports
  `unjudgeable-here`, not an accusation — LIVE it says exactly that
  for 3 rows and names the blind spot. `/api/magnetics/promotion`.
  ⚠ KNOWN WEAK JOINT (named, not hidden): QA records tie to a
  product VARIANT and the variant→material map lives in bizops
  PRESTAGE_VARIANTS as CODE, not rows — so the option name must
  appear in variant/batch_note/notes. A `material_ref` on the QA
  record is the real fix.
- **mag-13 DRIVETRAIN CARD** on /magnetics/motor: envelope, duty
  with its binding constraint, and THE PRICE OF THE RATIO as the
  headline; speedBasis/torqueBasis make the M0-exact vs M1-assumed
  distinction visible on screen. Duty-unmet is amber not red — an
  unmet duty is a design fact, not an error.
- Suites: motors **107/107**, magnetics **51/51**, gears 53/53,
  bizops 85/85, meshassets 36/36, lazy-imports 15/15.
- ⚠ shape_units struck AGAIN on the 13 new part rows (masses read
  23 kg / 419 kg until backfilled; now 23 g / 419 g). **Any new
  MotorPartDefinition row needs the shape_units backfill.**

## 🔩 mag-11 LIVE 2026-07-30: the per-part bill + /magnetics/clock-motor
Dustin: "a frontend for that motor and display/analysis of its
pieces and materials used for them and their resulting part
properties and purposes for the clock."
- `MotorPartDefinition` joins what lived apart: geometry was
  MathShapeDefinition rows, materials were per-SLOT on the design,
  and nothing said which shape was made of what or WHY it existed.
  Each row carries `function`, `purpose` (its job in the clock),
  and `why_this_material` (the deciding property, not a
  description). Seeded for all 7 Lavet v2 pieces.
- Numbers DERIVE and refuse rather than guess: volume from the
  part's OWN shape row (same geometry the viewer draws → bill and
  picture cannot disagree), mass = volume × the material row's
  density, per-part GAPS listed (the coil's material is a
  supplychain item, so no density resolves — said, not faked).
- ⚠ **UNIT BUG FOUND**: `shape_properties` reports volumeCm3 (assumes
  cm) but the v2 geometry is authored in **mm** — reading it as cm
  made a **1.1 KILOGRAM** clock motor. `shape_units` is now explicit
  per part; the whole motor is **1.15 g**.
- ⚠ **defClassList**: the import and seed-pair landed but the
  defClassList entry did NOT (a replace that silently didn't
  match), so the class had no CRUDE table — and the symptom looked
  exactly like an unseeded table, not a wiring error. **grep every
  polariServer edit to confirm it landed.**
- ⚠ **8th seed-field strike, new flavour**: `shape_units` persisted
  as `None` on a BRAND-NEW class's first seed while sibling fields
  came through. Cause not diagnosed; rule: after any first deploy
  of a new class, GET a row back and eyeball the fields.
- FRONTEND `/magnetics/clock-motor`: v2 motor in 3D beside the piece
  list; selecting a part dims every other body (highlight by
  OPACITY so material colours stay readable — the point of the view
  is what things are made of) and expands its material, why that
  material, the property table with provenance chips, and measured
  volume/mass. Winding card alongside. BROWSER-VERIFIED.
- `/api/motors/parts/{design}`; selftest_motors 76 → 86.

## ⚡ mag-9 + mag-10/10b LIVE 2026-07-30 — motors pushed further
- **mag-9 THE WINDING REALITY CHECK.** Every torque number rested
  on `coil_turns x coil_amps` being ASSERTED. Now checked: does the
  copper FIT the bobbin (fill factor, hand-windable 0.60 /
  machine-only 0.75), what RESISTANCE (from copper resistivity —
  1.724e-8 reproduces the published AWG ohms/m to 4 figures, a
  constant that checks itself), what VOLTAGE (I x R vs the supply),
  what DISSIPATION (I²R as watts + watts/cm², **never a predicted
  temperature** — no thermal model of a cast composite exists).
  Back-EMF named as unmodelled. Wire cost from the mag-1 CITED
  spools. `/api/motors/{winding,winding-sweep}/{design}`.
  LIVE, all four rungs BUILDABLE: M0 1500t 44 AWG fill 0.56 182 Ω
  3.64 V of 12 V 73 mW \$0.01; M1 0.60; M2 0.59; M3 0.46.
  ⚠ **THE EPISTEMIC RULE worth keeping**: our own crude stand-in
  geometry may NOT condemn a design. Stated bobbin → an over-full
  winding is IMPOSSIBLE and names the report it invalidates
  (clock-sim / torque curve). Unstated bobbin → `window-unknown`,
  invalidates nothing, asks for the real bobbin.
  Also fixed: the gauge auto-pick iterated thickest-first and
  handed a clock coil 18 AWG (lamp cord); table gained 38-46 AWG.
- **mag-10/10b THE MOTOR IS A LAVET-TYPE STEPPING MOTOR** (Marius
  Lavet, 1936) — that is the name to look up. Dustin checked
  photographs: our 3D "looked nothing like it", correct. THREE
  geometries now coexist, each labelled: SCHEMATIC (two pole
  shoes + disc + pointer — shows WHY it steps), v1, and **v2 built
  from his reference photos** (Prof MAD, "Lavet type stepper motor
  in clock"): squared-C stator plate = plate MINUS big rectangular
  window MINUS bore-at-one-END (n-ary CSG difference); a BIG
  flanged bobbin 13 mm against a 26 mm plate with two lead wires;
  a STEPPED rotor (diametric magnet below + integrated pinion
  above + index mark). Scene `motor-m0-lavet-v2-viz`.
  ⚠ Teeth deliberately NOT drawn though the photos show them:
  gear geometry is GENERATED (gr-3), and decorative teeth meshing
  with nothing is the exact "close enough gear" mistake the
  mesh-asset catalog refuses.
- selftest_motors 44 → **76**. ⚠ **SEED-FIELD GOTCHA 7th STRIKE**:
  the winding params live INSIDE `params_json`, so this was a JSON
  *value* edit on live rows — hides even better than a new column.
  All four designs read `window-unknown` live until backfilled.
- MOTORS NEXT: M1/M2/M3 have no 3D parts yet (only M0 does); a
  drivetrain card on `/magnetics/motor` showing the gear output;
  measured-run → realization-promotion SUGGESTION (never auto).

## 🧩 mesh-1 LIVE 2026-07-30: license-gated mesh catalog + organ fit
## (framework cdabe2a; 17 modules on pol-core)
Dustin, after the PlantMap3D refusal: "find a few samples of generic
plant sub-morphologies that are genuinely open source 3D models,
which we can use as a pick and choose 'close enough for
approximation' mesh ... fine tune them until they look similar
enough to the original using our morphology and part based
definitions based on vectors" (+ "assets for gears" too).
- NEW `modules/meshassets` (requires plant_morphology).
- ⚠⚠ **CORRECTED SAME DAY — read this before touching the gate.**
  The first pass used an ABSOLUTE licence ladder and graded
  CC-BY-SA-4.0 / LGPL-2.1 "reference-only". Dustin: *"this whole
  project is GPLv3 and openly available as such, so it should meet
  criteria for use of most forms of open source licenses"* — and he
  was right. **Compatibility is a RELATION between two licences,
  never a property of one**, and being copyleft ourselves is what
  makes copyleft assets usable:
  * **CC-BY-SA-4.0 → COMPATIBLE** (Creative Commons' own 2015
    ONE-WAY declaration into GPLv3),
  * **LGPL-2.1 → COMPATIBLE** (§3 relicenses to GPL "v2 or later"),
  * **GPL-2.0-only** = the one genuinely blocking copyleft case,
  * **no licence at all still blocks** — default copyright grants
    nothing and our licence cannot invent permission (PlantMap3D
    unaffected by any of this).
  `PROJECT_LICENSE_SPDX = GPL-3.0-or-later`, verified from our own
  `./LICENSE` by the same method we apply to strangers. Generalize
  it: **any "is X allowed" gate must name what it judges RELATIVE
  TO**, or it drifts into folklore.
- **CITATIONS AS DATA** (Dustin: "we just need to ensure assets have
  clear citations tracked as data"): `citation_record()` emits TASL
  (title, author, source, licence) + terms link + a paste-ready
  line; `citation_manifest()` is the list a release ships and
  doubles as the do-not-ship list. A licence that REQUIRES
  attribution with a missing author reports the GAP rather than
  quietly crediting the website. LIVE: 5/5 citations complete.
  `/api/meshassets/{citations,citation/{asset}}`.
- ⚠ **SEED-FIELD GOTCHA, 6th STRIKE**: `author`/`license_url` were
  added one deploy AFTER the rows seeded, so every live citation
  read "(author UNKNOWN)" while the seed file had them. Backfilled
  7 rows by CRUDE PUT. Adding a field to an already-live class =
  plan the backfill in the SAME change.
- **VERIFIED sources (quote kept on every row, 2026-07-30):**
  Poly Haven CC0 (scanned, closest to real morphology) · Quaternius
  CC0 (stylized low-poly, 35 plants — cite the PACK page, the site
  index has no licence text) · OpenGameArt "CC0 - 3D Plants" CC0 ·
  **pd-gears PUBLIC DOMAIN** · MCAD involute_gears LGPL-2.1 ·
  PolyGear CC-BY-SA-4.0. ⚠ All three gear libs report NO licence
  via the GitHub API and have no root LICENSE — terms live in
  headers/READMEs. **The API alone is not the check.**
- PlantMap3D stays IN the catalog graded `unverified`: a
  written-down negative finding doesn't get re-discovered at cost.
- **THE FIT:** OrganModel already states organs as VECTORS, so
  fitting = per-axis scaling + one honest number,
  **SHAPE FIDELITY = min(scale)/max(scale)**. LIVE: basil leaf vs
  Quaternius broadleaf = **0.667 usable-with-distortion**; the
  strap/grass blade = **0.092 WRONG-SHAPE** (the metric catches
  what eyeballing a thumbnail wouldn't). Ranked SUBJECT-first, and
  rejects list their reason. Scope stated every time: bbox
  proportions only — never silhouette, venation or curvature.
- **GEARS REFUSE TO BE APPROXIMATED** (`approximation_valid` False
  as data): a gear is exactly specified and two only mesh if their
  specs agree, so a "close enough" gear is a broken part. Geometry
  gets GENERATED (gr-3) with public-domain pd-gears as the
  unencumbered algorithm reference — NOT MCAD/PolyGear (copyleft).
- Assets are POINTERS + measured bboxes; no third-party geometry
  vendored. Unmeasured rows refuse instead of inventing a size.
  Picks (OrganMeshChoice) never seeded — choosing is a human act,
  recorded with who accepted it and why.
- `/api/meshassets/{sources,candidates,fit}`; selftest 24/24;
  meshassets_liveboot_probe 8/8.
- NEXT: download + MEASURE the real bboxes (every current bbox is a
  prior — that's what the refusal path is for), an import path that
  caches the mesh into Mesh3DDefinition/MathShapeDefinition, and a
  picker UI on the morphology page.

## 🌱 PlantMap3D: NOT open source — see PLANTMAP3D_EVALUATION.md
All three `precision-sustainable-ag/PlantMap3D-*` repos carry NO
license (API + root check) = all rights reserved. The org licenses
23 of its ~100 other repos, so the absence is meaningful, not an
oversight to shrug off. DO NOT vendor. Keep as a benchmark
reference (stereo depth -> canopy height -> per-species biomass is
publishable method, independently implementable); the open ask is
to request a license. Named alternatives (P3D, Phenomenal, DPPP)
still need the SAME license check — a paper calling a tool "open
source" has already been wrong once here.

## ✅ SAME DAY 2026-07-30 (autonomous continuation): Fe2O3 HUNT
## CLOSED + mag-8 SPLICE, BOTH DEPLOYED + LIVE-VERIFIED
## (framework 7fb948b, angular d3e2906, pointers committed)
- PIGMENT Fe2O3 HUNT CLOSED: alphachemicals.com is a Shopify
  store — /products/red-iron-oxide.json exposes exact variant
  prices (updated same day). alpha-chemicals source + 2 citations:
  5 lb $9.50 (4.19/kg), 50 lb $53 (2.34/kg) EXACT; assay UNSTATED
  on the 'natural' listing = the caveat on both rows (glaze row
  documents 81%). RIPPLES: srfe12o19 solid-state feed 11.81 ->
  2.90/kg, citrate sol-gel 16.94 -> 8.04 — the §1b pre-hunt
  '<$5/kg' now lands TRUE and hexaferrite feed UNDERCUTS bought
  magnetite (coercivity premium became a discount; roles still
  soft-vs-hard). Headline docstring + requirement notes rewritten.
  Live cascade verified 2.899, anyEstimate false.
- mag-8 SPLICE: PRESTAGE_VARIANTS +4 magnetic goods (inductor
  core / sensor set / flux guides / M0 clock kit) — material_ref
  = magnetic-geopolymer-mix (cascaded), price_ref = stated PRIOR,
  and a DATA-LEVEL realization gate (bizops reads the
  MagneticMaterialOption table without importing magnetics;
  absent table = honest 'gate unassessed'). LIVE: all 7 variants
  plan (cores 10 units \$17.03 mats), gates show recipe-seeded /
  literature-demonstrated from the real catalog, SELLING gated;
  the kit states wire/driver/hardware EXCLUDED (BOM =
  /api/motors/materials). QA +qa-magnet-remanence (7 total);
  compliance +req-magnet-ingestion (16 CFR 1262) +
  req-emc-claim (voluntary, claim-blocking only) = 8 total;
  partnerships +deal-magnet-wire-coop (4 deals; copper = the one
  un-makeable input, pool the 10 lb tier); walkthrough shopping
  list now covers magnetic-geopolymer-mix (magnetite bag lands,
  9 items live). Tech tree electromagnetic-systems FILLED:
  4 theory assignments (magnetics+motors done=true live), 2 B-H
  data_deps surfacing as derived data-missing warnings (verified
  in /api/techtree/completion). business-start batch card renders
  the amber/green gate chips + exclusion note (browser-verified).
- ⚠ Seed-field backfills done live (3 PUTs, text/data fields on
  EXISTING rows): TechNode electronics/electromagnetic-systems
  (description + data_dependencies_json), srfe12o19 requirement
  notes, clayking-fe2o3-5lb citation_note. Re-GET verified.
- Suites: bizops 78->85, magnetic sourcing 24->25, biz probe
  16/16 (pins 6/6/3 -> 8/7/4), magnetics probe 39/39, techtree
  61/61, formulas 55/55, motors 44/44.
- REMAINING (mag arc): circuit editor + field-view SimSpace
  renderer, fem-2d field-map export, mathshapes Shape-row
  emission, MotorVerificationRun-driven realization promotion
  (measured runs exist as rows; auto-promoting catalog
  realization_level stays a HUMAN step per the knobs ethos).

## ✅ Task 1 — business stack LIVE on pol-core (browser pass PARTIAL)
- Images REBUILT from framework dev-od-1-odoo-bringup 93bc062 +
  angular dev-od-7-business-ui 814f3a9; deployed `pol swarm deploy
  node` with POLARI_MODULES=materialsScience,pspp,techtree,
  simulations,polariapps,supplychain,bizops,odooconnect,waxprint,
  scoring + POLARI_LAZY_BOOT=on. ⚠ RENDER GOTCHA: the stale
  .generated/stack-node.yml still said machine==staging-a — live
  constraints had been hand-swapped to pol-core; re-render MUST set
  POL_STACK_CONSTRAINTS "svc=node.labels.polari.machine==pol-core"
  for all 6 services or they go unschedulable.
- 10/10 modules ONLINE (health /api/health lazy-boot payload; the 15
  'disabled … POLARI_MODULES gate' entries are CORRECT honest state,
  not failures — a wait-loop that counts them as pending never
  exits, learned the hard way).
- API-verified live: bizops economy/sellability/deal-pricing/
  walkthrough, sourcing, odoo status (honest unreachable — no local
  odoo pair). biz_liveboot_probe 16/16 pre-deploy.
- ⚠ Proxy serves the NIP.IO domain (https://prf.192.168.0.210.nip.io)
  — prf.polari-staging.test gets 'proxy host mismatch' on this
  render (BASE_DOMAIN=nip.io).
- ⚠⚠ SAME-TAG REDEPLOY GOTCHA (bit us live): `docker stack deploy`
  only restarts services whose SPEC changed — rebuilding an image
  under the same tag (prf-frontend:staging) does NOT roll the
  service (frontend served the 35h-old msci build; /business/*
  'not navigatable'). Fix after any same-tag rebuild:
  `docker service update --force polari-node_<svc>`.
- ✅ VISUAL BROWSER PASS DONE 2026-07-29 (Chrome tools live after
  Dustin allowed mcp__claude-in-chrome__* in settings.local.json):
  /business/start — accordion 6 steps, cited shopping list w/
  store+price+citation + safety-critical lye callout, SELLABILITY
  panel in step 4 (red hard rule, BLOCKED context chips,
  attained-vs-needed, disclaimer), QA table honest-unmeasured,
  economy bar 3/8 + nextGap, partnerships w/ TRANSFER-PRICE WINDOWS
  (biomass 0-4.81 suggest 2.40 vs terms 3.50; unbounded flows show
  the citation ask). /business/odoo — both tiles DOWN w/ honest
  refusals + push/read-only chips, scenario cards + plan buttons +
  repinned-price notes, make-vs-buy verdicts (geopolymer 77.1%,
  wax 36.9% vs MachinableWax 11.01 EXACT), receipts honest-empty,
  bindings table incl sim-sale-orders. DARK MODE holds on both.
  App cert-trust dialog flow works (trust api host via
  /cert-trust + refresh).
  ⚠ ONE VISUAL DEFECT for the sty sweep: /business/start QA table —
  the runs/units/pass count badges overlap and clip the
  'unmeasured' label at the right edge (both themes; column too
  narrow for the three badges).

## ✅ MAGNETICS SECTION A — BUILT + TESTED 2026-07-29
Branches dev-mag-a-magnetic-materials (framework b96d72e, off
dev-od-1-odoo-bringup; + rf-node/suite pointer branches). NOT pushed.
- mag-1 (supplychain/magnetic_sourcing_seed.py, extends the src
  lists): 14 sources + 24 dated 2026-07-28 citations — SrCO3 exact
  (ClayKing 50lb tier 5.67/kg, Evans), Fe2O3 exact (5.54/lb glaze
  grade = 12.21/kg), BaCO3 (+toxicity caveat as data), magnet wire
  (Essex 22AWG 31.3/kg bulk anchor), AS5600 est, SimpleFOC (official
  EUR out-of-stock -> availability=potential; clone est), carbonyl
  iron exact, MnZn (UK-only retail), ceramic ring magnets + FT-140-43
  = benchmarks, 608 bearings/shaft, graphite, SrFe12O19 buy-side
  QUOTE-ONLY (GBP row documents the gap). 5 requirements + 6 formulas:
  srfe12o19 solid-state 11.81/kg feed + citrate sol-gel 16.94 (kiln
  excluded-loud, nitrate-chemistry caveat), magnetic-geopolymer
  35vol=58wt cascades 6.09/kg, sol-gel mortar 10.22, wax-ferrite
  10.01 (71wt printability trial-gated), ferrite-CNT mortar 9.96.
  ⚡ HONEST HEADLINE: plan §1b pre-hunt said <\$5/kg hexaferrite
  feed — exact cites land ~11.8/kg; pigment-channel Fe2O3 (Alpha
  Chemicals) = the named cheaper hunt. Currency guard added:
  non-USD citations REFUSE normalization. selftest_magnetic_sourcing
  24/24; formulas catalog 13->19 (55/55).
- mag-2/2r/2t: NEW module modules/magnetics/ (requires supplychain+
  materialsScience, wave 3, fully wired). MaterialUseRole x10
  (predicate knobs, honesty notes TRAVEL: Earnshaw, copper gap,
  mu~2 caveat; form axis; mechanism-tagged any-of roles),
  MagneticMaterialOption x31 (§1c catalog, realization ladder,
  buyable_cited DERIVED live, per-value provenance, NdFeB/steel
  reference-only), MagneticPowderDefinition x7 (2 theoretical
  watermarked; Fe16N2 + exchange-spring w/ L4 flag).
  Analysis: gates (sim always/cost cited-or-recipe/business
  made-and-measured), derived viability (magnetite FAILS
  torque-magnet, alnico excluded H_c 50<100, maghemite unassessed
  w/ ask), THE vol<->wt conversion, MG+Bruggeman predictors (MG
  2.07 vs FEM 2.196 @35vol — confirmation-run pointer to
  fem-effective-permeability), cost-if-real via the cascade,
  laddered_answer (torque-magnet: recipe-seeded=SrFe12O19 /
  theoretical=Fe16N2 / literature=NdFeB flagged).
  /api/magnetics/{catalog,roles,viability,search,powders,predict,
  ladder}. research-tools tree +hall-gaussmeter+inductance-test-rig
  (theory ref=magnetics); bizops QA +qa-wound-core-inductance (the
  made-and-measured earner; QA counts 5->6, research nodes 9->11 —
  assertions updated). selftest_magnetics 37/37 +
  magnetics_liveboot_probe 12/12 + biz probe 16/16 w/ magnetics OFF
  (stub path) + full sweep green.
- ✅ DEPLOYED LIVE 2026-07-29: magnetics in POLARI_MODULES on
  pol-core (11/11 modules online), /api/magnetics/* verified through
  the proxy, wound-core QA row seeded into the live DB (6 checks).
- ✅ mag-3 BUILT + DEPLOYED same day (framework 930f459):
  MagneticCircuit/Element/FluxNode rows -> 'magnetic-netlist'
  GraphCompiler -> MNA permeance solve (numpy DIRECT solve — lstsq
  lost 1e-4 accuracy on the scale mix); materials resolve against
  the Section-A catalog by reference; magnets = Thevenin H_c*l_m
  Norton-stamped; saturation FLAGGED never hidden (composites got
  volume-diluted B_sat est priors); op + sweep analyses (overrides,
  rows never mutated); SPICE-analogy parity gated on electrodevice+
  ngspice (ngspice NOT on pol-core — refusal is correct there).
  Seeds hand-pinned: gapped toroid 1.3501e-7 Wb (core = 98% of
  reluctance at mu~2 — the honesty datum as numbers), C-core+probe
  (sign conventions pinned), horseshoe+keeper+leakage (KCL split).
  /api/magnetics/{circuits,solve,parity}. 25/25 + probe 16/16 +
  sweep green. LIVE solve verified through the proxy.
- ✅ mag-4 BUILT + DEPLOYED (framework a2e766c): BlockSizeVariant/
  BlockLayoutDefinition/BlockPlacement/JointMortarAssignment;
  SELECTIVE MORTAR PER JOINT = flux routing by construction
  (selftest proves it: upgrading the plain joint raises loop flux
  by the exact predicted ratio); network GENERATES from the layout
  (blocks=nodes, joints expand to half/mortar/half chains, wound
  placements must be LIMBS, virtual overlay — generated rows never
  persist); dry-fit report (un-mortared adjacency = suggestion);
  layout_cost per-block + per-joint w/ Section-A gates traveling
  into the bill. Seed ring-core-demo: 4 magnetic bricks + 3
  ferrite joints + 1 PLAIN joint (deliberate gap) + coil + a
  bearing-seat on plain mortar (~zero-flux dead end). LIVE: loop
  2.12e-6 Wb, bill \$1.31 est-flagged.
  /api/magnetics/{layouts,layout/{n}/network|cost|dryfit}. 16/16.
- ✅ mag-fv (§A2) BUILT + DEPLOYED (framework b42c727):
  FieldViewDefinition/FieldThresholdBand (thresholds+color+alpha
  as data, USER-drawn sphere/box/cylinder shells)/FieldViewGroup
  (the alternation). Exact analytic primitives (dipole, infinite
  wire — idealizations stated), deterministic threshold-GATED
  dispersions ('absence = below threshold, not zero field'),
  shell FIT METRICS (precision/recall — the sphere-vs-dipole
  factor-2 compromise MEASURED), flux tubes from mag-3/4 solves
  (1D-per-path watermark), fem-2d refuses naming the field-map-
  export follow-up; real mathshapes rows = named gated seam.
  /api/magnetics/{fieldviews,fieldview/{n},fieldview-group/{n}}.
  23/23; probe 24/24; LIVE group answers all three modes.
- ✅ SECTION C CORE BUILT + DEPLOYED (framework 9f550a4): NEW
  module modules/motors (requires magnetics, wave 4). THE MOTOR
  LADDER per Dustin ('simple->advanced in tolerances AND samples
  people can build'; M0 = clock motor control case verified
  against TIME PROGRESSION): M0 Lavet clock stepper / M1 6s4p
  reluctance (no PMs) / M2 ferrite-PM / M3 dual-stator axial (§2d
  end goal) — every rung carries build_requirements_json (tools/
  materials-with-cited-refs/skills/hours). design_report = mag-2r
  role checks AT DESIGN TIME (magnetite rotor flags unviable);
  clock_sim (Lavet co-energy, detent+coil amplitudes calibrated
  from the reluctance network; alternating pulses step 180deg,
  same-polarity honestly fails, dead coil = full clock error;
  LIVE: 60/60 steps 0 error); torque_curve (PARTIAL dW'/dtheta at
  held currents — total-derivative zero-means, caught by test;
  load-angle knob; dual gap DOUBLES mean torque, computed);
  torque_parity (hexaferrite vs NdFeB 3.33x area, dual-gap 1.67x,
  watermarks). MotorVerificationRun rows never seeded.
  /api/motors/{designs,report,clock-sim,torque,parity}.
  20/20 + probe 29/29.
- ⚠⚠ SEED-FIELD GOTCHA STRUCK AGAIN (4th time): live rows seeded
  before mu_r_eff/b_sat_t additions needed explicit CRUDE PUTs
  (multipart polariId+updateData; use curl --form-string — plain
  -F truncates values at ';'). Backfilled live:
  opt-bonded-hexaferrite-geopolymer (mu_r_eff 1.15),
  opt-geopolymer-ferrite (b_sat 0.21), opt-fired-ferrite-ceramic
  (b_sat 0.24).
- ✅ mag-7a + MOTOR-IN-ACTION PAGE (framework ba89039, angular
  dev-mag-7-motor-ui 2fc53d7+, BOTH deployed + BROWSER-VERIFIED):
  /api/motors/materials/{design} = COMPLETE MATERIAL
  ACCOUNTABILITY (slot -> option -> per-value provenance -> msci
  FEM by reference -> powder -> dated citations/recipes/cascade;
  derived composites follow their FILLER powder, labeled; absent
  links stated). /magnetics/motor page: M0 animation DRIVEN BY THE
  SOLVER (clock-sim history replay, red rotor ORIENTATION VECTOR,
  coil polarity colors, live steps/missed/clock-error vs time,
  theta mod 360 + half-turn counter, 'watch it honestly fail'
  same-polarity checkbox), M1-M3 torque curves, build-this-sample
  card, accountability panel w/ provenance chips + citation links.
  Browser-verified live: 11 pulses -> 11 steps, 0 error, arrow
  stepping. ⚠ THREE more live-row backfills done via CRUDE PUT
  (bonded rotor mu_r_eff + powder_ref, composites' b_sat_t) — the
  seed-field gotcha; --form-string not -F.
- ✅ mag-7b MOTOR 3D (framework +motor_shapes, angular
  dev-mag-7-motor-ui, DEPLOYED + browser-verified): every M0 part =
  a MathShapeDefinition row (rotor disc/pointer/shaft/poles/coil
  CSG ring — the SAME geometry the wax-mold seam casts); 7 motor
  Material3D rows incl the coil polarity pair. The /magnetics/motor
  3D card drives ThreeSimSpaceRenderer directly: parts resolve via
  mathshape: refs, rotor rotates from the clock-sim replay, coil
  material + bore field vector FLIP with each alternating pulse
  (the visible AC that walks the rotor), orbitable. 2D card stays
  (Dustin: both, for intuition). Live set now 15 modules
  (+mathshapes,aquaponics,plant_morphology for /api/shapes).
  ⚠ GAPS named: CSG surface returns points w/o triangulation (view
  uses solid coil outer meanwhile); Material3DLibraryService needs
  load() before direct renderer use (fixed in page); cylinder
  surfaces render sidewalls w/o caps (disc reads as a band);
  proper SimSpaceDefinition scene row + camera = mag-7 remainder.
- ✅ mag-6 BUILT + DEPLOYED: MotorControllerProfile (board/sensor/
  limits knobs, item_ref -> mag-1 cites) + PhaseBindingDefinition
  (phase->shield terminal; FPGA column named-not-wired);
  simplefoc_config generates the Arduino snippet FROM ROWS (pole
  pairs from the design; M0 REFUSES FOC — wants its 1 Hz pulse;
  dual-stator v1 parallels). /api/motors/drive/{design}. 33/33 +
  probe 32/32 + LIVE verified.
- NEXT: mag-7 remainder (SimSpaceDefinition scene row for the
  motor, circuit editor, field-view renderer; CSG triangulation +
  cylinder caps in the shape mesher; drive card on the motor
  page), fem-2d field-map export, mathshapes Shape-row emission,
  pigment-channel Fe2O3 cite, MotorVerificationRun recording seam,
  mag-8 business splice (OLD next-list follows:) (MotorControllerProfile +
  PhaseBindingDefinition), mag-7 remainder (circuit editor,
  field-view SimSpace renderer), fem-2d field-map export,
  mathshapes row emission, pigment-channel Fe2O3 cite,
  MotorVerificationRun recording seam. ngspice absent on pol-core
  so /api/magnetics/parity refuses honestly there.

---

# ⚡ DEVICE RENAME — 2026-07-27 (roles = accountability)

**Machines renamed so the name IS the mandate** (Dustin):
- **pol-core** (was staging-a, this HP box) — RESEARCH/Polari core;
  the node stack lives here.
- **isle-core** (unchanged) — ISLE-MESH/infra/hardware-integration
  core; science engines; its own Claude instance.
- **econ-core** (was lightweight, the DNB20) — BUSINESS-OPS/ECONOMICS
  core; the Odoo host (od-0 answered: sims FIRST, real ops much
  later).
Applied LIVE: swarm node labels + ALL service constraints swapped
(everything healthy), topology machine/instance rows repointed
(+roles in notes), nodes.yml keys+roles, ssh alias econ-core added
(legacy 'lightweight' still works), CLI defaults POLARI_LOCAL_NODE
-> pol-core, manifests re-rendered parity-OK. ⚠ Cleanup TODO: two
TOMBSTONE machine rows ('staging-a', 'lightweight' — notes say
renamed-to) remain in the topology table; delete via the Topology
UI/CRUDE when convenient. The TOPOLOGY itself is still NAMED
'staging-a' (deployment name, not a device) — renaming it to e.g.
'pol-core-deploy' is a separate decision. Deploy-command examples in
older sections below still say staging-a — read them as pol-core.

---

# ⚡⚡⚡⚡⚡⚡⚡ NEXT WORK (2026-07-28, READ FIRST): (1) REBUILD +
# BROWSER-TEST THE BUSINESS STACK, then (2) BUILD MAGNETICS SECTION A

**Dustin's directive at handoff: "bring things back up and rebuild
so we can test the business logic", then the magnetics arc.**

## Task 1 — Redeploy pol-core with the business modules, browser pass
Everything is committed on the branches (below) but NOTHING browsable
runs it yet: the live polari-node swarm stack is the msci build
(POLARI_MODULES=materialsScience,pspp,techtree,simulations,polariapps,
baked image prf-backend:staging, no bind mount).
1. Rebuild backend+frontend images from the CURRENT branches
   (framework dev-od-1-odoo-bringup 93bc062, angular
   dev-od-7-business-ui 814f3a9). `pol help` / `pol swarm help` are
   authoritative; deploy path is `pol swarm deploy node` (renders
   .generated/stack-node.yml, stack name polari-node).
2. Add to pol-core's POLARI_MODULES: supplychain,bizops,odooconnect
   (+waxprint,scoring if not already; bizops FEATURE_REQUIRES
   supplychain). Module env comes through the stack render — check
   nodes.yml/ModuleAssignment path from the mlb work.
3. SANITY BEFORE DEPLOY (cheap, ~3 min): from a throwaway cwd run
   polari-framework/tests/biz_liveboot_probe.py (16/16 expected;
   header has the exact invocation). ⚠ seeding is DB-GATED —
   hasDB=False boots have empty tables BY DESIGN.
4. Browser pass at https://prf.polari-staging.test after deploy:
   - /business/start — walkthrough accordion (cited shopping list,
     batch card, readiness rungs, SELLABILITY panel w/ red hard
     rule + context chips, QA table 'unmeasured', risk callouts),
     partnerships board w/ TRANSFER-PRICE WINDOWS (biomass
     [0-4.81] suggest 2.40 vs term 3.50), economy bar 3/8.
   - /business/odoo — instance tiles (both DOWN unless step 5),
     scenario cards + plan-first previews, make-vs-buy verdicts
     (wax now ~36.9% vs MachinableWax EXACT — was 68.5 vs the est),
     receipts/bindings tables (sim-sale-orders binding visible).
   - Theme check per styling rules (text by SURFACE tokens).
5. OPTIONAL live odoo: `pol odoo up` locally lights the tiles;
   or point ODOO_SIM_URL at econ-core (http://192.168.0.66:8069,
   pair RUNNING there w/ nightly backup cron). For a REAL
   pull-orders test the sim db needs the sale app (-i sale) + an
   order or two; refusals until then are correct behavior.
6. Odoo UI itself (works TODAY, no deploy needed):
   http://192.168.0.66:8069/web/login?db=odoo_sim (and ?db=odoo_ops)
   — admin passwords were printed in-session only; reset via odoo
   shell over ssh econ-core if Dustin lacks them.

## Task 2 — MAGNETICS: build SECTION A first
Plan = MAGNETIC_MATERIALS_PLAN.md (suite da1b1c6) — FULLY SPEC'D
after 5 refinement rounds with Dustin (mortar monoliths, dual-stator
axial flux, SimpleFOC, slot-matrix w/ selective magnetic mortar,
mag-2r role taxonomy w/ derived viability, §1b local hexaferrite
ladder from POTTERY CHEMICALS, §1c full option catalog w/
REALIZATION_LEVELS gating sim/cost/business). Build order: mag-1
(sourcing/formulas/citations: SrCO3+Fe2O3 pottery channel EXACT,
magnet wire, AS5600, SimpleFOC shield, carbonyl iron, NiZn/MnZn,
ring-magnet benchmark) -> mag-2/2r/2t (properties+realization
ladder, MaterialUseRole predicates, MagneticPowderDefinition +
laddered sweeps) -> then Section B blocks. Memory:
magnetic-materials.md has the full refinement trail.

---

# ⚡ PREVIOUS ARC: ODOO INTEGRATION — 2026-07-27 (complete, see below)

**Dustin's next arc, handed to the NEXT AGENT: integrate Odoo as the
backbone of BOTH business simulations AND real business ops.** The
full plan is `ODOO_INTEGRATION_PLAN.md` (suite root) — od-0..7 with
the architecture (one Odoo server, TWO databases sim/ops, the hard
sim/ops separation invariant, Keycloak SSO, JSON-RPC connector module
`odooconnect`, bindings-as-data, gm mover coverage for odoo +
odoo-postgres, the wax-print micro-business as the first scenario).
Start at od-0 (Dustin decisions: version pin, host machine, ops
accounting now-or-later), then od-1 service bring-up modeled on
pol-keycloak/pol-mariadb service defs. Everything below this section
(gm/mlb/glass) is DONE and on dev — it is the machinery the Odoo
work rides on (movers, quiesce, lazy boot, receipts, topology).

## ⚠️ MAGNETICS — PLANNING ONLY 2026-07-28 (next direction)
Dustin: magnetic geopolymer + magnetic sol-gel -> magnetic circuits
-> 3-phase motors, block-based like the circuit work. Plan =
MAGNETIC_MATERIALS_PLAN.md (mag-0..8). Key facts found: the
"isle-core notes" = the electrodevice block pattern itself
(~/ncg-matrix/polari-framework there; same module local) — rows ->
GraphCompiler seam -> solver -> honest refusals, mirrored via the
reluctance analogy (MMF~V, flux~I, reluctance~R). msci-22 already
has the composite ladder LIVE (geopolymer-ferrite mu 2.196 @35vol%,
sol-gel-ferrite 1.714, wax-ferrite printable); src-6 costed
magnetite (buy 9.70 wins vs make 20.11). PHYSICS HONESTY pinned in
plan: mu~2 is LOW (air-gap-dominated parts yes, motor iron no);
magnetite = soft (cores) NOT permanent magnets — hard ferrite
SrFe12O19 = citation gap; motor v1 = reluctance-first (all costed
today) then ferrite-PM BLDC once cited. mag-0 decisions await
Dustin (motor target, gaussmeter buy, module home, solver parity).

## ✅ biz-5 TRANSFER-PRICE DISCOVERY — 2026-07-28 (scenario-3 static)
- deal_price_window (bizops_deals.py): per-flow viable window =
  [supplier make-cost + minMarginPct, buyer's cited alternative
  (alternative_item_ref, default = item at retail)]. No recipe ->
  floor 0 + supplier-must-confirm; no citation -> unbounded + the
  ask; empty window says why. Midpoint = SUGGESTION never auto;
  dynamic half = scenario-engine re-run pointer, plan-first.
- Live: biomass [0, 4.81 exact] suggest 2.40 (seeded term 3.50
  shown beside); husks [0, 1.32~est]; pot flow unbounded (cite
  retail pots = the ask). /api/bizops/deal-pricing[/{deal}].
- VISUAL: windows on the partnership cards (/business/start), ng
  build green. selftest_bizops 78/78.
- Framework f066d53 + angular 814f3a9. Dynamic sweep (live odoo
  scenario at candidate prices) = open follow-up.

## ✅ src-9 CITATION HUNT — 2026-07-28 (honesty corrections)
- MachinableWax EXACT: pellets $49.95/10lb sale (reg $64.95) =
  11.01/kg — old est 22.05 was ~2x high; wax-vs-substitute verdict
  now ~36.9% cheaper (was 68.5). Margin SHRANK honestly.
- waste-glass-fines CITED (Tri-City 40/70 blast media $10.50/50lb
  = 0.46/kg, needs milling) + waterglass-from-waste-glass-v0
  formula 1.58/kg (sand 1.54 still wins — cascades unchanged).
- rice hulls EXACT $32.50/50lb (Seven Springs); candelilla EXACT
  $60/kg (VedaOils tiers) vs ~21/kg marketplace est — scatter real.
- 34 sources/41 citations/13 formulas. Framework 026b13f.
- Remaining gaps: bagasse ash (sugar-mill channel, no US retail),
  exact SWCNT grade, soda-ash fused-route wiring, beeswax/ferrous/
  hulls-est re-cites at purchase time.

## ✅ od-4b ORDER FEED + LIVE-BOOT PROOF — 2026-07-28
- /api/odoo/pull-orders: sale.order LINES -> ProductOrder rows via
  binding 'sim-sale-orders' (odoo_orders.py holds the derivations a
  flat field map can't: mapping ladder x_polari_ref > default_code >
  honest 'unmapped:'; volume m3->L w/ flagged 1.0 fallback; due_days
  from commitment_date; state map draft/sent->requested,
  sale->accepted, cancel->refused). Same provenance/conflict/receipt
  discipline as od-4. selftest_odoo_orders 20/20 incl. THE SPLICE
  (order planner over the pulled book). Needs sale app in odoo_sim
  for live use — pulls refuse honestly until installed.
- LIVE-BOOT PROOF: in-process boot of the REAL polariServer
  (hasDB=True — seeding is DB-gated by design, see
  ensureDefinitionTables 'no database, skipping') with
  supplychain+bizops+odooconnect enabled: 15/15 (seeds land, all
  bizops/sellability/qa/walkthrough routes answer, binding seeded).
  Scratch script pattern: managerObject(hasServer=True, hasDB=True)
  + falcon testing.TestClient — first non-fixture proof of the biz
  stack. Framework 08190b1.

## ✅ biz-4 COMPLIANCE + QA — 2026-07-28 (sell it legally, honestly)
Dustin: not-food-safe must NOT sell as food-safe; legal requirements
per product kind tracked at attainment LEVELS; QA per product kind.
- COMPLIANCE_LEVELS ladder = unassessed -> theoretical-pass ->
  self-test-pass -> certified-third-party-pass. ComplianceRequirement
  rows (kind legal-mandatory|market-rule|voluntary-standard,
  applies_context, required_level, reference_note) gate sale
  CONTEXTS; ComplianceRecord rows earn levels (variant-scoped or
  ''=business-wide). 6 seeded: food-contact (REQUIRES certified —
  the hard rule), honest-labeling, business-license, market-vendor
  rules, CPSIA children's, plant-safe leachate-pH (voluntary).
- sellability_report (bizops_compliance.py): per-context
  allowed/blocked with blocker sentences; legal-mandatory unmet
  blocks the CONTEXT, voluntary unmet blocks only the CLAIM;
  canSellPlainGoods; every report carries NOT-LEGAL-ADVICE.
- qa_report: QualityCheckDefinition (5 seeded: visual-crack,
  dimensional-fit, water-tightness, cure-hardness, leachate-pH
  which doubles as plant-safe evidence) + QualityCheckRecord pass
  rates; zero records = 'unmeasured', never fake 100%.
- Routes /api/bizops/sellability/{business} + /qa/{business}
  (?variant=); sellability embedded in walkthrough sell-and-log
  step; 4 classes + 2 seed lists wired in polariServer.
- VISUAL: /business/start sell step renders hard rule (red),
  context chips allowed/BLOCKED, per-requirement attained-vs-needed
  chips, disclaimer; new QA table w/ pass rates (warn <90%),
  honest 'unmeasured'. ng build green, NO browser pass.
- selftest_bizops 56 -> 71 (variant-scoped certification, no
  cross-requirement leaks, claim-vs-sale, honest unmeasured).
Framework ea59b74 (dev-od-1-odoo-bringup), angular 66fc5da
(dev-od-7-business-ui). NEXT candidates: browser pass on
/business/* (needs backend w/ odooconnect+bizops), od-4 order
bindings feeding ProductOrder from sale.order, scenario-3
transfer pricing, remaining citation re-cites.

## ✅ biz-3v VISUAL — /business/start (angular dev-od-7-business-ui)
The walkthrough as a PAGE (13c89f5 branch, new commit): six
numbered accordion steps, cited shopping-list table with ~estimate
markers, live batch card (budget input refetches), level-colored
readiness rungs, the step-up gate callout, severity-colored RISK
callouts w/ mitigations (safety-critical red), the local-economy
progress bar + derived milestones + nextGap, and the partnerships
board (coherent-chips, '(to be found)' markers) + mined deal-shape
suggestions. Cross-linked with /business/odoo. ng build green; NO
browser pass (needs backend w/ bizops enabled).

## ✅ biz-3 WALKTHROUGH + PARTNERSHIPS — 2026-07-28 (make it intuitive)
- STARTUP WALKTHROUGH (/api/bizops/walkthrough/{business}
  ?budgetUsd=): six steps in DOING order for a brand-new business
  maker, stages 0-1 ONLY (scope says so): prerequisites (printer
  assumed — the standing assumption) -> BUY MATERIALS (concrete
  shopping list from the cheapest CITED listing per material:
  store, price, citation URL, estimate~flag) -> FIRST BATCH (the
  live pre-stage plan embedded: varied products, budget+hours
  costs) -> SELL AND LOG (markets/online; MarketSessionRecord =
  the learning) -> READINESS CHECK (the earned ladder) -> STEP UP
  (commit-hours gate verbatim; bulk-tier math shown). RISKS are
  ROWS (BusinessRiskNote, 8 seeded) attached to the step where
  they bite: caustic lye (safety-critical, mitigation stated),
  alkaline paste burns, hot wax, unsold-stock tuition, price-drift
  on est~ citations, overpromising before measured speed, burnout,
  and NO-FOOD-SAFETY-CLAIM at the stall.
- PARTNERSHIPS as rows (PartnershipAgreement): flows with explicit
  direction, coherence-CHECKED against supplies/demands where
  parties resolve; placeholder partners honestly UNRESOLVED ('to
  be found'). Three archetypes seeded proposed: rice-mill husk
  supply deal (the local-byproduct shape — same as fly ash/
  bagasse), hydro<->mold mutual loop (scenario-2 as an agreement),
  printer makers<->assemblers service-maintenance + scaling deal.
  partnership_suggestions mines demands x supplies for missing
  deals (existing pairs excluded, humans agree terms).
  56/56 bizops selftests + sweep green.

## ✅ biz-2 STAGE-0 MODE + READINESS + LEAD-TIME QUOTES — 2026-07-28
Three Dustin refinements landed same-session:
- STAGE-0 = PRE-STAGED SPECULATIVE (work_mode on stages): no
  orders — produce what you can AFFORD with what you HAVE, VARY
  the products, then try to sell. prestage_plan(budget, horizon):
  even exploration split across variants until MarketSessionRecord
  sell-through exists, then winners get more of the next batch
  with a 10% exploration floor for losers; revenue lines say
  loudly they assume everything sells (unsold stock = tuition).
  /api/bizops/prestage/{business}?budgetUsd=.
- PRODUCT READINESS per business: concept -> produced (timed
  ProductionRunRecord) -> market-proven (MADE AND SOLD past the
  threshold, default 1 ADJUSTABLE via BusinessProfile
  .readiness_sold_threshold) -> advance-orderable (+ measured
  rates). Escalation EARNED by rows, never declared.
  /api/bizops/readiness/{business}.
- LEAD-TIME QUOTES gated on readiness: ProductionRunRecord rows =
  'the proper record of how long it takes'; quote = (backlog hours
  + order hours) / daily hours + cure buffer — 'based on our
  backlog this order will take ~N days'; promise ceiling defaults
  30 days (BusinessProfile.lead_limit_days, adjustable per call);
  beyond it -> honest do-not-accept naming the upgrade levers
  (commit-hours / hire-caster). Backlog estimated from priors is
  FLAGGED in the quote. /api/bizops/quote/{business}?variant=&
  quantity=&leadLimitDays=. 41/41 bizops selftests + full sweep.

## ✅ biz-1 BIZOPS MODULE — 2026-07-28 (Dustin's big splice)
NEW feature module modules/bizops (requires supplychain; wave 3;
wired into polari-modules.json/FEATURE_MODULES+REQUIRES/
polariServer/defClassList/seed_pairs/endpoint):
- SETUP FLOW as the AXIOM: every business starts stage-0 — ONE
  person, OFF-TIME hours, selling online + farmer/maker markets,
  buying retail-available. Seeded ladder stage-0..3 (solo-offtime →
  solo-committed → plus-one-hire → capability-shop with self-made
  intermediaries).
- UPGRADE FLOWS as evidence-gated EDGES (never auto): commit-hours,
  hire-caster (hire ON A TASK), adopt-wax-reclaim-loop,
  add-ceramic-firing (the Table 8.8 path as a business step),
  add-waterglass-production — each gate references the planner's
  numbers.
- LOCAL ECONOMY SETUP: 8-milestone track toward the functioning
  local economic baseline (OSEB operational) — status DERIVED from
  live rows (local-available sources, makeable intermediaries,
  mutual loops, business stages, reclaim/crush batches logged);
  progressPct + nextGap. Today: 3/8 done (waterglass+metakaolin
  makeable, mutual loop), nextGap = local wax feedstock (the farm
  turning real).
- ORDER PLANNER (ProductOrder registrar; od-4 sale.order binding =
  the designed Odoo feed): answers Dustin's THREE questions —
  (1) capacity: labor hours from volume-scaled (V^2/3) workflow
  priors vs the stage's weekly hours; infeasible → DEFER
  suggestions that free enough hours; (2) supply: priced
  procurement manifest riding the cascaded stack (honest: NO
  inventory tracking yet); (3) reuse: LADDER SCALING — geometric
  size rungs (2^k L), one mold family per rung, strategy picked
  per rung via the mold comparison, cycles pooled: fixture 270
  orders collapse to <30 molds (>85% mold savings). CAPABILITIES
  GATE THE PLAN: no ceramic strategy without ceramic-firing, wax
  priced at makeup-only with wax-reclaim-loop — upgrades visibly
  change the numbers (selftested both ways). /api/bizops/flows/
  {business} + /economy + /plan/{business}. 23/23 selftests.
- hemp-fiber CITED EXACT $17.09/lb; bagasse ash left uncited ON
  PURPOSE (no US retail channel — sugar-mill local hunt);
  cheapest_blend drops zero-fill optional roles. 55/55 formulas.

## ✅ bio-1 CORN HUSKS + BIO ROUTES — 2026-07-28 (Dustin's ask)
Are husks a sand alternative? NOT drop-in (sand = rigid inert
volume; husks = compressible, water-absorbing, and cellulose
DEGRADES in the alkaline matrix). THREE real routes as data, each
with its refinement chain in the requirement:
- FIBER (toughness, 0-2%): dry -> chop 10-30mm -> alkali-wash+rinse
  -> optional wax/waterglass coat vs matrix alkalinity. New OPTIONAL
  fiber-reinforcement role on geopolymer-mix (min 0 — optimizer
  fills at zero when nothing cited; that needed a cheapest_blend
  fix for optional roles).
- MINERALIZED CHIPS (lightweight PARTIAL sand substitution,
  insulating planter grades): dry -> chop 5-15mm -> WATERGLASS DIP
  (our intermediary — the wood-wool-board trick) -> dry. Nobody
  SELLS these, so buy-everything costing refuses honestly and the
  CASCADE is the only true cost (selftested as the design speaking).
- ASH: the honest comparator — corn/herbaceous ash yield ~5% (vs
  rice hulls 18%, K-rich low-SiO2) => ~487/kg at retail husks;
  rice hulls stay the special case, corn belongs to fiber/chips.
CITED EXACT: Farmers Spice 24 lb case $265 (24.34/kg FOOD-GRADE
tamale channel) — and that price IS the finding: husks are FARM
WASTE, near-free at source; the bio castable variant
(geopolymer-castable-bio-v0: 21% sand + 18% chips + 2% fiber)
costs ~5x the plain castable at retail husks (selftested), which
PROVES the farm-waste channel requirement — the hydroponic-farm
partner loop supplies exactly this. sugarcane-bagasse-ash +
hemp-fiber seeded as uncited candidates (documented pozzolan/
fiber). Coverage engine improved: makeable-but-uncited candidates
now show 'makeable' with their make-cost instead of counting as
research gaps. 55/55 formulas + full sweep. 30 sources / 34
citations / 11 requirements / 12 formulas.

## ✅ mold-1 MOLD STRATEGIES + CRUSH-RECYCLE — 2026-07-28
Dustin's geopolymer-mold questions as data:
- CAN geopolymer mold geopolymer? YES with a MANDATORY release
  agent — fresh paste bonds to cured aluminosilicate (same
  chemistry); oil prior 2.0/kg-uncited or the cited wax coat.
- Ceramic? BOTH directions handled honestly: ceramic molds for
  geopolymer fine; a geopolymer mold can be FIRED INTO a ceramic
  mold (the tech tree's Table 8.8 geopolymer->ceramic conversion =
  the upgrade path, kiln energy excluded-loud); geopolymer molds
  for ceramic SLIP casting REFUSED (needs capillary porosity —
  plaster's job; pressing clay against geopolymer is fine).
- End-of-life: crushed retired molds re-enter NEW geopolymer as
  crushed-geopolymer-aggregate (loopback candidate on the
  aggregate role; credited at displaced sand price).
MoldLifecycleRecord (waxprint, defClassList): mold_material
(wax-printed|geopolymer|ceramic-fired), casts_completed (THE reuse
counter), release_agent, retirement reason, crushed_kg_recovered.
supplychain/mold_analysis: strategy compare at any volume — at 100
casts all three land sub-dollar/cast from the cited stack
(geopolymer mold 1.5kg x 1.11 cascaded = 1.67/mold, ~50-cycle
formwork prior; ceramic ~200-cycle kiln-furniture prior; wax molds
melt back to the pool instead of crushing); volume crossovers
(1000 casts: wax needs 100 molds, ceramic 5); fleet report replaces
priors with measured casts-at-retirement + failure reasons.
/api/supplychain/sourcing/molds/compare?casts=N + /molds/fleet.
14/14 selftests; geopolymer coverage now honestly shows the ONE
loopback gap (crushed aggregate — log crush events to close).

## ✅ wp-r WAX RECLAIM LOOP + src-8 CITATION SWEEP — 2026-07-28
Dustin's melt-off question answered as DATA + tracking:
- WaxReclaimBatch (waxprint module, in defClassList, NO fake seeds):
  THE geopolymer-wax-mold-reuse-cycles tracker — pool_name +
  generation counter, melted/recovered/makeup kg (measured recovery
  ratio derives from these), residue_note, wash_done + wash_ph_result
  (red-cabbage/strip, research-tools tree), melt_point_c_measured
  (drift vs the feedstock window = the printability early-warning),
  printability untested|good|degraded|retired.
- supplychain/reclaim_analysis: steady-state + cycle-curve economics
  over CITED costs — virgin blend resolved cascaded (6.95/kg made),
  citric wash costed (the wash is NOT optional: alkaline geopolymer
  residue SAPONIFIES ester waxes — soy IS a triglyceride), recovery
  0.85 FLAGGED estimate (foundry practice 0.80-0.90) until batch
  rows land, melt/wash energy excluded, generation ceiling honestly
  UNKNOWN (refuses to promise one). RESULT: wax per mold 2.43 ->
  0.40 at steady state (~84% cut; per pot 0.24 -> 0.04).
  /api/supplychain/sourcing/reclaim (+?cycles=N curve) + /reclaim/
  pools. 13/13 selftests.
- src-8 SEVEN MORE CITATIONS: rice-bran-wax $65.99/5lb EXACT (the
  ENTIRE wax feedstock space is now cited — zero gaps), ferric
  chloride $21.95/500mL exact-price/mass-inferred, TEOS $5.80/20mL
  exact small-vial (~310/kg at that scale — why sg-community
  exists), fly-ash + GGBFS ~$17/7lb est via the countertop channel
  (BULK is ~100x cheaper $30-80/MT — local ready-mix/utility hunt
  noted IN the citations), vinegar $3.97/gal exact (5% solution
  caveat), desiccant gel ~$35/10lb est. GEOPOLYMER GAPS CLOSED TOO.
  29 sources / 33 citations. Remaining uncited: waste-glass-fines
  only (+ exact re-cites of est-flagged).

## ⚡⚡ AUTONOMOUS SESSION 2 — 2026-07-28 (Dustin away; delegated)
Everything below done autonomously on Dustin's 'keep going at will':
- SCENARIO PRICES REPINNED from citations (the drift suggestion,
  deliberately executed on delegation): soy 4.81 exact, drymix 4.85
  est — honest margin 235.8/2cycles (was 456 invented). LIVE re-run.
- SCENARIO 2 'hydroponic-wax-farm-v1' LIVE end-to-end: the sourcing
  mutual loop transactional (ONE partner = biomass customer AND pot
  supplier; farm bought 4 pots, sold 60kg biomass; margin +24 THIN
  by design — transfer-price discovery = scenario 3);
  hydroponic-wax-source-farm BusinessModel created.
- ScoreTerm 'material-cost-per-kg' REGISTERED in scoring seeds
  (materials-economics, USD/kg, is_positive False); full scoring
  sweep green.
- od-6 CORE: pol odoo backup-cron install|remove|status (03:17
  nightly, keep 14; CAUGHT LIVE: set -e kills the crontab subshell
  on empty grep -> empty crontab installed silently — || true) +
  pol odoo restore-drill <sim|ops> (latest receipt -> throwaway db,
  base-table count vs dump CREATE TABLEs — views made it off-by-one
  — + row-EXACT res_users/ir_model vs COPY stanzas) — DRILLED PASS
  on sim (236 tables) AND ops (205). econ-core got its own
  raw-docker nightly cron + proven 3.3MB manual dump (receipts in
  ~/polari-odoo-runtime/backups/). MOVE_SUBJECTS += odoo,
  odoo-postgres (25/25).
- od-7 FRONTEND: /business/odoo (angular dev-od-7-business-ui) —
  see the od-7 plan section. ng build green, NO browser pass.
STILL NOT PUSHED anywhere (Dustin's manual step). Local pair down
(volumes kept); econ-core pair RUNNING (its cron now takes nightly
receipts).

## ✅ src-7 CITATION SWEEP + NEW INTERMEDIARIES — 2026-07-28
Seven citations closed flagged gaps (ferrous sulfate est, SLS EXACT
15.84/lb, rice hulls est, EPK kaolin 21.50/50lb, stearic 40.19/5lb,
candelilla est, soda ash est — cited for the FUSED waterglass route
but NOT wired into the digestion recipe: different process, needs a
melt furnace). RIPPLES (the system did its job): metakaolin now
MAKEABLE (calcine kaolin 0.86 yield → 1.10/kg vs 2.04-2.91 bought)
→ geopolymer cascade = 1.11/kg, ~77% under the GPI kit with BOTH
waterglass and metakaolin self-made; RHA makeable (burn hulls,
7.35/kg — temperature win not price win, said so); ferrite coprecip
UN-REFUSED at 20.11/kg and BUYING (9.70) honestly wins ~2x; wax
optimizer switched hardener to stearic → 6.95/kg, ~68.5% under
MachinableWax; CNT dispersions gained the optional cited SLS role.
49/49 + full sweep green. REMAINING uncited: rice-bran-wax, TEOS,
acetic-vinegar, waste-glass-fines, ferric-chloride, fly-ash, slag,
silica-gel-desiccant, exact SWCNT grade, MachinableWax exact,
+ exact re-cites for the est-flagged seven.

## ✅ src-6 SOL-GEL + FERRITE + CNT COST LAYERS — 2026-07-28
yield_fraction landed on ProductFormula (output-basis costing —
sol-gel drying loses mass; refuses outside (0,1]). SOL-GEL:
silica-xerogel via waterglass+citric (cited est 5.73/kg)+water,
yield 0.16 → 35.79/kg bought-waterglass vs 10.67/kg SELF-MADE —
first two-level cascade proven (xerogel <- waterglass <- sand/
NaOH/tap). FERRITE: magnetite pigment CITED EXACT 9.70/kg
(Walmart $21.99/5lb); coprecipitation recipe seeded but refuses to
cost until iron salts cited (ferrous-sulfate garden channel /
ferric-chloride etchant channel = the hunts) — catalog shows the
refusal as the research ask. CNT: making-from-scratch = EXPLICIT
far-off assumption (polari-cnt-lab potential, no powder formula on
purpose; techtree CNT-builder models structure not production);
grades cited: MWCNT 375/kg vs SWCNT 500/g low-end electronic
(orders of magnitude ON RECORD), dispersion market 185/kg mid;
2wt% MWCNT dispersion from BOUGHT powder = 7.50/kg (~96% under
market; sonication excluded; surfactant gap noted). 49/49 formula
+ 23/23 sourcing (rank-1 check generalized: two polari labs now)
+ all suites green. NEXT hunts: ferrous sulfate, SDS surfactant,
RHA, exact SWCNT grade quote.

## ✅ src-5 WATERGLASS = MAKEABLE INTERMEDIARY — 2026-07-28
Dustin: waterglass is critical in multiple processes and is an
INTERMEDIARY — account for local production via different routes.
Built: sodium-silicate-solution ProductInputRequirement (silica-
source 24-32% {sand CITED, rice-husk-ash*, waste-glass-fines*},
alkali 12-18% {NaOH}, water 52-62% {tap-water CITED — published 2026
utility tariff $11.63/1000gal = 0.0031/kg; municipal-water-utility
source is the clean rank-4 local-closed example}) + recipe
waterglass-hydrothermal-v0 (28/15/57) = 1.54/kg vs 8.85 purchased
(-83%, digestion energy EXCLUDED loudly; RHA route = the sol-gel
sg-community low-temp path once cited). NEW CASCADED COSTING in
formula_analysis: make_cost (seeded recipes only), effective_unit_
price (min buy/make, recursive + cycle-guard), cascaded_cost
(breakdown tags via made/cited; madeIntermediates carry the energy
caveat); product_cost_comparison surfaces formula-with-made-
intermediates rows; /api/supplychain/sourcing/cascaded-cost/{name}.
CHAIN RESULT: geopolymer castable 2.65 → 1.48/kg with self-made
waterglass → ~69% cheaper than the GPI kit. Tech tree: sol-gel node
description names the production-routes seam (first-class
waterglass-production node = deliberate follow-up; data_deps
resolve against DigitizedDataset so they were the wrong hook).
40/40 formulas + 61/61 techtree + all suites green.

## ✅ src-4b METAKAOLIN EXACT-CITED — Dustin's screenshots 2026-07-28
Clay Art Center bot-blocks automated fetch; Dustin captured the real
prices by phone: metakaolin $5/1lb weigh-out, $66.00/50lb bag EXACT,
volume tiers to $46.20/bag at 40+ bags. Cited as TWO citations: the
single bag (2.91/kg exact) and the 40-bag tier with amount=2000lb so
the pack size SHOWS the commitment the price demands (2.04/kg).
Geopolymer numbers moved: v0 = 2.65/kg, optimized = 1.85/kg vs GPI
kit 4.85/kg → making beats buying ~45-62%. Pattern for the future:
when a site blocks fetch, a user screenshot IS a valid citation
(note says so + who captured it). 31/31 green.

## ✅ src-4 GEOPOLYMER MAKE-VS-BUY — 2026-07-28 (Dustin's spec)
Same pattern as the wax: geopolymer-mix (DIY-local castable) gets
its full feedstock space + real dated citations vs buying the GPI
kit. Roles: precursor 30-50% {metakaolin CITED 2.81/kg est,
fly-ash-class-f*, ggbfs-slag*}, silicate-activator 10-22%
{waterglass $46/gal EXACT Sheffield, mass-inferred 8.85/kg
as-solution}, alkali 1-6% {NaOH 9.64/kg exact — CAUSTIC/PPE caveat},
aggregate 30-55% {play sand 0.33/kg exact Home Depot}. (* = uncited
gap; industrial byproducts, often cheap-to-free locally.) v0
40/16/3/41 = 2.96/kg; optimizer 34/10/1/55 = 2.11/kg. Substitute =
geopolymer-kit (GPI) 4.85/kg, caveats cut BOTH ways (closed formula,
heavy shipping — but hydroxide-free = friendlier than DIY NaOH).
VERDICT: MAKING BEATS BUYING ~39-56% — the reverse of the wax
economics (where bulk pellets beat blending). /compare/
geopolymer-mix serves the table. 31/31 formula selftests. v2:
dry-basis silicate cost, mix water, cure validation; hunt local
fly-ash/slag citations.

## ✅ src-3 SUBSTITUTE BENCHMARK — MachinableWax 2026-07-28
The current commercial alternative for 3D-printing wax, accounted
honestly: SupplySourceProfile machinable-wax-com (commercial,
NON-eco — paraffin+polyethylene plastics blend, fume emission when
overheated, ventilation required); ProductInputRequirement gained
substitutes_json (WHOLE-product substitutes with caveats-as-data,
distinct from role candidates); citation ~$10/lb flagged is_estimate
(store TLS-unreachable at observation — forum-referenced figure,
re-cite when reachable) → 22.05 USD/kg. product_cost_comparison
(/api/supplychain/sourcing/compare/{item}): formulas vs optimizer vs
substitutes sorted cheapest-first WITH caveats attached + verdict —
our optimized natural blend 7.79/kg beats machinable wax by ~64.6%
(v0 10.78/kg beats it by ~51%). So: natural blending loses to bulk
commercial soy pellets (6.0/kg) as raw input but CRUSHES the
dedicated commercial print-wax substitute — the business case for
blending in-house is real TODAY vs MachinableWax, and gets better
with bulk/farm sourcing. 24/24 formula selftests.

## ✅ src-2 FORMULA LAYER — BUILT + TESTED 2026-07-28 (Dustin's spec)
Products map to their FULL feedstock space: ProductInputRequirement
(roles with fraction ranges + ALL candidate item_refs per role —
uncited candidates surface as researchGaps, never silently omitted;
natural-print-wax-blend seeded: base-wax 60-85% {soy, rice-bran*,
candelilla*}, toughener 10-30% {beeswax}, hardener 5-15% {carnauba,
stearic*, candelilla*}; * = uncited gap). ProductFormula = concrete
blend rows. formula_analysis: formula_cost validates (fraction sum,
role ranges, candidate legality, uncited components REFUSE with a
citation suggestion) then costs from citations with per-component
source/citation/date breakdown AND emits the material-cost-per-kg
SCORING TERM block (is_positive=False, evidence=citations) so
simulation results can score affordability directly; cheapest_blend
= greedy min-cost feasible fractions as a SUGGESTION demanding
print-validation. REAL numbers: v0 (70 soy/20 beeswax/10 carnauba)
= 10.78 USD/kg; optimizer 85/10/5 = 7.79 USD/kg (-28%) — and both
sit ABOVE the 6.0/kg commercial-pellet price scenario v1 pins,
which is the honest economics finding retail-sourced blending has
to beat (bulk pricing / farm-grown source = the path). API
/api/supplychain/sourcing/requirements/{item}|formulas|formula-cost/
{name}?sources=cheapest|preferred|cheapest-blend/{item}. 18/18
selftests + all suites green. Follow-up: seed the matching
ScoreTerm row in the scoring module (kept out of this pass to avoid
destabilizing its count-asserting suites).

## ✅ src-1 SOURCING LAYER — BUILT + TESTED 2026-07-28 (Dustin's spec)
Costs become CITED DATA (supplychain module): SupplySourceProfile
(overlap-capable booleans open/commercial/local/polari/eco — a
source CAN be several at once; availability available|potential;
demands_json = the customer side, so mutual supply loops are one
row: the hydroponics farm supplies wax-source-biomass AND wants
geopolymer-self-watering-pot + geopolymer-pot-shelf), PriceCitation
(price + amount/unit + observed_at datetime + citation_url +
is_estimate — ranges/'from' prices are FLAGGED, never silently
exact), SourcePreferencePolicy (the definable ladder, seeded to
Dustin's order: polari-open-local(1) > polari-open(2) >
open-non-polari-IF-eco(3) > local-closed(4) > commercial(5);
first-match-wins predicates over the flags — edit rules, not code).
REAL web-researched citations 2026-07-28: GPI GeoCement kits
$34.95(10lb)-$110(50lb) (range->size mapping flagged estimate),
Aztec LP402 soy $109/50lb exact, bulkbeeswax floor $8.99/lb
(flagged), carnauba 5lb $78.36 (aroma-depot) vs $92.99 (oilscenter).
Analysis (sourcing_analysis): normalization to USD/kg (dimension
mixing refused), price_compare with spread + PREFERENCE PREMIUM,
preferred_source (better-ranked potential sources fire develop-
suggestions, never auto-picks), scenario_price_drift — found the
real thing immediately: scenario v1 pins drymix 1.8/kg vs GPI cited
4.85/kg = +169% drift, surfaced as a deliberate-edit suggestion.
API /api/supplychain/sourcing/sources|prices/{item}|preferred/
{item}|scenario-drift. 23/23 selftests; all prior suites green;
scenario products now carry item_ref links into the citation
vocabulary. NEXT: repin scenario prices from citations (Dustin's
call — the suggestion is on record), scenario 2 (farm), natural-
print-wax-blend recipe costing from the 3 wax citations.

## ✅ od-5 BUSINESS SIMULATIONS — BUILT + END-TO-END VERIFIED 2026-07-28
THE PAYOFF: the economy tree got its first NUMBERS. Dustin's scoping
("businesses that do whatever they can with the tools they have"):
scenario v1 = wax-print molds + geopolymer goods micro-business with
TWO explicit assumptions in assumptions_json (feedstock from a
purely commercial supplier — the local hydroponic wax-source farm is
scenario 2; a working wax 3D printer exists; labor/energy/
amortization excluded from v1 economics). BusinessScenarioDefinition
= scenarios as DATA (seed spec: 3 partners, 4 products, 2 BOMs —
mold=0.35kg pellets, pot=2kg drymix+0.1 mold amortized; driver: 2
cycles of buy->receive->make->sell->deliver; outcome spec names the
business model). odoo_scenario_engine: plan-first step list; the
SIM-ONLY guard refuses ops configs before anything; create/archive
return exact pol-CLI commands (DB ops are host ops — never
pretended); seed idempotent by x_polari_ref; run drives Odoo's REAL
mrp/purchase/sale logic; harvest reads origin='polari:<scenario>'
docs only -> BusinessOutcome + BusinessModelDefinition (honestly not
self_sustaining). CLI: scenario-init/scenario-drop (odoo_scn_* prefix
guard; final pg_dump receipt before EVERY drop). API: /api/odoo/
scenarios + /api/odoo/scenario/{plan|create|seed|run|harvest|archive}.
ACCEPTANCE: real throwaway DB, 10 driver steps green (4 POs, 6 molds
+ 40 pots manufactured state=done, 2 SOs delivered), metrics revenue
720 / materials 264 / margin 456, outcome 'succeeded'; TWICE from
fresh DBs -> identical metrics; ops untouched proven at DATA level
(md5-of-dump is INVALID — pg_dump 16 embeds a random \restrict token
per dump). 20/20 scenario selftests + all prior suites green.
LESSON: Odoo 18 MOs park 'to_close' unless component moves are
picked before button_mark_done — engine sets them + verifies
state==done, refusing otherwise. NEXT: od-6 ops guardrails (backup
cron, restore drill, movers) or scenario 2 (hydroponic farm grows
the wax source — vertical integration), od-7 frontend surface.

## ✅ od-4 BINDINGS + SYNC — BUILT + VERIFIED 2026-07-28 (same branches)
OdooModelBinding (bindings are DATA: odoo_model<->polari_class +
field_map_json + direction + instance_ref; a binding can never widen
an instance's permissions) + OdooSyncReceipt (every run receipted).
odoo_sync.pull: provenance odoo:<inst>:<model>:<id>@<write_date>,
row name '<prefix>-<odoo_id>' idempotent, same-prov skip / older-prov
update / FOREIGN-prov conflict-report-never-touch; class resolution
via objectTypingDict.getCreateMethod() (CRUDE path) so a gated-off
class refuses naming POLARI_MODULES. odoo_sync.push: x_polari_ref
ensured on demand (ir.model.fields create = itself a guarded write),
found->write absent->create, explicit row_names required, confirm
string forwarded into the client guards. API: /api/odoo/bindings|
pull|push|receipts. Seeds: partners->SupplyNode, product.template<->
WaxFeedstockDefinition (both), mrp.bom->SupplyChainDefinition
(refuses until mrp installed). TESTS: 26/26 selftest_odoo_sync vs the
shared stub_odoo.py (stub starts WITHOUT x_polari_ref — ensure path
exercised for real); 27/27 od-3 suite still green. REAL acceptance
on the local pair: pulled hand-seeded products with exact provenance,
pushed a Polari row into odoo_sim (custom field created live,
round-trip verified, re-push updated not duplicated), ops write
refused AT THE GUARD (knob named) while ops reads flowed. Local
odoo_sim now has the 'product' app + test rows (verification
artifacts). NEXT: od-5 BusinessScenarioDefinition + wax-print
micro-business scenario (installs product/mrp/sale in scenario DBs).

## ⚡ ODOO LIVE ON ECON-CORE — 2026-07-28 (its mandated home)
Shipped WITHOUT pushing repos (Dustin: ssh route OK): images
docker-save|ssh-load'd, minimal runtime dir ~/polari-odoo-runtime on
econ-core (compose file + pol-odoo{,-postgres} configs + .generated
env copied; .generated/odoo-ports.yml override publishes 8069/8072/
5432 on the LAN until the proxy runs there) — run with
`docker compose -p polari-suite ...` so containers/volumes are named
EXACTLY as a future real checkout expects (polari-suite_odoo-db-data
adopts seamlessly). Both DBs created (base only, no product app yet),
admin passwords set + shown once in-session. Login:
http://192.168.0.66:8069/web/login?db=odoo_sim . SSO not configured
there (needs pol-keycloak reachable). The local pol-core pair still
exists (volumes kept) as the dev/verification copy.

## ✅ od-3 ODOOCONNECT MODULE — BUILT + VERIFIED 2026-07-27 (same branches)
Framework module modules/odooconnect/ (waxsupply anatomy):
OdooInstanceConfig treeObject (mode sim|ops, base_url + url_env
override, auth_password_env = env-var NAME never a secret,
push_enabled default False, read_only), stdlib JSON-RPC odoo_client
(OdooHandle bound to ONE row — sim/ops can never blur in a handle;
{ok:False, refusal, suggestion} everywhere; NO write retries;
READ_SAFE_METHODS allowlist so unknown methods are guarded), duck-
typed odoo_analysis, /api/odoo/status + /configs (OdooConnectAPI,
gated by _feature_available), seeds odoo-sim (push free) + odoo-ops
(read_only, push_enabled=False, typed phrase 'PUSH TO OPERATIONS
odoo-ops' required per write). Wired: polari-modules.json wave 2,
FEATURE_MODULES, polariServer guarded import + defClassList +
seed_pairs + endpoint block. TESTS: 27/27 selftest_odoo against an
in-process stub JSON-RPC server (auth, paging, refusal shapes, all
guard permutations, handle separation, status over fake manager) +
module suites green (registry 10/10, lazy-imports 15/15, lazy-boot
34, deps 13/14 = pre-existing xr miss). REAL round-trip verified
against the od-1 pair (18.0-20260723, uid 2, live partners).
Env knobs: ODOO_SIM_URL/ODOO_OPS_URL, ODOO_SIM_RPC_PASSWORD/
ODOO_OPS_RPC_PASSWORD (backend-side). Deviation: provider_registry
/capability probing skipped (odoo has none) — /api/odoo/status is
the probe surface. NEXT: od-4 OdooModelBinding + pull/push sync.

## ✅ od-2 SSO — BUILT + VERIFIED 2026-07-27 (same branches)
OCA auth_oidc 18.0.1.1.0.2 wheel PINNED into pol-odoo/Dockerfile;
`pol odoo sso-setup` (polari-cli scripts/lib/odoo-sso.sh) is the
idempotent, never-hand-clicked flow: admin-API-inside-pol-keycloak
ensures confidential client 'odoo' in realm Polari (redirect
https://odoo.<domain>/auth_oauth/signin — auth_oidc reuses the
auth_oauth route), then installs auth_oidc + upserts the
auth.oauth.provider row in EVERY odoo_% DB (flow id_token_code;
secret flows KC->odoo DB, never a file). Endpoint split = the PRF
pattern: browser auth/logout public https://auth.<domain>, token/
jwks/userinfo in-network http://pol-keycloak:8080. VERIFIED live
(pol-mariadb+pol-keycloak brought up from the existing volume, then
downed): client created+updated idempotently, both login pages
render 'Log in with Polari SSO' with a correct code-flow link.
GOTCHA fixed en route: docker exec needs -i for bash -s stdin
scripts. Honest gaps: browser round-trip + gm-4 KC-move-mid-session
check wait for pol-proxy serving odoo.<domain> (prf-proxy owns :443
on pol-core); KC-role->Odoo-group mapping MANUAL v1 (init-db admin
password = break-glass local login). Topology: odoo->pol-keycloak
keycloak-client-secrets connection seeded (16 connections, 52/52).
NEXT: od-3 odooconnect module (stdlib JSON-RPC, OdooInstanceConfig/
OdooModelBinding rows, stub-server selftests, /api/odoo/status).

## ✅ od-1 SERVICE BRING-UP — BUILT + VERIFIED 2026-07-27
Branches `dev-od-1-odoo-bringup` (suite + polari-cli + framework),
NOT pushed. `pol odoo up|down|build|status|logs|init-db <sim|ops>|
backup <sim|ops>|urls` works end-to-end: pair healthy in ~30s on the
staging tier, odoo_sim + odoo_ops created (admin password printed
ONCE at init-db), login forms serve, db-manager RPCs refuse
(list_db=False), pg_dump receipts (3.3M) in .generated/backups/.
Key shapes: images PINNED (odoo:18.0-20260723 / postgres:16.14, own
Dockerfile dirs pol-odoo/ + pol-odoo-postgres/); compose profile
'odoo' in ALL tiers so plain suite up NEVER starts the pair; proxy
odoo.<domain> routes are VARIABLE proxy_pass + resolver (a static
upstream would stop nginx booting while the profile is down),
/websocket -> :8072, friendly 503 JSON when down; ONE shared DB
secret in pol-odoo-postgres/odoo-postgres.env + pol-odoo/odoo.env
(setup-polari-security.sh 3b, knob POLARI_ODOO_DB_PASS, skip-if-
exists — drift rescue documented in pol-odoo/README.md); topology
seeds gained odoo + odoo-postgres instances on econ-core + 3 typed
connections (erp-api-seam key added), machine seed 'lightweight'
RENAMED to econ-core, topology_render.py got the odoo shape (52/52
+ 25 + 45/45 + 19/19 topology selftests green); registry entries +
suite trio re-rendered byte-parity OK; pol proxy render/check/
promote green (pol-proxy wasn't running — prf-proxy owns :443 on
pol-core — so browser-through-proxy verification waits for a suite
deploy; nginx -t validated the config). Verification pair was
brought up on pol-core then downed; volumes odoo-db-data/
odoo-filestore kept. NEXT: run `pol odoo up` on econ-core once code
syncs there (repos unpushed), then od-2 SSO (KC client + auth_oidc
addon in pol-odoo/Dockerfile), od-3 odooconnect module.

---

# ⚡⚡⚡⚡⚡⚡ CONSOLIDATED ON dev — 2026-07-27 (Dustin's call)

**ALL WORK IS NOW ON THE BASE `dev` BRANCHES** in all five repos
(framework fa475f3, angular 744d925, cli 88497c3, rf-node 34be606,
suite 2e55cb5) — pure fast-forwards (every feature branch was an
ancestor; nothing left behind, verified with --no-merged). Submodule
pointers coherent. Feature branches remain as historical markers.
NOT pushed — repos are PUBLIC; pushing stays Dustin's manual step.
Selftest sweep re-run green from the dev checkouts; live swarm
stack verified unaffected (same content).

---

# ⚡⚡⚡⚡⚡ GM-1 GRACEFUL ENGINE MOVES — 2026-07-27 (NEWEST)

**✅ gm-1 + gm-2-lite BUILT + ACCEPTANCE PASSED same day** (Dustin:
"the capability to move engines dynamically... ensure it can meet the
same criteria" as mlb — explicit trigger, topology-frontend tie-in,
tracked, prior-knowledge timing). Plan: GRACEFUL_MOBILITY_PLAN.md
(gm-1 automated; gm-2 landed as the moves-as-data slice; quiesce +
gm-3..5 stateful movers remain). Branches: framework
`dev-gm-1-engine-moves` (off dev-mlb-lazy-boot, a861f05), polari-cli
`dev-gm-1-graceful-allocate` (off dev, f5a7110), angular
`dev-gm-moves-ui` (off dev-mlb-frontend, 3dac0a3). NOT pushed.

- `pol allocate <instance> <machine> --graceful` = the gm-1 blue-
  green: image check/ship (save|ssh load, sized receipt) -> label
  check -> `docker service update --update-order start-first` +
  constraint swap (routing mesh keeps :9500 answering) ->
  /capability readiness gate -> probe-cache invalidation (NEW POST
  /api/topology/providers/reprobe; cache was 30s-TTL-only) ->
  verify. Needs POLARI_CORE_URL on swarm (be_call's docker-exec
  fallback expects the compose container name).
- MOVES AS DATA: MoveOperation rows (topology/move_operations.py) —
  planned step list shown BEFORE running, per-step receipts +
  server-measured durations, EXPECTED step durations = median of
  prior verified moves (failed moves never teach; no history = {}).
  API /api/topology/move-operations (+/step, /finish) + STOMP
  /topic/MoveOperation. plan_move's engine hand-back now suggests
  the --graceful command first.
- ✅ ACCEPTANCE (the plan's exact criterion): isle-core ->
  lightweight -> isle-core, 55 polls @1s against /capability, ZERO
  failures. Both moves 'verified' (7.6s / 10.2s total); move #2 ran
  with expected durations from move #1. Engines image now ALSO on
  lightweight (kept). Topology row for 'engines' updated + renders
  parity-OK (this also fixed the stale machine_name row).
- FRONTEND: "Graceful moves" panel atop /topology — step tables with
  receipts, measured vs expected durations, 3s poll while running.
  ng build green; frontend rolled; NO browser pass yet.
- Selftests: topology.selftest_move_operations 15 + topology 52/52 +
  lazy-imports 15/15.
## ⚡ SAME DAY 2nd pass: gm-2 QUIESCE + gm-5 SQLITE INSTANCE MOVE
("just keep moving" — framework d312d8f, cli 01d4d6e)
- gm-2 FULL: POST /api/quiesce (gate FIRST, persistTree flush, then
  the receipt — nothing mutates after it returns) + /status +
  /release; QuiesceMiddleware 423s mutations, reads + receipts flow;
  failed flush keeps the gate UP. In-process state ON PURPOSE
  (relocated instances boot unquiesced). selftest_quiesce 16.
- gm-5: `pol swarm relocate <machine>` moves the BACKEND (owned
  sqlite): sync-image (image-ID compare — same tag != same code
  across swarm nodes, learned the hard way) -> short-poll quiesce ->
  snapshot -> double-pass tar copy + PRE-BOOT file verify ->
  stop-first constraint swap -> placement-gated boot-ready with
  measured downtime -> dedup-aware verify (tables + stable tables +
  the marker MoveOperation row that travels INSIDE the copied DB) ->
  retire (old volume = rollback).
- ✅ LIVE: backend moved staging-a -> isle-core -> staging-a. Marker
  proof worked BOTH ways; return downtime ~71s (lazy boot!); final
  state: backend home on staging-a, engines on isle-core, rollback
  volumes on both boxes. Move rows: backend@1785164149 (forward,
  marked failed — verify raced, fixes applied) + backend@1785165052
  (return, VERIFIED with full receipts).
- ⚠ TWO MEASURED FINDINGS (the real gm-5 lessons):
  1. persistTree flush took 2758s on isle-core (row-by-row REPLACE +
     sqlite lock contention vs concurrent readers; OOPS handler
     recovered 4 lock failures). mlb-5b BATCHED FLUSH is now the
     gating item for gm-5 GA — the mover works, the flush is the
     bottleneck.
  2. Post-boot row totals SHRINK legitimately (restore dedupes
     historical duplicate rows then persistTree rewrites clean) —
     raw-total is the WRONG invariant; the mover now checks the
     copied FILE pre-boot + stable tables + marker post-boot.
## ⚡ SAME DAY 3rd pass: mlb-5b BATCHED FLUSH (fw 4540f6d, cli c0d960c)
Dustin: "sensible batches, module by module, per object type."
- managedDB.saveClassBatch = ONE transaction per object type (scoped
  DELETE + executemany REPLACE, uniform full-column rows — REPLACE
  NULLs unnamed columns either way so byte-equivalent to per-row);
  ok=False -> row-by-row OOPS fallback, never silent loss.
- persistTree = MODULE-ORDERED (core first, then dependency order),
  one batch per class, per-class progress callback, per-class
  fallback. Quiesce engage now ASYNC (gate up instantly, flush in a
  thread, /api/quiesce/status streams currentModule/currentClass/
  classesDone/rowsDone; wait=true = inline for tests).
- ✅ A/B ON THE LIVE RELOCATION (same data/boxes): flush 2758.5s ->
  53.2s (staging-a) / 104.4s (isle-core slow disk) — 26-52x. BOTH
  relocation directions ran FULLY AUTOMATED + verified,
  backend@1785179128 + backend@1785179320, downtime ~69-71s,
  expected-vs-actual populated from history. Final state: backend
  home on staging-a, engines isle-core, rollback volumes both boxes.
- selftest_batched_persist 17 (+PYTHONPATH=modules) +
  selftest_quiesce 20; full regression sweep green.
## ⚡ SAME DAY 4th pass: gm-SAFETY (fw fa3b07a, cli 24534f4)
Dustin's invariants: no failure point may lose data; delete only
after confirmation; be able to finish or reverse (target full /
connection drop); interrupted transfers discoverable after a crash.
- Mover: PREFLIGHT (target reachable + >=3x free space, fail early)
  -> STAGED copy into .incoming-<move>/ (live target data untouched
  by mid-copy failure; re-run resumes — quiesce engage is now
  idempotent per moveName) -> staged file verified row-for-row
  BEFORE the swap -> displaced generation kept in .previous-<move>/
  -> retire deletes ONLY target .previous + journal, after verify.
  The SOURCE volume is never deleted; its journal is rewritten
  'retired-moved-to-<target>' so any later boot of it declares
  where the live data went.
- .move-journal.json in BOTH volumes (phase copying->swapped) =
  crash-durable transfer record; /api/health surfaces
  staleMoveArtifacts (journal/.incoming/.previous) with meaning +
  action. selftest_quiesce -> 27.
- ✅ LIVE: staging-a -> isle-core -> staging-a fully automated +
  verified (downtime ~71s/~82s; flush 28.9s); planted-journal test
  surfaced + cleared on /api/health.
- ⚠ OPERATIONAL LESSON (recorded the hard way): never start a move
  while a service update is converging — a raced attempt
  (backend@1785180981, marked failed honestly) had its in-process
  gate wiped by the restart; no data touched (copy hadn't started).
  A pre-move 'no update in progress' check is a cheap future guard.
## ⚡ SAME DAY 5th pass: GUARD + gm-3 MinIO MOVER (fw a847479, cli ceac47c)
- GUARD (the raced-deploy lesson, enforced): relocate AND graceful
  allocate refuse to start while the moved service (or the backend
  carrying receipts) has a swarm update converging.
- `pol swarm relocate [backend|file-store|keydb] <machine>` — the
  staged-copy mover parameterized per service. MinIO (gm-3): verify
  = user-object count (.minio.sys volatile + move journal excluded);
  all data ops volume-level via alpine (MinIO image lacks tar/find);
  sidecar moves RELEASE the quiesce gate at retire (backend did not
  move). keydb-move shares the plan, refuses honestly until a stack
  deploys KeyDB (replica-promote zero-cold-cache = refinement).
- ✅ LIVE: prf-file-store staging-a -> isle-core -> staging-a,
  downtime ~12s/~11s, seeded 76KB object md5-intact after the round
  trip (read cross-node mid-flight), receipts complete
  (prf-file-store@1785184034 + @1785184115 verified). Bonus proof:
  the FIRST attempt refused at staged-verify (journal counted) with
  live data untouched and clean resume — the safety design working.
## ⚡ SAME DAY 6th pass: gm-4 KEYCLOAK MOVER (fw 05e2152, cli b142753,
## rf-node f94611f) + AUTH OUTAGE FOUND & FIXED
- ⚠ FOUND LIVE (pre-move probe): Keycloak had been CRASH-LOOPING
  since the mlb-0 stack redeploy — generated DB credentials DRIFT:
  stack re-renders inline CURRENT env files, but the MariaDB volume
  keeps the passwords it was INITIALIZED with (kc + root both
  mismatched). FIXED via rescue container (--skip-grant-tables on
  the volume, ALTER USER to the current rendered values — password
  reset only, zero data touched; 2 realms intact). JWKS 200 again.
  SYSTEMIC NOTE: any credential regeneration between deploys will
  re-break DB-backed services — the render/secrets pipeline needs a
  stable-credentials story (docker secrets refinement).
- gm-4 `pol swarm relocate keycloak <machine>`: SERVER-ONLY move
  (realms/keys live in MariaDB which does NOT move; keycloak+DB in
  one step refused via db-check). Blue-green start-first with a
  SELF-HEALING readiness healthcheck (first attempt measured the
  outage: an ungated JVM container is "running" in seconds, serves
  minutes later — the mover now applies a /dev/tcp realm healthcheck
  if absent; compose source carries it for future renders). Verify =
  SIGNING-KEY (kid) identity — access tokens expire in ~60s, shorter
  than any move, so kid comparison is the honest continuity check.
- ✅ ACCEPTANCE: isle-core -> staging-a, 223 JWKS polls @1s, ZERO
  failures (both servers visibly overlapped mid-swap), kids
  unchanged, receipts complete (prf-keycloak@1785187634 verified).
  KC image now also on isle-core (kept). Forward attempt receipts
  honestly record the two design lessons (token-lifetime verify +
  missing healthcheck outage).
## ⚡ SAME DAY 7th pass: gm-5 MARIADB MOVER (fw 18de28c, cli 88497c3)
## — EVERY gm MOVER (gm-1..5) IS NOW AUTOMATED
- `pol swarm relocate mariadb <machine>` — v1 correct-before-clever:
  writers-drain (Keycloak scaled 0, auth window MEASURED) ->
  mariadb-dump --single-transaction to .generated/backups/ (backup
  AND semantic baseline) -> quiesce-db (scale 0, volume still) ->
  staged volume copy verified pre-swap -> constraint swap + health-
  gated scale-up -> verify counts vs receipt + KC recovery + JWKS ->
  retire keeps source volume AND dump. mv_fail re-issues scale-1 on
  DB + writers — a failed DB move never strands auth down. v2
  replica-promote = documented refinement.
- ✅ ACCEPTANCE both directions: DB window ~62s/57s, auth window
  ~145s/141s, counts 2 realms/16 clients/3 users/88 tables identical
  both ways (prf-mariadb@1785189969 + @1785190199 verified); auth ran
  CROSS-MACHINE mid-flight (KC staging-a, DB isle-core, JWKS 200).
  All images (backend/engines/keycloak/mariadb/file-store) now on
  BOTH staging-a and isle-core — any split is a constraint swap away.
- THE MOVER SET IS COMPLETE: engines (blue-green), backend (sqlite
  staged), MinIO (staged), Keycloak (server-only blue-green), MariaDB
  (drain+dump+staged). All share: MoveOperation receipts + expected
  durations, staged-copy/no-deletion-before-confirmation, dual-volume
  journals + /api/health stale-artifact surfacing, update-in-progress
  guard, resumable quiesce.
## ⚡ SAME DAY 8th pass: gm-6 KIND-AWARE MOVE FLOWS — GM SEGMENT
## COMPLETE (gm-1..6 all built; fw fa475f3, ng 744d925, rf 34be606)
- Backend: MOVE_SUBJECTS catalog + move_plan() preview + GET
  /api/topology/move-operations/plan (?subject=&machine=) — planned
  steps, expected durations from history (LIVE: predicts 184s for a
  mariadb move from today's real receipts), statefulness, exact
  command. selftest_move_operations 25.
- Frontend /topology "Plan a graceful move…": subject+machine ->
  step plan + per-step ETAs (no history = 'no ETA, never a guess')
  -> STATEFUL subjects demand typing the subject name -> copy-ready
  command. Running moves PULSE; when a watched move verifies, the
  graph repaints AND the foundational ping pass auto-runs + paints.
  Execution stays the human-run command (knobs-and-suggestions).
  Deployed; NO browser pass yet (planner + pulse + verify strip).
- gm REFINEMENTS (all named, none built): UI-triggered execution
  (needs a host-side executor agent), KeyDB replica-promote, MariaDB
  binlog v2, docker-secrets (kills the credential-drift class),
  local registry (replaces save|ssh-load).

---

# ⚡⚡⚡⚡ MLB LAZY BOOT — 2026-07-27 (read with the section below)

**✅ mlb-0..5a BUILT + DEPLOYED + CROSS-DEVICE VERIFIED same day**
(Dustin: "start on mlb and keep going autonomously"; asks folded in:
multi-device splits over SSH, dynamic module moves, topology tie-in,
enabled/disabled tracking, and time-to-online-after-deps history).
Plan + wiring survey: MODULE_LAZY_BOOT_PLAN.md (PREP section has the
file:line map). Branches: framework `dev-mlb-lazy-boot` (off
dev-mtt2-solgel, 99e1c9e), angular `dev-mlb-frontend` (off
dev-gsp-structure-ui, becd09b), rf-node/suite dev-swarm-msci-deploy.
NOT pushed.

## What runs now (all live-verified)
- POLARI_LAZY_BOOT=on (default off = monolithic, byte-compatible):
  Phase 0 = typing+routes, LISTEN in ~10s; admission worker (daemon,
  mesh-autoconfig idiom) does core data then modules dependency-
  ordered. SWARM staging-a: core 56s / ALL msci modules online 107s
  on the real volume (was 15-25min + kill-loops). Healthcheck now
  hits /api/health (200 at core-ready; long grace kept for the
  monolithic fallback).
- Honest 503s while loading (middleware resolves CRUDE apiObject ->
  class -> module; custom APIs by package; Retry-After 5). /api/
  health + /api/modules/status (phase, per-module rows, %/times).
- POLARI_MODULES gate live on the swarm: msci set (materialsScience,
  pspp,techtree,simulations,polariapps) online; the other 18 modules
  visibly 'disabled' — enabled/not-enabled is tracked, never hidden.
- TIMING HISTORY (Dustin's ask): ModuleBootRecord rows persist each
  module's duration AFTER ITS DEPS came online, per boot+instance;
  warm boots restore history in the core phase and stamp
  expected_online_s ETAs (median; no history = NO ETA shown).
  PolariModule carries boot_status/timestamps/seeded/error/eta.
- FRONTEND /modules/bringup (angular): live tiles pending->loading->
  online/failed/blocked (STOMP /topic/PolariModule + poll fallback),
  progress bar, time-to-core/full, per-module ETA + last duration,
  disabled dashed; linked from /topology. NO browser pass yet.
- CROSS-DEVICE SPLIT EXPERIMENTS (via SSH): prf-backend:staging
  shipped to isle-core (image KEPT there). isle-core ran the AGRO
  family (aquaponics+plant_morphology+scoring): dependency order
  proven numerically (deps finish before aquaponics starts;
  deps_ready_at == last dep's online time); msci disabled there /
  agro disabled on staging-a = complementary split. DYNAMIC MOVE
  rehearsal: warm restart with techtree ADDED -> techtree admits
  fresh (no ETA), the 3 prior modules PREDICTED their durations from
  history (scoring ETA 1.076s vs actual 1.1s); warm core 24s.
- mlb-5a: POLARI_DB_LOG=quiet default ([DB-Save] stream gated, 17
  sites; warnings/errors always loud). Node compose carries all 3
  knobs render-time (${POLARI_MODULES:-} etc.).
- Selftests: moduleService.selftest_lazy_boot 34 (order/cycle/drift-
  pin/ETA-math/503+health via falcon TestClient/stubbed worker incl.
  LOUD failure + blocked deps) + selftest_db_log_quiet 16 +
  lazy-imports drift guard 15/15. Dependency edges: polari-modules.
  json is authoritative (FEATURE_REQUIRES pinned subset).

## Deploy cmd that WORKS (constraints + knobs at render)
  export LOCAL_IP=192.168.0.210
  C="node.labels.polari.machine==staging-a"
  POL_STACK_CONSTRAINTS="backend=$C frontend=$C prf-file-store=$C \
    prf-keycloak=$C prf-mariadb=$C prf-proxy=$C" \
  POLARI_LAZY_BOOT=on POLARI_MODULES=materialsScience,pspp,techtree,\
  simulations,polariapps POLARI_DB_LOG=quiet pol swarm deploy node
  (then force both service images as usual)

## mlb NEXT
- Browser pass: /modules/bringup + topology link (+ glass tab etc.).
- Derive POLARI_MODULES from ModuleAssignment rows automatically
  (pol topology/allocate emits the env; today it's typed at render).
- Nav gating sweep (mlb-4 second half): pages owned by a not-yet-
  online module render "loading — Nth in queue" (an HTTP interceptor
  on the 503 module-loading body); pspp pages already render
  refusals so v1 is acceptable.
- mlb-5b: batch seed inserts per class in one transaction; per-module
  persistence replay so Phase A restore shrinks further.
- Second swarm boot will show ETAs on /modules/bringup (history now
  exists on the volume). tt-16 blue-green module handover rides
  ModuleBootRecord + the move rehearsal above.

---

# ⚡⚡⚡ HANDOFF — 2026-07-26 (READ THIS SECTION FIRST; supersedes below)

**✅ REVIEW PASSED (Dustin) + ✅ ALL COMMITTED (later same day) +
✅ mtt-2 SOL-GEL BUILT.** Prepared for a context clear: this section
+ the plan files + the memory entries are the full pick-up.

The live target is a SWARM-based msci-focused instance, NOT the
compose suite. Full state in memory: [[swarm-msci-instance]],
[[geopolymer-structure-sampling]], [[materials-tech-tree]],
[[styling-theme-tokens]]. Plans at suite root:
MATERIALS_TECH_TREE_PLAN.md, MTT2_SOLGEL_SINTERING_PLAN.md,
GEOPOLYMER_STRUCTURE_SAMPLING_PLAN.md, FRONTEND_THEMING_PLAN.md,
MODULE_LAZY_BOOT_PLAN.md.

## ✅ COMMITS DONE 2026-07-26 (branch-per-phase, innermost-first, NOT pushed)
- framework (off dev-ssp-3-symmetry-xrd): `dev-gsp-structure` →
  `dev-mtt-1-materials-tree` → `dev-mtt2-solgel` (stack top).
- angular (off dev-ssp-2-lattice-view): `dev-sty-2-theming` →
  `dev-gsp-structure-ui` (stack top).
- rf-node: `dev-swarm-msci-deploy` (swarm nginx/grace fixes + both
  submodule pointer bumps). suite: `dev-swarm-msci-deploy`
  (stackify swarm-schema fix + session plans + rf-node pointer).
- Do NOT push — Dustin's manual step, repos are PUBLIC.

## ✅ mtt-2 Part A SOL-GEL BUILT (framework `dev-mtt2-solgel`, 6e9c188)
sg-1..5 per MTT2_SOLGEL_SINTERING_PLAN.md — a pure DATA library
(CMC-seed precedent), ZERO schema changes (condition gates already
key on arbitrary descriptors; the pH gate is just window rows):
- solgel_network.py: alkoxide species (generic Si(OR)4 + TEOS/TMOS;
  Al/Ti/Zr honest species-only), hydrolysis + water/alcohol
  condensation + growth rules on the SHARED siloxonate-q0..q4 ledger;
  pH catalysis-fork gates (acid→polymeric/spinnable,
  base→colloidal/dense; coarse neutral boundary, noted) + R gate +
  spinnability quality window; solgel_inventory (stoichiometry).
- solgel_process.py: sol→gel-point→aging→xerogel/aerogel FORK→
  densified-glass stages; 3 POINTS-EMPTY provisional Brinker datasets
  (gel-time-vs-pH, NMR Qn-vs-time, shrinkage-vs-T) that REFUSE until
  photographed — the refusal names the data ask.
- solgel_structure.py: stepped Q-groups under {pH,R} gates (shared
  new helper structure_groups.inventory_q_fractions); acid/base route
  demos through the gsp sampler/halo — acid Q4 0.0 vs base 0.5,
  polymeric XOR colloidal reachability, halo present both.
- API: GET /api/pspp/solgel/routes (+?route=acid|base), POST
  /api/pspp/solgel/stepped. polariServer seeds concatenate SOLGEL_*
  (guarded imports + stubs; drift guard 15/15).
- 58 new checks (24+15+19) green host AND in-container; full pspp
  sweep green; fixed pre-existing selftest_pspp_views red (rule count
  pinned 17 → tracks seed list). techtree sol-gel node SHELL→BUILT
  (⚠ changed seed row: live volumes keep the old text until row
  deletion + restart — cosmetic).
- Backend rebuilt + swarm service updated same day (cold seed ~10-15
  min; verify GET /api/pspp/solgel/routes?sample=false answers).

## ✅ mtt-2 sg-community BUILT + deployed (framework `dev-mtt2-solgel`, 857ba2d)
Dustin's ask: prove COMMUNITY-ACCESSIBLE sol-gel from common materials
(citrus/citric acid, rice husk, water glass), AND keep the industrial/
lab routes as REFERENCE so the lab->common SUBSTITUTION MAP is explicit
data. His steer: accessibility = a recorded PROPERTY of every
precursor/route, never a gate that hides one.
- solgel_network: alkoxide-FREE water-glass chemistry (sodium-silicate
  + citric-acid + silicate-acid-gelation rule + waterglass_inventory).
- solgel_sourcing.py (NEW `PrecursorSource` class): tiers household /
  common-industrial / lab-reagent; substitution_map (citrus juice <-
  mineral acid; water glass / rice husk <- TEOS); route_accessibility
  (route = worst precursor); route_report. COMMUNITY_ROUTES =
  waterglass-citrus, ricehusk-citrus, teos-citrus, teos-ammonia-lab.
- API: GET /api/pspp/solgel/sources, GET /solgel/community-routes
  (+?route=<name> full report). PrecursorSource wiring mirrors
  BenchmarkCase (module auto-registers; NOT in defClassList).
- ⚠ NOTHING claimed "proven". Tiers = qualitative CITED claims (real
  papers found via web, none were previously in the repo: lemon
  bio-waste sol-gel, Sustainable Chemistry 2021; rice-husk silica;
  acid-initiated sodium silicate, Gels 2024 / JMRT 2020). Numeric
  performance REFUSES until digitized. The water-glass MORPHOLOGY fork
  is OPPOSITE the alkoxide one (acidic water glass = dense small
  particles) — route_report refuses to assert a winner for it.
- 25 new checks (host + in-container). DATA ASKS to quantify: digitize
  sodium-silicate gel-time/morphology-vs-pH, rice-husk yield, lemon
  acid content.

## The running system (verify first: `docker service ls`)
- Swarm stacks: `polari-node` (all services pinned staging-a) +
  `polari-engines` (msci worker pinned isle-core, :9500 via ingress).
- App: https://prf.192.168.0.210.nip.io  API: https://api.prf.192.168.0.210.nip.io
- Deploy loop that WORKS: edit → `pol node build backend`(and/or
  frontend) → `docker service update --image prf-<x>:staging --force
  polari-node_<svc> --detach` → wait ~10-15 min cold seed (backend
  start_period is 1800s; routes 404 until endpoint construction ends,
  then answer). Bring up from cold with the constraint env — see
  swarm-msci-instance memory for the exact POL_STACK_CONSTRAINTS line.
- In-container selftests (swarm names differ from `pol modules
  selftest`): `docker run --rm -v $PWD/polari-framework:/app -w /app
  -e PYTHONPATH=/app:/app/modules prf-backend:staging python3 -m
  <module>.selftest_<x>`.

## What got built this session (all live-verified unless noted)
1. Swarm msci instance + 4 real deploy fixes (stackify swarm-schema,
   nginx lazy upstreams, backend grace/cpu). See memory.
2. Theming (pspp + materials-science + shared layout): tokens (sty-2)
   THEN three root-cause fixes verified in-browser by Dustin —
   (a) Material's prebuilt DARK palette leaked its near-white default
   into any uncolored text → fixed with `:host{color:var(--text-on-bg)}`
   anchor + SVG `fill` tokens; (b) DARK-MODE PAGE BACKGROUND: template
   has no <mat-sidenav-content>, so Material auto-generates an implicit
   `.mat-drawer-content` that never used our token → GLOBAL rule in
   styles.css ties `.mat-drawer-content/.mat-sidenav-content` to
   `--surface-app-background` (fixes bg app-wide, not just pspp);
   (c) /pspp/structure XRD page-freeze (getter→stable field render
   storm). Context-semantic tokens added: `--text-on-card{,-muted}` /
   `--text-on-bg{,-muted}` (pick by SURFACE); `--text-on-bg`=#000 light.
   FRONTEND_THEMING_PLAN.md has the rules; sty-3 sweep (app-wide, ~20
   dirs) must do :host anchor + SVG-fill audit + surface-token, not
   just hex→token. Light + dark both confirmed good on /pspp.
3. gsp-1..5 + 2b (GEOPOLYMER_STRUCTURE_SAMPLING_PLAN.md): Q-groups
   (reference/state/stepped modes) + deterministic ensemble sampler
   + /pspp/structure 3D page + Debye halo validation + density knob.
   70 selftest checks green. Halo validation caught a real sampler
   collapse bug (fixed). Optional follow-on: gsp-2 ring-statistics
   bias so more seeds land the halo in the gel band.
4. mtt-1 (MATERIALS_TECH_TREE_PLAN.md): new `materials-science` tech
   tree, 12 nodes (statistical/discrete/encapsulation hubs + 9 cores;
   stainless equiv = galvanized-bio-steel). Live.
5. smt-1: new `simulation-methods` tech tree, 9 method nodes. Live.
   techtree selftest 52/52.

## ✅ mtt-2 tech-tree DATA GAPS + Part B SINTERING ENGINE BUILT (dev-mtt2-solgel, 8ddf80e + 4f49cdc)
- GAPS ACCOUNTING (Dustin: account for the gaps in the tech tree):
  structural (theory) completion vs DATA completeness are now SEPARATE
  axes. Every sol-gel/community data ask is a first-class provisional
  DigitizedDataset; TechNode.data_dependencies_json + techtree_analysis
  .node_data_gaps DERIVE a warn gap for any referenced dataset that is
  missing/provisional/points-empty (carries the dataset's DATA ASK;
  digitize -> gap auto-clears; does NOT move completionLevel). sol-gel
  node declares 6 datasets, ceramics node 2. techtree 59 checks.
- SINTERING ENGINE (the genuinely-new Part B one): pspp/sintering_
  engine.py analytic Master Sintering Curve. Θ = ∫(1/T)exp(−Q/RT)dt
  (holds exact, ramps Simpson; isothermal closed form self-check);
  relative_density Θ->ρ via a master-curve DigitizedDataset (returns Θ,
  REFUSES ρ without a ready curve / in-range Θ); grain_size mean-field
  d^n law. HONEST SPLIT: Θ pure math, ρ(Θ)+kinetics are calibration
  data that refuse — no invented Q/curve/kinetics. sintering_structure
  .py plan-first L2 rows (grain-domain+pore-network) feeding the gsp-4
  seam. API POST /api/pspp/sinter/fire + GET /sinter/master-curves. 35
  new checks.

## ✅ mtt-2 CERAMICS SAMPLES + ESCALATION LADDER + FURNACE TECH TREE (dev-mtt2-solgel, 202391a)
Dustin's asks: locally-producible ceramic samples, "gradual escalating
temperature resistance", olivine carbon-negative track, and an
escalation ladder geopolymer-oven -> steelmaking — with tech trees
TRACKING it (his steer: a Manufacturing Tool / Furnace tree, "thermal
strain of material refinement").
- ceramics_samples.py (CeramicSample): earthenware->stoneware->fireclay
  firebrick->cordierite(thermal-shock champ)->mullite->alumina->SiC +
  TWO steelmaking basic refractories: LOCAL dolomitic (carbon-positive)
  and NON-LOCAL olivine forsterite (carbon-negative). feedstocks+tier,
  literature-approximate temps (temp_claim_status), thermal_shock,
  refractory_class (basic=steel-slag-resistant), carbon_profile.
- ceramics_ladder.py (LadderRung): the furnace bootstrapping (each rung
  built from the last one's output) + a CNT-CVD BRANCH honest that its
  gate is ATMOSPHERE not heat. validate_ladder proves consistency
  (lining fireable-below + survive-here) and surfaces the real
  mullite-firing gap as warns. steelmaking rung LINING-gated (not
  hotter); unlocks bio-galvanized-steel.
- olivine: new 'mined-nonlocal' accessibility tier; Mg2SiO4 + 2CO2 ->
  2MgCO3 + SiO2 (exact); provisional REFUSING carbonation dataset.
- NEW manufacturing-tools tech tree (6 furnace nodes; deps = the
  bootstrapping; cross-refs to linings + unlocked materials; data deps
  carry the gaps). techtree 60 checks. API /api/pspp/ceramics/samples
  (+minTemp/local/carbonNegative) + /ceramics/ladder. 28 new checks.

## ✅ GEOPOLYMER->CERAMIC/GLASS TRANSITION + /pspp/ceramics FRONTEND (dev-mtt2-solgel 1bc0b60 + angular dev-gsp-structure-ui 0065b66)
- geopolymer_ceramic_transition.py: DATA-BACKED (Table 8.8, Perera &
  Trautman 2005 — measured porosity + XRD phases). Amorphous
  geopolymer to ~1000C, kalsilite crystallizes at 1000C, leucite at
  1200C, distorted kalsilite stable to 1400C (no melting); each stage
  cites its reaction_network crystallization rule. Glass branch >1400C
  = honest above-range refusal. + 2 geopolymer-derived CeramicSamples
  (leucite-ceramic, kalsilite-ceramic).
- sinter_stages: sample a firing at N checkpoints (partial firings) ->
  Theta/rho/grain per stage, each refusing in place uncalibrated. API
  POST /api/pspp/sinter/stages + GET /ceramics/geopolymer-transition.
- FRONTEND /pspp/ceramics (angular, theme-token compliant, ng build
  green): 4 tabs — Samples+precursors (temp-ladder bars, steelmaking
  filter, feedstock inspector) / Furnace ladder (rungs+warns) /
  Geopolymer->ceramic (porosity bars + XRD + glass refusal) / Sinter
  sampler (fire a schedule -> logTheta plot + per-stage density REFUSED
  without a curve + grain). Route + home nav card.
- Backend + frontend both rebuilt; backend live-verified. FRONTEND
  DEPLOY: was building at handoff — confirm `docker service update
  --image prf-frontend:staging --force polari-node_frontend --detach`
  ran + /pspp/ceramics loads (needs a browser pass by Dustin).

## ✅ CHARACTERIZATION (FTIR+XRD) + RESEARCH-TOOLS TREE + /pspp/research (dev-mtt2-solgel 2bb873f + angular 2bb... /research commit)
Dustin: add FTIR alongside XRD (better for our amorphous materials +
locally/safely doable), explain what/how in plain language, and add
RESEARCH TOOLS as a category with its OWN tech tree (goal accountability).
- characterization.py: XRD + FTIR as data, plain-language what/how +
  diagnostic signals. FTIR reads BONDS (works on amorphous gels; XRD
  only sees a halo) + the carbonate band VERIFIES olivine carbon-neg.
  simulated_ftir: Si-O-T main band shifts LOWER with more Al (approx,
  cited anchors; direction reliable, intensities+exact pos REFUSE).
  Honest safety: XRD radiation hazard/not-DIY, FTIR safe/ambitious.
  Provisional FTIR band-calibration dataset = the data ask.
- research_tools.py (ResearchTool): buildable instruments easiest-first
  — red-cabbage pH (trivial), visible spectrometer (DVD+webcam, FTIR's
  accessible cousin), colorimeter, Brix (sugar direct; mineral/health
  = CORRELATION only), EC/TDS (direct minerals), thermocouple logger
  (bridges to furnace ladder), turbidity, DIY microscope, open-source
  FTIR (high). Parts carry accessibility tiers.
- NEW research-tools tech tree (7th, parallel to manufacturing): 9
  nodes, FTIR deps visible-spectrometer, thermocouple cross-refs
  furnaces, FTIR carries the band data gap. techtree 61 checks.
- FRONTEND /pspp/research (3 tabs: methods explainer / FTIR sampler /
  research tools). API /characterization/methods + /ftir +
  /research-tools. 31 new backend checks. ng build green.
- DEPLOY: backend rolled; frontend building at handoff — confirm
  `docker service update --image prf-frontend:staging --force
  polari-node_frontend --detach` ran + /pspp/research loads.

## ✅ mtt-2 GLASS CORE: REFINEMENT WINDOWS + VISCOUS SINTERING (2026-07-27, dev-mtt2-solgel + angular dev-gsp-structure-ui)
Dustin confirmed BOTH halves ("a viscous sintering variant would be
useful so likely both"). Closes the "glass windows" item from the
remaining mtt-2 cores.
- glass_refinement.py: viscosity FIXED POINTS as data (log-η values
  are DEFINITIONS — 10^3 working / 10^6.6 Littleton / 10^12 anneal /
  10^13.5 strain / ~10^1 practical melting; soda-lime TEMPERATURES
  literature-approximate, Shelby 2005). fit_vft = EXACT closed-form
  VFT solve through 3 anchor points, ZERO free parameters, other
  points reported as honesty residuals (soda-lime lands A≈-3.0,
  B≈4990K, T0≈206C — classic territory; residuals ≤0.43 log units).
  viscosity_at refuses outside the fitted span. 4 banded
  condition-gate windows (fining <10^2 / forming 10^3..10^6.6 /
  annealing 10^12..10^13.5 / soda-lime devit-risk zone 560..1040C).
  process_map grades every gate at a probed temperature. 3 new
  datasets: viscosity points READY; devit TTT + glass-frit viscous
  master curve provisional-REFUSING (the data asks).
- viscous_sintering.py: the glass variant of Part B. Λ = ∫γ/(η(T)r)dt
  reduced viscous work (pure math over cited γ default 0.30 N/m
  Scholze 1991 — surfaced in assumptions, overridable — + the VFT fit
  + particle radius; schedule above the fitted span REFUSES, time
  below the rigid floor contributes 0, stated). Frenkel early stage
  y=(3/8)Λ valid to y=0.10 — past it the refusal names BOTH ways
  onward (digitize the frit master curve, or measure a closed-pore
  checkpoint); Mackenzie-Shuttleworth final stage runs ONLY from a
  MEASURED checkpoint (ρ≥0.9 + pore radius). plan_viscous_structure
  = amorphous-matrix + pore L2 rows, NO grain row (glass has no
  grains — the absence is the point). viscous_fire orchestrates,
  every piece honest in place. The mid-stage gap (Frenkel→closed
  pores) is a REAL model gap (Scherer is the cited bridge) — refused,
  not papered over.
- API: GET /api/pspp/glass/refinement (+?temperature=<C> process
  map; reads live dataset/window rows when edited), POST
  /api/pspp/sinter/viscous. /api/pspp/sinter/master-curves now lists
  BOTH kinds (log10Theta='solid-state', log10Lambda='viscous').
- Seeds concatenated in polariServer (GLASS_DIGITIZED_DATASETS +
  GLASS_THRESHOLD_WINDOWS, guarded import + stub names); drift guard
  15/15. techtree glass node: description BUILT + 3 data_deps
  (⚠ changed seed row: live volumes keep old text until row deletion
  + restart — cosmetic, same as the sol-gel node). techtree 61/61.
- FRONTEND: 5th tab "Glass (viscous)" on /pspp/ceramics — viscosity
  ladder bars, VFT fit + residuals line, temperature probe grading
  the gates (open/closed/warn chips, refusals rendered), viscous
  frit-firing form (Λ + ρ + MS + structure-plan note, refusals
  rendered). pspp.service +glassRefinement/+sinterViscous. ng build
  green (pre-existing warnings only). NO browser pass yet.
- 68 new checks (selftest_glass_refinement 32 + selftest_viscous_
  sintering 36, green host AND in-container); FULL pspp sweep green
  (32 suites). ✅ DEPLOYED + LIVE-VERIFIED same day: both images
  rebuilt, both services rolled, backend answered ~5 min post-roll —
  GET /glass/refinement 200 (points + exact VFT fit), POST
  /sinter/viscous Λ matches host to full precision, ?temperature=
  process map grades, frontend /pspp/ceramics 200. Browser pass on
  the new tab still pending (Dustin).
- DATA ASKS added: digitize a soda-lime devit TTT/growth-rate curve
  (turns the risk zone into hold-time budgets) + a glass-frit
  ρ vs log10 Λ master curve (unlocks mid/final-stage ρ without a
  measured checkpoint) + replace approximate fixed-point temps with
  a measured batch viscosity curve (upgrade, not unlock).

## NEXT (Dustin's stated order)
- Browser pass on /pspp/ceramics + /pspp/research (theming + tabs)
  — now ALSO the new Glass (viscous) tab.
- Remaining mtt-2 cores: CNT builder, silicon grades (glass DONE).
- Research-tool ideas suggested beyond Dustin's 3 (in case he wants
  more built): visible spectrometer, EC/TDS, colorimeter, thermocouple
  logger, turbidity, DIY microscope — all seeded already.
- sinter-5 (phase-field/kMC spatial microstructure) DEFERRED per plan
  — only if mean-field proves insufficient.
- DATA ASKS that turn refusals into predictions (each is now a tree
  data gap): alumina/zirconia densification master curve + fitted Q
  (unlocks sinter ρ); grain-growth (n,k0,Qg); sol-gel gel-time-vs-pH,
  29Si NMR Qn-vs-time, xerogel shrinkage-vs-T (also sinter calib),
  sodium-silicate morphology-vs-pH, ricehusk yield, lemon acid
  content; GLASS: soda-lime devit TTT curve + glass-frit ρ vs log10 Λ
  viscous master curve (+ optional measured batch viscosity curve).
- then variant layers: carbon-negative (geopolymer) → magnetic/
  conductive → thermal → structural → nanocomposite semiconductors.
- Open decisions for Dustin: sub-domain labels (statistical/discrete
  vs stochastic/particulate — seed-only, cheap to rename).
- ⚡ mlb LAZY-BOOT IS PREPPED (Dustin asked 2026-07-27): full wiring
  survey with file:line refs is now the PREP section atop
  MODULE_LAZY_BOOT_PLAN.md — boot order mapped (listen is strictly
  LAST today; health route is net-new; [DB-Save] prints unconditional
  in managedDB.py), STOMP + frontend module grid already exist,
  dependency-edge DRIFT flagged (FEATURE_REQUIRES vs
  polari-modules.json — pick one source in mlb-1). Precondition
  (swarm healthy, seed verified end-to-end) is MET via the glass
  deploy. Start with mlb-0 (POLARI_MODULES env in
  pol-services/compose/services/prf-backend.yml; proposed msci set in
  the PREP section — Dustin confirms the list) then mlb-1+2.

## Commit note
✅ DONE — see "COMMITS DONE" at top. Nothing is pushed; pushing is
Dustin's manual step (repos are PUBLIC).

---

# ⚡ PSPP HANDOFF — 2026-07-19 (READ THIS SECTION FIRST)

## ⚡⚡ UPDATE 2026-07-19 (later session): pspp-8 FULL + THRESHOLD WINDOWS BUILT
Handoff items 3+4 below are DONE (the geopolymer-simulation +
experiment-guidance capability). Framework branch
`dev-pspp-8-network-stepping` (off the pspp-5 head c651f39), NOT
merged/pushed — review gate stands. 340 checks green across 17 pspp
suites (4 new: threshold_windows 36, network_stepping 37,
cure_checkpoints 20, experiment_guidance 14); lazy-imports guard
15/15. Full detail: 2026-07-19 UPDATE block atop PSPP_MATERIALS_PLAN.
Short version:
- `threshold_windows.py` ThresholdReactionWindow: banded asymmetric
  grading (p.193 preferred bands + crack thresholds seeded, supersede
  the binary patent rows in merged grading) + condition-GATE rows
  (MR<1.20 Q0 threshold as data).
- `network_stepping.py` (pspp-8 full): solution_inventory from
  Table 5.6 (Q motifs = dynamic resources), applicable_rules
  (species/site/cation/gate — NEW cation_family + condition_windows_json
  on ReactionRule), stoichiometric step_once, kinetics-free
  reachable_frameworks (rule chains, hypothesis floors, competing
  branches). I5 stands — rates still refuse.
- `cure_checkpoints.py`: plan-first promotion of measured cure
  completions → TRANSFORMATIVE execution edge + MaterialState +
  reactionExtent StructureClaim; apply is the explicit knob.
- `experiment_guidance.py` + API: POST /api/pspp/guide (grade +
  pathways + cure + gap-list-as-experiment-plan), GET
  /api/pspp/pathways, POST /api/pspp/checkpoint.
- Verify: add these to the loop below —
  `threshold_windows network_stepping cure_checkpoints
  experiment_guidance`.
- NOT deployed to staging yet (backend rebuild needed for the new
  routes/class; seeds are idempotent-by-name — new rows only, no
  changed rows, so no volume surgery needed).
- Remaining NEXT (order): Dustin review · V3 visuals · pspp-11 wax
  half · pspp-6 split decision · new data asks (a K glass→solution
  table would light up K pathways; calibrated kinetics rows would
  unlock time-resolved stepping — both refuse with those exact asks
  today).

### ⚡⚡⚡ SAME DAY, 3rd pass: V3 VISUALS + pspp-11 WAX HALF BUILT (rough-
### functionality mode per Dustin: "foundational approach, debug later")
Backend (framework `dev-pspp-8-network-stepping`, +commit 70fbb4f):
- `wax_states.py` (pspp-11 wax half): every WaxFeedstockDefinition
  derives its 4-stage VIRTUAL state route (solid→softened→melt→
  superheated) from its own temperatures — zero writes, zero behavior
  change; GET /api/pspp/wax-states. selftest 10/10.
- `benchmark_cases.py` (V3): 3 Ch.8 BenchmarkCase rows + measured-vs-
  predicted overlay — windows + framework reachability genuinely
  predict (all 3 cases verdict MATCH incl. kalsilite via the NEW
  ortho-sialate-formation-k twin rule; phillipsite/leucite correctly
  absent — Q0 gate); strength/cure refuse per I5. GET
  /api/pspp/benchmarks + /{name}/overlay. selftest 12/12.
Frontend (angular `dev-pspp-v3-visuals` off dev-pspp-v-visual-
proofing, commit 1be9165, ng build green):
- /pspp/benchmarks (overlay wall, verdict chips), /pspp/guide
  (experiment-guide form; gap list = experiment plan), /pspp/states
  (state-DAG SVG viewer + wax routes dropdown; `pspp-state-dag` also
  registered as a mountable no-code component with [material]).
- Grader renders BANDED p.193 gauges (per-band colors) + edit links;
  network detail panel links to ReactionRule/ChemicalSpecies CRUDE
  pages — "editable on canvas" v1 = riding /class-main-page/:class.
- Service +pathways/guide/checkpoint/benchmarks/waxStates; routes +
  registry entries added.
⚠ ROUGH-BUILD CAVEATS (debug list): NOT deployed/live-verified (no
browser pass, no staging rebuild); benchmark JSON panels are raw
pretty-print; state-DAG layout is naive depth-columns; guide K-cation
pathway section refuses by design (Na-only Table 5.6); banded gauge
untested against live payload shapes. Total pspp checks now 362
across 19 suites (all green at commit time).

**⚠ PSPP PARKED HERE (Dustin 2026-07-19, moving topics). Architecture
is CLOSED for geopolymers — every remaining gap is data entry, an
engine behind a registered seam, or debug/polish. THE canonical
to-address list is PSPP_MATERIALS_PLAN.md §4b GAP REGISTER:
A1-A5 engine gaps (kinetics execution, gel-structure evolution,
degradation engines, strength-as-selectable-model, amount-weighted
reachability) · B1-B6 data asks (K solution table, kinetics
calibrations, Fig 5.22 re-shoot, Ch.6/7/CMC pages, setting-class
completions, p.191 cut-off text) · C1-C7 debug/polish (staging
deploy + browser pass first) · D1-D3 Dustin decisions (pspp-6 split,
spatial sims, UQ). Pick up with C1, then work the register.**

## What PSPP is
A **generic reactive-material engine** inside Polari (module `pspp`), built
2026-07-18/19 from a three-way design dialogue (Dustin ↔ Claude ↔ ChatGPT, which
ingested Davidovits *Geopolymer Chemistry and Applications* + a CMC book ToC).
Core thesis: a material is NOT a property sheet — it is an identity with a DAG of
durable states; processes are edges; chemistry is a library of species +
graph-rewrite rules (competing hypotheses, cited, kinetics-free until calibrated);
book figures live as DigitizedDataset rows that every chart derives from.
Swap the library (sol-gel, cement, oxidation…) — never redesign the engine.

## Read these, in order
1. `PSPP_MATERIALS_PLAN.md` (suite root) — architecture, 8 invariants (I1 canonical
   state, I2 declared ExecutionEffect, I5 no invented kinetics, I6 curves-as-data…),
   phase table with status.
2. `PSPP_VISUAL_PROOFING_PLAN.md` — the visuals/no-code slice (V1 done, V2 done,
   V3 = next).
3. `PSPP_DIGITIZED_DATASETS.json` (suite root) — the book transcription RECORD:
   20 qualitative claims, 3 benchmark cases, as-printed anomalies (Table 5.6 sums,
   H2O/Na2O 17.20-vs-15.45). Operational form = `modules/pspp/datasets_seed.py`.
4. `polari-rf-node/polari-framework/modules/pspp/` — 30 small files, one concern
   each; every `selftest_*.py` runs via
   `PYTHONPATH=modules python3 -m pspp.selftest_<name>` from polari-framework/
   (sitecustomize covers server entrypoints only, NOT host `-m` runs).
5. Memory: `pspp-materials.md` (+ MEMORY.md index) has the compressed history.

## Branch topology (NOT merged, NOT pushed — Dustin's review gate)
polari-framework, stacked off dev:
`dev-pspp-1-evidence-claims` → `2-material-states` → `3-structure-layer` →
`7-q-distribution` → `4-process-layer` → `v-visual-proofing` →
`5-scale-transfers` (head also carries pspp-9 + pspp-11 commits: c651f39).
polari-platform-angular: `dev-pspp-v-visual-proofing` (1 commit, ng build green).
⚠ Branch names lag content after pspp-4 — commits landed on the current head
branch rather than new ones per phase. Verify with `git log --oneline dev..HEAD`.

## What is DONE (all selftested, 233 checks green total)
- Evidence/claims/EvidenceMethod vocabulary; DigitizedDataset + ONE generic
  interpolation engine (bands, UNSUPPORTED extrapolation refusals).
- 13 datasets (Ch.5 tables/figures incl. Figs 5.4/5.5 Q-curves, Fig 5.20/5.21/5.22,
  Tables 5.4/5.5/5.6/5.8; Ch.8 curing kinetics trio + Table 8.8 thermal phases).
- MaterialState DAG (implicit-virtual canonical `#as-defined`, sync-on-need, NO
  boot backfill); ProcessingStage rows; `state_resolution` = THE name→state path.
- Structure layer (5-descriptor mandatory core incl. reactionExtent∈[0,1]; L2
  multi-domain; `require_descriptors` gate).
- composition_math (book-pinned MR/WR 1.032/1.568, Baumé, oxide ratios incl.
  H2O/Al2O3); reaction_windows (8 patent rows, Tables A/C; p.193 graded bands
  recorded in notes — asymmetric variant NOT yet modeled).
- Process layer (ExecutionEffect I2, heating deposition models, thermal-window
  admissibility) + reaction network as data (17 rules: Na two-phase Fig 8.21
  surface→albite / interior→nepheline, phillipsite 6a/6b, K kalsilite/leucite
  analogues; site_constraint; competing hypotheses).
- q_distribution engines; progress_engine v1 (measured curves only, refusals name
  the dataset to enter); scale transfers (wax retrofit rows cite live msim models);
  exposure + performance scenarios v1 (elastic-bounds via mixture_bounds,
  water-transport via descriptors→Darcy pointer); CMC library through EXISTING
  classes (the zero-schema-change generality proof).
- `/api/pspp/*` (6 endpoints) + Angular `/pspp` pages (proofing chart wall from
  rows via Observable Plot, reaction-network SVG where styling=evidence, grader,
  progress) + no-code registry + seeded published page (module_id `pspp`).

## Verify before building anything
```
cd polari-rf-node/polari-framework
for t in evidence_claims digitized_datasets material_states material_structure \
  composition_math reaction_windows q_distribution material_processes \
  reaction_network pspp_views scale_transfers performance_scenarios cmc_library; \
  do PYTHONPATH=modules python3 -m pspp.selftest_$t | tail -1; done
cd ../polari-platform-angular && npm run build   # green, pre-existing warnings only
```
Live proofing: bring the stack up (`pol node up --env staging`), open
`/pspp/proofing` with the book — charts should match Figs 5.4/5.5, 8.18, 8.20,
5.20, 5.22, Tables 5.4/5.5/8.8.

## NEXT work, in priority order
1. **Dustin's review of the stack** — nothing merges until then.
2. **V3 visuals**: benchmark measured-vs-predicted overlays (3 benchmark cases in
   the JSON → rows), state-DAG + transfers view on the material detail page,
   no-code editing of rules/windows on the canvas.
3. **Threshold/asymmetric ReactionWindow variant** (p.193 preferred bands 1.3-1.52
   / 4.0-4.2 + crack thresholds <1.1 / <3.7 — currently notes only).
4. **pspp-8 full**: reaction-network stepping (rules consume/produce species,
   Q-distribution as dynamic resource), promote cure checkpoints to MaterialState
   rows via TRANSFORMATIVE executions.
5. **pspp-11 wax half**: map waxprint feedstocks onto states (wax ProcessingStages
   already seeded), zero behavior change.
6. **pspp-6 remainder**: geopolymer module glue (`modules/geopolymer/` was folded
   into `modules/pspp` — decide whether to split per module-projects idiom).
7. Data asks (only if Dustin photographs more): Ch.6 Fig 6.6 molecule types,
   Ch.7 kaolinite steps 1-7 pages, CMC chapter equations.

## Gotchas
- Never rescale as-printed book anomalies (Table 5.6 sums 92/110; H2O discrepancy).
- `pspp` imports as TOP-LEVEL package (modules/ is an import root).
- Seeds are idempotent-by-name: changed seed content needs row deletion + restart
  on existing volumes (standing gotcha).
- All 8 repos are PUBLIC — book data enters as cited transcriptions only, never
  scanned pages.
- Keep every capability = knob + evidence-bearing refusal; absence is honest data.

---

# Next-agent handoff — 2026-07-16 (THE BIG DAY: ncg-0..7 + DMV/scorecard epistemics stack)

## 🎯🎯 CURRENT STATE (Dustin 2026-07-19): MODULE PROJECTS DONE + EVERYTHING ON dev
**GRACEFUL_MOBILITY_PLAN.md is SHELVED for now (Dustin's call) — do
NOT start gm-1..6 until Dustin re-opens it.**
Module Projects mp-2+mp-3+mp-4 are EXECUTED, not just prepped —
Dustin ran the module-projects/ batches himself:
- ALL 22 feature modules live in modules/ (waves 1-6, pure renames,
  register paths updated) AND each is split to its own PUBLIC repo
  https://github.com/dausume/polari-module-<name> — remote main ==
  local `git subtree split` hash VERIFIED for all 22. In-tree copies
  stay AUTHORITATIVE; `pol modules publish <m>` re-pushes.
- Staging rebuilt on the full new layout: ~65 suites green; 3 reds
  triaged (aquaponics 12/13 = known pre-existing; testing double-
  import via the modules. namespace prefix = fixed; resources
  topology-character drift = re-pinned to tanks).
- **EVERYTHING IS MERGED TO dev in every repo** (2026-07-19, at
  Dustin's direction): framework dev = 3c1a28c (tt-1..15 backend +
  mp-1..4 + fixes, 29 commits ff), angular dev = aaa56f6 (tt-2..15
  UI, 12 commits ff), cli dev = c3f9892 (tt-12 apps + mp rails),
  rf-node dev carries both pointers (d6d870a), suite dev carries
  the batch scripts + plans. The old review-gate branch stacks are
  now redundant with dev (safe to delete after push). NOT pushed to
  origin — push is Dustin's manual step, repos are PUBLIC.
- Follow-ups parked for later phases: in-tree retirement of split
  modules (makes get/drop the real workflow), db_backend/rows
  reconcile, twin+dask stacks still DOWN, staging-nip parity diff.

## ⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡ 2026-07-18 (earlier): mp-2/mp-3 PREP + module-projects/ BATCHES — BUILT+LIVE
Dustin's ask: do all Module-Projects preparation an agent can, then
hand over SMALL BATCHED COMMAND FILES for the git/GitHub/deploy steps
only a human should run. Both delivered — read the STATUS block atop
**MODULE_PROJECTS_PLAN.md** (full detail) and
**`module-projects/README.md`** (the batch order Dustin runs).
Short version:
- **mp-3 lazy core BUILT+LIVE**: polariServer's 113 feature-module
  imports → 30 guarded blocks (absent code stubs SEED_*→[]/None +
  honest [ModuleLoading] boot line; downloaded-but-broken still
  raises); feature endpoints gate on feature_available; /modules +
  detail + Polari-Apps plans answer 'not downloaded — pol modules
  get <m>'. Seam: moduleService/module_loading.py. Drift guard
  selftest_lazy_imports 15/15 (ast-pins imports↔stubs). PROOF:
  in-container import of polariApiServer.polariServer with
  modules/biomining hidden succeeds.
- **Register FILLED**: all 20 feature modules + waves 1-6 +
  requires (cross-import survey) + required_by_core (xr, resources).
- **mp-2 rails BUILT**: pol modules publish (subtree split+push,
  prints its git) / register (--vendor) / get-drop refusals
  (requires + required_by_core) / sizes in registry.
- **module-projects/ batches (Dustin runs)**: 00-preflight →
  01-split-already-moved → 10-wave.sh <1..6> → 20-split-module.sh →
  90-verify-all.sh. env-file + pol-proxy gotchas baked in. gh is NOT
  authed on this machine (gh auth login is step one).
- **Two pre-existing reds found+fixed while verifying**: (1)
  SimulationDefinition.xr_requirement was assigned but never a
  parameter — EVERY SimulationDefinition CREATE raised NameError
  (5 seed sims failed every boot since the zones work); (2)
  managedFiles.openFile ignored self.Path — 304 'outside of path
  scope' boot lines, now 0.
- Branches: framework `dev-mp-3-lazy-core` (off
  dev-mp-1-module-projects), cli `dev-mp-2-publish-cli` (off
  dev-mp-1-modules-cli). NOT on dev, NOT pushed (review gate).
  GRACEFUL_MOBILITY_PLAN gm-1..6 remains queued after this.

## 🎯 NEXT AGENT STARTS HERE (Dustin 2026-07-18, end of session)
**⚠️ SUPERSEDED by the 2026-07-19 block above: item 1 (graceful
mobility) is SHELVED; item 2 (module projects) is DONE.**
Module moves between containers are smooth and CONFIRMED by Dustin.
The queued build, in order:
1. **GRACEFUL_MOBILITY_PLAN.md** (NEW — read end-to-end): move
   ENGINES / INFRASTRUCTURE (keydb, minio, mariadb, owned-sqlite
   instances) / AUTH (keycloak) between devices with warm-swap
   discipline (start new → ready-gate → swap refs/ports → quiesce,
   no in-flight actions, no data loss → retire old). gm-1 engine
   blue-green (swarm start-first) → gm-2 quiesce seam +
   MoveOperation receipts → gm-3 keydb/minio → gm-4 keycloak →
   gm-5 mariadb/sqlite → gm-6 kind-aware UI flows. Every phase ends
   with the ping/selftest verification paint.
2. **MODULE_PROJECTS_PLAN.md mp-2..mp-5** (EXECUTION APPENDIX added):
   subtree-split each moved module into polari-module-<name> repos
   (PUBLIC — no secrets), fill registry repo fields (get/drop rails
   go live automatically), `pol modules publish`, mp-3 lazy
   seed/endpoint imports so the CORE boots without downstream, then
   the mp-4 migration waves in the listed leaf-first order.
Both plans build on live, verified substrate — sixteen tt/mp phases
deployed on staging today, all on the review branch stacks below,
NOTHING on dev, NOTHING pushed (Dustin's review gate stands).

## ⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡ 2026-07-18: mp-1 MODULE PROJECTS SLICE 1 — LIVE
**Read MODULE_PROJECTS_PLAN.md** (new, suite root) — Dustin's
direction: the project is getting enormous; keep the basis, make
downstream modules their own downloadable sub-projects; feature
modules outside modules/ was a mistake — move them iteratively.
Slice 1 BUILT+LIVE:
- modules/ is a second IMPORT ROOT (server insert + sitecustomize +
  PYTHONPATH=/app/modules in the backend image) — moved modules keep
  their import names, zero import rewrites.
- FIRST MOVES: biomining + microalgae → modules/ (git mv, history
  kept). Live: import from /app/modules, 44 rows seeded, pol modules
  selftest biomining 33/33 from the new home.
- REGISTER: modules/polari-modules.json — kind official|vendor|self,
  repo ('' until mp-2 split), downloaded flag RE-DERIVED from the
  filesystem every read. moduleService/module_registry.py; user
  Create-Module flow auto-registers kind 'self'; GET
  /modules/registry; `pol modules registry` prints it; `pol modules
  get|drop` = the git rails (honest refusal until repos split in
  mp-2; drop refuses on uncommitted work).
- All discovery dual-root: selftest discovery, pip-suggest
  exclusions, /modules list + drill-in, pol modules list/selftest.
- KNOWN COSMETIC: 'File Instance ... outside of path scope' log
  lines for modules-dir classes (source-file tracker only knows the
  framework root — fix alongside mp-3).
NEXT: mp-2 repo split (per-module git repos + registry repo fields +
real get/drop/publish), mp-3 lazy seed/endpoint imports so the CORE
boots without downstream. Branches: framework
`dev-mp-1-module-projects`, cli `dev-mp-1-modules-cli` (stack tops).

## ⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡ 2026-07-18: tt-15 MOVE-BUTTON FIX — LIVE
Dustin's bug ('move aquaponics to prf-b — nothing happens'): the
drawer's move only worked on /topology; /testing + Module Management
embed the same drawer with no listener → silent no-op. Fixed:
topology-graph-view EXECUTES the move itself (inline outcome in the
drawer, self-refetch so the circle moves immediately, (moved) event
for hosts — wired on all three pages). Live round trip verified:
aquaponics → prf-b (ghost at prf-a) → back to prf-a (ghost at
prf-b, left visible). Drawer states runtime semantics honestly:
same-image moves need NO container replacement (both backends carry
the code; routing follows rows instantly).
**ROADMAP (Dustin's ask, NOT built): graceful blue-green module
handover** — for engine relocations / module-gated builds: start the
new container, warm it, swap references/ports the moment it's ready,
quiesce in-flight actions on the old one (no data loss/lag), then
retire it. Candidate tt-16; touches swarm deploy + provider routing
+ a drain seam in polariServer.
Branch: angular `dev-tt-15-move-fix` (stack top).

## ⚡⚡⚡⚡⚡⚡⚡⚡⚡⚡ 2026-07-18: tt-14 TOPOLOGY COHERENCE + VISIBILITY — LIVE
Dustin's semantic corrections (screenshots) encoded end-to-end:
- **Placement coherence**: only POLARI instances receive modules
  (workers/engines ARE Polari — a Polari wrapped the engine from the
  beginning); psc + infra + AUTH containers are non-adaptive
  integrated apps — placement_check refuses them in plan_move AND
  /assign; engine capabilities (msci fem/dft,
  ENGINE_CAPABILITY_MODULES) restrict to engine/worker hosts; the
  move picker only OFFERS coherent targets (device moves = engine
  modules only; sim machine rows excluded; live-verified: move to
  psc-a refused with the honest sentence).
- **Visibility**: appKind category colors (polari indigo /
  integrated-app teal / auth purple / infra brown) + per-container
  service DOTS (keycloak purple, mariadb/keydb amber, frontend vs
  backend distinguishable) + legend; NAMED storage identity per
  Polari card ('sqlite-<name> (owned)' vs 'pol-mariadb (shared)');
  /modules/{id} + module-details show WHICH database each class's
  rows live on. FOUND LIVE: prf-a's row claimed sqlite while the
  backend runs mariadb:polari_objects — corrected to combo; the
  other instance rows' db_backend may drift the same way
  (observation-reconcile is a follow-up).
- **Machine pings fixed**: isle-core now pings GREEN (node-addressed
  http://192.168.0.25:9500/capability); lightweight row corrected to
  swarm worker + honestly 'unpingable — nothing serving' instead of
  a scary 404; sim rows marked synthetic.
- **UI fixes**: light-mode white-on-white text swept to explicit
  dark colors (topology/testing/tech-tree/apps); wrapped-label
  packing pads for WIDTH so labels can't collide; machines endpoint
  500 fixed (junk roles_json).
DEFERRED (Dustin's asks, planned not built): sqlite dive-in
(per-file object inventory across containers), fe↔be login
capability matrix, cross-instance per-class DB map, class ownership
across modules (transient coherence of classes).
Branches: framework `dev-tt-14-coherence`, angular
`dev-tt-14-coherence-ui` (stack tops). selftests 45+19+52
in-container.

## ⚡⚡⚡⚡⚡⚡⚡⚡⚡ 2026-07-18: tt-13 DYNAMIC TOPOLOGY MOVES — LIVE
Click any module circle on /topology → drawer shows where it lives
(container + host + state) + a Move picker. plan_move knows MOVING
AN ENGINE ≠ MOVING A MODULE: container target = module reassignment
(former enabled placements become 'transient' GHOSTS — new
ASSIGNMENT_STATES entry, dashed+faded in the graph, EXCLUDED from
resolution/tests, one click back); device target = engine relocation
(the single-purpose provider instance re-pins machine+constraint;
stack redeploy stays the human pol command, returned as text);
device target for a multi-home module refused honestly. POST
/api/topology/move ({plan:true} previews). PERSISTENCE PROVEN LIVE:
moved mathshapes prf-a→prf-b (ghost left at prf-a — VISIBLE NOW on
/topology for review), restarted prf-backend, rows came back exactly
(and engines stayed pinned to isle-core). Engine-relocation
correctly plans engines isle-core→lightweight (plan-only, not
executed). selftests 33/33+19/19+52/52 in-container. Branches:
framework `dev-tt-13-dynamic-moves`, angular `dev-tt-13-moves-ui`
(stack tops).

## ⚡⚡⚡⚡⚡⚡⚡⚡ 2026-07-18: tt-12 POLARI-APPS + ISLE-CORE SWARM SPLIT — LIVE
Two things, both live on staging:
- **Swarm split across isle-core + staging-a (Dustin's ask).** All
  stacks brought down; isle-core (dustin-etts-mesh-core — was
  ALREADY a swarm node) labeled polari.machine=isle-core; the 4.5GB
  prf-msci-engines:staging image shipped lightweight→isle-core
  (gzip ssh pipe, 3m51s); InstanceDefinition 'engines' repointed
  (machine_name=isle-core + constraint) via the topology API;
  redeployed via POL_STACK_CONSTRAINTS + pol swarm deploy (NOTE:
  bare `pol swarm deploy engines` does NOT read stacks.yml — the
  constraint env comes from pol topology apply / pol allocate
  paths). RESULT: the cross-dependent pair is SPLIT between hosts —
  multiscale@prf-a (staging-a) → fem/dft on isle-core, ping-green
  through the routing mesh at :9500 (http, plaintext notated).
  Suite back up on staging-a; twin + dask stacks left DOWN.
  ⚠️ `pol topology render` shows a PRE-EXISTING suite-bundle PARITY
  DIFF on docker-compose.staging-nip.yml — check with Dustin.
- **tt-12 Polari-Apps.** polariapps/ + /api/apps + `pol apps` +
  /apps page: an app = a module configuration for a use-case;
  deployment is PLAN-FIRST + EXPORTABLE (polari-app-package JSON;
  `pol apps deploy <file.json>`), apply writes ModuleAssignment
  rows ONLY. Seeded: wax-print-shop (wax sims + auger shapes via
  mathshapes), judicial-lean, dmv-policy-analysis. LIVE round trip
  proven: plan 33% → export → deploy file → rows written
  (waxprint/mathshapes/waxsupply/supplychain → prf-a) → plan 100%.
  selftest_apps 20/20. Branches: framework `dev-tt-12-apps`, cli
  `dev-tt-12-apps-cli`, angular `dev-tt-12-apps-ui` (stack tops).

## ⚡⚡⚡⚡⚡⚡⚡ 2026-07-18: tt-11 TESTING OVER TOPOLOGY — BUILT+LIVE
Dustin: tie testing into topology so the graph visualizes test
progress. Built + deployed:
- **Backend** topology/topology_testing{,_api}.py: TopologyTestRun
  (subprocess selftest runs, parsed X/Y tallies, output tails) +
  IntegrationPing (FOUNDATIONAL connectivity only — machines via
  system_info_url, dep edges via top-7 provider routing = the real
  cross-node check, config-artifact connections honestly
  'static-artifact') — protocol + secured/how notated on every row.
  GET /api/topology/testing + POST run {module|all} + POST ping.
  selftest_testing 19/19. Module states: pass/fail/never-run/
  no-suites; partial runs are NOT green; instance/host rollups.
- **/testing page** (route+nav): wraps topology-graph-view with
  [testing] — modules/hosts red on fail, green on all-pass; pinged
  edges recolor + '· http ⚠'/'· https 🔒' labels; run/ping controls +
  suites/links tables. LIVE-verified: topology suites 3/3 pass
  in-container via the API; engines dep-edges ping OK cross-node
  (http, plaintext notated); isle-core/lightweight system-info URLs
  honestly FAIL 404 (real finding for Dustin); 18 links recorded.
- **Layout (Dustin review feedback)**: connector limit TRIPLED
  (gutter cap 6× largest circle diameter, gaps rewidened);
  module/engine labels WORD-WRAP (≤3 lines) with packing padded so
  labels never collide.
- **Module Management fix (Dustin's screenshots — 'only two modules
  configurable')**: GET /modules now lists ALL 39 modules (37
  boundary ones with classes/rows + boundary flag → card shows
  'loaded in-process · placement → Topology' instead of a dead
  toggle). Also KILLED the bogus '24 missing packages: pip install
  aquaponics ... topology' suggestion (framework dirs excluded from
  installable candidates; dependency selftest 14/14).
Branches (stack tops): framework `dev-tt-11-testing`, angular
`dev-tt-11-testing-ui`.

## ⚡⚡⚡⚡⚡⚡ 2026-07-18 (later): tt-9 CROSS-TREE ZOOM + tt-10 MODULE DRILL-IN — BUILT+LIVE
Dustin's follow-ups, all deployed to staging:
- **tt-9 cross-tree refs (NO edges)**: TechNode.cross_refs_json →
  dotted '↗ node · tree' chips + drawer rows naming the ref's HOME
  TREE; click = switch tree + center/select the target (focusNode/
  zoomRef seam). 18 refs seeded both directions across electronics ↔
  raw-supply-chain (+economy→3d-printing); boot backfill stamped
  pre-tt-9 rows (live: filled 18). Dangling refs = warn findings,
  red-dotted unclickable chips.
- **topology parity + layout (Dustin's connector complaint)**: dep
  connectors now run module circle → OWN CONTAINER BORDER → partner
  border → circle (modules stay physically inside; only the
  border-to-border run is external); inter-host gutter capped at 2×
  the largest module circle's diameter; instances barycenter-ordered
  + hosts vertically shifted to align with partners. Clicking a
  dashed transient copy zooms to the instance holding the primary.
- **tt-10 drill-in**: GET /modules/{id} now serves EVERY framework
  directory module (boundary fallback — registry only knew 2 legacy
  modules) with pages / real apiRoutes (text-scanned add_route, both
  spellings) / selftests + per-class row counts. module-details page
  gains a 'Navigate' tab (Pages/Data/Functionality/Selftests);
  topology drawer module chips + tech-tree theory ✓-chips (moduleId
  from PolariModule.source_ref) deep-link there. Live-verified:
  aquaponics 19cls/78rows/36routes, topology, techtree, waxprint.
Branches (stack tops): framework `dev-tt-10-module-map` ←
`dev-tt-9-cross-refs` ← `dev-tt-8-domain-trees`; angular
`dev-tt-10-drillin-ui` ← `dev-tt-9-zoomto` ← `dev-tt-8-domains-ui`.
selftest_techtree 50/50 in-container; builds green; pages 200.

## ⚡⚡⚡⚡⚡ 2026-07-18: tt-8 DOMAIN TREES — Dustin's revision, BUILT+LIVE
The single tech tree split into THREE DOMAIN TREES whose combination
is the OSEB (see the 2026-07-18 STATUS block atop
TECH_TREE_TOPOLOGY_PLAN.md for the full node list + numbers):
electronics 'Electronics / Microelectronics' (24 nodes; PVD is now
ITS OWN roadmap — OSPVD_ROADMAP.md — needing vacuum-pump +
piezoelectric-sputter prerequisites; expandable dielectrics →
Precision Laser Apparatus required by BOTH real-BLCNC and first-class
LASiS; CNT production via CO reduction; silicon refinement
grade-scale), raw-supply-chain 'Raw Supply Chain' (15 shells incl.
nanoparticle/CNT/p-doped/n-doped/silicon-grade/sol-gel/geopolymer/
wax/wax-nanocomposite supply streams), os-economy-politics 'Open
Source Economy & Politics' (4 shells: judicial, policy tracking,
business-logic models, micro-business tailoring). GET
/api/techtree/baseline + baseline strip on /tech-tree = the combined
OSEB (LIVE: 54.5%; electronics 51.7 / economy 75 / supply 36.7).
Legacy 'oseb' rows retired at boot (live: 78 rows removed, 14 hints
remapped; idempotent). 46/46 selftest in-container; deployed to
staging; pages 200. Branches: framework `dev-tt-8-domain-trees`,
angular `dev-tt-8-domains-ui` (both HEAD of their stacks).

## ⚡⚡⚡⚡ 2026-07-17: TOPOLOGY REVAMP + TECH TREE — tt-1..tt-7 ALL BUILT
Read the STATUS block atop **TECH_TREE_TOPOLOGY_PLAN.md** (branches,
defaults taken, live-verify detail) + memory [[topology-techtree-build]].
Short version:
- **tt-1** module graph: reverse edges/degrees, consumer/provider/
  hybrid/independent/data-only classification, STABLE transient/primary
  designation on ModuleDependencyEdge; PolariModule gained data_only +
  tech_node_ref; boundary_graph bidirectional; GET
  /api/topology/module-graph (26/26).
- **tt-2** renderer revamp: module CIRCLES packed in instance rects in
  HOST rects (toggle), deps nested in circles (depth 2), dashed =
  transient copy, connections = thin colored lines, dep edges anchor
  to circles. Pure geometry in topology-graph-layout.ts.
- **tt-3** techtree/ module: 5 data classes, DERIVED completion rollup
  (first-cut done-tests, evidence-bearing gaps), /api/techtree/* (37/37
  incl. tt-5/6 suites).
- **tt-4** /tech-tree page: segment-banded technology rects (blue/red/
  yellow/purple, only-if-populated, weight-sized, completion-filled),
  completion rings, dashed transient edges + dep chips, gaps table.
- **tt-5** OSEB seed: 19 nodes (13 domains + OS-PVD + BLCNC/PVD P1-P5
  per BLCNC_PVD_ROADMAP), theory wired to 14 genuinely-installed
  PolariModule rows; unbuilt 'blcnc'/'ospvd' refs stay honest gaps.
  **Baseline computes 62.7%.**
- **tt-6** RealArtifact/BusinessModelDefinition/BusinessOutcome/
  PolicyDefinition + honest examples filling all 4 segments on
  oseb/3d-printing (25% — unproven printer, unevidenced model+policy).
- **tt-7** Module Management embeds the circle/nesting renderer;
  /tech-tree gains per-org '+ new tree' creation.
**LIVE on staging NOW** (prf-backend+frontend rebuilt via `pol suite
build`/`up`, cold-seed + pol-proxy-restart gotchas both hit and
handled): /topology, /tech-tree, module-graph + techtree APIs all 200.
⚠️ REVIEW GATE: Dustin's browser pass pending (esp. tt-2 circles +
tt-4 bands). NOT merged to dev, NOT pushed — branch stacks in plan
STATUS block. NEXT after review: BLCNC_PVD_ROADMAP.md P1 (the blcnc
module — its TechNode + theory assignment already wait in the seed).

## ⚡⚡⚡ NEXT WORK (Dustin 2026-07-17): TOPOLOGY/TECH-TREE, then BLCNC+PVD
**This is the queued build, in Dustin's stated order — start here once the
push below lands.**
1. **Topology revamp + Tech Tree** — read `TECH_TREE_TOPOLOGY_PLAN.md`
   end-to-end. Phases tt-1..tt-7 (backend reverse-edge/transient computation →
   circle/nesting renderer → TechTree data model + completion rollup →
   4-segment render mode → seed the OSEB tree → real/business/politics
   objects → module-display convergence). Topology + tech tree are the
   cheaper build and come FIRST. Its §Open-questions list needs Dustin's
   answers (segment colors, 4-segment reading, completion gates) — ask
   or take the plan's defaults, which are marked.
2. **BLCNC + PVD proofing** — read `BLCNC_PVD_ROADMAP.md` (5 intertwined
   phases: ideal melt-voxel → theoretical chip via PVD+melt-voxel cycle →
   stochastic feasibility (locked by OS-PVD; 3.1 priors can start early) →
   BLCNC hardware in parallel → combined microfab device) + `BLCNC_PLAN.md`
   for the melt-voxel engine detail. Reuses the waxprint voxel/optimizer/
   no-code-command pattern (wp-1..8) — a `LaserOperation` twin of
   `WaxPrintOperation`.
3. **Why this matters (keep it front of mind):** BLCNC + PVD open sourcing
   is a CRITICAL part of the **Open Source Economic Baseline (OSEB)** — the
   overall end goal of the whole Polari project. The BLCNC/PVD phases are
   the worked example that flushes out the real OSEB tech tree (plan §B5):
   each phase lands as a TechNode whose theory segment is its sim modules
   and whose real segment is the Phase-4/5 CAD/hardware. Build tt-* so that
   seeding those nodes is the acceptance test.

**✅ REPO STATE: ALL GOOD — verified 2026-07-17 (late).** Every one of the 8
repos is on `dev`, working tree clean, and **0 ahead / 0 behind origin/dev**
— everything is pushed, all submodule pointers resolve on origin. Branch
hygiene done: all scratch/, rescue/, and merged feature branches deleted
after verifying their content landed on dev (each repo now carries only
`dev`, plus `main` where it existed). A fresh clone of origin/dev is the
complete, working state — the bring-up fixes above are all in it. Nothing
is waiting on a commit or push; next agent starts clean on the NEXT WORK
list at the top of this file.

## ⚡⚡ FLAWLESS BRING-UP — new workstream (2026-07-17). GOAL + open issues.
**Dustin's directive:** bringing up EVERY variation of the app must be
flawless across every route a person (or agent) might try, and it must be
*obvious* what the correct thing to do is. This is a first-class workstream,
not a cleanup afterthought.

**Canonical answer now documented (DONE 2026-07-17):** root **`README.md`**
(authoritative build/run/test guide) + root **`CLAUDE.md`** (short, auto-loaded
by instances). Both say: **use the `pol` CLI** (`polari-cli/`, installed via
`polari-cli/shells/install-cli.sh`) — do NOT hand-roll `docker compose`/`mvn`/`ng`.
Any new bring-up knowledge goes into these two files so it stays discoverable.

**The "all routes" mandate.** For every stack variation, the routes below must
each either JUST WORK or fail with a one-line pointer to the correct route:
- `pol` CLI (canonical): `pol security setup` → `pol suite up --env <tier>` /
  `pol node up --env dev|test|staging|prod|stateless`.
- Root shell launchers: `./start-staging.sh`, `./start-prod.sh`,
  `./setup-polari-security.sh`.
- Raw `docker compose -f …` (people will try this — it must work or refuse
  clearly).
- Native `npm run build` / `ng test` / `mvn` (fallback only; must not be a trap).
Acceptance: node {dev,test,staging,prod,stateless} + suite {dev,staging,prod} +
engines/twin/dask each come up clean via the documented route; test suites run;
**no route ever leaves root-owned artifacts on the host**; wrong routes give a
guided error, never a silent breakage.

**✅ ALL THREE OPEN ISSUES FIXED + LIVE-VERIFIED 2026-07-17 (this session,
per Dustin's directive "full build easy for anyone; keydb swapped in on the
political scorecard"). End-to-end proof: PSC test stack built + ran beside
the live suite (scratch `ports: !override []` overlay, port 8081 was taken
by prf-b-backend), `mvn clean verify` BUILD SUCCESS, 3/3 tests green,
`target/` fully HOST-owned. Detail:**
1. **psc-redis → KeyDB: DONE.** `redis/Dockerfile` + `Dockerfile.test` now
   build on `eqalpha/keydb` (same family as prf-keydb); the PSC confs carry
   over untouched (KeyDB reads the same ACL `user` directives — verified:
   authed PONG as psc-server-test, db-index write OK, unauthed refused).
   Bitnami startup scripts + empty ACL file deleted; redis/README rewritten.
   ⚠️ staging/prod compose `command:` was `redis-server --maxmemory…` — under
   the old swallowed-ENTRYPOINT it never ran; now fixed to
   `keydb-server /etc/keydb/keydb.conf --maxmemory…` so ACL auth survives the
   memory-cap override. Next staging up will rebuild psc-redis on KeyDB.
2. **Entrypoint mismatch: DONE.** Dockerfile + Dockerfile.suite use CMD (not
   ENTRYPOINT), so compose `command:` really runs. TRAP DEFUSED: three
   composes passed `command: ./startup_shell/startup_shell.sh` — a script
   that DOESN'T EXIST (silently swallowed before) — all now point at
   `dev_startup_shell.sh`. Host script exec bits fixed (`ug+x`; owner had
   no x-bit, which would have broken the UID-mapped container).
3. **Standalone test config: DONE.** test profile (both application-test.yml
   copies, now truly in sync — they had drifted) gains: stubbed
   `app.keycloak-admin.*` + lazy `jwk-set-uri` (no live Keycloak needed;
   env-overridable), and `app.datasource.minio.*` pointing at a NEW
   ephemeral `psc-minio-test` container in docker-compose-test.yml —
   required because DatabaseInitializer BLOCKS startup until MinIO responds
   (InitializationState.waitForDatabaseInitializations waits on the minio
   flag; a stub endpoint would hang forever, not fail).

**Already fixed + verified this session (DONE):**
- **Root-owned build artifacts.** `*-test` compose files bind-mount the repo and
  ran the build as **root**, leaving root-owned `target/` that then broke
  host-native `mvn` with "Permission denied". Fixed in
  `political-scorecard-backend/docker-compose-test.yml` with
  `user: "${UID:-1000}:${GID:-1000}"` (+ writable Maven `HOME`); verified the
  Maven build now writes `target/` (119 files incl. the file that used to fail)
  as **host-owned**, deletable without sudo. **✅ AUDIT DONE 2026-07-17:** every
  writable bind mount in every compose is covered — framework
  `docker-compose.test.yml` (test-results/) + angular `docker-compose.test.yml`
  and rf-node `docker-compose.fullstack-test.yml` (coverage/) now chown their
  output back to the host user via an EXIT trap (those tests must run as root:
  Chrome + image-owned /app); the PSC dev routes (suite/node/standalone
  backend = mvn, frontends = npm writing .angular/) now run as the host UID
  with in-container HOME. prf-backend dev was left as root deliberately — its
  persistent writes go to the prf_backend_data named volume, not the host.
  staging/prod composes have no writable source mounts (verified).
- **Frontends build clean:** psc-frontend + polari-platform-angular both
  `ng build` green (exit 0).
- Note: a full live suite was running during this work (15 containers, incl. a
  twin-B stack on 8081/8082/8083) — bring-up tests must route around live ports
  (verification used a scratch `ports: !override []` overlay) and never disturb
  a running stack.

## ⚡ XR ZONE CAPTURE — PARKED 2026-07-17 (Dustin moving topics). PICK-UP GUIDE.
Read AR_ZONE_CAPTURE_PLAN.md (status header carries the full pass
history) + memory [[ar-zone-capture]] (every gotcha). Where it stands:
- **WORKS ON DEVICE (Quest 2, built-in browser, hands + passthrough):**
  AR session grants, grayscale passthrough (normal for Quest 2), pinch
  point placement in the air, dot spheres + connecting lines + distance
  labels, HUD, wrist ring menu, 20 s auto-finalize countdown, commit
  reaches the backend (zone rows persist).
- **BACKEND: solid.** zones/ module selftest 45/45 + live on staging:
  planar (avg-height plane→floor extrusion) / hull (direct-3D) / prism
  models, calibration, rooms-vs-selections (rooms shared, selections
  tied to a simulation via simulation_ref), cube packing (lattice),
  room/site summaries (both volumes), zone→simulation bridge
  (SimSpaceDefinition '<zone>-space' + InitialConditionInterface
  'zone-ic--<zone>' carrying real constraints as setParams), AR
  Required Simulations (SimulationDefinition.xr_requirement; sample
  sim 'zone-block-filling' seeded), /display/zones + /zones-board.
- **JUST FIXED, NOT YET DEVICE-VERIFIED** (the last fix pass after
  Dustin's 2nd session found regressions): (1) hands-only point
  placement landed every dot at origin-on-floor — root cause: hand
  inputs have NO gripSpace so the grip Group never poses; placement
  now reads the index-finger-tip joint (hands) / target-ray pose
  (controllers). (2) Ring menu vanished when reaching toward it —
  root cause: ring parented to the hand WRIST JOINT, which three.js
  hides on any untracked frame and Quest drops the hand source on
  occlusion (reaching across causes exactly that); now sticky
  (fingertip-near OR 2 s grace). Also poke lateral tolerance widened.
  **NEXT HEADSET SESSION = verify these two fixes + first-ever look at
  the zone SHELL (cyan walls floor→plane, renders at commit) + pack
  outcome HUD line (silent zero-cube outcomes now always explained).**
- **KNOWN GAPS (not bugs):** hands can't cycle point kind (pad-click
  only — poke-able ring item would fix); Vive XR Elite has NO
  WebXR-AR browser path today (Vive Browser lacks immersive-ar, store
  Wolvic is Gecko, wolvic.com/dl has no Vive Chromium build — the
  in-app ar-unavailable-notice explains all this per-device);
  zone-block-filling sim is definition+ICs only (no SimState stepping
  yet — the packed lattice is its v1 output).
- **XR file reality check:** xr-zone-capture-runtime.ts/-page.ts are
  UNTRACKED (no git history); the recent-pass diffs on xr-wrist-ui.ts
  / xr-panel-system.ts are uncommitted. Poke seam (pokeFrom) and
  hand-wrist attach are opt-in — sim-space XR pages are untouched.
  Hands additions are ADDITIVE per Dustin: never override controller
  interactions.

## ⚡⚡ REVIEW GATE (2026-07-17): EVERYTHING below awaits Dustin's review.
ALL of tonight's work — authority capability, mock retirement, 9 no-code
module pages, epistemics routes + PSC pages (/survival, /court-cases,
/epistemics/*), governance CREATE UIs (/governance), staff-auth
browse/revoke, and the /worldview-scorer replacement (legacy scorer
DELETED) — is live on staging, UNCOMMITTED, and needs Dustin's browser
review + commit pass before further building. NEXT PLANNED WORK (do not
start before the review): **AR_ZONE_CAPTURE_PLAN.md** — capture 3D
zones in AR (point placement → real-distance estimation → ground area +
volume → 0.25 m cube packing with stacking → populate the zone in
AR/VR). Plan is written, phased arz-1..6, headset needed only for the
final stop line.

## ⚡ 2026-07-16/17 (latest): GROUP↔INSTANCE AUTHORITY + mock retirement + 9 no-code pages
Read **GROUP_AUTHORITY_PLAN.md** + memory [[group-authority]]. Built + LIVE
E2E-verified on staging, ALL UNCOMMITTED: (1) Polari scoring/group_authority
(grants/bindings/term-availability signals, 38/38 selftest, routes under
/api/scoring/authority/*); (2) PSC backend /api/authority/* (instance
registry, both-sides bindings, signal admission → term + provenance rows,
bearer-forwarding proxies) + /api/groups/directory + /api/terms/categories;
(3) PSC /authority hub UI + provenance badges; (4) ALL 7 PSC mock sites
retired to real data; (5) generic class-rows-table/api-json-panel display
components + seeded no-code pages: /display/{nutrition,vermicompost,tanks,
biomining,microalgae,wax-supply,supply-chain,plant-morphology,authority}.
Staging compose gotcha that BIT HARD: always `--env-file
.generated/.env.staging` AND `--no-deps` on any up -d --build; after a
backend recreate, `docker restart pol-proxy` (stale nginx upstream →
502). Keycloak realms differ (Political-Scorecard vs Polari) →
cross-side identity is payload-unverified until realms unify (Dustin
decision).

SECOND PASS same night (Dustin: "keep going on psc frontend"): the
epistemics stack is SURFACED — scoring/epistemics_api.py (29 GET routes
over the unrouted 2026-07-16 modules, live-verified), PSC court-case
proxy /api/court-cases, and PSC pages /survival + /court-cases +
/epistemics{,/proofs,/term-competition,/credibility,/sources,
/legislation} — all 200 on staging. Memory [[group-authority]] carries
the full detail.

THIRD PASS same night: mechanism-C CREATE UIs (/governance page +
/api/governance vote/ballot/edge creation; staff-auth browse/revoke +
admin list on /policy-votes) and the LEGACY CLIENT-SIDE WORLDVIEW SCORER
IS RETIRED — deleted outright, replaced by /worldview-scorer (front and
center on the home page): group-hosted concept sets + elected weights
read from ScoreGroup rows, per-concept readings + server-side
/groups/{name}/aggregate from Polari's real engine, what-if reweighting
clearly labeled local preview, group-asserted-term provenance inline.
All live-verified. Memory [[group-authority]] third-pass section.

## ⚡ POSTURE CHANGE (2026-07-16, later): NO aggressive building.
Dustin is doing a debugging + review pass. **FRONTEND_WORK_MAP.md** (suite
root) maps every missing/broken/mock-backed frontend surface across all
workstreams — work from that, at Dustin's direction. Correction: the
2026-07-09 claim below that aqp-3/7/8 have no frontend is STALE — aqp-3
(water-slice viz) and aqp-8 (plant-skeleton viz) exist and were verified;
only aqp-7 vermicompost has no UI.

## ⚡ READ FIRST
Two massive workstreams built TODAY, ALL UNCOMMITTED (55 files, framework
branch lineage dev-ncg-0-nocode-matrix → dev-ncg-5-breadboard off Dustin's
dev checkpoint), all selftest-green on 3 machines + live on staging:

1. **ncg-0..7 (no-code generalization)** — read NOCODE_GENERALIZATION_PLAN.md
   PICK UP HERE. graph_builder/graph_compilers seam; judicial CourtCase LIVE;
   hwdigital→iCE40 bitstreams; circuits/breadboards as rows (2.6123 mA
   regression); level bridge LIVE; NoCodeTestCase packs; module gating +
   PolariModule objects; 5-agent adversarial review, ~35 fixes pinned.
2. **DMV cost-of-living + scorecard epistemics** — read
   political-scorecard-node/DMV_COST_OF_LIVING_DATA_PLAN.md +
   DEMOCRATIC_SCORECARD_REVAMP_PLAN.md appendices (everything after the
   2026-07-16 sections). Source catalogs (verified URLs) + col-1/2 seeded
   LIVE; GovSource + 4 legal source types; cross-validation trust stack;
   profiler drift/discovery; policy drafts; venue patterns; legislation
   tracking; term competition; democratic proofs (18-pattern manipulation
   catalog); credibility bases + relevance voting.

Memory: [[nocode-generalization]] + [[dmv-cost-of-living]] carry every
gotcha. Matrix: format category = 6 blocking rows, nocode = 51.

**WAITING ON DUSTIN**: review/commit pass; API keys (POLARI_CENSUS_API_KEY,
POLARI_CONGRESS_API_KEY, POLARI_VA_LIS_API_KEY) for live pulls (col-3);
acct-0..3 review; manual browser pass; SEED_TERM_PROOFS demo-content pass;
model gaps (ContextualizedValue MOE fields, definition versioning, rollup
lineage, usage records). Pre-existing red: aquaponics.system 12/13 (NOT
from today's work). DO NOT COMMIT WITHOUT DUSTIN'S EXPLICIT ASK.

---

# Next-agent handoff — 2026-07-09 (AQUAPONICS PHASE 2 BUILT — tail below)

## ⚡ UPDATE 2026-07-09 (later session): aqp-3 / aqp-7 / aqp-8 ALL BUILT
All three Phase-2 phases are BUILT, committed locally, and selftest-green
(133 aquaponics checks). Branch stack in polari-framework:
`dev-aqp-3-hydraulics` → `dev-aqp-7-vermicompost` → `dev-aqp-8-growth`
(HEAD `dev-aqp-8-growth` = all three; commits 3780e28 / 48e5a20 /
054f401). rf-node worker twin on `dev-aqp-3-hydraulics` (3c09349).
Full per-phase detail + gotchas in [[aquaponics-module]] memory.

**✅ DEPLOYED + LIVE-VERIFIED this session** on
docker-compose.staging-nip.yml (prf-backend rebuilt, cold-seeded, all 8
aquaponics selftests green in-container). Live results:
- aqp-3 `GET /api/aquaponics/pots/demo-herb-pot/drains?soil=coir-perlite-mix`
  → `fidelity: fem`, drains: true, 0.044 mL/s, 8192-element mesh;
  head-field → 4225-node head field. **scikit-fem is pure-python and
  RIDES THE ALPINE BACKEND IMAGE** (as fem_engine.py's own comment
  says) — the FEM path runs IN-BACKEND, the msci-engines worker rebuild
  is NOT needed for aqp-3. (The worker `/darcy/*` routes + `darcy_solver.py`
  twin still exist as the delegation fallback; harmless, already built.)
- aqp-7 compare-modes recommends `direct`, periodic pulse peak 5.0 mg/L
  N; simulate persists the snapshot; the `nutrient-enrichment-efficiency`
  ScoreConcept resolves live.
- aqp-8 grow survives healthy (3 parts, top interaction leaf→root);
  under starved nitrate the root goes `condition: failed, limiting:
  nitrate-n, survived: false`.

**GPT-4 TAKEOVER — remaining tail (in priority order):**
1. **Optional: aqp-3 sim-as-data wrappers** (plan §aqp-3 item 4 —
   PotHydraulicsSimState + SimulationDefinition + coupling). I built the
   engine + analysis + API + scoring; deferred the runnable-sim-object
   wrappers (not in acceptance, add risk). Same for aqp-7 CompostLoopState
   / aqp-8 PlantLifetimeState if a runnable timeline object is wanted.
3. **Frontend surfaces** for the three phases (none built).
4. **Dustin browser review** + push to GitHub (repos PUBLIC — push
   before any `pol deploy run`).

Verify commands are at the bottom of this file. Nothing pushed to
GitHub (repos PUBLIC).

---

Dustin moved back to the aquaponics simulation. Phase-2 plan (now
executed): **`AQUAPONICS_PHASE2_PLAN.md`** at the suite root — three
GPT-4-executable phases (aqp-3 FEM hydraulics → aqp-7 worm-compost
enrichment loop → aqp-8 per-part plant growth/failure), ordered
HARDEST→EASIEST. Background: [[aquaponics-module]] +
`AQUAPONICS_MODULE_PLAN.md`.

## The three phases (all planned in AQUAPONICS_PHASE2_PLAN.md)
1. **aqp-3 — FEM water-flow engine** (hardest). New scikit-fem scalar
   Darcy solver (twin of `materialsScience/engines/fem_engine.py`
   `solve_steady_conduction`), runs on the msci-engines worker via the
   topology-routed remote seam. Answers "does the pot drain by gravity,
   at what rate, moisture field?" — replaces aqp-1's L0 permeability
   priors. Fidelity knob: reduced reservoir model (in-backend, always
   answers) vs FEM (worker). This is the long-standing aqp-3 phase.
2. **aqp-7 — worm-compost (vermicompost) nutrient-enrichment loop**
   (medium). Box-model bin that enriches passing aquaponic water; TWO
   modes both selectable — direct-in-loop (continuous) and controlled
   periodic flow-through (pulses + recharge). Abstract estimate OK;
   flag rate constants as literature-range priors. Couples enriched
   water into the pot's nutrient input; rankable via the scoring bridge.
3. **aqp-8 — per-part plant growth / growth-failure** (easiest; extends
   aqp-4). Makes the existing PlantPart objects GROW (logistic vs
   limiting resource) or FAIL (limiting factor named); volume-per-part
   interaction estimation (leaf↔root↔fruit coupling by volume+
   condition) as a small tunable coefficient table. Realized per-part
   volumes feed aqp-6 env-impact scoring.

## aqp status recap
aqp-1/2/4/5/6 BUILT + committed (5 stacked branches off the scoring
stack; 76 module selftest checks green; NOT yet deployed to staging).
aqp-3 was always "the one remaining phase". aqp-7/aqp-8 are NEW
(2026-07-09). Module lives at
`polari-rf-node/polari-framework/aquaponics/`; conventions + the exact
polariServer wiring points are in AQUAPONICS_PHASE2_PLAN.md §0.

## Live-verify commands for the aqp-3/7/8 endpoints
After `export LOCAL_IP=192.168.0.210` + `docker compose -f
docker-compose.staging-nip.yml up -d --build prf-backend` and the cold
seed finishes (backend serves :3000), from the suite root:

```
# in-container selftests (all 8 suites; 133 checks)
for t in pot growth_media plant atmosphere system hydraulics \
         vermicompost plant_growth; do \
  docker exec prf-backend python3 -m aquaponics.selftest_$t | tail -1; done

# aqp-3 hydraulics (reservoir until the worker carries skfem)
docker exec prf-backend python3 -c "import urllib.request as u; \
print(u.urlopen('http://localhost:3000/api/aquaponics/pots/demo-herb-pot/drains?soil=coir-perlite-mix').read())"
# aqp-7 vermicompost
docker exec prf-backend python3 -c "import urllib.request as u; \
print(u.urlopen('http://localhost:3000/api/aquaponics/compost-loops/basil-loop-direct/compare-modes').read())"
# aqp-8 growth
docker exec prf-backend python3 -c "import json,urllib.request as u; \
r=u.Request('http://localhost:3000/api/aquaponics/plants/sweet-basil/grow',\
data=json.dumps({'days':120}).encode(),headers={'Content-Type':'application/json'}); \
print(u.urlopen(r).read()[:400])"
```
Public proxy equivalent: `https://api.prf.192.168.0.210.nip.io/api/aquaponics/...`

## Deploy discipline (bit me repeatedly)
- `export LOCAL_IP=192.168.0.210` before ANY docker compose on
  docker-compose.staging-nip.yml (else pol-file-store crash-loops).
- prf-backend serves :3000 only after cold-seed (minutes; healthcheck
  flaps). Selftests run in-container: `pol modules selftest aquaponics`.
- API-created treeObject rows need explicit
  `manager.db.saveInstanceInDB(row)`.
- Angular templates: literal `@` breaks builds — use `&#64;`.
- falcon POST bodies read `request.bounded_stream`.

## Just-completed (last session): TOPOLOGY ORCHESTRATION — DONE
top-1..top-8 all built + live-verified (see [[topology-orchestration]]):
topology-as-data core (`topology/` module, /api/topology/*), `pol
topology` CLI + portable packages (parity round-trip), multi-node swarm
(**lightweight joined as a worker; the polari-engines stack now RUNS
THERE**), Topology tab (/topology, drag-drop modules — graph
autoplacement compacted + fit-to-view per Dustin), provider routing,
reallocation suggestions. **RELEVANT TO aqp-3**: the engines worker is
reachable via the topology-routed remote seam with no MSCI_ENGINES_URL
set — aqp-3's Darcy solver goes on that worker. ⚠️ Dustin's browser
review of the Topology tab is still pending.

## NOT pushed to GitHub
All local branch stacks (repos PUBLIC). Push before any `pol deploy
run`. Topology branches: suite/cli `dev-top-4-multinode`, rf-node
`dev-topology-orchestration`, framework `dev-top-1-topology`, angular
`dev-top-5-topology-tab`.

## Other parked work (unchanged)
scr-7 scorecard↔Polari wiring, scr-9..14; scoring/materials as before.
