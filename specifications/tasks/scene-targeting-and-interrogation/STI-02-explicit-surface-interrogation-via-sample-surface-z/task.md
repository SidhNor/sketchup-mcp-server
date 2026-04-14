# Task: STI-02 Explicit Surface Interrogation via `sample_surface_z`
**Task ID**: `STI-02`
**Title**: `Explicit Surface Interrogation via sample_surface_z`
**Status**: `draft`
**Priority**: `P0`
**Date**: `2026-04-14`

## Linked HLD

- [Scene Targeting and Interrogation](../../../hlds/hld-scene-targeting-and-interrogation.md)

## Problem Statement

Terrain-aware placement and reprojection-oriented workflows currently lack a product-owned way to sample explicit geometry in a deterministic, structured form. Without that capability, workflows either fall back to ad hoc probing or inherit ambiguity about whether the sampled surface was actually the intended target.

The HLD and PRD define `sample_surface_z` as the explicit interrogation tool for this need. This task turns that requirement into a focused first-iteration deliverable that builds on the shared targeting model from `STI-01`, keeps geometry behavior in Ruby, and returns compact structured outcomes for downstream automation.

## Goals

- deliver explicit target-based surface sampling through `sample_surface_z`
- return deterministic structured `hit`, `miss`, and `ambiguous` outcomes for one or more world-space XY sample points
- verify the geometry-heavy behavior with the smallest practical mix of contract checks and geometry-backed validation

## Acceptance Criteria

```gherkin
Scenario: sample_surface_z operates on explicit targets rather than generic probing
  Given a caller provides an explicit supported target reference and one or more XY sample points
  When `sample_surface_z` is exercised through the MCP surface
  Then the tool samples against the explicitly resolved target geometry
  And the behavior does not fall back to unconstrained generic scene probing as the normal path

Scenario: sample_surface_z returns structured point-by-point outcomes
  Given one or more sample points against supported target geometry
  When the result is reviewed
  Then the response returns one structured result per point with a status of `hit`, `miss`, or `ambiguous`
  And resolved hits include sampled coordinates in a JSON-serializable payload

Scenario: surface interrogation respects default visibility and ignore-target rules
  Given the scene contains geometry that may occlude or interfere with the intended sample
  When `sample_surface_z` is called with the documented defaults and optional ignore-target references
  Then visible-only behavior is the default interrogation mode
  And supported ignore-target references can exclude the specified geometry from the intended sampling result

Scenario: geometry outputs are consistent for downstream automation
  Given a successful sample result is returned at the MCP boundary
  When the payload is reviewed
  Then geometry values are reported in world space and meters
  And the Python tool remains a thin adapter over Ruby-owned geometry behavior

Scenario: geometry-heavy behavior is verified beyond pure unit seams
  Given `sample_surface_z` depends on real SketchUp geometry behavior
  When the task is reviewed
  Then the change includes minimum practical automated coverage for the contract surface
  And it includes geometry-backed verification or an explicit documented gap where hosted automation is not yet practical
```

## Non-Goals

- implementing `analyze_edge_network`
- implementing `get_bounds`
- adding workflow-specific interrogation helper tools beyond `sample_surface_z`

## Business Constraints

- the task must make terrain-aware and reprojection-aware workflows more reliable without requiring arbitrary Ruby as the normal path
- interrogation results must stay compact enough for automated consumers rather than becoming a debugging dump
- the task must preserve the product boundary that this slice returns findings, not downstream placement policy

## Technical Constraints

- `sample_surface_z` must use the explicit target-reference model established by `STI-01`
- Ruby must own geometry resolution, hit evaluation, ambiguity handling, and serialization of sampled results
- Python must remain a thin MCP adapter that performs boundary validation and bridge invocation only
- the task must preserve the HLD constraint that public geometry values are reported in world space and meters at the MCP boundary

## Dependencies

- `PLAT-02`
- `PLAT-03`
- `STI-01`

## Relationships

- enables downstream placement, reprojection, and validation-preparation workflows that require explicit surface sampling
- informs the deferred topology-analysis follow-on

## Related Technical Plan

- none yet

## Success Metrics

- representative explicit-target sampling scenarios return structured `hit`, `miss`, or `ambiguous` outcomes without ad hoc probing
- downstream consumers can use returned coordinates directly without text scraping or hidden unit conversion
- the first iteration includes a reviewable geometry-backed verification story for `sample_surface_z`, even if some hosted automation remains deferred
