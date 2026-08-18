# Missing Materials Data — Lookup Worksheet

Generated from the live seed data 2026-07-06. Everything the wax searches
(grid + batch refinement) still cannot see, prioritized by what unblocks the
most. "Likely metric" = the unit the schema already expects (from your target
rows / effect rows / notebook conventions). Ballpark columns are rough
literature-order starting points to sanity-check your lookups against — NOT
data; everything you confirm gets your provenance like the pine-rosin entry.

## Priority 1 — additive effect NUMBERS (blocks search winners the most)

These additives already have +/- intent rows; they need `effectPerWeightPercent`
(how much the property moves per 1 wt% added). Both wax profiles target
ShoreHardness and LayerAdhesionStrength, so these two columns matter most.

| Additive | ShoreHardness (Shore D per wt%) | LayerAdhesionStrength (MPa per wt%) |
|---|---|---|
| Rosin (pine) | needed (+, likely +0.5–1.5) | needed (+, likely +0.02–0.05) |
| Copal resin | needed (+) | needed (+) |
| Benzoin resin extract | — | needed (+) |
| Myrrh oleoresin | — | needed (+) |
| Carrageenan resin | — | needed (+) |
| Chalk powder | — | needed (±, likely small −) |
| Soy lecithin | — | needed (±) |
| Carnauba wax | needed (+, likely +0.3–0.8) | — |
| Grog 1/3/6 µm | needed (+, likely +0.2–0.5) | — |
| Kaolinite clay | needed (+) | — |
| Calcium alginate | needed (+) | — |
| Cork flour | needed (−, softens) | — |
| Glass microfibers | — (has FlexuralModulus intent: needs MPa per wt%, likely +10–30) | — |

Lower value: TackRating + ShockAbsorption (0–1 rating per wt%) for the
oleoresins — no current profile targets them; skip unless tack matters to you.

## Priority 2 — BASE WAX property values (the search's manual inputs)

The searches take `baseProperties` for your chosen base. Your notebook already
covers some (✓); the blanks are what to look up per base wax
(beeswax / candelilla / carnauba / coconut / soy):

| Property | Likely metric | Notebook status | Ballpark for natural waxes |
|---|---|---|---|
| ShrinkageRate | % (volumetric, melt→solid) | missing | 8–15% unfilled; your targets want 0.5–2 |
| FlexuralModulus | MPa (3-point bend) | missing | 20–120 (beeswax low, carnauba high) |
| ShoreHardness | Shore D (durometer) | "low/hard" qualitative ✓-ish | beeswax ~5–15, carnauba ~40–55 |
| LayerAdhesionStrength | MPa (printed-layer pull) | missing | 0.1–0.5 (your own test rig metric) |
| AirSolidificationRate | 1/ms (your metric — solidification rate constant in air) | missing | define via your test: 1/(time-to-solid) |
| ExtrusionPressure | MPa (at nozzle, at print temp) | missing | 0.01–0.2 per your target band |
| SurfaceTension (liquid) | N/m | ✓ 22–24 mN/m = 0.022–0.024 N/m | encode as 0.022–0.024 |
| Viscosity | mPa·s at temp | ✓ beeswax 200–300 @80°C | candelilla/carnauba/coconut have "low/creamy" only |
| MeltingPoint / SmokingPoint | °C | ✓ all four + rosin | done |
| Melt Flow Index | g/10min at temp | ✓ estimates for all four | done |

## Priority 3 — verify my literature-typical thermal fills (vetoable)

| Material | Value I entered | Confidence |
|---|---|---|
| Soy wax | melt 45–55°C, smoke ~230°C | medium — verify smoke |
| Stearin | melt 55–70°C, smoke ~230°C | medium |
| Soy lecithin | degrades ~120–160°C | medium-high — this one CLOSES windows, worth confirming |
| Cork flour | degradation onset ~200°C (never melts) | medium |
| Mineral fillers (grog/clays/graphite/DE/silica/chalk) | inert, never melt | high — no lookup needed |

## Oddities to define (your metrics, only you can pin them)
- **AirSolidificationRate (1/ms)** and **ShearThinningIndex (dimensionless,
  power-law n)** appear in the machinable-wax targets with exact optima
  (1.5 /ms and 0.4) — worth writing one notebook line each on how you intend
  to measure them, so effects can eventually be quantified against the same rig.
- Machinable-wax profile targets MeltingPoint 116°C / TargetPrintTemp 145°C /
  Smoke+Flash 302°C — those describe the commercial Print2Cast benchmark, and
  the blend-level values now COMPUTE from thermal profiles rather than needing
  lookup (the gate already reports blend melt-through and volatile limit).
