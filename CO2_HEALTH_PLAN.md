# CLIMATE CHANGE & ATMOSPHERE — a discipline APP, its objects,
# and the CO2-and-human-health analysis on top of them
# (executable handoff: written for ANY fresh agent)

> **Dustin 2026-08-02**: "look into implementing the capability to
> ingest xpt file format data from api's. Particularly Bicarbonate
> data per year from the CDC we need to be able to ingest and turn
> into graphs. While we are at it, we should probably look into
> other data like carbon dioxide levels indoors increasing over
> time, and carbon dioxide in ppm and partial pressure in the means
> it affects the lungs. And then also velocity and acceleration of
> co2 over time. And also rates of decline in carbon sinks. We will
> want to make an overall page for analysis of co2 and the way it
> is affecting human health. We should also indicate different
> thresholds on that page for human health impacts. Like when 800
> or 1000 ppm outdoors will be reached, or when it became the norm
> for 1000 ppm inside to be the norm from ventilation, and when we
> will hit more health thresholds. A page pulling from official
> sources to analyze this."
>
> **Follow-up, same day**: "we should also implement tracking of
> different known health thresholds of co2 and derive the times we
> would hit those thresholds for both indoor and outdoor levels
> based on analyzing trends in influence on co2 levels indoor and
> outdoor together with co2 velocity and acceleration."
>
> **Second follow-up, same day**: "we should probably actually
> make a Climate Change & Atmosphere App, and we will want to
> turn all of this data with it's sources into real polari objects
> we can use down the road with simulations."
>
> Status: PLAN. Nothing below is built.
> Style: decisions pre-made; every phase names the file to COPY
> FROM; acceptance = literal selftest lines.

## §-1 THE SHAPE OF THE WORK (read this before §0)

The second follow-up changes what is being built. This is **not a
page with charts on it**. It is:

1. **A DISCIPLINE APP** — "Climate Change & Atmosphere", a
   `PolariAppDefinition` row beside the eight the nav revamp
   seeded, with its own top + side menus, personas, and module
   gating. The page is one item in its nav, not the deliverable.
2. **AN OBJECT MODEL** — every measurement series, every source,
   every threshold, every room archetype and every sink figure is
   a **treeObject class with rows**, which means: a CRUDE
   endpoint, a place in the object tree, no-code editability, and
   — the point — **bindability by the simulation framework
   later**. Nothing here may live only inside an engine's return
   payload.
3. **THE ANALYSIS** — the CO2/health study, built ON those
   objects, exactly the way the motors views are built on motor
   rows.

The test for every phase below: *could a simulation defined
tomorrow bind this without a code change?* If the answer is no,
the data is in the wrong place. Concretely, that means each
series is rows the `SimulationDefinition` / `SimSpaceBinding`
machinery can reference, and the engines are pure functions OVER
those rows (the M0/M1/M2 discipline, unchanged).

**The first downstream consumer already exists**: aquaponics'
`AtmosphereDefinition.outside_co2_ppm` is a seeded constant
(420.0) that should be able to READ the live outdoor series
instead. Wiring that is the proof the objects are real — a
greenhouse simulation whose ambient CO2 tracks the actual record,
because both are the same rows.

## ⚠ THE RULE THAT OVERRIDES EVERYTHING ELSE HERE

**Every number in this plan is a PLACEHOLDER PRIOR.** The agent
writing this had no live data. Thresholds, growth rates, sink
figures, NHANES variable names — all of them are what a model
remembered, which is exactly the kind of number this project
refuses to ship. THE INGEST IS WHAT MAKES THEM REAL.

So: seed every one as `is_prior=True` with `replaces_with` naming
the fetch that retires it, and make the engines **refuse to
project from an unfetched series** rather than quietly using the
placeholder. A CO2-and-health page that is confidently wrong is
worse than one that says "not fetched yet" — this is health
information, and the whole point of pulling from official sources
is that the sources, not the model, are the authority.

Corollary: **verify every URL and variable name live before
seeding it.** Federal data portals move; NHANES file names are
per-cycle; NOAA renames product files. A citation row pointing at
a 404 is a lie with a footnote.

## THE DO/DON'T BOX (inherited — violations cost a deploy)

- DO run suites as: `cd polari-rf-node/polari-framework &&
  PYTHONPATH=modules:. python3 -m co2health.selftest_co2`
  (files named `selftest_*.py` are auto-discovered by
  `pol modules selftest`).
- DO register any NEW treeObject class in polariServer THREE
  places: the module's try-import block, its stub tuple, and the
  definition-table class list — or its seeds silently never land.
- DO seed ONLY via `composition.seed_upsert.upsert_seed_pairs`
  chains (legacy insert-only passes never converge changed rows).
- DON'T re-import module-level names inside `_seedSimSpace3D` —
  a local `from x import Name` makes it function-local and
  crashes the WHOLE admission worker (hit three times now).
- DO match rows by `getattr(row, 'name', '')` when reading
  manager.objectTables — LIVE tables key by id, fixtures by name.
- DO add the new module to the module registry + ModuleAssignment
  rows so `pol topology modules-env` derives POLARI_MODULES
  (never `--env-add`).
- Deploy ritual: `pol node build backend --env staging` then
  `docker service update --force --image prf-backend:staging
  polari-node_backend`; admission ~8 min of honest 503s — poll,
  don't panic; NEVER docker cp+restart. (A docker.io 502 can fail
  the BUILD — check the exit code before you roll, or you will
  restart the old image and wonder why nothing changed.)
- Commit innermost-first: polari-framework → polari-rf-node →
  polari-suite (angular beside framework), one phase per commit
  chain, all on `dev`.
- Every fact stated twice gets a two-modules-agree guard test.

## §0 What EXISTS to reuse (extend, do not invent)

| Piece | Where | Use it for |
|---|---|---|
| `GovSource` + `SourceRetrieval` | `modules/dmvdata/gov_sources.py` | THE official-source registry: acronym, agency, official website, data portal, `api_key_env` (a POINTER, never a literal key — repos are public), and a retrieval row recording WHEN data was copied and THROUGH WHOM. Every CO2 source is a GovSource row. |
| `census_pull.py` | `modules/dmvdata/census_pull.py` | The INGEST SHAPE to copy: build url → fetch (injectable fetcher) → parse → `ingest_*` writes rows + a SourceRetrieval. Its `_redact(url)` keeps keys out of provenance strings. |
| `environment_gas_exchange` | `modules/aquaponics/atmosphere_analysis.py` | 🔑 **THE INDOOR EQUATION ALREADY EXISTS.** It solves steady-state indoor CO2 under ventilation for a crop that DEPLETES it: `steady = outside_ppm − demand/ventilation_capacity`. A room full of people is the SAME equation with the sign flipped: `steady = outside_ppm + emission/ventilation_capacity`. Do NOT write a second CO2 mass balance — generalize that one (a signed source term) and let both callers use it. |
| `AtmosphereDefinition` | `modules/aquaponics/atmosphere_basis.py` | Already carries `co2_ppm`, `outside_co2_ppm`, `air_exchange_per_hour`, volume. An occupied room is an AtmosphereDefinition row with an occupancy term. |
| `CO2_MG_PER_M3_PER_PPM = 1.8` | same file | The ppm↔mass conversion, stated once. Import it; do not restate it. |
| `FieldThresholdBand` | `modules/magnetics/field_view_basis.py` | The BAND-AS-DATA precedent (min, max, unit, color, label). Health thresholds are bands over ppm. |
| `DigitizedDataset` | `modules/pspp/digitized_datasets.py` | A digitized source series WITH provenance and a `status` the engines refuse to read when it is `provisional-low-confidence`. The same refusal discipline applies here. |
| `EvidenceMethod` / `PropertyClaim` | materials science module | Per-value evidence grading — a threshold from a controlled human-exposure study is not the same grade as one from a ventilation standard, and the page must say so. |
| named-prior + `replaces_with` pattern | `motors/m1_positioning.py`, `motors/m2_lift.py` | The requirement-row shape: value, unit, basis, and THE MEASUREMENT THAT RETIRES IT. Copy it verbatim for thresholds and for room parameters. |
| `headline` renderer | `angular .../clock-views.component.ts` (m2-8) | A payload may offer `[{label, value, note, verdict}]` and it renders as a table with ok/warn/bad chips. Every engine here should offer one. |
| DisplayDefinition / GraphDefinition / TableDefinition | core no-code | The PAGE is rows, not a component — same promise the discipline views keep. |

## §1 THE OBJECT MODEL (new module `modules/climate/`)

Module name `climate` (not `co2health`): the app is Climate
Change & Atmosphere, and CO2-and-health is its first study, not
its whole subject. Every class below is a `treeObject` with the
THREE registrations, seeded through `upsert_seed_pairs`.

| Class | Holds | Why it is an OBJECT, not a payload field |
|---|---|---|
| `AtmosphericSeriesDefinition` | one measured series: what, where, unit, cadence, source_ref, first/last year, `status` | a simulation binds a SERIES, not a chart |
| `AtmosphericObservation` | one (series, time, value, uncertainty, revision) point | the actual data; queryable, re-ingestible, revisable |
| `AtmosphericTrendFit` | a fit over a series: window, velocity, acceleration, residual, method | a fit is a claim with a method — it gets a row so a later fit can disagree with it |
| `CO2HealthThreshold` | ppm, effect, population, exposure, evidence_grade, source_ref | the page's spine (§5) |
| `IndoorSpaceProfile` | volume, occupancy, activity, ACH — a room archetype | the coupling's inputs, and directly bindable by an indoor-air simulation |
| `CarbonSinkSeries` | land/ocean sink capacity + fraction over time | §8 |
| `PopulationBiomarkerSeries` | NHANES-style biomarker by cycle (bicarbonate first) | the population-measurement side, from XPT |
| `ExposureProjection` | a computed crossing: threshold × space × year band × method | ⚠ **stored, not just returned** — so a projection can be compared against the next one after new data lands, which is how the page shows its own answers moving |

Reuse rather than restate: `GovSource`/`SourceRetrieval` for
provenance (§0), `AtmosphereDefinition` for the physical room
(an `IndoorSpaceProfile` REFERENCES one rather than duplicating
volume/ACH), `EvidenceMethod` for grading.

**Files** (one per concern, `modules/climate/`)

- `climate_basis.py` — the classes above
- `climate_sources.py` — GovSource rows + endpoint definitions
- `xpt_reader.py` — THE XPT CAPABILITY (§2)
- `series_ingest.py` — fetch → parse → rows + SourceRetrieval
- `co2_trend.py` — velocity, acceleration, fit + projection
- `co2_thresholds.py` — health threshold rows
- `co2_indoor.py` — the coupled indoor model (reuses aqp-5)
- `co2_physiology.py` — ppm → partial pressure → the gradient
- `carbon_sinks.py` — sink capacity + its decline rate
- `biomarker_link.py` — NHANES series + the correlation-as-a-question
- `climate_views.py` — the study's sections as rows
- `climate_app.py` — the APP row + nav (§9b)
- `climate_api.py` — `/api/climate/*`
- `selftest_climate.py`

## §2 xpt-1 — THE XPT INGEST CAPABILITY (do this first)

**What XPT is**: SAS Transport Format (XPORT), the format CDC
publishes NHANES lab files in. It is a fixed-record binary format
(80-byte header records, member/namestr/observation blocks). It is
NOT CSV with a different extension.

**DECISION (pre-made): read it with pandas, guarded.**
`pandas.read_sas(path_or_buffer, format='xport')` is in the pandas
already vendored for the analysis modules. Wrap it so that:
- the reader is a THIN function with an injectable fetcher (copy
  `census_pull._default_fetcher`), so tests never hit the network;
- an unreadable/short file REFUSES with what it saw (first bytes,
  length) instead of raising a pandas traceback into an API;
- **the reader never guesses a variable's meaning.** NHANES column
  names are opaque (`LBXSC3SI`), so the mapping from column → what
  it measures → its unit lives in a SEEDED ROW, and a column with
  no row is reported as an unmapped column, not silently dropped.

Acceptance (selftest, no network):
- a hand-built minimal XPT fixture round-trips to rows;
- a truncated file REFUSES and names the byte count;
- an unmapped column appears in `unmappedColumns`, never dropped;
- the retrieval writes ONE `SourceRetrieval` row with a redacted
  URL and the row count.

**Generality**: this is `xpt_reader`, not `nhanes_reader`. Any
agency publishing XPORT (CDC, NCHS, some USDA series) rides it.

## §3 co2-0 — the sources, as rows (verify every URL live)

Seed one `GovSource` per source. Candidates (VERIFY BEFORE
SEEDING — the agent that wrote this could not):
- **NOAA GML** — the outdoor CO2 record: Mauna Loa and the
  globally-averaged marine-surface series, plus **the published
  annual GROWTH RATE series**, which is the velocity term already
  computed by the source. Prefer the source's own growth rate over
  differencing the levels, and when both exist, report both and
  make disagreement a finding (the bench-campaign discipline).
- **NASA / GISS** — cross-check series.
- **Global Carbon Project (Global Carbon Budget)** — land and
  ocean SINK time series; the sink-decline question is theirs.
- **CDC / NCHS NHANES** — the XPT lab files; serum bicarbonate
  lives in the standard biochemistry profile (per-cycle file
  names, e.g. `BIOPRO_*.XPT`; the bicarbonate column is believed
  to be `LBXSC3SI`, mmol/L — CONFIRM against the cycle's own
  codebook, which is itself a citable page).
- **ASHRAE / OSHA / NIOSH** — the standards behind the threshold
  rows (standards are not health studies; §5 grades them apart).

Each row: acronym, full name, agency, official website, data
portal, whether a key is needed and WHICH ENV KNOB supplies it.
Never a literal key.

## §4 co2-2 — series + velocity + acceleration

`co2_series.py` holds `CO2MeasurementSeries` rows (series name,
source_ref, what it measures, unit, cadence, first/last year,
status) and the ingested points. `co2_trend.py` derives:

- **velocity** dC/dt in ppm/yr — from the source's own growth-rate
  series where published, else a centred difference of the levels;
- **acceleration** d²C/dt² in ppm/yr² — fitted, not eyeballed, over
  a stated window, WITH the fit's uncertainty;
- a **quadratic projection** C(t) = C₀ + v·t + ½a·t², and beside
  it a **linear** one, because the difference between them IS the
  finding: acceleration is what moves the crossing dates earlier,
  and showing both makes that visible rather than asserted.

Refusals: fewer than N years of data → refuse to fit acceleration
and say so. A projection beyond a stated horizon → refuse or
carry a widening band; do not print a year for 2200 as if it were
a measurement.

## §5 co2-3 — HEALTH THRESHOLDS AS ROWS

`CO2HealthThreshold` rows (NEW class — the three-registration
rule applies). Fields, copying the requirement-row pattern:

    name, display_name, ppm, unit ('ppm'),
    effect            — what happens to a person at this level
    population        — general / occupational / sensitive
    exposure          — acute / hours / chronic
    evidence_grade    — 'controlled-human-study' |
                        'observational' | 'standard-or-guideline' |
                        'expert-judgement'
    source_ref        — the GovSource / citation row
    is_prior, replaces_with, notes

**The grading is the honesty.** A ventilation standard's 1000 ppm
is NOT a health threshold — it is an indicator chosen so that
odour and stuffiness stay acceptable, and rows must say that. An
occupational limit (thousands of ppm) is set for healthy adults
over a work shift, not for children in a classroom all year. A
cognitive-performance study result is a study result, with its
n and its contested replication. **If the page blurs these, it
becomes exactly the confident-and-wrong artifact the plan's top
rule forbids.**

Candidate rows to seed (ALL placeholders — fetch and confirm):
outdoor baseline today; the ventilation-indicator level; reported
cognitive-decrement levels; occupational time-weighted limits;
short-term exposure limits; the level at which acid-base
compensation (the bicarbonate link) is measurable in chronic
exposure; and the immediately-dangerous level. Also seed the
NEGATIVE row: the level below which there is no evidence of
effect — pages that only list harms imply harm everywhere.

## §6 co2-4 — PARTIAL PRESSURE AND WHY IT MATTERS

`co2_physiology.py`. ppm is a mixing ratio; **what acts on the
lung is partial pressure**: pCO2 = ppm × 1e-6 × ambient pressure.
Report it in both kPa and mmHg, and carry the altitude/pressure
row that changes it (the same ppm is a smaller pCO2 in Denver).

Then the honest framing, which the page must lead with:

> Ambient pCO2 even indoors is a fraction of a mmHg against an
> alveolar pCO2 near 40 mmHg. The mechanism is NOT that ambient
> CO2 "fills the lungs" — it is that the gradient the body
> eliminates CO2 down is slightly reduced, and that the
> compensations (ventilation rate, blood pH, renal bicarbonate
> handling) are measurable before anyone feels anything.

That is why the **NHANES bicarbonate series is the interesting
dataset**: it is the population-scale, officially-collected
measurement of the compensation side. Whether it trends with the
CO2 record is a QUESTION THE PAGE ASKS AND ANSWERS WITH A
CORRELATION AND ITS CONFOUNDERS — never a claim seeded in
advance. Confounders to name explicitly: altitude, kidney
disease, diet, age structure, assay changes between cycles, and
the fact that a population mean moving within the reference
interval is not a diagnosis.

## §7 co2-5 — THE COUPLED CROSSING PROJECTION (the heart)

This is the follow-up ask, and it is the piece that makes the page
more than a chart.

**The coupling**: indoor CO2 is not an independent series. A room
sits at

    indoor_ppm = outdoor_ppm + occupancy_emission / ventilation

so **every threshold indoors moves down the calendar as outdoor
rises**, one-for-one, on top of whatever the room's own ventilation
already contributes. Reuse the aqp-5 steady-state solver with a
signed source term (§0) — one equation, two callers, guard-tested
that the greenhouse and the classroom get the same answer for the
same inputs.

Room archetypes as ROWS (`IndoorSpaceProfile`), each a named
prior with `replaces_with` = "measure it with a CO2 meter":
bedroom overnight (closed door — the worst common case), a
classroom at occupancy, an open-plan office, a car cabin on
recirculate, a well-ventilated public building. Per row: volume,
occupancy, activity level (CO2 emission per person, itself a
cited prior), and air changes per hour.

**The projection**, per (threshold × space):
1. project outdoor with the quadratic fit (§4);
2. add the room's steady-state offset;
3. solve for the YEAR the sum crosses the threshold;
4. report `already-crossed` (with the year it happened) when it
   is in the past — for several indoor cases this will be the
   answer, and that is the finding Dustin is asking for;
5. state a band, not a point: the crossing year from the linear
   fit and from the quadratic fit bracket it, and the
   acceleration uncertainty widens it. **One number with no band
   is the failure mode here.**
6. name the knob that moves it: ventilation. A crossing that
   arrives in 2050 at 0.5 ACH and never at 3 ACH is the actionable
   result, and the page should say which rooms are already past
   which lines TODAY at their stated ventilation.

Acceptance (selftest):
- outdoor crossing years are monotone in the threshold;
- the SAME threshold always crosses EARLIER indoors than
  outdoors, for every space row (if it ever does not, the
  coupling has a sign error);
- doubling ACH moves an indoor crossing later, and the delta is
  reported as the ventilation knob;
- a threshold already crossed indoors returns `already-crossed`
  with a past year, never a negative "years away";
- the quadratic and linear projections bracket the reported band;
- with the series unfetched, EVERY projection REFUSES by name.

## §8 co2-6 — CARBON SINKS

`carbon_sinks.py`: land and ocean sink series as rows, the sink
FRACTION (sink / emissions) and its trend, and the honest
statement of what a declining sink fraction does to §4's
acceleration term — it is a reason the quadratic fit's `a` is not
a constant of nature. Do NOT model the carbon cycle here; cite the
budget and carry its uncertainty.

## §9a co2-7 — THE STUDY PAGE

`/co2/health` (a DisplayDefinition + sections, rows not a
component). Section order is an argument, so it is fixed:

1. **What is measured** — the outdoor record, its source, its
   velocity and acceleration, with the linear/quadratic pair.
2. **What it becomes indoors** — the coupling, per room archetype,
   at today's outdoor level.
3. **The thresholds** — the table, GRADED, with the negative row.
4. **Partial pressure and the mechanism** — §6's framing, so a
   reader knows what is and is not being claimed.
5. **THE CROSSINGS** — the §7 table: threshold × space × year (or
   `already-crossed`), banded, with the ventilation knob beside
   each.
6. **The population measurement** — NHANES bicarbonate, its trend,
   its confounders, and the correlation stated as a question.
7. **Sinks** — why the acceleration term may itself move.
8. **What would change these answers** — every `replaces_with` on
   the page, collected: the measurements that would retire the
   priors. (This section is the reason the page is trustworthy.)

Every section names its source rows and every number carries its
provenance chip, the same contract the discipline views keep.

## §9b co2-8 — THE APP (Climate Change & Atmosphere)

One `PolariAppDefinition` row via `polariapps/apps_seed.py`'s
`_app(...)`, copying the shape of `app-magnetics`:

- name `app-climate`, title **Climate Change & Atmosphere**
- discipline `climate` (a NEW discipline string — check the
  frontend's discipline handling has no hardcoded list; if it
  does, that list is the thing to generalize)
- personas: `climate-scientist`, `public-health-analyst` (new
  personas; the persona index is derived, so adding them is a
  row, not a code change)
- modules: `climate`, and the ones its studies read —
  `aquaponics` (the atmosphere/ventilation engine), `scoring` or
  `dmvdata` if the source registry lives there, `simulations`
- nav groups (top + side, per the nav-1 rules):
  - **Studies** — CO2 & human health (the §9a page), the crossing
    table, partial pressure & the mechanism, carbon sinks
  - **Data** — series catalog, sources & retrievals, the raw
    observation tables (CRUDE pages, which exist for free once
    the classes are registered — that is the payoff of §1)
  - **Tree** — the tech-tree node(s) this app owns
- every nav item declares `requires_module`, so an absent module
  renders the bring-up affordance instead of vanishing (the
  nav-2 tri-state; and REMEMBER the apps selftest PINS the
  absent-item count — update it deliberately, as m1-8/m2-8 did).

Also: a `TechNode` for atmospheric measurement instruments
(CO2 meter → NDIR sensor → calibration gas) so the bench-campaign
idiom applies here too — "measure your own room" is the cheapest
retirement of a prior on this whole page, and it belongs on a
tree like every other capability.

## §10 Honesty ledger (day one)

- Every number here is a placeholder until fetched (top rule).
- Standards ≠ health studies ≠ occupational limits: graded, never
  averaged together.
- There is **no long official INDOOR record** the way there is for
  outdoor. Indoor is MODELLED from outdoor + ventilation, with
  measured studies as validation points, and the page must not
  present a modelled indoor series as a measured one.
- The bicarbonate↔CO2 link is a QUESTION with named confounders,
  not a finding, until the correlation is run on fetched data.
- Projections carry bands and a horizon; a crossing year is a
  consequence of a fit, not a prediction of the world.
- The mechanism claim is bounded: ambient pCO2 shifts the
  elimination gradient; it does not "fill the lungs".

## §11 Order and gate

**co2-A (objects first)** — §1's classes + registrations + empty
seeds. Nothing reads them yet; this is the spine.
Then: xpt-1 → co2-0 → co2-2 → (co2-3 ∥ co2-4) → co2-5 → co2-6 →
co2-7 → co2-8 (the app) → **co2-9 (the simulation binding)**.

**co2-9** is the phase that proves §-1's claim: point
aquaponics' `AtmosphereDefinition.outside_co2_ppm` at the live
series (as an optional reference — the seeded constant stays the
fallback and the row says which it used), and show a greenhouse
run whose ambient CO2 comes from the actual record. Small phase,
large meaning: it is the difference between a page and an object
model.

Gate to call this built: the XPT reader round-trips a real
fetched NHANES file; the outdoor series is ingested from NOAA
with a retrieval row and lives in `AtmosphericObservation` rows;
velocity and acceleration are fitted with stated uncertainty and
STORED as a fit row; the crossing table answers for every
threshold × space with bands and `already-crossed` where true,
and those answers are stored as `ExposureProjection` rows; the
app renders with its nav tri-state honest; a simulation reads an
ingested series without a code change; suites + live probes
green; committed on dev through the pointer chains.

## §12 What this plan is NOT allowed to become

A dashboard that asserts a health crisis from a modelled indoor
series and a remembered threshold table. Every claim on this page
touches human health, and the project's own rules already answer
how to handle that: cite the source, grade the evidence, name the
prior, state the band, and refuse when the data has not been
fetched. If a phase cannot be built honestly, it ships as a
refusal with the measurement that would open it — exactly like a
motor rung that will not pretend to have a magnet.
