# The Electronics app — one app as data over the hardware bench (ea), 2026-10-28

**His asks (2026-10-28):** "the right way to expose things in the isle is to convert them into an app as data"; via Codex: "identify the
EXACT canonical app manifest/name … is this broader electronics/workbench app with uno_core_demo first slice? do not silently
substitute only UNO"; "use the Electronics app you have been developing, distributed across all 3 devices, as the test case for Isle
App/deployment refinement"; "record the plan for the electronics app". Companions: `AI-Notes/guides/ISLE_APP_KINDS_REFERENCE.md`,
`ELECTRONICS_DISTRIBUTION_PLAN.md` (placement), `POLARI_APP_UPDATES_PLAN.md` (how the app's Polari instances update). PLAN ONLY.

## 0. What exists and what is missing
Exists as data: twelve module manifests (`modules/<m>/polari-app.json`) — board, cmod, instruments, hwnocode, electrodevice, hwdigital,
grpcbridge, pcb, firmwarefaults, scoring, hwmap, mathproofs — and the hardware-app `uno_core_demo` (realization bridge, requires board,
cmod, electrodevice, grpcbridge, hwnocode). Six engine workers exist as catalog `mesh-app` tiles with `provides_engine` (board 9830, scope
9880, formal 9840, esp 9850, pcb 9860, bridge 9870). Missing: ONE manifest naming the whole, and a way for a module manifest to say "I need
engine X **as a worker tile**" (today `requires.engines[].kind` ∈ {system, python}).

## 1. The manifest — module `electronics`, `modules/electronics/polari-app.json`
- `app.kind = polari-app`, `agentTier = member`, `category = hardware`, `title = Electronics bench`, `catalogKinds = [polari-app,
  polari-instance]` (installable as a launcher onto an instance that carries it, or as the module set of a new instance).
- `requires.modules` = the twelve + `uno_core_demo` (closure resolved by the registrar; `library` kinds pulled in transitively).
- `requires.engines` = `[{name: board, kind: worker, tile: board-engines}, {scope, worker, scope-engines}, {formal, worker,
  formal-engines}, {esp, worker, esp-engines}, {pcb, worker, pcb-engines}, {bridge, worker, bridge-engines, placement: with-usb-boards}]`
  → **schema addition ea-0**: engine `kind: worker` = a mesh-app tile that `provides_engine` the name, bound through
  `EngineProviderBinding` (knob → binding row → `https://<tile>.isle`); `placement` is a hint the targets door honours (`with-usb-boards`,
  `any-member`, `core-only`).
- `pages` = the bench pages that exist: workbench, bench, pin view, chip ladder, budget, instruments, missions, hardware solutions,
  C-function atom; + the bench views being added: **Registers** (REGISTER_MAPPING_PLAN rm-4, absorbing hardware-chain / register profile /
  memory map / pin profile), **Structs** and **Polari Hardware Bridges** (HARDWARE_SYSTEM_PINS_PLAN §7, hsp-3); `selftests = [electronics_selftest]` (manifest conformance + requires closure + every named tile exists in the
  catalog + every page route registered); `security` block like its modules.
- `uno_core_demo` stays the FIRST SLICE inside it: the acceptance run is its uno-light mission on the twin.

## 2. How it installs (app-as-data lifecycle, nothing hand-wired)
1. **Instances** (D3 ruled: one Polari instance per device): the core's `polari.isle` (catalog/store), pol-core `polari-pol`, econ
   `polari-econ` — `isle polari instance deploy --name <n> --modules <csv>`; the electronics module set goes on `polari-pol`; the
   instance versions follow `POLARI_APP_UPDATES_PLAN.md`.
2. **Workers** (mesh-apps, `isle app scaffold <compose>` → `isle app deploy`): board, scope, formal, esp on econ; pcb on isle-core;
   bridge on pol-core with the USB boards (D4). Each becomes `<tile>.isle` with a core-signed leaf (the member CSR → leaf path, Codex).
3. **Bindings**: `polari-pol`'s `EngineProviderBinding` rows → the six tile URLs; an unreachable worker refuses with words.
4. **Launchers** (polari-app): `pol apps shell electronics` / `isle shell launcher` on the desk device(s); `pol apps shell uno_core_demo`
   builds the Hardware Bridge launcher (Depends avrdude) for the real-board half.
5. **Targets** (the Store's isle-wide question): `GET /api/islemesh/catalog/electronics/targets` lists per device ready / setup-required /
   incompatible with the ONE missing dependency (from the kinds reference §1) — the same payload the devices page shows.

## 3. Slices
| # | Slice | Owner | Proof |
|---|---|---|---|
| ea-0 | ✅ **BUILT 2026-10-29** (framework 207c0c9, `dev-ea-0`): validate() + conform() resolve each worker through `islemesh_catalog.resolve_worker_engines`; registrar piece `workers` (non-structural); hand-set workers survive regeneration; app_forms untouched (worker engines are isle-side, not in ENGINE_MAP); selftest_manifests +16 checks. schema: engine `kind: worker` (+ `tile`, `placement`) in the manifest vocabulary + registrar/app_forms + catalog resolution to `EngineProviderBinding` | Claude (framework) | registrar selftest + a manifest with a worker engine conforms; the catalog resolves it to the tile |
| ea-1 | `modules/electronics/polari-app.json` + `electronics_selftest` (closure, tiles, routes) | Claude | selftest green; `pol modules health` lists it; appears in `/api/islemesh/catalog` as polari-app + polari-instance |
| ea-2 | `/api/islemesh/catalog/electronics/targets` (requirements × device facts) | Claude (iam-0 shares it) | the three devices get the expected verdicts with reasons |
| ea-3 | install across the three devices per `ELECTRONICS_DISTRIBUTION_PLAN.md` ed-1..ed-4 (instances, workers, bindings, launcher) | Codex (verbs/deploy) + Claude (bindings/proof) | `electronics_selftest` + `uno_core_demo_selftest` green on `polari-pol`; the uno-light twin run returns the cycle record (129-cycle worst latency, 177 400 scan bound); instruments capture 62/62 via the remote scope |
| ea-4 | update + uninstall behaviour: the app updates through its instance/worker updates (`POLARI_APP_UPDATES_PLAN.md`); `isle app down` / module unassign / `dpkg -r` remove the pieces without touching the others | Codex + Claude | a round trip from clean → installed → updated → removed, recorded |

## 4. Decisions for him
- **D-ea-1** the name: `electronics` (recommended) vs `electronics_bench` / `hardware_bench`.
- **D-ea-2** does `electronics` also absorb the FET/microchip modules later, or does a separate **Microchip App** (computelod, tensormath,
  mathproofs, cntfet, sifet, fetviews, microchip + the eda/orfs/proof/torch workers) stay its own app? Recommended: separate (his 2026-10-28
  words: "those may be part of a Microchip App").
