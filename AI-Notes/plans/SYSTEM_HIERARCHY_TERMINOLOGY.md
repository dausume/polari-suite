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

## 8. His rulings and refinement (2026-10-16, second message)

His words: "We need to be specific and call it 'Hardware Mission', Tasks can likely be derived through automation but still be able to
be modified manually via no-code. The tasks should likely be generated no-code with already specified and chosen c-isotopes and hardware
set as a context specific to that no-code. So the purpose and mission level no-code is not firmware specific, but the Task no-code
basically is (partially, it does not take in specific pins and registers yet, but it got formulated in respect to a specific set of them
and had optimizations done in respect to that hardware). So we should be able to build firmware derived for one device towards another
that is similar still (a lot of firmware is like this) but we acknowledge and record what the original was based and designed around,
and what other things we found to work as well if we search for them. Tasks are Specific to an Electronic System I think?"

**Ruled:** D-sys-1 → **Hardware Mission**. D-sys-3 refined → Tasks (and their priorities) are DERIVED by automation and editable by hand
in no-code (a hand edit is recorded beside the derived value, who/when/why).

**Three layers of specificity (the refinement, stated precisely):**

| layer | no-code | hardware-specific? | exists as |
|---|---|---|---|
| Hardware Mission + Purposes | the WHY drawings (plan FGM §8) | **no** — names roles, never parts | CapabilityDefinition; Mission row next |
| **Task Plan** | the Task no-code, GENERATED for a chosen hardware context (which processors, which chosen C isotopes, which runtime), then editable | **partly** — formulated and optimized against a hardware set, but no pins or registers | new (fgm-3) |
| Binding | pins, registers, claims, register settings per board | **fully** | ✅ HardwareBinding, claims, RegisterSettings |

**Answer to "Tasks are specific to an Electronic System?" — yes, with one precision:** the **Task Plan** is derived for one Electronic
system (it decides how the work splits across the processors that system has and which isotopes each uses), and **each Task belongs to
one processor** within it (a Task never spans two chips; work that crosses chips is two Tasks plus the link between them). Pins and
registers come one step later, in the Binding — that is why the Task layer is "partly" specific.

**Porting, recorded honestly (his "designed around … and what other things we found to work as well"):**
- **Designed for** — the Task Plan's origin context, written once and never changed: the Electronic system, processors, chosen isotopes
  and runtime it was derived and optimized for (+ who/when, the Hardware Mission version).
- **Also runs on** — every other hardware context the plan has been carried to, each with HOW we know: `resolver-valid` (every
  requirement met, untested) < `proven-on-twin` < `proven-on-hardware` (the existing proof ladder), plus what had to change (a
  different isotope chosen, a task regrouped, a binding re-made). Found by search: the resolver (fgm-4) tries the plan against the known
  boards/chips and lists the ones that resolve, ranked by the Score card.
- Reuse: this is today's HardwareBinding pattern (one solution, several bindings, each with its own validity and proof) applied one level
  up to Task Plans across Electronic systems.

**Still open:** D-sys-2 (importance scale), D-sys-4 (Electronic system / Device), D-sys-5 (Participants as roles), D-sys-6 (Candidate /
Trade study / Score card).

## 9. Electronic system vs Device, sharpened (his ask 2026-10-16: "Distinguish Between Electronic System and Device")

**One-line test:** if it carries a signal or runs code, it is in the **Electronic system**. If it only has mass, shape, heat or
surroundings, it is in the **Device**. A Device = one Electronic system + its physical body + the environment it sits in.

| | **Electronic system** | **Device** |
|---|---|---|
| boundary | where the wires end | the outer body and whatever touches it |
| contains | boards, chips, Firmware, Tasks, links (USB/UART/I²C/radio), power electronics, host software, Polari/Hardware apps | the Electronic system + enclosure, mounts, heat sinks, mechanical loads, materials, ambient conditions (temperature, vibration, humidity) |
| question it answers | does the logic and signalling work? | does it behave and survive in the world? |
| checks | electrical rules (a)–(j), resource claims, timing, protocol contracts, Task schedulability | stress, thermal, fatigue, ingress, sensor readings of physical conditions |
| twin | firmware twins (simavr) + simulated links + host apps | the electronic twin coupled to the physics simulation (FEM/thermal), which feeds the simulated sensors |
| owns | Task Plans, Firmware, Bindings | physical requirements that flow DOWN onto the Electronic system (e.g. "the board runs at 70 °C ambient" → derating, a slower clock) |

**The seam is the transducers.** Every sensor and actuator has two faces: an electrical face in the Electronic system (a pin, a
voltage, a PWM duty) and a physical face in the Device (a temperature, a force, a light level). The TMP36 is "an ADC reading on A0"
in the Electronic system and "the enclosure temperature" in the Device. A Device twin connects the two faces; an Electronic-system twin
drives the electrical face directly (today's `drive-adc-ramp`).

**They vary independently.** The same Electronic system can go into different Devices (the UNO light board in a desk lamp vs a sealed
outdoor box: same Tasks, different thermal and ingress limits). The same Device design can swap its Electronic system (UNO → Nano
inside the same box); the Device's physical requirements then re-check against the new electronics.

**Where the other levels attach:**
- Tasks and Task Plans → the Electronic system (§8). The Device only adds constraints to them.
- Hardware Missions and Purposes → either level. A Purpose whose participants are physical ("keep the enclosure under 60 °C") is
  only provable on a Device twin. A Purpose whose participants are electrical ("the button toggles the light") is provable on the
  Electronic-system twin.
- Porting (§8 "Designed for / Also runs on") is recorded between Electronic systems. A Device adds "also fits in" records for
  bodies the Electronic system has been checked inside.

**Design vs physical unit.** "Device" in speech also means the one physical thing on the desk. Proposal: **Device** and **Electronic
system** name designs; the physical thing is a **unit** (a Device unit, with a serial), the same split as BoardDefinition vs
BoardInstance today. PurposeObservation already attaches per BoardInstance, so observations move to the unit level unchanged.

**The UNO demo under this split:** the Electronic system = the UNO + LED + 220 Ω + button + D6→D3 jumper + USB + the host bridge + the
light app. The Device level is empty: nothing is boxed and no body is modelled, so the bench is the only environment. It stays empty
until the first enclosure or physics-coupled case (D-sys-4 still his to confirm).

## 10. Naming with a "Hardware" prefix (his proposal 2026-10-17)

His words: "We should likely add a specifying word to participants as well to clarify, and to enclosures as well would Hardware
Participant and Hardware Enclosure work? And maybe we change Electronic System to Hardware System. And then Device is Embedded Device"

| was | his proposal | assessment |
|---|---|---|
| Electronic system | **Hardware System** | fits: matches Hardware Mission / Hardware App; the §9 test is unchanged (signal or code → Hardware System) |
| Device | **Embedded Device** | fits: "embedded device" in common use means a physical product with a computer inside it, which is exactly level 6. (The §3 worry was about "embedded SYSTEM", which means the inner computer; that word is now Hardware System, so no clash.) Physical unit = "Embedded Device unit" |
| (body, §9) | **Hardware Enclosure** | fits, as ONE part of the Embedded Device's body. The body also holds mounts, heat sinks and mechanical loads, and the surroundings are not enclosure at all → proposal: Embedded Device = Hardware System + Hardware Enclosure (+ other body parts) + **Operating environment** |
| Participant | **Hardware Participant** | fits for parts, but today's Purpose seeds also name a host and Polari as participants (`purpose_seeds.py`: board, chip, host, Polari), and a person pressing the button participates too → proposal: keep **Participant** as the umbrella with three kinds: **Hardware Participant** (board, chip, LED, button, sensor), **Software Participant** (host bridge, Polari, a Hardware App), **Person** |

No existing class clashes with HardwareSystem, HardwareEnclosure, EmbeddedDevice or HardwareParticipant (checked 2026-10-17).

Updated ladders: WHY — Purpose → Hardware Mission. HOW — C atom/isotope → Task → Firmware → Board build → **Hardware System** →
**Embedded Device**. D-sys-4 and D-sys-5 become these names once he confirms the two refinements (Participant umbrella; Operating
environment beside the Enclosure).
