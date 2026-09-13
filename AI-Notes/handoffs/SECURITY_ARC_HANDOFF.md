# Handoff: the security arc (2026-09-12)

_For the next instance (or the next session of this one). Written after the first live production deployment and his corrections on the security docs. Read this before touching anything under `os-security/`, the security docs, or the `security` stanza._

## 0. His rules, verbatim in spirit

- **"Ensure everything is warn for now so we do not break things we cannot fix."** Every control defaults to warn / complain / report. Nothing enforces unless `--enforce` is typed for that one piece, on purpose, after it has been proven.
- **"Re-test each time we change and go through one piece of the functionality."** One piece at a time; after each change run the tests in §4 and record the result before the next piece.
- **"We have not built out this security yet."** Rendered templates tested once are not protection. Never write "in place" for a control that is only rendered. The public security pages carry a "designed and prototyped, not deployed" banner until rung 3 of the ladder (§2).
- **Third-party testing comes after building** and is what insurance on data storage would need. Polari makes no assurance claim until then (overview page, "The assurance ladder").
- **Privacy:** never real LAN or public addresses, machine hostnames or the owner's e-mail in tracked files or on the site (memory `privacy-no-real-identifiers`). The site builder has a guard and a gitignored denylist.

## 1. Read order

1. `AI-Notes/plans/ISLE_HARDENING_PLAN.md` — the substance: five rings (DAC, MAC, network, host, the app's own surface), scenarios (isle, swarm-lean, swarm-full, dev), dynamics (profiles follow apps up/down), the network and firewall findings, §11 what was built, §12 the assurance ladder and the arc's order, decisions D1–D8.
2. `AI-Notes/plans/SECURITY_INTERFACES_PLAN.md` — the operator side: App / Network / OS taxonomy as objects and screens, the module `security/` directory standard, per-app proxy snippets, content policies derived from the data model (observe → test → enforce), service verification, hardware trials, the per-app ledger, decisions D1–D9.
3. `AI-Notes/guides/security/*.md` — the public pages; keep their status sections true.
4. `os-security/README.md` and the scripts: `render.py`, `apply.sh`, `audit.sh`, `escape-test.sh`.
5. This file's §3 (state) and §5 (gotchas).

## 2. Where it truly stands (the ladder)

| rung | state |
|---|---|
| 1 designed | done |
| 2 built | partly: `os-security/` templates + scripts; manifest `security` stanza (59/59 conform); proxy hardening + encrypted overlays (real, running on the production server); the credential vault; the `security` module/interfaces NOT built |
| 3 applied by default | no — nothing from `os-security` is applied on the production server or any isle; `POL_PROD_HARDEN` is off; scenarios are now warn-only |
| 4 self-tested per deployment | no — escape test run once by hand on one isle (14/14 blocked); audit run once (open, 12 pass / 13 fail) |
| 5 independently tested | no |
| 6 insurable | no |

## 3. What exists, precisely

- `os-security/scenarios/{isle,swarm-lean,swarm-full,dev}.yml` — **all `mode: complain`**; swarm ones declare `mac_attach: docker-default` + `apps_run: in-core` (2026-09-12), isle `security_opt` + `containers`.
- `os-security/render.py` — validates the stanza vocabulary, renders AppArmor per app (`templates/apparmor/app.j2`, an ALLOW-LIST since 2026-09-12: complain keeps only docker's stock denies, enforce adds Polari's), the node-wide `docker-default` + stock `docker-default.moby` on swarm, seccomp per kind, route-legal compose fragments, DOCKER-USER, ufw, daemon.json, sysctl, systemd hardening, perms, audit rules → `out/<scenario>/` + `manifest.json` (incl. `folded`, `node`, `mac_attach`). `--apps-from-manifests` or `--apps-from-core URL` (only online modules).
- `os-security/apply.sh` — **warn-only by default**: profiles load in complain (`-C --skip-cache`); on swarm the docker-default swap (live); the rings that cannot warn (DOCKER-USER, ufw, sysctl, perms, daemon.json) are only printed unless `--enforce`. `--dry-run` prints everything. `--revert-docker-default`. Removes profiles of apps no longer in the manifest.
- `os-security/allowed.py` — the harvest: kernel `ALLOWED`/`DENIED` lines for our profiles → per profile/operation/object with counts and the rule that would allow each; exit 1 when non-empty. `--selftest`.
- `os-security/audit.sh` — 25 controls (route-aware MAC controls; `no-audit-lines-24h`), verdict open|partial|hardened, `--json`. `pol deploy audit <node>` runs it remotely.
- `os-security/escape-test.sh` — 14 cross-over attempts under a named profile, two passes (full / `--alone`), python image, time-limited, `--verbose` names the blocking error.
- `pol security os render|apply|audit|escape-test|allowed|revert [--scenario …]` (scenario auto-detected). `pol prod harden [--enforce|--dry-run] | harden report [--rules] | harden revert` for the server; `pol prod apply` still renders after deploy and applies only with `POL_PROD_HARDEN=on` (warn-only inside).
- Manifest stanza: `security: {profile, writable, network, capabilities, devices, ports}` in every `polari-app.json`; `conform` reports, never gates.
- Proxy: `pol-proxy/nginx.{lean,prod}.conf.template` hardened (ciphers, headers, rate limits, HSTS once public); `pol proxy guard`.
- Vault: `pol security vault …`, root-only, encrypted with a local identity; provider stash policy all/some/none.
- Verified live: polari-systems.org on the droplet (lean profile, Let's Encrypt). `pol prod verify` proves the four module routes.

## 4. The test loop — run after EVERY change, one piece at a time

```
# render + validate for the scenario in play (no root)
pol security os render --scenario swarm-lean            # or isle / swarm-full / dev
apparmor_parser -Q --skip-cache os-security/out/<scenario>/apparmor/*    # every profile parses
# what apply would do — warn-only shows [warn-only …] lines for the rings it will not touch
sudo pol security os apply --scenario <scenario> --dry-run
# the audit before and after (compare the two)
pol security os audit --scenario <scenario> --json > before.json ; … ; > after.json
# the escape test, only against a profile you loaded on purpose (complain mode still reports what WOULD be denied)
sudo pol security os escape-test --scenario <scenario> --profile isle-app-<name>
# the deployment still works
pol prod verify            # on the server: all four routes must still pass
pol modules health         # every answered module still online
```
Record each run's result in `AI-Notes/ledgers/TESTING_OWED.md` (a line per piece: date, machine role, before/after audit counts, verify result). If anything regresses, revert that one piece; never stack a second change on a broken one.

## 5. Gotchas that cost time this week

- The CA scripts exist twice: suite `ca/` and `polari-rf-node/ca/`; `pol prod` runs the rf-node copy. Patch both.
- A droplet update needs `git submodule update --init polari-cli polari-rf-node`, not just `git pull`.
- The core image bakes every module; optional modules fetched at runtime live on `/app/data/modules` (`POLARI_FETCHED_MODULES_DIR`); the resolver, the register's `downloaded` flag and the deb builder all look there. Core code must never import optional modules unconditionally (grep today; wants a lint).
- The privacy guard in `pol-hub/build-docs.py` refuses the literals in `.polari/privacy-denylist.txt` (gitignored). Keep it current; never spell those literals in tracked files.
- The isle's live working copy is isle-core's own; contract via `Isle-Mesh/NOTES-FROM-POL-CORE.md`. Its doors speak plain HTTP on the outside leg (reported, open).
- ugrep is `grep` on pol-core: `(a|b|)` empty alternatives fail; prefer fixed strings or `?`.
- `pkill -f <pattern>` with the pattern in your own command line kills your shell; use `ps | grep "[p]attern"`.
- Textual: a RadioButton mounted into an existing set never becomes its pressed button; rebuild the set. Visibility sync after a radio change must be deferred.

Added 2026-09-12 (sec-1a, Polari side — plan §13):
- **Explicit `deny` rules are enforced even in complain mode**, quietly. A "warn-only" profile must be an allow-list; the template is one now. Never add a `deny` line outside the enforce-only block of `app.j2`.
- **Swarm services cannot carry `security_opt`** (dropped by `docker stack deploy`). On the server the MAC ring = the node-wide `docker-default` profile (`mac_attach: docker-default`); per-app profiles exist only on the isle route. `pol security os revert` puts docker's stock profile back.
- **The parser's cache is keyed by basename**: loading a changed profile with the same file name can be skipped as "same as current profile" (a complain→enforce switch silently stayed complain). Always `apparmor_parser --skip-cache` (apply.sh does); check the mode in `aa-status` after loading.
- **The full escape test never consults AppArmor**: cap_drop/seccomp/read-only block everything first (14/14 with zero audit lines). Run `--alone` too; that is the profile's own score. Three probes need python3 in the image (default image is python:3.12-alpine now); the old busybox `nc -U` socket probe hangs forever.
- A `$(… | tail)` command substitution loses `PIPESTATUS`; capture the exit status before the pipe (escape-test does, via a temp file).
- Killing by a pattern over ssh: the remote shell's own command line contains every path you typed — `ps | grep "[p]attern" | xargs kill` still matched it through an unrelated argument and killed the session. Prefer killing by name/pid you recorded.
- ⛔ The droplet is off limits for this work (his rule 2026-09-12: "you should not be working in the droplet"; it accepts no ssh key from pol-core anyway). Test across pol-core, econ-core and isle-core via app deployments.
- docker's `--tmpfs` mounts are noexec: a probe that copies a binary under /tmp and executes it fails for that reason, not confinement.
- Under `attach_disconnected` a connect to a bind-mounted unix socket is reported as path "/" — the docker-socket probe is blocked by the implicit deny of "/", not by the `docker.sock` deny lines (those never matched anything in the log).

## 6. The first slices, in order (each one = change → §4 loop → record)

1. **sec-1a — Polari side DONE 2026-09-12 (branch dev-sec-1, plan §13). ⛔ HIS RULE (2026-09-12): do NOT work in the droplet. Test across pol-core, econ-core and isle-core via app deployments** — the home swarm is the server route's test bed (lean stack on the manager, the audit on every node), isle-core the isle route's. On the swarm manager, as root in the checkout:
   ```
   pol prod harden --dry-run      # what it would do: the node-wide docker-default (complain) + printed rings
   pol prod harden                # warn-only: loads it, audits; nothing is denied beyond stock docker
   pol prod verify                # all four routes still pass
   … a normal day of use …
   pol prod harden report --rules # what enforcing would break, per profile, with the rule for each
   pol prod harden revert         # docker's stock docker-default back, any time, no restart
   ```
   Then fix `templates/apparmor/app.j2` (or the fixed pieces' stanzas in the scenario) until the report is empty for a normal day. Expect python `__pycache__` writes into the image first (seen on the isle): the honest fix is `read_only: true` + tmpfs in the stack file (sec-1b-swarm), not a wider profile.
   Note there is NO per-service profile on the swarm route: the four services share the node-wide union profile; per-app confinement is the isle route's. Root: pol-core's sudo needs his password (dry-run and audit work without); isle-core has passwordless root over ssh; econ-core = `pol deploy grant`.
   Measured 2026-09-12 on isle-core (worker profile, python:3.12-alpine): the profile ALONE in enforce blocks 11/14 (socket, mount, sysrq, sysctl, module, ptrace, raw socket, userns, image write, chroot, firmware), cannot block reading a host bind (path rules cannot tell a bind from the image → D1 userns-remap) nor keyctl/bpf (seccomp's job); the full confinement blocks everything but BREAKS python on musl (the `worker` seccomp list is too tight: 5 probes "Error relocating python3") — so **sec-1c = seccomp in warn mode** (`defaultAction: SCMP_ACT_LOG` in complain, harvested from `type=1326` lines) before any seccomp list goes near the alpine-based backend.
2. **sec-1b-swarm, the app-surface ring in `docker-compose.lean.yml`** (`cap_drop: [ALL]` + declared `cap_add`, `read_only: true`, `tmpfs`, `deploy.resources.limits.pids` — the rendered `out/swarm-lean/compose/*.security.yml` fragments say exactly what): a production stack change → his go, then `pol prod apply` + `verify`. On the swarm this ring, not AppArmor, is what blocked 14/14 in the escape test.
3. **sec-1b-isle, the same warn-only apply on an isle** (isle-core's half: `isle app install` renders + loads complain profiles through the compose fragment's `security_opt`; contract in NOTES-FROM-POL-CORE.md — tell isle-core about the allow-list template and `--skip-cache`).
   **State at the end of 2026-09-12:** `pol deploy harden isle-core` has RUN warn-only (node-wide union in complain over the isle's 5 containers, 65 per-app profiles loaded in complain, seccomp staged, other rings printed; audit open 12/14). Next session: `pol deploy harden isle-core --report --rules` = the first real day of harvest; `pol deploy harden econ-core` and pol-core need his sudo (dry-runs pass). Revert any time: `pol deploy harden isle-core --revert`.
   **sec-1c seccomp warn mode is DONE** (SCMP_ACT_LOG in complain, `.enforce.json` twins, harvest by syscall name; the missing `open` found and added; python + nginx run under the enforce lists). Attaching a list still needs the per-container `security_opt` (isle) or the daemon's `seccomp-profile` (swarm, restart window).
4. **Only then** `--enforce` for the MAC ring on the server (`pol prod harden --enforce` = the one docker-default profile; there is no per-service order on swarm), verify after; on the isle one app profile at a time.
5. **Firewall ring** with `--enforce`, DOCKER-USER first (it cannot lock you out of ssh), ufw last and only with the ssh rule proven from a second session.
6. **Audit + escape test (both passes) into `pol prod verify`** and into the CI plan (rung 4). seccomp on the swarm = the daemon-wide `seccomp-profile` setting (render into daemon.json; diffed, applied in a window) — not yet rendered.
7. **Interfaces** (SECURITY_INTERFACES_PLAN sec-i-0/1 — BEGUN 2026-09-12 night, plan §13): the `security` module exists with the taxonomy rows, `SecurityControl` per system × scenario with provenance stock/qemu/polari, and the THREE SECURITY TOPOLOGY VIEWS (`/display/security-os|network|app`) as reach simulations (`/api/security/topology|simulate|compare`, modes stock|today|complain|enforce; selftest 19/19). Not yet booted in a container or seen in a browser; the drawing of `nodes`/`edges` is a frontend decision (D10). PLUS the threat simulations (`/display/security-threats`, panel `security-threat-sim` — the one new frontend component, his ask): 14 threats × scenario × mode with the blocking policy and the counterexample. Remaining: AppSecurityRecord, TrustChannel, ProxySnippet, HardwareTrial; `APPLIED_TODAY` fed by the audit; both unseen in a browser until the images are rebuilt.
8. Decisions for him before going further: hardening D1–D8 (D1 userns-remap matters more than thought: a path-based profile cannot tell a bind of the host's /etc from the image, so reading host files through a bind is DAC's to stop); interfaces D1–D9; §12's D9 (scope of an independent test).

## 7. Boundaries

No enforcement by default anywhere until §6 steps 1–2 have run clean. No new engines. No history rewrites. No publishing outward (images, releases, packages) without his go. Nothing about isle networking on pol-core beyond the notes file.
