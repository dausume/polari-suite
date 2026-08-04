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
2. **Nothing groups assignments by the database they land in.** The
   pieces exist — `InstanceDefinition.db_backend` is the per-instance
   `pol db` choice, and `ModuleAssignment.instance_name` puts modules
   on instances — so a module's database is already determined by its
   instance. What is missing is the *grouping*: summing what every
   module on a given storage identity weighs. Dustin's worry —
   *"the database we plan to link it to is somewhere we are also
   planning multiple other pieces with a lot of seed data"* — is a
   question about that sum, and nothing computes it. **This is not a
   new placement axis**; see app-3.
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

**Overlap is the point, not a detail.** Two apps wanting the same
module SHARE one copy: it installs once, occupies one instance, and
seeds its data once. So every module carries `wantedBy: [app, ...]`
and is counted ONCE in every total. Two consequences to honour:

- A portfolio of five overlapping apps can be far cheaper than five
  standalone ones — the whole reason to plan a set rather than apps
  one at a time.
- Removing one app frees only the modules NOTHING else wants. The
  `wantedBy` list is what makes that answerable, so it must survive
  into the plan output rather than being collapsed away.

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

### app-3 — Storage co-tenancy, via the instance (CORRECTED)

⚠ **Correction to the first draft (Dustin, 2026-08-04).** That draft
proposed a `StorageEndpointDefinition` you assign modules to. That is
the wrong shape and would duplicate what exists.

**The database is a property OF the instance, and assigning a module
to an instance IS assigning it to that database.** The model already
says so:

- `InstanceDefinition.db_backend` — `DB_BACKENDS = ('sqlite',
  'mariadb', 'mariadb+keydb', 'postgres')`, documented as "the
  `pol db` choice for this instance".
- `ModuleAssignment.instance_name` — modules are assigned per
  instance.
- `config.yaml`: `database.type` (env `DATABASE_TYPE`) with
  `sqlite.path: ./data/polari.db` and `mariadb.host/database`.

So: **the KIND is configurable, the specific database is not chosen
separately — it follows from the instance.** No new assignment axis,
no new object to point modules at. We *de jure* assign storage by
choosing the PRF-level database.

**The rule that makes sqlite different, and must be enforced:**

> For a PRF instance, `sqlite` always means the sqlite that *that
> instance* creates locally. It is not shareable and must never be
> configurable to point elsewhere.

That is not a limitation to work around — it is what makes sqlite
co-tenancy trivially bounded.

**Storage identity** — the group key co-tenancy is computed over:

| `db_backend` | identity | who can share it |
|---|---|---|
| `sqlite` | **the instance itself** | nobody — local by construction |
| `mariadb` / `mariadb+keydb` / `postgres` | the server + database it points at | every instance pointing at the same one |

`storage_load(manager, identity)` then means:

- **sqlite** — the modules assigned to this one instance. Capacity is
  the disk of the `machine_name` it is pinned to (`PolariNodeMachine`
  → `node_resources`). A crowded sqlite is an *instance* problem and
  the fix is moving modules to another instance.
- **mariadb** — the modules across **every instance sharing that
  server**. This is the case Dustin described: several PRFs each
  looking reasonable alone, jointly overloading one database. The fix
  may be a different backend for one of them, not a module move.

**Verdicts** (unchanged in spirit, now correctly scoped):

```
crowded           combined seeded bytes > declared capacity share
hot-contention    several 'hot' access_pattern modules co-resident
mixed-durability  ephemeral and durable sharing one server
fits              and by how much headroom
```

Each names the modules that make it true, the instances involved, and
whether relief is a module move (sqlite) or a backend change
(shared server).

**Honest gap to resolve during the build:** `db_backend` records the
KIND; the specific mariadb host/database lives in config/env
(`MARIADB_HOST`), not in the topology rows. So "which instances share
a server" is not currently derivable from the object tree. Either
observe it per instance, or add an explicit identity field — and
until then, **state the assumption** ("all mariadb instances in this
topology are treated as one server") rather than silently assuming it.

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
- **Capacity is a policy, not a fact.** A storage budget is declared,
  not measured — say so. The exception is sqlite, whose ceiling IS the
  measured disk of the machine its instance is pinned to.
- **Never let sqlite look shareable.** Any UI or API that presents
  storage must show a sqlite identity as belonging to its one
  instance. Offering to "point it at" another database would be
  offering something that cannot exist.

---

## 5. Suggested order

app-6 (coverage) in parallel with app-1 (set arithmetic) → app-2
(seeded weight) → app-3 (storage co-tenancy — the distinctive part)
→ app-4 (portfolio verdict) → app-5 (balancer) → app-7 (UI).

app-3 is where the real new capability is — but it is smaller than
the first draft assumed, because the assignment axis already exists.
It is not a new placement target; it is **grouping existing
assignments by the storage identity their instance implies**, and
then summing seeded weight over each group. That is what makes the
"too much seed data pointed at one database" question answerable, and
it is mostly arithmetic over rows that are already there.
