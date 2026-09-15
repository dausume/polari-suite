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

## 8. Per-deployment scenarios (his ask 2026-09-10)

The controls are not one policy but a policy PER SCENARIO, declared in
`os-security/scenarios/<name>.yml` and rendered for that kind of machine:

| scenario | rings | fixed pieces | edge ports | notes |
|---|---|---|---|---|
| `isle` | all five | isle-agent, isle-gateway, prf-isle backend/frontend, isle-apt, isle-remote-agent (NET_ADMIN for DHCP) | 80/443 on the isle interface; doors added by the isle | userns-remap `isle`; hardware tier; sVirt required for guests |
| `swarm-lean` | 2–5 | pol-proxy, pol-hub, prf-frontend, prf-backend | 80/443 to anyone; swarm ports to peers | overlay encrypted; secrets/env 0600 |
| `swarm-full` | 2–5 | + psc-frontend/backend, keycloak, mariadb, minio, redis | same | credential files 0600 |
| `dev` | 3 (complain), 5 (sysctl) | none | untouched | the audit still reports |

Each scenario also carries the DOCKER-USER allow/deny lists, the ufw rules
with named source sets (isle, isle-lan, admin-lan, swarm — resolved from
the environment, never widened to "any" when unresolved), and the
host-side ownership rules. `pol security os` auto-detects the scenario
(isle agent present → isle; stack polari-prod → swarm-full; polari-lean →
swarm-lean; else dev).

## 9. Dynamics — the policy follows the apps

Profiles are per app and exist only while the app is up: `render.py`
takes the apps from the manifests (`--apps-from-manifests`), from a
running core's registrar (`--apps-from-core URL`: only modules the
registrar says are online), or from a file the isle writes from its
registry; it writes `out/<scenario>/manifest.json` naming every profile
it produced, and `apply.sh` unloads and removes any `isle-app-*` profile
NOT in that manifest. So: app admitted → render + apply → its profile is
loaded and its compose fragment carries `security_opt`; app put away →
render + apply → its profile is gone. The isle-side hook is `isle app
install|remove` calling the same two steps (sec-3, isle-core); on the
swarm route `pol prod apply` renders after every deploy and applies when
`POL_PROD_HARDEN=on`. Templates are jinja2 (`templates/apparmor/app.j2`
is the one profile template; `seccomp/kind.json.j2` one allow-list per
kind; firewall/dac templates per scenario), rendered with StrictUndefined
so a missing value fails loudly rather than rendering a hole.

## 10. Network + firewall — what the check found (his doubt 2026-09-10)

His instinct was right that nginx + the ingress policy carry most of the
network security on an isle: the agent's nginx is the sole ingress,
generated from the registry, TLS 1.2/1.3 with isle-CA leaves, a
per-app protocol class incl. mutual TLS, and the router's zones forward
nothing between the isle and the real interface (verified by the isle's
own network-isolation check). What was NOT covered, now addressed:
1. **Doors are plain HTTP** on the outside leg (`isle url expose` publishes
   `0.0.0.0:<port>:80`, basic auth in the clear) — reported to isle-core;
   the door must terminate TLS. Docs say "VPN or trusted network only"
   until then.
2. **Host firewall off** on isle-core (ufw inactive), sshd on all
   interfaces, DOCKER-USER empty (containers could reach host services),
   swarm ports open to the world on pol-core → the firewall ring
   (scenario ufw rules + DOCKER-USER) renders and applies; the audit
   reports each.
3. **Swarm overlays unencrypted** → every stack overlay now carries
   `encrypted: "true"` (lean/prod compose + stackify promotion).
4. **The suite's edge proxy had no hardening** beyond TLS 1.2/1.3 →
   both templates now set modern ciphers, server preference, no session
   tickets, `server_tokens off`, nosniff/frame/referrer headers, request
   rate + connection limits on `/downloads`, and HSTS rendered ONLY once
   the staged edge cert is publicly trusted (a self-signed edge with HSTS
   would lock browsers out). `pol proxy guard` passes for lean and prod.
5. Docker's published ports bypass ufw — documented; container traffic is
   governed by DOCKER-USER, host admission by ufw, and the lean stack
   publishes 80/443 in host mode on the manager only.

## 11. Built 2026-09-10 (sec-0 → the first slices of sec-2/3/4/5/6)

- `os-security/` — README, four scenarios, templates (AppArmor app
  profile, seccomp per kind, DOCKER-USER, ufw, docker daemon.json,
  sysctl, systemd hardening drop-in, perms, audit rules), `render.py`
  (validates the stanza vocabulary; StrictUndefined), `apply.sh`
  (enforce/complain, removes gone apps' profiles, diffs daemon.json,
  never restarts docker), `audit.sh` (24 controls across the rings,
  verdict, `--json`), `escape-test.sh` (14 cross-over attempts).
- Manifest `security` stanza: `SECURITY_*` vocabulary + `security_findings`
  in `moduleService/manifests.py`; generate adds the deny-all default,
  hand-tuned stanzas survive; conform refuses bad values; all 59 modules
  regenerated (59/59 conform); standard README §11.
- CLI: `pol security os render|apply|audit|escape-test [--scenario]`,
  `pol deploy audit <node>` (ships audit.sh over ssh), `pol prod apply`
  renders the scenario after every deploy and applies with
  `POL_PROD_HARDEN=on`.
- Proofs: 63 rendered profiles pass `apparmor_parser -Q`; seccomp lists
  are valid JSON (255 syscalls allowed per kind); on isle-core, with the
  `isle-app-prf-backend` profile LOADED AND ENFORCED, the escape test
  blocked all 14 attempts (docker socket, host /etc/shadow, mount,
  sysrq, sysctl, kernel module, ptrace init, raw socket, userns, write
  outside declared paths, chroot, keyctl, bpf, firmware); profile
  unloaded after. `pol deploy audit isle-core`: verdict OPEN (12/13) —
  the honest baseline the phases move from.
- Docs: a Security section on the public site — overview (the property,
  the layers, how policy is applied, every dependency with its licence:
  fully open source), OS security, proxy security, firewall security,
  network security (with the known gaps named).
Remaining: the isle-side apply at install/remove (sec-3 isle half),
userns-remap migration (sec-1), TLS on doors, auditd → SecurityEvent
rows + `/display/security` (sec-5/6), the store card (sec-7), D1–D8.

## 12. The assurance ladder (his point 2026-09-12) and the honest state

His correction: the security is not built; rendered templates tested once are not protection. And beyond building it, another step exists: independent third-party testing, which is what anyone would need before insurance on data storage and security using Polari can even be discussed.

Rungs: designed → built → applied by default on every route → self-tested on every deployment (audit + escape test, results recorded) → independently tested (a third party, findings and fixes published) → insurable (an underwriter's decision, needs the previous rung and evidence it is kept). Today Polari is at rung 1, partly 2. The docs carry a "designed and prototyped, not deployed" banner until rung 3 and say plainly that no assurance claim is made until rung 5.

Order of the arc from here: (a) sec-1..3 on the server and the isle so the rings apply by default (rung 3); (b) audit + escape test in every deployment's verify and in CI (rung 4); (c) the security interfaces (SECURITY_INTERFACES_PLAN) so an operator can see the state; (d) scope and budget an independent test — what to test (the droplet profile, an isle), against which references (CIS benchmarks for Docker and Ubuntu, OWASP ASVS for the apps), and where findings are published — his decision D9 here.

## 13. sec-1a, Polari side (2026-09-12, branch dev-sec-1) — what the first slice found before the server was touched

Three facts, each checked, that change how the MAC ring is applied:

1. **Explicit `deny` rules are enforced even in complain mode**, quietly (apparmor.d(5): complain only converts *implicit* denials to ALLOWED; proven on isle-core with a probe profile: `deny /tmp/x r` under `flags=(complain)` → "Permission denied", no log line). The first template was a blanket `file,` allow with `deny` carve-outs, so "warn-only" would have bitten silently and logged nothing about files. `templates/apparmor/app.j2` is now an **allow-list** (image `rmix`, declared paths `rwk`, declared network and capabilities, the runtime's signals); complain mode keeps only docker's stock explicit denies (every container is under them today, so complain never denies more than stock docker); enforce mode adds Polari's explicit denies. Bonus fixes from docker's stock profile: `signal (receive) peer=unconfined/runc/crun/dockerd` (the old template would have blocked `docker stop` under enforce), moby's `/proc` pattern, the powercap deny.
2. **Swarm services cannot carry a profile.** `docker stack deploy` drops `security_opt` (docker/cli `UnsupportedProperties`; also `privileged`, `devices`, `userns_mode`), so per-service AppArmor/seccomp is impossible on the server route. The lever is the node-wide `docker-default`: dockerd loads its own only when none is loaded (moby `daemon/apparmor_default.go`), and `apparmor_parser -r` swaps it live. Scenario keys `mac_attach: docker-default` (render the union of the fixed pieces + docker's stock copy for `--revert-docker-default`) and `apps_run: in-core` (modules fold into prf-backend's stanza; none get a profile of their own — 59 today, all the default stanza, so nothing widens). Proven on isle-core: swap in (complain) → a plain container's write to `/usr/bin` logged as 3 ALLOWED lines under `docker-default` with the rules `allowed.py` suggests → revert → stock profile back in enforce, no file left, every isle container untouched.
3. **The escape test never consulted AppArmor.** Full-confinement pass on isle-core: 14/14 blocked under complain AND under enforce with zero AppArmor audit lines — every block came from cap_drop ALL / seccomp / read-only rootfs / docker's masked paths; three probes (raw socket, keyctl, bpf) had "passed" on plain alpine only because python3 was missing; the docker-socket probe (busybox `timeout 3 nc -U`) hangs forever once the profile no longer fails it at `test -r`. `escape-test.sh` now: python image by default, python-dependent probes reported as skipped when absent, a host-side time limit (HUNG is a test failure), `--verbose` shows the blocking error, and `--alone` (profile only: seccomp unconfined, default caps, writable rootfs) — the pass that measures the MAC ring's own contribution.

Built: `os-security/allowed.py` (+ `pol security os allowed [--since] [--profile] [--rules] [--json]`, exit 1 when the list is non-empty), `apply.sh` docker-default piece + `--revert-docker-default` (`pol security os revert`), `audit.sh` route-aware MAC controls + `no-audit-lines-24h`, `pol prod harden [--enforce|--dry-run] | report | revert`. Test loop run locally: 142 profiles parse (all four scenarios, complain; swarm-lean also in enforce), apply dry-run, allowed selftest, audit. The server step (sec-1a proper) is his: the droplet is reachable only from his console (no ssh key from pol-core) — recipe in the handoff §6.

Consequence for the order of the arc: on the swarm route the strongest ring the server can get today is the **app-surface ring** (cap_drop ALL, read_only, tmpfs, pids) in `docker-compose.lean.yml`, which is not there yet and is a production stack change (his go) — sec-1b-swarm. AppArmor on the swarm is one shared profile per node, honest but coarse; per-app confinement exists only on the isle route.

## 14. sec-1a continued, same day (2026-09-12 evening, dev-sec-1) — seccomp warn mode, the loop across the home machines, the hardware-app notice

- **sec-1c, seccomp warn mode:** `templates/seccomp/kind.json.j2` renders `defaultAction: SCMP_ACT_LOG` in complain (a syscall outside the list is permitted and logged, kernel audit type=1326) and always an `<kind>.enforce.json` twin; `allowed.py` reduces those lines by syscall name (`syscalls_x86_64.json` ships with it) and suggests the list entry. First harvest on isle-core (python:3.12-alpine workload + nginx under the LOG lists): exactly one missing call, `open` (musl's loader) — added to the base list; under the ENFORCE lists python's workload (threads, subprocess, sqlite, ssl, asyncio, multiprocessing, tempfiles) and nginx (web-app and gateway kinds, serving a page) now run with no seccomp line.
- **`pol deploy harden <node> [--scenario] [--dry-run|--enforce] | --report [--rules] | --revert`:** renders here, ships the rendered scenario + scripts to the node, applies there warn-only, audits; scenario auto-detected from the node (isle agent → isle, else swarm-lean). Dry-runs on isle-core and econ-core; the REAL warn-only apply ran on isle-core: node-wide union in complain over its 5 containers (`node_profile: true` in isle.yml — a baseline until the agent attaches per-app profiles), 65 per-app profiles loaded in complain (inert until attached), seccomp lists staged, firewall/host/DAC rings printed. Audit after: open 12/14/0 (was 12/13/1; the new `no-audit-lines-24h` control counts today's test traffic). Revert: `pol deploy harden isle-core --revert`.
- **Stack overlay:** `out/<scenario>/stack.security.yml` = every fixed piece's swarm-legal fragment (cap_drop/add, read_only, tmpfs, pids) in one file to merge with `-c` — the app-surface ring for the swarm route; not yet deployed (a stack change, his go).
- **apply.sh fixes:** seccomp staging and unit drop-ins no longer abort a warn-only run (dir created only under --enforce, file installed regardless → `set -e` exit); `--skip-cache` everywhere; node union loaded whenever the manifest has a `node` entry.
- **The hardware-app rule, as HE ruled it (2026-09-12):** hardware kinds (`app.kind` hardware-app / hardware-extension-app, or a `security.profile` hardware-extension / `devices`) may be installed anywhere — the Polari side is useful for development — but a normal user must be told they will not actually work there: the hardware half needs the full isle (deb route: KVM guest + passthrough from the hardware map, the `hardware` agent tier) to reach the OS kernel and devices; a Docker Swarm deployment never can. Built as a NOTICE, never a refusal: `moduleService/hardware_reach.py` (route = `POLARI_DEPLOY_ROUTE` isle|swarm|dev, set in the lean/prod compose; inferred otherwise) → the registrar row's `hardware` {reach: ok | polari-side-only | none, notice}, `/api/modules/health` (brief too), the fetch-admit reply (`notice`), `pol modules health` (per-module line + list flag), the download page card. Before today the only rule was a conform lint (hardware kinds need `agentTier: hardware`) — nothing at admission or on the pages.

## 15. When the rings apply, and what has to restart (his question 2026-09-12)

Not every piece needs a reboot; most need nothing, some need a container to be recreated, a few need the docker daemon restarted in a window, and only kernel-level changes need the machine. The honest ladder, per piece:

| piece | takes effect | what must restart | why |
|---|---|---|---|
| AppArmor profile load, complain↔enforce switch, the node-wide docker-default swap | immediately | nothing | `apparmor_parser -r` replaces the policy in the kernel for running processes |
| seccomp list attached per container (`security_opt`) | at container start | that container (service update / `isle app restart`) | the filter is installed at exec time and cannot be changed after |
| daemon-wide seccomp-profile, `icc=false`, `no-new-privileges` (daemon.json) | at daemon start | dockerd (`live-restore` keeps containers up for most keys) | daemon settings |
| user-namespace remap (daemon.json) | at daemon start | dockerd AND every container recreated; image/volume ownership shifts | the biggest change; a real maintenance window, not a reboot |
| cap_drop / read-only root / tmpfs / pid limit (compose fragment, stack overlay) | at container start | the service (rolling update) | container config |
| DOCKER-USER, ufw rules | immediately | nothing (existing ssh sessions stay; new rules apply to new connections) | iptables |
| sysctl | immediately (`sysctl --system`) | nothing; persisted in `/etc/sysctl.d` for boot | kernel knobs are live |
| auditd rules | `augenrules --load` | auditd service if newly installed | |
| systemd hardening drop-ins for the isle units | after `daemon-reload` | those units | unit properties are read at start |
| a kernel update (unattended-upgrades), boot parameters, LSM changes | at boot | **the machine** | the only true reboot case |

Rules that follow:
1. **Never reboot from a script.** A deb's postinst or `apply.sh` records what is pending and says so; the person restarts. Use Ubuntu's own convention so the desktop and the CLI both show it: touch `/var/run/reboot-required` and append the package to `/var/run/reboot-required.pkgs` only for the kernel-tier case; for the daemon tier write `/run/polari/restart-required` (`docker`, `containers:<names>`, `units:<names>`) and have `pol security os status`, `isle status` and the store's status card read it.
2. **`apply.sh --needs`** (to build): after an apply, print the restart tier per applied piece and the one command that completes it (`docker service update --force <svc>`, `systemctl restart docker` in a window, `isle app restart <app>`, reboot). Warn-only applies need nothing today (profiles are live); the first enforce of the surface ring needs a service update; the remap needs the window.
3. **Order of a setup** so that at most one window is needed: (a) load profiles complain (live) → harvest a day → enforce (live); (b) the compose fragment / stack overlay at the NEXT deploy (a deploy recreates containers anyway); (c) the firewall rings live; (d) daemon.json changes batched into ONE dockerd restart, the remap last and only with the migration of volumes planned; (e) a kernel update reboots on the owner's schedule. On the ISO route (§ POLARI_ISO_PLAN) none of this is a migration: the rings are on from first boot, which is what "applied by default on every route" (rung 3) means there.
4. **The store / manager app** asks for the restart the way the desktop does (a notice, a button), never a surprise; the deb route reuses the desktop's reboot notification.

## §16 — Development postures (his ask 2026-09-14): relax for testing, never beyond one isle

**The ask.** Some testing needs parts of the security relaxed (root over ssh for a harness, a debugger port, a
profile in complain while a new module is exercised). A development mode must be able to switch those parts off —
and must NEVER expose anything beyond the scope of a single isle.

**The rule: a posture, not a switch.** "Dev" is a named POSTURE alongside the scenarios (isle / swarm-lean /
swarm-full / dev already exist as scenarios; this adds posture = the enforcement stance), never "security off".
A posture is a LIST of named relaxations, each scoped by the isle boundary, each visible, each time-boxed.

**The isle boundary — invariants no posture may break (audit rings mark a breach FAIL, never WARN):**
1. Inbound from any non-isle interface stays closed: the DOCKER-USER / ufw ring keeps accepting only from the
   isle's WireGuard + LAN subnets; a relaxation may open a port ON THE ISLE INTERFACES ONLY (`-i wg0`, `-s <isle cidr>`).
2. Nothing binds 0.0.0.0 on an upstream/public interface in dev; a debugger/inspector port binds the isle address.
3. ssh: key-only from the isle subnet is the most a relaxation grants (`Match Address <isle cidr>` →
   `PermitRootLogin prohibit-password`); PasswordAuthentication is never re-enabled by any posture.
4. No key or cert material leaves the node; the inventory keeps recording types + hashes only.
5. Dev posture is REFUSED on nodes whose deploy route is production (the droplet/server role, `pol prod`): it exists
   for isle members, the home swarm and standalone dev nodes only. Refusal is loud and names the role.
6. Federation/VPN doors stay as the applied scenario left them — a posture never widens what other isles can reach.

**What a relaxation looks like** (each = a row in the security module, provenance polari, with its scope):
- `mac.complain <profile>` — one profile to complain (the allow-list template already keeps explicit denies).
- `seccomp.log <kind>` — SCMP_ACT_LOG for one kind (worker/python already in warn mode).
- `net.isle-port <port>` — open a port on the isle interfaces only.
- `ssh.group <group> <user> --for` — a person joins a permission group that is allowed over ssh, for the time-box.
- `ssh.root-key-from-isle --for` — DEV POSTURE ONLY (his ruling 2026-09-14): `Match Address <isle cidr>` →
  `PermitRootLogin prohibit-password`; key-only, from the isle subnet, time-boxed, reverted on expiry/reboot, shown
  in the notice bar and the audit as an active relaxation. Never exists in any non-dev posture.
- `host.core-dumps` / `host.ptrace-scope 0` — debugging knobs, host-local.
- `dac.dev-group-write <path>` — group write on a dev tree, never on /etc, /var/lib/polari keys, the vault.

**Visible, time-boxed, audited.** `pol deploy harden --posture dev --for 8h` (default 8h; reverts on expiry AND on
reboot; `--until` never exceeds 7 days); the security overview + the app-system-notice bar say "DEV POSTURE until
<time>: <n> relaxations"; `pol security os audit` gains a `posture` ring: each active relaxation listed with its
scope, plus the six invariants checked — a breach is FAIL. Every apply/revert is a SecurityAuditRun row.

**Shape on the existing pieces.** render.py: `--posture dev` = the scenario's fixed_mode with the relaxation list
applied (per-ring overrides, already how `--mode` works); apply.sh: relaxations are drop-ins with an expiry unit
(`polari-posture-revert.timer`); audit.sh: the posture ring; security module: posture as a fourth view mode
(stock | today | complain | enforce | dev) so the topology shows exactly what dev opens and to whom (the isle only).

**Not decided (his):** D1 the default duration; D2 whether a dev posture may be applied remotely by the core to a
member, or only locally; D3 DECIDED 2026-09-14: root over ssh does not exist in a secure posture; in DEV POSTURE it may (key-only, isle cidr, time-boxed).

### §16a — ssh is for PERMISSION GROUPS, never root (his ruling 2026-09-14)

"In an actually secure situation root with key ssh should definitely not exist; what can exist is permission groups
that are allowed to be used over ssh." So:
- `PermitRootLogin no` everywhere, every posture (the audit's `no-root-login` already fails on `prohibit-password`).
- `AllowGroups` names the groups that may log in at all (audit control `ssh-groups`, added): a starting set
  `polari-ops` (operate: pol, systemctl for polari units, journalctl), `polari-dev` (the dev posture: docker, the
  module trees, debuggers), `polari-observe` (read-only: `ForceCommand` a fixed status shell). Being in no group =
  no ssh, key or not.
- Each group gets its OWN sudo command list in `/etc/sudoers.d/polari-<group>` — never `NOPASSWD: ALL` for a person
  or a group beyond root/admin/sudo (audit control `sudo-scoped`, added; isle-core's passwordless sudo for the user
  account will show as the first finding).
- `Match Group` blocks scope further: `polari-observe` gets ForceCommand + no forwarding; `polari-dev` may get
  forwarding on the isle interfaces only; every group is still key-only, from the isle cidr.
- The groups are OBJECTS in the security module (PermissionGroup rows with their ssh allowance + sudo list) and
  appear in the counterexamples ("a valid group holding exactly what it needs") and on the isle topology's ssh
  panel (who may reach which node, by group).
- The dev posture's ssh relaxations: membership (`ssh.group polari-dev <user> --for 8h`) and, his ruling, ROOT OVER
  SSH (`ssh.root-key-from-isle --for 8h`: key-only, from the isle cidr only, password auth still off). Both expire,
  both revert on reboot, both are audited; outside dev posture root over ssh never exists.
- Isle side (contract): the isle CLI creates the groups + sudoers files at install, puts the installing person in
  `polari-ops`, and the uninstall hand-back removes only what it created (the journal rule).

### §16b — dev-mode installs vs production installs; the standing warning (his rulings 2026-09-14)

- ssh, and even root over ssh, is something dev mode CAN enable. What matters is that a DEV-MODE INSTALL of Polari
  and a PRODUCTION-MODE install are different, declared things: `POLARI_POSTURE=dev|production` on the instance
  (compose/env, set by the installer's mode choice: `isle install --mode dev|production`; the deb's debconf question;
  the ISO's build knob), and `/etc/polari/posture.json` on each node:
  `{"posture": "dev", "until": "<UTC>", "relaxations": ["ssh.root-key-from-isle", ...], "applied_by": "<who>"}`.
- **The standing warning in dev mode** (his words): *any connection to systems that are not your own is extremely
  dangerous.* Shown by the app-system-notice bar on every page of a dev-mode instance (`dev-mode`, warning), on the
  security overview, by `pol` on every verb that opens a connection (`pol deploy`, `pol prod`, federation/VPN join,
  `pol apps fetch` from a foreign core) and by the isle CLI's join/peer verbs. Text lives in one place
  (security_notices.DEV_MODE_TEXT) so every surface says the same thing.
- **Tracking (built):** the inventory reports AllowGroups, the groups and their members, every sudoers grant and the
  posture file; the security module derives per device an ASSURANCE — `secure` (keys only, no root, AllowGroups set,
  sudo scoped), `dev` (declared and unexpired, listing what it relaxes), `unsecured` (anything else, with reasons;
  passwords accepted is unsecured even in dev — the invariant), `closed`, `unknown` — and one SshPermissionLevel row
  per person/group (allowed over ssh or not; root / blanket-sudo / scoped-sudo / shell; via; expires under dev).
  `/api/security/ssh` serves `assurance` + `levels_detail`; the isle topology shows both; the audit's
  `posture-assurance` control gives the one-line reading; `pol deploy inventory --post` prints it.
- **Production mode refuses** dev relaxations (§16 invariant 5) and shows no warning; a production instance whose
  devices are `unsecured` shows the `ssh-unsecured` error notice instead.
- Owed: `pol deploy harden --posture dev|production --for`, the installer's mode question, the isle CLI's warning on
  join/peer, PermissionGroup rows tied to the tracked groups.

### §16c — BUILT 2026-09-14: `pol deploy posture <node> status|dev|production`
`os-security/posture.sh` runs on the node as root: `dev --for 8h [--relax a,b] [--cidr]` writes /etc/polari/posture.json
(dev, until, relaxations, by), applies the named relaxations (`ssh.root-key-from-isle` = an sshd drop-in
`Match Address <isle cidr>` → `PermitRootLogin prohibit-password`, meaningful once the base is `no`; `host.ptrace-scope`,
`host.core-dumps` = sysctl drop-ins; the ring-level ones are recorded for apply.sh / the isle CLI), installs a
non-persistent systemd timer that runs `production` at expiry (so a reboot reverts too), prints the standing dev
warning; `--for` never exceeds 7 days; REFUSED when /etc/polari/production-route exists (written by `pol prod apply`
for a real domain). `production` reverts everything. Proven on isle-core (apply → drop-in + timer → revert clean).
Still design: D1 default duration (8h today), D2 remote-by-core vs local-only (today: whoever runs pol deploy).

## §17 — DEV APPS and dev builds: security that does not block, and says so (his rulings 2026-09-15)

His words: dev builds are their own thing where we specifically turn OFF securing things so everything can be tested
via APIs and we SEE WARNINGS when we do the wrong thing; Polari instances and objects must be able to dynamically form
new connections without breaking on security. So a **dev app** = a version of an app (and a dev build = a version of
an instance) where security is deliberately NON-BLOCKING: every control still evaluates, nothing is denied, and each
would-have-been-denial becomes a WARNING a person and an API can see.

- **One switch, one ledger.** `POLARI_POSTURE=dev` (the install-level mode, §16b) puts the security module into
  OBSERVE: AuthzRule / ContentPolicy / BrowserPolicy / TrustChannel checks return "allow + would-deny" instead of
  deny; the decision lands as a `SecurityEvent` row (who, what, which rule would have denied, when) and a `warning`
  notice on the notice bar; `/api/security/events` lists them; the audit counts them ("N actions ran that
  production would deny"). The invariants of §16 still hold (no passwords over ssh, nothing on upstream interfaces,
  refused on production routes).
- **Dynamic connections.** In dev, a connector (mqttbridge, grpcbridge, ThingSet, federation/VPN, module fetch from
  a foreign core, instance-to-instance links) ADMITS a new peer at once — recorded as a `TrustChannel` row in state
  `dev-admitted` with a warning — instead of waiting for the PeerAgreement/admission step; production requires the
  agreement. Self-signed and expired certificates are accepted in dev with a warning (`--insecure` becomes the
  posture, not a flag).
- **Dev apps as a variant, not a fork.** The app manifest gains `security.devVariant` = the list of controls the dev
  variant relaxes (default: all authz + content + trust checks → observe); the store shows a "DEV" badge and the
  standing warning; the catalogue offers the dev variant only on a dev-posture instance; the deb's preinst refuses a
  dev variant on a production route (like the hardware refusal). Same code, one posture check — never two code paths.
- **SSH scaffolding from the core outward** (his ask, same day): every machine the ISO builds authorises the core's
  dev key at install (D11 placed it; now it is generated and tracked): `pol iso keys init` makes the core's ed25519
  pair (untracked, `.polari/keys/`), every `pol iso build` includes its public half, first boot reports the device
  (hash, hostname, addresses) to `/api/iso/joined`, the core writes an ssh config stanza per device, and
  `pol iso ssh <device>` opens the session — one device manipulates all of them for development and testing. In
  production posture the key lands in the `polari-ops` group with its scoped sudo; in dev posture it may be root
  (§16a).
- What warns but never blocks in dev — the list is the contract: authz decisions, content policy, trust channels,
  certificate validity, peer admission, posture relaxations, hardware-tier notices. What still refuses even in dev:
  the six §16 invariants, dev variants on production routes, ISO refusals that protect the person (encryption on
  headless).
