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

## 2b. The availability ladder (recalled 2026-10-17 at his ask; agreed 2026-10-15)

His words: "there was logic we laid out previously on a ladder of how pins are exposed or not across different levels based on a
combination of participants and enclosures, determining where pins are available. Do you recall the logic for that"

Source: Revision 2 §5 (pasted 2026-10-15) — the hierarchy SoC pad → package contact → board net / board contact / onboard component →
board extension contact, "modelled as a connectivity graph rather than assuming every relationship is one-to-one" — and §5.2 "Derived
availability". My reconciliation (`FIRMWARE_GENERATION_REVIEW_R2.md` Part 2 items 3, 4, 9) kept it: availability is a COMPUTED view,
never stored; the four-way distinction documented capability (PinFunction) → available (computed) → proposed claim → committed
(RegisterSetting); one `participants_json` instead of five scope entities.

**The ladder, in order. A function on a pin is available only if every rung passes in the given context:**

| rung | question | answered by |
|---|---|---|
| 1 SoC capability | can the silicon do it on this pad? | PinFunction / PeripheralSignal |
| 2 package exposure | is the pad bonded on the package in use? | E1 EnclosureContact (not-bonded rows), PackageContact |
| 3 board routing | where does the leg go on the board: header, internal, via what? | E2 EnclosureContact |
| 4 connected components | what already sits on the line: onboard parts, bench circuit | E2 consumers + BoardPinNet + circuit rows |
| 5 attached extensions | does a shield / carrier take or re-expose it? | E3 EnclosureContact (none seeded yet) |
| 6 pin multiplexing | does the function exclude another active one? | target_compat, PinFunction exclusivity |
| 7 electrical limits | do the loads and levels fit? | electrical rules (a)–(j) |
| 8 lifecycle | is it reserved or prohibited in this phase / condition? | PinLifecycleConstraint |
| 9 existing claims | does another task already hold it? | cmod PinClaim / PeripheralClaim |
| 10 isotope requirements | does the chosen CIsotope's need match? | fgm-4 resolver (not yet) |

**Where participants and enclosures come in.** The participants fix the context: which board, which chip, which package (every allowed one
while the bench board's variant is pending), which circuit and extensions are attached, which host and transport (the condition
transport=usb-serial comes from the host participant). Rungs 2–5 are the enclosure levels walked inward to outward. Rungs 6–10 are the
existing checks, called, never re-implemented. Each rung answers ok · blocked (reason + citation) · conditional · unchecked · not-yet ·
undetermined, and the answer names the first blocking rung. A missing input is `unchecked`, never ok. Built in hsp-0 as
`board/custom/reachability.py` (rungs 1–5 derived, 6–9 delegated, 10 `not-yet`).

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

## 4. Decisions — ✅ RULED 2026-10-17 ("Will go with your recommendations")
- **D-hsp-1 names:** EnclosureKind / HardwareEnclosure / EnclosureContact / HardwareSystem / SystemLink / SignalPath (recommended), or
  other words.
- **D-hsp-2 home:** the board module now, moved with everything else under the parent Hardware tree in fgm-T (recommended).
- **D-hsp-3 the 16U2:** model all 32 contacts with citations, unused ones included (recommended, per "account for everything").

## 5. ✅ hsp-0 BUILT + MERGED 2026-10-17 (framework 7de838e + review 0583bed + dffefc3; cli 11f5e63; sonnet agent)
- Classes (board now 51): `EnclosureKind` 54 rows, all tentative, no physics numbers (adds `E2:test-pad`); `HardwareEnclosure` 4 (U1 SPDIP,
  TQFP variant, U2 QFN, the UNO board); `EnclosureContact` 166 (SPDIP 28 + 2 not-bonded ADC6/ADC7, TQFP 32, QFN 33, UNO board 71). Extra via
  kinds found on the schematic: `series-inductor` (AVCC through L2 10 µH) and `series-fuse` (USB VBUS through F1).
- The 16U2: `atmega16u2-32-qfn` (32M1-A), 33 contacts (32 legs from Figure 1-1 p.2 + the centre pad), 23 SocPins, functions from Tables 12-3/12-6/12-9.
- `board/custom/reachability.py` (header | internal | not-bonded per SoC pin; 155 pin functions flagged) + `board/custom/ladder.py` (the ten
  rungs; 6 → target_compat, 7 → electrical_check, 8 → electrical_hw.rule_lifecycle, 9 → cmod claims; pending variant → every allowed package).
- Doors `GET /api/board/{b}/exposure[/{pin}]`, `GET /api/board/{b}/reachability[?pin&function&package&circuit&binding&phase&transport]`; chain door
  gains EnclosureContact hops. CLI `pol board exposure | reach | ladder`.
- Review fixes (me): a board pin's exposure listed the 16U2's same-named PB5 under D13 → scoped to the board's own SoC (selftest pins it); the
  ladder headline said "available" with rungs 7/9 unchecked → now "available so far (unchecked: rungs 7, 9; not yet: rung 10)".
- Selftests: board 497 → 540, cmod 698, hwnocode 163, manifests 8/9 (pre-existing pspp/testing legacy, unchanged), lazy imports 23, lazy boot 34.
- Left undetermined (named in the rows): die pads; the QFN centre pad's ground tie; nine bare 16U2 stubs; RESET-EN series vs bridge and the
  RN1D/D2 branch; LMV358 input current; 16U2 ElectricalCharacteristics; the doc7799 footer revision mismatch (one file, sha matches).
- TQFP context: rung 3 is judged on the modelled SPDIP board nets → `conditional` (no TQFP board exists).
- **Seen live on the econ-core test node 2026-10-17** (`pol deploy run econ-core --role node`, exit 0): `/api/board/arduino-uno-r3/exposure/D13`
  answers from live rows (5 crossings, the buffer among them, no 16U2 rows); the ladder for D0 RXD with transport=usb-serial is blocked at
  rung 8 on both packages; reachability lists 48 pins and 155 functions. pol-core not rolled yet.

## 6. ✅ hsp-1 BUILT + MERGED 2026-10-17 (framework 8eeca13; cli: systems | system | links | paths; sonnet agent)
- Classes (board now 54): `HardwareSystem` 1 (`uno-light-system`, S1-breadboard, 14 participants of kind hardware / software / person in the
  cmod Purpose participant shape), `SystemLink` 7 (USART0↔USART1 via RN4A/RN4B 1 kΩ; U2 USB ↔ host with LightState v1 as protocol — partial
  while the bench variant is pending; DTR → C5 → RESET; the D6→D3 jumper; button → D2; D6 → R1 → LED1 → GND; serial port ↔ Java bridge ↔
  backend gRPC ↔ page), `SignalPath` 3 derived (button-to-polari 19 hops, polari-to-led 20, led-line-to-d3 10).
- Every hop names the check that owns it (ladder rung, electrical rule, lifecycle, contract hash, Purpose proof) and copies that check's own
  verdict; no hop is ok without a check. D0 RXD on polari-to-led = ok "reserved for the transport, used as the transport" while a GPIO claim on
  D0 stays blocked. The LED hops = undetermined (assumed Vf). The contract hop = conditional (LightState v1 has no command_id; fgm-6 v2).
  led-line-to-d3's sense-counter hop = not-yet (fgm-5 D3 isotope).
- Removing the D3 BoardPinNet blocks led-line-to-d3 at a hop naming it; the other two paths are unchanged hop for hop.
- Ladder refinements: a claim of the binding in context confirms the asked function (a different function still blocks); rung 7 reads the
  binding's PinClaims (rule (e) sees pull='up'); shared caches (one build 25 s → 0.8 s).
- Doors `GET /api/hardware-systems[/{name}[/links|/paths[?path=]]]`. Selftests: board 540 → 574, cmod 698, hwnocode 163, manifests 8/9 (unchanged).
- Owed: a `Person` class (the bench operator ref is `undetermined`); a display surface (configured tables) for the hsp classes; seeding the paths
  at import now pulls cmod_seed (~4 s) into board_seed (guarded: board still loads alone).
- **Test-node deploy finding (2026-10-17):** the hsp-1 refresh never served — the backend's full (non-lazy) boot on econ-core measured **31 min**
  (≈2 min module load, ≈8 min silent pre-server phase, ≈20 min restoring ~10k persisted rows: MoldFillSimState 2808, MatrixEquationDefinition
  1067, NutrientContent 988, MatrixDefinition 847 …), past the 1800 s healthcheck grace → compose marked it unhealthy and never started the
  proxy. hsp-1's own share: board_seed import 5 s in-container, a few hundred rows. Fix: grace 3600 s in docker-compose.staging-nip.yml (rf-node,
  2026-10-17). DEBTS: (1) every `pol deploy run` regenerates certs → rebuilds → recreates the backend → a full 31-min boot; (2) lazy boot is off on
  the test node, so health only answers after the full boot; (3) the 8-min silent phase before `polariServer created` is unexplained; (4) the
  ~41k "failed to analyze variable manager" log lines per boot.
- **Rolled to pol-core 2026-10-17** (images shipped from econ-core, `pol swarm deploy node` + forced service updates): `/api/hardware-systems/
  uno-light-system/paths` answers live with the three paths; D13 exposure = 5 crossings. Backend ready ≈ 26 min after the roll. Pruned 1.07 GB;
  disk 94 % (7.4 GB free) — prune again before the next roll.
- **ROOT CAUSE of the slow, GROWING boot (found 2026-10-18 on econ-core):** every boot persisted another `polariServer` row, and the restore pass
  re-CONSTRUCTED each stored one — re-running the whole server init (DefInit of 815 classes, the API profiler …) per old row. 28 stale rows ≈ 34 min of a
  51-min boot (+≈73 s per redeploy). c3-derive's 2 640 rows were NOT the cause (retired; boot unchanged). FIX (framework branch dev-bootfix, objectTreeManager
  Decorators.RUNTIME_SINGLETON_CLASSES): polariServer is a runtime singleton — never re-constructed on restore, rows left on disk, logged. Verifying with
  `pol deploy selftest isle-core --ref dev-bootfix` then a test-node boot. The same accumulation likely exists on pol-core's live stack.
