# Scoring accountability chain: time → assertions → policies → politicians

**STATUS 2026-07-08 (evening)**: scr-1..4 BUILT + LIVE-VERIFIED.
**scr-5, scr-6, scr-8 BUILT** this session (framework branches
dev-scr-5-assertions 623bb68 → dev-scr-6-politicians 6e80c07 →
dev-scr-8-voting f8851f1, stacked; angular dev-scr-5-assertions
9ef1fb7 carries the frontend for all three). Selftests:
scoring 65/65, assertions 48/48, politicians 21/21, elections 18/18.
Frontend: /scoring/accountability page + contextualization findings
on the concept board; ng build green. **NEXT BUILD: scr-7**
(scorecard polariUrl wiring + thin fixes) or Part 2 (scr-9 promises —
MediaEvidence already exists from scr-5). Working log + gotchas in
the context-scoring memory file.

Additions beyond the original scr-5 design (gaps Dustin's 2026-07-08
directive named that the plan lacked): **Contributor** rows
(individual/org/lobby/institution, pseudonymous KNOB, affiliations;
asserted_by / voter / submitted_by / contributed_by all key to them;
track-record endpoint = confirmation rate over validity review — the
lobby-accountability number); **EvidencePolicy** (grade → weight as
an editable row incl. 'unevidenced'); ContextualizedValue/PolicyVote
`contributed_by` + ingestion passthrough.

## Dustin's directives (2026-07-08)

> "Politician scoring through Policy Scoring via Score Assertions onto
> policies. We should track politician voting on policies, which should in
> theory be available via an API somewhere publically. Then based on
> highlighting and assertion that portions of policy impact a particular
> concept (and should thereby be scorable by the context that has been
> scored)."

> "we need our scores and their context to be very time specific and for
> polari to be able to adaptively handle different kinds of time frames and
> scales coexisting and overlapping and interpolating between multiple
> metrics that use different scales at which they are measured intelligently."

> "we need intelligent contextualization to ensure specificity of our terms
> and that the terms match to the specificity of the score itself, and that
> this can also map to more abstract concepts so that we can more easily
> assign scores via assertions of generic intents and then suggestions of
> scores that should apply"

The chain, end to end:
```
values (time-aware, any scale)         scr-4
  → concepts (nesting: scr-2)  → group agreement (scr-3)
  → ASSERTIONS bind policy text spans to concepts       scr-5
  → policy scores (assertion-weighted concept scores)   scr-5/6
  → votes bind politicians to policies (public APIs)    scr-6
  → politician scores                                   scr-6
```

## scr-4 — time-specific scores: coexisting/overlapping frames + interpolation

Values measured yearly, quarterly, per-event must serve one concept frame.

1. **Temporal nature on ScoreTerm** (`temporal_json`): {'nature':
   'stock'|'flow'|'event', 'resample': 'mean'|'sum'|'nearest'|'last'} —
   how a metric may be resampled is METRIC semantics, declared on the term
   (a flow sums, a stock averages/lasts, events count). Refusal when
   undeclared and resampling would be needed (knob named).
2. **Timeframe algebra** (scoring/timeframes.py): parse ScoreContext
   timeframe value_json (start/end ISO dates); `overlap_fraction(a, b)`;
   `duration_days`; timeframe specificity = shorter frame wins (replaces
   the flat base-5 rank).
3. **Time-aware selection** in the engine: a required timeframe context
   matches values whose frames OVERLAP it; full-cover direct use;
   partial covers → time-weighted combination per the term's resample
   rule; gaps between neighboring frames → linear interpolation
   (`method: 'interpolated'`), stamped on the breakdown ('derivedFrom'
   rows + method — a reader always sees measured vs derived). Knobs:
   `allow_interpolation` (concept-level, default True),
   `allow_extrapolation` (default False — refusal names the frontier
   frames).
4. Selftests: yearly+quarterly coexisting; overlap weighting parity
   (hand-computed); gap interpolation; extrapolation refusal; undeclared
   temporal nature refusal.

## scr-5 — score assertions + intelligent contextualization — BUILT 2026-07-08 (fw 623bb68)

1. **ScoreAssertion** class: `target_ref_json` (objectRef to ANY object; +
   optional `span_json` {'start','end','quote'} for policy TEXT spans — the
   scorecard's W3C-annotation idiom, generalized), `intent` (free generic
   statement, e.g. 'improves labor conditions'), `concept_name`/`term_name`
   (may be EMPTY — that is what suggestions fill), `direction`
   ('supports'|'harms'), `strength` (0-1), `asserted_by`, `status`
   ('asserted'|'confirmed'|'disputed'), provenance.
2. **Abstraction mapping**: ScoreTerm/ScoreConcept gain
   `abstract_tags_json` (generic intent vocabulary: 'labor-conditions',
   'wages', 'public-health'…). `suggest_scores_for_assertion(assertion)`
   matches the assertion's intent text/tags against concept/term tags →
   ranked SUGGESTIONS ({'concept', 'evidence', 'knob': assertion.
   concept_name, 'action'}) — never auto-bound (knobs-and-suggestions).
3. **Specificity conformance** (`check_concept_specificity`): per concept,
   compare each term's available value specificity (context hierarchy
   ranks + timeframe durations) against the concept's required contexts →
   findings ('term measured nationally, concept scores states — value
   will satisfy via hierarchy but is LESS specific; suggestion: ingest
   state-level series'). The msim-conformance idiom: slot-by-slot findings
   w/ evidence.
4. **Policy scoring**: a policy subject's score for a concept =
   assertion-weighted composition: confirmed assertions binding its spans
   to concepts, each direction×strength; refusals when a policy has no
   confirmed assertions for the requested concept. Endpoint:
   GET /api/scoring/policies/{name}/score?concept=...
5. Frontend: assertions panel (target + span quote + intent + status +
   suggested concepts w/ accept-knob), specificity findings on the concept
   board.

## scr-6 — politicians, votes, public-API ingestion — BUILT 2026-07-08 (fw 6e80c07; live Congress.gov profiling still pending, ingest-votes seam ready)

1. Subjects kind 'politician' + 'policy'; **PolicyVote** rows (politician,
   policy, vote 'yea'|'nay'|'abstain', vote_date, chamber, provenance).
2. Public vote APIs (Congress.gov API v3 — api.congress.gov, free key;
   GovTrack bulk; OpenStates for states) profiled through the EXISTING
   api-profiler (external API → local class), then
   `ingest_from_class` / direct PolicyVote rows. The profiler pipeline is
   the ingestion path — no bespoke ETL.
3. **Politician scoring**: politician's concept score = vote-weighted
   aggregation over policy scores (yea on a policy that scores 0.8 for
   labor-quality → contributes positively; nay inverts; abstain =
   participation gap, honestly surfaced). Time-specific: votes carry
   dates → politician scores per timeframe (scr-4 machinery).
4. Group lens (scr-3): politician cohorts as ScoreGroups (party =
   political group; committee = professional group) — divisive/consensus
   read on how cohorts vote across concepts.

## scr-7 — scorecard node division of labor
Scorecard = quick storage/retrieval + rough local calc (its
worldview-scoring.service stays for instant UI feedback); Polari =
authoritative engine. Wire ContextualizedTerm.pre/postProcessPolariUrl +
TermDimension.polariUrl at /api/scoring endpoints; scorecard annotation UI
(legislation annotator) posts ScoreAssertions to Polari. Rework scorecard
functionality as needed (Dustin's explicit OK, 2026-07-07).

---

# Scorecard gap audit (code sweep 2026-07-08) → plan mapping

A full sweep of political-scorecard-node for designed-but-not-functional
features. What IS real there: legislation CRUD + status workflow + MinIO +
PDF/DOCX export, annotation CRUD, debate websocket, Keycloak group
join/list-mine, and plain CRUD for terms/contexts/values/elections. The
hollow core is the **vote → results → score** layer. Division-of-labor
rule for every gap: aggregation/derivation logic lands in POLARI; the
scorecard gets thin storage + UI wiring.

## Gaps the Polari engine already covers (wire, don't rebuild)
- **Server-side score computation** (scorecard Score.java is a 3-field
  stub; math runs client-side on mocks) → Polari scr-1 engine. Wire via
  the polariUrl hooks.
- **DataSeries/DataSeriesDimension/Origin/Proxy** (0 references anywhere)
  → superseded by Polari scr-2 ingestion + the api-profiler pipeline. Do
  NOT implement in Java.
- **Competitors** (Competitor/CompetitorDimension/CompetitorCategory —
  models with no DAO/service/controller; UI shell only) → Polari
  ScoreSubjects. Scorecard competitor UI reads Polari subjects (scr-7).
- **Election results/aggregation** (worldview-elections-api.service.ts
  declares 7 un-backed endpoints: /{id}/ballots, /close, /results,
  /results/group/{groupId}, /groups, /create-general-score,
  /create-group-score — election-review.component 404s on all) → results
  = Polari scr-3 group aggregation; create-general/group-score = persist
  a ScoreConcept/group aggregate back. Scorecard keeps election lifecycle
  CRUD (already real) + proxies results to Polari (scr-7).

## Gaps that ENRICH scr-5 (from the scorecard's own README designs)
Three backend READMEs describe subsystems that were never built — adopt
their semantics into the Polari assertion model:
- **Typed assertions** (legislativecompetition README): positive/negative
  score-impact assertions, DEPENDENCY-legislation assertions (score
  carry-over from legislation this bill depends on), decorative-text
  assertions (spans asserted to carry no score weight). → ScoreAssertion
  gains `assertion_type` vocabulary + dependency propagation
  (carry-over = a nested-concept edge between policy subjects).
- **Multi-round assertion validity voting** (same README): assertions
  themselves get voted valid/invalid in rounds → ScoreAssertion.status
  lifecycle ('asserted'→'under-review'→'confirmed'|'rejected') + a
  validity-vote tally (scr-3 group machinery over assertion stances).
- **Purpose-equivalent terms / term scope** (termcompetition README +
  Term.java's unused logical/purpose-equivalence stubs): Polari
  ScoreTerm.equivalent_terms_json/competitive_terms_json ALREADY EXIST
  (seeded, unused) — scr-5 abstraction mapping must consume them for
  intent→term matching.
- **Policy-variation flowcharts w/ disputable context assertions**
  (policycompetition README) → scr-5/6: policy variants as subjects,
  their differing assertions = the comparison surface.
- **CriticalContext** (model exists, no backend; "system-suggested
  high-impact context variations") → scr-5 intelligent
  contextualization: suggest the contexts where a concept's scores
  DIVERGE most (variance scan over context slices) — evidence-bearing
  suggestions, never auto-applied.

## scr-8 (new) — voting modes over worldviews — BUILT 2026-07-08 (fw f8851f1: WorldviewElection/Ballot in POLARI, approval/sole/ranked-condorcet, closed-only apply → ScoreGroup.member_weights_json + provenance, weighted aggregation w/ scr-3 parity; scorecard-side vote storage wiring stays in scr-7)
WorldviewVote.java is a field-only skeleton describing approval / sole /
ranked(condorcet) voting over contexts AND term weights. Build the tally
in Polari (votes are just rows; tallies are scr-3-style aggregation with
a mode knob), scorecard stores votes (quick storage). Election close →
tally → group weights → a ScoreGroup's member worldviews get
vote-derived weights instead of hand-set ones.

# Part 2 — Societal accountability systems (Dustin 2026-07-08 + proposals)

## scr-9 — Political promise accountability
> "the ability to tie media as proof to a promise by a politician, and the
> ability for a politician to commit to a promise of something being
> improved by policy"

1. **MediaEvidence**: url/file ref, kind (video/transcript/official-record/
   article/social-post), quote/span, capture date, provenance,
   **evidence_grade** (primary-recording > official-record > contemporaneous
   -report > secondhand — a graded vocabulary row like AgreementPolicy, so
   what counts as proof is a SETTING). Assertions and promises cite
   MediaEvidence rows; assertion strength is weighted by grade.
2. **PoliticalPromise**: politician subject, statement, evidence refs, the
   COMMITMENT: term (ScoreTerm) + direction/target magnitude + the contexts
   it applies to + the promised timeframe. Two creation paths: asserted
   from media BY anyone (status 'attributed'), or COMMITTED by the
   politician themselves (status 'committed' — the stronger form Dustin
   names).
3. **Promise lifecycle**: attributed/committed → policy-linked (assertions
   tie policies to the promise) → window-open → measured → verdict
   (kept / partially-kept / broken / overtaken-by-events / unmeasurable —
   each verdict carries the measured values + windows + confounders, scr-11).
   Status transitions snapshot the promise (tamper-evident history:
   accountability can't be quietly rewritten).
4. **Effect windows** ("different policies may have different time-spans in
   which they can realistically take effect"): `effect_profile_json` on
   promises AND policy assertions: {lagDays, rampDays, horizonDays}.
   Judging before the window opens = honest refusal ("too early — window
   opens 2027-03"); scr-4 machinery evaluates inside the window.

## scr-10 — Events: impacts beyond policy
> "things besides just policies can actually cause effects … assertions
> that events are things with political impact as much as policy can be,
> and accountability for who was responsible … natural disasters of
> different scales, wars and who gave orders … whether people agree with
> them can also be voted on. Preparedness for bad things being sufficient."

1. **PoliticalEvent**: kind vocabulary (natural-disaster, war,
   pandemic, financial-crisis, infrastructure-failure, scandal…),
   **scale** (graded, per-kind vocabularies — e.g. disaster categories),
   timeframe + location contexts (scr-4/hierarchy native), description,
   provenance.
2. **Responsibility assertions**: who ordered / decided / neglected —
   target = a politician/office/institution subject OR honestly 'nature/
   nobody'; each with evidence (MediaEvidence) + status lifecycle +
   validity voting (scr-5's multi-round machinery).
3. **DecisionContext record**: "what the situation was for those that led
   to the decision" — the information available at decision time, as
   evidence-backed rows; the AGREEMENT VOTE runs over the decision given
   its context (scr-8 voting modes + scr-3 group reads: was the order
   justified — divisive/majority/consensus per group).
4. **Impact accounting**: economic/social impacts of events land as
   ContextualizedValues attributed to the event subject (same seam as
   policies) — events and policies become COMPARABLE impact sources.
5. **Preparedness evaluation**: a preparedness concept per event kind
   (readiness terms: reserves, response time, infrastructure grade,
   drills) scored BEFORE the event window; after an event, the gap
   between preparedness score and impact = the accountability reading
   ("prepared and unlucky" vs "warned and unprepared").

## scr-11 — Attribution honesty layer (proposed — the missing glue)
Accountability dies when everything in a window is attributed to whoever
holds office. Three systems the framework needs:
1. **Confounder surfacing**: scoring a politician/policy on an outcome
   metric automatically surfaces OVERLAPPING events + other policies whose
   effect windows intersect ("unemployment rose in this window, but
   war-X and disaster-Y overlap it") — attribution stays an assertion
   with named confounders, never a silent implication.
2. **Office-scoped responsibility** (proposed): Office rows (powers
   vocabulary + jurisdiction contexts + tenure timeframes); a
   responsibility/promise assertion conformance-checks that the subject
   HELD an office with relevant powers during the window (a mayor is not
   accountable for federal policy — the check is evidence, not censorship:
   mismatches surface as findings).
3. **Peer-baseline benchmarking** (proposed): outcomes judged against
   comparable subjects over the same window (difference-vs-peers: "did it
   improve MORE here than in peer states?") — reuses levelization +
   context hierarchy for peer selection; kills the rising-tide fallacy in
   both directions.

## scr-12 — Personal lens: tax burden + cost of living
> "tax burden evaluation … per week, per month, per year … against overall
> taxation at different scales … cost of living comparison … different
> knobs people can adjust"

1. **Tax burden evaluator**: personal profile knobs (income, location
   contexts, filing status, property, consumption pattern) × ingested
   rate tables (income/payroll/sales/property/fuel — public data via the
   api-profiler → ingest_from_class pipeline) → estimated burden per
   week/month/year, itemized per tax kind with provenance. Comparison via
   the context hierarchy: your burden vs city/state/country medians —
   the same value machinery, subjects = anonymized profiles or areas.
2. **Cost-of-living comparator**: a "standard of living" = a BASKET
   definition (knobs: housing type/size, diet, internet tier, commute
   miles + gas, childcare, healthcare) — structurally a weighted term
   bundle (ScoreConcept reused, terms = cost components priced per area
   from ingested series). Compare a basket across areas; compare baskets
   in one area; users adjust the knobs to assert what cost-of-living
   SHOULD include (their basket is a row, shareable, groupable — scr-3
   group agreement over baskets falls out for free).
3. **Budget-vs-outcome accountability** (proposed): where the taxes GO —
   promised budget allocations vs actual spend per program (ingested),
   tied to the outcome metrics those programs claim to move ("what you
   paid vs what was delivered") — closes the loop between the personal
   lens and the promise system.
4. **Income-bracket-relative burden** (Dustin 2026-07-08): brackets are
   DEMOGRAPHIC CONTEXTS (bracket ranges = an editable vocabulary row —
   what counts as a bracket is a setting); burden values keyed by
   bracket+circumstance contexts give: you vs your own bracket, vs other
   brackets, vs other circumstances (household size, filing type) — the
   existing value/context machinery, no new engine.
5. **Area profiling**: areas as subjects scored by profile concepts —
   crime rate, yearly budget-from-taxation, program spend, revenue mix —
   ingested public series; the per-bracket burden assessment reads
   THESE profiles (an area's budget ÷ its bracket distribution = who
   actually carries it).
6. **Program/subsidy accounting**: GovernmentProgram subjects; values:
   cost@area+year, recipientCount@area+bracket+year — the bracket
   context on recipient/benefit values directly yields "WHO at what
   income bracket the subsidies are benefitting" and how many people
   consume tax money through programs, per area, over time (scr-4
   frames native).

## scr-12a — Survival-cost intake walkthrough (personal lens, first slice) — BUILT 2026-07-08 (fw 0d3ea23, ng 6691a90: /scoring/survival wizard)
> Dustin 2026-07-08: "walking people through entering in their
> survival costs per month … rent, mortgage, what is required to work
> like cars needed per person … ask them to go into their bank app
> and go through the calendar for a month … also ask for
> uncancellable subscriptions since those are a pseudo-tax caused by
> corporate corruption or can be considered as such"

1. **CostCategory rows** (editable vocabulary, the AgreementPolicy
   idiom): each category carries its own WALKTHROUGH GUIDANCE ("open
   your bank app, go through last month's calendar, sum the rent
   payments…"), a kind (survival / work-required / pseudo-tax /
   discretionary) and a matching ScoreTerm. 'uncancellable-
   subscriptions' seeds as kind pseudo-tax — the classification is a
   KNOB on the row (a contestable framing groups can later vote on
   via scr-8/13), never baked-in fact.
2. **Walkthrough endpoint**: ordered steps from the category rows —
   household knobs first (household size, workers, cars needed per
   worker), then one step per category with its guidance. The UI is
   generated FROM the vocabulary, so editing categories edits the
   wizard (object-coherence).
3. **Submit**: validates against the vocabulary (unknown categories
   refuse; skipped categories are honest gaps that travel as
   completeness, not errors), creates a household ScoreSubject
   (pseudonymous contributor attribution) + one ContextualizedValue
   per category under [location, month] contexts — the profile IS
   engine-native data from the moment it lands.
4. **Area report**: per category across household profiles in an
   area/month: n, mean, median; subtotals BY KIND — survival /
   work-required / pseudo-tax — so "what does surviving here cost"
   and "how much of that is pseudo-tax" are one read. Small samples
   flagged.

## scr-13 — Definition accountability (the DC affordable-housing case)
> "in DC affordable housing was promised and subsidized but what they
> subsidized were housing for households with over 200k salary for small
> luxury apartments; if people were able to vote directly on the proper
> definition of this, their policy outcome score would be abysmal"

The failure mode no other phase catches: a promise KEPT under the
implementer's definition and BROKEN under the public's. Definitions
must be first-class, votable, and score-bearing:
1. **OperationalDefinition rows** attached to a ScoreTerm: the concrete
   parameters that decide what COUNTS (affordable-housing := rent ≤ X%
   of the area's Yth income percentile, unit ≥ Z sqft…). Multiple
   definitions per term coexist: the implementer's (as written in the
   policy — itself evidence), proposed alternatives, and the
   COMMUNITY'S (chosen by scr-8 definition votes, group-readable via
   scr-3 — is the definition itself consensus or divisive?).
2. **Side-by-side verdicts**: a promise/policy outcome is scored under
   EACH standing definition — "kept (implementer's definition) /
   broken (community definition, 0.12)" in one view. The divergence
   between definitions is itself a first-class finding
   (**definition-divergence**): large divergence + implementer-favorable
   direction = the deception made visible, with the parameter deltas as
   evidence (200k eligibility vs voted 60% median income).
3. Definition votes are time-stamped (scr-4): outcomes judge against the
   definition the community held WHEN THE PROMISE WAS MADE — redefining
   afterwards (in either direction) is visible history, not retroactive
   truth.

## scr-14 — Judicial accountability + operative-law drift
> "how often rulings for particular issues were done in direct
> contradiction to the policies (from a voter perspective) … legal
> contracts given by companies as pseudo-governmental policies that …
> change the local de jure law based on how judges have ruled on them.
> Meaning the de jure law may be the opposite of what is implied by
> legislative law. And people should be able to vote on if that is the
> case"

1. **JudicialRuling rows**: court + judge subjects (kind 'judge'/
   'court'), case ref, date (scr-4 frames), issue tags (the scr-5
   abstract-tag vocabulary — rulings and policies share it, that IS the
   match key), refs to the legislation/policies the ruling bears on,
   outcome summary, evidence = the opinion itself (MediaEvidence grade
   'official-record' — the best-documented domain in the framework).
2. **Contradiction assertions**: 'this ruling contradicts that policy's
   intent' — an assertion FROM THE VOTER PERSPECTIVE, evidence-backed,
   validity-voted (scr-8) and group-read (scr-3: is the contradiction
   reading consensus or partisan? — that split is itself a finding).
   **Judicial accountability concept**: per judge/court, contradiction
   rate per issue area over time — same engine, subjects are judges;
   appointment/election lineage ties a judge's record back to whoever
   appointed them (scr-11 responsibility chain).
3. **Contracts as pseudo-policies**: LegalContract subjects (kind
   'contract', issuer = a company subject; ToS, employment clauses,
   HOA covenants, arbitration terms) with impact-scope contexts (the
   community they bind). Assertions that a contract term FUNCTIONS as
   de facto local law; rulings upholding/striking terms link contracts
   into the operative-law record. Companies thereby become scoreable
   policy-issuing subjects — accountability is not government-only.
4. **De jure drift finding** (the scr-13 pattern applied to law):
   per issue + jurisdiction, the LEGISLATIVE position (from legislation
   text/assertions) vs the OPERATIVE position (from accumulated rulings
   + upheld contracts) — divergence computed, evidence-bearing
   (the rulings ARE the deltas), and VOTABLE: 'is operative law here
   the opposite of what the legislation implies?' Time-stamped so drift
   is a trajectory, not a snapshot — you can watch a protection get
   hollowed out ruling by ruling.

## scr-15 — Media accountability: accuracy against the data — BUILT 2026-07-08 (fw c4b85b1)
> Dustin 2026-07-08: "media accountability for accuracy to data"

Media outlets become scoreable subjects whose FACTUAL CLAIMS are
checked against the ingested data — the engine already knows what the
number actually was, so accuracy is computable, not voted.
1. **Media outlets as subjects** (kind 'media-outlet'); MediaEvidence
   gains `outlet_name` so every cited article ties to an accountable
   outlet.
2. **FactualClaim rows**: outlet × statement × the checkable payload
   (term, subject, contexts, claimed_value, claim date) + the article
   evidence. Logged by contributors (attributed).
3. **AccuracyPolicy** (editable bands over relative error, the
   AgreementPolicy idiom): exact ≤0.5% · accurate ≤5% · close ≤15% ·
   wrong — what counts as accurate is a SETTING.
4. **check_claim**: resolve the measured value through the SAME
   engine path scores use (context + time matched, scr-4 native) →
   relative error → band, with both numbers + the measured value's
   provenance. No data = 'unverifiable', an honest refusal naming
   what's missing — never a silent skip.
5. **Outlet accuracy record** (the contributor-record idiom): claims
   checked/unverifiable, band distribution, mean relative error,
   per-term breakdown → outlets rank by demonstrated accuracy, and
   scr-16 reads this as source quality.

## scr-16 — Per-group bias analysis — BUILT 2026-07-08 (fw 36b99f4; ng 8fb7cc6 carries the scr-15/16 sections)
> Dustin 2026-07-08: "per group bias analysis"

Four independent bias reads per group, each label traveling with its
numbers (bands = editable **BiasPolicy** rows):
1. **Stance skew vs consensus**: the group's aggregate definition vs
   the all-groups consensus, per term — opposed stances and emphasis
   gaps named (reuses scr-3 machinery).
2. **Assertion direction one-sidedness**: over assertions by the
   group's member contributors (`ScoreGroup.member_contributor_
   names_json`, new): supports-vs-harms fractions per target subject
   kind — a group that only ever harms one kind of target is
   visible.
3. **Validity-vote alignment (confirmation-bias read)**: for each
   member validity vote, was the assertion FAVORABLE to the group's
   stance on its term? alignmentRate = self-serving votes / decisive
   votes, banded (balanced / leaning / one-sided / echo-chamber);
   counter-stance votes are the evidence-driven signal. Small
   samples labeled, never over-read.
4. **Source quality**: evidence grades + scr-15 outlet accuracy over
   the sources the group's assertions cite — "who do they cite and
   how accurate are those outlets".

## Scorecard-side thin fixes (small, do during scr-7)
- worldview-ballots / contextualized-term-scores / critical-contexts:
  frontend CRUD services exist, backend has NO controllers — add thin
  storage controllers (or point the services at Polari CRUDE directly).
- terms-api.service.ts is 100% mock despite a REAL /api/terms backend —
  swap (file-level TODO says so).
- Dead route: manage-elections 'Review results' navigates to
  /worldview-elections/:id/review which is not in app.routes.ts.
- Groups: list is MOCK_*_GROUPS while join/list-mine are real Keycloak;
  missing list-all/leave/group-detail endpoints; 'view group detail' is
  a console.log TODO. Map scorecard groups ↔ Polari ScoreGroups.
- Political categories: mock-only (model exists, no DAO/controller).
- Legislation annotator's category/group dropdowns run on mocks (CRUD +
  export behind them is real).
- Hardcoded `currentUserId = 'current-user-id'` in election-creator +
  ballot-creator (TODO: auth service).
- connection-status service/indicator: disabled placeholder.
- ElectoralPosition.java: orphan (0 refs) — delete or leave; not planned.

## Conventions
Branch per phase (dev-scr-4-time…); selftests from polari-framework/ via
`python3 -m scoring.<mod>`; staging deploy per rebuild-staging convention;
knobs-and-suggestions; object-coherence (assertions/votes/policies are
rows); labels always travel with their numbers; falcon POST bodies read
request.bounded_stream (raw stream.read blocks the worker).
