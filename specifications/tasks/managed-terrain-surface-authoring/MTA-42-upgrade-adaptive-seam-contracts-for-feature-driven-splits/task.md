# Task: MTA-42 Upgrade Adaptive Seam Contracts For Feature-Driven Splits
**Task ID**: `MTA-42`
**Title**: `Upgrade Adaptive Seam Contracts For Feature-Driven Splits`
**Status**: `defined`
**Priority**: `core`
**Date**: `2026-05-15`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)

## Problem Statement

Feature-driven tolerance, density, and forced subdivision can create boundary split requirements
that affect neighboring patches. The existing adaptive production path has conformance behavior,
but feature-driven topology needs explicit seam contracts so one patch cannot introduce one-sided
boundary splits, cracks, ownership ambiguity, or retained-neighbor mismatch.

This task upgrades adaptive seam contracts with deterministic seam lattice behavior, retained
neighbor spans, seam digests, and validation for feature-driven splits.

## Goals

- Define deterministic seam lattice behavior for adaptive patch boundaries under feature-driven
  subdivision.
- Preserve retained neighbor spans when only one side of a seam is regenerated.
- Detect when a seam change requires neighbor promotion instead of one-sided replacement.
- Store or validate seam digests in derived patch metadata where needed for readback and repeated
  edits.
- Prove seam correctness with hosted replay evidence, including timing, face count, patch scope,
  and no-crack/no-T-junction checks.

## Acceptance Criteria

```gherkin
Scenario: Feature-driven seam lattice is deterministic
  Given neighboring adaptive patches with feature-driven split requirements near their shared boundary
  When output is regenerated through hosted public commands
  Then both sides derive the same ordered seam boundary chain when both sides are regenerated
  And retained neighbor spans are used as locked input when only one side is replaced
  And seam digest or equivalent metadata is sufficient for repeated edit validation

Scenario: One-sided invalid seam changes are refused or promoted
  Given a feature-driven split requires changing a retained neighbor boundary
  When the replacement side cannot conform to the retained neighbor span
  Then the planner promotes the neighbor patch when within policy budget
  Or refuses or safely falls back before mutation when promotion exceeds policy
  And old output remains intact on refusal or failed validation

Scenario: Seam validation catches cracks and T-junction regressions
  Given the MTA-38 replay corpus extended with seam-sensitive feature rows
  When MTA-42 validation runs
  Then regenerated shared seams have matching vertex chains and Z values within tolerance
  And no one-sided extra boundary splits, cracks, or T-junction regressions are accepted

Scenario: Live evidence is recorded for the same baseline corpus
  Given the MTA-38 replay corpus and MTA-40 forced subdivision behavior
  When MTA-42 verification completes
  Then every relevant replay row records before/after timing
  And every relevant replay row records before/after face count
  And every relevant replay row records patch promotion, retained-span, and dirty-window evidence
  And fallback/refusal/no-delete outcomes are recorded for seam failures
  And the task records a verdict of improved, neutral, regressed, or failed for each row
```

## Non-Goals

- Implementing the full patch component planner for arbitrary cross-patch features.
- Adding sparse local detail tiles, local CDT islands, native acceleration, or public backend
  selection.
- Using stitch or mortar strips as the normal production seam strategy.
- Replacing PatchLifecycle ownership or making seams public command concepts.

## Business Constraints

- Seam correctness must be proven before broad cross-patch feature component planning.
- The task must protect MTA-36 dirty-window and no-delete behavior under feature-driven splits.
- Hosted evidence must prove both correctness and performance impact.

## Technical Constraints

- `MTA-40` forced subdivision masks must exist first.
- Seam behavior must be deterministic from owner-local terrain/sample coordinates, patch policy,
  feature context, and retained neighbor spans.
- Seam metadata must remain derived output state, not terrain source state.
- Public MCP contracts must remain unchanged.
- Production output must remain adaptive patch/cell terrain output, not global CDT.

## Dependencies

- `MTA-40`
- `MTA-39`
- `MTA-38`
- `MTA-36`
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)

## Relationships

- blocks `MTA-43`
- blocks `MTA-44`
- does not require optional `MTA-41`

## Related Technical Plan

- none yet

## Success Metrics

- Seam-sensitive hosted rows show zero accepted cracks, T-junction regressions, or one-sided extra
  boundary splits.
- Retained neighbor spans are validated during local replacement.
- Required neighbor promotion or refusal is recorded before mutation.
- Timing, face-count, and patch-promotion evidence is captured per replay row.
- Registry/readback remains sufficient for repeated seam-sensitive edits.
