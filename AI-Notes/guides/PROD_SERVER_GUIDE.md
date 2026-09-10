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
