# Handoff — the App Separation arc SHIPPED (sep-0..7), AI Tool
# Linkages PLANNED (2026-08-15, one session)

The whole separation arc went from plan to live in this session,
plus the LocalAI evaluation/fork sweep and the next arc's plan.
This file is the map; detail lives in the plans and memory.

## 1. START HERE for the next arc

`AI_TOOL_LINKAGES_PLAN.md` — **ai-0..ai-5, surveyed not guessed**
(Dustin's design: AI tools as first-class store citizens; a
DEDICATED store section; remote-intermediary (claude/codex) vs
local-hosted (LocalAI) hosting kinds; a LINKAGE vocabulary with
proven-vs-feasible + LIVE readiness). First move = **ai-0** (the
AiToolDefinition object model + AI_LINKAGES vocabulary + seeds).
3 open questions for Dustin sit in the plan; none block ai-0..ai-2.

🔑 Why it is cheap: the reasoning seam is ALREADY provider-agnostic
(`polariApiServer/reasoning_provider.py` — `openai_compatible`
takes base_url; `/ai/providers` = select/set_auth/validate) and the
sep arc built the whole store chassis (derived sections, _BINDERS,
ENGINES pages, edge behaviors). LocalAI backs the assistant with
CONFIG, not code.

Branches: framework/angular/cli sit on `dev-sep-1` (stack: dev →
dev-dyn-1 → dev-mtg-1 → dev-ret-1 → dev-sep-1); app-shell's
`dev-sep-1` was cut from its `dev` (scan stays shelved on
dev-scan-1 — pointer question RESOLVED). Cut `dev-ai-1` from
`dev-sep-1` per the branch-per-phase rule (two empty dev-ai-1
branches were created and deleted this session — cut fresh).

## 2. What the separation arc left LIVE (all staging-proven)

- **sep-0** SPA single-app clamp (`?shellApp=`, session-sticky,
  falls OPEN on unknown names) + shellAppGuard territory redirects.
- **sep-1** `StartUrl.of()` in shell :core — desktop + android +
  the Wolvic intent share ONE URL rule; shell.info carries
  scope/appName.
- **sep-2** one registration generator: the deb builder consumes
  `--registration` verbatim (endpoint already existed:
  `GET /api/appstore/{shell}/registration?download=1`).
- **sep-3** `pol apps shell <app>` (row → registration → deb,
  idempotent) + the §43 isle-wide OPTION projection in
  /api/islemesh/catalog + store UI section.
- **sep-4** engine tiles: /api/engines + /engines/:engine pages;
  EngineUsageWindow metering at both *_remote seams;
  EngineProviderBinding = a new ladder rung written by msci/cad
  _BINDERS; duals carry engine_page.
- **sep-5** AppEdgeBehavior rows + /api/appstore/behaviors;
  CapabilityGate (deny-all) + shell.capabilities; branding worn.
- **sep-6** the sweep: ALL 16 apps converted (16/16 options
  "isle app"), debs in scratchpad `sep6-debs/` (rebuildable).
- **sep-7** AppPermissionProfile rows + the CRUDE gate on all 7
  verb handlers, **knob `POLARI_APP_PERMISSIONS` = OFF** (flipping
  it is Dustin's act); /api/apps/permissions/my + /profiles with
  ADAPTIVE knownGroups (live from the realm — NEVER invent groups;
  seeds are unpublished group-less templates); frontend 11a
  single-app auto-route. ⚠ DEFERRED: 11b app-prefixed routes,
  11c sticky menu-less exit.
- ⚠ standing ops facts: reticulum needs re-ADMIT after every
  backend roll (POST /modules/reticulum/admit — done ~8× today);
  the 3-node swarm bounces every `--force` roll (designed fix =
  pol allocate → POL_STACK_CONSTRAINTS, Dustin's call which
  machine pins).

## 3. Rules/gotchas minted this session (do not re-learn)

1. **sitecustomize prepends /app/modules unless it is ALREADY on
   PYTHONPATH** — in-container overlay test runs MUST include
   /app/modules in PYTHONPATH or old code silently shadows the
   copy (this masked a real seed-count drift once).
2. **composition is OFF on prf-a** → the upsert seed pass NEVER
   runs there; every seed-field change to existing rows needs the
   CRUDE-PUT backfill (12th strike, documented in the gotcha file;
   GETs showing class defaults prove nothing).
3. **NC = HARD BLOCKER** (the project exists to empower small
   businesses); weights carry their own licenses — check both.
   **Fork-as-pin**: criteria-passing upstreams get forked under
   dausume/ (15 pins incl. LocalAI; free-splatter.cpp = the
   important one for scanning revival).
4. `env UID=…` (bash UID is readonly); hung polari-frontend-tests
   containers block the compose name; 5 XrLobby spec fails are
   pre-existing; XrPanelSystem grip test is flaky (re-run).
5. KeycloakClient.configured is a @property.

## 4. Owed / waiting on Dustin

`TESTING_OWED.md` §0 is current and detailed. Headlines: the sep
GUI passes (clamp eyeball, one launcher install, per-app walk,
store/engine pages); the sep-7 sequence (bind the 2 template
profiles to EXISTING groups — the realm already has Polari
Administrators/Developers/Users/Viewers — flip the knob to
advisory, then the single-app login proof); DELETE 3 forked-in-
error repos (magpie-tts.cpp / vibevoice.cpp / face-detect.cpp —
gh token lacks delete_repo); answer the AI plan's 3 questions;
hand SEPARATION_ISLE_CORE_REQUEST.md to isle-core's Claude when
convenient. Older gates unchanged (dyn review, push sweep,
meetings human tests).

## 5. Memory map

[[polari-app-separation]] (the whole arc, dense),
[[ai-tool-linkages]] (the next arc, planned),
[[localai-self-hosting]], [[scan-reconstruction]] (revival engines
adopted), [[project-license-gplv3]] (NC rule + fork pins),
[[seed-field-addition-gotcha]] (12th strike + the answer),
TESTING_OWED.md + the two plan files + 
LOCALAI_3D_BACKENDS_EVALUATION.md at suite root.
