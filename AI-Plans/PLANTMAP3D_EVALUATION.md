# PlantMap3D — license evaluation (2026-07-30)

**Question (Dustin):** is PlantMap3D open source? If so, fold it into
the plant-morphology planning going forward.

**Answer: NO — not as published. Do not vendor, fork, or copy its
code into Polari.** The concepts are still useful as a *named
benchmark*; the code is not usable.

## What it is

PlantMap3D (Precision Sustainable Agriculture / USDA-ARS consortium)
is a platform-agnostic plant-mapping system: RGB cameras for species
classification plus grayscale **stereo** pairs for plant height, with
ML on top, producing real-time maps of species composition and
biomass. Hardware comes in two shapes — *MonoOak* (hand-held, single
stereo+RGB head, plot scale) and *MultiOak* (2–8 heads on a tractor
or sprayer boom). It is field-calibrated across cover-crop corn,
soybean and cotton regions and is being adapted for high-throughput
phenotyping. Public write-ups describe it as using "open-source
software" — that describes its *dependencies*, not its own terms.

## The license finding (checked 2026-07-30 via the GitHub API)

| repo | license | language | last push |
|---|---|---|---|
| `precision-sustainable-ag/PlantMap3D-Computer-Vision` | **none** | Python | 2024-02 |
| `precision-sustainable-ag/PlantMap3D-Hardware` | **none** | G-code / KiCad | 2024-09 |
| `precision-sustainable-ag/PlantMap3D-oakd` | **none** | Python | 2024-04 |

No `LICENSE` file at any repo root; the GitHub API reports a null
license for all three. Publicly *readable* is not the same as
*licensed*: with no license, default copyright applies — no right to
copy, modify, or redistribute.

**This is not plausibly an oversight to shrug off.** The same
organization licenses 23 of its ~100 public repos (MIT, GPL-3.0,
LGPL-3.0, AGPL-3.0, CC-BY-4.0), so it knows how to declare terms.
The absence on these three is a real gap, and the correct response
is to *ask*, not to assume.

Caveat worth stating rather than hiding: works authored by US federal
employees are public domain under 17 USC §105, and this is USDA-ARS
funded. But funding is not authorship — PSA is a multi-university
consortium, and contributor copyright is not resolvable from the
outside. "It might be public domain" is not a basis to copy code.

## What we do instead

1. **Do not incorporate the code.** No vendoring, no
   copy-paste-with-attribution, no derived port.
2. **The ASK (an open follow-up, cheap):** email/issue the
   maintainers requesting an explicit license. If they answer with
   an OSI license, this evaluation flips and the pipeline concepts
   become directly reusable — re-read this file first.
3. **Keep it as a benchmark reference.** The *approach* is public
   knowledge and independently implementable: stereo depth → canopy
   height → per-species biomass estimate, with species
   classification from RGB. Our morphology work can name PlantMap3D
   as the comparator it should be measured against, exactly like
   MachinableWax is the make-vs-buy comparator in the supply chain —
   a benchmark row is a citation, not a dependency.
4. **If we build this capability**, build it from the published
   method and our own stack (msci + plant_morphology + mathshapes),
   and cite the papers, not the repository.

## Genuinely open alternatives found while looking

- **Plant 3D (P3D)** — `iziamtso/P3D`, a phenotyping toolkit for 3D
  point clouds (stem/lamina classification, skeletonization, leaf
  segmentation), C++/PCL/Qt/TensorFlow, published in *Bioinformatics*
  (2020). Check its actual license before use — this list is a
  starting point for a hunt, not a cleared dependency.
- **Phenomenal** — open-source library for 3D shoot reconstruction
  and light interception from image-based phenotyping.
- **Digital Plant Phenotyping Platform** — in-silico phenotyping
  environment.

Each of these still needs its own license check by the same method
used here (`GET /repos/{org}/{repo}` → `.license.spdx_id`, plus a
root `LICENSE` file check). **Do not skip that step because a paper
called the tool "open source."** That phrase, on its own, has now
been wrong once in this very evaluation.

## Method note (reusable)

The check that produced this table:

```
curl -s https://api.github.com/repos/<org>/<repo> \
  | python3 -c "import json,sys; d=json.load(sys.stdin); \
    print((d.get('license') or {}).get('spdx_id'))"
curl -s https://api.github.com/repos/<org>/<repo>/contents \
  | grep -i licen
```

Both, not either: the API field can lag an unrecognized custom
license file, and a repo can carry a `LICENSE` the API cannot
classify.
