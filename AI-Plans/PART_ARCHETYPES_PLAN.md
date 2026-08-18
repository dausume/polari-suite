# Part archetypes + composition — schema and build plan

> **STATUS 2026-07-31 (Fable 5): arch-1..7-backend BUILT + verified**
> on `dev-arch-part-composition` (framework `1611e0f`, NOT pushed).
> Suites: composition selftest 74/74, liveboot probe 19/19 (incl.
> the live upsert-convergence proof), motors 242/242, magnetics
> 51/51 + probe 39/39, gears 62/62. **Remaining:** the `/composition`
> Angular page (arch-7 UI) and arch-8 (motors compat shim, M0
> end-to-end in composition rows); live deploy to pol-core.

**Follows `PART_COMPOSITION_HANDOVER.md` (observed behaviour) and
`PART_COMPOSITION_PRACTICE_MAP.md` (professional shapes to borrow).**
This is the buildable design: classes, derivations, phases, acceptance.
Everything here follows Polari scaffolding (treeObject → table + CRUDE
API), the knobs-and-suggestions ethos (checks refuse or suggest, never
auto-apply), and object coherence (every capability is an object-tree
node configurable to data).

Naming: phases are **arch-N**. Worked example throughout = the M0
Lavet motor and the mag-26 stator construction variants, because they
already exercise every feature the schema needs.

---

## 0. arch-0 — decisions for Dustin (recommendations attached)

> **2026-07-31: recommendations ADOPTED AS DEFAULTS** (Dustin approved
> proceeding; session ran in don't-ask mode). Each remains overridable
> at review — an override renames/moves data, none of them strands it.

1. **Module home.** Recommend a new module `modules/composition/`
   (requires: mathshapes, techtree; consumed later by motors/gears —
   dependency points *up* into composition, never back). Alternative:
   grow it inside motors and extract later — not recommended; the
   handover's whole point is that this is domain-general.
2. **Migration of `MotorPartDefinition`.** Recommend *wrap, don't
   port*: motors keeps its rows; a compat shim exposes each motor part
   as a composition `PartComponentDefinition`/member so the new
   engines can read them. Full port is a later phase once the schema
   has survived contact.
3. **Where material condition lives.** Recommend a `condition` key on
   property rows (per practice: C11000-**H02** vs **O60**), added to
   `MagneticMaterialOption.properties_json` entries and any future
   generic property store — absent condition = "unstated", which
   screens like any missing datum (unassessed, never a pass).
4. **Scope of arch-5 archetype seeds.** Recommend starting with the
   parts this arc actually built: coil/winding, spool/bobbin, pinion,
   shaft, magnet rotor — five archetypes, all with live equations
   already in `physics_equations.py`.

---

## 1. Design invariants (from the handover, non-negotiable)

- **Level is DERIVED, never stamped.** Component/part/assembly follow
  from structure (§2.2 below). A row may *declare* an intended level;
  a mismatch between declared and derived is a refusal with the
  reason, same discipline as viability in `part_roles`.
- **Promotion attaches to a named interface set** (mag-26), is a
  recorded operation, mints a **new identity** with genealogy, and
  records what it deleted, introduced, and spent.
- **Predicates keep both refinements**: requirement vs disqualifier
  mode; threshold/objective/penalty grading. Missing data →
  `unassessed`, never a pass; a data gap is never reported as a
  finding.
- **Design the seed upsert path FIRST** (ten strikes — §3.11 of the
  handover). No composition table ships until its seeds go through
  upsert-changed-fields.
- Every check can still say **"I do not know, and here is what would
  tell us."**

---

## 2. The schema

### 2.1 `PartComponentDefinition` — single-material element

Generalizes the material-facing half of `MotorPartDefinition`.

```
name, display_name
material_ref          # by name into msci/magnetics/supplychain — loose ref
material_condition    # temper/condition key ('' = unstated)
shape_ref, shape_units  # mathshapes row + explicit units (the 1.1 kg lesson)
coating_ref           # DISTINCT from material (handover §3.4)
coating_build_mm      # enters geometry as a square, so it is a field
process_state_ref     # routing op that produced this condition ('' = as-received)
quantity, notes, provenance_id
```

### 2.2 `CompositionNode` — the tree, with derived levels

One class for the structure; **level is computed**:

```
name, display_name, declared_level   # '' | component|part|subassembly|assembly
members_json          # [{ref, kind: component|node, quantity}]
interface_refs        # InterfaceDefinition names owned by this node
functional_ref        # FunctionalPartDefinition this node realizes ('' ok)
genealogy_ref         # the node this identity was PROMOTED from ('' ok)
```

Derivation (`derive_level()`):
- no members, one material row → **component**
- members present, **every** interface `designed_separable=False` →
  **part** (promoted or processed-whole)
- any separable interface → **assembly** (or **part with separable
  sub-parts** when some interface sets are promoted — the mag-26
  layered stator; reported as `part`, with the separable set named)
- declared ≠ derived → refusal naming the interface(s) that decide it.

### 2.3 `InterfaceDefinition` — first-class, the load-bearing row

```
name
node_ref              # owning CompositionNode
member_a, member_b    # member refs within that node
designed_separable    # bool — THE level-deciding bit
dof_removed_json      # subset of [tx,ty,tz,rx,ry,rz] — a CAD mate
retention_scheme      # snap|groove|fastener|adhesive|mortar|press|none
retention_material_requirements_json
                      # mag-26 req 3: snap features may need a tougher
                      # material than the body — role predicates, reused
                      # from part_roles shape
failure_mode_refs     # into FailureModeDefinition — INTERFACE-locus modes
equation_refs         # interface equations (friction, preload, fretting)
realization_level     # IRL: interfaces earn evidence like parts do
qualifying_act        # the named measurement that would promote it
```

### 2.4 `FailureModeDefinition` — one catalogue, two loci

```
name, domain          # part_roles DOMAINS, reused
locus                 # 'interface' | 'bulk'
summary
equation_ref          # governing equation if modelled ('' = named gap,
                      # stated loudly — the Hertzian-contact discipline)
evidence_note         # what observation would confirm/deny it
```

Seeds from this arc: fretting, fastener back-out, preload loss,
turn-to-turn abrasion (interface); brittle fracture w/ Weibull derate,
subcritical crack growth, Archard wear, potted-winding crack-short,
thermal-mismatch residual stress (bulk).

### 2.5 `FunctionalPartDefinition` + `ConstructionVariantDefinition`
###     — the EBOM/MBOM split

```
FunctionalPartDefinition:
  name, purpose                     # what the design needs
  allocated_role_refs               # part_roles roles — allocation-side
  archetype_ref                     # §2.7
  tunable_toward                    # allocation-side (handover §5.4):
                                    # a property of the SLOT, not the casting

ConstructionVariantDefinition:      # generalizes stator_construction.VARIANTS
  name, functional_ref
  node_ref                          # the CompositionNode it builds
  routing_ref                       # §2.6 — step count DERIVES from it
  fill_factor_class                 # scramble|ordered-rigid-floor|ordered-nested
                                    # — a property of the CONSTRUCTION (mag-26)
  selection_rationale               # inspectability vs packing vs cost —
                                    # what this variant is FOR
```

### 2.6 `RoutingDefinition` / `RoutingOperation` — process history,
###     and promotion as an operation kind

```
RoutingOperation:
  name, routing_ref, sequence
  kind                  # shape | join | condition-change | PROMOTE
  capability_rung_ref   # techtree ladder rung this op assumes (wire_ladder
                        # pattern) — REQUIRED; optimisation output is
                        # inadmissible without it (handover §3.2)
  purpose_class         # rate|yield|tolerance|physics — so industrial
                        # specs can be re-derived at our volume (§3.8)

  # PROMOTE-kind fields:
  consumes_interface_refs   # the NAMED SET being fused
  emits_node_ref            # the NEW identity (genealogy_ref points back)
  modes_deleted_refs / modes_introduced_refs
  reversibility_spent       # repairability → lifecycle_cost term
  dfa_justification_json    # Boothroyd–Dewhurst 3 answers per consumed
                            # member: moves-relative? different-material?
                            # separable-for-service? — the gate
  qualifying_act            # the named experiment that earns realization
```

Equation retirement is **by construction**: interface equations belong
to interface rows; PROMOTE consumes those rows into the genealogy
record, so nothing dangling can keep answering (handover §5.3, closed).

### 2.7 `PartArchetypeDefinition` — the machine-elements schema

```
name                    # coil-winding | bobbin | pinion | shaft | magnet-rotor …
parameter_set_json      # named knobs w/ units (gauge, turns, window, …)
equation_refs           # EquationDefinition rows, per level
failure_mode_refs       # the catalogue subset this archetype is prone to
role_refs               # material-facing half — part_roles, reused
selection_procedure     # ordered checks, as data (the Shigley recipe)
design_matrix_ref       # §2.8
```

### 2.8 `DesignMatrixDefinition` — cancellation as data

```
name, archetype_ref
entries_json        # [{knob, outcome, coupling: none|direct|inverse|both}]
                    # 'both' = the mag-22 ratio trap: one parameter feeds
                    # numerator AND denominator (handover §3.1)
classification      # DERIVED: uncoupled | decoupled | coupled
tuning_order_json   # REQUIRED when decoupled — the M0's is
                    # gauge → window → turns
```

`classify()` derives the classification from entries; **coupled is a
loud finding, not an error** — it names exactly where optimising one
objective moves another. The M0 seed is the acceptance test: it must
come out *decoupled* with that tuning order.

### 2.9 Model validity + realization (extend, don't add)

- Validity regime stays **data on the model** (`model_validity`
  pattern from `motors/inductance.py`) — arch adds nothing new, but
  archetype equation refs may carry a `validity_ref`.
- Realization ladder stays per-property with provenance
  (`MagneticMaterialOption` pattern); interfaces get `realization_level`
  (§2.3) — assemblies get theirs **derived**: min over members and
  interfaces, which answers handover §5.5 the IRL way.

---

## 3. Polari modularization

Composition must sit **low** in the module graph, because its whole
premise is domain-generality: motors, gears, and eventually magnetics
consume it — never the reverse.

### 3.1 Registry entry and wave

`polari-modules.json`:

```
"composition": {
  "kind": "official", "downloaded": true,
  "path": "modules/composition", "repo": "",
  "requires": ["mathshapes", "techtree"],
  "wave": 2,
  "description": "Part composition: components/interfaces/promotion,
                  EBOM-MBOM split, archetypes + design matrices."
}
```

Wave 2 (with supplychain/techtree), *below* magnetics/motors at
wave 3. Split-readiness from day one: the module is written so a
future `polari-module-composition` repo split is a move, not a
refactor (no reach-ins from other modules except through its API and
data rows).

### 3.2 Code dependencies vs data references — the bizops rule

- **Imports** (code): only `mathshapes` (shape rows → volume/mass) and
  `techtree` (capability rungs). Nothing domain-specific, ever.
- **Material/equation references are DATA, not imports** — the mag-8
  pattern ("bizops reads MagneticMaterialOption without importing
  magnetics"). `material_ref`/`equation_refs` resolve by manager
  lookup at runtime; if the module owning the row is not booted, the
  resolver **refuses honestly** (`module-not-booted`, naming it) in
  the lazy-boot/503 style — never a silent empty.

### 3.3 The extraction: `part_roles` moves DOWN into composition

`motors/part_roles.py` is the material-facing half of an archetype and
is already domain-general (5 domains, predicates as data). It cannot
stay in motors once motors requires composition. **arch-2 extracts it
to `composition/part_roles.py`; motors keeps a one-line re-export shim
so its imports and selftests are untouched.** Same treatment is NOT
needed for `physics_equations.py`: equation *rows* are core
`EquationDefinition` data reachable by name, so archetype
`equation_refs` cross module boundaries as data (§3.2) and the
motors-domain seeds stay where they are.

After arch-8 the graph reads:

```
mathshapes  techtree
     \        /
    composition          (wave 2)
     /        \
 motors      gears …     (wave 3 — requires gains "composition")
```

### 3.4 Module-internal layout (file-size discipline)

Follow the magnetics convention — one concern per file, basis/api/seed
split, selftests in-module:

```
composition/
  __init__.py            # module surface, boot registration
  component_basis.py     # PartComponentDefinition
  node_basis.py          # CompositionNode + derive_level()
  interface_basis.py     # InterfaceDefinition
  failure_modes.py       # FailureModeDefinition + seeds
  functional_basis.py    # FunctionalPartDefinition, ConstructionVariantDefinition
  routing_basis.py       # RoutingDefinition/Operation + PROMOTE + DFA gate
  archetype_basis.py     # PartArchetypeDefinition
  design_matrix.py       # DesignMatrixDefinition + classify()
  part_roles.py          # extracted from motors (arch-2)
  seed_upsert.py         # arch-1 — shared upsert-changed-fields path
  composition_seed.py    # seeds, THROUGH seed_upsert
  composition_api.py     # /api/composition/*
  selftest_composition.py
  composition_liveboot_probe.py
```

Registration gotchas carried forward: every new class lands in
`defClassList` (mag-11: the entry that silently didn't land — grep
every polariServer edit), and every new part-bearing row sets
`shape_units` explicitly.

---

## 4. Phases

| Phase | Content | Acceptance |
|---|---|---|
| **arch-1** | **Seed upsert path.** `seed_upsert.py`: diff existing row against current seed, PUT changed fields (the `--form-string` shape, §3.11), report `{inserted, updated, unchanged}`. Wired into composition seeding from day one. | Selftest: mutate a live row, reseed, field converges; untouched fields survive. |
| **arch-2** | Core rows: `PartComponentDefinition`, `CompositionNode`, `InterfaceDefinition`, `FailureModeDefinition`; `derive_level()` + declared-vs-derived refusal; failure-mode seeds from this arc; **`part_roles` extraction** (§3.3) + module scaffold/registry entry (§3.1). | The three mag-26 stator constructions expressed as nodes derive **assembly / part / part-with-separable-sub-parts** respectively, from their interface rows alone; motors suites green through the re-export shim. |
| **arch-3** | EBOM/MBOM split: `FunctionalPartDefinition`, `ConstructionVariantDefinition`; `stator_construction.VARIANTS` re-seeded as variant rows of ONE functional stator; fill-factor-class carried per variant. | `compare_variants` answers reproduced from the new rows (0.527 vs 0.600 groove result intact). |
| **arch-4** | Routing + PROMOTE: `RoutingDefinition`/`RoutingOperation`, DFA gate, genealogy, capability-rung requirement, `purpose_class`. Promotion is a **suggestion over evidence** (mag-12 pattern) — never auto-applied. | Promoting the bound stator: interface modes (fretting, abrasion) vanish from the emitted node's mode set; brittle-crack-short + residual stress appear; repairability spend prices through `lifecycle_cost`. Step counts 1/3/4 derive from routings. |
| **arch-5** | Archetypes + design matrix: 5 archetype seeds (arch-0 §4), `DesignMatrixDefinition` + `classify()`; equation refs into existing `physics_equations.py` rows (extend that table, never fork it). | M0 matrix derives **decoupled**, tuning order gauge→window→turns; a deliberately coupled seed (Lavet magnet: remanence → torque *and* detent, coupling `both`) is reported as the §3.1 finding. |
| **arch-6** | Interface realization + qualifying acts; assembly realization derived (min rule); condition key on property rows (arch-0 §3). | The one-LCR-reading act (mag-23) representable as an interface/model qualifying act; unstated condition screens as unassessed. |
| **arch-7** | API `/api/composition/*` + object-tree wiring + `/composition` page (tree w/ derived-level chips, interface panel, promotion record view, matrix view). Selftests + liveboot probe. | Browser pass; probes green; motors/gears suites untouched. |
| **arch-8** | Motors splice: compat shim reading `MotorPartDefinition` as members; M0 expressed end-to-end in composition rows. | motors selftests still green; M0 composition tree renders with the same bill/mass as mag-11. |

Branch: `dev-arch-part-composition` off the current consolidated dev
line, per branch-per-confirmed-phase. Each phase lands with its
selftests before the next starts.

---

## 5. Out of scope (named, not silent)

- Porting gears/magnetics content into composition rows (arch-8 does
  motors only; the rest follows the same shim pattern later).
- Generic tolerance stack-up across interfaces (the mm/cm and
  square-law lessons are carried as fields; a stack engine is its own
  phase).
- Auto-deriving failure-mode applicability from geometry (modes are
  seeded per archetype; derivation is a later refinement).
- Resolving the mag-26 snap-fit material conflict — the schema can now
  *state* it (`retention_material_requirements_json`); solving it is
  materials work.
