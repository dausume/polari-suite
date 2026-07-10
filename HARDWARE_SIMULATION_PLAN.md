# Hardware Simulation Stack — Renode / Verilator / ngspice

**Written 2026-07-10 from Dustin's direction (design goal: open source
as much as possible; Renode as the central simulator "for the first
several years of the hardware ecosystem"). PLANNED — phases below are
suggestions, nothing auto-builds.** Companion to
`GRPC_BRIDGE_PLAN.md` (the transport that already works, grpc-2/j2
live-verified) and the polari-hardware-architecture direction (MCU +
FPGA layered stack, Hardware Runtime register map).

Correction recorded: there is **no JavaFX** anywhere in this stack —
the host runtime is the headless Polari Hardware Bridge (generated
Java app, grpc-j1); human eyes are the Angular frontend via STOMP.

---

## 1. The open-source simulator stack (the decision)

| Layer | Tool | License | Role |
|---|---|---|---|
| MCU / SoC simulation | **Renode** | MIT | THE ORCHESTRATOR: CPUs, RAM, flash, SPI/UART/GPIO/DMA/interrupt controllers, whole boards (STM32, RP2040-class, RISC-V), multi-machine emulations |
| FPGA logic | **Verilator** (or Amaranth's simulator for Amaranth designs) | LGPL/Artistic (tool boundary) | Renode does NOT simulate Verilog/VHDL — verilated models fill that hole |
| Circuit / analog | **ngspice** (+ PySpice as the OO layer) | modified BSD / GPLv3 (worker boundary) | transistor/LED/power-electronics level; the target of the multiscale materials ladder |

Key architectural fact: Renode ships a **first-class Verilator
co-simulation integration** ("verilated peripherals") — an HDL block
is compiled by Verilator into a shared object and attached to the
Renode platform behind a bus/SPI/UART connector. So "MCU firmware
writes SPI → Renode forwards the transaction → verilated FPGA
registers update → response returns" is a supported flow, not an
invention. Renode is the conductor; Verilator plays the FPGA part;
ngspice sits below/beside for analog questions.

Every layer of the resulting tower is open source:

```
Angular frontend (STOMP)          ← eyes
Polari backend (object tree)      ← the OO simulation surface
gRPC bridge (:3002, grpc-2)       ← proven transport
Polari Hardware Bridge (Java)     ← headless host runtime, grpc-j1
Renode                            ← MCU + orchestration
Verilator                         ← FPGA logic
ngspice                           ← circuits
```

---

## 2. Where this bolts onto what already exists (REUSE, do not rebuild)

- **`DevicePort` seam (grpc-j1)** — read packet / send packet, with
  exactly two implementations today (`SimulatedDevice`,
  `SerialCdcPort`). Renode's entry point is ALREADY BUILT: Renode
  exposes a simulated MCU's UART as a **host pty**, and
  `SerialCdcPort` is plain file I/O on a tty path. Flipping the
  bridge's `source=serial` knob at a Renode pty (the "transition
  rehearsal" named in GRPC_BRIDGE_PLAN grpc-j2) IS the Renode
  integration, zero bridge changes expected. What's missing is only
  the firmware inside Renode (phase hwsim-1).
- **The `configure` knob act** (`/api/grpc/bridges/{name}`) — the
  sim→Renode→real ladder is one knob per rung: `source: simulated`
  (built-in synthetic MCU) → `serial` at a Renode pty → `serial` at
  /dev/ttyACM0. Nothing above the seam changes; that property is the
  whole point and was proven live 2026-07-10.
- **"Send this object instance to the hardware and it acts"** — this
  top-level semantic ALREADY WORKS: grpc-j2 proved REST row update →
  Commands stream → device applied it → telemetry echoed the new
  state. The object row is the device's digital twin; hardware
  becomes a lightweight object-oriented simulation exactly as
  intended. Renode/Verilator only deepen what sits behind the seam.
- **Hardware Runtime register map** (hardware-architecture memory:
  0x0000 Device ID … 0x1000 device data) — this is the vocabulary the
  universal device interface (section 3) and grpc-4's
  `HardwareSignalDefinition` (channel/register) already agree on.
- **msci engines + EngineModelOperation + material objects** — the
  multiscale ladder (section 4) is new LEVELS on existing machinery,
  not a new framework. The wax-ferrite + CNT semiconductor study
  (percolation, p/i/n frontier orbitals) is the natural seed dataset.
- **Sidecar/worker pattern** — Renode (.NET/mono), Verilator
  (C++ toolchain), ngspice are heavy deps: they ride Debian worker
  services exactly like msci-engines / cad-engines (`/capability`
  honesty, swarm-pinned), never the Alpine backend image.
- **MUX intuition** (Dustin's note): a multiplexer = select bits
  routing one of N inputs to an output. Our software mirrors: the
  `transport_preference` knob is the select on {stomp, grpc, both};
  the bridge `source` knob is the select on {simulated, serial(pty),
  serial(real)}; an FPGA-side mode MUX (sim vs hardware inputs) is
  the same idea in fabric and belongs in the hwsim-3 register block.

---

## 3. The universal hardware object model (the destination)

One abstract interface, implemented by every backend — simulator or
silicon — so nothing above it can tell the difference:

```
Device:
    readRegister(address)  -> value
    writeRegister(address, value)
    sendPacket(packet)           # PolariPacket, the universal frame
    receivePacket() -> packet
    reset()
```

- **Two levels, cleanly split**: `DevicePort` (packets — transport)
  stays as-is; `Device` adds register semantics (application level,
  the Hardware Runtime map). A packet-only backend (today's
  SimulatedDevice) simply refuses register calls honestly.
- **Implementations over time**: `SimulatedDevice` (built-in, today) →
  `RenodeDevice` (pty/Renode telnet-monitor) → `VerilatedDevice`
  (register block behind Renode) → `SerialCdcPort` (real board) →
  (eventually) own SKY130 silicon. Choose ANY iCE40 FPGA + MCU pair
  per the hardware-tier table; the interface is the contract.
- **Object coherence**: every device/simulator is a row in the object
  tree (`RenodeMachineDefinition`, `VerilatedBlockDefinition`,
  `SpiceCircuitDefinition`…), configured AT the object, exposed over
  the same CRUDE/gRPC surfaces as everything else. Capabilities are
  knobs + evidence-bearing suggestions, never auto-applied.

---

## 4. Multiscale electronics ladder (materials → SPICE)

The second goal: simulated materials plug into semiconductor sims,
those plug into LED/transistor sims, and the result is ABSTRACTED
into something SPICE can run.

```
L: DFT/FEM material sims (msci, exists)      e.g. CNT p/i/n frontier orbitals
      ↓ property extraction (bandgap, mobility, carrier conc., permittivity)
L+1: semiconductor/junction models            diode & transistor physics
      ↓ compact-model fitting
L+2: SPICE .model card (an OBJECT on the material — object coherence)
      ↓ ngspice via a PySpice worker engine
L+3: circuit sims (LED driver, H-bridge, laser PSU) → results as objects
      ↓
L+4: the same circuits Renode/Verilator devices pretend to drive
```

Each rung is a derived representation LINKED to its source material
row (like msci-28's detail view already links levels), with honest
provenance: a .model card generated from simulated properties says
so, and deviations between rungs are suggestions to re-derive, not
silent overwrites. This makes "we simulated this wax-ferrite/CNT
blend, here is the LED it could drive" a traceable chain.

---

## 5. Suggested phases (branch per phase, selftest green, live-verify)

- **hwsim-1 — Renode MCU twin**: **✅ BUILT + LIVE-VERIFIED 2026-07-10
  (framework branch dev-hwsim-1-renode), hours after this plan was
  written — Dustin's "start with making hardware work".** SimRigState
  twin class (seeded); generated per-class C header (grpc-j3 sliver,
  `c_twin.py` + `/api/grpc/exposures/{class}/c-header` — firmware
  knows ONLY its one class); 4KB bare-metal STM32F4 firmware; Renode
  1.16.1 ran the ELF with USART2 on a host pty; the EXISTING bridge
  (`source=serial`) needed ZERO changes. Real-firmware telemetry
  updated the seeded row (matched by name, 220 STOMP notifications);
  REST PUT pwm/led rode Commands down, firmware applied ACTUATORS
  ONLY (its sensors kept living) and echoed `status=commanded` back;
  schema stayed stabilized, zero deviations (bool-narrowing fix on
  Push). Toolchain: Renode portable + xPack arm-none-eabi-gcc in
  ~/tools (no sudo). Original spec: minimal open
  firmware (C, later generated per grpc-j3's `<class>_packets.h`)
  that speaks PolariPacket over UART; run it on a Renode STM32/RISC-V
  platform; expose the UART as a pty; point the EXISTING sim-rig
  bridge at it (`configure source=serial serialDevice=<pty>`).
  Acceptance: the grpc-j2 loop repeats byte-for-byte but frames come
  from REAL COMPILED FIRMWARE on a simulated MCU, and a Commands-down
  write flips firmware state (visible in subsequent telemetry).
- **hwsim-2 — Renode as data**: `renode-engines` Debian worker
  (msci-engines idiom); `RenodeMachineDefinition` treeObject (platform
  .repl, firmware image, pty path, running state) + generated .resc;
  knob API `/api/hw/machines` (create/start/stop/download); honest
  `/capability`.
- **hwsim-3 — Verilator co-sim**: **✅ BUILT + LIVE-VERIFIED
  2026-07-10 (framework dev-hwsim-1-renode 8cfb85c).** The register
  map is DATA (knobs/no-code-states directive): `hwfpga/` module —
  RegisterMapDefinition + RegisterDefinition rows seed the Hardware
  Runtime map; Verilog core, sim wrapper, Renode harness, firmware C
  defines, and a self-checking bench ALL generate from the rows
  (`/api/hw/registermaps`). Verilated via oss-cad-suite; attached as
  CoSimulated.CoSimulatedPeripheral (.so library mode, DOTNET Renode
  portable — mono crashes on native interop) at 0x70000000.
  LIVE: firmware read DEVICE_ID 0x504C0001 / VERSION 0x10000 from
  REAL verilated logic into Polari rows; REST PUT {commands: 0xCAFE,
  config: 777, mode_mux: 1} rode Commands → firmware → AXI writes →
  readback proved write-through AND THE MUX SWITCHED (STATUS input
  byte froze at the hw-pin pattern 0xB7); heartbeat live throughout;
  schemas stabilized zero deviations. selftest_fpga 8/8 (real
  verilated bench). Original spec: the Hardware Runtime register
  block as a small Verilog design; verilated .so attached to the
  Renode machine; firmware reads/writes FPGA registers; register
  values ride telemetry; sim/hardware-input mode MUX included.
  (SPI transport deferred to real boards — the block rides the
  memory bus in Renode, the synthesizable core is bus-agnostic at
  the register level.)
- **hwsim-led — the 4x4 LED grid demo**: **✅ BUILT + LIVE-VERIFIED
  2026-07-10 (fw 1133669).** "Send the object and it lights up":
  LED_MATRIX is a RegisterDefinition ROW (generic `pins_out` knob →
  generated `<register>_pins` output port, no per-device generator
  code); `LedMatrix4x4State.driver` is THE PROFILE KNOB ('fpga' |
  'mcu') — a field update switches the path, same firmware. LIVE:
  0xA5A5 checkerboard through the FPGA (pixels read back from
  verilated silicon), 0x0F0F stripes via the MCU RAM path on the same
  rig, and `sim_rig_mcu_only.resc` (NO FPGA attached) where the boot
  probe silences FPGA telemetry and honestly downgrades fpga-driver
  requests — diagonal 0x8421 lit MCU-only. Schemas zero deviations.

- **hwsim-nocode — generalize via no-code (NEXT, planned 2026-07-10;
  do in a FRESH session):** make the LED pattern repeatable for ANY
  device capability without touching Python/C/Verilog by hand:
  1. **FieldRegisterBinding rows** (class+field ↔ map+register,
     direction telemetry|command|both, scale/offset) — the firmware's
     per-class command/telemetry routing GENERATES from these rows
     the way grpc-4's HardwareSignalDefinition intends; deadband
     rides here too. The hand-written LedMatrix4x4State handling in
     main.c becomes the first generated instance (regression: the
     LED loop must re-pass byte-identically).
  2. **Generated firmware main** — `renode_twin/main.c` splits into
     a static core (uart/tick/rx loop) + a generated
     `bindings_generated.h` (msg_type dispatch + register I/O per
     binding row), served per-rig like the packet headers.
  3. **The no-code chain end-to-end**: /createClass (exists) makes a
     new state class → stabilize+expose knobs → add register rows +
     bindings → download regenerated firmware/HDL/bridge — a new
     hardware capability with ZERO hand-written code. Acceptance:
     drive a second demo (e.g. a servo angle or 7-segment register)
     created entirely through APIs.
  4. **Frontend tie-in (with Dustin)**: a small no-code editor state
     for binding rows + a live LED-grid widget riding the existing
     STOMP notifications.

- **hwsim-4 — universal Device interface**: register-level abstraction
  over {renode, verilated, serial}; binds grpc-4's
  `HardwareSignalDefinition` (register → object field, deadband).
  This phase merges with grpc-4 rather than duplicating it.
- **hwsim-5 — SPICE ladder**: **✅ FIRST RUNG BUILT + LIVE 2026-07-10
  (fw 89a71f6): the simplest device = the CNT-doped sol-gel composite
  RESISTOR (current limiter for the FPGA-driven LED grid).**
  `electrodevice/` module: ElectronicDeviceDefinition derives by
  EXECUTING the msci percolation sim (cnt-solgel-percolation →
  σ_eff 227.27 S/m @ 2 vol% → R = L/(σA) = 628.6 Ω), provenance +
  the sim's validity note stamped on the row AND in the .subckt
  comments (versioned SpiceModelCard rows). ngspice rides the Alpine
  backend image (capability-honest); circuit 'fpga-pin-led' = one
  branch per grid pin, pixels default to the LIVE LedMatrix4x4State
  row. LIVE: the 0x8421 diagonal → 4 LEDs at 2.6123 mA each, verdict
  all-leds-in-range, CircuitRunResult row; out-of-range yields a
  geometry/volumeFraction knob suggestion. selftest 9/9 (real
  ngspice legs). NEXT rungs: capacitor (dielectric sol-gel rows →
  C = εA/d, RC + FPGA PWM transient), diode (doped-Si / CNT p-n from
  the DFT frontier-orbital rows → .model D card), then PySpice
  worker if in-backend ngspice ever outgrows Alpine.

Ordering note: hwsim-1 is the highest-leverage next step (it converts
the proven j2 loop from synthetic packets to real firmware with ~zero
bridge changes), but grpc-3/grpc-4 from GRPC_BRIDGE_PLAN.md remain
valid parallel tracks — grpc-4's signal definitions are what hwsim-3/4
bind to.

## Open-source audit note
Renode MIT; Verilator LGPL-3/Artistic-2 and ngspice modified-BSD /
PySpice GPLv3 — all invoked as tools/worker services (process
boundary), never linked into Polari; generated firmware/HDL stays
ours under the repo license. Repos are PUBLIC — simulator configs and
generated HDL must carry no secrets.
