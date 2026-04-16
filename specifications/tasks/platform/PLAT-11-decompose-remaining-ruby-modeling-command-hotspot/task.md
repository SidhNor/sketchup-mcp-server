# Task: PLAT-11 Decompose Remaining Ruby Modeling Command Hotspot
**Task ID**: `PLAT-11`
**Title**: `Decompose Remaining Ruby Modeling Command Hotspot`
**Status**: `planned`
**Priority**: `P1`
**Date**: `2026-04-16`

## Linked HLD

- [Platform Architecture and Repo Structure](../../../hlds/hld-platform-architecture-and-repo-structure.md)

## Problem Statement

PLAT-08 reduced the first high-value Ruby cleanup targets, but `src/su_mcp/socket_server.rb` still owns the remaining heavy modeling and joinery command paths. Boolean operations, edge treatment, joint-generation flows, and their helper mechanics are still concentrated in the transport entrypoint instead of living behind clearer Ruby-owned command and support seams. That leaves the runtime with a visible structural gap against the platform HLD: transport ingress is cleaner than before, but it still carries too much direct ownership of modeling behavior that should be easier to review, test, and extend independently.

## Goals

- reduce the remaining modeling-command concentration inside the Ruby transport entrypoint
- preserve the current public tool names and bridge-facing behavior for the affected modeling flows
- create a clearer Ruby-owned boundary for advanced modeling and joinery behavior so follow-on capability work does not keep growing `SocketServer`
- leave the extracted Ruby-owned seams reusable from both the current bridge runtime and the Ruby-native runtime foundation being prepared elsewhere

## Acceptance Criteria

```gherkin
Scenario: Remaining modeling command ownership is no longer centered in SocketServer
  Given `SocketServer` still directly owns boolean, edge-treatment, and joint-generation behavior after PLAT-08
  When the Ruby runtime structure is reviewed after this task is complete
  Then those modeling flows no longer default to direct ownership inside the transport entrypoint
  And lower-level modeling helpers that deserve independent ownership are no longer embedded there by default

Scenario: Advanced modeling cleanup preserves the existing public bridge surface
  Given Python and bridge-facing tests already depend on the current Ruby command names and payload shapes
  When representative affected modeling flows are exercised after the cleanup
  Then public tool names remain stable unless a separate interface change is explicitly scoped
  And the bridge-facing request and response contracts remain behaviorally compatible for the supported flows

Scenario: Extracted modeling seams are reviewable and testable in isolation
  Given the current remaining hotspot is hard to validate without reading through transport-owned code
  When the affected Ruby-owned modeling seams are reviewed after this task is complete
  Then the extracted ownership can be exercised through focused regression coverage at the smallest practical Ruby layer
  And any remaining SketchUp-hosted-only verification gaps are explicit rather than hidden inside the cleanup

Scenario: Cleanup stays compatible with the parallel Ruby-native foundation work
  Given the platform is also preparing a Ruby-native runtime foundation outside this task
  When the extracted modeling seams are reviewed after this task is complete
  Then those Ruby-owned seams are reusable from both the current bridge path and the future Ruby-native runtime path
  And the task does not take ownership of packaging, loader, bootstrap, or Ruby-native tool registration concerns

Scenario: Cleanup stays bounded to the remaining modeling hotspot
  Given this task is a follow-up cleanup to PLAT-08 rather than a broad platform rewrite
  When the completed task is reviewed
  Then the changes are traceable to the remaining boolean, edge-treatment, and joint-generation hotspot in the Ruby runtime
  And unrelated runtime migration or new product-capability work is left outside the task boundary
```

## Non-Goals

- introducing new modeling or joinery capabilities
- migrating the platform to the Ruby-native MCP runtime
- redesigning the Python MCP adapter
- resolving unrelated runtime security or architecture concerns that are not required to decompose this hotspot

## Business Constraints

- Ruby must remain the owner of SketchUp-facing modeling behavior
- the cleanup must stay bounded enough to finish as a reviewable follow-up to PLAT-08 rather than becoming an open-ended rewrite
- existing client-facing behavior for the affected modeling flows should remain stable unless a separate interface change is intentionally scoped
- the task should improve maintainability for future Ruby capability work rather than only moving code cosmetically

## Technical Constraints

- the current dual-runtime platform behavior must remain intact unless a separate architecture task changes it
- cross-runtime payloads must remain JSON-serializable and compatible with the existing Python/Ruby bridge expectations
- extension loader and packaging behavior must remain valid after the Ruby restructuring
- the task must follow the platform HLD direction of separating transport ingress from command and support ownership
- the task must not take ownership of packaging, vendoring, loader, facade, bootstrap, or Ruby-native MCP registration work reserved for adjacent platform tasks

## Dependencies

- `PLAT-01`
- `PLAT-02`
- `PLAT-08`

## Relationships

- follows `PLAT-08`
- should remain compatible with `PLAT-09` without absorbing its runtime-foundation scope
- informs future Ruby runtime cleanup and capability planning
- informs any later effort to narrow or retire the remaining oversized `SocketServer` surface

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- the remaining modeling hotspot in `SocketServer` has materially narrower ownership after the task
- reviewers can locate advanced modeling and joinery ownership without treating the transport file as the default home for that behavior
- the affected flows retain stable bridge-facing behavior while gaining focused regression coverage or explicitly documented host-only validation gaps
