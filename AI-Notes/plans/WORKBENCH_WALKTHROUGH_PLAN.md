# Workbench walkthrough: set up a Bench, then assign a Mission (wb arc) — plan 2026-10-25

His words (2026-10-25): "something else I know I want to setup is a step by step way to go through setting up a mission and a workbench.
We should have selections for different things to put onto our workbench, and buttons we click to get pop-ups like a breadboard button
that gives us cards of breadboards and their details like different footprint sizes that fit and how many rails and power they handle, etc.
Then having a selector similarly for dev/eval-boards and other similar prototyping boards that are not specific PCBs made for a specific
purpose. Those should similarly be categorized into cards based on things like RISC-V vs not risc-V (largest part), pre-certified wireless
boards for different wireless categories, and then per-level boards (Bare-C, FreeRTOS, Zephyr). Try to put together a simple walkthrough for
making a Bench and then assigning a mission for what you want to do with that bench to see if a mission is possible."

## 1. What exists (surveyed 2026-10-25; paths under polari-framework/modules)
- **Bench** rows (`board/objects/board/Bench.py`): boards_json [{board, title, label, chip, family, section, testing, added, note}],
  breadboards_json [{model, title, count, note}]. `/display/bench` (`board/bench_page.py`) = configured tables; "Add to bench" / "Remove"
  are row actions on `/api/board/benches/<b>/{boards,breadboards,remove}` (`board/custom/bench.py`). One bench seeded: home-bench.
- **BreadboardModel** (`BreadboardModel.py`): kind half|full|mini|bus-strip|unverified, tie_points, rows, rail_holes, rails, width/height
  (derived at 2.54 mm), geometry_known, basis, notes. NOTHING on power/current/voltage, nothing on which board footprints fit.
- **Boards** come from the chip ladder (`ChipLadderEntry`: section riscv|convenience, family RISC-V|AVR|ARM Cortex-M0+|Xtensa LX7|FPGA,
  core, boards_json [{board, title, on_hand, note, price_usd?}], levels_json {bare_c|freertos|zephyr|ubuntu: {status, basis}}, emulator_json).
  So architecture = `family`; the level a board supports = its chip's levels_json (with a basis each); `RuntimeProfile` rows (rt-0) say per
  board whether a runtime is supported or refused. **Wireless** exists only as free text (`core`/`chip`, `BoardDefinition.radios`);
  **pre-certification (FCC/IC/CE module IDs) exists nowhere**.
- **The attempt engine**: `cmod/custom/solve.py: solve(mission, boards, tiers, objective, limits)` → candidates, score card, pruned branches
  with reasons (mis-0); `approach_profile_tiers.check_tier` (runtime supported/refused per board); `bench.ladder_boards` (each board's
  testing word: simulated with real pins / stub / HARDWARE ONLY). The Mission plan (§3) makes the bench the **Inventory** step and bounds
  Combine by `allowed_boards`, `max_dev_boards`, `max_breadboards` — the walkthrough feeds exactly those.
- **Display mechanics**: pages are `_page/_tab/_table` seeds (`polariApiServer/module_pages_seed.py`); a row action = one POST/PUT with
  `{field}` fill + optional scope/rev bump; display item kinds = graph|table|component|container|text|metric|form|button; display types
  include `popup` (modelled, used by no page). **No card grid, no picker modal, no generic stepper** (closest precedent:
  `pipeline-setup-panel`, a bespoke setup walkthrough with step tags). Rule kept: no raw JSON; panels are configured definitions; new
  generic display KINDS are fine, page-specific components are the thing to avoid.

## 2. The walkthrough (`/display/workbench`) — four steps, each a configured panel; a step strip shows where you are
| step | what the person sees | what it writes / reads |
|---|---|---|
| 1 **Name the bench** | a form (title, notes) + the list of existing benches as cards (pick one to continue instead) | `POST /api/board/benches` (new door: create) → scope `bench` |
| 2 **Breadboards** | a **Breadboards** button → pop-up of breadboard CARDS grouped by kind (full / half / mini / bus strip / unverified). Each card: tie points, rows, rails (count + holes), **rail power** (cited rating or "unverified"), outline mm, geometry status, and **"fits:"** one line per dev board on the bench or in the picker — *UNO: beside the board (shield headers, not breadboard pitch)* · *Feather M0: straddles the trough, N free holes each side* · *this board: too wide / not enough rows*. "Add" on the card. | `GET /api/board/bench-options/breadboards?bench=` (gains `fit_json`, `rail_power`), `POST …/breadboards` |
| 3 **Dev / eval boards** | a **Boards** button → pop-up of board CARDS with three facet rows at the top: **architecture** (RISC-V · not RISC-V, the largest split, then AVR / ARM / Xtensa / FPGA), **wireless** (none · Wi-Fi · BLE · 802.15.4/Thread · LoRa, each chip with *pre-certified module* badge + the cert IDs when cited, else "uncertified / unverified"), **level** (Bare-C · FreeRTOS · Zephyr, from the chip's levels with the basis shown). Card: title, chip + family + core, levels, radios + cert, on hand, testing word (real pins / stub / hardware only), price if cited. "Add". | `GET /api/board/bench-options/boards?bench=&arch=&radio=&level=` (facets as query knobs; new columns `radios_json`, `cert_json`, `levels`), `POST …/boards` |
| 4 **Mission** | a **Missions** button → cards of existing Missions (goal, Purposes with importance, today's verdict if any) + "write a new one" (goal + pick Purposes from the CapabilityDefinition list — mis-1 keeps the shape). Then **"Attempt on this bench"**: the verdict panel — *meets* with the candidate (boards chosen, pin assignment summary, score) or *closest + gap* (unmet Purposes, nearest existing piece), plus the pruned branches with reasons. Links: pin view of the candidate, the Mission's drawing. | `POST /api/board/benches/<b>/attempt {mission}` (new door: wraps `solve` with limits = the bench's boards / breadboard count / on-hand) → a run row; `GET /api/missions` |

The step strip is a generic display item (`steps`): ordered step names + which are done (derived from scope: a bench exists → 1 done;
it has ≥1 breadboard → 2; ≥1 board → 3; an attempt row → 4). Steps are not locked — a person can jump — but the strip says what is missing.

## 3. Facts to add (derive or cite; nothing retyped from memory — `derive-or-cite-chip-data`)
- **Breadboard fit** (pure function `breadboard_fit(footprint, breadboard)` in pv_shapes or a new `bench_fit.py`): a breadboard's trough
  is 3 pitches wide with 5 tie points each side (standard; cite one vendor drawing per model or mark `unverified`). A two-row board with
  row spacing S pitches straddles when 3 ≤ S ≤ 11 (free holes per side = (13 − S)/2, floor); length fits when pins-per-row ≤ rows.
  Boards with shield headers / non-0.1" rows (UNO R3) → "beside the breadboard". Needs a **footprint per board**: `footprint_json`
  {rows: 2, row_spacing_pitches, pins_per_row, pitch_in: 0.1, straddles: bool, basis} on the ladder's boards_json entries (cited from each
  vendor's mechanical drawing; `unverified` otherwise).
- **Rail power**: `rail_voltage_max_v`, `rail_current_max_a` on BreadboardModel with `basis` — vendors rarely publish; where none → -1 +
  "unverified" (never a typical number). BUD and the 400/830 generic boards: look for the vendor's contact rating; cite or refuse.
- **Wireless + pre-certification**: `radios_json` [{kind: wifi|ble|802.15.4|thread|lora|none, module: 'ESP32-S3-WROOM-1', precertified:
  {fcc_id, ic, ce: bool}, basis}] on the ladder boards_json entries (the Elecrow board: module brand still unread → `unverified`; the C3
  DevKitM-1: ESP32-C3-MINI-1 module cert IDs are published by Espressif — cite the page). Non-wireless boards: kind none.
- **Level per board**: derived — the chip's levels_json × the board's RuntimeProfile (supported/refused) → bare_c / freertos / zephyr with
  the stronger basis; shown on the card, never re-stated.

## 4. Slices (each its own branch off dev; backend proven by selftests now, Chrome pass in the isle when it is up)
| # | slice | who | proves |
|---|---|---|---|
| a | **wb-0** the facts + fit + doors | Claude (framework, dev-wb-0) | BreadboardModel rail power fields; `footprint_json` + `radios_json` on ladder board entries (cited/unverified); `breadboard_fit`; bench-options doors carry `fit_json`, `rail_power`, `radios`, `cert`, `levels`, facet query knobs; `POST /api/board/benches` (create) and `POST …/<b>/attempt` (wraps solve with bench limits, stores a run row); board selftests (fit cases: UNO beside, Feather straddles, a 1.0"-row board refused on a mini) |
| b | **wb-1** generic display kinds | Claude (angular, dev-wb-1) | `cards` item (rows → cards: title/subtitle/badges/fields/action, grouped by a field, facet chips from query knobs), `button` item opening a `popup` display (the picker), `steps` item (step strip from scope); Karma specs; tokens for card/badge/facet colours in both themes |
| c | **wb-2** the page | Claude (framework page seed, dev-wb-2) | `/display/workbench` = the four steps above as configured panels; home-bench round trip; attempt on the light Mission: *meets* with uno-light-sense-poll (as mis-0 proves today) and the Elecrow board listed as "hardware only / no twin" in the gap when chosen |
| d | **wb-3** converge | after mis-1a | the attempt door becomes the Mission's Inventory + Combine steps; "write a new one" becomes the Mission form; cards reused by `/display/bench` (which then retires into the walkthrough) |

## 5. Decisions (his; my recommendation first)
- **D-wb-1** cards + pop-up picker + step strip as GENERIC display kinds (recommended: three reusable item kinds, no page-specific
  component) — or one bespoke `workbench-walkthrough` component.
- **D-wb-2** board facets fixed to architecture / wireless-with-cert / level, with an explicit "unverified" bucket in each (recommended) —
  or free facets from any column.
- **D-wb-3** "is a mission possible" = the mis-0 `solve` wrapped with the bench's limits NOW, migrating into the Mission's Inventory/Combine
  steps at mis-1 (recommended; nothing waits on D-mis-1..9) — or wait for mis-1.
- **D-wb-4** breadboard power: cite a vendor rating or show "unverified" (recommended; the derive-or-cite rule) — or show a typical value.
- **D-wb-5** step 4 authoring: pick existing Missions only in wb-2, authoring arrives with mis-1 (recommended) — or a minimal goal+Purposes
  form now.

## 6. Rules this plan keeps
No raw JSON on screens; new kinds are generic display kinds; every number derived or cited (`unverified` is an honest value); test node =
the isle (TEST_ISLE_PLAN); branch per confirmed phase; no deploys for now ([[dev-focus-no-deploys]]).
