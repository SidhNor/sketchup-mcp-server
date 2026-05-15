# Task: MTA-38 Establish Feature-Aware Adaptive Baseline, Policy, And Validation Harness
**Task ID**: `MTA-38`
**Title**: `Establish Feature-Aware Adaptive Baseline, Policy, And Validation Harness`
**Status**: `completed`
**Priority**: `core`
**Date**: `2026-05-15`
**Completed**: `2026-05-16`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)

## Problem Statement

Feature-aware adaptive terrain output needs a reliable baseline before mesh behavior changes. The
current production spine already supports authoritative heightmap state, SketchUp-free edit
kernels, dirty-window planning, PatchLifecycle-backed mutation, adaptive output, registry metadata,
and hosted evidence from MTA-36. Later feature-aware tasks must not repeat the CDT failure pattern
of implementing backend changes before the evidence harness proves what changed in rendering,
geometry, and timing.

This task establishes the replay corpus, diagnostics, policy metadata, feature-view traceability,
and validation harness that every later feature-aware adaptive task must use.

## Goals

- Establish a representative replay corpus for accepted production adaptive terrain create and edit
  flows.
- Record current adaptive baseline rendering, geometry counts, timing, and patch/dirty-window scope
  through hosted SketchUp public commands.
- Include representative feature-context shapes across accepted edit modes, including at least one
  intersecting edit sequence that proves overlapping feature views reach output planning.
- Add feature-aware output policy metadata, feature-view digest, policy fingerprint, diagnostics,
  and local tolerance plumbing without materially changing generated geometry.
- Start the validation harness for feature-context, patch scope, dirty-window, output-policy, and
  diagnostic non-interference invariants.
- Define the evidence table format that all later MTA-39 through MTA-44 work must fill in their own
  task acceptance evidence.

## Acceptance Criteria

```gherkin
Scenario: Baseline replay corpus is defined and executable through public commands
  Given the current production adaptive terrain path
  When the baseline replay corpus is executed in hosted SketchUp
  Then each replay row uses public terrain command paths rather than private backend entrypoints
  And the corpus includes accepted create, local edit, adjacent edit, repeated edit, and representative edit-mode cases
  And at least one accepted replay sequence includes intersecting edits with overlapping feature contexts
  And each row records terrain position, patch scope, dirty window, geometry counts, rendering evidence, timing, and verdict

Scenario: Baseline figures are recorded before feature-aware behavior changes
  Given the MTA-38 replay corpus
  When the baseline run completes
  Then current adaptive timing figures are recorded for each replay row
  And current adaptive face and vertex counts are recorded for each replay row
  And rendered geometry shape evidence is recorded for each replay row
  And dirty-window and affected-patch evidence is recorded for each replay row

Scenario: Policy metadata is traceable without materially changing geometry
  Given accepted managed terrain commands with feature context available
  When adaptive output planning runs
  Then the internal output policy records a feature-view digest and policy fingerprint
  And diagnostics can explain which feature context was available to output planning
  And intersecting accepted edits record diagnostics that distinguish composed feature-view context from merely stored feature intent
  And the diagnostic metadata is not consumed by face or vertex generation
  And public MCP command responses preserve their existing compact contract shape

Scenario: Validation harness starts before topology-affecting work
  Given the production adaptive output path
  When the MTA-38 validation harness runs
  Then it can check diagnostic non-interference, patch scope, dirty-window scope, feature-context traceability, and output-policy invariants
  And it can be extended by later tasks for local tolerance, density, forced masks, seams, component promotion, and local detail
```

## Non-Goals

- Changing feature-aware mesh density, topology, forced subdivision, seam contracts, or diagonal choice.
- Creating a fallback matrix or treating fallback behavior as baseline rendering/timing evidence.
- Creating a refusal-focused replay corpus; refusals remain ordinary validation behavior, not
  geometry-producing baseline rows.
- Making reload/readback or public no-leak reporting a core acceptance goal for this baseline task.
- Implementing local detail tiles, local CDT islands, native acceleration, or a public backend selector.
- Replacing the production adaptive TIN path or making generated triangles terrain source of truth.
- Creating after-the-fact evidence tasks that allow later implementation tasks to skip live verification.

## Business Constraints

- The current adaptive patch lifecycle remains the production spine.
- Every later feature-aware adaptive task must prove its own effect with the same hosted replay
  corpus and evidence format.
- The baseline must preserve public command shape and compact public responses.
- Baseline rows must represent accepted public command flows that produce geometry for comparison.

## Technical Constraints

- Terrain state remains authoritative; feature policy metadata is derived planning/output metadata.
- Policy diagnostics must be JSON-serializable and must not carry raw SketchUp objects.
- Hosted verification must use the SketchUp runtime path that public commands use.
- Baseline evidence must be stable enough to support before/after comparison by later tasks.
- Feature-context diagnostics must prove relevant context reached output planning, not only that
  feature intent was stored in terrain state.
- The task must not introduce a global CDT/TIN backend or route production output through CDT.

## Dependencies

- `MTA-20`
- `MTA-21`
- `MTA-23`
- `MTA-36`
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)

## Relationships

- blocks `MTA-39`
- blocks `MTA-40`
- blocks `MTA-41`
- blocks `MTA-42`
- blocks `MTA-43`
- blocks `MTA-44`
- uses `MTA-36` as the primary production-path lifecycle evidence reference
- treats CDT tasks as negative context only, not as implementation templates

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- Baseline replay corpus exists and is executable through hosted public terrain commands.
- Each replay row records baseline timing, geometry counts, rendering evidence, dirty-window/patch
  scope, and verdict.
- At least one accepted replay sequence records intersecting edit evidence for composed feature-view
  context.
- Feature-view digest and output policy fingerprint are recorded internally without public contract expansion.
- Validation harness covers diagnostic non-interference, patch scope, dirty-window scope, feature-context
  traceability, and policy metadata.
- Later tasks can reuse one evidence table format without inventing task-specific proof.
