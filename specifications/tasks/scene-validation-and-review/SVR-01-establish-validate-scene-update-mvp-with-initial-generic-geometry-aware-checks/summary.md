# Summary: SVR-01 Establish `validate_scene_update` MVP With Initial Generic Geometry-Aware Checks

## What Shipped

- Added the new public native MCP tool `validate_scene_update`.
- Wired the new tool through:
  - [src/su_mcp/runtime/native/mcp_runtime_loader.rb](../../../../src/su_mcp/runtime/native/mcp_runtime_loader.rb)
  - [src/su_mcp/runtime/tool_dispatcher.rb](../../../../src/su_mcp/runtime/tool_dispatcher.rb)
  - [src/su_mcp/runtime/runtime_command_factory.rb](../../../../src/su_mcp/runtime/runtime_command_factory.rb)
- Added a new Ruby-owned validation slice:
  - [src/su_mcp/scene_validation/scene_validation_commands.rb](../../../../src/su_mcp/scene_validation/scene_validation_commands.rb)
  - [src/su_mcp/scene_validation/geometry_health_inspector.rb](../../../../src/su_mcp/scene_validation/geometry_health_inspector.rb)
- Kept the public request shape compact:
  - top-level `expectations` only
  - family sections for `mustExist`, `mustPreserve`, `metadataRequirements`, `tagRequirements`, `materialRequirements`, and `geometryRequirements`
  - exactly one of `targetReference` or `targetSelector` per expectation
- Reused the existing runtime response envelope through [ToolResponse](../../../../src/su_mcp/runtime/tool_response.rb) rather than introducing a new top-level result shape.
- Reused the existing selector and target-reference shapes already exposed by the runtime loader and scene-query seams.
- Implemented MVP refusal and validation behavior for:
  - missing or unsupported request fields
  - malformed expectation objects
  - none / ambiguous resolution outcomes
  - key-presence metadata requirements
  - tag requirements
  - material requirements
  - geometry requirements:
    - `mustHaveGeometry`
    - `mustNotBeNonManifold`
    - `mustBeValidSolid`
- Kept `mustPreserve` aligned with the MVP plan as continued unique resolution only.
- Enforced public-surface filtering for resolved targets so placeholder-style entities do not silently satisfy validation expectations.
- Updated [README.md](../../../../README.md) to include the new tool in the live MCP surface and describe the shipped MVP contract.

## Tests Added

- Runtime loader coverage for:
  - tool inventory
  - tool metadata
  - input schema structure
  - shared target-shape reuse
- Dispatcher coverage for `validate_scene_update` routing.
- Runtime facade / command-factory coverage for:
  - real factory inclusion of the validation command target
  - dispatch through the shared runtime command factory
- Validation command coverage for:
  - malformed-request refusal behavior
  - target input exclusivity
  - required family fields
  - none / ambiguous resolution handling
  - public-surface filtering
  - `mustExist`
  - `mustPreserve`
  - `metadataRequirements`
  - `tagRequirements`
  - `materialRequirements`
  - `mustHaveGeometry`
  - `mustNotBeNonManifold`
  - `mustBeValidSolid`
  - unsupported target types for geometry checks
  - expectation correlation in findings

## Validation

- Focused runtime validation:
  - `bundle exec ruby -Itest -e 'load "test/runtime/native/mcp_runtime_loader_test.rb"; load "test/runtime/tool_dispatcher_test.rb"; load "test/runtime/native/mcp_runtime_facade_test.rb"'`
- Focused validation-slice validation:
  - `bundle exec ruby -Itest -e 'load "test/scene_validation/scene_validation_commands_test.rb"'`
- Focused lint checks:
  - `RUBOCOP_CACHE_ROOT=tmp/.rubocop_cache bundle exec rubocop src/su_mcp/runtime/tool_dispatcher.rb src/su_mcp/runtime/native/mcp_runtime_loader.rb test/runtime/tool_dispatcher_test.rb test/runtime/native/mcp_runtime_loader_test.rb test/runtime/native/mcp_runtime_facade_test.rb`
  - `RUBOCOP_CACHE_ROOT=tmp/.rubocop_cache bundle exec rubocop src/su_mcp/runtime/runtime_command_factory.rb test/runtime/native/mcp_runtime_facade_test.rb src/su_mcp/scene_validation/scene_validation_commands.rb`
  - `RUBOCOP_CACHE_ROOT=tmp/.rubocop_cache bundle exec rubocop src/su_mcp/scene_validation/scene_validation_commands.rb src/su_mcp/scene_validation/geometry_health_inspector.rb test/scene_validation/scene_validation_commands_test.rb`
- Final broad validation:
  - `bundle exec rake ci`
- External MCP validation:
  - verified request-shape refusals, failed-vs-refused behavior, target resolution handling, all shipped expectation families, all shipped geometry kinds, mixed-batch aggregation, summary counts, expectation correlation fields, and unsupported geometry target refusal through the exposed MCP surface
  - confirmed that completely missing `expectations` is blocked by the MCP input schema before Ruby runtime handling, so runtime `missing_expectations` behavior is only observable when `expectations` is present but empty

## Codereview

- `mcp__pal__codereview` with model `grok-code`
  - Local pre-review found and fixed two real contract gaps before the final review:
    - missing enforcement of family-specific required fields
    - missing public-surface filtering for unique `targetReference` matches
  - Final outcome: no confirmed remaining findings on the validated change set.
- The expert analysis suggested distinguishing filtered public-surface misses from ordinary `none` resolution, but that was not adopted in this MVP because the current contract intentionally treats filtered-out non-public entities as unavailable to callers.
- `mcp__pal__codereview` with model `grok-4.20`
  - confirmed the overall runtime/tooling integration and selector/response-shape reuse
  - identified one real follow-up hardening item that was not changed in this task: family-specific fields such as `requiredKeys`, `expectedTag`, and `expectedMaterial` are presence-validated but not yet fully type-validated at normalization time
  - raised additional low-priority robustness notes around geometry-host behavior and a defensive Ruby local-variable edge case, but those were not treated as release blockers for `SVR-01`

## Docs And Metadata

- Updated [README.md](../../../../README.md) for the new public tool surface.
- Updated [task.md](./task.md) status to `completed`.
- Added this [summary.md](./summary.md).
- No `sketchup_mcp_guide.md` update was needed in this session because it already described `validate_scene_update` directionally; the README now captures the shipped MVP surface explicitly.

## Remaining Gaps

- No SketchUp-hosted smoke validation was completed in this session.
- The default geometry-health inspector remains intentionally minimal and should be treated as the MVP host seam, not as a complete geometry-diagnostics surface.
- `mustNotBeNonManifold` is currently strict enough that open surface geometry can fail it. This is consistent with the shipped implementation and external MCP verification, but the longer-term product intent for open surface workflows may need follow-on refinement.
- The broader validation roadmap from the capability HLD remains deferred:
  - richer geometry-aware checks
  - public `measure_scene`
  - asset-integrity validation
  - review snapshot capture

## Manual Verification Still Needed

- Run representative SketchUp-hosted checks for:
  - a non-volumetric surface target that should pass without `mustBeValidSolid`
  - a volumetric target that should fail `mustBeValidSolid`
  - a supported target with intentionally broken manifold/solid state
  - a placeholder or non-public entity that should not satisfy a validation expectation
