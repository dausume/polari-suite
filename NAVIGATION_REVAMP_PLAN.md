# Navigation revamp — apps with coherent per-topic navigation

> **HANDOFF STATE 2026-07-31 (Fable 5, token-conscious stop per
> Dustin).** nav-0 decided (§4). nav-1 STARTED and committed:
> `PolariAppDefinition` gained `nav_json` / `personas_json` /
> `discipline` (backward-compatible defaults) and `apps_seed.py`
> gained `_app(..., nav, personas, discipline)` + `_grp`/`_it`
> helpers. polariapps selftest 20/20. **Next agent picks up at §5.**

## 5. Pick-up instructions (exact)

1. **nav-1 remainder** — in `polariapps/apps_seed.py`, add six
   discipline apps using `_grp`/`_it` (kinds: page | simspace |
   view | tech-node): `app-magnetics` (groups: Studies → /magnetics/
   motor, /sim-spaces/motor-m0-viz (simspace), /magnetics/clock-views
   (view, requires composition), /magnetics/fields, /magnetics/
   clock-motor; Tree → electromagnetic-systems tech-node),
   `app-mechanical` (gears, composition mechanical view, stress/
   fatigue studies), `app-materials-science` (msci groups + a PSPP
   group holding the 11 existing pspp routes + multi-scale-sims),
   `app-business` (business/odoo, business/start, bizops),
   `app-policy` (dmvdata sources, maps, scoring epistemics; PSC
   splice = future group), `app-scorecards-data-analysis` (scoring,
   scoring/accountability, scoring/survival + workbench group
   linking datasets/graphs/tables). Personas per §4.4.
2. **⚠ Seed path**: polariapps rows currently seed INSERT-ONLY, so
   the new fields will NOT reach the three existing live rows (the
   ten-strikes gotcha). Wire `polariapps` seeds through
   `composition.seed_upsert.upsert_seed_pairs` in polariServer's
   seed pass (same guarded block pattern as CompositionSeed /
   ScaleGoalsSeed), gated on both modules being available.
3. **nav-2** — new `polariapps/apps_nav.py`: `apps_nav(manager)` /
   `app_nav_report(manager, name)`. Availability per item is a
   TRI-STATE (enabled | absent | unknown) derived via
   `polariApiServer.module_gating.feature_available` guarded in a
   try (apps_analysis's no-framework-imports rule: duck-type and
   degrade honestly). Absent → attach bringup affordance
   (`/modules/bringup`, requires chain from the registry if
   readable). Routes `/api/apps/nav` + `/api/apps/nav/{app}` in
   `apps_api.py` (follow its existing add_route pattern).
   Selftests in `selftest_apps.py` (fake-manager style, currently
   20/20): item availability derivation, absent-module app still
   renders its full nav with affordances, unknown tri-state when
   the gating import is unavailable.
4. **nav-3..6** — per §2/§3 of this plan (shell app switcher,
   /app/:name home, /magnetics redirect, clock-views sections lead
   with summaries + links INTO sim-spaces and materials/:name,
   persona chips, the absent-module map probe). Angular repo branch:
   `dev-arch-part-composition`; follow clock-views.component.ts
   conventions (standalone, theme surface tokens, loadComponent
   route in app-routing.module.ts).
5. Branch: continue on `dev-arch-part-composition` ×4 repos (or a
   fresh `dev-nav-revamp` off it if Dustin prefers a phase branch).
   Deploy: `pol node build backend|frontend` + `docker service
   update --force`; remember composition lives in the swarm env
   (see motor-goals memory) and heavy endpoints 504 on the first
   cold call.

**Dustin 2026-07-31**: the clock-views page is payloads, not insight;
`/magnetics` leads nowhere. Revamp: make magnetics (and disciplines
generally) APPS with app-specific navigation menus; navigate into
SimSpaces relevant to different studies (visualization + materials
used); persona entry points (EE → magnetics/electrical, ME →
mechanical, materials scientist → search FEM/DFT/PSPP...); preserve
CORE navigation; and keep an abstract map — structure, topology,
tech trees — even on instances (or collections of instances) that
don't have the modules enabled, so people see how to bring modules
online one at a time for a business or product. "Look through
everything and revamp the navigation into something coherent."

## 0. What exists — extend, do not invent

| Piece | Where | What it already does |
|---|---|---|
| **PolariAppDefinition** | `polariapps/apps_basis.py` (tt-12) | app = named module configuration: `use_case` (the persona hook), `modules_json`, `pages_json` (front doors); /apps page; export/deploy packages; **plan computation against a topology** (which modules run where — the multi-instance answer) |
| module registry | `polari-modules.json` + module_registry | downloaded/enabled/requires per module — the "may not be enabled" truth |
| lazy boot | mlb-0..5 | `/modules/bringup` panel, warm-boot ETAs, honest 503s — "bring online one at a time" exists |
| tech trees | techtree (3 domain trees) | the abstract-level map that must survive absent modules |
| SimSpaces | `sim-spaces/:name` route + SimSpaceDefinition rows | motor-m0-viz, field views — the study visualizations |
| views as data | `ClockViewDefinition` (view-1) | discipline sections; needs *linking into* pages/simspaces, not raw payload dumps |

## 1. Route audit (63 routes today) — the coherence problem stated

- **Core (keep in the global shell)**: apps, modules/bringup,
  module-management, module-details, tech-tree, topology,
  polari-config, permissions, api-config, api-profiler,
  manager-info, system-diagnostics, typing-info, callback, testing.
- **No-code core (keep)**: displays, display/:id, tables, graphs,
  maps, equations, matrices, datasets, create-class,
  class-main-page/:class, custom-no-code, sim-spaces(+/:name),
  multi-scale-sims(+/:name,+new).
- **App-shaped clusters (become apps with their own menus)**:
  magnetics/* (4 routes, no home), pspp/* (11 routes!), scoring/*
  (3), xr/* (4), zones-board, materials/:name, business/* (2),
  video-assets. Motors/gears/composition have APIs but no pages —
  they join the magnetics/mechanical apps.
- The sprawl: 63 flat routes, three navigation idioms, and app
  clusters (pspp!) that already invented private sub-navigation.
  The revamp gives every cluster the SAME app-nav mechanism.

## 2. The design

### nav-1 — extend `PolariAppDefinition` (backend, upsert-seeded)

New fields: `discipline`, `personas_json` (['electrical-engineer',
'mechanical-engineer', 'materials-scientist', 'business-operator']),
`nav_json` — the structured menu:

```
nav_json: [{ group: 'Studies', items: [
  { label: 'M0 clock motor — running', route: '/magnetics/motor',
    kind: 'page', requires_module: 'motors' },
  { label: 'Motor scene (3D)', route: '/sim-spaces/motor-m0-viz',
    kind: 'simspace', requires_module: 'motors' },
  { label: 'Goals & scales', route: '/magnetics/clock-views',
    kind: 'view', requires_module: 'composition' },
  { label: 'Electromagnetic systems (tree)',
    kind: 'tech-node', ref: 'electromagnetic-systems' }, ... ]}]
```

`kind` is what makes studies navigate INTO simspaces/materials
instead of dumping payloads. Item availability is DERIVED live from
the module registry: an item whose module is absent renders with a
"gated off — bring online" affordance (bringup ETA + `requires`
chain + tech-tree node), never hidden. **The map survives the
missing territory.**

App seeds (first wave): `app-magnetics` (magnetics+motors+
composition+gears studies), `app-mechanical` (composition mechanical
views, gears, stress/fatigue studies), `app-materials-science`
(materialsScience+pspp+msci sims — the FEM/DFT/PSPP search home),
`app-business` (bizops+odoo+supplychain), existing waxprint/aqua
apps re-seeded with nav_json.

### nav-2 — `/api/apps/nav` (backend)

Apps + nav trees + per-item availability + bringup hints, computed
against THIS instance's registry — and, via the existing tt-12 plan
computation, against a TOPOLOGY (collection of instances), so the
answer can be "enabled on node B" rather than "absent".

### nav-3 — the shell (frontend)

App switcher in the core header (core routes stay put); an
`app-nav` component renders any app's `nav_json` as its sidebar;
`/app/:name` = app home (title, use_case, personas, menu, module
status strip). `/magnetics` finally leads somewhere: redirect to
`/app/app-magnetics`.

### nav-4 — studies link INTO the visuals

Rework clock-views sections: each section card leads with a
2-3 line SUMMARY + links (open SimSpace / materials used / tech
node), full payload demoted to the expander. The mass view links
each part to `materials/:name`; motion links to
`sim-spaces/motor-m0-viz`; magnetics fields to `/magnetics/fields`.

### nav-5 — personas

Persona chips on /apps and app homes filter apps + jump straight
into the discipline's default study ("EE → magnetics"). Personas
are rows on the app, not code.

### nav-6 — the abstract map for absent modules

App home + tech-tree views render for apps whose modules are OFF:
tech trees are core-bootable, so the structure/topology/abstract
info always shows, with per-module "bring online" actions (the mlb
bringup flow) and the tt-12 deployment-plan suggestion for
multi-instance placement. This is the "understand the tech trees
and bring modules online one at a time for a business" requirement,
built from two systems that already exist.

## 3. Phases & acceptance

| Phase | Acceptance |
|---|---|
| nav-1 backend | app rows carry nav/personas/discipline; availability derived; selftests incl. absent-module rendering data |
| nav-2 API | /api/apps/nav live; topology-aware answers via tt-12 plan |
| nav-3 shell | app switcher + app-nav render from rows; /magnetics redirects to the app home; core routes untouched |
| nav-4 studies | clock-views sections lead with summaries + working links into sim-spaces/materials; raw payload demoted |
| nav-5 personas | EE/ME/MatSci/business chips route correctly |
| nav-6 absent-map | with magnetics gated OFF, the magnetics app home still shows its tree + bringup affordances (probe) |

## 4. nav-0 — DECIDED (Dustin 2026-07-31)

1. **pspp merges into `app-materials-science`** (one app, pspp as
   a nav group; the 11 pspp routes keep working and gain the app
   home first, migrating incrementally).
2. **`app-policy` is its own app** besides business — dmvdata
   sources/cost-of-living, gov/legal catalogs, maps; the political-
   scorecard splice is its future group.
3. **`app-scorecards-data-analysis`** — scoring (+accountability,
   survival), with nav links into the no-code analysis pages
   (datasets, graphs, tables) as its workbench group.
4. Personas: electrical-engineer, mechanical-engineer,
   materials-scientist, business-operator, + policy-analyst for
   the two new apps.
