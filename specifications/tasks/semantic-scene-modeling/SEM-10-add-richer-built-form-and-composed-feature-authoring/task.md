# Task: SEM-10 Add Richer Built-Form and Composed Feature Authoring
**Task ID**: `SEM-10`
**Title**: `Add Richer Built-Form and Composed Feature Authoring`
**Status**: `draft`
**Priority**: `P0`
**Date**: `2026-04-18`

## Linked HLD

- [Semantic Scene Modeling](../../../hlds/hld-semantic-scene-modeling.md)

## Problem Statement

The current semantic surface is strong for atomic first-wave objects, but it is still limited for richer built-form requests that exceed one simple footprint-mass object or one isolated site element. In practical authoring, users quickly move from isolated pads and structures into assembled houses, extensions, attached features, and grouped built-form work that must stay semantically legible without collapsing back into primitive construction or `eval_ruby`.

The capability therefore needs a richer authoring slice that stays inside the current semantic product boundary: built-form and composed feature workflows, not terrain authoring. That slice should extend the usefulness of the current first-wave semantic model without overloading atomic creation or bypassing the lifecycle primitives needed to keep richer authored results revision-friendly.

## Goals

- support richer built-form authoring workflows that go beyond one simple atomic footprint-mass result while staying inside the semantic surface
- support composed feature authoring through documented semantic workflows that remain compatible with the atomic-versus-composite boundary in the HLD
- keep richer built-form outputs semantically legible and revision-friendly rather than pushing representative higher-order authoring back toward primitive construction or fallback Ruby

## Acceptance Criteria

```gherkin
Scenario: representative richer built-form requests stay inside the semantic authoring surface
  Given the current semantic capability already supports first-wave atomic creation
  When representative richer built-form requests for supported houses, extensions, or attached built features are reviewed
  Then the capability exposes a documented semantic workflow for those cases without requiring new primitive-first public construction paths
  And the resulting scene objects remain structured Managed Scene Objects or structured semantic compositions rather than ad hoc unlabeled geometry

Scenario: composed feature authoring preserves the atomic-versus-composite boundary
  Given the semantic HLD keeps atomic creation separate from multipart composition
  When a richer authored feature requires more than one atomic managed object
  Then the workflow composes those objects through documented semantic or hierarchy-aware behavior instead of collapsing all behavior into one oversized atomic create contract
  And the task does not redefine `create_site_element` into a catch-all multipart feature constructor

Scenario: richer built-form authoring remains revision-friendly
  Given richer built-form requests are likely to be revised after initial creation
  When the resulting authored objects or composed features are inspected after creation
  Then they preserve stable semantic identity and structured outputs consistent with the current Managed Scene Object posture
  And they remain targetable for later lifecycle or maintenance flows without fallback Ruby

Scenario: richer built-form authoring stays inside the current product boundary
  Given the current semantic PRD keeps terrain modeling and grading-authoring out of scope
  When this task is completed
  Then the delivered richer authoring surface covers built-form and composed feature workflows only
  And the task does not widen into terrain-authoring or grading-specific semantic behavior
```

## Non-Goals

- terrain-authoring, grading, or terrain-patch workflows
- broad next-wave family promotion such as `seat`, `water_feature_proxy`, or `tree_instance`
- full managed-object maintenance alignment for generic mutation tools
- broad scene-orchestration or unrestricted hierarchy-control APIs

## Business Constraints

- the task must increase practical authoring leverage for richer built-form work rather than only hardening existing maintenance behavior
- richer authoring must stay semantically legible and compatible with revision-friendly workflows instead of creating visually useful but semantically weak geometry
- the delivered authoring slice must stay within the current semantic PRD boundary and keep terrain out of scope

## Technical Constraints

- the task depends on the lifecycle-enablement slice from `SEM-09` so richer authoring does not build on command-only parent or host semantics
- Ruby remains the owner of semantic interpretation, builder coordination, hierarchy-aware composition behavior, and JSON-safe result shaping
- the task must preserve the HLD boundary between atomic creation and composite feature assembly
- the task must reuse the delivered targeting and hierarchy-maintenance posture rather than introducing a second composition or lookup subsystem

## Dependencies

- `SEM-09`

## Relationships

- informs `SEM-11`
- informs deferred next-wave semantic-family work

## Related Technical Plan

- none yet

## Success Metrics

- representative richer built-form requests can be executed through documented semantic workflows without adding new primitive-first public construction tools
- richer authored built-form results remain semantically identifiable and targetable for later revision work
- the delivered authoring slice stays clearly out of terrain scope while materially improving practical built-form capability
