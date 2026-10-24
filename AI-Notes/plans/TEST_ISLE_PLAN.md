# A real isle for testing, worked by two instances (ti arc) — plan 2026-10-24

His words (2026-10-24): "since we have desktop testing now and the capability to do both desktop and web manipulation, it should be
feasible now to move towards having an actual isle for testing by having you and codex collaborating. And besides, you should also be able
to access isle apps that are non-desktop via .isle in chrome too." Then: "isle-core is usually the core for the Isle, thus the name, and it
makes sense for codex to take that over since it can handle desktop apps. We just need to work out a plan for you to collaborate with codex
on ensuring you are both working from the most up-to-date apps and that whenever one of you are moving to test something you coordinate."

The collaboration MECHANICS (mailboxes, locks, the state board) are device-local by his rule of 2026-10-23 and are NOT in this file;
this plan holds only the arc, its slices and his decisions.

## 1. Facts at planning time (2026-10-24)
- No isle is running: isle-core has no isle CLI on the PATH, no `.isle` DNS answering, nothing resolves `.isle` (post-purge state of
  2026-09-13). pol-core's resolver is the ISP's — `.isle` names do not resolve from pol-core.
- The two instances split by proof kind: web / compose / swarm / doors / Chrome = Claude (pol-core); desktop windows, GUIs, USB on a
  host, the JavaFX shell = Codex (isle-core). Codex has an X11 desktop MCP on isle-core; libvirt is present there (its dnsmasq listens
  on the virt bridge).
- Today's lesson: Chrome's extension cannot attach to a certificate interstitial, so any isle Claude must test in Chrome needs its CA
  trusted ONCE in the browser (step-ca as the single internal root — `polari-tls-ca` plan — is now on the critical path).

## 2. Shape
- **Placement:** the test isle is a **libvirt VM on isle-core**, under Codex's lifecycle. Own IP, own 80/443 (no collision with the
  swarm ingress on isle-core or the test node's proxy on econ-core); exercises the real install path (onboarding installers, the ISO
  plan) and the uninstall rule, which reusing a busy box never would.
- **Reach from pol-core:** Chrome at `https://<app>.isle` once pol-core routes `.isle` to the isle's DNS (one `resolvectl` domain route
  or the isle join step — his sudo) and trusts the isle CA (his browser step).
- **Verification loop:** Claude deploys from dev tips (pointers moved) → message "verify the desktop half of X" → Codex replies with what
  it saw; both write one line on the shared state board; locks before anything that restarts, flashes or reinstalls a shared resource.

## 3. Slices (each its own branch where code is touched; suites on isle-core; the isle itself is not a repo change)
| # | slice | who | proves |
|---|---|---|---|
| a | **ti-0** VM up + isle installed | Codex | one web app answers at a `.isle` name from inside the VM; DNS IP + CA path reported |
| b | **ti-1** `.isle` from pol-core | his two steps + Claude | `https://<app>.isle` renders in Chrome on pol-core with no interstitial; a screenshot in the handoff |
| c | **ti-2** the Polari node inside the isle | Claude deploys, Codex watches the desktop side | `pol deploy run <isle-vm> --role node` from dev tips; `/health` 200; the same four pages checked in Chrome as on econ-core |
| d | **ti-3** the bench boards in the isle | Codex (USB passthrough) + Claude (twin/bridge) | CX-001's desktop half runs against the VM; a board flashed from inside the isle, the hosted bridge reporting it |
| e | **ti-4** one round trip of the loop | both | a dev change → deploy → desktop verify → reply, all through the board and locks, no mouth relay |

## 4. Decisions (his; my recommendation first)
- **D-ti-1** placement: libvirt VM on isle-core (recommended) — or bare on econ-core beside the test node.
- **D-ti-2** how pol-core joins `.isle` DNS: a `resolvectl` per-domain route he sets once (recommended) — or an isle join command that does it.
- **D-ti-3** the CA: adopt step-ca now as the single internal root Chrome trusts once (recommended) — or keep importing per-node CAs by hand.
- **D-ti-4** VM lifecycle owner: Codex (recommended, his words today) — or him.
- **D-cx-6..9** (the protocol's own decisions) live in the device-local README.

## 5. Rules this plan keeps
Collaboration mechanics on the devices, never here ([[codex-collaboration]]); test on the home machines; deploys from dev tips with
pointers moved; no real identifiers in tracked files (the isle's IPs and CA fingerprints go on the device board, not here).
