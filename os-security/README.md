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
sudo bash os-security/escape-test.sh --profile isle-app-<name>          # prove it
pol security os render|apply|audit|escape-test …                        # the same through the CLI; pol deploy audit <node> remotely
```

Nothing here restarts docker on its own: `daemon.json` changes (userns
remap) are rendered and DIFFED; the operator applies them in a window.
Fully open source, and depends only on what Ubuntu ships: the Linux
kernel's AppArmor LSM and seccomp, docker/containerd, libvirt + qemu
(sVirt), nftables/iptables, ufw, auditd, systemd. Licences in
`AI-Notes/guides/security/SECURITY_OVERVIEW.md`.
