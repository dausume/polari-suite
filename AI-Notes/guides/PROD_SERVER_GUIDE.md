# Setting up a production server

Polari has two production routes. Pick by who is doing it.

| Route | Who | How |
|---|---|---|
| **A home computer, for people** | Anyone | Install the `polari-complete` deb, open **Isle App Store**, choose **Create my own isle**. The store runs the guided isle install in a window. Nothing else. |
| **A server (a small VM or your own swarm)** | Developers, or an AI assistant driving a terminal | `pol prod guide` — one walkthrough with menus, then it deploys. |

This page is the server route. It deploys one of two profiles, both as a docker swarm stack:

- **Lean** (logins off, the default): the site and documentation, the download page and apt repository, and one Polari backend with the floor set of modules, on SQLite, with no login server. The public distribution point; runs on a $12-class VM. Four services.
- **Full** (logins on): the lean set plus Keycloak logins, MariaDB, the MinIO file store, the Democratic Political Scorecard, and optionally Odoo. Eleven public names, about 7 GB of declared memory limits. Its credentials are generated at apply time, never typed defaults.

On a fresh VM start with `pol prod bootstrap`: it installs docker if missing, initialises the swarm, and opens the guide.

## One command

```
pol prod guide
```

The guide asks, in order, and remembers every answer in `.generated/prod-answers.env`:

1. **Which route** — server (this) or home computer (it tells you where to go instead).
2. **Domain** — the public name. It shows where each of the five names resolves right now (`example.org`, `www.`, `prf.`, `api.prf.`, `apt.`) against this host's public address, so you can fix DNS before anything is issued.
3. **HTTPS certificate** — two doors:
   - **Provider-issued, auto-approved** (Let's Encrypt): one certificate for all five names, trusted by every browser, renewed weekly. Verified either by an HTTP challenge through this server's port 80 (any registrar, nothing to configure) or by a DNS challenge through the DigitalOcean API.
   - **Auto-generated**: signed by the suite's own certificate authority. Works immediately; browsers warn until that root is imported. You can switch to the provider door later with `pol prod cert`.
4. **Logins** — none (the lean profile, the default) or Keycloak (the full profile). With Keycloak the guide also asks whether to deploy Odoo.
5. **Modules** — the floor set (`polariapps, appstore, islemesh, terms`); add more at the cost of memory.
6. **Installers** — build the platform debs here, copy them from a release pool, or skip for now. The Download page lists whatever is staged.
7. **Demonstration notice** — whether the apps show the "no personal information" bar and the terms gate.
8. **Images** — a registry prefix to pull the release images from (for example `ghcr.io/dausume/`), or empty to build them on this machine from the checkout, and the image tag.

Then it shows the plan and asks once whether to apply.

## What apply does

Every step is idempotent, so re-running after a fix is safe.

1. Preflight: docker, swarm manager, ports 80 and 443 free, images present, DNS, certificate, staged debs, apt signing key.
2. Writes the inputs: `.generated/.env.lean`, the frontend and hub runtime configs, `nginx.lean.conf`.
3. For the full profile, runs the security setup once: the suite's certificate authority, the Keycloak certificate and admin, random database and file-store credentials.
4. Stages the edge certificate: the Let's Encrypt pair when issued, else one signed by the suite CA for every name the profile serves (five for lean, eleven for full).
5. Stages the installers per your answer.
6. Pulls the release images from the registry, or builds them locally with compose; the hub image carries the site and its documentation, so any swarm node can run it.
7. Renders the stack from the profile's compose file (`docker-compose.lean.yml` or `docker-compose.prod.yml`) and deploys it as `polari-lean` or `polari-prod`. Configuration and the certificate travel as docker configs and secrets; the debs, apt tree and ACME webroot are directories on the manager, where the proxy and backend are pinned.
8. If you chose the provider certificate, issues it now (the HTTP challenge needs the proxy up), re-deploys with the new secret, and installs weekly renewal.
9. Prints the status board.

## Unattended

Every answer is also an environment variable, which is how a script or an AI assistant drives it:

```
POL_PROD_DOMAIN=example.org POL_PROD_CERT_MODE=letsencrypt POL_PROD_LE_CHALLENGE=http \
POL_PROD_LE_EMAIL=ops@example.org POL_PROD_DEBS=build pol prod apply --yes
```

`pol prod plan` prints what apply would do without changing anything. `pol prod check` is the preflight alone.

## One access point, several machines

The proxy runs on the manager and is the only entry point. It reaches every other service by name over the swarm's overlay network, wherever that service was placed, so adding machines does not change the proxy. With locally built images every service stays on the manager (only it has the images); with a registry prefix the services may spread across nodes. An isle is a different world: there the isle agent's own nginx fronts Polari as `polari.isle`, and nothing here touches it.

## Opening and closing an isle to the outside

An isle has its own, smaller version of "production": one door at a time, one person per door, and the isle's names never leave. From a terminal on the isle's core device:

```
sudo isle url entrypoint enable                              this device may open doors
sudo isle url expose polari.isle --port 18443 --user alice   a door to Polari, basic auth at the door
isle url exposures                                           what is open
sudo isle url unexpose --port 18443                          close the door
sudo isle url entrypoint disable                             back to fully contained
```

The door refuses to open until the device is designated and its deploy-time credentials pass the security gate. Closing it removes the gateway container; nothing inside changes.

## On a DigitalOcean droplet

The droplet tells the server its own addresses. `pol prod addresses` reads DigitalOcean's metadata service (nothing to configure, no token) and lists the public IPv4, the public IPv6 if enabled, the reserved IP if one is attached, and the private VPC address. The **exposure address** is the one every DNS A record must carry: the reserved IP when there is one, else the droplet's public IPv4.

Attach a reserved IP before you set DNS. A wiped and rebuilt droplet gets a new public address; a reserved IP stays yours and follows the rebuilt droplet, so the records never change. The guide warns when none is attached and links to the page.

The detected address is a suggestion. The guide asks whether to keep it or to type the address you know is right, for the cases where the machine sees the wrong one or the address is about to change. `pol prod addresses --use <ip>` records your answer at any time; `--auto` goes back to detection. The preflight and the status board say which one is in use.

If a DigitalOcean cloud firewall is attached to the droplet it must allow inbound 22, 80 and 443; the host firewall itself is rendered by os-security.

## Providers, and where to go

`pol prod providers` shows which provider fills which role for this deployment, hosting, DNS, certificate, registry and code, with the pages to visit for each. The guide shows the same links at the step where they matter: the DNS page where the A records are set, Let's Encrypt's rate limits and status before a certificate is requested, and the API token page when the DNS challenge is chosen. Provider credentials are never typed into the guide, except the DNS-challenge token, which is read from the environment and never written down.

## Credentials and the vault

Nothing the guide generates is left for you to protect by hand. On the full profile the Keycloak admin, the database passwords and the file-store keys are generated once, at random, and recorded in an encrypted, root-only vault at `/etc/polari/vault`. Read it with `sudo pol security vault show`; nothing in it is ever printed to a log.

At the start the guide tells you this and asks one rule for **provider** credentials, the ones you bring yourself, such as a DigitalOcean API token for the DNS challenge: stash all of them in the vault, ask for each one, or none. A stashed token is reused on the next run, so you are not asked twice. The advice stays the same either way: record provider credentials in your own password manager and remove them from the vault afterwards with `sudo pol security vault forget 'provider <name>'`. `pol security status` reminds you while any are stashed.

When apply finishes the guide asks what to do with the vault: keep it here, show everything once so you can write it down and then shred it, or export it (with its key, kept apart) to a path you choose and shred the local copy. Unattended runs keep it.

The vault protects against anyone external: a copied disk, a backup, another user, a tarball of the checkout. It does not hide values from the account that runs the deployment, which is deliberate while the setup is being iterated on; an off-machine-key mode exists for later.

One more thing the vault fixed: credential files that still carry placeholder values are no longer reused. Apply moves them aside, generates real ones, and tells you that a database volume created with the old values has to be recreated.

## From another machine

`pol deploy` drives machines listed in the nodes manifest over ssh:

```
pol deploy tier <node> --check                              what it qualifies for (member, hardware)
pol deploy tier <node> hardware                             label it; needs KVM + libvirt on the target
pol deploy install <node> --route swarm-worker              join this swarm
pol deploy install <node> --route swarm-server --domain D   a standalone production server there
pol deploy install <node> --route isle-member [--host]      join this isle (sudo on the target)
pol deploy install <node> --route isle-core [--yes]         ship the deb and run the isle install (unattended with --yes)
pol deploy status <node>                                    what runs there, either route
pol deploy uninstall <node> --route … [--yes]               the reverse; the isle wipe needs --yes
```

The app route is meant for people through the Isle App Store, but every step of it is also a terminal command, so a developer or an AI assistant can install, check and remove an isle over ssh.

Add `--dry-run` to see the exact commands first.

Root on the target is the one thing ssh cannot supply. Two permission groups make it unnecessary after a single setup:

```
pol deploy grant <node> --group remote     ssh + swarm + AI-assisted setup: exactly the commands pol deploy sends, no password
pol deploy grant <node> --group app        the app-setup route: what the Isle App Store's doors run for a person
```

The first grant needs a password once (the command prints the one line to run). The two groups are separate on purpose: a machine set up for people gets `app`; a machine an operator or an assistant drives remotely gets `remote`.

## Afterwards

```
pol prod status        stack, services, certificate issuer and expiry, DNS, health, terms gate
pol prod cert          issue or re-issue the provider certificate
pol prod debs build    (re)build and stage the installers
pol prod down          remove the stack; the data volume stays
```

The status board says plainly when the certificate is not yet publicly trusted, and what to run.

## What is still yours

- Point DNS at the server before choosing the provider certificate.
- The apt repository is served from `.generated/apt`; publishing into it needs the signing key, which lives with the build pipeline's secrets.
- The full profile's Keycloak credentials are generated by the security setup on first apply; rotate them with `pol security rotate prod` before the server faces the internet, and keep the generated env file private.
- The old `start-prod.sh` and `prod-setup.sh` still exist but only hand over to `pol prod`.
