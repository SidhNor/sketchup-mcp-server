# Task: PLAT-03 Decompose Python MCP Adapter
**Task ID**: `PLAT-03`
**Title**: `Decompose Python MCP Adapter`
**Status**: `planned`
**Priority**: `P0`
**Date**: `2026-04-13`

## Linked HLD

- [Platform Architecture and Repo Structure](../../../hlds/hld-platform-architecture-and-repo-structure.md)

## Problem Statement

The current Python MCP adapter works, but app boot, lifecycle behavior, shared bridge invocation, endpoint resolution, and the full tool surface are still concentrated in `server.py`. That limits scalability as capability areas expand and makes it harder to review bridge concerns separately from tool exposure.

## Goals

- separate shared bridge invocation and error mapping from Python app boot
- separate Python app boot from tool-module ownership
- preserve Python as a thin adapter with stable MCP-facing behavior
- preserve Python package entrypoints and cross-runtime version ownership through the decomposition

## Acceptance Criteria

```gherkin
Scenario: Shared bridge invocation has explicit Python ownership
  Given multiple MCP tools call into the Ruby bridge
  When the Python adapter is reviewed
  Then connection management, endpoint resolution, request construction, response parsing, and boundary error handling are owned by a shared platform layer
  And individual tool handlers do not duplicate those behaviors

Scenario: App boot is separate from tool-module ownership
  Given the FastMCP server has boot, lifecycle, and transport-selection responsibilities
  When the Python adapter structure is reviewed
  Then app boot ownership is distinct from tool-module ownership
  And tool definitions are no longer concentrated in the primary app-boot module

Scenario: Existing MCP-facing tool contracts remain stable
  Given MCP clients already depend on the current Python tool surface
  When the adapter structure is reviewed after the decomposition
  Then the package entrypoint still resolves correctly
  And existing tool names and argument surfaces are preserved unless a separate interface change is explicitly made

Scenario: Python decomposition preserves package and version ownership
  Given the repository already exposes a packaged Python server and aligned version-bearing artifacts
  When the Python adapter refactor is reviewed
  Then the Python packaging path remains valid
  And Python-side version ownership remains compatible with the supported cross-runtime release workflow
```

## Non-Goals

- moving capability behavior from Ruby into Python
- redesigning the Ruby command model
- changing tool names or argument contracts without a separate interface decision

## Business Constraints

- Python must remain thin and mechanical as the tool surface grows
- contributors must be able to locate app boot, invocation, and tool exposure responsibilities separately
- the task must preserve a stable MCP-facing experience for existing consumers
- already-working package and release behavior must remain intact through the adapter reorganization

## Technical Constraints

- the resulting structure must align with the revised platform HLD
- the Python boundary model must remain compatible with Ruby runtime contracts
- package ownership and console-script entrypoints must remain valid through the reorganization
- Python-side version-bearing artifacts must remain compatible with current release support

## Dependencies

- `PLAT-01`

## Relationships

- blocks `PLAT-05`
- informs `PLAT-06`

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- Python app boot, shared invocation, and MCP tool ownership are reviewable independently
- tool handlers no longer need to define their own connection or parse logic
- current MCP-facing contract stability is preserved through the Python reorganization
