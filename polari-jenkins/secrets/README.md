# secrets/ — the ONLY place auth material lives; git never sees it

Rules:
- One secret = one file; the FILE NAME is the variable name Configuration
  as Code reads (`${github_token}` ← `secrets/github/github_token`). No
  extension, no newline problems (trailing newline is stripped by Jenkins).
- Mode 0600, owned by the host user running `pol jenkins`. `pol jenkins
  status` lists which files exist — never their contents.
- `*.example` files document the FORMAT and are committed; the real file
  sits beside them and is gitignored (`secrets/**` in .gitignore, plus the
  suite's root `*.key/*.pem/*.gpg` rules as a second net).
- Rotation = replace the file, `pol jenkins restart`. Write the date in
  `ROTATION.log` here (that file is gitignored too).

| directory | file | used by |
|---|---|---|
| admin/ | jenkins_admin_password | the local admin login (no anonymous access) |
| github/ | github_token | routes/github-release.sh (scope: repo → releases) |
| github/ | github_ssh_key | optional: pushing tags/branches via ssh |
| registries/ | ghcr_token | routes/ghcr.sh (write:packages) |
| registries/ | dockerhub_user, dockerhub_token | routes/later/dockerhub.sh (PARKED) |
| signing/ | apt_signing_gpg, apt_signing_keyid | routes/apt-repo.sh (armored private key + its key id) |
| signing/ | cosign_key, cosign_password | image signing in ghcr.sh / dockerhub.sh |
| packaging/ | npm_token | routes/later/npm.sh (PARKED) |
| packaging/ | pypi_token | routes/later/pypi.sh (PARKED) |
| packaging/ | snapcraft_login | routes/later/snap.sh (PARKED) (exported login) |
| packaging/ | launchpad_ssh_key | routes/later/launchpad.sh (PARKED) (dput over sftp) |
| ssh/ | distribution_host_key | routes/apt-repo.sh rsync to the distribution VM |
