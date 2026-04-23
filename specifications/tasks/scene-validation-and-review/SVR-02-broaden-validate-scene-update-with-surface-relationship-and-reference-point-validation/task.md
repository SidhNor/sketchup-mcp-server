# Task: SVR-02 Broaden `validate_scene_update` With Surface-Relationship And Reference-Point Validation
**Task ID**: `SVR-02`
**Title**: `Broaden validate_scene_update With Object-Anchor Surface-Offset Validation`
**Status**: `completed`
**Priority**: `P1`
**Date**: `2026-04-21`

## Linked HLD

- [Scene Validation and Review](../../../hlds/hld-scene-validation-and-review.md)

## Problem Statement

`SVR-01` established `validate_scene_update` as an expectation-scoped acceptance endpoint, but the current geometry-aware checks remain intentionally coarse. They can catch missing geometry and some host-level defects, yet they still cannot verify whether reference points derived from the modeled result still satisfy the intended vertical relationship to an explicit target surface.

That gap matters because downstream workflows often derive terrain-relative expectations before or during creation, then need a post-build acceptance check that the actual modeled geometry still preserves those relationships. A validation mode that only replays caller-supplied world points is not strong enough for that goal. This task should therefore broaden `validate_scene_update` with a first richer geometry-aware expectation that derives documented anchor or reference points from an explicitly resolved modeled target, compares them against an explicit target surface using expected vertical offset and tolerance, and reuses the existing explicit surface-interrogation seams without waiting for full topology analysis or a standalone `measure_scene` surface. The delivered contract should stay narrow by supporting one explicit surface-offset relationship meaning in this task while using a generic derived-anchor selection model rather than arbitrary free-form point lists.

## Goals

- extend `validate_scene_update` with a richer geometry-aware expectation that goes beyond `SVR-01` mesh-health checks
- support structured validation of object-derived anchor or reference points against an explicit target surface using expected vertical offset and tolerance
- keep the richer validation slice compact by composing the existing targeting and explicit surface-interrogation seams rather than creating workflow-specific micro-tools
- keep the first delivered contract generic and reusable by using documented derived-anchor selection rather than object-family-specific public vocabulary

## Acceptance Criteria

```gherkin
Scenario: validate_scene_update can validate supported surface-offset expectations at object-derived anchor points
  Given a caller provides a documented validation request with an explicit modeled target, a documented derived-anchor selector, an explicit target surface, expected vertical offsets, and supported tolerances
  When `validate_scene_update` is exercised through the MCP surface
  Then the runtime derives the requested anchor points from the resolved modeled geometry and evaluates each point-to-surface relationship using reusable interrogation evidence rather than ad hoc geometry probing
  And the response returns structured findings when a derived point misses the target surface, resolves ambiguously, or does not satisfy the expected offset within tolerance

Scenario: validate_scene_update ties richer validation to the modeled result rather than only to caller-supplied world coordinates
  Given a caller provides a documented validation request for a modeled result and a documented derived-anchor selector
  When the request is executed
  Then the tool evaluates anchor or reference points derived from the resolved modeled target against the resolved target surface
  And any resulting failure maps back to the relevant expectation in a stable, automation-friendly form

Scenario: richer geometry-aware validation stays expectation-scoped and compact
  Given `validate_scene_update` already exists as the primary validation endpoint
  When this task is reviewed in schemas, command behavior, and tests
  Then the richer geometry-aware checks remain part of `validate_scene_update` rather than becoming new public validation micro-tools
  And the task does not broaden into whole-scene auditing or a standalone measurement surface

Scenario: the richer validation surface reuses the existing targeting and interrogation direction
  Given the repository already exposes shared target-resolution behavior and explicit surface sampling
  When the task is reviewed
  Then the validation contract reuses the existing selector and target-reference direction
  And the geometry-aware checks compose existing explicit interrogation seams instead of defining a second probing subsystem inside validation

Scenario: unsupported or out-of-scope richer geometry requests remain explicit
  Given a caller requests a geometry-aware expectation that is unsupported, unresolved, or outside the delivered follow-on scope
  When the request is executed
  Then the runtime returns a structured refusal or validation failure that makes the limitation explicit
  And topology-backed, edge-network-specific, or broad terrain-measurement checks are not silently approximated by the delivered point-to-surface-offset check

Scenario: the richer geometry-aware checks are covered by focused verification
  Given this task adds a new geometry-sensitive validation boundary
  When the task is reviewed
  Then the change includes focused Ruby and runtime-facing coverage for the delivered expectation kinds and result shaping
  And any remaining SketchUp-hosted validation gaps for the richer geometry behavior are explicitly documented if hosted automation is not yet practical
```

## Non-Goals

- implementing `measure_scene` as a public tool
- implementing topology-backed or edge-network validation that depends on a deferred topology-analysis seam
- adding path-specific, house-specific, or terrain-specific public helper tools outside `validate_scene_update`
- validating broad terrain clearances, overlaps, or unsupported-object heuristics beyond the delivered anchor-to-surface-offset contract
- supporting arbitrary free-form point lists that are not tied to the modeled result being validated
- defining a broad multi-relationship validation framework in this task beyond the first delivered surface-offset meaning
- introducing asset-integrity, asset-placement, or snapshot-review validation in this task

## Business Constraints

- the follow-on must create materially stronger geometry-aware acceptance value than `SVR-01` without fragmenting the public MCP surface
- the richer checks must remain generic enough to support multiple scene-update workflows rather than being shaped around one narrow tested scenario
- the task should make explicit geometry relationships legible to downstream agents without forcing them back to arbitrary Ruby or manual visual inspection as the normal path
- the delivered contract should be useful for workflows that derive terrain-relative expectations from prior surface sampling, then need post-build acceptance of the resulting modeled geometry
- the delivered check must validate the built result strongly enough to catch regressions such as moved, floating, or unexpectedly intersecting managed objects after terrain changes
- the delivered contract should stay compact enough for MCP clients to discover and use programmatically without a second nested relationship framework in this task

## Technical Constraints

- Ruby must continue to own validation request normalization, expectation evaluation, finding shaping, and JSON-safe serialization
- the task must build on `SVR-01` and reuse the existing `targetReference` and `targetSelector` direction already exposed by the runtime
- richer geometry-aware checks must compose the existing explicit surface-interrogation seam rather than duplicate target probing logic inside validation
- the delivered expectation must derive anchor or reference points from the resolved modeled target using a documented derived-anchor selection contract rather than only replaying caller-supplied world coordinates
- the task must keep the anchor-selection contract generic enough to support multiple managed-object workflows without requiring house- or slab-specific public vocabulary
- the delivered comparison must keep expected offset and tolerance semantics explicit at the MCP boundary
- the delivered contract should expose one narrow surface-offset relationship meaning in this task and defer additional relationship meanings until they are justified by later follow-ons
- the task must not claim topology-backed validation until the targeting and interrogation slice exposes reusable topology evidence strongly enough for validation consumption
- public contract changes must update runtime schemas, tests, and user-facing docs in the same change

## Dependencies

- `SVR-01`
- `STI-02`
- [Scene Validation and Review HLD](../../../hlds/hld-scene-validation-and-review.md)
- [PRD: Scene Validation and Review](../../../prds/prd-scene-validation-and-review.md)
- [PRD: Scene Targeting and Interrogation](../../../prds/prd-scene-targeting-and-interrogation.md)

## Relationships

- follows `SVR-03` in the current iteration so measured dimension and tolerance checks land before richer interrogation-backed geometry relationships
- informs the deferred topology-backed validation expansion for `validate_scene_update`
- informs the deferred public `measure_scene` follow-on by clarifying which geometry relationships belong in validation versus direct measurement
- informs the deferred terrain-relationship validation follow-on by establishing a first object-anchor-to-surface-offset expectation shape without claiming broader terrain diagnostics

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- representative geometry-aware validation workflows can express supported object-anchor-to-surface-offset expectations through `validate_scene_update` without falling back to arbitrary Ruby
- failures in the delivered richer geometry-aware checks return structured findings that clearly correlate to the triggering expectation and target
- the delivered follow-on reuses existing interrogation seams cleanly enough that richer validation behavior does not introduce a second geometry-probing subsystem
