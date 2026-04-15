# Task: SEM-02 Complete First-Wave Semantic Creation Vocabulary
**Task ID**: `SEM-02`
**Title**: `Complete First-Wave Semantic Creation Vocabulary`
**Status**: `completed`
**Priority**: `P0`
**Date**: `2026-04-14`

## Linked HLD

- [Semantic Scene Modeling](../../../hlds/hld-semantic-scene-modeling.md)

## Problem Statement

The semantic core is only valuable to the product if the first-wave vocabulary covers the baseline site workflows called for by the PRD. Delivering only `structure` and `pad` would prove the architecture, but it would still leave common path, edge, planting, and proxy-tree requests outside the supported semantic surface and push routine work back toward primitive construction or fallback Ruby.

This task completes the remaining first-wave `create_site_element` coverage on top of the semantic core established in `SEM-01` while preserving one stable command surface, one managed-object contract, and one shared result shape.

The current landed slice expands the semantic vocabulary, but a post-implementation audit found that the public geometry contract is still only meter-based by intent. Numeric inputs are currently forwarded into SketchUp as raw internal lengths, which makes `create_site_element` behave like inches instead of meters at runtime. The remaining work for `SEM-02` is to make the public creation surface explicitly meter-safe for every supported semantic type without moving unit semantics into Python or changing the public tool shape.

## Goals

- extend `create_site_element` to cover the remaining first-wave semantic element types of `path`, `retaining_edge`, `planting_mass`, and `tree_proxy`
- preserve the semantic metadata conventions, structured refusal posture, and result-envelope shape established by `SEM-01`
- demonstrate that the semantic constructor now covers the intended baseline site-object vocabulary without fragmenting into multiple public creation tools
- make the public `create_site_element` surface accept meter-valued dimensions and return meter-valued semantic outputs consistently for every supported type, regardless of active SketchUp model units

## Acceptance Criteria

```gherkin
Scenario: create_site_element supports the remaining first-wave semantic types
  Given the semantic core and first vertical slice already exist
  When `create_site_element` is exercised for `path`, `retaining_edge`, `planting_mass`, and `tree_proxy`
  Then each supported type accepts its documented MVP payload shape and returns a structured Managed Scene Object result or structured failure
  And the public creation surface remains one compact semantic command

Scenario: first-wave expansion preserves the core semantic contract
  Given the task extends the existing semantic creation path rather than introducing a new one
  When the resulting payloads are reviewed at the Python or Ruby boundary
  Then the result shape, metadata conventions, and refusal posture remain consistent with `SEM-01`
  And the expansion does not weaken the established managed-object invariants for the delivered element types

Scenario: representative baseline site-object requests stay semantic instead of primitive-first
  Given the first-wave vocabulary is intended to cover baseline site workflows
  When representative requests for path-like, edge-like, planting-mass, and tree-proxy objects are reviewed
  Then those requests can be expressed through `create_site_element`
  And the task does not require new public primitive construction flows to complete the covered cases

Scenario: vocabulary expansion lands with unit and contract coverage
  Given this task expands an existing public semantic command
  When the task is reviewed
  Then automated Ruby and Python tests cover the delivered request and response behavior for the newly supported types
  And the shared contract artifact and both native contract suites are updated in the same change

Scenario: create_site_element enforces the public meter contract
  Given the public semantic tool surface is documented in meters rather than active-model units
  When any supported `create_site_element` type is created through the MCP boundary
  Then all public geometric inputs are interpreted in meters at the Ruby boundary
  And all returned semantic numeric dimensions and bounds are serialized back in meters
  And the active SketchUp model unit configuration does not silently change the public contract
```

## Non-Goals

- redefining the semantic metadata model or command surface introduced by `SEM-01` without a separate contract decision
- delivering `set_entity_metadata`
- promoting next-wave semantic element types such as `tree_instance`, `seat`, `water_feature_proxy`, or `terrain_patch`

## Business Constraints

- the first-wave vocabulary must cover the baseline semantic workflows named in the PRD without turning the tool surface into multiple overlapping constructors
- the expansion must preserve semantic legibility and workflow-friendly results for downstream automation
- the task must complete MVP semantic coverage without quietly enlarging the scope into next-wave semantic families

## Technical Constraints

- Ruby must continue to own per-type builder behavior, payload interpretation, and JSON-safe serialization
- Python must remain a thin MCP adapter over the expanded Ruby command behavior
- the task must add or update shared contract cases and both native contract suites for the expanded public `create_site_element` behavior
- the task must preserve the registry-oriented extension path established by `SEM-01` rather than introducing ad hoc dispatch logic for each added type
- Ruby must explicitly convert public meter-valued semantic dimensions into SketchUp internal lengths on input and convert public semantic outputs back to meters on serialization
- Python must not infer, convert, or reinterpret public length units beyond basic schema typing

## Dependencies

- `SEM-01`

## Relationships

- informs `SEM-03`
- informs deferred semantic follow-ons that build on the first-wave vocabulary

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- representative requests for `path`, `retaining_edge`, `planting_mass`, and `tree_proxy` complete through `create_site_element`
- first-wave expansion preserves one stable semantic creation command and one consistent result contract
- the expanded creation boundary is covered by Ruby tests, Python tests, and shared contract cases in the same task
- representative numeric dimensions for every supported semantic type round-trip through the public boundary in meters instead of SketchUp internal inches

## MCP Decoration Guidance

- Live tool title remains `Create Semantic Site Element`
- Approved later-phase description for the `SEM-02` slice: `Create a managed semantic site element in SketchUp. Current support is limited to structure, pad, path, retaining_edge, planting_mass, and tree_proxy creation.`
- MCP posture remains mutating and non-destructive
