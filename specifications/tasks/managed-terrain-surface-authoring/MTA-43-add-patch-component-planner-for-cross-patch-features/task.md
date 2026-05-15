# Task: MTA-43 Add Patch Component Planner For Cross-Patch Features
**Task ID**: `MTA-43`
**Title**: `Add Patch Component Planner For Cross-Patch Features`
**Status**: `defined`
**Priority**: `core`
**Date**: `2026-05-15`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)

## Problem Statement

Feature geometry, seam changes, protected regions, and future local detail boundaries can cross
patch boundaries. The system needs a bounded component planner that can promote connected patches
when necessary without falling back to accidental full terrain regeneration. Without this planner,
feature-aware topology either risks one-patch lies at boundaries or grows replacement scope in an
uncontrolled way.

This task adds patch component planning above the adaptive mesh planner while preserving
PatchLifecycle ownership and dirty-window performance semantics.

## Goals

- Build bounded patch dependency components for feature, seam, protected-region, local-detail, and
  conformance needs.
- Distinguish affected, replacement, conformance, retained-boundary, and safety-margin patch roles.
- Promote connected patches only when feature correctness or seam contracts require it.
- Refuse or safely fall back when required promotion exceeds policy budget.
- Prove bounded component behavior with hosted replay evidence, timing, face count, dirty-window
  scope, patch scope, and verdict.

## Acceptance Criteria

```gherkin
Scenario: Cross-patch feature dependencies produce bounded components
  Given feature geometry or seam changes that cross patch boundaries
  When output planning runs through hosted public terrain commands
  Then the planner identifies connected patch components required for correctness
  And each patch role is classified as affected, replacement, conformance, retained-boundary, or safety-margin
  And replacement scope remains bounded to the required component rather than full terrain regeneration

Scenario: Component promotion respects policy budgets
  Given a feature dependency graph that would require broad patch promotion
  When required promotion exceeds configured policy limits
  Then the command refuses or safely falls back before mutation
  And old output remains intact
  And diagnostics explain the promotion budget outcome internally without leaking patch internals publicly

Scenario: Dirty-window performance semantics are preserved
  Given local terrain edits that do not require cross-patch promotion
  When the MTA-43 planner runs
  Then replacement remains patch-local or limited to existing conformance scope
  And unaffected patches remain outside the replacement set
  And local edits do not become full terrain regeneration by default

Scenario: Live evidence is recorded for the same baseline corpus
  Given the MTA-38 replay corpus and MTA-42 seam contracts
  When MTA-43 verification completes
  Then every relevant replay row records before/after timing
  And every relevant replay row records before/after face count
  And every relevant replay row records component size, patch roles, dirty-window scope, and promotion/refusal decisions
  And fallback/refusal/no-delete outcomes are recorded where applicable
  And the task records a verdict of improved, neutral, regressed, or failed for each row
```

## Non-Goals

- Adding sparse local detail state or composed height oracle behavior.
- Adding local CDT islands, native acceleration, public backend selection, or global terrain
  regeneration as the normal cross-patch solution.
- Replacing PatchLifecycle as owner of patch identity and SketchUp mutation.
- Exposing patch component internals in public MCP responses.

## Business Constraints

- Cross-patch correctness must not erase the product value of fast local edits.
- Promotion limits and refusal behavior must be deterministic and explainable.
- Hosted evidence must show whether component planning preserves bounded edit behavior.

## Technical Constraints

- `MTA-42` seam contract behavior must exist before component planning depends on retained spans and
  seam promotion rules.
- Component planning must operate in terrain owner-local/sample-aware coordinates.
- Patch role classification must remain derived planning metadata.
- Old output must survive failed component planning, validation, or mutation.
- Public command contracts and response shapes must remain unchanged.

## Dependencies

- `MTA-42`
- `MTA-40`
- `MTA-39`
- `MTA-38`
- `MTA-36`
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)

## Relationships

- blocks `MTA-44`
- does not require optional `MTA-41`
- informs any later local CDT island or native acceleration decision

## Related Technical Plan

- none yet

## Success Metrics

- Cross-patch replay rows produce bounded component plans with explicit patch roles.
- Local replay rows remain local when no cross-patch dependency requires promotion.
- Promotion budget failures refuse or fall back before mutation and leave old output intact.
- Timing, face-count, component-size, and patch-role evidence is recorded per replay row.
- Repeated edit and reload/readback evidence remains consistent after component-planned output.
