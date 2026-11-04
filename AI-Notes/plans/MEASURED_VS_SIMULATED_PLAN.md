# Measured vs simulated: binding real scope and multimeter readings to the simulation (msv) - plan 2026-11-04, PLAN ONLY

The user (2026-11-04): "we will want to make the capability to bind real oscilloscope and multimeter readings to the simulation data testing, to act
as a way to proof out that the physical device was done properly and/or to gauge what real soldered device variance is from the simulated device, and
we will want ways of recording acceptable real variances vs mistakes." Then: "manual entry and devices that tie in directly via usb should be
accounted for."

Three jobs, one mechanism:
1. **Proof of build**: the soldered unit behaves like the simulated Bench Solution at its nodes (a hardware confirmation earned by measurement).
2. **Variance**: how far real units sit from the simulated one, per measurement point, across units.
3. **Variance vs mistake**: every out-of-band reading is ruled on by a person. A reading is either an accepted variance (with its reason and scope) or a
   mistake (with a likely cause, the rework, and a re-measurement). Nothing is accepted automatically.

---

## 1. What exists (reuse it, do not rebuild it)

- **Nodes = end-state requirements** (bss). Each node already carries the twin's fields, its pin levels, and since bss-12 an **electrical circuit**
  collateral from the cst slice (ngspice .op: pin currents, the rail, VCC-GND). Those are exactly the multimeter's predictions.
- **Confirmations** (cmod/custom/confirmations.py): `from_record` already takes a hardware record (fields + duration) and judges it against the same
  requirements. It is voided on rebuild. msv extends what a hardware record can carry. It does not add a second confirmation path.
- **Instruments** (osc-0..8): `Instrument` rows with cited specs, `InstrumentEndpoint`, `ScopeChannel.probing` = a bench line, and the canonical
  `WaveformCapture` with `source` real | emulated | replay. Bench units and probes exist (placement.py). The scope client speaks raw-socket SCPI.
  PyVISA is optional (D-osc-6) and is refused by name when absent.
- **Twin captures** (bss-9/10/14): pin lines and fields as WaveformCapture rows (source twin), the VCD on read, and the run diff. The real capture
  lands in the same row class, so the diff and the VCD extend to real vs twin.
- **Fault stimuli** (bss-11): bounce knobs BOUNCE_EDGES / BOUNCE_SPAN_S are cited guesses (Ganssle). A real capture of the real button measures them.
- **Temperature** (tmp): a circuit at a temperature, so a band can be widened by the measured ambient.

## 2. The rows (small, by level, referencing; children named after their parent)

- **BuiltUnit**: one physical soldered or assembled device. It holds the Bench Solution, the layout, the hex sha256 flashed on it, who built it,
  and the build method (breadboard / perfboard / wire wrap / PCB). It never holds readings.
- **MeasurementPoint** `<node>-mp-<n>`: what to measure in a node's state, DERIVED from the node (D-wm-2's rule: derived, with any hand-drawn
  points kept beside it):
  - its quantity: V dc | I dc | R (power off) | continuity | a waveform feature (level, edge delay, pulse width, rise time, bounce count, period)
  - where: a net or pin, or a pair of nets for V and R
  - the instrument kind it needs
  - the prediction: nominal plus the band, each with its source (cst .op, twin, ngspice transient)
- **MeasurementReading** `<unit>-<mp>-r<n>`: one real value. It holds:
  - the instrument unit, and how it got in (§3)
  - the raw value with its unit and range, or the WaveformCapture acquisition
  - who took it, when, and the ambient if known
  - the evidence: a photo / file sha256, or the instrument's reply verbatim
  - the firmware fields reported over serial at the same moment, when the board reports them. That proves the board was in the node's state, not
    just something a person says.
- **ReadingJudgement**: derived on read, never stored. It gives the delta and the band the reading falls in (§4).
- **VarianceRuling** `<reading>-rule`: a person's ruling on an out-of-band reading. Each ruling carries who made it, the words, and the evidence. The
  rulings are:
  - **accepted-variance**, with a scope of this unit | this design | this part lot (D-msv-3)
  - **mistake**, with a cause: cold joint | bridge | open | wrong part value | reversed polarity | wrong pin | damaged part | other
  - **measurement-error**, which sends you to re-measure
  
  A mistake is closed only by a later in-band reading of the same point on the same unit. The rework words go in between.
- **InstrumentAccuracy** on the `Instrument` row: the cited accuracy per range and function, e.g. ±(% of reading + counts). A real DMM needs its
  datasheet read first, as for the scopes. Input impedance and burden voltage come from the same datasheet, because the meter is part of the circuit
  (§4).

## 3. How a reading gets in (the user: manual entry and direct USB)

One reading row, whatever the path. `MeasurementReading.via` says which path it came by. Every path refuses by name when its dependency is absent.

| via | what | how | first instruments |
|-----|------|-----|-------------------|
| **manual** | a person types the value off any meter or scope screen | a door-form on the node's Workbench card, one field per measurement point. It is pre-filled with the point, the unit and the expected range, so entry is just the number. An optional photo of the display goes in the file store with its sha256. The instrument model is picked from the bench's units so that its accuracy applies. | any instrument at all, including a $10 handheld. This is the floor, and it is built first. |
| **usb-scpi** (USBTMC) | bench DMMs and scopes that enumerate as USB Test & Measurement class devices | PyVISA + pyvisa-py over libusb (D-osc-6, optional imports). The same SCPI client as LAN, with only the transport changed. A DHO804 over USB is the same profile as over LAN. | DHO804 (owned/planned), bench DMMs with USBTMC, to be read before seeding |
| **usb-serial / usb-hid** | handheld DMMs with a USB cable (a serial bridge or HID) and cheap scopes that dump over serial | libsigrok / sigrok-cli (GPLv3, compatible with [project-license-gplv3]). Its per-device drivers decode the meter's protocol, so Polari does not write meter protocols itself ([use-established-solvers]). The DSO138's serial text dump is osc-7's adapter. | UNI-T / Owon / Victor style handhelds listed by sigrok, to be checked against sigrok's supported-hardware list before claiming any one |
| **lan-scpi** | what exists today (osc-3) | the raw socket :5555 | DHO804 over LAN |

**Where the USB device is plugged in.** A meter in the user's own machine is read by the Polari Bridge / app shell on that machine. That is the JavaFX
side, and USB there is Codex's area: [codex-collaboration]. A meter on an isle node is read by a small engine service on that node, the way
scope-engines is. In both cases, the backend sees an `InstrumentEndpoint` with transport usbtmc | sigrok:<driver> | serial, and a USB device is never
reached by guessing a path. Udev and dialout permissions follow [pol-core-usb-serial]. The first USB path proven end to end is whichever meter the
user owns (D-msv-2).

**Live readings.** A USB meter streams. A reading is KEPT only when the person presses "take" or a trigger condition holds (stable for N samples
within the meter's own resolution). The stream itself is not recorded, the same rule as bss's transient data.

## 4. Bands: what counts as variance and what is suspicious

A reading is judged against nested bands, all derived and none hand-typed:

1. **Instrument band**: the meter's cited accuracy at the range used, plus the scope's vertical accuracy and the timing of one sample. A reading
   inside it matches the simulation.
2. **Loading**: the instrument is put into the ngspice deck (DMM input impedance in V mode, burden in A mode, the 10x probe as 10 MΩ‖C). The
   nominal is then what the meter should read, not what the bare circuit does. The deck says so.
3. **Tolerance band**: ngspice over the parts' cited tolerances (resistor %, LED Vf min..max from its datasheet, the rail's regulator range, the
   chip's pin output resistance from the cited V_OH/V_OL tables). This is the variance the design allows on any correct build (D-msv-4).
4. **Temperature**: widened by the tmp arc when the ambient is given.
5. **Accepted variances**: earlier VarianceRulings whose scope covers this reading.

A reading outside all of them is **unexplained**. It does not count toward proof of build and it needs a ruling.

**Telling a mistake apart: fault signatures.** For each measurement point, ngspice is also run with the usual build faults injected at the parts on
that net: an open joint (1 GΩ), a bridge to each neighbour net (0.1 Ω; the neighbours come from the layout's adjacency, and from wm's wire routes
once those exist), a wrong value (the E12 neighbours), reversed polarity on polarised parts, and a wrong pin (off by one on a header). An
unexplained reading is ranked by which fault predicts it best across all of the unit's readings so far. The ranking is a suggestion with its
evidence ([knobs-and-suggestions]). The person still rules. A single faulty part normally moves several points at once, so the ranking gets sharper
as more readings come in.

**Scope readings** are aligned to the twin run by the first stimulus edge: the button press on PD2 is the trigger, and the twin's run has that edge
at a known cycle. Features are compared, not raw samples: levels, edge delays (stimulus to LED), bounce count and span, rise time against the
spice transient. A real capture of the real button gives a MEASURED bounce. It can replace the cited BOUNCE_* knobs for that unit's switch part, with
its source said, which closes bss-11's guess.

## 5. Proof of build and population variance

- **Hardware confirmation by measurement**: `from_record` takes a unit's readings at a node. The node is confirmed by hardware when the firmware
  fields meet the requirements AND every measurement point of that node is in band or ruled accepted. An open mistake blocks it (D-msv-5). It is
  voided on a rebuild (another hex) or when the unit is reworked after the reading.
- **Population**: across built units, the spread per measurement point (n, mean, min..max, sigma once n >= 5) against the tolerance band. Two
  findings matter:
  - units in band but far from their peers (a knob, off by default)
  - a design whose real spread sits outside the simulated tolerance band, which means the model or a cited part figure is wrong. That becomes a
    suggestion to re-read the part's datasheet or to correct a figure, never a silent change.
- **Views**: the Hardware Events page gets a "Measured" tab per node: points, readings, bands as a range chart, and rulings. It uses sci-xy-chart
  through a GraphDefinition, with no raw JSON on screen. The Workbench gets a "measure this node" walkthrough: put the board in the node's state
  (the path's stimuli in words: press, hold, release), then probe here, using the layout view's net highlight.

## 6. Decisions (recommended first; each is the user's)

- **D-msv-1 order of acquisition paths.** Recommended: manual first (msv-0, works with anything), then USB via sigrok for handheld DMMs plus
  USBTMC via pyvisa-py for bench gear (msv-3), and LAN stays as built. Alternative: USB first, if a USB meter is already on the bench.
- **D-msv-2 which instruments you own** (your fact): DMM make and model, whether it has a USB/serial port, and the scope. Each gets an Instrument
  row with cited accuracy before its readings are judged. Until then a reading is judged with the instrument band "unmeasured", which is said.
- **D-msv-3 the scope of an accepted variance.** Recommended: this unit by default. "This design" or "this part lot" only by an explicit ruling
  with the reason, and it can be revoked.
- **D-msv-4 the tolerance method.** Recommended: worst-case corners for the band's edge (the mistake boundary), and ngspice Monte Carlo for the
  typical spread shown beside it.
- **D-msv-5 whether an unexplained or open-mistake reading blocks the hardware confirmation.** Recommended: yes until ruled.

## 7. Phases (dev-electronics; selftests green; no deploy)

| | phase | proof |
|-|-------|-------|
| msv-0 | BuiltUnit / MeasurementPoint (derived from the node's electrical collateral: rail V, each driven pin's V, the LED branch I) / MeasurementReading via **manual**; the judgement with the instrument band; the Workbench card door-form | uno-light led-on: a typed 4.98 V rail, a 14.7 mA LED current judged in band; a typed 2 mA marked unexplained |
| msv-1 | loading + tolerance bands in the cst deck (cited part tolerances; the kit LED Vf becomes the band, not a guess) | the band edges equal hand-computed corners for the 220 Ω + LED branch |
| msv-2 | VarianceRuling (accepted / mistake / measurement-error, scope, closure by re-measure); fault signatures + ranking | an open LED joint reading ranks "open at D6 branch" first; a mistake stays open until an in-band re-read |
| msv-3 | **USB**: an `InstrumentEndpoint` transport usbtmc (pyvisa-py) and sigrok:<driver> (sigrok-cli, optional), refused by name when absent; take / stable-trigger; the Bridge-side reader agreed with Codex | a sigrok `demo` device reading through the same row path (sigrok's own demo driver, no hardware); then your meter |
| msv-4 | real scope binding: a real WaveformCapture aligned to the twin run by the stimulus edge; features vs twin + spice transient; measured bounce -> the switch part's knobs | a replayed real-style capture (source replay) aligned within one sample; the bounce count read off it |
| msv-5 | proof of build through `from_record` with readings; population spread; the Measured tab + walkthrough | a two-unit fixture: one confirmed, one blocked by an open mistake, then confirmed after rework |

## 8. Rules this plan keeps

Every prediction is derived or cited, and every band edge names its source ([derive-or-cite-chip-data]). Nothing is accepted without a person. A
reading is never edited; a later reading supersedes it. No real identifiers in tracked files (unit names are generic, and photos stay in the file
store, not git). Established tools do the hard parts: ngspice for bands and faults, sigrok for meter protocols, pyvisa-py for USBTMC.
