# Downloads-page next-session handoff (written 2026-08-24)

Fresh-session entry point for the dl arc. Governing plan (READ IT
FIRST, it is ratified): `AI-Notes/plans/DOWNLOADS_PAGE_PLAN.md`.
Offline flavor details: `AI-Notes/plans/OFFLINE_INSTALL_PLAN.md`
(decisions 3 signing-anchor + 4 app-images still open).

## Where every branch stands

| repo | branch | state |
|---|---|---|
| polari-framework | `dev-dl-1` | dl-1 page (4ca1dd9) + dl-1b product styling (e82f8c4). UNMERGED. |
| polari-suite | `dev-dl-1` | dl-3 BUILD SIDE DONE (46ff661): build-polari-complete-deb.sh PROVEN (real polari-complete_0.1.25_amd64.deb, 53 MB, 440 files) + build-polari-isle-deb.sh shell-core dist-fallback and complete-deb step. |
| polari-suite | `dev-nmp-1` | docs: plan + ledgers + this handoff. |
| polari-framework | `dev-cnt-2` | unrelated (cnt presentation) — do not mix. |

Also merged context: framework/angular `dev` carry the cnt merge
(cda27f0/9b7edb6); angular `dev-cnt-2` has the api-json-panel
readable upgrade + cntfet-iv-chart (0ed81f3) — the apps/offline
pages should reuse the dl-1b server-rendered styling, NOT the SPA.

## Ratified design in one breath

All-in-one = TRUE MERGED deb (dpkg-in-dpkg impossible);
`polari-complete`, Provides/Conflicts/Replaces its members.
App debs = generated ON REQUEST from the live module registry —
NO debs stored by default (a deb duplicates content the instance
already holds): generate → stream to requester → delete after
delivery or POLARI_APP_DEB_TTL; prebuilt pool only behind
POLARI_APP_DEB_PREBUILD (off). Shared payload across modules
factors into generated polari-app-shared-* debs (install-once,
dpkg-enforced); true conflicts refuse generation. Client side:
store-UI installs delete the deb on success (never on failure);
manual downloads belong to the user. Offline chunks generate
PIECE BY PIECE straight onto the medium (generate→write→delete→
next) — no pre-built pool needed, which dissolves the disk
blocker; pre-built pool = repeat-burn option.

## Next session's work, in order

1. **dl-3 page side** (framework `dev-dl-1`,
   modules/appstore/downloads_page.py): `polari-complete` staged →
   "Option A — one file installs everything" hero card; the
   ordered list demotes to "Option B — piece by piece";
   PACKAGE_INFO entry; selftest checks for A/B and the
   no-combined fallback. Then a REAL install of polari-complete
   on a test box = Dustin's window.
2. **dl-4 generator** (framework `dev-dl-1`,
   appstore/app_deb_builder.py + app_debs_page.py): pure-python
   deb writer (ar + tar.gz — no dpkg-deb dependency in
   containers), payload → /var/lib/polari/apps/<module>/ (code
   snapshot + exported seed data + manifest.json), on-request
   generation with TTL cleanup, shared-payload factoring,
   /downloads/apps page listing the module REGISTRY (not files on
   disk), traversal-safe serving, link from /downloads. Thin isle
   CLI verb `isle apps build-debs` calling the ONE framework
   implementation. Consumer honesty: payloads go LIVE via
   dynamic-modules live-admit — dev-dyn-1 MERGE IS ITS OWN GATE
   (ask Dustin); until then the page says how staged apps get
   admitted.
3. **dl-5 offline page** (framework `dev-dl-1`,
   appstore/offline_page.py): render staged chunks.json sets +
   honest not-yet state; /downloads footer note becomes the link.
   The piece-by-piece media chunker = off-1 in
   OFFLINE_INSTALL_PLAN.md (own session).
4. Client-side auto-delete in the store shell (polari-app-shell,
   Java) — separate session with Dustin's window.

## Gotchas already paid for

- `paste -sd ', '` CYCLES its delimiter chars (broke the Depends
  join) — use tr/sed. Fixed in the committed script.
- polari-shell-core needs jpackage; boxes without a JDK stage the
  newest prebuilt from polari-app-shell/dist (fallback now in the
  bundle script). pol-core has no jpackage.
- Merged maintainer scripts: strip member shebangs, subshell each
  member (`( ... )`) under one `set -e`; removal scripts run in
  REVERSE member order.
- Disk on pol-core: ~95% (6 GB free). Deb work fits; offline
  pools do NOT (on-demand chunking is the plan's answer).
- DisplayDefinition seeds are insert-by-name — but dl pages are
  server-rendered (no seeds), keep it that way.
- Suite ledger/plan docs live on `dev-nmp-1`; dl CODE on
  `dev-dl-1` branches. Don't cross them.

## Live state on pol-core (fine to leave / kill as needed)

Host preview stack from the cnt session may still run: backend
:3000 (POLARI_MODULES=cntfet,microchip,electrodevice,hwdigital,
working copy = framework dev-cnt-2) + ng serve :4201. The dl
pages don't need it (server-rendered, test via selftest +
static render + headless screenshots — see the dl-1b flow).

## Dustin's own queue (unchanged, TESTING_OWED)

cnt browser pass (hover/toggles/dark) + dev-cnt-2 merge gate;
dev-dl-1 review; dev-nmp-1 / dev-mqtt-1 / dev-ret-7 gates;
dev-dyn-1 merge decision (unblocks dl-4 admit wiring); KC
rotation (pub-0); offline decisions 3+4.
