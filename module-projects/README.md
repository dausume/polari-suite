# module-projects/ — batched commands for the mp-2/mp-4 switchover

Small, auditable batch scripts for **Dustin to run** — they carry the
git / GitHub / deploy commands the plan reserves for a human (public
repo creation, pushes, history-splits, wave moves). Every
state-changing command is echoed before it runs; scripts stop on the
first failure; destructive/irreversible steps ask for confirmation.

Prepared 2026-07-18 alongside the mp-2/mp-3 prep code
(see `MODULE_PROJECTS_PLAN.md` STATUS block). The prep that is
ALREADY BUILT and these scripts rely on:

- **mp-3 lazy core** — polariServer's 113 feature-module imports sit
  in 30 guarded blocks; absent code stubs (SEED_* → `[]`, classes →
  `None`), endpoints gate on `feature_available`, `/modules` says
  "not downloaded — pol modules get <m>". Drift guard:
  `python3 -m moduleService.selftest_lazy_imports` (15 checks).
- **register** — `modules/polari-modules.json` now lists ALL 20
  feature modules with `wave`, `requires`, `required_by_core`.
- **CLI rails** — `pol modules publish <m> [--repo url]` (subtree
  split + push, prints its git), `pol modules register <name>
  [--vendor url|--path p|--repo url]`, get/drop with
  requires/required_by_core refusals, sizes in `pol modules registry`.

## Order

| Script | What | When |
|---|---|---|
| `00-preflight.sh` | read-only checks (gh auth, clean tree, stack up) | first, and any time |
| `01-split-already-moved.sh` | biomining + microalgae → their own PUBLIC repos | once, after review-gate commits land |
| `10-wave.sh <1..6>` | move that wave's modules into `modules/`, commit on `dev-mp-4-wave-N`, rebuild staging backend, selftests | one wave at a time, in order |
| `20-split-module.sh <m>...` | PUBLIC repo + subtree push + register repo field for moved modules | after each wave (or batched later) |
| `90-verify-all.sh` | full paint: registry, drift guard, all module selftests, /modules API, boots-without-biomining proof | after anything |

Waves (from the register — the runner reads them from there):

1. nutrition, tanks, plant_morphology (pure leaves)
2. waxsupply, supplychain, dmvdata
3. mathshapes, electrodevice, hwdigital, hwfpga
4. zones, xr — *xr stays `required_by_core` (drop refuses)*
5. aquaponics, grpcbridge, resources — *resources stays `required_by_core`*
6. waxprint, scoring, techtree, polariapps, testing (deep
   polariServer coupling — mp-3's lazy imports are what make this
   wave legal; it runs last by design)

## Ground rules baked into the scripts

- **PUBLIC repos** ([[public-repos-hygiene]]): every
  `polari-module-*` repo is public; module code carries no secrets —
  keep it true.
- **Overlap period**: after a split the in-tree copy stays
  AUTHORITATIVE; `pol modules publish` re-pushes it. `pol modules
  drop` correctly refuses while the copy is tracked in-tree.
- **Staging gotchas** (both hit before, both baked in): rebuilds
  always use `--env-file .generated/.env.staging` (else MariaDB 1045
  at boot) and restart `pol-proxy` after a backend recreate (else
  502 from a stale nginx upstream).
- **Commit discipline**: innermost-first — each script prints the
  rf-node + suite pointer commits to run once the wave is confirmed.
- **Cross-module requires** (encoded in the register): aquaponics →
  plant_morphology+scoring; dmvdata → scoring; mathshapes →
  aquaponics+plant_morphology; electrodevice → hwdigital; zones →
  scoring. Drop order must respect these; `pol modules drop` refuses
  violations honestly.
