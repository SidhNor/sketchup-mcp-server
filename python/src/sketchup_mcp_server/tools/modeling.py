"""Modeling and mutation MCP tools."""

from __future__ import annotations

from typing import Any

from fastmcp import Context, FastMCP

from ..bridge import BridgeClient
from ..config import ServerSettings


def register_primary_tools(
    mcp: FastMCP,
    *,
    settings: ServerSettings,
    bridge_client: BridgeClient,
) -> None:
    del settings

    @mcp.tool
    def create_component(
        ctx: Context,
        type: str = "cube",
        position: list[float] | None = None,
        dimensions: list[float] | None = None,
    ) -> dict[str, Any]:
        """Create a new component in SketchUp."""
        return bridge_client.call_tool(
            "create_component",
            {
                "type": type,
                "position": position or [0, 0, 0],
                "dimensions": dimensions or [1, 1, 1],
            },
            request_id=_request_id(ctx),
        )

    @mcp.tool
    def delete_component(ctx: Context, id: str) -> dict[str, Any]:
        """Delete a component by ID."""
        return bridge_client.call_tool(
            "delete_component",
            {"id": id},
            request_id=_request_id(ctx),
        )

    @mcp.tool
    def transform_component(
        ctx: Context,
        id: str,
        position: list[float] | None = None,
        rotation: list[float] | None = None,
        scale: list[float] | None = None,
    ) -> dict[str, Any]:
        """Transform a component's position, rotation, or scale."""
        arguments: dict[str, Any] = {"id": id}
        if position is not None:
            arguments["position"] = position
        if rotation is not None:
            arguments["rotation"] = rotation
        if scale is not None:
            arguments["scale"] = scale
        return bridge_client.call_tool(
            "transform_component",
            arguments,
            request_id=_request_id(ctx),
        )


def register_tools(
    mcp: FastMCP,
    *,
    settings: ServerSettings,
    bridge_client: BridgeClient,
) -> None:
    register_primary_tools(mcp, settings=settings, bridge_client=bridge_client)
    register_secondary_tools(mcp, settings=settings, bridge_client=bridge_client)


def register_secondary_tools(
    mcp: FastMCP,
    *,
    settings: ServerSettings,
    bridge_client: BridgeClient,
) -> None:
    del settings

    @mcp.tool
    def set_material(ctx: Context, id: str, material: str) -> dict[str, Any]:
        """Set the material for a SketchUp entity."""
        return bridge_client.call_tool(
            "set_material",
            {"id": id, "material": material},
            request_id=_request_id(ctx),
        )

    @mcp.tool
    def export_scene(
        ctx: Context,
        format: str = "skp",
        width: int | None = None,
        height: int | None = None,
    ) -> dict[str, Any]:
        """Export the current SketchUp scene."""
        arguments: dict[str, Any] = {"format": format}
        if width is not None:
            arguments["width"] = width
        if height is not None:
            arguments["height"] = height
        return bridge_client.call_tool("export", arguments, request_id=_request_id(ctx))

    @mcp.tool
    def boolean_operation(
        ctx: Context,
        target_id: str,
        tool_id: str,
        operation: str,
        delete_originals: bool = False,
    ) -> dict[str, Any]:
        """Run a boolean operation between two SketchUp groups/components."""
        return bridge_client.call_tool(
            "boolean_operation",
            {
                "target_id": target_id,
                "tool_id": tool_id,
                "operation": operation,
                "delete_originals": delete_originals,
            },
            request_id=_request_id(ctx),
        )

    @mcp.tool
    def chamfer_edges(
        ctx: Context,
        entity_id: str,
        distance: float = 0.5,
        edge_indices: list[int] | None = None,
        delete_original: bool = False,
    ) -> dict[str, Any]:
        """Create a chamfer on selected edges of a group or component."""
        arguments: dict[str, Any] = {
            "entity_id": entity_id,
            "distance": distance,
            "delete_original": delete_original,
        }
        if edge_indices is not None:
            arguments["edge_indices"] = edge_indices
        return bridge_client.call_tool(
            "chamfer_edges",
            arguments,
            request_id=_request_id(ctx),
        )

    @mcp.tool
    def fillet_edges(
        ctx: Context,
        entity_id: str,
        radius: float = 0.5,
        segments: int = 8,
        edge_indices: list[int] | None = None,
        delete_original: bool = False,
    ) -> dict[str, Any]:
        """Create a fillet on selected edges of a group or component."""
        arguments: dict[str, Any] = {
            "entity_id": entity_id,
            "radius": radius,
            "segments": segments,
            "delete_original": delete_original,
        }
        if edge_indices is not None:
            arguments["edge_indices"] = edge_indices
        return bridge_client.call_tool(
            "fillet_edges",
            arguments,
            request_id=_request_id(ctx),
        )

def _request_id(ctx: Context) -> Any:
    return getattr(ctx, "request_id", None)
