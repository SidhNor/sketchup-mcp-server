# Task: PLAT-15 Align Public Targeting and Generic Mutation Tool Boundaries
**Task ID**: PLAT-15
**Title**: Align Public Targeting and Generic Mutation Tool Boundaries
**Status**: `completed`
**Priority**: P0
**Date**: 2026-04-17

## Linked HLD

- [HLD: Scene Targeting and Interrogation](specifications/hlds/hld-scene-targeting-and-interrogation.md)
- [HLD: Semantic Scene Modeling](specifications/hlds/hld-semantic-scene-modeling.md)
- [HLD: Platform Architecture and Repo Structure](specifications/hlds/hld-platform-architecture-and-repo-structure.md)

## Problem Statement

The current public MCP tool surface still teaches several wrong affordances even after the recent contraction pass. `list_entities` is still shaped as a broad top-level listing helper instead of an explicit scope-first inventory tool. `find_entities` is still carrying an MVP lookup posture that does not make its long-term predicate-first role explicit enough for downstream workflows. `delete_component` also still teaches a component-only contract even though the generic mutation slice is moving toward behavior defined by supported target types rather than narrow SketchUp primitive names.

These boundary mismatches matter because public tool contracts are part of the product surface, not just transport decoration. If inventory, targeting, and generic mutation tools do not clearly communicate what they are for and what they are not for, agents will continue to fall back to broad inspection, infer unsupported behavior, or choose the wrong tool for a workflow. The next task should tighten these boundaries in one coherent pass so the surviving query and mutation tools become explicit, compact, and evolution-safe.

## Goals

- Define `list_entities` as a scope-first inventory tool with an explicit inventory boundary.
- Define `find_entities` as a predicate-first targeting tool with an explicit lookup boundary distinct from inventory.
- Align the public deletion contract so its name, description, and supported target semantics match the behavior the product actually intends to support.

## Acceptance Criteria

```gherkin
Scenario: list_entities becomes an explicit scope-first inventory tool
  Given the public MCP scene-inspection surface
  When this task is complete
  Then `list_entities` accepts an explicit scope-oriented request contract rather than behaving as a broad implicit top-level listing helper
  And its documented purpose is inventory within a known scope such as selection, parent context, top-level context, or another explicitly supported scope
  And unsupported search-style lookup behavior is not described as part of `list_entities`

Scenario: find_entities becomes an explicit predicate-first targeting tool
  Given the public MCP scene-targeting surface
  When this task is complete
  Then `find_entities` exposes a documented predicate-centered request contract that is clearly distinct from `list_entities`
  And the delivered predicate families are explicit enough for reviewers to verify supported identity, attribute, and metadata lookup behavior without inference
  And `find_entities` continues to return structured resolution state and compact match summaries suitable for downstream automation

Scenario: generic deletion naming matches supported target semantics
  Given the public MCP generic mutation surface
  When this task is complete
  Then the deletion tool name, description, and request contract no longer imply narrower component-only behavior unless that restriction is intentionally enforced
  And the supported target types and refusal behavior are documented and covered by automated contract tests
  And public docs, runtime registration, and contract coverage are updated together in the same change
```

## Non-Goals

- Expanding the semantic creation vocabulary or lifecycle behavior for `create_site_element`
- Delivering full topology analysis, bounds tooling, or collection-discovery helpers beyond the tool-boundary work in this task
- Implementing workflow collection lookup behavior for `find_entities`; collection-aware targeting remains follow-on work tied to later targeting expansion
- Defining managed-object compatibility policy for every generic mutation tool beyond the deletion-contract alignment included here

## Business Constraints

- The public MCP surface must stay compact and avoid overlapping tools whose intended use cannot be distinguished reliably by agents or operators.
- Workflow-facing targeting should continue to favor business identity and structured product semantics over broad scene probing or raw runtime identifiers.
- Public tool names and descriptions must teach the intended workflow boundary rather than mirroring accidental implementation detail.

## Technical Constraints

- Ruby remains the owner of MCP tool registration, request normalization, command dispatch, and JSON-serializable response shaping.
- Public contract changes must update runtime registration, dispatch, automated contract coverage, and user-facing documentation in the same change.
- The task must preserve the existing separation between scene-targeting ownership and semantic mutation ownership rather than creating a second lookup subsystem or mutation policy layer.

## Dependencies

- [STI-01 Targeting MVP and `find_entities`](specifications/tasks/scene-targeting-and-interrogation/STI-01-targeting-mvp-and-find-entities/task.md)
- [SEM-03 Add Metadata Mutation for Managed Scene Objects](specifications/tasks/semantic-scene-modeling/SEM-03-add-metadata-mutation-for-managed-scene-objects/task.md)
- [PLAT-14 Establish Native MCP Tool Contract and Response Conventions](specifications/tasks/platform/PLAT-14-establish-native-mcp-tool-contract-and-response-conventions/task.md)
- [PRD: Scene Targeting and Interrogation](specifications/prds/prd-scene-targeting-and-interrogation.md)
- [PRD: Semantic Scene Modeling](specifications/prds/prd-semantic-scene-modeling.md)

## Relationships

- builds on `STI-01` by replacing the current MVP posture with a clearer long-term targeting boundary
- informs the deferred semantic generic-mutation compatibility follow-on for `transform_entities` and `set_material`

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- Reviewers can distinguish `list_entities` and `find_entities` by contract purpose alone without relying on implementation knowledge or informal guidance.
- The public deletion tool no longer teaches component-only semantics unless automated coverage proves that component-only restriction is intentional.
- Runtime registration, tests, and user-facing docs expose one consistent boundary story for inventory, targeting, and generic deletion after the task lands.

## Implementation Notes

- `list_entities` now requires `scopeSelector` and supports `top_level`, `selection`, and `children_of_target` scoped inventory through a dedicated scene-query `ScopeResolver`.
- `find_entities` now requires `targetSelector` with exact-match `identity`, `attributes`, and bounded `metadata` sections, while preserving `none`/`unique`/`ambiguous` resolution states.
- `delete_component` was replaced by `delete_entities`, which accepts compact `targetReference`, returns structured deletion results, and refuses unresolved, ambiguous, or unsupported targets explicitly.
- Shared direct-reference resolution now lives under the scene-query slice in `src/su_mcp/scene_query/target_reference_resolver.rb` and is reused by semantic and editing flows.

## Validation Snapshot

- Focused PLAT-15 TDD suite passed before final repo validation.
- Final repo validation ran through `bundle exec rake ruby:test`, `bundle exec rake ruby:lint`, and `bundle exec rake package:verify`.
- Native transport contract tests that depend on the staged vendor runtime still skip in this checkout when the staged runtime is unavailable.
- Live SketchUp MCP verification confirmed `scopeSelector` behavior for:
  - `top_level`
  - `selection`
  - `children_of_target`
  - `includeHidden`
  - `outputOptions.limit`
  - explicit request-error paths for missing mode, unsupported mode, missing target reference, no-match target, ambiguous target, non-container target, and unsupported output options
- Live SketchUp MCP verification confirmed `targetSelector` behavior for:
  - identity predicates: `sourceElementId`, `persistentId`, `entityId`
  - attribute predicates: `name`, `tag`, `material`
  - metadata predicates: `managedSceneObject`, `semanticType`, `status`, `state`, `structureCategory`
  - cross-section narrowing across identity, attributes, and metadata
  - valid `none` and `ambiguous` resolution outcomes
  - explicit request-error paths for empty selector, unsupported section, and unsupported fields within each section
- Remaining live manual follow-up is limited to `delete_entities`.
