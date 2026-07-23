"""Phase 2 test: gated no-code/display manipulation through the MCP binding.

Exercises the authority gate end-to-end against the live node:
  - lists tools + the polari://conventions resource
  - read tools (ping, topology, displays)
  - a full gated display round-trip: propose -> refuse(no confirm) -> execute
    -> verify -> restore
  - the JSON provenance audit trail
  - the high-authority refusal path (server launched with a lower threshold)
"""

import asyncio
import json
import os
import sys

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

HERE = os.path.dirname(os.path.abspath(__file__))
SERVER = os.path.join(HERE, "polari_mcp.py")


def txt(res):
    return json.loads(res.content[0].text) if res.content else {}


async def session(env_extra=None):
    env = os.environ.copy()
    if env_extra:
        env.update(env_extra)
    return StdioServerParameters(command=sys.executable, args=[SERVER], env=env)


async def main() -> int:
    async with stdio_client(await session()) as (r, w):
        async with ClientSession(r, w) as s:
            await s.initialize()

            tools = [t.name for t in (await s.list_tools()).tools]
            print(f"tools ({len(tools)}):", ", ".join(tools))
            resources = [str(x.uri) for x in (await s.list_resources()).resources]
            print("resources:", resources)

            conv = txt(await s.call_tool("polari_conventions", {}))
            print(f"conventions: {conv.get('spec')} v{conv.get('version')} — {len(conv.get('interfaces',{}))} interfaces")

            ping = txt(await s.call_tool("polari_ping", {}))
            print("ping ok:", ping.get("ok"), "status:", ping.get("status"))
            topo = txt(await s.call_tool("polari_topology", {}))
            print("topology ok:", topo.get("topology_definitions", {}).get("ok"))
            displays = txt(await s.call_tool("polari_list_displays", {}))
            print("list_displays ok:", displays.get("ok"), "bytes:", len(json.dumps(displays)))

            DID = "Sa6b4qiUN"
            got = txt(await s.call_tool("polari_get_display", {"display_id": DID}))
            original = got.get("display", {}).get("description")
            print(f"\n[round-trip] display {DID} original description = {original!r}")

            new_desc = "MCP phase2 — gated incremental display edit"
            prop = txt(await s.call_tool("polari_propose_display_update",
                                         {"display_id": DID, "patch": {"description": new_desc}}))
            pid = prop.get("proposal_id")
            print(f"proposed: id={pid} level={prop.get('authority_level')} "
                  f"gate_executable={prop.get('gate',{}).get('executable')} dry_run={prop.get('dry_run')}")

            refuse = txt(await s.call_tool("polari_execute_proposal", {"proposal_id": pid, "confirm": False}))
            print(f"execute(confirm=False) -> ok={refuse.get('ok')} error={refuse.get('error')!r}")

            done = txt(await s.call_tool("polari_execute_proposal", {"proposal_id": pid, "confirm": True}))
            print(f"execute(confirm=True) -> ok={done.get('ok')} status={done.get('result',{}).get('status')}")

            after = txt(await s.call_tool("polari_get_display", {"display_id": DID}))
            print(f"verify: description now = {after.get('display',{}).get('description')!r}")

            # restore
            rp = txt(await s.call_tool("polari_propose_display_update",
                                       {"display_id": DID, "patch": {"description": original}}))
            await s.call_tool("polari_execute_proposal", {"proposal_id": rp["proposal_id"], "confirm": True})
            restored = txt(await s.call_tool("polari_get_display", {"display_id": DID}))
            print(f"restored: description = {restored.get('display',{}).get('description')!r}")

            prov = txt(await s.call_tool("polari_provenance", {"limit": 20}))
            print(f"\nprovenance entries: {len(prov.get('provenance',[]))} (JSON audit trail)")
            for e in prov.get("provenance", [])[-4:]:
                print(f"  {e.get('phase'):9} L{e.get('authority_level')} {e.get('operation'):14} {e.get('summary')}")

    # high-authority refusal: threshold lowered so level-3 display edits are blocked
    print("\n[gate] relaunch with POLARI_AUTO_MAX_LEVEL=2 (level-3 edits must be refused)")
    async with stdio_client(await session({"POLARI_AUTO_MAX_LEVEL": "2"})) as (r, w):
        async with ClientSession(r, w) as s:
            await s.initialize()
            prop = txt(await s.call_tool("polari_propose_display_update",
                                         {"display_id": "Sa6b4qiUN", "patch": {"description": "should-be-blocked"}}))
            print(f"proposed level={prop.get('authority_level')} gate_executable={prop.get('gate',{}).get('executable')}")
            res = txt(await s.call_tool("polari_execute_proposal",
                                        {"proposal_id": prop["proposal_id"], "confirm": True}))
            print(f"execute(confirm=True) -> ok={res.get('ok')} refused={res.get('refused')} reason={res.get('reason')!r}")
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
