# Task: SAR-04 Replace Proxies With Staged Assets
**Task ID**: `SAR-04`
**Title**: `Replace Proxies With Staged Assets`
**Status**: `draft`
**Priority**: `P1`
**Date**: `2026-04-25`

## Linked HLD

- [Asset Exemplar Reuse](specifications/hlds/hld-asset-exemplar-reuse.md)

## Problem Statement

Landscape workflows need to upgrade lower-fidelity objects such as `tree_proxy` entities into higher-fidelity curated assets without losing workflow identity. Today, semantic replacement exists only inside `create_site_element` lifecycle behavior and does not create Asset Instances from approved Asset Exemplars or preserve source asset lineage for proxy-to-asset upgrades.

Replacement also needs to work with project-specific staged libraries, including the low-poly garden vegetation component set. A proxy or planting placeholder should be replaceable with an approved vegetation Asset Exemplar selected by archetype, represented species, planting role, style, and intended height, while preserving the target workflow identity and keeping the source library exemplar unchanged by the replacement flow.

This task delivers `replace_with_staged_asset` as the controlled proxy-to-asset upgrade path.

## Goals

- expose `replace_with_staged_asset` for approved Asset Exemplars
- replace a supported lower-fidelity target with an Asset Instance created from a staged asset
- preserve `sourceElementId` and semantic role where required by the workflow
- write source asset lineage on the replacement Asset Instance
- carry project asset-set metadata from the selected exemplar into replacement evidence and lineage where present
- support vegetation-library replacement scenarios from grouped component-instance exemplars without depending on a fixed group name or scene hierarchy
- handle the previous representation according to the supported replacement policy
- return JSON-safe replacement evidence and structured refusals

## Acceptance Criteria

```gherkin
Scenario: a supported proxy is replaced with an approved staged asset
  Given a supported lower-fidelity target and an approved Asset Exemplar can be resolved
  When `replace_with_staged_asset` is called
  Then an editable Asset Instance is created as the replacement representation
  And the replacement preserves the target `sourceElementId`
  And the replacement records source asset lineage
  And the response includes JSON-safe replacement evidence

Scenario: semantic role and workflow identity are preserved
  Given a supported proxy has semantic role metadata
  When it is replaced with a staged asset
  Then the resulting Asset Instance preserves the workflow identity required by the source target
  And the result is not classified as an Asset Exemplar

Scenario: the source exemplar remains unchanged during replacement
  Given an approved Asset Exemplar is used for replacement
  When replacement succeeds or refuses
  Then the source exemplar remains approved
  And replacement does not mutate the exemplar as the expected outcome

Scenario: a planting proxy is replaced from a project vegetation asset set
  Given a supported lower-fidelity planting target has workflow identity metadata
  And an approved low-poly vegetation Asset Exemplar can be resolved from a grouped project vegetation library
  And the exemplar includes asset-set metadata such as archetype, represented species, planting role, default height, height range, and style
  When `replace_with_staged_asset` replaces the target with that exemplar
  Then the resulting Asset Instance preserves the target workflow identity required by the replacement policy
  And the result records source exemplar lineage and source asset-set metadata
  And the source library exemplar remains approved and in its staging context

Scenario: replacement does not depend on exact project library hierarchy
  Given approved Asset Exemplars may be organized in a common group, staging collection, or equivalent metadata-backed library convention
  When the replacement target and selected exemplar resolve uniquely
  Then replacement succeeds or refuses based on target support, exemplar approval, integrity, and replacement policy
  And it does not require a hard-coded group name, exact nesting depth, or SketchUp tag/layer value

Scenario: unsupported replacement requests refuse clearly
  Given the target is missing, ambiguous, unsupported, locked, or the exemplar is missing, ambiguous, unapproved, or invalid
  When `replace_with_staged_asset` is called
  Then the command returns a structured refusal with actionable reason data
  And it does not leave partial replacement state as the expected outcome
```

## Non-Goals

- broad semantic lifecycle replacement beyond staged asset reuse
- full archival workflow for every previous representation type
- rich asset recommendation or ranking behavior
- curation, approval, or discovery of new exemplars
- comprehensive asset integrity validation across the whole scene
- live 3D Warehouse search or asset import
- broad planting-design recommendation logic beyond using selected approved exemplars
- requiring one canonical scene hierarchy for all project asset libraries

## Business Constraints

- replacement changes representation, not business identity
- proxy-to-asset upgrades must preserve traceability to the selected source asset
- approved Asset Exemplars must not be edited in place by replacement flows
- replacement should reduce dependence on arbitrary high-fidelity geometry generation
- grouped vegetation libraries are a supported source for replacement, but selected exemplars remain library sources rather than editable scene objects

## Technical Constraints

- `replace_with_staged_asset` must consume the curation/discovery contract from `SAR-01`
- replacement must reuse or align with the Asset Instance creation semantics from `SAR-02`
- replacement must not implicitly mutate the selected source Asset Exemplar
- replacement must preserve JSON-safe asset-set metadata needed for later validation and review when such metadata exists on the selected exemplar
- results and refusals must be JSON-safe and avoid raw SketchUp objects
- mutation must be a coherent SketchUp operation where practical
- MCP tool registration, dispatcher behavior, tests, and docs must stay in sync for the new replacement surface

## Dependencies

- `SAR-01`
- `SAR-02`
- [Asset Exemplar Reuse HLD](specifications/hlds/hld-asset-exemplar-reuse.md)
- [PRD: Staged Asset Reuse](specifications/prds/prd-staged-asset-reuse.md)
- [Low-Poly Garden Vegetation Inventory](specifications/research/asset-reuse/low_poly_garden_vegetation_inventory.md)
- existing targeting and semantic managed-object identity foundations

## Relationships

- depends on `SAR-02`
- informs later asset integrity and lineage validation

## Related Technical Plan

- none yet

## Success Metrics

- a representative `tree_proxy` or similar supported proxy can be replaced with an Asset Instance without `eval_ruby`
- a representative planting target can be replaced with a low-poly vegetation Asset Instance selected from a grouped project asset library
- replacement preserves `sourceElementId` and required semantic role metadata
- source asset lineage is present on the replacement instance
- source asset-set metadata is present in replacement evidence where the selected exemplar provides it
- unsupported replacement requests refuse without expected partial scene state
