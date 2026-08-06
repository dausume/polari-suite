# Handoff — Polari app shells (web-wrapper apps)

**Date:** 2026-08-06 · **From:** Fable 5 · **Status:** ⚠ CONCEPT
CAPTURE ONLY — **planning deliberately NOT started.** Dustin asked
that this session only record what he said and the next steps; the
plan gets written *with him* in the next session.

Nothing here is a design decision. Where wording is his, it is kept
as his.

---

## 1. What Dustin asked for (recorded, near-verbatim)

> "We are going to want to make basically web-wrapper applications
> (**not mesh apps**) for polari to be able to interact with. We
> will want to be able to define a way to make web-based apps that
> are **configurable and downloadable from a polari instance** so
> that you can use polari as an app from there onwards. We would
> also want the capability to **register multiple polari instances
> if the app is already installed**, and be able to **pass the
> pre-registration to the app when installed (so they can
> auto-install)** and automatically be able to connect to the
> polari instance from the app. The app should just be a **shell
> that auto-logs-in through keycloak (using sha)** and then
> connects them to the polari url and website."

Points as separated for later planning — do NOT treat these as
resolved:

1. **Web-wrapper apps, explicitly NOT mesh apps.** This is a
   different concept from the existing mesh/module distribution
   work; the handoff should not be read as extending it.
2. **Definable + configurable app builds** — a way to *define* a
   web-based app, not one hard-coded shell.
3. **Downloadable from a Polari instance** — the instance itself
   serves the app; "use polari as an app from there onwards."
4. **Multi-instance registration** — once installed, the app can
   register additional Polari instances.
5. **Pre-registration passed at install time** — the download
   carries which instance(s) it should attach to, so the app
   "auto-installs" already pointed at them.
6. **Auto-connect** to the Polari instance from the app.
7. **The shell is thin**: auto-login through **Keycloak (using
   sha)** and then connect to the Polari URL / website. Dustin's
   framing is that the app is *just a shell* — the UI stays the
   web app.

⚠ Ambiguities to resolve WITH him next session (not guessed here):
- what "using sha" refers to precisely in the Keycloak flow;
- whether "auto-install" means silent registration of a known
  instance vs an OS-level install action;
- what is configurable in an app definition (branding? which
  modules/pages? offline behavior?);
- whether app definitions are Polari objects (likely, given
  object-coherence) — to be decided, not assumed.

---

## 2. The attached image (from a more recent planning session)

**Source file:** `/home/user/.claude/uploads/`
`08a9b279-873e-44bb-9786-921f0d0cf886/a7b71f68-IMG_4325.png`
⚠ **Not yet copied into the repo** — Bash was unavailable in this
session's permission mode. Suggested home:
`docs/handoff-assets/polari-app-shell-platform-recommendation.png`.
The full content is transcribed below so the handoff stands alone
even if the file is not moved.

Screenshot of a chat giving a platform/runtime recommendation.
Partially visible above the fold is a build-target tree:

```
Desktop pipeline
├── Windows
├── (macOS)
├── Linux x64
└── Linux ARM64

Mobile pipeline
├── Android
└── iOS
```

**"My concrete recommendation" — Use:**

- JavaFX everywhere
- JCEF on Windows, macOS, and conventional Linux
- JCEF on PinePhone only if your Linux ARM64 build proves stable
- Installed Chromium app mode as the PinePhone fallback
- Android WebView on Android
- WKWebView on iOS/iPadOS
- One shared Three.js/D3 web bundle
- One shared JSON-based native bridge
- One Gradle repository with platform-specific modules

> "That gives you one application architecture and two meaningful
> browser integration paths. Trying to force JCEF into Android and
> iOS would likely increase—not decrease—the number and complexity
> of builds."

**Note for the planning session:** this is an *input* Dustin
brought, not a decision recorded here. It is one recommendation
from another session, and its provenance (which model/session,
what it was responding to) is not established in this handoff.
It notably assumes a JavaFX/Gradle/JCEF native-shell direction,
which is a much heavier build story than "just a shell that
auto-logs-in" implies — reconciling those two is probably the
first real planning question.

---

## 3. Next steps (the ask for the next session)

1. **Write the plan with Dustin** — this is the explicit
   instruction; do not pre-empt it.
2. Resolve the §1 ambiguities first, especially the Keycloak/sha
   flow and what an "app definition" contains.
3. Reconcile §1's "thin shell" against §2's JavaFX/JCEF/Gradle
   recommendation — decide whether the first target is a genuinely
   thin wrapper (PWA / WebView / Chromium app mode) or the full
   native-shell matrix, and say why.
4. Decide the object model only after the above: whether app
   definitions, instance registrations, and pre-registration
   payloads are Polari treeObjects (and if so, which module owns
   them — one module owns each object, per `/topology/databases`).
5. Note the standing repo gotchas apply to any new module:
   dependency-ordered admission via `modules/polari-modules.json`
   `requires`; a class in `seed_pairs` but NOT in
   `defClassList` silently gets no table; `pol topology assign
   <mod> prf-a` then apply the DERIVED env.

---

## 4. State of the previous arcs at handoff time

- **Casting / mold-nesting:** backend complete, deployed,
  live-verified. Frontend refinement remains — see
  `CASTING_FRONTEND_HANDOFF.md`. Modules currently SHELVED on
  `prf-b` (reversible via `pol topology assign`).
- **CO₂ / health + climate:** active focus before this switch.
  prf-a trimmed to 8 modules. All 6 atmospheric series + 11 NHANES
  bicarbonate cycles ingested live. Deviation-aware compression,
  clickable-citation endpoint, and the corrected attribution
  framing all landed today (see git log on
  `polari-rf-node/polari-framework` `dev`).
- Nothing pushed — pushing remains Dustin's manual step via
  `polari-cli/shells/push-all-dev.sh`.
