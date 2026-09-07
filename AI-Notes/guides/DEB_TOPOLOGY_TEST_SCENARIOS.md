# Deb install / uninstall / topology test scenarios — three devices, by hand

**Date:** 2026-09-06 · **For:** Dustin, running every step himself.
**Devices:** isle-core (the CORE — `polari-complete 0.1.33` already
installed, core-install done, polari.isle up), econ-core (member
candidate; its own bundle build in `~/Desktop/polari-debs-2026-09-06/`),
pol-core (this dev box; the swarm is DOWN so it can join as a member).

Artifacts:
- isle-core `~/Desktop/polari-debs-2026-09-05/`: the pol-core-built bundle
  (`polari-complete_0.1.33_amd64.deb` + the four members) and
  `modules/` = eight module debs (techtree, gears, mathshapes,
  household, mealoptions, nutrition, vpn, cntfet).
- econ-core `~/Desktop/polari-debs-2026-09-06/`: the bundle BUILT ON
  econ-core (isle-mesh-cli, isle-app-store, polari-isle and the merged
  polari-complete were built there; the `polari-shell-core` runtime
  member came from pol-core's build because econ-core's JDK is a
  runtime-only install with no `javac` and I have no sudo there —
  `sudo apt install openjdk-21-jdk` makes it fully local) + the same
  `modules/` eight.
- Every module deb is STAGING ONLY by design (dl-4): dpkg puts the
  payload under `/var/lib/polari/apps/<module>/` with a manifest; the
  module goes live through the admit machinery. Today the backend
  container does not mount `/var/lib/polari`, so the deb-staged copy
  cannot be admitted from the container — the prf image already carries
  every module, so admission from the image is the live path. Scenario
  B5 tests exactly that honest gap.

How to call the isle's API from any isle device:
`curl -sk https://api.polari.isle/<path>` (on the core, add
`--resolve api.polari.isle:443:127.0.0.1` if `.isle` does not resolve
in that shell). POST: `curl -sk -X POST -H 'Content-Type: application/json'
-d '{}' https://api.polari.isle/<path>`.

Record each scenario as PASS / FAIL / FINDING with a one-line note; the
visualization checklist at the end is run after phases A, B and C.

---

## Phase A — platform debs: install, conflict, membership

**A1 — the core (isle-core) — DONE, record the baseline.**
1. `isle status`; `dpkg -l | grep -E 'polari|isle'` (expect only
   `polari-complete 0.1.33`); `sudo isle uninstall --verify` (expect it
   to REPORT what exists — not zero — that is correct while installed).
2. Browser on isle-core: `https://polari.isle` (frontend),
   `https://api.polari.isle/api/health`, `https://apt.isle` (the apt
   landing page with the bootstrap script + SHA), the Isle App Store
   window from the menu → it should open the store directly (agent
   running → no two-doors dialog).
Expected: all answer; the store lists `polari`, `whoami`, `polari-instance`,
`odoo` and the ten `isle-vpn` kinds (from the merged catalog).

**A2 — econ-core, deb install with NO isle (expected honest state).**
1. Double-click `~/Desktop/polari-debs-2026-09-06/polari-complete_0.1.33_amd64.deb`
   (or `sudo apt install ./polari-complete_0.1.33_amd64.deb`).
   Expected: installs; the log ends with the NOTE "installing apps from
   the store REQUIRES this device to be an isle core or member" and the
   two commands. No app opens by itself (a package cannot launch a GUI).
2. Menu → Isle App Store. Expected: the first-open dialog with THREE
   doors (Create my own isle / Join an existing isle / Just browse).
   Pick **Just browse**. Expected FAILURE STATE: the shell opens on an
   honest "unreachable" page (no isle yet). Close it.

**A3 — econ-core joins isle-core's isle as a HOSTING member.**
1. On isle-core get the join info again:
   `openssl x509 -in /etc/isle-mesh/ca/isle-root.crt -noout -fingerprint -sha256`
   and the core's isle IP (`hostname -I` — the 192.168.x address on the
   isle bridge; the JOIN INFO block core-install printed had it).
2. On econ-core, door 2 of the store ("Join an existing isle") shows
   the same instructions; run them in a terminal:
   ```
   curl -ko isle-bootstrap.sh https://apt.isle/isle-bootstrap.sh \
     || curl -ko isle-bootstrap.sh --resolve apt.isle:443:<CORE_IP> https://apt.isle/isle-bootstrap.sh
   sha256sum isle-bootstrap.sh            # compare with the SHA the core printed
   sudo bash isle-bootstrap.sh --fingerprint '<FP>' --core <CORE_IP> --host
   ```
   Expected: CA fingerprint verified → apt-on-mesh enabled → `isle
   onboard --host` → an `isle-remote-agent` container runs on econ-core.
   Expected FAILURE to try first: run the one-liner with a WRONG
   fingerprint (change one hex pair) → it must refuse before installing
   anything.
3. Verify on econ-core: `isle status`; `docker ps` shows the remote
   agent; `https://polari.isle` opens in the browser; the store opens
   directly now (agent = membership).
4. Verify on the core within ~2 min (the isle's push runs every 2 min):
   `https://polari.isle/display/isle-mesh` → Devices table gains
   econ-core (agent_present, connectivity_mode), Uplinks shows its
   interface with link_up. FINDING if it does not appear: note whether
   `/api/islemesh` counts changed.

**A4 — conflicting routes (expected dpkg failure).**
On econ-core (polari-complete installed):
`sudo apt install ./isle-app-store_0.1.33_all.deb` → Expected: apt/dpkg
REFUSES (polari-complete Conflicts/Provides the member names). Nothing
changes. Then the reverse question: `sudo apt remove polari-complete`
must remove everything it installed but keep the isle membership
config? Expected: the CLI + store go away (`isle` command gone), the
agent container keeps running (containers are not package files) — a
FINDING either way; write down what happened, then reinstall
polari-complete (the agent is still there, so the store opens
directly).

**A5 — pol-core joins as a REACH-ONLY member (third device).**
On pol-core (this box; swarm stacks are down): same one-liner as A3
WITHOUT `--host`. Expected: CA trusted, `.isle` names resolve, the
store deb installs and opens directly — but "Install on this device"
for a mesh-app is refused (no agent tier here), while polari apps
(launchers) install. Gotcha from memory: if pol-core's default route
moves to the isle uplink and internet breaks, fix with
`nmcli connection modify <isle-connection> ipv4.never-default yes` and
re-up the connection (split DNS handles names, not routes).
Check the core's `/display/isle-mesh`: three devices; pol-core with
`agent_present: false`.

---

## Phase B — modules: admission, requirements, put-away, the deb gap, mesh-apps, a second instance
All API calls go to the CORE's polari (`api.polari.isle`); run them from
isle-core unless stated.

**B1 — live admission from the image (SUCCESS).**
```
curl -sk -X POST -H 'Content-Type: application/json' -d '{}' https://api.polari.isle/modules/techtree/admit
curl -sk https://api.polari.isle/api/modules/status | python3 -m json.tool | grep -A3 techtree
```
Expected: `ok: true`, classes listed, `assignmentRow techtree@prf-isle
enabled`. Browser: `https://polari.isle/display/techtree` renders the
tech tree page; `https://polari.isle/topology` shows the prf-isle
instance with `techtree` assigned (the row is the authority).

**B2 — unmet requires (FAILURE, then the ordered fix).**
```
curl -sk -X POST -H 'Content-Type: application/json' -d '{}' https://api.polari.isle/modules/nutrition/admit
```
Expected: HTTP 409 naming the missing `household` and `mealoptions`
(honest refusal, nothing admitted). Then either `?withDeps=1` on the
same call, or admit `household`, then `mealoptions`, then `nutrition`.
Expected: three 200s; `https://polari.isle/display/nutrition`,
`/display/mealplan`, `/display/mealplan/household` render (the meal
planning pages seed on admission; `mealplan/household` has one known
raw panel — note if you see it).

**B3 — opt-in module (FAILURE).**
`POST /modules/testing/admit` → Expected: refused (opt-in packages
never ride a normal build). Note the exact sentence.

**B4 — put-away and bring-back.**
```
curl -sk https://api.polari.isle/TechNode | head -c 200        # rows
curl -sk -X POST -H 'Content-Type: application/json' -d '{}' https://api.polari.isle/modules/techtree/put-away
curl -sk -i https://api.polari.isle/TechNode | head -5          # expect 410 Gone + a bring-back hint
curl -sk -X POST -H 'Content-Type: application/json' -d '{}' https://api.polari.isle/modules/techtree/admit
curl -sk https://api.polari.isle/TechNode | head -c 200         # same rows back
```
Expected: 200 / 410 with hint / 200 / identical rows. `/topology`
shows the assignment flipping disabled → enabled.

**B5 — the module DEB route (EXPECTED HONEST GAP today).**
On isle-core:
```
sudo apt install ~/Desktop/polari-debs-2026-09-05/modules/polari-app-vpn_*.deb
cat /var/lib/polari/apps/vpn/manifest.json | head -30      # says: staged, goes live through admit
isle module install vpn
```
Expected: dpkg installs the payload; `isle module install vpn` finds no
`polari-module-vpn` apt package, falls back to the topology assign and
prints "assigned … redeploy to load" — the module is NOT live (the
container cannot see `/var/lib/polari`). That is the gap the release
pipeline / core-only server must close; record it as a FINDING with the
exact message. Then take the live path instead:
```
curl -sk -X POST -H 'Content-Type: application/json' -d '{}' https://api.polari.isle/modules/vpn/admit
curl -sk -X POST -H 'Content-Type: application/json' -d '{}' https://api.polari.isle/api/vpn/demo | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['all_pass'], [s['step'] for s in d['steps'] if not s['pass']])"
```
Expected: admit 200 (vpn requires islemesh, which prf-isle already
runs); demo `True []`. Browser: `/display/vpn` (mock banner, ten kinds,
Blind / Sees traffic, three isles), `/display/isle-mesh` matrix now has
a `.vpn` column with `whoami.vpn`. Then `sudo apt remove polari-app-vpn`
→ Expected: payload dir gone, the module stays online (the deb was a
staging copy only) — write that down too.

**B6 — fetch-admit refusals (FAILURES by design).**
```
curl -sk -X POST -H 'Content-Type: application/json' -d '{"sourceKind":"peer","sourceRef":"http://isle-core:3000"}' https://api.polari.isle/modules/gears/fetch-admit
curl -sk -X POST -H 'Content-Type: application/json' -d '{}' https://api.polari.isle/modules/vpn/fetch-admit
```
Expected: the first refuses peer CODE ("modules travel as data
bundles, not code"); the second either no-ops (vpn already admitted)
or refuses because vpn has no repo yet (`repo: ''` — not published).
Both must be sentences, never a traceback.

**B7 — a mesh-app from the store on the hosting member (econ-core).**
On econ-core: `isle store list` → `isle store show whoami` (the
install plan) → `isle store install whoami` (confirm). Expected:
`https://whoami.isle` answers from any isle device; within 2 min the
core's `/display/isle-mesh` shows the app on econ-core with its
protocol permit in the matrix, and the store page (`/isle-store`)
counts one running instance of `whoami` on econ-core. Then
`isle store uninstall whoami` → the row disappears on the next push.
FAILURE to try: `isle store install whoami` on pol-core (reach-only
member) → must refuse (no agent tier) with the sentence saying so.

**B8 — a second polari instance on the member (econ-core).**
`isle polari instance deploy --modules techtree` → Expected: a new
instance (`polari-2`) behind econ-core's agent at
`https://polari-2.isle` (prf images are already loaded on econ-core?
NO — econ-core has none; expected FAILURE/honest message: the verb
tries the mesh registry `registry.isle:5000`, which is not set up on
this isle → note the exact refusal). If you want the success half, run
on isle-core first `bash /usr/share/isle-mesh/isle-cli/scripts/isle-registry-setup.sh`
then `docker tag prf-backend:staging registry.isle:5000/prf-backend:staging && docker push …`
(same for frontend), then retry on econ-core. `isle polari instances`
and `/topology` then show two instances; `isle polari instance undeploy polari-2` cleans up.

---

## Phase C — uninstall and topology teardown

**C1 — a member leaves (pol-core).** `sudo isle uninstall` (member
mode). Expected: CLI + store removed, trust entries removed, `.isle`
no longer resolves; `sudo isle uninstall --verify` zero. On the core's
`/display/isle-mesh` the device row stays until retired — retire it
from the core with `pol isle retire pol-core` (on pol-core after
reinstalling the CLI, or via `POST /api/islemesh/ingest/device
{"device":"pol-core","retire":true}`) → row + attributed rows gone,
receipts kept. FINDING if the row vanished on its own (say how).

**C2 — the core cascade (isle-core), then the round trip.**
On isle-core: `sudo isle uninstall --everything` (type the confirmation
it asks for). Expected: backups written, router VM destroyed, agent +
polari containers removed, volumes backed up + removed, packages
purged; econ-core's `isle-watch` receives ISLE-ENDING and its agent
stops (`docker ps` on econ-core; `isle status`). Then on both:
`sudo isle uninstall --verify` → zero footprint (delete the dangling
`~/Desktop/isle-app-store.desktop` link by hand — the uninstall does
not sweep home directories). Then reinstall on isle-core from the
desktop deb and rerun A1 → identical result = the round trip holds.

---

## Visualization checklist (run after each phase, on https://polari.isle)
| Page | What must make sense |
|---|---|
| `/display/isle-mesh` | device count = joined devices; uplinks with link_up; apps per device; permits = one row per served name; receipts grow with each push; the matrix has the `.vpn` column after B5 |
| `/isle-mesh` (the console) | the D3 topology: devices as groups, the agent at each device's edge, exposures outside the containment line, the inferred L2 segment once two devices share carrier |
| `/topology` and `/topology/databases` | instances (prf-isle, + polari-2 after B8), assignments flipping with admit/put-away, the drift report naming unobserved instances honestly |
| `/isle-store` | catalog entries with instance counts per device; the ten isle-vpn kinds with Blind / Sees traffic; the install plan text per entry |
| `/downloads` | the bundle with version + date; the on-demand app debs list with honest wait estimates |
| `/apps` | 19 apps in the nav, gating readable (modules not admitted show as such) |
| `/display/vpn` | mock banner, three isles, the proposals inbox; the forms refuse honestly (try a duplicate network) |
| `/display/techtree`, `/display/nutrition`, `/display/mealplan/*` | render after their admissions; no raw JSON anywhere |

What to send back: the PASS/FAIL/FINDING list with the exact sentences
for every refusal, and screenshots of any page where the picture does
not match the checklist row.

---

## Phase B addendum — online vs offline module debs (B9, added 2026-09-06)

Both desktops' `modules/` folders now also hold two OFFLINE-flavor debs:
`polari-app-techtree-offline_*.deb` (techtree has no pip dependencies,
so it carries no wheels — the flavor is the only difference) and
`polari-app-vpn-offline_*.deb` (4.4 MB: the `cryptography` wheels ride
inside under `wheels/`). Online and offline share the version
(`0.1.0+g<content-hash>`); the offline package `Provides`, `Conflicts`
and `Replaces` the online name.

**B9a — online flavor first, then offline (expected dpkg conflict).**
On econ-core (no internet needed for either step, but note which box):
```
sudo apt install ./modules/polari-app-vpn_*.deb          # online flavor
cat /var/lib/polari/apps/vpn/manifest.json | python3 -m json.tool | head -40
```
Expected: the manifest lists the pip libraries that would install
DYNAMICALLY at admission (with sizes) and names any system engine.
Then:
```
sudo apt install ./modules/polari-app-vpn-offline_*.deb
```
Expected: dpkg REPLACES the online package (Replaces/Conflicts) — the
online one is gone from `dpkg -l`, the payload now has `wheels/`
(`ls /var/lib/polari/apps/vpn/wheels`). Then try the reverse order on
isle-core (offline first, then online) → Expected: apt refuses the online
one while offline is installed, or replaces it — record which; both are
"never both at once", which is the rule.

**B9b — same content, same version.** `dpkg-deb --info` on both vpn
flavors: the Version strings differ only because the flavor is folded
into the content hash; techtree's two files differ by name and flavor
field only. A rebuilt deb from unchanged content must reproduce the
same file name (byte-deterministic) — FINDING if a rebuild changes it.

**B9c — where offline matters (FINDING to note, not a step):** the
offline flavor only pays off once admission can install wheels from
the staged payload; today (B5) the payload is not reachable from the
container, so both flavors stage equally. That is the ver-3 / prd-3b
seam.

---

## Phase D — OFFLINE base install on econ-core + an offline app (2026-09-07)

**What is on econ-core:** `~/Desktop/polari-offline-2026.09.07/` = the
whole offline medium (`offline-build/2026.09.07-dev+6f94a3e` on pol-core,
2.0 GB; template `AI-Notes/guides/OFFLINE_BUILD_TEMPLATE.md`): debs/ (the
`polari-complete-offline` deb), apt/ (the Ubuntu 22.04 closure incl.
docker, 421 debs, already preflighted in a network-less container),
images/ (prf-backend, prf-frontend, nginx:alpine, python:3.11-slim,
the sample app), modules/ (household, reticulum, techtree, vpn offline
debs), engines/ (the Reticulum sidecar), scripts/. router/ and
hardware/ are EMPTY on purpose (no libvirt on econ-core → routerless
single-device isle, same as isle-core today).

**D0 — clean start.** econ-core has no polari packages (verified
2026-09-07). Keep Odoo running; it is untouched.

**D1 — cut the internet, arm the proof.** Disconnect econ-core's
uplink the way you want to test (wifi off is the strict version; the
"roommates' LAN, no WAN" version = unplug the router's WAN or block
econ-core at the router). Then:
```
cd ~/Desktop/polari-offline-2026.09.07
sudo bash scripts/offproof.sh start        # nft counters + pcap; drops + counts any public-address egress or DNS
```

**D2 — install the platform from the medium.**
```
sudo bash scripts/install-offline.sh
```
Expected: verify → `/etc/polari/install-mode=offline` → distro closure
from `apt/` via a `file:` source (only socat + dpkg-dev/avahi/gnupg on
econ-core; docker is already there) → 5 images docker-loaded →
`polari-complete-offline 0.1.33` installed (its postinst prints the
offline notice). No prompt should mention a URL.

**D3 — create the isle like a normal user.** Menu → Isle App Store →
"Create my own isle" (or `sudo isle core-install`). Expected: the
create step says `offline install-mode: no libvirt — continuing WITHOUT
the router`, the sample app starts `from the offline medium's image (no
build)`, prf-isle comes up with the loaded images, `https://polari.isle`
answers, the store lists apps. FAILURE BY DESIGN to look for: nothing
may print "pulling"/"Downloading"; if any step does, it is a network
touch the gate missed — note the step name.

**D4 — the household app, offline.**
```
sudo bash scripts/install-app-offline.sh household
```
Expected: deb staged under `/var/lib/polari/apps/household` (manifest
says flavor offline, no wheels — household has no pip deps), then admit
200 from the running image; `/display/household` renders on polari.isle.
Negative: `sudo bash scripts/install-app-offline.sh gears` → refused
"not on the medium (section modules/)", nothing fetched.

**D5 — the proof.**
```
sudo bash scripts/offproof.sh report      # verdict line: CLEAN — zero packets
sudo bash scripts/offproof.sh stop
```
Paste the report (`/var/log/polari-offline-proof.txt`) into TESTING_OWED
§16. A DIRTY verdict is a finding, not a failure of the test: the
counter names the packets, and the step that caused them is the gap.

## Phase E — the Reticulum app on isle-core, a second isle on pol-core, and the archipelago over wifi (2026-09-07)

Context: an archipelago = a set of Reticulum nodes whose measured path
is internet-like (plan §5c-b); this phase measures the first real pair.
Both isles are routerless; the bearer is the Reticulum TCP interface on
port 4242 over the house wifi/LAN (192.168.0.x) — "two roommates sharing
a connection". Kit on both boxes: `engines/reticulum/` (sidecar image +
`reticulum-isle.yml` + enable/peer/status helpers) and the
`polari-app-reticulum-offline` deb (on isle-core:
`~/Desktop/polari-reticulum-2026-09-07/`; on pol-core:
`~/Desktop/polari-debs-2026-09-07/`).

**E1 — isle-core: the reticulum app via deb.**
```
cd ~/Desktop/polari-reticulum-2026-09-07
sudo dpkg -i polari-app-reticulum-offline_*.deb        # stages /var/lib/polari/apps/reticulum
sudo bash engines/reticulum/reticulum-enable.sh        # loads the sidecar image, runs it on isle-agent-net, RETICULUM_URL into prf-isle, reticulum into the boot set
bash engines/reticulum/reticulum-status.sh
```
Expected: sidecar identity + interfaces `Auto Discovery` and `TCP
Server` ONLINE; backend capability ok with the licence pins
(rns 0.9.4 / lxmf 0.6.3); `/display/reticulum` renders. Note the boot
takes the lean isle down ~1 min (backend re-up with the module in
POLARI_ISLE_MODULES).

**E2 — pol-core: a separate isle.** Install
`~/Desktop/polari-debs-2026-09-07/polari-complete_0.1.33_amd64.deb`
(online flavor is fine here) → store → "Create my own isle" (routerless,
like isle-core). Then the same E1 steps from `~/Desktop/polari-debs-2026-09-07/`
(`sudo dpkg -i modules/polari-app-reticulum-offline_*.deb`, then
`engines/reticulum/reticulum-enable.sh`). ⚠ pol-core also hosts the
staging swarm; keep it down during this phase (`pol swarm down` /
`docker service ls` empty) — both use the prf images and ports.

**E3 — link the isles (the archipelago bearer).**
```
# on pol-core (dials isle-core; use isle-core's LAN address)
bash engines/reticulum/reticulum-peer.sh <isle-core-ip>
# on isle-core, once, so it announces after the link exists
docker restart pol-reticulum && sleep 8 && bash engines/reticulum/reticulum-status.sh
# on pol-core
bash engines/reticulum/reticulum-status.sh
```
Expected: each side's `peersHeard` lists the other's destination
(announce count ≥ 1), interface `Isle <ip>` ONLINE on pol-core.
`/api/reticulum/peers` on each backend shows the sighting as
`unadjudicated` — HEARING IS NOT ADMITTING.

**E4 — a real exchange (ret-7 messages).** On isle-core take the
delivery hash from `reticulum-status.sh` (`lxmf facts`). On pol-core:
```
curl -sk --resolve api.polari.isle:443:127.0.0.1 -X POST -H 'Content-Type: application/json' \
  -d '{"destinationHash":"<isle-core delivery hash>","content":"hello from pol-core","title":"arch test"}' \
  https://api.polari.isle/api/reticulum/messages
```
then on isle-core `reticulum-status.sh` → the message is listed with a
receive time. Send one back. Record the round trip (send time → listed
time on the far side) and `ping <other-ip>` RTT: those two numbers are
the FIRST archipelago floor measurement (plan §5c-b, knob `max_rtt_ms`
default 150 — set it from what you see).

**E5 — what will NOT work yet (expected, write it down):**
- `.arch` naming: `POST /api/reticulum/peers/<name>/adjudicate` needs a
  Keycloak-verified caller; the lean isle has no Keycloak → 401. The
  archipelago rows (`ArchipelagoNode`) therefore stay empty on the lean
  tier; `/api/reticulum/resolve/<name>.arch` refuses by name. Gap = the
  lean tier needs a local-operator identity (the same gap vpn-3 noted).
- Direct website access over `.arch` (his definition) needs ret-5
  (HTTP/2 over Reticulum); today the proof of the bearer is LXMF.
- The `.mesh`-conversion / relay suggestion is ret-10 (not built).

**E6 — teardown order:** `docker compose -p pol-reticulum -f engines/reticulum/reticulum-isle.yml down`
on both (keep `-v` off to keep identities), then the usual
`isle uninstall` per box; econ-core: `offproof.sh stop` before uninstall.
