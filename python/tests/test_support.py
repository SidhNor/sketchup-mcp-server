from __future__ import annotations

import importlib
from dataclasses import dataclass, field
from typing import Any

import pytest


def require_module(module_name: str) -> Any:
    """Fail per-test when a planned PLAT-03 seam does not exist yet."""
    try:
        return importlib.import_module(module_name)
    except ModuleNotFoundError as exc:
        pytest.fail(
            f"Expected module {module_name!r} for the PLAT-03 adapter split. "
            f"Create the seam before implementing behavior. Original error: {exc}"
        )


@dataclass
class DummyContext:
    request_id: Any = "req-123"


@dataclass
class RecordingBridgeClient:
    result: Any = field(default_factory=lambda: {"ok": True})
    ping_result: Any = field(default_factory=lambda: {"success": True})
    calls: list[dict[str, Any]] = field(default_factory=list)
    disconnected: bool = False

    def ping(self, request_id: Any = None) -> Any:
        self.calls.append({"kind": "ping", "request_id": request_id})
        if isinstance(self.ping_result, Exception):
            raise self.ping_result
        return self.ping_result

    def call_tool(
        self,
        name: str,
        arguments: dict[str, Any] | None = None,
        request_id: Any = None,
    ) -> Any:
        self.calls.append(
            {
                "kind": "tool",
                "name": name,
                "arguments": arguments or {},
                "request_id": request_id,
            }
        )
        if isinstance(self.result, Exception):
            raise self.result
        return self.result

    def disconnect(self) -> None:
        self.disconnected = True
