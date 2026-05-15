# Task: MTA-41 Add Optional Deterministic Feature-Aware Diagonal Optimization
**Task ID**: `MTA-41`
**Title**: `Add Optional Deterministic Feature-Aware Diagonal Optimization`
**Status**: `defined`
**Priority**: `optional`
**Date**: `2026-05-15`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)

## Problem Statement

Adaptive cell output ultimately emits triangles, and the diagonal chosen for each quad can affect
visual quality, slope continuity, feature alignment, and protected-boundary ambiguity. The
architecture note identifies deterministic diagonal optimization as useful, but no later task
structurally depends on it. It should therefore remain optional and evidence-driven rather than
blocking forced masks, seam contracts, component planning, or sparse local detail.

This task adds deterministic feature-aware diagonal optimization only if the evidence shows that it
is worth doing in the current iteration.

## Goals

- Choose adaptive cell diagonals deterministically using height residual, slope continuity, feature
  alignment, and protected-boundary ambiguity.
- Respect existing feature-aware tolerance, density, and forced subdivision policy when available.
- Avoid topology flicker across repeated edits and reload/readback.
- Prove whether diagonal optimization improves visual/output quality without unacceptable timing
  or face-count cost.
- Keep this task out of the hard dependency chain for seam contracts, component planning, and
  sparse local detail.

## Acceptance Criteria

```gherkin
Scenario: Diagonal selection is deterministic
  Given the same managed terrain state and feature context
  When adaptive output is regenerated repeatedly through hosted public commands
  Then diagonal choices are stable across repeated runs
  And repeated edits do not introduce topology flicker caused by nondeterministic tie-breaking

Scenario: Diagonal optimization respects feature and protection policy
  Given feature-aware tolerance, density, and supported forced subdivision policy
  When diagonal optimization evaluates an emitted adaptive cell
  Then chosen diagonals do not cross protected or forced boundaries in unsupported ways
  And feature alignment can influence diagonal choice where policy allows it
  And unsupported ambiguity is refused or left to the safer existing diagonal policy

Scenario: Optional value is proven before adoption
  Given the MTA-38 replay corpus and current feature-aware adaptive output baseline
  When MTA-41 verification completes
  Then every relevant replay row records before/after timing
  And every relevant replay row records before/after face count
  And every relevant replay row records visual or residual evidence for diagonal quality
  And the task records whether the optimization is adopted, deferred, or rejected
```

## Non-Goals

- Blocking seam contracts, patch component planning, sparse local detail, or default feature-aware
  output on diagonal optimization.
- Forcing subdivision, promoting patches, upgrading seam contracts, or adding local CDT islands.
- Changing public command contracts or exposing diagonal diagnostics publicly.
- Treating diagonal optimization as a substitute for hard/protected topology validation.

## Business Constraints

- This task is optional and should proceed only when it offers visible or measurable value.
- It must not delay the structural feature-aware backend sequence.
- Hosted evidence must show whether the change is worth adopting.

## Technical Constraints

- `MTA-39` is the hard dependency because diagonal scoring needs feature-aware output policy.
- `MTA-40` is recommended before adoption so forced/protected boundaries are known.
- No downstream task may depend on MTA-41 unless explicitly replanned later.
- Diagonal decisions must be deterministic and must preserve PatchLifecycle behavior.

## Dependencies

- `MTA-39`
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)

## Relationships

- optionally follows `MTA-40`
- does not block `MTA-42`
- does not block `MTA-43`
- does not block `MTA-44`

## Related Technical Plan

- none yet

## Success Metrics

- Repeated hosted runs produce stable diagonal choices.
- Protected and forced-boundary ambiguity is handled safely.
- Replay evidence shows whether visual/residual quality improves without unacceptable timing cost.
- The task records an adoption, deferral, or rejection verdict from evidence.
