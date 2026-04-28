# Task: PLAT-17 Harmonize Residual Public MCP Contract Conventions
**Task ID**: PLAT-17
**Title**: Harmonize Residual Public MCP Contract Conventions
**Status**: planned
**Priority**: P1
**Date**: 2026-04-28

## Linked HLD

- [HLD: Platform Architecture and Repo Structure](specifications/hlds/hld-platform-architecture-and-repo-structure.md)
- [HLD: Scene Targeting and Interrogation](specifications/hlds/hld-scene-targeting-and-interrogation.md)
- [HLD: Semantic Scene Modeling](specifications/hlds/hld-semantic-scene-modeling.md)

## Problem Statement

The Ruby-native MCP runtime now has a stronger catalog and refusal baseline, but the shipped public surface still teaches mixed contract conventions across tool families. Response field casing still differs by capability, targeting selectors still expose parallel legacy shapes, caller-recoverable request failures are split between structured refusals and runtime error paths, and docs/catalog discoverability is not fully synchronized for the currently exposed tool inventory and unit semantics. This drift forces MCP clients to branch by tool family, increases contract guesswork, and weakens the product promise of one coherent public MCP contract.

## Goals

- Converge residual public contract vocabulary so first-class tools teach one consistent external shape.
- Align request and response discoverability across runtime schema, runtime behavior, contract fixtures, and user-facing docs.
- Reduce client-side ambiguity by clarifying selector policy, refusal policy, and tool inventory ownership in one bounded platform task.

## Acceptance Criteria

```gherkin
Scenario: First-class response vocabulary is coherent across exposed tool families
  Given the current first-class MCP tool surface
  When this task is complete
  Then first-class responses no longer mix conflicting public casing conventions for equivalent concepts
  And representative response fixtures and tests enforce the agreed response vocabulary

Scenario: Target selector contracts converge on one canonical public shape
  Given mutation and inspection tools that currently accept multiple selector forms
  When this task is complete
  Then the public selector contract is canonical and documented for each affected tool
  And runtime schema, validation behavior, and docs teach the same selector contract posture

Scenario: Caller-recoverable invalid requests return one consistent contract posture
  Given first-class tools with request-shape and finite-option validation
  When invalid caller inputs are submitted after this task
  Then caller-recoverable invalid inputs return structured refusal payloads through the shared response vocabulary
  And unexpected internal failures remain on the runtime error path

Scenario: Public tool discoverability and unit semantics are synchronized
  Given the runtime tool catalog and user-facing MCP reference docs
  When this task is complete
  Then published tool inventory reflects the runtime-exposed public tools
  And unit semantics are explicitly correct for each public geometry-bearing surface
  And contract coverage prevents docs/schema/runtime drift on these discoverability seams
```

## Non-Goals

- redesigning semantic capability boundaries or introducing new workflow tool families
- replacing escape-hatch behavior policy for `eval_ruby`
- broad refactors unrelated to public MCP contract convergence and discoverability

## Business Constraints

- The public MCP surface must remain compact and teach reliable affordances that reduce trial-and-error for MCP clients.
- Contract and vocabulary updates are allowed to introduce intentional breaking changes when they improve cross-family coherence.
- User-facing docs must remain trustworthy as a source of public contract behavior.

## Technical Constraints

- Ruby remains the owner of native MCP tool registration, request shaping, response shaping, and refusal behavior.
- Public contract updates must change runtime schema/registration, runtime behavior, docs, and contract tests in the same change.
- Outputs that cross the MCP boundary must remain JSON-serializable.
- Root-level schema guidance in the MCP authoring standard must be preserved while tightening discoverability.

## Dependencies

- [PLAT-14 Establish Native MCP Tool Contract and Response Conventions](specifications/tasks/platform/PLAT-14-establish-native-mcp-tool-contract-and-response-conventions/task.md)
- [PLAT-15 Align Public Targeting and Generic Mutation Tool Boundaries](specifications/tasks/platform/PLAT-15-align-public-targeting-and-generic-mutation-tool-boundaries/task.md)
- [PLAT-16 Align Residual Public Contract Discoverability With Runtime Constraints](specifications/tasks/platform/PLAT-16-align-residual-public-contract-discoverability-with-runtime-constraints/task.md)
- [MCP Tool Authoring Standard for SketchUp Modeling](specifications/guidelines/mcp-tool-authoring-sketchup.md)

## Relationships

- follows `PLAT-16` as a bounded convergence pass for remaining cross-family public contract inconsistencies
- informs future capability tasks that extend public tooling so they do not reintroduce mixed contract vocabularies

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- Reviewers can compare representative tools across query, mutation, semantic, terrain, and modeling families without encountering contradictory selector or response conventions for the same contract concept.
- Contract tests fail when runtime behavior, schema discoverability, and docs diverge on the touched contract seams.
- Client-facing invalid input handling is consistently recoverable through structured refusal payloads for caller-correctable errors on touched first-class tools.
