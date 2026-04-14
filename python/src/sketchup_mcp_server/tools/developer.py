"""Developer-oriented MCP tools."""

from __future__ import annotations

from typing import Any

from fastmcp import Context, FastMCP

from ..bridge import BridgeClient
from ..config import ServerSettings


def register_tools(
    mcp: FastMCP,
    *,
    settings: ServerSettings,
    bridge_client: BridgeClient,
) -> None:
    del settings

    @mcp.tool
    def eval_ruby(ctx: Context, code: str) -> dict[str, Any]:
        """Evaluate arbitrary Ruby code inside SketchUp."""
        return bridge_client.call_tool(
            "eval_ruby",
            {"code": code},
            request_id=_request_id(ctx),
        )


def _request_id(ctx: Context) -> Any:
    return getattr(ctx, "request_id", None)
