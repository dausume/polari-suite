# Electronics work distributed over the three devices — plan (ed), 2026-10-28

**His ask (2026-10-28):** "plan out the electronics work you have been doing being distributed across the 3 devices with types being
distributed according to resources and capabilities and roles of devices. Please coordinate with isle on the plan."
Companion to `AI-Notes/guides/ISLE_APP_KINDS_REFERENCE.md` (the per-kind contract) and `TEST_ISLE_PLAN.md` (ti-2 / ti-3). PLAN ONLY —
nothing deployed by this document. Coordination thread with Codex (isle-core) and Codex (econ-core): task `ISLE-ACCESS-20261028`, CX-027.

## 0. The devices as they are (read 2026-10-28 ~11:30Z, all read-only)

| Device | Role (his, 2026-10-28) | CPU | RAM free | Disk free | KVM | Already holds |
|---|---|---|---|---|---|---|
| **isle-core** (core) | orchestration, network, CA signing, registry/apt (to build), the core Polari `polari.isle` | i5-9400, 6 c | 5 GiB of 7 | **779 GB** | yes (router VM) | engine images from the old swarm era: board 603 MB, esp 1.81 GB, pcb 1.23 GB, formal 594 MB, bridge 506 MB |
| **pol-core** | mesh/Polari hosting on the EXISTING swarm; the desk with the boards on USB (UNO, ESP32-S3) | i5-4590, 4 c | **9 GiB of 15** | **3.5 GB** (97 %) | **NO** | dev swarm node (staging) + forge + four silicon engines (eda 2.56 GB, orfs 4.64 GB, proof 11 GB, torch 1 GB — idle) + board/esp/formal/scope images |
| **econ-core** | container/Swarm hosting + Hardware Bridge SIMULATIONS; no VM for now | N95, 4 c | 5 GiB of 7 | **72 GB** | yes | nothing running (CI/CD parked); old prf staging images |

Resource reading: pol-core has the RAM and no disk; econ has the disk and modest RAM; the core has the disk, the authority and should stay
light. KVM matters only for `hardware-app/kvm` guests — none of the electronics work needs one (all twins are QEMU-TCG/simavr containers).

## 1. The electronics inventory, by isle app kind

**Polari modules (kind polari-app / library, tier member) — the bench itself:** board (engines avr-gcc, avrdude, simavr, esp-idf … as
system tools or via the board worker), cmod (pycparser, avr-gcc, avr-nm, make), instruments (library), hwnocode (make, avr-twin),
electrodevice, hwdigital (verilator, ngspice), grpcbridge (grpcio), pcb (kicad-cli → pcb worker), firmwarefaults (avr-twin, avr-gcc,
avr-objdump, pyvcd), scoring, hwmap, mathproofs (lean), and the app `uno_core_demo` (hardware-app / realization bridge). Pages: workbench,
bench, pin view, chip ladder, budget, instruments, missions, hardware solutions.

**Engine workers (kind mesh-app, `provides_engine`) — compose files in `polari-rf-node/`, image / port / cap:**

| Worker | Engine | Image | Port | mem cap | Needs | Used by |
|---|---|---|---|---|---|---|
| board-engines | board (UNO simavr twin + ESP32-C3 QEMU twin, avr toolchain, cycle harness) | 603 MB | 9830 | 512 MiB | nothing special | board, cmod, hwnocode, firmwarefaults, uno_core_demo, the `smp S5` checks |
| scope-engines | scope (oscilloscope emulator, SCPI) | 178 MB | 9880 | 256 MiB | — | instruments (osc-5) |
| formal-engines | formal (CBMC, Mthread) | 594 MB | 9840 | 1 GiB | CPU bursts | firmwarefaults sc-3, cmod proofs |
| esp-engines | esp (ESP-IDF build + Espressif QEMU S3/C3) | 1.81 GB | 9850 | 2 GiB | CPU bursts, 85–100 s builds | board (C3/S3), ipb-4 harness |
| pcb-engines | pcb (KiCad 9 CLI) | 1.23 GB | 9860 | 1 GiB | — | pcb |
| bridge-engines (`hw-engines` compose) | bridge (board ↔ real device over USB) | = board image | 9870 | 512 MiB | **the USB board on the same host** (compose has no `devices:` yet — gap) | uno_core_demo real half, board flashing |
| eda / orfs / proof / torch / cnt / msci / cad | silicon, FET, proofs, ML, materials, CAD | 2.56 / 4.64 / 11 / 1.0 GB … | 9800/9801/9810/9820/… | 3 / — / 4 / 2 GiB | big disk | the FET/silicon arcs (parked), not the bench |

## 2. Placement (the proposal to coordinate; D1–D4 his)

```
isle-core  = network + CA + registry.isle + apt.isle + polari.isle (store/catalog)      [+ pcb-engines (KiCad, image present)]
pol-core   = local Polari node `polari-pol` with the ELECTRONICS module set + launchers + bridge-engines (USB boards are here)
econ-core  = the SIMULATION workers: board-engines, scope-engines, formal-engines, esp-engines  (sequential, bounded)
```

| Kind | What | Where | Why |
|---|---|---|---|
| polari-instance | `polari-pol` (`isle polari instance deploy --name polari-pol --modules board,cmod,instruments,hwnocode,electrodevice,hwdigital,grpcbridge,pcb,firmwarefaults,scoring,hwmap,mathproofs,uno_core_demo`) | **pol-core** | RAM-richest device; the human and the boards are here; images already local (prf-backend/frontend staging); keeps the core light |
| polari-module | the module set above | into `polari-pol` | one instance, one object tree for the bench |
| polari-app launchers | uno_core_demo, hwnocode, pcb (`pol apps shell` / `isle shell launcher`) | **pol-core** desktop (+ econ's if he sits there) | use, not host; access tier suffices |
| mesh-app | board-engines, scope-engines | **econ-core** first (512 + 256 MiB) | small, always-on twins; econ has the disk; keeps pol's 3.5 GB untouched |
| mesh-app | formal-engines, esp-engines | **econ-core** second (1 + 2 GiB caps; sequential) | bursty CPU builds; 5 GiB RAM allows one burst at a time — never alongside a VM |
| mesh-app | pcb-engines | **isle-core** (image already there) or econ (D2) | 1.23 GB; low duty |
| mesh-app | bridge-engines | **pol-core** (D4) | must sit where the UNO / ESP32-S3 are plugged in; needs a `devices:` + dialout mapping (gap) |
| hardware-app / bridge | uno_core_demo = modules (pol) + twin (econ) + launcher (pol) | split as above | the first vertical slice |
| polari-instance | `polari-econ` (his D3: one instance per device) with the modules econ's workers and bridge sims render through | **econ-core** | one object tree per device; econ renders its own hardware-app rows later |
| hardware-app / kvm | none for the bench; isle-relay / guestnet = isle infra on the core | core | no electronics work needs KVM today; ⚠ `isle vm` not in CLI 0.1.162 |
| silicon / FET / proof / ML workers | eda, orfs, proof, torch (+ cnt, msci, cad when revived) | **isle-core** when needed (779 GB) — today they sit idle on pol-core eating ~19 GB | **D1**: move or retire them off pol-core (compose files + READMEs in the repo; rebuildable) |

Bindings: `polari-pol`'s `EngineProviderBinding` rows → board → `board-engines.isle:9830`, scope → `scope-engines.isle:9880`, formal →
`formal-engines.isle:9840`, esp → `esp-engines.isle:9850`, pcb → `pcb-engines.isle:9860`, bridge → local `bridge-engines` on pol-core.
A declared-but-unreachable worker refuses with words (the seam already does this).

## 3. Phases (each row = a slice; owner in brackets; nothing runs without his go)

| # | Slice | Owner | Gate / proof |
|---|---|---|---|
| ed-0 | prerequisites: econ join (his sudo); `registry.isle` or blessed local images; member CSR → core-signed leaf; **D1** pol disk | Codex (core/CLI) + Dustin | econ agent healthy; a leaf for a member name; ≥ 10 GB free on pol-core |
| ed-1 | `polari-pol` on pol-core with the electronics module set; leafs for `polari-pol.isle` + `api.polari-pol.isle`; DNS via the reconciler | Codex verb, Claude module list + data | `uno_core_demo_selftest` + bench/workbench/instruments selftests green on that instance; https by name from econ and the core |
| ed-2 | board-engines + scope-engines on econ as mesh-apps (`isle app scaffold` from the two compose files); bindings in polari-pol | Codex deploy, Claude bindings + proof | `board-engines.isle:9830/health`; `selftest_light_samples/variants` + the four `smp S5` checks pass against the remote C3 twin; instruments capture 62/62 via the remote scope |
| ed-3 | formal-engines + esp-engines on econ (sequential); pcb-engines on the core (D2); bindings | Codex + Claude | sc-3 CBMC run; one C3 build (≈ 100 s) through the remote worker; pcb-0 ERC/DRC through the core worker |
| ed-4 | bridge-engines on pol-core with USB (`devices:`, dialout), `pol apps shell uno_core_demo` launcher; real-UNO flash | Claude compose + launcher data, Codex packaging | the UNO light mission flashed and read back on the real board from the pol-core page |
| ed-5 | Store eligibility door `/api/islemesh/catalog/<name>/targets` showing exactly this matrix (ready / setup-required / incompatible per device, with the one missing dependency named) | Claude backend, Codex store UX | the Store on any device answers "where can board-engines run?" = econ ready, pol setup-required (disk), core by choice |
| ed-6 | the owed Chrome passes (workbench, bench, pin view, chip ladder, budget, instruments, missions) — now through `polari-pol.isle` | Claude | each page seen in Chrome from pol-core and once from econ |

## 4. Decisions — RULED by him 2026-10-28 (his words: "are we using the silicon engines actively in the design work? I think one polari instance on every device. Disable if they are not actively used in the electronics layer and only used for simulating physics for creating new transistors. Those may be part of a Microchip App? Bridge on Polari along with Boards is probably fine, but we should move workhorses and engines to econ or isle then depending on resources")
- ✅ **D1 RULED — disable.** Facts: eda-engines + orfs-engines serve `computelod` (chip compute LOD, TABLED arc), proof-engines serves `mathproofs` (lean), torch-engines serves `tensormath`; none is in the electronics layer (firmware proofs use formal-engines' CBMC; hwdigital's ngspice/verilator are system tools). Containers untouched since 2026-10-11, zero requests in 7 days. DONE 2026-10-28 ~12:20Z on pol-core: the four compose projects brought down (containers removed, `restart` gone); images KEPT until his word (they are the 19 GB). They belong to a future **Microchip App** (app as data composing computelod, tensormath, mathproofs, cntfet, sifet, fetviews, microchip) hosted on isle-core or econ by resources when that arc resumes.
- **D2** pcb-engines: isle-core (image present) — stands as recommended; final placement of all workhorses = econ or isle "depending on resources" (his).
- ✅ **D3 RULED — one Polari instance on EVERY device:** core `polari.isle` (exists), pol `polari-pol`, econ `polari-econ`. Each hosts the modules its role needs; the electronics module set lives on pol (the bench), econ's instance carries what its workers/bridge sims render, the core's stays the catalog/store core.
- ✅ **D4 RULED — bridge + boards stay on pol-core.** Workhorses and engines move to econ or isle by resources (board/scope/formal/esp → econ; pcb → isle; the Microchip App workers → isle when revived).
