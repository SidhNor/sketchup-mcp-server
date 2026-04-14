"""Configuration helpers for the SketchUp MCP Python adapter."""

from __future__ import annotations

import logging
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping

DEFAULT_TRANSPORT = "stdio"
DEFAULT_HTTP_HOST = "127.0.0.1"
DEFAULT_HTTP_PORT = 8000
DEFAULT_SKETCHUP_HOST = "127.0.0.1"
DEFAULT_SKETCHUP_PORT = 9876
SUPPORTED_TRANSPORTS = {"stdio", "http"}

logger = logging.getLogger("SketchUpMCPServer")


@dataclass(frozen=True)
class ServerSettings:
    transport: str
    http_host: str
    http_port: int
    sketchup_host: str
    sketchup_port: int


def load_settings(env: Mapping[str, str] | None = None) -> ServerSettings:
    """Load immutable server settings from environment variables."""
    values = env if env is not None else os.environ

    transport = _transport(values)
    http_host = _http_host(values)
    http_port = _http_port(values)
    sketchup_port = _sketchup_port(values)
    sketchup_host = _sketchup_host(values)

    return ServerSettings(
        transport=transport,
        http_host=http_host,
        http_port=http_port,
        sketchup_host=sketchup_host,
        sketchup_port=sketchup_port,
    )


def detect_wsl_host() -> str | None:
    """Detect the Windows host address from a WSL environment."""
    try:
        for line in Path("/proc/net/route").read_text(encoding="utf-8", errors="ignore").splitlines()[1:]:
            fields = line.split()
            if len(fields) >= 3 and fields[1] == "00000000":
                gateway_hex = fields[2]
                octets = [str(int(gateway_hex[i : i + 2], 16)) for i in range(0, 8, 2)]
                return ".".join(reversed(octets))
    except OSError as exc:
        logger.warning("Could not read /proc/net/route for WSL host detection: %s", exc)

    try:
        for line in Path("/etc/resolv.conf").read_text(encoding="utf-8", errors="ignore").splitlines():
            if line.startswith("nameserver "):
                windows_host = line.split()[1].strip()
                if windows_host:
                    return windows_host
    except OSError as exc:
        logger.warning("Could not read /etc/resolv.conf for WSL host detection: %s", exc)

    return None


def _transport(env: Mapping[str, str]) -> str:
    value = env.get("SKETCHUP_MCP_TRANSPORT", DEFAULT_TRANSPORT).strip().lower() or DEFAULT_TRANSPORT
    if value not in SUPPORTED_TRANSPORTS:
        raise ValueError(
            f"Unsupported SKETCHUP_MCP_TRANSPORT value {value!r}. "
            "Expected 'stdio' or 'http'."
        )
    return value


def _http_host(env: Mapping[str, str]) -> str:
    return env.get("SKETCHUP_MCP_HTTP_HOST", DEFAULT_HTTP_HOST).strip() or DEFAULT_HTTP_HOST


def _http_port(env: Mapping[str, str]) -> int:
    value = env.get("SKETCHUP_MCP_HTTP_PORT", str(DEFAULT_HTTP_PORT)).strip()
    try:
        return int(value)
    except ValueError as exc:
        raise ValueError(
            f"Invalid SKETCHUP_MCP_HTTP_PORT value {value!r}; expected an integer."
        ) from exc


def _sketchup_port(env: Mapping[str, str]) -> int:
    value = env.get("SKETCHUP_PORT", str(DEFAULT_SKETCHUP_PORT)).strip()
    try:
        return int(value)
    except ValueError as exc:
        raise ValueError(
            f"Invalid SKETCHUP_PORT value {value!r}; expected an integer."
        ) from exc


def _sketchup_host(env: Mapping[str, str]) -> str:
    configured_host = env.get("SKETCHUP_HOST", "").strip()
    if configured_host:
        return configured_host

    if env.get("WSL_DISTRO_NAME"):
        windows_host = detect_wsl_host()
        if windows_host:
            return windows_host

    return DEFAULT_SKETCHUP_HOST
