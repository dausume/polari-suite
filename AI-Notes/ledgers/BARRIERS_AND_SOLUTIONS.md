# Barriers and solutions — the running ledger (started 2026-10-04)

One row per barrier actually hit. Columns: what blocked, the root cause once found (not the first guess), what was
done, and the durable form it must take (the owner in brackets). "Wrapped" = available through a `pol` verb /
topology row for the average person; "hand" = applied by hand this once (a DEBT until wrapped).

## A. Devices and networking

| # | barrier | root cause | done | durable form |
|---|---|---|---|---|
| A1 | isle-core swarm worker shows Down (`heartbeat failure`); engine URLs through the manager refuse | the manager's ADVERTISED address (`docker info .Swarm.NodeAddr`) was frozen at `swarm init` time on DHCP .210; pol-core's lease moved to .212; the worker dials .210 → "no route to host". Two wrong guesses first ("ufw blocks the ports" — ufw on pol-core is INACTIVE) | hand: `ip addr add 192.168.0.210/24` + NM `+ipv4.addresses`; `pol swarm ports` now reports `advertise … DRIFTED` with both remedies | tnb-0 finding `advertise-address-drift`; rule: a swarm manager (and the nip.io proxy) need a STABLE address — static primary + router reservation [him + tnb] |
| A2 | control plane up, mesh "Peers" complete, yet a published port via the manager hangs | VXLAN frames left pol-core from .212 (the kernel route's `src`) while isle-core's overlay fdb pins pol-core's VTEP at .210 → kernel drop reason `VXLAN_ENTRY_EXISTS` (bpftrace on isle-core). The `nc -zu` UDP probe cannot see a DROP | hand: `ip route change 192.168.0.0/24 … src 192.168.0.210 metric 600` (the metric must match or "No such file or directory"); mesh proven both ways; `pol swarm ports` data-plane test added | tnb-0 findings `route-source-mismatch` + `address-not-stable`; NOT persistent (NM restores src) [tnb] |
| A3 | the nip.io URLs 503 "Proxy host mismatch" | the proxy config carries the LAN address at render time; it moved | re-render by `pol swarm deploy node` (and A1 made the old address valid again); `lan_ip()` now prefers the swarm advertise address | same stable-address rule [tnb] |
| A4 | the backend task landed on isle-core and died on missing bind mounts | the node stack had no placement constraint; adding a worker let the scheduler move it | hand: `--constraint-add` ×6, then IN THE COMPOSE: `node.labels.polari.machine == ${POLARI_MACHINE}` on all node + suite services | wrapped (compose + render) ✅ |
| A5 | the backend could not reach the isle-core engines | no engine URL in the stack; the topology URL builder uses the manager address (dead until A2) | hand: `BOARD/ESP/FORMAL/PCB_ENGINES_URL` exported before the render (compose reads `${VAR:-}`) | rows resolve the URLs through the mesh, or the render writes them from rows — never a shell export [tnb-0] |
| A6 | `pol topology modules-env` missed `grpcbridge` | the requires-closure was computed by the RUNNING (old) backend from the manifests in ITS image | `pol topology assign grpcbridge prf-a` by hand; then the CLI unions the CHECKOUT's manifests and warns per unknown module | wrapped ✅ |
| A7 | `pol swarm deploy hw-engines` did not exist; `pcb-engines` ran ad hoc on the same port | role table lacked it; the worker predated the stack | `hw-engines` role (+ pcb-engines service, pinned to isle-core); the ad-hoc container removed by hand | wrapped; `pol swarm deploy` should offer to retire a same-port ad-hoc container [owed] |
| A8 | the twins cannot run on a remote worker | a twin is a long-lived TCP port on the device, not a `/run` request | by design; twins run on pol-core's local image | a remote-twin verb (start a twin ON isle-core and attach) [owed] |

## B. Pipeline

| # | barrier | root cause | done | durable form |
|---|---|---|---|---|
| B1 | `polari-test` FAILED on the merge: core suite | pcb-0 never added `pcb` to `moduleService/app_taxonomy.DEFAULTS` | fixed | the module scaffold adds the taxonomy entry [owed: `pol modules new`] |
| B2 | the isle stage: `isle create failed` at ~50 s | Isle-Mesh's router init apt-installs `yad sshpass` (and avahi) ON THE FLY; the throwaway guest's `unattended-upgrades` held the dpkg lock. Pre-existing flake (seen 2026-09-20) | bake masks apt timers; a lock wait before core-install; the three packages BAKED into the base (`CI_ISLE_PREREQ_PKGS`) so the isle script never calls apt | isle side: `apt-get -o DPkg::Lock::Timeout=300` [isle-core's owner]; verdict of the third run pending |
| B3 | the bake fix did not run on the second attempt | the prepared base is cached on the ssh TARGET (isle-core), not on econ-core — `cache.sh dir cloud` printed a local, unused path; the bake key ignored bake-logic changes | stale base deleted on isle-core by hand; `BAKE_FORMAT` folded into the key; `cache.sh` resolves the remote location; doctor shows the prepared base | wrapped ✅ |
| B4 | `pol jenkins promote test` stops on "tree not clean" | untracked build artefacts (`desktop/bin/`, `__pycache__/`, `board-home/` written by probes run from the framework dir) | `.gitignore` lines in four repos | probes must default to `~/.cache/polari-board` even when run from the framework dir [owed] |
| B5 | `pol modules selftest firmwarefaults` crashes IN-CONTAINER | `parents[3]`-up path to `prf-board-engines` sources does not exist in the image | honest SKIP naming the path; host run unchanged (190/190) | rule: a selftest never assumes the rf-node tree; it names what it skipped ✅ |
| B6 | a verify check printed PASS over a Traceback | exit code trusted, body ignored | the store check fails on a Traceback body | audit the other verify checks for the same [owed] |

## C. Data and code

| # | barrier | root cause | done | durable form |
|---|---|---|---|---|
| C1 | three firmwarefaults classes never persisted | column names `where`, `order`, `check` are SQLite reserved words; `makeSQLiteTable` does not quote identifiers | renamed to site/position/check_name; 25 more such columns found across modules (TESTING_OWED §79) | quote identifiers ONCE in the shared DB layer [his decision] |
| C2 | `pol pcb ingest <path> --api` fails against the staging container | the server opens the host path; the image has no bind mount | module-relative paths sent; others refused | an upload path [owed] |
| C3 | the pcb provenance file never committed | `modules/pcb/.gitignore` lacked the per-file exemption `board` has (`*.json` ignored) | regenerated with provenance; exemption added | module scaffold ships the exemption [owed] |
| C4 | a liveboot probe counted 3 bindings instead of 2 | not a duplicate-row bug: hwnocode's seed legitimately adds a binding on every boot | the probe counts only its own pair | ✅ |
| C6 | the new readiness tables showed `JSON Parse error: Unrecognized token '<'` | `class-rows-table`'s `dataPath` was fetched against the SPA origin (index.html), not the backend base | resolves through `PolariService.getBackendBaseUrl()` like the other panels; spec added | rule: every dataPath/url input goes through the backend base ✅ |
| C7 | layer/schematic drawings empty on the deployed stack | `artifact_url` needed `POLARI_PUBLIC_BASE_URL` (unset in staging) → '' | relative `/api/pcb/artifacts/...` by default; stale rows derive from `artifact_path` | never require a public base url for in-app links ✅ |
| C8 | drawings 404 after a backend redeploy | module artifact homes were `~/.cache/polari-*` inside the container (ephemeral) | `module_home()` → `/app/data/<name>` in the container | artifacts → the file store [owed] |
| C9 | the C3 pin map drew an empty box | the C3 has BoardPin rows but no Connector/ConnectorPin rows (only the UNO seeds them) | a bare-BoardPin fallback layout | seed the C3 connectors [TODO 4] |
| C10 | /display/c-canvas and /display/hardware-solutions reloaded forever | `initializeFromBackend()` wiped the just-created local canvas solution (save debounced 2 s) → fallback selected another solution → `router.navigate` → `display-page` reloaded the whole display on ANY query-param emission → the panel re-mounted → … | local unsaved solutions survive the cache rebuild; display reloads only on a real id/object change; spec: ensure+select once, no navigation | rules: a panel never navigates; a display reloads only on a real param change ✅ |
| C11 | "ecc83-pp" meant nothing on the page | the ingest ignored the KiCad title block | title/description/licence read from the title block + SOURCE.json, shown first | every ingested artefact carries its own title/description ✅ |
| C12 | `GET /Runtime` 404 on the deployed backend (demo-4b's class) | NEW CLASSES must be in the hand-maintained `polariServer.defClassList` + `feature_imports.py`; the manifest alone does nothing (third time today: demo-4's 3 classes, pcb's earlier) | registered + seeded; a guard in `selftest_manifests` (`defclasslist_gaps()`) fails on any objects/ class missing from the list — it also exposed pre-existing gaps in pspp (4 classes) and testing (1) | the module scaffold/`manifests conform` should WRITE the registration, not a person [owed]; fix pspp/testing [TODO] |
| C13 | "the frontend bundle hash did not change" after a roll | false premise: display components build into a lazy chunk; `main.js` is content-hashed and unchanged; the chunk (`5949.*.js`) and `runtime.*.js` DID change | verified from the two images | rule: prove a frontend roll by the `runtime.*.js` manifest or by grepping the served chunk for a new string, never by `main.js` alone ✅ |
| C14 | after visiting c-canvas / hardware-solutions, EVERY no-code solution rendered empty ("none of the states render") | the canvas panel shares the root solution-state service: its synthesized `cmod.c-canvas.*` solution was saved to the backend and its `selectSolution()` persisted the global last selection into localStorage `polari-no-code-solutions-cache`; later loads restored it under the wrong object | hidden-name convention, `persist=false` from panels, restore only confirmed selections, CACHE_VERSION 10 flushes poisoned caches; workaround = remove that key | rules: panels never write the user's global selection or the backend; bump the cache version with semantics ✅ |
| C5 | installer probe crashed (`KeyError 'build'`) | it posted ESP32-C3 variants to the UNO-only endpoint | C3 variants skipped by board, failures reported not raised | ✅ |

## D. Product

| # | barrier | root cause | done | durable form |
|---|---|---|---|---|
| D1 | nine pages of tables, "almost unusable … no demonstratables or sim-spaces … no descriptions" (his verdict) | briefs said "configured tables only, no new component"; the viewer design waited on decisions he had already made; rows/tests/proofs optimised, the front half never built | descriptions on every page/table (generic `DisplayItem.description`); readiness split usable/partial/tracked; DEMONSTRABLES plan; demo-4 (C in the canvas) + demo-1b (drawings) building | definition of done = the demonstrable FIRST, tables below, each described; C no-code IN the canvas with target definitions; board sim-space; trace view; the dlv ladder |
| D2 | the register lumps usable boards with tracked ones | "track all, simulate few" had no readiness signal | derived readiness + the split tables | installer/hwnocode default to usable boards [owed, demo-1b] |

## E. Working method

| # | barrier | root cause | done | durable form |
|---|---|---|---|---|
| E1 | an Opus agent killed mid-slice (`oauth_org_not_allowed`), work uncommitted | model access | inventory + resume with a Sonnet agent on the same worktrees | use sonnet for build agents; a killed agent's worktree is the handoff |
| E2 | agents parked for 30–60 min on background jobs or drifted (an hour of live checks for a plan; a four-part UI brief) | multi-deliverable briefs; background waits | one deliverable + a time box per brief; foreground with timeouts; status nudges | keep the count at one or two [his rule] |
| E3 | three wrong network diagnoses before the right one | guessing from symptoms instead of measuring | tcpdump on the target, kernel drop reasons (bpftrace), counters | measure first; every finding carries its evidence [tnb] |
