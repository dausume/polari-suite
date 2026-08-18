# Getting Started — polari development

From nothing to a working development machine + a running isle with
polari on it, using ONLY this repository. Every sub-project (polari,
the political scorecard, the app shells, isle-mesh) lives inside the
suite — one clone carries everything.

Security note up front: **no credential ships in this repo or in any
deb built from it.** All security material (passwords, domain, certs)
is put in AT DEPLOY TIME by the walkthrough (`isle security setup` /
`pol security`), which runs as the last step of the isle install.

## 0. Prerequisites

- Linux with `git`, `bash`, `curl`, and Docker (with the compose
  plugin). For hosting an isle core you also need `libvirt`/KVM
  (the isle router runs as a small VM) — the installer checks and
  names anything missing.
- Optional: GitHub auth if you need the private `polari-app-shell`
  sub-project (native app shells). Everything else is public; the
  bootstrap skips it gracefully without auth.

## 1. Clone the suite and pull everything (piece-wise)

    git clone https://github.com/dausume/polari-suite.git
    cd polari-suite
    ./bootstrap-dev.sh

`bootstrap-dev.sh` pulls every sub-project and lands each on its `dev`
branch. It is piece-wise: `./bootstrap-dev.sh --list` shows the pieces;
name one (e.g. `./bootstrap-dev.sh Isle-Mesh`) to pull only what you
need. At the end it offers to install the `pol` CLI — say yes
(everything below uses it; `pol help` is always current).

## 2. Build the polari images from code

    pol node build backend frontend

This builds the polari backend (Python/Falcon) and frontend (Angular)
container images from the `polari-rf-node` sub-project. The isle's
lean polari instance (next step) deploys these exact images.

## 3. Build + install the debs (the normal debian route, from code)

    ./build-polari-isle-deb.sh
    sudo apt install ./.generated/debs/isle-mesh-cli_*_all.deb \
                     ./.generated/debs/isle-app-store_*_all.deb \
                     ./.generated/debs/polari-isle_*_all.deb

Three packages, all built from the checkout you just cloned:
- `isle-mesh-cli` — the `isle` command (agents, router, DNS, store
  plumbing, the versioned `polari-isle/` deployment sub-project)
- `isle-app-store` — the native app-store shell
- `polari-isle` — the meta-package bundling both (this is the same
  single-download bundle the public site serves)

## 4. Stand up your own isle (single-device isles are first-class)

    sudo isle core-install

One idempotent flow: isle networking (router VM + agent) → the isle CA
trusted locally → the lean polari deployed behind the agent (seeded
from the versioned `polari-isle/` sub-project) → the store shell →
apt-on-mesh (so OTHER devices install everything over the mesh) → a
verify pass → **the production-security walkthrough** (generic
self-hosting first; provider-specific steps as a post step). It ends
by printing the JOIN INFO another device needs to join your isle.

Then open https://polari.isle — the isle hub — and the "Isle App
Store" application. The membership rule: the running agent IS
membership; the store installs apps only on isle members.

## 5. Or: run the polari node directly (no isle)

The standalone development loop, no isle required:

    pol security setup            # deploy-time credentials (prompted)
    pol node up --env dev         # or test | staging | prod
    pol node logs backend

`pol suite up --env staging` runs the combined suite (polari + the
political scorecard + shared services). Run ONE of node/suite at a
time — they share container names. `README.md` is the authoritative
build/run/test guide from here.

## 6. Day-to-day development

- Each sub-project is a git repo on `dev`: edit, commit inside the
  sub-project first, then commit the suite's pointer (innermost-first).
- `polari-cli/shells/push-all-dev.sh` dry-runs the publish state of
  the whole forest; `--with-isle --push` publishes it (submodules
  before superprojects, artifact + pointer-coherence guards).
- Rebuild + redeploy the lean isle polari after backend changes:
  `pol node build backend && isle-polari-deploy`
- Credential hygiene at any time: `isle security creds` (inventory),
  `isle security gate` (deploy check — web exposure refuses to open
  while it fails), `isle security setup` (the walkthrough).
