# APP PORTFOLIO PLANNING — "I want these apps; where does it all go?"

**Status 2026-08-04: PLAN ONLY. Nothing below is built.**

The ask (Dustin): define the whole set of apps we want, judge how
reasonable that proposal is against real resources, notice when too
much seed-heavy data is aimed at one database, and be able to say
"just give me these apps" and have Polari balance the modules and
databases across the devices we actually have.

---

## 1. What already exists (do NOT rebuild these)

This is closer to done than it looks. The per-module machinery is
built and tested; what is missing is mostly **set-level** and
**database-level**.

| Capability | Where | State |
|---|---|---|
| App = modules + pages + nav, as data | `PolariAppDefinition` | done |
| Author an app by hand | `/apps/build` (2026-08-04) | done |
| Per-app plan vs a topology | `apps_analysis.app_plan` → already-placed / needs-assignment / missing, readiness, `pol allocate` command | done |
| Apply an app (rows only) | `POST /api/apps/apply`, writes `ModuleAssignment` + `AppDeploymentPlan` receipt | done |
| Per-module resource profile | `ModuleResourceProfile` — `min_ram_mb`, `min_disk_mb`, `min_threads`, `thread_ceiling`, `cpu_benefit`/`ram_benefit`, `image_mb`, `deps_mb`, `est_row_bytes`, `growth_rate`, `access_pattern`, `durability`, `character` (compute\|data\|balanced) | **model done, data 13%** |
| Real device specs | `resources.node_resources.local_node_specs` — cores, RAM, disk, cgroup limit, from psutil/shutil | done |
| Single-module placement verdict | `resources.admission_advisor` — `route-to-storage` \| `fits-as-is` \| `fits-with-reallocation` \| `would-break`, benefit-aware (single-threaded → **smallest** adequate node; scaling → biggest), every verdict an evidence-bearing suggestion | done |
| Live data volume of a module | `profile_measure.observed_data_footprint` — data classes × predicted row bytes, labelled `estimate-x-count` | done |
| Module content closure | `polariPeers.module_exporter` — what rows a module actually carries | done |
| Moving a module safely | `pol allocate --graceful`, `MoveOperation` | done |

**The single most important fact for scoping this work: only 5
`ModuleResourceProfile` rows exist for 37 modules on this node.** The
algorithms below are largely already designed; without profile
coverage they would answer "unknown" for 87% of the estate.

---

## 2. The gaps, precisely

1. **Everything is per-MODULE, not per-SET.** `app_plan` handles one
   app; `admission_advisor` judges one module against the topology.
   Neither composes: two apps wanting the same module double-count,
   and nothing sums a portfolio's floors against a device's capacity.
2. **The database is not a placement target.** The advisor emits
   `route-to-storage` and names a backend *kind* (redis/sqlite/
   mariadb), but there is no object for "the MariaDB at
   shared-infra", no capacity on it, and no notion of what is already
   sitting there. Dustin's exact worry — *"the database we plan to
   link it to is somewhere we are also planning multiple other pieces
   with a lot of seed data"* — cannot currently be expressed.
3. **Seed volume ≠ observed volume, and only the latter exists.**
   `observed_data_footprint` measures what is in the tables NOW. What
   a fresh node would *inherit* by enabling a module is a different
   number, and it is the one that matters when planning. The exporter
   already computes a module's row closure — nobody has multiplied it
   by row bytes.
4. **No auto-plan.** Every verdict is a suggestion about one thing.
   Nothing searches the assignment space for a balanced allocation.
5. **Profile coverage is 13%.** See above.

---

## 3. Proposed phases

Ordered so each lands something usable and the risky part comes late.

### app-1 — Portfolio demand (set arithmetic)

New object `AppPortfolioProposal`: `{name, app_names[], topology,
notes}` — the "these are the apps I want" row.

`portfolio_demand(manager, proposal)` returns the **deduplicated**
module union across the apps, and for each module its profile. Sums:
floors (`min_ram_mb`, `min_disk_mb`, `min_threads`), install footprint
(`image_mb + deps_mb`), and counts by `character`.

Honesty contract: a module with no `ModuleResourceProfile` is listed
under `unprofiled[]` and **excluded from the totals**, which are
labelled `partial`. Never assume zero — an unprofiled module is an
unknown, not a free one. This is the existing "honest absence" rule.

*Deliverable:* `GET /api/apps/portfolio/demand?proposal=X`.

### app-2 — Seeded data weight

`seeded_data_weight(manager, module)`: the rows a module CARRIES
(reuse `module_exporter`'s closure walk — it already knows) ×
`estimate_row_bytes` per class. Cache on the profile as
`seeded_rows` / `seeded_bytes`.

This is the number Dustin asked for: *the seed data inherent to a
particular set of modules*. Report seeded and observed side by side —
they answer different questions (what you inherit vs what has grown).

Label both `estimate-x-count`; neither is a measurement.

### app-3 — The database as a first-class target

New object `StorageEndpointDefinition`: `{name, kind
(sqlite|mariadb|keydb|postgres), instance_name, topology_name,
capacity_mb, notes}`. An instance declares which endpoint it uses for
object storage.

⚠ Grounding note: an instance CHOOSES local sqlite or a remote
MariaDB (`DATABASE_TYPE` / `DATABASE_PATH`) — this object must reflect
that choice, not assume one.

Then `storage_load(manager, endpoint)`: every `data`-character module
whose assigned instance points at this endpoint, with its seeded +
observed bytes, plus its `growth_rate` and `access_pattern`.

**The co-tenancy verdict** — the heart of the ask:

```
crowded        combined seeded bytes > share of capacity_mb, OR
               >N high-growth modules on one endpoint
hot-contention several 'hot' access_pattern modules co-located
mixed-durability ephemeral and durable sharing one endpoint
fits           and says by how much headroom
```

Every verdict names the modules that make it true and the endpoint
that would relieve it. Suggestion, never auto-applied.

### app-4 — Portfolio admission verdict

Lift the advisor's four verdicts from one module to a whole proposal,
per device:

- `fits-as-is` — every module places without violating a floor
- `fits-with-reallocation` — names the moves (reuse
  `suggest_reallocations` / `pol allocate --graceful`)
- `would-break` — names the device, the **limiting resource**, and
  what to add
- plus the app-3 storage verdict, reported alongside — a portfolio can
  fit on compute and still be a bad idea on data

*Deliverable:* `GET /api/apps/portfolio/admission?proposal=X`.

### app-5 — Auto-plan (the balancer)

`balance(manager, proposal, topology)` → a proposed assignment set.

Rules, all reusing decisions already made elsewhere:
- **Compute:** keep the advisor's benefit-aware rule — a strictly
  single-threaded module goes to the *smallest adequate* node so
  scaling work keeps the big ones; `cpu_benefit: linear` goes to the
  biggest.
- **Data:** spread `data`-character modules across endpoints to
  minimise the worst endpoint's load, respecting `durability` and
  `access_pattern` (don't pile `hot` on one).
- **Affinity:** modules in the same app prefer the same instance
  (fewer cross-instance edges), *unless* that creates a storage
  crowd — the tension is real and must be reported, not hidden.
- **Determinism:** same inputs → same plan. Sort keys explicit,
  no `random`, no dict-order dependence. (`Date.now`/`random` are
  already banned in workflow scripts for the same reason.)

Output is an `AppPortfolioProposal` with a `placements_json` — a
**suggestion set** that flows into the existing apply path. It never
writes assignments itself. Every placement carries `why`.

Refusal beats a bad plan: if any module is unprofiled or any node
lacks observed specs, the balancer returns `partial` with those named,
rather than a confident allocation built on guesses.

### app-6 — Profile coverage (the unblocker)

**This gates the usefulness of app-1..5 and should run in parallel
from the start.** 5 of 37 modules profiled.

- Bulk-measure with the existing `profile_measure` machinery.
- `scan_module_source` already derives data classes; `estimate_row_bytes`
  already exists — the seeded/observed numbers are largely derivable.
- Floors (`min_ram_mb`, `min_threads`) need either measurement or an
  honest declared prior; mark which each is (`is_prior` pattern).
- Ship a coverage report: profiled / unprofiled, so the number is
  visible rather than discovered when a plan comes back `partial`.

### app-7 — UI

Extend the app builder rather than a new surface:
- a portfolio page: pick N apps → demand, storage load, admission
- the placement table gains a *why* column
- "auto-plan" produces the suggestion set; applying reuses the
  existing plan → review → apply flow, including its `confirm: true`
  guard and the "containers stay `pol topology apply`" contract

---

## 4. Risks and the honesty contract

- **Unprofiled modules are the main failure mode.** A totals number
  that silently omits 32 of 37 modules is worse than no number. Every
  aggregate carries `complete | partial` plus the names omitted.
- **Estimates must stay labelled.** Seeded and observed bytes are both
  `estimate-x-count`. Do not let a plan present them as measurements.
- **Nodes without observed specs are named, not guessed** — the
  advisor already does this; keep it.
- **Never auto-apply.** The balancer proposes; a human applies through
  the existing confirm-guarded path; containers still deploy only via
  `pol topology apply`.
- **Deduplication is load-bearing.** Two apps sharing a module must
  count it once for footprint but keep both provenance links, or
  removing one app will look like it frees resources it does not.
- **Capacity is a policy, not a fact.** `capacity_mb` on a storage
  endpoint is a declared budget. Say so; don't imply it was measured.

---

## 5. Suggested order

app-6 (coverage) in parallel with app-1 (set arithmetic) → app-2
(seeded weight) → app-3 (storage co-tenancy — the distinctive part)
→ app-4 (portfolio verdict) → app-5 (balancer) → app-7 (UI).

app-3 is where the real new capability is: it is the only phase with
no existing analogue in the codebase, and it is what makes the "too
much seed data pointed at one database" question answerable at all.
