# Navigation revamp — apps with coherent per-topic navigation

> **HANDOFF STATE 2026-07-31 (Fable 5, cont).** nav-0 decided (§4).
> nav-1 COMPLETE, DEPLOYED + LIVE-VERIFIED: fields + helpers, EIGHT
> discipline apps seeded (the six below PLUS `app-software-
> engineering` and `app-topology-network` — Dustin 2026-07-31:
> "customize displays and no-code or classes" / "Topology with
> Network and Cloud engineering"), polariapps seeds wired through
> the composition upsert path (`AppsNavSeed` block), and all 11
> live rows verified carrying nav_json/personas_json/discipline.
> selftest_apps 33/33 local + in-container; composition 75/75.
> Two live-caught gotchas recorded in §5.1.
>
> **nav-1b + nav-2 + nav-3 COMPLETE, DEPLOYED + BROWSER-VERIFIED
> (same day, cont).** Dustin: apps must leverage BOTH the top and
> side menus, with a base top+side nav preserved for entering apps
> and the higher-level views. Built: `top_menu` group placement
> (side menu = always the complete map; top groups additionally
> become header dropdowns; 10 groups promoted), `apps_nav.py` +
> `/api/apps/nav(+/{app})` (tri-state enabled|absent|unknown,
> bringup affordances w/ requires chain, server-computed per-module
> strip, synthesized Pages group for use-case apps, persona index;
> selftests 45/45), and the shell: header Apps switcher + Core menu
> (always present), app pill + topMenu dropdowns in context,
> side-nav `app-nav-panel` above a collapsible "Polari core"
> expander, `/app/:name` home, `/magnetics` redirect. Live-caught:
> the opt-in `testing` module renders absent w/ amber bring-online
> chip on the software-engineering app — nav-6's map-survives
> behavior demonstrated on a real gap. Both themes verified.
> **nav-4 + nav-5 + nav-6 COMPLETE, DEPLOYED + BROWSER-VERIFIED
> (same day, cont 2) — THE REVAMP'S SIX PHASES ARE ALL DONE.**
> nav-4: every clock-view section carries a seeded 2-3 line LEAD +
> links-as-data into the visuals (motion/stress → motor-m0-viz,
> magnetics → /magnetics/fields, sourcing → /magnetics/clock-motor);
> the mass bill DERIVES per-part /materials/:name links from its
> live payload; specialized tables + raw payload demoted into a
> 'details & numbers' expander. Browser-verified on view-mass.
> The tech-node ref was corrected to the NAMESPACED TechNode name
> ('electronics/electromagnetic-systems') — caught by the probe,
> and the ref change reached the live row via AppsNavSeed with
> zero CRUDE PUTs (second live proof of the upsert path).
> nav-5: 'I am a…' persona chips on /apps (?persona= deep-linkable
> filter; arrow jumps to the discipline's first enabled study —
> EE lands on /magnetics/motor, browser-verified); app-home chips
> route back to the filtered /apps. nav-6:
> tests/apps_nav_probe.py boots the real server with the ENTIRE
> magnetics chain gated OFF — full nav renders, every gated item
> absent w/ bringup + requires chain, tech-node survives, scoring
> contrast enabled, legacy no-composition seed fallback proven;
> 11/11 in-container (set POLARI_LAZY_BOOT=off in-process, else
> the container knob defers seeding and everything 503s).
> Suites: selftest_apps 45/45, selftest_motors 274/274.
> **mod-env (Dustin: "make it a real module, not an env-var
> outlier") — DONE, same day:** module enablement is topology ROWS.
> 13 env-only modules assigned to prf-a; `modules_env_for_instance`
> + GET /api/topology/modules-env/{instance} derive POLARI_MODULES
> from enabled ModuleAssignment rows with the registry requires
> closure (zero rows REFUSES — empty env would boot monolithic);
> `pol swarm render|deploy node` derives it (a pre-set env var is a
> loudly-warned override); `pol topology modules-env` reads it; the
> CLI's core-api transport now reaches the swarm backend task.
> Verified live: derived == live env EXACTLY (18 modules),
> app-magnetics plan readiness 0 → 1.0, stack render bakes the
> derived env with pol-core constraints intact.
> **Remaining idea beyond the plan:** /tech-tree could read ?node=
> to focus the ref'd node.

## 5. Pick-up instructions (exact)

1. ~~**nav-1 remainder**~~ ✅ DONE (framework `eaa7db1`+`8df3dad`+
   `86c4099`): six planned discipline apps seeded per spec, plus
   `app-software-engineering` (Build: create-class/custom-no-code/
   displays/equations/matrices; Inspect: typing/manager/api-config/
   profiler/diagnostics + /testing gated on `testing`) and
   `app-topology-network` (Topology, Modules & deployment, tech
   trees; personas network-engineer + cloud-engineer). Catalog
   items ride `/class-main-page/:class`; every route verified
   against the Angular router.
2. ~~**⚠ Seed path**~~ ✅ DONE: `AppsNavSeed` guarded block in
   `polariServer._seedSimSpace3D` (composition+polariapps gated);
   legacy insert pass kept as no-composition fallback.
   `PolariAppDefinition` gained `is_prior`.

### 5.1 Gotchas caught live during nav-1 (both now pinned in tests)

- **Local imports shadow module-level seed names**: re-importing
  `PolariAppDefinition`/`SEED_POLARI_APPS` inside `_seedSimSpace3D`
  made them function-local everywhere → the legacy seed list
  crashed the admission worker (UnboundLocalError) on the first
  deploy. Import only what is not already module-level.
- **`is_prior=None` is a NULL backfill, not a human's mark**: rows
  predating the column restore with None; `not is_prior` skipped
  them as "customized" — exempting exactly the legacy rows the
  upsert exists to converge. seed_upsert now blocks only on an
  EXPLICIT False/0 (composition selftest pins it).

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
