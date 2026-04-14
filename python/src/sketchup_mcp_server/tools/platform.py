"""Platform-level MCP tools."""

from __future__ import annotations

from typing import Any

from fastmcp import FastMCP

from ..bridge import BridgeClient
from ..config import ServerSettings


def register_tools(
    mcp: FastMCP,
    *,
    settings: ServerSettings,
    bridge_client: BridgeClient,
) -> None:
    @mcp.tool
    def ping() -> dict[str, Any]:
        """Basic health check for the Python MCP server."""
        return {
            "success": True,
            "message": "pong",
            "transport": settings.transport,
            "sketchup_host": settings.sketchup_host,
            "sketchup_port": settings.sketchup_port,
        }

    @mcp.tool
    def bridge_configuration() -> dict[str, Any]:
        """Return the current MCP transport and SketchUp bridge endpoint."""
        return {
            "mcp_transport": settings.transport,
            "http_host": settings.http_host,
            "http_port": settings.http_port,
            "sketchup_host": settings.sketchup_host,
            "sketchup_port": settings.sketchup_port,
        }
