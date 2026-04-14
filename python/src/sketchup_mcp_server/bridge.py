"""Shared TCP bridge client for the SketchUp Ruby runtime."""

from __future__ import annotations

import json
import logging
import socket
from typing import Any, Callable

from .config import ServerSettings

logger = logging.getLogger("SketchUpMCPServer")

SocketFactory = Callable[[int, int], socket.socket]


class BridgeError(RuntimeError):
    """Base error for Python-to-Ruby bridge failures."""


class BridgeTransportError(BridgeError):
    """Raised when the Ruby bridge cannot be reached."""


class BridgeProtocolError(BridgeError):
    """Raised when the Ruby bridge returns an invalid payload."""


class BridgeRemoteError(BridgeError):
    """Raised when the Ruby bridge reports an application error."""


class BridgeClient:
    """Short-lived socket client for the SketchUp bridge."""

    def __init__(
        self,
        settings: ServerSettings,
        *,
        socket_factory: SocketFactory = socket.socket,
        timeout: float = 15.0,
    ) -> None:
        self._settings = settings
        self._socket_factory = socket_factory
        self._timeout = timeout
        self._socket: socket.socket | None = None

    def ping(self, request_id: Any = None) -> dict[str, Any]:
        return self._send_request("ping", {}, request_id=request_id)

    def call_tool(
        self,
        name: str,
        arguments: dict[str, Any] | None = None,
        request_id: Any = None,
    ) -> dict[str, Any]:
        return self._send_request(
            "tools/call",
            {"name": name, "arguments": arguments or {}},
            request_id=request_id,
        )

    def disconnect(self) -> None:
        if self._socket is None:
            return

        try:
            self._socket.close()
        except OSError as exc:
            logger.warning("Error disconnecting from SketchUp bridge: %s", exc)
        finally:
            self._socket = None

    def _send_request(
        self,
        method: str,
        params: dict[str, Any],
        *,
        request_id: Any,
    ) -> dict[str, Any]:
        request = {
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
            "id": request_id,
        }

        self._connect()
        try:
            assert self._socket is not None
            self._socket.sendall(json.dumps(request).encode("utf-8") + b"\n")
            response = self._receive_response()
        finally:
            self.disconnect()

        error = response.get("error")
        if isinstance(error, dict):
            message = error.get("message", "Unknown SketchUp bridge error")
            raise BridgeRemoteError(message)

        result = response.get("result")
        if not isinstance(result, dict):
            raise BridgeProtocolError("Malformed JSON response received from the SketchUp bridge.")

        return result

    def _connect(self) -> None:
        self.disconnect()
        try:
            sock = self._socket_factory(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(self._timeout)
            sock.connect((self._settings.sketchup_host, self._settings.sketchup_port))
        except OSError as exc:
            raise BridgeTransportError(
                f"Could not connect to SketchUp bridge at "
                f"{self._settings.sketchup_host}:{self._settings.sketchup_port}: {exc}"
            ) from exc

        self._socket = sock

    def _receive_response(self, buffer_size: int = 8192) -> dict[str, Any]:
        assert self._socket is not None
        chunks: list[bytes] = []

        while True:
            chunk = self._socket.recv(buffer_size)
            if not chunk:
                break

            chunks.append(chunk)

            try:
                return json.loads(b"".join(chunks).decode("utf-8"))
            except json.JSONDecodeError:
                continue

        if not chunks:
            raise BridgeProtocolError("SketchUp bridge closed the connection without a response.")

        data = b"".join(chunks)
        try:
            json.loads(data.decode("utf-8"))
        except json.JSONDecodeError as exc:
            message = str(exc)
            if "Expecting value" in message and data.strip():
                raise BridgeProtocolError(
                    "Malformed JSON response received from the SketchUp bridge."
                ) from exc

        raise BridgeProtocolError("Incomplete JSON response received from the SketchUp bridge.")
