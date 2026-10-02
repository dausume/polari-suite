# C modularization (cmod arc): people write hardware C normally; Polari reads it as atoms, wires atoms in no-code, and always hands back a real C project

**Date:** 2026-10-02 · **Status: PLAN (his ruling recorded 2026-10-02); cmod-0 BUILT 2026-10-02 on `dev-cmod-0` (framework 3af175c, rf-node e0c0142, cli 500c9a5, suite dbdb3b9; unmerged — his word); D-cmod-1..5 his.** Drafted by an
opus agent from the verified tree (branch `dev-sc-2`), following the design he accepted (memory `c-modularization`). Facts
marked **unverified** were not confirmed from a primary source on 2026-10-02.

Companions: `BOARD_PROGRAMMING_PLAN.md` (the UNO firmware this arc reads first, RULE 2), `FIRMWARE_SCENARIO_PLAN.md` (the
faults a scanner can name), `HARDWARE_SIMULATION_PLAN.md` hwsim-nocode (absorbed here, §5), `GRPC_BRIDGE_PLAN.md` (the
generated `<class>_packets.h`), memories `language-layering`, `no-code-foundations`, `nocode-generalization`.

## 0. The ask, the design, and why no transpiling

**His words (2026-10-02):** "ensure that people can make hardware C code normally in addition to with Polari, so it should be
similar to the way we structure our custom python code and enable it to be embedded into no-code via the polari engine …
atomize the C-code … and ensure it can be transformed into real C projects after the fact … modularization of C code into
polari is likely going to be a critical part of functionality."

**The design (accepted):**
1. A firmware project is a NORMAL C project — `*.c`, `*.h`, a Makefile — that builds with `make` and the toolchain with
   Polari absent. Nothing Polari adds may change a byte of what the compiler sees.
2. An **ATOM** is a C function with declared ports. Ports, resources and cost are **DERIVED by parsing** into rows, the way
   `moduleService/manifests.py generate|conform` derives `polari-app.json` from a module's files. The conformed manifest
   `polari-firmware.json` sits beside the Makefile and is never hand-maintained (hand-set: title / description / notes).
3. A **no-code graph over atoms** generates plain-C glue + a Makefile → the result is a real C project, committed as files.
   "Transform into real C projects after the fact" is true because it is never anything else.
4. The same atoms compile for the HOST so the engine's no-code sim can call them (cffi, §6); the simavr twin runs the
   real artifact for cycle truth; the installer flashes it.

**Why no C↔Python transpiling.** Python → C fails on semantics a firmware lives by: pointers and aliasing, `volatile`,
fixed-width wrap-around (`uint8_t` + 1 at 255), integer promotion at 16-bit `int`, ISR context (no allocation, no blocking),
and the 2 KB of RAM (no heap, no interpreter). C → Python is pointless on a device and lossy in the sim (the torn read of a
4-byte counter does not exist in Python). The honest link is to RUN the same compiled C on both sides. A Python node that
someone wants on an MCU is a person's rewrite in C (stated on the node; a restricted Python subset is a later question).

## 1. What exists (verified in the tree, `dev-sc-2`, 2026-10-02)

Under `polari-rf-node/polari-framework/` unless stated.
- **The Python precedent.** `moduleService/manifests.py`: `_scan_file` (AST facts per file) → `classify` (concept by
  filename) → `generate` (derive the manifest) → `_preserve_hand_set` (title/description/app/security survive) → `conform`
  (report drift, never a gate). A module's free code lives in `custom/` (e.g. `modules/board/custom/`: gen, build, variants,
  engine_run). Python reaches no-code through a ROW naming a callable: `polariNoCode/analysis_calls.py`
  (`AnalysisDefinition.callable_ref = 'module:function'`, the `AnalysisCall` node in `SolutionExecutionEngine.py`), and
  `polariNoCode/graph_compilers.py` (`GraphCompilerDefinition`, `compile_with`, provenance stamp).
- **The no-code node model.** `SolutionExecutionEngine.py` + its TS mirror (parity vectors, `selftest_parity`); loops,
  `SolutionInvocation` (the re-wrapping abstraction); the canvas = D3 shapes + Angular overlays dispatched by `stateClass`
  (memory `matrix-equation-operation-node`; operands bind to runtime context through `ValueSourceConfig`).
- **The generator precedent.** `modules/hwdigital/custom/logic_verilog.py` (ncg-3): `LogicBlockNode` rows → synthesizable
  Verilog + a self-checking bench whose expected values come from the Python reference evaluator — two implementations of
  the same rows must agree. cmod-1's glue follows the same honesty pattern (the graph's C vs the hand-written app on the twin).
- **The staked plan absorbed.** `HARDWARE_SIMULATION_PLAN.md` hwsim-nocode: `FieldRegisterBinding` rows (class+field ↔
  register, direction, scale) → a generated `bindings_generated.h`; the renode `main.c` split into a static core + generated
  dispatch. Here: a binding is an EDGE from a class field to an atom port, and the dispatch is the generated glue (§5).
- **Already-generated C.** `modules/grpcbridge/custom/c_twin.py` `render_c_header` → `<class>_packets.h` (struct,
  encode/decode with a presence mask, CRC32, `target=avr`). Glue calls these as library functions; they are never atoms.
- **The first subject.** `modules/board/custom/firmware/uno/`: `hal.c`/`hal.h` (USART0 + RX ring ISR, Timer2 1 ms tick,
  LED, PWM, ADC, the sc-1 knobs INT0 / UART error counters / watchdog), `apps/{sim_rig,blink,analog,echo,scenario_rig}.c`,
  `board_config.h`, `Makefile`. `custom/gen.py` renders a buildable project per `FirmwareVariant` (`custom/variants.py`:
  app + features + knobs + build flags) — a variant is today's hand-written "graph" (an app wiring HAL atoms).
- **Cost conventions.** `modules/firmwarefaults/COST.md` (bytes, cycles, stack; every number with its build and engine),
  `firmwarefaults/custom/stack_static.py` (`-fstack-usage -fcallgraph-info=su`, the chain peak).
- **The rules.** C/Verilog/SV only on devices (RULE 2, `language-layering`); derive-or-cite; reproducibility (inputs by
  sha, tool versions); no raw JSON on screens; one new component only if justified — none in cmod-0.

## 2. The atom model as rows

| row | what it is | key fields |
|---|---|---|
| `CProject` | one C project: a template inside a module (rendered per configuration) or a plain directory | kind, root, board, mcu, configurations, parser + version, cc + version, make-alone proof per configuration, manifest sha |
| `CModule` | a `.c` with its `.h` (or a lone header) | role (hal / app / config / source / header), files + sha256, atoms |
| `CFunctionAtom` | one C function | signature, kind (function / isr / entry), ports summary, resources (registers → peripheral, globals r/w + volatile + width + shared-with-ISR, library resources, the vector it IS, declared `uses()`), calls, pure (+ why not), ISR-safe yes / no / undetermined / isr (+ why), atomic block, annotation form + role, configurations, cost: text shipped, text as a node, stack frame + kind |
| `CPort` | a parameter or the return | direction in / out / inout, C type, AVR width, Polari type (int64 / double / bool / string / bytes / ref:Type), unit, meaning, source (derived or + annotation) |
| `CGraph` | a no-code graph over atoms (cmod-1) — what a variant is today | nodes, edges, generated project |
| `CGraphEdge` | an out port → an in port, or a class field ↔ a port (the hwsim-nocode binding) | from, to, scale/offset, deadband (cmod-1) |
| `CGlueBuild` | a generated project | files + sha256, the graph's sha, build result, .hex sha, make-alone proof (cmod-1) |

**Derivation.** A CONFIGURATION is one buildable rendering (the UNO: the four single-instance seeded variants + two
coverage configurations that turn every sc-1 knob on, so knob-gated functions are seen). Every configuration is parsed;
an atom's facts are the UNION over the configurations that compile it (conservative: "may touch"). Functions defined in
headers are library. Verdicts close over the call graph: pure = touches no global, register or resource and calls only
pure functions; ISR-safe = every global it shares with ISR context (ISRs + their callees) is accessed inside an
`ATOMIC_BLOCK` when wider than one byte (the torn read) or modified read-modify-write while an ISR writes it (the lost
update); a caller of an unsafe atom is unsafe; a manual `cli()`/`sei()` region → undetermined (not tracked).

**`polari-firmware.json` (schema `polari-firmware/1`)** = project, kind, root, board, mcu, the parser block (pycparser
version, the fake-header sha, the register snapshot's avr-libc version + `-dM` sha), the build block (CC / CFLAGS / LDFLAGS
read FROM the Makefile, cc version, how cost is measured), configurations (flags, sources, generated files, source sha,
ELF shas, make-alone .hex sha), modules (files + sha), atoms, counts. `conform` = generate → keep the hand-set fields →
write ONLY if something derived changed, so a second conform changes nothing. Registers are not typed in: avr-libc's own
`<avr/io.h>` read with `avr-gcc -mmcu=… -E -dM` gives every `_SFR_*` register and `_VECTOR(n)`, committed as a snapshot
with its sha; the one judgement (register → peripheral) follows the datasheet's naming and is a written table.

## 3. The parser — D-cmod-1 (recommend pycparser)

| | pycparser | libclang |
|---|---|---|
| licence | BSD-3-Clause (package metadata: BSD) | Apache-2.0 WITH LLVM-exception |
| in Polari today | **already in the framework image**: `requirements.txt` pins `pycparser==2.21` (cffi needs it) — measured in `prf-backend:staging` (Python 3.12) | absent |
| Debian trixie | `python3-pycparser` 2.22-2 | `python3-clang-19` 19.1.7 → depends `libclang-19-dev` (304.5 MB installed) + `libllvm19` (126.7 MB) + `libclang1-19` (37.1 MB), 33 packages with gcc-14 dev deps (apt simulation in `prf-board-engines:trixie`, 2026-10-02) |
| where it runs | in the framework process, pure Python, ~0.9 s for the UNO's 6 configurations | an engine image (the framework image is Alpine/musl; the PyPI `libclang` wheel's musl support **unverified**) |
| avr-libc headers | **cannot parse them** (measured: `avr-gcc -E hal.c` fails at the first `__attribute__` in `<stdint.h>`'s mode typedefs; `__asm__ __volatile__`, `__cleanup__` follow) and they would erase register names (`UDR0` → `(*(volatile uint8_t *)(0xC6))`) → **fake headers** (the pycparser recipe) | parses them with `--target=avr` and GCC attributes (**unverified here**: not installed) |
| preprocessor | none of its own → its bundled PLY `pycparser.ply.cpp` (pure Python; two fixes: `!=` in `#if`, `#line` per file); cross-checked against GNU `cpp` on the host: same functions, same lines | its own |

**Recommendation: pycparser** — zero added bytes, runs where the rows live, and the fake headers are a feature: `ISR(v)`
becomes `void __polari_isr_v(void)`, `ATOMIC_BLOCK(t)` becomes `if (__polari_atomic_block(t))`, registers stay
identifiers the scan reads by name. Cost of the choice: macro-heavy code that only makes sense after real expansion
(`_SFR_MEM8` arithmetic, inline asm) is opaque — stated per atom when it matters. Revisit libclang if a project needs C11
`_Generic`, GNU statement expressions or C++ (RULE 2 excludes C++).

## 4. The annotation — D-cmod-2 (recommend both forms, the macro first)

```c
POLARI_NODE(hal_adc_read, in(channel, "", "A0..A5 (0..5)"), out(return, "count", "10-bit ADC = Vin*1024/Vref, 0..1023"),
            role("one blocking ADC conversion, AVcc reference"))
uint16_t hal_adc_read(uint8_t channel)
```
`#define POLARI_NODE(...)` (empty, `#ifndef`-guarded, in the project's own header — the UNO's `hal.h`) → a plain build never
sees it. The comment form `/* @polari-node(name, in(…), out(…)) */` serves a file that must not depend on any header of
ours. Clauses: `in` / `out` / `inout(<param>[, "unit"[, "meaning"]])`, `out(return, …)`, `uses(<resource>, …)`,
`role("…")`. Malformed → REFUSED with file:line (unknown clause, a port the signature lacks, `out()` on a by-value or const
parameter, an unclosed parenthesis, a port declared twice, an annotation not right above the function it names).

**Derivable WITHOUT annotation:** the signature (C types → AVR widths → Polari types), by-value = in, const pointer = in,
pointer only written through = out, read+written / handed on = inout, return = out; globals touched (r/w, volatile, width),
registers + peripheral, calls, ISR (by the macro), atomic regions, pure, ISR-safe, cost. **Needs the annotation:** the
UNIT and MEANING of a port, a pointer's direction when it is only handed to a callee, resources the scan cannot see (a pin
named by a knob: `uses(LED_PIN)`), the node's role. (Not yet: overriding a port's Polari type — `uint8_t *` stays `bytes`.)

## 5. Generated glue — "always a real C project" (cmod-1)

A `CGraph` → `polari_graph.c` + `polari_graph.h` + `Makefile` + the atoms' own `.c/.h` copied verbatim + the generated
`<class>_packets.h` + `board_config.h`:
- `polari_graph.c` holds `main()` = the init atoms (ordered by their resources: tick before anything reading `hal_millis`),
  `sei()`, then the loop: per edge a plain C assignment between locals typed from the ports; command dispatch by
  `msg_type` (the hwsim-nocode `FieldRegisterBinding`: class field → atom port, presence-mask gated); telemetry encode on
  a period atom; nothing else — no runtime, no interpreter, no tables walked at run time.
- The generated files are COMMITTED into the user's project (D-cmod-4) with a header comment naming the graph and its sha;
  editing them by hand is allowed and shows up as drift on the next `pol cmod conform` (a person's C wins; the graph is
  told, never silently re-imposed).
- Proof shape (logic_verilog's): the graph that mirrors `apps/sim_rig.c` → glue whose twin run reproduces the hand-written
  app's frames byte for byte (same seed, same stimulus), and `make` alone builds it.

## 6. Host execution via cffi — D-cmod-5 (recommend AFTER the twin path)

Compile the atoms for the host with `-DPOLARI_HOST`: the HAL atoms are swapped for host stubs (a register file in RAM, a
virtual `hal_millis`, the RX ring fed from the sim) or for the twin's pty; pure atoms (`sensor_value`, `crc8`) need nothing.
The engine calls them through cffi (pycparser underneath — already present). Limits, stated on every result: no ISR
preemption (an ISR atom is called between steps, never mid-instruction — the torn read cannot happen on the host, so ISR
safety stays the scanner's and the twin's), host widths differ (`int` 4 B, `double` 8 B → compile with `-m32`-style
checks or reject width-dependent atoms), no cycle timing. **Placement:** language-layering keeps native code out of the
framework process except parsing (firmwarefaults' engines note) → the host .so runs in an engine worker beside the board
engines; in-process cffi only for pure atoms, if at all. Recommend after cmod-1: the twin already gives truth for the whole
firmware; host execution is a speed-up for big no-code sims.

## 7. How the Python and C sides meet in no-code

One canvas, one engine. A new node kind **`c-atom`** (a `stateClass` like `AnalysisCall`): it names a `CFunctionAtom` row
(`uno:hal.hal_adc_read`) the way `AnalysisDefinition.callable_ref` names a Python function; its sockets ARE the `CPort`
rows (types and units from the manifest); its badge carries ISR-safe / pure / cost. In the SIM it executes through the
host build (§6) or the twin; on the MCU it is a call in the generated glue. A graph whose every node is a c-atom compiles
to a CGlueBuild; a graph mixing Python nodes runs only in the engine — a Python node wanted on an MCU is refused at
compile time with "rewrite it in C (a person's job)". The canvas needs the overlay for `c-atom` (cmod-3) — the one new
component, justified because a C node's sockets come from a manifest, not from a class.

## 8. Decisions (his)

- **D-cmod-1 parser** → recommend **pycparser** (§3: 0 MB, in-process, BSD; fake headers by design). Alternative: libclang
  in an engine image (~470 MB, real headers).
- **D-cmod-2 annotation form** → recommend **both, the empty macro first** (visible to tools, refusable, line-exact); the
  comment form for code that must not include our header.
- **D-cmod-3 where atoms live** → **both must work**: inside a module (`board/custom/firmware/uno/`, the manifest beside its
  Makefile, rendered per configuration) AND a standalone directory/repo a person wrote (`pol cmod conform ~/my-fw` — "people
  make hardware C normally"; its one configuration is the directory as it is). cmod-0 builds both kinds.
- **D-cmod-4 generated glue** → recommend **committed into the user's project** (a real project, reviewable, buildable from
  a clone) rather than a `.generated/` directory.
- **D-cmod-5 host cffi** → recommend **after** the twin path (cmod-2 follows cmod-1), executed in an engine worker.

## 9. Cost

| piece | measured / estimate |
|---|---|
| parser | pycparser 2.21 already in the framework image: **0 MB added**; the UNO parse (6 configurations, 34 atoms) **≈ 0.7–0.9 s** wall on the dev workstation |
| register snapshot | 96 registers + 25 vectors, one `avr-gcc -E -dM` (~1 s) on refresh only; a committed JSON |
| conform (cost + proof) | per configuration 2 compiles + 2 `avr-nm` + 1 `make` in `prf-board-engines:trixie` (local-image rung) → **≈ 16 s** for the UNO's 6 configurations; nothing new in the image (make, avr-nm already there) |
| an atom's cost | text bytes shipped (0 when inlined / gc'd, said so), text bytes as a node (`-fno-inline -Wl,--no-gc-sections`), the `.su` frame — numbers in the manifest, the conventions of firmwarefaults/COST.md |
| libclang (not taken) | `python3-clang-19` + deps ≈ 470 MB installed in an engine image |
| cmod-2 host build | one host gcc compile of the atoms per graph (~0.1 s); a worker process; **unverified** until built |

## 10. Slices (each its own branch off dev; proofs on the simavr twin + host builds — no UNO attached)

| slice | builds | proof |
|---|---|---|
| **cmod-0 ✅ BUILT 2026-10-02** atom parser + conformed manifest over the UNO firmware (`dev-cmod-0`) | module `cmod` (CProject / CModule / CFunctionAtom / CPort + CGraph as a row kind), `custom/{preprocess,annotation,scan,atoms,analyse,c_types}.py` (pycparser + PLY cpp with three fixes: `!=` in #if, #line per file, a zero-parameter function-like macro consuming its `()`), the register snapshot (avr-libc 2.2.1 `-dM`: 96 registers, 25 vectors), cost via `avr-nm -S --size-sort` + `-fstack-usage` (shipped / `-fno-inline -Wl,--no-gc-sections`; `-Wno-error` for the measurement only — GCC warns it cannot size a naked function), `custom/manifest.py` generate/conform, `pol cmod atoms\|conform\|show\|drift\|registers\|engines`, `GET /api/cmod/*`, `/display/c-atoms` (5 configured tables), 12 natural atoms annotated (hal_rx_pop, hal_usart_send, hal_millis, hal_led, hal_pwm_apply, hal_adc_read, sim_rig sensor_value / apply_command, echo_command, scenario_rig crc8 / slot_read / ack_step) | **MEASURED:** `pol cmod conform uno` → **34 atoms** over 6 configurations (4 seeded variants + 2 coverage), 32 ports, 3 ISRs, 2 pure (sensor_value, crc8), 12 annotated, 0 not ISR-safe; every atom has ports, resources, text bytes (shipped and as a node) and a `.su` frame except hal_wdt_boot (naked — stated); e.g. hal_millis 24 B / 54 B as a node / 2 B stack, hal_adc_read 36 B / 2 B, hal_pwm_apply 130 B / 10 B, ISR(USART_RX_vect) 66 B / 10 B, sim_rig.apply_command inlined (192 B as a node, 92 B frame). The torn build (HAL_MILLIS_ATOMIC=0) → hal_millis + main **not ISR-safe** ("g_ms (4 B, written by ISR …) … tears it"). **Byte-identical:** 17/17 builds (5 seeded variants, uno-pair ×2, the 11 scenario variants incl. the refused ring512) the same .hex before/after the annotations; the probe re-proves 4 shipped variants against a stripped copy. **make alone** builds all 6 configurations (uno-sim-rig 4188f6ae… = board's own .hex). A second conform: unchanged. Conform ≈ 16–26 s (local image), parse ≈ 0.7 s. Selftest 61/61 (cross-checked against GNU cpp: same 13 hal.c functions, same lines), probe `tests/cmod_liveboot_probe.py --engines` 20/20, conventions 41/41 · 61/61 · 8/8, `manifests conform` 69/69, board 128/128 + live boot 43/43, firmwarefaults 141/141, c_twin 44 + wire 21 + contracts 34 + javabridge 25, mathproofs 83 — all unchanged | pointer-to-byte ports stay `bytes` (the annotation cannot set a Polari type yet); a manual cli/sei region is `undetermined`, not tracked |
| **cmod-1** one graph → generated glue | `CGraph` / `CGraphEdge` / `CGlueBuild` rows, the glue generator (§5), FieldRegisterBinding edges (hwsim-nocode), the sim-rig graph seeded | the glue's twin run = the hand-written `apps/sim_rig.c`'s frames byte for byte; `make` alone builds the generated project; conform reads it back as a project |
| **cmod-2** host execution | the `-DPOLARI_HOST` build + HAL stubs in an engine worker, cffi calls, the `c-atom` handler in `SolutionExecutionEngine` | pure atoms agree host vs twin on a seeded sweep (sensor_value, crc8); an ISR atom refused mid-step, its limits stated |
| **cmod-3** the canvas | the `c-atom` overlay (sockets from CPort, badges ISR-safe / pure / cost), drag a graph, compile, install via the Firmware Installer | a person builds the echo app from atoms on the canvas, installs it on the twin, PUT echoes |
| **cmod-4** a second board + a plain project | the next board's HAL (D-brd-4: Pico 2 / RP2350) as atoms; `pol cmod conform <dir>` on a person's own repo | the same graph retargeted by swapping HAL atoms; a plain repo conforms with no Polari file but `polari-firmware.json` |
