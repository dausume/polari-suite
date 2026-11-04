# Measured vs simulated: binding real scope and multimeter readings to the simulation (msv) - plan 2026-11-04

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

## 5b. Generated step-by-step manual tests (the user, 2026-11-04)

The user: "generate step by step manual tests that either have people just touch the different pieces and then confirms when data came through from
the device to pass the test or fail it, or tells and shows you where to test visually on the left side while giving a sheet to manually fill out with
data from the device testing."

**A TestProcedure is GENERATED, not written by hand.** It is derived on read from a Bench Solution's topology and its measurement points
([nocode-first-reduce-code]). It is stored only once it is frozen for a run.
- **The order.** Each node is visited by the fastest path from the root, the same rule as the twin. Power-off checks come first: R and continuity
  between nets, so a bridge is found before power is applied. Then power on. Then the nodes along each path.
- **The steps.** Each step is one of:
  - **set up** — "plug the USB into the bridge", "flash build <sha12>"
  - **stimulus** — "press and release the button on D2", "hold it for 1 s". These words come from the edge's stimulus. The fault edges become
    steps too, e.g. "press and bounce": you tap it quickly.
  - **measure** — one measurement point: which instrument and mode, red probe here, black probe there, and the expected range.
  - **observe** — "the LED on D6 is lit". This is a person's yes/no, and it is recorded as evidence of the person's judgement, not as a measurement.
- **The rows.** A **TestProcedure** `<bench solution>-proc-<n>` is frozen per build (hex sha256 plus the layout) and is regenerated when either
  changes. Its **TestProcedureStep** `<proc>-s<n>` children each name the node, the point or stimulus, and the words. A **TestSession** `<unit>-<proc>-t<n>`
  is one person working through one procedure on one BuiltUnit. Its readings are ordinary MeasurementReadings carrying the session and the step.

**Two ways to run the same procedure** (picked per session; a session may mix them step by step):

1. **Touch and confirm (auto).**
   - The screen says what to touch: the probe point, or the button to press.
   - The step waits for the data to arrive from a device: a USB/LAN meter reading that holds steady inside its resolution, a scope trigger on the
     probed line, or the board's own serial fields changing (the twin's fields, read off the real firmware).
   - The step then passes or fails by the bands in §4 and moves to the next one. There is nothing to type.
   - **A timeout** (a knob, stated per step kind) fails the step with "no data came through", which is its own outcome: it means the probe, the
     cable or the connection, not the circuit.
   - Stimulus steps are confirmed by the device too. The press is seen in the serial fields, or on a probed line.
   - Needs: an instrument with a live path (§3) or firmware that reports its fields. A step whose instrument has no live path drops to mode 2 for
     that step, and says so.
2. **Guided sheet (manual).**
   - **Left pane — where to test:** the board or breadboard view (bb's layer, the layout view's net highlight) with the point lit, the probe colours
     (red / black) drawn on the two nets, the meter mode and range shown as an icon, and for a stimulus the part to press highlighted.
   - **Right pane — the sheet:** a form with one row per step: the expected range, a field for the value, pass/fail filled in as the value is
     typed (judged by §4 live), and a note. Observe steps are a yes/no.
   - **Printable:** the same sheet rendered for paper, with the left-pane picture per step. A filled paper sheet is entered back through the same
     form, and its photo is kept as evidence.

**What a session ends with.**
- A summary of passed / failed / unexplained / no-data steps.
- Every unexplained reading goes into §4's ruling queue, with its fault-signature ranking.
- Passed nodes feed §5's hardware confirmation.
- A session can stop and resume. A resumed session re-asks the stimulus steps before the next measure step, so the board is back in the node's
  state.

## 6. Decisions (recommended first; each is the user's)

**RULED 2026-11-04 (the user: "go with recommendations"): D-msv-1, 3, 4, 5, 6, 7, 8 as recommended. D-msv-2 is still the user's fact (the instruments they own); until it is given, readings carry the instrument band "unmeasured".**

- **D-msv-1 order of acquisition paths.** Recommended: manual first (msv-0, works with anything), then USB via sigrok for handheld DMMs plus
  USBTMC via pyvisa-py for bench gear (msv-3), and LAN stays as built. Alternative: USB first, if a USB meter is already on the bench.
  **REFINED 2026-11-04 by the user: "anything with sigrok"**. The automatic path is sigrok for every meter (msv-3 builds a sigrok-cli reader first).
  Manual entry stays the cheap path, and pyvisa-py is only a fallback for SCPI gear sigrok does not read.
- **D-msv-2 which instruments you own** (your fact): DMM make and model, whether it has a USB/serial port, and the scope. Each gets an Instrument
  row with cited accuracy before its readings are judged. Until then a reading is judged with the instrument band "unmeasured", which is said.
  **ANSWERED 2026-11-04.** The user first said: "I do not own any currently, just look into affordable commercial options as examples which are
  ideally American, and if open source options exist do one of those as well". They then added: "the open scopes we have already are fine, and
  anything with sigrok then, readings coming in automatically is one critical case and another is doing do manually/cheaply". So:
  - **Scopes:** the open scopes already seeded (osc-6: ScopeFun, DSO138) stand. No new scope is added.
  - **The automatic path is sigrok** (libsigrok/sigrok-cli, GPLv3). Every meter-type device is read through it, which refines D-msv-1. The
    `usb-scpi` path is kept only for what sigrok's own scpi-dmm driver reads.
  - **Two critical cases:**
    1. **Automatic**: a sigrok-supported meter streams its readings in.
    2. **Manual / cheap**: any meter, read by eye and typed in (msv-0, built).
  - **The example meter covers both:** the **TekPower TP4000ZC**. It costs about USD 43 from Kaito Electronics, a US company, and is a rebadged
    Digitek DT4000ZC. It has 4000 counts and an optically isolated RS232 port on a 3.5 mm jack (RS232 or USB cable), and sigrok lists it as
    supported (serial-dmm).
  - **Its accuracy is SEEDED** (`instruments_seed.SEED_ACCURACY`):
    - DC V: +/-(0.5 % + 5) on 0.4 / 4 / 40 / 400 V.
    - DC mA: +/-(1.5 % + 5) on 40 / 400 mA. This is the wider of two conflicting figures: a review gives 1.5 %, the seller 1.2 %.
    - The source is a review table plus the seller listing. The user manual's own table is still owed.
    - On its 40 mA range the LED point's band is about +/-0.27 mA, so a good board's 14.6 mA reads IN BAND.
  - **Looked at and not seeded:**
    - Keysight EDU34450A (about USD 1003; not on sigrok's list).
    - Fluke 87V (about USD 450-580; no data port).
    - Fluke 287/289 (sigrok-supported but costly).
    - SparkFun 70C (sigrok-supported, retired).
    - No mature open-hardware DMM exists. ThunderScope and PSLab are noted, but the open scopes already seeded suffice.
- **D-msv-3 the scope of an accepted variance.** Recommended: this unit by default. "This design" or "this part lot" only by an explicit ruling
  with the reason, and it can be revoked.
- **D-msv-4 the tolerance method.** Recommended: worst-case corners for the band's edge (the mistake boundary), and ngspice Monte Carlo for the
  typical spread shown beside it.
- **D-msv-5 whether an unexplained or open-mistake reading blocks the hardware confirmation.** Recommended: yes until ruled.
- **D-msv-6 how a touch-and-confirm step counts its data.** Recommended: the device's data decides pass/fail, and a person's "yes" never
  substitutes for it. A step with no live path is a sheet step, and is labelled as one on the result.
- **D-msv-7 whether power-off checks come first** (R / continuity between neighbour nets before power is applied). Recommended: yes, so a bridge is
  caught before it can damage a part. They can be skipped per session, and a skip is recorded.
- **D-msv-8 how far the paper sheet goes.** Recommended: a printable view of the same sheet (HTML print), entered back through the form. No PDF
  generator for now.

## 7. Phases (dev-electronics; selftests green; no deploy)

| | phase | proof |
|-|-------|-------|
| msv-0 | ✅ **BUILT 2026-11-04** (framework, local dev; not pushed - held with bss-11..14): `BuiltUnit` / `MeasurementPoint` / `MeasurementReading` (cmod) + `InstrumentAccuracy` (instruments: +/-(% of reading + counts x resolution) per function and range, input impedance / burden, the cite); `custom/measure_points.py` (the node's latest reached run -> its electrical collateral names the circuit state -> the cst .op of that state -> one V dc point per net with the probe words from the net's board pins, one I dc point per ammetered part with where to break the circuit, the 5 V rail under the node's load; a vanished point is marked stale, never dropped), `custom/measure_readings.py` (units, manual readings with units parsed V/mV/uV/A/mA/uA and refused across V vs A, judged on read: in-band / unexplained / unjudged / over-range, stale on another build; no range = the smallest that holds the value), `cmod_measure_api.py` (.../nodes/{slug}/measurement-points GET + POST derive, .../units GET + POST, .../units/{unit}/readings GET + POST), the **Measured** tab on /display/hardware-events (unit form + table, the node's points, the manual reading form, the judged readings). No real meter seeded (D-msv-2) | `cmod_measure_selftest` 32/32: led-on gives 5 points (LED current 14.715 mA, the R1/LED junction 1.763 V "no board pin", the rail 4.9926 V); with a FIXTURE meter 4.995 V in band (+/-27 mV), 14.2 mA unexplained (+/-0.442 mA), 14.7 mA in band, no instrument unjudged, 250 mA over range, an unread line unjudged, stale on a rebuilt unit; 5 refusals; 6 doors; the manifest (73/73 conform), the page; neighbours instruments 33/33, bench views 17/17, confirmations 11/11, coverage 9/9, retest 7/7, topology 16/16, node run 14/14 |
| msv-0b | ✅ **BUILT 2026-11-04** (framework, local dev; not pushed - held with bss-11..14):
- **Rows:** `TestProcedure` / `TestProcedureStep` / `TestSession` / `TestStepMark` (cmod).
- **`custom/test_procedures.py`:** GENERATES the test.
  - **Power off first.** Continuity between the circuit's board pins and their header neighbours (a bridge beeps before power is ever applied), 5V-GND, and each switch released then held.
  - **Then** power on, flash, boot.
  - **Then every state node** by its fastest path. A node continuing the one just tested needs no RESET; otherwise RESET first. Stimuli come in a person's words from the Hardware Events (press / bounce tap / long press with its knob / hold / release / send the command / wait).
  - **Each node ends with** its msv-0 measurement points and a look (the LED lit / dark, from its circuit state).
  - **Frozen per build**: an unchanged regeneration returns the frozen procedure.
- **`custom/test_sessions.py`:** the GUIDED SHEET.
  - A measure step is an ordinary MeasurementReading. Other steps are marks: done / skipped, beep / no-beep, yes / no.
  - Verdicts: pass / fail / unexplained / unjudged / over-range / done / skipped / pending.
  - Resume asks the RESET and presses again.
  - Done when nothing is pending.
  - Touch mode falls back to the sheet, said (msv-3).
- **`custom/procedure_svg.py`:** the LEFT PANE.
  - The UNO headers in board order plus the circuit's parts, drawn per step: the red / black probe rings, a pin-less net lit among the parts, a series current shown at the part's leg.
  - The print view (HTML, D-msv-8).
- **Doors** in `cmod_measure_api.py`: procedures, preview, steps, the step picture (image/svg+xml), sessions, the sheet, answer, resume, print, summary.
- **The Test sheet tab** on /display/hardware-events: the picture (api-svg-panel) beside the sheet, side by side. |
`cmod_procedure_selftest` 24/24 on the applied light spec with one run node:
- The order: off, 9 continuity checks, on, flash, boot.
- The words, the continue-vs-RESET rule, 10 nodes owed, frozen per build.
- A session: continuity pass / fail, the LED 14.6 mA on the TP4000ZC pass, the rail 4.6 V unexplained, the look fail; resume re-asks the RESET + press; done.
- The SVG rings, the print view, 11 doors + 3 refusals, the manifest, the page.

Neighbours: measure 34/34, coverage 9/9 (8 tabs), confirmations 11/11, retest 7/7, topology 16/16; conform 73/73. |
| msv-1 | ✅ **BUILT 2026-11-04** (framework, local dev; not pushed - held):
- **The cst deck takes `vary`.** The nominal deck is unchanged. The options:
  - the rail
  - a factor per resistor
  - a driven pin's output resistance
  - an LED's Vf shift (its model's Is scaled)
  - a voltmeter's input to GND, an ammeter's burden in series
- **`cmod/custom/measure_bands.py`:** the worst-case corners (D-msv-4). Each point gets band_lo..band_hi; led-on takes 32 runs. The parameters:
  - **the rail** 4.75..5.25 V: a KNOB, a USB host port, not read here. When the unit has its own 5 V rail reading, that reading +/- its meter band replaces it.
  - **R** +/-5 %: a KNOB, the gold band.
  - **LED Vf** 1.8..2.5 V at 20 mA: a KNOB, the kit LED has no cited rating. The user's kit LED Vf replaces it.
  - **The pin's output resistance** 0..40 ohm high / 0..45 ohm low: DERIVED from the cited VOH 4.2 V / VOL 0.9 V at 20 mA, Table 30-1.
  - **The pull-up** 20..50 k: cited.
- **The meter's loading** is one run with its cited input resistance or burden in the deck; uncited means none, said.
- **The new verdict IN TOLERANCE:** off the nominal but inside the band widened by the instrument band. Without a cited meter it says the meter is not counted.
- **The Measured tab** shows the band and the expected value. Monte Carlo (the typical spread) is not built yet. |
`cmod_bands_selftest` 10/10:
- The LED band edges equal the hand corners (the diode law by bisection, 8.5335..16.5816 mA both).
- LED_CONTROL's low edge by hand; 32 runs.
- Every state's nominal inside its bands; the nominal deck unchanged.
- Loading by hand: -9.98 mV for 10 Mohm on the 20 k pull-up, -65 uA for a 1 ohm burden.
- The unit's rail narrows the band.

Elsewhere:
- measure 36/36: 14.2 mA is now in tolerance, 5 mA unexplained.
- procedure 24/24; electrodevice circuit_states 29/29, rows 13/13, electrodevice 119/119; conform 73/73. |
| msv-2 | VarianceRuling (accepted / mistake / measurement-error, scope, closure by re-measure); fault signatures + ranking | an open LED joint reading ranks "open at D6 branch" first; a mistake stays open until an in-band re-read |
| msv-3 | ✅ **sigrok half BUILT 2026-11-04** (framework, local dev; not pushed - held). The user: "anything with sigrok".
- **`instruments/custom/sigrok_reader.py`:**
  - capability, or refused by name (apt install sigrok-cli / SIGROK_CLI)
  - SIGROK_DRIVERS from `sigrok-cli -L`: tekpower-tp4000zc -> `tekpower-tp4000ZC`, plus the demo driver
  - the `-O analog` line parser (SI prefixes, flags, overload)
  - one sigrok-cli run per take (argv checked: no shell characters)
  - STEADY = 3 samples in a row within one count, on one channel (knobs)
  - the evidence = the sha256 of the verbatim output
- **InstrumentEndpoint** transport `sigrok` (resource `<driver>[:conn=<port>]`, typed, never seeded).
- **TOUCH AND CONFIRM:** `test_sessions.take` + POST .../sessions/{s}/steps/{step}/take:
  - a measure step answered by the meter's steady value (via usb-serial)
  - its own outcomes: NO DATA (no line: the probe / cable / port), NOT STEADY, WRONG MODE (another unit or AC)
  - the BRIDGE PATH {instrument, lines} for a meter on the person's machine
- **The Test sheet tab's "Touch and confirm" form.**
- **OWED:**
  - sigrok-cli where the meter is plugged in: the backend image has none; an isle-node engine or the Bridge.
  - The Bridge side (run sigrok-cli on the person's machine, post the lines) is Codex's.
  - The USBTMC/pyvisa fallback.
  - Continuity by meter (the sheet's). |
`cmod_sigrok_selftest` 14/14:
- The recorded sigrok-cli 0.7.2 lines parse; steady, on one channel; refused without the binary.
- A stand-in sigrok-cli drives the real subprocess path; the endpoint door and its refusals.
- A take: 14.62 mA pass with the sha256, then no-data / not-steady / wrong-mode, the Bridge lines; a continuity step refused; the door.
- Proven against the REAL sigrok-cli 0.7.2 in a throwaway Debian trixie container: the demo read and steady, and a TP4000ZC with nothing plugged in gives "No devices found".

Elsewhere: instruments capture 62/62 (the seed-pair check now names the accuracy rows); conform 73/73. |
| msv-4 | real scope binding: a real WaveformCapture aligned to the twin run by the stimulus edge; features vs twin + spice transient; measured bounce -> the switch part's knobs | a replayed real-style capture (source replay) aligned within one sample; the bounce count read off it |
| msv-5 | proof of build through `from_record` with readings; population spread; the Measured tab + walkthrough | a two-unit fixture: one confirmed, one blocked by an open mistake, then confirmed after rework |

## 8. Rules this plan keeps

Every prediction is derived or cited, and every band edge names its source ([derive-or-cite-chip-data]). Nothing is accepted without a person. A
reading is never edited; a later reading supersedes it. No real identifiers in tracked files (unit names are generic, and photos stay in the file
store, not git). Established tools do the hard parts: ngspice for bands and faults, sigrok for meter protocols, pyvisa-py for USBTMC.
