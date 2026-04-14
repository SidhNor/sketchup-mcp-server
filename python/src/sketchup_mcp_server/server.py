"""Compatibility surface for the SketchUp MCP FastMCP server."""

from __future__ import annotations

from .app import VERSION, create_server, main

mcp = create_server()

__all__ = ["VERSION", "create_server", "main", "mcp"]
