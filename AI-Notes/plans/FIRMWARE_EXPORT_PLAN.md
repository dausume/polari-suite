# Firmware export (exp arc): carry a reviewed, independently-buildable directory out of Polari before anything is ever flashed

**Date:** 2026-10-06 · **Status: PLANNING ONLY — nothing in this document is to be built until he says so (his steer,
below).** Read-only research against the tree on `dev` (BOARD_PROGRAMMING_PLAN, C_MODULARIZATION_PLAN, PCB_FROM_SCRATCH_PLAN
§5b, DEMONSTRABLES_PLAN §9, OFFLINE_INSTALL_PLAN, DOWNLOADS_PAGE_PLAN, CICD_PIPELINE_PLAN, GRPC_BRIDGE_PLAN, the Isle
Manager app, polari-app-shell, `AI-Notes/designs/HARDWARE_CAPABILITY_REGISTER.md`). Companions: all of the above; memory
`language-layering`, `reproducible-initial-conditions`, `resource-cost-tracking`, `offline-app-debs`.

## §0. The ask, verbatim, and his steer on how to plan it

His ask (2026-10-06): *"something we want to ensure we can do is be able to export a directory that carries a lib that
enables you to simply compute the firmware. And then also we need a lib that can perform the install of the JavaFx
bridging app as a deb. And then we need a JavaFx app that is a bridge app that can act as a generalized installer via
both usb and usb-c. We should be able to request the C based firmware and/or the JavaFx apps as either directories of
compilable code as online or offline versions, or as already bundled apps, tars, or iso's, whatever is most convenient
depending on what we are installing. So we need to plan for that. This way we can proof out that the code being made
makes sense, and it is not just some nonsense we are spitting out and potentially destroying hardware by flashing it
with it."*

His steer on the plan itself, while this document was being drafted: *"planning and analysis of what we have and what
makes sense to build in the direction of to minimize bloat and build on what we already have, do not build it yet."*
§1 below is therefore the heart of this document, not a preamble: for every piece the ask needs, it names the existing
thing to build on and what would be pure duplication if a new thing were built instead. **Nothing in §2–§5 is scheduled
— it is the shape a future slice would take, ranked by how much it reuses, with an explicit refusal list of what we are
NOT adding (§5 bloat budget).**

**Rulings this arc inherits, unchanged:**
- C / Verilog / SystemVerilog only on a device; Java — JavaFX when a window is needed, headless otherwise — is the
  bridge to the kernel/hardware virtualization; everything else is the web stack (`language-layering`).
- USB or USB-C only, directly or through a USB adapter Polari knows (BOARD_PROGRAMMING_PLAN §0/§2a).
- Derive-or-cite: every number in an exported README traces to a row with provenance, never invented.
- Reproducibility: every exported artefact carries its inputs by sha256, tool/image versions, knobs, and (if any) seeds
  — `reproducible-initial-conditions`; this arc's "proof-of-sense gate" (§3) is that rule applied to a thing a person is
  about to solder voltage into.
- Resource cost: every added piece (toolchain image, JDK/JavaFX runtime, jpackage output) carries a measured cost and
  composes through the dependency closure (`resource-cost-tracking`) — §5 is this arc's reading of that ledger.
- Offline debs carry every dependency and install only what the target lacks (`offline-app-debs`); this is already the
  posture the FIRMWARE export's offline toolchain form must match, not reinvent.
- "The project is the capability" — a module's free code is a real, buildable project (cmod's central claim); an
  EXPORT is that same claim pointed at a person standing outside the server, about to touch hardware.

## §1. What exists today vs what the ask needs — build on this, do not duplicate it

| the ask needs | the EXISTING thing that already does most of it | the gap (small, named) | what would be DUPLICATION if built fresh |
|---|---|---|---|
| "a lib that enables you to simply compute the firmware" | `modules/cmod/custom/glue_build.py` (cmod-1): renders a `CGraph` to a real project (`Makefile`, `hal.c/h`, `polari_graph.c/h`, `board_config.h`, `<class>_packets.h`) that **`make` alone builds**, with a repro block (sha256, avr-gcc 14.2.0, make-alone proof, byte-identical .hex checked against the recorded sha, measured in `prf-board-engines:trixie`) | the project only builds **inside the engines image, or with avr-gcc/avrdude/simavr already on PATH** — there is no standalone script that carries or fetches the toolchain itself and nothing is ever copied OUT of the server's working tree to a person's machine | a second build system, a second repro-block format, a second "make alone" proof — `glue_build.py`'s logic is the lib; exporting means **packaging its own render + its own verify call**, not writing a new one |
| "a lib that can perform the install of the JavaFx bridging app as a deb" | the bridge is ALREADY a generated, buildable Maven project (`grpcbridge/custom/java_bridge.py:generate_project`, `pom.xml` with protobuf-maven-plugin + grpc-java) that is ALREADY downloadable as a tar.gz, built on demand and **never stored** ("the tarball is NOT stored; it is rebuilt deterministically at request" — `java_bridge.py:8-9`), plus `install-ubuntu.sh` + a systemd unit, LIVE-VERIFIED on staging 2026-07-10 (grpc-j2) | it ships as a tar.gz + a shell installer + a systemd service, not a `.deb`; nothing jpackages it; it is headless, not the JavaFX app the ask wants wrapped around it | a second Maven-project generator, a second systemd unit, a second staging/download route — the install LIB is a thin wrapper that turns the EXISTING generated project into a `.deb` using the EXISTING `build-polari-*-deb.sh` / `pol-build` conventions (control/postinst/polkit pattern already proven by `Isle-Mesh/isle-manager-app/shells/build-deb.sh` + its `debian/DEBIAN/{control,postinst,prerm}` + `usr/share/polkit-1/actions/*.policy`), not a bespoke packager |
| "a JavaFx app that is a bridge app that can act as a generalized installer via both usb and usb-c" | TWO existing JavaFX precedents, each proving HALF the shape: (a) `Isle-Mesh/isle-manager-app` — a standalone JavaFX **Maven** app with real native screens (HomePage/PortsView/AppsView/SecurityView/PermissionsCheck), packaged as its OWN `.deb` (control + postinst that symlinks a bundled CLI onto PATH + a polkit `.policy`), pkexec'd scripts called from Java; (b) `polari-app-shell/desktop` — a Java Swing frame hosting a JavaFX `JFXPanel` (`ShellFrame.java`) with a narrow, ALREADY-PROVEN pkexec security pattern (`core/.../host/HostInstall.java`: a name validated against a strict allowlist regex turns into a FIXED argv array — never a shell string — `pkexec isle store install <name> --yes`; the actual `Process` call lives in `:desktop`'s `HostProcess`) | neither app has hardware-detection screens (USB VID:PID scan, board/adapter match, a build-verify gate, a flash confirm); `app-shell` is shaped to be a BROWSER CHROME around the Angular web UI (JCEF/WebView), not a place to hand-build native device screens; `isle-manager-app` has real native screens but is scoped to isle networking, not boards | a third JavaFX application framework, a second pkexec security pattern, a second Maven/jpackage/deb pipeline — §2's recommendation is to build the Installer App **packaged exactly like `isle-manager-app`** (same pom shape, same DEBIAN triple) while **reusing `HostInstall`'s fixed-argv-allowlist pattern** verbatim for its own pkexec calls, because BOARD_PROGRAMMING_PLAN §7a's flasher argv is already rendered server-side (`board.custom.programmers.render_dry_run`) — the Java side only ever executes a pre-rendered, server-signed argv, never builds its own shell line |
| "request as directories of compilable code (online/offline), already bundled apps, tars, or isos" | `/downloads/apps` already does exactly this shape for MODULE debs: **generate-on-request, stream, delete after a TTL, never store by default** (`appstore/app_deb_builder.py`, `DOWNLOADS_PAGE_PLAN.md` dl-4 "generate ON REQUEST, never store by default"); the bridge tarball already follows the same rule (§ above); `OFFLINE_INSTALL_PLAN`'s standard offline-bundle template (apt/images/router/debs/modules/engines/hardware/scripts sections, each present-or-EMPTY) is the existing shape for "offline version"; the ISO plan (`POLARI_ISO_PLAN.md`) is the existing shape for "iso" | no FORM exists yet for firmware/bridge exports specifically (no Export row, no README/lib/twin/flash bundle); nothing jpackages the bridge or an installer app into an app-image | a second on-demand-generation mechanism, a second TTL ledger, a second offline-bundle template, a second ISO plan — §2's `Export` row is a NEW ROW over the SAME generate-on-request discipline, and §2's offline toolchain form is `docker save prf-board-engines:trixie` (§5), not a new toolchain packaging effort |
| "flash gate: proof the code makes sense, never destroy hardware" | `board.custom.flash.plan/flash`: DRY-RUN by default, needs a DETECTED `BoardInstance` + `--yes`, avrdude's own read-back verify (never `-V`), stamps `firmware_sha`/`last_flash_at` ONLY on a verified run; `board.custom.installer`: an `InstallPlan` row fixes the argv before confirm, re-checks compat at run time, refuses a plan made for another host; cmod-1's byte-identical-rebuild proof is the existing "does this code make sense" measurement | none of this runs OUTSIDE the server process today — a build exported as a directory has no equivalent local gate; a person with the export and a USB cable but no Polari server has nothing that refuses a bad flash | a second flash-safety design — §3 is `flash.py`'s existing read-back-verify + size-refusal + sha-check, re-expressed as a shell script shipped INSIDE the export, not a new safety model |
| where an export's files live while someone downloads it | `module_home()` (`polariApiServer/module_home.py`): env override → `/app/data/<name>` (the persistent volume every backend container already mounts) → `~/.cache/polari-<name>` on a bare host; its own docstring already names the eventual SeaweedFS-backed path as the env-override case, same as `pcb`/`board`/`hwnocode`/`faults` | nothing — this already does the job for a transient generation directory | a second file-store integration, a second storage-location convention |

## §2. The export model — a row and five directory shapes, built on what §1 named

**`Export`** (one row per request; modeled on `FirmwareBuild` + `DebGenerationRecord`, not a new concept): `what`
(`firmware` | `bridge-app` | `installer-app` | `both`), `form` (`source-dir` | `bundle-app` | `tar` | `deb` | `iso`),
`mode` (`online` fetches the toolchain | `offline` carries it), `target` (host OS/arch; for firmware, the
`BoardDefinition`), `provenance` (the `FirmwareSolution`/`FirmwareBuild`/`CGraph` shas, board sha, engine
versions+digests, the existing repro block — not a new one), `checksums`, `requested_at`, `expires_at` (the dl-4 TTL
idiom), `status` (queued/running/ready/refused). Generated into `module_home('exp')` (§1's last row), streamed, and
deleted on TTL — the SAME discipline as the bridge tarball and the app debs, not a new one.

### The FIRMWARE export directory (`firmware/<solution>/`)
```
firmware/<solution>/
  README.md            rendered from the SAME rows the firmware page already shows (CGraph schedule lane,
                        register map with citations, board, sizes, hex sha) — a view, not new content
  <the cmod project>    hal.c/h, polari_graph.c/h, board_config.h, *_packets.h, Makefile — UNCHANGED, cmod-1's
                        existing output, copied verbatim
  toolchain/            online: a pinned fetch script (apt-get install gcc-avr=<ver> avr-libc=<ver> avrdude=<ver>
                        simavr=<ver>, versions read off prf-board-engines's own `dpkg-query` build line, §5);
                        offline: `prf-board-engines.tar` (`docker save`, §5) — NOT a second toolchain build
  lib/polari-firmware-build.sh   make → hex + sha256 → compare to the Export's recorded sha → PASS/REFUSE
                        ("simply compute the firmware" — a thin wrapper around `make`, nothing novel)
  twin/                 the simavr/Renode twin invocation already proven in cmod-1/sc-1, so the export runs the
                        SAME proof a person can watch before touching hardware
  flash/                the EXACT avrdude argv (`board.custom.programmers.render_dry_run`, already rendered
                        server-side) + the read-back verify step + the REFUSAL if the rebuilt sha != the
                        reviewed sha — §3
```

### The BRIDGE export
The existing generated Maven project (§1) + `lib/polari-bridge-install.sh`: builds the SAME project with `mvn
package` (unchanged), then either `jpackage` (a self-contained app-image/`.deb` with a bundled JRE) or
`dpkg-deb` with the project's jar + a systemd **user** unit (closer to today's `install-ubuntu.sh` + system
unit — a decision, not a given, §6 D-exp-2) — reusing the `control`/`postinst`/`prerm` TRIPLE `isle-manager-app`
already has, not a new deb format.

### The INSTALLER APP
One JavaFX app, packaged like `isle-manager-app` (§1), generalized (not board-specific): detects boards/adapters
over USB/USB-C via the board/adapter register's VID:PIDs (reusing `hwmap.custom.scanner` + `board.custom.detect`
— unchanged, already host-side Python; the Java side calls the server's `/api/board/installer` document, it does
not re-implement detection), shows an export's `README.md`/register map as-is (no raw JSON — `no-raw-json-on-screens`),
runs the build-verify gate (`lib/polari-firmware-build.sh`, shelled out, output shown verbatim), flashes through
`HostInstall`'s fixed-argv-allowlist pattern (the argv is the SERVER's `plan.argv`, pkexec'd, never built by Java),
and attaches the bridge (launches the bridge jar/deb it just installed). **Shared pieces named, per his ask:** the
Maven/javafx-maven-plugin/maven-shade-plugin shape and the DEBIAN control/postinst/polkit-action triple come from
`isle-manager-app`; the fixed-argv pkexec pattern (`HostInstall`, `HostProcess`) comes from `polari-app-shell`. It is
a SIBLING of `isle-manager-app` (same build shape, its own small codebase), not a mode added to `app-shell` (a
browser-chrome shell is the wrong shape for native USB-scan screens) and not a feature bolted onto `isle-manager-app`
(wrong audience — isle networking vs. board flashing). Forms: `source-dir` (online/offline, a plain Maven
checkout + `toolchain/` = JDK+JavaFX+Maven, pinned or vendored), `bundle` (`jpackage` app-image), `deb`, `tar`.

### ISO
Referenced, not re-planned: `POLARI_ISO_PLAN.md`'s offline-first image already carries the apt pool + platform debs;
an export's `.deb` forms (firmware toolchain is NOT debbable — it is a directory or a docker tar, see §5) ride
inside that ISO the same way any other platform deb does. No new ISO work in this arc.

## §3. The safety gate — detail (his sentence: never flash what did not come out of a reviewed, independently buildable export)

| gate step | mechanism | already exists? |
|---|---|---|
| review artefact | README.md with the schedule lane, register map (with citations), board, sizes — a person reads this BEFORE building anything | yes — rendered from existing rows (§2) |
| byte-identical rebuild | `make` inside the export, compare the new hex's sha256 to the Export row's recorded sha; a mismatch REFUSES, named | yes — cmod-1's proof, re-run standalone |
| size limits | flash_kb/ram_kb refusal | **already exists** (`BoardDefinition.flash_kb/ram_kb`, firmwarefaults' cost gate) |
| board match | VID:PID scan + (where the bootloader/programmer exposes one) a signature/fuse read BEFORE write | VID:PID match exists (`hwmap`/`board.custom.detect`); a pre-write signature read is a **named gap** — avrdude's `-p` already refuses a signature mismatch by default (no `-F`), so the existing flasher argv (never passes `-F`) already gives this for free |
| read-back verify | avrdude's own verify (no `-V` ever passed) | yes, `flash.py` |
| "what this will do to the pins" table | the register map rendered from `RegisterDefinition`/pin bindings — already a row-backed table (`/display/c-atoms`, `hwfpga` register views) | yes — a view, not new data |
| dry-run default everywhere | `flash.plan()` always dry-runs; `--yes` + a detected instance is the only path to a real write | yes |
| **what BLOCKS vs WARNS** | BLOCK: sha mismatch, no detected board, size over limit, signature mismatch, plan made for a different host/board, missing `--yes`. WARN (shown, not refused): an untested configuration, a knob left at a non-default, a board seen for the first time | the block list is existing refusal code (`FlashRefused`, `InstallRefused`); the warn list is new UI text only, no new mechanism |

## §4. Slices (ranked by reuse — nothing here is scheduled; his go is required before any of it starts)

Ranked by how much existing code each reuses vs. how much is net-new, highest reuse first:

1. **exp-0 (highest reuse)** — the `Export` row (new fields on the existing FirmwareBuild/repro-block shape, not a
   new schema) + `pol firmware export <solution> --form source-dir --mode online|offline`, built ENTIRELY from
   cmod-1's `glue_build.py` output + `module_home('exp')` + the dl-4 generate/stream/TTL pattern. Proof: on a machine
   WITHOUT Polari (isle-core or econ-core), the exported `lib/polari-firmware-build.sh` alone reproduces the same
   sha cmod-1 already measured for `uno-sim-rig` (4188f6ae…) — zero new infrastructure, one new script.
2. **exp-1** — the bridge export + `lib/polari-bridge-install.sh` producing a `.deb` via the EXISTING generated
   Maven project + the EXISTING isle-manager-app control/postinst/polkit triple. No new Java code; packaging only.
3. **exp-2 (most net-new)** — the JavaFX Installer App itself: detection screens, the gate, the flash confirm,
   source-dir/jpackage/deb forms. This is the one slice that is a genuinely new codebase (small, per §2), because
   no existing JavaFX app has hardware-detection screens.
4. **exp-3** — additional forms (tar, offline bundles carrying `prf-board-engines.tar` / a JDK+JavaFX runtime), the
   ISO reference tie-in, the `/downloads/apps`-style catalogue entry for exports (reusing dl-4's page, not a new page).
5. **exp-4 (lowest priority, depends on exp-2)** — a Polari UI (status rows, artefact links) on the firmware/installer
   pages requesting an export — a configured-table view over the `Export` row, no new component.

**Do-not-build list (explicit, per his steer):** no second toolchain build (the image is `docker save`d, never
rebuilt for this arc); no new pkexec/privilege model (HostInstall's pattern is reused verbatim); no new deb format
(isle-manager-app's triple is reused verbatim); no ISO work (referenced only); no new file-store integration
(`module_home` as-is).

## §5. Costs, licences, bloat budget

| piece | size (measured where cited, else estimate) | what it reuses | what we refuse to add |
|---|---|---|---|
| firmware online toolchain | a pinned `apt-get install` list, **0 MB stored** (fetched at use) | the exact package names + versions `prf-board-engines`'s Dockerfile already installs and prints via `dpkg-query` | a second version-pinning scheme |
| firmware offline toolchain | `docker save prf-board-engines:trixie` — gcc-avr/avr-libc/avrdude/simavr on `debian:trixie-slim`, **≈150–300 MB estimate** (BOARD_PROGRAMMING_PLAN §8's unverified avr-gcc estimate; the actual number is one `docker image ls` away, unmeasured here) | the EXISTING image, byte for byte | a second, slimmer image built just for export (bloat; the engines image is already the proven, measured artefact) |
| bridge export | the existing generated Maven project (small, text only) + its `.deb` wrapper (KB) | the existing generator + the isle-manager-app packaging triple | no new JDK bundling for the bridge itself (it is headless; a plain `.deb` with `openjdk-21-jre` as a Depends, same as isle-manager-app's `control`, not a jpackage app-image) |
| installer app, source-dir form | the app's own source (small) + a JDK 21 + JavaFX 21 + Maven reference (online: `apt`/sdkman pointers; offline: vendored, **JDK ≈ 180–220 MB + JavaFX SDK ≈ 50–80 MB, unverified, measure before committing to an offline form**) | isle-manager-app's existing `javafx.version` pin (21.0.2) | no second JavaFX version pin |
| installer app, jpackage bundle | a bundled JRE app-image, **typically 150–250 MB for a small JavaFX app, unverified** | `jpackage` (ships with the JDK; no new tool) | no Electron-style alternative, no second packaging tool evaluated |
| licences | avr-gcc/binutils-avr GPL-3.0+(runtime exception)/GPL-3.0+, avr-libc modified BSD, avrdude GPL-2.0, simavr GPL-3.0, OpenJFX GPL-2.0 with the Classpath Exception — all already cleared in BOARD_PROGRAMMING_PLAN §8 and compatible with `project-license-gplv3`; nothing NC anywhere in this arc | — | — |

**Bloat budget, stated plainly:** this arc should add **one shell script per export kind** (`polari-firmware-build.sh`,
`polari-bridge-install.sh`), **one new row** (`Export`), **one new small JavaFX codebase** (the installer app, exp-2),
and **zero new images, zero new toolchains, zero new packaging formats, zero new pkexec patterns**. Any slice that
starts duplicating an §1 row instead of extending it is out of scope until re-justified.

## §6. Decisions (recommendation first; his to rule — D-exp-1..5)

- **D-exp-1 where exports are stored** → **recommend: `module_home('exp')` (today `/app/data/exp` in a container,
  `~/.cache/polari-exp` on a bare host), generated on request and deleted on a TTL — the EXACT dl-4/bridge-tarball
  discipline, not SeaweedFS.** An export is a transient rendering of rows that already exist elsewhere (the CGraph,
  the FirmwareBuild, the Maven project); occupying the file store permanently would duplicate data that is already
  durable as rows. SeaweedFS stays available as the env-override path (`module_home`'s existing ladder) for a
  deployment that wants exports to persist (e.g. a public download mirror) without any code change.
- **D-exp-2 online toolchain source** → **recommend: distro packages (apt) for online, the EXISTING `prf-board-engines`
  image (`docker save`) for offline** — not a third option (pinned tarballs of the compiler itself), because the
  engines image is already built, measured, and versioned; a tarball-of-binaries path would be a second toolchain
  packaging effort with no proven consumer.
- **D-exp-3 installer app: new app or an extension of app-shell/Isle Manager?** → **recommend: a NEW app, built the
  same way as `isle-manager-app`** (own small Maven project, own `.deb`, same packaging triple), reusing
  `polari-app-shell`'s `HostInstall`/`HostProcess` fixed-argv pattern for its pkexec calls. Not an app-shell mode
  (app-shell is a browser chrome around the Angular UI — the wrong shape for native USB-scan screens); not a feature
  added to `isle-manager-app` (wrong audience/scope — isle networking vs. board flashing; keeping them separate keeps
  each app's `.deb` small and its polkit action narrowly scoped).
- **D-exp-4 is a flash EVER allowed without a prior export?** → **recommend: no.** `pol board install --yes` (and the
  Installer App's flash button) routes through the SAME export-and-gate path exp-0 builds — generate the export (even
  if to a throwaway temp dir in the same process), rebuild, compare sha, THEN flash. This is the direct reading of his
  "not just some nonsense we are spitting out and potentially destroying hardware" — the gate must sit between EVERY
  compute-then-flash path and the device, not just the one a person explicitly exported.
- **D-exp-5 ISO scope** → **recommend: reference only, this arc.** `POLARI_ISO_PLAN.md` already owns offline-first
  image-building; an export's `.deb` forms become ordinary platform-deb entries in that pool once they exist (exp-1
  onward). No ISO work starts until the deb forms (exp-1, exp-2) are proven, per the bloat budget.

---

**Status: PLANNING ONLY.** No code, row, module, or branch for this arc exists yet. The next step is his ruling on
D-exp-1..5 and an explicit go before exp-0 starts.
