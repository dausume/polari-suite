# Hardware System pins, enclosures and signals (hsp arc) — plan 2026-10-17

Terminology lives in `SYSTEM_HIERARCHY_TERMINOLOGY.md` §8–§12 (Hardware Mission, Task Plan, Hardware System, Embedded Device, Hardware
Enclosure, Participants, development stages). This plan is the implementation record for the pin side.

## 0. His words (2026-10-17)

"Okay let's tentatively make the different kinds of enclosures we need and plan out for things we need, but in terms of implementation
focus on the ones for pins for now that are relevant to electronic systems and finish fleshing out what we need logic wise for the
electronics, pins, and signals, we are only accounting for terminology and the need for devices down the road"

So:
- **Tentative, data only:** every enclosure KIND from terminology §12 (levels E0–E5, functions) as catalogue rows marked `tentative`.
- **Built:** the pin side of enclosures (exposure maps) for the levels a Hardware System has today (E1 packages, E2 boards), plus the
  remaining logic for electronics, pins and signals.
- **Not built:** Embedded Device physics (thermal chain, stress, ingress, housing features). Named in the catalogue and the terminology
  only, for later.

## 1. What exists (facts, read 2026-10-17)

| concept | rows today | gap for this arc |
|---|---|---|
| package legs | `PackageDefinition` (28-SPDIP, 32-TQFP) + `PackageContact` (60) for the ATmega328P | the 16U2 (U2, 32-pad QFN per the schematic's `-MU` code) has no contacts; the package is not yet an enclosure with an exposure map |
| SoC pins | `SocPin` + `PinFunction` + `PeripheralSignal` + `Peripheral` (328P only) | U2's pins are not materialized |
| board pins | `BoardPin`, `Connector`, `ConnectorPin`, `BoardNet` (UNO) | no row says what lies BETWEEN a SoC pin and its header pin (direct trace, 1 kΩ series to the 16U2, the LMV358 buffer on D13, C5 on RESET) except prose in `PinLifecycleConstraint` and the schematic facts |
| chips on a board | `BoardComponent` U1 mcu, U2 usb-bridge | no row links U1 and U2 (USART0 ↔ the 16U2's serial; DTR → RESET) |
| outside the board | `BoardPinNet` (D6 driver, D3 input, D2 input, GND on circuit `uno-button-clock`), electrodevice circuit rows | no Hardware System row groups board + circuit + host; no link to the host |
| the walk | `GET /api/board/<b>/chain/<pin>` + `pol board chain` — board pin DOWN to registers, with package and lifecycle hops | walks one pin downward only; nothing walks a SIGNAL end to end (button → Polari, Polari → LED, LED line → D3) |
| checks | electrical rules (a)–(j), lifecycle constraints, target compatibility | results are per circuit/binding, not attached to a signal's hops |
| verification | `verification` (verified / partial) + `undetermined` on lifecycle rows | not uniform across the new rows |

## 2. The logic still needed for electronics, pins and signals (the full list)

| # | logic | built here? |
|---|---|---|
| L1 | **Enclosure kinds catalogue**: every kind by level E0–E5 and function (terminology §12.2), `status: tentative`, `pin_relevant` flag | ✅ hsp-0 (data only) |
| L2 | **Hardware Enclosure instances + nesting**: one row per enclosure in a design (U1's package, U2's package, the UNO board), with its kind, level, parent and contents | ✅ hsp-0 |
| L3 | **Exposure map**: one row per crossing (inner contact → outer contact through one enclosure) with `via` = direct · series-resistor · buffer · capacitor · jumper · not-bonded · internal-only, the via part and its value, and citations. DERIVED from the existing rows (PackageContact, BoardPin, ConnectorPin, the schematic facts), never typed twice | ✅ hsp-0 |
| L4 | **Reachability**: for every SoC pin and every pin function — reaches a header / internal only (and what consumes it) / not bonded in this package. For every header pin — what it reaches inward. His rule: account for everything, the unused included | ✅ hsp-0 |
| L5 | **The 16U2 as rows**: its QFN-32 contacts, SocPins and the functions the board uses (USART1, USB, DTR line), cited from doc7799 + the schematic; the rest `undetermined` rather than guessed | ✅ hsp-0 |
| L6 | **Hardware System + links**: `HardwareSystem` (stage S1 Breadboard for the light demo; its boards, components, circuits, host) and `SystemLink` (U1 USART0 ↔ U2 USART1 through 1 kΩ; U2 USB ↔ host; U2 DTR → U1 RESET through C5; the bench's D6 → D3 wire). Each link: two endpoints (pin sets), the signal kind, the protocol or contract when one exists (LightState v1), citations | ✅ hsp-1 |
| L7 | **Signal paths end to end**: `SignalPath` derived per logical signal, ordered hops across pins, enclosure crossings, nets and links. Seeded for the light demo: (1) button press → Polari, (2) Polari toggle → LED, (3) LED line → D3 sense. Each hop carries the verdict of the check that owns it (electrical rule, lifecycle, contract) or `unchecked`, never a silent ok | ✅ hsp-1 |
| L8 | **Uniform verification** on every new row: verified · partial · unverified · conflicted, plus `undetermined` text | ✅ hsp-0/1 |
| L9 | Doors + CLI + plain words: `GET /api/board/<b>/exposure[/<pin>]`, `GET /api/board/<b>/reachability`, `GET /api/hardware-systems/<s>/paths`; `pol board exposure|reach`, `pol board paths <system>`; a `plain_words` on every class | ✅ hsp-0/1 |
| later | typed HAL drive/signal kinds as resolver inputs; claim modes (shared, time-multiplexed) and proposed→committed | fgm-4 |
| later | several boards per binding; the TQFP package bound on a real board | fgm-8 |
| later | die-pad maps (E0/E1 inner side) | stage S4 (our own SoC) |
| later | housing exposure features (panel button, light window), thermal chain, stress | Embedded Device, terminology §12 |
| later | a display surface (configured Table definitions, no raw JSON) for the fgm-2 and hsp classes | next display slice |

## 3. Slices (each its own branch off dev, proven on the econ-core test node via `pol deploy run econ-core --role node`)

### hsp-0 — enclosures and exposure (board module; moves under the Hardware tree with fgm-T)
- Classes: `EnclosureKind` (catalogue, tentative), `HardwareEnclosure` (instance: kind, level, parent, board/package/component it is),
  `EnclosureContact` (one crossing: enclosure, inner ref, outer ref, via, via_part, via_value, exposed, verification, citations).
- Rows: all kinds from terminology §12.2; enclosures for U1's 28-SPDIP, the TQFP variant (not on the UNO, modelled), U2's QFN-32, the UNO
  board; crossings derived for every 328P contact (SPDIP + TQFP), every U2 contact, every UNO header pin, the ICSP headers (both chips),
  the USB connector.
- The 16U2 rows (L5) from the cached doc7799 text and the schematic, page-cited.
- Reachability derived (L4); the chain door gains the exposure hops (via + what consumes an internal line).
- Acceptance, refused or reported by name: D0/D1 show the 1 kΩ series crossing to U2; D13 shows the LMV358 buffer; RESET shows C5 from
  DTR; PB6/PB7 show internal-only (the 16 MHz part); ADC6/ADC7 show not-bonded on SPDIP and bonded on TQFP but on no UNO header; every
  328P SoC pin has a reachability verdict; no number without a citation or `undetermined`. Board, cmod, hwnocode selftests stay green and
  the fgm-0 identical-hex gate is untouched.

### hsp-1 — Hardware System, links, signal paths
- Classes: `HardwareSystem` (name, stage S1–S5, boards, components, circuits, host participants, Task Plan ref later), `SystemLink`,
  `SignalPath` (derived; hops as refs + per-hop verdict).
- Rows: `uno-light-system` at stage S1 Breadboard; its four links; the three light-demo paths.
- Acceptance: each path walks from its origin to its end with no gap; a hop whose check has not run says `unchecked`; changing the
  bench wiring (removing the D6 → D3 BoardPinNet) breaks path 3 by name; the LightState v1 contract appears as the protocol of the
  host link.

## 4. Decisions (his; my recommendation first)
- **D-hsp-1 names:** EnclosureKind / HardwareEnclosure / EnclosureContact / HardwareSystem / SystemLink / SignalPath (recommended), or
  other words.
- **D-hsp-2 home:** the board module now, moved with everything else under the parent Hardware tree in fgm-T (recommended).
- **D-hsp-3 the 16U2:** model all 32 contacts with citations, unused ones included (recommended, per "account for everything").
