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

The guardrail slice must cover practical project libraries, including a common group containing approved low-poly vegetation component-instance exemplars. Protection should follow exemplar metadata and approval state even when the exemplar is nested in a library group, and it should not accidentally protect editable Asset Instances merely because they were created from one of the same component definitions.

This task hardens exemplar-aware guardrails across normal mutation paths so approved exemplars are not edited in place by supported workflows.

## Goals

- apply exemplar-aware protection to supported normal mutation tools
- return structured refusals when a protected Asset Exemplar is targeted for unsupported mutation
- preserve the distinction between protected Asset Exemplars and editable Asset Instances
- protect approved exemplars inside grouped project asset libraries without requiring a fixed group name or SketchUp tag/layer convention
- avoid definition-level overreach where a protected exemplar component definition causes unrelated editable instances to be refused
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

Scenario: nested project vegetation exemplars remain protected
  Given approved low-poly vegetation Asset Exemplars are component instances inside a common project vegetation library group
  When a supported delete, transform, material, or metadata mutation command targets one of those exemplar instances
  Then the command returns a structured protected-exemplar refusal
  And the targeted exemplar remains present, approved, and in its library context

Scenario: editable instances sharing a component definition are not over-protected
  Given an approved component-instance Asset Exemplar exists in the project vegetation library
  And an editable Asset Instance was created from the same component definition
  When a supported mutation command targets the editable Asset Instance
  Then protection is evaluated against the target instance metadata
  And the command is not refused merely because the source exemplar or shared definition is protected
```

## Non-Goals

- creating a full scene-wide asset integrity validator
- preventing arbitrary manual SketchUp UI edits outside supported MCP workflows
- adding live 3D Warehouse or external asset-management behavior
- changing public tool names unrelated to exemplar guardrails
- replacing proxies with staged assets
- definition-level asset-locking policy beyond the explicit exemplar predicate

## Business Constraints

- accepted workflows must not modify approved Asset Exemplars in place
- Asset Instances remain editable design-scene objects even when derived from protected exemplars
- guardrails must support the primary KPI around zero accepted exemplar mutations
- grouped project asset libraries must remain usable as human staging areas without turning every component definition instance into a protected library object

## Technical Constraints

- guardrail refusals must be JSON-safe and consistent with existing runtime refusal conventions
- the protection rule must use the Asset Exemplar metadata contract from `SAR-01`
- protection must be instance-aware for component-backed exemplars so editable instances are governed by normal Managed Scene Object mutation rules
- mutation paths must keep tool registration, dispatcher behavior, tests, and docs in sync if public behavior changes
- unrelated mutation behavior must not be broadened or refactored beyond the exemplar guardrail need

## Dependencies

- `SAR-01`
- [Asset Exemplar Reuse HLD](specifications/hlds/hld-asset-exemplar-reuse.md)
- [PRD: Staged Asset Reuse](specifications/prds/prd-staged-asset-reuse.md)
- [Low-Poly Garden Vegetation Inventory](specifications/research/asset-reuse/low_poly_garden_vegetation_inventory.md)
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
- protected low-poly vegetation exemplars remain guarded when nested inside a grouped project library
- editable Asset Instances remain governed by normal editable-object rules
- editable instances sharing source component definitions are not refused solely by definition ancestry
- guardrail refusals are structured, deterministic, and covered by focused tests
- no supported mutation path intentionally changes an approved exemplar in place
