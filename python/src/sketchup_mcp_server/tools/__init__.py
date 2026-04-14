"""Tool registration for the SketchUp MCP Python adapter."""

from __future__ import annotations

from fastmcp import FastMCP

from ..bridge import BridgeClient
from ..config import ServerSettings
from . import developer, modeling, platform, scene, semantic


def register_all_tools(
    mcp: FastMCP,
    *,
    settings: ServerSettings,
    bridge_client: BridgeClient,
) -> None:
    # Preserve the existing public tool order while moving definitions into
    # capability-oriented modules.
    platform.register_tools(mcp, settings=settings, bridge_client=bridge_client)
    scene.register_tools(mcp, settings=settings, bridge_client=bridge_client)
    semantic.register_tools(mcp, settings=settings, bridge_client=bridge_client)
    modeling.register_primary_tools(mcp, settings=settings, bridge_client=bridge_client)
    scene.register_selection_tool(mcp, settings=settings, bridge_client=bridge_client)
    modeling.register_secondary_tools(mcp, settings=settings, bridge_client=bridge_client)
    developer.register_tools(mcp, settings=settings, bridge_client=bridge_client)
