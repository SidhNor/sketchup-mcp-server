from __future__ import annotations

import asyncio

import pytest

from .test_support import RecordingBridgeClient, require_module


class RecordingServer:
    def __init__(self) -> None:
        self.calls: list[dict[str, object]] = []

    def run(self, **kwargs: object) -> None:
        self.calls.append(kwargs)


def test_create_server_registers_expected_tool_names() -> None:
    app = require_module("sketchup_mcp_server.app")
    config = require_module("sketchup_mcp_server.config")

    server = app.create_server(
        settings=config.load_settings({}),
        bridge_client=RecordingBridgeClient(),
    )

    tool_names = asyncio.run(server.list_tools())

    assert [tool.name for tool in tool_names] == [
        "ping",
        "bridge_configuration",
        "get_scene_info",
        "list_entities",
        "find_entities",
        "sample_surface_z",
        "get_entity_info",
        "create_site_element",
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


def test_server_lifespan_startup_ping_is_non_fatal() -> None:
    app = require_module("sketchup_mcp_server.app")
    bridge = require_module("sketchup_mcp_server.bridge")
    client = RecordingBridgeClient(ping_result=bridge.BridgeTransportError("connection refused"))

    async def exercise() -> None:
        async with app.server_lifespan(client)(object()):
            pass

    asyncio.run(exercise())

    assert client.calls == [{"kind": "ping", "request_id": 0}]


def test_server_lifespan_disconnects_bridge_on_shutdown() -> None:
    app = require_module("sketchup_mcp_server.app")
    client = RecordingBridgeClient()

    async def exercise() -> None:
        async with app.server_lifespan(client)(object()):
            pass

    asyncio.run(exercise())

    assert client.disconnected is True


def test_main_runs_stdio_transport_by_default() -> None:
    app = require_module("sketchup_mcp_server.app")
    config = require_module("sketchup_mcp_server.config")
    server = RecordingServer()

    app.main(settings=config.load_settings({}), server=server)

    assert server.calls == [{}]


def test_main_runs_http_transport_when_configured() -> None:
    app = require_module("sketchup_mcp_server.app")
    config = require_module("sketchup_mcp_server.config")
    server = RecordingServer()

    app.main(
        settings=config.load_settings(
            {
                "SKETCHUP_MCP_TRANSPORT": "http",
                "SKETCHUP_MCP_HTTP_HOST": "0.0.0.0",
                "SKETCHUP_MCP_HTTP_PORT": "9100",
            }
        ),
        server=server,
    )

    assert server.calls == [{"transport": "http", "host": "0.0.0.0", "port": 9100}]


def test_main_rejects_unsupported_transport() -> None:
    app = require_module("sketchup_mcp_server.app")
    config = require_module("sketchup_mcp_server.config")

    with pytest.raises(ValueError, match="SKETCHUP_MCP_TRANSPORT"):
        app.main(
            settings=config.ServerSettings(
                transport="tcp",
                http_host="127.0.0.1",
                http_port=8000,
                sketchup_host="127.0.0.1",
                sketchup_port=9876,
            ),
            server=RecordingServer(),
        )


def test_server_module_remains_a_compatibility_surface() -> None:
    server_module = require_module("sketchup_mcp_server.server")
    app = require_module("sketchup_mcp_server.app")

    assert server_module.create_server is app.create_server
    assert server_module.main is app.main
    assert server_module.mcp is not None
