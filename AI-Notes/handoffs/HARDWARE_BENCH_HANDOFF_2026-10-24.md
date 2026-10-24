# Hardware bench + Mission arc — handoff 2026-10-24

Supersedes `HARDWARE_BENCH_HANDOFF_2026-10-20.md` for the state; that file keeps the history. Written under the operating rule of
2026-10-24 (memory `operating-mode-token-split`): checkpoint at milestones, write the handoff, tell him when to clear.

## STATE AT HANDOFF (fill the live/test-node lines when the roll is done)

**Branches (all pushed):**
- framework `dev` = 657c2bd (= dev-bench-1-bud ff onto f8eef26, pushed 13:20): the BUD BB-32650-W row is now CITED — 170 tie points (not 70: the DigiKey title drops the 1), kind mini, 17 rows, no rails, stated outline 47.0 × 36.1 mm from BUD's product page + DigiKey attributes (BUD publishes no PDF); `geometry_known` stays False because `breadboard_geometry` always reserves rail bands (51.8 mm tall vs 36.1 stated) — a generator debt; local board suite 1030/1034, misses = the four `smp S5` C3 twin checks only
- f8eef26 (before that) = dev ⊕ dev-pv-bench (4e82acd) ⊕ dev-chip-ladder (e76e3c5, rebased on pv-bench) ⊕ dev-smp-2
- angular `dev` = 4cbebf4 (= dev-aut-1-colour ff onto b35d85c, pushed 12:55): the aut-1 COLOUR HALF — `code-block` takes `identifiers` from the `/code` door, whole-word spans per kind + legend chips, `--code-kind-*`/`-text` tokens in both themes; Karma 5/5, tsc clean, `ng build` ok; NOT seen in a browser yet (test node) — add the C-function-atom page to the Chrome list
- cli unchanged; suite superproject pointers NOT yet moved (do it after the live roll, innermost-first)
- worktrees in the session scratchpad: `fw-smp2` (dev-smp-2, clean), `fw-chips` (dev-chip-ladder, clean) — remove with `git -C <framework> worktree remove --force <path>` after the roll

**Suites:**
- local board suite on each branch: pv-bench 59/59 (its own), chip-ladder 1027/1031, smp-2 990/994 — the misses are ALWAYS the four `smp S5` ESP32-C3 twin checks (no QEMU engine image on pol-core; they pass on isle-core)
- cmod on isle-core at dev-smp-2: 1373/1373 · apps 131/131 local
- ✅ isle-core board+cmod at merged dev f8eef26 (read 12:45 on 2026-10-24): board 1033/1033 · cmod 1373/1373 — owed #1 DONE; the two scratchpad worktrees removed

**Devices:** isle-core up (engines :9830..:9870). **econ-core (test node) POWERED OFF** at 10:49 on 2026-10-24, still off at 12:45 ("No route to
host" on 192.168.0.66) → the test-node deploy + Chrome check cannot run until it is on; the live roll (owed #3) is HELD behind it per the
test-node-first order — his call to roll live without it. pol-core live swarm untouched since 2026-10-20 (main == dev then).

**Built today (all on framework dev now):**
- pv-6 pins view: the breadboard drawn behind the bench parts (`pv_shapes.breadboard_geometry`, `pin_view_model._bench_board`, Angular `drawBreadboard`), parts labelled outward by column half
- smp-2: 26 cmod + 4 board expectations follow the polled sense line (`apps/light.sense_poll`)
- chp-0/chp-1: `/display/chip-ladder` — RISC-V sample (2 chips per level) apart from the convenience boards; testing split SIMULATED real pins / STUB / HARDWARE ONLY; Emulators tab
- bench-0: `/display/bench` — Bench + BreadboardModel rows, two selection panels (configured tables with Add-to-bench / Remove row actions); seeded home-bench from his bench photos (part names only)

**Owed, in order:**
1. isle-core suite green at f8eef26 (read the log tail) — fix any drift ON dev, re-run
2. test node: `pol deploy run econ-core --role node` (needs econ-core ON; backend boot ≈15 min) → Chrome: `/display/pin-view` (breadboard behind ubc-led1/r1/sw1), `/display/chip-ladder` (three tabs; the HARDWARE ONLY tables), `/display/bench` (Add to bench round-trips)
3. live roll (recipe in memory `hardware-bench-convergence`): `pol node build backend frontend --env staging` on pol-core → `docker service update --force --image prf-backend:staging polari-node_backend` (+ frontend) → `/health` 200 → Chrome on live → ff `main` in all five repos → push → superproject pointers (innermost-first) → push
4. ✅ C-atom code colouring by kind BUILT (angular 4cbebf4, see Branches); its Chrome check rides with owed #2; the plain-name toggle (§10.1) waits for `CAtomInput` (aut-0)
5. then: the Mission arc on his D-mis answers (plan §7, §9.2, §10.6, §11.5, §13.1) — mis-1a first (nothing visible changes)
6. kit register rows for the bench: ✅ the BUD BB-32650-W row cited (framework 657c2bd); the SAMD21 boards are already Bench rows (arduino-zero, adafruit-feather-m0-express); STILL OWED: the ESP32 eval board's module (needs his photo of the silk) and the Starter Kit breadboard's count; generator debt: `breadboard_geometry` should omit the rail bands when rails = 0 so mini/BUD boards draw at their true height
7. Codex (isle-core): CX-001 / CX-002 still UNACKED in pol-core `~/collab/codex-mailbox/inbox/` at 12:45 on 2026-10-24; my isle-core inbox empty. pol-core now has sshd; the forced-command path from isle-core was failing on an unknown host key — fixed (keyscan into detts' known_hosts), `ssh pol-core-mailbox list` works from isle-core. Nothing to do until Codex acks.

**Open decisions (his):** D-mis-1..9, 10..14, 15..19, 20 (buy a C3 DevKitM-1), 22..26 — all in `AI-Notes/plans/MISSION_GENERIC_PLAN.md`;
D-mis-21 RULED (own C3 twin as module `c3twin`; esp-emulator re-base recommended as D-mis-21b).

## What changed in how we work (2026-10-24)
Memory `operating-mode-token-split`: even Fable / non-Fable split (Fable = decisions, ssh/deploys/merges, Chrome; Sonnet = bounded verifiable
chunks — today: the smp-2 L7 drift + suites, 56 k tokens, 12 tool uses, correct first time); token hygiene; checkpoint at milestones; this
handoff; "clear now" said plainly when the context is heavy.
