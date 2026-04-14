"""Semantic MCP tools."""

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
    def create_site_element(
        ctx: Context,
        elementType: str,
        sourceElementId: str,
        status: str,
        footprint: list[list[float]],
        elevation: float | None = None,
        height: float | None = None,
        structureCategory: str | None = None,
        thickness: float | None = None,
        name: str | None = None,
        tag: str | None = None,
        material: str | None = None,
    ) -> dict[str, Any]:
        """Create the first semantic site element slice in SketchUp."""
        arguments: dict[str, Any] = {
            "elementType": elementType,
            "sourceElementId": sourceElementId,
            "status": status,
            "footprint": footprint,
        }
        if elevation is not None:
            arguments["elevation"] = elevation
        if height is not None:
            arguments["height"] = height
        if structureCategory is not None:
            arguments["structureCategory"] = structureCategory
        if thickness is not None:
            arguments["thickness"] = thickness
        if name is not None:
            arguments["name"] = name
        if tag is not None:
            arguments["tag"] = tag
        if material is not None:
            arguments["material"] = material

        return bridge_client.call_tool(
            "create_site_element",
            arguments,
            request_id=_request_id(ctx),
        )


def _request_id(ctx: Context) -> Any:
    return getattr(ctx, "request_id", None)
