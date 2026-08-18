# Polari over the home wifi — what to try when you get home

**Date:** 2026-08-10 · **Scope: LAN ONLY.** Nothing here is published to
the internet, and that distinction is deliberate — see §4.

Everything below is live right now on **pol-core (192.168.0.210)** and
verified from the box. What is *not* verified is a real second device,
because that is the part only you can do.

## 1. The two scopes, kept apart

These are different problems and this document only closes the first.

| | **LAN / wifi (this doc)** | **Internet (not this doc)** |
|---|---|---|
| who can reach it | any device on the home wifi | anyone, anywhere |
| DNS | `nip.io` — public DNS that resolves a name to the IP baked in it, so no isle DNS and no `.isle` involved | a real domain you own |
| the address | `prf.192.168.0.210.nip.io` — a **private** address; useless off the LAN | a public name pointed at your WAN IP |
| TLS | self-signed Polari Root CA — you install it once per device | a real cert (Let's Encrypt) |
| router | nothing to change | port-forward 443 + dynamic DNS |
| gating | Keycloak login | Keycloak login **plus** the exposure/allowlist work in `EXTERNAL_APPS_PLAN.md` |

The shell registration document records which of these an instance is,
in the schema's own vocabulary: `reachability.scope` is **`local`**, not
`web`. `local` means "reachable only on this network" — so a shell can
tell you *"this lives on your home network"* rather than failing with a
generic network error when you are away.

**This is off-isle.** The device does not join the isle, has no isle
agent, no `.isle` DNS, no mesh membership. It is a plain wifi client
talking to a normal HTTPS port. That is the thing being proven.

## 2. Browser test (do this first — no Mac needed)

On a phone or laptop **on the home wifi**:

1. **Install the CA** (once per device):
   `https://prf.192.168.0.210.nip.io/root-ca.crt`
   - **iOS**: it downloads as a profile → Settings → *Profile
     Downloaded* → Install. Then, and this is the step everyone
     misses, **Settings → General → About → Certificate Trust
     Settings → enable full trust** for "Polari Root CA". Without that
     second step iOS installs it but will not trust it.
   - **Android**: Settings → Security → Encryption & credentials →
     Install a certificate → CA certificate.
   - **macOS**: open in Keychain Access → System → set to *Always
     Trust*.
2. Go to **`https://prf.192.168.0.210.nip.io`** — no certificate
   warning if step 1 took.
3. Log in. You are redirected to Keycloak at
   `auth.prf.192.168.0.210.nip.io`, and back to the app after.

Verified from pol-core with the CA trusted and no `-k`: frontend 200,
`api.../api/health` 200, and the Keycloak OIDC discovery document 200,
issuer `https://auth.prf.192.168.0.210.nip.io/realms/Polari`. The
Keycloak client `polari-frontend` accepts the LAN redirect URI and
requires PKCE (S256).

## 3. iPhone app in Xcode

Sources: **`polari-app-shell/ios`** — a complete SwiftUI + WKWebView
shell. It loads the SPA and lets the SPA's own Keycloak flow run inside
the webview, so **no new Keycloak client is needed** for this test.

On a Mac:

```sh
brew install xcodegen
cd polari-app-shell/ios && xcodegen generate
open PolariShell.xcodeproj
```

Set your signing team, pick your iPhone, run. iOS 15+.

**Point it at the LAN instance.** The app ships config-free by design
(App Store review forbids per-user binaries), so it is enrolled at
runtime from a registration document. One is generated and ready:

    polari-app-shell/config/polari-shell.lan.json

It carries the LAN URLs, the Keycloak authority/realm/client, the
embedded root CA plus its sha256 pin
(`6e7a9f33…c854caa59`), and `reachability.scope: "local"`. It validates
against `polari-shell.schema.json`, and the CA in it is the one that
actually signs what the proxy serves — checked, not assumed.

Enroll by opening a `polari://register` deep link on the device (the
same TOFU flow the desktop and Android shells use), or during
development by loading that JSON directly.

Two honest caveats, both pre-existing and documented in
`ios/README.md`: the app pins the delivered CA per instance rather than
changing device-wide trust, so the app works even if you skip §2 step 1
— but Safari will not. And iOS ITP blocks the silent-renew iframe, so
expect a re-login when the access token lapses until the
`ASWebAuthenticationSession` work lands.

## 4. What is proven, and what is not

Proven from pol-core:
- the three LAN names resolve and serve (frontend / api / auth)
- the TLS chain validates against the downloadable root CA
- the SPA's `runtime-config.json` points at those LAN names, so a
  browser is told to use them
- Keycloak's OIDC discovery is consistent and the LAN redirect URI is
  accepted, PKCE required
- the registration document validates against the shell schema

Not proven, and needs you:
- an actual second device completing an actual login
- the iOS build (needs a Mac)

Not attempted, deliberately:
- **anything over the internet.** No port-forward, no public DNS, no
  public cert. `EXTERNAL_APPS_PLAN.md` covers that, and it is gated on
  reworking the §45b door to be Keycloak-backed rather than htpasswd.

## 5. Fixed to make this work

`/root-ca.crt` did not exist. Every path returned the SPA's catch-all
`index.html` with a 200, so a phone "downloading the CA" would have
silently installed a web page. Added as an exact-match nginx location
(exact match beats the SPA catch-all regardless of order) in
`polari-rf-node/prf-proxy/nginx.staging.conf.template` and applied live.

⚠ The live proxy reads a bind-mounted `.generated/nginx.staging.conf`,
which is patched too — but if that file gets re-rendered from the
template by a build, re-render rather than hand-edit, and reload the
proxy (`docker exec <prf-proxy> nginx -s reload`).
