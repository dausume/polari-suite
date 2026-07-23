"""HTTP client helpers for the Polari backend.

Encapsulates the CRUDE wire protocol so the MCP tools don't repeat it:
  - reads are plain GET (optionally with an attribute query)
  - writes are multipart/form-data with Polari's field conventions:
        create  POST   initParamSets = JSON array of __init__ kwargs
        update  PUT     polariId + updateData(JSON dict)
        delete  DELETE  targetInstance = JSON query (must resolve to ONE; use id)
        event   EVENT   targetInstance + event(method name) + optional params
  - custom endpoints (e.g. /api/simulations/...) are plain GET/POST JSON
"""

from __future__ import annotations

import json
import os
from typing import Any, Optional

import httpx

BASE_URL = os.environ.get("POLARI_BASE_URL", "http://localhost:3000").rstrip("/")
TOKEN = os.environ.get("POLARI_TOKEN")
TIMEOUT = float(os.environ.get("POLARI_TIMEOUT", "20"))


def _headers() -> dict[str, str]:
    h = {"Accept": "application/json"}
    if TOKEN:
        h["Authorization"] = f"Bearer {TOKEN}"
    return h


def _envelope(resp: httpx.Response) -> dict[str, Any]:
    try:
        body: Any = resp.json()
    except ValueError:
        body = resp.text
    return {"ok": resp.is_success, "status": resp.status_code, "url": str(resp.url), "data": body}


def _conn_error(url: str, exc: Exception) -> dict[str, Any]:
    return {
        "ok": False, "status": None, "url": url,
        "error": f"{type(exc).__name__}: {exc}",
        "hint": f"Could not reach the Polari node at {BASE_URL}. Is it running?",
    }


async def get(path: str, params: Optional[str] = None) -> dict[str, Any]:
    url = f"{BASE_URL}{path}"
    try:
        async with httpx.AsyncClient(timeout=TIMEOUT) as c:
            return _envelope(await c.get(url, headers=_headers(), params=params))
    except httpx.RequestError as exc:
        return _conn_error(url, exc)


async def post_json(path: str, payload: Optional[dict] = None) -> dict[str, Any]:
    url = f"{BASE_URL}{path}"
    try:
        async with httpx.AsyncClient(timeout=TIMEOUT) as c:
            return _envelope(await c.post(url, headers=_headers(), json=payload or {}))
    except httpx.RequestError as exc:
        return _conn_error(url, exc)


async def _multipart(method: str, path: str, fields: dict[str, str]) -> dict[str, Any]:
    url = f"{BASE_URL}{path}"
    # httpx `files` with (None, value) tuples encodes multipart/form-data.
    files = {k: (None, v) for k, v in fields.items()}
    try:
        async with httpx.AsyncClient(timeout=TIMEOUT) as c:
            return _envelope(await c.request(method, url, headers=_headers(), files=files))
    except httpx.RequestError as exc:
        return _conn_error(url, exc)


# -- CRUDE writes (each returns the envelope; callers gate BEFORE calling) --

async def create(class_name: str, params: dict[str, Any]) -> dict[str, Any]:
    return await _multipart("POST", f"/{class_name}",
                            {"initParamSets": json.dumps([params])})


async def update(class_name: str, polari_id: str, update_data: dict[str, Any]) -> dict[str, Any]:
    return await _multipart("PUT", f"/{class_name}",
                            {"polariId": polari_id, "updateData": json.dumps(update_data)})


async def delete_by_id(class_name: str, polari_id: str) -> dict[str, Any]:
    # Always target by id — attribute queries resolve to many and 409.
    return await _multipart("DELETE", f"/{class_name}",
                            {"targetInstance": json.dumps({"id": polari_id})})


async def event(class_name: str, target_id: str, method: str,
                literal_params: Optional[dict] = None) -> dict[str, Any]:
    fields = {"targetInstance": json.dumps({"id": target_id}), "event": method}
    if literal_params:
        fields["literalParams"] = json.dumps(literal_params)
    return await _multipart("EVENT", f"/{class_name}", fields)


# -- helpers -----------------------------------------------------------

def find_instances(read_envelope: dict[str, Any]) -> list[dict[str, Any]]:
    """Flatten a CRUDE read envelope into a list of instance dicts (those with an 'id')."""
    out: list[dict[str, Any]] = []

    def walk(o: Any) -> None:
        if isinstance(o, dict):
            if o.get("id") is not None and "class" not in o:
                out.append(o)
            for v in o.values():
                walk(v)
        elif isinstance(o, list):
            for v in o:
                walk(v)

    walk(read_envelope.get("data"))
    return out
