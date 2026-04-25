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

This task delivers `replace_with_staged_asset` as the controlled proxy-to-asset upgrade path.

## Goals

- expose `replace_with_staged_asset` for approved Asset Exemplars
- replace a supported lower-fidelity target with an Asset Instance created from a staged asset
- preserve `sourceElementId` and semantic role where required by the workflow
- write source asset lineage on the replacement Asset Instance
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

Scenario: the source exemplar remains protected during replacement
  Given an approved Asset Exemplar is used for replacement
  When replacement succeeds or refuses
  Then the source exemplar remains approved and protected
  And replacement does not mutate the exemplar as the expected outcome

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

## Business Constraints

- replacement changes representation, not business identity
- proxy-to-asset upgrades must preserve traceability to the selected source asset
- approved Asset Exemplars must not be edited in place by replacement flows
- replacement should reduce dependence on arbitrary high-fidelity geometry generation

## Technical Constraints

- `replace_with_staged_asset` must consume the curation/discovery contract from `SAR-01`
- replacement must reuse or align with the Asset Instance creation semantics from `SAR-02`
- exemplar guardrails from `SAR-03` must remain effective during replacement
- results and refusals must be JSON-safe and avoid raw SketchUp objects
- mutation must be a coherent SketchUp operation where practical
- MCP tool registration, dispatcher behavior, tests, and docs must stay in sync for the new replacement surface

## Dependencies

- `SAR-01`
- `SAR-02`
- `SAR-03`
- [Asset Exemplar Reuse HLD](specifications/hlds/hld-asset-exemplar-reuse.md)
- [PRD: Staged Asset Reuse](specifications/prds/prd-staged-asset-reuse.md)
- existing targeting and semantic managed-object identity foundations

## Relationships

- depends on `SAR-02`
- depends on `SAR-03`
- informs later asset integrity and lineage validation

## Related Technical Plan

- none yet

## Success Metrics

- a representative `tree_proxy` or similar supported proxy can be replaced with an Asset Instance without `eval_ruby`
- replacement preserves `sourceElementId` and required semantic role metadata
- source asset lineage is present on the replacement instance
- unsupported replacement requests refuse without expected partial scene state
