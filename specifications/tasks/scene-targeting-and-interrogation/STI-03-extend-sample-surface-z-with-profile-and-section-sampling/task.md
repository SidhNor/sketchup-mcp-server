# Task: STI-03 Extend `sample_surface_z` With Profile and Section Sampling
**Task ID**: `STI-03`
**Title**: `Extend sample_surface_z With Profile and Section Sampling`
**Status**: `planned`
**Priority**: `P1`
**Date**: `2026-04-24`

## Linked HLD

- [Scene Targeting and Interrogation](../../../hlds/hld-scene-targeting-and-interrogation.md)

## Related Signals

- [Partial terrain authoring session reveals stable patch-editing contract](../../../signals/2026-04-24-partial-terrain-authoring-session-reveals-stable-patch-editing-contract.md)

## Problem Statement

`sample_surface_z` now gives agents a safer explicit-host alternative to generic ray probing for point samples. Terrain review workflows still need repeated section and profile evidence, though, especially when checking whether a path, threshold, shoulder, or preserve-zone boundary is behaving as expected across a line rather than at isolated points.

This task extends the existing explicit surface-interrogation slice from point batches to ordered profile and section sampling while staying evidence-producing only. It should make terrain-shaped evidence easier to collect without creating terrain editing, grade validation, or fairness-solver responsibilities.

## Goals

- extend the explicit host-target sampling surface to ordered profile and section sampling
- preserve deterministic host-target disambiguation so vegetation and overlapping scene objects do not pollute terrain samples
- return compact ordered sample evidence that downstream measurement and validation tasks can consume
- keep `sample_surface_z` backward-compatible for point sampling unless implementation discovery proves a separate public tool is cleaner

## Acceptance Criteria

```gherkin
Scenario: profile sampling uses an explicit resolved host
  Given a caller provides one explicit target surface and a profile or section sampling request
  When the sampling request is executed
  Then every sample is evaluated against the explicit resolved host
  And the tool does not silently fall back to generic nearest-scene probing

Scenario: ordered profile output stays deterministic and compact
  Given a caller provides an ordered polyline, edge-chain, or ordered XY path with an interval or sample count
  When the profile is sampled
  Then the response returns an ordered array of JSON-serializable sample results
  And each sample includes input position, sample distance or progress, status, and sampled XYZ coordinates when hit
  And the response includes a compact summary with hit count, miss count, sampled length, and min/max sampled Z where available

Scenario: point sampling remains compatible
  Given existing callers use `sample_surface_z` for XY point batches
  When this task extends the public sampling surface
  Then existing point-sampling request and response behavior remains stable
  And any new discriminator or fields preserve the current point-sampling contract

Scenario: occlusion and miss handling are explicit
  Given vegetation or overlapping geometry exists above the intended terrain host
  When profile sampling is requested against the explicit terrain host
  Then sampling resolves against the host rather than the occluding object
  And misses are returned as structured sample statuses rather than fabricated elevations

Scenario: terrain diagnostics remain out of scope
  Given profile samples reveal a bump, trench, or abrupt grade break
  When this task is reviewed
  Then the output remains measurement evidence only
  And the tool does not return slope verdicts, fairness verdicts, grade compliance decisions, or terrain edit suggestions
```

## Non-Goals

- implementing terrain editing, patch replacement, smoothing, fairing, or working-copy lifecycle behavior
- adding validation verdicts for slope, humps, trenches, grade breaks, drainage, or fairness
- implementing a terrain solver or optimizing surface continuity
- adding generic scene probing or selector-style discovery inside the profile-sampling path
- making `measure_scene` depend on unfinished profile mode names in this task

## Business Constraints

- terrain workflows should gain safer evidence collection without committing the product to a paid-plugin-scale terrain modeling surface
- profile evidence must be useful to agents without becoming a verbose geometry dump
- the task must preserve the current capability ownership: targeting/interrogation collects evidence; validation/review interprets it later

## Technical Constraints

- Ruby must own host resolution, sampling behavior, ambiguity handling, and JSON-safe serialization
- the implementation must reuse the existing explicit target-resolution and surface-interrogation seams rather than creating a second raytest stack
- profile sampling must accept only explicit host references; broad discovery remains owned by targeting tools such as `find_entities`
- public geometry values must remain world-space and unit-explicit at the MCP boundary
- any public schema change must keep the tool-parameter root provider-compatible as a top-level object without root `oneOf`, `anyOf`, `allOf`, `not`, or `enum`
- if extending `sample_surface_z` makes the schema materially confusing, implementation planning may choose a separate profile-sampling tool while preserving this task's bounded product intent

## Dependencies

- `STI-02`
- [Scene Targeting and Interrogation HLD](../../../hlds/hld-scene-targeting-and-interrogation.md)
- [PRD: Scene Targeting and Interrogation](../../../prds/prd-scene-targeting-and-interrogation.md)

## Relationships

- builds directly on the explicit host-target semantics delivered by `sample_surface_z`
- enables `SVR-04` terrain-aware measurement evidence without moving terrain profile sampling into validation
- informs later terrain-aware validation diagnostics if profile evidence proves sufficient and stable
- keeps bounded terrain patch helpers deferred until evidence-producing workflows reveal a specific missing authoring primitive

## Related Technical Plan

- [Technical Plan](./plan.md)

## Success Metrics

- agents can request an ordered terrain profile or section against an explicit host without arbitrary Ruby
- overlapping vegetation or scene geometry does not change samples when the terrain host is explicitly targeted
- downstream tasks can consume compact ordered samples and summaries without text scraping
- no public output implies terrain editing, grade compliance, or fairness validation in this slice
