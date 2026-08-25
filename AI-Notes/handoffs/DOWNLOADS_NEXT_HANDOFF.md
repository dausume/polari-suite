# Downloads-page handoff (updated 2026-08-24 after the build session)

Governing plan (ratified, now carries ✅ markers):
`AI-Notes/plans/DOWNLOADS_PAGE_PLAN.md`. Offline flavor:
`AI-Notes/plans/OFFLINE_INSTALL_PLAN.md` (decisions 3 signing-anchor
+ 4 app-images still open).

## What the 2026-08-24 autonomous session built (dl-3/4/5)

| repo | branch | state |
|---|---|---|
| polari-framework | `dev-dl-1` | dl-1 (4ca1dd9) + dl-1b (e82f8c4) + **dl-3 page (d2aef34) + dl-4 (62cb902) + dl-5 (0fc6b38)**. UNMERGED. |
| Isle-Mesh | `dev-dl-1` | **`isle apps build-debs` thin verb (bfd0c5b)**. UNMERGED. |
| polari-suite | `dev-dl-1` | dl-3 build side (46ff661): build-polari-complete-deb.sh PROVEN. |
| polari-suite | `dev-nmp-1` | docs: plan + ledgers + this handoff. |

Everything selftested green from polari-framework/ with
`PYTHONPATH=.:modules python3 -m appstore.selftest_<x>`:
downloads 16/16 · app_debs 19/19 · offline 6/6 · appstore 36/36.

- **dl-3 page**: polari-complete staged → Option A hero
  (pre-prepped provenance) vs demoted Option B + can't-coexist
  note; fallback = dl-1b layout. `appstore/downloads_shared.py` =
  the shared page shell + transparency components (explainers,
  provenance lines) all three surfaces use.
- **dl-4**: `appstore/app_deb_builder.py` pure-python deb writer
  (real dpkg-deb accepts output), payload →
  /var/lib/polari/apps/<module>/ + honest manifest naming the dyn
  admit gap; content-hash version = cache key within
  POLARI_APP_DEB_TTL (1 h default, 0 = delete-after-delivery);
  shared-payload factoring → polari-app-shared-* symlink debs
  (≥4 KB floor); named refusals incl. deb-name collisions;
  DebGenerationRecord JSONL → median estimates ("never generated
  yet" before history); POLARI_APP_DEB_PREBUILD knob +
  prebuild_all(); CLI `python3 -m appstore.app_deb_builder`.
  `appstore/app_debs_page.py` /downloads/apps lists the REGISTRY
  (named-unavailable for ghost modules), steps named before the
  click, zero JS. Isle verb locates checkout/container, proven on
  a real gears deb.
- **dl-5**: `appstore/offline_page.py` renders staged chunks.json
  (contract in module docstring) per-disk + write-the-media
  steps, honest not-built-yet page otherwise, manifest-is-the-
  truth streamed serving, signing openness stated. /downloads
  footer links offline + apps pages.

## Dustin's gates (nothing else moves without them)

1. Real `polari-complete` install on a test box (dl-3 proof).
2. One real app-deb install (e.g. gears + its shared deb if any)
   + eyeball /var/lib/polari/apps/.
3. Browser pass of /downloads, /downloads/apps,
   /downloads/offline (light/dark; screenshots from the session
   are in the commit messages' described flow).
4. dev-dl-1 review ×2 repos; dev-dyn-1 merge decision — the
   admit wiring (app payload → live module via dynamic-modules)
   is the NEXT dl-4 session and queues entirely behind that
   merge.
5. Offline decisions 3 (signing anchor) + 4 (app images on
   medium) → then off-1 pool builder on a roomy box.

## off-1 MACHINERY BUILT (same session, second pass)

Framework `dev-dl-1` 24b54eb: `appstore/offline_chunker.py` —
deterministic FFD chunk planning (cd/dvd/usb presets), named
refusal for unsplittable files, piece-by-piece emit
(write→verify→delete-source), chunks.json in EXACTLY the
offline_page contract + sha256SUMS; selftest 10/10 incl. the
producer/consumer render check. Suite `dev-dl-1` 43e1c0a:
`build-offline-bundle.sh` — pool from .generated/debs, closure
resolved in a PRISTINE ubuntu:24.04/22.04 container
(--print-uris; --closure adds roots until off-0's inventory),
honest SKELETON mode without --download (URIs recorded, README
names every gap: closure absent, signing decision 3 open,
images/VM absent per decision 4/off-0), --iso = per-chunk ISOs
piece by piece with every disk self-identifying. PROVEN here:
101-deb closure resolved, 2-chunk split of the real 110 MB set,
ISOs isoinfo-verified, sums OK, /downloads/offline renders the
real output. REMAINING off-1: `--download` run on a roomy box
(pol-core is 95%) + off-0 instrumented inventory to supersede
the declared-Depends closure roots.

## Remaining build work (in order, after gates)

1. dl-4 admit wiring session (post-dyn-merge): installed payload
   → live admit + GUI progress in the store shell.
2. off-1 completion: off-0 instrumented inventory (clean target,
   record every fetch) → `--download` bundle build on a roomy
   box → off-2 media probe in core-install.
3. Client-side auto-delete in the store shell (polari-app-shell,
   Java) — Dustin's window.

## Gotchas already paid for (keep)

- `paste -sd ', '` CYCLES delimiter chars — Depends joins use
  tr/sed (committed).
- polari-shell-core needs jpackage; no-JDK boxes stage the
  newest prebuilt from polari-app-shell/dist (fallback in the
  bundle script). pol-core has no jpackage.
- Merged maintainer scripts: strip member shebangs, subshell each
  member under one `set -e`; removal scripts in REVERSE order.
- GzipFile mtime must be set AT CONSTRUCTION (mtime=0) for
  deterministic gzip — assigning `.mtime` later silently does
  nothing (paid for in app_deb_builder).
- Debian package names forbid `_` — module names map through
  deb_package_name(); collisions refuse BOTH sides by name.
- Explainer prose can collide with selftest substring counts —
  count `class="prov prov-prepped"`, not the word.
- DisplayDefinition seeds are insert-by-name — dl pages stay
  server-rendered (no seeds), keep it that way.
- Suite ledger/plan docs live on `dev-nmp-1`; dl CODE on
  `dev-dl-1` branches (framework + Isle-Mesh + suite). Don't
  cross them.

## MERGED TO DEV 2026-08-24 (Dustin's bring-to-dev ask; push = his)

All dl work is on `dev` in every repo, ready for `push-all-dev.sh
--with-isle` (framework dev 91ca72a via merge, rf-node dev 96e0f9f
pointer, Isle-Mesh dev a5a7667, suite dev 437fd62 incl. the docs
merge). Framework `dev-nmp-1` (nutrition CODE) deliberately NOT
merged — its review gate stands; the suite-dev submodule pin
resolves to the downloads-merged rf-node dev, never the nmp
pointer. Same session added **dl-6 /downloads/plan** — the
topology/bundle wizard (devices + performance-in-what-way + goals
→ speculated core/hosting/member roles + per-device download
bundles with real links; 13/13) — and
**appstore/preview_server.py**, the review harness serving all
four surfaces with real data (same resource classes, no twin
routes). Live pass caught + fixed: offline manifests belong IN
the pool; nested chunk paths need the {filename:path} route.
Preview left running: http://192.168.0.210:8090/downloads

## dl-7 (same day): dependency/engine accounting + two deb flavors

Framework dev d88e1c4 (rf-node 2088062, suite c0ee858). File
counts replaced by REAL accounting: appstore/module_requirements.py
derives per-module pip libraries (measured closure bytes from the
live env, honest 'unmeasured'), polari module requires, and curated
+probed ENGINES (system engines = distro/offline-media payload,
never a wheel). /downloads/apps offers BOTH flavors per app:
Online deb (small; manifest = dynamic-after-install accounting) and
Offline deb (wheels ride inside, -offline pkg Provides/Conflicts/
Replaces the online name; pip --no-index line in manifest);
per-flavor wait estimates; planner links offline flavor when
net=no. Live-proven: climate-offline 13.9 MB / 6 wheels / 4.3 s,
dpkg-verified. selftest_module_requirements 10/10; all 7 suites
green. ENGINE_MAP is deliberately curated — extending it per
module (and wiring engine payloads into the offline media bundle)
is follow-up work.

## dl-8 + dl-9 (2026-08-24 evening, his live-review rounds)

Status flow: every Download lands on /downloads/apps/status/<m>
?flavor= — initiated confirmation, live named step (background
thread + meta-refresh, zero JS), then auto-handover; GENERATING /
DOWNLOADING state tags. Tab toggles: /downloads/apps Online|
Offline installs; /downloads One-file|Stepped install. dl-9:
download times MEASURED (stream close = real transfer; median
throughput predicts; honest no-data line); pool-aware cards
(READY = direct Download w/ age+size+predicted transfer;
GENERATING NOW = View progress; else Generate & download).
Preview server is THREADED (transfers must not block clicks).
All 7 appstore suites green. Consolidated on dev across repos
2026-08-25 for his push.
