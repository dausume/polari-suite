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

## Proving it

`audit.sh` reports every control with evidence and a verdict. `escape-test.sh` starts a throwaway container with exactly an app's confinement, deliberately mounting the docker socket and the host's `/etc` to prove the profile denies them even when present, and tries fourteen cross-overs: the socket, the host's shadow file, mounting, sysrq, sysctl writes, kernel modules, ptrace of init, raw sockets, a new user namespace, writing outside the declared paths, chroot, keyctl, bpf, firmware. Each must fail. On an isle with a real enforced profile, all fourteen were blocked.

## Commands

```
pol security os render [--scenario isle]        render for the auto-detected or named scenario
pol security os apply [--complain|--enforce]    load it (root)
pol security os audit [--json]                  score this machine
pol security os escape-test [--profile P]       prove it
pol deploy audit <node>                         the audit on another machine, over ssh
```

## Where it stands

Templates, the renderer, the apply script and the audit exist and pass their own checks; the escape test was run once by hand on one isle. Nothing here is applied on any machine by default: no generated AppArmor profile is loaded on the production server or on an isle, user-namespace remapping is not enabled, and the audit reports both as open. Applying the rings per scenario, and the isle-side application when an app is installed, are the next work.
