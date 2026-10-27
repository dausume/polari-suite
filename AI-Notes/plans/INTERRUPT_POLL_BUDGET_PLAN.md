# Interrupt + polling budget per processor / per thread — on a RISC-V basis (ipb) — PLAN 2026-10-27

**His words (2026-10-27):** "Are NVIC interrupts and polling both things that are able to be fine-tuned to a particular chip or thread? …
we wrote some of our no-code structuring in a way that's completely centered around just interrupts … draft out an interface that tracks per
thread or per chip logic in terms of the real stuff that a thread or chip can process at a given time … two different columns what things are
polling, what things are interrupts, and per [iteration of all pollings] how many polling things do we want to happen … and how much space
between pollings that we leave for interrupts to be handled." Then the ruling: "open tooling over partially closed chips is the focus right now …
we do actually want to stick to RISC-V as much as possible … start from a RISC-V instruction set basis of how we operate, and adapt that as
much as possible to the other two types and orient our logic around the RISC-V, because that's where we're trying to head."

## 0. What is true today (read from dev, not assumed)
- `cmod/custom/task_plan.py` + `task_plan_steps.py`: every step has a LANE (`init | loop | isr`; `task` on FreeRTOS/Zephyr), tasks are grouped
  per processor and trigger, priority is deadline-monotonic, `isr_shared` marks a piece touched by an interrupt step and a loop step, a trigger's
  `how` is "interrupt" or "polled in the main loop". Polling is IMPLICIT: whatever sits in the loop lane.
- `board/custom/cycle_measure.py` (cyc-0) already MEASURES both sides on the simavr twin: per-vector ISR length + latency (n/min/max/mean) and the
  main loop's longest gap between two visits of its poll point. Nothing holds these as a BUDGET.
- The firmware manifest (`polari-firmware.json`) carries per atom `isr_vector` / `isr_safe`; counts of ISR atoms. All of this vocabulary is
  controller-agnostic by luck, not by design; the pages and words lean on "interrupt".
- Openness of our targets (the ruling's frame): AVR = closed core, open tooling (avr-gcc/avr-libc/avrdude/simavr); Cortex-M = closed core (ARM IP),
  open tooling (gcc/OpenOCD/QEMU); RISC-V = open ISA, open RTL only for some cores (Hazard3 in the Pico 2, PicoRV32, CV32E40P, CVA6 — memory
  `riscv-cores-reference`), Espressif's C3/P4 cores = open ISA, closed RTL. No open silicon at retail (microchip ladder's open-silicon rungs).

## 1. The principle: RISC-V vocabulary is the canonical shape; other ISAs carry an adaptation row
The budget row speaks RISC-V (privileged spec names). A chip on another ISA gets a cited ADAPTATION row that maps its mechanism onto those names,
and the page shows the mapping beside the number so a person learns the RISC-V way and sees where the chip departs from it.

| canonical field (RISC-V) | meaning | AVR (ATmega328P) | Arm Cortex-M (NVIC) |
|---|---|---|---|
| global enable `mstatus.MIE` | one bit that gates every interrupt | SREG I bit (`sei`/`cli`) | PRIMASK (`cpsie i`/`cpsid i`) |
| per-source enable `mie` | which sources may fire | each peripheral's enable bit (e.g. UCSR0B.RXCIE0) | NVIC_ISER |
| pending `mip` | which sources are waiting | each peripheral's flag bit | NVIC_ISPR |
| trap vector `mtvec` (direct / vectored) | where the core jumps | fixed vector table at 0x0000 (vectored only) | VTOR vector table (vectored only) |
| cause `mcause` | which source fired | implied by the vector taken | IPSR exception number |
| priority / preemption level | who wins, who nests | fixed by vector order; no nesting unless the handler re-enables I | NVIC priority + grouping (BASEPRI); hardware nesting |
| controller kind | timer/software via CLINT (`mtime`/`mtimecmp`), external via PLIC (claim/complete) or CLIC (levels, selective vectoring) | none (peripherals raise vectors directly) | NVIC + SysTick |
| idle | `wfi` | `sleep` | `wfi`/`wfe` |
| cycle counter | `mcycle` / `rdcycle` | none (the twin's own counter — cyc-0) | DWT_CYCCNT |

Every row above that names a number (entry latency, priority levels, nesting) is a FACT ROW cited to the spec or TRM before it is used; until read it is -1 /
"unverified" (rule `derive-or-cite-chip-data`). The C3's interrupt matrix and the P4's CLIC are their own cited rows (not assumed from the generic PLIC).

## 2. Terms (so "cycle" stays the clock's word)
- **scan** = one pass of all polls (PLC "scan"; bare-metal "loop pass"; on an RTOS each thread has its own scan = its period/tick).
- **poll divider** = this poll runs every Nth scan.
- **interrupt headroom** = the CPU share left after the scan's polls and the interrupts' work.
- Correction kept in the plan's words: interrupts do NOT wait for gaps between polls — they preempt a poll mid-instruction. What bounds an interrupt is
  the longest MASKED window (critical section, `MIE` cleared) plus the hardware entry latency. What polls and interrupts fight over is CPU TIME: ISR work
  steals cycles from the scan, so the scan deadline slips. That is the budget.

## 2b. Two columns ALWAYS, and the three ways a hart's time is divided (his questions 2026-10-27)
Interrupts are a feature of the chip, not of the RTOS: a hart's intake (enables, vector, controller) exists with or without a scheduler, so bare C
gets both columns too (the UNO's bare-C firmware already has six ISR atoms beside its polling loop; cyc-0 measured both). A column may be EMPTY
(pure polling superloop; interrupt-only design whose loop sleeps) but never missing. The RTOS adds threads and the defer-to-thread link, nothing else
on this axis. `schedule_model` on the hart row decides the derivations:
- **superloop** (bare C): one scan, polls in order; a poll is a part of the scan by construction. Tracks poll order + divider.
- **cyclic-executive** (bare C, time-triggered): the scan is split into fixed slots a tick starts; a task OWNS a slot — the only model where a
  task holds a fixed part of the cycle. Tracks the slot table (slot length, task, slack per slot).
- **preemptive-rtos** (FreeRTOS, Zephyr): a thread owns no part of the cycle; each thread is its own loop with a period or blocking point and the
  scheduler hands the PC to the highest-priority ready thread (on the tick or an event). The windows a thread occupies are an OUTCOME, repeating
  over the hyperperiod (LCM of the periods). Tracks per thread sub-row: period, priority, measured execution cycles, utilisation; per hart: the
  hyperperiod timeline + the response-time check (each thread meets its deadline given everything above it plus the interrupts).
An interrupt belongs to the HART in all three (it can land inside any thread's window), so the interrupt column is per hart and only the deferred
work carries a thread link.

## 3. The row shapes — the unit is ONE PROGRAM COUNTER (his ruling, see D-ipb-3)
**His words (2026-10-27):** "Two columns of polls and interrupts per PC, since that is what takes in the instructions and determines the genuine
stepping. In systems with two PCs (two chips) we would have four columns and so on." RISC-V's word for a PC with its own instruction stream is a
**hart** (hardware thread) — the canonical name here. One chip may hold several harts (RP2350: two; ESP32-S3: two Xtensa cores; ESP32-P4: two;
UNO and C3: one), so a chip contributes 2 × harts columns, and a system of chips sums them: two single-hart chips = four columns.

**`HartBudget`** (one per PC; RTOS threads are SUB-ROWS of the hart they run on — a thread has no PC of its own, it borrows the hart's by time
slicing, so its polls and interrupts land in its hart's two columns tagged with `thread`, `period_ms`, `priority`):
`hart` (chip + hart index), `processor` (BoardDefinition.processor / core), `isa` (riscv | avr | arm-m | xtensa), `controller_kind` (fact row ref),
`tier` (bare | freertos | zephyr), `clock_hz` (cited), `scan_deadline_ms` (knob: how often the whole poll set must complete), `polls[]`,
`interrupts[]`, `derived{}`. A `SystemBudget` is the ordered list of the system's harts' columns (2 × N), never a merged pair.

| polled column (`polls[]`) | interrupt column (`interrupts[]`) |
|---|---|
| `atom` (the c-atom ref), `trigger` (the Purpose trigger it serves) | `atom`, `source` (canonical name + the chip's vector/IRQ number) |
| `wanted_response_ms` (from the Purpose's deadline) | `expected_rate_hz` (from the stimulus / campaign rows, -1 until measured) |
| `poll_divider` (knob, default 1) | `priority_level` + `nests` (from the controller fact row + the chip's config) |
| `cycles_min/max` (cyc-0 measured; -1 on the C3 until ipb-4) | `length_cycles_min/max/mean` + `latency_cycles_min/max` (cyc-0 measured) |
| `cost_per_scan_cycles` = cycles_max / poll_divider | `utilisation` = length_mean × expected_rate / clock_hz |
| `masked_window_cycles` (the longest `cli`…`sei` / `MIE`-cleared stretch inside this poll's atoms) | `defers_to` (the thread/task an RTOS handler hands work to; empty on bare metal) |

**`derived{}`**: `scan_cycles` = Σ cost_per_scan + loop overhead (cyc-0's poll-point gap on the quiet pass); `scan_ms` = scan_cycles / clock_hz;
`polls_per_scan` (Σ 1/poll_divider); `scan_utilisation` = scan_ms / scan_deadline_ms; `isr_utilisation` = Σ utilisation;
`headroom` = 1 − scan_utilisation − isr_utilisation; `worst_latency_cycles` = controller entry latency + max(masked_window_cycles) + (the longest
higher-priority ISR, when nesting is off); per polled input the check `scan_ms ≤ wanted_response_ms / 2` (a polled input must be scanned at least twice
as fast as it must be answered).

**Suggestions (knobs-and-suggestions rule):** headroom < 0 → "scan deadline cannot be met: raise the deadline, raise a poll divider, or move <atom> to an
interrupt (its event rate × length fits)"; a poll failing the 2× check → "move to an interrupt" with the evidence; a masked window longer than the shortest
ISR's latency budget → "shorten the critical section in <atom>"; on an RTOS an ISR with `defers_to` empty and length above the controller's guidance →
"defer to a thread". Every suggestion names the measured rows it came from.

## 4. Slices (each its own branch off dev; selftest-proven; the page's Chrome pass in the isle)
**State 2026-10-27 (his "go with your own recommendations … work autonomously … both for planning and analysing existing hardware on specific Benches", then
"go with risc-v setups as much as possible for chip test cases" + "prefer more open source"):** ✅ ipb-0, ipb-1, ipb-2, ipb-3 BUILT on framework
branch `dev-ipb-0` (one commit), selftest `cmod.cmod_budget_selftest` 26/26; neighbours green (task plan 56/56, bench 46/46, bench setup 0 failures).
Deviations from the table below, said: (1) D-ipb-4's C3 `mcycle` harness (ipb-4) could NOT run today — the board engines (QEMU) are down with the swarm
(isle switch-over), so the first page shows the UNO's measured numbers and the RISC-V harts with -1 numbers + their cited facts; (2) TC-A1 moved OFF the
S3 onto the fully open QEMU RISC-V virt machine (his two mid-day rulings) — built as the facts + knob shape (harts by knob, CLINT + PLIC row, icount said),
numbers wait for ipb-4; the S3 stays on the bench page as an ISA exception with two harts; (3) TC-A2 = RP2350 two Hazard3 harts facts-only (as planned);
(4) TC-B2 = UNO + a C3 with an RTOS-shaped relay task on ONE plan (synthetic in the selftest) — four columns + the link row; the real C3 FreeRTOS graph
is still ipb-5; (5) knobs hold per process (not persisted) — said on the page. Also found + fixed: the board and cmod manifests had pre-existing drift
(bench / chip-ladder / workbench files never listed; the tool's `write` drops hand-set blocks, so the lists were merged by hand in the hand order).
| # | slice | holds | proves |
|---|---|---|---|
| ipb-0 | controller FACT rows | `board/custom/interrupt_controllers.py`: `InterruptControllerKind` rows riscv-clint-plic, riscv-clic, avr-vectors, arm-nvic (+ esp32c3-matrix) with the §1 fields, cited or -1; the adaptation table as rows | selftest: every numeric field is cited or -1; the C3 and the UNO resolve to a kind |
| ipb-1 | the budget row | `cmod/custom/budget.py`: `HartBudget` (thread sub-rows on an RTOS) + `SystemBudget` derived from the task plan (lanes → columns) + the cycle record (cyc-0) + the Purposes' deadlines; `derived{}` + the checks | selftest on uno-light + uno-button-clock: the two columns match the lanes, headroom is a number, the 2× check names the polled D3 sense; a two-chip system (UNO + C3 twin) shows FOUR columns, a two-hart chip (RP2350) also four |
| ipb-2 | the page | a tab on the processor's page (per-object display rule): two configured tables (polls / interrupts) + a headroom panel + knobs `scan_deadline_ms`, `poll_divider`; words in RISC-V names with the chip's mapping beside them | bench setup selftest; Chrome in the isle |
| ipb-3 | suggestions | the §3 suggestion rows as evidence-bearing SuggestionDefinition rows; a DerivedOverride for a person's move poll↔interrupt (re-derives the task plan's lane, AGREEMENT CHECK still runs) | selftest: forcing headroom < 0 produces the named suggestion |
| ipb-4 | RISC-V cycle harness | the C3 twin (QEMU) reads `mcycle` at the same three sampling points cyc-0 uses on simavr (function entry→ret, ISR flag→taken→mret, poll-point gaps) so the budget has real numbers on the RISC-V target first | selftest: two identical runs give identical counts; the uno-light-on-C3 budget fills |

## 4b. Test cases (his ask 2026-10-27: "(A) more than one hart exists in a MCU chip, and (B) we use an RTOS to coordinate Tasks across two
separate chips on a board") — each is a seeded graph + a selftest in ipb-1, a page check in ipb-2
**(A) more than one hart in one MCU**
- **TC-A1 ESP32-S3 (on the bench: the Elecrow board; twin = esp-emulator/QEMU)** — two Xtensa LX7 harts under ESP-IDF's FreeRTOS SMP: a sense task
  pinned to hart 0, a telemetry task pinned to hart 1, the UART receive interrupt routed to hart 1's interrupt matrix. Expect: FOUR columns on one
  chip; the interrupt sits in hart 1's column only; the hyperperiod timeline per hart; a task left unpinned shows as "either hart" with the check that
  the budget holds on both. Numbers: QEMU gives instruction counts (icount), not cycles — the rows say `basis: icount` until a real-board counter
  (`CCOUNT` on Xtensa) is read; the adaptation row for Xtensa is a new cited row (ISA exception, shown as such).
- **TC-A2 RP2350 (the RISC-V-first pick: two Hazard3 harts; NOT on the bench)** — the same graph on Hazard3 under Zephyr SMP. Until a Pico 2 is on
  the bench the case is facts-only (the controller row: Hazard3's standard `mie`/`mip` + its interrupt-priority extension, cited to the RP2350
  datasheet; two harts; the `mcycle` counter); the selftest proves the four-column shape from the facts, numbers -1. Buying one = his call (D-ipb-7).
**(B) an RTOS coordinating tasks across two chips on a board**
- Honesty first: no RTOS schedules across two chips. Each chip runs its own scheduler; "coordination" is MESSAGES over a link (UART/SPI/I2C), which the
  task plan already names as the `message`/`command` trigger kinds. So case B adds ONE row kind to the budget: **`links[]`** — transport, baud or clock,
  frame bytes, transit time (cited from baud × frame, or measured), the receiving hart's interrupt (which column it lands in) and the thread it defers
  to. An end-to-end deadline then becomes a CHAIN: thread on chip 1 → link transit → ISR on chip 2 → thread on chip 2, checked against the Purpose's
  response time; the page draws the chain across the four columns.
- **TC-B1 ESP32-S3 ↔ ESP32-C3 twin, both FreeRTOS, UART link** — the S3 senses and sends a frame; the C3 receives (UART ISR → queue → a task) and
  drives an output. Expect: four columns (S3 hart 0, S3 hart 1, C3 hart 0 … = six if the S3 uses both harts), the link row, the chain check, and a
  suggestion when the chain misses ("raise the baud / shorten the frame / raise the C3 task's priority"), each naming its rows.
- **TC-B2 UNO (bare C superloop + ISRs) ↔ C3 (FreeRTOS), UART** — the mixed case that is already on the bench (the uno-digital-twin bridge pattern):
  proves the chain works when one end has no scheduler (the UNO's receive ISR → ring buffer → the loop's poll point, cyc-0's measured gaps become
  the chip-1 leg).
- Prerequisite: a minimal seeded C3 FreeRTOS firmware graph (UART receive task + one output) does not exist yet — it is slice **ipb-5** below, and it
  is also the first RISC-V firmware under the RISC-V-first basis.

| # | slice | holds | proves |
|---|---|---|---|
| ipb-5 | the two-chip link + the C3 FreeRTOS graph | `links[]` on `SystemBudget` + the chain check; seeded graph `c3-uart-relay` (FreeRTOS: UART ISR → queue → task → GPIO) built through cmod's parser like the UNO's; the TC-B1/B2 graphs | selftests: the chain's legs sum to the measured/cited end-to-end; TC-B2 on the twins (UNO on simavr, C3 on QEMU) reproduces one frame end to end |

## 5. Decisions (his; my recommendation first)
- **D-ipb-1** Where the rows live: recommended = facts in `board` (beside variants/target_compat), the budget + suggestions in `cmod` (beside task_plan). Alt: a new `schedule` module.
- **D-ipb-2** The word for one pass of all polls: recommended **scan** (PLC lineage, established). Alt: "loop pass".
- ✅ **D-ipb-3** RULED by his words (2026-10-27): the unit is one PROGRAM COUNTER (hart): two columns per PC, four for two PCs, and so on; RTOS
  threads are sub-rows of the hart they time-share (they have no PC of their own). Multi-hart chips contribute one pair per hart.
- **D-ipb-7** Which multi-hart chip carries TC-A first: recommended the ESP32-S3 already on the bench (real twin now; an ISA exception shown as one),
  with the RP2350 as the RISC-V-first case once a Pico 2 is bought (his purchase; ≈ the price of the C3 DevKit in D-mis-20). Alt: wait for the Pico 2.
- **D-ipb-6** (opened by D-ipb-3) RP2350 PIO state machines and similar co-processors each have their OWN PC and instruction stream but no
  interrupt intake (they raise IRQs to a hart). Recommended: a column pair of their own with an empty interrupt column and a "raises → hart N" edge,
  because they do genuinely step instructions. Alt: fold them into the hart they signal.
- **D-ipb-4** Build ipb-4 (C3 `mcycle` harness) BEFORE ipb-2's page, so the first page shown is RISC-V numbers, not AVR's. Alt: page first on AVR numbers.
- **D-ipb-5** Openness shown on every processor page: a cited row "ISA open / core RTL open / silicon open / tooling open" (yes/no/unverified each) — the UNO reads closed/closed/closed/open, the Pico 2 open/open/closed/open.

## 6. Rules this plan keeps
RISC-V names canonical; other ISAs adapt ([[riscv-first-firmware-basis]]). Every number cited or -1. Measured costs over estimates (cyc-0 first). One no-code
model: the columns are the task plan's lanes seen as a budget, not a second model. Open tooling always; closed cores allowed as exceptions shown on the page.
