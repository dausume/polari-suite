# Reminders for Dustin — things only you can do (hardware arc)

Newest first. Tick a line (`[x]`) when done; Claude reads this file at the start of hardware work.

## Added 2026-10-15

- [ ] **Photograph the printed markings on the small kit parts** so their electrical facts can be cited instead of "undetermined":
      the 5 transistors, the 2 MOSFETs, the H-bridge chip, the 2 optocouplers, the temperature sensor's flat face, the back of the
      16×2 LCD, and the servo/DC-motor labels. (LED colours have no markings — their forward voltage comes from a datasheet or a
      measurement; a multimeter's diode mode on one red LED gives the number the light test still needs.)
- [ ] **While the board is on the bench, read its fuses once** (the app or `avrdude -c arduino -p atmega328p -P /dev/ttyACM0 -U hfuse:r:-:h`)
      — the RESET pin's disable fuse (RSTDISBL) state is the one board fact no document can give us.
- [ ] **If the board turns out to be a CH340 clone,** say so — its USB id and whether DTR resets it are undetermined today.
- [ ] **Plug the UNO into pol-core once** so Detect can read its real USB ids — that confirms the board variant (pending; the box says
      genuine UNO R3 with the DIP chip + 16U2, the board itself decides). `lsusb | grep -E '2341|2a03|1a86'` is enough.
- [x] ~~Claude rebuilds the runtime deb with the new Detect step~~ — done 2026-10-15 (sha e586932c…, on the demo page's Downloads;
      install that one, the newest row).
- [ ] **Bench prerequisites (sudo):** add yourself to `dialout` and log out/in; install avrdude (or install the two debs, which pull it in).
      Steps: `AI-Notes/guides/HARDWARE_ARC_TEST_GUIDE.md` §5.
- [ ] **Wire the light test (power off):** LED long leg → D6 through a 220 Ω resistor, short leg → GND; pushbutton between D2 and GND;
      a jumper from D6 to D3 (the feedback input).
- [ ] **Rule on the six flow-state decisions** (D-flow-1..6) in `AI-Notes/plans/FIRMWARE_FLOW_STATES_PLAN.md` §6 — recommendations are
      written there; one line each is enough.
