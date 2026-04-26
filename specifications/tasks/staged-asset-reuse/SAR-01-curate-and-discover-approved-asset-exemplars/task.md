# Task: SAR-01 Curate And Discover Approved Asset Exemplars
**Task ID**: `SAR-01`
**Title**: `Curate And Discover Approved Asset Exemplars`
**Status**: `planned`
**Priority**: `P1`
**Date**: `2026-04-25`

## Linked HLD

- [Asset Exemplar Reuse](specifications/hlds/hld-asset-exemplar-reuse.md)

## Problem Statement

Staged asset reuse needs an approved Asset Exemplar library before agents can safely reuse curated SketchUp assets. Today, there is no supported runtime path for taking a user-curated in-model asset, marking it as an approved exemplar, normalizing its metadata, organizing it into a staging area, or discovering it through a stable MCP tool.

This task delivers the first staged-asset vertical slice: register or curate an already in-model asset as an approved Asset Exemplar and prove that policy through `list_staged_assets`.

## Goals

- support curation of an existing in-model asset into an approved Asset Exemplar
- normalize minimum Asset Exemplar metadata, category, tags, and approval state
- organize approved exemplars into the staging area or equivalent library convention
- return JSON-safe curation evidence without raw SketchUp objects
- expose `list_staged_assets` for approved-exemplar discovery
- support documented discovery filters for the first asset-reuse workflow
- install the initial exemplar-protection predicate needed by later mutation guardrails

## Acceptance Criteria

```gherkin
Scenario: an in-model asset is curated as an approved exemplar
  Given a user-curated asset already exists in the SketchUp model
  When the asset is registered as an approved Asset Exemplar
  Then required Asset Exemplar metadata is written
  And the approval state is set to approved
  And the asset is organized into the staged asset library area or equivalent convention
  And the result is JSON-safe and does not expose raw SketchUp objects

Scenario: approved exemplars are discoverable
  Given one or more approved Asset Exemplars exist in the model
  When `list_staged_assets` is called with supported filters
  Then only matching approved Asset Exemplars are returned by default
  And each result includes selection-friendly identity, category, metadata summary, display name, and bounds or placement-relevant summary data

Scenario: unapproved or incomplete assets are not returned by normal discovery
  Given an asset lacks required exemplar metadata or approval state
  When `list_staged_assets` is called without an explicit unsupported override
  Then the asset is not returned as an approved Asset Exemplar
  And the response remains JSON-safe and deterministic

Scenario: unsupported curation requests refuse clearly
  Given an asset cannot be resolved, resolves ambiguously, or lacks required curation input
  When exemplar curation is requested
  Then the command returns a structured refusal with actionable reason data
  And no partial approved-exemplar metadata is accepted as the expected outcome
```

## Non-Goals

- live 3D Warehouse search, download, or marketplace integration
- creating or importing external assets into the model
- instantiating editable Asset Instances into the design scene
- replacing existing proxies or lower-fidelity objects
- rich curation UI, versioning, deprecation, or ranking behavior
- comprehensive asset integrity validation beyond the checks required for curation and discovery

## Business Constraints

- the workflow must support human-curated assets already present in the SketchUp model
- only approved Asset Exemplars should be discoverable by normal reuse flows
- Asset Exemplars must remain distinct from editable Asset Instances
- normal asset workflows must not depend on live public asset search

## Technical Constraints

- all runtime-facing results must be JSON-serializable hashes, arrays, strings, numbers, and booleans
- raw SketchUp objects must not cross public MCP tool boundaries
- MCP tool registration, dispatcher behavior, tests, and user-facing docs must stay in sync for the new discovery surface
- curation must use the extension runtime path rather than release tooling or helper scripts
- the first exemplar-protection predicate must be reusable by later mutation guardrail work

## Dependencies

- [Asset Exemplar Reuse HLD](specifications/hlds/hld-asset-exemplar-reuse.md)
- [PRD: Staged Asset Reuse](specifications/prds/prd-staged-asset-reuse.md)
- [Domain Analysis](specifications/domain-analysis.md)
- existing targeting and scene serialization foundations

## Relationships

- blocks `SAR-02`
- informs `SAR-03`
- provides the metadata and approval contract consumed by later asset reuse tasks

## Related Technical Plan

- [plan.md](./plan.md)

## Success Metrics

- a representative user-curated in-model asset can be registered as an approved Asset Exemplar without `eval_ruby`
- approved exemplars can be listed through `list_staged_assets` with deterministic JSON-safe summaries
- unapproved or incomplete assets are excluded from normal discovery
- curation and discovery refusals are structured and testable
