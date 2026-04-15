"""Semantic MCP tools."""

from __future__ import annotations

from typing import Any

from fastmcp import Context, FastMCP
from pydantic import BaseModel

from ..bridge import BridgeClient
from ..config import ServerSettings
from .metadata import tool_metadata


class PathPayload(BaseModel):
    centerline: list[list[float]]
    width: float
    elevation: float | None = None
    thickness: float | None = None


class RetainingEdgePayload(BaseModel):
    polyline: list[list[float]]
    height: float
    thickness: float
    elevation: float | None = None


class PlantingMassPayload(BaseModel):
    boundary: list[list[float]]
    averageHeight: float
    plantingCategory: str | None = None
    elevation: float | None = None


class TreeProxyPosition(BaseModel):
    x: float
    y: float
    z: float | None = None


class TreeProxyPayload(BaseModel):
    position: TreeProxyPosition
    canopyDiameterX: float
    canopyDiameterY: float | None = None
    height: float
    trunkDiameter: float
    speciesHint: str | None = None


class TargetReference(BaseModel):
    sourceElementId: str | None = None
    persistentId: str | None = None
    entityId: str | None = None


class MetadataPatch(BaseModel):
    status: str | None = None
    structureCategory: str | None = None


def register_tools(
    mcp: FastMCP,
    *,
    settings: ServerSettings,
    bridge_client: BridgeClient,
) -> None:
    del settings

    @mcp.tool(
        **tool_metadata(
            title="Create Semantic Site Element",
            description=(
                "Create a managed semantic site element in SketchUp. Current support is "
                "limited to structure, pad, path, retaining_edge, planting_mass, and "
                "tree_proxy creation."
            ),
            read_only=False,
        )
    )
    def create_site_element(
        ctx: Context,
        elementType: str,
        sourceElementId: str,
        status: str,
        footprint: list[list[float]] | None = None,
        elevation: float | None = None,
        height: float | None = None,
        structureCategory: str | None = None,
        thickness: float | None = None,
        name: str | None = None,
        tag: str | None = None,
        material: str | None = None,
        path: PathPayload | None = None,
        retaining_edge: RetainingEdgePayload | None = None,
        planting_mass: PlantingMassPayload | None = None,
        tree_proxy: TreeProxyPayload | None = None,
    ) -> dict[str, Any]:
        """Create the current semantic site element slice in SketchUp."""
        arguments: dict[str, Any] = {
            "elementType": elementType,
            "sourceElementId": sourceElementId,
            "status": status,
        }
        if footprint is not None:
            arguments["footprint"] = footprint
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
        if path is not None:
            arguments["path"] = _payload_dict(path)
        if retaining_edge is not None:
            arguments["retaining_edge"] = _payload_dict(retaining_edge)
        if planting_mass is not None:
            arguments["planting_mass"] = _payload_dict(planting_mass)
        if tree_proxy is not None:
            arguments["tree_proxy"] = _payload_dict(tree_proxy)

        return bridge_client.call_tool(
            "create_site_element",
            arguments,
            request_id=_request_id(ctx),
        )

    @mcp.tool(
        **tool_metadata(
            title="Set Entity Metadata",
            description=(
                "Update semantic metadata on an existing managed object in SketchUp."
                " Current support is limited to status updates for managed objects and"
                " structureCategory updates for managed structure objects."
            ),
            read_only=False,
        )
    )
    def set_entity_metadata(
        ctx: Context,
        target: TargetReference,
        set: MetadataPatch | None = None,
        clear: list[str] | None = None,
    ) -> dict[str, Any]:
        """Update the current semantic metadata mutation slice for a managed object."""
        arguments: dict[str, Any] = {"target": _payload_dict(target)}
        if set is not None:
            arguments["set"] = _payload_dict(set)
        if clear is not None:
            arguments["clear"] = clear

        return bridge_client.call_tool(
            "set_entity_metadata",
            arguments,
            request_id=_request_id(ctx),
        )


def _request_id(ctx: Context) -> Any:
    return getattr(ctx, "request_id", None)


def _payload_dict(payload: BaseModel | dict[str, Any]) -> dict[str, Any]:
    if isinstance(payload, BaseModel):
        return payload.model_dump(exclude_none=True)

    return dict(payload)
