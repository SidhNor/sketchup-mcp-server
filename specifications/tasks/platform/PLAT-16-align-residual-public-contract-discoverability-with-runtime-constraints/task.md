# Task: PLAT-16 Align Residual Public Contract Discoverability With Runtime Constraints
**Task ID**: PLAT-16
**Title**: Align Residual Public Contract Discoverability With Runtime Constraints
**Status**: `completed`
**Priority**: P1
**Date**: 2026-04-23

## Linked HLD

- [HLD: Platform Architecture and Repo Structure](specifications/hlds/hld-platform-architecture-and-repo-structure.md)
- [HLD: Semantic Scene Modeling](specifications/hlds/hld-semantic-scene-modeling.md)

## Problem Statement

The Ruby-native MCP runtime now has shared tool-declaration and refusal conventions, but the shipped public catalog still contains residual contract discoverability drift. In several places, runtime code enforces a finite or context-dependent option set while the published schema still advertises a broad string field, or the narrowed allowed set is only discoverable after a failed call. That mismatch causes clients to guess at valid values, repeatedly invoke unsupported options, and learn the wrong affordances from the contract surface.

This cleanup matters because public tool contracts are part of the product behavior, not secondary documentation. If the runtime knows that only a bounded set of values is valid for a public field, the contract surface must make that bounded set discoverable in-band through the owning schema, refusal behavior, or both. The remaining mismatches should be corrected in one bounded cleanup task so future contract work starts from a coherent baseline instead of preserving trial-and-error behavior in shipped tools.

## Goals

- align residual finite and context-dependent public option sets with the runtime constraints that already govern them
- make supported values discoverable in-band for shipped public tools before a bad call, after a bad call, or both, according to the true contract shape
- leave the public catalog with contract tests that fail when runtime restrictions drift away from schema exposure or refusal behavior

## Acceptance Criteria

```gherkin
Scenario: Residual finite public option sets are discoverable in-band
  Given the shipped public MCP tool catalog contains fields whose valid values are already constrained by runtime code
  When the completed task is reviewed
  Then each known finite public option set touched by this task is discoverable through the owning contract surface rather than only through trial-and-error
  And invalid known-option requests return structured refusals that expose the rejected field, the rejected value, and the supported values whenever the runtime has an authoritative finite set

Scenario: Context-dependent option sets remain truthful rather than flattened incorrectly
  Given some shipped public fields accept different values depending on another request field or execution context
  When the completed task is reviewed
  Then the contract surface does not mis-teach a misleading context-free enum where the allowed set actually depends on context
  And the narrowed allowed values are exposed through the owning refusal behavior or other in-band contract artifact for the relevant context
  And automated contract coverage proves that the context-specific discoverability matches runtime behavior

Scenario: Cleanup updates contract surfaces together
  Given the remaining mismatches span schema declarations, runtime validation, refusal behavior, contract tests, and user-facing docs
  When this task is complete
  Then every touched public mismatch is updated across its owning schema, runtime validation, refusal behavior, and contract coverage in the same change
  And user-facing docs are updated where the discoverability story or valid values changed materially

Scenario: The task stays bounded to discoverability cleanup
  Given broader public-surface work could also redesign tool boundaries, selector vocabularies, and non-enumerated field guidance
  When the completed task is reviewed
  Then the primary outcome is alignment of existing runtime constraints with shipped contract discoverability
  And the task does not require a broad redesign of tool names, tool ownership, or unrelated request fields
  And heavy guide-lint or catalog-scoring machinery is not required for task completion
```

## Non-Goals

- redesigning the public MCP tool catalog or renaming tools beyond what is required to fix discoverability mismatches
- introducing new product capabilities or widening existing tool behavior
- forcing open-ended user-facing strings into enums where the runtime does not actually own a finite supported set
- building a broad policy linter or guide-conformance framework as part of this cleanup task

## Business Constraints

- agentic clients must be able to recover from invalid known-option inputs without depending on out-of-band tribal knowledge
- the cleanup should prioritize shipped mismatches that most directly cause repeated invalid tool invocations or wrong client affordances
- public tool names and high-level workflow boundaries should remain stable unless a separate intentional interface change is defined later

## Technical Constraints

- Ruby remains the canonical owner of public MCP tool registration, runtime validation, refusal shaping, and SketchUp-facing behavior
- public contract changes must update the owning schema, runtime validation, refusal behavior, contract tests, and user-facing docs in the same change
- public outputs that cross the MCP boundary must remain JSON-serializable
- context-dependent option sets may use a broader schema enum or shape only when a flatter enum would misstate the real contract, but the narrowed allowed set must still be exposed in-band for the relevant context
- the task must preserve the existing ownership split between platform seams and capability seams rather than creating a second contract-definition subsystem

## Dependencies

- [PLAT-14 Establish Native MCP Tool Contract and Response Conventions](specifications/tasks/platform/PLAT-14-establish-native-mcp-tool-contract-and-response-conventions/task.md)
- [PLAT-15 Align Public Targeting and Generic Mutation Tool Boundaries](specifications/tasks/platform/PLAT-15-align-public-targeting-and-generic-mutation-tool-boundaries/task.md)
- [SEM-11 Align Managed-Object Maintenance Surface](specifications/tasks/semantic-scene-modeling/SEM-11-align-managed-object-maintenance-surface/task.md)
- [SEM-13 Realize Horizontal Cross-Section Terrain Drape for Paths](specifications/tasks/semantic-scene-modeling/SEM-13-realize-horizontal-cross-section-terrain-drape-for-paths/task.md)

## Relationships

- follows `PLAT-14` by applying the shared native contract conventions to residual discoverability drift in shipped tools
- narrows remaining public contract drift after `PLAT-15` and the current semantic follow-on slices
- informs future task-planning and implementation work that adds or changes finite public tool option sets

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- the known residual mismatches covered by this task no longer require trial-and-error to discover valid values
- touched public tools expose supported finite values through schema, refusal behavior, or both according to the true contract shape
- dedicated contract coverage fails if runtime restrictions drift away from their published discoverability surface again

## Implementation Notes

- Completed scope:
  - `boolean_operation.operation` now returns a structured `unsupported_option` refusal with `allowedValues`
  - `boolean_operation.operation` and `set_entity_metadata.set.structureCategory` now publish enums in the native loader schema
  - `set_entity_metadata` required and unsupported `clear` refusals now expose contextual `allowedValues`
  - `create_site_element.hosting.mode` unsupported refusals now expose contextual `allowedValues`
- Contract artifacts updated:
  - owning runtime tests for modeling, loader, semantic metadata, and semantic commands
  - shared semantic contract fixture updates for required-clear refusal shape
  - representative native contract fixtures and tests for touched refusal surfaces
- Local validation:
  - focused suites passed for `test/modeling/solid_modeling_commands_test.rb`
  - focused suites passed for `test/runtime/native/mcp_runtime_loader_test.rb`
  - focused suites passed for `test/semantic/semantic_metadata_test.rb`
  - focused suites passed for `test/semantic/semantic_commands_test.rb`
  - `bundle exec rake ruby:test` passed
  - `bundle exec rake ruby:lint` passed
  - `bundle exec rake package:verify` passed
  - `test/runtime/native/mcp_runtime_native_contract_test.rb` remained fully skipped locally because the staged native vendor runtime is absent in this environment
- Remaining manual verification gap:
  - rerun native transport preservation assertions in an environment where the staged vendor runtime is available to the direct native contract test file
