# os-security — the DAC + MAC controls, per deployment scenario, rendered

The one place the suite's operating-system security is DECLARED: what a
process may touch (AppArmor, MAC), who owns what and runs as whom (DAC),
what the firewall admits, what the kernel is told. Everything here is a
jinja2 template rendered for a **scenario** (isle, swarm-lean, swarm-full,
dev) plus the **apps currently up** on that machine, so the rendered
policy follows the deployment and changes as apps go up and down.
Plan: `AI-Notes/plans/ISLE_HARDENING_PLAN.md` (§8 scenarios, §9 dynamics).

```
os-security/
  scenarios/<name>.yml        which rings apply, the fixed pieces, ports, networks, tier
  templates/
    apparmor/app.j2           ONE profile template; every app (and fixed piece) is an instance
    seccomp/<kind>.json.j2    syscall allow-lists per profile kind
    firewall/docker-user.sh.j2, ufw.sh.j2   the network ring
    dac/daemon.json.j2, sysctl.conf.j2, systemd-hardening.conf.j2, perms.sh.j2, audit.rules.j2
  render.py                   scenario + apps → out/<scenario>/ (idempotent, pure)
  apply.sh                    load what render made (root; complain or enforce; removes profiles of apps that are gone)
  audit.sh                    score every ring on THIS machine (pass/fail per control, --json)
  escape-test.sh              attack our own confinement from inside a throwaway container; every attempt must fail
  out/                        rendered (gitignored)
```

## Warn-only by default (his rule 2026-09-12)

Every scenario renders in `complain` mode and `apply.sh` loads AppArmor profiles in complain: everything an enforced profile would deny is logged (`ALLOWED` audit lines), nothing is denied. The rings that cannot warn — DOCKER-USER, ufw, sysctl, permissions, systemd drop-ins — are only printed. `--enforce` applies one piece on purpose, after it has been proven with the test loop in `AI-Notes/handoffs/SECURITY_ARC_HANDOFF.md` §4. Change one piece, re-test, record, then the next.

**What "complain" really means (proven on an isle, 2026-09-12).** AppArmor enforces *explicit* `deny` rules even in complain mode, and quietly: `apparmor.d(5)` — "complain mode will only convert implicit denials to ALLOWED". A profile written as a blanket `file,` allow with `deny …` carve-outs (the first draft) would therefore have bitten silently and logged nothing about files. So the one template (`templates/apparmor/app.j2`) is an **allow-list**: the image readable and executable, the declared paths writable, the declared network and capabilities, the runtime's signals. In complain mode everything outside it is permitted and logged as `ALLOWED`; the only explicit denies kept are docker's own stock ones, which every container is under today, so a complain profile never denies more than stock docker does. Enforce mode adds Polari's explicit denies on top (they win over any allow). `allowed.py` (`pol security os allowed [--since 1d] [--profile P] [--rules]`) reduces the kernel's lines to the list of what enforcing would break, with the rule that would allow each; an empty list is the gate for `--enforce`.

## The swarm route: services cannot carry a profile (found 2026-09-12)

`docker stack deploy` drops `security_opt` (docker/cli `UnsupportedProperties`, with `privileged`, `devices`, `userns_mode`), so no swarm task can be given an AppArmor or seccomp profile of its own. Two consequences, declared per scenario:

- `mac_attach: docker-default` (swarm-lean, swarm-full): the MAC ring's one lever is the node-wide `docker-default` profile. dockerd loads its own only when none of that name is loaded (moby `daemon/apparmor_default.go`), and `apparmor_parser -r` replaces it live for running containers. `render.py` writes `apparmor/docker-default` = the **union** of the fixed pieces' surfaces, plus `docker-default.moby` (docker's stock profile) so `apply.sh --revert-docker-default` (`pol security os revert`) puts it back with one command, no docker restart. The per-piece `isle-app-*` profiles are still rendered for the escape test. seccomp per kind cannot attach either; the daemon-wide `seccomp-profile` setting is the equivalent lever (rendered into daemon.json in a later piece).
- `apps_run: in-core` (swarm-lean, swarm-full): modules are not containers on the swarm — they run inside `prf-backend` — so they get no profile of their own; their stanzas fold into the core's (network and capabilities union; writable stays the core's; hardware extensions are left out by name). `manifest.json` records `folded`.
- The compose fragment carries only what the route honours: on swarm `cap_drop/cap_add`, `read_only`, `tmpfs`, `deploy.resources.limits.pids`; on the isle route additionally `security_opt` and `pids_limit`.

The isle route (`mac_attach: security_opt`, `apps_run: containers`) is unchanged: the agent starts plain containers, so each app carries its own profile through the fragment. `node_profile: true` (isle.yml) additionally renders and loads the node-wide union in complain as a warn-only baseline over every isle container until the agent attaches per-app profiles.

**seccomp warn mode.** In complain the per-kind lists render with `defaultAction: SCMP_ACT_LOG` (a syscall outside the list is permitted and logged, audit type=1326; an `<kind>.enforce.json` twin is always rendered); `allowed.py` names the logged syscalls (`syscalls_x86_64.json`) and suggests the list entry. Nothing attaches a seccomp file until a container is started with it, so staging them is inert. The first harvest found the one call musl's loader needs, `open`.

**Across the home machines.** `pol deploy harden <node> [--scenario S] [--dry-run|--enforce] | --report [--rules] | --revert` renders here, ships the rendered scenario and the scripts to the node, applies there warn-only and audits (scenario auto-detected: an isle agent → isle, else swarm-lean). The stack overlay `out/<scenario>/stack.security.yml` carries the app-surface ring for the swarm route (`docker stack deploy -c <stack>.yml -c stack.security.yml`).

## The model

Five rings, each independent (plan §2): the app's declared surface → DAC
(user-namespace remap, one uid per app, read-only rootfs, no capabilities
but the declared allow-listed ones, no new privileges) → MAC (an AppArmor
profile per app from its manifest `security` stanza; seccomp per kind;
libvirt's sVirt per guest) → network (DOCKER-USER denies containers any
path to host services except the agent and DNS; ufw default deny) → host
(sysctl, auditd, unattended upgrades).

## The app declaration

Every module's `polari-app.json` carries (scaffolded as deny-all):

```json
"security": {
  "profile": "web-app",            // web-app | worker | gateway | vpn-gateway | hardware-extension
  "writable": ["/data"],           // the ONLY writable paths (everything else read-only)
  "network": ["isle"],             // isle | internet | none
  "capabilities": [],              // from the allow-list: NET_ADMIN NET_BIND_SERVICE CHOWN SETUID SETGID DAC_READ_SEARCH
  "devices": [],                   // /dev paths, only for hardware-extension
  "ports": [3000]                  // listening ports inside the container
}
```

`pol modules conform` refuses vocabulary outside these lists. The renderer
turns it into `isle-app-<name>` (AppArmor), a seccomp file, and the
compose/stack fragment (`security_opt`, `cap_drop/cap_add`, `read_only`,
`tmpfs`, `user`) the isle or the swarm stack applies.

## Scenarios

| scenario | who | rings | notes |
|---|---|---|---|
| `isle` | an isle device (core or member with the agent) | all five | fixed pieces: isle-agent, isle-gateway, polari-isle backend/frontend, apt; hardware guests via sVirt |
| `swarm-lean` | the lean production stack on a manager | 2–5 | proxy, hub, prf-frontend, prf-backend; ports 80/443 only |
| `swarm-full` | the full production stack | 2–5 | + keycloak, mariadb, minio, psc, redis (odoo optional) |
| `dev` | a developer's machine | 3 (complain), 5 (sysctl only) | nothing enforced that would get in the way; audit still reports |

## Use

```
python3 os-security/render.py --scenario isle --apps-from-manifests      # or --apps apps.json
sudo bash os-security/apply.sh --scenario isle [--complain|--enforce]   # loads profiles, firewall, sysctl; removes gone apps' profiles
bash os-security/audit.sh [--json]                                      # pass/fail per control, this machine
sudo bash os-security/escape-test.sh --profile isle-app-<name>          # prove it (image needs python3: python:3.12-alpine by default)
python3 os-security/allowed.py [--since 1d] [--profile P] [--rules]     # what enforcing would break (root or adm)
sudo bash os-security/apply.sh --scenario swarm-lean --revert-docker-default   # swarm: docker's stock profile back
pol security os render|apply|audit|escape-test|allowed|revert …         # the same through the CLI; pol deploy audit <node> remotely
pol prod harden [--enforce|--dry-run] | harden report [--rules] | harden revert   # the server route, from the answered profile
```

Nothing here restarts docker on its own: `daemon.json` changes (userns
remap) are rendered and DIFFED; the operator applies them in a window.
Fully open source, and depends only on what Ubuntu ships: the Linux
kernel's AppArmor LSM and seccomp, docker/containerd, libvirt + qemu
(sVirt), nftables/iptables, ufw, auditd, systemd. Licences in
`AI-Notes/guides/security/SECURITY_OVERVIEW.md`.
