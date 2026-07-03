# Mesh Convergence Plan — Isle-Mesh × Polari

_2026-07-03, from Dustin's brief. This document is deliberately shared ground between the
two projects (and the two Claude instances): committed in polari-suite AND copied to
isle-core:~/Isle-Mesh/. Each project keeps its own memory; this plan is the seam._

## Purpose (Dustin's framing)
Isle-Mesh generalizes making a capable, generalizable VLAN on top of the normal LAN, and
its CLI generalizes making apps able to talk to one another through automation
("mesh-apps"). Polari rides it as the first first-class mesh-app, with its node network
(parent/child) auto-configuring from mesh presence. Weave the two coherently, with
minimal footprint per role.

## 1. Component matrix (coherent + minimal footprint per variant)

| Component  | HOST                                            | REMOTE |
|------------|--------------------------------------------------|--------|
| CLI        | full: create/destroy/scan/appify/package/…       | thin subset: join/leave/integrate/status |
| Manager app| full UI                                          | SAME package, COLLAPSES to client mode on detection (no router capability → client) |
| Agent      | optional (host's own apps register locally)      | required: DHCP/macvlan attach + app-registration relay |
| Router VM  | yes (OpenWRT qcow2, DHCP + .isle DNS)            | never |

Acceptance rule: nothing installs on a remote that only the host needs, and vice versa —
audit each variant's payload against this table.

## 2. Mesh-app pipeline (isle CLI)
1. `isle appify <docker-compose.yml>` — scaffold an existing compose for the mesh:
   network attachment (macvlan on isle-br-0, DHCP from the router), .isle DNS names
   (the existing auto-.isle nginx generation), lifecycle hooks, mesh labels.
2. `isle package <scaffolded-app>` — generate a **Debian package** from the compose:
   payload = compose + scaffolding + assets; `postinst` = SELF-INTEGRATION:
   - detect isle-mesh presence (thin CLI installed? agent running? isle joined?)
   - present → `isle app integrate` (attach networks, register DNS, announce)
   - absent → run as a plain local compose app (**graceful degradation** — a mesh-app
     is still just an app; the mesh is an upgrade, not a dependency).
3. Average-user story (the acceptance narrative): install manager app on the main
   machine → install the same manager app on other machines (client-collapse) → install
   any isle-generated .deb on any device; apps weave themselves in.

## 3. Polari as the first first-class mesh-app (the weave)
- Polari's .deb is produced by the SAME pipeline from its compose (the twin build's
  INSTANCE_ID parametrization is the direct prep).
- First-boot mesh logic in the Polari backend (all knobs-and-suggestions compliant —
  detection SUGGESTS, explicit knobs decide, auto is the default posture):
  1. **Detect** mesh via the "mesh facts" interface (below).
  2. **Register** itself: claim `polari-<host>.isle`.
  3. **Discover** existing Polari instances on the mesh (registry/DNS lookup of the
     well-known parent claim + peer ping on discovered names).
  4. **Conditional role**: none found → configure as PARENT (claim the parent name);
     parent exists → configure as CHILD: register as the parent's peer (token via mesh
     trust, see open point), pull the coordination module via the modules API
     (/api/modules install from peer), assume Track 4 member role.
- Division of responsibility (the coherence rule): **Isle-Mesh owns** L2/L3 (VLAN, DHCP,
  .isle DNS), packaging, app scaffolding/integration, device inventory. **Polari owns**
  application peering, modules, placement, simulation coordination. Isle-Mesh never
  learns what Polari is (it's just a mesh-app) — information hiding between projects.

## 4. The seam: the "mesh facts" interface
A small READ interface the agent/thin CLI exposes and any mesh-app may consume:
  am-i-meshed? · my .isle name · known devices · existing service-name claims ·
  claim(name) / release(name) with atomic first-claim-wins semantics.
Shape TBD by the Isle-Mesh side (CLI subcommand with JSON output is fine: `isle facts
--json`); Polari consumes it read-only + performs claims. Keep it one-way and minimal.

## 5. Open design points (Dustin to rule)
1. **Parent-claim race**: two Polaris installed near-simultaneously. Proposal:
   first-claim-wins via the atomic mesh-registry claim; the loser configures as child;
   a manual role knob overrides either way; the manager app surfaces the topology.
2. **Child token distribution**: the peer-registration secret should ride the mesh's own
   join trust (isle join secret or agent-mediated exchange), not hand-copying. Later:
   Keycloak federation replaces shared tokens.
3. Degradation depth: does an unmeshed Polari .deb install single-instance-standalone
   (proposed: yes, full function, zero mesh references) — confirm.

## 6. Sequencing across the two projects
- Isle-Mesh side (other instance): appify/package (.deb gen) hardening; the component-
  matrix footprint audit; the `isle facts` read interface + atomic claims.
- Polari side (this instance): finish the no-code foundations workstream (in flight);
  then mesh-detection + role auto-config module (consumes `isle facts`), .deb-friendly
  first-boot behavior, PeerNode base_url on .isle names; Track 4 placement rides it.
- Integration milestone: **two machines, manager app + one .deb each, zero manual
  network/peer configuration → a parent/child Polari pair exchanging a module.**
