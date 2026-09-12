# The server route: a public site from a browser console

A person with a domain and a small virtual machine, and no wish to learn ssh.

## The whole thing

1. In your hosting provider's website (DigitalOcean is the one the guide knows best), attach a reserved IP to the machine and open its browser console.
2. Paste one line:

```
curl -fsSL https://raw.githubusercontent.com/dausume/polari-suite/main/get-polari.sh | bash
```

3. Answer the guided screens.

That is the route. The line installs what the command line needs, docker, the Polari code, and the `pol` command, then opens the full-screen guide. The guide asks in order: the vault for generated credentials, user logins, the domain, the address the internet reaches you at, the names and their DNS records, the certificate, the images, the installers to hand out, and the demonstration notice. Every step checks itself before the next. Apply streams what it does, and every run is logged for review.

The [production server guide](production-server.html) describes each screen in detail. Two decisions are worth knowing before you start:

- **Publicly trusted certificate.** Choose Let's Encrypt. It is free, automatic, and every browser trusts it. It needs the DNS records in place first, and the guide shows which are missing and how to add them at your DNS host.
- **Images.** Pull the published release from the official registry. The guide lists the tags the registry actually has. The `core` variant is the default; the `all-official` variant carries every module.

Afterwards, in the same console: `pol prod status`, `pol prod cert`, `pol prod verify`, `sudo pol security vault show`.
