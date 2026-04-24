# Task: SVR-03 Establish `measure_scene` MVP With Structured Measurement Modes
**Task ID**: `SVR-03`
**Title**: `Establish measure_scene MVP With Structured Measurement Modes`
**Status**: `completed`
**Priority**: `P1`
**Date**: `2026-04-24`

## Linked HLD

- [Scene Validation and Review](../../../hlds/hld-scene-validation-and-review.md)

## Problem Statement

The scene-validation capability HLD and PRD both define `measure_scene` as a distinct public workflow surface alongside `validate_scene_update`. The current task posture, however, folded measurement-driven work into `validate_scene_update` before a public measurement contract existed. That weakens the intended capability boundary by mixing direct interrogation with acceptance validation and leaves agents without a first-class structured way to ask basic fit, size, clearance, or placement questions without falling back to arbitrary Ruby.

This task should restore the intended boundary by shipping `measure_scene` as the public structured measurement surface first. `measure_scene` should answer direct measurement questions through documented modes and structured outputs, while `validate_scene_update` remains the primary acceptance endpoint that may later consume the same measurement evidence internally. Measured dimension pass/fail logic inside validation is therefore a later follow-on, not the main scope of this task.

## Goals

- deliver `measure_scene` as a first-class public MCP tool for structured scene measurements
- support a bounded initial measurement mode set that covers common size and fit questions without arbitrary Ruby
- keep measurement requests and responses compact, JSON-serializable, and explicit about units and evidence
- align measurement targeting with the same workflow-facing identity posture used by neighboring tools
- establish reusable measurement behavior that later validation work can depend on without redefining measurement logic

## Acceptance Criteria

```gherkin
Scenario: measure_scene supports documented structured measurement modes
  Given a caller provides a valid measurement request for a supported target and supported measurement mode
  When `measure_scene` is exercised through the MCP surface
  Then the runtime returns a structured measurement result
  And the result uses a documented shape rather than free-form text

Scenario: measure_scene ships a bounded initial public measurement mode set
  Given the first public measurement surface is being reviewed
  When schemas, docs, and tests are examined together
  Then `measure_scene` supports documented initial modes for `distance`, `area`, `height`, and `bounds`
  And `area` requests require an explicit area meaning rather than relying on an ambiguous generic area interpretation
  And unsupported modes remain explicit rather than silently heuristic

Scenario: measurement contracts use workflow-facing references and explicit units
  Given a caller measures scene state through the public MCP contract
  When the request is executed
  Then the contract prefers workflow-facing references such as `sourceElementId`, supports `persistentId` where runtime-safe lookup is needed, and keeps `entityId` compatibility-only
  And the returned measurement values expose documented public-unit semantics without leaking SketchUp internal units

Scenario: unsupported target or mode combinations stay bounded and diagnosable
  Given a caller requests a measurement mode or target combination outside the delivered support set
  When the request is executed
  Then the runtime returns a structured refusal or measurement error that makes the limitation explicit
  And the task does not imply support for unrestricted arbitrary-property interrogation

Scenario: measure_scene remains distinct from validation and debugging escape hatches
  Given the capability already includes `validate_scene_update` as the primary acceptance endpoint
  When this task is reviewed in schemas, docs, and tests
  Then `measure_scene` remains the direct structured measurement surface rather than a validation verdict tool
  And the task does not make `eval_ruby` or raw internal dictionaries part of the normal measurement path

Scenario: the public measurement surface lands with focused verification
  Given this task introduces a new public MCP tool
  When the task is reviewed
  Then the change includes focused Ruby and runtime-facing coverage for the delivered measurement modes, result shapes, and refusal behavior
  And any remaining SketchUp-hosted validation gaps for geometry-sensitive measurement modes are explicitly documented if hosted automation is not yet practical
```

## Non-Goals

- extending `validate_scene_update` with measured dimension or tolerance pass/fail logic in this task
- treating persisted semantic stored values as the meaning of geometric measurement
- creating a standalone public tool for raw semantic metadata or dictionary inspection
- exposing unrestricted measurement over arbitrary properties or arbitrary target types
- implementing `path_length`, `clearance`, or `slope_hint` measurement modes in this task
- implementing review snapshot capture, asset-integrity validation, or topology-heavy validation beyond the measurement slice

## Business Constraints

- the capability must keep `measure_scene` and `validate_scene_update` as distinct workflow surfaces with clear preference rules
- the public measurement surface should reduce routine fallback to arbitrary Ruby for direct fit, size, and clearance questions
- the delivered contract must be clear enough that callers can tell which measurement modes and target combinations are supported before execution
- the measurement result must remain useful for downstream automation rather than requiring free-form parsing or manual interpretation

## Technical Constraints

- Ruby must own measurement request normalization, target resolution collaboration, measurement execution, and JSON-safe serialization
- the task must align with the existing shared target-reference and selector posture already used by neighboring tools
- measurement outputs must keep units, evidence, and result meaning explicit at the MCP boundary
- where measurement overlaps with targeting and interrogation behavior such as bounds or surface sampling, the task must reuse those seams rather than create a second geometry-probing subsystem
- the public contract changes must update runtime schemas, tests, and user-facing docs in the same change
- the resulting measurement behavior should remain reusable by later validation work rather than becoming a public-only dead-end

## Dependencies

- `STI-02`
- [Scene Validation and Review HLD](../../../hlds/hld-scene-validation-and-review.md)
- [PRD: Scene Validation and Review](../../../prds/prd-scene-validation-and-review.md)
- [PRD: Scene Targeting and Interrogation](../../../prds/prd-scene-targeting-and-interrogation.md)

## Relationships

- follows `SVR-01` by adding the companion public measurement surface after the first validation MVP landed
- should precede any follow-on that adds measured dimension or tolerance verdicts inside `validate_scene_update`
- informs later validation work by establishing the reusable measurement contract and evidence posture first
- remains adjacent to `SVR-02`, which continues to broaden `validate_scene_update` with geometry-relationship checks rather than direct measurement modes

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- representative measurement workflows can answer structured distance, area, height, and bounds questions through `measure_scene` without arbitrary Ruby
- unsupported mode or target combinations return predictable structured failures instead of ambiguous partial results
- runtime schemas and user-facing docs describe the delivered measurement contract closely enough that supported versus unsupported usage is predictable before execution
- the delivered measurement contract is reusable enough that later validation work can depend on it instead of rebuilding geometry-derived evidence locally
