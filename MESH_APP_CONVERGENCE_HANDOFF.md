# Handoff — mesh-app convergence (polari apps × mesh apps)

**Date:** 2026-08-06 · **From:** Fable 5 · **Status:** ⚠ CONCEPT
CAPTURE ONLY — **planning deliberately NOT started.** Dustin: "I am
not sure what is the best approach there so maybe we will be
thinking that through next." The plan gets written *with him*.

Nothing here is a design decision. Where wording is his, it is his.

---

## 1. What Dustin asked for (recorded, near-verbatim)

> "We will want to move on to the mesh-app and figuring out how we
> can use what we built out to then make it so we can have apps be
> distributed across a computer and be able to manage everything as
> though they are mesh-apps.
>
> We will be trying to merge the polari app logic with the mesh app
> logic and try to make a coherent approach to making a more
> flawless approach to using polari to manage the topology
> automatically and enable leveraging and combining different apps
> into polari or isle mesh apps…."

Points as separated for later planning — NOT resolved:

1. **Use what appstore-1/shell-1 built** as the substrate: apps
   distributed across a computer (computers?), managed *as though
   they are mesh-apps*.
2. **Merge polari app logic with mesh app logic** into ONE coherent
   approach — today they are deliberately separate concepts.
3. **Polari manages the topology automatically** — "more flawless";
   today every deploy is knobs-and-suggestions human-invoked
   (`pol topology apply` stays a person's command by explicit
   standing rule — reconciling "automatic" with that rule is a real
   design question, not a detail).
4. **Combine different apps into polari or isle mesh apps** —
   composition of apps, targeting BOTH polari instances and isle
   mesh.

## 2. What already exists (the pieces a merge would draw on)

- **polariapps** — `PolariAppDefinition` (an app = a server-side
  module/pages/nav config), export/apply as credential-free JSON,
  `AppDeploymentPlan` receipts.
- **appstore-1 + shell-1 (built 2026-08-06, live-verified)** —
  downloadable native shells over those apps: enrollment tokens,
  registration documents carrying per-instance reachability
  (`accessibility_scope` local|web|**mesh** — mesh is ALREADY a
  named-but-refused placeholder on InstanceDefinition), multi-
  instance client registries, `polari://` deep links, desktop/
  android/android-vr artifacts in MinIO. See
  memory `polari-app-store.md`.
- **polariPeers** — instance-to-instance mesh: `PeerNode`,
  `PeerAgreement` (admission flow, mesh-convergence phase 1),
  `module_bundle`/`module_exporter`/`module_fetcher` (modules
  travel between instances), `join_flow`, `mesh_facts`.
  ⚠ The app-shell arc explicitly kept shells OUT of this ("NOT
  mesh apps"); this new arc is where the two finally meet — on
  purpose this time.
- **topology module** — `InstanceDefinition`/`ModuleAssignment`/
  `ModuleDependencyEdge`, `provider_registry` (module delegation
  resolves providers from rows), portable topology packages,
  `pol topology assign` + derived `POLARI_MODULES` (mod-env-3),
  `pol swarm deploy` re-render. `OrchestrationTarget` 'isle' =
  named-but-unavailable, exactly parallel to accessibility 'mesh'.
- **Graceful mobility (gm)** — blue-green module moves as data.
- **xsim** — cross-instance simulation coupling.
- ⛔ **isle-mesh networking lives on isle-core's own Claude**
  (standing rule since 2026-06-20): do NOT rebuild isle networking
  here. The seam is presumably: polari declares/consumes, isle-core
  transports.

## 2b. Dustin's follow-up answers (2026-08-06, recorded — these
## PRE-RESOLVE part of §3)

> "they can choose between auto or manual, and we will want to
> leverage it. We also previously defined everything assuming
> docker compose based apps. However we likely want to upgrade
> that so that the apps can effectively operate as though they are
> docker swarm apps. Or they are shell apps, basically allowing
> you to access the apps from another computer via web despite it
> actually being installed elsewhere."

As separated for planning:

1. **Auto vs manual is a CHOICE (a knob), not a doctrine** — the
   operator picks per-something (per app? per topology? to be
   pinned down), "and we will want to leverage it" — i.e. auto
   mode is expected to do real work, not be decorative. This
   dissolves the §3 tension: knobs-and-suggestions survives as the
   DEFAULT (manual), auto is an explicit opt-in knob.
2. **Upgrade ISLE-MESH's existing converter tool** (corrected by
   Dustin 2026-08-06): "isle mesh has a tool to automate converting
   compose into being a mesh app, we will want to upgrade that
   capability in order to automate them into becoming docker swarm
   capable apps, along with integrating together the mesh app
   automation capabilities with polari capabilities." So the work
   is TWO-sided:
   (a) the compose→mesh-app converter that ALREADY EXISTS on the
       isle-mesh side gets upgraded to emit swarm-capable apps;
   (b) that mesh-app automation gets integrated with polari's
       capabilities (topology rows, app definitions, the store).
   **THE GOAL (Dustin, verbatim): "our goal is to combine the two
   systems meaningfully not just upgrade one or the other."** So
   frame every design choice as convergence — one coherent
   app-automation system with polari and isle-mesh as its two
   halves — not as patches to either side. The converter upgrade
   and the polari integration are means; the combined system is
   the deliverable.
   ⚠ The converter presumably lives in isle-core's repos, and
   isle-core has its OWN Claude holding isle-mesh memories (rule
   since 2026-06-20) — the next session must LOCATE the tool
   first (isle-core over SSH, or ask Dustin where it lives) rather
   than assume its shape, and decide which side each change lands
   on. Note polari's own stackify.py (`pol swarm render`) does a
   compose→swarm-stack transform for INSTANCES — related but not
   the same tool; the combined system is where those two
   transforms likely become one model.
3. **OR shell apps as the other realization**: an app stays
   installed where it is, and the app-shell machinery
   (appstore-1/shell-1: registration, reachability, multi-instance
   registry) gives access "from another computer via web despite
   it actually being installed elsewhere". So a mesh-app has (at
   least) two delivery modes — MOVE the app (swarm placement) or
   REACH the app (shell access) — and the model should treat them
   as two answers to one question.

## 3. Ambiguities STILL open (after §2b; resolve with him)

- ~~auto vs manual~~ → RESOLVED as a knob (§2b.1). Remaining: the
  knob's GRAIN (per app? per topology? per move-class?) and what
  auto is allowed to touch (module assignment only? container
  deploys? cert/env renders?).
- What IS a "mesh-app" concretely — given §2b it looks like: one
  app definition + a per-deployment CHOICE of realization
  (swarm-distributed vs shell-reached vs both). Confirm that
  framing before modeling it.
- "distributed across a computer" — one machine, many instances?
  or the fleet (pol-core / isle-core / econ-core)? §2b.2's swarm
  wording suggests the fleet; confirm.
- Where does the App Store sit — per-instance stores, or one
  mesh-wide catalog with instance-local artifacts?
- Do the two placeholders ('mesh' accessibility scope, 'isle'
  orchestration target) become real in this arc, and which side
  (polari or isle-core) owns each?
- App-layer swarm: does a module/app become a swarm SERVICE of its
  own, or stay inside the instance containers with swarm placing
  the instances (today's model)? This is the biggest architecture
  fork §2b.2 opens.

## 4. State at handoff

- App Store arc COMPLETE + live on prf-a (all four platforms
  available; full download→register→probe→auto-redeem loop proven).
  Linux desktop manual check + push = Dustin. iOS: sources only, no
  Mac available. VR APK: no headset attached for on-device verify.
- Everything committed innermost-first, NOTHING pushed;
  `polari-app-shell/` awaits remote + .gitmodules.
- Staging cert leaves renewed 2026-08-06; they are 30-day — recur
  ~Sep 5.

---

## 5. Reconnaissance results (2026-08-07 — the "LOCATE it first" step, done)

§2b.2 said the next session must locate isle's converter rather than
assume its shape. Done, read-only over SSH (`isle-core:~/Isle-Mesh`).

**The converter is not one script — it is three layers:**
- `isle-cli/scripts/scaffold.sh` (1124 lines) — the compose→mesh-app
  converter proper: parses a docker-compose file, generates SSL certs
  and the nginx proxy config, writes the app's isle configuration.
- `isle-cli/scripts/app-package.sh` (145 lines) — compose→**.deb**:
  desktop icon + per-app `up/down/access/status` wrapper that
  registers/deregisters with the isle agent. **This is already
  "an app that feels installed"**, and it already carries
  `--mode <availability_mode>`.
- `isle-cli/scripts/app-orchestrator.sh` (523 lines) — deploy-time
  integration: detect agent, generate fragment, merge, reload
  with no downtime.
- Supporting: `mesh-app-scaffolding/` (jinja segments + templates +
  `parse-docker-compose.sh` + `build-proxy-config.py`),
  `isle-agent/scripts/generate-app-fragment.py` (345),
  `generate-compose.py` (232).

**isle-agent** = ONE nginx container per device (virtual MAC
`02:00:00:00:0a:01` for OpenWRT DHCP isolation), per-app config
FRAGMENTS merged into a master nginx.conf, `registry.json` as the
domain/subdomain/service registry with conflict detection, zero-
downtime reload. Siblings: `isle-host-agent` (device relay),
`isle-remote-agent`, `isle-vlan-agent`.

**`docs/AVAILABILITY-MODES.md` is the resource-adaptivity hook and it
is already specced on the isle side**: availability as
`up-trigger × down-trigger × placement`, presets over composable
knobs (explicitly "per the isle knobs-and-suggestions rule" — the
same rule polari follows). up-triggers: boot | access | schedule |
presence/quorum | manual | **resource-permitting**. down-triggers:
never | idle-timeout | schedule-end | presence-lost | manual |
**resource-pressure**. placement: single-host | **replicated
(failover across devices)**. Wake-on-access travels the device-relay
control plane; an app→device directory is named as needed
scaffolding. STATUS there: always-available implemented, on-demand
scaffolded/planned.

**🔑 THE BIG LIVE FACT (not known at handoff): the isle devices are
ALREADY swarm nodes of polari's cluster.**
```
docker node ls   (from pol-core)
  user-HP-ProDesk-600-G1-SFF   Leader   polari.machine=pol-core
  dustin-etts-mesh-core        Ready    polari.machine=isle-core
  dausume-DNB20-series         Down     polari.machine=econ-core
```
`polari-engines` (msci-engines) is RUNNING on isle-core right now,
next to `isle-sample-app` as a plain container. Stacks: polari-engines,
polari-node. So the substrate for "swarm apps distributed across
devices" is not something to build — it is live and half-used. The
arc is mostly ONE MODEL OVER TWO CONTROL PLANES, not new plumbing.

**Polari-side seams already cut** (confirmed in code):
- `topology/topology_constants.py`: `ORCHESTRATION_TARGETS =
  ('compose','swarm','isle')`, `ACCESSIBILITY_SCOPES =
  ('local','web','mesh')` — both with 'the future isle path,
  seeded unavailable' comments.
- `polari-cli/scripts/isle.sh` — 37-line namespace that refuses
  every verb and names `pol swarm` the deliberate stand-in.
- `pol-build/tools/stackify.py` — compose→swarm-stack with
  `--constraint <service>=<expr>` → `deploy.placement.constraints`,
  described as "how `pol allocate` pins a service to a machine
  (node labels, set by pol swarm init/join)". The node labels it
  refers to are the `polari.machine:*` labels above — already set.

## 6. The four decisions blocking the plan (asked of Dustin 2026-08-07)

1. **Cluster shape** — one swarm over the whole mesh / per-device
   swarms with isle routing between / hybrid (swarm MOVES compute,
   isle+shells REACH).
2. **Source of truth** — polari rows authoritative and isle
   registry.json RENDERED from them (the POLARI_MODULES idiom) /
   isle authoritative and polari mirrors / two-way with an explicit
   reconcile-and-surface-drift pass.
3. **The facade** — what makes an app look installed everywhere:
   isle `.deb` stub + agent proxy / polari app-shell client /
   browser-only `.isle` domain / a per-app choice among them.
4. **Work split** — spec-for-isle-core's-Claude (respects the
   2026-06-20 rule) / implement both halves over SSH / polari-side
   only against isle's current interfaces.

Still open after those: the auto/manual knob's GRAIN and what auto
may touch — though note isle's availability model already gives auto
a vocabulary (`resource-permitting` / `resource-pressure`), so the
knob may be nothing more than "which triggers is this app allowed
to use, and may polari move it".

## 7. Dustin's architecture answer (2026-08-07, recorded near-verbatim)

> "part of the solution here needs to be that we need to retain the
> capability for isle-mesh to remain authoritative over networking
> while pulling docker compose into it and enabling topology from
> polari to be able to dynamically change the topology. we want the
> network to focus on making everything a genuinely separate vLAN
> that cannot see the original network and vice versa. The isle-mesh
> approach should be the main approach for networking, and docker
> swarm just rides on top of that network so that we can leverage
> the capability to dynamically bring apps up or down and move them
> around dynamically. We want to make it so this can eventually be
> turned into something that simultaneously can be apps locally and
> be mesh accessed websites as well. The apps will leverage the
> .isle urls."

This RESOLVES three of §6's four decisions:

1. **Cluster shape → swarm-over-isle.** One swarm, but it RIDES ON
   the isle vLAN — swarm is purely the dynamic placement layer
   (up/down/move); isle-mesh is THE network. Mutual isolation is a
   hard requirement: the mesh vLAN cannot see the original network
   and vice versa.
2. **Source of truth → split by layer.** isle-mesh authoritative
   over NETWORKING (vLANs, .isle domains, certs, agent proxying);
   polari authoritative over TOPOLOGY (what runs where, dynamic
   changes). Compose apps get PULLED INTO the isle world.
3. **Facade → both, simultaneously.** An app is a local app AND a
   mesh-accessed website at the same time; both realizations hit
   the same `.isle` URLs.

**Derived layer stack (for the plan):**
```
 OpenWRT router + macvlan/vLAN        ← isle-core authoritative
 .isle DNS + per-device isle-agent    ← isle-core authoritative
 docker swarm control+data plane      ← rides ON isle addresses
 mesh-app swarm services              ← polari topology places these
 delivery: local stub / shell / URL   ← all resolve via .isle
```

**⚠ Consequence not yet decided: the CURRENT swarm contradicts the
isolation requirement.** All three nodes advertise on 192.168.0.x —
the original network. Swarm-over-isle means re-homing the swarm
(advertise-addr on isle vLAN interfaces = leave/re-join or
re-init), and pol-core itself needs a presence ON the isle network.
Transition plan (dual-home then cut over?) is a real design step.

Still open for the plan: §6.4 work split (isle-core's Claude vs SSH
vs polari-only), the auto-knob grain (isle's trigger vocabulary is
the likely answer), and the swarm re-homing path.

## 8. Work split RULED + survey done (2026-08-07)

Dustin: this instance takes **full responsibility over SSH** on the
isle side, in **active communication with isle-core's Claude**
(workspace `~/.claude/projects/-home-detts-Isle-Mesh` exists) —
"since this is attempting to merge the logic of both frameworks and
bring them into being a singular system." The 2026-06-20 rule is
amended accordingly (contract + notes keep the other instance
coherent).

Physical facts: pol-core `eno1` is DOWN/no-cable (WiFi-only on the
home LAN) → joining the isle vLAN needs Dustin to run ethernet.
SSH to isle-core rides the home LAN — sequence cutover carefully.
isle-core `enp1s0` up/addressless (isle bridge member); router VM
virbr0 currently DOWN.

Dustin then asked for a detailed BOTH-SIDES capability survey before
locking the plan → `MESH_APP_CONVERGENCE_CAPABILITIES.md` (9 domains
w/ merge verdicts + the 5 genuinely-new gaps). Key discoveries: the
2026-07-03 `MESH_CONVERGENCE_PLAN.md` seam doc EXISTS ON BOTH SIDES
and already ruled the authority split; isle's REVAMP-PLAN.md admits
the app layer is "built but disjointed" (registry durability etc. —
fix branches exist, VERIFY merged into dev-consolidation); isle's
availability-modes vocabulary + polari's movers/receipts are the
flagship merge. Draft phase plan: `MESH_APP_CONVERGENCE_PLAN.md`
(mac-0..7) — awaiting Dustin's cut.

## 9. Dustin's addition (2026-08-07, recorded near-verbatim): .deb installs + KVM hardware

> "another thing to account for is install via deb, we need to be
> able to install apps similarly to how we install isle-mesh itself
> currently and be able to make polari and particular modules in
> polari able to be installed similarly in a way that makes sense.
> That way people can use normal app stores to do installs but have
> all the capabilities of a docker swarm on the vlan of isle mesh.
> While retaining the capability to use KVMs for doing things like
> integrating arbitrary hardware over usb or usb-c (what we have
> been simulating in polari hardware wise, made real)"

As separated for planning:

1. **.deb is the UNIVERSAL install story** — apps install the way
   isle-mesh itself installs (`appInstall.sh` → manager-app .deb
   that BUNDLES the CLI; postinst installs CLI on clean machines).
   Note: the 2026-07-03 seam doc §2–3 ALREADY planned this — `isle
   package` .debs w/ postinst self-integration + graceful
   degradation, and "Polari's .deb is produced by the SAME
   pipeline". Dustin is re-affirming + extending it.
2. **Polari itself AND individual polari MODULES as .debs** "in a
   way that makes sense" — module .debs presumably wrap the existing
   module_bundle JSON + a postinst that installs into the local
   instance via the modules API (module_fetcher/loader machinery
   exists; 22 modules already split to polari-module-* repos).
3. **"Normal app stores"** as the front door — deb-native installs
   (apt repo on the mesh and/or the polari App Store serving .debs,
   which it already does for the shell) — while the payload still
   gets full docker-swarm-on-isle-vLAN capabilities via postinst
   self-integration.
4. **KVMs RETAINED as a first-class realization** — for integrating
   arbitrary hardware over USB/USB-C: polari's hardware simulation
   (hwsim Renode/Verilator/ngspice, electrodevice/hwdigital/hwfpga,
   the MCU+FPGA architecture direction) **made real** by passing
   the physical device into a VM. isle already runs libvirt (the
   OpenWRT router VM, virsh autostart) — the machinery exists.
   🔑 Implication: hardware presence is a PLACEMENT CONSTRAINT —
   a USB device is plugged into ONE machine, so a hardware-backed
   app is pinned there (node label e.g. polari.hw.<device>); it is
   the one realization the dynamic mover must refuse to move.

## 10. Dustin's transport requirement (2026-08-07, near-verbatim)

> "the goal is to ensure it is possible for everything to operate
> smoothly over a single ethernet cable dedicated to the isle-mesh,
> or for it to alternatively be able to operate smoothly over a
> dedicated usb-wifi or wifi card in general that has opted to
> connect to the openwrt router. It would be good if it were
> possible to expose the openwrt router via a plugin usb-wifi but I
> am not sure if that is possible. That way isle-mesh could also
> optionally just be the sole wifi connection of a device, the
> device would still want to utilize the agent and ensure access
> was only granted to .isle and such domains due to needing to
> follow the rules for separation"

As separated:

1. **Isle uplink is an ABSTRACTION**: any L2 attachment to the
   isle — dedicated ethernet cable (proven, ~1ms) OR a dedicated
   WiFi interface (USB dongle or internal card) associated to an
   isle AP. Everything (swarm control plane, overlay, .isle
   ingress) must run smoothly over ONE such link.
2. **Isle AP via plug-in USB-WiFi — FEASIBILITY: YES, with a
   chipset caveat.** Two realizations, both keep the router
   authoritative:
   (a) USB WiFi dongle passed into the OpenWRT router VM (libvirt
       hostdev — literally the FIRST real use of the mac-9 USB
       passthrough capability). Works IFF the chipset does AP mode
       under OpenWRT: MediaTek mt76 family (MT7612U, MT7921AU) is
       the safe choice; Atheros AR9271 ok (2.4GHz only); Realtek
       dongles are generally NOT AP-capable there — buy deliberately.
   (b) hostapd on the HOST bridged into isle-br-0 — the AP is pure
       L2; the router VM still owns DHCP + .isle DNS. More robust
       (no USB-into-VM jitter), still router-authoritative.
   Decide (a) vs (b) by prototype; (a) is more portable (the AP
   travels with the router VM), (b) is more reliable.
3. **Sole-WiFi mode**: a device whose ONLY connection is the isle
   AP. Separation rules enforced at the edge: DNS answers .isle
   only, firewall egress limited to isle nets, agent still
   mandatory. Consistent with the standing isle rule "never hijack
   the ISP route" — sole-wifi = no internet BY DESIGN unless the
   mesh explicitly provides a gateway (own knob, default off).
4. **Link quality as a placement input**: wifi uplinks have
   latency/jitter ethernet doesn't; the resources module should
   measure per-link quality so placement/availability suggestions
   can prefer cabled nodes for chatty services.

**§10 addendum (Dustin, same session):** "we want to be able to
have internet and isle-mesh on the same device as well as enabling
isle-mesh to operate fully without internet." So:
- **Dual-home is a FIRST-CLASS steady state**, not a transition:
  internet (home LAN/WiFi) + isle uplink on one device, with
  separation ENFORCED (no forwarding between them, no route leaks,
  split DNS: .isle → isle interface, everything else → normal).
  The earlier open question "do hosts eventually drop the home
  LAN" is ANSWERED: no — per-device connectivity mode is
  sole-isle | dual-home, operator's knob.
- **Offline-complete is an ACCEPTANCE RULE**: the whole mesh must
  work with zero internet — .isle DNS (already authoritative
  locally), own CA (no external chain), apt repo ON the mesh
  (mac-8), store artifacts in mesh MinIO, Keycloak local, time
  sync from the router (chrony peer, no NTP pool dependency), and
  🔑 a MESH-LOCAL DOCKER REGISTRY — without one, every dynamic
  placement move needs a rebuild on the target or an internet
  pull; a registry service on the isle is what makes "move apps
  around dynamically" real AND offline. (Today's swarm images are
  per-node local builds — fine static, wrong for dynamic.)

## 11. Dustin's interface requirement (2026-08-07, near-verbatim)

> "we will also want to leverage the work done on polari side for
> javaFx apps to enable JCEF for embedded chromium, and make a
> custom interface based on the polari topology work we have done,
> to make understanding what is happening on the isle easy to see
> and intuitive, we need to be able to see what all applications
> are on the network and also be able to see what protocols are
> being permitted between nodes on the network (known due to the
> nginx proxies being controlled by isle-mesh) and then we will
> also want to be able to see and leverage the interface to be
> able to do different kinds of operations native to isle-mesh
> like changing what the .isle urls are for different apps"

As separated — the ISLE CONSOLE:

1. **Vehicle = polari-app-shell** (JavaFX/JCEF, built+proven
   2026-08-06): the console ships AS a shell app — and by mac-8 it
   is itself a mesh-app .deb in the store (dogfood: the tool for
   seeing the mesh installs THROUGH the mesh, works offline).
2. **Content = topology-idiom Angular pages** (rows + D3 +
   per-object display config — the established polari route), fed
   by isle data through the mac-5 contract: mesh map (devices,
   uplinks + link quality, router, agents), apps-on-network view
   (realizations, modes, placement, status).
3. **🔑 Protocol matrix — a DERIVED view**: because isle-mesh
   controls every nginx proxy, the permitted protocols between
   nodes are KNOWABLE from the agent fragments/registry
   (server_names, ports, http/https/mTLS, upstreams). Parse/render
   them into rows → an app×app / node×node "who may speak what to
   whom" matrix. Nobody has to remember the network policy — the
   proxies ARE the policy, made visible.
4. **Operations from the UI, isle-native**: e.g. CHANGE an app's
   .isle URL — a compound receipted op (registry update → DNS
   re-register → fragment regen → cert reissue → agent reload),
   knobs-and-suggestions, through isle's generators only. Also
   up/down/wake, availability-mode changes. Adopt isle's own
   CLI↔app PARITY rule: every console operation = an isle CLI verb.

**§11 addendum (Dustin, ruled):** "the manager app has a jcef pane
to the same pages, but we likely keep some permissions restricted
to the manager app host and user login." → ONE set of pages, two
chromes; authorization is SURFACE- and HOST-aware, not just
role-based: privileged isle ops (network-shape changes, admissions,
destructive ops) require the manager app ON THE HOST machine + a
local user login — the console elsewhere gets the read views and
the unprivileged verbs. The permission tiers per operation get
enumerated at mac-10 phase start.

## 12. Cable topology decision (2026-08-07)

Physical constraint (Dustin): limited ethernet ports — EITHER
pol-core↔isle-core OR isle-core↔econ-core can be cabled, not both.
Currently the latter; Dustin leans to switching to the former for
this arc.

Assessment (agreed): **pol-core↔isle-core is the right cable.**
mac-3 requires the swarm MANAGER (pol-core) on the isle; the two
authorities of the merged system (polari=topology, isle=network)
must share the mesh. econ-core is the cheapest temporary loss — it
is already swarm-Down and out of this arc's critical path.

Development impact: the proven 2-machine isle gets RE-PROVEN with
the new pair (that IS the mac-2 exercise — plug-and-play machinery
should make it plug-in-and-verify); econ-core parks and becomes the
FIRST CANDIDATE for the §10 wifi-uplink path once the isle AP
exists; SSH/dev unaffected (home WiFi either way).

💡 The either/or may be removable for ~$15: a USB-3 gigabit
ethernet adapter on isle-core = another NIC; isle's own hotplug.sh
(udev on carrier-gain) + create.sh auto-bridging of non-ISP cables
look built for exactly this. One adapter → all three machines
cabled. Try it; if it works the constraint disappears.
Cable swap = Dustin's step; not yet performed.

**§12 addendum — switch option:** a ~$15 5-port UNMANAGED gigabit
switch (LS105G/GS305 class) interconnects all four+ ethernets and
is the isle-compatible choice: the isle is plain L2 (router VM =
only DHCP, virtual MACs, beacons) and a dumb switch just makes the
broadcast domain a star — simpler than multi-NIC bridging. AVOID
smart-switch port-security/MAC-limiting (virtual MACs). Verify on
arrival: non-ISP-cable auto-detection with 3 peers on one segment.
Future option noted: a cheap OpenWRT-capable box (GL.iNet class)
could one day BE the physical isle router, replacing the VM.

**§12 state update (2026-08-07, evening):** Dustin SWAPPED THE
CABLE — pol-core↔isle-core plugged, econ disconnected ("for
today"). **L1 VERIFIED both ends**: pol-core `eno1` UP w/
link-local, isle-core `enp1s0` UP w/ link-local. But the ISLE STACK
IS DOWN on isle-core: no `isle-br-0`, `virbr0` DOWN, router VM not
visible (system virsh needs interactive sudo — BatchMode SSH can't
elevate), `isle-mesh-boot.service` NOT FOUND (boot persistence not
installed?), `isle status` prints its banner then stalls >40s.
Bring-up needs Dustin (or passwordless-sudo grants for specific
isle commands) — recorded as the first live task of mac-2, not
attempted unilaterally.

**§12 purchase:** Dustin selected the TP-Link **TL-SG608** (8-port
unmanaged gigabit, ~$23) — confirmed compatible: unmanaged = no
port-security/MAC-limiting (virtual MACs safe); IGMP snooping
harmless (link-local multicast 224.0.0.0/24 — mDNS/beacons — is
always flooded; DHCP/broadcast untouched). 8 ports = all three
machines + router + headroom; econ-core returns without waiting on
the wifi-AP path. On-arrival check stands: non-ISP-cable detection
with multiple peers on one segment.

## 13. mac-1 STARTED + LIVE (2026-08-07, evening)

Dustin: build the polari-side acceptor module so the visualization
verifies layers/apps coming online as the real functionality lands;
mock data allowed but MUST carry a flag real data never has, shown
as a large MOCK NETWORK banner.

✅ BUILT + DEPLOYED on prf-a (branches dev-mac-1 in
polari-framework + polari-cli):
- `modules/islemesh/` — constants (ISLE'S availability vocabulary
  verbatim), basis (IsleDevice/IsleUplink/IsleApp/IsleAppService/
  MeshAppRealization/IsleProtocolPermit/IsleIngestReceipt, all
  is_mock-stamped), stdlib-pure parsers (registry.json + nginx
  fragments — THE PROXIES ARE THE POLICY), ingest API w/
  replace-per-device semantics + mock/real flip resets + orphan
  sweep + retire, /display/isle-mesh page, selftest 41/41.
- `pol isle` ALIVE: status/sync/mock/matrix/retire. sync = REAL
  data over SSH (never flagged); mock = built-in flagged network.
- LIVE-VERIFIED: mock seeds 4 devices/3 apps/10 permits + banner;
  real sync REPLACED isle-core+pol-core with reality (isle-core's
  actual registry: health + sample apps); final state = 2 real + 2
  mock devices, banner honestly up. 🔑 THE CABLE IS VISIBLE:
  pol-core@eno1 + isle-core@enp1s0 ethernet link_up=true
  mock=false — today's swap, as data.
- Live-caught fixes (committed): swarm scheduler tried isle-core/
  econ for the backend on --force (node stack has NO placement
  constraints — pinned polari.machine==pol-core by hand; row-level
  render fix = mac-5); IsleAppService needed device_name for
  replace semantics; mock→real flip must reset unsupplied facts;
  registry ingest must not claim agent_present (configured ≠
  running).
- Deploy chain used: pol topology assign islemesh prf-a →
  pol node build backend → pol swarm deploy node + service update
  --force (same-tag gotcha).
REMAINING for mac-1: Dustin's browser pass of /display/isle-mesh;
the Angular console page is mac-10.

**§12/§13 update (2026-08-07, night): THE SWITCH IS IN.** Dustin
cabled all three machines to the TL-SG608. L2 VERIFIED from both
ends (IPv6 all-nodes multicast): pol-core@eno1, isle-core@enp1s0,
econ-core@enp2s0 all on ONE segment, RTT 0.4–0.8ms, no loss. The
either/or cable constraint is GONE — econ-core is back without the
wifi-AP path. Synced into islemesh: all three devices now REAL rows
w/ ethernet(isle)+wifi(home) uplinks — the dual-home model as data.
Only guest-laptop remains mock (kept as the sole-isle demo; banner
honestly up). NEXT physical layer: the isle stack itself on
isle-core (router VM + agent + bridge adoption of the switch
segment) = mac-2's join flow, needs interactive sudo or Dustin.

**§13 requirement (Dustin, 2026-08-07): manual ops must be EASY,
FOREVER.** "ensure capabilities are set up so people can do this
easily and manually in the future." The bring-up (and every op like
it) must end up a first-class, documented, repeatable capability —
not a Claude-dropped script:
- isle CLI verb (fold isle-bringup-mac2.sh into `isle` proper —
  boot-bringup exists as a script; make bring-up + persistence +
  verify ONE obvious verb an average user can run);
- manager-app button for the same (isle's own CLI↔app parity rule);
- installed BY DEFAULT (.deb postinst installs boot persistence —
  a fresh install should never be missing isle-mesh-boot.service
  the way isle-core was);
- documented in GETTING-STARTED, not tribal knowledge;
- sudo grants stay operator-explicit (a knob, never baked in).
This is the isle "average-user story" applied to operations:
install → works, reboot → recovers, one command → verifiably up.
Lands in mac-2 (bring-up verb) + mac-8 (postinst defaults) +
mac-10 (console/manager button, host+login gated).

## 14. Isle stack LIVE + grant installed (2026-08-07, night)

Dustin ran `~/isle-bringup-mac2.sh --grant` on isle-core (via real
terminal — NB the Claude `!` prompt can't do interactive sudo):
router VM openwrt-isle-router RUNNING (reachable 192.168.1.1),
bridges br-mgmt/br-my-isle/isle-br-0 up, enp1s0 (the switch cable)
enslaved to br-my-isle, macvlan bound, isle-mesh-boot.service
INSTALLED+enabled, hotplug installed, **passwordless sudo granted**
(/etc/sudoers.d/isle-claude — the work-split capability; revoke =
rm). ⚠ boot-bringup reported "agent failed to start" but a manual
`docker start isle-vlan-agent` worked immediately (startup race —
container was Created-not-started; fold a retry into the mac-2
verb). Agent generated sample.local config on start.

Sync hardened (live-caught, all committed): agent container is
isle-vlan-agent (not isle-agent); fragments live at
agent/nginx/configs (ladder tries both); router detection via
`sudo -n virsh` with the grep -c prints-0-AND-exits-1 trap fixed
(SAME bug class as isle's own 8130095); 🔑 IsleAppService silently
dropped device_name — param existed but was never assigned to self,
and treeObjectInit DROPS unassigned params without error → AST
param-assignment guard now in selftest (42/42). This gotcha is
GENERAL to all polari basis classes.

FINAL LIVE STATE: 3 real devices w/ truthful agent/router facts +
mock guest (banner up); real registry (health+sample), real service
row, real protocol matrix (sample.local http-redirect + https →
isle-sample-app:5000). The visualization is doing its job: every
layer that came up tonight is visible as data.

## 16. Browser loop LIVE + lean prep done (2026-08-08)

- **In-browser testing WORKS**: Chrome extension connected
  (mcp__claude-in-chrome__* was already in project permissions;
  Dustin opened Chrome). Self-verified /isle-mesh visually, found
  + fixed two same-box label collisions unaided (final form:
  straight inner serves-edge + dashed LEADER LINE to URL labels
  hanging outside the box's left edge). The verify loop is now:
  edit → build → roll → hard-refresh → screenshot, no Dustin
  required.
- Cleanup DONE: polari-engines stack removed; pol-core builder
  prune 6.2G (67%→61%); isle-core debris pruned.
- **Lean confirmed by Dustin** ("start lean so we can test"):
  stateless-tier shape (backend+frontend+KC+mariadb, no
  persistence). All four :staging images SHIPPED to isle-core
  (~1.9G, over home wifi — cable-SSH via IPv6 link-local timed
  out; sshd/firewall on isle-core doesn't take it yet, note for
  mac-2). NEXT: isle-side compose override (no published ports,
  isle-agent-net, .isle hostnames) + agent registry entry
  (polari.isle / api.polari.isle) + router DNS registration.

## 17. 🏁 POLARI IS ON THE ISLE (2026-08-08, night)

**prf-isle LIVE on isle-core, served ONLY through the isle:**
- `~/polari-isle/docker-compose.yml` (isle-core): prf-backend +
  prf-frontend :staging images, NO published ports, containers on
  isle-agent-net, sqlite, POLARI_MODULES=islemesh, no KC (lean
  tier — read surfaces are unauthenticated; login arrives with the
  full tier). runtime-config points at api.polari.isle.
- Registered via ISLE'S OWN verbs (`agent-manager.sh register` ×2 —
  single-service-per-app limitation → polari + polari-api as two
  apps; the multi-service registry shape exists but no verb fills
  it = mac-4 converter gap, recorded). Certs openssl'd into the
  agent's ssl dirs (<domain>.crt convention). Agent regenerated +
  reloaded, stayed healthy.
- `https://polari.isle` → 200, `api.polari.isle/api/health` → 200
  THROUGH the agent. 🔑 backend boot log: RoleAutoConfig ran the
  2026-07-03 first-boot mesh logic FOR REAL — "meshed=False → 0
  instances found → DECISION: prf-isle → parent".
- **.isle DNS registered on the router**: polari.isle +
  api.polari.isle → 10.10.0.2 (agent's macvlan IP), resolvable
  from any isle node via 10.10.0.1.
- **THE MESH FEEDS ITSELF**: ~/polari-isle/push-to-polari.sh +
  systemd timer (2min, enabled): device facts + registry +
  fragments POSTed to api.polari.isle — REAL data only, never the
  mock flag. prf-isle's OWN /isle-mesh graph now shows polari.isle
  being served (the system observing itself). Pusher gotcha:
  User=detts needs `sudo -n virsh` for router detection (fixed).
- Frontend port gotcha: staging frontend nginx ANSWERS ON 4200
  (not 80 despite both exposed) — register --port 4200.

**To browse prf-isle from pol-core** (until the real mac-2 join):
pol-core needs an isle lease + name resolution — Dustin's two
commands: `sudo dhclient eno1` then /etc/hosts entries
`10.10.0.2 polari.isle api.polari.isle` (proper path: thin isle
CLI install + remote split-DNS on pol-core = mac-2 continuation).

**§17 fix trail (Dustin's browser pass caught it):** page loaded
but NO DATA — two stacked causes, both fixed live: (1) CORS — the
backend whitelists origins via CORS_ORIGINS env (config_loader →
api.cors_origins); polari.isle wasn't in it → header added
(compose env CORS_ORIGINS=https://polari.isle,http://polari.isle);
(2) certs — per-domain self-signed certs meant the browser's
interstitial exception for polari.isle did NOT cover XHR to
api.polari.isle (no interstitial is offered for XHR) → ONE SAN
cert (polari.isle + api.polari.isle) installed in both agent slots.
⚠ nginx -s reload inside the vlan-agent doesn't take (pid file) —
kill -HUP 1 works. REMAINING manual: browser must accept
api.polari.isle ONCE (per-origin exception) — goes away when .isle
leaves come from a trusted CA (mac-6). 🔑 LESSON for the merged
model: a mesh-app's API subdomain must share ONE cert with its
web origin, and CORS origins must be part of the app definition
the converter emits (mac-4 requirement).

**§17 CA step (Dustin: "do the CA and then be good" — DONE):**
.isle leaves now issued from THE SUITE'S OWN CA (the mac-6 verdict
executed early): `step ca certificate` offline against
polari-rf-node/ca/.step (provisioner polari-jwk), leaf
issued/polari-isle.{crt,key} w/ SANs polari.isle, api.polari.isle,
*.polari.isle, **\*.isle** (every future isle app pre-covered),
1yr. FULLCHAIN (leaf+intermediate) installed in both agent cert
slots, HUP'd, chain VERIFIES against root_ca.crt (return code 0).
Dustin's single manual step (browser security setting = his):
certutil-import polari-rf-node/ca/root_ca.crt → nip.io AND .isle
all green, interstitials gone for good. 🔑 conventions: agent
reload = kill -HUP 1 (not nginx -s reload); new .isle apps should
get the WILDCARD fullchain copied to their <domain>.crt slot (or
the agent generator learns a default-cert path — mac-4 item).
⚠ the 8760h leaf outlives the 30-day nip.io leaves — different
renewal cadences, note for the ~Sep 5 renew.

## 18. CA trust as an INSTALL STEP — `isle trust` (2026-08-08)

Dustin: detect + automate/instruct certutil imports as part of
installing the isle. BUILT (isle-cli commit on isle-core, synced
to the installed CLI): **`isle trust status|install|cert`** —
status detects trust in the system store, Chrome's NSS db, notes
Firefox's separate store, and runs a LIVE PROBE (--cacert fetch of
an .isle app); install is CONSENT-FIRST (fingerprint always shown;
--yes for postinst use), imports system-wide + user NSS, installs
libnss3-tools when missing. Root at /etc/isle-mesh/ca/
isle-root.crt (= the suite root today).

The full install story (recorded, built at mac-8):
1. .deb postinst → debconf consent → `isle trust install --yes`;
2. browsers on machines WITHOUT the CLI: plain-HTTP `trust.isle`
   welcome page — JS PROBE (fetch https .isle, catch = untrusted)
   → per-platform walkthrough + root download (covers phones:
   iOS profile flow, Android CA install);
3. app shells self-solve (CA pinning + TOFU).
🔑 SECURITY RECOMMENDATION (recorded, mac-6): mint a DEDICATED
"Isle Root CA" with X.509 NAME CONSTRAINTS (permitted DNS=.isle) —
an imported isle root that structurally CANNOT vouch for non-isle
names. Makes the import an honest ask of any user.

**§18 addendum — Dustin's rulings, BUILT:** (a) the app/agent
performs trust actions; (b) CA install is part of CONNECTING TO
THE CORE; (c) auto-update; (d) the JavaFX app prompts for sudo
(pkexec) so consent is a familiar OS dialog. Now live on
isle-core: **trust.isle** (static page + container, registered +
DNS'd: JS probe, per-platform walkthrough, root download — the
phone path); **isle trust fetch** (first-join acquisition —
fingerprint IS the consent; --fingerprint <fp> for app-driven
joins where the agreement/QR carries the expected value);
**isle trust update [--auto]** under the SIGNED-CHANNEL RULE (a
new root is only accepted over TLS the current root authenticates;
re-key demands explicit re-consent) + daily systemd timer.
VERIFIED: update fetches from trust.isle authenticated by the
current root → "up to date". 🔑 X.509 GOTCHA: OpenSSL REJECTS
single-label wildcards — *.isle matches NOTHING; every top-level
.isle app needs an explicit SAN (leaf reissued w/ trust.isle;
registration-triggered leaf issuance joins the mac-4 converter
requirements). Remaining wiring: manager-app join screen invokes
pkexec `isle trust fetch --fingerprint` (mac-10 UI work).

## 19. Leaf reissuance at registration — `isle certs` (2026-08-08)

Dustin: implement leaf reissuance now; wildcards GONE, explicit
SANs preferable anyway. BUILT + VERIFIED (isle commit a49a8ec):
- Signing material split: the isle INTERMEDIATE (+ password) now
  lives on isle-core (/etc/isle-mesh/ca/signing, 0700) — the ROOT
  key NEVER leaves the suite CA on pol-core. isle-core signs .isle
  leaves offline with plain openssl (no step dependency).
- **`isle certs status|sync|issue <domain>`**: per-domain EC
  leaves, explicit single SAN, 365d, fullchain (leaf+intermediate)
  into the agent slots + HUP. `sync` reconciles every
  registry.json domain (apps + subdomain.domain), idempotent,
  30-day renew threshold. `status` = honest per-domain table
  (missing/self-signed/wrong-san/expiring/ok).
- **Registration hook**: agent-manager register → certs issue —
  VERIFIED live (re-register trust → new leaf + reload inline).
  All five registered domains reissued as individual explicit-SAN
  leaves; served SNIs confirmed one-domain-one-leaf; trust update
  still green (root unchanged — leaves rotate freely under it).
- 🔧 gotchas: process-substitution extfile dies under sudo (real
  file in a USER-owned 0700 tmp); /usr/share installed-CLI copies
  need sudo cp + chmod 755; remote heredoc patching of quotes =
  pain, Write+scp instead.
Renewal story now: leaves auto-renew via `isle certs sync` (add to
the boot reconcile + a timer at mac-2 verb consolidation); the
ROOT rotates via isle trust's signed-channel update. The two
cadences are decoupled by design.

## 20. Dustin's directive (2026-08-08, near-verbatim): the GENERAL
## isle app store

> "we want to ensure that we have a general app-store capability
> for isle-mesh based on how we made the polari app store. It
> should incorporate both the capability to put arbitrary apps up
> as docker swarm apps with .isle endpoints (auto-configured to be
> isle apps) and also be able to treat polari apps as individual
> apps as well, and automating making the other apps like odoo or
> the like, capable of being interconnected with polari and
> serving as polari engines."

As separated:
1. **General store, appstore-1 idiom**: catalog + artifacts +
   install receipts, generalized from shells to MESH-APPS.
2. **Arbitrary apps → swarm apps w/ .isle endpoints, AUTO-isle**:
   the mac-4 converter as a STORE INSTALL pipeline — compose in →
   deployed (compose now, swarm when the stack rides the isle) →
   agent-registered → leaf issued (the §19 hook) → .isle DNS →
   visible in the graph. Zero manual steps.
3. **Polari apps as individual apps**: PolariAppDefinition entries
   in the SAME catalog (install = shell or .isle website slice —
   the appstore content layer reused).
4. **Engine interconnect**: a package DECLARES what it provides
   (e.g. odoo → business-ops engine); install writes polari
   provider rows (provider_registry / ServiceConnection idiom, the
   odooconnect/MSCI_ENGINES_URL pattern) so polari modules resolve
   the app as an ENGINE automatically.

**§20 progress — `isle app deploy` PROVEN (2026-08-08):** the
store's INSTALL PIPELINE (arbitrary #2) works end-to-end. One
command: compose → isle-overlay.yml auto-attaches every service to
isle-agent-net → compose up → agent register → leaf issued via the
§19 hook → .isle DNS → graph. Dogfooded with traefik/whoami (an
app the mesh had never seen): CA-trusted cert (DNS:whoami.isle),
https://whoami.isle live, edge in the graph — ZERO manual steps.
`--engine <kind>=<urltmpl>` writes engine.json (the provider-wiring
seam for #4). Remaining §20 legs: catalog rows polari-side (#1),
polari apps as catalog entries (#3), install→polari provider row
(#4 wiring), swarm-mode (rides mac-3 stack render).

## 21. Dustin's addition (2026-08-08): shared-code JavaFX shells

> "we will want to be able to use deb to install modules, and then
> have it become basically presenting polari apps as though they
> are individual javaFx apps. However ... we want ... these deb
> installed javaFX apps that are polari or isle shells to be
> sharing as much code as they possibly can so that we decrease
> the amount of space taken up ... while still giving the user the
> impression that they are native apps."

Model (to build): ONE shared runtime, MANY thin launcher .debs.
- **`polari-shell-core`** .deb: the JavaFX/JCEF runtime + all
  common code (the polari-app-shell :core/:desktop already exists
  — this is its packaging as a SHARED dependency, installed once).
- **per-app launcher .debs** (`polari-app-<name>`, `isle-app-
  <name>`): tiny — a .desktop entry + icon + a config pointing the
  shared runtime at that app's .isle URL / PolariAppDefinition
  slice. Depends: polari-shell-core. NO bundled runtime.
- Result: N "native" apps in the launcher, ONE ~55MB runtime on
  disk instead of N×55MB. Each opens its own window at its own
  URL — the native impression, shared bytes underneath.
- This is the DELIVERY side of the store (§20 #1/#3): a catalog
  "install" of a polari/isle app = apt-install its launcher .deb
  (pulls the shared core once). Ties to mac-8 (three .deb kinds)
  + the module-.deb story. jpackage/jlink share a runtime image;
  the launcher debs are Depends:polari-shell-core, not fat jars.

## 22. Shared-code shells BUILT + VERIFIED (§21, 2026-08-08)

The foundational delivery layer. `polari-app-shell` branch
`dev-shared-shells`:
- **`shells/build-shared-shell.sh`** → `polari-shell-core_0.1.0_
  amd64.deb` (53MB deb, 177MB installed ONCE at /opt/polari-shell,
  provides /usr/bin/polari-app-shell). gradle :desktop:installDist
  → jpackage --type app-image (bundled JRE+JCEF) → dpkg-deb. BUILT.
- **`shells/build-launcher-deb.sh`** → thin per-app launcher debs
  (**4KB**, Architecture: all, Depends: polari-shell-core). A
  .desktop entry runs the shared runtime with `--config` at a
  per-app ShellConfig JSON (isle CA embedded in tls.caPem). BUILT
  polari-app-polari (config VALIDATED against core's
  ShellConfig.looksValid — kind/schemaVersion/instances/webUrl/CA).
- 🔑 NO core change needed — the existing ConfigLoader precedence
  (--config wins) already supported one-runtime-many-configs.
- SPACE PROVEN: 20 apps = 173MB shared vs 3464MB fat (saves 3.3GB);
  savings grow linearly. This is §20 #1/#3 delivery + mac-8's
  polari/isle app .debs.

Remaining: install-test on a clean machine (dpkg -i core + apt
launcher → icon in menu → opens polari.isle in its own window);
`pol shell` / `isle app` verb wrappers to emit launchers from
catalog rows. NEXT (Dustin's order): odoo-as-engine, then catalog.

## 23. Engine interconnect PROVEN LIVE (§20.4, 2026-08-08)

`isle app deploy <name> --engine <kind>[@<url>]` makes an installed
isle app a polari ENGINE automatically. FULL LOOP DOGFOODED on
prf-isle:
- deploy `books --engine business-ops` → engine.json (provides +
  url, auto-derived http://<container>:<port>); pusher POSTs it to
  /api/islemesh/ingest/engine.
- polari: **IsleEngine** row + **binder** (islemesh_engines.py) —
  business-ops/odoo → **OdooInstanceConfig.base_url** upserted at
  the isle url. LIVE RESULT: `bound:true, bound_to:
  OdooInstanceConfig:books, note: wired ... -> http://isle-books-
  books-1:80`. GET /api/islemesh/engines lists them.
- Unknown kind / absent-consumer → recorded available-but-unbound,
  named honestly (binds when the module lands). Unit-proven both
  paths (selftest 45/45, real OdooInstanceConfig written).
- 🔑 arg gotcha: `<container>` template chars are shell redirects →
  switched to `--engine <kind>` (auto-derive) | `<kind>@<url>`.
- ⚠ REFINEMENT (recorded): the binder imports the consumer module
  (code ships in the image) rather than checking it's ENABLED in
  defClassList — on a lean instance the row is written ahead of the
  module's CRUDE surface. Correct for "config present when enabled";
  a _feature_available gate would be more precise (later).

Store directive status: §20 #2 (arbitrary→isle, proven) + #4
(engine interconnect, proven) + §21/§22 (shared shells, built)
DONE. Remaining: catalog rows generalizing appstore-1 (#1/#3) —
Dustin's next in order.

## 24. The general isle app store COMPLETE (§20.1/§20.3, 2026-08-08)

`isle store` — appstore-1 generalized over the two proven variants.
PROVEN end-to-end:
- **Catalog in polari**: `IsleCatalogEntry` rows + `install_plan`
  builder; `/api/islemesh/catalog` (list) + `/catalog/{entry}`
  (detail + host install-plan). Seeded polari/whoami/odoo across
  both kinds — never mock. selftest 51/51.
- **`isle store list|show|install`** (host CLI): browses the
  polari catalog, RUNS the plan on the host — the backend never
  deploys (mover-on-host). `isle store install whoami --yes` →
  catalog plan → `isle app deploy` → container+cert+DNS, fully
  automatic. LIVE.
- **kind dispatch**: mesh-app → `isle app deploy` (arbitrary
  compose/image, §20.2); polari-app → shared-shell launcher .deb
  (§21/§22); polari-module → module .deb (mac-8). One front door
  over both proven variants + modules.
- app-deploy gained `--image` (synthesizes a one-service compose)
  for the catalog's bare-image entries.

🏁 **STORE DIRECTIVE (§20) COMPLETE**: #1 catalog ✅, #2 arbitrary→
isle ✅, #3 polari apps as entries ✅, #4 engine interconnect ✅;
delivery via shared shells (§21/§22) ✅. The isle now has a general
app store that treats arbitrary apps, polari apps, and engines
uniformly — install is one command, everything auto-isle
(cert/DNS/graph), engines auto-wire to polari.

Remaining polish (not blocking): the store as a VISUAL page (the
mac-10 console gets a store tab reading /catalog); a real odoo
install (2GB pull — deferred, unit+plan proven); `_feature_
available` gate on the engine binder; multi-service registry
(the recurring converter gap).
