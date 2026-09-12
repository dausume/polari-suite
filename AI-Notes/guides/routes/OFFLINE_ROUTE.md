# Offline: the same routes without the internet

Every route has an offline form. What changes is where the pieces come from.

| piece | online | offline |
|---|---|---|
| installer | downloaded from a server or the releases page | carried on media: `polari-complete-offline`, which bundles the container images |
| container images | pulled from the public registry | loaded from the tarballs inside the offline installer |
| modules | fetched from their GitHub repositories on admission | the module's offline deb, with its Python wheels bundled |
| system dependencies | from the distribution's repositories | from the offline media, or the isle's apt mirror |
| updates | a pull profile on a cadence | a new release pool copied over |

On an isle, the isle's own apt repository and app store serve members without any of them reaching the internet, so one machine with a release pool supplies the rest.

The server route is the one exception: a public site needs the internet by definition. Everything else, desktop, automated and AI-driven, works from a release pool.
