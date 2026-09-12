# OS security: DAC and MAC

> **Status, 2026-09-12: designed and prototyped, not deployed.** The controls on this page exist as templates, scripts and plans in the repository. None of them is applied on the production server or on any isle unless an operator runs them by hand, and several pieces are still plans. Security is the next thing being built; the honest state of each piece is at the end of the page.

The operating-system layer answers two questions for every process Polari runs: **who is it** (discretionary access control: users, groups, file modes, capabilities) and **what may it touch** (mandatory access control: an AppArmor profile and a seccomp filter the process cannot change). Both are standard Ubuntu mechanisms. Polari declares them once and renders them per machine.

## The `os-security` directory

```
os-security/
  scenarios/     isle.yml · swarm-lean.yml · swarm-full.yml · dev.yml
  templates/     apparmor/app.j2 · seccomp/kind.json.j2 · firewall/… · dac/…
  render.py      scenario + the apps that are up → out/<scenario>/
  apply.sh       load profiles (enforce or complain), firewall, sysctl, audit rules, service hardening
  audit.sh       score every control on this machine; verdict hardened | partial | open
  escape-test.sh attack our own confinement from inside; every attempt must fail
```

A **scenario** says which rings apply on this kind of machine, the fixed pieces it runs (the isle agent, the proxy, Polari itself), the ports and networks, and the host's ownership rules. The **apps** come from their manifests, or from a running Polari's registrar (only what is online), or from the isle's own registry. Rendering is pure and idempotent; apply removes the profiles of apps that are no longer up.

## DAC: who runs as whom

- **User-namespace remap.** Docker maps a container's root to an unprivileged host uid, so an escape lands as nobody. Rendered into the daemon settings and diffed, never applied automatically, because it changes ownership of images and volumes and needs a restart window.
- **One host uid per app**, allocated at install and recorded on the app's row, so one app's files are unreadable to another even outside the container.
- **Read-only root filesystem** with a small tmpfs for `/tmp` and `/run`; only the declared data paths are writable.
- **Capabilities dropped** to none, then only the declared ones added back, from a short allow-list: `NET_ADMIN` (VPN gateways, the remote agent's DHCP), `NET_BIND_SERVICE`, `CHOWN`, `SETUID`, `SETGID`, `DAC_READ_SEARCH`. `SYS_ADMIN` is never grantable; hardware access goes through a guest.
- **No new privileges**, a process limit, and cgroup memory and CPU limits on every container.
- **Ownership on the host**: the isle's state directory is readable by an admin group only, private keys are mode 600, each app's data directory belongs to that app's uid.
- **Sudo**: two narrow groups, `polari-remote` (what remote setup over ssh may run) and `polari-app` (what the App Store's doors run), are the only sudoers files Polari installs. Service units run with `NoNewPrivileges`, `ProtectSystem=strict`, `ProtectHome`, and a capability bounding set.

## MAC: what a process may touch

**AppArmor, one profile per app, generated.** The app's manifest carries a `security` stanza:

```json
"security": { "profile": "web-app", "writable": ["/data"], "network": ["isle"], "capabilities": [], "devices": [], "ports": [3000] }
```

The renderer produces `isle-app-<name>` from one template: the image tree readable, only the declared paths writable, `/proc` and `/sys` writes denied, mount and pivot_root denied, ptrace and signals confined to the app itself, the docker socket and libvirt denied even if someone mounts them, raw sockets only for gateway kinds, devices only for hardware extensions and only the ones the hardware map assigned. Kinds: `web-app`, `worker`, `gateway`, `vpn-gateway`, `hardware-extension`. The fixed pieces (agent, gateway, proxy, Polari, the store's apt) are instances of the same template, declared in the scenario file.

**seccomp, one allow-list per kind.** Every syscall not listed fails. Absent everywhere: mounting, pivot_root, ptrace, kernel modules, reboot, bpf, perf, keyctl, user-namespace creation, open-by-handle. Gateway kinds add raw sockets and namespace moves for tunnels.

**Guests.** Hardware apps run in KVM guests under libvirt's per-VM AppArmor profile (sVirt), with virtio devices only, no shared folders, consoles on localhost, and passthrough only for ports the hardware map assigned. The isle refuses to define a guest without its profile.

**The kernel's own knobs.** Pointer and dmesg restriction, unprivileged BPF disabled, ptrace scope, protected symlinks and hardlinks, reverse-path filtering; user namespaces stay enabled because the remap needs them.

## Warn mode, precisely

Every profile loads in complain mode first. Two facts shape how the profiles are written:

- AppArmor enforces **explicit** `deny` rules even in complain mode, and quietly. Complain only turns *implicit* denials (accesses no rule allows) into logged, permitted `ALLOWED` events. A profile built as "allow everything, then deny a list" would bite silently in warn mode and log nothing. So each profile is an **allow-list**: the image readable and executable, the declared paths writable, the declared network and capabilities, the runtime's signals. In complain mode everything outside it is permitted and logged; the only explicit denies kept are docker's own stock ones, which every container already runs under, so a complain profile never denies more than stock docker does. Enforce mode adds Polari's stricter explicit denies on top.
- The list of what enforcing would break is therefore readable from the kernel log: `pol security os allowed --since 1d --rules` groups the `ALLOWED` lines per profile, with the rule that would allow each. An empty list after a normal day of use is the gate for `--enforce`, one profile at a time.

**seccomp has a warn mode too.** In complain the rendered allow-lists use the log action instead of the error action: a syscall outside the list goes through and the kernel records it, and the same harvest command names it (the syscall table ships with the scripts). The first run of it found the one call the worker list lacked, `open`, which musl's loader uses and which had stopped python from starting at all under the list; with it added, the python workload and nginx run under the enforce lists with nothing logged.

## Two routes, two shapes of the same rings

Polari deploys two ways, and the rings attach differently on each:

- **The app route (an isle):** the deb installs the isle agent, which starts every app as its own plain docker container, KVM guests for hardware apps with passthrough of what the hardware map assigns, and the hardware agent tier. Here every app carries its own AppArmor profile and seccomp list through the compose fragment (`security_opt`, dropped capabilities, read-only root, tmpfs, a pid limit), guests run under libvirt's per-VM profile, and the network ring is the agent's own firewall. Until the agent attaches per-app profiles, the scenario also loads the node-wide union as a warn-only baseline over every isle container.
- **The swarm route (a server):** the lean or full stack as swarm services. Services cannot carry `security_opt`, so the MAC ring is one node-wide profile (the union of the stack's pieces), seccomp can only be set for the whole daemon, and the app-surface ring lives in the stack file (the rendered overlay). Modules are not containers here; they run inside the Polari backend, so their declarations fold into the backend's profile. There are no KVM guests and no device access on this route at all: a hardware app's Polari side (its data model, pages and simulations) may still be installed, which is useful for development, and the module's health row, the admission reply, the download page and `pol modules health` say plainly that only that side works here and that the hardware half needs a full isle with the hardware agent tier. That is a notice, never a refusal.

## On the swarm route

Docker's `stack deploy` drops `security_opt` (with `privileged`, `devices` and `userns_mode`), so a swarm service cannot be given an AppArmor or seccomp profile of its own. The production server runs the lean stack as a swarm, so there the MAC ring has one lever: the node-wide `docker-default` profile that every container gets. The daemon loads its own only when no profile of that name is already loaded, and a replacement takes effect live for running containers. The renderer therefore writes `docker-default` as the union of the stack's pieces (proxy, hub, frontend, backend) and keeps docker's stock profile alongside it so `pol security os revert` restores it with one command, without restarting docker. Modules on the swarm are not containers, they run inside the Polari backend, so their declarations fold into the backend's profile rather than getting one each. The compose fragment for the swarm carries only what the swarm honours: dropped capabilities, read-only root filesystem, tmpfs, a process limit.

## Proving it

`audit.sh` reports every control with evidence and a verdict, including the count of audit lines in the last day. `escape-test.sh` starts a throwaway container with exactly an app's confinement, deliberately mounting the docker socket and the host's `/etc` to prove the profile denies them even when present, and tries fourteen cross-overs: the socket, the host's shadow file, mounting, sysrq, sysctl writes, kernel modules, ptrace of init, raw sockets, a new user namespace, writing outside the declared paths, chroot, keyctl, bpf, firmware. Each must fail. It runs in two passes: the full confinement (profile, seccomp, dropped capabilities, read-only root) and, with `--alone`, the AppArmor profile by itself. The second pass exists because the full pass proves little about the profile: on 2026-09-12 all fourteen attempts were blocked on an isle with the profile loaded, and the kernel recorded no AppArmor decision at all, every block having come from the other rings. The profile-only pass is what shows the MAC ring's own contribution.

## Commands

```
pol security os render [--scenario isle]        render for the auto-detected or named scenario
pol security os apply [--complain|--enforce]    load it (root; complain unless told otherwise)
pol security os audit [--json]                  score this machine
pol security os escape-test [--profile P] [--alone]   prove it (full confinement; --alone = the profile by itself)
pol security os allowed [--since 1d] [--rules]  what enforcing would break, from the kernel log
pol security os revert                          swarm: docker's stock docker-default back
pol prod harden [--enforce] | harden report | harden revert   the same for the server, from its answered profile
pol deploy audit <node>                         the audit on another machine, over ssh
pol deploy harden <node> [--dry-run|--enforce] | --report [--rules] | --revert   the rings on another machine, warn-only, over ssh
```

## Where it stands

Templates, the renderer, the apply script, the audit and the harvest of audit lines exist and pass their own checks. On 2026-09-12 the warn-mode mechanics were proven on one isle: a complain-mode profile logs what enforcing would deny and permits it; the node-wide `docker-default` replacement attaches live, logs, and reverts cleanly; the fourteen-probe escape test blocks all fourteen under the full confinement in both modes, and the profile-only pass measures what the profile itself adds. Applied so far, and only in warn mode: on one isle at home, the node-wide union profile in complain over every container and the per-app profiles loaded in complain, with the firewall, host and ownership rings printed and not applied. Nothing is loaded on the production server, user-namespace remapping is not enabled anywhere, the swarm stack file does not yet carry the dropped-capability and read-only settings, and the audit reports all of that as open. The next work is a day of harvested audit lines from that isle, the same warn-only application on the home swarm, and only then enforcement one piece at a time.
