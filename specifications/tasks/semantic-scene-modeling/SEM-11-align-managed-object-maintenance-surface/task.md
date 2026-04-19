# Task: SEM-11 Align Managed-Object Maintenance Surface
**Task ID**: `SEM-11`
**Title**: `Align Managed-Object Maintenance Surface`
**Status**: `draft`
**Priority**: `P1`
**Date**: `2026-04-18`

## Linked HLD

- [Semantic Scene Modeling](../../../hlds/hld-semantic-scene-modeling.md)

## Problem Statement

The semantic capability now has a meaningful create surface, metadata mutation, hierarchy maintenance primitives, and a clearer path toward richer built-form authoring. What it still lacks is one coherent maintenance posture for Managed Scene Objects after creation. Today `set_entity_metadata` is intentionally narrow, while `transform_entities` and `set_material` remain largely generic entity tools rather than clearly semantic-managed mutation paths.

That mismatch matters because richer semantic authoring is only durable if the resulting objects can be revised through a governed maintenance surface. The capability needs one follow-on maintenance-alignment task that decides how managed-object metadata updates, transforms, and material assignment should behave together, while preserving identity rules and structured results.

## Goals

- align post-create managed-object maintenance behavior under one coherent semantic posture
- widen semantic metadata mutation only where it remains compatible with Managed Scene Object invariants
- define how `transform_entities` and `set_material` should behave for Managed Scene Objects so revision workflows remain structured and predictable

## Acceptance Criteria

```gherkin
Scenario: supported managed-object metadata mutation is widened without weakening invariants
  Given Managed Scene Objects already support a narrow `set_entity_metadata` slice
  When the approved managed-object metadata surface is expanded
  Then supported semantic fields can be updated through one governed metadata mutation path
  And protected identity or management fields remain blocked or return structured failures

Scenario: transform and material updates have explicit managed-object behavior
  Given Managed Scene Objects may need geometric and representation revisions after creation
  When supported transform or material updates are applied to a Managed Scene Object
  Then the runtime follows one documented managed-object maintenance posture for those updates
  And the result preserves required identity, metadata invariants, and structured downstream state

Scenario: managed-object maintenance returns structured semantic results
  Given the semantic capability should return programmatically useful mutation outcomes
  When a supported managed-object maintenance action succeeds
  Then the public result is structured and JSON-serializable
  And the result communicates the updated Managed Scene Object state rather than only a primitive entity identifier

Scenario: maintenance alignment does not widen into destructive-policy work
  Given duplication and governed deletion remain a distinct semantic-policy slice
  When this task is completed
  Then the task aligns non-destructive managed-object maintenance behavior only
  And duplication or destructive deletion rules are left to a separate follow-on task
```

## Non-Goals

- duplication policy for Managed Scene Objects
- destructive deletion protections or batch cleanup policy
- terrain-authoring or grading behavior
- next-wave semantic-family promotion

## Business Constraints

- the maintenance surface must remain predictable for workflow clients and preserve semantic trust after creation
- widening maintenance behavior must not silently weaken Managed Scene Object identity or provenance rules
- the task should align post-create maintenance around real user workflows rather than expanding every possible metadata field speculatively

## Technical Constraints

- the task depends on `SEM-09` and the current semantic metadata posture from `SEM-03`
- Ruby must own invariant enforcement, maintenance bracketing, and structured mutation-result shaping
- the task must decide whether existing public generic mutation tools evolve in place or are narrowed in favor of clearer semantic-owned behavior without creating conflicting overlapping surfaces
- the task must reuse the delivered targeting posture and must not introduce a semantic-owned lookup subsystem

## Dependencies

- `SEM-03`
- `SEM-09`

## Relationships

- informs `SEM-12`

## Related Technical Plan

- none yet

## Success Metrics

- supported managed-object maintenance actions preserve identity and return structured semantic results instead of primitive-only acknowledgements
- approved metadata mutation coverage is materially broader than the current `status` and `structureCategory` slice without weakening invariants
- the semantic maintenance surface becomes coherent enough that richer authored objects can be revised without fallback Ruby for common non-destructive changes
