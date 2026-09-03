# VPN + federation for isles (vpn arc): peer-to-peer tunnels, a shared hub that federates, coordination-server hosts exported through Polari

**Date:** 2026-09-03 · **Status: PLAN (vpn-0) + his review amendments in §7 (authority isle-side, `.vpn` rung, relay kinds) — D1–D13 to ratify, then vpn-1.
No code changed. Grounded in the mechanics survey of 2026-09-03 (file:line
cites below are from the tree at that date).**

## 0. The capability, stated neutrally

A user of the suite needs, on top of the isle: (a) a **peer-to-peer VPN**
between devices and isles; (b) a **shared, centralized VPN** (a hub with
members) that can **federate** with other hubs and isles; (c) hosts and
internal services managed by a **coordination server** of the Headscale
class, **exported to other networks through Polari's web interface**;
(d) a **web-managed way in** ("influx": a member is admitted through the
web, receives config once) and an optional **exit node** to the internet;
(e) other self-hosting stacks (an OpenVPN-class peer, a YunoHost-class box)
joining as **gateway peers**. None of this exists today except a one-peer
WireGuard tunnel and application-layer consent (§1). Everything below
builds on what does exist rather than beside it.

## 1. What exists and what each piece contributes

| Existing mechanic (cite) | Role in this arc |
|---|---|
| **The isle** = OpenWRT VM, VLAN `eth1.10`, `10.<vlan>.0.1/24`, DHCP `.50–.249`, firewall zone `forward=REJECT`, no WAN zone (`Isle-Mesh/openwrt-router/isle-vlan-router-config-lib/05-config.sh:8-21`, `60-firewall.sh:14-19`) | The unit of membership stays the isle. A VPN adds a second interface (`wg-arch`) into the isle zone; nothing about VLAN membership changes. |
| **`.isle` DNS** written by the join-protocol daemon from avahi into dnsmasq (`configure-join-protocol.sh:204-215`, `local=/isle/`) | The same generator gains `.arch` names from the arch member list (isle-core item I-3). |
| **Containment rule**: `.isle` is ALWAYS internal; "exposing" grants an ADDITIONAL outside URL through an `isle-expose-<port>` gateway container, basic-auth, gated by `/etc/isle-mesh/entrypoint.enabled`, ledgered in `exposures.json` and pushed to Polari (`Isle-Mesh/isle-cli/scripts/url.sh:4-51`, `polari-isle/push-to-polari.sh:29-34`) | A VPN endpoint IS an exposure: one more row in the same ledger, same gate, same push. The `.isle` names never leave; the tunnel carries `.arch` names. |
| **isle-agent nginx = sole ingress**, fragments from `registry.json` (`isle-agent/isle-vlan-agent/generate-nginx-configs.sh:101-109`) → Polari `IsleApp` / `IsleProtocolPermit` rows ("the proxies ARE the policy", `modules/islemesh/islemesh_api.py:269-296`) | Per-app reachability across a tunnel is a fragment with the `.arch` server_name — derived from an exposure row, never hand-written. |
| **One-peer WireGuard** `pol remote` (`polari-cli/scripts/remote.sh`): keys via `wg` or python X25519 (`:57-64`), `wg0.conf` 0600 with no NAT (`:114-128`), phone `AllowedIPs` includes the LAN so nip.io works (`:134-145`), scope-check asserts `ip_forward = 0` (`:150-155`), router UDP forward manual (`docs/REMOTE-ACCESS.md:37-39`) | Generalises to N peers, two modes (mesh, hub) and a KNOB for forwarding. The key idiom (server keeps public keys; the private key is handed over once) is kept. |
| **LiveKit UDP publish** chosen by `islemesh_netledger.free_udp_range()` (`polari-rf-node/docker-compose.livekit.yml:12-15`) | WireGuard's UDP port is allocated from the same ledger; conflicts are the ledger's business. |
| **PeerAgreement**: a child is never auto-admitted; approve mints a per-child scoped revocable token; both sides keep the consent row (`polariPeers/peer_agreement.py:6-18`, `agreements_api.py:92-107`) | The consent record for a federation link. Approving provisions the tunnel credential; revoking tears the peer entry down (§4 vpn-3). |
| **The ladder** `.isle → .arch → .mesh → web`, exposure is ROWS per level carrying our role (`RETICULUM_TRANSPORT_PLAN.md:30`, §5n `:1124-1138`); `.arch` = isles meshed "as one network" (the farmers-market picture); state over Reticulum, deltas between archs | `.arch` gets an **IP transport**: the WireGuard tunnel realises the rung for HTTP/any-protocol apps, while Reticulum keeps the state-relay role. The planned `AppArchExposure` row is the per-app switch. |
| **Topology** rows (machines, instances, ModuleAssignment, stacks.yml placement) + `pol allocate` (`topology/topology_api.py:65-95`) | VPN networks and peers are topology objects; a hub is an instance pinned to a machine like any service. |
| **Certs**: three self-signed roots, `CERT_MODE self-signed|step-ca` (`nip-staging-setup.sh:110-116`), step-ca still "plan / investigation" (`CENTRALIZED_CA_PLAN.md:3`) | `.arch` names need certs both sides trust: step-ca is the engine (vpn-6). |
| **DDNS**: documentation only (`REMOTE-ACCESS.md:85-100`) | A hub needs a stable endpoint: a row + updater knob (vpn-6). |

Absent, verified: OpenVPN (one prose README), Headscale, Tailscale
(rejected once), exit node, hub, site-to-site, cross-site VLAN trunking,
DDNS automation, router WAN zone / masquerade / port-forward config.

## 2. Shape — one object tree, two modes, one consent

```
VpnNetwork  (name, mode mesh|hub, provider wireguard|headscale|openvpn-bridge,
             cidr 10.60.<n>.0/24 from the netledger, udp_port from free_udp_range,
             dns_suffix '.arch', exit_node_allowed KNOB=False, mtu, notes)
 ├─ VpnPeer (network, name, kind device|isle-gateway|hub|foreign-gateway,
 │           machine/device ref, public_key ONLY, address, endpoint (host:port or ''),
 │           allowed_ips_json (own /32 + carried subnets), persistent_keepalive_s,
 │           use_exit_node KNOB=False, status, last_handshake, exposure_ref)
 ├─ VpnAccessRule (network, from_tag, to_tag|cidr, allow|deny — rendered as
 │           AllowedIPs + an advisory nftables text; the router applies it)
 ├─ VpnFederationLink (network_a, remote_base_url, remote_network, gateway_peer_a,
 │           remote_gateway_public_key, remote_cidrs_json, agreement_id → PeerAgreement,
 │           status pending|active|revoked, arch_name)
 ├─ AppArchExposure (app, arch_name, role observer|user|relay-only|server — the
 │           ladder's planned row, built here; renders the .arch fragment)
 └─ VpnEndpointExposure = the isle exposure row (exposures.json) for the UDP port
Provider adapters: wireguard-native (rows are the control plane; we render),
                   headscale (rows mirror a Headscale server: nodes/users/routes/
                   ACL/pre-auth keys via its API; BSD-3),
                   openvpn-bridge (LAST: cert-signed server.conf + .ovpn for peers
                   that only speak OpenVPN; config text only, GPLv2+SSL-exception
                   binary in its own container).
```

- **mesh** = every peer carries every other peer (P2P); **hub** = members
  carry the hub only, the hub carries all (the shared centralized VPN);
  a hub-to-hub or hub-to-isle-gateway `VpnFederationLink` is what
  "federates" — routes are exchanged as `remote_cidrs_json`, consent is
  the PeerAgreement, `.arch` is the name space both sides serve.
- **Exit node** = a hub peer with `PostUp` masquerade rendered ONLY when
  `exit_node_allowed` is on (default off; `scope-check` keeps asserting
  `ip_forward = 0` otherwise). Members opt in per peer (`use_exit_node`).
- **Influx** = a member joins through the web: `POST /api/vpn/join-request`
  (a PeerAgreement with `requested_role vpn-member`) → an operator approves
  on `/display/vpn` → the member fetches config + QR ONCE (private key
  generated client-side in the browser or by `pol vpn`; the server never
  stores it) → the peer row goes active on first handshake.
- **Coordination-server hosts exported through Polari** = the headscale
  adapter mirrors that server's nodes as `VpnPeer` rows + `IsleDevice`
  rows in the islemesh acceptor; the apps on them are `IsleApp` rows with
  `AppArchExposure` rows deciding what is reachable from which network —
  the existing `/display/isle-mesh` matrix shows it.

## 3. Security stance (non-negotiable)
Private keys never persist server-side (public keys only; one-time
delivery). Nothing forwards by default (`ip_forward` stays 0 unless the
exit-node knob is on, and then only on that hub). A federation link
exists only behind an approved PeerAgreement and dies with its
revocation. The `.isle` containment rule holds: the tunnel serves
`.arch` names, never `.isle`. Every exposure is a ledger row pushed to
Polari, so `/display/isle-mesh` always shows what is reachable from
where. Licence gate before an engine is adopted: WireGuard (GPLv2 kernel
/ MIT tools, we render text), Headscale (BSD-3), OpenVPN (GPLv2 + OpenSSL
exception — binary isolated in its own container, never linked), any
Tailscale coordination server (proprietary — ⛔).

## 4. Phases (suite-side unless marked isle-core)

- **vpn-0 — this plan.** ✅
- **vpn-1 — objects + engine + selftests** (`modules/vpn/`): the rows in
  §2; `keygen()` (X25519 → base64, the remote.sh idiom, returned once);
  address allocation from the network cidr; `render_wireguard(peer)` for
  mesh / hub / exit; `render_access_rules`; UDP port from
  `islemesh_netledger.free_udp_range`; provider registry with
  `wireguard-native` live and the other two registered as honest refusals.
  Selftests: mesh conf carries N-1 peers, hub member carries one, exit
  masquerade appears only with the knob, a foreign-gateway's subnet lands
  in AllowedIPs, no private key in any row or export.
- **vpn-2 — API + page + CLI**: `/api/vpn/networks|peers|links|join-request|
  config/{peer}|status`; `/display/vpn` (tables, api-structured-panels,
  the join-approval and add-peer FORMS — no new components); `pol vpn`
  extends `pol remote` (`init --mode mesh|hub`, `peer add`, `qr`, `apply`,
  `status`, `federate <url>`); `wg show` parsed into `last_handshake`.
- **vpn-3 — the trust bridge**: approving a PeerAgreement whose
  `requested_role` is `vpn-member` or `vpn-federation` provisions the peer /
  link (gateway public keys + cidrs exchanged in the approval payload);
  revoke removes the peer entry and re-renders both sides. The join flow
  reuses `polariPeers/join_flow.py` verbs.
- **vpn-4 — `.arch` over IP**: `AppArchExposure` rows render `.arch`
  fragments on the isle-agent (derived, never hand-written); the arch
  member list feeds the router's DNS generator; the remote isle's
  `push-to-polari` runs over the tunnel so the acceptor ingests both
  isles; `/display/isle-mesh` gains the arch column.
- **vpn-5 — providers**: `headscale` adapter as its own compose stack,
  knob-gated (the mqttbridge precedent): nodes/users/routes/ACL/pre-auth
  keys mirrored to rows, pre-auth keys as the influx credential; then
  `openvpn-bridge` (cert-signed configs from the suite CA) for peers that
  cannot speak WireGuard.
- **vpn-6 — endpoint stability + names**: a DDNS row + updater knob for
  hubs; step-ca issuance for `.arch` names (CENTRALIZED_CA_PLAN's chosen
  direction) so both sides trust the fragments.
- **vpn-7 — isle-core items** (handed over through NOTES-FROM-POL-CORE's
  append-only channel; Polari renders, the router applies):
  I-1 `wireguard-tools` + `wg-arch` interface on the OpenWRT VM in the isle
  zone; I-2 firewall: forward isle↔wg-arch per VpnAccessRule text, WAN UDP
  forward for the hub port (today no WAN zone exists); I-3 `.arch` names in
  the join-protocol dnsmasq generator; I-4 `isle expose` learns the
  `vpn-endpoint` kind; I-5 the agent's fragment generator emits the
  `.arch` server_name from an exposure row.

## 5. Decisions (defaults in bold; his call)
- D1 engine: **WireGuard-native rows first**, Headscale as an adapter,
  OpenVPN only as a bridge for foreign peers.
- D2 `.arch` rung: **IP tunnel AND Reticulum state relay coexist**; apps
  choose per exposure row.
- D3 exit node: **off by default**, per-hub knob, per-member opt-in.
- D4 influx: **PeerAgreement consent, never auto-admit** (the mesh
  convergence ruling); the "auto-approve devices already on my isle" knob
  stays default off.
- D5 addressing: **10.60.<n>.0/24 per network from the netledger**;
  federation exchanges cidrs, never renumbers.
- D6 keys: **client-generated private keys preferred**; server-side
  keygen allowed with one-time delivery; nothing persisted.
- D7 names: **`.arch` served by both routers' dnsmasq from the shared
  member list**; `.isle` never crosses.
- D8 where it runs: hub = a topology instance pinned to a machine with a
  stable endpoint (**DDNS row required before a hub goes active**).

## 6. Selftest + acceptance (per phase, TESTING_OWED rows)
Two-isle demo on this box: two VpnNetworks, one federation link, an app
exposed at `.arch` reachable from the other isle's device; the exposure
visible on `/display/isle-mesh`; revoke → unreachable within one render.

## 7. Amendments from his review (2026-09-03 morning) — these override §2–§5 where they differ

**7.1 Licence answer (verified stance; re-check LICENSE files at pin time).**
WireGuard is fully open source: kernel implementation GPLv2 (mainline
since 5.6), `wireguard-tools` GPLv2, `wireguard-go` MIT, the protocol a
published spec on the Noise framework with no patent claims. Our GPLv3
tree never copies GPLv2-only source; it DRIVES WireGuard as a separate
program or through the kernel's netlink interface (subprocess `wg`,
`wg show` counters, pyroute2 GPLv2/Apache dual, config rendering,
on-the-wire analysis). Custom analysis/security wrappers are therefore
legal and stay GPLv3. `wireguard-go` (MIT) is the only piece we could
ever embed. Trademark: the module is `isle-vpn`, described as
"WireGuard-based" — never named WireGuard.

**7.2 `.vpn` is a rung and an exposure row.** The ladder becomes
`.isle → .arch → .vpn → .mesh → web`. An app exposed at `.vpn` is
reachable by the members of the VPN the isle's gateway belongs to. The
`.vpn` option appears in `isle expose` / the exposure form ONLY when an
installed VPN app of gateway kind is registered in the isle catalog
(the IsleCatalogEntry "providing engine" idiom: `vpn-gateway`). Names
`<app>.vpn` are served to members by the gateway's DNS; `.isle` still
never crosses.

**7.3 Configuration authority is the isle-mesh side — Polari mirrors.**
The VPN app's config API binds to isle-local addresses only (the
isle-agent's 127.0.0.1 / isle-address binding precedent) and REFUSES
any request arriving over the tunnel interface or from a non-isle
source. Polari's `VpnNetwork/VpnPeer/…` rows are a MIRROR fed by
`push-to-polari` (the islemesh acceptor rule "isle stays authoritative
over networking") plus PROPOSALS (rows with status `proposed`) that a
local operator applies on the isle with `isle vpn apply <proposal>`.
Nothing reached remotely or through the VPN can alter the VPN. This
inverts §2's "rows are the control plane": the control plane is the
isle-side app; the rows are its shadow and its inbox. Consequently
vpn-1/vpn-2 split into an isle-side half (Isle-Mesh repo, isle-core's)
and a Polari-side half (mirror, proposals, pages, analysis).

**7.4 Expose the manual configuration surface.** The app/module exposes
what a hand-written `wg` setup exposes, grouped basic/advanced:
Interface — private key (generated on the device, never leaves it),
listen port, addresses, DNS + search, MTU, fwmark, routing table,
SaveConfig; Peer — public key, preshared key (optional symmetric
layer, a post-quantum hedge), allowed IPs, endpoint, persistent
keepalive; plus routing/firewall rules (nftables text rendered from
VpnAccessRule), forwarding + masquerade toggles, key and preshared-key
rotation schedules, handshake/transfer monitoring. GUARD: PreUp/PostUp/
PreDown/PostDown are NOT free text (root shell) — templated toggles
only (forward, masquerade, route add), each a named knob.

**7.5 App kinds — relays are not one thing.** Catalog kinds for the
VPN app package, chosen at install: `vpn-node` (an endpoint; carries
its own /32), `vpn-gateway` (carries its isle subnet; what makes `.vpn`
available), `vpn-relay-blind` (forwards ENCRYPTED WireGuard datagrams
between peers that cannot reach each other — holds no keys, sees no
plaintext; the default for federation across isles and safe on a
rented box), `vpn-relay-routing` (an IP-layer forwarder that is a PEER
of both sides and therefore sees plaintext — a hub you own, required
for exit-node and subnet routing), `vpn-hub` (routing relay +
membership authority), `vpn-exit` (routing relay + masquerade to WAN,
the exit-node knob). The distinction is shown on every row and on the
`/display/isle-mesh` matrix so nobody mistakes a blind relay for a hub.

**7.6 Decisions added (defaults in bold; his call):**
- D9 authority: **isle-side app; Polari read + propose only; the config
  API refuses tunnel/remote sources.**
- D10 federation relays: **blind by default**; routing relays only on
  hubs the household owns.
- D11 hooks: **templated toggles, no free-text shell.**
- D12 naming: **`isle-vpn` module/app, "WireGuard-based".**

**7.7 OpenVPN as a full second provider (his question 2026-09-03).**
Licence: OpenVPN 2.x GPLv2 + OpenSSL exception; OpenVPN 3 core/Linux
client AGPLv3 (GPLv3-compatible but stricter — never embed, only
drive); ovpn-dco kernel offload GPLv2. Same rule as WireGuard: driven
as a separate program, never copied into the GPLv3 tree; a fork would
be its own GPLv2 pin. Modifiability is architectural, not legal:
OpenVPN offers a plugin API, a management interface (live client list,
kill, byte counts, signals), connect/learn-address/up/down hooks,
per-client config dirs and server-pushed routes/DNS — far more runtime
hooks for analysis and security tooling than WireGuard's netlink +
`wg show`. It also does L2 (tap) bridging (the archipelago README's
VLAN-across-sites idea), x509 identity with CA + CRL (fits step-ca and
PeerAgreement-as-consent), and TCP/443 traversal. It cannot do mesh or
a blind relay (the server always decrypts), and its attack surface and
speed are worse than WireGuard's. Recommendation: WireGuard stays the
core (node / gateway / mesh federation / blind relay); OpenVPN becomes a
FULL provider for L2 bridges between isles, x509 hubs, TCP/443 paths and
OpenVPN-only peers (YunoHost-class). Both providers expose the same row
shapes; the analysis/security wrappers target the management interface
(OpenVPN) and netlink/`wg show` (WireGuard) behind one interface.
- D13 providers: **WireGuard core + OpenVPN full provider (driven, not
  embedded); OpenVPN 3 only if AGPL terms are accepted.**
