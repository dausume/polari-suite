# Open-Source PVD — its own roadmap (Dustin 2026-07-18)

**Status: PLANNING SHELL.** PVD was folded into BLCNC_PVD_ROADMAP.md
as a dependency; Dustin's direction: **PVD is its own roadmap** with
its own prerequisites. Seeded as TechNodes in the
`electronics` (Electronics / Microelectronics) tree — see
`techtree/techtree_seed.py`; the tech tree's gap rows name what to
build. Nothing here is built.

## Prerequisites (seeded as upstream TechNodes)

1. **Open-source vacuum pump** (`electronics/vacuum-pump`) — a PVD
   chamber needs vacuum BEFORE any deposition physics matters; the
   BLCNC ideal melt extraction (near-vacuum + suction) shares it.
   Theory ref `vacuumpump` (module not built).
2. **Piezoelectric sputter materials**
   (`electronics/piezoelectrics`) — materials that can act as
   piezoelectronics, enabling the sputter the deposition needs.
   Theory rides the msci materials basis; a sputter-specific piezo
   family is the open question.

## Related, seeded alongside (shared with BLCNC/LASiS)

- **Tunable expansion dielectrics**
  (`electronics/expandable-dielectrics`) — dielectrics modifiable to
  expand/contract; the actuation basis for the
- **Precision Laser Apparatus**
  (`electronics/precision-laser-apparatus`) — required by BOTH the
  real BLCNC and **LASiS** (now a first-class TechNode,
  `electronics/lasis`). In the tree this shared requirement is
  exactly the transient/primary designation case.
- **Nanoparticle supply** (`raw-supply-chain/nanoparticle-supply`) —
  LASiS's output stream tracked as a RAW MATERIAL in the Raw Supply
  Chain tree (per Dustin: the supply itself belongs there).

## Phasing sketch (not yet numbered into ospvd-N — refine at build)

1. Vacuum pump: pump-down model + achievable vacuum levels vs.
   chamber volume/leakage; open-source pump design candidates.
2. Piezo sputter source: sputter yield model from piezo drive;
   material candidates from the msci basis.
3. Deposition physics sim (the `ospvd` module the tech tree's gaps
   point at): rate/uniformity/adhesion over the wax-mask workflow.
4. Mask cycle integration: couple deposition → BLCNC melt-voxel
   pattern → extraction (feeds BLCNC_PVD_ROADMAP P2/P3).

Dependency wiring already in the seed:
`os-pvd` ← {vacuum-pump, piezoelectrics}; BLCNC P2/P3/P3.1 ← os-pvd
(unchanged from BLCNC_PVD_ROADMAP.md).
