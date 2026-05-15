# Task: SAR-02 Instantiate Editable Asset Instances
**Task ID**: `SAR-02`
**Title**: `Instantiate Editable Asset Instances`
**Status**: `draft`
**Priority**: `P1`
**Date**: `2026-04-25`

## Linked HLD

- [Asset Exemplar Reuse](specifications/hlds/hld-asset-exemplar-reuse.md)

## Problem Statement

Approved Asset Exemplars are useful only when agents can create separate editable scene objects from them without damaging the curated source asset. Today, there is no `instantiate_staged_asset` tool and no runtime behavior that creates an Asset Instance with source lineage, managed-scene identity, placement, and serialization.

The instantiation slice must also support project-scoped asset sets such as the low-poly garden vegetation library captured in `specifications/research/asset-reuse/low_poly_garden_vegetation_inventory.md`. In that setup, a common group may contain many reusable vegetation component instances, and each exemplar may carry category-specific `assetAttributes` such as asset key, archetype, represented species, planting role, intended design height, height class, style, variant hints, and usage notes. Those vegetation fields are examples, not universal requirements. Instantiation should work from approved component-instance exemplars without depending on one fixed group name or exact scene hierarchy.

This task delivers controlled instantiation from approved exemplars into the editable design scene.

## Goals

- expose `instantiate_staged_asset` for approved Asset Exemplars
- create a separate editable Asset Instance without mutating the source exemplar
- support position-only minimum placement into model root, with optional direct scale variation
- support grouped project asset sets whose exemplars are component instances or groups organized inside a common library group
- preserve source asset-set and category-specific asset metadata on the created Asset Instance where present
- carry category-specific scale or height metadata as structured evidence when present, without auto-fitting target height
- write source asset lineage metadata on the created Asset Instance
- mark created instances as editable Managed Scene Objects where required by the domain model
- return JSON-safe instantiation evidence and structured refusals

## Acceptance Criteria

```gherkin
Scenario: an approved exemplar is instantiated into the design scene
  Given an approved Asset Exemplar can be resolved
  When `instantiate_staged_asset` is called with supported placement input
  Then a separate editable Asset Instance is created in the design scene
  And the source Asset Exemplar remains in the staging area without expected mutation
  And the result includes JSON-safe identity, lineage, placement, and bounds summary data

Scenario: source asset lineage is written on the created instance
  Given an Asset Instance was created from an approved Asset Exemplar with caller-supplied `metadata.sourceElementId`
  When the created instance metadata is reviewed
  Then it includes source asset lineage metadata
  And it is not classified as an Asset Exemplar
  And it satisfies the required Managed Scene Object identity rules for editable scene objects

Scenario: unsupported instantiation requests refuse clearly
  Given the requested exemplar is missing, ambiguous, unapproved, or fails required integrity checks
  When `instantiate_staged_asset` is called
  Then the command returns a structured refusal with actionable reason data
  And it does not create a partial Asset Instance as the expected outcome

Scenario: placement inputs are reflected in the result
  Given a supported model-root position payload is provided
  When the Asset Instance is created
  Then the serialized result reflects the applied placement
  And when optional direct scale is provided the serialized result reflects the applied scale
  And the response avoids raw SketchUp objects

Scenario: a project vegetation asset-set exemplar is instantiated
  Given an approved Asset Exemplar is a component instance inside a grouped project vegetation library
  And the exemplar includes vegetation-specific asset attributes such as asset key, archetype, represented species, planting role, intended design height, height class, style, variant hints, and usage notes
  When `instantiate_staged_asset` creates an Asset Instance from that exemplar
  Then the library exemplar remains in its original grouped staging context
  And the created Asset Instance records source exemplar lineage
  And the created Asset Instance preserves source asset-set metadata needed for later discovery, validation, and replacement
  And the result includes JSON-safe evidence of the selected exemplar and applied placement

Scenario: instantiation does not depend on a fixed library hierarchy
  Given approved Asset Exemplars may be organized in a common group, staging collection, or equivalent metadata-backed library convention
  When a supported exemplar reference resolves uniquely
  Then instantiation succeeds or refuses based on exemplar approval, integrity, and placement rules
  And it does not require a hard-coded group name, exact nesting depth, or SketchUp tag/layer value
```

## Non-Goals

- curation or approval of new Asset Exemplars
- replacement of existing proxies or lower-fidelity objects
- comprehensive asset integrity validation across the whole model
- live 3D Warehouse search or asset import
- advanced ranking, recommendation, or category-library behavior
- broad copy-versus-component policy beyond the first supported instantiation behavior
- target-height fitting or automatic rescaling from vegetation height metadata
- parent/collection placement options beyond model-root creation
- rigid digital asset management behavior for project asset sets
- requiring all staged asset libraries to use the same group name, nesting pattern, or SketchUp tag/layer convention

## Business Constraints

- Asset Instances must be editable scene objects, not renamed or moved Asset Exemplars
- source lineage must be available for later replacement, validation, and review workflows
- instantiation must support reliable reuse of curated assets without arbitrary geometry generation
- grouped in-model component libraries are a supported project staging pattern, but metadata and approval state remain the product source of truth

## Technical Constraints

- outputs must be JSON-serializable and must not expose raw SketchUp objects
- mutation must be a coherent SketchUp operation where practical
- MCP tool registration, dispatcher behavior, tests, and user-facing docs must stay in sync for the new instantiation surface
- instantiation must consume the metadata and approval contract established by `SAR-01`
- created Asset Instances must require caller-supplied `metadata.sourceElementId`; SAR-02 must not silently generate workflow identity
- instantiation must preserve JSON-safe asset metadata from SAR-01, including optional project asset-set and category-specific fields, without exposing raw SketchUp objects
- failures must not leave expected partial instance state

## Dependencies

- `SAR-01`
- [Asset Exemplar Reuse HLD](specifications/hlds/hld-asset-exemplar-reuse.md)
- [PRD: Staged Asset Reuse](specifications/prds/prd-staged-asset-reuse.md)
- [Low-Poly Garden Vegetation Inventory](specifications/research/asset-reuse/low_poly_garden_vegetation_inventory.md)
- existing managed-object metadata, targeting, and serialization foundations

## Relationships

- depends on `SAR-01`
- blocks `SAR-04`
- informs later asset integrity validation

## Related Technical Plan

- none yet

## Success Metrics

- a representative approved exemplar can create an editable Asset Instance without `eval_ruby`
- a representative low-poly vegetation component exemplar from a grouped project library can be instantiated without mutating the library source
- created instances retain source asset lineage metadata
- created instances retain or report source asset-set metadata needed for downstream validation and replacement
- source exemplars are not mutated during supported instantiation flows
- unsupported instantiation requests refuse without expected partial scene state
