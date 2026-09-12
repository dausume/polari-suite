# Firewall security

> **Status, 2026-09-12: designed and prototyped, not deployed.** The controls on this page exist as templates, scripts and plans in the repository. None of them is applied on the production server or on any isle unless an operator runs them by hand, and several pieces are still plans. Security is the next thing being built; the honest state of each piece is at the end of the page.

Two firewalls matter on a Polari machine, and they answer different questions. The **host firewall** (ufw) decides what the machine admits from the outside. **Docker's user chain** decides what containers may reach on the host and each other. A third, the **isle router's zones**, decides what crosses between the isle's VLAN and everything else. All three are rendered per scenario from `os-security`, and the audit reports each.

## The host firewall: ufw

Default deny incoming, allow outgoing. Each allowed port names a source set, resolved at apply time and skipped with a warning if unresolved, never widened to "any":

| Scenario | Allowed in | From |
|---|---|---|
| isle | 22 | the isle VLAN and the owner's LAN |
| | 80, 443 | the isle (the agent's ingress) |
| | 5353/udp | the isle (mDNS join protocol) |
| | 4242 | the relay segment (Reticulum bearer) |
| | doors opened with `isle url expose` | added and removed by the isle itself |
| swarm-lean / swarm-full | 22 | the operator's network |
| | 80, 443 | anyone (the edge) |
| | 2377, 7946, 4789/udp | swarm peers only |
| dev | nothing changes | the audit still reports |

One fact people miss: **docker's published ports bypass ufw**, because docker inserts its own rules ahead of it. That is why the lean stack publishes 80 and 443 in host mode on the manager only, and why container traffic is governed by the user chain below rather than by ufw.

## Docker's user chain

Docker leaves a chain, `DOCKER-USER`, that is evaluated before its own forwarding rules. Polari's rendered rules there say: a container may reach the host's own addresses only on the allowed ports (DNS, and the agent's 80/443 on an isle), never on ssh, the docker or libvirt sockets, the swarm ports or any service the host happens to run; and docker's TCP socket is dropped even if someone enables it. Established flows are allowed back. Rules carry a tag so re-applying replaces only Polari's own.

Inter-container communication is off by default in the isle and server scenarios: apps reach each other by name through the agent or proxy, not directly.

## The isle router's zones

The isle is one VLAN behind an OpenWrt router VM. Its zones forward nothing between the isle and the real interface unless the isle says so, there is no WAN zone by default, and the network-isolation check in the isle tooling verifies that no forwarding rule leaks from an isolated network to the real interface. Exposure is a separate mechanism (a door on a member device), never a hole in the router.

## Swarm

Swarm's management port, gossip and overlay tunnel are open only to peers. Overlay networks the stacks create are encrypted, so multi-node traffic between services is under IPsec; single-node stacks send no traffic off the machine.

## Proving it

`pol security os audit` reports: the user chain carries Polari's rules, ufw is active, sshd is not bound to every interface, no docker TCP socket, every overlay encrypted. `pol deploy audit <node>` runs the same on another machine. The escape test includes reaching host ports from inside a confined container.

## Where it stands

The rules render and validate for every scenario, and nothing more: no host firewall rules from these templates are applied on the production server or on an isle, docker's user chain is empty on both, and the audit reports it. Applying them per scenario, on the server and at isle install time, is the next work.
