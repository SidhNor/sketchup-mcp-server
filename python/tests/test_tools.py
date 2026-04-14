from __future__ import annotations

import asyncio

from fastmcp import FastMCP

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
    module = require_module(module_name)
    mcp = FastMCP("test")
    bridge_client = RecordingBridgeClient(result={"ok": True})
    module.register_tools(mcp, settings=_settings(), bridge_client=bridge_client)
    tool = asyncio.run(mcp.get_tool(tool_name))
    return tool.fn, bridge_client


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
