# secrets/ — the ONLY place auth material lives; git never sees it

## Where they actually live (ci-7, his ask 2026-09-19)

> "the secrets involved in it are only accessible via either sudo or the
> pipeline process itself, never a third party."

There are two postures. `pol jenkins doctor` always says which is in force.

| posture | directory | owner/mode | who can read a secret |
|---|---|---|---|
| **system** (wanted) | `/etc/polari-jenkins/secrets` | dir `root:polari-ci 0750`, files `root:polari-ci 0640` | **root** (a person who typed `sudo`) and the **`polari-ci`** system user the controller runs as. Nobody else. |
| repo (fallback) | `polari-jenkins/secrets/` | host user, `0600` | **every process of that user** — a browser extension, an `npm postinstall`, any script they run. Git still never sees it, but that is not the same as protected. |

Get the first one with:

```
sudo pol jenkins init-device      # creates polari-ci, /etc/polari-jenkins/secrets,
                                  # MOVES anything already in this directory there,
                                  # chowns jenkins_home/ + pool/, writes JENKINS_UID/GID
```

After that `docker-compose.yml` runs the controller as `polari-ci` and
mounts `/etc/polari-jenkins/secrets` at `/run/secrets:ro`. The directory
below keeps only `*.example` files and this README.

⚠ The `docker` group is **root-equivalent** on a machine with a docker
socket. `polari-ci` is in it because the jobs build images; the doctor
lists everyone else who is in it and warns when that is more than one
admin. Do **not** put the interactive user into the `polari-ci` group —
that would hand every process they run exactly the access this posture
exists to prevent, and the doctor's readability test says so.

## Handling

```
pol jenkins secrets put github/github_token    # value from stdin, never a shell argument
                                               #   (no history, no ps, no log)
pol jenkins secrets status                     # names only, plus which routes are ARMED
pol jenkins secrets rm  github/github_token
pol jenkins restart                            # the controller re-reads them at boot
```

- One secret = one file; the FILE NAME is the variable Configuration as
  Code reads (`${github_token}` ← `github/github_token`). No extension.
  A trailing newline is stripped by Jenkins.
- `controller/entrypoint.sh` flattens `<area>/<name>` into one private
  directory at boot and logs the NAMES only — `pol jenkins logs` never
  shows a value.
- `*.example` files document the FORMAT and are committed; the real file
  sits beside them and is gitignored (`secrets/**`, plus the suite root's
  `*.key/*.pem/*.gpg` rules as a second net).
- Rotation = replace the file, `pol jenkins restart`. Write the date in
  `ROTATION.log` here (gitignored too).

## What a missing secret does — nothing breaks, the route just stays DRY

`DRY_RUN=auto` (the default since ci-7) arms a route only when **both**
hold: its secret is present **and** the route is named in `CI_ROUTES`
(`polari-jenkins/device.env`). Every route prints its state as its first
line — `ARMED` · `DRY (secret <name> absent)` · `DRY (not in CI_ROUTES)` —
and `pol jenkins doctor` shows the same table before anything runs.

| directory | file | used by |
|---|---|---|
| admin/ | jenkins_admin_password | the local admin login (no anonymous access) |
| github/ | github_token | routes/github-release.sh + routes/homebrew.sh, and the **release tag push** (`contents:write`) |
| github/ | github_ssh_key | optional alternative for the tag push |
| registries/ | ghcr_token | routes/ghcr.sh (`write:packages`) |
| registries/ | dockerhub_user, dockerhub_token | routes/later/dockerhub.sh (PARKED) |
| signing/ | apt_signing_gpg, apt_signing_keyid | routes/apt-repo.sh (armored private key + its key id) |
| signing/ | cosign_key, cosign_password | image signing in ghcr.sh / dockerhub.sh |
| packaging/ | npm_token, pypi_token, snapcraft_login, launchpad_ssh_key | routes/later/* (PARKED — not declared to Jenkins) |
| ssh/ | distribution_host_key | routes/apt-repo.sh rsync to the distribution VM |

⛔ The apt route's secrets wait for the Keycloak rotation before that host
faces the web (`routes/apt-repo.sh:2`).
