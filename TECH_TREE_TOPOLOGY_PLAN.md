# Tech Trees + Topology Revamp — Planning

> **STATUS 2026-07-18 (tt-8, Dustin's revision): THREE DOMAIN TREES.**
> The single 'oseb' tree split into domain trees — the larger
> containment: **electronics** ('Electronics / Microelectronics', 24
> nodes — + PVD as its own roadmap w/ vacuum-pump + piezoelectric
> prerequisites (OSPVD_ROADMAP.md), expandable dielectrics →
> Precision Laser Apparatus required by BOTH real-BLCNC and the new
> first-class LASiS node, CNT-production-via-CO-reduction, silicon
> refinement grade-scale), **raw-supply-chain** ('Raw Supply Chain',
> 15 shell nodes — aquaponics/household nutrition, agroforestry,
> biomining, carbon management + the raw-material streams:
> nanoparticle supply, CNT / p-doped / n-doped CNT, silicon raw →
> PV-grade → semiconductor-grade, sol-gel, geopolymer composites,
> wax, wax nanocomposite layers), **os-economy-politics** ('Open
> Source Economy & Politics', 4 shells — judicial systems, policy
> tracking, business-logic models, micro-business tailoring).
> Reaching the end of ALL THREE, combined, = the OSEB:
> `baseline_report` / GET /api/techtree/baseline + a baseline strip
> on /tech-tree. Legacy 'oseb' rows retired at boot (live-verified:
> 1+19+37+21 rows removed, 14 hints remapped). LIVE numbers:
> electronics 51.7%, economy&politics 75% (scorecard genuinely
> enabled on staging), raw supply 36.7% → **combined OSEB 54.5%**.
> selftest_techtree 46/46 (in-container too); builds green; pages
> 200. New branches on the stacks: framework `dev-tt-8-domain-trees`
> (HEAD), angular `dev-tt-8-domains-ui` (HEAD).
>
> **STATUS 2026-07-17 (build pass): tt-1..tt-7 ALL BUILT + live on
> staging, awaiting Dustin's review.** Selftests: topology 52/52 +
> module-graph 26/26 + techtree 37/37 (all also green in-container);
> both Angular builds exit 0; live-verified on the running staging
> suite (`/api/topology/module-graph`, `/api/techtree/*`, /topology +
> /tech-tree pages 200 via pol-proxy). Seeded OSEB baseline computes
> **62.7%**; 3d-printing carries all four segments (25%, honest
> gaps). Branch stacks, NOT merged to dev, NOT pushed:
> polari-framework `dev-tt-1-module-graph` → `dev-tt-3-techtree` →
> `dev-tt-5-oseb-seed` → `dev-tt-6-segment-content` (HEAD);
> polari-platform-angular `dev-tt-2-graph-revamp` →
> `dev-tt-4-techtree-render` → `dev-tt-7-convergence` (HEAD).
> Open-question defaults taken (session ran unattended): 4 segments
> w/ politics=PURPLE, first-cut done-tests (gates can tighten later
> via `_ASSIGNMENT_TESTS`), PolariModule gained data_only +
> tech_node_ref, host▸container▸module triple nesting (hosts
> toggleable). tt-4 note: tech-dep "nesting" rendered as in-node dep
> CHIPS (dashed=transient) rather than recursive containers — call
> it out in review if the recursive reading is wanted.

**Status: PLANNING ONLY — baton hand-off.** *(superseded by the
status block above)* Scopes (A) a visual + semantic
revamp of the existing topology graph and (B) a new, generalizable **Tech
Tree** that is an expansion of topology — for tracking the full set of
technologies an org depends on, split Theoretical / Real (/ Business /
Politics), the theoretical portion tracked by Polari modules. End goal: a
complete tree = an **Open Source Economic Baseline (OSEB)** — the overall
end goal of the whole Polari project.

> **BUILD ORDER (Dustin 2026-07-17): do THIS first** — topology + tech tree
> are the cheaper build. THEN proof the BLCNC/PVD physics, whose
> [BLCNC_PVD_ROADMAP.md](BLCNC_PVD_ROADMAP.md) 5 intertwined phases are the
> **worked example that flushes out the real OSEB tech tree** (Part B5).

Grounded in the current system (verified this pass):
- Topology is **data in the object tree** ([[topology-orchestration]]):
  `TopologyDefinition` → `InstanceDefinition` (containers) pinned to
  `PolariNodeMachine` (hosts); `ModuleAssignment` (module→container),
  `ModuleDependencyEdge` (module→module, resolved to a provider),
  `ServiceConnection` (typed wires).
- It **renders** via one D3/SVG component
  `components/topology/topology-graph-view.component.ts`: nodes are
  **rectangular cards** (one per instance), modules are just a **text line
  inside the card**, dep edges are **solid** (colored by status), service
  connections are **dashed grey**. Layout is layered left→right, no
  nesting/containment.
- Module deps are **outbound-only** (`boundary_graph()` +
  `detect_cross_module_dependencies`); "who depends on me" (reverse edges)
  is **not stored** — must be computed by inverting the graph. This is the
  hook for "transient dependency" logic.
- Modules display today as **flat enable/disable cards** + a **text
  dependency tree** (`module-management` + `module-dependency-explorer`).
- **Tech tree: greenfield** — no technology/completion/baseline concept
  exists anywhere.

The tech tree and topology are the SAME "node-logic" graph with different
node semantics, so they share one revamped renderer.

---

## PART A — Topology visual + semantic revamp

### A1. Shapes: circles for node-logic, rectangles for containers
- **Modules → CIRCLES** (node-logic). Swap `rect`→`circle` in
  `render()` (topology-graph-view `:284-331`).
- **Polari containers (`InstanceDefinition`) → larger RECTANGLES**, and
  the modules assigned to a container are drawn **strictly inside** its
  rectangle (containment layout — replaces the flat `layout()` `:171-204`).
- Hosts (`PolariNodeMachine`) → the outermost rectangle a container sits
  in (optional grouping), so the nesting reads host ▸ container ▸ modules.

### A2. Module dependency semantics (per-module classification)
Derive from in/out degree over the dependency graph (compute reverse edges
by inverting `ModuleDependencyEdge` / `boundary_graph`):
- **consumer** — depends on other modules (has outbound deps).
- **provider** — depended on by others (has inbound deps).
- **hybrid** — both.
- **independent** — neither ("does not care").
- **data-only** — a module that is just stored class/data information,
  available but with no logic dependencies (a flag on `PolariModule` /
  boundary; the user's "some modules are just data and class information").

### A3. Nesting: a module's dependencies drawn inside it
"The modules it depends on should all be nested inside of it." For a module
`M` with deps `[A,B,C]`, render `A/B/C` as smaller circles **inside** `M`'s
circle. Recursive to a depth cap. This makes a "larger module composed of
multiple modules" literally contain its parts.

### A4. Transient (shared) dependencies → dashed/dotted border
"All but one of the modules, if used by multiple modules as a dependency,
should be transient." Rule:
- A dependency module used by **N>1** consumers is drawn once as the
  **primary** (SOLID border) under a canonical owner, and **N−1 transient
  copies** (DASHED/DOTTED border) nested under the other consumers.
- **Duplicate nodes are intentional** — the user wants duplicates shown
  when a larger module is composed of multiple modules. Transient copies
  are those duplicates, visually marked as references, optionally linked to
  the primary with a thin connector.
- Canonical-primary choice: deterministic (e.g. the consumer with the
  shortest dep path / first alphabetical — same determinism as
  `resolve_edges()`), stored so it's stable.
- NOTE: dashed currently means `ServiceConnection` in the renderer
  (`:272-274`). The revamp repurposes border-dash for **transient
  dependency**; service connections move to a different visual (e.g. thin
  colored connector lines, not node borders) so the two don't collide.

### A5. Backend additions (small)
- `topology_modules`: a reverse-edge/degree computation +
  `is_transient` + `is_primary` designation on `ModuleDependencyEdge` (or a
  computed graph endpoint). One deterministic pass, like `resolve_edges`.
- `boundary_graph()` gains reverse edges (`dependents:[...]`) so the module
  graph is bidirectional.
- Frontend model `topology-types.ts` gains node `shape`, `nesting`,
  `transient`, `dataOnly` fields.

### A6. Module display refinement
Converge the flat cards + text tree into the **same circle/nesting
graph** (a "modules" view of the revamped renderer): modules as circles,
grouped by container, nested by dependency, transient copies dashed. Keep
the enable/disable + detail actions as node interactions. The
`module-dependency-explorer` text tree becomes a fallback/list view.

---

## PART B — Tech Tree (expansion of topology)

### B1. Concept
A Tech Tree reuses topology's node-logic + container rendering, but:
- **Rectangular containers = TECHNOLOGIES** (not Polari containers).
- Each technology has up to **4 SEGMENTS**, each shown ONLY if populated
  (something relevant assigned from modules/artifacts):
  - **Theory (BLUE)** — code + simulations. Tracked by Polari MODULES.
  - **Real/Physical (RED)** — finalized CAD + hardware design data proven
    to work, paired with a **commercial route** AND an **open-source
    self-manufacture route**.
  - **Business (YELLOW)** — business-logic policies + increasing scales of
    business (one person → a business that fits a full unit economy and
    sustains itself), + examples of how those businesses worked out.
  - **Politics (PURPLE)** — policy done to increase/decrease the odds of
    success on those business models.
- A node with only theory is a solid blue rectangle; a theory+real node is
  split blue/red; a full node is quartered blue/red/yellow/purple. Only
  present segments take space.
- **Completion level per node** — rolled up from the completeness of each
  present segment (fraction of assigned items done/proven). When **all
  nodes complete → Open Source Economic Baseline**.
- Tech→tech **dependencies** reuse Part A's nesting + transient-dashed
  logic (a technology depends on other technologies).

### B2. Data model (new, mirrors topology-as-data)
- **`TechTreeDefinition`** (like `TopologyDefinition`): `name`, `owner`
  (org/business — configurable per org), `description`, `is_active`,
  `is_baseline` (the canonical Open-Source-Economic-Baseline tree). A
  business defines its OWN tree = the technologies it depends on to do
  business.
- **`TechNode`** (a technology): `name`, `tree_name`, `description`,
  `depends_on_json` (tech deps), layout hints; `segments_present` +
  `completion_level` are DERIVED (never hand-set — like drift/observation).
- **`TechSegment`**: `tech_node`, `kind` (theory|real|business|politics),
  `weight`, derived `completion`.
- **`TechSegmentAssignment`** — the join that fills a segment:
  - theory ← `module_name` (a Polari module/boundary; theory completion =
    the module's build/verify state).
  - real ← a `RealArtifact` (below).
  - business ← a `BusinessModelDefinition`.
  - politics ← a `PolicyDefinition`.
- **`TechDependencyEdge`**: `tech_node → depends_on_tech`, with the same
  `is_transient`/`is_primary` computation as modules.

### B3. Segment-content objects (real / business / politics)
- **`RealArtifact`**: `cad_ref` (mathshapes / CAD import — already exists),
  `hardware_design_ref`, `proven` (bool + `evidence_json`),
  `commercial_route_json`, `self_manufacture_route_json`. Real completion =
  proven AND both routes documented.
- **`BusinessModelDefinition`**: `scale` (one-person → small-team →
  unit-economy), `policies_json`, `unit_economics_json`, `self_sustaining`
  (bool + evidence). The "increasing scales" ladder is an ordered set.
- **`BusinessOutcome`**: an example of how a business model worked out
  (evidence for the business/politics segments).
- **`PolicyDefinition`**: `policy`, `effect` (increase|decrease odds),
  `target_business_model`, `evidence_json` (examples/outcomes).

### B4. Completion rollup (reuse the conformance pattern)
Follow the `MultiScaleSimulationProfile` "declarative naming + conformance
+ suggestions, never codegen" idiom ([[materials-science-module]]):
- Segment completion = fraction of its assignments meeting their
  done-criterion (theory: module verified/live; real: proven+both routes;
  business: self-sustaining evidenced; politics: policy+evidence).
- Node completion = weighted mean over PRESENT segments.
- Tree completion = mean over nodes; baseline "achieved" when 100%.
- Every gap is evidence-bearing (knobs-and-suggestions): "real segment 0%
  — no proven CAD/hardware; needs blcnc-CAD".

### B5. The Open Source Economic Baseline tree (seed)
Nodes = the 13 domains in `~/Desktop/Open-Source-Economy-Notes/`, with
theory segments wired to EXISTING modules (theory half is already
substantially built):

| Tech node | Theory (module) — mostly DONE | Real / Business / Politics |
|---|---|---|
| Wax materials | materialsScience (wax) + waxsupply | TODO |
| 3D printing + extrusion | **waxprint** (wp-1..8) | TODO CAD/hardware |
| Filament formulation | materialsScience formulation | TODO |
| Carbon nanotubes | materialsScience CNT family | TODO |
| Solid-state battery + semiconductors | electrodevice + msci | TODO |
| **Bombastic Laser CNC** | (BLCNC module — [BLCNC_PLAN](BLCNC_PLAN.md)) | TODO |
| Nanoparticles | msci nanoparticle family (LASiS) | TODO |
| Ceramics + composites | materialsScience ceramics/geopolymer | TODO |
| Electromagnetic systems | msci ferrite/magnetics + hardware | TODO |
| Open-source hardware | [[polari-hardware-architecture]] + hwsim | partial |
| Computational methods | the Polari framework (FEM/DFT/MD/meso) | n/a |
| Household nutrition / agroforestry | aquaponics + nutrition + tanks | partial |

This reframes the whole suite: the **theory baseline is ~built**; the tech
tree makes the remaining real/business/politics work legible.

**The BLCNC/PVD worked example (drives the first real tech-tree slice).**
The [BLCNC_PVD_ROADMAP.md](BLCNC_PVD_ROADMAP.md) 5 intertwined phases are
seeded as connected `TechNode`s under the Bombastic-Laser-CNC + a new
Open-Source-PVD node — the concrete example that exercises dependencies,
nesting, transient edges, and per-segment completion:

| TechNode | theory (blue, module) | real (red) | depends_on |
|---|---|---|---|
| P1 Ideal melt-voxel proof | blcnc melt-voxel + LaserOperation sim | — | — |
| OS-PVD theory | os-pvd deposition sim | — | — |
| P2 Theoretical chip | PVD+melt-voxel cycle sim | — | P1, OS-PVD |
| P3.1 Stochastic materials | stochastic-nanocomposite sim | — | (priors) |
| P3 Feasible production | feasibility sim | — | OS-PVD, P2, P3.1 |
| P4 BLCNC hardware (parallel) | hwsim twin | CAD + Al heat-cal voxel | — |
| P5 Combined microfab device | integration sim | integrated CAD | P3, P4 |

As each phase's modules land, its theory segment fills and node completion
rises; the real segments fill from Phase-4/5 CAD/hardware; when the slice
is 100%, this corner of the OSEB is proven. This is exactly how the real
OSEB tree gets flushed out node-by-node as work completes.

### B6. Configurability
- Any org creates a `TechTreeDefinition(owner=...)` and its own `TechNode`s.
- Theory segments reference that org's modules (Polari modules are the
  theory-tracking substrate for anyone).
- A business's tree = the technologies it depends on to operate; split
  theoretical (module-tracked) vs real; the completion rollup tells them
  where their self-sufficiency gaps are.

---

## Shared renderer (one component, two modes)
Both topology and tech tree are the same graph:
- **nodes**: circles (modules / node-logic) or split-segment rectangles
  (technologies), inside container rectangles.
- **nesting**: dependencies drawn inside their owner; depth-capped.
- **transient**: dashed/dotted borders for N−1 shared-dependency copies;
  duplicates intentional.
- **containers**: Polari containers (topology) or technologies (tech tree).
- **completion**: a ring/fill on tech nodes.
Implement as a revamp of `topology-graph-view.component.ts` parameterized
by mode, so improvements land in both.

## Phasing (tt-N, when green-lit — NOT now)
1. **tt-1** backend: reverse-edge/degree + transient/primary computation
   for modules (shared), `boundary_graph` bidirectional. Selftest.
2. **tt-2** renderer revamp: circles + container nesting + transient dashed
   + duplicate nodes (topology mode first). Dustin visual review.
3. **tt-3** TechTree data model (B2) + completion rollup (B4) + API.
4. **tt-4** tech-tree render mode: 4-segment colored nodes, only-if-applies,
   completion rings.
5. **tt-5** seed the Open Source Economic Baseline tree (B5); wire existing
   modules → theory segments; compute the current baseline %.
6. **tt-6** real/business/politics objects (B3) + assignment + a couple of
   real examples (waxprint CAD, a one-person business model).
7. **tt-7** module-display convergence (A6) + per-org configurable trees
   (B6).

## Open questions (for Dustin)
- Politics segment color — purple, or green? (spec said "another color").
- Business as a genuine 3rd segment + politics 4th (confirmed in the ask)
  vs. folding business under real — the plan takes the 4-segment reading.
- Completion criteria per segment — the done-tests above are a first cut;
  Dustin may want explicit gates (like the waxprint condition gates).
- Should `PolariModule` gain a `data_only` flag + a `techNodeRef`/segment
  hint now, so modules self-declare their tech-tree placement?
- Host▸container▸module triple nesting in topology, or just
  container▸module?
