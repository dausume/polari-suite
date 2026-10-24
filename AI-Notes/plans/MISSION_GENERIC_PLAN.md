# Missions as a generic, nested, executable structure (mis-1 arc) — plan 2026-10-24

PLAN ONLY. Nothing here is built before his go. Grows out of `MISSION_PROFILE_SOLVER_PLAN.md` §2.1 / §5 / §9 (mis-0, the Hardware
Mission no-code as built 2026-10-18) and `SYSTEM_HIERARCHY_TERMINOLOGY.md` §1–§3 / §8 (the WHY and HOW ladders; a Board build has one
Firmware per programmable chip). Revised three times on 2026-10-24 as his direction came in; §0 keeps every message verbatim.

## 0. His words (2026-10-24, in order)

1. "the Mission and Purpose No-Code does not really seem particularly coherent right now, can you walk me through what the thoughts were
   on that and what/why it looks the way it does?"
2. "Plan it as a slice, keep in mind this is going to be the HardwareMission and that FirmwareMission and other Missions use and we will
   want a more generic Mission structure later on for various kinds of engineering, this way we can define higher level goals and attempt
   to use existing solutions through a search to meet Missions through automation or get as close as possible, so there is less work to do."
3. "We need to reconsider what kind of interface would make the most sense for Missions and Purposes, we are supposed to have states that
   drive automation to be able to search all existing pins and components, and try to drive them to use a combination of Breadboards and
   Dev Boards to find solutions. Hardware Missions I guess make sense to apply strictly to Prototyping at the Breadboard level."
4. "A Hardware Solution should be able to have subordinate Firmware Solutions and similarly that should be the case with Missions"

What they add up to: the Mission drawing is not a document; it is the **search**, drawn as states the engine runs. A person types the
WHAT (goal, Purposes, importance, aim); automation finds the HOW over everything on hand — dev boards, their pins, breadboards, kit
parts — and either meets the Mission or gets as close as it can and names what is left. Missions nest the way solutions nest: a
Hardware Mission (breadboard prototyping) holds one Firmware Mission per processor the search picks; the Hardware Solution it finds holds
one Firmware Solution per processor. The structure is generic so later kinds of engineering reuse it.

## 1. Why mis-0 reads as incoherent (read in Chrome 2026-10-24 on live, `/display/hardware-solutions?solution=mission-uno-light-mission`)

| what is seen | why it is there | the fault |
|---|---|---|
| page header about sim-rig, bridge and the moving-average chain; **Runtime: Python (Backend)**; a palette of Conditionals, Loops, Math, Debug | the Mission was mounted on the executable no-code canvas the way the Purpose drawing (fgm-1) was, but declared DECLARATIVE: the validator refuses every compute kind | an execution editor around a drawing nothing executes — the runtime and the blocks are lies for this drawing |
| every state in a column has a `then` edge to the first state of the next column | the renderer invents `outs` so the canvas has lines | the lines mean nothing and cross |
| identical magenta 190×96 cards, titles truncated, the sentence cut at two lines | one size, one colour for authored states | Purposes look like participants; importance, proof, resolution buried |
| "Can it be done here?" says cycle time and resources are **Not worked out yet** | `mission_text.ESTIMATES` predates sol-0 | the numbers exist and are not read |

The row + write-back are sound. The fix is not a prettier declarative drawing: the drawing must BE the search (his message 3), so the
canvas's runtime, edges and play button all come to mean what they say.

## 2. The generic Mission (what every kind shares)

| piece | generic (one shape, the `Mission` row) | per kind (declared by a `MissionKind` row) |
|---|---|---|
| goal, title, lifecycle, notes | ✅ as mis-0 | — |
| Purposes with importance (safety / required / important / desired, D-sys-2) | ✅ `purposes_json` | the Purpose class (hardware + firmware: `CapabilityDefinition`) and its derive door (goal, criteria, proof step, resolution — D-mis-4) |
| Participants = roles | ✅ `participants_json` | allowed participant kinds; how a `ref` is checked |
| Settings = the aim the search optimizes | ✅ `settings_json.objective` | the objective set + plain words |
| Limits | ✅ `constraints_json` | the vocabulary. **Hardware kind: NO stage field any more** — a Hardware Mission is breadboard prototyping by definition (his message 3); allowed boards, max dev boards, max breadboards, on-hand-only remain |
| **Parent / children** (new, §4) | `parent` (a Mission name or '') stored; `children` DERIVED | which child kind a kind spawns (hardware → firmware, one per processor) |
| **The search** (§3) | one drawing shape: a WHAT zone + a HOW zone of executable states; one `MissionRun` record shape; one verdict shape (meets / closest + gap) | the kind's **step blocks** and the engine function behind each |
| Scores | the competitive rule (best = 100, worst = 0) | the score profiles door |

**Class shape (D-mis-1, recommended):** generic `Mission` (shared fields + `kind` + `parent`); `HardwareMission` a thin subclass,
kind `hardware`, no new fields, so every mis-0 door, seed, CLI and selftest keeps working and the schema-freeze rule is honoured;
`FirmwareMission` a second thin subclass, kind `firmware` (§5). `MissionKind` registry rows seeded for both. The frontend never names a
kind: it reads the kind's step blocks from `GET /api/mission-kinds/{kind}`.

## 3. The Mission drawing = the search, as executable states

Same canvas, same engine (`python_backend` runtime — now true), category `mission` becomes EXECUTABLE: its validator allows the kind's
step blocks plus the ordinary conditionals, and refuses the rest by name. Two zones read left to right:

**WHAT zone (authored; the row is the truth, write-back as mis-0):**
- `Mission` state — goal, aim (objective), limits. Clicking it: the row.
- one `Purpose` state per Purpose — importance on it, a link into the Purpose's own drawing. Proof step and resolution shown on the card
  from the Purpose's derive door (read-only).

**HOW zone (executable states; each is ONE engine step that runs, emits ROWS, and shows them as tables when clicked):**

| # | step block (hardware kind) | runs (exists today unless marked NEW) | emits | knobs on the state | views it opens |
|---|---|---|---|---|---|
| 1 | **Needs** | pp-0 `pin_profiles` per Purpose + the Purpose's part roles | pin profiles, part roles, per Purpose | — | pin profiles page |
| 2 | **Inventory** — search all existing pins and components | **NEW as a step**: boards on hand (BoardDefinition / BoardInstance + the kit register) with every pin's availability-ladder verdict (hsp-0), breadboards on hand (size, count), kit parts (KitPart), jumper wire | on-hand rows, each with its source | `on_hand_only` (off → cited offers, labelled not-on-hand) | pin view at stage base per board |
| 3 | **Combine** — dev boards + breadboards | sol-0 `solve` for the pin assignment under pp-1 overlap rules, per hardware context; **NEW**: more than one dev board — split Purposes across processors (each Purpose's tasks to one processor, links between them become SystemLinks), bounded by `max_dev_boards`; lay-3 `layout_place` puts parts on the breadboards | Candidates: boards chosen, pin assignment, placements, score card; pruned branches with reasons | `allowed_boards`, `max_dev_boards`, `max_breadboards`, `prefer_plain_pins` | pin view (tasks-assigned), layout view of the candidate |
| 4 | **Delegate** — one Firmware Mission per processor | **NEW**: for each processor the candidate uses, derive a child `FirmwareMission` (§5) with the Purposes/tasks that processor serves, importance inherited, aim inherited, limits = that processor + the tier rt-0 says | child Missions (rows, `parent` set) | `runtime_tier` override per child | the child's own drawing |
| 5 | **Plan** (runs inside each child) | fgm-3 task plan + iso-0 variants + rt-0 approach | TaskPlan per processor | — | task plan page |
| 6 | **Prove** (inside each child, then the parent) | the twin bench runs each Purpose on the candidate's firmware (sim bench, ScenarioRuns); fsc scores; electrical check on the layout | proof step per Purpose per candidate; scores; findings | `prove_on` twin \| hardware (hardware = the bench gate, ins-0/1) | firmware scores, breadboard walkthrough |
| 7 | **Verdict** | roll-up: every safety + required Purpose `met` → *meets*; else the closest candidate by hard coverage → importance-weighted coverage → the aim (measured over estimated, labelled) → proof strength (D-mis-2), and the **gap**: unmet Purposes with the nearest existing piece that would close each | the chosen **Hardware Solution** (§4) or the closest + gap | — | the Hardware Solution's page |

Edges are data flow (Needs → Combine, Inventory → Combine, Combine → Delegate → Plan → Prove → Verdict) and the engine honours them.
The play button runs the search; each state shows ran / rows / took / basis. Steps 3, 6 are heavy → the engines on isle-core
(`pol deploy selftest`, `pol mission run <m> --on isle-core`), the rest in the backend. Every run is a `MissionRun` row: inputs by sha256
(the Mission row, the inventory snapshot, rule versions, engine versions), verdict, chosen solution, duration, who/when — compared over
time so the gap is seen shrinking.

The step blocks are the same no-code kind as every other block (object coherence: a `MissionStep` block definition per step, with
in/out ports typed by row class), so a person can insert a conditional (skip Prove on hardware unless the twin passed) or re-order
within the engine's dependency rules. The Purpose drawing keeps its declarative shape (requirements), but gains the same read-only
proof/resolution cards and loses its invented edges.

## 4. Nesting: Hardware ⊃ Firmware, for Missions and for Solutions (his message 4)

| level | Mission (WHY) | Solution (HOW, what the search finds) |
|---|---|---|
| hardware (breadboard prototyping) | `HardwareMission` — goal over the whole bench build | **Hardware Solution** = the Build: dev boards + breadboards + parts + wires (the layout config), the pin assignment, the SystemLinks, and its **subordinate Firmware Solutions** |
| firmware (one processor) | `FirmwareMission`, `parent` = the Hardware Mission; one per processor the Combine step chose; may also exist standalone (a port with no bench) | `FirmwareSolution` + its `HardwareBinding` on that board, `parent` = the Hardware Solution |

Rules: a child's Purposes are a subset (or a task-level split) of the parent's; importance inherited unless raised; the parent's Verdict
rolls up its children's (a Hardware Mission is never `meets` while a child Firmware Mission is not); a child's run is a step inside the
parent's run, but a child can be run alone; deleting a parent orphans nothing (children keep `parent` and are flagged). Participants:
the parent's coarse roles (board, chip, person) are where the children's roles bind — shown on both.

**Where the Hardware Solution row lives (D-mis-7, recommended):** the existing `HardwareSystem` (board) already holds boards,
components, circuits, participants, the recorded task plan, a verification state and the stage vocabulary — it IS the Build minus three
things. Extend it (seed_upsert, no field removed): `mission` (the Mission it answers), `candidate` (the sol-0 candidate id), `layout` (the
layout config), and `firmware_solutions_json` DERIVED (one entry per processor: FirmwareSolution + HardwareBinding + proof step). Its
`stage` stays for S2+ kinds later. "Hardware Solution" is the person-facing word for a HardwareSystem a Mission run produced; the page
`/display/hardware-solutions` (today the cross-domain drawing) gains a Hardware Solutions list beside it. Alternative: a new
`HardwareSolution` class referencing a HardwareSystem — more rows for the same facts.

`FirmwareSolution` gains `parent` (the HardwareSystem name or '') — today a FirmwareSolution stands alone and is bound to boards by
HardwareBinding; the parent makes the subordinate relation a stored fact, derived children on the parent make it readable.

## 5. FirmwareMission (kind `firmware`)

"Run these Purposes on this processor under this runtime." Purpose class `CapabilityDefinition`; participants processor / runtime / host
software / person; objectives smallest-image · least-RAM · fastest-cycle · **fewest-changes** (from a named origin Task Plan — the porting
case, §8 "Designed for / Also runs on"); limits processor, runtime tier, allowed isotopes, origin plan. Step blocks: Needs → Inventory
(the processor's pins and peripherals, its registers by class from rp-0) → Plan → Prove → Verdict. Mostly derived as a child by a
Hardware Mission's Delegate step; standalone first seed: `esp32c3-light-firmware` (the light Purposes on the C3 under FreeRTOS, origin the
UNO's plan) — the sample's S5 is twin-only, so its Verdict must say: closest `esp32c3-light`, proven-on-twin, nothing on hardware, gap "a
C3 on the bench". Honest by construction.

## 6. Slices (each its own branch off dev; suites on isle-core; the drawing run and checked in Chrome on the test node; then live)

| # | slice | builds | proves |
|---|---|---|---|
| 1 | **mis-1a** generic + nested model | `Mission` (+ `kind`, `parent`), `HardwareMission` / `FirmwareMission` thin subclasses, `MissionKind` seeded (hardware, firmware; step blocks listed), `MissionRun`, `MissionStep` block definitions; `HardwareSystem` + `mission` / `candidate` / `layout` / derived `firmware_solutions_json`; `FirmwareSolution.parent`; doors `/api/missions/{m}/children`, `/api/mission-kinds`; stage dropped from the hardware limits vocabulary (seed converges) | every mis-0 / hsp / fs selftest still green; a generic selftest reads the light Mission through its kind only; `uno-light-system` lists its FirmwareSolution as a child |
| 2 | **mis-1b** the executable drawing | category `mission` executable: validator allows the kind's step blocks + conditionals; renderer draws WHAT + HOW zones with data-flow edges; engine adapters for Needs / Inventory (on-hand only) / Combine (ONE dev board, sol-0 + layout) / Delegate / Plan / Prove (twin) / Verdict; play runs it; state click → its rows as tables; canvas palette filtered to the category; column theme tokens; the Purpose drawing loses its invented edges; `pol mission run <m> [--on isle-core]` | Chrome on the test node: the light Mission runs end to end on the UNO: Verdict *meets* with uno-light-sense-poll (4/4 proven-on-twin), the child Firmware Mission drawn and linked, the Hardware Solution row holding the child; a run row with inputs sha256 |
| 3 | **mis-1c** closest + gap, inventory off-hand, history | the Verdict's closest-candidate ranking and the gap list with nearest pieces; `on_hand_only` off (cited offers); run history compared; the Hardware Solutions list on `/display/hardware-solutions` | uno-light-unsensed ranks closest-but-unmet with the gap "observe the hardware state: no sense line; nearest piece: the sense_poll atom / the D6→D3 jumper"; plans labelled estimated |
| 4 | **mis-2** multi-board Combine | `max_dev_boards` > 1: Purposes split across processors, SystemLinks between them, one child Firmware Mission each, the layout with two dev boards on the breadboards | a two-board Mission (UNO + ESP32-C3 twin) delegates two children and the Verdict rolls both up honestly |
| 5 | **mis-3** standalone FirmwareMission | the firmware kind's own run (fewest-changes from an origin plan), seed `esp32c3-light-firmware` | §5's honest sentence on the test node |

Order 1 → 2 → 3 → 4 → 5; mis-1a ships alone first (nothing visible changes, everything stays green).

## 7. Decisions (his; my recommendation first)

- **D-mis-1** class shape: generic `Mission` + thin `HardwareMission` / `FirmwareMission` subclasses (recommended) — or one class with `kind`.
- **D-mis-2** "as close as possible" ranks by hard coverage → importance-weighted coverage → the aim → proof strength (recommended) — or aim first.
- **D-mis-3** the Mission's home is the executable drawing on the canvas, with each state's rows as tables (recommended; supersedes the
  2026-10-24 morning draft's configured page) — or a configured page beside a declarative drawing.
- **D-mis-4** a kind's Purpose must answer goal / criteria / proof step / resolution and nothing more is shown per Purpose (recommended).
- **D-mis-5** every run is a `MissionRun` row compared over time (recommended; the reproducibility rule) — or last-only.
- **D-mis-6** importance edited on the Purpose state of the drawing (recommended; one editor) — or also in a table.
- **D-mis-7** the Hardware Solution = `HardwareSystem` extended with mission / candidate / layout / derived children (recommended) — or a new
  `HardwareSolution` class.
- **D-mis-8** children derived by Delegate are rows (visible, runnable alone) (recommended) — or kept inside the parent's run only.
- **D-mis-9** first slice Combine = one dev board (recommended; multi-board is mis-2) — or multi-board from the start.

## 8. Where things are used: the reuse index (his message 5)

His words (2026-10-24, fifth message): "we need to be able to define how Tasks and Catoms tie back to purposes and where they are used,
that way we can more quickly search and find things that make sense when we are applying a new purpose somewhere else. We can think of
Mission and Purpose as ways to search for existing Solutions that we can either re-use or expand on."

What exists, in pieces: a Purpose names its CGraph (`CapabilityDefinition.graph`) whose nodes are atoms; a Task lists the Purposes it
serves (`TaskDefinition.purposes_json`) and its atoms (`steps_json`); a graph answers `used_by` (every HardwareSolution whose cgraph it
is); isotopes name their parent atom and binding; variants name their job and purposes. Nothing joins them, and nothing answers the
question in his sentence: *I am applying Purpose P (or a Purpose like it) on board B — what already serves it, how well proven, and
what would have to change?*

**The index (`cmod.custom.reuse_index`, derived on request, cached per run — never stored as truth):** one directed graph over rows
`Mission → Purpose → Task → C atom → C isotope → Firmware Solution / Hardware Binding → Hardware Solution`, with the edges that exist
today read from their rows and two edges made explicit: **Purpose → job** (the job each Purpose's needs ask for: `pin_profiles` kinds →
`atom-jobs`) and **atom → job** (iso-0 already lists atoms per job). Every row answers two doors:

- `GET /api/reuse/{class}/{name}/uses`   — what it is built from (downwards), each hop with its proof step
- `GET /api/reuse/{class}/{name}/used-by` — everything built on it (upwards): tasks, plans, Purposes, Missions, Solutions, boards it is
  proven on, and the bench builds (layout configs) that wire it

and the search his sentence asks for:

- `GET /api/reuse/find?purpose=P[&board=B][&like=1]` — existing Tasks / atoms / isotopes / Firmware Solutions that serve P (or, with
  `like`, a Purpose with the same jobs and participant roles — the similarity is the job set and the criteria classes, stated), ranked
  by proof step on B > proof on any board > resolver-valid > exists; each with *what must change* for B (the isotope substitutions that
  would differ, the pins the overlap table frees or blocks, the tier rt-0 says). That is "re-use or expand on", with the expansion named.

The Mission run's **Inventory** step (§3) uses the same index: Mission and Purpose are the search keys; existing Solutions are the
first candidates before anything is searched from parts. On the pages: a **Used by / Uses** tab on every atom, isotope, task, Purpose,
Mission and Solution object page (one generic configured table per direction, the object's own page tabs — the per-object display rule);
`pol reuse find --purpose P --board B`.

## 9. Define everything by hand too: authored atoms, declared inputs, derived isotopes (his message 5, second part)

His words: "We need to be capable of defining all of these things by hand as well though. I should be able to write a new Catom in the
browser as well, and then define which variables recieve inputs from no-code, and Cisotopes become derived from each variation we find
in the code that is valid."

Today atoms exist only by parsing a C project (`cmod.custom.atoms.parse_file`, pycparser); their text lives in the project files; an
isotope is derived per atom × HardwareBinding by `code_interface.render`, which already classifies the identifiers it substitutes into
**kinds** — pin macros (`_pin_macro_identifier`), knobs (`_knob_identifier`, `_KNOB_FACTS`: F_CPU, USART_U2X …), registers
(`_register_identifier`) — each with its datasheet fact; a foundational isotope can be authored at a runtime level. The hand route:

1. **Authored atom.** `CFunctionAtom` gains `source` (the function text; '' for parsed atoms, whose text stays in the files),
   `provenance` (parsed | authored) and `project` = an **authored project** per person/workspace (so the manifest, measure and build
   steps treat it like any project). Door `POST /api/cmod/atoms` {name, source, kind, notes}; the C canvas page gets an **editor panel**
   (the existing `code-block` column format grows an edit mode: monospace, theme tokens, no library) — write the function in the browser.
2. **Validity = the same pipeline every parsed atom passes:** parse (pycparser) → targets (`targets.py`: declared pin macros, registers →
   peripheral, struct fields) → purity / ISR-safety → compile on the C engine (avr-gcc on isle-core) → measure (text / stack bytes). A
   failure is a named finding on the atom, never a silent reject; the atom is `valid` only when every step passes.
3. **Declared inputs** (his "which variables receive inputs from no-code"): a `CAtomInput` row per identifier the person marks (or the
   renderer finds): {atom, identifier, **kind**: register | pin-macro | knob (protocol / feature decision) | rate (baud, clock divider,
   period) | struct-field | constant, source: declared | found, datasheet_kind, default, allowed values or range, plain words}. The kinds
   are the renderer's kinds plus `rate` and `struct-field` split out; a declared input the renderer cannot find in the source is a
   finding. **This same row set is what the C-code colouring (his 2026-10-23 ask: "this is a register", "a decision on the kind of
   protocol", "a baud rate") renders from** — one classification, two uses: colour by kind in the code panel with a legend, and the
   no-code ports an atom exposes. No hand-typed word lists.
4. **Isotopes derived from every valid variation.** For an atom with declared inputs, the variations are the cross product the inputs
   allow — bindings (board × SoC × programming) for registers and pin macros, the knob values, the rates the Purpose criteria admit —
   filtered to those whose substitutions ALL resolve to a cited fact and whose compile passes: each is a `CIsotope` (provenance
   derived, `substitutions_json` as today). An invalid variation is listed with its reason (unresolved identifier, compile error,
   rule violated), not dropped. Where a variation changes the job's route (interrupt vs poll) it is a **variant** (iso-0) too, and is
   registered as one; the variants page and the reuse index see it the same hour it is written.
5. **Hand-made Tasks, Purposes, Missions** are already authored rows (no-code write-back); the gap is only the atom and its inputs. A
   person composing a Task from an authored atom declares the Purposes it serves, and §8's index links it at once.

### 9.1 Slices

| # | slice | builds | proves |
|---|---|---|---|
| a | **reu-0** the reuse index | `reuse_index` + the three doors + the Used by / Uses tabs + `pol reuse find` | `find?purpose=ensure-polari-observes-hardware-state&board=esp32c3-devkitm-1` names sense_poll's isotope on the C3, proven-on-twin, "what must change: the pin macro, the register set; the tier"; every object page shows both directions |
| b | **aut-0** authored atoms + declared inputs | atom `source` / `provenance` / authored project, the POST door, the browser editor, `CAtomInput` rows (declared + found), the validity pipeline with findings | an atom written in Chrome on the test node parses, compiles on isle-core, shows its inputs by kind, and a deliberate bad one shows a named finding |
| c | **aut-1** isotopes from variations + code colouring | the variation cross product → isotopes with reasons for the invalid ones; the code panel coloured by `CAtomInput.kind` with a legend (theme tokens per kind, `-text` pairs) | hal_usart_init shows registers, the USART_U2X decision and UBRR0_VALUE in three colours from the rows; a new atom's isotopes appear on the isotopes page and in the reuse index |

Order: reu-0 can run beside mis-1a; aut-0 → aut-1 after. The colouring half of aut-1 is small and may ship first on its own branch
(it reads the existing renderer's identifier kinds until `CAtomInput` lands).

**✅ aut-1 colour half BUILT 2026-10-24 (angular `dev-aut-1-colour` 4cbebf4 → dev):** `code-block` gains `identifiers` + `showLegend`; a
pure `segmentLine` (whole-word, longest name wins, only names the `/code` door returned — no frontend word list) renders spans per kind;
`legendChips` in the fixed order pin-macro · register · knob · global · library with counts; tokens `--code-kind-<kind>` + `-text` in
`_variables.css` and `_theme-dark.css` (contrast 7–12:1); the identifiers table's name cell uses the same classes. Karma 5/5, tsc, `ng build`.
Not yet: Chrome on the test node; `c-isotope-section` stays uncoloured (its row has `datasheet_kind` only, no `/code` call — wire via the
parent atom's door when aut-0 lands); the plain-name toggle (§10.1) waits for `CAtomInput`.

### 9.2 Decisions (his; my recommendation first)

- **D-mis-10** the reuse index is derived per request, never stored (recommended; the rows are the truth) — or materialised rows refreshed on write.
- **D-mis-11** "a Purpose like it" = same job set and criteria classes (recommended) — or a person-named family only.
- **D-mis-12** authored atoms live in a per-workspace authored project that the manifest treats as a project (recommended) — or inside an existing project.
- **D-mis-13** the input kinds: register · pin-macro · knob · rate · struct-field · constant (recommended) — or the renderer's three only.
- **D-mis-14** invalid variations are listed with reasons (recommended) — or only valid isotopes shown.

## 10. C atoms with contracts, plain names, and composition (his message 6)

His words (2026-10-24, sixth message): "those variable names are a bit too abstract for me because I am not an experienced engineer. Maybe
make it possible to make two variants of how variables appears, one should be self-descriptive and verbose 'UartCapablePinconfigRegister',
which then the Catom has logic in it's no-code for example to ensure that any pins that come in as input for that purpose, actually have
Uart capability. So Catoms perhaps have logic pertaining to 'what is allowed as inputs into my Catom' and then we use the purpose to bring
together the Catom logic with the Purpose logic. We may have the mission try finding tasks using different Catoms, by testing different
inputs against the Catoms, and the Catom no-code should be able to define what kinds of pins and registers are able to be used for the
Catom to achieve the purpose of the Catom. The purpose then need to have 'something' defined to where it knows what combination of Catoms
are needed in general, and must have Catoms that can combine other Catoms into tasks. So Catoms must be capable of accepting other Catoms
as inputs as well."

Four things, each with a home:

### 10.1 Two names for every input: the C name and the plain name

Every `CAtomInput` (§9.3) carries `c_name` (`UBRR0H`, `USART_U2X`, `UBRR0_VALUE`) and a **plain name**, DERIVED from cited rows — never
typed: kind + the peripheral or signal family + the register class (rp-0) or the knob's fact + the role. `UBRR0H` → *UartBaudRateRegisterHigh*
(register, USART0, peripheral-operation class, the datasheet's own words "USART Baud Rate Register"); `UCSR0C` → *UartFrameFormatRegister*;
`DDRD` with `PD1` → *UartCapablePinConfigRegister* (pin-configuration class, the pin's family from its PinFunction rows); `USART_U2X` →
*UartDoubleSpeedDecision* (knob); `UBRR0_VALUE` → *UartBaudRateDivider* (rate, derived from F_CPU and the baud). A person's better word is
a DerivedOverride (who / when / why) and the derived one stays visible beside it. The datasheet sentence is the hover on both.

The code panel shows either view — **C names** or **plain names** — by one toggle beside the kind legend (§9.3's colouring), kept per
viewer; the plain view substitutes identifiers in the DISPLAY only (the source is never rewritten) and keeps each token's kind colour.
Isotope substitutions, the reuse index and the no-code ports all show the plain name first, the C name in small type.

### 10.2 Input contracts: what is allowed into my atom

A `CAtomInput` gains a **contract**: the predicate a candidate value must pass, drawn from rows that exist and stated in plain words.
Per kind: **pin-macro** → the pin must carry a function of family F (PinFunction rows), be free at the ladder's rung (hsp-0,
`availability`), pass the overlap table against the atom's other pins (pp-1), and meet the drive or signal class the role needs
(`target_compat.compatible(kind, pin)`); **register** → the register must be of class C for peripheral P (rp-0 classes), its fields
cited; **knob** → one of the allowed values, each with its fact; **rate** → inside the range the chip's clock and the Purpose's
criteria admit; **struct-field** → the field's type and the writer/reader rule (struct controls hardware); **constant** → a range.
The contract is no-code on the atom's own drawing: one `Allows` state per input, its predicate rows editable (which families, which
class, which range), evaluated by the engine with the same functions the solver already uses — so "testing different inputs against the
Catoms" (his words) is the engine walking each input's candidates through its contract and keeping the passes, each with the reason. A
contract the atom's parsed code contradicts (the code writes a register the contract does not name) is a finding.

### 10.3 The Purpose's recipe: what combination of atoms, in general

The "something" exists in embryo: a Purpose names a CGraph whose nodes are atoms and whose edges are the data and call flow (fgm-1), and
fgm-3 derives Tasks from it. Made explicit as the Purpose's **recipe**: an ordered set of **job slots** (`read the button`, `drive the
light`, `send the report`, `sense the line`), each slot naming the JOB (iso-0's `atom-jobs`) and the role it serves, not an atom. The
recipe is hardware-agnostic (WHY ladder); the Mission's Combine step fills each slot by trying every atom and variant registered for
that job whose contracts pass on the candidate board — that is the search "finding tasks using different Catoms". A recipe slot may be
marked `any-of` (the route is the solver's) or `this-one` (a person pinned the atom). The recipe is drawn on the Purpose's own canvas
as its `Done by` column (today's `PurposeTasksState`), one slot per state, each with its job and the atoms that qualify.

### 10.4 Composite atoms: atoms that take atoms

A `CFunctionAtom` of kind **composite** takes other atoms as inputs (a `CAtomInput` of kind **atom**, with a contract on the job and the
signature the slot needs) and emits ONE Task body: the ordered calls, the trigger (boot / edge / period / command / message), the shared
struct bindings and the ISR-safety rule across its members. Today this body is generated by the glue (`cmod.custom.glue`) and recorded as
a `TaskDefinition` with `steps_json`; a composite atom is that generator made a first-class, authorable row: its no-code drawing lists its
slots, and the code it emits is plain C the same as every other atom (the C modularization rule — generated plain C, nothing hidden).
Seeded composites: `loop-task` (period, calls in order), `isr-task` (edge, one call, ISR-safe members only), `command-task` (message,
dispatch), `boot-task` (boot, init calls). A Task is therefore *a composite atom applied to concrete atoms on one processor*; the
Purpose's recipe says which composites and which jobs; the Mission's Combine step fills them; the Delegate step hands each processor's
Tasks to its child Firmware Mission. Composites nest (a composite slot may take a composite), with the processor rule unchanged (one
Task never spans two chips).

### 10.5 Slices

| # | slice | builds | proves |
|---|---|---|---|
| a | **con-0** plain names + the toggle | plain-name derivation from rp-0 classes, PinFunction families, knob facts; DerivedOverride; the C / plain toggle in the code panel beside the kind legend; plain names on isotopes, ports, the reuse index | `hal_usart_init` reads in plain names with the same colours; hovering gives the datasheet sentence; an override shows both |
| b | **con-1** input contracts | `CAtomInput.contract_json` + the `Allows` state on the atom drawing + the engine's candidate test (reuses availability, overlap, compatible, rp-0) + findings when the code contradicts the contract | on the UNO, `hal_usart_init`'s pin inputs admit only D0/D1 (the only USART0 pins), with the reason; a contract naming SPI for them is refused by name |
| c | **con-2** recipes | the Purpose recipe (job slots, any-of / this-one) drawn as the `Done by` column; Combine fills slots by contract passes | the light Purposes' recipes fill with sense_poll OR the INT1 route for the sense slot, both listed with reasons, the chosen one by the aim |
| d | **con-3** composite atoms | kind composite, atom-typed inputs, the four seeded composites, the glue emitting from them, Tasks recorded as composite applications | the UNO light Task Plan regenerates from composites byte-identical to today's generated C (the reproducibility check) |

Order: con-0 may ship with aut-1 (same code panel); con-1 → con-2 → con-3 follow aut-0 (contracts live on `CAtomInput`), and con-2/3
gate mis-1b's Combine step at full strength (mis-1b ships first with the existing sol-0 routes, then reads recipes when con-2 lands).

### 10.6 Decisions (his; my recommendation first)

- **D-mis-15** plain names DERIVED from the cited rows with DerivedOverride, both names always kept (recommended) — or person-typed aliases.
- **D-mis-16** the toggle is per viewer, default **plain** (recommended: his words, the average person) — or default C names.
- **D-mis-17** contracts reuse the solver's predicates and are drawn as `Allows` states on the atom (recommended) — or a table only.
- **D-mis-18** the recipe is job slots on the Purpose's `Done by` column, any-of by default (recommended) — or pinned atoms by default.
- **D-mis-19** Tasks become applications of composite atoms, with the four seeded composites (recommended) — or keep Tasks as a separate authored row beside atoms.

## 11. The ESP32-C3 DevKitM-1 as the second board context (his message 7)

His words (2026-10-24, seventh message): "we need to try and get the ESP32-C3 dev board fully flushed out then, that way we can use two
boards as a way to test that we are capable of having Catoms with purposes and missions that work in different board contexts."

The two-board proof this arc needs: the SAME Purposes and the SAME Mission run on the UNO and on the C3, filling the recipes' slots
with the SAME atoms where the contracts pass and with different isotopes where the chips differ, both proven on their twins, the
differences named by the reuse index. The C3 is far along; what stops that proof today is listed honestly (read 2026-10-24).

### 11.1 What the C3 has (cited or ingested; nothing retyped)

| piece | state | where |
|---|---|---|
| board object: header pins from Zephyr's `esp32c3_devkitm` devicetree (verbatim upstream, sha256) + the datasheet's IO MUX / analog functions + the DevKitM-1 guide's J1/J3 header tables, RGB LED on GPIO8, boot button GPIO9 | ✅ | `board_c3`, `ingest_zephyr`, `esp32c3_evidence` |
| QFN32 package legs (datasheet Fig 2-1, Table 2-1); the FH4X variant named as undetermined | ✅ | `packages_esp32c3` |
| pin functions: GPIO-matrix signals (TRM Table 5.11-1), peripheral pin priorities (Table 2-7), IO MUX (Table 2-4), analog (Table 2-6) → 2 640 PinFunction rows DERIVED on read | ✅ | `esp32c3_tables`, `soc_functions`, `c3_retire` |
| lifecycle constraints: strapping GPIO2/8/9, UART0 download link, USB pads 18/19, JTAG 4–7, in-package flash 12–17, VDD_SPI | ✅ | `lifecycle_c3` |
| build: ESP-IDF v5.5.5 through the `idf-build` engine; sizes measured; flash by esptool | ✅ | `build_c3`, `flash_c3`, `board_engines` |
| twin: Espressif QEMU `-machine esp32c3` booting the SAME merged image; UART0 on a pty | ✅ (GPIO = a register stub → the pin HAL is a RAM shim) | `light_c3_twin`, `light_c3_run` |
| the light's four Purposes proven on that twin (sample S5, twin-only, said so); six C3 FirmwareVariants; runtime tiers | ✅ | `light_c3_twin`, `variants_c3`, `approach_profile_tiers` |
| price offers for the DevKitM-1 (Adafruit, LCSC, marketplaces) | ✅ | `price_offers/part_price_offers.json` |

### 11.2 What is missing for the two-board proof (each a slice below)

| gap | why it blocks the proof | source to cite |
|---|---|---|
| **G1 no register map**: zero Register / RegisterField / MemoryRegion rows for the C3 (`hardware_chain_c3._NO_REG` says so) | rp-0 classes → plain names (§10.1), register contracts (§10.2), isotope substitutions of register identifiers all stop at the peripheral | TRM v1.4 register summaries: GPIO, IO MUX, GPIO matrix, UART0/1, interrupt matrix, system / clock, RTC; the datasheet's memory map (ROM, SRAM 400 KB, RTC SRAM, in-package flash) |
| **G2 no C3 atoms**: the C3 firmware is a separate ESP-IDF template (`custom/firmware/esp32c3`), not parsed into `CFunctionAtom` rows (`projects.TEMPLATES` names only `uno`); one foundational isotope exists (`polari_telemetry_start@esp32c3-freertos`) | there is nothing for the recipe slots to fill on the C3; "the same atom in two contexts" cannot be shown | the template's own C (parse it with the same `atoms.parse_file`); the UNO atoms' C3 isotopes by substitution where the job is the same (GPIO write, UART send) and foundational isotopes where FreeRTOS differs (tasks, queues) |
| **G3 no HardwareBinding** for a C3 FirmwareSolution on `esp32-c3-devkitm-1` | the solver, the pin view's stages, the claims and the proof ladder all hang off a binding | derived from the template's pin assignment (LED GPIO0, sense GPIO1, button GPIO3, trace UART1 TX GPIO4, frame UART0 GPIO20/21) |
| **G4 layout geometry**: `layout_sources` and the layout engine know only the UNO; the DevKitM-1 (two 15-pin 0.1" headers that straddle a breadboard trench) has no footprint | Combine cannot place a C3 on the breadboards; the walkthrough cannot draw it | the DevKitM-1 guide's header block and dimensions figure; the 0.1" pitch from the header part |
| **G5 pin view surfaces**: `pin_view_model` is per board, but the C3's die / QFN32 / module / board surfaces and `BENCH_LAYOUT_DEFAULT` exist only for the UNO; the MINI-1 module's 53 pads are not rows | the C3 cannot be shown the way the UNO is | `packages_esp32c3` (legs), MINI-1 datasheet Table 3-1 (pads → chip pins), the J1/J3 facts |
| **G6 twin fidelity**: QEMU's C3 GPIO is a stub, so pin writes are observed through the RAM shim, not the register | atoms whose logic IS the register write (the contracts of §10.2) are proven only by the shim's word | to investigate, not assumed: a GPIO model in the Espressif QEMU fork, or Renode's ESP32-C3 support, or accept twin = shim and let hardware carry the pin-level proof |
| **G7 interactive twin session** (`twin_sessions`) runs simavr only | the sim bench (bench mode of the layout view) cannot bind a C3 session | a `qemu:esp32c3` session kind on the same worker protocol |
| **G8 no C3 on the bench**; not in the kit register | nothing can reach proven-on-hardware; the install gate has no board to install to | one DevKitM-1 (offers on file, USD 9–24); flashing over USB is the desktop half — Codex's side (CX-001) |
| **G9 overlap table** (pp-1) was built "AVR first"; whether the C3 family has rules (GPIO matrix: any signal on any pin, exclusive only for strapping / flash / USB pads / IO-MUX-direct) is unverified | co-location on the C3 may answer undetermined everywhere | TRM §5 (GPIO matrix, IO MUX), datasheet Table 2-7 |
| **G10 pages fixed to the UNO**: `pin_view_page.BOARD`, the solve / scores / task-plan pages name `uno-light-mission` | the C3 has no page a person reaches | parametrise by `?board=` / `?mission=`, the way the Mission page of §3 already is |

### 11.3 Slices

| # | slice | builds | proves |
|---|---|---|---|
| a | **c3-1** register map | Register / RegisterField / MemoryRegion rows for GPIO, IO MUX, GPIO matrix, UART0/1, interrupt matrix, system/clock, RTC — transcribed by script from the TRM with page cites (the `esp32c3_tables` method); rp-0 classes derived; the memory map; `pol board registers esp32c3` | the C3 hardware chain no longer stops at the peripheral; `hal` register identifiers on the C3 resolve to cited facts |
| b | **c3-2** atoms, isotopes, binding | parse the C3 template into atoms (`projects.TEMPLATES['esp32c3']`); jobs mapped; C3 isotopes of the shared UNO atoms by substitution, foundational ones where FreeRTOS differs; the `esp32c3-light@esp32-c3-devkitm-1` HardwareBinding with claims | the reuse index answers `find?purpose=ensure-polari-can-control-light&board=esp32-c3-devkitm-1` with the C3 isotopes and what changed |
| c | **c3-3** layout + pin view | the DevKitM-1 footprint straddling the trench in the layout engine; the C3 surfaces (die, QFN32, MINI-1 module as a `module` level, board) in the pin view; `BENCH_LAYOUT_DEFAULT` for the C3 light | Chrome: `/display/pin-view?board=esp32-c3-devkitm-1` and the layout of the C3 light on a half breadboard |
| d | **c3-4** overlap + pages | the C3 family's overlap rules (matrix vs IO-MUX-direct, strapping, flash, USB) cited; pin view / solve / scores / task-plan pages take `?board=` / `?mission=` | pp-1 co-location on the C3 answers with reasons, not undetermined |
| e | **c3-5** twin session + fidelity | `qemu:esp32c3` twin sessions on the worker; the G6 investigation written up with a decision (D-mis-21) | the layout view's bench mode drives the C3 twin |
| f | **c3-6** the real board | the DevKitM-1 in the kit register (on hand), flash + bench gate over USB from the desktop side (Codex, CX-001), proven-on-hardware for the light Purposes | the sample's S5 stops being twin-only |
| g | **two-board proof** (closes the arc) | the light Mission run (§3) on both boards from one drawing; recipes filled on each; the Verdict names the shared atoms, the differing isotopes and both proof steps | the sentence his message asks for, on the test node in Chrome |

c3-1 and c3-2 first (they unblock §9–§10 on the C3); c3-3/c3-4 beside mis-1b; c3-5 and c3-6 as his bench allows.

### 11.4 Twin fidelity investigated (2026-10-24, his "yes please investigate") — G6 / D-mis-21

**Espressif QEMU fork (what the engine image runs: `prf-esp-engines:noble`, QEMU 9.2.2 `esp_develop_9.2.2_20260417`).** Measured in
the image and read in the sources, branch `esp-develop`:
- `info qtree`: the machine has `esp32c3.gpio` with ONE `gpio-out "sysbus-irq"` and NO pin lines (no `gpio-in`, no per-pin `gpio-out`);
  `-device esp32c3.gpio,help` shows only `strap_mode` and the irq. `info mtree`: `0x60004000–0x60004fff` is `esp32.gpio`; the IO MUX
  (`0x60009000`) and the rest of the peripheral space fall in a catch-all `esp32c3.iomem` region (writes stored as plain memory, no
  behaviour).
- `hw/gpio/esp32c3_gpio.c` is ≈49 lines: a subtype of `TYPE_ESP32_GPIO` that sets the default strap mode; no registers of its own.
- `hw/gpio/esp32_gpio.c` (the parent) is ≈110 lines: the read handler decodes `A_GPIO_STRAP` → `strap_mode`, every other offset reads 0;
  the write handler is EMPTY; no `qdev_init_gpio_in/out`; the irq is initialised and never raised. (The ops struct is even named
  `uart_ops`.) This confirms the 2026-10-19 measurement: GPIO_OUT stays 0, GPIO_IN never moves.
- Espressif's own QEMU docs list only the strap register for GPIO and name the UART, timer-group watchdogs and flash as emulated; the RTC
  watchdog is not. No external-signal mechanism is documented.
- Licence: QEMU is GPL-2.0; the fork is run as a separate engine process in a container (a tool, not linked) — the same posture as today.

**Renode.** Official Renode (MIT) has an RV32IMC core that would run the C3's code, but NO ESP32-C3 platform: the changelog has
"translation support for Espressif ESP32 chips" (1.14.0, 2023-08-08: the Xtensa core only, per a maintainer), an "ESP32 UART" model
(1.16.0, 2025-08-02) and an experimental Xtensa assembler (1.16.1, 2026-02-16). Nothing for the C3.
- Third-party `mithro/renode-espemu` (created 2026-04-04, last push 2026-09-05, 2 stars): `platforms/cpus/esp32c3.repl`, 16 C# peripherals
  + 23 Python placeholders, "full FreeRTOS boot through Hello world", HW-vs-Renode register match 49/81 (60 %). Its `ESP32C3_GPIO.cs`
  (≈410 lines) DOES define OUT / OUT_W1TS / OUT_W1TC / ENABLE / IN / STATUS / PINn / FUNCn_OUT_SEL / FUNCn_IN_SEL / STRAP — but IN is a
  loopback of OUT ("returns output data (loopback, independent of enable)"), it implements neither `IGPIOReceiver` nor
  `INumberedGPIOOutput` (no pin lines a test can drive or read), has no IRQ output and never evaluates INT_TYPE / INT_ENA.
- **No licence file anywhere in that repository and no licence header in the files** (GitHub API `license: null`). Under the project's
  licence gate that is a HARD BLOCKER: all rights reserved by default, so it cannot be vendored, forked or run as an engine.

**Verdict and recommendation (D-mis-21 → recommend route 2):**
1. *Adopt Renode via renode-espemu* — refused: unlicensed; and even licensed it has no pin lines or interrupts, so it would need the same
   work as route 2 on a 60 %-matched platform.
2. *Write the GPIO + IO MUX model in the Espressif fork ourselves* (`dausume/qemu`, the fork-the-upstream rule) — recommended. Scope,
   bounded and cited from the TRM (the same c3-1 transcription): the GPIO block's OUT / W1TS / W1TC / ENABLE / IN / STATUS / STATUS_W1TC /
   PINn (INT_TYPE, INT_ENA) / FUNCn_OUT_SEL / FUNCn_IN_SEL, the IO MUX GPIOn registers (MCU_SEL, FUN_IE, pull-ups) as a second device, 22
   `qdev_init_gpio_out` pin lines (output level after ENABLE and OUT_SEL) and 22 `qdev_init_gpio_in` lines (level into IN through IN_SEL,
   edge/level interrupts raised through the interrupt matrix which the machine already wires, `gpio-in "" 62`). Driving the lines from
   outside: a small QMP command pair (`set-gpio-in`, `query-gpio-out`) on the machine, read by the `c3-run` engine the way simavr's pin
   callbacks are today. Estimate: one bounded slice (c3-5b), with a selftest that boots the UNMODIFIED chip-HAL build (PIN_SHIM=0) and
   proves the four Purposes by pin level — the point of the exercise. Upstreaming the patch to Espressif is optional and welcome.
3. *Accept the shim* — stays as the fallback and remains labelled "twin (shim)" on the proof ladder; route 2 adds a "twin (pins)" rung.

### 11.5 Decisions (his; my recommendation first)

- **D-mis-20** buy one ESP32-C3-DevKitM-1 now (recommended; USD 9–24 on the offers file; flashing is Codex's USB half) — or stay twin-only this arc.
- **D-mis-21** ✅ RULED 2026-10-24 (his words: "that sounds fine, we will make our own QEMU defined digital twin of C3 as it's own project that is
  also it's own module"): route 2 — our own GPIO + IO MUX model with pin lines and a QMP door in `dausume/qemu`, as its OWN PROJECT and its
  OWN MODULE (§12). renode-espemu refused (unlicensed, pin-less); the shim stays the labelled fallback rung.
- **D-mis-22** register map scope: the light's peripherals first (GPIO, IO MUX, matrix, UART, interrupts, system), the rest on demand (recommended) — or the whole TRM.
- **D-mis-23** the MINI-1 module as its own surface level between package and board (recommended; it is what the legs reach) — or fold its pads into the board's notes as today.

## 12. The C3 digital twin as its own project and module (his ruling 2026-10-24)

His words: "we will make our own QEMU defined digital twin of C3 as it's own project that is also it's own module."

**Module `c3twin`** (framework `modules/c3twin/`, standalone repo `polari-module-c3twin`, developed through the `pol project` loop — the
module-projects rule). It OWNS everything about simulating the ESP32-C3 and nothing about the C3's rows (those stay in `board`):

| piece | what | where |
|---|---|---|
| the emulator | our fork `dausume/qemu`, branch `polari-c3twin`, pinned by commit sha; patches: `hw/gpio/esp32c3_gpio.c` (real register set: OUT / W1TS / W1TC / ENABLE / IN / STATUS / PINn INT_TYPE+INT_ENA / FUNCn_OUT_SEL / FUNCn_IN_SEL / STRAP), a new `hw/misc/esp32c3_iomux.c` (GPIOn MCU_SEL, FUN_IE, pull-ups, drive), 22 `gpio-out` + 22 `gpio-in` pin lines on the machine, interrupts into the existing intmatrix, QMP `set-gpio-in` / `query-gpio-out` / `query-gpio-config`; every register cited to the TRM page in the source comment (the c3-1 transcription is the single source) | `c3twin/upstream/SOURCE.json` (sha256 of the patch series; the fork is NOT vendored) |
| the engine | image `prf-c3twin` (the fork built once; ESP-IDF stays in `prf-esp-engines`) with its measured cost row (resource-cost rule); the `c3-run` engine moves here and grows the pin door | `c3twin/custom/engine.py`, `c3twin/custom/cost.json` |
| the session | twin session kind `qemu:esp32c3` on the existing `twin_sessions` worker protocol: inject (press, level, analog later), watch pins, trace | `c3twin/custom/session.py` |
| the proofs | the four light Purposes proven BY PIN LEVEL on the unmodified chip-HAL build (`PIN_SHIM=0`): press GPIO3 → LED GPIO0 flips → sense GPIO1 sees it; the proof-ladder rung `proven-on-twin (pins)` above `proven-on-twin (shim)` | `c3twin/c3twin_selftest.py`, `cmod.custom.capabilities.PROOF_ORDER` grows one rung |
| the module record | `polari-app.json`, registrar row, `pol twin c3 build \| run \| session`, initialData none (nothing seeded is a number) | `c3twin/` |

Boundaries: `board` keeps the rows, the build (`build_c3`, idf-build) and the flash (`flash_c3`); `c3twin` keeps the emulator, its engine
image, the pin door and the sessions; `light_c3_twin` / `light_c3_run` move into `c3twin` (they are the twin). Licence: QEMU GPL-2.0, run
as a separate engine process (a tool), the posture the gate already accepts for simavr and the esp engines. Runs on isle-core's engines.

**Revisited the same day under his "prefer existing RISC-V simulations" rule (D-mis-21b):** Espressif's own `esp-emulator` (Apache-2.0,
Rust, maintained by Espressif, Beta) already models the C3's GPIO, LEDC, MCPWM, PCNT, timers and interrupt controller — and the C6 and P4
with the same binary — but has no host-driven pin door (its open feature request #5 asks for exactly `--gpio-dev ENDPOINT`: output-change
events out, input edges in). Recommended re-base: `c3twin` wraps **esp-emulator** as its engine (`esp-emu`, QEMU-compatible flags: `--efuse`,
`--uart-tcp`, `--strap-mode`, `--gdb`, `--control-tcp`), and our contribution is the **pin bridge** upstream (a bounded Rust change on an
existing GPIO model, offered as the answer to #5; carried as a patch in `dausume/esp-emulator` until merged) instead of a GPIO model from
scratch in QEMU. One engine then twins three of the eight sample chips. The QEMU-fork GPIO model (route 2 above) becomes the fallback if
the bridge is refused upstream or the emulator's GPIO proves register-incomplete when measured (first task of c3t-0: run the chip-HAL build
with PIN_SHIM=0 under esp-emu and read GPIO_OUT / GPIO_IN back — the measurement that failed on QEMU). The module name stays `c3twin`; its
engine row says which emulator and version.

Slices: **c3t-0** fork + GPIO/IO MUX patch + pin lines + QMP, built into `prf-c3twin`, `info qtree` shows 22+22 pin lines (the measurement
that fails today) · **c3t-1** module skeleton + `c3-run` moved + the session kind + CLI · **c3t-2** the pin-level proofs of the four Purposes
+ the new ladder rung + the smp sample's S5 re-labelled "twin (pins)" · **c3t-3** standalone repo `polari-module-c3twin` through `pol project`.

## 13. Minimal simulation of cheap, simple hardware (his ruling 2026-10-24)

His words: "We need a minimal simulation of cheap and simple ways to make hardware to be able to move forward."

The minimum this arc simulates — enough for a Mission run to find, place, prove and compare builds on two boards; nothing more:

| in (minimal) | with | out (later kinds / arcs) |
|---|---|---|
| two dev boards: Arduino UNO R3 (simavr, pins real) and ESP32-C3 DevKitM-1 (`c3twin`, pins real after c3t-0) | twins boot the SAME firmware images the bench would | any third board; the UNO's 16U2; Zephyr boards |
| breadboards: half and full, by count on hand | the layout engine's geometry (lay-2/3) and the walkthrough (bb) | protoboard, PCB (own Mission kinds) |
| the starter-kit parts already drawn: LED, resistor, pushbutton, potentiometer, TMP36, transistor, jumper wire | 2-D sprites, the electrical check (drive / signal classes, never a number invented), the bench overlays | sensors not in the kit; displays; radios |
| digital pins, one analog input (the pot / TMP36 → ADC), UART frames | the pin HAL, the twin's ADC injection, the reference codec | PWM waveforms, I²C/SPI devices, timing-accurate buses |
| proof on the twin by pin level; hardware proof through the bench gate when a board is on hand | the proof ladder | thermal / mechanical / multi-scale sims (Device level, §3 of the terminology) |

What this minimum needs that is missing today: the C3 twin's pins (§12), the C3 breadboard footprint (c3-3), the C3 register map (c3-1),
and a C3 on the bench (D-mis-20). Everything else in the table exists. The Mission run's Inventory step (§3) reads exactly this set.

### 13.1 The RISC-V sample set: two chips per software level, preferring chips that ALREADY have an emulator (his rulings 2026-10-24)

His words: "we likely do not need more specifications if we have all levels covered. Maybe 2 risc-v chips per level as samples (bare,
FreeRTOS, Zephyr, Ubuntu). I think outside of that in theory we should be able to use peripherals or increasing our chips on boards and PCBs
to solve most issues." and then: "we want to minimize how much we need to make new qemu simulations from scratch as well, so preferring
solutions where those already exist but are RISCV." → the Inventory's chip universe is a FIXED SAMPLE of eight slots; capability beyond it
comes from peripherals and from more chips per board / PCB (the Electronic-system level, terminology §3), never from a longer chip list;
and a chip earns a slot first by having an emulator someone else maintains.

**What exists (surveyed 2026-10-24, primary sources):**
- Upstream QEMU RISC-V machines (documented): `virt`, `microchip-icicle-kit` (PolarFire SoC: E51 + 4×U54, FPGA), `milkv-duo` (Sophgo CV1800B,
  C906 cores, UART + SD, no GPIO), `k230` (Kendryte K230, one C908 core, UARTs, WDTs, no SD yet), `sifive_u`, `shakti_c`, `xiangshan-kunminghu`,
  `riscv-server-ref`, `tt-atlantis`, `amd-microblaze-v-generic`.
- Renode (MIT) RISC-V platforms shipped: sifive-fe310 / fu540 / fu740, polarfire-soc, kendryte_k210, opentitan-earlgrey, murax_vexriscv, the
  LiteX family (vexriscv, ibex, picorv32, minerva — Zephyr / Linux / Tock variants), starfive-jh7100, core-v-mcu, miv_rv32, riscv_virt.
- **Espressif `esp-emulator`** (Apache-2.0, Rust, Espressif's own, Beta, 465 stars, last push 2026-10-22): ESP32-C3, C5, C6, H2, P4 (RISC-V) and
  S3; models GPIO, LEDC, MCPWM, PCNT, RMT, I2C, SPI, timers, interrupt controllers, eFuse, flash encryption, Wi-Fi; QEMU-compatible flags
  (`--efuse`, `--uart-tcp`, `--strap-mode`, `--gdb`, `--control-tcp` in QMP's role: reset / flash / ping / efuse-load). NO external pin door yet:
  a host-driven GPIO bridge (`--gpio-dev ENDPOINT`: output-change events out, input edges in) is open feature request #5.
- Espressif's QEMU fork: `esp32c3` AND `esp32c6` machines (GPIO a stub on both, §11.4).
- None: RP2350 (project-specific Renode platforms only), CH32V003/V307, GD32VF103 (community forks only), SpacemiT K1 (QEMU `virt` approximates).
- Retired from consideration: SiFive HiFive1 Rev B (FE310; QEMU + Renode, but DISCONTINUED by SiFive and SparkFun).

| level | sample 1 | sample 2 | emulator (existing) | USB route |
|---|---|---|---|---|
| bare C | **ESP32-C3** DevKitM-1 (in hand soon, D-mis-20): plain-C chip HAL, no RTOS | **Kendryte K210** (Sipeed Maix Bit ≈$21; availability mixed — Seeed/DigiKey discontinued, DFRobot/Probots stock): RV64GC dual 400 MHz, standalone SDK | C3: esp-emulator + QEMU fork · K210: Renode `kendryte_k210` | USB-UART · USB-C |
| FreeRTOS | **ESP32-P4** DevKit: dual 400 MHz, MCPWM, Ethernet, USB HS | **PolarFire SoC E51** (the monitor core of the BeagleV-Fire, Microchip FreeRTOS demos) — the heterogeneous RTOS-beside-Linux case a machine controller needs | P4: esp-emulator · PolarFire: QEMU `microchip-icicle-kit` + Renode `polarfire-soc` | USB Serial-JTAG · USB |
| Zephyr | **ESP32-C6** DevKitC (≈$8): Zephyr upstream `esp32c6_devkitc` | **LiteX / VexRiscv** on an ECP5 board (OrangeCrab ≈$35, USB-C DFU): OPEN soft SoC, Zephyr upstream `litex_vexriscv` | C6: esp-emulator + QEMU fork · LiteX: Renode `litex_vexriscv_zephyr` | USB Serial-JTAG · DFU |
| Ubuntu | **BeagleV-Fire** (PolarFire SoC, 4×U54 + FPGA fabric): BeagleBoard Ubuntu 24.04 image (2025-07-21) and Debian 13 (2026-07-25) | **CanMV-K230** (≈$50; K230D-Zero ≈$30): Canaan SDK Debian and Ubuntu images (one review: Ubuntu's Ethernet flaky, Debian stable) | PolarFire: QEMU + Renode · K230: QEMU `k230` (one core, no SD yet) | USB (+ Ethernet) |

Seven distinct chips in eight slots (the PolarFire SoC fills two on purpose: its E51 + U54s is ONE chip running an RTOS beside Linux).
Noted beside the sample, not in it: **RP2350 / Pico 2** (the only retail open core with PIO step generation — no emulator; the exception
to take when PIO is needed, hardware-proven), **Milk-V Duo** (QEMU `milkv-duo`, ≈$5–10, Linux but not Ubuntu, no GPIO in the machine),
**SpacemiT K1** boards (Ubuntu hosts we may buy anyway; `virt` only), CH32V003 (the price floor; no emulator).
**The already-emulatable AVR boards stay (his words, same day: "we do want to keep our existing already emulatabale devices as well, the
arduinos are still very accessible and we want to keep using them"):** the RISC-V sample is ADDED to, not swapped for, the AVR set that
simavr already twins with real pins — **Arduino UNO R3** (ATmega328P, the core demo, every row cited), **Arduino Nano** (same chip, breadboard-
friendly DIP-30 footprint — the cheapest way to put a second ATmega on the same breadboard), **Arduino Mega 2560** (ATmega2560, 54 digital
pins + 16 analog, 4 UARTs — the "more pins" answer that needs no new chip), and the **ATtiny85 / ATtiny412-class** (simavr `attiny*` cores; the
smallest thing that can hold one Task) as the AVR price floor. Each is a kit-register row when on hand; the Mega and the ATtiny need their
datasheet transcription (legs, pin functions, lifecycle, register map — small: the 2560's register set is the 328P's pattern) before the
solver sees them. The twin engine for all four is the existing simavr worker — no new emulator.

Every chip still enters the rows the C3 way (datasheet / TRM cited, legs, pin functions, lifecycle, register map) before any solver sees it.

**✅ chp-0 BUILT 2026-10-24 (framework branch `dev-chip-ladder`, 7d2ecf7; his ask "let us make a dedicated page to the RISC-V and Arduino
chips and their different levels"):** `/display/chip-ladder` — the four levels above three tabs: RISC-V (the eight slots + exceptions),
Convenience and cross-reference boards, Emulators; `ChipLadderEntry` rows (code-owned seed, every level claim with its basis, every emulator
with licence and pins real|stub|none), doors `GET /api/board/chip-ladder?section=`, `/levels`, `/emulators`; `in_polari` derived on read; the two
sections never share a table; nav Hardware & Firmware → Chips and levels; selftest 15/15, BOARD_CLASSES 63. On his bench 2026-10-24 (part names
only): UNO R3, Arduino Zero (SAMD21), Adafruit Feather M0 Express (SAMD21), an Elecrow ESP32 (Xtensa) eval board, a bare iCE40UP5K WLCSP chip,
two BUD BB-32650-W breadboards (the kit register should gain these rows: the two breadboards + the SAMD21 boards + the ESP32 board). Not yet:
Chrome check on the test node (rides with the next deploy), the SAMD21 emulator question (none known), the ESP32 board's module (read the silk).
**Correction 2026-10-24 (his photos):** the Elecrow board is an **ESP32-S3** (Xtensa LX7), an enclosed e-paper HMI display (CrowPanel form), derived
from its GPIO header silk — IO20 and IO38 together exist only on the S3. Not RISC-V (the S3's only RISC-V is its ULP coprocessor). So esp-emulator's
S3 coverage (§11.4, D-mis-21b) now reaches a board on the bench. Exact module pending `esptool chip_id` / `flash_id` over USB.

**✅ bench-0 + chp-1 BUILT 2026-10-24 (same branch, rebased onto dev-pv-bench; his asks: "clear separation between those simulatable and
those not and how they are simulated with what software", "a dev/eval-board selection component for adding dev and eval boards to a Bench",
"a Breadboard Selection Component", "If something can only be hardware tested that needs to be outlined very clearly"):** `/display/bench`
(tabs On the bench · Add a dev or eval board · Add a breadboard) over `Bench` + `BreadboardModel` rows; the selection panels are configured
tables with Add-to-bench / Remove row actions (no new component); doors `/api/board/benches…`, `/api/board/bench-options/…`. Every board
carries a TESTING word from `chip_ladder.testing_of`: simulated with real pins · simulated with STUB / UNVERIFIED / NO pins · **HARDWARE
ONLY** — never blank. The ladder page splits each section into those three tables and the Emulators tab adds method + inputs_driven_by and
two cross-section tables. Breadboard geometry derived by `pv_shapes.breadboard_geometry` (half-400, full-830, mini-170); the BUD BB-32650-W
and the kit's breadboard say UNVERIFIED until their datasheet / a count. The Mission run's Inventory step (§3) reads the Bench. Selftests
18/18 + 15/15; BOARD_CLASSES 65. Not yet: Chrome on the test node; the SAMD21 (Arduino Zero, Feather M0 Express) stays HARDWARE ONLY.

- **D-mis-24** the sample above (recommended) — swap any one; two slots per level stay.
- **D-mis-25** RP2350 kept as the named no-emulator exception for PIO (recommended) — or dropped entirely.
- **D-mis-26** K210 vs LiteX for the second bare-C slot if Maix boards vanish (recommended: fall back to LiteX / PicoRV32 on the same ECP5 board, Renode `litex_picorv32`).

## 14. Rules this plan keeps

Derive or cite (every verdict names its run or rule; inventory rows name their source); knobs + suggestions (aim, importance, limits and
step knobs are knobs; the run is the suggestion with evidence); competitive scoring; reproducible initial conditions (`MissionRun`); no raw
JSON on screens (a state's rows are configured tables); theme tokens by property with `-text` pairs; click-toggle on states and rows;
object coherence (`Mission`, `MissionKind`, `MissionRun`, `MissionStep` as tree nodes with plain words); heavy steps on isle-core; files
small, one class per file; the hardware no-code's one model across frontend / backend / hardware (the step blocks are ordinary blocks).
