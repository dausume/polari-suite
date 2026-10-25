# A real isle for testing, worked by two instances (ti arc) — plan 2026-10-24

His words (2026-10-24): "since we have desktop testing now and the capability to do both desktop and web manipulation, it should be
feasible now to move towards having an actual isle for testing by having you and codex collaborating. And besides, you should also be able
to access isle apps that are non-desktop via .isle in chrome too." Then: "isle-core is usually the core for the Isle, thus the name, and it
makes sense for codex to take that over since it can handle desktop apps. We just need to work out a plan for you to collaborate with codex
on ensuring you are both working from the most up-to-date apps and that whenever one of you are moving to test something you coordinate."

🔑 His ruling the same night (2026-10-24 ~21:00, verbatim): "The isle apps handle both swarm oriented docker apps and also qemu based
isle apps. All of our testing now that it is possible should be going via the isle itself since that is the format it is meant to be done
via. The VM for testing via pipeline is for pipeline automation, not the testing and iteration of development." → the isle is THE
development test target; the compose test node on econ-core and any VM belong to pipeline automation, not to the dev loop.

The collaboration MECHANICS (mailboxes, locks, the state board) are device-local by his rule of 2026-10-23 and are NOT in this file;
this plan holds only the arc, its slices and his decisions.

## 1. Facts at planning time (2026-10-24)
- No isle is running: isle-core has no isle CLI on the PATH, no `.isle` DNS answering, nothing resolves `.isle` (post-purge state of
  2026-09-13). pol-core's resolver is the ISP's — `.isle` names do not resolve from pol-core.
- The two instances split by proof kind: web / compose / swarm / doors / Chrome = Claude (pol-core); desktop windows, GUIs, USB on a
  host, the JavaFX shell = Codex (isle-core). Codex has an X11 desktop MCP on isle-core; libvirt is present there (its dnsmasq listens
  on the virt bridge).
- Today's lesson: Chrome's extension cannot attach to a certificate interstitial. On the compose test node that needs a hand import;
  on the isle it needs nothing — the agent's bootstrap trusts the isle root (`/etc/isle-mesh/ca/isle-root.crt`) on the joined device.
- isle-core host facts (checked over ssh 21:00): Isle-Mesh dev tip b029fc9 is identical in the suite pin, origin/dev and Codex's
  checkout; nothing isle is installed (no `/etc/isle-mesh`, no `isle` on the PATH); Codex's user has passwordless sudo; the host has
  `/dev/kvm` + virsh (the isle's own OpenWRT router runs as a libvirt VM — that VM is part of the isle, not a test VM); the host is a
  swarm WORKER running the five hw-engines services; 7 GB RAM, 808 GB free. The runbook is `isle-cli/scripts/core-install.sh`
  (7 idempotent steps) after `isle-cli/shells/install-cli.sh` or the CLI deb.
- Codex's own session had restricted networking on 2026-10-24 (no ssh out, no DNS → it could not read its mailbox, pull, or apt) —
  that is a session-permission setting of his, not anything of ours; until it changes, its inbound messages reach it only on its own disk.

## 2. Shape (corrected the same evening by his words: "The whole point of isle-mesh is it takes care of that automatically so long as
you install the appropriate apps and modules. So long as an isle agent is installed on pol-core and connected to the isle-core, you
will automatically be able to resolve any .isle website defined via installs. That functionality is already built.")
- **Placement:** the isle core runs **on isle-core itself** (it is the isle core; Codex takes it over). Isle apps sit on the mesh's own
  addressing (macvlan — `isle-onboarding-installers`), so they do not contend with the swarm ingress on the host. A libvirt VM is only
  the fallback if the swarm worker and the isle core cannot share the box.
- **Reach from pol-core:** install the **isle agent on pol-core** and connect it to isle-core — `isle core-install` on isle-core ends with
  JOIN INFO (CA fingerprint + the `isle-bootstrap.sh` one-liner served at `https://apt.isle/isle-bootstrap.sh`); running that one-liner
  on pol-core (sudo: his) verifies the CA fingerprint, trusts the CA, enables apt-on-mesh, installs CLI + store + runtime and runs
  `isle onboard`. DNS for `.isle` and the CA trust are then AUTOMATIC — built, not a decision. Chrome reaches `https://<app>.isle`
  for every app installed on the isle; the uninstall must hand back a working Ubuntu (`uninstall-hands-back-default-ubuntu`).
- **What goes in the isle (his words):** isle apps are of two kinds — swarm-oriented docker apps and qemu-based isle apps. The Polari node
  (backend/frontend/db/cache/auth) is the first kind (ti-2); the QEMU twins and the engine workers are the second (ti-3). Both are
  installed through the isle store/CLI from dev tips, never hand-rolled compose on the host.
- **Test target:** the isle is THE place development work is tested and iterated (ruled). econ-core's compose node (`pol deploy run`)
  and any VM are pipeline automation (Jenkins), not the dev loop — the Chrome pass of a change happens at its `.isle` name.
- **Verification loop:** Claude deploys from dev tips (pointers moved) → message "verify the desktop half of X" → Codex replies with what
  it saw; both write one line on the shared state board; locks before anything that restarts, flashes or reinstalls a shared resource.

## 3. Slices (each its own branch where code is touched; suites on isle-core; the isle itself is not a repo change)
| # | slice | who | proves |
|---|---|---|---|
| a | **ti-0** the isle core on isle-core | Codex | `isle core-install` done (idempotent) + `isle-registry-setup` (the mesh registry `pol dev deploy` pushes to); its JOIN INFO (CA fingerprint + bootstrap one-liner) on the shared board; `https://apt.isle` answers on isle-core |
| b | **ti-1** pol-core joins | his one sudo line (the one-liner, prepared by Claude from the board) + Claude (`pol dev setup`) | `https://<app>.isle` renders in Chrome on pol-core with no interstitial; a screenshot in the handoff; `isle status` on pol-core shows the agent connected; `pol dev status` shows the registry catalog |
| b' | **ti-1a** `pol dev` without literal addresses | Claude (polari-cli, branch dev-ti-1a) | `pol dev`/`isle-dev-setup.sh` take the isle host from the ssh alias or nodes.yml and the registry from `registry.isle`; no home-LAN literal remains in polari-cli (grep clean); `pol dev help` unchanged |
| c | **ti-2** the Polari node inside the isle (swarm-oriented isle app) | Claude deploys, Codex watches the desktop side | the Polari node installed as an isle app from dev tips (pointers moved); `/health` 200 at its `.isle` name; the four bench pages (pin-view, chip-ladder, bench, the C-function-atom colours) get their visual pass HERE — this replaces the econ-core Chrome pass as the gate before a live roll |
| d | **ti-3** the QEMU twins + engines as qemu-based isle apps, then the bench boards | Codex (isle app installs, USB on the host) + Claude (twin/bridge) | the C3 twin / engine workers run as isle apps (the `smp S5` checks pass through the isle); CX-001's desktop half runs on isle-core as the isle core; a board flashed from the isle, the hosted bridge reporting it |
| e | **ti-4** one round trip of the loop | both | a dev change → deploy → desktop verify → reply, all through the board and locks, no mouth relay |

## 4. Decisions (his; my recommendation first)
- **D-ti-1** placement: the isle core bare on isle-core, Codex's (his words today — taken as ruled unless he says otherwise). No test VM
  (his ruling: VMs are for pipeline automation); if the swarm worker and the isle core cannot share the box, D-ti-1b = which one moves.
- ~~D-ti-2 DNS route~~ ~~D-ti-3 CA~~ — NOT decisions: the agent install does both (his correction). Retired the same evening.
- **D-ti-4** isle lifecycle owner on isle-core: Codex (recommended, his words today) — or him.
- ✅ **D-ti-5 RULED (21:00):** the isle is THE development test target; econ-core's compose node and the pipeline VM serve pipeline
  automation only. The node on econ-core stays up as-is (no further `pol deploy run` for dev iteration); the pending bench Chrome pass
  moves to ti-2.
- ✅ **D-ti-6 RULED (21:30, his words):** "it looked good enough for now i do not care to do a roll live in the first place … I do not
  care about deploying for a long while right now. And I care about functionality progression and getting a smooth setup of using real
  isle apps for testing from here on out with collab between you and codex." → NO live roll, no deploy work; dev is the branch of record
  (every repo at pushed dev, verified 21:30); effort goes to functionality + the isle testing loop.

## 4b. The loop already in the CLI (found 21:30) — ti-2's mechanism, and its debts
`pol dev` (polari-cli/scripts/dev.sh, "the ISLE-ORIENTED developer workflow") is the route: `pol dev setup` (trust the isle CA for the
browser + docker, point at the isle host + mesh registry; `polari-cli/shells/isle-dev-setup.sh`) · `pol dev deploy backend|frontend`
(`pol node build` here → push to the mesh registry → `isle-polari-deploy --pull` on the isle core) · `pol dev status` · `pol dev teardown`.
The isle side: `isle-polari-deploy` pulls `registry.isle:5000/prf-*:staging`; the registry is NOT part of `isle core-install` — it is
`isle-registry-setup` on the CA host (isle-core), so **ti-0 includes `isle-registry-setup`** and **ti-1 includes `pol dev setup`**
on pol-core after the bootstrap one-liner. Debts found: (1) `dev.sh` / `isle-dev-setup.sh` default the isle and registry hosts to a
LITERAL home-LAN address — a real identifier in a public tracked file (privacy rule) and stale; slice **ti-1a** (polari-cli, mine):
resolve the isle host from the ssh alias / `pol-build/manifests/nodes.yml` and the registry from `registry.isle` once joined, no literal
addresses. (2) Isle-Mesh `isle-cli/scripts/polari.sh` has the same literal as a pull fallback — isle code, Codex's side (noted on the board).
(3) The two kinds he named map to catalog kinds that already exist in `modules/islemesh/islemesh_catalog.py`: swarm-oriented docker apps =
`mesh-app` (a compose file or image → `isle app deploy`), qemu-based isle apps = `hardware-app` (a KVM guest rendered from Polari rows →
`isle vm define`, needs the hardware tier). The engine workers are `mesh-app`s (the esp worker's image carries QEMU inside the container);
the science engines msci/cad already have tiles with `provides_engine`, the FIVE hardware workers (board 9830 / formal 9840 / esp 9850 /
pcb 9860 / bridge 9870, compose files in polari-rf-node) have NONE — that is ti-3a.

## 4c. ti-3 split (speculative work while the isle comes up — selftest-proven, browser-proven later in the isle)
| # | slice | who | proves |
|---|---|---|---|
| d1 | **ti-3a** hardware engine tiles | Claude (framework, dev-ti-3a) | five `mesh-app` tiles with `provides_engine`; `install_plan` yields `isle app deploy <w> --compose … --engine <family>`; the board module resolves a worker deployed as an isle app through its EngineProviderBinding row (knob still absolute); islemesh + board selftests |
| d2 | **ti-3b** `pol dev deploy <worker>` | Claude (polari-cli) | builds/ships the worker image to `registry.isle:5000` and runs `isle store install <worker>` on the isle core over ssh — the engines reach the isle the same way the node does; dry-run prints the exact steps |
| d3 | **ti-3c** the isle install itself | Codex (isle-core, after ti-0) | `isle store install esp-engines` etc. on the isle core; the `smp S5` twin checks pass against `https://esp-engines.isle` from the Polari node inside the isle |
- **D-cx-6..9** (the protocol's own decisions) live in the device-local README.

## 5. Rules this plan keeps
Collaboration mechanics on the devices, never here ([[codex-collaboration]]); test on the home machines; deploys from dev tips with
pointers moved; no real identifiers in tracked files (the isle's IPs and CA fingerprints go on the device board, not here).
