# Task: MTA-17 Define Profile QA And Monotonic Terrain Diagnostics
**Task ID**: `MTA-17`
**Title**: `Define Profile QA And Monotonic Terrain Diagnostics`
**Status**: `deferred`
**Priority**: `P2`
**Date**: `2026-04-28`

## Linked HLD

- [Managed Terrain Surface Authoring](specifications/hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

The terrain modelling signal showed that point samples verify controls, but profile samples verify terrain shape. Several visible failures, including valleys, bumps, and crossfall errors, were only obvious after ordered profile sampling. The current product has `sample_surface_z` profile evidence and `measure_scene terrain_profile/elevation_summary`, but it does not yet define whether monotonic fall, bump detection, valley detection, or curvature-spike diagnostics belong in terrain evidence, measurement, or validation.

This task defines the ownership and contract posture for profile-based terrain QA without prematurely turning measurement evidence into validation verdicts or terrain mutation.

## Goals

- Define which profile QA concepts are terrain-owned evidence, measurement-owned quantities, and validation-owned findings.
- Clarify how monotonic grade-line checks should be represented before any edit mode enforces monotonicity.
- Identify the minimal profile diagnostics needed to support bump, valley, crossfall, and curvature-spike review.
- Preserve `sample_surface_z` and `measure_scene terrain_profile/elevation_summary` as evidence paths rather than mutation tools.
- Produce task-ready recommendations for later validation or terrain edit work.

## Acceptance Criteria

```gherkin
Scenario: profile QA ownership is mapped
  Given terrain workflows need to inspect bumps, valleys, crossfall, and monotonic fall
  When this task evaluates profile QA concepts
  Then each concept is assigned to terrain evidence, measurement evidence, validation findings, or deferred scope
  And no concept is assigned to terrain mutation solely because terrain edits produce related evidence

Scenario: monotonic profile semantics are defined before enforcement
  Given a caller wants terrain to fall monotonically along a profile
  When monotonic profile diagnostics are specified
  Then the task distinguishes diagnostic measurement from an edit constraint
  And it records what evidence would be needed before a future edit constraint could be safely planned

Scenario: profile guidance remains compatible with existing sampling tools
  Given sample_surface_z and measure_scene already expose terrain profile evidence
  When profile QA recommendations are produced
  Then they reuse those evidence paths where possible
  And they avoid introducing a second terrain sampling subsystem
```

## Non-Goals

- implementing terrain validation findings
- implementing monotonic terrain edit constraints
- changing `sample_surface_z` or `measure_scene` request shapes
- adding broad drainage, hydrology, or civil grading analysis
- replacing visual review with a single automated verdict

## Business Constraints

- Terrain QA should reduce trial-and-error without implying that every plausible terrain shape can be accepted automatically.
- Profile diagnostics must help agents inspect terrain shape between controls, not only report point hits.
- Terrain mutation, measurement, and validation ownership must remain distinct.

## Technical Constraints

- Profile sampling should continue to use existing explicit-target sampling and measurement seams.
- Outputs must remain JSON-serializable and compact enough for downstream agents to compare.
- Any future validation findings must be planned under the scene validation and review slice, not hidden inside terrain edit completion.
- Any future edit constraints must be planned separately from diagnostic measurement.

## Dependencies

- `STI-03`
- `SVR-04`
- `MTA-15`
- `MTA-16`
- `PLAT-18`
- [Terrain modelling signal](specifications/signals/2026-04-28-terrain-modelling-session-reveals-planar-intent-and-profile-qa-gaps.md)

## Relationships

- follows `MTA-15` by turning profile QA guidance into ownership analysis after baseline discoverability is hardened
- should follow `MTA-16` and `PLAT-18` so profile QA ownership reflects explicit planar fit and initial prompt guidance rather than the older workaround-heavy workflow
- may inform future scene validation and review tasks for bump, valley, crossfall, or monotonic profile findings
- may inform later terrain edit tasks if monotonic constraints become accepted edit intent

## Related Technical Plan

- none yet

## Success Metrics

- profile QA concepts are mapped to explicit owning slices without ownership ambiguity
- monotonic profile diagnostics are separated from monotonic edit constraints
- follow-on validation or terrain edit tasks can be created without re-litigating sampling ownership
- no recommendation duplicates existing `sample_surface_z` or `measure_scene` sampling responsibilities
