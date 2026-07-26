# MATERIALS SCIENCE TECH TREE — plan

**Status 2026-07-26: mtt-1 BUILT (seed the tree — data only);
mtt-2..7 planned. Establishes a dedicated `materials-science` tech
tree, the two representation sub-domains, the core material bodies,
the variant-property progression, and where prior work should be
filed.**

## Build state
- ✅ mtt-1 (`modules/techtree/techtree_seed.py`): 4th baseline tree
  `materials-science` + 12 nodes (statistical / discrete /
  encapsulation hubs + the 9 cores) with membership deps to the
  sub-domain hubs and cross-refs to the electronics/supply nodes;
  17 theory-segment assignments filing pspp/materialsScience/
  Wax-3D-Printing/biomining onto nodes; pspp added as a present
  `_module`. Tech-tree selftest updated (51/51 — node-count, baseline
  rollup, mean-completion assertions now include the 4th tree).
  Deployed to the swarm msci instance. DATA ONLY — no engine code.
- ✅ smt-1: 5th baseline tree `simulation-methods` — 9 METHOD nodes
  (nocode-execution → sim-core → multi-scale / resource-aware /
  distributed-compute → cross-instance-sim → grpc-bridge;
  hardware-sim; schema-stability), each cross-ref'd INTO the domain
  trees it serves (materials/electronics/hardware). Files
  simulations/matrices/polariNoCode/grpcbridge/resources theory;
  `resources` added as a present module. Answers the plan's open
  "sim-methods = own tree?" with YES (serves >1 tree). techtree
  selftest 52/52. Deployed. DATA ONLY.

Companion plans: GEOPOLYMER_STRUCTURE_SAMPLING_PLAN.md (gsp, built),
PSPP_MATERIALS_PLAN.md, SOLID_STATE_PHYSICS_PLAN.md, and the
tech-tree engine (TECH_TREE_TOPOLOGY_PLAN.md / topology-techtree
build). Trees are DATA (`modules/techtree/techtree_seed.py`); a new
tree is seed rows, not new engine code.

## What exists today (and the problem)

Three seeded trees: `electronics`, `raw-supply-chain`,
`os-economy-politics`. Materials work is scattered — `wax-materials`,
`carbon-nanotubes`, `silicon-refinement`, `ceramics-composites` under
electronics; `sol-gel-supply`, `silicon-supply`, `cnt-supply`,
`wax-supply` under supply. There is **no materials-science tree**, so
the msci/ssp/pspp/gsp body of work (hundreds of classes, real
engines) has no home node and the 9 core manufacturing materials
aren't enumerated anywhere as a set.

Fix: a 4th baseline tree, `materials-science`, that OWNS material
identity + simulation, with cross-refs (not edges — the engine's tt-9
convention) to electronics (what consumes the material), supply (where
feedstock comes from), and economy (business/policy around it).

## The categorization question — two representation sub-domains

The distinction Dustin named — stochastic pspp materials vs precise
particulate materials — is REAL and already latent in the schema
(`ScaleStructureDefinition.representation_type`). Name them as the two
sub-domains of the materials tree:

- **Statistical materials** (`materials-science/statistical/*`) —
  identity is a DISTRIBUTION over motifs/phases; amorphous, reactive,
  formulated. Engine: the **pspp** stack (datasets/rules/windows/
  state-DAG/progress/grader) + **gsp** (Q-groups, ensemble sampler,
  Debye halo). Members: wax, sol-gel, geopolymer, glass, ceramics
  (process side), the composite formulations.

- **Discrete materials** (`materials-science/discrete/*`) — identity
  is a PRECISE structure or particle: a lattice, a stoichiometric
  crystal, a sized nanoparticle. Engine: the **msci/ssp** stack
  (CrystalStructureDefinition, lattice scenes, phonons/elastic,
  pymatgen symmetry/XRD, MD/meso). Members: aluminum, silicon,
  carbon-nanotubes, the bio-steel alloys, crystalline ceramic phases,
  nanoparticles.

Why this cut is the right one: it's the engine boundary. A material
can appear in BOTH sub-domains at different scales (a ceramic is a
discrete crystal phase L3 inside a statistical green-body/sinter
process L2) — modeled as cross-refs between its two nodes, exactly
what the tech-tree cross-ref mechanism is for. It also names the
bridge Dustin flagged: **encapsulation** (below) is a discrete input
consumed by a statistical formulation.

### The encapsulation branch (the bridge, its own sub-tree)

`materials-science/encapsulation/*` — refining nanoparticles and
locking them into wax/lipid composite carriers so they are safe to
transport and handle (no free-particle spill/inhalation hazard). It
CONSUMES discrete (the sized particle) and PRODUCES statistical (the
loaded wax/lipid composite, a pspp material with a dispersion
distribution + a leak/release window). This is the categorization
"difference" Dustin couldn't name: it is not a third representation,
it is the **transform edge** discrete→statistical, and it earns its
own branch because safety gating (release windows, spill scenarios)
is a first-class concern with its own datasets and windows. Reuses
pspp windows + the existing ExposureScenario class.

## Core material bodies (the 9) — nodes + engine + status

Each becomes a `materials-science/<sub>/<material>` node. "Have"
notes what already exists to seed it.

| Material | Sub-domain | Engine path | Have today |
|---|---|---|---|
| Wax | statistical | pspp | ✅ Wax-3D-Printing module, wax states, feedstock routes |
| Sol-gel | statistical | pspp | ⚠ glass Q-curves reusable; needs alkoxide library + pH gate |
| Geopolymer | statistical | pspp + gsp | ✅ full pspp + gsp groups/sampler/halo |
| Glass | statistical→discrete | pspp (Q) + msci (devit) | ⚠ Maekawa glass Q-curves LIVE; refinement windows TODO |
| Ceramics | statistical (process) + discrete (phase) | pspp + msci | ⚠ ThermalProcessingProfile exists; sintering engine gap |
| Aluminum | discrete | msci/ssp | ✅ fcc crystal seed, phonons/elastic live |
| Silicon | discrete | msci/ssp | ✅ diamond-cubic seed, XRD, phonons; refinement grades TODO |
| Carbon nanotubes | discrete | msci (+ new tube builder) | ⚠ tech node exists, no structure builder |
| Stainless equiv = **galvanized-bio-steel** | discrete | msci | ✅ bio_alloys_seed; true stainless = honest Cr gap |

First MatSci step (Dustin's stated order): **simulate all 9 core
materials + known variants**. Concretely = one discrete
CrystalStructureDefinition-or-sampler entry point per material with a
scene + at least one property engine result, and one statistical
pspp/gsp entry where the material is formulated. The gaps above
(sol-gel library, glass refinement windows, sintering engine, CNT
builder, silicon grades) are the build backlog for this step.

## Variant-property progression (Dustin's ordering, as node layers)

Each is a LAYER of variant nodes hanging off the 9 cores, built in
this order:

1. **Baseline simulation** — the 9 cores + known variants (above).
2. **Carbon-negative formulations** — start geopolymer (known
   carbon-negative routes: MK-750 vs OPC, mineral carbonation,
   biochar fillers); carbon accounting via the existing supplychain/
   carbon ledger. Cross-ref to supply/carbon-management.
3. **Magnetic + conductive variants** — doped/loaded formulations and
   phases; conductive = CNT/graphitic loading + doped silicon;
   magnetic = ferrite/Fe-phase routes. Property engines: electronic
   (electrodevice/SPICE side) + a magnetic-property descriptor.
4. **Thermal variants** — conductivity/expansion/refractory windows;
   reuses phonon/elastic + ThermalProcessingProfile.
5. **Structural variants** — strength/toughness/durability envelopes;
   reuses elastic constants + performance scenarios + the grader.
6. **Advanced nanocomposites → semiconductors + sensors** — the
   payoff: encapsulation-derived composites + doped CNT/Si into
   device-grade materials. Cross-refs heavily into the electronics
   tree (blcnc theoretical chip, PVD, piezoelectrics) and the
   discrete nanoparticle path.

Layers 3-5 are the same property-engine pattern applied to different
observables; 6 is where materials-science hands materials to the
electronics tree.

## Prior-work → tree placement audit (the "where does it go" pass)

Modules/work that currently have no tree node or the wrong one:

- **materialsScience/ (msci-0..28), solid-state (ssp-1..4)** →
  `materials-science/discrete/*` — the discrete engine itself.
  Currently NO node. Highest-priority fix.
- **pspp (+ gsp)** → `materials-science/statistical/*` — the
  statistical engine. No node today.
- **waxprint / Wax-3D-Printing** → material identity node under
  statistical/wax; the PRINTER stays electronics/3d-printing (process
  vs material — cross-ref, don't move).
- **biomining alloy variants** → feedstock cross-ref from
  discrete/galvanized-bio-steel to supply/biomining (already partly
  wired via material_ref).
- **microalgae / waxsupply / supplychain carbon ledger** →
  supply tree (carbon-management, wax-supply) — cross-ref targets for
  the carbon-negative layer, not materials-science owners.
- **electrodevice / hwfpga / semiconductor seeds** → electronics
  tree; materials-science/discrete/silicon cross-refs INTO them at
  layer 6.
- **Existing scattered materials nodes** (electronics/carbon-nanotubes,
  /silicon-refinement, /ceramics-composites; supply/sol-gel-supply
  etc.) → keep as the CONSUMER/SUPPLY ends; add the materials-science
  IDENTITY node and cross-ref the pair. Do not delete — the tree
  engine models this as one material seen from three trees.

Other trees this pass suggests exist or fill out (Dustin's "prior
work that should be going into trees"):
- **Simulation-methods** could be a tree of its own OR a spine within
  materials-science (SimulationDefinition, multi-scale, coupling,
  resource-aware, xsim, gRPC bridge, hwsim) — LOTS of built work with
  no tree home. Proposal: a `simulation-methods` cross-cutting tree
  since it serves materials AND electronics AND hardware.
- **AR/zones/webxr, math-shapes, no-code** — infrastructure, arguably
  a `platform` tree; flagged, not scoped here.

## Build order (proposed)

1. **mtt-1**: seed the `materials-science` tree + the 3 sub-domain
   groupings (statistical/discrete/encapsulation) + the 9 core
   identity nodes with cross-refs to existing electronics/supply
   nodes; file msci/ssp/pspp/gsp modules onto their nodes
   (`_module` rows). DATA-ONLY, no engine code — proves the map.
2. **mtt-2**: baseline simulation coverage — close the per-core gaps
   so every one of the 9 has a scene + a property result (sol-gel
   library, glass windows, CNT builder, silicon grades, sintering
   engine is the big one).
3. **mtt-3**: carbon-negative geopolymer layer (+ carbon ledger
   cross-ref).
4. **mtt-4..6**: magnetic/conductive → thermal → structural variant
   layers.
5. **mtt-7**: nanocomposite semiconductor/sensor layer + encapsulation
   branch (safety windows).

Each phase: branch off the msci/pspp stack, selftests, review gate,
per the standing rules. mtt-1 is cheap and unblocks the rest by giving
everything a home.

## Open naming decision for Dustin
- Sub-domains: **statistical** vs **discrete** (proposed) — or
  "stochastic/particulate", "bulk/crystalline". Pick before mtt-1.
- Is **simulation-methods** its own tree or a materials-science
  spine? (Recommend own cross-cutting tree — it serves >1 tree.)
