# Claude ⇄ Codex collaboration guide (cx arc) — 2026-10-23

Two AI instances now work the same forest, on two machines, with two kinds of hands.
This guide is the contract between them. Both read it; neither edits it without his word
(the decisions in §7 are his).

His words (2026-10-23): "codex is housed on isle-core and handling desktop app and blender/freecad/kicad
work, while you primarily focus on web, simulation core, and the core polari functionality which lives on
the docker compose side … you take responsibility for things that only need polari side logic, and codex
taking things that require desktop apps and/or testing the app-only logic and bridging."

## 1. Who is where, with what hands (read from the machines 2026-10-23)

| | **Claude** (pol-core, `user`) | **Codex** (isle-core, `detts`) |
|---|---|---|
| machine | pol-core = the live swarm manager, the home stack, Chrome | isle-core = engines host (5 hw-engine workers), KDE/X11 desktop, 809 GB free |
| checkout | `~/Desktop/polari-suite` (authoritative dev) | `~/polari-suite` (was 25 commits behind dev on 2026-10-23 — Codex must `git pull --ff-only` + `git submodule update` before reading code) |
| hands | web (Chrome via CDP + the Chrome tools), `pol`, docker/swarm, ssh → isle-core/econ-core | X11 desktop (`linux-desktop` MCP: screenshot/move/click/scroll/keys), Blender 4.x (`/usr/bin/blender`), FreeCAD 1.1.4 AppImage, JDK 21 (JavaFX apps), the engine workers locally |
| cannot | drive a desktop window (no X on pol-core for Chrome's sake only); open USB on the board from a container | reach pol-core (no sshd there); roll the live stack; push `dev`/`main` |
| notes/memory | `AI-Notes/` in the suite + Claude's memory dir | `~/AGENTS.md` (desktop rules), `~/food-forest-blender-assets/POLARI_PLANT_SIMULATION_MEMORY.md`, `~/.codex/sessions/` |
| rulebook | `CLAUDE.md` (root) | `AGENTS.md` (root, added 2026-10-23) → points at `CLAUDE.md` + this guide |

## 2. Ownership — who takes what

**Rule of thumb:** if the proof can run with `pol`, a selftest, a door, or Chrome against the compose/swarm
stack, it is **Claude's**. If the proof needs a window on a desktop, a desktop app's own behaviour, a
Blender/FreeCAD/KiCad GUI, or a USB cable on a host, it is **Codex's**. Shared rows and doors are designed by
Claude (the Polari object tree is one), consumed by Codex; Codex never adds object classes or doors — it
asks (§3) and Claude builds them.

| area | owner | the other side's part |
|---|---|---|
| Python/Falcon framework, modules, no-code, object tree, doors, selftests | Claude | Codex reports gaps as requests |
| Angular pages, displays, Chrome checks | Claude | Codex checks the SAME pages inside the desktop shell's embedded browser (JCEF) and reports differences |
| sim core: twin sessions, hosted bridges (`:9870`), SPICE, cmod, firmware builds | Claude | Codex may START sessions/bridges locally on isle-core for its desktop tests (`pol board twin session …`, `pol grpc hosted …`) and must STOP them |
| `pol` CLI verbs | Claude | Codex uses them; asks for new verbs (every by-hand gap-fill is a DEBT to wrap — his rule) |
| swarm / compose / deploys / live roll / `main` | Claude only | — |
| **polari-app-shell** `:desktop` (JavaFX + JCEF), `:android`, pipeline app, the Polari Firmware Installer (exp-2, not built) | **Codex** builds + tests the app side | Claude owns the registration document, `BRIDGE_CONTRACT.md` semantics, the backend doors they call; contracts change in lockstep by request |
| generated Java gRPC bridge (`grpcbridge`) — the GENERATOR | Claude | Codex runs the generated project on a desktop host, hosts it inside the app (brg-1/brg-3), reports |
| USB / serial / flashing on a real host; the bench UNO cable | Codex (the JavaFX app is THE hardware bridge on a host — his 2026-10-06 rule) | Claude's `pol board flash` through the engines image stays the developer path |
| Blender: plant growth assets, animation skeletons, renders | Codex | Claude owns the data model those assets must match (`aquaponics`, `plant_morphology`, `mathshapes/pot_scene`); Codex's record exports are checked against the live rows by Claude |
| FreeCAD / KiCad GUIs (pcb-1 onward, `mathshapes.cad_remote`) | Codex | Claude owns the KiCad WORKER on isle-core (`prf-pcb-engines`) and the rows it fills |
| desktop-app testing of the web UI (the shell's CEF frame) | Codex | Claude fixes what it reports |

## 3. The channel — files in the repo, nothing else

pol-core has no sshd, so Codex cannot call Claude; Claude can `ssh isle-core` but must not drive Codex's
session. The shared truth is the forest on GitHub (`origin`, `dev`). The channel is therefore **the mailbox
directory `AI-Notes/handoffs/codex/`**, the same provenance-note pattern the isle-core Claude requests used
(`*_ISLE_CORE_REQUEST.md`):

- `AI-Notes/handoffs/codex/README.md` — the ledger: one row per request (id, title, from → to, state, branch, date).
- `AI-Notes/handoffs/codex/CX-NNN-<slug>.md` — one file per request. Sections, in order: **Ask** (verbatim, who
  asked) · **Context** (plans, files, doors, rows — paths, not retyped) · **Done by the sender already** · **Owed by
  the receiver** (numbered, each with its PROOF) · **Rules that apply** (links to CLAUDE.md sections / memories) ·
  **Reply** (the receiver appends; never edits the Ask) · **Closed** (the sender writes when verified).
- States: `open → taken → replied → verified → closed` (or `blocked(<why>)`).
- Codex **pulls** before reading (`git pull --ff-only && git submodule update --init --recursive`), writes its Reply on a
  branch `codex/CX-NNN-<slug>` in the repo the work touched, commits innermost-first (submodule before pointer),
  **pushes the branch**, and sets the ledger row to `replied`. Codex never pushes `dev`, `main` or `test`
  (the same rule agents live under — a stale push once dropped nine commits from origin/dev).
- Claude reviews the branch, runs the suites that matter on isle-core (`pol deploy selftest isle-core --ref codex/CX-NNN-…`),
  merges to dev, deploys, sets `verified`/`closed`.
- Requests the other way (Codex → Claude) are the same file, with Codex as sender; Claude answers in-session.
- Anything that cannot wait for a pull: he carries it by mouth. No other side channel (no shared sqlite, no ssh into
  the other's session, no editing the other's memory files; READING them with provenance is fine).

**DEBT (his rule "every hand-applied rule becomes a `pol` verb"):** `pol collab request|reply|list|close` wrapping this
mailbox (consent, `--json`, journal) — slice cx-2 below, not built.

## 4. Git discipline both sides keep

1. Branch per request (`codex/…` for Codex, `dev-…` for Claude); innermost-first commits; force-add new `.json` data
   files in the framework (its `.gitignore` swallows `*.json`).
2. Codex works in its own checkout `~/polari-suite` on isle-core — never in `~/polari-suite-test-runs/*` (those are
   Claude's selftest worktrees, created and removed per run) and never in `~/polari-suite-test`.
3. Commit trailer: Codex adds `Co-Authored-By: OpenAI Codex <noreply@openai.com>` (mirrors the Claude trailer) so the
   log says which instance wrote what.
4. Standing rules bind both: privacy (no real hostnames/addresses/e-mails in tracked files — use `pol-core`,
   `isle-core`, `econ-core`), GPLv3 compatibility for anything vendored, no raw JSON on screens, no new chart engines,
   no new custom Angular components without the sanctioned-component note, derive-or-cite every number, reproducible
   initial conditions on every committed result, measured COST on every engine.
5. Codex's Blender assets (`~/food-forest-blender-assets`, 316 MB, not a repo) stay OUT of the suite; what enters the
   suite is the recipe/record JSON that matches the Polari rows + the small research notes. Whether the assets get
   their own repo is his (D-cx-3).

## 5. Testing split — how a feature gets proven twice

| layer | Claude proves | Codex proves |
|---|---|---|
| backend door / row | selftest + `curl` through the proxy | — |
| web page | Chrome on pol-core (CDP shots) against the test node (econ-core) or live | the same route inside `polari-app-shell :desktop` (JCEF) on isle-core: login once, the page renders, the actions hit the same doors — screenshot before/after |
| bridge | `pol grpc hosted start <session>` on the worker; the test node's row follows the twin | the generated bridge project run on the desktop host (`mvn`/jar), then hosted INSIDE the app (brg-1); the LightState row follows |
| firmware → board | the twin session (sim install), the four Purposes, the confirmed-sim gate | the real install from the desktop app over USB, only after the gate says so; read-back verified |
| CAD / assets | the KiCad worker's rows, `pol circuit`, the layout engine's nets | the GUI (KiCad/FreeCAD/Blender) opens what the worker produced; visual diffs reported |

Both record proofs the same way: a ScenarioRun / attested run where one exists (`proof_kind=attested` for a manual
desktop session — never auto-promoted, D-hbc-4), otherwise a dated note in the request file with the screenshot path.

## 6. Slices (cx)

- **cx-0 — the channel** (THIS, built 2026-10-23): this guide, the mailbox + ledger, root `AGENTS.md`, CX-001.
- **cx-1 — Codex's first pass**: CX-001 (hardware bench desktop side) — see the file.
- **cx-2 — `pol collab`**: the mailbox as `pol` verbs (request/reply/list/close, `--json`, journal, consent on push).
- **cx-3 — the app-session proof row**: brg-3's "app-session" ScenarioRun kind + the door Codex posts its desktop
  runs to (Claude builds; Codex consumes).
- **cx-4 — plant assets ⇄ Polari**: Claude reviews Codex's `baseline-v2` record exports against the live `aquaponics` /
  `plant_morphology` rows; the diffs become either a Codex fix or a Claude schema extension (seed_upsert, never a
  silent field).

## 7. Decisions (his to rule; defaults in force until he does)

- **D-cx-1** root `AGENTS.md` added (CLAUDE.md said the root keeps only README/GETTING_STARTED_DEV/CLAUDE.md). Default:
  keep it — it is the standard Codex entry point and only points elsewhere.
- **D-cx-2** may Codex push `dev` after Claude's review is automated? Default: **no** — Codex pushes `codex/*` only.
- **D-cx-3** where the Blender assets live (own repo `dausume/polari-plant-assets`? the file store?). Default: outside the
  suite, on isle-core, until he says.
- **D-cx-4** may Claude read Codex's `~/.codex/sessions` rollouts for context? Default: **read-only, with provenance**
  ("Codex session 2026-10-21 said …"), never edit, never quote his words from there as rulings (verify-attributed-rulings).
- **D-cx-5** who owns the Polari Firmware Installer (exp-2) when it starts: default **Codex builds the JavaFX app** from
  Claude's contract (doors `/api/firmware`, `/api/board/installer`, the gate); Claude builds the export directory (exp-0/1).
