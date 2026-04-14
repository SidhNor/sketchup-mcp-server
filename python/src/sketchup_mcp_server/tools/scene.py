"""Scene inspection MCP tools."""

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
    def get_scene_info(ctx: Context, entity_limit: int = 25) -> dict[str, Any]:
        """Get a structured summary of the current SketchUp scene."""
        return bridge_client.call_tool(
            "get_scene_info",
            {"entity_limit": entity_limit},
            request_id=_request_id(ctx),
        )

    @mcp.tool
    def list_entities(
        ctx: Context,
        limit: int = 100,
        include_hidden: bool = False,
    ) -> dict[str, Any]:
        """List top-level entities in the current SketchUp model."""
        return bridge_client.call_tool(
            "list_entities",
            {"limit": limit, "include_hidden": include_hidden},
            request_id=_request_id(ctx),
        )

    @mcp.tool
    def get_entity_info(ctx: Context, id: str) -> dict[str, Any]:
        """Get structured information about a specific SketchUp entity by ID."""
        return bridge_client.call_tool(
            "get_entity_info",
            {"id": id},
            request_id=_request_id(ctx),
        )


def register_selection_tool(
    mcp: FastMCP,
    *,
    settings: ServerSettings,
    bridge_client: BridgeClient,
) -> None:
    del settings

    @mcp.tool
    def get_selection(ctx: Context) -> dict[str, Any]:
        """Get detailed information about the current SketchUp selection."""
        return bridge_client.call_tool("get_selection", request_id=_request_id(ctx))


def _request_id(ctx: Context) -> Any:
    return getattr(ctx, "request_id", None)
