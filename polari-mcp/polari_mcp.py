"""Polari MCP server — a provider-agnostic adapter exposing a running Polari
node as Model Context Protocol tools, with a deterministic authority gate on
every mutation and a committed JSON conventions standard surfaced to every
connecting AI.

Capability areas (see ai_conventions.json for the full standard):
  - Topology / module awareness        (read)
  - No-code inspection & play-through  (read + gated step)
  - Connectors                         (gated create)
  - Displays & event wiring            (gated incremental update)
  - Navigation assistance              (read / advice)

Mutation contract: every propose_* tool returns a dry-run JSON proposal;
nothing takes effect until polari_execute_proposal(proposal_id, confirm=True).
The AI cannot self-approve actions above the auto authority threshold. Every
proposal and execution is appended to logs/provenance.jsonl (human-analyzable).

Transport: stdio by default (Claude Code binding). Set POLARI_MCP_TRANSPORT=http
for the streamable-HTTP transport (provider-agnostic, multi-client).
"""

from __future__ import annotations

import json
import os
import time
from pathlib import Path
from typing import Any

from mcp.server.fastmcp import FastMCP

import polari_client as pc
from authority import AuthorityKernel

_HERE = Path(__file__).resolve().parent
_CONVENTIONS = json.loads((_HERE / "ai_conventions.json").read_text())

kernel = AuthorityKernel()

_INSTRUCTIONS = (
    "Polari research-OS control surface. Before manipulating no-code, displays, "
    "connectors, or navigation, read the standard via the `polari_conventions` "
    "tool (or the polari://conventions resource). Core rules: inspect before you "
    "write; every mutation is a two-step propose -> polari_execute_proposal(confirm=True); "
    "you cannot self-approve actions above the authority threshold; every change is "
    "recorded to a JSON provenance log for human review."
)

mcp = FastMCP(
    "polari",
    instructions=_INSTRUCTIONS,
    host=os.environ.get("POLARI_MCP_HOST", "127.0.0.1"),
    port=int(os.environ.get("POLARI_MCP_PORT", "3005")),
)


def _now() -> float:
    return time.time()


# ======================================================================
# The standard, surfaced to every connecting AI
# ======================================================================

@mcp.resource("polari://conventions")
def conventions_resource() -> str:
    """The committed JSON standard every AI must follow using this server."""
    return json.dumps(_CONVENTIONS, indent=2)


@mcp.tool()
def polari_conventions() -> dict[str, Any]:
    """Return the standard approach (JSON) every AI must follow when using this
    server to manipulate no-code, displays, connectors, topology, and navigation.
    Read this first. It is also a git-tracked file: polari-mcp/ai_conventions.json.
    """
    return _CONVENTIONS


@mcp.tool()
def polari_config() -> dict[str, Any]:
    """This adapter's non-secret configuration (base URL, auth mode, authority threshold)."""
    from authority import ALLOW_HIGH_AUTHORITY, AUTO_MAX_LEVEL
    return {
        "base_url": pc.BASE_URL,
        "auth": "bearer-token" if pc.TOKEN else "anonymous (no token)",
        "auto_max_authority_level": AUTO_MAX_LEVEL,
        "high_authority_grant_active": ALLOW_HIGH_AUTHORITY,
        "provenance_log": "logs/provenance.jsonl",
    }


# ======================================================================
# A. Topology / module awareness (read, level 0)
# ======================================================================

@mcp.tool()
async def polari_ping() -> dict[str, Any]:
    """Liveness + host metrics for the Polari node (GET /system-info)."""
    return await pc.get("/system-info")


@mcp.tool()
async def polari_list_object_types() -> dict[str, Any]:
    """The object-tree class catalog (GET /managerObject -> availableObjectTypes)."""
    return await pc.get("/managerObject")


@mcp.tool()
async def polari_instance_counts() -> dict[str, Any]:
    """Per-class live instance counts (GET /classInstanceCounts)."""
    return await pc.get("/classInstanceCounts")


@mcp.tool()
async def polari_list_modules() -> dict[str, Any]:
    """Modules and their status (GET /modules)."""
    return await pc.get("/modules")


@mcp.tool()
async def polari_topology() -> dict[str, Any]:
    """Topology of the running instance: the TopologyDefinition(s) and mesh peers."""
    topo = await pc.get("/TopologyDefinition")
    peers = await pc.get("/api/peers")
    return {"topology_definitions": topo, "peers": peers}


@mcp.tool()
async def polari_service_connections() -> dict[str, Any]:
    """Existing service connections between elements (GET /ServiceConnection)."""
    return await pc.get("/ServiceConnection")


@mcp.tool()
async def polari_read_class(class_name: str, attribute_filter: str | None = None) -> dict[str, Any]:
    """Read instances of a class via CRUDE (GET /<class_name>). class_name from
    polari_list_object_types. attribute_filter is a raw query string (e.g. 'name=foo').
    Note: the node currently returns all instances regardless of filter — filter client-side.
    """
    if not class_name or "/" in class_name or class_name.startswith(".") or " " in class_name:
        return {"ok": False, "error": f"invalid class_name: {class_name!r}"}
    return await pc.get(f"/{class_name}", params=attribute_filter)


# ======================================================================
# B. No-code inspection & play-through
# ======================================================================

@mcp.tool()
async def polari_list_solutions() -> dict[str, Any]:
    """No-code solution definitions (GET /SolutionDefinition)."""
    return await pc.get("/SolutionDefinition")


@mcp.tool()
async def polari_list_simulations() -> dict[str, Any]:
    """Simulation definitions known to the node (GET /api/simulations)."""
    return await pc.get("/api/simulations")


@mcp.tool()
async def polari_sim_runs() -> dict[str, Any]:
    """Simulation runs available to play through (GET /api/simulations/runs)."""
    return await pc.get("/api/simulations/runs")


@mcp.tool()
async def polari_sim_state(run_name: str) -> dict[str, Any]:
    """Current state of a simulation run — the per-state no-code context you analyze
    between steps (GET /api/simulations/runs/{run_name}/current-state).
    """
    return await pc.get(f"/api/simulations/runs/{run_name}/current-state")


@mcp.tool()
async def polari_propose_sim_step(run_name: str, steps: int = 1) -> dict[str, Any]:
    """PROPOSE advancing a simulation run by N steps (play-through). Reversible-workspace
    (level 2). Returns a dry-run proposal; confirm with polari_execute_proposal.
    Read polari_sim_state before and after to record the play-through.
    """
    path = f"/api/simulations/runs/{run_name}/step"
    payload = {"steps": steps}
    return kernel.propose(
        operation="sim_step",
        summary=f"Advance simulation run '{run_name}' by {steps} step(s)",
        request={"method": "POST", "path": path, "payload": payload},
        executor=lambda: _sync(pc.post_json(path, payload)),
        clock=_now(),
    )


# ======================================================================
# C. Connectors (gated create, level 3)
# ======================================================================

@mcp.tool()
async def polari_propose_connector(params: dict[str, Any],
                                   connector_class: str = "ServiceConnection") -> dict[str, Any]:
    """PROPOSE creating a connector between elements (default class ServiceConnection).
    Reversible-system (level 3). `params` are the connector's __init__ kwargs — read an
    existing connector with polari_service_connections first to mirror its shape.
    Confirm with polari_execute_proposal.
    """
    return kernel.propose(
        operation="connect",
        summary=f"Create {connector_class} connector: {json.dumps(params)[:160]}",
        request={"method": "POST(create)", "class": connector_class, "params": params},
        executor=lambda: _sync(pc.create(connector_class, params)),
        clock=_now(),
    )


# ======================================================================
# D. Displays & event wiring (gated incremental update, level 3)
# ======================================================================

@mcp.tool()
async def polari_list_displays() -> dict[str, Any]:
    """Display definitions (GET /DisplayDefinition)."""
    return await pc.get("/DisplayDefinition")


@mcp.tool()
async def polari_get_display(display_id: str) -> dict[str, Any]:
    """Read one display definition by id (from polari_list_displays), filtered client-side."""
    env = await pc.get("/DisplayDefinition")
    for inst in pc.find_instances(env):
        if inst.get("id") == display_id:
            return {"ok": True, "display": inst}
    return {"ok": False, "error": f"no DisplayDefinition with id {display_id!r}"}


@mcp.tool()
async def polari_propose_display_update(display_id: str, patch: dict[str, Any]) -> dict[str, Any]:
    """PROPOSE an INCREMENTAL update to a display — only the fields in `patch` change.
    Reversible-system (level 3). Read polari_get_display first and patch the minimal set
    of fields. Confirm with polari_execute_proposal.
    """
    return kernel.propose(
        operation="display_update",
        summary=f"Patch DisplayDefinition {display_id}: fields {list(patch.keys())}",
        request={"method": "PUT(update)", "class": "DisplayDefinition",
                 "polariId": display_id, "updateData": patch},
        executor=lambda: _sync(pc.update("DisplayDefinition", display_id, patch)),
        clock=_now(),
    )


@mcp.tool()
async def polari_propose_bind_event(display_id: str, event_binding: dict[str, Any]) -> dict[str, Any]:
    """PROPOSE wiring an event/data binding onto a display so it reacts to state.
    Reversible-system (level 3). `event_binding` is merged into the display's config fields
    (e.g. a data source, equation ref, or event->action map — read polari_get_display to see
    the display's actual binding fields first). Confirm with polari_execute_proposal.
    """
    return kernel.propose(
        operation="bind_event",
        summary=f"Bind event/data to DisplayDefinition {display_id}: {list(event_binding.keys())}",
        request={"method": "PUT(update)", "class": "DisplayDefinition",
                 "polariId": display_id, "updateData": event_binding},
        executor=lambda: _sync(pc.update("DisplayDefinition", display_id, event_binding)),
        clock=_now(),
    )


# ======================================================================
# E. Political scorecard: navigate scoring, policy, judicial, groups, maps
# ======================================================================

_PSC = {
    "scoring": ["ScoreTerm", "ScoreConcept", "ScoreGroup", "ScoreSubject",
                "ScoreContext", "ScoreAssertion"],
    "policy": ["PolicyDraft", "LegislationRecord", "LegislationProvision",
               "LegislativeVoteEvent", "PolicyIntent"],
    "judicial": ["CourtCase", "DecisionProcedureEdge", "SystemChoiceInForce",
                 "LogicForkCriterion"],
    "groups": ["ScoreGroup", "GroupAuthorityGrant", "GroupInstanceBinding",
               "Contributor", "WorldviewElection", "WorldviewBallot"],
    "sources": ["GovSource", "NonProfitSource", "CompanySource",
                "PoliticalGroupSource", "IndividualSource", "SourceRetrieval"],
    "maps": ["ZoneDefinition", "ZonePoint", "SiteDefinition",
             "MapPointDefinition", "MapLineSegmentDefinition", "MapPolygonDefinition"],
}

_SUMMARY_FIELDS = ("id", "name", "display_name", "title", "description",
                   "label", "value", "term", "subject", "context")


def _summarize(env: dict[str, Any], limit: int = 40) -> list[dict[str, Any]]:
    """Trim a CRUDE read to a short, human-legible list — the whole point for
    an average user navigating a complex scorecard."""
    rows = []
    for inst in pc.find_instances(env)[:limit]:
        rows.append({k: inst[k] for k in _SUMMARY_FIELDS if k in inst})
    return rows


async def _counts(classes: list[str]) -> dict[str, Any]:
    out: dict[str, Any] = {}
    for cls in classes:
        env = await pc.get(f"/{cls}")
        out[cls] = len(pc.find_instances(env)) if env.get("ok") else None
    return out


@mcp.tool()
async def polari_psc_overview() -> dict[str, Any]:
    """One-call orientation for the political scorecard: how many scoring terms,
    subjects, assertions, policies, court cases, sources, elections, and map zones
    exist. Start here to understand what's in the scorecard before navigating.
    """
    return {area: await _counts(classes) for area, classes in _PSC.items()}


@mcp.tool()
async def polari_psc_scoring() -> dict[str, Any]:
    """The scoring structure: terms, concepts, groups, subjects, contexts, and the
    assertions (actual scores) — summarized for readability."""
    return {cls: _summarize(await pc.get(f"/{cls}")) for cls in _PSC["scoring"]}


@mcp.tool()
async def polari_psc_policies() -> dict[str, Any]:
    """Policies and legislation: drafts, records, provisions, votes, and intents."""
    return {cls: _summarize(await pc.get(f"/{cls}")) for cls in _PSC["policy"]}


@mcp.tool()
async def polari_psc_judicial() -> dict[str, Any]:
    """Judicial / decision-procedure context: court cases, decision edges, and the
    system choices in force."""
    return {cls: _summarize(await pc.get(f"/{cls}")) for cls in _PSC["judicial"]}


@mcp.tool()
async def polari_psc_groups() -> dict[str, Any]:
    """Groups and their authority: score groups, authority grants, contributors,
    and worldview elections/ballots that shape group scoring."""
    return {cls: _summarize(await pc.get(f"/{cls}")) for cls in _PSC["groups"]}


@mcp.tool()
async def polari_psc_sources() -> dict[str, Any]:
    """The data sources behind scores: government / nonprofit / company / group /
    individual sources and their retrievals."""
    return {cls: _summarize(await pc.get(f"/{cls}")) for cls in _PSC["sources"]}


@mcp.tool()
async def polari_psc_maps() -> dict[str, Any]:
    """Geographic/map context: zones, sites, and map geometry — for understanding
    political context by place."""
    return {cls: _summarize(await pc.get(f"/{cls}")) for cls in _PSC["maps"]}


@mcp.tool()
async def polari_psc_search(query: str) -> dict[str, Any]:
    """Find scorecard items that mention `query` (case-insensitive substring across
    scoring terms, subjects, policies, and sources) — for a user navigating to the
    issues they care about."""
    q = (query or "").strip().lower()
    if not q:
        return {"ok": False, "error": "empty query"}
    hits: list[dict[str, Any]] = []
    for cls in ["ScoreTerm", "ScoreSubject", "ScoreContext", "PolicyDraft",
                "LegislationRecord", "GovSource"]:
        for row in _summarize(await pc.get(f"/{cls}"), limit=500):
            blob = " ".join(str(v) for v in row.values()).lower()
            if q in blob:
                hits.append({"class": cls, **row})
    return {"ok": True, "query": query, "matches": hits[:60]}


@mcp.tool()
async def polari_propose_score_assertion(subject_id: str, context_id: str,
                                         value: Any, basis: str = "") -> dict[str, Any]:
    """PROPOSE asserting a score (a ScoreAssertion) for a subject in a context.
    Reversible-system (level 3), dry-run until confirmed. Read polari_psc_scoring
    first to use real subject/context ids.
    """
    params = {"subject": subject_id, "context": context_id, "value": value, "basis": basis}
    return kernel.propose(
        operation="score_assert",
        summary=f"Assert score {value!r} for subject {subject_id} in context {context_id}",
        request={"method": "POST(create)", "class": "ScoreAssertion", "params": params},
        executor=lambda: _sync(pc.create("ScoreAssertion", params)),
        clock=_now(),
    )


@mcp.tool()
async def polari_propose_pull_and_assert(source_id: str, policy_or_subject_id: str,
                                         claim: str, value: Any = None) -> dict[str, Any]:
    """PROPOSE the 'pull data from a source and assert it against a policy/subject'
    workflow: records a FactualClaim tying a GovSource retrieval to a policy/subject.
    Reversible-system (level 3), dry-run until confirmed. Use polari_psc_sources +
    polari_psc_policies to reference real ids.
    """
    params = {"source": source_id, "target": policy_or_subject_id, "claim": claim, "value": value}
    return kernel.propose(
        operation="pull_and_assert",
        summary=f"Assert claim from source {source_id} against {policy_or_subject_id}: {claim[:80]}",
        request={"method": "POST(create)", "class": "FactualClaim", "params": params},
        executor=lambda: _sync(pc.create("FactualClaim", params)),
        clock=_now(),
    )


# ======================================================================
# F. Object storage (MinIO) — file access
# ======================================================================

@mcp.tool()
async def polari_storage_status() -> dict[str, Any]:
    """Object-storage (MinIO) connection status: connected?, endpoint, buckets."""
    return await pc.get("/object-storage")


@mcp.tool()
async def polari_storage_buckets() -> dict[str, Any]:
    """List object-storage buckets (GET /object-storage/buckets). Returns a clear
    'not connected' when MinIO isn't attached to this node."""
    return await pc.get("/object-storage/buckets")


@mcp.tool()
async def polari_list_files() -> dict[str, Any]:
    """Files Polari knows about (managedFile registry) — the file layer backed by
    object storage when connected."""
    return _summarize(await pc.get("/managedFile"), limit=100)


@mcp.tool()
async def polari_propose_storage_connect(config: dict[str, Any]) -> dict[str, Any]:
    """PROPOSE connecting the node to object storage (POST /object-storage/connect).
    Network-service (level 4) — the AI CANNOT self-approve this; it needs an
    out-of-band grant. Do not put real secrets in the proposal casually; a human
    supplies/approves credentials.
    """
    return kernel.propose(
        operation="storage_connect",
        summary=f"Connect object storage: endpoint={config.get('endpoint', '?')}",
        request={"method": "POST", "path": "/object-storage/connect", "config_keys": list(config.keys())},
        executor=lambda: _sync(pc.post_json("/object-storage/connect", config)),
        clock=_now(),
    )


@mcp.tool()
async def polari_propose_recon_run(job_name: str) -> dict[str, Any]:
    """PROPOSE running a photogrammetry ReconstructionJob (POST
    /api/scanning/jobs/{name}/run — scan-4). Network-service (level 4):
    tens of CPU-minutes on the recon worker, so the AI CANNOT
    self-approve; a human confirms via polari_execute_proposal after an
    out-of-band grant. The job row must already exist (CRUDE POST
    /ReconstructionJob, status 'proposed') and its CaptureSession must
    hold >=3 images. Re-runs are NEW job rows — nothing is overwritten.
    """
    path = f"/api/scanning/jobs/{job_name}/run"
    return kernel.propose(
        operation="recon_run",
        summary=f"Run reconstruction job {job_name!r} on the recon worker",
        request={"method": "POST", "path": path},
        executor=lambda: _sync(pc.post_json(path, {})),
        clock=_now(),
    )


# ======================================================================
# G. Reasoning-provider management (select + auth + validate)
# ======================================================================

@mcp.tool()
async def polari_reasoning_providers() -> dict[str, Any]:
    """Status of every reasoning provider: which SDKs are installed, which have a
    credential, which is active, and what each still needs to be ready. Use this to
    see how to set up a provider. Secrets are never shown — only whether one is set.
    """
    return await pc.get("/ai/providers")


@mcp.tool()
async def polari_reasoning_validate(provider: str) -> dict[str, Any]:
    """Probe a provider (a tiny live call) to confirm it is set up correctly.
    Read-only in effect — makes no config change. Returns {ok, detail}.
    """
    return await pc.post_json("/ai/providers", {"action": "validate", "provider": provider})


@mcp.tool()
async def polari_propose_select_provider(provider: str,
                                        settings: dict[str, Any] | None = None) -> dict[str, Any]:
    """PROPOSE switching the active reasoning provider (e.g. null -> anthropic, or an
    OpenAI-compatible local endpoint). Reversible-system (level 3), dry-run until
    confirmed. `settings` carries non-secret config like model or base_url.
    Note: this does NOT set credentials — a human enters the secret directly via the
    backend so it never passes through the AI/audit log. Check polari_reasoning_providers
    for what a provider still needs.
    """
    return kernel.propose(
        operation="select_provider",
        summary=f"Select reasoning provider '{provider}'"
                + (f" with {list((settings or {}).keys())}" if settings else ""),
        request={"method": "POST", "path": "/ai/providers",
                 "body": {"action": "select", "provider": provider, "settings": settings or {}}},
        executor=lambda: _sync(pc.post_json(
            "/ai/providers", {"action": "select", "provider": provider, "settings": settings or {}})),
        clock=_now(),
    )


# ======================================================================
# Authority gate control + audit
# ======================================================================

@mcp.tool()
def polari_execute_proposal(proposal_id: str, confirm: bool = False) -> dict[str, Any]:
    """Apply a previously-proposed change. Requires confirm=True. The kernel refuses
    proposals above the authority threshold unless an out-of-band grant is active.
    Records the outcome to the provenance log.
    """
    return kernel.execute(proposal_id, confirm=confirm, clock=_now())


@mcp.tool()
def polari_list_proposals() -> dict[str, Any]:
    """List proposals made this session and their status (pending/executed/refused/failed)."""
    return {"proposals": kernel.list_proposals()}


@mcp.tool()
def polari_provenance(limit: int = 50) -> dict[str, Any]:
    """The JSON-lines audit trail of every proposal and execution — human-analyzable."""
    return {"provenance": kernel.provenance(limit=limit)}


# ----------------------------------------------------------------------
# executor closures run synchronously inside the kernel; bridge the async
# client calls to a blocking result.
# ----------------------------------------------------------------------
def _sync(coro) -> Any:
    import asyncio
    try:
        loop = asyncio.get_running_loop()
    except RuntimeError:
        loop = None
    if loop and loop.is_running():
        # Called from within an async tool -> run the coroutine on a fresh loop
        # in a worker thread to avoid re-entrancy.
        import concurrent.futures
        with concurrent.futures.ThreadPoolExecutor(max_workers=1) as ex:
            return ex.submit(asyncio.run, coro).result()
    return asyncio.run(coro)


if __name__ == "__main__":
    transport = os.environ.get("POLARI_MCP_TRANSPORT", "stdio").lower()
    if transport in ("http", "streamable-http", "streamable_http"):
        mcp.run(transport="streamable-http")
    else:
        mcp.run()
