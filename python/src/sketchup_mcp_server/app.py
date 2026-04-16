"""FastMCP app composition for the SketchUp MCP server."""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastmcp import FastMCP

from .bridge import BridgeClient, BridgeError
from .config import ServerSettings, load_settings
from .tools import register_all_tools
from .version import __version__

VERSION = __version__

logger = logging.getLogger("SketchUpMCPServer")


def create_server(
    *,
    settings: ServerSettings | None = None,
    bridge_client: BridgeClient | None = None,
) -> FastMCP:
    """Create the FastMCP server instance."""
    resolved_settings = settings or load_settings()
    resolved_bridge = bridge_client or BridgeClient(resolved_settings)

    mcp = FastMCP(
        "SketchUp MCP Server",
        version=VERSION,
        instructions=(
            "Compatibility surface for SketchUp integration through a local "
            "Ruby socket bridge."
        ),
        lifespan=server_lifespan(resolved_bridge),
    )
    register_all_tools(mcp, settings=resolved_settings, bridge_client=resolved_bridge)
    return mcp


def server_lifespan(bridge_client: BridgeClient):
    """Build the app lifespan manager around a shared bridge client."""

    @asynccontextmanager
    async def lifespan(_server: FastMCP):
        logger.info("SketchUp MCP server starting up")
        try:
            try:
                bridge_client.ping(request_id=0)
                logger.info("SketchUp bridge responded to startup ping")
            except BridgeError as exc:
                logger.warning("SketchUp bridge not reachable on startup: %s", exc)
            yield {}
        finally:
            bridge_client.disconnect()
            logger.info("SketchUp MCP server shut down")

    return lifespan


def main(
    *,
    settings: ServerSettings | None = None,
    server: FastMCP | None = None,
) -> None:
    """Run the MCP server with the configured transport."""
    resolved_settings = settings or load_settings()
    resolved_server = server or create_server(settings=resolved_settings)

    if resolved_settings.transport == "stdio":
        resolved_server.run()
        return

    if resolved_settings.transport == "http":
        resolved_server.run(
            transport="http",
            host=resolved_settings.http_host,
            port=resolved_settings.http_port,
        )
        return

    raise ValueError(
        f"Unsupported SKETCHUP_MCP_TRANSPORT value {resolved_settings.transport!r}. "
        "Expected 'stdio' or 'http'."
    )
