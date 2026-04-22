# Task: SVR-02 Broaden `validate_scene_update` With Surface-Relationship And Reference-Point Validation
**Task ID**: `SVR-02`
**Title**: `Broaden validate_scene_update With Surface-Relationship And Reference-Point Validation`
**Status**: `draft`
**Priority**: `P1`
**Date**: `2026-04-21`

## Linked HLD

- [Scene Validation and Review](../../../hlds/hld-scene-validation-and-review.md)

## Problem Statement

`SVR-01` established `validate_scene_update` as an expectation-scoped acceptance endpoint, but the current geometry-aware checks remain intentionally coarse. They can catch missing geometry and some host-level defects, yet they still cannot verify the richer scene-correctness cases called out in the PRD, such as whether a named point lands on the intended surface or whether a reference location still satisfies a required spatial relationship.

That gap matters because downstream workflows often need more than existence and mesh-health signals. They need explicit geometric evidence that a modeled result relates correctly to terrain, reference coordinates, or other scene geometry. This task should broaden `validate_scene_update` with the first richer geometry-aware expectations that can be supported today by reusing the existing explicit surface-interrogation seams, without waiting for full topology analysis or a standalone `measure_scene` surface.

## Goals

- extend `validate_scene_update` with richer geometry-aware expectations that go beyond `SVR-01` mesh-health checks
- support expectation families that validate surface relationships and named or explicit reference-point expectations in a structured, automation-friendly form
- keep the richer validation slice compact by composing the existing targeting and explicit surface-interrogation seams rather than creating workflow-specific micro-tools

## Acceptance Criteria

```gherkin
Scenario: validate_scene_update can validate supported surface-relationship expectations
  Given a caller provides a documented validation request with supported surface-relationship expectations against explicitly resolved targets
  When `validate_scene_update` is exercised through the MCP surface
  Then the runtime evaluates the requested surface relationship using reusable interrogation evidence rather than ad hoc geometry probing
  And the response returns structured findings when the relationship is not satisfied

Scenario: validate_scene_update can validate supported reference-point expectations
  Given a caller provides a documented validation request with supported point or reference-location expectations
  When the request is executed
  Then the tool evaluates the requested point expectation against the resolved target and declared reference data
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
  And topology-backed or edge-network-specific checks are not silently approximated by unrelated surface checks

Scenario: the richer geometry-aware checks are covered by focused verification
  Given this task adds a new geometry-sensitive validation boundary
  When the task is reviewed
  Then the change includes focused Ruby and runtime-facing coverage for the delivered expectation kinds and result shaping
  And any remaining SketchUp-hosted validation gaps for the richer geometry behavior are explicitly documented if hosted automation is not yet practical
```

## Non-Goals

- implementing `measure_scene` as a public tool
- implementing topology-backed or edge-network validation that depends on a deferred topology-analysis seam
- adding path-specific or terrain-specific public helper tools outside `validate_scene_update`
- introducing asset-integrity, asset-placement, or snapshot-review validation in this task

## Business Constraints

- the follow-on must create materially stronger geometry-aware acceptance value than `SVR-01` without fragmenting the public MCP surface
- the richer checks must remain generic enough to support multiple scene-update workflows rather than being shaped around one narrow tested scenario
- the task should make explicit geometry relationships legible to downstream agents without forcing them back to arbitrary Ruby or manual visual inspection as the normal path

## Technical Constraints

- Ruby must continue to own validation request normalization, expectation evaluation, finding shaping, and JSON-safe serialization
- the task must build on `SVR-01` and reuse the existing `targetReference` and `targetSelector` direction already exposed by the runtime
- richer geometry-aware checks must compose the existing explicit surface-interrogation seam rather than duplicate target probing logic inside validation
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

## Related Technical Plan

- none yet

## Success Metrics

- representative geometry-aware validation workflows can express supported surface-relationship or reference-point expectations through `validate_scene_update` without falling back to arbitrary Ruby
- failures in the delivered richer geometry-aware checks return structured findings that clearly correlate to the triggering expectation and target
- the delivered follow-on reuses existing interrogation seams cleanly enough that richer validation behavior does not introduce a second geometry-probing subsystem
