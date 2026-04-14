# STI-02 Implementation Summary

## Delivered

- Added the public `sample_surface_z` bridge contract cases for `hit`, `miss`, `ambiguous`, mixed multi-point results, ignore-target behavior, and unsupported-target failure.
- Implemented Ruby-owned explicit surface interrogation in `SceneQueryCommands`, backed by the new `SampleSurfaceQuery` helper for target resolution, face collection, occlusion filtering, ambiguity clustering, and compact per-point result shaping.
- Added dedicated meter-space sample-point serialization in `SceneQuerySerializer` so the public `sample_surface_z` payload stays separate from the broader inspection serializer shape.
- Added Python MCP registration for `sample_surface_z` with typed nested `target`, `samplePoints`, and `ignoreTargets` models plus thin bridge forwarding.
- Reworked the Ruby sampling path to carry group/component transformations and use a world-space face-plane intersection plus `classify_point` evaluation for non-fixture SketchUp faces instead of the earlier bounds-center fallback.

## Tests Added

- Ruby command coverage for request validation, supported face/group/component targets, `hit` / `miss` / `ambiguous` outcomes, visible-only interference, ignore-target behavior, point-order preservation, clustering tolerance, and meter-space result serialization.
- Ruby command coverage for transformed nested targets and sloped-face sampling so the runtime path is not limited to flat untransformed fixture geometry.
- Ruby dispatcher coverage for the new `sample_surface_z` tool name.
- Python tool coverage for tool registration order, nested schema visibility, passthrough request shaping, and request-id propagation.
- Ruby and Python contract coverage for the new shared bridge cases.

## Implementation Notes

- Manual SketchUp verification is still required for representative geometry scenarios, especially to confirm the runtime face-plane/classification path against live SketchUp entities beyond the current non-hosted fixture coverage.
