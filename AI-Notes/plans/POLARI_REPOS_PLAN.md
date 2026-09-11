# Polari repos plan — `pol repos`: the CLI manages the code it holds, by pull profile

_2026-09-11, from Dustin's ask: "different pull automation profiles… a way for a code-based deployment using polari to manage the repos it is holding locally using the polari cli tool to manipulate git (only for the polari project and polari modules)". Planning only. Builds on bootstrap-dev.sh (piece-wise clone), push-all-dev.sh (the push sweep + module subtree re-publish), `pol modules get|publish`, `pol project update`, POLARI_VERSIONING_PLAN (tags, VERSION files, ReleaseManifest) and CICD_PIPELINE_PLAN (polling only, nothing inbound)._

## 0. The shape

One verb, `pol repos`, is the only thing that runs git across the forest, and it only ever touches **the forest**: the superproject, its submodules (nested), and the `polari-module-*` repos the register names. A **pull profile** says, for every repo, which ref it should be on and how it is allowed to move; `sync` makes the checkout match the profile with fast-forwards only; `status` says how far it is from matching; `promote` moves one ref onto another (what dev → main was today, by hand); `schedule` turns `sync` + the route's deploy verb into the code-based deployment: a machine polls its profile on a cadence and redeploys when the superproject commit changes. Nothing inbound, ever; the machine pulls.

## 1. Scope and the safety line

- **Forest only.** A repo is in scope when its `origin` URL is in the allow-list built from `.gitmodules` (recursively) plus the register's module `repo` fields plus the superproject itself. `pol repos` refuses any other directory or remote by name, even under the suite tree (a vendored upstream, `~/tools`, an isle-core-only copy). The allow-list is printed by `pol repos scope`.
- **Fast-forward only.** `sync`, `promote` and `push` never rebase, never merge, never force. A repo that cannot fast-forward is reported as *diverged* with the two tips and left alone; the rest of the forest still proceeds. The one existing exception stays where it is: module subtree re-publish (in-tree authoritative) force-pushes the split branch, and only to a `polari-module-*` remote.
- **Dirty means skip.** A repo with uncommitted changes is never moved; it is reported and the others continue (bootstrap-dev's "a failure never blocks the rest" rule).
- **Mutating verbs dry-run by default** (`--go` to act), the push-all-dev convention. `status`, `scope`, `verify` are read-only.
- **No credentials handled.** Pulls use whatever git already has (https anonymous for public repos, the user's ssh agent otherwise). Push needs the user's own credentials; a scheduled profile on a server never pushes.
- **Never the isle's live copy.** isle-core's `~/Isle-Mesh` is its own working copy; `pol repos` on pol-core moves only the suite's submodule pin, and `pol deploy sync <node>` runs `pol repos sync` *on* that node for its own checkout.

## 2. Pull profiles

A profile is a small YAML file in `polari-cli/repos/profiles/<name>.yml`; a checkout records its active profile in `.polari/repos.yml` (gitignored). Every repo gets `ref` (branch or tag) and `mode`:

| profile | superproject | submodules | module repos | mode | who uses it |
|---|---|---|---|---|---|
| `dev` | `dev` | `dev` (nested too) | in-tree authoritative; subtrees re-published on push | ff-pull, push allowed | developers (today's forest) |
| `main` | `main` | `main` | in-tree at the pin | ff-pull only, no push | a prod/distribution server, the Jenkins release job, a fresh isle install |
| `release` | tag `polari-vYYYY.MM.DD[.n]` | the pins of that tag | the manifest's content hashes | detached, moves only to another tag | production that wants an exact ReleaseManifest |
| `isle-member` | `main` | `main` | only the modules the isle admitted (`isle app` list) | ff-pull | a member device's `pol` (no framework tree needed beyond the CLI + admitted modules) |
| `module:<m>` | `main` | framework `main` | `<m>` on its own branch (`pol project`) | ff-pull for the frame, push for the module | a module developer (the Polari Developer loop) |
| custom | per-repo overrides on top of any of the above | | | | e.g. `dev` with Isle-Mesh pinned to a review branch |

Rules the profile carries: the branch each repo's default must be (`main` everywhere after today; `verify` fails on `master`), whether module subtrees are compared and re-published, whether `VERSION` files must be semver (versioning plan ver-1), and the deploy verb `schedule` runs after a change (`pol prod apply` for swarm profiles, `pol dev deploy` for the isle, `pol node up --env staging` for compose).

## 3. Verbs

```
pol repos scope                       the allow-list: every repo in the forest, its remote, its role
pol repos status [--profile P]        per repo: branch/tag, clean?, ahead/behind the profile ref, default branch, VERSION,
                                      module subtree drift (in-tree vs polari-module-* tip); one line per repo, a verdict
pol repos sync [--profile P] [--go]   fetch + fast-forward every repo to its profile ref, innermost first, submodule update;
                                      skips dirty/diverged repos and says so; exit 1 when anything was skipped
pol repos checkout <profile|tag>      switch the forest to a profile (or a release tag); records it in .polari/repos.yml
pol repos push [--go]                 push-all-dev generalised: push each repo's profile branch (dev profile only),
                                      then re-publish stale module subtrees (unless --skip-modules)
pol repos promote <from> <to> [--tag] [--go]
                                      ff-only promotion of every repo (dev→main today); refuses on to-only commits and names them;
                                      --tag writes polari-vYYYY.MM.DD on the superproject and pushes it (versioning ver-2)
pol repos publish [<module>|--stale]  the module subtree publish (moves from pol modules publish; that verb stays as an alias)
pol repos verify                      the standing invariants: every default branch is main, no master, pins on main are
                                      reachable on each submodule's main, VERSION files valid, register repos all exist,
                                      module subtrees match their repos; the CICD §3a docs check (README says main for users)
pol repos schedule [--profile P] [--every 5m] [--deploy auto|off] [--go]
                                      install a systemd timer (or print the Jenkins job stanza) that runs sync on this
                                      machine and, when the superproject commit changed, the profile's deploy verb
pol repos unschedule
pol repos log                         what sync/schedule did and when (the ledger under .polari/repos-log)
```

`pol deploy sync <node> [--profile P]` runs `pol repos sync` on a configured node over ssh (nodes.yml), so a prod server or an isle can be moved to `main` or a release tag from pol-core without anyone typing git there.

## 4. The code-based deployment

- **A prod/distribution server**: `pol repos checkout main` once; `pol repos schedule --profile main --every 5m --deploy auto` installs the timer. Each tick: fetch, ff, compare the superproject sha with the last deployed one, and if it moved run `pol prod apply` (which renders the proxy + os-security scenario, builds or pulls images per the answers, deploys the stack). A failed deploy leaves the previous stack running and writes the ledger; the next tick retries only when the sha moved again. This is the pull-based release loop the CI plan wanted, without Jenkins on machines that do not have it.
- **Jenkins** (host tier): the `polari-release` job's checkout step becomes `pol repos sync --profile main --go` in the workspace, so Jenkins and a timer-driven server behave identically; images and debs are still built and published only by Jenkins.
- **An isle**: the member profile pulls only the CLI and the admitted modules; `pol dev deploy` after a change. The isle's own `polari-isle-push` unit stays what it is (it pushes state, not code).
- **A release**: `pol repos promote dev main --tag --go` on pol-core (his gate first), then every `main`-profile machine picks it up on its next tick; `release`-profile machines move only when told `pol repos checkout polari-v2026.09.11`.

## 4a. Footprint — managing the space code takes on a given computer (his ask 2026-09-11)

Measured on pol-core today, the forest is **20 GB, of which source is under 200 MB**:

| what | size | note |
|---|---|---|
| working trees (all repos, no .git, no artifacts) | ~150 MB | modules/ is 50 MB of that |
| git objects, all repos | 1.9 GB | superproject 686 MB, polari-rf-node 591 MB, framework 548 MB (history carries old vendored blobs: FreeType tarball, wheels, libraries) |
| `.angular` build cache | 14 GB | pure cache, regenerable |
| `node_modules` (angular + psc frontend) | 1.2 GB | regenerable |
| app-shell dist, psc target, angular dist | 0.4 GB | regenerable |
| docker images / build cache / volumes | 11.9 / 5.1 / 1.1 GB | 10.7 GB of images reclaimable; separate from the forest but the same problem |

So the space a computer gives Polari is decided by three things the profile should control: **how much history it clones, which pieces it checks out, and what build caches it keeps.** The verb owns all three:

- **Profile fields**: `history: full|shallow|blobless` (`--depth 1` / `--filter=blob:none` partial clones: a `main` server or an isle member needs no history; a developer needs full), `pieces: [...]` (sparse checkout of the superproject: an isle member takes `polari-cli` + `Isle-Mesh` + admitted modules only; a prod server takes what its route builds; nobody takes `AI-Notes` unless they ask), `modules: all|admitted|list`, `caches: keep|prune-after-build|none`, and a **budget** (`max_mb`) the profile promises; `status` shows used vs budget and what is over.
- **`pol repos size`**: the table above for this machine, per repo: tree, .git, artifacts, plus docker's share; the largest regenerable items named with the command that removes each.
- **`pol repos slim [--go]`**: the safe reductions for the active profile: prune build caches (`.angular`, `node_modules`, `target`, `dist`, `__pycache__`, docker build cache and dangling images) that the profile says not to keep, `git gc --prune` and `git repack -d`, drop modules the profile does not need (`pol modules drop`, the register brings them back), convert a full clone to blobless on a server (`git fetch --refetch --filter=blob:none` after the profile changes). Never touches uncommitted work, never removes a repo, never prunes docker volumes (data) — those are `pol purge`'s business with backups.
- **`pol repos schedule`** on a server runs `slim` after every deploy when the profile says `caches: prune-after-build` (the disk-space memory: prune after staging rebuilds became a habit; this makes it a rule).
- **History slimming at the source (one-time, his call, D6)**: the framework's 548 MB of objects come from blobs that were removed from the tree (artifact hygiene 2026-08). Rewriting history to drop them is a force-push of every branch of a public repo; the alternative is to leave history and let every non-dev profile clone blobless. Recommended: blobless profiles, no rewrite.
- **Budgets as defaults**: `dev` full (today's shape, minus caches pruned on demand: ~4 GB with images), `main` server blobless + no caches + only its route's pieces (~300 MB of code + images), `isle-member` sparse + blobless (~50 MB + admitted modules), `release` same as main.

## 5. What exists and moves under the verb

bootstrap-dev.sh → `pol repos sync --profile dev` on a bare clone (the script stays as the zero-dependency entry point and calls the verb once the CLI is installed); push-all-dev.sh → `pol repos push`; the module subtree split/publish in modules.sh → `pol repos publish`; the promotion done by hand today → `pol repos promote`; the default-branch checks done by hand today → `pol repos verify`. The register (`polari-modules.json`) stays the source of module repo URLs; `.gitmodules` stays the source of submodule URLs.

## 6. Phases

| Phase | Builds | Proof |
|---|---|---|
| **rp-0** | `repos.sh`: scope, status, verify, **size**; profiles dev/main/release as files with history/pieces/caches/budget fields; `.polari/repos.yml` | status on this forest matches today's hand survey; verify passes (all main, no master) |
| **rp-1** | sync + checkout (ff-only, innermost first, dirty/diverged skip, ledger; shallow/blobless/sparse per profile) + **slim**; bootstrap-dev delegates | a fresh clone + `sync --profile main` equals the pinned tree at under 300 MB; a dirty repo is skipped and reported; `slim` on this box frees the 14 GB `.angular` cache and the dangling images |
| **rp-2** | push + promote (+ --tag) + publish moved under the verb; push-all-dev and `pol modules publish` become aliases | dry-run output equals push-all-dev's; promote refuses a to-only commit in a fixture repo |
| **rp-3** | schedule/unschedule (systemd timer), deploy-on-change with the profile's verb, `pol deploy sync <node>` | the home swarm manager on the main profile redeploys within one tick of a promote; a failed deploy leaves the old stack up |
| **rp-4** | isle-member and module profiles; Jenkins job uses the verb; docs (CLI guide section "Managing the code", PROD_SERVER_GUIDE "pull profile") | an isle member syncs only admitted modules; release job green |

## 7. Decisions for him

- **D1** Cadence default for `schedule`: 5 min (Jenkins parity) or 15 min?
- **D2** Deploy-on-change default: `auto` for the `main` profile on a server, or `off` until an operator turns it on? (Recommended: off by default, on by the prod guide's answer.)
- **D3** Should `promote` require `pol repos verify` green (the CICD §3a gate items it can check) or only warn?
- **D4** Release tags on promote by default (`--tag` implied), or explicit?
- **D6** Rewrite the framework's history to drop the removed vendored blobs (548 MB → small, force-push of a public repo) or keep history and clone blobless everywhere but dev? (Recommended: blobless, no rewrite.)
- **D7** Default budget per profile, and whether `status` only warns over budget or `sync` refuses to pull more.
- **D5** Where the profile files live: `polari-cli/repos/profiles/` (versioned with the CLI) or `AI-Notes/`-free `polari-suite/.polari/`? (Recommended: the CLI.)
