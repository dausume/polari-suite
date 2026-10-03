# Hardware as no-code (hn arc): ONE no-code model across frontend, backend and hardware. A graph can span a sensor atom on a board, the bridge, a backend node and a configured display. Polari suggests bare C, FreeRTOS or Zephyr, with evidence.

**Date:** 2026-10-03 · **Status: PLAN. Nothing built. D-hn-1..6 are his.** Drafted by an opus agent from the tree at
suite `origin/dev` (7b3f5bd), with framework `dev-hw-integration` a9885f8 and angular 1deb1da (the merged
brd/sc/cmod stack). Fable reviews it. Code paths are under `polari-rf-node/polari-framework/` unless they say
otherwise; Angular paths are under `polari-rf-node/polari-platform-angular/`. Facts marked **unverified** were not
confirmed from a primary source or a measurement on 2026-10-03.
Companions: `C_MODULARIZATION_PLAN.md` (atoms, CGraph, `cmod-glue`; this plan continues cmod-2/3/4),
`BOARD_PROGRAMMING_PLAN.md` (boards, variants, installer, wire), `FIRMWARE_SCENARIO_PLAN.md` (pairs, techniques, costs),
`GRPC_BRIDGE_PLAN.md` (Commands loop, grpc-j4), `HARDWARE_SIMULATION_PLAN.md` (hwsim-nocode),
`NOCODE_GENERALIZATION_PLAN.md` (the compiler seam), `AI-Notes/designs/HARDWARE_CAPABILITY_REGISTER.md`.

## 0. The ask and the principle

**His words (2026-10-03):** *"incorporate the capability for hardware to be done as no-code, this is going to be core
functionality but we will want to re-use capabilities if at all possible. We want this to be interwoven with the work
we have done so far. And we can make suggestions based on overall no-code whether a user should leverage straight C,
FreeRTOS, or Zephyr. We should also plan out what different variants of hardware we might make. Like standalone
hardware/firmware, firmware made to communicate with polari, etc. Try to come up with different scenarios and
reference how we already do frontend and backend no code."* + *"check what work we have already done and planned
around this too."*

**The principle: ONE no-code model.** Frontend, backend and hardware share the same canvas, the same compiler seam,
the same propose → execute path and the same configured displays. Hardware adds node KINDS, not a second system:

| hardware node kind | what it is | rows it stands on (exist) | compiled / run by |
|---|---|---|---|
| `c-atom` (+ the glue kinds `class` `parser` `frame` `tick` `rule`) | a C function of a normal C project, with ports | `cmod` `CFunctionAtom`/`CPort`, `CGraphNode` (`modules/cmod/objects/cmod/`) | `cmod-glue` → a real C project (`modules/cmod/custom/glue.py:501`) |
| `hw-interface` | one Polari object row ↔ one board instance/port/index; the device⇄backend SPLIT POINT | `grpcbridge` `HardwareInterfaceBinding`, `WireContract`, `EnumMapping` (`modules/grpcbridge/objects/mapping/`) | the Java bridge + `c_twin` headers (brd-wire) |
| `register` | one FPGA register: a knob the MCU or Polari writes and logic obeys | `hwfpga` `RegisterMapDefinition`/`RegisterDefinition` | `hwfpga/custom/fpga_verilog.py` → AXI4-Lite Verilog + `<map>_regs.h` |
| `logic-block` | gate / flop / counter / mux on a logic diagram | `hwdigital` `LogicBlockNode`/`LogicBlockDesign` | `hwdigital-logic` compiler → Verilog + a self-checking bench |

**What "interwoven" means concretely:** one `HardwareSolution` (§2c) can hold all of these:
- a `c-atom` that reads the TMP36 on the UNO;
- the `hw-interface` `SimRigState@uno-pair/0`;
- a backend solution that fires on the row change (`BackendStateChange`) and writes `led_on` back
  (`StateChangeCommit` → the Commands stream: "send the object and it acts", `GRPC_BRIDGE_PLAN.md:315-332`);
- a configured `sci-xy-chart` tab on the object.

Its **run** is the twin (simavr / QEMU / Renode) or the board. Its **test** is the scenario pairs + formal checks
(`firmwarefaults`). Its **deploy** is the Firmware Installer (`modules/board/custom/installer.py`: plan → confirm →
run) plus the advisory pipeline stage (`polari-jenkins/scenarios.sh`, sc-4).

## 1. How no-code works today

### 1a. What we already did and planned (survey: plans, shelved, designs, handoffs, memory)

| item | where | status | his ruling (quoted) | this plan |
|---|---|---|---|---|
| Solution engine + TS mirror, `/createClass`, SolutionInvocation | `polariNoCode/SolutionExecutionEngine.py`; memory `no-code-foundations` | built | "THE CONFIGURATION IS THE ARTIFACT"; P5 = true TS engine mirror | **reuse**: backend + browser nodes run here |
| Compiler seam `GraphCompilerDefinition` (ncg-1..7: judicial, logic, circuit, breadboard, magnetic) | `polariNoCode/graph_compilers.py:36-186`; `NOCODE_GENERALIZATION_PLAN.md` | built 2026-07-16 | "circuit/FPGA/MCU no-code by REUSING + GENERALIZING the existing no-code engine" | **reuse**: every hardware compiler is a row here |
| hwdigital logic blocks → Verilog → iCE40 (ncg-3) | `modules/hwdigital/`; `NOCODE_GENERALIZATION_PLAN.md:239-268` | built | "iCE40 is the synthesis target" | **reuse** as the `logic-block` kind |
| level_bridge: design bit ↔ breadboard vsource (ncg-6) | `modules/electrodevice/level_bridge_basis.py` | built | — | **reuse** for the logic ↔ circuit edge |
| Register map as data (hwsim-3/led) | `modules/hwfpga/custom/fpga_verilog.py` | built + live in sim | "send the object and it lights up" | **reuse** as the `register` kind; ADD its compiler row (§1d) |
| **hwsim-nocode** `FieldRegisterBinding` → generated firmware routing → `/createClass` | `HARDWARE_SIMULATION_PLAN.md:211-234` | planned 2026-07-10, never built | — | **continue, partly superseded**: cmod made a binding an EDGE (class field → atom port) (`C_MODULARIZATION_PLAN.md` §1). Field↔register becomes the edge `field-register` (§2a). Its end-to-end chain (§3 of that phase) is our hn-0 proof. No `FieldRegisterBinding` class. |
| grpc-j2 Commands loop, grpc-j1 bridge generator ("THE no-code capability") | `GRPC_BRIDGE_PLAN.md:315-334` | built + live | "send an object instance to hardware and it acts" | **reuse**: the device→backend→device round trip |
| grpc-4 `HardwareSignalDefinition` (deadband, `nanopb_lint`) | `GRPC_BRIDGE_PLAN.md:254-275` | planned | — | **continue**: deadband becomes a field-edge param (cmod-1 owed it); the embeddability lint becomes a suggestion |
| grpc-j4 / brd-wire mapping, instance index, EnumMapping | `GRPC_BRIDGE_PLAN.md:417-509`; `modules/grpcbridge/custom/wire_contract.py` | built 2026-10-02 | "use objects at the polari level and still ensure they correspond to a very specific hardware interface" | **reuse** as the `hw-interface` kind; the fleet variant (§4 i) continues its "20+" design |
| cmod-0/1: atoms, CGraph, `cmod-glue`, byte-identical .hex | `modules/cmod/`; `C_MODULARIZATION_PLAN.md` | built 2026-10-02 (dev-hw-integration) | "modularization of C code into polari is likely going to be a critical part of functionality" | **reuse**: the device subgraph. cmod-2 (cffi), cmod-3 (canvas overlay) and cmod-4 (second board) are slices here. |
| brd-0/1/fi/wire: BoardDefinition, FirmwareVariant, installer, twins | `modules/board/`; `BOARD_PROGRAMMING_PLAN.md` | built (UNO on the twin; C3 via sc-3) | RULE 1 USB/USB-C (adapters allowed); RULE 2 "C, Verilog or SystemVerilog ONLY" | **reuse**: run/deploy. Variants are today's hand-written graphs. |
| brd-2 Fire (bridge as a systemd unit) | `BOARD_PROGRAMMING_PLAN.md` §4 | planned | D-brd-3 "decide based on circumstances" | **continue** as the Polari-hosted variant (hn-3) |
| sc-0..4: scenario pairs, campaigns, CBMC/Mthread, pipeline stage | `modules/firmwarefaults/`; `FIRMWARE_SCENARIO_PLAN.md` | built (sc-3 C3 pairs measured) | fault kinds are "FirmwareFault OBJECTS"; open tools pulled in as engines | **reuse** as the suggestion engine's EVIDENCE |
| Capability register (33 devices, classes S/M/L/XL, tiers proven) | `AI-Notes/designs/HARDWARE_CAPABILITY_REGISTER.md` | written 2026-10-01 | "track all, simulate FEW" | **reuse**: board-pick input |
| Hardware architecture (MCU decides, FPGA times, interlocks override) | memory `polari-hardware-architecture` | design direction | "MCU makes decisions. FPGA enforces timing. Hardware interlocks override both." | **reuse**: the actuator/FPGA-companion variants obey it |
| MatrixEquationOperation node (overlay template) | memory `matrix-equation-operation-node` | built | — | **reuse**: the template for a new overlay |
| Printing suite / voron / hwmap | memory `printing-suite-and-hardware-map` | built (dev) | D6–D8 his ✓ | **reuse**: hwmap scanner = detection; voron = a Klipper host, not our firmware |
| BLCNC / PVD (LaserOperation node, safety MCU) | `AI-Notes/plans/shelved/BLCNC_PLAN.md`, `BLCNC_PVD_ROADMAP.md` | **shelved** ~2026-07-18 | revival needs "Dustin go-ahead" | **not revived**; its safety rule is reused in §4 e |
| Tech tree segments theory/real/business/politics | memory `tech-tree-and-blcnc-planning` | planning | baton not picked up | variants can become TechNodes later; not in scope |
| Motors / gears graphs (equations as rows) | memories `motor-goals`, `gears-module` | built | — | input to actuator sizing; no change |
| Standard Polari App (`polari-app.json`, `app.kind`) | `AI-Notes/designs/STANDARD_POLARI_APP.md` | sap-1..2c built | tiers access/host/hardware (2026-09-14) | **reuse**: a HardwareSolution exports as a module with `requires.engines` |
| Hardware Apps = KVM guests (`HardwareAppDefinition`) | `modules/hardwareapps/`; `HARDWARE_APPS_PLAN.md` | hw-app-1 built; rest plan | "start with … guest network KVM app and the relay KVM" | **a different sense of "hardware app"**: listed, out of scope. The name `HardwareApp` stays theirs. |
| Dynamic modules (live admit) | memory `dynamic-modules` | built | — | **reuse**: the Fire admits modules one at a time |

### 1b. Backend no-code today

- **Rows:**
  - A solution is ONE `SolutionDefinition` row (`polariApiServer/solutionDefinition.py:3-31`). It holds `definition`,
    a JSON blob `{solutionName, stateInstances:[…]}`.
  - Each state has a `stateClass` and slots. Branch order = slot order (`polariNoCode/graph_builder.py:14-43`).
- **Node kinds** are the dispatch arms of `SolutionExecutionEngine._execute_ungated`
  (`polariNoCode/SolutionExecutionEngine.py:744`, arms 1248-2785: e.g. `AwaitBackendCall` 1567,
  `MatrixEquationOperation` 1852, `AnalysisCall` 2558). The entry kinds include `BackendStateChange`
  (`INITIAL_STATE_CLASSES`, :54).
- **Python enters as a row naming a callable:** `AnalysisDefinition.callable_ref` (`polariNoCode/analysis_calls.py:25`).
- **Events:** `EventTrigger`/`TriggerFiring` rows (`polariNoCode/event_triggers.py:30,77`), fired by
  `polariNoCode/event_dispatcher.py`. Every firing is one complete execution: the engine has no pause/resume, so paced
  flows use `advance()` (`graph_compilers.py:200`).
- **Compilers:**
  - `GraphCompilerDefinition` rows: `name`, `domain`, `compiler_ref`, `enabled` = the knob.
  - `compile_with` stamps provenance and accepts ARTIFACT-ONLY output (`graph_compilers.py:164-186`).
  - `cmod-glue` is registered at `graph_compilers.py:127-137` as "artifacts only — a C graph never runs in the
    engine (RULE 2)".
- **Ports:** the engine's ports are untyped (duck-typed `ValueSource` dicts, `graph_builder.py:172-191`). Only cmod
  has typed ports: `CPort.polari_type` ∈ int64 | double | bool | string | bytes | ref:<T>, plus `ctype` and
  `width_bytes`.
- **The MCP path:**
  - `polari-mcp/ai_conventions.json` ("propose -> review -> confirm -> execute -> observe", the authority ladder,
    level 3 = "add a connector").
  - `polari-mcp/authority.py:84-133` (`AuthorityKernel`, `logs/provenance.jsonl`).
  - `polari_propose_connector` / `polari_propose_bind_event` live in `polari-mcp/polari_mcp.py`.

### 1c. Frontend no-code today

- **Displays are rows:**
  - `DisplayDefinition` (`polariApiServer/displayDefinition.py:3-13`: `source_class`, `definition`, `isPage`,
    `pageRoute`) is seeded by `*_page.py` through `polariApiServer/module_pages_seed.py` (`_table` 26-46, `_sapi` 64-81,
    `_page` 93-102). Example: `modules/cmod/cmod_page.py:13-62`, nine configured tables and no new component.
  - Angular renders them with `src/app/components/dashboard/dashboard-renderer/dashboard-renderer.ts`, via
    `DISPLAY_COMPONENT_REGISTRY` (`src/app/models/dashboards/ComponentRegistry.ts`). The registered components include
    `class-rows-table`, `api-structured-panel`, `sci-xy-chart` (`src/app/components/charts/sci-xy-chart.component.ts`,
    THE chart home) and `tensor-tree-panel`.
- **Per-object tabs:** `display-manager.service.ts:56-70` `fetchDisplaysForClass(source_class)`. Every display row for a
  class is a tab on that object's page (memory `per-object-display-config`).
- **The canvas:**
  - `src/app/components/custom-no-code/custom-no-code.ts`, D3 states under `editor/no-code-interface/`.
  - One overlay per `stateClass`, dispatched by `if/else` (`custom-no-code.ts:881-914`, e.g.
    `MatrixEquationOperation` :900).
  - **The palette is a static TS registry**: `states/_shared/state-space-class-registry.ts`, read at
    `custom-no-code.ts:4392`.
  - The backend's live endpoint `GET /stateSpaceClasses` (`polariApiServer/stateSpaceAPI.py:31-59`, every class with
    `isStateSpaceObject`) is wired into `state-definition.service.ts:391-412`, but the palette does not use it.

### 1d. Reuse vs add

| REUSED as is | ADDED (hn) |
|---|---|
| The canvas + overlays dispatch; D3 layers | the palette fed from `GET /stateSpaceClasses` (the existing endpoint), so hardware kinds arrive as data; 3 overlays: `c-atom` (= cmod-3), `hw-interface`, `register` (`logic-block` reuses the ncg-3 editor) |
| `SolutionDefinition` + engine + TS mirror for backend/browser nodes | node kinds `HardwareSubgraph` (a state that REFERENCES a CGraph / LogicBlockDesign / RegisterMap, like `SolutionInvocation`) and `hw-interface` |
| cmod rows + checker + `cmod-glue` (AVR, bare C) | the cmod edge kinds `field-cmd` (a presence-gated command field → atom port, owed by cmod-1), `field-register`, `deadband` param; node kinds `task`, `queue`, `mutex` for an RTOS glue target; glue targets `esp-idf` and `zephyr` |
| `GraphCompilerDefinition` (`hwdigital-logic`, `cmod-glue`) | compiler row `hwfpga-regblock` (fpga_verilog exists; no row yet) and `hn-split`, which partitions a HardwareSolution and calls the others |
| DisplayDefinition / `sci-xy-chart` / per-object tabs | display seeds for the new rows (configured tables only, no new component) |
| WireContract / HardwareInterfaceBinding / EnumMapping / c_twin | the type map as a checked table (§2a), applied at the split |
| Installer, twins, FirmwareVariant/Build, BoardSimCost | `HardwareSolution`, `RuntimeSuggestion`, `HardwareSuggestion` rows (module `hwnocode`, §2c) |
| Scenario pairs, campaigns, FormalCheck, COST.md numbers | the feature extractor + the rule table that cites them (§3) |
| MCP propose → execute | `polari_propose_hardware_solution` (a dry run = the split + the suggestion, no build) |

## 2. The hardware no-code model

### 2a. Ports and types: C ↔ Polari ↔ wire

| C (`CPort.ctype`) | Polari (`polari_type`) | wire (`WireContract` / c_twin) | rule |
|---|---|---|---|
| `uint8_t … int32_t`, `uint32_t` | int64 | fixed width per `field_order_json` | narrowing across the split = a refusal naming the field (cmod's type check, `cmod/custom/graph.py:226`) |
| `float` / `double` | double | binary64. On AVR, `double` is 4 B → c_twin AVR mode float32↔binary64 (`BOARD_PROGRAMMING_PLAN.md` §1) | the precision loss is stated on the edge |
| `bool` | bool | one presence-masked bit field | — |
| `char[64]` | string | `C_STR_MAX` 64 B, or ONE byte when an `EnumMapping` exists (labels[i] ↔ i+1, 0 = unknown) | a string state field with no EnumMapping crossing to an S-class board → suggestion "map it" |
| `const polari_rx_t *` | ref:polari_rx_t | the parser's frame | only `on-command` edges |
| (none) | the object's identity | stripped by the bridge and re-attached from `HardwareInterfaceBinding`; the index is `ceil(log2 n)` bits (`WireContract.index_repr` none / bits / byte / u16, knob `packed_max_bits`) | never rides in the struct |
| every field | presence | one mask bit per field (wire v2) | a command field without presence cannot be `field-cmd` |

### 2b. Where a node runs, and RULE 2 as the placement rule

Placements: `board` (the MCU / FPGA fabric), `twin` (same artifact, simulated: simavr, QEMU esp32c3, Renode),
`engine-host` (cmod-2's cffi worker, unbuilt), `backend` (the Python engine), `browser` (TS engine + displays),
`linux-device` (a Linux SoC running Polari itself, §4 c).

The placement is DERIVED, never typed in:
1. `c-atom` / glue kinds / `register` / `logic-block` → `board` (and `twin` when no BoardInstance is attached).
2. Engine state classes → `backend`. Displays → `browser`.
3. **Every edge that crosses board ⇄ backend must pass through one `hw-interface` node.** The bridge is the split
   point. Any other crossing is refused, naming the edge.
4. **A Python node placed on a `board` is refused with the reason** (RULE 2; `C_MODULARIZATION_PLAN.md` §7: "rewrite it
   in C (a person's job)"). The refusal offers the alternative "move it to the backend across the hw-interface" as a
   `HardwareSuggestion` (§5).
5. On a `linux-device`, Python nodes are allowed (a host-side layer, `language-layering`), but **D-hn-6**.

### 2c. Rows: SolutionDefinition vs CGraph (the trade-off behind D-hn-1)

cmod-1 already chose its own rows, for a measured reason (`C_MODULARIZATION_PLAN.md` §10 cmod-1):
- `SolutionDefinition` is ONE blob executed by the Python engine. A C graph never runs there, and a blob cannot be
  configured tables.
- `LogicBlockNode` is single-output and positional.

| option | for | against |
|---|---|---|
| **referenced subgraph (recommend)** | zero migration; cmod's checker, refusals, sha and byte-identical proof stay; the solution blob keeps its TS parity vectors; `HardwareSubgraph` behaves like `SolutionInvocation` | two row shapes for "a graph"; the canvas reads both |
| unify (move solutions to per-node rows) | one shape; every graph is configurable as tables | rewrites the engine loader, the TS mirror, `parity_vectors/` and every seeded solution; nothing hardware-specific gained |

A new row ties it together. **`HardwareSolution`** (module `hwnocode`): `solution` (a SolutionDefinition, optional),
`cgraphs`, `logic_designs`, `register_maps`, `interfaces` (HardwareInterfaceBinding names), `displays`,
`variant_kind` (§4), `board_definition`, **`firmware_runtime`** (KNOB: `auto` | `bare-c` | `freertos` | `esp-idf` |
`zephyr`), `split_sha256`, `status`. `CGraph` gains `firmware_runtime` too (the glue target). It defaults to
`bare-c`, so today's graphs are unchanged.

## 3. The suggestion engine: bare C / FreeRTOS / Zephyr

The rule (memory `knobs-and-suggestions`): the knob is `firmware_runtime`; the suggestion is a **`RuntimeSuggestion`**
row (`hardware_solution`, `suggested`, `alternatives_json`, `reasons` in plain words, `evidence` = row names,
`features_json`, `knob_at_time`, `accepted_by`, `at`); and **the engine never chooses silently**. There are two
precedents in the tree:
- cmod's `_advice` ("suggestions, never refusals", `cmod/custom/graph.py:409`);
- `WireContract.suggested_index_width` + `notes`.

Note: **ESP-IDF IS FreeRTOS** (ESP-IDF ships a FreeRTOS kernel; the sc-3 pairs ran on it). `esp-idf` is a separate
value only because its toolchain and image differ.

**Features extracted from the graph (all derivable from rows today, except where marked ADD):**

| feature | derived from | why it matters |
|---|---|---|
| concurrent activities | distinct scopes in cmod's model: ticks of different periods, the `on-rx` drain, `on-command` (`graph.py` scopes) | 1 loop + ISRs fits bare C; several independent periods with blocking calls point to tasks |
| blocking atoms | **ADD** a cmod verdict `blocking` (a busy-wait on a register flag, e.g. `hal_adc_read` "one blocking ADC conversion") | a blocking atom inside a fast tick = a missed deadline (`MissedDeadlineFault`) |
| request/ack, timeouts | a command path that waits on a reply | S2 `lost-ack-hang`: hang 47.5 % / 15.0 % / 2.5 % at p = 0.5 / 0.2 / 0.1, and 0 with a timeout. **Fixed in bare C** (`firmwarefaults/COST.md`), so a timeout alone does NOT force an RTOS. |
| shared resource across priorities | two tasks touching one resource (cmod resources: the same global or peripheral) | the priority-inversion pair applies. C3: binary semaphore H waited **12 160 µs** vs **2 098 µs** with a mutex (inheritance), **−38 B** flash (`firmwarefaults/COST.md` sc-3). That is FreeRTOS-only evidence. |
| two locks | two mutex nodes taken in both orders | the deadlock pair: cycle closed at tick 370; ordering −40 B; back-off +18 B, ≈ +8 ms/round |
| ISR-only timing paths | ISR atoms + `tick` with no blocking atom | bare C is deterministic: the torn-read fix costs **+6 B, +3 cycles** (sc-0) |
| radios | the board's `radios` column (register) + a radio atom | Wi-Fi/BLE on ESP32 → esp-idf; BLE/802.15.4 on nRF52840 → zephyr (open BLE stack); LoRa → the RNode route (**D-hn-6**) |
| memory class | `BoardDefinition.ram_kb` + the register's class | S (UNO 2 KB, CH32V203 20 KB, Longan 32 KB) → bare C. M (C3 400 KB, nRF52840 256 KB) → FreeRTOS/ESP-IDF. L (Pico 2 520 KB; Hazard3 = "Zephyr pick") → Zephyr viable. |
| cost floor | measured | UNO sim-rig **4 338 B flash / 491 B RAM** (wire v2) vs C3 ESP-IDF sim-rig **app 156 768 B, DRAM 87 796 B** (`board/COST.md`). Images: `prf-board-engines` 534.8 MB vs `prf-esp-engines` **1 813 MB**. An IDF build takes 57 s / 178 CPU-s / 193 MB RSS. Zephyr: **unmeasured**. |

**Rule table (ordered; the first decisive row wins; every row lists its evidence):**

| # | condition | suggests | evidence attached |
|---|---|---|---|
| 1 | the board is S class | bare-c (an RTOS is refused if picked, the reason being RAM) | board row, cmod cost estimate |
| 2 | a radio stack is needed | esp-idf (Espressif) / zephyr (nRF, STM32G4) | register `radios`, `tiers proven` |
| 3 | ≥ 2 activities AND (a blocking atom OR shared resource across priorities) | freertos / esp-idf (zephyr on L-class boards) | priority-inversion pair + deadlock pair rows, which are then **recommended to run** (§5) |
| 4 | only ISR + one loop, timeouts by state machine | bare-c | S2 pair (fixed in bare C), sc-0 cost pair |
| 5 | otherwise | bare-c, with the margin stated | cmod cost vs `flash_kb` |

`auto` = the suggestion is shown, and **D-hn-3** decides whether it is pre-selected. A person's explicit pick always
wins and is recorded as `accepted_by`. When a person's pick contradicts the suggestion, the row stays with
`overridden = true`.

## 4. Variants of hardware we might make

| v | variant | who talks to whom | nodes | runtime tends to | reference device (register) | covered by | gap |
|---|---|---|---|---|---|---|---|
| a | **standalone firmware** | board alone. Polari only at setup (config over USB once) | c-atom, tick, rule (no frame) | bare C | UNO R3 | cmod-glue, installer | glue requires a class header (`glue.py:91-93`) → ADD a no-class / config-only mode; config to EEPROM |
| b | **Polari-attached peripheral** | board ⇄ bridge ⇄ object rows | c-atom, class/parser/frame, hw-interface | bare C | UNO (sim-rig) | **exists**: brd-1/fi/wire + cmod-1 | the canvas (cmod-3) |
| c | **Polari-hosted device** | a Linux SoC runs a Polari node + bridge + the fabric | engine nodes on `linux-device`, register, logic-block | Linux | BeagleV-Fire | brd-2 planned; Renode `beaglev-fire` twin | brd-2, the framework's RSS on riscv64 (**unverified**) |
| d | sensor node | sensors → frames up (deadband) | c-atom, field (deadband), frame | bare C (S) / FreeRTOS when radio | UNO; C3 | sim-rig ADC path | `deadband` edge param |
| e | actuator / controller | Commands down → PWM/steppers/heaters. Safety MCU + FPGA timing + hardware interlock | field-cmd, register, logic-block | FreeRTOS (M) + FPGA | SAMD21/51 + iCE40 (tiers) | hwfpga regblock, hwdigital, sc watchdog pair | the interlock is HARDWARE: no node may be the only safety path (refusal) |
| f | gateway / radio node | Reticulum over LoRa / HaLow / BLE ⇄ Polari | radio atoms, hw-interface | esp-idf / zephyr | LilyGO T-Beam, RAK nRF52840, NRC7292 | `reticulum` module (pinned rns 0.9.4) | RNode firmware language (**D-hn-6**); `tx_permitted()` before any TX |
| g | FPGA companion | MCU ⇄ AXI4-Lite regblock ⇄ pins | register, logic-block, c-atom | bare C | iCE40 + SAMD21; Renode co-sim | hwsim-3/led, ncg-3 | the `field-register` edge + `hwfpga-regblock` compiler row |
| h | **split app** (the interwoven case) | board → bridge → backend solution → display, and back | all of the above + engine nodes | per board | UNO twin + a display | the parts exist | `HardwareSubgraph`, `hn-split`, the canvas |
| i | fleet of identical boards | N boards, one build, one bridge | same as b | same as b | N UNOs | WireContract index (bits/byte/u16) | ONE build with the index written at install (EEPROM byte) or a boot hello (`GRPC_BRIDGE_PLAN.md:470-480`, designed, unbuilt) |
| j | battery / solar node | MPPT + BMS rows up, sleep cycles | c-atom, tick (low power), frame | Zephyr | STM32G4 Libre Solar | none | Zephyr glue target; BMS rows (register §4 "advised") |

**Scenario walk-throughs.** **F** = a frontend no-code step (canvas, display row). **B** = a backend no-code step
(solution, trigger). **H** = a hardware step (graph, build, twin, install).

**(a) Standalone thermostat on the UNO**
1. H: on the canvas, drag `hal_adc_read` → `sensor_value` → a `rule` (on above X) → `hal_led_set`, with a `tick` of 100 ms.
2. H: the suggestion says bare-c (S class, rule 1/4).
3. H: `hn-split` sees no hw-interface → variant a; `cmod-glue` renders the project; `make` builds it.
4. H: the twin runs the ADC triangle (`FirmwareVariant.twin_stimulus_json`) and the LED toggles.
5. H: the installer plan → confirm → flash. The threshold goes to EEPROM over USB once, then the board runs with no Polari.

**(b) Attached peripheral: today's `uno-sim-rig-graph`**
1. H: open the seeded CGraph on the canvas (cmod-3). 2. F: add a per-object `sci-xy-chart` tab on `SimRigState`.
3. H: the installer flashes the twin or the board; the bridge binds `SimRigState@uno-pair/0`. 4. F: the row moves live (STOMP).

**(c) Polari-hosted on the Fire**
1. H: `pol board deploy fire` (brd-2) installs a lean Polari node.
2. B: dynamic modules admit `hwfpga`.
3. H: a `register` node writes the LED map and the fabric obeys (brd-2b).
4. B: the solution runs ON the Fire, next to the hardware.
5. F: the home core shows the Fire's rows through federation.

**(d) Sensor node**
1. H: the field edge `temp_c` gets `deadband=0.5`. 2. H: the cost estimate shows the bytes added.
3. H: a campaign (sc-2) on the twin measures the frames saved per minute. 4. F: the chart shows the gaps.

**(e) Heater controller**
1. H: `field-cmd pwm_duty` → `hal_pwm_set`, with a watchdog atom and an over-temp `rule`.
2. H: the suggestion recommends the watchdog pair (`runaway-hang-watchdog`).
3. H: the checker refuses the solution unless its safety path names a hardware interlock row (the architecture rule).
4. B: the backend sets the setpoints via `StateChangeCommit`.

**(f) LoRa gateway**
1. H: pick a T-Beam (the board suggestion: radio + cost).
2. H: the runtime is esp-idf.
3. B: the reticulum module rows bind to the radio's hw-interface.
4. H: every TX path calls `tx_permitted()`.
5. H: the twin covers the host half only (no LoRa twin exists).

**(g) FPGA companion**
1. H: add `register` rows (a `pins_out` knob) and a `logic-block` counter.
2. H: add the edge `field-register LedMatrix4x4State.pattern → REG_LED`.
3. H: `hwfpga-regblock` + `hwdigital-logic` build the Verilog and its self-checking bench.
4. H: Renode + Verilator co-sim.
5. F: the LED grid shows on the object tab.

**(h) Split app on the UNO**
1. H: the sim-rig subgraph.
2. B: a `BackendStateChange` on `temp_c > 30` → `StateChangeCommit led_on=true`.
3. F: a chart tab.
4. H: `hn-split` partitions the solution: board = cmod-glue, backend = the solution blob, browser = the display.
5. H: on the twin, ADC up → frame up → solution → command down → the LED frame comes back. A scenario pair (S2) runs
   on the request path.

**(i) Fleet of three UNOs**
1. H: one build. 2. H: the installer writes the index byte (`-U eeprom:w:`). 3. H: `assign_indexes` gives 2 bits.
4. H: three twins, `refused_frames = 0`, then a swapped cable is refused.

**(j) Solar node**
1. H: pick the STM32G4 (Libre Solar). 2. H: the runtime is zephyr (rule 2: the target's own firmware is Zephyr).
3. H: BMS rows come up. 4. H: no twin yet, so the slice waits for hardware or a Renode G4 platform (**unverified**).

## 5. Suggestions beyond the runtime (`HardwareSuggestion` rows: `kind`, `subject`, `suggested`, `reasons`, `evidence`)

| kind | input | output + evidence |
|---|---|---|
| `board` | the RAM/flash need (cmod cost estimate), radios, runtime, USB rule, the register's `status` (HIS PICK first), twin availability | ranked BoardDefinition rows, citing the register row + `BoardSimCost` |
| `scenario` | the graph's primitives (ISR-shared global, ring, ack path, two locks, shared resource across priorities, EEPROM record) | the matching `Scenario` rows to run (torn read, S2–S5, inversion, deadlock), each with its measured pair |
| `technique` | the same primitives | `Technique` rows with their measured cost: atomic +6 B / +3 cycles; mutex −38 B; ordering −40 B; back-off +18 B; watchdog; keep-tail parser |
| `formal` | an ISR-shared global or a ring in the subgraph | a CBMC/Mthread `FormalCheck`: Mthread decides the ring unbounded in 0.45 s vs CBMC 107.7 s (`firmwarefaults/COST.md`) |
| `placement` | flash/RAM over the board's limit, or a Python node on a device | "move node X to the backend across the hw-interface" with the bytes saved; or "a bigger board" (`board`) |
| `wire` | a string field with no EnumMapping, an index width over `packed_max_bits`, a non-embeddable contract (grpc-4 lint) | the EnumMapping / index_repr / field change, citing the WireContract |

## 6. Decisions (his; recommendations in bold)

- **D-hn-1 rows:** unify cmod's graph rows with `SolutionDefinition`, or keep them as a referenced subgraph?
  → **Referenced subgraph** (§2c): a `HardwareSubgraph` state + a `HardwareSolution` row. No migration, and the
  byte-identical proof chain stays intact.
- **D-hn-2 canvas:** one canvas or a separate hardware canvas? → **One canvas.** Add the kinds to
  `custom-no-code.ts`, and feed the palette from the existing `GET /stateSpaceClasses`. A second canvas would duplicate
  D3 layers, overlays and trace mode. There are three new overlays: `c-atom` (planned as cmod-3), `hw-interface` and
  `register`.
- **D-hn-3 suggestion default** on a new graph: suggest only, or pre-select the suggested runtime? → **Pre-select
  `bare-c` always; SHOW the suggestion with its evidence, applied by one click.** Today's graphs then stay byte-stable,
  and an RTOS is never picked silently.
- **D-hn-4 which variants first:** → **b (exists), then h (the split app on the UNO twin + a display), then a (the same
  graph standalone, no Polari)**. One graph proves three variants.
- **D-hn-5 Zephyr order:** SAMD21 or C3 first? → **C3 first**: the same board and QEMU twin as sc-3, so the pairs
  re-run under Zephyr for a direct FreeRTOS-vs-Zephyr cost row. SAMD21 has no twin in the register. ESP-IDF already runs
  (sc-3).
- **D-hn-6 RULE 2 edges (added):** (i) Python nodes on a Linux SoC (`linux-device`) are a host layer, allowed? → **yes,
  host layer**. (ii) Third-party radio firmware (RNode) is commonly Arduino C++ (**unverified**): vendor it as an opaque
  engine artifact, or exclude it? → **opaque artifact, never a no-code target**.

## 7. Cost and slices

Cost per the cost rule; numbers are estimates until measured. The module `hwnocode` holds pure Python rows plus the
split. **0 MB** of new image for hn-0..2. The Zephyr SDK image is **unmeasured** (multi-GB expected, **unverified**).
The Fire's Polari node RSS is **unmeasured**.

| slice | what | proof (twin / home machines; never the droplet) | gate |
|---|---|---|---|
| hn-0 | module `hwnocode` (`HardwareSolution`); kinds `HardwareSubgraph`, `hw-interface`; the palette from `/stateSpaceClasses`; the `c-atom` overlay (= cmod-3) + `hw-interface` overlay; `hn-split` compiler row; edges `field-cmd`, `deadband`; MCP `polari_propose_hardware_solution` | variant h on the simavr UNO twin: the `uno-sim-rig-graph` device half renders **byte-identical** to cmod-1 (4188f6ae…); ADC 700→800 mV crosses the threshold → the backend solution → Commands → `led_on` echoed in the next frame; a configured chart tab; a Python node dropped on the board is refused with the reason | D-hn-1, D-hn-2 |
| hn-1 | the feature extractor + rule table + `RuntimeSuggestion`/`HardwareSuggestion`; cmod verdict `blocking` | sim-rig graph → bare-c (rules 1/4, S2 + sc-0 evidence); a graph from the C3 `prio_inversion.c` atoms → freertos/esp-idf with the 12 160 → 2 098 µs pair attached; selftest = one case per rule row | D-hn-3 |
| hn-2 | standalone variant: glue no-class mode, EEPROM config | the hn-0 graph minus the hw-interface → twin LED toggles on the ADC triangle with no bridge; the config byte written by the installer plan; `make` alone | D-hn-4 |
| hn-3 | Polari-hosted: brd-2 + the `linux-device` placement + `hwfpga-regblock` row | the Renode `beaglev-fire` twin runs a lean node; a register write lights the hwsim-led pattern; the RSS is measured on pol-core | D-brd-3, D-hn-6 |
| hn-4 | fleet: one build, the index at install, `assign_indexes` | 3 UNO twins on one bridge, 2-bit index, 0 refused frames; a swapped port refused; ≈ 11 MB per twin measured | — |
| hn-5 | Zephyr glue target (`task`/`queue`/`mutex` nodes) | the inversion + deadlock pairs re-run on the C3 under Zephyr; cost rows beside the FreeRTOS ones; the image measured | D-hn-5 |

Not in scope: VHDL/C++/Rust/MicroPython on devices (RULE 2); BLCNC revival (shelved); KVM hardware apps; LoRa / HaLow
twins; signal-integrity physics.
