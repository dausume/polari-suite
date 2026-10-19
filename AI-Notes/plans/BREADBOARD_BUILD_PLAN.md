# Breadboard build walkthrough (bb) — PLAN, 2026-10-19 (nothing built)

His words (2026-10-19, quoted):
- "It would also be good to be able to model bread-boards and how components map to them, we should implement that visualization as well and be capable of rendering that along with the board visualizations, then be able to render 2D visualizations of components and jumpers piece by piece to make a walk-through of anything defined via no-code."
- "Initial real versions after simulations should jump up to breadboard visualizations. Then after the user confirms the breadboard looks correct from following the steps, then we attempt to bind to the breadboard prototype device."

## 1. The lifecycle this adds (stage S1 Breadboard of SYSTEM_HIERARCHY_TERMINOLOGY §8–13)
1. **simulated:** proven-on-twin. Exists: ScenarioRuns.
2. **breadboard layout derived (NEW):** every part, its holes and every jumper are computed from the solution. The compiled netlist of the layout EQUALS the
   design's nets, which is the proof that the layout is the design.
3. **walkthrough confirmed by the person (NEW):** they follow the steps. Each step is ticked, and the final check is "it looks like this".
4. **bind:** Detect → flash → the bridge runs. Exists: the Firmware Installer, Hardware Bridge App and readiness.
5. **proven-on-hardware.**

After a twin proof, the installer and the readiness page show "next: build it on a breadboard (link)" rather than "flash".

## 2. Reuse (what exists, read from the code)
| need | exists | gap |
|---|---|---|
| breadboard as connectivity | `electrodevice` ncg-5: `BreadboardDefinition` (rows, two rails), `ComponentPlacement` (kind, params, `tiepoints_json` `r<N>L/R`, `vplus`, `gnd`), `BoardJumper` (board↔board ties), `breadboard_netlist_seed` (the connectivity compiler), electrical rules (LED Vf/series resistor, ucd-0c) | no HOLE geometry (the column letters a–e / f–j, the rail columns, the pitch); no wire from an MCU header pin to a hole |
| the design's nets | `electrodevice` circuit level: the ucd-0c demo circuit as rows, with `board_pins_refs_json` (BoardPin refs); hsp `HardwareSystem`/`SystemLink`/`SignalPath`; the solve candidate's pin assignment | the circuits are hand-entered per demo; not derived from a sample config |
| the parts | `KitPart` (pin_roles, polarity, electrical notes, kit quantity, cited pages); the iso-0 route parts (`_pt` with kit keys); `fsc_prices` offers | 2-D geometry per part (lead count, spacing, orientation mark) |
| the board drawing | the pin view (d3, the sanctioned component): board outline, headers, bench parts, the stage selector, filters, click/Escape | no breadboard layer, no step mode |
| the stage ladder | `Enclosure` stages S1..S5 (hsp) | no confirmation row; no "next stage" advice |

## 3. What is new (small, one concern per file)
- **bb-0: geometry.**
  - Extend the tie-point grammar to the hole: `r<N><col>` (col a–e left of the trench, f–j right), and `rail:<top|bottom>:<+|->:<N>`. Old `r<N>L/R` stays valid,
    so the netlist compiler is unchanged in meaning.
  - `BreadboardDefinition` gains `size` (half 400-tie / full 830-tie) and pitch 2.54 mm (cited).
  - A `HeaderWire` (or a BoardJumper kind) joins a `BoardPin` (e.g. `arduino-uno-r3:D6`) to a hole.
- **bb-1: the placer.**
  - Input: a sample config (its routes → parts with kit keys, its pin assignment, the circuit nets).
  - Output: deterministic placements and wires:
    - rails first: GND and 5V from the header;
    - parts in column order;
    - a 4-leg pushbutton straddles the trench;
    - a two-lead part spans two rows; an LED is placed anode-row → series resistor → cathode-row;
    - sensors (TMP36 flat face toward the reader) span three adjacent rows;
    - the transistor E-B-C goes in three rows.
  - Then the electrical rules run (shorted strips, a missing series resistor, polarity), and **the netlist equality gate**: the layout's compiled netlist must
    equal the design's nets. Otherwise the layout is refused, with the mismatching nets named.
- **bb-2: the build steps.** These are ordered `BuildStep` rows, derived and never typed: (0) unplug the board, (1) the rails, (2…) each part with its orientation in
  plain words ("the LED's longer leg goes in row 14, hole e"), (…) each wire with its colour, and a final check list.
  - Each step names exactly what it adds; the drawing for step k is steps 0..k.
  - A person's edits (a different hole, a different wire colour) are kept BESIDE the derived value, as for Task Plans, and re-checked by the gate.
- **bb-3: the visualisation.** The pin view gets a breadboard layer drawn BESIDE the board outline (same zoom, same click/Escape rules), plus 2-D part sprites
  drawn from geometry:
  - a resistor with its colour bands computed from its value;
  - an LED with its flat side and long leg;
  - the pushbutton, the potentiometer, the TMP36 flat face, the transistor;
  - wires as curves in their colours.

  Modes:
  - **whole build;**
  - **step by step:** prev/next, the step text, the new element highlighted and the rest dimmed; the step is kept in the URL.

  Clicking a hole shows its net and what else is on that strip. Then comes a page `/display/breadboard?config=<name>` (the pin view's breadboard tab).
- **bb-4: confirmation and the bind step.**
  - `BuildConfirmation`: per-step ticks plus the final "it looks like this", by a named person, with a date, for one config and its layout's sha256. A layout change
    voids it.
  - The installer and the readiness page read it: confirmed → "bind (Detect → flash)" is the next step.
  - Not confirmed: binding is still possible, but only through an explicit "bind anyway", recorded with the reason. This follows his "advise, never block" rule; see D-bb-3.
- **bb-5: no-code.** Any Hardware System defined in the no-code (a Mission's chosen solution, a Cross-Domain solution's Firmware Run) gets its walkthrough through
  the same placer. The page has `?solution=` like the other no-code pages, and `pol board breadboard <config> [--steps] [--json]` (his CLI rule).

## 4. Order and the first proof
bb-0 → bb-1 (uno-light + its sense jumper first: S1 of the curated sample, FIRMWARE_SCORE_PROFILES_PLAN §13) → bb-2 → bb-3 → bb-4 → bb-5.

The first acceptance, checked in Chrome:
- S1's breadboard renders beside the UNO;
- stepping through it adds one element per step;
- its netlist equals the design;
- a deliberately wrong edit (an LED backwards, a missing resistor) is refused, in words.

## 5. Decisions (his)
- **D-bb-1:** Which breadboard is on the bench: half (400 ties) or full (830)? The kit page lists "Breadboard" without a size, so `kit_quantity` and the size are
  undetermined. I need it cited, or his measurement.
- **D-bb-2:** The wire colour convention. Recommend: red = 5 V, black = GND, signals in the pin view's signal-family colours (so the drawing and the bench agree).
- **D-bb-3:** The bind step after confirmation. Recommend ordered, with a recorded "bind anyway". (His words say bind AFTER confirmation; the standing rule is
  advise, never block.)
- **D-bb-4:** Confirmation granularity. Recommend a tick per step plus the final whole-board check.
- **D-bb-5:** An optional photo with the confirmation, kept in the file store and never in git (the kit-photo rule).

## 6. His answers 2026-10-19 (quoted)
"We should make it so breadboards are their own objects, we will also later on want protoboards as their own objects as well. Just define half and full
for now. Make wire colors modifiable"

- **Boards are objects.**
  - A breadboard is a first-class object: a `Breadboard` row (one physical board on a bench) of a `BreadboardModel` (the geometry).
  - It has its own object page (Polari's per-object display rule) and is a participant of the Hardware System. It appears in the pin view beside the MCU board, and
    a build names WHICH breadboard it is on.
  - The existing ncg-5 `BreadboardDefinition` becomes the model/instance pair (a converge, no lost rows).
  - **Protoboards later.** Room for `ProtoboardModel` / `Protoboard` (the same tie-point grammar, soldered = permanent; enclosure stage S2) is left in the
    design; nothing is built for it.
- **Two models only, for now:**
  - `half` — 400 ties: 30 rows × (a–e, f–j) + 2 rail pairs;
  - `full` — 830 ties: 63 rows × (a–e, f–j) + 2 rail pairs.
  - Pitch 2.54 mm. The counts are the common industry layout; cite a datasheet when one is read.
  - The kit's own size stays undetermined until he says it. A build asks which breadboard, and the default is `half`.
- **Wire colours are modifiable.**
  - A `WireColorScheme` object: the default is red = 5 V, black = GND, signals in the pin-view signal-family colours. A person can edit it or copy it for their
    own bench (seeded schemes are copied before an edit, as with score profiles).
  - Each wire can also take its own colour override, kept beside the derived colour.
  - The walkthrough text and the drawing use the effective colour.
- **Unanswered, so my recommendations stand (his to overturn):**
  - D-bb-3: ordered, with a recorded "bind anyway".
  - D-bb-4: a tick per step plus a final whole-board check.
  - D-bb-5: an optional photo in the file store, never in git.

## 7. 2026-10-19 — folded into PROTOTYPING_VIEWS_PLAN (his "general renderer for complex layouts spanning N boards")
This plan is now the LAYOUT slice of `AI-Notes/plans/PROTOTYPING_VIEWS_PLAN.md`:
- bb-0 → lay-0 (the board FAMILY: breadboard half/full, devboard; protoboard and PCB reserved)
- bb-1 + bb-2 → lay-1
- bb-3 is REPLACED: there is no pin-view layer; the layout is its own page with a general N-board renderer
- bb-4 → lay-3
- bb-5 stays (any no-code Hardware System gets a walkthrough).

The circuit-state work (cst) and its SPICE pairing are new slices in that plan.
