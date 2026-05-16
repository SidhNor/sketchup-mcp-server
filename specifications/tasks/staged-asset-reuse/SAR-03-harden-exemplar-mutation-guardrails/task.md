# Task: SAR-03 Harden Exemplar Mutation Guardrails
**Task ID**: `SAR-03`
**Title**: `Harden Exemplar Mutation Guardrails`
**Status**: `cancelled`
**Priority**: `P1`
**Date**: `2026-04-25`

## Linked HLD

- [Asset Exemplar Reuse](specifications/hlds/hld-asset-exemplar-reuse.md)

## Problem Statement

Approved Asset Exemplars must remain reliable source objects for reuse workflows, but they are still ordinary in-scene SketchUp objects that designers and agents may need to maintain intentionally. The original SAR-03 framing treated approved exemplars as protected from normal mutation tools, which would block deliberate library maintenance through the same explicit target-based edit commands used elsewhere.

The shipped SAR-02 implementation already covers the essential reuse invariant: instantiation creates a separate editable Asset Instance, clears exemplar-only fields on the copy, records source lineage, and leaves the source Asset Exemplar unchanged. Generic mutation tools require explicit target references, so the remaining risk is not implicit accidental mutation during reuse, but an intentional command targeting an exemplar directly.

This task is cancelled as a runtime guardrail slice. The retained policy is that reuse workflows must not mutate source exemplars implicitly; explicit generic mutation of an explicitly targeted exemplar remains allowed.

## Goals

- preserve SAR-02 source-stability semantics as the asset-reuse guardrail
- allow explicit generic mutation commands to operate on explicitly targeted Asset Exemplars
- avoid adding a duplicate exemplar-maintenance MCP surface for delete, transform, material, or metadata edits
- keep Asset Exemplars and Asset Instances distinct through metadata and source lineage
- keep future replacement flows responsible for not mutating selected source exemplars implicitly

## Acceptance Criteria

```gherkin
Scenario: reuse workflows preserve source exemplars
  Given an approved Asset Exemplar is selected for reuse
  When an instantiation or replacement workflow uses the exemplar as a source
  Then the workflow creates or updates an Asset Instance representation
  And the source exemplar is not mutated as an implicit side effect

Scenario: explicit mutation of a targeted exemplar remains allowed
  Given an approved Asset Exemplar exists in the staged asset library
  When a supported generic mutation command explicitly targets that exemplar
  Then the command is evaluated under the normal target-specific mutation rules
  And no exemplar-specific runtime refusal is required solely because the target is an approved exemplar

Scenario: Asset Instances remain distinct from exemplars
  Given an editable Asset Instance was created from an Asset Exemplar
  When staged-asset discovery or mutation policy evaluates the instance
  Then the instance is not classified as an Asset Exemplar
  And the instance remains governed by normal Managed Scene Object rules where applicable
```

## Non-Goals

- adding runtime refusals to generic mutation tools solely because the target is an approved Asset Exemplar
- creating a separate exemplar-maintenance MCP surface that duplicates existing generic mutation tools
- creating a full scene-wide asset integrity validator
- preventing arbitrary manual SketchUp UI edits
- adding live 3D Warehouse or external asset-management behavior
- replacing proxies with staged assets
- adding definition-level asset-locking policy

## Business Constraints

- reuse workflows must not modify approved Asset Exemplars in place as an implicit side effect
- explicitly targeted exemplar maintenance remains possible through normal mutation surfaces
- Asset Instances remain editable design-scene objects even when derived from approved exemplars
- grouped project asset libraries must remain usable as human staging areas without turning every component definition instance into a protected library object

## Technical Constraints

- no new public MCP tool surface should be introduced only to bypass a generic-mutation refusal
- source-stability checks belong in reuse workflows such as instantiation and replacement
- public tool registration and dispatcher behavior should not change for the cancelled SAR-03 guardrail
- task dependencies must not require SAR-03 before replacement work can proceed

## Dependencies

- `SAR-01`
- `SAR-02`
- [Asset Exemplar Reuse HLD](specifications/hlds/hld-asset-exemplar-reuse.md)
- [PRD: Staged Asset Reuse](specifications/prds/prd-staged-asset-reuse.md)
- [Low-Poly Garden Vegetation Inventory](specifications/research/asset-reuse/low_poly_garden_vegetation_inventory.md)

## Relationships

- cancelled after SAR-02 confirmed source-stability and Asset Instance separation semantics
- superseded by explicit source-stability requirements in SAR-02 and SAR-04
- removed as a dependency for `SAR-04`

## Related Technical Plan

- none yet

## Success Metrics

- no SAR-03 implementation plan is created for runtime mutation refusals
- SAR-04 can proceed without a SAR-03 dependency
- asset-reuse specs distinguish implicit reuse-flow source mutation from explicit targeted exemplar maintenance
