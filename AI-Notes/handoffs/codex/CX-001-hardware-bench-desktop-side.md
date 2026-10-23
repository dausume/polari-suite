# CX-001 — Hardware bench: the desktop side

**From:** Claude (pol-core) → **To:** Codex (isle-core) · opened 2026-10-23 · state: **open**
Protocol: `AI-Notes/guides/CODEX_COLLABORATION_GUIDE.md` (read §2–§4 first).

## Ask (his words, 2026-10-23)
"codex … handling desktop app and blender/freecad/kicad work … codex taking things that require desktop apps
and/or testing the app-only logic and bridging." This request is the desktop half of the hardware bench arc.

## Context (paths, not retyped)
- Umbrella plan: `AI-Notes/plans/HARDWARE_BENCH_CONVERGENCE_PLAN.md` — §4 (brg-0..3), §6 (order), §7 (D-hbc-1..5), §10 (what the bridge already proved), §13 (status).
- Handoff: `AI-Notes/handoffs/HARDWARE_BENCH_HANDOFF_2026-10-20.md` — "Rules that bit this iteration" + "His bench".
- The app shell: `polari-app-shell/README.md`, `polari-app-shell/docs/BRIDGE_CONTRACT.md`, `polari-app-shell/desktop/` (JavaFX chrome + JCEF). Build: `./gradlew :desktop:run --args="--config <polari-shell.json>"`; the registration document comes from `GET /api/appstore/{shell}/registration?download=1` on the test node.
- Bridge app spec: plan §4 brg-1 (device picker: real USB devices + the simulated sessions from `GET /api/board/twins`; picking a session writes `bridge.properties` with `source=twin-tcp` and starts the hosted bridge in the app), brg-3 (an "app-session" run).
- Doors you consume: `/api/board/twins`, `/api/grpc/hosted-bridges`, `/api/board/installer/*` (gate, sim-confirmations, sim-install), `/api/firmware-state/{config}`. CLI: `pol board twin session start|stop`, `pol grpc hosted start|stop`, `pol board install --sim|--real`, `pol board gate`.
- Where to point: the TEST NODE on econ-core (ask him for its current URL; `pol suite urls` prints pol-core's). Never the live stack on pol-core for destructive actions.
- Engines run on YOUR machine: board worker `:9830` (sessions `:9832–9863`), bridge worker `:9870`. Their `/sessions` must list none when you finish.

## Done already (Claude, dev, live + main == dev as of 2026-10-20)
ins-0/1 (Sim|Real toggle + confirmed-sim gate), fst-0..2 (`/display/firmware-state?config=`), sim-0..3 (twin sessions, TcpDevicePort, hosted bridges, `/display/sim-bench`, `/display/layout`), lay-0..2. On branches, Claude's to merge this week: `dev-cst` (circuit states), `dev-smp-2` (the sense line).

## Owed by Codex (in order; each with its proof)
1. **Sync your checkout.** `cd ~/polari-suite && git pull --ff-only && git submodule update --init --recursive` (you were at suite 18fd70e; dev is f8327f3+). Proof: `git log -1 --oneline` matches origin/dev; `git submodule status` has no `+`.
2. **The shell renders the three bench pages.** Build `:desktop` on isle-core, register the test node, log in once, open `/display/firmware-installer`, `/display/sim-bench`, `/display/firmware-state?config=uno-light`. Proof: a before/after screenshot of each inside the JCEF frame (paths in your Reply); any difference from the web rendering listed as a finding (route, what differs). Do NOT fix Angular — report.
3. **brg-1 — the device picker in the shell's hardware screen.** Lists detected USB boards AND `GET /api/board/twins` sessions; picking a session writes `bridge.properties` (`source=twin-tcp`, host/port of the session) and starts the hosted bridge INSIDE the app (not the `:9870` worker). Branch `codex/CX-001-brg-1` in `polari-app-shell`. Proof: start a twin session of `uno-light` (`pol board twin session start uno-light --api <test node>`), pick it in the app, press the twin's button (`pol board twin session inject <id> set PD2 0` then `set PD2 1`, or the sim-bench overlay) → the test node's `LightState` row reads `source=button`; the page's light button → the twin's LED follows (`source=command`). Record both as a ScenarioRun `proof_kind=attested` if the door exists, else in the Reply with times. Stop the session after.
4. **The real-install path from the desktop.** With his UNO on USB at isle-core: `pol board gate uno-light --api <test node>` must say the sim is confirmed before you flash; then `pol board install uno --real --variant uno-light --dry-run --api <test node>` and, only when the dry run offers it, the same with `--yes`. If the gate refuses, STOP and report the words — never `--anyway`. Proof: read-back verified line + the installer document's `attest` for the hex.
5. **Reply here** (append a `## Reply` section: what passed, findings, screenshot paths, branch names, the sessions you stopped), flip the ledger row to `replied`, push `codex/CX-001-*` branches only.

## Rules that apply
- No push to `dev`/`main`/`test`; branch per request; innermost-first commits; force-add new `.json` in the framework.
- Java = BRIDGING ONLY (no compute/logic/persistence in the app beyond what the shell already does); JavaFX screens are the app's own UI, never configurable.
- No raw JSON on any screen you add; the shell is the frame — the UI IS the configured Polari page (D-hbc-5).
- Privacy: no LAN addresses in tracked files (write `<test node>`; the host names `pol-core`/`isle-core`/`econ-core` are fine).
- Desktop input: screenshot before and after; never approve your own prompts with desktop input (your `~/AGENTS.md`).
- Time-box every probe; record and move on; nothing left running (sessions, bridges, Blender).

## Reply (Codex appends below this line)

## Closed (Claude)
