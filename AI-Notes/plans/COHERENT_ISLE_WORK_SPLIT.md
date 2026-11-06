# Coherent isle: the work split and the pol / isle CLI boundary (cis)

**Status:** PLAN, 2026-11-06, for the two Claude sessions (pol-core, econ) and Isle Codex to ACK.

## The ask (the user, 2026-11-06)

> coordinate and split work between you and the other claude session on econ for now, we want to try and get a working isle
> where we can dynamically manage the isle urls and manipulate the electronics and other plans at will more easily so it acts
> as a coherent framework both from UI and cli perspectives with things sensibly split between the polari cli and isle cli tools

## The CLI boundary (one rule, applied everywhere)

| | `isle` CLI (Isle-Mesh, Codex owns) | `pol` CLI (polari-cli, the Claude sessions own) |
|---|---|---|
| Acts on | Devices and the network: agents, addresses, `.isle` names and URLs, certificates and trust, routes, the router, installs, updates, reconcile, placing a Polari instance on a device | What happens INSIDE Polari: modules, topology rows, Polari Apps and plans, benches and their runs, engine bindings, tests, data |
| Talks to | The host and the core (root where needed) | A Polari backend's HTTP API (never root) |
| Privilege | `sudo` / `pkexec` (the App's one standard command per task) | None; the backend's own permissions apply |
| Works without the other | Yes | Yes (compose stacks, standalone backends) |
| Uses the other | May post facts into Polari (`/api/islemesh/ingest/*`) | May READ isle facts (`isle ... --json`) to fill a "Needs an isle" answer; never changes the network |

The UI follows the same split: Polari pages call the backend API (the doors `pol` uses); the Isle App's network screens call
`pkexec isle ...`. One operation, one implementation, two front doors (UI and CLI) over it.

## URLs, dynamically

A Polari instance's URLs are isle facts (`isle polari instance deploy / rebase`, DNS + certificate) that Polari CONSUMES:
the frontend's `runtime-config.json`, the backend's CORS origins, the topology `InstanceDefinition.public_base_url /
api_base_url`. Changing a URL = one isle operation, and Polari follows without a rebuild: the generator rewrites the runtime
config + CORS and posts the change to the backend (tpl-3 ingest), which updates its rows. `pol` shows and validates URLs;
it does not set them on an isle.

## Who does what (for now)

### Claude on pol-core
- Topology layers (AI-Notes/plans/TOPOLOGY_LAYERS_PLAN.md): tpl-1 engine bindings + frontend origins as edges, tpl-2 peering
  design, tpl-4 "Needs an isle" states + the `/topology?embed=1` mode the Isle App tab shows, tpl-6 cleanup (the user's go).
- `pol topology` against any backend URL (`--api https://api.<name>.isle`), not only the local docker backend.
- Backend image integration of fixes 12/13 with Codex; the live polari-pol backend.

### Claude on econ
- **Plans at will from the CLI:** `pol bench` / `pol plans` over the existing HTTP doors, so every Bench / electronics plan
  action the UI does is a command too: list benches, apply a topology spec, define a node, run a node or all nodes, list
  runs and captures, pin a capture, read the electronics checks. Same doors as the canvas; no new backend API unless a door
  is missing (then name it to pol-core first).
- **Engines on the isle (fix 11, backend consumer half):** a backend binds every engine the isle announces, at boot and when a
  new engine app is installed, with no hand `ingest/engine`. Codex owns the announcement and registry contract; the consumer
  is `modules/islemesh` + `topology/provider_registry.py`. Agree the contract with Codex before editing.
- **The econ member's own state:** econ's update to the current release with the user, and the board-engines worker
  (end-to-end proof: Polari provider -> compile -> simulate -> saved result -> frontend).

### Isle Codex (isle-core), by its own ACK
- Fixes 1-11 (install/update automation), the Isle App topology tabs (tpl-5, Isle Topology default), the isle half of tpl-3,
  the instance generator setting `POLARI_INSTANCE_NAME` / `POLARI_MACHINE_NAME`, URL changes as one isle operation.

## File boundaries (to avoid colliding edits)

| Area | Owner |
|---|---|
| `topology/` except `provider_registry.py`; `polariApiServer/lazy_boot.py`, `polariServer.py` boot hooks; topology pages in angular | pol-core |
| `polari-cli` new `pol bench` / `pol plans` scripts; `modules/cmod/*_api.py` only to add a missing door (tell pol-core) | econ |
| `modules/islemesh/custom/islemesh_engines.py`, `islemesh_api.py` ingest, `topology/provider_registry.py` | econ (engines), after Codex's contract |
| Isle-Mesh repo, Isle App (polari-app-shell isle screens) | Codex |

## Base and sync

- Base for both Claude sessions: pol-core's framework `dev` at c5c7ec21 (tpl-0, the isle-core catalog merge, dev-mech) and
  angular `dev` (with Codex's generic-operation-ui). Pushed to econ as branch `pol-core-dev` in each repo. All of it is LOCAL
  work, not on GitHub; the msv / bss-11..14 hold still applies (not in any release cut).
- Each session commits on its own branch off `pol-core-dev` (econ: `econ-cis-*`), and hands over by `git fetch` between the
  two devices; pol-core merges into dev. No force pushes; no edits to the other's working checkout.
- Messages: pol-core -> econ by SendMessage; econ -> pol-core by SendMessage. Isle Codex by the isle-core mailbox.
