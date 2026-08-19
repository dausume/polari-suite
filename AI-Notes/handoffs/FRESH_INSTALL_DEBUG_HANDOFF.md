# Fresh-install debug — ✅ RESOLVED 2026-08-19: core-install FULL GREEN

**Final state:** `sudo isle core-install` runs ALL 7 STEPS GREEN on a
genuinely fresh isle-core, from pure code (clone → bootstrap → pol node
build → build-polari-isle-deb → apt install → core-install). polari is
LIVE on the isle (https://polari.isle), apt.isle serves the four
from-code debs, the CA self-mints, security check passes. Six findings
were fixed at source across the exercise:

1. polari-shell-core never built from code (bundle builder step 2)
2. router-init packed-script lib path (pack.sh part homes)
3. set-e-silent avahi/dbus + ssh-keygen steps (if-wrapped, UCI→conf
   fallback)
4. no isle CA on a fresh box → `isle certs init-ca` (self-contained
   root+intermediate minted at install; core-install step 2 mints)
5. stale ~/polari-isle die-guard + sudo $HOME (deploy seeds from the
   versioned sub-project into the INVOKING user's home)
6. apt-repo publish only knew hand-staged ~/polari-shells (now also
   .generated/debs)

**Remaining (Dustin, tonight):** the GUI pass — on isle-core the agent
now runs, so the store icon opens the store DIRECTLY (the first-open
two-doors dialog only shows on agent-less devices); verify the store
window + hub. Optionally the round-trip proof: `sudo isle uninstall
--everything` (typed 'delete the isle' — it's a core) → `--verify`
zeros → rerun the install from the same checkout.

---
(Original debug notes below, kept for the record.)


**Date:** 2026-08-19 · **State:** mid-exercise. Dustin is proving the
clean-slate developer flow (GETTING_STARTED_DEV.md) on isle-core after
the FULL 3-device purge (2026-08-17). Everything up to `isle
core-install` step 1 is PROVEN; the router VM build is the live
failure frontier. Dustin resumes next session.

## What is already PROVEN on the fresh box (do not re-litigate)

1. `git clone --branch dev` + `./bootstrap-dev.sh` — all 5 sub-projects
   pulled on dev (note: first run silently did nothing for Dustin; ran
   fine over ssh — cause never found, watch for it).
2. `pol node build backend frontend` — images built from code.
3. `./build-polari-isle-deb.sh` — all FOUR debs from code (finding #1
   fixed: polari-shell-core, the shared JavaFX runtime, was only ever
   hand-staged; now built by step 2 of the builder, needs jpackage) +
   the end-of-build install offer works (4 packages installed).
4. **The app route works flawlessly**: store icon → first-run dialog
   (two doors) → "Create my own isle" → polkit → core-install runs.
   Verified via journal.
5. Finding #2 fixed at source: `router-init.sh` lib-path bug — the
   pack.sh-inlined 50-vm.sh resolved `../../lib` against the wrong
   home (repo root, no lib/ there). Old routers predated the packed
   form; a fresh box was the first to execute it. Fixed (tries ./lib
   then ../../lib), regenerated, PUSHED (Isle-Mesh 996c9eb).

## Resume point (exact)

On isle-core:

    cd ~/polari-suite/Isle-Mesh && git pull origin dev && cd ..
    ./build-polari-isle-deb.sh      # rebuilds CLI deb (0.1.116), say yes
    # then: Isle App Store → "Create my own isle"   (or: sudo isle core-install)

## Next likely failure points, in order (fresh-box firsts)

- **Router image fetch-or-build**: the purge deleted the pristine
  OpenWrt images; `40-image.sh` / get-router-image.sh must fetch or
  build one from scratch — first real run of that path on this box.
  (Deb EXCLUDES images by design — artifact-hygiene rule.)
- **core-install step 2/7 "isle CA"**: dies if `/etc/isle-mesh/ca/
  isle-root.crt` is absent; a genuinely fresh box has never minted
  one. If it dies here: wire CA issuance (security/ machinery) into
  `isle create` or core-install — at source, not a hand-mint.
- Step 3/7 prf-isle deploy now SEEDS ~/polari-isle from the versioned
  polari-isle/ sub-project (never run on a truly fresh box; the seed
  logic itself was tested in isolation).
- Step 7/7 security walkthrough on a box with no polari checkout
  creds — should pass creds cleanly (tested shape) and ask the
  provider question.

## Debug pattern that worked (use it)

- Dustin's error capture file may be empty — gather evidence directly:
  `ssh isle-core` + journalctl grep pkexec/isle, `docker ps -a`,
  `sudo virsh list --all`, then RE-RUN the failing step headlessly to
  capture stderr (e.g. `sudo bash /usr/share/isle-mesh/openwrt-router/
  scripts/router-init.sh` or `router.sh init`).
- Fix at SOURCE in the suite's Isle-Mesh submodule (it IS the working
  copy now), regenerate packed artifacts (pack.sh), commit, push
  Isle-Mesh then suite pointer, then on isle-core: pull + rebuild deb
  + reinstall. The deb rebuild is fast (~seconds; jpackage runtime is
  skip-if-built).

## Standing context

- All 3 devices were purged 2026-08-17 (backups in
  ~/polari-purge-backup-2026-08-17 on pol-core, incl. isle-core copy).
- The uninstall lifecycle (unin-0..7) is BUILT and rides these debs —
  after install succeeds, the round-trip proof is:
  `sudo isle uninstall --everything` then `--verify` (zeros).
- polari-app-shell is PUBLIC now; suite default branch stays `main`
  (clone with `--branch dev` — Dustin's explicit call).
- Bigger arc: AI-Notes/plans/POLARI_SYSTEMS_ORG_PLAN.md (pub-0
  evidence + deploy-time security). Blockers owned by Dustin: staging
  KC rotation (`pol security rotate staging`), DNS-at-DO + DO token +
  droplet.
