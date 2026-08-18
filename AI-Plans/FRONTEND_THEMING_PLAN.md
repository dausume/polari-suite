# FRONTEND THEMING — tokens everywhere, day/night correct by construction

**Status 2026-08-03: sty-1..sty-4 ALL DONE, deployed + live-verified in
BOTH themes over ~25 routes. Branch `dev-sty3-contrast-sweep` in
angular + rf-node + suite (NOT pushed).**

The sty-3 sweep did not proceed dir-by-dir as planned below; a live
contrast audit driven through Chrome found the failures first, and
they clustered into a handful of ROOT causes rather than a long tail
of per-file hexes. What actually shipped:

1. **Material's dark palette leaks** — anything Material styles that we
   don't kept its near-white default. Fixed GLOBALLY in `styles.css`:
   menu-item icons, slide-toggle/radio/checkbox labels, chip leading
   icons + remove buttons, and disabled button labels/borders.
2. **UA defaults** — bare `<a>` kept `#0000EE`, and a plain `<button>`
   the black `buttontext`. Both now themed globally (the button rule is
   scoped away from Material's own).
3. **Property-aware tokenization** — ~700 declarations across
   custom-no-code/, shared/, templateClassTable/, geojson-config/,
   permissions/, dashboard/, class-main-page/, topology/, techtree/,
   apps/, matrices/, displays/, multi-scale/ rewritten by the PROPERTY
   the color lands on (background -> --surface-*, color -> --text-*,
   border -> --border-*). Script kept at
   `/tmp/.../scratchpad/tokenize.py` — regenerate if needed, it is
   mechanical.
4. **Legends** — painted the whole legend item in the mark color, so
   pale kinds (yellow, light green) were unreadable. The color moved
   onto the SWATCH; the label rides the theme. Same idea for SVG
   labels on colored bands/edges: theme text color + a halo in the
   canvas color, which reads on any fill in either theme.
5. **Mark colors used as text** — `--brand-purple` / `--brand-teal` do
   NOT flip, so text set from them died on the opposite background.
   Added `--brand-{purple,teal}-text` pairs. **This is the general
   lesson: a --brand-* value is a MARK color; text needs its own
   flipping token.**

Two real (non-styling) bugs fell out: an unscoped `.num` badge rule in
business-start also matched the QA table's numeric `<td class="num">`
cells, and module-management's plan card was a fixed light pair whose
button text got themed by the global rule.

**sty-4 shipped as `scripts/check-theme-tokens.mjs`, wired into
`npm run build`.** It deliberately does NOT flag every raw color —
that was 1331 hits, mostly legitimate. It fails only on the pattern
that actually hides text: a rule that themes one side of the
background/text pair and hardcodes the other, or `color: inherit` on a
fixed background. It parses `_theme-dark.css` to know which tokens
actually flip, and treats low-alpha `rgba()` as adaptive (it tints
whatever is behind it). Remaining debt is reported, not failed:
**290 fixed pairs + 944 lone raw colors**. It caught a regression
introduced during this very sweep.

**Method worth reusing:** a contrast auditor injected via the Chrome
extension, walking text nodes + SVG text + mat-icons, compositing the
real background and reporting anything under 2.5:1, run over every
route in both themes. Note two blind spots learned the hard way —
SVG siblings are not DOM ancestors (needs a geometry hit-test), and it
cannot see a `paint-order: stroke` halo, so halo'd labels read as
false positives.

---

**Historical (2026-07-25): sty-1 + sty-2 BUILT. Trigger: pspp pages
white-on-white in night mode (screenshots 07-25) — recurring app-wide.**

## The system (already exists — use it, don't fight it)

- `src/styles/_variables.css` — every semantic token, light values, on
  `:root`: surfaces (`--surface-primary/-secondary/-tertiary/-hover/
  -app-background`), text (`--text-primary/-secondary/-tertiary/
  -disabled/-on-primary`), borders (`--border-light/-medium/-dark`),
  semantic sets (`--color-{error,success,info,warn}{,-bg,-border,-text}`),
  brand colors, chart tokens (`--chart-text`, `--chart-grid` — added
  sty-1), plus spacing/typography/radius.
- `src/styles/_theme-dark.css` — the SAME tokens overridden under
  `body.dark-theme` (ThemeService toggles the class; localStorage-backed).
- `body` sets `background: var(--surface-app-background);
  color: var(--text-primary)` — so **everything you don't color
  explicitly inherits the theme's text color.** That is exactly why
  hardcoding a light card background makes inherited text invisible:
  you changed one side of a pair the theme owns.

## ROOT CAUSE found 2026-07-26 (browser pass) — the inheritance trap

The token conversion (sty-2) was necessary but NOT sufficient. The
prebuilt Angular Material theme (pink-bluegrey) is a **dark palette**,
so any text element that does NOT set its own `color` inherits
Material's near-white default. Result: labels, `<td>/<th>`, card
`<b>` titles, and anything with `color: inherit` are near-white →
INVISIBLE on light card/app surfaces in light mode, and only
*accidentally* readable on dark surfaces in dark mode. (styles.css:29
even documents the palette but only fixed headings.) This is why pspp
"remained largely unresolved" after sty-2 — the tokens were right but
inheritance leaked Material's default past them.

**Two hard rules added (fix applied to all pspp components 07-26):**
- **Never rely on inherited color.** Anchor `:host { display: block;
  color: var(--text-primary); }` on every component so descendants
  inherit a THEME-FLIPPING color, not Material's default. Then any
  text needing a different shade sets its own token.
- **SVG `<text>` uses `fill`, not `color`** — it ignores the CSS
  color/`:host` anchor. Every SVG label needs an explicit
  `fill: var(--chart-text)` (or `--text-primary`); default SVG fill
  is pure black → invisible on dark surfaces.
- **Chart inputs must be STABLE fields, never getters.** A getter
  bound to `[series]` allocates a new array each change-detection
  cycle → Observable Plot re-renders → DOM change retriggers CD →
  render-storm freeze (the "browser slowdown, renders only after
  Stop" bug, hit on /pspp/structure XRD). Materialize once.

The sty-3 sweep MUST apply the `:host` anchor + SVG-fill audit, not
just hex→token substitution.

## Context-semantic text tokens (2026-07-26 — the generalization)

Two more root issues found on the dark-mode pass:
1. **The content area (`mat-sidenav-content`) had no themed background**
   — Material's default there did NOT flip, so in dark mode cards went
   dark but the page body behind out-of-card text stayed light, and
   the (now light) text vanished. FIXED in app.component.css:
   `mat-sidenav-content { background: var(--surface-app-background)
   !important; color: var(--text-on-bg); }`.
2. Text tokens were shade-named (`--text-primary/secondary`), so a
   component had to KNOW which surface it was on to pick contrast.

New vocabulary — **choose text color by the SURFACE it sits on, not by
theme or shade** (defined in _variables.css + _theme-dark.css):
- `--text-on-card` / `--text-on-card-muted` — text on `--surface-primary`
  (cards, panels, forms, sections).
- `--text-on-bg` / `--text-on-bg-muted` — text on
  `--surface-app-background` (page body, out-of-card titles/labels/intro).
On dark, `-bg` is tuned slightly brighter than `-card` so titles stay
legible on the near-black page. Applied in pspp: component `:host` =
`--text-on-bg` (page default), card containers re-assert
`--text-on-card`, intros use `--text-on-bg-muted`.

**sty-3 rule of thumb:** page/host default → on-bg; anything with a
`--surface-primary` background → on-card; data-marks stay fixed hex;
SVG text uses `fill: var(--chart-text)`. Any new SURFACE token needs
its matching `--text-on-<surface>` pair.

**2026-07-26 tuning:** `--text-on-bg` is now pure `#000` (light) /
bright (dark) — the strongest-contrast token, meant to WIN for
out-of-card text. The global `h1..h6 { color: ... !important }` rule
(styles.css) was overriding it with `--text-primary`; repointed to
`--text-on-bg` so titles get priority in both themes. When an
out-of-card element still looks weak, it's usually pinned to
`--text-primary/secondary` locally — switch it to
`--text-on-bg(-muted)`. In-card muted text keeps `--text-secondary`
(correct on card surfaces).

## THE RULE (what went to memory)

**Surfaces, text, and borders always come from `var(--…)` tokens —
never hex. Data marks (chart series, category node fills, band colors,
legend swatches matching them) stay fixed hex — and fixed-color text
may only sit on fixed-color fills.**

Corollaries:
- A component style with `background:` or `color:` + raw hex on
  anything that is not a data mark is a bug, even if it "looks fine" —
  it looks fine in exactly one theme.
- `color: inherit` on a hardcoded surface is the classic white-on-white
  generator (pspp's `.card` was this).
- SVG: text/axes/grid painted on a themed surface use
  `var(--chart-text)` / `var(--chart-grid)`; labels inside fixed-fill
  shapes (species nodes, state rects, rule pills) keep fixed dark fills.
- Observable Plot figures inherit `currentColor` — put them on a
  tokenized surface and DON'T set explicit text colors (sci-xy-chart
  is the reference: tokens with fallbacks).
- Semantic states map to the semantic sets: refusals →
  `--color-error-*` (hard) / `--color-warn-*` (advisory), grades →
  `--color-{success,warn,error}-text`, chips → `*-bg` + `*-text` pairs.
- Missing a token? Add it to BOTH `_variables.css` and
  `_theme-dark.css` in the same commit — a token defined once is a
  silent light-mode hardcode.

## Phases

- **sty-1 ✅ (07-25)**: `--chart-text`/`--chart-grid` tokens added to
  both theme files.
- **sty-2 ✅ (07-25)**: full conversion of the active working set — all
  10 `pspp/` components (~91 replacements + SVG text fixes) and
  `materials-science/` (4 files: chips, outcome text, thermal strip).
  `charts/sci-xy-chart` verified already-correct. Awaiting visual
  verify in both themes.
- **sty-3 — the sweep**: remaining dirs by audit (2026-07-25 counts of
  files with hardcoded colors): fully-unthemed `datasets/`, `graphs/`,
  `module-details/`, `auth-callback/`; partial `custom-no-code/` (44!),
  `sim-space/` (19), `shared/` (13), `templateClassTable/` (10),
  `multi-scale/` (10), `matrices/` (9), `geojson-config/` (9),
  `permissions/`, `dashboard/`, `class-main-page/` (5 each), then the
  1-3-file tail. Same mechanical rule; batch per directory, visual
  spot-check per batch in BOTH themes.
- **sty-4 — the guardrail**: frontend selftest that scans component
  styles for `color:|background:|border.*#hex` outside an allowlist
  (data-mark classes annotated `/* data-mark */`, brand tokens file)
  and FAILS with file:line. Wire into the existing frontend suite so
  regressions die in CI, not on Dustin's tablet. New-page checklist
  addition: "renders readable in body.dark-theme".

## Verify
Each batch: toggle ThemeService day/night on the touched pages; text
readable + cards distinct from app background in both; charts show
axis text/grid in both. The pspp/msci set is the reference example.

---

# RESPONSIVE / DEVICE ADAPTATION (2026-08-03) — sizes as tokens

**Status: BUILT + deployed + live-verified over 60 route×width probes.
Same branch `dev-sty3-contrast-sweep`.**

## The device classes

| class | trigger | notes |
|---|---|---|
| phone | `<= 599px` | one column, nav overlays, tables scroll |
| tablet | `600-1023px` | nav still overlays |
| standard | `1024-1899px` | the default working size |
| wide | `>= 1900px` | more columns, wider measure |
| **mesh** | `.xr-panel-context` **class** | MeshHTML / WebXR |

## 🔑 MESH IS NOT A WIDTH

The XR path rasterizes a DOM element that lives **off-viewport at a
fixed pixel size** — `panel:main` is a hard 900×700 in
`xr-direct-entry-page.component.ts`; the side panels are 380–720 in
`xr-panel-host.component.ts`. HTMLMesh captures at 1 CSS px = 1 texel
(`PX_TO_WORLD = 0.001`, 1000px = 1 world unit).

So **a viewport media query inside a mesh panel reports the flat
browser window**, which has nothing to do with the panel being drawn.
Any width-based `@media` is simply wrong there.

**Therefore: components adapt with `@container`, not `@media`.** The
same rule then works flat AND in a panel — a 390px panel and a 390px
phone lay out identically, which is the point. `@media` is reserved
for the app SHELL (sidenav mode, toolbar), which is genuinely
viewport-scoped.

## What shipped

- **`_responsive.css`** — the single source of truth. Breakpoints are
  documented constants; the responsive TOKENS (`--page-pad`,
  `--page-max-width`, `--grid-min-col`, `--card-pad`, `--drawer-width`,
  `--graph-height`, `--popup-max-width`, `--font-scale`) shift per
  class, so most components need no query at all. Also ships the
  layout primitives `.page-shell`, `.auto-grid`, `.split-view`,
  `.scroll-x`, `.popup-width`, and marks the content area +
  `.xr-panel-context` as container roots.
- **App shell** — sidenav flips to `mode="over"` below 1024px via
  `BreakpointObserver` and dismisses on navigation; its width was
  `min-width:350px` (nearly a whole phone screen) and is now
  `min(350px, 85vw)`. Content padding follows the tokens.
- **⚠ `@angular/flex-layout` IS NOT A DEPENDENCY.** The header used
  `fxLayout` / `fxFlex="grow"`, so the spacer meant to push the auth
  controls right was an **inert attribute** — the toolbar had been
  silently left-bunched. Replaced with a real `.header-spacer`.
- **`--surface-outline` was referenced in 10 components but never
  defined** — every use silently fell back to a literal `#8884` that
  never changed with the theme. Now defined in both theme files.

## The two blowout mechanisms (both were live)

1. **Grid**: a track never shrinks below its content's min-content
   size, so `repeat(2, 1fr)` overflows instead of wrapping. Fix is
   `repeat(auto-fit, minmax(min(100%, X), 1fr))` **plus**
   `min-width: 0` on the children. This put an **852px row inside a
   390px phone viewport on the home page** — clipped, not scrollable.
2. **Flex**: a flex child defaults to `min-width: auto`, and
   `align-items: center` stops it being stretched, so it sizes to
   max-content. Same page, 818px text block in a 311px card.

## Consolidation done

- **`_graph-view-common.scss`** — topology / tech-tree / multi-scale
  were three copies of one shell (the topology file's header even said
  "cloned from the msim composition graph"). 585 lines → 286 + one
  partial. Their SVG vocabularies stay component-local.
- **`_table-patterns.css`** — two recipes (dashed-row, lined-row)
  replacing six re-typings, matched by EXISTING class names so no
  template changed. Wide tables scroll in their own box below 900px of
  **container** width.
- **`_chip-patterns.css`** — one base + semantic state modifiers wired
  to the `--color-*` token pairs, replacing ~25 independent `.chip` /
  `.badge` / `.tag` declarations. The 6-file magnetics/climate
  outlined-chip family was deduped onto `.chip-outline`.

Global sheets are used on purpose: Angular scopes a component's own
styles, but a global rule still matches inside components, so one
definition can serve every existing class name without template churn.

## Guardrail: `scripts/check-responsive.mjs` (in `npm run build`)

Fails on the two mistakes that cannot adapt: a `width` wider than a
390px phone with no ceiling, and a grid with a fixed track count.
`min-width` above phone width is counted, not failed (21 remain).
Opt out with a `/* fixed-size */` comment; the XR panel hosts are
excluded by name because their pixel sizes ARE the HTMLMesh contract.

Run both gates with `npm run check:styles`.

## The 21 remaining `min-width`s — audited 2026-08-03

Audited rather than assumed, and they were not what the count implied:

- **19 of 20 are MatDialogs** (500px pickers, a 600px instance picker,
  an 800px class editor, an 880px LaTeX editor, the dict/list cell
  editors — which are themselves dialogs, and the material-choice
  popup, opened via `MatDialog`).
- **1 is a 1200px SVG network diagram** (`pspp-network`) already inside
  an `overflow: auto` wrapper — scrolling is the right answer for an
  irreducible diagram.

So the proposed "collapse to a small icon button, expand full-screen"
pattern is **half already true**: a dialog is by definition opened by a
control, so the launcher exists. What was missing was the other half —
give it the whole screen.

`_dialog-patterns.css`: below 600px the overlay pane fills the
viewport, the surface squares off, each dialog's own root `min-width`
is neutralized (`.mat-mdc-dialog-surface > *`, targeted as the direct
child rather than a blanket `*`), and the content body is released
from its card-sized `max-height` so it scrolls the full height.
Between 600–1023px the floating card is kept but capped at 96vw.
Above that, nothing changes.

Verified live with the worst case (880px LaTeX editor):
390 → pane 390, `min-width` computed 0 · 820 → 787 (96vw), 0 ·
1440 → 880px preserved.

A `.expand-to-edit` / `.inline-wide` primitive for the non-dialog case
was drafted and then **removed**: no inline control in the app actually
needs it today, and shipping unused pattern classes is exactly how the
existing library ended up with classes nothing references. Add it when
a real case appears.
