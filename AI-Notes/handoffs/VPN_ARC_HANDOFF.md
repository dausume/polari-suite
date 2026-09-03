# Handoff: the VPN + federation arc (vpn-1)

**Date:** 2026-09-03 · **From:** the night-run session (pol-core), updated
the same afternoon by the vpn-1 build session · **For:** the next session
here AND isle-core's own Claude (the isle-side half).

**STATUS 2026-09-03 (afternoon):** D1–D14 ratified ("I approve of the plan
for the VPN already"). **The Polari half of vpn-1 is BUILT on `dev-vpn-1`**
(polari-framework + polari-cli + superproject; plan §8 lists every file),
selftest 75/75, deployed to prf-a (ModuleAssignment rows `vpn@prf-a` +
`islemesh@prf-a`, image rebuilt, node stack rolled by
`polari-cli/shells/enable-vpn-prf-a.sh`). Live verification is in
`AI-Notes/ledgers/TESTING_OWED.md` §12. **The isle half (I-1..I-5) is NOT
started** — its contract (push payload, proposal row, render, config-API
binding) is posted in `Isle-Mesh/NOTES-FROM-POL-CORE.md` (2026-09-03
entry) for isle-core's Claude. COMMITTED on `dev-vpn-1` in
polari-framework, polari-rf-node, polari-cli and the superproject (NOT
merged to dev, NOT pushed — his ritual); the Isle-Mesh note is left
UNCOMMITTED in the submodule working tree on purpose (isle-core owns
that repo's dev tip — commit it there, then re-pin). Real-browser pass
17/17 + live API pass recorded in TESTING_OWED §12.

## Read first, in this order
1. `AI-Notes/plans/VPN_FEDERATION_PLAN.md` — §0 capability (neutral
   wording), §1 what exists (file:line cites), §2–§5 shape/phases/
   decisions, **§7 his review amendments (they override §2–§5 where they
   differ)**: licence stance, `.vpn` rung, isle-side authority, manual
   config surface, relay kinds, OpenVPN as a full provider, naming.
2. `AI-Notes/guides/VPN_APP_KINDS.md` — the user-facing names: **Isle
   Link** (WireGuard-based) / **Isle Bridge** (OpenVPN-based), kind ids
   `vpn-link-{node,gateway,relay,hub,exit}`, `vpn-bridge-{client,server,
   span,exit,peer}`, labels Blind / Sees traffic.
3. `AI-Notes/plans/RETICULUM_TRANSPORT_PLAN.md` row 20 + §5n (the ladder,
   now `.isle → .arch → .vpn → .mesh → web`), `MESH_CONVERGENCE_PLAN.md`
   §admission (never auto-admit), `CENTRALIZED_CA_PLAN.md` (step-ca).
4. Code you will extend: `polari-cli/scripts/remote.sh` (the one-peer
   WireGuard idiom: keygen, 0600 conf, scope-check `ip_forward = 0`),
   `modules/islemesh/` (acceptor: IsleDevice/IsleApp/IsleProtocolPermit,
   ingest routes, netledger `free_udp_range`, `/display/isle-mesh`),
   `polariPeers/` (PeerAgreement, join_flow, agreements_api),
   `Isle-Mesh/isle-cli/scripts/url.sh` (exposure ledger + entrypoint
   gate), `Isle-Mesh/polari-isle/push-to-polari.sh` (the isle feeds
   Polari every 2 min), `Isle-Mesh/openwrt-router/` (VLAN, zones, dnsmasq
   join-protocol generator).

## Standing constraints (do not relitigate)
- **Their message never enters git.** The requester's text lives only in
  `AI-Notes/local/` (gitignored). Plans and code describe the capability
  in neutral words.
- **Authority is the isle side.** The VPN app is configured on the isle
  (isle CLI / agent-tier UI); its config API binds to isle-local
  addresses and refuses requests over the tunnel or from outside the
  isle. Polari rows MIRROR (via push-to-polari) and PROPOSE; a local
  operator applies. No remote path may alter a VPN.
- **Licence rule.** We DRIVE WireGuard and OpenVPN as separate programs
  (subprocess / netlink / management interface); GPLv2-only source is
  never copied into the GPLv3 tree; `wireguard-go` (MIT) is the only
  embeddable piece; OpenVPN 3 (AGPLv3) only if AGPL terms are accepted.
  Re-check LICENSE files at pin time; anything NC is a hard stop.
- **Names.** Module/app family `isle-vpn`; "WireGuard-based" /
  "OpenVPN-based" in descriptions only (trademarks).
- **Security defaults.** Private keys and certs are made on the device
  and never leave; nothing forwards or exits unless its knob is on; a
  federation link exists only behind an approved PeerAgreement and dies
  with revocation; `.isle` never crosses; every exposure is a ledger row.
- **Hooks.** PreUp/PostUp are templated toggles, never free shell.
- **Isle networking code stays on isle-core** (its own Claude edits
  `Isle-Mesh/**`; this box keeps the submodule pin synced).

## vpn-1, split in two halves

**Polari side (this box, `polari-rf-node/polari-framework` + angular +
polari-cli), branch `dev-vpn-1` off `dev`:**
- `modules/vpn/` (registry id `vpn`, app family `isle-vpn`): rows
  `VpnNetwork`, `VpnPeer` (public key only), `VpnAccessRule`,
  `VpnFederationLink`, `AppVpnExposure` (the `.vpn` rung row),
  `VpnProposal` (status proposed|applied|rejected, applied_by,
  applied_at) — every row carries `provider` (link|bridge) and `kind`
  (the guide's ids) and the Blind / Sees-traffic label derived from kind.
- Engine (pure functions + selftests): keygen (X25519 → base64, returned
  once), address allocation from the network cidr, UDP port from
  `islemesh_netledger.free_udp_range`, `render_link_conf(peer)` for
  node/gateway/hub/exit (masquerade only with the exit knob),
  `render_bridge_server_conf` / `render_bridge_client_ovpn` (cert-signed
  via the suite CA path; refuse honestly until step-ca lands),
  `render_access_rules` (nftables text), federation route injection.
- Ingest: extend the islemesh acceptor with `POST /api/islemesh/ingest/vpn`
  (the isle pushes its VPN app's state: peers, handshakes, transfer
  counters, exposures) → mirror rows; `IsleCatalogEntry` rows for the ten
  kinds (providing engine `vpn-gateway` for gateway/server kinds).
- API + page: `/api/vpn/*` read + `POST /api/vpn/proposals` only;
  `/display/vpn` = tables + api-structured-panels + the propose FORMS (no
  new components); `/display/isle-mesh` matrix gains the `.vpn` column and
  the Blind / Sees-traffic label.
- CLI: `pol vpn` (propose, show, qr from a config the isle exported).
- Selftests: mesh conf carries N−1 peers, hub member carries one,
  masquerade appears only with the exit knob, a Bridge Peer's subnet lands
  in the routes, no private key in any row or export, a proposal never
  mutates rows until `applied_by` is set, the `.vpn` option is absent
  without a gateway-kind app.

**Isle side (isle-core's Claude, `~/Isle-Mesh`), same phase:**
- I-1 the `isle-vpn` app package (Link first): install kinds, config
  store under `/etc/isle-mesh/vpn/`, keys generated locally, `wg-quick`
  driven; the config API bound to isle-local addresses with the
  tunnel/remote refusal.
- I-2 router: `wireguard-tools` + `wg-arch` interface in the isle zone;
  forward rules per VpnAccessRule text; WAN UDP forward for hub ports
  (today no WAN zone exists — design it in).
- I-3 dnsmasq join-protocol generator emits `.arch` and `.vpn` names from
  the member list.
- I-4 `isle expose` learns the `vpn` kind, gated on an installed
  gateway-kind app; `exposures.json` carries it; `push-to-polari` pushes
  VPN state to `/api/islemesh/ingest/vpn`.
- I-5 `isle vpn apply <proposal-id>` pulls a proposal from Polari, shows
  the diff, applies on operator confirmation.
The contract between the halves is the ingest payload + the proposal
row shape — agree those first through `NOTES-FROM-POL-CORE.md` (the
append-only cross-machine channel).

## Acceptance for vpn-1 (from the plan §6, cut to this phase)
Two Link networks on this box (two isles simulated as two VpnNetworks),
one federation proposal → applied by the "isle" side → mirrored rows
show the link active; `.vpn` exposure option present only with the
gateway app; a revoke → the peer entry gone within one render; zero
private keys anywhere in the DB or `/modules/export`. Real-browser pass
of `/display/vpn` (CDP driver in the night-run scratchpad pattern).

## Gates
- His ratification of D1–D14 (plan §5 + §7.6/7.7/7.8) before code.
- Branch per phase (`dev-vpn-1` off `dev`), merge to dev when green,
  push = his ritual (`polari-cli/shells/push-all-dev.sh --push`, with
  `--with-isle` once isle-core has commits).
