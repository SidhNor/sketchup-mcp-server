from __future__ import annotations

import json

import pytest

from ..test_bridge import FakeSocket, _sent_json, _settings
from ..test_support import require_module
from .support import contract_cases_by_id


def test_ping_request_matches_shared_contract_case() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    fake_socket = FakeSocket(
        responses=[b'{"jsonrpc":"2.0","id":7,"result":{"success":true,"message":"pong"}}']
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    result = client.ping(request_id=7)

    contract_case = contract_cases_by_id().get("ping_request")
    assert contract_case is not None
    assert _sent_json(fake_socket) == contract_case["request"]
    assert {"jsonrpc": "2.0", "id": 7, "result": result} == contract_case["response"]


def test_tools_call_request_matches_shared_contract_case() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    contract_case = contract_cases_by_id().get("tools_call_request")

    assert contract_case is not None

    fake_socket = FakeSocket(
        responses=[json.dumps(contract_case["response"]).encode("utf-8")]
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    result = client.call_tool(
        contract_case["request"]["params"]["name"],
        contract_case["request"]["params"]["arguments"],
        request_id=contract_case["request"]["id"],
    )

    assert _sent_json(fake_socket) == contract_case["request"]
    assert result == contract_case["response"]["result"]


def test_request_id_round_trip_matches_shared_contract_case() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    contract_case = contract_cases_by_id().get("request_id_round_trip")

    assert contract_case is not None

    fake_socket = FakeSocket(
        responses=[json.dumps(contract_case["response"]).encode("utf-8")]
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    result = client.call_tool(
        contract_case["request"]["params"]["name"],
        contract_case["request"]["params"]["arguments"],
        request_id=contract_case["request"]["id"],
    )

    assert _sent_json(fake_socket)["id"] == contract_case["response"]["id"]
    assert result == contract_case["response"]["result"]


def test_wave_ready_tool_call_round_trip_matches_shared_contract_case() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    contract_case = contract_cases_by_id().get("wave_ready_tool_call")

    assert contract_case is not None

    fake_socket = FakeSocket(
        responses=[json.dumps(contract_case["response"]).encode("utf-8")]
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    result = client.call_tool(
        contract_case["request"]["params"]["name"],
        contract_case["request"]["params"]["arguments"],
        request_id=contract_case["request"]["id"],
    )

    assert _sent_json(fake_socket) == contract_case["request"]
    assert result == contract_case["response"]["result"]


def test_operation_failure_maps_remote_error_from_shared_contract_case() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    contract_case = contract_cases_by_id().get("operation_failure")

    assert contract_case is not None

    fake_socket = FakeSocket(
        responses=[json.dumps(contract_case["response"]).encode("utf-8")]
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    with pytest.raises(
        bridge.BridgeRemoteError,
        match=contract_case["response"]["error"]["message"],
    ):
        client.call_tool(
            contract_case["request"]["params"]["name"],
            contract_case["request"]["params"]["arguments"],
            request_id=contract_case["request"]["id"],
        )


def test_find_entities_unique_matches_shared_contract_case() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    contract_case = contract_cases_by_id().get("find_entities_unique")

    assert contract_case is not None

    fake_socket = FakeSocket(
        responses=[json.dumps(contract_case["response"]).encode("utf-8")]
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    result = client.call_tool(
        contract_case["request"]["params"]["name"],
        contract_case["request"]["params"]["arguments"],
        request_id=contract_case["request"]["id"],
    )

    assert _sent_json(fake_socket) == contract_case["request"]
    assert result == contract_case["response"]["result"]


def test_find_entities_none_matches_shared_contract_case() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    contract_case = contract_cases_by_id().get("find_entities_none")

    assert contract_case is not None

    fake_socket = FakeSocket(
        responses=[json.dumps(contract_case["response"]).encode("utf-8")]
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    result = client.call_tool(
        contract_case["request"]["params"]["name"],
        contract_case["request"]["params"]["arguments"],
        request_id=contract_case["request"]["id"],
    )

    assert _sent_json(fake_socket) == contract_case["request"]
    assert result == contract_case["response"]["result"]


def test_find_entities_ambiguous_matches_shared_contract_case() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    contract_case = contract_cases_by_id().get("find_entities_ambiguous")

    assert contract_case is not None

    fake_socket = FakeSocket(
        responses=[json.dumps(contract_case["response"]).encode("utf-8")]
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    result = client.call_tool(
        contract_case["request"]["params"]["name"],
        contract_case["request"]["params"]["arguments"],
        request_id=contract_case["request"]["id"],
    )

    assert _sent_json(fake_socket) == contract_case["request"]
    assert result == contract_case["response"]["result"]


def test_find_entities_malformed_request_maps_remote_error_from_shared_contract_case() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    contract_case = contract_cases_by_id().get("find_entities_malformed_request")

    assert contract_case is not None

    fake_socket = FakeSocket(
        responses=[json.dumps(contract_case["response"]).encode("utf-8")]
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    with pytest.raises(
        bridge.BridgeRemoteError,
        match=contract_case["response"]["error"]["message"],
    ):
        client.call_tool(
            contract_case["request"]["params"]["name"],
            contract_case["request"]["params"]["arguments"],
            request_id=contract_case["request"]["id"],
        )


def test_sample_surface_z_hit_matches_shared_contract_case() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    contract_case = contract_cases_by_id().get("sample_surface_z_hit")

    assert contract_case is not None

    fake_socket = FakeSocket(
        responses=[json.dumps(contract_case["response"]).encode("utf-8")]
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    result = client.call_tool(
        contract_case["request"]["params"]["name"],
        contract_case["request"]["params"]["arguments"],
        request_id=contract_case["request"]["id"],
    )

    assert _sent_json(fake_socket) == contract_case["request"]
    assert result == contract_case["response"]["result"]


def test_sample_surface_z_miss_matches_shared_contract_case() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    contract_case = contract_cases_by_id().get("sample_surface_z_miss")

    assert contract_case is not None

    fake_socket = FakeSocket(
        responses=[json.dumps(contract_case["response"]).encode("utf-8")]
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    result = client.call_tool(
        contract_case["request"]["params"]["name"],
        contract_case["request"]["params"]["arguments"],
        request_id=contract_case["request"]["id"],
    )

    assert _sent_json(fake_socket) == contract_case["request"]
    assert result == contract_case["response"]["result"]


def test_sample_surface_z_ambiguous_matches_shared_contract_case() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    contract_case = contract_cases_by_id().get("sample_surface_z_ambiguous")

    assert contract_case is not None

    fake_socket = FakeSocket(
        responses=[json.dumps(contract_case["response"]).encode("utf-8")]
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    result = client.call_tool(
        contract_case["request"]["params"]["name"],
        contract_case["request"]["params"]["arguments"],
        request_id=contract_case["request"]["id"],
    )

    assert _sent_json(fake_socket) == contract_case["request"]
    assert result == contract_case["response"]["result"]


def test_sample_surface_z_mixed_results_matches_shared_contract_case() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    contract_case = contract_cases_by_id().get("sample_surface_z_mixed_results")

    assert contract_case is not None

    fake_socket = FakeSocket(
        responses=[json.dumps(contract_case["response"]).encode("utf-8")]
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    result = client.call_tool(
        contract_case["request"]["params"]["name"],
        contract_case["request"]["params"]["arguments"],
        request_id=contract_case["request"]["id"],
    )

    assert _sent_json(fake_socket) == contract_case["request"]
    assert result == contract_case["response"]["result"]


def test_sample_surface_z_ignore_targets_matches_shared_contract_case() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    contract_case = contract_cases_by_id().get("sample_surface_z_ignore_targets")

    assert contract_case is not None

    fake_socket = FakeSocket(
        responses=[json.dumps(contract_case["response"]).encode("utf-8")]
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    result = client.call_tool(
        contract_case["request"]["params"]["name"],
        contract_case["request"]["params"]["arguments"],
        request_id=contract_case["request"]["id"],
    )

    assert _sent_json(fake_socket) == contract_case["request"]
    assert result == contract_case["response"]["result"]


def test_sample_surface_z_unsupported_target_maps_remote_error_from_shared_contract_case() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    contract_case = contract_cases_by_id().get("sample_surface_z_unsupported_target")

    assert contract_case is not None

    fake_socket = FakeSocket(
        responses=[json.dumps(contract_case["response"]).encode("utf-8")]
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    with pytest.raises(
        bridge.BridgeRemoteError,
        match=contract_case["response"]["error"]["message"],
    ):
        client.call_tool(
            contract_case["request"]["params"]["name"],
            contract_case["request"]["params"]["arguments"],
            request_id=contract_case["request"]["id"],
        )


def test_create_site_element_structure_created_matches_shared_contract_case() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    contract_case = contract_cases_by_id().get("create_site_element_structure_created")

    assert contract_case is not None

    fake_socket = FakeSocket(
        responses=[json.dumps(contract_case["response"]).encode("utf-8")]
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    result = client.call_tool(
        contract_case["request"]["params"]["name"],
        contract_case["request"]["params"]["arguments"],
        request_id=contract_case["request"]["id"],
    )

    assert _sent_json(fake_socket) == contract_case["request"]
    assert result == contract_case["response"]["result"]


def test_create_site_element_pad_created_matches_shared_contract_case() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    contract_case = contract_cases_by_id().get("create_site_element_pad_created")

    assert contract_case is not None

    fake_socket = FakeSocket(
        responses=[json.dumps(contract_case["response"]).encode("utf-8")]
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    result = client.call_tool(
        contract_case["request"]["params"]["name"],
        contract_case["request"]["params"]["arguments"],
        request_id=contract_case["request"]["id"],
    )

    assert _sent_json(fake_socket) == contract_case["request"]
    assert result == contract_case["response"]["result"]


def test_create_site_element_path_created_matches_shared_contract_case() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    contract_case = contract_cases_by_id().get("create_site_element_path_created")

    assert contract_case is not None

    fake_socket = FakeSocket(
        responses=[json.dumps(contract_case["response"]).encode("utf-8")]
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    result = client.call_tool(
        contract_case["request"]["params"]["name"],
        contract_case["request"]["params"]["arguments"],
        request_id=contract_case["request"]["id"],
    )

    assert _sent_json(fake_socket) == contract_case["request"]
    assert result == contract_case["response"]["result"]


def test_create_site_element_retaining_edge_created_matches_shared_contract_case() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    contract_case = contract_cases_by_id().get("create_site_element_retaining_edge_created")

    assert contract_case is not None

    fake_socket = FakeSocket(
        responses=[json.dumps(contract_case["response"]).encode("utf-8")]
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    result = client.call_tool(
        contract_case["request"]["params"]["name"],
        contract_case["request"]["params"]["arguments"],
        request_id=contract_case["request"]["id"],
    )

    assert _sent_json(fake_socket) == contract_case["request"]
    assert result == contract_case["response"]["result"]


def test_create_site_element_planting_mass_created_matches_shared_contract_case() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    contract_case = contract_cases_by_id().get("create_site_element_planting_mass_created")

    assert contract_case is not None

    fake_socket = FakeSocket(
        responses=[json.dumps(contract_case["response"]).encode("utf-8")]
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    result = client.call_tool(
        contract_case["request"]["params"]["name"],
        contract_case["request"]["params"]["arguments"],
        request_id=contract_case["request"]["id"],
    )

    assert _sent_json(fake_socket) == contract_case["request"]
    assert result == contract_case["response"]["result"]


def test_create_site_element_tree_proxy_created_matches_shared_contract_case() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    contract_case = contract_cases_by_id().get("create_site_element_tree_proxy_created")

    assert contract_case is not None

    fake_socket = FakeSocket(
        responses=[json.dumps(contract_case["response"]).encode("utf-8")]
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    result = client.call_tool(
        contract_case["request"]["params"]["name"],
        contract_case["request"]["params"]["arguments"],
        request_id=contract_case["request"]["id"],
    )

    assert _sent_json(fake_socket) == contract_case["request"]
    assert result == contract_case["response"]["result"]


def test_create_site_element_missing_payload_refused_matches_shared_contract_case() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    contract_case = contract_cases_by_id().get("create_site_element_missing_payload_refused")

    assert contract_case is not None

    fake_socket = FakeSocket(
        responses=[json.dumps(contract_case["response"]).encode("utf-8")]
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    result = client.call_tool(
        contract_case["request"]["params"]["name"],
        contract_case["request"]["params"]["arguments"],
        request_id=contract_case["request"]["id"],
    )

    assert _sent_json(fake_socket) == contract_case["request"]
    assert result == contract_case["response"]["result"]


def test_create_site_element_contradictory_payload_refused_matches_shared_contract_case() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    contract_case = contract_cases_by_id().get("create_site_element_contradictory_payload_refused")

    assert contract_case is not None

    fake_socket = FakeSocket(
        responses=[json.dumps(contract_case["response"]).encode("utf-8")]
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    result = client.call_tool(
        contract_case["request"]["params"]["name"],
        contract_case["request"]["params"]["arguments"],
        request_id=contract_case["request"]["id"],
    )

    assert _sent_json(fake_socket) == contract_case["request"]
    assert result == contract_case["response"]["result"]


def test_create_site_element_unsupported_type_refused_matches_shared_contract_case() -> None:
    bridge = require_module("sketchup_mcp_server.bridge")
    contract_case = contract_cases_by_id().get("create_site_element_unsupported_type_refused")

    assert contract_case is not None

    fake_socket = FakeSocket(
        responses=[json.dumps(contract_case["response"]).encode("utf-8")]
    )
    client = bridge.BridgeClient(_settings(), socket_factory=lambda *_args, **_kwargs: fake_socket)

    result = client.call_tool(
        contract_case["request"]["params"]["name"],
        contract_case["request"]["params"]["arguments"],
        request_id=contract_case["request"]["id"],
    )

    assert _sent_json(fake_socket) == contract_case["request"]
    assert result == contract_case["response"]["result"]
