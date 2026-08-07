# Capability survey — polari × isle-mesh (merge analysis)

**Date:** 2026-08-07 · surveyed from live code on BOTH machines
(pol-core repos + `isle-core:~/Isle-Mesh`, branch `dev-consolidation`).
Companion to `MESH_APP_CONVERGENCE_PLAN.md` (phases) and
`MESH_APP_CONVERGENCE_HANDOFF.md` §5–8 (decisions).

**Goals being served** (Dustin 2026-08-07): isle authoritative over
networking w/ true vLAN isolation · swarm rides on top as the
dynamic up/down/move layer · polari topology drives the dynamics ·
apps are simultaneously local apps AND mesh websites via `.isle` ·
installs managed by polari alongside the isle-agent.

**Precedent:** the two projects ALREADY share a seam doc —
`MESH_CONVERGENCE_PLAN.md` (2026-07-03, committed BOTH sides) ruled:
*"Isle-Mesh owns L2/L3 (VLAN, DHCP, .isle DNS), packaging, app
scaffolding/integration, device inventory. Polari owns application
peering, modules, placement, simulation coordination."* This survey
extends that ruling to the swarm layer; it does not overturn it.

---

## 1. Networking (L2/L3)

| | isle-mesh | polari |
|---|---|---|
| Has | OpenWRT router VM (DHCP + authoritative `.isle` DNS), macvlan `isle-br-0`, covert 2-machine isle over dedicated cable (~1ms, PROVEN), remote leases that never hijack ISP route, plug-and-play (cable self-configures router, hotplug udev, boot self-recovery, self-forming bridge of non-ISP cables), split-DNS for remotes, mDNS layer | nip.io hostnames on the home LAN, docker overlay networks inside swarm, static /etc/hosts-style conventions |

**Verdict — ADOPT ISLE OUTRIGHT.** This is the decided authority
split and isle's is proven where polari has only conventions. Polari
contributes nothing here except *demand* (its services become the
biggest tenant). nip.io stays as the home-LAN web tier until the
isolation cutover retires it deliberately.

## 2. Device ingress / proxy

| | isle-mesh | polari |
|---|---|---|
| Has | isle-agent: ONE nginx per device, virtual MAC for router DHCP, per-app config FRAGMENTS merged live (zero-downtime reload), jinja segments (http/https/subdomain/mTLS/security-headers), `generate-app-fragment.py` from compose | prf-proxy: per-instance nginx, jinja-rendered from manifest ROWS (vhost manifest caught the SAN bug), pol-build render pipeline |

**Verdict — CONVERGE: isle-agent is THE device ingress; polari's
manifest-rows idiom is the render source.** Both are jinja→nginx —
the merge is real: agent fragments get RENDERED FROM polari topology
rows *through isle's generators* (polari never writes raw files).
prf-proxy survives only as an app-internal proxy inside the polari
mesh-app, behind the agent.

## 3. App definition & packaging

| | isle-mesh | polari |
|---|---|---|
| Has | `scaffold.sh` (1124L) compose→mesh-app (SSL+nginx+metadata), `app-package.sh` compose→**.deb with desktop icon + up/down/access/status wrapper**, postinst SELF-INTEGRATION w/ **graceful degradation** (no mesh → runs as plain compose app), app types localhost-mdns/isle, `isle app mode` verb | `PolariAppDefinition` (app = module/pages/nav config), appstore (enrollment tokens, MinIO artifacts, catalog), app-shell (desktop JavaFX/JCEF + android + vr + ios sources, PROVEN loop), `module_bundle` JSON (polari modules travel between instances), grpcbridge tarball precedent |
| Gap | registry wiped on agent restart (fix branch exists — VERIFY merged into dev-consolidation), per-app .deb "unclear" per its own REVAMP plan | apps assume the polari backend; no story for arbitrary compose apps |

**Verdict — UNIFY AROUND ONE MeshApp MODEL, TWO PACKAGE KINDS.**
isle's .deb IS the "local app" realization (icon + wrapper) and its
graceful-degradation postinst is a keeper principle. Polari's store
is the distribution channel (catalog, tokens, MinIO) — isle .debs
become store artifacts alongside shells. Keep `module_bundle`
(polari-object modules) and .deb (container apps) as distinct
package kinds under ONE catalog; don't force them into one format.

## 4. Orchestration & placement

| | isle-mesh | polari |
|---|---|---|
| Has | per-app `docker compose up/down` via wrapper; **AVAILABILITY-MODES.md**: up-trigger × down-trigger × placement incl. `resource-permitting`/`resource-pressure`/`replicated`; always-available IMPLEMENTED (router autostart, boot reconcile, linger); on-demand SCAFFOLDED (wake via device relay — planned) | swarm cluster LIVE (3 nodes, `polari.machine` labels), `stackify.py` compose→stack w/ placement constraints, `pol swarm deploy/relocate`, **staged STATEFUL movers** (sqlite/MinIO/mariadb: quiesce, staged copy, verify, never delete source), **MoveOperation ledger** (moves as data, measured durations→ETAs), mlb lazy boot, topology rows + `pol topology assign` + derived POLARI_MODULES |

**Verdict — POLARI IS THE EXECUTOR, ISLE'S VOCABULARY IS THE
POLICY LANGUAGE.** The flagship merge: isle defined *when* (triggers,
composable knobs — same knobs-and-suggestions rule) but has no mover;
polari built *how* (swarm, staged movers, receipts) but has no
trigger model. MeshApp availability spec = isle's vocabulary;
enforcement = polari's reconciler + swarm; every auto action = a
MoveOperation receipt. Swarm itself gets demoted to mechanism riding
the isle network (decided).

## 5. Registry / discovery / inventory

| | isle-mesh | polari |
|---|---|---|
| Has | `registry.json` = durable desired-state per device (domains/subdomains/services/modes/availability_mode; conflict detection; REVAMP: merge-only-never-wipe, bring-up=reconcile), `.isle` DNS registration (deduped), device inventory, `diagnose.sh` capacity diagnostic, planned **mesh-facts** read interface (am-I-meshed, claims, first-claim-wins) | topology rows (InstanceDefinition/ModuleAssignment/DependencyEdge), provider_registry, portable topology packages, `mesh_facts.py` in polariPeers (the CONSUMER side, already stubbed) |

**Verdict — TWO TRUTHS, ONE CONTRACT, BY LAYER (decided).**
registry.json stays each device's live networking truth; polari rows
are the intent. mac-5's drift-reconcile surfaces divergence as
suggestions. The 2026-07-03 mesh-facts seam is the read interface
and polari's consumer stub already exists — build `isle facts
--json` on the isle side and the two meet in the middle.

## 6. Admission / trust

| | isle-mesh | polari |
|---|---|---|
| Has | join/leave/onboard flows, remote leases, discovery-on-install | **PeerAgreement** — durable bilateral consent, per-child revocable scoped tokens, BUILT to Dustin's 2026-07-03 ruling (never auto-admit; approval mints token; revoke=delete) + join_flow |

**Verdict — ALREADY CONVERGED BY DESIGN.** Polari holds the consent
objects, isle carries the channel. This arc just exercises it: device
joins the isle (isle's flow), polari instance admission rides
PeerAgreement. Nothing to merge — connect.

## 7. Certificates / TLS

| | isle-mesh | polari |
|---|---|---|
| Has | per-app self-signed certs (ssl/ utilities), mTLS nginx segments, `generate-ssl-env-config.sh` | centralized suite CA (3 roots, 30-day leaves — renew ~Sep 5), CERT_MODE knob, offline issuance path, shell CA-pinning w/ TOFU redeem, step-ca centralization plan |

**Verdict — MERGE TOWARD ONE CA HIERARCHY (polari's), ISLE ISSUES
FOR .isle.** isle's per-app self-signed certs are the weakest layer
on either side; polari's CA machinery + the shells' pinning already
handle multi-root. Near-term: shells carry the isle root as a second
pin (mac-6). Long-term: `.isle` leaves issued from the shared CA
(the step-ca plan's natural tenant). isle keeps *deploying* certs
(its segments/agent own the nginx side).

## 8. Management UX

| | isle-mesh | polari |
|---|---|---|
| Has | isle-manager-app (Java .deb, bundles CLI; AppsView drives installed apps, availability-mode control w/ CLI-parity rule; host/client role collapse) | Angular topology + apps + store pages, `pol` CLI (swarm/topology/shell/apps + the refusing `pol isle`), app-shell clients |

**Verdict — KEEP BOTH SURFACES, SAME ROWS UNDERNEATH.** The manager
app is the device-local operator surface (isle's "average-user
story"); polari's pages are the mesh-wide planner. Both must read
the same truth (rows + registry via the contract). isle's
CLI↔app-parity rule ("every availability capability = verb AND
control") is a keeper discipline — adopt it for the merged verbs.
`pol isle` comes alive proxying the isle CLI, never replacing it.

## 9. State moves / cross-instance

| | isle-mesh | polari |
|---|---|---|
| Has | — (apps are stateless-or-local by assumption) | gm staged stateful movers + receipts, xsim cross-instance sim coupling, shared-object DB, graceful mobility ledger |

**Verdict — POLARI ONLY; becomes generic.** When a mesh-app declares
a stateful volume, relocation uses the gm discipline. This is what
makes "move apps around dynamically" honest for real apps.

---

## Gaps NEITHER side has (the genuinely new work)

1. **Swarm-over-isle networking** — swarm control plane advertised
   on isle vLAN addresses; overlay traffic riding the isle. Needs a
   prototype (mac-3); macvlan+overlay interaction is the technical
   risk of the whole arc.
2. **Agent→swarm-service reachability** — fragment upstreams to
   ingress-published ports vs agent attached to overlay (mac-4
   decision, prototype both).
3. **The render pipeline** rows→registry/fragments through isle's
   generators (mac-5).
4. **`.isle` URLs in the delivery layer** — shells/store/deep links
   speak `.isle` (mac-6).
5. **Wake-on-access + resource triggers wired to real signals**
   (isle relay + polari resources module, mac-7).

## Where each side's *character* survives

- isle: the network IS the product; covert, isolated, plug-and-play,
  graceful degradation, average-user .deb story.
- polari: everything is rows + receipts; knobs-and-suggestions;
  honest refusal until proven; staged never-destructive moves.
- The merged system keeps both: isle's network under polari's
  ledgered dynamics — one system, two authorities, one contract.
