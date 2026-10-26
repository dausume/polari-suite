# Oscilloscope data: 4-channel capture, the LXI/SCPI standard, emulation, and the view (osc arc) — plan 2026-10-26

**His words (2026-10-26):** "a way to emulate 4-channel oscilloscope behavior in respect to devices, it looks like there is a standard
data format LXI compliant, we should adhere to for formatting that data. We will want to be able to emulate and enable the use of the
two biggest oscilloscope providers and leverage that data in polari when accessing their servers. We will also want to emulate using
them. Let's start with this model [the RIGOL DHO804], since it is a 4-channel model, and can support the debugging process of 4 channel
signals." Then: "work through a way of either finding an open source engine that handles this kind of data we can leverage (preferred)
or making what is needed to interpret that data, then we will want to be able to visualize that data being received from simulated
versions of the device." And: "work on this autonomously through the day."

## 0. What the standard actually is (so we adhere to the right layer)
- **LXI** (LAN eXtensions for Instrumentation, the LXI Consortium) is the *connectivity* standard: an instrument on Ethernet that is
  discovered by mDNS, reached by **VXI-11** (ONC-RPC, portmapper 111) and/or **HiSLIP**, has a web page, and (optionally) IEEE-1588 time
  and LAN triggers. LXI does **not** define a waveform *data* format.
- The **data** is carried by **SCPI** (IEEE 488.2 syntax) and the waveform payload is an **IEEE 488.2 definite-length arbitrary block**:
  `#` + one digit N + N digits of byte count + the bytes (the `#9000001000…` header every scope vendor sends). Sample→volts and
  index→time come from a vendor **preamble** query. Two lineages exist among the makers that matter here:
  - **Agilent lineage** (Keysight, and Rigol who adopted the same command tree): `:WAVeform:PREamble?` → 10 comma fields
    `format,type,points,count,xincrement,xorigin,xreference,yincrement,yorigin,yreference`;
    `V = (raw − yorigin − yreference) × yincrement`, `t = (i − xreference) × xincrement + xorigin`.
  - **Tektronix lineage**: `WFMOutpre?` (XINcr, XZEro, PT_Off, YMUlt, YOFf, YZEro, BYT_Nr, BN_Fmt) + `CURVe?`;
    `V = (raw − YOFf) × YMUlt + YZEro`, `t = (i − PT_Off) × XINcr + XZEro`.
- So Polari adheres to: **LXI for reach/discovery, SCPI + the 488.2 block for transport, one canonical capture record of ours that
  both preambles map onto losslessly** (raw block kept verbatim + the preamble fields + the formulas' parameters). That is the only
  honest "standard format": a capture is reproducible from its stored inputs ([[reproducible-initial-conditions]]).
- "The two biggest providers" = **Keysight** and **Tektronix** by revenue as commonly reported (a fact row cites a market source when
  written; nothing here depends on the ranking). Rigol is the volume entry-tier maker and the first model, as he asked.

## 1. Facts gathered 2026-10-26 (every number cited; "unverified" where a source was not read)
**DHO804 / DHO800 series** — RIGOL DHO800 Data Sheet DSA36106-1110, Oct. 2024, pp. 6–9 (read in full) unless noted:
| fact | value | source |
|---|---|---|
| analog bandwidth (−3 dB) | 70 MHz (DHO802/804); 100 MHz (DHO812/814) | datasheet p.6 |
| analog channels | **4** (DHO804/814); 2 + EXT (DHO802/812) | datasheet p.6 |
| rise time (10–90 %, typical) | ≤ 5 ns (70 MHz models) | datasheet p.6 |
| max sample rate, four-channel model | 1.25 GSa/s single-channel; 625 MSa/s dual; 312.5 MSa/s all four | datasheet p.6/9 |
| max memory depth, four-channel model | 25 Mpts single; 10 Mpts dual; 5 Mpts all four | datasheet p.6/9 |
| waveform capture rate | 30,000 wfms/s (Vector); 1,000,000 wfms/s (UltraAcquire) | datasheet p.6 |
| vertical resolution | 12 bits (4096 levels) | datasheet p.6/7 |
| input | 1 MΩ ± 1 %, 15 pF ± 3 pF; DC/AC/GND coupling; CAT I 300 Vrms / 400 Vpk max | datasheet p.7 |
| vertical sensitivity | 500 µV/div to 10 V/div; dynamic range ±4 div | datasheet p.7 |
| bandwidth limit | 20 MHz / FULL per channel | datasheet p.7 |
| timebase | 5 ns/div to 500 s/div; resolution 100 ps; pre-trigger −5 div | datasheet p.8 |
| trigger sources / modes | CH1–CH4 (+ EXT on 2-ch models); Auto / Normal / Single; edge, pulse, slope, video, pattern, duration, timeout, runt, window, delay, setup/hold, Nth edge, RS232/UART, I2C, SPI, CAN | datasheet p.9–11 |
| auto measurements | 41 items (Vmax … Phase) | datasheet p.13 |
| interfaces | USB Device & Host, LAN, HDMI (std.); USB Type-C power | datasheet p.1–2 |
| display | 7" 1024×600 capacitive multi-touch | datasheet p.6–7 |
| size | 265.35 × 161.75 × 77.38 mm (W×H×D) | datasheet p.2 |
| street price | USD 454–459 (Jameco / TestEquity listings, 2026-10-26) | his screenshot |
| LXI class / version | **unverified** — the datasheet pages read carry no LXI statement; Rigol's page only links an LXI conformance service | — |
| programming guide | "DHO800900 ProgrammingGuide" PGA39106-1110, 2025-05-09, listed on rigol.com — **no direct URL found; not read** | rigol.com product page |

**DHO command set and data format** — cited to the BSD-3 scopehal driver `scopehal/RigolOscilloscope.cpp` (ngscopeclient), read 2026-10-26,
the DHO branch (`m_protocol = DHO`, models `DHO%d` < 5000; `m_highDefinition = true` "those are 12 bits (HD) models"):
- setup `:WAV:FORM WORD` (12-bit → 2 bytes per sample; BYTE = 8-bit), `:WAV:MODE RAW` (then `NORM` toggled in PrepareStart);
- per channel `WAV:SOUR CHAN<n>`, `WAV:PRE?` parsed `%d,%d,%zu,%d,%lf,%lf,%lf,%lf,%lf,%lf` = format, type, points, count,
  xincrement (s/sample), xorigin, xreference, yincrement, yorigin, yreference; **V = (raw − (yorigin + yreference)) × yincrement**;
- paging `WAV:STAR <1-based>` / `WAV:STOP <end>` / `WAV:DATA?` in chunks of **250,000 points** (driver default, not overridden for DHO);
  the 488.2 header is read as `#`, one digit, that many digits of byte count, then bytes + one trailing `\n`; in WORD mode the sample
  count is bytes/2; the driver reinterprets the buffer as native little-endian uint16 with no swap;
- channel `:CHAN<n>:SCALE` (volts/div, ×8 = range), `:OFFS`, `:COUP AC|DC|GND`, `:BWL 20M|OFF`, `:PROB`; timebase `:TIM:SCAL`, `:TIM:MAIN:OFFS`;
  trigger `:TRIG:MODE EDGE`, `:TRIG:EDGE:SOUR`, `:TRIG:EDGE:LEV`, slopes POS|NEG|RFAL; acquisition `:ACQ:SRAT?`, `:ACQ:MDEP 1k…500M`.
- LAN ports: **TCP 5555 raw SCPI** and **111 (VXI-11 portmapper)** — a forum-compiled port list for the DHO800/900 (eevblog "Hacking the
  Rigol DHO800/900" thread) and a third-party tool's README; **forum-reported, not from the guide** → the facts row says so.
- Known report (unverified): `:WAV:DATA?` answered "The instruction is not supported!" on a DHO924S when reading internal memory in one
  user's port of DSRemote — the emulator must be able to *replay* such refusals so the client's refusal path is tested.
- `*IDN?` form for Rigol instruments: `RIGOL TECHNOLOGIES,<model>,<serial>,<firmware>` (four comma fields per IEEE 488.2; the DHO serial
  prefix is unverified).

**Open source engines surveyed (licence gate — the project is GPLv3; [[project-license-gplv3]])**
| engine | what it gives | licence | verdict |
|---|---|---|---|
| **PyVISA 1.16.2 + PyVISA-py 0.8.1** (pure Python backend) | transports `TCPIP::host::5555::SOCKET`, `TCPIP::host::INSTR` (VXI-11), `TCPIP::host::hislip0::INSTR` (HiSLIP), USBTMC (pyusb extra), VICP; `query_binary_values(..., datatype='h', is_big_endian=False, header_fmt='ieee')` parses the 488.2 block; zeroconf extra for HiSLIP/VICP discovery | MIT (PyPI metadata read) | **ADMIT as the transport engine** (optional import; the raw-socket path is stdlib so selftests need no wheel) |
| **scopehal / ngscopeclient** | C++ library + Vulkan GUI; drivers for Rigol DHO800/900/1000/4000, Keysight/Agilent, Tektronix, Siglent, LeCroy, Pico; "twinlan" bridge protocol | BSD-3 (LICENSE read) | **CITE** (its driver is our DHO command reference); not vendored — C++/Vulkan desktop, outside the web stack ([[language-layering]]); a later `scope-engines` worker may expose twinlan so ngscopeclient can view our emulator |
| **libsigrok / sigrok-cli / PulseView** | C; rigol-ds driver gained DHO800/900 in unofficial builds (PR #229, eevblog thread 2024–25) — mainline status unverified; srzip/VCD/CSV outputs; protocol decoders | GPL-3 (COPYING read) | **LATER** candidate for a worker that pulls from devices we have no adapter for; VCD aligns with the twin's VCD trace |
| python-ivi, pymeasure, instrumentkit | per-instrument driver classes (Agilent/Keysight/Tek/Rigol) | MIT / MIT / AGPL-3 | not needed for v1: the two preamble adapters are ~40 lines; revisit for Keysight/Tek details |
| pyvisa-sim | YAML-scripted fake instruments for tests | MIT | NOT enough: static replies, cannot synthesise 4 channels from device state |

**Conclusion (his preference honoured):** leverage **PyVISA + PyVISA-py** for every real-instrument transport and the 488.2 block
parsing; write only what no engine gives: the canonical capture record, the two preamble adapters, the **emulator** (no open source
4-channel SCPI *server* fed from device state exists), and the configured view.

## 2. Shape — a new module `instruments` (feature module, library kind; hardware-app tier not needed: no USB ownership)
```
modules/instruments/
  objects/instruments/   Instrument          one row per instrument MODEL known (vendor, model, kind=oscilloscope, channels, bandwidth_hz,
                                             sample_rate_sps[_per_channels_json], memory_depth_pts[_json], resolution_bits, transports_json
                                             [scpi-raw:5555, vxi-11, hislip?, usbtmc], lineage (agilent|tektronix), idn_format, citation,
                                             price_usd, emulated (bool)) — the WORKBENCH card
                         InstrumentEndpoint  one row per REACHABLE instrument (name, instrument (model row), transport, address — typed at
                                             runtime, NEVER seeded; the seed carries only the emulator's isle-local name), status, last_idn,
                                             checked_at
                         ScopeChannel        per endpoint × channel: enabled, scale_v_div, offset_v, coupling, bw_limit, probe, label
                         WaveformCapture     the CANONICAL record: endpoint, channel, acquired_at, points, x_increment, x_origin,
                                             x_reference, y_increment, y_origin, y_reference, format (BYTE|WORD), lineage, raw_sha256,
                                             raw_path (file store; inline for ≤ 1 Mpt in dev), sample_rate_sps, memory_depth_pts,
                                             trigger_json, source (real|emulated), source_ref (the twin session / stimulus / synth spec that
                                             produced an emulated capture — reproducibility)
  custom/scpi.py         IEEE 488.2 block encode/decode (stdlib), SCPI tokenizer (header tree, short/long forms, `?` queries, `;` chains)
  custom/lineage.py      agilent_preamble(text) / tek_wfmoutpre(text) → the canonical fields; to_volts / to_times (numpy)
  custom/client.py       ScopeClient: raw socket (stdlib) first; PyVISA resource string when pyvisa imports; capture(channels=[1..4])
                         pages WAV:STAR/STOP in 250,000-point chunks; refusal words kept ("The instruction is not supported!")
  custom/emulator.py     DHO804 EMULATOR: an asyncio TCP SCPI server (default port 5555 inside its container; any free port in selftests)
                         answering the subset above with 12-bit WORD data, 4 channels; sources: synth (sine/square/ramp/noise per channel),
                         replay (a stored WaveformCapture), device (the twin's pin trace → logic levels at 0/5 V, ADC ramp → analog)
  custom/sources.py      the signal sources (pure functions of the stimulus → samples at the emulator's sample rate)
  instruments_api.py     GET /api/instruments (models) · /endpoints · POST /endpoints (typed address) · POST /endpoints/<n>/idn ·
                         POST /endpoints/<n>/capture {channels, points} · GET /captures · GET /captures/<id>/chart ({ok, rows} long-form
                         for named-graph-panel: t_s + ch1..ch4 volts, decimated to ≤ 4000 rows for the screen, full data on /raw)
  instruments_page.py    /display/instruments: Instruments (cards of models), Endpoints table + add form (door-form), Channels table,
                         Captures table, ONE named-graph-panel per selected capture (4 series) — sci-xy-chart underneath, no new chart engine
  instruments_selftest.py
```
- **Emulator as an isle app:** tile `scope-engines` in `islemesh_catalog.SEED_CATALOG` (mesh-app, compose `docker-compose.scope-engines.yml`,
  JSON control port **9880** + SCPI 5555 exposed on the isle network, `provides_engine: 'scope'`), `pol dev deploy scope-engines`; the
  `instruments` module resolves it through the engines ladder like `board_engines` (binding row → topology → refusal naming the knob
  `SCOPE_ENGINES_URL`). Its cost block is measured per the cost rule.
- **Workbench tie-in (wb arc):** a fourth picker on `/display/workbench` — **Instruments** — cards from `/api/instruments` (channels,
  bandwidth, sample rate per channel count, depth, bits, transports, "emulator available"); Add puts the model on the bench
  (`bench.instruments`). A Mission Purpose can then say "needs N channels at ≥ X MHz" and the attempt verdict checks the bench's instruments.
- **Discovery (later):** mDNS `_scpi-raw._tcp`, `_vxi-11._tcp`, `_lxi._tcp` on the isle (Codex's mdns unit) → endpoint rows proposed, never
  auto-added.

## 3. Slices (each its own branch off dev; backend proven by selftests; the Chrome pass in the isle)
| # | slice | proves |
|---|---|---|
| a | ✅ **osc-0** BUILT 2026-10-26 (framework, branch dev-osc-0, directly — no agents): `modules/instruments` (scaffolded, kind library, requires board): `Instrument` / `InstrumentEndpoint` / `ScopeChannel` / `WaveformCapture` classes; seed = the four DHO800 rows from the datasheet table (`_dho()` builds them; per-channel-count sample-rate and depth tables as JSON) + the Keysight and Tektronix lineage rows with every number -1; `custom/catalog.py` (card text derived from the numbers: "1.25 GSa/s with 1 ch / 625 MSa/s with 2 ch / 312.5 MSa/s with 4 ch", "unverified" words), the bench doors (`Bench.instruments_json`, owned by instruments; board only carries the field + counts it); `/display/instruments` models tab (generic `cards` + a cited table); the **Instruments step** on `/display/workbench` (now 5 steps: picker with Add on oscilloscope rows only; the bench's instruments table with Remove). instruments 22/22; bench setup 0 failures | selftest: every DHO804 number equals the datasheet table above; unverified fields are -1/"unverified"; workbench picker's dataPath matches a registered route |
| b | ✅ **osc-1** BUILT 2026-10-26: `custom/scpi.py` (488.2 definite-length block encode/decode with BlockError on malformed headers; SCPI unit parser, long/short mnemonic matching, `idn()`), `custom/lineage.py` (Agilent ten-field preamble parse/format, Tektronix `WFMOutpre` field adapter, `samples` WORD-LE/BYTE, `volts`/`times`/`to_raw` by lineage) | round-trip selftests: encode→decode byte-exact; a captured DHO preamble line → the right volts/times (the scopehal formula); a Tek `WFMOutpre?` line → the same canonical fields; 12-bit WORD samples at full scale map to ±4 div |
| c | ✅ **osc-2** BUILT 2026-10-26: `custom/emulator.py` — a threaded stdlib TCP SCPI server (profile `dho804`): channels / timebase / acquisition / trigger / waveform command subset as scopehal sends it; sample rate = channel-count maximum capped by depth/(10 div × s/div); depth capped per channel count; 12-bit WORD over ±4 div (y_reference 2048, y_origin = offset/y_increment — OUR convention, said so); 250,000-point pages with per-page x_origin; setting changes drop the last acquisition (consistency rule); `*IDN?` honest by default (`POLARI,DHO804-EMU,<session>,osc-2`), `strict_idn` = the Rigol form with EMU markers; `refuse_wav_data` replays "The instruction is not supported!"; unknown headers queue -113 for `:SYST:ERR?`; `custom/sources.py` (sine / square / ramp / dc / noise / pulses / replay, deterministic, `describe()` for source_ref) | selftest spins it on a free port, drives it through `custom/client.py` over a raw socket: 4 channels × 250k-point pages, WORD, preamble consistent, `:ACQ:SRAT?` follows the channel count (1.25 G / 625 M / 312.5 M), unsupported commands answer the Rigol refusal text — PROVEN (capture selftest 53/53) |
| d | ✅ **osc-3** BUILT 2026-10-26: `custom/client.py` (`ScopeClient`: raw socket default, PyVISA resource path refusing BY NAME without the wheel — untested, D-osc-6; `capture()` = switch the asked channels on, `:SINGle`, `*OPC?`, then paged reads; sha256 per block; `ScopeRefusal` carries the words), `custom/captures.py` (endpoint rows typed at runtime, `start_emulator` in-process on a loopback port, `idn`, `capture` → `WaveformCapture` rows with the block inline ≤ 2 MB + sha256 + `source_ref`, `chart_rows` stride-decimated ≤ 4000 long-form t_s/ch1..ch4), nine doors in `instruments_api.py`, `/display/instruments` tabs endpoints / capture / chart (door-forms + tables + ONE `named-graph-panel` over the seeded GraphDefinition `instruments-capture`, four series). **Chrome pass owed in the isle** (the page is configured data; every path is a registered route by selftest) | selftest: capture via the emulator → `WaveformCapture` rows with sha256 of the raw block; chart rows decimated; refusal path — PROVEN 53/53 |
| e | ✅ **osc-4** BUILT 2026-10-26: `custom/device_feed.py` — `sources_from_stimulus(variant)` turns a cycle_stimuli record into channel sources (a button pin = a `pulses` line idling at 5 V with every `--pin-at` edge at cycle/CPS; ADC0 = `dc` mV/1000 or the twin's `triangle` ramp, a new source kind; wires noted), `sources_from_events(events, cps)` turns the twin's own `{"t":"pin"}` events into lines, `feed(emu, …)` sets the window to [0, seconds] (timebase + trigger offset), 2 V/div on fed channels (a 5 V line clips at the default 1 V/div, as a real scope does) and drops the last acquisition; door `POST /api/instruments/emulators/{name}/feed`; the capture's `source_ref` names the stimulus. Reading a LIVE twin session's events is a later bridge (the events door streams; the feed takes posted events) | selftest (62/62): the uno-light stimulus's five presses are five low pulses on CH1 with falling edges at 0.1 s + k × 157 ms within one sample and ~5 ms held; ADC0 0.75 V on CH2; the analog variant's 0.2..4.8 V triangle on CH3 (mean = the function's over 3.6 periods); events → PD6 on CH4; refusals |
| f | ✅ **osc-5 part 1** BUILT 2026-10-26: the emulator as an isle app — `polari-rf-node/prf-scope-engines/` (Dockerfile on the digest-pinned trixie base with Debian python3-numpy / falcon / gunicorn; `scope_engines_service.py` = the control API :9880 — /capability, /system-info, /cost, /emulators CRUD, /source, /feed — with up to five raw SCPI sockets :5555-:5559, one emulated instrument per port; `build.sh` vendors the framework's five emulator files (one source of truth, sha256 recorded); `cost.json` MEASURED), `docker-compose.scope-engines.yml`, the catalog tile `scope-engines` (mesh-app / engine `scope` / 9880) + the `scope` binder, `pol dev deploy scope-engines` (polari-cli dev.sh builds through build.sh then pushes), the framework seam `custom/scope_engines.py` (SCOPE_ENGINES_URL → the `scope` EngineProviderBinding → in-process; a declared worker that is unreachable REFUSES), `captures.py` routes start / source / feed / stop to the worker and the capture reads the worker-hosted scope over SCPI; `ModuleResourceProfile prf-scope-engines-resource-profile` + `modules/instruments/COST.md` (image 177.8 MB, build 20 s, 41 MB idle / 55 MB after a 4 × 250k capture at 0.38 s). Worker selftest 22/22 (the service run under wsgiref on a loopback port; the image also run as a container for the measurement); islemesh 103/103. ✅ **osc-5 part 2 BUILT 2026-10-26 (the two biggest makers' DIALECTS):** `custom/emulator_tek.py` — the Tektronix command dialect cited to scopehal's TektronixOscilloscope.cpp (DAT:SOU/WID 1|2/ENC SRI|RIB/START/STOP, `WFMO?` 22-field preamble, `CURV?` signed blocks, CHn:SCA/OFFS/COUP/BAN/PRO:GAIN?, DISP:WAVEV:CHn:STATE, HOR:MODE:SAMPLER/RECO, HOR:DELAY:TIME, TRIG:A:TYP/EDGE:SOU/LEV:CHn/EDGE:SLO, TRIG:STATE?, ACQ:STATE/STOPA/MOD, HEAD/VERB, EVMSG?; V = (raw − yoff) × ymult + yzero with OUR vertical convention stated); the Keysight Infiniium aliases on the agilent dialect (CHANn:RANGE/INP, WAV:BYT MSBF|LSBF, WAV:STR, ACQUIRE:SRATE?/POINTS?, ACQ:POINTS:ANALOG, ADER?, TRIG:SOURCE/SLOPE/LEV?); profiles `keysight-dialect` / `tek-dialect` whose limits are labelled DIALECT PROOF ONLY (no Keysight/Tek datasheet read — the Instrument lineage rows keep -1 and emulated=False, the card says "dialect proof only"); the client's tektronix path (`capture_tek`, `read_channel_tek`, `parse_tek_preamble`, signed INT8/INT16 incl. big-endian RIB; the doors pick the dialect from the endpoint's Instrument row); the worker vendors six files now. Dialects selftest 29/29. **REMAINING:** the actual isle deploy (registry on the core, TEST_ISLE ti-0) + the Chrome pass; real Keysight / Tektronix MODEL rows once a datasheet + programmer guide is read (then the dialect profiles become model profiles) | the isle app answers `*IDN?` from another node; the page shows a 4-channel capture from the emulator in Chrome |

## 4. Decisions (recommended option first; his call unless he says "go with your recommendations")
- **D-osc-1 `*IDN?` honesty.** Recommended: the emulator answers `POLARI,DHO804-EMU,<session>,<version>` by default and a knob
  `strict_idn=true` makes it answer the Rigol form for third-party tools that key on it — or always the Rigol string.
- **D-osc-2 first transport.** Recommended: raw SCPI socket (stdlib, no wheel, port 5555) in osc-2/3, PyVISA-py for VXI-11/HiSLIP/USBTMC
  when its wheel is in the image — or VXI-11 first (needs the RPC layer before anything is proven).
- **D-osc-3 the canonical record.** Recommended: keep the raw 488.2 block verbatim (sha256 + file) AND the preamble fields, volts
  computed on read — or store decoded floats only (loses reproducibility and 12-bit exactness).
- **D-osc-4 where the emulator runs.** Recommended: its own worker image / isle app (`scope-engines`, 9880 + 5555) — or inside the backend
  process (cheaper now, but then an isle member cannot reach a "scope" on the LAN the way it reaches a real one).
- **D-osc-5 vendor order after Rigol.** Recommended: Keysight (same command lineage, ~a profile) then Tektronix (second adapter) — or Tek first.
- **D-osc-6 dependencies.** Recommended: admit `pyvisa` + `pyvisa-py` (MIT) to the backend image as OPTIONAL imports, with `zeroconf`
  only when discovery lands — or stdlib only forever (then no VXI-11/HiSLIP/USBTMC instruments).

## 5. Rules this plan keeps
derive-or-cite ([[derive-or-cite-chip-data]]: -1/"unverified" are honest values); no raw JSON on screens — the chart is `named-graph-panel`
over a GraphDefinition, tables are configured ([[no-raw-json-on-screens]], [[frontend-graphing-capability]]); no real addresses in tracked
files — endpoint addresses are typed at runtime ([[privacy-no-real-identifiers]]); the emulator carries a measured cost
([[resource-cost-tracking]]); every capture reproducible from stored inputs ([[reproducible-initial-conditions]]); engines resolve
through the same ladder as the board engines ([[develop-across-devices]]); testing through the isle, not the pipeline VM
([[test-isle-plan]]); no agents while his rule stands.
