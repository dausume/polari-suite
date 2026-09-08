# routes/later — PARKED (his rule 2026-09-07: "for now we only do things we can do without needing authorization from any kind of authority")

Every route here needs an account, org, review or key issued by an outside
party before it can push. They are written and dry-runnable, not wired:
| route | the authority it waits on |
|---|---|
| dockerhub.sh | a Docker Hub org/account + access token (D9) |
| npm.sh | the `@polari` npm org + automation token |
| pypi.sh | a PyPI project name + API token |
| launchpad.sh | a Launchpad team, PPA and registered signing/ssh keys; debhelper source packaging (ci-6b) |
| snap.sh | a Snapcraft developer account AND Canonical's classic-confinement review (D10) |
Active routes (ours alone): `github-release`, `apt-repo` (our VM), `ghcr`
(GitHub packages on the account we already hold), `homebrew` (a tap is a
git repo we own). Moving a route back = `git mv` it up one level, add its
credential to `casc/jenkins.yaml` and its entry to `Jenkinsfile.publish`.
