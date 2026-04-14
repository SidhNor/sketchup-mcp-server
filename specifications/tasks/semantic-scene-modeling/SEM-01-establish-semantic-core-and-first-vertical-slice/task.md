# Task: SEM-01 Establish Semantic Core and First Vertical Slice
**Task ID**: `SEM-01`
**Title**: `Establish Semantic Core and First Vertical Slice`
**Status**: `draft`
**Priority**: `P0`
**Date**: `2026-04-14`

## Linked HLD

- [Semantic Scene Modeling](../../../hlds/hld-semantic-scene-modeling.md)

## Problem Statement

The current SketchUp MCP surface is still primitive-first. The repository exposes generic creation and mutation helpers, but it does not yet provide a semantic constructor, Managed Scene Object metadata ownership, or the invariant and serialization boundaries needed for revision-safe semantic workflows.

The semantic capability needs one architecture-shaping first slice that proves the full cross-runtime path end to end without trying to complete the entire first-wave vocabulary at once. `structure` and `pad` are the right first slice because they force the strongest semantic boundary in the PRD, require explicit metadata and classification rules, and establish the serializer and refusal posture the rest of the vocabulary must reuse.

## Goals

- deliver `create_site_element` as the first public semantic creation path through the Python and Ruby runtimes
- establish the Managed Scene Object metadata namespace, invariant model, operation boundary, and JSON-safe semantic serializer
- prove the first semantic boundary through `structure` and `pad`, including explicit refusal for ambiguous built-form versus surface-first requests

## Acceptance Criteria

```gherkin
Scenario: create_site_element delivers the first semantic creation slice end to end
  Given the MCP server exposes the current primitive-first modeling surface
  When `create_site_element` is exercised for the first supported semantic types
  Then the Python adapter forwards a compact semantic request to Ruby without reimplementing semantic behavior
  And Ruby owns builder selection, operation bracketing, metadata writes, and result serialization

Scenario: structure and pad establish the semantic boundary explicitly
  Given a request describes a `structure`, a `pad`, or an ambiguous built-form versus hardscape case
  When the first semantic slice is reviewed
  Then `structure` and `pad` accept their documented MVP payload shapes with structured outputs
  And ambiguous requests return a structured refusal instead of implicit type guessing

Scenario: managed objects carry required semantic identity from creation time
  Given a supported `structure` or `pad` is created through `create_site_element`
  When the created object is inspected at the Ruby or Python boundary
  Then the result is fully JSON-serializable
  And the managed object includes the required semantic identity and metadata fields defined for the delivered slice

Scenario: the first semantic slice is protected by unit and contract coverage
  Given this task changes the public Python/Ruby tool surface
  When the task is reviewed
  Then automated Ruby and Python tests cover the supported request and response behavior for the delivered slice
  And the shared contract artifact and both native contract suites are updated in the same change
```

## Non-Goals

- completing the full first-wave semantic vocabulary beyond `structure` and `pad`
- delivering metadata mutation through `set_entity_metadata`
- defining identity-preserving rebuild or replacement workflows

## Business Constraints

- the first semantic slice must replace primitive-first behavior for representative built-form and hardscape requests without forcing normal workflows back to `eval_ruby`
- semantic creation must make Managed Scene Objects the default unit of identity from the moment an object is created
- the `pad` versus `structure` distinction must stay explicit and reviewable rather than prompt-dependent

## Technical Constraints

- Ruby must own semantic payload normalization, builder selection, metadata writes, refusal behavior, and serialization
- Python must remain a thin MCP adapter that validates boundary shape and forwards the request over the existing bridge
- the task must introduce or update the shared contract artifact and native Ruby and Python contract suites for `create_site_element`
- the task must build on the current shared adapter and serializer seams rather than re-concentrating behavior in transport-adjacent files

## Dependencies

- `PLAT-02`
- `PLAT-03`

## Relationships

- blocks `SEM-02`
- informs `SEM-03`

## Related Technical Plan

- none yet

## Success Metrics

- representative `structure` and `pad` requests complete through `create_site_element` without primitive-tool fallback
- created objects for the delivered slice return structured Managed Scene Object outputs with required semantic identity fields
- the first semantic tool boundary is covered by Ruby tests, Python tests, and shared contract cases in the same task
