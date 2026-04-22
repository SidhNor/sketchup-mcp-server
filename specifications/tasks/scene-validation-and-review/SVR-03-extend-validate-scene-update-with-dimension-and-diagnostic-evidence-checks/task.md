# Task: SVR-03 Extend `validate_scene_update` With Measured Dimension And Tolerance Checks
**Task ID**: `SVR-03`
**Title**: `Extend validate_scene_update With Measured Dimension And Tolerance Checks`
**Status**: `draft`
**Priority**: `P0`
**Date**: `2026-04-22`

## Linked HLD

- [Scene Validation and Review](../../../hlds/hld-scene-validation-and-review.md)

## Problem Statement

`SVR-01` established `validate_scene_update` as the first expectation-scoped validation endpoint, but the current validation surface still cannot verify whether a modeled result actually satisfies dimension or tolerance expectations such as width, thickness, height, clearance, or similar geometry-facing checks. The live runtime can report existence, metadata, tags, materials, and coarse mesh-health failures, yet it still lacks a reusable measurement-backed path for answering a more basic acceptance question: is the geometry actually the right size within tolerance?

That gap matters because the validation slice is supposed to be the structured correctness signal for scene updates. Tolerance language only makes sense if the runtime is comparing against actual measured or derived geometry evidence rather than merely replaying stored semantic values. Consumer feedback also showed real demand for checking persisted semantic numeric values without `eval_ruby`, but that is a separate concern. This task should therefore extend `validate_scene_update` with measured dimension and tolerance expectations first, keep the public surface compact, and leave semantic stored-value validation as a later distinct follow-on.

## Goals

- extend `validate_scene_update` so it can validate documented measured dimension or tolerance expectations for supported scene targets
- introduce reusable internal measurement-backed evidence for validation without exposing public `measure_scene` yet
- provide structured diagnostic evidence that makes measured dimension failures actionable without requiring arbitrary Ruby or manual probing as the normal path
- keep the public validation surface compact by broadening `validate_scene_update` rather than introducing separate public measurement or debugging micro-tools

## Acceptance Criteria

```gherkin
Scenario: validate_scene_update supports documented dimension or tolerance expectations
  Given a caller provides a valid validation request for a supported scene target with a documented dimension or tolerance expectation
  When `validate_scene_update` is exercised through the MCP surface
  Then the runtime evaluates the requested expectation and returns a structured validation result
  And the result distinguishes satisfied expectations from failing ones without relying on generic metadata-key presence checks alone

Scenario: measured dimension validation uses an explicit contract shape
  Given the validation surface already supports multiple expectation families with distinct ownership
  When this task is reviewed in schemas, documentation, and tests
  Then measured dimension checks use a documented expectation shape of their own rather than being implied through `metadataRequirements`
  And the contract makes the measured property, expected value, and tolerance semantics explicit to callers

Scenario: validate_scene_update evaluates measured dimensions from geometry evidence rather than stored metadata alone
  Given a supported scene target can expose a documented measured dimension through reusable internal measurement evidence
  When a validation request checks that dimension through the delivered expectation shape
  Then the validation result reflects the actual measured or geometry-derived value for the resolved target
  And the task does not treat persisted semantic metadata alone as proof that the geometry satisfies the expectation

Scenario: dimension validation keeps units and tolerance behavior explicit
  Given a dimension or tolerance expectation compares a measured value at the MCP boundary
  When the request is executed
  Then the comparison uses documented public-unit semantics and deterministic tolerance handling
  And the returned evidence exposes the inspected value in a form that downstream automation can interpret without guessing internal SketchUp units

Scenario: dimension and property validation failures return structured diagnostic evidence
  Given a dimension or tolerance expectation fails
  When the caller reviews the validation result
  Then the result includes structured evidence that makes the failure diagnosable through the public contract
  And that evidence identifies the relevant expectation, target, and inspected value or missing-property condition in an automation-friendly form

Scenario: unsupported dimension-property requests remain explicit and bounded
  Given a caller requests a dimension family, target type, or measurement mode outside the delivered scope
  When the request is executed
  Then the runtime returns a structured refusal or validation finding that makes the limitation explicit
  And the task does not imply support for arbitrary attribute-dictionary keys as measured dimension properties

Scenario: richer validation evidence does not create a second public inspection tool
  Given the product already exposes scene inspection and validation as neighboring capabilities
  When this task is reviewed in schemas, command behavior, and documentation
  Then the new capability remains part of `validate_scene_update` rather than becoming a separate public measurement or debugging tool
  And the task does not make arbitrary Ruby or raw internal dictionaries part of the normal correctness path

Scenario: the extended validation surface is covered by focused verification
  Given this task broadens a public validation contract
  When the task is reviewed
  Then the change includes focused Ruby and runtime-facing coverage for the delivered dimension or tolerance behavior and diagnostic result shaping
  And any remaining SketchUp-hosted validation gaps for supported measured-dimension families are explicitly documented if hosted automation is not yet practical
```

## Non-Goals

- exposing `measure_scene` as a public tool in this task
- validating persisted semantic stored values as the primary meaning of dimension checks in this task
- creating a standalone public tool for raw semantic metadata inspection or debugging
- dumping arbitrary SketchUp attribute dictionaries as the default public validation or inspection contract
- supporting unrestricted measured validation over any arbitrary property or target type
- implementing topology-backed, asset-integrity, or snapshot-review validation beyond the scope of this follow-on

## Business Constraints

- the product must keep `validate_scene_update` as the primary correctness signal for scene updates rather than normalizing `eval_ruby` as part of validation workflows
- dimension and tolerance validation should be strong enough to reduce routine fallback to ad hoc inspection when modeled geometry fails acceptance
- the public MCP surface should stay compact and avoid adding a second public tool when the missing capability belongs under the existing validation boundary
- the delivered contract should be clear enough that callers can tell which measured dimension checks are supported without trial-and-error against the runtime

## Technical Constraints

- Ruby must continue to own validation request normalization, expectation evaluation, finding shaping, and JSON-safe serialization inside the validation slice
- the task must align with the existing shared target-reference and selector direction already used by neighboring tools
- dimension or tolerance behavior must keep units and inspected values explicit at the MCP boundary so callers can reason about failures deterministically
- the task must use reusable internal measurement evidence rather than rebranding metadata-key checks as dimension validation
- the task must keep the internal measurement dependency compatible with a later public `measure_scene` surface rather than inventing a validation-only dead-end
- public contract changes must update runtime schemas, tests, and user-facing docs in the same change

## Dependencies

- `SVR-01`
- `STI-02`
- [Scene Validation and Review HLD](../../../hlds/hld-scene-validation-and-review.md)
- [PRD: Scene Validation and Review](../../../prds/prd-scene-validation-and-review.md)
- [PRD: Scene Targeting and Interrogation](../../../prds/prd-scene-targeting-and-interrogation.md)

## Relationships

- follows `SVR-01` by adding measured geometry correctness checks before richer interrogation-backed relationship checks land
- should precede `SVR-02` in the current iteration so measured dimension and tolerance checks land before broader surface/reference-point validation
- informs the deferred public `measure_scene` follow-on by establishing the first reusable internal measurement-backed validation family
- leaves semantic stored-value validation for a later distinct follow-on rather than defining `dimension` checks around persisted metadata

## Related Technical Plan

- none yet

## Success Metrics

- representative scene-update validation flows can express supported measured width-, thickness-, height-, clearance-, or similar expectations through `validate_scene_update` without requiring arbitrary Ruby
- failing measured dimension expectations return enough structured evidence for downstream agents or reviewers to diagnose expected, actual, tolerance, and unsupported-measurement cases from the validation response alone
- the extended validation contract reduces ambiguity about whether a delivered dimension check reflects actual geometry or merely stored metadata
- runtime schemas and user-facing docs describe the delivered measured-dimension contract closely enough that supported versus unsupported checks are predictable before execution
