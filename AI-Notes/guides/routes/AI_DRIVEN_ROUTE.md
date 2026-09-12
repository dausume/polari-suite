# The AI-driven route: an assistant working through pol and the API

An assistant working on a machine, or over ssh, uses exactly the automated route, plus two things that make the state legible to it.

## Machine-readable state

`pol prod facts --json` returns what the guide knows: addresses, the detected DNS host, the names and whether each resolves, the registry's tags, the official sources, the release tags with installers, memory, swarm state, the vault. The guide's own screens are built from the same JSON, so an assistant sees what a person sees.

`pol modules health` and `GET /api/modules/health` return the registrar: every module's state (declared, loading, online, degraded, failed, invalid, put away) with the reason.

## Actions through the API

Every action a screen offers is an API call an assistant can make: admit a module (`POST /modules/<m>/admit`), fetch and admit one from its repository (`POST /modules/<m>/fetch-admit`), assign a module to an instance (`POST /api/topology/assign`), seed initial data, export rows. Refusals name the next step, so an assistant that admits a module whose dependencies are not online is told which to admit first, in order.

## The MCP surface

A Polari instance also exposes an MCP server for assistants: displays, object types, topology, simulations, proposals. Mutations are two-step, propose then execute, and every change is recorded to a provenance log a person can review.

## Rules an assistant follows

The same as a person's: never publish outward without a go, never handle credentials by value, prefer dry runs, and read the run log after apply. The security and permission groups apply to an assistant's account exactly as to any user's.
