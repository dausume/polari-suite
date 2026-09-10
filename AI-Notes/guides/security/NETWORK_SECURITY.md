# Network security

Polari's network model is containment first: an isle is your own private network, and everything beyond it is a deliberate rung on a ladder. This page is the security reading of that model; the [networking and topology model](../networking-model.html) describes it in full.

## Containment on the isle

- One VLAN behind a router the isle owns. Names end in `.isle` and are served only inside; they never cross.
- The agent's nginx is the only way into a device's apps, and what its proxies allow is the policy. Mutual TLS is a per-app option.
- Devices are sole-isle or dual-home (internet and isle at once, with the separation enforced). A dual-home device does not bridge the two.
- Containers cannot reach host services (docker's user chain) and do not talk to each other except through the agent.
- Trust is established once: a joining device verifies the isle CA's fingerprint out of band, then everything inside is under that authority.

## The exposure ladder

`.isle → .arch → .vpn → .mesh → web`. Each rung is a deliberate enablement, default most restrictive, and exposure is a row that names the app, the rung, the scope and our role, switchable at will. A rung only appears when the thing that makes it real is installed.

## Between isles: the archipelago

Isles federate over Reticulum, an encrypted, bearer-agnostic packet network (WiFi, ethernet, LoRa, serial alike). Every packet is end-to-end encrypted to a destination identity; relays forward ciphertext and never read it. Membership is measured, not declared: a node is in only while its path meets the floor, and trust is a separate, graded property that never means write access. Traffic is split into four classes at the forwarding decision in our fork, so a household can relay a neighbour's messaging without relaying their heavy app, and airtime budgets cap what any bearer may transmit. Radios never transmit until their legal basis is recorded.

## VPN kinds and relays

Two providers under one family, ten purpose-named kinds. Every row carries a label, **blind** or **sees traffic**, so nobody mistakes a relay for a hub:

- Blind relays (the default for federation) forward encrypted datagrams and hold no keys; safe on rented hardware.
- Hubs, servers and exits see traffic and run only as their own guests on hardware you own.
- Gateways and spans carry the isle's own subnet or VLAN and live on the router.
- Private keys are generated on the device that uses them and never leave it. Configuration is accepted from the isle side only; a request arriving over a tunnel is refused. Exits and forwarding are off until switched on.

## The mesh: zero trust

A mesh app's relay broadcasts state to consumers known only by their Reticulum identity. Consumers are not peers: nothing they send changes anything except through the proposal seam, and a mode that requires enrolment deliberately does not exist. Adaptive cadence and a user census keep a relay honest about who is listening.

## Servers and swarms

- One certificate for every public name, publicly trusted through Let's Encrypt or signed by the suite CA until then.
- Overlay networks between swarm nodes are encrypted; management and gossip ports are open to peers only.
- The proxy on the manager is the only entry point; every service is reached by name over the overlay, never by a published port.
- Keycloak, on the full profile only, is reached through the proxy; its credentials are generated, never typed, and rotated before the server faces the internet.

## Known gaps, tracked

- An isle door (`isle url expose`) speaks plain HTTP on its outside leg until the gateway terminates TLS; open doors only across a VPN or a trusted network for now.
- Direct-path discovery for VPN peers behind NAT (STUN, hole punching) is not built; the blind relay is the fallback.
- The isle-side application of the firewall chain and per-app profiles is a phase of the hardening plan, and the audit reports its absence honestly.
