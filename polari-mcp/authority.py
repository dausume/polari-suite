"""Authority kernel for the Polari MCP server.

This is the trusted, deterministic boundary the AI plane cannot reach past.
Every mutating tool routes through it: the model emits a *typed proposal*, the
kernel classifies its authority level deterministically, and nothing takes
effect until an explicit confirmation clears the gate. High-authority actions
(delete, and anything above the auto threshold) cannot be self-approved by the
model at all — they require an out-of-band grant.

The design mirrors the Polari governance model:
    proposal -> classify -> policy gate -> (confirm) -> execute -> provenance

Levels (the authority ladder):
    0 observation      read-only
    1 advice           text-only, no side effect
    2 reversible-work   create a scratch instance, step a simulation
    3 reversible-system update config, wire a display, add a connector
    4 network/public    (gated: out-of-band approval required)
    5 physical          (never auto)
    6 financial/legal   (never auto)
    7 irreversible      delete, destructive migration (gated)

Auto threshold: levels <= AUTO_MAX_LEVEL may execute once `confirm=True` is
passed. Levels above it are refused unless POLARI_ALLOW_HIGH_AUTHORITY=1 (the
stand-in for a human/out-of-band approval in this prototype).
"""

from __future__ import annotations

import json
import os
import secrets
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable, Optional

AUTO_MAX_LEVEL = int(os.environ.get("POLARI_AUTO_MAX_LEVEL", "3"))
ALLOW_HIGH_AUTHORITY = os.environ.get("POLARI_ALLOW_HIGH_AUTHORITY", "").strip() in ("1", "true", "yes")

_LOG_DIR = Path(__file__).resolve().parent / "logs"
_PROVENANCE = _LOG_DIR / "provenance.jsonl"

# Deterministic operation -> (level, label). The model never sets these.
_OP_LEVEL: dict[str, tuple[int, str]] = {
    "read": (0, "observation"),
    "sim_step": (2, "reversible-workspace"),
    "create": (2, "reversible-workspace"),
    "connect": (3, "reversible-system"),
    "display_update": (3, "reversible-system"),
    "bind_event": (3, "reversible-system"),
    "update": (3, "reversible-system"),
    "event": (3, "reversible-system"),
    "score_assert": (3, "reversible-system"),
    "pull_and_assert": (3, "reversible-system"),
    "select_provider": (3, "reversible-system"),
    "storage_connect": (4, "network-service"),
    # ret-8 seam (mirror of polariApiServer.ai_actions): inbound mesh
    # data proposes at network-service level — never auto-approved.
    "rns_inbound": (4, "network-service"),
    "delete": (7, "irreversible"),
}


def classify(operation: str) -> tuple[int, str]:
    """Deterministically map an operation to (authority_level, label)."""
    return _OP_LEVEL.get(operation, (7, "unknown-treated-as-irreversible"))


@dataclass
class Proposal:
    id: str
    operation: str
    level: int
    label: str
    summary: str
    request: dict[str, Any]           # exactly what will be sent to Polari
    executor: Callable[[], Any] = field(repr=False)  # closure that performs it
    created_at: float = field(default_factory=lambda: 0.0)
    status: str = "pending"           # pending | executed | refused | failed
    result: Any = None


class AuthorityKernel:
    def __init__(self) -> None:
        self._proposals: dict[str, Proposal] = {}
        _LOG_DIR.mkdir(exist_ok=True)

    # -- proposal creation (called by mutating tools) --------------------
    def propose(
        self,
        operation: str,
        summary: str,
        request: dict[str, Any],
        executor: Callable[[], Any],
        clock: float,
    ) -> dict[str, Any]:
        level, label = classify(operation)
        pid = "prop_" + secrets.token_hex(6)
        prop = Proposal(
            id=pid, operation=operation, level=level, label=label,
            summary=summary, request=request, executor=executor, created_at=clock,
        )
        self._proposals[pid] = prop
        gate = self._gate_preview(level)
        self._record("proposed", prop, extra={"clock": clock})
        return {
            "proposal_id": pid,
            "operation": operation,
            "authority_level": level,
            "authority_label": label,
            "summary": summary,
            "request": request,
            "gate": gate,
            "dry_run": True,
            "next": (
                f"Review, then call polari_execute_proposal(proposal_id='{pid}', confirm=True) "
                "to apply it."
                if gate["executable"]
                else f"BLOCKED: level {level} ({label}) requires out-of-band approval "
                     "(POLARI_ALLOW_HIGH_AUTHORITY). The AI cannot self-approve this."
            ),
        }

    def _gate_preview(self, level: int) -> dict[str, Any]:
        if level <= AUTO_MAX_LEVEL:
            return {"executable": True, "reason": f"level {level} <= auto threshold {AUTO_MAX_LEVEL}"}
        if ALLOW_HIGH_AUTHORITY:
            return {"executable": True, "reason": "out-of-band high-authority grant is active"}
        return {"executable": False, "reason": f"level {level} > auto threshold {AUTO_MAX_LEVEL}; "
                                               "out-of-band approval required"}

    # -- execution (called by polari_execute_proposal) ------------------
    def execute(self, proposal_id: str, confirm: bool, clock: float) -> dict[str, Any]:
        prop = self._proposals.get(proposal_id)
        if prop is None:
            return {"ok": False, "error": f"unknown proposal_id {proposal_id!r}"}
        if prop.status != "pending":
            return {"ok": False, "error": f"proposal already {prop.status}", "proposal_id": proposal_id}
        if not confirm:
            return {"ok": False, "error": "confirm=True is required to apply a proposal",
                    "proposal_id": proposal_id, "authority_level": prop.level}
        gate = self._gate_preview(prop.level)
        if not gate["executable"]:
            prop.status = "refused"
            self._record("refused", prop, extra={"gate": gate, "clock": clock})
            return {"ok": False, "refused": True, "reason": gate["reason"],
                    "proposal_id": proposal_id, "authority_level": prop.level,
                    "note": "The AI cannot self-approve a high-authority action."}
        try:
            result = prop.executor()
            prop.status = "executed"
            prop.result = result
            self._record("executed", prop, extra={"result": _trim(result), "clock": clock})
            return {"ok": True, "proposal_id": proposal_id, "operation": prop.operation,
                    "authority_level": prop.level, "result": result}
        except Exception as exc:  # noqa: BLE001 - surface, don't crash the server
            prop.status = "failed"
            self._record("failed", prop, extra={"error": str(exc), "clock": clock})
            return {"ok": False, "proposal_id": proposal_id, "error": f"{type(exc).__name__}: {exc}"}

    def list_proposals(self) -> list[dict[str, Any]]:
        return [
            {"proposal_id": p.id, "operation": p.operation, "level": p.level,
             "label": p.label, "status": p.status, "summary": p.summary}
            for p in self._proposals.values()
        ]

    def provenance(self, limit: int = 50) -> list[dict[str, Any]]:
        if not _PROVENANCE.exists():
            return []
        lines = _PROVENANCE.read_text().splitlines()[-limit:]
        return [json.loads(ln) for ln in lines if ln.strip()]

    def _record(self, phase: str, prop: Proposal, extra: dict[str, Any]) -> None:
        entry = {
            "phase": phase, "proposal_id": prop.id, "operation": prop.operation,
            "authority_level": prop.level, "authority_label": prop.label,
            "summary": prop.summary, "request": prop.request, **extra,
        }
        with _PROVENANCE.open("a") as fh:
            fh.write(json.dumps(entry, default=str) + "\n")


def _trim(value: Any, limit: int = 2000) -> Any:
    s = json.dumps(value, default=str)
    return value if len(s) <= limit else s[:limit] + f"...<trimmed {len(s) - limit} chars>"
