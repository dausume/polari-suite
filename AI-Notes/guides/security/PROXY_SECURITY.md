# Proxy security

> **Status, 2026-09-12: designed and prototyped, not deployed.** The controls on this page exist as templates, scripts and plans in the repository. None of them is applied on the production server or on any isle unless an operator runs them by hand, and several pieces are still plans. Security is the next thing being built; the honest state of each piece is at the end of the page.

Every request into Polari passes through exactly one nginx, and that nginx is the policy. There are two of them, one per world, and they do not share code.

## The isle agent's nginx

On an isle, each member device runs an agent whose nginx is the sole ingress for that device's apps. Its configuration is generated from the agent's registry of apps: for each app, which services exist, on which subdomain, over which protocol. Polari reads those generated proxies back as the **protocol matrix**, so what is allowed is exactly what the proxies say and nothing can drift.

- Names end in `.isle` and never leave the isle; the router serves them, and the agent answers only for names it registered.
- TLS 1.2 and 1.3 only, with leaves issued by the isle's own certificate authority, which every member trusts once at join.
- Three protocol classes per app: `http`, `https`, and `https-mtls`, where the client must present a certificate from the isle CA. The matrix shows which each app permits.
- Frame, content-type and legacy XSS headers are set; nothing is proxied that the registry does not name.

**Doors to the outside.** Exposing an app never moves it. `isle url expose` starts a small gateway container that publishes one port on the device and proxies into the agent with the internal name, admitting exactly one credentialed person by basic auth. The device must first be designated an entrypoint, and the security gate must pass. Closing the door removes the container. One known gap, tracked in the hardening plan: the door speaks plain HTTP on its outside leg, so the credential travels unencrypted until the gateway terminates TLS itself; until then, open doors only across a VPN or a trusted network.

## The suite's proxy

On a server (lean or full profile) and under compose, `pol-proxy` is plain nginx with one template per environment, rendered by `pol proxy template` and shipped to the swarm as a config with the certificate as secrets.

- One certificate covers every hostname the proxy terminates: five names on the lean profile, eleven on the full one. Provider-issued and auto-approved through Let's Encrypt, or signed by the suite CA until then; the status board says which.
- TLS 1.2 and 1.3, modern ciphers, server preference, session tickets off, HSTS once the certificate is publicly trusted.
- Security headers on every response: no framing, no content-type sniffing, a strict referrer policy.
- Every upstream is resolved lazily by name, so the proxy boots before every service exists and never hard-codes an address.
- Request size limits per host; rate limits on the download and API paths so an on-demand deb build cannot be used to exhaust the machine.
- Port 80 serves only the ACME challenge path and a redirect. Everything else is on 443.
- The backend's API host handles CORS preflight at the proxy, for the frontend's origin only.
- The apt repository host serves a static tree, nothing executes.

`pol proxy guard <env>` refuses a template with static upstreams and runs the nginx configuration test with the certificate and CA mounted before anything deploys.

## What the proxy does not do

It does not authenticate users; Keycloak does, on the full profile only. It does not inspect application payloads. It does not reach the internet on an isle. And it is itself confined: the proxy runs under its own AppArmor profile with no capabilities beyond binding its ports, a read-only filesystem, and a seccomp allow-list for a gateway.

## Where it stands

The suite proxy's hardening (TLS versions and ciphers, security headers, rate limits, HSTS once the certificate is public) is real and running on the production server. The isle agent's proxy behaves as described. Per-app proxy snippets, the security interface for proxies, and content policies are designed, not built.
