# Mesh-app convergence plan (mac-0 … mac-7)

**Date:** 2026-08-07 · **Status:** DRAFT — written with Dustin per the
handoff discipline; phases are for him to cut/reorder. Each confirmed
phase gets its own branch off `dev` (standing rule).

Decisions this plan is built on (recorded in
`MESH_APP_CONVERGENCE_HANDOFF.md` §7–8, Dustin verbatim there):

1. **isle-mesh is authoritative over networking** — genuinely
   separate vLAN, mutually invisible with the original network.
   Compose apps get pulled INTO the isle world.
2. **Docker swarm rides ON TOP of the isle network** — swarm is the
   dynamic placement mechanism (up/down/move), not the network.
3. **Polari topology drives dynamic changes** — what runs where is
   polari's, where packets go is isle's.
4. **An app is simultaneously a local app AND a mesh website**, both
   via its `.isle` URLs.
5. **Work split: this instance takes full responsibility over SSH**,
   in active communication with isle-core's Claude instance
   (workspace `~/.claude/projects/-home-detts-Isle-Mesh`), since the
   goal is a singular system. The 2026-06-20 "isle networking stays
   on isle-core" rule is AMENDED accordingly: work happens over SSH
   in isle-core's repos, with a written contract + notes so the
   other instance stays coherent.

The one-line architecture:

```
OpenWRT router + macvlan vLAN         isle authoritative (isolated from home LAN)
.isle DNS + per-device isle-agent     isle authoritative (all app URLs terminate here)
docker swarm control + data plane     rides ON isle addresses — placement only
mesh-app swarm services               polari topology places these, dynamically
delivery: local stub / shell / URL    same .isle URL behind every realization
```

---

## mac-0 — Convergence contract + comms channel (small, first)

The seam in writing, before any code moves.

- `CONVERGENCE.md` **in the Isle-Mesh repo** (committed on isle-core):
  the authority split (isle=network, polari=topology), the layer
  stack, what each side may write (polari may write registry
  entries/fragments THROUGH isle's tools, never raw files), and the
  note-passing protocol with isle-core's Claude (a `NOTES/` dir or
  doc both instances read+append; its memory lives in its own
  workspace).
- Mirror pointer in this suite: handoff doc already carries §5–8;
  add a short `pol isle` help update naming the plan (still refuses
  verbs until mac-4+).
- Amend the pol-core memory rule file (other-machines-ssh) to record
  the SSH-work amendment.

**Confirm gate:** Dustin reads CONVERGENCE.md; isle-core's Claude
acknowledges in NOTES (next time it runs) or Dustin waves it on.

## mac-1 — Unified app model (polari side, no network changes)

One definition, many realizations — the model the whole arc hangs on.

- `MeshApp` (topology module or new `meshapps`): references a
  compose file OR a PolariAppDefinition; owns `domain` (`<app>.isle`),
  services list (mirrors isle registry entry shape), availability
  spec (up-trigger × down-trigger × placement — ISLE'S vocabulary
  from AVAILABILITY-MODES.md, imported verbatim as constants), and
  the **auto/manual knob per-app**: `automation = {triggers_allowed:
  [...], may_relocate: bool}`, default manual-everything
  (knobs-and-suggestions preserved).
- `MeshAppRealization` rows: `local-stub | shell | website` —
  simultaneous, not exclusive; all carry the same `.isle` URL.
- Make the two placeholders REAL in vocabulary only:
  `OrchestrationTarget 'isle'` becomes seedable-but-gated (available
  once mac-3 verifies), `accessibility_scope='mesh'` accepted on
  InstanceDefinition with validation tied to the same gate.
- Mapping table: polari rows ↔ isle `registry.json` entry fields
  (domain/subdomains/services/modes/availability_mode) — the render
  contract mac-4/5 implement. Selftests: model + mapping round-trip.

**Confirm gate:** review of the model on the topology page.

## mac-2 — pol-core joins the isle vLAN (physical + join flow)

- **Dustin's manual step: a physical cable** — pol-core `eno1` is
  DOWN/no-carrier today (WiFi-only on 192.168.0.210). Run ethernet
  from pol-core to the isle bridge/router. isle's self-forming
  bridge (recent isle commits: auto-bridge non-ISP cables) should
  adopt it.
- Then over SSH: isle `join` flow for pol-core (the isle CLI owns
  this — use its scripts, don't reimplement), verify `.isle`
  resolution + reachability from pol-core, register pol-core in the
  mesh registry/device directory.
- Dual-homed on purpose during the arc (WiFi=home LAN for SSH/dev,
  eno1=isle). Mutual invisibility = no forwarding between the two on
  any host; verify with the isle conflict/isolation checks. Whether
  hosts eventually DROP the home LAN is a later, explicit decision.

**Confirm gate:** `ping <something>.isle` from pol-core; isolation
check green; home-LAN SSH still works.

## mac-3 — Re-home the swarm onto isle addresses

The current swarm advertises on 192.168.0.x — the network the mesh
must not see. Swarm-over-isle = the control plane moves.

- Sequence (no branch-sawing): keep home-LAN SSH up throughout.
  1. Snapshot current stacks (`polari-node`, `polari-engines`) +
     node labels.
  2. New swarm init on pol-core with `--advertise-addr <isle-ip>`
     (or leave/re-join each node — decide by evidence; a fresh init
     is cleaner and the stacks are re-renderable by `pol swarm`).
  3. isle-core + econ-core join over isle addresses; re-apply
     `polari.machine` labels. (econ-core is Down today — bring it
     back or explicitly park it.)
  4. `pol swarm deploy` re-renders stacks onto the new swarm;
     verify prf-a end-to-end.
- Ports 2377/7946/4789 ride the isle vLAN only.
- Verify isolation: swarm traffic absent from 192.168.0.x (tcpdump
  spot-check), mesh hosts cannot reach home-LAN-only services and
  vice versa.

**Confirm gate:** prf-a healthy on the re-homed swarm; isolation
evidence shown. (This phase is the riskiest — schedule with Dustin
present.)

## mac-4 — Converter upgrade (isle side, over SSH)

isle's compose→mesh-app converter learns to emit swarm-capable apps.
This is the two-transforms-become-one step: `scaffold.sh` (isle) and
`stackify.py` (polari) share one model.

- `scaffold.sh --orchestrator swarm` (knob; compose remains default):
  emits a stack file (reuse/port stackify's transforms: drop
  container_name/restart, deploy.resources, placement constraints)
  + the agent fragment + registry entry annotated
  `orchestrator: swarm`.
- **Agent→service reachability decision** (make with evidence, in
  CONVERGENCE.md): (a) swarm ingress-published ports — every
  device's agent upstreams `127.0.0.1:<port>`, giving the
  installed-everywhere appearance for free; or (b) attachable
  overlay — each device's isle-agent container joins the overlay
  and upstreams the service VIP. Prototype both on isle-sample-app;
  pick one; the loser stays documented.
- `app-package.sh` gains the same knob: the .deb's `up/down` wrapper
  drives `docker service scale/rm` (via the polari API or docker
  directly — decide) instead of `docker compose up` when the app is
  swarm-realized.
- All isle-side commits land in the Isle-Mesh repo with NOTES
  entries for its Claude.

**Confirm gate:** isle-sample-app converted to a swarm mesh-app,
reachable at its `.isle` URL from ≥2 devices, up/down works from
the .deb wrapper.

## mac-5 — Polari topology drives placement (the dynamic layer)

- MeshApp assignment rows → render: registry entry + fragment
  (THROUGH isle's generators over SSH/agent channel — polari never
  writes isle files raw) + stack constraints (`polari.machine`
  labels). `pol topology apply` stays the human verb (manual mode).
- **Auto mode (per-app knob from mac-1):** a reconciler that may act
  ONLY within the app's `triggers_allowed`/`may_relocate` envelope —
  up on access/schedule, down on idle, move on resource pressure.
  Every auto action writes an evidence row (suggestion→action
  provenance), so auto is a faster hand, not a different brain.
- Drift honesty: reconcile pass diffs polari rows vs each device's
  registry.json and surfaces mismatch as suggestions (isle remains
  live truth for networking; polari for intent).
- `pol isle` namespace comes ALIVE: status/apps/apply subcommands
  proxying the isle CLI + rows.

**Confirm gate:** move a demo app isle-core→pol-core by editing a
row + apply; watch `.isle` URL keep working; auto-mode demo on one
opted-in app.

## mac-6 — Delivery layer: local app + mesh website, same URL

- Point the existing realizations at `.isle`: app-shell registry
  entries gain isle URLs (`accessibility_scope='mesh'` goes live —
  probe/advisory logic extends: "reachable via isle mesh"); isle
  .deb stubs open the same URL; browser just visits it.
- App Store answer (open Q from handoff §3): store stays per-polari-
  instance, catalog entries become mesh-visible (served over .isle);
  one catalog many doors.
- Certs: `.isle` certs are isle's (its ssl/ tooling); shells must
  trust the isle CA — extend the shell's CA-pin machinery to carry
  a second root. (Cert unification = later; note in CONVERGENCE.md.)

**Confirm gate:** same app opened three ways on two devices: .deb
stub, shell, browser — all through `.isle`.

## mac-7 — Adaptive resource management (the payoff)

- Wire `resource-permitting`/`resource-pressure` triggers to real
  signals: polari's resource-awareness module (res-1..4) supplies
  per-node measurements; thresholds are per-app knobs.
- Wake-on-access (isle's AVAILABILITY-MODES on-demand flow): agent
  detects down on-demand app → wake request via device relay →
  polari reconciler (or device) brings the service up → holding
  page until healthy. Idle tracker scales back down.
- `placement: replicated` for the apps that warrant failover.
- Suggestions-first: pressure produces an evidence-bearing
  suggestion; only auto-enabled apps act on it unattended.

**Confirm gate:** live demo — kill/load a node, watch an auto app
relocate; an on-demand app wakes from a browser hit.

---

## Standing risks / flags

- **mac-3 is the risky one** (control-plane move) — do it with
  Dustin around; home-LAN SSH must survive every step.
- econ-core is swarm-Down today; decide park vs revive by mac-3.
- 30-day staging cert leaves recur ~Sep 5 (unrelated but will bite
  mid-arc; renew early).
- Everything committed innermost-first; pushes stay Dustin's manual
  `push-all-dev.sh --push`.
