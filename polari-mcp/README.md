# Polari MCP server

A provider-agnostic [Model Context Protocol](https://modelcontextprotocol.io)
adapter that exposes a running Polari node so any MCP-capable AI — Claude Code,
Claude Desktop, or another vendor's agent — can inspect and manipulate Polari's
no-code, displays, connectors, topology, and navigation through **one standard,
gated, human-auditable interface**.

This is the convergence seam for "the same AI in the terminal and in Polari":
the terminal agent and Polari's in-app reasoning both call these tools against
the same node state.

## The standard every AI follows

`ai_conventions.json` (git-**tracked**, human- and machine-readable) is the
canonical standard: authority ladder, the propose→confirm→execute mutation
protocol, per-interface command patterns, and the audit contract. It is served
to every connecting AI two ways:

- the `polari://conventions` MCP **resource**
- the `polari_conventions` **tool** (read it first)

Because it is JSON, a human can read exactly how an AI is expected to — and
does — manipulate the interfaces.

## How mutation works (the authority gate)

Every change is **two-step and deterministic-gated** (`authority.py`):

1. A `propose_*` tool returns a **dry-run JSON proposal** — operation, authority
   level (0–7), a one-line summary, and the exact request that will be sent.
2. Nothing happens until `polari_execute_proposal(proposal_id, confirm=True)`.
3. The kernel **refuses** anything above the auto threshold
   (`POLARI_AUTO_MAX_LEVEL`, default 3) unless an out-of-band grant
   (`POLARI_ALLOW_HIGH_AUTHORITY=1`) is active. **The AI cannot self-approve
   high-authority actions.**
4. Every proposal and execution is appended to `logs/provenance.jsonl` — one
   JSON object per line, for human review.

## Tools (22)

| Area | Tools |
|---|---|
| **Standard** | `polari_conventions`, `polari_config` |
| **Topology / awareness** (read) | `polari_ping`, `polari_list_object_types`, `polari_instance_counts`, `polari_list_modules`, `polari_topology`, `polari_service_connections`, `polari_read_class` |
| **No-code play-through** | `polari_list_solutions`, `polari_list_simulations`, `polari_sim_runs`, `polari_sim_state`, `polari_propose_sim_step` |
| **Connectors** | `polari_propose_connector` |
| **Displays & events** | `polari_list_displays`, `polari_get_display`, `polari_propose_display_update`, `polari_propose_bind_event` |
| **Gate / audit** | `polari_execute_proposal`, `polari_list_proposals`, `polari_provenance` |

Read tools are level 0. `propose_*` tools are level 2–3 (reversible). Raw delete
is deliberately **not** exposed.

## Setup

```bash
python3 -m pip install --user "mcp[cli]" httpx
```

No token needed for a local dev node (anonymous requests get full access); set
`POLARI_TOKEN` only for a secured node. See `.env.example`.

## Run a node, then test

```bash
# node (bare-metal gives direct http://localhost:3000; gRPC moved off a busy 3002)
cd ../polari-rf-node/polari-framework && GRPC_PORT=3012 python3 initLocalhostPolariServer.py

# stdio binding smoke test (tool discovery + live ping)
python3 test_binding.py
# full gated-write round-trip + high-authority refusal
python3 test_phase2.py
```

## Bind to an AI client

**stdio** (Claude Code launches the server per session):

```bash
claude mcp add polari -e POLARI_BASE_URL=http://localhost:3000 -- python3 "$(pwd)/polari_mcp.py"
```

**HTTP** (provider-agnostic — any vendor's agent binds by URL):

```bash
POLARI_MCP_TRANSPORT=http POLARI_MCP_PORT=3005 python3 polari_mcp.py      # serve
claude mcp add --transport http polari-http http://127.0.0.1:3005/mcp    # bind
```

Tools appear as `mcp__polari__*` in the client's next session.

## Configuration

| Env | Default | Meaning |
|---|---|---|
| `POLARI_BASE_URL` | `http://localhost:3000` | Node to control |
| `POLARI_TOKEN` | (unset) | Bearer token; unset = anonymous (local dev) |
| `POLARI_AUTO_MAX_LEVEL` | `3` | Highest authority level the AI may execute with `confirm` |
| `POLARI_ALLOW_HIGH_AUTHORITY` | (unset) | `1` = out-of-band grant for levels above the threshold |
| `POLARI_MCP_TRANSPORT` | `stdio` | `http` for streamable-HTTP |
| `POLARI_MCP_HOST` / `POLARI_MCP_PORT` | `127.0.0.1` / `3005` | HTTP bind |

## Phase 4 — in-app AI interface (text + voice, incl. VR) — IN PROGRESS

**Backend (done, tested live):**
- `polariApiServer/aiChatAPI.py` — `POST /ai/chat` ({message, history?}) with a
  live node-context snapshot; validates input (400 on missing message).
- `polariApiServer/reasoning_provider.py` — provider-agnostic reasoning layer
  (the capability manager's reasoning slice): `null` deterministic provider by
  default (works with no LLM key), `anthropic` pluggable, more providers drop in
  without touching the API or the app. Selected via `POLARI_REASONING_PROVIDER`.

**Frontend (built, compiles clean — not yet browser/headset-verified),** in
`polari-platform-angular`:
- `components/ai-assistant/ai-assistant-panel.component.ts` — standalone panel,
  text chat + push-to-talk voice (Web Speech API), **XR-aware** (reads
  `XR_PANEL_CONTEXT` → voice-first, keyboard-free, larger for headset
  rasterization; auto-speaks replies).
- `services/ai-assistant/ai-assistant.service.ts` — root service calling `/ai/chat`.
- Mounted app-wide in `app.component.html`; toolbar toggle in the header;
  registered in `AppModule`. `ng build` passes.

**XR surface (built, compiles):** the same `<ai-assistant-panel>` is registered as
an off-screen surface in `XrPanelHostComponent` (id `assistant`) with a wrist-ring
seed row (`panel:assistant`, label ASSISTANT). It inherits `XR_PANEL_CONTEXT=true`
from the host, so the identical voice-first panel is rasterized onto its own
HTMLMesh quad in-session — no XR-specific assistant UI to keep in sync. Runtime
behavior (voice in an immersive session, quad placement) still needs a headset pass.

The assistant is a **client of the gated capability**, not a bypass: in-app
actions still flow through the same propose→confirm→execute gate and provenance
log as the terminal agent — one standard whether the human types, speaks, or is
in VR. A real LLM is enabled by setting `POLARI_REASONING_PROVIDER=anthropic`
(plus SDK + credential); with none set it runs node-aware in no-LLM mode.

## Privacy

`ai_conventions.json` and the code are tracked. `logs/` (provenance + runtime),
`.env`, and the node's local seeded DB are git-ignored.
