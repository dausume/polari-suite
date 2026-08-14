# Polari App Separation — plan (sep-0..sep-6)

**Date:** 2026-08-14 · **Status: PLANNING — written with Dustin's
brief, grounded in a read-only survey of all four repos (exact paths
below; nothing here is guessed).** The next development phase after
the reticulum arc.

**Dustin's brief, verbatim intent:** render a single Polari app in
the JavaFX shell with app config passed in, WITHOUT the full-Polari
menu; be able to make a Polari Isle App for ANY PolariAppDefinition;
build the remaining engine apps (beyond odoo); keep it adaptable
with utilities that make adding more easy; "maybe simplifying polari
apps to shells with just specific config being passed per .desktop".

**The load-bearing discovery:** that last idea is ALREADY the
architecture — `polari-shell-core` is one shared runtime and every
launcher is a thin deb whose `.desktop` passes
`--config <registration>.json`. The registration schema
(`polari-app-shell/config/polari-shell.schema.json`) already defines
`app.scope ∈ {instance, app}` + `app.appName`; the appstore already
stores `AppShellDefinition` rows carrying scope/app_name/start_route
and even seeds a scope=app EXEMPLAR (`wax-print-shop-shell`,
described as "navigation clamped to one PolariAppDefinition").
**The clamping is implemented NOWHERE** — `scope`/`appName` are
parsed and then read by nothing in the Java shell, and the SPA has
zero single-app machinery (grep: no kiosk/appMode/hideNav anywhere).
So this arc is mostly CLOSING WIRES between halves that both exist.

## ✅ DECIDED (settled at planning time)

| # | Decision | Why |
|---|---|---|
| 1 | **The app-identity channel is the URL, with the bridge as garnish**: the shell appends `?shellApp=<appName>` (+ startRoute) in `ShellFrame.startUrl()`; `shell.info` ALSO grows `{scope, appName}` for shell-aware pages. URL wins because it works in a plain browser, needs no bridge, and survives reloads | the SPA must never block on the bridge (`available===false` in browsers) |
| 2 | **The SPA clamp lives in `AppsNavService`**: a `lockedApp` state making `appForUrl()` return it unconditionally — BOTH consumers (`app.component`, `header`) already derive `currentApp` from that one service, so one seam clamps everything | found seam, not invented: the service is already the single owner of "which app am I in" |
| 3 | **Locked mode HIDES chrome, it does not delete capability**: Apps switcher + Core menu + "Polari core" nav block gated out; routes outside the app REDIRECT to the app home (never 404 — a deep link into foreign territory goes home, honestly) | separation is presentation + navigation, not authorization; KC still governs what acts are allowed |
| 4 | **One generator, three consumers**: `registration_document()` (appstore, already correct for scope=app) becomes THE single source; `build-launcher-deb.sh` gains flags and consumes it; the store tarball path already does; `install_plan` passes the full arg set. No second registration-writer anywhere | the .deb path and tarball path must not drift (today the deb hardcodes scope=instance while the tarball is app-aware) |
| 5 | **Launcher rows are data**: making an isle app for a Polari app = creating/publishing an `AppShellDefinition` row (scope=app) — the store catalog already lists every unshelled app as `installable:false` with a `how` naming exactly this | the row model exists; the arc makes the how-path real |
| 6 | **Engine coverage follows the odoo chain** (module → app row → IsleCatalogEntry(provides_engine) → `_BINDERS` entry): msci + cad first; recon stays shelved with the scanning arc | `_BINDERS` and `SEED_CATALOG` are explicit one-entry-per-engine extension points |

## Phases

- **sep-0 — the SPA single-app mode (the clamp).** Angular:
  `AppsNavService.lockedApp` set from `?shellApp=` (read at
  bootstrap, persisted for the session) and/or `shell.info`;
  `appForUrl()` returns it unconditionally; gate the three chrome
  sites (`header.html` Apps switcher + Core menu;
  `app.component.html` "Polari core" expander); route guard
  redirecting foreign routes to `/app/<name>`. Honest edge: an app
  whose modules are absent still renders its nav with the standing
  quad-state availability (enabled/elsewhere/absent/unknown) — the
  clamp changes WHAT is shown, never the honesty of it. Provable in
  a plain browser (`https://…/?shellApp=app-archipelago`) before any
  shell work — that is the acceptance test.
- **sep-1 — the shell passes what it already knows.**
  polari-app-shell: `ShellFrame.startUrl()` appends
  `shellApp=<app.appName>` when `scope=='app'` (+ keep startRoute
  behavior; startRoute defaults to the app's first page when blank);
  `shell.info` gains `scope`/`appName`; `BRIDGE_CONTRACT.md` row;
  `ShellConfig.looksValid()` starts validating scope/appName
  coherence (scope=app requires appName). Android/iOS: same URL rule
  (it is just the URL — no per-platform work).
- **sep-2 — one registration generator, wired everywhere.**
  `build-launcher-deb.sh` gains `--scope app --app-name <n>
  --start-route <r> --capabilities <csv>` (and stops hardcoding
  scope=instance); preferably it accepts `--registration <json>` and
  the json comes from `appstore_payloads.registration_document()`
  via a new credential-free `GET
  /api/appstore/registration/{shellName}` — the deb builder becomes
  a CONSUMER of the canonical document rather than a second writer.
  Fix `HostInstall.installedVersionCommand`'s hardcoded `isle-app-`
  prefix (kind-aware). Fix `export_app()` dropping
  nav_json/personas_json/discipline (an exported app must be able to
  rebuild its menu).
- **sep-3 — "make an isle app from any Polari app" (the utility).**
  The one-command path: `pol app shell <PolariAppDefinition>` (and
  the isle-side `isle shell launcher --app <n>`): reads the app row
  (title, first page → startRoute, branding), creates/updates the
  `AppShellDefinition` row (scope=app), emits the registration,
  builds the launcher deb, and (isle side) publishes to apt.isle +
  projects an `IsleCatalogEntry`. The missing §43 half —
  *catalog projection of PolariAppDefinition rows into the isle
  store* — lands here, closing the loop the appstore catalog already
  points at. Store UI: the `installable:false … how` entries become
  a "Create launcher" action.
- **sep-4 — engine apps: msci + cad (the odoo chain, twice).** App
  rows (`app-materials-engines`? — naming open question 2),
  IsleCatalogEntry rows with `provides_engine`, `_BINDERS` entries
  whose upsert writes the consumer knob (MSCI_ENGINES_URL /
  CAD_ENGINES_URL provider rows, the same shape `_bind_odoo`
  writes), doors via sep-3. Recon: explicitly NOT (shelved with
  scanning). Livekit + reticulum already have app rows — they just
  get sep-3 launchers.
- **sep-5 — separation hardening.** Per-app capabilities in the
  registration (the camera precedent — declare-or-refused);
  per-app branding actually applied (brandColor/icon ride the
  registration but the shell frame should wear them); WM_CLASS
  per launcher already works. The auth question (open q. 3).
- **sep-6 — the 13-app sweep.** Run sep-3 across every seeded
  PolariAppDefinition; store shows a full shelf; TESTING_OWED gets
  Dustin's GUI pass per app.

## Boundaries

- **Ours**: angular (sep-0), polari-app-shell (sep-1, sep-2 deb
  builder — it lives in polari-app-shell/shells/), framework
  (appstore endpoint, apps export fix, polariapps rows, islemesh
  catalog projection + binders — islemesh module is core-resident).
- **isle-core's (request-doc or its own Claude)**: the `isle shell
  launcher` CLI verb's arg plumbing (its shells/tools are SYNCED
  from polari-app-shell — the sync must run after sep-2), apt.isle
  publishing of generated launchers, store-postinst review. The
  hosts-reconcile precedent: coordinate via provenance notes.

## Open questions for Dustin

1. **Default launcher set**: auto-publish launcher debs for ALL 13
   apps (a full shelf, ~4 KB each + shared core), or on-demand via
   the store's "Create launcher" action only?
2. **Engine app naming**: fold msci/cad into existing discipline
   apps (they already ride app-materials-science / app-mechanical
   via modules) with the ENGINES surfaced as capabilities, or give
   engines their own thin "engine ops" app rows?
3. **Auth in separated apps**: today the shell opens the instance
   URL and the SPA's KC login covers everything. Should a scope=app
   launcher share the instance session (current behavior, simplest)
   or eventually carry per-app KC clients (the registration's auth
   block already allows it — defer unless a real need appears)?
4. **Browser parity**: `?shellApp=` makes separation reachable from
   any browser — feature (shareable kiosk links) or leak (should
   locked mode require the shell)? Plan assumes FEATURE (it is
   presentation, not authorization).

## Grounding index (files the phases touch)

- angular: `src/app/services/apps-nav.service.ts`,
  `app.component.{ts,html}`, `components/header/header.{ts,html}`,
  `app-routing.module.ts`, `services/shell-bridge.service.ts`
- shell: `desktop/.../ShellFrame.java` (startUrl, buildBridge),
  `core/.../config/ShellConfig.java`, `config/polari-shell.schema.json`,
  `docs/BRIDGE_CONTRACT.md`, `shells/build-launcher-deb.sh`,
  `core/.../host/HostInstall.java`
- framework: `modules/appstore/{appstore_basis,appstore_payloads,
  appstore_api,appstore_seed}.py`, `modules/polariapps/{apps_api,
  apps_nav}.py` (export fix), `modules/islemesh/{islemesh_catalog,
  islemesh_engines}.py` (projection + binders)
- proofs: browser `?shellApp=` clamp test (sep-0 acceptance);
  selftests per touched module; a dyn-proof-style launcher
  round-trip (row → registration → deb → dpkg contents) in sep-3.
