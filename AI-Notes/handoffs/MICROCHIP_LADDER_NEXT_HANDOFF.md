# Next-session handoff: microchip LADDER arc (lad/fam) — 2026-08-31

**Read `AI-Notes/plans/MICROCHIP_LADDER_PLAN.md` first — it is the
ratified shape + phase table.** This handoff is the session entry point.

## Entry state (2026-08-31 evening)

Branches (NOT pushed — his `./push-all-dev.sh` ritual):
- framework `dev-lad-1` (tip `138007c`, branched off `dev-fg-1`):
  **fam-1 BUILT** — `microchip/chip_families.py`
  (`DeviceFamilyDefinition`: fet LIVE + 6 shells with
  contract-as-data; NO shell device classes by the schema-freeze
  rule), `GET /api/microchip/families[/{name}]`, families row on
  `/display/microchip`, defClassList + seed pairs registered.
  selftest_families 9/9, selftest_microchip 16/16.
- framework/angular `dev-fg-1`: the whole fg arc + multiscale LEVEL
  SCENES (cell/block 2-D/3-D, real-vs-blackbox LOD, upsert-on-GET
  `/api/fet/scene/...`) DEPLOYED + LIVE-VERIFIED on the dev swarm.
- suite dev: MICROCHIP_LADDER_PLAN + this handoff + pointer rolls.

Deploy state: backend image `prf-backend:staging` REBUILT with fam-1
but **NOT rolled** at write time (rolls held while the cells-advance
sweep runs; check `/api/fet/cells/advance` → `blankDevices` for the
live tail — 7 blank at write time, resilient sweep script running).
Closeout owed by the session that finds the sweep finished: ONE
batched `docker service update --force --image prf-backend:staging
polari-node_backend` (+ frontend if angular changed), then verify
`GET /api/microchip/families` live (expect 7 families, fet
liveRows > 0 on prf-a) and post the final ladder report.

## The ratified ladder (do not re-litigate — decided 2026-08-31)

device → standard-cell → functional-block → subsystem (core = a
KIND) → die (monolithic boundary) → package/chiplet-assembly →
exports ONE black-box PART into `composition` (computers/motors/RF
stay composition clients). Specialization = KINDS at ranks 3–4
(gpu-compute-unit, npu-tensor-array, sim-engine, memory kinds);
non-FET physics = FAMILIES at rank 1 (fam-1 shells); TRUE peer
ladders only when not litho-composed into a die AND different rung
structure (ladders are already data rows in chip_basis).

## Where to start (his gate D3: "next microchip-module session")

1. **lad-0 — rung migration** (the natural opener, small): in
   `microchip/chip_basis.py` rename rank 4 `core`→`subsystem`
   (+ a kinds field; core = first kind), rank 5 `chip`→`die`
   (D1 default: keep `chip` as an alias in traversal), ADD rank 6
   `package`. MIGRATE the seeded `MicrochipDesignNode` rows' `level`
   values (polari-chip, polari-rv32e-core, rv16x-* — see
   SEED_DESIGN_NODES) + `chip_traverse` + the microchip-ladder
   Angular component's level rail + selftest_microchip. Live rows
   need the CRUDE backfill treatment if seeds changed
   (INSERT-BY-NAME rule).
2. **THEN his D5/D6 pick**: capacitor family → 1T1C DRAM bitcell
   path (D6 default; graduates the first shell to live — its own
   arc defines CapacitorDevice THEN, not before), OR lad-5
   workload-profiled sim chips (needs only lad-0 + a profiling hook
   counting MatrixEquationOperation usage in real sim runs).
3. lad-1 export contract / lad-2 SubsystemConfiguration stay
   planned; lad-2 is where ARCHITECTURE_LEVEL_PLAN (parked) revives.

## Gotchas that WILL bite (all hit this arc)

- 🔑 New treeObject classes MUST be in polariServer
  `self.defClassList` (~2750) — the seed-pairs list (~3790) alone
  seeds but does NOT register (classes 404, seeds vanish on reboot).
- 🔑 DisplayDefinition seeds are INSERT-BY-NAME — live page edits
  need the CRUDE PUT backfill (`backfill-cntfet-pages.sh` pattern).
- 🔑 Deploy = image build (ABSOLUTE compose path
  `/home/user/Desktop/polari-suite/.generated/stack-node.yml`; a
  relative path from the wrong cwd silently no-ops) + service
  update; swarm respawns from IMAGE (docker cp is lost). Batch
  rolls; rolls KILL in-flight engine POSTs.
- 🔑 The proxy CUTS long POST responses (~40 min) while the backend
  keeps working — never parse a long call's body without a fallback
  poll (see `advance-cell-first-steps.sh` for the pattern; it lost
  us ~9 h once).
- 🔑 Verify suites from the TALLY LINE in the full log, never a
  tail-piped exit code.
- Selftest fake managers: SimpleNamespace rows; construct classes
  with `manager=None` ("no assigned manager" prints are normal).

## His open gates (unchanged)

- Push ritual `./push-all-dev.sh`; browser passes (level scenes
  Visualize sections, /display/microchip families row);
  CONFIRM_DELETE_LEGACY=yes sweep (28 legacy pages, 5
  cnt-device-3d scenes, 20 orphan shell shapes); plan decisions
  D1–D6 (defaults listed in the plan §4); merge order for
  dev-lad-1 ← dev-fg-1 ← dev when he ratifies.
