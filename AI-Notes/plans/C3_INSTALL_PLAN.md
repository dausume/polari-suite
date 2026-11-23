# The installer takes a C3 (`ins-c3`)

Written 2026-11-23 on pol. State words: source-tested, staged, installed, live-verified.

The user's direction (2026-11-22): "we need to get board simulations and hal fully working so we can prep loading to
real boards". The UNO has one guarded path to a real board: the Firmware Installer (build, plan as a dry run, the
confirmed-sim gate, install, a record). The C3 has the pieces and no such path. This plan gives the C3 the same path
through the same installer. It flashes nothing: a real flash needs a board on pol and the user's word.

## 1. What was read in the source

| Piece | UNO | C3 today |
|---|---|---|
| Variants | `variants.py`, FirmwareVariant rows | `variants_c3.py` (`esp32c3-light` has pads) |
| Build | `gen` + `build`, a `.hex` | `gen_c3` + `build_c3` through the engine ladder. The record holds the merged flash image as `hex_path`, its sha256 as `artifact_sha256`, the app's sha256, the sizes, `flash_args.txt` and the three files a board is flashed with |
| The image a board gets | the `.hex` | the chip-HAL build (`pin_shim` 0). The shim build (`pin_shim` 1) talks to no pad and is for a batch run only |
| Sim | the simavr twin, or a twin session | a twin session on the pin-model QEMU (`c3g-3`, source-tested); the four Purposes as batch runs (`pol firmware prove esp32c3-light`) |
| Flash command | `flash.py`: avrdude, rendered from its ProgrammerKind row, with a read-back | `flash_c3.py`: esptool, rendered from its ProgrammerKind row and idf.py's own `flash_args`; a dry run by default; needs a detected board and `--yes`; counts esptool's "Hash of data verified" once per file |
| The gate | `sim_gate.py`: the four Purposes passed on the config's own firmware, and a person's tick for the exact program | the gate reads configs, runs and a sha256. It names no board. Its own sim run asks the UNO twin whether it is ready |
| The installer | `installer.py` | names the UNO in its work folder, build, target, plan, both runs and the page document. `install_cli.py` refuses any other board. `pol board flash c3` reaches a board without the gate |

Asked of the code on pol, with no server and no network (2026-11-23):

- The gate already holds `esp32c3-light` as a built config of the light Mission: its four Purposes must pass before
  a real board. `esp32c3-echo` is not gated (no Mission names it), as `blink-only` is not for the UNO.
- A stored Purpose run of a C3 config names the image it ran (`sha256` in what the run observed). A UNO run does not.
- The Purposes run the chip-HAL build when the engine has the pin model, and refuse otherwise.
- The C3 build is reproducible (`CONFIG_APP_REPRODUCIBLE_BUILD=y`): the same sources on the same engine image give
  the same sha256, so a proof, a tick and a flash can be held to one number.
- On two real builds on pol the merged image (4,194,304 bytes) holds the three files byte for byte: the bootloader
  at 0x0, the partition table at 0x8000, the app at 0x10000. Every other byte is 0xFF. So check 2 below can be
  made exactly, file by file.

Three things follow. A C3 can be flashed today by a verb that asks no gate. Nothing checks that the image the twin
ran is the bytes a board would get: the twin boots the merged image, esptool writes three files. And the gate counts
Purpose runs by config name, while one C3 config name covers two images (the shim build and the chip-HAL build).

## 2. The rule

One installer. What differs between boards is one small table, `board/custom/install_kinds.py`, in the way
`twin_kinds.py` holds what differs between twins. `installer.py` asks the table which board a variant, a build or a
target belongs to.

The UNO's own steps stay in `installer.py` as they are, so its existing checks hold without a change. The C3's
steps are a new module, `board/custom/install_c3.py`: the work folder, how a variant is built, the limits, how a
plan's command is rendered, how the run is checked, and the words a person reads. The doors stay the same doors:
they take the board as a field, and no route is added. Which board a config belongs to follows the same rule as
`twin_kinds.of(config)`.

## 3. What a C3 install is

**Real.** The plan is the dry run: esptool's exact command from `flash_c3.argv_for`, the engine that would run it,
the gate's verdict for this config and this image, and what would be stamped. Before it offers anything the plan
checks four things and says each in words:

1. The build is the chip-HAL build. A shim build is refused for a real board: it drives no pad.
2. The three files are the image the twin ran. For each file of `flash_args.txt`, the merged image holds the same
   bytes at that offset. If one differs the plan is refused: what was simulated is then not what would be written.
3. The gate, as for the UNO: the four Purposes passed on this config's own firmware, and a person ticked this
   exact image (the Sim bench's tick is taken at the session's locked image, so it is the same sha256).
4. The Purposes ran this image: each proving run names this image's sha256. A run on another image, or one that
   names none, does not count for a C3, and the plan says which Purpose and how to run it again.

The run needs the plan, `confirm`, this host, a detected C3 and the gate read again. It calls `flash_c3.flash`.
`pol board flash c3 --yes` stays for a bench test and says that it asks no gate and that `pol board install c3
--real` does.

**Sim.** A twin session started with this build's own image (`twin_sessions.start(..., hex_bytes=...)`). It is
installed when the worker answers and the session's sha256 equals the build's. The record says it was the twin and
which session; a press then goes through the Sim bench. The four Purposes run as batch runs on the ESP engines,
which may be on another device. The gate's own "run the Purposes here" step asks the C3 engines whether they are
ready, where it asked the UNO twin for every config before.

**Not known yet, said in the plan's words:** no C3 is on the bench, so its USB ids are not in the register and
detection cannot name one. Until a board is plugged in once, a real plan can only be made for a port given by hand,
and it stays a dry run.

## 4. Phases

| Phase | What | Gate | State |
|---|---|---|---|
| ins-c3-1 | The table; the installer reads it; a C3 build, plan (real: dry run with the four checks; sim: a session) and run; `pol board install c3`, `pol board gate`, `pol board confirm-sim` for a C3 config | Offline, with a made-up worker and a made-up esptool: every UNO installer check unchanged; a C3 real plan prints esptool's command and is refused without the gate, with a shim build, with a file that differs from the image, and with a Purpose run on another image; a run is refused without a detected board | source-tested 2026-11-23 (§6) |
| ins-c3-2 | The Install Firmware page shows the C3: the panel takes the board from its configuration | Browser tests | source-tested 2026-11-23 (§7) |
| ins-c3-3 | In a release; `pol board install c3 --real --dry-run` on pol against the isle | The dry run prints on pol; the gate's words are right for a config that was proved and ticked | needs a release |
| ins-c3-4 | A real flash | A C3 on pol, the user's word, the gate offered | waits for a board and the user |

## 5. Open

- Which C3 board the user has or will buy. The seeds draw the ESP32-C3-DevKitM-1. Its USB bridge decides the port
  and how the chip is put into download mode.
- Whether `pol board flash c3 --yes` should refuse without the gate, as `pol board flash uno --yes` does not either.
  Left as it is: both are bench verbs, and the installer is the guarded path.

## 6. ins-c3-1 as built (2026-11-23, source-tested)

New: `board/custom/install_kinds.py` (the table, 52 lines), `board/custom/install_c3.py` (the C3's steps, 232 lines),
`board/board_installer_c3_selftest.py`. Changed: `installer.py` (asks the table; the UNO's steps as they were),
`installer_api.py` (the document door takes `?board=`; the plan door also answers the checks), `sim_gate.py` (a C3
config's Purposes ask the ESP engines whether they are ready), `install_cli.py` (`pol board install c3`),
`flash_c3.py` (two lines: this verb asks no gate), polari-cli `scripts/board.sh` (help only).

How it behaves, beyond §3:

- Check 2 also refuses when the merged image on disk is not the one the build recorded.
- "Install anyway" with a reason passes the gate and check 4 (both are about the simulation that was run). It
  never passes check 1 or 2, at plan time or at run time. The run reads the four checks again.
- `undetected:<board>` (either board): a plan that can be read before a board was ever plugged in. It is always
  refused, so nothing can run from it. `pol board install c3 --real` with no board plans against it and prints
  esptool's command and the checks. This is also new for the UNO: `--real` with no board and no `--yes` now prints
  the dry run instead of a bare refusal (exit 3 either way).
- A C3 sim install starts a twin session with the build's own image and leaves other sessions alone. No bridge is
  attached: the record names the session and how to press it.
- The page document for a C3 (`?board=c3`): the C3's builds, variants, targets, modes and running sessions; the RAM
  limit is the build's own DRAM total, or none when the build stated none. The UNO's document is the same as before
  apart from two new keys (`kind`, `kinds`).

Tested, with no network, no engine, no board (made-up build store, ESP worker and esptool):
`board.board_installer_c3_selftest` 52 of 52 (with the page-words check of ins-c3-2); the UNO installer checks 61 of 61, none changed; the C3 and UNO
session checks 33 of 33 and 28 of 28; `board.board_c3_selftest` 46 of 46.

Not tested: a real C3 build through the installer; a real esptool, board or USB detection (no C3 ids in the
register: the test uses a hand-made board row); a real ESP worker; a session that starts on the wrong image (the
branch exists, nothing drives it); the CLI against the doors end to end; the gate and tick doors over HTTP with a
C3 config; the page (ins-c3-2).

## 7. ins-c3-2 as built (2026-11-23, source-tested)

The panel names no board. The server sends each board's page words in the document (`page`: the twin note, the
no-board sentence, the artifact word, the twin's name in the result, and whether a bridge is attached after a twin
install), from `installer.PAGE` for the UNO and `install_c3.PAGE` for the C3. The panel asks for `?board=<its board>`,
shows a Board chooser when the document lists more than one, lists a plan's checks, shows a refused plan's command
and checks (dimmed, never runnable), says "limit not stated" for a RAM limit the build did not state, and does not
attach a bridge after a C3 twin install: the record's notes say which session and how to press it. With an older
server (no `page`) the panel shows today's UNO words.

Tested: the panel's browser tests 17 of 17 (8 new); the server's page words in `board.board_installer_c3_selftest`.
The whole board module with ins-c3-1 in: 1,248 of 1,249. The one failure was td-2 "unknown session": under load it
got the 5 s answer timeout instead of the door's close code. Alone it passed 20 of 20 three times. It does not touch
the installer. The cause was a race in the control hub, fixed the same day (`TESTING_OWED.md` §81 addendum 3).
Not tested: the page in a real browser against a backend; a C3 real install on the page.
