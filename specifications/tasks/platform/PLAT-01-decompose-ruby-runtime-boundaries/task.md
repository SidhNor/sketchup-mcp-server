# Task: PLAT-01 Decompose Ruby Runtime Boundaries
**Task ID**: `PLAT-01`
**Title**: `Decompose Ruby Runtime Boundaries`
**Status**: `defined`
**Date**: `2026-04-13`

## Linked HLD

- [Platform Architecture and Repo Structure](../../../hlds/hld-platform-architecture-and-repo-structure.md)

## Problem Statement

The current Ruby runtime already works, but it concentrates transport ingress, request routing, command behavior, and shared runtime concerns in one large implementation area. That concentration makes future platform and capability work harder to review, harder to test, and more likely to blur infrastructure ownership with behavior ownership.

## Goals

- separate Ruby transport ingress from Ruby command execution
- establish explicit ownership for shared Ruby runtime concerns such as result and error contracts
- preserve the existing bridge-facing and packaging behavior while making the Ruby runtime easier to extend

## Acceptance Criteria

```gherkin
Scenario: Ruby transport and execution are structurally distinct
  Given the SketchUp bridge accepts structured requests from Python
  When the Ruby runtime is reviewed
  Then transport ingress and request routing are owned separately from command execution
  And command behavior is no longer concentrated in the primary transport implementation

Scenario: Shared Ruby runtime contracts have explicit ownership
  Given result shaping, error handling, configuration, logging, and operation-boundary behavior are cross-cutting concerns
  When the Ruby platform is reviewed after the task is complete
  Then those concerns have a shared platform-owned home
  And they are not left to ad hoc interpretation inside individual execution paths

Scenario: Bridge-facing behavior remains stable through the decomposition
  Given Python tools already depend on the current Ruby bridge behavior
  When representative tool calls are exercised after the task is complete
  Then the Ruby runtime still accepts the established request shape
  And the bridge still returns structured responses without requiring unrelated MCP-side rewrites

Scenario: Ruby refactoring preserves extension packaging assumptions
  Given the repository already builds a valid SketchUp RBZ from the current loader and support tree
  When the Ruby runtime refactor is reviewed
  Then the standard SketchUp loader plus support-tree packaging shape remains valid
  And Ruby-side version-bearing artifacts remain compatible with the supported release workflow
```

## Non-Goals

- implementing new product-capability behavior
- redesigning the Python MCP adapter
- changing the external bridge contract beyond what is required to preserve current behavior

## Business Constraints

- Ruby must remain the owner of SketchUp-facing execution semantics
- the task must improve maintainability without turning into a platform rewrite
- existing tool behavior must remain stable enough to avoid unnecessary downstream churn
- already-working extension packaging behavior must be preserved rather than re-invented

## Technical Constraints

- the task must preserve the small SketchUp loader pattern centered on `src/su_mcp.rb`
- the resulting structure must align with the Ruby layering in the revised platform HLD
- cross-runtime payloads must remain JSON-serializable and contract-friendly
- the Ruby refactor must remain compatible with RBZ packaging and current version-alignment support

## Dependencies

- revised platform HLD

## Relationships

- blocks `PLAT-02`
- blocks `PLAT-03`
- blocks `PLAT-05`
- informs `PLAT-06`
- enables the initial always-on verification work in `PLAT-04`

## Related Technical Plan

- none yet

## Success Metrics

- transport ingress, command execution, and shared runtime concerns are reviewable as distinct Ruby-owned platform areas
- current socket-driven tool calls continue to function without MCP-facing contract churn
- future Ruby command work no longer requires repeated edits to one concentrated transport implementation
