# Isle hardening plan — DAC + MAC so an app cannot cross into the OS

_2026-09-10, from Dustin's ask: "secure the isles per system with a combination of AppArmor and normal Ubuntu security (DAC and MAC), so that if an app were hacked, the attacker cannot cross over from inside the app into our OS." Planning only; nothing below is built. Isle-side pieces are isle-core's to build; the contract lines are marked._

## 0. The goal, stated as a property

**A process that has full control of one isle app (container or guest) can do nothing outside that app's declared surface.** Not read another app's data, not reach the host filesystem, not talk to the docker daemon or libvirt, not open host ports, not become root on the host, not persist past the app's removal. "Declared surface" means what the app's manifest says it needs: its own data directory, its own network, the capabilities it asked for. Everything else is denied by default, by two independent mechanisms (DAC and MAC), so a single mistake does not open the host.

Threat model, concretely: the attacker already runs code as the app's user inside the container (a vulnerable web app, a poisoned image, a malicious module). Also in scope: a compromised hardware-app guest (KVM) and a compromised exposure gateway. Out of scope here: kernel zero-days (mitigated only by updates and reduced surface), a compromised host user with sudo, physical access.

## 1. What the isle does today (isle-core, 2026-09-10, read-only survey)

| Layer | Today | Verdict |
|---|---|---|
| Container root | Every container runs as **uid 0 inside** (prf-isle-backend, isle-vlan-agent, sample app, apt); no `userns-remap`, so container root is host root behind one escape | ⛔ the single biggest gap |
| AppArmor | Module loaded, 74 profiles enforced; every container under **docker-default** (generic: no mount, no ptrace of others, limited /proc, /sys) | ✅ baseline, ⚠ generic, not per app |
| seccomp | docker's builtin profile on every container | ✅ baseline |
| Capabilities | none added on the core's containers; the REMOTE agent adds `NET_ADMIN` (udhcpc); VPN kinds will need NET_ADMIN | ⚠ NET_ADMIN in a root container is a network-plane escape |
| Host binds | the agent mounts `/etc/isle-mesh/agent/{nginx/configs,logs,nginx.conf}` **rw**; prf-isle mounts its data volume rw; nothing mounts docker.sock | ✅ no socket; ⚠ the agent can write host config it later executes as nginx |
| Host agent | `isle-host-agent.service`: `ProtectSystem=strict`, `ProtectHome=yes`, `NoNewPrivileges=yes` (no `User=` shown → runs as root) | ⚠ good sandboxing, still root |
| libvirt guests | sVirt: the router VM runs under its own AppArmor profile `libvirt-<uuid>` (enforcing) | ✅ keep; extend to every hardware app |
| Firewall | ufw **inactive**; sshd on all interfaces; 7946 (swarm gossip) + 1716 open | ⚠ host-side rules are the OS default |
| Ownership | `/etc/isle-mesh` and `/etc/isle-mesh/ca` are `root:root 755` (world-listable; key files' own modes not checked here) | ⚠ tighten to a group |
| Sudo | the login user is in `sudo docker libvirt kvm`; `docker` group = root-equivalent | ⚠ the two new groups (polari-remote / polari-app) narrow this for OTHER users; the owner still has everything |
| App manifest | `polari-app.json` has no security stanza | ⛔ nothing declares what an app may touch |
| Network | the isle's containment (VLAN, agent nginx as sole ingress, `.isle` never crosses) | ✅ the design is right; container→host paths are not blocked |

Good news: nothing today hands an app the docker socket or `--privileged`, the guest VM is already MAC-confined, and the host agent is sandboxed. The gaps are root-inside-containers, no per-app policy, and no host-side deny rules.

## 2. Shape — five rings, each independent

Defense in depth means each ring holds on its own; an attacker must break all of them.

```
 ring 5  host: ufw default-deny, sshd bound to the isle side, auditd, unattended-upgrades, sysctl
 ring 4  network: DOCKER-USER chain — containers cannot reach host services, only the agent, DNS, their peers
 ring 3  MAC: one AppArmor profile PER APP generated from its manifest; seccomp per kind; sVirt per guest
 ring 2  DAC: userns-remap (container root ≠ host root), one host uid per app, read-only rootfs, minimal caps
 ring 1  the app itself: its own data dir, its own network, its declared surface — nothing else exists to it
```

### 2.1 DAC (ring 2) — "normal Ubuntu security"

- **User namespace remap for docker** (`/etc/docker/daemon.json`: `"userns-remap": "isle"`): container uid 0 maps to a high unprivileged host uid. An escape lands as nobody. Cost: volumes owned by the remapped range (the isle CLI already chowns what it mounts); one-time migration of existing volumes (`isle security migrate-userns`).
- **One host uid per app** (`user:` in the compose the scaffolder emits; `isle app install` allocates from a reserved range `isle-app-<n>`), so app A's files are unreadable to app B even if both escape the container. The agent gets its own uid; prf-isle its own.
- **Read-only root filesystem** for every app container (`read_only: true` + `tmpfs` for `/tmp`, `/run`); writable ONLY the declared data volume.
- **Capabilities**: `cap_drop: [ALL]` by default; `cap_add` only what the manifest declares, and the manifest may only declare from an allow-list (`NET_ADMIN` for VPN gateway/hub kinds and the remote agent's DHCP, `NET_BIND_SERVICE`, `CHOWN/SETUID/SETGID` for entrypoints that drop privilege). `no-new-privileges: true` everywhere.
- **PID limits and cgroups**: `pids_limit`, memory/cpu (already on the compose route) — an escape cannot fork-bomb the host.
- **Host filesystem**: `/etc/isle-mesh` → `root:isle-admin 750`; `ca/*.key` `600`; `agent/` writable only by the agent's uid; app data under `/var/lib/isle/apps/<app>/` owned by that app's uid, `700`.
- **Sudo**: the two groups (`polari-remote` for ssh/swarm/AI setup, `polari-app` for the store's doors) become the ONLY sudoers drop-ins the isle installs; the owner's `sudo` membership stays the owner's business, but the isle never adds a service user to `docker`, `libvirt` or `sudo`. Service units get `User=`, `DynamicUser=` where they hold no state.

### 2.2 MAC (ring 3) — AppArmor, per app, generated

- **Generated profiles, never hand-written per app.** The manifest gains a `security` stanza:
  ```json
  "security": { "profile": "web-app", "writable": ["/data"], "network": ["isle"], "capabilities": [], "devices": [], "ports": [3000] }
  ```
  `isle app install` renders `/etc/apparmor.d/isle-app-<name>` from the stanza + a base template per `profile` (`web-app`, `worker`, `gateway`, `vpn-gateway`, `hardware-extension`), loads it enforcing, and starts the container with `security_opt: [apparmor=isle-app-<name>]`. The base templates: deny `mount`, `ptrace` (peer≠self), `/proc/sys/**` writes, `/sys/**` writes, `capability sys_admin/sys_module/sys_rawio/sys_ptrace/dac_override`, raw sockets unless `gateway`; allow read of the image tree, rw of the declared writables only, network by family/type per `network`.
- **Fixed pieces get profiles too**: the isle agent (`isle-agent`: nginx may read its configs and certs, write logs and the two generated files, nothing else; no exec of anything but nginx), the exposure gateway (`isle-gateway`: proxy only, no filesystem writes), prf-isle backend/frontend (`isle-polari`), the apt container.
- **seccomp per kind**: docker's builtin for `web-app`; a stricter allow-list for `worker` and `gateway` (no `mount`, `ptrace`, `keyctl`, `bpf`, `perf_event_open`, `userfaultfd`, `unshare` with new userns).
- **Hardware apps (KVM)**: sVirt stays on (it is); `isle vm define` refuses a guest without a libvirt profile; passthrough only for `HardwarePort` rows the hwmap assigned; no `<filesystem>` shares, no host-network NICs (bridges only), SPICE/VNC on localhost, disk images `libvirt-qemu:kvm 600`. Extension apps (reticulum, printcam) run INSIDE the guest, never on the host.
- **Profiles ship with the deb** (`/usr/share/isle-mesh/apparmor/`) and `isle security apply` loads/updates them; `aa-status` must show every isle profile in enforce mode or the security gate fails.

### 2.3 Network (ring 4)

- `DOCKER-USER` iptables chain (the hook docker leaves for us): from any isle container network, **drop** to the host's own addresses except the agent's ports and DNS; drop to `127.0.0.1` services, to 2375/2376 (docker), 16509 (libvirt), 22 (ssh), 7946/4789 (swarm); drop to the other docker networks. Rendered by the isle from its known networks (`isle-agent-net`, `isle-br-0`, per-app networks), applied by `isle security apply`, idempotent.
- `icc=false` per app network where apps do not need each other; the agent is the only common neighbour.
- The exposure gateway on its own network, reaching only the agent.
- The host: ufw enabled, default deny incoming; allow ssh only from the isle VLAN and the LAN the owner names; allow the agent's 80/443 on the isle interface; swarm ports only when the machine is a swarm node and only from the swarm's peers.

### 2.4 Host (ring 5)

- `unattended-upgrades` for security updates (kernel included; the isle schedules the reboot window).
- `auditd` rules on `/etc/isle-mesh`, `/etc/sudoers.d`, docker and libvirt sockets, `execve` by service uids — the isle pushes findings to Polari as rows (a `SecurityEvent` class, no raw logs on screens).
- sysctl: `kernel.kptr_restrict=2`, `kernel.dmesg_restrict=1`, `fs.protected_*=1` (already), `kernel.unprivileged_bpf_disabled=1`, `net.ipv4.conf.all.rp_filter=1`; keep unprivileged user namespaces ON (userns-remap and rootless need them) but confine who may create them via AppArmor (`userns` rule, Ubuntu 24.04+).
- No docker TCP socket, ever; the store and the CLI talk to docker through the socket as members of a **narrow** group only where hosting is enabled.

## 3. Prove it, do not assert it

- **`isle security audit`** (isle-side): one command that checks every control above and prints pass/fail per ring, pushed to Polari as `SecurityControl` rows; `pol deploy audit <node>` runs it remotely; `pol modules health`-style verdict: `hardened | partial | open`.
- **`isle security escape-test`**: starts a throwaway container with the SAME confinement an app gets and tries, from inside, every known cross-over: docker socket, `mount`, `/proc/sysrq-trigger`, `/proc/1/root`, `ptrace` of another pid, `cap_sys_admin` use, raw socket, reaching host ssh/docker/libvirt ports, writing outside `/data`, `unshare -r`, `keyctl`, reading another app's volume. Every attempt must FAIL; the report lists each with the ring that stopped it. It runs after every `isle security apply` and in the CI throwaway-VM isle test (ci-3). This is our own isle, deliberately attacked by ourselves; it is the only honest proof.
- The security gate (`isle security gate`) grows a `--hardening` mode: no door opens (`isle url expose`) unless the audit says `hardened`.

## 4. Phases

- **sec-0 — this plan + the survey (done).** Isle-core ratifies the split of work (§6).
- **sec-1 — DAC baseline (isle-core).** userns-remap + volume migration; per-app uid allocation in `isle app install`; read-only rootfs + tmpfs + `cap_drop ALL` + `no-new-privileges` in the scaffolded compose; `/etc/isle-mesh` ownership; service `User=`. Acceptance: every container shows a non-zero host uid for its root; `docker exec` as the app user cannot read another app's volume.
- **sec-2 — MAC for the fixed pieces (isle-core).** AppArmor profiles for agent, gateway, prf-isle, apt; shipped in the deb; `isle security apply` loads them; sVirt asserted for every guest. Acceptance: `aa-status` shows them enforcing; the agent cannot exec anything but nginx.
- **sec-3 — per-app policy from the manifest (Polari side + isle-core).** The `security` stanza in `polari-app.json` (schema, validation in `pol modules conform`, scaffold default = deny-all web-app); the profile/seccomp renderer (`polari-cli`/moduleService, pure); `isle app install` consumes it. Acceptance: an app declaring nothing gets the strictest profile and still runs; an app declaring `NET_ADMIN` gets it and nothing more.
- **sec-4 — network ring (isle-core).** DOCKER-USER rendering, per-app networks, ufw baseline, exposure gateway isolation. Acceptance: from inside any app, host ssh/docker/libvirt/swarm ports are unreachable; the agent is.
- **sec-5 — host ring (isle-core).** unattended-upgrades, auditd → `SecurityEvent` rows, sysctl set. Acceptance: audit rows appear in Polari within a minute of a sudo on the host.
- **sec-6 — audit + escape-test (both sides).** `isle security audit|escape-test`, `pol deploy audit <node>`, `SecurityControl` rows + `/display/security` (tables only), the gate's `--hardening` mode, ci-3 runs the escape-test in the throwaway isle. Acceptance: every escape attempt fails on a freshly installed isle; a deliberately weakened isle (one control off) is reported `partial` naming the control.
- **sec-7 — the store shows it.** Each app's card states its confinement (profile kind, capabilities, writable paths) from the same stanza; a person sees what an app may touch before installing it.

## 5. Decisions (defaults in bold; his call)

- **D1 userns-remap vs rootless docker.** **userns-remap** (one daemon, works with the agent's bridges and macvlan); rootless docker per app user is stronger but breaks macvlan/DHCP joins — revisit for member devices that host no networking apps.
- **D2 per-app uid range.** **10000–19999 reserved for isle apps**, allocated at install, recorded on the IsleApp row.
- **D3 the manifest's `security.profile` vocabulary.** **web-app | worker | gateway | vpn-gateway | hardware-extension**; anything else refuses at conform.
- **D4 capability allow-list.** **NET_ADMIN, NET_BIND_SERVICE, CHOWN, SETUID, SETGID, DAC_READ_SEARCH (read-only helpers)**; `SYS_ADMIN` never (no app has a legitimate need; hardware access goes through a guest).
- **D5 ufw on the isle host.** **On, default deny incoming**, ssh allowed from the isle VLAN + the owner's LAN, agent ports on the isle interface only. (Today it is inactive on isle-core.)
- **D6 the escape-test cadence.** **After every `isle security apply` and on every ci-3 run**; not on a timer (it creates containers).
- **D7 enforce vs complain first.** **Complain mode for one release** for the fixed-piece profiles (logs, no denials) so isle-core sees what nginx/agent actually touch, then enforce; per-app profiles enforce from day one (they are generated from a declaration, so a denial means the declaration is wrong).
- **D8 the owner's account.** Untouched by the isle (his `sudo docker libvirt kvm` membership stays); the isle only ever creates the narrow groups. A separate "operator" account that is in `polari-remote` and nothing else is recommended for AI-driven work.

## 6. Boundaries

- Isle-side (isle-core's Claude): sec-1, sec-2, sec-4, sec-5, the isle half of sec-3 and sec-6 — everything under `Isle-Mesh/`. Contract in `NOTES-FROM-POL-CORE.md`.
- Polari-side (this instance): the manifest `security` stanza + conform + scaffold default (sec-3), the pure profile/seccomp renderer, `pol deploy audit`, the `SecurityControl`/`SecurityEvent` classes + `/display/security`, the store card (sec-7), the CI hook.
- Not in this plan: the swarm/server profiles' hardening (the same rings apply to `pol prod` stacks — a follow-on once the isle pattern lands, since compose already carries `read_only`, `cap_drop`, `security_opt`).

## 7. Grounding

- Survey: isle-core 2026-09-10 (`docker info` security options, `docker inspect` of the five containers, `aa-status`, `virsh dominfo`, ufw, sysctl, `systemctl cat isle-host-agent`).
- `Isle-Mesh/isle-agent/docker-compose.remote.yml` (NET_ADMIN for udhcpc), `isle-cli/scripts/url.sh` (gateway containers), `Isle-Mesh/polari-isle/docker-compose.yml`.
- `polari-cli/shells/groups/` (the two sudoers groups), PRODUCTION_DEPLOY_PLAN §15.
- Ubuntu: AppArmor (docker-default, libvirt sVirt, `userns` rules on 24.04), docker `userns-remap`, `DOCKER-USER`, ufw, auditd, unattended-upgrades.
