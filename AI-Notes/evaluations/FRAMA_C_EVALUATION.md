# Frama-C (+ Mthread, EVA, WP) as a second formal engine for the firmware-fault arc — a real trial

**Date:** 2026-10-02. Scope: `AI-Notes/plans/FIRMWARE_SCENARIO_PLAN.md` §5 (evidence tiers) and §7 D-sc-6, which
marked Frama-C "LGPL (exact version unverified)" and Mthread "included in main Frama-C distribution (ISR modelling
as threads is unverified)" — evaluate sc-2 left this undone when sc-2b adopted CBMC instead. This is a candidate
evaluation only: nothing here changes `prf-formal-engines` or any module; it answers whether Frama-C should be
D-sc-6's **second** engine, alongside CBMC, not instead of it.

**Method, per his instruction:** no host install. Everything below ran inside `docker run`/`docker exec` containers
from a bare `debian:trixie` image, kept alive only for the length of this trial (`docker run -d --name frama-trial
debian:trixie sleep infinity`, `docker exec` repeatedly, `docker rm -f` + `docker rmi` at the end — see §5). The sc-2b
CBMC model files were copied in unmodified from `polari-rf-node/polari-framework` at `dev-sc-2`
(`modules/firmwarefaults/custom/cbmc_model/{hal_millis_isr.c,g_ms_avr_model.c,rx_ring_bound.c,stubs/}`) and the real
UNO firmware (`modules/board/custom/firmware/uno/hal.c`, `hal.h`), read via `git show dev-sc-2:<path>` / `git
ls-tree`. A minimal `board_config.h` was written for the trial (RX_RING=64, FEATURE_COMMANDS=1, USART_U2X=0,
TELEMETRY_HZ=10) matching the real `pol board gen` knobs sc-2b's harnesses already assume.

## 1. Licence + packaging — verified primary sources, 2026-10-02

| Component | Licence (primary source) | In Debian trixie? |
|---|---|---|
| **Frama-C** (kernel + Eva + WP + Mthread + Volatile, all in one opam package) | **LGPL-2.1-only** — `opam show frama-c` → `license "LGPL-2.1-only"` ([opam.ocaml.org/p/frama-c](https://ocaml.org/p/frama-c/latest)); corroborated by [Wikipedia's Frama-C infobox](https://en.wikipedia.org/wiki/Frama-C) | **No.** `apt-cache policy frama-c` on a fresh `debian:trixie` returns nothing; `apt-get install frama-c` → `E: Unable to locate package frama-c` (verified live in the trial container). The [Debian package tracker](https://tracker.debian.org/pkg/frama-c) confirms: frama-c is stuck in **unstable** at **25.0-manganese-5** (an old release — see below), "not currently in testing," removed from testing three times (2020, 2021, and again 2025-02-02), currently blocked from migrating by an **unsatisfiable `frama-c-base` dependency on seven architectures** plus a known regression bug (#1093102). So the plan's "unverified" packaging question resolves to: **there is no `frama-c` Debian package to point at for trixie, period** — not "unverified," just absent. |
| **Mthread** (the plugin this ask is about) | **LGPL-2.1** — the installed plugin's own stub headers carry `SPDX-License-Identifier LGPL-2.1` / `Copyright (C) CEA` (`share/frama-c/share/mt/mthread_interrupts.h`, read verbatim in the trial container — same licence as the kernel, one package) | N/A (ships inside the frama-c opam package above, which trixie doesn't have). Per [Frama-C's own release notes](https://git.frama-c.com/pub/frama-c/-/wikis/Frama-C-31.0-Gallium) (via search, corroborated by the installed `mthread.html` plugin description), Mthread "is now embedded within Eva and available in the open-source release" **as of Frama-C 31.0 (Gallium, released 2025-06-24)**. Debian's stuck 25.0 (Manganese, released 2022-06-21 per [the 25.0 release notes](https://git.frama-c.com/pub/frama-c/-/releases/25.0)) **predates that by three years and six version numbers** — even if Debian's unstable package were usable, its Mthread would not be the open-distribution one the plan was asking about. This fully resolves the plan's "unverified": **Mthread IS in the open distribution, but only from 31.0 onward; the only Debian frama-c package that exists anywhere is older than that boundary.** |
| **Eva, WP, Volatile** (the plugins actually used below) | Same LGPL-2.1 package as the kernel | Same absence as above |
| **Why3** (WP's backend prover orchestrator) | **LGPL-2.1-only** — `opam show why3` → `license "LGPL-2.1-only"` ([why3.org/doc/foreword.html](https://why3.org/doc/foreword.html)) | **Yes** — `why3 1.8.0-2+b1` is a real trixie package (`apt-cache policy why3`, verified live). Installed via opam instead here only because opam's `frama-c` pulls its OWN pinned Why3 1.8.2 as a dependency; a Debian-package route would need to bridge versions. |
| **Alt-Ergo** (WP's default/native prover) | **NOT fully open.** `opam show alt-ergo` → `license "LicenseRef-OCamlpro-Non-Commercial" "Apache-2.0"` (verified live, installed version 2.6.4). [OCamlPro's own licence page](https://ocamlpro.github.io/alt-ergo/latest/About/license.html) and [alt-ergo.ocamlpro.com](https://alt-ergo.ocamlpro.com/): **every opam release from `alt-ergo` is OCamlPro-Non-Commercial** (commercial use requires a paid "Club" membership); the **only open build is `alt-ergo-free`, Apache-2.0, frozen at 2.3.3 (2022-05-20) — roughly four years and seventeen minor releases stale** against the mainline 2.6.4 installed here. **This is the same NC pattern the plan already excludes Tracealyzer/SystemView for** (project rule: NC = hard blocker). **Not packaged for trixie at all** (`apt-cache policy alt-ergo` → `Candidate: (none)`, verified live). |
| **CVC5** (an open WP backend) | **BSD-3-Clause** (+ a couple of vendored Expat/GPL-3+ files per `/usr/share/doc/cvc5/copyright`, verified live) | **Yes** — `cvc5 1.1.2-2+b3` (verified live apt install) |
| **Z3** (an open WP backend) | **MIT/Expat** (`/usr/share/doc/z3/copyright`: `License: Expat`, verified live) | **Yes** — `z3 4.13.3-1` (verified live) |
| **CBMC** (sc-2b's adopted engine, for reference) | **BSD-4-Clause** (advertising clause) — `/usr/share/doc/cbmc/copyright`, verified live; matches the plan | **Yes** — `cbmc 6.6.0-4`, the exact build `prf-formal-engines:trixie` already pins |
| **cppcheck** (sc-1's static engine, for reference) | Mixed per-file (BSD-2/GPL-2+/ZLIB), project overall GPL-3.0 | **Yes** — `cppcheck 2.17.1-2`, matches the plan |

**GPLv3-compatibility read:** Frama-C/Why3/Mthread are LGPL-2.1, which is directly compatible with linking into or
alongside a GPLv3 project (more permissive here than CBMC's BSD-4-Clause advertising clause, which the plan already
treats as fine only because CBMC runs as a separate process). Running Frama-C as a separate-process engine (the
existing `prf-formal-engines` pattern) is still right architecturally, just not licence-forced. **Alt-Ergo's default
build is the one piece that fails the project's NC rule outright** — the fix is trivial: WP does not need Alt-Ergo
specifically, and **CVC5 and Z3 are both fully open** and were both used successfully below.

## 2. The trial

### 2a. Install, verified live

```
$ apt-get install frama-c          # debian:trixie
E: Unable to locate package frama-c
```
Route used instead (same as Frama-C's own documented opam install path, nothing host-side): `apt-get install -y
opam ocaml-nox cbmc cppcheck z3 cvc5 graphviz zlib1g-dev <build deps>`, then `opam switch create fc ocaml-system`,
`opam install -y --confirm-level=unsafe-yes frama-c alt-ergo`. Result: **Frama-C 33.0 (Arsenic)** (opam's current
default — newer than the Mthread-manual's 32.0 Germanium cited in the plan's survey), with every open plugin in one
binary:
```
$ frama-c -plugins
...
Eva    automatically computes variation domains ...
Mthread  Experimental tools for multi-threaded programs (-mt-h)
Volatile  support for volatile accesses and calls through function pointers (-volatile-h)
WP     Proof by Weakest Precondition Calculus (-wp-h)
```
`why3 config detect` found all three provers (Alt-Ergo 2.6.4, CVC5 1.1.2, Z3 4.13.3). **Build cost: ~15–20 minutes
of OCaml compilation** (dune, zarith, ocamlgraph, menhir, ppxlib, why3, alt-ergo, then the Frama-C kernel itself —
the single longest step), **2.0 GB** opam switch on disk, **2.48 GB** container size. For comparison, Frama-C's own
official Docker Hub images (`framac/frama-c-gui:28.1`) run **1.2–1.4 GB compressed**, and a `framac/frama-c:dev-stripped`
variant is advertised as smaller still ([frama-c.com/2020/11/04/docker-images.html](https://frama-c.com/2020/11/04/docker-images.html))
— a real `prf-formal-engines`-style image should start from one of those or a multi-stage build copying only
`/root/.opam/fc`'s runtime output, not repeat this from-source build.

### 2b. EVA on the torn `hal_millis` — does it flag anything?

**First, unmodified: `hal_millis()` exactly as hal.c ships it**, no instrumentation at all, both variants
(`-DHAL_MILLIS_ATOMIC=1` / `=0`), `-machdep x86_32 -eva`:
```
[eva:show] eva_plain.c:19: Frama_C_show_each_result: [0..4294967295]     # ATOMIC build
[eva:show] eva_plain.c:19: Frama_C_show_each_result: [0..4294967295]     # TORN build — IDENTICAL
```
**Both variants give the full `uint32_t` range. EVA does not flag the torn read specifically — it is maximally
unprecise about *every* access to `g_ms`, atomic or not, and cannot distinguish the safe build from the unsafe one.**
Why: EVA's built-in semantics for `volatile`-qualified objects treats every READ as returning an unconstrained value
of the declared type (representing "a memory-mapped register might change under you"), **and every WRITE as not
depositing the written value either** (a write to a volatile register might trigger a side effect instead of storing
a byte) — a blanket, software-ATOMIC_BLOCK-unaware over-approximation. `ATOMIC_BLOCK`'s masking is just our own
`polari_sreg_i` integer flag; EVA has no concept of it, so it treats the shipped (safe) and bare (unsafe) builds
identically.

**Second, the explicit byte-read model** (sc-2b's own `g_ms_avr_model.c`, copied in verbatim, called directly
instead of through `hal_millis()` — Frama-C has no equivalent of `goto-instrument`'s `--nondet-volatile-model`/`--isr`
GOTO-level splice to wire it in transparently, so the harness calls `polari_avr_read_g_ms()` itself). Tried casting
away `volatile` on the byte pointer (`(const uint8_t *)&g_ms`) to see if EVA would then track it precisely:
```
[eva:volatile] model/g_ms_avr_model.c:38: Warning:
  Lvalue *(p + 0) with non-volatile-qualified type may refer to an object defined with a volatile-qualified type.
... (same for p+1, p+2, p+3)
[eva:show] eva_model.c:31: Frama_C_show_each_pre: [0..4294967295]
[eva:show] eva_model.c:32: Frama_C_show_each_result: [0..4294967295]
[eva:show] eva_model.c:33: Frama_C_show_each_post: [0..4294967295]
```
**Same result, in both the masked (`POLARI_SREG_INIT=0`) and interruptible (`=1`) cases.** EVA tracks volatility by
the object's *base allocation*, not the access expression's static type, specifically so a pointer cast cannot evade
it. There is no `-eva` flag to turn this off (`frama-c -eva-h | grep -i volatile` → nothing); the only documented
escape hatch is the separate **Volatile** plugin, which rewrites volatile accesses into ordinary function calls per
an ACSL-specified model (`-volatile -volatile-binding VAR:FN`) — the real Frama-C analogue of CBMC's
`--nondet-volatile-model`. **Not attempted within this trial's time budget**; flagged under "could not run" (§4).

**Ring index bound — the task predicted this would be "a natural fit for EVA's interval domain." It is not, for the
same reason:**
```
[eva:alarm] hal.c:67: Warning: accessing out of bounds index. assert rx_head < 64u;
[eva:alarm] hal.c:76: Warning: accessing out of bounds index. assert rx_tail < 64u;
```
`rx_head`/`rx_tail` are `volatile uint8_t`; the ISR's `rx_head = next;` is a write to a volatile object, so EVA
immediately forgets the value is `next` (∈[0,63]) and falls back to the full `uint8_t` range [0,255] — which then
trips a **spurious** out-of-bounds alarm on the very next `rx_ring[rx_head]` access. CBMC's bounded check (below)
proved the real property holds; EVA's default volatile handling turns the identical property into **false-positive
noise on exactly the variables an ISR-shared ring needs tracked.**

**Verdict for 2b: out of the box, EVA is *useless* for this firmware's properties.** Not wrong — sound, even — but
uniformly unprecise on anything touching a volatile, which is every byte of shared state an AVR ISR interface has.

### 2c. Mthread — the two-"thread" race, both unprotected and protected

Frama-C's own test suite ships a working, licensed (LGPL-2.1, same SPDX header) example at
`src/plugins/eva/tests/mthread/mutex.c` (found in the opam source cache, `~/.opam/fc/.opam-switch/sources/frama-c.33.0/`)
showing the real convention: `Frama_C_thread_create` + `Frama_C_mutex_lock/unlock` (there is also a CLI-only
`-mt-interrupt-handlers <fn>` flag, demonstrated in `.../tests/mthread/interrupt.c`, for a handler that fires with
**no** synchronization modelled at all — tried first and also found the race, but gives no way to test protection,
so the thread+mutex convention below is the one reported). The tick is modelled as a genuine Mthread thread running
`polari_isr_timer2_compa()` (the real `TIMER2_COMPA_vect`, unedited) in a loop; main calls the real `hal_millis()`.

**Unprotected (no lock anywhere — this IS the race):**
```
$ frama-c -eva -mthread -mt-threads-lib builtins-only -main main mt_thread_torn.c
[mt] Possible read/write data races:
  g_ms:
    read by <main> at hal.c:132, unprotected
    read by tick at hal.c:110, unprotected
    write by <main> at mt_thread_torn.c:29, unprotected
    write by tick at hal.c:110, unprotected
[mt] Mutexes for concurrent accesses:
  g_ms  unprotected
```
**Yes — Mthread reports the race, by name, at the exact source lines**, on both sides of the interaction
(`hal.c:132` is literally `v = g_ms;` inside `hal_millis`; `hal.c:110` is `g_ms++;` inside the real ISR). This took
0.35 s wall, 113 MB peak RSS.

**Protected** (main and the tick thread both wrapped in `Frama_C_mutex_lock(g_ms_lock)` / `_unlock`, mirroring
`mutex.c`'s own `f1()`/`f2()` pattern exactly — the Mthread-native equivalent of what `ATOMIC_BLOCK` does on real
hardware):
```
[mt] Possible read/write data races:
  g_ms:
    read by <main> at hal.c:132, protected by g_ms_lock
    read by tick at hal.c:110, protected by g_ms_lock
    write by <main> at mt_thread_atomic.c:33, unprotected   <- an intentionally-UNguarded setup write in MY harness,
    write by tick at hal.c:110, protected by g_ms_lock          before the lock is taken — correctly still flagged
[mt] Mutexes for concurrent accesses:
  g_ms  write protected by (?)g_ms_lock, read protected by g_ms_lock
```
**Mthread correctly distinguishes protected from unprotected accesses to the same global, down to the individual
statement** — the one access it still calls out (`mt_thread_atomic.c:33`) is a deliberately-unguarded setup write in
the harness itself, not a false positive. This is the single cleanest, most decisive result in the whole trial:
**unbounded** (a fixed-point interference computation over the whole program, no `--unwind`/`k` anywhere) and
precise, at essentially the same cost as plain EVA (0.35 s, 113 MB).

### 2d. WP with a minimal ACSL contract

Per the ask, scoped to the ATOMIC variant's actual guarantee (masked throughout ⇒ no tick can land): a minimal
contract on the explicit byte-read model (`wp_model.c`, built for this trial — WP needs ACSL, which the CBMC harness
has none of):
```c
/*@ requires polari_sreg_i == 0;
    assigns \nothing;
    ensures \result == g_ms;
*/
uint32_t polari_avr_read_g_ms(void) { /* same four-byte read as g_ms_avr_model.c */ }
```
with `polari_tick()` given a `behavior masked: assumes polari_sreg_i==0; assigns \nothing;` / `behavior enabled: ...`
split so WP knows masked ticks truly do nothing. Default memory model (`Typed`):
```
[  Valid  ] Pre-condition ("wp_model.c", line 35)          by Call Preconditions.
[    -    ] Post-condition ("wp_model.c", line 37)         tried with Wp.typed.        <- NOT proved
[ Partial ] Exit-condition  ... pending: Assertion 'rte,mem_access' (x3)               <- pointer-cast validity unresolved
```
12.1 s wall. **Unknown** — WP's default `Typed` memory model cannot even discharge the *pointer-validity* side
obligations for `(const uint8_t*)&g_ms; p[0..3]` (byte-wise access to a 4-byte object through a reinterpreted
pointer — a classic memory-model mismatch, not a bug in the property). Escalating to the byte-addressable model and
all three open provers:
```
$ frama-c -wp -wp-rte -wp-model 'Typed,Bytes' -wp-prover alt-ergo,cvc5,z3 -wp-timeout 20 ...
[  Valid  ] Assertion 'rte,mem_access' (x4)      by Wp.bytes (v1).      <- NOW proved
[    -    ] Post-condition ("wp_model.c", line 37)  tried with Wp.bytes (v1).   <- STILL not proved
    25 Completely validated / 4 To be validated / 29 Total
```
25.8–72.4 s wall across runs (shared Why3 session cache made the second run faster), **877 MB peak RSS** (three
solvers loaded). **Unknown, not Proved, not Timeout as such** — the `Bytes` model closes the pointer-validity
obligations but none of Alt-Ergo 2.6.4, CVC5 1.1.2, or Z3 4.13.3 (20 s each, 60 s of solver time total on that one
goal) can automatically discharge "`b0 | (b1<<8) | (b2<<16) | (b3<<24) == g_ms`" — a byte-decomposition identity that
needs either a bit-vector-native prover configuration or a manual ACSL lemma bridging the byte array view to the
integer value, neither of which is "minimal" by the plan's own standard. **This is itself the honest finding**: WP
proves exactly what you give it an exploitable VC for; byte-level AVR reasoning is not that, out of the box.

### 2e. CBMC, re-run on the SAME container for a true apples-to-apples host comparison

sc-2b's own argv sequence (`goto-cc --16 → goto-instrument --nondet-volatile-model/--isr → cbmc --unwind`), replayed
verbatim from `polari-rf-node/prf-formal-engines/polari_cbmc_check.py`, on the identical `cbmc 6.6.0-4` Debian
package, sharing this CPU with the concurrent Frama-C build (so wall times here run high — noted per-row):

| Property | Verdict | This container (contended) | sc-2b recorded (`COST.md`, pol-core, idle) |
|---|---|---|---|
| `hal_millis` atomic, k=2 | **decided** (0 failures / 25 properties) | 0.43 s, 13.1 MB | 0.097 s, 13.8 MB |
| `hal_millis` bare, k=2 | **refuted** (1/25 FAILURE: "hal_millis returns g_ms before or after a tick, never a torn mix of both") | 0.19 s, 14.2 MB | 0.109 s, 14.9 MB |
| RX ring, RX_RING=64, k=4, unwind 6 | **decided** (0 failures / 22 properties) | 156.5 s, 82.0 MB | 107.7 s, 81.5 MB |

Verdicts match exactly; the wall-time gap is CPU contention from the simultaneous `dune build -j3` of Frama-C, not a
different result — peak RSS (the more host-independent number) matches to within 1 MB on every row.

## 3. Comparison table

| | CBMC (sc-2b, adopted) | Frama-C/EVA (default) | Frama-C/EVA (explicit model) | Frama-C/Mthread | Frama-C/WP |
|---|---|---|---|---|---|
| Torn `hal_millis`: distinguishes atomic vs bare? | **Yes** — decided vs refuted, with a trace | **No** — identical TOP both builds | **No** — identical TOP both builds (volatile tracked through the base, casts don't help) | **Yes** — unprotected vs protected, by source line | Attempted atomic-only: pointer-validity proved, core identity **Unknown** |
| Race/interleaving honesty | Explicit, hand-built (`--isr`/`--nondet-volatile-model`); models the AVR's 4-byte load sequence precisely, by construction | Does not model it — blanket conservatism substitutes for a real interleaving model | Same | **Models it for real** — a genuine two-"thread" interference fixed point, not hand-unrolled | N/A (sequential VCGen, no concurrency model at all) |
| Bounded or unbounded? | **Bounded** (`k=2`/`k=4`, `--unwind`); a longer run is outside what was checked | N/A (unprecise either way) | N/A | **Unbounded** — no `k`/unwind anywhere; this is the one place in the whole trial where an UNBOUNDED answer came back | N/A (would be unbounded if it could close the goal) |
| Ring index bound | **Decided**, precise, bounded k=4 | **False-positive alarms** (volatile-write loses precision) | not tried (would hit the same issue) | not applicable (not a race property) | not tried |
| Wall time (this host) | 0.2–157 s depending on property | 0.3 s | 0.3 s | 0.35 s | 12–72 s |
| Peak RSS | 13–82 MB | 110 MB | 110 MB | 113 MB | 878 MB (3 provers) |
| Engine image | 408.8 MB (`prf-formal-engines:trixie`, measured) | same binary, ~2.0–2.5 GB as built here (official images 1.2–1.4 GB) | same | same | same |

**Which gives an unbounded answer where CBMC is bounded:** **Mthread**, decisively — the interference/race computation
has no unwind depth. EVA and WP, the two engines that in principle also compute unbounded (fixed-point /
VC-discharge) answers, simply could not produce a USEFUL one here — EVA because of blanket volatile conservatism,
WP because the byte-decomposition VC defeated every available prover.

**Which models the ISR interleaving honestly:** Mthread, by construction (a real second control flow, not an
instrumentation trick). CBMC's `--isr`/`--nondet-volatile-model` is an honest MODEL of the AVR's instruction sequence
(acknowledged "ours" in sc-2b's own commentary), built by hand per property; Mthread needs no such per-property
hand-built model — you give it the real ISR function and a real (or stand-in) mutex and it works out the
interference itself.

## 4. What could not be run / was not attempted

- **The Volatile plugin's precise binding model** (`-volatile -volatile-binding g_ms:polari_avr_read_g_ms`), which is
  the real Frama-C analogue of CBMC's `--nondet-volatile-model` and might let EVA compute the torn-value range
  precisely instead of blanket TOP. Not attempted — out of this trial's time budget once the default-EVA and
  explicit-model routes both confirmed the same conservatism; flagged as the one unresolved "maybe EVA still has a
  path to a useful answer" question.
- **WP's byte-decomposition identity**, left at Unknown rather than chased further with manual ACSL lemmas or a
  different prover configuration (e.g., CVC5 in a pure bit-vector mode) — the plan asked for a *minimal* contract,
  and reporting Unknown honestly is more useful than hand-holding one goal past what "minimal" would ever reach in
  production use.
- **A from-Debian-unstable install** (the 25.0-manganese-5 package) was not attempted — it predates the open
  Mthread by three years regardless, so it would not answer the question this evaluation was for; opam's current
  33.0 is the right comparison point.
- **Why3/Alt-Ergo-free route**: did not try substituting `alt-ergo-free` 2.3.3 for the NC mainline build to see if
  WP's goals change provability — moot, since CVC5 and Z3 (both fully open, both already tried) are the
  recommended backends regardless (§1).
- Real silicon / Renode cross-check of any Frama-C finding: out of scope for this evaluation (that is sc-3/D-sc-5
  territory, not this arc).

## 5. Cleanup

```
docker rm -f frama-trial
docker rmi debian:trixie
```
run at the end of this session — no image, container, or volume from this trial persists; nothing was installed on
the host; this file is the only change made.

## 6. Recommendation for D-sc-6

**Adopt Frama-C as a second engine in `prf-formal-engines` — but only the Mthread plugin, for ONE kind of property
CBMC cannot state as naturally: "does this interrupt/main interaction need a lock, and is the lock actually taken on
every shared access."** Concretely:

- **Which plugins:** Mthread only, for now. EVA (bare) is not worth wiring in — it answers nothing about this
  firmware's properties that CBMC doesn't answer better (§2b, §3). WP is not worth wiring in until a real Polari
  property needs a sequential, non-concurrent functional proof (its strength — it has nothing to do with the
  interrupt properties this arc cares about, and §2d shows even a minimal interrupt-adjacent VC defeats it).
- **Which solver, if WP is ever added later:** **CVC5 or Z3**, never Alt-Ergo's default opam build (§1 — NC,
  excluded by the project's own rule; `alt-ergo-free` is a legal fallback but four years stale).
- **Claim statuses Mthread can produce**, in his vocabulary: a race found ⇒ **refuted** (the exact source-line pair
  is the counterexample, no trace/cycle needed the way CBMC's is — it's a static pair of accesses, not a scenario
  run); no race found over every declared interrupt handler ⇒ **decided**, and *unbounded* unlike CBMC's `decided
  (bounded, k=…)` — this is a strictly stronger claim status than anything CBMC can currently produce for this
  firmware, worth its own footnote in `FormalCheck.claim_status` (e.g. `decided (unbounded)`) rather than reusing
  CBMC's `decided (bounded, k=N)` wording; `inapplicable` for a build with no declared interrupt handlers (a
  `FEATURE_COMMANDS 0` build, same pattern CBMC already uses for the ring's `_Static_assert` refusal);
  `undetermined` never really arises for Mthread (no timeout/unwind-budget concept the way CBMC has one) — if the
  analysis doesn't converge treat it as an engine error, not a claim status. Never `proved` — same discipline as
  CBMC, for the same reason (the AVR byte/interleaving model is still ours, not Mthread's; Mthread proves the
  *source-level* interference property, same caveat CBMC's `LIMITS` text already states for itself).
- **The first Polari property for it:** **exactly scenario 1's `hal-millis-not-torn` pair, restated as a race
  query instead of a bounded trace** — `hal-millis-race@uno-sim-rig-torn` (no `ATOMIC_BLOCK`, expect **refuted**:
  `g_ms` read in `hal_millis` unprotected vs written in `TIMER2_COMPA_vect` unprotected, §2c) and
  `hal-millis-race@uno-sim-rig` (shipped, `ATOMIC_BLOCK` present — **this needs real work**: `ATOMIC_BLOCK`'s
  `cli()/sei()` masking has no Mthread-native meaning, so a `prf-formal-engines`-side source rewrite or macro shim
  mapping `cli()`→`Frama_C_mutex_lock` / `sei()`→`Frama_C_mutex_unlock` would be needed before Mthread can see the
  shipped build as protected — §2c's "protected" harness used Mthread's own mutex calls directly, not the firmware's
  real `ATOMIC_BLOCK`, and that bridge is NOT built yet). Second candidate once that bridge exists: the RX ring's
  ISR-vs-main-loop interaction (`hal_rx_pop` vs `USART_RX_vect`) as a second, independent race query — CBMC already
  decided it bounded (k=4, §2e); Mthread would decide it **unbounded**, which is the more useful claim to carry
  forward.
- **Image cost, honestly:** budget roughly **3–6x** `prf-formal-engines`'s current 408.8 MB if Frama-C is added
  (§2a) — use an official `framac/frama-c` base or a stripped multi-stage build, never repeat this trial's
  from-source opam build in a production Dockerfile. Per-run cost is cheap once built: Mthread ran in 0.35 s at
  113 MB peak RSS on both properties tried here, cheaper than CBMC's ring check (156 s / 82 MB) and close to CBMC's
  millis checks (0.2–0.4 s / 13–14 MB).

## 7. Outcome (2026-10-02): ruled and built as sc-2c

His ruling: "Mthread can join the formal engines." Built on `dev-sc-2c` (plan §9 sc-2c row; module `COST.md` sc-2c section):
Mthread only, opam-built from a pinned opam-repository commit into the SAME `prf-formal-engines` image — the pruned runtime
closure is **+185 MB**, not the 3–6x this evaluation budgeted from its unpruned from-source container. The `ATOMIC_BLOCK` bridge §6
said was not built now exists (`modules/firmwarefaults/custom/mthread_model/`: cli/sei/ATOMIC_BLOCK → one global interrupt lock,
the ISR a started thread holding it), and the shipped build is recognised as protected through the firmware's REAL macro.
Two corrections to §1 / §2c found while building: (1) opam-repository carries **`alt-ergo-free` 2.4.3 under CeCILL-C** (not only
2.3.3 Apache-2.0) and frama-c 33.0's opam REQUIRES `("alt-ergo-free" | "alt-ergo")` — the free one is pinned and the build fails
on any OCamlPro-NC `alt-ergo*`; (2) a thread from `Frama_C_thread_create` starts suspended until `Frama_C_thread_start`, and
`ATOMIC_BLOCK`'s for-loop needs `-eva-slevel` ≥ 2 or the protected read reads back as `protected by (?)…`. Frama-C also has an
`avr_16` machdep (int 16, long 32, pointers 16), used instead of `x86_32`.
