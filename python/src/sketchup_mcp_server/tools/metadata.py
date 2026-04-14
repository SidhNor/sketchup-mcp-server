"""Shared MCP tool decoration helpers."""

from __future__ import annotations

from typing import Any

from mcp.types import ToolAnnotations


def tool_metadata(
    *,
    title: str,
    description: str,
    read_only: bool,
    destructive: bool = False,
) -> dict[str, Any]:
    """Return the required MCP decoration contract for live public tools."""
    return {
        "title": title,
        "description": description,
        "annotations": ToolAnnotations(
            readOnlyHint=read_only,
            destructiveHint=destructive,
        ),
    }
