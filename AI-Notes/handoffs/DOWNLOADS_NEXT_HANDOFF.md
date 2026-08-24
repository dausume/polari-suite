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
