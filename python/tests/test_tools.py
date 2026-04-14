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
        "create_component",
        "delete_component",
        "transform_component",
        "get_selection",
        "set_material",
        "export_scene",
        "boolean_operation",
        "chamfer_edges",
        "fillet_edges",
        "create_mortise_tenon",
        "create_dovetail",
        "create_finger_joint",
        "eval_ruby",
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
