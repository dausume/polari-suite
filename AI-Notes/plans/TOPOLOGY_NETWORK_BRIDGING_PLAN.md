# Topology network bridging (tnb arc): addresses, firewalls and reachability become topology ROWS — no separate `pol net doctor`

**Date:** 2026-10-04 · **Status: PLAN (tnb-0 not started). No code changed.** Drafted from the tree at suite
`origin/dev` (d879381), with polari-rf-node pin `ed5fa4c` and polari-cli pin `195f220`. Facts marked
**unverified** were not confirmed from a primary source or a measurement on 2026-10-04.
Companions: `AI-Notes/handoffs/BOARD_ARC_HANDOFF.md` (the DEBT table this plan clears, §7; "Engines on
isle-core"), `HARDWARE_NOCODE_PLAN.md` (slice/decision house style), `CICD_PIPELINE_PLAN.md`.

## 0. The ask and his rulings

His words (quoted, across the arc):

1. *"the purpose of polari is to enable the average person to use it while still being secure, so the rules
   we may need applied will need to be able to be handled dynamically by polari cli calls, that way AI like
   you can use it reliably, and I can build interfaces that wrap the shells for intuitive graphical
   manipulation for humans."*
2. *"we can fill in gaps to proof something out, but each time we do that and proof it, it means we need to
   remember to go back and ensure we have it wrapped in a way that polari can make it available to the
   average person."*
3. On a separate `pol net doctor`: *"no we already have that via topology, that would just be a firewall
   visualization piece in the topology of polari, which I think we should already have … this is something
   we likely need accounted for in topology if it is not already."*

Reading (2) + (3) together: the fixes proved by hand on 2026-10-04 (§1) are not a new diagnostic tool — they
are gaps in `topology`'s own rows and in `pol topology report/validate/apply`. This plan folds the firewall
and address plumbing built this week (`net-needs.sh`, `fw-handshake.sh`, `net.sh`, the four new `swarm.sh`
checks) INTO topology, instead of leaving it as a swarm-specific side pocket.

## 1. What happened (2026-10-04) — the evidence

The isle-core swarm worker showed `Down`; the routing mesh never carried traffic. Three wrong diagnoses
("ufw blocks the ports" — ufw on pol-core is INACTIVE) before the truth, both found and fixed by hand:

- **(a) Advertise-address drift.** The manager's ADVERTISED address (`docker info --format
  '{{.Swarm.NodeAddr}}'` = 192.168.0.210, frozen at `docker swarm init`) had drifted from its DHCP address
  (.212) → the worker's heartbeat to .210 failed with "no route to host". Fixed by `sudo ip addr add
  192.168.0.210/24 dev <iface>` (+ an NM `+ipv4.addresses` for durability). `swarm.sh`'s
  `check_manager_advertise` (`polari-cli/scripts/swarm.sh:168`) now detects this: it compares
  `docker info`'s `NodeAddr` against every address `ip -4 -o addr show` reports on the host and sets
  `ADVERTISE_DRIFTED=1` with both remedies printed (immediate `ip addr add`, durable re-`swarm init`) —
  **pol never runs either for you.**
- **(b) Route-source / VXLAN mismatch.** Control plane then up, data plane still dead: VXLAN frames left
  pol-core from .212 (the kernel's route `src` pick) while isle-core's overlay fdb pinned pol-core's VTEP at
  .210 → silent kernel drop, reason `VXLAN_ENTRY_EXISTS`, found with bpftrace on isle-core. Fixed by `route
  … src 192.168.0.210` (making .210 the route source too). `check_data_plane`
  (`polari-cli/scripts/swarm.sh:313`) now proves this class of failure instead of guessing: it curls a
  published ingress port via the node's own address AND via the manager's advertised address
  (`_curl_elapsed`, :288) and treats "fast via node, TIMEOUT via manager" as "mesh formed but VXLAN
  blocked" — never visible to the UDP port probe, see next point.
- **The `nc -zu` UDP probe cannot see a DROP** — `check_swarm_ports` (`swarm.sh:225`) labels its own UDP
  rows `(probe cannot see DROP)` for exactly this reason: the ingress `Peers` list
  (`check_mesh_formed`, `swarm.sh:271`, reading `docker network inspect ingress`'s `.Peers`) can be
  COMPLETE while the data plane is dead.
- **Also found the same day** (not yet wrapped, carried into this plan's findings, §3): the hw-engines
  stack lacked a placement constraint (the scheduler put the backend on isle-core where its bind mounts
  don't exist, fixed by six `docker service update --constraint-add`); the engine URLs
  (`BOARD_ENGINES_URL`, `ESP_ENGINES_URL`, …) reached the backend only via shell-exported knobs, never
  topology rows; `pol topology modules-env` computed the requires-closure from the OLD running image, not
  the checked-out one.

## 2. What exists (the survey)

**Rows (`polari-rf-node/polari-framework/topology/`):**

| class | file | fields (today) | gap |
|---|---|---|---|
| `PolariNodeMachine` | `topology_basis.py:26-107` | name, ssh_alias, arch/mem/cpu/disk (`res-1` observed resources), roles_json, swarm_role, tier, repo_dir, source, notes | **no LAN ip, no advertised ip, no firewall state, no ports** |
| `InstanceDefinition` | `topology_basis.py:138-224` | machine_name, orchestration_target, accessibility_scope, network_kind, network_hint_json, public/api base urls, db/cache/blob backend | network_hint_json is explicitly ADVISORY ONLY (`:193-197`, "RFC1918 subnets collide … hints can never prove right network") |
| `ModuleDependencyEdge` | rows read in `topology_analysis.py` (e.g. `:307-324`, `:521-567`) | module_name, consumer/provider instance, status (`resolved`\|`unresolved`\|`degraded`), evidence_json | **no port/proto** — a dependency is a module name, never a socket |
| `ServiceConnection` | `topology_analysis.py:326-345`, `:684-695` | interconnect_key, from/to_kind, from/to_instance_name, artifact, notes | config wiring only |
| `TopologyObservation` | `topology_state.py:62-104` | stacks_json, services_json, modules_json per node, posted by `pol topology report` | **no addresses, no ports, no firewall** |

`validate_topology` (`topology_analysis.py:140-351`) runs 18 structural checks today (`duplicate-instance`,
`unknown-machine`, `unknown-target`, `target-unavailable`, `machine-not-in-swarm`, `unknown-db-backend`,
`unknown-cache-backend`, `unknown-blob-backend`, `double-declared-cache`, `unknown-accessibility-scope`,
`scope-unavailable`, `unknown-network-kind`, `unknown-env-tier`, `unknown-service-kind`,
`assignment-unknown-instance`, `edge-without-provider`, `unknown-interconnect`,
`connection-unknown-instance`) — **none about addresses, ports or reachability.** `drift_report`
(`:736-791`) compares desired `service_kinds_json` against the latest `TopologyObservation` per machine —
service kinds only, no socket-level check. `pol topology` (`polari-cli/scripts/topology.sh`, verbs
`status|graph|validate|pull|push|diff|report|assign|modules-env|resolve|render|apply|deploy|export|
allocate`) has **no `--json`** on any verb (confirmed: no `--json` string anywhere in the script).

**The security module builds a DIFFERENT, STATIC graph.** `/display/security-network`
(`security_topology.py`) renders three views (os/network/app) from `load_scenario()` reading
`os-security/scenarios/<name>.yml` — a hand-authored file describing a MACHINE CLASS (`swarm-full`,
`swarm-lean`, `isle`, `dev`), not a live node. `SecurityTopologyNode`/`Edge` rows are seeded per scenario
(generic panels only); `FirewallRuleSet` (`modules/security/objects/security/FirewallRuleSet.py`) holds one
row per `(scenario, chain)` — `scenario, chain, rules, rule_count, applied, sources_resolved, artifact` —
populated by `firewall_rule_rows()` (`modules/security/custom/security_network_rows.py:96-110`), which reads
the RENDERED `os-security/out/<scenario>/ufw.sh` / `docker-user.sh` text and a from-hand `applied` dict
(`security_facts.APPLIED_TODAY`); it never reads an actual host's `ufw status`. The scenario's
`ufw.allow[]` rows (`os-security/scenarios/swarm-full.yml:26-35`, e.g. `{port: 4789, proto: udp, from:
swarm, why: "overlay VXLAN (peers only)"}`) name a SOURCE CLASS (`any|isle|isle-lan|admin-lan|swarm`)
resolved only at render-and-apply time by `ufw.sh.j2`'s `src_list()` (`$OS_SEC_ISLE_NET`, `$OS_SEC_LAN_NET`,
`$OS_SEC_ADMIN_NET`, `$OS_SEC_SWARM_PEERS` env vars) — an unresolved source is SKIPPED with a warning, never
widened to "any". The real interactive graph is `topology-graph-view.component.ts`
(`polari-rf-node/polari-platform-angular/.../components/topology/`): D3, a `TopologyGraph` input, machines
drawn as host boxes (`renderHosts`), modules as circles nested inside instance nodes, `ServiceConnection`
rows as thin colored lines (`renderConnections`, colored by `interconnectKey`) and `ModuleDependencyEdge`
rows as directed edges (`renderDependencyEdges`) colored by `status` (resolved/unresolved/degraded) — it
draws the module graph; it has no concept of an address, a port or a firewall today.

**CLI pieces built this week (polari-cli), to be FOLDED IN, not duplicated:**

- `scripts/lib/net-needs.sh`: `net_needs <binding> [port]` — a pure derivation table, binding kind → the
  ports/protos/purposes it needs open (`swarm-manager` → 2377/tcp, 7946/tcp+udp, 4789/udp;
  `swarm-worker` → 7946/tcp+udp, 4789/udp; `engine-worker <port>` → one tcp port, 9830\|9840\|9850\|9860
  known).
- `scripts/lib/fw-handshake.sh`: `fw_detect` (ufw-active\|ufw-inactive\|firewalld\|nftables\|none),
  `fw_can_prompt` (refuses in CI/no-TTY/`POL_ASSUME_NO=1`), `fw_handshake_apply` (turns
  `SWARM_PORTS_CLOSED` into consented, SOURCE-SCOPED `ufw allow from <peer> to any port <p> proto <x>`
  rules; firewalld/nftables get the equivalent PRINTED, never applied), `fw_journal_append` /
  `fw_handback_apply` — the hand-back journal at `~/.polari/handback/firewall.jsonl`, replayed in reverse.
- `scripts/net.sh`: `pol net needs|handback` — the data table + the undo ledger as a thin CLI face; the
  handshake itself lives in `pol swarm ports --apply` / `pol swarm join`.
- `scripts/swarm.sh`: `check_manager_advertise` (:168, advertise-drift + remedies),
  `check_swarm_ports` (:225, probes `nc -z[u]` against the ADVERTISED address, not blindly localhost;
  fills `SWARM_PORTS_CLOSED`, surfaces the Down reason via `_node_down_reason`), `check_mesh_formed`
  (:271, polls `docker network inspect ingress`'s `Peers`), `check_data_plane` (:313, the via-node-vs-
  via-manager timing test; feeds `4789/udp`+`7946/udp` into `SWARM_PORTS_CLOSED` on a VXLAN-blocked
  verdict so the SAME consent handshake can open them).
- Proven: swarm-selftest 129/129.

## 3. The design

Additive rows in the `topology` package (schema-stable: nothing above changes shape). Mirrors
`topology_basis.py`'s field-comment style.

```python
class MachineAddress(treeObject):
    """One address a machine answers to or advertises — never guessed, always observed."""
    name: str = ''              # '<machine>@<kind>', e.g. 'pol-core@advertised'
    machine_name: str = ''      # PolariNodeMachine.name
    kind: str = ''              # dhcp | static | secondary | advertised | route-source
    address: str = ''
    iface: str = ''
    observed_at: str = ''
    source: str = ''            # 'docker info' | 'ip addr show' | 'ip route get' | 'manual'
    stable: bool = False        # survives a reboot/lease renewal (static/reservation) vs not (dhcp)
    note: str = ''

class MachineFirewall(treeObject):
    """Observed host firewall state — never rendered-and-assumed."""
    name: str = ''               # '<machine>@<observed_at>'
    machine_name: str = ''
    engine: str = 'none'          # ufw | firewalld | nftables | none
    active: bool = False
    default_incoming: str = ''   # deny | allow | '' (unknown)
    observed_at: str = ''
    rules_json: str = '[]'       # [{port, proto, from, comment}], from fw_detect()'s own read

class NetworkEdge(treeObject):
    """One reachability requirement, DERIVED from instances/edges/assignments — the net-needs
    table becomes the derivation rule, not a hand-maintained row."""
    name: str = ''
    from_machine: str = ''
    to_machine: str = ''
    port: int = 0
    proto: str = 'tcp'
    purpose: str = ''
    binding: str = ''            # swarm-manager | swarm-worker | engine-worker | proxy | ...
    required_by: str = ''        # the InstanceDefinition/ModuleDependencyEdge id that implies it
    state: str = 'unknown'       # open | closed | unknown | drop-suspected
    data_plane: str = 'n/a'      # ok | timeout | n/a
    observed_at: str = ''
    evidence_json: str = '[]'

class AppliedRule(treeObject):
    """The hand-back journal AS ROWS — the jsonl stays the on-host truth; this is its mirror
    so the Topology tab shows what pol opened."""
    name: str = ''
    machine_name: str = ''
    rule: str = ''
    undo: str = ''
    binding: str = ''
    peer: str = ''
    applied_at: str = ''
    by: str = ''
    handed_back_at: str = ''     # '' = still open
```

**Derivation, not declaration (D-tnb-1).** `NetworkEdge` rows are computed the same way
`modules_env_for_instance` computes the requires-closure (`topology_analysis.py:65-132`): a swarm-worker
`InstanceDefinition` implies the four `net_needs(swarm-worker)` edges both ways; an engine
`ModuleAssignment` implies the caller→worker port from `net_needs(engine-worker, <port>)`; a proxy instance
implies 80/443 from `any`. `topology/net_needs.py` becomes the one place this table lives (today's
`net-needs.sh` stays a thin CLI mirror reading it, same shape as `modules_env` is read from the API or the
local module).

**New findings in `validate_topology`** (each evidence-bearing + naming the exact fix, the `aqp-1` idiom
already used at `topology_analysis.py:135-137`):

| finding | evidence | fix named |
|---|---|---|
| `advertise-address-drift` | `MachineAddress(kind=advertised)` ≠ the machine's current primary | `sudo ip addr add <ip>/24 dev <iface>` (immediate) or re-`swarm init` on a reserved address (durable) — `check_manager_advertise`'s own two remedies |
| `route-source-mismatch` | VXLAN/route `src` ≠ the advertised address | `ip route … src <advertised>` or make the advertised address the primary |
| `address-not-stable` | a manager/proxy machine's only address row is `kind=dhcp` | suggest a static address + router reservation |
| `edge-port-closed` | a `NetworkEdge.state == closed` | the exact `ufw allow from <peer> …` line, source-scoped |
| `edge-data-plane-dead` | mesh `Peers` complete (`check_mesh_formed`) but a published port times out via the manager (`check_data_plane`) | allow the UDP overlay ports from the peer; same handshake |
| `firewall-unobserved` | no `MachineFirewall` row for a machine in this topology | `pol topology report --node <m>` |
| `placement-unpinned` | an `InstanceDefinition` with host bind mounts and no `machine_name`/`placement_constraint` | pin it (closes the 2026-10-04 "six `docker service update --constraint-add`" gap) |
| `knob-not-from-rows` | an engine URL env var set while a `ModuleDependencyEdge`/`NetworkEdge` could resolve it | derive it from rows instead |
| `closure-from-old-image` | `pol topology modules-env` run against a running image older than the checkout | re-render from the checked-out `polari-modules.json` |

**Observation.** `pol topology report [--node]` grows addresses + firewall + edge probes: the four
`swarm.sh` checks (`check_manager_advertise`, `check_swarm_ports`, `check_mesh_formed`, `check_data_plane`)
move into `topology/net_probe.py`, run on the host directly or over ssh (same alias resolution
`net.sh:resolve_host_alias` already does from `nodes.yml`). The data-plane test stays exactly what
`check_data_plane` proved: a published port timed via the node's own address vs via the manager's
advertised address. The kernel drop-reason tracer (bpftrace) is OPTIONAL evidence attached to a finding
when bpftrace exists on the host (D-tnb-3) — never a hard requirement.

**Actions.** `pol topology apply` gains consented host actions driven by findings, never free-standing:
`address add-secondary`, `address route-source`, `address make-static` (prints the NetworkManager
commands; applies only with `--yes` + sudo — same `fw_can_prompt`/no-CI/no-pipe rule as
`fw_handshake_apply`), `firewall allow` (source-scoped, built from the derived `NetworkEdge` rows; ufw
applies today, firewalld/nftables print the equivalent — exactly `fw_handshake_apply`'s existing behavior),
`swarm rejoin`. Every action journals an `AppliedRule` with its undo, mirroring
`fw_journal_append`/`~/.polari/handback/firewall.jsonl`. `pol topology handback [--node]` replays it —
`net.sh`'s `handback` verb becomes an alias (§3 fold-in). `--json` lands on every topology verb (and on
`pol swarm ports`/`pol swarm join`) so the text view is a renderer over the same JSON a GUI consumes — his
ruling (1): AI and CLI get the same reliable surface a graphical wrapper calls. Never offered in CI/no-TTY,
same as the firewall handshake.

**Visualization — no new chart engine (per `frontend-graphing-capability`/`no-raw-json-on-screens`).**
`topology-graph-view.component.ts` already draws host boxes, module circles, `ServiceConnection` lines and
`ModuleDependencyEdge` edges colored by status (`:23-128` category/status palettes). It gains: `NetworkEdge`
rows as edges BETWEEN MACHINES, colored by `state` (open=green, closed=red, drop-suspected=amber,
unknown=grey — the same palette idiom as `RESOLUTION_COLORS`/`CLASSIFICATION_COLORS` already in the file);
the firewall `engine`+`active` as a small badge on the host box (`renderHosts`); `AppliedRule` rows listed
in the machine's detail/drawer tab. All of it is the existing per-object display pattern
(`per-object-display-config`) — configured tables, no new component. `/display/security-network` keeps its
scenario SIMULATION (what WOULD be blocked under a posture) and gains one more panel: a "live machines"
table sourced from `MachineFirewall`/`NetworkEdge` rows, so the simulated view and the observed view sit
side by side without merging (the scenario view answers "what would enforce do"; the new rows answer "what
is true right now").

**Fold-in (delete duplicates, never maintain two copies of one fact):** `pol net` → `pol topology net …`
aliases kept for one release (D-tnb-4); `pol swarm join`/`pol swarm ports` call the topology probes and
findings instead of their own copies — `check_manager_advertise`/`check_swarm_ports`/`check_mesh_formed`/
`check_data_plane` keep their names as thin wrappers over `topology/net_probe.py` so `swarm-selftest`
doesn't need a rewrite, only a redirect; `net-needs.sh`'s table becomes `topology/net_needs.py`, read by the
CLI from the API when reachable, from the local module file otherwise (same fallback shape
`modules_env_for_instance` already uses for `load_module_requires`, `topology_analysis.py:103-111`).

**Security posture (unchanged, now provable instead of asserted):** closed by default; every rule
source-scoped (never `allow <port>` bare); consent/sudo is the handshake, never silent; a DHCP-leased
address on a manager/proxy is a FINDING, not a silent change — nothing here authorizes `pol` to touch a
firewall or an address without a typed `y`/sudo prompt, matching `fw-handshake.sh`'s existing rule
word-for-word.

## 4. Slices

| slice | what | proof | gate |
|---|---|---|---|
| **tnb-0** | `MachineAddress`/`MachineFirewall`/`NetworkEdge`/`AppliedRule` rows; `net_needs.py` derivation; `pol topology report` observes addresses/firewall/edges (`net_probe.py` wrapping the four `swarm.sh` checks); 9 new `validate_topology` findings; `--json` on `report`/`validate`/`graph` | on the LIVE home topology: must raise `advertise-address-drift` + `route-source-mismatch` + `address-not-stable` for pol-core AND `edge-data-plane-dead` for the four hw-engine ports, matching what was found and fixed by hand on 2026-10-04 | D-tnb-1 |
| **tnb-1** | consented actions (`address add-secondary\|route-source\|make-static`, `firewall allow`, `swarm rejoin`) + `AppliedRule` mirror + `pol topology handback` | the fake no-TTY/CI harness (mirrors `fw-handshake.sh`'s existing selftest pattern) for every refusal path; ONE real consented run with him on pol-core | D-tnb-2 |
| **tnb-2** | visualization: `NetworkEdge` edges colored by state, firewall badge, `AppliedRule` drawer tab | his browser pass on `/topology` and `/display/security-network`'s new "live machines" panel | — |
| **tnb-3** | fold-in: `pol net`/`pol swarm ports`/`pol swarm join` become thin callers of `topology/net_probe.py` + `net_needs.py`; duplicate probe code deleted; selftests moved, not duplicated | `swarm-selftest` stays green post-redirect; no two functions answer the same question | D-tnb-4 |

## 5. Costs

Measured per probe, nothing heavy — this is plumbing, not a new engine or image. Per-call cost is an ssh
round trip (`ConnectTimeout=8`, same as `fw-handshake.sh`/`net.sh` today) plus one `nc`/`curl`/`docker
inspect` each; `check_data_plane`'s curl pair is bounded by `SWARM_DP_TIMEOUT` (default 5 s) per route. No
new container, no new dependency — `topology/net_probe.py` is pure Python reading the same `docker`/`ip`/
`nc`/`curl` surface the shell checks already call, over the same ssh alias resolution `net.sh` already has.
0 MB of new image.

## 6. Decisions (his; recommendations in bold)

- **D-tnb-1 `NetworkEdge`: derived only, or also hand-declared?** → **Derived only** (§3): a swarm-worker
  instance, an engine assignment and a proxy instance each imply their edges through `net_needs.py`, the
  same way `modules_env_for_instance` derives the requires-closure rather than hand-listing it. A
  hand-declared edge could drift from the instances it claims to describe; a derivation can't.
- **D-tnb-2 does the static-address action apply NetworkManager changes with consent, or print only?** →
  **Print only for tnb-1; apply with `--yes` + sudo only after one real run with him proves the NM command
  set on pol-core's own config** (its `ipv4.addresses` knob, per the DEBT table's own fix). Addresses are
  harder to undo cleanly than a firewall rule (no single "undo" line the way `ufw delete` is); the apply
  path should not ship before it is proven on one real box.
- **D-tnb-3 is the kernel drop-reason tracer (bpftrace) shipped as a probe, or stays a manual diagnosis
  note?** → **Manual note for now.** It needs root + bpftrace on the target and was used exactly once, by
  hand, to find the VXLAN_ENTRY_EXISTS drop reason; `check_data_plane`'s via-node/via-manager timing test
  already proves the SYMPTOM (mesh formed, data plane dead) without root. Promote it to an optional
  evidence-only probe later if the symptom recurs on a box where the timing test alone isn't conclusive.
- **D-tnb-4 keep the `pol net` aliases, or remove at once?** → **Keep for one release** (the `HARDWARE_
  NOCODE_PLAN` precedent: `pol net needs`/`pol net handback` are muscle-memory from this week's hand
  debugging); delete in tnb-3 once `pol topology net …` is proven and nothing else calls the old names.

## 7. The DEBT table (from `BOARD_ARC_HANDOFF.md`), mapped to the slice that clears each row

| hand-applied fix (2026-10-04) | cleared by |
|---|---|
| `ip addr add .210/24` + NM `+ipv4.addresses` (advertise drift) | **tnb-0** finding `advertise-address-drift` (+ **tnb-1** `address make-static` action, D-tnb-2) |
| `route … src .210` (VXLAN frames left from the wrong address) | **tnb-0** finding `route-source-mismatch` |
| two ufw lines for 4789/7946 udp (harmless — ufw was inactive) | **tnb-0** observes `MachineFirewall`; **tnb-1** `firewall allow` applies the derived `NetworkEdge` rule with consent |
| `docker service update --constraint-add` ×6 (unpinned placement) | **tnb-0** finding `placement-unpinned` (the render-side fix itself stays `dev-hw-followups #1`, outside this arc) |
| `BOARD/ESP/FORMAL/PCB_ENGINES_URL` + `LOCAL_IP` exported by hand | **tnb-0** finding `knob-not-from-rows`; the edges that resolve the URLs are the derived `NetworkEdge` rows |
| `pol topology assign … ` computed from the OLD running image | **tnb-0** finding `closure-from-old-image` |
| `pol pcb ingest` in-container path | **out of scope** — CLI path handling (`dev-hw-followups #8`), not network/firewall |
| untracked-file `rm` to unblock `pol jenkins promote test` | **out of scope** — `.gitignore` hygiene |
| `docker rm -f prf-pcb-engines` then `pol swarm deploy hw-engines` | **out of scope** — `pol swarm deploy`'s own ad-hoc-container retirement, not addressed here |
