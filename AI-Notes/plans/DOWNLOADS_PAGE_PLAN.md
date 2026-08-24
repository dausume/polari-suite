# Downloads page — next iteration plan (dl-3 / dl-4 / dl-5)

Written 2026-08-24 from Dustin's asks: (1) an all-three-in-one deb,
(2) a second page linked from /downloads serving per-app debs
(modules + polari app data, "install odoo-style apps via debs"),
(3) the offline installable debs. PLANNING ONLY — build starts on
his go, per-arc.

Built so far (branch `dev-dl-1`, UNMERGED): dl-1 the /downloads
page + traversal-safe deb serving + POLARI_DOWNLOADS_DIR knob;
dl-1b the product-page presentation (cards, buttons, steps,
light/dark). Offline flavor plan: `OFFLINE_INSTALL_PLAN.md`
(decisions 1+2 ratified: Ubuntu target, multi-disk/multi-USB
chunking; 3+4 open).

---

## dl-3 — the all-in-one deb (`polari-complete`)

### The constraint that shapes the design

dpkg holds its lock during maintainer scripts, so a deb whose
postinst runs `dpkg -i` / `apt install` on bundled sibling debs
is NOT viable (classic dpkg-inside-dpkg refusal). Two designs
survive:

- **A. TRUE MERGED deb (recommended).** At bundle-build time,
  unpack every member deb (`dpkg-deb -R`), merge the file trees,
  and emit ONE package:
  - `Depends` = union of member Depends minus the member names
    themselves. Current union (read from the real debs):
    `nodejs, jq, openssl, curl, iw, hostapd, policykit-1`.
  - `Provides: isle-mesh-cli, polari-shell-core, isle-app-store,
    polari-isle` + matching `Conflicts`/`Replaces`, so the
    combined and piecewise installs can never coexist or
    double-install (reinstall-dedup rule).
  - Maintainer scripts concatenated in INSTALL_ORDER under
    `set -e` (member postinsts are ours and small: 31/13/7
    lines — auditable merge, refuse the build on any file-path
    conflict between members).
  - We own every member build script, so the merge is
    deterministic — no guessing about foreign packages.
- B. Meta-deb + local file:// apt source pointing at bundled deb
  copies. Rejected: needs the source dir staged before apt runs,
  leaves two install mechanisms alive, and apt refuses unsigned
  local sources without extra ceremony.

### Build side

- New suite-root `build-polari-complete-deb.sh`, invoked at the
  end of `build-polari-isle-deb.sh` (same .generated/debs output,
  same one-version-per-package prune).
- Version = the store deb's version (matches the page headline
  logic).
- REFUSES unless ALL of INSTALL_ORDER is present — no silent
  partial bundle. ⚠ pol-core currently stages only 3/4:
  `polari-shell-core` is missing from .generated/debs; the full
  bundle build (build-launcher-deb.sh path) must run first.

### Page side

- `polari-complete` staged → rendered as **"Option A — one file
  installs everything"** hero card; the existing ordered list
  demotes to "Option B — piece by piece". PACKAGE_INFO entry +
  selftest checks for both options and for the
  no-combined-staged fallback (page unchanged from dl-1b).

### Proof

Merge-planner selftest (Depends union, Provides/Conflicts set,
file-conflict refusal); real build from a full bundle;
`dpkg-deb -R` round-trip check headless; real install on a test
box = Dustin's window.

### ✅ BUILD-SIDE DONE 2026-08-24 (suite branch `dev-dl-1`, 46ff661)

`build-polari-complete-deb.sh` built + PROVEN on the real bundle:
polari-complete_0.1.25_amd64.deb, 53 MB, 440 merged files, zero
collisions, Depends `curl, hostapd, iw, jq, libnss3-tools,
nodejs, openssl, policykit-1`, Provides/Conflicts/Replaces all
four members, merged postinst/postrm syntax-checked.
`build-polari-isle-deb.sh` now (a) falls back to the newest
prebuilt polari-shell-core from polari-app-shell/dist on
no-jpackage boxes (closes the 3-of-4 staging gap) and (b) runs
the complete build after the prune. REMAINING for dl-3: the
/downloads page Option A/B rendering + selftests + a real install
(Dustin). Gotcha for the next session: `paste -sd ', '` cycles
its delimiter chars — the Depends join uses tr/sed instead.

### ✅ PAGE SIDE DONE 2026-08-24 (framework `dev-dl-1`, d2aef34)

Option A hero card (pre-prepped provenance line) vs demoted
Option B with the can't-coexist note; dl-1b fallback intact; the
transparency components landed as `appstore/downloads_shared.py`
(page shell + explainers + provenance lines, shared by all three
surfaces). Selftest 6→16, real-bundle render + light/dark/mobile
screenshots. REMAINING: the real install = Dustin's window.

---

## dl-4 — the apps page (/downloads/apps)

### Concept

`polari-app-<module>_<v>_all.deb` = one installable app:
- payload → `/var/lib/polari/apps/<module>/`:
  `modules/<module>/` code snapshot + exported seed/app data
  (the export→seed machinery; climate is the precedent) +
  `manifest.json` (module name, version, framework
  compatibility, data files, licence note).
- Page: same product styling as /downloads, one card per staged
  app deb, staging knob `POLARI_APP_DEBS_DIR`, traversal-safe
  `/downloads/apps/{file}`, honest empty state; linked from
  /downloads ("Add individual apps").

### AUTO-GENERATION, not a hand-run builder (Dustin 2026-08-24)

App/module debs are generated BY polari + isle-mesh, so every
module is automatically available as a deb without anyone
remembering a build step:
- The framework owns a generator (`appstore/app_deb_builder.py`)
  that packages any registered module from its own checkout; the
  isle CLI gets the verb (`isle apps build-debs`) for on-isle
  generation — CLI verb and framework generator share ONE
  implementation (vendor-sync rule, never twin scripts).
- Generated pool obeys reinstall-dedup: ONE version per package,
  old versions pruned on regeneration.

### REFINEMENT (Dustin 2026-08-24, second pass): generate ON
### REQUEST, never store by default

A deb is a DUPLICATE of content the instance already holds (the
module code + app data ARE the app) — it must not occupy disk
unless someone currently wants it:
- **Default = on-demand**: the apps page lists modules from the
  live registry (no debs on disk at all). Clicking Download
  triggers generation, the deb streams to the requester, and the
  server copy is deleted after delivery — or after a TTL
  (POLARI_APP_DEB_TTL, e.g. 1 h) so a flaky download can retry
  without regenerating. Version-hash caching applies only WITHIN
  the TTL window.
- **EXCEPTION (Dustin 2026-08-24 third pass): `polari-complete`
  is PRE-PREPPED** — the headline installer must download
  instantly, so the bundle build stages it and it never enters
  the on-demand flow. The page says so explicitly, and says the
  app/module debs are generated on demand.
- **Generation timing is RECORDED for honest estimates**: every
  generation appends {module, contentHash, bytes, seconds,
  generatedAt} to a small ledger (DebGenerationRecord rows);
  the page shows each on-demand item's expected wait from its
  history ("usually ~40 s", median of recent runs) and an
  honest "never generated yet — first run measures it" before
  any history exists. No invented numbers.
- **Pre-prepped pool = an explicit OPTION** (POLARI_APP_DEB_PREBUILD
  knob, off by default) for deployments that prefer instant
  downloads over disk — e.g. the public droplet.
- The FOUNDATIONS (generator + module content + manifest spec)
  are always present; only the artifact is transient.
- Same principle for the offline media flavor: the chunker can
  generate debs PIECE BY PIECE straight onto the USB/CD/DVD
  (generate chunk → write → delete → next), so no full
  pre-built pool is ever required on disk; a pre-built pool
  stays an option for repeat burns. ⚠ this also dissolves the
  disk-space blocker for off-1 on small boxes.

### Space: debs are delivery vehicles, deleted after install

- Server side: on-demand generation + TTL cleanup above; the
  pre-prepped pool (when enabled) keeps only the current
  generation.
- Client side, store-UI path (the normal flow): the shell
  downloads to a temp dir, installs via pkexec, and DELETES the
  deb once dpkg reports success — a failed install keeps the file
  + surfaces the error (never delete on failure).
- Client side, manual browser-download path: the deb sits in the
  user's Downloads folder; a package must not reach into the
  user's files to delete itself — the page instructions say the
  file can be deleted after install. (Decision 6 confirms this
  split.)

### Overlap between modules installs ONCE

Two app debs must never carry the same file twice — dpkg itself
refuses two packages owning one path, so this is correctness,
not just space:
- Generation-time overlap analysis: content-hash every payload
  file across the module set; files shared by ≥2 modules are
  factored OUT into generated `polari-app-shared-<name>` debs
  that the app debs `Depends:` on — shared code/data installs
  once, dpkg-enforced.
- Data-level dedup: seed/app data imports go through
  composition.seed_upsert (insert-by-name) so overlapping seed
  rows never double-insert on install or REinstall — same
  discipline as the seed-field-addition rule.
- The analysis REFUSES generation on a true conflict (same path,
  different content, no shared factoring possible) — named
  refusal, never a silently-clobbered file.

### The honest gap — DECISION for Dustin

An installed payload still has to become LIVE on the local
instance. That consumer is the **dynamic-modules arc**
(dev-dyn-1: live admit, module directory — backend PROVEN but
UNMERGED). Options:
1. Ratify + merge dyn first; app debs then admit through the
   real machinery (clean, one mechanism).
2. v1 ships payload staging only + a documented
   `pol modules admit <path>` step; GUI admit follows the dyn
   merge (faster to page, but a terminal step hides in the flow
   — against the no-terminal promise for normal users).

Recommendation: option 1 — the dyn merge gate is review-only
work and keeps the no-terminal promise intact.

### Odoo-style third-party apps

An app deb that declares a compose service (the odoo precedent)
is v2 — v1 scope is polari-module apps only, so the manifest
stays honest about what the instance can actually admit.

### ✅ dl-4 BUILT 2026-08-24 (framework d2aef34→62cb902,
### Isle-Mesh bfd0c5b — admit wiring still queued on dyn merge)

`appstore/app_deb_builder.py` (pure-python ar+tar.gz writer,
dpkg-deb-verified; content-hash version = TTL cache key; shared
factoring via polari-app-shared-* symlink debs, ≥4 KB floor;
named refusals; DebGenerationRecord JSONL + median estimates;
POLARI_APP_DEB_TTL / POLARI_APP_DEB_PREBUILD knobs) +
`appstore/app_debs_page.py` (/downloads/apps, registry-listed,
on-demand provenance + pre-click named steps, admit-gap
explainer) + `isle apps build-debs` thin verb. Selftest 19/19.

---

## dl-5 — the offline surface

Governing plan stays `OFFLINE_INSTALL_PLAN.md` (off-0..off-4;
decisions 1+2 RATIFIED — Ubuntu, multi-disk/multi-USB chunking;
**open: 3 signing anchor, 4 app images on medium**). The
downloads-page tie-in this iteration adds:

- `/downloads/offline` page: renders staged chunk sets from a
  `chunks.json` manifest (POLARI_OFFLINE_DIR) — per-disk file
  lists, sizes, burn/copy instructions in the same product
  styling; honest "not built yet, here is what it will be" state
  when nothing is staged.
- /downloads footer note ("not available yet") becomes the LINK
  to that page.
- off-1 pool builder (apt dependency closure for the target
  Ubuntu release, chunk planner splitting by media size) builds
  the real payload. ⚠ the docker/qemu closure is multi-GB —
  pol-core sat at 96% disk 2026-08-16; the pool build belongs on
  the droplet/build box, or after a prune pass here.

### ✅ dl-5 PAGE BUILT 2026-08-24 (framework 0fc6b38)

`appstore/offline_page.py`: staged chunks.json (contract
documented in the module docstring: target/builtAt/media +
per-chunk labeled file lists) renders per-disk sections + sizes +
write-the-media steps; honest not-built-yet page otherwise; named
refusals for malformed manifests; manifest-is-the-truth streamed
serving; the open signing decision stated honestly on-page.
/downloads footer note is now the link. Selftest 6/6.
REMAINING: off-1 pool builder (own session, roomy box).

---

## Transparency components (Dustin 2026-08-24: "the frontend
## will also need components that explain everything
## transparently to the user")

Every downloads surface explains itself in plain language —
nothing happens invisibly:
- **What-is-this explainers** on each page: what a deb is, why
  install order matters, what "pre-prepped" vs "generated on
  demand" means, what gets fetched from the internet during
  install, and what will occupy disk where.
- **Per-item provenance line**: pre-prepped items say when/where
  they were built and their version source; on-demand items say
  "generated fresh when you click, deleted from the server after
  delivery/TTL" plus the recorded time estimate (above).
- **During generation**: an honest progress state naming the
  step (packaging module → writing data → streaming), never a
  bare spinner; failures surface the named refusal.
- These are server-rendered blocks in the dl pages' shared
  styling (no SPA dependency), reusable across /downloads,
  /downloads/apps, /downloads/offline.

## Decisions — RATIFIED 2026-08-24 ("the plan sounds good as is")

Dustin ratified the plan with the recommended option on every
line; the one carve-out is that the dev-dyn-1 MERGE itself stays
its own explicit gate (dl-4's admit wiring queues behind it).
The list below is kept for the record:

1. dl-3 design A (true merged deb) — yes/no.
2. Combined package name: `polari-complete` (alt: `polari-suite`).
3. dl-4 consumer path: dyn merge first (recommended) vs
   documented-admit v1.
4. dl-4 v1 scope = polari-module apps only (odoo/compose apps =
   v2) — yes/no.
5. Offline decisions 3 (signing anchor) + 4 (app images on
   medium) from OFFLINE_INSTALL_PLAN.md.
6. Client deb cleanup split: store-UI installs auto-delete on
   success; manual browser downloads are the user's files (page
   says "safe to delete after install") — confirm.
7. ~~Auto-generation trigger~~ SUPERSEDED by the on-request
   refinement: generate when asked, delete after delivery/TTL;
   prebuild = explicit knob. RATIFIED 2026-08-24.
8. Shared-payload factoring via generated polari-app-shared-*
   debs (vs refusing all overlap outright) — confirm.

Sizing: dl-3 ≈ one session (builder + page + tests + real build);
dl-4 ≈ two sessions (generator + hash trigger + overlap factoring
+ page; admit wiring lands with the dyn merge); dl-5 page ≈ half
a session, off-1 pool builder = its own session on a roomy box.
