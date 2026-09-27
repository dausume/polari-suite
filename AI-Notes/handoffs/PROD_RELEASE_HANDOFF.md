# Handoff — the first automated release + the first droplet deploy (started 2026-09-27)

_The dedicated handoff `PIPELINE_HANDOFF.md` §7 promised. Read that file's §5–§7 first (what the pipeline is, the
dep design, the rules); this file only tracks THIS run to production. Rules that bind: only what was TESTED is
released (verdict per sha, released == tested by image id); main promotion and the first apply of any box are a
PERSON's; the pipeline's ssh never touches production secrets (the deploy agent under a restricted key); few
agents, non-Fable for readings and scripted checks; no real identifiers in tracked files._

## 1. Where it starts from (2026-09-27, 06:00 EDT)

| fact | value |
|---|---|
| `dev == main` | c40fffc (suite), by his DIRECT push on 2026-09-27 — not through the pipeline, so main had NO verdict |
| `test` before today | 62e4305, verdict `passed` WITH WARNINGS (uninstall dirty, `CI_UNINSTALL_GATE=warn`) on 2026-09-23 |
| pipeline device | econ-core: Jenkins up (docker compose, loopback :8080), checkout was at 62e4305 → pulled to c40fffc, `pol jenkins up` re-stamped (25 pipeline files; the tip added the ADVISORY proofs stage: `Jenkinsfile.test`, `proofs.sh`, `report.py`, `verdict.py`) |
| isle target | isle-core reachable again (idle, 1.5 GB free); the pipeline user reaches it with its own key |
| tokens | release token classic `repo`, expires **2026-10-23**, can push suite + tap; registry token classic `repo, write:packages`, expires 2026-12-19; `dausume/homebrew-polari` exists |
| device knobs | `CI_ISLE_VM_RAM_GB=4`, `CI_BUILD_OFFLINE_MEDIUM=false`, `CI_MAIN_RELEASE_AT` unset (= midnight), `CI_UNINSTALL_GATE` unset (= warn) |
| main queue | SCHEDULED c40fffc for the next local midnight — the gate reads `pool/test/<sha>/verdict.json` for main's OWN sha, so it refuses (NOT_BUILT) until c40fffc has a `passed` verdict |

## 2. What was done today (in order)

1. 06:02 EDT — `pol jenkins promote test` from econ-core: all repos ff'd test ← dev (framework 61c03cf→c74ecbf,
   angular eff10dc→cc01202, rf-node 4a69384→7fb63a6, cli 433269e→b9c003e, scorecard-backend e0b28fd→dd0cbdb,
   scorecard-node 751f135→93383d8, suite 62e4305→c40fffc; app-shell, Isle-Mesh, scorecard-frontend already equal).
   Promotion marker written → the next 10-minute tick starts `polari-test` on c40fffc without the quiet window.
2. Watching the run (a Sonnet watcher; 60–75 min expected: wipe → debs → images → scans → proofs → 89 selftests →
   isle stage on isle-core → verdict). Result: _pending — see §3 when filled._

## 3. The verdict for c40fffc — FAILED (polari-test #2079, 06:06–06:32 EDT, 26.6 min)

`why: module selftests failed on the device: core (3 of 89 suites)` — the SAME three fail inside the isle, so it is
code, not environment. All three are the tt/lod + proofs arc merged 2026-09-26/27 without the core suite being run:

| suite | finding | fix (on dev) |
|---|---|---|
| `accessControl.selftest_cause_context` 40/41 | thread-start site UNLISTED: `modules/resources/custom/cost_meter.py` (the rc-1 cost sampler) | list it in `KNOWN_THREAD_SITES` with its cause |
| `polariApiServer.selftest_outbound` 60/61 | raw `urlopen` fallbacks bypass `outbound.py`: `computelod/custom/eda_engines.py:96`, `mathproofs/custom/proof_engines.py:73`, `tensormath/custom/torch_engine.py:76` | drop the `except ImportError` fallback (outbound is core) |
| `moduleService.selftest_manifests` 7/8 | `computelod` manifest lacks `custom/explain.py`, `custom/repro.py`; `mathproofs` lacks `custom/explain.py`, `custom/sources.py` + table drift | `moduleService.manifests conform` for both |

Everything else was green: debs + images built (prf-frontend from Dockerfile.prod), isle stage on isle-core — guest up
45 s, install 515 s to online, verify 8/8, 86/89 suites inside the isle, leak check clean; uninstall `dirty` (warn);
scans advisory 5 critical / 155 high (the 9 gitleaks highs = Isle-Mesh test-fixture keys; the critical = maplibre-gl
CVE-2026-85061).

**Pipeline bug found by the run:** the ADVISORY proofs stage never ran — `bash: /var/polari-jenkins/proofs.sh: No
such file or directory`: the script was added to the checkout but never bind-mounted into the controller
(`polari-jenkins/docker-compose.yml`), and the controller stamp only hashes files already mounted. Fix = the mount
(+ the stamp list if hard-coded); the stage's `catchError` hid it as "not run".

**Secrets question settled:** the controller runs the routes as `polari-ci` (uid 999), which reads
`/run/secrets/github/{release_token,registry_token}` → github-release, ghcr, homebrew are ARMED at release time;
apt-repo is DRY for real (no signing key yet). The doctor's `DRY (secret absent)` rows are the desktop user's view only.

**The midnight tick:** main = c40fffc with a FAILED verdict → the release gate refuses (NOT_BUILT), nothing publishes.
Next: fix the three suites on dev → commit innermost-first → `pol jenkins promote test` again from econ-core → a
`passed` verdict → then §4.

## 3a. The second run — test = 50d956c (framework 2a9a507, rf-node 70d3b40), promoted ~07:1x EDT

The fixes (§3 table) + the proofs mount are on dev and pushed; econ-core pulled, `pol jenkins up` recreated the
controller (mount + stamp), `promote test` again. **Consequence for the release gate:** main is still c40fffc, whose
verdict is FAILED and stays so — a `passed` 50d956c does NOT release by itself. Main must move to 50d956c by
`pol jenkins promote main` (HIS word each time, as always) or his own push; only then does the scheduled tick (or
`pol jenkins retry main`) publish. _Result of the second run: §3b._

## 3b. The verdict for 50d956c — PASSED WITH WARNINGS (polari-test #2084, 06:51–07:24 EDT, 33.7 min)

`89 suite(s): 89 pass` on the device AND inside the isle; isle stage: guest up, install 544 s to online, verify 8/8,
leak check clean (RAM +30 MB); uninstall `dirty` (warn, same footprint as before); scans advisory unchanged
(5 critical / 155 high). `pol jenkins promote status`: `test 50d956c verdict=passed · main c40fffc verdict=failed ·
dev 50d956c`. **The release now waits on ONE thing: his `pol jenkins promote main`** (main ← test = 50d956c); then
the midnight tick publishes, or `pol jenkins retry main` at once.

**Proofs stage, first real execution:** it RAN (33 claims: 9 decided, 9 witnessed, 7 checked-symbolically, 2 refuted
= the two known red claims, 3 unprovable-here, 2 conjectured, 1 undetermined; lean not run — no worker on the
device; 104 s) and then died writing `/out/results.json` (PermissionError): `proofs.sh` bind-mounted a path that
exists only inside the controller, so the HOST daemon created it root-owned. Fixed on suite dev after the run
(no bind mount — write inside the container, `docker cp` out, like selftests.sh never mounting). The fix is a
pipeline-script change only: it reaches econ-core by `git pull` + `pol jenkins up` (the stamp), and does NOT need a
new test verdict — `promote main` promotes from origin/test = 50d956c regardless.

## 3c. His `promote main` + `retry main` (~07:40 EDT)

main ← test = 50d956c on every repo (framework c74ecbf→2a9a507, rf-node 7fb63a6→70d3b40, scorecard-backend
e0b28fd→dd0cbdb, suite c40fffc→50d956c; the rest already equal); GitHub bypassed its PR rule for his account as
before. `retry main` printed "the next tick releases now, not at the scheduled slot". Release run being watched
(the tested-images load, the tag, the three armed routes, release.json testedAgainst, the report asset, then the
deploy tick). _Result: §3d._

## 3d. ✅ THE FIRST AUTOMATED RELEASE — `polari-v2026.09.27` (polari-release #1074, 09:43–09:46 EDT, 3 min 7 s)

(The retry marker re-keyed to 50d956c at 09:39 EDT, ~2 h after his commands' wall clock as pasted — the tick that
picked it up was #1074; the earlier #1073 at 09:33 still saw c40fffc.)

| rule | evidence |
|---|---|
| released == tested | `[tested-images] prf-backend:2026.09.27 IS the tested image sha256:086166c8… (loaded, not rebuilt)`, same for prf-frontend `96e987a2…`; "2 image(s): released == tested by construction" |
| the tag | `polari-v2026.09.27` → 50d956c, pushed |
| github-release | REAL: `https://github.com/dausume/polari-suite/releases/tag/polari-v2026.09.27`, 11 assets: 6 debs, `TEST_REPORT.md`, `SCAN_SUMMARY.md`, `verdict.json`, `SHA256SUMS`, `release.json` |
| ghcr | REAL: `prf-backend` + `prf-frontend` `:2026.09.27` + `:latest`, digests = the tested ones; both packages already **public**; pushed UNSIGNED (`cosign_key` absent — a later secret) |
| release.json | `tested_against.sha` = 50d956c, `verdict: passed`, the two images, the report path; `publishedTo` = github-release + ghcr (`dryRun: false`) |
| polari-deploy | #720 NOT_BUILT: `SKIP hold — HOLD is on for self-proof` (correct) |

**polari-publish #1 FAILED on homebrew** (66 s): `git commit -qam` on a NEW, untracked `Formula/pol.rb` committed
nothing → non-zero → the tap unchanged AND apt-repo never even rendered (no isolation between routes). Fixed on suite
dev: `homebrew.sh` stages `Formula` explicitly and skips an empty commit on a re-run; `Jenkinsfile.publish` wraps each
route in `catchError` (the build still ends FAILURE). To finish the release: pull + `pol jenkins up` on econ-core,
then re-run `polari-publish` with `VERSION=2026.09.27 ROUTES=homebrew,apt-repo` (github-release/ghcr are idempotent
anyway: "already exists — idempotent skip").

**publish #2 (13:57Z, homebrew,apt-repo) FAILED at `verify pool`:** `./release.json: FAILED` — the routes write their
`publishedTo` entry INTO release.json after `SHA256SUMS` was frozen at mint time, so the first successful route breaks
every later publish of the same version. Rule fixed on dev: the manifest covers the immutable artifacts and never
release.json (the living record, published beside it); publish verifies the manifest minus that line, so the existing
2026.09.27 pool re-publishes. (The GitHub-release assets `SHA256SUMS` + `release.json` for 2026.09.27 agree with each
other — both were uploaded before the mutation.) No `pol jenkins` verb triggers a job by hand — the re-run used the
Jenkins API through the controller with a crumb + cookie jar (a `pol jenkins publish <version> [routes]` verb is owed).

**publish #3 (14:04Z):** `verify pool` PASSED with the new rule; apt-repo rendered DRY correctly (names the three absent
signing/deploy secrets; six `reprepro includedeb` + the rsync line); homebrew staged + committed `pol 2026.09.27` and
then the PUSH failed: `fatal: could not read Username for 'https://github.com'` — `gh repo clone` authenticates via gh,
a plain `git push` in the controller has no credential helper. Fixed on dev: the tap push uses the token-in-URL form
the release job already uses for the tag (never echoed; Jenkins masks it). Lesson: the homebrew route had never
been exercised past its dry-run rendering — each of its three real steps failed once (stage, commit, push).

**✅ publish #4 (14:11Z, 12 s) SUCCESS — the release is COMPLETE on every armed route:** homebrew tap commit `7131680
pol 2026.09.27`, `Formula/pol.rb` url = the tag tarball (resolves 200), sha256 recorded; apt-repo DRY (three secrets
absent); `publishedTo` = github-release + ghcr + homebrew real, apt-repo dryRun. Owed, small: the formula hashes
GitHub's on-the-fly archive tarball (GitHub has changed that compression before) — a release-asset tarball would be
the stable source; and `pol jenkins publish <version> [routes]` so a person never needs the API by hand.

## 4. What happens next, and who does it

- ✅ DONE 2026-09-27: test passed → his `promote main` + `retry main` → `polari-v2026.09.27` on GitHub Releases, ghcr
  (both packages already public) and the homebrew tap; apt-repo waits for the signing key after the Keycloak rotation.
- **The next cycle is routine:** dev → `pol jenkins promote test` → `passed` → his `promote main` → the midnight tick
  (or `retry main`) releases; a failed publish route is re-run by hand for now (API; the `publish` verb is owed).
- **Still his after the first release:** link the ghcr packages to the repo (they are public already).
- **The droplet deploy (dep-3, plan §11.7 D1–D6 — ALL STILL OPEN, his):** D5 = his key on the droplet once, then
  `pol jenkins deploy authorize <name>` installs the pipeline key restricted to the deploy agent; D1 window,
  D2 min_health routes, D3 rollback policy, D4 a `channel=test` home box or not, D6 the isle route. The row stays
  `hold=true`; the first apply is `pol jenkins deploy <name> --now` with him watching.

## 5. Known warnings carried into this release (not gates)

- The isle uninstall footprint (`/usr/share/isle-mesh`, `/etc/polari`, 5 images) — isle-core's; `PIPELINE_HANDOFF` §2.
- Advisory scans (last: 5 critical / 156 high) and the advisory proofs stage — recorded in the report only.
- The doctor run as the desktop user prints the routes as `DRY (secret absent)` because `/etc/polari-jenkins/secrets`
  is root:polari-ci 0640 — _whether the CONTROLLER sees them (what arms a route) is being verified; see §3._
- The wired port on econ-core still has no IPv4; builds pull over Wi-Fi.
- **Owed (found while conforming):** `moduleService.manifests generate` does NOT preserve a hand-authored
  `requires.engines` list (computelod's seven engine entries would be wiped; `_preserve_hand_set` never learned the
  key and `module_requirements.ENGINE_MAP` has no computelod row) — the manifests were hand-patched instead. Fix
  `_preserve_hand_set` (or source the engines from the map) before anyone runs `generate` on computelod.
- The nested `Isle-Mesh/isle-manager-app` submodule (ssh URL) fails `submodule update` on econ-core — host key not
  known to that user; harmless to the pipeline (top-level submodules only), fix = `ssh-keyscan` or an https URL.
