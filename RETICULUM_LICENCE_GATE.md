# Reticulum licence gate — three-source audit (2026-08-13)

**Verdict: ⚠ CONDITIONAL PASS — proceed ONLY on the pinned MIT pair
`rns==0.9.4` + `lxmf==0.6.3`. Current releases are a BLOCKER.**

Frame: whole project GPLv3 ([[project-license-gplv3]]); GPL deps fine;
blockers = unlicensed / non-commercial / GPL-incompatible /
field-of-use restrictions. Method: three sources per component
(published metadata + repo LICENSE + source headers), fetched
2026-08-12/13, sdists also inspected locally.

## The finding that changes the plan

**Plan DECIDED row 2 ("Reticulum is MIT") was TRUE ONLY of old
versions.** On **2025-04-15** Mark Qvist relicensed RNS and LXMF (same
hour, both repos) from MIT to a custom **"Reticulum License"**: MIT's
grant verbatim, plus two added conditions —

> - The Software shall not be used in any kind of system which includes
>   amongst its functions the ability to purposefully do harm to human
>   beings.
> - The Software shall not be used, directly or indirectly, in the
>   creation of an artificial intelligence, machine learning or language
>   model training dataset, including but not limited to any use that
>   contributes to the training or development of such a model or
>   algorithm.

Both are **field-of-use restrictions**: "further restrictions" under
GPLv3 §7, failing FSF freedom 0 and OSD §6 → **GPLv3-INCOMPATIBLE**.
Clause 2 is also exceptionally broad ("directly or indirectly …
contributes to") and this suite integrates AI tooling throughout, so
it is a live exposure for us even before the GPL question.

All three sources agree for the current releases (rns 1.4.2, lxmf
1.1.1): PyPI `license: 'Reticulum License'`, repo LICENSE at master
and at the release tags, and per-file headers in RNS (LXMF has no
per-file headers; repo LICENSE + setup.py govern). Local sdist
inspection confirmed the same (scratchpad `licence-evidence/`).

## Component table

| Component | Current | Licence now | GPLv3-ok | Last MIT version |
|---|---|---|---|---|
| rns | 1.4.2 (2026-07-26) | Reticulum License | **NO** | **0.9.4** (2025-04-15, tag LICENSE = MIT, published hours BEFORE the licence commit) |
| lxmf | 1.1.1 (2026-07-30) | Reticulum License | **NO** | **0.6.3** (2025-03-13; pairs with rns 0.9.3/0.9.4) |
| RNode_Firmware | 1.86 (2026-04-24) | **GPLv3-or-later** (since 2022-11-10; ignore stale MIT v1.x tags) | **YES** | n/a |
| rnodeconf | ships inside rns | follows rns | NO with current rns / **MIT inside rns 0.9.4** | (standalone rnodeconfigutil 1.3.1 is MIT but ARCHIVED 2022 — dead code, not an escape hatch) |
| cryptography | 50.0.0 | Apache-2.0 OR BSD-3-Clause | YES | n/a |
| pyserial | 3.5 | BSD-3-Clause | YES | n/a |

The relicensing is prospective only — Qvist (sole copyright holder)
cannot retroactively unlicense shipped MIT copies, so the 0.9.4/0.6.3
pair is genuinely MIT and stays MIT.

## Options weighed, and the decision taken

**(a) PIN the MIT pair `rns==0.9.4` + `lxmf==0.6.3` — CHOSEN
(overnight assumption 2026-08-13, Dustin to confirm).**
- Licence-clean with NO aggregation argument needed and NO
  use-restriction exposure at all.
- Cost: frozen at April 2025; rns 1.0.0→1.4.2 (~15 months of fixes)
  is forfeit, and there is no compatible upstream to pull from — a
  long-term commitment to this pin is effectively a solo-maintained
  MIT fork.
- Why the cost is acceptable HERE: both ends of `.arch` are OUR nodes,
  so wire-protocol drift vs. upstream 1.x does not bite; ret-0..ret-5
  need a working stack, not the newest one. Revisit at ret-6/ret-9.

**(b) Current rns as an external, unlinked service** (separate
container, GPLv3 code never importing RNS): the aggregation argument
handles the GPL side, **but the use-restrictions bind regardless of
process boundaries** — clause 2's breadth would hang over every AI
feature in the suite. Rejected as the default; available if Dustin
prefers it with eyes open.

**(c) Drop Reticulum.** Not warranted — (a) is clean.

## Consequences enforced in the code

1. **Version pins are licence pins**: every requirements/container
   reference MUST be `rns==0.9.4` and `lxmf==0.6.3` exactly (never
   `>=`), with a comment naming this gate. An unpinned bump is a
   LICENCE change, not a version change.
2. **rnodeconf** is used only as shipped inside rns 0.9.4 (MIT).
   Whether that rnodeconf can flash current RNode_Firmware 1.86 is a
   ret-6 technical question — the firmware itself is GPLv3 and fine at
   any version.
3. Plan DECIDED row 2 and §1/§5h are amended to cite this gate.
4. If upstream ever offers a dual licence or drops the clauses,
   re-run this gate before unpinning.
