# Task: MTA-38 Establish Feature-Aware Adaptive Baseline, Policy, And Validation Harness
**Task ID**: `MTA-38`
**Title**: `Establish Feature-Aware Adaptive Baseline, Policy, And Validation Harness`
**Status**: `defined`
**Priority**: `core`
**Date**: `2026-05-15`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [Recommended Backend Architecture for Feature-Aware Adaptive Terrain Output](../../../research/managed-terrain/recommended_new_adaptive_backend_architecture.md)

## Problem Statement

Feature-aware adaptive terrain output needs a reliable baseline before mesh behavior changes. The
current production spine already supports authoritative heightmap state, SketchUp-free edit
kernels, dirty-window planning, PatchLifecycle-backed mutation, adaptive output, registry/readback,
and hosted evidence from MTA-36. Later feature-aware tasks must not repeat the CDT failure pattern
of implementing backend changes before the evidence harness proves what changed.

This task establishes the replay corpus, diagnostics, policy metadata, feature-view traceability,
and validation harness that every later feature-aware adaptive task must use.

## Goals

- Establish a representative replay corpus for production adaptive terrain create and edit flows.
- Record current adaptive baseline timing, face count, patch/dirty-window scope, fallback/refusal,
  and no-delete behavior through hosted SketchUp public commands.
- Add feature-aware output policy metadata, feature-view digest, policy fingerprint, diagnostics,
  and local tolerance plumbing without materially changing generated geometry.
- Start the validation harness for feature, patch, dirty-window, output-policy, and ownership
  invariants.
- Define the evidence table format that all later MTA-39 through MTA-44 work must fill in their own
  task acceptance evidence.

## Acceptance Criteria

```gherkin
Scenario: Baseline replay corpus is defined and executable through public commands
  Given the current production adaptive terrain path
  When the baseline replay corpus is executed in hosted SketchUp
  Then each replay row uses public terrain command paths rather than private backend entrypoints
  And the corpus includes create, local edit, adjacent edit, repeated edit, feature-intent edit, fallback or refusal, and reload/readback cases
  And each row records terrain position, patch scope, dirty window, face count, timing, and verdict

Scenario: Baseline figures are recorded before feature-aware behavior changes
  Given the MTA-38 replay corpus
  When the baseline run completes
  Then current adaptive timing figures are recorded for each replay row
  And current adaptive face counts are recorded for each replay row
  And dirty-window and affected-patch evidence is recorded for each replay row
  And fallback, refusal, no-delete, no-leak, and registry/readback outcomes are recorded where applicable

Scenario: Policy metadata is traceable without materially changing geometry
  Given a managed terrain command with feature intent available
  When adaptive output planning runs
  Then the internal output policy records a feature-view digest and policy fingerprint
  And diagnostics can explain which feature context was available to output planning
  And generated geometry remains materially equivalent to the pre-task adaptive baseline except for documented diagnostic-only metadata
  And public MCP command responses do not expose raw feature graphs, patch ids, backend selectors, or low-level adaptive internals

Scenario: Validation harness starts before topology-affecting work
  Given the production adaptive output path
  When the MTA-38 validation harness runs
  Then it can check patch ownership, dirty-window scope, no-delete replacement, registry/readback, and output-policy invariants
  And it can be extended by later tasks for local tolerance, density, forced masks, seams, component promotion, and local detail
```

## Non-Goals

- Changing feature-aware mesh density, topology, forced subdivision, seam contracts, or diagonal choice.
- Implementing local detail tiles, local CDT islands, native acceleration, or a public backend selector.
- Replacing the production adaptive TIN path or making generated triangles terrain source of truth.
- Creating after-the-fact evidence tasks that allow later implementation tasks to skip live verification.

## Business Constraints

- The current adaptive patch lifecycle remains the production spine.
- Every later feature-aware adaptive task must prove its own effect with the same hosted replay
  corpus and evidence format.
- The baseline must preserve public command shape and compact public responses.
- Old output must remain protected on refusal or failed replacement.

## Technical Constraints

- Terrain state remains authoritative; feature policy metadata is derived planning/output metadata.
- Policy diagnostics must be JSON-serializable and must not carry raw SketchUp objects.
- Hosted verification must use the SketchUp runtime path that public commands use.
- Baseline evidence must be stable enough to support before/after comparison by later tasks.
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

- none yet

## Success Metrics

- Baseline replay corpus exists and is executable through hosted public terrain commands.
- Each replay row records baseline timing, face count, dirty-window/patch scope, and verdict.
- Feature-view digest and output policy fingerprint are recorded internally without public contract expansion.
- Validation harness covers patch ownership, dirty-window scope, no-delete behavior, registry/readback, and policy metadata.
- Later tasks can reuse one evidence table format without inventing task-specific proof.
