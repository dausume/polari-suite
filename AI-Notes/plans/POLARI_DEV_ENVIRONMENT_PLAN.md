# Polari development environment (de arc): in-browser or VS Code-class editing, existing extension ecosystem, licence-clean, as a Polari app — PLAN

**Date:** 2026-09-09 · **Status: PLAN (de-0).** His framing: "plan out a way
to do software development for Polari in-browser or in VS Code (or a more
open source equivalent), ideally something that can use the broad range of
already existing coding modules, but also be made accessible through Polari
with compatible licensing and be made into an app."

Companions: POLARI_DEV_TOOLS_PLAN (the rules/linter/scaffolds this editor
runs), STANDARD_POLARI_APP §7/§9 (the module shape the editor helps write),
the suite-app design (this becomes a suite: an editor container + our
extension + a notebook container + the dev-tools module).

## 1. The candidates (licences to be VERIFIED three ways at pin time — the gate rule)
| candidate | what | licence (claim) | extensions | offline | fit |
|---|---|---|---|---|---|
| **code-server** (coder/code-server) | VS Code (Code-OSS) served in the browser | MIT | Open VSX (Microsoft's marketplace ToS forbids non-Microsoft products) | yes: extensions pre-installed in the image | 🟢 the direct answer to "in-browser VS Code" |
| **OpenVSCode Server** (gitpod-io) | the same idea, closer to upstream Code-OSS | MIT | Open VSX | yes | 🟢 alternative; fewer opinions than code-server (no password auth built in) |
| **Eclipse Theia IDE** | an IDE platform (browser + desktop) that runs VS Code extensions; can be a custom product | EPL-2.0 OR GPL-2.0-w/-Classpath-exception | Open VSX | yes | 🟢 the "more open source equivalent"; the right base if we ever want a Polari-branded IDE rather than VS Code-in-a-box |
| **VSCodium** | desktop Code-OSS binaries without Microsoft telemetry/branding | MIT | Open VSX | n/a (desktop) | 🟢 the desktop twin: same extensions, same settings checked into the repo |
| **Open VSX** (eclipse/openvsx) | the extension registry | EPL-2.0 (registry); extensions carry their own licences | — | mirror pinned extensions into the offline medium | 🟢 required; we never point at Microsoft's marketplace |
| **JupyterLab** | notebooks (the research side; `~/Desktop/self-hosted-jupyter-notebooks` already exists) | BSD-3 | — | yes | 🟢 the second container of the suite |
| Eclipse Che | workspace orchestration on Kubernetes | EPL-2.0 | Open VSX | heavy | 🟡 too big for an isle; Theia/code-server cover it |
| Microsoft VS Code binaries, Pylance, C#/Remote dev packs | proprietary | ✗ | — | — | 🔴 never; Pyright (MIT) replaces Pylance, jdtls (EPL) replaces the Java pack's proprietary bits |
Compatibility: MIT and BSD combine with GPLv3 trivially; EPL-2.0 does not
combine by linking but every editor here is a SEPARATE PROCESS in its own
container talking to Polari over HTTP — the process boundary that already
settles Reticulum/Renode/ngspice. Our own extension is ours (GPLv3), which
is fine for a VS Code extension (extensions are independent programs).

## 1b. His ruling (2026-09-09): VS Code-first, usable independently OR through Polari
"The point is to find the candidate that can be used with Polari or
independently (like VS Code since many people use it already) and to
develop out the dev tool so it is compatible with that and we can leverage
it as much as possible." So the ORDER inverts: the primary deliverable is
the **Polari extension + dev-tools working in stock VS Code** on anyone's
laptop (no isle required: it talks to any Polari instance URL, or works
offline on a checkout with the linter/scaffold), and the in-browser
`polari-code` isle-app is the SAME extension served by code-server for
people who do not install anything. One extension, four hosts: VS Code,
VSCodium, code-server, Theia (all run VS Code extensions). Distribution:
our extension is published to BOTH the VS Code Marketplace (publishing our
own extension there is allowed; only CONSUMING that marketplace from
non-Microsoft products is forbidden) and Open VSX — a ci-6 route pair.
The extension leverages what people already have: their VS Code, their
Python/Java/Angular extensions, git — the dev-tools add the Polari-specific
parts (rules, scaffolds, object tree, admit) and nothing else.

## 2. Recommendation
**de-1 = code-server as the isle-app `polari-code`** (fastest path to "VS
Code in the browser through Polari"), with **Theia kept as the platform
option** (de-6) if we later want a Polari-branded IDE or the desktop/browser
single codebase. Both consume the same Open VSX pins and the same Polari
extension, so the choice is not a lock-in.

## 3. The app shape (a suite: `dev-environment`)
- **`polari-code`** (isle-app container, `code.isle` behind the agent): the
  code-server release at a pinned version; extensions pre-installed from
  Open VSX at pinned versions (Python + Pyright, Java jdtls, ESLint, Angular
  language service, Docker, GitLens-class git, YAML, Mermaid, Jupyter
  client); the workspace = the Polari checkout mounted read-write from the
  member's `~/polari-suite` (bootstrap-dev.sh idiom) with `pol`, the
  dev-tools (`pol dev lint|new|admit`) and the module scaffold on PATH; a
  terminal that is the host user's shell (UID/GID mapped — the root-artifact
  rule). Auth: behind the isle proxy with Keycloak OIDC (one login for
  Polari and the editor); code-server's own password auth is the
  no-Keycloak fallback for a lean isle.
- **`polari-notebooks`** (isle-app, `lab.isle`): JupyterLab at a pinned
  version, the same mounted checkout, kernels with the framework on
  `PYTHONPATH` (the sim/msci research workflow), notebooks stored as rows'
  attachments in the object store.
- **The Polari extension** (`polari-vscode`, our repo, GPLv3): the object
  tree (CRUDE) as a side-bar view; `polari-app.json` schema validation +
  the dev-tools linter rules (PA-xxx) as diagnostics (the linter's JSON
  output); commands: new module, add object, conform, admit to my instance,
  open this row's page; a status item showing which instance the workspace
  is bound to (`POLARI_API`). One extension, both editors, plus VSCodium.
- **`.vscode/` in the repo**: `extensions.json` with the Open VSX ids,
  `settings.json` (Pyright config, the framework PYTHONPATH roots
  `polari-framework` + `polari-framework/modules`), tasks that call `pol`.
  Same on desktop (VSCodium) and in the browser.
- **No-code round trip** (dt-2/dt-3): a module generated by the no-code side
  opens in the editor as the scaffold's shape; `pol dev admit` brings hand
  edits back onto the running instance.
- **Offline**: the images and the pinned extensions (.vsix) go into the
  medium's `engines/` section like the Reticulum sidecar; nothing fetches at
  runtime.

## 4. Phases
- **de-1 (moved first) the Polari extension for stock VS Code** (`polari-vscode`,
  TypeScript, GPLv3 or MIT per D5): workspace detection (a Polari checkout
  or a single module dir), `polari-app.json` schema + linter diagnostics
  (dt-1 JSON), commands new-module / add-object / conform / admit-to-instance
  (runs `pol dev …` or the framework's python directly), the object tree
  view against `POLARI_API`, a status item for the bound instance; packaged
  as .vsix; published to Open VSX + the VS Code Marketplace (ci-6). Proof:
  install the .vsix in VS Code on this box, open the checkout, see
  diagnostics for a deliberately broken module, scaffold a module, admit it
  to the test build.
- **de-2** `polari-code`: Dockerfile from the pinned code-server release +
  pinned Open VSX extensions, compose with the checkout mount + UID map,
  store row (mesh-app, `code.isle`), Keycloak via the proxy (fallback
  password), the `.vscode/` files in the repo. Proof: open the checkout in
  the browser, run `pol modules conform gears` in its terminal, edit a
  module, run its selftest.
- **de-3** `polari-notebooks` (JupyterLab) with the framework kernel; the
  `dev-environment` suite row (parts: polari-code, polari-notebooks,
  dev-tools module, the instance) with contracts (`PolariAppDefinition`,
  the manifests, `CheckRun` from the accountability API).
- **de-4** desktop parity: VSCodium + the same extension; a `pol dev open`
  verb that launches either.
- **de-5** offline bundle of images + .vsix; Jenkins builds the images.
- **de-6** (option) Theia-based Polari IDE product if de-1 proves too
  constraining.

## 5. Decisions (his)
- D1 code-server (default) vs OpenVSCode Server vs Theia for the in-browser host (the extension is host-agnostic).
- D2 auth: Keycloak through the isle proxy (default) vs code-server password.
- D3 workspaces: one shared checkout per isle member (default: the member's
  own `~/polari-suite`) vs per-user containers.
- D4 extension policy: OSI-licensed only, from Open VSX, pinned; the
  proprietary Microsoft packs are excluded by rule (Pyright, jdtls replace them).
- D5 whether the Polari extension is GPLv3 (default, our repos) or MIT
  (easier for others to fork into their own editors).

## 6. Gates
Licence gate doc (`DEV_ENVIRONMENT_GATE.md`) before de-1 pins: code-server,
Open VSX, each pinned extension (LICENSE + package.json + headers), Pyright,
jdtls, JupyterLab. Forks: dausume/code-server (or openvscode-server),
dausume/polari-vscode (ours), the .vsix set mirrored.
