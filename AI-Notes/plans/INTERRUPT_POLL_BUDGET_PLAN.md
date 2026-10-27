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
| # | slice | holds | proves |
|---|---|---|---|
| ipb-0 | controller FACT rows | `board/custom/interrupt_controllers.py`: `InterruptControllerKind` rows riscv-clint-plic, riscv-clic, avr-vectors, arm-nvic (+ esp32c3-matrix) with the §1 fields, cited or -1; the adaptation table as rows | selftest: every numeric field is cited or -1; the C3 and the UNO resolve to a kind |
| ipb-1 | the budget row | `cmod/custom/budget.py`: `HartBudget` (thread sub-rows on an RTOS) + `SystemBudget` derived from the task plan (lanes → columns) + the cycle record (cyc-0) + the Purposes' deadlines; `derived{}` + the checks | selftest on uno-light + uno-button-clock: the two columns match the lanes, headroom is a number, the 2× check names the polled D3 sense; a two-chip system (UNO + C3 twin) shows FOUR columns, a two-hart chip (RP2350) also four |
| ipb-2 | the page | a tab on the processor's page (per-object display rule): two configured tables (polls / interrupts) + a headroom panel + knobs `scan_deadline_ms`, `poll_divider`; words in RISC-V names with the chip's mapping beside them | bench setup selftest; Chrome in the isle |
| ipb-3 | suggestions | the §3 suggestion rows as evidence-bearing SuggestionDefinition rows; a DerivedOverride for a person's move poll↔interrupt (re-derives the task plan's lane, AGREEMENT CHECK still runs) | selftest: forcing headroom < 0 produces the named suggestion |
| ipb-4 | RISC-V cycle harness | the C3 twin (QEMU) reads `mcycle` at the same three sampling points cyc-0 uses on simavr (function entry→ret, ISR flag→taken→mret, poll-point gaps) so the budget has real numbers on the RISC-V target first | selftest: two identical runs give identical counts; the uno-light-on-C3 budget fills |

## 5. Decisions (his; my recommendation first)
- **D-ipb-1** Where the rows live: recommended = facts in `board` (beside variants/target_compat), the budget + suggestions in `cmod` (beside task_plan). Alt: a new `schedule` module.
- **D-ipb-2** The word for one pass of all polls: recommended **scan** (PLC lineage, established). Alt: "loop pass".
- ✅ **D-ipb-3** RULED by his words (2026-10-27): the unit is one PROGRAM COUNTER (hart): two columns per PC, four for two PCs, and so on; RTOS
  threads are sub-rows of the hart they time-share (they have no PC of their own). Multi-hart chips contribute one pair per hart.
- **D-ipb-6** (opened by D-ipb-3) RP2350 PIO state machines and similar co-processors each have their OWN PC and instruction stream but no
  interrupt intake (they raise IRQs to a hart). Recommended: a column pair of their own with an empty interrupt column and a "raises → hart N" edge,
  because they do genuinely step instructions. Alt: fold them into the hart they signal.
- **D-ipb-4** Build ipb-4 (C3 `mcycle` harness) BEFORE ipb-2's page, so the first page shown is RISC-V numbers, not AVR's. Alt: page first on AVR numbers.
- **D-ipb-5** Openness shown on every processor page: a cited row "ISA open / core RTL open / silicon open / tooling open" (yes/no/unverified each) — the UNO reads closed/closed/closed/open, the Pico 2 open/open/closed/open.

## 6. Rules this plan keeps
RISC-V names canonical; other ISAs adapt ([[riscv-first-firmware-basis]]). Every number cited or -1. Measured costs over estimates (cyc-0 first). One no-code
model: the columns are the task plan's lanes seen as a budget, not a second model. Open tooling always; closed cores allowed as exceptions shown on the page.
