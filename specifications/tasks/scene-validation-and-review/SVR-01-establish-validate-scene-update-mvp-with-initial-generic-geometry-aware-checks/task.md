# Task: SVR-01 Establish `validate_scene_update` MVP With Initial Generic Geometry-Aware Checks
**Task ID**: `SVR-01`
**Title**: `Establish validate_scene_update MVP With Initial Generic Geometry-Aware Checks`
**Status**: `completed`
**Priority**: `P0`
**Date**: `2026-04-21`

## Linked HLD

- [Scene Validation and Review](../../../hlds/hld-scene-validation-and-review.md)

## Problem Statement

The repository now has Ruby-native runtime seams, targeting resolution helpers, and managed-object metadata conventions, but it still lacks any validation surface for deciding whether a scene update actually satisfied its intended outcome. That leaves agents and operators with a weak acceptance story: tool success can be mistaken for scene correctness, and callers must compose inspection tools or fall back to ad hoc checking when they need evidence that an update is acceptable.

The first validation task needs to close that gap without overreaching into whole-scene auditing, path-specific product shaping, or a proliferation of fine-grained public tools. It must establish `validate_scene_update` as an expectation-scoped validation endpoint that returns a meaningful acceptance verdict and provides at least one generic geometry-aware check family so the result is materially more valuable than inspection tooling alone.

## Goals

- establish `validate_scene_update` as the first public validation surface for expectation-scoped scene acceptance
- deliver a stable validation result contract with structured findings, warnings, and summary data that downstream workflows can consume programmatically
- provide a first MVP set of validation checks that combines core expectation checks with one initial generic geometry-aware check family

## Acceptance Criteria

```gherkin
Scenario: validate_scene_update validates an explicit expectation-scoped request
  Given a caller provides a documented validation request describing what must exist, be preserved, or satisfy supported expectations
  When `validate_scene_update` is exercised through the MCP surface
  Then the runtime validates only the explicitly requested expectations rather than auditing the whole scene
  And the response is fully JSON-serializable and suitable for agent consumption without text scraping

Scenario: validate_scene_update aligns with the shared selector direction already present in the repo
  Given the repository already exposes shared target-reference and selector behavior for neighboring tools
  When `validate_scene_update` is reviewed in schemas, command behavior, and tests
  Then the task reuses or aligns with that shared selector direction instead of inventing a bespoke validation-only selector grammar
  And the task does not require a broad selector redesign across the existing tool catalog

Scenario: validate_scene_update returns stable structured validation outcomes
  Given a request produces satisfied expectations, blocking failures, or non-blocking warnings
  When the result is reviewed at the Ruby and MCP boundaries
  Then the response reports a structured overall validation outcome with findings and summary data
  And each finding maps back to the relevant expectation or target in a stable, automation-friendly form

Scenario: validate_scene_update supports the confirmed MVP expectation families
  Given a validation request references supported scene targets and supported MVP expectations
  When the request is executed
  Then the tool supports checks for required existence, preservation, metadata requirements, specified tag requirements, and specified material requirements
  And unresolved or ambiguous target references are reported explicitly rather than being silently accepted

Scenario: validate_scene_update includes an initial generic geometry-aware check family
  Given a validation request includes the documented first geometry-derived expectation family
  When the request is executed against supported targets
  Then the tool evaluates that geometry-derived expectation and returns structured evidence or failure data
  And the delivered geometry-aware check remains generic rather than being tied to one path-specific or workflow-specific product slice

Scenario: the first validation surface is covered by focused automated verification
  Given `validate_scene_update` establishes a new public product boundary
  When the task is reviewed
  Then the change includes focused Ruby and runtime-facing automated coverage for the validation contract, selector alignment, and supported MVP expectation behavior
  And any remaining SketchUp-hosted validation gap for the initial geometry-aware check is explicitly documented if hosted automation is not yet practical
```

## Non-Goals

- implementing whole-scene validation or scene-health auditing
- exposing `measure_scene` as a public tool in this task
- delivering path-specific, terrain-specific, or workflow-specific validation helpers as first-class public tools
- adding richer geometry, topology, asset-integrity, or snapshot-review validation beyond the confirmed MVP boundary

## Business Constraints

- the task must provide a real acceptance step for scene updates rather than leaving correctness to inference from command completion
- the first validation slice must remain generic across product capabilities and must not let one tested workflow narrow the public product direction
- the first validation result must be more valuable than inspection-only tooling by including at least one generic geometry-aware expectation family
- the public validation surface should remain compact and should not proliferate new fine-grained public tools when the capability belongs under `validate_scene_update`

## Technical Constraints

- Ruby must own validation request normalization, target resolution collaboration, check execution, finding shaping, and JSON-safe serialization
- the task must build on the current Ruby-native runtime seams and align with the shared selector direction already present in the repository
- the task must not require a catalog-wide selector redesign or broad shared-helper extraction to be considered complete
- the initial geometry-aware check family must remain intentionally bounded and generic so the task does not turn into a broad measurement or interrogation initiative
- public contract changes must update runtime schemas, tests, and user-facing docs in the same change

## Dependencies

- `STI-01`
- [Scene Validation and Review HLD](../../../hlds/hld-scene-validation-and-review.md)
- [PRD: Scene Validation and Review](../../../prds/prd-scene-validation-and-review.md)

## Relationships

- blocks the deferred richer-geometry validation follow-on for `validate_scene_update`
- informs the deferred public `measure_scene` follow-on by establishing the first validation result and selector-alignment posture

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- representative scene-update workflows can request an explicit validation verdict without falling back to ad hoc inspection logic alone
- the first validation surface returns stable structured findings and summary data that downstream automation can consume directly
- the delivered MVP includes at least one generic geometry-derived validation expectation that makes the first release materially more useful than inspection-only tooling
