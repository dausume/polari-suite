# System hierarchy and terminology — what sits above Purposes, how Tasks stay independent, how options get scored

**Date:** 2026-10-16 · **Status:** PROPOSAL for his rulings (D-sys-1..6). Nothing built. Feeds FIRMWARE_GENERATION_MODULE_PLAN (fgm-3
Tasks, fgm-4 resolver) and FIRMWARE_FLOW_STATES_PLAN (Priority assignment).

## 0. His ask (2026-10-16, verbatim)

"We need to consider the participants and how we are going to connect purposes up to a higher level, and what level is above
purposes. What are we combining purposes into, and what is our terminology for that? We want to be able to define things like, how
important is this purpose? What priorities will we want on the tasks being derived from this purpose? And we also need to be tracking
that tasks are independent from purposes, and one task can be fulfilling multiple purposes and be taking C atoms from multiple
purposes. Because the way we organize tasks is an optimization question in respect to the boards, not how do we solve our purpose.
How do we solve our purpose can be done through multiple kinds of C atoms and C isotopes, and what is the best way to do that will
vary per board. And eventually we're going to want to account for things like cost, efficiency, trying to derive from the known
possible boards and chips what our best option is, and being able to score different kinds of solutions to something based on our
available resources, such as integrated circuits, chips, boards, stuff like that. … above firmware, which just applies to like one
board or two boards, we might have multi-board systems and embedded systems that incorporate in with simulations. That is where we
are accounting for the physical properties of a device and trying to do things like stress testing physically in terms of stress
tensors, and also like thermal stresses, simulating the thermal conditions, and then how the simulated sensors would react to those
conditions. So an embedded system, by that definition, is actually going to be a combination of our electronics system and the
physics simulation of the overall device. So maybe electronic system would be what we call that larger system. Think over that and
get back to me with some more terminology."

## 1. The core idea: two ladders, joined only through roles

Everything sorts onto one of two ladders. Mixing them is what made "task" ambiguous before.

- **The WHY ladder (requirements):** what must be true, how much it matters, under which limits. Never mentions a chip.
- **The HOW ladder (realization):** which parts, which code, how it is scheduled. Never mentions why.

They meet in exactly two places: **Participants** (a Purpose names ROLES; the HOW ladder decides which part plays each role) and
**proof** (a Purpose is proven by evidence produced on the HOW ladder). This is the same split the code already makes between a
hardware-agnostic `FirmwareSolution` and a per-board `HardwareBinding`, lifted one level up.

## 2. The WHY ladder

| level | term (recommended) | what it holds | exists today |
|---|---|---|---|
| 1 | **Purpose** | one outcome: goal, when/then, bounds (latency, delivery…), what Polari must see, its proof | ✅ `CapabilityDefinition` (UI "Purpose"), plan §8 |
| 2 | **Mission** | a set of Purposes a thing must fulfil, each with an **importance**, plus the **budgets** (cost, power, size, mass, thermal envelope) and the **environment** (ambient range, vibration, supply) it must survive | new |

**Why "Mission":** it is what the whole thing is FOR, it is scoped (one Mission per product or experiment), and it carries the
budgets a Purpose cannot (cost and power are properties of the whole, not of one outcome). Alternatives: **Charter** (formal,
less common), **Brief** (light, but reads as a document), **Requirement set** (accurate, cold). "Capability" stays retired as a
person-facing word (his ruling 2026-10-08).

**Importance lives on the Mission ↔ Purpose link, not on the Purpose** — the same Purpose ("Polari observes the light") can be
critical in one Mission and optional in another. Proposed scale (D-sys-2): **safety** (violation is never acceptable; overrides
everything) · **required** (the Mission fails without it) · **important** (scored heavily) · **desired** (scored lightly). Required
and safety are HARD constraints for the optimizer; important and desired are WEIGHTS in the score.

**Task priority is DERIVED, never typed per task:** a Task's priority = f(the highest importance among the Purposes it serves,
the tightest deadline among their bounds, its rate). That is the classic deadline-monotonic rule with importance as the tie-breaker:
shorter deadline → higher priority; equal deadlines → higher importance wins. A person may override (DerivedOverride, who/when/why),
which the flow-states plan's Priority assignment card shows as "derived: fast · overridden: interrupt".

## 3. The HOW ladder

| level | term (recommended) | what it is | exists today |
|---|---|---|---|
| 1 | **C atom** → **C isotope** | a family of implementations for one piece of work → one implementation fit for a given chip/board/runtime | ✅ CFunctionAtom, CIsotope (widening per fgm plan) |
| 2 | **Task** | a dispatchable unit of work on ONE processor: its atoms, its trigger, its derived priority, its Struct bindings. **Many-to-many with Purposes:** one Task can serve several Purposes and hold atoms several Purposes asked for; how atoms are grouped into Tasks is an OPTIMIZATION per board, not part of any Purpose | planned (fgm-3) |
| 3 | **Firmware** | everything that runs on ONE processor: its Tasks, its init, its scheduler/runtime (bare C, FreeRTOS…). A board with two programmable chips has two Firmwares (the UNO R3 already does: the 328P and the 16U2) | ✅ `FirmwareSolution` (+ `HardwareBinding` per board) |
| 4 | **Board build** | one physical board: its chips, each chip's Firmware, the parts wired to it (the LED, the button), its connectors | partly: BoardDefinition + BoardInstance + circuit rows |
| 5 | **Electronic system** | several Board builds + the links between them (USB, UART, I²C, radio) + the host software and Polari apps that talk to them (today's Cross-Domain Solution and Hardware App are the first, single-board case) | partly: Cross-Domain Solution, Hardware App, topology |
| 6 | **Device** | the Electronic system inside its physical body, simulated together: mechanics (stress tensors), heat (thermal fields), the environment — and the simulated sensors reading those simulated conditions back into the firmware twins | partly: simulation framework, sim spaces, FEM/thermal modules, the twin's ADC injection (`drive-adc-ramp`) |

**On the word "embedded system":** in common engineering use it means the computer INSIDE a device (our Firmware + its board), so
using it for the larger whole would read backwards to most engineers. And "electronic system" usually means electronics only. So:
**Electronic system** = all the electronics and their links (level 5); **Device** = electronics + physical body + physics, simulated as
one (level 6). The formal name for level 6 is a **cyber-physical system**; "Device" is the person-facing word. A **Device twin** is the
level-6 simulation (today's simavr "digital twin" is a Firmware-level twin — keep the two names apart).

## 4. Participants, restated

A Participant is a **role** a Purpose needs, not a part: "the light", "the button", "the controller", "the link to Polari", "the
operator's screen". Each role carries the requirements a part must meet (drive kind, interrupt-capable input, transport…). The HOW
ladder **binds** roles to parts — at Board-build level (D6 plays "the light"), at Electronic-system level (board A plays "the
controller", board B "the sensor head"), at Device level (this thermistor plays "the enclosure temperature sensor"). This is what lets
the optimizer swap a board or a chip without touching any Purpose. Today's Participants (board / chip / host / Polari) become the
coarsest roles; finer roles (the light, the button) come with fgm-4's typed HAL bindings, which already resolve a role's needs to a pin.

## 5. Scoring and choosing (the optimization)

- **Candidate** — one complete HOW-ladder answer to a Mission: which chips and boards, which isotopes, how atoms are grouped into Tasks,
  which runtime, how roles bind to parts.
- **Trade study** — the comparison of Candidates for one Mission (the standard engineering name for exactly this).
- **Score card** — per Candidate: HARD checks (every safety/required Purpose provable; electrical rules pass; flash/RAM within the chip;
  lifecycle constraints respected) and SOFT scores (weighted Purpose fulfilment by importance; cost from parts and boards; power; timing
  margin against each bound; memory headroom; parts availability from what is ON HAND — e.g. his kit register — vs to be bought; licence).
  Every number carries its source (the resource-cost and reproducibility rules); unknown numbers are `undetermined`, never 0.
- Reuse: `ResourceCost` rows (measured cost per engine/module), the kit-part counts (what is on hand), `electrical_check` findings, the
  resolver's claims (fgm-4), the context-scoring module's weighted-score machinery.

## 6. What this changes in current plans (small)

- fgm-3: `TaskDefinition` is many-to-many with Purposes from day one (a `serves` list), and its priority is a DERIVED field (§2).
- fgm-1 rows: Participants evolve from part references to roles with requirements; the existing four become coarse roles.
- A `Mission` row (+ `MissionPurpose` link with importance) is the next WHY-ladder slice; budgets and environment are fields on it.
- Board build, Electronic system, Device become explicit rows only when the first multi-board or physics-coupled case is built; until
  then the Cross-Domain Solution and Hardware App remain the single-board stand-ins.

## 7. Decisions (his; recommendation first)

- **D-sys-1** the word above Purpose: **Mission** · Charter · Brief.
- **D-sys-2** importance scale: **safety / required / important / desired** (hard, hard, weighted, weighted) · a numeric 1–5.
- **D-sys-3** task priority: **derived (deadline-monotonic, importance breaks ties), overridable** · authored per task.
- **D-sys-4** the top two HOW levels: **Electronic system (electronics + links + host software) and Device (electronics + physical body +
  physics, simulated together)** · "Electronic system" for the physics-coupled whole (his suggestion) · "Embedded system".
- **D-sys-5** Participants as **roles bound to parts** · parts named directly.
- **D-sys-6** the comparison words: **Candidate / Trade study / Score card** · Option / Evaluation / Score.
