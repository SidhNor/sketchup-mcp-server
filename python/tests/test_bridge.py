from __future__ import annotations

import json
from dataclasses import dataclass, field
from typing import Any

import pytest

from .test_support import require_module


@dataclass
class FakeSocket:
    responses: list[bytes] = field(default_factory=list)
    sent_packets: list[bytes] = field(default_factory=list)
    timeout: float | None = None
    connected_to: tuple[str, int] | None = None
    closed: bool = False

    def settimeout(self, timeout: float) -> None:
        self.timeout = timeout

    def connect(self, endpoint: tuple[str, int]) -> None:
        self.connected_to = endpoint

    def sendall(self, data: bytes) -> None:
        self.sent_packets.append(data)

    def recv(self, _buffer_size: int) -> bytes:
        if self.responses:
            return self.responses.pop(0)
        return b""

    def close(self) -> None:
        self.closed = True


def _settings():
    config = require_module("sketchup_mcp_server.config")
    return config.ServerSettings(
        transport="stdio",
        http_host="127.0.0.1",
        http_port=8000,
        sketchup_host="127.0.0.1",
        sketchup_port=9876,
    )


def _sent_json(fake_socket: FakeSocket) -> dict[str, Any]:
    assert fake_socket.sent_packets
    return json.loads(fake_socket.sent_packets[0].decode("utf-8"))


def test_ping_request_shaping() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    fake_socket = FakeSocket(
        responses=[b'{"jsonrpc":"2.0","id":7,"result":{"success":true}}']
    )

    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)
    client.ping(request_id=7)

    assert _sent_json(fake_socket) == {
        "jsonrpc": "2.0",
        "method": "ping",
        "params": {},
        "id": 7,
    }


def test_call_tool_request_shaping() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    fake_socket = FakeSocket(
        responses=[b'{"jsonrpc":"2.0","id":"req-9","result":{"ok":true}}']
    )

    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)
    client.call_tool("get_scene_info", {"entity_limit": 3}, request_id="req-9")

    assert _sent_json(fake_socket) == {
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {"name": "get_scene_info", "arguments": {"entity_limit": 3}},
        "id": "req-9",
    }


def test_call_tool_returns_result_payload() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    fake_socket = FakeSocket(
        responses=[b'{"jsonrpc":"2.0","id":"req-2","result":{"entities":[]}}']
    )

    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    assert client.call_tool("list_entities", {"limit": 2}, request_id="req-2") == {"entities": []}


def test_call_tool_preserves_request_id() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    fake_socket = FakeSocket(
        responses=[b'{"jsonrpc":"2.0","id":"abc-123","result":{"ok":true}}']
    )

    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)
    client.call_tool("eval_ruby", {"code": "1 + 1"}, request_id="abc-123")

    assert _sent_json(fake_socket)["id"] == "abc-123"


def test_call_tool_maps_remote_error_payload() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    fake_socket = FakeSocket(
        responses=[
            b'{"jsonrpc":"2.0","id":"req-1","error":{"code":-32001,"message":"No entity with id 42"}}'
        ]
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    with pytest.raises(bridge.BridgeRemoteError, match="No entity with id 42"):
        client.call_tool("get_entity_info", {"id": "42"}, request_id="req-1")


def test_call_tool_raises_for_closed_socket_without_response() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: FakeSocket())

    with pytest.raises(bridge.BridgeProtocolError, match="without a response"):
        client.call_tool("ping", request_id="req-empty")


def test_call_tool_raises_for_incomplete_json_response() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    fake_socket = FakeSocket(responses=[b'{"jsonrpc":"2.0","id":"req-4"', b""])
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    with pytest.raises(bridge.BridgeProtocolError, match="Incomplete JSON response"):
        client.call_tool("ping", request_id="req-4")


def test_call_tool_raises_for_malformed_json_response() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    fake_socket = FakeSocket(responses=[b"this-is-not-json\n"])
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    with pytest.raises(bridge.BridgeProtocolError, match="Malformed JSON response"):
        client.call_tool("ping", request_id="req-bad-json")
