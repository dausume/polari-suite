# Multi-Scale Simulation Page — Design (for review)

_2026-07-02 — follows Milestone A (wind→pendulum coupling, live-verified, checkpointed on
`dev-wind-coupling` in all four repos). This is the design for Dustin's next ask: a configurable
page that ties Displays, graphs-over-time, parallel run viewers, and initial-condition-setting
interfaces into the Multi-Scale Simulation via linkable definition objects. Nothing below is
built yet — review + adjust freely._

## What you asked for, restated

1. A **Multi-Scale Simulation Page** showing multiple simulation runs at the same time,
   progressing **in tune** (the wind run and the pendulum run advancing together).
2. **Configurable graph interfaces** — data evolving over time as the sim advances.
3. **Initial-condition-setting views** linked to the ICs, **auto-triggering the IC validator
   (debounced)** as selections are made — e.g. a **material picker for the bob**.
4. All of it **configurable and linkable via objects** that tie into the multi-scale sim,
   matching the style of the existing general pages (Displays / Graphs / Datasets).
5. **Toolbars + configurations that weave together and reach into every part of the
   multi-scale simulation, so a user can configure one FROM SCRATCH with configuration and
   no-code only** — the page is the authoring hub, not just a display surface.
6. **Reuse first**: per-simulation configuration happens on each sim's EXISTING config
   pages — the multi-scale page links out with navigation buttons rather than duplicating
   those editors. The page itself owns only what is genuinely multi-scale: the *weaving*
   (couplings), the *overall initial conditions*, and the *multi-scale steps*.
7. **Multi-scale steps are themselves no-code**: an ordered progression of stages with
   gates — e.g. FIRST run the material simulation (adjust temp/pressure until the substance
   condenses into a solid ball, analyze the resulting ball size, prove a solid ball is
   possible); only when that gate passes does the pendulum stage unlock, with the proven
   ball's properties flowing into its initial conditions.
8. **Audience: normal people.** This is a framework to help non-specialists build
   multi-scale simulations — guided flows and plain-language gates over expert consoles.

## Core concepts (Dustin, 2026-07-02 — these govern naming and architecture)

**Scenario Comparison ≠ Multi-Scale.** Two distinct things the page does; never blur them:

- **Scenario Comparison**: the *same* simulation run under different conditions, side by
  side (vacuum vs wind; ice bob vs steel bob). The runs are **causally independent** —
  nothing flows between them; the page merely keeps them time-aligned for contrast. This is
  what the fan-out stepping + side-by-side viewer are, and the UI labels them
  "scenario comparison".

- **Multi-Scale Simulation**: spaces with **inherent logical interconnection** — they step
  and interlink logically. Two grades of interconnection exist in the system today:
  1. *Coupled stepping* (wind → pendulum): one space's field sampled into another's step,
     across timescales. Real multi-scale data flow.
  2. *Constitutive dependency* (material → pendulum): the deeper form. The **first-
     principles space** (materials) must have a valid-solution condition that is both
     **DEFINED** (the condition is authored: "a solid ball is achievable; analyze its
     shape/size/properties") **and ACHIEVED** (an actual run found the temp/pressure where
     it holds) before the downstream simulation can even *define its own initial
     conditions*. The pendulum's IC interface is only legitimate downstream of that.
     Enforced in the stage evaluator: a stage that later stages `derive` from is never
     complete without a defined, passing gate — running alone doesn't count.

Mathematically, multi-scale spaces are often function/solution spaces (Green's-function /
Hilbert-space character) rather than simple state vectors. The framework's primitives are
shaped for that: **field-valued state** (a whole grid/matrix as one row, e.g. `cells_json`)
and **no-code sampler equations as the projection operators between spaces**. When a space's
"state" is a solution space, the coupling is a projection/sampling from it — keep new
couplings in that shape.

## What already exists (surveyed — we reuse, not rebuild)

- **Display grid system**: `Display → DisplayRow → DisplayColumn → DisplayItem`, rendered by
  `dashboard-renderer`. Item type `'component'` resolves any registered Angular component by
  name via `DISPLAY_COMPONENT_REGISTRY` with per-item inputs. This is the plug-in point: once
  our panels are registered components, they become usable in ANY user-configured Display.
- **Graph pipeline**: `GraphDefinition` (source_class + x/y dimensions) → `graph-renderer`,
  which fully re-renders whenever its `instanceData` array is reassigned — so "graph that
  grows as the sim steps" is just feeding it a new array per committed step.
- **Sim-space viewer** is standalone and multi-instance-safe (fresh renderer per instance).
  It's missing only a `@Input() run` (today the run is chosen by its internal panel) and a
  `@Input()` to hide that panel for read-only embeds. Two small additions.
- **IC editing + debounced validation is already built**: `RunInitialConditionsEditorComponent`
  debounces edits 400 ms and calls the standalone endpoint
  `POST /api/simulations/{sim}/validate-initial-conditions` — the SAME code path that gates
  step 0, so the live feedback and the real gate can't drift apart. We wrap it, not rewrite it.
- **Page skeleton + styling**: the Graphs/Datasets/Displays pages share one SCSS contract
  (`_config-page-common.scss`: page-container, class-group accordions, config-card grids) and
  one component pattern (definition service + `allConfigList$` + group-by-source-class). The
  new pages copy this exactly. Nav = one route + one `staticNavComponents` entry; no auth
  wrapper needed (object-level Keycloak enforcement already applies).
- **Backend definition classes cost nothing**: import + `defClassList` gives auto DB table +
  CRUDE + typing. (Polari doing its job.)

## The one real backend gap

**No timeseries endpoint.** Generic CRUDE `readAll` cannot filter by run or step (it returns
every row of the class), and `current-state` is single-step. Graphs-over-time need:

```
GET /api/simulations/runs/{run}/series
    ?class=NewtonianPendulumBobSimState
    &fields=energy_total,fwind_x,pz
    &stepFrom=0&stepTo=400        (optional)
    &sinceStep=123                (optional — incremental fetch for live growth)
```

Returns `{steps: [...], time: [...], fields: {name: [...]}}` per class, filtered through the
existing shared `run_scope` (so a coupled run's series can include its source runs' rows
consistently with how the renderer filters). Implementation mirrors the row-walk already in
`on_get_current_state`. `sinceStep` keeps live polling cheap.

## New objects (the "linkable via objects" part)

**1. `MultiScaleSimulationDefinition`** — THE tying object (this is roadmap Milestone C
made concrete: space composition as configuration):

- `name`, `description`
- `member_simulation_refs_json` — the participating SimulationDefinitions
  (e.g. `["newtonian-pendulum-3d", "wind-field-3d"]`)
- `coupling_refs_json` — the SimulationCouplingDefinitions binding them
  (e.g. `["wind-to-newtonian-pendulum"]`)
- `primary_simulation_ref` — the sim whose run the user drives (play/step);
  coupled sources advance themselves via the existing lazy pull
- `stages_json` — **the multi-scale progression, itself no-code.** Ordered stages the run
  set advances through, each with a completion **gate**:
  ```json
  [
    {"key": "material-precondition", "kind": "runToCompletion",
     "simulationRef": "material-condensation-2d",
     "gate":   {"solutionRef": "solid-ball-achievable"},
     "derive": {"params": {"newtonian-pendulum-3d.mass": "ball_mass",
                            "newtonian-pendulum-3d.bob_radius": "ball_radius"}}},

    {"key": "pendulum-in-wind", "kind": "coStep",
     "primarySimulationRef": "newtonian-pendulum-3d",
     "couplingRefs": ["wind-to-newtonian-pendulum"]}
  ]
  ```
  A `runToCompletion` stage runs its simulation (whose own no-code solutions do the
  searching — e.g. sweep temp/pressure toward a solid phase); its **gate is a no-code
  SolutionDefinition** evaluated over the run's results, executed through the SAME engine
  flow the IC validator already uses (flattened `class.field` context in → pass/fail +
  reason + derived values out). Gate passes → the next stage unlocks, and `derive` maps the
  gate's outputs (proven ball mass/radius) into the next stage's ICs/params.

  **Solution search (decided 2026-07-02): a first-principles stage can attempt MULTIPLE
  candidate solutions per simulation to reach one valid solution.** Stage schema gains
  `search`: each candidate is a run of the stage's sim with its own parameter overrides
  (a different T/P point); the orchestrator steps candidates in batches, gate-evaluates
  each, and the stage is ACHIEVED by the first candidate whose gate passes (the winner's
  derived values feed `derive`). All attempts — including failures — are recorded; an
  exhausted search IS the `disabledData` for the downstream choice (searched ranges,
  every attempt's reason, nearest miss).
  ```json
  "search": {
    "candidates": {"kind": "grid",
                   "parameters": {"temperature": {"from": 250, "to": 350, "steps": 5},
                                   "pressure":    {"from": 1,   "to": 100, "steps": 4}}},
    "stepsPerAttempt": 50,      // default: the sim's duration/dt
    "batchSize": 4,             // attempts advanced per orchestrator call
    "select": "first-valid"     // ("best-score" via a gate score output: later)
  }
  ```
  `kind: "list"` supplies explicit candidate dicts; `kind: "solver"` (gradient-descent
  candidate generation — the Milestone E "encroach on a target" search) is the reserved
  next step and slots into the same orchestrator. The search is STATELESS/resumable:
  attempts are ordinary named runs (`<msim>-<stage>-attempt-<k>`), so progress is derivable
  from the DB and repeated orchestrator calls continue where the last left off. A `coStep`
  stage is the live coupled stepping we have today. The page shows the progression as a
  plain stepper — "1 ✓ Material proved · 2 ▶ Pendulum running" — with a human-readable
  reason when a gate fails ("no solid phase found in the searched T/P range").
- `panels_json` — ordered panel configs for the page's default layout. Each panel is a
  `{kind, ...refs}` record pointing at OTHER definition objects, never inline duplicates:
  - `{kind: "scene",  simSpaceRef: "newtonian-pendulum-viz", run: "primary" | "<name>"}`
  - `{kind: "graph",  graphRef: "<GraphDefinition name>", runs: ["primary", "compare:*"]}`
  - `{kind: "ic",     icInterfaceRef: "<InitialConditionInterfaceDefinition name>"}`
  - `{kind: "display", displayId: <id>}` — escape hatch: embed a whole user-configured
    Display grid inside the page
- `display_ref` (optional) — when set, the ENTIRE page layout is that Display (fully custom
  layout via the existing grid editor) instead of the default panel flow.
- `compare_run_policy_json` — how "comparison" runs (e.g. vacuum vs wind) are grouped and
  kept in tune (see progression section).

**2. `InitialConditionInterfaceDefinition`** — a configured IC-setting view:

- `name`, `description`, `target_simulation_ref`, `target_class_name`
- `interface_kind`: `'choicePreset'` (the material picker) | `'fieldEditor'` (raw fields,
  the existing editor scoped to configured fields) — extensible later (sliders, 2D pickers)
- `config_json` for `choicePreset`:
  ```json
  {
    "label": "Bob material",
    "choices": [
      {"key": "ice",   "label": "Ice ball",   "setFields": {"..."},
       "setParams": {"mass": 0.48, "bob_radius": 0.05}},
      {"key": "steel", "label": "Steel ball", "setParams": {"mass": 4.1, "bob_radius": 0.05}},
      {"key": "lead",  "label": "Lead ball",  "setParams": {"mass": 5.9, "bob_radius": 0.05}}
    ],
    "derived": {"bob_cross_section": "pi * bob_radius**2", "...": "..."}
  }
  ```
  A choice maps to a bundle of IC field values / parameter overrides; derived geometry is
  recomputed so the wind drag sees the right cross-section. Every selection fires the
  debounced validator automatically (it plugs into the existing `stateChange` +
  validate-initial-conditions flow).
- **Milestone B bridge (why this shape):** when the material space lands, `choices` stops
  being hand-authored and is instead *generated from* Material objects + the condensation
  precondition sim — the interface definition stays identical, only the choice source
  changes. That's deliberate: the material picker you asked for is the doorway into
  Milestone B without rework.
- **Failed first-principles choices are DISABLED WITH REASON AND DATA** (decided
  2026-07-02): when the first-principles space fails to achieve a valid solution for a
  substance (no temp/pressure yields a solid ball), the IC interface still shows that
  substance — disabled, with the gate's plain-language reason AND the supporting data
  (e.g. the T/P range searched, the nearest-miss result). The physics teaching the user
  what it refused, and why, is part of the framework's purpose. Choice schema gains:
  `{key, label, enabled: false, disabledReason, disabledData: {...gate outputs...}}`.

Both are plain definition classes: import + `defClassList` + optional seed rows. We seed one
demo of each: **"Pendulum in Wind"** (members: pendulum + wind; panels: scene, energy graph,
wind-force graph, material picker) so the page works out of the box.

## "In-tune" parallel progression — two mechanisms

1. **Coupled runs** (wind + pendulum): already in tune by construction — advancing the
   primary run lazy-pulls its sources to exact time coverage. Nothing new needed.
2. **Comparison runs** (vacuum vs wind pendulum): the page's play/step control fans the same
   step commands out to every run in the comparison group, so they stay at the same time.
3. **One shared page scrubber**: a single time axis; every panel (scenes, graphs' cursor,
   readouts) shows its state at the latest step ≤ t — the same zero-order-hold rule the
   backend coupling uses, so what you see IS the sampling semantics.

Scene panels: the coupled set renders in ONE viewer (already works — wind cells + bob share
the scene via run-scope expansion). Comparison runs get side-by-side viewers. WebGL caps the
page at ~4 3D viewers; the default layout stays well under.

## Frontend pages (matching existing style)

- **`/multi-scale-sims`** — list page: copy of the Graphs page skeleton (accordion groups,
  config cards, `_config-page-common.scss`), listing `MultiScaleSimulationDefinition`s, with
  create/edit/delete + "Open page".
- **`/multi-scale-sim/:name`** — the page itself. Default layout (no custom Display set):

  ```
  ┌─────────────────────────────────────────────────┐
  │ Pendulum in Wind          [Run set ▾] [▶ Play]  │  header: run-set picker,
  │ members: pendulum + wind   coupling: wind→bob   │  play/step (drives primary)
  ├──────────────────────────┬──────────────────────┤
  │  3D scene (coupled set)  │  3D scene (vacuum)   │  scene panels
  ├──────────────────────────┴──────────────────────┤
  │  ⏱ shared time scrubber ————————●————           │
  ├──────────────────────────┬──────────────────────┤
  │ energy vs t (both runs)  │ |F_wind| vs t        │  graph panels (live-growing)
  ├──────────────────────────┴──────────────────────┤
  │ Bob material: ( ice | wood | steel | lead )     │  IC interface panel(s)
  │ ✓ valid — |T|max within rod limit    [New run]  │  debounced validator verdict
  └─────────────────────────────────────────────────┘
  ```

- Panels are standalone components registered in `DISPLAY_COMPONENT_REGISTRY`
  (`msim-scene-panel`, `msim-graph-panel`, `msim-ic-panel`) so the same panels are ALSO
  available inside any user-configured Display — that's requirement 4 satisfied twice over.
- Small enabling changes: `sim-space-viewer` gains `@Input() run` + `@Input() hideRunPanel`;
  `MultiScaleSimulationDefinitionService` + `InitialConditionInterfaceDefinitionService` are
  copies of the graph-definition service template.

## Authoring: from scratch, no-code only (the toolbar architecture)

The page gets two modes, mirroring the Displays edit-mode convention: **Run mode** (panels
above) and **Configure mode**. Configure mode adds a persistent **part rail** (left toolbar)
whose entries are the anatomical parts of a multi-scale simulation. Each entry expands to
list the objects of that part, with create/edit actions that **deep-link into the existing
no-code editors and return here** (breadcrumb back to the page) — that's the weaving:

```
┌──────────┬──────────────────────────────────────┐
│ PARTS    │  (selected part's config surface)    │
│──────────│                                      │
│ ▸ Spaces │  Spaces = member SimulationDefs.     │
│ ▸ States │   · new space → sim-def form         │
│ ▸ Steps  │   · states → /createClass (exists)   │
│ ▸ Coupl. │   · steps → no-code solution editor  │
│ ▸ Scenes │     (exists, incl. MatrixEquationOp) │
│ ▸ Graphs │   · couplings → NEW coupling editor  │
│ ▸ ICs    │   · scenes/bindings → binding forms  │
│ ▸ Panels │   · ICs → IC-interface editor        │
│ ▸ Runs   │   · panels/layout → Display grid     │
└──────────┴──────────────────────────────────────┘
```

**Reuse rule (per Dustin):** the rail's per-simulation entries NAVIGATE OUT to each sim's
existing config surfaces (sim pages, solution editor, /createClass, scene pages) via
buttons and return via breadcrumb — the multi-scale page never re-implements them. Only
the genuinely multi-scale parts get NEW editors here: **weaving** (couplings), **overall
initial conditions** (across spaces/stages), and the **stage progression + gates**.

Every part is already a definition object with CRUDE, so authoring = forms + existing
editors; **no step requires code**. The from-scratch journey (also offered as a guided
"New Multi-Scale Simulation" wizard walking the same rail top to bottom — written for a
non-specialist: each wizard step says what it's for in plain language):

1. **Spaces** — pick existing SimulationDefinitions or create one (→ navigates to the sim
   config surface; per-space states/steps are authored THERE, via /createClass + the
   no-code solution editor, not here).
2. **Stages** — order the spaces into the multi-scale progression: which run to
   completion first (preconditions), which co-step live; author each gate in the no-code
   editor (button out, breadcrumb back); wire `derive` mappings (gate outputs → later
   stages' ICs/params).
3. **Couplings** — the weaving editor (NEW): source space+class+field → target
   space+class, sampler equation (picked/authored in the matrix-equation editor), inject
   map, defaults. Writes a `SimulationCouplingDefinition` row.
4. **Overall ICs** — the cross-space initial-condition surface: IC interfaces (material
   picker etc.), per-space overrides, one debounced validation verdict.
5. **Scenes / Graphs / Panels** — link existing SimSpace scenes + GraphDefinitions,
   arrange panels (optionally via the Display grid).
6. **Runs** — create run sets, pair coupled runs (`coupled_run_refs_json`), play.

Gap check for "truly no-code from scratch": `/createClass`, the solution editor, the
matrix-equation editor, scene viewing, CRUDE forms all EXIST. What must be built new:
the **coupling editor form**, a **sim-def/space form**, **binding editor forms** (bindings
are currently seeded/JSON-edited), the **IC-interface editor**, and the **rail/wizard**
shell itself. All are config forms over existing CRUDE objects — no new engine surface.

## Build order (each phase = branch off dev, per the standing workflow)

- **Phase 1 (backend):** two definition classes (incl. `stages_json`) + `/series` endpoint +
  the stage-gate evaluator (reusing the IC-validator engine flow) + demo seeds + selftest.
- **Phase 2 (page core):** list page, detail page with scene panels, run-set header controls,
  shared scrubber, viewer `run` input, **Configure-mode shell + part rail with deep links to
  the editors that already exist** (spaces/states/steps/scenes navigate out and back).
  → *first visible page, already an authoring hub*
- **Phase 3 (graphs):** graph panels on `/series` with `sinceStep` live growth; energy +
  wind-force demo graphs for both runs.
- **Phase 4 (IC interfaces + stages UI):** `msim-ic-panel` wrapping the existing debounced
  editor + the choicePreset material picker; the stage stepper (run-to-completion → gate
  verdict → unlock next, plain-language reasons); "new run set from these ICs" flow.
- **Phase 5 (authoring forms):** the NEW editors — coupling (weaving) editor, stage/gate
  wiring form, IC-interface editor — completing the from-scratch no-code journey via the
  guided wizard; per-sim parts stay navigate-out buttons to their existing pages.
- **Phase 6 (composition):** register panels in the Display registry, support `display_ref`
  full-custom layouts, polish to match the general pages.

Acceptance test for the whole initiative: **recreate "Pendulum in Wind" from an empty
database using only the page's toolbars and the no-code editors** — if that works, the
framework has genuinely become configure-only for multi-scale simulation.

## Questions for you (answerable from your phone)

1. **Material picker now = presets** (ice/wood/steel/lead mapping to mass/radius/derived
   geometry), wired to real Material objects when Milestone B lands. OK, or do you want the
   materials-science module involved from day one?
2. **Default scene layout**: coupled set in one shared 3D scene + comparisons side-by-side
   (recommended), or strictly one viewer per run?
3. **Custom layouts** via the Display grid arrive in Phase 5 (default auto-layout first).
   OK to defer, or is grid-configurable layout needed from the first version?
4. Any additional panel kinds you already know you want (tables of raw step rows? readout
   tiles like the HUD evals?) so I shape `panels_json` for them now?
