# Task: SEM-15 Add Terrain-Anchored Hosting for Tree Proxy and Structure
**Task ID**: `SEM-15`
**Title**: `Add Terrain-Anchored Hosting for Tree Proxy and Structure`
**Status**: `completed`
**Priority**: `P1`
**Date**: `2026-04-24`

## Linked HLD

- [Semantic Scene Modeling](specifications/hlds/hld-semantic-scene-modeling.md)

## Problem Statement

The public `create_site_element` contract already advertises `hosting.mode: "terrain_anchored"` as a possible hosting mode, and the validator treats it as a hosting mode that requires a target. The runtime execution matrix, however, does not currently support `terrain_anchored` for any semantic element family. Supported hosted execution is limited to `path` with `surface_drape`, `pad` with `surface_snap`, and `retaining_edge` with `edge_clamp`.

This leaves two common semantic families with weak terrain ergonomics:

- `tree_proxy` still depends on the caller supplying the correct `definition.position.z`, even when the tree should stand on a known terrain host.
- `structure` still depends on a caller-supplied base elevation, even when a footprint should be placed as a planar built form anchored to terrain.

This task adds bounded, real `terrain_anchored` behavior for `tree_proxy` and `structure` without turning either family into terrain authoring or draped geometry. It should make the advertised hosting mode useful for these two families while preserving structured refusals for unsupported or unsatisfied terrain-hosting requests.

## Goals

- support `hosting.mode: "terrain_anchored"` for `tree_proxy` through the existing `create_site_element` surface
- support `hosting.mode: "terrain_anchored"` for `structure` through the existing `create_site_element` surface
- define `structure` terrain anchoring as planar base anchoring rather than vertex-by-vertex terrain draping
- return structured refusals when the hosting target is missing, invalid, unsupported, or cannot provide a usable terrain height
- align runtime support, public schema guidance, refusal behavior, tests, and user-facing documentation for the new hosted combinations

## Acceptance Criteria

```gherkin
Scenario: tree_proxy can be anchored to terrain
  Given a valid `create_site_element` request for `elementType: "tree_proxy"` uses `hosting.mode: "terrain_anchored"` with a resolvable terrain hosting target
  When the request is executed through the semantic runtime
  Then the created tree proxy is placed with its base anchored to the terrain height at the requested tree position
  And the result remains a managed semantic object with the normal `tree_proxy` metadata and JSON-serializable response shape

Scenario: structure can be anchored to terrain as a planar built form
  Given a valid `create_site_element` request for `elementType: "structure"` uses `hosting.mode: "terrain_anchored"` with a resolvable terrain hosting target
  When the request is executed through the semantic runtime
  Then the created structure uses one terrain-derived base elevation for the whole footprint
  And the structure remains a planar extruded built form rather than a terrain-draped or warped footprint

Scenario: unsupported or unsatisfied terrain anchoring refuses clearly
  Given a `tree_proxy` or `structure` request asks for `hosting.mode: "terrain_anchored"`
  When the hosting target is missing, unresolved, unsupported, or cannot provide a usable terrain height for the request
  Then the runtime returns a structured semantic refusal attributed to the `hosting` section
  And the refusal explains the unsupported or unsatisfied terrain anchoring condition without partially creating geometry

Scenario: hosting support matrix is discoverable and enforced
  Given clients inspect or misuse `create_site_element` hosting modes
  When `terrain_anchored` is used with `tree_proxy`, `structure`, or other supported semantic families
  Then the runtime accepts it only for the delivered `tree_proxy` and `structure` combinations
  And unsupported families still return `unsupported_hosting_mode` with allowed values for the requested `elementType`

Scenario: contract, docs, and validation move together
  Given this task expands the effective hosted semantic creation matrix
  When the task is complete
  Then loader guidance, semantic runtime behavior, refusal coverage, automated tests, and user-facing docs describe the new `terrain_anchored` behavior consistently
  And live or hosted SketchUp verification confirms the created geometry lands on terrain as documented
```

## Non-Goals

- terrain-draping, warping, cutting, filling, or conforming individual `structure` footprint vertices to terrain
- adding terrain anchoring to `pad`, `path`, `retaining_edge`, `planting_mass`, or new semantic families in this task
- introducing a new terrain authoring, terrain patch, water feature, seat, gate, stair, or tree-instance family
- changing the public `create_site_element` command into separate lifecycle- or hosting-specific tools
- changing `surface_drape`, `surface_snap`, or `edge_clamp` behavior for currently supported families

## Business Constraints

- `create_site_element` must remain one coherent semantic constructor rather than splitting into terrain-specific creation tools.
- Terrain anchoring must make common tree and structure placement easier without requiring callers to precompute exact z elevations externally.
- Structure behavior must stay semantically legible as a built form; terrain anchoring should place the building base, not turn buildings into terrain surfaces.
- Unsupported hosting combinations must teach clients through structured refusals rather than silently falling back to caller-provided elevations.

## Technical Constraints

- Ruby remains the owner of semantic hosting interpretation, target resolution, geometry construction, refusal behavior, and result serialization.
- The runtime hosting support matrix must be updated intentionally; schema enum exposure alone is not sufficient.
- `tree_proxy` and `structure` builders must consume resolved hosting context without exposing raw SketchUp objects across public boundaries.
- The behavior must be undo-safe and must not partially create geometry when terrain anchoring cannot be satisfied.
- Outputs must remain JSON-serializable managed-object results or structured semantic refusals.
- Tests must cover supported success paths, unsupported family refusals, missing or invalid hosting targets, and the documented structure planar-base rule.

## Dependencies

- `SEM-09`
- `SEM-13`
- `SEM-14`
- [HLD: Semantic Scene Modeling](specifications/hlds/hld-semantic-scene-modeling.md)
- [PRD: Semantic Scene Modeling](specifications/prds/prd-semantic-scene-modeling.md)

## Relationships

- follows `SEM-09` by extending the bounded hosted-execution matrix beyond the initial path, pad, and retaining-edge combinations
- builds on `SEM-13` terrain-sensitive hosted behavior while keeping `structure` anchoring distinct from path draping
- follows `SEM-14` by relying on clearer create-site-element request boundaries and structured refusal behavior
- informs future terrain-hosting work for planting, terrain patching, or richer site-object families

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- `tree_proxy` requests with `hosting.mode: "terrain_anchored"` can create managed tree proxies whose base elevation is derived from the resolved terrain host.
- `structure` requests with `hosting.mode: "terrain_anchored"` can create managed planar structures whose base elevation is derived from the resolved terrain host.
- unsupported terrain-hosting cases refuse with structured `hosting` details rather than silently creating unanchored geometry.
- automated and live or hosted SketchUp validation prove the new hosted combinations behave as documented.
