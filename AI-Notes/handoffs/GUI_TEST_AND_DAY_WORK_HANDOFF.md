# Handoff — Dustin tests the GUI install AT NIGHT; the session works
# the arcs THROUGH THE DAY

**Date:** 2026-08-20 · **Shape of the next iteration (Dustin's
instruction):** he runs the isle-core GUI install test TONIGHT or the
upcoming night (he started today, ran out of time — the box is
untouched past the clone); the next session does arc work throughout
the day, and folds in his test findings when they arrive.

## isle-core state (verified 2026-08-20, after the unin-6 round trip)

- **Fully purged via `isle uninstall --everything`** — the unin-6
  PROOF PASSED: core-cascade warning + typed-confirmation knob,
  destroy, network handback, volumes backed up
  (/var/backups/isle-mesh-purge-20260820-*), packages purged,
  `--verify` ZERO footprint. Two live findings fixed at source during
  the round trip (#7: resolved left a wifi link with no DNS scope —
  handback now ends with `nmcli device reapply`; plus the generic
  base images note). Earlier same-day: core-install reached FULL
  GREEN (findings #1-#6, see FRESH_INSTALL_DEBUG_HANDOFF.md).
- **Fresh clone at `~/polari-suite`**, dev tip b189f95, bootstrap NOT
  run — the box sits at step 0 of GETTING_STARTED_DEV.md. No pol, no
  images, no debs, no /etc/isle-mesh, no VMs.

## Dustin's night test (his exact steps)

    cd ~/polari-suite
    ./bootstrap-dev.sh                # Yes to the pol CLI
    pol node build backend frontend   # slow step
    ./build-polari-isle-deb.sh        # Y to the install offer

then GUI: open **Isle App Store** → expect the FIRST-RUN dialog
(agent-less box): "Create my own isle" / "Join an existing isle" /
"Just browse" → Create my own isle → polkit prompt → terminal runs
core-install (7 steps; router VM ~5-10 min; CA self-mints; the
security walkthrough asks its questions at step 7) → Enter → the
store window opens; https://polari.isle = the hub.

**Everything up to the click is machine-proven** (core-install ran
full green headlessly). What only Dustin can certify: the dialog
appears with the right wording, polkit flows smoothly, the terminal
window opens/closes properly, the store lands on the live isle.
If it fails: gather evidence directly (journalctl grep pkexec/isle,
docker ps, tail the terminal output) — his error-capture files have
arrived empty twice; don't rely on them.

## The day work (next session's queue, in priority order)

1. **React to any test findings first** — fixes at source, the
   iterate pattern from FRESH_INSTALL_DEBUG_HANDOFF.md (fix in
   suite's Isle-Mesh → pack.sh if router parts → push → pull on
   isle-core → rebuild deb → reinstall).
2. **Nutrition arc (nmp)**: plan is at decisions 1-14, phases
   nmp-0..11 (AI-Notes/plans/NUTRITION_MEAL_PLANNING_PLAN.md, memory
   nutrition-meal-planning.md). Status PLANNING — Dustin has been
   actively refining it (5 design messages on 2026-08-19/20), so
   likely next: either MORE design refinement as he sends thoughts,
   or his go-ahead to START BUILDING nmp-0 (data adoption: FDC
   subset, DRI/UL transcription, DGA limits, MET table, retention
   factors — all seeds cited+versioned; fork-pins). 5 open questions
   pend: wger mine-vs-run, URL import timing, trajectory horizon +
   privacy, Q5 pattern fractions.
3. **pub arc remaining** (polari-systems.org): Dustin-owned blockers
   unchanged — staging KC rotation (`pol security rotate staging`,
   with him present), DNS-at-DO + DO_API_TOKEN + droplet. Ours when
   those land: pub-1 compose profile + BASE_DOMAIN prod threading.
4. **unin-4** — ✅ BUILT + MERGED TO dev + PUSHED 2026-08-20
   (Dustin's go-ahead): Isle-Mesh `isle store uninstall` verb,
   polari-app-shell store.uninstall/store.removeIsle bridge +
   terminal opener, polari-rf-node/angular two Q2 buttons +
   remove-isle footer, suite pointers + plan (dev-unin-4 branches
   kept as snapshots). Java :core tests + ng build green; verb
   negative-paths tested. REMAINING: GUI pass + positive path on a
   live isle — rides the isle-core round after the night test; the
   CLI deb picks the verb up on the next rebuild (whole isle-cli
   dir is copied; no pack step).

## Standing context for a fresh session

- Everything is PUSHED to GitHub dev across all repos (suite tip =
  handoff commit). The suite checkout on pol-core is the working
  copy for Isle-Mesh too (isle-core's ~/Isle-Mesh is GONE — purged;
  the suite submodule is the only working copy now).
- Memory index: polari-systems-org (pub arc + install exercise),
  nutrition-meal-planning (nmp), public-repos-hygiene (KC rotation
  procedure). AI-Notes/ structure: plans/ handoffs/ evaluations/
  designs/ ledgers/ guides/.
- isle-core has passwordless sudo over ssh — the headless iterate
  loop works end to end from pol-core.
