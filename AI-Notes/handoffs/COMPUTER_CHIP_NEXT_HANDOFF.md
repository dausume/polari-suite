# Next-session handoff: computer composition ∥ microchip (2026-08-25)

Entry point AFTER Dustin's dev push of the downloads arc.
Governing plan (READ FIRST): AI-Notes/plans/COMPUTER_COMPOSITION_PLAN.md
— PLANNING RATIFICATION PENDING (his 4 decisions at the bottom).

## The ask, verbatim-close

Continue microchip functionality AND, in parallel, computer
composition as its OWN app — assembly + components SEPARABLE from
microchip creation/levels. Components: storage (HDD/SSD), graphics,
RAM, etc. Computer PROFILES per use-case: standard user ·
assistive-AI dedicated · high-capacity storage bound to dedicated
databases · FPGA · more as data. Assess against what exists.

## Where to start

1. Get his answers to the plan's 4 decisions.
2. cmp-c-0 survey (computerparts + composition seams) on
   dev-cmpc-1; chip-1 (F3 Poisson) on dev-chip-1 — parallel
   branches, separate modules, never crossed.
3. Existing assets: modules/computerparts (ai-8 — dated parts,
   builds, assembly checks), modules/composition (arch — EBOM,
   derived levels, DFA gates, seed_upsert), cnt arc on dev
   (cntfet/microchip/hwdigital/hwfpga), dl-6 planner perf classes,
   ai-6 hosting gauge, object-ownership/databases arc for the
   DB-binding profile.

## Standing context

- Downloads arc dl-1..9 + off-1 machinery CONSOLIDATED on dev
  (framework 9d4e3cb, rf-node bb10455, Isle-Mesh a5a7667, suite
  dev) — his push via ./push-all-dev.sh (suite-root wrapper →
  polari-cli/shells/push-all-dev.sh) --with-isle --push.
- Preview server (threaded) http://192.168.0.210:8090/downloads.
- Gates untouched: framework dev-nmp-1 (nutrition), angular
  dev-cnt-2, dev-dyn-1 merge (unblocks dl-4 admit wiring).
- Dustin's open queue: TESTING_OWED item 18 (installs, browser
  passes), offline decisions 3+4, dyn merge.
