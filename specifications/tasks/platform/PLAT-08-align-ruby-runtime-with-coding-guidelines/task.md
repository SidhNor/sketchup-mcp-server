# Task: PLAT-08 Align Ruby Runtime With Coding Guidelines
**Task ID**: `PLAT-08`
**Title**: `Align Ruby Runtime With Coding Guidelines`
**Status**: `completed`
**Priority**: `P1`
**Date**: `2026-04-16`

## Linked HLD

- [Platform Architecture and Repo Structure](../../../hlds/hld-platform-architecture-and-repo-structure.md)

## Problem Statement

The Ruby runtime now has a portable coding-guidelines baseline, but the implemented code still reflects uneven decomposition. Some areas are already well-shaped, while others still concentrate transport, command behavior, host interaction, validation mechanics, and response shaping in ways that conflict with the current Ruby coding guidelines. The main cleanup targets for this task are the remaining transport-adjacent command concentration, the semantic request validator concentration, and the sample-surface query concentration. That gap makes the runtime harder to review, harder to extend consistently, and harder to keep structurally coherent as capability work continues.

## Goals

- reduce the highest-value divergences between the current Ruby runtime and the portable Ruby coding guidelines
- improve file and folder modularization so protocol, transport, command, serializer, and host-facing seams are easier to identify
- preserve existing external behavior while making internal Ruby ownership more consistent and reviewable

## Acceptance Criteria

```gherkin
Scenario: Ruby modularization reflects the intended runtime seams more clearly
  Given the Ruby runtime currently has a flat top-level structure and several concentrated implementation hotspots
  When the runtime structure is reviewed after the task is complete
  Then protocol, transport, command, serializer, and host-facing support concerns are more clearly separated in files and folders
  And the top-level runtime namespace no longer acts as the default home for unrelated concerns

Scenario: Highest-value Ruby hotspots no longer dominate their current responsibilities
  Given the current Ruby runtime still contains concentrated structural hotspots
  When the highest-priority affected areas are reviewed after the cleanup
  Then those areas no longer mix as many unrelated responsibilities as they do today
  And lower-level mechanics that deserve independent ownership are no longer embedded inside one dominant class by default

Scenario: Ruby cleanup preserves existing public behavior
  Given Python and contract tests already depend on the current Ruby request and response surface
  When representative Ruby-owned tool flows are exercised after the cleanup
  Then public tool names and bridge-facing payload contracts remain stable unless a separate interface change is made
  And existing behavior is preserved without requiring unrelated MCP-facing rewrites

Scenario: Cleanup remains bounded to the identified structural hotspots
  Given the task targets the remaining transport-adjacent command hotspot, semantic validator hotspot, and sample-surface query hotspot
  When the task outcome is reviewed
  Then the completed cleanup is traceable to those identified hotspots
  And remaining notable divergences are either reduced or explicitly left outside the task boundary
```

## Non-Goals

- implementing new product-capability behavior
- redesigning the Python MCP adapter
- committing to the unimplemented Ruby-native MCP ADR as part of this cleanup
- eliminating every Ruby-guideline divergence in one pass

## Business Constraints

- Ruby must remain the owner of SketchUp-facing behavior
- the cleanup must improve maintainability without turning into an open-ended rewrite
- existing consumer-facing behavior should remain stable unless an interface change is explicitly scoped elsewhere
- the task should create a clearer baseline for future Ruby capability work rather than only moving code around cosmetically

## Technical Constraints

- the task must preserve the current dual-runtime platform behavior unless a separate architecture task changes it
- cross-runtime payloads must remain JSON-serializable and contract-safe
- extension loader and packaging assumptions must remain valid
- the cleanup should be driven by the identified structural hotspots and portable Ruby coding guidelines rather than ad hoc preferences

## Dependencies

- `PLAT-01`
- `PLAT-02`
- `specifications/guidelines/ryby-coding-guidelines.md`

## Relationships

- informs future Ruby runtime cleanup and capability planning
- informs follow-on platform decomposition work

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- the highest-priority divergence hotspots have materially narrower ownership after the cleanup
- the Ruby runtime file and folder structure makes major seams easier to locate during review
- the cleanup can be explained against the identified structural hotspots instead of as subjective stylistic churn

## Implementation Notes

- Extracted a first grouped editing-command surface out of the Ruby transport hotspot:
  - [EditingCommands](./../../../src/su_mcp/editing_commands.rb)
  - [ComponentGeometryBuilder](./../../../src/su_mcp/component_geometry_builder.rb)
  - [MaterialResolver](./../../../src/su_mcp/material_resolver.rb)
- Rewired [SocketServer](./../../../src/su_mcp/socket_server.rb) to build that grouped command surface and route tool calls through [ToolDispatcher](./../../../src/su_mcp/tool_dispatcher.rb) without keeping the moved edit/export/material methods on the transport entrypoint.
- Extracted lower-level semantic geometry and numeric mechanics into [Semantic::GeometryValidator](./../../../src/su_mcp/semantic/geometry_validator.rb) and rewired [RequestValidator](./../../../src/su_mcp/semantic/request_validator.rb) to depend on it.
- Extracted sample-surface traversal, visibility, and clustering mechanics into [SampleSurfaceSupport](./../../../src/su_mcp/sample_surface_support.rb) and rewired [SampleSurfaceQuery](./../../../src/su_mcp/sample_surface_query.rb) to depend on it.
- Added seam-level regression coverage for each extracted owner:
  - [test/editing_commands_test.rb](./../../../test/editing_commands_test.rb)
  - [test/semantic_geometry_validator_test.rb](./../../../test/semantic_geometry_validator_test.rb)
  - [test/sample_surface_support_test.rb](./../../../test/sample_surface_support_test.rb)

## Validation Notes

- Passed `bundle exec rake ruby:test`
- Passed `bundle exec rake ruby:lint`
- Passed `bundle exec rake package:verify`
- The public Python/Ruby bridge contract did not change, so shared contract artifacts and contract suites did not require updates.
- Manual SketchUp-hosted verification was not run for the touched edit/material flows; that remains the main follow-up validation gap.
