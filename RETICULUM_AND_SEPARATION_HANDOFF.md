# Handoff — the Reticulum arc SHIPPED, App Separation PLANNED
# (2026-08-13..15)

Two sessions' worth in one arc: Reticulum went from planning-only to
deployed-and-radio-proven (ret-0..ret-1g + the map simulators), and
the next arc — Polari App Separation — is FULLY PLANNED with zero
open questions. This file is the map; the detail lives in the plans
and memory.

## 1. START HERE for the next arc

`POLARI_APP_SEPARATION_PLAN.md` — **FINAL, 11 decisions ledgered,
zero open questions** (Dustin answered everything 2026-08-14). Do
not relitigate the decisions table. First move = **sep-0**: the SPA
single-app clamp (`AppsNavService.lockedApp` + `?shellApp=` +
gating three chrome sites), acceptance-tested in a PLAIN BROWSER
(`?shellApp=app-archipelago`) before any shell work. The plan's
Grounding Index names every file each phase touches — it was
surveyed, not guessed.

Branches: framework/rf-node/cli/angular sit on `dev-ret-1` (stacked
dev → dev-dyn-1 → dev-mtg-1 → dev-ret-1). Cut `dev-sep-1` from
`dev-ret-1` per the branch-per-phase rule. ⚠ `polari-app-shell` is
on `dev-scan-1` and the SUITE's pointer to it has sat MODIFIED since
before these sessions (the scan arc's — deliberately never
committed by us). sep-1/sep-2 touch that repo: resolve the pointer
question with Dustin before committing there.

## 2. What the Reticulum arc left LIVE

- **Staging (pol-core)**: backend + frontend carry the full
  reticulum module (13+ classes, /arch page with planner + peers +
  loadouts + scenarios). ⚠ **the module needs a re-ADMIT (~2 min,
  `POST /modules/reticulum/admit`) after every backend service
  roll** — admit state does not survive; boot-derivation from
  assignment rows is the named fix, unbuilt.
- **pol-reticulum sidecar**: running, TCP-only, identity
  `765aa9a9…` persisted in its named volume (= THE ISLE IDENTITY —
  §5r flashes it as device owner). Lighthouse + delta broadcasting +
  announce listener live in it.
- **econ-core probe**: `pol-reticulum-probe` container announces
  every 60 s into the peers panel (identity `7e156b5f…`,
  UNADJUDICATED — waiting to be Dustin's first KC-authed
  adjudication). Teardown: `ssh econ-core docker rm -f
  pol-reticulum-probe`.
- **The SH-L1A radio pair**: configured PERSISTENT to 915.125 MHz /
  62.5k air / 115200 UART (Dustin's recorded TX approval), catalog
  row `dsd-tech-sh-l1a` carries everything learned. **Radios are
  DARK** (row 19: idle = silent; every rig torn down after its
  proof).

## 3. The rules this arc minted (do not re-learn)

1. **Licence pins are licence pins**: `rns==0.9.4` + `lxmf==0.6.3`
   (last MIT releases; upstream relicensed 2025-04-15,
   GPLv3-incompatible). RNS imports exist ONLY in the sidecar —
   the process boundary IS the licence boundary, selftest-pinned.
   🔑 the pin is WIRE-STRANDED from RNS ≥1.0 (AES-128 removed);
   RetiNet (AGPL-3.0) is the gated exit when third-party interop
   matters. microReticulum = Apache-2.0-clean, watch-don't-bet
   (§5r two-track).
2. **Never transmit without confirming legality** (the pair SHIPPED
   on 873.125 MHz, outside US ISM) + **idle radios are silent**
   (announces are TX; row 19). Both are code (`tx_permitted`,
   `idle_policy`) and memory.
3. **Devices are catalogued with evidence** (DeviceModel: vendor/OEM
   lineage, openness, interop, restrictions, setup steps, prices
   dated); wifi devices carry the ASSIGNMENT knob
   (unassigned default | reticulum | onboarding-ap | 3 dual
   flavors) + measured ap/ap-sta facts (pol-core's MediaTek:
   both YES, same-channel ≤2 ifaces — and it is currently the box
   UPLINK).
4. **Isle-core hosts the core+OpenWRT**: upgrades prove on a member
   first, isle-core last; its Claude gets provenance notes for
   cross-instance edits (pattern used twice: CLI 0.1.23/0.1.24,
   hosts-reconcile).
5. **The core cannot hairpin its own macvlan**: hosts-reconcile
   (CLI 0.1.24) now pins core-served .isle domains to loopback as a
   RULE on the self-feed timer — that was the "store broken on
   isle-core" mystery.

## 4. Owed / waiting on Dustin

`TESTING_OWED.md` is current. Headlines: the meetings-arc human
tests (unchanged); /arch browser pass (planner on a real drawn
shape, scenarios, cohorts, antennas); the FIRST KC-authed peer
adjudication (econ-core is live in the panel); §6 + licence-pin
assumptions standing confirmed-by-use but never formally; SH-L1A
price approximate. Reticulum module remaining phases: ret-3
packet-plane mapper (wants the router half from
`RETICULUM_ISLE_CORE_REQUEST.md`), ret-5 gRPC deltas, link-
authenticated lighthouse returns, metered app demand, listing
endpoints for the planner's hardcoded pickers, ret-9 real distance.

## 5. Memory map

[[reticulum-transport]] (the whole arc, dense),
[[polari-app-separation]] (the next arc, final),
[[no-tx-without-legality-check]], [[other-machines-ssh]] (isle-core
care rule), TESTING_OWED.md + the two plan files at suite root.
Isle-Mesh-side provenance lives in isle-core's own Claude memory
(wifi-ap-tooling-dep.md there).
