"""FastMCP server for the SketchUp extension.

The MCP transport is stdio by default. The Python process forwards tool
requests to the SketchUp Ruby extension over a local TCP socket bridge.
"""

from __future__ import annotations

import json
import logging
import os
import socket
from contextlib import asynccontextmanager
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from fastmcp import Context, FastMCP

from .version import __version__

VERSION = __version__
DEFAULT_TRANSPORT = "stdio"
DEFAULT_HTTP_HOST = "127.0.0.1"
DEFAULT_HTTP_PORT = 8000
DEFAULT_SKETCHUP_PORT = 9876
DEFAULT_SKETCHUP_HOST = "127.0.0.1"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("SketchUpMCPServer")


@dataclass
class SketchupConnection:
    """Short-lived socket client for the SketchUp extension bridge."""

    host: str
    port: int
    sock: socket.socket | None = None

    def connect(self) -> None:
        self.disconnect()
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.settimeout(15.0)
        self.sock.connect((self.host, self.port))
        logger.info("Connected to SketchUp at %s:%s", self.host, self.port)

    def disconnect(self) -> None:
        if self.sock is None:
            return

        try:
            self.sock.close()
        except OSError as exc:
            logger.warning("Error disconnecting from SketchUp: %s", exc)
        finally:
            self.sock = None

    def send_command(
        self,
        method: str,
        params: dict[str, Any] | None = None,
        request_id: Any = None,
    ) -> dict[str, Any]:
        """Send a JSON-RPC request to SketchUp and return the result payload."""
        self.connect()

        try:
            request = self._build_request(method, params or {}, request_id)
            request_bytes = json.dumps(request).encode("utf-8") + b"\n"
            logger.info("Sending request to SketchUp: %s", request["method"])
            self.sock.sendall(request_bytes)

            response = json.loads(self._receive_full_response().decode("utf-8"))
            logger.info("Received response from SketchUp for request %r", request_id)

            if "error" in response:
                message = response["error"].get("message", "Unknown SketchUp bridge error")
                raise RuntimeError(message)

            return response.get("result", {})
        finally:
            self.disconnect()

    def _build_request(
        self,
        method: str,
        params: dict[str, Any],
        request_id: Any,
    ) -> dict[str, Any]:
        if method == "ping":
            return {
                "jsonrpc": "2.0",
                "method": "ping",
                "params": params,
                "id": request_id,
            }

        if method == "tools/call" and "name" in params:
            return {
                "jsonrpc": "2.0",
                "method": "tools/call",
                "params": params,
                "id": request_id,
            }

        return {
            "jsonrpc": "2.0",
            "method": "tools/call",
            "params": {
                "name": method,
                "arguments": params,
            },
            "id": request_id,
        }

    def _receive_full_response(self, buffer_size: int = 8192) -> bytes:
        assert self.sock is not None
        chunks: list[bytes] = []

        while True:
            chunk = self.sock.recv(buffer_size)
            if not chunk:
                break

            chunks.append(chunk)

            try:
                data = b"".join(chunks)
                json.loads(data.decode("utf-8"))
                return data
            except json.JSONDecodeError:
                continue

        if not chunks:
            raise RuntimeError("SketchUp bridge closed the connection without a response.")

        raise RuntimeError("Incomplete JSON response received from the SketchUp bridge.")


_sketchup_connection: SketchupConnection | None = None


def get_sketchup_endpoint() -> tuple[str, int]:
    """Resolve the host/port for the SketchUp socket bridge."""
    port = int(os.getenv("SKETCHUP_PORT", str(DEFAULT_SKETCHUP_PORT)))
    configured_host = os.getenv("SKETCHUP_HOST")
    if configured_host:
        return configured_host, port

    if os.getenv("WSL_DISTRO_NAME"):
        windows_host = _detect_wsl_host()
        if windows_host:
            return windows_host, port

    return DEFAULT_SKETCHUP_HOST, port


def get_sketchup_connection() -> SketchupConnection:
    """Get or create the SketchUp bridge connection manager."""
    global _sketchup_connection

    if _sketchup_connection is None:
        host, port = get_sketchup_endpoint()
        logger.info("Using SketchUp bridge endpoint %s:%s", host, port)
        _sketchup_connection = SketchupConnection(host=host, port=port)

    return _sketchup_connection


def create_server() -> FastMCP:
    """Create the FastMCP server instance."""
    return FastMCP(
        "SketchUp MCP Server",
        version=VERSION,
        instructions="SketchUp integration through a local Ruby socket bridge.",
        lifespan=server_lifespan,
    )


@asynccontextmanager
async def server_lifespan(_server: FastMCP):
    """Log startup and attempt a non-fatal bridge health check."""
    logger.info("SketchUp MCP server starting up")
    try:
        try:
            get_sketchup_connection().send_command("ping", {}, request_id=0)
            logger.info("SketchUp bridge responded to startup ping")
        except Exception as exc:  # noqa: BLE001
            logger.warning("SketchUp bridge not reachable on startup: %s", exc)
        yield {}
    finally:
        global _sketchup_connection
        if _sketchup_connection is not None:
            _sketchup_connection.disconnect()
            _sketchup_connection = None
        logger.info("SketchUp MCP server shut down")


def main() -> None:
    """Run the MCP server using the configured transport."""
    transport = _transport()

    if transport == "stdio":
        mcp.run()
        return

    if transport == "http":
        mcp.run(transport="http", host=_http_host(), port=_http_port())
        return

    raise ValueError(
        f"Unsupported SKETCHUP_MCP_TRANSPORT value {transport!r}. "
        "Expected 'stdio' or 'http'."
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


def _detect_wsl_host() -> str | None:
    try:
        for line in Path("/proc/net/route").read_text(encoding="utf-8", errors="ignore").splitlines()[
            1:
        ]:
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


def _request_id(ctx: Context) -> Any:
    return getattr(ctx, "request_id", None)


def _call_bridge_tool(ctx: Context, name: str, arguments: dict[str, Any] | None = None) -> dict[str, Any]:
    return get_sketchup_connection().send_command(
        method="tools/call",
        params={
            "name": name,
            "arguments": arguments or {},
        },
        request_id=_request_id(ctx),
    )


mcp = create_server()


@mcp.tool
def ping() -> dict[str, Any]:
    """Basic health check for the Python MCP server."""
    host, port = get_sketchup_endpoint()
    return {
        "success": True,
        "message": "pong",
        "transport": _transport(),
        "sketchup_host": host,
        "sketchup_port": port,
    }


@mcp.tool
def bridge_configuration() -> dict[str, Any]:
    """Return the current MCP transport and SketchUp bridge endpoint."""
    host, port = get_sketchup_endpoint()
    return {
        "mcp_transport": _transport(),
        "http_host": _http_host(),
        "http_port": _http_port(),
        "sketchup_host": host,
        "sketchup_port": port,
    }


@mcp.tool
def get_scene_info(ctx: Context, entity_limit: int = 25) -> dict[str, Any]:
    """Get a structured summary of the current SketchUp scene."""
    return _call_bridge_tool(ctx, "get_scene_info", {"entity_limit": entity_limit})


@mcp.tool
def list_entities(
    ctx: Context,
    limit: int = 100,
    include_hidden: bool = False,
) -> dict[str, Any]:
    """List top-level entities in the current SketchUp model."""
    return _call_bridge_tool(
        ctx,
        "list_entities",
        {
            "limit": limit,
            "include_hidden": include_hidden,
        },
    )


@mcp.tool
def get_entity_info(ctx: Context, id: str) -> dict[str, Any]:
    """Get structured information about a specific SketchUp entity by ID."""
    return _call_bridge_tool(ctx, "get_entity_info", {"id": id})


@mcp.tool
def create_component(
    ctx: Context,
    type: str = "cube",
    position: list[float] | None = None,
    dimensions: list[float] | None = None,
) -> dict[str, Any]:
    """Create a new component in SketchUp."""
    return _call_bridge_tool(
        ctx,
        "create_component",
        {
            "type": type,
            "position": position or [0, 0, 0],
            "dimensions": dimensions or [1, 1, 1],
        },
    )


@mcp.tool
def delete_component(ctx: Context, id: str) -> dict[str, Any]:
    """Delete a component by ID."""
    return _call_bridge_tool(ctx, "delete_component", {"id": id})


@mcp.tool
def transform_component(
    ctx: Context,
    id: str,
    position: list[float] | None = None,
    rotation: list[float] | None = None,
    scale: list[float] | None = None,
) -> dict[str, Any]:
    """Transform a component's position, rotation, or scale."""
    arguments: dict[str, Any] = {"id": id}
    if position is not None:
        arguments["position"] = position
    if rotation is not None:
        arguments["rotation"] = rotation
    if scale is not None:
        arguments["scale"] = scale
    return _call_bridge_tool(ctx, "transform_component", arguments)


@mcp.tool
def get_selection(ctx: Context) -> dict[str, Any]:
    """Get detailed information about the current SketchUp selection."""
    return _call_bridge_tool(ctx, "get_selection")


@mcp.tool
def set_material(ctx: Context, id: str, material: str) -> dict[str, Any]:
    """Set the material for a SketchUp entity."""
    return _call_bridge_tool(ctx, "set_material", {"id": id, "material": material})


@mcp.tool
def export_scene(
    ctx: Context,
    format: str = "skp",
    width: int | None = None,
    height: int | None = None,
) -> dict[str, Any]:
    """Export the current SketchUp scene."""
    arguments: dict[str, Any] = {"format": format}
    if width is not None:
        arguments["width"] = width
    if height is not None:
        arguments["height"] = height
    return _call_bridge_tool(ctx, "export", arguments)


@mcp.tool
def boolean_operation(
    ctx: Context,
    target_id: str,
    tool_id: str,
    operation: str,
    delete_originals: bool = False,
) -> dict[str, Any]:
    """Run a boolean operation between two SketchUp groups/components."""
    return _call_bridge_tool(
        ctx,
        "boolean_operation",
        {
            "target_id": target_id,
            "tool_id": tool_id,
            "operation": operation,
            "delete_originals": delete_originals,
        },
    )


@mcp.tool
def chamfer_edges(
    ctx: Context,
    entity_id: str,
    distance: float = 0.5,
    edge_indices: list[int] | None = None,
    delete_original: bool = False,
) -> dict[str, Any]:
    """Create a chamfer on selected edges of a group or component."""
    arguments: dict[str, Any] = {
        "entity_id": entity_id,
        "distance": distance,
        "delete_original": delete_original,
    }
    if edge_indices is not None:
        arguments["edge_indices"] = edge_indices
    return _call_bridge_tool(ctx, "chamfer_edges", arguments)


@mcp.tool
def fillet_edges(
    ctx: Context,
    entity_id: str,
    radius: float = 0.5,
    segments: int = 8,
    edge_indices: list[int] | None = None,
    delete_original: bool = False,
) -> dict[str, Any]:
    """Create a fillet on selected edges of a group or component."""
    arguments: dict[str, Any] = {
        "entity_id": entity_id,
        "radius": radius,
        "segments": segments,
        "delete_original": delete_original,
    }
    if edge_indices is not None:
        arguments["edge_indices"] = edge_indices
    return _call_bridge_tool(ctx, "fillet_edges", arguments)


@mcp.tool
def create_mortise_tenon(
    ctx: Context,
    mortise_id: str,
    tenon_id: str,
    width: float = 1.0,
    height: float = 1.0,
    depth: float = 1.0,
    offset_x: float = 0.0,
    offset_y: float = 0.0,
    offset_z: float = 0.0,
) -> dict[str, Any]:
    """Create a mortise and tenon joint between two components."""
    return _call_bridge_tool(
        ctx,
        "create_mortise_tenon",
        {
            "mortise_id": mortise_id,
            "tenon_id": tenon_id,
            "width": width,
            "height": height,
            "depth": depth,
            "offset_x": offset_x,
            "offset_y": offset_y,
            "offset_z": offset_z,
        },
    )


@mcp.tool
def create_dovetail(
    ctx: Context,
    tail_id: str,
    pin_id: str,
    width: float = 1.0,
    height: float = 1.0,
    depth: float = 1.0,
    angle: float = 15.0,
    num_tails: int = 3,
    offset_x: float = 0.0,
    offset_y: float = 0.0,
    offset_z: float = 0.0,
) -> dict[str, Any]:
    """Create a dovetail joint between two components."""
    return _call_bridge_tool(
        ctx,
        "create_dovetail",
        {
            "tail_id": tail_id,
            "pin_id": pin_id,
            "width": width,
            "height": height,
            "depth": depth,
            "angle": angle,
            "num_tails": num_tails,
            "offset_x": offset_x,
            "offset_y": offset_y,
            "offset_z": offset_z,
        },
    )


@mcp.tool
def create_finger_joint(
    ctx: Context,
    board1_id: str,
    board2_id: str,
    width: float = 1.0,
    height: float = 1.0,
    depth: float = 1.0,
    num_fingers: int = 5,
    offset_x: float = 0.0,
    offset_y: float = 0.0,
    offset_z: float = 0.0,
) -> dict[str, Any]:
    """Create a finger joint between two components."""
    return _call_bridge_tool(
        ctx,
        "create_finger_joint",
        {
            "board1_id": board1_id,
            "board2_id": board2_id,
            "width": width,
            "height": height,
            "depth": depth,
            "num_fingers": num_fingers,
            "offset_x": offset_x,
            "offset_y": offset_y,
            "offset_z": offset_z,
        },
    )


@mcp.tool
def eval_ruby(ctx: Context, code: str) -> dict[str, Any]:
    """Evaluate arbitrary Ruby code inside SketchUp."""
    return _call_bridge_tool(ctx, "eval_ruby", {"code": code})
