# Group ↔ Instance Authority plan — 2026-07-16

Dustin's ask (verbatim intent): a user can become the **primary authority** or a
**shared authority** for BOTH (a) a group of any kind and (b) a Polari instance.
A group↔instance binding designates a Polari instance as **the authoritative
source for that group** — defined on BOTH sides (Polari + PSC). Polari becomes
how groups assert complex matters to the Political Scorecard and how the PSC
gets complex data sources. When a signal arrives ("we want to make this term
available for this context on the PSC"), Keycloak auth assesses that the person
is authoritative on both the Polari instance and the group, the binding exists
on both sides, and only then is the data admitted as **asserted by that group**.
This also becomes the channel that replaces PSC mock data with real
group-attributed data from Polari.

## Decisions (following recon of all three codebases)

1. **Polari side** — new `scoring/group_authority.py` (treeObject + @treeObjectInit,
   name-keyed, `*_json` fields, `_insert`/`_persist` idiom from term_competition):
   - `GroupAuthorityGrant`: `group_name` (ScoreGroup), `subject` (Keycloak sub),
     `username`, `role` ∈ (primary|shared), `status` ∈ (active|revoked),
     `granted_by`, timestamps. **Bootstrap rule:** a group with zero active
     grants → first authenticated claimer becomes primary (first-claim-wins,
     same spirit as mesh name claiming). Afterward only the active primary can
     grant/revoke; at most one active primary (transfer = explicit act).
   - `InstanceAuthorityGrant`: same shape for `instance_name`
     (default `instance_identity()['instanceName']`).
   - `GroupInstanceBinding`: `group_name`, `instance_name`, `counterparty`
     ('psc'), `status`: proposed → **confirmed-local** (proposer holds authority
     on BOTH group and instance) → **active** (counterparty confirm-remote) |
     revoked. This is Polari's side of "defined on both sides".
   - `TermAvailabilitySignal`: `term_name`, `context_name`, `concept_name`,
     `group_name`, `instance_name`, `requested_by_subject/_username`,
     `status` ∈ (pending|admitted|refused), `verdict_json`.
   - `authority_check(manager, subject, group, instance)` → evidence-bearing
     verdict: three named checks (group-authority, instance-authority,
     binding-active), each pass/fail with the grant/binding rows as evidence
     (knobs-and-suggestions: never a bare boolean).
   - **Identity:** handlers prefer the Keycloak-verified principal from
     `request.context.user_info` (AuthContextMiddleware); payload-supplied
     subject is accepted only as fallback and stamped
     `identitySource: 'payload-unverified'` in the verdict evidence.
   - API: self-registering `AuthorityAPI(treeObject)` in
     `scoring/authority_api.py` (ScoringAPI pattern; bounded_stream POSTs;
     `response.media={'ok':...}`), instantiated beside ScoringAPI in
     polariServer. Routes under `/api/scoring/authority/*` +
     `/api/scoring/signals/term-availability`.
   - Classes into `defClassList` + `seed_pairs` (mostly empty seed lists —
     runtime data; a tiny demo set for browser visibility).
   - `scoring/selftest_group_authority.py` per selftest convention
     (SimpleNamespace manager, PASS/FAIL counter).

2. **PSC backend side** (Spring Boot, 4-tier convention):
   - New tables via `*TableInitializer` + registration in
     `ScoringDatasourceInitializer`: `polari_instance` (registry — greenfield;
     seeded with the configured `app.polari.api-url` as instance
     'polari-default'), `group_instance_binding` (PSC's side of the binding),
     `term_provenance` (term/context ↔ group/instance/signal attribution).
   - `PolariAuthorityService` (RestTemplate, PolariSyncService pattern) that
     **forwards the caller's bearer token** to Polari so Polari's Keycloak
     middleware independently verifies the same principal (both sides assess).
   - Controllers (@PreAuthorize per SecurityConfiguration idiom, identity from
     UserInfoService — token subject always overrides client-supplied ids):
     - `/api/authority/instances` GET (public list) / POST (admin-gated,
       `hasRole('policy-voting-admin')`).
     - `/api/authority/bindings` GET/POST — POST creates PSC row then calls
       Polari `bindings/{name}/confirm-remote`; success → active both sides.
     - `/api/authority/signals/term-availability` POST — forwards signal to
       Polari; on `admitted`: ensure Term exists (source stamped
       "group:X via instance:Y"), write `term_provenance`. Returns the full
       verdict either way.
     - Polari-mutation proxies (grants/binding-propose) so browsers keep never
       talking to Polari for writes: `/api/authority/polari/*`.
   - `GET /api/groups/directory` — real group catalogue from Keycloak admin API
     (new `listGroups` in KeycloakAdminService) for the mocked group pages.
   - `GET /api/terms/categories` — distinct categories off the real `term`
     table (replaces MOCK_POLITICAL_CATEGORIES for the annotator).

3. **PSC frontend** (standalone components, lazy routes, polari-votes pattern):
   - `/authority` hub page: instances, bindings (both-sides status chips),
     my grants, grant/propose forms, term-availability signal form showing the
     evidence verdict check-by-check; home-page tile.
   - Provenance badge on term surfaces ("asserted by group X via instance Y").
   - Mock retirement (real group-attributed sources): terms-api.service → real
     `/api/terms`; view-term → real `by-term/{id}` (+ DTO→class rehydration
     mapper, scorer needs Date instances); annotator → terms categories +
     groups directory; group pages → groups directory + existing join;
     worldview effects/selectors/scoring-service → real terms +
     contextualized-terms; fix both hardcoded `'current-user-id'` sites via
     the auth store (election-debate pattern).

## Acceptance (live, staging)
grant(group, primary) → grant(instance, primary) → propose binding
(confirmed-local) → PSC binding create (active both sides) → term-availability
signal admitted with 3/3 checks + provenance row on PSC; the same signal from
an unauthorized subject refused with the failing check named. Selftests green;
both frontends build; PSC term/group pages render real rows.

## Non-goals this pass
Multi-PSC counterparties, authority elections/expiry, revocation cascades,
per-assertion group-roster verification (attribution stays evidence-first, as
in assertion_credibility), retiring the client-side worldview scorer entirely.
