# Task: MTA-40 Add Forced Subdivision Masks For Feature-Critical Geometry
**Task ID**: `MTA-40`
**Title**: `Add Forced Subdivision Masks For Feature-Critical Geometry`
**Status**: `defined`
**Priority**: `core`
**Date**: `2026-05-15`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)

## Problem Statement

Feature-aware tolerance and density can improve triangle allocation, but important design geometry
can still disappear if height residual alone says a cell is acceptable. Hard segments, protected
boundaries, anchors, local detail boundaries, and feature-critical geometry need explicit
subdivision pressure before the system can claim that feature intent affects output topology.

This task introduces forced subdivision masks for feature-critical geometry while preserving the
adaptive patch/cell production path and refusing unsupported hard/protected cases before mutation.

## Goals

- Force adaptive subdivision around supported hard segments, protected boundaries, anchors, and
  feature-critical geometry.
- Treat unsupported or conflicting hard/protected feature cases as structured refusal or safe
  fallback before SketchUp output mutation.
- Preserve existing PatchLifecycle ownership, dirty-window behavior, registry/readback, and
  no-delete replacement.
- Extend validation so height correctness is not confused with feature-topology correctness.
- Prove the change with MTA-38 replay evidence and MTA-39 baseline deltas.

## Acceptance Criteria

```gherkin
Scenario: Supported feature-critical geometry forces subdivision
  Given a managed terrain replay row with supported hard or protected feature geometry
  When adaptive output is regenerated through the hosted public command path
  Then cells intersecting supported feature-critical geometry are subdivided according to policy
  And the resulting output records diagnostics explaining which feature geometry affected subdivision
  And local face-count changes are attributable to the relevant feature windows

Scenario: Unsupported hard or protected cases refuse before mutation
  Given hard or protected feature geometry that cannot be represented within current adaptive policy
  When output planning or validation detects the unsupported case
  Then the command refuses or routes to a safe fallback before erasing old output
  And old derived terrain output remains intact
  And the public response remains sanitized and does not expose raw feature graphs or internal patch ids

Scenario: Feature topology validation distinguishes more than height residual
  Given a replay row where height samples pass but feature-critical geometry could be underrepresented
  When MTA-40 validation runs
  Then validation checks whether supported feature-critical geometry influenced output topology as required
  And the task records failure when height residual passes but required feature subdivision was skipped

Scenario: Live evidence is recorded for the same baseline corpus
  Given the MTA-38 replay corpus and MTA-39 feature-aware output policy
  When MTA-40 verification completes
  Then every relevant replay row records before/after timing
  And every relevant replay row records before/after face count
  And every relevant replay row records dirty-window and affected-patch scope
  And fallback/refusal/no-delete outcomes are recorded for unsupported or invalid feature cases
  And the task records a verdict of improved, neutral, regressed, or failed for each row
```

## Non-Goals

- Upgrading seam contracts, patch component promotion, sparse local detail tiles, local CDT islands,
  native acceleration, or public backend selection.
- Guaranteeing arbitrary hard-feature representation outside the supported adaptive mask policy.
- Using stitch or mortar strips as the normal seam strategy.
- Making generated mesh topology the terrain source of truth.

## Business Constraints

- This is the first major topology-affecting feature-aware adaptive task and must be proven in
  hosted verification before downstream seam or component work relies on it.
- Unsupported hard/protected cases must fail safely rather than silently approximate.
- Performance and face-count evidence must be comparable with the MTA-38 harness.

## Technical Constraints

- `MTA-39` feature-aware tolerance and density policy must exist first.
- Forced subdivision masks must be deterministic for repeated runs over the same terrain state.
- PatchLifecycle ownership and no-delete mutation semantics from MTA-36 must remain intact.
- Public MCP tool names, request schemas, dispatcher routes, and response shapes must remain
  unchanged.
- CDT must not become the production path for this task.

## Dependencies

- `MTA-39`
- `MTA-38`
- `MTA-36`
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)

## Relationships

- blocks `MTA-42`
- informs optional `MTA-41`
- informs `MTA-43`

## Related Technical Plan

- none yet

## Success Metrics

- Supported feature-critical geometry produces deterministic forced subdivision diagnostics.
- Unsupported hard/protected cases refuse or fall back before mutation and leave old output intact.
- Replay evidence reports localized face-count impact and timing impact.
- Validation can fail a row where height residual passes but required feature subdivision is missing.
- Patch ownership, registry/readback, and repeated edit behavior remain reliable.
