# Task: SEM-09 Realize Lifecycle Primitives Needed for Richer Built-Form Authoring
**Task ID**: `SEM-09`
**Title**: `Realize Lifecycle Primitives Needed for Richer Built-Form Authoring`
**Status**: `completed`
**Priority**: `P0`
**Date**: `2026-04-19`

## Linked HLD

- [Semantic Scene Modeling](../../../hlds/hld-semantic-scene-modeling.md)

## Problem Statement

The semantic capability now exposes sectioned `hosting`, `placement`, and `lifecycle` inputs through `create_site_element`, but the current runtime still realizes too much of that contract only at the command-validation layer. The repo can validate, normalize, and resolve parent or host targets, yet the builder-owned scene behavior is still too narrow for the next richer built-form slice.

That gap matters because the next authoring step should not add richer built-form workflows on top of lifecycle semantics that are only partially real. The capability needs a smaller, focused lifecycle-enablement task that makes the current semantic contract materially true where richer built-form authoring depends on it, without broadening into full terrain authoring or a full managed-object maintenance rewrite.

## Goals

- make the sectioned semantic lifecycle contract materially real where richer built-form authoring depends on it
- realize explicit parent-aware placement and supported hosting behavior through builder-owned scene mutation rather than command-layer threading alone
- define governed scene-handoff behavior for `adopt_existing` and `replace_preserve_identity` so supported revision flows preserve business identity and intended scene context

## Acceptance Criteria

```gherkin
Scenario: parent-aware placement is realized for supported semantic creation flows
  Given the native semantic create surface already accepts sectioned `placement` input
  When a supported `create_site_element` request uses explicit parent placement
  Then the created Managed Scene Object is inserted under the resolved supported parent context
  And the resulting managed-object output preserves the intended scene hierarchy without relying on command-only placeholder semantics

Scenario: supported hosting modes have real scene behavior for the delivered families
  Given the native semantic create surface already accepts sectioned `hosting` input
  When a supported semantic family uses a delivered hosting mode through `create_site_element`
  Then the runtime applies the documented hosting behavior through Ruby-owned semantic execution
  And unsupported or unfulfillable hosted requests return structured refusals instead of silently degrading to unhosted creation

Scenario: adopt and replace flows perform governed lifecycle handoff
  Given a supported Managed Scene Object already exists in the scene
  When `create_site_element` is exercised through `adopt_existing` or `replace_preserve_identity`
  Then the resulting flow preserves required business identity and managed-object metadata invariants
  And the resulting object preserves or explicitly re-establishes the intended scene context for the supported lifecycle path

Scenario: lifecycle realization remains undo-safe and JSON-serializable
  Given this task changes live semantic mutation behavior
  When supported lifecycle-enabled create flows succeed or fail
  Then each flow completes inside one coherent SketchUp operation boundary
  And the public result remains structured and JSON-serializable without exposing raw SketchUp objects
```

## Non-Goals

- broad terrain-authoring or grading workflows
- widening the generic mutation surface for `transform_entities` or `set_material`
- introducing next-wave semantic families such as `tree_instance`, `seat`, `water_feature_proxy`, or `terrain_patch`
- turning multipart composition into one oversized atomic `create_site_element` contract

## Business Constraints

- the task must improve the reality of the current semantic contract before richer built-form authoring expands the surface
- lifecycle realization must preserve stable business identity and intended scene context for supported flows instead of creating visually correct but semantically weak results
- the task must stay inside the current semantic-scene-modeling product boundary and keep terrain authoring out of scope

## Technical Constraints

- Ruby remains the owner of semantic lifecycle handling, parent or host target resolution consumption, operation bracketing, and result serialization
- the task must build on the sectioned `create_site_element` contract already established by `SEM-06` and `SEM-08`
- supported lifecycle behavior must reuse the delivered targeting contract rather than introducing a second semantic lookup subsystem
- the task must realize only the lifecycle primitives needed for the next richer built-form slice rather than broadening into full maintenance-policy work

## Dependencies

- `SEM-08`
- `PLAT-15`

## Relationships

- blocks `SEM-10`
- informs `SEM-11`

## Related Technical Plan

- [Technical Plan](./plan.md)
- [Implementation Summary](./summary.md)

## Success Metrics

- representative parented or hosted semantic create flows produce scene results that match the sectioned lifecycle contract rather than command-only placeholders
- supported `adopt_existing` and `replace_preserve_identity` flows preserve required business identity and managed-object invariants in live semantic results
- the delivered lifecycle-enabled flows remain covered by deterministic Ruby tests and are suitable for SketchUp-hosted smoke validation
