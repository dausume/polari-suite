# Uninstall lifecycle — one teardown engine, three standard routes
# (unin-0..unin-6)

**Date:** 2026-08-17 · **Status: PLANNING (Dustin: automate the manual
purge so every edge case is handled by a normal/standard uninstall
route).** Grounded in the FULL 3-DEVICE MANUAL PURGE of 2026-08-17 —
every phase below traces to something we actually had to do by hand,
or a gap we hit live.

**The principle (mirrors install): TERMINAL-FIRST, ONE SHELL ENGINE,
three doors.** The engine is plain shell — the terminal way IS the
implementation. Every route invokes the SAME shells:
- privilege goes through **polkit** (`pkexec`) when a desktop session
  can prompt, `sudo` otherwise — the existing `sec_esc` pattern from
  the security walkthrough lib, so the flow is smooth both WITH and
  WITHOUT a UI;
- the UI performs no logic of its own — **the documentation states
  plainly that the UI just runs the same steps via polkit**;
- the per-scenario differences (core / remote-with-takeover /
  dev-hybrid, below) are NOT separate scripts — they are **variations
  and conditionals INSIDE the one engine** (detect the device's role:
  agent.mode core|remote, router VM present, swarm stack present,
  NetworkManager active — and branch), so every route handles every
  scenario identically.

## Ground truth — what the manual purge required, per scenario

The same "uninstall" meant meaningfully different work on each device
role. All of it must be automatic:

| # | scenario (device) | what existed | edge cases hit |
|---|---|---|---|
| A | **isle CORE** (isle-core) | router VM + bridges, vlan-agent, prf-isle polari, extra polari instances, apt-on-mesh server, registry, trust page, exposure doors, whoami/odoo demo apps, push + trust timers, CA + /etc/isle-mesh, hosts pins, dnsmasq split-DNS, iptables/avahi hardening | 🔑 `isle destroy --force` tore down agent+router but **left 9 app containers running**; bridge `br-my-isle` survived; deb purge left `/usr/share/isle-mesh/shells/debs` (not-empty dir); timers kept firing until stopped by hand |
| B | **REMOTE with network takeover** (econ-core) | remote agent, macvlan nets, images; wifi handed to `wpa_supplicant@` + systemd-networkd by the join | 🔑 THE HARD CASE: after removing the agent, **the box's wifi was still owned by the isle-era stack** — networkd holding a second address (.67) beside NM's (.66), a failed `wpa_supplicant@wlp1s0` unit, a stale wired isle lease (10.10.0.113) and a **dead default route via the now-gone router** (the route-theft pattern) |
| C | **DEV/HYBRID box** (pol-core) | polari as a SWARM STACK (stack rm ≠ compose down), many standalone polari service containers (livekit, reticulum, meetings), ~80 image tags incl. registry-tagged, staged deb dir, NM `~isle` dns-search | 🔑 MUST-SPARE list: **odoo (business system), the code checkout, the pol CLI — and `aisleriot`** (GNOME solitaire!) matched a naive `grep isle` over dpkg. Name-matching is a live hazard |

Cross-cutting, all devices: **data volumes are real data** (we tarred
every one before deleting — `~/polari-purge-backup-2026-08-17`); gpg
keys are not code (left the user keyring); backups themselves must be
excluded from any purge sweep.

## The three uninstall routes (Dustin's cases)

- **R1 — terminal:** `apt remove` / `apt purge` / `isle uninstall
  [--everything]`. Today: apt touches ONLY the package layer — a user
  who "uninstalls" keeps a fully running mesh (`restart:
  unless-stopped` containers + router VM survive). Dishonest; fix at
  the deb layer so plain apt is enough.
- **R2 — desktop:** right-click uninstall / software center. These
  drive apt underneath, so R2 inherits R1's fix for free — the deb
  maintainer scripts ARE the standard route.
- **R3 — in-app (JavaFX store shell):** per-app Uninstall buttons +
  a "remove isle-mesh from this device" flow, driving the same verbs
  through pkexec (the store's existing privilege pattern). Today only
  a Reinstall button exists.

## Debian semantics = the data policy

- **`remove`** = stop everything + hand networking back, **PRESERVE
  data** (/etc/isle-mesh incl. CA, docker volumes). Reinstalling picks
  the isle back up. (Debian convention: remove keeps state.)
- **`purge`** = additionally wipe config/state: /etc/isle-mesh,
  systemd units, hosts pins, split-DNS, apt source. Volumes: **Q1**
  (proposal: backup-tar to /var/backups/isle-mesh-<date>/ first, then
  delete — exactly what we did manually).
- **Maintainer-script discipline** (extends the 2026-08-09 incident
  rule): prerm/postrm act ONLY on `remove`/`purge` args — never on
  upgrade; never prompt; every step `|| true` (an uninstall must never
  wedge dpkg); act only on EXACT isle-owned name families (the
  aisleriot lesson); never touch third-party systems (odoo), user
  keyrings, code checkouts, or backup directories.

## Safety constants (every route, every phase)

1. **Never leave a box without a network owner** — ownership handback
   only happens when NetworkManager is active to take over; otherwise
   leave and say so.
2. Exact-name families only; no fuzzy grep over dpkg/docker.
3. Backup before destruction, path printed.
4. Teardown is idempotent and re-runnable; partial failure leaves a
   re-runnable state, never a bricked package manager.
5. Honest final report: what was removed, what was preserved, what
   remains (volumes on `remove`), and the command to finish the job.

## Phases

- **unin-0 — close the teardown-engine gaps** (destroy.sh):
  the app-container sweep (the 9-containers gap, hit live), exposure
  doors, leftover bridges (`br-my-isle`), timer stops
  (polari-isle-push, isle-trust-update), registry/apt/trust-page
  containers. Acceptance: `isle destroy --force` on a full core
  leaves ZERO isle containers/bridges/timers.
- **unin-1 — network handback** (✅ groundwork BUILT 2026-08-17:
  `isle-cli/scripts/network-handback.sh`): wpa_supplicant@ instances +
  networkd disabled only when NM is present; isle-written .network
  files removed; stale 10.10.0.x addresses + dead default routes
  flushed; `~isle` dns-search stripped from NM profiles; .isle hosts
  pins removed. Wire as `isle network-handback`; scenario-B acceptance
  = econ-core's exact end state, automatically.
- **unin-2 — deb wiring (makes R1+R2 real)**: isle-mesh-cli prerm
  (`remove` only) = stop timers → app-container sweep → `destroy
  --force` → network-handback; postrm (`purge` only, SELF-CONTAINED —
  package files are already gone) = config wipe + volume policy (Q1)
  + honest report. Launcher debs (isle-app-*) get minimal prerms that
  stop only their own app's containers. Fix the not-empty-dir purge
  warning (shells/debs staging dir).
- **unin-3 — `isle uninstall --everything` (the one honest verb)**:
  interactive full wipe = backup offer → unin-0 engine →
  network-handback → apt purge of the whole family (self-deleting
  script ordering: apt last) → verify sweep. Keeps today's
  --cli-only/--app-only tooling modes. Privilege via the sec_esc
  pattern (polkit on desktop, sudo in terminals) so the identical
  verb serves both worlds. Includes UNINSTALL.md: the three routes,
  remove-vs-purge semantics, the note that UI = same steps via
  polkit, and the per-scenario conditionals the engine applies.
- **unin-4 — the store-shell route (R3)**: per-app Uninstall buttons
  and the "remove isle-mesh" flow are THIN: each button = one pkexec
  invocation of the SAME engine verb the terminal uses — zero
  teardown logic in the UI. Ships with an UNINSTALL doc section
  stating exactly that ("the UI runs the same steps via polkit") and
  listing the terminal equivalents next to each button. Surfacing
  remove-vs-purge honestly = Q2. polari-app-shell + angular work
  rides the existing store.status/pkexec bridge pattern.
- **unin-5 — the dev/hybrid polari box (scenario C)**: `pol purge`
  verb mirroring what we did on pol-core — swarm stack rm + standalone
  polari containers + volumes (backup-first) + images + networks,
  with the explicit spare-list (odoo, code, pol CLI, backups) and
  swarm-vs-compose shape detection. The suite dev box is not a deb
  install, so it gets its own verb rather than maintainer scripts.
- **unin-6 — proofs**: install→uninstall→verify-zero on a scratch
  box/VM per route; the isle-core verification sweep we ran becomes
  `isle uninstall --verify` (containers/volumes/images/VMs/debs/dirs/
  units all zero, network owner named).

## Open questions (Dustin)

1. **Volumes on purge**: backup-then-delete (proposal, matches the
   manual run) or preserve-always (delete only via
   `isle uninstall --everything`)?
2. **GUI remove-vs-purge**: two buttons ("Uninstall" / "Uninstall +
   erase data") or one button + checkbox? (Proposal: two buttons,
   erase variant restating what gets backed up where.)
3. **Does plain `apt remove isle-mesh-cli` on a CORE tear down the
   router VM too?** Proposal: yes — removing the CLI is leaving the
   mesh; data survives for a reinstall. The alternative (require
   purge) leaves a headless mesh running with no tooling.
4. **Scenario-C scope**: is `pol purge` in-scope now, or later (the
   dev box is ours, not an end-user surface)?

## Grounding index

- The manual purge session (2026-08-17): memory polari-systems-org
  §"FULL 3-DEVICE PURGE" + this file's ground-truth table
- isle-cli/scripts/destroy.sh (--purge exists; app-sweep gap)
- isle-cli/scripts/uninstall.sh (tooling-only today, points at
  destroy --purge as "Wipe Island")
- isle-cli/scripts/network-handback.sh (unin-1 groundwork, built)
- build-cli-deb.sh postinst/postrm (the deb seam)
- ISLE_ONBOARDING_HANDOFF incident rule (maintainer-script discipline)
- ISLE_ETHERNET_ROUTE_PRIORITY_HANDOFF (route-theft; never-default)
