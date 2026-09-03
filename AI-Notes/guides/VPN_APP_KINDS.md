# VPN apps on an isle — which one do I install?

Two product lines, one family (`isle-vpn`). The name says what it does;
the engine is only in the description.

- **Isle Link** — WireGuard-based. Fast, key-based tunnels between
  devices and isles: point to point, mesh, and relays that never hold
  keys.
- **Isle Bridge** — OpenVPN-based. Certificate-based joins of whole
  networks and outside peers: layer-2 spans, hubs with a certificate
  authority, TCP/443 paths, boxes that only speak OpenVPN.

**Rule of thumb: Link when both ends run ours; Bridge when you are
joining a network, or something that only speaks OpenVPN.**

| App | Kind id | What it does |
|---|---|---|
| Link Node | `vpn-link-node` | Puts this device on a Link network with its own address. Nothing behind it is shared. |
| Link Gateway | `vpn-link-gateway` | Puts this isle on a Link network and makes `.vpn` exposure available for its apps. |
| Link Relay | `vpn-link-relay` | Passes encrypted Link traffic between peers that cannot reach each other. Holds no keys, sees nothing. Safe on a rented box. **Blind.** |
| Link Hub | `vpn-link-hub` | A Link network's centre: admits members, routes between them, can carry other isles' subnets. **Sees traffic** — own hardware only. |
| Link Exit | `vpn-link-exit` | A Link Hub that also passes members' internet traffic out through its own connection. Off unless you turn it on. **Sees traffic.** |
| Bridge Client | `vpn-bridge-client` | Joins this device or isle to a Bridge server with a certificate. Works over TCP/443 where UDP is blocked. |
| Bridge Server | `vpn-bridge-server` | A certificate-issuing hub for Bridge clients, with live per-client control and revocation. **Sees traffic** — own hardware only. |
| Bridge Span | `vpn-bridge-span` | Stretches one isle's VLAN across sites at layer 2, so two locations behave as one isle. **Sees traffic.** |
| Bridge Exit | `vpn-bridge-exit` | A Bridge Server that also passes clients' internet traffic out. Off unless you turn it on. **Sees traffic.** |
| Bridge Peer | `vpn-bridge-peer` | Connects an outside box that only speaks OpenVPN (a YunoHost-class server, an existing VPN) as a gateway peer. |

Two labels appear on every row and on the isle-mesh matrix:
**Blind** (holds no keys, cannot read traffic — only Link Relay) and
**Sees traffic** (every hub, server, span, exit and routing relay).

Rules that hold for every kind: the app is configured from the isle
side only (never over the tunnel or from outside the isle); private
keys and certificates are made on the device and never leave it;
nothing forwards or exits unless its knob is on; every exposure is a
ledger row the isle pushes to Polari.
