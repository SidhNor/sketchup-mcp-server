# Summary: SVR-02 Broaden `validate_scene_update` With Object-Anchor Surface-Offset Validation
**Task ID**: `SVR-02`
**Status**: `completed`
**Date**: `2026-04-23`

## Shipped

- Extended `validate_scene_update.expectations.geometryRequirements` with `kind: "surfaceOffset"`.
- Added the new public request fields for `surfaceOffset`:
  - `surfaceReference`
  - `anchorSelector.anchor`
  - `constraints.expectedOffset`
  - `constraints.tolerance`
- Exposed the new `surfaceOffset` branch in the MCP loader schema, including the finite `anchorSelector.anchor` enum:
  - `approximate_bottom_bounds_center`
  - `approximate_bottom_bounds_corners`
  - `approximate_top_bounds_center`
  - `approximate_top_bounds_corners`
- Added command-side refusal coverage for malformed `surfaceOffset` requests, including:
  - missing `surfaceReference`
  - missing `anchorSelector`
  - missing `constraints`
  - missing `constraints.expectedOffset`
  - missing `constraints.tolerance`
  - non-numeric `constraints.expectedOffset`
  - non-numeric `constraints.tolerance`
  - unsupported `anchorSelector.anchor` with `allowedValues`
- Implemented MVP approximate bounds-derived anchor evaluation against an explicit surface target using shared `SampleSurfaceQuery` behavior and ignore-target sampling to avoid self-occlusion by the modeled object.
- Added `failedAnchors` result evidence for `surfaceOffset` mismatches.
- Updated runtime passthrough coverage, native contract coverage, `README.md`, and `sketchup_mcp_guide.md` for the changed public surface.

## Validation

- `bundle exec ruby -Itest test/runtime/native/mcp_runtime_loader_test.rb`
- `bundle exec ruby -Itest test/scene_validation/scene_validation_commands_test.rb`
- `bundle exec ruby -Itest test/runtime/tool_dispatcher_test.rb`
- `bundle exec ruby -Itest test/runtime/native/mcp_runtime_facade_test.rb`
- `bundle exec ruby -Itest test/runtime/native/mcp_runtime_native_contract_test.rb`
- `bundle exec rake ruby:test`
- `bundle exec rake ruby:lint`
- `bundle exec rake package:verify`

## Notes

- The implementation stayed inside the Ruby runtime surfaces already planned:
  - `src/su_mcp/scene_validation/scene_validation_commands.rb`
  - `src/su_mcp/runtime/native/mcp_runtime_loader.rb`
- The implementation reused the existing `SampleSurfaceQuery` / `SampleSurfaceSupport` sampling behavior rather than extracting a second probing subsystem for this MVP.
- The finite `anchorSelector.anchor` option set is now aligned across:
  - runtime validation and refusal behavior
  - schema discoverability before a bad call
  - refusal `allowedValues` after a bad call
  - contract tests
  - user-facing docs
- The shipped anchors are intentionally approximate and bounds-derived. They are suitable for simple rectangular or slab-like forms, not irregular footprints.

## Remaining Gap

- SketchUp-hosted manual verification is still needed for transformed geometry, real-face sampling under occluding modeled objects, and irregular terrain cases outside the fake-geometry test harness.
- The immediate follow-up identified in planning remains valid: stronger shape-derived or contact-oriented anchors are still needed for irregular footprints such as L-shaped extensions on slopes.
