# Pin twin: simulated pins for RISC-V chips, the C3 first (pt)

**The user, 2026-11-13:** "yes we want a simulator that genuinely simulates the c3 pins" and "we need to be capable of simulating
custom riscv devices anyways so this can act as a way towards prototyping that".

Owner: pol (the QEMU device + image). econ keeps hal-3b step 2 (C3 GPIO on the generated header) and reviews the device.

## 1. Why

The C3 twin (board.custom.twin_c3) runs the real flash image in Espressif's QEMU fork (esp-develop-9.2.2-20260417, commit 40edccac).
Its pin block is a stub, read from the source on 2026-11-13:
- `hw/gpio/esp32_gpio.c`: `esp32_gpio_read` answers only GPIO_STRAP (0x38), and `esp32_gpio_write` is empty.
- `hw/gpio/esp32c3_gpio.c` only sets the strap mode.
- IO_MUX (0x60009000) has no device at all. It falls to the machine's catch-all `esp32c3_io_ops`.

So the C3 lamp firmware runs `PIN_SHIM 1` (a RAM pin layer above the HAL), and the C3 chip HAL can only be checked by its bus
writes (econ's step-2 gate 2), never by a pin that moves.

## 2a. Our own chip data structure, with an overlay layer (the user, 2026-11-13)

**The user:** "We should build our own clean data structure for later on when we are building out our own custom risc-v chips
which we will need to plug into simulations. We can layer and make an overlay/interface for going between them so they act like
one device though."

### Three layers
1. **The chip (static, ours):** what the chip IS. This layer already exists in the board module as small linked rows, and is
   reused, not duplicated:
   - SocDefinition, SocPin, Peripheral, PeripheralSignal, RegisterBlock, Register, RegisterField (bits, reset, the access word)
   - RegisterAccessKind (the access vocabulary), RegisterAddressMapping
   - Every source fills these same rows: a vendor manual (hand rows, the C3 today), an SVD (svd_import), our own SystemRDL
     (rdl_import), via econ's chip description (HAL plan §4d). A custom chip is one more source, not a new shape.
2. **The behaviour (new, ours):** what a block DOES, written once per kind of block, not per chip.
   - `BlockBehaviour`: one row per behaviour kind (`pinbank` first; later uart, timer, interrupt matrix). It names the roles that
     kind needs and the rules it follows (the pin-level rule of §2).
   - **The role bindings are NOT a new table.** The HAL's chip rules (hal.custom.soc_rules RULES[soc]['roles']) already bind each
     role to its cited register / field, with the value meanings and the cite.
     - Those roles: output, direction, input, pull_up / pull_down, edge_sense / edge_mask / edge_flag; on the C3,
       INT_TYPE 1/2/3 = rising / falling / any.
     - The simulator reads that SAME binding, so the firmware generator and the simulator can never disagree about what a bit means.
     - A role the simulator needs and the HAL lacks is added THERE, and the HAL gains it too:
       - pad_input_enable: C3 FUN_IE, econ's queued digital_input_off
       - pad_function: C3 MCU_SEL, with "1 = GPIO"
       - output_route: C3 GPIO_FUNCn_OUT_SEL_CFG, with "128 = plain GPIO out"
       - interrupt_source: C3 16
     - The C3 entries are econ's C3 rows. The first two are what pol asked econ to add for gpio.output (a pad left on JTAG / USB
       never drives).
     - (Decided 2026-11-13 by pol on reading RULES: a separate BehaviourRole table would duplicate those facts.)
   - The behaviour's parameters (pin count, which roles it requires) live on the SimOverlay row (layer 3), not a separate
     PeripheralBehaviour row.
   - w1-set / w1-clear fields name the register they act on as data: `RegisterField.acts_on` (econ, 2026-11-13, cross-checked
     against the TRM / SVD words by board_acts_on_selftest). The layout export refuses an alias with a blank acts_on.
3. **The simulation binding (new, ours):** how a chip becomes one simulated device.
   - `SimulatedChip`: a SocDefinition + the simulator that carries its CPU and vendor peripherals (C3: `qemu:esp32c3`; a custom
     chip: a plain RISC-V machine).
   - `SimOverlay`: one row per address SPAN (not per Peripheral: the C3's GPIO Peripheral has two spans, GPIO and IO_MUX), saying who
     models it.
     - `vendor`: the simulator's own model, untouched. Where the simulator has no model at all (C3 LEDC, ADC: the fork's catch-all
       region answers), the row says "NOT modelled" in its reason instead of claiming one.
     - `overlay`: ours, mapped over the vendor model's span at a higher priority. Only the registers we model are mapped (as contiguous
       runs), so every other offset falls through to the vendor model with no forwarding code (GPIO_STRAP still answers from
       Espressif's code). The layout lists both the mapped runs and the passthrough gaps.
     - `native`: ours alone (a custom chip's blocks).
     - Spans with the same `device` are one instance of their behaviour (the C3's GPIO + IO_MUX spans are one `pinbank`).
     - Each row also gives the span, the reason, and the evidence that proved it.

### The interface between the layers: one exported layout
- The rows export to one **device layout** document (JSON) per SimulatedChip. It lists, per overlaid or native block: base, size,
  the registers with offsets / resets / access words / alias targets, the role bindings and values, and the passthrough ranges.
- The QEMU side is ONE generic device, `polari-block`, that loads that layout at start (`-machine esp32c3,polari-layout=FILE`;
  the esp32c3 machine does not allow dynamic sysbus devices, so `-device` would be refused: the machine creates the device when
  the property is set, maps its runs at priority 1 and wires its line to intmatrix source 16, which the stock GPIO never connects;
  unset = the stock init path, byte for byte; a custom chip's plain machine does the same from its own property). It
  interprets access words and runs the named behaviour.
  - So a new chip, or a changed register, needs a new layout, never a QEMU rebuild.
  - QEMU's own JSON parser (qobject) reads it, with no new dependency.
- The pin channel (§2) is part of the same interface: a block with the `pinbank` behaviour exposes its pins on a chardev.
- To the firmware the result is one chip: Espressif's CPU, UART, timers and flash, with our pins and pads in the same address
  space at the TRM's addresses.

### Why this split
- A custom RISC-V chip is described in layer 1 (from our RDL), reuses layer 2's behaviours, and gets a `native` binding in layer 3.
  It is simulated with no device code written for it.
- A vendor chip keeps everything its simulator already models, and we overlay only what is missing. That is the C3 GPIO / IO_MUX
  today.
- The rows are data (app-as-data), so the bench and the object pages show which simulator models which block, and why.

## 2. The shape: one generic device, driven by a chip description

**Not a C3 device.** The device is `polari.pinbank`: a QEMU sysbus device that holds a register file and interprets each register
by its **access word**. The words are the ones HAL plan §4d fixed: rw, r, w, w1-set / w1-clear (acting on another register),
r-w1c, w-strobe, rw-sc.

- **The layout is generated, not hand-written:** a header `pinbank_<soc>.h` is generated from the chip description (REGISTERS +
  FIELDS, HAL plan §4d).
  - So any source that yields a chip description gives a pin twin with zero device changes: a vendor manual (the C3 today), an SVD
    (RP2350, a LiteX SoC), or our own SystemRDL (custom RISC-V silicon).
- **Pin model roles:** a small table says which fields play which part, like hal soc_rules RULES:
  - output, output-enable, input, interrupt status
  - per-pin interrupt type / enable
  - pad input-enable, pull-up, pull-down
  - pad function select (+ the value meaning "GPIO")
  - output routing (+ the value meaning "plain GPIO out")
  - the interrupt source number
- **Reset values** come from the description. The C3's per-pad IO_MUX resets are the cited Table 5.12-1 p.174, which the SVD gets
  wrong (§4d proof 1).
- **Pin level** (roles from RULES, econ 2026-11-13: + output_enable_source OEN_SEL {gpio_enable 1}, output_driver PAD_DRIVER
  {push_pull 0, open_drain 1}):
  - driven: pad function is one of THAT pad's GPIO functions (C3: 1 everywhere, 0 too on GPIO0-3, 8-11, 18, 19, Table 5.12-1
    p.174; MCU_SEL resets to 0), routing = plain out, output enabled, giving the out bit
  - with routing = plain out (OUT_SEL 128) the enable is GPIO_ENABLE whatever OEN_SEL says: ESP-IDF writes OUT_SEL_CFG = 128
    (OEN_SEL 0) and its LED drives on silicon. That is an inference from IDF's working path, not the TRM's words (econ review,
    2026-11-13). pt-1b / pt-2 control: the light toggles under BOTH the ESP-IDF build (OEN_SEL 0) and the HAL build (OEN_SEL 1)
  - open drain drives only 0; a 1 releases the pin
  - else the externally driven level
  - else the pull
  - else `z`
  - The input register reads (level AND pad input-enable). A pad left on JTAG / USB function never drives.
- **The pin channel:** a QEMU chardev, a line protocol.
  - out: `@<virtual ns> <pin> 0|1|z` on every change
  - in: `<pin> 0|1|z`
  - Same role as the UNO twin's pin I/O, so scenarios and the bench read both alike.
- **Interrupts:** the per-pin type sets the status bit. The CPU's status register reads status AND the per-pin enable (C3:
  GPIO_PCPU_INT 0x5C = STATUS AND INT_ENA bit 0, the register ESP-IDF's ISR reads: gpio.c:517 -> gpio_ll.h:112-115). The IRQ line
  into the interrupt matrix (C3: source 16, TRM Table 8.3-1 p.204) is the OR of that CPU status. Write-1-to-clear clears it.
  - Without PCPU_INT modelled, the ISR would read 0, never clear STATUS, and re-enter forever (econ's pt-1a review): a pt-3
    blocker. Closed 2026-11-14: econ's rows (61acca05) add GPIO_PCPU_INT (Register 5.13 p.183) and GPIO_STATUS_W1TS (5.11 p.182);
    PCPU_NMI_INT is not in the TRM's register summary, so it has no row and stays the vendor's. The pinbank requires the role
    `interrupt_status_cpu` with its `from` (STATUS AND PINn.INT_ENA bit 0), and the export refuses without it.
- **Level triggers and inversion are roles** (econ: level_sense INT_TYPE 4 / 5, output_invert, enable_invert). A value no role
  names is logged by the device as unmodelled, never silently read as 0.
- **Per-pad GPIO functions are data** (pad_function.gpio_functions, Table 5.12-1 p.174); the export refuses a pad_function without
  them, so no chip silently falls back to "function 1 only".
- **Reset exceptions the composed resets cannot show** (econ, Table 5.12-1 legend p.175), for pt-2:
  - GPIO6 / MTCK `1*`: WPU = 1 when EFUSE_DIS_PAD_JTAG = 0
  - GPIO19 `0*`: pulled up by USB_SERIAL_JTAG_DP_PULLUP (1 by default) although FUN_WPU = 0
  - GPIO21 resets as U0TXD (function 0): the UART owns it

**Licence:** the fork's GPIO files are GPL-2.0-or-later, and the new device file is GPL-2.0-or-later too (compatible with the
project's GPLv3). The patch lives in the engine image's build, outside the framework tree's licence. Contributing it to Espressif is
publishing and waits on the user's go.

## 3. Phases (each with its gate)

| phase | what | gate |
|---|---|---|
| pt-0 | Build the pinned tag from source, unpatched (Espressif's own configure flags, minus the SDL UI) | the from-source binary boots the C3 light firmware (PIN_SHIM 1) with raw UART0 identical to the prebuilt binary's |
| pt-1a | The rows (§2a): BlockBehaviour / SimulatedChip / SimOverlay, seeded for the C3 (GPIO + IO_MUX overlay, the rest vendor), and the layout export reading the HAL's role bindings | every required role of an overlaid block resolves through soc_rules to a cited RegisterField (a missing one fails the export, named); every overlaid block's unmodelled offsets are listed as passthrough; the layout is deterministic (same rows -> same sha) |
| pt-1b | `polari-block` QEMU device loading the layout (`-machine esp32c3,polari-layout=FILE`), mapped as an overlay with passthrough; default off | with it off, pt-0 is unchanged; with it on, PIN_SHIM 1 is still UART-identical; econ's measured bus-write logs fold to the same final register state on the device's own read-back; `info mtree -f` shows polari-block answering every mapped run in BOTH spans (GPIO over esp32.gpio, IO_MUX over the esp32c3.iomem catch-all, both priority 0 in the source) and the vendor at GPIO_STRAP (econ, 2026-11-14) |
| pt-2 | pin level + the chardev channel | the PIN_SHIM 0 builds (ESP-IDF driver and the HAL) both show the LED pin's edge on SET_LED (the measured check of the OUT_SEL 128 inference: IDF writes OUT_SEL_CFG whole, OEN_SEL 0, MCU_SEL twice; the HAL per field, OEN_SEL 1, MCU_SEL once), and both see the button (pt-3); a pad left on a non-GPIO function shows NO edge (negative control) |
| pt-3 | pin interrupts into the interrupt matrix | driving the button pin low fires the firmware's ISR (ESP-IDF path, PIN_SHIM 0); the toggle is seen on UART and on the LED pin; no edge = no interrupt (control) |
| pt-4 | Twin integration: twin_c3 / c3-run `--pins`, the scenario runner reads the channel; the image installs `qemu-system-riscv32-polari` beside the prebuilt binary | the C3 light acceptance runs on PIN_SHIM 0; econ's step-2 gate 4 becomes a run |
| pt-5 | Prototyping path for custom RISC-V: a `native` SimulatedChip described by our own RDL (toyperiph -> rows -> layout), on a plain RISC-V machine | a generated layout for a non-Espressif description boots in a minimal RISC-V machine with the pin channel working |

## 4. Evidence so far (2026-11-13)
- Source: espressif/qemu tag esp-develop-9.2.2-20260417 (commit 40edccac), shallow clone, 204 MB.
  - The user approved the download 2026-11-13.
- The prebuilt binary in prf-esp-engines:noble reports `esp_develop_9.2.2_20260417`. It holds the esp32c3.gpio type strings, so
  it is the same device code as the source read here.

### pt-0: PASSED (2026-11-13)
**Build:**
- Builder: ubuntu:24.04 with Espressif's native configure flags (.github/workflows/scripts/configure-native.sh), minus SDL (UI only), plus
  `--enable-fdt=system --disable-download`.
- Build dependencies, all at the source's pinned revisions:
  - keycodemapdb f5772a62
  - berkeley-softfloat-3 b64af41c
  - berkeley-testfloat-3 e7af9751 (the fp test suite is built whenever TCG is on; there is no switch to skip it)
- Result: `QEMU emulator version 9.2.2 (polari-stock-esp_develop_9.2.2_20260417)`.

**Runtime gap:** the engine image lacks libfdt, so pt-4 installs `libfdt1`.

**A/B:**
- Inputs:
  - Image: the C3 light flash image, PIN_SHIM 1, sha256 b5b6635b, identical to econ's independent build.
  - Params: 3 presses, window 1150 ms; `--icount 3`.
- Arms: prf-esp-engines:noble (the prebuilt binary) vs a test image of it with the from-source binary in its place.
- Result: both reach @END with presses=3 led_on=1, the LED written at 300 / 450 / 600 ms.
  - UART0 is identical: 1809 B, sha256 a412df4e….
  - The trace is identical: 21 lines, sha256 ec174f51….
- So the from-source build is a faithful base for the patch.

### pt-1a: BUILT (2026-11-13, dev-hal-3b, board_sim_layout_selftest 16/16)
- Rows: board.custom.sim_bindings -> BlockBehaviour (`pinbank`: 13 modelled roles + the value role interrupt_source),
  SimulatedChip (`esp32c3-qemu`), 9 SimOverlay rows (GPIO + IO_MUX overlay as one `pins` device; UART0, SYSTIMER, INTMTX, SYSTEM,
  RTC_CNTL vendor, each with the esp32c3.c line that maps it; LEDC and APB_SARADC vendor, "NOT modelled").
- Export: board.custom.sim_layout.layout('esp32c3-qemu') -> 76 registers (54 GPIO, 22 IO_MUX; GPIO_STRAP left to the vendor), every
  role resolved on all 22 pins from hal soc_rules, sha 604ccae1… (deterministic under reversed row order).
- Resets: a hex printed reset is used and must agree with its fields; a reset printed in words (IO_MUX, per pad from Table 5.12-1)
  is composed from the fields and the layout says so.
- Controls (all refuse, named): a role absent from RULES, a role marked missing, a role naming a field that is not a row, a set alias
  with no acts_on, a field reset contradicting its register's printed reset.

### pt-1b: PASSED (2026-11-14)
- Patch: hw/misc/polari_block.c + include/hw/misc/polari_block.h + a 27-line esp32c3.c hunk (the `polari-layout` machine
  property; unset = the stock init path) + meson. GPL-2.0-or-later. Built with `-Werror` in polari-qemu-builder:noble on the
  pinned tag. Kept on a local branch of the scratchpad build copy (commit f4e0585, patch sha256 75aa0174…); pt-4 moves it into
  the engine image's build. Not sent to Espressif (the user's call).
- **Measurement correction to pt-0.** polari-c3-run polls for `@END` every 50 ms and then kills QEMU, so the bytes after `@END`
  depend on host timing. The UNCHANGED stock binary gave 1717 / 1809 / 1901 B over three runs, so pt-0's whole-file sha match was
  luck. The deterministic measures:
  - the trace through the `@END` line;
  - every UART capture is a byte prefix of one stream.
  pt-0 still holds on both.
- Arms (pt-1b gate image prf-esp-engines:pt1b-polari, the pt-0 inputs):
  - A: stock from source;
  - B: the polari-block build, no layout;
  - C: the polari-block build with the layout.
  All 9 runs (A, B, C + 3 repeats each of A and B) give the trace through `@END` sha f8495d14…, and every UART capture is a prefix of
  one stream.
- Fold: the device run's own traced writes (152 inside the layout; 3 to GPIO_FUNC{n}_IN_SEL registers with no rows, which
  went to esp32.gpio) folded through the access words in Python equal the device's read-back on all 78 registers (25 changed
  by the firmware).
  - econ's stock-measured logs cannot be the reference: the firmware read-modify-writes IO_MUX, the stock catch-all reads 0 and
    the device reads the real resets (FUN_DRV 2, FUN_IE), so the written values legitimately differ. The write addresses and
    count match (152 + 3).
- `info mtree -f`: polari-block at priority 1 over esp32.gpio (8 runs; GPIO_STRAP's 0x2c-0x3b stays esp32.gpio) and over the
  esp32c3.iomem catch-all (IO_MUX 0x60009004-0x6000905b).

### pt-2: PASSED for the output side (2026-11-14)
- Patch 40b75b4 (patch 0003 sha256 f364d603…), on pt-1b's two commits: the pinbank in polari-block, plus the pin channel
  (`-chardev …,id=pins -global polari-block.chardev=pins`).
- Inputs: econ's four gate-2 images (isle-core:~/collab/c3-light-images, SHA256SUMS verified), variant esp32c3-light with
  LED GPIO0, SENSE GPIO1, BUTTON GPIO3 (econ's correction: NOT GPIO4). Stimulus: SET_LED 1, then SET_LED 0 over UART, paced
  by the firmware's own @TEL lines (the light tests' command_run plan).
- Results (pin channel, GPIO0):
  - IDF build, PIN_SHIM 0 (OEN_SEL 0): z -> 0 at 22.0 ms (setup) -> 1 at 542 ms (SET_LED 1) -> 0 at 1142 ms (SET_LED 0).
  - HAL build, PIN_SHIM 0 (OEN_SEL 1): z -> 0 at 21.9 ms -> 1 at 442 ms -> 0 at 968 ms.
  - So the OUT_SEL 128 inference is MEASURED: both enable paths drive the LED.
  - Controls, no edge on GPIO0 although the firmware's own reports say led_on went on and off:
    - the PIN_SHIM 1 build (its LED lives in RAM);
    - the HAL build with a layout whose pad 0 lacks GPIO function 1 (the "pad not on GPIO" control).
  - Stock arm: no channel, the same reports.
  - At setup SENSE (GPIO1) reads 0 through its pull-down and BUTTON (GPIO3) 1 through its pull-up. The reset levels follow
    Table 5.12-1: GPIO9 and the flash pads 12-17 pulled up, GPIO20 / 21 pulled up, the rest floating.
  - Unmodelled (logged, counted): GPIO4 carries peripheral signal 9 (OUT_SEL_CFG 0x9) in both builds.
- GPIO4's signal 9 is U1TXD_out (TRM Table 5.11-1): the light's UART1 trace TX (board_pins.h POLARI_TRACE_TX_GPIO 4), which the
  fork serves as the second -serial. Logged and not driven is right (econ).
- econ's review (commit 691d6b5, patch 0004 sha256 cff07127…):
  - Inputs can be STAMPED: "@<virtual ns> <pin> 0|1|z" is applied by a QEMU_CLOCK_VIRTUAL timer, so a press lands on the same
    instruction every run. Measured: SENSE driven at @700000000 and released at @800000000 shows at exactly those ns, and two
    runs give the same pin-log sha (5e7ff6a9).
  - A pad on a non-GPIO function is logged unmodelled once. At reset these are exactly Table 5.12-1's function-0 pads
    (4-7, 12-17, 20, 21).
  - Contention (the chip drives one level, the outside the other) is a guest error, logged once; the chip's level is kept.
- econ's gate image: a 29 MB build context (FROM prf-esp-engines:noble + a copied libfdt.so.1), not a 2 GB image tar.

### pt-3: PASSED (2026-11-14)
- Patch 168c032 (patch 0005 sha256 a3e6873d…). Edges / levels go to STATUS, then to the CPU status (PCPU_INT = STATUS AND INT_ENA
  bit 0, from the layout's `from`), then the OR goes to intmatrix source 16, re-evaluated after every write. A stamped input that
  arrives late is logged (econ).
- Gate (pt3_gate.py, econ's images, presses stamped on GPIO3 with the shim's own timing: 300 / 450 / 600 ms, held 80 ms):
  - IDF build and HAL build, PIN_SHIM 0: `@END presses=3 led_on=1`, 3 interrupts, the LED toggled at 300 / 450 / 600 ms. That is
    ESP-IDF's real GPIO ISR -> task -> LED path, and the same times the PIN_SHIM 1 build gave in pt-0.
  - Repeat of the HAL arm: the trace through `@END` is identical (aba2c140).
  - Controls: no press -> `presses=0 led_on=0`, 0 interrupts, no LED edge; presses on GPIO7 -> the same.
- econ's review (91cbb57, patch 0006 sha256 d91c5a53…):
  - A reset now lowers the line into the interrupt matrix (clearing the device's own record never reached it).
    - Control NOT yet exercised: a reset while the line is high needs firmware that enables a pin interrupt and never
      clears it. That is pt-5's bare-C firmware (then `system_reset` from the monitor, and the line must read 0).
  - Enable bits past the CPU bit (C3 INT_ENA bit 1 = NMI) are logged unmodelled: TRM v1.1 deleted GPIO_PCPU_NMI_INT_REG and
    its map.
  - The level-trigger re-set is cited as inferred from ESP-IDF gpio.c:491-504; the TRM is silent.
  - The gate re-run is unchanged.
- econ's gate 2 on arm C (08a85749, taken into dev-hal-3b): every build writes the same addresses as under the stub, the same
  number of times; the IDF and HAL builds end equal except GPIO_FUNC0_OUT_SEL_CFG.OEN_SEL (0 vs 1). The device block is now the
  value reference in light_pins_mmio.json.

## 5. Open (the user's call)
- Contributing the device to Espressif's fork (publishing).
- Whether the from-source binary eventually replaces the prebuilt one, or stays beside it.
