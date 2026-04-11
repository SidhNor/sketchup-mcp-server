"""FastMCP server scaffold for the SketchUp extension.

The packaged server runs over stdio by default. Set
``SKETCHUP_MCP_TRANSPORT=http`` to expose an HTTP MCP endpoint instead.
"""

from __future__ import annotations

import os

from fastmcp import FastMCP

DEFAULT_HTTP_HOST = "127.0.0.1"
DEFAULT_HTTP_PORT = 8000
DEFAULT_TRANSPORT = "stdio"


def create_server() -> FastMCP:
    """Create the FastMCP server instance used by local tooling and the CLI."""
    server = FastMCP("SketchUp MCP Server")

    @server.tool
    def ping() -> str:
        """Basic health check for the server process."""
        return "pong"

    @server.tool
    def bridge_configuration() -> dict[str, str | int]:
        """Return the currently configured bridge transport and endpoint settings."""
        return {
            "transport": _transport(),
            "http_host": _http_host(),
            "http_port": _http_port(),
        }

    return server


def main() -> None:
    """Run the server using the configured transport.

    Stdio is the default transport so MCP clients can spawn this process
    directly. HTTP is opt-in via ``SKETCHUP_MCP_TRANSPORT=http``.
    """
    transport = _transport()

    if transport == "stdio":
        mcp.run()
        return

    if transport == "http":
        mcp.run(transport="http", host=_http_host(), port=_http_port())
        return

    raise ValueError(
        "Unsupported SKETCHUP_MCP_TRANSPORT value "
        f"{transport!r}. Expected 'stdio' or 'http'."
    )


def _transport() -> str:
    value = os.getenv("SKETCHUP_MCP_TRANSPORT", DEFAULT_TRANSPORT).strip().lower()
    return value or DEFAULT_TRANSPORT


def _http_host() -> str:
    return os.getenv("SKETCHUP_MCP_HTTP_HOST", DEFAULT_HTTP_HOST).strip() or DEFAULT_HTTP_HOST


def _http_port() -> int:
    value = os.getenv("SKETCHUP_MCP_HTTP_PORT", str(DEFAULT_HTTP_PORT)).strip()

    try:
        return int(value)
    except ValueError as exc:
        raise ValueError(
            f"Invalid SKETCHUP_MCP_HTTP_PORT value {value!r}; expected an integer."
        ) from exc


mcp = create_server()
