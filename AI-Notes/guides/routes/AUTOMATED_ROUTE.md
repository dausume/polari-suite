# The automated route: scripts, swarm, ssh, CI

Everything the guided screens ask can be answered in advance, so the same deployment runs unattended, from a script, a CI job, a swarm manager, or another machine over ssh.

## Answers as environment

Every answer is a `POL_PROD_*` variable. With them set, apply asks nothing:

```
POL_PROD_DOMAIN=example.org POL_PROD_AUTH=keycloak POL_PROD_CERT_MODE=letsencrypt \
POL_PROD_LE_EMAIL=you@example.org POL_PROD_IMAGE_REPO=ghcr.io/dausume/ \
POL_PROD_IMAGE_TAG=polari-v2026.09.12-core POL_PROD_DEBS=release:polari-v2026.09.12 \
pol prod apply --yes
```

The answers file the guide writes, `.generated/prod-answers.env`, is the same thing in a file; a script can write it and run apply. `pol prod plan` prints what apply will do without doing it. `pol prod facts` prints the machine's state as JSON for a script to decide from.

## Remote machines over ssh

Machines are rows in `nodes.yml`. From one machine, `pol deploy install <node>` puts a Polari instance on another, `pol deploy status <node>` reports it, `pol deploy tier <node> hardware` raises it to the hardware tier, `pol deploy audit <node>` runs the security audit there, and `pol deploy uninstall <node>` removes it. Two permission groups keep this bounded: `polari-remote` for ssh, swarm and AI setup; `polari-app` for app installs.

## Swarm

Production is a docker swarm. `pol prod apply` initialises the swarm if needed and deploys the profile as a stack; `pol swarm` manages a multi-node swarm; images are pulled by every node from the registry, so services may spread. A multi-node deployment needs the registry, since only the manager has locally built images.

## CI

The host-tier Jenkins polls GitHub, builds and publishes on merge to main, and runs throwaway-VM tests. Nothing inbound is ever opened; every machine pulls.

## Offline

An automated deployment can be fed from a release pool instead of the internet: installers copied from a directory, images loaded from a tarball, wheels bundled in the offline module packages. The pull profile decides which.
