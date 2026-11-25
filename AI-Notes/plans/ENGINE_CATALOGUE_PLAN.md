# Engine catalogue, categories and layout — PLAN ONLY (2026-11-24)

The user, 2026-11-24: engines should be easy to find, sorted by category (one category being chip emulators); do both
the catalogue rows and the folder move; combine engines where it makes sense. Engines are hand-defined and bound for
now. Generating them from custom chips comes later (`HARDWARE_SIM_GENERALITY_PLAN.md` §2).

## 1. What exists (read from source 2026-11-24)

| Worker image (`polari-rf-node/`) | Base | What is in it | Local size |
|---|---|---|---|
| `prf-board-engines` | debian trixie | simavr twin (`polari_avr_twin.c`, `twin_ctl`), avr toolchain and flasher, sessions, the door | 603 MB |
| `prf-esp-engines` | ubuntu 24.04 | ESP-IDF, Espressif QEMU + the `polari-block` pin device, the C3 twin, sessions and door (copied from board) | 1.9 GB |
| `prf-bridge-engines` | debian trixie | JDK 21 + maven: builds and hosts the generated Java bridges | not built here |
| `prf-formal-engines` | debian trixie | Frama-C (opam build), CBMC, cppcheck | 594 MB |
| `prf-pcb-engines` | debian trixie | the PCB/EDA service | not built here |
| `prf-scope-engines` | debian trixie | the scope emulation (numpy) | 178 MB |

Resolvers, one per using module, each with its own idea of an engine kind:
`board/custom/board_engines.py` (kinds C, Verilog, flasher, simulator; families avr and esp),
`computelod/custom/eda_engines.py`, `pcb/custom/pcb_engines.py`, `mathproofs/custom/proof_engines.py`,
`cmod/custom/solve_engine.py`. ngspice is found on the host (`electrodevice/custom/ngspice_shared.py`), not in a worker
image. The image names are referenced from about 100 tracked files (Dockerfiles, CLIs, release definitions, selftests).

## 2. Categories

| Category | Members today |
|---|---|
| chip-emulator | simavr (AVR), Espressif QEMU + `polari-block` (C3), Renode/Verilator (hwsim) |
| toolchain | avr-gcc, ESP-IDF |
| flasher | avrdude, esptool |
| circuit-solver | ngspice (shared library or executable) |
| formal | Frama-C, CBMC, cppcheck, the proof engines |
| eda | the PCB engines, the computelod EDA engines |
| instrument | the scope |
| bridge | the Java bridge builder and host |

One engine can carry more than one category (an image is a box; the category belongs to each engine in it).

## 3. ec-1, the catalogue as rows

- One row per engine: name, category, family (avr, esp, …), the binary or entry point, the worker image that carries
  it, its port, the knob that points at a remote worker, its licence note and its `cost.json`.
- For chip emulators, also the binding (`polari-avr-twin`, `polari-c3-twin`) and its declared capabilities. This is
  the same declaration as the generality plan's g-2b, stored once.
- The five resolvers read the rows instead of their own tables. Their ladders (remote knob, local binary, local
  image, provider, refusal) stay as they are.
- `pol engines list [--category chip-emulator]` and `pol engines show <name>` print where each engine is and whether
  it can be reached from here.
- This changes no paths and no images, so nothing built or released moves.

## 4. ec-2, the folder move (after release 94 is run)

- `polari-rf-node/engines/<category>/<image>/`, for example `engines/chip-emulators/avr/` and
  `engines/chip-emulators/esp/`. An image that holds several categories sits under its main one, and the catalogue
  says what else is in it.
- **The image names and tags stay the same,** so the store apps, the release packets and the devices that already
  pull them are not affected. Only the build context paths change: the Dockerfiles' `--build-context` lines, `pol
  build` and the CLIs that build them, and the docs.
- One commit per repository, innermost first. Then every image is rebuilt with no change of content, and its layer
  digests must match the build from the old path. That is the test that the move changed nothing.

### 4a. One folder layout for every engine (the user, 2026-11-24: "a specific and repeatable directory structure that
is generalizable across kinds of engines")

```
polari-rf-node/engines/
  _shared/                     what every worker reuses
    service/                   the gunicorn + falcon skeleton: health, cost report, refusal words
    frames/chip-emulator/      sessions + door (today's board_sessions.py, twin_door.py), shared by every chip emulator
  <category>/                  chip-emulator | toolchain | flasher | circuit-solver | formal | eda | instrument | bridge
    CONTRACT.md                the category's contract in words
    contract.json              the same as data: what a member must answer (chip-emulator: the control line)
    conformance/               the one suite every member of the category passes
    <engine>/                  one worker image
      engine.json              its catalogue rows: each engine in it, category, family, port, knob, licence, capabilities
      Dockerfile
      README.md
      cost.json
      service/                 <engine>_service.py, built on _shared/service
      binding/                 the adapter that speaks the category's contract (chip emulators: polari-avr-twin, polari-c3-twin)
      tools/                   polari-* command-line entry points (polari_c3_run, polari_idf_build, …)
      patches/                 patches applied to upstream sources (today's qemu-patches)
      vendor/                  pinned third-party sources or wheels, each with its hash
      tests/                   in-image tests, run during the build
```

- A folder holds only the parts it has: no empty `binding/` for a scope.
- The rows in §3 are loaded from the `engine.json` files, so the folder and the catalogue cannot disagree.
- `pol engines check` validates every folder against this layout, and each `engine.json` and capability declaration
  against its category's `contract.json`. It runs in the selftests, so the layout stays repeatable.
- A new engine is a new folder under its category, with an `engine.json`, a Dockerfile, a binding where the category
  has a contract, and a pass of that category's conformance suite. A generated engine later fills in the same folder.

## 5. No combining (the user, 2026-11-24)

"maybe we do not do combining then, folder layout sounds like a good way to do reorganizing to have things more
uniform though". Every worker image stays its own image. What is shared is source, not images: `_shared/service/`
and `_shared/frames/chip-emulator/` are copied into each image at build time, as the ESP image already copies the
sessions and the door from the board folder today.

Open, separate from combining: ngspice has no worker image (it is found on the host). A `circuit-solver/ngspice/`
engine would let the circuit checks run anywhere and in the release-image gate. Ask the user before adding it.

## 6. Order

1. Release 94 is run (no paths move before it).
2. ec-1, the rows and `pol engines`.
3. ec-2, the move into the layout of §4a, with `pol engines check`; images rebuilt and their layers compared.
