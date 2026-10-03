# PCB from scratch (pcb arc): choose chips in Polari, generate the KiCad schematic, a person places and routes in KiCad, `kicad-cli` checks and exports, and the Gerber zip goes to a fab (DKRed first) — every step a row, traceable from the chosen chip to the uploaded file

**Date:** 2026-10-03 · **Status: PLAN ONLY — nothing built; decisions D-pcb-1..6 his.** Drafted by an opus agent from the
tree at suite `origin/dev` 94f2900 (framework / angular at the `dev-hn-0` tips 17b99ef / d563892); Fable reviews.
His ask (2026-10-03): *"We also need to plan out where different things needed for KiCad as well as footprint planning
and solder and other things needed for KiCad to enable making a board from scratch."* + his screenshot of the fab's
accepted layers (silkscreen .gto/.gbo, paste .gtp/.gbp, soldermask .gts/.gbs, drill .drl/.xln, drill drawing,
mechanical .gm, outline .gko, copper .gtl/.gbl). His standing word (BOARD_PROGRAMMING_PLAN §8a): *"Eventually we will
want to make our own boards"* — `BoardDefinition.designer` already separates "theirs" from "ours". The views half is
the companion `DESIGN_LEVEL_VIEWS_PLAN.md` (dlv arc). Facts marked **unverified** were not confirmed from a primary
source on 2026-10-03.

## 0. The ask and the principle

- **KiCad is the ENGINE** (GPL-3.0; a separate process, so linking never arises — the `polari-eda-tools/LICENSES.md`
  reasoning). Headless `kicad-cli` (KiCad 9 docs, verified https://docs.kicad.org/9.0/en/cli/cli.html) does:
  `sch export netlist` (formats kicadsexpr, kicadxml, cadstar, orcadpcb2, spice, spicemodel, pads, allegro),
  `sch export bom` (ordered `--fields`), `sch export svg|pdf`, `sch erc`; `pcb export gerbers` (Protel extensions
  .gtl/.gbl… by default, `--no-protel-ext` for .gbr), `pcb export drill` (`--format excellon|gerber`,
  `--generate-map --map-format pdf|gerberx2|ps|dxf|svg`), `pcb export pos`, `pcb export step|vrml|glb`,
  `pcb export svg`, `pcb export ipc2581|odb`, `pcb drc`; jobsets run predefined jobs. **It does NOT place or route.**
- **Polari holds the DESIGN AS ROWS** — the parts (the register + datasheet facts), the netlist (from the no-code graph
  / electrodevice circuit), the board constraints (the fab's rules as rows) — and GENERATES the KiCad schematic,
  INGESTS the KiCad board back after a person edits it, and RUNS kicad-cli as an engine for checks and outputs.
- **A person places and routes in KiCad** (the open tooling is weakest at autorouting); Freerouting (GPL-3.0, Specctra
  DSN in / SES out, CLI, verified https://github.com/freerouting/freerouting) is an optional first pass (D-pcb-2).
- **Traceable and costed:** every number (a pad size, a reflow peak, a min trace) is DERIVED (shown) or CITED
  (`DatasheetFact`, the board module's existing class: document, revision, page_table, url); every engine run has a
  repro block; the fab order's price is a quote row, never asserted.
- **Where it sits:** the microchip ladder ENDS at package (memory `microchip-ladder`: *"Board/PCB = future composition
  arc, not this ladder"*); a PCB is a COMPOSITION of parts — the `composition` module (`PartComponentDefinition`,
  `InterfaceDefinition`, `RoutingDefinition`, `FunctionalPartDefinition`) is the parent concept; a chip's package
  exports a black-box PART into it. The board rows here refine that for electronics; they do not replace it.

## 1. What exists (verified in the tree) and the gaps

Paths under `polari-rf-node/polari-framework/modules/`.
- **electrodevice:** `CircuitDefinition` (analyses, probes) + `CircuitComponentDefinition` (kind, params, `pins_json` =
  ordered net names = the SPICE node order, `device_name`) + `CircuitNetDefinition` (net, is_ground) → a netlist
  (`GET /api/electrodevice/circuits/{name}/netlist`) and a SPICE run (`…/run`, `custom/spice_run.py`,
  `CircuitRunResult`); breadboards (`BreadboardDefinition`, `ComponentPlacement` tie points, `BoardJumper`);
  `PinBindingDefinition` (a design output bit → a driven source); `SpiceModelCard`. **This is already a netlist model —
  the schematic generator reads it; no second netlist class.**
- **board:** `BoardDefinition` (33 devices from the register incl. `designer`, `board_design_open`, `licence_notes`),
  `DatasheetFact` (19 UNO facts, boards.txt pinned to a commit + line), `AdapterDefinition`, `Road` (todo/in-progress/
  done per device), `FirmwareBuild`; the register `AI-Notes/designs/HARDWARE_CAPABILITY_REGISTER.md` (devices,
  adapters, open cores, organisations).
- **no-code naming the chips:** hwnocode `HardwareSolution` (board/instance + cmod subgraph + hw-interface binding),
  cmod `CGraph` (the firmware half), hwfpga `RegisterMapDefinition` → `polari_regblock.v` (an FPGA companion's logic).
- **machines a board goes into:** voron `PrinterDefinition` / `PrinterBoard` / `PrinterState`, printing_suite
  `PrintJob`/`SliceJob`/`GcodeArtifact` (an enclosure is a print job), the shelved BLCNC plan
  (`AI-Notes/plans/shelved/BLCNC_PLAN.md`, its safety board explicitly out of scope of brd).
- **artifacts:** the file store (SeaweedFS, fs-1, S3 :9000) for Gerber zips / STEP / KiCad projects; the forge
  (`polari-forge`, Forgejo GPL-3.0-or-later, git + Debian registry) for publishing the design repo and its releases.
- **views:** the dlv arc's `level-view` (a schematic is a graph — same component, a `schematic` renderer).

**Gaps:** no symbol / footprint / land-pattern model; no PCB rows (stackup, outline, placement, tracks); no KiCad engine
or worker; no fab rules as data; no DFM/DFA or assembly (solder) data; no order/quote rows. `grep -ri
"kicad\|gerber\|footprint"` over the modules finds nothing PCB-related.

## 2. The rows (new module `pcb`, one class per file; depends on board, electrodevice, composition)

- **`Part`**: manufacturer + MPN, package, `device_definition` (a `BoardDefinition` for modules/boards, or an
  `ElectronicDeviceDefinition`/kit part), datasheet document + revision, lifecycle (active/NRND/EOL as cited),
  provenance (register row), `mount` (tht|smd), `symbol`, `footprint`. A kit part (TMP36, 220 Ω, LED) is a `Part`.
- **`Symbol`** / **`Footprint`**: a KiCad library reference (`Device:R`, `Package_TO_SOT_THT:TO-92_Inline`) + the
  library's version/sha + `source` + licence. Sources:
  - **official KiCad libraries — CC-BY-SA-4.0 with the design exception** (verified
    https://www.kicad.org/libraries/license/: the holder *"waives article 3 of the license with respect to these
    designs and any generated files"*) → our boards and Gerbers are free of the share-alike; redistributing the
    libraries themselves stays CC-BY-SA. GPLv3-project-compatible for our use. **Default.**
  - vendor/aggregator libraries (DigiKey, SnapEDA, Ultra Librarian, SamacSys): terms are per site and often ToS-bound;
    **unverified per source** → engine-only (used at design time, never committed) or excluded until read (D-pcb-3).
  - our own (derived, below) — committed, GPL-3.0 with the project.
- **`LandPattern`** — "footprint planning": a footprint DERIVED from the package dimensions on the datasheet
  (`DatasheetFact` rows: body, pitch, lead width/length, tolerances) by IPC-7351-style land rules (toe/heel/side
  fillets per density level — a knob `density=most|nominal|least`), with the equation shown and the result compared
  against the KiCad library footprint where one exists (difference = a finding). IPC-7351 itself is a paid standard:
  we cite it by clause, never copy its tables (**unverified**: which formula set KiCad's own footprint generator uses).
- **`Schematic`** (sheets) + **`SchematicSymbolInstance`** (ref designator, Part, unit, sheet) — the nets come from
  electrodevice `CircuitNetDefinition`/`pins_json` (or a hwnocode solution's hw-interface pins), never re-entered.
- **`Board`**: layer count, stackup (`BoardLayer` rows: copper/dielectric, thickness, copper weight), outline (a
  math-shapes polygon, `units=space` — the shape library already does 2-D polygons), the fab profile it targets.
- **`FabProfile` + `FabRule`** — the fab's constraints as rows, each CITED. **DKRed** (DigiKey's fab service, verified
  https://www.digikey.com/en/resources/dkred, 2026-10-03): 2 or 4 layers; 0.5″×0.5″ to 10″×10″; 62 mil (1.6 mm);
  FR4 TG 170–180; ENIG; 1 oz copper; min trace 5 mil (0.13 mm); min space 5 mil (0.13 mm); min drill 8 mil (0.20 mm);
  max drill 245 mil (6.22 mm); min via hole 8 mil; min via pad 16 mil (0.41 mm); min pad 10 mil (0.25 mm); plating
  1 mil; tolerance 5 mil; red mask, white silk; min 4 copies; 5–10 business days; "starting at $1.50 per square inch".
  Accepted names as listed there: silkscreen .gbo/.gto/.sst/.ssb/.legend/.silk; paste .gtp/.gbp/.gpt/.gpb/.paste;
  soldermask .gts/.bgs/.smt/.sm_/.smb/.mask/.solder; drill .drl/.drd/.xln/.drill; drill drawing .gd/.dd; mechanical
  .gm; outline .gko/.outline/.profile; copper .pho/.copper/.physical_layer/.Layer. **Two discrepancies to settle at
  the first upload:** his screenshot shows copper .gtl/.gbl and mask .gbs, while the page text lists neither (it shows
  ".bgs", likely a typo) — KiCad's default Protel names are .gtl/.gbl/.gts/.gbs, so we export those and record the
  upload form's verdict as a `DatasheetFact`. A DigiKey forum thread (https://forum.digikey.com/t/minimum-drill-size-changed/55716,
  2025) reports 0.20 mm holes finished at 0.25 mm within the stated ±3 mil plated tolerance → knob
  `drill_margin_mil` with a suggestion. Fab rules become the KiCad board's design rules (written into the `.kicad_pro`
  / `.kicad_dru`) AND a Polari check over the ingested board.
- **`Placement`** (ref → x, y, rot, side) and **`Track`/`Via`/`Zone`** — INGESTED from the `.kicad_pcb` a person saved
  (s-expression read in Python), never authored by Polari; summarised (counts, lengths per net) rather than every
  segment when large.
- **`DRCResult` / `ERCResult`**: kicad-cli's report as rows (severity, rule, items, location) + our fab-rule check.
- **`FabricationOutput`**: one row per file (layer, extension, sha256, kicad-cli version/digest, the board sha it came
  from): copper F/B, mask F/B, paste F/B (= the stencil), silk F/B, edge cuts (outline), drill (Excellon) + drill map,
  pos/centroid, BOM; the zip (sha) in the file store.
- **`Assembly`** — solder: per `Part` a `SolderMethod` (hand-THT | hand-SMD | stencil+reflow | hot-air) chosen by a
  knob with a suggestion (e.g. QFN/BGA → reflow; all-THT kit parts → hand), the paste layer → stencil (the .gtp/.gbp),
  a `ReflowProfile` per part CITED from its datasheet (peak, time above liquidus; J-STD-020 as the cited reference,
  **unverified URL**), the board's profile = the most constrained part's (derived, shown); tools/consumables named
  (iron, solder alloy — SAC305 vs Sn63Pb37 as a knob with the lead caveat).
- **`Order`/`Quote`**: fab + qty + price + date + the uploaded zip sha; DKRed via its web form (a person's step);
  later parts availability/price via the DigiKey API (a closed service, ToS — optional engine, D-pcb-6).

## 2b. THE BOARD OBJECT — one definition shared by KiCad, Zephyr, FreeRTOS/ESP-IDF, bare C and Polari (his ruling 2026-10-03)

*"we want to be able to share a similar or overlapping board definition between kicad as well as zephyr and freeRTOS and
the system, trying to structure our board object to make sense in respect to all of them since we will be flipping
between them."*

Each world already has a "board" and they overlap on exactly one thing: **which MCU pin is wired to which net, and what
that net is for.** So the shared object is built around the pin/net assignment, with each world as a VIEW generated from
it (and ingested back into it), never four hand-kept copies:

| layer (rows) | what it holds | KiCad view | Zephyr view | FreeRTOS / ESP-IDF view | bare-C view (cmod) | Polari runtime view (brd) |
|---|---|---|---|---|---|---|
| **Soc** (`SocDefinition`, from DatasheetFact rows) | the chip: packages, pins with their alternate functions, peripherals (USART0, ADC, TIM2…), memory map, clocks | the MCU symbol + footprint (package) | the SoC `.dtsi` it matches (upstream Zephyr) | the vendor HAL target (`-mmcu`, `IDF_TARGET`) | `F_CPU`, register names | ISA, flash/RAM class S/M/L |
| **BoardHardware** (`Board`, `BoardComponent`, `Net`, `Connector`) | the physical board: every component, every net, connectors/headers and their pin order, power rails, crystals, USB bridge | THE schematic + PCB (components ↔ symbols/footprints, nets ↔ nets) | the board `.dts`: `chosen`, `aliases`, connector nodes (e.g. an Arduino-header gpio map), regulators | the BSP's pin definitions | — | USB VID:PID (the bridge/chip on the board), programmer kind, adapter needed |
| **PinAssignment** (`BoardPin`: soc pin ↔ net ↔ connector pin ↔ function + peripheral + electrical facts) | the ONE overlap: "PD6 → net PWM_LED → header D6, function TIM0_OC0A" | net names and the ERC class (power/signal) | `pinctrl` + `gpio` aliases + `status = "okay"` per peripheral in the board `.dts`/overlay | `#define`s / `sdkconfig.defaults` / `menuconfig` fragments for the pins and peripherals in use | the generated `board_config.h` (cmod already generates one per variant: INSTANCE_INDEX, HAL knobs) + the HAL atoms' pin constants | the Firmware Installer's compatibility (a build names the pins it drives; refused if the instance's board lacks them) |
| **RuntimeProfile** (per `firmware_runtime` knob) | which runtime, which peripherals enabled, clocks, stack/heap sizes, console UART, the twin | — | Kconfig fragment + the devicetree overlay | `sdkconfig` / FreeRTOSConfig.h deltas | the Makefile/linker script | twin (simavr/QEMU), BoardSimCost, the scenarios that apply |
| **Identity** | name, revision, designer (theirs/ours), licence, the register row, roads | title block | `board.yml` / vendor + name | the BSP name | `BoardDefinition` (brd-0) + `Road` |

Rules:
- **Pins are named once.** A `BoardPin` has one canonical name (the connector label when there is one — `D6`, `A0` — else
  the SoC pin); every generated view uses that name, so flipping between KiCad, a Zephyr overlay, an ESP-IDF header and
  the C firmware shows the same identifiers. Nets carry the KiCad net name; the two are linked, not merged.
- **Generate out, ingest in, both by hash.** `pol board render <board> --as kicad|zephyr|esp-idf|bare-c` writes the
  view with a header naming the board row + its sha; `pol board ingest <path>` reads a KiCad project (nets, components,
  footprints), a Zephyr board dir (`.dts`/`.dtsi`/`pinctrl`/`board.yml`), or an ESP-IDF BSP into the same rows and
  reports what disagreed (a pin assigned differently in two views is a `BoardConflict` row — shown, never auto-resolved).
- **Datasheet facts under everything** (derive-or-cite): a pin's alternate functions, drive strength, ADC channel
  numbers, package dimensions come from `DatasheetFact` rows; the land pattern for the footprint and the Zephyr
  pinctrl both cite the same fact.
- **The SoC is shared across boards; the board is shared across runtimes.** The UNO, a future UNO shield, a Longan Nano,
  the Pico 2 and the C3 each get a `Board` row; their SoCs (`ATmega328P`, `GD32VF103`, `RP2350`, `ESP32-C3`) are
  separate rows the boards reference. Zephyr's own upstream board dirs for the C3/SAMD21/Pico 2 are INGESTED as the
  starting rows (and cited), not retyped.
- **brd-0's `BoardDefinition` becomes the Identity + runtime layer of this object** (no second board class); cmod's
  `board_config.h` and hwnocode's `firmware_runtime` knob read the PinAssignment + RuntimeProfile rows; the PCB arc's
  `Board`/`Net`/`Footprint` rows are the BoardHardware layer. One module owns the object: `board` (brd), with pcb/
  hwnocode/cmod as readers and writers through it.

First proofs: (1) ingest Zephyr's upstream `esp32c3_devkitm` (or the C3 board sc-3 used) + the UNO's pins typed from the
Arduino pinout drawing (cited) → the same `BoardPin` rows render a Zephyr overlay AND cmod's `board_config.h` AND a
KiCad netlist stub with identical pin names; (2) the UNO shield (pcb-1) is designed as a `Board` whose connector rows
reference the UNO board's header pins, so its KiCad schematic, its C firmware and its Zephyr overlay (on a Zephyr-capable
host board) are three renders of one assignment. Slice: `brd-bo` (the board object) — before pcb-0 and hn-1, since both
read it.

## 3. The flow as no-code (ties to HARDWARE_NOCODE_PLAN)

1. **Choose chips:** a `HardwareSolution` already names its board/MCU; a `Board` node on the ONE canvas (hn-0's
   data-driven palette: a `statePalette` on the class) collects the Parts the solution's interfaces need (a TMP36 on
   A0 = the `hw-interface` binding's pin; the LED on D13).
2. **Netlist:** the parts' pins → an electrodevice `CircuitDefinition` (the same rows SPICE runs on) — so **SPICE
   validates the analog part** (TMP36 divider, LED current at 220 Ω) BEFORE a schematic exists.
3. **Generate the schematic:** rows → `.kicad_sch` (D-pcb-1: direct s-expression writer vs SKiDL) → `kicad-cli sch erc`
   → ERCResult rows (clean is the gate) → `kicad-cli sch export netlist` round-trips against our rows (equal nets =
   the proof the generator is faithful).
4. **Board:** a `.kicad_pcb` seeded with outline, stackup, fab rules and footprints (unplaced or a starter placement)
   → **a person places and routes in KiCad** (or Freerouting first, then the person) → save → `pol pcb ingest`
   → Placement/Track rows → `kicad-cli pcb drc` + our FabRule check → DRCResult rows.
5. **Outputs:** `kicad-cli pcb export gerbers` (Protel names) + `export drill --format excellon --generate-map` +
   `export pos` + `sch export bom` → FabricationOutput rows → the zip, checked against the FabProfile's accepted
   names → file store + a forge release (the design repo tagged).
6. **The other outputs of the same graph:** the firmware (cmod glue → the installer) and the twin/scenarios validate
   behaviour; the board's `BoardDefinition` row (designer = us) is created from the `Board` so detection, flashing and
   the installer treat our board like any other.
7. **First board: the UNO shield** — a 2-layer shield carrying the kit's TMP36 + an LED + 220 Ω + the headers, all THT
   (hand-solderable); it proves chips → schematic → DRC → Gerbers → fab → solder → flash (brd-fi's uno-sim-rig variant
   unchanged: same pins A0/D13/D6) → the row moves. The UNO header geometry (the non-0.1″ gap) must be CITED from
   Arduino's published drawing/files (https://docs.arduino.cc/hardware/uno-rev3/; Eagle format, not KiCad — KiCad
   can import Eagle projects, **unverified for this file**) into `DatasheetFact` rows, not eyeballed.

## 4. Visualization (ties to DESIGN_LEVEL_VIEWS_PLAN)

- **`/display/board-schematic`**: `level-view` with a `schematic` renderer (symbols as boxes with pin stubs, ELK
  orthogonal routing — the dlv renderer with a symbol vocabulary) over Schematic rows; or kicad-cli's own
  `sch export svg` as an image panel for fidelity. Recommend both: rows drive the interactive view, the SVG is the
  "as KiCad draws it" tab.
- **`/display/board-layout`**: per-layer SVG from `kicad-cli pcb export svg` (verified command; per-layer option
  details **unverified**: the docs summary says single vs multi mode) in a layer-toggle panel; Placement rows drive the
  click targets (ref → Part detail). KLayout also reads Gerber (https://www.klayout.de/) if D-dlv-3 brings it in —
  not needed for boards. No new chart engine.
- **`/display/board-bom`**: configured table (ref, Part, MPN, qty, mount, solder method, source, licence, price quote).
- **`/display/board-assembly`**: per-part solder method + reflow table + the board's derived profile as a
  GraphDefinition (temperature vs time via `named-graph-panel`).
- **`/display/board-fab`**: FabRule rows vs DRCResult; FabricationOutput rows (layer, extension, accepted?, sha).
- **3D:** `kicad-cli pcb export step|vrml|glb` (verified) → the existing scene as the board's detail tab (glb is a
  three.js-native format; the cad worker already exports glTF/GLB). 3D models come from `kicad-packages3d` (4.9 GB
  installed) — fetched per footprint used, never the whole set (cost rule).

## 5. Decisions (his; recommendations in bold)

- **D-pcb-1 schematic generation:** **write the `.kicad_sch` s-expression directly** (a small, owned writer; nothing
  between rows and file; the format is documented by KiCad, **unverified** for stability across 9→10) vs SKiDL (MIT,
  verified https://github.com/devbisme/skidl: netlists + "editable KiCad schematics (KiCad 6–10)") — SKiDL is a Python
  DSL whose own model would sit beside our rows. Fallback: SKiDL as an engine if the writer proves costly.
- **D-pcb-2 placement/routing:** **a person in KiCad first; Freerouting as an opt-in first pass** later (GPL-3.0, CLI;
  it also offers a hosted API — the self-hosted jar only, never the hosted service, so the design never leaves our machines).
- **D-pcb-3 footprint sources:** **KiCad official libs + our derived LandPatterns only**; vendor libraries per source
  after reading their terms (engine-only at most; NC/ToS-bound excluded — `project-license-gplv3`).
- **D-pcb-4 first board:** **the UNO shield** (THT, hardware he owns, firmware already proven on the twin).
- **D-pcb-5 assembly scope:** **hand-soldered THT first** (the kit's parts); SMD + stencil + reflow at pcb-3 with a
  small SMD part set (0805 passives, SOT-23, SOIC) before QFN.
- **D-pcb-6 DigiKey API:** **none for now**; quotes entered as rows by a person; an optional engine later (closed
  service, its ToS recorded) — DKRed is DigiKey's own fab, so the same account covers both if he wants it.


### 5a. HIS RULINGS 2026-10-03 (his words)
- **D-pcb-1 → write directly:** "write directly so we can track them through polari and keep them in our own apis and
  dbs, while relaying them through kicad engines." The design IS the rows (Part/Symbol/Footprint/Schematic/Board/…);
  Polari writes `.kicad_sch`/`.kicad_pcb` from them and reads them back; KiCad is the relay engine for ERC/DRC/exports
  and the editor a person uses. No SKiDL.
- **D-pcb-2 → accepted:** a person places and routes in KiCad, Freerouting opt-in — "fine, if the functionality is too
  complex."
- **NEW — FreeCAD alongside KiCad, both as POLARI-MANAGED NATIVE APPS:** "along with KiCad, we should also already have
  functionality to handle FreeCAD as well. Both of those can become polari managed native apps not on the isle or
  swarm, and we can automate the download and setup of those apps so that we can set up volumes that enable them to
  have files shared between both the native apps and the polari isle and/or swarm." → §5b.

### 5b. KiCad + FreeCAD as Polari-managed NATIVE apps with shared volumes (new slice pcb-na, shared with the CAD arcs)
- **A new app kind in the store: `native-desktop-app`** (beside container apps and hardware/KVM apps — the name
  "Hardware App" stays the KVM guest's). Rows: `NativeAppDefinition` (name, upstream, licence — KiCad GPL-3, FreeCAD
  LGPL-2.1+ — install routes per OS: Debian package / Flatpak / AppImage pinned by version + sha256, the binary and
  the headless CLI it exposes: `kicad-cli`, `FreeCADCmd`), `NativeAppInstall` (per device: route taken, version,
  verified sha, paths), `SharedProjectVolume` (a host folder registered with the node and mirrored to the file store:
  SeaweedFS as the truth, mounted or synced both ways — `weed mount` (FUSE) where available, else a watched-folder sync
  run by the node; conflict rule = the file store wins and the native copy is renamed, never silently overwritten).
- **Automation:** `pol apps native install kicad|freecad` (download by pinned URL + sha, verify, install by the OS
  route, register the CLI as an ENGINE for the ladder so the same `kicad-cli` serves the headless exports), `pol apps
  native volume add <folder> --project <board>` (creates the volume row, the file-store bucket/prefix, the mount or
  sync), `pol apps native open <project>` (launches the app on the shared folder). The app shell's store page shows
  native apps with install/open; the desktop shell runs the fixed argv through its existing pkexec pattern.
- **Where it runs:** on a person's desktop (pol-core-class box or a laptop), NOT on the isle or swarm; the isle/swarm
  side sees the same files through the file store and runs the headless engines in workers (`prf-pcb-engines` for
  `kicad-cli`; a `prf-cad-engines` with `FreeCADCmd` for STEP/mesh work).
- **Why FreeCAD here:** enclosures, mounts, panels and the machines of the printing/BLCNC arcs are FreeCAD work; the
  KiCad StepUp workbench (open) carries a board's STEP into FreeCAD and the enclosure back; FreeCAD's own files
  (`.FCStd`) become rows the same way (`CadProject`, parts, parameters) and its 3D shows in the existing scene.
- **Proof for pcb-na:** on pol-core, `pol apps native install kicad freecad` (pinned, verified), a shared volume for the
  UNO-shield project, the schematic written by Polari opens in KiCad from the volume, a person's edit round-trips into
  rows, `kicad-cli` in the worker exports the same project from the file store, and the board's STEP opens in FreeCAD.

## 6. Cost + licences

| component | licence (verified where) | role | cost |
|---|---|---|---|
| KiCad 9 (`kicad` Debian trixie 9.0.2+dfsg-1) | GPL-3.0 (KiCad project) | engine: kicad-cli ERC/DRC/exports | package 164 MB installed (amd64, https://packages.debian.org/trixie/kicad) + its wx/OCCT deps → image ≈ 1–1.5 GB **unverified, measure** |
| kicad-symbols / kicad-footprints 9.0.2-1 | CC-BY-SA-4.0 + design exception (https://www.kicad.org/libraries/license/) | libraries | 216 MB / 155 MB installed (https://packages.debian.org/trixie/kicad-symbols, …/kicad-footprints) |
| kicad-packages3d 9.0.2-1 | same | 3D models | **4.9 GB** installed (https://packages.debian.org/trixie/kicad-packages3d) → never in the image; per-footprint fetch |
| SKiDL | MIT (repo) | optional generator (D-pcb-1) | pip, small |
| Freerouting | GPL-3.0 (repo) | optional router (D-pcb-2) | Java jar + a JRE — size **unverified** |
| KLayout | GPL-3.0 (LICENSE file) | optional Gerber/GDS viewer engine (dlv) | inside `openroad/orfs` already |
| elkjs | EPL-2.0 + GPL-3.0-or-later Secondary License (LICENSE.md) | schematic layout in the browser (dlv) | bundle **unverified** |
| DKRed | DigiKey terms of sale (not read in full) | fab | quoted per order |
| DigiKey API | closed service, ToS | optional (D-pcb-6) | none |

Worker: **`prf-pcb-engines`** (debian:trixie-slim pinned by digest + kicad + symbols + footprints, no 3D, + the
standard worker `/capability` `/run` + res-2/res-3 blocks, provider kind in PROVIDER_PORTS/ENGINE_MODULES, a
`ModuleResourceProfile`) — estimated 1.5–2 GB, measured at pcb-0 with peak RSS / CPU-s of an ERC, a DRC and a full
export of the reference board. Whether kicad-cli runs with no X display in the slim image: **verify at pcb-0**.

## 7. Slices (each its own branch off dev)

| slice | what | proof | gate |
|---|---|---|---|
| pcb-0 | module `pcb` (§2 rows), `prf-pcb-engines` worker + the engines ladder entry (`PCB_ENGINES_URL` → local `kicad-cli` → image → provider `pcb.engines` → refusal), `pol pcb ingest`; DKRed `FabProfile`/`FabRule` rows cited; pages board-bom / board-fab / board-layout (svg layers) | ingest an OPEN KiCad board: **Raspberry Pi's RP2040 Minimal design** (KiCad, `datasheets.raspberrypi.com/rp2040/Minimal-KiCAD.zip`; staff answer "all design files are made available openly, with no limitations", https://forums.raspberrypi.com/viewtopic.php?t=340030 — the formal licence page returned 404 → record as such). NOTE: the Raspberry Pi Debug Probe's repo is FIRMWARE ONLY (https://github.com/raspberrypi/debugprobe) — not a KiCad source. → rows (parts, placements, nets), kicad-cli DRC + Gerbers reproduce byte-stable (same sha twice), DKRed rule check reports the board's real violations or none; worker cost row | D-pcb-3 |
| pcb-1 | schematic generator (D-pcb-1) from rows: the UNO shield's Parts (TMP36, LED, 220 Ω, headers) + its electrodevice circuit; SPICE on the same rows; `/display/board-schematic` | `kicad-cli sch erc` clean; `sch export netlist` equals our nets; SPICE: LED current and TMP36 output at 25 °C within the cited datasheet values | D-pcb-1, D-pcb-4 |
| pcb-2 | board seeded (outline 2-layer, DKRed rules into `.kicad_dru`, footprints) → a person places/routes → ingest → DRC (KiCad + ours) → Gerbers/drill/map/pos/BOM in DKRed names → zip | DRC 0 against DKRed rules; every file's extension accepted by the profile; zip sha in the file store; the upload form's verdict recorded as a fact (settles .gtl/.gbl vs the page text) | D-pcb-2 |
| pcb-3 | assembly: SolderMethod per part, ReflowProfile rows cited, the board profile derived, stencil = paste layers; `/display/board-assembly`; LandPattern derivation for one SMD package compared with the KiCad footprint | hand-THT plan for the shield (all parts THT); one SOT-23 LandPattern derived from a datasheet within the KiCad footprint's pads ± a stated tolerance, differences listed | D-pcb-5 |
| pcb-4 | Order/Quote rows; the design repo published through the forge (release with the Gerber zip + STEP + BOM); the `BoardDefinition` (designer = us) created from the Board | **his step:** order 4 shields from DKRed; solder; `pol board install uno --variant uno-sim-rig` on an UNO wearing OUR shield → the TMP36 row tracks a finger, D13 lights from a PUT | D-pcb-6 |
| pcb-5 | the FPGA companion board: an iCE40 (USB-programmable per the brd rule — ProgrammerKind `fpga-usb-jtag`, brd-0) carrying hwfpga's `polari_regblock.v`; symbols/footprints for a QFN FPGA, SMD + stencil | ERC/DRC clean; the regblock bitstream builds (yosys + nextpnr-ice40, already in eda-tools) for the board's pinout; the twin (Verilated regblock) reads the same register map | pcb-3 |

**Not in scope:** autorouting by default, high-speed/impedance-controlled design, more than 4 layers (DKRed's limit),
BGA assembly, an in-house fab or the BLCNC as a PCB mill (a later machine road), any vendor library committed without
its terms read.
