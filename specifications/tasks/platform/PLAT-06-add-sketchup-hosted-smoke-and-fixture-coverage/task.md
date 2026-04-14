# Task: PLAT-06 Add SketchUp-Hosted Smoke and Fixture Coverage
**Task ID**: `PLAT-06`
**Title**: `Add SketchUp-Hosted Smoke and Fixture Coverage`
**Status**: `defined`
**Date**: `2026-04-13`

## Linked HLD

- [Platform Architecture and Repo Structure](../../../hlds/hld-platform-architecture-and-repo-structure.md)

## Problem Statement

Some platform behaviors depend on real SketchUp semantics and cannot be validated purely through Ruby or Python unit tests. A SketchUp-hosted smoke layer and governed fixture strategy would improve confidence in those runtime-dependent behaviors, but this work is lower priority because it is not expected to become part of the normal CI path.

## Goals

- establish a formal SketchUp-hosted smoke or integration layer for platform-critical runtime behavior
- define governance for fixture `.skp` models and related runtime-dependent assets
- keep this verification path clearly distinct from the always-on unit-test workflow

## Acceptance Criteria

```gherkin
Scenario: Real SketchUp runtime verification has an explicit platform-owned layer
  Given some platform behaviors depend on actual SketchUp semantics
  When the platform quality model is reviewed
  Then SketchUp-hosted smoke or integration coverage has an explicit platform owner
  And that layer is used to validate runtime paths that cannot be proven through unit tests alone

Scenario: Fixture assets are governed rather than ad hoc
  Given repeatable SketchUp-hosted verification depends on fixture models or related assets
  When the runtime fixture strategy is reviewed
  Then fixture categories, ownership expectations, and update rules are explicit
  And fixture assets are treated as maintained platform artifacts

Scenario: SketchUp-hosted coverage remains a deferred workflow
  Given the platform does not currently expect SketchUp-hosted smokes to run in normal CI
  When the task is reviewed in the platform backlog
  Then it is clearly treated as deferred or low-priority work
  And it does not block the core decomposition and unit-test slices
```

## Non-Goals

- defining every future capability acceptance scenario
- requiring SketchUp-hosted checks to run in all environments by default
- replacing unit tests with full end-to-end runtime coverage

## Business Constraints

- platform confidence should eventually include real SketchUp behavior, not only synthetic checks
- fixture governance must scale with future capability work
- backlog priority should reflect that this work is useful but not part of the near-term delivery path

## Technical Constraints

- the resulting strategy must align with the revised platform HLD
- fixture assets must support repeatable runtime verification
- the SketchUp-hosted layer must remain compatible with manual or environment-gated execution models

## Dependencies

- `PLAT-01`
- `PLAT-02`

## Relationships

- deferred low-priority platform task
- complements `PLAT-04`

## Related Technical Plan

- none yet

## Success Metrics

- platform-critical runtime behavior has a defined SketchUp-hosted verification layer
- fixture models and related runtime assets have explicit governance expectations
- the task remains clearly outside the main always-on CI path unless priorities change later
