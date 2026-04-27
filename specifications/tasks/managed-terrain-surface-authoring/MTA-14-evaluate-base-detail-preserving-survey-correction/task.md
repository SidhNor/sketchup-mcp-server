# Task: MTA-14 Evaluate Base Detail Preserving Survey Correction
**Task ID**: `MTA-14`
**Title**: `Evaluate Base Detail Preserving Survey Correction`
**Status**: `completed`
**Priority**: `P0`
**Date**: `2026-04-27`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

`MTA-13` needs survey point constraints to satisfy measured elevations at one or more XY locations. A naive survey correction that only drives nearby heightmap samples toward requested elevations may satisfy residual tolerances while erasing local terrain character, introducing humps or trenches, or making later single-point survey corrections disturb too much surrounding detail.

Prior terrain work deliberately excluded detail-preserving smoothing from `MTA-06` to keep fairing scope bounded. Survey point constraints are different because measured points can force local terrain changes. Targeted Unreal Engine Landscape source inspection also shows relevant patterns: UE can operate on composed terrain while writing only an edit-layer contribution, and its detail-smooth path separates broader form from high-frequency detail. This task evaluates whether an analogous base/detail-preserving correction strategy is needed and practical for the current `heightmap_grid` v1 terrain state before `MTA-13` commits to a solver.

## Goals

- Define measurable detail-preservation and distortion criteria for survey point terrain correction.
- Compare minimum-change survey correction against at least one base/detail-preserving correction strategy on representative terrain grids.
- Verify single-point, multi-point, and later corrected single-point survey workflows.
- Determine whether base/detail preservation should be included in `MTA-13`, deferred to `MTA-11`, or replaced by refusal and warning thresholds.
- Capture decision evidence that can be referenced by the `MTA-13` technical plan.

## Acceptance Criteria

```gherkin
Scenario: survey correction strategies are compared on representative terrain
  Given representative heightmap terrain fixtures include flat terrain with local detail, steady slope with noise, nearby survey points, and a later corrected survey point
  When candidate correction strategies are evaluated
  Then each strategy reports survey residuals, max sample delta, changed-region size, slope or curvature change, and detail-preservation evidence
  And the comparison identifies which strategy best preserves terrain detail while satisfying supported survey constraints

Scenario: base detail preservation criteria are explicit
  Given survey point correction can disturb local terrain detail
  When the task defines detail-preservation evidence
  Then the evidence includes measurable criteria rather than visual-only judgments
  And the criteria distinguish acceptable local correction from unsafe humps, trenches, broad flattening, or excessive drift

Scenario: repeated survey edits are evaluated
  Given a terrain state receives a single survey point edit, a later batch edit, and a later corrected single-point edit
  When candidate strategies are applied against the current terrain state
  Then the evaluation reports whether each strategy preserves prior acceptable terrain detail
  And it identifies any strategy that reintroduces stale detail or causes uncontrolled cumulative drift

Scenario: MTA-13 implementation guidance is recorded
  Given the candidate strategy comparison is complete
  When the findings are reviewed for MTA-13 planning
  Then the task records a clear recommendation for the MTA-13 solver boundary
  And it identifies any cases that should refuse, warn, or escalate to localized survey/detail zones
```

## Non-Goals

- shipping a public `edit_terrain_surface` survey mode
- implementing durable localized survey/detail zones
- changing the persisted terrain payload kind or schema version
- adding interactive brush UI, broad sculpting, or public Unreal-style terrain tools
- copying Unreal Engine Landscape edit-layer or render-target architecture into the SketchUp extension
- mutating semantic hardscape objects as terrain state

## Business Constraints

- survey correction must not create misleading terrain that merely satisfies point residuals while damaging reviewable terrain quality
- repeated survey workflows must support practical corrections without forcing a full terrain reset
- unsupported or under-resolved survey cases must fail honestly rather than hiding representational limits
- the evaluation must produce enough evidence for `MTA-13` planning without expanding into durable representation work prematurely

## Technical Constraints

- evaluation must use the current materialized `heightmap_grid` v1 terrain model as the primary substrate
- candidate outputs and findings must remain JSON-serializable and must not expose raw SketchUp objects
- detail-preservation metrics must be computable in SketchUp-free terrain-domain tests or prototypes
- findings must respect fixed controls, preserve-zone expectations, and current terrain output boundaries
- Unreal Engine Landscape findings are research input only and must not define public MCP naming, Ruby class names, or repository architecture

## Dependencies

- `MTA-04`
- `MTA-06`
- `MTA-12`
- `MTA-13`
- [Managed Terrain Surface Authoring HLD](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [PRD: Managed Terrain Surface Authoring](../../../prds/prd-managed-terrain-surface-authoring.md)
- [Managed Terrain Phase 1 UE Research Reference](../../../research/managed-terrain/ue-reference-phase1.md)

## Relationships

- informs `MTA-13` solver selection, refusal thresholds, and evidence shape
- informs `MTA-11` when v1 `heightmap_grid` cannot preserve survey detail safely
- follows `MTA-06` and `MTA-12` for existing fairing, region influence, and detail/falloff research baselines

## Research Notes

Initial targeted Unreal Engine source inspection has already checked these paths. Reuse these findings before doing more source discovery:

- `/mnt/c/Users/Gleb/Projects/UnrealEngine/Engine/Source/Runtime/Landscape/Public/LandscapeEdit.h`
- `/mnt/c/Users/Gleb/Projects/UnrealEngine/Engine/Source/Runtime/Landscape/Private/LandscapeEdit.cpp`
- `/mnt/c/Users/Gleb/Projects/UnrealEngine/Engine/Source/Runtime/Landscape/Private/LandscapeEditLayers.cpp`
- `/mnt/c/Users/Gleb/Projects/UnrealEngine/Engine/Source/Editor/LandscapeEditor/Private/LandscapeEdModeTools.h`
- `/mnt/c/Users/Gleb/Projects/UnrealEngine/Engine/Source/Editor/LandscapeEditor/Private/LandscapeEdModePaintTools.cpp`
- `/mnt/c/Users/Gleb/Projects/UnrealEngine/Engine/Source/Editor/LandscapeEditor/Private/LandscapeEditorObject.cpp`
- `/mnt/c/Users/Gleb/Projects/UnrealEngine/Engine/Source/Editor/LandscapeEditor/Public/LandscapeEditorObject.h`
- `/mnt/c/Users/Gleb/Projects/UnrealEngine/Engine/Source/Runtime/Landscape/Public/LandscapeBlueprintBrushBase.h`
- `/mnt/c/Users/Gleb/Projects/UnrealEngine/Engine/Source/Runtime/Landscape/Private/LandscapeBlueprintBrushBase.cpp`
- `/mnt/c/Users/Gleb/Projects/UnrealEngine/Engine/Source/Runtime/Landscape/Public/LandscapeEditLayerRenderer.h`
- `/mnt/c/Users/Gleb/Projects/UnrealEngine/Engine/Source/Runtime/Landscape/Public/LandscapeEditLayerMergeContext.h`
- `/mnt/c/Users/Gleb/Projects/UnrealEngine/Engine/Source/Runtime/Landscape/Private/LandscapeEditLayerMergeContext.cpp`

Dead ends and path corrections:

- `/mnt/c/Users/Gleb/Projects/UnrealEngine/Engine/Source/Editor/Runtime/Landscape/Public/LandscapeEdit.h` does not exist; use the runtime `LandscapeEdit.h` path above.
- `/mnt/c/Users/Gleb/Projects/UnrealEngine/Engine/Source/Editor/LandscapeEditor/Private/LandscapeEdModeTools.cpp` does not exist in this checkout; relevant tool code is in `LandscapeEdModeTools.h` and `LandscapeEdModePaintTools.cpp`.
- `/mnt/c/Users/Gleb/Projects/UnrealEngine/Engine/Plugins/Experimental/LandscapePatch` exists locally with `Binaries` and `Intermediate` only; no plugin `Source` directory was available to inspect.

Findings to carry forward:

- UE combined-layer operations can read composed terrain, read lower layers separately, and write only the current layer contribution needed to reach the desired composed result.
- UE flatten-style target edits still lerp samples toward target height or plane; detail preservation mainly comes from layer separation rather than from flatten math itself.
- UE detail smooth uses a low-pass style filter with `DetailScale`, supporting base/detail separation as a research pattern.
- Blueprint brush and edit-layer renderer APIs are useful as bounded modifier concepts, but their render-target/GPU architecture should not be copied into this SketchUp extension.

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- at least two survey correction strategies are compared against the same representative terrain fixtures
- detail-preservation and distortion evidence is explicit enough to drive `MTA-13` acceptance criteria
- repeated single-point, batch, and corrected single-point survey workflows are evaluated
- the task produces a clear recommendation for including, deferring, or refusing base/detail-preserving correction in `MTA-13`

## Implementation Conclusion

MTA-14 completed the comparison and recommends carrying the base/detail-preserving strategy into `MTA-13` as the primary solver candidate for supported `heightmap_grid` v1 survey edits.

The evaluation proved that base/detail correction can satisfy survey residuals while preserving outside detail and suppressing local correction-core detail. The richer large-surface visual proof also showed an important nuance: minimum-change can score lower on slope/curvature proxies when it changes only local stencils, so `MTA-13` should report residual, detail-preservation, and distortion evidence together rather than treating threshold checks as detail preservation.

`MTA-13` should reuse the MTA-14 solver logic and fixtures as much as possible, but by promoting the reusable algorithm into production terrain-domain code under `src/su_mcp/terrain/` rather than depending on the MTA-14 `test/support` harness directly. Hosted/public MCP validation for request handling, persistence, regenerated output, undo behavior, and visual/runtime quality remains required in `MTA-13`.
