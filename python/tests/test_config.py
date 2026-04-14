from __future__ import annotations

import pytest

from .test_support import require_module


def _load_settings():
    config = require_module("sketchup_mcp_server.config")
    return config, config.load_settings


def test_load_settings_defaults_to_stdio_and_localhost_bridge() -> None:
    config, load_settings = _load_settings()

    settings = load_settings({})

    assert settings == config.ServerSettings(
        transport="stdio",
        http_host="127.0.0.1",
        http_port=8000,
        sketchup_host="127.0.0.1",
        sketchup_port=9876,
    )


def test_load_settings_reads_http_host_and_port_from_env() -> None:
    _, load_settings = _load_settings()

    settings = load_settings(
        {
            "SKETCHUP_MCP_TRANSPORT": " HTTP ",
            "SKETCHUP_MCP_HTTP_HOST": "0.0.0.0",
            "SKETCHUP_MCP_HTTP_PORT": "8123",
        }
    )

    assert settings.transport == "http"
    assert settings.http_host == "0.0.0.0"
    assert settings.http_port == 8123


def test_load_settings_rejects_invalid_http_port() -> None:
    _, load_settings = _load_settings()

    with pytest.raises(ValueError, match="SKETCHUP_MCP_HTTP_PORT"):
        load_settings({"SKETCHUP_MCP_HTTP_PORT": "not-a-port"})


def test_load_settings_rejects_unsupported_transport() -> None:
    _, load_settings = _load_settings()

    with pytest.raises(ValueError, match="SKETCHUP_MCP_TRANSPORT"):
        load_settings({"SKETCHUP_MCP_TRANSPORT": "tcp"})


def test_load_settings_prefers_explicit_sketchup_host_override() -> None:
    _, load_settings = _load_settings()

    settings = load_settings(
        {
            "SKETCHUP_HOST": "192.168.1.77",
            "SKETCHUP_PORT": "9988",
            "WSL_DISTRO_NAME": "Ubuntu",
        }
    )

    assert settings.sketchup_host == "192.168.1.77"
    assert settings.sketchup_port == 9988


def test_load_settings_uses_wsl_detection_when_host_not_set(monkeypatch: pytest.MonkeyPatch) -> None:
    config, load_settings = _load_settings()
    monkeypatch.setattr(config, "detect_wsl_host", lambda: "172.28.96.1")

    settings = load_settings({"WSL_DISTRO_NAME": "Ubuntu"})

    assert settings.sketchup_host == "172.28.96.1"
