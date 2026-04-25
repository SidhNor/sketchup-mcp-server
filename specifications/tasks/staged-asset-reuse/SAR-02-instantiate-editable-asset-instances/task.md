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

This task delivers controlled instantiation from approved exemplars into the editable design scene.

## Goals

- expose `instantiate_staged_asset` for approved Asset Exemplars
- create a separate editable Asset Instance without mutating the source exemplar
- support documented placement and scale inputs for the first asset-reuse workflow
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
  Given an Asset Instance was created from an approved Asset Exemplar
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
  Given a supported placement and scale payload is provided
  When the Asset Instance is created
  Then the serialized result reflects the applied placement and scale
  And the response avoids raw SketchUp objects
```

## Non-Goals

- curation or approval of new Asset Exemplars
- replacement of existing proxies or lower-fidelity objects
- comprehensive asset integrity validation across the whole model
- live 3D Warehouse search or asset import
- advanced ranking, recommendation, or category-library behavior
- broad copy-versus-component policy beyond the first supported instantiation behavior

## Business Constraints

- Asset Instances must be editable scene objects, not renamed or moved Asset Exemplars
- source lineage must be available for later replacement, validation, and review workflows
- instantiation must support reliable reuse of curated assets without arbitrary geometry generation

## Technical Constraints

- outputs must be JSON-serializable and must not expose raw SketchUp objects
- mutation must be a coherent SketchUp operation where practical
- MCP tool registration, dispatcher behavior, tests, and user-facing docs must stay in sync for the new instantiation surface
- instantiation must consume the metadata and approval contract established by `SAR-01`
- failures must not leave expected partial instance state

## Dependencies

- `SAR-01`
- [Asset Exemplar Reuse HLD](specifications/hlds/hld-asset-exemplar-reuse.md)
- [PRD: Staged Asset Reuse](specifications/prds/prd-staged-asset-reuse.md)
- existing managed-object metadata, targeting, and serialization foundations

## Relationships

- depends on `SAR-01`
- blocks `SAR-04`
- informs later asset integrity validation

## Related Technical Plan

- none yet

## Success Metrics

- a representative approved exemplar can create an editable Asset Instance without `eval_ruby`
- created instances retain source asset lineage metadata
- source exemplars are not mutated during supported instantiation flows
- unsupported instantiation requests refuse without expected partial scene state
