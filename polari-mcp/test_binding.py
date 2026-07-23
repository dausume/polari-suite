"""Self-contained binding test for the Polari MCP server.

Launches `polari_mcp.py` over stdio exactly the way an MCP client (Claude Code)
would, lists the exposed tools, and calls `polari_ping` + `polari_list_object_types`.

This validates the full MCP path (client -> stdio -> server -> Polari HTTP)
independent of whether Claude Code has hot-loaded the server into a session.

Run:  python3 test_binding.py
A live Polari node on POLARI_BASE_URL makes the calls return real data; with no
node up, they return the adapter's structured connection error (still a pass for
the binding itself).
"""

import asyncio
import os
import sys

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

HERE = os.path.dirname(os.path.abspath(__file__))


async def main() -> int:
    server = StdioServerParameters(
        command=sys.executable,
        args=[os.path.join(HERE, "polari_mcp.py")],
        env=os.environ.copy(),
    )
    async with stdio_client(server) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()

            tools = await session.list_tools()
            print("Tools exposed by the Polari MCP server:")
            for tool in tools.tools:
                print(f"  - {tool.name}")

            print("\nCalling polari_config ...")
            cfg = await session.call_tool("polari_config", {})
            print(cfg.content[0].text if cfg.content else "(no content)")

            print("\nCalling polari_ping ...")
            ping = await session.call_tool("polari_ping", {})
            print(ping.content[0].text if ping.content else "(no content)")

            print("\nCalling polari_list_object_types ...")
            types = await session.call_tool("polari_list_object_types", {})
            print((types.content[0].text if types.content else "(no content)")[:1200])

    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
