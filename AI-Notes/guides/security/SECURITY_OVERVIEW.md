# Security in Polari

> **Status, 2026-09-19.** The OS, proxy, firewall and network rings below are still **designed and prototyped, not deployed**: templates, scripts and plans that an operator must apply by hand. The **application ring is different** — role-play/observe mode, causal tracing, traffic policies, per-app security decisions and owner-defined permissions are **built, selftested and live-proven** on the home staging stack, running in `advisory` mode under a `dev` posture. Nothing is enforced anywhere; browser passes are owed on all of it. See [Application security](app-security.html) for the ring in full, and "Where things stand" below for the honest split.

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
| Application | [Application security](app-security.html) | Who may call which class × verb (CRUDE), who a class's **owner** is and what others may see of their rows, what leaves and enters over the wire, what each app version has had ruled on, and what a role-play session shows an event really causes |

Two things cut across them. **Deployment scenario**: an isle, a lean server, a full server and a developer machine need different policy, so every control is rendered for a named scenario. **The apps that are up**: a profile exists for each app while it runs and is removed when it goes; policy follows the deployment.

## The application ring, in brief

Unlike the four rings above, this one is built and running — in `advisory` mode, on a `dev`-posture home stack, enforcing nothing (ledger §59–§66). Full detail, doors and what is not built yet: [Application security](app-security.html).

- **Dev posture and observe mode.** A `POLARI_APP_PERMISSIONS` knob (`off | advisory | enforce`) gates the CRUDE class × verb check; deployed stacks stay at `off` or `advisory` by rule, never `enforce` (ledger §51).
- **Role-play → review → concrete → verify.** An operator acts as a prototype role, Polari records what it touched, proposes a permission profile from the recording, an administrator concretes it, and a verify pass replays the recording against it before anyone considers enforcing (ledger §51, operator guide `ROLEPLAY_PERMISSIONS_GUIDE.md`).
- **Causal tracing.** One class at a time, with self-disarming budgets, Polari records what a chain of events actually causes — a map of cause → effect edges and a journal of which instances were written — and can walk that map into a *closure*: the implicit permissions an event or a profile grants beyond its explicit list (ledger §59, §61, §63).
- **Traffic policies.** Outbound and inbound traffic are closed by default; a monitoring pass in dev suggests allow-list rows from what is actually seen, and a person confirms or denies each one before production would rely on it (ledger §66).
- **Security decisions per app × version.** Every kind of security ruling (profile grants, owner policies, outbound/inbound, trigger run-as, declared flows, role bindings, trace coverage) is enumerated per application and per version, so coverage can be read as none / partial / full and a version bump shows what needs re-confirming (ledger §64).
- **Owner-defined permissions.** Some classes (opt-in only) also have a per-instance **owner** — a Keycloak subject id — with a floor of verbs the owner keeps and a ceiling of verbs and fields everyone else gets; the class-level gate always decides first, and owner rules only ever narrow (ledger §60, design `OWNER_DEFINED_PERMISSIONS_DESIGN.md` §3).
- **STOMP subscribe follows the same posture as CRUDE.** Subscribing to a live-update topic now asks the identical `read` question the HTTP gate asks, under the same knob (ledger §65).

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

## The assurance ladder

Security is not one state but a ladder, and every rung has to be earned before the next means anything. Polari states which rung it is on rather than implying a higher one:

| rung | what it means | Polari today |
|---|---|---|
| 1. designed | the model is written down: the rings, the taxonomy, what each control protects against | yes |
| 2. built | the controls exist as code: templates, renderers, interfaces | partly: templates and scripts; the interfaces are plans |
| 3. applied by default | every deployment route turns the controls on without an operator remembering to | no |
| 4. self-tested | the audit and the escape test run on every deployment and their results are recorded | no, run once by hand on one machine |
| 5. independently tested | a third party, not the authors, tests the deployed system and publishes what it found and what was fixed | no |
| 6. insurable | an insurer will underwrite data storage and processing on it, which in practice requires rung 5 and evidence it is kept | no |

Rungs 5 and 6 are outside what the project can do for itself: independent testing has to be bought or contributed, and insurance is an underwriter's decision. Until rung 5, Polari makes no assurance claim about the safety of data stored on it, and nobody should rely on it for data whose loss or exposure they cannot bear. The point of the ladder is to be honest about that on the day it is true, and to make each rung a visible, checkable step.

## Where things stand

Plainly, and by ring:

- **OS, proxy, firewall, network — designed and partly prototyped, not deployed.** Exists as code: the `os-security` directory (scenario files, jinja2 templates for AppArmor, seccomp, the firewall chains, sysctl and audit rules; render, apply, audit and escape-test scripts), the `security` stanza in every module manifest, the proxy hardening in the nginx templates, encrypted swarm overlays, and the credential vault. Tested once: the escape test was run on one isle with one profile loaded and enforced by hand, and every attempt was blocked — evidence the template works, not evidence that anything is protected today. Not applied anywhere by default: the production server runs with the proxy hardening and encrypted overlays only; no AppArmor profile from these templates is loaded there, the host firewall chains are not rendered onto it, and the audit reports it as open. Isles are the same. Still plans: content policies derived from the data model, verification between services, the hardware trials, per-app security directories in modules, and the isle-side application at install time.
- **Application ring — built, selftested, pushed, and live-proven on the home staging stack.** Role-play/observe mode (ledger §51), causal tracing (ledger §59, §61, §63, §65), traffic policies (ledger §66), security decisions per app × version (ledger §64) and owner-defined permissions (ledger §60) all exist as code, are wired into the running CRUDE, STOMP and outbound paths, and have each been exercised over the real API against a deployed `polari-lean` stack — not only selftested in isolation (the `§59–§62`, `§63–§64` and `§65–§66` ledger addenda are the live proofs, including two rounds of `pol prod apply` redeploy that found and fixed a core restore-race defect, ledger §66 addenda 2–4). The stack runs `dev` posture with the gate at `advisory`: every refusal is a header or a notice, nothing is blocked. **Remaining:** the `objects` topology view (ct-5), session tasks (ct-7), the rest of owner-defined permissions (`OwnerGrant` and the Sharing tab, the anonymised side channels' remaining halves, `Ballot`, the `app.owned` manifest stanza — op-1 through op-4), and — for all of it — the browser pass: none of the new panels, tables or advisory headers has been seen by eye yet, only driven over the API.
- **The assurance ladder is unchanged by this arc.** It adds rung-2 code and, on one demo stack, a rung-3-shaped exercise (applied, but only where an operator ran `pol prod apply` by hand, not applied by default across every deployment route) — it does not move any ring past rung 2 in general, and self-tests here mean selftest suites plus one operator's live proof, not rung 4's "runs on every deployment automatically."

This is active work. Until browser passes land and the remaining slices are built, treat the application ring as proven at the API and unseen on screen, and every other ring in this section as a description of the intended design, with the state of each piece stated on it.
