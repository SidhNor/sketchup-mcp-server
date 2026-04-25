# Task: SAR-03 Harden Exemplar Mutation Guardrails
**Task ID**: `SAR-03`
**Title**: `Harden Exemplar Mutation Guardrails`
**Status**: `draft`
**Priority**: `P1`
**Date**: `2026-04-25`

## Linked HLD

- [Asset Exemplar Reuse](specifications/hlds/hld-asset-exemplar-reuse.md)

## Problem Statement

Approved Asset Exemplars must remain protected source objects for reliable reuse. After exemplars can be curated and discovered, normal mutation surfaces such as delete, transform, material updates, and metadata updates could accidentally alter the approved library unless those surfaces recognize exemplar protection rules.

This task hardens exemplar-aware guardrails across normal mutation paths so approved exemplars are not edited in place by supported workflows.

## Goals

- apply exemplar-aware protection to supported normal mutation tools
- return structured refusals when a protected Asset Exemplar is targeted for unsupported mutation
- preserve the distinction between protected Asset Exemplars and editable Asset Instances
- ensure guardrail behavior is testable through existing mutation paths
- keep comprehensive integrity validation deferred to the later validation follow-on

## Acceptance Criteria

```gherkin
Scenario: protected exemplars cannot be deleted through normal mutation tools
  Given an approved Asset Exemplar exists in the staged asset library
  When a supported delete command targets the exemplar
  Then the command returns a structured protected-exemplar refusal
  And the exemplar remains present and approved

Scenario: protected exemplars cannot be transformed through normal mutation tools
  Given an approved Asset Exemplar exists in the staged asset library
  When a supported transform command targets the exemplar
  Then the command returns a structured protected-exemplar refusal
  And the exemplar placement remains unchanged

Scenario: protected exemplars cannot be changed through supported material or metadata mutation paths
  Given an approved Asset Exemplar exists in the staged asset library
  When a supported material or metadata mutation command targets the exemplar
  Then the command returns a structured protected-exemplar refusal
  And protected exemplar metadata remains unchanged

Scenario: editable Asset Instances remain mutable where supported
  Given an editable Asset Instance was created from an Asset Exemplar
  When a supported normal mutation command targets the Asset Instance
  Then the command is evaluated under normal Managed Scene Object mutation rules
  And the instance is not refused merely because it has source asset lineage
```

## Non-Goals

- creating a full scene-wide asset integrity validator
- preventing arbitrary manual SketchUp UI edits outside supported MCP workflows
- adding live 3D Warehouse or external asset-management behavior
- changing public tool names unrelated to exemplar guardrails
- replacing proxies with staged assets

## Business Constraints

- accepted workflows must not modify approved Asset Exemplars in place
- Asset Instances remain editable design-scene objects even when derived from protected exemplars
- guardrails must support the primary KPI around zero accepted exemplar mutations

## Technical Constraints

- guardrail refusals must be JSON-safe and consistent with existing runtime refusal conventions
- the protection rule must use the Asset Exemplar metadata contract from `SAR-01`
- mutation paths must keep tool registration, dispatcher behavior, tests, and docs in sync if public behavior changes
- unrelated mutation behavior must not be broadened or refactored beyond the exemplar guardrail need

## Dependencies

- `SAR-01`
- [Asset Exemplar Reuse HLD](specifications/hlds/hld-asset-exemplar-reuse.md)
- [PRD: Staged Asset Reuse](specifications/prds/prd-staged-asset-reuse.md)
- existing editing and metadata mutation surfaces

## Relationships

- depends on `SAR-01`
- hardens the protection predicate introduced by `SAR-01`
- informs `SAR-04`
- reduces risk for later asset integrity validation

## Related Technical Plan

- none yet

## Success Metrics

- protected exemplars refuse supported delete, transform, material, and metadata mutation attempts
- editable Asset Instances remain governed by normal editable-object rules
- guardrail refusals are structured, deterministic, and covered by focused tests
- no supported mutation path intentionally changes an approved exemplar in place
