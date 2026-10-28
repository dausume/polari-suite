# Polari app updates on the isle — versioned images, the app updates (pau), 2026-10-28

**His words (2026-10-28):** "Basically they need the app for polari updated with a new image, not just the image rebuilt correct? To a
normal user that is an app update." Memory `polari-update-is-an-app-update`. Roots: his 2026-10-24 loop (`pol dev deploy` → mesh
registry → `isle-polari-deploy --pull`) and the "isle update" notes (Isle-Mesh b029fc9: the isle's twin of `pol prod update` — registered
source, one container at a time, release rule on the device, journal-aware). Companion: `ISLE_APP_KINDS_REFERENCE.md` (polari-instance),
`ELECTRONICS_APP_PLAN.md`, `ELECTRONICS_DISTRIBUTION_PLAN.md`. PLAN ONLY; verbs are Codex's (isle-cli), publication is mine (pol).

## 0. The rule
A device's Polari is the catalog kind `polari-instance` = an APP with an IMAGE VERSION. Bringing it to current code = publish a new version
into the isle; the device's Polari app UPDATES (pull → recreate one container at a time behind the same agent, same `<name>.isle` names →
health → journal). Members never build. Build hosts have disk and CPU (econ-core 72 GB, isle-core 779 GB), never a member's disk.
Two channels: **dev** (`pol dev deploy` → `registry.isle:5000`, versioned dev tags) and **release** (calendar tag + ReleaseManifest →
ghcr / the offline media / apt.isle — Codex's offline7 work). The device does not care which channel: it sees installed vs available.

## 1. What the installed code does today (CLI 0.1.162 + framework dev)
- `polari.sh ensure_images` pulls `prf-backend:staging` / `prf-frontend:staging` from the registry ONLY when the local tag is absent;
  `:staging` is mutable → "update available" can never be shown; the instance records no version.
- Verbs: `isle polari instance deploy | rebase | undeploy | instances`, `isle polari module move`; NO `instance update`.
  `isle-polari-deploy --pull` pulls + recreates the CORE's polari only (and refuses offline).
- `pol dev deploy backend|frontend` builds in polari-rf-node, tags `registry.isle:5000/prf-backend:staging`, pushes, then
  `ssh isle-core isle-polari-deploy --pull`. `registry.isle` does not exist yet (CX-022).
- Images on the members today: pol-core prf-backend:staging = 2026-10-20 (lacks `instruments`, osc-8, ipb-7); econ holds the 2026.09.27
  release images + an older staging set. Both are "behind" in app terms.

## 2. The target behaviour
| Step | Who | What |
|---|---|---|
| publish | `pol dev deploy` (mine) | tag `prf-backend:dev-<framework sha>` + `prf-frontend:dev-<angular sha>` (+ a moving `dev-latest`), push to `registry.isle:5000`, write the version into the catalog row `polari-instance.versions[]` (channel dev, sha, built_at, built_on, size) via the core's API |
| see | Store / devices page (mine, backend) | per instance: `installed_version`, `available_version` per channel, "Update" action with the plan (images to pull, size, containers to recreate) |
| update | `isle polari instance update [<name>] [--to <version>] [--channel dev|release]` (Codex) | pull the version → recreate backend then frontend (one at a time) → health → journal row; refuse offline unless the media carries the version; keep the previous image for rollback (`--rollback`) |
| update workers | `isle app update <tile> [--to <version>]` (Codex) | same shape for mesh-app workers (board-engines etc.), versions published by `pol dev deploy <worker>` |
| record | both | every update = a journal row (device, app, from → to, channel, who, when, result) — the same journal the isle-update notes ask for; the devices page shows it |

## 3. Slices
| # | Slice | Owner | Proof |
|---|---|---|---|
| pau-0 | `registry.isle:5000` on the core, TLS from the isle intermediate (members already trust it), `pol dev setup` sees it | Codex (`isle-registry-setup`) | `docker push registry.isle:5000/x` from pol-core works; `pol dev status` green |
| pau-1 | `pol dev deploy backend|frontend|<worker>` tags `dev-<sha>` (+ `dev-latest`), pushes, records the version in the catalog row; `pol dev status` shows installed vs available per device | Claude (polari-cli + framework catalog) | the catalog row carries two versions after one publish; selftest on the row shape |
| pau-2 | `isle polari instance update` (+ `--rollback`, `--channel`), journal row | Codex (isle-cli polari.sh) | `polari-pol` goes from dev-A to dev-B with the agent untouched; `.isle` names keep answering; rollback restores A |
| pau-3 | `isle app update <tile>` for workers | Codex | board-engines on econ updated; binding still resolves |
| pau-4 | Store / devices page: installed vs available + Update action + journal | Claude (backend/page) + Codex (store UX) | a user on any device sees "Polari (polari-pol): dev-A → dev-B available" and the journal after |
| pau-5 | release channel parity: a calendar release published through the same catalog versions (ghcr + offline media), `isle polari instance update --channel release` | Codex + Claude | one release update on a member from the media, offline |

## 4. Decisions for him
- **D-pau-1** dev tag form: `dev-<sha>` + moving `dev-latest` (recommended) vs date tags.
- **D-pau-2** rollback depth: keep one previous image per instance (recommended; disk) vs N.
- **D-pau-3** who may trigger an update on a member: the device's owner at the device (sudo), or the core operator remotely? Recommended:
  at the device, with the core able to PUBLISH only (matches the posture rules).
