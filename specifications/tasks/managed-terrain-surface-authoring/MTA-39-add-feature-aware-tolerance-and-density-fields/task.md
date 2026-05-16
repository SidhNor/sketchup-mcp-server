# Task: MTA-39 Add Feature-Aware Tolerance And Density Fields
**Task ID**: `MTA-39`
**Title**: `Add Feature-Aware Tolerance And Density Fields`
**Status**: `planned`
**Priority**: `core`
**Date**: `2026-05-15`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)

## Problem Statement

The production adaptive mesher currently uses a broadly fixed simplification policy. It can keep
height error bounded, but it does not allocate triangles based on feature intent, protected areas,
survey controls, corridors, planar regions, target-height edits, or fairing pressure. As a result,
important feature regions may be underrepresented while unimportant regions may receive the same
output policy.

This task makes feature intent operational for low-risk adaptive output behavior by adding local
tolerance and target density fields while preserving the current adaptive production spine.

## Goals

- Use the collated feature view to produce local simplification tolerance for adaptive output.
- Use feature pressure to produce local target cell-size or density pressure for adaptive output.
- Keep the current adaptive patch/cell terrain output path as the production route.
- Preserve PatchLifecycle ownership, dirty-window behavior, registry/readback, no-delete mutation,
  and public command contracts.
- Prove the change with the MTA-38 replay corpus, including before/after timing, face count,
  patch scope, dirty-window scope, and a clear verdict.

## Acceptance Criteria

```gherkin
Scenario: Feature-aware local tolerance influences adaptive output
  Given a managed terrain replay row with feature intent and an MTA-38 baseline
  When adaptive output is regenerated through the hosted public command path
  Then local simplification tolerance is derived from feature role, strength, proximity, and terrain context
  And important feature regions can use stricter tolerance than normal terrain
  And soft or fairing regions cannot weaken hard or protected feature policy
  And public command responses remain contract-compatible and compact

Scenario: Feature pressure influences adaptive output density
  Given feature intent for corridors, survey controls, target regions, planar regions, or fairing regions
  When adaptive output planning evaluates local density pressure
  Then target density or target cell-size pressure is available to the adaptive output policy
  And feature-influenced density remains bounded by task policy and patch/window budgets
  And any face count increase is attributable to relevant local feature windows rather than unexplained global growth

Scenario: Existing patch lifecycle semantics are preserved
  Given a terrain with existing adaptive patch ownership from the production path
  When a valid local edit is replayed after tolerance and density fields are enabled
  Then dirty-window mapping remains bounded to affected patches and required conformance scope
  And old output remains until replacement output validates
  And registry/readback remains consistent after repeated edits and reload/readback checks

Scenario: Live evidence is recorded for the same baseline corpus
  Given the MTA-38 replay corpus and baseline figures
  When MTA-39 verification completes
  Then every relevant replay row records before/after timing
  And every relevant replay row records before/after face count
  And every relevant replay row records dirty-window and patch-scope evidence
  And every relevant replay row records fallback/refusal/no-delete outcomes where applicable
  And the task records a verdict of improved, neutral, regressed, or failed for each row
```

## Non-Goals

- Forcing hard feature topology or protected boundaries to be represented exactly.
- Adding seam lattice upgrades, patch component promotion, sparse local detail tiles, CDT islands,
  native acceleration, or public backend selection.
- Exposing feature graphs, patch ids, raw triangles, or output-policy internals in public responses.
- Treating generated mesh vertices or faces as durable terrain state.

## Business Constraints

- The task must improve or explain output allocation without destabilizing the proven adaptive path.
- Hosted evidence is part of task completion, not a later release-readiness task.
- Performance and face-count changes must be reported against the same MTA-38 replay corpus.
- Feature-aware output must remain reversible through existing fallback/refusal behavior.

## Technical Constraints

- `MTA-38` policy scaffolding and replay corpus must exist before this task is implemented.
- Feature intent and feature geometry are planning inputs; terrain heightmap state remains
  authoritative.
- Local tolerance and density fields must be deterministic for repeated runs over the same state.
- PatchLifecycle mutation, registry/readback, and public MCP command shapes must remain unchanged.
- The production path must remain adaptive patch/cell output, not CDT.

## Dependencies

- `MTA-38`
- `MTA-20`
- `MTA-36`
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)

## Relationships

- blocks `MTA-40`
- recommended before optional `MTA-41`
- informs `MTA-42` because seam policy must account for feature-driven density and tolerance

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- Feature-aware local tolerance and density pressure are visible in internal diagnostics.
- Hosted replay rows show timing, face-count, and patch-scope deltas against MTA-38 baselines.
- Face-count growth, if present, is localized and explained by feature relevance.
- Repeated edit, adjacent edit, fallback/refusal, and reload/readback rows preserve MTA-36 lifecycle behavior.
- No public command contract or response-shape change is required.
