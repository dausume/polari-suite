# tpl-2: Polari backends see each other without an isle (design, for the user's review)

**Status:** DECIDED 2026-11-07 (the user, see Decisions); BUILT as source 2026-11-07 (framework df3077ae, selftest_peering 36/36; CLI `pol topology self | peers [pull]`). Change signal BUILT (framework 395484cb) as digest checks every POLARI_TOPOLOGY_PEER_CHECK_S (15 s) + nudges on own change, instead of a STOMP subscription per peer; /topology labels peer copies and the July rows (angular 6f124c0). /self is open per D-tpl2-a. Part of AI-Notes/plans/TOPOLOGY_LAYERS_PLAN.md (tpl-2). Builds on decisions
D-tpl-1 (no hub: every backend merges its peers) and D-tpl-3 (HTTPS pull on a timer + the STOMP topic as a change signal),
both taken 2026-11-06.

## The problem

Today a backend knows only itself (tpl-0), its engine bindings and its frontends (tpl-1). Without an isle it cannot learn
that another Polari backend exists, so the Polari topology of a two-backend compose setup shows two disconnected islands,
and on an isle it depends on the isle feed. The plan's gap 7: "No peering."

## What already exists (reused, not rebuilt)

| Piece | Where | What it gives |
|---|---|---|
| Peer registry | `polariPeers` (`PeerNode` rows; `POST /api/peers/register`) | Named peers with `base_url`, `status`, `last_seen`, gated by a per-child agreement token (`agreements_api`) |
| Identity probe | `GET /api/peers/ping` | Who a backend is (+ module count), short timeouts, a dead peer degrades to 'unreachable' |
| Outbound seam | `polariApiServer.outbound.http_request` | Verified TLS, timeouts, logged calls |
| Self rows + provenance | `topology_self` (tpl-0/1), `topology_example_retire.provenance` (tpl-6) | Which rows a backend wrote about itself (`self` / `link`) |
| Isle registry | `IsleDevice` / `IsleApp` rows via ingest (when an isle exists) | Backends the isle knows, with URLs |

## The design

1. **Publish.** `GET /api/topology/self` returns ONLY this backend's own rows (provenance `self` and `link`): its
   InstanceDefinition, its machine, its module assignments, its engine links and frontends, each with the time it was
   written, plus `describedAt`. Never another backend's rows, so pulls cannot echo or loop.
2. **Who are my peers.** In order, each marked in the result:
   - `PeerNode` rows (the existing agreement handshake): works with no isle (compose stacks, two laptops);
   - with an isle: Polari backends the isle registry lists (the ingested `IsleApp` rows that name a Polari backend and its URL), read from rows already
     ingested, never a new probe of the isle.
3. **Pull.** On a timer (knob `POLARI_TOPOLOGY_PEER_PULL_S`, default 300 s; `0` = off) and when the peer's STOMP
   `/topic/PolariModule` signal arrives, GET each peer's `/api/topology/self` through the outbound seam with the agreement
   token. A failed pull marks the peer's rows stale in words; it never deletes them on one failure.
4. **Merge.** A peer's rows land here marked `(tpl-2 peer:<name>)` with `observedAt`. Rules:
   - a peer is the authority for ITS OWN instance: its rows replace the previous copy from that peer;
   - a local row with the same name that a person wrote is KEPT, and the conflict is reported (never overwritten);
   - a row the peer stops listing is retired here at the next good pull (disabled first, as tpl-1 does);
   - rows older than `POLARI_ISLE_EVIDENCE_MAX_AGE_S` show as stale (the tpl-4 rule, same knob).
5. **Show.** `/topology` badges each instance by source (self / link / peer:<name> / example / other) with its age; the
   Isle App's Polari tab shows the same page (tpl-5). `isle-needs`' "discovery" fallback becomes "registered peers
   (tpl-2)".
6. **CLI.** `pol topology self [--api URL]` and `pol topology peers [--api URL]` (each peer, its source, its last pull,
   its words). The same doors as the page.

## Decisions (TAKEN by the user, 2026-11-07)

- **D-tpl2-a: who may read `/api/topology/self`: OPEN for now.** The user: "alternative for now, we can secure further
  later." Anyone who can reach the backend may read it; securing it (agreement token) is a later change.
- **D-tpl2-b: how peers are named: BOTH.** The user: "we need to account for the scenario of loading and rebooting from a
  pre-made configuration, which may need a list or equivalent, perhaps both?" Peers come from (1) the agreement handshake
  (`PeerNode` rows) and (2) a configured list that a pre-made configuration ships and that survives a reboot: knob
  `POLARI_TOPOLOGY_PEERS` (`name=url,...` or bare URLs) and/or a file named by `POLARI_TOPOLOGY_PEERS_FILE` (JSON list of
  `{name, url}`). Each peer is shown with where it came from (agreed / configured-env / configured-file).
- **D-tpl2-c: when a peer and a local row disagree: as recommended.** The peer wins for its own copied rows; a row a
  person (or this backend) wrote under the same name is kept and the conflict is reported.

## Tests (when built)

Two in-memory backends: A names B (agreement row, knob or file), A pulls B's self rows, both pages show both instances with the right
sources; B changes a module, the signal or the timer brings it to A; B goes down, A shows stale (not deleted); B
retires a module, A retires it at the next pull; a person's local row survives a conflicting peer row, reported; no
echo (A's copy of B never goes back to B); an unauthorized `/self` read refused per D-tpl2-a; TLS verified, never -k.

## Not in scope

Reticulum transport for off-isle peers (D-tpl-3 says later); write-through to a peer (peering is read-only: placement
changes stay the isle operation or the peer's own owner).
