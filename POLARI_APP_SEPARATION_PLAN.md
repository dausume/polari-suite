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
| 7 | **The store shows the ISLE-WIDE app picture, and launchers MATERIALIZE on demand** (Dustin 2026-08-14): the catalog lists every PolariAppDefinition known ACROSS the isle — which are defined at isle level, which exist only on some instance, which are "standard" — all as OPTIONS, none pre-installed anywhere; the launcher deb is BUILT AT INSTALL TIME (row → registration → deb → install, one flow), never a shelf of pre-built artifacts that balloons as app counts grow. "Standard polari apps" = the curated seeded set, always listed; NEW apps are convertible into isle apps automatically (the same generator, triggered from the store) | Dustin: counts will balloon; 4 KB × many becomes real; options ≠ artifacts |
| 9 | **Engines get their OWN tiles, and an engine's nature is DUAL-CAPABLE** (Dustin 2026-08-14, both halves): every compute engine appears as its own store tile "just so we can see where they are", and every engine tile carries a **DATA PAGE** — placement, reachability (the *_remote ladder's honest halves), and usage/traffic through it over time where tracked (where NOT tracked, the page says so rather than showing empty charts). But **some engines are simultaneously their own APPS** (Odoo: a full UI *and* the business-ops engine) — so the tile model carries both natures: engine-only tiles (msci/cad) open TO the data page; engine+app tiles (odoo) open to their OWN UI with the engine data page as a secondary view. One tile, two natures, never two tiles. Consequence for sep-4: *_remote seams gain lightweight usage metering (call counts/bytes/latency per window) as rows | visibility of where engines live + what flows through them, without flattening the odoo-like duals into either pure infrastructure or pure app |
| 8 | **Edge behaviors live in APP-SPECIFIC MODULES, as reusable data** (Dustin 2026-08-14): a shell that does MORE than wrap the webapp (camera, device passthrough, radio access, network merge behaviors) gets its native half as a Gradle capability module (the existing ServiceLoader precedent) and its CONFIGURATION half as rows in a module specific to that app — behavior definitions that are configurable, reusable across apps, and expressible as no-code at the edge, "to merge polari, devices, and networks as needed". The registration's `capabilities` list becomes a REFERENCE to those definitions, not the definition itself | capability code is rare and native; capability CONFIG is common and belongs in the object model like everything else |

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
- **sep-3 — "make an isle app from any Polari app" (the utility,
  shaped by decision 7).** The one-command path: `pol app shell
  <PolariAppDefinition>` (and the isle-side `isle shell launcher
  --app <n>`): reads the app row (title, first page → startRoute,
  branding), creates/updates the `AppShellDefinition` row
  (scope=app), emits the registration, and **builds the launcher deb
  AT INSTALL TIME** — the store lists options; artifacts materialize
  when chosen. The missing §43 half — *catalog projection of
  PolariAppDefinition rows into the isle store* — lands here as the
  ISLE-WIDE view: apps aggregated across every instance on the isle
  (the coherence/catalog machinery already joins devices × instances
  × modules), each marked **defined-at-isle-level / instance-only /
  standard / not-yet-converted**, with "convert to isle app" as the
  automatic path for new ones. Store UI: the `installable:false …
  how` entries become that convert/install action.
- **sep-4 — engine apps: msci + cad (the odoo chain, twice), as
  DATA-PAGE tiles (decision 9).** Per engine: an app row whose one
  page is the ENGINE PAGE — placement (topology/coherence rows),
  reachability (the *_remote ladder rendered honestly), and
  usage-over-time; a lightweight metering addition at each *_remote
  seam (call count / bytes / latency per window, rows not logs) so
  the traffic story is measured, with "not tracked yet" stated
  wherever it isn't. IsleCatalogEntry rows with `provides_engine`,
  `_BINDERS` entries whose upsert writes the consumer knob
  (MSCI_ENGINES_URL / CAD_ENGINES_URL provider rows, the
  `_bind_odoo` shape), doors via sep-3. Recon: explicitly NOT
  (shelved with scanning). Livekit + reticulum already have app
  rows and richer pages of their own — they just get sep-3
  launchers, and their engine pages can reuse the same metering
  rows. **Dual-natured engines (decision 9): odoo is the exemplar —
  its tile opens its own UI, its engine data page rides as the
  secondary view; the app row carries an `engine_page` reference so
  ANY engine+app keeps both natures on one tile. Livekit and
  reticulum are duals too (own pages + engine role).**
- **sep-5 — edge-behavior modules (decision 8).** The shape:
  `AppEdgeBehavior` rows (object-coherent, in a module specific to
  the app that needs them — the reticulum module already models
  exactly this for radios: DeviceLink correspondence + the §5l
  shell-capability gate) defining WHAT a shell may do at the edge
  (which devices, which networks, which no-code graphs run
  edge-side) and with what configuration; the registration's
  `capabilities` list references those rows; the shell's Gradle
  capability modules (ServiceLoader, the camera/:capture-desktop
  precedent) stay the rare NATIVE half, gated on declaration as
  today. Reuse: a behavior configuration written once (e.g. "may
  attach the isle's LoRa radio", "may join SSID X") is referenced
  by any app that needs it. No-code at the edge = the graphs the
  behavior rows name, executed shell-side against the same schema
  the backend serves — the "merge polari, devices, and networks"
  seam. Also here: per-app branding actually applied (brandColor/
  icon ride the registration but the frame should wear them); the
  auth question (open q. 2).
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

(Answered 2026-08-14 → decision 7: isle-wide options, install-time
materialization, standard set listed, auto-convert for new. And →
decision 9: engines get their own tiles; opening one = the engine's
data page with placement + usage-over-time.)

1. **Login in a single-app window**: share the one Polari sign-in
   across all app windows (recommended, simplest), or give some
   apps their own separate login registration later if a real need
   appears?
3. **The stripped view in a plain browser**: `?shellApp=` would let
   anyone open the single-app no-menus view from a normal browser —
   good (shareable kiosk-style links; permissions still gate every
   action) or should the stripped view be desktop-shell-only? Plan
   assumes GOOD.

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
