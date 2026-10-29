# Register mapping — one place, its own bench views (rm), 2026-10-28

**His ask (2026-10-28):** "Last piece to plug in is the register mapping which will also need its own views that plug into the Bench and
will need to be used to expand out and better group existing register mapping functionality to bring everything into one place, please
revise plan based on this" + his proposal "Polari Register Mapping Visualization" (kept verbatim in the chat of 2026-10-28; its sections are
cited here as P§n). Companions: `HARDWARE_SYSTEM_PINS_PLAN.md` §7 (structs, bridges, Catom assertions), `ELECTRONICS_APP_PLAN.md` (the
pages the `electronics` app ships), `PIN_VIEW_PLAN.md` (pv-4 phases), `UNO_CORE_DEMO_PLAN.md` §5f/§5g (the hardware chain),
`FIRMWARE_GENERATION_MODULE_PLAN.md` §7.7 (lifecycle constraints). PLAN ONLY — per P§13 this is the implementation plan + affected files
presented before any structural change.

## 0. What exists (inspected 2026-10-28, framework dev c11eacd) — most of P§10's model is already built
| P§10 concept | Existing row / code | State |
|---|---|---|
| RegisterDefinition | `board/objects/board/Register.py` (soc, register, peripheral, addr, addr_mem, space, width_bytes, reset_value, description, fields_refs_json, document/page_table/url, origin, undetermined) | ✅ ATmega328P (`registers_atmega328p.json`, `register_summary_*`); ❌ ESP32-C3: `hardware_chain_c3._NO_REG` = "the ESP32-C3 register map is not ingested" |
| RegisterField | `RegisterField.py` (bit_hi/lo, width, **access**, reset_value, values_json, **affects_signal, affects_pin**, cites) | ✅ 328P bit by bit (`register_fields_atmega328p.py`); ❌ C3 |
| HardwareDomain[] / FunctionalRole[] | — | ❌ missing: no domain taxonomy, no control/status/data role |
| AccessSemantics / ResetBehavior | `RegisterField.access`, `reset_value` on both | ✅ (per-reset-source differences ❌) |
| PinDefinition chain | `BoardPin → SocPin → PinFunction → PeripheralSignal → Peripheral → Register → RegisterField`, materialized with reverse `*_refs_json` (ucd-0a, `custom/hardware_chain.py` + `hardware_chain_c3.py`); door `GET /api/board/{board}/chain/{pin}`; page `/display/hardware-chain` | ✅ both chips down to Peripheral; Register/Field only on the 328P |
| LifecycleConstraints[] | `PinLifecycleConstraint` (pin × phase × policy × condition × reason × cite); phases `power-up, reset, bootloader, init, runtime, programming, debug`; policies `prohibited, conditional, reserved, preserve, free`; `lifecycle_uno.py` (RESET/C5 auto-reset, D0/D1 Optiboot + USB-serial, ICSP D11–D13, AREF, XTAL) + `lifecycle_c3.py` (strapping GPIO2/8/9, USB-Serial-JTAG pins, flash pins) | ✅ both chips, cited |
| Phase visualization | pin view phases (pv-4: power-up / reset / bootloader / init / runtime + two blank baselines, `pin_view_phases.py`, `pin_view_modes.py` lifecycle mode) | ✅ per phase in the pin view; no per-pin four-stage MATRIX |
| FirmwarePinAssignment | pin-view claims (`pin_view_state` / InstallRecord / BoardPinNet) + `cmod/objects/cmod/RegisterSetting` (solution, binding, register, **phase**, value, write_mask, field_settings, source line, status) + `CapabilityDefinition` (Purpose: goal → required_targets → acceptance scenario) + `DerivedOverride` | ✅ parts exist, not presented as one chain |
| Register profile / memory map | `register_profile.py`, `memory_map_atmega328p.py`, `memory_map_view.py`, `MemoryRegion`; doors `/api/board/socs/{soc}/register-profile`, `/memory-map`; page `register_profile_page.py`; cmod `cmod_pin_profile_page.py` | ✅ separate pages |
| Validation states | pin view state classes (`within-recommended`, `over`, `undetermined`…), lifecycle policies, electrical refusals | partial; no Valid / Warning / Conflict / Unknown roll-up, no boot-conflict check as such |
| Board register snapshot ("register" = the capability register of boards) | `register_map.py` / `register_rows.json` → BoardDefinition / AdapterDefinition / Road rows | ⚠ NAME CLASH: this "register" is the hardware CAPABILITY register (boards/adapters), not chip registers — kept, but renamed in the UI ("board capability register") so the Registers view is unambiguous |

So the work is: (1) classify, (2) group the four stages, (3) roll up validation, (4) ingest the C3, (5) put the existing pieces into ONE
bench view with three synchronized panels — not a new model.

## 1. Additions to the data (smallest coherent extension, P§13.4)
- **`Register.domains_json`** (list, P§2: `mcu-pin | mcu-internal | mcu-peripheral | mcu-system | soc-interconnect | soc-processor |
  soc-device | platform-virtual`, + a sub-category per P§4 tree, e.g. `mcu-pin/direction`) and **`roles_json`** on `Register` AND
  `RegisterField` (`control | status | data`, several allowed; read/write roles may differ → `{read: [...], write: [...]}`). DERIVED by a
  rule table per chip (`custom/register_taxonomy.py`: e.g. 328P `DDRx` → mcu-pin/direction + control; `PORTx` → mcu-pin/io-data + data,
  and mcu-pin/electrical (pull-up when DDR=0) + control; `PINx` → mcu-pin/io-data + status (write = toggle → control on write);
  `UCSR0A` → mcu-peripheral/uart + status; `CLKPR`/`MCUSR`/`WDTCSR` → mcu-system …), every rule with its datasheet page — derive or cite.
  Categories with no registers (soc-*, platform-virtual, mcu-internal detail) appear in the tree as **deferred** (P§3) with a count of 0 and
  the word "future scope".
- **Lifecycle STAGES** (P§5) over the existing PHASES (no new phase rows): `RESET` = power-up + reset · `BOOTLOADER` = bootloader +
  programming (+ debug) · `INITIALIZATION` = init · `ACTIVE` = runtime. A constant map in `custom/pin_stages.py`; the stage view
  reads `PinLifecycleConstraint` + `RegisterField.reset_value` (RESET column) + `RegisterSetting` rows with `phase=init` (INIT column)
  + runtime claims (ACTIVE column). Per-reset-source differences (P§5 RESET): a `reset_source` condition on the constraint rows
  (`por | external | watchdog | brown-out | software`) where a datasheet distinguishes them (328P `MCUSR`; C3 reset reasons) — cited.
- **`PinStageAssessment`** (derived, not stored): pin × stage → `{function, direction, owner (hardware | boot-firmware | application |
  bridge), restrictions, register_fields, verdict, reasons}`; **verdict** ∈ `valid | warning | conflict | unknown` (P§8) from:
  lifecycle policy (prohibited → conflict, reserved/conditional → warning or conflict by condition, preserve → warning on change),
  electrical refusals (conflict), missing clock enable / invalid mux / two functions on a pin (conflict), no evidence (unknown — never
  valid). **Boot conflicts** (strap level wrong, programming interface blocked, recovery path lost) are flagged `boot-critical` and rendered
  first (P§8).
- **Pin ↔ field both ways at FIELD level** (P§6): already carried by `RegisterField.affects_pin` / `affects_signal` + `PinFunction` refs;
  add `affects_pins_json` for fields that control several pins (a whole PORT register's bits; C3 GPIO matrix fields) and a `nonregister`
  kind of constraint for strap/external-circuit restrictions (already expressible as a `PinLifecycleConstraint` without a register — the
  view must show them; no new row).
- **Firmware chain** (P§7): no new rows — `CapabilityDefinition` (Purpose → required capability) → peripheral/protocol (Peripheral) →
  pin (pin claim) → stage assessment → `RegisterSetting` (the field writes, ordered by `source_line` within `phase=init`) → generated
  firmware (the cmod atoms; with hsp-3, the **Catom assertions** name which atom writes which field). The register view draws this chain
  for the selected pin/field.

## 2. The ESP32-C3 register map (P§11) — the second architecture
Ingest the C3 registers the pin path needs, from the ESP32-C3 Technical Reference Manual (cite chapter + page): IO MUX (`IO_MUX_GPIOn_REG`:
MCU_SEL, FUN_DRV, FUN_WPU/WPD, FUN_IE, MCU_OE …), GPIO (`GPIO_ENABLE_REG`, `GPIO_OUT_REG`, `GPIO_IN_REG`, `GPIO_PINn_REG` interrupt
fields, `GPIO_FUNCn_OUT_SEL_CFG_REG`, `GPIO_FUNCy_IN_SEL_CFG_REG` = the GPIO matrix), `GPIO_STRAP_REG` (boot strapping, read-only),
UART0 control/status essentials, `SYSTEM_PERIP_CLK_EN0_REG` (peripheral clock enable — the "missing clock enable" check), RTC/reset-reason
registers needed for the RESET column. Not the whole TRM: P§3 scope. Rows into the same `Register`/`RegisterField` classes; the chain's
`_NO_REG` refusal goes away for these peripherals. Download mode / USB-Serial-JTAG / strapping are already in `lifecycle_c3.py` — reused.

## 3. The views — ONE bench view "Registers" with three synchronized panels (P§9), absorbing the scattered pages
| Panel | Content | Built from |
|---|---|---|
| A. Taxonomy | the P§4 tree (MCU → Pin/Internal/Peripheral/System → sub-categories; SoC; Platform/Virtual) with counts; deferred branches greyed with "future scope"; role filter chips Control / Status / Data | `domains_json` / `roles_json` |
| B. Register mapping | selected register: name, description, peripheral, address/offset (or "not memory-mapped: <space>"), width, roles (read vs write), access, fields + bit ranges (bit strip), reset value(s), related pins + pin functions, lifecycle restrictions, firmware settings (RegisterSetting) and the Catom assertions that write it, provenance | Register / RegisterField / RegisterSetting / CatomAssertion |
| C. Pin lifecycle | selected pin: the 4-column matrix RESET · BOOTLOADER · INITIALIZATION · ACTIVE (rows: function, direction, owner, pull/electrical, register fields, restrictions, verdict) — the P§5 example table exactly; boot-critical conflicts on top | PinStageAssessment |
Selection sync (P§9): pin → filters B to its fields; field → highlights its pins in C and on the pin view; register → its pins. Three
distinctions shown everywhere (P§9): **supported** (rows exist + verified), **documented** (cited, not exercised), **future** (taxonomy only).
- **Absorbs:** `/display/hardware-chain` (becomes panel B's "chain" tab), `register_profile_page` + `memory-map` (panel B's "profile" and
  "memory" tabs), `cmod_pin_profile_page` (panel C's firmware rows), the pin view's lifecycle MODE (kept on the pin view; it reads the same
  assessment). Old routes REDIRECT to the new view with the selection pre-set — nothing deleted until the Chrome pass proves the view.
- **On the bench:** a Registers step in the Workbench walkthrough and a Registers tab on the Bench page, scoped to the bench's boards;
  the Structs view and Bridges view (hsp-3) link into it (a struct field's catom → the register fields it writes → their pins and
  stages), closing the loop pins ↔ registers ↔ catoms ↔ structs ↔ bridges.
- Frontend: configured tables + the existing pin view / D3 components; the bit strip and the 4-column matrix as two small sanctioned
  presentational components (no logic), `no-raw-json` rule kept.

## 4. Slices (each own branch off dev; selftest-proven; Chrome pass in the isle through `polari-pol`)
| # | Slice | Affected files (framework unless noted) | Proof |
|---|---|---|---|
| rm-0 | taxonomy + roles: `domains_json` / `roles_json` on Register + RegisterField, `custom/register_taxonomy.py` rule table (328P), deferred categories | `board/objects/board/Register.py`, `RegisterField.py`, `board/custom/register_taxonomy.py` (new), `custom/hardware_chain.py` (fill), schema freeze note | every 328P register in ≥1 domain; DDRx/PORTx/PINx/UCSR0A/MCUSR land as listed with roles; a register with no rule = `unclassified` by name (never guessed) |
| rm-1 | stages + assessment: `custom/pin_stages.py` (stage map, `reset_source` condition), `PinStageAssessment` derivation with valid/warning/conflict/unknown + boot-critical; door `GET /api/board/{board}/pins/{pin}/stages` | `board/custom/pin_stages.py` (new), `board/board_chain_api.py` (or the chain door's file), `custom/lifecycle_uno.py` (reset_source where cited) | UNO D0/D1 BOOTLOADER = reserved (Optiboot) → a GPIO-output claim on D0 = boot-critical conflict; D13 = warning (L LED buffer); a pin with no evidence = unknown, never valid |
| rm-2 | ESP32-C3 register ingest (IO MUX, GPIO + matrix, strap, UART0 essentials, clock enable, reset reason) from the TRM, cited; the chain reaches Register/Field on the C3 | `board/custom/registers_esp32c3.py` + `register_fields_esp32c3.py` (new), `hardware_chain_c3.py` (`_NO_REG` narrowed), taxonomy rules (C3) | GPIO2/8/9 RESET column = strap with GPIO_STRAP_REG field; a matrix route with no clock enable = conflict; download-mode pins = BOOTLOADER reserved |
| rm-3 | doors for the view: `/api/board/registers/tree?soc=`, `/api/board/registers/{name}` (detail incl. RegisterSetting + Catom assertions), `/api/board/fields/{name}/pins` | `board/register_profile_api.py` (extend) | both chips answer; deferred branches count 0 + "future" |
| rm-4 | the Registers bench view (three panels, sync), redirects from the four old pages, Workbench step + Bench tab, links from Structs/Bridges views | `board/register_profile_page.py` → `registers_page.py`, `board/board_page.py`, `workbench_page.py`, `cmod/cmod_pin_profile_page.py`; angular: bit-strip + stage-matrix components, page config | Chrome pass: pick UNO D0 → matrix shows the bootloader reservation; pick `DDRD` bit 0 → D0 highlighted; C3 GPIO9 → strap row |
| rm-5 | firmware trace: selected pin/field → Purpose → peripheral → pin → stage → RegisterSetting (init order) → atom (Catom assertion) | `cmod` doors (read-only join), page config | uno-light: LED pin → `CapabilityDefinition` "LED on command" → DDRB/PORTB settings in init order → the atom that writes them |

Acceptance (P§12) maps 1:1: (1) rm-0+rm-4 · (2) rm-0 · (3)(4) rm-3+rm-4 · (5)(6) rm-1 · (7) existing fields kept · (8) rm-5 · (9) rm-0
deferred branches · (10) every existing selftest (chain, pin view phases, register profile, lifecycle) unchanged.

## 5. Decisions — his answers 2026-10-28
- ✅ **D-rm-1 RULED:** "Rule table per chip that comes from a DataSheet" — every rule row cites the datasheet page/table it was read from.
  His addition, **deferred to a later round** ("maybe not in this round though"): a STEP-BY-STEP GUIDE that walks a person through a
  datasheet and lets them enter the rules by hand (pick the register table → classify each register's domain + role → enter field bit
  ranges, access, reset → cite the page), producing the same rule rows. Recorded as slice **rm-6 (deferred)**.
- ✅ **D-rm-2 RULED:** "keep all phases, but define groupings of them so we can constrain what we see to what is relevant per view."
  → the 7 phases stay as rows; `custom/pin_stages.py` defines NAMED GROUPINGS, and each view declares which grouping it shows:
  `lifecycle-4` (RESET = power-up+reset · BOOTLOADER = bootloader+programming+debug · INITIALIZATION = init · ACTIVE = runtime) for the
  Registers view's pin-lifecycle panel; `boot-safety` (power-up, reset, bootloader, programming) for the boot-conflict list; `firmware`
  (init, runtime) for the firmware trace and the Structs view; `all-7` for the pin view's phase mode (unchanged). A grouping is a data
  row (name, phases, purpose), so a new view adds a grouping instead of a new phase.
- **D-rm-3 (clarified, open):** today four separate pages each show a slice of this: `/display/hardware-chain` (one pin's chain down to
  its register fields), the register profile page (a chip's registers grouped by peripheral), the memory map, and cmod's pin profile page.
  The question: once the new Registers bench view shows all of that in its three panels, do those four pages (a) stay as they are, as
  separate entries, or (b) stop being separate pages — their address keeps working but opens the Registers view with the same pin or
  register already selected ("redirect"), so bookmarks and links in other pages still land somewhere useful. Recommended (b), and only
  after the new view is checked in Chrome.
- ✅ **D-rm-4 RULED 2026-10-28 — option (a), with his condition:** "a is probably fine for now, we need Uart, init, and the other stuff in
  the picture I sent before accounted for however." → the ingest scope for BOTH chips = every register and field his notebook drawing
  (HARDWARE_SYSTEM_PINS_PLAN §7) touches, through all four stages:
  | Drawing element | ATmega328P (UNO) — fields today → owed | ESP32-C3 — owed (TRM, cited) |
  |---|---|---|
  | P1/P2 outputs held HIGH (supply), LED P5/P6 | DDRB/D, PORTB/D, PINB/D fields ✅ cited | IO MUX `MCU_SEL`/`FUN_DRV`, `GPIO_ENABLE`, `GPIO_OUT`(_W1TS/_W1TC) |
  | P3/P4 inputs + pull, button | MCUCR.PUD ✅, PORTx pull-up ✅ | IO MUX `FUN_IE`, `FUN_WPU/WPD`, `GPIO_IN` |
  | button → INTERRUPT routine | EICRA/EIMSK/EIFR (INT0/1) ✅, PCICR/PCMSK0-2/PCIFR ✅ | `GPIO_PINn_REG` (INT_TYPE, INT_ENA), `GPIO_STATUS`(_W1TC), interrupt-matrix map reg for the GPIO source |
  | timestampHW (the chip's clock) | Timer2 TCCR2A/B, TIMSK2, TIFR2 ✅ (the HAL's millis timer) | SYSTIMER unit/alarm regs (the IDF tick) |
  | P7/P8 UART → polling, UIswitch | UBRR0H/L, UCSR0A/B/C, UDR0 — registers ✅ in the snapshot, **FIELDS OWED** (U2X0, RXC0, UDRE0, RXEN0, TXEN0, UCSZ0x … cited bit by bit) | UART0: `UART_CLKDIV`, `UART_CONF0/1`, `UART_STATUS`, `UART_FIFO`; GPIO-matrix routing of U0TXD/U0RXD |
  | init (configuration ordering) | `RegisterSetting phase=init` rows ✅ (uno-light); clock: CLKPR **owed**; power: PRR (PRUSART0, PRTIM2) **owed** | `SYSTEM_PERIP_CLK_EN0/RST_EN0` (UART, timers) **owed** |
  | RESET / BOOTLOADER columns | MCUSR (reset source), WDTCSR (Optiboot's watchdog reset) **owed**; Optiboot + DTR auto-reset already in `lifecycle_uno` ✅ | `GPIO_STRAP` (GPIO2/8/9), RTC reset-reason reg **owed**; download mode / USB-Serial-JTAG in `lifecycle_c3` ✅ |
  | UART-to-USB bridge chip | ATmega16U2 side: `soc_atmega16u2` + package rows ✅ (its pins on the BridgePath hops, hsp-3) | CH340 on the Elecrow S3 (external, no registers: a BridgePath hop with level 3.3 V); the C3's own USB-Serial-JTAG = `USB_SERIAL_JTAG_*` conf/status regs owed |
  | SREG (global interrupt enable, the masked windows of ipb-7) | SREG.I **owed** as a cited field | `mstatus.MIE` = CPU internal (taxonomy: mcu-internal, shown, not ingested) |
  rm-2 widens to "rm-2a UNO owed fields (UART0, CLKPR, PRR, MCUSR, WDTCSR, SREG)" + "rm-2b C3 drawing set"; everything else in either
  manual = "documented, not ingested" in the taxonomy until a firmware uses it.
- **D-rm-4 (original wording, kept for the record):** how much of the ESP32-C3's register map to type in now. The C3 Technical Reference Manual documents
  hundreds of registers across every peripheral (Wi-Fi, Bluetooth, crypto, timers, LED PWM …). Option (a) only the registers a PIN
  touches: IO MUX (a pad's function, pull-up/down, drive strength), GPIO + its routing matrix (direction, output, input, interrupt, which
  peripheral signal is routed to which pad), the strap register (boot-mode pins), UART0 (the programming/console port), the peripheral
  clock-enable register (to detect "peripheral used but its clock is off"), and the reset-reason register (for the RESET column). Option
  (b) every register in the manual. Recommended (a): it is what pin configuration and boot safety need; the rest appears in the taxonomy
  as "documented, not ingested" and gets added when a firmware uses that peripheral.
- ✅ **D-rm-5 RESOLVED by his explanation (2026-10-28):** "the capability snapshot was supposed to be pinning code to registers, that may
  be deprecated now. But the way we are switching to pin code to registers now is through the literal pins visualized on the Bench, and
  how they get tied into code because Catoms get tied to tasks and tasks go to chips, and the catom then ties assertions from the code to
  pins that can be clicked on. This way the code is tied to pins through assertions for the UI and variables in the real firmware."
  Facts checked: two things are named "register" in the code. (i) `register_map.py` + `register_rows.json` = the HARDWARE CAPABILITY
  REGISTER (`AI-Notes/designs/HARDWARE_CAPABILITY_REGISTER.md`: one row per board/adapter — chip, ISA, USB programming method, openness,
  twin …) → BoardDefinition / AdapterDefinition / Road rows. It never tied code to anything; it stays as the board catalogue (the chip
  ladder and the bench's board picker read it) and is labelled "board catalogue", not "registers", in the UI. (ii) The code → register
  tie that DOES exist: `RegisterSetting` + `RegisterFieldSetting` (board, ucd-0a/0b: "uno-button-clock writes EICRA = 0b00000101 at init",
  each field naming the claim and the task, `source_file` / `source_line`). **His model makes this the firmware-variable END of one
  chain:** Catom → task → chip (hart affinity, ipb-8) → **Catom assertion** → the clicked pin on the bench (UI side) and → the
  RegisterFieldSetting the generated firmware writes (firmware side). So `RegisterFieldSetting` gains the asserting catom as its reason
  (alongside claim + task), and a register write with no asserting catom shows as a gap — the same rule as the Structs view. No separate
  "code-to-register" route remains; the assertions are the route.
- **rm-6 (DEFERRED, his D-rm-1 addition):** the datasheet rule-entry guide (a Workbench-style walkthrough producing cited rule rows).
