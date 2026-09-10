# Security in Polari

Polari is free and open-source software, and so is everything it relies on to be secure. There is no proprietary agent, no vendor console, no service you must trust: every control is a standard Linux mechanism you can read, and every policy Polari applies is a file you can inspect before it lands.

This section is the map. Each page below covers one layer; this page says how they fit and what they depend on.

## The property we are after

An attacker who fully controls one app should be able to do nothing outside that app's declared surface: not read another app's data, not reach the host, not talk to docker or the hypervisor, not become root, not persist after the app is removed. Two independent mechanisms enforce it at every layer, so one mistake does not open the machine.

## The layers

| Layer | Page | What it decides |
|---|---|---|
| Operating system | [OS security](os-security.html) | Who runs as whom (DAC), what each process may touch (MAC: AppArmor and seccomp), the hypervisor's confinement of guests, the kernel's own knobs |
| Proxy | [Proxy security](proxy-security.html) | The single ingress: TLS, certificates, headers, what is exposed by name, basic-auth doors on an isle |
| Firewall | [Firewall security](firewall-security.html) | What the host admits (ufw), what containers may reach on the host (docker's user chain), swarm and isle ports |
| Network | [Network security](network-security.html) | The isle's containment, the exposure ladder, VPN kinds and relays, encrypted overlays, Reticulum |

Two things cut across them. **Deployment scenario**: an isle, a lean server, a full server and a developer machine need different policy, so every control is rendered for a named scenario. **The apps that are up**: a profile exists for each app while it runs and is removed when it goes; policy follows the deployment.

## How it is applied

The controls are declared once, in the `os-security` directory of the suite: scenario files (which rings apply, ports, networks, the fixed pieces) and jinja2 templates (AppArmor profiles, seccomp allow-lists, firewall rules, sysctl, audit rules, service hardening). A renderer turns a scenario plus the running apps into concrete files; an apply step loads them; an audit scores every control on the machine; an escape test attacks our own confinement from inside a throwaway container and expects every attempt to fail.

Each app states what it needs in its manifest: a profile kind, the paths it may write, the networks it may use, the capabilities it needs from a short allow-list. Anything not declared is denied. The conformance check refuses values outside the vocabulary.

## What it depends on, and the licences

| Dependency | Role | Licence |
|---|---|---|
| Linux kernel: AppArmor, seccomp, namespaces, cgroups, netfilter | Every enforcement point | GPL-2.0 |
| AppArmor userspace (parser, aa-status) | Loading and inspecting profiles | GPL-2.0 |
| Docker Engine / containerd / runc | Containers, the user chain, userns remap | Apache-2.0 |
| libvirt + QEMU/KVM | Hardware-app guests, sVirt confinement | LGPL-2.1 / GPL-2.0 |
| nftables / iptables | The firewall rules docker and the host use | GPL-2.0 |
| ufw | The host firewall front end | GPL-3.0 |
| auditd | The audit trail the host ring reports from | GPL-2.0 |
| systemd | Service sandboxing (ProtectSystem, NoNewPrivileges) | LGPL-2.1 |
| nginx | The proxy and the isle agent's ingress | BSD-2-Clause |
| OpenSSL, certbot | TLS, the certificate authority, Let's Encrypt issuance | Apache-2.0 |
| WireGuard, OpenVPN | The VPN kinds (driven as separate programs, never embedded) | GPL-2.0 / GPL-2.0 with OpenSSL exception |
| Reticulum, LXMF (our forks at the last MIT commit) | The archipelago and mesh transport | MIT |
| Keycloak | Logins on the full server profile only | Apache-2.0 |
| OpenWrt | The isle router | GPL-2.0 |
| jinja2, PyYAML | Rendering the policy | BSD-3-Clause / MIT |

Polari itself is GPL-3.0. Nothing in this stack is proprietary, and nothing phones home.

## Where things stand

The controls are declared, rendered and validated. The escape test has been run against a real enforced profile on an isle and every attempt was blocked. Applying the full set on a live isle, and the isle-side pieces (per-app profiles at install time, the firewall chain, the audit feed), are tracked in the hardening plan and its phases; the audit says, per machine, exactly which controls are in place and which are not.
