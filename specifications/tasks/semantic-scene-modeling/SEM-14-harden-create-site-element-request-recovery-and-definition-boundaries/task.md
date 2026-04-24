# Task: SEM-14 Harden Create Site Element Request Recovery and Definition Boundaries
**Task ID**: `SEM-14`
**Title**: `Harden Create Site Element Request Recovery and Definition Boundaries`
**Status**: `completed`
**Priority**: `P0`
**Date**: `2026-04-23`

## Linked HLD

- [Semantic Scene Modeling](specifications/hlds/hld-semantic-scene-modeling.md)

## Problem Statement

`SEM-06` and `SEM-08` established the sectioned `create_site_element` contract as the single public semantic creation baseline, but the live MCP boundary is still too brittle when clients misconstruct that shape in common, recognizable ways. In practice, callers are repeatedly:

- wrapping the entire semantic payload under top-level `definition`
- placing geometry leaf fields such as `mode`, `position`, `height`, or `width` at top level instead of inside `definition`
- selecting family-wrong `definition` fields because the published inner `definition` surface is still broad enough to imply that some fields are global when they are actually element-type-specific

Those failures currently surface as generic MCP `-32602` invalid-params errors before Ruby can normalize, refuse, or teach the caller. That leaves the primary semantic creation surface materially harder to use than the product intends, and it pushes clients back toward trial-and-error on the most important semantic constructor in the system.

This task exists to harden `create_site_element` at the real contract seam. It should keep one durable sectioned public constructor while ensuring that bounded malformed-but-recognizable create requests are either recovered in Ruby or refused with structured correction guidance instead of dying as opaque MCP param-shape failures. It should also make family-specific `definition` boundaries explicit enough that clients stop inferring wrong-family geometry fields from the broad inner create schema.

## Goals

- prevent common malformed `create_site_element` request shapes from failing only as generic MCP param errors when the intent is recoverable or diagnosable
- preserve one canonical sectioned public semantic create contract rather than reopening a flat dual-contract posture
- make family-specific `definition` fields and modes explicit enough that element-type-specific geometry boundaries are discoverable and enforceable
- align loader schema behavior, semantic request handling, refusals, tests, and user-facing guidance around the hardened create-contract seam

## Acceptance Criteria

```gherkin
Scenario: common malformed create_site_element request shapes are handled in-band
  Given a caller sends a bounded malformed but recognizable `create_site_element` request shape
  When the request is processed through the shipped MCP runtime
  Then the call does not fail only as a generic MCP missing-required-arguments error
  And the runtime either recovers the request into the canonical sectioned shape or returns a structured semantic refusal that explains the shape problem

Scenario: create_site_element remains one canonical sectioned public contract
  Given the semantic creation surface already chose the sectioned contract posture
  When this task is reviewed
  Then `create_site_element` still has one canonical sectioned public request shape
  And the task does not restore the older flat create contract as an equal public alternative
  And any compatibility handling remains explicitly bounded to malformed-shape recovery rather than becoming a second promoted contract

Scenario: family-specific definition boundaries become explicit for all supported first-wave families
  Given supported semantic element types own different `definition` fields and modes
  When a caller inspects or misuses the `create_site_element` contract for `structure`, `pad`, `path`, `retaining_edge`, `planting_mass`, or `tree_proxy`
  Then the runtime contract and refusal behavior make clear which `definition` fields and modes belong to the chosen `elementType`
  And wrong-family `definition` fields are not silently accepted as if they were global create fields

Scenario: representative malformed requests are covered beyond tree_proxy
  Given the malformed-shape pattern has been observed on more than one semantic family
  When this task is complete
  Then automated coverage proves the hardening works for representative malformed requests across more than one supported `elementType`
  And the task does not narrow the fix to `tree_proxy` alone

Scenario: contract surfaces and guidance ship together
  Given this task changes the effective create-contract behavior at the MCP boundary
  When the task is reviewed
  Then the native loader schema, semantic normalization and validation behavior, structured refusals, contract tests, and user-facing guidance are updated in the same change
  And the shipped guidance makes the canonical top-level sections versus inner `definition` payload boundary explicit
```

## Non-Goals

- introducing a new semantic creation tool outside `create_site_element`
- reopening the broader sectioned-versus-flat public contract decision settled by `SEM-06`
- inventing next-wave semantic families or widening the supported first-wave vocabulary
- migrating unrelated metadata, hierarchy-maintenance, duplication, or deletion behavior

## Business Constraints

- `create_site_element` must remain the primary semantic constructor rather than becoming so brittle that clients fall back to trial-and-error or escape-hatch workflows
- the fix must improve real caller recovery and guidance for malformed requests without teaching a second public create posture as the new normal
- the task must help all currently supported first-wave semantic families, not just the family where the latest failures were observed first
- the delivered behavior must make the contract easier to learn in-band rather than relying only on repo-local documentation or prompt discipline

## Technical Constraints

- Ruby remains the owner of the public `create_site_element` schema, semantic normalization, validation, refusal shaping, and builder routing
- if the current MCP schema is too strict to let Ruby recover bounded malformed request shapes, the loader contract must be changed in a bounded way that still preserves one canonical sectioned public baseline
- compatibility handling must stay limited to known malformed-shape classes and must not silently reinterpret materially ambiguous requests
- family-specific `definition` boundaries must be expressed through the shipped contract surface, structured refusal behavior, or both; broad wrong-family field acceptance is not an acceptable end state
- all successful and refused results must remain JSON-serializable and undo-safe, and docs/tests must move with any public contract hardening

## Dependencies

- `SEM-06`
- `SEM-08`
- [HLD: Semantic Scene Modeling](specifications/hlds/hld-semantic-scene-modeling.md)
- [PRD: Semantic Scene Modeling](specifications/prds/prd-semantic-scene-modeling.md)

## Relationships

- follows `SEM-06` and `SEM-08` by hardening the live sectioned create-contract seam after the public cutover and remaining-family migration
- informs future semantic contract work so later create-surface expansion does not repeat the same malformed-shape and wrong-family-field failure modes

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- representative malformed `create_site_element` attempts no longer fail only as raw MCP `-32602` missing-required-arguments errors when the runtime can recognize the intended sectioned shape
- supported semantic families expose clearer `definition` ownership boundaries so wrong-family field usage is caught or corrected predictably
- contract coverage exists for malformed-shape recovery or structured refusal paths across multiple supported semantic families, not only `tree_proxy`

## Implementation Notes

- Completed scope:
  - added a dedicated semantic `RequestShapeRecovery` seam before strict validation
  - added bounded recovery for:
    - whole sectioned payloads accidentally wrapped under top-level `definition`
    - unambiguous top-level family-owned geometry leaf fields that can be relocated into `definition`
  - added structured `malformed_request_shape` refusals for ambiguous and wrong-family request shapes
  - introduced a shared `RequestShapeContract` source for canonical sections and family-owned `definition` fields
  - kept the native loader schema focused on the canonical sectioned contract while runtime recovery handles bounded compatibility cases
  - updated `README.md`, current source-of-truth docs, loader descriptions, semantic tests, loader tests, and native contract fixtures together
- Local validation:
  - `bundle exec ruby -Itest test/semantic/request_shape_recovery_test.rb`
  - `bundle exec ruby -Itest test/semantic/semantic_request_validator_test.rb`
  - `bundle exec ruby -Itest test/semantic/semantic_commands_test.rb`
  - `bundle exec ruby -Itest test/runtime/native/mcp_runtime_loader_test.rb`
  - `bundle exec rake ruby:test`
  - `bundle exec rake ruby:lint`
  - `bundle exec rake package:verify`
- Remaining manual verification gap:
  - rerun `test/runtime/native/mcp_runtime_native_contract_test.rb` in an environment with the staged native vendor runtime present so the new malformed-shape transport contract case executes instead of skipping
