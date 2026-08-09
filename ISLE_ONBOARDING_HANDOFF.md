# Handoff — smooth from-scratch install flows (the §33 goal)

**Date:** 2026-08-09 · **From:** the mesh-app convergence sessions.
This is the plan for the remaining significant arc: two SMOOTH,
one-flow installers. Everything they orchestrate is already built +
proven (see "What exists"); the arc is wiring it into two polished
flows + the one genuinely-hard tier (a remote HOSTING apps).

Read `MESH_APP_CONVERGENCE_HANDOFF.md` §17–§39 for the full trail.

---

## 1. THE GOAL (Dustin, verbatim, §33)

Two from-scratch install flows, each ONE smooth process:

- **Core install**: one flow stands up the isle app store + a
  bare-bones polari (topology + isle-topology pages) + the polari
  app store — a working core out of the box.
- **Remote install**: one flow connects a device to that mesh AND
  gives it a shell app store, from which the user installs whatever
  else the device needs. Smooth + efficient.

Framing (Dustin, §32): the ISLE app store is the GENUINE store; the
polari app store projects in when a polari instance is available.
Installing the store shell ALWAYS brings up an agent so the device
can host, not just reach.

---

## 2. WHAT EXISTS (all built + proven — the installers just wire it)

- **prf-isle**: lean polari ON isle-core, served ONLY via the isle
  agent (`polari.isle`/`api.polari.isle`), self-feeding topology
  (systemd timer). `~/polari-isle/` compose + isle-polari-deploy /
  isle-polari-teardown. (§17, §27)
- **The store**: `IsleCatalogEntry` + install plans + `/api/islemesh/
  catalog`; **`/isle`** tabbed hub (App store + Topology);
  `isle store list|show|install` (host runs the plan). §24, §32.
- **Native shells (§21/§22)**: `polari-shell-core` deb = ONE ~177MB
  runtime; 4KB per-app launcher debs; the **JavaFX store shell**
  with a pkexec install bridge (§31). Icons: CC0 island (store) +
  polari mark (apps) in `polari-app-shell/shells/icons/`.
- **The CLI**: `isle-mesh-cli` deb (packages /usr/share/isle-mesh +
  the `isle` command). Verbs: trust, agent (+ensure), certs, store,
  shell, module, **onboard** (MVP, this handoff), app deploy.
- **Certs (§18/§19)**: isle CA; join-time `isle trust fetch`;
  signed-channel auto-update; per-domain leaf issuance at register.
- **Registry (§28)**: mesh-local docker registry (`registry.isle`)
  — offline-complete image supply + the dev-loop accelerator.
- **Dev loop (§29)**: `pol dev setup|deploy|teardown|status`.
- **Multi-device (§30)**: reach PROVEN on all 3 (pol/isle/econ
  resolve .isle + reach polari/odoo); real 3-device topology.

## 2b. PROVEN vs the boundary (§34, §39)

- ✅ FULL install chain proven on a MEMBER (isle-core): dpkg core →
  apt store (agent up) → `isle store install polari` (native
  launcher) → `isle store install whoami` (mesh-app deployed).
- ✅ On a REMOTE (pol-core): store opens clean, tabs, pkexec
  password prompt, catalog load — the desktop store EXPERIENCE.
- ⛔ Installing ONTO a remote needs it onboarded as a HOST first —
  the gap these installers close.

---

## 3. THE ONBOARDING TIERS (what a device needs, easy→hard)

`isle onboard` (MVP shipped, `isle-cli/scripts/onboard.sh`) already
does tiers 1–4; tier 5 is the hard one.

1. **Trust** — `isle trust install` (CA → system + browser NSS). ✅
2. **Reach** — .isle resolves + `api.polari.isle` answers. ✅
   (proven on all devices; onboard verifies it)
3. **Register** — POST device facts → shows in topology. ✅
4. **Native-app install** — `isle store install <polari-app>`
   builds+installs a launcher here. ✅ *once the fixes below land*.
5. **HOST** (`--host`) — bring up a LOCAL agent so the device runs
   containers (mesh-apps). ⛔ THE HARD TIER — needs the isle
   remote-agent + macvlan + router join. Best-effort `isle agent
   ensure` today; real remote hosting = `isle create`/`isle join`
   territory (isle-core's networking domain).

---

## 4. KNOWN FIXES NEEDED (found during §34–§39 testing)

Small, concrete — do these first; they make tier-4 actually work:

1. **pkexec runs as ROOT** → `$HOME` is `/root`. shell.sh's
   `POLARI_SHELL_STAGE` defaults to `~/polari-shells` (empty for
   root). FIX: default to a SYSTEM path
   (`/usr/share/isle-mesh/shells/debs`), and `isle onboard` stages
   the `polari-shell-core` deb there. (Not needed if core is
   already dpkg-installed — `ensure_core` returns early — but stage
   it for the fresh-device case.)
2. **Launcher icons**: `build-launcher-deb.sh` reads
   `$ROOT/shells/icons/polari-mark.png`. Put the icons in the CLI
   deb at `/usr/share/isle-mesh/shells/icons/` (dir created on
   isle-core; COPY polari-app-shell/shells/icons/*.png there and
   rebuild the CLI deb). Currently falls back to
   `applications-internet` — works, just not branded.
3. **store.sh catalog fetch**: FIXED (§39) — was hardcoded
   `--resolve 127.0.0.1`; now system DNS + localhost fallback. CLI
   deb v0.1.1 staged. Ship into the CLI deb going forward.
4. **store postinst CA path** (§34): `isle trust install` in the
   store deb postinst looked at the wrong CA path — didn't take.
   `isle onboard` does trust correctly; fold that in or fix the
   path (`/usr/share/isle-app-store/isle-root.crt`).

## 4b. Shell-config lessons (baked into the builders — keep)

- ShellConfig for a mesh WEB VIEW: `instanceId=""` +
  `probeUrl=<page url>` (a 200) → reachable, no false verdict.
  Blank probeUrl → false "instance-down"; an appstore-identity URL
  on a non-appstore instance → false "wrong-instance". (§36–§38)
- Registry merge REFRESHES a same-URL entry (core ≥0.1.4) so config
  changes take; a launcher opens ITS OWN config's instance, not the
  registry's last-used. (§36)

---

## 5. THE TWO INSTALLERS TO BUILD (the deliverable)

### 5a. Core installer (`isle core-install` or a top-level script)
One flow on a fresh core box → a working isle core:
1. `isle create` (router VM + agent + bridges + boot persistence —
   isle's existing setup; see isle-bringup-mac2.sh / §14).
2. Issue the isle CA + trust it locally (`isle trust`).
3. Deploy prf-isle LEAN (islemesh module → topology + isle-topology
   pages + the store) via `isle-polari-deploy` (§27); register
   polari.isle/api.polari.isle + leaves + DNS.
4. Install the isle-app-store shell locally + stage the shell debs.
5. Verify: `https://polari.isle/isle` answers; store lists; agent
   up. Output the CA fingerprint + a join token for remotes.
Idempotent; every step already exists as a verb — this SEQUENCES
them + adds the "output join info" bit.

### 5b. Remote installer (`isle join <core>` → onboard)
One flow on a fresh remote → a mesh member with a store:
1. Reach the core (cable/wifi to the isle); get its CA fingerprint
   (out-of-band or via the join token) → `isle trust fetch
   --fingerprint <fp>`.
2. Install `isle-mesh-cli` + `polari-shell-core` + the
   `isle-app-store` shell (the store's Depends pull these; or the
   join script apt-installs from a mesh-served apt repo — see the
   apt-on-mesh gap, §10 #8-adjacent).
3. `isle onboard` (tiers 1–4) → trust, reach, register, native-app
   path staged.
4. `isle onboard --host` (tier 5, optional) → `isle join` the isle
   so the remote can HOST: remote-agent attach (macvlan/DHCP from
   the router), isle-agent-net, so `isle store install <mesh-app>`
   deploys locally. THIS is the hard, isle-networking part.
5. Open "Isle App Store" → install whatever the device needs.

**Distribution**: both installers want the mesh apt repo +
appstore serving the debs (isle-mesh-cli, polari-shell-core,
isle-app-store) so a remote pulls them over the isle, offline. The
registry (§28) is the docker half; an **apt-on-mesh** (signed, at a
.isle URL, MinIO-served) is the deb half — build it as part of 5b.

---

## 6. CONCRETE NEXT STEPS (order)

1. Land the §4 fixes (stage core deb + icons system-wide in the CLI
   deb; fold store.sh fix + onboard-trust into the CLI deb). Rebuild
   `isle-mesh-cli` (bump version).
2. Prove tier-4 END TO END: on a member, `isle store install polari`
   builds+installs the launcher via pkexec-as-root (the fixes make
   the root-home + icons work). Then from the STORE UI button.
3. Build 5b's tier-5 (the hard part) WITH isle-core's networking
   knowledge: remote-agent join so a remote hosts. This is where an
   isle-core-savvy session (or its Claude) is most valuable —
   macvlan/DHCP/router-join is its domain.
4. Build the apt-on-mesh repo so remotes pull the debs offline.
5. Wrap 5a + 5b as the two smooth top-level flows; test on econ-core
   (a real fresh-ish remote) end to end.

## 7. GOTCHAS / RULES (carry forward)

- isle-core has passwordless sudo for this work; pol-core/econ-core
  need Dustin's password (or a grant) — a fresh remote's onboarding
  therefore needs an interactive sudo (that's fine — it's a user
  install).
- Remote heredoc quoting bites: write scripts locally, `scp`, don't
  inline-patch quotes over SSH.
- The installed CLI lives at `/usr/share/isle-mesh` (deb copy) —
  repo edits need a sync + CLI-deb rebuild to reach devices.
- macvlan host-isolation: a host can't reach its own agent's
  macvlan IP → the 127.0.0.1 fallback in store.sh matters.
- GUI verification (window opens, icon shows, click Install) is
  Dustin's — no display access on remote machines.
- Keep the isle CA import an honest ask: consider the dedicated
  NAME-CONSTRAINED isle root (§18) before wide distribution.
