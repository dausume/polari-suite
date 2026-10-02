# Firmware scenarios (sc arc): FORCE a concurrency or physics bug on purpose, show the cycle where it goes wrong, then show the technique that makes it safe and what that technique costs

**Date:** 2026-10-02 · **Status: PLAN ONLY. Nothing is built.** Drafted by an opus agent from the tree on `dev-brd-wire`, the
simavr 1.6 headers (Debian `libsimavr-dev 1.6+dfsg-3+b3`, read 2026-10-02) and primary URLs. Fable reviews it.
**Three rulings (his, 2026-10-02) are DECIDED:** (1) fault kinds are **FirmwareFault OBJECTS**, one class per kind, so
a run attaches to an object and not to a label; (2) the analysis and the scenario analyzer are **their own module**;
(3) **open-source tools are pulled in wherever they exist** and driven as engines, not rewritten (§2d).
Companions: `BOARD_PROGRAMMING_PLAN.md` (the UNO, its twin and its variants), `GRPC_BRIDGE_PLAN.md` §grpc-j4 (the wire and the
parser), `HARDWARE_SIMULATION_PLAN.md` (Renode as the orchestrator), memories `firmware-faults-design`, `design-lod-viewer`.
Facts marked **unverified** were not confirmed from a primary source on 2026-10-02.

## 0. The ask, the correction, the goal, the boundary

**His ask:** *"track kinds of multithreading/concurrency programming and the bugs they produce on firmware (semaphores,
mutexes…), track space optimisation and safety, and simulate/solve why deviations like deadlock occur by simulating the
physics and disruption in the physical layer … or maybe my assumption on how those are happening is wrong."*
**His clarification:** *"eventually we want to do SCENARIO ANALYSIS to force it to be the case that bugs happen in the
concurrency so we can see what goes wrong and how/why we make it safer with certain techniques."*

**The correction, which he has not disputed:** deadlock is a LOGIC property. A circular wait needs no physics. What physics
supplies is a TRIGGER: it breaks an ASSUMPTION ("every message arrives", "one edge, one interrupt", "a write completes")
and that exposes a latent bug, which often looks like a hang. So there are two analyses, kept apart, because their
remedies differ (lock ordering or a proof vs a timeout, CRC, debounce or watchdog): **logical** — can this interleaving
happen at all? (§5's tiers); **physical** — inject the trigger at a physics-derived rate and watch it climb the ladder.

**Goal:** a `Scenario` row pins ONE interleaving or ONE trigger, for example "fire the tick ISR at this PC", "flip this
bit at this cycle", "drop the Nth ack". Running it BEFORE a technique shows the failure at a named cycle and PC, with
the trace. Running it AFTER shows it pass. The technique's cost is recorded in bytes and cycles. Every run can be
reproduced from the row plus its seed.

**Boundary:** firmware on admitted boards (the UNO first, twins before silicon); the digital layer later via Verilator
(forced register values at VCD cycles); the physical layer later via SPICE (`electrodevice`: where ringing comes from).

## 1. The rows: module `firmwarefaults` (ruled: its own module)

**Proposed name `firmwarefaults`.** Its `requires.modules` are `board` (FirmwareBuild, FirmwareVariant, the twin),
`grpcbridge` (the wire and parser under test) and `mathproofs` (claims). Its `requires.engines` are resolved through the
ladder (`board.custom.board_engines` pattern): `avr-twin` (prf-board-engines, reused), `renode` (hwsim worker, later),
`cppcheck` / `cbmc` / `avstack` per §2d.

Why a separate module and not part of `board`: the fault taxonomy is not about boards. The same `TornReadFault` row holds
on an STM32 or a soft core, and `board` is already large (file-size rule; D-brd-7 said to split into sensible chunks).

| Class | Key fields (beyond name/description/provenance) | Notes |
|---|---|---|
| `ConcurrencyPrimitive` | kind (irq-mask \| atomic-section \| spsc-ring \| semaphore \| mutex \| spinlock \| queue \| message-passing \| lock-free), needs_rtos, typical_cost_cycles | seeded; the UNO uses irq-mask, atomic-section, spsc-ring |
| `FirmwareFault` (base) + **one class per kind** | layer (concurrency \| physical-trigger \| space-safety), assumption_broken (→ `Assumption`), observable, primitives (→ ConcurrencyPrimitive), remedies (→ `Technique`), rate, rate_unit, rate_source (citation or `unverified`), needs_rtos | kind fields below |
| concurrency kinds | `TornReadFault` (width_bytes, read_order), `DoubleGiveFault`, `LostWakeupFault`, `PriorityInversionFault` (bounded/unbounded), `DeadlockFault` (lock_cycle_json), `LivelockFault`, `StarvationFault` | a logic fault; rate = the interleaving's probability, measured (§5) |
| physical-trigger kinds | `UartBitErrorFault` (ber), `DoubleEdgeFault` (bounce_us), `MetastableInputFault` (MTBF params), `BrownoutMidWriteFault` (droop V/ms, BOD level), `BitFlipFault` (upsets/bit/day), `ClockSkewFault` (ppm) | RATE comes from physics; a number without a source is labelled `unverified`, never guessed silently |
| space/safety kinds | `StackOverflowFault` (headroom_bytes), `BufferOverrunFault` (buffer, bound), `MissedDeadlineFault` (deadline_cycles) | space pressure is a cause: a smaller buffer is where the race lands |
| `Assumption` | statement, holder (FirmwareBuild/variant/class), who_relies (code ref: file+symbol), checkable_by (scenario \| static \| formal) | e.g. "a 32-bit read of g_ms is atomic" |
| `Technique` | restores (→ Assumption), primitive, idiom_c (RULE 2: C only), typical_cost (bytes, cycles, latency_cycles) | atomic section, lock ordering, timeout+FSM, debounce, CRC/resync, write-then-commit, priority inheritance, watchdog |
| `Scenario` | target_build (→ FirmwareBuild), target_variant, fault (→ a FirmwareFault row), breaks (→ Assumption), steps (ordered `ScenarioStep`), expected_observable, window_cycles, seed_policy, simulator (avr-twin \| renode \| silicon) | the forcing recipe |
| `ScenarioStep` | order, kind (`irq-at-pc` \| `irq-at-cycle` \| `corrupt-word` \| `drop-nth-frame` \| `flip-bit-at-cycle` \| `uart-ber` \| `hold-lock-order` \| `clock-skew`), args_json (pc as symbol+offset resolved against the ELF, vector, addr, value, cycle, p, n), condition_json (e.g. `g_ms & 0xFF == 0xFF`) | symbol+offset so a rebuild re-resolves the address |
| `ScenarioRun` | scenario, technique_applied (→ Technique or none), outcome (failed \| passed \| inapplicable \| undetermined), fault_cycle, fault_pc, landed_pc (where the forced IRQ actually landed), observed_json, trace_sha256 (VCD), firmware_sha256, elf_sha256, harness_digest, simulator_version, seed, sim_cycles, wall_s, stack_high_water, isr_latency_max_cycles, size_text/data/bss, cost_delta_json (bytes, cycles vs its pair), repro_json | the before/after pair = two runs with the same scenario + seed |

**A run becomes a claim.** One `MathClaim` per (scenario, build) states "firmware F under scenario S is free of fault B".
Its kind is a new value `safe-under-scenario`, and its `about_refs_json` names the Scenario, the FirmwareBuild and the fault
row. A new checker `sim` (tier 0, a WITNESS, never a proof) maps outcomes onto his vocabulary: `failed` → **refuted**
(`counterexample_json` = {cycle, pc, landed_pc, values}); `passed` → **witnessed** (one interleaving, not all);
the scenario's PC/ISR does not exist in this build (a `FEATURE_COMMANDS 0` build has no RX ISR) → **inapplicable**; the
window ran out before the forcing condition held → **undetermined**. A later formal tier (`cbmc`, §5) can raise a claim
to `decided`. A refuted claim is never deleted.

## 2. Forcing mechanisms per simulator

### 2a. simavr (the UNO twin): headers read, what is verified and what is assumed

| Hook (libsimavr 1.6) | Header | Status | Use |
|---|---|---|---|
| `avr_run(avr)`, "run one cycle of the AVR" | sim_avr.h:384 | **verified** (signature); per-INSTRUCTION granularity in practice is **assumed** (sim_avr.c not read) | check `avr->pc`, `avr->cycle` after each call = the step |
| `cpu_Step` / `cpu_StepDone` states | sim_avr.h:109 | verified (used by the gdb stub) | single-step from a debugger |
| `avr->interrupts.vector[64]` + `avr_raise_interrupt(avr, vec)`, `avr_is_interrupt_pending`, `avr_clear_interrupt` | sim_interrupts.h:57–92, sim_avr.h:319 | **verified** public | `irq-at-pc` / `irq-at-cycle`: raise vector N (TIMER2_COMPA = 7, verified: avr-gcc names the ISR `__vector_7`; USART_RX = 18, **unverified**). It latches only if enabled. The landing PC is recorded, not assumed |
| `avr_cycle_timer_register(avr, when, cb, p)` / `_usec` / `_cancel` | sim_cycle_timers.h:79–93 | **verified** | `irq-at-cycle`, `flip-bit-at-cycle` at an exact cycle |
| `avr_core_watch_write/read(avr, addr, v)` | sim_avr.h:419 | **verified** (an accessor that honours gdb watchpoints, NOT a callback) | `corrupt-word`: poke SRAM/I/O |
| `avr_register_io_write/read` | sim_io.h:83–90 | verified; **I/O space only** (`io[MAX_IOs=280]`) | SRAM writes cannot be hooked; poll `avr->data[]` per instruction instead (cheap at 2 KB) |
| `avr_raise_irq(uart_in, byte \| UART_INPUT_FE)` | avr_uart.h:68–76 | **verified** flag; the FE0-bit semantics are **assumed** | `uart-ber` (flip bits in the byte before feeding it) and framing errors |
| `avr_vcd_init/add_signal/start/stop` | sim_vcd_file.h:95–123 | **verified**; signals must be IRQs | VCD: allocate our own IRQs (`avr_alloc_irq`, sim_irq.h:85) for main PC, ISR PC, in_isr, the watched word, then raise them per instruction |
| `avr_reset(avr)` | sim_avr.h:380 | verified; whether EEPROM survives is **assumed** | brownout = stop mid-write, then reset |
| watchdog (`avr_watchdog.h`, `cpu_Crashed` = "watchdog fired") | sim_avr.h:113 | verified the module exists | watchdog coverage (§4) |
| a brown-out detector model | — | **absent** in the header set | brownout is emulated by the harness (stop and reset), said so in the run row |

**What `polari-avr-twin` must add** (≈ 250–400 lines of C, **estimate**; it stays one C file, splitting into
`forcing.c` when it passes the file-size rule):
`--elf FW.elf` (steps name symbols; the build already makes the ELF) · `--irq-at pc=<sym+off|0x…>,vec=N[,when=<cond>]`
and `--irq-at cycle=N,vec=N` · `--poke addr=val@cycle` · `--uart-ber p --seed S` · `--drop-frame n` (TX or RX path) ·
`--trace out.vcd --trace-window c0:c1` (a cycle window keeps traces small) · `--sp-watch` (min SP from SPL/SPH = exact
stack high-water) · `--isr-latency` (cycle raised → cycle the vector runs) · a final JSON line with fault_cycle,
fault_pc, landed_pc.

**Determinism.** simavr is deterministic on identical inputs. The runtime inputs are the stimulus, UART bytes and their
timing, which today are paced by wall clock. In scenario mode the harness runs `--free` and timestamps UART input in
CYCLES from a seeded schedule. So a run = f(Scenario row, ELF sha, harness digest, seed). Statistics (§5) vary the seed
(start-phase offset, BER draws), never the clock.

### 2b. Renode: the STM32F4 twin now, the Fire later (MIT)

Present in `renode-infrastructure` source (GitHub code search 2026-10-02): `AddHook(ulong addr, …)` on `TranslationCPU`
(irq-at-pc / corrupt-at-pc) · `Step(int count)` on `BaseCPU`/`ICPU` · `AddWatchpointHook` on `SystemBus`
(corrupt-on-access) · `WriteDoubleWord(ulong address, uint value)` · `IGPIOReceiver.OnGPIO(int, bool)` (raise an NVIC/PLIC
line) · `Emulation.RunFor` · `ExecutionTracer` / `CreateExecutionTracing` (the PC trace).

The exact monitor spellings (`sysbus.cpu AddHook 0x… "python"`, `nvic OnGPIO 37 true`) are **unverified**: the
monitor-syntax doc page does not list them. They are read from the docs and samples in sc-3. Renode is instruction-level,
not cycle-accurate. Its fault_cycle is therefore an instruction count plus virtual time, and the run row says so.

### 2c. Real silicon (D-sc-5)

A SECOND board drives the interrupt line (UNO GPIO → INT0, or into RX), timed off a trigger pin the target raises at the
vulnerable point (a test build sets it just before `hal_millis`); a USB-UART injects bit errors (the CP2102 on pol-core,
seeded host-side corruption); a bench supply sag gives the brownout. The limits: there is no PC-exact forcing; instead you get statistical alignment plus the trigger pin, and the evidence is
the observable (frames), not a cycle trace. A silicon run replays a twin scenario and agrees or disagrees with it.

### 2d. Open tools to pull in (ruling 3): survey; licences checked against the repo or vendor page 2026-10-02

| Tool | Licence | Maturity | How we drive it | Slice |
|---|---|---|---|---|
| simavr (github.com/buserror/simavr) | GPL-3.0 (GitHub API) | active (push 2026-09) | already linked by `polari-avr-twin`; hooks §2a | sc-0 |
| Renode (github.com/renode/renode) | MIT (LICENSE) | active | hwsim worker; hooks §2b; Robot tests | sc-3 |
| ARCHIE (github.com/Fraunhofer-AISEC/archie) | Apache-2.0 | active; needs its patched QEMU 10.0 + fault plugin; ARM/AArch64 | an engine image for Cortex-M fault campaigns (transient/permanent faults in RAM, flash, registers) | sc-3 option |
| FAIL* (github.com/danceos/fail) | GPL-3.0 | mature on Bochs/gem5/OpenOCD; QEMU "less mature" | reference for campaign design; OpenOCD backend = silicon | not adopted now |
| FIES (github.com/ahoeller/fies) | **unverified** | ARM QEMU fork, old | — | no |
| QEMU plugin fault-injection API (RFC on qemu-devel, 2026-03) | GPL-2.0 (QEMU) | **RFC, not merged (unverified state)** | watch; would replace ARCHIE's patch | later |
| FreeRTOS trace hook macros (FreeRTOS-Kernel) | MIT | mature | `traceTASK_SWITCHED_IN`, `traceTAKE_MUTEX…` → our wait-for-graph events | sc-3 |
| Zephyr tracing, CTF backend (docs.zephyrproject.org/latest/services/tracing) | Apache-2.0 | mature | CTF → babeltrace → rows | sc-3 (if Zephyr) |
| Percepio TraceRecorder / **Tracealyzer** | recorder Apache-2.0 (GitHub API); **Tracealyzer host = proprietary subscription** | — | the recorder format could be read; the host app is EXCLUDED | — |
| SEGGER SystemView | target code BSD-style (LICENSE.md); **host app free only for non-commercial use ("Friendly License")** | — | NC = hard blocker under the GPLv3 rule → EXCLUDED | — |
| ThreadSanitizer (LLVM) | Apache-2.0 w/ LLVM exception | mature | **host-only**: useful for the Java/C host side, not on AVR | — |
| cppcheck (github.com/danmar/cppcheck) | GPL-3.0 | mature | engine (apt), `--addon=misra`-style static rules on the generated C (§4) | sc-1 |
| Frama-C (+ Mthread, "included in main Frama-C distribution") | LGPL (frama-c.com; exact version **unverified**) | mature | Eva/Mthread race report; ISR modelling as threads is **unverified** | evaluate sc-2 |
| CBMC (github.com/diffblue/cbmc) | BSD-4-clause style (advertising clause → GPL-incompatible to LINK; fine as a separate-process engine) | mature | bounded model checking of `hal.c` + a harness that calls the ISR at nondeterministic points | **sc-2b** |
| ESBMC (github.com/esbmc/esbmc) | own code Apache-2.0; some solvers it can link are NC | active | engine only with an open solver (Z3 MIT / Bitwuzla); second opinion to CBMC | later |
| Infer/RacerD (github.com/facebook/infer) | MIT | mature | race checker aimed at Java/C++ locks; C/ISR fit **unverified** | no |
| GCC `-fstack-usage` + avstack.pl (dlbeer.co.nz/oss/avstack.html) | GPL (in avr-gcc) / ISC | stable | static peak stack from `.su` + call graph; cross-checks `--sp-watch` | sc-0 |
| puncover (github.com/HBehrens/puncover) | MIT | active, ARM-oriented; AVR **unverified** | code/stack size browser → rows, not its UI | later |
| GTKWave / Surfer / pyvcd | GPL-2.0 / EUPL-1.2 / MIT | mature / active / stable | pyvcd = engine-side VCD reader → the "cycles around the fault" table; GTKWave/Surfer = a person's viewer until §6's 2D viewer | sc-0 |
| SymbiYosys (github.com/YosysHQ/sby) | ISC | mature | the formal tier for FPGA-side scenarios (`design-lod-viewer`) | after Verilator rung |
| SPIN (github.com/nimble-code/Spin) / TLA+ | BSD-3 style / MIT | mature | model the RTOS lock graph → deadlock proof by state search | sc-3 |
| SCRAM fault-tree (github.com/rakhimov/scram) | GPL-3.0 | **stale since 2023** | FTA over FirmwareFault rows, if wanted | optional |

## 3. The FIRST scenario in full: the torn tick read on the UNO

**Finding while reading the firmware: the RX ring buffer does NOT tear.** The firmware is `board/custom/firmware/uno/hal.c`
plus an app; there is no `main.c` in the template, since brd-fi split it. The ring buffer
(`hal.c` lines 24–41) uses `static volatile uint8_t rx_head, rx_tail;`. Each index is ONE byte, so on AVR every read is a
single `lds` (verified in the disassembly). Each index also has exactly one writer, which makes it a correct
single-producer single-consumer ring. The one multi-byte variable shared with an ISR is the 1 ms tick:

```c
71  static volatile uint32_t g_ms;
73  ISR(TIMER2_COMPA_vect) { g_ms++; }
83  uint32_t hal_millis(void)
84  {
85      uint32_t v;
86      ATOMIC_BLOCK(ATOMIC_RESTORESTATE) { v = g_ms; }
87      return v;
88  }
```

The shipped code already applies the technique. The **BEFORE** build is therefore a scenario variant (`FirmwareVariant`
knob `HAL_MILLIS_ATOMIC 0`, rendered by `pol board gen`, never hand-edited) that reads `v = g_ms;` bare. Compiled with
avr-gcc 14.2.0 `-Os` in `prf-board-engines:trixie` (disassembled 2026-10-02):

| | `hal_millis` | size (hal.o .text) |
|---|---|---|
| BEFORE (bare) | `lds r22,g_ms` · `lds r23,g_ms+1` · `lds r24,g_ms+2` · `lds r25,g_ms+3` · `ret` | 504 B |
| AFTER (shipped) | `in r18,SREG` · `cli` · the same four `lds` · `out SREG,r18` · `ret` | 510 B |

The ISR (`__vector_7`) loads all four bytes, increments them, and stores all four.

**The interleaving.** The read is FOUR one-byte loads; the brief assumed two. Take g_ms = 0x000000FF:
1. the first `lds` gets byte 0 = 0xFF;
2. the forced ISR runs and g_ms becomes 0x00000100;
3. the next three loads get 0x01, 0x00, 0x00.

So v = 0x000001FF = **511 instead of 255 or 256**: time jumps 256 ms ahead, then falls back. At the 16-bit carry
(0x0000FFFF) the jump is +65 536 ms.

**Forcing steps:**
1. `corrupt-word g_ms = 0x000000FE @ cycle ≈ 320 000` (20 ms in, after `sei`), so the tick reaches 0xFF quickly;
2. `irq-at-pc pc = "after the first lds of g_ms in hal_millis", vec = 7, when g_ms&0xFF == 0xFF` (one shot). The address is
   resolved per build from the disassembly: hal_millis+4 bare, hal_millis+8 atomic.

This injects ONE extra tick (+1 ms), and the run row records it. The stricter variant `align-at-pc` pokes TCNT2 so the
GENUINE compare lands there, with no extra tick. It is the sc-1 refinement.

**How it surfaces** (apps/sim_rig.c lines 116–125): `now = 511` passes `(int32_t)(now - next_ms) < 0` early, so a frame
goes out with `uptime_ms = 511`. `next_ms` advances by 100, and the next frames carry 400, 500… So the decoded
SimRigState rows show **uptime_ms going backwards** (…200, 511, 400…) and one frame off cadence. CRC passes, because the
wire is fine and the value is wrong. That is why a CRC is NOT the remedy and the taxonomy says so.

**The pair:**

| Run | Outcome | Evidence |
|---|---|---|
| BEFORE (HAL_MILLIS_ATOMIC 0) | **failed** at fault_cycle/fault_pc = the 2nd `lds`, landed_pc recorded | the VCD window; decoded uptime_ms non-monotone; claim → refuted with the cycle |
| AFTER (shipped) | **passed** | the forced IRQ stays pending through `cli` and lands after `out SREG` (landed_pc = hal_millis+0x16, the `ret` — expected, the run records the real one); uptime monotone; claim → witnessed |

**Cost of the technique** (from the disassembly; the harness re-measures): **+6 B flash** (3 words); **+3 cycles** per
`hal_millis` call (`in`, `cli`, `out`); **interrupts masked ≈ 9 cycles** (four 2-cycle `lds` + `out`) = **≈ 0.56 µs
added worst-case ISR latency** at 16 MHz (**estimate** until `--isr-latency` measures it).

`ATOMIC_FORCEON` would save the `in` (−2 B, −1 cycle). It is only correct where interrupts are known to be on, so it is
recorded as an alternative Technique row, not the default.

**In the 2D viewer (§6):** one cycle axis; row 1 = main-loop PC (symbol-labelled: hal_millis+0…+0x16), row 2 = ISR PC
(`__vector_7`), row 3 = in_isr, rows 4–7 = r22..r25, row 8 = g_ms bytes. The cursor sits on the cycle where r22 holds
0xFF and g_ms becomes 0x100.

**Scenario 1b (space pressure, the ring the brief meant):** a variant with `RX_RING 512` needs 16-bit indices. Then
`rx_tail == rx_head` in `hal_rx_pop` becomes two loads and DOES tear: the head reads 0x01FF, stale slots are popped, the
parser sees garbage, and the CRC fails and resyncs (the observable the brief expected). No `_Static_assert(RX_RING <=
256)` guards this today (a §4 static rule); with `uint8_t` indices RX_RING 512 silently uses 256 slots and wastes 256 B.

### 3a. Five more scenarios (single-board unless marked)

| # | Scenario | Fault row / broken assumption | Forcing | Observable | Technique (cost to measure) | Target |
|---|---|---|---|---|---|---|
| 2 | lost ack without a timeout → hang | `LivelockFault`/hang · "every message arrives" | `drop-nth-frame n=1` on the ack | the firmware never leaves WAIT; telemetry stops | timeout + explicit state machine (+ watchdog) | UNO — needs a variant WITH a request/ack. The natural one is grpc-j4's designed **boot-announced index** handshake (not built) |
| 3 | double interrupt from a ringing edge → double give/count | `DoubleEdgeFault` · "one edge, one interrupt" | two INT0 edges `bounce_us` apart via the PD2 pin IRQ | a press counted twice | debounce (timer-qualified) on MCU; a synchroniser on FPGA | UNO — needs a button-on-INT0 variant (kit project 02) |
| 4 | UART bit error → the parser's residual frame loss | `UartBitErrorFault` · "a rejected span holds at most one frame" | `uart-ber p` seeded; plus the exact residual: a valid frame then part of another inside one rejected span (GRPC plan §Finding 3) | frames lost per 1000 vs p; the residual counted separately; FE0/DOR0 never read by the firmware today | rescan the trailing bytes after a rescued frame (the parser fix) + count FE0/DOR0 | UNO, today's firmware (no new variant) |
| 5 | brownout mid-write → half-updated record | `BrownoutMidWriteFault` · "a write completes" | stop at a cycle inside the EEPROM write, `avr_reset`, re-run | a record with new A and old B | write-then-commit flag (or two copies + sequence + CRC); BOD fuse | UNO — needs a variant that persists settings to EEPROM (none does today); simavr has no BOD model |
| 6 | priority inversion on a mutex | `PriorityInversionFault` · "the high task waits at most the critical section" | `hold-lock-order` + a medium-priority busy task | high task's deadline missed by the medium task's run time | priority inheritance (FreeRTOS mutexes have it, **unverified for ESP-IDF's FreeRTOS**) | **RTOS**: ESP32-C3 (D-sc-4) |
| 7 | classic two-lock deadlock | `DeadlockFault` · "locks are taken in one global order" | `hold-lock-order` A→B in T1 and B→A in T2, preemption forced between | both tasks blocked; wait-for graph has a cycle | lock ordering (or try-lock + back-off) | **RTOS**: ESP32-C3; SPIN/TLA+ model proves the order |

The UNO has no RTOS, so 6–7 need FreeRTOS. A twin for the C3 is **unverified**: Espressif's QEMU fork is reported to
cover ESP32-C3, and Renode support is unknown. Picking it is part of sc-3.

## 4. Space and safety beside it: rows on `FirmwareBuild` / `ScenarioRun`, no new report format

- **Stack high-water**, exact: `--sp-watch` tracks min SP; cross-checked by painting `__bss_end`..RAMEND with 0xA5 and
  reading back, and by the static peak from `-fstack-usage` + avstack.pl. Static RAM today is 491 / 2048 B (uno-sim-rig,
  brd-wire); the stack is NOT counted (`COST.md`).
- **Worst-case ISR latency**: measured per vector (raised → first instruction), max over the run.
- **Watchdog coverage**: today **none**, since no variant enables the WDT (verified: no `wdt_` in hal.c or the apps). A
  row states which loops kick it and the timeout.
- **Size per technique**: `size_text/data/bss` already on FirmwareBuild. A Technique run records the delta (§3: +6 B).
- **Static rules for 8-bit** (cppcheck plus a small rule list as rows): every ISR-shared multi-byte variable is read
  inside an atomic section; ring sizes carry a `_Static_assert` on index width; no `double` on AVR without the c_twin
  conversion; no recursion; no heap.

## 5. The three evidence tiers

1. **Simulation detects** (sc-0/1): a run is a witness or a refutation, with the cycle, PC and trace. It is never a proof.
2. **Formal proves:**
   - FPGA side: SymbiYosys on the generated RTL (the `design-lod-viewer` plan).
   - Firmware side: the brief said bounded model checking is out of scope. **With CBMC available as an open engine, a
     narrow firmware formal tier is in reach sooner** (sc-2b). The model is `hal.c` plus a harness that may call the ISR
     between any two statements of `hal_millis`. The claim "returns g_ms before or after the tick" is proved to bound k,
     or refuted with a trace.
   - Caveats, honestly: CBMC models C semantics, not AVR instruction interleaving. It proves the C-level property, and the
     simulation tier covers the instruction level. CBMC's result maps to `decided` (bounded), never to Lean's `proved`.
3. **Statistics estimate:** many runs, with the fault's RATE as the stimulus distribution (BER p, edge bounce, start-phase
   offset seeded) → likelihood per fault kind, with coverage stated. For scenario 1 the natural tear rate per byte-0
   carry is ≈ the vulnerable window (3 gaps ≈ 6 cycles) over the idle loop (≈ 45 cycles), so **≈ 13 % per 256 ms**. This
   is an **estimate**, and the twin measures it. It is also why the bug "works fine on the bench" until it does not.
   Rare cases are seeded from the formal counterexample prefix.

## 6. Pages (configured only; no new component in the first slices)

`/display/firmware-faults`: configured tables over fault rows (by layer), Techniques with their cost columns, Scenarios,
ScenarioRuns, the before/after PAIRS (one row per pair: outcome before/after, fault cycle, cost delta), and the claims
(mathproofs' existing table).

The trace goes to the 2D semantic-zoom viewer once it exists. Until then a run shows the VCD artifact link (sha) plus a
configured table of the ±N cycles around fault_cycle (pc, symbol, in_isr, watched registers), produced by pyvcd on the
engine side. No raw JSON (`observed_json` renders as key/value rows).

## 7. Decisions (his; recommendations in bold)

- **D-sc-1 module home → RULED 2026-10-02: its own module.** Proposed name **`firmwarefaults`**, requires board +
  grpcbridge + mathproofs (§1).
- **D-sc-2 trace format:** VCD from the harness (simavr's own writer, signals as IRQs) vs our own cycle log. **VCD**: it
  is the viewer design's shared time axis and GTKWave/Surfer/pyvcd read it. A cycle window keeps it small.
- **D-sc-3 scenarios in the pipeline's advisory stage:** **yes, advisory** (each forced run is sub-second to seconds on
  simavr, §8). Refutations surface; they never fail the build.
- **D-sc-4 RTOS target for scenarios 6–7:** ESP32-C3 FreeRTOS vs SAMD21 Zephyr. **The C3 first**, because FreeRTOS's
  mutex/semaphore/priority-inheritance primitives are the classic ones. Note: his register pick reads "STM32-C3", which was
  interpreted as ESP32-C3 and is **UNCONFIRMED**. Confirm the board before sc-3.
- **D-sc-5 forcing on real silicon:** **twins now, plus one silicon replay of scenario 1** when an UNO is on the bench (a
  second board or a trigger pin; §2c).
- **D-sc-6 which open tools first:** **pyvcd + avstack.pl/`-fstack-usage` in sc-0** (tiny, permissive, no new image);
  **cppcheck in sc-1**; **CBMC in sc-2b** (separate-process engine; its advertising clause forbids linking, not running);
  **FreeRTOS trace hooks + SPIN in sc-3**; ARCHIE only if Cortex-M fault campaigns outgrow Renode. Excluded: Tracealyzer
  (proprietary), the SystemView host (NC).
- **D-sc-7 the BEFORE build:** a scenario variant knob (`HAL_MILLIS_ATOMIC 0`) vs patching the binary in the twin.
  **The knob**: the BEFORE firmware is a real, reproducible FirmwareBuild with its own sha.

## 8. Cost (estimates until measured, per the cost rule)

- **Run time on simavr.** Scenario 1 needs ≈ 20 ms of boot plus one tick after the poke ≈ 0.35 M cycles. At the measured
  78.6 M cycles/s that is **< 10 ms of simulation**, so the run is dominated by process start and ELF load (**≈ 0.1–0.3 s
  per run, estimate**). Per-instruction PC/SP checks and VCD writing slow the loop by an unmeasured factor (**guess
  2–5x**). A 10 s firmware window ≈ 2 s free-running. A 1000-run statistics batch ≈ 5–30 CPU-min on one core.
- **Twin object cost:** unchanged, 11.2 MB peak RSS (`COST.md`), plus the trace window (KB–MB per run).
- **Harness change:** ≈ 250–400 lines of C (estimate) in `prf-board-engines/polari_avr_twin.c`. **No new engine image for
  sc-0/sc-1**: simavr and avr-gcc are already in `prf-board-engines:trixie` (534.7 MB). pyvcd and avstack are small
  (pip/perl). cppcheck and cbmc add an apt layer each (size **unverified**). They are measured before use and land in
  `cost.json`.
- **Rows:** ~16 fault classes plus ~8 Techniques plus ~7 Scenarios seeded (≈ 40 rows), and 2 runs per pair.

## 9. Slices

| Slice | What | Proof | Gate |
|---|---|---|---|
| sc-0 | module `firmwarefaults` (classes §1, one per file); taxonomy seeds (primitives, the 16 fault classes, Assumptions, Techniques); harness flags `--elf --irq-at --poke --trace --sp-watch --isr-latency` + the final JSON line; variant knob `HAL_MILLIS_ATOMIC`; pyvcd window table; avstack static stack | on the UNO twin: the BEFORE build **fails at a named cycle**, with the PC between the 1st and 2nd `lds` of `hal_millis`, uptime_ms 511 then 400 in the decoded frames, VCD sha recorded; the AFTER build **passes** with landed_pc after `out SREG`; cost pair recorded (+6 B, +3 cycles, measured latency); both runs reproduce bit-identically from row + seed | D-sc-2, D-sc-7 |
| sc-1 | scenarios 1b, 2–5 on the twin (+ `align-at-pc`, `--uart-ber`, `--drop-frame`, the stop-and-reset brownout); variants: RX_RING 512, request/ack (or the boot-announced index), INT0 button, EEPROM record; cppcheck rules | each scenario: one failed BEFORE + one passed AFTER, with its cost delta; scenario 4 = frames lost per 1000 at p ∈ {1e-5…1e-3} with the residual counted apart, then 0 residual after the parser fix | D-sc-6 |
| sc-2 | claims: `safe-under-scenario` kind, `sim` checker → refuted/witnessed/inapplicable/undetermined; the statistics tier (seeded rates → likelihood + coverage) | scenario 1's natural tear rate MEASURED vs the 13 % estimate; claims visible on mathproofs' table with counterexample cycles | sc-0 |
| sc-2b | CBMC engine on `hal.c` + an ISR-interleaving harness | `hal_millis` bare → refuted with a C trace; atomic → decided (bound k) | D-sc-6 |
| sc-3 | RTOS scenarios 6–7 on the C3 (after brd admits it): FreeRTOS trace hooks → wait-for-graph rows; SPIN/TLA+ lock model; Renode/QEMU twin pick | inversion: deadline miss measured, then bounded with inheritance; deadlock: cycle in the wait-for graph at a named tick, then none with ordering; SPIN proves the order | D-sc-4, brd C3 admission |
| sc-4 | pipeline advisory stage: every committed scenario re-run on every firmware change | stage output = the pairs table; a refutation is advisory, never a build failure | D-sc-3 |
| sc-5 | silicon replay of scenario 1 on his UNO (trigger pin + a second board on the tick or INT0) | the BEFORE build shows the backwards uptime on real frames, the AFTER build never does, over N minutes | D-sc-5, UNO on the bench |

Not in scope: metastability and timing-margin scenarios (they wait for the Verilator rung); signal-integrity physics (the
SPICE rung); SEU rates beyond citing them; Fire and soft-core firmware.
