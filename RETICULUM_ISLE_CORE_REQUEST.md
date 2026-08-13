# REQUEST to isle-core — router-side half of the Reticulum gateway (ret-3)

**Written 2026-08-13 by the polari-suite instance. This is a REQUEST
document, per the standing boundary (RETICULUM_TRANSPORT_PLAN.md §0):
isle networking lives on isle-core with its own Claude; nothing here
was applied from the polari side, and nothing should be — this file
states what the Polari half needs and exactly where its own surfaces
are.**

## What exists on the Polari side (built + proven 2026-08-13)

- `pol-reticulum` sidecar container, LIVE on staging-a: Reticulum
  TCP bearer on **:4242**, honest status API on **:4285**
  (`pol compose reticulum up`). ⚠ Licence note for any isle-side
  packaging: rns/lxmf are PINNED to `0.9.4`/`0.6.3` — the last MIT
  releases; NEWER VERSIONS ARE GPLv3-INCOMPATIBLE
  (`RETICULUM_LICENCE_GATE.md`). Do not "helpfully" bump them.
- **Name registry**: `GET /api/reticulum/resolve/{name}` on the
  prf backend answers what a `*.rns.isle` / `.arch` name maps to
  (destination hash, type, scope) and **refuses unmapped names by
  name** (404 + evidence/knob/action). This is the source of truth
  a resolver should consult; nothing is guessed.
- **Netledger kind for the synthetic range**:
  `islemesh_netledger.free_synthetic_pool()` suggests a /24
  (default space `10.77.x.0/24`) that overlaps no docker pool and no
  other synthetic pool on the host; `synthetic_pool_conflicts()`
  flags the dangerous case (a synthetic range docker also routes).
  The isle agent's device ingest may now carry `synthetic_pools`
  beside `pools`/`ports`.

## What is requested of isle-core (when convenient — nothing blocks on it)

1. **Reserve the synthetic pool as data**: pick (or accept) a /24
   from `free_synthetic_pool()` on each isle edge and record it in
   the isle registry so it rides the existing ingest into Polari's
   ledger (`synthetic_pools` on the device row).
2. **DNS**: answer `*.rns.isle` (and, if agreed, `*.arch`) queries
   with addresses from that pool — one stable address per name,
   only for names the Polari registry actually resolves
   (`/api/reticulum/resolve/{name}` → 200). An unmapped name should
   get NXDOMAIN, mirroring the registry's refusal-by-name.
3. **Routing/nftables**: steer the synthetic /24 to the host running
   `pol-reticulum` (the gateway host). The packet-plane mapper on
   our side is ret-3's remaining half; until it lands, steering to
   the host is sufficient and safe (unmatched packets are refused,
   not black-holed).
4. **OpenWRT packaging of rnsd is NOT requested.** Decision 15/16:
   the stack lives in the `pol-reticulum` container on the Ubuntu
   isle host; the router keeps only DNS + steering. If a deployment
   genuinely wants a router-resident stack later, that is its own
   conversation (and its own licence-pin care, see above).

## Open questions for isle-core

- Is the OpenWRT instance on staging-a itself a KVM guest on the same
  host? (Plan §5k: if so, USB radios pass through to the
  pol-reticulum container directly and the router never touches
  them — worth confirming before any radio arrives.)
- Which suffix do you want authoritative on the router: `.rns.isle`
  under the existing `.isle` zone, `.arch` as its own, or both?
