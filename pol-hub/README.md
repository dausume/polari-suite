# pol-hub — the Polari hub

The suite's lightweight informational front door. A **static site** (plain
HTML/CSS/JS on nginx — no build step, no runtime) that links out to the heavier
apps and hosts light [Mermaid](https://mermaid.js.org) docs, so casual/
informational traffic lands here and the intensive tools (PRF, the scorecard)
stay free for people doing serious accountability or science/engineering work.

## Contents
```
pol-hub/
  site/
    index.html          # the hub — links to PRF / DPS / Isle-Mesh / OSEB
    docs.html           # Mermaid-rendered docs (how the projects fit together)
    assets/
      styles.css        # shared styles (Material blue, Roboto, theme-aware)
      app.js            # theme persistence + the node-mesh hero
      polari-mark.png   # the dodecahedron mark
  Dockerfile            # nginx:alpine + the static site
  nginx.conf            # port 4200, /health, static caching
```

## Run it
```bash
# in the suite:
pol suite up --env staging        # builds pol-hub + serves it behind pol-proxy
```
Reachable at the apex + `www.<local-ip>.nip.io` (staging) — the proxy's landing
block points here. Locally without the suite:
```bash
docker build -t pol-hub . && docker run --rm -p 4200:4200 pol-hub
# then open http://localhost:4200
```

## How it's wired into the suite (same pattern as the other frontends)
- **Compose:** annotated source `pol-services/compose/services/pol-hub-frontend.yml`
  (included in `pol-services/compose/suite-bundle.yml`) → `pol build render --project
  suite` → `pol build promote` writes the `pol-hub` service into the three root
  `docker-compose*.yml`. A tiny service: 32 MB / 0.1 cpu, no backend.
- **Proxy:** `pol-services/proxy/nginx.staging.conf` routes the apex +
  `www.<ip>.nip.io` to `pol-hub:4200`. (Prod: mirror the same block in
  `nginx.prod.conf` — its landing stanza has a slightly different shape.)
- **Registry:** declared as `kind: pol-hub` in `pol-build/registry/services.yml`
  (so `pol registry check` passes).
- **Swarm:** rides the `suite` role automatically — no per-service swarm config.

## Notes
- The four project links in `index.html` are placeholders (`href="#"`) — set them
  to the real repo/site URLs.
- Mermaid loads from CDN in `docs.html`; for a fully offline/self-hosted build,
  vendor `mermaid.esm.min.mjs` into `site/assets/` and repoint the import.
- Fonts (Roboto, Roboto Mono) load from Google Fonts; self-host them for offline.

## Documentation section (2026-09-09)

`site/docs.html` is the index; `site/assets/docs.json` is the ONE manifest
(categories → pages) that `assets/docs.js` renders as the index and as the
sidebar on every doc page (static fallbacks stay in the HTML). Doc pages
live under `site/docs/` and load `assets/docs.css` on top of `styles.css`;
they use inline SVG and no CDN, so they render on an air-gapped isle.
Most pages are GENERATED from Markdown already in the suite by
`pol-hub/build-docs.py` (stdlib only): a manifest entry with a `source`
(path from the suite root) becomes `site/docs/<slug>.html`, with the
static sidebar and the index rewritten into every page between
`<!-- docs-nav -->` / `<!-- docs-index -->` markers. Edit the Markdown,
rerun `python3 pol-hub/build-docs.py`, commit the output (`--check` says
whether anything is stale; the generated HTML is committed because the
site has no build step). Hand-written pages (no `source`) live under
`site/docs/` and keep the same markers. To add a page: add its manifest
entry (and, for a hand page, the file), run the script. nginx keeps every
`.html` and `.json` `no-store` by one pattern rule. Six categories today:
Start here, Install, Networking and topology, Running an isle, Building
modules and apps, Reference — 31 pages, 28 generated.
