# Polari versioning (ver arc): one Polari version, matched component versions, online/offline flavors that never collide

**Date:** 2026-09-06 · **Status: PLAN (ver-0). No code changed.** His
framing: "We need to do a versioning mapping of the different parts of
the overall polari system … We might as well call the project overall
Polari now even though it was initially just the research framework …
ensure that versioning between different parts of polari match up, that
way we can have one overall Polari version. Whereas the original polari
would be called either polari framework or polari research framework."

Companions: PRODUCTION_DEPLOY_PLAN (prd — the release manifest is the
carrier of the overall version), CICD_PIPELINE_PLAN (ci — the pipeline
stamps it), DOWNLOADS_PAGE_PLAN (the page states versions + dates).

## 0. Naming (decided by his message; applied from here on)

| Name | Means |
|---|---|
| **Polari** | the whole system: every repository below, released together under ONE version |
| **Polari Research Framework** (short: Polari Framework, code `prf`) | the original backend + frontend pair (`polari-framework` + `polari-platform-angular`, the `prf-*` images) — a COMPONENT of Polari now |
| Isle-Mesh | the networking layer (isle CLI, agent, router, polari-isle deployment) |
| Polari App Shell | the JavaFX runtime (`polari-shell-core`), the Isle App Store, the launcher debs |
| pol CLI | the developer/operator CLI |
| Political Scorecard | the PSC frontend + Java backend (a client of the framework) |
| modules | each `polari-module-<m>` repo, versioned on its own, admitted by a Polari release |

Docs, the downloads page and the deb descriptions say "Polari <ver>";
"framework" is reserved for the prf component. (README/GETTING_STARTED
wording follows in ver-1.)

## 1. What is versioned how today (verified 2026-09-06)

| Part | Version source today | Value now | Verdict |
|---|---|---|---|
| polari-isle meta deb | `build-polari-isle-deb.sh --version`, default `0.1.0` (`:29`) | 0.1.0 | hand default, never bumped |
| polari-complete (merged) | inherits the store version | 0.1.33 | derived |
| isle-mesh-cli deb | `0.1.<git commit count of Isle-Mesh>` (`build-polari-isle-deb.sh:76`) | 0.1.128 | counter, not a release |
| polari-shell-core + isle-app-store | `0.1.<commit count of polari-app-shell>` (`:88`) | 0.1.33 | counter |
| module app debs (dl-4) | `0.1.0+g<content-hash>` (`app_deb_builder.py:426`), offline flavor = same scheme, `-offline` name + Provides/Conflicts/Replaces | e.g. `polari-app-vpn 0.1.0+g363301e197` | content-addressed — right idea, wrong prefix (always 0.1.0) |
| prf images | tag `staging` / `prod` / `stateless` | `prf-backend:staging` | no version at all — the tag names a TIER |
| framework python | `setup.py version='0.1'` (`:21`) | 0.1 | static |
| angular | `package.json` | 0.0.0 | static |
| isle CLI `package.json` / pol CLI `package.json` | | 0.0.1 / 0.0.1 | static |
| PSC backend | `pom.xml` | 3.5.0 (the Spring parent) | not ours |
| `/api/health` | reports no version | — | nothing to compare against |
| git | eight repos, no tags (`git tag` empty), superproject pins = the only "release" record | | the pins ARE the truth, unnamed |

So: three unrelated counters, one static, one content hash, images
with no version, and no place that says which set of parts belongs
together. The superproject's submodule pins already define that set —
they just have no name.

## 2. The scheme

**2.1 One Polari version = a superproject tag.** `polari-vYYYY.MM.DD[.n]`
(calendar, `.n` for a second release the same day) on the superproject
commit whose submodule pins are the release. The pins ARE the mapping:
the tag names a specific commit of every component. This is the
"overall Polari version". A pre-release built from an untagged commit is
`YYYY.MM.DD-dev+<short sha>`.

**2.2 Component versions are semver, owned by each repo, and MUST be
declared in ONE file per repo:** `VERSION` at the repo root (plain text,
e.g. `0.2.0`). Every builder reads it instead of counting commits:
- polari-framework: `VERSION` → `setup.py`, `/api/health` (`version`,
  `polariVersion`), the `prf-backend` image label
  `org.opencontainers.image.version`.
- polari-platform-angular: `VERSION` → `package.json` + `runtime-config.json`
  (`frontendVersion`), the `prf-frontend` image label.
- Isle-Mesh: `VERSION` → `isle-mesh-cli` deb + `isle --version`.
- polari-app-shell: `VERSION` → `polari-shell-core` + `isle-app-store`
  debs + the launcher debs (`Depends: polari-shell-core (>= x.y)`).
- polari-cli: `VERSION` → `pol --version`.
- each module repo: `VERSION` → the module deb's version prefix
  (`<VERSION>+g<content-hash>` — the hash stays as the cache key).
Bumping a component is a normal commit in its repo; the Polari release
picks up whatever the pins say.

**2.3 The Release Manifest is the mapping, written by the release
build** (prd-5 / ci-2) and served by the framework: `ReleaseManifest`
row + `GET /api/release` + the downloads page:
```
{ "polari": "2026.09.06", "tag": "polari-v2026.09.06",
  "superproject": "<sha>",
  "components": { "prf-backend": {"version":"0.2.0","sha":"…","image":"ghcr.io/dausume/prf-backend:2026.09.06","digest":"sha256:…"},
                  "prf-frontend": {...}, "isle-mesh": {"version":"0.3.1","sha":"…","deb":"isle-mesh-cli_0.3.1_all.deb"},
                  "app-shell": {...}, "pol-cli": {...}, "psc": {...} },
  "debs": { "polari-complete": "polari-complete_2026.09.06_amd64.deb", ... },
  "modules": { "techtree": {"version":"0.1.0","content":"g500a5e9854","online":"polari-app-techtree_…","offline":"polari-app-techtree-offline_…"}, ... },
  "builtAt": "…", "builtOn": "pol-core" }
```
The merged `polari-complete` deb and the bundle meta deb carry the
POLARI version (`polari-complete_2026.09.06_amd64.deb`); their members
keep their component versions. Images get BOTH tags: the Polari version
(immutable, what the manifest pins) and the tier tag (`staging`, a
moving pointer for the swarm files).

**2.4 Compatibility = the manifest, checked at the seams:**
- the frontend's `runtime-config.json` carries the Polari version it was
  built in; the backend `/api/health` carries its own; the frontend shows
  a banner when they differ (a rolled backend under an old frontend, the
  exact case of the last two days).
- `isle` refuses to `core-install` a polari whose manifest names a
  different Isle-Mesh major than the CLI's, and says so.
- a module deb's manifest names the Polari version it was generated
  from; admission warns when the running Polari is older (the module may
  need symbols the core lacks) — warns, never refuses, because content
  is content.
- `pol build parity` gains a check that every `VERSION` file is a valid
  semver and that the manifest's component shas equal the pins.

**2.5 Online vs offline flavors share the version.** Same
`<VERSION>+g<hash>` for both; the offline deb's name gains `-offline`
and declares `Provides/Conflicts/Replaces` the online name, so dpkg
refuses installing both (proven today: `polari-app-vpn-offline
0.1.0+g4e1e1fd858` Conflicts `polari-app-vpn`). The offline deb carries
the pip wheels under `/var/lib/polari/apps/<m>/wheels/` (vpn: 4.4 MB,
cryptography rides inside; techtree: none, it has no pip deps); system
engines never ride a wheel — the manifest names them as coming from the
distro / offline media. The platform bundle gets the same pair in
prd-5: `polari-complete` (online: images pulled from the registry) and
`polari-complete-offline` (image tarballs inside, `build-offline-bundle.sh`).

## 3. Phases

- **ver-0 — this plan.** ✅
- **ver-1 — VERSION files + readers.** Add `VERSION` to the six repos
  (initial values: framework 0.2.0 — the dyn/merge line; angular 0.2.0;
  Isle-Mesh 0.3.0; app-shell 0.2.0; pol-cli 0.2.0; modules stay 0.1.0),
  make every builder read it (no more commit counting, no more `0.1.0`
  defaults), `/api/health` + `runtime-config.json` + `isle --version` +
  `pol --version` report it, image labels stamped. Rename in docs:
  "Polari" for the whole, "Polari Research Framework" for prf.
- **ver-2 — the tag + manifest.** `pol build release <YYYY.MM.DD>`: tag
  the superproject, write `ReleaseManifest` (row + `release.json` next
  to the pool), name the merged deb by the Polari version, tag images
  twice. This IS prd-5's release script; ci-2 runs it on merge to main.
- **ver-3 — the seams.** Frontend/backend mismatch banner; isle
  major check; module-deb generation stamps the Polari version in its
  manifest and admission warns on older cores; `pol build parity`
  version checks; the downloads page reads the manifest for every
  version + date it shows.
- **ver-4 — first tagged Polari.** After the readiness gate
  (CICD §3a): `polari-v2026.09.xx` on the promoted main, the manifest
  published with the debs.

## 4. Decisions (defaults in bold; his call)
- D1 overall version form: **calendar `YYYY.MM.DD[.n]`** (matches "what
  did I install and when" on the downloads page) vs semver for the whole.
- D2 component form: **semver in a `VERSION` file per repo**, bumped by
  hand in the commit that warrants it (minor for a phase/arc, patch for
  fixes, major for a contract break such as the vpn ingest schema).
- D3 modules: **keep the content hash as the cache key**, prefix with the
  module's `VERSION`.
- D4 image tags: **both** the Polari version (immutable) and the tier
  tag (moving) vs only the version.
- D5 naming in code: repos and image names stay as they are (`prf-*`,
  `polari-framework`); only prose and the manifest use the new names —
  a rename of repos/images is a separate, later decision.

## 5. Boundaries
- Ours: VERSION files + readers in framework, angular, pol-cli,
  app-shell; the manifest; the seams; docs wording.
- isle-core's Claude: Isle-Mesh's `VERSION`, `isle --version`, the
  core-install major check.
- Dustin: D1–D5, the initial component numbers, the first tag.
