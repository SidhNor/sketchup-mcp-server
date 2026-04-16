from __future__ import annotations

import asyncio

from fastmcp import FastMCP
from fastmcp.utilities.json_schema import dereference_refs

from .test_support import DummyContext, RecordingBridgeClient, require_module


def _settings():
    config = require_module("sketchup_mcp_server.config")
    return config.ServerSettings(
        transport="http",
        http_host="0.0.0.0",
        http_port=8123,
        sketchup_host="127.0.0.1",
        sketchup_port=9876,
    )


def _registered_tool(module_name: str, tool_name: str):
    tool, bridge_client = _registered_tool_definition(module_name, tool_name)
    return tool.fn, bridge_client


def _registered_tool_definition(module_name: str, tool_name: str):
    module = require_module(module_name)
    mcp = FastMCP("test")
    bridge_client = RecordingBridgeClient(result={"ok": True})
    module.register_tools(mcp, settings=_settings(), bridge_client=bridge_client)
    return asyncio.run(mcp.get_tool(tool_name)), bridge_client


def test_register_all_tools_exposes_the_expected_names() -> None:
    tools_module = require_module("sketchup_mcp_server.tools")
    mcp = FastMCP("test")

    tools_module.register_all_tools(
        mcp,
        settings=_settings(),
        bridge_client=RecordingBridgeClient(),
    )

    tool_names = asyncio.run(mcp.list_tools())

    assert [tool.name for tool in tool_names] == [
        "ping",
        "bridge_configuration",
        "get_scene_info",
        "list_entities",
        "find_entities",
        "sample_surface_z",
        "get_entity_info",
        "create_site_element",
        "set_entity_metadata",
        "create_component",
        "delete_component",
        "transform_component",
        "get_selection",
        "set_material",
        "export_scene",
        "boolean_operation",
        "chamfer_edges",
        "fillet_edges",
        "eval_ruby",
    ]


def test_create_site_element_exposes_a_typed_semantic_request_schema() -> None:
    tool, _bridge_client = _registered_tool_definition(
        "sketchup_mcp_server.tools.semantic",
        "create_site_element",
    )

    schema = dereference_refs(tool.parameters)

    assert schema["type"] == "object"
    assert schema["required"] == ["elementType", "sourceElementId", "status"]
    assert set(schema["properties"]) >= {
        "elementType",
        "sourceElementId",
        "status",
        "footprint",
        "elevation",
        "height",
        "structureCategory",
        "thickness",
        "name",
        "tag",
        "material",
        "path",
        "retaining_edge",
        "planting_mass",
        "tree_proxy",
    }


def test_create_site_element_exposes_explicit_current_phase_metadata() -> None:
    tool, _bridge_client = _registered_tool_definition(
        "sketchup_mcp_server.tools.semantic",
        "create_site_element",
    )

    assert tool.title == "Create Semantic Site Element"
    assert (
        tool.description
        == "Create a managed semantic site element in SketchUp. Current support is"
        " limited to structure, pad, path, retaining_edge, planting_mass, and"
        " tree_proxy creation."
    )
    assert tool.annotations is not None
    assert tool.annotations.readOnlyHint is False
    assert tool.annotations.destructiveHint is False


def test_create_site_element_passthrough_preserves_semantic_shape_and_request_id() -> None:
    fn, bridge_client = _registered_tool(
        "sketchup_mcp_server.tools.semantic",
        "create_site_element",
    )

    fn(
        DummyContext("semantic-1"),
        elementType="path",
        sourceElementId="main-walk-001",
        status="proposed",
        path={
            "centerline": [[0.0, 0.0], [4.0, 1.0], [8.0, 1.0]],
            "width": 1.6,
            "elevation": 0.0,
            "thickness": 0.1,
        },
        name="Main Walk",
        tag="Proposed",
        material="Gravel",
    )

    assert bridge_client.calls == [
        {
            "kind": "tool",
            "name": "create_site_element",
            "arguments": {
                "elementType": "path",
                "sourceElementId": "main-walk-001",
                "status": "proposed",
                "path": {
                    "centerline": [[0.0, 0.0], [4.0, 1.0], [8.0, 1.0]],
                    "width": 1.6,
                    "elevation": 0.0,
                    "thickness": 0.1,
                },
                "name": "Main Walk",
                "tag": "Proposed",
                "material": "Gravel",
            },
            "request_id": "semantic-1",
        }
    ]


def test_set_entity_metadata_exposes_a_typed_semantic_mutation_schema() -> None:
    tool, _bridge_client = _registered_tool_definition(
        "sketchup_mcp_server.tools.semantic",
        "set_entity_metadata",
    )

    schema = dereference_refs(tool.parameters)

    assert schema["type"] == "object"
    assert schema["required"] == ["target"]
    assert set(schema["properties"]) >= {"target", "set", "clear"}
    assert schema["properties"]["target"] == {
        "type": "object",
        "properties": {
            "sourceElementId": {
                "anyOf": [{"type": "string"}, {"type": "null"}],
                "default": None,
            },
            "persistentId": {
                "anyOf": [{"type": "string"}, {"type": "null"}],
                "default": None,
            },
            "entityId": {
                "anyOf": [{"type": "string"}, {"type": "null"}],
                "default": None,
            },
        },
    }
    assert schema["properties"]["set"] == {
        "anyOf": [
            {
                "type": "object",
                "properties": {
                    "status": {
                        "anyOf": [{"type": "string"}, {"type": "null"}],
                        "default": None,
                    },
                    "structureCategory": {
                        "anyOf": [{"type": "string"}, {"type": "null"}],
                        "default": None,
                    },
                },
            },
            {"type": "null"},
        ],
        "default": None,
    }
    assert schema["properties"]["clear"] == {
        "anyOf": [{"items": {"type": "string"}, "type": "array"}, {"type": "null"}],
        "default": None,
    }


def test_set_entity_metadata_exposes_explicit_semantic_mutation_metadata() -> None:
    tool, _bridge_client = _registered_tool_definition(
        "sketchup_mcp_server.tools.semantic",
        "set_entity_metadata",
    )

    assert tool.title == "Set Entity Metadata"
    assert (
        tool.description
        == "Update semantic metadata on an existing managed object in SketchUp."
        " Current support is limited to status updates for managed objects and"
        " structureCategory updates for managed structure objects."
    )
    assert tool.annotations is not None
    assert tool.annotations.readOnlyHint is False
    assert tool.annotations.destructiveHint is False


def test_set_entity_metadata_passthrough_preserves_request_shape_and_request_id() -> None:
    fn, bridge_client = _registered_tool(
        "sketchup_mcp_server.tools.semantic",
        "set_entity_metadata",
    )

    fn(
        DummyContext("semantic-2"),
        target={"sourceElementId": "house-extension-001"},
        set={"status": "existing"},
    )

    assert bridge_client.calls == [
        {
            "kind": "tool",
            "name": "set_entity_metadata",
            "arguments": {
                "target": {"sourceElementId": "house-extension-001"},
                "set": {"status": "existing"},
            },
            "request_id": "semantic-2",
        }
    ]


def test_scene_tool_passthrough_uses_shared_bridge_client() -> None:
    fn, bridge_client = _registered_tool("sketchup_mcp_server.tools.scene", "get_scene_info")

    fn(DummyContext("scene-1"), entity_limit=7)

    assert bridge_client.calls == [
        {
            "kind": "tool",
            "name": "get_scene_info",
            "arguments": {"entity_limit": 7},
            "request_id": "scene-1",
        }
    ]


def test_get_scene_info_exposes_explicit_metadata() -> None:
    tool, _bridge_client = _registered_tool_definition(
        "sketchup_mcp_server.tools.scene",
        "get_scene_info",
    )

    assert tool.title == "Get Scene Summary"
    assert (
        tool.description
        == "Get a structured summary of the current SketchUp scene for broad grounding"
        " before more targeted inspection tools are used."
    )
    assert tool.annotations is not None
    assert tool.annotations.readOnlyHint is True
    assert tool.annotations.destructiveHint is False


def test_list_entities_exposes_explicit_metadata() -> None:
    tool, _bridge_client = _registered_tool_definition(
        "sketchup_mcp_server.tools.scene",
        "list_entities",
    )

    assert tool.title == "List Top-Level Entities"
    assert (
        tool.description
        == "List top-level SketchUp model entities with an optional limit and optional"
        " hidden-entity inclusion."
    )
    assert tool.annotations is not None
    assert tool.annotations.readOnlyHint is True
    assert tool.annotations.destructiveHint is False


def test_find_entities_exposes_a_typed_nested_query_schema() -> None:
    tool, _bridge_client = _registered_tool_definition(
        "sketchup_mcp_server.tools.scene",
        "find_entities",
    )

    schema = dereference_refs(tool.parameters)

    assert schema["type"] == "object"
    assert "query" in schema["required"]
    assert schema["properties"]["query"] == {
        "type": "object",
        "properties": {
            "sourceElementId": {
                "anyOf": [{"type": "string"}, {"type": "null"}],
                "default": None,
            },
            "persistentId": {
                "anyOf": [{"type": "string"}, {"type": "null"}],
                "default": None,
            },
            "entityId": {
                "anyOf": [{"type": "string"}, {"type": "null"}],
                "default": None,
            },
            "name": {"anyOf": [{"type": "string"}, {"type": "null"}], "default": None},
            "tag": {"anyOf": [{"type": "string"}, {"type": "null"}], "default": None},
            "material": {"anyOf": [{"type": "string"}, {"type": "null"}], "default": None},
        },
    }


def test_find_entities_exposes_explicit_mvp_metadata() -> None:
    tool, _bridge_client = _registered_tool_definition(
        "sketchup_mcp_server.tools.scene",
        "find_entities",
    )

    assert tool.title == "Find Scene Entities"
    assert (
        tool.description
        == "Find scene entities using the supported MVP targeting fields and return"
        " explicit match summaries. Supports identity references, name, tag, and"
        " material only."
    )
    assert tool.annotations is not None
    assert tool.annotations.readOnlyHint is True
    assert tool.annotations.destructiveHint is False


def test_find_entities_passthrough_preserves_query_shape_and_request_id() -> None:
    scene_module = require_module("sketchup_mcp_server.tools.scene")
    fn, bridge_client = _registered_tool("sketchup_mcp_server.tools.scene", "find_entities")

    fn(
        DummyContext("find-1"),
        query=scene_module.FindEntitiesQuery(persistentId="1001", tag="Trees"),
    )

    assert bridge_client.calls == [
        {
            "kind": "tool",
            "name": "find_entities",
            "arguments": {"query": {"persistentId": "1001", "tag": "Trees"}},
            "request_id": "find-1",
        }
    ]


def test_sample_surface_z_exposes_typed_nested_schema() -> None:
    tool, _bridge_client = _registered_tool_definition(
        "sketchup_mcp_server.tools.scene",
        "sample_surface_z",
    )

    schema = dereference_refs(tool.parameters)

    assert schema["type"] == "object"
    assert schema["required"] == ["target", "samplePoints"]
    assert schema["properties"]["target"] == {
        "type": "object",
        "properties": {
            "sourceElementId": {
                "anyOf": [{"type": "string"}, {"type": "null"}],
                "default": None,
            },
            "persistentId": {
                "anyOf": [{"type": "string"}, {"type": "null"}],
                "default": None,
            },
            "entityId": {
                "anyOf": [{"type": "string"}, {"type": "null"}],
                "default": None,
            },
        },
    }
    assert schema["properties"]["samplePoints"] == {
        "type": "array",
        "items": {
            "type": "object",
            "properties": {"x": {"type": "number"}, "y": {"type": "number"}},
            "required": ["x", "y"],
        },
    }
    assert schema["properties"]["ignoreTargets"] == {
        "anyOf": [
            {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "sourceElementId": {
                            "anyOf": [{"type": "string"}, {"type": "null"}],
                            "default": None,
                        },
                        "persistentId": {
                            "anyOf": [{"type": "string"}, {"type": "null"}],
                            "default": None,
                        },
                        "entityId": {
                            "anyOf": [{"type": "string"}, {"type": "null"}],
                            "default": None,
                        },
                    },
                },
            },
            {"type": "null"},
        ],
        "default": None,
    }
    assert schema["properties"]["visibleOnly"] == {"type": "boolean", "default": True}


def test_sample_surface_z_exposes_explicit_targeted_metadata() -> None:
    tool, _bridge_client = _registered_tool_definition(
        "sketchup_mcp_server.tools.scene",
        "sample_surface_z",
    )

    assert tool.title == "Sample Target Surface Elevation"
    assert (
        tool.description
        == "Sample world-space surface elevation from an explicit target at one or more"
        " XY points in meters. Callers must provide the target and sample points; this"
        " is not broad scene discovery."
    )
    assert tool.annotations is not None
    assert tool.annotations.readOnlyHint is True
    assert tool.annotations.destructiveHint is False


def test_sample_surface_z_passthrough_preserves_nested_shape_and_request_id() -> None:
    scene_module = require_module("sketchup_mcp_server.tools.scene")
    fn, bridge_client = _registered_tool("sketchup_mcp_server.tools.scene", "sample_surface_z")

    fn(
        DummyContext("sample-1"),
        target=scene_module.SampleSurfaceTarget(persistentId="4006"),
        samplePoints=[scene_module.SampleSurfacePoint(x=105.0, y=5.0)],
        ignoreTargets=[scene_module.SampleSurfaceTarget(persistentId="4007")],
        visibleOnly=True,
    )

    assert bridge_client.calls == [
        {
            "kind": "tool",
            "name": "sample_surface_z",
            "arguments": {
                "target": {"persistentId": "4006"},
                "samplePoints": [{"x": 105.0, "y": 5.0}],
                "ignoreTargets": [{"persistentId": "4007"}],
                "visibleOnly": True,
            },
            "request_id": "sample-1",
        }
    ]


def test_get_entity_info_exposes_explicit_metadata() -> None:
    tool, _bridge_client = _registered_tool_definition(
        "sketchup_mcp_server.tools.scene",
        "get_entity_info",
    )

    assert tool.title == "Get Entity Information"
    assert tool.description == "Get structured information for a specific SketchUp entity by id."
    assert tool.annotations is not None
    assert tool.annotations.readOnlyHint is True
    assert tool.annotations.destructiveHint is False


def test_modeling_tool_omits_none_optional_arguments() -> None:
    fn, bridge_client = _registered_tool(
        "sketchup_mcp_server.tools.modeling",
        "transform_component",
    )

    fn(
        DummyContext("move-1"),
        id="component-1",
        position=[1, 2, 3],
        rotation=None,
        scale=None,
    )

    assert bridge_client.calls == [
        {
            "kind": "tool",
            "name": "transform_component",
            "arguments": {"id": "component-1", "position": [1, 2, 3]},
            "request_id": "move-1",
        }
    ]


def test_developer_tool_passthrough_preserves_code() -> None:
    fn, bridge_client = _registered_tool("sketchup_mcp_server.tools.developer", "eval_ruby")

    fn(DummyContext("dev-1"), code="1 + 1")

    assert bridge_client.calls == [
        {
            "kind": "tool",
            "name": "eval_ruby",
            "arguments": {"code": "1 + 1"},
            "request_id": "dev-1",
        }
    ]


def test_bridge_configuration_uses_shared_settings() -> None:
    fn, _bridge_client = _registered_tool(
        "sketchup_mcp_server.tools.platform",
        "bridge_configuration",
    )

    result = fn()

    assert result == {
        "mcp_transport": "http",
        "http_host": "0.0.0.0",
        "http_port": 8123,
        "sketchup_host": "127.0.0.1",
        "sketchup_port": 9876,
    }
