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

- `os-security/scenarios/{isle,swarm-lean,swarm-full,dev}.yml` — **all `mode: complain` now.**
- `os-security/render.py` — validates the stanza vocabulary, renders AppArmor per app (`templates/apparmor/app.j2`), seccomp per kind, DOCKER-USER, ufw, daemon.json, sysctl, systemd hardening, perms, audit rules → `out/<scenario>/` + `manifest.json`. `--apps-from-manifests` or `--apps-from-core URL` (only online modules).
- `os-security/apply.sh` — **warn-only by default**: profiles load in complain (`-C`); the rings that cannot warn (DOCKER-USER, ufw, sysctl, perms, daemon.json) are only printed unless `--enforce`. `--dry-run` prints everything. Removes profiles of apps no longer in the manifest.
- `os-security/audit.sh` — 24 controls, verdict open|partial|hardened, `--json`. `pol deploy audit <node>` runs it remotely.
- `os-security/escape-test.sh` — 14 cross-over attempts under a named profile.
- `pol security os render|apply|audit|escape-test [--scenario …]` (scenario auto-detected). `pol prod apply` renders after deploy; applies only with `POL_PROD_HARDEN=on` (still warn-only inside).
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

## 6. The first slices, in order (each one = change → §4 loop → record)

1. **sec-1a, server:** `pol prod apply` renders the swarm scenario (it does) and applies it warn-only on the droplet: AppArmor profiles in complain for the four services, firewall rings printed only. Then read `dmesg`/`journalctl` for `ALLOWED` audit lines over a day: that is the list of what enforcing would break. Fix the templates until the list is empty for a normal day of use.
2. **sec-1b, the same on an isle** (isle-core's half: `isle app install` renders + loads complain profiles; contract in NOTES-FROM-POL-CORE.md).
3. **Only then** `--enforce` for the MAC ring on the server, one service at a time (backend first; frontend; hub; proxy), verify after each.
4. **Firewall ring** with `--enforce`, DOCKER-USER first (it cannot lock you out of ssh), ufw last and only with the ssh rule proven from a second session.
5. **Audit + escape test into `pol prod verify`** and into the CI plan (rung 4).
6. **Interfaces** (SECURITY_INTERFACES_PLAN sec-i-0): the `security` module, taxonomy, AppSecurityRecord ledger, the three screens — read-only first.
7. Decisions for him before going further: hardening D1–D8; interfaces D1–D9; §12's D9 (scope of an independent test).

## 7. Boundaries

No enforcement by default anywhere until §6 steps 1–2 have run clean. No new engines. No history rewrites. No publishing outward (images, releases, packages) without his go. Nothing about isle networking on pol-core beyond the notes file.
